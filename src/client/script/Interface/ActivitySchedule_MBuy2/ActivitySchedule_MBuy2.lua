local g_ActivitySchedule_MBuy2_Frame_UnifiedPosition
local g_ActivitySchedule_Type = 2
local g_ActivitySchedule_itemid = 0
local g_ActivitySchedule_MBuy2_CurPage = 0
local g_ActivitySchedule_MBuy2_ItemIndex = 0
local g_ActivitySchedule_MBuy2_PerPageCount = 0
local g_ActivitySchedule_MBuy2_TargetId = -1

--===============================================
-- OnLoad()
--===============================================
function ActivitySchedule_MBuy2_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--逻辑相关的事件
	this:RegisterEvent("OPEN_HUOYUESHAOP_BUY_L",true)    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

function ActivitySchedule_MBuy2_OnLoad()
	g_ActivitySchedule_MBuy2_Frame_UnifiedPosition	=	ActivitySchedule_MBuy2_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function ActivitySchedule_MBuy2_OnEvent( event )
	if event == "OPEN_HUOYUESHAOP_BUY_L" then
        g_ActivitySchedule_MBuy2_CurPage = tonumber(arg0) 
        g_ActivitySchedule_MBuy2_ItemIndex = tonumber(arg1) 
        g_ActivitySchedule_MBuy2_PerPageCount = tonumber(arg2) 
        g_ActivitySchedule_MBuy2_TargetId = tonumber(arg3) 
	    ActivitySchedule_MBuy2_InputNumBK:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        ActivitySchedule_MBuy2_InputNumBK:SetText("1")					--默认输入为1   
        ActivitySchedule_MBuy2_InputNumBK:SetSelected( 0, -1 ); 
        ActivitySchedule_MBuy2_FreshWindow(g_ActivitySchedule_MBuy2_ItemIndex) 
        -- objCared = DataPool : GetNPCIDByServerID(g_ActivitySchedule_MBuy2_TargetId)
        -- this:CareObject(objCared, 1, "ActivitySchedule_MBuy2");	
		this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		ActivitySchedule_MBuy2_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ActivitySchedule_MBuy2_Closed()
	elseif event == "ADJEST_UI_POS" then
		ActivitySchedule_MBuy2_Frame_On_ResetPos() 		
    -- elseif (event == "OBJECT_CARED_EVENT") then
	-- 	if(tonumber(arg0) ~= objCared) then
	-- 		return;
	-- 	end
	-- 	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	-- 	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
	-- 		this:Hide();
	-- 		--取消关心
	-- 		this:CareObject(objCared, 0, "ActivitySchedule_Shop2");
	-- 	end	
	end
end

--===============================================
--刷新界面信息
--===============================================
function ActivitySchedule_MBuy2_FreshWindow( index )
    local tblinfo= GetHuoYueShopData(g_ActivitySchedule_Type,g_ActivitySchedule_MBuy2_CurPage,g_ActivitySchedule_MBuy2_PerPageCount)
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
	if ActivitySchedule_MBuy2_InputNumBK:GetText() ~= '' then
		nBuyNum	=	tonumber(ActivitySchedule_MBuy2_InputNumBK:GetText())
    end 
	local	theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
	if theAction:GetID() ~= 0 then
		ActivitySchedule_MBuy2_Item:SetActionItem(theAction:GetID())
		ActivitySchedule_MBuy2_Item:Show()
    end
    
    if isshowunbind == 1 then
        ActivitySchedule_MBuy2_Item_Feibang:Show()
    else
        ActivitySchedule_MBuy2_Item_Feibang:Hide()
    end

    local nhavenum = 0 
    if limitday == 0 and limitweek == 0 and limitmonth == 0 and limitfov == 0 then
        ActivitySchedule_MBuy2_Item_BuyLimitNumBK:Hide()
        ActivitySchedule_MBuy2_Item_Mask:Hide()
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
            ActivitySchedule_MBuy2_Item_BuyLimitNum:SetText(nhavenum)
            ActivitySchedule_MBuy2_Item_BuyLimitNumBK:Show()
            ActivitySchedule_MBuy2_Item_Mask:Hide()
        else
            ActivitySchedule_MBuy2_Item_BuyLimitNumBK:Hide()
            ActivitySchedule_MBuy2_Item_Mask:Show()
        end        
        if limitday > 0 then
            ActivitySchedule_MBuy2_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day") 
        elseif limitweek > 0 then
            ActivitySchedule_MBuy2_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week") 
        elseif limitmonth > 0 then
            ActivitySchedule_MBuy2_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Month") 
        elseif limitfov > 0 then
            ActivitySchedule_MBuy2_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever")  
        end
        ActivitySchedule_MBuy2_Item_BuyLimit:Show()
    else
        ActivitySchedule_MBuy2_Item_BuyLimitNumBK:Hide()
        ActivitySchedule_MBuy2_Item_Mask:Hide()        
        ActivitySchedule_MBuy2_Item_BuyLimit:Hide()
    end
    ActivitySchedule_MBuy2_ItemInfo_Text:SetText(ScriptGlobal_Format("#{HYCT_20210629_12}",DataPool:Lua_GetItemNameByIndex(itemid)))
    if daibitype == 1 then
        ActivitySchedule_MBuy2_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format("#{HYCT_20210629_14}",daibinum))         
        if daibinum*nBuyNum > nhigh_total or nBuyNum == 0 then
            ActivitySchedule_MBuy2_Price:SetText("#{HYCT_20210629_19}")
            ActivitySchedule_MBuy2_PriceNum:SetText("#cff0000"..daibinum*nBuyNum)
            ActivitySchedule_MBuy2_Cash:SetText("#{HYCT_20210629_22}")
            ActivitySchedule_MBuy2_CashNum:SetText(nhigh_total)            
            ActivitySchedule_MBuy2_Submit:Disable()
        else 
            ActivitySchedule_MBuy2_Price:SetText("#{HYCT_20210629_19}") 
            ActivitySchedule_MBuy2_PriceNum:SetText("#G"..daibinum*nBuyNum)
            ActivitySchedule_MBuy2_Cash:SetText("#{HYCT_20210629_22}")
            ActivitySchedule_MBuy2_CashNum:SetText(nhigh_total)
            ActivitySchedule_MBuy2_Submit:Enable()
        end
    else
        ActivitySchedule_MBuy2_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format("#{HYCT_20210629_13}",daibinum))  
        if daibinum*nBuyNum > nlow_total or nBuyNum == 0 then 
            ActivitySchedule_MBuy2_Price:SetText("#{HYCT_20210629_18}")
            ActivitySchedule_MBuy2_PriceNum:SetText("#cff0000"..daibinum*nBuyNum)             
            ActivitySchedule_MBuy2_Cash:SetText("#{HYCT_20210629_21}") 
            ActivitySchedule_MBuy2_CashNum:SetText(nlow_total)        
            ActivitySchedule_MBuy2_Submit:Disable()
        else 
            ActivitySchedule_MBuy2_Price:SetText("#{HYCT_20210629_18}")
            ActivitySchedule_MBuy2_PriceNum:SetText("#G"..daibinum*nBuyNum)     
            ActivitySchedule_MBuy2_Cash:SetText("#{HYCT_20210629_21}") 
            ActivitySchedule_MBuy2_CashNum:SetText(nlow_total)
            ActivitySchedule_MBuy2_Submit:Enable()
        end
    end     
