--XL_Shop

local g_XL_Shop_Frame_UnifiedXPosition;
local g_XL_Shop_Frame_UnifiedYPosition;  
local MAX_OBJ_DISTANCE = 5.0;

local g_XL_Curpage = 1
local g_XL_TotalPage= 0
local g_XL_PerPage =12
local g_XL_itemctl = {}
local g_XL_Tabctl = {}
local g_XL_Type = 1
local g_XL_TargetID = 0
local g_XL_NpcId=0
local g_XL_LimitData = {0}

local g_XL_ShopItem = {
    [1] = {itemid = 30008130, itemnum = 1, yuanbao = 480, limitcnt = 1, type = 1, discount = 1},
    [2] = {itemid = 30008130, itemnum = 1, yuanbao = 600, limitcnt = 20, type = 2, discount = 0},
}
function XL_Shop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false) 
	this:RegisterEvent("OBJECT_CARED_EVENT",false)  
    this:RegisterEvent("PLAYER_LEAVE_WORLD",false) 

end

function XL_Shop_OnEvent(event) 
    if ( event == "UI_COMMAND" and tonumber(arg0) == 99976701 ) then
    	if IsWindowShow("XL_MBuy") then
			CloseWindow("XL_MBuy", true)
		end
        
        local paramcount = Get_XParam_INT_Count()
        local operator = Get_XParam_INT(0)
        g_XL_TargetID = Get_XParam_INT(1)
        g_XL_Type = Get_XParam_INT(2)
        
        XL_Shop_CleanUp()
        for i = 3, paramcount-1 do
            local data = Get_XParam_INT(i)
            g_XL_LimitData[i-2] = data
        end
	 
		if operator == 1 then
            local objCared = DataPool : GetNPCIDByServerID(g_XL_TargetID)
            this:CareObject(objCared, 1, "XL_Shop");
            XL_Shop_OnShown()
            OpenWindow("Packet")
		elseif operator == 2 and this:IsVisible() then
            XL_Shop_OnShown()
		end    
	elseif( event == "ADJEST_UI_POS" ) then
		XL_Shop_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		XL_Shop_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		XL_Shop_Close()    
	elseif event == "PLAYER_LEAVE_WORLD" then
		XL_Shop_Close()
    elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end 
        --如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
			XL_Shop_Close()
		end
	end
end

function XL_Shop_OnLoad()  
	-- 保存界面的默认相对位置
	g_XL_Shop_Frame_UnifiedXPosition	= XL_Shop_Frame:GetProperty("UnifiedXPosition");
    g_XL_Shop_Frame_UnifiedYPosition	= XL_Shop_Frame:GetProperty("UnifiedYPosition");  
    for i = 1, g_XL_PerPage do
        g_XL_itemctl[i] = {}
        g_XL_itemctl[i].act  = _G["XL_Shop_Item"..i]
        g_XL_itemctl[i].name = _G["XL_Shop_ItemInfo"..i.."_Text"] 
        g_XL_itemctl[i].money= _G["XL_Shop_ItemInfo"..i.."_GB"]  
        g_XL_itemctl[i].limit= _G["XL_Shop_Item"..i.."_BuyLimitNum"] 
        g_XL_itemctl[i].mask=_G["XL_Shop_Item"..i.."_Mask"] 
        g_XL_itemctl[i].discount= _G["XL_Shop_Item"..i.."_Discount"]   
    end 
    g_XL_Tabctl[1] = XL_Shop_Tab1
    g_XL_Tabctl[2] = XL_Shop_Tab2
end 

function XL_Shop_CleanUp()
    for i = 1, g_XL_PerPage do
        g_XL_LimitData[i] = 0
    end
end

