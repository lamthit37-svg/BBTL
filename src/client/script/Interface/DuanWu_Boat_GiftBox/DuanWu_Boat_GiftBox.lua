--端午开船 批量
local g_DuanWu_Boat_GiftBox_Frame_UnifiedPosition
local g_BatchUse = 0
local g_Select = 0
local g_LiheId = 0
local g_BagPos = -1
local g_ShowItem = {
    [38008611] = {37003203,37003204},
}
--===============================================
-- OnLoad()
--===============================================
function DuanWu_Boat_GiftBox_PreLoad()
    this:RegisterEvent( "UI_COMMAND" );                   -- UI_COMMAND
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

end

function DuanWu_Boat_GiftBox_OnLoad()
	g_DuanWu_Boat_GiftBox_Frame_UnifiedPosition = DuanWu_Boat_GiftBox_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function DuanWu_Boat_GiftBox_OnEvent( event )
	if (event == "UI_COMMAND" and tonumber(arg0) == 88557501) then

        DuanWu_Boat_GiftBox_Clear()

        g_LiheId = tonumber(Get_XParam_INT(0))
        g_BagPos = tonumber(Get_XParam_INT(1))
        DuanWu_Boat_GiftBox_FreshWindow() 
        this:Show()
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 88557503) then
        if (true ~= this:IsVisible()) then
            return
        end
        DuanWu_Boat_GiftBox_OnHidden()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		DuanWu_Boat_GiftBox_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DuanWu_Boat_GiftBox_OnHidden()
	elseif event == "ADJEST_UI_POS" then
		DuanWu_Boat_GiftBox_Frame_On_ResetPos() 	
	end
end

--===============================================
--刷新界面信息
--===============================================
function DuanWu_Boat_GiftBox_FreshWindow()

    if g_ShowItem[g_LiheId][1] ~= nil and g_ShowItem[g_LiheId][2] ~= nil then
        local theAction = DataPool:CreateActionItemForShow(g_ShowItem[g_LiheId][1], 1)
        if (theAction:GetID()~=0) then
            DuanWu_Boat_GiftBox_Item1:SetActionItem(theAction:GetID())
        end

        local theAction = DataPool:CreateActionItemForShow(g_ShowItem[g_LiheId][2], 1)
        if (theAction:GetID()~=0) then
            DuanWu_Boat_GiftBox_Item2:SetActionItem(theAction:GetID())
        end

        DuanWu_Boat_GiftBox_Item1_Name:SetText(DataPool:Lua_GetItemNameByIndex(g_ShowItem[g_LiheId][1]))
        DuanWu_Boat_GiftBox_Item2_Name:SetText(DataPool:Lua_GetItemNameByIndex(g_ShowItem[g_LiheId][2]))
        local str = ScriptGlobal_Format("#{DWKC_260515_05}", DataPool:Lua_GetItemNameByIndex(g_LiheId))
        DuanWu_Boat_GiftBox_DragTitle:SetText(str)
        DuanWu_Boat_GiftBox_Info:SetText("#{DWKC_260515_22}")
    end
    
end

function DuanWu_Boat_GiftBox_OnGetClicked()

    if g_Select == 0 then
        PushDebugMessage("#{DWKC_260515_24}")
        return
    end

    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "SelectItem" ) 				
        Set_XSCRIPT_ScriptID( 885575 )									  
        Set_XSCRIPT_Parameter( 0, g_BatchUse)	 
        Set_XSCRIPT_Parameter( 1, g_Select)
        Set_XSCRIPT_Parameter( 2, g_LiheId)   
        Set_XSCRIPT_ParamCount( 3 )  
    Send_XSCRIPT()	
end

function DuanWu_Boat_GiftBox_OnItemClicked(idx)
    if idx == 1 and g_Select == 1 then
        DuanWu_Boat_GiftBox_Item1_Mask:Hide()
        g_Select = 0
        return
    end
    if idx == 1 and g_Select ~= 1 then
        DuanWu_Boat_GiftBox_Item1_Mask:Show()
        DuanWu_Boat_GiftBox_Item2_Mask:Hide()
        g_Select = 1
        return
    end
    if idx == 2 and g_Select == 2 then
        DuanWu_Boat_GiftBox_Item2_Mask:Hide()
        g_Select = 0
        return
    end
    if idx == 2 and g_Select ~= 2 then
        DuanWu_Boat_GiftBox_Item2_Mask:Show()
        DuanWu_Boat_GiftBox_Item1_Mask:Hide()
        g_Select = 2
        return
    end
end

function DuanWu_Boat_GiftBox_OnHidden()
    PushEvent("CLOSE_DUANWU_BOAT_GIFTBOX_MBUY")
    DuanWu_Boat_GiftBox_Clear() 
	this:Hide()
end

function DuanWu_Boat_GiftBox_Frame_On_ResetPos()
	 DuanWu_Boat_GiftBox_Frame:SetProperty("UnifiedPosition", g_DuanWu_Boat_GiftBox_Frame_UnifiedPosition)
end

function DuanWu_Boat_GiftBox_Clear()
    DuanWu_Boat_GiftBox_Item1_Mask:Hide()
    DuanWu_Boat_GiftBox_Item2_Mask:Hide()
    DuanWu_Boat_GiftBox_Item1_Name:SetText()
    DuanWu_Boat_GiftBox_Item2_Name:SetText()
    DuanWu_Boat_GiftBox_Item1:SetActionItem(-1)
    DuanWu_Boat_GiftBox_Item2:SetActionItem(-1)
    DuanWu_Boat_GiftBox_CheckBox:SetCheck(0)
    DuanWu_Boat_GiftBox_Info:SetText("")
    g_BatchUse = 0
    g_Select = 0
    g_LiheId = 0
    g_BagPos = -1
end

function DuanWu_Boat_GiftBox_Clicked()
    if g_BatchUse == 0 then
        DuanWu_Boat_GiftBox_CheckBox:SetCheck(1)
        g_BatchUse = 1
    else
        DuanWu_Boat_GiftBox_CheckBox:SetCheck(0)
        g_BatchUse = 0
    end
end