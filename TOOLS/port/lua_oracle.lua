-- Môi trường giả cho script giao diện của client 2026, chạy trên chính LuaPlus.dll của nó (Lua
-- 5.0.1 có thêm `continue`). TOOLS/port/lua_oracle.py nạp tệp này trước script gốc.
-- Mọi cửa sổ của layout là một biến toàn cục mang trạng thái mà script đặt (chữ, hiện hay ẩn, đánh
-- dấu, mục của danh sách, phần tử của cửa sổ phức hợp). Hàm của game (DataPool, Player,
-- EnumAction...) do tệp kịch bản định nghĩa; gọi một hàm hay phương thức chưa mô phỏng là lỗi, để
-- không có giá trị mặc định nào lẻn vào số vàng.
-- Hành vi của từng phương thức theo lớp nối Lua của UI_CEGUI.dll (docs/NHIEM-VU-VO-CONG-2026.md).
-- Tệp ra chỉ nêu thứ script ĐÃ ĐỤNG tới (đã gọi hàm đặt nó ít nhất một lần), kèm giá trị cuối:
-- bản port giữ đúng tập đó trong panel::Widgets nên so được từng dòng mà không cần layout.

__windows = {}
__tables = {}
__order = {}
__calls = {}
__this = { visible = false, events = {} }

-- Ghi một việc script nhờ game làm (PushDebugMessage, PushEvent, OpenWindow...), theo thứ tự gọi.
function __note(...)
    local parts = {}
    for index = 1, arg.n do
        parts[index] = tostring(arg[index])
    end
    table.insert(__calls, table.concat(parts, "\t"))
end

local methods = {}

local function record(self)
    return __windows[self.__name]
end

-- Đặt một trường trạng thái (không phải thuộc tính) và đánh dấu đã đụng.
local function put(self, field, value)
    local own = record(self)
    own[field] = value
    own.touched[field] = true
end

local function put_prop(self, name, value)
    local own = record(self)
    own.props[name] = tostring(value)
    own.set[name] = true
end

function methods.Show(self) put(self, "visible", true) end
function methods.Hide(self) put(self, "visible", false) end
function methods.IsVisible(self) return record(self).visible end
function methods.Enable(self) put(self, "disabled", false) end
function methods.Disable(self) put(self, "disabled", true) end
function methods.SetText(self, text) put_prop(self, "Text", text) end
function methods.GetText(self) return record(self).props.Text or "" end
function methods.SetToolTip(self, text) put_prop(self, "Tooltip", text) end
function methods.SetProperty(self, name, value) put_prop(self, name, value) end
-- Cửa sổ mesh: tên fake object đang hiện (rỗng là không hiện gì).
function methods.SetFakeObject(self, name) put_prop(self, "FakeObject", name) end
-- Độ trong của cửa sổ. Trọng tài không có đồng hồ: StartFade tới đích ngay, và ghi đích đó thành
-- thuộc tính Alpha, nên GetAlpha sau một lần mờ dần trả đúng số mà client gốc trả khi đoạn mờ dần
-- đã chạy xong.
function methods.GetAlpha(self) return record(self).alpha or 1 end
function methods.StartFade(self, from, to, seconds)
    record(self).alpha = to
    put_prop(self, "Alpha", to)
end

-- Vị trí mà layout không ghi thẳng dưới tên được hỏi (CEGUI tính nó từ thuộc tính khác): trả một
-- dấu "@layout:<tên>", nghĩa là "giá trị của layout"; script chỉ cất nó để trả cửa sổ về chỗ cũ.
local derived = { UnifiedXPosition = true, UnifiedYPosition = true, UnifiedPosition = true }
function methods.GetProperty(self, name)
    local value = record(self).props[name]
    if value ~= nil then return value end
    if derived[name] then return "@layout:" .. name end
    error("layout không có thuộc tính " .. tostring(name) .. " ở " .. self.__name, 2)
end

