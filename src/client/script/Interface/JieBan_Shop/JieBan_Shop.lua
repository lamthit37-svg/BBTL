--JieBan_Shop

local g_JieBan_Shop_UnifiedPosition;

local JieBan_Shop_BuyItem_Num = {}
local g_JieBan_Shop_ItemNumMax = 999

local g_JieBan_IsHuiliu = 0
local g_JieBan_pagebuttonleft1 = {}
local g_JieBan_pagebuttonleft2 = {}
local g_JieBan_pagebuttonleft3 = {}

local g_JieBan_Tips1 = {}
local g_JieBan_Tips2 = {}
local g_JieBan_Tips3 = {}
local g_JieBan_button_state = {0,0,0,0}
local g_JieBan_Shop_ActionButton = {}
local g_JieBan_Shop_ScrollBar = {}

local g_JieBan_Shop_ItemList = {}

local g_JieBan_Shop_CurType = 1
local g_JieBan_Shop_Limit_MD = {}
local g_JieBan_Shop_Limit_Count = 0

local g_HLDaibi = 0
local g_HYDaibi = 0
local g_hisHLDaibi = 0
local g_hisHYDaibi = 0

local g_JieBan_lefttime = -1;

local g_JieBan_huiliu_level = -1;

local g_JieBan_Huiliu_LevelImage = {
	[1] = "set:JieBan6 image:jie1", -- 1级
	[2] = "set:JieBan6 image:jie2", -- 2级
	[3] = "set:JieBan6 image:jie3", -- 3级
	[4] = "set:JieBan6 image:jie4", -- 4级
	[5] = "set:JieBan6 image:jie5", -- 5级
	[6] = "set:JieBan6 image:jie6", -- 6级
}


function JieBan_Shop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

end

function JieBan_Shop_OnLoad()

	g_JieBan_pagebuttonleft1[1] = JieBan_Shop_Left1_Buttontab01
	g_JieBan_pagebuttonleft1[2] = JieBan_Shop_Left1_Buttontab02

	g_JieBan_pagebuttonleft2[1] = JieBan_Shop_Left2_Buttontab01
	g_JieBan_pagebuttonleft2[2] = JieBan_Shop_Left2_Buttontab02
	g_JieBan_pagebuttonleft2[3] = JieBan_Shop_Left2_Buttontab03
	g_JieBan_pagebuttonleft2[4] = JieBan_Shop_Left2_Buttontab04
	
	g_JieBan_Tips1[1] = JieBan_Shop_Left1_Buttontab01_Tips
	g_JieBan_Tips1[2] = JieBan_Shop_Left1_Buttontab02_Tips

	g_JieBan_Tips2[1] = JieBan_Shop_Left2_Buttontab01_Tips
	g_JieBan_Tips2[2] = JieBan_Shop_Left2_Buttontab02_Tips
	g_JieBan_Tips2[3] = JieBan_Shop_Left2_Buttontab03_Tips
	g_JieBan_Tips2[4] = JieBan_Shop_Left2_Buttontab04_Tips
	
	g_JieBan_pagebuttonleft3[1] = JieBan_Shop_Left3_Buttontab01
	g_JieBan_pagebuttonleft3[2] = JieBan_Shop_Left3_Buttontab02
	g_JieBan_pagebuttonleft3[3] = JieBan_Shop_Left3_Buttontab04

	g_JieBan_Tips3[1] = JieBan_Shop_Left3_Buttontab01_Tips
	g_JieBan_Tips3[2] = JieBan_Shop_Left3_Buttontab02_Tips
	g_JieBan_Tips3[3] = JieBan_Shop_Left3_Buttontab04_Tips

	
	g_JieBan_Shop_UnifiedPosition = JieBan_Shop:GetProperty("UnifiedPosition")
	
end

