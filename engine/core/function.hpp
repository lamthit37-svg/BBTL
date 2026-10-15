/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/function.hpp
 *  PHÂN HỆ   : Core / Function
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hàm chỉ chuyển, không sao chép. Thư viện có std::move_only_function thì
 *    bọc một lớp mỏng: gọi lúc rỗng, operator() của thư viện ném
 *    bad_function_call. libc++ của NDK r30 tắt __cpp_lib_move_only_function,
 *    nên nhánh kia tự cài cho chữ ký không const và chữ ký const.
 *  - Nguồn: Forge2 src/core/function.hpp@d7fcd76. Khác gốc: gọi lúc rỗng là
 *    core::check, không ném bad_function_call.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/check.hpp"

#include <concepts>
#include <cstddef>
#include <utility>
#include <version>

#if defined(__cpp_lib_move_only_function)

#include <functional>
#include <type_traits>

namespace game::core {

// Chữ ký không const là những chữ ký repo đang dùng. Gọi lúc rỗng thì check, không ném.
template <class Signature>
class MoveOnlyFunction;

template <class R, class... Args>
class MoveOnlyFunction<R(Args...)> {
public:
    static constexpr bool kIsFallback = false;

    MoveOnlyFunction() = default;
    MoveOnlyFunction(MoveOnlyFunction&&) noexcept = default;
    MoveOnlyFunction& operator=(MoveOnlyFunction&&) noexcept = default;
    MoveOnlyFunction(const MoveOnlyFunction&) = delete;
    MoveOnlyFunction& operator=(const MoveOnlyFunction&) = delete;
    ~MoveOnlyFunction() = default;

    explicit MoveOnlyFunction(std::nullptr_t) noexcept {}

    template <class F>
        requires(!std::same_as<std::remove_cvref_t<F>, MoveOnlyFunction> &&
            std::constructible_from<std::move_only_function<R(Args...)>, F>)
    // Chuyển ngầm từ lambda là hợp đồng của tham số (lệch API-04).
    // NOLINTNEXTLINE(cppcoreguidelines-explicit-constructor,misc-explicit-constructor)
    MoveOnlyFunction(F&& function) : call_(std::forward<F>(function)) {}

    MoveOnlyFunction& operator=(std::nullptr_t) noexcept {
        call_ = nullptr;
        return *this;
    }

    [[nodiscard]] R operator()(Args... args) {
        check(call_ != nullptr, "gọi hàm rỗng");
        return call_(std::forward<Args>(args)...);
    }

    [[nodiscard]] explicit operator bool() const noexcept { return static_cast<bool>(call_); }

private:
    std::move_only_function<R(Args...)> call_;
};

// Cùng hợp đồng với nhánh tự cài: chữ ký const cũng check khi rỗng, không ném.
template <class R, class... Args>
class MoveOnlyFunction<R(Args...) const> {
public:
    static constexpr bool kIsFallback = false;

    MoveOnlyFunction() = default;
    MoveOnlyFunction(MoveOnlyFunction&&) noexcept = default;
    MoveOnlyFunction& operator=(MoveOnlyFunction&&) noexcept = default;
    MoveOnlyFunction(const MoveOnlyFunction&) = delete;
    MoveOnlyFunction& operator=(const MoveOnlyFunction&) = delete;
    ~MoveOnlyFunction() = default;

    explicit MoveOnlyFunction(std::nullptr_t) noexcept {}

    template <class F>
        requires(!std::same_as<std::remove_cvref_t<F>, MoveOnlyFunction> &&
            std::constructible_from<std::move_only_function<R(Args...) const>, F>)
    // Chuyển ngầm từ lambda là hợp đồng của tham số (lệch API-04).
    // NOLINTNEXTLINE(cppcoreguidelines-explicit-constructor,misc-explicit-constructor)
    MoveOnlyFunction(F&& function) : call_(std::forward<F>(function)) {}

    MoveOnlyFunction& operator=(std::nullptr_t) noexcept {
        call_ = nullptr;
        return *this;
    }

    [[nodiscard]] R operator()(Args... args) const {
        check(call_ != nullptr, "gọi hàm rỗng");
        return call_(std::forward<Args>(args)...);
    }

    [[nodiscard]] explicit operator bool() const noexcept { return static_cast<bool>(call_); }

private:
    std::move_only_function<R(Args...) const> call_;
};

} // namespace game::core

#else

#include <memory>
#include <type_traits>

namespace game::core {

template <class Signature>
class MoveOnlyFunction;

namespace detail {

template <class R, class... Args>
struct CallConcept {
    CallConcept() = default;
    CallConcept(const CallConcept&) = delete;
    CallConcept& operator=(const CallConcept&) = delete;
    CallConcept(CallConcept&&) = delete;
    CallConcept& operator=(CallConcept&&) = delete;
    virtual ~CallConcept() = default;
    [[nodiscard]] virtual R call(Args... args) = 0;
};

template <class F, class R, class... Args>
struct CallModel final : CallConcept<R, Args...> {
    // Nhận theo giá trị: callable const vẫn sao chép được, callable chỉ chuyển thì chuyển.
    explicit CallModel(F function) : function_(std::move(function)) {}

