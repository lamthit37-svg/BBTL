--!!!reloadscript =Rune_Stars

local g_Rune_Stars_UnifiedPosition = ""
local g_MaxBarNum = 0
local g_MaxSkillBarNum = 0
local g_ActivedButton = {}
local g_LockLimit = {50, 60, 70, 80}
local g_BarListA = {}
local g_BarListB = {}
local g_SkillAction = {}
local g_CurrentFilterA = 0
local g_CurrentFilterB = 0
local g_InitList = 0
local g_ShowType = 0

local g_MaxOrder = 5
local g_SelXingJuanID = 0
local g_SelXingJuanIndex = 0

local g_XingJuanOrderImg = {
	"set:Rune_Star01 image:Rune_Level01",
	"set:Rune_Star01 image:Rune_Level02",
	"set:Rune_Star01 image:Rune_Level03",
	"set:Rune_Star01 image:Rune_Level04",
	"set:Rune_Star01 image:Rune_Level05",
}

local g_CurAttrPage = 1
local g_AttrNumOfPage = 12
local g_MaxAttrPage = 0
local g_AttrList = {}

local g_SlotActiveCount = 0
local g_LowestSlotOrder = 0

local g_NeedChangeScrollSize = 0

function Rune_Stars_PreLoad()

	this:RegisterEvent("OPEN_XINGZHEN")	
	this:RegisterEvent("XINGZHEN_UPDATE",false)
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	--更新装备
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("XINGJUAN_STOREEXP",false)
	this:RegisterEvent("XINGJUAN_CHIPDRE",false)
	this:RegisterEvent("XINGJUAN_CHIPESS",false)
	this:RegisterEvent("YINGXIONG_REDPOINT")
	this:RegisterEvent("CLOSE_XINGZHENUI_GROUP",false)
end

