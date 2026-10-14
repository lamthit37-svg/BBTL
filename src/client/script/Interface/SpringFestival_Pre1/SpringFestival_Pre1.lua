--SpringFestival_Pre1.lua
local g_Frame_UnifiedPosition
local g_RandomText = {}
local g_RandomTextMoQi = {}
local g_Animate = {}
local g_Background = {}
local g_BackgroundText = {}
local g_index = 1
local g_Random = {
	[1] = 20;
	[2] = 20;
	[3] = 20;
	[4] = 20;
	[5] = 20;
}
local g_Image = {


	[1] = "set:Spring31  image:MiQingYin_YuYunShui1",
	[2] = "set:Spring31  image:MiQingYin_MiaoCuiWei1",
	[3] = "set:Spring31  image:MiQingYin_WenZheLiu1",
	[4] = "set:Spring31  image:MiQingYin_LingBiBo1",
	[5] = "set:Spring31  image:MiQingYin_JingFengLei1",
	
	
}

local g_ImageNormal = {


	[1] = "set:Spring31  image:MiQingYin_YuYunShui2",
	[2] = "set:Spring31  image:MiQingYin_MiaoCuiWei2",
	[3] = "set:Spring31  image:MiQingYin_WenZheLiu2",
	[4] = "set:Spring31  image:MiQingYin_LingBiBo2",
	[5] = "set:Spring31  image:MiQingYin_JingFengLei2",
	
	
}

local g_Imagebk = {
	[1] = "set:Spring31  image:MiQingYin_InstrBG_Hover",
}
--=========
-- PreLoad()
--=========
function SpringFestival_Pre1_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function SpringFestival_Pre1_OnLoad()
	
	g_Frame_UnifiedPosition = SpringFestival_Pre1_Frame:GetProperty("UnifiedPosition")
	g_RandomText[1] = SpringFestival_Pre1_1Text;
	g_RandomText[2] = SpringFestival_Pre1_2Text;
	g_RandomText[3] = SpringFestival_Pre1_3Text;
	g_RandomText[4] = SpringFestival_Pre1_4Text;
	g_RandomText[5] = SpringFestival_Pre1_5Text;
	
	g_RandomTextMoQi[1] = SpringFestival_Pre1_MoQi1;
	g_RandomTextMoQi[2] = SpringFestival_Pre1_MoQi2;
	g_RandomTextMoQi[3] = SpringFestival_Pre1_MoQi3;
	g_RandomTextMoQi[4] = SpringFestival_Pre1_MoQi4;
	g_RandomTextMoQi[5] = SpringFestival_Pre1_MoQi5;
	
	g_Animate[1] = SpringFestival_Pre1_WeaponVFX1;
	g_Animate[2] = SpringFestival_Pre1_WeaponVFX2;
	g_Animate[3] = SpringFestival_Pre1_WeaponVFX3;
	g_Animate[4] = SpringFestival_Pre1_WeaponVFX4;
	g_Animate[5] = SpringFestival_Pre1_WeaponVFX5;
	
	g_Background[1] = SpringFestival_Pre1_QuanTu1;
	g_Background[2] = SpringFestival_Pre1_QuanTu2;
	g_Background[3] = SpringFestival_Pre1_QuanTu3;
	g_Background[4] = SpringFestival_Pre1_QuanTu4;
	g_Background[5] = SpringFestival_Pre1_QuanTu5;
	
	g_BackgroundText[1] = SpringFestival_Pre1_Name1;
	g_BackgroundText[2] = SpringFestival_Pre1_Name2;
	g_BackgroundText[3] = SpringFestival_Pre1_Name3;
	g_BackgroundText[4] = SpringFestival_Pre1_Name4;
	g_BackgroundText[5] = SpringFestival_Pre1_Name5;
	
	for i = 1, 5 do 
		g_Animate[i]:Play(false)
	end
	SpringFestival_Pre1_Icon1_tips:Hide()
	SpringFestival_Pre1_Icon2_tips:Hide()
end