    [[nodiscard]] R call(Args... args) override { return function_(std::forward<Args>(args)...); }

private:
    F function_;
};

template <class R, class... Args>
struct CallConceptConst {
    CallConceptConst() = default;
    CallConceptConst(const CallConceptConst&) = delete;
    CallConceptConst& operator=(const CallConceptConst&) = delete;
    CallConceptConst(CallConceptConst&&) = delete;
    CallConceptConst& operator=(CallConceptConst&&) = delete;
    virtual ~CallConceptConst() = default;
    [[nodiscard]] virtual R call(Args... args) const = 0;
};

template <class F, class R, class... Args>
struct CallModelConst final : CallConceptConst<R, Args...> {
    explicit CallModelConst(F function) : function_(std::move(function)) {}

    [[nodiscard]] R call(Args... args) const override { return function_(std::forward<Args>(args)...); }

private:
    F function_;
};

} // namespace detail

// Gọi khi rỗng thì core::check, không ném bad_function_call như std::move_only_function.
template <class R, class... Args>
class MoveOnlyFunction<R(Args...)> {
public:
    static constexpr bool kIsFallback = true;

    MoveOnlyFunction() = default;
    MoveOnlyFunction(MoveOnlyFunction&&) noexcept = default;
    MoveOnlyFunction& operator=(MoveOnlyFunction&&) noexcept = default;
    MoveOnlyFunction(const MoveOnlyFunction&) = delete;
    MoveOnlyFunction& operator=(const MoveOnlyFunction&) = delete;
    ~MoveOnlyFunction() = default;

    explicit MoveOnlyFunction(std::nullptr_t) noexcept {}

    template <class F>
        requires std::invocable<std::decay_t<F>&, Args...>
    // Chuyển ngầm từ lambda là hợp đồng của tham số (lệch API-04).
    // NOLINTNEXTLINE(cppcoreguidelines-explicit-constructor,misc-explicit-constructor)
    MoveOnlyFunction(F&& function) : call_(make_call(std::forward<F>(function))) {}

    MoveOnlyFunction& operator=(std::nullptr_t) noexcept {
        call_.reset();
        return *this;
    }

    [[nodiscard]] R operator()(Args... args) {
        check(call_ != nullptr, "gọi hàm rỗng");
        return call_->call(std::forward<Args>(args)...);
    }

    [[nodiscard]] explicit operator bool() const noexcept { return call_ != nullptr; }

private:
    using Concept = detail::CallConcept<R, Args...>;

    template <class F>
    [[nodiscard]] static std::unique_ptr<Concept> make_call(F&& function) {
        using Value = std::decay_t<F>;
        using Model = detail::CallModel<Value, R, Args...>;
        return std::make_unique<Model>(std::forward<F>(function));
    }

    std::unique_ptr<Concept> call_;
};

template <class R, class... Args>
class MoveOnlyFunction<R(Args...) const> {
public:
    static constexpr bool kIsFallback = true;

    MoveOnlyFunction() = default;
    MoveOnlyFunction(MoveOnlyFunction&&) noexcept = default;
    MoveOnlyFunction& operator=(MoveOnlyFunction&&) noexcept = default;
    MoveOnlyFunction(const MoveOnlyFunction&) = delete;
    MoveOnlyFunction& operator=(const MoveOnlyFunction&) = delete;
    ~MoveOnlyFunction() = default;

    explicit MoveOnlyFunction(std::nullptr_t) noexcept {}

    template <class F>
        requires std::invocable<const std::decay_t<F>&, Args...>
    // Chuyển ngầm từ lambda là hợp đồng của tham số (lệch API-04).
    // NOLINTNEXTLINE(cppcoreguidelines-explicit-constructor,misc-explicit-constructor)
    MoveOnlyFunction(F&& function) : call_(make_call(std::forward<F>(function))) {}

    MoveOnlyFunction& operator=(std::nullptr_t) noexcept {
        call_.reset();
        return *this;
    }

    [[nodiscard]] R operator()(Args... args) const {
        check(call_ != nullptr, "gọi hàm rỗng");
        return call_->call(std::forward<Args>(args)...);
    }

    [[nodiscard]] explicit operator bool() const noexcept { return call_ != nullptr; }

private:
    using Concept = detail::CallConceptConst<R, Args...>;

    template <class F>
    [[nodiscard]] static std::unique_ptr<Concept> make_call(F&& function) {
        using Value = std::decay_t<F>;
        using Model = detail::CallModelConst<Value, R, Args...>;
        return std::make_unique<Model>(std::forward<F>(function));
    }

    std::unique_ptr<Concept> call_;
};

} // namespace game::core

#endif
