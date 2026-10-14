
local g_Anniversary_Blessing_Frame_UnifiedPosition;  

local g_Anniversary_Blessing_Count = 0
local g_Anniversary_Blessing_CountMax = 400
local g_Anniversary_Blessing_QiFuBi = 0
local g_Anniversary_Blessing_QiFuBiHigh = 0
local g_Anniversary_Blessing_SYCount = 0
local g_Anniversary_Blessing_LimitNum = 0
local g_Anniversary_Blessing_RetStr = ""
local g_Anniversary_Blessing_Times = 0
local g_Anniversary_Blessing_ShowId = 0

local g_Anniversary_Blessing_ItemIcon = {}
local g_Anniversary_Blessing_ReturnIcon = {}

local g_Anniversary_Blessing_ReturnList = {}

local g_Anniversary_Blessing_ItemList = {
[1] = { itemid = 39922619, itemnum = 1},
[2] = { itemid = 39922183, itemnum = 1},
[3] = { itemid = 39922156, itemnum = 1},
[4] = { itemid = 39922157, itemnum = 1},
[5] = { itemid = 39922174, itemnum = 1},
[6] = { itemid = 39922686, itemnum = 5},
[7] = { itemid = 39922684, itemnum = 5},
[8] = { itemid = 39922685, itemnum = 5},
[9] = { itemid = 39920181, itemnum = 1},
[10] = { itemid = 39921545, itemnum = 1},
[11] = { itemid = 39920162, itemnum = 5},
[12] = { itemid = 39920163, itemnum = 10},
}

function Anniversary_Blessing_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	    
	-- 进入游戏世界
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	 
end 

