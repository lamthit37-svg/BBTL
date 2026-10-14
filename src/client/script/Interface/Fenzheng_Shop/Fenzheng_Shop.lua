-- PVP纷争商店 
-- 聚侠堂 分页3
-- PVPZH_220124_02	#gFF0FA0铁甲阁
-- PVPZH_220124_03	#gFF0FA1金戈馆
-- PVPZH_220124_04	#gFF0FA2逐鹿馆·虎啸
-- PVPZH_220124_05	#gFF0FA3逐鹿馆·龙腾

-- SHZJ_241220_04	云锦行
-- SHZJ_241220_05	华玉集
-- SHZJ_241220_06	聚侠堂
-- SHZJ_241220_07	天荒商行
-- XKSD_250110_05   侠客商店

-- local g_Fenzheng_Shop_Frame_UnifiedXPosition
-- local g_Fenzheng_Shop_Frame_UnifiedYPosition 
local g_Fenzheng_Shop_listitem ={}
local g_Fenzheng_Shop_Type = 1
local g_Fenzheng_Shop_CurPage = 1
local g_Fenzheng_Shop_TargetId = -1
local g_Fenzheng_Shop_PerPageCount = 15

local g_Fenzheng_Shop_LimitLevel = 60

local g_Fenzheng_Shop_InfoExLevel = 80

