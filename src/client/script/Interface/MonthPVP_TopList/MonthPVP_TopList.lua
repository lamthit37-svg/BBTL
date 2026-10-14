-- !!!reloadscript =MonthPVP_TopList
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local g_MonthPVP_TopList_StrTeamName =
{
	[1] = {str = "#{LLKC_240517_125}"},
	[2] = {str = "#{LLKC_240517_126}"},
	[3] = {str = "#{LLKC_240517_127}"},
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function MonthPVP_TopList_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function MonthPVP_TopList_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= MonthPVP_TopList_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= MonthPVP_TopList_Frame:GetProperty("UnifiedYPosition");
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MonthPVP_TopList_ResetPos()
	MonthPVP_TopList_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	MonthPVP_TopList_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function MonthPVP_TopList_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 82003001) then
		local nParamSTR0 = Get_XParam_STR(0)
		local nPlayerInfo = 
		{
			[1] = {nName="",nZoneWorldId=-1,nScore=0,nTeam=0},
			[2] = {nName="",nZoneWorldId=-1,nScore=0,nTeam=0},
			[3] = {nName="",nZoneWorldId=-1,nScore=0,nTeam=0},
			[4] = {nName="",nZoneWorldId=-1,nScore=0,nTeam=0},
			[5] = {nName="",nZoneWorldId=-1,nScore=0,nTeam=0},
		}

		for i=0,4 do
			nPlayerInfo[i+1].nName = Get_XParam_STR(i+1) --1,2,3,4,5
			nPlayerInfo[i+1].nZoneWorldId = Get_XParam_INT(3*i) --0,3,6,9,12
			nPlayerInfo[i+1].nScore = Get_XParam_INT(3*i+1)--1,4,7,10,13
			nPlayerInfo[i+1].nTeam = Get_XParam_INT(3*i+2)--2,5,8,11,14
		end

		local nKillNum = Get_XParam_INT(15)

		if nParamSTR0 == "Open" then
			MonthPVP_TopList_Show()
			MonthPVP_TopList_Update(nPlayerInfo,nKillNum)
		elseif nParamSTR0 == "Updata" then
			if (this:IsVisible()) then
				MonthPVP_TopList_Update(nPlayerInfo,nKillNum)
				return
			end
		end
	elseif event=="HIDE_ON_SCENE_TRANSED" or event=="SCENE_TRANSED" or event=="PLAYER_LEAVE_WORLD" then
		MonthPVP_TopList_Hide()
	end

	if this:IsVisible() then
        if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
			MonthPVP_TopList_ResetPos()
        end
	end
end

--显示UI
function MonthPVP_TopList_Show()
	MonthPVP_TopList_ClearData()
	this:Show()
end

--隐藏UI
function MonthPVP_TopList_Hide()
	MonthPVP_TopList_ClearData()
	this:Hide()
end

--清除数据
function MonthPVP_TopList_ClearData()

end

--更新
function MonthPVP_TopList_Update(nPlayerInfo,nKillNum)
	MonthPVP_TopList_List:RemoveAllItem()

	local j = 0
	for i=1,5 do
		if nPlayerInfo[i].nName ~= "" then
			MonthPVP_TopList_List:AddNewItem(tostring(j+1), 0, j) --排名
			
			local strName = ""
			if nPlayerInfo[i].nZoneWorldId ~=0 and nPlayerInfo[i].nZoneWorldId ~= -1 then
				strName = DataPool:GetServerName( nPlayerInfo[i].nZoneWorldId )
			end
			MonthPVP_TopList_List:AddNewItem(nPlayerInfo[i].nName.."@"..strName, 1, j) --姓名
			MonthPVP_TopList_List:AddNewItem(g_MonthPVP_TopList_StrTeamName[nPlayerInfo[i].nTeam].str, 2, j) --阵营
			MonthPVP_TopList_List:AddNewItem(tostring(nPlayerInfo[i].nScore), 3, j) --击杀数
			j = j + 1
		end
	end

	MonthPVP_TopList_My:SetText(ScriptGlobal_Format("#{LLKC_240517_146}",nKillNum))
end

function MonthPVP_TopList_Close()
	MonthPVP_TopList_Hide()
end