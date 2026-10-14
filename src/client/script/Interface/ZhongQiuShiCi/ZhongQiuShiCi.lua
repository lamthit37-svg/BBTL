-- 2017中秋应景活动 中秋诗词 2017-9-8 lishilong
-- ID 1115
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local npcObjId = -1
local g_ZhongQiuShiCi_Frame_UnifiedPosition

-- 操作类型 查看1 激活2 图鉴诗3 图鉴词4
local g_OpType 				= 1
-- 激活数量
local g_nActivatedNum 		= 0

-- 最大激活诗词数量
local g_MAX_ActivatedNum		= 12
-- 最大激活诗数量
local g_MAX_ActivatedNumPoem	= 4

-- 诗显示相关
-- local g_ShiShowInfo = {
    -- [1] = { ImageN ="set:ZhongQiushi image:Shi1_1" , ImageY = "set:ZhongQiushi image:Shi1_2" },
    -- [2] = { ImageN ="set:ZhongQiushi image:Shi2_1" , ImageY = "set:ZhongQiushi image:Shi2_2" },
    -- [3] = { ImageN ="set:ZhongQiushi image:Shi3_1" , ImageY = "set:ZhongQiushi image:Shi3_2" },
    -- [4] = { ImageN ="set:ZhongQiushi image:Shi4_1" , ImageY = "set:ZhongQiushi image:Shi4_2" },
-- }

-- 诗的显示控件
local g_ShiShowControl = {}
-- 诗的Animate控件
local g_ShiAnimateControl = {}

-- 词显示相关
-- local g_CiShowInfo = {
    -- [1] = { ImageN ="set:ZhongQiuci image:Ci1_1" , ImageY = "set:ZhongQiuci image:Ci1_2" },
    -- [2] = { ImageN ="set:ZhongQiuci image:Ci2_1" , ImageY = "set:ZhongQiuci image:Ci2_2" },
    -- [3] = { ImageN ="set:ZhongQiuci image:Ci3_1" , ImageY = "set:ZhongQiuci image:Ci3_2" },
    -- [4] = { ImageN ="set:ZhongQiuci image:Ci4_1" , ImageY = "set:ZhongQiuci image:Ci4_2" },
	-- [5] = { ImageN ="set:ZhongQiuci1 image:Ci5_1" , ImageY = "set:ZhongQiuci1 image:Ci5_2" },
    -- [6] = { ImageN ="set:ZhongQiuci1 image:Ci6_1" , ImageY = "set:ZhongQiuci1 image:Ci6_2" },
    -- [7] = { ImageN ="set:ZhongQiuci1 image:Ci7_1" , ImageY = "set:ZhongQiuci1 image:Ci7_2" },
    -- [8] = { ImageN ="set:ZhongQiuci1 image:Ci8_1" , ImageY = "set:ZhongQiuci1 image:Ci8_2" },
-- }
-- 词的显示控件
local g_CiShowControl = {}
-- 词的Animate控件
local g_CiAnimateControl = {}

-- 动画播放时间 ms
local g_nTimerElapse 	= 1000 * 2
-- Timer执行次数
local g_nTimerTick		= 0

