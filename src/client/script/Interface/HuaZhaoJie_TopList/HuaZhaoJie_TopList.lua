-- HuaZhaoJie_TopList 2024Q1 花朝节排行榜 2023-12-27 by lishilong
-- !!!reloadscript =HuaZhaoJie_TopList
--

local g_HuaZhaoJie_TopList_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= -1
local g_nComfirmParam2		= -1

local g_nUICommandID		= 79007701
local g_nComfirmUICommandID	= 79007702

-- 自动寻路信息
local g_nAutoGoPosX			= 280
local g_nAutoGoPosZ			= 270
local g_nAutoGoSceneID		= 0
local g_nAutoGoNPCName		= "花意浓"
-- 活动限制等级
local g_nLimitLevel			= 30

-- local g_nMDForScore		= 2972
-- local g_nMDForScore		= 3151
local g_nMDForScore			= 3373
local g_nMaxItemNum			= 20
local g_tRankImage			= 
{
	[1] 	= "set:HuaZhaoJiePic_TopList image:HuaZhaoJiePic_TopList_1",
	[2] 	= "set:HuaZhaoJiePic_TopList image:HuaZhaoJiePic_TopList_2",
	[3] 	= "set:HuaZhaoJiePic_TopList image:HuaZhaoJiePic_TopList_3",
}

local g_strCommonRankImage	= "set:HuaZhaoJiePic_TopList image:HuaZhaoJiePic_TopList_NumBK"

local g_tStrRankDic			= 
{
	[1] 	= "",
	[2] 	= "",
	[3] 	= "",
	[4] 	= "#{HZJPH_231222_49}",
	[5] 	= "#{HZJPH_231222_50}",
	[6] 	= "#{HZJPH_231222_51}",
	[7] 	= "#{HZJPH_231222_52}",
	[8] 	= "#{HZJPH_231222_53}",
	[9] 	= "#{HZJPH_231222_54}",
	[10] 	= "#{HZJPH_231222_55}",
	[11] 	= "#{HZJPH_231222_56}",
	[12] 	= "#{HZJPH_231222_57}",
	[13] 	= "#{HZJPH_231222_58}",
	[14] 	= "#{HZJPH_231222_59}",
	[15] 	= "#{HZJPH_231222_60}",
	[16] 	= "#{HZJPH_231222_61}",
	[17] 	= "#{HZJPH_231222_62}",
	[18] 	= "#{HZJPH_231222_63}",
	[19] 	= "#{HZJPH_231222_64}",
	[20] 	= "#{HZJPH_231222_65}",
}

-- 未上榜的排名图片
local g_strRankStrForNoTopList = "#{HZJPH_231222_66}"

-- 排名奖励						
-- 名次	奖励1	奖励2	物品ID	奖励3	物品ID
-- 第1名	称号：AAA（180天，拾取绑定）	时装：花醉云裳（永久，拾取绑定）	10126702	坐骑：蝶羽（90天，拾取绑定）	10147230
-- 第2-3名	称号：BBB（90天，拾取绑定）	时装：花醉云裳（180天，拾取绑定）	10126701	坐骑：蝶羽（30天，拾取绑定）	10146102
-- 第4-10名	称号：CCC（60天，拾取绑定）	时装：花醉云裳（90天，拾取绑定）	10126700	坐骑：蝶羽（15天，拾取绑定）	10147370
-- 第11-20名	称号：DDD（30天，拾取绑定）	时装：花醉云裳（30天，拾取绑定）	10126699	坐骑：蝶羽（7天，拾取绑定）	10146084

-- 展示道具名称	展示ID
-- 称号：倾世人间献天香（180天，拾取绑定）	39924617
-- 称号：仙姿遥见赋惊鸿（90天，拾取绑定）	39924618
-- 称号：碧丛灼华披锦绣（60天，拾取绑定）	39924619
-- 称号：游春赏红见花朝（30天，拾取绑定）	39924620
-- 时装：花醉云裳（永久，拾取绑定）	39924272

-- 2025 花醉云裳 -> 青萝倚翠
-- 10126697		10126936  7天
-- 10126699		10126938  30天
-- 10126700		10126939  90天
-- 10126701		10126940  180天
-- 10126702		10126941  永久
-- 39924272		39924559

