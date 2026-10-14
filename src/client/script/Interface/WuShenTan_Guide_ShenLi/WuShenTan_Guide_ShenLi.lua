--WuShenTan_Guide_ShenLi.lua
local g_WuShenTan_Guide_ShenLi_Frame_UnifiedPosition
local g_WuShenTan_Guide_ShenLi_UICOM                 = 21225602
local g_WuShenTan_Guide_ShenLi_NowuiTab              = 1 --界面区分3个页签，分别显示不同内容
local g_WuShenTan_Guide_ShenLi_WorldEmpowerData      = 0
local g_WuShenTan_Guide_ShenLi_WorldCacheEmpowerData = 0 --比赛前缓存记录的本服神力祝福进度
local g_WuShenTan_Guide_ShenLi_Origin_RankType       = 41 --本服个人排行榜类型
local g_WuShenTan_Guide_ShenLi_Origin_Level          = 30
local g_WuShenTan_Guide_ShenLi_Origin_MyRank         = -1 --本人的排名
local g_WuShenTan_Guide_ShenLi_Origin_RewardFlag     = 0 --本人的奖励领取标记
local g_WuShenTan_Guide_ShenLi_Origin_IsRewardGet    = 1 --个人排行榜的奖励领取标记
local g_WuShenTan_Guide_ShenLi_Origin_MyRankWidget   = {}
local g_WuShenTan_Guide_ShenLi_Origin_MyRankCount    = 3 --前三名用的图片来显示名次
local g_WuShenTan_Guide_ShenLi_KajiType				 = 74 --KJ_PLAYERMAKR
local g_WuShenTan_Guide_ShenLi_GiftTblCount          = 10
local g_WuShenTan_Guide_ShenLi_GiftTbl               =
{
	[1] = { needpro = 500000,  isGet = 0, itemId = 30700241, itemNum =  2,},
	[2] = { needpro = 1000000, isGet = 0, itemId = 20310168, itemNum = 10,},
	[3] = { needpro = 1500000, isGet = 0, itemId = 30503133, itemNum =  2,},
	[4] = { needpro = 2000000, isGet = 0, itemId = 38000571, itemNum =  3,},
	[5] = { needpro = 2500000, isGet = 0, itemId = 38000807, itemNum =  3,},
	[6] = { needpro = 3000000, isGet = 0, itemId = 38000380, itemNum =  2,},
	[7] = { needpro = 3500000, isGet = 0, itemId = 38000992, itemNum =  3,},
	[8] = { needpro = 4000000, isGet = 0, itemId = 38004359, itemNum =  2,},
	[9] = { needpro = 4500000, isGet = 0, itemId = 30008048, itemNum =  1,},
   [10] = { needpro = 5000000, isGet = 0, itemId = 38005556, itemNum =  1,},
}
local g_WuShenTan_Guide_ShenLi_GiftTbl_kaji               =
{
	[1] = { needpro = 500000,  itemId = 30700241, itemNum =  2,},
	[2] = { needpro = 1000000, itemId = 20310168, itemNum = 10,},
	[3] = { needpro = 1500000, itemId = 30503133, itemNum =  2,},
	[4] = { needpro = 2000000, itemId = 38000571, itemNum =  3,},
	[5] = { needpro = 2500000, itemId = 38000807, itemNum =  3,},
	[6] = { needpro = 3000000, itemId = 38000656, itemNum =  5,},
	[7] = { needpro = 3500000, itemId = 38000992, itemNum =  3,},
	[8] = { needpro = 4000000, itemId = 38000571, itemNum =  5,},
	[9] = { needpro = 4500000, itemId = 30008048, itemNum =  1,},
   [10] = { needpro = 5000000, itemId = 38005556, itemNum =  1,},
}
local g_WuShenTan_Guide_ShenLi_GiftTbl_sj               =
{
	[1] = { needpro = 500000,  itemId = 30700241, itemNum =  2,},
	[2] = { needpro = 1000000, itemId = 20310168, itemNum = 10,},
	[3] = { needpro = 1500000, itemId = 30503133, itemNum =  2,},
	[4] = { needpro = 2000000, itemId = 38000571, itemNum =  3,},
	[5] = { needpro = 2500000, itemId = 38000807, itemNum =  3,},
	[6] = { needpro = 3000000, itemId = 38000380, itemNum =  2,},
	[7] = { needpro = 3500000, itemId = 38000992, itemNum =  3,},
	[8] = { needpro = 4000000, itemId = 38000571, itemNum =  5,},
	[9] = { needpro = 4500000, itemId = 30008048, itemNum =  1,},
   [10] = { needpro = 5000000, itemId = 38005556, itemNum =  1,},
}
local g_WuShenTan_Guide_ShenLi_GiftTbl_qx               =
{
	[1] = { needpro = 500000,  itemId = -1, itemNum = 0,},
	[2] = { needpro = 1000000, itemId = -1, itemNum = 0,},
	[3] = { needpro = 1500000, itemId = -1, itemNum = 0,},
	[4] = { needpro = 2000000, itemId = -1, itemNum = 0,},
	[5] = { needpro = 2500000, itemId = -1, itemNum = 0,},
	[6] = { needpro = 3000000, itemId = -1, itemNum = 0,},
	[7] = { needpro = 3500000, itemId = -1, itemNum = 0,},
	[8] = { needpro = 4000000, itemId = -1, itemNum = 0,},
	[9] = { needpro = 4500000, itemId = -1, itemNum = 0,},
   [10] = { needpro = 5000000, itemId = -1, itemNum = 0,},
}
local g_WuShenTan_Guide_ShenLi_GiftTblWidget         = {}
local g_WuShenTan_Guide_ShenLi_EmpowerTblCount       = 10
local g_WuShenTan_Guide_ShenLi_EmpowerTbl            =
{
	[1] = { needEmpowerData = 500000,  damageStr = "1%", defenseStr = "0%", damageDic = "", defenseDic ="", },
	[2] = { needEmpowerData = 1000000, damageStr = "1%", defenseStr = "1%", damageDic = "", defenseDic ="", },
	[3] = { needEmpowerData = 1500000, damageStr = "2%", defenseStr = "1%", damageDic = "", defenseDic ="", },
	[4] = { needEmpowerData = 2000000, damageStr = "2%", defenseStr = "2%", damageDic = "", defenseDic ="", },
	[5] = { needEmpowerData = 2500000, damageStr = "3%", defenseStr = "2%", damageDic = "", defenseDic ="", },
	[6] = { needEmpowerData = 3000000, damageStr = "3%", defenseStr = "3%", damageDic = "", defenseDic ="", },
	[7] = { needEmpowerData = 3500000, damageStr = "4%", defenseStr = "3%", damageDic = "", defenseDic ="", },
	[8] = { needEmpowerData = 4000000, damageStr = "4%", defenseStr = "4%", damageDic = "", defenseDic ="", },
	[9] = { needEmpowerData = 4500000, damageStr = "5%", defenseStr = "4%", damageDic = "", defenseDic ="", },
   [10] = { needEmpowerData = 5000000, damageStr = "5%", defenseStr = "5%", damageDic = "", defenseDic ="", },
}
local g_WuShenTan_Guide_ShenLi_EmpowerTblWidget      = {}
local g_WuShenTan_Guide_ShenLi_AllZone_RankType      = 42 --跨服服务器级排行榜类型
local g_WuShenTan_Guide_ShenLi_AllZone_RankType_sj   = 43 --跨服服务器级排行榜类型
local g_WuShenTan_Guide_ShenLi_AllZone_RankType_qx   = 44 --跨服服务器级排行榜类型
local g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType = 0 --兼容三种服务器级排行榜
local g_WuShenTan_Guide_ShenLi_AllZone_MyRankWidget  = {}
local g_WuShenTan_Guide_ShenLi_AllZone_MyRankCount   = 3 --前三名用的图片来显示名次
local g_WuShenTan_Guide_ShenLi_AllZone_IsRewardGet   = 1 --跨服排行榜的领奖标记
local g_WuShenTan_Guide_ShenLi_AllZone_MyworldRank   = -1 --本服的排名
local g_WuShenTan_Guide_ShenLi_SelfEmpowerData       = 0 --本服的排名
local g_WuShenTan_Guide_ShenLi_IsInEmpowerMatchCacheTime = 0
local g_WuShenTan_Guide_ShenLi_SwitchBtnWidget		 = {}
local g_WuShenTan_Guide_ShenLi_SwitchBtnWidgetCount  = 3
local g_WuShenTan_Guide_ShenLi_IsShowRewardBtn  	 = 1

