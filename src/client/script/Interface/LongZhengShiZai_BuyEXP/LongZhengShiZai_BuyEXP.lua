local g_LongZhengShiZai_BuyEXP_Frame_UnifiedPosition = nil

local g_price = 0
local g_MAXBUY = 0
local g_yuanbao = 0
--===============================================
-- OnLoad()
--===============================================
function LongZhengShiZai_BuyEXP_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("NLZSZ_UI",true)
    this:RegisterEvent("UPDATE_YUANBAO", false)
end

function LongZhengShiZai_BuyEXP_OnLoad()
	g_LongZhengShiZai_BuyEXP_Frame_UnifiedPosition	=	LongZhengShiZai_BuyEXP_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function LongZhengShiZai_BuyEXP_OnEvent( event )
    if event == "NLZSZ_UI" then
        local Opt = tonumber(arg0)
        if Opt == 4 then
            g_price = tonumber(arg1)
            g_MAXBUY = tonumber(arg2)
            LongZhengShiZai_BuyEXP_InputNum:SetText("1")		--打开界面默认购买领取数值为1
            SetDefaultMouse()
            LongZhengShiZai_BuyEXP_Open()
        end
    elseif event == "UPDATE_YUANBAO" then
		LongZhengShiZai_BuyEXP_Open()
	end
end

local function CalMaxNum()
    --计算最大能领取数量
    local canbuy =  math.floor(g_yuanbao/g_price)
    if canbuy > g_MAXBUY then
        return g_MAXBUY
    else
        return canbuy
    end
end

--===============================================
--刷新界面信息
--===============================================
function LongZhengShiZai_BuyEXP_Open()
    g_yuanbao = Player:GetData("YUANBAO")
	LongZhengShiZai_BuyEXP_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	LongZhengShiZai_BuyEXP_InputNum:SetText("1")					--默认输入为1
	LongZhengShiZai_BuyEXP_Price_Yuanbao:SetText(g_price) --需要元宝
	LongZhengShiZai_BuyEXP_Cash_Yuanbao:SetText(g_yuanbao) --拥有元宝
    this:Show()
    LongZhengShiZai_BuyEXP_TextChanged()
end

--===============================================
--关闭界面
--===============================================
function LongZhengShiZai_BuyEXP_Closed()

    g_Info = nil
    this:Hide()

end

function LongZhengShiZai_BuyEXP_Buy_Clicked()
	local count = tonumber(LongZhengShiZai_BuyEXP_InputNum:GetText())
	if count <= 0 then
		return
    end	
    if count > CalMaxNum() then
        PushDebugMessage("购买数量超过最大值")
    end
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnBuySteps")
        Set_XSCRIPT_ScriptID(888391)			
        Set_XSCRIPT_Parameter(0,count);				
        Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()	
	
	--隐藏界面
	this:Hide()					
end



function LongZhengShiZai_BuyEXP_CalMax()
	LongZhengShiZai_BuyEXP_InputNum : SetText(tostring(CalMaxNum()))
end

function LongZhengShiZai_BuyEXP_TextChanged()
	local	nBuyNum	=	0
	if LongZhengShiZai_BuyEXP_InputNum:GetText() ~= '' then
		nBuyNum	=	tonumber(LongZhengShiZai_BuyEXP_InputNum:GetText())
	end
	if nBuyNum > g_MAXBUY then
		nBuyNum = g_MAXBUY
		LongZhengShiZai_BuyEXP_InputNum:SetText(tostring(nBuyNum))
		return
	end

	if nBuyNum*g_price > g_yuanbao  then
		LongZhengShiZai_BuyEXP_Price_Yuanbao:SetText("#cFF0000"..nBuyNum*g_price)
	else
		LongZhengShiZai_BuyEXP_Price_Yuanbao:SetText("#c00FF00"..nBuyNum*g_price)
	end
	if nBuyNum > CalMaxNum() or nBuyNum == 0 then
		LongZhengShiZai_BuyEXP_Buy:Disable()
	else
		LongZhengShiZai_BuyEXP_Buy:Enable()
	end
end

function LongZhengShiZai_BuyEXP_CancelClicked()
	LongZhengShiZai_BuyEXP_Closed()
end

function LongZhengShiZai_BuyEXP_Frame_On_ResetPos()
	 LongZhengShiZai_BuyEXP_Frame:SetProperty("UnifiedPosition", g_LongZhengShiZai_BuyEXP_Frame_UnifiedPosition)
end
