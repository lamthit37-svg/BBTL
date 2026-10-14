local g_Frame_UnifiedPosition
local tab_AllControls = {}
local tab_AllCoorPos = {}
local tab_AllLevels = {
	{ [1]=13,	[4]=9,	[3]=27,	[2]=10,	 [6]=6,   [8]=18 },
	{ [1]=14,	[2]=13,	[6]=20,	[10]=23, [3]=27,  [7]=11,  [5]=3, [4]=10 },
	{ [1]=13, 	[2]=10, [6]=6,  [3]=27,  [5]=34,  [4]=9, [8]=18},

	{ [1]=13,	[4]=16,	[3]=26,	[2]=12,  [6]=29,  [5]=1 },
	{ [1]=13,	[2]=1,	[6]=9,	[3]=2,   [7]=4,   [5]=25,  [4]=16, [8]=17},
	{ [1]=14, 	[2]=21, [6]=18, [3]=29, [5]=31,   [9]=7, [4]=11},

	{ [1]=14,	[2]=7,	[3]=23,	[7]=31,  [4]=5,   [8]=21 },
	{ [1]=13,	[2]=10,	[6]=6,	[4]=9,   [8]=18,  [5]=34,  [3]=27},
	{ [1]=15, 	[3]=19, [2]=21, [4]=1, 	 [8]=2,   [12]=11, [5]=31, [9]=28},

	{ [1]=14,	[2]=13,	[6]=20,	[10]=23, [4]=10,  [7]=11,  [5]=3},
	{ [1]=14,	[2]=13,	[6]=20,	[10]=23, [3]=27,  [5]=3,   [4]=10},
	{ [1]=16,   [2]=1,  [6]=13, [10]=15, [3]=9,   [7]=23,  [4]=6, [8]=22, [5]=31},

	{ [1]=13,	[3]=25,	[7]=31,	[2]=10,  [6]=12,  [5]=22,  [11]=4},
	{ [1]=16,	[2]=1,	[6]=13,	[10]=15, [3]=9,   [7]=23,  [4]=6, [8]=22, [5]=31},
	{ [1]=14, 	[2]=13, [6]=20, [10]=23, [4]=10,  [7]=11,  [5]=3, [4]=10},

	{ [1]=14,	[5]=7,	[9]=31,	[4]=11,  [2]=21,  [6]=18,  [3]=29},
	{ [1]=15,	[3]=19,	[2]=21,	[4]=1,   [8]=2,   [12]=11, [5]=31, [9]=28},
	{ [1]=13, 	[2]=10, [6]=6,  [4]=9, 	 [8]=18,  [5]=34,  [3]=27},

	{ [1]=13, 	[2]=15, [3]=29, [5]=7, 	 [4]=11},
	{ [1]=14,	[2]=21,	[6]=18,	[3]=29,  [5]=31,  [9]=7,   [4]=11},
	{ [1]=13, 	[2]=25, [6]=26, [10]=10, [3]=19,  [7]=33,  [4]=9, [8]=11},

	{ [1]=13, 	[3]=7, 	[7]=21, [2]=3, 	 [6]=26,  [4]=11,  [8]=24, [5]=33},
	{ [1]=13,	[2]=10,	[6]=6,	[3]=27,  [5]=34,  [4]=9,   [8]=18},
	{ [1]=13, 	[2]=1,  [6]=9,  [3]=2, 	 [7]=4,   [5]=25,  [4]=16, [8]=17},
}
local tab_AnimPos = {
	[13] = "{{0.000000,166.000000},{0.000000,76.000000}}",
	[14] = "{{0.000000,216.000000},{0.000000,76.000000}}",
	[15] = "{{0.000000,266.000000},{0.000000,76.000000}}",
	[16] = "{{0.000000,316.000000},{0.000000,76.000000}}",
}
local tabTempPosCtrol = {}
local tabPosExist = {}
local g_PlayDayIndex_FromStart = 0
local g_NowPlaySubIndex = 0
local g_ChongZhiTime = 0
--预加载函数，可以而且只能在这里注册脚本关心的事件
function ZhouNian12_Level_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function ZhouNian12_Level_OnLoad()
	g_Frame_UnifiedPosition = ZhouNian12_Level_Frame:GetProperty("UnifiedPosition")
	tab_AllControls = {
		--[1]控件名字 [2]0横向1纵向 [3]占位数量
		[1] = {ZhouNian12_Level_Outside_21_1, 0, 2},

		[2] = {ZhouNian12_Level_Inside_12_2, 1, 2},
		[3] = {ZhouNian12_Level_Inside_21_3, 0, 2},
		[4] = {ZhouNian12_Level_Inside_13_4, 1, 3},
		[5] = {ZhouNian12_Level_Inside_31_5, 0, 3},

		[6] = {ZhouNian12_Level_Inside_12_6, 1, 2},
		[7] = {ZhouNian12_Level_Inside_21_7, 0, 2},
		[8] = {ZhouNian12_Level_Inside_13_8, 1, 3},
		[9] = {ZhouNian12_Level_Inside_31_9, 0, 3},

		[10] = {ZhouNian12_Level_Inside_12_10, 1, 2},
		[11] = {ZhouNian12_Level_Inside_21_11, 0, 2},
		[12] = {ZhouNian12_Level_Inside_13_12, 1, 3},
		[13] = {ZhouNian12_Level_Inside_31_13, 0, 3},

		[14] = {ZhouNian12_Level_Inside_12_14, 1, 2},
		[15] = {ZhouNian12_Level_Inside_21_15, 0, 2},
		[16] = {ZhouNian12_Level_Inside_13_16, 1, 3},
		[17] = {ZhouNian12_Level_Inside_31_17, 0, 3},
	}
	-- tabTempPosCtrol = {
	-- 	ZhouNian12_Level_Inside_Single_1, ZhouNian12_Level_Inside_Single_2, ZhouNian12_Level_Inside_Single_3, ZhouNian12_Level_Inside_Single_4, ZhouNian12_Level_Inside_Single_5, ZhouNian12_Level_Inside_Single_6, 
	-- 	ZhouNian12_Level_Inside_Single_7, ZhouNian12_Level_Inside_Single_8, ZhouNian12_Level_Inside_Single_9, ZhouNian12_Level_Inside_Single_10, ZhouNian12_Level_Inside_Single_11, ZhouNian12_Level_Inside_Single_12, 
	-- 	ZhouNian12_Level_Inside_Single_13, ZhouNian12_Level_Inside_Single_14, ZhouNian12_Level_Inside_Single_15, ZhouNian12_Level_Inside_Single_16, ZhouNian12_Level_Inside_Single_17, ZhouNian12_Level_Inside_Single_18, 
	-- 	ZhouNian12_Level_Inside_Single_19, ZhouNian12_Level_Inside_Single_20, ZhouNian12_Level_Inside_Single_21, ZhouNian12_Level_Inside_Single_22, ZhouNian12_Level_Inside_Single_23, ZhouNian12_Level_Inside_Single_24, 
	-- 	ZhouNian12_Level_Inside_Single_25, ZhouNian12_Level_Inside_Single_26, ZhouNian12_Level_Inside_Single_27, ZhouNian12_Level_Inside_Single_28, ZhouNian12_Level_Inside_Single_29, ZhouNian12_Level_Inside_Single_30, 
	-- 	ZhouNian12_Level_Inside_Single_31, ZhouNian12_Level_Inside_Single_32, ZhouNian12_Level_Inside_Single_33, ZhouNian12_Level_Inside_Single_34, ZhouNian12_Level_Inside_Single_35, ZhouNian12_Level_Inside_Single_36, 
	-- }
	for i = 0,35 do 
		local hang = math.floor(i/6)
		local lie = math.mod(i,6)
		local nIndex = i+1
		tab_AllCoorPos[nIndex] = string.format("{{0,%s},{0,%s}}", lie*50, hang*50)
		-- tabTempPosCtrol[nIndex]:SetProperty("UnifiedPosition", tab_AllCoorPos[nIndex]);
		-- tabTempPosCtrol[nIndex]:SetText(tostring(nIndex))
		-- tabTempPosCtrol[nIndex]:Hide()
		tabPosExist[nIndex] = true;
	end
	ZhouNian12_Level_Guide_Animate1:Play(false)
	ZhouNian12_Level_Guide_Animate2:Play(false)
