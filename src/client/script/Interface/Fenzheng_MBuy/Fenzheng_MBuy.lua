local g_Fenzheng_MBuy_Frame_UnifiedPosition
local g_Fenzheng_MBuy_Shop_Type = 2
local g_Fenzheng_MBuy_ItemId = 0
local g_Fenzheng_MBuy_CurPage = 0
local g_Fenzheng_MBuy_ItemIndex = 0
local g_Fenzheng_MBuy_PerPageCount = 0
local g_Fenzheng_MBuy_TargetId = -1

local g_Fenzheng_MBuy_TypeCountMax = 4

local g_Fenzheng_MBuy_Dict = 
{
	[1] = {daibiname = "#{PVPZH_220124_106}",shownum = "#{PVPZH_220124_20}", need = "#{PVPZH_220124_22}", have = "#{PVPZH_220124_26}", },
	[2] = {daibiname = "#{PVPZH_220124_105}",shownum = "#{PVPZH_220124_82}", need = "#{PVPZH_220124_83}", have = "#{PVPZH_220124_84}", },
	[3] = {daibiname = "#{ZCSD_20240204_53}",shownum = "#{ZCSD_20240204_37}", need = "#{ZCSD_20240204_49}", have = "#{ZCSD_20240204_51}", },
	[4] = {daibiname = "#{ZCSD_20240204_52}",shownum = "#{ZCSD_20240204_36}", need = "#{ZCSD_20240204_48}", have = "#{ZCSD_20240204_50}", },
}

--===============================================
-- OnLoad()
--===============================================
function Fenzheng_MBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--逻辑相关的事件
	this:RegisterEvent("OPEN_PVPSHOP_BUY",true)    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

