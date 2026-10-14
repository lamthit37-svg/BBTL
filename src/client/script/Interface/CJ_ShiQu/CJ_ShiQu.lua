local g_CJ_ShiQu_UnifiedPosition;
local g_UICOMMAND = -1
local g_ExeScript = 999340
local g_UI_Items = {}
local g_ItemNum = 8
local g_UICOMMAND = 99934001
local g_NpcId = -1 
local g_objCared = -1

function CJ_ShiQu_PreLoad()
	this:RegisterEvent("TLCJ_OPENDROPBAG")
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")	
	this:RegisterEvent("TLCJ_BASEATTRUPDATE",false);

end
function CJ_ShiQu_OnLoad()	
	g_CJ_ShiQu_UnifiedPosition  =CJ_ShiQu_Frame:GetProperty("UnifiedPosition");
    for i = 1, g_ItemNum do
        g_UI_Items[i] = {
            actionBtn = _G[string.format( "CJ_ShiQu_Item_%d",i)],
            text = _G[string.format( "CJ_ShiQu_Text_%d",i)],
            window = _G[string.format( "CJ_ShiQu_ItemContent_%d",i)],
            mask = _G[string.format( "CJ_ShiQu_Item_%d_Mask",i)],
        }
        g_UI_Items[i].actionBtn:SetProperty("DragAcceptName", "JF"..tostring(i))
        g_UI_Items[i].actionBtn:SetProperty("DraggingEnabled", "True")
    end
end

function CJ_ShiQu_OnEvent(event)

	if event ==  "TLCJ_OPENDROPBAG" then
        if tonumber(arg0) == 1 then
            g_NpcId = tonumber(arg1)
            g_objCared = DataPool : GetNPCIDByServerID(g_NpcId)
            CJ_ShiQu_Open()
         elseif  tonumber(arg0) == 88 then
            g_NpcId = -1
            CJ_ShiQu_Close_OnClicked()
        end
    elseif   event == "TLCJ_BASEATTRUPDATE" and arg0 == "level" then
        CJ_ShiQu_CheckEquipLevel()
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		CJ_ShiQu_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CJ_ShiQu_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
end

-- TLCJ_ITEMCONTAINER_INVALID = 0,
-- TLCJ_ITEMCONTAINER_EQUIPSLOT = 1,
-- TLCJ_ITEMCONTAINER_SKILLSLOT = 2,
-- TLCJ_ITEMCONTAINER_EUIQPBAG = 3,
-- TLCJ_ITEMCONTAINER_ITEMBAG = 4,
-- TLCJ_ITEMCONTAINER_SKILLBAG = 5,
-- TLCJ_ITEMCONTAINER_DROPBAG = 6,

function CJ_ShiQu_Open()

    local theAction = nil
    local actionBtn = nil
    for i = 1, g_ItemNum do
        theAction = Lua_CreateChiJiAction(6,i-1)
        actionBtn = g_UI_Items[i].actionBtn
        if theAction:GetID() ~= 0 and actionBtn ~= nil then
            theAction:SetLockStatus(1)
            actionBtn:SetActionItem(theAction:GetID())
            local itemType,id,szname = TLCJ:GetDropBagItemInfo(i-1)
            if  szname then
                g_UI_Items[i].text:SetText(szname)
            else
                g_UI_Items[i].text:SetText("")
            end
        else
            actionBtn:SetActionItem(-1)
            g_UI_Items[i].text:SetText("")
        end
    end
    if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 1, "CJ_ShiQu")
    end

    CJ_ShiQu_CheckEquipLevel()
    this:Show()
end

function CJ_ShiQu_Item_Clicked(pos)
    if pos < 1 or pos > g_ItemNum then
        return 
    end
    local actionBtn = g_UI_Items[pos].actionBtn
    if actionBtn:GetActionItem() < 1 then
        return 
    end
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PickItem" )
		Set_XSCRIPT_ScriptID(g_ExeScript)
        Set_XSCRIPT_Parameter(0,g_NpcId);
        Set_XSCRIPT_Parameter(1,pos-1);
        Set_XSCRIPT_Parameter(2,-1);
        Set_XSCRIPT_Parameter(3,-1);
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end


function CJ_ShiQu_On_ResetPos()
	CJ_ShiQu_Frame:SetProperty("UnifiedPosition", g_CJ_ShiQu_UnifiedPosition);
end


function CJ_ShiQu_Close_OnClicked()
	this:Hide()
    if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "CJ_ShiQu")
    end
    g_objCared= -1
     g_NpcId = -1 

end

function CJ_ShiQu_AllShiQu_Clicked()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PickAllItem" )
		Set_XSCRIPT_ScriptID(g_ExeScript)
        Set_XSCRIPT_Parameter(0,g_NpcId);
 
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function CJ_ShiQu_CheckEquipLevel()
    for i = 1, g_ItemNum do
        local actionBtn = g_UI_Items[i].actionBtn
        local actionId = actionBtn:GetActionItem()
        g_UI_Items[i].mask:Hide()
        if actionId>0 then
            local showmask = Lua_CheckChiJiEquipLevel(actionId)
            if showmask == 1 then
                g_UI_Items[i].mask:Show()
            end
        end
    end
end