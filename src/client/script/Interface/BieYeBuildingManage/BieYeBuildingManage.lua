
local g_BieYeBuildingManage_Frame_UnifiedPosition;
local g_clientNpcId = -1
local g_curBieYeBuildingIndex = 1

local g_MaxBuildingNum = 8
local g_MaxBuildingLevel = 5
local g_BuildingLevelControls = {}
local g_BuildingLevelTimeControls = {}
local g_BuildingButton = {}

local g_BuildingName = {"#{JYGZ_160606_207}", "#{JYGZ_160606_208}", "#{JYGZ_160809_367}", "#{JYGZ_160606_211}",
												"#{JYGZ_160606_209}", "#{JYGZ_160606_209}", "#{JYGZ_160606_210}", "#{JYGZ_160606_212}"}
												
local g_BuildingDes = {"#{JYGZ_160523_61}", "#{JYGZ_160523_62}", "#{JYGZ_160523_66}", "#{JYGZ_160523_65}",
											 "#{JYGZ_160523_63}", "#{JYGZ_160523_63}", "#{JYGZ_160523_64}", "#{JYGZ_160523_64}"}

function BieYeBuildingManage_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	this:RegisterEvent("BIEYERESUPDATE") --资源数据有更新
end

function BieYeBuildingManage_OnLoad() 
	g_BieYeBuildingManage_Frame_UnifiedPosition = BieYeBuildingManage_Frame:GetProperty("UnifiedPosition");
	
	g_BuildingLevelControls[1] = BieYeBuildingManage_BuildingSet_Building01_level
	g_BuildingLevelControls[2] = BieYeBuildingManage_BuildingSet_Building02_level
	g_BuildingLevelControls[3] = BieYeBuildingManage_BuildingSet_Building08_level
	g_BuildingLevelControls[4] = BieYeBuildingManage_BuildingSet_Building03_level
	g_BuildingLevelControls[5] = BieYeBuildingManage_BuildingSet_Building04_level
	g_BuildingLevelControls[6] = BieYeBuildingManage_BuildingSet_Building05_level
	g_BuildingLevelControls[7] = BieYeBuildingManage_BuildingSet_Building06_level
	g_BuildingLevelControls[8] = BieYeBuildingManage_BuildingSet_Building07_level
	
	g_BuildingLevelTimeControls[1] = BieYeBuildingManage_BuildingSet_Building01_Time
	g_BuildingLevelTimeControls[2] = BieYeBuildingManage_BuildingSet_Building02_Time
	g_BuildingLevelTimeControls[3] = BieYeBuildingManage_BuildingSet_Building08_Time
	g_BuildingLevelTimeControls[4] = BieYeBuildingManage_BuildingSet_Building03_Time
	g_BuildingLevelTimeControls[5] = BieYeBuildingManage_BuildingSet_Building04_Time
	g_BuildingLevelTimeControls[6] = BieYeBuildingManage_BuildingSet_Building05_Time
	g_BuildingLevelTimeControls[7] = BieYeBuildingManage_BuildingSet_Building06_Time
	g_BuildingLevelTimeControls[8] = BieYeBuildingManage_BuildingSet_Building07_Time
	
	g_BuildingButton[1] = BieYeBuildingManage_BuildingSet_Building01_Btn
	g_BuildingButton[2] = BieYeBuildingManage_BuildingSet_Building02_Btn
	g_BuildingButton[4] = BieYeBuildingManage_BuildingSet_Building03_Btn
	g_BuildingButton[5] = BieYeBuildingManage_BuildingSet_Building04_Btn
	g_BuildingButton[6] = BieYeBuildingManage_BuildingSet_Building05_Btn
	g_BuildingButton[7] = BieYeBuildingManage_BuildingSet_Building06_Btn
	g_BuildingButton[8] = BieYeBuildingManage_BuildingSet_Building07_Btn
	g_BuildingButton[3] = BieYeBuildingManage_BuildingSet_Building08_Btn
end

