-- 战况查询

local g_unifiedposistion
local g_TargetId = -1
local g_teamcnt = 0
local g_szType = ""
local g_typeName	= {
	["qualify"] = {
		title = "#{WCBZ_180128_180}",
		desc = "#{WCBZ_180128_181}",
		btnshow = 1,
		trans = 0,						-- 这个地方需要转换名字
	},

	["promote"] = {
		title = "#{WCBZ_220809_13}",
		desc = "#{WCBZ_220809_14}",
		btnshow = 1,
		trans = 1,
	},
}

function ZBS_ShowStateOne_PreLoad()
	this:RegisterEvent("ZBS_PROMOTE_INFO_SHOW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function ZBS_ShowStateOne_OnLoad()
	g_unifiedposistion	= ZBS_ShowStateOne_Frame:GetProperty("UnifiedPosition")
end

function ZBS_ShowStateOne_OnEvent(event)
	if event == "ZBS_PROMOTE_INFO_SHOW" then
		ZBS_ShowStateOne_OnShow(tonumber(arg0),tonumber(arg1),arg2)
	elseif event == "ADJEST_UI_POS" then
		ZBS_ShowStateOne_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZBS_ShowStateOne_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ZBS_ShowStateOne_CloseClicked()
	end
end

function ZBS_ShowStateOne_OnShow(cnt, targetId, sztype)
	if targetId > 0 then
		g_TargetId = DataPool : GetNPCIDByServerID( targetId )
		this:CareObject( g_TargetId, 1, "ZBS_ShowStateOne" )
	end

	g_teamcnt = cnt

	ZBS_ShowStateOne_OtherUIShow(sztype)
	ZBS_ShowStateOne_UpdateList()
	
	this:Show()
end

function ZBS_ShowStateOne_OtherUIShow(sztype)
	g_szType = sztype
	if g_typeName[g_szType] ~= nil then
		ZBS_ShowStateOne_DragTitle:SetText(g_typeName[g_szType].title)
		ZBS_ShowStateOne_ExplainText:SetText(g_typeName[g_szType].desc)
	end
end

function ZBS_ShowStateOne_UpdateList()

    ZBS_ShowStateOne_ResetControl()
    
	local cnt = 0
	for i = 0, g_teamcnt-1 do
		local teamid, teamname, teamleadername, zoneid = ZBS:GetTeamProtomeInfo(i)
	    if teamid ~= nil  and teamid > 0 then
			ZBS_ShowStateOne_ListInfo:AddNewItem(tostring(cnt+1), 0, cnt)
    		ZBS_ShowStateOne_ListInfo:AddNewItem(ZBS_ShowStateOne_TransformName(teamname,zoneid), 1, cnt)
    		ZBS_ShowStateOne_ListInfo:AddNewItem(teamleadername, 2, cnt)
    		ZBS_ShowStateOne_ListInfo:AddNewItem("#{WCBZ_180128_188}", 3, cnt)
			cnt = cnt + 1
        end
	end

end

function ZBS_ShowStateOne_TransformName(name, zoneid)
	if zoneid < 0 then
		return name
	end

	local retname = name
	if g_typeName[g_szType] ~= nil then
		-- 是否需要转换名字
		if g_typeName[g_szType].trans > 0 then
			local selfzoneid = DataPool:GetSelfZoneWorldID()
			if selfzoneid ~= zoneid then
				local serverName = DataPool:GetServerName( zoneid )
				retname = name.."@"..tostring(serverName)
			end
		end
	end

	return retname
end

function ZBS_ShowStateOne_ResetControl()
	ZBS_ShowStateOne_ListInfo:RemoveAllItem()

	if g_szType == "" or g_typeName[g_szType] == nil or g_typeName[g_szType].btnshow < 1 then
		ZBS_ShowStateOne_TeamInfo:Hide()
	else
		ZBS_ShowStateOne_TeamInfo:Disable()
		ZBS_ShowStateOne_TeamInfo:Show()
	end
end

function ZBS_ShowStateOne_ListInfo_On_SelectionChanged()
	if g_szType == "" or g_typeName[g_szType] == nil or g_typeName[g_szType].btnshow < 1 then
		return
	else
		ZBS_ShowStateOne_TeamInfo:Enable()
	end
end

function ZBS_ShowStateOne_TeamInfo_Clicked()
	local index = ZBS_ShowStateOne_ListInfo:GetSelectItem()
	if index < 0 then
		return
	end

	local trans = 0
	if g_typeName[g_szType] ~= nil then
		trans = g_typeName[g_szType].trans
	end
	
	PushEvent("ZBS_VIEWTEAMINFO_SHOW", index, trans)
end

function ZBS_ShowStateOne_YXSJS_Clicked()
end


function ZBS_ShowStateOne_CloseClicked()
	if g_TargetId ~= -1 then
		this:CareObject( g_TargetId, 0, "ZBS_ShowStateOne" )
		g_TargetId = -1
	end
	CloseWindow("ZBS_TeamInfo",true)
    this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function ZBS_ShowStateOne_ResetPos()
	ZBS_ShowStateOne_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end