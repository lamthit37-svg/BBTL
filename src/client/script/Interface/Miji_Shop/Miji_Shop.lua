local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_NpcId = -1
local g_checkType = -1
local g_curPage = 1
local g_num4Page = 15
local g_TotalPageNum = 0
local g_isMultBuy = 0

local g_GoodsList = {}
local g_GoodsNameList = {}
local g_GoodsPrizeList = {}
local g_checkList = {}

	
local g_moneyTypeStr = {[1] = "#{MJDH_210511_08}",
						[2] = "#{MJDH_210511_09}"}
						
local g_itemIndex = {[1] = 38005316,
						[2] = 38005317}

function Miji_Shop_PreLoad()
	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function Miji_Shop_OnLoad()
	g_Frame_UnifiedXPosition	= Miji_Shop_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Miji_Shop_Frame:GetProperty("UnifiedYPosition");
	
	for i = 1, g_num4Page do
		g_GoodsList[i] = _G["Miji_Shop_Item"..i]
		g_GoodsNameList[i] = _G["Miji_Shop_ItemInfo"..i.."_Name"]
		g_GoodsPrizeList[i] = _G["Miji_Shop_ItemInfo"..i.."_Text"]
	end
	
	g_checkList[1] = Miji_Shop_FenYe_CardFragment
	g_checkList[2] = Miji_Shop_FenYe_Skill
	
end

function Miji_Shop_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 88843501) then
		
		g_NpcId = Target:GetServerId2ClientId(Get_XParam_INT(0))
		g_checkType = -1
		this:CareObject( g_NpcId, 1, "Miji_Shop" )
		this:Show()

		Miji_Shop_OnCheck(1)
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Miji_Shop_OnHidden()
		
	elseif event == "ADJEST_UI_POS" then
		Miji_Shop_ResetPos()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Miji_Shop_ResetPos()
	elseif event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() then	
		Miji_Shop_UpdateXJ()
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Miji_Shop_ResetPos()
	Miji_Shop_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Miji_Shop_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Miji_Shop_Reset()
	g_curPage = 1
	g_TotalPageNum = 0
end


function Miji_Shop_UpdateXJ()

	local nItemCount = PlayerPackage:Lua_GetUnLockItemCount(g_itemIndex[g_checkType])
	if g_checkType == 1 then
		Miji_Shop_Text1:SetText(ScriptGlobal_Format(g_moneyTypeStr[g_checkType], nItemCount));
	else
		Miji_Shop_Text1:SetText(ScriptGlobal_Format(g_moneyTypeStr[g_checkType], nItemCount));
	end

end

function Miji_Shop_OnCheck(checkType)
	if g_checkType == checkType then
		return
	end
	
	g_checkType = checkType
	g_checkList[1]:SetCheck(0)
	g_checkList[2]:SetCheck(0)
	
	g_checkList[checkType]:SetCheck(1)
	
	Miji_Shop_Reset()
	
	Miji_Shop_UpPage:Disable()
	Miji_Shop_DownPage:Disable()
	Miji_Shop_CurrentlyPage:SetText(ScriptGlobal_Format("#{MJDH_210511_32}",1,1))
	
	local goodsNum = DataPool:LuaFnGetCanYeShopGoodsNum(checkType)
	
	g_TotalPageNum = math.floor(( goodsNum - 1 ) / g_num4Page) + 1
	if g_TotalPageNum < 1 then
		g_TotalPageNum = 1
	end
	
	g_curPage = 1
	Miji_Shop_UpdateGoods(g_curPage)
	Miji_Shop_UpdateXJ()
	
	if(IsWindowShow("Miji_Shop_Mbuy")) then
		CloseWindow("Miji_Shop_Mbuy", true)
	end
end

function Miji_Shop_RestGoods()
	for i = 1, g_num4Page do
		g_GoodsList[i]:SetActionItem(-1)
		g_GoodsList[i]:ActionDisable()
		g_GoodsNameList[i]:SetText("")
		g_GoodsPrizeList[i]:SetText("")
	end
end

