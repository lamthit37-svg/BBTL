
local g_Frame_UnifiedPosition
local g_LuckyPondData=0
local g_LuckyPondIdx=1

local g_ItemList1 = {
[1]  = {showid = 39920296, 	num = 1},--真元珀
[2]  = {showid = 39920537, 	num = 1},--幻魂丹
[3]  = {showid = 39922767, 	num = 1},--四绘卷
[4]  = {showid = 39923232, 	num = 1},--四绘流光匣
[5]  = {showid = 39920332, 	num = 1},--悟灵珠
[6]  = {showid = 39925124, 	num = 1},--迎春锦
}

local g_ItemList1_KaJiServer = {
[1]  = {showid = 39920334, 	num = 1},		--典籍注解*1
[2]  = {showid = 39920537, 	num = 1},		--幻魂丹*1
[3]  = {showid = 39920396, 	num = 1},		--3级棉布*1
[4]  = {showid = 39923635, 	num = 1},		--3级精铁*1
[5]  = {showid = 39920332, 	num = 1},    --悟灵珠*1
[6]  = {showid = 39925124, 	num = 1},    --迎春锦
}

local g_XingHuo_ID = 38002626	--星火
local g_XingHuo_NUM = 3

local g_Pond1AcBtn={}
local m_Lights1Ctrl={}
local m_Num1Ctrl={}

--转盘控制
local g_Lightindex = 6	--启动起始位置
local g_Step = 1		--启动起始步数
local g_MaxStep = 4 	--最大步数
local g_SumStep = 0		--步数累加
local g_RollStep = 1	--抽奖步骤(1:可抽取 2:转动中 3:可领取)

local m_Steps = {4,26,8,4}--{4,15,4,4}--		--步数列表
local m_Rates = {200,50,200,500}--{300,100,100,100}--{200,50,200,500}		--频率列表