function Rune_Stars_OnLoad()

	g_Rune_Stars_UnifiedPosition = Rune_Stars_Frame:GetProperty("UnifiedPosition")
	
	g_ActivedButton = {btn = {}, rank = {}, tip = {}}
	
	g_ActivedButton.btn[1] = Rune_Stars_Button1
	g_ActivedButton.btn[2] = Rune_Stars_Button3
	g_ActivedButton.btn[3] = Rune_Stars_Button4
	g_ActivedButton.btn[4] = Rune_Stars_Button2
	
	g_ActivedButton.rank[1] = Rune_Stars_Button1Rank
	g_ActivedButton.rank[2] = Rune_Stars_Button3Rank
	g_ActivedButton.rank[3] = Rune_Stars_Button4Rank
	g_ActivedButton.rank[4] = Rune_Stars_Button2Rank	
	
	g_ActivedButton.tip[1] = Rune_Stars_Button1tips
	g_ActivedButton.tip[2] = Rune_Stars_Button3tips
	g_ActivedButton.tip[3] = Rune_Stars_Button4tips
	g_ActivedButton.tip[4] = Rune_Stars_Button2tips	
	
	Rune_Stars_StarBind:AddTextItem("#{XZJC_200309_72}" ,1)	--全部
	Rune_Stars_StarBind:AddTextItem("#{XZJC_200309_73}" ,2)	--橙色
	Rune_Stars_StarBind:AddTextItem("#{XZJC_200309_74}" ,3)	--紫色
	Rune_Stars_StarBind:AddTextItem("#{XZJC_200309_75}" ,4)	--蓝色
	Rune_Stars_StarBind:AddTextItem("#{XZJC_200309_76}" ,5)	--绿色
	
	Rune_Stars_SkillBind:AddTextItem("#{XZJC_200309_72}" ,1)	--全部
	Rune_Stars_SkillBind:AddTextItem("#{XZJC_200309_73}" ,2)	--橙色
	Rune_Stars_SkillBind:AddTextItem("#{XZJC_200309_74}" ,3)	--紫色
	Rune_Stars_SkillBind:AddTextItem("#{XZJC_200309_75}" ,4)	--蓝色
	Rune_Stars_SkillBind:AddTextItem("#{XZJC_200309_76}" ,5)	--绿色
	
	g_SkillAction = {btn = {}, lv_text = {}, lv_bk = {}, tip = {}}
	g_SkillAction.btn[1] = Rune_Stars_EffectItem1
	g_SkillAction.btn[2] = Rune_Stars_EffectItem3
	g_SkillAction.btn[3] = Rune_Stars_EffectItem4
	g_SkillAction.btn[4] = Rune_Stars_EffectItem2
	
	g_SkillAction.lv_text[1] = Rune_Stars_EffectItem1Steps
	g_SkillAction.lv_text[2] = Rune_Stars_EffectItem3Steps
	g_SkillAction.lv_text[3] = Rune_Stars_EffectItem4Steps
	g_SkillAction.lv_text[4] = Rune_Stars_EffectItem2Steps
	
	g_SkillAction.lv_bk[1] = Rune_Stars_EffectItem1StepsBK
	g_SkillAction.lv_bk[2] = Rune_Stars_EffectItem3StepsBK
	g_SkillAction.lv_bk[3] = Rune_Stars_EffectItem4StepsBK
	g_SkillAction.lv_bk[4] = Rune_Stars_EffectItem2StepsBK
	
	g_SkillAction.tip[1] = Rune_Stars_EffectItem1tips
	g_SkillAction.tip[2] = Rune_Stars_EffectItem3tips
	g_SkillAction.tip[3] = Rune_Stars_EffectItem4tips
	g_SkillAction.tip[4] = Rune_Stars_EffectItem2tips	
	
	for i = 1, 4 do
		g_ActivedButton.btn[i]:SetProperty("DragAcceptName", "WB"..tostring(i))
		g_SkillAction.btn[i]:SetProperty("DragAcceptName", "WD"..tostring(i))
	end
	
	g_AttrList = {bk = {}, str = {}, value = {}}
	g_AttrList.bk[1] =	Rune_Stars_NumListCoinAItemBK
	g_AttrList.bk[2] =	Rune_Stars_NumListCoinAItem2BK
	g_AttrList.bk[3] =	Rune_Stars_NumListCoinAItem3BK
	g_AttrList.bk[4] =	Rune_Stars_NumListCoinAItem4BK
	g_AttrList.bk[5] =	Rune_Stars_NumListCoinAItem5BK
	g_AttrList.bk[6] =	Rune_Stars_NumListCoinAItem6BK
	g_AttrList.bk[7] =	Rune_Stars_NumListCoinAItem7BK
	g_AttrList.bk[8] =	Rune_Stars_NumListCoinAItem8BK
	g_AttrList.bk[9] =	Rune_Stars_NumListCoinAItem9BK
	g_AttrList.bk[10] =	Rune_Stars_NumListCoinAItem10BK
	g_AttrList.bk[11] =	Rune_Stars_NumListCoinAItem11BK
	g_AttrList.bk[12] =	Rune_Stars_NumListCoinAItem12BK
	
	g_AttrList.str[1] =	Rune_Stars_NumListInfo
	g_AttrList.str[2] =	Rune_Stars_NumList2Info
	g_AttrList.str[3] =	Rune_Stars_NumList3Info
	g_AttrList.str[4] =	Rune_Stars_NumList4Info
	g_AttrList.str[5] =	Rune_Stars_NumList5Info
	g_AttrList.str[6] =	Rune_Stars_NumList6Info
	g_AttrList.str[7] =	Rune_Stars_NumList7Info
	g_AttrList.str[8] =	Rune_Stars_NumList8Info
	g_AttrList.str[9] =	Rune_Stars_NumList9Info
	g_AttrList.str[10] = Rune_Stars_NumList10Info
	g_AttrList.str[11] = Rune_Stars_NumList11Info
	g_AttrList.str[12] = Rune_Stars_NumList12Info
	
	g_AttrList.value[1] =	Rune_Stars_NumListInfo2
	g_AttrList.value[2] =	Rune_Stars_NumList2Info2
	g_AttrList.value[3] =	Rune_Stars_NumList3Info2
	g_AttrList.value[4] =	Rune_Stars_NumList4Info2
	g_AttrList.value[5] =	Rune_Stars_NumList5Info2
	g_AttrList.value[6] =	Rune_Stars_NumList6Info2
	g_AttrList.value[7] =	Rune_Stars_NumList7Info2
	g_AttrList.value[8] =	Rune_Stars_NumList8Info2
	g_AttrList.value[9] =	Rune_Stars_NumList9Info2
	g_AttrList.value[10] =	Rune_Stars_NumList10Info2
	g_AttrList.value[11] =	Rune_Stars_NumList11Info2
	g_AttrList.value[12] =	Rune_Stars_NumList12Info2

end

