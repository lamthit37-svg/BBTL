local g_ActivitySchedule_MBuy_Frame_UnifiedPosition
local g_ActivitySchedule_MBuy_ItemIndex = 0
local g_ActivitySchedule_Type = 1
local g_ActivitySchedule_itemid = 0
local g_ActivitySchedule_MBuy_CurPage = 1
local g_ActivitySchedule_MBuy_PerPageCount = 20
--===============================================
-- OnLoad()
--===============================================
function ActivitySchedule_MBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	--逻辑相关的事件
    this:RegisterEvent("OPEN_HUOYUESHAOP_BUY_H",true)
    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function ActivitySchedule_MBuy_OnLoad()
	g_ActivitySchedule_MBuy_Frame_UnifiedPosition	=	ActivitySchedule_MBuy_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function ActivitySchedule_MBuy_OnEvent( event )
	if event == "OPEN_HUOYUESHAOP_BUY_H" then
        g_ActivitySchedule_MBuy_CurPage = tonumber(arg0) 
        g_ActivitySchedule_MBuy_ItemIndex = tonumber(arg1) 
        g_ActivitySchedule_MBuy_PerPageCount = tonumber(arg2) 
	    ActivitySchedule_MBuy_InputNumBK:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        ActivitySchedule_MBuy_InputNumBK:SetText("1")					--默认输入为1   
        ActivitySchedule_MBuy_InputNumBK:SetSelected( 0, -1 ); 
        ActivitySchedule_MBuy_FreshWindow(g_ActivitySchedule_MBuy_ItemIndex) 
        this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		ActivitySchedule_MBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ActivitySchedule_MBuy_Closed()
	elseif event == "ADJEST_UI_POS" then
		ActivitySchedule_MBuy_Frame_On_ResetPos() 		
	end
end

