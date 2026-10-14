-- 雪人大作战，分数界面
local g_unifiedposistion

local g_ui_list = {}

local g_camp_info = 
{
	{name="#{BXDZ_240918_182}",},
	{name="#{BXDZ_240918_183}",},
	{name="#{BXDZ_240918_184}",},
	{name="#{BXDZ_240918_185}",},
	{name="#{BXDZ_240918_186}",},
	{name="#{BXDZ_240918_186}",},
}

local g_SnowMan_Exp = {               -- 雪人经验
	exp = {
        100,200,400,600,900,1200,1600,
        2000,2000,999999,999999,
	},

	maxexp = 999999,
	maxlevel = 10,
}
local g_flagmax = 4
local g_mission_max = 2
local g_flag = {0,0,0,0}

local g_missioninfo = {
	[1] = {flag=4, str="#{BXDZ_240918_361}",max=3,},
	[2] = {flag=3, str="#{BXDZ_240918_362}",max=10,},
	[3] = {flag=2, str="#{BXDZ_240918_363}",max=5,},
	[4] = {flag=1, str="#{BXDZ_240918_364}",max=5,},
}

function Frozen_PVPScore_PreLoad()
	this:RegisterEvent("XRZPVP_BATTLESCORE_SHOW")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("XRZPVP_BATTLERESULT_SHOW",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Frozen_PVPScore_OnLoad()

	g_ui_list = {}
	-- 保存界面的默认相对位置
	g_unifiedposistion = Frozen_PVPScore_Frame:GetProperty("UnifiedPosition")
end

function Frozen_PVPScore_OnEvent(event)

	if ( event == "ADJEST_UI_POS" ) then
		Frozen_PVPScore_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		Frozen_PVPScore_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_PVPScore_CloseClicked()
	elseif (event == "XRZPVP_BATTLERESULT_SHOW") then
		Frozen_PVPScore_CloseClicked()
	elseif(event == "XRZPVP_BATTLESCORE_SHOW") then
		Frozen_PVPScore_OnShow()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 80030605 ) then
		Frozen_PVPScoreTask_OnTaskShow()
	end
end

function Frozen_PVPScore_OnShow()
	local ret = Frozen_PVPScore_InitUIData()
	if ret > 0 then
		if IsWindowShow("Frozen_PVPScoreMini") then
			this:Hide()
		else
			this:Show()
		end
	else
		this:Hide()
	end

	PushEvent("XRZPVP_UI_BATTLE_PACKET_SHOW")
end

