--- 万宝镶嵌
--- Author: David Gao 2012.08.13

local g_EquipBaoshiChange_SERVER_CONTROL_1 = 2012081301   --- 一键换宝石使用界面
local g_EquipBaoshiChange_Frame_UnifiedPosition
local g_EquipBaoshiChange_ObjCared = -1

local g_EquipBaoshiChange_Container_Gems = {}    --- 装备位上的宝石
local g_EquipBaoshiChange_Container_Info = {}    --- 装备位上的宝石数据
local g_EquipBaoshiChange_Container_Animates = {}    --- 装备位上的动画

local g_EquipBaoshiChange_Equip_Gems     = {}    --- 装备上的宝石
local g_EquipBaoshiChange_Equip_Info     = {}    --- 装备上的宝石数据

local g_EquipBaoshiChange_NeedHint       = 0     --- 是否需要提示

local g_EquipBaoshiChange_YuanBaoPay = 1

-- 所有神器都可以打四孔 by lishilong 2016-8-23
local EQUIP_SHENQI_BEGIN = 10300000
local EQUIP_SHENQI_END = 10399999

local g_EquipBaoshiChange_Equip_TypeList =
{
	[1]  = { name="#{WBSS_120727_34}", gemConIndex=0,  equipIndex=0,  },    --- 武器
	[2]  = { name="#{WBSS_120727_26}", gemConIndex=11, equipIndex=14, },    --- 护腕
	[3]  = { name="#{WBSS_120727_30}", gemConIndex=6,  equipIndex=6,  },    --- 戒指（上）
	[4]  = { name="#{WBSS_120727_31}", gemConIndex=8,  equipIndex=11, },    --- 戒指（下）
	[5]  = { name="#{WBSS_120727_32}", gemConIndex=9,  equipIndex=12, },    --- 护符（上）
	[6]  = { name="#{WBSS_120727_33}", gemConIndex=10, equipIndex=13, },    --- 护符（下）
	[7]  = { name="#{WBSS_120727_35}", gemConIndex=2,  equipIndex=2,  },    --- 衣服
	[8]  = { name="#{WBSS_120727_24}", gemConIndex=1,  equipIndex=1,  },    --- 帽子
	[9]  = { name="#{WBSS_120727_25}", gemConIndex=12, equipIndex=15, },    --- 肩膀
	[10] = { name="#{WBSS_120727_27}", gemConIndex=3,  equipIndex=3,  },    --- 手套
	[11] = { name="#{WBSS_120727_28}", gemConIndex=5,  equipIndex=5,  },    --- 腰带
	[12] = { name="#{WBSS_120727_29}", gemConIndex=4,  equipIndex=4,  },    --- 鞋子
	[13] = { name="#{WBSS_120727_36}", gemConIndex=7,  equipIndex=7,  },    --- 项链
	[14] = { name="#{WBSS_120727_37}", gemConIndex=13, equipIndex=17, },    --- 暗器
	[15] = { name="#{WBSS_120727_39}", gemConIndex=15, equipIndex=19, },    --- 龙纹
	[16] = { name="#{WBSS_120727_38}", gemConIndex=14, equipIndex=18, },    --- 武魂
	[17] = { name="#{BHZB_140521_241}", gemConIndex=16, equipIndex=20, },    --- 令牌 
	[18] = { name="#{HXYSJ_141031_131}", gemConIndex=17, equipIndex=21, },    --- 豪侠印
	[19] = { name="#{WBSS_230829_01}", gemConIndex=18, equipIndex=23, },    --- 镇派秘宝
}

--经典版图片素材
local g_EquipBaoshiChange_UnActived_Image  = "set:Agname3 image:BaoShiCheckFeng"    --- 未打孔
local g_EquipBaoshiChange_Actived_Image    = "set:UIIcons image:Equip_Ring"      --- 暂时使用真元激活的图片

local g_EquipBaoshiChange_WanbaoXiangqian_Fu = 30900125     --- 万宝镶嵌符ID

function EquipBaoshiChange_PreLoad()
    this:RegisterEvent("EQUIP_BAOSHI_CHANGE");
    this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);
    this:RegisterEvent("UI_COMMAND");
    this:RegisterEvent("GEM_CONTAINER_REFRESH");
    this:RegisterEvent("REFRESH_EQUIP");

    this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function EquipBaoshiChange_OnLoad()

	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片素材为唯美版
		g_EquipBaoshiChange_UnActived_Image  = "set:WM_CommonFrame1 image:Feng"    --- 未打孔
		g_EquipBaoshiChange_Actived_Image    = "set:WM_Button2 image:Equip_Ring"      --- 暂时使用真元激活的图?
	end

    g_EquipBaoshiChange_Frame_UnifiedPosition = EquipBaoshiChange_Frame:GetProperty( "UnifiedPosition" )

    g_EquipBaoshiChange_Equip_Gems[1]     = EquipBaoshiChange_Special_Button1
    g_EquipBaoshiChange_Equip_Gems[2]     = EquipBaoshiChange_Special_Button2
    g_EquipBaoshiChange_Equip_Gems[3]     = EquipBaoshiChange_Special_Button3
    g_EquipBaoshiChange_Equip_Gems[4]     = EquipBaoshiChange_Special_Button4

    --- 保存自己的装备上的宝石信息
    g_EquipBaoshiChange_Equip_Info =
    {
        isEquiped       = 0,  --- 是否有装备
        holeNum         = 0,  --- 打孔数
        gemNum          = 0,  --- 已镶嵌宝石数目
        canStilettoFour = 1,  --- 能否打第四孔
        equipPoint      = -1, --- 装备的索引
        containerPos    = -1, --- 装备位的索引
        gemInfo         =     --- 已经镶嵌的宝石信息
        {
            [1] = { gemIndex = 0, gemType = -1, },
            [2] = { gemIndex = 0, gemType = -1, },
            [3] = { gemIndex = 0, gemType = -1, },
            [4] = { gemIndex = 0, gemType = -1, },
        },
    }

    g_EquipBaoshiChange_Container_Gems[1] = EquipBaoshiChange_Special_Button6
    g_EquipBaoshiChange_Container_Gems[2] = EquipBaoshiChange_Special_Button7
    g_EquipBaoshiChange_Container_Gems[3] = EquipBaoshiChange_Special_Button8
    g_EquipBaoshiChange_Container_Gems[4] = EquipBaoshiChange_Special_Button9

    g_EquipBaoshiChange_Container_Animates[1] = BaoShiCheck1
    g_EquipBaoshiChange_Container_Animates[2] = BaoShiCheck2
    g_EquipBaoshiChange_Container_Animates[3] = BaoShiCheck3
    g_EquipBaoshiChange_Container_Animates[4] = BaoShiCheck4

    g_EquipBaoshiChange_Container_Info =
    {
        --- actionID, 背包位置, 是否已经镶嵌, 宝石类型
        [1] = { actionID = -1, bagIndex = -1, isAlreadyFixed = 0, gemType = -1, },
        [2] = { actionID = -1, bagIndex = -1, isAlreadyFixed = 0, gemType = -1, },
        [3] = { actionID = -1, bagIndex = -1, isAlreadyFixed = 0, gemType = -1, },
        [4] = { actionID = -1, bagIndex = -1, isAlreadyFixed = 0, gemType = -1, },
    }

    EquipBaoshiChange_tishi   : SetText( "" )
    EquipBaoshiChange_static3 : SetText( "" )
    EquipBaoshiChange_static3 : Hide()
    
    g_EquipBaoshiChange_YuanBaoPay = 1;
    EquipBaoshiChange_YuanBaoPay:SetCheck(g_EquipBaoshiChange_YuanBaoPay)
end

