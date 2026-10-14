local g_DiGong_Shop_BulkBuying_Frame_UnifiedPosition = nil

local g_Info = nil
local g_shopDaibiInfo = {
    [1] ={id=38006331,singleprice="#{JDQL_230322_153}",needprice="#{JDQL_230322_156}",haveprice="#{JDQL_230322_158}"}, --通天暗火
    [2] ={id=38006332,singleprice="#{JDQL_230322_154}",needprice="#{JDQL_230322_157}",haveprice="#{JDQL_230322_159}"}, --通天赤炎
}
--===============================================
-- OnLoad()
--===============================================
function DiGong_Shop_BulkBuying_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	--逻辑相关的事件
	this:RegisterEvent("DIGONG_SHOP_MITYBUY")
end

function DiGong_Shop_BulkBuying_OnLoad()
	g_DiGong_Shop_BulkBuying_Frame_UnifiedPosition	=	DiGong_Shop_BulkBuying_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function DiGong_Shop_BulkBuying_OnEvent( event )
    if event == "DIGONG_SHOP_MITYBUY" then
        g_Info = {}
        g_Info.needNum = tonumber(arg0)
        g_Info.itemID = tonumber(arg1)
        g_Info.shopID = tonumber(arg2)
        g_Info.objId = tonumber(arg3)
        g_Info.daibiNum = tonumber(arg4)
        g_Info.maxNum = tonumber(arg5)
        g_Info.onceNum = tonumber(arg6)
        g_Info.itemName = arg7
        g_Info.itemIndex = tonumber(arg8)
		DiGong_Shop_BulkBuying_IME:SetText("1")		--打开界面默认购买领取数值为1
		SetDefaultMouse()
        DiGong_Shop_BulkBuying_Open()
	end
end

local function CalMaxNum()
    --计算最大能领取数量
    if g_Info == nil then
        return 0
    end
    if g_Info.needNum <= 0 then
        return 0
    end
    local canbuy =  math.floor(g_Info.daibiNum/g_Info.needNum)
    if canbuy > g_Info.maxNum then
        return g_Info.maxNum
    else
        return canbuy
    end
end

--===============================================
--刷新界面信息
--===============================================
function DiGong_Shop_BulkBuying_Open()
    if g_Info == nil then
        return 
    end
    local shopId = g_Info.shopID
    if g_shopDaibiInfo[shopId] == nil then
        return 
    end
    local	theAction = nil
    if  g_Info.maxNum == -1 then
        --不限量
        theAction =  DataPool:CreateBindActionItemForShow(g_Info.itemID,g_Info.onceNum)
    elseif g_Info.maxNum > 0 then
        theAction = DataPool:CreateBindActionItemForShowWithMaxNum(g_Info.itemID,g_Info.onceNum,g_Info.maxNum)
    end
	if theAction:GetID() ~= 0 then
		DiGong_Shop_Icon:SetActionItem(theAction:GetID())
		DiGong_Shop_Icon:Show()
	end
	DiGong_Shop_BulkBuying_IME:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	DiGong_Shop_BulkBuying_IME:SetText("1")					--默认输入为1
	DiGong_Shop_BulkBuying_Need:SetText("#cfff263"..g_Info.itemName) --item名字
	DiGong_Shop_BulkBuying_Money1:SetText(ScriptGlobal_Format( g_shopDaibiInfo[shopId].singleprice, g_Info.needNum)) --单价
    DiGong_Shop_BulkBuying_Text3:SetText(g_shopDaibiInfo[shopId].needprice)
    DiGong_Shop_BulkBuying_Money2:SetText(g_Info.needNum)
    DiGong_Shop_BulkBuying_Text5:SetText(g_shopDaibiInfo[shopId].haveprice)
    DiGong_Shop_BulkBuying_Money4:SetText(g_Info.daibiNum)
    this:Show()
    --关闭二次确认
    PushEvent("DIGONGSHOP_CONFIRM")

end

--===============================================
--关闭界面
--===============================================
function DiGong_Shop_BulkBuying_Closed()

    g_Info = nil
    this:Hide()

end



--===============================================
--取出相应的物资
--===============================================
function DiGong_Shop_BulkBuying_Accept_Clicked()
	local count = tonumber(DiGong_Shop_BulkBuying_IME:GetText())
	if count <= 0 then
		return
    end	
    if count > CalMaxNum() then
        PushDebugMessage("#{JDQL_230322_144}")
    end
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("BuyMuti")
        Set_XSCRIPT_ScriptID(888864)
        Set_XSCRIPT_Parameter(0,g_Info.itemIndex);
        Set_XSCRIPT_Parameter(1,g_Info.itemID);			
        Set_XSCRIPT_Parameter(2,g_Info.shopID);				
        Set_XSCRIPT_Parameter(3,g_Info.objId);				
        Set_XSCRIPT_Parameter(4,count);				
        Set_XSCRIPT_ParamCount(5)
    Send_XSCRIPT()	
	
	--隐藏界面
	this:Hide()					
end



function DiGong_Shop_BulkBuying_CalMax()
	DiGong_Shop_BulkBuying_IME : SetText(tostring(CalMaxNum()))
end

function DiGong_Shop_BulkBuying_TextChanged()
	local	nBuyNum	=	0
	if DiGong_Shop_BulkBuying_IME:GetText() ~= '' then
		nBuyNum	=	tonumber(DiGong_Shop_BulkBuying_IME:GetText())
	end
	if nBuyNum > 250 then
		--一次性购买数目不能超过250
		nBuyNum = 250
		DiGong_Shop_BulkBuying_IME:SetText(tostring(nBuyNum))
		return
	end

	if nBuyNum*g_Info.needNum > g_Info.daibiNum  then
		DiGong_Shop_BulkBuying_Money2:SetText("#cFF0000"..nBuyNum*g_Info.needNum)
	else
		DiGong_Shop_BulkBuying_Money2:SetText(nBuyNum*g_Info.needNum)
	end
	if nBuyNum > CalMaxNum() or nBuyNum == 0 then
		DiGong_Shop_BulkBuying_Accept:Disable()
	else
		DiGong_Shop_BulkBuying_Accept:Enable()
	end
end

function DiGong_Shop_BulkBuying_CancelClicked()
	DiGong_Shop_BulkBuying_Closed()
end

function DiGong_Shop_BulkBuying_Frame_On_ResetPos()
	 DiGong_Shop_BulkBuying_Frame:SetProperty("UnifiedPosition", g_DiGong_Shop_BulkBuying_Frame_UnifiedPosition)
end