function JieBan_Shop_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89319601 ) then
			
			if IsWindowShow("VIP_Shop") then
				CloseWindow("VIP_Shop", true)
			end
			if(IsWindowShow("YuanbaoShop")) then
				CloseWindow("YuanbaoShop", true)
			end
			if(IsWindowShow("ShowShop")) then
				CloseWindow("ShowShop", true)
			end
			if(IsWindowShow("XuanShop")) then
				CloseWindow("XuanShop", true)
			end
			g_HLDaibi = Get_XParam_INT(0)	
			g_HYDaibi = Get_XParam_INT(1)
			g_hisHLDaibi = Get_XParam_INT(2)	
			g_hisHYDaibi = Get_XParam_INT(3)
			--for i = 1, 6 do
			--	g_DuanWu_MD_List[i] = Get_XParam_INT(i)
			--end
			g_JieBan_IsHuiliu = Get_XParam_INT(4)	
			g_JieBan_lefttime = Get_XParam_INT(5)
			g_JieBan_huiliu_level = Get_XParam_INT(6)
			--红点
			g_JieBan_button_state[1] = Get_XParam_INT( 7 )
			g_JieBan_button_state[2] = Get_XParam_INT( 8 )
			g_JieBan_button_state[3] = Get_XParam_INT( 9 )
			g_JieBan_button_state[4] = Get_XParam_INT( 10 )	
			JieBan_Shop_On_SetLastPos()
			
			if g_JieBan_IsHuiliu == 1 or g_JieBan_IsHuiliu == 2 then
				JieBan_Shop_Select(1)
			else
				JieBan_Shop_Select(2)
			end
			--JieBan_Shop_Update()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319603 and this:IsVisible()) then
		g_HLDaibi = Get_XParam_INT(0)	
		g_HYDaibi = Get_XParam_INT(1)

		JieBan_Shop_UpdateDaibi()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319510 and this:IsVisible()) then
		--红点
		g_JieBan_button_state[1] = Get_XParam_INT( 0 )
		g_JieBan_button_state[2] = Get_XParam_INT( 1 )
		g_JieBan_button_state[3] = Get_XParam_INT( 2 )
		g_JieBan_button_state[4] = Get_XParam_INT( 3 )
		--刷新红点
		JieBan_Shop_ShowButtonTips()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89319604 and this:IsVisible()) then
		g_JieBan_Shop_Limit_Count = Get_XParam_INT_Count()
		for i = 1, g_JieBan_Shop_Limit_Count do
			g_JieBan_Shop_Limit_MD[i] = Get_XParam_INT(i-1)
		end	
		JieBan_Shop_UpdateItemLimit()	
	elseif (event == "ADJEST_UI_POS" ) then
		JieBan_Shop_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JieBan_Shop_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--更新界面
