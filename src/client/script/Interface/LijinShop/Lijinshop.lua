
local ObjCaredId = -1	--关注NPC ObjID
local TargetObjId = -1

local LAST_TAG = 1
local LAST_SHOP = 1
local lastA = 0			--一级目录最后点击的tag
local lastB = 0			--二级目录最后点击的shop

local SHOP_LIST_A = {}
local SHOP_LIST_B = {}

local GOODS_BUTTONS_NUM = 18
local GOODS_BUTTONS = {}
local GOODS_DESCS = {}
local GOOD_BAD = {}

local g_nTotalNum = 0	--当前商店的商品数量
local g_tOrderPool = {}	--存储随机排序的索引值
local maxPage = 1
local nPageNum = 1

local g_LijinShop_Frame_UnifiedPosition

function LijinShop_PreLoad()
--	this:RegisterEvent("UI_COMMAND")
--	this:RegisterEvent("ADJEST_UI_POS",false)
--	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
--	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
--	this:RegisterEvent("OPEN_LIJINSHOP")
--	this:RegisterEvent("UPDATE_LIJIN")
--	this:RegisterEvent("GAMELOGIN_OPEN_SELECT_CHARACTOR")
end

function LijinShop_OnLoad()
	--礼金大卖场
--	SHOP_LIST_A[1] = {btn = LijinShop_LijinHallShop, shopname="#{LJSD_120508_09}", tooltips="#{YBSD_081225_083}", shoplist={}}
--	SHOP_LIST_A[1].shoplist[1] = "#{LJSD_120508_10}"	--"新品上架"
--	SHOP_LIST_A[1].shoplist[8] = "#{LJSD_120508_11}"	--"最近购买"
	
	--礼金宝石店
--	SHOP_LIST_A[2] = {btn = LijinShop_LijinBaoShiShop, shopname="#{LJSD_120508_12}", tooltips="#{YBSD_081225_084}", shoplist={}}
--	SHOP_LIST_A[2].shoplist[1] = "#{LJSD_120508_13}"	--"礼金宝石斋"
--	SHOP_LIST_A[2].shoplist[2] = "#{LJSD_120508_14}"	--"宝石加工坊"
	
	--礼金珍兽店
--	SHOP_LIST_A[3] = {btn = LijinShop_LijinPetShop, shopname="#{LJSD_120508_19}", tooltips="#{YBSD_081225_085}", shoplist={}}
--	SHOP_LIST_A[3].shoplist[1] = "#{LJSD_120508_20}"	--"珍兽百宝箱"
	
	--礼金奇货店
--	SHOP_LIST_A[4] = {btn = LijinShop_LijinQiHuoShop, shopname="#{LJSD_120508_15}", tooltips="#{YBSD_081225_086}", shoplist={}}
--	SHOP_LIST_A[4].shoplist[1] = "#{LJSD_120508_16}"	--"仙丹灵药"
--	SHOP_LIST_A[4].shoplist[2] = "#{LJSD_120508_17}"	--"奇珍异宝"
--	SHOP_LIST_A[4].shoplist[3] = "#{YBSD_XML_8}"	    --"防具雕纹店"
--	SHOP_LIST_A[4].shoplist[4] = "#{YBSD_XML_9}"	    --"武具雕纹店"
--	SHOP_LIST_A[4].shoplist[5] = "#{YBSD_XML_10}"	    --"雕纹加工坊"
	
--	SHOP_LIST_A[5] = {btn = LijinShop_LijinShop1, shopname="", tooltips="", shoplist={}}
--	SHOP_LIST_A[6] = {btn = LijinShop_LijinShop2, shopname="", tooltips="", shoplist={}}
--	SHOP_LIST_A[7] = {btn = LijinShop_LijinShop3, shopname="", tooltips="", shoplist={}}
--	SHOP_LIST_A[8] = {btn = LijinShop_LijinShop4, shopname="", tooltips="", shoplist={}}
	
	--二级商店
