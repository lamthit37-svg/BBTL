local bBeingRadio = 0;                  --
--local MissionType = {};               --  废弃, 而且还继续被重定义, 避免错误, 在此取消定义
local MissionPucker = {};               --  已接任务的分类折叠标志, 1: 非折叠, 0: 折叠
local Current_Select;                   --  当前选择任务
local First_Open = 1;                   --  首次打开?
local MissionParam_Index = 0;           --  任务变量索引
local HaveGetMissionNum = 0;            --  已接任务数量

local LEVEL_TO_MY_LEVEL = 10000;        --  与玩家等级一致的任务等级

local g_nMissionNum = 20;               --  最大可接任务数

local MissionOutlineDeploy = {}         --  未接任务的分类折叠标志, 1: 非折叠, 0: 折叠

local CurList                           -- 1为任务列表,2为任务索引

local Current_Clicked = -1;
--TT53675对所有不符合规范，没有将missionparam第0位做为任务完成标志的任务脚本做特殊处理,需要特殊处理的任务脚本号列表：
local SpecialMissionList = {200006,200031}

-- 界面的默认相对位置
local g_QuestLog_Frame_UnifiedXPosition;
local g_QuestLog_Frame_UnifiedYPosition;

local g_QuestLog_LastSelect=-1;                   --  当前选择任务

local g_MenPai_Special_id = 0

local g_QuestLog_ListID = -1


-- 帮会交互任务
-- local g_GuildInteractiveMissionDesc = {
-- 	"    前往#G帮会城市（%d，%d）#W、#G（%d，%d）#W、#G（%d，%d）#W、#G（%d，%d）#W、#G（%d，%d）#W等处，救治5名#R受伤的帮众#W，返回#R武大威#G（134，51）#W处交还任务。#r    打开TAB地图，可以查看受伤的帮众的所在位置。#r    #G注意：多人一起治疗可以加快治疗速度。放弃此帮会任务后15分钟内不能再次接取同类任务。",		-- 任务一：英豪携手救伤患
-- 	"#{BHDR_140528_75}",		-- 任务二：奋勇协力捉飞贼
-- 	"#{BHDR_140528_94}",		-- 任务三：缆却扁舟捕鱼归
-- 	"#{BHDR_140528_113}",		-- 任务四：荷锄南园除虫害
-- 	"#{BHDR_140528_129}",		-- 任务五：军需支援集物资
-- }
-- local g_GuildInteractiveMission_MisType = 6				-- 任务类型(子任务ID)
-- -- 任务1
-- local g_GuildInteractiveMission1_PosIndexOne = 2		-- 第一个伤员的位置索引
-- local g_GuildInteractiveMission1_PosIndexTwo = 3		-- 第二个伤员的位置索引
-- local g_GuildInteractiveMission1_PosIndexThree = 4		-- 第三个伤员的位置索引
-- local g_GuildInteractiveMission1_PosIndexFour = 5		-- 第四个伤员的位置索引
-- local g_GuildInteractiveMission1_PosIndexFive = 7		-- 第五个伤员的位置索引
-- -- 任务2
-- local g_GuildInteractiveMission2_PosIndex = 4			-- 起始坐标点索引

--生育系统成长任务相关内容
local g_QuestLog_Infant_SubMissionTypeEnum = {BaiFang=1, Caiji=2, DingDianYinDao=3, XunWu=4, BuZhuo=5,}

local g_QuestLog_Infant_MissionType_Index = 1
local g_QuestLog_Infant_baozhuang_Index = 2
local g_QuestLog_Infant_Mission_Index = 3

local g_QuestLog_Infant_tips = {
														BaiFang = {"#{CZRW_130822_18}",
																			 "#{CZRW_130822_24}",
																			 "#{CZRW_130822_30}",
																			 "#{CZRW_130822_38}",},

														Caiji = {"#{CZRW_130822_46}",
																		 "#{CZRW_130822_51}",
																		 "#{CZRW_130822_56}",
																		 "#{CZRW_130822_61}",
																		},

														DingDianYinDao = {"#{CZRW_130822_91}",
																							"#{CZRW_130822_96}",
																							"#{CZRW_130822_101}",
																							"#{CZRW_130822_106}",},

														XunWu = {"#{CZRW_130822_69}",
																		 "#{CZRW_130822_74}",
																		 "#{CZRW_130822_79}",
																		 "#{CZRW_130822_84}",
                                                                         "#{CZRW_130822_163}",
                                                                         "#{CZRW_130822_164}",
                                                                         "#{CZRW_130822_165}",
                                                                         "#{CZRW_130822_166}",},

														BuZhuo = {"#{CZRW_130822_116}",
																			"#{CZRW_130822_116}",
																			"#{CZRW_130822_125}",
																			"#{CZRW_130822_130}",}, }

local g_QuestLog_Infant_complete_tips = {
														BaiFang = {"#{CZRW_130822_19}",
																			 "#{CZRW_130822_25}",
																			 "#{CZRW_130822_31}",
																			 "#{CZRW_130822_39}",},

														Caiji = {"#{CZRW_130822_47}",
																		 "#{CZRW_130822_52}",
																		 "#{CZRW_130822_57}",
																		 "#{CZRW_130822_62}",
																		},

														DingDianYinDao = {"#{CZRW_130822_92}",
																							"#{CZRW_130822_97}",
																							"#{CZRW_130822_102}",
																							"#{CZRW_130822_107}",},

														XunWu = {"#{CZRW_130822_70}",
																		 "#{CZRW_130822_75}",
																		 "#{CZRW_130822_80}",
																		 "#{CZRW_130822_85}",},

														BuZhuo = {"#{CZRW_130822_117}",
																			"#{CZRW_130822_121}",
																			"#{CZRW_130822_126}",
																			"#{CZRW_130822_131}",}, }

--  界面预加载...
function QuestLog_PreLoad()
    this:RegisterEvent("TOGLE_MISSION",true);
    this:RegisterEvent("UPDATE_MISSION",false);
    this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
    this:RegisterEvent("UPDATE_DOUBLE_EXP",true);
    this:RegisterEvent("UPDATE_QUESTTIME",false);
    this:RegisterEvent("NEW_MISSION",false);
    this:RegisterEvent("DELETE_MISSION",false);
    this:RegisterEvent("TOGLE_MISSION_OUTLINE",true);
    this:RegisterEvent("UI_COMMAND",true)
    this:RegisterEvent("OPEN_FROM_MISSIONTRACK",true);
    this:RegisterEvent("UPDATE_QUESTLOG_BY_TRACK",false);
    this:RegisterEvent("UPDATE_TRACK_STATE_BUTTON",false);

    -- 游戏窗口尺寸发生了变化
    this:RegisterEvent("ADJEST_UI_POS",false)

    -- 游戏分辨率发生了变化
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--界面互斥
	this:RegisterEvent("ONOPENBIEYEFURCREATE")
end

--  界面首次加载初始化, 所有任务类型折叠标志为展开, 记录界面的初始位置
function QuestLog_OnLoad()

    local i=1;
    for i=1,200 do
        MissionPucker[i] = 1;
    end;

    for i=1,200 do
        MissionOutlineDeploy[ i ] = 1  --任务索引默认都为展开
    end

    First_Open = 1;
    CurList = 1

    -- 保存界面的默认相对位置
    g_QuestLog_Frame_UnifiedXPosition    = QuestLog_Frame : GetProperty("UnifiedXPosition");
    g_QuestLog_Frame_UnifiedYPosition    = QuestLog_Frame : GetProperty("UnifiedYPosition");

end

--  界面事件处理
--  因为同一时刻只会有一个事件, 因此不用处理多个if的情况
function QuestLog_OnEvent(event)
--    if(this:IsVisible()) then
--        QuestLog_OnShown();
--        return;
--    end

	g_MenPai_Special_id = 0

    if(event == "UI_COMMAND" and tonumber(arg0) == 831020) then
        QuestLog_UpdateListbox();
        QuestLog_UpdateMissionOutline();
        QuestLog_ShowWindow();
    elseif(event == "TOGLE_MISSION" or (event == "UI_COMMAND" and tonumber(arg0) == 110921)) then
		if tonumber(arg0) == 110921 then
			g_MenPai_Special_id = 1
		end

        QuestLog_UpdateListbox();
        QuestLog_ShowWindow();
    elseif(event == "TOGLE_MISSION_OUTLINE" ) then
        QuestLog_UpdateMissionOutline();
        QuestLog_ShowWindow();
    elseif(event == "UPDATE_MISSION" ) then
        if not this:IsVisible() then
            return;
        end
        if (CurList == 1) then
            QuestLog_UpdateListbox();
        end
    elseif(event == "PACKAGE_ITEM_CHANGED_EX") then
        if CurList == 1 then
            QuestLog_UpdateListbox();
        end
    elseif(event == "UPDATE_DOUBLE_EXP" ) then
        local DT = SystemSetup : GetDoubleExp("remaintime");
        QuestLog_Watch:SetProperty("Timer",DT);
    elseif(event == "UPDATE_QUESTTIME") then
        if not this:IsVisible() then
            return;
        end

        if( 2 == CurList ) then
            return    --这个消息是用来更新任务计时的,当当前选中项为任务索引时,则不应该进行更新.
        end

        if arg0 ~= nil and tonumber(arg0) <= 20 and tonumber(arg0) >= 0 then
            if tonumber(arg0) == Current_Select then
                QuestLog_ListBox_SelectChanged()
            end
        end
    elseif(event == "NEW_MISSION" ) then
        Current_Select = tonumber(arg0)
        if not this:IsVisible() then
            return;
        else
            QuestLog_UpdateListbox();
        end
    elseif(event == "DELETE_MISSION") then
        if Current_Select == tonumber(arg0) then
            DataPool:GetPlayerMission_DelActivePos(Current_Select);
	    CloseFreshManGuide()
            return;
        end
    elseif (event == "OPEN_FROM_MISSIONTRACK") then
        Current_Select = tonumber(arg0)
        if not this:IsVisible() then
            First_Open = 0;

            --全部展开
            for i=1,200 do
                MissionPucker[i] = 1;
            end;

            QuestLog_UpdateListbox();
            QuestLog_ShowWindow();
        else
            --QuestLog_UpdateListbox();
            this:Hide();
        end
    elseif (event == "UPDATE_QUESTLOG_BY_TRACK") then
        if this:IsVisible() then
            QuestLog_UpdateListbox();
        end
    elseif (event == "UPDATE_TRACK_STATE_BUTTON") then
        local nType = tonumber(arg0);
        if not this:IsVisible() then
            return;
        end

        if (nType == 0) then  -- MissionTrack State Changed
            if (DataPool:IsTrackFuncShow(1) > 0) then
                QuestLog_Mode1:SetCheck(1);
            else
                QuestLog_Mode1:SetCheck(0);
            end
        elseif (nType == 1) then  -- CampaignTrack StateChanged
            if (DataPool:IsTrackFuncShow(2) > 0) then
                QuestLog_Mode2:SetCheck(1);
            else
                QuestLog_Mode2:SetCheck(0);
            end
        end
    -- 游戏窗口尺寸发生了变化
    elseif (event == "ADJEST_UI_POS" ) then
        -- 更新背包界面位置
        QuestLog_Frame_On_ResetPos()

    -- 游戏分辨率发生了变化
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        -- 更新背包界面位置
        QuestLog_Frame_On_ResetPos()
	elseif (event == "ONOPENBIEYEFURCREATE" and this:IsVisible()) then
		this:Hide()
    end
end

function QuestLog_OnShown()
	QuestLog_FreshManGuideOnShown(1)
end

--2011Q3新手任务ui指引
--
--
function QuestLog_FreshManGuideOnShown(nType)
    if 1 ~= CurList then   --不是可接任务列表不管
        return
    end

    local nLevel = Player:GetData("LEVEL")
    if nLevel == nil or nLevel > 10 then
        return
    end
    local nSelIndex = QuestLog_Listbox:GetFirstSelectItem()
    if nSelIndex < 0 then
        return
    end
    local nScriptId = DataPool:GetPlayerMission_Display(nSelIndex, 7)
    if nScriptId ~= 210262 and   --初涉江湖
        nScriptId ~= 210255 and  --第一把武器
        nScriptId ~= 210256 and
		nScriptId ~= 890252 then --第一件防具
        return
    end
    if nScriptId == 210255 then
	local fX, fY = this:GetChildOffset("QuestLog_Desc")
	local fPosX = tonumber(QuestLog_Frame:GetProperty("AbsoluteXPosition"))
	local fPosY = tonumber(QuestLog_Frame:GetProperty("AbsoluteYPosition"))
	local fW = tonumber(QuestLog_Desc:GetProperty("AbsoluteWidth"))
	local fH = tonumber(QuestLog_Desc:GetProperty("AbsoluteHeight"))
	fX = math.floor(fX + fPosX + (0.5 * fW) + 20)
	fY = fY + fPosY + 35
	--OpenFreshManGuide(1, 1, fX, fY, "QuestLog", "northeast")
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 2, 1, "QuestLog")
    end

	if nScriptId == 890252 then
	local fX, fY = this:GetChildOffset("QuestLog_Desc")
	local fPosX = tonumber(QuestLog_Frame:GetProperty("AbsoluteXPosition"))
	local fPosY = tonumber(QuestLog_Frame:GetProperty("AbsoluteYPosition"))
	local fW = tonumber(QuestLog_Desc:GetProperty("AbsoluteWidth"))
	local fH = tonumber(QuestLog_Desc:GetProperty("AbsoluteHeight"))
	fX = math.floor(fX + fPosX + (0.5 * fW) + 20)
	fY = fY + fPosY + 35
	--OpenFreshManGuide(1, 1, fX, fY, "QuestLog", "northeast")
	if(SystemSetup:IsClassic() == 0) then  --尼玛，唯美字体改了导致位置变了
		fX = fX+ 30
	end
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 2, 1, "QuestLog")

	SetTimer("QuestLog", "QuestLog_ShowFreshManGuide()", 3000)
    end
end
function QuestLog_OnMoved()
    if "QuestLog" == GetFreshManGuideOwner() then
	QuestLog_FreshManGuideOnShown(2)
        --OpenFreshManGuide(2, -1, -1, -1) --当本界面show并且引导ui指向本界面,才需要响应
    end
end
function QuestLog_OnHidden()
    if "QuestLog" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
    end
end

function QuestLog_ShowFreshManGuide()

	 KillTimer("QuestLog_ShowFreshManGuide()")
	 if "QuestLog" == GetFreshManGuideOwner() then
		QuestLog_ShowFreshManClose()
	 end
end

function QuestLog_ShowFreshManClose()
	local fX = 0
	local fY = 0
	local nPosX = tonumber(QuestLog_Frame:GetProperty("AbsoluteXPosition"))
	local nPosY = tonumber(QuestLog_Frame:GetProperty("AbsoluteYPosition"))
	fX, fY = this:GetChildOffset("QuestLog_Close")
	local fH = tonumber(QuestLog_Close:GetProperty("AbsoluteHeight"))
	local fW = tonumber(QuestLog_Close:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + nPosX + fW) - 107)
	if(SystemSetup:IsClassic() == 0) then
		fX = fX+ -10
	end
	fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)+45))
	OpenFreshManGuideNew(1, fX, fY, fW, fH, 1, 3, "QuestLog")
	--DataPool:SetCurrentFreshManGuideItemValue(12)
end
--  活动日程按钮点击回调
function QuestLog_HitRiCheng()
	
	if IsTBFinalServer() >= 1 then
		--总决赛特殊服务器不允许进行该操作
		PushDebugMessage("#{BHKF_150323_61}")
		return
	end	
    OpenTodayCampaignList();
end

--  更新可接任务类型
--  采取短路写法, 尽快返回, 减少缩进
function QuestLog_UpdateMissionType( iMissionType )
    local strOutlineName = ""
    --  构造任务类型名称和显示颜色
    if( 1 == MissionOutlineDeploy[ iMissionType ] ) then
        strOutlineName = "#gFE7E82- " .. DataPool:GetMissionInfo_Kind( iMissionType )
    else
        strOutlineName = "#gFE7E82+ " .. DataPool:GetMissionInfo_Kind( iMissionType )
    end

    --  这句判断永远通过, 而且 不应该是 or 而应该是 and
    --if( strOutlineName ~= "" or strOutlineName ~= 0 ) then
    --  如果是无效的任务名称
    if( strOutlineName == "" or strOutlineName == 0 ) then
        return;
    end

    local iStart = iMissionType*10000;
    local DeployNum = GetMissionOutlineNum( iMissionType )

    --  如果当前任务分类没有可接任务
    if( DeployNum <= 0 ) then
        return;
    end

    --  增加该任务分类的名称显示
    QuestLog_Listbox:AddItem( strOutlineName, iStart )
    --  该任务分类不是展开的
    if( 1 ~= MissionOutlineDeploy[ iMissionType ] ) then
        return;
    end

    --  增加该分类下可接的任务名称和其对应颜色配置
    local nMyLevel = Player:GetData( "LEVEL" )
	local isCompatPKServer = Player:GetData("IsPKServer_JD")
	local nCompatPKLevel = Player:GetData( "LEVEL_CompatPKLV" )
	if isCompatPKServer == 1 and nCompatPKLevel < nMyLevel then
		nMyLevel = nCompatPKLevel
	end
    for i=1, DeployNum do
        local color= ""
        local MissionLevel, MinLevel, MaxLevel, strNpcName, strNpcPos, strScene, strMissionName = GetMissionOutlineInfo( iMissionType, i )
		if SystemSetup:IsClassic() == 1 then
			if( MissionLevel - nMyLevel < -11 ) then
				color = "FFB9B9B9";		--灰色
			elseif( MissionLevel - nMyLevel <=-6 ) then
				color = "FF0A9605";		--绿色
			elseif( MissionLevel - nMyLevel <= 5 ) then
				color = "FFD9F80A";		--黄色
			elseif( MissionLevel - nMyLevel <= 10 ) then
				color = "FFF8A10A";		--橙色
			else
				color = "FFFA0A0A";		--红色
			end
		else
			if( MissionLevel - nMyLevel < -11 ) then
				color = "FF545050";		--灰色
			elseif( MissionLevel - nMyLevel <=-6 ) then
				color = "FF04721E";		--绿色
			elseif( MissionLevel - nMyLevel <= 5 ) then
				color = "FFD9F80A";		--黄色
			elseif( MissionLevel - nMyLevel <= 10 ) then
				color = "FF7A3409";		--橙色
			else
				color = "FFFA0A0A";		--红色
			end
		end

        QuestLog_Listbox:AddItem( "    "..MissionLevel.." "..strMissionName, (iStart+i), color )
    end
end

--  更新可接任务列表
--  这部分跟重构后的MissionTrack一样... 因此不再做变更了
function QuestLog_UpdateMissionOutline()

    --  从已接任务列表切换到可接任务列表
    if( 1 == CurList ) then
        CurList = 2
        QuestLog_AcceptMission:SetCheck(1);
        QuestLog_Stop:Hide()
        QuestLog_AcceptMission_Button:Hide()
        QuestLog_TargetMission : SetText( "" );
    end

    --  记录当前列表显示位置
    local FirstItem = QuestLog_Listbox : GetCurrentFirstItem();


    --  获取所有可接任务, 清除当前列表显示内容
    CollectMissionOutline()
    QuestLog_Listbox:ClearListBox()
    QuestLog_Desc:ClearAllElement();

	local nXiaKe = Player:GetData("IsXiaKe") --2025侠客行引导任务
    --  分类更新200中任务...
    for i=1,200 do             --现任务类型一共200种
		if(i == 153 and nXiaKe ~= 1) then      --2025侠客行引导任务
            continue;
        end		
        QuestLog_UpdateMissionType( i )
    end

    --QuestLog_Listbox : EnsureItemIsVisable( Current_Clicked );
    QuestLog_Listbox : SetCurrentFirstItem( FirstItem );
    QuestLog_TrackButtonState();


end

--  点击可接任务条目
function QuestLog_MissionOutlineClicked()
    local nSelIndex = QuestLog_Listbox:GetFirstSelectItem();

    local iMod = math.mod( nSelIndex, 10000 )
    local iFloor = math.floor( nSelIndex / 10000 );

    --  根据点击选项的id值判断该项目是 任务类型(iMod==0) 还是具体任务(iMod!=0)
    if( 0 == iMod ) then
        --  反转该类型的折叠属性
        if( 0 == MissionOutlineDeploy[ iFloor ] ) then
            MissionOutlineDeploy[ iFloor ] = 1
        else
            MissionOutlineDeploy[ iFloor ] = 0
        end

        --  更新列表显示
        QuestLog_UpdateMissionOutline()
        QuestLog_Desc:ClearAllElement();
        return
        --QuestLog_Listbox:SetItemSelectByItemID( nSelIndex )
    end

    --  如果是具体任务, 在任务描述区显示其描述信息
    QuestLog_Desc:ClearAllElement();
    local MissionLevel, MinLevel, MaxLevel, strNpcName, strNpcPos, strScene, strMissionName, PosX, PosY, SceneID = GetMissionOutlineInfo( iFloor, iMod )
    QuestLog_Desc:AddTextElement("#Y"..strMissionName.."#W")

    strNpcPos = "#{_INFOAIM"..(PosX)..","..(PosY)..","..(SceneID)..","..(strNpcName).."}"
    --strNpcPos = "[["..(PosX)..","..(PosY)..","..(SceneID)..","..(strNpcName).."]]"
    --strNpcPos = "（"..PosX.."，"..PosY.."）"

    if strScene and strScene ~= "" then
            QuestLog_Desc:AddTextElement("任务所在地："..strScene.."  "..strNpcPos )
    end
    QuestLog_Desc:AddTextElement("任务发布人："..strNpcName )
    QuestLog_Desc:AddTextElement("任务等级："..tostring(MissionLevel) )
end

--  更新已接任务列表的指定分类
--  以短路写法重构, 减少缩进
function QuestLog_UpdateHaveGetMission( kind, kindTbl )
    --  单条任务记录
    local Constitutes = {};
    --  玩家当前等级
    local nMyLevel = Player:GetData( "LEVEL" );
    --  是否有该分类的任务
    local bHave = 0;

    --  遍历所有已接任务
    for i=1, g_nMissionNum do
        --  当前位置为无效任务
        if (DataPool:GetPlayerMission_InUse(i-1) ~= 1) then
            continue;
        end

        --  非当前类型的任务
        local MissionKind = DataPool:GetPlayerMission_Kind(i-1);
        if(MissionKind ~= kind) then
            continue;
        end

        --  当前任务类型是非折叠的
        if ( MissionPucker[kind] > 0 ) then
            --  获得任务 g_MissionTarget 字段
            local strInfo = DataPool:GetPlayerMission_Memo(i-1);
            --  获得任务 g_MissionLevel 字段
            local nMissionLevel = DataPool:GetPlayerMission_Level(i-1);

            --  如果任务等级是玩家等级, 将任务等级设置为玩家等级
            --  这里没有向MissionTrack中对擂台的 0 等级做特殊处理
            if nMissionLevel == LEVEL_TO_MY_LEVEL then
                nMissionLevel =  Player:GetData( "LEVEL" );
            end

            --  如果首次有该分类任务, 增加该分类的条目记录
            if(bHave == 0) then
                local str= "#gFE7E82- " .. DataPool:GetMissionInfo_Kind(kind);
                Constitutes = {str,100+kind,"",0}
                table.insert(kindTbl,Constitutes)
                bHave = 1;

                --  for debug only
                local xx;
                for i,xx in ipairs(Constitutes) do

                end
            end

            --------------------------------------------------
            local strOKFail = "";
            --显示任务是否已完成或已失败
            local Mission_Variable = DataPool:GetPlayerMission_Variable(i-1,0);

            if QuestLog_IsSpecialMission(i-1) == 1 then
                Mission_Variable = IsMissionSuccess(i-1)
            end

            if(Mission_Variable >0) then
                if(Mission_Variable == 1) then
                    strOKFail = "完成";
                elseif(Mission_Variable == 2) then
					--战备任务特写
					local TempScriptId = DataPool:GetPlayerMission_Display(i-1,7)
					if(TempScriptId ==  891456 or TempScriptId ==  891457 or TempScriptId ==  891458 or TempScriptId ==  891459 or TempScriptId ==  891460 or TempScriptId ==  891461) then
						strOKFail = "失败";--任务已经失败，请放弃
					else
						strOKFail = "失败";
					end
                end
            end

            ----------------------------------------------------
			if SystemSetup:IsClassic() == 1 then
				if(nMissionLevel - nMyLevel < -11) then
					color = "FFB9B9B9"; 	--灰色
				elseif(nMissionLevel - nMyLevel <=-6) then
					color = "FF0A9605";    	--绿色
				elseif(nMissionLevel - nMyLevel <= 5) then
					color = "FFD9F80A";    	--黄色
				elseif(nMissionLevel - nMyLevel <= 10) then
					color = "FFF8A10A";    	--橙色
				else
					color = "FFFA0A0A"; 	--红色
				end
			else
				if(nMissionLevel - nMyLevel < -11) then
					color = "FF545050"; 	--灰色
				elseif(nMissionLevel - nMyLevel <=-6) then
					color = "FF04721E";    	--绿色
				elseif(nMissionLevel - nMyLevel <= 5) then
					color = "FFD9F80A";    	--黄色
				elseif(nMissionLevel - nMyLevel <= 10) then
					color = "FF7A3409";    	--橙色
				else
					color = "FFFA0A0A"; 	--红色
				end
			end
            local nMissionTrackType = DataPool:GetPlayerMissionTrackType(i-1);
            local nIsMissionTrackOpen = DataPool:IsMissionTrackOpen(i-1);
            if (nIsMissionTrackOpen > 0 and nMissionTrackType > 0) then
                Constitutes = {"   √" .. nMissionLevel .." " .. strInfo .. " " .. strOKFail,i-1,color,nMissionLevel}
            else
                Constitutes = {"     " .. nMissionLevel .." " .. strInfo .. " " .. strOKFail,i-1,color,nMissionLevel}
            end
            table.insert(kindTbl,Constitutes)
        else
            --  该任务分类是折叠的, 因此只显示一条任务分类名称
            if(bHave == 0) then
                local str= "#gFE7E82+ " .. DataPool:GetMissionInfo_Kind(kind);

                Constitutes = {str,100+kind,"",0}
                table.insert(kindTbl,Constitutes)

                bHave = 1;
            end

        end
        --  增加已接任务数
        HaveGetMissionNum=HaveGetMissionNum+1;
    end

    --  返回该分类下的任务记录
    return kindTbl;
