--Armor_Tips
--!!!reloadscript =Armor_Tips
local g_WindowType = -1    --0:自己  1:其他人
local g_UA_Index = -1

local g_UA_Rank_Name = {
	"#{NJBZ_220816_333}",
	"#{NJBZ_220816_334}",
	"#{NJBZ_220816_335}",
	"#{NJBZ_220816_336}",
	"#{NJBZ_220816_337}",
	"#{NJBZ_220816_338}",
}

function Armor_Tips_PreLoad()
	this:RegisterEvent("OPEN_UNDERARMOUR_TIP", true)
	this:RegisterEvent("OPEN_TARGET_UNDERARMOUR_TIP", true)
	this:RegisterEvent("CLOSE_UNDERARMOUR_TIP", false)
	this:RegisterEvent("CLOSE_TARGET_UNDERARMOUR_TIP", false)
end

function Armor_Tips_OnLoad()
	
end
--=========
--OnEvent
--=========
function Armor_Tips_OnEvent(event)

	if event == "OPEN_UNDERARMOUR_TIP" then
		g_WindowType = 0
		g_UA_Index = tonumber(arg0)
		local SetX = tonumber(arg1)
		local SetY = tonumber(arg2)
		local SetWidth = tonumber(arg3)
		local SetHeight = tonumber(arg4)
		Armor_Tips_CleanUp()
		Armor_Tips_Update_Self()
		Armor_Tips_Frame:PositionSelf(SetX, SetY, SetX + SetWidth, SetY + SetHeight)
		this:Show()
		return
	end
	
	if event == "OPEN_TARGET_UNDERARMOUR_TIP" then		
		g_WindowType = 1
		g_UA_Index = tonumber(arg0)
		local SetX = tonumber(arg1)
		local SetY = tonumber(arg2)
		local SetWidth = tonumber(arg3)
		local SetHeight = tonumber(arg4)
		Armor_Tips_CleanUp()
		Armor_Tips_Update_Other()
		Armor_Tips_Frame:PositionSelf(SetX, SetY, SetX + SetWidth, SetY + SetHeight)
		this:Show()
		return
	end
	
	if event == "CLOSE_UNDERARMOUR_TIP" then
		this:Hide()
		return
	end
	
	if event == "CLOSE_TARGET_UNDERARMOUR_TIP" then
		this:Hide()
		return
	end
	
end

function Armor_Tips_CleanUp()
	Armor_Tips_Title:SetText("")
	Armor_Tips_ArmorIcon:SetProperty("Image", "")
	Armor_Tips_ArmorText1:SetText("")
	Armor_Tips_ArmorText2:SetText("")
	Armor_Tips_Attr:SetText("")
end

function Armor_Tips_Update_Self()	

	local toDisplay = ""
	toDisplay = toDisplay .."Armor_Tips_PageHeader"
	toDisplay = toDisplay ..";Armor_Tips_Attr"
	Armor_Tips_Frame:SetProperty("PageElements",  toDisplay)

	if g_UA_Index >= 1 and g_UA_Index <= 3 then

		local strTemp = ""

		local strName = DataPool:LuaFnGetUnderArmourInfo(g_UA_Index - 1, "NAME")
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_18}", tostring(strName))
		Armor_Tips_Title:SetText(strTemp)
		
		local iLevel = DataPool:LuaFnGetUnderArmourData(g_UA_Index - 1, "LEVEL")
		local iRank = DataPool:LuaFnGetUnderArmourData(g_UA_Index - 1, "RANK")
		local iStar = DataPool:LuaFnGetUnderArmourData(g_UA_Index - 1, "STAR")
		local iJewel = DataPool:LuaFnGetUnderArmourData(g_UA_Index - 1, "JEWEL")
		
		local strIcon = DataPool:LuaFnGetUnderArmourInfo(g_UA_Index - 1, "ICON", iRank)
		local strIconImage = GetIconFullName(tostring(strIcon))
		Armor_Tips_ArmorIcon:SetProperty("Image", tostring(strIconImage))
		
		local _, _, _, _, _, fix_rate = DataPool:LuaFnGetUnderArmourStarUpInfo(iStar)
		local percent_str = Armor_Tips_GetPercentageString(fix_rate)
		if iStar == 0 then
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_391}", tostring(iStar))
			Armor_Tips_ArmorText1:SetText(strTemp)
		else
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_19}", tostring(iStar), percent_str)
			Armor_Tips_ArmorText1:SetText(strTemp)
		end
		
		if iRank == 5 then
			Armor_Tips_ArmorText2:SetText("#{NJBZ_220816_445}")
		else
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_20}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel))
			Armor_Tips_ArmorText2:SetText(strTemp)
		end
		
		local strDesc = ""
		strTemp = DataPool:LuaFnGetUnderArmourMainAttrDesc(g_UA_Index - 1, iRank, iLevel, iStar)
		strDesc = strTemp
		
		local iExCount = DataPool:LuaFnGetUnderArmourData(g_UA_Index - 1, "EX_COUNT")
		for i = 1, 7 do
			if i <= iExCount then
				local ex_id = DataPool:LuaFnGetUnderArmourData(g_UA_Index - 1, "EX_ATTR", i - 1)
				strTemp = DataPool:LuaFnGetUnderArmourExAttrDesc(g_UA_Index - 1, ex_id, iRank, iLevel, iStar)
				strDesc = strDesc.."#r"..strTemp
			end
		end
		
		Armor_Tips_Attr:SetText(strDesc)
	else
	end