--===============================================
--刷新界面信息
--===============================================
function ActivitySchedule_MBuy_FreshWindow( index )
    local tblinfo= GetHuoYueShopData(g_ActivitySchedule_Type,g_ActivitySchedule_MBuy_CurPage,g_ActivitySchedule_MBuy_PerPageCount)
    local nhigh_total,  nlow_total = GetHuoYueShopDaiBiInfo()
    if type(tblinfo) ~= "table" or tblinfo[index] == nil then
		PushDebugMessage("error11")
		return
    end 
    local itemid 	    = tblinfo[index].itemid
    local itemnum 	    = tblinfo[index].itemnum
    local daibitype     = tblinfo[index].daibitype
    local daibinum      = tblinfo[index].daibinum
    local limitday      = tblinfo[index].limitday
    local limitday_self = tblinfo[index].limitday_self
    local limitweek     = tblinfo[index].limitweek
    local limitweek_self= tblinfo[index].limitweek_self
    local limitmonth    = tblinfo[index].limitmonth
    local limitmonth_self= tblinfo[index].limitmonth_self
    local limitfov      = tblinfo[index].limitfov
    local limitfov_self = tblinfo[index].limitfov_self
    local yulan         = tblinfo[index].yulan
    local huoyueweek    = tblinfo[index].huoyueweek
    local isshowunbind    = tblinfo[index].isshowunbind

    g_ActivitySchedule_itemid = itemid
    local	nBuyNum	=	0
	if ActivitySchedule_MBuy_InputNumBK:GetText() ~= '' then
		nBuyNum	=	tonumber(ActivitySchedule_MBuy_InputNumBK:GetText())
    end 
	local	theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
	if theAction:GetID() ~= 0 then
		ActivitySchedule_MBuy_Item:SetActionItem(theAction:GetID())
		ActivitySchedule_MBuy_Item:Show()
    end
    
    if isshowunbind == 1 then
        ActivitySchedule_MBuy_Item_Feibang:Show()
    else
        ActivitySchedule_MBuy_Item_Feibang:Hide()
    end

    local nhavenum = 0 
    if limitday == 0 and limitweek == 0 and limitmonth == 0 and limitfov == 0 then
        ActivitySchedule_MBuy_Item_BuyLimitNumBK:Hide()
        ActivitySchedule_MBuy_Item_Mask:Hide()
    elseif limitday > 0 then 
        nhavenum = limitday_self 
    elseif limitweek > 0 then 
        nhavenum = limitweek_self 
    elseif limitmonth > 0 then 
        nhavenum = limitmonth_self 
    elseif limitfov > 0 then 
        nhavenum = limitfov_self
    end

    if (limitday > 0 or limitweek > 0 or limitmonth > 0 or limitfov > 0 ) then
        if nhavenum > 0 then
            ActivitySchedule_MBuy_Item_BuyLimitNum:SetText(nhavenum)
            ActivitySchedule_MBuy_Item_BuyLimitNumBK:Show()
            ActivitySchedule_MBuy_Item_Mask:Hide()
        else
            ActivitySchedule_MBuy_Item_BuyLimitNumBK:Hide()
            ActivitySchedule_MBuy_Item_Mask:Show()
        end        
        if limitday > 0 then
            ActivitySchedule_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day") 
        elseif limitweek > 0 then
            ActivitySchedule_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week") 
        elseif limitmonth > 0 then
            ActivitySchedule_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Month") 
        elseif limitfov > 0 then
            ActivitySchedule_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever")  
        end
        ActivitySchedule_MBuy_Item_BuyLimit:Show()
    else
        ActivitySchedule_MBuy_Item_BuyLimitNumBK:Hide()
        ActivitySchedule_MBuy_Item_Mask:Hide()        
        ActivitySchedule_MBuy_Item_BuyLimit:Hide()
    end
 

    ActivitySchedule_MBuy_ItemInfo_Text:SetText(ScriptGlobal_Format("#{HYCT_20210629_12}",DataPool:Lua_GetItemNameByIndex(itemid)))
    if daibitype == 1 then
        ActivitySchedule_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format("#{HYCT_20210629_14}",daibinum))         
        if daibinum*nBuyNum > nhigh_total or nBuyNum == 0 then
            ActivitySchedule_MBuy_Price:SetText("#{HYCT_20210629_19}")
            ActivitySchedule_MBuy_PriceNum:SetText("#cff0000"..daibinum*nBuyNum)
            ActivitySchedule_MBuy_Cash:SetText("#{HYCT_20210629_22}")
            ActivitySchedule_MBuy_CashNum:SetText(nhigh_total)            
            ActivitySchedule_MBuy_Submit:Disable()
        else 
            ActivitySchedule_MBuy_Price:SetText("#{HYCT_20210629_19}") 
            ActivitySchedule_MBuy_PriceNum:SetText("#G"..daibinum*nBuyNum)
            ActivitySchedule_MBuy_Cash:SetText("#{HYCT_20210629_22}")
            ActivitySchedule_MBuy_CashNum:SetText(nhigh_total)
            ActivitySchedule_MBuy_Submit:Enable()
        end
    else
        ActivitySchedule_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format("#{HYCT_20210629_13}",daibinum))  
        if daibinum*nBuyNum > nlow_total or nBuyNum == 0 then 
            ActivitySchedule_MBuy_Price:SetText("#{HYCT_20210629_18}")
            ActivitySchedule_MBuy_PriceNum:SetText("#cff0000"..daibinum*nBuyNum)             
            ActivitySchedule_MBuy_Cash:SetText("#{HYCT_20210629_21}") 
            ActivitySchedule_MBuy_CashNum:SetText(nlow_total)        
            ActivitySchedule_MBuy_Submit:Disable()
        else 
            ActivitySchedule_MBuy_Price:SetText("#{HYCT_20210629_18}")
            ActivitySchedule_MBuy_PriceNum:SetText("#G"..daibinum*nBuyNum)     
            ActivitySchedule_MBuy_Cash:SetText("#{HYCT_20210629_21}") 
            ActivitySchedule_MBuy_CashNum:SetText(nlow_total)
            ActivitySchedule_MBuy_Submit:Enable()
        end
    end     
end



