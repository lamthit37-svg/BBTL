// Cầu nối từ Model (GLB đã nạp) sang hệ xương theo OGRE 1.2.5 của anim/: nút xương thành
// anim::SourceSkeleton, clip thành anim::Animation với khoá là ĐỘ LỆCH so với bind pose.
// Quy ước của cây GLB do TOOLS/glb dựng: chỉ số nút của xương bằng handle của nó, tư thế gốc của
// xương là tịnh tiến, xoay, tỉ lệ nguyên văn của tệp .skeleton, và khoá animation là giá trị tuyệt
// đối đã ghép với tư thế gốc theo NodeAnimationTrack::applyToNode (dịch = gốc + khoá; xoay = gốc
// nhân khoá; tỉ lệ = gốc nhân khoá). Ở đây làm phép ngược để anim::apply cộng dồn lại đúng như
// OGRE, lên bind pose của skeleton CHÍNH của mô hình (có thể khác bind pose của tệp chứa clip: tệp
// clip của nữ lệch tư thế gốc tới 0,3 đơn vị).
// Bản mới của dự án, không port từ nơi khác; tương ứng phần đọc .tlskel và .tlanim ở
// render/asset_file của TLBB Dev, nơi dữ liệu đã là khoá độ lệch.
#pragma once

#include "anim/asset.hpp"
#include "core/error.hpp"
#include "resource/model.hpp"

#include <cstddef>

namespace game::resource {

// Xương của model. Có skin thì các khớp của skin đầu, không thì mọi nút; chỉ số nút phải bằng
// handle (liền từ 0) và xương khai bằng tịnh tiến, xoay, tỉ lệ. Cạnh cha con lấy từ children của
// nút.
[[nodiscard]] core::Result<anim::SourceSkeleton> bones_of(const Model& model);

// Clip thứ index của model thành animation của OGRE. own là xương của chính model chứa clip (từ
// bones_of): khoá tuyệt đối trừ ngược tư thế gốc của own. Mọi kênh của một nút phải chung thời
// điểm, nội suy tuyến tính. Độ dài là thời điểm khoá muộn nhất.
[[nodiscard]] core::Result<anim::Animation> animation_of(const Model& model, std::size_t index,
    const anim::SourceSkeleton& own);

} // namespace game::resource
