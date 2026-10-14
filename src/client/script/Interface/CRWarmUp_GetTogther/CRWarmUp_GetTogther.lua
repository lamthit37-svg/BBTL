-- 2021Q3 预热签到 聚一起

local g_data_list = {}								-- 临时数据
local g_ui_list = {}								-- 组合表
local g_frame_unifiedposition = nil					-- 分辨率变化跟踪数值

local g_crwarmup_gettogther_expmax		= 20		-- 历练次数上限
local g_crwarmup_gettogther_expfinish	= 5			-- 历练终点
local g_crwarmup_gettogther_level		= 30		-- 等级限制
local g_crwarmup_gettogther_actneed		= 200		-- 游历值日活需要
local g_crwarmup_gettogther_lotterymax	= 5			-- 最大抽奖次数
local g_crwarmup_gettogther_boxcost		= 1			-- 抽取钥匙消耗
local g_crwarmup_gettogther_boxdayneed	= 1200		-- 宝箱活跃需要
local g_crwarmup_gettogther_boxweekneed	= 2000		-- 宝箱周活跃
local g_crwarmup_gettogther_looptime	= 1.1		-- 动画播放时间

local g_Time_Start						= 20211011	--20211011
local g_TimeStep1_End					= 20211028	--20211028
-- 第二阶段：29日宝箱
local g_TimeStep2_Start					= 20211029	--20211029
local g_TimeBox_End						= 20211114	-- 礼包结束时间
local g_TimeEnd							= 20211117

local g_secStep_Update					= 1			-- 二阶段更新标识

local g_OpenTime						= 0
local g_UICommand						= 88877304	-- 刷新界面红点

g_crwarmup_gettogther_playerexpcost = {				-- 历练消耗
	2, 4, 6, 8, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
}

g_crwarmup_gettogther_17expcost = {					-- 十七历练一次消耗的代币数量
	2, 2, 3, 2, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,  
}

local g_crwarmup_gettogther_itemreward = {
	39923595,39923596,39923597,39923598,39923599,39923600,39923601,39923602,39923603,
}

-- 剧情名字包装
local g_crwarmup_gettogther_story = {
	"#{MPYR_210830_44}","#{MPYR_210830_46}","#{MPYR_210830_48}","#{MPYR_210830_50}","#{MPYR_210830_54}",
	"#{MPYR_210830_56}","#{MPYR_210830_58}","#{MPYR_210830_60}","#{MPYR_210830_52}",
}

local g_crwarmup_gettogther_story_text = {
	{"#{MPYR_210830_44}","#{MPYR_210830_45}",},
	{"#{MPYR_210830_46}","#{MPYR_210830_47}",},
	{"#{MPYR_210830_48}","#{MPYR_210830_49}",},
	{"#{MPYR_210830_50}","#{MPYR_210830_51}",},
	{"#{MPYR_210830_54}","#{MPYR_210830_55}",},
	{"#{MPYR_210830_56}","#{MPYR_210830_57}",},
	{"#{MPYR_210830_58}","#{MPYR_210830_59}",},
	{"#{MPYR_210830_60}","#{MPYR_210830_61}",},
	{"#{MPYR_210830_52}","#{MPYR_210830_53}",},
}

-- 宝箱TIPS
local g_crwarmup_gettogther_item_tips = {
	"#{MPYR_210830_205}",
	"#{MPYR_210830_206}",
	"#{MPYR_210830_207}",
	"#{MPYR_210830_208}",
	"#{MPYR_210830_209}",
	"#{MPYR_210830_210}",
	"#{MPYR_210830_211}",
	"#{MPYR_210830_212}",
	"#{MPYR_210830_213}",
}

local g_crwarmup_gettogther_btn_image = {
	rumeng =	{ push = "set:JiuYiRuMeng2 image:RuMeng_Pushed", normal = "set:JiuYiRuMeng2 image:RuMeng_Normal", hover = "set:JiuYiRuMeng2 image:RuMeng_Hover",},
	nianqing =	{ push = "set:JiuYiRuMeng2 image:NianQing_Pushed", normal = "set:JiuYiRuMeng2 image:NianQing_Normal", hover = "set:JiuYiRuMeng2 image:NianQing_Hover",},
	zhumeng =	{ push = "set:JiuYiRuMeng2 image:ZhuMeng_Pushed", normal = "set:JiuYiRuMeng2 image:ZhuMeng_Normal", hover = "set:JiuYiRuMeng2 image:ZhuMeng_Hover",},
	liuqing =	{ push = "set:JiuYiRuMeng2 image:LiuQing_Pushed", normal = "set:JiuYiRuMeng2 image:LiuQing_Normal", hover = "set:JiuYiRuMeng2 image:LiuQing_Hover",},
	box =		{ push = "set:JiuYiRuMeng2 image:BlackBox_Pushed", normal = "set:JiuYiRuMeng2 image:BlackBox_Normal", hover = "set:JiuYiRuMeng2 image:BlackBox_Hover", disable = "set:JiuYiRuMeng2 image:BlackBox_Disabled",},
	bigbox =	{ push = "set:JiuYiRuMeng2 image:MidBox_Pushed", normal = "set:JiuYiRuMeng2 image:MidBox_Normal", hover = "set:JiuYiRuMeng2 image:MidBox_Hover", disable = "set:JiuYiRuMeng2 image:MidBox_Disabled",},
}


