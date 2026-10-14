--供奉界面


local g_NewFriend_GF_Frame_UnifiedXPosition;

local g_NewFriend_GF_Frame_UnifiedYPosition;

local g_NewFriend_GF_GongfengText = {}
local g_NewFriend_GF_GongfengCheck = {}
local g_NewFriend_GF_GongfengCheckText = {}
local g_NewFriend_GF_GongfengMoney = {}
local g_NewFriend_GF_GongfengMoneyText = {}
local g_NewFriend_GF_GongfengGUID = {}
local g_NewFriend_GF_GongfengData = {}

local g_NewFriend_GF_Money = 50000

local g_NewFriend_GF_PrizeItemID = {
	38001274,
	38001275,
}

local g_NewFriend_GF_PrizeIcon = {}

function NewFriend_GF_PreLoad()
	--开启界面
	this:RegisterEvent("OPEN_NEWFRIEND_GF")
	
	this:RegisterEvent("ADJEST_UI_POS",false);

	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	--this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent( "UPDATE_SERVER_TIME_UI" )
end	

function NewFriend_GF_OnLoad()

	-- 保存界面的默认相对位置
	g_NewFriend_GF_Frame_UnifiedXPosition	= NewFriend_GF_Frame : GetProperty("UnifiedXPosition");
	g_NewFriend_GF_Frame_UnifiedYPosition	= NewFriend_GF_Frame : GetProperty("UnifiedYPosition");

	g_NewFriend_GF_GongfengText[1] = NewFriend_GF_Text0_1
	g_NewFriend_GF_GongfengText[2] = NewFriend_GF_Text1_1
	g_NewFriend_GF_GongfengText[3] = NewFriend_GF_Text2_1
	g_NewFriend_GF_GongfengText[4] = NewFriend_GF_Text3_1
	g_NewFriend_GF_GongfengText[5] = NewFriend_GF_Text4_1
	g_NewFriend_GF_GongfengText[6] = NewFriend_GF_Text5_1
	g_NewFriend_GF_GongfengText[7] = NewFriend_GF_Text6_1
	g_NewFriend_GF_GongfengText[8] = NewFriend_GF_Text7_1
	
	g_NewFriend_GF_GongfengCheck[1] = NewFriend_GF_DX0_1
	g_NewFriend_GF_GongfengCheck[2] = NewFriend_GF_DX1_1
	g_NewFriend_GF_GongfengCheck[3] = NewFriend_GF_DX2_1
	g_NewFriend_GF_GongfengCheck[4] = NewFriend_GF_DX3_1
	g_NewFriend_GF_GongfengCheck[5] = NewFriend_GF_DX4_1
	g_NewFriend_GF_GongfengCheck[6] = NewFriend_GF_DX5_1
	g_NewFriend_GF_GongfengCheck[7] = NewFriend_GF_DX6_1
	g_NewFriend_GF_GongfengCheck[8] = NewFriend_GF_DX7_1
	
	g_NewFriend_GF_GongfengCheckText[1] = NewFriend_GF_DX0_1Text
	g_NewFriend_GF_GongfengCheckText[2] = NewFriend_GF_DX1_1Text
	g_NewFriend_GF_GongfengCheckText[3] = NewFriend_GF_DX2_1Text
	g_NewFriend_GF_GongfengCheckText[4] = NewFriend_GF_DX3_1Text
	g_NewFriend_GF_GongfengCheckText[5] = NewFriend_GF_DX4_1Text
	g_NewFriend_GF_GongfengCheckText[6] = NewFriend_GF_DX5_1Text
	g_NewFriend_GF_GongfengCheckText[7] = NewFriend_GF_DX6_1Text
	g_NewFriend_GF_GongfengCheckText[8] = NewFriend_GF_DX7_1Text
	
	g_NewFriend_GF_GongfengMoney[1] = NewFriend_GF_DX0_2
	g_NewFriend_GF_GongfengMoney[2] = NewFriend_GF_DX1_2
	g_NewFriend_GF_GongfengMoney[3] = NewFriend_GF_DX2_2
	g_NewFriend_GF_GongfengMoney[4] = NewFriend_GF_DX3_2
	g_NewFriend_GF_GongfengMoney[5] = NewFriend_GF_DX4_2
	g_NewFriend_GF_GongfengMoney[6] = NewFriend_GF_DX5_2
	g_NewFriend_GF_GongfengMoney[7] = NewFriend_GF_DX6_2
	g_NewFriend_GF_GongfengMoney[8] = NewFriend_GF_DX7_2
	
	g_NewFriend_GF_GongfengMoneyText[1] = NewFriend_GF_DX0_2Text
	g_NewFriend_GF_GongfengMoneyText[2] = NewFriend_GF_DX1_2Text
	g_NewFriend_GF_GongfengMoneyText[3] = NewFriend_GF_DX2_2Text
	g_NewFriend_GF_GongfengMoneyText[4] = NewFriend_GF_DX3_2Text
	g_NewFriend_GF_GongfengMoneyText[5] = NewFriend_GF_DX4_2Text
	g_NewFriend_GF_GongfengMoneyText[6] = NewFriend_GF_DX5_2Text
	g_NewFriend_GF_GongfengMoneyText[7] = NewFriend_GF_DX6_2Text
	g_NewFriend_GF_GongfengMoneyText[8] = NewFriend_GF_DX7_2Text
	
	g_NewFriend_GF_PrizeIcon[1] = NewFriend_GF_GetIcon1
	g_NewFriend_GF_PrizeIcon[2] = NewFriend_GF_GetIcon2
