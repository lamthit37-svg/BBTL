
local g_Frame_UnifiedPosition
local g_NowPlaySubIndex = 0
local g_ChongZhiTime = 0
local tab_AllCoorPos = {}
local tabPosExist = {}
local tab_AllLevels = {
	{ [1]=13, [2]=15, [6]=30, [3]=7, [7]=9, [11]=23, [5]=1, [9]=33, [4]=5, [8]=19, [12]=20},
	{ [1]=13, [2]=1, [6]=19, [10]=15, [14]=17, [3]=9, [7]=11, [4]=20, [8]=18, [5]=27},
	{ [1]=14, [2]=13, [6]=21, [10]=4, [3]=1, [4]=5, [8]=6, [5]=7, [9]=28, [13]=33},
	{ [1]=15, [2]=1, [6]=21, [10]=12, [3]=19, [7]=4, [11]=28, [4]=2, [8]=11, [5]=31},
	{ [1]=13, [2]=1, [6]=2, [10]=10, [14]=29, [3]=3, [7]=22, [4]=9, [5]=25, [9]=31},
	{ [1]=15, [2]=22, [3]=9, [7]=19, [11]=31, [15]=29, [4]=1, [8]=2, [12]=12, [5]=4},
	{ [1]=13, [2]=25, [6]=26, [10]=10, [3]=19, [7]=33, [4]=9, [8]=11},
	{ [1]=13, [2]=12, [6]=24, [10]=26, [3]=27, [7]=33, [4]=3, [8]=4, [12]=17}
}
local tab_AnimPos = {
	[13] = "{{0.000000,166.000000},{0.000000,76.000000}}",
	[14] = "{{0.000000,216.000000},{0.000000,76.000000}}",
	[15] = "{{0.000000,266.000000},{0.000000,76.000000}}",
	[16] = "{{0.000000,316.000000},{0.000000,76.000000}}",
}

local tab_GuanQia_Image = {
	"set:ZhouNian12_5 image:ZN12_num1",
	"set:ZhouNian12_5 image:ZN12_num2",
	"set:ZhouNian12_5 image:ZN12_num3",
	"set:ZhouNian12_15 image:ZN12_num4",
	"set:ZhouNian12_15 image:ZN12_num5",
	"set:ZhouNian12_15 image:ZN12_num6",
	"set:ZhouNian12_15 image:ZN12_num7",
	"set:ZhouNian12_15 image:ZN12_num8",
}
--预加载函数，可以而且只能在这里注册脚本关心的事件
function ZhouNian12_Level_Chal_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function ZhouNian12_Level_Chal_OnLoad()
	g_Frame_UnifiedPosition = ZhouNian12_Level_Chal_Frame:GetProperty("UnifiedPosition")
	tab_AllControls = {
		--[1]控件名字 [2]0横向1纵向 [3]占位数量
		[1] = {ZhouNian12_Level_Chal_Outside_21_1, 0, 2},

		[2] = {ZhouNian12_Level_Chal_Inside_12_2, 1, 2},
		[3] = {ZhouNian12_Level_Chal_Inside_21_3, 0, 2},
		[4] = {ZhouNian12_Level_Chal_Inside_13_4, 1, 3},
		[5] = {ZhouNian12_Level_Chal_Inside_31_5, 0, 3},

		[6] = {ZhouNian12_Level_Chal_Inside_12_6, 1, 2},
		[7] = {ZhouNian12_Level_Chal_Inside_21_7, 0, 2},
		[8] = {ZhouNian12_Level_Chal_Inside_13_8, 1, 3},
		[9] = {ZhouNian12_Level_Chal_Inside_31_9, 0, 3},

		[10] = {ZhouNian12_Level_Chal_Inside_12_10, 1, 2},
		[11] = {ZhouNian12_Level_Chal_Inside_21_11, 0, 2},
		[12] = {ZhouNian12_Level_Chal_Inside_13_12, 1, 3},
		[13] = {ZhouNian12_Level_Chal_Inside_31_13, 0, 3},

		[14] = {ZhouNian12_Level_Chal_Inside_12_14, 1, 2},
		[15] = {ZhouNian12_Level_Chal_Inside_21_15, 0, 2},
		[16] = {ZhouNian12_Level_Chal_Inside_13_16, 1, 3},
		[17] = {ZhouNian12_Level_Chal_Inside_31_17, 0, 3},
	}
	for i = 0,35 do 
		local hang = math.floor(i/6)
		local lie = math.mod(i,6)
		local nIndex = i+1
		tab_AllCoorPos[nIndex] = string.format("{{0,%s},{0,%s}}", lie*50, hang*50)
		tabPosExist[nIndex] = true;
	end
	ZhouNian12_Level_Chal_Guide_Animate1:Play(false)
	ZhouNian12_Level_Chal_Guide_Animate2:Play(false)
