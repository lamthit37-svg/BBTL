-- 选人界面
local g_unifiedposistion
local g_assChiefPos = 8
local g_positionInfo = {
	"#{GCQH_240429_132}",       -- 待批准
	"#{GCQH_240429_133}",       -- 帮众
	"#{GCQH_240429_134}",       -- 精英
	"#{GCQH_240429_135}",       -- 商人
	"#{GCQH_240429_136}",       -- 弘化使
	"#{GCQH_240429_137}",       -- 工务使
	"#{GCQH_240429_138}",       -- 内务使
	"#{GCQH_240429_139}",       -- 副帮主
	"#{GCQH_240429_140}",       -- 帮主
}
local g_ListToMember = {}
local g_levellimit = 85
function ConfraternityCommander_Select_PreLoad()
	this:RegisterEvent("COMMANDERFLAG_SETLISTSHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("GUILD_SHOW_MEMBERINFO",false)

end

function ConfraternityCommander_Select_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion = ConfraternityCommander_Select_Frame:GetProperty("UnifiedPosition")
end

function ConfraternityCommander_Select_OnEvent(event)

	if ( event == "ADJEST_UI_POS" ) then
		ConfraternityCommander_Select_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		ConfraternityCommander_Select_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED")	 then
		ConfraternityCommander_Select_CloseClicked()
	elseif (event == "GUILD_SHOW_MEMBERINFO")	 then
		ConfraternityCommander_Select_CloseClicked()
	elseif (event == "COMMANDERFLAG_SETLISTSHOW") then
		ConfraternityCommander_Select_OnShow()
	end
end

function ConfraternityCommander_Select_OnShow(selectScnId)
	Guild:PrepareMembersInfomation(1)
	ConfraternityCommander_Select_List:RemoveAllItem()
	local szName = ""
	local totalNum = Guild:GetMembersNum(4)
	local i = 0
	local listidx = 0
	while i < totalNum do
		local guildIdx = Guild:GetShowMembersIdx(i)
		local guildpos = Guild:GetMembersInfo(guildIdx, "Position")
		local firstManGuid = Guild:GetMembersInfo(guildIdx, "FirstManGuid")
		local color, strTips = Guild:GetMembersInfo(guildIdx, "ShowColor")
		local szName = Guild:GetMembersInfo(guildIdx, "Name")
		local level = Guild:GetMembersInfo(guildIdx, "Level")
		local commanderDate = Guild:GetMembersInfo(guildIdx, "CommanderDate")
		if firstManGuid == Guild:GetMembersInfo(guildIdx, "GUID") and guildpos == g_assChiefPos then
		--local commanderDate = Guild:GetMembersInfo(guildIdx, "CommanderDate")
		--if commanderDate > 0 then
			ConfraternityCommander_Select_List:AddNewItem("#P"..g_positionInfo[guildpos], 0, listidx)
			ConfraternityCommander_Select_List:AddNewItem("#P"..szName, 1, listidx)
			ConfraternityCommander_Select_List:AddNewItem("#P"..level, 2, listidx)
			if commanderDate ~= nil and commanderDate > 0 then
				ConfraternityCommander_Select_List:AddNewItem("#P".."#{CZBJ_250512_43}", 3, listidx)
			else
				ConfraternityCommander_Select_List:AddNewItem("#P ", 3, listidx)
			end
		else
			ConfraternityCommander_Select_List:AddNewItem(color..g_positionInfo[guildpos], 0, listidx)
			ConfraternityCommander_Select_List:AddNewItem(color..szName, 1, listidx)
			ConfraternityCommander_Select_List:AddNewItem(color..level, 2, listidx)
			if commanderDate ~= nil and commanderDate > 0 then
				ConfraternityCommander_Select_List:AddNewItem(color.."#{CZBJ_250512_43}", 3, listidx)
			else
				ConfraternityCommander_Select_List:AddNewItem(" ", 3, listidx)
			end
		end

		ConfraternityCommander_Select_List:SetRowTooltip(listidx, strTips)
		g_ListToMember[listidx] = guildIdx

		listidx = listidx + 1
		i = i + 1
	end

	
	this:Show()
end

--================================================
-- 关闭
--================================================
function ConfraternityCommander_Select_CloseClicked()
	this:Hide()
end

function ConfraternityCommander_Select_Cancel_Clicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ConfraternityCommander_Select_ResetPos()
	ConfraternityCommander_Select_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function ConfraternityCommander_Select_Btn_Clicked()
	PushEvent("COMMANDERFLAG_SETLISTSHOW")

	ConfraternityCommander_Select_CloseClicked()
end

function ConfraternityCommander_Select_ListSelected()
	local select = ConfraternityCommander_Select_List:GetSelectItem()
	if( -1 == select ) then
		return
	end


end

function ConfraternityCommander_Select_Accept_BtnClick()
	local select = ConfraternityCommander_Select_List:GetSelectItem()
	if select == nil or select == -1 then
		return
	end

	local guildIdx = g_ListToMember[select]
	if guildIdx ~= nil and guildIdx >= 0 then
		local level = Guild:GetMembersInfo(guildIdx, "Level")
		if level < g_levellimit then
			PushDebugMessage("#{CZBJ_250512_39}")
			return
		end

		Guild:ModifyGuildCommander(guildIdx)
	end

	this:Hide()
end