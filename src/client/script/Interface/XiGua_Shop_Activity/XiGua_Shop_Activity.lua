-- 2020西瓜节
-- 活动攻略

local g_Frame_UnifiedPosition

-- 代币数量
local g_AllData = 0
local g_MaxData = 380

-- 奖励展示
local g_IconButton ={}
local g_IconData = 
{
		--领奖需要代币数量--已领取标记--红点标记--领奖按钮tips
		[1] = {	count = 45, prizeflag = 0, reddotflag = 0, btntips = "#{XGZH_200628_42}", },
		[2] = {	count = 120, prizeflag = 0, reddotflag = 0, btntips = "#{XGZH_200628_43}", },
		[3] = {	count = 190, prizeflag = 0, reddotflag = 0, btntips = "#{XGZH_200628_44}", },
		[4] = {	count = 330, prizeflag = 0, reddotflag = 0, btntips = "#{XGZH_200628_45}", },
		[5] = {	count = 380, prizeflag = 0, reddotflag = 0, btntips = "#{XGZH_200628_46}", },
}

-- 活动展示
local g_CoinData = 
{
		--活动时间
		[1] = {	begtime=20210712, endtime =20210728, },
		[2] = {	begtime=20210712, endtime =20210728, },
		[3] = {	begtime=20210712, endtime =20210728, },	
		[4] = {	begtime=20210712, endtime =20210728, },	
}

--=========
-- PreLoad()
--=========
function XiGua_Shop_Activity_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function XiGua_Shop_Activity_OnLoad()

	XiGua_Shop_Activity_LoadControl()
	
	g_Frame_UnifiedPosition = XiGua_Shop_Activity:GetProperty("UnifiedPosition")

end

--=========
-- 装载控件
--=========
function XiGua_Shop_Activity_LoadControl()

	g_IconButton = 
	{
		[1] = {	btn = XiGua_Shop_Activity_Icon1, flag = XiGua_Shop_Activity_Icon1_Done, reddot = XiGua_Shop_Activity_Icon1_RedDot, text = XiGua_Shop_Activity_Huoyue_Text2, },
		[2] = {	btn = XiGua_Shop_Activity_Icon2, flag = XiGua_Shop_Activity_Icon2_Done, reddot = XiGua_Shop_Activity_Icon2_RedDot, text = XiGua_Shop_Activity_Huoyue_Text3, },
		[3] = {	btn = XiGua_Shop_Activity_Icon3, flag = XiGua_Shop_Activity_Icon3_Done, reddot = XiGua_Shop_Activity_Icon3_RedDot, text = XiGua_Shop_Activity_Huoyue_Text4, },
		[4] = {	btn = XiGua_Shop_Activity_Icon4, flag = XiGua_Shop_Activity_Icon4_Done, reddot = XiGua_Shop_Activity_Icon4_RedDot, text = XiGua_Shop_Activity_Huoyue_Text5, },
		[5] = {	btn = XiGua_Shop_Activity_Icon5, flag = XiGua_Shop_Activity_Icon5_Done, reddot = XiGua_Shop_Activity_Icon5_RedDot, text = XiGua_Shop_Activity_Huoyue_Text6, },
	}

end

--=========
-- Event
--=========
function XiGua_Shop_Activity_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88809901) then
		
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			XiGua_Shop_Activity_SetData()
			XiGua_Shop_Activity_Open()
			this:Show()
		elseif bShow == 2 then
			if this:IsVisible() then
				XiGua_Shop_Activity_SetData()
				XiGua_Shop_Activity_Open()
			end
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		XiGua_Shop_Activity_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		XiGua_Shop_Activity_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		XiGua_Shop_Activity_On_ResetPos()

	end

end

--=========
-- 设置数据
--=========
function XiGua_Shop_Activity_SetData()
	
	-- 代币数量
	g_AllData = Get_XParam_INT(1)
	-- 奖励展示
	for nIndex=1,table.getn(g_IconData) do
		g_IconData[nIndex].prizeflag = Get_XParam_INT(nIndex*2)
		g_IconData[nIndex].reddotflag = Get_XParam_INT(nIndex*2+1)
	end

end

