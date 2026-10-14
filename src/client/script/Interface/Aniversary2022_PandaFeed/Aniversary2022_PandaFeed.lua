--周年庆 熊猫交互
local g_Aniversary2022_PandaFeed_Frame_UnifiedPosition;
local g_ExeScript = 888953
local g_UICOMMAND = 88895301
local g_NUMA  = 0
local g_NUMB  = 0
local g_State = 0
local g_actTime = {begintime = 20220422,endtime = 20220515}
local g_LimitLevel = 30
local g_Title= {"十五的投喂官","天天龙龙的投喂官"}
--===============================================
-- PreLoad()
--===============================================
function Aniversary2022_PandaFeed_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化

end

--===============================================
-- OnEvent()
--===============================================
function Aniversary2022_PandaFeed_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then 
		g_NUMA = Get_XParam_INT(0)
	    g_NUMB = Get_XParam_INT(1)
		g_State = Get_XParam_INT(2)
		Aniversary2022_PandaFeed_Open()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		Aniversary2022_PandaFeed_Close()
	
	elseif (event == "ADJEST_UI_POS") then
		Aniversary2022_PandaFeed_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Aniversary2022_PandaFeed_On_ResetPos()
	end
end

--===============================================
-- OnLoad()
--===============================================
function Aniversary2022_PandaFeed_OnLoad()

	g_Aniversary2022_PandaFeed_Frame_UnifiedPosition = Aniversary2022_PandaFeed_Frame_BK:GetProperty("UnifiedPosition")



end

--===============================================
-- Close()
--===============================================
function Aniversary2022_PandaFeed_Close()

	this:Hide();
end
--===============================================
-- ResetPos()
--===============================================
function Aniversary2022_PandaFeed_On_ResetPos()
	Aniversary2022_PandaFeed_Frame_BK:SetProperty("UnifiedPosition", g_Aniversary2022_PandaFeed_Frame_UnifiedPosition)
end

--===============================================
-- Open()
--===============================================
function  Aniversary2022_PandaFeed_Open()
	Aniversary2022_PandaFeed_Page_Lace1Item_Tip1:SetText(ScriptGlobal_Format("#{XMJH_220121_52}",g_NUMA))
	Aniversary2022_PandaFeed_Page_Lace1Item_Tip2:SetText(ScriptGlobal_Format("#{XMJH_220121_53}",g_NUMB))
	Aniversary2022_PandaFeed_GetAward:Hide()	--领奖按钮
	Aniversary2022_PandaFeed_Received:Hide()	--已领取
	Aniversary2022_PandaFeed_TitleBK:Hide()	--Title图片
	Aniversary2022_PandaFeed_Image_Client1_WinImage:Hide()	--胜出图片
	Aniversary2022_PandaFeed_Image_Client2_WinImage:Hide()
	Aniversary2022_PandaFeed_GetAward_Tips:Hide() --红点
	Aniversary2022_PandaFeed_TimingBK:Hide()
	if g_State == 1 then
		Aniversary2022_PandaFeed_Page_AwardInfo:SetText("#{XMJH_220121_120}")
		Aniversary2022_PandaFeed_TimingBK:Show()
	else
		Aniversary2022_PandaFeed_TitleBK:Show()
		if g_NUMA > g_NUMB then
			Aniversary2022_PandaFeed_Title1:Show()
			Aniversary2022_PandaFeed_Title2:Hide()
			Aniversary2022_PandaFeed_Image_Client1_WinImage:Show()
			Aniversary2022_PandaFeed_Image_Client2_WinImage:Hide()
		else
			Aniversary2022_PandaFeed_Title2:Show()
			Aniversary2022_PandaFeed_Title1:Hide()
			Aniversary2022_PandaFeed_Image_Client2_WinImage:Show()
			Aniversary2022_PandaFeed_Image_Client1_WinImage:Hide()
		end

		if g_State == 2 then
			
			local btnTips = ""
			if g_NUMA > g_NUMB then
				btnTips = ScriptGlobal_Format("#{XMJH_220121_57}",g_Title[1]) 
			else
				btnTips = ScriptGlobal_Format("#{XMJH_220121_57}",g_Title[2]) 
			end
			
			Aniversary2022_PandaFeed_GetAward:Show()
			Aniversary2022_PandaFeed_GetAward:SetToolTip(btnTips)			
			local redPoint =  Get_XParam_INT(3)
			if redPoint == 1 then
				Aniversary2022_PandaFeed_GetAward_Tips:Show()
			else
				Aniversary2022_PandaFeed_GetAward_Tips:Hide()
			end

		elseif g_State == 3 then --已领取
			Aniversary2022_PandaFeed_Received:Show()
		end
	end
	Aniversary2022_PandaFeed_Page_VoteDays:SetText(ScriptGlobal_Format("#{XMJH_220121_123}",Get_XParam_INT(4)) )
	this:Show()

end

function Aniversary2022_PandaFeed_GetClick()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnGetTitleReward")
	Set_XSCRIPT_ScriptID(g_ExeScript)					
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

function Aniversary2022_PandaFeed_GotoClick()
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay < g_actTime.begintime or curDay > g_actTime.endtime then
		PushDebugMessage("#{XMJH_220121_01}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{XMJH_220121_02}")
		return
	end

	--寻路
	AutoRunToTargetEx(274, 270, 0)	
end

function Aniversary2022_PandaFeed_ShowHelp()
	 	-- 借用一下别人的通道
		 PushEvent("CCSHOP_HELP", 153)
end