-- OnEvent
function EquipBaoshiChange_OnEvent(event)
    if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_EquipBaoshiChange_SERVER_CONTROL_1 then
        if ( this : IsVisible() ) then
        		g_EquipBaoshiChange_YuanBaoPay = EquipBaoshiChange_YuanBaoPay:GetCheck();
            this:Hide()
        end
        EquipBaoshiChange_Update()
        if g_EquipBaoshiChange_YuanBaoPay == 1 or g_EquipBaoshiChange_YuanBaoPay == 0 then
					EquipBaoshiChange_YuanBaoPay:SetCheck(g_EquipBaoshiChange_YuanBaoPay)
				end
        this : Show()
        g_EquipBaoshiChange_ObjCared = -1
        local xx = Get_XParam_INT( 0 )
        g_EquipBaoshiChange_ObjCared = DataPool : GetNPCIDByServerID( xx )
        if g_EquipBaoshiChange_ObjCared == -1 then
            return
        end
        EquipBaoshiChange_BeginCareObject( g_EquipBaoshiChange_ObjCared )
        --- 是否是第一次打开
        local isFirstOpen = Get_XParam_INT( 1 )
        --- 如果是第一次打开，需要弹出指引
        if isFirstOpen == 0 then
            EquipBaoshiChange_OpenFreshManGuide()
        end
    elseif ( event == "UI_COMMAND" ) and tonumber( arg0 ) == 2012081302 then
        if ( this : IsVisible() ) then
            EquipBaoshiChange_EquipSel( )
        end
    elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_EquipBaoshiChange_ObjCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
		    --取消关心
    		EquipBaoshiChange_OnClosed()
		end
    elseif ( event == "EQUIP_BAOSHI_CHANGE" ) then
        local type    = tostring( arg0 )
        local bagIdx  = tonumber( arg1 )
        local conIdx1 = tonumber( arg2 )
        local conIdx2 = tonumber( arg3 )
        EquipBaoshiChange_PutInGem( type, bagIdx, conIdx1, conIdx2 )
    elseif ( event == "RESUME_ENCHASE_GEM_EX" ) then
		if arg0 ~= nil then
            arg0 = arg0 - 110
            EquipBaoshiChange_Resume( arg0 )
		end
    elseif ( event == "GEM_CONTAINER_REFRESH" ) then
        if ( this : IsVisible() ) then
            EquipBaoshiChange_EquipSel( )
        end
    elseif ( event == "REFRESH_EQUIP" ) then
        if ( this:IsVisible() ) then
            EquipBaoshiChange_EquipSel( )
        end
	elseif event == "HIDE_ON_SCENE_TRANSED"  then
        EquipBaoshiChange_OnClosed()
	elseif (event == "ADJEST_UI_POS" ) then
		EquipBaoshiChange_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipBaoshiChange_On_ResetPos()
	end
end

function EquipBaoshiChange_Update(  )
    --- 重设装备下拉列表
    EquipBaoshiChange_zhuangbeixiala : ResetList ()
    for i = 1, table.getn( g_EquipBaoshiChange_Equip_TypeList ) do
		if Player:GetData("Is2606S") == 1 and (i == 15 or i == 18) then
		else
        EquipBaoshiChange_zhuangbeixiala : AddTextItem( g_EquipBaoshiChange_Equip_TypeList[i].name, i - 1 )
		end
    end
    --- 默认选中第一个
    EquipBaoshiChange_zhuangbeixiala : SetCurrentSelect( 0 )
    EquipBaoshiChange_EquipSel( )
	
	if Player:GetData("Is2606S") == 1 then
		EquipBaoshiChange_Frame_Info:SetText("#{QXF_260623_116}")
	else
		EquipBaoshiChange_Frame_Info:SetText("#{WBSS_120727_79}")
	end
	
end

function EquipBaoshiChange_EquipSel( )
    EquipBaoshiChange_Clear()

    --- 转换为选择了哪个装备
    local _, curSel = EquipBaoshiChange_zhuangbeixiala : GetCurrentSelect( )
    if curSel == nil or curSel < 0 or curSel > table.getn( g_EquipBaoshiChange_Equip_TypeList ) then
        return
    end
    --- 注: 控件索引是从0开始的
    curSel = curSel + 1
    local curEquipIndex  = g_EquipBaoshiChange_Equip_TypeList[curSel].equipIndex
    local curGemConIndex = g_EquipBaoshiChange_Equip_TypeList[curSel].gemConIndex
    local updateRet      = LifeAbility : SplitWearedEquipGem_Update( curEquipIndex )
    local itemTblIdx     = LifeAbility : GetWearedEquip_ItemTableIndex( curEquipIndex )
    --- 是否是暗器
    local bIsDark        = LifeAbility : IsWearedEquipDark( curEquipIndex )
    --- 是否是豪侠印
    local bIsHXY        = LifeAbility : IsWearedEquipHXY( curEquipIndex )
    --- 缓存装备数据
    g_EquipBaoshiChange_Equip_Info.equipPoint   = curEquipIndex
    g_EquipBaoshiChange_Equip_Info.containerPos = curGemConIndex

    local ActionID, nItemID, gemTblIdx
    --- 显示装备上的宝石
    if updateRet then
        local holeCount  = LifeAbility : GetWearedEquip_HoleCount( curEquipIndex )
        g_EquipBaoshiChange_Equip_Info.isEquiped = 1
        g_EquipBaoshiChange_Equip_Info.holeNum   = holeCount
        --- 对1~4孔进行遍历
        for i = 1, 4 do
            nItemID = LifeAbility : GetSplitGem_Gem ( i-1 );

            --- 如果有宝石
			if nItemID ~= -1 then
			    ActionID = DataPool:EnumPlayerMission_ItemAction( nItemID );
				g_EquipBaoshiChange_Equip_Gems[i] : SetActionItem( ActionID );
                gemTblIdx = LifeAbility : GetSplitGem_GemIndex ( i - 1 );

                --- 缓存装备数据
                g_EquipBaoshiChange_Equip_Info.gemNum      = 1 + g_EquipBaoshiChange_Equip_Info.gemNum
                g_EquipBaoshiChange_Equip_Info.gemInfo[i].gemIndex = gemTblIdx
                g_EquipBaoshiChange_Equip_Info.gemInfo[i].gemType  = EquipBaoshiChange_GetGemTypeByIndex( gemTblIdx )
            --- 没有宝石
            else
                --- 未开启的孔显示封印状态
                if i > holeCount then
                    g_EquipBaoshiChange_Equip_Gems[i] : SetActionItem( -1 );
                    g_EquipBaoshiChange_Equip_Gems[i] : SetToolTip( "#{WBSS_120727_40}" )   --- 装备的该孔位未开启
                    g_EquipBaoshiChange_Equip_Gems[i] : SetProperty( "BackImage",  g_EquipBaoshiChange_UnActived_Image )
                    --- 第四孔特殊判断
                    if i == 4 then
                        --- 如果无法开启第四孔
                        if 0 == EquipBaoshiChange_Can_Stiletto_Four( itemTblIdx, bIsDark, bIsHXY ) then
                            g_EquipBaoshiChange_Equip_Gems[i] : SetToolTip( "#{WBSS_120727_41}" )   --- 装备无法开启第四孔
                            g_EquipBaoshiChange_Equip_Info.canStilettoFour = 0
                        end
                    end
                --- 开孔未镶嵌宝石则对应格子处显示空格子
                else
                    g_EquipBaoshiChange_Equip_Gems[i] : SetProperty( "BackImage",  g_EquipBaoshiChange_Actived_Image )
                    g_EquipBaoshiChange_Equip_Gems[i] : SetToolTip( "#{WBSS_120727_45}" )   --- 该孔位未镶嵌宝石
                end
            end
		end
        EquipBaoshiChange_static3 : SetText( "" )
        EquipBaoshiChange_static3 : Hide()
    --- 玩家当前并没有穿指定装备
    else
        g_EquipBaoshiChange_Equip_Info.isEquiped = 0
        for i = 1, 4 do
            g_EquipBaoshiChange_Equip_Gems[i] : Hide()
        end
        EquipBaoshiChange_static3 : SetText( "#{WBSS_120727_13}" )
        EquipBaoshiChange_static3 : Show()
    end

    --- 显示装备位上的宝石
    LifeAbility : GemContainer_Update()
    for i = 1, 4 do
        local gemConGemIndex, tmpGemType
        nItemID, gemConGemIndex, tmpGemType = LifeAbility : GetGemContainer_Gem( curGemConIndex, i - 1 )
        if nItemID ~= -1 then
            ActionID = DataPool : EnumPlayerMission_ItemAction( nItemID )
            g_EquipBaoshiChange_Container_Gems[i] : SetActionItem( ActionID )
            g_EquipBaoshiChange_Container_Info[i].actionID  = ActionID
            g_EquipBaoshiChange_Container_Info[i].bagIndex  = -1
            g_EquipBaoshiChange_Container_Info[i].isAlreadyFixed = 1
            g_EquipBaoshiChange_Container_Info[i].gemType   = tmpGemType
            g_EquipBaoshiChange_Container_Gems[i] : SetProperty("DraggingEnabled","False")
            g_EquipBaoshiChange_Container_Animates[i] : Hide()
        else
            g_EquipBaoshiChange_Container_Gems[i] : SetActionItem( -1 )
            g_EquipBaoshiChange_Container_Gems[i] : SetToolTip( "#{WBSS_120727_42}" )   --- 该孔位可镶嵌宝石
            g_EquipBaoshiChange_Container_Info[i].actionID  = -1
            g_EquipBaoshiChange_Container_Info[i].bagIndex  = -1
            g_EquipBaoshiChange_Container_Info[i].isAlreadyFixed = 0
            g_EquipBaoshiChange_Container_Info[i].gemType   = -1
            g_EquipBaoshiChange_Container_Animates[i] : Hide()
        end
    end

    --- 更新提示信息的显示
    EquipBaoshiChange_UpdateHints( curSel )
