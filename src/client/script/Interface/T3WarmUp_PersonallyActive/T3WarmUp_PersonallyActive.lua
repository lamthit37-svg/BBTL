--T3WarmUp_PersonallyActive.lua
--2020 新天外预热整合界面
local g_Frame_UnifiedPosition
local g_Index_Stage = 0
local g_Index_Wanfa = 0
local g_ItemNum_BMZY = {}
local g_RedPointMF = 0

local g_WanFa_Info ={
	"#{TWYR_200908_189}",
	"#{TWYR_200908_190}",
	"#{TWYR_200908_191}",
}
local g_BMZY_Info ={
	{szItemName = "#{TWYR_200908_177}"},
	{szItemName = "#{TWYR_200908_180}"},
	{szItemName = "#{TWYR_200908_183}"},
	{szItemName = "#{TWYR_200908_186}"},
	{szItemName = "#{TWYR_200908_178}"},
	{szItemName = "#{TWYR_200908_181}"},
	{szItemName = "#{TWYR_200908_184}"},
	{szItemName = "#{TWYR_200908_187}"},
	{szItemName = "#{TWYR_200908_179}"},
	{szItemName = "#{TWYR_200908_182}"},
	{szItemName = "#{TWYR_200908_185}"},
	{szItemName = "#{TWYR_200908_188}"},
}

local g_BMZY_Bajing_HisHuiZhi = 0
local g_BMZY_Bajing_HuiZhiCount = 0
local g_BMZY_Bajing_Info = {
	{nAllNum = 1, szName="#{TWYR_200908_154}"},
	{nAllNum = 2, szName="#{TWYR_200908_155}"},
	{nAllNum = 3, szName="#{TWYR_200908_156}"},
	{nAllNum = 5, szName="#{TWYR_200908_157}"},	
	{nAllNum = 7, szName="#{TWYR_200908_158}"},	
	{nAllNum = 9, szName="#{TWYR_200908_159}"},	
	{nAllNum = 12, szName="#{TWYR_200908_160}"},	
	{nAllNum = 16, szName="#{TWYR_200908_161}"},	
}

local g_BMZY_UIControl ={}
local g_WanFa_UIControl ={}
local g_Finish_UIControl ={}
local g_BMZYPoint_UIControl ={}
--===============================================
-- OnLoad()
--===============================================
function T3WarmUp_PersonallyActive_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
end
function T3WarmUp_PersonallyActive_OnLoad()
	g_Frame_UnifiedPosition = T3WarmUp_PersonallyActive_Frame:GetProperty("UnifiedPosition")
	g_BMZY_UIControl ={
	[1] = {	biUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame1_Btn1, T3WarmUp_PersonallyActive_Status2_OperateFrame1_Text1, },
			moUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame2_Btn1, T3WarmUp_PersonallyActive_Status2_OperateFrame2_Text1, },
			zhiUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame3_Btn1, T3WarmUp_PersonallyActive_Status2_OperateFrame3_Text1,},
			yanUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame4_Btn1, T3WarmUp_PersonallyActive_Status2_OperateFrame4_Text1,},
			},
	[2] = {	biUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame1_Btn2, T3WarmUp_PersonallyActive_Status2_OperateFrame1_Text2, }, 
			moUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame2_Btn2, T3WarmUp_PersonallyActive_Status2_OperateFrame2_Text2, },
			zhiUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame3_Btn2, T3WarmUp_PersonallyActive_Status2_OperateFrame3_Text2, },
			yanUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame4_Btn2, T3WarmUp_PersonallyActive_Status2_OperateFrame4_Text2, },
			},
	[3] = {	biUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame1_Btn3, T3WarmUp_PersonallyActive_Status2_OperateFrame1_Text3, },
			moUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame2_Btn3, T3WarmUp_PersonallyActive_Status2_OperateFrame2_Text3, },
			zhiUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame3_Btn3, T3WarmUp_PersonallyActive_Status2_OperateFrame3_Text3, },
			yanUI = {T3WarmUp_PersonallyActive_Status2_OperateFrame4_Btn3, T3WarmUp_PersonallyActive_Status2_OperateFrame4_Text3, },
			},
	}
	g_Finish_UIControl = {
		[1] = {T3WarmUp_PersonallyActive_Status2_OperateFrame1_Tips1, T3WarmUp_PersonallyActive_Status2_OperateFrame1_Tips2},
		[2] = {T3WarmUp_PersonallyActive_Status2_OperateFrame2_Tips1, T3WarmUp_PersonallyActive_Status2_OperateFrame2_Tips2},
		[3] = {T3WarmUp_PersonallyActive_Status2_OperateFrame3_Tips1, T3WarmUp_PersonallyActive_Status2_OperateFrame3_Tips2},
		[4] = {T3WarmUp_PersonallyActive_Status2_OperateFrame4_Tips1, T3WarmUp_PersonallyActive_Status2_OperateFrame4_Tips2},
	}
	g_WanFa_UIControl = {
		[1] = {T3WarmUp_PersonallyActive_Status1_Pic1, T3WarmUp_PersonallyActive_Status1_Pic2, T3WarmUp_PersonallyActive_Status1_Pic3},
		[2] = {T3WarmUp_PersonallyActive_Status2_Pic1, T3WarmUp_PersonallyActive_Status2_Pic2, T3WarmUp_PersonallyActive_Status2_Pic3},
		[3] = {T3WarmUp_PersonallyActive_Status3_Pic1, T3WarmUp_PersonallyActive_Status3_Pic2, T3WarmUp_PersonallyActive_Status3_Pic3},
	}
	g_BMZYPoint_UIControl = {		
		T3WarmUp_PersonallyActive_Status2_OperateFrame1_TextTips,
		T3WarmUp_PersonallyActive_Status2_OperateFrame2_TextTips,
		T3WarmUp_PersonallyActive_Status2_OperateFrame3_TextTips,
		T3WarmUp_PersonallyActive_Status2_OperateFrame4_TextTips,
	}
