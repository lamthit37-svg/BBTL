--PVP纷争商店 
local g_Fenzheng_ShopPreview_Frame_UnifiedXPosition
local g_Fenzheng_ShopPreview_Frame_UnifiedYPosition 
local g_Fenzheng_ShopPreview_listitem ={}
local g_Fenzheng_ShopPreview_Type = 1
local g_Fenzheng_ShopPreview_CurPage = 1
local g_Fenzheng_ShopPreview_TargetId = -1
local g_Fenzheng_ShopPreview_PerPageCount = 1000

local g_Fenzheng_ShopPreview_LimitLevel = 60

local g_Fenzheng_ShopPreview_StrDicList = 
{
	[1] = {name = "#{ZCSD_20240204_64}", info = "#{ZCSD_20240204_62}", infokaji = "#{ZCSD_20240204_72}",  own = "#{PVPZH_220124_13}", owntip = "#{PVPZH_220124_14}", thisweek = "#{PVPZH_220124_113}", 
			thisweektip = "#{PVPZH_220124_114}", icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon3" },
	[2] = {name = "#{ZCSD_20240204_28}", info = "#{ZCSD_20240204_62}", infokaji = "#{ZCSD_20240204_72}", own = "#{PVPZH_220124_80}", owntip = "#{PVPZH_220124_81}", thisweek = "#{PVPZH_220124_115}", 
			thisweektip = "#{PVPZH_220124_116}", icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon4" },
	[3] = {name = "#{ZCSD_20240204_69}", info = "#{ZCSD_20240204_70}", infokaji = "#{ZCSD_20240204_71}", own = "#{ZCSD_20240204_40}", owntip = "#{ZCSD_20240204_41}", thisweek = "#{ZCSD_20240204_44}", 
			thisweektip = "#{ZCSD_20240204_45}", icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon6" },
	[4] = {name = "#{ZCSD_20240204_28}", info = "#{ZCSD_20240204_70}", infokaji = "#{ZCSD_20240204_71}", own = "#{ZCSD_20240204_38}", owntip = "#{ZCSD_20240204_39}", thisweek = "#{ZCSD_20240204_42}", 
			thisweektip = "#{ZCSD_20240204_43}", icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon7" },
}

local g_Fenzheng_ShopPreview_TypeCountMax = 4

function Fenzheng_ShopPreview_PreLoad()

	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("UPDATE_PVPSHOP_DAIBI1",true) 
	this:RegisterEvent("UPDATE_PVPSHOP_DAIBI2",true) 
	this:RegisterEvent("UPDATE_PVESHOP_DAIBI1",true) 
	this:RegisterEvent("UPDATE_PVESHOP_DAIBI2",true) 
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false);  
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_PVPESHOP")
	this:RegisterEvent("OPEN_PVPSHOP_PREVIEW")
end

function Fenzheng_ShopPreview_OnLoad() 
	g_Fenzheng_ShopPreview_Frame_UnifiedXPosition = Fenzheng_ShopPreview_Frame:GetProperty("UnifiedXPosition") 
	g_Fenzheng_ShopPreview_Frame_UnifiedYPosition = Fenzheng_ShopPreview_Frame:GetProperty("UnifiedYPosition") 
    Fenzheng_ShopPreview_ItemList:Clear();   
end


 
--=========
-- Event
--=========
---   !!!reloadscript =Fenzheng_ShopPreview
function Fenzheng_ShopPreview_OnEvent(event) 
	
	if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 88896901 then
		if this:IsVisible() then 
					
			local daibiType = Get_XParam_INT(0)
			local daibiaccconsumption = Get_XParam_INT(1)			
			--PushDebugMessage("daibiType = "..daibiType.."  daibiaccconsumption = "..daibiaccconsumption)
			if daibiType == g_Fenzheng_ShopPreview_Type then
				Fenzheng_ShopPreview4_Currency1:SetText(ScriptGlobal_Format(g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].own, daibiaccconsumption)) 
			end
		end
	end	
	if event == "UPDATE_PVPESHOP" then
		if this:IsVisible() then 
			local curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVPShopDaiBi1Info()
			if g_Fenzheng_ShopPreview_Type == 2 then
				curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVPShopDaiBi2Info()
			elseif g_Fenzheng_ShopPreview_Type == 3 then
				curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVEShopDaiBi1Info()
			elseif g_Fenzheng_ShopPreview_Type == 4 then
				curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVEShopDaiBi2Info()
			end
			Fenzheng_ShopPreview_Currency1:SetText(ScriptGlobal_Format(g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].own,curDaibiTotal)) 
			Fenzheng_ShopPreview_Currency1:SetToolTip(g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].owntip) 
			Fenzheng_ShopPreview_CurrencyIcon1:SetToolTip(g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].owntip) 
		end
	end
    if event == "OPEN_PVPSHOP_PREVIEW" then   
		local inputtype = tonumber(arg0) 
		g_Fenzheng_ShopPreview_TargetId = tonumber(arg1) 
		if inputtype > 0 and inputtype <= g_Fenzheng_ShopPreview_TypeCountMax then
			g_Fenzheng_ShopPreview_Type = inputtype
		else
			g_Fenzheng_ShopPreview_Type = 1
		end
		Fenzheng_ShopPreview_Open(1)
		-- objCared = DataPool : GetNPCIDByServerID(g_Fenzheng_ShopPreview_TargetId)
		-- this:CareObject(objCared, 1, "Fenzheng_ShopPreview");
        this:Show()
		Fenzheng_ShopPreview_Frame:SetForce()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Fenzheng_ShopPreview_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Fenzheng_ShopPreview_Close()
	elseif event == "ADJEST_UI_POS" then
        Fenzheng_ShopPreview_On_ResetPos() 	
    -- elseif (event == "OBJECT_CARED_EVENT") then
	-- 	if(tonumber(arg0) ~= objCared) then
	-- 		return;
	-- 	end
	-- 	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	-- 	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
	-- 		this:Hide();
	-- 		--取消关心
	-- 		this:CareObject(objCared, 0, "Fenzheng_ShopPreview");
	-- 	end	
	end

