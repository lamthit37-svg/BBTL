--!!!reloadscript =TargetRune

local g_TargetRune_Frame_UnifiedPosition = ""

local g_ActivedButton = {}
local g_SkillAction = {}
local g_MaxOrder = 5
local g_SlotAttrList = {}
local g_AttrNumOfSlotPage = 12

local g_SlotActiveCount = 0
local g_LowestSlotOrder = 0

local g_ActiveAttrList = {}
local g_AttrNumOfActivePage = 8
local g_MaxActiveAttrPage = 0
local g_CurActiveAttrPage = 1

local g_objCared = -1

local g_OrderBonusText = {
	{count = 4, order = 1,	no = "#{XZJC_200309_169}", yes = "#{XZJC_200309_170}"},
	{count = 4, order = 2,	no = "#{XZJC_200309_171}", yes = "#{XZJC_200309_172}"},
	{count = 4, order = 3,	no = "#{XZJC_200309_173}", yes = "#{XZJC_200309_174}"},
	{count = 4, order = 4,	no = "#{XZJC_200309_175}", yes = "#{XZJC_200309_176}"},
	{count = 4, order = 5,	no = "#{XZJC_200309_177}", yes = "#{XZJC_200309_178}"},
}

local g_XingJuanOrderImg = {
	"set:Rune_Star01 image:Rune_Level01",
	"set:Rune_Star01 image:Rune_Level02",
	"set:Rune_Star01 image:Rune_Level03",
	"set:Rune_Star01 image:Rune_Level04",
	"set:Rune_Star01 image:Rune_Level05",
}
local g_tab_JiBanAttrInfo = {}

