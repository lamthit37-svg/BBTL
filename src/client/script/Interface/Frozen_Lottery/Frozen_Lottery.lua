--******************************************
--冰雪舞会抽奖
--create by  wangsaifei 
--2025-10-19
--******************************************

local g_Frozen_Lottery_Frame_UnifiedPosition;
local g_Frozen_Lottery_objCared = -1;
local g_Frozen_Lottery_targetId = -1
local g_Frozen_Lottery_num_picInfo = 
{
	[0] = "set:Frozen_Lottery image:Frozen_Lottery_N10",
	[1] = "set:Frozen_Lottery image:Frozen_Lottery_N1",
	[2] = "set:Frozen_Lottery image:Frozen_Lottery_N2",
	[3] = "set:Frozen_Lottery image:Frozen_Lottery_N3",
	[4] = "set:Frozen_Lottery image:Frozen_Lottery_N4",
	[5] = "set:Frozen_Lottery image:Frozen_Lottery_N5",
	[6] = "set:Frozen_Lottery image:Frozen_Lottery_N6",
	[7] = "set:Frozen_Lottery image:Frozen_Lottery_N7",
	[8] = "set:Frozen_Lottery image:Frozen_Lottery_N8",
	[9] = "set:Frozen_Lottery image:Frozen_Lottery_N9",
}

--本期中奖号码逻辑
local g_Frozen_Lottery_now_num_picInfo = 
{
	[0] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N10",
	[1] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N1",
	[2] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N2",
	[3] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N3",
	[4] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N4",
	[5] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N5",
	[6] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N6",
	[7] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N7",
	[8] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N8",
	[9] = "set:Frozen_Lottery image:Frozen_Lottery_Machine_N9",
}

-- 自己竞猜号码逻辑
local g_Frozen_Lottery_prize_num_picInfo = 
{
	[0] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N10",
	[1] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N1",
	[2] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N2",
	[3] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N3",
	[4] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N4",
	[5] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N5",
	[6] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N6",
	[7] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N7",
	[8] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N8",
	[9] = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_N9",
}


local g_Frozen_Lottery_num_defualut = "set:Frozen_Lottery image:Frozen_Lottery_Null"


local g_Frozen_Lottery_now_num_defualut = "set:Frozen_Lottery image:Frozen_Lottery_Machine_Null"

local g_Frozen_Lottery_prize_num_defualut = "set:Frozen_Lottery image:Frozen_Lottery_Ticket_Null"

local g_Frozen_Lottery_PirzeDarwPic ={}
local g_Frozen_Lottery_RewradInfo =
{
	[1] = {itemid=39925106, neednum=4,msg="#{WHCJ_251018_23}",img="set:Frozen_Lottery image:Frozen_Lottery_Reward1"},
	[2] = {itemid=39925107, neednum=3,msg="#{WHCJ_251018_23}",img="set:Frozen_Lottery image:Frozen_Lottery_Reward2"},
	[3] = {itemid=39925096, neednum=2,msg="#{WHCJ_251018_23}",img="set:Frozen_Lottery image:Frozen_Lottery_Reward3"},
	[4] = {itemid=39920109, neednum=0,msg="#{WHCJ_251018_24}",img="set:Frozen_Lottery image:Frozen_Lottery_Reward4"},
}

local g_Frozen_Lottery_Now_Data = {}
local g_Frozen_Lottery_Select = 0

local g_Frozen_Lottery_RewardOkItem = {} -- 领奖ok
local g_Frozen_Lottery_RewardTips = {}	 -- 领奖tips

local g_Frozen_Lottery_ItemId = 38008223 --券id
local g_Frozen_Lottery_NeedItemCount = 10

local g_Frozen_Lottery_UpDownBtnList= {}
local g_Frozen_Lottery_Ticket={}   -- 显示数字
local g_Frozen_Lottery_TicketChest={} -- 物品按钮
local g_Frozen_Lottery_TIcketOk={} -- 已领取
local g_Frozen_Lottery_TicketTips={} -- 待领取

local g_Frozen_Lottery_BkText={} -- 当前按钮
local g_Frozen_Lottery_Status={} -- 几等奖


local g_Frozen_Lottery_Empty={} -- 未填写逻辑
local g_Frozen_Lottery_HavePrize={} -- 填写逻辑

local g_Frozen_Lottery_Title={} -- 第几张券 文字
local g_Frozen_Lottery_Noraml_BK={} --默认背景

local g_Frozen_Lottery_ChestGroup={}