end

--响应事件的函数，当注册的事件发生时会调用的函数
function ZhouNian12_Level_Chal_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		ZhouNian12_Level_Chal_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2019041301 ) then
		this:Show()
		local theAction = nil
		theAction = DataPool:CreateActionItemForShow(39921687, 10)
		ZhouNian12_Level_Chal_Item1:SetActionItem(theAction:GetID());
		theAction = DataPool:CreateActionItemForShow(39921688, 1)
		ZhouNian12_Level_Chal_Item2:SetActionItem(theAction:GetID());

		local taregetNpc 	= Get_XParam_INT(0)
		local playIndex 	= Get_XParam_INT(1) + 1
		local awardState 	= Get_XParam_INT(2)
		local nextState 	= Get_XParam_INT(3)
		if taregetNpc ~= 0 then 
			local CareNPC_OBJ = Target:GetServerId2ClientId( tonumber( taregetNpc ) );
			this:CareObject(CareNPC_OBJ, 1, "ZhouNian12_Level_Chal");
		end
		if awardState == 1 then
			playIndex = playIndex - 1
			ZhouNian12_Level_Chal_AwardBkState(1, playIndex+1)
		elseif nextState == 1 then 
			playIndex = playIndex - 1
			ZhouNian12_Level_Chal_AwardBkState(0, playIndex+1)
		else
			ZhouNian12_Level_Chal_BKClientBK1:Hide()
		end
		if not tab_AllLevels[playIndex] then 
			PushDebugMessage("ZhouNian12_Leve_Chal:没有第["..playIndex.."]的关卡,使用第一关关卡展示")
			playIndex = 1
		end
		ZhouNian12_Level_Chal_InitLevel(playIndex)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2019041302 ) then
		if not this:IsVisible() then return end
		local awardState 	= Get_XParam_INT(0)
		local nextIndex 	= Get_XParam_INT(1) + 1
		ZhouNian12_Level_Chal_AwardBkState(awardState, nextIndex)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2019041303 ) then
		this:Hide()
	end
end

--以下是用户自定义的函数
function ZhouNian12_Level_Chal_OnHiden()

end
function ZhouNian12_Level_Chal_Close()
	this:Hide()
end
function ZhouNian12_Level_Chal_PosExist(nIndex, bExist)
	if bExist then 
		tabPosExist[nIndex] = true;
	else
		tabPosExist[nIndex] = false;
	end
end
function ZhouNian12_Level_Chal_InitLevel(nIndex)
	if g_NowPlaySubIndex ~= nIndex then 
		ZhouNian12_Level_Chal_Guide_Animate1:Play(true)
		ZhouNian12_Level_Chal_Guide_Animate2:Play(true)
	end
	g_NowPlaySubIndex = nIndex
	ZhouNian12_Level_Chal_Accumulate_1:SetProperty("Image", tab_GuanQia_Image[nIndex] or "")
	for i = 1,36 do 
		ZhouNian12_Level_Chal_PosExist(i, false)
	end
	for i, v in pairs(tab_AllControls) do 
		v[1]:Hide()
	end
	local animPos = tab_AnimPos[13]
	if tab_AllLevels[nIndex] then 
		local oneIndex = tab_AllLevels[nIndex][1]
		animPos = tab_AnimPos[oneIndex] or tab_AnimPos[13]
	end
	ZhouNian12_Level_Chal_Guide_Animate1:SetProperty("UnifiedPosition", animPos)
	for i, v in pairs(tab_AllLevels[nIndex] or {}) do 
		tab_AllControls[i][1]:Show()
		tab_AllControls[i][1]:SetProperty("UnifiedPosition", tab_AllCoorPos[v])
		local dirAdd = 1;
		if tab_AllControls[i][2] == 1 then 
			dirAdd = 6
		end
		local num = tab_AllControls[i][3]
		for j =1, num do 
			ZhouNian12_Level_Chal_PosExist(v+(j-1)*dirAdd, true)
		end
	end