local g_Fenzheng_Shop_StrDicList = 
{
	[1] = {name = "#{ZCSD_20240204_29}", info = "#{ZCSD_20240204_74}", infoex = "#{PVPZH_220124_06}", infoqx = "#{QXF_260623_144}", infoqxex = "#{QXF_260623_03}", 
			own = "#{PVPZH_220124_13}", owntip = "#{PVPZH_220124_14}", thisweek = "#{PVPZH_220124_113}", 
			thisweekqx = "#{PVPZH_260716_01}", thisweektip = "#{PVPZH_220124_114}", icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon3" },
	[2] = {name = "#{ZCSD_20240204_30}", info = "#{PVPZH_220124_07}", infoex = "#{PVPZH_220124_07}", infoqx = "#{QXF_260623_140}", infoqxex = "#{QXF_260623_140}", 
			own = "#{PVPZH_220124_80}", owntip = "#{PVPZH_220124_81}", thisweek = "#{PVPZH_220124_115}", 
			thisweekqx = "#{PVPZH_260716_02}", thisweektip = "#{PVPZH_220124_116}", icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon4" },
	[3] = {name = "#{ZCSD_20240204_32}", info = "#{ZCSD_20240204_75}", infoex = "#{ZCSD_20240204_34}", infoqx = "#{QXF_260623_145}", infoqxex = "#{QXF_260623_142}", 
			own = "#{ZCSD_20240204_40}", owntip = "#{ZCSD_20240204_41}", thisweek = "#{ZCSD_20240204_44}", 
			thisweekqx = "#{PVPZH_260716_04}", thisweektip = "#{ZCSD_20240204_45}", icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon6" },
	[4] = {name = "#{ZCSD_20240204_31}", info = "#{ZCSD_20240204_33}", infoex = "#{ZCSD_20240204_33}", infoqx = "#{QXF_260623_141}", infoqxex = "#{QXF_260623_141}", 
			own = "#{ZCSD_20240204_38}", owntip = "#{ZCSD_20240204_39}", thisweek = "#{ZCSD_20240204_42}", 
			thisweekqx = "#{PVPZH_260716_03}", thisweektip = "#{ZCSD_20240204_43}", icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon7" },
}

local g_Fenzheng_Shop_ButList = {}

local g_Fenzheng_Shop_TypeCountMax = 4

function Fenzheng_Shop_PreLoad()

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
end

function Fenzheng_Shop_OnLoad() 
	-- g_Fenzheng_Shop_Frame_UnifiedXPosition = Fenzheng_Shop_Frame:GetProperty("UnifiedXPosition") 
	-- g_Fenzheng_Shop_Frame_UnifiedYPosition = Fenzheng_Shop_Frame:GetProperty("UnifiedYPosition") 

	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if( curWorldBank_UIPos ~= nil) then
        Fenzheng_Shop_Frame : SetProperty("UnifiedPosition", curWorldBank_UIPos )
    else
        Variable : SetVariable("WorldBank_UIPos", Fenzheng_Shop_Frame : GetProperty("UnifiedPosition"), 1)
	end

    Fenzheng_Shop_ItemList:Clear();   
	g_Fenzheng_Shop_ButList[1] = Fenzheng_Shop_But1
	g_Fenzheng_Shop_ButList[2] = Fenzheng_Shop_But2
	g_Fenzheng_Shop_ButList[3] = Fenzheng_Shop_But3
	g_Fenzheng_Shop_ButList[4] = Fenzheng_Shop_But4
	
end
 
--=========
-- Event
--=========
---   !!!reloadscript =Fenzheng_Shop
function Fenzheng_Shop_OnEvent(event) 
	
	if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 88896901 then
		if this:IsVisible() then 
					
			local daibiType = Get_XParam_INT(0)
			local daibiaccconsumption = Get_XParam_INT(1)			
			--PushDebugMessage("daibiType = "..daibiType.."  daibiaccconsumption = "..daibiaccconsumption)
			if daibiType == g_Fenzheng_Shop_Type then
				Fenzheng_Shop_Currency1:SetText(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].own, daibiaccconsumption)) 
			end
		end
	end	
	if event == "UPDATE_PVPESHOP" then
		if this:IsVisible() then 
			local curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVPShopDaiBi1Info()
			if g_Fenzheng_Shop_Type == 2 then
				curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVPShopDaiBi2Info()
			elseif g_Fenzheng_Shop_Type == 3 then
				curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVEShopDaiBi1Info()
			elseif g_Fenzheng_Shop_Type == 4 then
				curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVEShopDaiBi2Info()
			end
			Fenzheng_Shop_Currency1:SetText(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].own,curDaibiTotal)) 
			Fenzheng_Shop_Currency1:SetToolTip(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].owntip,curDaibiTotal)) 
			Fenzheng_Shop_XuanjiaNum:SetText(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].thisweek, curDaibiDay, curDaibiDayLimit, curDaibiWeek, curDaibiWeekLimit)) 
			Fenzheng_Shop_XuanjiaNum:SetToolTip(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].thisweektip,curDaibiDayLimit,curDaibiWeekLimit))
			Fenzheng_Shop_XuanjiaIcon:SetToolTip(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].thisweektip,curDaibiDayLimit,curDaibiWeekLimit))
				
			if Player:GetData("Is2606S") == 1 then
				Fenzheng_Shop_XuanjiaNum:SetText(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].thisweekqx, curDaibiWeek, curDaibiWeekLimit)) 
				Fenzheng_Shop_XuanjiaNum:SetToolTip("")
				Fenzheng_Shop_XuanjiaIcon:SetToolTip("")		
			end
			
		end
	end
    if event == "UPDATE_PVPSHOP_DAIBI1" or event == "UPDATE_PVPSHOP_DAIBI2" or event == "UPDATE_PVESHOP_DAIBI1" or event == "UPDATE_PVESHOP_DAIBI2" then   
		local inputtype = tonumber(arg0) 
			
		if inputtype > 0 and inputtype <= g_Fenzheng_Shop_TypeCountMax then
			g_Fenzheng_Shop_Type = inputtype
		else
			g_Fenzheng_Shop_Type = 1
		end
        -- g_Fenzheng_Shop_TargetId = tonumber(arg1) 
		if tonumber(arg2) ~= nil then
			g_Fenzheng_Shop_CurPage = tonumber(arg2)
		else
			g_Fenzheng_Shop_CurPage = 1
		end
        -- objCared = DataPool : GetNPCIDByServerID(g_Fenzheng_Shop_TargetId)
		-- this:CareObject(objCared, 1, "Fenzheng_Shop");
		Fenzheng_Shop_Open(g_Fenzheng_Shop_CurPage)
        this:Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Fenzheng_Shop_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Fenzheng_Shop_Close()
	elseif event == "ADJEST_UI_POS" then
        Fenzheng_Shop_On_ResetPos() 	
    -- elseif (event == "OBJECT_CARED_EVENT") then
	-- 	if(tonumber(arg0) ~= objCared) then
	-- 		return;
	-- 	end
	-- 	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	-- 	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
	-- 		this:Hide();
	-- 		--取消关心
	-- 		this:CareObject(objCared, 0, "Fenzheng_Shop");
	-- 	end	
	end

end
 
--=========
-- 重置
--=========
function Fenzheng_Shop_On_ResetPos()

	-- Fenzheng_Shop_Frame:SetProperty("UnifiedXPosition", g_Fenzheng_Shop_Frame_UnifiedXPosition)
	-- Fenzheng_Shop_Frame:SetProperty("UnifiedYPosition", g_Fenzheng_Shop_Frame_UnifiedYPosition)

	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if( curWorldBank_UIPos ~= nil) then
        Fenzheng_Shop_Frame : SetProperty("UnifiedPosition", curWorldBank_UIPos )
	end

