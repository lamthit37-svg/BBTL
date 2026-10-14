--!!!reloadscript =PetNeidan_Tujian

local g_PetNeidan_Tujian_Frame_UnifiedPosition = ""

local g_InitList = 0

local g_MaxNeiDanBarNum = 0
local g_NeiDanBarList = {}

local g_NeedChangeNeiDanScrollSize = 0

local g_CurrentSelect = 0
local g_CurrentFilter = 0

local g_StrLevel = {
	"#{ZSND_230428_135}",
	"#{ZSND_230428_106}",
	"#{ZSND_230428_107}",
	"#{ZSND_230428_108}",
	"#{ZSND_230428_109}",
	"#{ZSND_230428_110}",
}

function PetNeidan_Tujian_PreLoad()
	--this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_PET_NEIDAN_TUJIAN")
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("PLAYER_ENTERING_WORLD", false)
end

function PetNeidan_Tujian_OnLoad()
	g_PetNeidan_Tujian_Frame_UnifiedPosition = PetNeidan_Tujian_Frame:GetProperty("UnifiedPosition")
end

function PetNeidan_Tujian_OnEvent(event)
	if event == "OPEN_PET_NEIDAN_TUJIAN" then
		if this:IsVisible() then
			this:Activate()
			return
		else
			g_CurrentSelect = 1
		end
		this:Show()
		g_CurrentFilter = 2
		g_NeedChangeNeiDanScrollSize = 1
		PetNeidan_Tujian_Update()
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		PetNeidan_Tujian_On_ResetPos()
		return
	end
end

function PetNeidan_Tujian_On_ResetPos()
	PetNeidan_Tujian_Frame:SetProperty("UnifiedPosition", g_PetNeidan_Tujian_Frame_UnifiedPosition)
end

function PetNeidan_Tujian_InitListBar()

	if g_InitList == 0 then		
		g_MaxNeiDanBarNum = DataPool:LuaFnGetPetNeiDanTuJianMaxCount()
		for i = 1, g_MaxNeiDanBarNum do
			local bar = PetNeidan_Tujian_List_Lace:AddChild("PetNeidan_Tujian_List_LaceItem1")
			bar:SetProperty("SuperBarButtonHover", "SuperBarHoverSection")
			g_NeiDanBarList[i] = bar	
			bar:GetSubItem("PetNeidan_Tujian_List_LaceItem1_Icon"):SetEvent("MouseLButtonDown", string.format("PetNeidan_Tujian_NeiDanClicked(%d)", i))
		end
		g_InitList = 1
	end
end

function PetNeidan_Tujian_CleanUp()

end

function PetNeidan_Tujian_UpdateNeiDanList()
	
	for i = 1, g_MaxNeiDanBarNum do
		if g_NeiDanBarList[i] then
			local ctrlAction = g_NeiDanBarList[i]:GetSubItem("PetNeidan_Tujian_List_LaceItem1_Icon")
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
				ctrlAction:SetActionItem(-1)
				ctrlAction:SetProperty("DraggingEnabled", "False")
			end
		end	
	end
		
	DataPool:LuaFnInitPetNeiDanTuJianList(g_CurrentFilter)
	local nCount = DataPool:LuaFnGetPetNeiDanTuJianListCount()
	
	for	i = 1, g_MaxNeiDanBarNum do
		PetNeidan_Tujian_NeiDanList_SetItem(i, nCount)
	end
	
	if g_NeedChangeNeiDanScrollSize == 1 then
		PetNeidan_Tujian_List_Lace:RefreshLayout()
		PetNeidan_Tujian_List_Lace:SetScrollPosition(0)
		g_NeedChangeNeiDanScrollSize = 0
	end
	
	if g_CurrentSelect ~= 0 then
		PetNeidan_Tujian_SetPetNeiDanSelected(g_CurrentSelect)
	end
end

function PetNeidan_Tujian_NeiDanList_SetItem(idx, max_count)
	if g_NeiDanBarList[idx] == nil then
		return
	end
	
	if idx > max_count then
		g_NeiDanBarList[idx]:Hide()
		return
	end

	local bar = g_NeiDanBarList[idx]
	bar:Show()	
	
	local nd_id = DataPool:LuaFnGetPetNeiDanIDFromTuJianList(idx - 1)
	
	local ctrlAction = bar:GetSubItem("PetNeidan_Tujian_List_LaceItem1_Icon")
	if ctrlAction ~= nil then
		ctrlAction:SetActionItem(-1)
		local theNeiDanAction = EnumAction(nd_id, "pndtujian")
		if theNeiDanAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theNeiDanAction:GetID())
		end
	end