end

--- 预留
--  用来处理特殊的任务显示
function QuestLog_UpdateListbox()
    QuestLog_UpdateListbox_Ex()
end
--  更新已接任务列表
function QuestLog_UpdateListbox_Ex()

    --  从可接任务列表切换为已接任务列表
    if( 2 == CurList ) then
        CurList = 1
        QuestLog_CurrentMission:SetCheck(1);
        QuestLog_Stop:Show()
        QuestLog_AcceptMission_Button:Hide()
    end

    --  切换按钮状态.
    --  JOY: 可接任务列表更新时为什么没有相关切换
    QuestLog_CurrentMission:SetCheck( 1 )
    QuestLog_AcceptMission:SetCheck( 0 )

--    local nMissionNum = DataPool:GetPlayerMission_Num();
    local i;

    QuestLog_Listbox:ClearListBox();

    HaveGetMissionNum = 0
    local color;

    for i=1,g_nMissionNum do
        if (DataPool:GetPlayerMission_InUse(i-1) == 1) then
            DataPool:GetPlayerMission_Description(i-1);
        end
    end;

    --  已接任务分类总表
    local Sequence_Assemble = {}

    --  变量所有类型的已接任务, 分类排序插入总表
    for j=1, 200 do
        local Sequence_OnefoldGenre = QuestLog_UpdateHaveGetMission( j, {} );
        ----
        table.sort(Sequence_OnefoldGenre,QuestLog_CompareTable)

        for i,n in ipairs(Sequence_OnefoldGenre) do
            table.insert(Sequence_Assemble,n)
        end
        ----
    end

    --  将已接任务数据插入任务列表
    local Per_Segment,xxxx,i,j;
    for i,Per_Segment in ipairs(Sequence_Assemble) do
        if Per_Segment[3] ~= "" then
            QuestLog_Listbox:AddItem(Per_Segment[1],Per_Segment[2],Per_Segment[3])
        else
            QuestLog_Listbox:AddItem(Per_Segment[1],Per_Segment[2])
        end
    end

    --  如果没有任务, 则任务列表显示相关提示
    if First_Open == 1 then  --首次打开，选中最后一个
        First_Open = 0
        Current_Select = HaveGetMissionNum - 1
    end

    --  设置原本的任务选择项
	if g_MenPai_Special_id == 1 then
		QuestLog_Listbox : SetItemSelectByItemID(HaveGetMissionNum-1);
	else
		QuestLog_Listbox : SetItemSelectByItemID(Current_Select);
	end

	--任务数
    local currMissionNum = tostring( HaveGetMissionNum )
    QuestLog_Amount : SetText( currMissionNum .. "/" .. g_nMissionNum);

	if g_MenPai_Special_id == 1 then
		QuestLog_Listbox : SetCurrentFirstItem(HaveGetMissionNum-1);
	end
    QuestLog_ListBox_SelectChanged();

    --  更新当前的显示位置
    if Current_Clicked ~= -1 then
        --QuestLog_Listbox : EnsureItemIsVisable(Current_Clicked);
        QuestLog_Listbox : SetCurrentFirstItem(Current_Clicked);
        Current_Clicked = -1
    end
    QuestLog_TrackButtonState();
--
end

--  插入任务类型, 废弃
--function MissionType_Insert(str)
--排序算法在上面已经实现了，理论上讲这个不会被调用到。chris
--        for i=1,table.getn(MissionType) do
--        for i,Per_Segment in ipairs(MissionType) do
--            if(MissionType[i] == str) then
--                return;
--            elseif( MissionType[i] > str ) then
--                    table.insert(MissionType,i,str);

--                    return;
--            end
--        end
--        table.insert(MissionType,str);
--        return;
--end

--  变换当前任务选择
--  本身就是使用短路写法, 不用重构, 仅重新调整缩进增加注释
function QuestLog_ListBox_SelectChanged()

    -- 如果当前显示为可接任务, 转向可接任务处理
    if( 2 == CurList ) then
        QuestLog_MissionOutlineClicked()
        return
    end

    --  开始当前选择任务的数据更新
    local MissionParam_Index = 0;
    local nSelIndex = QuestLog_Listbox:GetFirstSelectItem();
	local Mission_Variable;
    --  如果没有接任何任务... Nothing
    if(HaveGetMissionNum<1) then
        QuestLog_Desc:ClearAllElement();
        QuestLog_TargetMission : SetText("");
        return;
    end

    --  如果任务列表记录的当前任务无效, 并且界面本身也没有记录当前选择任务.. Nothing
    if nSelIndex == -1 then
        if Current_Select == -1 then
            QuestLog_Desc:ClearAllElement();
            QuestLog_TargetMission : SetText("");
            return;
        else
            --  将当前选择任务置为界面记录的任务
            nSelIndex = Current_Select;
        end
    end

    --  如果当前点击项目为分类名称项
    if nSelIndex > 20 then
        --  切换其折叠状态, 并更新显示
        if MissionPucker[nSelIndex-100] == 1 then
            MissionPucker[nSelIndex-100] = 0;
        else
            MissionPucker[nSelIndex-100] = 1;
        end
		g_QuestLog_ListID = nSelIndex;
        Current_Clicked = QuestLog_Listbox : GetCurrentFirstItem();
        QuestLog_UpdateListbox();

        return;
    end;

    --  如果当前选中项为无效的任务记录, Nothing
    if (DataPool:GetPlayerMission_InUse(nSelIndex) ~= 1) then
        QuestLog_Desc:ClearAllElement();
        QuestLog_TargetMission : SetText("");
        return;
    end

    --  清除任务描述
    QuestLog_Desc:ClearAllElement();
    QuestLog_TargetMission : SetText("");

    --  获得任务描述
    local desc = DataPool:GetPlayerMission_Description(nSelIndex)
    DataPool:GetPlayerMission_DelActivePos(Current_Select)
    Current_Select = nSelIndex;

    local strInfo,strDesc = DataPool:GetPlayerMission_Memo(nSelIndex);
    local i = 0
    local m = 0
    local nBegin = DataPool:GetPlayerMission_ForePart(nSelIndex);


    local strReplace = ""
    local strOriginal = ""

    --  合并任务的多条描述为1条
    while 1 do
        i = string.find(strDesc,"%%s")
        if i == nil then break end
        local strIndex =  DataPool:GetPlayerMission_VariableByByte(nSelIndex,nBegin,m)
        local strTemp = DataPool : GetPlayerMission_StrList(strIndex)

--        string.format(strDesc,strTemp)

        strReplace = strReplace .. string.sub(strDesc,1,i-1) .. strTemp


        strDesc = string.sub(strDesc,i+2)
        m = m + 1;

    end

	-- 帮会交互设计
	local nScriptId = DataPool : GetPlayerMission_Display( nSelIndex, 7 );
	-- if ( nScriptId == 610013 or nScriptId == 610014 ) then
	-- 	local text = QuestLog_GuildInteractiveMission( nSelIndex );
	-- 	--QuestLog_Desc : AddTextElement( ""..text );
	-- 	strDesc =  ""..text;
	-- end
	
	if ( nScriptId == 506100 ) then
		local taskDesc = QuestLog_BountyTaskDesc( nSelIndex )
		if taskDesc~=nil then
			strDesc =  ""..taskDesc
		end
	end
    --  显示任务描述
    strReplace = strReplace .. strDesc
    strDesc = strReplace
	if(SystemSetup:IsClassic() == 1) then
		QuestLog_TargetMission : SetText("#gFF0FA0" ..strInfo);
	else
		QuestLog_TargetMission : SetText("#gFF0FA0" ..strInfo);
	end
    QuestLog_Desc:AddTextElement("#Y任务目标：#W")
    QuestLog_Desc:AddTextElement("" .. strDesc);

	--城战战备任务特写
	local TempScriptId = DataPool:GetPlayerMission_Display(nSelIndex,7)
	if(TempScriptId ==  891456 or TempScriptId ==  891457 or TempScriptId ==  891458 or TempScriptId ==  891459 or TempScriptId ==  891460 or TempScriptId ==  891461) then
    	QuestLog_Desc:AddTextElement("" .. QuestLog_GetZhanBeiTarget(nSelIndex));
    end
	--门派进阶任务
	if(TempScriptId == 212150 or TempScriptId == 212146 or TempScriptId == 889484 or TempScriptId == 889513 or TempScriptId == 889478 or TempScriptId == 889507 or
	   TempScriptId == 889496 or TempScriptId == 889555 or TempScriptId == 889519 or TempScriptId == 889490 or TempScriptId == 212153) then
		QuestLog_Desc:AddTextElement("" .. "#{GMMF_160614_26}");
	end
	-- 战备任务之击败守卫
	if ( DataPool:GetPlayerMission_Display( nSelIndex, 7 ) == 891688 ) then
		local text = QuestLog_ZhanBeiMission_JiShaShouWei( nSelIndex );
		QuestLog_Desc:AddTextElement( ""..text );
	end

    --  特殊处理
    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 500510) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetSCMTarget(nSelIndex));
    end

    --生育系统成长任务特写
    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 890500 ) then
    	QuestLog_Desc:AddTextElement("" .. QuestLog_GetInfantTarget(nSelIndex));
    end

    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 889265) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetHLXQJTarget(nSelIndex));
    end

    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 890714) then
	QuestLog_Desc:AddTextElement("" .. QuestLog_GetJFTXTarget(nSelIndex))
    end

    --Q4打卡活动
    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 890638) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetXunBaoLeFanTianTarget(nSelIndex));
    end
	--Q3打卡活动
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 890612) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetDAKATarget(nSelIndex));
    end
    -- 子女系统属性培养——作画任务
    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 890512) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetDrawTarget(nSelIndex));
    end
    -- 子女系统属性培养——礼仪任务
    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 890513) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetMannerNPC(nSelIndex));
    end
--    QuestLog_Desc:AddTextElement("" .. strReplace);

	--shitu mission by yuanpeilong 201505
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 891159) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetShiFuTarget(nSelIndex));
    end

	--shitu mission by yuanpeilong 201505
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 891160) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetTuDiTarget(nSelIndex));
    end

	--20150701-七夕交互任务-by yuanpeilong
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 891322) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_Get2015QiXiJiaoHuTarget(nSelIndex));
    end
	
	----20150701-七夕鹊桥任务-by yuanzhiheng
	--if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 891345) and (QuestLog_IsQiXiQueQiaoDate() ~= 1)then
  --      QuestLog_Desc:AddTextElement("#{QXQQ_160613_93}");
  --  end

	-- [2017-元宵节猜灯谜活动]
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 892384) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetTarget_2017YXJCDM(nSelIndex));
    end

	--2022新天外跑环任务链：简单模式
	if((DataPool:GetPlayerMission_Display(nSelIndex,7) == 998267) or (DataPool:GetPlayerMission_Display(nSelIndex,7) == 998346)) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetTarget_2022XTWBDPH_easy(nSelIndex));
    end

	--2022新天外跑环任务链：困难模式
	if((DataPool:GetPlayerMission_Display(nSelIndex,7) == 998268) or (DataPool:GetPlayerMission_Display(nSelIndex,7) == 998347)) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetTarget_2022XTWBDPH_diff(nSelIndex));
    end
	
	--2022Q3新天外预热活动-ypl
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 998179) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetTarget_2022Q3NTWYR(nSelIndex));
    end
	
	--新暗器引导任务
	-- if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 891829) then
        -- QuestLog_Desc:AddTextElement("" .. QuestLog_NewDark_Target(nSelIndex));
    -- end	
	
	--十六周年情怀任务
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 998472) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetTarget_2023Anniversay(nSelIndex));
    end
   
  --2023Q3宗门日常任务
	if nScriptId == 998613 or nScriptId == 998614 or nScriptId == 998615 or nScriptId == 998616 or nScriptId == 998617 
			or nScriptId == 998618 or nScriptId == 998619 or nScriptId == 998621 or nScriptId == 998622 or nScriptId == 998623
			or nScriptId == 998624 or nScriptId == 998625 or nScriptId == 998626 or nScriptId == 998627 or nScriptId == 998607 then
		QuestLog_Desc:AddTextElement("" .. QuestLog_GetTarget_RiChangMission(nSelIndex))
	end
	
	--宗门预热活动
	if nScriptId == 998839 then
		QuestLog_Desc:AddTextElement("" .. QuestLog_GetTarget_ZongMenYuRe(nSelIndex))
	end
	
	if(nScriptId == 891176) or
		(nScriptId == 891177) or
		(nScriptId == 891178) or
		(nScriptId == 891179) then
		QuestLog_Desc:AddTextElement("" .. QuestLog_GetZhenFaTarget(nSelIndex,nScriptId));
	end
    DataPool:GetPlayerMission_ActivePos(nSelIndex);

    --显示是否双倍时间
    local nDoubleExp = DataPool:GetPlayerMission_Display(nSelIndex,6)

    local DoubleExp_Text = "";
    if nDoubleExp > 0 then
        local IsDouble = DataPool:GetPlayerMission_DataRound(nDoubleExp);

        if IsDouble > 0 then
            DoubleExp_Text = "#B多倍奖励"
            QuestLog_Desc:AddTextElement(DoubleExp_Text);
        end
    end


    --前面是否有一位显示任务是否已完成,第一位为完成信息
    if QuestLog_IsSpecialMission(nSelIndex)==0 then
        MissionParam_Index = MissionParam_Index + 1;
    end

--        for i =0,7 do

--        end

    --显示任务剩余时间
    local nTotalTime = DataPool:GetPlayerMission_Display(nSelIndex,2);

    if( nTotalTime > 0 ) then
        --73637【天龙服务器组】QuestLog中剩余时间定时器逻辑
        local nRemainTime = DataPool:GetPlayerMission_RemainTime(nSelIndex);

        --不好意思，加点注释，怕以后忘了，当然您如果一看就明白，那就跳过
        --73637的改造是为了避免服务端每次响应任务ontimer时都向客户端发包，以告知倒计时的变化
        --改造以后，任务7号参数不存倒计时时间，存任务启动timer或者说是接受任务的时间
        --服务端在接受任务、切场景、登录，都会下发此时间值，客户端根据这个自己tick倒计时
        --GetPlayerMission_RemainTime获取的就是7号参数，GetPlayerMission_RemainTimeEx是客户端自己算的，也是改造后界面显示真正使用的
        --而nTotalTime是限时时间，所以下面这个判断其实是比较取巧的
        if(nRemainTime == 0 or nRemainTime > nTotalTime ) then
            nRemainTime = nTotalTime - DataPool:GetPlayerMission_RemainTimeEx(nSelIndex);
        end
        if(nTotalTime >0) then
--          QuestLog_Desc:AddTextElement(" ");
            local strRemainTime,strTotalTime,nSecond,nMinute,nHour; --Dengxx

            if(nTotalTime >= 60000*60) then
                nHour = math.floor(nTotalTime/60000/60)
                nMinute = math.floor((math.mod(nTotalTime,60000*60))/60000)
                nSecond = math.floor((math.mod(nTotalTime,60000))/1000)
                strTotalTime = nHour .. "小时"..nMinute.."分"..nSecond.."秒"
            elseif(nTotalTime >= 60000) then
                nMinute = nTotalTime/60000;
                strTotalTime = nMinute .. "分"
                nSecond = (nTotalTime - nMinute * 60000)/1000;
                strTotalTime = strTotalTime .. nSecond .."秒"
            elseif(nTotalTime >= 1000) then
                strTotalTime = nTotalTime/1000 .."秒"
            end

            if(nRemainTime >= 60000*60) then
                nHour = math.floor(nRemainTime/60000/60)
                nMinute = math.floor((math.mod(nRemainTime,60000*60))/60000)
                nSecond = math.floor((math.mod(nRemainTime,60000))/1000)
                strRemainTime = nHour .. "小时"..nMinute.."分"..nSecond.."秒"
            elseif(nRemainTime >= 60000) then
                nMinute = math.floor(nRemainTime/60000);
                strRemainTime = nMinute .. "分"
                nSecond = math.floor((nRemainTime - nMinute * 60000)/1000);
                strRemainTime = strRemainTime .. nSecond .."秒"
            elseif(nRemainTime >= 1000) then
                strRemainTime = math.floor(nRemainTime/1000) .."秒"
            else
                strRemainTime = "0秒"
            end

--          QuestLog_Desc:AddTextElement("剩余时间： " .. strRemainTime .."/".. strTotalTime);
            local remainTimeColor = "#c00ff00"
            if (nRemainTime <= 5*60000) then
                remainTimeColor = "#cff0000"
            end
			if DataPool:GetPlayerMission_Display(nSelIndex,7)==808141 and (DataPool:GetPlayerMission_Variable(nSelIndex,0)==1 or DataPool:GetPlayerMission_Variable(nSelIndex,0)==2) then
				strRemainTime = "0秒"
			end
            QuestLog_Desc:AddTextElement("#Y剩余时间： " .. remainTimeColor .. strRemainTime );
            --QuestLog_TargetMission : SetText("#cFF0FA0" ..strInfo .. "  #cff0000[剩余:" .. strRemainTime .. "]");

        end
    end

	--上面那个不能通用，因为是固定时间
	--战备任务特写
	local TempScriptId1 = DataPool:GetPlayerMission_Display(nSelIndex,7)
	local TempHaveDone = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	if TempHaveDone ~= 1 and (TempScriptId1 ==  891456 or TempScriptId1 ==  891457 or TempScriptId1 ==  891458 or TempScriptId1 ==  891459 or TempScriptId1 ==  891460 or TempScriptId1 ==  891461 or TempScriptId1 == 891688) then
		local nLeftTime = DataPool:GetPlayerMission_Variable( nSelIndex, 7 ) --剩余时间
		if nLeftTime >= 0 then
			local strLeftTime = ""

            if(nLeftTime >= 60000) then
                local nMinute = math.floor(nLeftTime/60000);
                strLeftTime = nMinute .. "分"
                local nSecond = math.floor((nLeftTime - nMinute * 60000)/1000);
                strLeftTime = strLeftTime .. nSecond .."秒"
            elseif(nLeftTime >= 1000) then
                strLeftTime = math.floor(nLeftTime/1000) .."秒"
            else
                strLeftTime = "0秒"
            end

			local LeftTimeColor = "#c00ff00"
            if (nLeftTime <= 5*60000) then
                LeftTimeColor = "#cff0000"
            end

            QuestLog_Desc:AddTextElement("#Y任务失败倒计时：" .. LeftTimeColor .. strLeftTime );
		end

		local Mission_Variable = DataPool:GetPlayerMission_Variable(nSelIndex, 0);
		if Mission_Variable == 2 then
			QuestLog_Desc:AddTextElement("#cff0000任务已经失败，请放弃。#W");
		elseif Mission_Variable == 1 then
			QuestLog_Desc:AddTextElement("#G任务已经完成。#W");
		end
	end


    --显示任务当前环数，misInfo的第三号参数为环数，通过mission data显示
    --yanghui，设置标志，通过mission data显示环数还是mission param显示环数
    local bShowByMD = 0;
    local nRound = DataPool:GetPlayerMission_Display(nSelIndex,3);
    if( nRound >= 0 ) then
        Mission_Variable = DataPool:GetPlayerMission_DataRound(nRound);

        if(Mission_Variable >= 0) then
            QuestLog_Desc:AddTextElement("#r#Y任务当前环数：#W"..Mission_Variable);
            bShowByMD = 1;
        end
    end

    --TT76649，老带新使用mission param增加连续完成天数显示
    if( DataPool:GetPlayerMission_Display(nSelIndex,7) == 210254 ) then --如果任务处理脚本是210254（老带新活动）
        Mission_Variable = DataPool:GetPlayerMission_DataRound(511);--老带新活动的连续天数存储在missiondata的
        																														--MD_HELPNEWBIE_SUBMIT_TIMES_SEQUENCE = 511 --帮助新人任务连续完成天数
        local strseqdays = string.format("#{LDX_100726_05}%d",Mission_Variable)
 				QuestLog_Desc:AddTextElement(strseqdays);
    end


    --显示任务银票数量
    if( DataPool:GetPlayerMission_Display(nSelIndex,4) > 0 ) then
        Mission_Variable = DataPool:GetPlayerMission_Variable(nSelIndex,MissionParam_Index);
        MissionParam_Index = MissionParam_Index + 1;

        if(Mission_Variable >0) then
--            QuestLog_Desc:AddTextElement(" ");
            silverdesc = DataPool:GetPlayerMission_BillName(nSelIndex);
            QuestLog_Desc:AddTextElement(silverdesc .. ":");
            QuestLog_Desc:AddMoneyElement(Mission_Variable);

        end
    end
    QuestLog_Desc:AddTextElement(" ");
    if( DataPool:GetPlayerMission_Display(nSelIndex,5) <= 0 ) then
        QuestLog_Desc:AddTextElement("#Y完成情况：#W")
    end
	
	--【2017九星神器每日任务】
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 892627) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetTarget_9_Start(nSelIndex));
    end	
	
    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 500510) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetSCMComplete(nSelIndex));
    end



	-- [2017-元宵节猜灯谜活动]
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 892384) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_Complete_2017YXJCDM(nSelIndex));
    end

	--2022新天外跑环任务链：简单模式
	if((DataPool:GetPlayerMission_Display(nSelIndex,7) == 998267) or (DataPool:GetPlayerMission_Display(nSelIndex,7) == 998346))  then
        QuestLog_Desc:AddTextElement("" .. QuestLog_Complete_2022XTWBDPH_easy(nSelIndex));
    end

	--2022新天外跑环任务链：困难模式
	if((DataPool:GetPlayerMission_Display(nSelIndex,7) == 998268) or (DataPool:GetPlayerMission_Display(nSelIndex,7) == 998347)) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_Complete_2022XTWBDPH_diff(nSelIndex));
    end

	--2022Q3新天外预热活动-ypl
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 998179) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_Complete_2022Q3NTWYR(nSelIndex));
    end
	
    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 889265) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetHLXQJComplete(nSelIndex));
    end

    --	2014Q1聚福天下任务
    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 890714) then
	QuestLog_Desc:AddTextElement("" .. QuestLog_GetJFTXComplete(nSelIndex))
    end

    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 890500) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetInfantComplete(nSelIndex));
    end

    --fengyundaka
    if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 893602) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_GetFengYunDaKaComplete(nSelIndex));
    end

	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 808141) then
		QuestLog_Desc:AddTextElement("\n#{LADR_091105_40}" .. DataPool : GetPlayerMission_ItemCountNow(40004502));
    end
    
    --2023Q3宗门日常任务
		if nScriptId == 998613 or nScriptId == 998614 or nScriptId == 998615 or nScriptId == 998616 or nScriptId == 998617 
				or nScriptId == 998618 or nScriptId == 998619 or nScriptId == 998621 or nScriptId == 998622 or nScriptId == 998623
				or nScriptId == 998624 or nScriptId == 998625 or nScriptId == 998626 or nScriptId == 998627 or nScriptId == 998607 then
			QuestLog_Desc:AddTextElement("" .. QuestLog_GetComplete_RiChangMission(nSelIndex))
		end
		
		--宗门预热活动
		if nScriptId == 998839 then
			QuestLog_Desc:AddTextElement("" .. QuestLog_GetComplete_ZongMenYuRe(nSelIndex))
		end

	--大话西游第一阶段主线剧情-ypl
	if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 999119) then
        QuestLog_Desc:AddTextElement("" .. QuestLog_Complete_2024DHMission(nSelIndex));
    end
	
    --任务需要杀的npc
    local nDemandKillNum,Kill_Random_Type = DataPool:GetPlayerMissionDemandKill_Num(nSelIndex);
    if( nDemandKillNum > 0 ) then
