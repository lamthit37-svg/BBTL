--端午开船 批量使用
local g_DuanWu_Boat_GiftBox_MBuy_Frame_UnifiedPosition
local g_MaxNum = 0
local g_BagPos = -1
local g_SelectIdx = 0
local g_nIputNum = 1
local g_ShowItem = {
    [38008611] = {37003203,37003204},
}
--===============================================
-- OnLoad()
--===============================================
function DuanWu_Boat_GiftBox_MBuy_PreLoad()

    this:RegisterEvent( "UI_COMMAND" ); 
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	--逻辑相关的事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

    this:RegisterEvent("CLOSE_DUANWU_BOAT_GIFTBOX_MBUY",false);
    
end

function DuanWu_Boat_GiftBox_MBuy_OnLoad()
	g_DuanWu_Boat_GiftBox_MBuy_Frame_UnifiedPosition = DuanWu_Boat_GiftBox_MBuy_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function DuanWu_Boat_GiftBox_MBuy_OnEvent( event )

    if (event == "UI_COMMAND" and tonumber(arg0) == 88557502) then
        --g_BagPos = tonumber(Get_XParam_INT(0)) 
        g_SelectIdx = tonumber(Get_XParam_INT(0))
        g_MaxNum = tonumber(Get_XParam_INT(1))
        g_LiheId = tonumber(Get_XParam_INT(2))

        DuanWu_Boat_GiftBox_MBuy_InputNum:SetProperty("DefaultEditBox", "True");    --设置输入框为默认输入框
        DuanWu_Boat_GiftBox_MBuy_InputNum:SetText(g_nIputNum)                  --默认输入为1   
        DuanWu_Boat_GiftBox_MBuy_InputNum:SetSelected( 0, -1 ); 
        DuanWu_Boat_GiftBox_MBuy_FreshWindow() 
        this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		DuanWu_Boat_GiftBox_MBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DuanWu_Boat_GiftBox_MBuy_Close_Clicked()
	elseif event == "ADJEST_UI_POS" then
		DuanWu_Boat_GiftBox_MBuy_Frame_On_ResetPos() 	
    elseif event == "CLOSE_DUANWU_BOAT_GIFTBOX_MBUY" then
        if (true ~= this:IsVisible()) then
            return
        end	
        DuanWu_Boat_GiftBox_MBuy_Close_Clicked()
	end
end

--===============================================
--刷新界面信息
--===============================================
function DuanWu_Boat_GiftBox_MBuy_FreshWindow()
    
    if g_ShowItem[g_LiheId][g_SelectIdx] ~= nil then
        local theAction = DataPool:CreateActionItemForShow(g_ShowItem[g_LiheId][g_SelectIdx], 1)
        if (theAction:GetID()~=0) then
            DuanWu_Boat_GiftBox_MBuy_But:SetActionItem(theAction:GetID())
            DuanWu_Boat_GiftBox_MBuy_ItemInfo_Text:SetText(DataPool:Lua_GetItemNameByIndex(g_ShowItem[g_LiheId][g_SelectIdx]))
            DuanWu_Boat_GiftBox_MBuy_ItemInfo_Lilianzhi:SetText(ScriptGlobal_Format("#{DWKC_260515_15}", g_MaxNum))
        end 
    end
     
end

--===============================================
--取出相应的物资
--===============================================
function DuanWu_Boat_GiftBox_MBuy_OK_Clicked()
 
	if g_nIputNum <= 0 then
        PushDebugMessage("#{DWKC_260515_10}")
		return
    end 
    if g_nIputNum > g_MaxNum then
        PushDebugMessage("#{DWKC_260515_11}")
        return
    end
	DuanWu_Boat_GiftBox_MBuy_BuyItem(g_nIputNum)				
end

function DuanWu_Boat_GiftBox_MBuy_BuyItem(count)

    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "OnItemBatchUse" )
        Set_XSCRIPT_ScriptID( 885575 )
        Set_XSCRIPT_Parameter( 0, g_SelectIdx)
        Set_XSCRIPT_Parameter( 1, g_LiheId)
        Set_XSCRIPT_Parameter( 2, count)
        Set_XSCRIPT_ParamCount( 3 )
    Send_XSCRIPT()	
end

function DuanWu_Boat_GiftBox_MBuy_CalMax()    

	DuanWu_Boat_GiftBox_MBuy_InputNum:SetText(g_MaxNum)
    DuanWu_Boat_GiftBox_MBuy_FreshWindow()
end

function DuanWu_Boat_GiftBox_MBuy_TextChanged() 

    local nString = DuanWu_Boat_GiftBox_MBuy_InputNum:GetText()

    --默认为1
    if nString == nil or nString == "" then
        g_nIputNum = 1
        DuanWu_Boat_GiftBox_MBuy_InputNum:SetText(g_nIputNum)
        return
    end

    local nBuysNum = tonumber(nString)
    if nBuysNum == nil then
        g_nIputNum = 1
        DuanWu_Boat_GiftBox_MBuy_InputNum:SetText(g_nIputNum)
        return
    end

    --小于0时
    if nBuysNum <= 0 then
        g_nIputNum = 1
        DuanWu_Boat_GiftBox_MBuy_InputNum:SetText(g_nIputNum)
        return
    end
    
    --大于最大使用数量
    if nBuysNum > g_MaxNum then
        g_nIputNum = g_MaxNum
        DuanWu_Boat_GiftBox_MBuy_InputNum:SetText(g_nIputNum)
        return
    end

    g_nIputNum = nBuysNum
end

function DuanWu_Boat_GiftBox_MBuy_OnHidden()  
    g_MaxNum = 0
    g_BagPos = -1
    g_SelectIdx = 0  
    g_nIputNum = 1
	this:Hide()
end

function DuanWu_Boat_GiftBox_MBuy_Close_Clicked()
	DuanWu_Boat_GiftBox_MBuy_OnHidden()  
end

function DuanWu_Boat_GiftBox_MBuy_Frame_On_ResetPos()
	 DuanWu_Boat_GiftBox_MBuy_Frame:SetProperty("UnifiedPosition", g_DuanWu_Boat_GiftBox_MBuy_Frame_UnifiedPosition)
end