function WuShenTan_Guide_ShenLi_PreLoad()
	--第二个参数代表界面隐藏时事件是否有效,默认为true
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("OPEN_WSTEMPOWER_RLORIGIN", true)
	this:RegisterEvent("OPEN_WSTEMPOWER_RLALLZONE", true)
end

function WuShenTan_Guide_ShenLi_OnLoad()
	WuShenTan_Guide_ShenLi_LoadControl()
	g_WuShenTan_Guide_ShenLi_Frame_UnifiedPosition = WuShenTan_Guide_ShenLi_Frame:GetProperty("UnifiedPosition")
end

-- 装载控件
function WuShenTan_Guide_ShenLi_LoadControl()

	g_WuShenTan_Guide_ShenLi_Origin_MyRankWidget[1] = WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_Rank1
	g_WuShenTan_Guide_ShenLi_Origin_MyRankWidget[2] = WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_Rank2
	g_WuShenTan_Guide_ShenLi_Origin_MyRankWidget[3] = WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_Rank3

	g_WuShenTan_Guide_ShenLi_AllZone_MyRankWidget[1] = WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_Rank1
	g_WuShenTan_Guide_ShenLi_AllZone_MyRankWidget[2] = WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_Rank2
	g_WuShenTan_Guide_ShenLi_AllZone_MyRankWidget[3] = WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_Rank3

	for i = 1, g_WuShenTan_Guide_ShenLi_GiftTblCount do
		g_WuShenTan_Guide_ShenLi_GiftTblWidget[i] = {
			btn = _G["WuShenTan_Guide_ShenLiZhuFu_Reward_" .. i .. "_Btn"],
			getmask = _G["WuShenTan_Guide_ShenLiZhuFu_Reward_" .. i .. "_Btn_GetMask"],
			animate = _G["WuShenTan_Guide_ShenLiZhuFu_Reward_" .. i .. "_Btn_AnimateTip"],
			blackmask = _G["WuShenTan_Guide_ShenLiZhuFu_Reward_" .. i .. "_Btn_BlackMask"],
		}
	end

	g_WuShenTan_Guide_ShenLi_EmpowerTblWidget[1] = {
		imageline = nil,
		image = _G["WuShenTan_Guide_ShenLi_StageImage_1"],
		imageDisable = _G["WuShenTan_Guide_ShenLi_StageImage_1_Disable"],
		imagebk = _G["WuShenTan_Guide_ShenLi_StageImageBK_1"],
		imageText = _G["WuShenTan_Guide_ShenLi_StageImage_1_Text"],
	}
	for i = 2, g_WuShenTan_Guide_ShenLi_EmpowerTblCount do
		g_WuShenTan_Guide_ShenLi_EmpowerTblWidget[i] = {
			imageline = _G["WuShenTan_Guide_ShenLi_StageImageLine_" .. i],
			image = _G["WuShenTan_Guide_ShenLi_StageImage_" .. i],
			imageDisable = _G["WuShenTan_Guide_ShenLi_StageImage_" .. i .. "_Disable"],
			imagebk = _G["WuShenTan_Guide_ShenLi_StageImageBK_" .. i],
			imageText = _G["WuShenTan_Guide_ShenLi_StageImage_" .. i .. "_Text"],
		}
	end
	--for index = 1, g_WuShenTan_Guide_ShenLi_EmpowerTblCount, 1 do
	--	local tooltips = ""
	--	if g_WuShenTan_Guide_ShenLi_EmpowerTbl[index].damageDic ~= "" then
	--		tooltips = ScriptGlobal_Format(g_WuShenTan_Guide_ShenLi_EmpowerTbl[index].damageDic,g_WuShenTan_Guide_ShenLi_EmpowerTbl[index].damageStr)
	--	end
	--	if g_WuShenTan_Guide_ShenLi_EmpowerTbl[index].defenseDic ~= "" then
	--		tooltips = ScriptGlobal_Format(g_WuShenTan_Guide_ShenLi_EmpowerTbl[index].defenseDic,g_WuShenTan_Guide_ShenLi_EmpowerTbl[index].defenseStr)
	--	end
	--	g_WuShenTan_Guide_ShenLi_EmpowerTblWidget[index].image:SetToolTip(tooltips)
	--	g_WuShenTan_Guide_ShenLi_EmpowerTblWidget[index].imageDisable:SetToolTip(tooltips)
	--end

	function g_WuShenTan_Guide_ShenLi_EmpowerTblWidget:Show(index)
		if not self[index] then
			return
		end
		if self[index].imageline ~= nil then
			self[index].imageline:Show()
		end
		self[index].image:Show()
	end

	function g_WuShenTan_Guide_ShenLi_EmpowerTblWidget:Hide(index)
		if not self[index] then
			return
		end
		if self[index].imageline ~= nil then
			self[index].imageline:Hide()
		end
		self[index].image:Hide()
	end

	g_WuShenTan_Guide_ShenLi_SwitchBtnWidget[1] = WuShenTan_Guide_ShenLi_SwitchToPage1_Btn
	g_WuShenTan_Guide_ShenLi_SwitchBtnWidget[2] = WuShenTan_Guide_ShenLi_SwitchToPage2_Btn
	g_WuShenTan_Guide_ShenLi_SwitchBtnWidget[3] = WuShenTan_Guide_ShenLi_SwitchToPage3_Btn
end