--=========================================================
function JieBan_Shop_Update()
	--页签button
	JieBan_Shop_ButtonPage(2)
	--刷新红点
	JieBan_Shop_ShowButtonTips()
	
	for i = 1, table.getn(g_JieBan_Shop_ActionButton) do
		if g_JieBan_Shop_ActionButton[i] ~= nil then
			g_JieBan_Shop_ActionButton[i]:SetActionItem(-1)
			g_JieBan_Shop_ActionButton[i] = nil
		end
	end
	
	for i = 1, table.getn(g_JieBan_Shop_ScrollBar) do
		if g_JieBan_Shop_ScrollBar[i] ~= nil then
			g_JieBan_Shop_ScrollBar[i] = nil
		end
	end
	--DataPool:ClearActionItemForShow()
	
	JieBan_Shop_Lace:Clear()
	
	local nType = g_JieBan_Shop_CurType
	local nCount = GetJiebanShopItemCount(nType)

	g_JieBan_Shop_ItemList = {}
	for i = 1, nCount  do
		table.insert( g_JieBan_Shop_ItemList, {} )
		local nItemShowId, nItemNum, nCredit, nIsNew = GetJiebanShopItem(nType, i)
		g_JieBan_Shop_ItemList[i].nIndex = i
		g_JieBan_Shop_ItemList[i].IsNew = nIsNew
	end
	-- 排序
	table.sort(g_JieBan_Shop_ItemList, function(a, b)
			if a.IsNew == b.IsNew then
				return a.nIndex < b.nIndex
			end
			return a.IsNew > b.IsNew
		end)
		
	for i = 1, nCount do
		--第一列
		local bar1 = JieBan_Shop_Lace:AddChild("JieBan_Shop_CoinAItem1")
		if not bar1 then
    		break
  		end
		local nItemShowId, nItemNum, nCredit, nIsNew = GetJiebanShopItem(nType, g_JieBan_Shop_ItemList[i].nIndex)
		local theAction = DataPool:CreateActionItemForShow(nItemShowId, nItemNum)
		if theAction:GetID() ~= 0 then
			local oActionBtn = bar1:GetSubItem("JieBan_Shop_CoinAItem1_Icon");
			if oActionBtn ~= nil then
				oActionBtn:SetActionItem( theAction:GetID() );
				g_JieBan_Shop_ActionButton[i] = oActionBtn
				oActionBtn:SetEvent( "Clicked", string.format("JieBan_Shop_ActionItem_Clicked(%d)", g_JieBan_Shop_ItemList[i].nIndex))
			end
		end
		bar1:GetSubItem("JieBan_Shop_CoinAItem1_Name"):SetText("#L"..theAction:GetName())
		if nType == 1 then
			bar1:GetSubItem("JieBan_Shop_CoinAItem1_Cost"):SetText(ScriptGlobal_Format("#{JBHL_190803_117}", nCredit))
		else
			bar1:GetSubItem("JieBan_Shop_CoinAItem1_Cost"):SetText(ScriptGlobal_Format("#{JBHL_190803_274}", nCredit))
		end
		
		--删掉限购
		--local curcnt = JieBan_Shop_GetLimitCount(i)
		--local str = ScriptGlobal_Format("#{JBHL_190803_118}", g_JieBan_Shop_ItemList[i].limit-curcnt,g_JieBan_Shop_ItemList[i].limit)
		--if curcnt >= g_JieBan_Shop_ItemList[i].limit then
		--	bar1:GetSubItem("JieBan_Shop_CoinAItem1_IconMark"):Show()
		--	bar1:GetSubItem("JieBan_Shop_CoinAItem1_Num"):SetText("#cFF0000"..str)
		--else
		--	bar1:GetSubItem("JieBan_Shop_CoinAItem1_IconMark"):Hide()
		--	bar1:GetSubItem("JieBan_Shop_CoinAItem1_Num"):SetText("#M"..str)
		--end
		bar1:GetSubItem("JieBan_Shop_CoinAItem1_IconMark"):Hide()
		bar1:GetSubItem("JieBan_Shop_CoinAItem1_Num"):Hide()
		bar1:GetSubItem("JieBan_Shop_CoinAItem1_IconXin"):Hide()
		bar1:GetSubItem("JieBan_Shop_CoinAItem1BK"):Hide()
		if nIsNew > 0 then
			bar1:GetSubItem("JieBan_Shop_CoinAItem1_IconXin"):Show()
			bar1:GetSubItem("JieBan_Shop_CoinAItem1BK"):Show()
		end
		g_JieBan_Shop_ScrollBar[i] = bar1
	end
	
	JieBan_Shop_but:Hide()
	if nType == 1 then 
		if g_JieBan_IsHuiliu == 1 or g_JieBan_IsHuiliu == 2 then --剩余回流时间
			local day = math.floor(g_JieBan_lefttime/(3600*24))
			local hour = math.ceil(math.mod(g_JieBan_lefttime, (3600*24))/3600)
			JieBan_Shop_Coin_Text3:SetText(ScriptGlobal_Format("#{JBHL_190803_389}", day, hour))
			JieBan_Shop_but:Show()
				 -- 图片	
			if g_JieBan_Huiliu_LevelImage[g_JieBan_huiliu_level] ~= nil then
				JieBan_Shop_but:SetProperty("Image", g_JieBan_Huiliu_LevelImage[g_JieBan_huiliu_level])
			end
			JieBan_Shop_but:SetToolTip(ScriptGlobal_Format("#{JBHL_190803_417}",g_JieBan_huiliu_level))
		else
			JieBan_Shop_Coin_Text3:SetText("#{JBHL_190803_422}")
		end
	else
		local curDay = tonumber(DataPool:GetServerDayTime());
		local year,month,day = GetHuoyueDaibiCleanTime(curDay)
		JieBan_Shop_Coin_Text3:SetText(ScriptGlobal_Format("#{JBHL_190803_423}", year,month,day))
	end
	
	JieBan_Shop_UpdateDaibi()
	
	this:Show()
end

--刷新代币数
function JieBan_Shop_UpdateDaibi()
	if g_JieBan_Shop_CurType == 1 then
		JieBan_Shop_Coin_Text:SetText(ScriptGlobal_Format("#{JBHL_190803_113}", g_HLDaibi,g_hisHLDaibi,5500))
		JieBan_Shop_Coin_Text:SetToolTip("#{JBHL_190803_388}")
	else
		local curDay = tonumber(DataPool:GetServerDayTime());
		local year,month,day = GetHuoyueDaibiCleanTime(curDay)
		JieBan_Shop_Coin_Text:SetText(ScriptGlobal_Format("#{JBHL_190803_253}", g_HYDaibi,g_hisHYDaibi,5000))
		JieBan_Shop_Coin_Text:SetToolTip(ScriptGlobal_Format("#{JBHL_190803_390}", year,month,day))
	end
