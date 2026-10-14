-- 雪人大作战，个人榜单界面
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
function Frozen_PVPTopList_PreLoad()
	this:RegisterEvent("XRZPVP_BATTLERANK_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Frozen_PVPTopList_OnLoad()

	g_ui_list = {}
	-- 保存界面的默认相对位置
	g_unifiedposistion = Frozen_PVPTopList_Frame:GetProperty("UnifiedPosition")
end

function Frozen_PVPTopList_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Frozen_PVPTopList_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_PVPTopList_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED")	 then
		Frozen_PVPTopList_Close()
	elseif (event == "XRZPVP_BATTLERANK_SHOW") then
		Frozen_PVPTopList_OnShow()
	end
end

function Frozen_PVPTopList_OnShow()

	local ret = Frozen_PVPTopList_InitUIData()
	if ret > 0 then
		this:Show()
	else
		this:Hide()
	end
end

-- 初始化控件数据
function Frozen_PVPTopList_InitUIData(lastTime)

	local data = XRZPVP:GetBattlePlayerRankInfo("myinfo")
	if data == nil or type(data) ~= "table" then
		this:Hide()
		return -1
	end

	local strKill = ScriptGlobal_Format("#{BXDZ_240918_255}", data.kill)
	Frozen_PVPTopList_My:SetText(strKill)
	
	Frozen_PVPTopList_List:RemoveAllItem()
	
	-- 刷新阵营信息
	local teamCount = XRZPVP:GetBattlePlayerRankInfo("num")
	if (teamCount > 0) then
		local listIndex = 0
		for i=1, teamCount, 1 do
			local playerData = XRZPVP:GetBattlePlayerRankInfo("info", listIndex)
			if playerData ~= nil and type(playerData) == "table" then
				local strName = Frozen_PVPTopList_TransformName(playerData.name, playerData.world)
				local strCamp = Frozen_PVPTopList_GetCampName(playerData.team+1)
				Frozen_PVPTopList_List:AddNewItem("#cfff263"..tostring(listIndex+1), 0, listIndex)
				Frozen_PVPTopList_List:AddNewItem("#cfff263"..strName, 1, listIndex)
				Frozen_PVPTopList_List:AddNewItem("#cfff263"..strCamp, 2, listIndex)
				Frozen_PVPTopList_List:AddNewItem("#cfff263"..tostring(playerData.kill), 3, listIndex)

				listIndex = listIndex + 1
			end
		end
	end
	
	return 1
end

function Frozen_PVPTopList_TransformName(name, zoneid)
	if zoneid < 0 then
		return name
	end

	local retname = name
	if zoneid > 0 then
		local serverName = DataPool:GetServerName( zoneid )
		retname = name.."@"..tostring(serverName)
	end

	return retname
end


function Frozen_PVPTopList_GetCampName(campIndex)
	local data = g_camp_info[campIndex]
	if data == nil then
		return "???"
	end
	
	return data.name
end

--================================================
-- 关闭
--================================================
function Frozen_PVPTopList_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_PVPTopList_ResetPos()
	Frozen_PVPTopList_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end