end

--响应事件的函数，当注册的事件发生时会调用的函数
function ZhouNian12_Level_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		ZhouNian12_Level_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2019032001 ) then
		this:Show()
		local theAction = nil
		theAction = DataPool:CreateActionItemForShow(39921681, 1)
		ZhouNian12_Level_Item1:SetActionItem(theAction:GetID());
		ZhouNian12_Level_Item3:SetActionItem(theAction:GetID());
		theAction = DataPool:CreateActionItemForShow(39921682, 1)
		ZhouNian12_Level_Item2:SetActionItem(theAction:GetID());
		g_ChongZhiTime = 0
		local taregetNpc 	= Get_XParam_INT(0)
		local dayIndex 		= Get_XParam_INT(1)
		g_PlayDayIndex_FromStart = dayIndex*3
		if taregetNpc ~= 0 then 
			local CareNPC_OBJ = Target:GetServerId2ClientId( tonumber( taregetNpc ) );
			this:CareObject(CareNPC_OBJ, 1, "ZhouNian12_Level");
		end
		if not tab_AllLevels[g_PlayDayIndex_FromStart+1] then 
			-- PushDebugMessage("ZhouNian12_Leve:没有配今天["..dayIndex.."]的关卡,默认用第一天的关卡")
			g_PlayDayIndex_FromStart = 0
		end 
		local playIndex 	= Get_XParam_INT(2) + 1
		local awardState 	= Get_XParam_INT(3)
		local nextState 	= Get_XParam_INT(4)
		-- 这里写的有点绕, 现在的逻辑是通关Success重置成下一关，
		-- 这么写的原因是：重新打开界面还需要显示领奖或下一关的按钮状态
		if awardState == 1 then 
			playIndex = playIndex - 1
			ZhouNian12_Level_AwardBkState(1, playIndex+1)
		elseif nextState == 1 then 
			playIndex = playIndex - 1
			ZhouNian12_Level_AwardBkState(0, playIndex+1)
		else
			ZhouNian12_Level_BKClientBK1:Hide()
		end
		ZhouNian12_Level_InitLevel(playIndex)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2019032002 ) then
		if not this:IsVisible() then return end
		local dayIndex 		= Get_XParam_INT(0)
		g_PlayDayIndex_FromStart = dayIndex*3
		if not tab_AllLevels[g_PlayDayIndex_FromStart+1] then 
			g_PlayDayIndex_FromStart = 0
		end 
		local awardState 	= Get_XParam_INT(1)
		local nextIndex 	= Get_XParam_INT(2) + 1
		ZhouNian12_Level_AwardBkState(awardState, nextIndex)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2019032003 ) then
		this:Hide()
	end
