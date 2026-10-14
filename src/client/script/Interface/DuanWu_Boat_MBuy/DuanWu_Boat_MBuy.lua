--端午开船 批量购买
local g_DuanWu_Boat_MBuy_Frame_UnifiedPosition
local g_MaxNum = 3635
local g_HaveNum = 0
local g_HadCostNum = 0
local g_Price = 98
--===============================================
-- OnLoad()
--===============================================
function DuanWu_Boat_MBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	--逻辑相关的事件
    this:RegisterEvent("OPEN_DUANWU_BOAT_MBUY",true)
    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

    this:RegisterEvent("CLOSE_DUANWU_BOAT_MBUY",false);
    
end

function DuanWu_Boat_MBuy_OnLoad()
	g_DuanWu_Boat_MBuy_Frame_UnifiedPosition = DuanWu_Boat_MBuy_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function DuanWu_Boat_MBuy_OnEvent( event )
	if event == "OPEN_DUANWU_BOAT_MBUY" then
        g_HaveNum = tonumber(arg0) 
        g_HadCostNum = tonumber(arg1) 

	    DuanWu_Boat_MBuy_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        DuanWu_Boat_MBuy_InputNum:SetText("1")					--默认输入为1   
        DuanWu_Boat_MBuy_InputNum:SetSelected( 0, -1 ); 
        DuanWu_Boat_MBuy_FreshWindow() 
        this:Show()
        
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		DuanWu_Boat_MBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DuanWu_Boat_MBuy_Close_Clicked()
	elseif event == "ADJEST_UI_POS" then
		DuanWu_Boat_MBuy_Frame_On_ResetPos() 	
    elseif event == "CLOSE_DUANWU_BOAT_MBUY" then	
        DuanWu_Boat_MBuy_Close_Clicked()
	end
end

--===============================================
--刷新界面信息
--===============================================
function DuanWu_Boat_MBuy_FreshWindow()
    
    local nBuyNum =	1
	if DuanWu_Boat_MBuy_InputNum:GetText() ~= '' then
		nBuyNum	= tonumber(DuanWu_Boat_MBuy_InputNum:GetText())
    end 

	if nBuyNum < 0 then
        nBuyNum = 0
        DuanWu_Boat_MBuy_InputNum:SetText(nBuyNum)
        PushDebugMessage("#{DWKC_20210508_16}")
    end

    local nYuanBao = Player:GetData("YUANBAO")
    local nCanBuy_ = g_MaxNum - g_HadCostNum - g_HaveNum

    if nCanBuy_ == 0 then
        PushDebugMessage("#{DWKC_20210508_31}")
        return
    end
    
    if nBuyNum > nCanBuy_ then
        nBuyNum = nCanBuy_
        local str = ScriptGlobal_Format("#{DWKC_20210508_32}", g_HadCostNum + g_HaveNum, nBuyNum)
        PushDebugMessage(str)
        DuanWu_Boat_MBuy_InputNum:SetText(nBuyNum)
    end

    DuanWu_Boat_MBuy_Price_Lilianzhi:SetText("#M"..(g_Price * nBuyNum))
    DuanWu_Boat_MBuy_Cash_Lilianzhi:SetText()
    
    if nYuanBao < g_Price * nBuyNum then
        DuanWu_Boat_MBuy_Cash_Lilianzhi:SetText("#cff0000"..nYuanBao)
    else
        DuanWu_Boat_MBuy_Cash_Lilianzhi:SetText("#M"..nYuanBao)
    end

    local theAction = DataPool:CreateActionItemForShow(39921716, 1)
    if (theAction:GetID()~=0) then
        DuanWu_Boat_MBuy_But:SetActionItem(theAction:GetID())
    end

    DuanWu_Boat_MBuy_ItemInfo_Text:SetText("#{DWKC_20210508_13}")
    DuanWu_Boat_MBuy_ItemInfo_Lilianzhi:SetText(ScriptGlobal_Format("#{DWKC_20210508_14}", g_Price))
end



--===============================================
--取出相应的物资
--===============================================
function DuanWu_Boat_MBuy_OK_Clicked()
 
	local count = tonumber(DuanWu_Boat_MBuy_InputNum:GetText())
	if count <= 0 then
        PushDebugMessage("#{DWKC_20210508_16}")
		return
    end 

	DuanWu_Boat_MBuy_BuyItem(count)				
end

function DuanWu_Boat_MBuy_BuyItem(count)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "BuyItem" ) 				
        Set_XSCRIPT_ScriptID( 505087 )									  
        Set_XSCRIPT_Parameter( 0, count)	 
        Set_XSCRIPT_Parameter( 1, 0)    
        Set_XSCRIPT_ParamCount( 2 )  
    Send_XSCRIPT()	
end

function DuanWu_Boat_MBuy_CalMax()    
    local nYB = Player:GetData("YUANBAO")
    local nCanBuy = math.floor(nYB/g_Price)
    local nCanBuy_ = g_MaxNum - g_HadCostNum - g_HaveNum
    local nMax = 0
    if nCanBuy >= nCanBuy_ then
        nMax = nCanBuy_
    else
        nMax = nCanBuy
    end

	DuanWu_Boat_MBuy_InputNum:SetText(nMax)
    DuanWu_Boat_MBuy_FreshWindow()
end

function DuanWu_Boat_MBuy_TextChanged() 
    DuanWu_Boat_MBuy_FreshWindow() 
end

function DuanWu_Boat_MBuy_OnHidden()    
	this:Hide()
end

function DuanWu_Boat_MBuy_Close_Clicked()
	this:Hide()
end

function DuanWu_Boat_MBuy_Frame_On_ResetPos()
	 DuanWu_Boat_MBuy_Frame:SetProperty("UnifiedPosition", g_DuanWu_Boat_MBuy_Frame_UnifiedPosition)
end