function Rune_Stars_OnEvent(event)

	if event == "OPEN_XINGZHEN" then
		if TLCJ:IsInTLCJScene() > 0 then
			PushDebugMessage("#{TLCJ_20240709_69}")
			return 
		end
		if Player:GetData("IsOriginalJD") == 1 then
			PushDebugMessage("#{SJF_251024_1}")
			return
		end
		if Player:GetData("Is2606S") == 1 then
			PushDebugMessage("#{SJF_251024_1}")
			return
		end

		local nSel = tonumber(arg0)
		this:Show()
		g_ShowType = 0
		g_CurrentFilterA = 1
		g_NeedChangeScrollSize = 1
		Rune_Stars_StarBind:SetText("#{XZJC_200309_72}")
		Rune_Stars_Update()
		g_SelXingJuanID = nSel
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "CLOSE_XINGZHENUI_GROUP" then
		this:Hide()
		return
	end
	
	if event == "XINGZHEN_UPDATE"  and this:IsVisible() then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Frame:GetProperty("UnifiedPosition"), 1)	
		if arg0 == "slot" then
		
		end
		Rune_Stars_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Rune_Stars_On_ResetPos()
	end
	
	if event == "YINGXIONG_REDPOINT" then
		if tonumber(arg0)==1 or tonumber(arg1)==1 or tonumber(arg2) == 1 then 
			Rune_Stars_FenYe4_Buttontips:Show()
		else
			Rune_Stars_FenYe4_Buttontips:Hide()
		end
	end
end