-- Event
function WuShenTan_Guide_ShenLi_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_WuShenTan_Guide_ShenLi_UICOM then
		local nOperation = Get_XParam_INT(0)
		if nOperation == 1 then --打开界面 页签一
			g_WuShenTan_Guide_ShenLi_NowuiTab = Get_XParam_INT(1)
			g_WuShenTan_Guide_ShenLi_WorldEmpowerData = Get_XParam_INT(2)
			g_WuShenTan_Guide_ShenLi_WorldCacheEmpowerData = Get_XParam_INT(3)
			g_WuShenTan_Guide_ShenLi_GiftTbl[1].isGet = Get_XParam_INT(4)
			g_WuShenTan_Guide_ShenLi_GiftTbl[2].isGet = Get_XParam_INT(5)
			g_WuShenTan_Guide_ShenLi_GiftTbl[3].isGet = Get_XParam_INT(6)
			g_WuShenTan_Guide_ShenLi_GiftTbl[4].isGet = Get_XParam_INT(7)
			g_WuShenTan_Guide_ShenLi_GiftTbl[5].isGet = Get_XParam_INT(8)
			g_WuShenTan_Guide_ShenLi_GiftTbl[6].isGet = Get_XParam_INT(9)
			g_WuShenTan_Guide_ShenLi_AllZone_IsRewardGet = Get_XParam_INT(10)
			g_WuShenTan_Guide_ShenLi_SelfEmpowerData = Get_XParam_INT(11)
			g_WuShenTan_Guide_ShenLi_Origin_IsRewardGet = Get_XParam_INT(12)
			g_WuShenTan_Guide_ShenLi_IsInEmpowerMatchCacheTime = Get_XParam_INT(13)
			--之后的参数
			local mf7_10 = Get_XParam_INT(14)
			g_WuShenTan_Guide_ShenLi_GiftTbl[7].isGet = math.floor(mf7_10 / 1000)
			mf7_10 = math.mod(mf7_10, 1000)
			g_WuShenTan_Guide_ShenLi_GiftTbl[8].isGet = math.floor(mf7_10 / 100)
			mf7_10 = math.mod(mf7_10, 100)
			g_WuShenTan_Guide_ShenLi_GiftTbl[9].isGet = math.floor(mf7_10 / 10)
			mf7_10 = math.mod(mf7_10, 10)
			g_WuShenTan_Guide_ShenLi_GiftTbl[10].isGet = mf7_10
			g_WuShenTan_Guide_ShenLi_IsShowRewardBtn = Get_XParam_INT(15)
			WuShenTan_Guide_ShenLi_Update()
			this:Show()
		elseif nOperation == 2 then --关闭界面
			WuShenTan_Guide_ShenLi_Close()
		elseif nOperation == 3 then --刷新界面
			--g_WuShenTan_Guide_ShenLi_NowuiTab = Get_XParam_INT(1)
			g_WuShenTan_Guide_ShenLi_WorldEmpowerData = Get_XParam_INT(2)
			g_WuShenTan_Guide_ShenLi_WorldCacheEmpowerData = Get_XParam_INT(3)
			g_WuShenTan_Guide_ShenLi_GiftTbl[1].isGet = Get_XParam_INT(4)
			g_WuShenTan_Guide_ShenLi_GiftTbl[2].isGet = Get_XParam_INT(5)
			g_WuShenTan_Guide_ShenLi_GiftTbl[3].isGet = Get_XParam_INT(6)
			g_WuShenTan_Guide_ShenLi_GiftTbl[4].isGet = Get_XParam_INT(7)
			g_WuShenTan_Guide_ShenLi_GiftTbl[5].isGet = Get_XParam_INT(8)
			g_WuShenTan_Guide_ShenLi_GiftTbl[6].isGet = Get_XParam_INT(9)
			g_WuShenTan_Guide_ShenLi_AllZone_IsRewardGet = Get_XParam_INT(10)
			g_WuShenTan_Guide_ShenLi_SelfEmpowerData = Get_XParam_INT(11)
			g_WuShenTan_Guide_ShenLi_Origin_IsRewardGet = Get_XParam_INT(12)
			g_WuShenTan_Guide_ShenLi_IsInEmpowerMatchCacheTime = Get_XParam_INT(13)
			--之后的参数
			local mf7_10 = Get_XParam_INT(14)
			g_WuShenTan_Guide_ShenLi_GiftTbl[7].isGet = math.floor(mf7_10 / 1000)
			mf7_10 = math.mod(mf7_10, 1000)
			g_WuShenTan_Guide_ShenLi_GiftTbl[8].isGet = math.floor(mf7_10 / 100)
			mf7_10 = math.mod(mf7_10, 100)
			g_WuShenTan_Guide_ShenLi_GiftTbl[9].isGet = math.floor(mf7_10 / 10)
			mf7_10 = math.mod(mf7_10, 10)
			g_WuShenTan_Guide_ShenLi_GiftTbl[10].isGet = mf7_10
			g_WuShenTan_Guide_ShenLi_IsShowRewardBtn = Get_XParam_INT(15)
			WuShenTan_Guide_ShenLi_Update()
		end
	elseif event == "OPEN_WSTEMPOWER_RLORIGIN" then --显示页签二的本服个人排行榜 刷新排行榜也走的这里
		--tonumber(arg0) 传回来的是排行榜类型
		--tonumber(arg1) npcid 本功能不需要
		g_WuShenTan_Guide_ShenLi_NowuiTab = 2
		WuShenTan_Guide_ShenLi_Update()
		this:Show()
	elseif event == "OPEN_WSTEMPOWER_RLALLZONE" then --显示页签三的跨服服务器级排行榜 刷新排行榜也走的这里
		--tonumber(arg0) 传回来的是排行榜类型
		--tonumber(arg1) npcid 本功能不需要
		--获取本服的信息
		g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType = tonumber(arg0)--兼容三种全服排行榜
		if g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType ~= g_WuShenTan_Guide_ShenLi_AllZone_RankType
		and g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType ~= g_WuShenTan_Guide_ShenLi_AllZone_RankType_qx
		and g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType ~= g_WuShenTan_Guide_ShenLi_AllZone_RankType_sj then
			return 0
		end
		g_WuShenTan_Guide_ShenLi_NowuiTab = 3
		WuShenTan_Guide_ShenLi_Update()
		this:Show()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		WuShenTan_Guide_ShenLi_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		WuShenTan_Guide_ShenLi_Close()
	elseif event == "ADJEST_UI_POS" then
		WuShenTan_Guide_ShenLi_On_ResetPos()
	end

end

-- 重置界面位置
function WuShenTan_Guide_ShenLi_On_ResetPos()
	WuShenTan_Guide_ShenLi_Frame:SetProperty("UnifiedPosition", g_WuShenTan_Guide_ShenLi_Frame_UnifiedPosition)
end

function WuShenTan_Guide_ShenLi_InitialData()
	g_WuShenTan_Guide_ShenLi_NowuiTab              = 1
	g_WuShenTan_Guide_ShenLi_WorldEmpowerData      = 0
	g_WuShenTan_Guide_ShenLi_WorldCacheEmpowerData = 0
	g_WuShenTan_Guide_ShenLi_Origin_MyRank         = -1
	g_WuShenTan_Guide_ShenLi_AllZone_MyworldRank   = -1
	g_WuShenTan_Guide_ShenLi_Origin_RewardFlag     = 0
	for i = 1, g_WuShenTan_Guide_ShenLi_GiftTblCount, 1 do
		g_WuShenTan_Guide_ShenLi_GiftTbl[i].isGet = 0
	end
	g_WuShenTan_Guide_ShenLi_AllZone_IsRewardGet = 1
	g_WuShenTan_Guide_ShenLi_Origin_IsRewardGet = 1
	g_WuShenTan_Guide_ShenLi_SelfEmpowerData = 0
	g_WuShenTan_Guide_ShenLi_IsInEmpowerMatchCacheTime = 0
	g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType = 0
	g_WuShenTan_Guide_ShenLi_IsShowRewardBtn = 1
end

-- 关闭
function WuShenTan_Guide_ShenLi_Close()
	WuShenTan_Guide_ShenLi_InitialData()
	this:Hide()
end