-- Nút đánh dấu của TLBB là lớp FalagardCheckButton của CEGUIFalagard.dll. Nút có CheckMode 1 được
-- bật thì mọi nút đánh dấu cùng cha bị tắt, dù chúng mang CheckMode nào: setCheck (0x1800d31a0) gọi
-- setCheck(false) cho từng nút anh em, onMouseButtonUp (0x1800d2ed0) ghi thẳng cờ của chúng.
local function clear_siblings(name)
    local own = __windows[name]
    for _, other in ipairs(__order) do
        local sibling = __windows[other]
        if other ~= name and sibling.is_check and sibling.parent == own.parent then
            sibling.checked = false
            sibling.touched.checked = true
        end
    end
end

local function set_check(name, is_on)
    local own = __windows[name]
    own.checked = is_on
    own.touched.checked = true
    if is_on and own.props.CheckMode == "1" then clear_siblings(name) end
end

-- SetCheck nhận số, GetCheck trả 1 hay 0.
function methods.SetCheck(self, state) set_check(self.__name, state == 1) end
function methods.GetCheck(self)
    if record(self).checked then return 1 end
    return 0
end

-- Nút action.
function methods.SetActionItem(self, id) put(self, "action", id) end
function methods.SetPushed(self, state) put(self, "pushed", state == 1) end
function methods.SetNewFlash(self) put(self, "flash", true) end
-- DoAction (UI_CEGUI 3.71.9509 0x180028c00): ô trống (không có action) thì không làm gì.
function methods.DoAction(self)
    local action = record(self).action
    if action ~= nil and action ~= -1 then __note("DoAction", self.__name, action) end
end
function methods.PlayWarning(self, state) put(self, "warning", state) end
-- Gloom() và Bright() đặt thuộc tính Gloom True và False (docs/GIAO-DIEN-2026.md 2.7).
function methods.Gloom(self) put_prop(self, "Gloom", "True") end
function methods.Bright(self) put_prop(self, "Gloom", "False") end
-- GetActionItem (UI_CEGUI 3.71.9509 0x180028f00): id action đang giữ, -1 khi ô trống.
function methods.GetActionItem(self)
    local action = record(self).action
    if action == nil then return -1 end
    return action
end
-- Play(loop) của cửa sổ hoạt ảnh TLBB_Animate (UI_CEGUI 0x180029530: gọi ô ảo 0 của giao diện hoạt ảnh).
function methods.Play(self, loop) put(self, "playing", loop) end

-- Danh sách: mỗi mục giữ chữ, id và màu; mục được chọn tra theo id.
function methods.ClearListBox(self)
    local own = record(self)
    own.items = {}
    own.selected = nil
    own.first = 0
    own.touched.items = true
end
function methods.AddItem(self, text, id, colour)
    local own = record(self)
    table.insert(own.items, { text = tostring(text), id = id, colour = colour or "" })
    own.touched.items = true
end
function methods.GetFirstSelectItem(self)
    local own = record(self)
    if own.selected == nil then return -1 end
    return own.items[own.selected].id
end
function methods.SetItemSelectByItemID(self, id)
    local own = record(self)
    for index, item in ipairs(own.items) do
        if item.id == id then
            own.selected = index
            return
        end
    end
end
function methods.GetCurrentFirstItem(self) return record(self).first or 0 end
function methods.SetCurrentFirstItem(self, index) put(self, "first", index) end
function methods.GetClickItem(self) return record(self).clicked or -1 end

-- Cửa sổ phức hợp.
local function add_element(self, line)
    local own = record(self)
    table.insert(own.elements, line)
    own.touched.elements = true
end
function methods.ClearAllElement(self)
    local own = record(self)
    own.elements = {}
    own.touched.elements = true
