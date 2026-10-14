
local g_nContentButton = {}

local g_CurrentSelect = 1

local g_MaxMissionNeed = 15

local g_WuLinCharts_MaxIndex = 31

local g_lineNumToIndex =		-- [PlayerQuicklyEnter.lua]中也保存了一份, 修改的时候, 需要同步修改
{
	[0] = 0, [1] = 20, [2] = 26, [3] = 31, [4] = 1, [5] = 2,[6] = 3, [7] = 4, [8] = 5, [9] = 17, [10] = 23, [11] = 29, [12] = 30, [13] = 6, [14] = 7, [15] = 8, [16] = 27, 
	[17] = 16, [18] = 9, [19] = 10, [20] = 11, [21] = 18, [22] = 12, [23] = 15, [24] = 19, [25] = 21,[26] = 24, [27] = 28,[28] = 13, [29] = 14, [30] = 22, [31] = 25,
}

local g_DZD_forbid = { --1是开启 0是隐藏
	[0] = 1, [1] = 1, [2] = 0, [3] = 1, [4] = 1, [5] = 1,[6] = 1, [7] = 1, [8] = 1, [9] = 1, [10] = 1, [11] = 0, [12] = 1, [13] = 1, [14] = 1, [15] = 1, [16] = 0, 
	[17] = 0, [18] = 1, [19] = 1, [20] = 1, [21] = 1, [22] = 0, [23] = 0, [24] = 0, [25] = 0,[26] = 0, [27] = 0 ,[28] = 1, [29] = 1, [30] = 1, [31] = 0,
}
local g_2606S_forbid = { ----1是开启 0是隐藏
	[0] = 1, [1] = 0, [2] = 0, [3] = 0, [4] = 1, [5] = 1,[6] = 1, [7] = 1, [8] = 1, [9] = 1, [10] = 1, [11] = 0, [12] = 1, [13] = 1, [14] = 1, [15] = 1, [16] = 0, 
	[17] = 0, [18] = 1, [19] = 1, [20] = 1, [21] = 0, [22] = 0, [23] = 0, [24] = 0, [25] = 0,[26] = 0, [27] = 0	 ,[28] = 0, [29] = 1, [30] = 0, [31] = 0,
}
--隐藏索引对照表 
local g_DZD_forbid_xmltoindex = {}

local g_ActionButton = {}

local g_ActionMask = {}

local g_IsOpenByHXL = 0

local g_KajiTable_FYL = {
	--type0 不卡级
	[0] = 31,
	--type1 卡69 最大到65级的武魂
	[1] = 13
}

local g_ZMYD_Intro = {
[0]=	"#{ZMYD_230801_02}",
[1]=	"#{ZMYD_230801_22}",
[2]=	"#{ZMYD_230801_23}",
[3]=	"#{ZMYD_230801_24}",
[4]=	"#{ZMYD_230801_25}",
[5]=	"#{ZMYD_230801_26}",
[6]=	"#{ZMYD_230801_27}",
[7]=	"#{ZMYD_230801_28}",
[8]=	"#{ZMYD_230801_29}",
[10]=	"#{ZMYD_230801_30}",
[11]=	"#{ZMYD_230801_31}",
[12]=	"#{ZMYD_230801_32}",
[13]=	"#{ZMYD_230801_33}",
[14]=	"#{ZMYD_230801_34}",
[15]=	"#{ZMYD_230801_700}",--menpai15 mptodo
}

function WuLinCharts_PreLoad()
	this:RegisterEvent("TOGGLE_FENGYUNLU")
	this:RegisterEvent("FENGYUNLU_UPDATE_MISSION")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("OPEN_FENGYUNLU_WITH_ID");		--打开特定页
	this:RegisterEvent("UI_COMMAND",true)
end


function WuLinCharts_OnLoad()
	g_ActionButton[0] =  WuLinChartsFrame_Item1
	g_ActionButton[1] =  WuLinChartsFrame_Item2
	g_ActionButton[2] =  WuLinChartsFrame_Item3
	g_ActionButton[3] =  WuLinChartsFrame_Item4
	g_ActionButton[4] =  WuLinChartsFrame_Item5

	g_ActionMask[1] =  WuLinChartsFrame_Item1_Mask
	g_ActionMask[2] =  WuLinChartsFrame_Item2_Mask
	g_ActionMask[3] =  WuLinChartsFrame_Item3_Mask
	g_ActionMask[4] =  WuLinChartsFrame_Item4_Mask
	g_ActionMask[5] =  WuLinChartsFrame_Item5_Mask

