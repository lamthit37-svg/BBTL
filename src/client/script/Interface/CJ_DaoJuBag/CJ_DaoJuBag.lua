local g_CJ_DaoJuBag_UnifiedPosition;
local g_ExeScript = 999340
local g_UI_Items = {}

local g_TLCJ_ITEMBAG_NUM = 6
local g_TLCJ_EQUIPBAG_NUM = 12


function CJ_DaoJuBag_PreLoad()
	--this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("TLCJ_OPENPLAYERBAG")
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")	

	this:RegisterEvent("TLCJ_BASEATTRUPDATE",false);


end
function CJ_DaoJuBag_OnLoad()	
	g_CJ_DaoJuBag_UnifiedPosition  =CJ_DaoJuBag_Frame:GetProperty("UnifiedPosition");

    g_UI_Items.itembags = {}
    for i = 1, g_TLCJ_ITEMBAG_NUM do
        g_UI_Items.itembags[i] =  _G[string.format( "CJ_DaoJuBag_Item%d",i)]
        g_UI_Items.itembags[i]:SetProperty("DragAcceptName", "JD"..tostring(i))
        g_UI_Items.itembags[i]:SetProperty("DraggingEnabled", "True")
    end
    g_UI_Items.equipbags = {}
    for i = 1, g_TLCJ_EQUIPBAG_NUM do
        g_UI_Items.equipbags[i] =  _G[string.format( "CJ_DaoJuBag_Equip_Item%d",i)]
        g_UI_Items.equipbags[i]:SetProperty("DragAcceptName", "JC"..tostring(i))
        g_UI_Items.equipbags[i]:SetProperty("DraggingEnabled", "True")
    end
    g_UI_Items.equipbagmask ={}
    for i = 1, g_TLCJ_EQUIPBAG_NUM do
        g_UI_Items.equipbagmask[i] =  _G[string.format( "CJ_DaoJuBag_Equip_Item%d_Mask",i)]
    end
end

function CJ_DaoJuBag_OnEvent(event)

	-- if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
		
	-- end
	if event ==  "TLCJ_OPENPLAYERBAG" then
        if tonumber(arg0) == 3 then
            CJ_DaoJuBag_Open()
        elseif tonumber(arg0) == 2 then
            if(this:IsVisible()) then
                --只刷新部分
                if tonumber(arg1) > 0 then
                    CJ_DaoJuBag_RefreshBag(tonumber(arg1))
                end
            end
        elseif tonumber(arg0) == 4 then
            if(this:IsVisible()) then
                --只刷新部分
                CJ_DaoJuBag_RefreshBag(3)
            end
        end
    elseif   event == "TLCJ_BASEATTRUPDATE" and arg0 == "level" then
        CJ_DaoJuBag_CheckEquipLevel()
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		CJ_DaoJuBag_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CJ_DaoJuBag_On_ResetPos()
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

function CJ_DaoJuBag_Open()

    CJ_DaoJuBag_SetAllActionBtn()
    this:Show()

    if TLCJ:IsInTLCJScene_Team()==1 then
        CJ_DaoJuBag_TeamBag_Btn:Show()
    else
        CJ_DaoJuBag_TeamBag_Btn:Hide()
    end
end

function CJ_DaoJuBag_SetAllActionBtn()
    local theAction = nil
    local actionBtn = nil
  
    --道具包
    for i = 1, g_TLCJ_ITEMBAG_NUM do
        theAction = Lua_CreateChiJiAction(4,i-1)
        actionBtn = g_UI_Items.itembags[i]
        if theAction:GetID() ~= 0 and actionBtn ~= nil then
            actionBtn:SetActionItem(theAction:GetID())
        else
            actionBtn:SetActionItem(-1)
        end
    end

     --装备包
     for i = 1, g_TLCJ_EQUIPBAG_NUM do
        theAction = Lua_CreateChiJiAction(3,i-1)
        actionBtn = g_UI_Items.equipbags[i]
        if theAction:GetID() ~= 0 and actionBtn ~= nil then
            actionBtn:SetActionItem(theAction:GetID())
        else
            actionBtn:SetActionItem(-1)
        end
    end
    CJ_DaoJuBag_CheckEquipLevel()

end

