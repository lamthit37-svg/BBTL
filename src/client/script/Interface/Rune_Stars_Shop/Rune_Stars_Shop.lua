local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_ShopIndex = -1
local g_NpcId = -1
local g_FubenLayerNum = 0
local g_checkType = -1
local g_curPage = 1
local g_num4Page = 15
local g_TotalPageNum = 0

local g_GoodsList = {}
local g_GoodsLockList = {}
local g_GoodsLimitedNum = {}
local g_GoodsLimitedNumBK = {}
local g_GoodsNameList = {}
local g_GoodsPrizeList = {}
local g_GoodsMask = {}
local g_GoodsLimitedImg = {}
local g_checkList = {}

local g_shopType = {[0] = {1,2}, [1] = {3,4}}

local g_shopTypeName = {[0] = {"#{XZJC_200309_184}", "#{XZJC_200309_185}"}, 
												[1] = {"#{XZJC_200309_241}", "#{XZJC_200309_242}"}} 

local g_shopName = {[0] = "#{XZJC_200309_239}",
										[1] = "#{XZJC_200309_240}"}
	
local g_moneyTypeStr = {[1] = "#{XZJC_200309_190}",
												[2] = "#{XZJC_200309_189}",
												[3] = "#{XZJC_200309_244}",
												[4] = "#{XZJC_200309_243}"}

function Rune_Stars_Shop_PreLoad()
	this:RegisterEvent("XZ_OPEN_NPCSHOP")
	this:RegisterEvent("XZ_UPDATE_NPCSHOP_LIMITED")
	this:RegisterEvent("XINGJUAN_CHIPDRE", false)
	this:RegisterEvent("XINGJUAN_CHIPESS", false)
	this:RegisterEvent("XZ_ONBUY")
	this:RegisterEvent("XINGJUAN_SKILLCARD")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function Rune_Stars_Shop_OnLoad()
	g_Frame_UnifiedXPosition	= Rune_Stars_Shop_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Rune_Stars_Shop_Frame:GetProperty("UnifiedYPosition");
	
	for i = 1, g_num4Page do
		g_GoodsList[i] = _G["Rune_Stars_Shop_Item"..i]
		g_GoodsLockList[i] = _G["Rune_Stars_Shop_ItemIcon_"..i]
		g_GoodsNameList[i] = _G["Rune_Stars_Shop_ItemInfo"..i.."_Text"]
		g_GoodsPrizeList[i] = _G["Rune_Stars_Shop_ItemInfo"..i.."_GB"]
		g_GoodsLimitedNum[i] = _G["Rune_Stars_Shop_Item"..i.."LimitNumber"]
		g_GoodsMask[i] = _G["Rune_Stars_Shop_ItemIcon_"..i.."Mask"]
		g_GoodsLimitedImg[i] = _G["Rune_Stars_Shop_ItemInfo"..i.."_Image"]
		g_GoodsLimitedNumBK[i] = _G["Rune_Stars_Shop_Item"..i.."LimitNumberBK"]
	end
	
	g_checkList[1] = Rune_Stars_Shop_Lower
	g_checkList[2] = Rune_Stars_Shop_Hight
	
	Rune_Stars_Shop_Text2BK:Hide()
end

function Rune_Stars_Shop_OnEvent(event)
	if (event == "XZ_OPEN_NPCSHOP") then
		g_ShopIndex = tonumber(arg0)
		g_NpcId = Target:GetServerId2ClientId(tonumber(arg1))
		g_FubenLayerNum = tonumber(arg2)
		g_checkType = -1
		this:CareObject( g_NpcId, 1, "Rune_Stars_Shop" )
		this:Show()
		
		Rune_Stars_Shop_SetShopText()
		Rune_Stars_Shop_OnCheck(1)
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Rune_Stars_Shop_OnClose()
		
	elseif event == "ADJEST_UI_POS" then
		Rune_Stars_Shop_ResetPos()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Rune_Stars_Shop_ResetPos()
		
	elseif event == "XZ_UPDATE_NPCSHOP_LIMITED" then
		Rune_Stars_Shop_UpdateGoods(g_curPage)
		
	elseif event == "XINGJUAN_CHIPDRE" then
		Rune_Stars_Shop_UpdateXJ()
		
	elseif event == "XINGJUAN_CHIPESS" then
		Rune_Stars_Shop_UpdateXJ()
		
	elseif event == "XINGJUAN_SKILLCARD" then
		Rune_Stars_Shop_UpdateXJ()
		
	elseif event == "XZ_ONBUY" then
		Rune_Stars_Shop_onBuy(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4))
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Rune_Stars_Shop_ResetPos()
	Rune_Stars_Shop_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Rune_Stars_Shop_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Rune_Stars_Shop_Reset()
	g_curPage = 1
	g_TotalPageNum = 0
