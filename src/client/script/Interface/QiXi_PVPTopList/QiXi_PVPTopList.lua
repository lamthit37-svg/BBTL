-- 七夕pvp，击杀排行榜
local g_unifiedposistion

local g_camp_info = 
{
	{name="#{XQPVP_260526_124}",},
	{name="#{XQPVP_260526_125}",},
}
function QiXi_PVPTopList_PreLoad()
	this:RegisterEvent("QIXI_PVP_BATTLERANK_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function QiXi_PVPTopList_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion = QiXi_PVPTopList_Frame:GetProperty("UnifiedPosition")
end

function QiXi_PVPTopList_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		QiXi_PVPTopList_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QiXi_PVPTopList_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED")	 then
		QiXi_PVPTopList_Close()
	elseif (event == "QIXI_PVP_BATTLERANK_SHOW") then
		QiXi_PVPTopList_OnShow()
	end
end

function QiXi_PVPTopList_OnShow()

	local ret = QiXi_PVPTopList_InitUIData()
	if ret > 0 then
		this:Show()
	else
		this:Hide()
	end
end

-- 初始化控件数据
function QiXi_PVPTopList_InitUIData(lastTime)

	local ncount, ntype,nserver,nkillnum,szname = QXPVP:GetBattleMyInfo()
	QiXi_PVPTopList_My:SetText(ScriptGlobal_Format("#{XQPVP_260526_86}", nkillnum))
	QiXi_PVPTopList_List:RemoveAllItem()
	
	-- 刷新阵营信息
	if (ncount > 0) then
		local listIndex = 0
		for i=1, ncount, 1 do
			local ptype,pserver,pkillnum,pszname = QXPVP:GetBattleRankInfo(i)
			if ptype ~= nil and ptype >= 0 then
				local strName = QiXi_PVPTopList_TransformName(pszname, pserver)
				local strCamp = QiXi_PVPTopList_GetCampName(ptype+1)

				QiXi_PVPTopList_List:AddNewItem("#cfff263"..tostring(i), 0, listIndex)
				QiXi_PVPTopList_List:AddNewItem("#cfff263"..strCamp, 1, listIndex)
				QiXi_PVPTopList_List:AddNewItem("#cfff263"..strName, 2, listIndex)
				QiXi_PVPTopList_List:AddNewItem("#cfff263"..tostring(pkillnum), 3, listIndex)
				listIndex = listIndex + 1
			end
		end
	end
	
	return 1
end

function QiXi_PVPTopList_TransformName(name, zoneid)
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


function QiXi_PVPTopList_GetCampName(campIndex)
	local data = g_camp_info[campIndex]
	if data == nil then
		return "???"
	end
	
	return data.name
end

--================================================
-- 关闭
--================================================
function QiXi_PVPTopList_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function QiXi_PVPTopList_ResetPos()
	QiXi_PVPTopList_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end