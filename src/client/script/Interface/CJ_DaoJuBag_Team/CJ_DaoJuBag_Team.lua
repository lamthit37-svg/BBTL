local g_CJ_DaoJuBag_Team_UnifiedPosition;
local g_ExeScript = 999340
local g_UI_Items = {}

local g_TLCJ_TEAMBAG_NUM = 8


function CJ_DaoJuBag_Team_PreLoad()
	--this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("TLCJ_OPENTEAMBAG")
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")	

	this:RegisterEvent("TLCJ_BASEATTRUPDATE",false);


end
function CJ_DaoJuBag_Team_OnLoad()	
	g_CJ_DaoJuBag_Team_UnifiedPosition  =CJ_DaoJuBag_Team_Frame:GetProperty("UnifiedPosition");

    g_UI_Items.teambags = {}
    for i = 1, g_TLCJ_TEAMBAG_NUM do
        g_UI_Items.teambags[i] =  _G[string.format("CJ_DaoJuBag_Team_Equip_Item%d",i)]
        g_UI_Items.teambags[i]:SetProperty("DraggingEnabled", "True")
        g_UI_Items.teambags[i]:SetProperty("DragAcceptName", "JG"..tostring(i))
    end
    g_UI_Items.teambagmask ={}
    for i = 1, g_TLCJ_TEAMBAG_NUM do
        g_UI_Items.teambagmask[i] =  _G[string.format("CJ_DaoJuBag_Team_Equip_Item%d_Mask",i)]
    end
end

function CJ_DaoJuBag_Team_OnEvent(event)

	-- if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
		
	-- end
	if event ==  "TLCJ_OPENTEAMBAG" then
        if tonumber(arg0) == 0 then
            CJ_DaoJuBag_Team_Open()
        elseif  tonumber(arg0) == 1 then
            if this:IsVisible() then
                 CJ_DaoJuBag_Team_Open()
            end
        end
    elseif   event == "TLCJ_BASEATTRUPDATE" and arg0 == "level" then
        CJ_DaoJuBag_Team_CheckEquipLevel()
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		CJ_DaoJuBag_Team_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CJ_DaoJuBag_Team_On_ResetPos()
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

function CJ_DaoJuBag_Team_Open()

    CJ_DaoJuBag_Team_SetAllActionBtn()
    this:Show()
end

function CJ_DaoJuBag_Team_SetAllActionBtn()
    local theAction = nil
    local actionBtn = nil
  
    for i = 1, g_TLCJ_TEAMBAG_NUM do
        theAction = Lua_CreateChiJiAction(7,i-1)
        actionBtn = g_UI_Items.teambags[i]
        if theAction:GetID() ~= 0 and actionBtn ~= nil then
            actionBtn:SetActionItem(theAction:GetID())
        else
            actionBtn:SetActionItem(-1)
        end
    end

    CJ_DaoJuBag_Team_CheckEquipLevel()

end


function CJ_DaoJuBag_Team_CheckEquipLevel()
    for i = 1, g_TLCJ_TEAMBAG_NUM do
        local actionBtn = g_UI_Items.teambags[i]
        local actionId = actionBtn:GetActionItem()
        g_UI_Items.teambagmask[i]:Hide()
        if actionId>0 then
            local showmask = Lua_CheckChiJiEquipLevel(actionId)
            if showmask == 1 then
                g_UI_Items.teambagmask[i]:Show()
            end
        end
    end
end

--点击道具包
function CJ_DaoJuBag_Team_Equip_Item_Click(nPos,bClicked )
    if nPos < 1 or nPos > g_TLCJ_TEAMBAG_NUM or bClicked==1  then
        return 
    end
    local actionBtn = g_UI_Items.teambags[nPos]
    if actionBtn:GetActionItem() < 1 then
        return 
    end
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "TeamBagOpt" )
        Set_XSCRIPT_ScriptID(g_ExeScript)
        Set_XSCRIPT_Parameter(0,1);
        Set_XSCRIPT_Parameter(1,nPos-1);
        Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()  
end

function CJ_DaoJuBag_Team_Equip_ALLBtn_Clicked()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "TeamBagOpt" )
    Set_XSCRIPT_ScriptID(g_ExeScript)
    Set_XSCRIPT_Parameter(0,2);
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()  
end




function CJ_DaoJuBag_Team_Hide_OnClick()
    this:Hide()
end

function CJ_DaoJuBag_Team_On_ResetPos()
	CJ_DaoJuBag_Team_Frame:SetProperty("UnifiedPosition", g_CJ_DaoJuBag_Team_UnifiedPosition);
end

