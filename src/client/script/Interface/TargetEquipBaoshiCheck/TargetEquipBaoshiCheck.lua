--- 一键换宝石界面
--- Author: David Gao 2012.08.13

local g_TargetEquipBaoshiCheck_Frame_UnifiedPosition

local g_TargetEquipBaoshiCheck_Equip_Gem            = {}     --- 装备上的宝石
local g_TargetEquipBaoshiCheck_Equip_GemTypeList    = {}     --- 装备上的宝石类型信息

local g_TargetEquipBaoshiCheck_Gem_Container              = {}     --- 装备位上的宝石
local g_TargetEquipBaoshiCheck_Gem_Container_GemTypeList  = {}     --- 装备位上的宝石类型信息

local g_TargetEquipBaoshiCheck_IsHaveEquiped  = -1     --- 是否有装备

local g_TargetEquipBaoshiCheck_Current_Sel = -1       --- 纪录当前选择的哪个界面

-- 所有神器都可以打四孔 by lishilong 2016-8-23
local EQUIP_SHENQI_BEGIN = 10300000
local EQUIP_SHENQI_END = 10399999

--设置经典版本使用的图片资源
local g_TargetEquipBaoshiCheck_UnActived_Image  = "set:Agname3 image:BaoShiCheckFeng"    --- 未打孔
local g_TargetEquipBaoshiCheck_Actived_Image    = "set:UIIcons image:Equip_Ring"      --- 暂时使用真元激活的图片

local g_TargetEquipBaoshiCheck_Equip_TypeList =
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

function TargetEquipBaoshiCheck_PreLoad()
    this:RegisterEvent("UI_COMMAND");
    this:RegisterEvent("REFRESH_EQUIP");

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("GEM_CONTAINER_CHECK")
end

function TargetEquipBaoshiCheck_OnLoad()
	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片资源为唯美版资源
		g_TargetEquipBaoshiCheck_UnActived_Image  = "set:WM_CommonFrame1 image:Feng"    --- 未打孔
		g_TargetEquipBaoshiCheck_Actived_Image    = "set:WM_Button2 image:Equip_Ring"      --- 暂时使用真元激活的图片
	end

    g_TargetEquipBaoshiCheck_Frame_UnifiedPosition = TargetEquipBaoshiCheck_Frame:GetProperty( "UnifiedPosition" )

    g_TargetEquipBaoshiCheck_Equip_Gem[1] = TargetEquipBaoshiCheck_Special_Button1
    g_TargetEquipBaoshiCheck_Equip_Gem[2] = TargetEquipBaoshiCheck_Special_Button2
    g_TargetEquipBaoshiCheck_Equip_Gem[3] = TargetEquipBaoshiCheck_Special_Button3
    g_TargetEquipBaoshiCheck_Equip_Gem[4] = TargetEquipBaoshiCheck_Special_Button4

    g_TargetEquipBaoshiCheck_Gem_Container[1] = TargetEquipBaoshiCheck_Special_Button6
    g_TargetEquipBaoshiCheck_Gem_Container[2] = TargetEquipBaoshiCheck_Special_Button7
    g_TargetEquipBaoshiCheck_Gem_Container[3] = TargetEquipBaoshiCheck_Special_Button8
    g_TargetEquipBaoshiCheck_Gem_Container[4] = TargetEquipBaoshiCheck_Special_Button9

    TargetEquipBaoshiCheck_Clear()

    g_TargetEquipBaoshiCheck_Current_Sel = -1

end