function Anniversary_Blessing_OnLoad()
	g_Anniversary_Blessing_Frame_UnifiedPosition = Anniversary_Blessing_Frame:GetProperty("UnifiedPosition"); 	

	g_Anniversary_Blessing_ItemIcon	= {
		[1] = {Anniversary_Blessing_Draw_Item1_Frame, Anniversary_Blessing_Draw_Item1, Anniversary_Blessing_Draw_Item1_Text},
		[2] = {Anniversary_Blessing_Draw_Item2_Frame, Anniversary_Blessing_Draw_Item2, Anniversary_Blessing_Draw_Item2_Text},
		[3] = {Anniversary_Blessing_Draw_Item3_Frame, Anniversary_Blessing_Draw_Item3, Anniversary_Blessing_Draw_Item3_Text},
		[4] = {Anniversary_Blessing_Draw_Item4_Frame, Anniversary_Blessing_Draw_Item4, Anniversary_Blessing_Draw_Item4_Text},
		[5] = {Anniversary_Blessing_Draw_Item5_Frame, Anniversary_Blessing_Draw_Item5, Anniversary_Blessing_Draw_Item5_Text},
		[6] = {Anniversary_Blessing_Draw_Item6_Frame, Anniversary_Blessing_Draw_Item6, Anniversary_Blessing_Draw_Item6_Text},
		[7] = {Anniversary_Blessing_Draw_Item7_Frame, Anniversary_Blessing_Draw_Item7, Anniversary_Blessing_Draw_Item7_Text},
		[8] = {Anniversary_Blessing_Draw_Item8_Frame, Anniversary_Blessing_Draw_Item8, Anniversary_Blessing_Draw_Item8_Text},
		[9] = {Anniversary_Blessing_Draw_Item9_Frame, Anniversary_Blessing_Draw_Item9, Anniversary_Blessing_Draw_Item9_Text},
		[10] = {Anniversary_Blessing_Draw_Item10_Frame, Anniversary_Blessing_Draw_Item10, Anniversary_Blessing_Draw_Item10_Text},
		[11] = {Anniversary_Blessing_Draw_Item11_Frame, Anniversary_Blessing_Draw_Item11, Anniversary_Blessing_Draw_Item11_Text},
		[12] = {Anniversary_Blessing_Draw_Item12_Frame, Anniversary_Blessing_Draw_Item12, Anniversary_Blessing_Draw_Item12_Text},
	}
	
	g_Anniversary_Blessing_ReturnIcon = {
		[1] = {Anniversary_Blessing_Return_Item1_Frame, Anniversary_Blessing_Return_Item1, 
				Anniversary_Blessing_Return_Item1_Text, Anniversary_Blessing_Return_Item1_BuyLimit, Anniversary_Blessing_Return_Item1_Animate},
		[2] = {Anniversary_Blessing_Return_Item2_Frame, Anniversary_Blessing_Return_Item2, 
				Anniversary_Blessing_Return_Item2_Text, Anniversary_Blessing_Return_Item2_BuyLimit, Anniversary_Blessing_Return_Item2_Animate},
		[3] = {Anniversary_Blessing_Return_Item3_Frame, Anniversary_Blessing_Return_Item3, 
				Anniversary_Blessing_Return_Item3_Text, Anniversary_Blessing_Return_Item3_BuyLimit, Anniversary_Blessing_Return_Item3_Animate},
		[4] = {Anniversary_Blessing_Return_Item4_Frame, Anniversary_Blessing_Return_Item4, 
				Anniversary_Blessing_Return_Item4_Text, Anniversary_Blessing_Return_Item4_BuyLimit, Anniversary_Blessing_Return_Item4_Animate},
		[5] = {Anniversary_Blessing_Return_Item5_Frame, Anniversary_Blessing_Return_Item5, 
				Anniversary_Blessing_Return_Item5_Text, Anniversary_Blessing_Return_Item5_BuyLimit, Anniversary_Blessing_Return_Item5_Animate},
		[6] = {Anniversary_Blessing_Return_Item6_Frame, Anniversary_Blessing_Return_Item6, 
				Anniversary_Blessing_Return_Item6_Text, Anniversary_Blessing_Return_Item6_BuyLimit, Anniversary_Blessing_Return_Item6_Animate},
		[7] = {Anniversary_Blessing_Return_Item7_Frame, Anniversary_Blessing_Return_Item7, 
				Anniversary_Blessing_Return_Item7_Text, Anniversary_Blessing_Return_Item7_BuyLimit, Anniversary_Blessing_Return_Item7_Animate},
		[8] = {Anniversary_Blessing_Return_Item8_Frame, Anniversary_Blessing_Return_Item8, 
				Anniversary_Blessing_Return_Item8_Text, Anniversary_Blessing_Return_Item8_BuyLimit, Anniversary_Blessing_Return_Item8_Animate},
		[9] = {Anniversary_Blessing_Return_Item9_Frame, Anniversary_Blessing_Return_Item9, 
				Anniversary_Blessing_Return_Item9_Text, Anniversary_Blessing_Return_Item9_BuyLimit, Anniversary_Blessing_Return_Item9_Animate},
		[10] = {Anniversary_Blessing_Return_Item10_Frame, Anniversary_Blessing_Return_Item10, 
				Anniversary_Blessing_Return_Item10_Text, Anniversary_Blessing_Return_Item10_BuyLimit, Anniversary_Blessing_Return_Item10_Animate},
	}
	
end

function Anniversary_Blessing_Frame_On_ResetPos()
  	Anniversary_Blessing_Frame:SetProperty("UnifiedPosition", g_Anniversary_Blessing_Frame_UnifiedPosition);
end