end

function EquipBaoshiChange_Clear(  )
    for i = 1, 4 do
        local bagIndex = g_EquipBaoshiChange_Container_Info[i].bagIndex
        if bagIndex >= 0 then
            LifeAbility : Lock_Packet_Item( bagIndex, 0 )
        end
    end

    for i=1, 4 do
        g_EquipBaoshiChange_Equip_Gems[i]     : SetActionItem( -1 )
        g_EquipBaoshiChange_Equip_Gems[i]     : Show()
        g_EquipBaoshiChange_Container_Gems[i] : SetActionItem( -1 )
        g_EquipBaoshiChange_Container_Gems[i] : Show()
        g_EquipBaoshiChange_Container_Gems[i] : SetProperty("DraggingEnabled","True")
        g_EquipBaoshiChange_Container_Animates[i] : Hide()
    end

    g_EquipBaoshiChange_Container_Info =
    {
        [1] = { actionID = -1, bagIndex = -1, isAlreadyFixed = 0, gemType = -1, },
        [2] = { actionID = -1, bagIndex = -1, isAlreadyFixed = 0, gemType = -1, },
        [3] = { actionID = -1, bagIndex = -1, isAlreadyFixed = 0, gemType = -1, },
        [4] = { actionID = -1, bagIndex = -1, isAlreadyFixed = 0, gemType = -1, },
    }

    g_EquipBaoshiChange_Equip_Info =
    {
        isEquiped       = 0,  --- 是否有装备
        holeNum         = 0,  --- 打孔数
        gemNum          = 0,  --- 已镶嵌宝石数目
        canStilettoFour = 1,  --- 能否打第四孔
        equipPoint      = -1, --- 装备的装备位信息
        gemInfo         =     --- 已经镶嵌的宝石信息
        {
            [1] = { gemIndex = 0, gemType = -1, },
            [2] = { gemIndex = 0, gemType = -1, },
            [3] = { gemIndex = 0, gemType = -1, },
            [4] = { gemIndex = 0, gemType = -1, },
        },
    }

    EquipBaoshiChange_tishi   : SetText( "" )
    EquipBaoshiChange_static3 : SetText( "" )
    EquipBaoshiChange_static3 : Hide()

    g_EquipBaoshiChange_NeedHint = 0
end

function EquipBaoshiChange_OnClosed()
    EquipBaoshiChange_Clear(  )
    g_EquipBaoshiChange_YuanBaoPay = EquipBaoshiChange_YuanBaoPay:GetCheck();
    this:Hide()
    PushEvent( "CLOSE_FRESHMAN_GUIDE" )
    return
end

function EquipBaoshiChange_On_ResetPos()
    EquipBaoshiChange_Frame:SetProperty( "UnifiedPosition", g_EquipBaoshiChange_Frame_UnifiedPosition )
    return
end

--- 如果是右键单击
function EquipBaoshiChange_Handle_RClicked( bagIdx, equipPoint, gemConIndex, typeListIndex )

	--分期付款宝石
	local bBP_Gem = BudgetPlanGem: IsBudgetPlanGem( bagIdx )
	if bBP_Gem > 0 then
		PushDebugMessage("#{FQBS_140508_53}")
		return
	end

    local gemIndex = PlayerPackage : GetItemTableIndex( bagIdx )
    local gem_type = LifeAbility : Get_Gem_Level( bagIdx, 2 )
    --- 1. 判断当前的宝石类型是否可以镶嵌到此装备位上
    if 0 == EquipBaoshiChange_Can_Gem_BePutIn( gem_type, equipPoint ) then
        local gemName = LifeAbility : Get_GemName( bagIdx )
        --- %S0装备位上无法镶嵌%S1
        local strText = ScriptGlobal_Format( "#{WBSS_120727_55}", g_EquipBaoshiChange_Equip_TypeList[typeListIndex].name, gemName )
        PushDebugMessage( strText ) --- 包裹中未加锁的万宝镶嵌符数量不足X个，无法同时镶嵌X个宝石
        return
    end

    --- 1. 判断当前装备位是否有剩余的孔位
    local firstThreeNum = 0
    local isExistSameType = 0
    for i = 1, 3 do
        --- 记录有多少空位
        if g_EquipBaoshiChange_Container_Info[i].actionID ~= -1 then
            firstThreeNum = firstThreeNum + 1
        end
        --- 是否有同类型宝石
        if g_EquipBaoshiChange_Container_Info[i].gemType == gem_type then
            isExistSameType = 1
        end
    end

    --- 2. 判断能否放入第四个空位
    local canBeInForthHole = EquipBaoshiChange_Can_BePutInForthHole( gemIndex )

    --- 3. 前3个空位满了
    if firstThreeNum >= 3 then
        --- 第四个空位也满了
        if g_EquipBaoshiChange_Container_Info[4].actionID ~= -1 then
            PushDebugMessage( "#{WBSS_120727_56}" )     --- 当前装备位没有剩余孔位，如需更换镶嵌的宝石请先进行万宝摘除
            return
        else
            --- 判断能否放入第四个空位
            if canBeInForthHole == 0 then
                PushDebugMessage( "#{WBSS_120727_57}" )     --- 第四孔无法镶嵌血精石和红宝石
                return
            else
                --- 现在终于可以放入第四孔了
                local theActionItem = EnumAction( bagIdx, "packageitem" )
                g_EquipBaoshiChange_Container_Gems[4] : SetActionItem( theActionItem:GetID() )
                LifeAbility:Lock_Packet_Item( bagIdx, 1 )
                g_EquipBaoshiChange_Container_Info[4].actionID  = theActionItem:GetID()
                g_EquipBaoshiChange_Container_Info[4].bagIndex  = bagIdx
                g_EquipBaoshiChange_Container_Info[4].isAlreadyFixed = 0
                g_EquipBaoshiChange_Container_Info[4].gemType   = LifeAbility : Get_Gem_Level( bagIdx, 2 )
                g_EquipBaoshiChange_Container_Animates[4] : Show()
                return
            end
        end
    end

    --- 4. 判断前三孔中是否有同类型的宝石
    if isExistSameType == 1 then
        --- 额外加条判断，为了满足策划需求
        if g_EquipBaoshiChange_Container_Info[4].actionID ~= -1 then
                PushDebugMessage( "#{WBSS_120727_58}" )     --- 前三孔中无法镶嵌同类型宝石
                return
        end

        --- 不能放入第四孔
        if canBeInForthHole == 0 then
            PushDebugMessage( "#{WBSS_120727_57}" )     --- 第四孔无法镶嵌血精石和红宝石
            return
        --- 放入第四孔
        else
            --- 第四个空位也满了
            if g_EquipBaoshiChange_Container_Info[4].actionID ~= -1 then
                PushDebugMessage( "#{WBSS_120727_58}" )     --- 前三孔中无法镶嵌同类型宝石
                return
            else
                --- 现在终于可以放入第四孔了
                local theActionItem = EnumAction( bagIdx, "packageitem" )
                g_EquipBaoshiChange_Container_Gems[4] : SetActionItem( theActionItem:GetID() )
                LifeAbility:Lock_Packet_Item( bagIdx, 1 )
                g_EquipBaoshiChange_Container_Info[4].actionID  = theActionItem:GetID()
                g_EquipBaoshiChange_Container_Info[4].bagIndex  = bagIdx
                g_EquipBaoshiChange_Container_Info[4].isAlreadyFixed = 0
                g_EquipBaoshiChange_Container_Info[4].gemType   = LifeAbility : Get_Gem_Level( bagIdx, 2 )
                g_EquipBaoshiChange_Container_Animates[4] : Show()
            end
        end
    --- 前三孔中没有同类型的宝石
    else
        --- 先找武器上同类型宝石的位置镶嵌
        for i = 1, 3 do
            if g_EquipBaoshiChange_Equip_Info.gemInfo[i].gemType == gem_type and g_EquipBaoshiChange_Container_Info[i].actionID == -1  then
                local theActionItem = EnumAction( bagIdx, "packageitem" )
                g_EquipBaoshiChange_Container_Gems[i] : SetActionItem( theActionItem:GetID() )
                LifeAbility:Lock_Packet_Item( bagIdx, 1 )
                g_EquipBaoshiChange_Container_Info[i].actionID  = theActionItem:GetID()
                g_EquipBaoshiChange_Container_Info[i].bagIndex  = bagIdx
                g_EquipBaoshiChange_Container_Info[i].isAlreadyFixed = 0
                g_EquipBaoshiChange_Container_Info[i].gemType   = LifeAbility : Get_Gem_Level( bagIdx, 2 )
                g_EquipBaoshiChange_Container_Animates[i] : Show()
                return
            end
        end

        --- 如果没有，随便找个空位置放
        for i = 1, 3 do
            if g_EquipBaoshiChange_Container_Info[i].actionID == -1 then
                local theActionItem = EnumAction( bagIdx, "packageitem" )
                g_EquipBaoshiChange_Container_Gems[i] : SetActionItem( theActionItem:GetID() )
                LifeAbility:Lock_Packet_Item( bagIdx, 1 )
                g_EquipBaoshiChange_Container_Info[i].actionID  = theActionItem:GetID()
                g_EquipBaoshiChange_Container_Info[i].bagIndex  = bagIdx
                g_EquipBaoshiChange_Container_Info[i].isAlreadyFixed = 0
                g_EquipBaoshiChange_Container_Info[i].gemType   = LifeAbility : Get_Gem_Level( bagIdx, 2 )
                g_EquipBaoshiChange_Container_Animates[i] : Show()
                break
            end
        end
    end
