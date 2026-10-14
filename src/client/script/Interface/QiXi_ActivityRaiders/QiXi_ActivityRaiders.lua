local g_Frame_UnifiedPosition

-- 代币数量
local g_AllData = 0
local g_MaxData = 280
local g_LevelLimit = 30

-- 奖励展示
local g_IconButton ={}
local g_IconData = 
{
		--领奖需要代币数量--已领取标记--红点标记--领奖按钮tips
		[1] = {	count = 45, prizeflag = 0, reddotflag = 0, btntips = "#{QXZH_200708_28}", },
		[2] = {	count = 90, prizeflag = 0, reddotflag = 0, btntips = "#{QXZH_200708_29}", },
		[3] = {	count = 140, prizeflag = 0, reddotflag = 0, btntips = "#{QXZH_200708_30}", },
		[4] = {	count = 210, prizeflag = 0, reddotflag = 0, btntips = "#{QXZH_200708_31}", },
		[5] = {	count = 280, prizeflag = 0, reddotflag = 0, btntips = "#{QXZH_200708_32}", },
}

-- 活动奖励
local g_HuoDongJiangLi = 
{
		[1] = {	name = "#{QXZH_200708_34}", starttime = 20210802, endtime = 20210822, item1 = 39921759, item2 = 39921756, item3 = 39921758, item4 = 39921757, item5 = 39921775,},
		[2] = {	name = "#{QXZH_200708_35}", starttime = 20210802, endtime = 20210818, item1 = 39920389, item2 = 39923469, item3 = 39921247, item4 = 39921243, item5 = 39921775,},
		[3] = {	name = "#{QXZH_200708_36}", starttime = 20210802, endtime = 20210818, item1 = 39921251, item2 = 39921252, item3 = 39921775, item4 = -1, item5 = -1,},
		[4] = {	name = "#{QXZH_200708_57}", starttime = 20210802, endtime = 20210822, item1 = 39921762, item2 = 39923468, item3 = 39921755, item4 = 39921377, item5 = 39921443,},
		[5] = {	name = "#{QXZH_200708_58}", starttime = 20210802, endtime = 20210822, item1 = 39921545, item2 = 39920396, item3 = 39920397, item4 = 39921763, item5 = -1,},
		[6] = {	name = "#{QXZH_200708_59}", starttime = 20210802, endtime = 20210822, item1 = 39921760, item2 = 39921809, item3 = -1, item4 = -1, item5 = -1,},
}
-- 活动展示
local g_CoinData = 
{
		--活动时间
		[1] = {	begtime=20210802, endtime =20210822, },
		[2] = {	begtime=20210802, endtime =20210818, },
		[3] = {	begtime=20210802, endtime =20210818, },	
}

local g_QiXi_nContentButton = {}
local g_QiXi_Reward = {
"QiXi_ActivityRaiders_RewardItem1",
"QiXi_ActivityRaiders_RewardItem2",
"QiXi_ActivityRaiders_RewardItem3",
"QiXi_ActivityRaiders_RewardItem4",
"QiXi_ActivityRaiders_RewardItem5",
}

--=========
-- PreLoad()
--=========
function QiXi_ActivityRaiders_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("2019QIXI_CLOSE",false)
end

--=========
-- OnLoad()
--=========
function QiXi_ActivityRaiders_OnLoad()

	
	g_Frame_UnifiedPosition = QiXi_ActivityRaiders_Frame:GetProperty("UnifiedPosition")
	QiXi_ActivityRaiders_LoadControl()

end

--=========
-- Event
--=========
function QiXi_ActivityRaiders_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88811201) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			QiXi_ActivityRaiders_SetData()
			QiXi_ActivityRaiders_Open()
			this:Show()
		elseif bShow == 2 then
			if this:IsVisible() then
				QiXi_ActivityRaiders_SetData()
				QiXi_ActivityRaiders_Open()
			end
		end
		QiXi_ActivityRaiders_Button01:SetCheck(1)
		QiXi_ActivityRaiders_Button02:SetCheck(0)
		QiXi_ActivityRaiders_Page1:Show()
		QiXi_ActivityRaiders_Page2:Hide()
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		QiXi_ActivityRaiders_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		QiXi_ActivityRaiders_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		QiXi_ActivityRaiders_On_ResetPos()
		
	elseif event == "2019QIXI_CLOSE" then
		QiXi_ActivityRaiders_Close()
	end