-- 刷新界面
function WuShenTan_Guide_ShenLi_Update()
	if g_WuShenTan_Guide_ShenLi_NowuiTab == 1 then --页签一
		WuShenTan_Guide_ShenLi_SwitchTabWidget(g_WuShenTan_Guide_ShenLi_NowuiTab)
		--展示
		local nLastEmpowerBuffIdx = 0 --目前满足的阶段
		local nLastEmpowerCacheBuffIdx = 0
		for i = 1, g_WuShenTan_Guide_ShenLi_EmpowerTblCount, 1 do
			if g_WuShenTan_Guide_ShenLi_WorldEmpowerData >= g_WuShenTan_Guide_ShenLi_EmpowerTbl[i].needEmpowerData then
				g_WuShenTan_Guide_ShenLi_EmpowerTblWidget:Show(i)
				nLastEmpowerBuffIdx = i
			else
				g_WuShenTan_Guide_ShenLi_EmpowerTblWidget:Hide(i)
			end

			if g_WuShenTan_Guide_ShenLi_WorldCacheEmpowerData >= g_WuShenTan_Guide_ShenLi_EmpowerTbl[i].needEmpowerData then
				nLastEmpowerCacheBuffIdx = i
			end
		end
		if nLastEmpowerBuffIdx >= g_WuShenTan_Guide_ShenLi_EmpowerTblCount then--满了 阶段显示100%
			local percentStr = ScriptGlobal_Format("#{WSZH_260408_124}","100%")
			WuShenTan_Guide_ShenLiLevel_NextLevel_Percent:SetText(percentStr)
			WuShenTan_Guide_ShenLiLevel_EXPLace:SetProgress(1, 1)
		else
			local beginData = 0
			if nLastEmpowerBuffIdx == 0 then
				beginData = 0
			else
				beginData = g_WuShenTan_Guide_ShenLi_EmpowerTbl[nLastEmpowerBuffIdx].needEmpowerData
			end
			local endData = 0
			endData = g_WuShenTan_Guide_ShenLi_EmpowerTbl[nLastEmpowerBuffIdx+1].needEmpowerData
			local totolData = endData - beginData
			local subData = g_WuShenTan_Guide_ShenLi_WorldEmpowerData - beginData
			if subData > totolData then
				subData = totolData
			end
			if subData < 0 then
				subData = 0
			end
			local persent = 0
			if totolData > 0 then
				persent = math.floor((subData / totolData) * 100)
				--显示进度
				local percentStr = ScriptGlobal_Format("#{WSZH_260408_124}",tostring(persent).."%")
				WuShenTan_Guide_ShenLiLevel_NextLevel_Percent:SetText(percentStr)
				WuShenTan_Guide_ShenLiLevel_EXPLace:SetProgress(persent, 100)
			else
				WuShenTan_Guide_ShenLiLevel_EXPLace:SetProgress(0, 1)
			end
		end
		WuShenTan_Guide_ShenLiLevel_LevelFrame_1:Hide()
		WuShenTan_Guide_ShenLiLevel_LevelFrame_2:Hide()
		if nLastEmpowerBuffIdx >= 0 and nLastEmpowerBuffIdx < g_WuShenTan_Guide_ShenLi_EmpowerTblCount then
			WuShenTan_Guide_ShenLiLevel_LevelFrame_1:Show()
			WuShenTan_Guide_ShenLiLevel_LevelFrame_1_1:SetProperty("Image", "set:WuShenTan_Guide_ShenLi image:WuShenTan_Guide_ShenLi_BigNum"..tostring(nLastEmpowerBuffIdx))
		elseif nLastEmpowerBuffIdx == g_WuShenTan_Guide_ShenLi_EmpowerTblCount then
			WuShenTan_Guide_ShenLiLevel_LevelFrame_2:Show()
			WuShenTan_Guide_ShenLiLevel_LevelFrame_2_1:SetProperty("Image", "set:WuShenTan_Guide_ShenLi image:WuShenTan_Guide_ShenLi_BigNum1")
		end
		--显示造成伤害和收到伤害的加成用比赛时间点缓存的值
		if g_WuShenTan_Guide_ShenLi_IsInEmpowerMatchCacheTime == 1 then
			if nLastEmpowerCacheBuffIdx > 0 and nLastEmpowerCacheBuffIdx <= g_WuShenTan_Guide_ShenLi_EmpowerTblCount then
				local sDamageStr = ScriptGlobal_Format("#{WSZH_260408_110}",g_WuShenTan_Guide_ShenLi_EmpowerTbl[nLastEmpowerCacheBuffIdx].damageStr)
				local sDefenseStr = ScriptGlobal_Format("#{WSZH_260408_111}",g_WuShenTan_Guide_ShenLi_EmpowerTbl[nLastEmpowerCacheBuffIdx].defenseStr)
				WuShenTan_Guide_ShenLiLevel_AttackBuff_Num:SetText(sDamageStr)
				WuShenTan_Guide_ShenLiLevel_DefenceBuff_Num:SetText(sDefenseStr)
			else
				local sDamageStr = ScriptGlobal_Format("#{WSZH_260408_110}","0%")
				local sDefenseStr = ScriptGlobal_Format("#{WSZH_260408_111}","0%")
				WuShenTan_Guide_ShenLiLevel_AttackBuff_Num:SetText(sDamageStr)
				WuShenTan_Guide_ShenLiLevel_DefenceBuff_Num:SetText(sDefenseStr)
			end
		else
			if nLastEmpowerBuffIdx > 0 and nLastEmpowerBuffIdx <= g_WuShenTan_Guide_ShenLi_EmpowerTblCount then
				local sDamageStr = ScriptGlobal_Format("#{WSZH_260408_110}",g_WuShenTan_Guide_ShenLi_EmpowerTbl[nLastEmpowerBuffIdx].damageStr)
				local sDefenseStr = ScriptGlobal_Format("#{WSZH_260408_111}",g_WuShenTan_Guide_ShenLi_EmpowerTbl[nLastEmpowerBuffIdx].defenseStr)
				WuShenTan_Guide_ShenLiLevel_AttackBuff_Num:SetText(sDamageStr)
				WuShenTan_Guide_ShenLiLevel_DefenceBuff_Num:SetText(sDefenseStr)
			else
				local sDamageStr = ScriptGlobal_Format("#{WSZH_260408_110}","0%")
				local sDefenseStr = ScriptGlobal_Format("#{WSZH_260408_111}","0%")
				WuShenTan_Guide_ShenLiLevel_AttackBuff_Num:SetText(sDamageStr)
				WuShenTan_Guide_ShenLiLevel_DefenceBuff_Num:SetText(sDefenseStr)
			end
		end
		--累计奖励控件
		for i = 1, g_WuShenTan_Guide_ShenLi_GiftTblCount, 1 do
			local isGet = g_WuShenTan_Guide_ShenLi_GiftTbl[i].isGet
			local needPro = g_WuShenTan_Guide_ShenLi_GiftTbl[i].needpro
			local itemId = g_WuShenTan_Guide_ShenLi_GiftTbl[i].itemId
			local itemNum = g_WuShenTan_Guide_ShenLi_GiftTbl[i].itemNum
			if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(g_WuShenTan_Guide_ShenLi_KajiType) > 0 then
				needPro = g_WuShenTan_Guide_ShenLi_GiftTbl_kaji[i].needpro
				itemId = g_WuShenTan_Guide_ShenLi_GiftTbl_kaji[i].itemId
				itemNum = g_WuShenTan_Guide_ShenLi_GiftTbl_kaji[i].itemNum	
			elseif Player:GetData("IsOriginalJD") == 1 then
				needPro = g_WuShenTan_Guide_ShenLi_GiftTbl_sj[i].needpro
				itemId = g_WuShenTan_Guide_ShenLi_GiftTbl_sj[i].itemId
				itemNum = g_WuShenTan_Guide_ShenLi_GiftTbl_sj[i].itemNum
			elseif Player:GetData("Is2606S") == 1 then
				needPro = g_WuShenTan_Guide_ShenLi_GiftTbl_qx[i].needpro
				itemId = g_WuShenTan_Guide_ShenLi_GiftTbl_qx[i].itemId
				itemNum = g_WuShenTan_Guide_ShenLi_GiftTbl_qx[i].itemNum
			end
			if itemId ~= -1 then
				local theAction1 = DataPool:CreateBindActionItemForShow(itemId, itemNum)
				if theAction1:GetID() ~= 0 then
					g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].btn:SetActionItem(theAction1:GetID())
				end
				g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].btn:Show()
			else
				g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].btn:Hide()
			end
			if isGet == 1 then
				g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].getmask:Show()--已领取
				g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].animate:Hide()
				g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].blackmask:Hide()
			elseif isGet == 0 then
				g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].getmask:Hide()--未领取
				g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].animate:Hide()
				if g_WuShenTan_Guide_ShenLi_WorldEmpowerData >= needPro then--可领取
					g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].animate:Show()
					g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].blackmask:Hide()
				else
					--不可领取
					g_WuShenTan_Guide_ShenLi_GiftTblWidget[i].blackmask:Show()
				end
			end
		end
	elseif g_WuShenTan_Guide_ShenLi_NowuiTab == 2 then --页签二 本服个人排行榜
		WuShenTan_Guide_ShenLi_SwitchTabWidget(g_WuShenTan_Guide_ShenLi_NowuiTab)
		WuShenTan_Guide_ShenLi_Page_2_List:Clear()
		--获取本人的信息
		local myScore, myRewardFlag = DataPool:lua_GetJSRankingListMyInfo(g_WuShenTan_Guide_ShenLi_Origin_RankType)
		g_WuShenTan_Guide_ShenLi_Origin_RewardFlag = g_WuShenTan_Guide_ShenLi_Origin_IsRewardGet --不用通用排行榜的领奖标记
		local myNameStr = ScriptGlobal_Format("#{WSZH_260408_64}", Player:GetName())
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_Name:SetText(myNameStr)
		if myScore <= 0 then
			myScore = g_WuShenTan_Guide_ShenLi_SelfEmpowerData
		end
		local myValueStr = ScriptGlobal_Format("#{WSZH_260408_66}", tostring(myScore))
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_GongXian:SetText(tostring(myValueStr))
		--展示排行榜
		local myRank = -1 --本人是否上榜
		local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_WuShenTan_Guide_ShenLi_Origin_RankType)
		if nDataCount > 0 then
			for i = 0, nDataCount - 1 do
				local nRank, sName, nValue, _ = DataPool:lua_GetJSRankingListInfo(g_WuShenTan_Guide_ShenLi_Origin_RankType, i)
				local bValid, nGuid, _, _, _, _ = DataPool:lua_GetJSRankingListMemberInfo(g_WuShenTan_Guide_ShenLi_Origin_RankType, i, 0)
				if bValid == 1 and myRank < 0 then
					if nGuid == Player:GetGUID() then
						myRank = nRank + 1
					end
				end
				local titleId,rewardId,rewardNum = WuShenTan_Guide_ShenLi_GetOriginRankReward(nRank+1)
				local rankNameStr = ScriptGlobal_Format("#{WSZH_260408_64}", sName)
				local valueStr = ScriptGlobal_Format("#{WSZH_260408_66}", tostring(nValue))
				local widgetNum = nRank + 1
				if widgetNum > 3 then
					widgetNum = 4
				end
				local childName = "WuShenTan_Guide_ShenLi_Page_2_ListItem"
				local rankStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_Rank"
				local nameStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_Name"
				local gongxianStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXian"
				local gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXianReward"
				local gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXianReward2_1"
				local gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXianReward2_2"
				if widgetNum >= 2 then
					childName = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum)
					rankStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_Rank"
					nameStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_Name"
					gongxianStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXian"
					gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXianReward"
					gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_1"
					gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_2"
				end
				local ItemBar = WuShenTan_Guide_ShenLi_Page_2_List:AddChild(childName)
				if ItemBar ~= nil then
					if widgetNum > 3 then
						local rankvalueStr = ScriptGlobal_Format("#{WSZH_260408_62}", tostring(nRank+1))
						ItemBar:GetSubItem(rankStr):SetText(rankvalueStr)
					end
					ItemBar:GetSubItem(nameStr):SetText(rankNameStr)
					ItemBar:GetSubItem(gongxianStr):SetText(valueStr)
					ItemBar:GetSubItem(gongxianrewardStr):Hide()
					ItemBar:GetSubItem(gongxianreward1Str):Hide()
					ItemBar:GetSubItem(gongxianreward2Str):Hide()
					if titleId ~= -1 and rewardId ~= -1 then
						local titleAction = DataPool:CreateBindActionItemForShow(titleId, 1)
						if titleAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianreward1Str):Show()
							ItemBar:GetSubItem(gongxianreward1Str):SetActionItem(titleAction:GetID())
						end
						local theItemAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
						if theItemAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianreward2Str):Show()
							ItemBar:GetSubItem(gongxianreward2Str):SetActionItem(theItemAction:GetID())
						end
					elseif titleId ~= -1 then
						local theAction = DataPool:CreateBindActionItemForShow(titleId, 1)
						if theAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianrewardStr):Show()
							ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
						end
					elseif rewardId ~= -1 then
						local theAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
						if theAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianrewardStr):Show()
							ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
						end
					end
				end
			end
			--剩下的位置填充虚位以待
			local nTableListCount = DataPool:LuaFnGetRankingList_ListCount(g_WuShenTan_Guide_ShenLi_Origin_RankType)
			if nDataCount < nTableListCount then
				for i = nDataCount+1, nTableListCount, 1 do
					local widgetNum = i
					if widgetNum > 3 then
						widgetNum = 4
					end
					local childName = "WuShenTan_Guide_ShenLi_Page_2_ListItem"
					local rankStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_Rank"
					local nameStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_Name"
					local gongxianStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXian"
					local gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXianReward"
					local gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXianReward2_1"
					local gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXianReward2_2"
					if widgetNum >= 2 then
						childName = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum)
						rankStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_Rank"
						nameStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_Name"
						gongxianStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXian"
						gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXianReward"
						gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_1"
						gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_2"
					end
					local ItemBar = WuShenTan_Guide_ShenLi_Page_2_List:AddChild(childName)
					if ItemBar ~= nil then
						if widgetNum > 3 then
							local rankvalueStr = ScriptGlobal_Format("#{WSZH_260408_62}", tostring(i))
							ItemBar:GetSubItem(rankStr):SetText(rankvalueStr)
						end
						ItemBar:GetSubItem(nameStr):SetText("#{WSZH_260408_95}")
						ItemBar:GetSubItem(gongxianStr):SetText("")
						local titleId,rewardId,rewardNum = WuShenTan_Guide_ShenLi_GetOriginRankReward(i)
						ItemBar:GetSubItem(gongxianrewardStr):Hide()
						ItemBar:GetSubItem(gongxianreward1Str):Hide()
						ItemBar:GetSubItem(gongxianreward2Str):Hide()
						if titleId ~= -1 and rewardId ~= -1 then
							local titleAction = DataPool:CreateBindActionItemForShow(titleId, 1)
							if titleAction:GetID() ~= 0 then
								ItemBar:GetSubItem(gongxianreward1Str):Show()
								ItemBar:GetSubItem(gongxianreward1Str):SetActionItem(titleAction:GetID())
							end
							local theItemAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
							if theItemAction:GetID() ~= 0 then
								ItemBar:GetSubItem(gongxianreward2Str):Show()
								ItemBar:GetSubItem(gongxianreward2Str):SetActionItem(theItemAction:GetID())
							end
						elseif titleId ~= -1 then
							local theAction = DataPool:CreateBindActionItemForShow(titleId, rewardNum)
							if theAction:GetID() ~= 0 then
								ItemBar:GetSubItem(gongxianrewardStr):Show()
								ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
							end
						elseif rewardId ~= -1 then
							local theAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
							if theAction:GetID() ~= 0 then
								ItemBar:GetSubItem(gongxianrewardStr):Show()
								ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
							end
						end
					end
				end
			end
		else
			--全部显示虚位以待
			local nTableListCount = DataPool:LuaFnGetRankingList_ListCount(g_WuShenTan_Guide_ShenLi_Origin_RankType)
			for i = 1, nTableListCount, 1 do
				local widgetNum = i
				if widgetNum > 3 then
					widgetNum = 4
				end
				local childName = "WuShenTan_Guide_ShenLi_Page_2_ListItem"
				local rankStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_Rank"
				local nameStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_Name"
				local gongxianStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXian"
				local gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXianReward"
				local gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXianReward2_1"
				local gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem_GongXianReward2_2"
				if widgetNum >= 2 then
					childName = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum)
					rankStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_Rank"
					nameStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_Name"
					gongxianStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXian"
					gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXianReward"
					gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_1"
					gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_2_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_2"
				end
				local ItemBar = WuShenTan_Guide_ShenLi_Page_2_List:AddChild(childName)
				if ItemBar ~= nil then
					if widgetNum > 3 then
						local rankvalueStr = ScriptGlobal_Format("#{WSZH_260408_62}", tostring(i))
						ItemBar:GetSubItem(rankStr):SetText(rankvalueStr)
					end
					ItemBar:GetSubItem(nameStr):SetText("#{WSZH_260408_95}")
					ItemBar:GetSubItem(gongxianStr):SetText("")
					local titleId,rewardId,rewardNum = WuShenTan_Guide_ShenLi_GetOriginRankReward(i)
					ItemBar:GetSubItem(gongxianrewardStr):Hide()
					ItemBar:GetSubItem(gongxianreward1Str):Hide()
					ItemBar:GetSubItem(gongxianreward2Str):Hide()
					if titleId ~= -1 and rewardId ~= -1 then
						local titleAction = DataPool:CreateBindActionItemForShow(titleId, 1)
						if titleAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianreward1Str):Show()
							ItemBar:GetSubItem(gongxianreward1Str):SetActionItem(titleAction:GetID())
						end
						local theItemAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
						if theItemAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianreward2Str):Show()
							ItemBar:GetSubItem(gongxianreward2Str):SetActionItem(theItemAction:GetID())
						end
					elseif titleId ~= -1 then
						local theAction = DataPool:CreateBindActionItemForShow(titleId, 1)
						if theAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianrewardStr):Show()
							ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
						end
					elseif rewardId ~= -1 then
						local theAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
						if theAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianrewardStr):Show()
							ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
						end
					end
				end
			end
		end
		for i = 1, g_WuShenTan_Guide_ShenLi_Origin_MyRankCount, 1 do
			g_WuShenTan_Guide_ShenLi_Origin_MyRankWidget[i]:Hide()
		end
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_Rank4:Show()
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_Rank4:SetText("#{WSZH_260408_72}") --暂未上榜
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_GetBtn:Show()
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_GetBtn:Disable()
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_OK:Hide()
		if g_WuShenTan_Guide_ShenLi_Origin_MyRankWidget[myRank] ~= nil then
			g_WuShenTan_Guide_ShenLi_Origin_MyRankWidget[myRank]:Show()
			WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_Rank4:Hide()
		end
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton1:Hide()
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton2:Hide()
		WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton3:Hide()
		if myRank ~= -1 then
			local myTitleId,myRewardId,rewardNum = WuShenTan_Guide_ShenLi_GetOriginRankReward(myRank)
			if myTitleId ~= -1 and myRewardId ~= -1 then
				local titleAction = DataPool:CreateBindActionItemForShow(myTitleId, 1)
				if titleAction:GetID() ~= 0 then
					WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton2:Show()
					WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton2:SetActionItem(titleAction:GetID())
				end
				local theItemAction = DataPool:CreateBindActionItemForShow(myRewardId, rewardNum)
				if theItemAction:GetID() ~= 0 then
					WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton3:Show()
					WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton3:SetActionItem(theItemAction:GetID())
				end
			elseif myTitleId ~= -1 then
				local theAction = DataPool:CreateBindActionItemForShow(myTitleId, 1)
				if theAction:GetID() ~= 0 then
					WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton1:Show()
					WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton1:SetActionItem(theAction:GetID())
				end
			elseif myRewardId ~= -1 then
				local theAction = DataPool:CreateBindActionItemForShow(myRewardId, rewardNum)
				if theAction:GetID() ~= 0 then
					WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton1:Show()
					WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_ActionButton1:SetActionItem(theAction:GetID())
				end
			end
			local myRankStr = ScriptGlobal_Format("#{WSZH_260408_62}", tostring(myRank))
			WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_Rank4:SetText(myRankStr)
			if g_WuShenTan_Guide_ShenLi_Origin_RewardFlag == 0 then
				WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_GetBtn:Enable()
			elseif g_WuShenTan_Guide_ShenLi_Origin_RewardFlag == 1 then
				WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_GetBtn:Hide()
				WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_OK:Show()
			end
		end
		if g_WuShenTan_Guide_ShenLi_IsShowRewardBtn == 0 then
			WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_GetBtn:Hide()
			WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_TimeTips:Show()
		else
			WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_TimeTips:Hide()
		end
		g_WuShenTan_Guide_ShenLi_Origin_MyRank = myRank --缓存一下我的排名
	elseif g_WuShenTan_Guide_ShenLi_NowuiTab == 3 then --页签三
		--跨服排行榜
		WuShenTan_Guide_ShenLi_SwitchTabWidget(g_WuShenTan_Guide_ShenLi_NowuiTab)
		WuShenTan_Guide_ShenLi_Page_3_List:Clear()
		--获取本服的信息
		if g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType == 0 then
			return 0
		end
		local myWorldScore, _ = DataPool:lua_GetJSRankingListMyInfo(g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType)
		local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
		local sMyWorldName = "服务器名称"
		if selfZoneWorldID ~= 0 then
			sMyWorldName = DataPool:GetServerName(tonumber(selfZoneWorldID))
		end
		local myWorldNameStr = ScriptGlobal_Format("#{WSZH_260408_64}", sMyWorldName)
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_Server:SetText(myWorldNameStr)
		if myWorldScore <= 0 then
			myWorldScore = g_WuShenTan_Guide_ShenLi_WorldEmpowerData
		end
		local myValueStr = ScriptGlobal_Format("#{WSZH_260408_66}", tostring(myWorldScore))
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_GongXian:SetText(tostring(myValueStr))
		--展示排行榜
		local myWorldRank = -1 --本服是否上榜
		local nDataCount = DataPool:lua_GetJSRankingListDataCount(g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType)
		if nDataCount > 0 then
			for i = 0, nDataCount - 1 do
				local nRank, _, nValue, _ = DataPool:lua_GetJSRankingListInfo(g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType, i)
				local nZwid = DataPool:lua_GetJSRankingListParam(g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType, i, 2)
				if nRank == -1 or nZwid == nil then --检验缓存是否对的上g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType
					return 0
				end
				if nZwid == selfZoneWorldID then
					myWorldRank = nRank + 1
				end
				local sWorldName = DataPool:GetServerName(tonumber(nZwid))
				local worldNameStr = ScriptGlobal_Format("#{WSZH_260408_64}", sWorldName)
				local valueStr = ScriptGlobal_Format("#{WSZH_260408_66}", tostring(nValue))
				local titleId,rewardId,rewardNum = WuShenTan_Guide_ShenLi_GetAllZoneRankReward(nRank+1)
				local widgetNum = nRank + 1
				if widgetNum > 3 then
					widgetNum = 4
				end
				local childName = "WuShenTan_Guide_ShenLi_Page_3_ListItem"
				local rankStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_Rank"
				local nameStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_Server"
				local gongxianStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXian"
				local gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXianReward"
				local gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXianReward2_1"
				local gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXianReward2_2"
				if widgetNum >= 2 then
					childName = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum)
					rankStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_Rank"
					nameStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_Server"
					gongxianStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXian"
					gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXianReward"
					gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_1"
					gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_2"
				end
				local ItemBar = WuShenTan_Guide_ShenLi_Page_3_List:AddChild(childName)
				if ItemBar ~= nil then
					if widgetNum > 3 then
						local rankvalueStr = ScriptGlobal_Format("#{WSZH_260408_62}", tostring(nRank + 1))
						ItemBar:GetSubItem(rankStr):SetText(rankvalueStr)
					end
					ItemBar:GetSubItem(nameStr):SetText(worldNameStr)
					ItemBar:GetSubItem(gongxianStr):SetText(valueStr)
					ItemBar:GetSubItem(gongxianrewardStr):Hide()
					ItemBar:GetSubItem(gongxianreward1Str):Hide()
					ItemBar:GetSubItem(gongxianreward2Str):Hide()
					if titleId ~= -1 and rewardId ~= -1 then
						local titleAction = DataPool:CreateBindActionItemForShow(titleId, 1)
						if titleAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianreward1Str):Show()
							ItemBar:GetSubItem(gongxianreward1Str):SetActionItem(titleAction:GetID())
						end
						local theItemAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
						if theItemAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianreward2Str):Show()
							ItemBar:GetSubItem(gongxianreward2Str):SetActionItem(theItemAction:GetID())
						end
					elseif titleId ~= -1 then
						local theAction = DataPool:CreateBindActionItemForShow(titleId, 1)
						if theAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianrewardStr):Show()
							ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
						end
					elseif rewardId ~= -1 then
						local theAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
						if theAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianrewardStr):Show()
							ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
						end
					end
				end
			end
			--剩下的位置填充虚位以待
			local nTableListCount = DataPool:LuaFnGetRankingList_ListCount(g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType)
			if nDataCount < nTableListCount then
				for i = nDataCount+1, nTableListCount, 1 do
					local widgetNum = i
					if widgetNum > 3 then
						widgetNum = 4
					end
					local childName = "WuShenTan_Guide_ShenLi_Page_3_ListItem"
					local rankStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_Rank"
					local nameStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_Server"
					local gongxianStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXian"
					local gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXianReward"
					local gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXianReward2_1"
					local gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXianReward2_2"
					if widgetNum >= 2 then
						childName = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum)
						rankStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_Rank"
						nameStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_Server"
						gongxianStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXian"
						gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXianReward"
						gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_1"
						gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_2"
					end
					local ItemBar = WuShenTan_Guide_ShenLi_Page_3_List:AddChild(childName)
					if ItemBar ~= nil then
						if widgetNum > 3 then
							local rankvalueStr = ScriptGlobal_Format("#{WSZH_260408_62}", tostring(i))
							ItemBar:GetSubItem(rankStr):SetText(rankvalueStr)
						end
						ItemBar:GetSubItem(nameStr):SetText("#{WSZH_260408_95}")
						ItemBar:GetSubItem(gongxianStr):SetText("")
						local titleId,rewardId,rewardNum = WuShenTan_Guide_ShenLi_GetAllZoneRankReward(i)
						ItemBar:GetSubItem(gongxianrewardStr):Hide()
						ItemBar:GetSubItem(gongxianreward1Str):Hide()
						ItemBar:GetSubItem(gongxianreward2Str):Hide()
						if titleId ~= -1 and rewardId ~= -1 then
							local titleAction = DataPool:CreateBindActionItemForShow(titleId, 1)
							if titleAction:GetID() ~= 0 then
								ItemBar:GetSubItem(gongxianreward1Str):Show()
								ItemBar:GetSubItem(gongxianreward1Str):SetActionItem(titleAction:GetID())
							end
							local theItemAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
							if theItemAction:GetID() ~= 0 then
								ItemBar:GetSubItem(gongxianreward2Str):Show()
								ItemBar:GetSubItem(gongxianreward2Str):SetActionItem(theItemAction:GetID())
							end
						elseif titleId ~= -1 then
							local theAction = DataPool:CreateBindActionItemForShow(titleId, 1)
							if theAction:GetID() ~= 0 then
								ItemBar:GetSubItem(gongxianrewardStr):Show()
								ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
							end
						elseif rewardId ~= -1 then
							local theAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
							if theAction:GetID() ~= 0 then
								ItemBar:GetSubItem(gongxianrewardStr):Show()
								ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
							end
						end
					end
				end
			end
		else
			--全部显示虚位以待
			local nTableListCount = DataPool:LuaFnGetRankingList_ListCount(g_WuShenTan_Guide_ShenLi_temp_AllZone_RankType)
			for i = 1, nTableListCount, 1 do
				local widgetNum = i
				if widgetNum > 3 then
					widgetNum = 4
				end
				local childName = "WuShenTan_Guide_ShenLi_Page_3_ListItem"
				local rankStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_Rank"
				local nameStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_Server"
				local gongxianStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXian"
				local gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXianReward"
				local gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXianReward2_1"
				local gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem_GongXianReward2_2"
				if widgetNum >= 2 then
					childName = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum)
					rankStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_Rank"
					nameStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_Server"
					gongxianStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXian"
					gongxianrewardStr = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXianReward"
					gongxianreward1Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_1"
					gongxianreward2Str = "WuShenTan_Guide_ShenLi_Page_3_ListItem" .. tostring(widgetNum) .. "_GongXianReward2_2"
				end
				local ItemBar = WuShenTan_Guide_ShenLi_Page_3_List:AddChild(childName)
				if ItemBar ~= nil then
					if widgetNum > 3 then
						local rankvalueStr = ScriptGlobal_Format("#{WSZH_260408_62}", tostring(i))
						ItemBar:GetSubItem(rankStr):SetText(rankvalueStr)
					end
					ItemBar:GetSubItem(nameStr):SetText("#{WSZH_260408_95}")
					ItemBar:GetSubItem(gongxianStr):SetText("")
					local titleId,rewardId,rewardNum = WuShenTan_Guide_ShenLi_GetAllZoneRankReward(i)
					ItemBar:GetSubItem(gongxianrewardStr):Hide()
					ItemBar:GetSubItem(gongxianreward1Str):Hide()
					ItemBar:GetSubItem(gongxianreward2Str):Hide()
					if titleId ~= -1 and rewardId ~= -1 then
						local titleAction = DataPool:CreateBindActionItemForShow(titleId, 1)
						if titleAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianreward1Str):Show()
							ItemBar:GetSubItem(gongxianreward1Str):SetActionItem(titleAction:GetID())
						end
						local theItemAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
						if theItemAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianreward2Str):Show()
							ItemBar:GetSubItem(gongxianreward2Str):SetActionItem(theItemAction:GetID())
						end
					elseif titleId ~= -1 then
						local theAction = DataPool:CreateBindActionItemForShow(titleId, 1)
						if theAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianrewardStr):Show()
							ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
						end
					elseif rewardId ~= -1 then
						local theAction = DataPool:CreateBindActionItemForShow(rewardId, rewardNum)
						if theAction:GetID() ~= 0 then
							ItemBar:GetSubItem(gongxianrewardStr):Show()
							ItemBar:GetSubItem(gongxianrewardStr):SetActionItem(theAction:GetID())
						end
					end
				end
			end
		end
		for i = 1, g_WuShenTan_Guide_ShenLi_AllZone_MyRankCount, 1 do
			g_WuShenTan_Guide_ShenLi_AllZone_MyRankWidget[i]:Hide()
		end
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_Rank4:Show()
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_Rank4:SetText("#{WSZH_260408_72}") --暂未上榜
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_GetBtn:Show()
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_GetBtn:Disable()
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_OK:Hide()
		if g_WuShenTan_Guide_ShenLi_AllZone_MyRankWidget[myWorldRank] ~= nil then
			g_WuShenTan_Guide_ShenLi_AllZone_MyRankWidget[myWorldRank]:Show()
			WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_Rank4:Hide()
		end
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton1:Hide()
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton2:Hide()
		WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton3:Hide()
		if myWorldRank ~= -1 then
			local myTitleId,myRewardId,rewardNum = WuShenTan_Guide_ShenLi_GetAllZoneRankReward(myWorldRank)
			if myTitleId ~= -1 and myRewardId ~= -1 then
				local titleAction = DataPool:CreateBindActionItemForShow(myTitleId, 1)
				if titleAction:GetID() ~= 0 then
					WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton2:Show()
					WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton2:SetActionItem(titleAction:GetID())
				end
				local theItemAction = DataPool:CreateBindActionItemForShow(myRewardId, rewardNum)
				if theItemAction:GetID() ~= 0 then
					WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton3:Show()
					WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton3:SetActionItem(theItemAction:GetID())
				end
			elseif myTitleId ~= -1 then
				local theAction = DataPool:CreateBindActionItemForShow(myTitleId, 1)
				if theAction:GetID() ~= 0 then
					WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton1:Show()
					WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton1:SetActionItem(theAction:GetID())
				end
			elseif myRewardId ~= -1 then
				local theAction = DataPool:CreateBindActionItemForShow(myRewardId, rewardNum)
				if theAction:GetID() ~= 0 then
					WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton1:Show()
					WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_ActionButton1:SetActionItem(theAction:GetID())
				end
			end
			local myRankStr = ScriptGlobal_Format("#{WSZH_260408_62}", tostring(myWorldRank))
			WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_Rank4:SetText(myRankStr)
			--领奖按钮
			if g_WuShenTan_Guide_ShenLi_AllZone_IsRewardGet == 0 then
				WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_GetBtn:Enable()
			elseif g_WuShenTan_Guide_ShenLi_AllZone_IsRewardGet == 1 then
				WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_GetBtn:Hide()
				WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_OK:Show()
			end
		end
		if g_WuShenTan_Guide_ShenLi_IsShowRewardBtn == 0 then
			WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_GetBtn:Hide()
			WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_TimeTips:Show()
		else
			WuShenTan_Guide_ShenLi_Page_3_PlayerInfo_TimeTips:Hide()
		end
		g_WuShenTan_Guide_ShenLi_AllZone_MyworldRank = myWorldRank --缓存一下本服的排名
	end

	if g_WuShenTan_Guide_ShenLi_SwitchBtnWidget[g_WuShenTan_Guide_ShenLi_NowuiTab] ~= nil then
		g_WuShenTan_Guide_ShenLi_SwitchBtnWidget[g_WuShenTan_Guide_ShenLi_NowuiTab]:SetCheck(1);
	end
