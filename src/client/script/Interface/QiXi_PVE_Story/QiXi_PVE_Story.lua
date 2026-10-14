-- 七夕副本 过场UI

local g_ui_commonid = 05123803
local g_frame_unifiedposition
local g_animate_absolutepos = {}
--**************UI相关内容的常量************************
local g_alpha_time = 1.0
local g_alpha_time_line = g_alpha_time + 0.3
local g_Animate_time = 1.5
local from_to_alpha = string.format("curve:easeInOutCubic mode:Once duration:%s startx:0 starty:0 endx:1 endy:0",g_alpha_time)
local from_to_alpha_line = string.format("curve:easeInBack mode:Once duration:%s startx:0 starty:0 endx:1 endy:0",g_alpha_time_line)
local animate_str_once = "curve:%s mode:Once duration:%s startx:%s starty:%s endx:%s endy:%s"

-- 每个阶段蝴蝶的飞行轨迹
local from_to_pos_animate = {
	string.format(animate_str_once,"Liner",g_Animate_time,0,0,-112,143),
}
--***************UI相关内容的常量end************************
-- 文字动画UI组
local g_ui_tween_text = {}
-- 按钮动画UI组
local g_ui_tween_btn = {}
-- 普通应用UI
local g_ui_list = {}

local g_ui_ani_max = 1

--*************临时数据******************
-- 当前分页
local g_curpage = 1

-- 当前渐隐播放到啥程度
local g_alpha_playstate = 0

local g_fst_start_time = 0


--*************临时数据end****************


local function cleanup()
	g_alpha_playstate = 0
end

function QiXi_PVE_Story_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function QiXi_PVE_Story_OnLoad()
    g_ui_tween_text = {
        [1] = {
            {title=QiXi_PVE_Story_PageFrame1_Text1,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame1_Text2,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame1_Text3,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame1_Text4,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame1_Text5,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame1_Text6,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame1_Text7,line=nil,},
        },
		[2] = {
            {title= QiXi_PVE_Story_PageFrame2_Text1,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame2_Text2,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame2_Text3,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame2_Text4,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame2_Text5,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame2_Text6,line=nil,},
        },
        [3] = {
            {title= QiXi_PVE_Story_PageFrame3_Text1,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame3_Text2,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame3_Text3,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame3_Text4,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame3_Text5,line=nil,},
        },
        [4] = {
            {title= QiXi_PVE_Story_PageFrame4_Text1,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame4_Text2,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame4_Text3,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame4_Text4,line=nil,},
		    {title= QiXi_PVE_Story_PageFrame4_Text5,line=nil,},
        },
	}
    g_ui_list = {
        --animate = {},
        frame = {
            QiXi_PVE_Story_PageFrame1,
            QiXi_PVE_Story_PageFrame2,
            QiXi_PVE_Story_PageFrame3,
            QiXi_PVE_Story_PageFrame4,
        }
    }
        
    g_ui_tween_btn = {QiXi_PVE_Story_Button1,QiXi_PVE_Story_Button2,QiXi_PVE_Story_Button3,QiXi_PVE_Story_Button4}

    -- 进行初始位置缓存
	g_frame_unifiedposition = QiXi_PVE_Story_Frame:GetProperty("UnifiedPosition")

    -- for i=1, g_ui_ani_max do
	-- 	local item = g_ui_list.animate[i]
	-- 	if item ~= nil then
	-- 		g_animate_absolutepos[i] = item:GetProperty("UnifiedPosition")
	-- 	else
	-- 		g_animate_absolutepos[i] = nil
	-- 	end
	-- end

end


function QiXi_PVE_Story_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_commonid then
        local opt = Get_XParam_INT( 0 )
        if opt == 0 then
            QiXi_PVE_Story_Hide()
        elseif  opt == 1 then
            g_curpage = Get_XParam_INT( 1 )
            if not g_ui_list.frame[g_curpage] then
                return
            end 
            QiXi_PVE_Story_OnShow()
        end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_PVE_Story_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		QiXi_PVE_Story_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
        QiXi_PVE_Story_Hide()
	end
end


function QiXi_PVE_Story_OnShow()
	-- 先重置数据
	cleanup()
	QiXi_PVE_Story_UIReset()

    QiXi_PVE_Story_FadeShowing()

end


-- 还原动画位置和状态
local function uitweenreset()
	-- for i=1, g_ui_ani_max do
	-- 	local item = g_ui_list.animate[i]
	-- 	if item ~= nil then
	-- 		item:SetProperty("UnifiedPosition", g_animate_absolutepos[i])
	-- 	end
	-- end
end

-- 执行tween内容
local function tweenstart(ui, sztype, info, reset)
	if ui == nil then
		return
	end
	if reset == true then
		ui:Tween_Reset(sztype,true)
	end
	ui:Tween_SetInfo(sztype, info)
	ui:Tween_Play(sztype, true, true)
	ui:Show()
end


