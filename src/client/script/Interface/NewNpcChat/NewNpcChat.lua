local NEWNPCCHAT_EVENT_TABLE_SERVER_COMMAND =
{
{ command=888888, arg=1, set=1 },
{ command=888888, arg=3, set=5 }
}

local g_MoveTimer = 1000;
local g_closeWindowTime = 20000;

local g_ShowRide = 0;

local g_posx = 187;
local g_posy = 225;
local g_movetick = 0;
local g_havepettick = 0;

local g_Step = -2;

local g_PlayerLevel = 0;

function NewNpcChat_PreLoad()
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_FRESHMAN_NEWNPCCHAT")
	this:RegisterEvent("CLOSE_FRESHMAN_GUIDE")
	this:RegisterEvent("NOTIFY_NEW_SKILLS")
	this:RegisterEvent("GAMELOGIN_SELECTCHARACTER")
	this:RegisterEvent("UNIT_LEVEL")
	this:RegisterEvent("GAMELOGIN_SHOW_SYSTEM_INFO")
	--this:RegisterEvent("PACKAGE_AWARDITEM")  --骑乘指引相关
	this:RegisterEvent("UPDATE_ACHIEVEMENT")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("CLOSE_NEWNPCCHAT")
	this:RegisterEvent("SCENE_DATA_READY")
end


function NewNpcChat_OnLoad()
end

