
local g_XingXia_Shop_Frame_UnifiedPosition;  

local g_XingXia_Shop_Count = 0
local g_XingXia_Shop_CountMax = 400
local g_XingXia_Shop_DaiBi = 0
local g_XingXia_Shop_LimitNum = 0
local g_XingXia_Shop_RetStr = ""
local g_XingXia_Shop_Times = 0
local g_XingXia_Shop_ShowId = 0
local g_XingXia_Shop_LeiJiMF = {0,0,0,0,0,0}
local g_XingXia_Shop_ShowFenYePoint = 0
local g_XingXia_Shop_ItemIcon = {}
local g_XingXia_Shop_ReturnIcon = {}

local g_XingXia_Shop_ReturnList = {}
local g_XingXia_Shop_LeiJiItem = {}
local g_ItemList = {}
local g_LeiJiList = {}
local g_XingXia_Shop_ItemList = {
[1] = { itemid = 10102892, itemnum = 1},
[2] = { itemid = 38000956, itemnum = 1},
[3] = { itemid = 38000953, itemnum = 1},
[4] = { itemid = 38000992, itemnum = 1},
[5] = { itemid = 38005288, itemnum = 2},
[6] = { itemid = 38004734, itemnum = 5},
[7] = { itemid = 38004804, itemnum = 5},
[8] = { itemid = 38004805, itemnum = 5},
[9] = { itemid = 38000571, itemnum = 2},
[10] = { itemid = 20310168, itemnum = 5},
[11] = { itemid = 20700055, itemnum = 10},
[12] = { itemid = 20700063, itemnum = 20},
}

local g_XingXia_Shop_LeiJiReward = {
[1] = { itemid1 = 20310168, itemnum1 = 2, itemid2 = 0, itemnum2 = 0,tarnum = 50,},
[2] = { itemid1 = 30008130, itemnum1 = 1, itemid2 = 0, itemnum2 = 0,tarnum = 100,},
[3] = { itemid1 = 38005775, itemnum1 = 1, itemid2 = 20501003, itemnum2 = 1,tarnum = 150,},
[4] = { itemid1 = 38004734, itemnum1 = 20, itemid2 = 20502003, itemnum2 = 1,tarnum = 200,},
[5] = { itemid1 = 38000571, itemnum1 = 5, itemid2 = 38000953, itemnum2 = 3,tarnum = 300,},
[6] = { itemid1 = 38005780, itemnum1 = 1, itemid2 = 38000956, itemnum2 = 3,tarnum = 400,},
}

local g_XingXia_Shop_ItemList_KaJi = {
[1] = { itemid = 10102892, itemnum = 1},
[2] = { itemid = 20501003, itemnum = 1},
[3] = { itemid = 20502003, itemnum = 1},
[4] = { itemid = 38000992, itemnum = 1},
[5] = { itemid = 38005288, itemnum = 2},
[6] = { itemid = 20500003, itemnum = 1},
[7] = { itemid = 38000443, itemnum = 1},
[8] = { itemid = 30008034, itemnum = 2},
[9] = { itemid = 38000571, itemnum = 2},
[10] = { itemid = 20310168, itemnum = 5},
[11] = { itemid = 30700241, itemnum = 1},
[12] = { itemid = 38000807, itemnum = 2},
}

local g_XingXia_Shop_LeiJiReward_KaJi = {
[1] = { itemid1 = 20310168, itemnum1 = 2, itemid2 = 0, itemnum2 = 0,tarnum = 50,},
[2] = { itemid1 = 30008130, itemnum1 = 1, itemid2 = 0, itemnum2 = 0,tarnum = 100,},
[3] = { itemid1 = 38005775, itemnum1 = 1, itemid2 = 20501003, itemnum2 = 1,tarnum = 150,},
[4] = { itemid1 = 30008048, itemnum1 = 1, itemid2 = 20502003, itemnum2 = 1,tarnum = 200,},
[5] = { itemid1 = 38000571, itemnum1 = 5, itemid2 = 20501004, itemnum2 = 1,tarnum = 300,},
[6] = { itemid1 = 38005780, itemnum1 = 1, itemid2 = 20502004, itemnum2 = 1,tarnum = 400,},
}

