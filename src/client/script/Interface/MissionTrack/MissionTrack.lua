-- 任务跟踪   author：houzhifang

local g_strWndName = "MissionTrack";

local g_dlgctrls = {};              --控件集合, noused
local MissionPucker = {};           --任务类型折叠标记, 1为不折叠, 0为折叠
local g_nNowCheck = 0;              --0:初始化，1:已接任务，2：可接任务
local g_LockState = 0;              --0:未锁定，1：已锁定
local LEVEL_TO_MY_LEVEL = 10000;    --如果任务等级为该值, 则玩家当前等级就是任务等级
local g_Temp_Mylevel = 1;           --一个玩家等级的临时变量, 主要用于擂台场景, 玩家等级是0的情况

local g_DiFu_Scene_Id = 77;         --地府场景ID
local g_nMissionNum = 20;           --最大任务个数

--TT53675对所有不符合规范，没有将missionparam第0位做为任务完成标志的任务脚本做特殊处理,需要特殊处理的任务脚本号列表：
local SpecialMissionList = {200006,200031}

--用于保留界面原始尺寸和位置信息
local g_MissionTrack_Frame_UnifiedSize;
local g_MissionTrack_Frame_UnifiedXPosition;
local g_MissionTrack_Frame_UnifiedYPosition;
local g_MissionTrack__Frame_AbsolutePosition;
local g_MissionTrack__Frame_AbsoluteSize;
local g_MissionTrack_Function_Frame_AbsolutePosition;
local g_MissionTrack_DragTitle_AbsolutePosition;
local g_MissionTrack_Close_AbsolutePosition;
local g_MissionTrack__CheckBox_Frame_AbsolutePosition;
local g_MissionTrack_Lock_AbsolutePosition;
local g_MissionTrack_UnLock_AbsolutePosition;

--特写任务追踪内容，实在没办法了，居然要表格任务批量特写，对不住了--quyan
local g_MissionTrack_Display_Special_Process =  --师门援助系列
{{missionIndex = 1010220, missionTargetStr = "#{MIS_Track_1}"},
{missionIndex = 1010221, missionTargetStr = "#{MIS_Track_2}"},
{missionIndex = 1010222, missionTargetStr = "#{MIS_Track_3}"},
{missionIndex = 1010223, missionTargetStr = "#{MIS_Track_4}"},
{missionIndex = 1010224, missionTargetStr = "#{MIS_Track_5}"},
{missionIndex = 1010225, missionTargetStr = "#{MIS_Track_6}"},
{missionIndex = 1010226, missionTargetStr = "#{MIS_Track_7}"},
{missionIndex = 1010227, missionTargetStr = "#{MIS_Track_8}"},
{missionIndex = 1010228, missionTargetStr = "#{MIS_Track_9}"},
{missionIndex = 1018880, missionTargetStr = "#{MIS_Track_10}"},
}

local g_NeedPopUITip = 1
local g_ShowRect = 0
local g_CurGuide = -1;

--生育系统成长任务相关内容
local g_MissionTrack_Infant_SubMissionTypeEnum = {BaiFang=1, Caiji=2, DingDianYinDao=3, XunWu=4, BuZhuo=5,}

local g_MissionTrack_Infant_MissionType_Index = 1
local g_MissionTrack_Infant_baozhuang_Index = 2
local g_MissionTrack_Infant_Mission_Index = 3

-- 帮会交互设计
-- local g_GuildInteractiveMissionTrack = {
-- 	"#W前往#G帮会城市（%d，%d）#W、#G（%d，%d）#W、#G（%d，%d）#W、#G（%d，%d）#W、#G（%d，%d）#W等处，救治5名受伤的帮众。",
-- 	"#{BHDR_140528_149}",
-- 	"",
-- 	"",
-- 	"",
-- }
-- local g_GuildInteractiveMission_MisType = 6				-- 任务类型(子任务ID)
-- -- 任务1
-- local g_GuildInteractiveMission1_CustomNum = 1			-- 任务完成情况
-- local g_GuildInteractiveMission1_PosIndexOne = 2		-- 第一个伤员的位置索引
-- local g_GuildInteractiveMission1_PosIndexTwo = 3		-- 第二个伤员的位置索引
-- local g_GuildInteractiveMission1_PosIndexThree = 4		-- 第三个伤员的位置索引
-- local g_GuildInteractiveMission1_PosIndexFour = 5		-- 第四个伤员的位置索引
-- local g_GuildInteractiveMission1_PosIndexFive = 7		-- 第五个伤员的位置索引
-- -- 任务2
-- local g_GuildInteractiveMission2_PosIndex = 4			-- 起始坐标点索引

local g_MissionTrack_Infant_tips = {
														BaiFang = {"#{CZRW_130822_147}",
																			 "#{CZRW_130822_147}",
																			 "#{CZRW_130822_147}",
																			 "#{CZRW_130822_147}",},

														Caiji = {"#{CZRW_130822_149}",
																		 "#{CZRW_130822_149}",
																		 "#{CZRW_130822_149}",
																		 "#{CZRW_130822_149}",
																		},

														DingDianYinDao = {"#{CZRW_130822_153}",
																							"#{CZRW_130822_155}",
																							"#{CZRW_130822_157}",
																							"#{CZRW_130822_159}",},

														XunWu = {"#{CZRW_130822_151}",
																		 "#{CZRW_130822_151}",
																		 "#{CZRW_130822_151}",
																		 "#{CZRW_130822_151}",},

														BuZhuo = {"#{CZRW_130822_161}",
																			"#{CZRW_130822_161}",
																			"#{CZRW_130822_161}",
																			"#{CZRW_130822_161}",}, }

local g_MissionTrack_Infant_complete_tips = {
														BaiFang = {"#{CZRW_130822_148}",
																			 "#{CZRW_130822_148}",
																			 "#{CZRW_130822_148}",
																			 "#{CZRW_130822_148}",},

														Caiji = {"#{CZRW_130822_150}",
																		 "#{CZRW_130822_150}",
																		 "#{CZRW_130822_150}",
																		 "#{CZRW_130822_150}",
																		},

														DingDianYinDao = {"#{CZRW_130822_154}",
																							"#{CZRW_130822_156}",
																							"#{CZRW_130822_158}",
																							"#{CZRW_130822_160}",},

														XunWu = {"#{CZRW_130822_152}",
																		 "#{CZRW_130822_152}",
																		 "#{CZRW_130822_152}",
																		 "#{CZRW_130822_152}",},

														BuZhuo = {"#{CZRW_130822_162}",
																			"#{CZRW_130822_162}",
																			"#{CZRW_130822_162}",
																			"#{CZRW_130822_162}",}, }
--
function MissionTrack_PreLoad()
    this:RegisterEvent("OPEN_WINDOW");
    this:RegisterEvent("CLOSE_WINDOW");
    this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
    this:RegisterEvent("OPEN_MISSION_TRACK");
    this:RegisterEvent("UPDATE_MISSION_TRACK");
    this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");

    this:RegisterEvent("TRACK_ALPHA_ACTION");
    this:RegisterEvent("UNIT_LEVEL"); --玩家升级的时候更新可接列表
    this:RegisterEvent("UNIT_COMPATPKLEVEL");
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("ADJEST_UI_RELATION_POS")
    this:RegisterEvent("NOTIFY_POP_UITIP")
    this:RegisterEvent("NEW_MISSION");
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_THIS_UI")				-- 隐藏界面
end

--  界面初次加载时初始化所有类型任务都是非折叠的, 并保存界面尺寸和位置信息
function MissionTrack_OnLoad()
    local i=1;
    for i=1,200 do
        MissionPucker[i] = 1;
    end;
    MissionTrack_Lock:Show();
    MissionTrack_UnLock:Hide();
    MissionTrack_ShowORHideFunc(0);

    g_MissionTrack_Frame_UnifiedSize = MissionTrack_Frame:GetProperty("UnifiedSize");
    g_MissionTrack_Frame_UnifiedXPosition = MissionTrack_Frame:GetProperty("UnifiedXPosition");
    g_MissionTrack_Frame_UnifiedYPosition = MissionTrack_Frame:GetProperty("UnifiedYPosition");
    g_MissionTrack__Frame_AbsolutePosition = MissionTrack__Frame:GetProperty("AbsolutePosition");
    g_MissionTrack__Frame_AbsoluteSize = MissionTrack__Frame:GetProperty("AbsoluteSize");
    g_MissionTrack_Function_Frame_AbsolutePosition = MissionTrack_Function_Frame:GetProperty("AbsolutePosition");
    g_MissionTrack_DragTitle_AbsolutePosition = MissionTrack_DragTitle:GetProperty("AbsolutePosition");
    g_MissionTrack_Close_AbsolutePosition = MissionTrack_Close:GetProperty("AbsolutePosition");
    g_MissionTrack__CheckBox_Frame_AbsolutePosition = MissionTrack_CheckBox_Frame:GetProperty("AbsolutePosition");
    g_MissionTrack_Lock_AbsolutePosition = MissionTrack_Lock:GetProperty("AbsolutePosition");
    g_MissionTrack_UnLock_AbsolutePosition = MissionTrack_UnLock:GetProperty("AbsolutePosition");

end

--  事件处理, 基本没有可剔除的冗余部分, 就结构来看, 比较清晰
function MissionTrack_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end
	
    if ZBS:IsViewerWatching() > 0 then
        this:Hide()
        return
    end
    
    if(event == "OPEN_WINDOW") then
        if( arg0 == "MissionTrack") then
            this:Show();
            MissionTrack_ShowORHideFunc(0);
            MissionTrack_UpdateHaveGetMission(-1);
            DataPool:UpdateTrackStateButton(0);
        end
    elseif(event == "CLOSE_WINDOW") then
        if( arg0 == "MissionTrack") then
            this:Hide();
        end
    elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
        if not this:IsVisible() then
            return;
        end
        if (g_nNowCheck == 1) then
            MissionTrack_UpdateHaveGetMission(-1);
        end
    elseif (event == "OPEN_MISSION_TRACK") then
        --local nMissionTrackShow = DataPool:IsTrackFuncShow(1);
        --if (nMissionTrackShow > 0) then

            local nType = tonumber(arg0);
            if (nType == 1) then
                this:Show();
                MissionTrack_ShowORHideFunc(0);
                MissionTrack_UpdateHaveGetMission(-1);
                DataPool:UpdateTrackStateButton(0);
            end
        --end
    elseif (event == "UPDATE_MISSION_TRACK") then
        if not this:IsVisible() then
            return;
        end
        if (g_nNowCheck == 1) then
            local nSelect = tonumber(arg0)
            MissionTrack_UpdateHaveGetMission(nSelect);

            if 1 == g_NeedPopUITip and Player:GetData("LEVEL") < 15 then
                for i= 1, g_nMissionNum do
                    if "Mission:1403" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --“第一次杀怪”杀够了
                        MissionTrack_FreshManGuide(1, 1, 3)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1407" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then	--	剑阁猴患
						MissionTrack_FreshManGuide(1, 1, 23)
                        g_NeedPopUITip = 0
						break
					elseif "Mission:1423" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then	--	何谓行善
						MissionTrack_FreshManGuide(1, 1, 24)
                        g_NeedPopUITip = 0
						break
					elseif "Mission:1415" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then	--	抓珍兽
						MissionTrack_FreshManGuide(1, 1, 25)
                        g_NeedPopUITip = 0
						break
					elseif "Mission:1683" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 37)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1684" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 38)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1685" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 39)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1686" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 34)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1687" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 34)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1688" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 36)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1689" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 40)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1690" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 34)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1691" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 45)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1692" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 34)
                        g_NeedPopUITip = 0
                        break
					elseif "Mission:1693" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then  --杀怪杀够了
                        MissionTrack_FreshManGuide(1, 1, 34)
                        g_NeedPopUITip = 0
                        break