end

function Fenzheng_Shop_OnHiden()
    Fenzheng_Shop_Close()
end
--=========
-- 关闭
--=========
function Fenzheng_Shop_Close()     
    g_Fenzheng_Shop_CurPage = 1
	this:Hide()
end

function Fenzheng_Shop_ChangeShowTab(index)
	
	 Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "FCOnAskDataByType" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 888969 );											-- 脚本编号  
        Set_XSCRIPT_Parameter( 0, index + 1 );	
        Set_XSCRIPT_Parameter( 1, g_Fenzheng_Shop_TargetId );		     
        Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
    Send_XSCRIPT()	

end

--=========
-- 打开
--=========
function Fenzheng_Shop_Open(page)

	-- 总界面控制
    -- 关闭其他所有界面组 页签高亮
    Fenzheng_Shop_CloseSameGroupWindow()

	g_Fenzheng_Shop_CurPage = page
	local curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVPShopDaiBi1Info()
	if g_Fenzheng_Shop_Type == 2 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVPShopDaiBi2Info()
	elseif g_Fenzheng_Shop_Type == 3 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVEShopDaiBi1Info()
	elseif g_Fenzheng_Shop_Type == 4 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVEShopDaiBi2Info()
	end
	
	if g_Fenzheng_Shop_Type == 1 or g_Fenzheng_Shop_Type == 3 then
		Fenzheng_Shop_Preview:Show()
	else
		Fenzheng_Shop_Preview:Hide()
	end
	
	local infostr = ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].info, curDaibiDayLimit, curDaibiWeekLimit)

	if Player:GetData("Is2606S") == 1 then
		infostr = ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].infoqx, curDaibiWeekLimit)
	end	
	
    if (Player:GetData("LEVEL") >= g_Fenzheng_Shop_InfoExLevel) then
		infostr = ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].infoex, curDaibiDayLimit, curDaibiWeekLimit)
		if Player:GetData("IsOriginalJD") == 1 and g_Fenzheng_Shop_Type == 1 then
			infostr = ScriptGlobal_Format("#{SJF_251024_18}", curDaibiDayLimit, curDaibiWeekLimit)
		end
		if Player:GetData("Is2606S") == 1 then
			infostr = ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].infoqxex, curDaibiWeekLimit)
		end	
    end	

	
	Fenzheng_Shop_Info:SetText(infostr)	
	--Fenzheng_Shop_DragTitle:SetText(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].name)
	-- Fenzheng_Shop_DragTitle:SetText("#{ZCSD_20240204_28}")	
	Fenzheng_Shop_XuanjiaIcon:SetProperty("Image", g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].icon)
	Fenzheng_Shop_CurrencyIcon1:SetProperty("Image", g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].icon)


	for i = 1, 4 do
		g_Fenzheng_Shop_ButList[i]:SetProperty("Selected", "False")
	end
	g_Fenzheng_Shop_ButList[g_Fenzheng_Shop_Type]:SetProperty("Selected", "True" )
	
    for i = 1, table.getn(g_Fenzheng_Shop_listitem) do
		if g_Fenzheng_Shop_listitem[i] ~= nil then
			g_Fenzheng_Shop_listitem[i] = nil
		end
    end
    
    Fenzheng_Shop_ItemList:Clear()
    local tblinfo= GetPVPEShopData(g_Fenzheng_Shop_Type,g_Fenzheng_Shop_CurPage, g_Fenzheng_Shop_PerPageCount)
	
	if type(tblinfo) ~= "table" then
		PushDebugMessage("error")
		return
    end 

	for i = 1, table.getn(tblinfo) do
		--第一列
		local bar1 = Fenzheng_Shop_ItemList:AddChild("Fenzheng_Shop_ItemFrame")
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
		local saletype = tblinfo[i].saletype
		
		--PushDebugMessage("limitday = "..limitday.."  limitweek = "..limitweek.."limitmonth = "..limitmonth.."limitpermanent = "..limitpermanent)	
        --PushDebugMessage("limitday_self = "..limitday_self.."  limitweek_self = "..limitweek_self.."limitmonth_self = "..limitmonth_self.."limitpermanent_self = "..limitpermanent_self)	
		
		if limitday < 0 and limitweek < 0 and limitmonth < 0 and limitpermanent < 0 then
            bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Hide()
            bar1:GetSubItem("Fenzheng_Shop_Item_Mask"):Hide()  
            bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Limit"):Hide()
        elseif limitday > 0 then      
            bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNum"):SetText(limitday_self)               
            bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day") 
            bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Limit"):Show() 
            if limitday_self ~= 0 then 
                bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Show()  
                bar1:GetSubItem("Fenzheng_Shop_Item_Mask"):Hide()  
            else
                bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Hide()  
                bar1:GetSubItem("Fenzheng_Shop_Item_Mask"):Show()  
            end
        elseif limitweek > 0 then
            bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Show()        
            bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNum"):SetText(limitweek_self)             
            bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week") 
            bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Limit"):Show()         
            if limitweek_self ~= 0 then 
                bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Show()  
                bar1:GetSubItem("Fenzheng_Shop_Item_Mask"):Hide()  
            else
                bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Hide()  
                bar1:GetSubItem("Fenzheng_Shop_Item_Mask"):Show()  
            end
        elseif limitmonth > 0 then
            bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Show()        
            bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNum"):SetText(limitmonth_self)         
            bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Month") 
            bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Limit"):Show()         
            if limitmonth_self ~= 0 then 
                bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Show()  
                bar1:GetSubItem("Fenzheng_Shop_Item_Mask"):Hide()  
            else
                bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Hide()  
                bar1:GetSubItem("Fenzheng_Shop_Item_Mask"):Show()  
            end

        elseif limitpermanent > 0 then
            bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Show()        
            bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNum"):SetText(limitpermanent_self)    
            bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever") 
            bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Limit"):Show()         
            if limitpermanent_self ~= 0 then 
                bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Show()  
                bar1:GetSubItem("Fenzheng_Shop_Item_Mask"):Hide()  
            else
                bar1:GetSubItem("Fenzheng_Shop_Item_BuyLimitNumBK"):Hide()  
                bar1:GetSubItem("Fenzheng_Shop_Item_Mask"):Show()  
            end
        end
		
		-- 道具展示区域
	    local theAction = DataPool:CreateBindActionItemForShow(itemid, itemnum)
	    if theAction:GetID() ~= 0 then
            bar1:GetSubItem("Fenzheng_Shop_Item"):SetActionItem(theAction:GetID())
        end
		
		bar1:GetSubItem("Fenzheng_Shop_ItemPreview"):Hide()
        bar1:GetSubItem("Fenzheng_Shop_ItemText"):SetText(DataPool:Lua_GetItemNameByIndex(itemid))   
		bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Dynamic"):Hide()
		
		bar1:GetSubItem("Fenzheng_Shop_ItemPrice"):SetText(ScriptGlobal_Format("#{HYCT_20210629_05}",price))
        bar1:GetSubItem("Fenzheng_Shop_Item_Feibang"):Hide()
		
		bar1:SetEvent("MouseLClick", string.format("Fenzheng_Shop_Clicked(%d)", i))  
		
		if saletype == 2 then  --轮换型
			bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Turn"):Show()
		else
			bar1:GetSubItem("Fenzheng_Shop_ItemInfo_Turn"):Hide()
		end
		
		bar1:GetSubItem("Fenzheng_Shop_ItemPriceIcon"):SetProperty("Image", g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].icon) 
         
		g_Fenzheng_Shop_listitem[i] = bar1
    end
    
	local curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVPShopDaiBi1Info()
	if g_Fenzheng_Shop_Type == 2 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVPShopDaiBi2Info()
	elseif g_Fenzheng_Shop_Type == 3 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVEShopDaiBi1Info()
	elseif g_Fenzheng_Shop_Type == 4 then
		curDaibiTotal, curDaibiWeek, curDaibiWeekLimit, curDaibiDay, curDaibiDayLimit = GetPVEShopDaiBi2Info()
	end
	