function  CJ_DaoJuBag_RefreshBag(bagType)
    local theAction = nil
    local actionBtn = nil

    if  bagType == 4 then
         --道具包
        for i = 1, g_TLCJ_ITEMBAG_NUM do
            theAction = Lua_CreateChiJiAction(4,i-1)
            actionBtn = g_UI_Items.itembags[i]
            if theAction:GetID() ~= 0 and actionBtn ~= nil then
                actionBtn:SetActionItem(theAction:GetID())
            else
                actionBtn:SetActionItem(-1)
            end
        end
    elseif  bagType == 3 then
        --装备包
        for i = 1, g_TLCJ_EQUIPBAG_NUM do
            theAction = Lua_CreateChiJiAction(3,i-1)
            actionBtn = g_UI_Items.equipbags[i]
            if theAction:GetID() ~= 0 and actionBtn ~= nil then
                actionBtn:SetActionItem(theAction:GetID())
            else
                actionBtn:SetActionItem(-1)
            end
        end
        CJ_DaoJuBag_CheckEquipLevel()
    end
end

function CJ_DaoJuBag_CheckEquipLevel()
    for i = 1, g_TLCJ_EQUIPBAG_NUM do
        local actionBtn = g_UI_Items.equipbags[i]
        local actionId = actionBtn:GetActionItem()
        g_UI_Items.equipbagmask[i]:Hide()
        if actionId>0 then
            local showmask = Lua_CheckChiJiEquipLevel(actionId)
            if showmask == 1 then
                g_UI_Items.equipbagmask[i]:Show()
            end
        end
    end
end

--点击道具包
function CJ_DaoJuBag_Item_Click(nPos,bClicked )
    if nPos < 1 or nPos > g_TLCJ_ITEMBAG_NUM or bClicked==1  then
        return 
    end
    local actionBtn = g_UI_Items.itembags[nPos]
    if actionBtn:GetActionItem() < 1 then
        return 
    end
    if(IsWindowShow("CJ_DaoJuBag_Team")) then
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "TeamBagOpt" )
        Set_XSCRIPT_ScriptID(g_ExeScript)
        Set_XSCRIPT_Parameter(0,3);
        Set_XSCRIPT_Parameter(1,nPos-1);
        Set_XSCRIPT_Parameter(2,4);
        Set_XSCRIPT_ParamCount(3)
        Send_XSCRIPT()
    else    
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "UseItem" )
        Set_XSCRIPT_ScriptID(g_ExeScript)
        Set_XSCRIPT_Parameter(0,4);
        Set_XSCRIPT_Parameter(1,nPos-1);
        Set_XSCRIPT_ParamCount(2)
        Send_XSCRIPT()  
    end
end


--点击装备包
function CJ_DaoJuBag_Equip_Item_Click(nPos,bClicked )
    if nPos < 1 or nPos > g_TLCJ_EQUIPBAG_NUM or bClicked==1  then
        return 
    end
    local actionBtn = g_UI_Items.equipbags[nPos]
    if actionBtn:GetActionItem() < 1 then
        return 
    end
    if(IsWindowShow("CJ_DaoJuBag_Team")) then
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "TeamBagOpt" )
        Set_XSCRIPT_ScriptID(g_ExeScript)
        Set_XSCRIPT_Parameter(0,3);
        Set_XSCRIPT_Parameter(1,nPos-1);
        Set_XSCRIPT_Parameter(2,3);
        Set_XSCRIPT_ParamCount(3)
        Send_XSCRIPT()
    else   
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "UseItem" )
            Set_XSCRIPT_ScriptID(g_ExeScript)
            Set_XSCRIPT_Parameter(0,3);
            Set_XSCRIPT_Parameter(1,nPos-1);
            Set_XSCRIPT_ParamCount(2)
        Send_XSCRIPT()
    end
end


function CJ_DaoJuBag_Hide_OnClick()
    this:Hide()
end

function CJ_DaoJuBag_On_ResetPos()
	CJ_DaoJuBag_Frame:SetProperty("UnifiedPosition", g_CJ_DaoJuBag_UnifiedPosition);
end


function CJ_DaoJuBag_Equip_DestoryBtn_Clicked()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "DestoryAllEquipBagItem" )
    Set_XSCRIPT_ScriptID(g_ExeScript)
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

function CJ_DaoJuBag_TeamBag_Btn_Clicked()
    if TLCJ:IsInTLCJScene_Team()==1 then
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "TeamBagOpt" )
        Set_XSCRIPT_ScriptID(g_ExeScript)
        Set_XSCRIPT_Parameter(0,4);
        Set_XSCRIPT_ParamCount(1)
        Send_XSCRIPT()
    end
end