function TargetRune_PreLoad()

	this:RegisterEvent("OPEN_OTHER_XINGZHEN")	
	this:RegisterEvent("OTHER_XINGZHEN_UPDATE",false)
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	--更新装备
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function TargetRune_OnLoad()

	g_TargetRune_Frame_UnifiedPosition = TargetRune_Frame:GetProperty("UnifiedPosition")
	
	g_ActivedButton = {btn = {}, rank = {}}
	
	g_ActivedButton.btn[1] = TargetRune_Button1
	g_ActivedButton.btn[2] = TargetRune_Button3
	g_ActivedButton.btn[3] = TargetRune_Button4
	g_ActivedButton.btn[4] = TargetRune_Button2
	
	g_ActivedButton.rank[1] = TargetRune_Button1Rank
	g_ActivedButton.rank[2] = TargetRune_Button3Rank
	g_ActivedButton.rank[3] = TargetRune_Button4Rank
	g_ActivedButton.rank[4] = TargetRune_Button2Rank	
	
	g_SkillAction = {btn = {}, lv_text = {}, lv_bk = {}}
	g_SkillAction.btn[1] = TargetRune_EffectItem1
	g_SkillAction.btn[2] = TargetRune_EffectItem3
	g_SkillAction.btn[3] = TargetRune_EffectItem4
	g_SkillAction.btn[4] = TargetRune_EffectItem2
	
	g_SkillAction.lv_text[1] = TargetRune_EffectItem1Steps
	g_SkillAction.lv_text[2] = TargetRune_EffectItem3Steps
	g_SkillAction.lv_text[3] = TargetRune_EffectItem4Steps
	g_SkillAction.lv_text[4] = TargetRune_EffectItem2Steps
	
	g_SkillAction.lv_bk[1] = TargetRune_EffectItem1StepsBK
	g_SkillAction.lv_bk[2] = TargetRune_EffectItem3StepsBK
	g_SkillAction.lv_bk[3] = TargetRune_EffectItem4StepsBK
	g_SkillAction.lv_bk[4] = TargetRune_EffectItem2StepsBK
	
	g_SlotAttrList = {bk = {}, str = {}, value = {}, add = {}}
	g_SlotAttrList.bk[1] =	TargetRune_NumListCoinAItemBK
	g_SlotAttrList.bk[2] =	TargetRune_NumListCoinAItem2BK
	g_SlotAttrList.bk[3] =	TargetRune_NumListCoinAItem3BK
	g_SlotAttrList.bk[4] =	TargetRune_NumListCoinAItem4BK
	g_SlotAttrList.bk[5] =	TargetRune_NumListCoinAItem5BK
	g_SlotAttrList.bk[6] =	TargetRune_NumListCoinAItem6BK
	g_SlotAttrList.bk[7] =	TargetRune_NumListCoinAItem7BK
	g_SlotAttrList.bk[8] =	TargetRune_NumListCoinAItem8BK
	g_SlotAttrList.bk[9] =	TargetRune_NumListCoinAItem9BK
	g_SlotAttrList.bk[10] =	TargetRune_NumListCoinAItem10BK
	g_SlotAttrList.bk[11] =	TargetRune_NumListCoinAItem11BK
	g_SlotAttrList.bk[12] =	TargetRune_NumListCoinAItem12BK
	
	g_SlotAttrList.str[1] =	TargetRune_NumListInfo
	g_SlotAttrList.str[2] =	TargetRune_NumList2Info
	g_SlotAttrList.str[3] =	TargetRune_NumList3Info
	g_SlotAttrList.str[4] =	TargetRune_NumList4Info
	g_SlotAttrList.str[5] =	TargetRune_NumList5Info
	g_SlotAttrList.str[6] =	TargetRune_NumList6Info
	g_SlotAttrList.str[7] =	TargetRune_NumList7Info
	g_SlotAttrList.str[8] =	TargetRune_NumList8Info
	g_SlotAttrList.str[9] =	TargetRune_NumList9Info
	g_SlotAttrList.str[10] = TargetRune_NumList10Info
	g_SlotAttrList.str[11] = TargetRune_NumList11Info
	g_SlotAttrList.str[12] = TargetRune_NumList12Info
	
	g_SlotAttrList.value[1] =	TargetRune_NumListInfo2
	g_SlotAttrList.value[2] =	TargetRune_NumList2Info2
	g_SlotAttrList.value[3] =	TargetRune_NumList3Info2
	g_SlotAttrList.value[4] =	TargetRune_NumList4Info2
	g_SlotAttrList.value[5] =	TargetRune_NumList5Info2
	g_SlotAttrList.value[6] =	TargetRune_NumList6Info2
	g_SlotAttrList.value[7] =	TargetRune_NumList7Info2
	g_SlotAttrList.value[8] =	TargetRune_NumList8Info2
	g_SlotAttrList.value[9] =	TargetRune_NumList9Info2
	g_SlotAttrList.value[10] =	TargetRune_NumList10Info2
	g_SlotAttrList.value[11] =	TargetRune_NumList11Info2
	g_SlotAttrList.value[12] =	TargetRune_NumList12Info2
	
	g_SlotAttrList.add[1] =	TargetRune_NumListInfo3
	g_SlotAttrList.add[2] =	TargetRune_NumList2Info3
	g_SlotAttrList.add[3] =	TargetRune_NumList3Info3
	g_SlotAttrList.add[4] =	TargetRune_NumList4Info3
	g_SlotAttrList.add[5] =	TargetRune_NumList5Info3
	g_SlotAttrList.add[6] =	TargetRune_NumList6Info3
	g_SlotAttrList.add[7] =	TargetRune_NumList7Info3
	g_SlotAttrList.add[8] =	TargetRune_NumList8Info3
	g_SlotAttrList.add[9] =	TargetRune_NumList9Info3
	g_SlotAttrList.add[10] = TargetRune_NumList10Info3
	g_SlotAttrList.add[11] = TargetRune_NumList11Info3
	g_SlotAttrList.add[12] = TargetRune_NumList12Info3
	
	g_ActiveAttrList = {bk = {}, str = {}, value = {}}
	
	g_ActiveAttrList.bk[1] =	TargetRune_List1CoinAItem
	g_ActiveAttrList.bk[2] =	TargetRune_List1CoinAItem2
	g_ActiveAttrList.bk[3] =	TargetRune_List1CoinAItem3
	g_ActiveAttrList.bk[4] =	TargetRune_List1CoinAItem4
	g_ActiveAttrList.bk[5] =	TargetRune_List1CoinAItem5
	g_ActiveAttrList.bk[6] =	TargetRune_List1CoinAItem6
	g_ActiveAttrList.bk[7] =	TargetRune_List1CoinAItem7
	g_ActiveAttrList.bk[8] =	TargetRune_List1CoinAItem8
	g_ActiveAttrList.bk[9] =	TargetRune_List1CoinAItem9
	g_ActiveAttrList.bk[10] =	TargetRune_List1CoinAItem10
	g_ActiveAttrList.bk[11] =	TargetRune_List1CoinAItem11
	g_ActiveAttrList.bk[12] =	TargetRune_List1CoinAItem12
		
	g_ActiveAttrList.str[1] =	TargetRune_List1CoinAItem_Text
	g_ActiveAttrList.str[2] =	TargetRune_List1CoinAItem2_Text
	g_ActiveAttrList.str[3] =	TargetRune_List1CoinAItem3_Text
	g_ActiveAttrList.str[4] =	TargetRune_List1CoinAItem4_Text
	g_ActiveAttrList.str[5] =	TargetRune_List1CoinAItem5_Text
	g_ActiveAttrList.str[6] =	TargetRune_List1CoinAItem6_Text
	g_ActiveAttrList.str[7] =	TargetRune_List1CoinAItem7_Text
	g_ActiveAttrList.str[8] =	TargetRune_List1CoinAItem8_Text
	g_ActiveAttrList.str[9] =	TargetRune_List1CoinAItem9_Text
	g_ActiveAttrList.str[10] =	TargetRune_List1CoinAItem10_Text
	g_ActiveAttrList.str[11] =	TargetRune_List1CoinAItem11_Text
	g_ActiveAttrList.str[12] =	TargetRune_List1CoinAItem12_Text
		
		
		
		
	g_ActiveAttrList.value[1] =	TargetRune_List1CoinAItem_Text2
	g_ActiveAttrList.value[2] =	TargetRune_List1CoinAItem2_Text2
	g_ActiveAttrList.value[3] =	TargetRune_List1CoinAItem3_Text2
	g_ActiveAttrList.value[4] =	TargetRune_List1CoinAItem4_Text2
	g_ActiveAttrList.value[5] =	TargetRune_List1CoinAItem5_Text2
	g_ActiveAttrList.value[6] =	TargetRune_List1CoinAItem6_Text2
	g_ActiveAttrList.value[7] =	TargetRune_List1CoinAItem7_Text2
	g_ActiveAttrList.value[8] =	TargetRune_List1CoinAItem8_Text2
	g_ActiveAttrList.value[9] =	TargetRune_List1CoinAItem9_Text2
	g_ActiveAttrList.value[10] =	TargetRune_List1CoinAItem10_Text2
	g_ActiveAttrList.value[11] =	TargetRune_List1CoinAItem11_Text2
	g_ActiveAttrList.value[12] =	TargetRune_List1CoinAItem12_Text2

	g_tab_JiBanAttrInfo = {
		{uiBk = TargetRune_List2CoinAItem,uiName = TargetRune_List2CoinAItem_Text, uiNum = TargetRune_List2CoinAItem_Text2},
		{uiBk = TargetRune_List2CoinAItem2,uiName = TargetRune_List2CoinAItem2_Text, uiNum = TargetRune_List2CoinAItem2_Text2},
		{uiBk = TargetRune_List2CoinAItem3,uiName = TargetRune_List2CoinAItem3_Text, uiNum = TargetRune_List2CoinAItem3_Text2},
		{uiBk = TargetRune_List2CoinAItem4,uiName = TargetRune_List2CoinAItem4_Text, uiNum = TargetRune_List2CoinAItem4_Text2},
		{uiBk = TargetRune_List2CoinAItem5,uiName = TargetRune_List2CoinAItem5_Text, uiNum = TargetRune_List2CoinAItem5_Text2},
		{uiBk = TargetRune_List2CoinAItem6,uiName = TargetRune_List2CoinAItem6_Text, uiNum = TargetRune_List2CoinAItem6_Text2},
		{uiBk = TargetRune_List2CoinAItem7,uiName = TargetRune_List2CoinAItem7_Text, uiNum = TargetRune_List2CoinAItem7_Text2},
		{uiBk = TargetRune_List2CoinAItem8,uiName = TargetRune_List2CoinAItem8_Text, uiNum = TargetRune_List2CoinAItem8_Text2},
		{uiBk = TargetRune_List2CoinAItem9,uiName = TargetRune_List2CoinAItem9_Text, uiNum = TargetRune_List2CoinAItem9_Text2},
		{uiBk = TargetRune_List2CoinAItem10,uiName = TargetRune_List2CoinAItem10_Text, uiNum = TargetRune_List2CoinAItem10_Text2},
		{uiBk = TargetRune_List2CoinAItem11,uiName = TargetRune_List2CoinAItem11_Text, uiNum = TargetRune_List2CoinAItem11_Text2},
	}
	