-- 2026 青萝倚翠 -> 相见欢
-- 10126975 永久
-- 10126974 180天
-- 10126973 90天
-- 10126972 30天
-- 10126970	7天

-- 奖励信息
local g_tRewardInfo			= 
{
	[1] 	= {nItemID01 = 39924617, nItemNum01 = 1, nItemID02 = 10126975, nItemNum02 = 1, nItemID03 = 10147230, nItemNum03 = 1,}, 
	[2] 	= {nItemID01 = 39924618, nItemNum01 = 1, nItemID02 = 10126974, nItemNum02 = 1, nItemID03 = 10146102, nItemNum03 = 1,}, 
	[3] 	= {nItemID01 = 39924618, nItemNum01 = 1, nItemID02 = 10126974, nItemNum02 = 1, nItemID03 = 10146102, nItemNum03 = 1,}, 
	[4] 	= {nItemID01 = 39924619, nItemNum01 = 1, nItemID02 = 10126973, nItemNum02 = 1, nItemID03 = 10147370, nItemNum03 = 1,}, 
	[5] 	= {nItemID01 = 39924619, nItemNum01 = 1, nItemID02 = 10126973, nItemNum02 = 1, nItemID03 = 10147370, nItemNum03 = 1,}, 
	[6] 	= {nItemID01 = 39924619, nItemNum01 = 1, nItemID02 = 10126973, nItemNum02 = 1, nItemID03 = 10147370, nItemNum03 = 1,}, 
	[7] 	= {nItemID01 = 39924619, nItemNum01 = 1, nItemID02 = 10126973, nItemNum02 = 1, nItemID03 = 10147370, nItemNum03 = 1,}, 
	[8] 	= {nItemID01 = 39924619, nItemNum01 = 1, nItemID02 = 10126973, nItemNum02 = 1, nItemID03 = 10147370, nItemNum03 = 1,}, 
	[9] 	= {nItemID01 = 39924619, nItemNum01 = 1, nItemID02 = 10126973, nItemNum02 = 1, nItemID03 = 10147370, nItemNum03 = 1,}, 
	[10] 	= {nItemID01 = 39924619, nItemNum01 = 1, nItemID02 = 10126973, nItemNum02 = 1, nItemID03 = 10147370, nItemNum03 = 1,}, 
	[11] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
	[12] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
	[13] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
	[14] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
	[15] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
	[16] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
	[17] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
	[18] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
	[19] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
	[20] 	= {nItemID01 = 39924620, nItemNum01 = 1, nItemID02 = 10126972, nItemNum02 = 1, nItemID03 = -1, nItemNum03 = 0,}, 
}