--	PushDebugMessage("curDaibiTotal = "..curDaibiTotal.."  curDaibiWeek = "..curDaibiWeek)
	Fenzheng_Shop_Currency1:SetText(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].own,curDaibiTotal)) 
	Fenzheng_Shop_Currency1:SetToolTip(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].owntip) 
	Fenzheng_Shop_CurrencyIcon1:SetToolTip(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].owntip) 
	Fenzheng_Shop_XuanjiaNum:SetText(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].thisweek, curDaibiDay, curDaibiDayLimit, curDaibiWeek, curDaibiWeekLimit)) 
	Fenzheng_Shop_XuanjiaNum:SetToolTip(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].thisweektip,curDaibiDayLimit,curDaibiWeekLimit))
	Fenzheng_Shop_XuanjiaIcon:SetToolTip(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].thisweektip,curDaibiDayLimit,curDaibiWeekLimit))
							
	if Player:GetData("Is2606S") == 1 then
		Fenzheng_Shop_XuanjiaNum:SetText(ScriptGlobal_Format(g_Fenzheng_Shop_StrDicList[g_Fenzheng_Shop_Type].thisweekqx, curDaibiWeek, curDaibiWeekLimit)) 
		Fenzheng_Shop_XuanjiaNum:SetToolTip("")
		Fenzheng_Shop_XuanjiaIcon:SetToolTip("")		
	end			
			
    if g_Fenzheng_Shop_CurPage == 1 then
        Fenzheng_Shop_UpPage:Disable()
    else
        Fenzheng_Shop_UpPage:Enable()
    end
    
    if g_Fenzheng_Shop_CurPage*g_Fenzheng_Shop_PerPageCount >= GetPVPEShopTotalCount(g_Fenzheng_Shop_Type) then
        Fenzheng_Shop_DownPage:Disable()
    else
        Fenzheng_Shop_DownPage:Enable()
    end
	
	

    local npagecount = 0
    if GetPVPEShopTotalCount(g_Fenzheng_Shop_Type) <= g_Fenzheng_Shop_PerPageCount then
        npagecount = 1
    elseif math.mod(GetPVPEShopTotalCount(g_Fenzheng_Shop_Type), g_Fenzheng_Shop_PerPageCount) == 0  then
        npagecount = math.floor(GetPVPEShopTotalCount(g_Fenzheng_Shop_Type)/g_Fenzheng_Shop_PerPageCount)
    else
        npagecount = math.floor(GetPVPEShopTotalCount(g_Fenzheng_Shop_Type)/g_Fenzheng_Shop_PerPageCount) + 1
    end
    Fenzheng_Shop_CurrentlyPage:SetText( ScriptGlobal_Format("#{PVPZH_220124_16}",g_Fenzheng_Shop_CurPage, npagecount) )		
		


