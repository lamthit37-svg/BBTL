local g_Newserver_Hongbao_MBuy_Frame_UnifiedPosition  
local g_Newserver_Hongbao_MBuy_tblidx = -1;
local g_Newserver_Hongbao_MBuy_cxid = -1;
--===============================================
-- OnLoad()
--===============================================
function Newserver_Hongbao_MBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	--逻辑相关的事件
    this:RegisterEvent("OPEN_NSHB_M_BUY",true)  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Newserver_Hongbao_MBuy_OnLoad()
	g_Newserver_Hongbao_MBuy_Frame_UnifiedPosition	=	Newserver_Hongbao_MBuy_Frame:GetProperty("UnifiedPosition")
end 

--===============================================
-- OnEvent()
--===============================================
function Newserver_Hongbao_MBuy_OnEvent( event )
    if event == "OPEN_NSHB_M_BUY" then 
        g_Newserver_Hongbao_MBuy_tblidx = tonumber(arg0)   
        g_Newserver_Hongbao_MBuy_cxid   = tonumber(arg1)   
	    Newserver_Hongbao_MBuy_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        Newserver_Hongbao_MBuy_InputNum:SetText("1")					--默认输入为1   
        Newserver_Hongbao_MBuy_InputNum:SetSelected( 0, -1 ); 
        Newserver_Hongbao_MBuy_FreshWindow() 
        this:Show() 
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Newserver_Hongbao_MBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Newserver_Hongbao_MBuy_OnHidden()
	elseif event == "ADJEST_UI_POS" then
        Newserver_Hongbao_MBuy_Frame_On_ResetPos() 	 
	end
end

function Newserver_Hongbao_MBuy_Frame_On_ResetPos()
    Newserver_Hongbao_MBuy_Frame:SetProperty("UnifiedPosition", g_Newserver_Hongbao_MBuy_Frame_UnifiedPosition)
end

--===============================================
--刷新界面信息
--===============================================
function Newserver_Hongbao_MBuy_FreshWindow()  
    
    local hb_data = Lua_GetXinFuHongBaoDataInfo()
    if type(hb_data) ~= "table" then
        return
    end

    local hb_shop_info = Lua_GetXinFuHongBaoShopInfo()
    if type(hb_shop_info) ~= "table" then
        return
    end
    
    if hb_shop_info[g_Newserver_Hongbao_MBuy_tblidx].CXID ~= g_Newserver_Hongbao_MBuy_cxid then
        PushDebugMessage("cxid err")
        return
    end 

    local CurDaibi  = hb_data.Daibi
    local itemid    = hb_shop_info[g_Newserver_Hongbao_MBuy_tblidx].ItemID
    local Price     = hb_shop_info[g_Newserver_Hongbao_MBuy_tblidx].Price 
    local LimitNum  = hb_shop_info[g_Newserver_Hongbao_MBuy_tblidx].LimitNum
    local YunLan    = hb_shop_info[g_Newserver_Hongbao_MBuy_tblidx].YuLan
    local ZheKou    = hb_shop_info[g_Newserver_Hongbao_MBuy_tblidx].ZheKou 
    local curnum    = hb_data.BuyNum[g_Newserver_Hongbao_MBuy_cxid]
    --Lua_TDU_Log("itemid:"..itemid);
    --Lua_TDU_Log("Price:"..Price);
    --Lua_TDU_Log("LimitNum:"..LimitNum);
    --Lua_TDU_Log("YunLan:"..YunLan);
    --Lua_TDU_Log("ZheKou:"..ZheKou);
    --Lua_TDU_Log("curnum:"..curnum); 
    local theAction = DataPool:CreateBindActionItemForShow(itemid, 1)
    if theAction:GetID() ~= 0 then 
        Newserver_Hongbao_MBuy_But:SetActionItem(theAction:GetID()) 
        Newserver_Hongbao_MBuy_ItemInfo_Text:SetText(ScriptGlobal_Format("#{HBF_241219_39}",theAction:GetName()))
        Newserver_Hongbao_MBuy_ItemInfo_Daibi:SetText(ScriptGlobal_Format("#{HBF_241219_40}",Price))
    end  
    if ZheKou == 1 then
        Newserver_Hongbao_MBuy_But_Discount:Show()
    else
        Newserver_Hongbao_MBuy_But_Discount:Hide()
    end
    if LimitNum == -1  then
        Newserver_Hongbao_MBuy_But_Buy_LimitNum:SetText(0)  
        Newserver_Hongbao_MBuy_But_Buy_LimitNum:Hide()
    else
        Newserver_Hongbao_MBuy_But_Buy_LimitNum:SetText(LimitNum-curnum) 
        Newserver_Hongbao_MBuy_But_Buy_LimitNum:Show()
    end
    Newserver_Hongbao_MBuy_ItemInfo_Daibi:SetText(ScriptGlobal_Format("#{HBF_241219_40}",Price))
    Newserver_Hongbao_MBuy_Price_Daibi:SetText(ScriptGlobal_Format("#{HBF_241219_39}",Price*tonumber(Newserver_Hongbao_MBuy_InputNum:GetText()))) 
    Newserver_Hongbao_MBuy_Cash_Daibi:SetText(ScriptGlobal_Format("#{HBF_241219_39}",CurDaibi))  
