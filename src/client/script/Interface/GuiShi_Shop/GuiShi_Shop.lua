local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_ShopIndex = -1
local g_NpcId = -1
local g_curPage = 1
local g_num4Page = 12
local g_TotalPageNum = 0

local g_GoodsList = {}
local g_GoodsNumList = {}
local g_GoodsNameList = {}
local g_GoodsLimitedList = {}
local g_GoodsLimitedListBK = {}
local g_GoodsLimitedIcon = {}
local g_GoodsMask = {}
local g_GoodsPrice1 = {}
local g_GoodsPricePlus = {}
local g_GoodsPrice2 = {}
local g_RepoList = {}

local g_priceStr = {"#{GSHB_190801_65}", "#{GSHB_190801_66}", "#{GSHB_190801_67}", "#{GSHB_190801_68}", "#{GXDJ_200323_59}" }
local g_NPC_SHOP_NAME = {[0] = "#{GSHB_190801_113}", [1] = "#{GSCX_190727_358}", [2] = "#{GSCX_190727_359}", [3] = "#{GSQL_190731_108}",  [4] = "#{GSDG_190729_235}", [8] = "#{GXDJ_200323_48}"}
local g_AboutTips = {[8] = "#{GXDJ_200323_50}" }

function GuiShi_Shop_PreLoad()
	this:RegisterEvent("GUISHI_OPEN_NPCSHOP")
	this:RegisterEvent("GUISHI_UPDATE_NPCSHOP_LIMITED")
	this:RegisterEvent("GUISHI_UPDATE_NPCSHOP_SOLDLIST")
	this:RegisterEvent("GUISHI_YINPIAO_UPDATE",false)
	this:RegisterEvent("GUISHI_YINLIANG_UPDATE",false)
	this:RegisterEvent("GUISHI_TONGBI_UPDATE",false)
	this:RegisterEvent("GUISHI_MONEY4_UPDATE",false)
	this:RegisterEvent("GUISHI_ONBUY")
	this:RegisterEvent("GUISHI_ONREPO")
	this:RegisterEvent("GUISHI_ONSELL")
	this:RegisterEvent("GUISHI_SELL")
	this:RegisterEvent("MONEY_CHANGE_EX", false);
	
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function GuiShi_Shop_OnLoad()
	g_Frame_UnifiedXPosition	= GuiShi_Shop_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= GuiShi_Shop_Frame:GetProperty("UnifiedYPosition");
	
	for i = 1, g_num4Page do
		g_GoodsList[i] = _G["GuiShi_Shop_Item"..i]
		g_GoodsNumList[i] = _G["GuiShi_Shop_Item"..i.."LimitNumber"]
		g_GoodsNameList[i] = _G["GuiShi_Shop_Item"..i.."Name"]
		g_GoodsLimitedList[i] = _G["GuiShi_Shop_Item"..i.."LimitiImage"]
		g_GoodsLimitedListBK[i] = _G["GuiShi_Shop_Item"..i.."LimitNumberBK"]
		g_GoodsPrice1[i] = _G["GuiShi_Shop_Item"..i.."Price1"]
		g_GoodsPricePlus[i] = _G["GuiShi_Shop_Item"..i.."Plus"]
		g_GoodsPrice2[i] = _G["GuiShi_Shop_Item"..i.."Price2"]
		g_GoodsMask[i] = _G["GuiShi_Shop_Item"..i.."Mask"]
		g_GoodsLimitedIcon[i] = _G["GuiShi_Shop_Item"..i.."Icon"]
	end
	
	for i = 1, 5 do
		g_RepoList[i] = _G["GuiShi_Shop_Callback"..i]
	end
end

