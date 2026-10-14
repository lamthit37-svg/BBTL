-- 2021Q3 预热签到 剧情界面

local g_frame_unifiedposition = nil			-- 分辨率变化跟踪数值

-- 剧情名字包装
local g_crwarmup_storytitle = {
	"#{MPYR_210830_72}","#{MPYR_210830_73}","#{MPYR_210830_74}","#{MPYR_210830_75}","#{MPYR_210830_76}",
	"#{MPYR_210830_77}","#{MPYR_210830_78}","#{MPYR_210830_79}","#{MPYR_210830_80}",
}

local g_crwarmup_story = {
	"#{MPYR_210830_81}","#{MPYR_210830_82}","#{MPYR_210830_83}","#{MPYR_210830_84}","#{MPYR_210830_85}",
	"#{MPYR_210830_86}","#{MPYR_210830_87}","#{MPYR_210830_88}","#{MPYR_210830_89}",
}

function CRWarmUp_Story_PreLoad()
	this:RegisterEvent("OPEN_21Q3ACT_SIGNIN_OTHER")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CRWarmUp_Story_OnLoad()
	g_frame_unifiedposition = CRWarmUp_Story_Frame:GetProperty("UnifiedPosition") 
end

function CRWarmUp_Story_OnEvent(event)
	if event == "OPEN_21Q3ACT_SIGNIN_OTHER" and tonumber(arg0) == 1 then
		CRWarmUp_Story_OnShow(tonumber(arg1))
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		CRWarmUp_Story_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		CRWarmUp_Story_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		CRWarmUp_Story_Close()
	end
end

--===================================================================================
--*******************************显示剧情内容 Start***************************************
--===================================================================================

--=================初始化界面信息==============================
function CRWarmUp_Story_OnShow(nStoryId)
	-- 判定索引是否合法
	local Count = table.getn(g_crwarmup_storytitle)
	if nStoryId > Count or nStoryId < 1 then
		CRWarmUp_Story_Close()
		return
	end

	local szTitle = g_crwarmup_storytitle[nStoryId]
	CRWarmUp_Story_Title:SetText(szTitle)

	Count = table.getn(g_crwarmup_story)
	if nStoryId > Count or nStoryId < 1 then
		return
	end

	local szStory = g_crwarmup_story[nStoryId]
	CRWarmUp_Story_Info:SetText(szStory)
	
	this:Show()
end

function CRWarmUp_Story_Close()
	this:Hide()
end

function CRWarmUp_Story_ResetPos()
	CRWarmUp_Story_Frame:SetProperty("UnifiedPosition", g_frame_unifiedposition)
end