end

function Rune_Stars_Shop_SetShopText()
	Rune_Stars_Shop_Text:SetText(g_shopName[g_ShopIndex])
	Rune_Stars_Shop_Lower:SetText(g_shopTypeName[g_ShopIndex][1])
	Rune_Stars_Shop_Hight:SetText(g_shopTypeName[g_ShopIndex][2])
end

function Rune_Stars_Shop_UpdateXJ()
	if g_ShopIndex == 0 then
		if g_checkType == 1 then
			Rune_Stars_Shop_Text1:SetText(ScriptGlobal_Format("#{XZJC_200309_190}", tostring(Player:GetData("XJCHIPDRE"))));
		else
			Rune_Stars_Shop_Text1:SetText(ScriptGlobal_Format("#{XZJC_200309_189}", tostring(Player:GetData("XJCHIPESS"))));
		end
	elseif g_ShopIndex == 1 then
		if g_checkType == 1 then
			Rune_Stars_Shop_Text1:SetText(ScriptGlobal_Format("#{XZJC_200309_244}", tostring(Player:GetData("XJSKILLCARDDRE"))))
		else
			Rune_Stars_Shop_Text1:SetText(ScriptGlobal_Format("#{XZJC_200309_243}", tostring(Player:GetData("XJSKILLCARDESS"))))
		end
	end
end

function Rune_Stars_Shop_OnCheck(checkType)
	if g_checkType == checkType then
		return
	end
	
	g_checkType = checkType
	g_checkList[1]:SetCheck(0)
	g_checkList[2]:SetCheck(0)
	
	g_checkList[checkType]:SetCheck(1)
	
	Rune_Stars_Shop_Reset()
	
	Rune_Stars_Shop_UpPage:Disable()
	Rune_Stars_Shop_DownPage:Disable()
	Rune_Stars_Shop_CurrentlyPage:SetText(ScriptGlobal_Format("#{XZJC_200309_195}",1,1))
	
	local goodsNum = DataPool:LuaFnGetXZNPCShopGoodsNum(g_shopType[g_ShopIndex][checkType])
	
	g_TotalPageNum = math.floor(( goodsNum - 1 ) / g_num4Page) + 1
	if g_TotalPageNum < 1 then
		g_TotalPageNum = 1
	end
	
	g_curPage = 1
	Rune_Stars_Shop_UpdateGoods(g_curPage)
	Rune_Stars_Shop_UpdateXJ()
end

function Rune_Stars_Shop_RestGoods()
	for i = 1, g_num4Page do
		g_GoodsList[i]:SetActionItem(-1)
		g_GoodsList[i]:ActionDisable()
		g_GoodsLockList[i]:Hide("")
		g_GoodsNameList[i]:SetText("")
		g_GoodsPrizeList[i]:SetText("")
		g_GoodsLimitedNum[i]:SetText("")
		g_GoodsMask[i]:Hide()
		g_GoodsLimitedImg[i]:Hide()
		g_GoodsLimitedNumBK[i]:Hide()
	end
end