end

function PetNeidan_Tujian_Update()
	PetNeidan_Tujian_InitListBar()
	PetNeidan_Tujian_ListCleanUpAction()
	PetNeidan_Tujian_UpdateCheckButton()
	PetNeidan_Tujian_UpdateNeiDanList()
	if g_CurrentSelect ~= 0 then
		PetNeidan_Tujian_SetPetNeiDanSelected(g_CurrentSelect)
	end
	PetNeidan_Tujian_UpdateInfo()
end

function PetNeidan_Tujian_NeiDanClicked(idx)
	if g_CurrentSelect ~= idx then
		g_CurrentSelect = idx
		PetNeidan_Tujian_SetPetNeiDanSelected(idx)
		PetNeidan_Tujian_UpdateInfo()
	end
end

function PetNeidan_Tujian_SetPetNeiDanSelected(nIndex)
	for i = 1, g_MaxNeiDanBarNum do		
		if g_NeiDanBarList[i] ~= nil then	
			local ctrlAction = g_NeiDanBarList[i]:GetSubItem("PetNeidan_Tujian_List_LaceItem1_Icon")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
end

function PetNeidan_Tujian_UpdateInfo()
	PetNeidan_Tujian_Title:SetText("")
	PetNeidan_Tujian_ExplainList:ClearAllElement()
	
	if g_CurrentSelect ~= 0 then
		local nd_id = DataPool:LuaFnGetPetNeiDanIDFromTuJianList(g_CurrentSelect - 1)
		if tonumber(nd_id) ~= nil and tonumber(nd_id) > 0 then
			local nd_name = DataPool:LuaFnGetPetNeiDanNameById(nd_id)
			PetNeidan_Tujian_Title:SetText(tostring(nd_name))
			for i = 0, 5 do
				local strDesc = DataPool:LuaFnGetPetNeiDanTuJianDesc(nd_id, i)
				PetNeidan_Tujian_ExplainList:AddTextElement(g_StrLevel[i + 1].."\n"..tostring(strDesc).."\n")
			end
		end
	end
end

function PetNeidan_Tujian_ListCleanUpAction()
	for i = 1, g_MaxNeiDanBarNum do
		if g_NeiDanBarList[i] then
			local ctrlAction = g_NeiDanBarList[i]:GetSubItem("PetNeidan_Tujian_List_LaceItem1_Icon")
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
				ctrlAction:SetActionItem(-1)
			end
		end	
	end
end

function PetNeidan_Tujian_CloseClick()
	this:Hide()
end

function PetNeidan_Tujian_OnHidden()
	PetNeidan_Tujian_CleanUp()
	DataPool:LuaFn_MouseCmd_Cancel_PND_HQ()
end

function PetNeidan_Tujian_UpdateCheckButton()
	if g_CurrentFilter == 2 then
		PetNeidan_Tujian_ListPage1:SetCheck(1)
		PetNeidan_Tujian_ListPage2:SetCheck(0)
		PetNeidan_Tujian_ListPage3:SetCheck(0)
	elseif g_CurrentFilter == 3 then
		PetNeidan_Tujian_ListPage1:SetCheck(0)
		PetNeidan_Tujian_ListPage2:SetCheck(1)
		PetNeidan_Tujian_ListPage3:SetCheck(0)
	elseif g_CurrentFilter == 4 then
		PetNeidan_Tujian_ListPage1:SetCheck(0)
		PetNeidan_Tujian_ListPage2:SetCheck(0)
		PetNeidan_Tujian_ListPage3:SetCheck(1)
	else
		PetNeidan_Tujian_ListPage1:SetCheck(0)
		PetNeidan_Tujian_ListPage2:SetCheck(0)
		PetNeidan_Tujian_ListPage3:SetCheck(0)
	end
end

--内丹类型切换
function PetNeidan_Tujian_SubFenYe_Switch(idx)
	if g_CurrentFilter == idx then
		return
	end
	
	g_CurrentFilter = idx
	g_CurrentSelect = 1
	PetNeidan_Tujian_UpdateCheckButton()
	g_NeedChangeNeiDanScrollSize = 1
	PetNeidan_Tujian_UpdateNeiDanList()
	PetNeidan_Tujian_SetPetNeiDanSelected(g_CurrentSelect)
	PetNeidan_Tujian_UpdateInfo()
end