--=========================================================
-- PreLoad
--=========================================================
function ZhongQiuShiCi_PreLoad()
	this : RegisterEvent("UI_COMMAND")
	--this : RegisterEvent("OBJECT_CARED_EVENT")
	this : RegisterEvent("HIDE_ON_SCENE_TRANSED")
	this : RegisterEvent("ADJEST_UI_POS")
	this : RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function ZhongQiuShiCi_OnLoad()
	g_ZhongQiuShiCi_Frame_UnifiedPosition = ZhongQiuShiCi_Frame:GetProperty("UnifiedPosition")
	g_ShiShowControl[1] = ZhongQiuShiCi_Shi_Sentence1
	g_ShiShowControl[2] = ZhongQiuShiCi_Shi_Sentence2
	g_ShiShowControl[3] = ZhongQiuShiCi_Shi_Sentence3
	g_ShiShowControl[4] = ZhongQiuShiCi_Shi_Sentence4
	
	g_ShiAnimateControl[1] = ZhongQiuShiCi_Shi_Sentence1_Animate
	g_ShiAnimateControl[2] = ZhongQiuShiCi_Shi_Sentence2_Animate
	g_ShiAnimateControl[3] = ZhongQiuShiCi_Shi_Sentence3_Animate
	g_ShiAnimateControl[4] = ZhongQiuShiCi_Shi_Sentence4_Animate
	
	g_CiShowControl[1] = ZhongQiuShiCi_Ci_Sentence1
	g_CiShowControl[2] = ZhongQiuShiCi_Ci_Sentence2
	g_CiShowControl[3] = ZhongQiuShiCi_Ci_Sentence3
	g_CiShowControl[4] = ZhongQiuShiCi_Ci_Sentence4
	g_CiShowControl[5] = ZhongQiuShiCi_Ci_Sentence5
	g_CiShowControl[6] = ZhongQiuShiCi_Ci_Sentence6
	g_CiShowControl[7] = ZhongQiuShiCi_Ci_Sentence7
	g_CiShowControl[8] = ZhongQiuShiCi_Ci_Sentence8
	
	g_CiAnimateControl[1] = ZhongQiuShiCi_Ci_Sentence1_Animate
	g_CiAnimateControl[2] = ZhongQiuShiCi_Ci_Sentence2_Animate
	g_CiAnimateControl[3] = ZhongQiuShiCi_Ci_Sentence3_Animate
	g_CiAnimateControl[4] = ZhongQiuShiCi_Ci_Sentence4_Animate
	g_CiAnimateControl[5] = ZhongQiuShiCi_Ci_Sentence5_Animate
	g_CiAnimateControl[6] = ZhongQiuShiCi_Ci_Sentence6_Animate
	g_CiAnimateControl[7] = ZhongQiuShiCi_Ci_Sentence7_Animate
	g_CiAnimateControl[8] = ZhongQiuShiCi_Ci_Sentence8_Animate
end

--=========================================================
-- OnEvent
--=========================================================
function ZhongQiuShiCi_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 920170916 ) then
		-- 客户端调用 打开UI 操作类型 查看1 激活2 图鉴诗3 图鉴词4
		-- 参数0 类型；参数1 激活数量；参数2 targetId 暂时不用
		g_OpType 			= Get_XParam_INT(0)
		g_nActivatedNum 	= Get_XParam_INT(1)
		
		if g_OpType < 1 or g_OpType > 4 then
			return
		end
		
		if g_nActivatedNum < 0 then
			g_nActivatedNum = 0
		end
		
		if g_nActivatedNum > g_MAX_ActivatedNum then
			g_nActivatedNum = g_MAX_ActivatedNum
		end
		
		-- 显示界面
		this:Show()
		ZhongQiuShiCi_Update()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		-- 关闭界面
		ZhongQiuShiCi_OnClosed()
	
	elseif (event == "ADJEST_UI_POS" ) then
		ZhongQiuShiCi_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZhongQiuShiCi_Frame_On_ResetPos()
		
	end
end

--=========================================================
-- 关闭界面：脚本各种关闭逻辑调用n次 点击关闭界面调用一次
--=========================================================
function ZhongQiuShiCi_OnClosed()
	-- 数据清空	
	this:Hide()
end

