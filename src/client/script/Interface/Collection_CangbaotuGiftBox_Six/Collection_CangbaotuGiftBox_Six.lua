--2026Q1藏品藏宝图玩法设计
--多选一
--!!!reloadscript =Collection_CangbaotuGiftBox_Six

local g_Frame_UnifiedPosition = ""

local g_MaxCount = 6
local g_targetId = -1
local g_CurIndex = -1

local g_SelectItemId={}
local g_SelectItemNum={}
local g_SelectItemBind={}
local g_SelectMemberName={}

local g_ActionItem = {}
local g_ActionMask = {}
local g_ActionImage = {}
local g_ItemNameText = {}

function Collection_CangbaotuGiftBox_Six_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Collection_CangbaotuGiftBox_Six_OnLoad()

	g_Frame_UnifiedPosition = Collection_CangbaotuGiftBox_Six_Frame_BK:GetProperty("UnifiedPosition")
	
	g_ActionItem[1] = Collection_CangbaotuGiftBox_Six_Item1
	g_ActionItem[2] = Collection_CangbaotuGiftBox_Six_Item2
	g_ActionItem[3] = Collection_CangbaotuGiftBox_Six_Item3
	g_ActionItem[4] = Collection_CangbaotuGiftBox_Six_Item4
	g_ActionItem[5] = Collection_CangbaotuGiftBox_Six_Item5
	g_ActionItem[6] = Collection_CangbaotuGiftBox_Six_Item6
	
	g_ActionMask[1] = Collection_CangbaotuGiftBox_Six_Item1_Mask
	g_ActionMask[2] = Collection_CangbaotuGiftBox_Six_Item2_Mask
	g_ActionMask[3] = Collection_CangbaotuGiftBox_Six_Item3_Mask
	g_ActionMask[4] = Collection_CangbaotuGiftBox_Six_Item4_Mask
	g_ActionMask[5] = Collection_CangbaotuGiftBox_Six_Item5_Mask
	g_ActionMask[6] = Collection_CangbaotuGiftBox_Six_Item6_Mask
	
	g_ActionImage[1] = Collection_CangbaotuGiftBox_Six_Item1_Cornermark
	g_ActionImage[2] = Collection_CangbaotuGiftBox_Six_Item2_Cornermark
	g_ActionImage[3] = Collection_CangbaotuGiftBox_Six_Item3_Cornermark
	g_ActionImage[4] = Collection_CangbaotuGiftBox_Six_Item4_Cornermark
	g_ActionImage[5] = Collection_CangbaotuGiftBox_Six_Item5_Cornermark
	g_ActionImage[6] = Collection_CangbaotuGiftBox_Six_Item6_Cornermark
	
	g_ItemNameText[1] = Collection_CangbaotuGiftBox_Six_Item1_Name
	g_ItemNameText[2] = Collection_CangbaotuGiftBox_Six_Item2_Name
	g_ItemNameText[3] = Collection_CangbaotuGiftBox_Six_Item3_Name
	g_ItemNameText[4] = Collection_CangbaotuGiftBox_Six_Item4_Name
	g_ItemNameText[5] = Collection_CangbaotuGiftBox_Six_Item5_Name
	g_ItemNameText[6] = Collection_CangbaotuGiftBox_Six_Item6_Name
	
end										

function Collection_CangbaotuGiftBox_Six_Frame_On_ResetPos()
	if g_Frame_UnifiedPosition ~= nil then
		Collection_CangbaotuGiftBox_Six_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	end
end