-- 按钮alpha动画的显隐
local function uibtnshow(idx,isshow)
	for i,v in ipairs(g_ui_tween_btn or {}) do
        if isshow > 0 and i == idx then
            tweenstart(	v, "Alpha", from_to_alpha, true)
            --z:Show()
        else
            v:Hide()
        end
	end
end

-- 对所有UI内容进行还原
function QiXi_PVE_Story_UIReset()
	-- 对文字内容进行隐藏
	for _,v in ipairs(g_ui_tween_text[g_curpage] or {}) do
		v.title:Hide()
		if v.line ~= nil then
			v.line:Hide()
		end
	end

    uibtnshow(1,0)

    for _,v in ipairs(g_ui_list.frame or {}) do
		v:Hide()
	end

    uitweenreset()
end



-- 按钮蝴蝶动画移动
local function uibtn_animateshow(idx)
	-- local item = g_ui_list.animate[idx]
	-- if item ~= nil then
	-- 	tweenstart(item, "Position", from_to_pos_animate[idx], true)
	-- end
end

function QiXi_PVE_Story_TweenPlay()
	SetTimer("QiXi_PVE_Story","QiXi_PVE_Story_OnTweenTimer()", g_alpha_time*1000)
end

function QiXi_PVE_Story_TextTweenPlay(index)
	local count,idx = table.getn(g_ui_tween_text[g_curpage]),index
	if count >= idx and idx > 0 then
		local item = g_ui_tween_text[g_curpage][idx]
		tweenstart(	item.title, "Alpha", from_to_alpha, true)
		if item.line ~= nil then
			tweenstart(	item.line, "Alpha", from_to_alpha_line, true)
		end
	else
		KillTimer("QiXi_PVE_Story_OnTweenTimer()")
		uibtnshow(g_curpage,1)
		-- 蝴蝶飞出来
		uibtn_animateshow(1)
        QiXi_PVE_Story_FadeDisappering()
	end
end

function QiXi_PVE_Story_OnTweenTimer()
    g_alpha_playstate = g_alpha_playstate + 1
		if g_alpha_playstate > g_fst_start_time then
			QiXi_PVE_Story_TextTweenPlay(g_alpha_playstate-g_fst_start_time)
		end
end


function QiXi_PVE_Story_FadeDisappering()
	KillTimer("QiXi_PVE_Story_OnFadeDisappering()")
	QiXi_PVE_Story_Frame:Tween_SetInfo("Alpha", "curve:Liner mode:Once duration:4 startx:1 starty:0 endx:0 endy:0")
	QiXi_PVE_Story_Frame:Tween_Play("Alpha", true, true)
    SetTimer("QiXi_PVE_Story","QiXi_PVE_Story_OnFadeDisappering()", 4100)
end

function QiXi_PVE_Story_OnFadeDisappering()
	KillTimer("QiXi_PVE_Story_OnFadeDisappering()")
	QiXi_PVE_Story_OnClose()
end

function QiXi_PVE_Story_FadeShowing()

	KillTimer("QiXi_PVE_Story_OnFadeShowing()")
	QiXi_PVE_Story_Frame:Tween_SetInfo("Alpha", "curve:Liner mode:Once duration:0.7 startx:0 starty:0 endx:1 endy:0")
	QiXi_PVE_Story_Frame:Tween_Play("Alpha", true, true)
    SetTimer("QiXi_PVE_Story","QiXi_PVE_Story_OnFadeShowing()", 710)
end

function QiXi_PVE_Story_OnFadeShowing()
	KillTimer("QiXi_PVE_Story_OnFadeShowing()")
	this:Show()
    g_ui_list.frame[g_curpage]:Show()
    QiXi_PVE_Story_TweenPlay()
end



function QiXi_PVE_Story_Hide()
	cleanup()
	QiXi_PVE_Story_StopAllTween()
	KillTimer("QiXi_PVE_Story_OnTweenTimer()")
	KillTimer("QiXi_PVE_Story_OnFadeShowing()")
	KillTimer("QiXi_PVE_Story_OnFadeDisappering()")
	this:Hide()
end


-- 停止动画的播放
function QiXi_PVE_Story_StopAllTween()

    for _,v in ipairs(g_ui_tween_text[g_curpage] or {}) do
		if v ~= nil then
			if v.title ~= nil then
				v.title:Tween_Reset("Alpha",true)
			end
			if v.line ~= nil then
				v.line:Tween_Reset("Alpha",true)
			end
		end
	end

    for i,v in ipairs(g_ui_tween_btn or {}) do
		v:Tween_Reset("Alpha",true)
	end

	-- for i=1, g_ui_ani_max do
	-- 	local item = g_ui_list.animate[i]
	-- 	if item ~= nil then
	-- 		item:Tween_Reset("Position",true)
	-- 	end
	-- end
end

function QiXi_PVE_Story_OnClose()
	QiXi_PVE_Story_Hide()
end

function QiXi_PVE_Story_ResetPos()
	QiXi_PVE_Story_Frame:SetProperty("UnifiedPosition", g_frame_unifiedposition)
end