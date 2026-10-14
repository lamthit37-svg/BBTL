local g_JiangHuShiJi_UnifiedPosition 
local g_JiangHuShiJi_CurPage = 1
local g_JiangHuShiJi_ShowNextIdx = -1
local g_JiangHuShiJi_PerPageCount = 4
local g_JiangHuShiJi_Total = 0 
local g_JiangHuShiJi_Ctl = {}
local g_JiangHuShiJi_red = 0 
local g_JiangHuShiJi_GiftMD = 0
local g_JiangHuShiJi_SvtTime = 0
--=========
-- PreLoad()
--=========
function JiangHuShiJi_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("OPENJIANGSHUJISHI",true) 
	this:RegisterEvent("UPDATE_MISSION",true) 
	this:RegisterEvent("UPDATE_MISSION_TRACK",true) 
end

--=========
-- OnLoad()
--=========
function JiangHuShiJi_OnLoad() 
	g_JiangHuShiJi_UnifiedPosition = JiangHuShiJi_Frame:GetProperty("UnifiedPosition")
	JiangHuShiJi_LoadControl()
end

--=========
-- Event
--=========
function JiangHuShiJi_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88892802) then
		g_JiangHuShiJi_red 		= Get_XParam_INT(0)    
		g_JiangHuShiJi_GiftMD	= Get_XParam_INT(1) 
		g_JiangHuShiJi_SvtTime	= Get_XParam_INT(2) 
		JiangHuShiJi_GetCurPage() 
		JiangHuShiJi_Open()
		this:Show()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		JiangHuShiJi_OnHiden()
	elseif event == "VIEW_RESOLUTION_CHANGED" then	
		JiangHuShiJi_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
        JiangHuShiJi_On_ResetPos()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88892801) then
		g_JiangHuShiJi_red = Get_XParam_INT(0)     
		g_JiangHuShiJi_GiftMD	= Get_XParam_INT(1) 
		g_JiangHuShiJi_SvtTime	= Get_XParam_INT(2) 
		JiangHuShiJi_ShowPoint()  
	elseif event == "UPDATE_MISSION_TRACK" then  
		JiangHuShiJi_ShowPoint() 
	end

end

function JiangHuShiJi_OnHiden() 
	g_JiangHuShiJi_Total 	= 0
	g_JiangHuShiJi_CurPage  = 1
	this:Hide()
end

--=========
-- 重置
--=========
function JiangHuShiJi_On_ResetPos()

	JiangHuShiJi_Frame:SetProperty("UnifiedPosition", g_JiangHuShiJi_UnifiedPosition)

end

--=========
-- 装载控件
--=========
function JiangHuShiJi_LoadControl() 
	g_JiangHuShiJi_Ctl[1] = {
		img		= JiangHuShiJi_TextBK1, 
		status 	= JiangHuShiJi_TextBK1_info1, 
		Desc  	= JiangHuShiJi_TextBK1_info3,
		redPoint= JiangHuShiJi_TextBK1_Tips,
		NestImg = JiangHuShiJi_TextBK1_Star,		
		LockImg = JiangHuShiJi_TextBK1_BK,  
	}
	g_JiangHuShiJi_Ctl[2] = {
		img		= JiangHuShiJi_TextBK2, 
		status 	= JiangHuShiJi_TextBK2_info1, 
		Desc  	= JiangHuShiJi_TextBK2_info3,
		redPoint= JiangHuShiJi_TextBK2_Tips,
		NestImg = JiangHuShiJi_TextBK2_Star,  
		LockImg = JiangHuShiJi_TextBK2_BK,  
	}
	g_JiangHuShiJi_Ctl[3] = {
		img		= JiangHuShiJi_TextBK3, 
		status 	= JiangHuShiJi_TextBK3_info1, 
		Desc  	= JiangHuShiJi_TextBK3_info3,
		redPoint= JiangHuShiJi_TextBK3_Tips,
		NestImg = JiangHuShiJi_TextBK3_Star,  
		LockImg = JiangHuShiJi_TextBK3_BK,  
	}
	g_JiangHuShiJi_Ctl[4] = {
		img		= JiangHuShiJi_TextBK4, 
		status 	= JiangHuShiJi_TextBK4_info1, 
		Desc  	= JiangHuShiJi_TextBK4_info3,
		redPoint= JiangHuShiJi_TextBK4_Tips,
		NestImg = JiangHuShiJi_TextBK4_Star,  
		LockImg = JiangHuShiJi_TextBK4_BK,  
	}
end

