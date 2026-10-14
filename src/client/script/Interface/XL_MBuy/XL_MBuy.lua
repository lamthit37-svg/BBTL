local g_XL_MBuy_UnifiedPosition
local g_XL_MBuy_MaxLibaoCount = 3
local g_XL_MBuy_ItemSelectIndex
local g_XL_MBuy_SinglePrice = 1
local g_XL_MBuy_ReduceNum = 0
local g_XL_MBuy_LimitNum = 0
local g_XL_MBuy_PageNum = 0
local g_XL_MBuy_MaxMoney = 0
local g_XL_MBuy_TargetID = 0
local g_XL_MBuy_Type = 0
local g_XL_MBuy_ShopItem = {
    [1] = {itemid = 30008130, itemnum = 1, yuanbao = 480, limitcnt = 1, type = 1},
    [2] = {itemid = 30008130, itemnum = 1, yuanbao = 600, limitcnt = 20, type = 2},
}

function XL_MBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function XL_MBuy_OnLoad()	
	g_XL_MBuy_UnifiedPosition = XL_MBuy_Frame:GetProperty("UnifiedPosition")

	g_XL_MBuy_SinglePrice = 1
	g_XL_MBuy_ReduceNum = 0
	g_XL_MBuy_LimitNum = 0
	g_XL_MBuy_PageNum = 0
	g_XL_MBuy_MaxMoney = 0
end

function XL_MBuy_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99976703 ) then
		g_XL_MBuy_TargetID = tonumber(arg1)
	   	local objCared = DataPool : GetNPCIDByServerID(g_XL_MBuy_TargetID)
        this:CareObject(objCared, 1, "XL_MBuy");
		XL_MBuy_Update( tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4) )
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		XL_MBuy_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XL_MBuy_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end 
        --如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
			XL_MBuy_Close_Clicked()
		end
	end
end

function XL_MBuy_On_ResetPos()
	XL_MBuy_Frame:SetProperty("UnifiedPosition", g_XL_MBuy_UnifiedPosition);
end

function XL_MBuy_Update(targetId, ntype, nIndex, curbuynum )

	g_XL_MBuy_Type = ntype
	g_XL_MBuy_ItemSelectIndex = nIndex

    local tblinfo = {}
	local j = 0
	local tbIndex = 0
    for i = 1, table.getn(g_XL_MBuy_ShopItem) do
        if g_XL_MBuy_ShopItem[i].type == ntype then
			j = j+1
			if j == nIndex then
            	tbIndex = i
				break
			end
        end
    end
	if tbIndex < 1 or tbIndex > 2 then
		return
	end
	
	local nItemShowId = g_XL_MBuy_ShopItem[tbIndex].itemid
	local nItemNum = g_XL_MBuy_ShopItem[tbIndex].itemnum
	local nLimit = g_XL_MBuy_ShopItem[tbIndex].limitcnt
	local nDisCount = 1
	local nYB = g_XL_MBuy_ShopItem[tbIndex].yuanbao

	if nItemShowId < 0 then
		return
	end

	local theAction = DataPool:CreateActionItemForShow(nItemShowId, nItemNum)
	XL_MBuy_Item:SetActionItem(theAction:GetID())
	XL_MBuy_ItemInfo_Text:SetText("#cfff263"..theAction:GetName())


	g_XL_MBuy_SinglePrice = nYB
	g_XL_MBuy_LimitNum = nLimit
	g_XL_MBuy_ReduceNum = curbuynum
	
	XL_MBuy_ItemInfo_YuanBaoNum:SetText(ScriptGlobal_Format( "#{XLSD_251103_09}", g_XL_MBuy_SinglePrice))
	XL_MBuy_Item_BuyLimitNum:SetText("#e010101#cFFFFFF"..(g_XL_MBuy_LimitNum-g_XL_MBuy_ReduceNum))
	if g_XL_MBuy_ReduceNum >= nLimit then
		XL_MBuy_Item_Mask:Show() --售罄
	else
		XL_MBuy_Item_Mask:Hide()
	end

	XL_MBuy_InputNumBK:SetProperty("DefaultEditBox", "True");
	XL_MBuy_InputNumBK:SetText("1")
	XL_MBuy_InputNumBK:SetSelected( 0, -1 );
	local num = tonumber(XL_MBuy_InputNumBK:GetText())
	XL_MBuy_PriceNum:SetText(ScriptGlobal_Format( "#{XLSD_251103_26}", nYB*num))

	local takeYB = Player:GetData("YUANBAO")

	if takeYB >= nYB*num then
		XL_MBuy_CashNum:SetText("#cfff263"..Player:GetData("YUANBAO"))
	else
		XL_MBuy_CashNum:SetText("#cff0000"..Player:GetData("YUANBAO"))
	end
end

function XL_MBuy_TextChanged()
	local num = tonumber(XL_MBuy_InputNumBK:GetText())
	if(num == nil or num < 1) then
		XL_MBuy_InputNumBK:SetText(1)
		return
	end

	local ClaMax = 1
	local takeYB = Player:GetData("YUANBAO")
	ClaMax = math.floor(tonumber(takeYB)/tonumber(g_XL_MBuy_SinglePrice))

	if g_XL_MBuy_LimitNum ~= 0 then
		if ClaMax > (g_XL_MBuy_LimitNum-g_XL_MBuy_ReduceNum) then
			ClaMax = g_XL_MBuy_LimitNum-g_XL_MBuy_ReduceNum
		end
	end

	if num > ClaMax and ClaMax > 0 then
		num = ClaMax
		XL_MBuy_InputNumBK:SetText(tostring(num))
	end

	XL_MBuy_PriceNum:SetText(ScriptGlobal_Format( "#{XLSD_251103_26}", g_XL_MBuy_SinglePrice*num))

	local takeYB = Player:GetData("YUANBAO")
	if takeYB >= g_XL_MBuy_SinglePrice*num then
		XL_MBuy_CashNum:SetText("#cfff263"..Player:GetData("YUANBAO"))
	else
		XL_MBuy_CashNum:SetText("#cff0000"..Player:GetData("YUANBAO"))
	end
	
end

function XL_MBuy_Close_Clicked()
	this:Hide()
end

function XL_MBuy_CalMax()
	local reduce = 1
	local takeYB = Player:GetData("YUANBAO")
	reduce = math.floor(tonumber(takeYB)/tonumber(g_XL_MBuy_SinglePrice))

	if g_XL_MBuy_LimitNum ~= 0 then
		if reduce > (g_XL_MBuy_LimitNum-g_XL_MBuy_ReduceNum) then
			reduce = g_XL_MBuy_LimitNum-g_XL_MBuy_ReduceNum
		end
	end

	XL_MBuy_InputNumBK:SetText(tostring(reduce))

	return reduce
end

function XL_MBuy_OK_Clicked()
	local num = tonumber(XL_MBuy_InputNumBK:GetText())
	if(num == nil or num < 1) then
		PushDebugMessage("#{XLSD_251103_18}")
		return
	end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "buyitem" )
			Set_XSCRIPT_ScriptID(999767)
			Set_XSCRIPT_Parameter( 0, g_XL_MBuy_TargetID )
			Set_XSCRIPT_Parameter( 1, g_XL_MBuy_Type )
			Set_XSCRIPT_Parameter( 2, g_XL_MBuy_ItemSelectIndex )
			Set_XSCRIPT_Parameter( 3, num )
			Set_XSCRIPT_Parameter( 4, 0 )
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()

end

function XL_MBuy_OnHidden()
	this:Hide()
end