end

--以下是用户自定义的函数
function ZhouNian12_Level_OnHiden()
end
function ZhouNian12_Level_Close()
	this:Hide()
end
function ZhouNian12_Level_PosExist(nIndex, bExist)
	if bExist then 
		-- tabTempPosCtrol[nIndex]:SetText(tostring(nIndex).."+")
		tabPosExist[nIndex] = true;
	else
		-- tabTempPosCtrol[nIndex]:SetText(tostring(nIndex).."-")
		tabPosExist[nIndex] = false;
	end
end
function ZhouNian12_Level_InitLevel(nIndex)
	if g_NowPlaySubIndex ~= nIndex then 
		ZhouNian12_Level_Guide_Animate1:Play(true)
		ZhouNian12_Level_Guide_Animate2:Play(true)
	end
	g_NowPlaySubIndex = nIndex
	local realIndex = g_PlayDayIndex_FromStart + nIndex
	ZhouNian12_Level_Accumulate_1:Hide()
	ZhouNian12_Level_Accumulate_2:Hide()
	ZhouNian12_Level_Accumulate_3:Hide()
	if nIndex == 1 then 
		ZhouNian12_Level_Accumulate_1:Show()
	elseif nIndex == 2 then 
		ZhouNian12_Level_Accumulate_2:Show()
	elseif nIndex == 3 then 
		ZhouNian12_Level_Accumulate_3:Show()
	end
	for i = 1,36 do 
		ZhouNian12_Level_PosExist(i, false)
	end
	for i, v in pairs(tab_AllControls) do 
		v[1]:Hide()
	end
	local animPos = tab_AnimPos[13]
	if tab_AllLevels[realIndex] then 
		local oneIndex = tab_AllLevels[realIndex][1]
		animPos = tab_AnimPos[oneIndex] or tab_AnimPos[13]
	end
	ZhouNian12_Level_Guide_Animate1:SetProperty("UnifiedPosition", animPos)
	for i, v in pairs(tab_AllLevels[realIndex] or {}) do 
		tab_AllControls[i][1]:Show()
		tab_AllControls[i][1]:SetProperty("UnifiedPosition", tab_AllCoorPos[v])
		local dirAdd = 1;
		if tab_AllControls[i][2] == 1 then 
			dirAdd = 6
		end
		local num = tab_AllControls[i][3]
		for j =1, num do 
			ZhouNian12_Level_PosExist(v+(j-1)*dirAdd, true)
		end
	end