function GuiShi_Shop_OnEvent(event)
	if (event == "GUISHI_OPEN_NPCSHOP") then
		g_ShopIndex = tonumber(arg0)
		g_NpcId = Target:GetServerId2ClientId(tonumber(arg1))
		this:CareObject( g_NpcId, 1, "GuiShi_Shop" )
		GuiShi_Shop_Reset()
		GuiShi_Shop_OnOpen()
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		GuiShi_Shop_OnClose()
	elseif event == "ADJEST_UI_POS" then
		GuiShi_Shop_ResetPos()
		
	elseif event == "GUISHI_UPDATE_NPCSHOP_LIMITED" then
		GuiShi_Shop_UpdateGoods(g_curPage)
		
	elseif event == "GUISHI_UPDATE_NPCSHOP_SOLDLIST" then
		GuiShi_Shop_UpdateRepo()
		
	elseif event == "GUISHI_YINPIAO_UPDATE" then
		GuiShi_Shop_UpdateMoney()
	elseif event == "GUISHI_YINLIANG_UPDATE" then
		GuiShi_Shop_UpdateMoney()
	elseif event == "GUISHI_TONGBI_UPDATE" then
		GuiShi_Shop_UpdateMoney()
	elseif event == "GUISHI_MONEY4_UPDATE" then
		GuiShi_Shop_UpdateMoney()
	elseif event == "MONEY_CHANGE_EX" then
		GuiShi_Shop_UpdateMoney()
		
	elseif event == "GUISHI_ONBUY" then
		GuiShi_Shop_onBuy(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4))
		
	elseif event == "GUISHI_ONREPO" then
		GuiShi_Shop_onRepoList(tonumber(arg0), tonumber(arg1))
		
	elseif event == "GUISHI_ONSELL" then
		GuiShi_Shop_onSell(tonumber(arg0))
	
	elseif event == "GUISHI_SELL" then
		 GuiShi_Shop_Sell(tonumber(arg0))
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function GuiShi_Shop_ResetPos()
	GuiShi_Shop_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	GuiShi_Shop_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function GuiShi_Shop_Reset()
	g_curPage = 1
	g_TotalPageNum = 0
end

function GuiShi_Shop_OnClose()
	this:Hide()
	SetDefaultMouse()
end

function GuiShi_Shop_OnHidden()
	this:CareObject( g_NpcId, 0, "GuiShi_Shop" )
	GuiShi_Shop_Reset()
	if(IsWindowShow("GuiShi_ShopMBuy")) then
		CloseWindow("GuiShi_ShopMBuy", true)
	end
end

function Gui_Shi_Shop_resetGoods()
	for i = 1, g_num4Page do
		g_GoodsList[i]:SetActionItem(-1)
		g_GoodsList[i]:ActionDisable()
		g_GoodsNumList[i]:SetText("")
		g_GoodsLimitedListBK[i]:Hide()
		g_GoodsNameList[i]:SetText("")
		g_GoodsLimitedList[i]:Hide()
		g_GoodsPrice1[i]:SetText("")
		g_GoodsPricePlus[i]:Hide()
		g_GoodsPrice2[i]:SetText("")
		g_GoodsMask[i]:Hide()
		g_GoodsLimitedIcon[i]:Hide()
	end
end

function GuiShi_Shop_OnOpen()
	local name = Target:GetNpcName(g_NpcId)
	if g_NPC_SHOP_NAME[g_ShopIndex] ~= nil then
		name = g_NPC_SHOP_NAME[g_ShopIndex]
	end
	
	if g_AboutTips[g_ShopIndex] ~= nil then
		GuiShi_Shop_Help:SetToolTip(g_AboutTips[g_ShopIndex])
	else
		GuiShi_Shop_Help:SetToolTip("")
	end

	GuiShi_Shop_DragTitle:SetText("#gFF0FA0"..name)
	Gui_Shi_Shop_resetGoods()
	
	GuiShi_Shop_UpPage:Disable()
	GuiShi_Shop_DownPage:Disable()
	GuiShi_Shop_CurrentlyPage:SetText(ScriptGlobal_Format("#{GSHB_190801_26}",1,1))
	
	local goodsNum = GuiShiUI:LuaFnGetNPCShopGoodsNum()
	if goodsNum > 0 then
		g_TotalPageNum = math.floor(( goodsNum - 1 ) / g_num4Page) + 1
		g_curPage = 1
		GuiShi_Shop_UpdateGoods(g_curPage)
	end
	
	GuiShi_Shop_UpdateRepo()
	GuiShi_Shop_UpdateMoney()

	if IsWindowShow("GuiShi_ShopMBuy") then
		CloseWindow("GuiShi_ShopMBuy", true)
	end