--===============================================
-- OnLoad()
--===============================================
function Frozen_Lottery_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("OPEN_ICE_PRIZE_DRAW")
	this:RegisterEvent("ICE_PRIZE_DRAW_ING")
	this:RegisterEvent("ICE_PRIZE_DRAW_REWARD")
	this:RegisterEvent("PACKAGE_ITEM_CHANGED")
end

--===============================================
-- OnLoad()
--===============================================
function Frozen_Lottery_OnLoad()   
	-- 保存界面的默认相对位置
	g_Frozen_Lottery_Frame_UnifiedPosition = Frozen_Lottery_Frame:GetProperty("UnifiedPosition");
	
	g_Frozen_Lottery_PirzeDarwPic[1] =Frozen_Lottery_Number_1
	g_Frozen_Lottery_PirzeDarwPic[2] =Frozen_Lottery_Number_2
	g_Frozen_Lottery_PirzeDarwPic[3] =Frozen_Lottery_Number_3
	g_Frozen_Lottery_PirzeDarwPic[4] =Frozen_Lottery_Number_4

	g_Frozen_Lottery_RewardOkItem[1] = Frozen_Lottery_Rward_1_Item_OK
	g_Frozen_Lottery_RewardOkItem[2] = Frozen_Lottery_Rward_2_Item_OK
	g_Frozen_Lottery_RewardOkItem[3] = Frozen_Lottery_Rward_3_Item_OK
	g_Frozen_Lottery_RewardOkItem[4] = Frozen_Lottery_Rward_4_Item_OK


	g_Frozen_Lottery_RewardTips[1] = Frozen_Lottery_Rward_1_Item_Tips
	g_Frozen_Lottery_RewardTips[2] = Frozen_Lottery_Rward_2_Item_Tips
	g_Frozen_Lottery_RewardTips[3] = Frozen_Lottery_Rward_3_Item_Tips
	g_Frozen_Lottery_RewardTips[4] = Frozen_Lottery_Rward_4_Item_Tips


	g_Frozen_Lottery_UpDownBtnList[1] = Frozen_Lottery_Number_1_UpBtn
	g_Frozen_Lottery_UpDownBtnList[2] = Frozen_Lottery_Number_2_UpBtn
	g_Frozen_Lottery_UpDownBtnList[3] = Frozen_Lottery_Number_3_UpBtn
	g_Frozen_Lottery_UpDownBtnList[4] = Frozen_Lottery_Number_4_UpBtn

	g_Frozen_Lottery_UpDownBtnList[5] = Frozen_Lottery_Number_1_DownBtn
	g_Frozen_Lottery_UpDownBtnList[6] = Frozen_Lottery_Number_2_DownBtn
	g_Frozen_Lottery_UpDownBtnList[7] = Frozen_Lottery_Number_3_DownBtn
	g_Frozen_Lottery_UpDownBtnList[8] = Frozen_Lottery_Number_4_DownBtn


	g_Frozen_Lottery_Ticket[1] =
	{
		[1]=Frozen_Lottery_Ticket_01_Num1,
		[2]=Frozen_Lottery_Ticket_01_Num2,
		[3]=Frozen_Lottery_Ticket_01_Num3,
		[4]=Frozen_Lottery_Ticket_01_Num4,
	}


	g_Frozen_Lottery_Ticket[2] =
	{
		[1]=Frozen_Lottery_Ticket_02_Num1,
		[2]=Frozen_Lottery_Ticket_02_Num2,
		[3]=Frozen_Lottery_Ticket_02_Num3,
		[4]=Frozen_Lottery_Ticket_02_Num4,
	}

	g_Frozen_Lottery_Ticket[3] =
	{
		[1]=Frozen_Lottery_Ticket_03_Num1,
		[2]=Frozen_Lottery_Ticket_03_Num2,
		[3]=Frozen_Lottery_Ticket_03_Num3,
		[4]=Frozen_Lottery_Ticket_03_Num4,
	}

	g_Frozen_Lottery_Ticket[4] =
	{
		[1]=Frozen_Lottery_Ticket_04_Num1,
		[2]=Frozen_Lottery_Ticket_04_Num2,
		[3]=Frozen_Lottery_Ticket_04_Num3,
		[4]=Frozen_Lottery_Ticket_04_Num4,
	}


	g_Frozen_Lottery_TicketChest[1] = Frozen_Lottery_Ticket_01_Chest
	g_Frozen_Lottery_TicketChest[2] = Frozen_Lottery_Ticket_02_Chest
	g_Frozen_Lottery_TicketChest[3] = Frozen_Lottery_Ticket_03_Chest
	g_Frozen_Lottery_TicketChest[4] = Frozen_Lottery_Ticket_04_Chest


	g_Frozen_Lottery_TIcketOk[1] = Frozen_Lottery_Ticket_01_Chest_OK
	g_Frozen_Lottery_TIcketOk[2] = Frozen_Lottery_Ticket_02_Chest_OK
	g_Frozen_Lottery_TIcketOk[3] = Frozen_Lottery_Ticket_03_Chest_OK
	g_Frozen_Lottery_TIcketOk[4] = Frozen_Lottery_Ticket_04_Chest_OK

	g_Frozen_Lottery_TicketTips[1]= Frozen_Lottery_Ticket_01_Chest_Tips
	g_Frozen_Lottery_TicketTips[2]= Frozen_Lottery_Ticket_02_Chest_Tips
	g_Frozen_Lottery_TicketTips[3]= Frozen_Lottery_Ticket_03_Chest_Tips
	g_Frozen_Lottery_TicketTips[4]= Frozen_Lottery_Ticket_04_Chest_Tips

	g_Frozen_Lottery_BkText[1] = Frozen_Lottery_Ticket_01_HoverBK
	g_Frozen_Lottery_BkText[2] = Frozen_Lottery_Ticket_02_HoverBK
	g_Frozen_Lottery_BkText[3] = Frozen_Lottery_Ticket_03_HoverBK
	g_Frozen_Lottery_BkText[4] = Frozen_Lottery_Ticket_04_HoverBK

	g_Frozen_Lottery_Status[1] = Frozen_Lottery_Ticket_01_KaiJiangStatus
	g_Frozen_Lottery_Status[2] = Frozen_Lottery_Ticket_02_KaiJiangStatus
	g_Frozen_Lottery_Status[3] = Frozen_Lottery_Ticket_03_KaiJiangStatus
	g_Frozen_Lottery_Status[4] = Frozen_Lottery_Ticket_04_KaiJiangStatus


	g_Frozen_Lottery_Empty[1] = Frozen_Lottery_Ticket_01_Empty
	g_Frozen_Lottery_Empty[2] = Frozen_Lottery_Ticket_02_Empty
	g_Frozen_Lottery_Empty[3] = Frozen_Lottery_Ticket_03_Empty
	g_Frozen_Lottery_Empty[4] = Frozen_Lottery_Ticket_04_Empty

	g_Frozen_Lottery_HavePrize[1]=Frozen_Lottery_Ticket_01
	g_Frozen_Lottery_HavePrize[2]=Frozen_Lottery_Ticket_02
	g_Frozen_Lottery_HavePrize[3]=Frozen_Lottery_Ticket_03
	g_Frozen_Lottery_HavePrize[4]=Frozen_Lottery_Ticket_04

	g_Frozen_Lottery_Title[1] = Frozen_Lottery_Ticket_01_NormalBK_Title
	g_Frozen_Lottery_Title[2] = Frozen_Lottery_Ticket_02_NormalBK_Title
	g_Frozen_Lottery_Title[3] = Frozen_Lottery_Ticket_03_NormalBK_Title
	g_Frozen_Lottery_Title[4] = Frozen_Lottery_Ticket_04_NormalBK_Title

	g_Frozen_Lottery_Noraml_BK[1] = Frozen_Lottery_Ticket_01_NormalBK
	g_Frozen_Lottery_Noraml_BK[2] = Frozen_Lottery_Ticket_02_NormalBK
	g_Frozen_Lottery_Noraml_BK[3] = Frozen_Lottery_Ticket_03_NormalBK
	g_Frozen_Lottery_Noraml_BK[4] = Frozen_Lottery_Ticket_04_NormalBK

	g_Frozen_Lottery_ChestGroup[1]=Frozen_Lottery_Ticket_01_ChestGroup
	g_Frozen_Lottery_ChestGroup[2]=Frozen_Lottery_Ticket_02_ChestGroup
	g_Frozen_Lottery_ChestGroup[3]=Frozen_Lottery_Ticket_03_ChestGroup
	g_Frozen_Lottery_ChestGroup[4]=Frozen_Lottery_Ticket_04_ChestGroup

	for i = 1, 4 do
		g_Frozen_Lottery_Now_Data[i] = 0
	end