--					elseif "Mission:1417" == DataPool:GetPlayerMission_Name(i-1) and
--                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then	--	喜庆烟火
--			MissionTrack_FreshManGuide(1, 1, 26)
--                        g_NeedPopUITip = 0
--			break
		    elseif  "Mission:1414" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then	--第一只珍兽
			MissionTrack_FreshManGuide(1, 1, 30)
			g_NeedPopUITip = 0
		    elseif "Mission:1419" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then	--	江湖问答
			MissionTrack_FreshManGuide(1, 1, 27)
                        g_NeedPopUITip = 0
			break
		    elseif "Mission:1420" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then	--	最后的试炼
			MissionTrack_FreshManGuide(1, 1, 28)
                        g_NeedPopUITip = 0
			break
		    elseif "Mission:1405" == DataPool:GetPlayerMission_Name(i-1) and
                        1 == DataPool:GetPlayerMission_Variable(i-1, 0) then	--	初级技能
						MissionTrack_FreshManGuide(1, 1, 32)
                        g_NeedPopUITip = 0
						break
                    end
                end
	    else
		    for i = 1, g_nMissionNum do
			    if "Mission:1424" == DataPool:GetPlayerMission_Name(i-1) and
				    1 == DataPool:GetPlayerMission_Variable(i-1, 0) then
				    MissionTrack_FreshManGuide(1, 1, 29)	--	十年
				    break
			    end
		    end
            end
        end
    elseif (event == "UPDATE_WILLGET_MISSION_TRACK" or event == "UNIT_LEVEL" or event == "UNIT_COMPATPKLEVEL" ) then
        if not this:IsVisible() then
            return;
        end
        if (g_nNowCheck == 2) then
            MissionTrack_UpdateWillGet();
        end
    elseif (event == "TRACK_ALPHA_ACTION") then
        MissionTrack_SetAlpha(arg0)
    elseif (event == "ADJEST_UI_POS") then
        local nCurX = MissionTrack_Frame:GetProperty("AbsoluteXPosition")
        local nCurY = MissionTrack_Frame:GetProperty("AbsoluteYPosition")
        local nCurWidht    = MissionTrack_Frame:GetProperty("AbsoluteWidth")
        local nCurHeigh    = MissionTrack_Frame:GetProperty("AbsoluteHeight")
        local nScreenMaxWidht = tonumber(arg0)
        local nScreenMaxHeigh = tonumber(arg1)
        if (nCurX+nCurWidht > nScreenMaxWidht or nCurY+nCurHeigh > nScreenMaxHeigh) then
            MissionTrack_On_Reset()
            --同时调整CampaignTrack界面
            AdjustUIPos("CampaignTrack")
        end
    elseif (event == "ADJEST_UI_RELATION_POS") then
        if (arg0 == "MissionTrack" ) then
            MissionTrack_On_Reset()
        end
    elseif event == "NOTIFY_POP_UITIP" then
        if "MissionTrack" == arg0 and this:IsVisible() then
            MissionTrack_FreshManGuide(1, tonumber(arg1), tonumber(arg2))
        end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 210274 then
		if Get_XParam_INT(0) == 1 then
			MissionTrack_FreshManGuide(1, 1, 7)
		elseif Get_XParam_INT(0) == 2 then
			MissionTrack_FreshManGuide(1, 1, 34)
		elseif Get_XParam_INT(0) == 3 then
			MissionTrack_FreshManGuide(1, 1, 41)
		elseif Get_XParam_INT(0) == 4 then
			MissionTrack_FreshManGuide(1, 1, 42)
		end

	elseif event == "UI_COMMAND" and tonumber(arg0) == 2113 then
		MissionTrack_FreshManGuide(1, 1, 31)
    elseif "NEW_MISSION" == event and this:IsVisible() then
        local szMissionName = DataPool:GetPlayerMission_Name(tonumber(arg0))
		local nLevel = Player:GetData( "LEVEL" );
        if "Mission:1402" == szMissionName then  --第一件防具
            MissionTrack_FreshManGuide(1, 1, 5)
	    g_NeedPopUITip = 1
        elseif "Mission:1403" == szMissionName then  --第一次杀怪
            MissionTrack_FreshManGuide(1, 1, 4)
	    g_NeedPopUITip = 1
        elseif "Mission:1404" == szMissionName then --回访天师
            MissionTrack_FreshManGuide(1, 1, 6)
        elseif "Mission:1405" == szMissionName then --初级技能
            MissionTrack_FreshManGuide(1, 1, 2)
	    g_NeedPopUITip = 1
		elseif "Mission:1408" == szMissionName then --大理怪人
		--	MissionTrack_FreshManGuide(1, 1, 7)
		elseif "Mission:1414" == szMissionName then --第一只珍兽
			g_NeedPopUITip = 1
--	    	MissionTrack_FreshManGuide(1, 1, 8)
--        	elseif "Mission:1424" == szMissionName and nLevel > 5 then --初涉江湖
--			MissionTrack_FreshManGuide(1, 1, 9)
--    		elseif "Mission:1401" == szMissionName then --第一把武器
--	    	MissionTrack_FreshManGuide(1, 1, 10)
		elseif "Mission:1406" == szMissionName then -- 灵丹妙药
			MissionTrack_FreshManGuide(1, 1, 11)
		elseif "Mission:1407" == szMissionName then --剑阁猴患
			MissionTrack_FreshManGuide(1, 1, 12)
			g_NeedPopUITip = 1
		elseif "Mission:1423" == szMissionName then --何谓行善
			MissionTrack_FreshManGuide(1, 1, 13)
			g_NeedPopUITip = 1
		elseif "Mission:1412" == szMissionName then --再访天师
			MissionTrack_FreshManGuide(1, 1, 14)
		elseif "Mission:1413" == szMissionName then -- 珍兽家族
			MissionTrack_FreshManGuide(1, 1, 15)
		elseif "Mission:1415" == szMissionName then --抓珍兽
			MissionTrack_FreshManGuide(1, 1, 16)
			g_NeedPopUITip = 1
		elseif "Mission:1416" == szMissionName then --三访天师
			MissionTrack_FreshManGuide(1, 1, 17)
		elseif "Mission:1417" == szMissionName then --喜庆烟火
			MissionTrack_FreshManGuide(1, 1, 18)
			g_NeedPopUITip = 1
		elseif "Mission:1418" == szMissionName then --大善人
			MissionTrack_FreshManGuide(1, 1, 19)
--		elseif "Mission:1419" == szMissionName then --江湖问答
--			MissionTrack_FreshManGuide(1, 1, 20)
--			g_NeedPopUITip = 1
		elseif "Mission:1420" == szMissionName then --最后的试炼
			MissionTrack_FreshManGuide(1, 1, 21)
			g_NeedPopUITip = 1
		elseif "Mission:1421" == szMissionName then --十一大门派
			--MissionTrack_FreshManGuide(1, 1, 22)
			PushEvent("OPEN_PLAYERGUIDE", 1)
		elseif "Mission:1683" == szMissionName then --路见不平
			g_NeedPopUITip = 1
		elseif "Mission:1684" == szMissionName then --武功招式
			g_NeedPopUITip = 1
			MissionTrack_FreshManGuide(1, 1, 35)
		elseif "Mission:1685" == szMissionName then --武功招式
			g_NeedPopUITip = 1
		elseif "Mission:1686" == szMissionName then --武功招式
			g_NeedPopUITip = 1
		elseif "Mission:1687" == szMissionName then --武功招式
			g_NeedPopUITip = 1
		elseif "Mission:1688" == szMissionName then --武功招式
			g_NeedPopUITip = 1
		elseif "Mission:1689" == szMissionName then --武功招式
			g_NeedPopUITip = 1
		elseif "Mission:1690" == szMissionName then --武功招式
			g_NeedPopUITip = 1
		elseif "Mission:1691" == szMissionName then --武功招式
			g_NeedPopUITip = 1
		elseif "Mission:1692" == szMissionName then --武功招式
			g_NeedPopUITip = 1
		elseif "Mission:1693" == szMissionName then --武功招式
			g_NeedPopUITip = 0
		-- elseif "Mission:1682" == szMissionName then  --2013Q3新手任务引导
            -- MissionTrack_FreshManGuide(1, 1, 4)
			-- g_NeedPopUITip = 1
        end
		
	elseif event == "HIDE_THIS_UI" then
		if this:IsVisible() then
			this:Hide()
		end
    end
end

--  更新玩家已接的任务
--  如果 nSelectMissionID 不为 -1 则会在更新结束后将列表定位到指定的任务位置处
function MissionTrack_UpdateHaveGetMission(nSelectMissionID)
    local i = 1;
    --unused
    --local nMyLevel = Player:GetData( "LEVEL" );

    --  记录当前列表所指向的位置
    local nNowFirstItem;
    nNowFirstItem = MissionTrack_ListBoxTransparent:GetCurrentFirstItem();

    --  将界面状态切换为 已接任务 跟踪
    MissionTrack_HaveGet:SetCheck(1);
    MissionTrack_WillGet:SetCheck(0);
    g_nNowCheck = 1;

    --  清除列表内容
    MissionTrack_ListBoxTransparent:ClearListBoxEx();

    --  用 g_nMissionNum 替代
    --local nMissionNum = 20
    local color;

    --  填充任务信息
    for i=1,g_nMissionNum do
        if (DataPool:GetPlayerMission_InUse(i-1) == 1) then
            DataPool:GetPlayerMission_Description(i-1);
        end
    end;

    --unused
    --local k = 0;
    --声明转到for循环之内
    --local Sequence_OnefoldGenre = {}
    --  已接任务跟踪总表
    local Sequence_Assemble = {}
    --成为MissionTrack_GroupHaveGetMission的临时变量了
    --local Constitutes = {};
    --unused
    --local MissionTitles = {};

    for j=1, 200 do
        --  将获取相同分组的任务抽成函数, 便于阅读和维护
        local Sequence_OnefoldGenre = MissionTrack_GroupHaveGetMission( j, {} );

        ----
        table.sort(Sequence_OnefoldGenre,MissionTrack_CompareTable)

        --  将该类型的一组数据, 插入到总表中
        for i,n in ipairs(Sequence_OnefoldGenre) do
            table.insert(Sequence_Assemble,n)
        end
        --notused
        --Sequence_OnefoldGenre = {};
        ----
    end

    --  遍历已接任务跟踪总表, 将数据插入到显示列表中
    local Per_Segment,xxxx,i,j;
    for i,Per_Segment in ipairs(Sequence_Assemble) do
        local nMissionTrackType = DataPool:GetPlayerMissionTrackType(Per_Segment[2]);
        if (Per_Segment[3] ~= "" and nMissionTrackType > 0) then
            local nIsMissionTrackOpen = DataPool:IsMissionTrackOpen(Per_Segment[2]);
            if (nIsMissionTrackOpen > 0) then
                --  这一部分只添加了任务的名称
                MissionTrack_ListBoxTransparent:AddItemExWithoutLayout("#e010101" ..Per_Segment[1],Per_Segment[2], 3, Per_Segment[3],4)
                --  这一部分实际添加了任务的达成方式和相关目标完成情况的数据统计
                MissionTrack_AddMissionTrackInfo(Per_Segment[2], nMissionTrackType, Per_Segment[5]);
            end
        elseif (tonumber(Per_Segment[4]) == 0) then
            MissionTrack_ListBoxTransparent:AddItemExWithoutLayout("#e010101" ..Per_Segment[1],Per_Segment[2], 0);
        end
    end
    MissionTrack_ListBoxTransparent:RequestLayout();

    --  更新任务追踪列表的显示位置
    if (nSelectMissionID ~= -1) then
        local itemNum = MissionTrack_ListBoxTransparent:GetItemNumByMissionId(nSelectMissionID);
        if( itemNum ~= -1) then
            MissionTrack_ListBoxTransparent:SetCurrentFirstItem(itemNum);
        else
            MissionTrack_ListBoxTransparent:SetCurrentFirstItem(nNowFirstItem);
        end
        MissionTrack_ListBoxTransparent:SetItemSelectByItemID(nSelectMissionID);
    else
        MissionTrack_ListBoxTransparent:SetCurrentFirstItem(nNowFirstItem);
    end

    --QuestLog_Amount : SetText( k .. "/" .. nMissionNum);
---
    --QuestLog_ListBox_SelectChanged();

    --if Current_Clicked ~= -1 then
    --    --QuestLog_Listbox : EnsureItemIsVisable(Current_Clicked);
    --    QuestLog_Listbox : SetCurrentFirstItem(Current_Clicked);
    --    Current_Clicked = -1
    --end
end

-- function MissionTrack_GuildMission( nSelIndex )
-- 	-- 子任务
-- 	local nSubMission = DataPool : GetPlayerMission_Variable( nSelIndex, g_GuildInteractiveMission_MisType );
-- 	if ( nSubMission < 1 or nSubMission > table.getn( g_GuildInteractiveMissionTrack ) ) then
-- 		return "";
-- 	end