end

function TargetRune_OnEvent(event)

	if event == "OPEN_OTHER_XINGZHEN" then
		
		if not CachedTarget:IsPresent(1) then
			return
		end
		
		if not CachedTarget:CanGetTargetEquip() then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		
		g_objCared = CachedTarget:GetData("NPCID", 1)
		if type(g_objCared) ~= "number" then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		
		this:Show()
		TargetRune_Update()
		TargetRune_UpdateJiBanAttrList()
		this:CareObject(g_objCared , 1)
		
	end
	
	if event == "OTHER_XINGZHEN_UPDATE" then
		g_CurActiveAttrPage = 1
		TargetRune_Update()
		return
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		TargetRune_On_ResetPos()
	end	

end

--刷新
function TargetRune_Update()
	
	local nLevel = CachedTarget:GetData("LEVEL",1)
	
	local g_SlotActiveCount = 0
	local g_LowestSlotOrder = g_MaxOrder
	for i = 1, 4 do

		g_ActivedButton.btn[i]:SetActionItem(-1)
		g_ActivedButton.btn[i]:SetToolTip("")
		g_ActivedButton.btn[i]:SetProperty("DraggingEnabled","False")
		g_ActivedButton.rank[i]:Hide()
		
		g_SkillAction.btn[i]:SetActionItem(-1)
		g_SkillAction.btn[i]:SetToolTip("")		
		g_SkillAction.btn[i]:SetProperty("DraggingEnabled","False")		
		g_SkillAction.lv_bk[i]:Hide()	
		
			local nXingJuanID = CachedTarget:LuaFnGetActivedXingJuanID(i)
			
			if nXingJuanID > 0 then
			
				local theAction = EnumAction(nXingJuanID,"otherxingjuan")
				if theAction:GetID() ~= 0 then
					g_ActivedButton.btn[i]:SetActionItem(theAction:GetID())
					g_ActivedButton.btn[i]:SetProperty("DraggingEnabled","True")
				end
				
				local nLevel = CachedTarget:LuaFnGetXingJuanInfo(nXingJuanID, "Level")
				
				local nOrder = CachedTarget:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
			if nOrder > 0 then
				g_ActivedButton.rank[i]:Show()
				g_ActivedButton.rank[i]:SetProperty("Image",g_XingJuanOrderImg[nOrder])
			else
				g_ActivedButton.rank[i]:Hide()
				end
				
				g_SlotActiveCount = g_SlotActiveCount + 1
				if nOrder < g_LowestSlotOrder then
					g_LowestSlotOrder = nOrder
				end
				
				local nCardID = CachedTarget:LuaFnGetActivedSkillCardID(i)
				if nCardID > 0 then
					
				g_SkillAction.lv_bk[i]:Show()				
					local nCardLevel = CachedTarget:LuaFnGetSkillCardInfo(nCardID, "Level")
					g_SkillAction.lv_text[i]:SetText(tostring(nCardLevel))
					
					local cardAction = EnumAction(nCardID,"otherskillcard")
					if cardAction:GetID() ~= 0 then
						g_SkillAction.btn[i]:SetActionItem(cardAction:GetID())
						g_SkillAction.btn[i]:SetProperty("DraggingEnabled","True")	
					end
				end	
			end			
	
	end
	
	TargetRune_UpdateSlotAttrList(g_SlotActiveCount, g_LowestSlotOrder)
	
	TargetRune_UpdateActiveAttrList()