function Rune_Stars_InitListBar()
	
	if g_InitList == 0 then		
		g_MaxBarNum = DataPool:LuaFnGetXingJuanMaxCount()
		for i = 1, g_MaxBarNum do
			local bar = Rune_Stars_StarLace:AddChild("Rune_Stars_StarCoinAItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			g_BarListA[i] = bar	
			bar:GetSubItem("Rune_Stars_StarCoinAItemOption"):SetEvent("MouseLButtonDown", string.format("Rune_Stars_ItemClicked(%d)", i))
			bar:GetSubItem("Rune_Stars_StarCoinAItemOption"):SetEvent("MouseMove", string.format("Rune_Stars_ItemMouseMove(%d)", i))
			bar:GetSubItem("Rune_Stars_StarCoinAItemOption"):SetProperty("DragAcceptName", "WA"..tostring(i))
		end
		
		g_MaxSkillBarNum = DataPool:LuaFnGetSkillCardMaxCount()
		for i = 1, g_MaxSkillBarNum do
			local bar = Rune_Stars_SkillLace:AddChild("Rune_Stars_SkillCoinAItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			g_BarListB[i] = bar	
			bar:GetSubItem("Rune_Stars_SkillCoinAItemOption"):SetEvent("MouseLButtonDown", string.format("Rune_Stars_ItemClicked_Skill(%d)", i))
			bar:GetSubItem("Rune_Stars_SkillCoinAItemOption"):SetEvent("MouseMove", string.format("Rune_Stars_ItemMouseMove_Skill(%d)", i))
			bar:GetSubItem("Rune_Stars_SkillCoinAItemOption"):SetProperty("DragAcceptName", "WC"..tostring(i))
		end
		g_InitList = 1
	end
end

--刷新
function Rune_Stars_Update()
	
	local selfUnionPos = Variable:GetVariable("RuneStarPos")
	if selfUnionPos ~= nil then
		Rune_Stars_Frame:SetProperty("UnifiedPosition", selfUnionPos)
	end
	
	Rune_Stars_InitListBar()
	
	Rune_Stars_Refresh_Page_Button()
	
	Rune_Stars_UpdateRedPoint()
	
	Rune_Stars_ListCleanUpAction()
	
	Rune_Stars_UpdateList()

	local nLevel = Player:GetData("LEVEL")

	g_SlotActiveCount = 0
	g_LowestSlotOrder = g_MaxOrder
	
	local xj_to_slot = DataPool:LuaFnHaveXingJuanToSlot()
	for i = 1, 4 do

		g_ActivedButton.btn[i]:SetActionItem(-1)
		g_ActivedButton.btn[i]:SetToolTip("#{XZJC_200309_233}")
		g_ActivedButton.btn[i]:SetProperty("DraggingEnabled","False")

		g_ActivedButton.rank[i]:Hide()
		g_ActivedButton.tip[i]:Hide()
		
		g_SkillAction.btn[i]:SetActionItem(-1)
		g_SkillAction.btn[i]:SetToolTip("#{XZJC_200309_258}")		
		g_SkillAction.btn[i]:SetProperty("DraggingEnabled","False")		
		g_SkillAction.lv_bk[i]:Hide()	
		g_SkillAction.tip[i]:Hide()

		local nXingJuanID = DataPool:LuaFnGetActivedXingJuanID(i)			
		
		if nXingJuanID <= 0 and xj_to_slot == 1 then
			g_ActivedButton.tip[i]:Show()
		end
		
		if nXingJuanID > 0 then
		
			g_ActivedButton.btn[i]:SetToolTip("")
			
			local theAction = EnumAction(nXingJuanID,"xingjuan")
			if theAction:GetID() ~= 0 then
				g_ActivedButton.btn[i]:SetActionItem(theAction:GetID())
				g_ActivedButton.btn[i]:SetProperty("DraggingEnabled","True")
			end
			
			local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
			if nOrder > 0 then
				g_ActivedButton.rank[i]:Show()
				g_ActivedButton.rank[i]:SetProperty("Image",g_XingJuanOrderImg[nOrder])
			end
			
			g_SlotActiveCount = g_SlotActiveCount + 1
			if nOrder < g_LowestSlotOrder then
				g_LowestSlotOrder = nOrder
			end
			
			local nCardID = DataPool:LuaFnGetActivedSkillCardID(i)

			if nCardID > 0 then
				g_SkillAction.btn[i]:SetToolTip("")
				g_SkillAction.lv_bk[i]:Show()
				
				local nCardLevel = DataPool:LuaFnGetSkillCardInfo(nCardID, "Level")
				g_SkillAction.lv_text[i]:SetText(tostring(nCardLevel))
				
				local cardAction = EnumAction(nCardID,"skillcard")
				if cardAction:GetID() ~= 0 then
					g_SkillAction.btn[i]:SetActionItem(cardAction:GetID())
					g_SkillAction.btn[i]:SetProperty("DraggingEnabled","True")	
				end
			else
				if DataPool:LuaFnHaveSkillCardToSlot(i) == 1 then
					g_SkillAction.tip[i]:Show()
				end
			end
		end	
	end
	
	local strAllXingJuanAttr = DataPool:LuaFnGetXingZhenAllAttrDesc()
	if strAllXingJuanAttr == "" then
		Rune_Stars_StarBtn_Look:SetToolTip("#Y".."#{XZJC_200309_273}")
	else
		Rune_Stars_StarBtn_Look:SetToolTip("#Y"..strAllXingJuanAttr)
	end
	
	Rune_Stars_UpdateAttrList(g_SlotActiveCount, g_LowestSlotOrder)
	
end

function Rune_Stars_UpdateList()
	
	if g_ShowType == 0 then
	
		Rune_Stars_ListStar:Show()
		Rune_Stars_ListSkill:Hide()
		
		Rune_Stars_LittleFenYe1:SetCheck(1)		
		Rune_Stars_LittleFenYe2:SetCheck(0)
		
		DataPool:LuaFnInitXingJuanList(0, 1, g_CurrentFilterA)
		local nCount = DataPool:LuaFnGetXingJuanListCount()	
		
		for i = 1, g_MaxBarNum do
			Rune_Stars_SetItem(i, nCount)
		end
		
		if g_NeedChangeScrollSize == 1 then
			Rune_Stars_StarLace:RefreshLayout()
			Rune_Stars_StarLace:SetScrollPosition(0)
			g_NeedChangeScrollSize = 0
		end
		
		if g_SelXingJuanIndex ~= 0 then
			Rune_Stars_StarLace:SetScrollPosition4Index(g_SelXingJuanIndex - 1)
			g_SelXingJuanID = 0
			g_SelXingJuanIndex = 0
		end
		
	else
		Rune_Stars_ListStar:Hide()
		Rune_Stars_ListSkill:Show()
		
		Rune_Stars_LittleFenYe1:SetCheck(0)		
		Rune_Stars_LittleFenYe2:SetCheck(1)
		
		DataPool:LuaFnInitSkillCardList(g_CurrentFilterB)
		local nCount = DataPool:LuaFnGetSkillCardListCount()	
		
		for i = 1, g_MaxSkillBarNum do
			Rune_Stars_SetItem_Skill(i, nCount)
		end
		
		if g_NeedChangeScrollSize == 1 then
			Rune_Stars_SkillLace:RefreshLayout()
			Rune_Stars_SkillLace:SetScrollPosition(0)
			g_NeedChangeScrollSize = 0
		end		
	end
	
end

function Rune_Stars_SetItem(idx, max_count)

	if g_BarListA[idx] == nil then
		return
	end
	
	if idx > max_count then
		g_BarListA[idx]:Hide()
		return
	end
	
	local bar = g_BarListA[idx]
	bar:Show()
	
	local nXingJuanID = DataPool:LuaFnGetXingJuanID(idx - 1)	
	local nUnLocked = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "UnLocked")
	local nLevel = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Level")
	local nSlot = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Slot")
	local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
	local nNew = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "New")
	local nQuality = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Quality")
	local strName = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Name")
	
	local strNameWithColor = strName
	if nQuality == 1 then
		strNameWithColor = "#G"..strNameWithColor
	elseif nQuality == 2 then
		strNameWithColor = "#B"..strNameWithColor
	elseif nQuality == 3 then
		strNameWithColor = "#cbe38ff"..strNameWithColor
	elseif nQuality == 4 then
		strNameWithColor = "#cfff965"..strNameWithColor
	end
		
	bar:GetSubItem("Rune_Stars_StarCoinAItemOptionName"):SetText(tostring("#L"..strName))
	
	if nNew == 1 then
		bar:GetSubItem("Rune_Stars_StarCoinAItemOptiontips"):Show()
	else
		bar:GetSubItem("Rune_Stars_StarCoinAItemOptiontips"):Hide()
	end
	
	--激活锁
	if nUnLocked == 1 then
		bar:GetSubItem("Rune_Stars_StarLock"):Hide()
		if nOrder > 0 then
		bar:GetSubItem("Rune_Stars_StarFightRank"):Show()
			bar:GetSubItem("Rune_Stars_StarFightRank"):SetProperty("Image",g_XingJuanOrderImg[nOrder])
		else
			bar:GetSubItem("Rune_Stars_StarFightRank"):Hide()
		end
	else
		bar:GetSubItem("Rune_Stars_StarLock"):Show()
		bar:GetSubItem("Rune_Stars_StarFightRank"):Hide()		
	end
	
	--上阵标识
	if nSlot > 0 then
		bar:GetSubItem("Rune_Stars_StarFight"):Show()		
	else
		bar:GetSubItem("Rune_Stars_StarFight"):Hide()
	end	

	local ctrlAction = bar:GetSubItem("Rune_Stars_StarCoinAItemOption")
	if ctrlAction ~= nil then
		ctrlAction:SetActionItem(-1)
		
		local theAction = EnumAction(nXingJuanID,"xingjuan")
		if theAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theAction:GetID())
		end
	
		if nUnLocked == 1 and nSlot == 0 then
			ctrlAction:SetProperty("DraggingEnabled","True")
		else
			ctrlAction:SetProperty("DraggingEnabled","False")
		end
		
		if g_SelXingJuanID == nXingJuanID then
			ctrlAction:SetPushed(1)
			g_SelXingJuanIndex = idx
		end
	end	