end

function Fenzheng_Shop_Preview_Clicked()
	
	PushEvent("OPEN_PVPSHOP_PREVIEW", g_Fenzheng_Shop_Type, g_Fenzheng_Shop_TargetId)

end

function Fenzheng_Shop_Clicked(index)
	
    local nLevel = Player:GetLevel();
    if nLevel < g_Fenzheng_Shop_LimitLevel then        
		PushDebugMessage(ScriptGlobal_Format("#{PVPZH_220124_53}",g_Fenzheng_Shop_LimitLevel))
		return
    end
    -- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
    end
    local tblinfo= GetPVPEShopData(g_Fenzheng_Shop_Type,g_Fenzheng_Shop_CurPage, g_Fenzheng_Shop_PerPageCount)
	
	if type(tblinfo) ~= "table" or tblinfo[index]  == nil then
		PushDebugMessage("error")
		return
    end 
    local itemid 	    = tblinfo[index].itemid
	local itemnum 	    = tblinfo[index].itemnum
	local price     = tblinfo[index].price

	local limitday      = tblinfo[index].limitday
	local limitday_self = tblinfo[index].limitday_self
	local limitweek     = tblinfo[index].limitweek
	local limitweek_self= tblinfo[index].limitweek_self
	local limitmonth    = tblinfo[index].limitmonth
	local limitmonth_self= tblinfo[index].limitmonth_self
	local limitpermanent      = tblinfo[index].limitpermanent
	local limitpermanent_self = tblinfo[index].limitpermanent_self

    if  (limitday  > 0 and limitday_self  <= 0) or
        (limitweek > 0 and limitweek_self <= 0) or
        (limitmonth > 0 and limitmonth_self<= 0) or
        (limitpermanent > 0 and limitpermanent_self  <= 0)  
      then
        PushDebugMessage("#{PVPZH_220124_54}")
		return
    end
    --local active_week = Player:GetData("WEEKACTIVEPOINT")
    PushEvent("OPEN_PVPSHOP_BUY", g_Fenzheng_Shop_CurPage, index, g_Fenzheng_Shop_PerPageCount,g_Fenzheng_Shop_TargetId, g_Fenzheng_Shop_Type)
end 