function XingXia_Shop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	    
	-- 进入游戏世界
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	 
end 

function XingXia_Shop_OnLoad()
	g_XingXia_Shop_Frame_UnifiedPosition = XingXia_Shop_Frame:GetProperty("UnifiedPosition"); 	

	g_XingXia_Shop_ItemIcon	= {
		[1] = {XingXia_Shop_Draw_Item1_Frame, XingXia_Shop_Draw_Item1, XingXia_Shop_Draw_Item1_Text},
		[2] = {XingXia_Shop_Draw_Item2_Frame, XingXia_Shop_Draw_Item2, XingXia_Shop_Draw_Item2_Text},
		[3] = {XingXia_Shop_Draw_Item3_Frame, XingXia_Shop_Draw_Item3, XingXia_Shop_Draw_Item3_Text},
		[4] = {XingXia_Shop_Draw_Item4_Frame, XingXia_Shop_Draw_Item4, XingXia_Shop_Draw_Item4_Text},
		[5] = {XingXia_Shop_Draw_Item5_Frame, XingXia_Shop_Draw_Item5, XingXia_Shop_Draw_Item5_Text},
		[6] = {XingXia_Shop_Draw_Item6_Frame, XingXia_Shop_Draw_Item6, XingXia_Shop_Draw_Item6_Text},
		[7] = {XingXia_Shop_Draw_Item7_Frame, XingXia_Shop_Draw_Item7, XingXia_Shop_Draw_Item7_Text},
		[8] = {XingXia_Shop_Draw_Item8_Frame, XingXia_Shop_Draw_Item8, XingXia_Shop_Draw_Item8_Text},
		[9] = {XingXia_Shop_Draw_Item9_Frame, XingXia_Shop_Draw_Item9, XingXia_Shop_Draw_Item9_Text},
		[10] = {XingXia_Shop_Draw_Item10_Frame, XingXia_Shop_Draw_Item10, XingXia_Shop_Draw_Item10_Text},
		[11] = {XingXia_Shop_Draw_Item11_Frame, XingXia_Shop_Draw_Item11, XingXia_Shop_Draw_Item11_Text},
		[12] = {XingXia_Shop_Draw_Item12_Frame, XingXia_Shop_Draw_Item12, XingXia_Shop_Draw_Item12_Text},
	}
	
	g_XingXia_Shop_ReturnIcon = {
		[1] = {XingXia_Shop_Return_Item1_Frame, XingXia_Shop_Return_Item1, 
				XingXia_Shop_Return_Item1_Text, XingXia_Shop_Return_Item1_BuyLimit, XingXia_Shop_Return_Item1_Animate},
		[2] = {XingXia_Shop_Return_Item2_Frame, XingXia_Shop_Return_Item2, 
				XingXia_Shop_Return_Item2_Text, XingXia_Shop_Return_Item2_BuyLimit, XingXia_Shop_Return_Item2_Animate},
		[3] = {XingXia_Shop_Return_Item3_Frame, XingXia_Shop_Return_Item3, 
				XingXia_Shop_Return_Item3_Text, XingXia_Shop_Return_Item3_BuyLimit, XingXia_Shop_Return_Item3_Animate},
		[4] = {XingXia_Shop_Return_Item4_Frame, XingXia_Shop_Return_Item4, 
				XingXia_Shop_Return_Item4_Text, XingXia_Shop_Return_Item4_BuyLimit, XingXia_Shop_Return_Item4_Animate},
		[5] = {XingXia_Shop_Return_Item5_Frame, XingXia_Shop_Return_Item5, 
				XingXia_Shop_Return_Item5_Text, XingXia_Shop_Return_Item5_BuyLimit, XingXia_Shop_Return_Item5_Animate},
		[6] = {XingXia_Shop_Return_Item6_Frame, XingXia_Shop_Return_Item6, 
				XingXia_Shop_Return_Item6_Text, XingXia_Shop_Return_Item6_BuyLimit, XingXia_Shop_Return_Item6_Animate},
		[7] = {XingXia_Shop_Return_Item7_Frame, XingXia_Shop_Return_Item7, 
				XingXia_Shop_Return_Item7_Text, XingXia_Shop_Return_Item7_BuyLimit, XingXia_Shop_Return_Item7_Animate},
		[8] = {XingXia_Shop_Return_Item8_Frame, XingXia_Shop_Return_Item8, 
				XingXia_Shop_Return_Item8_Text, XingXia_Shop_Return_Item8_BuyLimit, XingXia_Shop_Return_Item8_Animate},
		[9] = {XingXia_Shop_Return_Item9_Frame, XingXia_Shop_Return_Item9, 
				XingXia_Shop_Return_Item9_Text, XingXia_Shop_Return_Item9_BuyLimit, XingXia_Shop_Return_Item9_Animate},
		[10] = {XingXia_Shop_Return_Item10_Frame, XingXia_Shop_Return_Item10, 
				XingXia_Shop_Return_Item10_Text, XingXia_Shop_Return_Item10_BuyLimit, XingXia_Shop_Return_Item10_Animate},
	}

	g_XingXia_Shop_LeiJiItem = {
		[1] = {XingXia_Shop_Leiji_Item1, XingXia_Shop_Leiji_Item1_Text, XingXia_Shop_Leiji_Item1_Text2,XingXia_Shop_Leiji_Item1_Button,XingXia_Shop_Leiji_Item1_Text3, 
				XingXia_Shop_Leiji_Item1_Button1, XingXia_Shop_Leiji_Item1_Text4, XingXia_Shop_Leiji_Item1_Icon, XingXia_Shop_Leiji_Item1_Icon_Tips,XingXia_Shop_Leiji_Item1_Image},
		[2] = {XingXia_Shop_Leiji_Item2, XingXia_Shop_Leiji_Item2_Text, XingXia_Shop_Leiji_Item2_Text2,XingXia_Shop_Leiji_Item2_Button,XingXia_Shop_Leiji_Item2_Text3,
				XingXia_Shop_Leiji_Item2_Button1, XingXia_Shop_Leiji_Item2_Text4, XingXia_Shop_Leiji_Item2_Icon, XingXia_Shop_Leiji_Item2_Icon_Tips,XingXia_Shop_Leiji_Item2_Image},
		[3] = {XingXia_Shop_Leiji_Item3, XingXia_Shop_Leiji_Item3_Text, XingXia_Shop_Leiji_Item3_Text2,XingXia_Shop_Leiji_Item3_Button,XingXia_Shop_Leiji_Item3_Text3, 
				XingXia_Shop_Leiji_Item3_Button1, XingXia_Shop_Leiji_Item3_Text4, XingXia_Shop_Leiji_Item3_Icon, XingXia_Shop_Leiji_Item3_Icon_Tips,XingXia_Shop_Leiji_Item3_Image},
		[4] = {XingXia_Shop_Leiji_Item4, XingXia_Shop_Leiji_Item4_Text, XingXia_Shop_Leiji_Item4_Text2,XingXia_Shop_Leiji_Item4_Button,XingXia_Shop_Leiji_Item4_Text3, 
				XingXia_Shop_Leiji_Item4_Button1, XingXia_Shop_Leiji_Item4_Text4, XingXia_Shop_Leiji_Item4_Icon, XingXia_Shop_Leiji_Item4_Icon_Tips,XingXia_Shop_Leiji_Item4_Image},
		[5] = {XingXia_Shop_Leiji_Item5, XingXia_Shop_Leiji_Item5_Text, XingXia_Shop_Leiji_Item5_Text2,XingXia_Shop_Leiji_Item5_Button,XingXia_Shop_Leiji_Item5_Text3, 
				XingXia_Shop_Leiji_Item5_Button1, XingXia_Shop_Leiji_Item5_Text4, XingXia_Shop_Leiji_Item5_Icon, XingXia_Shop_Leiji_Item5_Icon_Tips,XingXia_Shop_Leiji_Item5_Image},
		[6] = {XingXia_Shop_Leiji_Item6, XingXia_Shop_Leiji_Item6_Text, XingXia_Shop_Leiji_Item6_Text2,XingXia_Shop_Leiji_Item6_Button,XingXia_Shop_Leiji_Item6_Text3, 
				XingXia_Shop_Leiji_Item6_Button1, XingXia_Shop_Leiji_Item6_Text4, XingXia_Shop_Leiji_Item6_Icon, XingXia_Shop_Leiji_Item6_Icon_Tips,XingXia_Shop_Leiji_Item6_Image},
	}