--        QuestLog_Desc:AddTextElement(" ");
        QuestLog_Desc:AddTextElement("已击败：");
    end

    for i=1, nDemandKillNum do
        --    需要的NPC, 需要的数量
        local nNPCName, nNum = DataPool:GetPlayerMissionDemand_NPC(i-1,Kill_Random_Type,nSelIndex);
        Mission_Variable = DataPool:GetPlayerMission_Variable(nSelIndex,MissionParam_Index,Kill_Random_Type,i-1);
        MissionParam_Index = MissionParam_Index + 1;



        QuestLog_Desc:AddTextElement(nNPCName .. " ： "..Mission_Variable.. " / " .. nNum);

    end

    --任务需要的物品
    local nDemandNum,Item_Random_Type = DataPool:GetPlayerMissionDemand_Num(nSelIndex);
    if( nDemandNum > 0 ) then
--      QuestLog_Desc:AddTextElement(" ");
        if(Item_Random_Type == -100) then
            QuestLog_Desc:AddTextElement("已提交：");
            Item_Random_Type = 0
        else
            QuestLog_Desc:AddTextElement("已得到：");
        end
    end

    for i=1, nDemandNum do
        --    需要的类型，需要物品ID，需要多少个
        local szName,nItemID, nNum = DataPool:GetPlayerMissionDemand_Item(i-1,Item_Random_Type,nSelIndex);
--      Mission_Variable = DataPool:GetPlayerMission_Variable(nSelIndex,MissionParam_Index);
--      MissionParam_Index = MissionParam_Index + 1
        Mission_Variable = DataPool : GetPlayerMission_ItemCountNow(nItemID)
        --71435 “寻找万灵石”任务逻辑的修改
        if nItemID == 20309012 then
            Mission_Variable = Mission_Variable + DataPool : GetPlayerMission_ItemCountNow(20309020)
        end




        if Mission_Variable > nNum then
            Mission_Variable = nNum
        end


--      QuestLog_Desc:AddItemElement(nItemID, nNum, 0);
        local Mission_Variable2 = DataPool:GetPlayerMission_Variable(nSelIndex,0);
        if Mission_Variable2 > 0 then
            Mission_Variable = nNum
        end
        QuestLog_Desc:AddTextElement(szName .. " ： " .. Mission_Variable .. " / " .. nNum);
    end

    -----------------------------------------------------------------------------------
    --任务自定义的物品
    local nCustomNum = DataPool:GetPlayerMissionCustom_Num(nSelIndex);
    if( nCustomNum > 0 ) then
        QuestLog_Desc:AddTextElement(" ");
    end

    for i=1, nCustomNum do
        --    需要的NPC，需要NPC ID，需要多少个
        local strCustom, nNum = DataPool:GetPlayerMissionCustom(i-1);
        Mission_Variable = DataPool:GetPlayerMission_Variable(nSelIndex,MissionParam_Index);
        MissionParam_Index = MissionParam_Index + 1;



        if nNum == 0 then
            QuestLog_Desc:AddTextElement(strCustom);
        else
            QuestLog_Desc:AddTextElement(strCustom .. " ： ".. Mission_Variable .. " / " .. nNum);
        end
    end

    -----------------------------------------------------------------------------------
    --任务自定义的随机物品 zz添加
    local nRandomCustomNum = DataPool:GetPlayerMissionRandomCustom_Num(nSelIndex);
    if( nRandomCustomNum > 0 ) then
            --QuestLog_Desc:AddTextElement(" ");
    end
    for i=1,nRandomCustomNum do
        local strCustom, nNeedNum,nCompleteNum = DataPool:GetPlayerMissionRandomCustom(i-1,nSelIndex);
        if nNeedNum == 0 then
            QuestLog_Desc:AddTextElement(strCustom);
        else
            QuestLog_Desc:AddTextElement(strCustom .. " ： ".. nCompleteNum .. " / " .. nNeedNum);
        end
    end
    
    if ( nScriptId == 506100 ) then
    	strCustom = QuestLog_BountyTaskComp( nSelIndex )
    	QuestLog_Desc:AddTextElement(strCustom)
    end

    ----------------------------------------------------------------------------------
    --  任务奖励说明
    QuestLog_Desc:AddTextElement(" ");
    local nBonusNum = DataPool:GetPlayerMissionBonus_Num();

    if( nBonusNum > 0 ) then
        QuestLog_Desc:AddTextElement("#Y奖励：#W");
    end
    local nRadio = 1;
    local nRand = 1;
	local missionId = DataPool:GetPlayerMission_Display(nSelIndex,8)
	local isJDTS =  Player:GetData("IsOriginalJD")

    for i=1, nBonusNum do
        --奖励的类型，奖励物品ID，奖励多少个
        local strType, nItemID, nNum = DataPool:GetPlayerMissionBonus_Item(i-1);
        if(strType == "money" and nNum > 0 )then
--            QuestLog_Desc:AddTextElement("奖励金钱：");
            --这里有对剧情循环任务的特殊处理
            local nScriptId = DataPool:GetPlayerMission_Display(nSelIndex,7)
            if (nScriptId >= 890000 and nScriptId <= 890005) then
                QuestLog_Desc:AddJiaoZiElement(nNum)
            else
                if (nScriptId >= 1010243 and nScriptId <= 1010250) or
                    (nScriptId >= 1010402 and nScriptId <= 1010409) or
                    (nScriptId >= 1018000 and nScriptId <= 1018033) or
                    (nScriptId >= 1018050 and nScriptId <= 1018084) or
                    (nScriptId >= 1018100 and nScriptId <= 1018155) or
                    (nScriptId >= 1018200 and nScriptId <= 1018235) or
                    (nScriptId >= 1018300 and nScriptId <= 1018311) or
                    (nScriptId >= 1018350 and nScriptId <= 1018352) or
                    (nScriptId >= 1018360 and nScriptId <= 1018367) or
                    (nScriptId >= 1018400 and nScriptId <= 1018455) or
                    (nScriptId >= 1018500 and nScriptId <= 1018504) or
                    (nScriptId >= 1018530 and nScriptId <= 1018541) or
                    (nScriptId >= 1018560 and nScriptId <= 1018566) or
                    (nScriptId >= 1038000 and nScriptId <= 1038040) or
                    (nScriptId >= 1038110 and nScriptId <= 1038114) or
                    (nScriptId >= 1039000 and nScriptId <= 1039011) or
                    (nScriptId >= 1039020 and nScriptId <= 1039024) or
                    (nScriptId >= 1039100 and nScriptId <= 1039104) or
                    (nScriptId >= 1038100 and nScriptId <= 1038104) or
                    (nScriptId >= 1039110 and nScriptId <= 1039126) or
                    (nScriptId >= 1039200 and nScriptId <= 1039211) or
                    (nScriptId >= 1039250 and nScriptId <= 1039259) or
                    (nScriptId >= 1039300 and nScriptId <= 1039312) or
                    (nScriptId >= 1039350 and nScriptId <= 1039357) or
                    (nScriptId >= 1039400 and nScriptId <= 1039412) or
                    (nScriptId >= 1039450 and nScriptId <= 1039462) or
                    (nScriptId >= 1039500 and nScriptId <= 1039511) or
                    (nScriptId >= 1039550 and nScriptId <= 1039554) or
                    (nScriptId >= 1039600 and nScriptId <= 1039612) or
                    (nScriptId >= 1009000 and nScriptId <= 1009027) or
                    (nScriptId >= 1009100 and nScriptId <= 1009103) then

                    -- 使用玩家自己的等级来计算得到的奖励
                    nNum = tonumber(Player:GetData("LEVEL") * 18 -101)
                end

                QuestLog_Desc:AddMoneyElement(nNum);
            end
        elseif(strType == "moneyjz" and nNum > 0) then
            QuestLog_Desc:AddJiaoZiElement(nNum)
        elseif(strType == "item") then
--            QuestLog_Desc:AddTextElement("固定奖励物品：");
            local ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
            QuestLog_Desc:AddActionElement(ActionID, nNum, 0);
        elseif(strType == "itemrand") then
            if (nRand == 1) then
                nRand = 0;
                QuestLog_Desc:AddTextElement("随机奖励物品：");
                local ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
                QuestLog_Desc:AddActionElement(ActionID, nNum, 0);
            end
--          local ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
--          QuestLog_Desc:AddActionElement(ActionID, nNum, 0);
--          QuestLog_Desc:AddItemElement(-1, nNum, 0);
        elseif(strType == "itemradio") then
            bBeingRadio = 1;
            if (nRadio == 1) then
                nRadio = 0;
                QuestLog_Desc:AddTextElement("在下列物品中选择一项作为奖励");
            end
			if isJDTS ~= 1 or DataPool:Lua_CheckJDTSMissionForbiddenItem(missionId,nItemID) ~= 1   
			then
            	local ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);

            	QuestLog_Desc:AddActionElement(ActionID,nNum, 0 ,0);
--           	 QuestLog_Desc:AddItemElement(nItemID, nNum, 1 ,1);
			end
        end
    end

    --------------------------------------------------------------------------------
    --2009圣诞日常活动的特殊处理
    --Add by Jiang Yin
    --------------------------------------------------------------------------------
    local nScriptId = DataPool:GetPlayerMission_Display(nSelIndex, 7)
    if nScriptId == 808200 then
        local strIndex = DataPool:GetPlayerMission_Variable(nSelIndex, 1)
        local strTemp = DataPool:GetPlayerMission_StrList(strIndex)
        local pos = string.find(strTemp, "%%s")
        if pos ~= nil then
            strTemp = string.sub(strTemp, 1, pos - 1) .. DataPool:GetPlayerMission_Variable(nSelIndex, 2) .. string.sub(strTemp,  pos + 2)
        end
        QuestLog_Desc:AddTextElement(strTemp)
    end
    
    if ( nScriptId == 506100 ) then
    	strCustom = QuestLog_BountyTaskAward( nSelIndex )
    end
    
    --------------------------------------------------------------------------------
    --2009圣诞日常活动的特殊处理完毕
    --------------------------------------------------------------------------------
    
	
	--新暗器引导任务
	-- if(DataPool:GetPlayerMission_Display(nSelIndex,7) == 891829) then
        -- QuestLog_Desc:AddTextElement("" .. QuestLog_NewDark_Complete(nSelIndex));
    -- end	
	
--	PushDebugMessage("scriptID="..scriptID)
    QuestLog_TrackButtonState();

    if  g_QuestLog_LastSelect ==  nSelIndex then
      QuestLog_Desc:SetScrollPosition()
    else
    	QuestLog_Desc:ResetScrollPosition()
    end
    g_QuestLog_LastSelect = nSelIndex
		
end


function QuestLog_ListBox_RClick()
	if( 1 ~= CurList ) then
        return
    end

	local nSelIndex = QuestLog_Listbox:GetFirstSelectItem();
	local nClickIndex= QuestLog_Listbox : GetClickItem();
	--点击空白处无效
	if nSelIndex == -1 or nClickIndex == -1 then
		return
    end
	--点击伸缩开关无效
	if g_QuestLog_ListID > 100 or nClickIndex > 100 then
		g_QuestLog_ListID = -1
		return
	end

    local nCanTrack = DataPool:GetPlayerMissionTrackType(nSelIndex);
    if (nCanTrack > 0) then
        local nTrackOpen = DataPool:IsMissionTrackOpen(nSelIndex);
        if (nTrackOpen > 0) then
            DataPool:SetMissionTrackOpen(nSelIndex, 0);
        else
            if (DataPool:IsTrackFuncShow(1) == 0) then
                OpenWindow("MissionTrack");
                DataPool:SetTrackFuncShow(1, 1);
            end
            DataPool:SetMissionTrackOpen(nSelIndex, 1);
        end
        QuestLog_UpdateListbox();
        DataPool:UpdateMissionTrack();
	else
		PushDebugMessage("#{RWZZYH_120925_02}")
    end
end

--  放弃任务 按钮点击回调
function Abnegate_Quest()
    if(HaveGetMissionNum<1 or QuestLog_Listbox:GetFirstSelectItem() < 0) then
        return;
    end
    if(Current_Select < 100) then
        DataPool : Mission_Abnegate_Popup( Current_Select, DataPool:GetPlayerMission_Memo(Current_Select));
    end
end

--  已接任务分类排序函数
function QuestLog_CompareTable(table_a,table_b)
    if table_a[4] < table_b[4] then
        return true
    else
        return false
    end
end

--  任务追踪复选框点击回调
function QuestLog_MissionTrack_Clicked()
    local nCheck = QuestLog_Mode1:GetCheck();  --为点击后的状态
    if (nCheck > 0) then
        OpenWindow("MissionTrack");
        DataPool:SetTrackFuncShow(1, 1);
    else
        CloseWindow("MissionTrack");
        DataPool:SetTrackFuncShow(1, 0);
    end
end

--  活动追踪复选框点击回调
function QuestLog_CampaignTrack_Clicked()
    local nCheck = QuestLog_Mode2:GetCheck();  --为点击后的状态
    if (nCheck > 0) then
        OpenWindow("CampaignTrack");
        DataPool:SetTrackFuncShow(2, 1);
    else
        CloseWindow("CampaignTrack");
        DataPool:SetTrackFuncShow(2, 0);
    end
end

--  显示任务列表
function QuestLog_ShowWindow()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
    this:TogleShow();
    local nMissionTrackShow = DataPool:IsTrackFuncShow(1);
    local nCampaignTrackShow = DataPool:IsTrackFuncShow(2);
    if (nMissionTrackShow > 0) then
        QuestLog_Mode1:SetCheck(1);
    else
        QuestLog_Mode1:SetCheck(0);
    end
    if (nCampaignTrackShow > 0) then
        QuestLog_Mode2:SetCheck(1);
    else
        QuestLog_Mode2:SetCheck(0);
    end
    if this:IsVisible() then
	    QuestLog_FreshManGuideOnShown(1)
    else
	    CloseFreshManGuide()
    end
    g_QuestLog_LastSelect=-1
	PushEvent("ON_SHOWQUESTLOGWINDOW")
end

--  更新任务的追踪选项按钮, 设置追踪按钮为 取消追踪/开始追踪
function QuestLog_TrackButtonState()
    if( 1 ~= CurList ) then
        QuestLog_Refuse:SetText("#{INTERFACE_XML_301}");
        QuestLog_Refuse:Enable();
        return
    end

    local nSelIndex = QuestLog_Listbox:GetFirstSelectItem();
    local nCanTrack = DataPool:GetPlayerMissionTrackType(nSelIndex);
    local MissionKind = DataPool:GetPlayerMission_Kind(nSelIndex);
    --关系任务不可追踪
    if (nCanTrack > 0 and MissionKind ~= 10) then
        local nTrackOpen = DataPool:IsMissionTrackOpen(nSelIndex);
        if (nTrackOpen > 0) then
            QuestLog_Refuse:SetText("取消追踪");
        else
            QuestLog_Refuse:SetText("开始追踪");
        end
        QuestLog_Refuse:Enable();
    else
        QuestLog_Refuse:SetText("不可追踪");
        QuestLog_Refuse:Disable();
    end
end

--  开启任务追踪或者取消任务追踪
function QuestLog_TrackCancelOrOpen()
    if( 1 ~= CurList ) then
            --可接任务关闭
            this:Hide();
        return
    end

    local nSelIndex = QuestLog_Listbox:GetFirstSelectItem();
    local nCanTrack = DataPool:GetPlayerMissionTrackType(nSelIndex);
    if (nCanTrack > 0) then
        local nTrackOpen = DataPool:IsMissionTrackOpen(nSelIndex);
        if (nTrackOpen > 0) then
            DataPool:SetMissionTrackOpen(nSelIndex, 0);
        else
            if (DataPool:IsTrackFuncShow(1) == 0) then
                OpenWindow("MissionTrack");
                DataPool:SetTrackFuncShow(1, 1);
            end
            DataPool:SetMissionTrackOpen(nSelIndex, 1);
        end
        QuestLog_UpdateListbox();
        DataPool:UpdateMissionTrack();
    end
end


--TT53675对所有不符合规范，没有将missionparam第0位做为任务完成标志的任务脚本做特殊处理，判断任务是否完成
function IsMissionSuccess(nSelIndex)
    local MissionParam_Index = 0
    local Mission_Variable = 0

    --任务需要杀的npc
    local nDemandKillNum,Kill_Random_Type = DataPool:GetPlayerMissionDemandKill_Num(nSelIndex);
    if( nDemandKillNum > 0 ) then
        for i=1, nDemandKillNum do
            --  需要的NPC, 需要的数量
            local nNPCName, nNum = DataPool:GetPlayerMissionDemand_NPC(i-1,Kill_Random_Type,nSelIndex);
            --  完成的数量
            Mission_Variable = DataPool:GetPlayerMission_Variable(nSelIndex,MissionParam_Index,Kill_Random_Type,i-1);
            MissionParam_Index = MissionParam_Index + 1;
            if Mission_Variable < nNum then
                return 0
            end
        end
    end

    --任务需要的物品
    local nDemandNum,Item_Random_Type= DataPool:GetPlayerMissionDemand_Num(nSelIndex);
    if( nDemandNum > 0 ) then
        for i=1, nDemandNum do
            --    需要的类型，需要物品ID，需要多少个
            local szName,nItemID, nNum = DataPool:GetPlayerMissionDemand_Item(i-1,Item_Random_Type,nSelIndex);
            --  完成的数量
            Mission_Variable = DataPool : GetPlayerMission_ItemCountNow(nItemID)
            if Mission_Variable < nNum then
                return 0
            end
        end
    end

    -----------------------------------------------------------------------------------
    --任务自定义的物品
    local nCustomNum = DataPool:GetPlayerMissionCustom_Num(nSelIndex);
    if( nCustomNum > 0 ) then
        for i=1, nCustomNum do
            --    需要的类型, 需要的数量
            local strCustom, nNum = DataPool:GetPlayerMissionCustom(i-1);
            --  完成的数量
            Mission_Variable = DataPool:GetPlayerMission_Variable(nSelIndex,MissionParam_Index);
            MissionParam_Index = MissionParam_Index + 1;
            if Mission_Variable < nNum then
                return 0
            end
        end
    end

    -----------------------------------------------------------------------------------
    --任务自定义的随机物品 zz添加
    local nRandomCustomNum = DataPool:GetPlayerMissionRandomCustom_Num(nSelIndex);
    if( nRandomCustomNum > 0 ) then
        for i=1,nRandomCustomNum do
            --  需要的类型, 需要的数量, 完成的数量
            local strCustom, nNeedNum,nCompleteNum = DataPool:GetPlayerMissionRandomCustom(i-1,nSelIndex);
            if nCompleteNum < nNeedNum then
                return 0
            end
        end
    end

    return 1
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function QuestLog_Frame_On_ResetPos()

    QuestLog_Frame : SetProperty("UnifiedXPosition", g_QuestLog_Frame_UnifiedXPosition);
    QuestLog_Frame : SetProperty("UnifiedYPosition", g_QuestLog_Frame_UnifiedYPosition);

end

function QuestLog_GetSCMTarget(nSelIndex)
    --第五位的第一字节存任务类型，第二字节场景序号
    local missionType = DataPool:GetPlayerMission_VariableByByte(nSelIndex, 5, 0) - 1
    local sceneIndex = DataPool:GetPlayerMission_VariableByByte(nSelIndex, 5, 1) - 1
    local strScript = DataPool:GetPlayerMission_StrList(missionType)
    local strTarget = ParserString(strScript,"Color")
    local strReplace = ""
    if missionType < 2 and  missionType >= 0 then
        strReplace = DataPool:GetPlayerMission_StrList(missionType*33 + 3 + sceneIndex)--这里的33是场景数量，如果要增加需要修改这个数字
    elseif missionType == 2 then--读表
        local monster={}
        local killNumber = 0
        killNumber,monster[1],monster[2],monster[3],monster[4],monster[5],monster[6],monster[7],monster[8] = DataPool:GetSCMKillMonsterInfo(sceneIndex+1)
        for i=1,8 do
            if monster[i]~=nil and monster[i]~="" then
                strReplace = strReplace .. monster[i] .. "#{SDHDRW_091216_02}"
            end
        end
        --去掉最后一个逗号
        strReplace = string.sub(strReplace, 1, string.len(strReplace) - string.len("#{SDHDRW_091216_02}"))
        strReplace = strReplace .. "#{CJXH_100517_14}" .. tostring(killNumber)
    end

    local pos = string.find(strTarget,"%%s")

    if(pos~=nil) then
        strTarget = string.sub(strTarget, 1 ,pos-1)..strReplace..string.sub(strTarget,pos+2)
    end

    local SceneList = {170,169,171,156,173,176,445,174,157,177,175,178,517,519,520,179,427,434,432,202,400,401,
                        402,203,159,160,161,162,163,164,165,166,167}
    local sceneId = SceneList[sceneIndex + 1]
    strReplace = GetSceneNameByID(sceneId)
    pos = string.find(strTarget,"%%t")
    if(pos~=nil and strReplace~=nil) then
	    strTarget = string.sub(strTarget, 1 ,pos-1)..strReplace..string.sub(strTarget,pos+2)
    end
    return strTarget
end

function QuestLog_GetSCMComplete(nSelIndex)
    local missionType = DataPool:GetPlayerMission_VariableByByte(nSelIndex, 5, 0) - 1
    local sceneIndex = DataPool:GetPlayerMission_VariableByByte(nSelIndex, 5, 1) - 1
    local strComplete = ""
    if(missionType==0) then
        strComplete = strComplete.."#{CJXH_100517_17}"
        local alreadyKill = DataPool:GetPlayerMission_Variable(nSelIndex, 1)
        local needKill = DataPool:GetPlayerMission_Variable(nSelIndex, 2)
	if alreadyKill > needKill then
		alreadyKill = needKill
	end
        strComplete = strComplete..tostring(alreadyKill).." / "..tostring(needKill)
    elseif (missionType == 1) then
        local itemName = PlayerPackage:GetItemName(40004526)
        strComplete = strComplete.."#{CJXH_100517_21}\n"..itemName.."："
        local alreadyObtain = DataPool:GetPlayerMission_Variable(nSelIndex, 1)
        local needObtain = DataPool:GetPlayerMission_Variable(nSelIndex, 2)
	if alreadyObtain > needObtain then
		alreadyObtain = needObtain
	end
        strComplete = strComplete..tostring(alreadyObtain).." / "..tostring(needObtain)
    elseif(missionType == 2) then
        strComplete = strComplete.."#{CJXH_100517_24}\n"
        local monster={}
        local killNumber = 0
        local alreadyKill = {}
        alreadyKill[1] = DataPool:GetSCMAlreadyKillNumber(DataPool:GetPlayerMission_Variable(nSelIndex, 1),1)
        alreadyKill[2] = DataPool:GetSCMAlreadyKillNumber(DataPool:GetPlayerMission_Variable(nSelIndex, 1),2)
        alreadyKill[3] = DataPool:GetSCMAlreadyKillNumber(DataPool:GetPlayerMission_Variable(nSelIndex, 2),1)
        alreadyKill[4] = DataPool:GetSCMAlreadyKillNumber(DataPool:GetPlayerMission_Variable(nSelIndex, 2),2)
        alreadyKill[5] = DataPool:GetSCMAlreadyKillNumber(DataPool:GetPlayerMission_Variable(nSelIndex, 3),1)
        alreadyKill[6] = DataPool:GetSCMAlreadyKillNumber(DataPool:GetPlayerMission_Variable(nSelIndex, 3),2)
        alreadyKill[7] = DataPool:GetSCMAlreadyKillNumber(DataPool:GetPlayerMission_Variable(nSelIndex, 4),1)
        alreadyKill[8] = DataPool:GetSCMAlreadyKillNumber(DataPool:GetPlayerMission_Variable(nSelIndex, 4),2)
        killNumber,monster[1],monster[2],monster[3],monster[4],monster[5],monster[6],monster[7],monster[8] = DataPool:GetSCMKillMonsterInfo(sceneIndex+1)
        for i=1,8 do
            if monster[i]~=nil and monster[i]~="" then
                strComplete = strComplete .. monster[i] .."：" .. tostring(alreadyKill[i]) .. " / " .. tostring(killNumber) .. "\n"
            end
        end
    end
    return strComplete
