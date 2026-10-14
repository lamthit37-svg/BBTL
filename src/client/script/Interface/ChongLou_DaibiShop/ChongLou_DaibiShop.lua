

--
--重楼商店购买
--
--选择目录
local g_CurShop_Level  --当前商店等级
local g_CurShopID_btns --商店等级按钮
--一页最大显示数量
local GOODS_BUTTONS_NUM = 15
--最大页数
local g_MaxPage = 1
--当前页数
local g_CurPage = 1
--当前商店信息list表
local g_Cur_ShopList  =
{
	-- [idx] key
	-- id,          item_id,	name,	 show_id,   time_type,	count,		now, 		      price, 	 moneytype,  				gpcount
	-- 表中ID（1）   道具id      道具名称  道具展示id  限时类型    限购数量,    当前以买限购的数量  商品价格   货币类型(1高级 2低级)	    商品数量
}

local g_PriceFormat = {
	--高级代币商店
    [1] = {ItemID =38005313,price="#{CLDHDB_210510_15}",show="#{CLDHDB_210510_17}"},--玲珑华璧：%s0  --拥有玲珑华璧：%s0
    [2] = {ItemID =38005312,price="#{CLDHDB_210510_16}",show="#{CLDHDB_210510_18}"},--玲珑白玉：%s0  --拥有玲珑白玉：%s0
}

local g_ChongLou_DaibiShop_Frame_UnifiedPosition
local g_CurShopIndex = 1
local g_objCared = -1
local g_objID = -1

--物品展示控件
local GOODS_BUTTONS = {}
--物品名字控件
local GOODS_DESCS = {}
--物品价格控件
local GOODS_PRICE = {}
local GOODS_NUMBK = {}
local GOODS_NUM = {}

--NPC最大距离
local MAX_OBJ_DISTANCE = 3.0


function ChongLou_DaibiShop_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UPDATE_CL_SHOP")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	--this:RegisterEvent("PACKAGE_ITEM_CHANGED",false)--??

end