end

--领取本服个人排行榜的奖励
function WuShenTan_Guide_ShenLi_Page_2_PlayerInfo_GetBtn_OnClick()
	--等级
	if Player:GetLevel() < g_WuShenTan_Guide_ShenLi_Origin_Level then
		PushDebugMessage("#{WSZH_260408_27}")
		return 0
	end
	--是否上榜
	if g_WuShenTan_Guide_ShenLi_Origin_MyRank == -1 then
		PushDebugMessage("#{WSZH_260408_89}")
		return 0
	end
	--奖励是否已领取
	if g_WuShenTan_Guide_ShenLi_Origin_IsRewardGet == 1 then
		PushDebugMessage("#{WSZH_260408_84}")
		return 0
	end
	--领奖 需要支持原服server和t服server都能领取奖励 所以不走通用排行榜领奖的客户端接口
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenEmpowerUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 7)
	Set_XSCRIPT_Parameter(1, g_WuShenTan_Guide_ShenLi_Origin_MyRank)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function WuShenTan_Guide_ShenLi_AllZoneGetReward()
	--等级
	if Player:GetLevel() < g_WuShenTan_Guide_ShenLi_Origin_Level then
		PushDebugMessage("#{WSZH_260408_27}")
		return 0
	end
	--是否上榜
	if g_WuShenTan_Guide_ShenLi_AllZone_MyworldRank == -1 then
		PushDebugMessage("#{WSZH_260408_89}")
		return 0
	end
	--奖励是否已领取
	if g_WuShenTan_Guide_ShenLi_AllZone_IsRewardGet == 1 then
		PushDebugMessage("#{WSZH_260408_84}")
		return 0
	end
	--服务器级排行榜不支持通用排行榜领奖逻辑 需自己写
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenEmpowerUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 6)
	Set_XSCRIPT_Parameter(1, g_WuShenTan_Guide_ShenLi_AllZone_MyworldRank)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

