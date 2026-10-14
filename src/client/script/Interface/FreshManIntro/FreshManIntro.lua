local NEWBIEHELP_MY_LEVEL = 1
local g_FreshManIntro_Frame_UnifiedPosition;

local NEWBIEHELP_EVENT_TABLE_SERVER_COMMAND =
{
--{ command=888888, arg=1, set=1 },
{ command=888888, arg=3, set=5 }
}

local NEWBIEHELP_EVENT_TABLE_TRANSCENE_WITH_MISSION =
{
{ scene="wuliangscene", mission="Mission:1403", set=4 },
{ scene="newbie_2", mission="Mission:1415", set=8 }
}

local NEWBIEHELP_EVENT_TABLE_FINISH_MISSION =
{
--{ mission="1401", set=3 },
{ mission="1415", set=9 },
--{ mission="1406", set=6 },
}

local NEWBIEHELP_EVENT_TABLE_LEARN_SKILL =
{
{ skill=241, set=5 }
}

local NEWBIEHELP_EVENT_TABLE_ACCEPT_MISSION =
{
--{ mission="Mission:1401", set=2 },  --第一把武器
--{ mission="Mission:1414", set=7 }   --第一只珍兽
}

local g_FreshGuideProcess = 0
local g_PopAlready = 0

local g_CurFlashAct = -1;