-- 	if ( nSubMission == 1 ) then
-- 		local nRefreshPos = {
-- 			{43,65}, 	{44,78}, 	{54,77},
-- 			{50,87}, 	{60,87}, 	{44,95},
-- 			{69,87}, 	{92,97}, 	{82,63},
-- 			{124,96}, 	{147,84}, 	{156,84},
-- 			{41,55}, 	{85,81}, 	{81,118},
-- 			{65,119}, 	{39,123}, 	{49,148},
-- 			{53,130}, 	{118,121}, 	{123,124},
-- 			{116,131}, 	{147,137}, 	{50,148},
-- 			{51,133}, 	{77,132}, 	{93,138},
-- 			{106,119}, 	{127,48}, 	{151,60},
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
-- 		local text = string.format( g_GuildInteractiveMissionTrack[ nSubMission ],
-- 										nRefreshPos[ nPos1 ][ 1 ], nRefreshPos[ nPos1 ][ 2 ],
-- 										nRefreshPos[ nPos2 ][ 1 ], nRefreshPos[ nPos2 ][ 2 ],
-- 										nRefreshPos[ nPos3 ][ 1 ], nRefreshPos[ nPos3 ][ 2 ],
-- 										nRefreshPos[ nPos4 ][ 1 ], nRefreshPos[ nPos4 ][ 2 ],
-- 										nRefreshPos[ nPos5 ][ 1 ], nRefreshPos[ nPos5 ][ 2 ] );
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
-- 		local text = ScriptGlobal_Format( g_GuildInteractiveMissionTrack[ nSubMission ], nStartPos[ nPosIndex ][ 1 ], nStartPos[ nPosIndex ][ 2 ] );
-- 		return text;
-- 	end

-- 	return "";
-- end

function MissionTrack_GetInfantTips(nSelIndex)
	local MissType = DataPool:GetPlayerMission_Variable( nSelIndex, g_MissionTrack_Infant_MissionType_Index )
	local BaoZhuangIndex = DataPool:GetPlayerMission_Variable( nSelIndex, g_MissionTrack_Infant_baozhuang_Index )
	local MissIndex = DataPool:GetPlayerMission_Variable( nSelIndex, g_MissionTrack_Infant_Mission_Index )

	local misId, sceneId, sceneName, NpcName, PosX, PosZ = DataPool:GetInfantExpMission(MissIndex)
	local str
	if MissType == g_MissionTrack_Infant_SubMissionTypeEnum.BaiFang then
		str = ScriptGlobal_Format(g_MissionTrack_Infant_tips.BaiFang[BaoZhuangIndex], sceneName, PosX, PosZ, sceneId, NpcName)

	elseif MissType == g_MissionTrack_Infant_SubMissionTypeEnum.Caiji then
		str = ScriptGlobal_Format(g_MissionTrack_Infant_tips.Caiji[BaoZhuangIndex], sceneName, PosX, PosZ, sceneId, NpcName)

	elseif MissType == g_MissionTrack_Infant_SubMissionTypeEnum.XunWu then
		str = ScriptGlobal_Format(g_MissionTrack_Infant_tips.XunWu[BaoZhuangIndex], NpcName)

	elseif MissType == g_MissionTrack_Infant_SubMissionTypeEnum.DingDianYinDao then
		str = ScriptGlobal_Format(g_MissionTrack_Infant_tips.DingDianYinDao[BaoZhuangIndex], sceneName, PosX, PosZ, sceneId)

	elseif MissType == g_MissionTrack_Infant_SubMissionTypeEnum.BuZhuo then
		str = ScriptGlobal_Format(g_MissionTrack_Infant_tips.BuZhuo[BaoZhuangIndex], PosX, PosZ, NpcName)
	end

	return str
end


function MissionTrack_GetInfantCompleteTips(nSelIndex)
	local MissDone = DataPool:GetPlayerMission_Variable( nSelIndex, 0 )
	local MissType = DataPool:GetPlayerMission_Variable( nSelIndex, g_MissionTrack_Infant_MissionType_Index )
	local BaoZhuangIndex = DataPool:GetPlayerMission_Variable( nSelIndex, g_MissionTrack_Infant_baozhuang_Index )
	local MissIndex = DataPool:GetPlayerMission_Variable( nSelIndex, g_MissionTrack_Infant_Mission_Index )

	local misId, sceneId, sceneName, NpcName, PosX, PosZ = DataPool:GetInfantExpMission(MissIndex)
	local str
	if MissType == g_MissionTrack_Infant_SubMissionTypeEnum.BaiFang then
		str = g_MissionTrack_Infant_complete_tips.BaiFang[BaoZhuangIndex]

	elseif MissType == g_MissionTrack_Infant_SubMissionTypeEnum.Caiji then
		str = g_MissionTrack_Infant_complete_tips.Caiji[BaoZhuangIndex]

	elseif MissType == g_MissionTrack_Infant_SubMissionTypeEnum.XunWu then
		str = ScriptGlobal_Format(g_MissionTrack_Infant_complete_tips.XunWu[BaoZhuangIndex], NpcName)

	elseif MissType == g_MissionTrack_Infant_SubMissionTypeEnum.DingDianYinDao then
		str = g_MissionTrack_Infant_complete_tips.DingDianYinDao[BaoZhuangIndex]

	elseif MissType == g_MissionTrack_Infant_SubMissionTypeEnum.BuZhuo then
		str = ScriptGlobal_Format(g_MissionTrack_Infant_complete_tips.BuZhuo[BaoZhuangIndex], NpcName)
	end

	return str
end

function MissionTrack_ZhanBeiMission_JiShaShouWei( nSelIndex )
	-- Param
	local nDirection = DataPool:GetPlayerMission_Variable( nSelIndex, 2 );		-- 方向
	local nCombination = DataPool:GetPlayerMission_Variable( nSelIndex, 4 );	-- 自身战盟ID和NPC索引
	local nXZZMId = DataPool:GetPlayerMission_Variable( nSelIndex, 5 );			-- 目标战盟id
	local nSubMission = DataPool:GetPlayerMission_Variable( nSelIndex, 6 );		-- 子任务类型
	-- Check
	if ( nDirection < 1 or nDirection > 4 ) then
		return "";
	end
	local nSelfAllianceId = math.floor( nCombination / 10000 );
	if ( nSelfAllianceId < 0 or nSelfAllianceId > 4 ) then
		return "";
	end
	local npcIndex = math.mod( nCombination, 10000 );
	if ( npcIndex < 1 or npcIndex > 4 ) then
		return "";
	end
	if ( nXZZMId < 0 or nXZZMId > 4 ) then
		return "";
	end
	if ( nSubMission ~= 7 ) then
		return "";
	end
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
	-- Text
	local szAllianceName = aryAllianceName[ nXZZMId ];
	local szDirectionName = aryDirection[ nDirection ];
	local aryPos = aryCaptains[ nXZZMId ][ nDirection ].MissionPos;
	local nSceneId = aryAllianceScene[ nXZZMId ];
	local strText = ScriptGlobal_Format( "#{MZZBQ_150811_531}", szAllianceName, szDirectionName, aryPos[ 1 ], aryPos[ 2 ], nSceneId, szDirectionName );
	return strText;
end

function MissionTrack_ZhanBeiMission_CompleteJiShaShouWei( nSelIndex )
	-- Param
	local nDirection = DataPool:GetPlayerMission_Variable( nSelIndex, 2 );		-- 方向
	local nCombination = DataPool:GetPlayerMission_Variable( nSelIndex, 4 );	-- 自身战盟ID和NPC索引
	local nXZZMId = DataPool:GetPlayerMission_Variable( nSelIndex, 5 );			-- 目标战盟id
	local nSubMission = DataPool:GetPlayerMission_Variable( nSelIndex, 6 );		-- 子任务类型
	-- Check
	if ( nDirection < 1 or nDirection > 4 ) then
		return "";
	end
	local nSelfAllianceId = math.floor( nCombination / 10000 );
	if ( nSelfAllianceId < 0 or nSelfAllianceId > 4 ) then
		return "";
	end
	local npcIndex = math.mod( nCombination, 10000 );
	if ( npcIndex < 1 or npcIndex > 4 ) then
		return "";
	end
	if ( nXZZMId < 0 or nXZZMId > 4 ) then
		return "";
	end
	if ( nSubMission ~= 7 ) then
		return "";
	end
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
	local aryAllianceNpcName = {
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
	-- Text
	local szAllianceName = aryAllianceName[ nXZZMId ];
	local xpos = aryZhanBeiNpc_Ex[ nXZZMId ][ npcIndex ].xpos;
	local zpos = aryZhanBeiNpc_Ex[ nXZZMId ][ npcIndex ].zpos;
	local nSceneId = aryAllianceScene[ nXZZMId ];
	local szNpcName = aryZhanBeiNpc_Ex[ nXZZMId ][ npcIndex ].name;
	local strText = ScriptGlobal_Format( "#{MZZBQ_150811_532}", szAllianceName, xpos, zpos, nSceneId, szNpcName );
	return strText;
end

function MissionTrack_GetZBTips(nSelIndex)
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

		str = ScriptGlobal_Format("#{MZZBQ_150811_336}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

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

		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_82}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = ScriptGlobal_Format("#{MZZBQ_150811_337}", targetZMName,PosX,PosZ,toScene)

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


		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_95}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = ScriptGlobal_Format("#{MZZBQ_150811_338}", targetZMName,PosX,PosZ,toScene)

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

		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_124}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = ScriptGlobal_Format("#{MZZBQ_150811_339}", targetZMName,PosX,PosZ,toScene)

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

		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_137}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = ScriptGlobal_Format("#{MZZBQ_150811_340}", targetZMName,PosX,PosZ,toScene)

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

		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_166}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = ScriptGlobal_Format("#{MZZBQ_150811_405}", targetZMName,PosX,PosZ,toScene)
	end

	return str
end

function MissionTrack_GetZBCompleteTips(nSelIndex)
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

		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_49}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = string.format("   #W找#G%s#{_INFOAIM%s,%s,%s,-1}#W处的#R%s#W战备官交任务。", targetZMName, acceptxPos, acceptzPos, selfScene, missNpcName);

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

		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_82}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = string.format("   #W找#G%s#{_INFOAIM%s,%s,%s,-1}#W处的#R%s#W战备官交任务。", targetZMName, acceptxPos, acceptzPos, selfScene, missNpcName);

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


		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_95}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = string.format("   #W找#G%s#{_INFOAIM%s,%s,%s,-1}#W处的#R%s#W战备官交任务。", targetZMName, acceptxPos, acceptzPos, selfScene, missNpcName);

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

		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_124}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = string.format("   #W找#G%s#{_INFOAIM%s,%s,%s,-1}#W处的#R%s#W战备官交任务。", targetZMName, acceptxPos, acceptzPos, selfScene, missNpcName);

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

		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_137}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = string.format("   #W找#G%s#{_INFOAIM%s,%s,%s,-1}#W处的#R%s#W战备官交任务。", targetZMName, acceptxPos, acceptzPos, selfScene, missNpcName);

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

		--local strtemp1 = ScriptGlobal_Format("#{MZZBQ_150811_166}", targetZMName,PosX,PosZ,toScene)
		--local strtemp2 = ScriptGlobal_Format("#{MZZBQ_150811_547}", targetZMName,acceptxPos,acceptzPos,selfScene,missNpcName,missNpcName)

		--str = strtemp1 .. strtemp2

		str = string.format("   #W找#G%s#{_INFOAIM%s,%s,%s,-1}#W处的#R%s#W战备官交任务。", targetZMName, acceptxPos, acceptzPos, selfScene, missNpcName);
	end

	return str
end