function ChongLou_DaibiShop_OnLoad()

	g_ChongLou_DaibiShop_Frame_UnifiedPosition = ChongLou_DaibiShop_Frame:GetProperty("UnifiedPosition")

	--高级商店按钮 低级商店按钮
	g_CurShopID_btns = {
		[1] = ChongLou_DaibiShop_FenYe_CardFragment, --高级
		[2] = ChongLou_DaibiShop_FenYe_Skill, --低级
	}

	--物品展示
	GOODS_BUTTONS[1]	= ChongLou_DaibiShop_Item1
	GOODS_BUTTONS[2]	= ChongLou_DaibiShop_Item2
	GOODS_BUTTONS[3]	= ChongLou_DaibiShop_Item3
	GOODS_BUTTONS[4]	= ChongLou_DaibiShop_Item4
	GOODS_BUTTONS[5]	= ChongLou_DaibiShop_Item5
	GOODS_BUTTONS[6]	= ChongLou_DaibiShop_Item6
	GOODS_BUTTONS[7]	= ChongLou_DaibiShop_Item7
	GOODS_BUTTONS[8]	= ChongLou_DaibiShop_Item8
	GOODS_BUTTONS[9]	= ChongLou_DaibiShop_Item9
	GOODS_BUTTONS[10]	= ChongLou_DaibiShop_Item10
	GOODS_BUTTONS[11]	= ChongLou_DaibiShop_Item11
	GOODS_BUTTONS[12]	= ChongLou_DaibiShop_Item12
	GOODS_BUTTONS[13]	= ChongLou_DaibiShop_Item13
	GOODS_BUTTONS[14]	= ChongLou_DaibiShop_Item14
	GOODS_BUTTONS[15]	= ChongLou_DaibiShop_Item15

	--物品名字
	GOODS_DESCS[1] 	= ChongLou_DaibiShop_ItemInfo1_Name
	GOODS_DESCS[2]	= ChongLou_DaibiShop_ItemInfo2_Name
	GOODS_DESCS[3]	= ChongLou_DaibiShop_ItemInfo3_Name
	GOODS_DESCS[4] 	= ChongLou_DaibiShop_ItemInfo4_Name
	GOODS_DESCS[5]	= ChongLou_DaibiShop_ItemInfo5_Name
	GOODS_DESCS[6]	= ChongLou_DaibiShop_ItemInfo6_Name
	GOODS_DESCS[7]	= ChongLou_DaibiShop_ItemInfo7_Name
	GOODS_DESCS[8]	= ChongLou_DaibiShop_ItemInfo8_Name
	GOODS_DESCS[9]	= ChongLou_DaibiShop_ItemInfo9_Name
	GOODS_DESCS[10]	= ChongLou_DaibiShop_ItemInfo10_Name
	GOODS_DESCS[11]	= ChongLou_DaibiShop_ItemInfo11_Name
	GOODS_DESCS[12]	= ChongLou_DaibiShop_ItemInfo12_Name
	GOODS_DESCS[13]	= ChongLou_DaibiShop_ItemInfo13_Name
	GOODS_DESCS[14]	= ChongLou_DaibiShop_ItemInfo14_Name
	GOODS_DESCS[15]	= ChongLou_DaibiShop_ItemInfo15_Name

	--物品价格
	GOODS_PRICE[1]  =     ChongLou_DaibiShop_ItemInfo1_Text
	GOODS_PRICE[2]  =     ChongLou_DaibiShop_ItemInfo2_Text
	GOODS_PRICE[3]  =     ChongLou_DaibiShop_ItemInfo3_Text
	GOODS_PRICE[4]  =     ChongLou_DaibiShop_ItemInfo4_Text
	GOODS_PRICE[5]  =     ChongLou_DaibiShop_ItemInfo5_Text
	GOODS_PRICE[6]  =     ChongLou_DaibiShop_ItemInfo6_Text
	GOODS_PRICE[7]  =     ChongLou_DaibiShop_ItemInfo7_Text
	GOODS_PRICE[8]  =     ChongLou_DaibiShop_ItemInfo8_Text
	GOODS_PRICE[9]  =     ChongLou_DaibiShop_ItemInfo9_Text
	GOODS_PRICE[10] =     ChongLou_DaibiShop_ItemInfo10_Text
	GOODS_PRICE[11] =     ChongLou_DaibiShop_ItemInfo11_Text
	GOODS_PRICE[12] =     ChongLou_DaibiShop_ItemInfo12_Text
	GOODS_PRICE[13]  =     ChongLou_DaibiShop_ItemInfo13_Text
	GOODS_PRICE[14]  =     ChongLou_DaibiShop_ItemInfo14_Text
	GOODS_PRICE[15]  =     ChongLou_DaibiShop_ItemInfo15_Text

	--黑底
	GOODS_NUMBK[1] = ChongLou_DaibiShop_Item1_NumBK
	GOODS_NUMBK[2] = ChongLou_DaibiShop_Item2_NumBK
	GOODS_NUMBK[3] = ChongLou_DaibiShop_Item3_NumBK
	GOODS_NUMBK[4] = ChongLou_DaibiShop_Item4_NumBK
	GOODS_NUMBK[5] = ChongLou_DaibiShop_Item5_NumBK
	GOODS_NUMBK[6] = ChongLou_DaibiShop_Item6_NumBK
	GOODS_NUMBK[7] = ChongLou_DaibiShop_Item7_NumBK
	GOODS_NUMBK[8] = ChongLou_DaibiShop_Item8_NumBK
	GOODS_NUMBK[9] = ChongLou_DaibiShop_Item9_NumBK
	GOODS_NUMBK[10] = ChongLou_DaibiShop_Item10_NumBK
	GOODS_NUMBK[11] = ChongLou_DaibiShop_Item11_NumBK
	GOODS_NUMBK[12] = ChongLou_DaibiShop_Item12_NumBK
	GOODS_NUMBK[13] = ChongLou_DaibiShop_Item13_NumBK
	GOODS_NUMBK[14] = ChongLou_DaibiShop_Item14_NumBK
	GOODS_NUMBK[15] = ChongLou_DaibiShop_Item15_NumBK

	--数字
	GOODS_NUM[1] = ChongLou_DaibiShop_Item1_Num
	GOODS_NUM[2] = ChongLou_DaibiShop_Item2_Num
	GOODS_NUM[3] = ChongLou_DaibiShop_Item3_Num
	GOODS_NUM[4] = ChongLou_DaibiShop_Item4_Num
	GOODS_NUM[5] = ChongLou_DaibiShop_Item5_Num
	GOODS_NUM[6] = ChongLou_DaibiShop_Item6_Num
	GOODS_NUM[7] = ChongLou_DaibiShop_Item7_Num
	GOODS_NUM[8] = ChongLou_DaibiShop_Item8_Num
	GOODS_NUM[9] = ChongLou_DaibiShop_Item9_Num
	GOODS_NUM[10] = ChongLou_DaibiShop_Item10_Num
	GOODS_NUM[11] = ChongLou_DaibiShop_Item11_Num
	GOODS_NUM[12] = ChongLou_DaibiShop_Item12_Num
	GOODS_NUM[13] = ChongLou_DaibiShop_Item13_Num
	GOODS_NUM[14] = ChongLou_DaibiShop_Item14_Num
	GOODS_NUM[15] = ChongLou_DaibiShop_Item15_Num
	