end

function NewFriend_GF_OnEvent(event)

	if ( event == "OPEN_NEWFRIEND_GF") then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskGongfengMD")
			Set_XSCRIPT_ScriptID(891113)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
		NewFriend_GF_Open();

	--(点击领取之后，刷新状态)
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89111301) then
		local nGUIDH = tonumber(Get_XParam_INT(0))
		local nGUIDL = tonumber(Get_XParam_INT(1))
		local nMoney = tonumber(Get_XParam_INT(2))
		NewFriend_GF_Update(nGUIDH, nGUIDL, nMoney)
		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89111302) then
		local nGongfengMD = tonumber(Get_XParam_INT(0))
		local strInfo = ScriptGlobal_Format("#{STGZ_150514_189}", tostring(nGongfengMD))
		NewFriend_GF_Info:SetText(strInfo)
	
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		NewFriend_GF_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		
	--elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
	--	NewFriend_GF_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		NewFriend_GF_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化		
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		NewFriend_GF_Frame_On_ResetPos();
	elseif ( event == "UPDATE_SERVER_TIME_UI" ) then
		if ( this:IsVisible() ) then
			NewFriend_GF_Flush()
		end
	end

end	

--===============================================
-- 					切换界面
--===============================================
--也就是主界面--
function NewFriend_GF_Open()

	CloseWindow("NewFriend_GF", true)
	--加载数据客户端
	AskServerTimeAgain()
	NewFriend_GF_Hide()
	--NewFriend_GF_Flush()
	
	NewFriend_GF_ItemIcon()
	NewFriend_GF_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	--NewFriend_GF_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
	this:Show()

end

--领奖之后更新界面以及缓存数据
function NewFriend_GF_Update(nGUIDH, nGUIDL, nMoney)
	for nIndex = 1,table.getn(g_NewFriend_GF_GongfengGUID) do
		local oldguidh, oldguidl = SplitGUID64(g_NewFriend_GF_GongfengGUID[nIndex])
		if oldguidh == nGUIDH and oldguidl == nGUIDL then
			
			if nMoney == 1 then
				local nGongfeng = g_NewFriend_GF_GongfengData[nIndex]
				WenDingUI:SetShiMenGongfengByGuid(g_NewFriend_GF_GongfengGUID[nIndex], nGongfeng, 2)
				g_NewFriend_GF_GongfengCheck[nIndex]:Hide()
				g_NewFriend_GF_GongfengMoney[nIndex]:Hide()
				g_NewFriend_GF_GongfengCheckText[nIndex]:Hide()
				g_NewFriend_GF_GongfengMoneyText[nIndex]:Show()
				--g_NewFriend_GF_GongfengCheck[i]:SetText("#{STGZ_150514_396}")
				--g_NewFriend_GF_GongfengMoney[i]:SetText("#{STGZ_150514_447}")
			else
				local nGongfeng = g_NewFriend_GF_GongfengData[nIndex]
				WenDingUI:SetShiMenGongfengByGuid(g_NewFriend_GF_GongfengGUID[nIndex], nGongfeng, 1)
				g_NewFriend_GF_GongfengCheck[nIndex]:Hide()
				g_NewFriend_GF_GongfengMoney[nIndex]:Hide()
				g_NewFriend_GF_GongfengMoneyText[nIndex]:Hide()
				g_NewFriend_GF_GongfengCheckText[nIndex]:Show()
				--g_NewFriend_GF_GongfengCheck[i]:SetText("#{STGZ_150514_447}")
				--g_NewFriend_GF_GongfengMoney[i]:SetText("#{STGZ_150514_396}")
			end
			--g_NewFriend_GF_GongfengCheck[nIndex]:Disable()
			--g_NewFriend_GF_GongfengMoney[nIndex]:Disable()
			break
		end
	end
	
	--刷新界面(只置灰按钮)
	--NewFriend_GF_FlushPrizeBtn()