end

function QuestLog_GetInfantComplete( nSelIndex )
	local MissDone = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local MissType = DataPool:GetPlayerMission_Variable( nSelIndex, g_QuestLog_Infant_MissionType_Index )
	local BaoZhuangIndex = DataPool:GetPlayerMission_Variable( nSelIndex, g_QuestLog_Infant_baozhuang_Index )
	local MissIndex = DataPool:GetPlayerMission_Variable( nSelIndex, g_QuestLog_Infant_Mission_Index )

	local misId, sceneId, sceneName, NpcName, PosX, PosZ = DataPool:GetInfantExpMission(MissIndex)
	local str
	if MissType == g_QuestLog_Infant_SubMissionTypeEnum.BaiFang then
		str = ScriptGlobal_Format(g_QuestLog_Infant_complete_tips.BaiFang[BaoZhuangIndex], sceneName, PosX, PosZ, sceneId, NpcName, MissDone)

	elseif MissType == g_QuestLog_Infant_SubMissionTypeEnum.Caiji then
		str = ScriptGlobal_Format(g_QuestLog_Infant_complete_tips.Caiji[BaoZhuangIndex], NpcName, MissDone)

	elseif MissType == g_QuestLog_Infant_SubMissionTypeEnum.XunWu then
		str = ScriptGlobal_Format(g_QuestLog_Infant_complete_tips.XunWu[BaoZhuangIndex], NpcName, MissDone)

	elseif MissType == g_QuestLog_Infant_SubMissionTypeEnum.DingDianYinDao then
		str = ScriptGlobal_Format(g_QuestLog_Infant_complete_tips.DingDianYinDao[BaoZhuangIndex], MissDone)

	elseif MissType == g_QuestLog_Infant_SubMissionTypeEnum.BuZhuo then
		str = ScriptGlobal_Format(g_QuestLog_Infant_complete_tips.BuZhuo[BaoZhuangIndex], NpcName, MissDone)
	end

	return str
end


function QuestLog_GetHLXQJComplete( nSelIndex )
	local AlreadyPlay = {}

	AlreadyPlay[1] = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	AlreadyPlay[2] = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	AlreadyPlay[3] = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	AlreadyPlay[4] = DataPool:GetPlayerMission_Variable( nSelIndex, 4 )
	AlreadyPlay[5] = DataPool:GetPlayerMission_Variable( nSelIndex, 5 )

	local MenPaiList = {
		[0] = { id = 0, rate = 10, name = "#{XQ_MP_1}" },    --少林
		[1] = { id = 1, rate = 20, name = "#{XQ_MP_2}" },    --明教
		[2] = { id = 2, rate = 30, name = "#{XQ_MP_3}" },    --丐帮
		[3] = { id = 3, rate = 40, name = "#{XQ_MP_4}" },    --武当
		[4] = { id = 4, rate = 50, name = "#{XQ_MP_5}" },    --峨眉
		[5] = { id = 5, rate = 60, name = "#{XQ_MP_6}" },    --星宿
		[6] = { id = 6, rate = 70, name = "#{XQ_MP_7}" },    --天龙
		[7] = { id = 7, rate = 80, name = "#{XQ_MP_8}" },    --天山
		[8] = { id = 8, rate = 90, name = "#{XQ_MP_9}" },    --逍遥
        [9] = { id = 9, rate = 0, name = "" },         --无门派
		[10] = { id = 10, rate = 100, name = "#{XQ_MP_10}" },  --慕容
		[11] = { id = 11, rate = 100, name = "#{XMPTM_130123_05}" },  --唐门
		[12] = { id = 12, rate = 100, name = "#{XMPGG_160524_02}" },  --鬼谷
        [13] = { id = 13, rate = 100, name = "#{XQ_MP_15}" },  --桃花岛
		[14] = { id = 14, rate = 100, name = "#{XMPHM_210604_01}" }, 
		[15] = { id = 15, rate = 100, name = "#{GMGameInterface_Script_DataPool_Info_ERenGu}" },--menpai15 mptodo 
	}

	local strComplete = ""

	for i = 1, 5 do
		local aimMenpai = 0
		local isDone = 1
		if AlreadyPlay[i] >= 100 then
			aimMenpai = 1
			AlreadyPlay[i] = AlreadyPlay[i] - 100
		end
        local temp_str = "#{XQ_MP_11}"..MenPaiList[AlreadyPlay[i]].name.."#{XQ_MP_12}".." "..tostring( aimMenpai ).."/"..tostring( isDone )
        strComplete = strComplete..temp_str.."\n"
	end

	return strComplete
end

function QuestLog_GetJFTXComplete( nSelIndex )
	local AlreadyPlay = {}

	AlreadyPlay[1] = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	AlreadyPlay[2] = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	AlreadyPlay[3] = DataPool:GetPlayerMission_Variable( nSelIndex, 4 )

	local MenPaiList = {
		[0] = { id = 0, rate = 10, name = "#{XQ_MP_1}" },    --少林
		[1] = { id = 1, rate = 20, name = "#{XQ_MP_2}" },    --明教
		[2] = { id = 2, rate = 30, name = "#{XQ_MP_3}" },    --丐帮
		[3] = { id = 3, rate = 40, name = "#{XQ_MP_4}" },    --武当
		[4] = { id = 4, rate = 50, name = "#{XQ_MP_5}" },    --峨眉
		[5] = { id = 5, rate = 60, name = "#{XQ_MP_6}" },    --星宿
		[6] = { id = 6, rate = 70, name = "#{XQ_MP_7}" },    --天龙
		[7] = { id = 7, rate = 80, name = "#{XQ_MP_8}" },    --天山
		[8] = { id = 8, rate = 90, name = "#{XQ_MP_9}" },    --逍遥
		[9] = { id = 9, rate = 0, name = "" },         --无门派
		[10] = { id = 10, rate = 100, name = "#{XQ_MP_10}" },  --慕容
		[11] = { id = 11, rate = 100, name = "#{XMPTM_130123_05}" },  --唐门
		[12] = { id = 12, rate = 100, name = "#{XMPGG_160524_02}" },  --鬼谷
        [13] = { id = 13, rate = 100, name = "#{XQ_MP_15}" },  --桃花岛
		[14] = { id = 14, rate = 100, name = "#{XMPHM_210604_01}" }, 
		[15] = { id = 15, rate = 100, name = "#{GMGameInterface_Script_DataPool_Info_ERenGu}" }, --menpai15 mptodo
	}

	local strComplete = ""

	for i = 1, 3 do
		local aimMenpai = 0
		local isDone = 1
		if AlreadyPlay[i] >= 100 then
			aimMenpai = 1
			AlreadyPlay[i] = AlreadyPlay[i] - 100
		end
		local temp_str = "#{FJTX_140227_70}"..MenPaiList[AlreadyPlay[i]].name.."#{FJTX_140227_71}".." "..tostring( aimMenpai ).."/"..tostring( isDone )
		strComplete = strComplete..temp_str.."\n"
	end

	return strComplete
end

--*************************************
-- 帮会交互任务
--*************************************
-- function QuestLog_GuildInteractiveMission( nSelIndex )
-- 	-- 子任务
-- 	local nSubMission = DataPool : GetPlayerMission_Variable( nSelIndex, g_GuildInteractiveMission_MisType );
-- 	if ( nSubMission < 1 or nSubMission > table.getn( g_GuildInteractiveMissionDesc ) ) then
-- 		return "";
-- 	end
-- 	if ( nSubMission == 1 ) then
-- 		local nRefreshPos = {
-- 			{83,43}, {84,45}, {88,41}, {88,48}, {92,46}, 			-- Group1
-- 			{43,62},{45,66}, {42,71}, {47,68},{47,60},  			-- Group2
-- 			{79,95}, {74,100},{81,103}, {84,105}, {85,95},  		-- Group3
-- 			{81,140}, {80,145}, {77,144}, {82,143}, {84,149},  		-- Group4
-- 			{120,139}, {122,143}, {115,146}, {120,148}, {118,143},  -- Group5
-- 			{140,128}, {144,130}, {146,133}, {141,134}, {138,140}, 	-- Group6
-- 		};
-- 		local nPos1 = DataPool : GetPlayerMission_Variable( nSelIndex, g_GuildInteractiveMission1_PosIndexOne );
-- 		local nPos2 = DataPool : GetPlayerMission_Variable( nSelIndex, g_GuildInteractiveMission1_PosIndexTwo );
-- 		local nPos3 = DataPool : GetPlayerMission_Variable( nSelIndex, g_GuildInteractiveMission1_PosIndexThree );
-- 		local nPos4 = DataPool : GetPlayerMission_Variable( nSelIndex, g_GuildInteractiveMission1_PosIndexFour );
-- 		local nPos5 = DataPool : GetPlayerMission_Variable( nSelIndex, g_GuildInteractiveMission1_PosIndexFive );
-- 		if ( nPos1 < 1 or nPos1 > table.getn( nRefreshPos )
-- 				or nPos2 < 1 or nPos2 > table.getn( nRefreshPos )
-- 				or nPos3 < 1 or nPos3 > table.getn( nRefreshPos )
-- 				or nPos4 < 1 or nPos4 > table.getn( nRefreshPos )
-- 				or nPos5 < 1 or nPos5 > table.getn( nRefreshPos ) ) then
-- 			return "";
-- 		end
-- 		-- ScriptGlobal_Format 只能支持7个参数
-- 		--local text = ScriptGlobal_Format( g_GuildInteractiveMissionDesc[ nSubMission ], nRefreshPos[ nPos1 ][ 1 ], nRefreshPos[ nPos1 ][ 2 ],
-- 		--																				nRefreshPos[ nPos2 ][ 1 ], nRefreshPos[ nPos2 ][ 2 ],
-- 		--																				nRefreshPos[ nPos3 ][ 1 ], nRefreshPos[ nPos3 ][ 2 ],
-- 		--																				nRefreshPos[ nPos4 ][ 1 ], nRefreshPos[ nPos4 ][ 2 ],
-- 		--																				nRefreshPos[ nPos5 ][ 1 ], nRefreshPos[ nPos5 ][ 2 ] );
-- 		local text = string.format( g_GuildInteractiveMissionDesc[ nSubMission ], nRefreshPos[ nPos1 ][ 1 ], nRefreshPos[ nPos1 ][ 2 ],
-- 																			nRefreshPos[ nPos2 ][ 1 ], nRefreshPos[ nPos2 ][ 2 ],
-- 																			nRefreshPos[ nPos3 ][ 1 ], nRefreshPos[ nPos3 ][ 2 ],
-- 																			nRefreshPos[ nPos4 ][ 1 ], nRefreshPos[ nPos4 ][ 2 ],
-- 																			nRefreshPos[ nPos5 ][ 1 ], nRefreshPos[ nPos5 ][ 2 ] );
-- 		return text;
-- 	elseif ( nSubMission == 2 ) then
-- 		-- 飞贼起始点
-- 		local nStartPos = {
-- 			{151,64},
-- 			{125,66},
-- 			{142,58},
-- 			{129,53},
-- 			{134,57},
-- 		};
-- 		local nPosIndex = DataPool : GetPlayerMission_Variable( nSelIndex, g_GuildInteractiveMission2_PosIndex );
-- 		if ( nPosIndex < 1 or nPosIndex > table.getn( nStartPos ) ) then
-- 			return "";
-- 		end
-- 		local text = ScriptGlobal_Format( g_GuildInteractiveMissionDesc[ nSubMission ], nStartPos[ nPosIndex ][ 1 ], nStartPos[ nPosIndex ][ 2 ] );
-- 		return text;
-- 	end

-- 	return "";
-- end

function QuestLog_ZhanBeiMission_JiShaShouWei( nSelIndex )

	--战盟对应场景
	local aryAllianceScene = {
		[ 0 ] = 663,
		[ 1 ] = 664,
		[ 2 ] = 665,
		[ 3 ] = 666,
		[ 4 ] = 667,
	}
	--战盟对应的名字
	local aryAllianceName = {
		[0] = "千秋殿",
		[1] = "不归林",
		[2] = "无涯海",
		[3] = "炎罗天",
		[4] = "玉皇山",
	}
	local aryDirection = { "东", "西", "南", "北" }
	-- 城门守将
	local aryCaptains = {
		[ 0 ] = {
			{ NpcId = 44603, Pos = { 282, 189 }, MissionPos = { 299, 189 } },	-- 东
			{ NpcId = 44604, Pos = { 99, 189 }, MissionPos = { 77, 180 } },		-- 西
			{ NpcId = 44605, Pos = { 189, 282 }, MissionPos = { 190, 300 } },	-- 南
			{ NpcId = 44606, Pos = { 189, 97 }, MissionPos = { 189, 78 } },		-- 北
		},
		[ 1 ] = {
			{ NpcId = 44613, Pos = { 282, 189 }, MissionPos = { 299, 189 } },	-- 东
			{ NpcId = 44614, Pos = { 99, 189 }, MissionPos = { 77, 180 } },		-- 西
			{ NpcId = 44615, Pos = { 189, 282 }, MissionPos = { 190, 300 } },	-- 南
			{ NpcId = 44616, Pos = { 189, 97 }, MissionPos = { 189, 78 } },		-- 北
		},
		[ 2 ] = {
			{ NpcId = 44623, Pos = { 282, 189 }, MissionPos = { 299, 189 } },	-- 东
			{ NpcId = 44624, Pos = { 99, 189 }, MissionPos = { 77, 180 } },		-- 西
			{ NpcId = 44625, Pos = { 189, 282 }, MissionPos = { 190, 300 } },	-- 南
			{ NpcId = 44626, Pos = { 189, 97 }, MissionPos = { 189, 78 } },		-- 北
		},
		[ 3 ] = {
			{ NpcId = 44633, Pos = { 282, 189 }, MissionPos = { 299, 189 } },	-- 东
			{ NpcId = 44634, Pos = { 99, 189 }, MissionPos = { 77, 180 } },		-- 西
			{ NpcId = 44635, Pos = { 189, 282 }, MissionPos = { 190, 300 } },	-- 南
			{ NpcId = 44636, Pos = { 189, 97 }, MissionPos = { 189, 78 } },		-- 北
		},
		[ 4 ] = {
			{ NpcId = 44643, Pos = { 282, 189 }, MissionPos = { 299, 189 } },	-- 东
			{ NpcId = 44644, Pos = { 99, 189 }, MissionPos = { 77, 180 } },		-- 西
			{ NpcId = 44645, Pos = { 189, 282 }, MissionPos = { 190, 300 } },	-- 南
			{ NpcId = 44646, Pos = { 189, 97 }, MissionPos = { 189, 78 } },		-- 北
		},
	}
	local  aryAllianceNpcName = {
			[0] = "陆浅秋",
			[1] = "陆薄归",
			[2] = "陆伍涯",
			[3] = "陆彦罗",
			[4] = "陆黄山",
		}
	--战备开始时刷的4个战备官
	local aryZhanBeiNpc_Ex = {
		[0] = {
				[1] = {npcid = 44599, xpos=368, zpos=10, name="前锋营地战备官·东北" }, 	--东北前锋战备官
				[2] = {npcid = 44600, xpos=373, zpos=370, name="前锋营地战备官·东南" }, --东南前锋战备官
				[3] = {npcid = 44601, xpos=15, zpos=371, name="前锋营地战备官·西南" }, 	--西南前锋战备官
				[4] = {npcid = 44602, xpos=9, zpos=11, name="前锋营地战备官·西北" }, 	--西北前锋战备官
			  },
		[1] = {
				[1] = {npcid = 44609, xpos=368, zpos=10, name="前锋营地战备官·东北" }, 	--东北前锋战备官
				[2] = {npcid = 44610, xpos=373, zpos=370, name="前锋营地战备官·东南" }, --东南前锋战备官
				[3] = {npcid = 44611, xpos=15, zpos=371, name="前锋营地战备官·西南" }, 	--西南前锋战备官
				[4] = {npcid = 44612, xpos=9, zpos=11, name="前锋营地战备官·西北" }, 	--西北前锋战备官
			  },
		[2] = {
				[1] = {npcid = 44619, xpos=368, zpos=10, name="前锋营地战备官·东北" }, 	--东北前锋战备官
				[2] = {npcid = 44620, xpos=373, zpos=370, name="前锋营地战备官·东南" }, --东南前锋战备官
				[3] = {npcid = 44621, xpos=15, zpos=371, name="前锋营地战备官·西南" }, 	--西南前锋战备官
				[4] = {npcid = 44622, xpos=9, zpos=11, name="前锋营地战备官·西北" }, 	--西北前锋战备官
			  },
		[3] = {
				[1] = {npcid = 44629, xpos=368, zpos=10, name="前锋营地战备官·东北" }, 	--东北前锋战备官
				[2] = {npcid = 44630, xpos=373, zpos=370, name="前锋营地战备官·东南" }, --东南前锋战备官
				[3] = {npcid = 44631, xpos=15, zpos=371, name="前锋营地战备官·西南" }, 	--西南前锋战备官
				[4] = {npcid = 44632, xpos=9, zpos=11, name="前锋营地战备官·西北" }, 	--西北前锋战备官
			  },
		[4] = {
				[1] = {npcid = 44639, xpos=368, zpos=10, name="前锋营地战备官·东北" }, 	--东北前锋战备官
				[2] = {npcid = 44640, xpos=373, zpos=370, name="前锋营地战备官·东南" }, --东南前锋战备官
				[3] = {npcid = 44641, xpos=15, zpos=371, name="前锋营地战备官·西南" }, 	--西南前锋战备官
				[4] = {npcid = 44642, xpos=9, zpos=11, name="前锋营地战备官·西北" }, 	--西北前锋战备官
			  },
	}
	-- Parameters
	local nZhanBeiMission_TargetDirectIndex = 2				-- 任务参数2: 发放目标点的位置索引
	local nZhanBeiMission_AllianceIdAndNpcIndex = 4			-- 任务参数4: 接任务时的战盟id和任务ObjId
	local nZhanBeiMission_XZAllianceId = 5					-- 任务参数5: 接任务时的目标战盟id
	local nZhanBeiMission_SubMission_JisShaShouWei = 6;		-- 任务参数6: 子任务类型
	-- Direction
	local rdmDirection = DataPool : GetPlayerMission_Variable( nSelIndex, nZhanBeiMission_TargetDirectIndex );
	if ( rdmDirection < 1 or rdmDirection > table.getn( aryDirection ) ) then
		return "";
	end
	-- Npc Index
	local npcIndex = DataPool : GetPlayerMission_Variable( nSelIndex, nZhanBeiMission_AllianceIdAndNpcIndex );
	npcIndex = math.mod( npcIndex, 10000 );
	if ( npcIndex < 1 or npcIndex > 4 ) then
		return "";
	end
	-- XZAllianceId
	local nXZAllianceId = DataPool : GetPlayerMission_Variable( nSelIndex, nZhanBeiMission_XZAllianceId );
	if ( nXZAllianceId < 0 or nXZAllianceId > table.getn( aryAllianceName ) ) then
		return "";
	end
	-- SubMission
	local nSubMission = DataPool : GetPlayerMission_Variable( nSelIndex, nZhanBeiMission_SubMission_JisShaShouWei );
	if ( nSubMission ~= 7 ) then
		return "";
	end

	-- First half string
	local nSceneId = aryAllianceScene[ nXZAllianceId ];
	local szAllianceName = aryAllianceName[ nXZAllianceId ];
	local szDirection = aryDirection[ rdmDirection ];
	local aryPos = aryCaptains[ nXZAllianceId ][ rdmDirection ].MissionPos;
	local textFirstHalf = ScriptGlobal_Format( "#{MZZBQ_150811_548}", szDirection, aryPos[ 1 ], aryPos[ 2 ], nSceneId, szDirection );
	-- Latter half string
	local xpos = aryZhanBeiNpc_Ex[ nXZAllianceId ][ npcIndex ].xpos;
	local ypos = aryZhanBeiNpc_Ex[ nXZAllianceId ][ npcIndex ].zpos;
	local szTargetAllianceName = aryAllianceName[ nXZAllianceId ];
	local npcName = aryAllianceNpcName[ nXZAllianceId ];
	local targetName = aryZhanBeiNpc_Ex[ nXZAllianceId ][ npcIndex ].name;
	local textLatterHalf=ScriptGlobal_Format( "#{MZZBQ_150811_549}", szTargetAllianceName, xpos, ypos, nSceneId, npcName, targetName);
	-- synthesis string
	local synthesisText = ""..textFirstHalf..""..textLatterHalf;
	return synthesisText;
end