end
function methods.AddTextElement(self, text) add_element(self, "text\t" .. tostring(text)) end
function methods.AddMoneyElement(self, amount) add_element(self, "money\t" .. tostring(amount)) end
function methods.AddJiaoZiElement(self, amount) add_element(self, "jiaozi\t" .. tostring(amount)) end
function methods.AddActionElement(self, action, count, radio, extra)
    local line = "action\t" .. tostring(action) .. "\t" .. tostring(count) .. "\t" .. tostring(radio)
    if extra ~= nil then line = line .. "\t" .. tostring(extra) end
    add_element(self, line)
end
function methods.SetScrollPosition(self) put(self, "scroll", "Keep") end
function methods.ResetScrollPosition(self) put(self, "scroll", "Reset") end

local window_meta = {
    __index = function(self, key)
        local found = methods[key]
        if found == nil then
            error("phương thức cửa sổ chưa mô phỏng: " .. tostring(key) .. " ở " .. rawget(self, "__name"), 2)
        end
        return found
    end,
}

-- Tạo cửa sổ name với các thuộc tính của layout và các sự kiện layout nối vào script (tên sự kiện
-- sang đoạn Lua). parent là tên cửa sổ cha trong layout (rỗng với cửa sổ gốc); is_check là cửa sổ
-- thuộc kiểu nút đánh dấu.
function __window(name, props, events, parent, is_check)
    local visible = true
    if props.Visible == "False" or props.Visible == "false" then visible = false end
    __windows[name] = {
        props = props, events = events, visible = visible, disabled = false, checked = false,
        items = {}, elements = {}, first = 0, set = {}, touched = {}, parent = parent, is_check = is_check,
    }
    table.insert(__order, name)
    local proxy = { __name = name }
    setmetatable(proxy, window_meta)
    rawset(_G, name, proxy)
end

-- Chạy đoạn Lua mà layout nối vào sự kiện event của cửa sổ name (mặc định Clicked).
function __fire(name, event)
    local own = __windows[name]
    if own == nil then error("layout không có cửa sổ " .. tostring(name), 2) end
    local code = own.events[event or "Clicked"]
    if code == nil then error(name .. " không nối sự kiện " .. tostring(event or "Clicked"), 2) end
    local chunk, problem = loadstring(code, "=" .. name)
    if chunk == nil then error(problem, 2) end
    chunk()
end

-- Người chơi bấm trái một nút đánh dấu. Lúc nhấn (onMouseButtonDown 0x1800d2e50): nút CheckMode 1
-- hay 2 đang bật thì giữ nguyên, còn lại đảo dấu. Lúc nhả (onMouseButtonUp 0x1800d2ed0): nút
-- CheckMode 1 đang bật thì tắt các nút đánh dấu cùng cha, rồi mới phát Clicked. Sự kiện khác
-- Clicked (MouseLButtonDown) phát lúc nhấn, sau khi dấu đã đổi và trước khi các nút cùng cha bị tắt.
function __check(name, event)
    local own = __windows[name]
    if own == nil then error("layout không có cửa sổ " .. tostring(name), 2) end
    local mode = own.props.CheckMode
    local stays = (mode == "1" or mode == "2") and own.checked
    if not stays then own.checked = not own.checked end
    own.touched.checked = true
    local on_press = event ~= nil and event ~= "Clicked"
    if on_press then __fire(name, event) end
    if mode == "1" and own.checked then clear_siblings(name) end
    if not on_press then __fire(name, event) end
end

-- Người chơi bấm một ô đánh dấu thường (CheckMode 0): dấu đảo rồi script nghe sự kiện.
function __toggle(name, event)
    local own = __windows[name]
    own.checked = not own.checked
    own.touched.checked = true
    __fire(name, event)
end

-- Người chơi bấm mục mang id của một danh sách: mục đó thành mục được chọn và mục vừa bấm, rồi
-- script nghe ItemSelectionChanged.
function __pick(name, id)
    local own = __windows[name]
    own.selected = nil
    own.clicked = id
    for index, item in ipairs(own.items) do
        if item.id == id then
            own.selected = index
            break
        end
    end
    __fire(name, "ItemSelectionChanged")