--  增加已接任务的详细追踪信息
function MissionTrack_AddMissionTrackInfo(nMissionIndex, nMissionTrackType, nFinished)
    --unused
    --local nNewIndex = nMissionIndex+200;
    local color = "FFCCCCCC";

    --任务变量索引
    local MissionParam_Index = 0;
    local strTarget = "";

    local strFinishNPC, strFinishSceneName, nFinishSceneID, nFinishX, nFinishY = DataPool:GetMissionFinishInfo(nMissionIndex);
    local nIndex = DataPool:GetPlayerMission_Display(nMissionIndex, 7)
    if (nFinished == 1 and strFinishNPC ~= "") then       --已完成的任务
        --if (strFinishNPC ~= "") then
            --local strTemp = string.format("   #W去#G%s#W找#R%s#{_INFOAIM%d,%d,%d,%s}#W", strFinishSceneName, strFinishNPC, nFinishX, nFinishY, nFinishSceneID, strFinishNPC);
            local strTemp = "";
            if nIndex == 1018870 then
                strTemp = string.format("   #W去#G%s#W找#R%s#W", strFinishSceneName, strFinishNPC);
            elseif nIndex== 890500 then
            		strTemp = MissionTrack_GetInfantCompleteTips(nMissionIndex)
            elseif nIndex == 210273 then
                strTemp = "#{XSRW_100313_01}"
            elseif nIndex == 210257 then
                strTemp = "#{XSRW_100313_02}"
            elseif nIndex == 210264 then
                strTemp = "#{XSRW_100313_03}"
            elseif nIndex == 210265 then
                strTemp = "#{XSRW_100313_04}"
            elseif nIndex == 210269 then
                strTemp = "#{XSRW_100313_05}"
            elseif nIndex == 600047 or nIndex == 600048 or nIndex == 600049 then        --帮派任务 for:TT 64489
                strTemp = string.format("   #W去找#R%s",    strFinishNPC);
            elseif nIndex == 200081 then --青衫磊落险峰行
				strTemp = "   ".."#{Mis_juqing_Tar_0046}";
			elseif nIndex == 200002 then --相会在万劫谷
				strTemp = "   ".."#{Mis_juqing_Tar_0047}";
			elseif nIndex == 200084 or nIndex == 200085 then --还施水阁 and 一品堂
				strTemp = "   ".."#{Mis_juqing_Tar_0048}";
			elseif nIndex == 200093 then	--远赴苍茫山
				strTemp = "   ".."#{Mis_juqing_Tar_0049}";
			elseif nIndex == 200032 then  --勤王
				strTemp = "   ".."#{Mis_juqing_Tar_0050}";
			elseif nIndex == 200041 then  --静候佳音
				strTemp = "   ".."#{Mis_juqing_Tar_0051}";
			elseif nIndex == 200043 then  --择日再战
				strTemp = "   ".."#{Mis_juqing_Tar_0052}";
			elseif nIndex == 200097 then  --虽危实安
				strTemp = "   ".."#{Mis_juqing_Tar_0053}";
           		 elseif nIndex == 890638 then  --Q4打卡 寻宝乐翻天
             		        strTemp = "   ".."#{XBLFT_131112_99}";
			elseif nIndex == 890612 then  --新代言人打卡
				strTemp = "   ".."#{MBHTL_130906_67}";
			elseif nIndex == 891456 or nIndex == 891457 or nIndex == 891458 or nIndex == 891459 or nIndex == 891460 or nIndex == 891461 then --战备任务
				strTemp = MissionTrack_GetZBCompleteTips(nMissionIndex)
			elseif nIndex == 891688 then
				strTemp = MissionTrack_ZhanBeiMission_CompleteJiShaShouWei( nMissionIndex );
			--elseif nIndex == 891345 and MissionTrack_IsQiXiQueQiaoDate() ~= 1 then --七夕鹊桥相会 add by yuanzhiheng (下面大哥说的好共军太狡猾 ^ ^)
            --	 strTemp = "   ".."#{QXQQ_160613_93}"
            elseif nIndex == 888231 then --帮会属地 特特特
                strTemp = "   ".."#{JLTX_200909_71}"
			elseif nIndex >= 999381 and nIndex <= 999388 then
                strTemp = "   ".."#W#{ERYR_240701_334}"
			elseif nIndex == 300141 then
				strTemp = "#{HXWS_20250613_66}"
            elseif nIndex == 893602 then
                strTemp = "#{FYDK_260129_60}"
			elseif nFinishSceneID < 0 then  --任务完成场景如配置为-1,则不予显示坐标(例如“古来英雄皆寂寞”)
                strTemp = string.format("   #W去#G%s#W找#R%s", strFinishSceneName, strFinishNPC);
			else
                strTemp = string.format("   #W去#G%s#W找#R%s#{_INFOAIM%d,%d,%d,%s}", strFinishSceneName, strFinishNPC, nFinishX, nFinishY, nFinishSceneID, strFinishNPC);
            end
            --特写人物追踪处理
            if nMissionTrackType == 2 then
    			for _, item in g_MissionTrack_Display_Special_Process do
    				if nIndex == item.missionIndex then
    				    strTemp = item.missionTargetStr
    				end
    			end
    		end
            strTarget = strTemp;
        --end
    else    --未完成的任务
        --local nRound = DataPool:GetPlayerMission_Display(nMissionIndex,3);
        --if( nRound >= 0 ) then
        --    Mission_Variable = DataPool:GetPlayerMission_DataRound(nRound);
        --    if(Mission_Variable >= 0) then
        --        strTarget = "任务当前环数：#W"..tostring(Mission_Variable);
        --    end
        --end
            --显示任务银票数量
        --if( DataPool:GetPlayerMission_Display(nMissionIndex,4) > 0 ) then
        --    Mission_Variable = DataPool:GetPlayerMission_Variable(nMissionIndex,MissionParam_Index);
        --    MissionParam_Index = MissionParam_Index + 1;

        --    if(Mission_Variable >0) then
        --        silverdesc = DataPool:GetPlayerMission_BillName(nMissionIndex);
        --        strTarget = "需要得到金钱：#W"..tostring(Mission_Variable);
        --    end
        --end

        ---------------------------------------------------------------------------------------------------------------------------------------------------------
        --  这下面会根据任务的目标构造任务目标和完成情况数据, 每个目标一条
        --  没有特别需要更改的必要, 比较容易理解, 因此只是增加注释和必要的分割

        local strAppend = "";
        local Mission_Variable = 0;

        --非特殊任务, 需要忽略第一个任务参数
        if MissionTrack_IsSpecialMission(nMissionIndex)==0 then
            MissionParam_Index = MissionParam_Index + 1;
        end

        ---------------------------------------------------------------------------------------------------------------------------------------------------------
        --  下面这四大块是在构造任务目标的完成情况

        --任务需要杀的npc
        local nDemandKillNum,Kill_Random_Type = DataPool:GetPlayerMissionDemandKill_Num(nMissionIndex);
        if( nDemandKillNum > 0 ) then
            strAppend = "   #W已击败：";
            for i=1, nDemandKillNum do
                --  需要的NPC, 需要的数量
                local nNPCName, nNum = DataPool:GetPlayerMissionDemand_NPC(i-1,Kill_Random_Type,nMissionIndex);
                --  实际获得的数量
                Mission_Variable = DataPool:GetPlayerMission_Variable(nMissionIndex,MissionParam_Index,Kill_Random_Type,i-1);
                --
                MissionParam_Index = MissionParam_Index + 1;

                --  根据不同条件决定如何显示目标完成情况
                if (i == 1 and nDemandKillNum > 1) then
                    strAppend = strAppend.."#W"..nNPCName.."："..tostring(Mission_Variable).."/"..tostring(nNum).."#r";
                elseif (i == 1 and nDemandKillNum == 1) then
                    strAppend = strAppend.."#W"..nNPCName.."："..tostring(Mission_Variable).."/"..tostring(nNum);
                elseif( i == nDemandKillNum) then
                    strAppend = strAppend.."#W            "..nNPCName.."："..tostring(Mission_Variable).."/"..tostring(nNum);
                else
                    strAppend = strAppend.."#W            "..nNPCName.."："..tostring(Mission_Variable).."/"..tostring(nNum).."#r";
                end
                --unused
                --nNewIndex = nNewIndex + 1;
            end
        end

        --任务需要的物品
        local nDemandNum,Item_Random_Type= DataPool:GetPlayerMissionDemand_Num(nMissionIndex);
        if( nDemandNum > 0 ) then
            if(Item_Random_Type == -100) then
                strAppend = "   #W已提交：";
                --unused
                --nNewIndex = nNewIndex + 1;
                Item_Random_Type = 0
            else
                strAppend = "   #W已得到：";
                --unused
                --nNewIndex = nNewIndex + 1;
            end
        end

        for i=1, nDemandNum do
            --    需要的类型，需要物品ID，需要多少个
            local szName,nItemID, nNum = DataPool:GetPlayerMissionDemand_Item(i-1,Item_Random_Type,nMissionIndex);
            --  背包中已经有的数量
            Mission_Variable = DataPool : GetPlayerMission_ItemCountNow(nItemID)

            if Mission_Variable > nNum then
                Mission_Variable = nNum
            end

            --  JOY: 这里的想法是要检查任务是否已经完成了... 但这个逻辑应该是有误的
            local Mission_Variable2 = DataPool:GetPlayerMission_Variable(nMissionIndex,0);
            if Mission_Variable2 > 0 then
                Mission_Variable = nNum
            end

            --
            if (i == 1 and nDemandNum > 1) then
                strAppend = strAppend.."#W"..szName..":"..tostring(Mission_Variable).."/"..tostring(nNum).."#r";
            elseif(i == 1 and nDemandNum == 1) then
                strAppend = strAppend.."#W"..szName..":"..tostring(Mission_Variable).."/"..tostring(nNum);
            elseif(i == nDemandNum) then
                strAppend = strAppend.."#W            "..szName..":"..tostring(Mission_Variable).."/"..tostring(nNum);
            else
                strAppend = strAppend.."#W            "..szName..":"..tostring(Mission_Variable).."/"..tostring(nNum).."#r";
            end
        end

        --任务自定义的物品
        local nCustomNum = DataPool:GetPlayerMissionCustom_Num(nMissionIndex);
        for i=1, nCustomNum do
            --    需要的物品, 需要的数量
            local strCustom, nNum = DataPool:GetPlayerMissionCustom(i-1);
            --  已经获得的数量
            Mission_Variable = DataPool:GetPlayerMission_Variable(nMissionIndex,MissionParam_Index);

            MissionParam_Index = MissionParam_Index + 1;

            local strDot = "";
            if (i < nCustomNum) then
                strDot = "#r";
            end

            if nNum == 0 then
                strAppend = strAppend.."   " .. strCustom..strDot;
            else
                strAppend = strAppend.."   " .. strCustom .. " ： ".. Mission_Variable .. "/" .. nNum..strDot;
            end
        end

        --任务自定义的随机物品 zz添加
        local nRandomCustomNum = DataPool:GetPlayerMissionRandomCustom_Num(nMissionIndex);
        for i=1,nRandomCustomNum do
            --  需要的类型, 需要的数量, 获得的数量
            local strCustom, nNeedNum, nCompleteNum = DataPool:GetPlayerMissionRandomCustom(i-1,nMissionIndex);

            local strDot = "";
            if (i < nCustomNum) then
                strDot = "#r";
            end

            if nNeedNum == 0 then
                strAppend = strAppend.."   "..strCustom..strDot;
            else
                strAppend = strAppend.."   "..strCustom .. " ： ".. nCompleteNum .. "/" .. nNeedNum..strDot;
            end
        end

        ---------------------------------------------------------------------------------------------------------------------------------------------------------
        --  下面这一部分, 主要构造如何达成任务目标的说明, 并在该说明之后加上当前任务的完成情况统计

        local strTemp = "";
        strTarget = "";

        --脚本任务，直接读取任务跟踪信息

        if (nMissionTrackType == 1) then
           strTarget = DataPool:GetLuaMissionTrackInfo(nMissionIndex);
			-- 帮会交互设计
			-- if ( nIndex == 610013 or nIndex == 610014 ) then
			-- 	strTarget = MissionTrack_GuildMission( nMissionIndex );
			-- end
            if nFinished == 1 and nIndex == 892856 then
                strTarget = "#{SQBP_180608_164}"
            end
           if (strAppend ~= "") then
				strTarget = "   #W" .. strTarget.."#r#W"..strAppend;
            else
                strTarget = "   #W" .. strTarget;
            end

        --表格送物任务，根据不同类型进行文字匹配
        elseif(nMissionTrackType == 2) then
            local strNPCName, strSceneName, nTargetScene, nPosX, nPosY = DataPool:GetDeliveryMissionTrackInfo(nMissionIndex);
            if (strNPCName ~= "") then
                -- 英雄任务对应 场景为-1
                local strTemp = "";
                if(nTargetScene ~= -1) then
                    --strTemp = string.format("   #W去#G%s#W找#R%s#{_INFOAIM%d,%d,%d,%s}#W", strSceneName, strNPCName, nPosX, nPosY, nTargetScene, strNPCName);
                    if nIndex == 1018870 then
                        strTemp = string.format("   #W去#G%s#W找#R%s#W", strSceneName, strNPCName);
                    else
                        strTemp = string.format("   #W去#G%s#W找#R%s#{_INFOAIM%d,%d,%d,%s}", strSceneName, strNPCName, nPosX, nPosY, nTargetScene, strNPCName);
                    end
                else
                    strTemp = string.format("   #W去#G%s#W找#R%s#W", strSceneName, strNPCName);
                end
                strTarget = strTarget .. strTemp .. "#r";
            end
            if (strAppend ~= "") then
                strTarget = strTarget .. strAppend;
            end

         --表格配置杀怪任务
        elseif(nMissionTrackType == 3) then
            local nMonsterNum = DataPool:GetKillMonsterMissionTrackInfo_num(nMissionIndex);
            if (nMonsterNum > 0) then
                for nn = 1, nMonsterNum do
                    local strMonsterName, strSceneName, nSceneId, nCount, nXpos, nYpos = DataPool:GetKillMonsterMissionTrackInfo_MonsterInfo(nMissionIndex, nn-1);
                    if(strMonsterName ~= "") then
                        local strTemp = "";
                        if(nSceneId ~= -1) then
                             strTemp = string.format("   #W去#G%s#W击败#R%s#{_INFOKILL%d,%d,%d,%s}#W", tostring(strSceneName),tostring(strMonsterName), tonumber(nXpos), tonumber(nYpos), tonumber(nSceneId), tostring(strMonsterName));
                        else
                             strTemp = string.format("   #W去#G%s#W杀#R%s#W", tostring(strSceneName),tostring(strMonsterName));
                        end
                        strTarget = strTarget .. strTemp;
                        strTarget = strTarget .. "#r";
                    end
                end
            end
            if (strAppend ~= "") then
                strTarget = strTarget .. strAppend;
            end

        --表格配置掉落任务
        elseif(nMissionTrackType == 4) then
            local nLootItemNum = DataPool:GetLootItemMissionTrackInfo_num(nMissionIndex);
            if(nLootItemNum > 0) then
                for nn = 1, nLootItemNum do
                    local strMonsterName, strSceneName, strItemName, nSceneID, nItemNum, xPos, yPos = DataPool:GetLootItemMissionTrackInfo_ItemInfo(nMissionIndex, nn-1);
                    if (strMonsterName ~= "") then
                        local strTemp = "";
                        if(nSceneID ~= -1) then
                             strTemp = string.format("   #W去#G%s#W击败#R%s#{_INFOKILL%d,%d,%d,%s}#W", strSceneName, strMonsterName, xPos, yPos, nSceneID, strMonsterName);
                        else
                             strTemp = string.format("   #W去#G%s#W杀#R%s#W", strSceneName, strMonsterName);
                        end
                        strTarget = strTarget .. strTemp;
                        strTarget = strTarget .. "#r";
                    end
                end
            end
            if (strAppend ~= "") then
                strTarget = strTarget .. strAppend;
            end

        --表格配置护送任务
        elseif (nMissionTrackType == 6) then
            local strObjName, strTargetNPC, strTargetScene, nTargetScene, xPos, yPos = DataPool:GetHusongMissionTrackInfo(nMissionIndex);
            if (strObjName ~= "") then
                local strTemp = "";
                if(nTargetScene ~= -1) then
                    strTemp = string.format("   #W到%s找#R%s#{_INFOAIM%d,%d,%d,%s}#W#r",strTargetScene, strTargetNPC, xPos, yPos, nTargetScene, strTargetNPC);
                else
                    strTemp = string.format("   #W到%s找#R%s#W",strTargetScene, strTargetNPC);
                end
                strTarget = strTarget .. strTemp;
            end
            if (strAppend ~= "") then
                strTarget = strTarget .. strAppend;
            end
        elseif (nMissionTrackType == 7) then
     			if nIndex == 890500 then
    				strTarget = MissionTrack_GetInfantTips(nMissionIndex)
    			end
        end
    	if(nMissionTrackType == 8 and nIndex == 890638) then
       		 strTarget="   "..MissionTrack_GetXunBaoLeFanTianTarget(nMissionIndex)
        end
      if(nMissionTrackType == 8 and nIndex==890612) then
      	strTarget="   "..MissionTrack_GetDAKATarget(nMissionIndex)
      end
	  --shitu mission by yuanpeilong 201505
	  if(nMissionTrackType == 9 and nIndex==891159) then
      	strTarget="   "..QuestLog_GetShiFuTrack(nMissionIndex)
      end
	  --shitu mission by yuanpeilong 201505
      if(nMissionTrackType == 10 and nIndex==891160) then
      	strTarget="   "..QuestLog_GetTuDiTrack(nMissionIndex)
      end
	  --20150701-七夕交互任务-by yuanpeilong
      if(nMissionTrackType == 11 and nIndex==891322) then
      	strTarget="   "..QuestLog_Get2015QiXiJiaoHuTrack(nMissionIndex).."#r"..strAppend
      end
	  --if(nIndex == 891345 and MissionTrack_IsQiXiQueQiaoDate() ~= 1) then
		--strTarget = "   ".."#{QXQQ_160613_93}"
	  --end
	  --【君临天下】【日常PVE任务设计】 by yuanpeilong
      if(nMissionTrackType == 12 and nIndex==891472) then
      	strTarget="   "..QuestLog_GetTrack_2(nMissionIndex)
      end
	  --【君临天下】【日常PVE任务设计】 by yuanpeilong
      if(nMissionTrackType == 14 and nIndex==891473) then
      	strTarget="   "..QuestLog_GetTrack_2(nMissionIndex)
      end
	  --【君临天下】【日常PVE任务设计】 by yuanpeilong
      if(nMissionTrackType == 16 and nIndex==891474) then
      	strTarget="   "..QuestLog_GetTrack_2(nMissionIndex)
      end
	  --【君临天下】【日常PVE任务设计】 by yuanpeilong
      if(nMissionTrackType == 18 and nIndex==891475) then
      	strTarget="   "..QuestLog_GetTrack_2(nMissionIndex)
      end
	  --【君临天下】【日常PVE任务设计】 by yuanpeilong
      if(nMissionTrackType == 20 and nIndex==891476) then
      	strTarget="   "..QuestLog_GetTrack_2(nMissionIndex)
      end
	  --【君临天下】【日常PVE任务设计】 by yuanpeilong
      -- if(nMissionTrackType == 21 and nIndex==891501) then
      	-- strTarget="   "..QuestLog_GetTrack_5(nMissionIndex)
      -- end
	  -- --【君临天下】【日常PVE任务设计】 by yuanpeilong
      -- if(nMissionTrackType == 22 and nIndex==891502) then
      	-- strTarget="   "..QuestLog_GetTrack_5(nMissionIndex)
      -- end
	  -- --【君临天下】【日常PVE任务设计】 by yuanpeilong
      -- if(nMissionTrackType == 23 and nIndex==891503) then
      	-- strTarget="   "..QuestLog_GetTrack_5(nMissionIndex)
      -- end
	  -- --【君临天下】【日常PVE任务设计】 by yuanpeilong
      -- if(nMissionTrackType == 24 and nIndex==891504) then
      	-- strTarget="   "..QuestLog_GetTrack_5(nMissionIndex)
      -- end
	  -- --【君临天下】【日常PVE任务设计】 by yuanpeilong
      -- if(nMissionTrackType == 25 and nIndex==891505) then
      	-- strTarget="   "..QuestLog_GetTrack_5(nMissionIndex)
      -- end
	  --战备任务
	  if(nMissionTrackType == 27) then
		if(nIndex==891456 or nIndex==891457 or nIndex==891458 or nIndex==891459 or nIndex==891460 or nIndex==891461) then
			strTarget="   "..MissionTrack_GetZBTips(nMissionIndex)
		end
      end

		-- 战备任务7 击败守卫
		if ( nMissionTrackType == 28 and nIndex == 891688 ) then
			strTarget = "   " .. MissionTrack_ZhanBeiMission_JiShaShouWei( nMissionIndex );
		end

		--新暗器引导任务
		-- if ( nMissionTrackType == 29 and nIndex == 891829 ) then
			-- strTarget = "#W" .. MissionTrack_NewDark( nMissionIndex );
		-- end		
		-- [2017-元宵节猜灯谜活动]
		if (nMissionTrackType == 30 and nIndex == 892384) then
			strTarget = "   "..QuestLog_GetTrack_2017YXJCDM(nMissionIndex);
		end		

		--【2017九星神器每日任务】
		if (nMissionTrackType == 33 and nIndex == 892627) then
			strTarget = "   "..QuestLog_GetTrack_9_Star(nMissionIndex);
		end	

		--2022新天外跑环任务链：简单模式
		if (nMissionTrackType == 34 and (nIndex == 998267 or nIndex == 998346)) then
			strTarget = "   "..QuestLog_GetTrack_2022XTWBDPH_easy(nMissionIndex);
		end	
		
		--2022新天外跑环任务链：困难模式
		if (nMissionTrackType == 35 and (nIndex == 998268 or nIndex == 998347)) then
			strTarget = "   "..QuestLog_GetTrack_2022XTWBDPH_diff(nMissionIndex);
		end	

		--2022Q3新天外预热活动-ypl
		if (nMissionTrackType == 36 and nIndex == 998179) then
			strTarget = "   "..QuestLog_GetTrack_2022Q3NTWYR(nMissionIndex);
		end	

		--十六周年情怀任务
		if (nMissionTrackType == 37 and nIndex == 998472) then
			strTarget = QuestLog_GetTarget_2023Anniversay(nMissionIndex).."#r"..strAppend;
		end
		
		--2023Q3宗门日常任务
	  if(nMissionTrackType == 38) then
	  	if nIndex == 998613 or nIndex == 998614 or nIndex == 998615 or nIndex == 998616 or nIndex == 998617 
	  			or nIndex == 998618 or nIndex == 998619 or nIndex == 998621 or nIndex == 998622 or nIndex == 998623
	  			or nIndex == 998624 or nIndex == 998625 or nIndex == 998626 or nIndex == 998627 or nIndex == 998607 then
				strTarget = "   "..QuestLog_GetTrack_RiChangMission(nMissionIndex)
			end
		end
		
		--宗门预热活动
		if (nMissionTrackType == 39 and nIndex == 998839) then
			strTarget = "   "..QuestLog_GetTrack_ZongMenYuRe(nMissionIndex)
		end

		
		if ( nMissionTrackType == 40 ) then
			if nIndex == 999147 then
				strTarget = "   "..MissionTrack_GetTrack_DHXYStage2_1(nMissionIndex)
			elseif nIndex == 999148 then
				strTarget = "   "..MissionTrack_GetTrack_DHXYStage2_2(nMissionIndex)
			elseif nIndex == 999149 then
				strTarget = "   "..MissionTrack_GetTrack_DHXYStage2_3(nMissionIndex)
			elseif nIndex == 999150 then
				strTarget = "   "..MissionTrack_GetTrack_DHXYStage2_4(nMissionIndex)
			elseif nIndex == 999151 then
				strTarget = "   "..MissionTrack_GetTrack_DHXYStage2_5(nMissionIndex)
			elseif nIndex == 999152 then
				strTarget = "   "..MissionTrack_GetTrack_DHXYStage2_6(nMissionIndex)
			end
		end
		--大话西游第一阶段主线剧情-ypl
		if (nMissionTrackType == 41 and nIndex == 999119) then
			strTarget = "   "..QuestLog_GetTrack_2024DHMission(nMissionIndex);
		end	

		--2024Q2大话西游第三阶段主线剧情
		if nMissionTrackType == 42 then
			if nIndex == 999191 then
				strTarget = "   "..MissionTrack_GetTrack_DHXYStage3_1(nMissionIndex)
			end
			if nIndex == 999193 then
				strTarget = "   "..MissionTrack_GetTrack_DHXYStage3_2(nMissionIndex)
			end
		end	
		
		-- 2024Q3版本稳活活动
		if nMissionTrackType == 43 then
			if nIndex == 999423 then
				strTarget = "   "..MissionTrack_GetTrack_WenHuoMission1(nMissionIndex)
			elseif nIndex == 999424 then
				strTarget = "   "..MissionTrack_GetTrack_WenHuoMission2(nMissionIndex)
			elseif nIndex == 999427 then
				strTarget = "   "..MissionTrack_GetTrack_WenHuoMission5(nMissionIndex)
			end
		end	
		
        --fengyundaka
        if (nMissionTrackType == 44 and nIndex == 893602) then
            strTarget = "   "..MissionTrack_GetTrack_FengYunDaKa(nMissionIndex);
        end
		
		if ( nMissionTrackType == 45 ) then
	       local nIndex = DataPool:GetPlayerMission_Display(nMissionIndex, 7)
		   if nIndex == 900057 then
			  strTarget = "   "..MissionTrack_GetTrack_QIXIYURE_1(nMissionIndex)
		   elseif nIndex == 900058 then
			  strTarget = "   "..MissionTrack_GetTrack_QIXIYURE_2(nMissionIndex)
		   elseif nIndex == 900059 then
			  strTarget = "   "..MissionTrack_GetTrack_QIXIYURE_3(nMissionIndex)
		   elseif nIndex == 900060 then
			  strTarget = "   "..MissionTrack_GetTrack_QIXIYURE_4(nMissionIndex)
		   elseif nIndex == 900061 then
			  strTarget = "   "..MissionTrack_GetTrack_QIXIYURE_5(nMissionIndex)
		   end
	   end

	    --特写人物追踪处理
	    if nMissionTrackType == 2 then
    		for _, item in g_MissionTrack_Display_Special_Process do
            	if nIndex == item.missionIndex then
            		strTarget = item.missionTargetStr .. "#r" .. strAppend
            	end
    	    end
    	end
    end

    --表格任务,Mission_Delivery.txt,天师举荐
    --我也觉得特来特去的挺恶,但是改配表机制貌似不现实...不是兄弟无能,实在是共军太狡猾
    if nMissionTrackType == 2 and nIndex >= 1019110 and nIndex <= 1019119 then
        strTarget = "#{XSRWGZ_110917_116}"
    end

	-- 【2026Q2】七夕联动剧情 任务脚本3
	if 505210 == nIndex then
		local finished = DataPool:GetPlayerMission_Variable(nMissionIndex, 0)
		local step = DataPool:GetPlayerMission_Variable(nMissionIndex, 2)
		if nFinished == 0 and step >= 5 then
			strTarget = "   #W"..MissionTrack_GetTrack_2026QiXiJuQing3(nMissionIndex)
		end
	end

	MissionTrack_ListBoxTransparent:AddItemExWithoutLayout("#e010101" ..strTarget, nMissionIndex, 0, color, 4);
