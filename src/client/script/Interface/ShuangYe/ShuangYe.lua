--赏枫领奖界面
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_TicketGainCount = 0
local g_nDownTick = 0
local g_MaxTicket = 4
local g_ShuangYe_HoyueRewardIcon = {}
local g_Offset=2;

--累计登陆天数
local g_ShuangYe_ActivePointNeed = {1,50,150,450}

local g_ShuangYe_ActivePointNeed_KaJi = {1,50,100,150}

local g_ShuangYe_ItemId = 39921494
local g_ShuangYe_ExtraItemId = 39921474

local g_ShuangYe_todayPoint = 0
local g_ShuangYe_IsGetGift = {0,0,0,0}
local g_ShuangYe_HuoyueRewardMark = {}
local g_SHuangYe_RedPoint = {}
local g_ShuangYe_CountButton = {}
local g_ShuangYe_CollectedButton = {}
local g_ShuangYe_ButtonTips = {}
local g_ShuangYe_ImageNormal = {}
local g_ShuangYe_ImageDisable = {}
local g_ShuangYe_ImageCollected = {}
local g_ShuangYe_CountButtonText = {}
local g_ShuangYe_CountDownBK = {}
local g_ShuangYe_ActionButtonTips = {}
local g_ShuangYe_HuoyueText = {}
local g_ShuangYe_QiufengyinCount = 0
local g_ShuangYe_IsGetFrostleaf = {0,0,0,0}

local g_ShuangYe_HuoYue_ToolTip_Text = {
	[1] = "#{QFGS_200814_61}",
	[2] = "#{QFGS_200814_62}",
	[3] = "#{QFGS_200814_63}",
	[4] = "#{QFGS_200814_64}",
}

local g_ShuangYe_HuoYue_ToolTip_Text_Kaji = {
	[1] = "#{QFGS_200814_61}",
	[2] = "#{QFGS_200814_62}",
	[3] = "#{QFGS_220725_05}",
	[4] = "#{QFGS_200814_63}",
}

function ShuangYe_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function ShuangYe_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 89141402 then
        if ( Get_XParam_INT_Count() < 1 ) then
			return
		end
		local isShow = Get_XParam_INT(0);
		if isShow == 1 then
			g_TicketGainCount = Get_XParam_INT(1)
			g_nDownTick = Get_XParam_INT(2)
			g_ShuangYe_QiufengyinCount = Get_XParam_INT(3)
			g_Offset=Get_XParam_INT(4)
			for i = 1, 4 do
				local isGet = Get_XParam_INT(4+i)
			    g_ShuangYe_IsGetFrostleaf[i] = isGet
			end
			ShuangYe_OnShown()
		elseif isShow == 2 then
			if (this:IsVisible()) then
				g_TicketGainCount = Get_XParam_INT(1)
				g_nDownTick = Get_XParam_INT(2)
				g_ShuangYe_QiufengyinCount = Get_XParam_INT(3)
				g_Offset=Get_XParam_INT(4)
				for i = 1, 4 do
					local isGet = Get_XParam_INT(4+i)
					g_ShuangYe_IsGetFrostleaf[i] = isGet
				end
				ShuangYe_OnShown()
			end
		else
		 	ShuangYe_OnHiden()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89141403 and (this:IsVisible()) then
		g_ShuangYe_todayPoint = Get_XParam_INT(0)
		g_ShuangYe_QiufengyinCount = Get_XParam_INT(1)
		for i = 1, 4 do
			local isGet = Get_XParam_INT(i+1)
			g_ShuangYe_IsGetGift[i] = isGet
		end
		
		ShuangYe_UpdateHuoyueData()
	elseif( event == "ADJEST_UI_POS" ) then
		ShuangYe_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		ShuangYe_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function ShuangYe_OnLoad()   
	g_ShuangYe_HoyueRewardIcon[1] = ShuangYe_Icon1
	g_ShuangYe_HoyueRewardIcon[2] = ShuangYe_Icon2
	g_ShuangYe_HoyueRewardIcon[3] = ShuangYe_Icon3
	g_ShuangYe_HoyueRewardIcon[4] = ShuangYe_Icon4

	g_SHuangYe_RedPoint[1] = ShuangYe_Icon1_Tips
	g_SHuangYe_RedPoint[2] = ShuangYe_Icon2_Tips
	g_SHuangYe_RedPoint[3] = ShuangYe_Icon3_Tips
	g_SHuangYe_RedPoint[4] = ShuangYe_Icon4_Tips

	g_ShuangYe_HuoyueRewardMark[1] = ShuangYe_Icon1_Mark
	g_ShuangYe_HuoyueRewardMark[2] = ShuangYe_Icon2_Mark
	g_ShuangYe_HuoyueRewardMark[3] = ShuangYe_Icon3_Mark
	g_ShuangYe_HuoyueRewardMark[4] = ShuangYe_Icon4_Mark
	
	g_ShuangYe_HuoyueText[1] = ShuangYe_huoyue1_text
	g_ShuangYe_HuoyueText[2] = ShuangYe_huoyue2_text
	g_ShuangYe_HuoyueText[3] = ShuangYe_huoyue3_text
	g_ShuangYe_HuoyueText[4] = ShuangYe_huoyue4_text

	g_ShuangYe_ActionButtonTips[1] = ShuangYe_Icon5
	g_ShuangYe_ActionButtonTips[2] = ShuangYe_Icon6
	g_ShuangYe_ActionButtonTips[3] = ShuangYe_Icon7
	g_ShuangYe_ActionButtonTips[4] = ShuangYe_Icon8

	g_ShuangYe_CountButtonText[1] = ShuangYe_Today_CountDownText
	g_ShuangYe_CountButtonText[2] = ShuangYe_Today_CountDownText2
	g_ShuangYe_CountButtonText[3] = ShuangYe_Today_CountDownText3
	g_ShuangYe_CountButtonText[4] = ShuangYe_Today_CountDownText4

	g_ShuangYe_CountDownBK[1] = ShuangYe_Today_CountDownBK
	g_ShuangYe_CountDownBK[2] = ShuangYe_Today_CountDownBK2
	g_ShuangYe_CountDownBK[3] = ShuangYe_Today_CountDownBK3
	g_ShuangYe_CountDownBK[4] = ShuangYe_Today_CountDownBK4
	
	g_ShuangYe_ButtonTips[1] = ShuangYe_Icon5_Tips
	g_ShuangYe_ButtonTips[2] = ShuangYe_Icon6_Tips
	g_ShuangYe_ButtonTips[3] = ShuangYe_Icon7_Tips
	g_ShuangYe_ButtonTips[4] = ShuangYe_Icon8_Tips
	
	g_ShuangYe_ImageNormal[1] = ShuangYe_Icon5_Mark
	g_ShuangYe_ImageNormal[2] = ShuangYe_Icon6_Mark
	g_ShuangYe_ImageNormal[3] = ShuangYe_Icon7_Mark
	g_ShuangYe_ImageNormal[4] = ShuangYe_Icon8_Mark

	g_Frame_UnifiedXPosition = ShuangYe_FrameNULL:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition = ShuangYe_FrameNULL:GetProperty("UnifiedYPosition");