end

--刷新限购
function JieBan_Shop_UpdateItemLimit()
	local nType = g_JieBan_Shop_CurType
	--限购次数
	for i = 1, table.getn(g_JieBan_Shop_ScrollBar) do
		if g_JieBan_Shop_ScrollBar[i] ~= nil then
			local itemindex, maxlimitcount = GetJiebanShopLimit(nType, g_JieBan_Shop_ItemList[i].nIndex)
			local curcnt = JieBan_Shop_GetLimitCount(itemindex)
			local str = ""
			if maxlimitcount < curcnt then
				str = ScriptGlobal_Format("#{JBHL_190803_118}", 0, maxlimitcount)
			else
				str = ScriptGlobal_Format("#{JBHL_190803_118}", maxlimitcount-curcnt, maxlimitcount)
			end
			
			if curcnt >= maxlimitcount then
				g_JieBan_Shop_ScrollBar[i]:GetSubItem("JieBan_Shop_CoinAItem1_IconMark"):Show()
				g_JieBan_Shop_ScrollBar[i]:GetSubItem("JieBan_Shop_CoinAItem1_Num"):Show()
				g_JieBan_Shop_ScrollBar[i]:GetSubItem("JieBan_Shop_CoinAItem1_Num"):SetText("#cFF0000"..str)
			else
				g_JieBan_Shop_ScrollBar[i]:GetSubItem("JieBan_Shop_CoinAItem1_IconMark"):Hide()
				g_JieBan_Shop_ScrollBar[i]:GetSubItem("JieBan_Shop_CoinAItem1_Num"):Show()
				g_JieBan_Shop_ScrollBar[i]:GetSubItem("JieBan_Shop_CoinAItem1_Num"):SetText("#M"..str)
			end
		end
	end
end

