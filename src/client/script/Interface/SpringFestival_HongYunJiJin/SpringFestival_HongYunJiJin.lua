
local g_Frame_UnifiedPosition

local g_SpringFestival_HongYunJiJin_state = 0
local g_SpringFestival_HongYunJiJin_benjin = 0
local g_SpringFestival_HongYunJiJin_jiaxibili = 0
local g_SpringFestival_HongYunJiJin_all = 0
local g_SpringFestival_HongYunJiJin_old = 0
local g_SpringFestival_HongYunJiJin_add = 0
local g_SpringFestival_HongYunJiJin_isget = 0

local g_SpringFestival_HongYunJiJin_Image = {
[1] = { s = 1, e = 1200, img = "set:Spring14 image:Jijin_benjin_1" },
[2] = { s = 1201, e = 2400, img = "set:Spring15 image:Jijin_benjin_2" },
[3] = { s = 2401, e = 3600, img = "set:Spring15 image:Jijin_benjin_3" },
[4] = { s = 3601, e = 4800, img = "set:Spring16 image:Jijin_benjin_4" },
[5] = { s = 4801, e = 6000, img = "set:Spring16 image:Jijin_benjin_5" },
}

local g_SpringFestival_HongYunJiJin_Num = {
[0] = "set:Spring14 image:jijin_0",
[1] = "set:Spring14 image:jijin_1",
[2] = "set:Spring14 image:jijin_2",
[3] = "set:Spring14 image:jijin_3",
[4] = "set:Spring14 image:jijin_4",
[5] = "set:Spring14 image:jijin_5",
[6] = "set:Spring14 image:jijin_6",
[7] = "set:Spring14 image:jijin_7",
[8] = "set:Spring14 image:jijin_8",
[9] = "set:Spring14 image:jijin_9",
}

--=========
-- PreLoad
--=========
function SpringFestival_HongYunJiJin_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

--=========
-- OnLoad
--=========
function SpringFestival_HongYunJiJin_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_HongYunJiJin_Frame:GetProperty("UnifiedPosition") 
		
end

--=========
-- OnEvent
--=========
function SpringFestival_HongYunJiJin_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89332402 then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then		
			g_SpringFestival_HongYunJiJin_state = Get_XParam_INT(1)
			g_SpringFestival_HongYunJiJin_benjin = Get_XParam_INT(2)
			g_SpringFestival_HongYunJiJin_jiaxibili = Get_XParam_INT(3)			
			g_SpringFestival_HongYunJiJin_all = Get_XParam_INT(4)		
			g_SpringFestival_HongYunJiJin_old = Get_XParam_INT(5)		
			g_SpringFestival_HongYunJiJin_add = Get_XParam_INT(6)
			g_SpringFestival_HongYunJiJin_isget = Get_XParam_INT(7)
			
			SpringFestival_HongYunJiJin_Update()

			this:Show()	
		elseif bShow == 2 then			
			g_SpringFestival_HongYunJiJin_state = Get_XParam_INT(1)
			if IsWindowShow("SpringFestival_HongYunJiJin") then
				g_SpringFestival_HongYunJiJin_benjin = Get_XParam_INT(2)
				g_SpringFestival_HongYunJiJin_jiaxibili = Get_XParam_INT(3)		
				g_SpringFestival_HongYunJiJin_all = Get_XParam_INT(4)	
				g_SpringFestival_HongYunJiJin_old = Get_XParam_INT(5)		
				g_SpringFestival_HongYunJiJin_add = Get_XParam_INT(6)
				g_SpringFestival_HongYunJiJin_isget = Get_XParam_INT(7)
				
				SpringFestival_HongYunJiJin_Update()
			end
		else
			SpringFestival_HongYunJiJin_OnHiden()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_HongYunJiJin_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival_HongYunJiJin_On_ResetPos()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
	
		SpringFestival_HongYunJiJin_OnHiden();

	end

end