end

function Rune_Stars_SetItem_Skill(idx, max_count)

	if g_BarListB[idx] == nil then
		return
	end
	
	if idx > max_count then
		g_BarListB[idx]:Hide()
		return
	end
	
	local bar = g_BarListB[idx]
	bar:Show()
	
	local nSkillCardID = DataPool:LuaFnGetSkillCardID(idx - 1)	
	local nUnLocked = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "UnLocked")
	local nLevel = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Level")
	local nSlot = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Slot")
	local nNew = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "New")
	local strName = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Name")
	local nQuality = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Quality")
	
	local strNameWithColor = strName
	if nQuality == 1 then
		strNameWithColor = "#G"..strNameWithColor
	elseif nQuality == 2 then
		strNameWithColor = "#B"..strNameWithColor
	elseif nQuality == 3 then
		strNameWithColor = "#cbe38ff"..strNameWithColor
	elseif nQuality == 4 then
		strNameWithColor = "#cfff965"..strNameWithColor
	end
	
	bar:GetSubItem("Rune_Stars_SkillCoinAItemOptionName"):SetText(tostring("#L"..strName))
	
	if nNew == 1 then
		bar:GetSubItem("Rune_Stars_SkillCoinAItemOptiontips"):Show()
	else
		bar:GetSubItem("Rune_Stars_SkillCoinAItemOptiontips"):Hide()
	end
	--激活锁
	if nUnLocked == 1 then
		bar:GetSubItem("Rune_Stars_SkillLock"):Hide()
		bar:GetSubItem("Rune_Stars_SkillCoinAItemStepsBK"):Show()
		bar:GetSubItem("Rune_Stars_SkillCoinAItemSteps"):SetText(tostring(nLevel))
	else
		bar:GetSubItem("Rune_Stars_SkillLock"):Show()
		bar:GetSubItem("Rune_Stars_SkillCoinAItemStepsBK"):Hide()
	end
	
	--上阵标识
	if nSlot > 0 then
		bar:GetSubItem("Rune_Stars_SkillFight"):Show()
	else
		bar:GetSubItem("Rune_Stars_SkillFight"):Hide()
	end

	local ctrlAction = bar:GetSubItem("Rune_Stars_SkillCoinAItemOption")
	if ctrlAction ~= nil then
		ctrlAction:SetActionItem(-1)
		
		local theAction = EnumAction(nSkillCardID,"skillcard")
		if theAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theAction:GetID())
		end
	
		if nUnLocked == 1 and nSlot == 0 then
			ctrlAction:SetProperty("DraggingEnabled","True")
		else
			ctrlAction:SetProperty("DraggingEnabled","False")
		end
	end