function Fenzheng_Shop_PageDown()
    if g_Fenzheng_Shop_CurPage*g_Fenzheng_Shop_PerPageCount < GetPVPEShopTotalCount(g_Fenzheng_Shop_Type) then
        g_Fenzheng_Shop_CurPage = g_Fenzheng_Shop_CurPage + 1
        Fenzheng_Shop_Open(g_Fenzheng_Shop_CurPage)
    end
end


function Fenzheng_Shop_PageUp()
    if g_Fenzheng_Shop_CurPage > 1 then
        g_Fenzheng_Shop_CurPage = g_Fenzheng_Shop_CurPage - 1
        Fenzheng_Shop_Open(g_Fenzheng_Shop_CurPage)
    end
end

-- 聚侠堂 分页3
-- SHZJ_241220_04	云锦行
-- SHZJ_241220_05	华玉集
-- SHZJ_241220_06	聚侠堂
-- SHZJ_241220_07	天荒商行
function Fenzheng_Shop_ChangeWorldBankPage(nPageIndex)

    Fenzheng_Shop_YunJin    :   SetCheck(0)
	Fenzheng_Shop_HuaYu     :   SetCheck(0)
	Fenzheng_Shop_JuXia     :   SetCheck(1)
	Fenzheng_Shop_TianHuang :   SetCheck(0)
	Fenzheng_Shop_XiaKe		:   SetCheck(0)


	Variable : SetVariable("WorldBank_UIPos", Fenzheng_Shop_Frame : GetProperty("UnifiedPosition"), 1)

    if 1 == nPageIndex then
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "OnAskData_L" ); 	    -- 函数名
            Set_XSCRIPT_ScriptID( 888393 );						-- 脚本编号
            Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
        Send_XSCRIPT()
        return
    end

    if 2 == nPageIndex then
        PushEvent("OPEN_HUOYUESHOP_H")
        return
    end

    if 3 == nPageIndex then
        -- -- if Player:GetLevel() < 60 then        
        -- --     PushDebugMessage(ScriptGlobal_Format("#{PVPZH_220124_53}", 60))
        -- --     return
        -- -- end
        -- -- PushEvent("UPDATE_PVPSHOP_DAIBI1", 1, -1, 1)
        -- Clear_XSCRIPT()
        --     Set_XSCRIPT_Function_Name( "FCOnAskDataByType" ); 					    -- 脚本函数名称
        --     Set_XSCRIPT_ScriptID( 888969 );											-- 脚本编号  
        --     Set_XSCRIPT_Parameter( 0, 1 );	
        --     Set_XSCRIPT_Parameter( 1, -1 );		     
        --     Set_XSCRIPT_ParamCount( 2 ); 	                                        -- 参数个数  
        -- Send_XSCRIPT()	
        return
    end

    if 4 == nPageIndex then
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "OnAskDataByType" ); 					    -- 脚本函数名称
            Set_XSCRIPT_ScriptID( 889833 );											-- 脚本编号 
            Set_XSCRIPT_Parameter( 0, -1 );	
            Set_XSCRIPT_Parameter( 1, 0 );		 
            Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数
        Send_XSCRIPT()
        return
	end
	
	if 5 == nPageIndex then
		PushEvent("UI_COMMAND", 18201)
        return
    end
end

function Fenzheng_Shop_CloseSameGroupWindow()

	Fenzheng_Shop_On_ResetPos()

    CloseWindow("ActivitySchedule_Shop2", true)
    CloseWindow("ActivitySchedule_Shop", true)
    -- CloseWindow("Fenzheng_Shop", true)
	CloseWindow("FengmingShop", true)
	CloseWindow("Xiake_Shop", true)
    
    Fenzheng_Shop_YunJin    :   SetCheck(0)
	Fenzheng_Shop_HuaYu     :   SetCheck(0)
	Fenzheng_Shop_JuXia     :   SetCheck(1)
	Fenzheng_Shop_TianHuang :   SetCheck(0)
	Fenzheng_Shop_XiaKe		:   SetCheck(0)

	local n2606S = Player:GetData("Is2606S") 
    if n2606S ~= 1 then
        Fenzheng_Shop_TianHuang:Show()
    else
        Fenzheng_Shop_TianHuang:Hide()
	end
	
	local nXiaKe = Player:GetData("IsXiaKe") 
    if nXiaKe ~= 1 then
        Fenzheng_Shop_XiaKe:Hide()
    else
        Fenzheng_Shop_XiaKe:Show()
	end
end