-- OnEvent
function TargetEquipBaoshiCheck_OnEvent(event)
	if event == "GEM_CONTAINER_CHECK"  then
        local btnIndex = tonumber( arg0 )
        local isTarget = tonumber( arg1 )
        if btnIndex < 1 or btnIndex > 19 then
            return
        end

        --- 如果是查看对方的装备位宝石
        if isTarget == 1 then
            if g_TargetEquipBaoshiCheck_Current_Sel == btnIndex then
                if this:IsVisible() then
                    TargetEquipBaoshiCheck_Close_Clicked()
                end
                 return
            end

            g_TargetEquipBaoshiCheck_Current_Sel = btnIndex
            TargetEquipBaoshiCheck_Update( btnIndex )
            if this:IsVisible() then
            else
                this:Show()
            end
        elseif isTarget == 3 then
            TargetEquipBaoshiCheck_OnClosed()
            return
        end
    end

    if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == 2012081302 then
        if ( this : IsVisible() ) then
            TargetEquipBaoshiCheck_Update( g_TargetEquipBaoshiCheck_Current_Sel )
        end
    elseif ( event == "REFRESH_EQUIP" ) then
        if ( this:IsVisible() ) then
            TargetEquipBaoshiCheck_Update( g_TargetEquipBaoshiCheck_Current_Sel )
        end
	elseif event == "HIDE_ON_SCENE_TRANSED"  then
		this:Hide()
	elseif (event == "ADJEST_UI_POS" ) then
		TargetEquipBaoshiCheck_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TargetEquipBaoshiCheck_On_ResetPos()
	end
end

function TargetEquipBaoshiCheck_Init( itemState )

    return
end

function TargetEquipBaoshiCheck_OnClosed()
    this:Hide()
    return
end

function TargetEquipBaoshiCheck_On_ResetPos()
    TargetEquipBaoshiCheck_Frame:SetProperty( "UnifiedPosition", g_TargetEquipBaoshiCheck_Frame_UnifiedPosition )
    return
end


function TargetEquipBaoshiCheck_Update( btnIndex )
    if btnIndex < 1 or btnIndex > 19 then
        return
    end
    TargetEquipBaoshiCheck_Clear()

    --- 对话框名称
    local equipName = g_TargetEquipBaoshiCheck_Equip_TypeList[btnIndex].name
    local strTitle = ScriptGlobal_Format( "#{WBSS_120727_11}", equipName )
    TargetEquipBaoshiCheck_DragTitle : SetText( strTitle )

    local equipPoint = g_TargetEquipBaoshiCheck_Equip_TypeList[btnIndex].equipIndex
    local gemConPos  = g_TargetEquipBaoshiCheck_Equip_TypeList[btnIndex].gemConIndex

    local equipIndex, gemHole, equipGem1, equipGem2, equipGem3, equipGem4 = LifeAbility : Get_OtherPlayerEquip_GemInfo( equipPoint )
    local conGem1, conGem2, conGem3, conGem4 = LifeAbility : Get_OtherPlayerEquip_GemContainerInfo( gemConPos )
    --- 是否是暗器
    local bIsDark       = 0
    if curEquipIndex == 17 then
        bIsDark = 1
    end
    
    local bIsHxy       = 0
    if equipPoint == 21 then
        bIsHxy = 1
    end

    local index = gemConPos * 4
    if equipIndex ~= -1 then
        for i = 1, 4 do
            local equipGemAction = EnumAction( index + i - 1, "targetequipgem");

            --- 如果有宝石
            if equipGemAction:GetID() ~= 0 then
                g_TargetEquipBaoshiCheck_Equip_Gem[i] : SetActionItem( equipGemAction:GetID() )
            else
                g_TargetEquipBaoshiCheck_Equip_Gem[i] : SetActionItem( -1 )
                --- 未开启的孔显示封印状态
                if i > gemHole then
                    g_TargetEquipBaoshiCheck_Equip_Gem[i] : SetActionItem( -1 );
                    g_TargetEquipBaoshiCheck_Equip_Gem[i] : SetToolTip( "#{WBSS_120727_40}" )   --- 装备的该孔位未开启
                    g_TargetEquipBaoshiCheck_Equip_Gem[i] : SetProperty( "BackImage",  g_TargetEquipBaoshiCheck_UnActived_Image )
                    --- 第四孔特殊判断
                    if i == 4 then
                        --- 如果无法开启第四孔
                        if 0 == TargetEquipBaoshiCheck_Can_Stiletto_Four( equipIndex, bIsDark, bIsHxy ) then
                            g_TargetEquipBaoshiCheck_Equip_Gem[i] : SetToolTip( "#{WBSS_120727_41}" )   --- 装备无法开启第四孔
                        end
                    end
                --- 开孔未镶嵌宝石则对应格子处显示空格子
                else
                    g_TargetEquipBaoshiCheck_Equip_Gem[i] : SetProperty( "BackImage",  g_TargetEquipBaoshiCheck_Actived_Image )
                    g_TargetEquipBaoshiCheck_Equip_Gem[i] : SetToolTip( "#{WBSS_120727_45}" )   --- 该孔位未镶嵌宝石
                end
            end
            g_TargetEquipBaoshiCheck_Equip_Gem[i] : Show()
        end
    else
        for i = 1, 4 do
            g_TargetEquipBaoshiCheck_Equip_Gem[i] : Hide()
        end
        TargetEquipBaoshiCheck_TXT : Show()
    end

    --- 其次显示装备位上的宝石
    for i = 0, 3 do
        local gemConAction   = EnumAction( index + i, "targetgemcontainer");
        if gemConAction:GetID() ~= 0 then
            g_TargetEquipBaoshiCheck_Gem_Container[i+1] : SetActionItem( gemConAction:GetID() )
        end
    end

    return