-- 切换页签一
function WuShenTan_Guide_ShenLi_SwitchToPage1_Btn_OnClick()
	--等级
	if Player:GetLevel() < g_WuShenTan_Guide_ShenLi_Origin_Level then
		PushDebugMessage("#{WSZH_260408_02}")
		return 0
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenEmpowerUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 1)
	Set_XSCRIPT_Parameter(1, 0)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

-- 切换页签二
function WuShenTan_Guide_ShenLi_SwitchToPage2_Btn_OnClick()
	--等级
	if Player:GetLevel() < g_WuShenTan_Guide_ShenLi_Origin_Level then
		PushDebugMessage("#{WSZH_260408_02}")
		return 0
	end
	if g_WuShenTan_Guide_ShenLi_SwitchBtnWidget[g_WuShenTan_Guide_ShenLi_NowuiTab] ~= nil then
		g_WuShenTan_Guide_ShenLi_SwitchBtnWidget[g_WuShenTan_Guide_ShenLi_NowuiTab]:SetCheck(1);
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenEmpowerUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 2)
	Set_XSCRIPT_Parameter(1, 0)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--切换页签三
function WuShenTan_Guide_ShenLi_SwitchToPage3_Btn_OnClick()
	--等级
	if Player:GetLevel() < g_WuShenTan_Guide_ShenLi_Origin_Level then
		PushDebugMessage("#{WSZH_260408_02}")
		return 0
	end
	if g_WuShenTan_Guide_ShenLi_SwitchBtnWidget[g_WuShenTan_Guide_ShenLi_NowuiTab] ~= nil then
		g_WuShenTan_Guide_ShenLi_SwitchBtnWidget[g_WuShenTan_Guide_ShenLi_NowuiTab]:SetCheck(1);
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenEmpowerUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 3)
	Set_XSCRIPT_Parameter(1, 0)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--点击神力祝福按钮