-- 初始化控件数据
function Frozen_PVPScore_InitUIData(lastTime)

	local data = XRZPVP:GetBattleBaseInfo()
	if data == nil or type(data) ~= "table" then
		this:Hide()
		return -1
	end

	-- 显示一些基础信息
	local strLowNum = ScriptGlobal_Format("#{BXDZ_240918_178}", data.lownum)
	Frozen_PVPScore_SnowMan_Text1:SetText(strLowNum)
	local strHighNum = ScriptGlobal_Format("#{BXDZ_240918_179}", data.highnum)
	Frozen_PVPScore_SnowMan_Text2:SetText(strHighNum)

	-- 显示剩余时间
	if data.lefttime ~= nil and data.lefttime > 0 then
		Frozen_PVPScore_Text_Time:SetProperty("Timer", data.lefttime)
	else
		Frozen_PVPScore_Text_Time:SetProperty("Timer", 0)
	end
	Frozen_PVPScore_Text_Time:SetProperty("TextColor", "FF00FF00")


	if data.freshtime <= 0 and data.freshtime2 <= 0 and data.freshtime3 <= 0 then
		Frozen_PVPScore_SnowMan_Text3:Hide()
		Frozen_PVPScore_SnowMan_Text5:Hide()
		Frozen_PVPScore_SnowMan_Text6:Hide()
		Frozen_PVPScore_SnowMan_Text4:Show()
	elseif data.freshtime > 0 and data.freshtime2 > 0 and data.freshtime3 > 0 then
		if data.freshtime < data.freshtime2 and data.freshtime < data.freshtime3 then
			Frozen_PVPScore_SnowMan_Text3:Hide()
			Frozen_PVPScore_SnowMan_Text4:Hide()
			Frozen_PVPScore_SnowMan_Text6:Hide()
			Frozen_PVPScore_SnowMan_Text5:Show()

			Frozen_PVPScore_SnowMan_Text5_Time:SetProperty("Timer", data.freshtime)
			Frozen_PVPScore_SnowMan_Text5_Time:SetProperty("TextColor", "FF00FF00")
			Frozen_PVPScore_SnowMan_Text5_Time:Show()
		elseif data.freshtime2 < data.freshtime and data.freshtime2 < data.freshtime3 then
			Frozen_PVPScore_SnowMan_Text3:Hide()
			Frozen_PVPScore_SnowMan_Text4:Hide()
			Frozen_PVPScore_SnowMan_Text5:Hide()
			Frozen_PVPScore_SnowMan_Text6:Show()

			Frozen_PVPScore_SnowMan_Text6_Time:SetProperty("Timer", data.freshtime2)
			Frozen_PVPScore_SnowMan_Text6_Time:SetProperty("TextColor", "FF00FF00")
			Frozen_PVPScore_SnowMan_Text6_Time:Show()
		elseif data.freshtime3 < data.freshtime and data.freshtime3 < data.freshtime2 then
			Frozen_PVPScore_SnowMan_Text3:Show()
			Frozen_PVPScore_SnowMan_Text4:Hide()
			Frozen_PVPScore_SnowMan_Text5:Hide()
			Frozen_PVPScore_SnowMan_Text6:Hide()

			Frozen_PVPScore_SnowMan_Text3_Time:SetProperty("Timer", data.freshtime3)
			Frozen_PVPScore_SnowMan_Text3_Time:SetProperty("TextColor", "FF00FF00")
			Frozen_PVPScore_SnowMan_Text3_Time:Show()
		else
			Frozen_PVPScore_SnowMan_Text3:Hide()
			Frozen_PVPScore_SnowMan_Text4:Hide()
			Frozen_PVPScore_SnowMan_Text5:Hide()
			Frozen_PVPScore_SnowMan_Text6:Show()

			Frozen_PVPScore_SnowMan_Text6_Time:SetProperty("Timer", data.freshtime2)
			Frozen_PVPScore_SnowMan_Text6_Time:SetProperty("TextColor", "FF00FF00")
			Frozen_PVPScore_SnowMan_Text6_Time:Show()
		end
	elseif data.freshtime <= 0 then
		if data.freshtime2 > 0 and data.freshtime3 > 0 then
			if data.freshtime2 < data.freshtime3 then
				Frozen_PVPScore_SnowMan_Text3:Hide()
				Frozen_PVPScore_SnowMan_Text4:Hide()
				Frozen_PVPScore_SnowMan_Text5:Hide()
				Frozen_PVPScore_SnowMan_Text6:Show()
	
				Frozen_PVPScore_SnowMan_Text6_Time:SetProperty("Timer", data.freshtime2)
				Frozen_PVPScore_SnowMan_Text6_Time:SetProperty("TextColor", "FF00FF00")
				Frozen_PVPScore_SnowMan_Text6_Time:Show()
			else
				Frozen_PVPScore_SnowMan_Text3:Show()
				Frozen_PVPScore_SnowMan_Text4:Hide()
				Frozen_PVPScore_SnowMan_Text5:Hide()
				Frozen_PVPScore_SnowMan_Text6:Hide()
	
				Frozen_PVPScore_SnowMan_Text3_Time:SetProperty("Timer", data.freshtime3)
				Frozen_PVPScore_SnowMan_Text3_Time:SetProperty("TextColor", "FF00FF00")
				Frozen_PVPScore_SnowMan_Text3_Time:Show()
			end
		else
			Frozen_PVPScore_SnowMan_Text3:Hide()
			Frozen_PVPScore_SnowMan_Text4:Hide()
			Frozen_PVPScore_SnowMan_Text5:Hide()
			Frozen_PVPScore_SnowMan_Text6:Show()

			Frozen_PVPScore_SnowMan_Text6_Time:SetProperty("Timer", data.freshtime2)
			Frozen_PVPScore_SnowMan_Text6_Time:SetProperty("TextColor", "FF00FF00")
			Frozen_PVPScore_SnowMan_Text6_Time:Show()
		end
	end

	local camp,level,exp,max,camppos = XRZPVP:GetBattleRankInfo("campinfo")
	local strLevel = ScriptGlobal_Format("#{BXDZ_240918_176}", level)
	Frozen_PVPScore_SnowMan_Level:SetText(strLevel)

	local realExp, realNeedExp = Frozen_PVPScore_GetExp(exp, level)
	local strExp = ScriptGlobal_Format("#{BXDZ_240918_177}", realExp, realNeedExp)
	Frozen_PVPScore_SnowMan_Pro:SetText(strExp)

	-- 刷新阵营信息
	local teamCount = XRZPVP:GetBattleRankInfo("teamnum")
	Frozen_PVPScore_TopList_ListFrame:Clear()
	if (teamCount > 0) then
		for i=1, teamCount, 1 do
			local snowDataValid = XRZPVP:GetBattleRankInfo("isvalid", i-1)
			if snowDataValid ~= nil and snowDataValid > 0 then
				local child = Frozen_PVPScore_TopList_ListFrame:AddChild("Frozen_PVPScore_TopList_List_Item")
				if (child ~= nil) then
					-- 是否是自己的阵营					
					local snowStackScore,playerCamp = XRZPVP:GetBattleRankInfo("rankinfo", i-1)
					local strRank = tostring(i)
					local strCampName = g_camp_info[i].name
					if g_camp_info[playerCamp+1] ~= nil then
						strCampName = g_camp_info[playerCamp+1].name
					end
					local strScore = ScriptGlobal_Format("#{BXDZ_240918_187}", snowStackScore)
					child:GetSubItem("Frozen_PVPScore_TopList_List_Rank"):SetText("#cfff263"..strRank)
					child:GetSubItem("Frozen_PVPScore_TopList_List_Name"):SetText(strCampName)
					child:GetSubItem("Frozen_PVPScore_TopList_List_Score"):SetText(strScore)

					if playerCamp == camppos then
						child:GetSubItem("Frozen_PVPScore_TopList_List_ItemBK"):Show()
					else
						child:GetSubItem("Frozen_PVPScore_TopList_List_ItemBK"):Hide()
					end
				end
			end
		end
	end
	
	return 1
