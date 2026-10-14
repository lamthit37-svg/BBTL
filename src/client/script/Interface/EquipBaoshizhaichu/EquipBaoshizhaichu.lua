--- 一键换宝石界面
--- Author: David Gao 2012.08.13

local g_EquipBaoshizhaichu_SERVER_CONTROL_1 = 2012081303   --- 一键换宝石使用界面
local g_EquipBaoshizhaichu_Frame_UnifiedPosition
local g_EquipBaoshiZhaichu_ObjCared = -1
local g_EquipBaoshiZhaichu_NeedHint = 0;

local g_EquipBaoshizhaichu_Container_Gems = {}        --- 装备位上的宝石
local g_EquipBaoshizhaichu_Gem_Lists      = {}        --- 装备位上的宝石
local g_EquipBaoshizhaichu_Selected_List  = {}        --- 选中的宝石列表
local g_EquipBaoshizhaichu_Pos_Selected   = -1        --- 选中的装备位
local g_EquipBaoshizhaichu_Animates       = {}        --- 动画效果
local g_EquipBaoshizhaichu_Equip_TypeList = 
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

local g_EquipBaoshiZhaichu_WanbaoZhaichu_Fu = 30900126     --- 万宝摘除符ID

local g_EquipBaoshizhaichu_YuanBaoPay = 1

function EquipBaoshizhaichu_PreLoad()
    this:RegisterEvent("UI_COMMAND");
    this:RegisterEvent("GEM_CONTAINER_REFRESH");
    this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function EquipBaoshizhaichu_OnLoad()
    g_EquipBaoshizhaichu_Frame_UnifiedPosition = EquipBaoshizhaichu_Frame:GetProperty( "UnifiedPosition" )

    g_EquipBaoshizhaichu_Container_Gems[1] = EquipBaoshizhaichu_Special_Button1
    g_EquipBaoshizhaichu_Container_Gems[2] = EquipBaoshizhaichu_Special_Button2
    g_EquipBaoshizhaichu_Container_Gems[3] = EquipBaoshizhaichu_Special_Button3
    g_EquipBaoshizhaichu_Container_Gems[4] = EquipBaoshizhaichu_Special_Button4

    g_EquipBaoshizhaichu_Animates[1] = BaoShizhaichu1
    g_EquipBaoshizhaichu_Animates[2] = BaoShizhaichu2
    g_EquipBaoshizhaichu_Animates[3] = BaoShizhaichu3
    g_EquipBaoshizhaichu_Animates[4] = BaoShizhaichu4

    g_EquipBaoshizhaichu_Gem_Lists[1] = -1
    g_EquipBaoshizhaichu_Gem_Lists[2] = -1
    g_EquipBaoshizhaichu_Gem_Lists[3] = -1
    g_EquipBaoshizhaichu_Gem_Lists[4] = -1

    g_EquipBaoshizhaichu_Pos_Selected = -1
    EquipBaoshizhaichu_zhuangbeixiala : ResetList()
    
    g_EquipBaoshizhaichu_YuanBaoPay = 1;
    EquipBaoshizhaichu_YuanBaoPay:SetCheck(g_EquipBaoshizhaichu_YuanBaoPay)
end

-- OnEvent
function EquipBaoshizhaichu_OnEvent(event)
    if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_EquipBaoshizhaichu_SERVER_CONTROL_1 then
        EquipBaoshizhaichu_Update()
        if g_EquipBaoshizhaichu_YuanBaoPay == 1 or g_EquipBaoshizhaichu_YuanBaoPay == 0 then
					EquipBaoshizhaichu_YuanBaoPay:SetCheck(g_EquipBaoshizhaichu_YuanBaoPay)
				end
		this:Show()
        
        g_EquipBaoshiZhaichu_ObjCared = -1
        local xx = Get_XParam_INT( 0 )
        g_EquipBaoshiZhaichu_ObjCared = DataPool : GetNPCIDByServerID( xx )
        if g_EquipBaoshiZhaichu_ObjCared == -1 then
            return
        end
        EquipBaoshiZhaichu_BeginCareObject( g_EquipBaoshiZhaichu_ObjCared )
    elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_EquipBaoshiZhaichu_ObjCared) then
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
		    --取消关心
    		EquipBaoshizhaichu_OnClosed()
		end
    elseif ( event == "UI_COMMAND" ) and tonumber( arg0 ) == 2012081302 then
        if ( this : IsVisible() ) then
            EquipBaoshizhaichu_EquipSel()
        end
    elseif ( event == "GEM_CONTAINER_REFRESH" ) then
        if ( this : IsVisible() ) then
            EquipBaoshizhaichu_EquipSel()
        end
	elseif event == "HIDE_ON_SCENE_TRANSED"  then
		EquipBaoshizhaichu_OnClosed()
	elseif (event == "ADJEST_UI_POS" ) then
		EquipBaoshizhaichu_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipBaoshizhaichu_On_ResetPos()
	end