end

function ZhouNian12_Level_Chal_BtnResetPlayIndex()
	local curTime = tonumber(DataPool:GetServerMinuteTime())
	if curTime - g_ChongZhiTime == 0 then 
		PushDebugMessage("#{ZNYR_190316_69}")
		return
	end
	g_ChongZhiTime = curTime
	ZhouNian12_Level_Chal_InitLevel(g_NowPlaySubIndex)
end
function ZhouNian12_Level_Chal_AwardBkState(canAward, nextIndex)
	ZhouNian12_Level_Chal_BKClientBK1:Show()
	ZhouNian12_Level_Chal_Btn_Prize:Hide()
	ZhouNian12_Level_Chal_Btn_Next:Hide()
	ZhouNian12_Level_Chal_Item1:Hide()
	ZhouNian12_Level_Chal_Item2:Hide()
	ZhouNian12_Level_Chal_PrizeText:Hide()
	ZhouNian12_Level_Chal_NOPrizeText:Hide()
	if canAward == 1 then 
		ZhouNian12_Level_Chal_Item1:Show()
		ZhouNian12_Level_Chal_Item2:Show()
		ZhouNian12_Level_Chal_PrizeText:Show()
		ZhouNian12_Level_Chal_Btn_Prize:Show()
	elseif nextIndex > 8 then
		ZhouNian12_Level_Chal_NOPrizeText:Show()
	else
		ZhouNian12_Level_Chal_Btn_Next:Show()
	end
end
function ZhouNian12_Level_Chal_CheckMove(nItemIndex, dir)
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
function ZhouNian12_Level_Chal_ClickDir(nItemIndex, dir)
	if (nItemIndex == 1 and dir == 1 ) then 
		local xPos = tab_AllControls[1][1]:GetProperty("AbsoluteXPosition")
		local nItemOneIndex = math.floor(xPos/50) +1
		if nItemOneIndex == 7 then return end
		if nItemOneIndex == 5 then 
			ZhouNian12_Level_Chal_Success()
			return 
		end
	end
	local canMove, nPosIndex, destPosIndex = ZhouNian12_Level_Chal_CheckMove(nItemIndex, dir)
	if not canMove then 
		return
	end
	-- PushDebugMessage("#{ZNYR_190316_32}")
	--更新位置填充状态
	local dirAdd = 1;
	if tab_AllControls[nItemIndex][2] == 1 then dirAdd = 6 end
	-- 清除原来状态
	for i =1, tab_AllControls[nItemIndex][3] do 
		ZhouNian12_Level_Chal_PosExist(nPosIndex+(i-1)*dirAdd, false)
	end
	-- 更新成新的状态
	for i =1, tab_AllControls[nItemIndex][3] do 
		ZhouNian12_Level_Chal_PosExist(destPosIndex+(i-1)*dirAdd, true)
	end

	tab_AllControls[nItemIndex][1]:SetProperty("UnifiedPosition", tab_AllCoorPos[destPosIndex])
end
function ZhouNian12_Level_Chal_Success()
	tab_AllControls[1][1]:SetProperty("UnifiedPosition", "{{0,300},{0,100}}")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HRD_TZ_Success" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 893067 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 300 );					-- 参数一:类型
		Set_XSCRIPT_Parameter( 1, 100 );					-- 参数一:类型
		Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
	Send_XSCRIPT()
end
function ZhouNian12_Level_Chal_BtnPrizeClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HRD_TZ_GetPlayAward" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 893067 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
function ZhouNian12_Level_Chal_BtnNextClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HRD_TZ_GotoNextLevel" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 893067 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
function ZhouNian12_Level_Chal_Client_HelpClicked()
	PushEvent( "OPEN_HUODONGTEXT_HELP", 1299, "#{ZNYR_190316_67}")
end
function ZhouNian12_Level_Chal_BtnResetPlayIndex()
	local curTime = tonumber(DataPool:GetServerMinuteTime())
	if curTime - g_ChongZhiTime == 0 then 
		PushDebugMessage("#{ZNYR_190316_69}")
		return
	end
	g_ChongZhiTime = curTime
	ZhouNian12_Level_Chal_InitLevel(g_NowPlaySubIndex)
end