end

--新暗器引导任务
function MissionTrack_NewDark(nSelIndex)

	local Data1 = DataPool:GetPlayerMission_Variable( nSelIndex, 1 )
	local Data2 = DataPool:GetPlayerMission_Variable( nSelIndex, 2 )
	local Data3 = DataPool:GetPlayerMission_Variable( nSelIndex, 3 )
	local Data4 = DataPool:GetPlayerMission_Variable( nSelIndex, 4 )

	local strComplete = "#{JCLY_160411_191}".."#r    "..ScriptGlobal_Format("#{JCLY_160411_192}", Data1).."#r    "..ScriptGlobal_Format("#{JCLY_160411_193}", Data2).."#r    "..ScriptGlobal_Format("#{JCLY_160411_194}", Data3).."#r    "..ScriptGlobal_Format("#{JCLY_160411_195}", Data4)
	
	return strComplete
	
end

--  更新可接任务列表
function MissionTrack_UpdateWillGet()

    --  切换界面状态为 可接任务 追踪
    MissionTrack_HaveGet:SetCheck(0);
    MissionTrack_WillGet:SetCheck(1);
    g_nNowCheck = 2;

    --  这里需要用到玩家等级
    --  如果在擂台中到这里了不是会出事么?
    local nMyLevel = Player:GetData( "LEVEL" )
	local isCompatPKServer = Player:GetData("IsPKServer_JD")
	local nCompatPKLevel = Player:GetData( "LEVEL_CompatPKLV" )
	if isCompatPKServer == 1 and nCompatPKLevel < nMyLevel then
		nMyLevel = nCompatPKLevel
	end
    MissionTrack_ListBoxTransparent:ClearListBoxEx();

    --  获得玩家所有可以接的任务
    CollectMissionOutline();

	local nXiaKe = Player:GetData("IsXiaKe") --2025侠客行引导任务
    --  依然是根据每个任务类型进行分类
    for iMissionType=1,200 do             --现任务类型一共200种
        local strOutlineName = "#cff9900" .. DataPool:GetMissionInfo_Kind( iMissionType );  --#gFE7E82

        --  原先应该是个 与 逻辑, 现在才是 或 逻辑
        --  不合法的任务类型数据, 继续检查下个任务
        if( strOutlineName == "" or strOutlineName == 0) then
            continue;
        end

        local iStart = iMissionType*10000;
        local DeployNum = GetMissionOutlineNum( iMissionType )
        --  可接任务数的判断可以提到外边去, 减少循环次数
           if( DeployNum <= 0 or iMissionType == 50) then       --帮会城市任务，这里不要了
            continue;
        end
		if(iMissionType == 153 and nXiaKe ~= 1) then      --2025侠客行引导任务
            continue;
        end
        --  当前类型的一组可接任务
        local OutLineMission_Seq = {};
        local i = 1;
        for i=1, DeployNum do
            local color= "";
            local MissionLevel, MinLevel, MaxLevel, strNpcName, strNpcPos, strScene, strMissionName, PosX, PosY, SceneID = GetMissionOutlineInfo( iMissionType, i );
            --  如果任务与玩家的等级差在[-3, 5]之间, 则构造一条该任务的追踪信息, 插入到该类型的任务表中
            if( MissionLevel - nMyLevel <= 5 and MissionLevel >= nMyLevel -3) then
                local strInfo = "";
                strInfo = " #Y("..MissionLevel..")"..strMissionName;   --任务名
                table.insert(OutLineMission_Seq,strInfo)
                strInfo = "";
                strNpcPos = "#{_INFOAIM"..(PosX)..","..(PosY)..","..(SceneID)..","..(strNpcName).."}";
                if strScene and strScene ~= "" then
                    strInfo = strInfo.."   #G"..strScene.."  #R"..strNpcName..strNpcPos;
                else
                    strInfo = strInfo.."   #R"..strNpcName..strNpcPos
                end
                table.insert(OutLineMission_Seq,strInfo)        --任务追踪信息
            end
        end

        --  这处理真简单
        if (table.getn(OutLineMission_Seq) > 0) then
            --  插入任务类型的一条数据
            MissionTrack_ListBoxTransparent:AddItemExWithoutLayout( "#e010101" ..strOutlineName, iStart, 0 )

            --  插入剩余可接的任务类型数据
            local nn = 1;
            color = "FFD9F80A";    --黄色
            for nn,Per_Seq in ipairs(OutLineMission_Seq) do
                MissionTrack_ListBoxTransparent:AddItemExWithoutLayout( "#e010101" ..Per_Seq, (iStart+nn), 0, color, 4);
            end
        end
    end

    MissionTrack_ListBoxTransparent:RequestLayout();
end

--  关闭任务追踪界面
function MissionTrack_CloseFunc()
    this:Hide();
    DataPool:SetTrackFuncShow(1, 0);
    DataPool:UpdateTrackStateButton(0);
end

--  点击任务追踪的已经任务按钮, 更新列表为已接任务
--  这里关于按钮的状态处理可以省去
function MissionTrack_HaveGetFunc()
    MissionTrack_HaveGet:SetCheck(1);
    MissionTrack_WillGet:SetCheck(0);
    if(g_nNowCheck ~= 1) then
        MissionTrack_UpdateHaveGetMission(-1);
    end
end

--  点击任务追踪的可接任务按钮, 更新列表为可接任务
--  这里关于按钮的状态处理可以省去
function MissionTrack_WillGetFunc()
    MissionTrack_HaveGet:SetCheck(0);
    MissionTrack_WillGet:SetCheck(1);
    if(g_nNowCheck ~= 2) then
        MissionTrack_UpdateWillGet();
    end
end

--  点击任务追踪的详细信息按钮, 打开任务列表, 显示该任务的详细信息
function MissionTrack_ItemContextClickedForEye()
    local curSceneID = GetSceneID();
    if (curSceneID == g_DiFu_Scene_Id) then
            return
    end

    local nClickedItemInx = MissionTrack_ListBoxTransparent:GetClickedButtonItem();
    DataPool:MissionTrackGotoQuestLog(nClickedItemInx);
end