function Fenzheng_MBuy_OnLoad()
	g_Fenzheng_MBuy_Frame_UnifiedPosition	=	Fenzheng_MBuy_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function Fenzheng_MBuy_OnEvent( event )
	if event == "OPEN_PVPSHOP_BUY" then

        g_Fenzheng_MBuy_CurPage = tonumber(arg0) 
        g_Fenzheng_MBuy_ItemIndex = tonumber(arg1) 
        g_Fenzheng_MBuy_PerPageCount = tonumber(arg2) 
        -- g_Fenzheng_MBuy_TargetId = tonumber(arg3) 
		g_Fenzheng_MBuy_Shop_Type = tonumber(arg4)  
		
		if g_Fenzheng_MBuy_Shop_Type < 0 or g_Fenzheng_MBuy_Shop_Type > g_Fenzheng_MBuy_TypeCountMax then
			return
		end
		
	    Fenzheng_MBuy_InputNumBK:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        Fenzheng_MBuy_InputNumBK:SetText("1")					--默认输入为1   
        Fenzheng_MBuy_InputNumBK:SetSelected( 0, -1 ); 
        Fenzheng_MBuy_FreshWindow(g_Fenzheng_MBuy_ItemIndex) 
        -- objCared = DataPool : GetNPCIDByServerID(g_Fenzheng_MBuy_TargetId)
        -- this:CareObject(objCared, 1, "Fenzheng_MBuy");	
		this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Fenzheng_MBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Fenzheng_MBuy_Closed()
	elseif event == "ADJEST_UI_POS" then
		Fenzheng_MBuy_Frame_On_ResetPos() 		
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
function Fenzheng_MBuy_FreshWindow( index )
    local tblinfo= GetPVPEShopData(g_Fenzheng_MBuy_Shop_Type,g_Fenzheng_MBuy_CurPage,g_Fenzheng_MBuy_PerPageCount)
	local curDaibiTotal = {}
	curDaibiTotal[1],_1,_2,_11,_12 = GetPVPShopDaiBi1Info()
	curDaibiTotal[2],_3,_4,_13,_14 = GetPVPShopDaiBi2Info()
	curDaibiTotal[3],_5,_6,_15,_16 = GetPVEShopDaiBi1Info()
	curDaibiTotal[4],_7,_8,_17,_18 = GetPVEShopDaiBi2Info()
    if type(tblinfo) ~= "table" or tblinfo[index] == nil then
		PushDebugMessage("error11")
		return
    end 
    local itemid 	    = tblinfo[index].itemid
	local itemnum 	    = tblinfo[index].itemnum
	local itemname     = tblinfo[index].itemname
	local price      = tblinfo[index].price
	local limitday      = tblinfo[index].limitday
	local limitday_self = tblinfo[index].limitday_self
	local limitweek     = tblinfo[index].limitweek
	local limitweek_self= tblinfo[index].limitweek_self
	local limitmonth    = tblinfo[index].limitmonth
	local limitmonth_self= tblinfo[index].limitmonth_self
	local limitpermanent      = tblinfo[index].limitpermanent
	local limitpermanent_self = tblinfo[index].limitpermanent_self

    g_Fenzheng_MBuy_ItemId = itemid
    local	nBuyNum	=	0
	if Fenzheng_MBuy_InputNumBK:GetText() ~= '' then
		nBuyNum	=	tonumber(Fenzheng_MBuy_InputNumBK:GetText())
    end 
	local	theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
	if theAction:GetID() ~= 0 then
		Fenzheng_MBuy_Item:SetActionItem(theAction:GetID())
		Fenzheng_MBuy_Item:Show()
    end
    
    local nhavenum = 0 
    if limitday < 0 and limitweek < 0 and limitmonth < 0 and limitpermanent < 0 then
        Fenzheng_MBuy_Item_BuyLimitNumBK:Hide()
        Fenzheng_MBuy_Item_Mask:Hide()
    elseif limitday > 0 then 
        nhavenum = limitday_self 
    elseif limitweek > 0 then 
        nhavenum = limitweek_self 
    elseif limitmonth > 0 then 
        nhavenum = limitmonth_self 
    elseif limitpermanent > 0 then 
        nhavenum = limitpermanent_self
    end

    if (limitday > 0 or limitweek > 0 or limitmonth > 0 or limitpermanent > 0 ) then
        if nhavenum > 0 then
            Fenzheng_MBuy_Item_BuyLimitNum:SetText(nhavenum)
            Fenzheng_MBuy_Item_BuyLimitNumBK:Show()
            Fenzheng_MBuy_Item_Mask:Hide()
        else
            Fenzheng_MBuy_Item_BuyLimitNumBK:Hide()
            Fenzheng_MBuy_Item_Mask:Show()
        end        
        if limitday > 0 then
            Fenzheng_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day") 
        elseif limitweek > 0 then
            Fenzheng_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week") 
        elseif limitmonth > 0 then
            Fenzheng_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Month") 
        elseif limitpermanent > 0 then
            Fenzheng_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever")  
        end
        Fenzheng_MBuy_Item_BuyLimit:Show()
    else
        Fenzheng_MBuy_Item_BuyLimitNumBK:Hide()
        Fenzheng_MBuy_Item_Mask:Hide()        
        Fenzheng_MBuy_Item_BuyLimit:Hide()
    end
    Fenzheng_MBuy_ItemInfo_Text:SetText(ScriptGlobal_Format("#{PVPZH_220124_19}",DataPool:Lua_GetItemNameByIndex(itemid)))

    Fenzheng_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format(g_Fenzheng_MBuy_Dict[g_Fenzheng_MBuy_Shop_Type].shownum,price))  
    if price*nBuyNum > curDaibiTotal[g_Fenzheng_MBuy_Shop_Type] or nBuyNum == 0 then 
        Fenzheng_MBuy_Price:SetText(g_Fenzheng_MBuy_Dict[g_Fenzheng_MBuy_Shop_Type].need)
        Fenzheng_MBuy_PriceNum:SetText("#cff0000"..price*nBuyNum)             
        Fenzheng_MBuy_Cash:SetText(g_Fenzheng_MBuy_Dict[g_Fenzheng_MBuy_Shop_Type].have) 
        Fenzheng_MBuy_CashNum:SetText(curDaibiTotal[g_Fenzheng_MBuy_Shop_Type])        
        Fenzheng_MBuy_Submit:Disable()
    else 
        Fenzheng_MBuy_Price:SetText(g_Fenzheng_MBuy_Dict[g_Fenzheng_MBuy_Shop_Type].need)
        Fenzheng_MBuy_PriceNum:SetText("#G"..price*nBuyNum)     
        Fenzheng_MBuy_Cash:SetText(g_Fenzheng_MBuy_Dict[g_Fenzheng_MBuy_Shop_Type].have) 
        Fenzheng_MBuy_CashNum:SetText(curDaibiTotal[g_Fenzheng_MBuy_Shop_Type])
        Fenzheng_MBuy_Submit:Enable()
    end

end



--===============================================
--取出相应的物资
--===============================================
function Fenzheng_MBuy_OK_Clicked()
 
	local count = tonumber(Fenzheng_MBuy_InputNumBK:GetText())
	if count <= 0 then
		return
    end 
	Fenzheng_MBuy_BuyItem(g_Fenzheng_MBuy_ItemId, count)
	--隐藏界面
	this:Hide()					