function WuShenTan_Guide_ShenLiZhuFu_Btn_OnClick()
	
end

--点击刷新按钮
function WuShenTan_Guide_ShenLi_ListRefresh_Btn_OnClick()
	--等级
	if Player:GetLevel() < g_WuShenTan_Guide_ShenLi_Origin_Level then
		PushDebugMessage("#{WSZH_260408_02}")
		return 0
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenEmpowerUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, g_WuShenTan_Guide_ShenLi_NowuiTab)
	Set_XSCRIPT_Parameter(1, 1)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function WuShenTan_Guide_ShenLiZhuFu_RewardBtnClick(index)
	if index < 1 or index > g_WuShenTan_Guide_ShenLi_GiftTblCount then
		return 0
	end
	--等级
	if Player:GetLevel() < g_WuShenTan_Guide_ShenLi_Origin_Level then
		PushDebugMessage("#{WSZH_260408_02}")
		return 0
	end
	if g_WuShenTan_Guide_ShenLi_NowuiTab ~= 1 then
		return 0
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenEmpowerUI")
	Set_XSCRIPT_ScriptID(212256)
	Set_XSCRIPT_Parameter(0, 5) --领取累计奖励
	Set_XSCRIPT_Parameter(1, index)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--页签一和页签二的控件总显隐