end
--- 如果是从背包拖拽到装备位
function EquipBaoshiChange_Handle_Drag( bagIdx, equipPoint, gemConIndex, typeListIndex, conIdx1, conIdx2 )
	--分期付款宝石
	local bBP_Gem = BudgetPlanGem: IsBudgetPlanGem( bagIdx )
	if bBP_Gem > 0 then
		PushDebugMessage("#{FQBS_140508_53}")
		return
	end

    --- 得到对应的控件索引
    local btnIndex = conIdx1 - 115
    if btnIndex < 1 or btnIndex > 4 then
        return
    end

    --- 判断当前的宝石类型是否可以镶嵌到此装备位上
    local gemIndex = PlayerPackage : GetItemTableIndex( bagIdx )
    local gem_type = LifeAbility : Get_Gem_Level( bagIdx, 2 )
    if 0 == EquipBaoshiChange_Can_Gem_BePutIn( gem_type, equipPoint ) then
        local gemName = LifeAbility : Get_GemName( bagIdx )
        --- %S0装备位上无法镶嵌%S1
        local strText = ScriptGlobal_Format( "#{WBSS_120727_55}", g_EquipBaoshiChange_Equip_TypeList[typeListIndex].name, gemName )
        PushDebugMessage( strText ) --- 包裹中未加锁的万宝镶嵌符数量不足X个，无法同时镶嵌X个宝石

        return
    end

    --- 是否是往前三孔上拖
    local isTryPutFirstThree = 0
    if btnIndex >= 1 and btnIndex <= 3 then
        --- 是否和前三种宝石同种类型
        if 1 == EquipBaoshiChange_Is_FristThree_Have_SameType( gem_type, btnIndex ) then
            PushDebugMessage( "#{WBSS_120727_58}" )         --- 前三孔中无法镶嵌同类型宝石
            return
        end
    --- 往第四孔上拖
    else
        local canBeInForthHole = EquipBaoshiChange_Can_BePutInForthHole( gemIndex )
        if canBeInForthHole == 0 then
            PushDebugMessage( "#{WBSS_120727_57}" )     --- 第四孔无法镶嵌血精石和红宝石
            return
        end
    end

    --- 如果是：拖拽到已经镶嵌宝石的装备位孔位
    if g_EquipBaoshiChange_Container_Info[btnIndex].isAlreadyFixed == 1 then
        PushDebugMessage( "#{WBSS_120727_51}" )         --- 目标孔位已经镶嵌了宝石
        return
    end

    --- 如果是空位
    if g_EquipBaoshiChange_Container_Info[btnIndex].actionID < 0 then
        local theActionItem = EnumAction( bagIdx, "packageitem" )
        if theActionItem:GetID() ~= 0 then
            --- 先设置控件
            LifeAbility : Lock_Packet_Item( bagIdx, 1 )
            g_EquipBaoshiChange_Container_Gems[btnIndex] : SetActionItem( theActionItem:GetID() )
            g_EquipBaoshiChange_Container_Animates[btnIndex] : Show()
            --- 设置缓存的数据
            g_EquipBaoshiChange_Container_Info[btnIndex].actionID  = theActionItem:GetID()
            g_EquipBaoshiChange_Container_Info[btnIndex].bagIndex  = bagIdx
            g_EquipBaoshiChange_Container_Info[btnIndex].isAlreadyFixed = 0
            g_EquipBaoshiChange_Container_Info[btnIndex].gemType   = LifeAbility : Get_Gem_Level( bagIdx, 2 );
        end
        return
    --- 如果已经放入过宝石
    else
        local theActionItem = EnumAction( bagIdx, "packageitem" )
        if theActionItem:GetID() ~= 0 then
            --- 先设置控件
            --- 先把原来蒙红的释放
            LifeAbility:Lock_Packet_Item( g_EquipBaoshiChange_Container_Info[btnIndex].bagIndex, 0 )
            --- 再锁住新的
            LifeAbility:Lock_Packet_Item( bagIdx, 1 )
            g_EquipBaoshiChange_Container_Gems[btnIndex] : SetActionItem( theActionItem:GetID() )
            g_EquipBaoshiChange_Container_Animates[btnIndex] : Show()
            --- 设置缓存的数据
            g_EquipBaoshiChange_Container_Info[btnIndex].actionID  = theActionItem:GetID()
            g_EquipBaoshiChange_Container_Info[btnIndex].bagIndex  = bagIdx
            g_EquipBaoshiChange_Container_Info[btnIndex].isAlreadyFixed = 0
            g_EquipBaoshiChange_Container_Info[btnIndex].gemType   = LifeAbility : Get_Gem_Level( bagIdx, 2 );
        end
        return
    end

