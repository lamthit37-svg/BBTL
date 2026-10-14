local g_Frame_UnifiedPosition

-- 代币数量
local g_AllData = 0
local g_MaxData = 50
local g_LevelLimit = 30

-- 奖励展示
local g_IconButton ={}
local g_IconData = {}
local g_IconData_normal = 
{
		--领奖需要代币数量--已领取标记--红点标记--领奖按钮tips
		[1] = {	count = 5, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_200721_22}", },
		[2] = {	count = 15, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_200721_45}", },
		[3] = {	count = 25, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_200721_46}", },
		[4] = {	count = 40, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_200721_47}", },
		[5] = {	count = 50, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_200721_60}", },
}

local g_IconData_ks = 
{
		--领奖需要代币数量--已领取标记--红点标记--领奖按钮tips
		[1] = {	count = 5, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_220615_1}", },
		[2] = {	count = 15, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_220615_2}", },
		[3] = {	count = 25, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_220615_3}", },
		[4] = {	count = 40, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_220615_4}", },
		[5] = {	count = 50, prizeflag = 0, reddotflag = 0, btntips = "#{JFZH_220615_5}", },
}

-- 活动奖励
local g_HuoDongJiangLi ={}
local g_HuoDongJiangLi_normal = 
{
		[1] = {	name = "#{JFZH_200721_34}", starttime = 20230831, endtime = 20230913, item1 = 39923958, item2 = 39922000, item3 = 39922765, item4 = 39921491, item5 = 39920462,}, --金枫密藏
		[2] = {	name = "#{JFZH_200721_35}", starttime = 20230831, endtime = 20230913, item1 = 39921474, item2 = 39924395, item3 = 39923961, item4 = 39924396, item5 = 39920298,}, --秋枫共赏
		--[3] = {	name = "#{JFZH_200721_59}", starttime = 20210823, endtime = 20210905, item1 = 39922762, item2 = 39920397, item3 = 39920396, item4 = 39922156, item5 = 39921474,}, --丝绸之路
		[3] = {	name = "#{JFZH_200721_36}", starttime = 20230831, endtime = 20230913, item1 = 39921474, item2 = 39924398, item3 = 39923961, item4 = 39920334, item5 = 39920329,}, --枫林拾趣
		--[4] = {	name = "#{JFZH_200721_83}", starttime = 20210823, endtime = 20210829, item1 = 39921474, item2 = 39921496, item3 = -1, item4 = -1, item5 = -1,}, --丹枫蹴鞠
		[4] = {	name = "#{JFZH_200721_37}", starttime = 20230831, endtime = 20230913, item1 = 39921474, item2 = 39921496, item3 = -1, item4 = -1, item5 = -1,}, --秋枫雅弈

}

local g_HuoDongJiangLi_ks = 
{
		[1] = {	name = "#{JFZH_200721_34}", starttime = 20230831, endtime = 20230913, item1 = 39923958, item2 = 39922000, item3 = 39922765, item4 = 39921491, item5 = 39920462,}, --金枫密藏
		[2] = {	name = "#{JFZH_200721_35}", starttime = 20230831, endtime = 20230913, item1 = 39921474, item2 = 39924395, item3 = 39923961, item4 = 39924396, item5 = 39921141,}, --秋枫共赏
		--[3] = {	name = "#{JFZH_200721_59}", starttime = 20210823, endtime = 20210905, item1 = 39922762, item2 = 39920397, item3 = 39920396, item4 = 39922156, item5 = 39921474,}, --丝绸之路
		[3] = {	name = "#{JFZH_200721_36}", starttime = 20230831, endtime = 20230913, item1 = 39921474, item2 = 39924398, item3 = 39923961, item4 = 39920334, item5 = 39920329,}, --枫林拾趣
		--[4] = {	name = "#{JFZH_200721_83}", starttime = 20210823, endtime = 20210829, item1 = 39921474, item2 = 39921496, item3 = -1, item4 = -1, item5 = -1,}, --丹枫蹴鞠
		[4] = {	name = "#{JFZH_200721_37}", starttime = 20230831, endtime = 20230913, item1 = 39921474, item2 = 39921496, item3 = -1, item4 = -1, item5 = -1,}, --秋枫雅弈

}

