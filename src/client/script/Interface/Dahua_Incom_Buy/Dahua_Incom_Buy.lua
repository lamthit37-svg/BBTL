local g_Dahua_Incom_Buy_Frame_UnifiedPosition 
local g_Dahua_Incom_Buy_DaiBi = 0
local g_Dahua_Incom_Buy_PerDaibi_Cost = 698
--===============================================
-- OnLoad()
--===============================================
function Dahua_Incom_Buy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	--逻辑相关的事件
    this:RegisterEvent("OPEN_DAHUA_BUY",true)
    this:RegisterEvent("UPDATE_YUANBAO",true)
    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Dahua_Incom_Buy_OnLoad()
	g_Dahua_Incom_Buy_Frame_UnifiedPosition	=	Dahua_Incom_Buy_Frame:GetProperty("UnifiedPosition")
end 

--===============================================
-- OnEvent()
--===============================================
function Dahua_Incom_Buy_OnEvent( event )
	if event == "OPEN_DAHUA_BUY" then
        g_Dahua_Incom_Buy_DaiBi = tonumber(arg0)   
	    Dahua_Incom_Buy_Moral_Value:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        Dahua_Incom_Buy_Moral_Value:SetText("1")					--默认输入为1   
        Dahua_Incom_Buy_Moral_Value:SetSelected( 0, -1 ); 
        Dahua_Incom_Buy_FreshWindow() 
        this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Dahua_Incom_Buy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Dahua_Incom_Buy_OnHidden()
	elseif event == "ADJEST_UI_POS" then
        Dahua_Incom_Buy_Frame_On_ResetPos() 	
    elseif event == "UPDATE_YUANBAO" then
        local nYuanBao = Player:GetData("YUANBAO")
        Dahua_Incom_Buy_HaveYB:SetText(tonumber(nYuanBao)) 	
	end
end

function Dahua_Incom_Buy_Frame_On_ResetPos()
    Dahua_Incom_Buy_Frame:SetProperty("UnifiedPosition", g_Dahua_Incom_Buy_Frame_UnifiedPosition)
end

--===============================================
--刷新界面信息
--===============================================
function Dahua_Incom_Buy_FreshWindow() 
    local nYuanBao = Player:GetData("YUANBAO")
    local nNeedYuanBao = g_Dahua_Incom_Buy_PerDaibi_Cost*tonumber(Dahua_Incom_Buy_Moral_Value:GetText())
    Dahua_Incom_Buy_HaveYB:SetText(tonumber(nYuanBao))
    
    if nNeedYuanBao > nYuanBao then
        Dahua_Incom_Buy_SpendYB:SetText("#cff0000"..nNeedYuanBao)  
    else
        Dahua_Incom_Buy_SpendYB:SetText(nNeedYuanBao)  
    end
    local theAction = DataPool:CreateBindActionItemForShow(38006877, 1)
    if theAction:GetID() ~= 0 then 
        Dahua_Incom_Buy_Item:SetActionItem(theAction:GetID()) 
        Dahua_Incom_Buy_Text4:SetText(theAction:GetName())
        Dahua_Incom_Buy_NeedYB:SetText(ScriptGlobal_Format("#{DHLS_240611_88}",g_Dahua_Incom_Buy_PerDaibi_Cost))
    end  
end

--===============================================
--取出相应的物资
--===============================================
function Dahua_Incom_Buy_OK_Clicked()
 
	local count = tonumber(Dahua_Incom_Buy_Moral_Value:GetText())
	if count <= 0 then
		return
    end 
	Dahua_Incom_Buy_BuyItem(count)
	--隐藏界面
	Dahua_Incom_Buy_OnHidden()					
end

function Dahua_Incom_Buy_BuyItem(count)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "BuyDaiBi" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 501003 );								-- 脚本编号  
        Set_XSCRIPT_Parameter( 0, count );	 
        Set_XSCRIPT_Parameter( 1, 0 );	 
        Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
    Send_XSCRIPT()	
end

function Dahua_Incom_Buy_GetBuyMaxNum() 
    local nYuanBao = Player:GetData("YUANBAO")
    return math.floor(nYuanBao/g_Dahua_Incom_Buy_PerDaibi_Cost)
end

function Dahua_Incom_Buy_Max_Clicked()    
    Dahua_Incom_Buy_Moral_Value : SetText(Dahua_Incom_Buy_GetBuyMaxNum())
    Dahua_Incom_Buy_FreshWindow() 
end

function Dahua_Incom_Buy_Count_Change() 
    local num = tonumber(Dahua_Incom_Buy_Moral_Value:GetText());
	if(nil == num or(num and num < 0)) then 
        Dahua_Incom_Buy_SpendYB:SetText("0") 
        Dahua_Incom_Buy_Moral_Value:SetText("0") 
        return
	end
    Dahua_Incom_Buy_FreshWindow() 
end

function Dahua_Incom_Buy_OnHidden()    
	this:Hide()
end

function Dahua_Incom_Buy_Cancel_Clicked()
	this:Hide()
end  