end

function Rune_Stars_UpdateAttrList(nSlotActiveCount, nLowLevel)
	
	for i = 1, g_AttrNumOfPage do
		g_AttrList.bk[i]:Hide()	
	end
	
	local count = DataPool:LuaFnGetXingZhenSlotAttrListCount()
	
	local pagenum = math.floor(count / g_AttrNumOfPage)
	if math.mod(count, g_AttrNumOfPage) ~= 0 then
		pagenum = pagenum + 1
	end

	g_MaxAttrPage = pagenum
	
	if g_CurAttrPage > g_MaxAttrPage or g_CurAttrPage < 1 then
		g_CurAttrPage = 1
	end
	
	local start_index = g_AttrNumOfPage * (g_CurAttrPage - 1) + 1
	local valid_index = 1
	
	--Rune_Stars_ItemUpBtn:Disable()
	--Rune_Stars_ItemDownBtn:Disable()
	if g_CurAttrPage > 1 then
		--Rune_Stars_ItemUpBtn:Enable()
	end
	
	if g_CurAttrPage < g_MaxAttrPage then
		--Rune_Stars_ItemDownBtn:Enable()
	end
	
	for i = 1, count do
		
		if valid_index > g_AttrNumOfPage or start_index > count then
			break
		end		
		
		local strAttr, attr_value, attr_add, attr_type, attrValue = DataPool:LuaFnGetXingZhenSlotAttr(start_index - 1, 0, 0)
		if strAttr ~= "" then
			
			g_AttrList.bk[valid_index]:Show()
			g_AttrList.str[valid_index]:SetText("#L"..strAttr)
			g_AttrList.value[valid_index]:SetText("#L+"..attr_value)

			if attr_type == 37 then
				g_AttrList.value[valid_index]:SetToolTip("#{XZJC_200309_237}")
			elseif attr_type == 47 then
				g_AttrList.value[valid_index]:SetToolTip("#{XZJC_200309_238}")
			else
				g_AttrList.value[valid_index]:SetToolTip("#{XZJC_200309_21}")
			end
			
			valid_index = valid_index + 1
			start_index = start_index + 1
		end
	end
end

function Rune_Stars_ItemClicked(nIndex)

	local nXingJuanID = DataPool:LuaFnGetXingJuanID(nIndex - 1)		
	local nUnLocked = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "UnLocked")
	if nUnLocked ~= 1 then
		PushDebugMessage("#{XZJC_200309_271}")
		return
	end
	
	for i = 1, g_MaxBarNum do		
		if g_BarListA[i] ~= nil then	
			local ctrlAction = g_BarListA[i]:GetSubItem("Rune_Stars_StarCoinAItemOption")
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

function Rune_Stars_ItemClicked_Skill(nIndex)

	local nSkillCardID = DataPool:LuaFnGetSkillCardID(nIndex - 1)	
	local nUnLocked = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "UnLocked")	
	
	if nUnLocked ~= 1 then
		PushDebugMessage("#{XZJC_200309_272}")
		return
	end
	
	for i = 1, g_MaxSkillBarNum do		
		if g_BarListB[i] ~= nil then	
			local ctrlAction = g_BarListB[i]:GetSubItem("Rune_Stars_SkillCoinAItemOption")
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