end

function Armor_Tips_Update_Other()
	local toDisplay = ""
	toDisplay = toDisplay .."Armor_Tips_PageHeader"
	toDisplay = toDisplay ..";Armor_Tips_Attr"
	Armor_Tips_Frame:SetProperty("PageElements",  toDisplay)

	if g_UA_Index >= 1 and g_UA_Index <= 3 then

		local strTemp = ""

		local strName = DataPool:LuaFnGetUnderArmourInfo(g_UA_Index - 1, "NAME")
		strTemp = ScriptGlobal_Format("#{NJBZ_220816_18}", tostring(strName))
		Armor_Tips_Title:SetText(strTemp)
		
		local iLevel = DataPool:LuaFnGetOtherUnderArmourData(g_UA_Index - 1, "LEVEL")
		local iRank = DataPool:LuaFnGetOtherUnderArmourData(g_UA_Index - 1, "RANK")
		local iStar = DataPool:LuaFnGetOtherUnderArmourData(g_UA_Index - 1, "STAR")
		local iJewel = DataPool:LuaFnGetOtherUnderArmourData(g_UA_Index - 1, "JEWEL")
		
		local strIcon = DataPool:LuaFnGetUnderArmourInfo(g_UA_Index - 1, "ICON", iRank)
		local strIconImage = GetIconFullName(tostring(strIcon))
		Armor_Tips_ArmorIcon:SetProperty("Image", tostring(strIconImage))
		
		local _, _, _, _, _, fix_rate = DataPool:LuaFnGetUnderArmourStarUpInfo(iStar)
		local percent_str = Armor_Tips_GetPercentageString(fix_rate)
		if iStar == 0 then
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_391}", tostring(iStar))
			Armor_Tips_ArmorText1:SetText(strTemp)
		else
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_19}", tostring(iStar), percent_str)
			Armor_Tips_ArmorText1:SetText(strTemp)
		end
		
		if iRank == 5 then
			Armor_Tips_ArmorText2:SetText("#{NJBZ_220816_445}")
		else
			strTemp = ScriptGlobal_Format("#{NJBZ_220816_20}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel))
			Armor_Tips_ArmorText2:SetText(strTemp)
		end
		
		local strDesc = ""
		strTemp = DataPool:LuaFnGetUnderArmourMainAttrDesc(g_UA_Index - 1, iRank, iLevel, iStar)
		strDesc = strTemp
		
		local iExCount = DataPool:LuaFnGetOtherUnderArmourData(g_UA_Index - 1, "EX_COUNT")
		for i = 1, 7 do
			if i <= iExCount then
				local ex_id = DataPool:LuaFnGetOtherUnderArmourData(g_UA_Index - 1, "EX_ATTR", i - 1)
				strTemp = DataPool:LuaFnGetUnderArmourExAttrDesc(g_UA_Index - 1, ex_id, iRank, iLevel, iStar)
				strDesc = strDesc.."#r"..strTemp
			end
		end
		
		Armor_Tips_Attr:SetText(strDesc)
	else

	end
end

function Armor_Tips_GetPercentageString(num)
	if tonumber(num) == nil then
		return ""
	end
	
	local intPart = math.floor(num / 100)
	local floatPart = math.floor(math.mod(num, 100) / 10)
			
	if floatPart == 0 then
		return tostring(intPart)
	else
		return tostring(intPart).."."..tostring(floatPart)
	end
end