--=========
-- 更新界面
--=========
function SpringFestival_HongYunJiJin_Update()	
	
	local msg = ""	
	
	--原始本金
	msg = ScriptGlobal_Format("#{SZYG_191126_64}", g_SpringFestival_HongYunJiJin_benjin)
	SpringFestival_HongYunJiJin_Frame_CapitalText:SetText(msg)
	
	--加息
	if g_SpringFestival_HongYunJiJin_jiaxibili == 0 then
		msg = ScriptGlobal_Format("#{SZYG_191126_150}", 0, 0)
		SpringFestival_HongYunJiJin_Interest:SetToolTip( msg )
		SpringFestival_HongYunJiJin_CapitalUp:SetToolTip( msg )
		SpringFestival_HongYunJiJin_Num1:SetToolTip( msg )
		SpringFestival_HongYunJiJin_Num2:SetToolTip( msg )
		SpringFestival_HongYunJiJin_Percent:SetToolTip( msg )
		
		SpringFestival_HongYunJiJin_Num1:Hide()			
			
		if g_SpringFestival_HongYunJiJin_Num[0] ~= nil then
			SpringFestival_HongYunJiJin_Num2:SetProperty( "Image", g_SpringFestival_HongYunJiJin_Num[0])
		end
		
		SpringFestival_HongYunJiJin_Incometip:SetToolTip( msg )
		--加息收益
		msg = ScriptGlobal_Format("#{SZYG_191126_60}", 0)
		SpringFestival_HongYunJiJin_Frame_IncomeText1:SetText(msg)
	else		
		local nfirst = math.floor(g_SpringFestival_HongYunJiJin_jiaxibili / 10)
		local nsecond = math.mod( g_SpringFestival_HongYunJiJin_jiaxibili, 10 )
		if nfirst == 0 then
			SpringFestival_HongYunJiJin_Num1:Hide()			
			
			if g_SpringFestival_HongYunJiJin_Num[nsecond] ~= nil then
				SpringFestival_HongYunJiJin_Num2:SetProperty( "Image", g_SpringFestival_HongYunJiJin_Num[nsecond])
			end
		else
			SpringFestival_HongYunJiJin_Num1:Show()		
			
			if g_SpringFestival_HongYunJiJin_Num[nfirst] ~= nil then
				SpringFestival_HongYunJiJin_Num1:SetProperty( "Image", g_SpringFestival_HongYunJiJin_Num[nfirst])
			end
			
			if g_SpringFestival_HongYunJiJin_Num[nsecond] ~= nil then
				SpringFestival_HongYunJiJin_Num2:SetProperty( "Image", g_SpringFestival_HongYunJiJin_Num[nsecond])
			end
		end
		
		local lixivalue = 0
		if math.mod(g_SpringFestival_HongYunJiJin_benjin*g_SpringFestival_HongYunJiJin_jiaxibili, 100) == 0 then
			lixivalue = math.floor(g_SpringFestival_HongYunJiJin_benjin*g_SpringFestival_HongYunJiJin_jiaxibili/100)
		else
			lixivalue = math.floor(g_SpringFestival_HongYunJiJin_benjin*g_SpringFestival_HongYunJiJin_jiaxibili/100) + 1
		end
		msg = ScriptGlobal_Format("#{SZYG_191126_150}", g_SpringFestival_HongYunJiJin_jiaxibili, lixivalue)
		SpringFestival_HongYunJiJin_Interest:SetToolTip( msg )
		SpringFestival_HongYunJiJin_CapitalUp:SetToolTip( msg )
		SpringFestival_HongYunJiJin_Num1:SetToolTip( msg )
		SpringFestival_HongYunJiJin_Num2:SetToolTip( msg )
		SpringFestival_HongYunJiJin_Percent:SetToolTip( msg )
	
		SpringFestival_HongYunJiJin_Incometip:SetToolTip( msg )
		--加息收益
		msg = ScriptGlobal_Format("#{SZYG_191126_60}", lixivalue)
		SpringFestival_HongYunJiJin_Frame_IncomeText1:SetText(msg)
	end
	
	--元宝盒子
	for i = 1, table.getn(g_SpringFestival_HongYunJiJin_Image) do
		if g_SpringFestival_HongYunJiJin_benjin >= g_SpringFestival_HongYunJiJin_Image[i].s 
			and g_SpringFestival_HongYunJiJin_benjin <= g_SpringFestival_HongYunJiJin_Image[i].e then
			SpringFestival_HongYunJiJin_CapitalIconR:SetProperty( "Image", g_SpringFestival_HongYunJiJin_Image[i].img )
		end
	end
		
	if g_SpringFestival_HongYunJiJin_state == 1 then -- 预计收益
		SpringFestival_HongYunJiJin_Available_Icon_L1:Show()
		SpringFestival_HongYunJiJin_Available_Icon_L2:Hide()
	elseif g_SpringFestival_HongYunJiJin_state == 2 then -- 总收益
		SpringFestival_HongYunJiJin_Available_Icon_L1:Hide()
		SpringFestival_HongYunJiJin_Available_Icon_L2:Show()
	end
		
	--总资产
	msg = ScriptGlobal_Format("#{SZYG_191126_60}", g_SpringFestival_HongYunJiJin_all)
	SpringFestival_HongYunJiJin_Frame_FundText1:SetText(msg)
	
	--是否已领取
	if g_SpringFestival_HongYunJiJin_isget == 1 then
		SpringFestival_HongYunJiJin_Frame_RewardButton:Disable()
	else
		SpringFestival_HongYunJiJin_Frame_RewardButton:Enable()
	end
	
	if g_SpringFestival_HongYunJiJin_state == 1 then
		SpringFestival_HongYunJiJin_Frame_RewardButtonCover:Show()
	else
		SpringFestival_HongYunJiJin_Frame_RewardButtonCover:Hide()
	end
	
	--昨日收益
	msg = ScriptGlobal_Format("#{SZYG_191126_60}", g_SpringFestival_HongYunJiJin_old)
	SpringFestival_HongYunJiJin_Frame_ProfitText1:SetText(msg)
		
	--可领取金珠
	msg = ScriptGlobal_Format("#{SZYG_191126_60}", g_SpringFestival_HongYunJiJin_all + g_SpringFestival_HongYunJiJin_add)
	SpringFestival_HongYunJiJin_Available_Text1:SetText(msg)
	
end

--=========
-- 关闭
--=========
function SpringFestival_HongYunJiJin_OnHiden()

	this:Hide()

end

--=========
-- 重置
--=========
function SpringFestival_HongYunJiJin_On_ResetPos()

	SpringFestival_HongYunJiJin_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 确认兑换
--=========
function SpringFestival_HongYunJiJin_Clicked()

    Clear_XSCRIPT()
    	Set_XSCRIPT_Function_Name("OnFondExchange")
    	Set_XSCRIPT_ScriptID(893324)
    	Set_XSCRIPT_Parameter(0, 0);
    	Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()		
	
end

function SpringFestival_HongYunJiJin_Help()

    Clear_XSCRIPT()
    	Set_XSCRIPT_Function_Name("OnShowFashionHelp")
    	Set_XSCRIPT_ScriptID(893324)
    	Set_XSCRIPT_Parameter(0, 4);
    	Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()		
	
end