--  点击任务追踪的关闭按钮, 关闭对该任务的追踪
function MissionTrack_ItemContextClickedForClose()
    local nClickedItemInx = MissionTrack_ListBoxTransparent:GetClickedButtonItem();
    DataPool:SetMissionTrackOpen(nClickedItemInx, 0);
    MissionTrack_UpdateHaveGetMission(-1);
    DataPool:UpdateQuestLogByTrack();
end

--  增大界面高度
function MissionTrack_On_Height_Add()
    local nHeightOld = MissionTrack_Frame:GetProperty("AbsoluteHeight");
    local nListTopOld = MissionTrack__Frame:GetProperty("AbsoluteYPosition");
    local nHeightOld2 = MissionTrack__Frame:GetProperty("AbsoluteHeight");
    local nFunctionTopOld = MissionTrack_Function_Frame:GetProperty("AbsoluteYPosition");
    if (tonumber(nHeightOld) < 379) then
        MissionTrack_Frame:SetProperty("AbsoluteHeight", nHeightOld+17);
        MissionTrack__Frame:SetProperty("AbsoluteHeight", nHeightOld2+17);
        MissionTrack__Frame:SetProperty("AbsoluteYPosition", nListTopOld);
        MissionTrack_Function_Frame:SetProperty("AbsoluteYPosition", nFunctionTopOld);
    end
end

--  减小界面高度
function MissionTrack_On_Height_Reduce()
    local nHeightOld = MissionTrack_Frame:GetProperty("AbsoluteHeight");
    local nListTopOld = MissionTrack__Frame:GetProperty("AbsoluteYPosition");
    local nHeightOld2 = MissionTrack__Frame:GetProperty("AbsoluteHeight");
    local nFunctionTopOld = MissionTrack_Function_Frame:GetProperty("AbsoluteYPosition");
    if (tonumber(nHeightOld) > 158) then
        MissionTrack_Frame:SetProperty("AbsoluteHeight", nHeightOld-17);
        MissionTrack__Frame:SetProperty("AbsoluteYPosition", nListTopOld);
        MissionTrack__Frame:SetProperty("AbsoluteHeight", nHeightOld2-17);
        MissionTrack_Function_Frame:SetProperty("AbsoluteYPosition", nFunctionTopOld);
    end
end

--  增大界面宽度
function MissionTrack_On_Width_Add()
    --MissionTrack_Frame_Context:SetProperty("Alpha", "10");

    local nWidthOld = MissionTrack_Frame:GetProperty("AbsoluteWidth");
    local nFrameLeftOld = MissionTrack_Frame:GetProperty("AbsoluteXPosition");
    local nCheckBoxX = MissionTrack_CheckBox_Frame:GetProperty("AbsoluteXPosition");
    local nDragX = MissionTrack_DragTitle:GetProperty("AbsoluteXPosition");
    local nCloseX = MissionTrack_Close:GetProperty("AbsoluteXPosition");
    local nWidthOld2 = MissionTrack__Frame:GetProperty("AbsoluteWidth");
    local nFuncLeft = MissionTrack_Function_Frame:GetProperty("AbsoluteXPosition");
    local nLockX = MissionTrack_Lock:GetProperty("AbsoluteXPosition");
    if (tonumber(nWidthOld) < 310) then
        MissionTrack_Frame:SetProperty("AbsoluteWidth", nWidthOld + 10);
        MissionTrack_Frame:SetProperty("AbsoluteXPosition", nFrameLeftOld-10);
        MissionTrack_CheckBox_Frame:SetProperty("AbsoluteXPosition", nCheckBoxX + 10);
        MissionTrack_DragTitle:SetProperty("AbsoluteXPosition", nDragX + 10);
        MissionTrack_Close:SetProperty("AbsoluteXPosition", nCloseX + 10);
        MissionTrack__Frame:SetProperty("AbsoluteWidth", nWidthOld2 + 10);
        MissionTrack_Function_Frame:SetProperty("AbsoluteXPosition", nFuncLeft + 10);
        MissionTrack_Lock:SetProperty("AbsoluteXPosition", nLockX + 10);
        MissionTrack_UnLock:SetProperty("AbsoluteXPosition", nLockX + 10);
    end
end

--  减小界面宽度
function MissionTrack_On_Width_Reduce()
    local nWidthOld = MissionTrack_Frame:GetProperty("AbsoluteWidth");
    local nFrameLeftOld = MissionTrack_Frame:GetProperty("AbsoluteXPosition");
    local nCheckBoxX = MissionTrack_CheckBox_Frame:GetProperty("AbsoluteXPosition");
    local nDragX = MissionTrack_DragTitle:GetProperty("AbsoluteXPosition");
    local nCloseX = MissionTrack_Close:GetProperty("AbsoluteXPosition");
    local nWidthOld2 = MissionTrack__Frame:GetProperty("AbsoluteWidth");
    local nFuncLeft = MissionTrack_Function_Frame:GetProperty("AbsoluteXPosition");
    local nLockX = MissionTrack_Lock:GetProperty("AbsoluteXPosition");
    if (tonumber(nWidthOld) > 230) then
        MissionTrack_Frame:SetProperty("AbsoluteWidth", nWidthOld - 10);
        MissionTrack_Frame:SetProperty("AbsoluteXPosition", nFrameLeftOld+10);
        MissionTrack_CheckBox_Frame:SetProperty("AbsoluteXPosition", nCheckBoxX - 10);
        MissionTrack_DragTitle:SetProperty("AbsoluteXPosition", nDragX - 10);
        MissionTrack_Close:SetProperty("AbsoluteXPosition", nCloseX - 10);
        MissionTrack__Frame:SetProperty("AbsoluteWidth", nWidthOld2 - 10);
        MissionTrack_Function_Frame:SetProperty("AbsoluteXPosition", nFuncLeft - 10);
        MissionTrack_Lock:SetProperty("AbsoluteXPosition", nLockX - 10);
        MissionTrack_UnLock:SetProperty("AbsoluteXPosition", nLockX - 10);
    end
end

--  界面锁定或者解除锁定
function MissionTrack_On_Lock()

    if (g_LockState == 0) then   --准备锁定
        g_LockState = 1;
        MissionTrack_UnLock:Show();
        MissionTrack_Lock:Hide();
        MissionTrack_HaveGet:SetProperty("MouseHollow", "True");
        MissionTrack_WillGet:SetProperty("MouseHollow", "True");
        MissionTrack_Close:SetProperty("MouseHollow", "True");
        MissionTrack_Frame:SetProperty("MouseHollow", "True");
        MissionTrack_DragTitle:SetProperty("MouseHollow", "True");
        MissionTrack_Function_Frame:SetProperty("MouseHollow", "True");
        MissionTrack_Height_Add:SetProperty("MouseHollow", "True");
        MissionTrack_Height_Reduce:SetProperty("MouseHollow", "True");
        MissionTrack_Width_Add:SetProperty("MouseHollow", "True");
        MissionTrack_Width_Reduce:SetProperty("MouseHollow", "True");
        MissionTrack_Reset:SetProperty("MouseHollow", "True");
    else               --解锁
        g_LockState = 0;
        MissionTrack_Lock:Show();
        MissionTrack_UnLock:Hide();
        MissionTrack_HaveGet:SetProperty("MouseHollow", "False");
        MissionTrack_WillGet:SetProperty("MouseHollow", "False");
        MissionTrack_Close:SetProperty("MouseHollow", "False");
        MissionTrack_Frame:SetProperty("MouseHollow", "False");
        MissionTrack_DragTitle:SetProperty("MouseHollow", "False");
        MissionTrack_Function_Frame:SetProperty("MouseHollow", "False");
        MissionTrack_Height_Add:SetProperty("MouseHollow", "False");
        MissionTrack_Height_Reduce:SetProperty("MouseHollow", "False");
        MissionTrack_Width_Add:SetProperty("MouseHollow", "False");
        MissionTrack_Width_Reduce:SetProperty("MouseHollow", "False");
        MissionTrack_Reset:SetProperty("MouseHollow", "False");
    end
    MissionTrack_ShowORHideFunc(0);

end

--  重置界面尺寸和位置
function MissionTrack_On_Reset()
    MissionTrack_Frame:SetProperty("UnifiedSize", g_MissionTrack_Frame_UnifiedSize);
    MissionTrack_Frame:SetProperty("UnifiedXPosition", g_MissionTrack_Frame_UnifiedXPosition);
    MissionTrack_Frame:SetProperty("UnifiedYPosition", g_MissionTrack_Frame_UnifiedYPosition);

    MissionTrack__Frame:SetProperty("AbsolutePosition", g_MissionTrack__Frame_AbsolutePosition);
    MissionTrack__Frame:SetProperty("AbsoluteSize", g_MissionTrack__Frame_AbsoluteSize);

    MissionTrack_Function_Frame:SetProperty("AbsolutePosition", g_MissionTrack_Function_Frame_AbsolutePosition);

    MissionTrack_DragTitle:SetProperty("AbsolutePosition", g_MissionTrack_DragTitle_AbsolutePosition);
    MissionTrack_Close:SetProperty("AbsolutePosition", g_MissionTrack_Close_AbsolutePosition);
    MissionTrack_CheckBox_Frame:SetProperty("AbsolutePosition", g_MissionTrack__CheckBox_Frame_AbsolutePosition);
    MissionTrack_Lock:SetProperty("AbsolutePosition", g_MissionTrack_Lock_AbsolutePosition);
    MissionTrack_UnLock:SetProperty("AbsolutePosition", g_MissionTrack_UnLock_AbsolutePosition);
end

--  鼠标进入, 显示界面尺寸控制条
function MissionTrack_Func_MouseEnter()
    MissionTrack_ShowORHideFunc(1);
end

--  鼠标离开, 隐藏界面尺寸控制条
function MissionTrack_Func_MouseLeave()
    MissionTrack_ShowORHideFunc(0);
end

--  隐藏或显示界面尺寸控制条
function MissionTrack_ShowORHideFunc( nShow )

    if (nShow >= 1 and g_LockState == 0) then
        MissionTrack_Height_Add:Show();
        MissionTrack_Height_Reduce:Show();
        MissionTrack_Width_Add:Show();
        MissionTrack_Width_Reduce:Show();
        MissionTrack_Reset:Show();
		MissionTrack_Function_FrameBK:Show();
    else
        MissionTrack_Height_Add:Hide();
        MissionTrack_Height_Reduce:Hide();
        MissionTrack_Width_Add:Hide();
        MissionTrack_Width_Reduce:Hide();
        MissionTrack_Reset:Hide();
		MissionTrack_Function_FrameBK:Hide();
    end
end

--  设置界面Alpha值
function MissionTrack_SetAlpha(val)
    local bNum = val
    if tonumber(bNum) < 0.3 then
        MissionTrack_Frame:SetProperty( "Alpha", "0.5" );
        MissionTrack_Function_Frame:SetProperty( "Alpha", "0.5" );
        MissionTrack_ListBoxTransparent:SetVScrollbarAlpha("0.3");
    elseif tonumber(bNum) < 0.5 then
        MissionTrack_Frame:SetProperty( "Alpha", "0.5" );
        MissionTrack_Function_Frame:SetProperty( "Alpha", "0.5" );
        MissionTrack_ListBoxTransparent:SetVScrollbarAlpha(val);
    else
        MissionTrack_Frame:SetProperty( "Alpha", val );
        MissionTrack_Function_Frame:SetProperty( "Alpha", val );
        MissionTrack_ListBoxTransparent:SetVScrollbarAlpha(val);
    end
    MissionTrack_Frame_Context:SetProperty( "Alpha", val );
end

--TT53675对所有不符合规范，没有将missionparam第0位做为任务完成标志的任务脚本做特殊处理，判断任务是否完成
--  目前的写法已经算比较清楚了, 增加适当注释, 不做修改
function IsMissionSuccess(nSelIndex)
    --  任务变量索引
    --  通常第0位记录的是任务结果, 然后按照顺序逐一向后排
    local MissionParam_Index = 0
    local Mission_Variable = 0

    --任务需要杀的npc
    local nDemandKillNum,Kill_Random_Type = DataPool:GetPlayerMissionDemandKill_Num(nSelIndex);
    if( nDemandKillNum > 0 ) then
        for i=1, nDemandKillNum do
            --    需要的NPC, 需要的数量
            local nNPCName, nNum = DataPool:GetPlayerMissionDemand_NPC(i-1,Kill_Random_Type,nSelIndex);
            --  获得当前已经完成的数量
            Mission_Variable = DataPool:GetPlayerMission_Variable(nSelIndex,MissionParam_Index,Kill_Random_Type,i-1);
            --
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
            local szName, nItemID, nNum = DataPool:GetPlayerMissionDemand_Item(i-1,Item_Random_Type,nSelIndex);
            --  获得当前已经完成的数量, 这部分数据是从背包中取得的, 不记录到任务变量中
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
            --  获得当前已经完成的数量
            Mission_Variable = DataPool:GetPlayerMission_Variable(nSelIndex,MissionParam_Index);
            --
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
            --  需要的类型, 需要的数量, 已经完成的黑素瘤
            local strCustom, nNeedNum,nCompleteNum = DataPool:GetPlayerMissionRandomCustom(i-1,nSelIndex);

            if nCompleteNum < nNeedNum then
                return 0
            end
        end
    end

    return 1
end