function Miji_Shop_UpdateGoods(pageNum)
	if not this:IsVisible() then 
		return 
	end
	
	Miji_Shop_CurrentlyPage:SetText(ScriptGlobal_Format("#{MJDH_210511_32}",pageNum,g_TotalPageNum))
	if pageNum == 1 then
		Miji_Shop_UpPage:Disable()
	else
		Miji_Shop_UpPage:Enable()
	end
	
	if pageNum == g_TotalPageNum then
		Miji_Shop_DownPage:Disable()
	else
		Miji_Shop_DownPage:Enable()
	end
	
	Miji_Shop_RestGoods()
	
	local goodsNum =  DataPool:LuaFnGetCanYeShopGoodsNum(g_checkType)
	if goodsNum <= 0 then
		return
	end
	
	local startIndex = pageNum * g_num4Page - g_num4Page
	local endIndex = startIndex + g_num4Page
	if endIndex > goodsNum then
		endIndex = goodsNum
	end
	
	local nIndex = 1
	for i = startIndex, endIndex - 1 do
		local nItemId, nItemShowId, nNeedItemId, nNeedItemNum, szItemName, szNeedItemName = DataPool:LuaFnGetCanYeShopGoodsInfo( g_checkType, i)
		if nItemId == -1 then
			return 
		end
		
		local theAction = DataPool:CreateBindActionItemForShow(nItemShowId, 1)
		if theAction:GetID() == 0 then
			return
		end
		
		g_GoodsList[nIndex]:SetActionItem(theAction:GetID())
		g_GoodsList[nIndex]:ActionEnable()
		g_GoodsNameList[nIndex]:SetText("#cfff263"..szItemName)		
		g_GoodsPrizeList[nIndex]:SetText(ScriptGlobal_Format(g_moneyTypeStr[g_checkType], nNeedItemNum))
		nIndex = nIndex + 1
		
	end
end

function Miji_Shop_onGoods(index)
	if index < 1 or index > g_num4Page then
		return
	end
	local ret = g_GoodsList[index]:GetActionItem()
	if ret == -1 then
		return
	end

	if g_isMultBuy == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnByItem" )
			Set_XSCRIPT_ScriptID(888435)
			Set_XSCRIPT_Parameter(0, g_checkType) 
			Set_XSCRIPT_Parameter(1, g_num4Page*(g_curPage-1)+index) 
			Set_XSCRIPT_Parameter(2, 1) 
			Set_XSCRIPT_Parameter(3, 0) 
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
		if(IsWindowShow("Miji_Shop_Mbuy")) then
			CloseWindow("Miji_Shop_Mbuy", true)
		end
	else
		SetDefaultMouse()
		g_isMultBuy = 0
		PushEvent("CANYESHOP_OPENMUTLBUY", g_checkType, g_num4Page*(g_curPage-1)+index, g_NpcId)
	end
end

function Miji_Shop_BuyMult()
	PrepearBuyMult()
	g_isMultBuy = 1
end

function Miji_Shop_onPageUp()
	if g_curPage <= 1 then
		return
	end
	
	g_curPage = g_curPage - 1
	Miji_Shop_UpdateGoods(g_curPage)
	if(IsWindowShow("Miji_Shop_Mbuy")) then
		CloseWindow("Miji_Shop_Mbuy", true)
	end
end

function Miji_Shop_onPageDown()
	if g_curPage >= g_TotalPageNum then
		return
	end
	
	g_curPage = g_curPage + 1
	Miji_Shop_UpdateGoods(g_curPage)
	if(IsWindowShow("Miji_Shop_Mbuy")) then
		CloseWindow("Miji_Shop_Mbuy", true)
	end
end


function Miji_Shop_CloseClicked()
	this:Hide()
end

function Miji_Shop_OnHidden()
	SetDefaultMouse()
	this:CareObject( g_NpcId, 0, "Miji_Shop" )
	g_isMultBuy = 0
	g_checkType = -1
	if(IsWindowShow("Miji_Shop_Mbuy")) then
		CloseWindow("Miji_Shop_Mbuy", true)
	end
end