end
--- 如果是从背包拖拽到装备位
function EquipBaoshiChange_Handle_Switch( bagIdx, equipPoint, gemConIndex, typeListIndex, conIdx1, conIdx2 )
    --- 得到对应的控件索引
    local srcBtnIndex = conIdx1 - 115
    local dstBtnIndex = conIdx2 - 115
    if srcBtnIndex < 1 or srcBtnIndex > 4 or dstBtnIndex < 1 or dstBtnIndex > 4 or srcBtnIndex == dstBtnIndex then
        return
    end

    --- 源位置是已经镶嵌的
    if g_EquipBaoshiChange_Container_Info[srcBtnIndex].isAlreadyFixed == 1 then
        return
    end

    --- 目标位置是已经镶嵌过
    if g_EquipBaoshiChange_Container_Info[dstBtnIndex].isAlreadyFixed == 1 then
        PushDebugMessage( "#{WBSS_120727_51}" )         --- 目标孔位已经镶嵌了宝石
        return
    end

    --- 目标位置是空位
    if g_EquipBaoshiChange_Container_Info[dstBtnIndex].actionID < 0 then
        --- 目标是第四孔
        if dstBtnIndex == 4 then
            local srcBagIdx = g_EquipBaoshiChange_Container_Info[srcBtnIndex].bagIndex
            local gemIndex  = PlayerPackage : GetItemTableIndex( srcBagIdx )
            if EquipBaoshiChange_Can_BePutInForthHole( gemIndex ) == 0 then
                PushDebugMessage( "#{WBSS_120727_57}" )     --- 第四孔无法镶嵌血精石和红宝石
                return
            end
        end

        local dstActionID = g_EquipBaoshiChange_Container_Info[srcBtnIndex].actionID
        local dstBagIdx   = g_EquipBaoshiChange_Container_Info[srcBtnIndex].bagIndex
        local dstGemType  = g_EquipBaoshiChange_Container_Info[srcBtnIndex].gemType

        --- 是否会出现三种同样的宝石
        for i = 1, 3 do
            if i ~= srcBtnIndex and g_EquipBaoshiChange_Container_Info[i].gemType == dstGemType then
                PushDebugMessage( "#{WBSS_120727_58}" )     --- 前三孔中无法镶嵌同类型宝石
                return
            end
        end

        --- 先设置目标数据
        g_EquipBaoshiChange_Container_Info[dstBtnIndex].actionID  = dstActionID
        g_EquipBaoshiChange_Container_Info[dstBtnIndex].bagIndex  = dstBagIdx
        g_EquipBaoshiChange_Container_Info[dstBtnIndex].isAlreadyFixed = 0
        g_EquipBaoshiChange_Container_Info[dstBtnIndex].gemType   = dstGemType
        --- 设置目标控件
        g_EquipBaoshiChange_Container_Gems[dstBtnIndex] : SetActionItem( dstActionID )
        g_EquipBaoshiChange_Container_Animates[dstBtnIndex] : Show()
        --- 再设置源数据
        g_EquipBaoshiChange_Container_Info[srcBtnIndex].actionID  = -1
        g_EquipBaoshiChange_Container_Info[srcBtnIndex].bagIndex  = -1
        g_EquipBaoshiChange_Container_Info[srcBtnIndex].isAlreadyFixed = 0
        g_EquipBaoshiChange_Container_Info[srcBtnIndex].gemType   = -1
        --- 设置源控件
        g_EquipBaoshiChange_Container_Gems[srcBtnIndex] : SetActionItem( -1 )
        g_EquipBaoshiChange_Container_Animates[srcBtnIndex] : Hide()

        return
    --- 目标位置有宝石
    else
        local dstActionID = g_EquipBaoshiChange_Container_Info[srcBtnIndex].actionID
        local dstBagIdx   = g_EquipBaoshiChange_Container_Info[srcBtnIndex].bagIndex
        local dstGemType  = g_EquipBaoshiChange_Container_Info[srcBtnIndex].gemType
        local dstGemIndex = PlayerPackage : GetItemTableIndex( dstBagIdx )

        local srcActionID = g_EquipBaoshiChange_Container_Info[dstBtnIndex].actionID
        local srcBagIdx   = g_EquipBaoshiChange_Container_Info[dstBtnIndex].bagIndex
        local srcGemType  = g_EquipBaoshiChange_Container_Info[dstBtnIndex].gemType
        local srcGemIndex = PlayerPackage : GetItemTableIndex( srcBagIdx )

        --- 是否是与第四孔上交换
        --- 如果是从第四孔往其他的孔拖
        if srcBtnIndex == 4 then
            --- 目标是否能镶嵌在第四孔
            if EquipBaoshiChange_Can_BePutInForthHole( srcGemIndex ) == 0 then
                PushDebugMessage( "#{WBSS_120727_57}" )     --- 第四孔无法镶嵌血精石和红宝石
                return
            end
            --- 源是否与另外两个孔的同类型
            for i = 1, 3 do
                if i ~= dstBtnIndex and g_EquipBaoshiChange_Container_Info[i].gemType == dstGemType then
                    PushDebugMessage( "#{WBSS_120727_58}" )     --- 前三孔中无法镶嵌同类型宝石
                    return
                end
            end

            --- 如果是从其他的地方往第四孔拖
        elseif dstBtnIndex == 4 then
            --- 源宝石能否镶嵌在第四孔
            if EquipBaoshiChange_Can_BePutInForthHole( dstGemIndex ) == 0 then
                PushDebugMessage( "#{WBSS_120727_57}" )     --- 第四孔无法镶嵌血精石和红宝石
                return
            end
            --- 目标是否与另外两个孔的同类型
            for i = 1, 3 do
                if i ~= srcBtnIndex and g_EquipBaoshiChange_Container_Info[i].gemType == srcGemType then
                    PushDebugMessage( "#{WBSS_120727_58}" )     --- 前三孔中无法镶嵌同类型宝石
                    return
                end
            end
        end

        --- 先设置目标数据
        g_EquipBaoshiChange_Container_Info[dstBtnIndex].actionID  = dstActionID
        g_EquipBaoshiChange_Container_Info[dstBtnIndex].bagIndex  = dstBagIdx
        g_EquipBaoshiChange_Container_Info[dstBtnIndex].isAlreadyFixed = 0
        g_EquipBaoshiChange_Container_Info[dstBtnIndex].gemType   = dstGemType
        --- 设置目标控件
        g_EquipBaoshiChange_Container_Gems[dstBtnIndex] : SetActionItem( dstActionID )
        g_EquipBaoshiChange_Container_Animates[dstBtnIndex] : Show()
        --- 再设置源数据
        g_EquipBaoshiChange_Container_Info[srcBtnIndex].actionID  = srcActionID
        g_EquipBaoshiChange_Container_Info[srcBtnIndex].bagIndex  = srcBagIdx
        g_EquipBaoshiChange_Container_Info[srcBtnIndex].isAlreadyFixed = 0
        g_EquipBaoshiChange_Container_Info[srcBtnIndex].gemType   = srcGemType
        --- 设置源控件
        g_EquipBaoshiChange_Container_Gems[srcBtnIndex] : SetActionItem( srcActionID )
        g_EquipBaoshiChange_Container_Animates[srcBtnIndex] : Show()

        return
    end
end

--- TODO: 下面这个函数需要重构, 哥太累了，明天再来弄
--- 这里的conIdx是116，117，118，119，分别对应第1，2，3，4个控件
function EquipBaoshiChange_PutInGem( type, bagIdx, conIdx1, conIdx2 )
    if type == nil or bagIdx == nil or conIdx1 == nil or conIdx2 == nil then
        return
    end

    --- 是否是有效装备
    local equipPoint = g_EquipBaoshiChange_Equip_Info.equipPoint
    if equipPoint == -1 or equipPoint == 8 or equipPoint == 9 or equipPoint == 10 or equipPoint == 16 then
		return
    end
	
	--宗门装备暂时关闭
	if equipPoint == 23 then
		PushDebugMessage("#{XWXT_230825_24}")
		return
	end

    local gemConIndex   = g_EquipBaoshiChange_Equip_Info.containerPos
    --- 得到在TypeList里面的索引
    local typeListIndex = 1
    for i = 1, table.getn( g_EquipBaoshiChange_Equip_TypeList ) do
        if g_EquipBaoshiChange_Equip_TypeList[i].gemConIndex == gemConIndex then
            typeListIndex = i
            break
        end
    end

    --- 如果是右键单击
    if type == "RClicked" then
        EquipBaoshiChange_Handle_RClicked( bagIdx, equipPoint, gemConIndex, typeListIndex )
    elseif type == "Drag" then
        --- 这里哥有必要解释下，不同的装备位之间是允许拖拽的，但是这个地方装备位上能拖拽的宝石的Container并不是CT_GEM_CONTAINER，
        --- 而是Package，所以这里比较绕
        --- 判断拖拽的宝石的bagIndex，如果之前已经缓存过了，说明已经被放在装备位上了，就是装备位上之间的拖拽
        --- 否则就是从背包里拖拽到装备位上
        local preSel = -1
        for i = 1, 4 do
            if g_EquipBaoshiChange_Container_Info[i].bagIndex == bagIdx then
                preSel = i
                break
            end
        end

        --- 如果是从背包拖拽到装备位
        if preSel == -1 then
            EquipBaoshiChange_Handle_Drag( bagIdx, equipPoint, gemConIndex, typeListIndex, conIdx1, conIdx2 )
        --- 如果是在装备位之间拖拽
        else
            EquipBaoshiChange_Handle_Switch( bagIdx, equipPoint, gemConIndex, typeListIndex, preSel + 115, conIdx1 )
        end

    else
        return
    end

    --- 更新提示信息
    EquipBaoshiChange_UpdateHints( typeListIndex )

    g_EquipBaoshiChange_NeedHint = 0

    return
end

function EquipBaoshiChange_SetHints()

end

