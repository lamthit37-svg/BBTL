// Ghi và đọc cây thư mục cho .tlpak. Một tệp trong bộ nhớ tại một thời điểm.
// Ghi ra tệp .partial rồi đổi tên. Không ghi đè khoá, gói, hay bản dở.
// Từ chối đích có "thienlong/client" trong đường chuẩn: client không nhận gói này.
// Từ chối gói nằm trong thư mục nguồn, kẻo công cụ tự niêm chính nó.
// View.context chỉ gắn sau khi Input nằm trong expected: trả Input theo giá trị rồi mới lấy địa
// chỉ.
#include "seal/tree.hpp"

#include "io/file.hpp"
#include "seal/detail/format.hpp"
#include "seal/detail/sodium.hpp"
#include "seal/package.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <fstream>
#include <ios>
#include <limits>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

namespace game::seal {
namespace {

using detail::Catalog;
using detail::derive_subkeys;
using detail::encode_head;
using detail::encode_index;
using detail::Entry;
using detail::fold_ascii;
using detail::Gate;
using detail::Head;
using detail::kMaxPlain;
using detail::kOverhead;
using detail::legal_name;
using detail::mark;
using detail::open_catalog;
using detail::package_check;
using detail::read_named;
using detail::read_names;
using detail::seal_chunk;
using detail::seal_plain;
using detail::SubKeys;
using detail::View;
using Path = std::filesystem::path;
using Listing = std::expected<std::vector<std::string>, Error>;

struct Canon {
    std::string text;
    bool is_ok = false;
};

// NOLINTNEXTLINE(bugprone-exception-escape): giả dương của STL MSVC (HP-07)
struct Input {
    std::ifstream file;
    std::uint64_t size = 0;
};

struct Ledger {
    std::ofstream* file = nullptr;
    std::vector<Entry>* entries = nullptr;
    std::uint64_t cursor = kHeaderBytes;
    std::uint64_t raw_bytes = 0;
    Gate gate;
};

struct Pump {
    Ledger* ledger = nullptr;
    const SubKeys* keys = nullptr;
    const Path* root = nullptr;
};

struct Walk {
    std::vector<std::string>* names = nullptr;
    std::set<std::string>* folded = nullptr;
    const Path* root = nullptr;
    Gate gate;
};

struct Step {
    std::error_code* error = nullptr;
    bool stopped = false;
};

struct Draft {
    Ledger* ledger = nullptr;
    const SubKeys* keys = nullptr;
    const Path* partial = nullptr;
    const Path* into = nullptr;
    std::uint64_t files = 0;
};

// Hai đường dẫn. Không đưa hai path cạnh nhau trên chữ ký tự do (dễ đảo).
struct TwoPaths {
    const Path* first = nullptr;
    const Path* second = nullptr;
};

struct Rename {
    const Path* partial = nullptr;
    const Path* into = nullptr;
};

struct Extract {
    const Catalog* catalog = nullptr;
    const View* view = nullptr;
    const Path* root = nullptr;
    Saved saved;
    Gate gate;
};

using InputResult = std::expected<Input, Error>;
using HeadBytes = std::array<std::byte, kHeaderBytes>;
using HeadResult = std::expected<HeadBytes, Error>;
using PathResult = std::expected<Path, Error>;

// NOLINTBEGIN(cppcoreguidelines-pro-type-reinterpret-cast)
bool write_span(std::ofstream& file, Bytes bytes) {
    if (bytes.empty()) return true;
    const auto* raw = reinterpret_cast<const char*>(bytes.data());
    file.write(raw, static_cast<std::streamsize>(bytes.size()));
    return static_cast<bool>(file);
}

bool read_input(void* context, std::uint64_t offset, std::span<std::byte> into) {
    auto* input = static_cast<Input*>(context);
    if (input == nullptr) return false;
    if (into.empty()) return true;
    if (offset > input->size || into.size() > input->size - offset) return false;
    const auto limit = std::numeric_limits<std::streamoff>::max();
    if (offset > static_cast<std::uint64_t>(limit)) return false;
    input->file.clear();
    input->file.seekg(static_cast<std::streamoff>(offset));
    if (!input->file) return false;
    auto* raw = reinterpret_cast<char*>(into.data());
    input->file.read(raw, static_cast<std::streamsize>(into.size()));
    const auto got = input->file.gcount();
    return std::cmp_equal(got, into.size());
}
// NOLINTEND(cppcoreguidelines-pro-type-reinterpret-cast)

bool write_file(const Path& path, Bytes bytes) {
    std::ofstream file(path, std::ios::binary | std::ios::trunc);
    if (!file.is_open()) return false;
    return write_span(file, bytes);
}

Canon canon_fold(const Path& path) {
    std::error_code error;
    const Path full = std::filesystem::weakly_canonical(path, error);
    Canon canon;
    if (error) return canon;
    canon.text = fold_ascii(io::utf8_of(full));
    canon.is_ok = true;
    return canon;
}

bool hits_client(const Path& path) {
    const Canon canon = canon_fold(path);
    if (!canon.is_ok) return true;
    const auto found = canon.text.find("thienlong/client");
    return found != std::string::npos;
}

bool covers(const TwoPaths& paths) {
    if (paths.first == nullptr || paths.second == nullptr) return false;
    const Canon parent_canon = canon_fold(*paths.first);
    const Canon child_canon = canon_fold(*paths.second);
    if (!parent_canon.is_ok || !child_canon.is_ok) return false;
    if (child_canon.text == parent_canon.text) return true;
    if (!child_canon.text.starts_with(parent_canon.text)) return false;
    const std::size_t cut = parent_canon.text.size();
    const bool longer = child_canon.text.size() > cut;
    return longer && child_canon.text[cut] == '/';
}

bool same_place(const TwoPaths& paths) {
    if (paths.first == nullptr || paths.second == nullptr) return true;
    const Canon left_canon = canon_fold(*paths.first);
    const Canon right_canon = canon_fold(*paths.second);
    if (!left_canon.is_ok || !right_canon.is_ok) return true;
    return left_canon.text == right_canon.text;
}

bool path_blocks(const Path& path) {
    std::error_code error;
    const bool exists = std::filesystem::exists(path, error);
    return static_cast<bool>(error) || exists;
}

bool is_folder(const Path& path) {
    std::error_code error;
    const bool folder = std::filesystem::is_directory(path, error);
    return !error && folder;
}

bool is_file(const Path& path) {
    std::error_code error;
    const bool file = std::filesystem::is_regular_file(path, error);
    return !error && file;
}

Path partial_path(const Path& into) {
    Path partial = into;
    partial += ".partial";
    return partial;
}

UnitResult ensure_parent(const Path& into) {
    const Path parent = into.parent_path();
    if (parent.empty()) return {};
    std::error_code error;
    std::filesystem::create_directories(parent, error);
    if (error) return std::unexpected(Error::kIo);
    return {};
}

UnitResult ensure_directory(const Path& directory) {
    std::error_code error;
    std::filesystem::create_directories(directory, error);
    if (error) return std::unexpected(Error::kIo);
    if (!is_folder(directory)) return std::unexpected(Error::kIo);
    return {};
}

BlobResult slurp(const Path& path) {
    std::error_code error;
    const auto size = std::filesystem::file_size(path, error);
    if (error) return std::unexpected(Error::kIo);
    if (size > kMaxPlain) return std::unexpected(Error::kTooLarge);
    Blob bytes(static_cast<std::size_t>(size));
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) return std::unexpected(Error::kIo);
    if (bytes.empty()) return bytes;
    Input holder;
    holder.file = std::move(file);
    holder.size = bytes.size();
    const bool got = read_input(&holder, 0, bytes);
    if (!got) return std::unexpected(Error::kIo);
    return bytes;
}

void append_line(Blob& body, std::string_view name) {
    for (const char unit : name)
        body.push_back(static_cast<std::byte>(unit));
    body.push_back(std::byte{'\n'});
}

Blob manifest_body(const std::vector<std::string>& names) {
    Blob body;
    for (const std::string& name : names)
        append_line(body, name);
    return body;
}

bool append_raw(Ledger& ledger, const SubKeys& keys, std::string_view name, Bytes raw) {
    if (!ledger.gate.is_ok || ledger.file == nullptr || ledger.entries == nullptr) return false;
    auto chunk = seal_chunk(keys, name, raw);
    if (!chunk) mark(ledger.gate, chunk.error());
    if (!ledger.gate.is_ok) return false;
    const std::uint64_t width = chunk->bytes.size();
    const auto room = std::numeric_limits<std::uint64_t>::max() - ledger.cursor;
    if (width > room) mark(ledger.gate, Error::kTooLarge);
    if (!ledger.gate.is_ok) return false;
    chunk->entry.offset = ledger.cursor;
    const bool wrote = write_span(*ledger.file, chunk->bytes);
    if (!wrote) mark(ledger.gate, Error::kIo);
    if (!wrote) return false;
    ledger.cursor += width;
    ledger.entries->push_back(chunk->entry);
    return true;
}

bool add_raw_bytes(Ledger& ledger, std::uint64_t more) {
    const auto room = std::numeric_limits<std::uint64_t>::max() - ledger.raw_bytes;
    if (more > room) mark(ledger.gate, Error::kTooLarge);
    if (!ledger.gate.is_ok) return false;
    ledger.raw_bytes += more;
    return true;
}

bool pump_file(Pump& pump, std::string_view name) {
    if (pump.ledger == nullptr || pump.keys == nullptr || pump.root == nullptr) return false;
    if (!pump.ledger->gate.is_ok) return false;
    const Path full = *pump.root / io::path_from_utf8(name);
    auto raw = slurp(full);
    if (!raw) mark(pump.ledger->gate, raw.error());
    if (!pump.ledger->gate.is_ok) return false;
    const bool room = add_raw_bytes(*pump.ledger, raw->size());
    if (!room) return false;
    return append_raw(*pump.ledger, *pump.keys, name, *raw);
}

bool pump_names(Pump& pump, const std::vector<std::string>& names) {
    if (pump.ledger == nullptr || pump.keys == nullptr) return false;
    bool alive = true;
    for (const std::string& name : names)
        alive = alive && pump_file(pump, name);
    if (!alive) return false;
    const Blob body = manifest_body(names);
    return append_raw(*pump.ledger, *pump.keys, kManifestName, body);
}

bool rising(const std::vector<Entry>& entries) {
    bool ordered = true;
    for (std::size_t index = 1; index < entries.size(); ++index) {
        const bool less = entries[index - 1].hash < entries[index].hash;
        ordered = ordered && less;
    }
    return ordered;
}

HeadResult make_head(const Ledger& ledger, const SubKeys& keys, Bytes plain) {
    if (ledger.entries == nullptr) return std::unexpected(Error::kIo);
    const auto count = ledger.entries->size();
    if (count > std::numeric_limits<std::uint32_t>::max()) return std::unexpected(Error::kTooLarge);
    const std::uint64_t index_bytes = plain.size() + kOverhead;
    if (index_bytes < plain.size()) return std::unexpected(Error::kTooLarge);
    Head head;
    head.count = static_cast<std::uint32_t>(count);
    head.index_offset = ledger.cursor;
    head.index_size = index_bytes;
    head.check = package_check(keys);
    return encode_head(head);
}

bool ledger_open(const Ledger& ledger) {
    const bool parts = ledger.file != nullptr && ledger.entries != nullptr;
    return ledger.gate.is_ok && parts;
}

bool keep_sorted(Ledger& ledger) {
    if (ledger.entries == nullptr) return false;
    std::ranges::sort(*ledger.entries, {}, &Entry::hash);
    if (rising(*ledger.entries)) return true;
    mark(ledger.gate, Error::kDuplicate);
    return false;
}

template <class Result>
bool take_blob(Ledger& ledger, Result& result) {
    if (result) return true;
    mark(ledger.gate, result.error());
    return false;
}

bool write_or_mark(Ledger& ledger, Bytes bytes) {
    if (ledger.file == nullptr) return false;
    const bool wrote = write_span(*ledger.file, bytes);
    if (wrote) return true;
    mark(ledger.gate, Error::kIo);
    return false;
}

bool write_index(Ledger& ledger, const SubKeys& keys) {
    if (!ledger_open(ledger) || !keep_sorted(ledger)) return false;
    const Blob plain = encode_index(*ledger.entries);
    auto raw = make_head(ledger, keys, plain);
    if (!take_blob(ledger, raw)) return false;
    auto sealed = seal_plain(keys.index, plain, *raw);
    if (!take_blob(ledger, sealed)) return false;
    if (!write_or_mark(ledger, *sealed)) return false;
    ledger.file->seekp(0);
    if (!write_or_mark(ledger, *raw)) return false;
    ledger.file->flush();
    const bool healthy = static_cast<bool>(*ledger.file);
    if (healthy) return true;
    mark(ledger.gate, Error::kIo);
    return false;
}

void discard_partial(std::ofstream& file, const Path& partial) {
    if (file.is_open()) file.close();
    std::error_code error;
    std::filesystem::remove(partial, error);
}

bool commit_partial(std::ofstream& file, const Rename& rename) {
    if (rename.partial == nullptr || rename.into == nullptr) return false;
    file.close();
    std::error_code error;
    if (file.fail()) {
        std::filesystem::remove(*rename.partial, error);
        return false;
    }
    std::filesystem::rename(*rename.partial, *rename.into, error);
    if (!error) return true;
    std::error_code remove_error;
    std::filesystem::remove(*rename.partial, remove_error);
    return false;
}

UnitResult open_blank(std::ofstream& file, const Path& partial) {
    file.open(partial, std::ios::binary | std::ios::trunc);
    if (!file.is_open()) return std::unexpected(Error::kIo);
    const HeadBytes blank{};
    const bool wrote = write_span(file, blank);
    if (wrote) return {};
    discard_partial(file, partial);
    return std::unexpected(Error::kIo);
}

UnitResult check_seal_paths(const TreePaths& paths) {
    if (paths.from == nullptr || paths.into == nullptr) return std::unexpected(Error::kIo);
    if (!is_folder(*paths.from)) return std::unexpected(Error::kIo);
    if (hits_client(*paths.into)) return std::unexpected(Error::kIo);
    const Path partial = partial_path(*paths.into);
    if (hits_client(partial)) return std::unexpected(Error::kIo);
    if (path_blocks(*paths.into) || path_blocks(partial)) return std::unexpected(Error::kIo);
    const TwoPaths into_nest{.first = paths.from, .second = paths.into};
    const TwoPaths partial_nest{.first = paths.from, .second = &partial};
    if (covers(into_nest) || covers(partial_nest)) return std::unexpected(Error::kIo);
    return ensure_parent(*paths.into);
}

void note_increment(std::filesystem::recursive_directory_iterator& cursor, Step& step) {
    if (step.stopped || step.error == nullptr) return;
    cursor.increment(*step.error);
    step.stopped = static_cast<bool>(*step.error);
}

bool reject_link(Walk& walk, const std::filesystem::directory_entry& entry) {
    std::error_code error;
    const bool link = entry.is_symlink(error);
    const bool bad = static_cast<bool>(error) || link;
    if (bad) mark(walk.gate, Error::kIo);
    return bad;
}

bool reject_directory(Walk& walk, const std::filesystem::directory_entry& entry, bool& directory) {
    std::error_code error;
    directory = entry.is_directory(error);
    if (error) mark(walk.gate, Error::kIo);
    return static_cast<bool>(error);
}

bool walk_ready(const Walk& walk) {
    const bool named = walk.names != nullptr && walk.folded != nullptr;
    return walk.gate.is_ok && named && walk.root != nullptr;
}

bool note_regular(Walk& walk, const std::filesystem::directory_entry& entry) {
    std::error_code error;
    const bool regular = entry.is_regular_file(error);
    const bool bad = static_cast<bool>(error) || !regular;
    if (!bad) return true;
    mark(walk.gate, Error::kIo);
    return false;
}

bool keep_name(Walk& walk, std::string_view name) {
    if (walk.folded == nullptr || walk.names == nullptr) return false;
    if (!legal_name(name)) mark(walk.gate, Error::kName);
    if (!walk.gate.is_ok) return false;
    const std::string folded = fold_ascii(name);
    const bool fresh = walk.folded->insert(folded).second;
    if (fresh) return true;
    mark(walk.gate, Error::kDuplicate);
    return false;
}

void note_file(Walk& walk, const std::filesystem::directory_entry& entry) {
    if (!walk_ready(walk)) return;
    if (reject_link(walk, entry)) return;
    bool directory = false;
    if (reject_directory(walk, entry, directory)) return;
    if (directory) return;
    if (!note_regular(walk, entry)) return;
    const Path relative = entry.path().lexically_relative(*walk.root);
    const std::string name = io::utf8_of(relative);
    if (!keep_name(walk, name)) return;
    walk.names->push_back(name);
}

Listing collect_names(const Path& root) {
    std::error_code error;
    const auto options = std::filesystem::directory_options::skip_permission_denied;
    std::filesystem::recursive_directory_iterator cursor(root, options, error);
    if (error) return std::unexpected(Error::kIo);
    std::vector<std::string> names;
    std::set<std::string> folded;
    Walk walk{.names = &names, .folded = &folded, .root = &root, .gate = {}};
    Step step{.error = &error};
    const auto end = std::filesystem::recursive_directory_iterator{};
    while (cursor != end && !step.stopped && walk.gate.is_ok) {
        note_file(walk, *cursor);
        note_increment(cursor, step);
    }
    if (step.stopped) return std::unexpected(Error::kIo);
    if (!walk.gate.is_ok) return std::unexpected(walk.gate.error);
    std::ranges::sort(names);
    return names;
}

SaveResult finish_draft(const Draft& draft) {
    if (draft.ledger == nullptr || draft.keys == nullptr) return std::unexpected(Error::kIo);
    if (draft.partial == nullptr || draft.into == nullptr || draft.ledger->file == nullptr)
        return std::unexpected(Error::kIo);
    const bool indexed = write_index(*draft.ledger, *draft.keys);
    if (!indexed) {
        discard_partial(*draft.ledger->file, *draft.partial);
        return std::unexpected(draft.ledger->gate.error);
    }
    const Rename rename{.partial = draft.partial, .into = draft.into};
    const bool committed = commit_partial(*draft.ledger->file, rename);
    if (!committed) return std::unexpected(Error::kIo);
    Saved saved;
    saved.files = draft.files;
    saved.bytes = draft.ledger->raw_bytes;
    return saved;
}

InputResult open_input(const Path& path) {
    std::error_code error;
    const auto size = std::filesystem::file_size(path, error);
    if (error) return std::unexpected(Error::kIo);
    Input input;
    input.size = static_cast<std::uint64_t>(size);
    input.file.open(path, std::ios::binary);
    if (!input.file.is_open()) return std::unexpected(Error::kIo);
    return input;
}

View view_of(Input& input) {
    View view;
    view.size = input.size;
    view.read = &read_input;
    view.context = &input;
    return view;
}

UnitResult check_open_paths(const TreePaths& paths) {
    if (paths.from == nullptr || paths.into == nullptr) return std::unexpected(Error::kIo);
    if (!is_file(*paths.from)) return std::unexpected(Error::kIo);
    if (hits_client(*paths.into)) return std::unexpected(Error::kIo);
    const TwoPaths same{.first = paths.from, .second = paths.into};
    if (same_place(same)) return std::unexpected(Error::kIo);
    if (path_blocks(*paths.into) && !is_folder(*paths.into)) return std::unexpected(Error::kIo);
    return ensure_directory(*paths.into);
}

PathResult place_of(const Path& root, std::string_view name) {
    if (!legal_name(name)) return std::unexpected(Error::kName);
    const Path relative = io::path_from_utf8(name);
    if (relative.is_absolute()) return std::unexpected(Error::kName);
    Path full = root / relative;
    const TwoPaths nest{.first = &root, .second = &full};
    if (!covers(nest) || same_place(nest)) return std::unexpected(Error::kName);
    return full;
}

bool write_fresh(const Path& path, Bytes bytes) {
    if (path_blocks(path)) return false;
    const UnitResult parent = ensure_parent(path);
    if (!parent) return false;
    return write_file(path, bytes);
}

bool job_ready(const Extract& job) {
    const bool book = job.catalog != nullptr && job.view != nullptr && job.root != nullptr;
    return job.gate.is_ok && book;
}

bool add_saved(Extract& job, std::uint64_t size) {
    const auto room = std::numeric_limits<std::uint64_t>::max() - job.saved.bytes;
    if (size > room) mark(job.gate, Error::kTooLarge);
    if (!job.gate.is_ok) return false;
    job.saved.bytes += size;
    job.saved.files += 1;
    return true;
}

bool extract_one(Extract& job, std::string_view name) {
    if (!job_ready(job)) return false;
    auto body = read_named(*job.catalog, *job.view, name);
    if (!body) mark(job.gate, body.error());
    if (!job.gate.is_ok) return false;
    auto full = place_of(*job.root, name);
    if (!full) mark(job.gate, full.error());
    if (!job.gate.is_ok) return false;
    const bool wrote = write_fresh(*full, *body);
    if (!wrote) mark(job.gate, Error::kIo);
    if (!wrote) return false;
    return add_saved(job, body->size());
}

bool tally_one(Extract& job, std::string_view name) {
    if (!job.gate.is_ok || job.catalog == nullptr || job.view == nullptr) return false;
    auto body = read_named(*job.catalog, *job.view, name);
    if (!body) mark(job.gate, body.error());
    if (!job.gate.is_ok) return false;
    const auto room = std::numeric_limits<std::uint64_t>::max() - job.saved.bytes;
    if (body->size() > room) mark(job.gate, Error::kTooLarge);
    if (!job.gate.is_ok) return false;
    job.saved.bytes += body->size();
    job.saved.files += 1;
    return true;
}

SaveResult walk_names(Extract& job, const std::vector<std::string>& names, bool writing) {
    bool alive = true;
    for (const std::string& name : names) {
        const bool step = writing ? extract_one(job, name) : tally_one(job, name);
        alive = alive && step;
    }
    if (!alive) return std::unexpected(job.gate.error);
    return job.saved;
}

} // namespace