end

--- 根据物品序列号来获得物品的类型
function TargetEquipBaoshiCheck_GetGemTypeByIndex( itemTblIdx )
    if itemTblIdx == nil or itemTblIdx <= 0 then
        return -1
    end

    local tmpValue = math.mod( itemTblIdx, 100000 )
    local itemType = math.floor( tmpValue / 1000 )
    return itemType
end

function TargetEquipBaoshiCheck_Clear()
    --- 初始化所有的Buttons
    for i=1, 4 do
        g_TargetEquipBaoshiCheck_Equip_Gem[i]     : SetActionItem( -1 )
        g_TargetEquipBaoshiCheck_Gem_Container[i] : SetActionItem( -1 )

        g_TargetEquipBaoshiCheck_Equip_GemTypeList[i]         = -1
        g_TargetEquipBaoshiCheck_Gem_Container_GemTypeList[i] = -1
    end
    TargetEquipBaoshiCheck_DragTitle  : SetText( "" )

    g_TargetEquipBaoshiCheck_IsHaveEquiped = -1
    TargetEquipBaoshiCheck_TXT : Hide()
end

function TargetEquipBaoshiCheck_Close_Clicked()
    TargetEquipBaoshiCheck_Clear()
    g_TargetEquipBaoshiCheck_Current_Sel = -1
    this:Hide()
end

function TargetEquipBaoshiCheck_OnHidden()
    TargetEquipBaoshiCheck_Close_Clicked()
end



--- 就为了判断下是否能打四孔
local g_TargetEquipBaoshiCheck_Stiletto_four_ID = {

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

local g_TargetEquipBaoshiCheck_Stiletto_four_80_ID = {
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
function TargetEquipBaoshiCheck_Can_Stiletto_Four( itemTableIndex, isDark, isHxy )
    if( isDark == 1) then
        return 1
		end
		
		if( isHxy == 1) then
        return 1
		end

    --- 90+装备
    for i, v in g_TargetEquipBaoshiCheck_Stiletto_four_ID do
		if itemTableIndex == v then
            return 1
		end
	end
    --- 80~89级装备
	for i, v in g_TargetEquipBaoshiCheck_Stiletto_four_80_ID do
	    if itemTableIndex == v then
	        return 1
	    end
	end
	
	-- 所有神器都可以打四孔 by lishilong 2016-8-23
	if itemTableIndex >= EQUIP_SHENQI_BEGIN and itemTableIndex <= EQUIP_SHENQI_END then
		return 1
	end
	
    return 0
end