-- 活动展示
local g_CoinData = 
{
		--活动时间
		[1] = {	begtime=20230831, endtime =20230913, },
		[2] = {	begtime=20200903, endtime =20200909, },
		[3] = {	begtime=20230831, endtime =20230913, },
		[4] = {	begtime=20230831, endtime =20230913, },
	
}

local g_JinFengJi_nContentButton = {}
local g_JinFengJi_Reward = {
"JinFengJi_ActivityRaiders_RewardItem1",
"JinFengJi_ActivityRaiders_RewardItem2",
"JinFengJi_ActivityRaiders_RewardItem3",
"JinFengJi_ActivityRaiders_RewardItem4",
"JinFengJi_ActivityRaiders_RewardItem5",
}

--=========
-- PreLoad()
--=========
function JinFengJi_ActivityRaiders_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function JinFengJi_ActivityRaiders_OnLoad()

	
	g_Frame_UnifiedPosition = JinFengJi_ActivityRaiders_Frame:GetProperty("UnifiedPosition")
	JinFengJi_ActivityRaiders_LoadControl()

end

--=========
-- Event
--=========
function JinFengJi_ActivityRaiders_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88812801) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			JinFengJi_ActivityRaiders_SetData()
			JinFengJi_ActivityRaiders_Open()
			this:Show()
			JinFengJi_ActivityRaiders_Button01:SetCheck(1)
			JinFengJi_ActivityRaiders_Button02:SetCheck(0)
			JinFengJi_ActivityRaiders_Page1:Show()
			JinFengJi_ActivityRaiders_Page2:Hide()
		elseif bShow == 2 then
			if this:IsVisible() then
				JinFengJi_ActivityRaiders_SetData()
				JinFengJi_ActivityRaiders_Open()
			end
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		JinFengJi_ActivityRaiders_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		JinFengJi_ActivityRaiders_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		JinFengJi_ActivityRaiders_On_ResetPos()

	end

end

function JinFengJi_ActivityRaiders_Close()
	for i = 1, table.getn(g_JinFengJi_nContentButton) do
		for j = 1, table.getn(g_JinFengJi_Reward) do
			g_JinFengJi_nContentButton[i]:GetSubItem(g_JinFengJi_Reward[j]):SetActionItem(-1)
		end
	end			
	JinFengJi_ActivityRaiders_Page2List:Clear()		
	g_JinFengJi_nContentButton = {}
	this:Hide()
end

--=========
-- 重置
--=========
function JinFengJi_ActivityRaiders_On_ResetPos()

	JinFengJi_ActivityRaiders_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 装载控件
--=========
function JinFengJi_ActivityRaiders_LoadControl()

	g_IconButton = 
	{
		[1] = {	btn = JinFengJi_ActivityRaiders_Icon1, flag = JinFengJi_ActivityRaiders_Icon1_Mark, reddot = JinFengJi_ActivityRaiders_Icon1_Tips, text = JinFengJi_ActivityRaiders_Huoyue_Text2, },
		[2] = {	btn = JinFengJi_ActivityRaiders_Icon2, flag = JinFengJi_ActivityRaiders_Icon2_Mark, reddot = JinFengJi_ActivityRaiders_Icon2_Tips, text = JinFengJi_ActivityRaiders_Huoyue_Text3, },
		[3] = {	btn = JinFengJi_ActivityRaiders_Icon3, flag = JinFengJi_ActivityRaiders_Icon3_Mark, reddot = JinFengJi_ActivityRaiders_Icon3_Tips, text = JinFengJi_ActivityRaiders_Huoyue_Text4, },
		[4] = {	btn = JinFengJi_ActivityRaiders_Icon4, flag = JinFengJi_ActivityRaiders_Icon4_Mark, reddot = JinFengJi_ActivityRaiders_Icon4_Tips, text = JinFengJi_ActivityRaiders_Huoyue_Text5, },
		[5] = {	btn = JinFengJi_ActivityRaiders_Icon5, flag = JinFengJi_ActivityRaiders_Icon5_Mark, reddot = JinFengJi_ActivityRaiders_Icon5_Tips, text = JinFengJi_ActivityRaiders_Huoyue_Text6, },
	}

