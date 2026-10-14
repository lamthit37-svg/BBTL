
--- 缝绘蜜语金丝界面
--- Author: David Gao 2012.07.23
--- 界面相关参数
local g_Miyu_huanyuan_ObjCared = -1
local g_Miyu_huanyuan_MAX_OBJ_DISTANCE = 3.0
---------------------------------------
--- 逻辑相关参数
local g_Miyu_huanyuan_Dress_Pos     = -1      --- 时装ID
---------------------------------------

function Miyu_huanyuan_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)

    this:RegisterEvent("UPDATE_DRESS_MIYU")
end

function Miyu_huanyuan_OnLoad()
    g_Miyu_huanyuan_Dress_Pos = -1
    Miyu_huanyuan_OK : Disable()
end

-- OnEvent
function Miyu_huanyuan_OnEvent(event)
    if( event == "UI_COMMAND" and tonumber(arg0) == 201207232 ) then
	    g_Miyu_huanyuan_ObjCared = Get_XParam_INT(0)
        if this:IsVisible() and g_Miyu_huanyuan_ObjCared == -1 then
            Miyu_huanyuan_OnClosed()
        else
		    Miyu_huanyuan_Init()
    		this:Show()
		    g_Miyu_huanyuan_ObjCared = Target:GetServerId2ClientId(g_Miyu_huanyuan_ObjCared)
    		this:CareObject(g_Miyu_huanyuan_ObjCared, 1, "Miyu_huanyuan")
        end
    elseif( event == "UPDATE_DRESS_MIYU" ) then
        Miyu_huanyuan_Update( arg0, arg1, arg2, arg3 )
	elseif(event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_Miyu_huanyuan_ObjCared) then
			return
		end
		if( ( arg1 == "distance" and tonumber(arg2)> g_Miyu_huanyuan_MAX_OBJ_DISTANCE ) or arg1=="destroy") then
            Miyu_huanyuan_OnClosed()
			this:CareObject(g_Miyu_huanyuan_ObjCared, 0, "Miyu_huanyuan")
		end
	end

end

function Miyu_huanyuan_Init()
    Miyu_huanyuan_OnClear()
    g_Miyu_huanyuan_Dress_Pos = -1
    Miyu_huanyuan_OK : Disable()
    return
end

function Miyu_huanyuan_OnClear()
    if ( g_Miyu_huanyuan_Dress_Pos ~= -1 ) then
        Miyu_huanyuan_Item:SetActionItem( -1 )
        LifeAbility:Lock_Packet_Item( g_Miyu_huanyuan_Dress_Pos, 0 )
        g_Miyu_huanyuan_Dress_Pos = -1
    end

    return
end

function Miyu_huanyuan_OnClosed()
    Miyu_huanyuan_OnClear()
    this:Hide()
    return
end

function Miyu_huanyuan_Close_Clicked()
    Miyu_huanyuan_OnClosed()
    return
end

function Miyu_huanyuan_OK_Clicked()
    --- 角色当前未处于安全时间内；
    if( tonumber( DataPool:GetLeftProtectTime() ) >0 )    then
        PushDebugMessage( "#{OR_PILFER_LOCK_FLAG}" ) --- 在安全时间内无法进行此操作。打开包裹栏，点击防盗号按钮可以自行设置安全时间
        return 0
    end

    --- 电话密保和二级密码保护当前未处于保护状态；
    if CheckPhoneMibaoAndMinorPassword() == 0 then
		return 0
	end

    Clear_XSCRIPT();
	    Set_XSCRIPT_Function_Name( "OnEraseDrawedSweetWords" );
		Set_XSCRIPT_ScriptID( 889933 );
		Set_XSCRIPT_Parameter(0, g_Miyu_huanyuan_Dress_Pos );
		Set_XSCRIPT_ParamCount( 1 );
    Send_XSCRIPT();

    return
end

function Miyu_huanyuan_Cancel_Clicked()
    Miyu_huanyuan_OnClosed()
    return
end

function Miyu_huanyuan_Resume( index )
    if ( this:IsVisible() ) then
        Miyu_huanyuan_Item : SetActionItem( -1 )
        LifeAbility : Lock_Packet_Item( g_Miyu_huanyuan_Dress_Pos, 0 ) 
        g_Miyu_huanyuan_Dress_Pos = -1
    end

    return
end

function Miyu_huanyuan_Update( eventIndex, creatorName, itemBagPos, paramValue )
    local iIndex  = tonumber( eventIndex )
    local iBagPos = tonumber( itemBagPos )
    local theActionItem = EnumAction( iBagPos, "packageitem" )
    if theActionItem:GetID() ~= 0 then
        if iIndex == 4 then
            --- 是否是已经缝绘蜜语金丝
            if tonumber( paramValue ) <= 0 then
                PushDebugMessage( "#{MYJS_120723_22}" )
                return
            end

            if g_Miyu_huanyuan_Dress_Pos ~= -1 then
                LifeAbility:Lock_Packet_Item( g_Miyu_huanyuan_Dress_Pos, 0 )
            end

            Miyu_huanyuan_Item:SetActionItem( theActionItem:GetID() )
            LifeAbility:Lock_Packet_Item( iBagPos, 1 )
            g_Miyu_huanyuan_Dress_Pos = iBagPos
        end
    end

    if g_Miyu_huanyuan_Dress_Pos ~= -1 then
        Miyu_huanyuan_OK : Enable()
    end
    return
end