end

function EquipBaoshizhaichu_Update( )
    EquipBaoshizhaichu_zhuangbeixiala : ResetList ()
    for i = 1, table.getn( g_EquipBaoshizhaichu_Equip_TypeList ) do
		if Player:GetData("Is2606S") == 1 and (i == 15 or i == 18) then
		else
        EquipBaoshizhaichu_zhuangbeixiala : AddTextItem( g_EquipBaoshizhaichu_Equip_TypeList[i].name, i - 1 )
		end
    end
    EquipBaoshizhaichu_zhuangbeixiala : SetCurrentSelect( 0 )
    EquipBaoshizhaichu_EquipSel( )
end

function EquipBaoshizhaichu_EquipSel()
    EquipBaoshizhaichu_Clear()

    local _, curSel = EquipBaoshizhaichu_zhuangbeixiala : GetCurrentSelect( )
    if curSel == nil or curSel < 0 or curSel > table.getn( g_EquipBaoshizhaichu_Equip_TypeList ) then
        return
    end
    curSel = curSel + 1
    local curIndex = g_EquipBaoshizhaichu_Equip_TypeList[curSel].gemConIndex
    g_EquipBaoshizhaichu_Pos_Selected = curIndex

    --- 显示装备位上的宝石
    LifeAbility : GemContainer_Update()
    for i = 1, 4 do
        local itemID, _, _ = LifeAbility : GetGemContainer_Gem( curIndex, i - 1 )
        if itemID ~= -1 then
            local ActionID = DataPool : EnumPlayerMission_ItemAction( itemID )
            g_EquipBaoshizhaichu_Container_Gems[i] : SetActionItem( ActionID )
            g_EquipBaoshizhaichu_Gem_Lists[i]     = itemID
        end
    end
    g_EquipBaoshizhaichu_NeedHint = 0;
end

function EquipBaoshizhaichu_Clear(  )
    for i=1, 4 do
        g_EquipBaoshizhaichu_Container_Gems[i]     : SetActionItem( -1 )
        g_EquipBaoshizhaichu_Gem_Lists[i]     = -1
        g_EquipBaoshizhaichu_Selected_List[i] = 0
        g_EquipBaoshizhaichu_Animates[i] : Hide()
    end
    g_EquipBaoshizhaichu_Pos_Selected = -1
    g_EquipBaoshizhaichu_NeedHint = 0;
end

function EquipBaoshizhaichu_OnClosed()
    EquipBaoshizhaichu_Clear()
    g_EquipBaoshizhaichu_YuanBaoPay = EquipBaoshizhaichu_YuanBaoPay:GetCheck();
    this:Hide()
    return
end

function EquipBaoshizhaichu_On_ResetPos()
    EquipBaoshizhaichu_Frame:SetProperty( "UnifiedPosition", g_EquipBaoshizhaichu_Frame_UnifiedPosition )
    g_EquipBaoshizhaichu_NeedHint = 0;
    return
end

--- 得到当前材料包有多少空位
function EquipBaoshizhaichu_GetCurPacketMat_SpaceNum(  )
    local CurrBagNum = DataPool:GetMatBag_Num()
    local curMatNum  = 0
    local PACKAGE_NUM_PER_LINE = 5
    local nMaxLine = math.floor( CurrBagNum / PACKAGE_NUM_PER_LINE );
	--如果是整除了
	if( nMaxLine * PACKAGE_NUM_PER_LINE == CurrBagNum ) then
	else
		nMaxLine = nMaxLine + 1;
	end

	--- 如果超过当前显示的最大范围了，就更新包的行数
	local nMaxDisplayNumber = nMaxLine * PACKAGE_NUM_PER_LINE;
	for i=1, nMaxDisplayNumber do
        local theAction,bLocked = PlayerPackage:EnumItem( "material", i-1 );
        if theAction : GetID() ~= 0 then
            curMatNum = curMatNum + 1
        end
    end

    return CurrBagNum - curMatNum

end

function EquipBaoshizhaichu_Selected( index )
    if index < 1 or index > 4 then
        return
    end
    
    if g_EquipBaoshizhaichu_Gem_Lists[index] < 0 then
        g_EquipBaoshizhaichu_Selected_List[index] = 0
        --- g_EquipBaoshizhaichu_Container_Gems[index] : SetPushed( 0 )
        g_EquipBaoshizhaichu_Animates[index] : Hide()
        return
    end

    local curValue = g_EquipBaoshizhaichu_Selected_List[index]
    if curValue == 0 then
        g_EquipBaoshizhaichu_Selected_List[index] = 1
        g_EquipBaoshizhaichu_Animates[index] : Show()
    else
        g_EquipBaoshizhaichu_Selected_List[index] = 0
        g_EquipBaoshizhaichu_Animates[index] : Hide()
    end

    g_EquipBaoshizhaichu_NeedHint = 0;
    --- g_EquipBaoshizhaichu_Container_Gems[index] : SetPushed( g_EquipBaoshizhaichu_Selected_List[index] ) 
    