local NEWBIEHELP_TUTORIAL =
{
{set=1,num=4,image={{"set:NewFreshManIntro01_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro01_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro01_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro01_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro01_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro01_01_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro01_02_1 image:IntroImage1_1",
                     "set:NewFreshManIntro01_02_2 image:IntroImage1_2",
                     "set:NewFreshManIntro01_02_3 image:IntroImage1_3",
                     "set:NewFreshManIntro01_02_3 image:IntroImage1_4",
                     "set:NewFreshManIntro01_02_4 image:IntroImage1_5",
                     "set:NewFreshManIntro01_02_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro01_03_1 image:IntroImage1_1",
                     "set:NewFreshManIntro01_03_2 image:IntroImage1_2",
                     "set:NewFreshManIntro01_03_3 image:IntroImage1_3",
                     "set:NewFreshManIntro01_03_3 image:IntroImage1_4",
                     "set:NewFreshManIntro01_03_4 image:IntroImage1_5",
                     "set:NewFreshManIntro01_03_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro01_04_1 image:IntroImage1_1",
                     "set:NewFreshManIntro01_04_2 image:IntroImage1_2",
                     "set:NewFreshManIntro01_04_3 image:IntroImage1_3",
                     "set:NewFreshManIntro01_04_3 image:IntroImage1_4",
                     "set:NewFreshManIntro01_04_4 image:IntroImage1_5",
                     "set:NewFreshManIntro01_04_4 image:IntroImage1_6"}}},

{set=2,num=2,image={{"set:NewFreshManIntro02_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro02_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro02_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro02_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro02_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro02_01_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro02_02_1 image:IntroImage1_1",
                     "set:NewFreshManIntro02_02_2 image:IntroImage1_2",
                     "set:NewFreshManIntro02_02_3 image:IntroImage1_3",
                     "set:NewFreshManIntro02_02_3 image:IntroImage1_4",
                     "set:NewFreshManIntro02_02_4 image:IntroImage1_5",
                     "set:NewFreshManIntro02_02_4 image:IntroImage1_6"}}},

{set=3,num=5,image={{"set:NewFreshManIntro03_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro03_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro03_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro03_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro03_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro03_01_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro03_02_1 image:IntroImage1_1",
                     "set:NewFreshManIntro03_02_2 image:IntroImage1_2",
                     "set:NewFreshManIntro03_02_3 image:IntroImage1_3",
                     "set:NewFreshManIntro03_02_3 image:IntroImage1_4",
                     "set:NewFreshManIntro03_02_4 image:IntroImage1_5",
                     "set:NewFreshManIntro03_02_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro03_03_1 image:IntroImage1_1",
                     "set:NewFreshManIntro03_03_2 image:IntroImage1_2",
                     "set:NewFreshManIntro03_03_3 image:IntroImage1_3",
                     "set:NewFreshManIntro03_03_3 image:IntroImage1_4",
                     "set:NewFreshManIntro03_03_4 image:IntroImage1_5",
                     "set:NewFreshManIntro03_03_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro03_04_1 image:IntroImage1_1",
                     "set:NewFreshManIntro03_04_2 image:IntroImage1_2",
                     "set:NewFreshManIntro03_04_3 image:IntroImage1_3",
                     "set:NewFreshManIntro03_04_3 image:IntroImage1_4",
                     "set:NewFreshManIntro03_04_4 image:IntroImage1_5",
                     "set:NewFreshManIntro03_04_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro03_05_1 image:IntroImage1_1",
                     "set:NewFreshManIntro03_05_2 image:IntroImage1_2",
                     "set:NewFreshManIntro03_05_3 image:IntroImage1_3",
                     "set:NewFreshManIntro03_05_3 image:IntroImage1_4",
                     "set:NewFreshManIntro03_05_4 image:IntroImage1_5",
                     "set:NewFreshManIntro03_05_4 image:IntroImage1_6"}}},

{set=4,num=3,image={{"set:NewFreshManIntro04_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro04_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro04_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro04_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro04_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro04_01_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro04_02_1 image:IntroImage1_1",
                     "set:NewFreshManIntro04_02_2 image:IntroImage1_2",
                     "set:NewFreshManIntro04_02_3 image:IntroImage1_3",
                     "set:NewFreshManIntro04_02_3 image:IntroImage1_4",
                     "set:NewFreshManIntro04_02_4 image:IntroImage1_5",
                     "set:NewFreshManIntro04_02_4 image:IntroImage1_6"},
	     	     {"set:NewFreshManIntro04_03_1 image:IntroImage1_1",
	     	     "set:NewFreshManIntro04_03_2 image:IntroImage1_2",
	     	     "set:NewFreshManIntro04_03_3 image:IntroImage1_3",
	     	     "set:NewFreshManIntro04_03_3 image:IntroImage1_4",
	     	     "set:NewFreshManIntro04_03_4 image:IntroImage1_5",
	     	     "set:NewFreshManIntro04_03_4 image:IntroImage1_6",}}},

{set=5,num=3,image={{"set:NewFreshManIntro05_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro05_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro05_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro05_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro05_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro05_01_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro05_02_1 image:IntroImage1_1",
                     "set:NewFreshManIntro05_02_2 image:IntroImage1_2",
                     "set:NewFreshManIntro05_02_3 image:IntroImage1_3",
                     "set:NewFreshManIntro05_02_3 image:IntroImage1_4",
                     "set:NewFreshManIntro05_02_4 image:IntroImage1_5",
                     "set:NewFreshManIntro05_02_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro05_03_1 image:IntroImage1_1",
                     "set:NewFreshManIntro05_03_2 image:IntroImage1_2",
                     "set:NewFreshManIntro05_03_3 image:IntroImage1_3",
                     "set:NewFreshManIntro05_03_3 image:IntroImage1_4",
                     "set:NewFreshManIntro05_03_4 image:IntroImage1_5",
                     "set:NewFreshManIntro05_03_4 image:IntroImage1_6"}}},

{set=6,num=1,image={{"set:NewFreshManIntro06_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro06_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro06_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro06_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro06_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro06_01_4 image:IntroImage1_6"}}},

{set=7,num=3,image={{"set:NewFreshManIntro07_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro07_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro07_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro07_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro07_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro07_01_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro07_02_1 image:IntroImage1_1",
                     "set:NewFreshManIntro07_02_2 image:IntroImage1_2",
                     "set:NewFreshManIntro07_02_3 image:IntroImage1_3",
                     "set:NewFreshManIntro07_02_3 image:IntroImage1_4",
                     "set:NewFreshManIntro07_02_4 image:IntroImage1_5",
                     "set:NewFreshManIntro07_02_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro07_03_1 image:IntroImage1_1",
                     "set:NewFreshManIntro07_03_2 image:IntroImage1_2",
                     "set:NewFreshManIntro07_03_3 image:IntroImage1_3",
                     "set:NewFreshManIntro07_03_3 image:IntroImage1_4",
                     "set:NewFreshManIntro07_03_4 image:IntroImage1_5",
                     "set:NewFreshManIntro07_03_4 image:IntroImage1_6"}}},

{set=8,num=2,image={{"set:NewFreshManIntro08_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro08_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro08_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro08_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro08_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro08_01_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro08_02_1 image:IntroImage1_1",
                     "set:NewFreshManIntro08_02_2 image:IntroImage1_2",
                     "set:NewFreshManIntro08_02_3 image:IntroImage1_3",
                     "set:NewFreshManIntro08_02_3 image:IntroImage1_4",
                     "set:NewFreshManIntro08_02_4 image:IntroImage1_5",
                     "set:NewFreshManIntro08_02_4 image:IntroImage1_6"}}},

{set=9,num=1,image={{"set:NewFreshManIntro09_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro09_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro09_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro09_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro09_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro09_01_4 image:IntroImage1_6"}}},

{set=10,num=2,image={{"set:NewFreshManIntro10_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro10_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro10_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro10_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro10_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro10_01_4 image:IntroImage1_6"},
                     {"set:NewFreshManIntro10_03_1 image:IntroImage1_1",
                     "set:NewFreshManIntro10_03_2 image:IntroImage1_2",
                     "set:NewFreshManIntro10_03_3 image:IntroImage1_3",
                     "set:NewFreshManIntro10_03_3 image:IntroImage1_4",
                     "set:NewFreshManIntro10_03_4 image:IntroImage1_5",
                     "set:NewFreshManIntro10_03_4 image:IntroImage1_6"}}},
--变身系统引导
{set=11,num=1,image={{"set:FreshManIntro11_01_1 image:IntroImage1_1",
                     "set:FreshManIntro11_01_2 image:IntroImage1_2",
                     "set:FreshManIntro11_01_3 image:IntroImage1_3",
                     "set:FreshManIntro11_01_3 image:IntroImage1_4",
                     "set:FreshManIntro11_01_4 image:IntroImage1_5",
                     "set:FreshManIntro11_01_4 image:IntroImage1_6"}}},
--KVK城市产出副本引导
{set=12,num=2,image={{"set:FreshManIntro12_01_1 image:IntroImage1_1",
                     "set:FreshManIntro12_01_2 image:IntroImage1_2",
                     "set:FreshManIntro12_01_3 image:IntroImage1_3",
                     "set:FreshManIntro12_01_3 image:IntroImage1_4",
                     "set:FreshManIntro12_01_4 image:IntroImage1_5",
                     "set:FreshManIntro12_01_4 image:IntroImage1_6"},
					 {"set:FreshManIntro12_02_1 image:IntroImage1_1",
                     "set:FreshManIntro12_02_2 image:IntroImage1_2",
                     "set:FreshManIntro12_02_3 image:IntroImage1_3",
                     "set:FreshManIntro12_02_3 image:IntroImage1_4",
                     "set:FreshManIntro12_02_4 image:IntroImage1_5",
                     "set:FreshManIntro12_02_4 image:IntroImage1_6"}}},

--领取帮派珍兽引导
{set=13,num=1,image={{"set:NewFreshManIntro11_01_1 image:IntroImage1_1",
                     "set:NewFreshManIntro11_01_2 image:IntroImage1_2",
                     "set:NewFreshManIntro11_01_3 image:IntroImage1_3",
                     "set:NewFreshManIntro11_01_3 image:IntroImage1_4",
                     "set:NewFreshManIntro11_01_4 image:IntroImage1_5",
                     "set:NewFreshManIntro11_01_4 image:IntroImage1_6"}}},

}

