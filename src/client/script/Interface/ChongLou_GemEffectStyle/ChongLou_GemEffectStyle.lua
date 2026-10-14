--!!!reloadscript =ChongLou_GemEffectStyle

local g_ChongLou_GemEffectStyle_UnifiedPosition = ""
local g_MaxBarNum = 10

local g_BarList = {}
local g_ListInit = 0

local g_ObjServerId = -1
local g_EquipTypeNum = 15
local g_EquipButton = {}
local g_NeedChangeScrollSize = 0
local g_CurEquipType = 0
local g_CurEffect = 0
local g_CurShowEffect = 0

function ChongLou_GemEffectStyle_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)

	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	--更新装备
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	
	this:RegisterEvent("CHONGLOU_EFFECT_UPDATE", false)
	
end

function ChongLou_GemEffectStyle_OnLoad()
	
	g_ChongLou_GemEffectStyle_UnifiedPosition = ChongLou_GemEffectStyle_Frame:GetProperty("UnifiedPosition")	
--	Rune_Stars_Reelup_DemandMoney2:SetProperty("MoneyColor", "ff6a3906")
	
	g_EquipButton[1] = ChongLou_GemEffectStyle_Btn1
	g_EquipButton[2] = ChongLou_GemEffectStyle_Btn2
	g_EquipButton[3] = ChongLou_GemEffectStyle_Btn3
	g_EquipButton[4] = ChongLou_GemEffectStyle_Btn4
	g_EquipButton[5] = ChongLou_GemEffectStyle_Btn5
	g_EquipButton[6] = ChongLou_GemEffectStyle_Btn6
	g_EquipButton[7] = ChongLou_GemEffectStyle_Btn7
	g_EquipButton[8] = ChongLou_GemEffectStyle_Btn8
	g_EquipButton[9] = ChongLou_GemEffectStyle_Btn9
	g_EquipButton[10] = ChongLou_GemEffectStyle_Btn10
	g_EquipButton[11] = ChongLou_GemEffectStyle_Btn11
	g_EquipButton[12] = ChongLou_GemEffectStyle_Btn12
	g_EquipButton[13] = ChongLou_GemEffectStyle_Btn13
	g_EquipButton[14] = ChongLou_GemEffectStyle_Btn14
	g_EquipButton[15] = ChongLou_GemEffectStyle_Btn15
	
end

function ChongLou_GemEffectStyle_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ChongLou_GemEffectStyle_On_ResetPos()
	end
	
	if event == "MONEY_CHANGE_EX" and this:IsVisible()  then
		--Rune_Stars_Reelup_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	--	Rune_Stars_Reelup_SelfMoney2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		--if g_CurrentUIType == 1 then
		--	ChongLou_GemEffectStyle_Update()
		--end
		return
	end
	
	if event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		--Rune_Stars_Reelup_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		--Rune_Stars_Reelup_SelfJiaozi2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		--if g_CurrentUIType == 1 then
		--	ChongLou_GemEffectStyle_Update()		
		--end
		return
	end

	if event == "UI_COMMAND" and tonumber(arg0) == 88110101 then
		if not this:IsVisible() then
		--	Armor_Purify_CleanUp()
			g_NeedChangeScrollSize = 1
			g_CurEquipType = 1
			this:Show()
			ChongLou_GemEffectStyle_OnShow()
			ChongLou_GemEffectStyle_Update()
			ChongLou_GemEffectStyle_BeginCareObj(Get_XParam_INT(0))
		end
		return
	end
	
	if event == "CHONGLOU_EFFECT_UPDATE" and this:IsVisible() then
		ChongLou_GemEffectStyle_Update()
	end
end

function ChongLou_GemEffectStyle_BeginCareObj(obj_id)	
	g_ObjServerId = obj_id
	local npc_id = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(npc_id, 1)
end