--=========
-- 打开
--=========
function JiangHuShiJi_Open() 
	local pEndTime = DataPool:GetPlayerMissionData42TIME(2479)
	local dpEndYear= math.floor(pEndTime/100000000)
	local dpEndMon = math.mod(math.floor(pEndTime/1000000),100)
	local dpEndDay =math.mod(math.floor(pEndTime/10000),100) 
	local dpEndHour = math.mod(math.floor(pEndTime/100),100)  
	
	local dexpText 		= ScriptGlobal_Format("#{TSFCL_220210_45}", dpEndYear,dpEndMon,dpEndDay,dpEndHour)
	if JiangHuShiJi_IsExist2099() == 0 then
		JiangHuShiJi_Info:SetText(dexpText)
	else 
		JiangHuShiJi_Info:SetText("#{TSFCL_220210_67}")
	end

	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" then
		return
	end
	g_JiangHuShiJi_Total = table.getn(infotbl)
	 
	for i = 1, g_JiangHuShiJi_PerPageCount do
		g_JiangHuShiJi_Ctl[i].img:Hide()
		g_JiangHuShiJi_Ctl[i].NestImg:Hide() 
		g_JiangHuShiJi_Ctl[i].LockImg:Hide()
		local ncuridx = (g_JiangHuShiJi_CurPage - 1)*g_JiangHuShiJi_PerPageCount + i
		if ncuridx > g_JiangHuShiJi_Total or ncuridx <= 0 then
			continue
		end
		 
		local curDay 	= g_JiangHuShiJi_SvtTime 
		local opentime  = Lua_GetTeSeServerOpenTime(infotbl[ncuridx].FuncID)
		if curDay >= opentime then 
			g_JiangHuShiJi_Ctl[i].status:SetText("#{TSFCL_220210_06}")	 
			g_JiangHuShiJi_Ctl[i].redPoint:Hide()	 
			if 0 == DataPool:Lua_GetBinaryData(g_JiangHuShiJi_red, infotbl[ncuridx].FreeIDX) then
				g_JiangHuShiJi_Ctl[i].redPoint:Show()     
			end
			if infotbl[ncuridx].YuanBaoOrCost == 1 then 
				local exchinfo = Lua_GetTeSeServerCostData(infotbl[ncuridx].FuncID)
				local nCostCur = DataPool:GetPlayerMission_DataRound(727)
				local nExchCur = DataPool:GetPlayerMission_DataRound(726)
				for key, value in pairs(exchinfo) do
					if nCostCur >= value.CostNum and nExchCur >= value.CostNum and 0 == DataPool:Lua_GetBinaryData(DataPool:GetPlayerMission_DataRound(value.MDINDEX), value.MDPos) then
						g_JiangHuShiJi_Ctl[i].redPoint:Show()  
					end
				end
			end	 	
			g_JiangHuShiJi_Ctl[i].NestImg:Hide()
			g_JiangHuShiJi_Ctl[i].LockImg:Hide()
		else			
			local year = math.floor(opentime/10000)
			local month = math.mod(math.floor(opentime/100),100)
			local day   = math.mod(opentime,100)			
			local strtime = ScriptGlobal_Format("#{TSFCL_220210_07}",month,day)
			g_JiangHuShiJi_Ctl[i].status:SetText(strtime)	 
			g_JiangHuShiJi_Ctl[i].redPoint:Hide()	 
			if g_JiangHuShiJi_ShowNextIdx == ncuridx then				
				g_JiangHuShiJi_Ctl[i].NestImg:Show()				
			else				
				g_JiangHuShiJi_Ctl[i].NestImg:Hide()				
			end	
			if year >= 2099 then
				g_JiangHuShiJi_Ctl[i].status:SetText("#{TSFCL_220210_58}")	
			end	
			g_JiangHuShiJi_Ctl[i].LockImg:Show()
		end
		g_JiangHuShiJi_Ctl[i].img:Show()
		g_JiangHuShiJi_Ctl[i].img:SetProperty("Image",infotbl[ncuridx].img); 
		g_JiangHuShiJi_Ctl[i].Desc:SetText(infotbl[ncuridx].Desc) 
	 
	end 
	 
	local totoalpage = 0
	if math.mod(g_JiangHuShiJi_Total,g_JiangHuShiJi_PerPageCount) == 0 then
		totoalpage = math.floor(g_JiangHuShiJi_Total/g_JiangHuShiJi_PerPageCount)
	else
		totoalpage = math.floor(g_JiangHuShiJi_Total/g_JiangHuShiJi_PerPageCount) + 1
	end
	local strpage = ScriptGlobal_Format("#{HYCT_20210629_105}",g_JiangHuShiJi_CurPage,totoalpage) 
	if totoalpage == 1 then
		JiangHuShiJi_UpPage:Hide()
		JiangHuShiJi_DownPage:Hide()
	else
		JiangHuShiJi_UpPage:Show()
		JiangHuShiJi_DownPage:Show()
	end
end 
   