local now_tutorial_set = 0
local now_tutorial_page = 0

local g_Need_PopUITip = 0
--===============================================
-- OnLoad()
--===============================================
function FreshManIntro_PreLoad()
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("FINISH_MISSION");
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("NEW_MISSION");
	this:RegisterEvent("OPEN_FRESHMAN_INTRO");
	this:RegisterEvent("UPDATE_MISSION_TRACK");
	this:RegisterEvent("UPDATE_ACHIEVEMENT_GET");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UNIT_LEVEL")
end

function FreshManIntro_OnLoad()
	g_FreshManIntro_Frame_UnifiedPosition=FreshManIntro_Frame:GetProperty("UnifiedPosition");
end

function FreshManIntro_OnHiden()
    if 1 == g_Need_PopUITip and IsWindowShow("MissionTrack") then
	    g_Need_PopUITip = 0
        --NotifyPopUITip("MissionTrack", 1, 1)  --通知任务追踪界面：弹出ui引导
    elseif 2 == g_Need_PopUITip and not IsWindowShow("Packet") then
        FlashPacketButton()
        NotifyPopUITip("MainMenuBar", 5, 1)  --通知主动作条：弹出ui引导--打开包裹
    elseif 3 == g_Need_PopUITip and not IsWindowShow("Pet") then
	    g_Need_PopUITip = 0
        --NotifyPopUITip("MainMenuBar", 11, 4)  --通知主动作条：弹出ui引导--打开珍兽
    elseif 4 == g_Need_PopUITip and not IsWindowShow("QuestLog") then
        NotifyPopUITip("MainMenuBar", 21, 5)  --通知主动作条：弹出ui引导--打开任务日志
    elseif 5 == g_Need_PopUITip then
	--NotifyPopUITip("MissionTrack", 1, 5)  --通知任务追踪界面：弹出ui引导
	NotifyPopUITip("MainMenuBar", 1, 6)
    elseif 6 == g_Need_PopUITip and not IsWindowShow("Packet") then
	local nExp = Player:GetData("EXP");
	if nExp ~= nil and Player:CompareHumanExp(1) < 0 then
		DataPool:SetCurrentFreshManGuideItemValue(1)
		NotifyPopUITip("MainMenuBar", 21, 7)
	end
    end
    g_Need_PopUITip = 0