--	SHOP_LIST_B[1] = LijinShop_Button01
--	SHOP_LIST_B[2] = LijinShop_Button02
--	SHOP_LIST_B[3] = LijinShop_Button03
--	SHOP_LIST_B[4] = LijinShop_Button04
--	SHOP_LIST_B[5] = LijinShop_Button05
--	SHOP_LIST_B[6] = LijinShop_Button06
--	SHOP_LIST_B[7] = LijinShop_Button07
--	SHOP_LIST_B[8] = LijinShop_Button08
	
	
	--商品按钮
--	GOODS_BUTTONS[1] = LijinShop_Item1
--	GOODS_BUTTONS[2] = LijinShop_Item2
--	GOODS_BUTTONS[3] = LijinShop_Item3
--	GOODS_BUTTONS[4] = LijinShop_Item4
--	GOODS_BUTTONS[5] = LijinShop_Item5
--	GOODS_BUTTONS[6] = LijinShop_Item6
--	GOODS_BUTTONS[7] = LijinShop_Item7
--	GOODS_BUTTONS[8] = LijinShop_Item8
--	GOODS_BUTTONS[9] = LijinShop_Item9
--	GOODS_BUTTONS[10] = LijinShop_Item10
--	GOODS_BUTTONS[11] = LijinShop_Item11
--	GOODS_BUTTONS[12] = LijinShop_Item12
--	GOODS_BUTTONS[13] = LijinShop_Item13
--	GOODS_BUTTONS[14] = LijinShop_Item14
--	GOODS_BUTTONS[15] = LijinShop_Item15
--	GOODS_BUTTONS[16] = LijinShop_Item16
--	GOODS_BUTTONS[17] = LijinShop_Item17
--	GOODS_BUTTONS[18] = LijinShop_Item18
	
	--商品名字
--	GOODS_DESCS[1] = LijinShop_ItemInfo1_Text
--	GOODS_DESCS[2] = LijinShop_ItemInfo2_Text
--	GOODS_DESCS[3] = LijinShop_ItemInfo3_Text
--	GOODS_DESCS[4] = LijinShop_ItemInfo4_Text
--	GOODS_DESCS[5] = LijinShop_ItemInfo5_Text
--	GOODS_DESCS[6] = LijinShop_ItemInfo6_Text
--	GOODS_DESCS[7] = LijinShop_ItemInfo7_Text
--	GOODS_DESCS[8] = LijinShop_ItemInfo8_Text
--	GOODS_DESCS[9] = LijinShop_ItemInfo9_Text
--	GOODS_DESCS[10] = LijinShop_ItemInfo10_Text
--	GOODS_DESCS[11] = LijinShop_ItemInfo11_Text
--	GOODS_DESCS[12] = LijinShop_ItemInfo12_Text
--	GOODS_DESCS[13] = LijinShop_ItemInfo13_Text
--	GOODS_DESCS[14] = LijinShop_ItemInfo14_Text
--	GOODS_DESCS[15] = LijinShop_ItemInfo15_Text
--	GOODS_DESCS[16] = LijinShop_ItemInfo16_Text
--	GOODS_DESCS[17] = LijinShop_ItemInfo17_Text
--	GOODS_DESCS[18] = LijinShop_ItemInfo18_Text
	
	--商品价格
