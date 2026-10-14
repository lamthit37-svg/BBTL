--获奖界面
local SpringFestival_WHY_Frame_UnifiedPosition;
local g_Item = 0
--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function SpringFestival_WHY_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED" , false);		-- 离开场景
end

--=========================================================
-- 载入初始化
--=========================================================
function SpringFestival_WHY_OnLoad()
	
	SpringFestival_WHY_Frame_UnifiedPosition = SpringFestival_WHY_Frame:GetProperty("UnifiedPosition");
end

--=========================================================
-- 事件处理
--=========================================================
function SpringFestival_WHY_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 88889201) then 
		SpringFestival_WHY_Clear()
		g_Item = Get_XParam_INT(0)
		SetTimer("SpringFestival_WHY","SpringFestival_WHY_ShowFrame()", 500)
		--SpringFestival_WHY_ShowFrame()
	elseif (event == "ADJEST_UI_POS" ) then
		SpringFestival_WHY_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_WHY_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		SpringFestival_WHY_OnHidden()
	end
end


function SpringFestival_WHY_Clear()
	g_Item = 0
	SpringFestival_WHY_Bag_Item:SetActionItem(-1);
	SpringFestival_WHY_Bag_Item_Animate:Hide()
end

--=========================================================
-- 界面控件数据
--=========================================================
function SpringFestival_WHY_ShowFrame()
	KillTimer("SpringFestival_WHY_ShowFrame()")
	if g_Item <= 0 then
		return
	end

	local theAction = DataPool:CreateBindActionItemForShow(g_Item, 1)
	if theAction:GetID() ~= 0 then
		SpringFestival_WHY_Bag_Item:SetActionItem(theAction:GetID());
		SpringFestival_WHY_Bag_Item:Show()
		SpringFestival_WHY_Bag_Item_Animate:Show()
	end
	this:Show()
end

--=========================================================
-- 关闭界面
--=========================================================
function SpringFestival_WHY_OnHidden()
	SpringFestival_WHY_Clear()
	this:Hide()
end


function SpringFestival_WHY_On_ResetPos()
  	SpringFestival_WHY_Frame:SetProperty("UnifiedPosition", SpringFestival_WHY_Frame_UnifiedPosition);
end

function SpringFestival_WHY_OnActionItemClicked(idx)

end