end

--===============================================
-- OnEvent()
--===============================================
function FreshManIntro_OnEvent(event)

	--PushDebugMessage("FreshManIntro_OnEvent " .. event.. " " .. arg0 .. " " .. arg1 .. " " .. arg2);

	if (event == "ADJEST_UI_POS" ) then
		FreshManIntro_Frame_On_ResetPos()
		-- 游戏分辨率发生了变化
		return

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FreshManIntro_Frame_On_ResetPos()
		return

	end

	if (event == "UNIT_LEVEL" ) then
		NEWBIEHELP_MY_LEVEL = Player:GetData("LEVEL")
		return
	end

	--变身系统引导，不受level影响，特写
	if ( event == "UI_COMMAND" and tonumber(arg0) == 40206501 ) then
		FreshManIntro_ReSetImage( 11 )
		return
	end

	--KVK城市产出副本引导
	if (event == "UI_COMMAND" and tonumber(arg0) == 88940802) then
		FreshManIntro_ReSetImage(12)
		return
	end

	--领取帮派珍兽引导	--2013q3新的指引干掉这个选项
	-- if (event == "UI_COMMAND" and tonumber(arg0) == 20120112) then
		-- FreshManIntro_ReSetImage(13)
		-- return
	-- end

	local nLevel = Player:GetData("LEVEL")
	if nLevel == nil then
		--PushDebugMessage("FreshManIntro_OnEvent nil level" );
		return
	end

	--PushDebugMessage("FreshManIntro_OnEvent level " .. nLevel );
	--因为切场景的时候获得的Player:GetData("LEVEL")是0，不愿意动底层所以如此
	if nLevel == 0 then
		nLevel = NEWBIEHELP_MY_LEVEL
	end

	if nLevel > 20 then
		return
	end

	local showed = 0;
	if ( event == "SCENE_TRANSED" ) then
		for i, transtab in NEWBIEHELP_EVENT_TABLE_TRANSCENE_WITH_MISSION do
			if( transtab.scene == arg0 ) then
				for j = 1, 20 do
					if (DataPool:GetPlayerMission_InUse(j-1) == 1) then
						local missname = DataPool:GetPlayerMission_Name(j-1)
						--PushDebugMessage("FreshManIntro_Mission " .. missname );
						if ( missname == transtab.mission ) then
							--PushDebugMessage( transtab.mission .." == " .. missname );
							showed = FreshManIntro_ReSetImage( transtab.set )
							break;
						--else
							--PushDebugMessage( transtab.mission .." != " .. missname );
						end
					end
				end
			end
			if(showed ==1) then
				break;
			end
		end
	elseif ( event == "UI_COMMAND" ) then
		for i, commandtab in NEWBIEHELP_EVENT_TABLE_SERVER_COMMAND do
			if( commandtab.command == tonumber( arg0 ) and commandtab.arg == Get_XParam_INT(0)) then
				if SystemSetup:IsClassic() == 0 and commandtab.arg == 1 and commandtab.set == 1 then
					return
				end
				showed = FreshManIntro_ReSetImage( commandtab.set )
				if commandtab.arg == 1 then
