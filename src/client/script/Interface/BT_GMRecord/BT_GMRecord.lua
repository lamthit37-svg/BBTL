-- 总决赛GM比赛操作界面
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function BT_GMRecord_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BT_GMRecord_InitData()
	BT_GMRecord_Input1:SetText("")
	BT_GMRecord_Input2:SetText("")
	BT_GMRecord_ComboList:ResetList();
	BT_GMRecord_ComboList:AddTextItem("", 0);
	BT_GMRecord_ComboList:AddTextItem("争霸赛一号场地", 1);
	BT_GMRecord_ComboList:AddTextItem("争霸赛二号场地", 2);
	BT_GMRecord_ComboList:AddTextItem("争霸赛三号场地", 3);
	BT_GMRecord_ComboList:AddTextItem("争霸赛四号场地", 4);
	BT_GMRecord_ComboList:AddTextItem("争霸赛五号场地", 5);
	BT_GMRecord_ComboList:AddTextItem("争霸赛六号场地", 6);
	BT_GMRecord_ComboList:AddTextItem("争霸赛七号场地", 7);
	BT_GMRecord_ComboList:AddTextItem("争霸赛八号场地", 8);
	BT_GMRecord_ComboList:AddTextItem("争霸赛九号场地", 9);
	BT_GMRecord_ComboList:AddTextItem("争霸赛十号场地", 10);
	
	BT_GMRecord_ComboList:AddTextItem("争霸赛十一号场地", 11);
	BT_GMRecord_ComboList:AddTextItem("争霸赛十二号场地", 12);
	BT_GMRecord_ComboList:AddTextItem("争霸赛十三号场地", 13);
	BT_GMRecord_ComboList:AddTextItem("争霸赛十四号场地", 14);
	BT_GMRecord_ComboList:AddTextItem("争霸赛十五号场地", 15);
	BT_GMRecord_ComboList:AddTextItem("争霸赛十六号场地", 16);
	BT_GMRecord_ComboList:AddTextItem("争霸赛十七号场地", 17);
	BT_GMRecord_ComboList:AddTextItem("争霸赛十八号场地", 18);
	BT_GMRecord_ComboList:AddTextItem("争霸赛十九号场地", 19);
	BT_GMRecord_ComboList:AddTextItem("争霸赛二十号场地", 20);
	
	BT_GMRecord_ComboList:SetCurrentSelect(0);
end

function BT_GMRecord_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BT_GMRecord_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BT_GMRecord_Frame:GetProperty("UnifiedYPosition");

end

function BT_GMRecord_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BT_GMRecord_ResetPos()
		
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BT_GMRecord_ResetPos()
		
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		BT_GMRecord_Close_Clicked()
		
	elseif (event == "UI_COMMAND") then
		if tonumber(arg0) == 29151401 then
			BT_GMRecord_InitData()
			this:Show()
		end
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_GMRecord_ResetPos()
	BT_GMRecord_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_GMRecord_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function BT_GMRecord_Submit_Clicked()

	local nWTeamA_ID = BT_GMRecord_Input1:GetText()
	local nWTeamB_ID = BT_GMRecord_Input2:GetText()

	if nWTeamA_ID == nil or nWTeamB_ID == nil or nWTeamA_ID == "" or nWTeamB_ID == "" then
		PushDebugMessage("比赛双方的ID不能为空")
		return
	end

	if tonumber(nWTeamA_ID) == nil or tonumber(nWTeamB_ID) == nil then
		PushDebugMessage("比赛双方的ID必须为数字")
		return
	end

	local __txt, idx = BT_GMRecord_ComboList:GetCurrentSelect();
	if idx <= 0 then
		PushDebugMessage("请选择比赛场地")
		return
	end

	--增加接口
	--比赛场地、双方战队ID
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnSelectTwoTeamToBattleField")
		Set_XSCRIPT_ScriptID(291514)
		Set_XSCRIPT_Parameter(0, tonumber(nWTeamA_ID));
		Set_XSCRIPT_Parameter(1, tonumber(nWTeamB_ID));
		Set_XSCRIPT_Parameter(2, tonumber(idx));
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT()

	this:Hide()
end

function BT_GMRecord_Close_Clicked()
	BT_GMRecord_InitData()
	this:Hide()
end

function BT_GMRecord_SearchMode_Changed()

end