function ChongLou_GemEffectStyle_InitListBar()
	if g_ListInit ~= 1 then
		for i = 1, g_MaxBarNum do
			local bar = ChongLou_GemEffectStyle_StyleList:AddChild("ChongLou_GemEffectStyleSuperListItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			bar:GetSubItem("ChongLou_GemEffectStyleSkill1_BKG"):SetEvent("MouseLButtonDown", string.format("ChongLou_GemEffectStyle_ItemClicked(%d)", i))
			g_BarList[i] = bar
		end
		g_ListInit = 1
	end
end

function ChongLou_GemEffectStyle_OnShow()
	ChongLou_GemEffectStyle_Fitting_FakeObject:AttachWindowEx("ChongLou_Player")
	SetFakeObjDataEx("ChongLou_Player")
end

--刷新
function ChongLou_GemEffectStyle_Update()
	ChongLou_GemEffectStyle_InitListBar()
	ChongLou_GemEffectStyle_UpdateEquipButton()
	ChougLou_GemEffectStyle_Update_List()
	ChongLou_GemEffectStyle_Update_Obj()
end

function ChougLou_GemEffectStyle_Update_List()
	
	g_NeedChangeScrollSize = 1
	DataPool:LuaFnInitChongLouEffectList(g_CurEquipType - 1)
	local nCount = DataPool:LuaFnGetChongLouEffectListCount()
	
	for i = 1, g_MaxBarNum do
		ChongLou_GemEffectStyle_SetItem(i, nCount)
	end
	
	if g_NeedChangeScrollSize == 1 then		
		ChongLou_GemEffectStyle_StyleList:RefreshLayout()
		ChongLou_GemEffectStyle_StyleList:SetScrollPosition(0)
		g_NeedChangeScrollSize = 0
	end
end

function ChongLou_GemEffectStyle_SetItem(idx, max_count)

	local effect_id = DataPool:LuaFnGetChongLouEffectIDFromList(idx - 1)
	local bar = g_BarList[idx]
	
	if g_BarList[idx] == nil then
		return
	end	
	
	if idx > max_count then
		g_BarList[idx]:Hide()
		return
	end
	
	local bar = g_BarList[idx]
	bar:Show()	
	
	local bActived = DataPool:LuaFnIsChongLouEffectActived(effect_id)
	local strIcon = DataPool:LuaFnGetChongLouEffectIcon(effect_id)
	local strImage = GetIconFullName(tostring(strIcon))
	local strName = DataPool:LuaFnGetChongLouEffectName(effect_id)
	GetIconFullName(strIcon)
--	bar:GetSubItem("ChongLou_GemEffectStyle_SkillCoinAItemOptionName"):SetText(tostring("#L"..strName))
	
	bar:GetSubItem("ChongLou_GemEffectStyleSkill1_BKG_Mask"):Hide()
	bar:GetSubItem("ChongLou_GemEffectStyleSuperListItemActionLock1"):Hide()
	bar:GetSubItem("ChongLou_GemEffectStyleSuperListItemActionDef1"):Hide()
	bar:GetSubItem("ChongLou_GemEffectStyleSuperListItemActionTry1"):Hide()
	bar:GetSubItem("ChongLou_GemEffectStyleSuperListItemActionAct1"):Hide()
	
	if g_CurEffect == 0 then
		g_CurEffect = effect_id
	end
	
	local ctrlAction = bar:GetSubItem("ChongLou_GemEffectStyleSkill1_BKG")
	if ctrlAction ~= nil then
		
		ctrlAction:SetProperty("NormalImage", tostring(strImage))
		ctrlAction:SetProperty("HoverImage", tostring(strImage))
		ctrlAction:SetToolTip(tostring(strName))
		
		if effect_id == g_CurEffect then
			ctrlAction:SetPushed(1)
		else
			ctrlAction:SetPushed(0)
		end
	end
	
	if bActived ~= 1 then
		bar:GetSubItem("ChongLou_GemEffectStyleSkill1_BKG_Mask"):Show()
	end
	
	if effect_id == DataPool:LuaFnGetChongLouEffectInUse(g_CurEquipType - 1) then
		bar:GetSubItem("ChongLou_GemEffectStyleSuperListItemActionDef1"):Show()
	elseif effect_id == g_CurEffect then
		bar:GetSubItem("ChongLou_GemEffectStyleSuperListItemActionTry1"):Show()
	end
end

function ChongLou_GemEffectStyle_ItemClicked(nIndex)

	local effect_id = DataPool:LuaFnGetChongLouEffectIDFromList(nIndex - 1)
	if g_CurEffect == effect_id then
		return
	end
	
	g_CurEffect = effect_id
	
	for i = 1, g_MaxBarNum do
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("ChongLou_GemEffectStyleSkill1_BKG")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_BarList[i]:GetSubItem("ChongLou_GemEffectStyleSuperListItemActionTry1"):Show()
					if DataPool:LuaFnGetChongLouEffectInUse(g_CurEquipType - 1) == g_CurEffect then
						g_BarList[i]:GetSubItem("ChongLou_GemEffectStyleSuperListItemActionTry1"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_BarList[i]:GetSubItem("ChongLou_GemEffectStyleSuperListItemActionTry1"):Hide()
				end
			end			
		end
	end
	ChongLou_GemEffectStyle_Update_Obj()
end

function ChongLou_GemEffectStyle_Update_Obj()
	if g_CurShowEffect ~= 0 then
		DataPool:LuaFnAvatarRemoveChongLouEffect(g_CurShowEffect)
		g_CurShowEffect = 0
	end
	
	if g_CurEquipType >= 1 and g_CurEquipType <= g_EquipTypeNum then
		if g_CurEffect ~= 0 then			
			DataPool:LuaFnAvatarShowChongLouEffect(g_CurEffect)
			g_CurShowEffect = g_CurEffect
		end
	end
end
	
function ChongLou_GemEffectStyle_On_ResetPos()
	if g_ChongLou_GemEffectStyle_UnifiedPosition ~= nil then
		ChongLou_GemEffectStyle_Frame:SetProperty("UnifiedPosition", g_ChongLou_GemEffectStyle_UnifiedPosition)
	end
end

function ChongLou_GemEffectStyle_SelectEquip(idx)
	if g_CurEquipType ~= idx then
		g_CurEquipType = idx
		g_NeedChangeScrollSize = 1
		g_CurEffect = 0
		ChongLou_GemEffectStyle_UpdateEquipButton()
		ChougLou_GemEffectStyle_Update_List()
		ChongLou_GemEffectStyle_Update_Obj()
	end	
end

function ChongLou_GemEffectStyle_UpdateEquipButton()
	for i = 1, g_EquipTypeNum do
		if i == g_CurEquipType then
			g_EquipButton[i]:SetCheck(1)
		else
			g_EquipButton[i]:SetCheck(0)
		end
	end
end

function ChongLou_GemEffectStyle_Close()
	this:Hide()
end

function ChongLou_GemEffectStyle_OnHidden()
	ChongLou_GemEffectStyle_CleanUp()
	g_ObjServerId = -1
end

function ChongLou_GemEffectStyle_CleanUp()
	if g_CurShowEffect ~= 0 then
		DataPool:LuaFnAvatarRemoveChongLouEffect(g_CurShowEffect)
	end
	g_CurShowEffect = 0
	g_CurEffect = 0
	g_CurEquipType = 0
	ChongLou_GemEffectStyle_Fitting_FakeObject:DetachWindowEx()
end

function ChongLou_GemEffectStyle_Change()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(881101)
		Set_XSCRIPT_Function_Name("CL_EffectChange")
		Set_XSCRIPT_Parameter(0, g_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_CurEquipType - 1)
		Set_XSCRIPT_Parameter(2, g_CurEffect)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function ChongLou_GemEffectStyle_Active()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(881101)
		Set_XSCRIPT_Function_Name("CL_EffectActive")
		Set_XSCRIPT_Parameter(0, g_ObjServerId)
		Set_XSCRIPT_Parameter(1, g_CurEquipType - 1)
		Set_XSCRIPT_Parameter(2, g_CurEffect)
		Set_XSCRIPT_Parameter(3, 1)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function ChongLou_GemEffectStyle_FakeObject_TurnLeft(idx)
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		ChongLou_GemEffectStyle_Fitting_FakeObject:RotateBeginEx("ChongLou_Player", -0.3)
	else
		ChongLou_GemEffectStyle_Fitting_FakeObject:RotateEndEx()
	end
end

function ChongLou_GemEffectStyle_FakeObject_TurnRight(idx)
	if idx == 1 and CEArg:GetValue("MouseButton") == "LeftButton" then
		ChongLou_GemEffectStyle_Fitting_FakeObject:RotateBeginEx("ChongLou_Player", 0.3)
	else
		ChongLou_GemEffectStyle_Fitting_FakeObject:RotateEndEx()
	end
end
--!!!reloadscript =Rune_Stars