function EquipBaoshiChange_OK_Clicked()
    --- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	--- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

    --- 判断玩家等级是否大于等于90级
    local level = Player : GetData( "LEVEL" )
    if level < 90 then
        PushDebugMessage( "#{WBSS_120727_60}" ) --- 只有等级大于等于90级的玩家才能进行此操作
        return
    end

    --- 判断玩家是否已经学习万宝随身互换
    if 0 == EquipBaoshiChange_Is_Learned_Skill() then
        PushDebugMessage( "#{WBSS_120727_61}" ) --- 只有学习了万宝随身的玩家才能进行此操作
        return
    end

    --- 判断当前装备位是否有选择
    if g_EquipBaoshiChange_Equip_Info.equipPoint == -1 then
        PushDebugMessage( "#{WBSS_120727_62}" ) --- 请先选择需要进行万宝镶嵌的装备位
        return
    end

    --- 判断当前是否有放入镶嵌的宝石
    local putGemNum = 0
    local curAlreadyFixed = 0
    for i = 1, 4 do
        if g_EquipBaoshiChange_Container_Info[i].isAlreadyFixed == 0 then
            if g_EquipBaoshiChange_Container_Info[i].bagIndex >= 0 then
                putGemNum = putGemNum + 1
            end
        else
            curAlreadyFixed = curAlreadyFixed + 1
        end
    end
    if curAlreadyFixed == 4 then
        PushDebugMessage( "#{WBSS_120727_99}" )     --- 装备位已镶嵌4颗宝石，如需更换宝石请先进行万宝摘除
        return
    end

    if putGemNum <= 0 then
        PushDebugMessage( "#{WBSS_120727_63}" ) --- 请放入需要镶嵌的宝石
        return
    end

    --- 下面这个不判断了，之前放入宝石的时候，条件已经判断过了
    --- 判断前三孔是否有同类型宝石
    --- 判断第四孔是否有红宝石和血精石

    --- 判断玩家包裹中未加锁的万宝镶嵌符数量是否大于等于放入的宝石数量
    --local curFuNum = PlayerPackage : CountAvailableItemByIDTable( g_EquipBaoshiChange_WanbaoXiangqian_Fu )
    --if curFuNum < putGemNum then
    --    if putGemNum == 1 then
    --        PushDebugMessage("#{WBSS_120727_64}")       --- 包裹中缺少未加锁的万宝镶嵌符，无法进行万宝镶嵌
    --    else
    --        local strText = ScriptGlobal_Format( "#{WBSS_120727_65}", putGemNum, putGemNum )
    --        PushDebugMessage( strText ) --- 包裹中未加锁的万宝镶嵌符数量不足X个，无法同时镶嵌X个宝石
    --    end
    --    return
    --end

    --if g_EquipBaoshiChange_NeedHint == 0 and curFuNum >= putGemNum then
    if g_EquipBaoshiChange_NeedHint == 0 then
        PushEvent( "GAMELOGIN_SYSTEM_INFO_OK", "#{WBSS_120727_92}", "-1" )
        g_EquipBaoshiChange_NeedHint = 1
    else
        Clear_XSCRIPT();
	        Set_XSCRIPT_Function_Name( "PutGemInContainer" );
		    Set_XSCRIPT_ScriptID( 701614 );
    		Set_XSCRIPT_Parameter( 0, g_EquipBaoshiChange_Equip_Info.containerPos    );         --- 装备位
	    	Set_XSCRIPT_Parameter( 1, g_EquipBaoshiChange_Container_Info[1].bagIndex );
		    Set_XSCRIPT_Parameter( 2, g_EquipBaoshiChange_Container_Info[2].bagIndex );
    		Set_XSCRIPT_Parameter( 3, g_EquipBaoshiChange_Container_Info[3].bagIndex );
	    	Set_XSCRIPT_Parameter( 4, g_EquipBaoshiChange_Container_Info[4].bagIndex );
	    	Set_XSCRIPT_Parameter( 5, tonumber(EquipBaoshiChange_YuanBaoPay:GetCheck()) );
		    Set_XSCRIPT_ParamCount( 6 );
        Send_XSCRIPT();
        --g_EquipBaoshiChange_NeedHint = 0
    end

end

function EquipBaoshiChange_Cancel_Clicked()

    EquipBaoshiChange_OnClosed()
end

function EquipBaoshiChange_Resume( index )
    if index == nil or index < 6 or index > 9 then
        return
    end
    index =  index - 5
    local bagIndex = g_EquipBaoshiChange_Container_Info[index].bagIndex
    if bagIndex >= 0 then
        LifeAbility : Lock_Packet_Item( bagIndex, 0 )
    else
        --- 这个地方的宝石都是已经镶嵌的，不作处理
        return
    end
    g_EquipBaoshiChange_Container_Gems[index] : SetActionItem( -1 )
    g_EquipBaoshiChange_Container_Animates[index] : Hide()

    g_EquipBaoshiChange_Container_Info[index].actionID       = -1
    g_EquipBaoshiChange_Container_Info[index].bagIndex       = -1
    g_EquipBaoshiChange_Container_Info[index].isAlreadyFixed = 0
    g_EquipBaoshiChange_Container_Info[index].gemType        = -1

    --- 更新提示信息
    local typeListIndex = EquipBaoshiChange_GetTypeListIndex()
    EquipBaoshiChange_UpdateHints( typeListIndex )

    g_EquipBaoshiChange_NeedHint = 0

    return
end

-----------------------------------------------------------------------------------
--- 下面这些全部是辅助函数 AuxFunc
-----------------------------------------------------------------------------------
--- 玩家是否学会了一键换宝石技能
function EquipBaoshiChange_Is_Learned_Skill()
    local gemSwitchSkillID = 278

	if( Player:GetSkillInfo( gemSwitchSkillID, "learn") ) then
        return 1
	else
        return 0
	end
end

--- 前三孔宝石是否存在同种类型
function EquipBaoshiChange_Is_FristThree_Have_SameType( gem_type, srcIndex )
    for i = 1, 3 do
        if g_EquipBaoshiChange_Container_Info[i].gemType == gem_type and i ~= srcIndex then
            return 1
        end
    end
    return 0
end

--- 宝石能否被放入装备位
--- 装备宝石镶嵌逻辑
local g_EquipBaoshiChange_EquipGemTable = {
    [0] = { 1, 2, 3, 4, 21 },
	[1] = { 11, 12, 13, 14 },
	[2] = { 11, 12, 13, 14 },
	[3] = { 11, 12, 13, 14 },
	[4] = { 11, 12, 13, 14 },
	[5] = { 11, 12, 13, 14 },
	[6] = { 1, 2, 3, 4, 21 },
	[7] = { 1, 2, 3, 4, 11, 12, 13, 14, 21 },
	[11] = { 1, 2, 3, 4, 21 },
	[12] = { 1, 2, 3, 4, 21 },
	[13] = { 1, 2, 3, 4, 21 },
	[14] = { 1, 2, 3, 4, 21 },
	[15] = { 11, 12, 13, 14 },
	[17] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 },
	[18] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 },
	[19] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 },
	[20] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 },
	[21] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 },
	[23] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21 },
}
function EquipBaoshiChange_Can_Gem_BePutIn( gem_type, equipPoint )
    local passFlag = 0
    for i, gt in g_EquipBaoshiChange_EquipGemTable[equipPoint] do
        if gt == gem_type then
            passFlag = 1
            return 1
        end
    end

    --- 此类宝石不能放在此类装备位上
    if passFlag == 0 then
        return 0
    end

    return 1
end

--- 能否放入第四孔
--- 下列宝石不能镶嵌在第四孔上
local g_EquipBaoshiChange_GemEmbed_four_ID = {
    --- 红宝石
    50113004,50213004,50313004,50413004,50513004,50613004,50713004,50813004,50913004,
    --- 血精石
    50113006,50213006,50313006,50413006,50513006,50613006,50713006,50813006,50913006,
    --- 红宝石·通宝
	50313010,50413010,50513010,50613010,50713010,50813010,50913010,
	--- 血精石·通宝
	50313012,50413012,50513012,50613012,50713012,50813012,50913012,
    }
function EquipBaoshiChange_Can_BePutInForthHole( gem_Index )
    for i, gt in g_EquipBaoshiChange_GemEmbed_four_ID do
        if gem_Index == gt then
            return 0
        end
    end
    return 1
end