--				    g_Need_PopUITip = 4 --玩家第一次登陆游戏时,弹移动引导图片,关闭后弹任务日志按钮引导
				    g_Need_PopUITip = 6
				end
			end
			if(showed ==1) then
				break;
			end
		end
	elseif ( event == "NEW_MISSION" ) then
		for i, newmissiontab in NEWBIEHELP_EVENT_TABLE_ACCEPT_MISSION do
			local missname = DataPool:GetPlayerMission_Name(tonumber( arg0 ))
			--PushDebugMessage( newmissiontab.mission.." :: " .. missname );
			if( newmissiontab.mission == missname ) then
				showed = FreshManIntro_ReSetImage( newmissiontab.set )

				if "Mission:1401" == missname then --"第一把武器"
			        g_Need_PopUITip = 5 --此任务要求在关闭引导图片后,给任务追踪加提示
			    elseif "Mission:1414" == missname then --"第一只珍兽"
			        g_Need_PopUITip = 3
			        NotifyPopUITip("Pet", 12, 1)  --通知珍兽界面,tip”出战“
			    end
			end

			if missname ==  "Mission:1414" then
				NotifyPopUITip("Pet", 12, 1)
			end
			if(showed ==1) then
				break
			end
		end
	elseif ( event == "FINISH_MISSION" ) then
		for i, finishmissiontab in NEWBIEHELP_EVENT_TABLE_FINISH_MISSION do
			--local missname = DataPool:GetPlayerMission_Name(tonumber( arg0 ))
			--PushDebugMessage( finishmissiontab.mission.." :: " .. arg0 );
			if( finishmissiontab.mission == arg0 ) then
				showed = FreshManIntro_ReSetImage( finishmissiontab.set )
				if "1401" == arg0 then --第一把武器
			        g_Need_PopUITip = 2
			    end
			end
			if(showed ==1) then
				break;
			end
		end
	elseif ( event == "OPEN_FRESHMAN_INTRO" ) then
		local introSet = tonumber(arg0)
		FreshManIntro_ReSetImage( introSet )
	elseif ( event == "UPDATE_MISSION_TRACK") then		--	初级技能完成状态显示这个玩意。。。。
		for i = 1, 20 do	--	玩家当前任务上限为20
			if "Mission:1405" == DataPool:GetPlayerMission_Name(i-1) then		--	初级技能
				local value = DataPool:GetPlayerMission_Variable(i-1, 0)	
				if 1 == value and g_PopAlready == 0 then		--	是否为完成状态	
					g_PopAlready = 1 
					FreshManIntro_ReSetImage( 5 )
				end
			end
		end
	elseif ( event == "UPDATE_ACHIEVEMENT_GET" ) then  --不再显示这个了
		--if 73 == tonumber(arg0) then		--	成功召唤坐骑后再显示这个玩意。。。。。
		--	FreshManIntro_ReSetImage( 10 )
		--end
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FreshManIntro_Frame_On_ResetPos()
	FreshManIntro_Frame:SetProperty("UnifiedPosition", g_FreshManIntro_Frame_UnifiedPosition);
end

function FreshManIntro_ReSetImage( transtabset )
	now_tutorial_set = transtabset
	now_tutorial_page = 1
	return FreshManIntro_SetImage( );
end