end

function XingXia_Shop_Frame_On_ResetPos()
  	XingXia_Shop_Frame:SetProperty("UnifiedPosition", g_XingXia_Shop_Frame_UnifiedPosition);
end

function XingXia_Shop_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" or event == "PLAYER_ENTERING_WORLD" ) then
		XingXia_Shop_Close();
		return
	end
  
    -- 游戏窗口尺寸发生了变化
	if ( event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 更新背包界面位置
		XingXia_Shop_Frame_On_ResetPos()
		return
	end
		 
	-- 打开界面
	if (event == "UI_COMMAND" and tonumber(arg0) == 88896301) then 
		local nFlag = Get_XParam_INT(0)
		g_ItemList = {}
		g_LeiJiList = {}
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(70) > 0 then
			g_ItemList = g_XingXia_Shop_ItemList_KaJi
			g_LeiJiList = g_XingXia_Shop_LeiJiReward_KaJi
		else
			g_ItemList = g_XingXia_Shop_ItemList
			g_LeiJiList = g_XingXia_Shop_LeiJiReward
		end
		if nFlag < 1 then
			XingXia_Shop_Close()  
			return
		end
		
		if nFlag == 3 then
			g_XingXia_Shop_DaiBi = Get_XParam_INT(1)
			
			local str = tostring(g_XingXia_Shop_DaiBi) 
			XingXia_Shop_Client_Currency_Number:SetText( "#G"..str )
		elseif nFlag == 4 then
			for i = 1, table.getn(g_XingXia_Shop_LeiJiMF) do
				g_XingXia_Shop_LeiJiMF[i] = Get_XParam_INT(i)
			end
			XingXia_Shop_ShowLeiJi()
		else		
			g_XingXia_Shop_Count = Get_XParam_INT(1)
			g_XingXia_Shop_DaiBi = Get_XParam_INT(2)
			g_XingXia_Shop_LimitNum = Get_XParam_INT(3) 
			g_XingXia_Shop_Times = Get_XParam_INT(4)
			g_XingXia_Shop_ShowFenYePoint = Get_XParam_INT(5)
			g_XingXia_Shop_RetStr = Get_XParam_STR(0)
			if g_XingXia_Shop_ShowFenYePoint == 1 then
				XingXia_Shop_Left1_Buttontab02_Tips:Show()
			else
				XingXia_Shop_Left1_Buttontab02_Tips:Hide()
			end
			if nFlag == 1 then
				XingXia_Shop_OnShowMain(); 
			elseif nFlag == 2 then
				XingXia_Shop_ShowReturn() 
			end
			this:Show();
		end
		return
	end  
	
end 

function XingXia_Shop_OnInitData() 
	
	-- 代币拥有显示
	local str = tostring(g_XingXia_Shop_DaiBi)
	XingXia_Shop_Client_Currency_Number:SetText( "#G"..str )
	
	-- 上方显示保底奖励提示
	if g_XingXia_Shop_LimitNum > 0 then
		XingXia_Shop_Draw_Title:SetText( "#{XXSD_220209_15}" )
	else
		XingXia_Shop_Draw_Title:SetText( "#{XXSD_220209_14}" )
	end

	-- 抽奖次数上限提示
	if g_XingXia_Shop_Count >= g_XingXia_Shop_CountMax then
		str = "#{XXSD_220209_19}"
	else
		str = ScriptGlobal_Format("#{XXSD_220209_18}", g_XingXia_Shop_Count)
	end
	XingXia_Shop_Draw_Title_Info:SetText( "#L"..str )
	
end 

function XingXia_Shop_OnShowMain()   
	XingXia_Shop_Left_Buttontab01_Tips:Hide()
	XingXia_Shop_Left_Buttontab01:SetCheck(1)
	XingXia_Shop_Left1_Buttontab02:SetCheck(0)

	g_XingXia_Shop_Times = 0
	g_XingXia_Shop_ShowId = 0

	XingXia_Shop_DrawFrame:Show()
	XingXia_Shop_ReturnFrame:Hide()
	XingXia_Shop_OnceReturnFrame:Hide()
	XingXia_Shop_Leiji_Client:Hide()
	XingXia_Shop_Client:Show()
	XingXia_Shop_OnInitData() 
	
	for i = 1, table.getn(g_XingXia_Shop_ItemIcon) do
		g_XingXia_Shop_ItemIcon[i][1]:Hide()
		g_XingXia_Shop_ItemIcon[i][2]:SetActionItem(-1)
	end		
	
	-- 展示奖励
	for i = 1, table.getn(g_ItemList) do
		-- info
		local GiftItemID = g_ItemList[i].itemid
		local GiftCount = g_ItemList[i].itemnum
		-- icon
		local theAction = DataPool:CreateBindActionItemForShow(GiftItemID, GiftCount)
		if theAction:GetID() ~= 0 then
			g_XingXia_Shop_ItemIcon[i][2]:SetActionItem( theAction:GetID() );
		end		
		-- name
		str = DataPool:Lua_GetItemNameByIndex(GiftItemID)
		g_XingXia_Shop_ItemIcon[i][3]:SetText( "#cfff263"..str )
		-- show
		g_XingXia_Shop_ItemIcon[i][1]:Show()
	end
	
	if g_XingXia_Shop_LimitNum > 0 then
		XingXia_Shop_Draw_Item1_Icon_Mask:Show()
		XingXia_Shop_Draw_Item1_ObjectMask:Hide()
	else
		XingXia_Shop_Draw_Item1_Icon_Mask:Hide()
		XingXia_Shop_Draw_Item1_ObjectMask:Hide()
	end
	
end

function XingXia_Shop_ShowReturn() 
	
	if g_XingXia_Shop_Times ~= 1 and g_XingXia_Shop_Times ~= 10 then
		return
	end

	XingXia_Shop_DrawFrame:Hide()

	XingXia_Shop_OnInitData() 
	
	local strItem = g_XingXia_Shop_RetStr.."-"
	for i = 1, g_XingXia_Shop_Times do
		local iPos = string.find( strItem, "-" );
		if ( iPos ~= nil ) then
			local tempstr = string.sub(strItem, 1, iPos-1)	
			g_XingXia_Shop_ReturnList[i] = tonumber(tempstr)
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
		end
	end
	
	if g_XingXia_Shop_Times == 1 then
		XingXia_Shop_OnceReturnFrame:Show()
		XingXia_Shop_ReturnFrame:Hide()
		
		if g_XingXia_Shop_ReturnList[1] ~= nil then
			-- info
			local itemIdx = g_XingXia_Shop_ReturnList[1]
			if g_ItemList[itemIdx] ~= nil then
				local GiftItemID = g_ItemList[itemIdx].itemid
				local GiftCount = g_ItemList[itemIdx].itemnum
				-- icon
				local theAction = DataPool:CreateBindActionItemForShow(GiftItemID, GiftCount)
				if theAction:GetID() ~= 0 then
					XingXia_Shop_OnceReturn_Item1:SetActionItem( theAction:GetID() );
				end		
				-- name
				str = DataPool:Lua_GetItemNameByIndex(GiftItemID)
				XingXia_Shop_OnceReturn_Item1_Text:SetText( "#cfff263"..str )
				
				XingXia_Shop_OnceReturn_Item1_Frame:Hide()
								
				-- limit
				if itemIdx == 1 then
					XingXia_Shop_OnceReturn_Item1_BuyLimit:Show()
					XingXia_Shop_OnceReturn_Item1_Animate:Show()
				else
					XingXia_Shop_OnceReturn_Item1_BuyLimit:Hide()
					XingXia_Shop_OnceReturn_Item1_Animate:Hide()
				end
			end
		end
	
		-- 定时器 开启
		SetTimer("XingXia_Shop","XingXia_Shop_TimerProc()", 100)
		g_XingXia_Shop_ShowId = 1
		
		return
	end
	
	XingXia_Shop_OnceReturnFrame:Hide()
	XingXia_Shop_ReturnFrame:Show()
		
	for i = 1, table.getn(g_XingXia_Shop_ReturnIcon) do
		g_XingXia_Shop_ReturnIcon[i][1]:Hide()
		g_XingXia_Shop_ReturnIcon[i][2]:SetActionItem(-1)
	end		
	
	-- 展示结果
	for i = 1, g_XingXia_Shop_Times do
		if g_XingXia_Shop_ReturnList[i] ~= nil then
			-- info
			local itemIdx = g_XingXia_Shop_ReturnList[i]
			if g_ItemList[itemIdx] ~= nil then
				local GiftItemID = g_ItemList[itemIdx].itemid
				local GiftCount = g_ItemList[itemIdx].itemnum
				-- icon
				local theAction = DataPool:CreateBindActionItemForShow(GiftItemID, GiftCount)
				if theAction:GetID() ~= 0 then
					g_XingXia_Shop_ReturnIcon[i][2]:SetActionItem( theAction:GetID() );
				end		
				-- name
				str = DataPool:Lua_GetItemNameByIndex(GiftItemID)
				g_XingXia_Shop_ReturnIcon[i][3]:SetText( "#cfff263"..str )
				
				-- show
				--g_XingXia_Shop_ReturnIcon[i][1]:Show()
				
				-- limit
				if itemIdx == 1 then
					g_XingXia_Shop_ReturnIcon[i][4]:Show()
					g_XingXia_Shop_ReturnIcon[i][5]:Show()
				else
					g_XingXia_Shop_ReturnIcon[i][4]:Hide()
					g_XingXia_Shop_ReturnIcon[i][5]:Hide()
				end
			end
		end
	end
	
	-- 定时器 开启
	SetTimer("XingXia_Shop","XingXia_Shop_TimerProc()", 500)
	g_XingXia_Shop_ShowId = 1
	
end

function XingXia_Shop_TimerProc()
	KillTimer("XingXia_Shop_TimerProc()");
	
	if g_XingXia_Shop_Times == 1 then
		XingXia_Shop_OnceReturn_Item1_Frame:Show()
	else
		if g_XingXia_Shop_ReturnIcon[g_XingXia_Shop_ShowId] ~= nil then
			g_XingXia_Shop_ReturnIcon[g_XingXia_Shop_ShowId][1]:Show()
			if g_XingXia_Shop_ShowId < g_XingXia_Shop_Times then
				SetTimer("XingXia_Shop","XingXia_Shop_TimerProc()", 200)
			end
			g_XingXia_Shop_ShowId = g_XingXia_Shop_ShowId + 1
		end
	end
end

function XingXia_Shop_Help_Click()

	PushEvent("CCSHOP_HELP", 158)	
	
end

function XingXia_Shop_OK_Clicked( nTimes )

	if nTimes ~= 1 and nTimes ~= 10 then
		return
	end
	
	g_XingXia_Shop_Times = nTimes
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoChouJiang" )
		Set_XSCRIPT_ScriptID( 888963 )
		Set_XSCRIPT_Parameter(0, nTimes)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	

end

function XingXia_Shop_Close() 	

	for i = 1, table.getn(g_XingXia_Shop_ReturnIcon) do
		g_XingXia_Shop_ReturnIcon[i][2]:SetActionItem(-1)
	end		
	
	for i = 1, table.getn(g_XingXia_Shop_ItemIcon) do
		g_XingXia_Shop_ItemIcon[i][2]:SetActionItem(-1)
	end		
		
	if IsWindowShow("XingXia_ShopBuy") then
		CloseWindow("XingXia_ShopBuy", true)
	end
	
	this:Hide(); 
end 

function XingXia_Shop_OpenBuyDaiBi()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenBuyDaiBi" )
		Set_XSCRIPT_ScriptID( 888963 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()		
		
end

function XingXia_Shop_Page(idx)
	if idx == 1 then
		XingXia_Shop_OnShowMain()
	elseif idx == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ShowLeiJi" )
			Set_XSCRIPT_ScriptID( 888963 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	else
		return 
	end
end

function XingXia_Shop_ShowLeiJi()
	XingXia_Shop_Leiji_Client:Show()
	XingXia_Shop_Client:Hide()
	XingXia_Shop_Left_Buttontab01:SetCheck(0)
	XingXia_Shop_Left1_Buttontab02:SetCheck(1)
	XingXia_Shop_Left1_Buttontab02_Tips:Hide()
	for i = 1, table.getn(g_XingXia_Shop_LeiJiItem) do
		g_XingXia_Shop_LeiJiItem[i][1]:Hide()
		g_XingXia_Shop_LeiJiItem[i][2]:SetText("")
		g_XingXia_Shop_LeiJiItem[i][3]:SetText("")
		g_XingXia_Shop_LeiJiItem[i][4]:SetActionItem(-1)
		g_XingXia_Shop_LeiJiItem[i][5]:SetText("")
		g_XingXia_Shop_LeiJiItem[i][5]:Hide()
		g_XingXia_Shop_LeiJiItem[i][6]:SetActionItem(-1)
		g_XingXia_Shop_LeiJiItem[i][6]:Hide()
		g_XingXia_Shop_LeiJiItem[i][7]:SetText("")
		g_XingXia_Shop_LeiJiItem[i][7]:Hide()
		g_XingXia_Shop_LeiJiItem[i][8]:Show()
		g_XingXia_Shop_LeiJiItem[i][9]:Hide()
		g_XingXia_Shop_LeiJiItem[i][10]:Hide()

	end

	for i = 1, table.getn(g_LeiJiList) do
		g_XingXia_Shop_LeiJiItem[i][1]:Show()
		g_XingXia_Shop_LeiJiItem[i][2]:SetText(ScriptGlobal_Format("#{XXSD_220209_73}", g_LeiJiList[i].tarnum))
		if g_XingXia_Shop_Count >= g_LeiJiList[i].tarnum then
			g_XingXia_Shop_LeiJiItem[i][3]:SetText(ScriptGlobal_Format("#{XXSD_220209_75}", g_XingXia_Shop_Count,g_LeiJiList[i].tarnum))
		else
			g_XingXia_Shop_LeiJiItem[i][3]:SetText(ScriptGlobal_Format("#{XXSD_220209_74}", g_XingXia_Shop_Count,g_LeiJiList[i].tarnum))
		end
		

		local theAction = DataPool:CreateBindActionItemForShow(g_LeiJiList[i].itemid1, g_LeiJiList[i].itemnum1)
		if (theAction:GetID() ~= 0) then
			g_XingXia_Shop_LeiJiItem[i][4]:SetActionItem(theAction:GetID())
		end

		if g_LeiJiList[i].itemnum2 > 0 then
			local theAction2 = DataPool:CreateBindActionItemForShow(g_LeiJiList[i].itemid2, g_LeiJiList[i].itemnum2)
			if (theAction2:GetID() ~= 0) then
				g_XingXia_Shop_LeiJiItem[i][6]:Show()
				g_XingXia_Shop_LeiJiItem[i][6]:SetActionItem(theAction2:GetID())
			end
		end

		if g_XingXia_Shop_Count >= g_LeiJiList[i].tarnum and g_XingXia_Shop_LeiJiMF[i] == 0 then--够了没领取
			g_XingXia_Shop_LeiJiItem[i][8]:Show()
			g_XingXia_Shop_LeiJiItem[i][9]:Show()--tips
			g_XingXia_Shop_LeiJiItem[i][10]:Hide()--已领取图片
			XingXia_Shop_Left1_Buttontab02_Tips:Show()
		elseif g_XingXia_Shop_Count < g_LeiJiList[i].tarnum then
			g_XingXia_Shop_LeiJiItem[i][8]:Show()
			g_XingXia_Shop_LeiJiItem[i][9]:Hide()--tips
			g_XingXia_Shop_LeiJiItem[i][10]:Hide()--已领取图片
		end

		if g_XingXia_Shop_LeiJiMF[i] == 1 then
			g_XingXia_Shop_LeiJiItem[i][8]:Hide()
			g_XingXia_Shop_LeiJiItem[i][9]:Hide()--tips
			g_XingXia_Shop_LeiJiItem[i][10]:Show()--已领取图片
		end

	end
end

function XingXia_Shop_LeijiAward_OnClicked(idx)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "LingQuLeiJi" )
		Set_XSCRIPT_ScriptID( 888963 )
		Set_XSCRIPT_Parameter(0, idx)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function XingXia_Shop_Return()  

	XingXia_Shop_OnShowMain()   
	
end