end

function ShuangYe_OnShown()
	
	-- 赏枫道具
	for i = 1, 4 do
   		g_ShuangYe_ActionButtonTips[i]:Show()
		g_ShuangYe_ActionButtonTips[i]:Enable()
		g_ShuangYe_ActionButtonTips[i]:SetToolTip("#{QFGS_200814_60}")
	end

	-- 枫叶图标
	for i = 1, 4 do
		--已经领过的
		if 	g_ShuangYe_IsGetFrostleaf[i] == 1 then
			g_ShuangYe_ImageNormal[i]:Show()
			g_ShuangYe_ActionButtonTips[i]:Disable()
		else
			g_ShuangYe_ImageNormal[i]:Hide()
		end
	end
	--默认第一个可以直接领取
	if g_TicketGainCount==0 then
		g_ShuangYe_ButtonTips[1]:Show()
		g_ShuangYe_CountDownBK[1]:Hide()
	end
	--总计时间结束
	if g_nDownTick <= 0 then
		--红点
		for i = 1, 4 do
			if g_ShuangYe_IsGetFrostleaf[i] ~= 1 then			
				g_ShuangYe_ButtonTips[i]:Show()
			else				
				g_ShuangYe_ButtonTips[i]:Hide()
			end
			g_ShuangYe_CountDownBK[i]:Hide()
		end
	else
		for i = 1, 4 do
			--倒计时显示
			if i == g_Offset then
				g_ShuangYe_CountDownBK[i]:Show()	
				g_ShuangYe_CountButtonText[i]:SetProperty( "Timer", tostring(g_nDownTick) )
			else
				g_ShuangYe_CountDownBK[i]:Hide()
			end
			--红点
			if g_ShuangYe_IsGetFrostleaf[i] ~= 1 and i<g_Offset then
				g_ShuangYe_ButtonTips[i]:Show()
			else
				g_ShuangYe_ButtonTips[i]:Hide()
			end
			
		end
	end
	
	-- 剩余秋枫引
	qiufengyin_number_Text:SetText(ScriptGlobal_Format("#{QFGS_180807_50}",g_ShuangYe_QiufengyinCount))
	
	this:Show();