function NewNpcChat_OnEvent(event)

 	--将泡泡固定到人物右上侧
 	--获得Client分辨率
	local nWidth ,nHeight = GetCurClientSize()
	local TempX = math.floor(tonumber(nWidth/24))
	local TempY = (-math.floor(tonumber(nHeight/2.8)))

	--取合适坐标
	local ScreenXPoint = "{0.5,"..TempX.."}"
	local ScreenYPoint = "{0.5,"..TempY.."}"

	--设置
	NewNpcChat : SetProperty("UnifiedXPosition", ScreenXPoint);
	NewNpcChat : SetProperty("UnifiedYPosition", ScreenYPoint);

	if(event == "SCENE_TRANSED") then
		--this:Show()
		local temp =1+1
	elseif (event == "UI_COMMAND") then
		local nLevel = Player:GetData("LEVEL")
		if nLevel == nil or nLevel > 15 then
			return
		end
		for i, commandtab in NEWNPCCHAT_EVENT_TABLE_SERVER_COMMAND do
			if( commandtab.command == tonumber(arg0) and commandtab.arg == Get_XParam_INT(0)) then
				if commandtab.arg == 1 and commandtab.set == 1 and SystemSetup:IsClassic() == 1 then

					NewNpcChat_Chat_Text:SetText("#{XSZY_130909_01}")
					SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
					SetTimer("NewNpcChat" , "NewNpcChat_MoveTran()",1000);		--开定时器
					NewNpcChat_openNewFreshman(1)
					NewNpcChat_UpDataFream(0)
					this:Show()
				end
			end
		end

		if (tonumber(arg0) == 20130910 and Get_XParam_INT(0) == 890252) then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_07}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			NewNpcChat_openNewFreshman(1)
			this:Show()
		end


		if(tonumber(arg0) == 20130910 and Get_XParam_INT(0) == 890264) then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_10}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			this:Show()
			NotifyPopUITip("Quest", -1, 6)
		end

		if tonumber(arg0) == 20130918 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_16}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			SetTimer("NewNpcChat" , "NewNpcChat_Skillguild()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			this:Show()
			PushEvent("NOTIFY_NEW_SKILLS") --去闪耀技能按钮
			DataPool:SetCurrentFreshManGuideItemValue(22);
		end

		-- if tonumber(arg0) == 20120112 then
			-- NewNpcChat_Chat_Text:SetText("#{XSZY_130909_12}")
			-- SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			-- NewNpcChat_UpDataFream(0)
			-- this:Show()
			-- NotifyPopUITip("MainMenuBar", 21, 4)
		-- end

	elseif(event == "OPEN_FRESHMAN_NEWNPCCHAT") then

		local nLevel = Player:GetData("LEVEL")
		if nLevel == nil or nLevel > 15 then
			return
		end
		if tonumber(arg0) == 0 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_04}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			NewNpcChat_openNewFreshman(1)
			this:Show()
		elseif tonumber(arg0) == 1 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_05}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			this:Show()
		elseif tonumber(arg0) == 2 then		--技能指引
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_08}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			g_Step = 2;
			NewNpcChat_UpDataFream(1)
			this:Show()
		elseif tonumber(arg0) == 3 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_23}")
			SetTimer("NewNpcChat" , "NewNpcChat_HavePet()",1000);
			NewNpcChat_UpDataFream(0)
			this:Show()
		elseif tonumber(arg0) == 4 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_30}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			g_Step = 4;
			NewNpcChat_UpDataFream(1)
			this:Show()
			PushEvent("NOTIFY_POP_UITIP","MissionTrack",-1,43) --在【无量玉璧】任务接取成功，完成坐骑指引之后，在右侧任务追踪出显示tips指引
		elseif tonumber(arg0) == 5 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_27}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			this:Show()

		elseif tonumber(arg0) == 6 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_11}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_openNewFreshman(2)
			NewNpcChat_UpDataFream(0)
			DataPool:SetCurrentFreshManGuideItemValue(38000770)
			this:Show()
		elseif tonumber(arg0) == 7 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_13}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			g_Step = 7;
			NewNpcChat_UpDataFream(1)
			this:Show()
		elseif tonumber(arg0) == 8 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_17}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NotifyPopUITip("ActionSkill", 1, 1)
			g_Step = 9;
			NewNpcChat_UpDataFream(1)
			this:Show()
		elseif tonumber(arg0) == 9 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_01}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			SetTimer("NewNpcChat" , "NewNpcChat_MoveTran()",1000);		--开定时器
			NewNpcChat_openNewFreshman(1)
			NewNpcChat_UpDataFream(0)
			this:Show()
		elseif tonumber(arg0) == 10 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_02}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			SetTimer("NewNpcChat" , "NewNpcChat_MoveTran()",1000);		--开定时器
			NewNpcChat_openNewFreshman(3)
			NewNpcChat_UpDataFream(0)
			this:Show()
		elseif tonumber(arg0) == 11 then
			local strToShow = ScriptGlobal_Format("#{XSZY_130909_26}", PlayerPackage:GetEquipItemName(10141517))
			NewNpcChat_Chat_Text:SetText(strToShow)
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			g_ShowRide = 1; --要求可以显示骑上坐骑的提示
			this:Show()
		elseif tonumber(arg0) == 12 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_20}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			this:Show()
		elseif tonumber(arg0) == 13 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_21}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			this:Show()
		elseif tonumber(arg0) == 14 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_22}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(1)
			this:Show()
		elseif tonumber(arg0) == 15 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130912_04}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			this:Show()
		end

	elseif(event == "CLOSE_FRESHMAN_GUIDE") then
		if g_Step ~= -2 and g_Step ~= 4 and g_Step ~= 7 and g_Step ~= 8 then
			NewNpcChat_TimerCloseWindow()
		end
	elseif event == "GAMELOGIN_SELECTCHARACTER" then
		g_Step = -2
	elseif event == "UNIT_LEVEL" then
		local level = Player:GetData("LEVEL")
		local menpai = Player : GetData("MEMPAI");
		if level == 10 and  menpai == 9 and g_PlayerLevel == 0 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_31}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(0)
			this:Show()
			g_PlayerLevel = 10;
		end

		if level >= 10 then
			NewNpcChat_MultiLine()
		end

	elseif event == "GAMELOGIN_SHOW_SYSTEM_INFO" then
		NewNpcChat_TimerCloseWindow()
	--elseif event == "PACKAGE_AWARDITEM" then
		--local nLevel = Player:GetData("LEVEL")
		--if nLevel == nil or nLevel > 15 then
			--return
		--end
		--local itemindex = DataPool:GetCurrentFreshManGuideItemValue()
		--if itemindex == 10141451 or itemindex == 10141517 then
			--local strToShow = ScriptGlobal_Format("#{XSZY_130909_26}", PlayerPackage:GetEquipItemName(itemindex))
			--NewNpcChat_Chat_Text:SetText(strToShow)
			--SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			--NewNpcChat_UpDataFream(0)
			--this:Show()
		--end
	elseif event == "UPDATE_ACHIEVEMENT" then
		local nLevel = Player:GetData("LEVEL")
		if nLevel == nil or nLevel > 15 then
			return
		end
		if 75 == tonumber(arg0) and g_ShowRide == 1 then		--	成功召唤坐骑后再显示这个玩意。。。。。
			-- NewNpcChat_Chat_Text:SetText("#{XSZY_130909_28}") --xjc
			-- SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			-- NewNpcChat_UpDataFream(0)
			-- this:Show()
			-- NotifyPopUITip("MainMenuBar", -1, 10)
			-- g_ShowRide = 0
		end
	--elseif event == "ADJEST_UI_POS"	or event == "VIEW_RESOLUTION_CHANGED"  then
		--g_Step = -3;	--第一次进游戏肯定会发这个消息，初次进入屏蔽一下
		--PushDebugMessage("cacacacscscscscs")
		--NewNpcChat_TimerCloseWindow()
	elseif event == "CLOSE_NEWNPCCHAT" then
		g_Step = -1;
		NewNpcChat_TimerCloseWindow()
	elseif(event == "SCENE_DATA_READY") then
		NewNpcChat_MultiLine()
	end
