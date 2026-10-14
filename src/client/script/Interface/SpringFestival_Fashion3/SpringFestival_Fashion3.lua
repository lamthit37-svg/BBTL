--2024春节时装获得方式

local g_Frame_UnifiedPosition

--碎片数量上限
local g_MaxCount = 4

--碎片数量
local g_SpringFestival_Fashion3_Num

--领奖标记
local g_SpringFestival_Fashion3_MF

--小红点
local g_RedPoints

--=========
-- PreLoad()
--=========
function SpringFestival_Fashion3_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function SpringFestival_Fashion3_OnLoad()
	
	g_Frame_UnifiedPosition = SpringFestival_Fashion3_Frame:GetProperty("UnifiedPosition")
		
	g_SpringFestival_Fashion3_Num = 0
	g_SpringFestival_Fashion3_MF = 0
	g_RedPoints = 0
	
end

--=========
-- Event
--=========
function SpringFestival_Fashion3_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 99889701) then
	
		local bShow = Get_XParam_INT(0)
		--打开界面
		if bShow == 1 then
			g_SpringFestival_Fashion3_Num = Get_XParam_INT(1)
			g_SpringFestival_Fashion3_MF = Get_XParam_INT(2)
			SpringFestival_Fashion3_Open()
			this:Show()
		--关闭界面
		elseif bShow == 2 then
			SpringFestival_Fashion3_Close()
		--刷新界面
		elseif bShow == 3 then
			if this:IsVisible() then
				g_SpringFestival_Fashion3_Num = Get_XParam_INT(1)
				g_SpringFestival_Fashion3_MF = Get_XParam_INT(2)
				SpringFestival_Fashion3_Open()
			end
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		SpringFestival_Fashion3_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_Fashion3_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		SpringFestival_Fashion3_On_ResetPos()

	end
	
end

--=========
-- Close
--=========
function SpringFestival_Fashion3_Close()

	this:Hide()

end

--=========
-- 重置
--=========
function SpringFestival_Fashion3_On_ResetPos()

	SpringFestival_Fashion3_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function SpringFestival_Fashion3_Open()

	--按钮 + 文字 + 小红点
	if g_SpringFestival_Fashion3_MF == 1 then
		SpringFestival_Fashion3_OKBtn:Disable()
		SpringFestival_Fashion3_OKBtn_Got:Show()
		SpringFestival_Fashion3_HaveText:SetText("")
		SpringFestival_Fashion3_OKBtn_Tip:Hide()
		SpringFestival_Fashion3_HaveTextBK:Hide()
	else
		SpringFestival_Fashion3_OKBtn:Enable()
		SpringFestival_Fashion3_OKBtn_Got:Hide()
		local str = ""
		if g_SpringFestival_Fashion3_Num >= g_MaxCount then
			str = ScriptGlobal_Format("#{CJSZ_231030_05}", g_SpringFestival_Fashion3_Num)
			SpringFestival_Fashion3_OKBtn_Tip:Show()
		else
			str = ScriptGlobal_Format("#{CJSZ_231030_06}", g_SpringFestival_Fashion3_Num)
			SpringFestival_Fashion3_OKBtn_Tip:Hide()
		end
		SpringFestival_Fashion3_HaveText:SetText(str)
		SpringFestival_Fashion3_HaveTextBK:Show()
	end
	SpringFestival_Fashion3_HaveText2:SetText("#{CJSZ_231030_07}")

end

--=========
-- 点击领奖
--=========
function SpringFestival_Fashion3_BtnClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "CheckItemState" )
		Set_XSCRIPT_ScriptID( 998897 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end

--========
-- 预览
--========
function SpringFestival_Fashion3_Preview()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Parameter(0, 10128584)
		Set_XSCRIPT_Parameter(1, 283)--hairId
		Set_XSCRIPT_Parameter(2, 207)--faceid
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	
end

--=========
-- 问号帮助
--=========
function SpringFestival_Fashion3_HelpClick()
	PushEvent("CCSHOP_HELP", 138)
end
