
local g_Frame_UnifiedPosition

local g_AA_ItemListCtrl = {}

local g_AA_JuYiZhi = 0
local g_AA_ChoujiangIdx = 0

local g_ItemList = {
[1]={itemid=	38004357	,itemcount=	2},--	良品残印集录*2
[2]={itemid=	38004358	,itemcount=	1},--	精品残印集录*1
[3]={itemid=	20310168	,itemcount=	2},--	金蚕丝*2
[4]={itemid=	38000571	,itemcount=	1},--	至尊强化精华*1
[5]={itemid=	38000807	,itemcount=	1},--	典籍注解*1
[6]={itemid=	38000992	,itemcount=	1},--	虹耀石*1
[7]={itemid=	10126422	,itemcount=	1},--	时装：倾国两相欢（焦骨，永久）
[8]={itemid=	10127643	,itemcount=	1},--	时装：墨染幽篁（原色，永久）
}
local g_ItemList_KJS = {
[1]={itemid=	38005733	,itemcount=	1},--	随机润魂石
[2]={itemid=	30700241	,itemcount=	1},--	回天神石
[3]={itemid=	20310168	,itemcount=	2},--	金蚕丝*2
[4]={itemid=	38000571	,itemcount=	1},--	至尊强化精华*1
[5]={itemid=	38000807	,itemcount=	1},--	典籍注解*1
[6]={itemid=	38000992	,itemcount=	1},--	虹耀石*1
[7]={itemid=	10126422	,itemcount=	1},--	时装：倾国两相欢（焦骨，永久）
[8]={itemid=	10127643	,itemcount=	1},--	时装：墨染幽篁（原色，永久）
}

local m_Lights1Ctrl={}


--转盘控制
local g_Lightindex = 8	--启动起始位置
local g_Step = 1		--启动起始步数
local g_MaxStep = 4 	--最大步数
local g_SumStep = 0		--步数累加
local g_RollStep = 1	--抽奖步骤(1:可抽取 2:转动中 3:可领取)
local m_Lights = {}		--闪光灯控件列表
local m_Steps = {4,24,8,4}--步数列表
local m_Rates = {200,50,200,500}--频率列表

--=========
--PreLoad==
--=========
function Anniversary_Award_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
--=========
--OnLoad
--=========
function Anniversary_Award_OnLoad()
	g_AA_ItemListCtrl = {
		{actb=Anniversary_Award_Icon1,	animate=Anniversary_Award1_Light, count=Anniversary_Award_Icon1_Num},
		{actb=Anniversary_Award_Icon2,	animate=Anniversary_Award2_Light, count=Anniversary_Award_Icon2_Num},
		{actb=Anniversary_Award_Icon3,	animate=Anniversary_Award3_Light, count=Anniversary_Award_Icon3_Num},
		{actb=Anniversary_Award_Icon4,	animate=Anniversary_Award4_Light, count=Anniversary_Award_Icon4_Num},
		{actb=Anniversary_Award_Icon5,	animate=Anniversary_Award5_Light, count=Anniversary_Award_Icon5_Num},
		{actb=Anniversary_Award_Icon6,	animate=Anniversary_Award6_Light, count=Anniversary_Award_Icon6_Num},
		{actb=Anniversary_Award_Icon7,	animate=Anniversary_Award7_Light, count=Anniversary_Award_Icon7_Num},
		{actb=Anniversary_Award_Icon8,	animate=Anniversary_Award8_Light, count=Anniversary_Award_Icon8_Num},
	}
	g_Frame_UnifiedPosition = Anniversary_Award_Frame:GetProperty("UnifiedPosition") 
end
--=========
--OnEvent
--=========
function Anniversary_Award_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 8884803 then

		local bUIFlag = Get_XParam_INT(0)
		if bUIFlag==1 then
			g_AA_JuYiZhi = Get_XParam_INT(1)--jyz
			g_AA_ChoujiangIdx = 0
			Anniversary_Award_Show()
			this:Show()
			CloseWindow("Packet",true)
			CloseWindow("Anniversary_Gift",true)
		elseif bUIFlag==2 then
			g_AA_JuYiZhi = Get_XParam_INT(1)
			g_AA_ChoujiangIdx = Get_XParam_INT(2)
			g_RollStep=1
			Anniversary_Award_UpdateCJCount()
			Anniversary_Award_UpdateButton()
			Anniversary_Award_LotteryStart()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
		Anniversary_Award_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Anniversary_Award_Close();
	end

end

--开抽
function Anniversary_Award_LotteryStart()
	g_Lightindex=8
	if g_RollStep == 2 then
		return
	end

	g_RollStep = 2 	--摇奖中
	g_AA_ItemListCtrl[g_Lightindex].animate:Hide()

	g_Step = 1
	g_SumStep = 0
	KillTimer("Anniversary_Award_LotteryTick()")
	SetTimer("Anniversary_Award","Anniversary_Award_LotteryTick()", m_Rates[g_Step])
	