end

--清空
local function clean()
    g_CurShop_Level = nil
	g_Cur_ShopList  = {}
	g_CurPage = 1
	g_objID = -1

	for i = 1, GOODS_BUTTONS_NUM do
		GOODS_BUTTONS[i]:SetActionItem(-1)
	end
end

--物品显示
local function cur_show()

	local g_nTotalNum = table.getn(g_Cur_ShopList )--取得这一类表中物品最大数量
	
	--计算总页数
	local nTotalPage
	if g_nTotalNum < 1 then
		nTotalPage	= 1
	else
		--总页数 = （物品最大数量 - 1） / 一页最大显示数量 + 1
		nTotalPage	= math.floor((g_nTotalNum - 1)/GOODS_BUTTONS_NUM) + 1
	end
	g_MaxPage = nTotalPage

	--起始下标位置 = （当前页数-1）* 一页最大显示数量
	local nStartIndex = (g_CurPage - 1) * GOODS_BUTTONS_NUM 

	--显示当前页面
	for i = 1, GOODS_BUTTONS_NUM do
		--当前物品[idx] key为nStartIndex + i
		local item_shop_index = nStartIndex + i

		--若index小于最大数量
		if item_shop_index <= g_nTotalNum then
			--当前物品各种信息
			local item = g_Cur_ShopList [item_shop_index] 

			
			if item.time_type == 0 then
				--不限量
				GOODS_NUM[i]:Hide()
				GOODS_NUMBK[i]:Hide()

				local theAction = DataPool:CreateActionItemForShow(item.item_id, item.gpcount)
				if theAction:GetID() ~= 0 then
					GOODS_BUTTONS[i]:SetActionItem(theAction:GetID()) --设置图标
				end
			else
				--限量
				local countLeft = item.count - item.now --剩余数量
				if countLeft < 0 or countLeft > 200 then
					countLeft = 0
				end

				GOODS_NUM[i]:Show()
				GOODS_NUMBK[i]:Show()
				GOODS_NUM[i]:SetText("" ..countLeft)

				--local theAction = DataPool:CreateActionItemForShowWithMaxNum(item.item_id, item.gpcount, countLeft)
				local theAction = DataPool:CreateActionItemForShow(item.item_id, item.gpcount)
				if theAction:GetID() ~= 0 then
					GOODS_BUTTONS[i]:SetActionItem(theAction:GetID()) --设置图标
				end
				--若已经购尽则标红
				if countLeft == 0 then
					GOODS_BUTTONS[i]:SetProperty("Gloom", "true")
				else
					GOODS_BUTTONS[i]:SetProperty("Gloom", "False")
				end
			end
			--商品名
			GOODS_DESCS[i]:SetText(item.name) 
			--价格
			GOODS_PRICE[i]:SetText(ScriptGlobal_Format(g_PriceFormat[g_CurShop_Level].price,item.price))
		else
			GOODS_BUTTONS[i]:SetActionItem(-1)
			GOODS_DESCS[i]:SetText("")
			GOODS_PRICE[i]:SetText("")
			GOODS_NUM[i]:Hide()
			GOODS_NUMBK[i]:Hide()
		end
	end
	
	--页面信息设置
	local strTemp = ScriptGlobal_Format("#{LDSD_200805_33}", tostring(g_CurPage), tostring(g_MaxPage))	
	ChongLou_DaibiShop_CurrentlyPage:SetText(strTemp)
	
	ChongLou_DaibiShop_UpPage:Enable()
	ChongLou_DaibiShop_DownPage:Enable()
	if g_CurPage == g_MaxPage then
		ChongLou_DaibiShop_DownPage:Disable()
	end

	if g_CurPage == 1 then
		ChongLou_DaibiShop_UpPage:Disable()
	end	

	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 1, "ChongLou_DaibiShop")
	end
	
	this:Show()
	