end

function EquipBaoshizhaichu_OK_Clicked()
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
    if 0 == EquipBaoshizhaichu_Is_Learned_Skill() then
        PushDebugMessage( "#{WBSS_120727_61}" ) --- 只有学习了万宝随身的玩家才能进行此操作
        return
    end

    --- 判断当前装备位是否有选择
    if g_EquipBaoshizhaichu_Pos_Selected < 0 then
        PushDebugMessage( "#{WBSS_120727_67}" ) --- 请先选择需要进行万宝摘除的装备位
        return
    end

    --- 判断当前是否有选中的需要摘除的宝石
    local selectedNum = 0
    for i = 1, 4 do
        selectedNum = selectedNum + g_EquipBaoshizhaichu_Selected_List[i]
    end
    if selectedNum == 0 then
        PushDebugMessage( "#{WBSS_120727_68}" ) --- 请选择需要摘除的宝石
        return
    end

    --- 判断玩家材料栏中的空位是否大于等于选中的宝石数量
    local curMatFreeSpace = EquipBaoshizhaichu_GetCurPacketMat_SpaceNum(  )
    if curMatFreeSpace < selectedNum then
        if selectedNum == 1 then
            PushDebugMessage( "#{WBSS_120727_69}" ) --- 材料栏没有空位，无法摘除宝石
        else
            local strText = ScriptGlobal_Format( "#{WBSS_120727_70}", selectedNum, selectedNum )
            PushDebugMessage( strText ) --- 材料栏空位不足X个，无法同时摘除X个宝石
        end
        return
    end

    --- 判断玩家包裹中未加锁的万宝摘除符数量是否大于等于选中的宝石数量
    --local curFuNum = PlayerPackage : CountAvailableItemByIDTable( g_EquipBaoshiZhaichu_WanbaoZhaichu_Fu ) 
    --if curFuNum < selectedNum then
    --    if selectedNum == 1 then
    --        PushDebugMessage( "#{WBSS_120727_71}" ) --- 包裹中缺少未加锁的万宝摘除符，无法进行万宝摘除
    --    else
    --        local strText = ScriptGlobal_Format( "#{WBSS_120727_72}", selectedNum, selectedNum )
    --        PushDebugMessage( strText ) --- 包裹中未加锁的万宝摘除符数量不足X个，无法同时摘除X个宝石
    --    end
    --    return
    --end
    
    if g_EquipBaoshizhaichu_NeedHint == 0 then
	    PushEvent("GAMELOGIN_SYSTEM_INFO_OK", "#{WBZC_140211_01}", "-1")
	    g_EquipBaoshizhaichu_NeedHint = 1;
    else
	    Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name( "RemoveGemFromContainer" );
		Set_XSCRIPT_ScriptID( 701614 );
		Set_XSCRIPT_Parameter( 0, g_EquipBaoshizhaichu_Pos_Selected     );         --- 装备位
		Set_XSCRIPT_Parameter( 1, g_EquipBaoshizhaichu_Selected_List[1] );
		Set_XSCRIPT_Parameter( 2, g_EquipBaoshizhaichu_Selected_List[2] );
		Set_XSCRIPT_Parameter( 3, g_EquipBaoshizhaichu_Selected_List[3] );
		Set_XSCRIPT_Parameter( 4, g_EquipBaoshizhaichu_Selected_List[4] );
		Set_XSCRIPT_Parameter( 5, tonumber(EquipBaoshizhaichu_YuanBaoPay:GetCheck()) );
		Set_XSCRIPT_ParamCount( 6 );
	    Send_XSCRIPT();
	    --g_EquipBaoshizhaichu_NeedHint = 0;
    end

  --  EquipBaoshizhaichu_OnClosed()

    return
end


-----------------------------------------------------------------------------------
--- 下面这些全部是辅助函数 AuxFunc
-----------------------------------------------------------------------------------
--- 玩家是否学会了一键换宝石技能
function EquipBaoshizhaichu_Is_Learned_Skill()
    local gemSwitchSkillID = 278

	if( Player:GetSkillInfo( gemSwitchSkillID, "learn") ) then
        return 1
	else
        return 0
	end
end

function EquipBaoshiZhaichu_BeginCareObject( objCaredId )
	this:CareObject( objCaredId, 1, "EquipBaoshiZhaichu");
end
function EquipBaoshiZhaichu_StopCareObject( objCaredId )
	this:CareObject( objCaredId, 0, "EquipBaoshiZhaichu");
end