end

--=========
-- 打开
--=========
function JinFengJi_ActivityRaiders_Open()
	
	-- 代币数量
	JinFengJi_ActivityRaiders_Huoyue_Text1:SetText(ScriptGlobal_Format("#{JFZH_200708_85}",g_AllData))
	-- 设进度条
	JinFengJi_ActivityRaiders_Huoyue:SetProgress(tonumber(g_AllData), g_MaxData)
	
	local kjtype   = KaJi:LuaFnGetKaJiType(96)
	if kjtype == 1 then
		g_IconData = g_IconData_ks
	else
		g_IconData = g_IconData_normal
	end
	-- 奖励展示
	for nIndex=1,table.getn(g_IconData) do
			-- 进度文字
			local nCount = g_IconData[nIndex].count
			g_IconButton[nIndex].text:SetText("#L"..nCount)
			-- 领奖标记+按钮tips
			local prizeflag = g_IconData[nIndex].prizeflag
			if prizeflag == 1 then
				g_IconButton[nIndex].btn:SetToolTip("#{JFZH_200721_23}")
				g_IconButton[nIndex].flag:Show()
			else
				g_IconButton[nIndex].btn:SetToolTip(g_IconData[nIndex].btntips)
				g_IconButton[nIndex].flag:Hide()
			end
			-- 红点标记
			local reddotflag = g_IconData[nIndex].reddotflag
			if reddotflag == 1 then
				g_IconButton[nIndex].reddot:Show()
			else
				g_IconButton[nIndex].reddot:Hide()
			end
	end	

end

--=========
-- 设置数据
--=========
function JinFengJi_ActivityRaiders_SetData()
	
	local kjtype   = KaJi:LuaFnGetKaJiType(96)
	if kjtype == 1 then
		g_IconData = g_IconData_ks
	else
		g_IconData = g_IconData_normal
	end
	-- 代币数量
	g_AllData = Get_XParam_INT(1)
	-- 奖励展示
	for nIndex=1,table.getn(g_IconData) do
		g_IconData[nIndex].prizeflag = Get_XParam_INT(nIndex*2)
		g_IconData[nIndex].reddotflag = Get_XParam_INT(nIndex*2+1)
	end

end

--=========
-- 点击领奖
--=========
function JinFengJi_ActivityRaiders_PrizeClicked( nIndex )
	local kjtype   = KaJi:LuaFnGetKaJiType(96)
	if kjtype == 1 then
		g_IconData = g_IconData_ks
	else
		g_IconData = g_IconData_normal
	end
	if nIndex == nil or nIndex <= 0 or nIndex > table.getn(g_IconData) then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888128 )
		Set_XSCRIPT_Parameter( 0, nIndex )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
	
end