end

function QiXi_ActivityRaiders_Close()
	for i = 1, table.getn(g_QiXi_nContentButton) do
		for j = 1, table.getn(g_QiXi_Reward) do
			g_QiXi_nContentButton[i]:GetSubItem(g_QiXi_Reward[j]):SetActionItem(-1)
		end
	end			
	QiXi_ActivityRaiders_Page2List:Clear()		
	g_QiXi_nContentButton = {}
	this:Hide()
end

--=========
-- 重置
--=========
function QiXi_ActivityRaiders_On_ResetPos()

	QiXi_ActivityRaiders_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 装载控件
--=========
function QiXi_ActivityRaiders_LoadControl()

	g_IconButton = 
	{
		[1] = {	btn = QiXi_ActivityRaiders_Icon1, flag = QiXi_ActivityRaiders_Icon1_Mark, reddot = QiXi_ActivityRaiders_Icon1_Tips, text = QiXi_ActivityRaiders_Huoyue_Text2, },
		[2] = {	btn = QiXi_ActivityRaiders_Icon2, flag = QiXi_ActivityRaiders_Icon2_Mark, reddot = QiXi_ActivityRaiders_Icon2_Tips, text = QiXi_ActivityRaiders_Huoyue_Text3, },
		[3] = {	btn = QiXi_ActivityRaiders_Icon3, flag = QiXi_ActivityRaiders_Icon3_Mark, reddot = QiXi_ActivityRaiders_Icon3_Tips, text = QiXi_ActivityRaiders_Huoyue_Text4, },
		[4] = {	btn = QiXi_ActivityRaiders_Icon4, flag = QiXi_ActivityRaiders_Icon4_Mark, reddot = QiXi_ActivityRaiders_Icon4_Tips, text = QiXi_ActivityRaiders_Huoyue_Text5, },
		[5] = {	btn = QiXi_ActivityRaiders_Icon5, flag = QiXi_ActivityRaiders_Icon5_Mark, reddot = QiXi_ActivityRaiders_Icon5_Tips, text = QiXi_ActivityRaiders_Huoyue_Text6, },
	}

end

--=========
-- 打开
--=========
function QiXi_ActivityRaiders_Open()
	
	-- 代币数量
	QiXi_ActivityRaiders_Huoyue_Text1:SetText(ScriptGlobal_Format("#{QXZH_200708_26}",g_AllData))
	-- 设进度条
	QiXi_ActivityRaiders_Huoyue:SetProgress(tonumber(g_AllData), g_MaxData)
	
	-- 奖励展示
	for nIndex=1,table.getn(g_IconData) do
			-- 进度文字
			local nCount = g_IconData[nIndex].count
			g_IconButton[nIndex].text:SetText("#L"..nCount)
			-- 领奖标记+按钮tips
			local prizeflag = g_IconData[nIndex].prizeflag
			if prizeflag == 1 then
				g_IconButton[nIndex].btn:SetToolTip("#{QXZH_200708_33}")
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
function QiXi_ActivityRaiders_SetData()
	
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
function QiXi_ActivityRaiders_PrizeClicked( nIndex )

	if nIndex == nil or nIndex <= 0 or nIndex > table.getn(g_IconData) then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888112 )
		Set_XSCRIPT_Parameter( 0, nIndex )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
	
end