function CRWarmUp_GetTogther_PreLoad()
	this:RegisterEvent("OPENUI_21Q3ACT_SIGNIN")
	this:RegisterEvent("UPDATE_21Q3ACT_SIGNIN",false)
	this:RegisterEvent("UI_COMMAND",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CRWarmUp_GetTogther_OnLoad()
	g_data_list = {
		playerexp			= 0,
		shiqiexp			= 0,
		playerplaying		= 0,	-- 男主动画标识
		shiqiplaying		= 0,	-- 十七动画标识
	}
	g_ui_list.nanzhu = {
		[1] = {action=CRWarmUp_GetTogther_NanZhu_Item1, icon=CRWarmUp_GetTogther_Frame1_NanZhuImage,btn=CRWarmUp_GetTogther_NanZhu_Story1,
					red=CRWarmUp_GetTogther_NanZhu_Tips1,bg=CRWarmUp_GetTogther_NanZhu_Client1,txt=CRWarmUp_GetTogther_NanZhu_TravelValue1,bget=CRWarmUp_GetTogther_NanZhu_Item1YiLingQu,},
		[2] = {action=CRWarmUp_GetTogther_NanZhu_Item2, icon=CRWarmUp_GetTogther_Frame2_NanZhuImage,btn=CRWarmUp_GetTogther_NanZhu_Story2,
					red=CRWarmUp_GetTogther_NanZhu_Tips2,bg=CRWarmUp_GetTogther_NanZhu_Client2,txt=CRWarmUp_GetTogther_NanZhu_TravelValue2,bget=CRWarmUp_GetTogther_NanZhu_Item2YiLingQu,},
		[3] = {action=CRWarmUp_GetTogther_NanZhu_Item3, icon=CRWarmUp_GetTogther_Frame3_NanZhuImage,btn=CRWarmUp_GetTogther_NanZhu_Story3,
					red=CRWarmUp_GetTogther_NanZhu_Tips3,bg=CRWarmUp_GetTogther_NanZhu_Client3,txt=CRWarmUp_GetTogther_NanZhu_TravelValue3,bget=CRWarmUp_GetTogther_NanZhu_Item3YiLingQu,},
		[4] = {action=CRWarmUp_GetTogther_NanZhu_Item4, icon=CRWarmUp_GetTogther_Frame4_NanZhuImage,btn=CRWarmUp_GetTogther_NanZhu_Story4,
					red=CRWarmUp_GetTogther_NanZhu_Tips4,bg=CRWarmUp_GetTogther_NanZhu_Client4,txt=CRWarmUp_GetTogther_NanZhu_TravelValue4,bget=CRWarmUp_GetTogther_NanZhu_Item4YiLingQu,},
		[5] = {action=CRWarmUp_GetTogther_NanZhuAndShiQi_Item, icon=CRWarmUp_GetTogther_NanZhuImage_Final,btn=CRWarmUp_GetTogther_NanZhuAndShiQi_Story,
					red=CRWarmUp_GetTogther_NanZhuAndShiQi_Tips,bg=CRWarmUp_GetTogther_NanZhuFinal,txt=CRWarmUp_GetTogther_NanZhu_TravelValue_Final,bget=CRWarmUp_GetTogther_NanZhuAndShiQi_ItemYiLingQu,},
	}
	g_ui_list.shiqi = {
		[1] = {action=CRWarmUp_GetTogther_ShiQi_Item1, icon=CRWarmUp_GetTogther_Frame1_ShiQiImage,btn=CRWarmUp_GetTogther_ShiQi_Story1,
					red=CRWarmUp_GetTogther_ShiQi_Tips1,bg=CRWarmUp_GetTogther_ShiQi_Client1,txt=CRWarmUp_GetTogther_ShiQi_TravelValue1,bget=CRWarmUp_GetTogther_ShiQi_Item1YiLingQu,},
		[2] = {action=CRWarmUp_GetTogther_ShiQi_Item2, icon=CRWarmUp_GetTogther_Frame2_ShiQiImage,btn=CRWarmUp_GetTogther_ShiQi_Story2,
					red=CRWarmUp_GetTogther_ShiQi_Tips2,bg=CRWarmUp_GetTogther_ShiQi_Client2,txt=CRWarmUp_GetTogther_ShiQi_TravelValue2,bget=CRWarmUp_GetTogther_ShiQi_Item2YiLingQu,},
		[3] = {action=CRWarmUp_GetTogther_ShiQi_Item3, icon=CRWarmUp_GetTogther_Frame3_ShiQiImage,btn=CRWarmUp_GetTogther_ShiQi_Story3,
					red=CRWarmUp_GetTogther_ShiQi_Tips3,bg=CRWarmUp_GetTogther_ShiQi_Client3,txt=CRWarmUp_GetTogther_ShiQi_TravelValue3,bget=CRWarmUp_GetTogther_ShiQi_Item3YiLingQu,},
		[4] = {action=CRWarmUp_GetTogther_ShiQi_Item4, icon=CRWarmUp_GetTogther_Frame4_ShiQiImage,btn=CRWarmUp_GetTogther_ShiQi_Story4,
					red=CRWarmUp_GetTogther_ShiQi_Tips4,bg=CRWarmUp_GetTogther_ShiQi_Client4,txt=CRWarmUp_GetTogther_ShiQi_TravelValue4,bget=CRWarmUp_GetTogther_ShiQi_Item4YiLingQu,},
		[5] = {action=CRWarmUp_GetTogther_NanZhuAndShiQi_Item, icon=CRWarmUp_GetTogther_ShiQiImage_Final,btn=CRWarmUp_GetTogther_NanZhuAndShiQi_Story,
					red=CRWarmUp_GetTogther_NanZhuAndShiQi_Tips,bg=CRWarmUp_GetTogther_ShiQiFinal,txt=CRWarmUp_GetTogther_ShiQi_TravelValue_Final,bget=CRWarmUp_GetTogther_NanZhuAndShiQi_ItemYiLingQu,},
	}
	g_frame_unifiedposition = CRWarmUp_GetTogther_MainFrame:GetProperty("UnifiedPosition") 
end

function CRWarmUp_GetTogther_OnEvent(event)
	if event == "OPENUI_21Q3ACT_SIGNIN" and tonumber(arg0) == 1 then
		CRWarmUp_GetTogther_DataEvent(0)
		CRWarmUp_GetTogther_OnShow()
	elseif event == "UPDATE_21Q3ACT_SIGNIN" then
		CRWarmUp_GetTogther_DataEvent(1)
		CRWarmUp_GetTogther_OnShow()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_UICommand then
		CRWarmUp_GetTogther_UpdateAllUI()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		CRWarmUp_GetTogther_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		CRWarmUp_GetTogther_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		CRWarmUp_GetTogther_Close()
	end
end

--===================================================================================
--*******************************聚一起Start***************************************
--===================================================================================

--=================初始化界面信息==============================
function CRWarmUp_GetTogther_OnShow()
	CRWarmUp_GetTogther_BaseUIUpdate()
	CRWarmUp_GetTogther_TogtherUIUpdate()
	CRWarmUp_GetTogther_RedPointUIUpdate()
	CRWarmUp_GetTogther_CloseOtherUI()
	this:Show()
end

--=================基础数据刷新==============================
function CRWarmUp_GetTogther_BaseUIUpdate()
	-- 男主历练值
	local nPlayerCoin = DataPool:Lua_21Q3SignInAct_GetCoin(0)
	-- 十七历练值
	local n17Coin = DataPool:Lua_21Q3SignInAct_GetCoin(1)

	-- 显示男主历练值
	local strText = ScriptGlobal_Format("#{MPYR_210830_62}", nPlayerCoin)
	--CRWarmUp_GetTogther_NanZhu_TravelValue:SetText(strText)
	-- 显示十七历练值
	--strText = ScriptGlobal_Format("#{MPYR_210830_64}", n17Coin)
	--CRWarmUp_GetTogther_ShiQi_TravelValue:SetText(strText)
	-- 显示需要的历练值
	local nPlayerExpCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount() + 1
	if nPlayerExpCnt > g_crwarmup_gettogther_expmax then
		nPlayerExpCnt = g_crwarmup_gettogther_expmax
	end

	local imagedata,tips = nil,""
	if nPlayerExpCnt <= g_crwarmup_gettogther_expfinish then
		imagedata = g_crwarmup_gettogther_btn_image.rumeng
		tips = "#{MPYR_210830_197}"
	else
		imagedata = g_crwarmup_gettogther_btn_image.zhumeng
		tips = "#{MPYR_210830_199}"
	end
	CRWarmUp_GetTogther_NanZhuTravel_Btn:SetProperty("PushedImage",imagedata.push)
	CRWarmUp_GetTogther_NanZhuTravel_Btn:SetProperty("HoverImage",imagedata.hover)
	CRWarmUp_GetTogther_NanZhuTravel_Btn:SetProperty("NormalImage",imagedata.normal)
	CRWarmUp_GetTogther_NanZhuTravel_Btn:SetToolTip(tips)

	strText = ScriptGlobal_Format("#{MPYR_210830_39}", g_crwarmup_gettogther_playerexpcost[nPlayerExpCnt])
	CRWarmUp_GetTogther_NanZhu_TravelDemandInfo:SetText(strText)

	-- 显示需要的17历练值
	local n17ExpCnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount() + 1
	if n17ExpCnt > g_crwarmup_gettogther_expmax then
		n17ExpCnt = g_crwarmup_gettogther_expmax
	end
	if n17ExpCnt <= g_crwarmup_gettogther_expfinish then
		imagedata = g_crwarmup_gettogther_btn_image.nianqing
		tips = "#{MPYR_210830_198}"
	else
		imagedata = g_crwarmup_gettogther_btn_image.liuqing
		tips = "#{MPYR_210830_200}"
	end

	CRWarmUp_GetTogther_ShiQiTravel_Btn:SetProperty("PushedImage",imagedata.push)
	CRWarmUp_GetTogther_ShiQiTravel_Btn:SetProperty("HoverImage",imagedata.hover)
	CRWarmUp_GetTogther_ShiQiTravel_Btn:SetProperty("NormalImage",imagedata.normal)
	CRWarmUp_GetTogther_ShiQiTravel_Btn:SetToolTip(tips)

	strText = ScriptGlobal_Format("#{MPYR_210830_40}", g_crwarmup_gettogther_17expcost[n17ExpCnt])
	CRWarmUp_GetTogther_ShiQi_TravelDemandInfo:SetText(strText)

	-- TabToolTips
	CRWarmUp_GetTogther_PageSelect1:SetToolTip("#{MPYR_210830_35}")
	CRWarmUp_GetTogther_PageSelect2:SetToolTip("#{MPYR_210830_36}")
	CRWarmUp_GetTogther_GetTravelValue:SetToolTip("#{MPYR_210830_201}")

	CRWarmUp_GetTogther_PageSelect1:SetCheck(1)
end

--=================TogtherUI刷新==============================
function CRWarmUp_GetTogther_TogtherUIUpdate()
	-- 显示历练起点
	CRWarmUp_GetTogther_StartExpUIUpdate()
	-- 显示男主历练
	CRWarmUp_GetTogther_PlayerExpUIUpdate()
	-- 显示十七历练
	CRWarmUp_GetTogther_17ExpUIUpdate()
	-- 显示终点区域
	CRWarmUp_GetTogther_FinishExpUIUpdate()
end

--=================动画UI刷新==============================
function CRWarmUp_GetTogther_AniUIUpdate()

end

--=================历程起点显示==============================
function CRWarmUp_GetTogther_StartExpUIUpdate()
	-- 男主历程起点
	local nPlayerExpCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount()
	if nPlayerExpCnt < 1 then
		local nPlayerCoin = DataPool:Lua_21Q3SignInAct_GetCoin(0)
		local szText = ScriptGlobal_Format("#{MPYR_210830_62}", nPlayerCoin)
		CRWarmUp_GetTogther_NanZhu_TravelValue_Start:SetText(szText)
		CRWarmUp_GetTogther_NanZhuStart:Show()
	else
		CRWarmUp_GetTogther_NanZhuStart:Hide()
	end
	-- 十七历程起点
	local n17ExpCnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount()
	if n17ExpCnt < 1 then
		-- 十七历练值
		local n17Coin = DataPool:Lua_21Q3SignInAct_GetCoin(1)
		local szText = ScriptGlobal_Format("#{MPYR_210830_64}", n17Coin)
		CRWarmUp_GetTogther_ShiQi_TravelValue_Start:SetText(szText)
		CRWarmUp_GetTogther_ShiQiStart:Show()
	else
		CRWarmUp_GetTogther_ShiQiStart:Hide()
	end
end

--=================男主历程UI刷新==============================
function CRWarmUp_GetTogther_PlayerExpUIUpdate()
	local cnt,uiimage = g_crwarmup_gettogther_expfinish - 1, g_crwarmup_gettogther_btn_image.box
	for i=1, cnt do
		local uidata = g_ui_list.nanzhu[i]
		-- 显示是否已经领取奖励
		local bGet = DataPool:Lua_21Q3SignInAct_GetRewardListValue(i-1)
		if bGet == 1 then
			uidata.action:SetProperty("PushedImage",uiimage.disable)
			uidata.action:SetProperty("HoverImage",uiimage.disable)
			uidata.action:SetProperty("NormalImage",uiimage.disable)
			uidata.bget:Show()
		else
			uidata.action:SetProperty("PushedImage",uiimage.push)
			uidata.action:SetProperty("HoverImage",uiimage.hover)
			uidata.action:SetProperty("NormalImage",uiimage.normal)
			uidata.bget:Hide()
		end
		uidata.action:SetToolTip(g_crwarmup_gettogther_item_tips[i])
		if bGet == 1000 then
			uidata.red:Show()
		else
			uidata.red:Hide()
		end
		-- 剧情按钮显示
		local nPlayerExpCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount()
		--	if nPlayerExpCnt >= i then
		--		uidata.btn:Show()
		--	else
		--		uidata.btn:Hide()
		--	end

		-- 小人显示
		if nPlayerExpCnt == i then
			local nPlayerCoin = DataPool:Lua_21Q3SignInAct_GetCoin(0)
			local szText = ScriptGlobal_Format("#{MPYR_210830_62}", nPlayerCoin)
			uidata.txt:SetText(szText)
			uidata.icon:Show()
			uidata.bg:Show()
		else
			uidata.icon:Hide()
			uidata.bg:Hide()
		end
		
		local text = g_crwarmup_gettogther_story_text[i]
		--uidata.btn:SetText(text[1])
		uidata.btn:SetToolTip(text[2])
	end
end

--=================17历程UI刷新==============================
function CRWarmUp_GetTogther_17ExpUIUpdate()
	local cnt,uiimage = g_crwarmup_gettogther_expfinish - 1, g_crwarmup_gettogther_btn_image.box
	for i=1, cnt do
		local idx = i + g_crwarmup_gettogther_expfinish - 1
		-- 首先显示action
		local uidata = g_ui_list.shiqi[i]
		-- 显示是否已经领取奖励
		local bGet = DataPool:Lua_21Q3SignInAct_GetRewardListValue(idx-1)
		if bGet == 1 then
			uidata.action:SetProperty("PushedImage",uiimage.disable)
			uidata.action:SetProperty("HoverImage",uiimage.disable)
			uidata.action:SetProperty("NormalImage",uiimage.disable)
			uidata.bget:Show()
		else
			uidata.action:SetProperty("PushedImage",uiimage.push)
			uidata.action:SetProperty("HoverImage",uiimage.hover)
			uidata.action:SetProperty("NormalImage",uiimage.normal)
			uidata.bget:Hide()
		end
		uidata.action:SetToolTip(g_crwarmup_gettogther_item_tips[idx])
		if bGet == 1000 then
			uidata.red:Show()
		else
			uidata.red:Hide()
		end
		-- 剧情按钮显示
		local n17ExpCnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount()
		--if n17ExpCnt >= i then
		--	uidata.btn:Show()
		--else
		--	uidata.btn:Hide()
		--end
		-- 小人显示
		if n17ExpCnt == i then
			local n17Coin = DataPool:Lua_21Q3SignInAct_GetCoin(1)
			local szText = ScriptGlobal_Format("#{MPYR_210830_64}", n17Coin)
			uidata.txt:SetText(szText)
			uidata.icon:Show()
			uidata.bg:Show()
		else
			uidata.icon:Hide()
			uidata.bg:Hide()
		end

		local text = g_crwarmup_gettogther_story_text[idx]
		--uidata.btn:SetText(text[1])
		uidata.btn:SetToolTip(text[2])
	end
end

--=================历程终点UI刷新==============================
function CRWarmUp_GetTogther_FinishExpUIUpdate()

	-- 获得终点ID
	local idx = g_crwarmup_gettogther_expfinish*2 - 1
	local finishidx = g_crwarmup_gettogther_expfinish
	-- 首先显示action
	local uidata = g_ui_list.nanzhu[finishidx]

	local uiimage = g_crwarmup_gettogther_btn_image.bigbox
	-- 显示是否已经领取奖励
	local bGet = DataPool:Lua_21Q3SignInAct_GetRewardListValue(idx-1)
	if bGet == 1 then
		uidata.action:SetProperty("PushedImage",uiimage.disable)
		uidata.action:SetProperty("HoverImage",uiimage.disable)
		uidata.action:SetProperty("NormalImage",uiimage.disable)
		uidata.bget:Show()
	else
		uidata.action:SetProperty("PushedImage",uiimage.push)
		uidata.action:SetProperty("HoverImage",uiimage.hover)
		uidata.action:SetProperty("NormalImage",uiimage.normal)
		uidata.bget:Hide()
	end
	uidata.action:SetToolTip(g_crwarmup_gettogther_item_tips[idx])
	if bGet == 1000 then
		uidata.red:Show()
	else
		uidata.red:Hide()
	end


	local text = g_crwarmup_gettogther_story_text[idx]
	--uidata.btn:SetText(text[1])
	uidata.btn:SetToolTip(text[2])

	-- 剧情按钮和小人显示
	local n17ExpCnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount()
	local nPlayerExpCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount()


	if nPlayerExpCnt >= finishidx then
		local nPlayerCoin = DataPool:Lua_21Q3SignInAct_GetCoin(0)
		local szText = ScriptGlobal_Format("#{MPYR_210830_62}", nPlayerCoin)
		uidata.txt:SetText(szText)

		if g_data_list.playerplaying > 0 then
			uidata.icon:Hide()
		else
			uidata.icon:Show()
		end

		uidata.bg:Show()
	else
		uidata.bg:Hide()
	end

	local ui17data = g_ui_list.shiqi[finishidx]
	if n17ExpCnt >= finishidx then
		local n17Coin = DataPool:Lua_21Q3SignInAct_GetCoin(1)
		local szText = ScriptGlobal_Format("#{MPYR_210830_64}", n17Coin)
		ui17data.txt:SetText(szText)

		if g_data_list.shiqiplaying > 0 then
			ui17data.icon:Hide()
		else
			ui17data.icon:Show()
		end

		ui17data.bg:Show()
	else
		ui17data.bg:Hide()
	end

	if nPlayerExpCnt >= finishidx and n17ExpCnt >= finishidx then
		CRWarmUp_GetTogther_Logo:Show()
	else
		CRWarmUp_GetTogther_Logo:Hide()
	end
end

--=================红点刷新==============================
function CRWarmUp_GetTogther_RedPointUIUpdate()

	if CRWarmUp_GetTogther_IsRightTime() == 1 then
		-- 男主历练值
		local nPlayerCoin = DataPool:Lua_21Q3SignInAct_GetCoin(0)
		-- 十七历练值
		local n17Coin = DataPool:Lua_21Q3SignInAct_GetCoin(1)
		-- 获得男主历练值
		local nPlayerCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount()
		-- 获得17历练值
		local n17Cnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount()
		
		local bRed = 0
		-- 判定男主历练是否显示红点
		if nPlayerCnt >= g_crwarmup_gettogther_expmax then
			CRWarmUp_GetTogther_NanZhuTravel_Tips:Hide()
		elseif nPlayerCoin >= g_crwarmup_gettogther_playerexpcost[nPlayerCnt+1] then
			bRed = 1
			CRWarmUp_GetTogther_NanZhuTravel_Tips:Show()
		else
			CRWarmUp_GetTogther_NanZhuTravel_Tips:Hide()
		end

		-- 判定十七历练是否否显示红点
		if n17Cnt >= g_crwarmup_gettogther_expmax then
			CRWarmUp_GetTogther_ShiQiTravel_Tips:Hide()
		elseif n17Coin >= g_crwarmup_gettogther_17expcost[n17Cnt+1] then
			bRed = 1
			CRWarmUp_GetTogther_ShiQiTravel_Tips:Show()
		else
			CRWarmUp_GetTogther_ShiQiTravel_Tips:Hide()
		end

		-- 阶段领奖
		local getRewardCnt = g_crwarmup_gettogther_expfinish*2 - 1
		for i=1, getRewardCnt do
			local bGetItem = DataPool:Lua_21Q3SignInAct_GetRewardListValue(i-1)
			if bGetItem == 1000 then
				bRed = 1
				break
			end
		end

		--Lua_21Q3SignInAct_GetDayExpReward
		local bValueRed = 0
		-- 登录奖励是否领取
		local blogin = DataPool:Lua_21Q3SignInAct_GetDayExpReward(0)
		if blogin <= 0 then
			bValueRed = 1
		end
		-- 日活奖励
		local bDay = DataPool:Lua_21Q3SignInAct_GetDayExpReward(1)
		if bDay <= 0 then
			local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
			if nToadyActivePoint >= g_crwarmup_gettogther_actneed then
				bValueRed = 1
			end
		end
		
		-- 参与交互活动
		--local bAct = DataPool:Lua_21Q3SignInAct_GetDayExpReward(2)
		--if bAct <= 0 then
			--bValueRed = 1
		--end

		-- 显示获取阅历红点
		if bValueRed > 0 then
			CRWarmUp_GetTogther_GetTravelValue_Tips:Show()
		else
			CRWarmUp_GetTogther_GetTravelValue_Tips:Hide()
		end

		-- 显示聚一起红点
		if bValueRed > 0 or bRed > 0 then
			CRWarmUp_GetTogther_PageSelect1_Tips:Show()
		else
			CRWarmUp_GetTogther_PageSelect1_Tips:Hide()
		end
	else
		CRWarmUp_GetTogther_ShiQiTravel_Tips:Hide()
		CRWarmUp_GetTogther_NanZhuTravel_Tips:Hide()
		CRWarmUp_GetTogther_GetTravelValue_Tips:Hide()
		CRWarmUp_GetTogther_PageSelect1_Tips:Hide()
	end

	-- 红点默认二级段没有
	CRWarmUp_GetTogther_PageSelect2_Tips:Hide()
	-- if CRWarmUp_GetTogther_IsRightTime() >= 2 and CRWarmUp_GetTogther_IsRightTime() < 4 then
	-- 	local bRed = 0
	-- 	-- 抽取一次红点
	-- 	local nKey = DataPool:Lua_21Q3SignInAct_GetCoin(2)
	-- 	if nKey >= g_crwarmup_gettogther_boxcost then
	-- 		bRed = 1
	-- 	end

	-- 	if CRWarmUp_GetTogther_IsRightTime() == 2 then
	-- 		-- 日活跃钥匙
	-- 		local nDayReward = DataPool:Lua_21Q3SignInAct_GetDayActiveKeyReward()
	-- 		if nDayReward <=0 then
	-- 			local nToadyActivePoint = Player:GetData("WEEKACTIVEPOINT")
	-- 			if nToadyActivePoint >= g_crwarmup_gettogther_boxdayneed then
	-- 				bRed = 1
	-- 			end
	-- 		end

	-- 		-- 周活跃钥匙
	-- 		if bRed < 1 then
	-- 			local nWeekReward = DataPool:Lua_21Q3SignInAct_GetWeekActiveKeyReward()
	-- 			if nWeekReward <= 0 then
	-- 				local nWeekActivePoint = Player:GetData("WEEKACTIVEPOINT")
	-- 				if nWeekActivePoint >= g_crwarmup_gettogther_boxweekneed then
	-- 					bRed = 1
	-- 				end
	-- 			end
	-- 		end
	-- 	end

	-- 	-- 元宝买钥匙
	-- 	--if bRed < 1 then
	-- 	--	local bKeyBug = 0
	-- 	--	for i=1, g_crwarmup_gettogther_lotterymax do
	-- 	--		local reward = DataPool:Lua_21Q3SignInAct_GetLotteryInfo(i-1)
	-- 	--		if reward == 0 then
	-- 	--			bRed = 1
	-- 	--			break
	-- 	--		end
	-- 	--	end
	-- 	--end

	-- 	-- 显示开宝箱红点
	-- 	if bRed > 0 then
	-- 		CRWarmUp_GetTogther_PageSelect2_Tips:Show()
	-- 	end
	-- else
	-- 	CRWarmUp_GetTogther_PageSelect2_Tips:Hide()
	-- end
end

--=================是否为正确时间=============================
function CRWarmUp_GetTogther_IsRightTime()
	local nCurDay = tonumber(DataPool:GetServerDayTime())
	-- 第一阶段
	if nCurDay >= g_Time_Start and nCurDay <= g_TimeStep1_End then
		return 1
	end

	if nCurDay >= g_TimeStep2_Start and nCurDay <= g_TimeBox_End and g_secStep_Update > 0 then
		return 2
	end

	-- 第二阶段
	if nCurDay >= g_TimeStep2_Start and nCurDay <= g_TimeEnd and g_secStep_Update > 0 then
		return 3
	end

	if nCurDay >= g_Time_Start and nCurDay <= g_TimeEnd then
		return 4
	end

	-- 活动未开启
	if nCurDay < g_Time_Start then
		return -1
	end

	-- 活动已结束
	if nCurDay > g_TimeEnd then
		return -2
	end

	return 0
end

--=================基础条件检查=============================
function CRWarmUp_GetTogther_BaseCheck()
	-- 安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return 0
	end

	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return 0
	end

	-- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage("#{ZJWF_201231_25}")
		return 0
	end

	return 1
end
--=================点击男主历练==============================
function CRWarmUp_GetTogther_NanZhuTravel_OnClick()
	
	-- 基础条件检查
	if CRWarmUp_GetTogther_BaseCheck() < 1 then
		return
	end

	-- 男主历练值
	local nPlayerCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount()
	if nPlayerCnt < g_crwarmup_gettogther_expfinish then
		-- 判定是否处于活动时间内
		if CRWarmUp_GetTogther_IsRightTime() ~= 1 then
			PushDebugMessage( "#{MPYR_210830_106}" )
			return
		end

		local nLevel = Player:GetLevel()
		if nLevel < g_crwarmup_gettogther_level then
			PushDebugMessage("#{MPYR_210830_104}")
			return 0
		end

		if nPlayerCnt >= g_crwarmup_gettogther_expfinish then
			PushDebugMessage( "#{MPYR_210830_107}" )
			return
		end

		-- 获得男主历练值
		local nPlayerCoin = DataPool:Lua_21Q3SignInAct_GetCoin(0)
		if nPlayerCoin < g_crwarmup_gettogther_playerexpcost[nPlayerCnt+1] then
			PushDebugMessage( "#{MPYR_210830_108}" )
			return
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AddPlayerExpCount" )
			Set_XSCRIPT_ScriptID( 888772 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		-- 判定是否处于活动时间内
		if CRWarmUp_GetTogther_IsRightTime() ~= 1 then
			PushDebugMessage( "#{MPYR_210830_162}" )
			return
		end

		local nLevel = Player:GetLevel()
		if nLevel < g_crwarmup_gettogther_level then
			PushDebugMessage("#{MPYR_210830_163}")
			return 0
		end

		if nPlayerCnt >= g_crwarmup_gettogther_expmax then
			PushDebugMessage( "#{MPYR_210830_191}" )
			return
		end

		-- 获得男主历练值
		local nPlayerCoin = DataPool:Lua_21Q3SignInAct_GetCoin(0)
		if nPlayerCoin < g_crwarmup_gettogther_playerexpcost[nPlayerCnt+1] then
			PushDebugMessage( "#{MPYR_210830_164}" )
			return
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AddPlayerExExpCount" )
			Set_XSCRIPT_ScriptID( 888772 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

--=================点击17历练==============================
function CRWarmUp_GetTogther_ShiQiTravel_OnClick()
	-- 基础条件检查
	if CRWarmUp_GetTogther_BaseCheck() < 1 then
		return
	end

	local nCnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount()
	if nCnt < g_crwarmup_gettogther_expfinish then
		-- 判定是否处于活动时间内
		if CRWarmUp_GetTogther_IsRightTime() ~= 1 then
			PushDebugMessage( "#{MPYR_210830_187}" )
			return
		end

		local nLevel = Player:GetLevel()
		if nLevel < g_crwarmup_gettogther_level then
			PushDebugMessage("#{MPYR_210830_188}")
			return 0
		end

		-- 判断是否到上限
		if nCnt >= g_crwarmup_gettogther_expmax then 
			PushDebugMessage( "#{MPYR_210830_113}" )
			return
		end

		-- 17历练值
		local nShiQiCoin = DataPool:Lua_21Q3SignInAct_GetCoin(1)
		if nShiQiCoin < g_crwarmup_gettogther_17expcost[nCnt+1] then
			PushDebugMessage( "#{MPYR_210830_189}" )
			return
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Add17ExpCount" )
			Set_XSCRIPT_ScriptID( 888772 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		-- 判定是否处于活动时间内
		if CRWarmUp_GetTogther_IsRightTime() ~= 1 then
			PushDebugMessage( "#{MPYR_210830_166}" )
			return
		end

		local nLevel = Player:GetLevel()
		if nLevel < g_crwarmup_gettogther_level then
			PushDebugMessage("#{MPYR_210830_167}")
			return 0
		end

		-- 判断是否到上限
		if nCnt >= g_crwarmup_gettogther_expmax then 
			PushDebugMessage( "#{MPYR_210830_193}" )
			return
		end

		-- 17历练值
		local nShiQiCoin = DataPool:Lua_21Q3SignInAct_GetCoin(1)
		if nShiQiCoin < g_crwarmup_gettogther_17expcost[nCnt+1] then
			PushDebugMessage( "#{MPYR_210830_168}" )
			return
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Add17ExExpCount" )
			Set_XSCRIPT_ScriptID( 888772 )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

--=================点击领取奖励==============================
function CRWarmUp_GetTogther_ItemReward_OnClick(nIndex)
	-- 判定是否处于活动时间内
	if CRWarmUp_GetTogther_IsRightTime() ~= 1 then
		PushDebugMessage( "#{MPYR_210830_114}" )
		return
	end

	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_gettogther_level then
		PushDebugMessage("#{MPYR_210830_115}")
		return 0
	end

	-- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage("#{ZJWF_201231_25}")
		return 0
	end

	local max = g_crwarmup_gettogther_expfinish*2 - 1
	if nIndex < 1 or nIndex > max then
		return
	end

	local bGet = DataPool:Lua_21Q3SignInAct_GetRewardListValue(nIndex-1)
	if bGet == 1 then
		PushDebugMessage("#{MPYR_210830_116}")
		return
	elseif bGet ~= 1000 then
		local szStory = g_crwarmup_gettogther_story[nIndex]
		local szNotice = ScriptGlobal_Format("#{MPYR_210830_117}", szStory)
		PushDebugMessage(szNotice)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetRewardItem" )
		Set_XSCRIPT_ScriptID( 888772 )
		Set_XSCRIPT_Parameter(0, nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=================点击男主剧情界面==============================
function CRWarmUp_GetTogther_Story_OnClick(nIndex)
	-- 判定是否处于活动时间内
	if CRWarmUp_GetTogther_IsRightTime() ~= 1 then
		PushDebugMessage( "#{MPYR_210830_120}" )
		return
	end

	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_gettogther_level then
		PushDebugMessage("#{MPYR_210830_121}")
		return 0
	end

	local max = g_crwarmup_gettogther_expfinish*2 - 1
	if nIndex < 1 or nIndex > max then
		return
	end

	local bRet = 1
	-- 点击的位男主剧情
	if nIndex < g_crwarmup_gettogther_expfinish then
		-- 获得男主历练值
		local nPlayerCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount()
		if nPlayerCnt < nIndex then
			bRet = 0
		end
	elseif nIndex < max then
		-- 17历练
		local n17Cnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount()
		local realidx = nIndex - g_crwarmup_gettogther_expfinish + 1
		if n17Cnt < realidx then
			bRet = 0
		end
	else
		-- 终点
		local nPlayerCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount()
		local n17Cnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount()
		if nPlayerCnt < g_crwarmup_gettogther_expfinish or n17Cnt < g_crwarmup_gettogther_expfinish then
			bRet = 0
		end
	end

	-- 判断是否通过
	if bRet == 0 then
		if nIndex == max then
			PushDebugMessage( "#{MPYR_210830_123}" )
		else
			local szStory = g_crwarmup_gettogther_story[nIndex]
			local szNotice = ScriptGlobal_Format("#{MPYR_210830_122}", szStory)
			PushDebugMessage(szNotice)
		end
		
		return
	end

	CRWarmUp_GetTogther_OnShowStoryUI(nIndex)
end

--=================获得历练值==============================
function CRWarmUp_GetTogther_GetTravelValue_OnClick()
	-- 判定是否处于活动时间内
	if CRWarmUp_GetTogther_IsRightTime() ~= 1 then
		PushDebugMessage( "#{MPYR_210830_114}" )
		return
	end

	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_gettogther_level then
		PushDebugMessage("#{MPYR_210830_115}")
		return 0
	end

	PushEvent("OPEN_21Q3ACT_SIGNIN_OTHER", 2)
end

--=================点击开宝箱==============================
function CRWarmUp_GetTogther_SelectPageOnClick()
	--CRWarmUp_GetTogther_Close()
	-- 打开开宝箱界面
	-- 判定时间
	if CRWarmUp_GetTogther_IsRightTime() <= 0 then
		PushDebugMessage("#{MPYR_210830_18}")
		return
	end

	-- 等级
	local nLevel = Player:GetLevel()
	if nLevel < g_crwarmup_gettogther_level then
		PushDebugMessage("#{MPYR_210830_17}")
		return
	end

	CRWarmUp_GetTogther_Close_Reset()
	PushEvent("OPENUI_21Q3ACT_SIGNIN", 2)
end

function  CRWarmUp_GetTogther_CloseOtherUI()
	if IsWindowShow( "CRWarmUp_OpenBaoXiang" ) then
		CloseWindow( "CRWarmUp_OpenBaoXiang", true )
	end
end

--=================点击帮助按钮==============================
function CRWarmUp_GetTogther_OnHelpClick()
	PushEvent( "OPEN_HUODONGTEXT_HELP", 3, "#{MPYR_210830_38}" )
end


function CRWarmUp_GetTogther_DataReset()
	g_data_list.playerexp = 0
	g_data_list.shiqiexp = 0
	g_data_list.playerplaying = 0
	g_data_list.shiqiplaying = 0
	g_OpenTime = 0
end

function CRWarmUp_GetTogther_DataEvent(bShow)

	local nPlayerCnt = DataPool:Lua_21Q3SignInAct_GetPlayerExperienceCount()
	local n17ExpCnt = DataPool:Lua_21Q3SignInAct_Get17ExperienceCount()

	CRWarmUp_NanZhu:Hide()
	CRWarmUp_ShiQi:Hide()
	if bShow > 0 then
		-- 男主历程变化
		if nPlayerCnt > g_data_list.playerexp then
			if nPlayerCnt > g_crwarmup_gettogther_expfinish then
				g_data_list.playerplaying = 1
				-- 跳跃
				CRWarmUp_NanZhu:Show()
				CRWarmUp_NanZhu:Play(true)
				SetTimer("CRWarmUp_GetTogther", "CRWarmUp_GetTogther_SetTimer()",g_crwarmup_gettogther_looptime*1000)
			else
				-- 弹剧情
				if n17ExpCnt >= g_crwarmup_gettogther_expfinish and nPlayerCnt >= g_crwarmup_gettogther_expfinish then
					-- 最终剧情
					CRWarmUp_GetTogther_OnShowStoryUI(g_crwarmup_gettogther_expfinish*2-1)
				elseif nPlayerCnt < g_crwarmup_gettogther_expfinish then
					-- 男主历程剧情
					CRWarmUp_GetTogther_OnShowStoryUI(nPlayerCnt)
				end
			end
		end

		-- 十七历程变化
		if n17ExpCnt > g_data_list.shiqiexp then
			if n17ExpCnt > g_crwarmup_gettogther_expfinish then
				g_data_list.shiqiplaying = 1
				-- 跳跃
				CRWarmUp_ShiQi:Show()
				CRWarmUp_ShiQi:Play(true)
				SetTimer("CRWarmUp_GetTogther", "CRWarmUp_GetTogther_SetTimer()",g_crwarmup_gettogther_looptime*1000)
			else
				-- 弹剧情
				if n17ExpCnt >= g_crwarmup_gettogther_expfinish and nPlayerCnt >= g_crwarmup_gettogther_expfinish then
					-- 最终剧情
					CRWarmUp_GetTogther_OnShowStoryUI(g_crwarmup_gettogther_expfinish*2-1)
				elseif n17ExpCnt < g_crwarmup_gettogther_expfinish then
					-- s历程剧情
					CRWarmUp_GetTogther_OnShowStoryUI(n17ExpCnt + g_crwarmup_gettogther_expfinish - 1)
				end
			end
		end
	else
		local selfUnionPos = Variable:GetVariable("CRWarmUpPos")
		if selfUnionPos ~= nil then
			CRWarmUp_GetTogther_MainFrame:SetProperty("UnifiedPosition", selfUnionPos)
		end
	end

	g_OpenTime = tonumber(DataPool:GetServerDayTime())
	g_data_list.playerexp = nPlayerCnt
	g_data_list.shiqiexp = n17ExpCnt
end

function CRWarmUp_GetTogther_OnShowStoryUI(nIndex)

	if IsWindowShow( "CRWarmUp_Story" ) then
		CloseWindow( "CRWarmUp_Story", true )
	end

	PushEvent("OPEN_21Q3ACT_SIGNIN_OTHER", 1, nIndex)
end

function CRWarmUp_GetTogther_UpdateAllUI()
	if this:IsVisible() then
		local curday = Get_XParam_INT(0)
		if curday > g_OpenTime then
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "RefreshClientUI" )
			Set_XSCRIPT_ScriptID( 888772 )
			Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()
		end
	end
end


function CRWarmUp_GetTogther_SetTimer()
	if g_data_list.playerplaying > 0 then
		CRWarmUp_NanZhu:Hide()
		g_ui_list.nanzhu[g_crwarmup_gettogther_expfinish].icon:Show()
		g_data_list.playerplaying = 0
	end

	if g_data_list.shiqiplaying > 0 then
		CRWarmUp_ShiQi:Hide()
		g_ui_list.shiqi[g_crwarmup_gettogther_expfinish].icon:Show()
		g_data_list.shiqiplaying = 0
	end

	if g_data_list.playerplaying <= 0 and g_data_list.shiqiplaying <= 0 then
		KillTimer("CRWarmUp_GetTogther_SetTimer()")
	end
end

function CRWarmUp_GetTogther_Close_Reset()
	CRWarmUp_GetTogther_DataReset()
	KillTimer("CRWarmUp_GetTogther_SetTimer()")

	Variable:SetVariable("CRWarmUpPos", CRWarmUp_GetTogther_MainFrame:GetProperty("UnifiedPosition"), 1)
end

function CRWarmUp_GetTogther_Close()
	CRWarmUp_GetTogther_Close_Reset()
	this:Hide()
end

function CRWarmUp_GetTogther_ResetPos()
	CRWarmUp_GetTogther_MainFrame:SetProperty("UnifiedPosition", g_frame_unifiedposition)
end