function Rune_Stars_Shop_UpdateGoods(pageNum)
	if not this:IsVisible() then 
		return 
	end
	
	Rune_Stars_Shop_CurrentlyPage:SetText(ScriptGlobal_Format("#{XZJC_200309_195}",pageNum,g_TotalPageNum))
	if pageNum == 1 then
		Rune_Stars_Shop_UpPage:Disable()
	else
		Rune_Stars_Shop_UpPage:Enable()
	end
	
	if pageNum == g_TotalPageNum then
		Rune_Stars_Shop_DownPage:Disable()
	else
		Rune_Stars_Shop_DownPage:Enable()
	end
	
	Rune_Stars_Shop_RestGoods()
	
	local goodsNum =  DataPool:LuaFnGetXZNPCShopGoodsNum(g_shopType[g_ShopIndex][g_checkType])
	if goodsNum <= 0 then
		return
	end
	
	local startIndex = pageNum * g_num4Page - g_num4Page
	local endIndex = startIndex + g_num4Page
	if endIndex > goodsNum then
		endIndex = goodsNum
	end
	
	
	local index = 1
	for i = startIndex, endIndex - 1 do
		local result, realIndex, itemId, name, limitType, lastNum, moneyType, moneyNum, needFubenLayerNum = DataPool:LuaFnGetXZNPCShopGoodsInfo(i, g_shopType[g_ShopIndex][g_checkType])
		if result == 0 then
			continue
		end
		
		local theAction = EnumAction(realIndex, "xz_npcshop_goodslist")
		if theAction:GetID() == 0 then
			continue
		end
		
		g_GoodsList[index]:SetActionItem(theAction:GetID())
		g_GoodsNameList[index]:SetText("#L"..name)
		
		if needFubenLayerNum > g_FubenLayerNum then
			g_GoodsLockList[index]:Show()
			g_GoodsLockList[index]:SetToolTip(ScriptGlobal_Format("#{XZJC_200309_186}", needFubenLayerNum))
		else
			g_GoodsList[index]:ActionEnable()
		end
		
		g_GoodsPrizeList[index]:SetText(ScriptGlobal_Format(g_moneyTypeStr[moneyType], moneyNum))
		if limitType > 0 then
			g_GoodsLimitedNumBK[index]:Show()
			g_GoodsLimitedNum[index]:SetText(tostring(lastNum))
			g_GoodsLimitedImg[index]:Show()
			if limitType == 1 then
				g_GoodsLimitedImg[index]:SetProperty("Image", "set:Rune_Star01 image:zhouxian")
				g_GoodsLimitedImg[index]:SetToolTip("#{XZJC_200309_188}")
			elseif limitType == 2 then
				g_GoodsLimitedImg[index]:SetProperty("Image", "set:Rune_Star01 image:yongxian")
				g_GoodsLimitedImg[index]:SetToolTip("#{XZJC_200309_187}")
			else
				g_GoodsLimitedImg[index]:SetProperty("Image", "set:Rune_Star01 image:rixian")
				g_GoodsLimitedImg[index]:SetToolTip("#{XZJC_200309_308}")
			end
			
			if lastNum <= 0 then
				g_GoodsMask[index]:Show()
			end
		end
		
		index = index + 1
	end
end

function Rune_Stars_Shop_onGoods(index)
	if index < 1 or index > g_num4Page then
		return
	end
	
	g_GoodsList[index]:DoAction()
end

function Rune_Stars_Shop_BuyMult()
	PrepearBuyMult()
end

function Rune_Stars_Shop_onPageUp()
	if g_curPage <= 1 then
		return
	end
	
	g_curPage = g_curPage - 1
	Rune_Stars_Shop_UpdateGoods(g_curPage)
end

function Rune_Stars_Shop_onPageDown()
	if g_curPage >= g_TotalPageNum then
		return
	end
	
	g_curPage = g_curPage + 1
	Rune_Stars_Shop_UpdateGoods(g_curPage)
end

function Rune_Stars_Shop_onBuy(index, goodsId, isMult, num, isReconFirm)
	if isMult == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "onBuy" )
			Set_XSCRIPT_ScriptID(888055)
			Set_XSCRIPT_Parameter(0, g_ShopIndex) 
			Set_XSCRIPT_Parameter(1, goodsId) 
			Set_XSCRIPT_Parameter(2, num) 
			Set_XSCRIPT_Parameter(3, g_NpcId) 
			Set_XSCRIPT_Parameter(4, isReconFirm) 
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
		
		if(IsWindowShow("Rune_Stars_BatchBuy")) then
			CloseWindow("Rune_Stars_BatchBuy", true)
		end
	else
		PushEvent("XZ_OPENMUTLBUY", index, g_NpcId)
	end
end

function Rune_Stars_Shop_OnClose()
	this:Hide()
end

function Rune_Stars_Shop_OnHidden()
	SetDefaultMouse()
	this:CareObject( g_NpcId, 0, "Rune_Stars_Shop" )
	g_checkType = -1
	if(IsWindowShow("Rune_Stars_BatchBuy")) then
		CloseWindow("Rune_Stars_BatchBuy", true)
	end
end