local g_TeQuanShop_Mbuy_Frame_UnifiedPosition = nil

local g_Info = nil

--===============================================
-- OnLoad()
--===============================================
function TeQuanShop_Mbuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	--this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	--this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	--逻辑相关的事件
    this:RegisterEvent("TeQuanShop_MITYBUY",true)
    
    this:RegisterEvent("UPDATE_YUANBAO",false);
end

function TeQuanShop_Mbuy_OnLoad()
	g_TeQuanShop_Mbuy_Frame_UnifiedPosition	=	TeQuanShop_MBuy_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function TeQuanShop_Mbuy_OnEvent( event )
    if event == "TeQuanShop_MITYBUY" then
        g_Info = {}

        g_Info.itemPriceYuanbao = tonumber(arg0)
        g_Info.itemID = tonumber(arg1)
        g_Info.maxNum = tonumber(arg2)
        g_Info.itemGroupNum = tonumber(arg3)
        g_Info.curShopLevel = tonumber(arg4)
        g_Info.OpenShopDay = tonumber(arg5)
        g_Info.uniqueID = tonumber(arg6)
        g_Info.showID = tonumber(arg7)

		TeQuanShop_MBuy_InputNumBK:SetText("1")		--打开界面默认购买领取数值为1

        TeQuanShop_Mbuy_Open()
    elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
        if not g_Info then
            return 
        end
        local	nBuyNum	=	0
        if TeQuanShop_MBuy_InputNumBK:GetText() ~= '' then
            nBuyNum	=	tonumber(TeQuanShop_MBuy_InputNumBK:GetText())
        end
        local haveMoney = Player:GetData("YUANBAO")
        TeQuanShop_MBuy_CashNum:SetText(ScriptGlobal_Format("#{TQSD_230201_26}",haveMoney))
        local needMoney = Lua_Multiply(nBuyNum, g_Info.itemPriceYuanbao)
        if haveMoney < needMoney then
            TeQuanShop_MBuy_Submit:Disable()
        end
	end
end

local function CalMaxNum()
    --计算最大能领取数量
    if g_Info == nil then
        return 0
    end
    if g_Info.itemPriceYuanbao <= 0 then
        return g_Info.maxNum
    end
    local canbuy =  math.floor(Player:GetData("YUANBAO")/g_Info.itemPriceYuanbao)
    if canbuy > g_Info.maxNum and g_Info.maxNum ~= -1 then
        return g_Info.maxNum
    else
        return canbuy
    end
end

--===============================================
--刷新界面信息
--===============================================
function TeQuanShop_Mbuy_Open()
    if g_Info == nil then
        return 
    end

    local	theAction = nil
    theAction =  DataPool:CreateBindActionItemForShow(g_Info.showID,g_Info.itemGroupNum)
    if  g_Info.maxNum == -1 then
        --不限量
        TeQuanShop_MBuy_ItemL_BuyLimitNumBK:Hide()
    elseif g_Info.maxNum > 0 then
        TeQuanShop_MBuy_ItemL_BuyLimitNumBK:Show()
        TeQuanShop_MBuy_ItemL_BuyLimitNum:SetText(g_Info.maxNum)
    end

	if theAction:GetID() ~= 0 then
		TeQuanShop_MBuy_Item:SetActionItem(theAction:GetID())
		TeQuanShop_MBuy_Item:Show()
    end
    if g_Info.maxNum ~= -1 and g_Info.maxNum < 1 then
        TeQuanShop_MBuy_Item_Mask:Show()
    else
        TeQuanShop_MBuy_Item_Mask:Hide()
    end
	TeQuanShop_MBuy_InputNumBK:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	TeQuanShop_MBuy_InputNumBK:SetText("1")					--默认输入为1
	TeQuanShop_MBuy_ItemInfo_Text:SetText("#cfff263"..DataPool:Lua_GetItemNameByIndex(g_Info.itemID)) --item名字
	TeQuanShop_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format( "#{TQSD_230201_21}", g_Info.itemPriceYuanbao)) --单价
    TeQuanShop_MBuy_PriceNum:SetText(ScriptGlobal_Format("#{TQSD_230201_26}",g_Info.itemPriceYuanbao))
    TeQuanShop_MBuy_CashNum:SetText(ScriptGlobal_Format("#{TQSD_230201_26}",Player:GetData("YUANBAO")))
    this:Show()


end

--===============================================
--关闭界面
--===============================================
function TeQuanShop_MBuy_Close_Clicked()

    g_Info = nil
    this:Hide()

end



--===============================================
--取出相应的物资
--===============================================
function TeQuanShop_MBuy_OK_Clicked()
	local count = tonumber(TeQuanShop_MBuy_InputNumBK:GetText())
	if count <= 0 then
		return
    end	
    if count > CalMaxNum() then
        PushDebugMessage("物品数量不足")
    end
    if not g_Info then
        return 
    end

    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("BuyMuti")
        Set_XSCRIPT_ScriptID(998401)
        Set_XSCRIPT_Parameter(0,g_Info.uniqueID);			
        Set_XSCRIPT_Parameter(1,g_Info.curShopLevel	);				
        Set_XSCRIPT_Parameter(2,count);	
        Set_XSCRIPT_Parameter(3,g_Info.OpenShopDay);	
        Set_XSCRIPT_ParamCount(4)
    Send_XSCRIPT()	
	
	--隐藏界面
	this:Hide()					
end



function TeQuanShop_MBuy_CalMax()
	TeQuanShop_MBuy_InputNumBK : SetText(tostring(CalMaxNum()))
end

function TeQuanShop_MBuy_TextChanged()
	local	nBuyNum	=	0
	if TeQuanShop_MBuy_InputNumBK:GetText() ~= '' then
		nBuyNum	=	tonumber(TeQuanShop_MBuy_InputNumBK:GetText())
	end
	if nBuyNum > 250 then
		--一次性购买数目不能超过250
		nBuyNum = 250
		TeQuanShop_MBuy_InputNumBK:SetText(tostring(nBuyNum))
		return
	end
    local needMoney = Lua_Multiply(nBuyNum, g_Info.itemPriceYuanbao)
	if needMoney > Player:GetData("YUANBAO")  then
        TeQuanShop_MBuy_PriceNum:SetText("#cFF0000"..ScriptGlobal_Format("#{TQSD_230201_26}",nBuyNum*g_Info.itemPriceYuanbao))
	else
        TeQuanShop_MBuy_PriceNum:SetText(ScriptGlobal_Format("#{TQSD_230201_26}",nBuyNum*g_Info.itemPriceYuanbao))
	end
	if nBuyNum > CalMaxNum() or nBuyNum == 0 then
		TeQuanShop_MBuy_Submit:Disable()
	else
		TeQuanShop_MBuy_Submit:Enable()
	end
end

function TeQuanShop_MBuy_Cancel()
	TeQuanShop_MBuy_Close_Clicked()
end

function TeQuanShop_Mbuy_Frame_On_ResetPos()
	 TeQuanShop_MBuy_Frame:SetProperty("UnifiedPosition", g_TeQuanShop_Mbuy_Frame_UnifiedPosition)
end