end

--重新刷新界面
function NewFriend_GF_Flush()
	g_NewFriend_GF_GongfengGUID = {}
	g_NewFriend_GF_GongfengData = {}
	--加载数据客户端
	local rtype = 2
	local nIndex = 1
	for i=0,8 do
		local nGUID,
		szCharName,
		nType,
		nSex,
		nLevel,
		szGuildName,
		nQinmi,
		nGongfeng,
		nStartDay,
		nIsOnline = WenDingUI:GetShiMenInfoByIdx( i ,rtype)
			
			
		local nGonfengFlag = math.mod(math.mod(nGongfeng,100000),10)
		if szCharName ~= "" and nType == 2 then
			local ServerDayTime = DataPool:GetServerDayTime()
			local locYear = math.floor(ServerDayTime/10000)
			local locMon = math.mod(ServerDayTime,10000)
			local serYear = math.floor(nGongfeng/100000)
			local serMonth = math.floor(math.mod(nGongfeng,100000)/10)
			--if locYear == serYear and locMon == serMonth then
			if nIndex < 8 then
				g_NewFriend_GF_GongfengGUID[nIndex] = nGUID
				g_NewFriend_GF_GongfengData[nIndex] = nGongfeng
				g_NewFriend_GF_GongfengText[nIndex]:SetText(szCharName)
				nIndex = nIndex + 1
			end
			--end
		end
	end
	
	NewFriend_GF_Show()
end
--更新主界面位置
function NewFriend_GF_Frame_On_ResetPos()
	NewFriend_GF_Frame : SetProperty("UnifiedXPosition", g_NewFriend_GF_Frame_UnifiedXPosition);
	NewFriend_GF_Frame : SetProperty("UnifiedYPosition", g_NewFriend_GF_Frame_UnifiedYPosition);

end

--师父领取单人供奉
function NewFriend_GF_AcceptOne(nIndex,nMoney)
	if nIndex < 1 or nIndex > 8 then
		return
	end
	
	if nIndex > table.getn(g_NewFriend_GF_GongfengGUID) then
		return
	end

	local nGUID = g_NewFriend_GF_GongfengGUID[nIndex]
	local nGUIDH, nGUIDL = SplitGUID64(nGUID)
	
	if nGUIDH == 0 or nGUIDL == 0 then
		return
	end
	
	--检查身上的金钱是否足够
	if nMoney == 1 then
		--local selfMoney = Player : GetData( "MONEY" ) + Player : GetData( "MONEY_JZ" )
		local selfMoney = Player : GetData( "MONEY" )
		if selfMoney < g_NewFriend_GF_Money then
			local strInfo = ScriptGlobal_Format("#{STGZ_150514_386}", tostring(g_NewFriend_GF_Money))
			PushDebugMessage(strInfo)
			return
		end
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MasterAcceptGongfeng")  --脚本接口
		Set_XSCRIPT_ScriptID(891113) --脚本编号 g_CurrentSelect
		Set_XSCRIPT_Parameter(0,nGUIDH);
		Set_XSCRIPT_Parameter(1,nGUIDL);
		Set_XSCRIPT_Parameter(2,nMoney);
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--免费
function NewFriend_GF_Radio(nIndex)
	if nIndex <=0 or nIndex > 8 then
		return
	end
	
	NewFriend_GF_AcceptOne(nIndex,0)
end

--付费
function NewFriend_GF_RadioMoney(nIndex)
	if nIndex <=0 or nIndex > 8 then
		return
	end

	NewFriend_GF_AcceptOne(nIndex,1)
end

function NewFriend_GF_Hide()
	for i=1, 8 do
		g_NewFriend_GF_GongfengText[i]:Hide()
		g_NewFriend_GF_GongfengCheck[i]:Hide()
		g_NewFriend_GF_GongfengCheckText[i]:Hide()
		g_NewFriend_GF_GongfengMoney[i]:Hide()
		g_NewFriend_GF_GongfengMoneyText[i]:Hide()
		g_NewFriend_GF_GongfengText[i]:SetText("")
	end
	--NewFriend_GF_Info5:Hide()