end


function WuLinCharts_OnEvent(event)
	if event == "TOGGLE_FENGYUNLU" then
		if this:IsVisible() then
			this:Hide()
		else
			WuLinChartsFrame_Charts_Reset()
			this:Show()
			WuLinCharts_Init()

		end

	elseif event == "FENGYUNLU_UPDATE_MISSION" then
		if this:IsVisible() then
			WuLinCharts_UpdateRightPart()
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide();
	elseif event == "OPEN_FENGYUNLU_WITH_ID" and arg0~=nil and tonumber(arg0) >= 0 then
		WuLinChartsFrame_Charts_Reset()
		this:Show()
		--修改为使用nindex，这样不管中间怎么插入都不用改调用
		local nIndex = tonumber(arg0)
		for i=0,g_WuLinCharts_MaxIndex do
			if(nIndex == g_lineNumToIndex[i]) then
				g_CurrentSelect = i + 1
			end
		end
		WuLinCharts_Init()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2018012303 then
		--豪侠路打开界面
		g_IsOpenByHXL = tonumber(arg1)
		--PushDebugMessage("g_IsOpenByHXL="..g_IsOpenByHXL)
		if g_IsOpenByHXL > 0 then
			WuLinChartsFrame_Charts_SetButtonSelected(g_IsOpenByHXL)
			WuLinChartsFrame_Charts:Flash()
			g_CurrentSelect = g_IsOpenByHXL
			local kajiType = KaJi:LuaFnGetKaJiType(16)
			local nSpecKaJi89 = Player : GetData("SPECKAJI89")  
			if nil~=kajiType and nil~=g_KajiTable_FYL[kajiType]  then		
				if kajiType == 0 and nSpecKaJi89 == 0 then
					g_WuLinCharts_MaxIndex = g_KajiTable_FYL[kajiType] 
				elseif kajiType == 0 and nSpecKaJi89 >= 1 then 
					g_WuLinCharts_MaxIndex = 27
				else
					g_WuLinCharts_MaxIndex = g_KajiTable_FYL[kajiType] 
				end 
			end
			WuLinCharts_UpdateRightPart()
			WuLinChartsFrame_Charts:SetVertScrollbarPosition(69*(g_IsOpenByHXL-1))
		end
		g_IsOpenByHXL = 0
	end
end


function WuLinCharts_Init()
	local nSpecKaJi89 = Player : GetData("SPECKAJI89")  
	WuLinChartsFrame_Charts:CleanAllElement("WuLinCharts")
	local achivementidx = 0 
	for i = 0 , g_WuLinCharts_MaxIndex do
			if ( Player : GetData("IsOriginalJD") == 0 and i ~= 2 and Player : GetData("Is2606S") == 0) or 
				(g_DZD_forbid[i] == 1 and Player : GetData("IsOriginalJD") == 1) or 
				(g_2606S_forbid[i] == 1 and Player : GetData("Is2606S") == 1) then   
				achivementidx = achivementidx + 1
				g_DZD_forbid_xmltoindex[achivementidx] = i + 1
				WuLinCharts_AddOneItem(i) 
			end
	end
	if g_CurrentSelect < 1 or g_CurrentSelect > g_WuLinCharts_MaxIndex+1 then
		g_CurrentSelect = 1
	end
	WuLinChartsFrame_Charts_SetButtonSelected(g_CurrentSelect)

	WuLinChartsFrame_Charts:Flash()

	WuLinChartsFrame_Charts:SetElementsInView(g_CurrentSelect)

	WuLinCharts_UpdateRightPart()

end