function WuShenTan_Guide_ShenLi_SwitchTabWidget(tabIndex)
	if tabIndex == 1 then --显示页签一的控件 隐藏其他
		WuShenTan_Guide_ShenLi_Page_1:Show()
		WuShenTan_Guide_ShenLi_Page_2:Hide()
		WuShenTan_Guide_ShenLi_Page_3:Hide()
	elseif tabIndex == 2 then --显示页签二的控件 隐藏其他
		WuShenTan_Guide_ShenLi_Page_1:Hide()
		WuShenTan_Guide_ShenLi_Page_2:Show()
		WuShenTan_Guide_ShenLi_Page_3:Hide()
	elseif tabIndex == 3 then --显示页签三的控件 隐藏其他
		WuShenTan_Guide_ShenLi_Page_1:Hide()
		WuShenTan_Guide_ShenLi_Page_2:Hide()
		WuShenTan_Guide_ShenLi_Page_3:Show()
	end
end

--根据排名获得个人排行榜奖励的展示道具id:称号,道具
function WuShenTan_Guide_ShenLi_GetOriginRankReward(nRank)
	local nItemId = -1
	local nTitleId = -1
	local nItemNum = 1
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(g_WuShenTan_Guide_ShenLi_KajiType) > 0 then
		if nRank == 1 then
			nItemId = 10147495
			nItemNum = 1
			nTitleId = 39925464
		elseif nRank >= 2 and nRank <= 3 then
			nItemId = 10147494
			nItemNum = 1
			nTitleId = 39925465
		elseif nRank >= 4 and nRank <= 10 then
			nItemId = 10147493
			nItemNum = 1
			nTitleId = 39925466
		elseif nRank >= 11 and nRank <= 30 then
			nItemId = -1
			nTitleId = 39925467
		elseif nRank >= 31 and nRank <= 50 then
			nItemId = -1
			nTitleId = 39925468
		else
			nItemId = -1
			nTitleId = -1
		end
	elseif Player:GetData("IsOriginalJD") == 1 then
		if nRank == 1 then
			nItemId = 10147495
			nItemNum = 1
			nTitleId = 39925464
		elseif nRank >= 2 and nRank <= 3 then
			nItemId = 10147494
			nItemNum = 1
			nTitleId = 39925465
		elseif nRank >= 4 and nRank <= 10 then
			nItemId = 10147493
			nItemNum = 1
			nTitleId = 39925466
		elseif nRank >= 11 and nRank <= 30 then
			nItemId = -1
			nTitleId = 39925467
		elseif nRank >= 31 and nRank <= 50 then
			nItemId = -1
			nTitleId = 39925468
		else
			nItemId = -1
			nTitleId = -1
		end
	elseif Player:GetData("Is2606S") == 1 then
		nItemId = -1
		nTitleId = -1
	else
		if nRank == 1 then
			nItemId = 10147495
			nItemNum = 1
			nTitleId = 39925464
		elseif nRank >= 2 and nRank <= 3 then
			nItemId = 10147494
			nItemNum = 1
			nTitleId = 39925465
		elseif nRank >= 4 and nRank <= 10 then
			nItemId = 10147493
			nItemNum = 1
			nTitleId = 39925466
		elseif nRank >= 11 and nRank <= 30 then
			nItemId = -1
			nTitleId = 39925467
		elseif nRank >= 31 and nRank <= 50 then
			nItemId = -1
			nTitleId = 39925468
		else
			nItemId = -1
			nTitleId = -1
		end
	end
	return nTitleId,nItemId,nItemNum
end

--根据排名获得服务器排行榜奖励的展示道具id:称号,道具
function WuShenTan_Guide_ShenLi_GetAllZoneRankReward(nRank)
	local nItemId = -1
	local nItemNum = 1
	local nTitleId = -1
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(g_WuShenTan_Guide_ShenLi_KajiType) > 0 then
		if nRank == 1 then
			nItemId = 38008844
			nItemNum = 8
			nTitleId = 39925463
		elseif nRank == 2 then
			nItemId = 38008844
			nItemNum = 4
			nTitleId = -1
		elseif nRank == 3 then
			nItemId = 38008844
			nItemNum = 2
			nTitleId = -1
		else
			nItemId = -1
			nTitleId = -1
		end
	elseif Player:GetData("IsOriginalJD") == 1 then
		if nRank == 1 then
			nItemId = 38008844
			nItemNum = 8
			nTitleId = 39925463
		elseif nRank == 2 then
			nItemId = 38008844
			nItemNum = 4
			nTitleId = -1
		elseif nRank == 3 then
			nItemId = 38008844
			nItemNum = 2
			nTitleId = -1
		else
			nItemId = -1
			nTitleId = -1
		end
	elseif Player:GetData("Is2606S") == 1 then
		nItemId = -1
		nTitleId = -1
	else
		if nRank == 1 then
			nItemId = 38008838
			nItemNum = 1
			nTitleId = 39925463
		elseif nRank == 2 then
			nItemId = 38008839
			nItemNum = 1
			nTitleId = -1
		elseif nRank == 3 then
			nItemId = 38008840
			nItemNum = 1
			nTitleId = -1
		else
			nItemId = -1
			nTitleId = -1
		end
	end
	return nTitleId,nItemId,nItemNum
end

function WuShenTan_Guide_ShenLi_HelpBtn_OnClick()
	PushEvent("QUEST_HELPINFO", "#{WSZH_260408_41}")
end