function Rune_Stars_UnActive(nSlotIndex)	
	local nXingJuanID = DataPool:LuaFnGetActivedXingJuanID(nSlotIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("InsertSlot")
		Set_XSCRIPT_ScriptID(888555)
		Set_XSCRIPT_Parameter(0, nXingJuanID)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function Rune_Stars_RBClicked(nSlotIndex)	
	Rune_Stars_UnActive(nSlotIndex)
end

function Rune_Stars_RBClicked_Skill(nSlotIndex)	
	local nSkillCardID = DataPool:LuaFnGetActivedSkillCardID(nSlotIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("InsertSlot")
		Set_XSCRIPT_ScriptID(888555)
		Set_XSCRIPT_Parameter(0, nSkillCardID)	
		Set_XSCRIPT_Parameter(1, 0)				--上阵插槽0标识卸下
		Set_XSCRIPT_Parameter(2, 1)				--表示技能
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function Rune_Stars_OnCloseClicked()
	this:Hide()
end

function Rune_Stars_OnHidden()
	Rune_Stars_ListCleanUpAction()	
	for i = 1, 4 do
		g_ActivedButton.btn[i]:SetActionItem(-1)
		g_SkillAction.btn[i]:SetActionItem(-1)
	end
	
end

function Rune_Stars_Elements_MouseLeave(nIndex)
	Lua_CloseFiveElementsTip(0 , nIndex)
end

function Rune_Stars_Elements_MouseEnter(nIndex)

end

function Rune_Stars_ListCleanUpAction()	
	for i = 1, g_MaxBarNum do
		if g_BarListA[i] then			
			local ctrlAction = g_BarListA[i]:GetSubItem("Rune_Stars_StarCoinAItemOption")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end	
	end
	
	for i = 1, g_MaxSkillBarNum do
		if g_BarListB[i] then			
			local ctrlAction = g_BarListB[i]:GetSubItem("Rune_Stars_SkillCoinAItemOption")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end	
	end
end

function Rune_Stars_OnSelectFilter(idx)
	
	if idx == 0 then
		local _,nIndex = Rune_Stars_StarBind:GetCurrentSelect()
		if g_CurrentFilterA == nIndex then
			return
		end
		g_CurrentFilterA = nIndex
		g_NeedChangeScrollSize = 1
		Rune_Stars_UpdateList()
	else
		local _,nIndex = Rune_Stars_SkillBind:GetCurrentSelect()
		if g_CurrentFilterB == nIndex then
			return
		end
		g_CurrentFilterB = nIndex
		g_NeedChangeScrollSize = 1
		Rune_Stars_UpdateList()
	end
end

function Rune_Stars_FenYe_Switch(idx)
	--养成
	if idx == 2 then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Frame:GetProperty("UnifiedPosition"), 1)
		LuaFnOpenXingZhenUpgrade()
	elseif idx == 3 then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Frame:GetProperty("UnifiedPosition"), 1)
		LuaFnOpenXingZhenSkill()
	elseif idx == 4 then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Frame:GetProperty("UnifiedPosition"), 1)		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenXZ_Heroes") 		-- 脚本号
			Set_XSCRIPT_ScriptID(888052)					-- 脚本编号
			Set_XSCRIPT_ParamCount(0)						-- 参数个数
		Send_XSCRIPT()
	end

end

function Rune_Stars_SubFenYe_Switch(idx)
	
	if g_ShowType == idx then
		return
	end
	
	g_ShowType = idx
	g_CurrentFilterA = 1
	g_CurrentFilterB = 1
	Rune_Stars_StarBind:SetText("#{XZJC_200309_72}")
	Rune_Stars_SkillBind:SetText("#{XZJC_200309_72}")
	g_NeedChangeScrollSize = 1
	Rune_Stars_UpdateList()

end

function Rune_Stars_Refresh_Page_Button()
	Rune_Stars_FenYe1:SetCheck(1)
	Rune_Stars_FenYe2:SetCheck(0)
	Rune_Stars_FenYe3:SetCheck(0)
	Rune_Stars_FenYe4:SetCheck(0)	
end