end
function ZhouNian12_Level_CheckMove(nItemIndex, dir)
	local xPos = tab_AllControls[nItemIndex][1]:GetProperty("AbsoluteXPosition")
	local yPos = tab_AllControls[nItemIndex][1]:GetProperty("AbsoluteYPosition")
	local nPosIndex = math.floor(yPos/50)*6+math.floor(xPos/50) +1
	local itemDir = tab_AllControls[nItemIndex][2]
	local itemNum = tab_AllControls[nItemIndex][3]
	local dirAdd = 1;
	if itemDir == 1 then 
		dirAdd = 6
	end
	local destPosIndex = nPosIndex + dir*dirAdd;
	local maxPosIndex = destPosIndex + (itemNum-1)*dirAdd
	-- PushDebugMessage("ZhouNian12_Level_CheckMove:"..destPosIndex..":"..maxPosIndex)
	if itemDir == 0 then 
		local startIndex = math.floor((nPosIndex-1)/6)*6+1
		if destPosIndex<startIndex or maxPosIndex>startIndex+5 then 
			return false
		end
	else
		if destPosIndex<1 or maxPosIndex >36 then 
			return false
		end
	end
	local checkIndex = maxPosIndex;
	if dir == -1 then 
		checkIndex = destPosIndex
	end
	return tabPosExist[checkIndex]==false, nPosIndex, destPosIndex;
end
function ZhouNian12_Level_ClickDir(nItemIndex, dir)
	if (nItemIndex == 1 and dir == 1 ) then 
		local xPos = tab_AllControls[1][1]:GetProperty("AbsoluteXPosition")
		local nItemOneIndex = math.floor(xPos/50) +1
		if nItemOneIndex == 7 then return end
		if nItemOneIndex == 5 then 
			ZhouNian12_Level_Success()
			return 
		end
	end
	local canMove, nPosIndex, destPosIndex = ZhouNian12_Level_CheckMove(nItemIndex, dir)
	-- PushDebugMessage("ZhouNian12_Level_ClickDir:"..nItemIndex..":"..(nPosIndex or "nil")..":"..(destPosIndex or "nil"));
	if not canMove then 
		return
	end
	--更新位置填充状态
	local dirAdd = 1;
	if tab_AllControls[nItemIndex][2] == 1 then dirAdd = 6 end
	-- 清除原来状态
	for i =1, tab_AllControls[nItemIndex][3] do 
		ZhouNian12_Level_PosExist(nPosIndex+(i-1)*dirAdd, false)
	end
	-- 更新成新的状态
	for i =1, tab_AllControls[nItemIndex][3] do 
		ZhouNian12_Level_PosExist(destPosIndex+(i-1)*dirAdd, true)
	end

	tab_AllControls[nItemIndex][1]:SetProperty("UnifiedPosition", tab_AllCoorPos[destPosIndex])
end
function ZhouNian12_Level_Success()
	tab_AllControls[1][1]:SetProperty("UnifiedPosition", "{{0,300},{0,100}}")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HRD_Success" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 893067 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 300 );					-- 参数一:类型
		Set_XSCRIPT_Parameter( 1, 100 );					-- 参数一:类型
		Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
	Send_XSCRIPT()
end

function ZhouNian12_Level_AwardBkState(canAward, nextIndex)
	ZhouNian12_Level_BKClientBK1:Show()
	ZhouNian12_Level_Btn_Pic:Hide()
	ZhouNian12_Level_Btn_Prize:Hide()
	ZhouNian12_Level_Btn_Next:Hide()

	ZhouNian12_Level_Item1:Hide()
	ZhouNian12_Level_Item2:Hide()
	ZhouNian12_Level_Item3:Hide()
	ZhouNian12_Level_PrizeText:Hide()

	if canAward == 1 then 
		ZhouNian12_Level_PrizeText:Show()
		if nextIndex > 3 then 
			ZhouNian12_Level_Item1:Show()
			ZhouNian12_Level_Item2:Show()
		else
			ZhouNian12_Level_Item3:Show()
		end
		ZhouNian12_Level_Btn_Prize:Show()
	elseif nextIndex > 3 then
		ZhouNian12_Level_Btn_Pic:Show()
	else
		ZhouNian12_Level_Btn_Next:Show()
	end
end
function ZhouNian12_Level_BtnPicClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HRD_OpenRht" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 893067 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
function ZhouNian12_Level_BtnPrizeClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HRD_GetPlayAward" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 893067 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
function ZhouNian12_Level_BtnNextClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HRD_GotoNextLevel" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 893067 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
function ZhouNian12_Level_Client_HelpClicked()
	PushEvent( "OPEN_HUODONGTEXT_HELP", 1287, "#{ZNYR_190316_67}")
end
function ZhouNian12_Level_BtnResetPlayIndex()
	local curTime = tonumber(DataPool:GetServerMinuteTime())
	if curTime - g_ChongZhiTime == 0 then 
		PushDebugMessage("#{ZNYR_190316_69}")
		return
	end
	g_ChongZhiTime = curTime
	ZhouNian12_Level_InitLevel(g_NowPlaySubIndex)
end