--=========
-- 点击前往
--=========
function QiXi_ActivityRaiders_Clicked( clickId )
	
	local curDay = DataPool:GetServerDayTime()
	if clickId == 1 then
		if curDay < g_CoinData[1].begtime or curDay > g_CoinData[1].endtime then
            PushDebugMessage("#{QXHF_190620_20}")
            return
        end

        if Player:GetLevel() < g_LevelLimit then
            PushDebugMessage("#{QXHF_190620_21}")
            return
        end
		AutoRunToTargetEx(328,306,1)
		SetAutoRunTargetNPCName( "溪娘" )
		PushDebugMessage("#{QXHF_190620_76}")		
	elseif clickId == 2 then
		if curDay < g_CoinData[2].begtime or curDay > g_CoinData[2].endtime then
            PushDebugMessage("#{QXHF_190620_14}")
            return
        end

        if Player:GetLevel() < g_LevelLimit then
            PushDebugMessage("#{QXHF_190620_15}")
            return
        end
		
		local ret = AutoRuntoTargetExWithName(223, 138, 30, "灵鹊仙子")
        if 0 == ret then
            PushDebugMessage("无法自动寻路")
            return
        end
       PushDebugMessage("#{QXHF_190620_16}")
	elseif clickId == 3 then
	
		if curDay < g_CoinData[3].begtime or curDay > g_CoinData[3].endtime then
            PushDebugMessage("#{QXHF_190620_17}")
            return
        end

        if Player:GetLevel() < g_LevelLimit then
            PushDebugMessage("#{QXHF_190620_18}")
            return
        end
		
		local ret = AutoRuntoTargetExWithName(223, 138, 30, "灵鹊仙子")
        if 0 == ret then
            PushDebugMessage("无法自动寻路")
            return
        end
        PushDebugMessage("#{QXJH_161117_10}")
	end
	
end

--=========
-- 问号帮助
--=========
function QiXi_ActivityRaiders_Help_Clicked()
	PushEvent("CCSHOP_HELP", 116)
end


--=========
-- 分页切换
--=========
function QiXi_ActivityRaiders_PageClick(index)

	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowClientUI" )
			Set_XSCRIPT_ScriptID( 888112 )
		Send_XSCRIPT()
		QiXi_ActivityRaiders_Button01:SetCheck(1)
		QiXi_ActivityRaiders_Button02:SetCheck(0)
		QiXi_ActivityRaiders_Page1:Show()
		QiXi_ActivityRaiders_Page2:Hide()
	elseif index == 2 then
		QiXi_ActivityRaiders_Button01:SetCheck(0)
		QiXi_ActivityRaiders_Button02:SetCheck(1)
		QiXi_ActivityRaiders_Page1:Hide()
		QiXi_ActivityRaiders_Page2:Show()
		QiXi_ActivityRaiders_Updata_HDJL()
	end
end

--=========
-- 填充活动奖励界面
--=========
function QiXi_ActivityRaiders_Updata_HDJL()

	for i = 1, table.getn(g_QiXi_nContentButton) do
		for j = 1, table.getn(g_QiXi_Reward) do
			g_QiXi_nContentButton[i]:GetSubItem(g_QiXi_Reward[j]):SetActionItem(-1)
		end
	end			
	QiXi_ActivityRaiders_Page2List:Clear()		
	g_QiXi_nContentButton = {}

	for nIndex=1,table.getn(g_HuoDongJiangLi) do
		local bar = QiXi_ActivityRaiders_Page2List:AddChild("QiXi_ActivityRaiders_Page2List_Content")
		if nil ~= bar then
			bar:GetSubItem("QiXi_ActivityRaiders_RewardText"):SetText(g_HuoDongJiangLi[nIndex].name)
			if g_HuoDongJiangLi[nIndex].item1 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item1, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_QiXi_Reward[1]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_QiXi_Reward[1]):Show()
				end
			else
				bar:GetSubItem(g_QiXi_Reward[1]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item2 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item2, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_QiXi_Reward[2]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_QiXi_Reward[2]):Show()
				end
			else
				bar:GetSubItem(g_QiXi_Reward[2]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item3 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item3, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_QiXi_Reward[3]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_QiXi_Reward[3]):Show()
				end
			else
				bar:GetSubItem(g_QiXi_Reward[3]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item4 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item4, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_QiXi_Reward[4]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_QiXi_Reward[4]):Show()
				end
			else
				bar:GetSubItem(g_QiXi_Reward[4]):Hide()
			end
			if g_HuoDongJiangLi[nIndex].item5 ~= -1 then
				local theAction = DataPool:CreateActionItemForShow(g_HuoDongJiangLi[nIndex].item5, 1)
				if theAction:GetID() ~= 0 then
					bar:GetSubItem(g_QiXi_Reward[5]):SetActionItem(theAction:GetID());
					bar:GetSubItem(g_QiXi_Reward[5]):Show()
				end
			else
				bar:GetSubItem(g_QiXi_Reward[5]):Hide()
			end
			g_QiXi_nContentButton[nIndex] = bar
		end
	end
	
end