--=========
-- 打开
--=========
function XiGua_Shop_Activity_Open()
	
	-- 代币数量
	XiGua_Shop_Activity_Huoyue_Text1:SetText(ScriptGlobal_Format("#{XGZH_200628_48}",g_AllData))
	-- 设进度条
	XiGua_Shop_Activity_Huoyue:SetProgress(tonumber(g_AllData), g_MaxData)
	
	-- 奖励展示
	for nIndex=1,table.getn(g_IconData) do
			-- 进度文字
			--local nCount = g_IconData[nIndex].count
			--g_IconButton[nIndex].text:SetText(""..nCount)
			-- 领奖标记+按钮tips
			local prizeflag = g_IconData[nIndex].prizeflag
			if prizeflag == 1 then
				g_IconButton[nIndex].btn:SetToolTip("#{XGZH_200628_47}")
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
-- 重置
--=========
function XiGua_Shop_Activity_On_ResetPos()

	XiGua_Shop_Activity:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function XiGua_Shop_Activity_Close()

	this:Hide()
	
end

--=========
-- 点击领奖
--=========
function XiGua_Shop_Activity_PrizeClicked( nIndex )

	if nIndex == nil or nIndex <= 0 or nIndex > table.getn(g_IconData) then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888099 )
		Set_XSCRIPT_Parameter( 0, nIndex )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
	
end

--=========
-- 点击前往
--=========
function XiGua_Shop_Activity_Clicked( clickId )
	
	if clickId == 1 then
		-- 清凉一夏
		local curDay = DataPool:GetServerDayTime()
		if curDay < g_CoinData[clickId].begtime then
			PushDebugMessage("#{XGSD_200609_03}")
			return
		elseif curDay > g_CoinData[clickId].endtime then
			PushDebugMessage("#{XGSD_200609_03}")
			return
		else
			local nLevel = Player:GetLevel();
			if nLevel < 30 then
				PushDebugMessage("#{XGSD_200609_02}")
				return
			end
		end
		local bRet = AutoRuntoTargetExWithName(212, 95, 30, "王云逸")
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
		PushDebugMessage("#{XGSD_200609_07}")

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetRedPoint")
			Set_XSCRIPT_ScriptID(892856)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	
	elseif clickId == 2 then
		local curDay = DataPool:GetServerDayTime()
		if curDay < g_CoinData[clickId].begtime or curDay > g_CoinData[clickId].endtime then
			PushDebugMessage("#{XGSD_200609_03}")
			return
		end
		
		local nLevel = Player:GetLevel();
		if nLevel < 30 then
			PushDebugMessage("#{XGSD_200609_02}")
			return
		end
		
		-- 仲夏盘寻节气
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateUI" )
			Set_XSCRIPT_ScriptID(891920)
		Send_XSCRIPT()
	
	elseif clickId == 3 then
		-- 吃瓜大赛
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("GetRedPoint")
				Set_XSCRIPT_ScriptID(892855)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()

			local nLevel = Player:GetLevel();
			if nLevel < 30 then
				PushDebugMessage("#{XGSD_200609_02}")
				return
			end

			local curDay = DataPool:GetServerDayTime()
			if curDay < g_CoinData[clickId].begtime or curDay > g_CoinData[clickId].endtime then
				PushDebugMessage("#{XGSD_200609_03}")
				return
			end
			local bRet = AutoRuntoTargetExWithName(245, 346, 0, "乐长青")
			if 0 == bRet then
				PushDebugMessage("无法自动寻路")
				return
			end
			PushDebugMessage("#{XGSD_200609_10}")	
			
	elseif clickId == 4 then
		-- 清泉茗茶
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("GetRedPoint")
				Set_XSCRIPT_ScriptID(889861)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()

			local nLevel = Player:GetLevel();
			if nLevel < 30 then
				PushDebugMessage("#{XGSD_200609_02}")
				return
			end

			local curDay = DataPool:GetServerDayTime()
			if curDay < g_CoinData[clickId].begtime or curDay > g_CoinData[clickId].endtime then
				PushDebugMessage("#{XGSD_200609_03}")
				return
			end
			local bRet = AutoRuntoTargetExWithName(296, 188, 1, "陆屿")
			if 0 == bRet then
				PushDebugMessage("无法自动寻路")
				return
			end
			PushDebugMessage("#{XGSD_200609_13}")	
	end
	
end

--=========
-- 问号帮助
--=========
function XiGua_Shop_Activity_Description_Clicked()
	PushEvent("CCSHOP_HELP", 115)
end
