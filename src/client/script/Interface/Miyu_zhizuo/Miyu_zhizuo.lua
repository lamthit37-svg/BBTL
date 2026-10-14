
--- 缝绘蜜语金丝界面
--- Author: David Gao 2012.07.23
--- 界面相关参数
local g_Miyu_zhizuo_MAX_OBJ_DISTANCE = 3.0
local g_Miyu_zhizuo_objCared = -1
local g_Miyu_zhizuo_Frame_UnifiedPosition;
---------------------------------------
--- 逻辑相关参数
local g_Miyu_zhizuo_Dress_Pos     = -1      --- 时装ID
local g_Miyu_zhizuo_Miyujinsi_Pos = -1      --- 蜜语金丝
---------------------------------------
--- 道具ID
local g_Miyu_zhizuo_Miyujinsi_ItemID = 
{
    38000402, 38000403, 38000404, 38000405, 38000406, 38000430, 38000431, 38000432, 38000433, 38000434, 38001165, 38001166, 38001337, 38001338, 38006194,38006195
}

function Miyu_zhizuo_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)

	this:RegisterEvent("UPDATE_DRESS_MIYU")
end

function Miyu_zhizuo_OnLoad()
    g_Miyu_zhizuo_Dress_Pos     = -1
    g_Miyu_zhizuo_Miyujinsi_Pos = -1
end

-- OnEvent
function Miyu_zhizuo_OnEvent(event)

    if( event == "UI_COMMAND" and tonumber(arg0) == 201207231 ) then
    	g_Miyu_zhizuo_objCared = Get_XParam_INT(0)
        if this:IsVisible() and g_Miyu_zhizuo_objCared == -1 then
            Miyu_zhizuo_OnClosed()
        else
		    Miyu_zhizuo_Init()
            this:Show()
	    	g_Miyu_zhizuo_objCared = Target:GetServerId2ClientId( g_Miyu_zhizuo_objCared )
		    this:CareObject( g_Miyu_zhizuo_objCared, 1, "Miyu_zhizuo")
        end
    elseif( event == "UPDATE_DRESS_MIYU" ) then
        Miyu_zhizuo_Update( arg0, arg1, arg2, arg3 )
	elseif(event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_Miyu_zhizuo_objCared ) then
			return
		end
		if( ( arg1 == "distance" and tonumber(arg2)> g_Miyu_zhizuo_MAX_OBJ_DISTANCE ) or arg1=="destroy") then
            Miyu_zhizuo_OnClosed()
			this:CareObject( g_Miyu_zhizuo_objCared , 0, "Miyu_zhizuo")
		end
	end

end