end

function GuiShi_Shop_UpdateGoods(page)
	GuiShi_Shop_CurrentlyPage:SetText(ScriptGlobal_Format("#{GSHB_190801_26}",page,g_TotalPageNum))
	if page == 1 then
		GuiShi_Shop_UpPage:Disable()
	else
		GuiShi_Shop_UpPage:Enable()
	end
	
	if page == g_TotalPageNum then
		GuiShi_Shop_DownPage:Disable()
	else
		GuiShi_Shop_DownPage:Enable()
	end
	
	Gui_Shi_Shop_resetGoods()
	
	local goodsNum = GuiShiUI:LuaFnGetNPCShopGoodsNum()
	local startIndex = page * g_num4Page - g_num4Page
	local endIndex = startIndex + g_num4Page
	if endIndex > goodsNum then
		endIndex = goodsNum
	end
	
	local index = 1
	for i = startIndex, endIndex - 1 do
		local result, name, isLimited, limitedNum, buyNum, needType1, needNum1, needStep1, needType2, needNum2, needStep2= GuiShiUI:LuaFnGetNPCShopGoodsInfo(i)
		if result == 0 then
			continue
		end
			
		local theAction = EnumAction(i, "gs_npcshop_goodslist")
		if theAction:GetID() == 0 then
			continue
		end
		g_GoodsList[index]:SetActionItem(theAction:GetID())
		g_GoodsNameList[index]:SetText(name)
		g_GoodsList[index]:ActionEnable()
		if isLimited > 0 then
			if limitedNum < 0 then
				limitedNum = 0
			end
			
			if limitedNum == 0 then
				g_GoodsNameList[index]:SetText("#c7f7f7f"..name)
				g_GoodsMask[index]:Show()
			end
			
			needNum1 = needNum1 + needStep1 * buyNum
			needNum2 = needNum2 + needStep2 * buyNum
			g_GoodsNumList[index]:SetText(tostring(limitedNum))
			g_GoodsLimitedList[index]:Show()
			g_GoodsLimitedListBK[index]:Show()
			g_GoodsLimitedIcon[index]:Show()
		end
		
		local pirce = {{needType1, needNum1}, {needType2, needNum2}}
		local isHigher = function(a, b)
									if a[2] == 0 then
										return false
									
									elseif b[2] == 0 then
										return false
									else
										return a[1] < b[1]
									end
								end

		table.sort(pirce, isHigher)	
		if pirce[1][2] ~= 0 then
			g_GoodsPrice1[index]:SetText(ScriptGlobal_Format(g_priceStr[pirce[1][1]], pirce[1][2]))
		end
		
		if pirce[2][2] ~= 0 then
			g_GoodsPrice1[index]:SetText(ScriptGlobal_Format(g_priceStr[pirce[2][1]], pirce[2][2]).."#{GSHB_190801_99}"..ScriptGlobal_Format(g_priceStr[pirce[1][1]], pirce[1][2]))
			--g_GoodsPricePlus[index]:Show()
			--g_GoodsPrice2[index]:SetText(ScriptGlobal_Format(g_priceStr[pirce[2][1]], pirce[2][2]))
		end
		
		index = index + 1
	end
end