--=========================================================
-- 界面更新
--=========================================================
function ZhongQiuShiCi_Update()	
	if g_OpType < 1 or g_OpType > 4 then
		ZhongQiuShiCi_OnClosed()
	end
	
	-- 清一下
	ZhongQiuShiCi_ClearShow()	
	
	-- 查看和激活逻辑通用
	if 1 == g_OpType or 2 == g_OpType then
		--ZhongQiuShiCi_Shi_Button : Show()
		--ZhongQiuShiCi_Ci_Button : Show()
		
		-- 显示按钮 总按钮，合成一个了，名字起的比较随意，应该叫做ZhongQiuShiCi_Button
		ZhongQiuShiCi_Ci_Button : Show()
		
		if g_nActivatedNum <= g_MAX_ActivatedNumPoem then
			-- 显示诗mask
			ZhongQiuShiCi_ShowShi(g_nActivatedNum)
			-- 显示切换按钮
			ZhongQiuShiCi_Ci_Pick : SetCheck(0)
			ZhongQiuShiCi_Shi_Pick : SetCheck(1)			
		else
			-- 显示词mask
			ZhongQiuShiCi_ShowCi(g_nActivatedNum - g_MAX_ActivatedNumPoem)
			-- 显示切换按钮
			ZhongQiuShiCi_Ci_Pick : SetCheck(1)
			ZhongQiuShiCi_Shi_Pick : SetCheck(0)
		end
		

	end
	
	-- 激活逻辑播放动画
	-- if 2 == g_OpType then
		-- if g_nActivatedNum <= g_MAX_ActivatedNumPoem then
			--诗
			-- g_ShiAnimateControl[g_nActivatedNum] : Play(true)
		-- else
			--词
			-- g_CiAnimateControl[g_nActivatedNum - g_MAX_ActivatedNumPoem] : Play(true)
		-- end
		
		-- g_nTimerTick = 0
		-- SetTimer("ZhongQiuShiCi", "ZhongQiuShiCi_TimerProc()", g_nTimerElapse)
	-- end
	
	-- 道具诗打开页面
	if 3 == g_OpType then
		ZhongQiuShiCi_ShowShi(4)
		-- 显示赠与词条
		--ZhongQiuShiCi_Shi_Explain : Show()
		--local strMsg = ScriptGlobal_Format("#{ZQYJ_170906_91}", Player:GetName())
		--ZhongQiuShiCi_Shi_ExplainText : SetText(strMsg)
		
		-- 隐藏进度条
		ZhongQiuShiCi_Shi_Jihuo : Hide()
		ZhongQiuShiCi_Ci_Jihuo : Hide()
	end
	
	-- 道具词打开页面 
	if 4 == g_OpType then
		ZhongQiuShiCi_ShowCi(8)
		-- 显示赠与词条
		--ZhongQiuShiCi_Ci_Explain : Show()
		--local strMsg = ScriptGlobal_Format("#{ZQYJ_170906_91}", Player:GetName())
		--ZhongQiuShiCi_Ci_ExplainText : SetText(strMsg)
		
		-- 隐藏进度条
		ZhongQiuShiCi_Shi_Jihuo : Hide()
		ZhongQiuShiCi_Ci_Jihuo : Hide()
	end
end
--=========================================================
-- 计时器的回调
--=========================================================
function ZhongQiuShiCi_TimerProc()
	if g_nTimerTick >= 1 then
		-- 停止所有动画
		for i = 1, 4 do
			g_ShiAnimateControl[i] : Play(false)
		end
		
		for i = 1, 8 do
			g_CiAnimateControl[i] : Play(false)
		end
		g_nTimerTick = 0
		KillTimer("ZhongQiuShiCi_TimerProc()")
	end
	g_nTimerTick = g_nTimerTick + 1
end

--=========================================================
-- 点击切换按钮
--=========================================================
function ZhongQiuShiCi_ChangePage(nPageNum)
	if 1 == nPageNum then
		-- 切换到第一页 诗
		ZhongQiuShiCi_ShowShi(g_nActivatedNum)
		ZhongQiuShiCi_Ci_Pick : SetCheck(0)
		ZhongQiuShiCi_Shi_Pick : SetCheck(1)
	end
	
	if 2 == nPageNum then
		-- 切换到第二页 词
		ZhongQiuShiCi_ShowCi(g_nActivatedNum - g_MAX_ActivatedNumPoem)
		ZhongQiuShiCi_Ci_Pick : SetCheck(1)
		ZhongQiuShiCi_Shi_Pick : SetCheck(0)
	end
end