--兑换	
function JieBan_Shop_ActionItem_Clicked(index)
	local nCount = GetJiebanShopItemCount(g_JieBan_Shop_CurType)
	if index < 1 or index > nCount then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ExchangeReward" )
		Set_XSCRIPT_ScriptID(893196)
		Set_XSCRIPT_Parameter(0,index)
		Set_XSCRIPT_Parameter(1,1)
		Set_XSCRIPT_Parameter(2,g_JieBan_Shop_CurType) --代币类型
		Set_XSCRIPT_Parameter(3,0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()	

end

--页面切换 1、结伴任务 2、商店 3、回流任务 4、回流特权 
function JieBan_Shop_Project_Clicked(index)
	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenJiebanMission" )
			Set_XSCRIPT_ScriptID( 893195 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif index == 2 then
		return
	elseif index == 3 then
		if g_JieBan_IsHuiliu ~= 1 then
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenHuiliuMission" )
			Set_XSCRIPT_ScriptID( 893229 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif index == 4 then
		if g_JieBan_IsHuiliu == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ShowHuiGuiUIDefaultPage")
				Set_XSCRIPT_ScriptID(808110)
				Set_XSCRIPT_Parameter(0,1)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif g_JieBan_IsHuiliu == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ShowHuiGuiUIDefaultPage")
				Set_XSCRIPT_ScriptID(808112)
				Set_XSCRIPT_Parameter(0,1)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
		
	end
	
	Variable:SetVariable("JieBanUIPos", JieBan_Shop:GetProperty("UnifiedPosition"), 1)
end

--=========================================================
--商店说明
--=========================================================
function JieBan_Shop_Help_Clicked()

end

function JieBan_Shop_Select(nType)
	if nType ~= 1 and nType ~= 2 then
		return
	end
	
	g_JieBan_Shop_CurType = nType
	if nType == 1 then
		JieBan_Shop_Client_ReturnShop:SetCheck(1)
		JieBan_Shop_Client_ActiveShop:SetCheck(0)
	else
		JieBan_Shop_Client_ReturnShop:SetCheck(0)
		JieBan_Shop_Client_ActiveShop:SetCheck(1)
	end
	JieBan_Shop_Update()
	
	JieBan_Shop_UpdateItemLimit()
end
--选中页签
function JieBan_Shop_ButtonPage(index)
	if g_JieBan_IsHuiliu == 1 then
		JieBan_Shop_ButtonLeft1:Hide()
		JieBan_Shop_ButtonLeft2:Show()
		JieBan_Shop_ButtonLeft3:Hide()
		
		for i = 1, 4 do
			if index == i then
				g_JieBan_pagebuttonleft2[i]:SetProperty("Selected", "True")
			else
				g_JieBan_pagebuttonleft2[i]:SetProperty("Selected", "False")
			end
		end
		JieBan_Shop_Left2_Buttontab01:SetToolTip("#{JBHL_190803_11}")
		JieBan_Shop_Left2_Buttontab03:SetToolTip("#{JBHL_190803_12}")
	elseif g_JieBan_IsHuiliu == 2 then
		JieBan_Shop_ButtonLeft1:Hide()
		JieBan_Shop_ButtonLeft2:Hide()
		JieBan_Shop_ButtonLeft3:Show()
		
		for i = 1, 3 do
			if index == i then
				g_JieBan_pagebuttonleft3[i]:SetProperty("Selected", "True")
			else
				g_JieBan_pagebuttonleft3[i]:SetProperty("Selected", "False")
			end
		end
		JieBan_Shop_Left3_Buttontab01:SetToolTip("#{JBHL_190803_11}")	
	else
		JieBan_Shop_ButtonLeft1:Show()
		JieBan_Shop_ButtonLeft2:Hide()
		JieBan_Shop_ButtonLeft3:Hide()
		for i = 1, 2 do
			if index == i then
				g_JieBan_pagebuttonleft1[i]:SetProperty("Selected", "True")
			else
				g_JieBan_pagebuttonleft1[i]:SetProperty("Selected", "False")
			end
		end
	end
end

--刷新红点
function JieBan_Shop_ShowButtonTips()
	if g_JieBan_IsHuiliu == 1 then
		for i = 1, 4 do
			if g_JieBan_button_state[i] == 1 then
				g_JieBan_Tips2[i]:Show()
			else
				g_JieBan_Tips2[i]:Hide()
			end
		end		
	elseif g_JieBan_IsHuiliu == 2 then
		g_JieBan_button_state[3] = g_JieBan_button_state[4]
		for i = 1, 3 do
			if g_JieBan_button_state[i] == 1 then
				g_JieBan_Tips3[i]:Show()
			else
				g_JieBan_Tips3[i]:Hide()
			end
		end					
	else
		for i = 1, 2 do
			if g_JieBan_button_state[i] == 1 then
				g_JieBan_Tips1[i]:Show()
			else
				g_JieBan_Tips1[i]:Hide()
			end
		end		
	end
end
--=========================================================
--关闭
--=========================================================
function JieBan_Shop_Close()
	for i = 1, table.getn(g_JieBan_Shop_ActionButton) do
		if g_JieBan_Shop_ActionButton[i] ~= nil then
			g_JieBan_Shop_ActionButton[i]:SetActionItem(-1)
			g_JieBan_Shop_ActionButton[i] = nil
		end
	end
	DataPool:ClearActionItemForShow()
	JieBan_Shop_Lace:Clear()
	this:Hide()
end

function JieBan_Shop_Help_Clicked()
	PushEvent("CCSHOP_HELP", 114)
end
--=========================================================
--刷新位置
--=========================================================
function JieBan_Shop_On_ResetPos()
	JieBan_Shop:SetProperty("UnifiedPosition", g_JieBan_Shop_UnifiedPosition);
end

--===============================================
-- 设置共享位置信息
--===============================================
function JieBan_Shop_On_SetLastPos()
	local CurUIPos = Variable:GetVariable("JieBanUIPos")
	if( CurUIPos ~= nil) then
	    JieBan_Shop:SetProperty("UnifiedPosition", CurUIPos )
	end
end

--获取物品已兑换数
function JieBan_Shop_GetLimitCount(nIndex)
	if nIndex < 1 then
		return -1
	end 	
	
	local MDData = nil
	for i = 1, table.getn(g_JieBan_Shop_Limit_MD) do
		if nIndex > 3*(i-1) and nIndex <= 3*i then
			MDData = g_JieBan_Shop_Limit_MD[i]
			break
		end
	end

	local ret = -1
	if MDData ~= nil then
		local temp = math.mod(nIndex-1, 3) --0,1,2
		if temp == 0 then
			ret = math.mod(MDData, 1000)
		elseif temp == 1 then
			ret = math.mod(math.floor(MDData/1000), 1000)
		elseif temp == 2 then
			ret = math.mod(math.floor(MDData/1000000),1000)
		end
	end
	
	return ret
end