function XL_Shop_OnShown()
    
    g_XL_Tabctl[g_XL_Type]:SetCheck(1)
    for i = 1, table.getn(g_XL_itemctl) do
        g_XL_itemctl[i].name:SetText("") 
        g_XL_itemctl[i].money:SetText("") 
        g_XL_itemctl[i].limit:SetText("")
        g_XL_itemctl[i].act:SetActionItem(-1)
        g_XL_itemctl[i].mask:Hide()
        g_XL_itemctl[i].discount:Hide()
    end
    
    if g_XL_Type == 1 then
        XL_Shop_Watch_Text:SetText("#{XLSD_251103_07}")
    elseif g_XL_Type == 2 then
        XL_Shop_Watch_Text:SetText("#{XLSD_251103_08}")
    end
    
    local plimit = 0
    local j = 0
    for i = 1, table.getn(g_XL_ShopItem) do
        if g_XL_ShopItem[i].type == g_XL_Type then   
            j = j + 1
            local id = g_XL_ShopItem[i].itemid
            local num= g_XL_ShopItem[i].itemnum
            local limitcnt = g_XL_ShopItem[i].limitcnt
            local discount = g_XL_ShopItem[i].discount
            local nYB = g_XL_ShopItem[i].yuanbao
        
            local theAction = DataPool:CreateActionItemForShow(id, num)
	        if theAction:GetID() ~= 0 then
	    	    g_XL_itemctl[j].act:SetActionItem(theAction:GetID())
                g_XL_itemctl[j].name:SetText(theAction:GetName())
            end    
            g_XL_itemctl[j].money:SetText(ScriptGlobal_Format( "#{XLSD_251103_09}",nYB))
            if limitcnt <= 0 then
                g_XL_itemctl[j].limit:Hide() 
            else
                plimit = plimit + 1
                local limitweek_self = limitcnt - g_XL_LimitData[plimit]
                g_XL_itemctl[j].limit:Show()          
                g_XL_itemctl[j].limit:SetText("#e010101#cFFFFFF"..limitweek_self)
                if limitweek_self <= 0 then
                    g_XL_itemctl[j].act:Disable()
                else            
                    g_XL_itemctl[j].act:Enable()
                end
            end   
            if discount == 1 then
                g_XL_itemctl[j].discount:Show()
            end
        end
    end

  	this:Show();
end 

--================================================
-- 界面的默认相对位置
--================================================
function XL_Shop_ResetPos()
	XL_Shop_Frame:SetProperty("UnifiedXPosition", g_XL_Shop_Frame_UnifiedXPosition);
	XL_Shop_Frame:SetProperty("UnifiedYPosition", g_XL_Shop_Frame_UnifiedYPosition); 
end 

function XL_Shop_Close() 
	if IsWindowShow("XL_MBuy") then
		CloseWindow("XL_MBuy", true)
	end
    g_XL_Curpage = 1
	this:Hide();
end
 
function XL_Shop_Btn_Clicked(index)  
    if index < 1 or index > g_XL_PerPage then
        return
    end
	local j = 0
	local tbIndex = 0
    for i = 1, table.getn(g_XL_ShopItem) do
        if g_XL_ShopItem[i].type == g_XL_Type then
			j = j+1
			if j == index then
            	tbIndex = i
				break
			end
        end
    end
	if tbIndex < 1 or tbIndex > 2 then
		return
	end
   -- local tblinfo= Lua_GetZBSShopData(g_XL_Type, g_XL_Curpage, g_XL_PerPage)	
--	if type(tblinfo) ~= "table" then
--		return
  --  end 
    
  --  if table.getn(tblinfo) < index then
  --      return
   -- end
    
   -- Clear_XSCRIPT()
    --    Set_XSCRIPT_Function_Name("buyitem")
    --    Set_XSCRIPT_ScriptID( 999767 )
    --    Set_XSCRIPT_Parameter( 0, g_XL_TargetID ); 
    --    Set_XSCRIPT_Parameter( 1, g_XL_Type ); 
    --    Set_XSCRIPT_Parameter( 2, index ); 
    --    Set_XSCRIPT_ParamCount( 3 ); 
    --Send_XSCRIPT()
    local curbuycnt = 0
    local plimit = 0
    local j = 0
    for i = 1, table.getn(g_XL_ShopItem) do
        if g_XL_ShopItem[i].type == g_XL_Type then   
            j = j + 1
            local limitcnt = g_XL_ShopItem[i].limitcnt
            if limitcnt > 0 then
                plimit = plimit + 1
                if j == index then
                    curbuycnt = g_XL_LimitData[plimit]
                    break
                end
            end 
        end  
    end    
    PushEvent( "UI_COMMAND", 99976703, g_XL_TargetID, g_XL_Type, index, curbuycnt )
	this:Show()

end

function XL_Shop_TabOnClick(nIndex)
    if nIndex < 1 or nIndex > 2 then
        return
    end
    g_XL_Type = nIndex
    XL_Shop_Update()
end

function XL_Shop_Update()
    if g_XL_Type < 1 or g_XL_Type > 2 then
        return
    end
    
    Clear_XSCRIPT()
       Set_XSCRIPT_Function_Name("RefreshUI")
       Set_XSCRIPT_ScriptID( 999767 )
       Set_XSCRIPT_Parameter( 0, g_XL_TargetID ); 
       Set_XSCRIPT_Parameter( 1, g_XL_Type ); 
       Set_XSCRIPT_Parameter( 2, 2 ); 
       Set_XSCRIPT_ParamCount( 3 ); 
    Send_XSCRIPT() 
end