function Anniversary_Blessing_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" or event == "PLAYER_ENTERING_WORLD" ) then
		Anniversary_Blessing_Close();
		return
	end
  
    -- 游戏窗口尺寸发生了变化
	if ( event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 更新背包界面位置
		Anniversary_Blessing_Frame_On_ResetPos()
		return
	end
		 
	-- 打开界面
	if (event == "UI_COMMAND" and tonumber(arg0) == 89340302) then 
		local nFlag = Get_XParam_INT(0)
		if nFlag < 1 then
			Anniversary_Blessing_Close()  
			return
		end
		
		if nFlag == 3 then
			g_Anniversary_Blessing_QiFuBi = Get_XParam_INT(1)
			g_Anniversary_Blessing_QiFuBiHigh = Get_XParam_INT(2)
			
			local str = tostring(g_Anniversary_Blessing_QiFuBi) --ScriptGlobal_Format("#{FBQF_200327_19}", g_Anniversary_Blessing_QiFuBi)
			Anniversary_Blessing_Client_Currency_Number:SetText( "#L"..str )
			
			--str = ScriptGlobal_Format("#{FBQF_200327_13}", g_Anniversary_Blessing_QiFuBiHigh)
			Anniversary_Blessing_Up_Client_PageIntro:SetText( "#{FBQF_200327_13}" ) --"#L"..str )
		else		
			g_Anniversary_Blessing_Count = Get_XParam_INT(1)
			g_Anniversary_Blessing_QiFuBi = Get_XParam_INT(2)
			g_Anniversary_Blessing_SYCount = Get_XParam_INT(3)
			g_Anniversary_Blessing_LimitNum = Get_XParam_INT(4) 
			g_Anniversary_Blessing_Times = Get_XParam_INT(5)
			g_Anniversary_Blessing_QiFuBiHigh = Get_XParam_INT(6) 
			g_Anniversary_Blessing_RetStr = Get_XParam_STR(0)
			
			--local str = ScriptGlobal_Format("#{FBQF_200327_13}", g_Anniversary_Blessing_QiFuBiHigh)
			Anniversary_Blessing_Up_Client_PageIntro:SetText( "#{FBQF_200327_13}" ) --"#L"..str )
			
			if nFlag == 2 then
				Anniversary_Blessing_ShowReturn() 
			else
				Anniversary_Blessing_OnShowMain(); 
			end
			this:Show();
		end
		return
	end  
	
end 

function Anniversary_Blessing_OnInitData() 
	
	-- 代币拥有显示
	local str = tostring(g_Anniversary_Blessing_QiFuBi) --ScriptGlobal_Format("#{FBQF_200327_19}", g_Anniversary_Blessing_QiFuBi)
	Anniversary_Blessing_Client_Currency_Number:SetText( "#L"..str )
	
	-- 上方显示保底奖励提示
	Anniversary_Blessing_Draw_Title:SetText( "#{FBQF_200327_14}" )
	
	-- 抽奖次数上限提示
	if g_Anniversary_Blessing_Count >= g_Anniversary_Blessing_CountMax then
		str = ScriptGlobal_Format("#{FBQF_200327_18}", g_Anniversary_Blessing_CountMax)
	else
		str = ScriptGlobal_Format("#{FBQF_200327_17}", g_Anniversary_Blessing_Count)
	end
	Anniversary_Blessing_Draw_Title_Info:SetText( "#L"..str )
	
end 