end



--===============================================
--取出相应的物资
--===============================================
function ActivitySchedule_MBuy2_OK_Clicked()
 
	local count = tonumber(ActivitySchedule_MBuy2_InputNumBK:GetText())
	if count <= 0 then
		return
    end 
	ActivitySchedule_MBuy2_BuyItem(g_ActivitySchedule_itemid, count)
	--隐藏界面
	this:Hide()					
end

function ActivitySchedule_MBuy2_BuyItem(itemid,count)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "BuyItem" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 888393 );											-- 脚本编号 
        Set_XSCRIPT_Parameter( 0, g_ActivitySchedule_MBuy2_TargetId );	
        Set_XSCRIPT_Parameter( 1, g_ActivitySchedule_Type );		     
        Set_XSCRIPT_Parameter( 2, itemid );	 
        Set_XSCRIPT_Parameter( 3, count );			 
        Set_XSCRIPT_ParamCount( 4 ); 	-- 参数个数  
    Send_XSCRIPT()	
end
function ActivitySchedule_MBuy2_GetBuyMaxNum()
    local tblinfo= GetHuoYueShopData(g_ActivitySchedule_Type,g_ActivitySchedule_MBuy2_CurPage,g_ActivitySchedule_MBuy2_PerPageCount)
    local nhigh_total, nlow_total = GetHuoYueShopDaiBiInfo()
    if type(tblinfo) ~= "table" or tblinfo[g_ActivitySchedule_MBuy2_ItemIndex] == nil then
		PushDebugMessage("error222")
		return
    end 
    local itemid 	    = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].itemid
    local itemnum 	    = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].itemnum
    local daibitype     = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].daibitype
    local daibinum      = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].daibinum
    local limitday      = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].limitday
    local limitday_self = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].limitday_self
    local limitweek     = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].limitweek
    local limitweek_self= tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].limitweek_self
    local limitmonth    = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].limitmonth
    local limitmonth_self= tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].limitmonth_self
    local limitfov      = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].limitfov
    local limitfov_self = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].limitfov_self
    local yulan         = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].yulan
    local huoyueweek    = tblinfo[g_ActivitySchedule_MBuy2_ItemIndex].huoyueweek
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
    return HuoYueShopCalcMaxNumCanBuy(itemid,itemnum,g_ActivitySchedule_Type,ndaibicount,daibinum,nislimit,limitnum,0,0)
end
function ActivitySchedule_MBuy2_CalMax()    
	ActivitySchedule_MBuy2_InputNumBK : SetText(ActivitySchedule_MBuy2_GetBuyMaxNum())
end

function ActivitySchedule_MBuy2_TextChanged() 
    ActivitySchedule_MBuy2_FreshWindow(g_ActivitySchedule_MBuy2_ItemIndex) 
end

function ActivitySchedule_MBuy2_OnHidden()    
	this:Hide()
end
function ActivitySchedule_MBuy2_CancelClicked()
	this:Hide()
end
--===============================================
--关闭界面
--===============================================
function ActivitySchedule_MBuy2_Closed()
	this:Hide()
end
function ActivitySchedule_MBuy2_Close_Clicked()
	this:Hide()
end
function ActivitySchedule_MBuy2_Frame_On_ResetPos()
	 ActivitySchedule_MBuy2_Frame:SetProperty("UnifiedPosition", g_ActivitySchedule_MBuy2_Frame_UnifiedPosition)
end
