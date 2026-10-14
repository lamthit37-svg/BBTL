--FengYun_JinDu_Buy_Frame.lua
local g_FengYun_JinDu_Buy_Frame_UnifiedXPosition
local g_FengYun_JinDu_Buy_Frame_UnifiedYPosition

local g_FengYun_JinDu_Buy_YuanBaoNeedPer=3
local g_FengYun_JinDu_Buy_CurPoint = 0
local g_FengYun_JinDu_Buy_MaxPoint = 0

function FengYun_JinDu_Buy_PreLoad()
	--第二个参数表示界面隐藏时是否响应事件 默认为true
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)

end

function FengYun_JinDu_Buy_OnLoad()
	g_FengYun_JinDu_Buy_Frame_UnifiedXPosition	= FengYun_JinDu_Buy_Frame:GetProperty("UnifiedXPosition");
	g_FengYun_JinDu_Buy_Frame_UnifiedYPosition	= FengYun_JinDu_Buy_Frame:GetProperty("UnifiedYPosition");

end

function FengYun_JinDu_Buy_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99984102) then
		local bShow = Get_XParam_INT(0)
		g_FengYun_JinDu_Buy_CurPoint = Get_XParam_INT(1)
		g_FengYun_JinDu_Buy_MaxPoint = Get_XParam_INT(2)
		if bShow == 1 then
			FengYun_JinDu_Buy_Open(g_FengYun_JinDu_Buy_CurPoint,g_FengYun_JinDu_Buy_MaxPoint)
			this:Show()
		elseif bShow == 2 then
			this:Hide()
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		FengYun_JinDu_Buy_Close_Clicked()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengYun_JinDu_Buy_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		FengYun_JinDu_Buy_On_ResetPos()
	end
end

function FengYun_JinDu_Buy_Close_Clicked()
	this:Hide()
end

function FengYun_JinDu_Buy_OnHiden()
	this:Hide()
end

function FengYun_JinDu_Buy_On_ResetPos()
	FengYun_JinDu_Buy_Frame:SetProperty("UnifiedXPosition", g_FengYun_JinDu_Buy_Frame_UnifiedXPosition);
	FengYun_JinDu_Buy_Frame:SetProperty("UnifiedYPosition", g_FengYun_JinDu_Buy_Frame_UnifiedYPosition);
end

--点击最大按钮
function FengYun_JinDu_Buy_CalMax()

	if g_FengYun_JinDu_Buy_CurPoint >= 0 and  g_FengYun_JinDu_Buy_MaxPoint > 0 then
		local nCanAdd = g_FengYun_JinDu_Buy_MaxPoint - g_FengYun_JinDu_Buy_CurPoint
		if nCanAdd > 0 then
			FengYun_JinDu_Buy_InputNum:SetText(nCanAdd)
		else
			FengYun_JinDu_Buy_InputNum:SetText(1)
		end
	end
end

--打开购买界面
function FengYun_JinDu_Buy_Open(npoint,nPointMax)
	
	FengYun_JinDu_Buy_InputNum:SetText(1)
	local nAdd = FengYun_JinDu_Buy_InputNum:GetText()

	local nNeedYuanbao = nAdd*g_FengYun_JinDu_Buy_YuanBaoNeedPer
	FengYun_JinDu_Buy_Price_Yuanbao:SetText(ScriptGlobal_Format("#{FYJD_250113_73}",tostring(nNeedYuanbao)))

	local nHaveYB = Player:GetData("YUANBAO")
	if nNeedYuanbao > nHaveYB then
		FengYun_JinDu_Buy_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{FYJD_250113_76}",tostring(nHaveYB)))
	else
		FengYun_JinDu_Buy_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{FYJD_250113_75}",tostring(nHaveYB)))
	end
end

--确定购买
function FengYun_JinDu_Buy_BuyMulti_Clicked()
	local nLevel = Player:GetLevel();
    -- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
    end
	if nLevel < 30  then        
		PushDebugMessage("#{FYJD_250113_40}")
		return
    end
	
	local	nNum	=	0
	if FengYun_JinDu_Buy_InputNum:GetText() ~= '' then
		nNum	=	tonumber(FengYun_JinDu_Buy_InputNum:GetText())
    end 

	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("BuyDaiBi")
	Set_XSCRIPT_ScriptID(999841)
	Set_XSCRIPT_Parameter(0,tonumber(nNum)); 
	Set_XSCRIPT_Parameter(1,0); 
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--数量变化
function FengYun_JinDu_Buy_TextChanged()


	if FengYun_JinDu_Buy_InputNum:GetText() ~= '' then
		local nAdd = FengYun_JinDu_Buy_InputNum:GetText()
		
		local nAddNew = FengYun_JinDu_Buy_FixData(tonumber(nAdd))
		
		local nNeedYuanbao = nAddNew*g_FengYun_JinDu_Buy_YuanBaoNeedPer
		FengYun_JinDu_Buy_Price_Yuanbao:SetText(ScriptGlobal_Format("#{FYJD_250113_73}",tostring(nNeedYuanbao)))
		
		local nHaveYB = Player:GetData("YUANBAO")
		if nNeedYuanbao > nHaveYB then
			FengYun_JinDu_Buy_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{FYJD_250113_76}",tostring(nHaveYB)))
		else
			FengYun_JinDu_Buy_Cash_Yuanbao:SetText(ScriptGlobal_Format("#{FYJD_250113_75}",tostring(nHaveYB)))
		end
	end
end

function FengYun_JinDu_Buy_FixData(nValue)
	if g_FengYun_JinDu_Buy_CurPoint >= 0 and  g_FengYun_JinDu_Buy_MaxPoint > 0 then
		local nCanAdd = g_FengYun_JinDu_Buy_MaxPoint - g_FengYun_JinDu_Buy_CurPoint
		if nValue > nCanAdd then
			FengYun_JinDu_Buy_InputNum:SetText(nCanAdd)
			return nCanAdd
		end
	end
	return nValue
end
