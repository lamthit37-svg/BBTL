local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_XGGoodsIndex = -1
local g_XGGoodsId = -1
local g_XGGoodsNum = -1
local g_XGGoodsCost = -1
local g_XGGoodsLast = -1
local g_XGGoodsLimit = -1
local g_XGMaxNum = 0

function XiGua_BatchBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function XiGua_BatchBuy_OnLoad()
	g_Frame_UnifiedXPosition	= XiGua_BatchBuy_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= XiGua_BatchBuy_Frame:GetProperty("UnifiedYPosition")
end

function XiGua_BatchBuy_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88808205) then
		local nFlag = Get_XParam_INT(0)
		if nFlag == 2 then
			if this:IsVisible() then
				g_XGGoodsLast = Get_XParam_INT(1)		
				g_XGGoodsLimit = Get_XParam_INT(2)	
				if g_XGGoodsLimit > 0 then
					if g_XGGoodsLast < 0 then
						g_XGGoodsLast = 0
					end
					
					XiGua_BatchBuyBtnNumber:SetText(tostring(g_XGGoodsLast))
				end
				return
			end
		elseif nFlag == 1 then
			g_XGGoodsIndex = Get_XParam_INT(1)			
			g_XGGoodsId = Get_XParam_INT(2)
			g_XGGoodsNum = Get_XParam_INT(3)	
			g_XGGoodsCost = Get_XParam_INT(4)	
			g_XGGoodsLast = Get_XParam_INT(5)	
			g_XGGoodsLimit = Get_XParam_INT(6)	
			
			this:Show()
			XiGua_BatchBuy_OnOpen()
		else
			XiGua_BatchBuy_OnClose()
		end
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		XiGua_BatchBuy_OnClose()
		
	elseif (event == "ADJEST_UI_POS") then
		XiGua_BatchBuy_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiGua_BatchBuy_ResetPos()

	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		XiGua_BatchBuy_MaxNum()
		XiGua_BatchBuy_TextChanged()
	end
end

function XiGua_BatchBuy_ResetPos()
	XiGua_BatchBuy_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	XiGua_BatchBuy_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function XiGua_BatchBuy_OnHidden()
	XiGua_BatchBuy_NumberInput:SetProperty("DefaultEditBox", "False");
end

function XiGua_BatchBuy_OnOpen()
	
	if g_XGGoodsNum < 0 or g_XGGoodsId < 0 then
		return
	end
			
	local name = DataPool:Lua_GetItemNameByIndex(g_XGGoodsId)
	if name == nil then
		return
	end
	
	local theAction = DataPool:CreateActionItemForShow(g_XGGoodsId, g_XGGoodsNum)
	if theAction:GetID() == 0 then
		return
	end
	
	XiGua_BatchBuyBtnNumber:SetText("")
	XiGua_BatchBuyBtnNumberBK:Hide()
	
	if g_XGGoodsLimit > 0 then
		if g_XGGoodsLast < 0 then
			g_XGGoodsLast = 0
		end
		
		XiGua_BatchBuyBtnNumber:SetText(tostring(g_XGGoodsLast))
		XiGua_BatchBuyBtnNumberBK:Show()
	end
	
	XiGua_BatchBuy_Item:SetActionItem(theAction:GetID())
	XiGua_BatchBuy_ItemName:SetText("#L"..name)
	XiGua_BatchBuy_ItemPrice:SetText(ScriptGlobal_Format("#{MZXB_200609_88}", tostring(g_XGGoodsCost)))
	
	XiGua_BatchBuy_MaxNum()	
	XiGua_BatchBuy_NumberInput:SetProperty("DefaultEditBox", "True");
	XiGua_BatchBuy_NumberInput:SetText(tostring(1))
	XiGua_BatchBuy_NumberInput:SetSelected( 0, -1 );
end

function XiGua_BatchBuy_MaxNum()

	if g_XGGoodsNum < 0 or g_XGGoodsId < 0 then
		return
	end
	
	local bagSpace = GetBagSpace(g_XGGoodsId)
	local layerNum = GuiShiUI:LuaFnGetNPCShopGoodsLayerNum(g_XGGoodsId)
	
	local layerMaxNum = bagSpace * layerNum
	
	local numList = {}
	table.insert(numList, layerMaxNum) 
	
	if g_XGGoodsLimit > 0 then
		table.insert(numList, g_XGGoodsLast)
	end 
	
	g_XiGua_BatchBuy_CurYuLianZi = PlayerPackage:CountAvailableItemByIDTable(38004800)
	table.insert(numList, math.floor(g_XiGua_BatchBuy_CurYuLianZi / g_XGGoodsCost))
		
	g_XGMaxNum = numList[1]
	for i = 1, table.getn(numList) do
		if g_XGMaxNum > numList[i] then
			g_XGMaxNum = numList[i]
		end
	end
	
	if g_XGMaxNum < 1 then
		g_XGMaxNum = 1
	end
	
	if g_XGMaxNum > 999 then
		g_XGMaxNum = 999
	end
end

function XiGua_BatchBuy_TextChanged()
	local num = tonumber(XiGua_BatchBuy_NumberInput:GetText())
	if num == nil then
		XiGua_BatchBuy_TextNeedNum:SetText("#L"..tostring(0))
		return
	end
	
	if num > g_XGMaxNum then
		XiGua_BatchBuy_NumberInput:SetText(tostring(g_XGMaxNum))
		
	elseif num < 1 then
		XiGua_BatchBuy_NumberInput:SetText("1")
		
	else
		if g_XGGoodsNum < 0 or g_XGGoodsId < 0 then
			return
		end
		
		local totalNum = num * g_XGGoodsCost
		XiGua_BatchBuy_TextNeedNum:SetText("#L"..tostring(totalNum))
		
		local haveNum = PlayerPackage:CountAvailableItemByIDTable(38004800)
		if haveNum < totalNum then
			XiGua_BatchBuy_TextHaveNum:SetText(ScriptGlobal_Format("#{MZXB_200609_94}", tostring(haveNum)))
		else
			XiGua_BatchBuy_TextHaveNum:SetText(ScriptGlobal_Format("#{MZXB_200609_95}", tostring(haveNum)))
		end
	end
end

function XiGua_BatchBuy_OnMax()
	XiGua_BatchBuy_NumberInput:SetText(g_XGMaxNum)
end

function XiGua_BatchBuy_OnClose()
	this:Hide()
end


function XiGua_BatchBuy_OnOK()
	local num = tonumber(XiGua_BatchBuy_NumberInput:GetText());
	if num == nil then
		PushDebugMessage("#{MZXB_200609_118}")
		return
	end
	
	if g_XGGoodsNum < 0 or g_XGGoodsId < 0 then
		PushDebugMessage("#{MZXB_200609_120}")
		return
	end
	 
	if num > 0 and num ~= nil then		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnMultDuiHuanItem")
			Set_XSCRIPT_ScriptID(888082)
			Set_XSCRIPT_Parameter(0, g_XGGoodsIndex)
			Set_XSCRIPT_Parameter(1, g_XGGoodsId)
			Set_XSCRIPT_Parameter(2, num)
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()		
	end
end