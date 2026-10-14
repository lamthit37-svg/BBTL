local g_OpenType = 0

function Union_Ensure_PreLoad()
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("OPNE_CREATE_RAID_CONFIRM")
end
	
function Union_Ensure_OnLoad()
end

function Union_Ensure_OnEvent(event)
	if (event == "OPEN_WINDOW") then
		if arg0 == "Union_Ensure" then
			Union_Ensure_Clear()
			Union_Ensure_Text1:SetText("#{TDGZ_100809_29}")
			g_OpenType = 1
			this:Show()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Union_Ensure_Clear()
	elseif (event == "OPNE_CREATE_RAID_CONFIRM") then
			Union_Ensure_Clear()
			Union_Ensure_Text1:SetText("#{TDGZ_100809_87}")
			g_OpenType = 2
			this:Show()
	end
end

function Union_Ensure_ConfirmClick()
	if g_OpenType == 1 then
		Raid:ConfirmShowAllSquad()
	elseif g_OpenType == 2 then
	    --windowname是哪儿来的?InterfaceEx.txt配置,实现看UIWindowMng...
	    --当然像此处队伍窗口名字起的非要跟文件名不一致,基本纯属捣乱
		CloseWindow("Team_Frame", true)
		Player:CreateRaidSelf()
	end
	Union_Ensure_Clear()
end

function Union_Ensure_CancelClick()
	Union_Ensure_Clear()
end

function Union_Ensure_Clear()
	g_OpenType = 0
	Union_Ensure_Text1:SetText("")
	this:Hide()
end