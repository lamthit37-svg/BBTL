
local g_NewExterior_TuJing_UnifiedPosition = ""

local g_NewExterior_TuJing_Type = -1
local g_NewExterior_TuJing_ExteriorId = -1
local g_NewExterior_TuJing_TypeEx = -1
local g_NewExterior_TuJing_ExteriorIdEx = -1

local g_NewExterior_TuJing_Page = 0

local g_NewExterior_TuJing_Text = {}

local g_NewExterior_TuJing_Str = {
[0] = "#{SZDP_230509_22}",	-- 坐骑：0
[1] = "#{SZDP_230509_21}",	-- 幻武：1
[2] = "#{SZDP_230509_25}",	-- 附体：2
[3] = "#{SZDP_230509_23}",	-- 脸型：3
[4] = "#{SZDP_230509_24}",	-- 发型：4
[5] = "#{SZDP_230509_26}",	-- 头像：5
[6] = "#{SZDP_230509_70}",	-- 头像框：6
[100] = "#{SZDP_230509_28}",	-- 头饰：100
[101] = "#{SZDP_230509_27}",	-- 背饰：101
[102] = "#{SZDP_230509_20}",	-- 时装：102
[103] = "#{SZDP_230509_71}",	-- 配饰：103
}

--===============================================
-- OnLoad()
--===============================================
function NewExterior_TuJing_PreLoad()

	this:RegisterEvent("OPEN_EXTERIOR_TUJING");
	
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function NewExterior_TuJing_OnLoad()

	g_NewExterior_TuJing_UnifiedPosition = NewExterior_TuJing_Frame:GetProperty("UnifiedPosition")
	
	g_NewExterior_TuJing_Text = { NewExterior_TuJing_Text1, NewExterior_TuJing_Text2, NewExterior_TuJing_Text3 }
	
end

--===============================================
-- OnEvent()
--===============================================
function NewExterior_TuJing_OnEvent( event )
	if event == "OPEN_EXTERIOR_TUJING" then
		if arg0 and arg1 then
		
			g_NewExterior_TuJing_Type = tonumber(arg0)			
			g_NewExterior_TuJing_ExteriorId = tonumber(arg1)
			
			g_NewExterior_TuJing_TypeEx = tonumber(arg2)
			g_NewExterior_TuJing_ExteriorIdEx = tonumber(arg3)

			NewExterior_TuJing_Frame:SetForce()
	
			NewExterior_TuJing_PageClick(1)
			
		else
		
			NewExterior_TuJing_CloseClick()
			
		end
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
	
		NewExterior_TuJing_CloseClick()
		
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
	
		NewExterior_TuJing_Frame:SetProperty("UnifiedPosition", g_NewExterior_TuJing_UnifiedPosition)
		
	end
	
end

function NewExterior_TuJing_OnShow()

	if g_NewExterior_TuJing_Str[g_NewExterior_TuJing_Type] == nil then
		NewExterior_TuJing_CloseClick()
		return
	end

	for i = 1, table.getn(g_NewExterior_TuJing_Text) do
		g_NewExterior_TuJing_Text[i]:SetChatString("")
	end
	
	if g_NewExterior_TuJing_Str[g_NewExterior_TuJing_TypeEx] == nil then 
		g_NewExterior_TuJing_Page = 1		
		NewExterior_TuJing_Btn2:Hide()
	end

	local TextCount = 0
	local TextName = ""
	local textList = {} 
	if g_NewExterior_TuJing_Page == 2 then
		TextCount, TextName, textList[1], textList[2], textList[3] = Exterior:LuaFnGetExteriorTuJingInfo(g_NewExterior_TuJing_TypeEx, g_NewExterior_TuJing_ExteriorIdEx)
	else
		TextCount, TextName, textList[1], textList[2], textList[3] = Exterior:LuaFnGetExteriorTuJingInfo(g_NewExterior_TuJing_Type, g_NewExterior_TuJing_ExteriorId)
	end
	if TextCount > 0 then
		for i = 1, TextCount do
			if textList[i] and textList[i] ~= "-1" then
				g_NewExterior_TuJing_Text[i]:SetChatString("#cffe1b8"..textList[i])
			end
		end
	else
		g_NewExterior_TuJing_Text[1]:SetChatString("#{SZDP_230509_69}")
	end

	if g_NewExterior_TuJing_Str[g_NewExterior_TuJing_Type] ~= nil then
		NewExterior_TuJing_Btn1:SetText(g_NewExterior_TuJing_Str[g_NewExterior_TuJing_Type])
	end
	
	if g_NewExterior_TuJing_Str[g_NewExterior_TuJing_TypeEx] ~= nil then
		NewExterior_TuJing_Btn2:Show()
		NewExterior_TuJing_Btn2:SetText(g_NewExterior_TuJing_Str[g_NewExterior_TuJing_TypeEx])
	end
	
	this:Show()
	
end

function NewExterior_TuJing_PageClick(Idx)

	if Idx == 1 then
		NewExterior_TuJing_Btn1:SetCheck(1)
		NewExterior_TuJing_Btn2:SetCheck(0)
		
		g_NewExterior_TuJing_Page = 1
		
		NewExterior_TuJing_OnShow()
	elseif Idx == 2 then
		NewExterior_TuJing_Btn1:SetCheck(0)
		NewExterior_TuJing_Btn2:SetCheck(1)
		
		g_NewExterior_TuJing_Page = 2
		
		NewExterior_TuJing_OnShow()
	else
		-- 要不关了
		NewExterior_TuJing_CloseClick()
	end
	
end

function NewExterior_TuJing_CloseClick()
	this:Hide()
end

function NewExterior_TuJing_OnHidden()
	
	g_NewExterior_TuJing_Type = -1
	g_NewExterior_TuJing_ExteriorId = -1
	g_NewExterior_TuJing_TypeEx = -1
	g_NewExterior_TuJing_ExteriorIdEx = -1

end