function FreshManIntro_SetImage( )
	--PushDebugMessage( "FreshManIntro_SetImage ".. now_tutorial_set .." ".. now_tutorial_page );
	if now_tutorial_set == 0 then
		return 0
	end
	local tutorialtab = NEWBIEHELP_TUTORIAL[now_tutorial_set]
	if(now_tutorial_page >= tutorialtab.num) then
		FreshManIntro_DownPage:Disable();
	end
	if(now_tutorial_page <= 1) then
		FreshManIntro_UpPage:Disable();
	end

	if( tutorialtab.num > 1 )then
		if(now_tutorial_page > 1)then
			FreshManIntro_UpPage:Enable();
		end
		if(now_tutorial_page < tutorialtab.num)then
			FreshManIntro_DownPage:Enable();
		end
	end

	if(tutorialtab~=nil) then
		if ( now_tutorial_page > tutorialtab.num or now_tutorial_page < 1 ) then
			return 0
		end

		--PushDebugMessage(tutorialtab.image[now_tutorial_page][1])
		--PushDebugMessage(tutorialtab.image[now_tutorial_page][2])
		--PushDebugMessage(tutorialtab.image[now_tutorial_page][3])
		--PushDebugMessage(tutorialtab.image[now_tutorial_page][4])
		--PushDebugMessage(tutorialtab.image[now_tutorial_page][5])
		--PushDebugMessage(tutorialtab.image[now_tutorial_page][6])

		FreshManIntro_Image1:SetProperty("Image", tutorialtab.image[now_tutorial_page][1])
		FreshManIntro_Image2:SetProperty("Image", tutorialtab.image[now_tutorial_page][2])
		FreshManIntro_Image3:SetProperty("Image", tutorialtab.image[now_tutorial_page][3])
		FreshManIntro_Image4:SetProperty("Image", tutorialtab.image[now_tutorial_page][4])
		FreshManIntro_Image5:SetProperty("Image", tutorialtab.image[now_tutorial_page][5])
		FreshManIntro_Image6:SetProperty("Image", tutorialtab.image[now_tutorial_page][6])
		this:Show();

		--	先把计时器加进来。。。。要不没戏了。。。
		if now_tutorial_set == 1 and now_tutorial_page == 1 then
			SetTimer("FreshManIntro", "FreshManIntro_ShowFreshManGuide()", 10000)
			g_FreshGuideProcess = 1
		end

		return 1
	else
		return 0
	end
end

function FreshManIntro_ShowFreshManGuide()
	KillTimer("FreshManIntro_ShowFreshManGuide()")
	if not this:IsVisible() then
		return
	end

	
	if g_FreshGuideProcess == 1 then
		FreshManIntro_ShowGuide(1)
		g_FreshGuideProcess = 2
		g_CurFlashAct = 1
	end
end

function FreshManIntro_ShowGuide(nType)
	local nPosX = tonumber(FreshManIntro_Frame:GetProperty("AbsoluteXPosition"))
	local nPosY = tonumber(FreshManIntro_Frame:GetProperty("AbsoluteYPosition"))
	local fX = 0
	local fY = 0
	fX, fY = this:GetChildOffset("FreshManIntro_Close")
	local fH = tonumber(FreshManIntro_Close:GetProperty("AbsoluteHeight"))
	local fW = tonumber(FreshManIntro_Close:GetProperty("AbsoluteWidth"))
	fX = tonumber(fX + nPosX)
	fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 11, 2, "FreshManIntro")
end

function FreshManIntro_CloseFunction()
	KillTimer("FreshManIntro_ShowFreshManGuide()")
	if "FreshManIntro" == GetFreshManGuideOwner() then
		g_CurFlashAct = -1
		CloseFreshManGuide()
	end

	if g_FreshGuideProcess > 0 then
		DataPool:SetCurrentFreshManGuideItemValue(1)	--	设置当前武器
		g_CurFlashAct = -1
		NotifyPopUITip("MainMenuBar", 12, 7)
		g_FreshGuideProcess = 0
		g_Need_PopUITip = 0
	end
	this:Hide();
end

function FreshManIntro_OnMove()
	if g_CurFlashAct > 0 then
		FreshManIntro_ShowGuide(2)
	end
end


function FreshManIntro_PageUp()
	--PushDebugMessage("FreshManIntro_FunctionPrev " .. now_tutorial_set.." "..now_tutorial_page );
	if(now_tutorial_page<=1) then
		return;
	end

	now_tutorial_page = now_tutorial_page - 1
	FreshManIntro_SetImage( )
end

function FreshManIntro_PageDown()
	--PushDebugMessage("FreshManIntro_FunctionNext " .. now_tutorial_set.." "..now_tutorial_page );
	local tutorialtab = NEWBIEHELP_TUTORIAL[now_tutorial_set]
	if(tutorialtab~=nil) then
		if(now_tutorial_page >= tutorialtab.num) then
			return;
		end
	end

	now_tutorial_page = now_tutorial_page + 1
	FreshManIntro_SetImage( )
end

function FreshManIntro_Quit_Clicked()
	KillTimer("FreshManIntro_ShowFreshManGuide()")
	if "FreshManIntro" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	if g_FreshGuideProcess > 0 then
		DataPool:SetCurrentFreshManGuideItemValue(1)	--	设置当前武器
		NotifyPopUITip("MainMenuBar", 12, 7)
		g_FreshGuideProcess = 0
		g_Need_PopUITip = 0
	end
	this:Hide();
end