KeyResult load_key(const Path& path) {
    auto body = slurp(path);
    if (!body) return std::unexpected(body.error());
    if (body->size() != kKeyBytes) return std::unexpected(Error::kIo);
    Key key;
    std::ranges::copy(*body, key.bytes.begin());
    detail::wipe(*body);
    return key;
}

UnitResult store_key(const Key& key, const Path& path) {
    if (hits_client(path)) return std::unexpected(Error::kIo);
    const Path partial = partial_path(path);
    if (hits_client(partial)) return std::unexpected(Error::kIo);
    if (path_blocks(path) || path_blocks(partial)) return std::unexpected(Error::kIo);
    const UnitResult parent = ensure_parent(path);
    if (!parent) return std::unexpected(parent.error());
    const bool wrote = write_file(partial, key.bytes);
    if (!wrote) {
        std::error_code error;
        std::filesystem::remove(partial, error);
        return std::unexpected(Error::kIo);
    }
    std::error_code error;
    std::filesystem::rename(partial, path, error);
    if (!error) return {};
    std::error_code remove_error;
    std::filesystem::remove(partial, remove_error);
    return std::unexpected(Error::kIo);
}

SaveResult seal_folder(const Key& key, const TreePaths& paths) {
    const UnitResult paths_ok = check_seal_paths(paths);
    if (!paths_ok) return std::unexpected(paths_ok.error());
    auto names = collect_names(*paths.from);
    if (!names) return std::unexpected(names.error());
    auto sub = derive_subkeys(key);
    if (!sub) return std::unexpected(sub.error());
    const Path partial = partial_path(*paths.into);
    std::ofstream file;
    const UnitResult opened = open_blank(file, partial);
    if (!opened) return std::unexpected(opened.error());
    std::vector<Entry> entries;
    Ledger ledger{.file = &file, .entries = &entries, .cursor = kHeaderBytes, .raw_bytes = 0, .gate = {}};
    Pump pump{.ledger = &ledger, .keys = &*sub, .root = paths.from};
    const bool pumped = pump_names(pump, *names);
    if (!pumped) {
        discard_partial(file, partial);
        return std::unexpected(ledger.gate.error);
    }
    Draft draft;
    draft.ledger = &ledger;
    draft.keys = &*sub;
    draft.partial = &partial;
    draft.into = paths.into;
    draft.files = names->size();
    return finish_draft(draft);
}

SaveResult open_folder(const Key& key, const TreePaths& paths) {
    const UnitResult paths_ok = check_open_paths(paths);
    if (!paths_ok) return std::unexpected(paths_ok.error());
    auto input = open_input(*paths.from);
    if (!input) return std::unexpected(input.error());
    const View view = view_of(*input);
    auto catalog = open_catalog(key, view);
    if (!catalog) return std::unexpected(catalog.error());
    auto names = read_names(*catalog, view);
    if (!names) return std::unexpected(names.error());
    Extract job{.catalog = &*catalog, .view = &view, .root = paths.into, .saved = {}, .gate = {}};
    return walk_names(job, *names, true);
}

SaveResult verify_folder(const Key& key, const Path& package) {
    auto input = open_input(package);
    if (!input) return std::unexpected(input.error());
    const View view = view_of(*input);
    auto catalog = open_catalog(key, view);
    if (!catalog) return std::unexpected(catalog.error());
    auto names = read_names(*catalog, view);
    if (!names) return std::unexpected(names.error());
    Extract job{.catalog = &*catalog, .view = &view, .root = nullptr, .saved = {}, .gate = {}};
    return walk_names(job, *names, false);
}

} // namespace game::seal