--  获取当前玩家已接的一组相同类型的任务描述
--  kind    要获取的任务类型
--  kindTbl 要填充的记录表
--
--  该函数采取短路原则, 对于不满足条件的任务将离开返回, 这样可以减少缩进
function MissionTrack_GroupHaveGetMission( kind, kindTbl )
    --  一条任务记录
    local Constitutes = {};
    --  是否有该类型任务的标志
    local bHave = 0;
    --  变量玩家所有的已接任务
    for i=1, g_nMissionNum do
        --  如果当前位置没有任务, 检查下个任务
        if (DataPool:GetPlayerMission_InUse(i-1) ~= 1) then
            continue;
        end

        --  如果当前任务与指定的任务类型不一致, 检查下个任务
        local MissionKind = DataPool:GetPlayerMission_Kind(i-1);
        if(MissionKind ~= kind) then
            continue;
        end

        --  如果该任务类型不是可追踪的类型, 检查下个任务
        --  这个检查可以提到循环外执行, 这样可以减少检查次数
        local nThisKindHaveMission = DataPool:HaveMisstionTrackThisType(MissionKind);
        if (nThisKindHaveMission ~= 1 ) then
            continue;
        end

        --  虽然任务追踪不支持折叠功能, 但这部分代码还是保留吧, 省心
        if ( MissionPucker[kind] > 0 ) then
            --  获得 g_MissionTarget 字段
            local strInfo = DataPool:GetPlayerMission_Memo(i-1);
            --  获得 g_MissionLevel 字段
            local nMissionLevel = DataPool:GetPlayerMission_Level(i-1);

            --  任务等级是玩家等级的特殊处理
            if nMissionLevel == LEVEL_TO_MY_LEVEL then
                nMissionLevel =  Player:GetData( "LEVEL" );
                if (nMissionLevel > 0) then   --进入擂台后得到是0，只是显示问题，不想改服务器逻辑，所以用这么一种很弱智的方法
                    --  非擂台场景获取的玩家等级是正常的, 此时会记录一个临时等级
                    g_Temp_Mylevel = nMissionLevel;
                else
                    --  擂台场景的玩家等级不正确, 将上一次记录的临时等级指定为任务等级, 避免出现0的情况
                    nMissionLevel = g_Temp_Mylevel;
                end
            end

            --  有该类型的任务, 增加一条任务类型的记录, 仅增加一次
            if(bHave == 0) then
                local str= "#cff9900" .. DataPool:GetMissionInfo_Kind(kind);   --title
                Constitutes = {str,100+kind,"",0}
                --unused
                --table.insert(MissionTitles, str);
                table.insert(kindTbl,Constitutes)
                bHave = 1;
            end

            --------------------------------------------------
            --  下面开始构造任务描述文字

            local strOKFail = "";
            local nFinished = 0;
            --  显示任务是否已完成或已失败
            local Mission_Variable = DataPool:GetPlayerMission_Variable(i-1,0);

            --  特殊任务, 特殊处理
               if MissionTrack_IsSpecialMission(i-1) == 1 then
                Mission_Variable = IsMissionSuccess(i-1)
               end

            --  生成任务结果文字
            if(Mission_Variable >0) then
                if(Mission_Variable == 1) then
                    strOKFail = "完成";
                    nFinished = 1
                elseif(Mission_Variable == 2) then
                    strOKFail = "失败";
                end
            end

            --  获得简短的任务描述文字
            color = "FFF8A10A";    --橙色
            local nChange, strMissionName = DataPool:GetMissionShortName(strInfo);--string.sub(strInfo, -6);

            --  任务描述是否过长
            if (nChange > 0) then
                strMissionName = strMissionName .. "...";
            end

            --  生成一条任务记录
            if (nFinished == 1) then   --已完成
                Constitutes = {"  #Y(" .. nMissionLevel ..") " .. strMissionName .. " #G" .. strOKFail,i-1,color,nMissionLevel,nFinished};
            else
                Constitutes = {"  #Y(" .. nMissionLevel ..") " .. strMissionName .. " " .. strOKFail,i-1,color,nMissionLevel,nFinished};
            end

            --  增加一条任务记录
            table.insert(kindTbl,Constitutes)
        else    --  仅折叠状态下会进行下面的处理, 但 任务追踪 界面没有折叠选项, 因此下述代码不会被执行
            --  有该类型的任务, 增加一条任务类型的记录, 仅增加一次
            if(bHave == 0) then
                local str= "#gFE7E82" .. DataPool:GetMissionInfo_Kind(kind);
                Constitutes = {str,100+kind,"",0}
                table.insert(kindTbl,Constitutes)
                --unused
                --table.insert(MissionTitles, str);
                bHave = 1;
            end
        end
    end

    --  返回kind类型的已接任务列表
    return kindTbl;
end

--  是否是特殊任务, 任务状态不是记录在0号位置的.
function MissionTrack_IsSpecialMission( index )
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

--  比较器, MissionTrack原本直接引用的是QuestLog的函数...
--  现在复制为两份, 并且拥有各自的名称
function MissionTrack_CompareTable(table_a,table_b)
    if table_a[4] < table_b[4] then
        return true
    else
        return false
    end
end

--!!!reloadscript =MissionTrack
function MissionTrack_FreshManGuide(nType, nTextID, nPosID)
    if nType ~= 1 and      --1 is reset and open
        nType ~= 2 then    --2 is modify
        return
    end

    if not this:IsVisible() then
	    return
    end

    if 1 ~= g_nNowCheck then
        return  --不是显示已接任务,不管
    end
    if Player:GetData("LEVEL") > 15 then
        return
    end

    local fX, fY = this:GetChildOffset("MissionTrack_Frame_Context")
    local fW = tonumber(MissionTrack_Frame_Context:GetProperty("AbsoluteWidth"))
    local fH = tonumber(MissionTrack_Frame_Context:GetProperty("AbsoluteHeight"))
    local PosX = tonumber(MissionTrack_Frame:GetProperty("AbsoluteXPosition"))
    local PosY = tonumber(MissionTrack_Frame:GetProperty("AbsoluteYPosition"))
    if 1 == nPosID then
--        fX = fX + MissionTrack_Frame_Context:GetProperty("AbsoluteWidth") / 2
--        fY = fY + MissionTrack_Frame_Context:GetProperty("AbsoluteHeight") - 20
		fX = math.floor(tonumber(fX + PosX + fW / 2))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 2 == nPosID then
--        fX = fX + MissionTrack_Frame_Context:GetProperty("AbsoluteWidth") / 2
--        fY = fY + MissionTrack_Frame_Context:GetProperty("AbsoluteHeight") / 2 + 15
		fX = math.floor(tonumber(fX + PosX + fW / 2))
        fY = math.floor(tonumber(fY + PosY + fH / 2 + 15))
    elseif 3 == nPosID then	--	第一次杀怪（完成）
--        fX = fX + 90
--        fY = fY + MissionTrack_Frame_Context:GetProperty("AbsoluteHeight") - 20
		fX = math.floor(tonumber(fX + PosX + 110))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 4 == nPosID then
--        fX = fX + MissionTrack_Frame_Context:GetProperty("AbsoluteWidth") / 2 - 33
--        fY = fY + MissionTrack_Frame_Context:GetProperty("AbsoluteHeight") / 2 + 33
		fX = math.floor(tonumber(fX + PosX + (fW / 2) - 5))
        fY = math.floor(tonumber(fY + PosY + fH / 2 + 58))
    elseif 5 == nPosID then
		fX = math.floor(tonumber(fX + PosX + (fW * 0.5) + 38))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 6 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 40))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 7 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 35))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 8 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 25))
        fY = math.floor(tonumber(fY + PosY + 100))
    elseif 9 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 30))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 10 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 30))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 11 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 40))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 12 == nPosID then
		fX = math.floor(tonumber(fX + PosX + 70))
        fY = math.floor(tonumber(fY + PosY + fH - 15))
    elseif 13 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 50))
        fY = math.floor(tonumber(fY + PosY + 35))
    elseif 14 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 35))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 15 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 40))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 16 == nPosID then	--	抓珍兽
		fX = math.floor(tonumber(fX + PosX + 75))
        fY = math.floor(tonumber(fY + PosY + (fH * 0.5) + 15))
    elseif 17 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 40))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 18 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 25))
        fY = math.floor(tonumber(fY + PosY + fH - 35))
    elseif 19 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 30))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 20 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2))
        fY = math.floor(tonumber(fY + PosY + (fH * 0.5) + 10))
    elseif 21 == nPosID then
		fX = math.floor(tonumber(fX + PosX + 65))
        fY = math.floor(tonumber(fY + PosY + fH - 55))
    elseif 22 == nPosID then
		fX = math.floor(tonumber(fX + PosX + 90))
        fY = math.floor(tonumber(fY + PosY + 50))
    elseif 23 == nPosID then		--	完成追踪....奶奶滴....这个最坑爹		剑阁猴患
		fX = math.floor(tonumber(fX + PosX + (fW / 2)))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 24 == nPosID then		--	何谓行善
		fX = math.floor(tonumber(fX + PosX + (fW / 2) + 40))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 25 == nPosID then		--	抓珍兽
		fX = math.floor(tonumber(fX + PosX + 50))
        fY = math.floor(tonumber(fY + PosY + fH - 10))
    elseif 26 == nPosID then		--	喜庆烟火
		fX = math.floor(tonumber(fX + PosX + (fW / 2) + 40))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 27 == nPosID then		--	江湖问答
		fX = math.floor(tonumber(fX + PosX + (fW / 2) + 40))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 28 == nPosID then		--	最后的试炼
		fX = math.floor(tonumber(fX + PosX + 30))
        fY = math.floor(tonumber(fY + PosY + fH - 10))
    elseif 29 == nPosID then		--	十年
	fX = math.floor(tonumber(fX + PosX + (fW / 2) + 40))
        fY = math.floor(tonumber(fY + PosY + 45 ))
    elseif 30 == nPosID then		--	第一只珍兽
	fX = math.floor(tonumber(fX + PosX + (fW / 2)))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
    elseif 31 == nPosID then
		fX = math.floor(tonumber(fX + PosX + 20))
        fY = math.floor(tonumber(fY + PosY + 75))
    elseif 32 == nPosID then		--	初级技能完成
	fX = math.floor(tonumber(fX + PosX + (fW * 0.5) + 28))
        fY = math.floor(tonumber(fY + PosY + fH - 20))
	elseif 33 == nPosID then
		fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+80))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
	elseif 34 == nPosID then
		fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+40))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
	elseif 35 == nPosID then
		fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+60))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
	elseif 36 == nPosID then
		fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+77))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
    elseif 37 == nPosID then
        fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+80))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
    elseif 38 == nPosID then
        fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+90))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
    elseif 39 == nPosID then
        fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+90))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
    elseif 40 == nPosID then
        fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+75))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
    elseif 41 == nPosID then
    	fX = math.floor(tonumber(fX + PosX + (fW * 0.5)-55))
        fY = math.floor(tonumber(fY + PosY + fH )-50)
    elseif 42 == nPosID then
    	fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+10))
	    fY = math.floor(tonumber(fY + PosY + fH )-85)
    elseif 43 == nPosID then  --用来并肩作战(珍兽)、无量玉臂(坐骑)寻路指引
        fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+40))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
    elseif 44 == nPosID then  --浩劫前夕(门派技能)寻路指引
        fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+40))
        fY = math.floor(tonumber(fY + PosY + fH )-15)
	elseif 45 == nPosID then
        fX = math.floor(tonumber(fX + PosX + (fW * 0.5)+25))
        fY = math.floor(tonumber(fY + PosY + fH )-85)
    else
        return               --unkown position
    end
    g_CurGuide = nPosID
    if nType == 1 and nPosID ~= 33 and nPosID ~= 43 and nPosID ~= 44 then  --missiontrack特写,为了不被其他窗口遮挡
        CloseAllWindow()                                  --43为特写。否则会关闭骑马的窗口
    end
--    OpenFreshManGuide(nType, nTextID, fX, fY, "MissionTrack", "southwest")

    if nPosID == 9 then
	    g_ShowRect = 1
	    MissionTrack_ShowAutoPathRect(1)
    else
	g_ShowRect = 0
    end

    OpenFreshManGuideNew(nType, fX, fY, fW, fH, 2, 1, "MissionTrack")
end

function MissionTrack_GetDAKATarget( nSelIndex )
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
	local strComplete = ScriptGlobal_Format("#{MBHTL_130906_65}",  city, posx,posz,sceneid)


	return strComplete
end

function MissionTrack_ShowAutoPathRect(nType)
	if g_ShowRect > 0 then
		local fX, fY = this:GetChildOffset("MissionTrack_Frame_Context")
		local fW = tonumber(MissionTrack_Frame_Context:GetProperty("AbsoluteWidth"))
		local fH = tonumber(MissionTrack_Frame_Context:GetProperty("AbsoluteHeight"))
		local PosX = tonumber(MissionTrack_Frame:GetProperty("AbsoluteXPosition"))
		local PosY = tonumber(MissionTrack_Frame:GetProperty("AbsoluteYPosition"))
		fX = math.floor(tonumber(fX + PosX + fW / 2 + 8))
	        fY = math.floor(tonumber(fY + PosY + fH - 34))
		PushEvent("OPEN_FRESHMANGUIDE_AUTOPATH", "MisstionTrack", nType, fX, fY)
	end
end

function MissionTrack_OnMoved()
    if "MissionTrack" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
--        OpenFreshManGuide(2, -1, -1, -1)
	MissionTrack_ShowAutoPathRect(2)
	MissionTrack_FreshManGuide(2, -1, g_CurGuide)
    end
end
function MissionTrack_OnHidden()
    if "MissionTrack" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
	g_ShowRect = 0
    end