end

function ShuangYe_UpdateHuoyueData()
	local ShuangYe_HuoYue_ToolTip_Text = nil
	if KaJi:LuaFnGetKaJiType(97) == 1 then
		ShuangYe_HuoYue_ToolTip_Text = g_ShuangYe_HuoYue_ToolTip_Text_Kaji
	else
		ShuangYe_HuoYue_ToolTip_Text = g_ShuangYe_HuoYue_ToolTip_Text
	end
	
	for i = 1, 4 do
		g_ShuangYe_HoyueRewardIcon[i]:SetToolTip(ShuangYe_HuoYue_ToolTip_Text[i])

		if g_ShuangYe_IsGetGift[i] == 1 then
			g_ShuangYe_HuoyueRewardMark[i]:Show()
			g_ShuangYe_HoyueRewardIcon[i]:Disable()
		else
			g_ShuangYe_HuoyueRewardMark[i]:Hide()
			g_ShuangYe_HoyueRewardIcon[i]:Enable()
		end
		
		local ShuangYe_ActivePointNeed = nil
		if KaJi:LuaFnGetKaJiType(97) == 1 then
			ShuangYe_ActivePointNeed = g_ShuangYe_ActivePointNeed_KaJi
		else
			ShuangYe_ActivePointNeed = g_ShuangYe_ActivePointNeed
		end
		--红点
		if g_ShuangYe_todayPoint >= ShuangYe_ActivePointNeed[i] and g_ShuangYe_IsGetGift[i] == 0 then
			g_ShuangYe_HoyueRewardIcon[i]:SetToolTip("#{QFGS_180807_08}")
			g_SHuangYe_RedPoint[i]:Show()
		else
			g_SHuangYe_RedPoint[i]:Hide()
		end

		if g_ShuangYe_todayPoint >= ShuangYe_ActivePointNeed[i] then
			local text = ScriptGlobal_Format("#{QFGS_180807_49}", ShuangYe_ActivePointNeed[i], ShuangYe_ActivePointNeed[i])
			g_ShuangYe_HuoyueText[i]:SetText(text)
		else
			local text = ScriptGlobal_Format("#{QFGS_180807_49}", g_ShuangYe_todayPoint, ShuangYe_ActivePointNeed[i])
			g_ShuangYe_HuoyueText[i]:SetText(text)
		end
		
		
	end	
	
	--剩余秋枫引
	qiufengyin_number_Text:SetText(ScriptGlobal_Format("#{QFGS_180807_50}",g_ShuangYe_QiufengyinCount))
end

--倒计时结束
function ShuangYe_CountDown_OnTimer()
	for i = 1, 4 do
		if i == g_TicketGainCount+1 then
			g_ShuangYe_ButtonTips[i]:Show()
			g_ShuangYe_ActionButtonTips[i]:SetToolTip("#{QFGS_180807_08}")
			--g_ShuangYe_ActionButtonTips[i]:Enable()
		else
			g_ShuangYe_ButtonTips[i]:Hide()
			--g_ShuangYe_ActionButtonTips[i]:Disable()
		end
	end				
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateUIForTick" )
		Set_XSCRIPT_ScriptID( 891414 )
		Set_XSCRIPT_Parameter(0,0);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end
--=========================================================
--选择
--=========================================================
function ShuangYe_Reward_Clicked(index)
	if index < 1 or index > 5 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetHuoyueGift" )
		Set_XSCRIPT_ScriptID( 891414 )
		Set_XSCRIPT_Parameter(0,index);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

--=========================================================
--确认
--=========================================================
function ShuangYe_Button_Clicked(index)
    if index>g_Offset then
		PushDebugMessage("#{QFGS_200814_65}")
		return
	end
	if index==g_Offset then
		PushDebugMessage("#{SYHY_150727_08}")
		return
	end
	--在地府中不能领取
	local isInHell = IsInHell()
	if isInHell == 1 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGuideItem" )
		Set_XSCRIPT_ScriptID( 891414 )
		Set_XSCRIPT_Parameter(0,index);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========================================================
--使用秋枫引
--=========================================================
function ShuangYe_UseQiufengyin_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UseQiuFengYin" )
		Set_XSCRIPT_ScriptID( 891415 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

function ShuangYe_Help_Clicked()
	PushEvent("OPEN_SHANGFENG_HELP")
end

function ShuangYe_OnHiden()
	this:Hide();
end
function ShuangYe_ResetPos()
	ShuangYe_FrameNULL:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ShuangYe_FrameNULL:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end