function Rune_Stars_On_ResetPos()
	if g_Rune_Stars_UnifiedPosition ~= nil then
		Rune_Stars_Frame:SetProperty("UnifiedPosition", g_Rune_Stars_UnifiedPosition)
	end
end

function Rune_Stars_ShowSlotTip(flag)
--	LuaFnShowXingZhenSlotTip(flag, 0)
end

function Rune_Stars_AttrPageUp()
	
	if g_CurAttrPage <= 1 then
		return
	end
	
	g_CurAttrPage = g_CurAttrPage - 1 
	
	Rune_Stars_UpdateAttrList(g_SlotActiveCount, g_LowestSlotOrder)
	
end

function Rune_Stars_AttrPageDown()
	
	if g_CurAttrPage >= g_MaxAttrPage then
		return
	end
	
	g_CurAttrPage = g_CurAttrPage + 1
	
	Rune_Stars_UpdateAttrList(g_SlotActiveCount, g_LowestSlotOrder)

end

function Rune_Stars_UpdateRedPoint()

	Rune_Stars_FenYe1_Buttontips:Hide()
	Rune_Stars_FenYe2_Buttontips:Hide()
	Rune_Stars_FenYe3_Buttontips:Hide()	
	
	Rune_Stars_LittleFenYe1tips:Hide()
	Rune_Stars_LittleFenYe2tips:Hide()
	
	--有星卷可以上阵
	local nHaveXingJuanToSlot = DataPool:LuaFnHaveXingJuanToSlot()	
	if nHaveXingJuanToSlot == 1 then
		Rune_Stars_FenYe1_Buttontips:Show()
		Rune_Stars_LittleFenYe1tips:Show()
	end
	
	--有技能可以上阵	
	local bHaveSkillCardToSlot = 0
	for i = 1, 4 do
		if DataPool:LuaFnHaveSkillCardToSlot(i) == 1 then
			bHaveSkillCardToSlot = 1
			break
		end
	end
	if bHaveSkillCardToSlot == 1 then
		Rune_Stars_FenYe1_Buttontips:Show()
		Rune_Stars_LittleFenYe2tips:Show()
	end
	
		--有新的星卷
	local nHaveNewXingJuan = DataPool:LuaFnHaveNewXingJuan()
	if nHaveNewXingJuan == 1 then
		Rune_Stars_FenYe1_Buttontips:Show()
		Rune_Stars_LittleFenYe1tips:Show()
	end
	
		--有新的技能
	local nHaveNewSkillCard = DataPool:LuaFnHaveNewSkillCard()
	if nHaveNewSkillCard == 1 then
		Rune_Stars_FenYe1_Buttontips:Show()
		Rune_Stars_LittleFenYe2tips:Show()
	end	
	
	if DataPool:LuaFnHaveXingJuanToUpgrade() == 1 then
		--有星卷可以升阶
		Rune_Stars_FenYe2_Buttontips:Show()
	elseif DataPool:LuaFnHaveXingJuanToUnLock() == 1 then	
		--有星卷可以激活
		Rune_Stars_FenYe2_Buttontips:Show()
	end
	
	--有技能可以升级
	if DataPool:LuaFnHaveSkillCardToLevelUp() == 1 then
		Rune_Stars_FenYe3_Buttontips:Show()	
	end
end

function Rune_Stars_ItemMouseMove(nIndex)

	if g_BarListA[nIndex] ~= nil then	
		g_BarListA[nIndex]:GetSubItem("Rune_Stars_StarCoinAItemOptiontips"):Hide()
	end
	
	local nXingJuanID = DataPool:LuaFnGetXingJuanID(nIndex - 1)
	local nNew = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "New")
	if nNew == 1 then
		DataPool:LuaFnRemoveXingJuanNew(nXingJuanID)
		Rune_Stars_UpdateRedPoint()
	end
end

function Rune_Stars_ItemMouseMove_Skill(nIndex)

	if g_BarListB[nIndex] ~= nil then	
		g_BarListB[nIndex]:GetSubItem("Rune_Stars_SkillCoinAItemOptiontips"):Hide()
	end
	
	local nSkillCardID = DataPool:LuaFnGetSkillCardID(nIndex - 1)	
	local nNew = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "New")
	if nNew == 1 then
		DataPool:LuaFnRemoveSkillCardNew(nSkillCardID)
		Rune_Stars_UpdateRedPoint()
	end
end


--!!!reloadscript =Rune_Stars