end
function NewNpcChat_TimerCloseWindow()
	KillTimer("NewNpcChat_TimerCloseWindow()")

		-- if g_Step == -3 then
			-- g_Step = -1;
			-- return
		-- end
		if g_Step == 2 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_09}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(1)
			-- this:Show()
			-- g_Step = -1;
		elseif g_Step == 7 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_14}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(1)
			g_Step =8
			return
		elseif g_Step == 8 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_15}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(1)
		elseif g_Step == 9 then
			NewNpcChat_Chat_Text:SetText("#{XSZY_130909_18}")
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			NewNpcChat_UpDataFream(1)
			NotifyPopUITip("ActionSkill", 1, 2)
			this:Show()
			g_Step =10
			return
		elseif g_Step == 10 then
			PushEvent("NOTIFY_POP_UITIP","MissionTrack",-1,44) --弹出指引 4.在【浩劫前夕】任务接取成功，完成门派技能指引之后，在右侧任务追踪出显示tips指引
		else
			if this:IsVisible() then
				this:Hide()
			end
		end

		g_Step = -1;

end

function NewNpcChat_HavePet()
	if Player:IsHaveCurrentPet() then
		KillTimer("NewNpcChat_HavePet()")
		PushEvent("NOTIFY_POP_UITIP","MissionTrack",-1,43) --2.在【并肩作战】任务接取成功，完成珍兽指引之后，在右侧任务追踪出显示tips指引
		NewNpcChat_OnPetReady()
	end
end

function NewNpcChat_OnPetReady()
			local nEra, strTypeName = Pet:GetPetTypeName(0);
			local strToShow = ScriptGlobal_Format("#{XSZY_130909_25}", strTypeName)
			NewNpcChat_Chat_Text:SetText(strToShow)
			SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
			this:Show()
end

function NewNpcChat_ButtonClicked()
	NewNpcChat_TimerCloseWindow()
end
function NewNpcChat_MoveTran()

	local posx, posy = Target:GetMyPos()

	if posx == 0 then
		KillTimer("NewNpcChat_MoveTran()")
		return
	end

	if posx ~= g_posx  or  posy ~= g_posy  then
		KillTimer("NewNpcChat_MoveTran()")
		NewNpcChat_openNewFreshman(1)
		PushEvent("NOTIFY_POP_UITIP",  "MissionTrack", 2, 33)
		NewNpcChat_AutoMoveTuto()
		g_Step = -1
		DataPool:SetCurrentFreshManGuideItemValue(100)
		if this:IsVisible() then
			--this:Hide()
		end
		return
	end


end

function NewNpcChat_AutoMoveTuto()
	NewNpcChat_Chat_Text:SetText("#{XSZY_130909_03}")
	SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
	NewNpcChat_UpDataFream(0)
	if not this:IsVisible() then
			this:Show()
	end

end

function NewNpcChat_UpDataFream(nKnowType)
	if (nKnowType == 0) then
		NewNpcChat_Button:Hide()
	elseif (nKnowType == 1) then
		NewNpcChat_Button:SetProperty( "Flash", "1" );
		NewNpcChat_Button:Show()
	end
end

function NewNpcChat_openNewFreshman(Index)
					local PosX = tonumber(NewNpcChat:GetProperty("AbsoluteXPosition"))
					local PosY = tonumber(NewNpcChat:GetProperty("AbsoluteYPosition"))
					PushEvent("OPEN_FRESHMAN_GUIDE_NEW2013Q3",Index,PosX, PosY)
end

function NewNpcChat_Skillguild()
	KillTimer("NewNpcChat_Skillguild")
	DataPool:SetCurrentFreshManGuideItemValue(0);
end

function NewNpcChat_MultiLine()
	-- 当前所在场景id
	local nSceneId = GetSceneServerID()
	if IsBranchingScene(nSceneId) == 0 then
		return
	end

	-- 如果已经弹窗过
	local showPage =Variable:GetVariable("MultiLineShowPage")
	if  showPage ~= nil  then
		return
	end

	-- 判断等级
	local nLevel = Player:GetLevel();
	if nLevel < 15 then
		return
	end

	NewNpcChat_Chat_Text:SetText("#{DFFX_20240515_35}")
	SetTimer("NewNpcChat" , "NewNpcChat_TimerCloseWindow()",g_closeWindowTime);
	NewNpcChat_UpDataFream(0)
	this:Show()

	Variable:SetVariable("MultiLineShowPage","1",0)
	PushEvent("OPEN_MULTILINE_GUIDE",1)
end