-- 选人界面
local g_unifiedposistion

function ConfraternityCommander_Name_PreLoad()
	this:RegisterEvent("COMMANDERFLAG_SETSHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("GUILD_SHOW_MEMBERINFO",false)
end

function ConfraternityCommander_Name_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion = ConfraternityCommander_Name_Frame:GetProperty("UnifiedPosition")
end

function ConfraternityCommander_Name_OnEvent(event)

	if ( event == "ADJEST_UI_POS" ) then
		ConfraternityCommander_Name_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		ConfraternityCommander_Name_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED")	 then
		ConfraternityCommander_Name_CloseClicked()
	elseif (event == "GUILD_SHOW_MEMBERINFO")	 then
		ConfraternityCommander_Name_CloseClicked()
	elseif (event == "COMMANDERFLAG_SETSHOW") then
		ConfraternityCommander_Name_OnShow()
	end
end

function ConfraternityCommander_Name_OnShow(selectScnId)
	Guild:PrepareMembersInfomation(1)
	local szName = "#{CZBJ_250512_16}"
	local totalNum = Guild:GetMembersNum(4)
	local i = 0
	while i < totalNum do
		local guildIdx = Guild:GetShowMembersIdx(i)
		local commanderDate = Guild:GetMembersInfo(guildIdx, "CommanderDate")
		if commanderDate ~= nil and commanderDate > 0 then
			szName = Guild:GetMembersInfo(guildIdx, "Name")
			break
		end
		i = i + 1
	end

	
	ConfraternityCommander_Name_Text:SetText(szName)
	this:Show()
end

--================================================
-- 关闭
--================================================
function ConfraternityCommander_Name_CloseClicked()
	this:Hide()
end

function ConfraternityCommander_Name_Cancel_Clicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ConfraternityCommander_Name_ResetPos()
	ConfraternityCommander_Name_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function ConfraternityCommander_Name_Btn_Clicked()
	PushEvent("COMMANDERFLAG_SETLISTSHOW")

	ConfraternityCommander_Name_CloseClicked()
end
