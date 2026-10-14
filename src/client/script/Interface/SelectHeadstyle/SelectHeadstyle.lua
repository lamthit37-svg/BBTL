		
local g_SelectHeadstyle_YuanbaoPay=1	
local g_SelectHeadstyle_Frame_UnifiedPosition;
local g_clientNpcId = -1
local g_ExteriorType = 5 --头像
local g_MaxBarNum = 0
local g_BarList = {}
local g_CurSelExteriorID = 0		--当前选择的外观ID，从1开始
local g_CurSelExteriorIndex = 0		--当前选择的外观索引，从1开始

function SelectHeadstyle_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("REFRESH_HEADSTYLE",false);
end


function SelectHeadstyle_OnLoad()
	
	g_SelectHeadstyle_Frame_UnifiedPosition=SelectHeadstyle_Frame:GetProperty("UnifiedPosition");

end

function SelectHeadstyle_Frame_On_ResetPos()
	SelectHeadstyle_Frame:SetProperty("UnifiedPosition", g_SelectHeadstyle_Frame_UnifiedPosition);
end


function SelectHeadstyle_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		if ( tonumber(arg0) == 112730 ) then
			local npcObjId = Get_XParam_INT(0)
			g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
			if g_clientNpcId == -1 then
				PushDebugMessage("未发现 NPC")
				SelectHeadstyle_Close()
				return
			end
			this:CareObject( g_clientNpcId, 1, "SelectHeadstyle" )

			if(IsWindowShow("SelectHairstyle")) then
				CloseWindow("SelectHairstyle", true);
			end

			if(IsWindowShow("SelectHairColor")) then
				CloseWindow("SelectHairColor", true);
			end

			if(IsWindowShow("SelectFacestyle")) then
				CloseWindow("SelectFacestyle", true);
			end

			SelectHeadstyle_OnShown()
			this:Show();
		elseif ( tonumber(arg0) == 201203143 ) then
			SelectHeadstyle_Close()
		end
	elseif (event == "ADJEST_UI_POS" ) then
		SelectHeadstyle_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SelectHeadstyle_Frame_On_ResetPos()
	elseif (event == "REFRESH_HEADSTYLE") then
		SelectHeadstyle_Update()
	end
end


function SelectHeadstyle_OnShown()
	if g_SelectHeadstyle_YuanbaoPay == 1 or g_SelectHeadstyle_YuanbaoPay == 0 then
		SelectHeadstyle_Blank_Queren:SetCheck(g_SelectHeadstyle_YuanbaoPay)
	end
	local cacheExteriorHeadID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
	if cacheExteriorHeadID > 0 then
		g_CurSelExteriorID = cacheExteriorHeadID
	end
	SelectHeadstyle_Update();
end


function SelectHeadstyle_Update()
	Exterior:LuaFnInitExteriorList(g_ExteriorType)
	g_MaxBarNum = Exterior:LuaFnGetExteriorMaxCount(g_ExteriorType)
	SelectHeadGroup_StyleList:Clear()

	for i = 1, g_MaxBarNum do
		local bar = SelectHeadGroup_StyleList:AddChild("SelectHeadGroup_StyleListItem")
		g_BarList[i] = bar	
		bar:GetSubItem("SelectHeadGroup_Skill1_BKG"):SetEvent("MouseLButtonDown", string.format("SelectHeadstyle_ItemClicked(%d)", i))
		bar:GetSubItem("SelectHeadGroup_Skill1_BKG"):SetEvent("MouseMove", string.format("SelectHeadstyle_ItemMouseMove(%d)", i))
		SelectHeadstyle_SetItem(i)
	end
	SelectHeadstyle_ShowDetail()
	
end

