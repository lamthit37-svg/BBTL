local g_HuaShanCompetition_ZhanKuang_Frame_UnifiedPosition = nil 

local g_HuaShanCompetition_ZhanKuang_RankList = {}
--滚动条的位置
local g_HuaShan_Position_Scroll = 0;
function HuaShanCompetition_ZhanKuang_PreLoad()

	-- 游戏窗口尺寸发生了变化

	this:RegisterEvent("NEWHUASHAN_MENPAI_RANK")
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("NEWHUASHAN_SWITCH")

end 

-- HuaShanCompetition_ZhanKuang_Frame_BK => TLBB_StaticImageNULL
-- HuaShanCompetition_ZhanKuang_Progress_Client => DefaultWindow
function HuaShanCompetition_ZhanKuang_OnLoad()
	g_HuaShanCompetition_ZhanKuang_Frame_UnifiedPosition = HuaShanCompetition_ZhanKuang_Frame:GetProperty("UnifiedPosition");
end

function HuaShanCompetition_ZhanKuang_OnEvent(event)


	if event == "NEWHUASHAN_MENPAI_RANK" then
		HuaShanCompetition_ZhanKuang_Create()
		if IsWindowShow("HuaShanCompetition_Mini") == false then
			this:Show()
		end
	elseif event == "NEWHUASHAN_SWITCH" then
		if tonumber(arg0) == 0 then
			this:Show()
		else
			this:Hide()
		end

	elseif(event == "ADJEST_UI_POS") then
		HuaShanCompetition_ZhanKuang_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanCompetition_ZhanKuang_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		HuaShanCompetition_ZhanKuang_On_Hide()
	end
end


function HuaShanCompetition_ZhanKuang_GetRank(bar)
	return bar:GetSubItem("HuaShanCompetition_ZhanKuang_TopList_AItem_Rank")
end

function HuaShanCompetition_ZhanKuang_GetMenpai(bar)
	return bar:GetSubItem("HuaShanCompetition_ZhanKuang_TopList_AItem_Name")
end

function HuaShanCompetition_ZhanKuang_GetScore(bar)
	return bar:GetSubItem("HuaShanCompetition_ZhanKuang_TopList_AItem_AllScore")
end


function HuaShanCompetition_ZhanKuang_Create()
	g_HuaShan_Position_Scroll = 0
	g_HuaShan_Position_Scroll = HuaShanCompetition_ZhanKuang_TopList_ListFrame:GetScrollPosition()	--保存上一次滚动条位置

	local list = HuaShanCompetition_ZhanKuang_TopList_ListFrame;
	list:Clear()

	for i=1,15 do 
		local bar  = list:AddChild("HuaShanCompetition_ZhanKuang_TopList_AItem")
		g_HuaShanCompetition_ZhanKuang_RankList[i] = bar;
	end

	local rankdata = DataPool:GetNewHuaShanMenPaiRank()
	local index = 1
	for i=1,16 do
		if g_HuaShanCompetition_ZhanKuang_RankList[index] == nil then
			
		else

			local info = rankdata.m_Data[i]
			if info.nMenpaiid == 9 then
			
			else
				--自己的门派
				local menpai = Player:GetData("MEMPAI")
				if menpai ==  info.nMenpaiid then

					HuaShanCompetition_ZhanKuang_MenpaiInfo_Score:SetText(info.nScore)
					HuaShanCompetition_ZhanKuang_MenpaiInfo_Rank:SetText(index)
					HuaShanCompetition_ZhanKuang_MenpaiInfo_Name:SetText(GetMenpaiByID(info.nMenpaiid))
					HuaShanCompetition_ZhanKuang_PersonalInfo_Score:SetText(ScriptGlobal_Format("#{HSLX_230720_69}",rankdata.m_SelfScore))
					HuaShanCompetition_ZhanKuang_PersonalInfo_Rank:SetText(ScriptGlobal_Format("#{HSLX_230720_86}",rankdata.m_SelfRank))
				end

				HuaShanCompetition_ZhanKuang_GetRank(g_HuaShanCompetition_ZhanKuang_RankList[index]):SetText(index)
				HuaShanCompetition_ZhanKuang_GetMenpai(g_HuaShanCompetition_ZhanKuang_RankList[index]):SetText(GetMenpaiByID(info.nMenpaiid))
				HuaShanCompetition_ZhanKuang_GetScore(g_HuaShanCompetition_ZhanKuang_RankList[index]):SetText(info.nScore)
				index = index+1
			end
		end
	end

	list:SetScrollPosition(g_HuaShan_Position_Scroll)
	--PushDebugMessage("rankdata.m_State="..rankdata.m_State)
	HuaShanCompetition_ZhanKuang_CountdownInfo_Time:Show()
	if rankdata.m_State == 1 then
		HuaShanCompetition_ZhanKuang_CountdownInfo:SetText("#{HSLX_230720_56}")
		HuaShanCompetition_ZhanKuang_CountdownInfo_Time:SetProperty("Timer",tostring(30-rankdata.m_Tick))
	elseif rankdata.m_State == 2 then
		HuaShanCompetition_ZhanKuang_CountdownInfo:SetText("#{HSLX_230720_57}")
		HuaShanCompetition_ZhanKuang_CountdownInfo_Time:SetProperty("Timer",tostring(1200-rankdata.m_Tick))
	else 
		HuaShanCompetition_ZhanKuang_CountdownInfo:SetText("#{HSLX_230720_58}")
		HuaShanCompetition_ZhanKuang_CountdownInfo_Time:Hide()
	end

	if rankdata.m_State == 3 then
		HuaShanCompetition_ZhanKuang_CountdownInfo_TimeFinish:Show()
		HuaShanCompetition_ZhanKuang_CountdownIcon:Hide()
		HuaShanCompetition_ZhanKuang_CountdownInfo:Hide()
		HuaShanCompetition_ZhanKuang_CountdownInfo_Time:Hide()
	else
		HuaShanCompetition_ZhanKuang_CountdownInfo_TimeFinish:Hide()
		HuaShanCompetition_ZhanKuang_CountdownIcon:Show()
		HuaShanCompetition_ZhanKuang_CountdownInfo:Show()
		HuaShanCompetition_ZhanKuang_CountdownInfo_Time:Show()
	end




end

function HuaShanCompetition_ZhanKuang_Help_Clicked()
	PushEvent("CCSHOP_HELP",202)
end

function HuaShanCompetition_ZhanKuang_AskGeRen()

	AskHuaShanGeren()
end

function HuaShanCompetition_ZhanKuang_On_ResetPos()
	HuaShanCompetition_ZhanKuang_Frame:SetProperty("UnifiedPosition", g_HuaShanCompetition_ZhanKuang_Frame_UnifiedPosition)
end

function HuaShanCompetition_ZhanKuang_On_Hide()
	g_HuaShan_Position_Scroll = 0
	this:Hide()
end

function HuaShanCompetition_ZhanKuang_OnClosed_Clicked()
	PushEvent("NEWHUASHAN_SWITCH",1)
end