-- 活跃积分商店 
-- 华玉集 分页2

-- SHZJ_241220_04	云锦行
-- SHZJ_241220_05	华玉集
-- SHZJ_241220_06	聚侠堂
-- SHZJ_241220_07	天荒商行
-- XKSD_250110_05   侠客商店

-- local g_ActivitySchedule_Shop_Frame_UnifiedXPosition
-- local g_ActivitySchedule_Shop_Frame_UnifiedYPosition 
local g_ActivitySchedule_Shop_listitem ={}
local g_ActivitySchedule_Shop_Type = 1
local g_ActivitySchedule_Shop_CurPage = 1
local g_ActivitySchedule_Shop_PerPageCount = 15
function ActivitySchedule_Shop_PreLoad()

	this:RegisterEvent("OPEN_HUOYUESHOP_H", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("UPDATE_HUOYUE_SHOP_H",true) 
	this:RegisterEvent("UPDATE_HUOYUE_SHOP_H",true) 
end

function ActivitySchedule_Shop_OnLoad() 
	-- g_ActivitySchedule_Shop_Frame_UnifiedXPosition = ActivitySchedule_Shop_Frame:GetProperty("UnifiedXPosition") 
    -- g_ActivitySchedule_Shop_Frame_UnifiedYPosition = ActivitySchedule_Shop_Frame:GetProperty("UnifiedYPosition") 
    
    local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if( curWorldBank_UIPos ~= nil) then
        ActivitySchedule_Shop_Frame : SetProperty("UnifiedPosition", curWorldBank_UIPos )
    else
        Variable : SetVariable("WorldBank_UIPos", ActivitySchedule_Shop_Frame : GetProperty("UnifiedPosition"), 1)
    end
    
    ActivitySchedule_Shop_ItemList:Clear();   
end
 
--=========
-- Event
--=========
function ActivitySchedule_Shop_OnEvent(event) 
	if event == "OPEN_HUOYUESHOP_H"  then -- 
		if this:IsVisible() then
			ActivitySchedule_Shop_Close()
			return
        end         
        g_ActivitySchedule_Shop_CurPage = 1
        ActivitySchedule_Shop_AskData() 
    elseif event == "UPDATE_HUOYUE_SHOP_H" then     
        ActivitySchedule_Shop_Open(g_ActivitySchedule_Shop_CurPage)
        this:Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ActivitySchedule_Shop_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ActivitySchedule_Shop_Close()
	elseif event == "ADJEST_UI_POS" then
		ActivitySchedule_Shop_On_ResetPos() 		
	end

end
 
--=========
-- 重置
--=========
function ActivitySchedule_Shop_On_ResetPos()

	-- ActivitySchedule_Shop_Frame:SetProperty("UnifiedXPosition", g_ActivitySchedule_Shop_Frame_UnifiedXPosition)
    -- ActivitySchedule_Shop_Frame:SetProperty("UnifiedYPosition", g_ActivitySchedule_Shop_Frame_UnifiedYPosition)
    
    local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if( curWorldBank_UIPos ~= nil) then
        ActivitySchedule_Shop_Frame : SetProperty("UnifiedPosition", curWorldBank_UIPos )
	end

end

function ActivitySchedule_Shop_OnHiden()
    ActivitySchedule_Shop_Close()
end
--=========
-- 关闭
--=========
function ActivitySchedule_Shop_Close() 
    g_ActivitySchedule_Shop_CurPage = 1
	this:Hide()
end

function ActivitySchedule_Shop_AskData()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnAskData_H" ); 	-- 函数名
		Set_XSCRIPT_ScriptID( 888393 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
--=========
-- 打开
--=========
function ActivitySchedule_Shop_Open()  

    -- 总界面控制
    -- 关闭其他所有界面组 页签高亮
    ActivitySchedule_Shop_CloseSameGroupWindow()

    for i = 1, table.getn(g_ActivitySchedule_Shop_listitem) do
		if g_ActivitySchedule_Shop_listitem[i] ~= nil then
			g_ActivitySchedule_Shop_listitem[i] = nil
		end
    end
    
    ActivitySchedule_Shop_ItemList:Clear()
    local tblinfo= GetHuoYueShopData(g_ActivitySchedule_Shop_Type, g_ActivitySchedule_Shop_CurPage, g_ActivitySchedule_Shop_PerPageCount)
	
	if type(tblinfo) ~= "table" then
		PushDebugMessage("error")
		return
    end 
    for i = 1, table.getn(tblinfo) do
		--第一列
		local bar1 = ActivitySchedule_Shop_ItemList:AddChild("ActivitySchedule_Shop_ItemFrame")
		if not bar1 then
    	   break
        end
        local itemid 	    = tblinfo[i].itemid
		local itemnum 	    = tblinfo[i].itemnum
		local daibitype     = tblinfo[i].daibitype
		local daibinum      = tblinfo[i].daibinum
		local limitday      = tblinfo[i].limitday
		local limitday_self = tblinfo[i].limitday_self
		local limitweek     = tblinfo[i].limitweek
		local limitweek_self= tblinfo[i].limitweek_self
		local limitmonth    = tblinfo[i].limitmonth
		local limitmonth_self= tblinfo[i].limitmonth_self
		local limitfov      = tblinfo[i].limitfov
		local limitfov_self = tblinfo[i].limitfov_self
		local yulan         = tblinfo[i].yulan
        local huoyueweek    = tblinfo[i].huoyueweek
        local isshowunbind      = tblinfo[i].isshowunbind

        --set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever
        --set:ActivitySchedule image:ActivitySchedule_ShopTips_Day
        --set:ActivitySchedule image:ActivitySchedule_ShopTips_Week
        --set:ActivitySchedule image:ActivitySchedule_ShopTips_Month

        if limitday == 0 and limitweek == 0 and limitmonth == 0 and limitfov == 0 then
            bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Hide()
            bar1:GetSubItem("ActivitySchedule_Shop_Item_Mask"):Hide()  
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Limit"):Hide()  

        elseif limitday ~= 0 then      
            bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNum"):SetText(limitday_self)   
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day") 
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Limit"):Show()
            if limitday_self ~= 0 then 
                bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Show()  
                bar1:GetSubItem("ActivitySchedule_Shop_Item_Mask"):Hide()  
            else
                bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Hide()  
                bar1:GetSubItem("ActivitySchedule_Shop_Item_Mask"):Show()  
            end
        elseif limitweek ~= 0 then
            bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Show()        
            bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNum"):SetText(limitweek_self)  
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week") 
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Limit"):Show()     
            if limitweek_self ~= 0 then 
                bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Show()  
                bar1:GetSubItem("ActivitySchedule_Shop_Item_Mask"):Hide()  
            else
                bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Hide()  
                bar1:GetSubItem("ActivitySchedule_Shop_Item_Mask"):Show()  
            end
        elseif limitmonth ~= 0 then
            bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Show()        
            bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNum"):SetText(limitmonth_self)    
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Month") 
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Limit"):Show()     
            if limitmonth_self ~= 0 then 
                bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Show()  
                bar1:GetSubItem("ActivitySchedule_Shop_Item_Mask"):Hide()  
            else
                bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Hide()  
                bar1:GetSubItem("ActivitySchedule_Shop_Item_Mask"):Show()  
            end

        elseif limitfov ~= 0 then
            bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Show()        
            bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNum"):SetText(limitfov_self)    
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Limit"):SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever") 
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Limit"):Show()      
            if limitfov_self ~= 0 then 
                bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Show()  
                bar1:GetSubItem("ActivitySchedule_Shop_Item_Mask"):Hide()  
            else
                bar1:GetSubItem("ActivitySchedule_Shop_Item_BuyLimitNumBK"):Hide()  
                bar1:GetSubItem("ActivitySchedule_Shop_Item_Mask"):Show()  
            end
        end
		-- 道具展示区域
	    local theAction = DataPool:CreateBindActionItemForShow(itemid, itemnum)
	    if theAction:GetID() ~= 0 then
            bar1:GetSubItem("ActivitySchedule_Shop_Item"):SetActionItem(theAction:GetID())
        end
        
        if yulan == 0 then
            bar1:GetSubItem("ActivitySchedule_Shop_ItemPreview"):Hide()
        else
            bar1:GetSubItem("ActivitySchedule_Shop_ItemPreview"):Show()
            bar1:GetSubItem("ActivitySchedule_Shop_ItemPreview"):SetEvent("MouseLClick", string.format("ActivitySchedule_Shop_YuLan(%d)", i))  
        end
        bar1:GetSubItem("ActivitySchedule_Shop_ItemText"):SetText(DataPool:Lua_GetItemNameByIndex(itemid))   

        if huoyueweek == 0 then
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Dynamic"):Hide()
        else
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Dynamic"):Show()
            bar1:GetSubItem("ActivitySchedule_Shop_ItemInfo_Dynamic"):SetText(huoyueweek)
        end

        if daibitype == 1 then
            bar1:GetSubItem("ActivitySchedule_Shop_ItemPrice"):SetText(ScriptGlobal_Format("#{HYCT_20210629_05}",daibinum))
        else            
            bar1:GetSubItem("ActivitySchedule_Shop_ItemPrice"):SetText(ScriptGlobal_Format("#{HYCT_20210629_04}",daibinum))
        end

        if isshowunbind == 1 then
            bar1:GetSubItem("ActivitySchedule_Shop_Item_Feibang"):Show()
        else
            bar1:GetSubItem("ActivitySchedule_Shop_Item_Feibang"):Hide()
        end

        bar1:SetEvent("MouseLClick", string.format("ActivitySchedule_Shop_Clicked(%d)", i))  
         
		g_ActivitySchedule_Shop_listitem[i] = bar1
    end
    
    local nhigh_total , nlow_total  = GetHuoYueShopDaiBiInfo() 
    ActivitySchedule_Shop_Currency1:SetText(ScriptGlobal_Format("#{HYCT_20210629_09}",nhigh_total)) 

    if g_ActivitySchedule_Shop_CurPage == 1 then
        ActivitySchedule_Shop_UpPage:Disable()
    else
        ActivitySchedule_Shop_UpPage:Enable()
    end
    
    if g_ActivitySchedule_Shop_CurPage*g_ActivitySchedule_Shop_PerPageCount >= GetHuoYueShopTotalCount(g_ActivitySchedule_Shop_Type) then
        ActivitySchedule_Shop_DownPage:Disable()
    else
        ActivitySchedule_Shop_DownPage:Enable()
    end

    local npagecount = 0
    if GetHuoYueShopTotalCount(g_ActivitySchedule_Shop_Type) <= g_ActivitySchedule_Shop_PerPageCount then
        npagecount = 1
    elseif math.mod(GetHuoYueShopTotalCount(g_ActivitySchedule_Shop_Type), g_ActivitySchedule_Shop_PerPageCount) == 0  then
        npagecount = math.floor(GetHuoYueShopTotalCount(g_ActivitySchedule_Shop_Type)/g_ActivitySchedule_Shop_PerPageCount)
    else
        npagecount = math.floor(GetHuoYueShopTotalCount(g_ActivitySchedule_Shop_Type)/g_ActivitySchedule_Shop_PerPageCount) + 1
    end
    ActivitySchedule_Shop_CurrentlyPage:SetText( ScriptGlobal_Format("#{HYCT_20210629_105}",g_ActivitySchedule_Shop_CurPage, npagecount) )
end

function ActivitySchedule_Shop_Clicked(index)
    local nLevel = Player:GetLevel();
    if nLevel < 10  then        
		PushDebugMessage("#{HYCT_20210629_26}")
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
    local tblinfo= GetHuoYueShopData(g_ActivitySchedule_Shop_Type, g_ActivitySchedule_Shop_CurPage, g_ActivitySchedule_Shop_PerPageCount)
	
	if type(tblinfo) ~= "table" or tblinfo[index]  == nil then
		PushDebugMessage("error")
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
    if  (limitday  ~= 0 and limitday_self  <= 0) or
        (limitweek ~= 0 and limitweek_self <= 0) or
        (limitmonth~= 0 and limitmonth_self<= 0) or
        (limitfov  ~= 0 and limitfov_self  <= 0)  
      then
        PushDebugMessage("#{HYCT_20210629_28}")
		return
    end
    local active_week = Player:GetData("WEEKACTIVEPOINT")
    if huoyueweek >= 0 and huoyueweek > active_week then
        PushDebugMessage("#{HYCT_20210629_29}")
		return
    end   
    PushEvent("OPEN_HUOYUESHAOP_BUY_H", g_ActivitySchedule_Shop_CurPage, index, g_ActivitySchedule_Shop_PerPageCount)
end

function ActivitySchedule_Shop_PageDown()
    if g_ActivitySchedule_Shop_CurPage*g_ActivitySchedule_Shop_PerPageCount < GetHuoYueShopTotalCount(g_ActivitySchedule_Shop_Type) then
        g_ActivitySchedule_Shop_CurPage = g_ActivitySchedule_Shop_CurPage + 1
        ActivitySchedule_Shop_Open()
    end
end


function ActivitySchedule_Shop_PageUp()
    if g_ActivitySchedule_Shop_CurPage > 1 then
        g_ActivitySchedule_Shop_CurPage = g_ActivitySchedule_Shop_CurPage - 1
        ActivitySchedule_Shop_Open()
    end
end

-- 华玉集 分页2

-- SHZJ_241220_04	云锦行
-- SHZJ_241220_05	华玉集
-- SHZJ_241220_06	聚侠堂
-- SHZJ_241220_07	天荒商行
function ActivitySchedule_Shop_ChangeWorldBankPage(nPageIndex)

    ActivitySchedule_Shop_YunJin    :   SetCheck(0)
	ActivitySchedule_Shop_HuaYu     :   SetCheck(1)
	ActivitySchedule_Shop_JuXia     :   SetCheck(0)
    ActivitySchedule_Shop_TianHuang :   SetCheck(0)
    ActivitySchedule_Shop_XiaKe     :   SetCheck(0)

    Variable : SetVariable("WorldBank_UIPos", ActivitySchedule_Shop_Frame : GetProperty("UnifiedPosition"), 1)

    if 1 == nPageIndex then
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "OnAskData_L" ); 	    -- 函数名
            Set_XSCRIPT_ScriptID( 888393 );						-- 脚本编号
            Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
        Send_XSCRIPT()
        return
    end

    if 2 == nPageIndex then
        -- PushEvent("OPEN_HUOYUESHOP_H")
        return
    end

    if 3 == nPageIndex then
        -- if Player:GetLevel() < 60 then        
        --     PushDebugMessage(ScriptGlobal_Format("#{PVPZH_220124_53}", 60))
        --     return
        -- end
        -- PushEvent("UPDATE_PVPSHOP_DAIBI1", 1, -1, 1)
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "FCOnAskDataByType" ); 					    -- 脚本函数名称
            Set_XSCRIPT_ScriptID( 888969 );											-- 脚本编号  
            Set_XSCRIPT_Parameter( 0, 1 );	
            Set_XSCRIPT_Parameter( 1, -1 );		     
            Set_XSCRIPT_ParamCount( 2 ); 	                                        -- 参数个数  
        Send_XSCRIPT()	
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

function ActivitySchedule_Shop_CloseSameGroupWindow()

    ActivitySchedule_Shop_On_ResetPos()
	
    CloseWindow("ActivitySchedule_Shop2", true)
    -- CloseWindow("ActivitySchedule_Shop", true)
    CloseWindow("Fenzheng_Shop", true)
    CloseWindow("FengmingShop", true)
    CloseWindow("Xiake_Shop", true)
    
    ActivitySchedule_Shop_YunJin    :   SetCheck(0)
	ActivitySchedule_Shop_HuaYu     :   SetCheck(1)
	ActivitySchedule_Shop_JuXia     :   SetCheck(0)
    ActivitySchedule_Shop_TianHuang :   SetCheck(0)
    ActivitySchedule_Shop_XiaKe     :   SetCheck(0)

    local n2606S = Player:GetData("Is2606S")  
    if n2606S ~= 1 then
        ActivitySchedule_Shop_TianHuang:Show()
    else
        ActivitySchedule_Shop_TianHuang:Hide()
    end

    local nXiaKe = Player:GetData("IsXiaKe") 
    if nXiaKe ~= 1 then
        ActivitySchedule_Shop_XiaKe:Hide()
    else
        ActivitySchedule_Shop_XiaKe:Show()
    end

end