--- 就为了判断下是否能打四孔
local g_EquipBaoshiChange_Stiletto_four_ID = {

																	10514091,10514092,10514093,10514094,10514095,10514096,10514097,10514098,10515090,10515091,
																	10515092,10515093,10515094,10515095,10515096,10515097,10515098,10521090,10521091,10521092,
																	10521093,10521094,10521095,10521096,10521097,10521098,10522090,10522091,10522092,10522093,
																	10522094,10522095,10522096,10522097,10522098,10523090,10523091,10523092,10523093,10523094,
																	10523095,10523096,10523097,10523098,10514090,
																	-- 褚少微，2008.6.12。添加102神器极限打孔
																	10300100,10300101,10300102, 10301100,10301101,10301102, 10301200,10301201,10301202,
																	10302100,10302101,10302102, 10303100,10303101,10303102, 10303200,10303201,10303202,
																	10304100,10304101,10304102, 10305100,10305101,10305102, 10305200,10305201,10305202,
																	10422016,10423024,10422149,	10422150,
																	--胡凯，2008.8.29。旧100套（五件套）及新96套开放极限打孔
																	10510009,10510019,10510029,10510039,10510049,10510059,10510069,10510079,10510089,10511009,
																	10511019,10511029,10511039,10511049,10511059,10511069,10511079,10511089,10512009,10512019,
																	10512029,10512039,10512049,10512059,10512069,10512079,10512089,10513009,10513019,10513029,
																	10513039,10513049,10513059,10513069,10513079,10513089,10511096,10512092,10520092,10522101,
																	10523101,10511097,10512093,10520093,10522102,10523102,10511098,10512094,10520094,10522103,
																	10523103,10511099,10512095,10520095,10522104,10523104,
																	--胡凯，2008.9.18。90级以上（含90）生活技能产出的戒指，护符，肩开放极限打孔
																	10215020,10222020,10223020,10222035,10222036,10223035,10223036,
																	--胡凯，2008.11.11。90级以上（含90）手工装备开放极限打孔（鞋，腰带，护腕，手套，头盔，武器，护甲，项链）
																	10200019,10200020,10201019,10201020,10202019,10202020,10203019,10203020,10204019,10204020,
																	10205019,10205020,10210020,10210040,10210060,10213020,10213040,10213060,10212020,10212040,
																	10212060,10211020,10211040,10211060,10214020,10221020,10220020,
																	--zchw，2008-11-17  TT：41140 90门派套，92级神器开放第四孔
																	10510008,10510038,10510068,
																	10511018,10511028,10511048,10511058,10511078,10511088,10512008,10512038,
																	10512068,10513008,10513018,10513028,10513038,10513048,10513058,10513068,
																	10513078,10513088,10514028,10514058,10514088,10520018,10520028,10520048,
																	10520058,10520078,10520088,10521028,10521058,10521088,10522018,10522048,
																	10522078,10552008,10552038,10552068,10553008,10553018,10553038,10553048,
																	10553068,10553078,
																	--zchw 2008-11-26 TT：41771
																	10410026, 10410027, 10410034, 10410035, 10423025, 10423026,
																	--houzhifang 2008-12-22: dark
																	10150001,10150002,
																	10300005,10302005,10304005,10305005,
																	--likun 2009-8-18
																	10300103,10300104,10300105,10300106,10300107,10300108,10300109,10300110,10300111,10301103,
																	10301104,10301105,10301106,10301107,10301108,10301109,10301110,10301111,10301203,10301204,
																	10301205,10301206,10301207,10301208,10301209,10301210,10301211,10302103,10302104,10302105,
																	10302106,10302107,10302108,10302109,10302110,10302111,10303103,10303104,10303105,10303106,
																	10303107,10303108,10303109,10303110,10303111,10303203,10303204,10303205,10303206,10303207,
																	10303208,10303209,10303210,10303211,10304103,10304104,10304105,10304106,10304107,10304108,
																	10304109,10304110,10304111,10305103,10305104,10305105,10305106,10305107,10305108,10305109,
																	10305110,10305111,10305203,10305204,10305205,10305206,10305207,10305208,10305209,10305210,
																	10305211,
									--likun 2009-8-26
									10300007,	--赤焰九纹刀	96
									10301001,	--斩忧断愁枪	96
									10301199,	--弈天破邪杖	96
									10302007,	--含光弄影剑	96
									10302009,	--万仞龙渊剑	96
									10303001,	--转魂灭魄钩	96
									10304007,	--雷鸣离火扇	96
									10304009,	--雷鸣离火扇	96
									10305007,	--碎情雾影环	96
									10305009,	--天星耀阳环	96
									--zhanglei 2009-9-4
									10156001, --武魂：琉璃焰
									10156002, --武魂：御瑶盘
									--绑定武魂
									10156003,
									10156004,
									--以下为姑苏新装备
									10510118,	10510119,	10511119,	10512118,	10512119,	10513118,10513119,
                  10514109, 10515109, 10521109,	10522109,	10523109, 10552118,10553118,
                   --慕容神器
                  10302011,10302200,10302201,10302202,10302203,10302204,10302205,
									10302206,10302207,10302208,10302209,10302210,10302211,
									--永恒钻戒，90级及以上开发极限打孔
									10422128,10422129,10422130,10422131,10422132,10422136,10422137,10422138,10422139,10422140,
									--重楼召 重楼归 guochenshu 2010-09-17 重楼返
									10422155,10423064,10420091,
									--（84235、84236、84237一起提交）【每周10新】90级宋辽装备开4孔·脚本修改
									10421941,10421942,10421943,10421944,10421951,10421952,10421953,10421954,10421961,10421962,10421963,10421964,
									10415941,10415942,10415943,10415944,10415951,10415952,10415953,10415954,10415961,10415962,10415963,10415964,
									10414941,10414942,10414943,10414944,10414951,10414952,10414953,10414954,10414961,10414962,10414963,10414964,
									--quyan 重楼链，真重楼链 2010.11.29
									--lilianhuan 新增不绑定的真重楼链
									10420088,10420089,10420090,10420093,
									-- -_-!!!!kaibin for 添加少室山96套装可打孔
									10510124,10510125,10510126,10510127,10511124,10511125,10511126,10511127,10512124,10512125,10512126,10512127,
									10522124,10522125,10522126,10522127,10523124,10523125,10523126,10523127,
									10157001,10157002, --龙纹
									10422160,--变身戒指
									10415055,10415056, --modify by kaibin for 新重楼护肩
									10423076,10423077, --真重楼玉和真重楼戒
									10511138,10513138,10520138,10514149,10515149,			--唐门新增90+装备
									10521149,10522149,10523149,10522138,10523138,			----唐门新增90+装备
									10206023,10206024,10206025,10206026,10206027,10206028,10206029,10206030,10406006,10306004,10306005, --唐门装备
									10306006,10306007,10306008,10306009,10306010,10306011,10306012,10306013,10306014,10306015,10306016,10306017,10306018,	--唐门装备
									10306019,10306020,10306021,10306022,10306023,10306024,10306025,10306026,10306027,10306028,10306029,10306030,10306031,	--唐门装备
									10306032,10306033,10306034,10306035,10306036,10306037,10306038,10306039,10306040,10306041,					--唐门装备
									10510139,10511139,10512139,10513139,		--唐门100装备
									--kk 新重楼
									10410149,10410150,10410151,10410152,
									10411101,10411102,10411103,10411104,
									10412097,10412098,10412099,10412100,
									10413102,10413103,10413104,10413105,
									10414055,10414056,10414057,10414058,
									10421092,10421093,10421094,10421095,
									10511148,10513148,10520148,10514169,10515169,			--鬼谷新增90+装备
									10521169,10522169,10523169,10522158,10523158,			----唐门新增90+装备
									10207023,10207024,10207025,10207026,10207027,10207028,10207029,10207030,10407006,10307004,10307005, --鬼谷装备
									10307006,10307007,10307008,10307009,10307010,10307011,10307012,10307013,10307014,10307015,10307016,10307017,10307018,	--鬼谷装备
									10307019,10307020,10307021,10307022,10307023,10307024,10307025,10307026,10307027,10307028,10307029,10307030,10307031,	--鬼谷装备
									10307032,10307033,10307034,10307035,10307036,10307037,10307038,10307039,10307040,10307041,					--鬼谷装备
									10510149,10511149,10512149,10513149,		--鬼谷100装备
									10511153,10513152,10520152,10522173,10523173,		--桃花岛
									10514174,10515174,10521174,10522175,10523175,			----桃花岛新增90+装备
									10208023,10208024,10208025,10208026,10208027,10208028,10208029,10208030,10408006,10308004,10308005, --桃花岛装备
									10308006,10308007,10308008,10308009,10308010,10308011,10308012,10308013,10308014,10308015,10308016,10308017,10308018,	--桃花岛装备
									10308019,10308020,10308021,10308022,10308023,10308024,10308025,10308026,10308027,10308028,10308029,10308030,10308031,	--桃花岛装备
									10308032,10308033,10308034,10308035,10308036,10308037,10308038,10308039,10308040,10308041,					--桃花岛装备
									10510153,10511154,10512153,10513153,		--桃花岛100装备
									10511158,10513156,10520156,10522179,10523179,		--menpai14
									10514179,10515179,10521179,10522181,10523181,
									10216023,10216024,10216025,10216026,10216027,10216028,10216029,10216030,10416006,10316004,10316005,
									10316006,10316007,10316008,10316009,10316010,10316011,10316012,10316013,10316014,10316015,10316016,10316017,10316018,
									10316019,10316020,10316021,10316022,10316023,10316024,10316025,10316026,10316027,10316028,10316029,10316030,10316031,
									10316032,10316033,10316034,10316035,10316036,10316037,10316038,10316039,10316040,10316041,
									10510157,10511159,10512157,10513157,
									10511163,10513160,10522185,10520160,10523185,		--menpai15
									10514184,10515184,10521184,10522187,10523187,
									10217023,10217024,10217025,10217026,10217027,10217028,10217029,10217030,10417006,10317004,10317005,
									10317006,10317007,10317008,10317009,10317010,10317011,10317012,10317013,10317014,10317015,10317016,10317017,10317018,
									10317019,10317020,10317021,10317022,10317023,10317024,10317025,10317026,10317027,10317028,10317029,10317030,10317031,
									10317032,10317033,10317034,10317035,10317036,10317037,10317038,10317039,10317040,10317041,
									10510161,10511164,10512161,10513161,
									--Vega 2025.09.01。进阶后装备开放极限打孔
	10210091,10210092,10210093,10211091,10211092,10211093,10212097,10212098,10212099,10213091,
	10213092,10213093,10214031,10215031,10220031,10221031,10222037,10222038,10222039,10223037,
	10223038,10223039,
		}
