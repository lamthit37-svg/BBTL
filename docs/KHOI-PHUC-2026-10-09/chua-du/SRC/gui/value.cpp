⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫

// Vị trí của key khi nó đứng đầu chuỗi hay ngay sau một khoảng trắng; npos khi không có.
std::size_t tag_at(std::string_view text, std::string_view key) noexcept {
    std::size_t position = text.find(key);
    while (position != std::string_view::npos && position != 0 && !is_blank(text[position - 1]))
        position = text.find(key, position + 1);
    return position;
}

// Hex tối đa 8 chữ số sau tiền tố key (rỗng là đầu chuỗi), như "%8X".
std::optional<std::uint32_t> hex_after(std::string_view text, std::string_view key) noexcept {
    const std::size_t position = text.find(key);
    if (position == std::string_view::npos) return std::nullopt;
    const std::string_view rest = trimmed(text.substr(position + key.size()));
    const core::OptionalUnsigned parsed = core::parse_unsigned(rest.substr(0, kHexDigits), 16);
    if (!parsed) return std::nullopt;
    return parsed->value;
}

} // namespace

std::optional<GuiUDim> parse_udim(std::string_view text) noexcept {
    const auto values = numbers<2>(text);
    if (!values) return std::nullopt;
    return GuiUDim{.scale = values->at(0), .offset = values->at(1)};
}

std::optional<UVector> parse_uvector(std::string_view text) noexcept {
    const auto values = numbers<4>(text);
    if (!values) return std::nullopt;
    const GuiUDim across{.scale = values->at(0), .offset = values->at(1)};
    const GuiUDim down{.scale = values->at(2), .offset = values->at(3)};
    return UVector{.x = across, .y = down};
}

std::optional<URect> parse_urect(std::string_view text) noexcept {
    const auto values = numbers<8>(text);
    if (!values) return std::nullopt;
    const UVector low{
        .x = {.scale = values->at(0), .offset = values->at(1)}, .y = {.scale = values->at(2), .offset = values->at(3)}};
    const UVector high{
        .x = {.scale = values->at(4), .offset = values->at(5)}, .y = {.scale = values->at(6), .offset = values->at(7)}};
    return URect{.min = low, .max = high};
}

bool parse_bool(std::string_view text) noexcept {
    const std::string_view value = trimmed(text);
    return value == "True" || value == "true";
}

⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
⟪thiếu dòng này⟫