function GuiShi_Shop_UpdateMoney()
	if g_ShopIndex == 8 then
		GuiShi_Shop_Money3:SetText("")
		GuiShi_Shop_Money3Image:Hide()
		GuiShi_Shop_Money1:SetText(GuiShi_Shop_FormatMoney(GuiShiUI:LuaFnGetGuiShiTongBi()))
		GuiShi_Shop_Money1:SetToolTip("#{GSHB_190801_93}")
		GuiShi_Shop_Money1Image:SetProperty("Image","set:GuiShiBase image:GuiShiMoney3")
		GuiShi_Shop_Money2:SetText(GuiShi_Shop_FormatMoney(GuiShiUI:LuaFnGetGuiShiMoney4()))
		GuiShi_Shop_Money2:SetToolTip("#{GXDJ_200323_52}")
		GuiShi_Shop_Money2Image:SetProperty("Image","set:GuiShiBase image:GuiShiMoney4")
		GuiShi_Shop_Money4:Hide()
	else
		GuiShi_Shop_Money1:SetText(GuiShi_Shop_FormatMoney(GuiShiUI:LuaFnGetGuiShiYinPiao()))
		GuiShi_Shop_Money1:SetToolTip("#{GSHB_190801_91}")
		GuiShi_Shop_Money1Image:SetProperty("Image","set:GuiShiBase image:GuiShiMoney1")
		GuiShi_Shop_Money2:SetText(GuiShi_Shop_FormatMoney(GuiShiUI:LuaFnGetGuiShiYinLiang()))
		GuiShi_Shop_Money2:SetToolTip("#{GSHB_190801_92}")
		GuiShi_Shop_Money2Image:SetProperty("Image","set:GuiShiBase image:GuiShiMoney2")
		GuiShi_Shop_Money3:SetText(GuiShi_Shop_FormatMoney(GuiShiUI:LuaFnGetGuiShiTongBi()))
		GuiShi_Shop_Money3:SetToolTip("#{GSHB_190801_93}")
		GuiShi_Shop_Money3Image:SetProperty("Image","set:GuiShiBase image:GuiShiMoney3")
		GuiShi_Shop_Money3Image:Show()
		GuiShi_Shop_Money4:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		GuiShi_Shop_Money4:Show()
	end
end

function GuiShi_Shop_FormatMoney(value)
	if value / 1000000 >= 1 then
		result = math.floor(value/ 10000)
		return tostring(result).."#{GSHB_190801_105}"
	else
		return tostring(value)
	end
end

function GuiShi_Shop_UpdateRepo()
	for i = 1, 5 do
		g_RepoList[i]:SetActionItem(-1)
	end
	
	local num = GuiShiUI:LuaFnGetNPCShopRepoListNum()
	local index = 1
	for i = 0, num - 1 do
		local theAction = EnumAction(i, "gs_npcshop_repolist")
		if theAction:GetID() == 0 then
			continue
		end
		
		g_RepoList[index]:SetActionItem(theAction:GetID())
		index = index + 1
	end
end

function GuiShi_Shop_onPageUp()
	if g_curPage <= 1 then
		return
	end
	
	g_curPage = g_curPage - 1
	GuiShi_Shop_UpdateGoods(g_curPage)
end

function GuiShi_Shop_onPageDown()
	if g_curPage >= g_TotalPageNum then
		return
	end
	
	g_curPage = g_curPage + 1
	GuiShi_Shop_UpdateGoods(g_curPage)
end

function GuiShi_Shop_BuyMult()
	PrepearBuyMult()
end

function GuiShi_Shop_onGoods(index)
	if index < 1 or index > g_num4Page then
		return
	end
	
	g_GoodsList[index]:DoAction()
end

function GuiShi_Shop_onRepo(index)
	if index < 1 or index > 5 then
		return
	end
	
	g_RepoList[index]:DoAction()
end

function GuiShi_Shop_onHelp()
	PushEvent("GUISHI_NPCSHOP_HELP", g_ShopIndex )
end

function GuiShi_Shop_price2str(priceList)
	if table.getn(priceList) == 0 then
		return ""
	end
	
	local str = ""
	local strList = {"#{GSHB_190801_65}", "#{GSHB_190801_66}", "#{GSHB_190801_67}"}
	for i = 1,  3 do
		if priceList[i] > 0 then
			str = str..ScriptGlobal_Format(strList[i], priceList[i])
		end
	end
	
	return str
end