--=========
-- 点击前往
--=========
function JinFengJi_ActivityRaiders_Clicked( clickId )
	
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then
		if curDay < g_CoinData[1].begtime or curDay > g_CoinData[1].endtime then
            PushDebugMessage("#{QFGS_180807_02}")
            return
        end

        if Player:GetLevel() < g_LevelLimit then
            PushDebugMessage("#{QFGS_180807_03}")
            return
        end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenFrostReWard" )
			Set_XSCRIPT_ScriptID( 891414 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif clickId == 2 then
		if curDay < g_CoinData[2].begtime or curDay > g_CoinData[2].endtime then
            PushDebugMessage("#{JFH5_210706_04}")
            return
        end

        if Player:GetLevel() < g_LevelLimit then
            PushDebugMessage("#{JFH5_210706_05}")
            return
        end
		PushEvent("2020JQ_YUNYING")
	elseif clickId == 3 then
		if curDay < g_CoinData[3].begtime or curDay > g_CoinData[3].endtime then
            PushDebugMessage("#{JFLZ_200803_03}")
            return
        end

        if Player:GetLevel() < g_LevelLimit then
            PushDebugMessage("#{JFLZ_200803_04}")
            return
        end
		local bRet = AutoRuntoTargetExWithName(231, 186, 1, "金叶彤枫")
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
		PushDebugMessage("#{JFLZ_200803_05}")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("HotPointClick")
			Set_XSCRIPT_ScriptID(892889)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif clickId == 4 then
		if curDay < g_CoinData[clickId].begtime or curDay > g_CoinData[clickId].endtime then
			PushDebugMessage("#{JFZH_200721_03}")
			return
		end
		if Player:GetLevel() < g_LevelLimit then
			PushDebugMessage("#{JFZH_200721_02}")
			return
		end
		
		local bRet = AutoRuntoTargetExWithName(238, 186, 1, "枫凌")
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
	end
	
end

--=========
-- 问号帮助
--=========
function JinFengJi_ActivityRaiders_Help_Clicked()
	PushEvent("CCSHOP_HELP", 120)
end


--=========
-- 分页切换
--=========
function JinFengJi_ActivityRaiders_PageClick(index)

	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID( 888128 )
		Send_XSCRIPT()
		JinFengJi_ActivityRaiders_Button01:SetCheck(1)
		JinFengJi_ActivityRaiders_Button02:SetCheck(0)
		JinFengJi_ActivityRaiders_Page1:Show()
		JinFengJi_ActivityRaiders_Page2:Hide()
	elseif index == 2 then
		JinFengJi_ActivityRaiders_Button01:SetCheck(0)
		JinFengJi_ActivityRaiders_Button02:SetCheck(1)
		JinFengJi_ActivityRaiders_Page1:Hide()
		JinFengJi_ActivityRaiders_Page2:Show()
		JinFengJi_ActivityRaiders_Updata_HDJL()
	end
end

--=========
-- 填充活动奖励界面
--=========
function JinFengJi_ActivityRaiders_Updata_HDJL()

	for i = 1, table.getn(g_JinFengJi_nContentButton) do
		for j = 1, table.getn(g_JinFengJi_Reward) do
			g_JinFengJi_nContentButton[i]:GetSubItem(g_JinFengJi_Reward[j]):SetActionItem(-1)
		end
	end			
	JinFengJi_ActivityRaiders_Page2List:Clear()		
	g_JinFengJi_nContentButton = {}
	local kjtype   = KaJi:LuaFnGetKaJiType(96)
	if kjtype == 1 then
		g_HuoDongJiangLi = g_HuoDongJiangLi_ks
	else
		g_HuoDongJiangLi = g_HuoDongJiangLi_normal
	end

	for nIndex=1,table.getn(g_HuoDongJiangLi) do
		local bar = JinFengJi_ActivityRaiders_Page2List:AddChild("JinFengJi_ActivityRaiders_Page2List_Content")
		if nil ~= bar then
			bar:GetSubItem("JinFengJi_ActivityRaiders_RewardText"):SetText(g_HuoDongJiangLi[nIndex].name)
			if g_HuoDongJiangLi[nIndex].item1 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item1, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_JinFengJi_Reward[1]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_JinFengJi_Reward[1]):Show()
				end
			else
				bar:GetSubItem(g_JinFengJi_Reward[1]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item2 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item2, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_JinFengJi_Reward[2]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_JinFengJi_Reward[2]):Show()
				end
			else
				bar:GetSubItem(g_JinFengJi_Reward[2]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item3 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item3, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_JinFengJi_Reward[3]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_JinFengJi_Reward[3]):Show()
				end
			else
				bar:GetSubItem(g_JinFengJi_Reward[3]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item4 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item4, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_JinFengJi_Reward[4]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_JinFengJi_Reward[4]):Show()
				end
			else
				bar:GetSubItem(g_JinFengJi_Reward[4]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item5 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item5, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_JinFengJi_Reward[5]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_JinFengJi_Reward[5]):Show()
				end
			else
				bar:GetSubItem(g_JinFengJi_Reward[5]):Hide()
			end
			g_JinFengJi_nContentButton[nIndex] = bar
		end
	end
	
end