function QuestLog_GetZhanBeiTarget( nSelIndex )
	local MissType = DataPool:GetPlayerMission_Variable( nSelIndex, 6 ) --任务子类型
	local nXZZMId = DataPool:GetPlayerMission_Variable( nSelIndex, 5 ) --目标战盟id
	local nTargetIndex = DataPool:GetPlayerMission_Variable( nSelIndex, 2 ) --目标位置索引
	local nSelfZMId_temp = DataPool:GetPlayerMission_Variable( nSelIndex, 4 ) --接任务时的战盟id(此为两个合体:000000|0000，低4位为接任务时的npc索引，策划你别再加了，要崩溃了)
	local nSelfZMId = math.floor(nSelfZMId_temp/10000)
	local nAcceptNpcIndex = math.mod(nSelfZMId_temp, 10000)

	local  AllianceNpcNameList = {
		[0] = {
				[1] = {xpos=368, zpos=10, name="前锋营地战备官·东北"}, --东北前锋战备官
				[2] = {xpos=373, zpos=370, name="前锋营地战备官·东南"}, --东南前锋战备官
				[3] = {xpos=15, zpos=371, name="前锋营地战备官·西南"}, --西南前锋战备官
				[4] = {xpos=9, zpos=11, name="前锋营地战备官·西北"}, --西北前锋战备官
			  },
		[1] = {
				[1] = {xpos=368, zpos=10, name="前锋营地战备官·东北"}, --东北前锋战备官
				[2] = {xpos=373, zpos=370, name="前锋营地战备官·东南"}, --东南前锋战备官
				[3] = {xpos=15, zpos=371, name="前锋营地战备官·西南"}, --西南前锋战备官
				[4] = {xpos=9, zpos=11, name="前锋营地战备官·西北"}, --西北前锋战备官
			  },
		[2] = {
				[1] = {xpos=368, zpos=10, name="前锋营地战备官·东北"}, --东北前锋战备官
				[2] = {xpos=373, zpos=370, name="前锋营地战备官·东南"}, --东南前锋战备官
				[3] = {xpos=15, zpos=371, name="前锋营地战备官·西南"}, --西南前锋战备官
				[4] = {xpos=9, zpos=11, name="前锋营地战备官·西北"}, --西北前锋战备官
			  },
		[3] = {
				[1] = {xpos=368, zpos=10, name="前锋营地战备官·东北"}, --东北前锋战备官
				[2] = {xpos=373, zpos=370, name="前锋营地战备官·东南"}, --东南前锋战备官
				[3] = {xpos=15, zpos=371, name="前锋营地战备官·西南"}, --西南前锋战备官
				[4] = {xpos=9, zpos=11, name="前锋营地战备官·西北"}, --西北前锋战备官
			  },
		[4] = {
				[1] = {xpos=368, zpos=10, name="前锋营地战备官·东北"}, --东北前锋战备官
				[2] = {xpos=373, zpos=370, name="前锋营地战备官·东南"}, --东南前锋战备官
				[3] = {xpos=15, zpos=371, name="前锋营地战备官·西南"}, --西南前锋战备官
				[4] = {xpos=9, zpos=11, name="前锋营地战备官·西北"}, --西北前锋战备官
			  },
		}

	local AllianceSceneList = {
				[ 0 ] = 663,
				[ 1 ] = 664,
				[ 2 ] = 665,
				[ 3 ] = 666,
				[ 4 ] = 667,
			}

	local AllianceName_list = {
			[0] = "千秋殿",
			[1] = "不归林",
			[2] = "无涯海",
			[3] = "炎罗天",
			[4] = "玉皇山",
	}

	local targetZMName = ""
	local toScene = 0
	local selfScene = 0
	local missNpcName = ""
	local acceptxPos = 0
	local acceptzPos = 0
	if nXZZMId >= 0 and nXZZMId <= 4 then
		targetZMName = AllianceName_list[nXZZMId]
		toScene = AllianceSceneList[nXZZMId]
		selfScene = AllianceSceneList[nXZZMId]
	end

	if nSelfZMId >= 0 and nSelfZMId <= 4 and nAcceptNpcIndex > 0 and nAcceptNpcIndex <= 4 then
		--接交任务又改到宣战战盟的地图上去了
		--selfScene = AllianceSceneList[nSelfZMId]
		local AcceptMisInfo = AllianceNpcNameList[nSelfZMId]
		missNpcName = AcceptMisInfo[nAcceptNpcIndex].name
		acceptxPos = AcceptMisInfo[nAcceptNpcIndex].xpos
		acceptzPos = AcceptMisInfo[nAcceptNpcIndex].zpos
	end

	local str
	if MissType == 1 then
		local DestPosList = {
				[1] = {xlefttoppos = 129, zlefttoppos = 80, xrightbottompos = 150, zrightbottompos = 91, tipposx = 139, tipposz = 85},
				[2] = {xlefttoppos = 222, zlefttoppos = 83, xrightbottompos = 236, zrightbottompos = 92, tipposx = 229, tipposz = 87},
				[3] = {xlefttoppos = 286, zlefttoppos = 124, xrightbottompos = 296, zrightbottompos = 144, tipposx = 291, tipposz = 134},
				[4] = {xlefttoppos = 284, zlefttoppos = 223, xrightbottompos = 294, zrightbottompos = 243, tipposx = 289, tipposz = 233},
				[5] = {xlefttoppos = 220, zlefttoppos = 285, xrightbottompos = 240, zrightbottompos = 295, tipposx = 230, tipposz = 290},
				[6] = {xlefttoppos = 144, zlefttoppos = 286, xrightbottompos = 164, zrightbottompos = 296, tipposx = 154, tipposz = 291},
				[7] = {xlefttoppos = 84, zlefttoppos = 217, xrightbottompos = 94, zrightbottompos = 237, tipposx = 89, tipposz = 227},
				[8] = {xlefttoppos = 84, zlefttoppos = 151, xrightbottompos = 94, zrightbottompos = 171, tipposx = 89, tipposz = 161},
			}

		local PosX = 0
		local PosZ = 0
		if nTargetIndex >= 1 and nTargetIndex <= 8 then
			PosX = DestPosList[nTargetIndex].tipposx
			PosZ = DestPosList[nTargetIndex].tipposz
		end

		local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_49}", targetZMName,PosX,PosZ,toScene)
		local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		str = strtemp1 .. strtemp2

	elseif MissType == 2 then
		local ZhanBeiNpc_Info = {
				[1] = {npcid = 43906, poslist = {[1] = {xpos=147, zpos=35}, [2] = {xpos=230, zpos=39}, [3] = {xpos=342, zpos=150}, [4] = {xpos=349, zpos=224}, [5] = {xpos=232, zpos=346}, [6] = {xpos=162, zpos=349}, [7] = {xpos=33, zpos=232}, [8] = {xpos=30, zpos=160}}, baseai=3, aiScript=-1, scriptid=891451, dir=0}, --密信探子
				[2] = {npcid = 43907, poslist = {[1] = {xpos=159, zpos=66}, [2] = {xpos=231, zpos=60}, [3] = {xpos=314, zpos=150}, [4] = {xpos=311, zpos=232}, [5] = {xpos=222, zpos=312}, [6] = {xpos=150, zpos=317}, [7] = {xpos=63, zpos=230}, [8] = {xpos=62, zpos=149}}, baseai=3, aiScript=-1, scriptid=891452, dir=0}, --情报探子
				[3] = {npcid = 43908, poslist = {[1] = {xpos=312, zpos=62}, [2] = {xpos=315, zpos=311}, [3] = {xpos=67, zpos=314},[4] = {xpos=64, zpos=68}}, baseai=3, aiScript=-1, scriptid=891453, dir=0}, --王旗
				[4] = {npcid = 43909, poslist = {[1] = {xpos=82, zpos=134}, [2] = {xpos=84, zpos=246}, [3] = {xpos=143, zpos=298}, [4] = {xpos=241, zpos=305}, [5] = {xpos=287, zpos=244}, [6] = {xpos=297, zpos=133}, [7] = {xpos=240, zpos=78}, [8] = {xpos=133, zpos=82}}, baseai=3, aiScript=-1, scriptid=891454, dir=0}, --粮仓
			}

		local PosX = 0
		local PosZ = 0
		if nTargetIndex >= 1 and nTargetIndex <= 8 then
			local TempData = ZhanBeiNpc_Info[1].poslist
			PosX = TempData[nTargetIndex].xpos
			PosZ = TempData[nTargetIndex].zpos
		end

		local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_82}", targetZMName,PosX,PosZ,toScene)
		local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		str = strtemp1 .. strtemp2

	elseif MissType == 3 then
		local ZhanBeiNpc_Info = {
				[1] = {npcid = 43906, poslist = {[1] = {xpos=147, zpos=35}, [2] = {xpos=230, zpos=39}, [3] = {xpos=342, zpos=150}, [4] = {xpos=349, zpos=224}, [5] = {xpos=232, zpos=346}, [6] = {xpos=162, zpos=349}, [7] = {xpos=33, zpos=232}, [8] = {xpos=30, zpos=160}}, baseai=3, aiScript=-1, scriptid=891451, dir=0}, --密信探子
				[2] = {npcid = 43907, poslist = {[1] = {xpos=159, zpos=66}, [2] = {xpos=231, zpos=60}, [3] = {xpos=314, zpos=150}, [4] = {xpos=311, zpos=232}, [5] = {xpos=222, zpos=312}, [6] = {xpos=150, zpos=317}, [7] = {xpos=63, zpos=230}, [8] = {xpos=62, zpos=149}}, baseai=3, aiScript=-1, scriptid=891452, dir=0}, --情报探子
				[3] = {npcid = 43908, poslist = {[1] = {xpos=312, zpos=62}, [2] = {xpos=315, zpos=311}, [3] = {xpos=67, zpos=314},[4] = {xpos=64, zpos=68}}, baseai=3, aiScript=-1, scriptid=891453, dir=0}, --王旗
				[4] = {npcid = 43909, poslist = {[1] = {xpos=82, zpos=134}, [2] = {xpos=84, zpos=246}, [3] = {xpos=143, zpos=298}, [4] = {xpos=241, zpos=305}, [5] = {xpos=287, zpos=244}, [6] = {xpos=297, zpos=133}, [7] = {xpos=240, zpos=78}, [8] = {xpos=133, zpos=82}}, baseai=3, aiScript=-1, scriptid=891454, dir=0}, --粮仓
			}

		local PosX = 0
		local PosZ = 0
		if nTargetIndex >= 1 and nTargetIndex <= 4 then
			local TempData = ZhanBeiNpc_Info[3].poslist
			PosX = TempData[nTargetIndex].xpos
			PosZ = TempData[nTargetIndex].zpos
		end


		local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_95}", targetZMName,PosX,PosZ,toScene)
		local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		str = strtemp1 .. strtemp2

	elseif MissType == 4 then
		local ZhanBeiNpc_Info = {
				[1] = {npcid = 43906, poslist = {[1] = {xpos=147, zpos=35}, [2] = {xpos=230, zpos=39}, [3] = {xpos=342, zpos=150}, [4] = {xpos=349, zpos=224}, [5] = {xpos=232, zpos=346}, [6] = {xpos=162, zpos=349}, [7] = {xpos=33, zpos=232}, [8] = {xpos=30, zpos=160}}, baseai=3, aiScript=-1, scriptid=891451, dir=0}, --密信探子
				[2] = {npcid = 43907, poslist = {[1] = {xpos=159, zpos=66}, [2] = {xpos=231, zpos=60}, [3] = {xpos=314, zpos=150}, [4] = {xpos=311, zpos=232}, [5] = {xpos=222, zpos=312}, [6] = {xpos=150, zpos=317}, [7] = {xpos=63, zpos=230}, [8] = {xpos=62, zpos=149}}, baseai=3, aiScript=-1, scriptid=891452, dir=0}, --情报探子
				[3] = {npcid = 43908, poslist = {[1] = {xpos=312, zpos=62}, [2] = {xpos=315, zpos=311}, [3] = {xpos=67, zpos=314},[4] = {xpos=64, zpos=68}}, baseai=3, aiScript=-1, scriptid=891453, dir=0}, --王旗
				[4] = {npcid = 43909, poslist = {[1] = {xpos=82, zpos=134}, [2] = {xpos=84, zpos=246}, [3] = {xpos=143, zpos=298}, [4] = {xpos=241, zpos=305}, [5] = {xpos=287, zpos=244}, [6] = {xpos=297, zpos=133}, [7] = {xpos=240, zpos=78}, [8] = {xpos=133, zpos=82}}, baseai=3, aiScript=-1, scriptid=891454, dir=0}, --粮仓
			}

		local PosX = 0
		local PosZ = 0
		if nTargetIndex >= 1 and nTargetIndex <= 8 then
			local TempData = ZhanBeiNpc_Info[2].poslist
			PosX = TempData[nTargetIndex].xpos
			PosZ = TempData[nTargetIndex].zpos
		end

		local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_124}", targetZMName,PosX,PosZ,toScene)
		local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		str = strtemp1 .. strtemp2

	elseif MissType == 5 then
		local ZhanBeiNpc_Info = {
				[1] = {npcid = 43906, poslist = {[1] = {xpos=147, zpos=35}, [2] = {xpos=230, zpos=39}, [3] = {xpos=342, zpos=150}, [4] = {xpos=349, zpos=224}, [5] = {xpos=232, zpos=346}, [6] = {xpos=162, zpos=349}, [7] = {xpos=33, zpos=232}, [8] = {xpos=30, zpos=160}}, baseai=3, aiScript=-1, scriptid=891451, dir=0}, --密信探子
				[2] = {npcid = 43907, poslist = {[1] = {xpos=159, zpos=66}, [2] = {xpos=231, zpos=60}, [3] = {xpos=314, zpos=150}, [4] = {xpos=311, zpos=232}, [5] = {xpos=222, zpos=312}, [6] = {xpos=150, zpos=317}, [7] = {xpos=63, zpos=230}, [8] = {xpos=62, zpos=149}}, baseai=3, aiScript=-1, scriptid=891452, dir=0}, --情报探子
				[3] = {npcid = 43908, poslist = {[1] = {xpos=312, zpos=62}, [2] = {xpos=315, zpos=311}, [3] = {xpos=67, zpos=314},[4] = {xpos=64, zpos=68}}, baseai=3, aiScript=-1, scriptid=891453, dir=0}, --王旗
				[4] = {npcid = 43909, poslist = {[1] = {xpos=82, zpos=134}, [2] = {xpos=84, zpos=246}, [3] = {xpos=143, zpos=298}, [4] = {xpos=241, zpos=305}, [5] = {xpos=287, zpos=244}, [6] = {xpos=297, zpos=133}, [7] = {xpos=240, zpos=78}, [8] = {xpos=133, zpos=82}}, baseai=3, aiScript=-1, scriptid=891454, dir=0}, --粮仓
			}

		local PosX = 0
		local PosZ = 0
		if nTargetIndex >= 1 and nTargetIndex <= 8 then
			local TempData = ZhanBeiNpc_Info[4].poslist
			PosX = TempData[nTargetIndex].xpos
			PosZ = TempData[nTargetIndex].zpos
		end

		local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_137}", targetZMName,PosX,PosZ,toScene)
		local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		str = strtemp1 .. strtemp2

	elseif MissType == 6 then
		local TargetPosInfo = {
				[1] = {xpos = 78, zpos = 162},
				[2] = {xpos = 80, zpos = 241},
				[3] = {xpos = 157, zpos = 299},
				[4] = {xpos = 223, zpos = 297},
				[5] = {xpos = 300, zpos = 220},
				[6] = {xpos = 299, zpos = 157},
				[7] = {xpos = 230, zpos = 80},
				[8] = {xpos = 146, zpos = 83},
			}

		local PosX = 0
		local PosZ = 0
		if nTargetIndex >= 1 and nTargetIndex <= 8 then
			PosX = TargetPosInfo[nTargetIndex].xpos
			PosZ = TargetPosInfo[nTargetIndex].zpos
		end

		local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_166}", targetZMName,PosX,PosZ,toScene)
		local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		str = strtemp1 .. strtemp2
	end

	return str
end

function QuestLog_GetInfantTarget( nSelIndex )
	local MissType = DataPool:GetPlayerMission_Variable( nSelIndex, g_QuestLog_Infant_MissionType_Index )
	local BaoZhuangIndex = DataPool:GetPlayerMission_Variable( nSelIndex, g_QuestLog_Infant_baozhuang_Index )
	local MissIndex = DataPool:GetPlayerMission_Variable( nSelIndex, g_QuestLog_Infant_Mission_Index )

	local misId, sceneId, sceneName, NpcName, PosX, PosZ = DataPool:GetInfantExpMission(MissIndex)
	local str
	if MissType == g_QuestLog_Infant_SubMissionTypeEnum.BaiFang then
		str = ScriptGlobal_Format(g_QuestLog_Infant_tips.BaiFang[BaoZhuangIndex], sceneName, PosX, PosZ, sceneId, NpcName)

	elseif MissType == g_QuestLog_Infant_SubMissionTypeEnum.Caiji then
		str = ScriptGlobal_Format(g_QuestLog_Infant_tips.Caiji[BaoZhuangIndex], sceneName, PosX, PosZ, sceneId, NpcName)

	elseif MissType == g_QuestLog_Infant_SubMissionTypeEnum.XunWu then
        --坑爹提示
        --寻物任务里面前6个是在1个npc处购买，后6个是在一个npc处购买，因此才会有下面的特写
		--有问题就先看看InfantExpMisTable.txt这张表吧
        if misId >= 47 and misId <=52 then
            str = ScriptGlobal_Format(g_QuestLog_Infant_tips.XunWu[BaoZhuangIndex], NpcName)
		else
            str = ScriptGlobal_Format(g_QuestLog_Infant_tips.XunWu[BaoZhuangIndex+4], NpcName)
        end
	elseif MissType == g_QuestLog_Infant_SubMissionTypeEnum.DingDianYinDao then
		str = ScriptGlobal_Format(g_QuestLog_Infant_tips.DingDianYinDao[BaoZhuangIndex], sceneName, PosX, PosZ,sceneId)

	elseif MissType == g_QuestLog_Infant_SubMissionTypeEnum.BuZhuo then
		str = ScriptGlobal_Format(g_QuestLog_Infant_tips.BuZhuo[BaoZhuangIndex], PosX, PosZ, NpcName)
	end

	return str
end

function QuestLog_GetHLXQJTarget( nSelIndex )
	local AlreadyPlay = {}

    AlreadyPlay[1] = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	AlreadyPlay[2] = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	AlreadyPlay[3] = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	AlreadyPlay[4] = DataPool:GetPlayerMission_Variable( nSelIndex, 4 )
	AlreadyPlay[5] = DataPool:GetPlayerMission_Variable( nSelIndex, 5 )

    for i = 1, 5 do
        if AlreadyPlay[i] >= 100 then
            AlreadyPlay[i] = AlreadyPlay[i] - 100
        end
    end

	local MenPaiList = {
		[0] = { id = 0, rate = 10, name = "#{XQ_MP_1}" },    --少林
		[1] = { id = 1, rate = 20, name = "#{XQ_MP_2}" },    --明教
		[2] = { id = 2, rate = 30, name = "#{XQ_MP_3}" },    --丐帮
		[3] = { id = 3, rate = 40, name = "#{XQ_MP_4}" },    --武当
		[4] = { id = 4, rate = 50, name = "#{XQ_MP_5}" },    --峨眉
		[5] = { id = 5, rate = 60, name = "#{XQ_MP_6}" },    --星宿
		[6] = { id = 6, rate = 70, name = "#{XQ_MP_7}" },    --天龙
		[7] = { id = 7, rate = 80, name = "#{XQ_MP_8}" },    --天山
		[8] = { id = 8, rate = 90, name = "#{XQ_MP_9}" },    --逍遥
        [9] = { id = 9, rate = 0, name = "" },         --无门派
		[10] = { id = 10, rate = 100, name = "#{XQ_MP_10}" },  --慕容
		[11] = { id = 11, rate = 100, name = "#{XMPTM_130123_05}" },  --唐门
		[12] = { id = 12, rate = 100, name = "#{XMPGG_160524_02}" },  --鬼谷
        [13] = { id = 13, rate = 100, name = "#{XQ_MP_15}" },  --桃花岛
		[14] = { id = 14, rate = 100, name = "#{XMPHM_210604_01}" },
		[15] = { id = 15, rate = 100, name = "#{GMGameInterface_Script_DataPool_Info_ERenGu}" },--menpai15 mptodo
	}

	local strComplete = ""

	strComplete = "#{XQHLJ_101108_59}"..MenPaiList[AlreadyPlay[1]].name.."#{XQHLJ_101108_65}"..MenPaiList[AlreadyPlay[2]].name.."#{XQHLJ_101108_65}"..MenPaiList[AlreadyPlay[3]].name.."#{XQHLJ_101108_65}"..MenPaiList[AlreadyPlay[4]].name.."#{XQHLJ_101108_65}"..MenPaiList[AlreadyPlay[5]].name.."#{XQHLJ_101108_60}"

	return strComplete
end

function QuestLog_GetJFTXTarget( nSelIndex )
	local AlreadyPlay = {}

	AlreadyPlay[1] = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	AlreadyPlay[2] = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	AlreadyPlay[3] = DataPool:GetPlayerMission_Variable( nSelIndex, 4 )

	for i = 1, 3 do
		if AlreadyPlay[i] >= 100 then
			AlreadyPlay[i] = AlreadyPlay[i] - 100
		end
	end

	local MenPaiList = {
		[0] = { id = 0, rate = 10, name = "#{XQ_MP_1}" },    --少林
		[1] = { id = 1, rate = 20, name = "#{XQ_MP_2}" },    --明教
		[2] = { id = 2, rate = 30, name = "#{XQ_MP_3}" },    --丐帮
		[3] = { id = 3, rate = 40, name = "#{XQ_MP_4}" },    --武当
		[4] = { id = 4, rate = 50, name = "#{XQ_MP_5}" },    --峨眉
		[5] = { id = 5, rate = 60, name = "#{XQ_MP_6}" },    --星宿
		[6] = { id = 6, rate = 70, name = "#{XQ_MP_7}" },    --天龙
		[7] = { id = 7, rate = 80, name = "#{XQ_MP_8}" },    --天山
		[8] = { id = 8, rate = 90, name = "#{XQ_MP_9}" },    --逍遥
		[9] = { id = 9, rate = 0, name = "" },         --无门派
		[10] = { id = 10, rate = 100, name = "#{XQ_MP_10}" },  --慕容
		[11] = { id = 11, rate = 100, name = "#{XMPTM_130123_05}" },  --唐门
		[12] = { id = 12, rate = 100, name = "#{XMPGG_160524_02}" },  --鬼谷
        [13] = { id = 13, rate = 100, name = "#{XQ_MP_15}" },  --桃花岛
		[14] = { id = 14, rate = 100, name = "#{XMPHM_210604_01}" },
		[15] = { id = 15, rate = 100, name = "#{GMGameInterface_Script_DataPool_Info_ERenGu}" },--menpai15 mptodo
	}

	local strComplete = ""

	strComplete = "#{FJTX_140227_18}"..MenPaiList[AlreadyPlay[1]].name .. "#W、#G".. MenPaiList[AlreadyPlay[2]].name.."#W、#G"..MenPaiList[AlreadyPlay[3]].name .."#{FJTX_140227_72}"

	return strComplete
end

--shitu mission by yuanpeilong 201505
function QuestLog_GetShiFuTarget( nSelIndex )
	local AlreadyPlay = {}

	AlreadyPlay[1] = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	AlreadyPlay[2] = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	local scene_monster = {
		[1] = {sceneid = 8, monster = {[1]={x=140,y=91,name="西夏士兵"},[2]={x=108,y=277,name="一品堂前锋"},[3]={x=238,y=173,name="沙坡狼"}},},
		[2] = {sceneid = 24, monster = {[1]={x=164,y=185,name="风豹"},[2]={x=87,y=245,name="风狼"}},},
		[3] = {sceneid = 18, monster = {[1]={x=37,y=129,name="秦家寨喽啰"},[2]={x=184,y=66,name="灰熊"},[3]={x=240,y=262,name="西北狼"}},},
		[4] = {sceneid = 25, monster = {[1]={x=47,y=104,name="雪狼"},[2]={x=158,y=70,name="狼族勇士"},[3]={x=138,y=236,name="狼族头"}},},
		[5] = {sceneid = 26, monster = {[1]={x=76,y=185,name="花岗石人"},[2]={x=167,y=196,name="石人偃师"},[3]={x=185,y=99,name="狼蛛"}},},
		[6] = {sceneid = 20, monster = {[1]={x=78,y=246,name="闪电马匪"},[2]={x=40,y=45,name="打草谷宋兵"},[3]={x=273,y=156,name="弯刀马匪"}},},
		[7] = {sceneid = 27, monster = {[1]={x=57,y=73,name="剧毒狼蛛"},[2]={x=87,y=258,name="龙血石人"},[3]={x=222,y=213,name="偃师护法"}},},
		[8] = {sceneid = 28, monster = {[1]={x=102,y=271,name="黑苗战士"},[2]={x=182,y=210,name="藤甲勇士"},[3]={x=193,y=95,name="丛林蜂"}},},
		[9] = {sceneid = 29, monster = {[1]={x=37,y=198,name="万劫修罗"},[2]={x=265,y=83,name="阿鼻修罗"},[3]={x=205,y=208,name="厄修罗"}},},
	}

	if AlreadyPlay[1] < 1 or AlreadyPlay[1] > table.getn(scene_monster) then
		return
	end

	if AlreadyPlay[2] < 1 or AlreadyPlay[2] > table.getn(scene_monster[AlreadyPlay[1]].monster) then
		return
	end

	local strComplete = ScriptGlobal_Format("#{STRW_150514_69}", GetSceneNameByID(scene_monster[AlreadyPlay[1]].sceneid),scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].name,
						scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].x, scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].y, scene_monster[AlreadyPlay[1]].sceneid)

	return strComplete
end

--shitu mission by yuanpeilong 201505
function QuestLog_GetTuDiTarget( nSelIndex )
	local AlreadyPlay = {}

	AlreadyPlay[1] = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	AlreadyPlay[2] = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	local scene_monster = {
		[1] = {sceneid = 8, monster = {[1]={x=140,y=91,name="西夏士兵"},[2]={x=108,y=277,name="一品堂前锋"},[3]={x=238,y=173,name="沙坡狼"}},},
		[2] = {sceneid = 24, monster = {[1]={x=164,y=185,name="风豹"},[2]={x=87,y=245,name="风狼"}},},
		[3] = {sceneid = 18, monster = {[1]={x=37,y=129,name="秦家寨喽啰"},[2]={x=184,y=66,name="灰熊"},[3]={x=240,y=262,name="西北狼"}},},
		[4] = {sceneid = 25, monster = {[1]={x=47,y=104,name="雪狼"},[2]={x=158,y=70,name="狼族勇士"},[3]={x=138,y=236,name="狼族头"}},},
		[5] = {sceneid = 26, monster = {[1]={x=76,y=185,name="花岗石人"},[2]={x=167,y=196,name="石人偃师"},[3]={x=185,y=99,name="狼蛛"}},},
		[6] = {sceneid = 20, monster = {[1]={x=78,y=246,name="闪电马匪"},[2]={x=40,y=45,name="打草谷宋兵"},[3]={x=273,y=156,name="弯刀马匪"}},},
		[7] = {sceneid = 27, monster = {[1]={x=57,y=73,name="剧毒狼蛛"},[2]={x=87,y=258,name="龙血石人"},[3]={x=222,y=213,name="偃师护法"}},},
		[8] = {sceneid = 28, monster = {[1]={x=102,y=271,name="黑苗战士"},[2]={x=182,y=210,name="藤甲勇士"},[3]={x=193,y=95,name="丛林蜂"}},},
		[9] = {sceneid = 29, monster = {[1]={x=37,y=198,name="万劫修罗"},[2]={x=265,y=83,name="阿鼻修罗"},[3]={x=205,y=208,name="厄修罗"}},},
	}

	if AlreadyPlay[1] < 1 or AlreadyPlay[1] > table.getn(scene_monster) then
		return
	end

	if AlreadyPlay[2] < 1 or AlreadyPlay[2] > table.getn(scene_monster[AlreadyPlay[1]].monster) then
		return
	end

	local strComplete = ScriptGlobal_Format("#{STRW_150514_70}", GetSceneNameByID(scene_monster[AlreadyPlay[1]].sceneid),scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].name,
						scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].x, scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].y, scene_monster[AlreadyPlay[1]].sceneid)

	return strComplete