function GuiShi_Shop_onBuy(index, goodsId, isMult, num, isReconFirm)
	if isMult == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "onBuy" )
			Set_XSCRIPT_ScriptID(893190)
			Set_XSCRIPT_Parameter(0, g_ShopIndex) 
			Set_XSCRIPT_Parameter(1, goodsId) 
			Set_XSCRIPT_Parameter(2, num) 
			Set_XSCRIPT_Parameter(3, g_NpcId) 
			Set_XSCRIPT_Parameter(4, isReconFirm) 
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
		
		--if isReconFirm == 0 then
		if(IsWindowShow("GuiShi_ShopMBuy")) then
			CloseWindow("GuiShi_ShopMBuy", true)
		end
		--end
	else
		PushEvent("GUISHI_OPENMUTLBUY", index, g_NpcId)
	end
end

function GuiShi_Shop_getSellPrice(ItemIndex, num)
	local result, yinPiao, yinLiang, tongQian = GuiShiUI:LuaFnGetNPCShopGoodsSellInfo(ItemIndex)
	if result == 0 then
		return {}
	end 
	
	return {yinPiao * num, yinLiang * num, tongQian * num}
end

function GuiShi_Shop_onRepoList(index, isReconFirm)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnRepo" )
			Set_XSCRIPT_ScriptID(893190)
			Set_XSCRIPT_Parameter(0, g_ShopIndex) 
			Set_XSCRIPT_Parameter(1, index) 
			Set_XSCRIPT_Parameter(2, isReconFirm) 
			Set_XSCRIPT_Parameter(3, g_NpcId) 
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()	
end

function GuiShi_Shop_onSell(bagIndex)
	-- 安全时间判断
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{LZZZ_150526_51}")
		return
	end

	-- 畅游+ 硬件密保 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	
	local ItemIndex = PlayerPackage : GetItemTableIndex(bagIndex)
	if ItemIndex == -1 then
		return
	end
	
	local num = PlayerPackage : GetBagItemNum(bagIndex)
	if num <= 0 then
		return
	end
	
	local priceList = GuiShi_Shop_getSellPrice(ItemIndex, num)
	if table.getn(priceList) == 0 then
		PushDebugMessage("#{GSHB_190801_40}")
		return
	end
	
	local str1 =""
	local str2 =""
	local maxYinPiao, maxYinLiang, maxTongQian = GuiShiUI:LuaFnGetMaxMoneyNum()
	local list1 = {maxYinPiao, maxYinLiang, maxTongQian}
	local list2 = {GuiShiUI:LuaFnGetGuiShiYinPiao(), GuiShiUI:LuaFnGetGuiShiYinLiang(), GuiShiUI:LuaFnGetGuiShiTongBi()}
	local strlist = {"#{GSHB_190801_60}", "#{GSHB_190801_59}", "#{GSHB_190801_61}"}
	
	for i = 1, 3 do
		if priceList[i] > 0 then
			if list2[i] == list1[i] then
				if str2 ~= "" then
					str2 = str2.."#{GSHB_190801_58}"
				end
				str2 = str2..strlist[i]
				
			elseif priceList[i] + list2[i] >  list1[i] then
				if str1 ~= "" then
					str1 = str1.."#{GSHB_190801_58}"
				end
				str1 = str1..strlist[i]
			end
		end
	end
	
	local name = DataPool:Lua_GetItemNameByIndex(ItemIndex)
	local msg
	if str2 ~= "" then
		msg = ScriptGlobal_Format("#{GSHB_190801_76}", num, name, str2)
	elseif str1 ~= "" then
		msg = ScriptGlobal_Format("#{GSHB_190801_41}", num, name, str1)
	else
		msg = ScriptGlobal_Format("#{GSHB_190801_42}", num, name, GuiShi_Shop_price2str(priceList))
	end
	PushEvent("GUISHI_SELL_RECONFIRM", "89319003", msg, g_NpcId, bagIndex)
end

function GuiShi_Shop_Sell(bagIndex)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnSell" )
			Set_XSCRIPT_ScriptID(893190)
			Set_XSCRIPT_Parameter(0, g_ShopIndex) 
			Set_XSCRIPT_Parameter(1, bagIndex) 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
end