--	GOOD_BAD[1] = LijinShop_ItemInfo1_GB
--	GOOD_BAD[2] = LijinShop_ItemInfo2_GB
--	GOOD_BAD[3] = LijinShop_ItemInfo3_GB
--	GOOD_BAD[4] = LijinShop_ItemInfo4_GB
--	GOOD_BAD[5] = LijinShop_ItemInfo5_GB
--	GOOD_BAD[6] = LijinShop_ItemInfo6_GB
--	GOOD_BAD[7] = LijinShop_ItemInfo7_GB
--	GOOD_BAD[8] = LijinShop_ItemInfo8_GB
--	GOOD_BAD[9] = LijinShop_ItemInfo9_GB
--	GOOD_BAD[10] = LijinShop_ItemInfo10_GB
--	GOOD_BAD[11] = LijinShop_ItemInfo11_GB
--	GOOD_BAD[12] = LijinShop_ItemInfo12_GB
--	GOOD_BAD[13] = LijinShop_ItemInfo13_GB
--	GOOD_BAD[14] = LijinShop_ItemInfo14_GB
--	GOOD_BAD[15] = LijinShop_ItemInfo15_GB
--	GOOD_BAD[16] = LijinShop_ItemInfo16_GB
--	GOOD_BAD[17] = LijinShop_ItemInfo17_GB
--	GOOD_BAD[18] = LijinShop_ItemInfo18_GB
	
--	if lastA ~= nil and lastA > 0 and lastA <= table.getn(SHOP_LIST_A) then
--		SHOP_LIST_A[lastA].btn:SetCheck(1)
--	end
	
--	if lastB ~= nil and lastB > 0 and lastB <= table.getn(SHOP_LIST_B) then
--		SHOP_LIST_B[lastB].btn:SetCheck(1)
--	end
	
--	for i = 1, table.getn(SHOP_LIST_B) do
--		SHOP_LIST_B[i]:Hide()
--	end
	
	--显示一级目录，不会变的东东
--	for i = 1, table.getn(SHOP_LIST_A) do
--		if table.getn(SHOP_LIST_A[i].shoplist) > 0 then
--			SHOP_LIST_A[i].btn:SetText(SHOP_LIST_A[i].shopname)
--			SHOP_LIST_A[i].btn:SetToolTip(SHOP_LIST_A[i].tooltips)
--			SHOP_LIST_A[i].btn:Show()
--		else
--			SHOP_LIST_A[i].btn:Hide()
--		end
--	end
	
--	g_LijinShop_Frame_UnifiedPosition = LijinShop_Frame:GetProperty("UnifiedPosition")
end

function LijinShop_OnEvent(event)
--	if (event == "HIDE_ON_SCENE_TRANSED" and this:IsVisible()) then
--	    ObjCaredId = -1
--	    this:Hide()
       -- LijinShop_Close()
--	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20120508) then
--		TargetObjId = Get_XParam_INT(0)
--		LijinShop_Show()
	
--	elseif (event == "OPEN_LIJINSHOP") then
--		g_nTotalNum = 0
		
--		local bConfirm = tonumber(NpcShop:GetLiJinBuyDirectly())
--		if bConfirm >= 1 then
--			LijinShop_querengoumai:SetCheck(0)
--		else
--			LijinShop_querengoumai:SetCheck(1)
--		end
		
--		if this:IsVisible() == false then
--			this:Show();
			
--			OpenWindow("Packet")
			-- 在先打开NPC商店，后打开元宝商店的时候，存在一个问题
			-- 元宝商店在打开时会关闭已经打开的NPC商店，而关闭这个操作会将是否打开商店这个状态只为假，从而导致购买相关的逻辑出现错误
			-- 目前的解决办法是在Show的地方，设置是否打开商店的状态为真。
--			OpenBooth()
--		end
		
		--关心商人Obj
		--if ObjCaredId == -1 then
--			ObjCaredId = NpcShop:GetNpcId()
		--end
--		this:CareObject(ObjCaredId, 1, "LijinShop")
		
  --      NpcShop:CloseConfirm()

--		LijinShop_UpdatePage(1)
	
--	elseif (event == "UPDATE_LIJIN" and this:IsVisible()) then
--		LijinShop_HaveLijin_Text:SetText("#{LJSD_120508_08}"..tostring(Player:GetData("LIJIN")))
	
--	elseif (event == "ADJEST_UI_POS") then
--		LijinShop_ResetPos()
	
--	elseif (event == "VIEW_RESOLUTION_CHANGED") then
--		LijinShop_ResetPos()
	