end

--shitu mission by yuanpeilong 201507
function QuestLog_GetShiFuTrack( nSelIndex )
	local AlreadyPlay = {}

	AlreadyPlay[1] = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	AlreadyPlay[2] = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local scene_monster = {
		[1] = {sceneid = 8, monster = {[1]={x=140,y=91,name="西夏士兵"},[2]={x=108,y=277,name="一品堂前锋"},[3]={x=238,y=173,name="沙坡狼"}},},
		[2] = {sceneid = 24, monster = {[1]={x=164,y=185,name="风豹"},[2]={x=87,y=245,name="风狼"}},},
		[3] = {sceneid = 18, monster = {[1]={x=37,y=129,name="秦家寨喽啰"},[2]={x=184,y=66,name="灰熊"},[3]={x=240,y=262,name="西北狼"}},},
		[4] = {sceneid = 25, monster = {[1]={x=47,y=104,name="雪狼"},[2]={x=158,y=70,name="狼族勇士"},[3]={x=138,y=236,name="狼族头"}},},
		[5] = {sceneid = 26, monster = {[1]={x=76,y=185,name="花岗石人"},[2]={x=167,y=196,name="石人偃师"},[3]={x=185,y=99,name="狼蛛"}},},
		[6] = {sceneid = 20, monster = {[1]={x=78,y=246,name="闪电马匪"},[2]={x=40,y=45,name="打草谷宋兵"},[3]={x=273,y=156,name="弯刀马匪"}},},
		[7] = {sceneid = 27, monster = {[1]={x=57,y=73,name="剧毒狼蛛"},[2]={x=87,y=258,name="龙血石人"},[3]={x=222,y=213,name="偃师护法"}},},
		[8] = {sceneid = 28, monster = {[1]={x=102,y=271,name="黑苗战士"},[2]={x=182,y=210,name="藤甲勇士"},[3]={x=193,y=95,name="丛林蜂"}},},
		[9] = {sceneid = 29, monster = {[1]={x=37,y=198,name="万劫修罗"},[2]={x=265,y=83,name="阿鼻修罗"},[3]={x=205,y=208,name="厄修罗"}},},
	}

	if AlreadyPlay[1] < 1 or AlreadyPlay[1] > table.getn(scene_monster) then
		return
	end

	if AlreadyPlay[2] < 1 or AlreadyPlay[2] > table.getn(scene_monster[AlreadyPlay[1]].monster) then
		return
	end

	local strComplete = ScriptGlobal_Format("#{STRW_150514_117}", GetSceneNameByID(scene_monster[AlreadyPlay[1]].sceneid),scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].name,
						scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].x, scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].y, scene_monster[AlreadyPlay[1]].sceneid, num)

	return strComplete
end

--shitu mission by yuanpeilong 201507
function QuestLog_GetTuDiTrack( nSelIndex )
	local AlreadyPlay = {}

	AlreadyPlay[1] = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	AlreadyPlay[2] = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local scene_monster = {
		[1] = {sceneid = 8, monster = {[1]={x=140,y=91,name="西夏士兵"},[2]={x=108,y=277,name="一品堂前锋"},[3]={x=238,y=173,name="沙坡狼"}},},
		[2] = {sceneid = 24, monster = {[1]={x=164,y=185,name="风豹"},[2]={x=87,y=245,name="风狼"}},},
		[3] = {sceneid = 18, monster = {[1]={x=37,y=129,name="秦家寨喽啰"},[2]={x=184,y=66,name="灰熊"},[3]={x=240,y=262,name="西北狼"}},},
		[4] = {sceneid = 25, monster = {[1]={x=47,y=104,name="雪狼"},[2]={x=158,y=70,name="狼族勇士"},[3]={x=138,y=236,name="狼族头"}},},
		[5] = {sceneid = 26, monster = {[1]={x=76,y=185,name="花岗石人"},[2]={x=167,y=196,name="石人偃师"},[3]={x=185,y=99,name="狼蛛"}},},
		[6] = {sceneid = 20, monster = {[1]={x=78,y=246,name="闪电马匪"},[2]={x=40,y=45,name="打草谷宋兵"},[3]={x=273,y=156,name="弯刀马匪"}},},
		[7] = {sceneid = 27, monster = {[1]={x=57,y=73,name="剧毒狼蛛"},[2]={x=87,y=258,name="龙血石人"},[3]={x=222,y=213,name="偃师护法"}},},
		[8] = {sceneid = 28, monster = {[1]={x=102,y=271,name="黑苗战士"},[2]={x=182,y=210,name="藤甲勇士"},[3]={x=193,y=95,name="丛林蜂"}},},
		[9] = {sceneid = 29, monster = {[1]={x=37,y=198,name="万劫修罗"},[2]={x=265,y=83,name="阿鼻修罗"},[3]={x=205,y=208,name="厄修罗"}},},
	}

	if AlreadyPlay[1] < 1 or AlreadyPlay[1] > table.getn(scene_monster) then
		return
	end

	if AlreadyPlay[2] < 1 or AlreadyPlay[2] > table.getn(scene_monster[AlreadyPlay[1]].monster) then
		return
	end

	local strComplete = ScriptGlobal_Format("#{STRW_150514_118}", GetSceneNameByID(scene_monster[AlreadyPlay[1]].sceneid),scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].name,
						scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].x, scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].y, scene_monster[AlreadyPlay[1]].sceneid, num)

	return strComplete
end

--20150701-七夕交互任务-by yuanpeilong
function QuestLog_Get2015QiXiJiaoHuTarget( nSelIndex )
	local AlreadyPlay = {}

	local ss = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	AlreadyPlay[1] = 4--math.mod(math.floor(ss/100),100)
	AlreadyPlay[2] = math.mod(ss,100)

	local scene_monster = {
		[1] = {sceneid = 24, monster = {[1]={x=102,y=99,name="野人山花农"},[2]={x=225,y=90,name="上关村花农"},[3]={x=98,y=224,name="茶马道花农"},[4]={x=204,y=223,name="磁沙田花农"}},},
		[2] = {sceneid = 4,  monster = {[1]={x=220,y=218,name="南驿道花农"},[2]={x=215,y=109,name="马山镇花农"},[3]={x=117,y=93,name="宋军水寨花农"},[4]={x=92,y=208,name="鼋头渚花农"}},},
		[3] = {sceneid = 18, monster = {[1]={x=97,y=113,name="穆柯湖花农"},[2]={x=230,y=121,name="雁门关花农"},[3]={x=90,y=211,name="秦家寨花农"},[4]={x=209,y=237,name="狼牙口花农"}},},
		[4] = {sceneid = 121, monster = {[1]={x=68,y=86,name="香樟林花农"},[2]={x=196,y=107,name="白堤花农"},[3]={x=105,y=220,name="茶山花农"},[4]={x=204,y=199,name="苏堤花农"}},},
	}

	if AlreadyPlay[1] < 1 or AlreadyPlay[1] > table.getn(scene_monster) then
		return
	end

	if AlreadyPlay[2] < 1 or AlreadyPlay[2] > table.getn(scene_monster[AlreadyPlay[1]].monster) then
		return
	end
	--local strComplete = ScriptGlobal_Format("#{QXJH_150630_43}", GetSceneNameByID(scene_monster[AlreadyPlay[1]].sceneid),
	local strComplete = ScriptGlobal_Format("#{QXJH_150630_43}", "夜西湖",
						scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].x, scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].y, 164, scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].name)

	return strComplete
end

-- [2017-元宵节猜灯谜活动]
function QuestLog_GetTarget_2017YXJCDM( nSelIndex )
	local Lanterns_Info =
	{
		{LanterID = 1, 	LanternDataID = "洛神牡丹灯笼", PosX = 270, PosZ = 342, aiType = 3, sceneID = {0} },
		{LanterID = 2, 	LanternDataID = "风花雪月灯笼", PosX = 266, PosZ = 342, aiType = 3, sceneID = {0} },
		{LanterID = 3, 	LanternDataID = "曲院风荷灯笼", PosX = 266, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 4, 	LanternDataID = "云栖竹径灯笼", PosX = 270, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 5, 	LanternDataID = "梅坞春早灯笼", PosX = 274, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 6, 	LanternDataID = "玉宇琼楼灯笼", PosX = 278, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 7, LanternDataID = "流水桃花灯笼", PosX = 282, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 8, LanternDataID = "三台云水灯笼", PosX = 286, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 9, LanternDataID = "湖滨晴雨灯笼", PosX = 290, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 10, LanternDataID = "柳浪闻莺灯笼", PosX = 290, PosZ = 342, aiType = 3, sceneID = {0} },
		{LanterID = 11, LanternDataID = "花港观鱼灯笼", PosX = 286, PosZ = 342, aiType = 3, sceneID = {0} },
	}
	
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 1 ) + 1
	if index > table.getn(Lanterns_Info) then
		index = table.getn(Lanterns_Info)
	end
	if index >= 1 and index <= table.getn(Lanterns_Info) then
		local str = ScriptGlobal_Format("#{YXCDM_161114_18}", Lanterns_Info[index].PosX, Lanterns_Info[index].PosZ, Lanterns_Info[index].LanternDataID, Lanterns_Info[index].LanternDataID)
		return str	
	else
		return ""
	end
	
end
function QuestLog_Complete_2017YXJCDM( nSelIndex)
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local str = ScriptGlobal_Format("#{YXCDM_161114_19}", index)
	return str	
end
function QuestLog_GetTrack_2017YXJCDM( nSelIndex )

	local Lanterns_Info =
	{
		{LanterID = 1, 	LanternDataID = "洛神牡丹灯笼", PosX = 270, PosZ = 342, aiType = 3, sceneID = {0} },
		{LanterID = 2, 	LanternDataID = "风花雪月灯笼", PosX = 266, PosZ = 342, aiType = 3, sceneID = {0} },
		{LanterID = 3, 	LanternDataID = "曲院风荷灯笼", PosX = 266, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 4, 	LanternDataID = "云栖竹径灯笼", PosX = 270, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 5, 	LanternDataID = "梅坞春早灯笼", PosX = 274, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 6, 	LanternDataID = "玉宇琼楼灯笼", PosX = 278, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 7, LanternDataID = "流水桃花灯笼", PosX = 282, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 8, LanternDataID = "三台云水灯笼", PosX = 286, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 9, LanternDataID = "湖滨晴雨灯笼", PosX = 290, PosZ = 337, aiType = 3, sceneID = {0} },
		{LanterID = 10, LanternDataID = "柳浪闻莺灯笼", PosX = 290, PosZ = 342, aiType = 3, sceneID = {0} },
		{LanterID = 11, LanternDataID = "花港观鱼灯笼", PosX = 286, PosZ = 342, aiType = 3, sceneID = {0} },
	}
	
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 1 ) + 1
	if index >= 1 and index <= table.getn(Lanterns_Info) then
		local str = ScriptGlobal_Format("#{YXCDM_161114_61}", Lanterns_Info[index].PosX, Lanterns_Info[index].PosZ, Lanterns_Info[index].LanternDataID, Lanterns_Info[index].LanternDataID)
		return str
	else
		return ""
	end
	
end

--新暗器引导任务
function QuestLog_NewDark_Target(nSelIndex)

	local strComplete = "#{JCLY_160411_191}"
	
	return strComplete
	
end
function QuestLog_NewDark_Complete(nSelIndex)

	local Data1 = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local Data2 = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local Data3 = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	local Data4 = DataPool:GetPlayerMission_Variable( nSelIndex, 4 )

	local strComplete = ScriptGlobal_Format("#{JCLY_160411_192}", Data1).."#r"..ScriptGlobal_Format("#{JCLY_160411_193}", Data2).."#r"..ScriptGlobal_Format("#{JCLY_160411_194}", Data3).."#r"..ScriptGlobal_Format("#{JCLY_160411_195}", Data4)
	
	return strComplete
	
end

--20150701-七夕交互任务-by yuanpeilong
function QuestLog_Get2015QiXiJiaoHuTrack( nSelIndex )

	local AlreadyPlay = {}

	local ss = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	AlreadyPlay[1] = 4--math.mod(math.floor(ss/100),100)
	AlreadyPlay[2] = ss

	local scene_monster = {
		[1] = {sceneid = 24, monster = {[1]={x=102,y=99,name="野人山花农"},[2]={x=225,y=90,name="上关村花农"},[3]={x=98,y=224,name="茶马道花农"},[4]={x=204,y=223,name="磁沙田花农"}},},
		[2] = {sceneid = 4,  monster = {[1]={x=220,y=218,name="南驿道花农"},[2]={x=215,y=109,name="马山镇花农"},[3]={x=117,y=93,name="宋军水寨花农"},[4]={x=92,y=208,name="鼋头渚花农"}},},
		[3] = {sceneid = 18, monster = {[1]={x=97,y=113,name="穆柯湖花农"},[2]={x=230,y=121,name="雁门关花农"},[3]={x=90,y=211,name="秦家寨花农"},[4]={x=209,y=237,name="狼牙口花农"}},},
		[4] = {sceneid = 121, monster = {[1]={x=68,y=86,name="香樟林花农"},[2]={x=196,y=107,name="白堤花农"},[3]={x=105,y=220,name="茶山花农"},[4]={x=204,y=199,name="苏堤花农"}},},
	}

	if AlreadyPlay[1] < 1 or AlreadyPlay[1] > table.getn(scene_monster) then
		return
	end

	if AlreadyPlay[2] < 1 or AlreadyPlay[2] > table.getn(scene_monster[AlreadyPlay[1]].monster) then
		return
	end
	--local strComplete = ScriptGlobal_Format("#{QXJH_150630_43}", GetSceneNameByID(scene_monster[AlreadyPlay[1]].sceneid),
	local strComplete = ScriptGlobal_Format("#{QXJH_150630_378}", "夜西湖",
						scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].x, scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].y, 164, scene_monster[AlreadyPlay[1]].monster[AlreadyPlay[2]].name)


	return strComplete
end

function QuestLog_GetDAKATarget( nSelIndex )
	local pos =
{
	[1] = {
		[1] = {SceneID = 0, PosX = 153, PosZ = 158 ,SceneName = "洛阳"},
		[2] = {SceneID = 0, PosX = 295, PosZ = 260 ,SceneName = "洛阳"},
		[3] = {SceneID = 0, PosX = 226, PosZ = 419 ,SceneName = "洛阳"},
		[4] = {SceneID = 1, PosX = 367, PosZ = 171 ,SceneName = "苏州"},
		[5] = {SceneID = 1, PosX = 278, PosZ = 326 ,SceneName = "苏州"},
		[6] = {SceneID = 1, PosX = 181, PosZ = 355 ,SceneName = "苏州"},
	},
	[2] = {
		[1] = {SceneID = 2, PosX = 70, PosZ = 49 ,SceneName = "大理"},
		[2] = {SceneID = 2, PosX = 293, PosZ = 46 ,SceneName = "大理"},
		[3] = {SceneID = 2, PosX = 69, PosZ = 235 ,SceneName = "大理"},
		[4] = {SceneID = 18, PosX = 156, PosZ = 277 ,SceneName = "雁南"},
		[5] = {SceneID = 18, PosX = 250, PosZ = 82 ,SceneName = "雁南"},
		[6] = {SceneID = 18, PosX = 138, PosZ = 242 ,SceneName = "雁南"},
	},
	[3] = {
		[1] = {SceneID = 4, PosX = 168, PosZ = 189 ,SceneName = "太湖"},
		[2] = {SceneID = 4, PosX = 62, PosZ = 74 ,SceneName = "太湖"},
		[3] = {SceneID = 4, PosX = 100, PosZ = 175 ,SceneName = "太湖"},
		[4] = {SceneID = 30, PosX = 124, PosZ = 50 ,SceneName = "西湖"},
		[5] = {SceneID = 30, PosX = 246, PosZ = 193 ,SceneName = "西湖"},
		[6] = {SceneID = 30, PosX = 154, PosZ = 132 ,SceneName = "西湖"},
	},
}
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local sub = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	local city=pos[index][sub].SceneName;
	local posx=pos[index][sub].PosX;
	local posz=pos[index][sub].PosZ;
	local sceneid=pos[index][sub].SceneID;
	local strComplete = ScriptGlobal_Format("#{MBHTL_130906_27}", city, city, posx,posz,sceneid)


	return strComplete
end


function QuestLog_GetDrawTarget( nSelIndex )
    local level = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
    local pos = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
    local xInfant_DrawPos = {
    [1] = {
        [1] = {SceneID = 0, SceneName = "洛阳", PosX = 153, PosZ = 158},
        [2] = {SceneID = 0, SceneName = "洛阳", PosX = 295, PosZ = 260},
        [3] = {SceneID = 0, SceneName = "洛阳", PosX = 226, PosZ = 419},
        [4] = {SceneID = 1, SceneName = "苏州", PosX = 367, PosZ = 171},
        [5] = {SceneID = 1, SceneName = "苏州", PosX = 278, PosZ = 326},
        [6] = {SceneID = 1, SceneName = "苏州", PosX = 181, PosZ = 355},
    },
    [2] = {
        [1] = {SceneID = 2,SceneName = "大理", PosX = 70, PosZ = 49},
        [2] = {SceneID = 2,SceneName = "大理", PosX = 293, PosZ = 46},
        [3] = {SceneID = 2,SceneName = "大理", PosX = 69, PosZ = 235},
        [4] = {SceneID = 18,SceneName = "雁南", PosX = 156, PosZ = 277},
        [5] = {SceneID = 18,SceneName = "雁南", PosX = 250, PosZ = 82},
        [6] = {SceneID = 18,SceneName = "雁南", PosX = 138, PosZ = 242},
    },
    [3] = {
        [1] = {SceneID = 4,SceneName = "太湖", PosX = 168, PosZ = 189},
        [2] = {SceneID = 4,SceneName = "太湖", PosX = 62, PosZ = 74},
        [3] = {SceneID = 4,SceneName = "太湖", PosX = 100, PosZ = 175},
        [4] = {SceneID = 30,SceneName = "西湖", PosX = 124, PosZ = 50},
        [5] = {SceneID = 30,SceneName = "西湖", PosX = 246, PosZ = 193},
        [6] = {SceneID = 30,SceneName = "西湖", PosX = 154, PosZ = 132},
    },
    }
    return ScriptGlobal_Format("#{SXPY_130826_79}", xInfant_DrawPos[level][pos].SceneName, xInfant_DrawPos[level][pos].PosX, xInfant_DrawPos[level][pos].PosZ, xInfant_DrawPos[level][pos].SceneID )
end

function QuestLog_GetMannerNPC( nSelIndex )
    local level = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
    local xMannerNPCTable =
    {
        [1] = {NPCName = "全小颜", PosX = 118,PosZ = 138},
        [2] = {NPCName = "曹小明", PosX = 118,PosZ = 132},
        [3] = {NPCName = "陆小祺", PosX = 127,PosZ = 132},
    }
    return ScriptGlobal_Format("#{SXPY_130826_109}", xMannerNPCTable[level].PosX, xMannerNPCTable[level].PosZ, xMannerNPCTable[level].NPCName )
end
--  是否是特殊任务, 任务状态不是记录在0号位置的.
function QuestLog_IsSpecialMission( index )
    --TT53675对于所有没有用missionparam第0位表示任务是否完成的任务，使用IsMissionSuccess判断任务是否完成
    local IsSpecial = 0
    local nScriptId = DataPool:GetPlayerMission_Display(index,7);

    for i, findId in SpecialMissionList do
          if nScriptId == findId then
             IsSpecial = 1
            break
        end
    end

    if nScriptId >= 1020000 and nScriptId <= 1029999 then --所有的探索配表任务都需要特殊处理
          IsSpecial = 1
    end

    return IsSpecial;
end

function QuestLog_GetXunBaoLeFanTianTarget( nMissionIndex )

    local pos =
{
    [1] = {
        [1] = {SceneID = 1, PosX = 366, PosZ = 170 ,SceneName = "苏州",SubName = "码头"},
        [2] = {SceneID = 1, PosX = 179, PosZ = 189 ,SceneName = "苏州",SubName = "文庙"},
        [3] = {SceneID = 1, PosX = 350, PosZ = 236 ,SceneName = "苏州",SubName = "欧冶子"},
    },
    [2] = {
        [1] = {SceneID = 0, PosX = 307, PosZ = 296 ,SceneName = "洛阳",SubName = "武器店"},
        [2] = {SceneID = 0, PosX = 145, PosZ = 182 ,SceneName = "洛阳",SubName = "月老"},
        [3] = {SceneID = 0, PosX = 179, PosZ = 258 ,SceneName = "洛阳",SubName = "镖局"},
    },
    [3] = {
        [1] = {SceneID = 2, PosX = 241, PosZ = 26  ,SceneName = "大理",SubName = "望苍台"},
        [2] = {SceneID = 2, PosX = 160, PosZ = 174 ,SceneName = "大理",SubName = "五华坛"},
        [3] = {SceneID = 2, PosX = 270, PosZ = 126 ,SceneName = "大理",SubName = "云飘飘"},
    },
}
    local index_suzhou  = 1
    local index_luoyang = 2
    local index_dali    = 3

    local sub_suzhou = DataPool:GetPlayerMission_Variable( nMissionIndex, 5 )
    local sub_luoyang = DataPool:GetPlayerMission_Variable( nMissionIndex, 6 )
    local sub_dali = DataPool:GetPlayerMission_Variable( nMissionIndex, 7 )

    local city_suzhou = pos[index_suzhou][sub_suzhou].SceneName;
    local posx_suzhou = pos[index_suzhou][sub_suzhou].PosX;
    local posz_suzhou = pos[index_suzhou][sub_suzhou].PosZ;
    local sceneid_suzhou = pos[index_suzhou][sub_suzhou].SceneID;
    local SubName_suzhou = pos[index_suzhou][sub_suzhou].SubName;

    local city_luoyang = pos[index_luoyang][sub_luoyang].SceneName;
    local posx_luoyang = pos[index_luoyang][sub_luoyang].PosX;
    local posz_luoyang = pos[index_luoyang][sub_luoyang].PosZ;
    local sceneid_luoyang = pos[index_luoyang][sub_luoyang].SceneID;
    local SubName_luoyang = pos[index_luoyang][sub_luoyang].SubName;

    local city_dali = pos[index_dali][sub_dali].SceneName;
    local posx_dali = pos[index_dali][sub_dali].PosX;
    local posz_dali = pos[index_dali][sub_dali].PosZ;
    local sceneid_dali = pos[index_dali][sub_dali].SceneID;
    local SubName_dali = pos[index_dali][sub_dali].SubName;

    local strComplete = ScriptGlobal_Format("#{XBLFT_131112_38}",SubName_suzhou, posx_suzhou,posz_suzhou, SubName_luoyang, posx_luoyang,posz_luoyang,SubName_dali,posx_dali,posz_dali)

    return strComplete
end

function QuestLog_GetZhenFaTarget(nSelIndex,nScriptId)
	local strMain =""
	local nAdvance = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	if nScriptId == 891176 then
		local strBossName = ScriptGlobal_Format("#{JBGXW_150526_126}",nAdvance+1)
		strMain = ScriptGlobal_Format("#{JBGXW_150526_129}",nAdvance+1,nAdvance+1,strBossName)
	elseif nScriptId == 891177 then
		local strBossName = ScriptGlobal_Format("#{JBGXW_150526_125}",nAdvance+1)
		strMain =  ScriptGlobal_Format("#{JBGXW_150526_130}",nAdvance+1,nAdvance+1,strBossName)
	elseif nScriptId == 891178 then
		local strBossName = ScriptGlobal_Format("#{JBGXW_150526_127}",nAdvance+1)
		strMain = ScriptGlobal_Format("#{JBGXW_150526_131}",nAdvance+1,nAdvance+1,strBossName)
	elseif nScriptId == 891179 then
		local strBossName = ScriptGlobal_Format("#{JBGXW_150526_128}",nAdvance+1)
		strMain = ScriptGlobal_Format("#{JBGXW_150526_132}",nAdvance+1,nAdvance+1,strBossName)
	end

	return strMain

