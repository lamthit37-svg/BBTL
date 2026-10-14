local g_Newserver_Hongbao_JSB_Buy_Frame_UnifiedPosition 
local g_Newserver_Hongbao_JSB_Buy_PerDaibi_Cost = 1
local g_Newserver_Hongbao_JSB_Buy_Daibi_BuyMAX = 7000
local g_Newserver_Hongbao_JSB_Buy_Daibi_MAX = 99999
--===============================================
-- OnLoad()
--===============================================
function Newserver_Hongbao_JSB_Buy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	--逻辑相关的事件
    this:RegisterEvent("OPEN_NSHB_JSB_BUY",true) 
    this:RegisterEvent("UPDATE_YUANBAO",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Newserver_Hongbao_JSB_Buy_OnLoad()
	g_Newserver_Hongbao_JSB_Buy_Frame_UnifiedPosition	=	Newserver_Hongbao_JSB_Buy_Frame:GetProperty("UnifiedPosition")
end 

--===============================================
-- OnEvent()
--===============================================
function Newserver_Hongbao_JSB_Buy_OnEvent( event )
	if event == "OPEN_NSHB_JSB_BUY" then 
	    Newserver_Hongbao_JSB_Buy_Item1_Cash:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        Newserver_Hongbao_JSB_Buy_Item1_Cash:SetText("1")					--默认输入为1   
        Newserver_Hongbao_JSB_Buy_Item1_Cash:SetSelected( 0, -1 ); 
        Newserver_Hongbao_JSB_Buy_FreshWindow() 
        this:Show()
    elseif event == "UPDATE_YUANBAO" then
        local nYuanBao = Player:GetData("YUANBAO")
        Newserver_Hongbao_JSB_Buy_CashNum:SetText(ScriptGlobal_Format("#{HBF_241219_39}",tonumber(nYuanBao))) 	          
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Newserver_Hongbao_JSB_Buy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Newserver_Hongbao_JSB_Buy_OnHidden()
	elseif event == "ADJEST_UI_POS" then
        Newserver_Hongbao_JSB_Buy_Frame_On_ResetPos() 	 
	end
end

function Newserver_Hongbao_JSB_Buy_Frame_On_ResetPos()
    Newserver_Hongbao_JSB_Buy_Frame:SetProperty("UnifiedPosition", g_Newserver_Hongbao_JSB_Buy_Frame_UnifiedPosition)
end

--===============================================
--刷新界面信息
--===============================================
function Newserver_Hongbao_JSB_Buy_FreshWindow()  
    local hb_data = Lua_GetXinFuHongBaoDataInfo()
    if type(hb_data) ~= "table" then
        return
    end
    local Daibi         = hb_data.Daibi
    local BuyDaibi      = hb_data.BuyDaibi
    local opentime      = hb_data.OpenTime
    local closetime     = hb_data.CloseTime
    local openyear      = math.floor(opentime/10000)
    local openmonth     = math.floor(math.mod(opentime,10000)/100)
    local openday       = math.mod(opentime,100)
    local closeyear     = math.floor(closetime/10000)
    local closemonth    = math.floor(math.mod(closetime,10000)/100)
    local closeday      = math.mod(closetime,100)
    Newserver_Hongbao_JSB_Buy_ItemInfo_Text:SetText(ScriptGlobal_Format("#{HBF_241219_125}",openyear,openmonth,openday,closeyear,closemonth,closeday))
    Newserver_Hongbao_JSB_Buy_HaveNum:SetText(ScriptGlobal_Format("#{HBF_241219_128}",BuyDaibi)) 
    local nNeedYB       = g_Newserver_Hongbao_JSB_Buy_PerDaibi_Cost*tonumber(Newserver_Hongbao_JSB_Buy_Item1_Cash:GetText())
    Newserver_Hongbao_JSB_Buy_PriceNum:SetText(ScriptGlobal_Format("#{HBF_241219_39}",nNeedYB))  
    local nYuanBao = Player:GetData("YUANBAO")
    Newserver_Hongbao_JSB_Buy_CashNum:SetText(ScriptGlobal_Format("#{HBF_241219_39}",nYuanBao)) 	
end

--===============================================
--取出相应的物资
--===============================================
function Newserver_Hongbao_JSB_Buy_GetClick()
 
	local count = tonumber(Newserver_Hongbao_JSB_Buy_Item1_Cash:GetText())
	if count <= 0 then
		return
    end 
	Newserver_Hongbao_JSB_Buy_BuyItem(count)
	--隐藏界面
	Newserver_Hongbao_JSB_Buy_OnHidden()					
end

function Newserver_Hongbao_JSB_Buy_BuyItem(count) 
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "BuyDaiBi" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 501016 );								-- 脚本编号   
        Set_XSCRIPT_Parameter( 0, count );	 
        Set_XSCRIPT_Parameter( 1, 0 );	 
        Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
    Send_XSCRIPT()	
end

function Newserver_Hongbao_JSB_Buy_GetBuyMaxNum()  
    local nYuanBao = Player:GetData("YUANBAO")  
    local hb_data = Lua_GetXinFuHongBaoDataInfo()
    if type(hb_data) ~= "table" then
        return
    end
    local Daibi         = hb_data.Daibi
    local BuyDaibi      = hb_data.BuyDaibi
    if Daibi >= g_Newserver_Hongbao_JSB_Buy_Daibi_MAX then
        return 0
    end
    if BuyDaibi >= g_Newserver_Hongbao_JSB_Buy_Daibi_BuyMAX then
        return 0
    end
    local real = math.floor(nYuanBao/g_Newserver_Hongbao_JSB_Buy_PerDaibi_Cost)
    if real >= g_Newserver_Hongbao_JSB_Buy_Daibi_MAX - Daibi then
        real = g_Newserver_Hongbao_JSB_Buy_Daibi_MAX - Daibi
    end    
    if real >= g_Newserver_Hongbao_JSB_Buy_Daibi_BuyMAX - BuyDaibi  then
        real = g_Newserver_Hongbao_JSB_Buy_Daibi_BuyMAX - BuyDaibi 
    end
    return real
end

function Newserver_Hongbao_JSB_Buy_CalMax()    
    Newserver_Hongbao_JSB_Buy_Item1_Cash : SetText(Newserver_Hongbao_JSB_Buy_GetBuyMaxNum())
    Newserver_Hongbao_JSB_Buy_FreshWindow() 
end

function Newserver_Hongbao_JSB_Buy_TextChanged() 
    local num = tonumber(Newserver_Hongbao_JSB_Buy_Item1_Cash:GetText());
	if(nil == num or(num and num < 0)) then 
        Newserver_Hongbao_JSB_Buy_PriceNum:SetText("0") 
        Newserver_Hongbao_JSB_Buy_Item1_Cash:SetText("0") 
        return
    end
    local nbuynum = Newserver_Hongbao_JSB_Buy_GetBuyMaxNum()
    if num >=0 and num > nbuynum then
        Newserver_Hongbao_JSB_Buy_Item1_Cash : SetText(Newserver_Hongbao_JSB_Buy_GetBuyMaxNum())
    end
    Newserver_Hongbao_JSB_Buy_FreshWindow() 
end

function Newserver_Hongbao_JSB_Buy_OnHidden()    
    g_Newserver_Hongbao_Tblidx = 1
    g_Newserver_Hongbao_CXID = 1
    this:Hide()
end

function Newserver_Hongbao_JSB_Buy_Close_Clicked()
	Newserver_Hongbao_JSB_Buy_OnHidden()
end  
