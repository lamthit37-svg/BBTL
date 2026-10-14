--ValentineAlbum_Memorial

local g_ValentineAlbum_Memorial_Frame_UnifiedPosition


local g_ValentineAlbum_Memorial_Locked = {}
local g_ValentineAlbum_Memorial_FinishImage = {}
local g_ValentineAlbum_Memorial_Page = {}

local g_ValentineAlbum_Memorial_ShowMissionInfo = {}

local g_CurPage = 0
local g_IsBind = 0
local g_BindPartnerName = ""


function ValentineAlbum_Memorial_PreLoad()
    this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function ValentineAlbum_Memorial_OnLoad()

	for i = 1, 12 do
		g_ValentineAlbum_Memorial_Locked[i] = "ValentineAlbum_Memorial_TaskLocked"..i
		g_ValentineAlbum_Memorial_FinishImage[i] = "ValentineAlbum_Memorial_TaskFinished"..i
	end
	
	for i = 1, 12 do
		g_ValentineAlbum_Memorial_ShowMissionInfo[i] = {
			locked = _G[g_ValentineAlbum_Memorial_Locked[i]],
			finish = _G[g_ValentineAlbum_Memorial_FinishImage[i]],
		}
	end
	
	g_ValentineAlbum_Memorial_Page[1] = ValentineAlbum_Memorial_Page1
	g_ValentineAlbum_Memorial_Page[2] = ValentineAlbum_Memorial_Page2
	g_ValentineAlbum_Memorial_Page[3] = ValentineAlbum_Memorial_Page3
	g_ValentineAlbum_Memorial_Page[4] = ValentineAlbum_Memorial_Page4
	
    g_ValentineAlbum_Memorial_Frame_UnifiedPosition = ValentineAlbum_Memorial_Frame:GetProperty("UnifiedPosition")

end

function ValentineAlbum_Memorial_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		ValentineAlbum_Memorial_Close()

	elseif (event == "ADJEST_UI_POS" ) then
		ValentineAlbum_Memorial_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ValentineAlbum_Memorial_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 99835801) then
		local operator = Get_XParam_INT( 0 )
		g_BindPartnerName = Get_XParam_STR(0)

		if operator == 1 then
			g_CurPage = 1
			ValentineAlbum_Memorial_Update()
		elseif operator == 2 then
			if this:IsVisible() then
				ValentineAlbum_Memorial_Update()
			end
		end

	end
end

function ValentineAlbum_Memorial_Update()

	ValentineAlbum_Memorial_Info:SetText(ScriptGlobal_Format("#{QRJJN_221118_165}", Player:GetName(),g_BindPartnerName))
	ValentineAlbum_Memorial_PageUpdate(g_CurPage)

	this:Show()
end

function ValentineAlbum_Memorial_PageUpdate(nPage)
	if nPage < 1 or nPage > 4 then
		return
	end
	
	--上下页
	ValentineAlbum_Memorial_LeftArrow:Enable()
	ValentineAlbum_Memorial_RightArrow:Enable()
	if nPage <= 1 then
		ValentineAlbum_Memorial_LeftArrow:Disable()
	elseif nPage >= 4 then
		ValentineAlbum_Memorial_RightArrow:Disable()
	end
	
	for i = 1, 4 do
		if nPage == i then
			g_ValentineAlbum_Memorial_Page[i]:Show()
		else
			g_ValentineAlbum_Memorial_Page[i]:Hide()
		end
	end
	
end

--查看详情
function ValentineAlbum_Memorial_TaskDetailsClicked(index)
	if index < 1 or index > 12 then
		return
	end
	
	PushEvent("UI_COMMAND", 99835607, 1, index, g_BindPartnerName)	
end

--上一页
function ValentineAlbum_Memorial_PreClick()
	if g_CurPage <= 1 or g_CurPage > 4 then
		return
	end
	
	g_CurPage = g_CurPage-1
	ValentineAlbum_Memorial_PageUpdate(g_CurPage)
end

--下一页
function ValentineAlbum_Memorial_NextClick()
	if g_CurPage < 1 or g_CurPage >= 4 then
		return
	end
	
	g_CurPage = g_CurPage+1
	ValentineAlbum_Memorial_PageUpdate(g_CurPage)
end


--关闭
function ValentineAlbum_Memorial_Close()
	this:Hide()
end

function ValentineAlbum_Memorial_On_ResetPos()
    ValentineAlbum_Memorial_Frame:SetProperty("UnifiedPosition", g_ValentineAlbum_Memorial_Frame_UnifiedPosition)
end