function Collection_CangbaotuGiftBox_Six_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 51011101 then
		local flag = Get_XParam_INT(0)
		if flag == 3 then--仅刷新
			if (this:IsVisible()) then  --界面打开状态
				for i=1, g_MaxCount do
					g_SelectItemId[i] = tonumber(Get_XParam_STR(2*i-2))
					g_SelectItemNum[i] = tonumber(Get_XParam_INT(2*i))
					g_SelectItemBind[i] = tonumber(Get_XParam_INT(2*i+1))
					g_SelectMemberName[i] = tostring(Get_XParam_STR(2*i-1))
				end
				Collection_CangbaotuGiftBox_Six_Update()
				if g_CurIndex > 0 then
					g_ActionItem[g_CurIndex]:SetPushed(1)
					g_ActionMask[g_CurIndex]:Show()
				end
			end
			return
		end
		Collection_CangbaotuGiftBox_Six_CleanUp()
		if flag == 1 then
			g_targetId = Get_XParam_INT(1)
			for i=1, g_MaxCount do
				g_SelectItemId[i] = tonumber(Get_XParam_STR(2*i-2))
				g_SelectItemNum[i] = tonumber(Get_XParam_INT(2*i))
				g_SelectItemBind[i] = tonumber(Get_XParam_INT(2*i+1))
				g_SelectMemberName[i] = tostring(Get_XParam_STR(2*i-1))
			end
			this:Show()		
			Collection_CangbaotuGiftBox_Six_Update()
			return
		end
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Collection_CangbaotuGiftBox_Six_Frame_On_ResetPos()
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
end

function Collection_CangbaotuGiftBox_Six_Update()

	for i = 1, g_MaxCount do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end

	for i = 1, g_MaxCount do
		if g_SelectItemId[i] > 0 and g_SelectItemNum[i] > 0 then
			local itemAction 
			if g_SelectItemBind[i] == 0 then
				itemAction = DataPool:CreateActionItemForShow(g_SelectItemId[i], g_SelectItemNum[i])
			else
				itemAction = DataPool:CreateBindActionItemForShow(g_SelectItemId[i], g_SelectItemNum[i])
			end
			if itemAction:GetID() ~= 0 then
				g_ActionItem[i]:SetActionItem(itemAction:GetID())
			end			
			g_ActionImage[i]:Hide()
		else
			g_ActionImage[i]:Show()
		end
		if i == 1 then
			if g_SelectMemberName[i] ~= "" then
				g_ItemNameText[i]:SetText(ScriptGlobal_Format("#{CPBT_260115_82}", g_SelectMemberName[i]))
			else
				g_ItemNameText[i]:SetText("#{CPBT_260115_84}")
			end
		else
			if g_SelectMemberName[i] ~= "" then
				g_ItemNameText[i]:SetText(ScriptGlobal_Format("#{CPBT_260115_83}", g_SelectMemberName[i]))
			else
				g_ItemNameText[i]:SetText("#{CPBT_260115_84}")
			end
		end
		
	end
	
end

function Collection_CangbaotuGiftBox_Six_OnItemClicked(index)

	if index == nil or index <= 0 then
		return
	end
	
	if g_SelectItemId[index] == nil or g_SelectItemId[index] <= 0 then
		return
	end
	
	if g_SelectItemNum[index] == nil or g_SelectItemNum[index] <= 0 then
		return
	end

	if g_CurIndex == index then
		g_CurIndex = -1
	else
		g_CurIndex = index
	end		
	
	for i = 1, g_MaxCount do	
		g_ActionItem[i]:SetPushed(0)
		g_ActionMask[i]:Hide()
	end
	
	if g_CurIndex > 0 then
		g_ActionItem[g_CurIndex]:SetPushed(1)
		g_ActionMask[g_CurIndex]:Show()
	end
	
end

function Collection_CangbaotuGiftBox_Six_CleanUp()	

	for i = 1, g_MaxCount do	
		g_ActionItem[i]:SetActionItem(-1)
		g_ItemNameText[i]:SetText("")
		g_ActionMask[i]:Hide()
		g_ActionImage[i]:Show()
	end
	
	g_targetId = -1
	g_CurIndex = -1

	this:Hide()--待 是否多遍进入
	
end

function Collection_CangbaotuGiftBox_Six_OnHidden()
	Collection_CangbaotuGiftBox_Six_CleanUp()
end

function Collection_CangbaotuGiftBox_Six_CloseClicked()
	this:Hide()
end

function Collection_CangbaotuGiftBox_Six_OnGetClicked()
	if g_CurIndex == nil or g_CurIndex <= 0 then
		PushDebugMessage("#{CPBT_260115_88}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(510111)
		Set_XSCRIPT_Function_Name("OnPrize")
		Set_XSCRIPT_Parameter(0, g_targetId)
		Set_XSCRIPT_Parameter(1, g_CurIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