end

-- Đối tượng `this` của script: cả cửa sổ gốc. Lúc nạp client gốc giấu mọi bảng.
this = {}
function this:Show() __this.visible = true end
function this:Hide() __this.visible = false end
function this:TogleShow() __this.visible = not __this.visible end
function this:IsVisible() return __this.visible end
function this:RegisterEvent(name) table.insert(__this.events, name) end

-- Biến toàn cục chưa định nghĩa: báo ngay tên, thay vì để script chạy tiếp với nil. Kịch bản kê
-- vào __optional những tên mà chính script gốc đọc khi chưa gán (lỗi của script gốc, giá trị nil là
-- hành vi thật), kèm lý do.
__optional = { arg0 = true, arg1 = true, arg2 = true, arg3 = true, arg4 = true, arg5 = true, arg6 = true,
    arg7 = true, arg8 = true, arg9 = true }
setmetatable(_G, {
    __index = function(_, key)
        if __optional[key] then return nil end
        error("tên chưa mô phỏng: " .. tostring(key), 2)
    end,
})

-- Giá trị trên một dòng: gạch chéo ngược, xuống dòng và về đầu dòng viết thành hai ký tự (gạch
-- chéo ngược rồi gạch chéo ngược, n hay r), để mỗi dòng của tệp ra là đúng một thuộc tính.
local function flat(value)
    local text = string.gsub(tostring(value), "\\", "\\\\")
    text = string.gsub(text, "\n", "\\n")
    text = string.gsub(text, "\r", "\\r")
    return text
end

local function truth(value)
    if value then return "True" end
    return "False"
end

local function emit_window(name)
    local own = __windows[name]
    local keys = {}
    for key in pairs(own.set) do table.insert(keys, key) end
    table.sort(keys)
    for _, key in ipairs(keys) do
        __emit(name .. "\t" .. key .. "\t" .. flat(own.props[key]))
    end
    local touched = own.touched
    if touched.visible then __emit(name .. "\tVisible\t" .. truth(own.visible)) end
    if touched.disabled then __emit(name .. "\tDisabled\t" .. truth(own.disabled)) end
    if touched.checked then __emit(name .. "\tSelected\t" .. truth(own.checked)) end
    if touched.pushed then __emit(name .. "\tPushed\t" .. truth(own.pushed)) end
    if touched.action then __emit(name .. "\tActionItem\t" .. tostring(own.action)) end
    if touched.flash then __emit(name .. "\tNewFlash\tTrue") end
    if touched.playing then __emit(name .. "\tPlaying\t" .. truth(own.playing)) end
    if touched.first then __emit(name .. "\tFirstItem\t" .. tostring(own.first)) end
    if touched.scroll then __emit(name .. "\tScroll\t" .. own.scroll) end
    if touched.items then __emit(name .. "\tItems\t" .. table.getn(own.items)) end
    for index, item in ipairs(own.items) do
        local head = name .. "\tItem" .. index .. "\t" .. tostring(item.id) .. "\t" .. item.colour
        __emit(head .. "\t" .. flat(item.text))
    end
    if own.selected ~= nil then
        __emit(name .. "\tSelectedItem\t" .. tostring(own.items[own.selected].id))
    end
    if touched.elements then __emit(name .. "\tElements\t" .. table.getn(own.elements)) end
    for index, element in ipairs(own.elements) do
        __emit(name .. "\tElement" .. index .. "\t" .. flat(element))
    end
end

-- Ghi trạng thái hiện tại: cửa sổ gốc, từng cửa sổ theo thứ tự của layout, rồi các việc đã nhờ.
function __dump(label)
    __emit("# " .. label)
    __emit("this\tVisible\t" .. truth(__this.visible))
    for _, name in ipairs(__order) do emit_window(name) end
    for index, line in ipairs(__calls) do
        __emit("!call" .. index .. "\t" .. flat(line))
    end
    __calls = {}
end