end

function Fenzheng_MBuy_BuyItem(itemid,count)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "BuyItem" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 888969 );											-- 脚本编号 
        Set_XSCRIPT_Parameter( 0, g_Fenzheng_MBuy_TargetId );	
        Set_XSCRIPT_Parameter( 1, g_Fenzheng_MBuy_Shop_Type );		     
        Set_XSCRIPT_Parameter( 2, itemid );	 
        Set_XSCRIPT_Parameter( 3, count );
		Set_XSCRIPT_Parameter( 4, g_Fenzheng_MBuy_CurPage );				 
        Set_XSCRIPT_ParamCount( 5 ); 	-- 参数个数  
    Send_XSCRIPT()	
end
function Fenzheng_MBuy_GetBuyMaxNum()
    local tblinfo= GetPVPEShopData(g_Fenzheng_MBuy_Shop_Type,g_Fenzheng_MBuy_CurPage,g_Fenzheng_MBuy_PerPageCount)
    local curDaibiTotal = {}
	curDaibiTotal[1],_1,_2,_11,_12 = GetPVPShopDaiBi1Info()
	curDaibiTotal[2],_3,_4,_13,_14 = GetPVPShopDaiBi2Info()
	curDaibiTotal[3],_5,_6,_15,_16 = GetPVEShopDaiBi1Info()
	curDaibiTotal[4],_7,_8,_17,_18 = GetPVEShopDaiBi2Info()
    if type(tblinfo) ~= "table" or tblinfo[g_Fenzheng_MBuy_ItemIndex] == nil then
		PushDebugMessage("error222")
		return
    end 
    local itemid 	    = tblinfo[g_Fenzheng_MBuy_ItemIndex].itemid
    local itemnum 	    = tblinfo[g_Fenzheng_MBuy_ItemIndex].itemnum
    local price     = tblinfo[g_Fenzheng_MBuy_ItemIndex].price
    local limitday      = tblinfo[g_Fenzheng_MBuy_ItemIndex].limitday
    local limitday_self = tblinfo[g_Fenzheng_MBuy_ItemIndex].limitday_self
    local limitweek     = tblinfo[g_Fenzheng_MBuy_ItemIndex].limitweek
    local limitweek_self= tblinfo[g_Fenzheng_MBuy_ItemIndex].limitweek_self
    local limitmonth    = tblinfo[g_Fenzheng_MBuy_ItemIndex].limitmonth
    local limitmonth_self= tblinfo[g_Fenzheng_MBuy_ItemIndex].limitmonth_self
    local limitpermanent      = tblinfo[g_Fenzheng_MBuy_ItemIndex].limitpermanent
    local limitpermanent_self = tblinfo[g_Fenzheng_MBuy_ItemIndex].limitpermanent_self


    local ndaibicount   = curDaibiTotal[g_Fenzheng_MBuy_Shop_Type]
	local	nBuyNum	=	0

    local nislimit = 0
    local limitnum = 0
    if limitday < 0 and limitweek < 0 and limitmonth < 0 and limitpermanent < 0 then
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
    elseif limitpermanent > 0 then
        nislimit = 1
        limitnum =limitpermanent_self    
    end 
	--计算最大能领取数量 
    return PVPShopCalcMaxNumCanBuy(itemid,itemnum,g_Fenzheng_MBuy_Shop_Type,ndaibicount,price,nislimit,limitnum,0,0)
end
function Fenzheng_MBuy_CalMax()    
	Fenzheng_MBuy_InputNumBK : SetText(Fenzheng_MBuy_GetBuyMaxNum())
end

function Fenzheng_MBuy_TextChanged() 
    Fenzheng_MBuy_FreshWindow(g_Fenzheng_MBuy_ItemIndex) 
end

function Fenzheng_MBuy_OnHidden()    
	this:Hide()
end
function Fenzheng_MBuy_CancelClicked()
	this:Hide()
end
--===============================================
--关闭界面
--===============================================
function Fenzheng_MBuy_Closed()
	this:Hide()
end
function Fenzheng_MBuy_Close_Clicked()
	this:Hide()
end
function Fenzheng_MBuy_Frame_On_ResetPos()
	 Fenzheng_MBuy_Frame:SetProperty("UnifiedPosition", g_Fenzheng_MBuy_Frame_UnifiedPosition)
end