--	elseif (event == "GAMELOGIN_OPEN_SELECT_CHARACTOR") then
--		LAST_TAG = 1
--		LAST_SHOP = 1
--		lastA = 0
--		lastB = 0
	
--	end
end

--显示礼金商店
function LijinShop_Show()
	if lastA < 1 or lastA > table.getn(SHOP_LIST_A) then
		lastA = LAST_TAG
		lastB = LAST_SHOP
	end
	
	if lastB < 1 or lastB > table.getn(SHOP_LIST_B) then
		lastB = LAST_SHOP
	end
	
	--显示上次打开的商店
	if table.getn(SHOP_LIST_A[lastA].shoplist) > 0 then
		SHOP_LIST_A[lastA].btn:SetCheck(1)
		for i = 1, table.getn(SHOP_LIST_B) do
			SHOP_LIST_B[i]:Hide()
			if SHOP_LIST_A[lastA].shoplist[i] ~= nil then
				SHOP_LIST_B[i]:SetText(SHOP_LIST_A[lastA].shoplist[i])
				SHOP_LIST_B[i]:Show()
				if lastB == i then
					SHOP_LIST_B[i]:SetCheck(1)
					LijinShop_UpdateItem(lastA, lastB)
				end
			end
		end
	end
end

--点击一级目录
function LijinShop_UpdateList(nIndex)
	if nIndex < 1 or nIndex > table.getn(SHOP_LIST_A) or lastA == nIndex then
		return
	end
	
	SHOP_LIST_A[nIndex].btn:SetCheck(1)
	
	LAST_TAG = nIndex
	lastA = nIndex
	lastB = 0
	
	for i = 1, table.getn(SHOP_LIST_B) do
		SHOP_LIST_B[i]:Hide()
		if SHOP_LIST_A[lastA].shoplist[i] ~= nil then
			SHOP_LIST_B[i]:SetText(SHOP_LIST_A[lastA].shoplist[i])
			SHOP_LIST_B[i]:Show()
		end
	end
	
	LijinShop_UpdateShop(1)
end

--点击二级目录
function LijinShop_UpdateShop(nIndex)
	if nIndex < 1 or nIndex > table.getn(SHOP_LIST_B) or lastB == nIndex then
		return
	end
	
	SHOP_LIST_B[nIndex]:SetCheck(1)
	
	LAST_SHOP = nIndex
	lastB = nIndex
	
	if lastA > 0 and lastA <= table.getn(SHOP_LIST_A) then
		LijinShop_UpdateItem(lastA, lastB)
	else
		LijinShop_UpdateItem(1, 1)
	end
end

--请求商品信息
function LijinShop_UpdateItem(shopA, shopB)
	if shopA == 1 and shopB == 8 then
		OpenRecentBuyLiJinShop()
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenLijinShop")
		Set_XSCRIPT_ScriptID(889854)
		Set_XSCRIPT_Parameter(0, TargetObjId)
		Set_XSCRIPT_Parameter(1, shopA)
		Set_XSCRIPT_Parameter(2, shopB)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--随机排序
function LijinShop_Order()
	local max = g_nTotalNum
	local oldt = {}
	g_tOrderPool = {}
	
	for i = 1, tonumber(max) do
		oldt[i] = i - 1
	end
	
	if tonumber(NpcShop:GetIsShopReorder()) == 0 then
		g_tOrderPool = oldt
	else
		for i = 1, table.getn(oldt) do
			local idx = math.random(1, table.getn(oldt))
			local val = oldt[idx]
			g_tOrderPool[i] = val
			table.remove(oldt, idx)
		end
	end
end