function Anniversary_Blessing_OnShowMain()   

	g_Anniversary_Blessing_Times = 0
	g_Anniversary_Blessing_ShowId = 0

	Anniversary_Blessing_DrawFrame:Show()
	Anniversary_Blessing_ReturnFrame:Hide()
	Anniversary_Blessing_OnceReturnFrame:Hide()
	
	Anniversary_Blessing_OnInitData() 
	
	for i = 1, table.getn(g_Anniversary_Blessing_ItemIcon) do
		g_Anniversary_Blessing_ItemIcon[i][1]:Hide()
		g_Anniversary_Blessing_ItemIcon[i][2]:SetActionItem(-1)
	end		
	
	-- 展示奖励
	for i = 1, table.getn(g_Anniversary_Blessing_ItemList) do
		-- info
		local GiftItemID = g_Anniversary_Blessing_ItemList[i].itemid
		local GiftCount = g_Anniversary_Blessing_ItemList[i].itemnum
		-- icon
		local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftCount)
		if theAction:GetID() ~= 0 then
			g_Anniversary_Blessing_ItemIcon[i][2]:SetActionItem( theAction:GetID() );
		end		
		-- name
		str = DataPool:Lua_GetItemNameByIndex(GiftItemID)
		g_Anniversary_Blessing_ItemIcon[i][3]:SetText( "#L"..str )
		-- show
		g_Anniversary_Blessing_ItemIcon[i][1]:Show()
	end
	
	if g_Anniversary_Blessing_LimitNum >= 0 then
		Anniversary_Blessing_Draw_Item1_FrameBK2:Show()
		Anniversary_Blessing_Draw_Item1_Icon_Mask:Show()
		
		Anniversary_Blessing_Draw_Item1_FrameBK1:Hide()
		Anniversary_Blessing_Draw_Item1_ObjectMask:Hide()
	else
		Anniversary_Blessing_Draw_Item1_FrameBK1:Show()
		Anniversary_Blessing_Draw_Item1_ObjectMask:Show()
		
		Anniversary_Blessing_Draw_Item1_FrameBK2:Hide()
		Anniversary_Blessing_Draw_Item1_Icon_Mask:Hide()
	end
	
end

function Anniversary_Blessing_ShowReturn() 
	
	if g_Anniversary_Blessing_Times ~= 1 and g_Anniversary_Blessing_Times ~= 10 then
		return
	end

	Anniversary_Blessing_DrawFrame:Hide()

	Anniversary_Blessing_OnInitData() 
	
	local strItem = g_Anniversary_Blessing_RetStr.."-"
	for i = 1, g_Anniversary_Blessing_Times do
		local iPos = string.find( strItem, "-" );
		if ( iPos ~= nil ) then
			local tempstr = string.sub(strItem, 1, iPos-1)	
			g_Anniversary_Blessing_ReturnList[i] = tonumber(tempstr)
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
		end
	end
	
	if g_Anniversary_Blessing_Times == 1 then
		Anniversary_Blessing_OnceReturnFrame:Show()
		Anniversary_Blessing_ReturnFrame:Hide()
		
		if g_Anniversary_Blessing_ReturnList[1] ~= nil then
			-- info
			local itemIdx = g_Anniversary_Blessing_ReturnList[1]
			if g_Anniversary_Blessing_ItemList[itemIdx] ~= nil then
				local GiftItemID = g_Anniversary_Blessing_ItemList[itemIdx].itemid
				local GiftCount = g_Anniversary_Blessing_ItemList[itemIdx].itemnum
				-- icon
				local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftCount)
				if theAction:GetID() ~= 0 then
					Anniversary_Blessing_OnceReturn_Item1:SetActionItem( theAction:GetID() );
				end		
				-- name
				str = DataPool:Lua_GetItemNameByIndex(GiftItemID)
				Anniversary_Blessing_OnceReturn_Item1_Text:SetText( "#L"..str )
				
				Anniversary_Blessing_OnceReturn_Item1_Frame:Hide()
								
				-- limit
				if itemIdx == 1 then
					Anniversary_Blessing_OnceReturn_Item1_BuyLimit:Show()
					Anniversary_Blessing_OnceReturn_Item1_Animate:Show()
				else
					Anniversary_Blessing_OnceReturn_Item1_BuyLimit:Hide()
					Anniversary_Blessing_OnceReturn_Item1_Animate:Hide()
				end
			end
		end
	
		-- 定时器 开启
		SetTimer("Anniversary_Blessing","Anniversary_Blessing_TimerProc()", 100)
		g_Anniversary_Blessing_ShowId = 1
		
		return
	end
	
	Anniversary_Blessing_OnceReturnFrame:Hide()
	Anniversary_Blessing_ReturnFrame:Show()
		
	for i = 1, table.getn(g_Anniversary_Blessing_ReturnIcon) do
		g_Anniversary_Blessing_ReturnIcon[i][1]:Hide()
		g_Anniversary_Blessing_ReturnIcon[i][2]:SetActionItem(-1)
	end		
	
	-- 展示结果
	for i = 1, g_Anniversary_Blessing_Times do
		if g_Anniversary_Blessing_ReturnList[i] ~= nil then
			-- info
			local itemIdx = g_Anniversary_Blessing_ReturnList[i]
			if g_Anniversary_Blessing_ItemList[itemIdx] ~= nil then
				local GiftItemID = g_Anniversary_Blessing_ItemList[itemIdx].itemid
				local GiftCount = g_Anniversary_Blessing_ItemList[itemIdx].itemnum
				-- icon
				local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftCount)
				if theAction:GetID() ~= 0 then
					g_Anniversary_Blessing_ReturnIcon[i][2]:SetActionItem( theAction:GetID() );
				end		
				-- name
				str = DataPool:Lua_GetItemNameByIndex(GiftItemID)
				g_Anniversary_Blessing_ReturnIcon[i][3]:SetText( "#L"..str )
				
				-- show
				--g_Anniversary_Blessing_ReturnIcon[i][1]:Show()
				
				-- limit
				if itemIdx == 1 then
					g_Anniversary_Blessing_ReturnIcon[i][4]:Show()
					g_Anniversary_Blessing_ReturnIcon[i][5]:Show()
				else
					g_Anniversary_Blessing_ReturnIcon[i][4]:Hide()
					g_Anniversary_Blessing_ReturnIcon[i][5]:Hide()
				end
			end
		end
	end
	
	-- 定时器 开启
	SetTimer("Anniversary_Blessing","Anniversary_Blessing_TimerProc()", 500)
	g_Anniversary_Blessing_ShowId = 1
	
