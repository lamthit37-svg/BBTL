--福运案牍
local SpringFestival_Collection_Frame_UnifiedPosition;
local g_Text = {}
local g_isHave = {}
local g_NPC = {
	[1] = {name = "高海", posX = 242, posZ = 347,},
	[2] = {name = "墨琉", posX = 242, posZ = 345,},
	[3] = {name = "佘离", posX = 245, posZ = 345,},
	[4] = {name = "殷阪", posX = 244, posZ = 346,},
	[5] = {name = "陈弘海", posX = 244, posZ = 337,},
}
local g_ActionButton = {}
local g_Item = {38005634, 38005635, 38005636, 38005637,}
--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function SpringFestival_Collection_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED" , false);		-- 离开场景
end

--=========================================================
-- 载入初始化
--=========================================================
function SpringFestival_Collection_OnLoad()
	
	g_Text[1] = SpringFestival_Collection_Page_Lace1Item_Tip
	g_Text[2] = SpringFestival_Collection_Page_Lace2Item_Tip
	g_Text[3] = SpringFestival_Collection_Page_Lace3Item_Tip
	g_Text[4] = SpringFestival_Collection_Page_Lace4Item_Tip
	
	g_ActionButton[1] = SpringFestival_Collection_Page_Lace1Item
	g_ActionButton[2] = SpringFestival_Collection_Page_Lace2Item
	g_ActionButton[3] = SpringFestival_Collection_Page_Lace3Item
	g_ActionButton[4] = SpringFestival_Collection_Page_Lace4Item

	SpringFestival_Collection_Frame_UnifiedPosition = SpringFestival_Collection_Frame_BK:GetProperty("UnifiedPosition");
end

--=========================================================
-- 事件处理
--=========================================================
function SpringFestival_Collection_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 88887101) then 
		g_isHave[1] = Get_XParam_INT(0)
		g_isHave[2] = Get_XParam_INT(1)
		g_isHave[3] = Get_XParam_INT(2)
		g_isHave[4] = Get_XParam_INT(3)
		this:Show()
		SpringFestival_Collection_ShowFrame()
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 88887102) then 
    	if Get_XParam_INT(0) == 1 then
    		if(not this:IsVisible()) then
    			return
    		end
    		g_isHave[1] = Get_XParam_INT(1)
			g_isHave[2] = Get_XParam_INT(2)
			g_isHave[3] = Get_XParam_INT(3)
			g_isHave[4] = Get_XParam_INT(4)
			this:Show()
			SpringFestival_Collection_ShowFrame()
    		return
    	elseif Get_XParam_INT(0) == 2 then
    		--导航
    		local index = Get_XParam_INT(1)
    		SpringFestival_Collection_Goto(index)
    	elseif Get_XParam_INT(0) == 3 then
    		SpringFestival_Collection_OnHidden()
    	elseif Get_XParam_INT(0) == 4 then
    		SpringFestival_Collection_GoToTargetPlace()
    		SpringFestival_Collection_OnHidden()
    	end
    	
	elseif (event == "ADJEST_UI_POS" ) then
		SpringFestival_Collection_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_Collection_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		SpringFestival_Collection_OnHidden()
	end
end

function SpringFestival_Collection_Goto(index)

	if index < 1 or index > 5 then
		PushDebugMessage("无法自动寻路")
		return
	end
	local bRet = AutoRuntoTargetExWithName(g_NPC[index].posX, g_NPC[index].posZ, 0, g_NPC[index].name)
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end

end

function SpringFestival_Collection_Clear()
	for i = 1, 4 do
		g_Text[i]:SetText("")
		g_isHave[i] = 0
		g_ActionButton[i]:SetActionItem(-1);
	end
end

--=========================================================
-- 界面控件数据
--=========================================================
function SpringFestival_Collection_ShowFrame()
	for i = 1, 4 do
		if g_isHave[i] == 1 then
			local tips = ScriptGlobal_Format("#{CJYJ_211203_140}", "#M"..tostring(1))
			g_Text[i]:SetText(tips)
		else
			local tips = ScriptGlobal_Format("#{CJYJ_211203_140}", "#cff0000"..tostring(0))
			g_Text[i]:SetText(tips)
		end
		local theAction = DataPool:CreateActionItemForShow(g_Item[i], 1)
		if theAction:GetID() ~= 0 then
			g_ActionButton[i]:SetActionItem(theAction:GetID());
			g_ActionButton[i]:Show()
		end
	end
end

--=========================================================
-- 关闭界面
--=========================================================
function SpringFestival_Collection_OnHidden()
	SpringFestival_Collection_Clear()
	this:Hide()
end


function SpringFestival_Collection_On_ResetPos()
  	SpringFestival_Collection_Frame_BK:SetProperty("UnifiedPosition", SpringFestival_Collection_Frame_UnifiedPosition);
end

function SpringFestival_Collection_OnClick()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnCall")
		Set_XSCRIPT_ScriptID(888873)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

function SpringFestival_Collection_ShowHelp()
	PushEvent("CCSHOP_HELP", 143)
end

function SpringFestival_Collection_OnActionItemClicked(idx)

end

function SpringFestival_Collection_GoToTargetPlace()
	PushEvent("CCSHOP_HELP", 144)
end