function JiangHuShiJi_ShowPoint()  
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" then
		return
	end
	g_JiangHuShiJi_Total = table.getn(infotbl)
	local curDay 	= g_JiangHuShiJi_SvtTime 
	local isShowPoint = 0 
	for i = 1, g_JiangHuShiJi_Total do 		 
		local opentime  = Lua_GetTeSeServerOpenTime(infotbl[i].FuncID)  
		if curDay >= opentime then  			 
			if 0 == DataPool:Lua_GetBinaryData(g_JiangHuShiJi_red, infotbl[i].FreeIDX) then 
				isShowPoint = 1 	
			end  
			if infotbl[i].YuanBaoOrCost == 1 then 
				local exchinfo = Lua_GetTeSeServerCostData(infotbl[i].FuncID)
				local nCostCur = DataPool:GetPlayerMission_DataRound(727)
				local nExchCur = DataPool:GetPlayerMission_DataRound(726)
				for key, value in pairs(exchinfo) do
					if nCostCur >= value.CostNum and nExchCur >= value.CostNum and 0 == DataPool:Lua_GetBinaryData(DataPool:GetPlayerMission_DataRound(value.MDINDEX), value.MDPos) then
						isShowPoint = 1 	
					end
				end
			end	 	
					
		end 
	end   
	 
	Lua_ShowQuickEnterPointTip(33, isShowPoint)
	if (this:IsVisible()) then
		JiangHuShiJi_Open()
	end
end
function JiangHuShiJi_PageDown()
    if g_JiangHuShiJi_CurPage*g_JiangHuShiJi_PerPageCount < g_JiangHuShiJi_Total then
        g_JiangHuShiJi_CurPage = g_JiangHuShiJi_CurPage + 1
        JiangHuShiJi_Open()
    end
end

function JiangHuShiJi_PageUp()
    if g_JiangHuShiJi_CurPage > 1 then
        g_JiangHuShiJi_CurPage = g_JiangHuShiJi_CurPage - 1
        JiangHuShiJi_Open()
    end
end

function JiangHuShiJi_Click(idx) 
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" then
		return
	end
	local idx = (g_JiangHuShiJi_CurPage - 1)*g_JiangHuShiJi_PerPageCount + idx
	local curDay 	= g_JiangHuShiJi_SvtTime
	local opentime  = Lua_GetTeSeServerOpenTime(infotbl[idx].FuncID) 
	local year = math.floor(opentime/10000)
	local month = math.mod(math.floor(opentime/100),100)
	local day   = math.mod(opentime,100)			
	if year >= 2099 then
		PushDebugMessage("#{TSFCL_230301_11}")
		return
	end
	if opentime > curDay then
		local strtime = ScriptGlobal_Format("#{TSFCL_220210_05}",month,day)
		PushDebugMessage(strtime)
		return
	end 
	if infotbl[idx].YuanBaoOrCost == 0 then
		PushEvent("OPENJIANGSHUJISHI_POPUP", idx) 
	else
		PushEvent("OPENJIANGSHUJISHI_POPUP_TWO", idx) 
	end
	
end

function JiangHuShiJi_GetCurPage()
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" then
		return
	end 
	g_JiangHuShiJi_Total = table.getn(infotbl) 
	g_JiangHuShiJi_ShowNextIdx = -1
	local ncurpage = 1
	for i = 1, table.getn(infotbl) do		
		local curDay 	= g_JiangHuShiJi_SvtTime
		local opentime  = Lua_GetTeSeServerOpenTime(infotbl[i].FuncID)
		if opentime > curDay then
			g_JiangHuShiJi_ShowNextIdx = i
			g_JiangHuShiJi_CurPage = ncurpage 			 
			return 
		end
		if math.mod(i,g_JiangHuShiJi_PerPageCount) == 0 then
			ncurpage = ncurpage + 1
		end
	end
	if g_JiangHuShiJi_ShowNextIdx == -1 then 
		if math.mod(g_JiangHuShiJi_Total,g_JiangHuShiJi_PerPageCount) == 0 then
			g_JiangHuShiJi_CurPage = math.floor(g_JiangHuShiJi_Total/g_JiangHuShiJi_PerPageCount)
		else
			g_JiangHuShiJi_CurPage = math.floor(g_JiangHuShiJi_Total/g_JiangHuShiJi_PerPageCount) + 1
		end
	end			 
end

function JiangHuShiJi_IsExist2099()
	local infotbl = Lua_GetTeSeServerData()
	if type(infotbl) ~= "table" then
		return 0
	end 
	for i = 1, table.getn(infotbl) do		 
		local opentime  = Lua_GetTeSeServerOpenTime(infotbl[i].FuncID)
		if math.floor(opentime/10000) >=2099 then
			return 1
		end
	end
	return 0
end