end

--显示控件，默认不显示
function NewFriend_GF_Show()
	local nGonfengFlag = 0
	for i=1, table.getn(g_NewFriend_GF_GongfengGUID) do
		local nGongfeng = g_NewFriend_GF_GongfengData[i]
		g_NewFriend_GF_GongfengText[i]:Show()
		g_NewFriend_GF_GongfengCheck[i]:Show()
		g_NewFriend_GF_GongfengMoney[i]:Show()
		nGonfengFlag = math.mod(math.mod(nGongfeng,100000),10)
		local ServerDayTime = DataPool:GetServerDayTime()
		local locYear = math.floor(ServerDayTime/10000)
		local locMon = math.mod(ServerDayTime,10000)
		local serYear = math.floor(nGongfeng/100000)
		local serMonth = math.floor(math.mod(nGongfeng,100000)/10)
		if locYear == serYear and locMon == serMonth then
			if nGonfengFlag == 1 then
				--g_NewFriend_GF_GongfengCheck[i]:Disable()
				--g_NewFriend_GF_GongfengMoney[i]:Disable()
				--g_NewFriend_GF_GongfengCheck[i]:SetText("#{STGZ_150514_447}")
				--g_NewFriend_GF_GongfengMoney[i]:SetText("#{STGZ_150514_396}")
				g_NewFriend_GF_GongfengCheck[i]:Hide()
				g_NewFriend_GF_GongfengMoney[i]:Hide()
				g_NewFriend_GF_GongfengMoneyText[i]:Hide()
				g_NewFriend_GF_GongfengCheckText[i]:Show()
			elseif nGonfengFlag == 2 then
				--g_NewFriend_GF_GongfengCheck[i]:Disable()
				--g_NewFriend_GF_GongfengMoney[i]:Disable()
				--g_NewFriend_GF_GongfengCheck[i]:SetText("#{STGZ_150514_396}")
				--g_NewFriend_GF_GongfengMoney[i]:SetText("#{STGZ_150514_447}")
				g_NewFriend_GF_GongfengCheck[i]:Hide()
				g_NewFriend_GF_GongfengMoney[i]:Hide()
				g_NewFriend_GF_GongfengMoneyText[i]:Show()
				g_NewFriend_GF_GongfengCheckText[i]:Hide()
			elseif nGonfengFlag == 0 then
				g_NewFriend_GF_GongfengCheck[i]:Enable()
				g_NewFriend_GF_GongfengMoney[i]:Enable()
				g_NewFriend_GF_GongfengCheck[i]:SetText("#{STGZ_150514_396}")
				g_NewFriend_GF_GongfengMoney[i]:SetText("#{STGZ_150514_396}")
			end
		else
			g_NewFriend_GF_GongfengCheck[i]:Disable()
			g_NewFriend_GF_GongfengMoney[i]:Disable()
			g_NewFriend_GF_GongfengCheck[i]:SetText("#{STGZ_150514_448}")
			g_NewFriend_GF_GongfengMoney[i]:SetText("#{STGZ_150514_448}")
		end
	end
	
	--NewFriend_GF_ItemIcon()
	
	--NewFriend_GF_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	
	--NewFriend_GF_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
end

function NewFriend_GF_ItemIcon()

	DataPool:Lua_ClearShituGongfengActionItem()
	
	DataPool:Lua_SetShituGongfengActionItem(0, g_NewFriend_GF_PrizeItemID[1])
	DataPool:Lua_SetShituGongfengActionItem(1, g_NewFriend_GF_PrizeItemID[2])
	DataPool:Lua_UpdateShituGongfengActionItem()
	
	local theAction = EnumAction( 0, "shitugongfeng")
	if theAction:GetID() ~= 0 then
		g_NewFriend_GF_PrizeIcon[1]:SetActionItem( theAction:GetID())
	else
		g_NewFriend_GF_PrizeIcon[1]:SetActionItem( -1 )
	end
	
	theAction = EnumAction( 1, "shitugongfeng")
	if theAction:GetID() ~= 0 then
		g_NewFriend_GF_PrizeIcon[2]:SetActionItem( theAction:GetID())
	else
		g_NewFriend_GF_PrizeIcon[2]:SetActionItem( -1 )
	end
	
end
function NewFriend_GF_Close()
	this:Hide()
end