function BieYeBuildingManage_OnEvent(event) 

	if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 89187202 then
		local Type = Get_XParam_INT(0)
		
		if Type == 1 then       --打开界面
			if this : IsVisible() then									-- 如果界面开着，则不处理
				return
			end
			
			local npcObjId = Get_XParam_INT(1)
			g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
			if g_clientNpcId == -1 then
				PushDebugMessage("未发现 NPC")
				BieYeBuildingManage_OnHiden()
				return
			end
		
			this:CareObject( g_clientNpcId, 1, "BieYeBuildingManage" )
			BieYeBuildingManage_Update()
			this:Show()
			
		elseif Type == 2 then		--成功刷新界面
			if(not this:IsVisible()) then
				return
			end
			
			BieYeBuildingManage_Update()
		end
	
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeBuildingManage_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeBuildingManage_Frame_On_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BieYeBuildingManage_OnHiden()
		
	elseif (event == "BIEYERESUPDATE") then
		if(this:IsVisible()) then
			BieYeBuildingManage_ResourceUpdate()
		end
	end
end

function BieYeBuildingManage_Frame_On_ResetPos()
  BieYeBuildingManage_Frame:SetProperty("UnifiedPosition", g_BieYeBuildingManage_Frame_UnifiedPosition);
end

function BieYeBuildingManage_OnHiden()
	this:CareObject( g_clientNpcId, 0, "BieYeBuildingManage" )
	g_clientNpcId = -1
	
	g_curBieYeBuildingIndex = 1
	this:Hide() 
end

function BieYeBuildingManage_Close()
	BieYeBuildingManage_OnHiden()
end

function BieYeBuildingManage_GetBuildingLevelTime(Time)
	if Time >= 3600 then
		local hour = math.floor(Time/3600)
		local minute = math.floor(math.mod(Time, 3600)/60)
				
		local strHour = ScriptGlobal_Format("#{JYGZ_160615_228}", tostring(hour))
		local strMinute = ScriptGlobal_Format("#{JYGZ_160615_229}", tostring(minute))
		if minute > 0 then
			str = strHour..strMinute
		else
			str = strHour
		end
	else
		local minute = math.floor(Time/60)
		if minute <= 0 then
			minute = 1
		end
		local strMinute = ScriptGlobal_Format("#{JYGZ_160615_229}", tostring(minute))			
		str = strMinute
	end
	
	return str
end

function BieYeBuildingManage_ResourceUpdate()
	local WoodNum = BieYeUI:GetBieYeBaseInfo("ResWoods")
	local StoneNum = BieYeUI:GetBieYeBaseInfo("ResStones")
	local FoodNum = BieYeUI:GetBieYeBaseInfo("ResFoods")
	
	local str = ScriptGlobal_Format("#{JYGZ_160523_48}", tostring(WoodNum))
	BieYeBuildingManage_CaiLiao1_des:SetText(str)
	
	str = ScriptGlobal_Format("#{JYGZ_160523_50}", tostring(FoodNum))
	BieYeBuildingManage_CaiLiao2_des:SetText(str)
	
	str = ScriptGlobal_Format("#{JYGZ_160523_52}", tostring(StoneNum))
	BieYeBuildingManage_CaiLiao3_des:SetText(str)
end

function BieYeBuildingManage_Update()

	if IsWindowShow( "BieYeBaseInfo" ) then
		CloseWindow( "BieYeBaseInfo", true )
	end
	
	local str = ScriptGlobal_Format("#{JYGZ_160809_401}", tostring(BieYeUI:GetBieYeBaseInfo("HouseComfort")))
	BieYeBuildingManage_JSSSD_des:SetText(str)
	
	str = ScriptGlobal_Format("#{JYGZ_160809_403}", tostring(BieYeUI:GetBieYeBaseInfo("YardComfort")))
	BieYeBuildingManage_TYSSD_des:SetText(str)
	
	--str = ScriptGlobal_Format("#{JYGZ_160809_405}", tostring(BieYeUI:GetBieYeBaseInfo("Cleaness")))
	--BieYeBuildingManage_ZYQJD_des:SetText(str)
	
	BieYeBuildingManage_ResourceUpdate()
	
	local level = {}
	level[1],level[2],level[3],level[4],level[5],level[6],level[7],level[8] = BieYeUI:GetBuildingsLevel()
	for i = 1,g_MaxBuildingNum do
		str = ScriptGlobal_Format("#{JYGZ_160714_237}", tostring(level[i]))
		g_BuildingLevelControls[i]:SetText(str)
	end
	
	level[1],level[2],level[3],level[4],level[5],level[6],level[7],level[8] = BieYeUI:GetBuildingsLevelTime()
	for i = 1, g_MaxBuildingNum do
		if level[i] <= 0 then
			g_BuildingLevelTimeControls[i]:Hide()
		else
			g_BuildingLevelTimeControls[i]:Show()
			str = ScriptGlobal_Format("#{JYGZ_160523_47}", BieYeBuildingManage_GetBuildingLevelTime(level[i]))
			g_BuildingLevelTimeControls[i]:SetText(str)
		end
	end
	
	BieYeBuildingManage_UpdateBuiding(g_curBieYeBuildingIndex)