end

--===============================================
--取出相应的物资
--===============================================
function Newserver_Hongbao_MBuy_OK_Clicked()
 
	local count = tonumber(Newserver_Hongbao_MBuy_InputNum:GetText())
	if count <= 0 then
		return
    end 
	Newserver_Hongbao_MBuy_BuyItem(count)
	--隐藏界面
	Newserver_Hongbao_MBuy_OnHidden()					
end

function Newserver_Hongbao_MBuy_BuyItem(count) 
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "Buy" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 501016 );								-- 脚本编号  
        Set_XSCRIPT_Parameter( 0, g_Newserver_Hongbao_MBuy_cxid );	 
        Set_XSCRIPT_Parameter( 1, count );	 
        Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
    Send_XSCRIPT()	
end

function Newserver_Hongbao_MBuy_GetBuyMaxNum()  
    local hb_data = Lua_GetXinFuHongBaoDataInfo()
    if type(hb_data) ~= "table" then
        return 0
    end

    local hb_shop_info = Lua_GetXinFuHongBaoShopInfo()
    if type(hb_shop_info) ~= "table" then
        return 0
    end
    local CurDaibi  = hb_data.Daibi
    local Price     = hb_shop_info[g_Newserver_Hongbao_MBuy_tblidx].Price
    if hb_shop_info[g_Newserver_Hongbao_MBuy_tblidx].CXID ~= g_Newserver_Hongbao_MBuy_cxid then
        PushDebugMessage("请重新打开界面")
        return 0
    end

    local curnum    = hb_data.BuyNum[g_Newserver_Hongbao_MBuy_cxid]
    local LimitNum  = hb_shop_info[g_Newserver_Hongbao_MBuy_tblidx].LimitNum

    local canbuynum = math.floor(CurDaibi/Price)

    if canbuynum > LimitNum - curnum and LimitNum ~= -1  then
        canbuynum = LimitNum - curnum
    end

    return canbuynum
end

function Newserver_Hongbao_MBuy_CalMax()    
    Newserver_Hongbao_MBuy_InputNum : SetText(Newserver_Hongbao_MBuy_GetBuyMaxNum())
    Newserver_Hongbao_MBuy_FreshWindow() 
end

function Newserver_Hongbao_MBuy_TextChanged() 
    local num = tonumber(Newserver_Hongbao_MBuy_InputNum:GetText());
	if(nil == num or(num and num < 0)) then 
        Newserver_Hongbao_MBuy_Price_Daibi:SetText("0") 
        Newserver_Hongbao_MBuy_InputNum:SetText("0") 
        return
    end

    local nbuynum = Newserver_Hongbao_MBuy_GetBuyMaxNum()    
    if num >=0 and num > nbuynum then
        Newserver_Hongbao_MBuy_InputNum : SetText(Newserver_Hongbao_MBuy_GetBuyMaxNum())
    end
    Newserver_Hongbao_MBuy_FreshWindow() 
end

function Newserver_Hongbao_MBuy_OnHidden()    
    g_Newserver_Hongbao_Tblidx = 1
    g_Newserver_Hongbao_CXID = 1
    this:Hide()
end

function Newserver_Hongbao_MBuy_Close_Clicked()
	Newserver_Hongbao_MBuy_OnHidden()
end  