function WuLinCharts_UpdateRightPart() 
	local sInfoTitle , sInfo = Lua_GetFengyunluInfo(g_CurrentSelect - 1)
	WuLinChartsFrame_Name:SetText(sInfoTitle)
	if sInfo == "#{ZMYD_230801_02}" then
		local nMenpai = Player:GetData("MEMPAI")
		WuLinChartsFrame_Intro:SetText(g_ZMYD_Intro[nMenpai])
	else
		WuLinChartsFrame_Intro:SetText(sInfo)
	end
	local sMissionListTitle = Lua_GetFengyunluMissionListTitle(g_CurrentSelect - 1)
	WuLinChartsFrame_Name2:SetText(sMissionListTitle)

	local strTxt = ""
	local allDone = 1
	for i = 0 , g_MaxMissionNeed -1 do
		local misID = Lua_GetFengyunluMissionIDNeed(g_CurrentSelect - 1 ,i);
		if misID >= 0 then
			local strTemp = ""
			local iHave = DataPool:Lua_IsHaveMission(misID)
			if iHave > 0 then
				allDone = 0
				strTemp = Lua_GetFengyunluMissionTextHave(g_CurrentSelect - 1 ,i)
			else
				local iDone = DataPool:Lua_IsMissionHaveDone(misID)
				if iDone > 0 then
					strTemp = Lua_GetFengyunluMissionTextDone(g_CurrentSelect - 1 ,i)
				else
					allDone = 0
					strTemp = Lua_GetFengyunluMissionTextNoHave(g_CurrentSelect - 1 ,i)
				end
			end
			if strTemp ~= "" then
				strTxt = strTxt.."#r"..strTemp
			end
		end
	end 
	if allDone == 1 then
		strTxt = Lua_GetFengyunluOverText(g_CurrentSelect - 1)
		if g_CurrentSelect - 1 == 14 and Player:GetData("Is2606S") == 1 then  --表里修炼id14
			strTxt = "#{QXF_260623_146}"
		end
	end

	WuLinChartsFrame_Intro2:ClearAllElement()
	WuLinChartsFrame_Intro2:AddTextElement(strTxt)

	for i = 1 , 5 do
		g_ActionMask[i]:Hide();
	end

	local index = g_CurrentSelect - 1
	local ret = 0
	if index >= 0 and index <= g_WuLinCharts_MaxIndex then
		ret  = DataPool:Lua_IsHaveGot_FYL_BonusItem(g_lineNumToIndex[index])
	end

	DataPool:Lua_UpdateFYLBonusItem(g_CurrentSelect - 1);
	local iHaveBonus = 0
	for i = 0 , 4 do
		g_ActionButton[i]:SetActionItem(-1);
		local theAction = EnumAction(i, "fyl_item");
		if theAction:GetID() ~= 0 then
			g_ActionButton[i]:SetActionItem(theAction:GetID());
			if ret == 1 then
				g_ActionMask[i+1]:Show();
			end
			iHaveBonus = 1

		end
	end

	if allDone == 1 then
		if ret == 1 then
			WuLinChartsFrame_Get:Disable()
		else
			WuLinChartsFrame_Get:Enable()
		end
	else
		WuLinChartsFrame_Get:Disable()
	end


	for nButtonIndex = 1,table.getn(g_nContentButton) do
		if nil ~= g_nContentButton[nButtonIndex] then
			local nIndex = nButtonIndex - 1
			local bGot = 0
			if nIndex >= 0 and nIndex <= g_WuLinCharts_MaxIndex then
				bGot  = DataPool:Lua_IsHaveGot_FYL_BonusItem(g_lineNumToIndex[g_DZD_forbid_xmltoindex[nButtonIndex]-1])
			end

			if bGot == 1 then
				g_nContentButton[nButtonIndex]:SetAchvGetedShow()
				g_nContentButton[nButtonIndex]:SetAchvGetHide()
			else
				g_nContentButton[nButtonIndex]:SetAchvGetedHide()
				local allDone = 1
				for i = 0 , g_MaxMissionNeed -1 do
					local misID = Lua_GetFengyunluMissionIDNeed(g_DZD_forbid_xmltoindex[nButtonIndex]-1 ,i);
					if misID >= 0 then
						local iHave = DataPool:Lua_IsHaveMission(misID)
						if iHave > 0 then
							allDone = 0
						else
							local iDone = DataPool:Lua_IsMissionHaveDone(misID)
							if iDone > 0 then
							else
								allDone = 0
							end
						end
					end
				end
				if allDone == 1 then
					g_nContentButton[nButtonIndex]:SetAchvGetShow()
				end
			end
		end
	end