--=========================================================
-- 清空所有内容
--=========================================================
function ZhongQiuShiCi_ClearShow()
	ZhongQiuShiCi_Shi_BK : Hide()
	ZhongQiuShiCi_Ci_BK : Hide()
	--ZhongQiuShiCi_Shi_Explain : Hide()
	--ZhongQiuShiCi_Ci_Explain : Hide()
	--ZhongQiuShiCi_Shi_Button : Hide()
	--ZhongQiuShiCi_Ci_Button : Hide()
	
	ZhongQiuShiCi_Shi_Jihuo : Hide()
	ZhongQiuShiCi_Ci_Jihuo : Hide()
	
	-- 总按钮，合成一个了，名字起的比较随意，应该叫做ZhongQiuShiCi_Button
	ZhongQiuShiCi_Ci_Button : Hide()
	ZhongQiuShiCi_Ci_Pick : SetCheck(0)
	ZhongQiuShiCi_Shi_Pick : SetCheck(0)
	
	for i = 1, 4 do
		--g_ShiShowControl[i]:SetProperty("NormalImage", g_ShiShowInfo[i].ImageN )
		g_ShiShowControl[i] : Hide()
		g_ShiAnimateControl[i] : Play(false)
	end
	
	for i = 1, 8 do
		--g_CiShowControl[i]:SetProperty("NormalImage", g_ShiShowInfo[i].ImageN )
		g_CiShowControl[i] : Hide()
		g_CiAnimateControl[i] : Play(false)
	end
end

--=========================================================
-- 显示诗词条
--=========================================================
function ZhongQiuShiCi_ShowShi(nNum)	
	ZhongQiuShiCi_Shi_BK : Show()
	ZhongQiuShiCi_Ci_BK : Hide()
	
	for i = 1, 4 do
		if i > nNum then
			-- 未激活
			--g_ShiShowControl[i]:SetProperty("NormalImage", g_ShiShowInfo[i].ImageN )
			g_ShiShowControl[i] : Hide()
		else
			-- 激活
			--g_ShiShowControl[i]:SetProperty("NormalImage", g_ShiShowInfo[i].ImageY )
			g_ShiShowControl[i] : Show()
		end
	end
	
	ZhongQiuShiCi_Shi_Jihuo : Show()
	ZhongQiuShiCi_Ci_Jihuo : Hide()
	
	local nNumShow = nNum
	if nNumShow > 4 then
		nNumShow = 4
	end
	if nNumShow < 0 then
		nNumShow = 0
	end
	local strMsg = ScriptGlobal_Format("#{ZQYJ_170906_137}", nNumShow)
	ZhongQiuShiCi_Shi_Jihuo : SetText(strMsg)
end

--=========================================================
-- 显示词词条
--=========================================================
function ZhongQiuShiCi_ShowCi(nNum)	
	ZhongQiuShiCi_Ci_BK : Show()
	ZhongQiuShiCi_Shi_BK : Hide()
	
	for i = 1, 8 do
		if i > nNum then
			-- 未激活
			--g_CiShowControl[i]:SetProperty("NormalImage", g_CiShowInfo[i].ImageN )
			g_CiShowControl[i] : Hide()
		else
			-- 激活
			--g_CiShowControl[i]:SetProperty("NormalImage", g_CiShowInfo[i].ImageY )
			g_CiShowControl[i] : Show()
		end
	end
	
	ZhongQiuShiCi_Shi_Jihuo : Hide()
	ZhongQiuShiCi_Ci_Jihuo : Show()
	
	local nNumShow = nNum
	if nNumShow > 8 then
		nNumShow = 8
	end
	if nNumShow < 0 then
		nNumShow = 0
	end
	
	local strMsg = ScriptGlobal_Format("#{ZQYJ_170906_138}", nNumShow)
	ZhongQiuShiCi_Ci_Jihuo : SetText(strMsg)
end

--=========================================================
-- 界面位置重置
--=========================================================
function ZhongQiuShiCi_Frame_On_ResetPos()
  ZhongQiuShiCi_Frame:SetProperty("UnifiedPosition", g_ZhongQiuShiCi_Frame_UnifiedPosition)
end