function SelectHeadstyle_SetItem(index)
	if g_BarList[index] == nil then
		return
	end
	local bar = g_BarList[index]
	bar:Show()
	local nExteriorID = Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, index - 1)

	local nID,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,_ = Exterior:LuaFnGetExteriorHeadStyleInfo(nExteriorID)
	
	if nID>0 then
		local ctrlAction = bar:GetSubItem("SelectHeadGroup_Skill1_BKG")
		if ctrlAction ~= nil then
			IconFile = GetIconFullName(IconFile)
			ctrlAction:SetProperty("NormalImage", IconFile)
			ctrlAction:SetProperty("HoverImage", IconFile)
			ctrlAction:SetToolTip(StyleName)
			
			if g_CurSelExteriorID == nExteriorID then
				ctrlAction:SetPushed(1)
			else
				ctrlAction:SetPushed(0)
			end
		end

		bar:GetSubItem("SelectHeadGroup_SuperListItemActionTry"):Hide()
		bar:GetSubItem("SelectHeadGroup_SuperListItemActionDef"):Hide()
		local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		if nExteriorID == cacheExteriorID then
			--当前正在装备的
			bar:GetSubItem("SelectHeadGroup_SuperListItemActionDef"):Show()
		end


		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then		
			bar:GetSubItem("SelectHeadGroup_SuperListItemActionLock1"):Hide()
		else
			bar:GetSubItem("SelectHeadGroup_SuperListItemActionLock1"):Show()
		end	
	end

end

function SelectHeadstyle_ItemClicked(nIndex)

	local oldbar = g_BarList[g_CurSelExteriorIndex]
	if oldbar~=nil then
		oldbar:GetSubItem("SelectHeadGroup_SuperListItemActionTry"):Hide()
	end

	g_CurSelExteriorIndex = nIndex
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, nIndex - 1)

	local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
	if nExteriorID ~= cacheExteriorID then
		--当前不是正在装备的
		local newbar = g_BarList[g_CurSelExteriorIndex]
		newbar:GetSubItem("SelectHeadGroup_SuperListItemActionTry"):Show()
	end

	g_CurSelExteriorID = nExteriorID
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("SelectHeadGroup_Skill1_BKG")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
	SelectHeadstyle_ShowDetail()
end

function SelectHeadstyle_ShowDetail()
	local nID,ItemID,ItemCount,SelectType,IconFile,CostMoney,StyleName,TitleInfo = Exterior:LuaFnGetExteriorHeadStyleInfo(g_CurSelExteriorID);
	if nID <= 0 then
		return
	end
	IconFile = GetIconFullName(IconFile)
	SelectHeadstyle_Skill1_BKG:SetProperty("NormalImage",IconFile)
	SelectHeadstyle_Skill1_BKG:SetProperty("HoverImage",IconFile)
	SelectHeadstyle_Skill1_BKG:SetToolTip(StyleName)

	if Exterior:LuaFnIsHaveExterior(g_ExteriorType, g_CurSelExteriorID) == 1 then
		SelectHeadstyle_WarningText : SetText("#{YRGTX_160809_3}")
		SelectHeadstyle_Accept:SetText("#{GXHDZ_141121_04}")
		local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
		if g_CurSelExteriorID == cacheExteriorID then
			--当前正在装备的
			SelectHeadstyle_WarningText : SetText("#r".."#{WGTJ_210112_17}")
		end
	else
		SelectHeadstyle_Accept:SetText("#{GXHDZ_141121_10}")
		local name,icon = LifeAbility : GetPrescr_Material(ItemID);
		SelectHeadstyle_WarningText : SetText("#{INTERHEAD_XML_013}"..TitleInfo.."#{INTERHEAD_XML_014}"..name.."#{INTERHEAD_XML_015}#{_EXCHG"..CostMoney.."}#{INTERHEAD_XML_016}")
	end
end

--关闭
function SelectHeadstyle_Close()
	this:Hide()
end
--==================================
--关闭
--==================================
function SelectHeadstyle_Cancel_Clicked()
	this:CareObject( g_clientNpcId, 0, "SelectHeadstyle" )
	g_clientNpcId = -1
	g_CurSelExteriorID = 0
	g_CurSelExteriorIndex = 0
	PushEvent("CONVENIENT_BUY_CONFIRM_CLOSE");
end

--==================================
--确认
--==================================
function SelectHeadstyle_OK_Clicked()

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("UnlockAndChangeExteriorHeadId");
		Set_XSCRIPT_ScriptID(805030);
		Set_XSCRIPT_Parameter(0,g_CurSelExteriorID);
		Set_XSCRIPT_Parameter(1,g_SelectHeadstyle_YuanbaoPay);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();

end



function SelectHeadstyle_ItemMouseMove(nIndex)

end


function SelectHeadstyle_Blank_Queren_Clicked() 
	g_SelectHeadstyle_YuanbaoPay = SelectHeadstyle_Blank_Queren:GetCheck();
end