end

--===============================================
-- OnEvent()
--===============================================
function T3WarmUp_PersonallyActive_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		T3WarmUp_PersonallyActive_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		T3WarmUp_PersonallyActive_Close()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 15530001 ) then
		if Get_XParam_INT( 0 ) == 0 then 
			T3WarmUp_PersonallyActive_Close()
			return
		end
		g_Index_Stage = Get_XParam_INT( 1 )
		g_Index_Wanfa = Get_XParam_INT( 2 )
		g_ItemNum_BMZY[1] = Get_XParam_INT( 3 )
		g_ItemNum_BMZY[2] = Get_XParam_INT( 4 )
		g_ItemNum_BMZY[3] = Get_XParam_INT( 5 )
		g_ItemNum_BMZY[4] = Get_XParam_INT( 6 )
		g_RedPointMF = Get_XParam_INT( 7 )
		g_BMZY_Bajing_HisHuiZhi = Get_XParam_INT( 8 )
		g_BMZY_Bajing_HuiZhiCount = Get_XParam_INT( 9 )
		T3WarmUp_PersonallyActive_UpdateInfo()
		this:Show()
	end
end
function T3WarmUp_PersonallyActive_Close()
	this:Hide()
end
--===============================================
--===============================================
function T3WarmUp_PersonallyActive_UpdateInfo()
	T3WarmUp_PersonallyActive_Status1:Hide()
	T3WarmUp_PersonallyActive_Status2:Hide()
	T3WarmUp_PersonallyActive_Status3:Hide()
	if g_Index_Stage == 2 then 
		T3WarmUp_PersonallyActive_Status3:Show()
	elseif g_Index_Stage == 1 then 
		T3WarmUp_PersonallyActive_Status2:Show()
	else
		T3WarmUp_PersonallyActive_Status1:Show()
	end

	local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
	if nToadyActivePoint >= 200 then 
		T3WarmUp_PersonallyActive_Status1_InfoText:SetText( ScriptGlobal_Format("#{TWYR_200908_65}", 200))
	else
		T3WarmUp_PersonallyActive_Status1_InfoText:SetText( ScriptGlobal_Format("#{TWYR_200908_64}", nToadyActivePoint))
	end		
	
	for i = 1, 3 do
		if i == g_Index_Wanfa+1 then
			for j = 1, 3 do
				g_WanFa_UIControl[j][i]:Show()
			end	
			
			g_BMZY_UIControl[i].biUI[1]:Show()
			g_BMZY_UIControl[i].moUI[1]:Show()
			g_BMZY_UIControl[i].zhiUI[1]:Show()
			g_BMZY_UIControl[i].yanUI[1]:Show()
			g_BMZY_UIControl[i].biUI[2]:Show()
			g_BMZY_UIControl[i].moUI[2]:Show()
			g_BMZY_UIControl[i].zhiUI[2]:Show()
			g_BMZY_UIControl[i].yanUI[2]:Show()
		else
			for j = 1, 3 do
				g_WanFa_UIControl[j][i]:Hide()
			end		
			
			g_BMZY_UIControl[i].biUI[1]:Hide()
			g_BMZY_UIControl[i].moUI[1]:Hide()
			g_BMZY_UIControl[i].zhiUI[1]:Hide()
			g_BMZY_UIControl[i].yanUI[1]:Hide()
			g_BMZY_UIControl[i].biUI[2]:Hide()
			g_BMZY_UIControl[i].moUI[2]:Hide()
			g_BMZY_UIControl[i].zhiUI[2]:Hide()
			g_BMZY_UIControl[i].yanUI[2]:Hide()
		end
	end
	
	local IsShowRedPoint = 0
	for j = 1, 4 do
		if g_ItemNum_BMZY[j] > 0 then
			g_Finish_UIControl[j][1]:Hide()
			g_Finish_UIControl[j][2]:Show()
			-- 收集按钮上的小红点
			IsShowRedPoint = IsShowRedPoint + 1
			-- 笔墨纸砚上的小红点
			g_BMZYPoint_UIControl[j]:Hide()
		else
			g_Finish_UIControl[j][1]:Show()
			g_Finish_UIControl[j][2]:Hide()
			g_BMZYPoint_UIControl[j]:Show()
		end
	end
	
	if IsShowRedPoint == 4 then
		T3WarmUp_PersonallyActive_Status2_SubmitTips:Show()
		T3WarmUp_PersonallyActive_Status2_SubmitBtn:Show()
	else
		T3WarmUp_PersonallyActive_Status2_SubmitTips:Hide()
		T3WarmUp_PersonallyActive_Status2_SubmitBtn:Hide()
	end
	
	T3WarmUp_PersonallyActive_Status2_InfoText:SetText( ScriptGlobal_Format("#{TWYR_200908_71}", g_WanFa_Info[g_Index_Wanfa+1] or "nil") )
	T3WarmUp_PersonallyActive_Status3_InfoText:SetText( ScriptGlobal_Format("#{TWYR_200908_216}", g_WanFa_Info[g_Index_Wanfa+1] or "nil") )
	
	if g_Index_Stage == 2 and g_BMZY_Bajing_Info[g_BMZY_Bajing_HisHuiZhi] ~= nil then 
		if g_BMZY_Bajing_HuiZhiCount >= g_BMZY_Bajing_Info[g_BMZY_Bajing_HisHuiZhi].nAllNum then
			local str = ScriptGlobal_Format("#{TWYR_200908_218}", g_BMZY_Bajing_HuiZhiCount, g_BMZY_Bajing_Info[g_BMZY_Bajing_HisHuiZhi].szName)
			T3WarmUp_PersonallyActive_Status3_InfoText2:SetText( str )
		else
			local str = ScriptGlobal_Format("#{TWYR_200908_217}", g_BMZY_Bajing_HuiZhiCount, g_BMZY_Bajing_Info[g_BMZY_Bajing_HisHuiZhi].nAllNum, g_BMZY_Bajing_Info[g_BMZY_Bajing_HisHuiZhi].szName)
			T3WarmUp_PersonallyActive_Status3_InfoText2:SetText( str )
		end
	end
	
	if g_RedPointMF == 0 then
		T3WarmUp_PersonallyActive_Status1_LetterTips:Show()
	else
		T3WarmUp_PersonallyActive_Status1_LetterTips:Hide()
	end
end

function T3WarmUp_PersonallyActive_GotoClicked()
	T3WarmUp_PersonallyActive_Close()
	SetAutoRunTargetNPCName("张择端");
	AutoRunToTargetEx(290,261,0)
end
function T3WarmUp_PersonallyActive_EndBiMoZhiYan()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("EndBiMoZhiYan")
		Set_XSCRIPT_ScriptID(888233)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function T3WarmUp_PersonallyActive_GotoBMZYNPC(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GotoBMZYNPC")
		Set_XSCRIPT_ScriptID(888233)
		Set_XSCRIPT_Parameter( 0, nIndex )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function T3WarmUp_PersonallyActive_LetterClicked()

	T3WarmUp_PersonallyActive_Status1_LetterTips:Hide()

	PushEvent("UI_COMMAND", 15630001, 1)
	
	if g_RedPointMF == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("SetLetterRedPoint")
			Set_XSCRIPT_ScriptID(888233)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end
function T3WarmUp_PersonallyActive_HelpClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpTips")
		Set_XSCRIPT_ScriptID(888233)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end