end

function TargetRune_UpdateSlotAttrList(nSlotActiveCount, nLowLevel)

	for i = 1, g_AttrNumOfSlotPage do
		g_SlotAttrList.bk[i]:Hide()	
	end
	
	local count = DataPool:LuaFnGetOtherXingZhenSlotAttrListCount()
	
	if count > g_AttrNumOfSlotPage then
		count = g_AttrNumOfSlotPage
	end
	
	for i = 1, count do
		
		local strAttr, attr_value, attr_add, attr_type, attrValue = DataPool:LuaFnGetOtherXingZhenSlotAttr(i - 1, 0, 0)
		if strAttr ~= "" then
			
			g_SlotAttrList.bk[i]:Show()
			g_SlotAttrList.str[i]:SetText("#L"..strAttr)
			g_SlotAttrList.value[i]:SetText("#L+"..attr_value)

			if attr_type == 37 then
				g_SlotAttrList.value[i]:SetToolTip("#{XZJC_200309_237}")
			elseif attr_type == 47 then
				g_SlotAttrList.value[i]:SetToolTip("#{XZJC_200309_238}")
			else
				g_SlotAttrList.value[i]:SetToolTip("#{XZJC_200309_21}")
			end
		end
	end

end

function TargetRune_UpdateActiveAttrList()
	
	for i = 1, g_AttrNumOfActivePage do
		g_ActiveAttrList.bk[i]:Hide()	
	end
	
	local count = DataPool:LuaFnGetOtherXingZhenAttrListCount()
	
	local pagenum = math.floor(count / g_AttrNumOfActivePage)
	if math.mod(count, g_AttrNumOfActivePage) ~= 0 then
		pagenum = pagenum + 1
	end

	g_MaxActiveAttrPage = pagenum
	
	if g_CurActiveAttrPage > g_MaxActiveAttrPage or g_CurActiveAttrPage < 1 then
		g_CurActiveAttrPage = 1
	end
	
	local start_index = g_AttrNumOfActivePage * (g_CurActiveAttrPage - 1) + 1
	local valid_index = 1
	
		TargetRune_List1LaceUpBtn:Disable()
	TargetRune_List1LaceDownBtn:Disable()
	
	if g_CurActiveAttrPage > 1 then
		TargetRune_List1LaceUpBtn:Enable()
	end
	
	if g_CurActiveAttrPage < g_MaxActiveAttrPage then
		TargetRune_List1LaceDownBtn:Enable()
	end
	
	for i = 1, count do
		
		if valid_index > g_AttrNumOfActivePage or start_index > count then
			break
		end		
		
		local strAttr, attr_value, attr_type, attrValue = DataPool:LuaFnGetOtherXingZhenAttr(start_index - 1)
		if strAttr ~= "" then
			
			g_ActiveAttrList.bk[valid_index]:Show()
			g_ActiveAttrList.str[valid_index]:SetText("#L"..strAttr)
			g_ActiveAttrList.value[valid_index]:SetText("#L+"..attr_value)			
			valid_index = valid_index + 1
			start_index = start_index + 1
		end
	end