end

function Frozen_PVPScore_OK()
	
end

function Frozen_PVPScore_TransformName(name, zoneid)
	if zoneid < 0 then
		return name
	end

	local retname = name
	if g_trasname > 0 then
		local selfzoneid = DataPool:GetSelfZoneWorldID()
		if selfzoneid ~= zoneid then
			local serverName = DataPool:GetServerName( zoneid )
			retname = name.."@"..tostring(serverName)
		end
	end

	return retname
end

function Frozen_PVPScore_GetExp(curexp, level)
	
	local needExp = 0
	for lv, exp in (g_SnowMan_Exp.exp or {}) do
		if lv == level then
			local realExp = curexp - needExp
			return realExp, exp
		else
			needExp = needExp + exp
		end
	end

	return 0,1
end

--================================================
-- 开启个人榜
--================================================
function Frozen_PVPScore_TopList()
	PushEvent("XRZPVP_BATTLERANK_SHOW")
end

--================================================
-- 最小化
--================================================
function Frozen_PVPScore_Mini()
	PushEvent("XRZPVP_UI_BATTLEMINI_SHOW")
end

--================================================
-- 关闭
--================================================
function Frozen_PVPScore_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_PVPScore_ResetPos()
	Frozen_PVPScore_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

--================================================
-- 打开任务界面
--================================================
function Frozen_PVPScore_Task()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAskPlayerTaskInfo")
		Set_XSCRIPT_ScriptID(800306)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Frozen_PVPScoreTask_OnTaskShow()

	g_flag = {}
	for i=1, g_flagmax do
		g_flag[i] = Get_XParam_INT(i-1)
	end
	
	local isShow = Get_XParam_INT(g_flagmax)

	local progress = 0
	for i=1, g_flagmax do
		local data = g_missioninfo[i]
		if data ~= nil then
			local num = g_flag[data.flag]
			if num ~= nil and num >= data.max then
				num = data.max
				progress = progress + 1
			end
		end
	end

	local colorStr = "#{BXDZ_240918_377}"
	if progress >= g_mission_max then
		progress = g_mission_max
		colorStr = "#{BXDZ_240918_359}"
	end

	local str = ScriptGlobal_Format(colorStr, progress, g_mission_max)
	Frozen_PVPScore_TaskTask:SetText(str)

end