end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_Lottery_Frame_On_ResetPos()
	Frozen_Lottery_Frame:SetProperty("UnifiedPosition", g_Frozen_Lottery_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function Frozen_Lottery_OnEvent(event)

    if(event == "OPEN_ICE_PRIZE_DRAW") then
		--打开界面
		Frozen_Lottery_BeginCareObject(tonumber(arg0))
		Frozen_Lottery_Open()
		this:Show()
	elseif event == "ICE_PRIZE_DRAW_ING" then
		-- 更新竞猜次数信息
		local nItemCount =	PlayerPackage:CountAvailableItemByIDTable(tonumber(g_Frozen_Lottery_ItemId))
		local strN = ScriptGlobal_Format("#{WHCJ_251018_74}", nItemCount)
		if nItemCount < g_Frozen_Lottery_NeedItemCount then
			Frozen_Lottery_QuanNumberInfo:SetText(strN)
		else
			strN = ScriptGlobal_Format("#{WHCJ_251018_20}", nItemCount)
			Frozen_Lottery_QuanNumberInfo:SetText(strN)
		end


		-- 剩余竞猜信息
		local nPrizeCount = DataPool:LuaFnGetIcePrizeDrawCount(g_Frozen_Lottery_Select)
		strN = ScriptGlobal_Format("#{WHCJ_251018_19}", 4-nPrizeCount)
		Frozen_Lottery_PageInfo:SetText(strN)

		--刷新当前选择的界面
		Frozen_Lottery_Update_DrawInfo(g_Frozen_Lottery_Select)

	elseif event == "ICE_PRIZE_DRAW_REWARD" then
		-- 更新竞猜次数信息
		local nItemCount =	PlayerPackage:CountAvailableItemByIDTable(tonumber(g_Frozen_Lottery_ItemId))
		local strN = ScriptGlobal_Format("#{WHCJ_251018_74}", nItemCount)
		if nItemCount < g_Frozen_Lottery_NeedItemCount then
			Frozen_Lottery_QuanNumberInfo:SetText(strN)
		else
			strN = ScriptGlobal_Format("#{WHCJ_251018_20}", nItemCount)
			Frozen_Lottery_QuanNumberInfo:SetText(strN)
		end

		-- 更新下拉
		Frozen_Lottery_Updata_XiaLaInfo(g_Frozen_Lottery_Select)
		Frozen_Lottery_XiaLa:SetCurrentSelect(g_Frozen_Lottery_Select)
		
		--刷新当前选择的界面
		Frozen_Lottery_Update_DrawInfo(g_Frozen_Lottery_Select)

	elseif (event == "PACKAGE_ITEM_CHANGED" and this:IsVisible()) then
		local nItemCount =	PlayerPackage:CountAvailableItemByIDTable(tonumber(g_Frozen_Lottery_ItemId))
		if nItemCount < g_Frozen_Lottery_NeedItemCount then
			local strN = ScriptGlobal_Format("#{WHCJ_251018_74}", nItemCount)
			Frozen_Lottery_QuanNumberInfo:SetText(strN)
		else
			local strN = ScriptGlobal_Format("#{WHCJ_251018_20}", nItemCount)
			Frozen_Lottery_QuanNumberInfo:SetText(strN)
		end

		-- 某逻辑对象的某些发生改变
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_Frozen_Lottery_objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			
			--取消关心
			Frozen_Lottery_StopCareObject();
		end	
	end
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Frozen_Lottery_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_Lottery_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       Frozen_Lottery_OnClose()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end
         
end

--===============================================
-- Frozen_Lottery_OnClose()
--===============================================
function Frozen_Lottery_OnClose()
	Frozen_Lottery_StopCareObject()
	this:Hide()
end


function Frozen_Lottery_Random_Btn_OnClick()
	local nState = DataPool:LuaFnGetIcePrizeDrawNowState()
	if nState ~= 1 then
		return
	end

	for i = 1, 4 do 
		g_Frozen_Lottery_Now_Data[i] = math.random( 0, 9 )
	end
	
	for i = 1, 4 do 
		g_Frozen_Lottery_PirzeDarwPic[i]:SetProperty ("Image", g_Frozen_Lottery_num_picInfo[g_Frozen_Lottery_Now_Data[i]])
	end
end

--=========================================================
--默认打开界面
--=========================================================
function Frozen_Lottery_Open()
	Frozen_Lottery_Init()
	this:Show()		
end


--=========================================================
--帮助
--=========================================================
function Frozen_Lottery_Intro_HelpBtn_OnClieck()
	PushEvent("QUEST_HELPINFO", "#{WHCJ_251018_08}")
end


function Frozen_Lottery_XiaLa_Changed()
	local str, nIndex = Frozen_Lottery_XiaLa:GetCurrentSelect()
	Frozen_Lottery_Update_DrawInfo(nIndex)
end


-- 初始化
function Frozen_Lottery_Init()
	
	local nNowId = DataPool:LuaFnGetIcePrizeDrawNowId()
	local nState = DataPool:LuaFnGetIcePrizeDrawNowState()

	Frozen_Lottery_CommonInfo_ItemBK_DangQianHoverBK1:Hide()
	Frozen_Lottery_CommonInfo_ItemBK_DangQianHoverBK2:Hide()
	Frozen_Lottery_CommonInfo_ItemBK_DangQianHoverBK3:Hide()

	Frozen_Lottery_CommonInfo_JingPai:Show()
	Frozen_Lottery_CommonInfo_YaoHao:Show()
	Frozen_Lottery_CommonInfo_KaiJiang:Show()

	if nState == 1 then 
		Frozen_Lottery_CommonInfo_ItemBK_DangQianHoverBK1:Show()
	elseif nState == 2 then
		Frozen_Lottery_CommonInfo_ItemBK_DangQianHoverBK2:Show()
	elseif nState == 3 then
		Frozen_Lottery_CommonInfo_ItemBK_DangQianHoverBK3:Show()
	end

	local nNowIndex = Frozen_Lottery_Updata_XiaLaInfo(-1)

	-- 更新竞猜次数信息
	local nItemCount =	PlayerPackage:CountAvailableItemByIDTable(tonumber(g_Frozen_Lottery_ItemId))
	local strN = ScriptGlobal_Format("#{WHCJ_251018_74}", nItemCount)
	if nItemCount < g_Frozen_Lottery_NeedItemCount then
		Frozen_Lottery_QuanNumberInfo:SetText(strN)
	else
		strN = ScriptGlobal_Format("#{WHCJ_251018_20}", nItemCount)
		Frozen_Lottery_QuanNumberInfo:SetText(strN)
	end


	-- 剩余竞猜信息
	local nPrizeCount = DataPool:LuaFnGetIcePrizeDrawCount(nNowIndex)
	strN = ScriptGlobal_Format("#{WHCJ_251018_19}", 4-nPrizeCount)
	Frozen_Lottery_PageInfo:SetText(strN)

	--刷新当前选择的界面
	Frozen_Lottery_Update_DrawInfo(nNowIndex)
end


function Frozen_Lottery_Updata_XiaLaInfo(nindex)
	local nListCount = DataPool:LuaFnGetIcePrizeDrawListCount()
	local nNowIndex = 0
	local nHaveReward = 0
	Frozen_Lottery_XiaLa:ResetList()
	for i=1, nListCount do
		--更新数据== 
		local id,drawData,bend,havereward = DataPool:LuaFnGetIcePrizeDrawInfo(i-1)
		if id == nNowId then 
			nNowIndex = i -1
		end

		-- 名字
		local strN = ScriptGlobal_Format("#{WHCJ_251018_67}", id)
		if id == nNowId then
			strN =  strN.."#{WHCJ_251018_12}"
		end

		-- 可领奖
		if havereward == 1 then
			strN = strN .. "#{WHCJ_251018_70}"
			nHaveReward = 1
		end

		Frozen_Lottery_XiaLa:AddTextItem(strN, i-1)
	end

	if nindex < 0 then
		Frozen_Lottery_XiaLa:SetText("#{WHCJ_251018_66}")
	else
		Frozen_Lottery_XiaLa:SetCurrentSelect(nindex)
	end

	if nHaveReward == 0 then
		Frozen_Lottery_XiaLa_RedDot:Hide()
	else
		Frozen_Lottery_XiaLa_RedDot:Show()
	end

	return nNowIndex
end

-- 初始化
function Frozen_Lottery_Update_DrawInfo(index)
	local nNowId = DataPool:LuaFnGetIcePrizeDrawNowId()
	local nState = DataPool:LuaFnGetIcePrizeDrawNowState()

	Frozen_Lottery_Clear_PrizeDraw_Data()

	-- 设置当前选择项
	g_Frozen_Lottery_Select = index

	-- 如果是当前期 显示开奖的数字
	Frozen_Lottery_NumberThisTime_Client:Hide()

	local id,nPrizedrawData,bEndTime = DataPool:LuaFnGetIcePrizeDrawInfo(index)
	local nDrawData, breward = DataPool:LuaFnGetIcePrizeDrawDataByInDex(index,selectIndex)

	Frozen_Lottery_Random_Btn:Disable()
	for i = 1, table.getn(g_Frozen_Lottery_UpDownBtnList) do
		g_Frozen_Lottery_UpDownBtnList[i]:Disable()
	end

	local nPrizeCount = DataPool:LuaFnGetIcePrizeDrawCountById(nNowId)
	for i = 1, table.getn(g_Frozen_Lottery_PirzeDarwPic) do
		g_Frozen_Lottery_PirzeDarwPic[i]:SetProperty ("Image", g_Frozen_Lottery_num_picInfo[0])
	end

	-- 判断当前是否有中奖号码出现
	if nPrizedrawData  < 0 then
		Frozen_Lottery_JingCaiStatus:Show()
	else
		Frozen_Lottery_JingCaiStatus:Hide()
	end
	Frozen_Lottery_Show_Prize_Draw_Data(nPrizedrawData)


	-- 显示自己竞猜信息
	Frozen_Lottery_ShowMyPrizeDrawData(index)
	
	local nItemCount =	PlayerPackage:CountAvailableItemByIDTable(tonumber(g_Frozen_Lottery_ItemId))

	--PushDebugMessage("id="..id.."nowid="..nNowId.."nstate="..nState.."nPrize="..nPrizeCount)
	if nNowId == id and  nItemCount >= g_Frozen_Lottery_NeedItemCount and nState == 1 and nPrizeCount < 4 then

		for i = 1, table.getn(g_Frozen_Lottery_UpDownBtnList) do
			g_Frozen_Lottery_UpDownBtnList[i]:Enable()
		end
		Frozen_Lottery_Random_Btn:Enable()
	end
end


function Frozen_Lottery_Show_Prize_Draw_Data(nData)
	-- 如果没有数据 默认 0
	if nData < 0 then
		Frozen_Lottery_NumberThisTime_4:SetProperty ("Image", g_Frozen_Lottery_now_num_defualut)
		Frozen_Lottery_NumberThisTime_3:SetProperty ("Image", g_Frozen_Lottery_now_num_defualut)
		Frozen_Lottery_NumberThisTime_2:SetProperty ("Image", g_Frozen_Lottery_now_num_defualut)
		Frozen_Lottery_NumberThisTime_1:SetProperty ("Image", g_Frozen_Lottery_now_num_defualut)
		Frozen_Lottery_NumberThisTime_Client:Show()

		Frozen_Lottery_Animate1:Hide()
		Frozen_Lottery_Animate2:Hide()
		Frozen_Lottery_Animate3:Hide()
		Frozen_Lottery_Animate4:Hide()
		return
	end

	local nNum = {}
	local nTempData = nData
	for i = 1, 4 do 
		nNum[i] = math.mod(nTempData,10)
		nTempData = math.floor(nTempData/10)
	end

	Frozen_Lottery_NumberThisTime_4:SetProperty ("Image", g_Frozen_Lottery_now_num_picInfo[nNum[1]])
	Frozen_Lottery_NumberThisTime_3:SetProperty ("Image", g_Frozen_Lottery_now_num_picInfo[nNum[2]])
	Frozen_Lottery_NumberThisTime_2:SetProperty ("Image", g_Frozen_Lottery_now_num_picInfo[nNum[3]])
	Frozen_Lottery_NumberThisTime_1:SetProperty ("Image", g_Frozen_Lottery_now_num_picInfo[nNum[4]])

	Frozen_Lottery_Animate1:Show()
	Frozen_Lottery_Animate2:Show()
	Frozen_Lottery_Animate3:Show()
	Frozen_Lottery_Animate4:Show()

	Frozen_Lottery_NumberThisTime_Client:Show()
end

-- 竞猜
function Frozen_Lottery_Confirm_Btn_OnClick()
	local nData = g_Frozen_Lottery_Now_Data[1]*1000+g_Frozen_Lottery_Now_Data[2]*100+g_Frozen_Lottery_Now_Data[3]*10+g_Frozen_Lottery_Now_Data[4]

	local nItemCount =	PlayerPackage:CountAvailableItemByIDTable(tonumber(g_Frozen_Lottery_ItemId))
	if nItemCount < g_Frozen_Lottery_NeedItemCount then
		PushDebugMessage("#{WHCJ_251018_38}")
		return
	end

	local nState = DataPool:LuaFnGetIcePrizeDrawNowState()
	if nState ~= 1 then
		PushDebugMessage("#{WHCJ_251018_28}")
		return
	end

	local nNowId = DataPool:LuaFnGetIcePrizeDrawNowId()
	local nPrizeCount = DataPool:LuaFnGetIcePrizeDrawCountById(nNowId)
	if nPrizeCount >= 4 then
		PushDebugMessage("#{WHCJ_251018_37}")
		return
	end

	-- 请求舞会抽奖
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("IcePrizeDrawIng")
		Set_XSCRIPT_ScriptID(999780)
		Set_XSCRIPT_Parameter(0, nData)
		Set_XSCRIPT_Parameter(1, g_Frozen_Lottery_targetId)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end


-- 上选择号码
function Frozen_Lottery_Number_UpBtnOnClick(nIndex)
	if g_Frozen_Lottery_PirzeDarwPic[nIndex] == nil then
		return
	end
	
	if g_Frozen_Lottery_Now_Data[nIndex] == nil then
		return
	end

	local nNowData = g_Frozen_Lottery_Now_Data[nIndex]
	local nNewIndex =  math.mod(nNowData+10-1,10)
	g_Frozen_Lottery_Now_Data[nIndex] = nNewIndex
	g_Frozen_Lottery_PirzeDarwPic[nIndex]:SetProperty ("Image", g_Frozen_Lottery_num_picInfo[nNewIndex])

end

-- 下选择号码
function Frozen_Lottery_Number_DownBtnOnClick(nIndex)
	if g_Frozen_Lottery_PirzeDarwPic[nIndex] == nil then
		return
	end
	
	if g_Frozen_Lottery_Now_Data[nIndex] == nil then
		return
	end

	local nNowData = g_Frozen_Lottery_Now_Data[nIndex]
	local nNewIndex =  math.mod(nNowData+1,10)
	g_Frozen_Lottery_Now_Data[nIndex] = nNewIndex
	g_Frozen_Lottery_PirzeDarwPic[nIndex]:SetProperty ("Image", g_Frozen_Lottery_num_picInfo[nNewIndex])

end

-- 显示当前自己选择的内容
function Frozen_Lottery_ShowMyPrizeDrawData(index)

	local id,nPrizedrawData,bEndTime = DataPool:LuaFnGetIcePrizeDrawInfo(index)
	local nNowId = DataPool:LuaFnGetIcePrizeDrawNowId()
	local nState = DataPool:LuaFnGetIcePrizeDrawNowState()

	local nNowIndex = 0
	for npos = 1, 4 do 
		--当前按钮显示
		g_Frozen_Lottery_BkText[npos]:Hide()
		g_Frozen_Lottery_TIcketOk[npos]:Hide()
		g_Frozen_Lottery_TicketTips[npos]:Hide()
		
		g_Frozen_Lottery_Empty[npos]:Hide() -- 未填写Hide
		g_Frozen_Lottery_HavePrize[npos]:Show() -- 主要内容show
		g_Frozen_Lottery_TicketChest[npos]:Hide() -- 奖励Hide
		g_Frozen_Lottery_Status[npos]:Hide()	-- 几等奖Hide
		g_Frozen_Lottery_Title[npos]:Show() -- 第几张券show
		g_Frozen_Lottery_Noraml_BK[npos]:Hide() -- 默认背景Hide
		g_Frozen_Lottery_ChestGroup[npos]:Hide()

		-- 获取当前自己选择的内容
		local nPrizeData,breward = DataPool:LuaFnGetIcePrizeDrawDataByInDex(index,npos-1)
		if g_Frozen_Lottery_Ticket[npos] ~= nil then
			if nPrizeData < 0 then -- 如果还未竞猜
				if nNowId ~= id then -- 如果非当前期
					g_Frozen_Lottery_Empty[npos]:Show()
					for i = 1, table.getn(g_Frozen_Lottery_Ticket[npos]) do  
						g_Frozen_Lottery_Ticket[npos][i]:Hide()
					end

				else -- 如果是当前期
					if  nNowIndex == 0 and nState == 1 then
						g_Frozen_Lottery_BkText[npos]:Show()
						nNowIndex= 1
					end

					g_Frozen_Lottery_Noraml_BK[npos]:Show()
					-- 数字
					for i = 1,  table.getn(g_Frozen_Lottery_Ticket[npos]) do
						g_Frozen_Lottery_Ticket[npos][i]:SetProperty ("Image", g_Frozen_Lottery_prize_num_defualut)
						g_Frozen_Lottery_Ticket[npos][i]:Show()
					end		
				end		
				
			else -- 如果竞猜了
				-- 显示数字
				for i = 1,  table.getn(g_Frozen_Lottery_Ticket[npos]) do
					local nIndex = Frozen_Lottery_GetPictIndex(nPrizeData,i)
					g_Frozen_Lottery_Ticket[npos][i]:SetProperty ("Image", g_Frozen_Lottery_prize_num_picInfo[nIndex])
					g_Frozen_Lottery_Ticket[npos][i]:Show()
				end

				-- 显示背景
				g_Frozen_Lottery_Noraml_BK[npos]:Show()
				-- 显示奖励 显示几等奖
				if nPrizedrawData > 0 then
					local nNum = Frozen_Lottery_RewardCount(nPrizedrawData,nPrizeData)
					local nRewardItem  = -1
					for i = 1, table.getn(g_Frozen_Lottery_RewradInfo) do
						if g_Frozen_Lottery_RewradInfo[i].neednum <= nNum then
							nRewardItem  = g_Frozen_Lottery_RewradInfo[i].itemid 
							g_Frozen_Lottery_ChestGroup[npos]:Show()
							g_Frozen_Lottery_Status[npos]:SetProperty ("Image", g_Frozen_Lottery_RewradInfo[i].img)
							g_Frozen_Lottery_Status[npos]:Show()
							break
						end
					end

					-- 奖励物品信息
					if nRewardItem > 0 then
						local theAction = DataPool:CreateActionItemForShow(nRewardItem, 1) 
						if (theAction:GetID() ~= 0) then
							g_Frozen_Lottery_TicketChest[npos]:SetActionItem(theAction:GetID())
							g_Frozen_Lottery_TicketChest[npos]:Show()
						end 
					end

					-- 是否可以领取
					if bEndTime == 0  and breward == 0 then
						g_Frozen_Lottery_TicketTips[npos]:Show()
						g_Frozen_Lottery_TicketChest[npos]:Enable()
					end
				end
				
				-- 已经领取奖励
				if breward == 1 then
					g_Frozen_Lottery_TIcketOk[npos]:Show()
				end
			end
		end

	end

end

function Frozen_Lottery_GetPictIndex(ndata,nIndex)

	local nNum = {}
	local nTempData = ndata
	for i = 1, 4 do 
		nNum[4+1-i] = math.mod(nTempData,10)
		nTempData = math.floor(nTempData/10)
	end

	return nNum[nIndex]
end

function Frozen_Lottery_RewardCount(nPrizeData, nMyData)

	local nCount = 0
	local nTempPrize = nPrizeData
	local nTempMyData = nMyData
	for i = 1, 4 do 
		if math.mod(nTempPrize,10) == math.mod(nTempMyData,10) then
			nCount = nCount+1
		end
		nTempPrize = math.floor(nTempPrize/10)
		nTempMyData = math.floor(nTempMyData/10)
	end

	return nCount
end

-- 清空当前自己选择的数据信息
function Frozen_Lottery_Clear_PrizeDraw_Data()
	for i = 1, 4 do
		g_Frozen_Lottery_Now_Data[i] = 0
	end
end

-- 点击领取奖励
function Frozen_Lottery_Ticket_Chest(nIndex)
	-- 请求舞会抽奖
	local id,nPrizedrawData,bEndTime = DataPool:LuaFnGetIcePrizeDrawInfo(g_Frozen_Lottery_Select)

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("IcePrizeDrawReward")
		Set_XSCRIPT_ScriptID(999780)
		Set_XSCRIPT_Parameter(0, id)
		Set_XSCRIPT_Parameter(1, nIndex-1)
		Set_XSCRIPT_Parameter(2, g_Frozen_Lottery_targetId)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function Frozen_Lottery_BeginCareObject( objCaredId )
	g_Frozen_Lottery_targetId = objCaredId
	g_Frozen_Lottery_objCared = DataPool : GetNPCIDByServerID( objCaredId )
	if g_Frozen_Lottery_objCared == -1 then
		this : Hide()
		return
	end

	this : CareObject( g_Frozen_Lottery_objCared, 1, "Frozen_Lottery" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function Frozen_Lottery_StopCareObject()
	this : CareObject( g_Frozen_Lottery_objCared, 0, "Frozen_Lottery" )
	g_Frozen_Lottery_objCared = -1
	g_Frozen_Lottery_targetId = -1
end