end
function Anniversary_Award_LotteryTick()
--PushDebugMessage("Anniversary_Award_LotteryTick")
	--正常转动
	local lightnow = g_Lightindex
	local lightnext = g_Lightindex + 1
	if lightnext == 9 then
		lightnext = 1
	end
	
	g_AA_ItemListCtrl[lightnow].animate:Hide()
	g_AA_ItemListCtrl[lightnext].animate:Show()

	g_Lightindex = lightnext
	
	--转动控制
	g_SumStep = g_SumStep + 1
	local maxStep = m_Steps[g_Step]
	if g_Step == 2 then
		maxStep = m_Steps[g_Step] + g_AA_ChoujiangIdx
	end
	if g_SumStep >= maxStep then
		g_Step = g_Step + 1
		g_SumStep = 0
		KillTimer("Anniversary_Award_LotteryTick()")
--		PushDebugMessage("KillTimer")
		if g_Step <= g_MaxStep then
			SetTimer("Anniversary_Award","Anniversary_Award_LotteryTick()", m_Rates[g_Step])
		else
			--转动结束,奖品可领取状态
			g_RollStep = 3
			--再来个计时器，不需要通知服务器
			SetTimer("Anniversary_Award","Anniversary_Award_GetReward()", 1000)
		end
	end
end
function Anniversary_Award_GetReward()
	KillTimer("Anniversary_Award_GetReward()")
	--醒目提示
	if g_ItemList[g_AA_ChoujiangIdx]~=nil then--相同
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(130) > 0 then  --卡级
			local itemname = DataPool:Lua_GetItemNameByIndex(g_ItemList_KJS[g_AA_ChoujiangIdx].itemid)
			local strTemp = ScriptGlobal_Format("#{ZNQYJ_220215_43}", g_ItemList_KJS[g_AA_ChoujiangIdx].itemcount, itemname)
			PushDebugMessage(strTemp)
		else
			local itemname = DataPool:Lua_GetItemNameByIndex(g_ItemList[g_AA_ChoujiangIdx].itemid)
			local strTemp = ScriptGlobal_Format("#{ZNQYJ_220215_43}", g_ItemList[g_AA_ChoujiangIdx].itemcount, itemname)
			PushDebugMessage(strTemp)
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnChouJiangEnd" ); 	-- 脚本函数名称
			Set_XSCRIPT_ScriptID( 888480 );								-- 脚本编号
			Set_XSCRIPT_ParamCount( 0 );									-- 参数个数
		Send_XSCRIPT()
	end
	g_AA_ChoujiangIdx = 0
	Anniversary_Award_UpdateButton()
end


--=========
--OnClose "X"
--=========
function Anniversary_Award_Close()
	for i = 1, 8 do
		g_AA_ItemListCtrl[i].actb:SetActionItem(-1)
		g_AA_ItemListCtrl[i].animate:Hide()
	end
	KillTimer("Anniversary_Award_LotteryTick()")
	KillTimer("Anniversary_Award_GetReward()")
	this:Hide()
end


function Anniversary_Award_On_ResetPos()
	Anniversary_Award_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function Anniversary_Award_UpdateCJCount()
	--"#G" "#cff0000"
	Anniversary_Award_NUM1_Des:SetText( ScriptGlobal_Format("#{ZNQYJ_220215_37}", g_AA_JuYiZhi) )
	if g_AA_JuYiZhi > 0 then
		Anniversary_Award_Button_tips:Show()
	else
		Anniversary_Award_Button_tips:Hide()
	end
end

function Anniversary_Award_Show()

--	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(52) > 0 then

	--设置虚拟道具和数量
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(130) > 0 then  --卡级
		for i = 1, 8 do
			local theAction = DataPool:CreateActionItemForShow(g_ItemList_KJS[i].itemid, 1)
			if theAction:GetID() ~= 0 then
				g_AA_ItemListCtrl[i].actb:SetActionItem(theAction:GetID());
			end
			g_AA_ItemListCtrl[i].count:SetText(g_ItemList_KJS[i].itemcount)
			g_AA_ItemListCtrl[i].animate:Hide()
		end
	else
		for i = 1, 8 do
			local theAction = DataPool:CreateActionItemForShow(g_ItemList[i].itemid, 1)
			if theAction:GetID() ~= 0 then
				g_AA_ItemListCtrl[i].actb:SetActionItem(theAction:GetID());
			end
			g_AA_ItemListCtrl[i].count:SetText(g_ItemList[i].itemcount)
			g_AA_ItemListCtrl[i].animate:Hide()
		end
	end

	Anniversary_Award_UpdateCJCount()
	Anniversary_Award_UpdateButton()
end



function Anniversary_Award_Click()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnChouJiangBegin" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 888480 );								-- 脚本编号
--		Set_XSCRIPT_Parameter( 0, 1 )
		Set_XSCRIPT_ParamCount( 0 );									-- 参数个数
	Send_XSCRIPT()

end

function Anniversary_Award_UpdateButton()

	if g_AA_ChoujiangIdx  > 0 then
		Anniversary_Award_Button:Disable()
	else
		Anniversary_Award_Button:Enable()
	end

end