end

function BieYeBuildingManage_UpdateBuiding(index)

	if index < 1 or index > g_MaxBuildingNum then
		return
	end
	
	g_curBieYeBuildingIndex = index
	
	for i = 1, g_MaxBuildingNum do
		g_BuildingButton[i]:SetCheck(0)
	end
	
	g_BuildingButton[g_curBieYeBuildingIndex]:SetCheck(1)
	
	local level = {}
	level[1],level[2],level[3],level[4],level[5],level[6],level[7],level[8] = BieYeUI:GetBuildingsLevel()
	
	local str = ScriptGlobal_Format(g_BuildingName[index], tostring(level[index]))
	BieYeBuildingManage_BuildingInfo_BdName_name:SetText(str)
	BieYeBuildingManage_BuildingInfo_Explain:SetText(g_BuildingDes[index])
	
	local levelTime = {}
	levelTime[1],levelTime[2],levelTime[3],levelTime[4],levelTime[5],levelTime[6],levelTime[7],levelTime[8] = BieYeUI:GetBuildingsLevelTime()
		
	if level[index] == g_MaxBuildingLevel then
		BieYeBuildingManage_BuildingInfo_LvUpLimit_des:SetText("#{JYGZ_160809_432}")
		BieYeBuildingManage_BuildingInfo_LvUpCost_des:SetText("#{JYGZ_160809_432}")
		BieYeBuildingManage_BuildingInfo_LvUpTime_des:SetText("#{JYGZ_160809_432}")
	elseif (levelTime[index] > 0) then
		str = ScriptGlobal_Format("#{JYGZ_160809_418}", BieYeBuildingManage_GetBuildingLevelTime(levelTime[index]))
		BieYeBuildingManage_BuildingInfo_LvUpLimit_des:SetText(str)
		BieYeBuildingManage_BuildingInfo_LvUpCost_des:SetText(str)
		BieYeBuildingManage_BuildingInfo_LvUpTime_des:SetText(str)
	else
		local MoneyNum, WoodNum, FoodNum, StoneNum, BedRoomValue, ParkValue,BieYeValue, NeedTime = BieYeUI:GetBuildingsLevelupData(index-1, level[index])
		if(index == 1) then
			
			local bRet = 1
			for i = 2, g_MaxBuildingNum do
				if level[1] > level[i] then
					bRet = 0
					break
				end
			end
			
			if bRet == 1 then
				str = ScriptGlobal_Format("#{JYGZ_160809_408}", tostring(level[index])).."\n"
			else
				str = ScriptGlobal_Format("#{JYGZ_160809_409}", tostring(level[index])).."\n"
			end
			
			if BieYeUI:GetBieYeBaseInfo("HouseComfort") < BedRoomValue then
				str = str..ScriptGlobal_Format("#{JYGZ_160809_411}", tostring(BedRoomValue)).."\n"
			else
				str = str..ScriptGlobal_Format("#{JYGZ_160809_410}", tostring(BedRoomValue)).."\n"
			end
			
			if BieYeUI:GetBieYeBaseInfo("YardComfort") < ParkValue then
				str = str..ScriptGlobal_Format("#{JYGZ_160809_413}", tostring(ParkValue)).."\n"
			else
				str = str..ScriptGlobal_Format("#{JYGZ_160809_412}", tostring(ParkValue)).."\n"
			end
			
			--if BieYeUI:GetBieYeBaseInfo("Cleaness") < BieYeValue then
				--str = str.."#{JYGZ_160809_415}".."\n"
			--else
				--str = str.."#{JYGZ_160809_414}".."\n"
			--end
			
			if BieYeUI:GetBieYeBaseInfo("WorkingGardener") + BieYeUI:GetBieYeBaseInfo("WorkingYbGardener") > 5 then
				str = str.."#{JYGZ_160809_417}"
			else
				str = str.."#{JYGZ_160809_416}"
			end
			
			BieYeBuildingManage_BuildingInfo_LvUpLimit_des:SetText(str)
		else
			if level[index] <  level[1] then
				str = ScriptGlobal_Format("#{JYGZ_160809_433}", tostring(level[1])).."\n"
			else
				str = ScriptGlobal_Format("#{JYGZ_160809_434}", tostring(level[1] + 1)).."\n"
			end
			
			--if BieYeUI:GetBieYeBaseInfo("Cleaness") < BieYeValue then
				--str = str.."#{JYGZ_160809_415}".."\n"
			--else
				--str = str.."#{JYGZ_160809_414}".."\n"
			--end
			
			if BieYeUI:GetBieYeBaseInfo("WorkingGardener") + BieYeUI:GetBieYeBaseInfo("WorkingYbGardener") > 5 then
				str = str.."#{JYGZ_160809_417}"
			else
				str = str.."#{JYGZ_160809_416}"
			end
			
			BieYeBuildingManage_BuildingInfo_LvUpLimit_des:SetText(str)
		end
		
		if   BieYeUI:GetBieYeBaseInfo("ResWoods") < WoodNum then
			str = ScriptGlobal_Format("#{JYGZ_160809_421}", tostring(WoodNum)).."\n"
		else
			str = ScriptGlobal_Format("#{JYGZ_160809_420}", tostring(WoodNum)).."\n"
		end
		
		if   BieYeUI:GetBieYeBaseInfo("ResFoods") < FoodNum then
			str = str..ScriptGlobal_Format("#{JYGZ_160809_423}", tostring(FoodNum)).."\n"
		else
			str = str..ScriptGlobal_Format("#{JYGZ_160809_422}", tostring(FoodNum)).."\n"
		end
		
		if   BieYeUI:GetBieYeBaseInfo("ResStones") < StoneNum then
			str = str..ScriptGlobal_Format("#{JYGZ_160809_425}", tostring(StoneNum))
		else
			str = str..ScriptGlobal_Format("#{JYGZ_160809_424}", tostring(StoneNum))
		end
		
		BieYeBuildingManage_BuildingInfo_LvUpCost_des:SetText(str)
		
		str = ScriptGlobal_Format("#{JYGZ_160809_431}", BieYeBuildingManage_GetBuildingLevelTime(NeedTime))
		BieYeBuildingManage_BuildingInfo_LvUpTime_des:SetText(str)
	end
