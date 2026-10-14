
--- 缝绘蜜语金丝界面
--- 界面相关参数

local g_Miyu_xiugai_UnifiedPosition;
local g_Miyu_xiugai_ObjCared = -1
local g_Miyu_xiugai_MAX_OBJ_DISTANCE = 3.0
---------------------------------------
--- 逻辑相关参数
local g_Miyu_xiugai_Dress_Pos     = -1      --- 时装ID
---------------------------------------

--- 道具ID
local g_Miyu_xiugai_Miyujinsi_ItemID = 
{
    38000402, 38000403, 38000404, 38000405, 38000406, 38000430, 38000431, 38000432, 38000433, 38000434, 38001165, 38001166, 38001337, 38001338, 38006194, 38006195,
}
function Miyu_xiugai_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--this:RegisterEvent("OBJECT_CARED_EVENT",false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("MIYUJINSI_RENAME",false)
end

function Miyu_xiugai_OnLoad()
    g_Miyu_xiugai_Dress_Pos = -1
    g_TreasureBox_UnifiedPosition = Miyu_xiugai_Frame:GetProperty("UnifiedPosition")
    Miyu_xiugai_OK : Disable()
end

-- OnEvent
function Miyu_xiugai_OnEvent(event)
    if( event == "UI_COMMAND" and tonumber(arg0) == 20220213 ) then
	    g_Miyu_xiugai_ObjCared = Get_XParam_INT(0)
        if this:IsVisible() and g_Miyu_xiugai_ObjCared == -1 then
            Miyu_xiugai_OnClosed()
        else
		    Miyu_xiugai_Init()
    		this:Show()
		    g_Miyu_xiugai_ObjCared = Target:GetServerId2ClientId(g_Miyu_xiugai_ObjCared)
    		this:CareObject(g_Miyu_xiugai_ObjCared, 1, "Miyu_xiugai")
        end
    elseif( event == "MIYUJINSI_RENAME" ) then
        Miyu_xiugai_Update( arg0, arg1, arg2, arg3 )
	-- elseif(event == "OBJECT_CARED_EVENT") then
	-- 	if(tonumber(arg0) ~= g_Miyu_xiugai_ObjCared) then
	-- 		return
	-- 	end
	-- 	if( ( arg1 == "distance" and tonumber(arg2)> g_Miyu_xiugai_MAX_OBJ_DISTANCE ) or arg1=="destroy") then
    --         Miyu_xiugai_OnClosed()
	-- 		this:CareObject(g_Miyu_xiugai_ObjCared, 0, "Miyu_xiugai")
    -- 	end
    elseif( event == "ADJEST_UI_POS") then
        Miyu_xiugai_ResetPos()
    elseif( event == "VIEW_RESOLUTION_CHANGED") then
        Miyu_xiugai_ResetPos()
	end

end

--=========================================================
--刷新位置
--=========================================================
function Miyu_xiugai_ResetPos()
	Miyu_xiugai_Frame:SetProperty("UnifiedPosition", g_TreasureBox_UnifiedPosition);
end

function Miyu_xiugai_Init()
    Miyu_xiugai_OnClear()
    g_Miyu_xiugai_Dress_Pos = -1
    Miyu_xiugai_OK : Disable()
    return
end

function Miyu_xiugai_OnClear()
    if ( g_Miyu_xiugai_Dress_Pos ~= -1 ) then
        Miyu_xiugai_Item:SetActionItem( -1 )
        LifeAbility:Lock_Packet_Item( g_Miyu_xiugai_Dress_Pos, 0 )
        g_Miyu_xiugai_Dress_Pos = -1
    end

    return
end

function Miyu_xiugai_OnClosed()
    Miyu_xiugai_OnClear()
    this:Hide()
    return
end

function Miyu_xiugai_Close_Clicked()
    Miyu_xiugai_OnClosed()
    return
end

function Miyu_xiugai_OK_Clicked()
    --- 角色当前未处于安全时间内；
    if( tonumber( DataPool:GetLeftProtectTime() ) >0 )    then
        PushDebugMessage( "#{OR_PILFER_LOCK_FLAG}" ) --- 在安全时间内无法进行此操作。打开包裹栏，点击防盗号按钮可以自行设置安全时间
        return 0
    end

    --- 电话密保和二级密码保护当前未处于保护状态；
    if CheckPhoneMibaoAndMinorPassword() == 0 then
		return 0
    end
    
    if g_Miyu_xiugai_Dress_Pos == - 1 then
        PushDebugMessage( "#{MYJS_220125_16}" )
        return 
    end

    Clear_XSCRIPT();
	    Set_XSCRIPT_Function_Name( "Rename" );
		Set_XSCRIPT_ScriptID( 889933 );
		Set_XSCRIPT_Parameter(0, g_Miyu_xiugai_Dress_Pos );
		Set_XSCRIPT_ParamCount( 1 );
    Send_XSCRIPT();

    Miyu_xiugai_OK : Disable()

    return
end

function Miyu_xiugai_Cancel_Clicked()
    Miyu_xiugai_OnClosed()
    return
end

function Miyu_xiugai_Resume( index )
    if ( this:IsVisible() ) then
        Miyu_xiugai_Item : SetActionItem( -1 )
        LifeAbility : Lock_Packet_Item( g_Miyu_xiugai_Dress_Pos, 0 ) 
        g_Miyu_xiugai_Dress_Pos = -1
        Miyu_xiugai_OK : Disable()
      
    end

    return
end

 function Miyu_xiugai_Update( eventIndex, creatorName, itemBagPos, paramValue )
     local iIndex  = tonumber( eventIndex )
     local iBagPos = tonumber( itemBagPos )
     local theActionItem = EnumAction( iBagPos, "packageitem" )
     if theActionItem:GetID() ~= 0 then
         if iIndex == 1 then
--             --- 是否是永久时装
            if tonumber( paramValue ) ~= -1 then
                PushDebugMessage( "#{MYJS_220125_10}" )
                return
            end

--             --- 判断时装是否已经被缝绘
            if creatorName == nil or tostring(creatorName) == "" then
                PushDebugMessage( "#{MYJS_220125_10}" )
                return
            end
            

            local sPos, ePos = string.find( creatorName, "*" )
            if sPos == nil or ePos == nil then
                PushDebugMessage( "#{MYJS_220125_10}" )
                return 
            end
            
            if g_Miyu_xiugai_Dress_Pos ~= -1 then
                LifeAbility:Lock_Packet_Item( g_Miyu_xiugai_Dress_Pos, 0 )
            end

            Miyu_xiugai_Item : SetActionItem( theActionItem:GetID() )
            LifeAbility:Lock_Packet_Item( iBagPos, 1 )
            g_Miyu_xiugai_Dress_Pos = iBagPos
         elseif iIndex == 2 then
            --- 判断当前右键点击的道具是否为蜜语金丝
            local itemID = PlayerPackage : GetItemTableIndex( iBagPos )
            local isMiyuItem = 0
            for index=1, table.getn( g_Miyu_xiugai_Miyujinsi_ItemID ) do
                if itemID == g_Miyu_xiugai_Miyujinsi_ItemID[index] then
                    isMiyuItem = 1 
                     break
                end
            end
            if isMiyuItem == 0 then
                PushDebugMessage( "#{MYJS_220125_09}" )
                return
            end

            --- 判断蜜语金丝是否已记录角色名称
            if creatorName == nil or tostring(creatorName) == "" then
                PushDebugMessage( "#{MYJS_220125_09}" )
                return
            end


            --- 当前密语金丝记录的角色名称是否含有*号
            local sPos, ePos = string.find( creatorName, "*" )
            if sPos == nil or ePos == nil then
                PushDebugMessage( "#{MYJS_220125_09}" )
                return 
            end

            ---
            if g_Miyu_xiugai_Dress_Pos ~= -1 then
                LifeAbility:Lock_Packet_Item( g_Miyu_xiugai_Dress_Pos, 0 )
            end

            Miyu_xiugai_Item : SetActionItem( theActionItem:GetID() )
            LifeAbility:Lock_Packet_Item( iBagPos, 1 )
            g_Miyu_xiugai_Dress_Pos = iBagPos
         end
     end


    if g_Miyu_xiugai_Dress_Pos ~= -1 then
        Miyu_xiugai_OK : Enable()
    end
end