end

function WuLinCharts_AddOneItem(nLineNum)
	local ItemBar = WuLinChartsFrame_Charts:AddItemElement( "FYL_Button", "LEFT", "WuLinCharts","" ,"")
	ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")

	local sTitle , sSubTitle = Lua_GetFengyunluTitle(nLineNum)
	local strIcon = Lua_GetFengyunluIcon(nLineNum)
	if strIcon ~= nil and strIcon ~= "" then
		local sPos,_ = string.find(strIcon," ");
		local IconImageSet = string.sub(strIcon,5,sPos-1);
		local IconIamge = string.sub(strIcon,sPos+7)
		if nil ~= IconImageSet and nil ~= IconIamge then
			ItemBar:AddBarIconImage(IconImageSet,IconIamge)
		end
	end

	ItemBar:AddBarText(sTitle)
	ItemBar:SetBarContentText(sSubTitle)
	ItemBar:SetProgressHide()

	local ret = 0
	if nLineNum >= 0 and nLineNum <= g_WuLinCharts_MaxIndex then
		ret  = DataPool:Lua_IsHaveGot_FYL_BonusItem(g_lineNumToIndex[nLineNum])
		--Lua_TDU_Log("nLineNum:"..nLineNum)
	end

	if ret == 1 then
		ItemBar:SetAchvGetedShow()
	else
		ItemBar:SetAchvGetedHide()
	end
		ItemBar:SetAchvGetHide()


	table.insert(g_nContentButton,ItemBar);
end

function WuLinChartsFrame_Charts_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1
	--PushDebugMessage("WuLinChartsFrame_Charts_OnItemClick nIndex:"..nIndex)
	if nIndex > 0 then
		WuLinChartsFrame_Charts_SetButtonSelected(nIndex)
		WuLinChartsFrame_Charts:Flash()
		g_CurrentSelect = g_DZD_forbid_xmltoindex[nIndex]
		--PushDebugMessage("g_CurrentSelect:"..g_CurrentSelect)
		WuLinCharts_UpdateRightPart()
	end

end;


function WuLinChartsFrame_Charts_SetButtonSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_nContentButton) do
		if nil ~= g_nContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
--	AchievementFrame_SetButtonSelectedDesc(nIndex)
end

function WuLinChartsFrame_Charts_Reset()
	local kajiType = KaJi:LuaFnGetKaJiType(16)
	local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
	if nil~=kajiType and nil~=g_KajiTable_FYL[kajiType]  then		
		if kajiType == 0 and nSpecKaJi89 == 0 then
			g_WuLinCharts_MaxIndex = g_KajiTable_FYL[kajiType] 
		elseif kajiType == 0 and nSpecKaJi89 >= 1 then 
			g_WuLinCharts_MaxIndex = 27
		elseif kajiType == 1 then
			g_WuLinCharts_MaxIndex = g_KajiTable_FYL[kajiType] 
		end 
	end
 
--	g_CurrentSelect = 1
	g_nContentButton = {}
	WuLinChartsFrame_Intro:SetText("")
	WuLinChartsFrame_Name:SetText("")
	WuLinChartsFrame_Intro2:ClearAllElement()
	WuLinChartsFrame_Name2:SetText("")

	for i = 0 , 4 do
		g_ActionButton[i]:SetActionItem(-1);
	end

	for i = 1 , 5 do
		g_ActionMask[i]:Hide();
	end
end

function WuLinChartsFrame_Charts_CloseClick()
	WuLinChartsFrame_Charts_Reset()
	this:Hide()
end

function WuLinChartsFrame_Charts_GetClick()

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetBonus")  --脚本接口
			Set_XSCRIPT_ScriptID(290099) --脚本编号 g_CurrentSelect
			Set_XSCRIPT_Parameter(0,tonumber(g_CurrentSelect - 1))
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
end


--local theAction = EnumAction(0, "fyl_item");