end

function BieYeBuildingManage_LevelUp()
	if g_curBieYeBuildingIndex < 1 or g_curBieYeBuildingIndex > g_MaxBuildingNum then
		return
	end
	
	local level = {}
	level[1],level[2],level[3],level[4],level[5],level[6],level[7],level[8] = BieYeUI:GetBuildingsLevel()
	
	if level[g_curBieYeBuildingIndex] >= g_MaxBuildingLevel then
		PushDebugMessage("#{JYGZ_160523_70}")
		return 
	end
	
	local levelTime = {}
	levelTime[1],levelTime[2],levelTime[3],levelTime[4],levelTime[5],levelTime[6],levelTime[7],levelTime[8] = BieYeUI:GetBuildingsLevelTime()
	if levelTime[g_curBieYeBuildingIndex] > 0 then
		PushDebugMessage("#{JYGZ_160530_204}")
		return 
	end
	
	local str
	if g_curBieYeBuildingIndex == 1 then
		for i = 2, g_MaxBuildingNum do
			if level[1] > level[i] then
				str = ScriptGlobal_Format("#{JYGZ_160523_71}", tostring(level[1]))
				PushDebugMessage(str)
				return 
			end
		end
	else
		if level[g_curBieYeBuildingIndex] >= level[1] then
				PushDebugMessage("#{JYGZ_160523_72}")
				return 
		end
	end
	
	local needMoneyNum, needWoodNum, needFoodNum, needStoneNum = BieYeUI:GetBuildingsLevelupData(g_curBieYeBuildingIndex-1, level[g_curBieYeBuildingIndex])
	
	local WoodNum = BieYeUI:GetBieYeBaseInfo("ResWoods")
	local StoneNum = BieYeUI:GetBieYeBaseInfo("ResStones")
	local FoodNum = BieYeUI:GetBieYeBaseInfo("ResFoods")
	
	if WoodNum < needWoodNum then
		PushDebugMessage("#{JYGZ_160523_73}")
		return 
	end
	
	if FoodNum < needFoodNum then
		PushDebugMessage("#{JYGZ_160523_73}")
		return 
	end
	
	if StoneNum < needStoneNum then
		PushDebugMessage("#{JYGZ_160523_73}")
		return 
	end
	
	BieYeUI:BuildingLevelUpWithIndex(g_curBieYeBuildingIndex-1,1,0)
end