end

--设置对应等级商店信息
local function select_catalog(which)
	assert(g_CurShop_Level)

	for k, v in pairs(g_CurShopID_btns) do
		v:SetCheck(0)
		v:SetToolTip("")
	end
	g_CurShopID_btns[g_CurShop_Level]:SetCheck(1)--对应商店按钮设置为按下

	g_Cur_ShopList  = DataPool:LuaFnGetChongLouShopByLv(g_CurShop_Level) --拿到对应等级商店中的数据
	assert(type(g_Cur_ShopList ) == "table")

	cur_show()--物品显示
	
end

local function CloseShop()
	clean()

    if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "ChongLou_DaibiShop")
	end
	
	--批量购买界面也关了
	if IsWindowShow("ChongLou_DaibiShop_Mbuy") then
		CloseWindow("ChongLou_DaibiShop_Mbuy", true)
	end

	PushEvent("CHONGLOU_SHOP_CONFIRM", "close")


    g_objCared= -1
    this:Hide()
end

function ChongLou_DaibiShop_OnEvent(event)

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end	

    if event == "UI_COMMAND" then
		if tonumber(arg0) == 88843101 then
			-- Get_XParam_INT(0) --商店等级
			-- Get_XParam_INT(1) --高级代币
			-- Get_XParam_INT(2) --低级代币
			-- Get_XParam_INT(3) --targetId
			-- Get_XParam_STR(0) --字符
            if Get_XParam_STR(0) == "REFRESH_HIGHLOW_SHOW" then --高级代币和低级代币有变动
				if this:IsVisible() then
                    local hightokens = Get_XParam_INT(1)
                    local shightokens = ScriptGlobal_Format("#{CLDHDB_210510_17}",hightokens)--拥有高级代币：%s0	 
                    ChongLou_DaibiShop_Text2:SetText(shightokens)

                    local lowtokens = Get_XParam_INT(2)	
                    local slowtokens = ScriptGlobal_Format("#{CLDHDB_210510_18}",lowtokens)--拥有低级代币：%s0	 
                    ChongLou_DaibiShop_Text1:SetText(slowtokens)
                    
				end
			else

				clean()

				local seleLevel = Get_XParam_INT(0)--商店等级

				g_objID = Get_XParam_INT(3)--objID
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(g_objID))

				if g_objCared == -1 then
					PushDebugMessage("异常数据，请稍后再试！")
					return
				end

				ChongLou_DaibiShop_Select_OpenShop(seleLevel)--选择打开商店的等级 1 2
				

				local hightokens = Get_XParam_INT(1)
				local shightokens = ScriptGlobal_Format("#{CLDHDB_210510_17}",hightokens)--拥有高级代币：%s0	 
				ChongLou_DaibiShop_Text2:SetText(shightokens)

				local lowtokens = Get_XParam_INT(2)	
				local slowtokens = ScriptGlobal_Format("#{CLDHDB_210510_18}",lowtokens)--拥有低级代币：%s0	 
				ChongLou_DaibiShop_Text1:SetText(slowtokens)

				OpenWindow("Packet")

			end

		end
	elseif event == "UPDATE_CL_SHOP" then
        if this:IsVisible() == false then
            return
        end
        assert(g_CurShop_Level)
        ChongLou_DaibiShop_Select_OpenShop()
	
	elseif ( event == "OBJECT_CARED_EVENT" and this:IsVisible() ) then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy") then
			CloseShop()
		end
	--
	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ChongLou_DaibiShop_Frame_On_ResetPos()
	end

end

--回调（XML）
function ChongLou_DaibiShop_OnHidden()
	g_objCared= -1
	clean()

	PushEvent("CHONGLOU_SHOP_CONFIRM", "close")

	--批量购买界面也关了
	if IsWindowShow("ChongLou_DaibiShop_Mbuy") then
		CloseWindow("ChongLou_DaibiShop_Mbuy", true)
	end