function Miyu_zhizuo_Update( eventIndex, creatorName, itemBagPos, paramValue )
    local iIndex  = tonumber( eventIndex )
    local iBagPos = tonumber( itemBagPos )
    local theActionItem = EnumAction( iBagPos, "packageitem" )
    if theActionItem:GetID() ~= 0 then
        if iIndex == 1 then         --- 装备类，需要时装
            --- 是否是永久时装
            if tonumber( paramValue ) ~= -1 then
                PushDebugMessage( "#{MYJS_120723_09}" )
                return
            end

            --- 判断时装是否已经被缝绘
            if creatorName  ~= "" then
                PushDebugMessage( "#{MYJS_120723_10}" )
                return
            end

            if g_Miyu_zhizuo_Dress_Pos ~= -1 then
                LifeAbility:Lock_Packet_Item( g_Miyu_zhizuo_Dress_Pos, 0 )
            end

            Miyu_zhizuo_Item:SetActionItem( theActionItem:GetID() )
            LifeAbility:Lock_Packet_Item( iBagPos, 1 )
            g_Miyu_zhizuo_Dress_Pos = iBagPos

        elseif iIndex == 2 then     --- 道具：蜜语金丝
            --- 判断当前右键点击的道具是否为蜜语金丝
            local itemID = PlayerPackage : GetItemTableIndex( iBagPos )
            local isMiyuItem = 0
            for index=1, table.getn( g_Miyu_zhizuo_Miyujinsi_ItemID ) do
                if itemID == g_Miyu_zhizuo_Miyujinsi_ItemID[index] then
                    isMiyuItem = 1 
                     break
                end
            end
            if isMiyuItem == 0 then
                PushDebugMessage( "#{MYJS_120723_12}" )
                return
            end

            --- 判断蜜语金丝是否已记录角色名称
            if creatorName == nil or tostring(creatorName) == "" then
                PushDebugMessage( "#{MYJS_120723_11}" )
                return
            end

            --- 当前密语金丝记录的角色名称是否是自己
            if creatorName == Player:GetName() then
                PushDebugMessage( "#{MYJS_120723_13}" )
                return
            end

            --- 当前密语金丝记录的角色名称是否含有*号
            local sPos, ePos = string.find( creatorName, "*" )
            if sPos ~= nil and ePos ~= nil then
                PushDebugMessage( "#{MYJS_120723_32}" )
                return 
            end

            ---
            if g_Miyu_zhizuo_Miyujinsi_Pos ~= -1 then
                LifeAbility:Lock_Packet_Item( g_Miyu_zhizuo_Miyujinsi_Pos, 0 )
            end

            Miyu_zhizuo_Qingrentang : SetActionItem( theActionItem:GetID() )
            LifeAbility:Lock_Packet_Item( iBagPos, 1 )
            g_Miyu_zhizuo_Miyujinsi_Pos = iBagPos
        elseif iIndex == 3 then
            PushDebugMessage( "#{MYJS_120723_12}" )
            return
        end
    end

    if g_Miyu_zhizuo_Dress_Pos ~= -1 and g_Miyu_zhizuo_Miyujinsi_Pos ~= -1 then
        Miyu_zhizuo_OK : Enable()
    end
end

function Miyu_zhizuo_Clear()
    if ( g_Miyu_zhizuo_Dress_Pos ~= -1 ) then
        Miyu_zhizuo_Item:SetActionItem( -1 )
        LifeAbility:Lock_Packet_Item( g_Miyu_zhizuo_Dress_Pos, 0 )
        g_Miyu_zhizuo_Dress_Pos = -1
    end

    if ( g_Miyu_zhizuo_Miyujinsi_Pos ~= -1 ) then
        Miyu_zhizuo_Qingrentang : SetActionItem( -1 )
        LifeAbility:Lock_Packet_Item( g_Miyu_zhizuo_Miyujinsi_Pos, 0 )
        g_Miyu_zhizuo_Miyujinsi_Pos = -1
    end
end

function Miyu_zhizuo_Init()
    Miyu_zhizuo_Clear()
    Miyu_zhizuo_OK : Disable()
    return
end

function Miyu_zhizuo_OnClosed()
    Miyu_zhizuo_Clear()
    this:Hide()
    return
end

function Miyu_zhizuo_Close_Clicked()
    Miyu_zhizuo_OnClosed()
    return
end

function Miyu_zhizuo_OK_Clicked()
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
	    Set_XSCRIPT_Function_Name( "OnDrawSweetWords" );
		Set_XSCRIPT_ScriptID( 889933 );
		Set_XSCRIPT_Parameter(0,g_Miyu_zhizuo_Dress_Pos);
		Set_XSCRIPT_Parameter(1,g_Miyu_zhizuo_Miyujinsi_Pos);
		Set_XSCRIPT_ParamCount(2 );
    Send_XSCRIPT();

    return
end

function Miyu_zhizuo_Cancel_Clicked()
    Miyu_zhizuo_OnClosed()
    return
end

function Miyu_zhizuo_Resume( index )
    if index ~= 25 and index ~= 26 then
        return
    end

    if ( this:IsVisible() ) then
        if index == 25 then
            Miyu_zhizuo_Item : SetActionItem( -1 )
            LifeAbility : Lock_Packet_Item( g_Miyu_zhizuo_Dress_Pos, 0 ) 
            g_Miyu_zhizuo_Dress_Pos = -1
        elseif index == 26 then
            Miyu_zhizuo_Qingrentang : SetActionItem( -1 )
            LifeAbility : Lock_Packet_Item( g_Miyu_zhizuo_Miyujinsi_Pos, 0 ) 
            g_Miyu_zhizuo_Miyujinsi_Pos = -1
        end
    end

    Miyu_zhizuo_OK : Disable()
    return
end