end


--七夕鹊桥任务
--function QuestLog_IsQiXiQueQiaoDate()
--	local StartDateTime = 20160801
--	local EndMissionTime= 20160814 
--	local CurTime = DataPool:GetServerDayTime();
--	if(CurTime >= StartDateTime and CurTime <= EndMissionTime) then
--		return 1
--	end
--	return 0
--end

--【2017九星神器每日任务】
function QuestLog_GetTarget_9_Start( nSelIndex )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	if num >= 10 then
		num = 10
	end	
	local strComplete = "#r"..ScriptGlobal_Format("#{JXMR_171027_05}", num)
	return strComplete
end

function QuestLog_BountyTaskComp( nSelIndex )
	local mid = DataPool : GetPlayerMission_Variable( nSelIndex, 1 )
	local tq,taskType,uiDesc,accDesc,p1,p2,p3,p4,p5,p6,taskDesc,compDesc = ZhanTuanInterface:GetBountyTaskDesc(mid)
	if compDesc~=nil then
		if taskType == 2 and mid ~= 13 and mid ~= 14 then
			local curKill = DataPool : GetPlayerMission_Variable( nSelIndex, 3 )
			compDesc = ScriptGlobal_Format(compDesc, tostring(curKill),tostring(p4))		
		elseif taskType == 3 and 11 ~= mid then
			local itemId = DataPool : GetPlayerMission_Variable( nSelIndex, 3 )
			local itemName = DataPool:Lua_GetItemNameByIndex(itemId)
			local needItemCount = DataPool : GetPlayerMission_Variable( nSelIndex, 4 )
			local have_count = PlayerPackage:Lua_GetUnLockItemCount(itemId)
			if 9 ~= mid or mid == 27 or mid == 28 or mid == 29 then
				local itemId2 = DataPool : GetPlayerMission_Variable( nSelIndex, 5 )
				have_count = have_count + PlayerPackage:Lua_GetUnLockItemCount(itemId2)
			end
			compDesc = ScriptGlobal_Format(compDesc, itemName, tostring(have_count), tostring(needItemCount))
		else 
			if DataPool : GetPlayerMission_Variable( nSelIndex, 0 ) == 1 then
				compDesc = ScriptGlobal_Format(compDesc, "1","1")
			else
				compDesc = ScriptGlobal_Format(compDesc, "0","1")
			end
		end
		return compDesc
	else
		return " "
	end
end

function QuestLog_BountyTaskAward( nSelIndex )
	QuestLog_Desc:AddTextElement("#Y奖励：#W")
		
	local mid = DataPool : GetPlayerMission_Variable( nSelIndex, 1 )
	local tq,taskType,uiDesc,accDesc,p1,p2,p3,p4,p5,p6,taskDesc,compDesc = ZhanTuanInterface:GetBountyTaskDesc(mid)
		
	local rewardDisplayItem ={
	[1] = {item1=39923218,count1=10,item2=nil,count2=nil,},
	[2] = {item1=39923218,count1=20,item2={39923215,39923216,39923217},count2={1,1,1},},
	[3] = {item1=39923218,count1=20,item2={39923215,39923216,39923217},count2={2,2,2},},
	[4] = {item1=39923218,count1=20,item2={39923215,39923216,39923217},count2={2,2,2},},
	}
	
	local theAction1 = DataPool:CreateActionItemForShow(rewardDisplayItem[tq].item1, rewardDisplayItem[tq].count1)
	local ActionID1=theAction1:GetID()
	QuestLog_Desc:AddActionElement(ActionID1, rewardDisplayItem[tq].count1, 0, 0)
	
	if tq > 1 then
		local week1end,week2end = DataPool:Lua_XinFuXuanShangWeekEndDate()
		local weekidx = 1
		local nCurDay = DataPool:GetServerDayTime()
		if nCurDay <= week1end then
			weekidx = 1
		elseif nCurDay <= week2end then
			weekidx = 2
		else
			weekidx = 3
		end
		local theAction2 = DataPool:CreateActionItemForShow(rewardDisplayItem[tq].item2[weekidx], rewardDisplayItem[tq].count2[weekidx])
		local ActionID2=theAction2:GetID()	
		QuestLog_Desc:AddActionElement(ActionID2, rewardDisplayItem[tq].count2[weekidx], 0, 0)
	end
	
end

function QuestLog_BountyTaskDesc( nSelIndex )
	local mid = DataPool : GetPlayerMission_Variable( nSelIndex, 1 )
	local tq,taskType,uiDesc,accDesc,p1,p2,p3,p4,p5,p6,taskDesc,compDesc = ZhanTuanInterface:GetBountyTaskDesc(mid)
	if mid == 10 or mid == 24 then
		local itemId = DataPool : GetPlayerMission_Variable( nSelIndex, 3 )
		local itemName = DataPool:Lua_GetItemNameByIndex(itemId)
		local needItemCount = DataPool : GetPlayerMission_Variable( nSelIndex, 4 )
		taskDesc = ScriptGlobal_Format(taskDesc, tostring(needItemCount), itemName)
	end	
	if mid == 9 then
		local itemId = DataPool : GetPlayerMission_Variable( nSelIndex, 3 )
		local itemName = DataPool:Lua_GetItemNameByIndex(itemId)
		taskDesc = ScriptGlobal_Format(taskDesc, itemName )
	end
	return taskDesc
end

--2022新天外跑环任务链 --Start
function QuestLog_GetTarget_2022XTWBDPH_easy( nSelIndex )
	local MonsterInfo = {
		--任务链1
		[1] = {
			[1]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[2]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[3]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},	
			[4]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[5]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[6]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[7]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[8]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[9]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43},	
			[10]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
		},
		--任务链2
		[2] = {
			[1]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[2]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[3]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[4]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[5]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[6]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[7]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[8]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[9]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[10]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47},
		},
		--任务链3
		[3] = {
			[1]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[2]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[3]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[4]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},
			[5]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[6]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47},
			[7]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[8]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},
			[9]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[10]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47},
		},	
		--任务链1
		[4] = {
			[1]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[2]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[3]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},	
			[4]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[5]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[6]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[7]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[8]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[9]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43},	
			[10]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
		},		
	}
	
	local StrInfo = {
		--任务链1
		[1] = "#{PHRW_220905_15}",
		--任务链2
		[2] = "#{PHRW_220905_25}",
		--任务链3
		[3] = "#{PHRW_220905_35}",
		--任务链1
		[4] = "#{PHRW_220905_15}",		
	}
	
	--1号参数：杀怪数；2号参数：任务链序号；3号参数：当前环数
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local subindex = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	
	local str = StrInfo[index]
	if str == nil then
		return ""
	end
	
	if MonsterInfo[index] == nil or MonsterInfo[index][subindex] == nil then
		return ""
	end
	local info = MonsterInfo[index][subindex]
	
	if finish == 1 and subindex == 10 then
		local str1 = "#{PHRW_220905_50}"
		return str1
	else
		local retStr = ScriptGlobal_Format(str, GetSceneNameByID(info.scene), info.posx, info.posz, info.res, TServerUI:GetMonsterNamebyDataID(info.monsterid))
		return retStr	
	end
end
function QuestLog_Complete_2022XTWBDPH_easy( nSelIndex)
	local MonsterInfo = {
		--任务链1
		[1] = {
			[1]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[2]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[3]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},	
			[4]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[5]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[6]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[7]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[8]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[9]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43},	
			[10]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
		},
		--任务链2
		[2] = {
			[1]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[2]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[3]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[4]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[5]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[6]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[7]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[8]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[9]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[10]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47},
		},
		--任务链3
		[3] = {
			[1]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[2]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[3]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[4]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},
			[5]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[6]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47},
			[7]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[8]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},
			[9]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[10]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47},
		},	
		--任务链1
		[4] = {
			[1]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[2]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[3]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},	
			[4]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[5]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[6]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[7]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[8]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[9]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43},	
			[10]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
		},
	}
	local StrInfo = {
		--任务链1
		[1] = {[1]="#{PHRW_220905_16}", [2]="#{PHRW_220905_17}",},
		--任务链2
		[2] = {[1]="#{PHRW_220905_26}", [2]="#{PHRW_220905_27}",},
		--任务链3
		[3] = {[1]="#{PHRW_220905_36}", [2]="#{PHRW_220905_37}",},
		--任务链1
		[4] = {[1]="#{PHRW_220905_16}", [2]="#{PHRW_220905_17}",},		
	}
	
	--1号参数：杀怪数；2号参数：任务链序号；3号参数：当前环数
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local subindex = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )	
	
	local str = StrInfo[index]
	if str == nil then
		return ""
	end	

	if MonsterInfo[index] == nil or MonsterInfo[index][subindex] == nil then
		return ""
	end
	local info = MonsterInfo[index][subindex]
	
	if finish == 1 and subindex == 10 then
		local str1 = "\n".."#{PHRW_220905_51}"
		return str1	
	else
		local retStr = "\n"..ScriptGlobal_Format(str[1], subindex).."\n"..ScriptGlobal_Format(str[2], TServerUI:GetMonsterNamebyDataID(info.monsterid), num)
		return retStr
	end
end
function QuestLog_GetTrack_2022XTWBDPH_easy( nSelIndex, callByNeiGua )
	local MonsterInfo = {
		--任务链1
		[1] = {
			[1]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[2]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[3]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},	
			[4]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[5]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[6]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[7]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[8]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[9]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43},	
			[10]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
		},
		--任务链2
		[2] = {
			[1]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[2]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[3]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[4]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[5]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[6]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[7]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[8]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[9]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[10]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47},
		},
		--任务链3
		[3] = {
			[1]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[2]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[3]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47}, 
			[4]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},
			[5]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[6]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47},
			[7]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[8]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},
			[9]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[10]={monstertype=1, monsterid=51172, num=10, scene=15344, res=859, posx=47, posz=47},
		},	
		--任务链1
		[4] = {
			[1]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[2]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124}, 
			[3]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212},	
			[4]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43}, 
			[5]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[6]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[7]={monstertype=1, monsterid=51171, num=10, scene=15343, res=858, posx=203, posz=212}, 
			[8]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
			[9]={monstertype=1, monsterid=51169, num=10, scene=15345, res=860, posx=72, posz=43},	
			[10]={monstertype=1, monsterid=51170, num=10, scene=15343, res=858, posx=77, posz=124},
		},		
	}
	
	local StrInfo1 = {
		--任务链1
		[1] = "#{PHRW_220905_18}",
		--任务链2
		[2] = "#{PHRW_220905_28}",
		--任务链3
		[3] = "#{PHRW_220905_38}",
		--任务链1
		[4] = "#{PHRW_220905_18}",		
	}
	
	local StrInfo2 = {
		--任务链1
		[1] = {[1]="#{PHRW_220905_19}", [2]="#{PHRW_220905_20}",},
		--任务链2
		[2] = {[1]="#{PHRW_220905_29}", [2]="#{PHRW_220905_30}",},
		--任务链3
		[3] = {[1]="#{PHRW_220905_39}", [2]="#{PHRW_220905_40}",},
		--任务链1
		[4] = {[1]="#{PHRW_220905_19}", [2]="#{PHRW_220905_20}",},		
	}
	
	--1号参数：杀怪数；2号参数：任务链序号；3号参数：当前环数
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local subindex = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )	
	
	local str_1 = StrInfo1[index]
	if str_1 == nil then
		return ""
	end
	
	local str_2 = StrInfo2[index]
	if str_2 == nil then
		return "" 
	end	

	if MonsterInfo[index] == nil or MonsterInfo[index][subindex] == nil then
		return ""
	end
	local info = MonsterInfo[index][subindex]
	if callByNeiGua then
		return GetSceneNameByID(info.scene), info.posx, info.posz, TServerUI:GetMonsterNamebyDataID(info.monsterid), num, 10
	end

	if finish == 1 and subindex == 10 then
		local str1 = "#{PHRW_220905_52}"
		return str1
	else
		local str1 =  ScriptGlobal_Format(str_1, GetSceneNameByID(info.scene), info.posx, info.posz, info.res, TServerUI:GetMonsterNamebyDataID(info.monsterid))
		local str2 = "   "..ScriptGlobal_Format(str_2[1], subindex).."\n".."   "..ScriptGlobal_Format(str_2[2], TServerUI:GetMonsterNamebyDataID(info.monsterid), num)
		if str1~=nil and str2~=nil then
			return str1.."\n"..str2
		else
			return "Error-1"
		end
	end
	
end

function QuestLog_GetTarget_2022XTWBDPH_diff( nSelIndex )
	local MonsterInfo = {
		--任务链1
		[1] = {
			[1]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51}, 
			[2]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[3]={monstertype=1, monsterid=51179, num=10, scene=15341, res=856, posx=208, posz=168},	
			[4]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96}, 
			[5]={monstertype=2, monsterid=51168, num=1, scene=15340, res=855, posx=-1, posz=-1, posx1=187, posz1=139, posx2=183, posz2=39, posx3=68, posz3=120, posx4=145, posz4=170}, --Boss3
			[6]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[7]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96}, 
			[8]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83},
			[9]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51},	
			[10]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2
		},
		--任务链2
		[2] = {
			[1]={monstertype=1, monsterid=51177, num=10, scene=15342, res=857, posx=122, posz=193},
			[2]={monstertype=1, monsterid=51176, num=10, scene=15342, res=857, posx=212, posz=53}, 
			[3]={monstertype=1, monsterid=51177, num=10, scene=15342, res=857, posx=122, posz=193},	
			[4]={monstertype=2, monsterid=51166, num=1, scene=15342, res=857, posx=-1, posz=-1, posx1=103, posz1=84, posx2=163, posz2=217, posx3=37, posz3=122, posx4=225, posz4=124}, --Boss1
			[5]={monstertype=1, monsterid=51177, num=10, scene=15342, res=857, posx=122, posz=193}, 
			[6]={monstertype=1, monsterid=51176, num=10, scene=15342, res=857, posx=212, posz=53},
			[7]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[8]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51},
			[9]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2
			[10]={monstertype=1, monsterid=51179, num=10, scene=15341, res=856, posx=208, posz=168},	
		},
		--任务链3
		[3] = {
			[1]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51}, 
			[2]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[3]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 	
			[4]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96},  
			[5]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[6]={monstertype=2, monsterid=51168, num=1, scene=15340, res=855, posx=-1, posz=-1, posx1=187, posz1=139, posx2=183, posz2=39, posx3=68, posz3=120, posx4=145, posz4=170}, --Boss3
			[7]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[8]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2
			[9]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83},	
			[10]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51},
		},	
		--任务链4
		[4] = {
			[1]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[2]={monstertype=1, monsterid=51179, num=10, scene=15341, res=856, posx=208, posz=168}, 
			[3]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2	
			[4]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51}, 
			[5]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[6]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150},
			[7]={monstertype=2, monsterid=51168, num=1, scene=15340, res=855, posx=-1, posz=-1, posx1=187, posz1=139, posx2=183, posz2=39, posx3=68, posz3=120, posx4=145, posz4=170}, --Boss3
			[8]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[9]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96},	
			[10]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150},
		},	
	}
	
	local StrInfo = {
		--任务链1
		[1] = {[1]="#{PHRW_220905_64}", [2]="#{PHRW_220905_65}"},
		--任务链2
		[2] = {[1]="#{PHRW_220905_78}", [2]="#{PHRW_220905_79}"},
		--任务链3
		[3] = {[1]="#{PHRW_220905_92}", [2]="#{PHRW_220905_93}"},
		--任务链4
		[4] = {[1]="#{PHRW_220905_106}", [2]="#{PHRW_220905_107}"},	
	}
	
	--1号参数：杀怪数；2号参数：任务链序号；3号参数：当前环数
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local subindex = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	
	if MonsterInfo[index] == nil or MonsterInfo[index][subindex] == nil then
		return ""
	end
	local info = MonsterInfo[index][subindex]
	
	if StrInfo[index] == nil or StrInfo[index][info.monstertype] == nil then
		return ""
	end
	local str = StrInfo[index][info.monstertype]
	
	if finish == 1 and subindex == 10 then
		local str1 = "#{PHRW_220905_50}"
		return str1
	else
		--普通怪
		if info.monstertype == 1 then
			local retStr = ScriptGlobal_Format(str, GetSceneNameByID(info.scene), info.posx, info.posz, info.res, TServerUI:GetMonsterNamebyDataID(info.monsterid))
			return retStr			
		--Boss
		elseif info.monstertype == 2 then
			local retStr = ScriptGlobal_Format(str, GetSceneNameByID(info.scene), info.posx1, info.posz1, info.res, info.posx2, info.posz2, info.posx3, info.posz3, info.posx4, info.posz4)
			return retStr			
		end
	end	
end
function QuestLog_Complete_2022XTWBDPH_diff( nSelIndex)
	local MonsterInfo = {
		--任务链1
		[1] = {
			[1]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51}, 
			[2]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[3]={monstertype=1, monsterid=51179, num=10, scene=15341, res=856, posx=208, posz=168},	
			[4]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96}, 
			[5]={monstertype=2, monsterid=51168, num=1, scene=15340, res=855, posx=-1, posz=-1, posx1=187, posz1=139, posx2=183, posz2=39, posx3=68, posz3=120, posx4=145, posz4=170}, --Boss3
			[6]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[7]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96}, 
			[8]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83},
			[9]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51},	
			[10]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2
		},
		--任务链2
		[2] = {
			[1]={monstertype=1, monsterid=51177, num=10, scene=15342, res=857, posx=122, posz=193},
			[2]={monstertype=1, monsterid=51176, num=10, scene=15342, res=857, posx=212, posz=53}, 
			[3]={monstertype=1, monsterid=51177, num=10, scene=15342, res=857, posx=122, posz=193},	
			[4]={monstertype=2, monsterid=51166, num=1, scene=15342, res=857, posx=-1, posz=-1, posx1=103, posz1=84, posx2=163, posz2=217, posx3=37, posz3=122, posx4=225, posz4=124}, --Boss1
			[5]={monstertype=1, monsterid=51177, num=10, scene=15342, res=857, posx=122, posz=193}, 
			[6]={monstertype=1, monsterid=51176, num=10, scene=15342, res=857, posx=212, posz=53},
			[7]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[8]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51},
			[9]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2
			[10]={monstertype=1, monsterid=51179, num=10, scene=15341, res=856, posx=208, posz=168},	
		},
		--任务链3
		[3] = {
			[1]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51}, 
			[2]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[3]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 	
			[4]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96},  
			[5]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[6]={monstertype=2, monsterid=51168, num=1, scene=15340, res=855, posx=-1, posz=-1, posx1=187, posz1=139, posx2=183, posz2=39, posx3=68, posz3=120, posx4=145, posz4=170}, --Boss3
			[7]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[8]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2
			[9]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83},	
			[10]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51},
		},	
		--任务链4
		[4] = {
			[1]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[2]={monstertype=1, monsterid=51179, num=10, scene=15341, res=856, posx=208, posz=168}, 
			[3]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2	
			[4]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51}, 
			[5]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[6]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150},
			[7]={monstertype=2, monsterid=51168, num=1, scene=15340, res=855, posx=-1, posz=-1, posx1=187, posz1=139, posx2=183, posz2=39, posx3=68, posz3=120, posx4=145, posz4=170}, --Boss3
			[8]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[9]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96},	
			[10]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150},
		},	
	}
	
	local StrInfo = {
		--任务链1
		[1] = {[1]="#{PHRW_220905_67}", [2]="#{PHRW_220905_68}", [3]="#{PHRW_220905_66}",},
		--任务链2
		[2] = {[1]="#{PHRW_220905_81}", [2]="#{PHRW_220905_82}", [3]="#{PHRW_220905_80}",},
		--任务链3
		[3] = {[1]="#{PHRW_220905_95}", [2]="#{PHRW_220905_96}", [3]="#{PHRW_220905_94}",},
		--任务链4
		[4] = {[1]="#{PHRW_220905_109}", [2]="#{PHRW_220905_110}", [3]="#{PHRW_220905_108}",},		
	}
	
	--1号参数：杀怪数；2号参数：任务链序号；3号参数：当前环数
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local subindex = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )	
	
	if MonsterInfo[index] == nil or MonsterInfo[index][subindex] == nil then
		return ""
	end
	local info = MonsterInfo[index][subindex]
	
	if StrInfo[index] == nil or StrInfo[index][info.monstertype] == nil then
		return ""
	end	
	
	local str = StrInfo[index][info.monstertype]
	
	if finish == 1 and subindex == 10 then
		local str1 = "\n".."#{PHRW_220905_51}"
		return str1	
	else
		local retStr = "\n"..ScriptGlobal_Format(StrInfo[index][3], subindex).."\n"..ScriptGlobal_Format(str, TServerUI:GetMonsterNamebyDataID(info.monsterid), num)
		return retStr
	end