end

--关闭界面（XML）
function ChongLou_DaibiShop_CloseClicked()
	CloseShop()
end

--HELP界面（XML）
function ChongLou_DaibiShop_HelpClicked()
	--通用，不写
end

--选择高级还是低级商店 1 高级 2 低级（XML）
function ChongLou_DaibiShop_ChangeShowTab(idx)

	if g_CurShop_Level == idx then
		return
	end

	--二次确认框关闭
	PushEvent("CHONGLOU_SHOP_CONFIRM", "close")
	--批量购买界面也关了
	if IsWindowShow("ChongLou_DaibiShop_Mbuy") then
		CloseWindow("ChongLou_DaibiShop_Mbuy", true)
	end
	
	if idx == 1 or idx == 2 then
		g_CurShop_Level = idx
		g_CurPage = 1
		ChongLou_DaibiShop_Select_OpenShop(g_CurShop_Level)
	end

end

--点击购买 1-15 的商品（XML）
function ChongLou_DaibiShop_GoodButton_Clicked(index)

	local nStartIndex = (g_CurPage - 1) * GOODS_BUTTONS_NUM 
	local item_shop_index = nStartIndex + index

	if g_Cur_ShopList[item_shop_index] == nil then
		return
	end
	
	if CheckBuyMult() == 1 then
		Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888431)
		Set_XSCRIPT_Function_Name("MBuyItem")
		Set_XSCRIPT_Parameter(0, g_Cur_ShopList[item_shop_index].id)--索引
		Set_XSCRIPT_Parameter(1, g_Cur_ShopList[item_shop_index].item_id)--物品ID
		Set_XSCRIPT_Parameter(2, g_CurShop_Level)--商店等级
		Set_XSCRIPT_Parameter(3, g_objID)
		Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	else
		--批量购买界面也关了
		if IsWindowShow("ChongLou_DaibiShop_Mbuy") then
			CloseWindow("ChongLou_DaibiShop_Mbuy", true)
		end

		Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888431)
		Set_XSCRIPT_Function_Name("BuyItem")
		Set_XSCRIPT_Parameter(0, g_Cur_ShopList[item_shop_index].id)--索引
		Set_XSCRIPT_Parameter(1, g_Cur_ShopList[item_shop_index].item_id)--物品ID
		Set_XSCRIPT_Parameter(2, g_CurShop_Level)--商店等级
		Set_XSCRIPT_Parameter(3, g_objID)
		Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end

end

--批量购买（XML）
function ChongLou_DaibiShop_MBuy()
	PushEvent("CHONGLOU_SHOP_CONFIRM", "close")
	PrepearBuyMult()
end

--上一页（XML）
function ChongLou_DaibiShop_PageUp()
	--二次确认框关闭
	PushEvent("CHONGLOU_SHOP_CONFIRM", "close")
	--批量购买界面也关了
	if IsWindowShow("ChongLou_DaibiShop_Mbuy") then
		CloseWindow("ChongLou_DaibiShop_Mbuy", true)
	end

	if g_CurPage <= 1 then
		return
	end
	
	g_CurPage = g_CurPage - 1
	
	cur_show()
end

--下一页（XML）
function ChongLou_DaibiShop_PageDown()
	--二次确认框关闭
	PushEvent("CHONGLOU_SHOP_CONFIRM", "close")
	--批量购买界面也关了
	if IsWindowShow("ChongLou_DaibiShop_Mbuy") then
		CloseWindow("ChongLou_DaibiShop_Mbuy", true)
	end

	if g_CurPage >= g_MaxPage then
		return
	end
	
	g_CurPage = g_CurPage + 1

	cur_show()

end

--Reset
function ChongLou_DaibiShop_Frame_On_ResetPos()
	ChongLou_DaibiShop_Frame:SetProperty("UnifiedPosition", g_ChongLou_DaibiShop_Frame_UnifiedPosition)
end

--选择打开商店的等级
function ChongLou_DaibiShop_Select_OpenShop(which)
	g_CurShop_Level = (which or g_CurShop_Level) or 1
	select_catalog(g_CurShop_Level)
end