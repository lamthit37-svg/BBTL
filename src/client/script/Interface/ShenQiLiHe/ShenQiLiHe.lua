--神器盒子
local g_Item1 = 10304426
local g_Item2 = 10305444
local g_Script_FunctionName = "GetAward"
local g_Script_Id = 892325
--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function ShenQiLiHe_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end

--=========================================================
-- 载入初始化
--=========================================================
function ShenQiLiHe_OnLoad()
	local theAction1 = DataPool:CreateActionItemForShow(g_Item1, 1)
	local theAction2 = DataPool:CreateActionItemForShow(g_Item2, 1)
	ShenQiLiHe_Frame_Reward1_Icon:SetActionItem(theAction1:GetID())
	ShenQiLiHe_Frame_Reward2_Icon:SetActionItem(theAction2:GetID())
end

function ShenQiLiHe_OnHiden()
	if(this:IsVisible()) then
		this:Hide()
	end
end

--=========================================================
-- 事件处理
--=========================================================
function ShenQiLiHe_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 892325) then
		this:Show()
	end
end

function ShenQiLiHe_ClickGetReward(index)
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name(g_Script_FunctionName)
	Set_XSCRIPT_ScriptID(g_Script_Id)
	Set_XSCRIPT_Parameter(0,index)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	ShenQiLiHe_OnHiden()
end




