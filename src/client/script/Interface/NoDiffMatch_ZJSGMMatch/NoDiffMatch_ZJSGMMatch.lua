-- 总决赛GM比赛操作界面
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function NoDiffMatch_ZJSGMMatch_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_ZJSGMMatch_InitData()
	NoDiffMatch_ZJSGMMatch_Input1:SetText("")
	NoDiffMatch_ZJSGMMatch_Input2:SetText("")
	NoDiffMatch_ZJSGMMatch_select:ResetList();
	NoDiffMatch_ZJSGMMatch_select:AddTextItem("", 0);
	NoDiffMatch_ZJSGMMatch_select:AddTextItem("#{WCJS_180522_86}", 1);
	NoDiffMatch_ZJSGMMatch_select:AddTextItem("#{WCJS_180522_87}", 2);
	NoDiffMatch_ZJSGMMatch_select:AddTextItem("#{WCJS_180522_88}", 3);
	NoDiffMatch_ZJSGMMatch_select:AddTextItem("#{WCJS_180522_89}", 4);
	NoDiffMatch_ZJSGMMatch_select:AddTextItem("#{WCJS_180522_90}", 5);
	NoDiffMatch_ZJSGMMatch_select:AddTextItem("#{WCJS_180522_91}", 6);
	NoDiffMatch_ZJSGMMatch_select:AddTextItem("#{WCJS_180522_92}", 7);
	NoDiffMatch_ZJSGMMatch_select:AddTextItem("#{WCJS_180522_93}", 8);
	NoDiffMatch_ZJSGMMatch_select:SetCurrentSelect(0);
end

function NoDiffMatch_ZJSGMMatch_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_ZJSGMMatch_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_ZJSGMMatch_Frame:GetProperty("UnifiedYPosition");

	NoDiffMatch_ZJSGMMatch_InitData()
end

function NoDiffMatch_ZJSGMMatch_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_ZJSGMMatch_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		NoDiffMatch_ZJSGMMatch_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		NoDiffMatch_ZJSGMMatch_InitData()
		this:Hide()
	elseif (event == "UI_COMMAND") then
		if tonumber(arg0) == 89270201 then
			this:Show()
		end
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_ZJSGMMatch_ResetPos()
	NoDiffMatch_ZJSGMMatch_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_ZJSGMMatch_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
function NoDiffMatch_ZJSGMMatch_Submit_Clicked()

	local nCorpA_ID = NoDiffMatch_ZJSGMMatch_Input1:GetText()
	local nCorpB_ID = NoDiffMatch_ZJSGMMatch_Input2:GetText()

	if nCorpA_ID == nil or nCorpB_ID == nil or nCorpA_ID == "" or nCorpB_ID == "" then
		PushDebugMessage("比赛双方的ID不能为空")
		return
	end

	if tonumber(nCorpA_ID) == nil or tonumber(nCorpB_ID) == nil then
		PushDebugMessage("比赛双方的ID必须为数字")
		return
	end

	local __txt, idx = NoDiffMatch_ZJSGMMatch_select:GetCurrentSelect();
	if idx <= 0 then
		PushDebugMessage("请选择比赛场地")
		return
	end

	--增加接口
	--比赛场地、双方战队ID
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnSelectTwoCorpsToBattleField")
		Set_XSCRIPT_ScriptID(892702)
		Set_XSCRIPT_Parameter(0,tonumber(nCorpA_ID));
		Set_XSCRIPT_Parameter(1,tonumber(nCorpB_ID));
		Set_XSCRIPT_Parameter(2,tonumber(idx));
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT()

	this:Hide()
end

function NoDiffMatch_ZJSGMMatch_Cancel_Clicked()
	this:Hide()
end