local g_EquipBaoshiChange_Stiletto_four_80_ID = {
	10200018,10201018,10202018,10203018,10204018,10205018,10210018,10210038,10210058,10211018,
	10211038,10211058,10212018,10212038,10212058,10213018,10213038,10213058,10214018,10215018,
	10220019,10221019,10222019,10222033,10222034,10223019,10223033,10223034,10300004,10300006,
	10301000,10301198,10302004,10302006,10302008,10302010,10303000,10304004,10304006,10304008,
	10305004,10305006,10305008,10410025,10410033,10414841,10414842,10414843,10414844,10414851,
	10414852,10414853,10414854,10414861,10414862,10414863,10414864,10415841,10415842,10415843,
	10415844,10415851,10415852,10415853,10415854,10415861,10415862,10415863,10415864,10421841,
	10421842,10421843,10421844,10421851,10421852,10421853,10421854,10421861,10421862,10421863,
	10421864,10510017,10510047,10510077,10511007,10511037,10511067,10511117,10512017,10512047,
	10512077,10514007,10514017,10514037,10514047,10514067,10514077,10514117,10515027,10515057,
	10515087,10520027,10520057,10520087,10521007,10521017,10521027,10521037,10521047,10521057,
	10521067,10521077,10521087,10521117,10522007,10522037,10522067,10522117,10523017,10523047,
	10523077,10552027,10552057,10552087,10553007,10553027,10553037,10553057,10553067,10553087,
	10553117,10400075,10402075,10404072,10405071,10412081,10412083,10413084,10413086,10422122,
	10422124,10423047,10423049,10510092,10510093,10510094,10510095,10511094,10511095,10512090,
	10512091,10514101,10514102,10514103,10514104,10522099,10522100,10523099,10523100,10510120,
	10510121,10510122,10510123,10511120,10511121,10511122,10511123,10512120,10512121,10512122,
	10512123,10522120,10522121,10522122,10522123,10523120,10523121,10523122,10523123,
	10510137,10512137,10514137,10521137,10523137,		--唐门新增装备
	10510147,10512147,10514157,10521157,10523157,		--鬼谷新增装备
	10510152,10512152,10514172,10521172,10523172,		--桃花岛新增装备
	10510156,10512156,10514177,10521177,10523178,		--menpai14
	10510160,10512160,10514182,10521182,10523184,
	}
--- 装备是否能打第四个孔
function EquipBaoshiChange_Can_Stiletto_Four( itemTableIndex, isDark, isHXY )
    if( isDark == 1) then
        return 1
		end
		
		if( isHXY == 1) then
        return 1
		end

    --- 90+装备
    for i, v in g_EquipBaoshiChange_Stiletto_four_ID do
		if itemTableIndex == v then
            return 1
		end
	end
    --- 80~89级装备
	for i, v in g_EquipBaoshiChange_Stiletto_four_80_ID do
	    if itemTableIndex == v then
	        return 1
	    end
	end
	
	-- 所有神器都可以打四孔 by lishilong 2016-8-23
	if itemTableIndex >= EQUIP_SHENQI_BEGIN and itemTableIndex <= EQUIP_SHENQI_END then
		return 1
	end
	
	--宗门信物都可4孔
	if DataPool:Lua_GetEquipPointByIndex(itemTableIndex) == 23 then
		return 1
	end

	return 0
end

function EquipBaoshiChange_BeginCareObject( objCaredId )
	this:CareObject( objCaredId, 1, "EquipBaoshiChange");
end
function EquipBaoshiChange_StopCareObject( objCaredId )
	this:CareObject( objCaredId, 0, "EquipBaoshiChange");
end

--- 根据物品序列号来获得物品的类型
function EquipBaoshiChange_GetGemTypeByIndex( itemTblIdx )
    if itemTblIdx == nil or itemTblIdx <= 0 then
        return -1
    end

    local tmpValue = math.mod( itemTblIdx, 100000 )
    local itemType = math.floor( tmpValue / 1000 )
    return itemType
end

function EquipBaoshiChange_Can_SwitchGem( curSel )
    local conPos     = g_EquipBaoshiChange_Equip_TypeList[curSel].gemConIndex
    local equipPoint = g_EquipBaoshiChange_Equip_TypeList[curSel].equipIndex

    --- 得到装备上的宝石
    local equipTypeList = {}
    if g_EquipBaoshiChange_Equip_Info.isEquiped <= 0 then
        return 1    --- 没有装备
    end
    for i = 1, 4 do
        equipTypeList[i] = g_EquipBaoshiChange_Equip_Info.gemInfo[i].gemType
    end

    --- 其次得到装备位上的宝石类型
    local gemConTypeList  = { }
    local bHaveGemCon     = 0       --- 装备位上是否有宝石
    for i = 1, 4 do
        gemConTypeList[i] = g_EquipBaoshiChange_Container_Info[i].gemType
        if gemConTypeList[i] > 0 then
            bHaveGemCon       = 1
        end
    end
    if bHaveGemCon == 0 then
        return 2
    end

    --- 判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
    for i = 1, 4 do
        --- 如果装备位上有宝石
        if gemConTypeList[i] > 0 then
            -- 判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
            if equipTypeList[i] <= 0 then
                return 3
            end
            equipTypeList[i] = gemConTypeList[i]
        end
    end

    --- 判断互换后，当前装备前三孔是否会出现同类型宝石
    if equipTypeList[1] > 0 then
        if ( equipTypeList[1] == equipTypeList[2] ) or ( equipTypeList[1] == equipTypeList[3] ) then
            return 4
        end
    end

    if equipTypeList[2] > 0 then
        if ( equipTypeList[1] == equipTypeList[2] ) or ( equipTypeList[2] == equipTypeList[3] ) then
            return 4
        end
    end

    if equipTypeList[3] > 0 then
        if ( equipTypeList[1] == equipTypeList[3] ) or ( equipTypeList[2] == equipTypeList[3] ) then
            return 4
        end
    end

    return 0
end


--- 信息提示区域的显示
function EquipBaoshiChange_UpdateHints( typeListIndex )
    local ret = EquipBaoshiChange_Can_SwitchGem( typeListIndex )
    if ret == 1 then
        EquipBaoshiChange_tishi : SetText( "#{WBSS_120727_15}" )      --- 装备位上无装备时，镶嵌后无法进行万宝随身互换
    elseif ret == 2 then --- 这里等字典
        EquipBaoshiChange_tishi : SetText( "#{WBSS_120727_98}" )      --- 装备位上尚未镶嵌宝石，该装备位将不能进行互换
    elseif ret == 3 then
        EquipBaoshiChange_tishi : SetText( "#{WBSS_120727_17}" )      --- 对应的装备孔位中没有宝石，镶嵌后无法进行万宝随身互换
    elseif ret == 4 then
        EquipBaoshiChange_tishi : SetText( "#{WBSS_120727_18}" )      --- 互换时装备前三孔会出现同类型宝石，镶嵌后无法进行万宝随身互换
    elseif ret == 0 then
        EquipBaoshiChange_tishi : SetText( "#{WBSS_120727_19}" )      --- 满足互换条件，可以进行万宝随身互换
    else
        EquipBaoshiChange_tishi : SetText( "" )
    end
end

function EquipBaoshiChange_GetTypeListIndex( )
    --- 得到在TypeList里面的索引
    local typeListIndex = 1
    for i = 1, table.getn( g_EquipBaoshiChange_Equip_TypeList ) do
        if g_EquipBaoshiChange_Equip_TypeList[i].equipIndex == g_EquipBaoshiChange_Equip_Info.equipPoint then
            typeListIndex = i
            break
        end
    end
    return typeListIndex
end

function EquipBaoshiChange_OpenFreshManGuide( )
    local fX, fY = this:GetChildOffset("EquipBaoshiChange_Special_Button9")
    fX = fX + EquipBaoshiChange_Special_Button9:GetProperty("AbsoluteWidth")  / 2
    fY = fY + EquipBaoshiChange_Special_Button9:GetProperty("AbsoluteHeight") / 2
    OpenFreshManGuide( 1, 37, fX, fY, "EquipBaoshiChange", "northeast" )
end

function EquipBaoshiChange_OnMoved()
    if "EquipBaoshiChange" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
end