end

function TargetRune_UpdateJiBanAttrList()
	local tabInfo = {}
	tabInfo[1],tabInfo[2],tabInfo[3],tabInfo[4],tabInfo[5],tabInfo[6],tabInfo[7],tabInfo[8],tabInfo[9],tabInfo[10],tabInfo[11],tabInfo[12],tabInfo[13],tabInfo[14],tabInfo[15],tabInfo[16],tabInfo[17],tabInfo[18],tabInfo[19],tabInfo[20],tabInfo[21],tabInfo[22] = CachedTarget:LuaFnGetXingZhen_JiBanTotalAttr()
	local nIndex = 0
	for i=1,table.getn(g_tab_JiBanAttrInfo) do 
		local szAttrName = tabInfo[2*i-1]
		local nAttrValue = tabInfo[2*i]
		if nAttrValue > 0 then 
			nIndex = nIndex + 1
			g_tab_JiBanAttrInfo[nIndex].uiBk:Show()
			g_tab_JiBanAttrInfo[nIndex].uiName:SetText( ScriptGlobal_Format("#{XZYX_200309_379}", "#{"..szAttrName.."}") )
			g_tab_JiBanAttrInfo[nIndex].uiNum:SetText( ScriptGlobal_Format("#{XZYX_200309_380}", tabInfo[2*i]) )
		end
	end
	for i=nIndex+1,table.getn(g_tab_JiBanAttrInfo) do 
		g_tab_JiBanAttrInfo[i].uiBk:Hide()
	end
end

function TargetRune_OnCloseClicked()
	this:Hide()
end

function TargetRune_OnHidden()

	for i = 1, 4 do
		g_ActivedButton.btn[i]:SetActionItem(-1)
		g_SkillAction.btn[i]:SetActionItem(-1)
	end
end

function TargetRune_Elements_MouseLeave(nIndex)
	
end

function TargetRune_Elements_MouseEnter(nIndex)

end

function TargetRune_On_ResetPos()
	if g_TargetRune_Frame_UnifiedPosition ~= nil then
		TargetRune_Frame:SetProperty("UnifiedPosition", g_TargetRune_Frame_UnifiedPosition)
	end
end

function TargetRune_ActiveAttrPageUp()
	
	if g_CurActiveAttrPage <= 1 then
		return
	end
	
	g_CurActiveAttrPage = g_CurActiveAttrPage - 1 
	
	TargetRune_UpdateActiveAttrList()
	
end

function TargetRune_ActiveAttrPageDown()
	
	if g_CurActiveAttrPage >= g_MaxActiveAttrPage then
		return
	end
	
	g_CurActiveAttrPage = g_CurActiveAttrPage + 1
	
	TargetRune_UpdateActiveAttrList()

end

function TargetRune_ShowSlotTip(flag)
--	LuaFnShowXingZhenSlotTip(flag, 1)
end

--!!!reloadscript =TargetRune
