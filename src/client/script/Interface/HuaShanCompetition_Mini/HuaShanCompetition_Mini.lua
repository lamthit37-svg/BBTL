local g_HuaShanCompetition_Mini_Frame_UnifiedPosition = nil 

function HuaShanCompetition_Mini_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("NEWHUASHAN_SWITCH")
	this:RegisterEvent("NEWHUASHAN_MENPAI_RANK")

end 

-- HuaShanCompetition_MiniBK => TLBB_StaticImageNULL
-- HuaShanCompetition_Mini_DragTitle => TLBB_DragTitle
function HuaShanCompetition_Mini_OnLoad()
	g_HuaShanCompetition_Mini_Frame_UnifiedPosition = HuaShanCompetition_Mini_Frame:GetProperty("UnifiedPosition");
end

function HuaShanCompetition_Mini_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		HuaShanCompetition_Mini_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanCompetition_Mini_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		HuaShanCompetition_Mini_On_Hide()
	elseif(event == "NEWHUASHAN_MENPAI_RANK") then
		local rankdata = DataPool:GetNewHuaShanMenPaiRank()
		local index = 1
		for i=1,16 do
			local info = rankdata.m_Data[i]
			if info.nMenpaiid == 9 then
			
			else
				--自己的门派
				local menpai = Player:GetData("MEMPAI")
				if menpai ==  info.nMenpaiid then
					HuaShanCompetition_Mini_Count:SetText(ScriptGlobal_Format("#{HSLX_230720_54}",info.nScore))
					HuaShanCompetition_Mini_Rank:SetText(ScriptGlobal_Format("#{HSLX_230720_55}",index))
				end

				index = index+1
			end
		end		

		HuaShanCompetition_Mini_CountdownInfo_Time:Show()
		if rankdata.m_State == 1 then
			HuaShanCompetition_Mini_CountdownInfo:SetText("#{HSLX_230720_56}")
			HuaShanCompetition_Mini_CountdownInfo_Time:SetProperty("Timer",tostring(30-rankdata.m_Tick))
		elseif rankdata.m_State == 2 then
			HuaShanCompetition_Mini_CountdownInfo:SetText("#{HSLX_230720_57}")
			HuaShanCompetition_Mini_CountdownInfo_Time:SetProperty("Timer",tostring(1200-rankdata.m_Tick))
		else 
			HuaShanCompetition_Mini_CountdownInfo:SetText("#{HSLX_230720_58}")
			HuaShanCompetition_Mini_CountdownInfo_Time:Hide()
		end

		if rankdata.m_State == 3 then
			HuaShanCompetition_Mini_CountdownInfo_TimeFinish:Show()
			HuaShanCompetition_Mini_CountdownIcon:Hide()
			HuaShanCompetition_Mini_CountdownInfo:Hide()
			HuaShanCompetition_Mini_CountdownInfo_Time:Hide()
		else
			HuaShanCompetition_Mini_CountdownInfo_TimeFinish:Hide()
			HuaShanCompetition_Mini_CountdownIcon:Show()
			HuaShanCompetition_Mini_CountdownInfo:Show()
			HuaShanCompetition_Mini_CountdownInfo_Time:Show()
		end
		if IsWindowShow("HuaShanCompetition_ZhanKuang") == false then
			this:Show()
		end

	elseif( event == "NEWHUASHAN_SWITCH") then
		if tonumber(arg0) == 1 then
			this:Show()
		else
			this:Hide()
		end
		
	end
end


function HuaShanCompetition_Mini_Help_Clicked()
	PushEvent("CCSHOP_HELP",202)
end

function HuaShanCompetition_Mini_Small_Clicked()
	PushEvent("NEWHUASHAN_SWITCH",0)
end

function HuaShanCompetition_Mini_On_ResetPos()
	HuaShanCompetition_Mini_Frame:SetProperty("UnifiedPosition", g_HuaShanCompetition_Mini_Frame_UnifiedPosition)
end

function HuaShanCompetition_Mini_On_Hide()
	this:Hide()
end