end
 
--=========
-- 重置
--=========
function Fenzheng_ShopPreview_On_ResetPos()

	Fenzheng_ShopPreview_Frame:SetProperty("UnifiedXPosition", g_Fenzheng_ShopPreview_Frame_UnifiedXPosition)
	Fenzheng_ShopPreview_Frame:SetProperty("UnifiedYPosition", g_Fenzheng_ShopPreview_Frame_UnifiedYPosition)

end

function Fenzheng_ShopPreview_OnHiden()
    Fenzheng_ShopPreview_Close()
end
--=========
-- 关闭
--=========
function Fenzheng_ShopPreview_Close()     
    g_Fenzheng_ShopPreview_CurPage = 1
	this:Hide()
end

function Fenzheng_ShopPreview_ChangeShowTab(index)
	
	 Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "FCOnAskDataByType" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 888969 );											-- 脚本编号  
        Set_XSCRIPT_Parameter( 0, index + 1 );	
        Set_XSCRIPT_Parameter( 1, -1 );		     
        Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
    Send_XSCRIPT()	

end

--=========
-- 打开
--=========
function Fenzheng_ShopPreview_Open(page)

	g_Fenzheng_ShopPreview_CurPage = page
	local curDaibiTotal, curDaibiWeek, curDaibiWeekLimit = GetPVPShopDaiBi1Info()
	if g_Fenzheng_ShopPreview_Type == 2 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit = GetPVPShopDaiBi2Info()
	elseif g_Fenzheng_ShopPreview_Type == 3 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit = GetPVEShopDaiBi1Info()
	elseif g_Fenzheng_ShopPreview_Type == 4 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit = GetPVEShopDaiBi2Info()
	end
	local infostr = g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].info
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(65) > 0 then  --卡级
		infostr = g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].infokaji
	end
	if Player:GetData("IsOriginalJD") == 1 and (g_Fenzheng_ShopPreview_Type == 1 or g_Fenzheng_ShopPreview_Type == 2) then
		infostr = "#{SJF_251024_19}"
	end
	if Player:GetData("Is2606S") == 1 and (g_Fenzheng_ShopPreview_Type == 1 or g_Fenzheng_ShopPreview_Type == 2) then
		infostr = "#{QXF_260623_04}"
	end
	Fenzheng_ShopPreview_Info:SetText(infostr)	
	Fenzheng_ShopPreview_DragTitle:SetText(g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].name)
	--Fenzheng_ShopPreview_DragTitle:SetText("#{ZCSD_20240204_28}")	
	Fenzheng_ShopPreview_CurrencyIcon1:SetProperty("Image", g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].icon)
	
	
    for i = 1, table.getn(g_Fenzheng_ShopPreview_listitem) do
		if g_Fenzheng_ShopPreview_listitem[i] ~= nil then
			g_Fenzheng_ShopPreview_listitem[i] = nil
		end
    end
    
    Fenzheng_ShopPreview_ItemList:Clear()
    local tblinfo= GetPVPEShopDataSpecial(g_Fenzheng_ShopPreview_Type,g_Fenzheng_ShopPreview_CurPage, g_Fenzheng_ShopPreview_PerPageCount)
	
	if type(tblinfo) ~= "table" then
		PushDebugMessage("error")
		return
    end 

	for i = 1, table.getn(tblinfo) do
		--第一列
		local bar1 = Fenzheng_ShopPreview_ItemList:AddChild("Fenzheng_ShopPreview_ItemFrame")
		if not bar1 then
    	   break
        end
        local itemid 	    = tblinfo[i].itemid
		local itemnum 	    = tblinfo[i].itemnum
		local itemname     = tblinfo[i].itemname
		local price      = tblinfo[i].price
		local limitday      = tblinfo[i].limitday
		local limitday_self = tblinfo[i].limitday_self
		local limitweek     = tblinfo[i].limitweek
		local limitweek_self= tblinfo[i].limitweek_self
		local limitmonth    = tblinfo[i].limitmonth
		local limitmonth_self= tblinfo[i].limitmonth_self
		local limitpermanent      = tblinfo[i].limitpermanent
		local limitpermanent_self = tblinfo[i].limitpermanent_self
		
		--PushDebugMessage("limitday = "..limitday.."  limitweek = "..limitweek.."limitmonth = "..limitmonth.."limitpermanent = "..limitpermanent)	
        --PushDebugMessage("limitday_self = "..limitday_self.."  limitweek_self = "..limitweek_self.."limitmonth_self = "..limitmonth_self.."limitpermanent_self = "..limitpermanent_self)	
		
		if limitday < 0 and limitweek < 0 and limitmonth < 0 and limitpermanent < 0 then
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNumBK"):Hide()
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_Mask"):Hide()  
            bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Limit"):Hide()
        elseif limitday > 0 then      
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNum"):SetText(limitday)               
            bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day") 
            bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Limit"):Show() 
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNumBK"):Show()  
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_Mask"):Hide()  

        elseif limitweek > 0 then
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNumBK"):Show()        
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNum"):SetText(limitweek)             
            bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week") 
            bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Limit"):Show()         
			bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNumBK"):Show()  
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_Mask"):Hide()  

        elseif limitmonth > 0 then
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNumBK"):Show()        
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNum"):SetText(limitmonth)         
            bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Month") 
            bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Limit"):Show()         
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNumBK"):Show()  
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_Mask"):Hide()  

        elseif limitpermanent > 0 then
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNumBK"):Show()        
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNum"):SetText(limitpermanent)    
            bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever") 
            bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Limit"):Show()         
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_BuyLimitNumBK"):Show()  
            bar1:GetSubItem("Fenzheng_ShopPreview_Item_Mask"):Hide()  

        end
		
		-- 道具展示区域
	    local theAction = DataPool:CreateBindActionItemForShow(itemid, itemnum)
	    if theAction:GetID() ~= 0 then
            bar1:GetSubItem("Fenzheng_ShopPreview_Item"):SetActionItem(theAction:GetID())
        end
		
		bar1:GetSubItem("Fenzheng_ShopPreview_ItemPreview"):Hide()
        bar1:GetSubItem("Fenzheng_ShopPreview_ItemText"):SetText(DataPool:Lua_GetItemNameByIndex(itemid))   
		bar1:GetSubItem("Fenzheng_ShopPreview_ItemInfo_Dynamic"):Hide()
		
		bar1:GetSubItem("Fenzheng_ShopPreview_ItemPrice"):SetText(ScriptGlobal_Format("#{HYCT_20210629_05}",price))
        bar1:GetSubItem("Fenzheng_ShopPreview_Item_Feibang"):Hide()

		bar1:GetSubItem("Fenzheng_ShopPreview_ItemPriceIcon"):SetProperty("Image", g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].icon)
		
		g_Fenzheng_ShopPreview_listitem[i] = bar1
    end
    
	local curDaibiTotal, curDaibiWeek, curDaibiWeekLimit = GetPVPShopDaiBi1Info()
	if g_Fenzheng_ShopPreview_Type == 2 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit = GetPVPShopDaiBi2Info()
	elseif g_Fenzheng_ShopPreview_Type == 3 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit = GetPVEShopDaiBi1Info()
	elseif g_Fenzheng_ShopPreview_Type == 4 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit = GetPVEShopDaiBi2Info()
	end
	