--刷新页
function LijinShop_UpdatePage(thePage)
	LijinShop_HaveLijin_Text:SetText("#{LJSD_120508_08}"..tostring(Player:GetData("LIJIN")))
	
	for i = 1, GOODS_BUTTONS_NUM do
		GOOD_BAD[i]:Show()
	end
	
	if g_nTotalNum == 0 or g_nTotalNum ~= GetActionNum("boothitem") then
		g_nTotalNum	= GetActionNum("boothitem")
		LijinShop_Order()
	end
	
	--计算总页数
	local nTotalPage = 1
	if g_nTotalNum < 1 then
		nTotalPage = 1
	else
		nTotalPage = math.floor((g_nTotalNum - 1) / GOODS_BUTTONS_NUM) + 1
	end
	
	maxPage = nTotalPage
	
	if thePage < 1 or thePage > nTotalPage then
		return
	end
	
	nPageNum = thePage
	
	local nStartIndex = (thePage - 1) * GOODS_BUTTONS_NUM
	local nActIndex = nStartIndex
	local i = 1
	while i <= GOODS_BUTTONS_NUM do
		local idx = g_tOrderPool[nActIndex + 1]
		if idx == nil then
			idx = -1
		end
		
		local theAction = EnumAction(idx, "boothitem")
		if theAction:GetID() ~= 0 then
			GOODS_BUTTONS[i]:SetActionItem(theAction:GetID())
			if theAction:GetItemColorInShop() ~= "" then
				GOODS_DESCS[i]:SetText(theAction:GetItemColorInShop()..theAction:GetName())
			else
				GOODS_DESCS[i]:SetText(theAction:GetName())
			end
			
			local nPrice = NpcShop:EnumItemPrice(idx)
			GOOD_BAD[i]:SetText("#{LJSD_120508_38}"..tostring(nPrice))
		else
			GOODS_BUTTONS[i]:SetActionItem(-1)
			GOODS_DESCS[i]:SetText("")
			GOOD_BAD[i]:SetText("")
		end
		
		i = i + 1
		nActIndex = nActIndex + 1
	end
	
	if nTotalPage == 1 then
		LijinShop_UpPage:Hide()
		LijinShop_DownPage:Hide()
		LijinShop_CurrentlyPage:Hide()
	else
		LijinShop_UpPage:Show()
		LijinShop_DownPage:Show()
		LijinShop_CurrentlyPage:Show()
		
		LijinShop_UpPage:Enable()
		LijinShop_DownPage:Enable()
		
		if nPageNum == nTotalPage then
			LijinShop_DownPage:Disable()
		end
		
		if nPageNum == 1 then
			LijinShop_UpPage:Disable()
		end
		
		LijinShop_CurrentlyPage:SetText(tostring(nPageNum).."/"..tostring(nTotalPage))
	end
end

--PageUp
function LijinShop_PageUp()
	local curPage = nPageNum - 1
	if curPage < 0 then
		curPage = 0
	end
    NpcShop:CloseConfirm()
	LijinShop_UpdatePage(curPage)
end

--PageDown
function LijinShop_PageDown()
	local curPage = nPageNum + 1
	if curPage >= maxPage then
		curPage = maxPage
	end
    NpcShop:CloseConfirm()
	LijinShop_UpdatePage(curPage)
end

--Button Clicked
function LijinShop_GoodButton_Clicked(nIndex)
	if nIndex < 1 or nIndex > GOODS_BUTTONS_NUM then
		return
	end
	GOODS_BUTTONS[nIndex]:DoAction()
end

--确认购买按钮
function LijinShop_querengoumai_Clicked()
	if tonumber(NpcShop:GetLiJinBuyDirectly()) == 0 then
		NpcShop:SetLiJinBuyDirectly(1)
	else
		NpcShop:SetLiJinBuyDirectly(0)
	end
end

function LijinShop_Close()
    NpcShop:CloseConfirm()
	ObjCaredId = -1
	this:CareObject(objCared, 0, "LijinShop")
	this:Hide()
end

function LijinShop_ResetPos()
	LijinShop_Frame:SetProperty("UnifiedPosition", g_LijinShop_Frame_UnifiedPosition)
end
