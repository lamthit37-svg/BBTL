--******************************
--比武招亲：祝福界面
--******************************

local g_nObjID = -1

local g_MartialFireWroks_Frame_UnifiedPosition
local g_MartialFireWroks_Item={}
local g_FireWorksID={
39921069,39921070,39921071,39921072
}
local g_YBforFireWorks=120 --全景烟花 120元宝

function MartialFireWroks_PreLoad()
	 this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function MartialFireWroks_OnLoad()
	g_MartialFireWroks_Frame_UnifiedPosition=MartialFireWroks_Frame:GetProperty("UnifiedPosition");
	g_MartialFireWroks_Item={ MartialFireWroks_Bk1_Item1, MartialFireWroks_Bk2_Item1, MartialFireWroks_Bk3_Item1, MartialFireWroks_Bk4_Item1 }
end


function MartialFireWroks_OnEvent(event)
	if event == "UI_COMMAND" then
		if tonumber(arg0) ~= 5090880 then
			return
		end
		local targetId=Get_XParam_INT(0)
		g_nObjID = Target:GetServerId2ClientId(targetId)
		if not g_nObjID or g_nObjID < 0 then
			return
		end
		this:CareObject(g_nObjID, 1)
		MartialFireWroks_Update()
		this:Show()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		MartialFireWroks_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MartialFireWroks_ResetPos()
	end
end

function MartialFireWroks_ResetPos()
	MartialFireWroks_Frame:SetProperty("UnifiedPosition", g_MartialFireWroks_Frame_UnifiedPosition);
end

function MartialFireWroks_Update()
	local szName, nLevel, nMenPai, szGuildName, nEquipHH = BWDH:GetCompeMarryCurSponsor()
	local msg=ScriptGlobal_Format("#{BWZQ_160623_294}", szName, g_YBforFireWorks)
	MartialFireWroks_Explain:SetText(msg)
	local theAction,ActionItemID
	for i=1,table.getn(g_FireWorksID) do
		theAction = DataPool:CreateActionItemForShow(g_FireWorksID[i], 1)
		ActionItemID = theAction:GetID()
		g_MartialFireWroks_Item[i]:SetActionItem(ActionItemID)
	end
end

function MartialFireWroks_OnClosed()
	this:Hide()
end

function MartialFireWroks_Bk_Button(nIdx)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnBuyFireWorks");
		Set_XSCRIPT_ScriptID(509088);
		Set_XSCRIPT_Parameter(0, nIdx)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end