--=========
-- Event
--=========
function SpringFestival_Pre1_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88833401) then
		for i = 1, 5 do
			g_Background[i]:SetProperty("Image", "set:Spring31  image:MiQingYin_InstrBG_Normal")		
			g_BackgroundText[i]:SetProperty("Image", g_ImageNormal[i])
		end
	
		local nSYCY_INDEX = Get_XParam_INT(0)
		local nRandom = {0,0,0,0,0}
		nRandom[1] = Get_XParam_INT(1)
		nRandom[2] = Get_XParam_INT(2)
		nRandom[3] = Get_XParam_INT(3)
		nRandom[4] = Get_XParam_INT(4)
		nRandom[5] = Get_XParam_INT(5)
		for i = 1 , 5 do
			g_Random[i] = nRandom[i]
		end
		local nIsGetItem = Get_XParam_INT(6)
		local nIsPlayAnim = Get_XParam_INT(7)
		if nIsGetItem == 0 then
			SpringFestival_Pre1_Open(nSYCY_INDEX, nRandom[1], nRandom[2], nRandom[3], nRandom[4], nRandom[5], nIsGetItem, nIsPlayAnim)
		else
			this:Hide()
		end
		
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		SpringFestival_Pre1_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_Pre1_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		SpringFestival_Pre1_On_ResetPos()

	end
end


function SpringFestival_Pre1_Close()
	
	this:Hide()
end

--=========
-- 重置
--=========
function SpringFestival_Pre1_On_ResetPos()

	SpringFestival_Pre1_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function SpringFestival_Pre1_Open(index, random1, random2, random3, random4, random5, isgetitem, nIsPlayAnim)

	
	SpringFestival_Pre1_ClientDownFrame_Content:SetText("#{SYCY_201225_175}")
	if index == 0 then
		for i = 1, 5 do
			g_RandomText[i]:Hide()
			g_RandomTextMoQi[i]:Hide()
		end		
		SpringFestival_Pre1_Tacit_Button:Show()
		SpringFestival_Pre1_Reward_Button:Hide()
		SpringFestival_Pre1_Icon2_tips:Hide()
		SpringFestival_Pre1_Reward_BasicItemReceived:Hide()
		SpringFestival_Pre1_Icon1_tips:Show()
	else
		g_index = index
		if nIsPlayAnim == 0 then
			for i = 1, 5 do
				g_RandomText[i]:Show()
				g_RandomTextMoQi[i]:Show()
			end
			g_RandomText[1]:SetText(ScriptGlobal_Format("#{SYCY_201225_79}",random1))	
			g_RandomText[2]:SetText(ScriptGlobal_Format("#{SYCY_201225_79}",random2))
			g_RandomText[3]:SetText(ScriptGlobal_Format("#{SYCY_201225_79}",random3))	
			g_RandomText[4]:SetText(ScriptGlobal_Format("#{SYCY_201225_79}",random4))	
			g_RandomText[5]:SetText(ScriptGlobal_Format("#{SYCY_201225_79}",random5))
			g_Background[index]:SetProperty("Image", g_Imagebk[1])		
			g_BackgroundText[index]:SetProperty("Image", g_Image[index])	
		else
			g_Animate[1]:Play(true)
			g_RandomText[1]:Show()
			g_RandomText[1]:SetText(ScriptGlobal_Format("#{SYCY_201225_79}",random1))	
			g_RandomTextMoQi[1]:Show()
		end
		SpringFestival_Pre1_Tacit_Button:Hide()
		if isgetitem == 0 then
			SpringFestival_Pre1_Reward_Button:Show()
			SpringFestival_Pre1_Icon2_tips:Show()
			SpringFestival_Pre1_Reward_BasicItemReceived:Hide()
		else	
			SpringFestival_Pre1_Reward_Button:Hide()
			SpringFestival_Pre1_Icon2_tips:Hide()
			SpringFestival_Pre1_Reward_BasicItemReceived:Show()
		end
		
		
	end
	this:Show()
	
end	

--=========
-- 点击领奖
--=========
function SpringFestival_Pre1_GetClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetInstrument" )
		Set_XSCRIPT_ScriptID( 888334 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end

--=========
-- 随机幻世武器契合度
--=========
function SpringFestival_Pre1_RandomClick(  )
	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "RandomOne" )
		Set_XSCRIPT_ScriptID( 888334 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	SpringFestival_Pre1_Icon1_tips:Hide()
end

--=========
-- help
--=========
function SpringFestival_Pre1_HelpClick(  )
	PushEvent("CCSHOP_HELP", 129)
end

function SpringFestival_Pre1_AnimateRabbitNext(index)
	g_Animate[index+1]:Play(true)
	g_RandomText[index+1]:Show()
	g_RandomText[index+1]:SetText(ScriptGlobal_Format("#{SYCY_201225_79}",g_Random[index+1]))
	g_RandomTextMoQi[index+1]:Show()
	if index == 4 then
		g_Background[g_index]:SetProperty("Image", g_Imagebk[1])		
		g_BackgroundText[g_index]:SetProperty("Image", g_Image[g_index])	
	end
end
	