--===============================================
--取出相应的物资
--===============================================
function ActivitySchedule_MBuy_OK_Clicked()
 
	local count = tonumber(ActivitySchedule_MBuy_InputNumBK:GetText())
	if count <= 0 then
		return
    end 
	ActivitySchedule_MBuy_BuyItem(g_ActivitySchedule_itemid, count)
	--隐藏界面
	this:Hide()					
end

function ActivitySchedule_MBuy_BuyItem(itemid,count)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "BuyItem" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 888393 );											-- 脚本编号  
        Set_XSCRIPT_Parameter( 0, -1 );	
        Set_XSCRIPT_Parameter( 1, g_ActivitySchedule_Type );		     
        Set_XSCRIPT_Parameter( 2, itemid );	 
        Set_XSCRIPT_Parameter( 3, count );			 
        Set_XSCRIPT_ParamCount( 4 ); 	-- 参数个数  
    Send_XSCRIPT()	
end
function ActivitySchedule_MBuy_GetBuyMaxNum()
    local tblinfo= GetHuoYueShopData(g_ActivitySchedule_Type,g_ActivitySchedule_MBuy_CurPage,g_ActivitySchedule_MBuy_PerPageCount)
    local nhigh_total, nlow_total = GetHuoYueShopDaiBiInfo()
    if type(tblinfo) ~= "table" or tblinfo[g_ActivitySchedule_MBuy_ItemIndex] == nil then
		PushDebugMessage("error222")
		return
    end 
    local itemid 	    = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].itemid
    local itemnum 	    = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].itemnum
    local daibitype     = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].daibitype
    local daibinum      = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].daibinum
    local limitday      = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].limitday
    local limitday_self = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].limitday_self
    local limitweek     = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].limitweek
    local limitweek_self= tblinfo[g_ActivitySchedule_MBuy_ItemIndex].limitweek_self
    local limitmonth    = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].limitmonth
    local limitmonth_self= tblinfo[g_ActivitySchedule_MBuy_ItemIndex].limitmonth_self
    local limitfov      = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].limitfov
    local limitfov_self = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].limitfov_self
    local yulan         = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].yulan
    local huoyueweek    = tblinfo[g_ActivitySchedule_MBuy_ItemIndex].huoyueweek
    local ndaibicount   = 0
	local	nBuyNum	=	0
    if daibitype == 1 then 
        ndaibicount = nhigh_total; 
    else   
        ndaibicount = nlow_total; 
    end
    local nislimit = 0
    local limitnum = 0
    if limitday == 0 and limitweek == 0 and limitmonth == 0 and limitfov == 0 then
        nislimit = 0
    elseif limitday > 0 then
        nislimit = 1
        limitnum =limitday_self
    elseif limitweek > 0 then
        nislimit = 1
        limitnum =limitweek_self
    elseif limitmonth > 0 then
        nislimit = 1
        limitnum =limitmonth_self
    elseif limitfov > 0 then
        nislimit = 1
        limitnum =limitfov_self    
    end 
	--计算最大能领取数量 
    return HuoYueShopCalcMaxNumCanBuy(itemid,itemnum,g_ActivitySchedule_Type,ndaibicount,daibinum,nislimit,limitnum,0,1)
end
function ActivitySchedule_MBuy_CalMax()    
	ActivitySchedule_MBuy_InputNumBK : SetText(ActivitySchedule_MBuy_GetBuyMaxNum())
end

function ActivitySchedule_MBuy_TextChanged() 
    ActivitySchedule_MBuy_FreshWindow(g_ActivitySchedule_MBuy_ItemIndex) 
end

function ActivitySchedule_MBuy_OnHidden()    
	this:Hide()
end
function ActivitySchedule_MBuy_CancelClicked()
	this:Hide()
end
--===============================================
--关闭界面
--===============================================
function ActivitySchedule_MBuy_Closed()
	this:Hide()
end
function ActivitySchedule_MBuy_Close_Clicked()
	this:Hide()
end
function ActivitySchedule_MBuy_Frame_On_ResetPos()
	 ActivitySchedule_MBuy_Frame:SetProperty("UnifiedPosition", g_ActivitySchedule_MBuy_Frame_UnifiedPosition)
end