end
function MissionTrack_GetXunBaoLeFanTianTarget( nMissionIndex )

    local pos =
{
    [1] = {
        [1] = {SceneID = 1, PosX = 366, PosZ = 170 ,SceneName = "苏州"},
        [2] = {SceneID = 1, PosX = 179, PosZ = 189 ,SceneName = "苏州"},
        [3] = {SceneID = 1, PosX = 350, PosZ = 236 ,SceneName = "苏州"},
    },
    [2] = {
        [1] = {SceneID = 0, PosX = 307, PosZ = 296 ,SceneName = "洛阳"},
        [2] = {SceneID = 0, PosX = 145, PosZ = 182 ,SceneName = "洛阳"},
        [3] = {SceneID = 0, PosX = 179, PosZ = 258 ,SceneName = "洛阳"},
    },
    [3] = {
        [1] = {SceneID = 2, PosX = 241, PosZ = 26  ,SceneName = "大理"},
        [2] = {SceneID = 2, PosX = 160, PosZ = 174 ,SceneName = "大理"},
        [3] = {SceneID = 2, PosX = 270, PosZ = 126 ,SceneName = "大理"},
    },
}
    local index_suzhou = 1
    local index_luoyang = 2
    local index_dali = 3

    local sub_suzhou = DataPool:GetPlayerMission_Variable( nMissionIndex, 5 )
    local sub_luoyang = DataPool:GetPlayerMission_Variable( nMissionIndex, 6 )
    local sub_dali = DataPool:GetPlayerMission_Variable( nMissionIndex, 7 )

    local city_suzhou = pos[index_suzhou][sub_suzhou].SceneName;
    local posx_suzhou = pos[index_suzhou][sub_suzhou].PosX;
    local posz_suzhou = pos[index_suzhou][sub_suzhou].PosZ;
    local sceneid_suzhou = pos[index_suzhou][sub_suzhou].SceneID;

    local city_luoyang = pos[index_luoyang][sub_luoyang].SceneName;
    local posx_luoyang = pos[index_luoyang][sub_luoyang].PosX;
    local posz_luoyang = pos[index_luoyang][sub_luoyang].PosZ;
    local sceneid_luoyang = pos[index_luoyang][sub_luoyang].SceneID;

    local city_dali = pos[index_dali][sub_dali].SceneName;
    local posx_dali = pos[index_dali][sub_dali].PosX;
    local posz_dali = pos[index_dali][sub_dali].PosZ;
    local sceneid_dali = pos[index_dali][sub_dali].SceneID;

    local strComplete = ScriptGlobal_Format("#{XBLFT_131112_98}", posx_suzhou,posz_suzhou,posx_luoyang,posz_luoyang,posx_dali,posz_dali)

    return strComplete
end


--七夕鹊起任务
--function MissionTrack_IsQiXiQueQiaoDate()
--	local StartDateTime = 20160801
--	local EndMissionTime= 20160814 
--	local CurTime = DataPool:GetServerDayTime();
--	if(CurTime >= StartDateTime and CurTime <= EndMissionTime) then
--		return 1
--	end
--	return 0
--end

--【2017九星神器每日任务】
function QuestLog_GetTrack_9_Star(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )

	if finish == 1 then
		local strComplete = "#W".."#{JXMR_171027_22}"
		return strComplete		
	else
		local num = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
		local strComplete = "#W".."#{JXMR_171027_21}".."#r"..ScriptGlobal_Format("#{JXMR_171027_05}", num)
		if num >= 10 then
			strComplete = "#W".."#{JXMR_171027_22}"
		end
		return strComplete	
	end

end
function MissionTrack_GetTrack_DHXYStage2_1(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_244}", 1)
		return strComplete	
	else
		local num = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if num == 0 then
			--阶段一进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_241}", 0)
			return strComplete
		elseif num == 1 then
			--阶段二进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_242}", 0)
			return strComplete
		elseif num == 2 then
			--阶段三进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_243}", 0)
			return strComplete
		end
	end
	return ""
end

function MissionTrack_GetTrack_DHXYStage2_2(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_248}", 1)
		return strComplete	
	else
		local stage1 = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if stage1 == 0 then
			--阶段一进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_245}", 0)
			return strComplete
		end
		local stage2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		if stage2 == 0 then
			--阶段一进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_246}", 0)
			return strComplete
		end
		local stage3 = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		--阶段三进行中
		local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_247}", stage3)
		return strComplete
	end
	return ""
end

function MissionTrack_GetTrack_DHXYStage2_3(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_254}", 1)
		return strComplete	
	else
		local param2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if param2 == 0 then
			--阶段一进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_249}", 0)
			return strComplete
		end
		local param3 = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		local param4 = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		if param3 < 1 or param4 < 1 then
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_250}", param3, param4)
			return strComplete
		end
		local param5 = DataPool:GetPlayerMission_Variable( nMissionIndex, 5 )
		if param5 < 1 then
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_252}", param5)
			return strComplete
		end
	end
	return ""
end

function MissionTrack_GetTrack_DHXYStage2_4(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_258}", 1)
		return strComplete	
	else
		local param2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if param2 == 0 then
			--阶段一进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_255}", param2)
			return strComplete
		end
		local param3 = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		if param3 == 0 then
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_256}", param3)
			return strComplete
		end
		local param4 = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		if param4 == 0 then
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_257}", param4)
			return strComplete
		end
	end
	return ""
end
function MissionTrack_GetTrack_DHXYStage2_5(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_269}", 1)
		return strComplete	
	else
		local stagecur = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if stagecur == 0 then
			--第一阶段
			local stage1 = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
			if stage1 == 0 then
				local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_259}", 0)
				return strComplete
			elseif stage1 == 1 then
				local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_260}", 0)
				return strComplete
			end
		elseif stagecur == 1 then
			--第二阶段
			local stage2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
			if stage2 == 0 then
				local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_261}", 0)
				return strComplete
			elseif stage2 == 1 then
				local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_262}", 0)
				return strComplete
			elseif stage2 == 2 then
				local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_263}", 0)
				return strComplete
			elseif stage2 == 3 then
				local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_264}", 0)
				return strComplete
			elseif stage2 == 4 then
				local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_265}", 0)
				return strComplete
			elseif stage2 == 5 then
				local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_266}", 0)
				return strComplete
			end
		elseif stagecur == 2 then
			--第三阶段
			local stage3a = DataPool:GetPlayerMission_Variable( nMissionIndex, 5 )
			local stage3b = DataPool:GetPlayerMission_Variable( nMissionIndex, 6 )
			if stage3a == 0 or stage3b == 0 then
				local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_267}", stage3a, stage3b)
				return strComplete
			end
		end
	end
	return ""
end
function MissionTrack_GetTrack_DHXYStage2_6(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_274}", 1)
		return strComplete	
	else
		local stage1a = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		local stage1b = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		if stage1a == 0 or stage1b == 0 then
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_270}", stage1a, stage1b)
			return strComplete
		end
		local stage2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		if stage2 == 0 then
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_272}", stage2)
			return strComplete
		end
		local stage3 = DataPool:GetPlayerMission_Variable( nMissionIndex, 5 )
		if stage3 == 0 then
			local strComplete = "#W"..ScriptGlobal_Format("#{DHEJ_240521_273}", stage3)
			return strComplete
		end
	end
end

--2024Q2大话西游第三阶段主线剧情
function MissionTrack_GetTrack_DHXYStage3_1(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W".."#{DSJD_240520_192}"
		return strComplete
	else
		local num = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		if num == 0 then
			--接任务
			local value1 = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
			local value2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_191}", value1, value2)
			return strComplete
		elseif num == 1 then
			--进副本
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_193}", 0)
			return strComplete
		elseif num == 2 then
			--寻路看剧情2
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_311}", 0)
			return strComplete
		elseif num == 3 then
			--寻路看剧情3
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_312}", 0)
			return strComplete
		elseif num == 4 then
			--寻路看剧情4
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_313}", 0)
			return strComplete
		elseif num == 5 then
			--开boss
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_184}", 0)
			return strComplete
		elseif num == 6 then
			--杀boss
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_193}", 1)
			return strComplete
		end
	end
	return ""
end
function MissionTrack_GetTrack_DHXYStage3_2(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W".."#{DSJD_240520_253}"
		return strComplete
	else
		local num = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if num == 0 then
			--接任务
			local value = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_252}", value)
			return strComplete
		elseif num == 1 then
			--进副本
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_208}", 0)
			return strComplete
		elseif num == 2 then
			--第一波
			local value = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_220}", value)
			return strComplete
		elseif num == 3 then
			--第二波
			local value = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_223}", value)
			return strComplete
		elseif num == 4 then
			--第三波
			local value = DataPool:GetPlayerMission_Variable( nMissionIndex, 5 )
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_224}", value)
			return strComplete
		elseif num == 5 then
			--开boss剧情
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_194}", 0)
			return strComplete
		elseif num == 6 then
			--第四波
			local value1 = DataPool:GetPlayerMission_Variable( nMissionIndex, 6 )
			local value2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 7 )
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_225}", value1, value2 )
			return strComplete
		elseif num == 7 then
			--开天劫剧情
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_234}", 0)
			return strComplete
		elseif num == 8 then
			--开天劫
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_240}", 0)
			return strComplete
		elseif num == 9 then
			--成功
			local strComplete = "#W"..ScriptGlobal_Format("#{DSJD_240520_208}", 1)
			return strComplete
		end
	end
	return ""
end

-- 2024Q3版本稳活活动
function MissionTrack_GetTrack_WenHuoMission1(nMissionIndex)
	local strComplete = ""
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local nChoose = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if nChoose == 1 then--帮助			
			strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_316}", 1)
		elseif nChoose == 2 then--教训			
			strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_314}", 1)
		end
	else
		local bFlag = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		if bFlag == 0 then--接任务
			strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_312}", 0)
		elseif bFlag == 1 then--开启选项
			local nChoose = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
			if nChoose == 0 then--未选择		
				strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_372}", 0)
			elseif nChoose == 1 then--帮助			
				strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_315}", 0)
			elseif nChoose == 2 then--教训			
				strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_313}", 0)
			end
		end
	end
	return strComplete
end
function MissionTrack_GetTrack_WenHuoMission2(nMissionIndex)
	local strComplete = ""
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local nChoose = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if nChoose == 1 then--帮助			
			strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_323}", 1)
		elseif nChoose == 2 then--教训			
			strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_321}", 1)
		end
	else
		local bFlag = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		if bFlag == 0 then--接任务
			strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_319}", 0)
		elseif bFlag == 1 then--开启选项
			local nChoose = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
			if nChoose == 0 then--未选择			
				strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_320}", 0)
			elseif nChoose == 1 then--帮助			
				strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_322}", 0)
			elseif nChoose == 2 then--教训			
				strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_321}", 0)
			end
		end
	end
	return strComplete
end
function MissionTrack_GetTrack_WenHuoMission5(nMissionIndex)
	local strComplete = ""
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local nChoose = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if nChoose == 1 then--帮助			
			strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_345}", 1)
		elseif nChoose == 2 then--教训			
			strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_343}", 1)
		end
	else
		local bFlag = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		if bFlag == 0 then--接任务
			strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_340}", 0)
		elseif bFlag == 1 then--开启选项
			local nChoose = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
			if nChoose == 0 then--未选择		
				strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_341}", 0)
			elseif nChoose == 1 then--帮助			
				strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_344}", 0)
			elseif nChoose == 2 then--教训			
				strComplete = "#W"..ScriptGlobal_Format("#{ERWH_240719_342}", 0)
			end
		end
	end
	return strComplete
end

function MissionTrack_GetTrack_FengYunDaKa(nMissionIndex)
    local strComplete = ""
    local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
    if finish == 1 then
        strComplete = "#W".."#{FYDK_260129_60}"
    else
        local nTodayNpc = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
        local str = {"#{FYDK_260129_57}","#{FYDK_260129_58}","#{FYDK_260129_59}",}
        if nTodayNpc == 1 or nTodayNpc == 2 or nTodayNpc == 3 then
            strComplete = "#W"..ScriptGlobal_Format("#{FYDK_260129_56}", str[nTodayNpc])
        end
    end
    return strComplete
end

function MissionTrack_GetTrack_QIXIYURE_1(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_173}", 1)
		return strComplete	
	else
		local num1 = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
		local num2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if num1 == 0 then
			--阶段一进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_40}", num1)
			return strComplete
		else
			--阶段二进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_41}", num2)
			return strComplete
		end
	end
	return ""
end

function MissionTrack_GetTrack_QIXIYURE_2(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_174}", 1)
		return strComplete	
	else
		local num1 = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
		local num2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if num1 == 0 then
			--阶段一进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_82}", num1)
			return strComplete
		else
			--阶段二进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_83}", num2)
			return strComplete
		end
	end
	return ""
end

function MissionTrack_GetTrack_QIXIYURE_3(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_174}", 1)
		return strComplete	
	else
		local num1 = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
		local num2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if num1 == 0 then
			--阶段一进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_106}", num1)
			return strComplete
		else
			--阶段二进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_107}", num2)
			return strComplete
		end
	end
	return ""
end

function MissionTrack_GetTrack_QIXIYURE_4(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_174}", 1)
		return strComplete	
	else
		local num1 = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
		local num2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		if num1 == 0 then
			--阶段一进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_127}", 0)
			return strComplete
		else
			--阶段二进行中
			local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_128}", num2)
			return strComplete
		end
	end
	return ""
end

function MissionTrack_GetTrack_QIXIYURE_5(nMissionIndex)
	local finish = DataPool:GetPlayerMission_Variable( nMissionIndex, 0 )
	if finish == 1 then
		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_174}", 1)
		return strComplete	
	else
		local num1 = DataPool:GetPlayerMission_Variable( nMissionIndex, 1 )
		local num2 = DataPool:GetPlayerMission_Variable( nMissionIndex, 2 )
		local num3 = DataPool:GetPlayerMission_Variable( nMissionIndex, 3 )
		local num4 = DataPool:GetPlayerMission_Variable( nMissionIndex, 4 )
		local num5 = DataPool:GetPlayerMission_Variable( nMissionIndex, 5 )
		
		--进行中
		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_160}", num1,num2,num3,num4,num5)
		return strComplete
	--	if num1 == 0 then
	--		--阶段一进行中
	--		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_127}", 0)
	--		return strComplete
	--	elseif num2 == 0 then
	--		--阶段二进行中
	--		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_128}", 0)
	--		return strComplete
	--	elseif num2 == 0 then
	--		--阶段二进行中
	--		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_128}", 0)
	--		return strComplete
	--	elseif num2 == 0 then
	--		--阶段二进行中
	--		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_128}", 0)
	--		return strComplete
	--	elseif num2 == 0 then
	--		--阶段二进行中
	--		local strComplete = "#W"..ScriptGlobal_Format("#{QXYR_260601_128}", 0)
	--		return strComplete
	--	end
	end
	return ""
end

function MissionTrack_GetTrack_2026QiXiJuQing3(missionId)
	local ret = ""
	local step = DataPool:GetPlayerMission_Variable(missionId, 1)
	local done = DataPool:GetPlayerMission_Variable(missionId, 2)
	ret = "#{XYYJ_260529_243}"
	return ret
end