--=========
--PreLoad==
--=========
function SpringFirst_Lucky_PreLoad()
	this:RegisterEvent("LAYUE_BAOZHUSHENGSHENG",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
end
--=========
--OnLoad
--=========
function SpringFirst_Lucky_OnLoad()
	g_Pond1AcBtn={
		SpringFirst_Lucky_Pond1_Icon1,
		SpringFirst_Lucky_Pond1_Icon2,
		SpringFirst_Lucky_Pond1_Icon3,
		SpringFirst_Lucky_Pond1_Icon4,
		SpringFirst_Lucky_Pond1_Icon5,
		SpringFirst_Lucky_Pond1_Icon6,
	}
	m_Lights1Ctrl={
		SpringFirst_Lucky_Pond1_Icon1Animate,
		SpringFirst_Lucky_Pond1_Icon2Animate,
		SpringFirst_Lucky_Pond1_Icon3Animate,
		SpringFirst_Lucky_Pond1_Icon4Animate,
		SpringFirst_Lucky_Pond1_Icon5Animate,
		SpringFirst_Lucky_Pond1_Icon6Animate
	}
	m_Num1Ctrl={
		SpringFirst_Lucky_Pond1_Icon1_Animate2,SpringFirst_Lucky_Pond1_Icon2_Animate2,SpringFirst_Lucky_Pond1_Icon3_Animate2,
		SpringFirst_Lucky_Pond1_Icon4_Animate2,SpringFirst_Lucky_Pond1_Icon5_Animate2,SpringFirst_Lucky_Pond1_Icon6_Animate2
	}
	g_Frame_UnifiedPosition = SpringFirst_Lucky_Frame:GetProperty("UnifiedPosition") 
end
--=========
--OnEvent
--=========
function SpringFirst_Lucky_OnEvent(event)

	if event == "LAYUE_BAOZHUSHENGSHENG" then
		local bUIFlag = tonumber(arg0)
		g_LuckyPondData = tonumber(arg1)
--		PushDebugMessage("bUIFlag="..bUIFlag.." g_LuckyPondData="..g_LuckyPondData)
		if bUIFlag==1 then
			SpringFirst_Lucky_Show()
			this:Show()
			CloseWindow("Packet",true)
		elseif bUIFlag==2 then
			SpringFirst_Lucky_Show()
			--直接展示结果吧
		elseif bUIFlag==3 then--A盘转圈
			g_RollStep=1
			--转圈
			SpringFirst_Lucky_UpdateButton()
			SpringFirst_Lucky_UpdateItemCount()
			SpringFirst_Lucky_LotteryStart()
--		elseif bUIFlag==4 then
--			g_RollStep=1
--			--转圈
--			SpringFirst_Lucky_UpdateButton()
--			SpringFirst_Lucky_UpdateItemCount()
--			SpringFirst_Lucky_Lottery2Start()
		elseif bUIFlag==5 then
			SpringFirst_Lucky_Show()
			SpringFirst_Lucky_UpgradeAnimateFrame:Show()
			SpringFirst_Lucky_UpgradeAmiate1:Show()
			SpringFirst_Lucky_UpgradeAmiate1:Play(true)
			SpringFirst_Lucky_UpgradeAmiate2:Show()
			SpringFirst_Lucky_UpgradeAmiate2:Play(true)
			SpringFirst_Lucky_UpgradeAmiate3:Show()
			SpringFirst_Lucky_UpgradeAmiate3:Play(true)
			SpringFirst_Lucky_UpgradeAmiate4:Show()
			SpringFirst_Lucky_UpgradeAmiate4:Play(true)
			SpringFirst_Lucky_UpgradeAmiate5:Show()
			SpringFirst_Lucky_UpgradeAmiate5:Play(true)
			SpringFirst_Lucky_UpgradeAmiate6:Show()
			SpringFirst_Lucky_UpgradeAmiate6:Play(true)
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
		SpringFirst_Lucky_On_ResetPos()
	end

end

--开抽
function SpringFirst_Lucky_LotteryStart()
	g_Lightindex=6
	if g_RollStep == 2 then
		return
	end

	g_RollStep = 2 	--摇奖中
	m_Lights1Ctrl[g_Lightindex]:Hide()
	m_Num1Ctrl[g_Lightindex]:Hide()
	g_Step = 1
	g_SumStep = 0
	KillTimer("SpringFirst_Lucky_LotteryTick()")
	SetTimer("SpringFirst_Lucky","SpringFirst_Lucky_LotteryTick()", m_Rates[g_Step])
end

function SpringFirst_Lucky_LotteryTick()
--PushDebugMessage("SpringFirst_Lucky_LotteryTick")
	--正常转动
	local lightnow = g_Lightindex
	local lightnext = g_Lightindex + 1
	if lightnext == 7 then
		lightnext = 1
	end
	
	m_Lights1Ctrl[lightnow]:Hide()
	m_Lights1Ctrl[lightnext]:Show()
	m_Num1Ctrl[lightnow]:Hide()
	m_Num1Ctrl[lightnext]:Show()
	
	g_Lightindex = lightnext
	
	--转动控制
	g_SumStep = g_SumStep + 1
	local maxStep = m_Steps[g_Step]
	if g_Step == 2 then
		maxStep = m_Steps[g_Step] + g_LuckyPondData
	end
	if maxStep == nil then 
		SpringFirst_Lucky_OnCloseClicked()
		return
	end
	if g_SumStep >= maxStep then
		g_Step = g_Step + 1
		g_SumStep = 0
		KillTimer("SpringFirst_Lucky_LotteryTick()")
--		PushDebugMessage("KillTimer")
		if g_Step <= g_MaxStep then
			SetTimer("SpringFirst_Lucky","SpringFirst_Lucky_LotteryTick()", m_Rates[g_Step])
		else
			--转动结束,奖品可领取状态
			g_RollStep = 3
			--再来个计时器，通知服务器
			SetTimer("SpringFirst_Lucky","SpringFirst_Lucky_GetReward()", 1000)
		end
	end
end
function SpringFirst_Lucky_GetReward()
	KillTimer("SpringFirst_Lucky_GetReward()")
	--醒目提示
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(52) > 0 then
		if g_ItemList1_KaJiServer[g_LuckyPondData]~=nil then
			local itemname = DataPool:Lua_GetItemNameByIndex(g_ItemList1_KaJiServer[g_LuckyPondData].showid)
			local strTemp = ScriptGlobal_Format("#{LYYJ_181206_43}", itemname)
			PushDebugMessage(strTemp)
		end
	else
		if g_ItemList1[g_LuckyPondData]~=nil then
			local itemname = DataPool:Lua_GetItemNameByIndex(g_ItemList1[g_LuckyPondData].showid)
			local strTemp = ScriptGlobal_Format("#{LYYJ_181206_43}", itemname)
			PushDebugMessage(strTemp)
		end
	end
	

end


--=========
--OnClose "X"
--=========
function SpringFirst_Lucky_OnCloseClicked()
	this:Hide()
end
--=========
--handle Hide Event
--=========
function SpringFirst_Lucky_OnHiden()
	for i = 1, 6 do
		g_Pond1AcBtn[i]:SetActionItem(-1)
		m_Lights1Ctrl[i]:Hide()
		m_Num1Ctrl[i]:Hide()
	end
	KillTimer("SpringFirst_Lucky_LotteryTick()")
	KillTimer("SpringFirst_Lucky_LotteryTick()")
	KillTimer("SpringFirst_Lucky_GetReward()")

end

function SpringFirst_Lucky_On_ResetPos()
	SpringFirst_Lucky_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function SpringFirst_Lucky_Show()
	g_LuckyPondIdx=1

	SpringFirst_Lucky_Pond1_Client:Show()
	SpringFirst_Lucky_Pond2_Client:Hide()
	--看步调
	SpringFirst_Lucky_PondUpdate()

	SpringFirst_Lucky_UpdateItemCount()
end

function SpringFirst_Lucky_UpdateItemCount()
	--拥有星火
	local HaveCount = PlayerPackage:CountAvailableItemByIDTable(g_XingHuo_ID)
	if HaveCount>=g_XingHuo_NUM then--绿色
		local strTemp = ScriptGlobal_Format("#{LYYJ_181206_36}", HaveCount)
		SpringFirst_Lucky_Cost_Text:SetText(strTemp)
	else--红色
		local strTemp = ScriptGlobal_Format("#{LYYJ_181206_59}", HaveCount)
		SpringFirst_Lucky_Cost_Text:SetText(strTemp)
	end
end

function SpringFirst_Lucky_PondUpdate()
	--A盘
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(52) > 0 then
		--设置虚拟道具和数量
		for i = 1, 6 do
			local theAction = DataPool:CreateActionItemForShow(g_ItemList1_KaJiServer[i].showid, 1)
			if theAction:GetID() ~= 0 then
				g_Pond1AcBtn[i]:SetActionItem(theAction:GetID());
			end
		end
	else
		--设置虚拟道具和数量
		for i = 1, 6 do
			local theAction = DataPool:CreateActionItemForShow(g_ItemList1[i].showid, 1)
			if theAction:GetID() ~= 0 then
				g_Pond1AcBtn[i]:SetActionItem(theAction:GetID());
			end
		end
	end
	for i=1,6 do
		m_Lights1Ctrl[i]:Hide()
		m_Num1Ctrl[i]:Hide()
	end
	SpringFirst_Lucky_Cost_Hint:SetText("#{LYYJ_181206_34}")
	SpringFirst_Lucky_UpdateButton()

end

function SpringFirst_Lucky_Pond1_BtnClick()

	if g_LuckyPondData==0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetLuckyItem_Begin" ); 	-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 890804 );								-- 脚本编号
			Set_XSCRIPT_Parameter( 0, g_LuckyPondIdx-1 )
			Set_XSCRIPT_ParamCount( 1 );									-- 参数个数
		Send_XSCRIPT()
	elseif g_LuckyPondData>0 then
		PushDebugMessage("#{LYYJ_181206_38}")
	end
end

function SpringFirst_Lucky_UpdateButton()
	if g_LuckyPondIdx==1 then
		if g_LuckyPondData>0 then
			SpringFirst_Lucky_Pond1_Button:Disable()
		else
			SpringFirst_Lucky_Pond1_Button:Enable()
		end
	end
end
function SpringFirst_Lucky_OnHelpClicked()
	PushEvent("LAYUE_BZSS_HELP")
end