end
function QuestLog_GetTrack_2022XTWBDPH_diff( nSelIndex, callByNeiGua )
	local MonsterInfo = {
		--任务链1
		[1] = {
			[1]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51}, 
			[2]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[3]={monstertype=1, monsterid=51179, num=10, scene=15341, res=856, posx=208, posz=168},	
			[4]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96}, 
			[5]={monstertype=2, monsterid=51168, num=1, scene=15340, res=855, posx=-1, posz=-1, posx1=187, posz1=139, posx2=183, posz2=39, posx3=68, posz3=120, posx4=145, posz4=170}, --Boss3
			[6]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[7]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96}, 
			[8]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83},
			[9]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51},	
			[10]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2
		},
		--任务链2
		[2] = {
			[1]={monstertype=1, monsterid=51177, num=10, scene=15342, res=857, posx=122, posz=193},
			[2]={monstertype=1, monsterid=51176, num=10, scene=15342, res=857, posx=212, posz=53}, 
			[3]={monstertype=1, monsterid=51177, num=10, scene=15342, res=857, posx=122, posz=193},	
			[4]={monstertype=2, monsterid=51166, num=1, scene=15342, res=857, posx=-1, posz=-1, posx1=103, posz1=84, posx2=163, posz2=217, posx3=37, posz3=122, posx4=225, posz4=124}, --Boss1
			[5]={monstertype=1, monsterid=51177, num=10, scene=15342, res=857, posx=122, posz=193}, 
			[6]={monstertype=1, monsterid=51176, num=10, scene=15342, res=857, posx=212, posz=53},
			[7]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[8]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51},
			[9]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2
			[10]={monstertype=1, monsterid=51179, num=10, scene=15341, res=856, posx=208, posz=168},	
		},
		--任务链3
		[3] = {
			[1]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51}, 
			[2]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[3]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 	
			[4]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96},  
			[5]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[6]={monstertype=2, monsterid=51168, num=1, scene=15340, res=855, posx=-1, posz=-1, posx1=187, posz1=139, posx2=183, posz2=39, posx3=68, posz3=120, posx4=145, posz4=170}, --Boss3
			[7]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[8]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2
			[9]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83},	
			[10]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51},
		},	
		--任务链4
		[4] = {
			[1]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[2]={monstertype=1, monsterid=51179, num=10, scene=15341, res=856, posx=208, posz=168}, 
			[3]={monstertype=2, monsterid=51167, num=1, scene=15341, res=856, posx=-1, posz=-1, posx1=107, posz1=31, posx2=71, posz2=207, posx3=145, posz3=226, posx4=172, posz4=117}, --Boss2	
			[4]={monstertype=1, monsterid=51173, num=10, scene=15341, res=856, posx=60, posz=51}, 
			[5]={monstertype=1, monsterid=51174, num=10, scene=15341, res=856, posx=188, posz=83}, 
			[6]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150},
			[7]={monstertype=2, monsterid=51168, num=1, scene=15340, res=855, posx=-1, posz=-1, posx1=187, posz1=139, posx2=183, posz2=39, posx3=68, posz3=120, posx4=145, posz4=170}, --Boss3
			[8]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150}, 
			[9]={monstertype=1, monsterid=51175, num=10, scene=15340, res=855, posx=160, posz=96},	
			[10]={monstertype=1, monsterid=51178, num=10, scene=15340, res=855, posx=129, posz=150},
		},	
	}
	
	local StrInfo1 = {
		--任务链1
		[1] = {[1]="#{PHRW_220905_69}", [2]="#{PHRW_220905_70}"},
		--任务链2
		[2] = {[1]="#{PHRW_220905_83}", [2]="#{PHRW_220905_84}"},
		--任务链3
		[3] = {[1]="#{PHRW_220905_97}", [2]="#{PHRW_220905_98}"},
		--任务链4
		[4] = {[1]="#{PHRW_220905_111}", [2]="#{PHRW_220905_112}"},	
	}
	
	local StrInfo2 = {
		--任务链1
		[1] = {[1]="#{PHRW_220905_72}", [2]="#{PHRW_220905_73}", [3]="#{PHRW_220905_71}",},
		--任务链2
		[2] = {[1]="#{PHRW_220905_86}", [2]="#{PHRW_220905_87}", [3]="#{PHRW_220905_85}",},
		--任务链3
		[3] = {[1]="#{PHRW_220905_100}", [2]="#{PHRW_220905_101}", [3]="#{PHRW_220905_99}",},
		--任务链4
		[4] = {[1]="#{PHRW_220905_114}", [2]="#{PHRW_220905_115}", [3]="#{PHRW_220905_113}",},		
	}
	
	--1号参数：杀怪数；2号参数：任务链序号；3号参数：当前环数
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local subindex = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )	

	if MonsterInfo[index] == nil or MonsterInfo[index][subindex] == nil then
		return ""
	end
	local info = MonsterInfo[index][subindex]
	if callByNeiGua then
		if info.posx == -1 then
			return GetSceneNameByID(info.scene), info["posx"..callByNeiGua], info["posz"..callByNeiGua], TServerUI:GetMonsterNamebyDataID(info.monsterid), num, 1
		else
			return GetSceneNameByID(info.scene), info.posx, info.posz, TServerUI:GetMonsterNamebyDataID(info.monsterid), num, 10
		end
	end
	
	if StrInfo1[index] == nil or StrInfo1[index][info.monstertype] == nil then
		return ""
	end
	local str_1 = StrInfo1[index][info.monstertype]

	if StrInfo2[index] == nil or StrInfo2[index][info.monstertype] == nil then
		return ""
	end	
	
	local str_2 = StrInfo2[index][info.monstertype]
	
	
	if finish == 1 and subindex == 10 then
		local str1 = "#{PHRW_220905_52}"
		return str1
	else
		local str1 = ""
		local str2 = ""
		--普通怪
		if info.monstertype == 1 then
			str1 = ScriptGlobal_Format(str_1, GetSceneNameByID(info.scene), info.posx, info.posz, info.res, TServerUI:GetMonsterNamebyDataID(info.monsterid))			
		--Boss
		elseif info.monstertype == 2 then
			str1 = ScriptGlobal_Format(str_1, GetSceneNameByID(info.scene), info.posx1, info.posz1, info.res, info.posx2, info.posz2, info.posx3, info.posz3, info.posx4, info.posz4)			
		end	
	
		str2 = "   "..ScriptGlobal_Format(StrInfo2[index][3], subindex).."\n".."   "..ScriptGlobal_Format(str_2, TServerUI:GetMonsterNamebyDataID(info.monsterid), num)
		
		if str1~=nil and str2~=nil then
			return str1.."\n"..str2
		else
			return "Error-2"
		end
	end		
end
--2022新天外跑环任务链 --End

--2022Q3新天外预热活动-ypl --Start
function QuestLog_GetTarget_2022Q3NTWYR(nSelIndex)
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )

	local str = {
		[1]="#{XTWYR_220729_62}", [2]="#{XTWYR_220729_311}", [3]="#{XTWYR_220729_312}",
	}
	
	local nStr = str[index]
	if nStr ~= nil then
		return nStr
	end
	
	return ""	
end

function QuestLog_Complete_2022Q3NTWYR(nSelIndex)
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	
	local nStr = ScriptGlobal_Format("#{XTWYR_220729_63}", num)
	return "\n"..nStr
end

function QuestLog_GetTrack_2022Q3NTWYR(nSelIndex)
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local num = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local index = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )

	local str = {
		[1]="#{XTWYR_220729_64}", [2]="#{XTWYR_220729_313}", [3]="#{XTWYR_220729_314}",
	}
	
	local nStr1 = str[index]
	if nStr1 == nil then
		return ""
	end
	
	local nStr2 = ScriptGlobal_Format("#{XTWYR_220729_65}", num)
	
	return nStr1.."\n".."   "..nStr2
end
--2022Q3新天外预热活动-ypl --End


function QuestLog_GetTarget_2023Anniversay(nSelIndex)
	local MenPaiList = {
		[0] = "#{QHRW_230317_86}",    --少林
		[1] = "#{QHRW_230317_91}",    --明教
		[2] = "#{QHRW_230317_88}",    --丐帮
		[3] = "#{QHRW_230317_84}",    --武当
		[4] = "#{QHRW_230317_90}",    --峨眉
		[5] = "#{QHRW_230317_87}",    --星宿
		[6] = "#{QHRW_230317_85}",    --天龙
		[7] = "#{QHRW_230317_89}",    --天山
		[8] = "#{QHRW_230317_83}",    --逍遥
		[9] = "#{GMGameInterface_Script_DataPool_Info_WuMenPai}",         --无门派
		[10] = "#{QHRW_230317_92}",  --慕容
		[11] = "#{QHRW_230317_93}",  --唐门
		[12] = "#{QHRW_230317_94}",  --鬼谷
        [13] = "#{QHRW_230317_95}",  --桃花岛
		[14] = "#{QHRW_230317_96}",	--绝情谷
		[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}",	--menpai15 mptodo
	}

	local menpaiID = DataPool:GetPlayerMission_Variable( nSelIndex, 5 )		--获取玩家门派ID
	
	local strTarget = ScriptGlobal_Format("#{QHRW_230317_36}", MenPaiList[menpaiID])
	return strTarget
end

--2023Q3宗门日常任务 begin
function QuestLog_GetRiChangMission_Str( mpindex, posindex )
	local rList = 
	{
		[0] = {npclink="#{ZMSW_230627_159}",caijiname="#{ZMSW_230627_173}",npcname="#{ZMSW_230627_366}",tnpcname="#{ZMSW_230627_383}",actionposlink="#{ZMSW_230627_229}",poslink={"#{ZMSW_230627_187}","#{ZMSW_230627_201}","#{ZMSW_230627_215}"},mpname = "少林"},
		[1] = {npclink="#{ZMSW_230627_160}",caijiname="#{ZMSW_230627_174}",npcname="#{ZMSW_230627_367}",tnpcname="#{ZMSW_230627_384}",actionposlink="#{ZMSW_230627_230}",poslink={"#{ZMSW_230627_188}","#{ZMSW_230627_202}","#{ZMSW_230627_216}"},mpname = "明教"},
		[2] = {npclink="#{ZMSW_230627_161}",caijiname="#{ZMSW_230627_175}",npcname="#{ZMSW_230627_368}",tnpcname="#{ZMSW_230627_385}",actionposlink="#{ZMSW_230627_231}",poslink={"#{ZMSW_230627_189}","#{ZMSW_230627_203}","#{ZMSW_230627_217}"},mpname = "丐帮"},
		[3] = {npclink="#{ZMSW_230627_162}",caijiname="#{ZMSW_230627_176}",npcname="#{ZMSW_230627_369}",tnpcname="#{ZMSW_230627_386}",actionposlink="#{ZMSW_230627_232}",poslink={"#{ZMSW_230627_190}","#{ZMSW_230627_204}","#{ZMSW_230627_218}"},mpname = "武当"},
		[4] = {npclink="#{ZMSW_230627_163}",caijiname="#{ZMSW_230627_177}",npcname="#{ZMSW_230627_370}",tnpcname="#{ZMSW_230627_387}",actionposlink="#{ZMSW_230627_233}",poslink={"#{ZMSW_230627_191}","#{ZMSW_230627_205}","#{ZMSW_230627_219}"},mpname = "峨眉"},
		[5] = {npclink="#{ZMSW_230627_164}",caijiname="#{ZMSW_230627_178}",npcname="#{ZMSW_230627_371}",tnpcname="#{ZMSW_230627_388}",actionposlink="#{ZMSW_230627_234}",poslink={"#{ZMSW_230627_192}","#{ZMSW_230627_206}","#{ZMSW_230627_220}"},mpname = "星宿"},
		[6] = {npclink="#{ZMSW_230627_165}",caijiname="#{ZMSW_230627_179}",npcname="#{ZMSW_230627_372}",tnpcname="#{ZMSW_230627_389}",actionposlink="#{ZMSW_230627_235}",poslink={"#{ZMSW_230627_193}","#{ZMSW_230627_207}","#{ZMSW_230627_221}"},mpname = "天龙"},
		[7] = {npclink="#{ZMSW_230627_166}",caijiname="#{ZMSW_230627_180}",npcname="#{ZMSW_230627_373}",tnpcname="#{ZMSW_230627_390}",actionposlink="#{ZMSW_230627_236}",poslink={"#{ZMSW_230627_194}","#{ZMSW_230627_208}","#{ZMSW_230627_222}"},mpname = "天山"},
		[8] = {npclink="#{ZMSW_230627_167}",caijiname="#{ZMSW_230627_181}",npcname="#{ZMSW_230627_374}",tnpcname="#{ZMSW_230627_391}",actionposlink="#{ZMSW_230627_237}",poslink={"#{ZMSW_230627_195}","#{ZMSW_230627_209}","#{ZMSW_230627_223}"},mpname = "逍遥"},
		[10] = {npclink="#{ZMSW_230627_168}",caijiname="#{ZMSW_230627_182}",npcname="#{ZMSW_230627_375}",tnpcname="#{ZMSW_230627_392}",actionposlink="#{ZMSW_230627_238}",poslink={"#{ZMSW_230627_196}","#{ZMSW_230627_210}","#{ZMSW_230627_224}"},mpname = "慕容"},
		[11] = {npclink="#{ZMSW_230627_169}",caijiname="#{ZMSW_230627_183}",npcname="#{ZMSW_230627_376}",tnpcname="#{ZMSW_230627_393}",actionposlink="#{ZMSW_230627_239}",poslink={"#{ZMSW_230627_197}","#{ZMSW_230627_211}","#{ZMSW_230627_225}"},mpname = "唐门"},
		[12] = {npclink="#{ZMSW_230627_170}",caijiname="#{ZMSW_230627_184}",npcname="#{ZMSW_230627_377}",tnpcname="#{ZMSW_230627_394}",actionposlink="#{ZMSW_230627_240}",poslink={"#{ZMSW_230627_198}","#{ZMSW_230627_212}","#{ZMSW_230627_226}"},mpname = "鬼谷"},
		[13] = {npclink="#{ZMSW_230627_171}",caijiname="#{ZMSW_230627_185}",npcname="#{ZMSW_230627_378}",tnpcname="#{ZMSW_230627_395}",actionposlink="#{ZMSW_230627_241}",poslink={"#{ZMSW_230627_199}","#{ZMSW_230627_213}","#{ZMSW_230627_227}"},mpname = "桃花岛"},
		[14] = {npclink="#{ZMSW_230627_172}",caijiname="#{ZMSW_230627_186}",npcname="#{ZMSW_230627_379}",tnpcname="#{ZMSW_230627_396}",actionposlink="#{ZMSW_230627_242}",poslink={"#{ZMSW_230627_200}","#{ZMSW_230627_214}","#{ZMSW_230627_228}"},mpname = "绝情谷"},
		[15] = {npclink="#{ZMSW_230627_400}",caijiname="#{ZMSW_230627_401}",npcname="#{ZMSW_230627_407}",tnpcname="#{ZMSW_230627_406}",actionposlink="#{ZMSW_230627_405}",poslink={"#{ZMSW_230627_402}","#{ZMSW_230627_403}","#{ZMSW_230627_404}"},mpname = "恶人谷"},--menpai15 mptodo
	}
	local tList = rList[mpindex]
	if tList ~= nil then
		if posindex ~= nil and tList.poslink[posindex] ~= nil then
			return tList.mpname,tList.npcname,tList.npclink,tList.caijiname,tList.actionposlink,tList.poslink[posindex],tList.tnpcname
		else
			return tList.mpname,tList.npcname,tList.npclink,tList.caijiname,tList.actionposlink,"",tList.tnpcname
		end
	end
	return "","","","","","",""
end
function QuestLog_GetTarget_RiChangMission( nMissionIndex )
	local strTarget = ""
	local paramType = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
	if paramType == 1 then
		local mpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		local mpname,npcname,npclink,caijiname,actionposlink,poslink,tnpcname = QuestLog_GetRiChangMission_Str( mpindex )
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTarget = ScriptGlobal_Format("#{ZMSW_230627_24}",npclink,selfnpclink)
	elseif paramType == 2 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTarget = ScriptGlobal_Format("#{ZMSW_230627_63}",selfcaijiname,selfnpclink)
	elseif paramType == 3 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local posindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex, posindex )
		strTarget = ScriptGlobal_Format("#{ZMSW_230627_80}",selfposlink,selfnpclink)
	elseif paramType == 4 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTarget = ScriptGlobal_Format("#{ZMSW_230627_102}",selfnpclink,selftnpcname)
	elseif paramType == 5 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTarget = ScriptGlobal_Format("#{ZMSW_230627_113}",selfnpclink)
	elseif paramType == 6 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTarget = ScriptGlobal_Format("#{ZMSW_230627_136}",selfactionposlink,selfnpclink)
	elseif paramType == 7 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTarget = ScriptGlobal_Format("#{ZMSW_230627_145}",selfnpclink)
	end
	return strTarget
end
function QuestLog_GetComplete_RiChangMission( nMissionIndex )	
	local strComplete = ""
	local paramCustom = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
	local paramType = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
	if paramType == 1 then
		local mpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		local mpname,npcname,npclink,caijiname,actionposlink,poslink,tnpcname = QuestLog_GetRiChangMission_Str( mpindex )
		strComplete = "\n"..ScriptGlobal_Format("#{ZMSW_230627_25}",npcname,paramCustom)
	elseif paramType == 2 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strComplete = "\n"..ScriptGlobal_Format("#{ZMSW_230627_64}",selfcaijiname,paramCustom)
	elseif paramType == 3 then
		strComplete = "\n"..ScriptGlobal_Format("#{ZMSW_230627_81}",paramCustom)
	elseif paramType == 4 then
		strComplete = "\n"..ScriptGlobal_Format("#{ZMSW_230627_103}",paramCustom)
	elseif paramType == 5 then
		strComplete = "\n"..ScriptGlobal_Format("#{ZMSW_230627_114}",paramCustom)
	elseif paramType == 6 then
		strComplete = "\n"..ScriptGlobal_Format("#{ZMSW_230627_137}",paramCustom)
	elseif paramType == 7 then
		strComplete = "\n"..ScriptGlobal_Format("#{ZMSW_230627_146}",paramCustom)
	end
	return strComplete
end
function QuestLog_GetTrack_RiChangMission( nMissionIndex )
	local strTrack = ""
	local paramCustom = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
	local paramType = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
	if paramType == 1 then
		local mpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		local mpname,npcname,npclink,caijiname,actionposlink,poslink,tnpcname = QuestLog_GetRiChangMission_Str( mpindex )
		strTrack = "#W"..ScriptGlobal_Format("#{ZMSW_230627_26}",npclink).."\n".."   "..ScriptGlobal_Format("#{ZMSW_230627_27}",npcname,paramCustom)
	elseif paramType == 2 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTrack = "#W"..ScriptGlobal_Format("#{ZMSW_230627_65}",selfcaijiname).."\n".."   "..ScriptGlobal_Format("#{ZMSW_230627_66}",selfcaijiname,paramCustom)
	elseif paramType == 3 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local posindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex, posindex )
		strTrack = "#W"..ScriptGlobal_Format("#{ZMSW_230627_82}",selfposlink).."\n".."   "..ScriptGlobal_Format("#{ZMSW_230627_83}",paramCustom)
	elseif paramType == 4 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTrack = "#W"..ScriptGlobal_Format("#{ZMSW_230627_104}",selfnpclink).."\n".."   "..ScriptGlobal_Format("#{ZMSW_230627_105}",paramCustom)
	elseif paramType == 5 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTrack = "#W"..ScriptGlobal_Format("#{ZMSW_230627_115}",selfnpclink).."\n".."   "..ScriptGlobal_Format("#{ZMSW_230627_116}",paramCustom)
	elseif paramType == 6 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfmpname,selfnpcname,selfnpclink,selfcaijiname,selfactionposlink,selfposlink,selftnpcname = QuestLog_GetRiChangMission_Str( selfmpindex )
		strTrack = "#W"..ScriptGlobal_Format("#{ZMSW_230627_138}",selfactionposlink).."\n".."   "..ScriptGlobal_Format("#{ZMSW_230627_139}",paramCustom)
	elseif paramType == 7 then
		strTrack = "#W".."#{ZMSW_230627_147}".."\n".."   "..ScriptGlobal_Format("#{ZMSW_230627_148}",paramCustom)
	end
	return strTrack
end
--2023Q3宗门日常任务 end

--2023Q3宗门预热活动 begin
function QuestLog_GetZongMenYuRe_Str( mpindex )
	local rList = 
	{
		[0] = {npcname="#{ZMYR_230803_65}",	mpname = "#{ZMYR_230803_79}"},
		[1] = {npcname="#{ZMYR_230803_66}",	mpname = "#{ZMYR_230803_80}"},
		[2] = {npcname="#{ZMYR_230803_67}",	mpname = "#{ZMYR_230803_81}"},
		[3] = {npcname="#{ZMYR_230803_68}",	mpname = "#{ZMYR_230803_82}"},
		[4] = {npcname="#{ZMYR_230803_69}", mpname = "#{ZMYR_230803_83}"},
		[5] = {npcname="#{ZMYR_230803_70}", mpname = "#{ZMYR_230803_84}"},
		[6] = {npcname="#{ZMYR_230803_71}", mpname = "#{ZMYR_230803_85}"},
		[7] = {npcname="#{ZMYR_230803_72}", mpname = "#{ZMYR_230803_86}"},
		[8] = {npcname="#{ZMYR_230803_73}", mpname = "#{ZMYR_230803_87}"},
		[10] = {npcname="#{ZMYR_230803_74}", mpname = "#{ZMYR_230803_88}"},
		[11] = {npcname="#{ZMYR_230803_75}", mpname = "#{ZMYR_230803_89}"},
		[12] = {npcname="#{ZMYR_230803_76}", mpname = "#{ZMYR_230803_90}"},
		[13] = {npcname="#{ZMYR_230803_77}", mpname = "#{ZMYR_230803_91}"},
		[14] = {npcname="#{ZMYR_230803_78}", mpname = "#{ZMYR_230803_92}"},
	}
	local tList = rList[mpindex]
	if tList ~= nil then
		return tList.npcname,tList.mpname
	end
	return "",""
end
function QuestLog_GetTarget_ZongMenYuRe( nMissionIndex )
	local strTarget = ""
	local npclist = {"#{ZMYR_230803_60}","#{ZMYR_230803_61}","#{ZMYR_230803_62}"}
	local paramType = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
	if paramType == 1 then
		local npcindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		local npclink = npclist[npcindex]
		if npclink ~= nil then
			strTarget = ScriptGlobal_Format("#{ZMYR_230803_58}",npclink)
		end
	elseif paramType == 2 then
		strTarget = "#{ZMYR_230803_63}"
	elseif paramType == 3 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfnpcname, selfmpname = QuestLog_GetZongMenYuRe_Str( selfmpindex )
		strTarget = ScriptGlobal_Format("#{ZMYR_230803_64}", selfnpcname, selfmpname)
	end
	return strTarget
end
function QuestLog_GetComplete_ZongMenYuRe( nMissionIndex )	
	local strComplete = ""
	local paramCustom = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
	local paramType = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
	if paramType == 1 then
		strComplete = ScriptGlobal_Format("#{ZMYR_230803_132}", paramCustom)
	elseif paramType == 2 then
		local paramIndex = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		strComplete = ScriptGlobal_Format("#{ZMYR_230803_133}", paramCustom, paramIndex)
	elseif paramType == 3 then
		strComplete = ScriptGlobal_Format("#{ZMYR_230803_134}", paramCustom)
	end
	return strComplete
end
function QuestLog_GetTrack_ZongMenYuRe( nMissionIndex )
	local strTrack = ""
	local npclist = {"#{ZMYR_230803_60}","#{ZMYR_230803_61}","#{ZMYR_230803_62}"}
	local paramCustom = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
	local paramType = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
	if paramType == 1 then
		local npcindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		local npclink = npclist[npcindex]
		if npclink ~= nil then
			strTrack = "#W"..ScriptGlobal_Format("#{ZMYR_230803_59}",npclink).."\n".."  "..ScriptGlobal_Format("#{ZMYR_230803_132}", paramCustom)
		end
	elseif paramType == 2 then
		local paramIndex = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		strTrack = "#W".."#{ZMYR_230803_93}".."\n".."  "..ScriptGlobal_Format("#{ZMYR_230803_130}", paramCustom, paramIndex)
	elseif paramType == 3 then
		local selfmpindex = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local selfnpcname, selfmpname = QuestLog_GetZongMenYuRe_Str( selfmpindex )
		strTrack = "#W"..ScriptGlobal_Format("#{ZMYR_230803_94}", selfnpcname, selfmpname).."\n".."  "..ScriptGlobal_Format("#{ZMYR_230803_134}", paramCustom)
	end
	return strTrack
end
--2023Q3宗门预热活动 end

--大话西游第一阶段主线剧情-ypl
function QuestLog_Complete_2024DHMission(nSelIndex)
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local nStep = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local num1 = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local num2 = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	local num3 = DataPool:GetPlayerMission_Variable( nSelIndex, 5 )
	
	local nStr = ""
	if nStep == 0 then
		nStr = "\n"..ScriptGlobal_Format("#{DHJDY_240521_189}", num1).."\n"..ScriptGlobal_Format("#{DHJDY_240521_196}", num3).."\n"..ScriptGlobal_Format("#{DHJDY_240521_190}", num2)
	elseif nStep == 1 then
		nStr = "\n"..ScriptGlobal_Format("#{DHJDY_240521_189}", num1)
	elseif nStep == 2 then
		nStr = "\n"..ScriptGlobal_Format("#{DHJDY_240521_196}", num3)		
	elseif nStep == 3 then
		nStr = "\n"..ScriptGlobal_Format("#{DHJDY_240521_190}", num2)
	elseif nStep == 4 then
		nStr = "\n"..ScriptGlobal_Format("#{DHJDY_240521_189}", num1).."\n"..ScriptGlobal_Format("#{DHJDY_240521_196}", num3).."\n"..ScriptGlobal_Format("#{DHJDY_240521_190}", num2)
	end

	return nStr
end
function QuestLog_GetTrack_2024DHMission(nSelIndex)	
	local finish = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local nStep = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local num1 = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local num2 = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	local num3 = DataPool:GetPlayerMission_Variable( nSelIndex, 5 )
	local nStr1 = "#{DHJDY_240521_132}"
	local nStr2 = ""
	if nStep == 0 then
		nStr2 = "#W".."  "..ScriptGlobal_Format("#{DHJDY_240521_189}", num1).."\n".."  "..ScriptGlobal_Format("#{DHJDY_240521_196}", num3).."\n".."  "..ScriptGlobal_Format("#{DHJDY_240521_190}", num2)
	elseif nStep == 1 then
		nStr2 = "#W".."  "..ScriptGlobal_Format("#{DHJDY_240521_189}", num1)
	elseif nStep == 2 then
		nStr2 = "#W".."  "..ScriptGlobal_Format("#{DHJDY_240521_196}", num3)		
	elseif nStep == 3 then
		nStr2 = "#W".."  "..ScriptGlobal_Format("#{DHJDY_240521_190}", num2)
	elseif nStep == 4 then
		nStr2 = "#W".."  "..ScriptGlobal_Format("#{DHJDY_240521_189}", num1).."\n".."  "..ScriptGlobal_Format("#{DHJDY_240521_196}", num3).."\n".."  "..ScriptGlobal_Format("#{DHJDY_240521_190}", num2)
	end	
	
	return nStr1.."\n"..nStr2
end

function QuestLog_GetFengYunDaKaComplete(nSelIndex) 
    local nProgress = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
    return ScriptGlobal_Format("#{FYDK_260129_55}", nProgress)
end
