-- Hàm của game mà MainMenuBar_2.lua gọi ngoài bộ dùng chung ui_common_api.lua, action_bar_api.lua và
-- main_menu_bar_4_api.lua (TLCJ:IsInTLCJScene), cho nhánh hướng dẫn tân thủ của UI_COMMAND 20130527:
--   Get_XParam_INT 0x140240ea0 (đối số của lệnh UI, kịch bản đặt vào __xparam),
--   PutItemToMainmenuBar2 0x140267ae0 (đặt vật phẩm lên ô trống của thanh, trả isShow và chỉ số ô; kịch bản đặt vào __put),
--   GetFreshManGuideOwner 0x1402621b0 (__guide_owner), OpenFreshManGuideNew 0x1402649e0 và CloseFreshManGuide 0x140262120
--   (chỉ ghi lại lời gọi), this:GetChildOffset (UI_CEGUI; độ lệch ô con so với khung, kịch bản đặt bằng __place_button) và
--   thuộc tính tuyệt đối AbsoluteXPosition, AbsoluteYPosition của khung và AbsoluteWidth, AbsoluteHeight của ô (CEGUI tính từ
--   layout và màn hình; kịch bản đặt bằng __place_frame và __place_button).
__xparam = 0
__put = { is_show = 0, index = -1 }
__guide_owner = ""
__offsets = {}

function Get_XParam_INT(slot) return __xparam end
function PutItemToMainmenuBar2(item) return __put.is_show, __put.index end
function GetFreshManGuideOwner() return __guide_owner end
function OpenFreshManGuideNew(...) __note("OpenFreshManGuideNew", unpack(arg)) end
function CloseFreshManGuide() __note("CloseFreshManGuide") end

-- Vị trí tuyệt đối của khung.
function __place_frame(x, y)
    local frame = __windows["MainMenuBar_2_Frame"]
    frame.props.AbsoluteXPosition = tostring(x)
    frame.props.AbsoluteYPosition = tostring(y)
end

-- Ô thứ k (1..10): độ lệch so với khung và kích thước.
function __place_button(k, x, y, width, height)
    local name = "MainMenuBar_2_Button_Action" .. k
    __offsets[name] = { x = x, y = y }
    __windows[name].props.AbsoluteWidth = tostring(width)
    __windows[name].props.AbsoluteHeight = tostring(height)
end

function this:GetChildOffset(name)
    local offset = __offsets[name]
    return offset.x, offset.y
end