--=========================================================
-- PreLoad
--=========================================================
function HuaZhaoJie_TopList_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	if 1 == bCaredItem then
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	end
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	if 1 == bCaredYuanBao then
		this:RegisterEvent("UPDATE_YUANBAO", false)
	end
	this:RegisterEvent("OPEN_HUAZHAO_TOPLIST")
	-- this:RegisterEvent("HUAZHAO_TOPLIST_VOTE_SELECTED_BY_UI")
	this:RegisterEvent("HUAZHAO_TOPLIST_VOTE_SELECTED_BY_USEITEM")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function HuaZhaoJie_TopList_OnLoad()
	g_HuaZhaoJie_TopList_Frame_UnifiedPosition = HuaZhaoJie_TopList_Frame:GetProperty("UnifiedPosition")

	-- HuaZhaoJie_TopList_OK_Button : SetEvent("Clicked", "HuaZhaoJie_TopList_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function HuaZhaoJie_TopList_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		-- local nOpType 	= Get_XParam_INT(0)

		-- -- 关闭界面
		-- if 0 == nOpType then	
		-- 	if this:IsVisible() then
		-- 		HuaZhaoJie_TopList_OnClose()
		-- 	end
		-- end

		-- -- 打开界面
		-- if 1 == nOpType then
		-- 	-- 关注npc
		-- 	if 1 == bCaredObj then
		-- 		local nServerObjID 	= Get_XParam_INT(1)
		-- 		if nServerObjID == nil or nServerObjID < 0 then
		-- 			if this:IsVisible() then
		-- 				HuaZhaoJie_TopList_OnClose()
		-- 			end
		-- 		end
		-- 		g_nServerObjID = nServerObjID
		-- 		g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
		-- 		BeginCareObject_HuaZhaoJie_TopList()
		-- 	end

		-- 	-- 显示界面
		-- 	-- 为了解决界面被遮挡的问题，先把界面关了
		-- 	-- if this:IsVisible() then
		-- 	-- 	HuaZhaoJie_TopList_OnClose()
		-- 	-- end
		-- 	HuaZhaoJie_TopList_Reset()
		-- 	HuaZhaoJie_TopList_Frame_On_ResetPos()
		-- 	this:Show()
		-- 	HuaZhaoJie_TopList_ParamInit()
		-- 	HuaZhaoJie_TopList_MoneyUpdate()
		-- 	HuaZhaoJie_TopList_YuanBaoUpdate()
		-- 	HuaZhaoJie_TopList_Update(1)
		-- end
			
		-- -- 刷新界面
		-- if 2 == nOpType then
		-- 	-- 关注npc
		-- 	if 1 == bCaredObj then
		-- 		local nServerObjID 	= Get_XParam_INT(1)
		-- 		if nServerObjID == nil or nServerObjID < 0 then
		-- 			if this:IsVisible() then
		-- 				HuaZhaoJie_TopList_OnClose()
		-- 			end
		-- 		end
		-- 	end
		-- 	if this:IsVisible() then
		-- 		HuaZhaoJie_TopList_ParamInit()
		-- 		HuaZhaoJie_TopList_Update(0)
		-- 	end
		-- end

		-- -- 二次确认框
		-- if 3 == nOpType then
		-- 	local strMsg = Get_XParam_STR(0)
		-- 	-- g_nComfirmParam1 = Get_XParam_INT(1)
		-- 	-- ["Type"] "Ok" "YesNo"
		-- 	MessageBoxSelf3("HuaZhaoJie_TopList_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		-- end

	-- 界面打开逻辑
	elseif event == "OPEN_HUAZHAO_TOPLIST" then
		-- 显示界面
		-- 为了解决界面被遮挡的问题，先把界面关了
		-- if this:IsVisible() then
		-- 	HuaZhaoJie_TopList_OnClose()
		-- end

		-- PushDebugMessage("OPEN_HUAZHAO_TOPLIST")

		HuaZhaoJie_TopList_Reset()
		HuaZhaoJie_TopList_Frame_On_ResetPos()
		this:Show()
		HuaZhaoJie_TopList_ParamInit()
		HuaZhaoJie_TopList_MoneyUpdate()
		HuaZhaoJie_TopList_YuanBaoUpdate()
		HuaZhaoJie_TopList_Update(1)

	-- elseif (event == "HUAZHAO_TOPLIST_VOTE_SELECTED_BY_UI") then
	-- 	-- 鼠标选中了一个玩家
	-- 	local targetID = tonumber(arg0)
	-- 	Clear_XSCRIPT()
	-- 	-- nOpType 类型1 道具使用 类型2 客户端鼠标动作选中
	-- 	-- nOpType, bJustCheck, nSelectedTargetID
	-- 		Set_XSCRIPT_Function_Name( "OnVoteOhterPlayer" )
	-- 		Set_XSCRIPT_ScriptID(790077)
	-- 		Set_XSCRIPT_Parameter(0, 2)								
	-- 		Set_XSCRIPT_Parameter(1, 0)								
	-- 		Set_XSCRIPT_Parameter(2, targetID)								
	-- 		Set_XSCRIPT_ParamCount(3)
	-- 	Send_XSCRIPT()

	-- 二次确认框逻辑
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == g_nComfirmUICommandID ) then
		local strMsg = Get_XParam_STR(0)
		g_nComfirmParam1 = Get_XParam_INT(0)
		g_nComfirmParam2 = Get_XParam_INT(1)
		-- ["Type"] "Ok" "YesNo"
		MessageBoxSelf3("HuaZhaoJie_TopList_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })

	elseif (event == "HUAZHAO_TOPLIST_VOTE_SELECTED_BY_USEITEM") then
		-- 鼠标选中了一个obj 或者 道具直接对某个obj使用
		local nItemBagPos = tonumber(arg0)
		local nTargetServerID = tonumber(arg1)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnVoteOhterPlayer" )
			Set_XSCRIPT_ScriptID(790077)
			Set_XSCRIPT_Parameter(0, nItemBagPos)								
			Set_XSCRIPT_Parameter(1, nTargetServerID)															
			Set_XSCRIPT_Parameter(2, 0)								
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			HuaZhaoJie_TopList_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			HuaZhaoJie_TopList_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		HuaZhaoJie_TopList_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		HuaZhaoJie_TopList_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		HuaZhaoJie_TopList_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		HuaZhaoJie_TopList_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HuaZhaoJie_TopList_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function HuaZhaoJie_TopList_ParamInit()

end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function HuaZhaoJie_TopList_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnVoteOhterPlayer" )
			Set_XSCRIPT_ScriptID(790077)
			Set_XSCRIPT_Parameter(0, g_nComfirmParam1)								
			Set_XSCRIPT_Parameter(1, g_nComfirmParam2)															
			Set_XSCRIPT_Parameter(2, 1)								
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 自动寻路
--=========================================================
function HuaZhaoJie_TopList_AutoGo()

	local nCurLevel = Player:GetData("LEVEL");
	if nCurLevel < g_nLimitLevel then
		PushDebugMessage("#{HZJPH_231222_02}")
		return
	end

	-- 前往NPC
	AutoRuntoTargetExWithName(g_nAutoGoPosX, g_nAutoGoPosZ, g_nAutoGoSceneID, g_nAutoGoNPCName)
end

--=========================================================
-- 帮助
--=========================================================
function HuaZhaoJie_TopList_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowHelp" )
		Set_XSCRIPT_ScriptID(790077)
		Set_XSCRIPT_Parameter(0, 1)							
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =HuaZhaoJie_TopList
function HuaZhaoJie_TopList_Update(bOpen)
	HuaZhaoJie_TopList : Clear()

	local nMyRank = 0
	local nMyScore = 0

	-- 简介
	local strInfo = "#{HZJPH_231222_07}"
	if 1 == KaJi:LuaFnIsKaJiServer() then
		strInfo = "#{HZJPH_231222_68}"
	end
	HuaZhaoJie_TopList_Page_info : SetText(strInfo)

	-- 红点
	-- HuaZhaoJie_TopList_Go_Tips

	-- 显示榜单
	for i = 1, g_nMaxItemNum do
		local bar = HuaZhaoJie_TopList : AddChild("HuaZhaoJie_TopList_Item")

		-- 名次图片或者文字
		bar : GetSubItem("HuaZhaoJie_TopList_Ranking_Img") : Hide()
		bar : GetSubItem("HuaZhaoJie_TopList_Ranking_Text") : Hide()
		if nil ~= g_tRankImage[i] then
			bar : GetSubItem("HuaZhaoJie_TopList_Ranking_Img") : Show()			
			bar : GetSubItem("HuaZhaoJie_TopList_Ranking_Img") : SetProperty("Image", g_tRankImage[i])
		elseif nil ~= g_tStrRankDic[i] then
			bar : GetSubItem("HuaZhaoJie_TopList_Ranking_Img") : Show()		
			bar : GetSubItem("HuaZhaoJie_TopList_Ranking_Img") : SetProperty("Image", g_strCommonRankImage)
			bar : GetSubItem("HuaZhaoJie_TopList_Ranking_Text") : Show()			
			bar : GetSubItem("HuaZhaoJie_TopList_Ranking_Text") : SetText(g_tStrRankDic[i])
		end

		-- 奖励
		bar : GetSubItem("HuaZhaoJie_TopList_Present_Button1") : Hide()
		bar : GetSubItem("HuaZhaoJie_TopList_Present_Button2") : Hide()
		bar : GetSubItem("HuaZhaoJie_TopList_Present_Button3") : Hide()

		local tSubInfo = g_tRewardInfo[i]
		if nil ~= tSubInfo then		
			if tSubInfo.nItemID01 > 0 and tSubInfo.nItemNum01 > 0 then
				local theAction = DataPool:CreateActionItemForShow(tSubInfo.nItemID01, tSubInfo.nItemNum01)
				if 0 ~= theAction:GetID() then
					bar : GetSubItem("HuaZhaoJie_TopList_Present_Button1") : Show()
					bar : GetSubItem("HuaZhaoJie_TopList_Present_Button1") : SetActionItem (theAction:GetID())
				end
			end
			
			if tSubInfo.nItemID02 > 0 and tSubInfo.nItemNum02 > 0 then
				local theAction = DataPool:CreateActionItemForShow(tSubInfo.nItemID02, tSubInfo.nItemNum02)
				if 0 ~= theAction:GetID() then
					bar : GetSubItem("HuaZhaoJie_TopList_Present_Button2") : Show()
					bar : GetSubItem("HuaZhaoJie_TopList_Present_Button2") : SetActionItem (theAction:GetID())
				end
			end

			if tSubInfo.nItemID03 > 0 and tSubInfo.nItemNum03 > 0 then
				local theAction = DataPool:CreateActionItemForShow(tSubInfo.nItemID03, tSubInfo.nItemNum03)
				if 0 ~= theAction:GetID() then
					bar : GetSubItem("HuaZhaoJie_TopList_Present_Button3") : Show()
					bar : GetSubItem("HuaZhaoJie_TopList_Present_Button3") : SetActionItem (theAction:GetID())
				end
			end
		end
		
		-- 姓名
		bar : GetSubItem("HuaZhaoJie_TopList_Name") : SetText("#{HZJPH_231222_48}")
		-- 积分
		bar : GetSubItem("HuaZhaoJie_TopList_Num") : SetText("")	

		-- 排行榜取姓名和积分数据
		local bValid, nRank, strName, nScore, nReserved0, sGUID64 = DataPool : Lua_GetHuaZhaoTopListInfo( i - 1 )
		if 1 == bValid and nRank > 0 and nRank <= g_nMaxItemNum then
			-- 姓名
			bar : GetSubItem("HuaZhaoJie_TopList_Name") : SetText(ScriptGlobal_Format("#{HZJPH_231222_14}", strName))
			-- 积分
			bar : GetSubItem("HuaZhaoJie_TopList_Num") : SetText(ScriptGlobal_Format("#{HZJPH_231222_39}", nScore))
		end

		-- 找我的排名
		if Player:GetGUID() == sGUID64 then
			nMyRank = nRank
			nMyScore = nScore
		end
	end

	-- 显示我的信息
	-- 默认显示不上榜信息

	-- 名次图片或者文字
	HuaZhaoJie_TopList_My_Ranking_Img : Show()
	HuaZhaoJie_TopList_My_Ranking_Img : SetProperty("Image", g_strCommonRankImage)
	HuaZhaoJie_TopList_My_Ranking_Text : Show()
	HuaZhaoJie_TopList_My_Ranking_Text : SetText(g_strRankStrForNoTopList)

	-- 奖励
	HuaZhaoJie_TopList_My_Present_Button1 : Hide()
	HuaZhaoJie_TopList_My_Present_Button2 : Hide()
	HuaZhaoJie_TopList_My_Present_Button3 : Hide()
	-- 姓名
	HuaZhaoJie_TopList_My_Name : SetText(ScriptGlobal_Format("#{HZJPH_231222_14}", Player:GetName()))
	-- 积分
	local nMyScore = DataPool:GetPlayerMission_DataRound(g_nMDForScore)
	HuaZhaoJie_TopList_My_Num : SetText(ScriptGlobal_Format("#{HZJPH_231222_40}", nMyScore))

	if nMyRank > 0 and nMyRank <= g_nMaxItemNum then
		if nil ~= g_tRankImage[nMyRank] then
			-- 名次图片
			HuaZhaoJie_TopList_My_Ranking_Img : Show()			
			HuaZhaoJie_TopList_My_Ranking_Img : SetProperty("Image", g_tRankImage[nMyRank])
			HuaZhaoJie_TopList_My_Ranking_Text : Hide()
		elseif nil ~= g_tStrRankDic[nMyRank] then
			HuaZhaoJie_TopList_My_Ranking_Img : Show()
			HuaZhaoJie_TopList_My_Ranking_Img : SetProperty("Image", g_strCommonRankImage)
			HuaZhaoJie_TopList_My_Ranking_Text : Show()			
			HuaZhaoJie_TopList_My_Ranking_Text : SetText(g_tStrRankDic[nMyRank])
		end

		-- 奖励
		local tSubInfo = g_tRewardInfo[nMyRank]
		if nil ~= tSubInfo then		
			if tSubInfo.nItemID01 > 0 and tSubInfo.nItemNum01 > 0 then
				local theAction = DataPool:CreateActionItemForShow(tSubInfo.nItemID01, tSubInfo.nItemNum01)
				if 0 ~= theAction:GetID() then
					HuaZhaoJie_TopList_My_Present_Button1 : Show()
					HuaZhaoJie_TopList_My_Present_Button1 : SetActionItem (theAction:GetID())
				end
			end
			
			if tSubInfo.nItemID02 > 0 and tSubInfo.nItemNum02 > 0 then
				local theAction = DataPool:CreateActionItemForShow(tSubInfo.nItemID02, tSubInfo.nItemNum02)
				if 0 ~= theAction:GetID() then
					HuaZhaoJie_TopList_My_Present_Button2 : Show()
					HuaZhaoJie_TopList_My_Present_Button2 : SetActionItem (theAction:GetID())
				end
			end

			if tSubInfo.nItemID03 > 0 and tSubInfo.nItemNum03 > 0 then
				local theAction = DataPool:CreateActionItemForShow(tSubInfo.nItemID03, tSubInfo.nItemNum03)
				if 0 ~= theAction:GetID() then
					HuaZhaoJie_TopList_My_Present_Button3 : Show()
					HuaZhaoJie_TopList_My_Present_Button3 : SetActionItem (theAction:GetID())
				end
			end
		end
		-- 积分
		HuaZhaoJie_TopList_My_Num : SetText(ScriptGlobal_Format("#{HZJPH_231222_39}", nMyScore))
	end
	
end

--=========================================================
-- 重置界面
--=========================================================
function HuaZhaoJie_TopList_Reset()

end

--=========================================================
-- 界面确认按钮
--=========================================================
function HuaZhaoJie_TopList_ConfirmClick()
	-- Clear_XSCRIPT()
	-- 	Set_XSCRIPT_Function_Name( "OnUIEvent" )
	-- 	Set_XSCRIPT_ScriptID(060225)
	-- 	Set_XSCRIPT_Parameter(0, 2)					
	-- 	Set_XSCRIPT_Parameter(1, 1)				
	-- 	Set_XSCRIPT_ParamCount(2)
	-- Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function HuaZhaoJie_TopList_OnClose()	
	this:Hide()
	StopCareObject_HuaZhaoJie_TopList()
	-- 重置
	HuaZhaoJie_TopList_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="HuaZhaoJie_TopList_OnHidden();" />
--=========================================================
function HuaZhaoJie_TopList_OnHidden()
	StopCareObject_HuaZhaoJie_TopList()
	-- 重置
	HuaZhaoJie_TopList_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_HuaZhaoJie_TopList()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "HuaZhaoJie_TopList")
end

function StopCareObject_HuaZhaoJie_TopList()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "HuaZhaoJie_TopList")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function HuaZhaoJie_TopList_MoneyUpdate()
	-- HuaZhaoJie_TopList_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- HuaZhaoJie_TopList_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function HuaZhaoJie_TopList_YuanBaoUpdate()
	-- HuaZhaoJie_TopList_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function HuaZhaoJie_TopList_Frame_On_ResetPos()
	HuaZhaoJie_TopList_Frame:SetProperty("UnifiedPosition", g_HuaZhaoJie_TopList_Frame_UnifiedPosition)
end