end

function Anniversary_Blessing_TimerProc()
	KillTimer("Anniversary_Blessing_TimerProc()");
	
	if g_Anniversary_Blessing_Times == 1 then
		Anniversary_Blessing_OnceReturn_Item1_Frame:Show()
	else
		if g_Anniversary_Blessing_ReturnIcon[g_Anniversary_Blessing_ShowId] ~= nil then
			g_Anniversary_Blessing_ReturnIcon[g_Anniversary_Blessing_ShowId][1]:Show()
			if g_Anniversary_Blessing_ShowId < g_Anniversary_Blessing_Times then
				SetTimer("Anniversary_Blessing","Anniversary_Blessing_TimerProc()", 200)
			end
			g_Anniversary_Blessing_ShowId = g_Anniversary_Blessing_ShowId + 1
		end
	end
end

function Anniversary_Blessing_Help_Click()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AnniPreShowHelp" )
		Set_XSCRIPT_ScriptID( 893401 )
		Set_XSCRIPT_Parameter(0, 2)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
	
end

function Anniversary_Blessing_OK_Clicked( nTimes )

	if nTimes ~= 1 and nTimes ~= 10 then
		return
	end
	
	g_Anniversary_Blessing_Times = nTimes
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoQiFu" )
		Set_XSCRIPT_ScriptID( 893403 )
		Set_XSCRIPT_Parameter(0, nTimes)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	

end

function Anniversary_Blessing_Return()  

	Anniversary_Blessing_OnShowMain()   
	
end

function Anniversary_Blessing_Close() 	

	for i = 1, table.getn(g_Anniversary_Blessing_ReturnIcon) do
		g_Anniversary_Blessing_ReturnIcon[i][2]:SetActionItem(-1)
	end		
	
	for i = 1, table.getn(g_Anniversary_Blessing_ItemIcon) do
		g_Anniversary_Blessing_ItemIcon[i][2]:SetActionItem(-1)
	end		
		
	if IsWindowShow("Anniversary_BlessingBuy") then
		CloseWindow("Anniversary_BlessingBuy", true)
	end
	
	this:Hide(); 
end 

function Anniversary_Blessing_BuyBlessingCoin()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoBuyQiFuBi" )
		Set_XSCRIPT_ScriptID( 893403 )
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()		
		
end