--	PushDebugMessage("curDaibiTotal = "..curDaibiTotal.."  curDaibiWeek = "..curDaibiWeek)
	Fenzheng_ShopPreview_Currency1:SetText(ScriptGlobal_Format(g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].own,curDaibiTotal)) 
	Fenzheng_ShopPreview_Currency1:SetToolTip(g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].owntip)
	Fenzheng_ShopPreview_CurrencyIcon1:SetToolTip(g_Fenzheng_ShopPreview_StrDicList[g_Fenzheng_ShopPreview_Type].owntip)		
   
 --if g_Fenzheng_ShopPreview_CurPage == 1 then
    --    Fenzheng_ShopPreview_UpPage:Disable()
    --else
    --    Fenzheng_ShopPreview_UpPage:Enable()
    --end
    
	--if g_Fenzheng_ShopPreview_CurPage*g_Fenzheng_ShopPreview_PerPageCount >= GetPVPEShopTotalCount(g_Fenzheng_ShopPreview_Type) then
    --    Fenzheng_ShopPreview_DownPage:Disable()
    --else
    --    Fenzheng_ShopPreview_DownPage:Enable()
	--end
	
	

    --local npagecount = 0
    --if GetPVPEShopTotalCount(g_Fenzheng_ShopPreview_Type) <= g_Fenzheng_ShopPreview_PerPageCount then
    --    npagecount = 1
    --elseif math.mod(GetPVPEShopTotalCount(g_Fenzheng_ShopPreview_Type), g_Fenzheng_ShopPreview_PerPageCount) == 0  then
    --    npagecount = math.floor(GetPVPEShopTotalCount(g_Fenzheng_ShopPreview_Type)/g_Fenzheng_ShopPreview_PerPageCount)
    --else
    --    npagecount = math.floor(GetPVPEShopTotalCount(g_Fenzheng_ShopPreview_Type)/g_Fenzheng_ShopPreview_PerPageCount) + 1
    --end
    --Fenzheng_ShopPreview_CurrentlyPage:SetText( ScriptGlobal_Format("#{PVPZH_220124_16}",g_Fenzheng_ShopPreview_CurPage, npagecount) )		
		


end
