--!!!reloadscript =Rune_Stars_Piece

local g_Rune_Stars_Piece_UnifiedPosition = ""
local g_XingJuanID = 0
local g_CurNum = 1
local g_MaxCount = 0
local g_Chip2Token = {5,45,200,50}

function Rune_Stars_Piece_PreLoad()
	this:RegisterEvent("OPEN_XINGZHEN_CHIP")
	this:RegisterEvent("XINGZHEN_UPDATE",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Rune_Stars_Piece_OnLoad()
	g_Rune_Stars_Piece_UnifiedPosition = Rune_Stars_Piece_Frame:GetProperty("UnifiedPosition")
end

function Rune_Stars_Piece_OnEvent(event)
	
	if event == "OPEN_XINGZHEN_CHIP" then
		g_XingJuanID = tonumber(arg0)
		this:Show()
		g_CurNum = 1
		Rune_Stars_Piece_Frame:SetForce()
		Rune_Stars_Piece_Update()
	end
	
	if event == "XINGZHEN_UPDATE" then

		if arg0 == "melt" then
			this:Hide()
		else
			Rune_Stars_Piece_Update()
		end		
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Rune_Stars_Piece_On_ResetPos()
	end
end

function Rune_Stars_Piece_Update()

	if g_XingJuanID == 0 then
		return
	end
	
	Rune_Stars_PieceBtn:SetActionItem(-1)
	local theAction = EnumAction(g_XingJuanID,"xingjuanchip")
	if theAction:GetID() ~= 0 then
		Rune_Stars_PieceBtn:SetActionItem(theAction:GetID())
	end	
	Rune_Stars_PieceBtn:SetProperty("DraggingEnabled","False")
	
	local strName = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Name")
	local nUnLocked = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "UnLocked")
	local nOrder = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Order")
	
	if nUnLocked == 0 then
		Rune_Stars_Piece_Text:SetText("#L"..strName.."#{XZJC_200309_276}#{XZJC_200309_339}")
	elseif nOrder == 5 then
		Rune_Stars_Piece_Text:SetText("#L"..strName.."#{XZJC_200309_276}#{XZJC_200309_341}")
	else
		Rune_Stars_Piece_Text:SetText("#L"..strName.."#{XZJC_200309_276}#{XZJC_200309_340}")
	end	
	
	local nChipCount = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "ChipCount")
	local strTemp = ScriptGlobal_Format("#{XZJC_200309_81}",tostring(nChipCount))
	Rune_Stars_Piece_Text2:SetText(strTemp)
	g_MaxCount = nChipCount
	Rune_Stars_Piece_NumberInput:SetText(tostring(g_CurNum))
	Rune_Stars_Piece_UpdateRet()
end

function Rune_Stars_Piece_UpdateRet()
	
	local nQual = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Quality")
	local nReturnCount = g_CurNum
	if g_Chip2Token[nQual] then
		nReturnCount = g_CurNum * g_Chip2Token[nQual]
	end

	local nQuality = DataPool:LuaFnGetXingJuanInfo(g_XingJuanID, "Quality")
	if nQuality == 4 then
		local strTemp = ScriptGlobal_Format("#{XZJC_200309_83}",tostring(nReturnCount), "#{XZJC_200309_218}")
		Rune_Stars_Piece_Text4:SetText(strTemp)
	
		Rune_Stars_Piece_Image:SetProperty("Image","set:GuiShi_Clue_1 image:ClueType1")
	else
		local strTemp = ScriptGlobal_Format("#{XZJC_200309_83}",tostring(nReturnCount), "#{XZJC_200309_219}")
		Rune_Stars_Piece_Text4:SetText(strTemp)
		
		Rune_Stars_Piece_Image:SetProperty("Image","set:GuiShi_Clue_1 image:ClueType2")
	end
end

function Rune_Stars_Piece_Max()
	if g_CurNum >= g_MaxCount then	
		return 
	end
	
	g_CurNum = g_MaxCount
	
	Rune_Stars_Piece_NumberInput:SetText(tostring(g_CurNum))
	Rune_Stars_Piece_UpdateRet()
end

function Rune_Stars_Piece_CalMin()
	
	if g_CurNum <= 1 then
		return
	end	
	
	g_CurNum = g_CurNum - 1

	Rune_Stars_Piece_NumberInput:SetText(tostring(g_CurNum))
	Rune_Stars_Piece_UpdateRet()
end

function Rune_Stars_Piece_CalMax()
	
	if g_CurNum >= g_MaxCount then	
		return 
	end
	
	g_CurNum = g_CurNum + 1
	
	Rune_Stars_Piece_NumberInput:SetText(tostring(g_CurNum))
	Rune_Stars_Piece_UpdateRet()
end

function Rune_Stars_Piece_TextChanged()
	
	local nString = Rune_Stars_Piece_NumberInput:GetText()
	
	local nChangNum = 1
	
	if nString == nil or nString == "" then
		nChangNum = 1
	else
		nChangNum = tonumber(nString)
	end
	
	if nChangNum >= g_MaxCount then
		nChangNum = g_MaxCount
	end
	
	if nChangNum <= 0 then
		nChangNum = 1
	end
	
	if g_CurNum ~= tonumber(nString) then
		
		g_CurNum = nChangNum
		
		Rune_Stars_Piece_NumberInput:SetText(g_CurNum)
		
		Rune_Stars_Piece_UpdateRet()
	end
end

function Rune_Stars_Piece_OK()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MeltChip")
		Set_XSCRIPT_ScriptID(888555)
		Set_XSCRIPT_Parameter(0, g_XingJuanID)
		Set_XSCRIPT_Parameter(1, g_CurNum)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function Rune_Stars_Piece_Close()
	this:Hide()
end

function Rune_Stars_Piece_OnHidden()
	Rune_Stars_PieceBtn:SetActionItem(-1)
end

function Rune_Stars_Piece_On_ResetPos()
	if g_Rune_Stars_Piece_UnifiedPosition ~= nil then
		Rune_Stars_Piece_Frame:SetProperty("UnifiedPosition", g_Rune_Stars_Piece_UnifiedPosition)
	end
end


--!!!reloadscript =Rune_Stars_Piece
