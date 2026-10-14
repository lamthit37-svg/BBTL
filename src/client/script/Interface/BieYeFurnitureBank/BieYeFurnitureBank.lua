local g_BieYeFurnitureBank_Frame_UnifiedPosition;

--功能按钮
local COMMAND_BUTTONS_NUM = 4;
local COMMAND_BUTTONS = {}

--页签及其编号
local PACK_BUTTONS_NUM = 13;
local PACK_BUTTONS = {};

--格子及其编号
local GRID_BUTTONS_NUM = 16;
local GRID_LINE_NUM = 8;
local GRID_BUTTONS = {};
local ActionButton = {};
local GRID_BUTTONS_ICON = {};
local PACK_BUTTONS_tips = {}
local   g_DescriptionOuter= {
						[1] = "庭院桌",
						[2] = "庭院凳",
						[3] = "喷泉",
						[4] = "影壁",
						[5] = "风灯",
						[6] = "鼎",
						[7] = "奇石",
						[8] = "树木",
						[9] = "植栽",
						[10] = "玩物",
						[11] = "栏杆",				
						[12] = "花草",		
						[13] = "奇珍",											
																}
local  g_DescriptionInner= {
						[1] = "床帐",
						[2] = "居室桌",
						[3] = "条案",
						[4] = "茶几",
						[5] = "椅",
						[6] = "居室凳",
						[7] = "柜架",
						[8] = "屏风",
						[9] = "灯烛",
						[10] = "装饰",
						[11] = "隔断",
						[12] = "地毯",
						[13] = "瑰宝",
																	
																}

local g_CurrentPage = 1;
--当前家具类型最大的页数
local g_CurrentMaxFurniturePage = 0;
local g_CurrentRentBoxMax = 50
--大类别下小类型的最大值
local g_MaxTypeValue = 500
local g_CurrentRentBox = 1

--===============================================
-- OnLoad()
--===============================================
function BieYeFurnitureBank_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BIEYE_OPEN_FURNITURE_BANK")
	this:RegisterEvent("BIEYE_UPDATE_FURNITURE_BANK")
	this:RegisterEvent("BIEYE_OPEN_MINI")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	
	this:RegisterEvent("FURNITURE_ADD_UPDATE")	--离开场景关闭界面
	this:RegisterEvent("BIEYEFURNITUREBANK_LOG")	--离开场景关闭界面
	this:RegisterEvent("BIEYEFURNITUREBANKHIDE")	--离开场景关闭界面
	
end
	
function BieYeFurnitureBank_OnLoad()


	
	COMMAND_BUTTONS[1] = BieYeFurnitureBank_Delete; --摧毁
	COMMAND_BUTTONS[2] = BieYeFurnitureBank_Buy; --仓库补货
	COMMAND_BUTTONS[3] = BieYeFurnitureBank_Show;--预览
	COMMAND_BUTTONS[4] = BieYeFurnitureBank_Put;--摆放
	
	ActionButton[1] = BieYeFurnitureBank_Item_LineOneA;
	ActionButton[2] = BieYeFurnitureBank_Item_LineOneB;
	ActionButton[3] = BieYeFurnitureBank_Item_LineOneC;
	ActionButton[4] = BieYeFurnitureBank_Item_LineOneD;
	ActionButton[5] = BieYeFurnitureBank_Item_LineOneE;
	ActionButton[6] = BieYeFurnitureBank_Item_LineOneF;
	ActionButton[7] = BieYeFurnitureBank_Item_LineOneG;
	ActionButton[8] = BieYeFurnitureBank_Item_LineOneH;
	
	ActionButton[9] = BieYeFurnitureBank_Item_LineTwoA;
	ActionButton[10] = BieYeFurnitureBank_Item_LineTwoB;
	ActionButton[11] = BieYeFurnitureBank_Item_LineTwoC;
	ActionButton[12] = BieYeFurnitureBank_Item_LineTwoD;
	ActionButton[13] = BieYeFurnitureBank_Item_LineTwoE;
	ActionButton[14] = BieYeFurnitureBank_Item_LineTwoF;
	ActionButton[15] = BieYeFurnitureBank_Item_LineTwoG;
	ActionButton[16] = BieYeFurnitureBank_Item_LineTwoH;
	

	GRID_BUTTONS[1]  = BieYeFurnitureBank_Item_LineOneA_Mask;
	GRID_BUTTONS[2]  = BieYeFurnitureBank_Item_LineOneB_Mask;
	GRID_BUTTONS[3]  = BieYeFurnitureBank_Item_LineOneC_Mask;
	GRID_BUTTONS[4]  = BieYeFurnitureBank_Item_LineOneD_Mask;
	GRID_BUTTONS[5]  = BieYeFurnitureBank_Item_LineOneE_Mask;
	GRID_BUTTONS[6]  = BieYeFurnitureBank_Item_LineOneF_Mask;
	GRID_BUTTONS[7]  = BieYeFurnitureBank_Item_LineOneG_Mask;
	GRID_BUTTONS[8]  = BieYeFurnitureBank_Item_LineOneH_Mask;
	
	GRID_BUTTONS[9]	 = BieYeFurnitureBank_Item_LineTwoA_Mask;
	GRID_BUTTONS[10] = BieYeFurnitureBank_Item_LineTwoB_Mask;
	GRID_BUTTONS[11] = BieYeFurnitureBank_Item_LineTwoC_Mask;
	GRID_BUTTONS[12] = BieYeFurnitureBank_Item_LineTwoD_Mask;
	GRID_BUTTONS[13] = BieYeFurnitureBank_Item_LineTwoE_Mask;
	GRID_BUTTONS[14] = BieYeFurnitureBank_Item_LineTwoF_Mask;
	GRID_BUTTONS[15] = BieYeFurnitureBank_Item_LineTwoG_Mask;
	GRID_BUTTONS[16] = BieYeFurnitureBank_Item_LineTwoH_Mask;
	
	
	
	GRID_BUTTONS_ICON[1] = BieYeFurnitureBank_Item_LineOneA_Icon;
	GRID_BUTTONS_ICON[2] = BieYeFurnitureBank_Item_LineOneB_Icon;
	GRID_BUTTONS_ICON[3] = BieYeFurnitureBank_Item_LineOneC_Icon;
	GRID_BUTTONS_ICON[4] = BieYeFurnitureBank_Item_LineOneD_Icon;
	GRID_BUTTONS_ICON[5] = BieYeFurnitureBank_Item_LineOneE_Icon;
	GRID_BUTTONS_ICON[6] = BieYeFurnitureBank_Item_LineOneF_Icon;
	GRID_BUTTONS_ICON[7] = BieYeFurnitureBank_Item_LineOneG_Icon;
	GRID_BUTTONS_ICON[8] = BieYeFurnitureBank_Item_LineOneH_Icon;
	
	GRID_BUTTONS_ICON[9] = BieYeFurnitureBank_Item_LineTwoA_Icon;
	GRID_BUTTONS_ICON[10] = BieYeFurnitureBank_Item_LineTwoB_Icon;
	GRID_BUTTONS_ICON[11] = BieYeFurnitureBank_Item_LineTwoC_Icon;
	GRID_BUTTONS_ICON[12] = BieYeFurnitureBank_Item_LineTwoD_Icon;
	GRID_BUTTONS_ICON[13] = BieYeFurnitureBank_Item_LineTwoE_Icon;
	GRID_BUTTONS_ICON[14] = BieYeFurnitureBank_Item_LineTwoF_Icon;
	GRID_BUTTONS_ICON[15] = BieYeFurnitureBank_Item_LineTwoG_Icon;
	GRID_BUTTONS_ICON[16] = BieYeFurnitureBank_Item_LineTwoH_Icon;

										
	PACK_BUTTONS[1]  = BieYeFurnitureBank_YeQianA;
	PACK_BUTTONS[2]  = BieYeFurnitureBank_YeQianB;
	PACK_BUTTONS[3]  = BieYeFurnitureBank_YeQianC;
	PACK_BUTTONS[4]  = BieYeFurnitureBank_YeQianD;
	PACK_BUTTONS[5]  = BieYeFurnitureBank_YeQianE;
	PACK_BUTTONS[6]  = BieYeFurnitureBank_YeQianF;
	PACK_BUTTONS[7]  = BieYeFurnitureBank_YeQianG;
	PACK_BUTTONS[8]  = BieYeFurnitureBank_YeQianH;
	PACK_BUTTONS[9]  = BieYeFurnitureBank_YeQianI;
	PACK_BUTTONS[10]  = BieYeFurnitureBank_YeQianJ;
	PACK_BUTTONS[11]  = BieYeFurnitureBank_YeQianK;
	PACK_BUTTONS[12]  = BieYeFurnitureBank_YeQianL;
	PACK_BUTTONS[13]  = BieYeFurnitureBank_YeQianM;
	
	PACK_BUTTONS_tips[1]  = BieYeFurnitureBank_YeQianAtips;
	PACK_BUTTONS_tips[2]  = BieYeFurnitureBank_YeQianBtips;
	PACK_BUTTONS_tips[3]  = BieYeFurnitureBank_YeQianCtips;
	PACK_BUTTONS_tips[4]  = BieYeFurnitureBank_YeQianDtips;
	PACK_BUTTONS_tips[5]  = BieYeFurnitureBank_YeQianEtips;
	PACK_BUTTONS_tips[6]  = BieYeFurnitureBank_YeQianFtips;
	PACK_BUTTONS_tips[7]  = BieYeFurnitureBank_YeQianGtips;
	PACK_BUTTONS_tips[8]  = BieYeFurnitureBank_YeQianHtips;
	PACK_BUTTONS_tips[9]  = BieYeFurnitureBank_YeQianItips;
	PACK_BUTTONS_tips[10]  = BieYeFurnitureBank_YeQianJtips;
	PACK_BUTTONS_tips[11]  = BieYeFurnitureBank_YeQianKtips;
	PACK_BUTTONS_tips[12]  = BieYeFurnitureBank_YeQianLtips;
	PACK_BUTTONS_tips[13]  = BieYeFurnitureBank_YeQianMtips;
	
  g_BieYeFurnitureBank_Frame_UnifiedPosition=BieYeFurnitureBank_Frame:GetProperty("UnifiedPosition");

end										


--===============================================
-- OnEvent
--===============================================
function BieYeFurnitureBank_OnEvent(event)

	if(event == "BIEYE_OPEN_FURNITURE_BANK") then


			--------------是否有操作权限
			local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
			local myGuid = Player:GetGUID();
				--婚姻组
			local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()

			local bIsMyBieye = 0
			if isHaveSpouse == 1 then
				if BieYeGuid == myGuid then
					bIsMyBieye = 1
				elseif BieYeGuid == spouseGuid then
					bIsMyBieye = 2 
				else
					return
				end
			end
			--------------是否有操作权限


			if(IsWindowShow("YouLongKa2")) then
			  CloseWindow("YouLongKa2", true);
			end
			if(IsWindowShow("Bank")) then
			  CloseWindow("Bank", true);
			end
			if(IsWindowShow("BigBank")) then
			  CloseWindow("BigBank", true);
			end
			if(IsWindowShow("BieYeBank")) then
			  CloseWindow("BieYeBank", true);
			end
			if(IsWindowShow("BieYeFurnitureTransfer"))then
				CloseWindow("BieYeFurnitureTransfer", true);
			end

			--if(IsWindowShow("BieYe_Mini")) then
			--  CloseWindow("BieYe_Mini", true);
			--end		


			--页签上的红点
			for i=1, PACK_BUTTONS_NUM do
				PACK_BUTTONS_tips[i]:Hide()
			end			

					
				
			if tonumber(arg0) == 0 then 
				--BieYeFurnitureBank_Open()
				for i=1, PACK_BUTTONS_NUM do
					PACK_BUTTONS[i]:Enable()
				end
				
				local g_CurrentRentBox = BieYeFurniture:GetCurRentIndex();
				
				BieYeFurnitureBank_patulousBox_Clicked(g_CurrentRentBox)
			end


		
			if tonumber(arg0) == 1 then 
				--摆放之后触发的
				local remains = tonumber(arg1)
				local isBatchPut = tonumber(arg2)
				--当前种类没有了才打开界面
				---[[
				if remains < 0 or isBatchPut == 0 then
					local g_CurrentRentBox = BieYeFurniture:GetCurRentIndex();
					BieYeFurnitureBank_ChangeCurrrentRecentPage(g_CurrentRentBox)
					g_CurrentPage = BieYeFurniture:GetPageIndex();
					--模拟点击
					BieYeFurnitureBank_UpdateFrame(g_CurrentRentBox )
					for i=1, (g_CurrentPage - 1 )do
						--模拟页数
						BieYeFurnitureBank_DownPage_Clicked()
					end				
					this:Show();
				end
				--]]--


			end

			--代表新的新家具标记
			for i=1, GRID_BUTTONS_NUM do
				GRID_BUTTONS_ICON[i]:SetProperty("Visible","False")
				GRID_BUTTONS_ICON[i]:Hide()
			end		
			
			

	elseif (event == "BIEYE_UPDATE_FURNITURE_BANK") then

		--if( BieYeFurnitureBank_Frame:IsVisible() ) then
			BieYeFurnitureBank_UpdateFrame(g_CurrentRentBox)

			
			if tonumber(arg0) == 0 then 
				this:Show();
				
				--引导任务tips
				BieYeFurnitureBank_Put_Animate:Play(false)
				BieYeFurnitureBank_Buy_Animate:Play(false)
				local bIsInner = BieYeFurniture:GetCurInner() 
				if DataPool:Lua_IsHaveMission(1856) > 0 and bIsInner == 0 then
					local misIndex = DataPool:GetPlayerMissionIndexByID(1856)
					if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
						CloseFreshManGuide()	
						local fX, fY = this:GetChildOffset("BieYeFurnitureBank_Put")
						OpenFreshManGuide(1, 120, fX+60, fY+10, "BieYeFurnitureBank", "northeast")
						BieYeFurnitureBank_Put_Animate:Play(true)
					end
				elseif DataPool:Lua_IsHaveMission(1862) > 0 and bIsInner == 1 then
					local misIndex = DataPool:GetPlayerMissionIndexByID(1862)
					if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
						CloseFreshManGuide()	
						local fX, fY = this:GetChildOffset("BieYeFurnitureBank_Buy")
						OpenFreshManGuide(1, 127, fX+30, fY+20, "BieYeFurnitureBank", "southeast")
						BieYeFurnitureBank_Buy_Animate:Play(true)
					elseif DataPool:GetPlayerMission_Variable(misIndex, 2) == 0 then
						CloseFreshManGuide()	
						local fX, fY = this:GetChildOffset("BieYeFurnitureBank_Put")
						OpenFreshManGuide(1, 128, fX+60, fY+10, "BieYeFurnitureBank", "northeast")
						BieYeFurnitureBank_Put_Animate:Play(true)
					end
				end
			end
		--end
	elseif (event == "BIEYEFURNITUREBANKHIDE") then
			BieYeFurnitureBank_OnHiden()

	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then

		local nType = tonumber(Get_XParam_INT(0))

		if nType == 30 then --打开界面
			BieYeFurnitureBank_OnHiden()
		end
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20170229 then
		local nType = Get_XParam_INT(0)
		if nType == 0 then --更新界面
			BieYeFurnitureBank_HCBieYeFurniture()
		elseif nType == 1 then 
			BieYeFurnitureBank_ZHBieYeFurniture()
		end
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeFurnitureBank_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeFurnitureBank_Frame_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BieYeFurnitureBank_ChangeCurrrentRecentPage(1)
		g_CurrentPage = 1
		BieYeFurniture:SetPageIndex(g_CurrentPage);
		this:Hide()
	elseif (event == "BIEYEFURNITUREBANK_LOG") then
		BieYeFurnitureBank_Log()
		
		
	elseif (event == "FURNITURE_ADD_UPDATE") then
	
		local nCurrentRentBox = tonumber(arg0) + 1
		BieYeFurnitureBank_ChangeCurrrentRecentPage(nCurrentRentBox)


		if(IsWindowShow("BieYeFurnitureBank")) then
			BieYeFurnitureBank_FenYe1:SetProperty("Selected", "True");
			BieYeFurnitureBank_FenYe2:SetProperty("Selected", "False");
			BieYeFurnitureBank_ChangeFurnitureIn()
		end		
		
		if(IsWindowShow("YouLongKa2")) then
		  CloseWindow("YouLongKa2", true);
		end
		
		if(IsWindowShow("Bank")) then
		  CloseWindow("Bank", true);
		end
		if(IsWindowShow("BigBank")) then
		  CloseWindow("BigBank", true);
		end
		if(IsWindowShow("BieYeBank")) then
		  CloseWindow("BieYeBank", true);
		end
		BieYeFurnitureBank_UpdateFrame(g_CurrentRentBox )
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 201611033 then
		local nType = tonumber(Get_XParam_INT(0))
		if nType == 1 then --引导任务tips
			CloseFreshManGuide()	
			local fX, fY = this:GetChildOffset("BieYeFurnitureBank_Put")
			OpenFreshManGuide(1, 128, fX+60, fY+10, "BieYeFurnitureBank", "northeast")
			BieYeFurnitureBank_Put_Animate:Play(true)
		end
	end
	
	
end

function BieYeFurnitureBank_Open()
		BieYeFurnitureBank_ChangeCurrrentRecentPage(0)
		g_CurrentPage = 1;
		g_CurrentMaxFurniturePage = 0
end

--===============================================
-- BieYeFurnitureBank_UpdateFrame
--===============================================
function BieYeFurnitureBank_UpdateFrame(nIndex)
	


	--0是院子  1是居室
	local bIsInner = BieYeFurniture:GetCurInner() 
	local nCount = BieYeFurniture:GetBieYeFurnitureTypeCount()
	local nCountLimit = BieYeFurniture:GetBieYeFurnitureLimitByBieYeLevel()
	local str = nCount .. "/"..nCountLimit


	BieYeFurniture:SetCurRentIndex(nIndex);
	g_CurrentRentBox = nIndex
	

	BieYeFurnitureBank_Delete:SetToolTip("#{BYFUR_160531_72}")
	BieYeFurnitureBank_Show:SetToolTip("#{BYFUR_160531_76}")
	for i=1, PACK_BUTTONS_NUM do
		if(i==nIndex) then
			PACK_BUTTONS[i]:SetProperty("Selected", "True");  
			PACK_BUTTONS[i]:SetProperty("RiseOnClick", "False");
		else
			PACK_BUTTONS[i]:SetProperty("Selected", "False");  
			PACK_BUTTONS[i]:SetProperty("RiseOnClick", "True");
		end
		
		if bIsInner == 1 then
			
			local isInCangKuOrPut = BieYeFurniture:GetBieYeFurnitureInCangKuOrPut() 
			if isInCangKuOrPut == 1 then 
				BieYeFurnitureBank_DragTitle:SetText("#{BYFUR_160531_90}")
			else
				BieYeFurnitureBank_DragTitle:SetText("#{BFYH_170209_12}")
			end

			PACK_BUTTONS[i]:SetText(g_DescriptionInner[i]);

			--contr1
			local strNumText_tools1 = ScriptGlobal_Format("#{BFYH_170209_13}", g_DescriptionInner[nIndex],str)
			BieYeFurnitureBank_Text1_number:SetText(strNumText_tools1)

			local strNumTexttooltips = ScriptGlobal_Format("#{BFYH_170209_15}", g_DescriptionInner[nIndex])	
			BieYeFurnitureBank_Text1_number:SetToolTip(strNumTexttooltips)


			--contr
			local strNumText = ScriptGlobal_Format("#{BYFUR_160531_191}", g_DescriptionInner[nIndex],str)	
			BieYeFurnitureBank_Allnumber:SetText(strNumText)
			BieYeFurnitureBank_Allnumber:SetToolTip("#{BYFUR_160531_208}")
			
			local nInnerPutFurnitureCount =  BieYeFurnitureBank_GetInnerHavePutFurnitureCount()
			local nPutCountLimit = BieYeFurniture:GetBieYePutFurnitureLimitByBieYeLevel(bIsInner)
			local Allnumber1 = ScriptGlobal_Format("#{BFYH_170209_18}", nInnerPutFurnitureCount,nPutCountLimit)		
			BieYeFurnitureBank_Allnumber1:SetText(Allnumber1)
			BieYeFurnitureBank_Allnumber1:SetToolTip("#{BFYH_170209_19}")
			
			

		else
			local isInCangKuOrPut = BieYeFurniture:GetBieYeFurnitureInCangKuOrPut() 		
			if isInCangKuOrPut == 1 then 
				BieYeFurnitureBank_DragTitle:SetText("#{BYFUR_160531_66}")

			else
				BieYeFurnitureBank_DragTitle:SetText("#{BFYH_170209_11}")
			end

			PACK_BUTTONS[i]:SetText(g_DescriptionOuter[i]);


			--contr1
			local strNumText_tools1 = ScriptGlobal_Format("#{BFYH_170209_13}", g_DescriptionOuter[nIndex],str)
			BieYeFurnitureBank_Text1_number:SetText(strNumText_tools1)
			
			local strNumTexttooltips = ScriptGlobal_Format("#{BFYH_170209_14}", g_DescriptionOuter[nIndex])	
			BieYeFurnitureBank_Text1_number:SetToolTip(strNumTexttooltips)

			
			--contr
			local strNumText = ScriptGlobal_Format("#{BYFUR_160531_191}", g_DescriptionOuter[nIndex],str)	
			BieYeFurnitureBank_Allnumber:SetText(strNumText)
			BieYeFurnitureBank_Allnumber:SetToolTip("#{BYFUR_160531_198}")
			
			
			local nOutterPutFurnitureCount =  BieYeFurnitureBank_GetOutterHavePutFurnitureCount()
			local nPutCountLimit = BieYeFurniture:GetBieYePutFurnitureLimitByBieYeLevel(bIsInner)
			local Allnumber1 = ScriptGlobal_Format("#{BFYH_170209_16}", nOutterPutFurnitureCount,nPutCountLimit)		
			BieYeFurnitureBank_Allnumber1:SetText(Allnumber1)
			BieYeFurnitureBank_Allnumber1:SetToolTip("#{BFYH_170209_17}")
		end
	
		BieYeFurnitureBank_Allnumberhelp1:SetToolTip("#{BFYH_170209_20}")
	
	end

	if bIsInner ==  1 then
		BieYeFurnitureBank_Buy:SetToolTip("#{BYFUR_160531_293}")			
		local str = ScriptGlobal_Format("#{BYFUR_160531_93}", g_DescriptionInner[nIndex])
		BieYeFurnitureBank_Put:SetToolTip(str)
		str = ScriptGlobal_Format("#{BFYH_170413_54}", g_DescriptionInner[nIndex])
		BieYeFurnitureBank_PutAll:SetToolTip(str)
	else
		BieYeFurnitureBank_Buy:SetToolTip("#{BYFUR_160531_74}")	
		local str = ScriptGlobal_Format("#{BYFUR_160531_79}", g_DescriptionOuter[nIndex])
		BieYeFurnitureBank_Put:SetToolTip(str)
		str = ScriptGlobal_Format("#{BFYH_170413_53}", g_DescriptionOuter[nIndex])
		BieYeFurnitureBank_PutAll:SetToolTip(str)
	end

	for i=1, GRID_BUTTONS_NUM do
		ActionButton[i]:SetActionItem(-1);
		ActionButton[i]:Enable();
	end


	BieYeFurnitureBank_Fresh()
	--从数据池中使用数据填入背包内的物品

	for i=1, GRID_BUTTONS_NUM  do
		local nActVerifyIndex = ( g_CurrentPage - 1 ) * GRID_BUTTONS_NUM + i - 1

        if nActVerifyIndex >= 0 and nActVerifyIndex <  g_CurrentRentBoxMax  then
			--比最大内存小
			local theAction = BieYeFurniture:EnumItem( nActVerifyIndex );
			local nNum  = BieYeFurniture:GetNum( nActVerifyIndex );
			
			if theAction:GetID() ~= 0 then
				ActionButton[i]:SetActionItem(theAction:GetID());
				if nNum > 0 then
					GRID_BUTTONS[i]:SetProperty("Visible","false")
				else
					GRID_BUTTONS[i]:SetProperty("Visible","true")
				end
			else
				ActionButton[i]:SetActionItem(-1);
				GRID_BUTTONS[i]:SetProperty("Visible","false")
			end
		else
			ActionButton[i]:SetActionItem(-1);
			GRID_BUTTONS[i]:SetProperty("Visible","false")
		end
	end

	--新增物品处理
	--BieYeFurnitureBank_YeQianM:SetProperty("Visible", "False");  
	
	BieYeFurnitureBank_OnChoice()

	local isInCangKuOrPut = BieYeFurniture:GetBieYeFurnitureInCangKuOrPut() 
	if isInCangKuOrPut == 1 then 
		--隐藏面板
		BieYeFurnitureBank_Control1:SetProperty("Visible","False")
		BieYeFurnitureBank_Control1:Hide()
		
		BieYeFurnitureBank_Control:SetProperty("Visible","True")	
	else
			--隐藏面板
		BieYeFurnitureBank_Control:SetProperty("Visible","False")
		BieYeFurnitureBank_Control:Hide()
		
		BieYeFurnitureBank_Control1:SetProperty("Visible","True")
		
	end

end

--===============================================
-- 点击页签的操作 
--===============================================
function BieYeFurnitureBank_patulousBox_Clicked(nIndex)



	local i = 1
	for i=1, GRID_BUTTONS_NUM do

		ActionButton[i]:SetActionItem(-1);
		GRID_BUTTONS[i]:SetProperty("Visible","false")
		ActionButton[i]:Enable();
	end

	for i=1, PACK_BUTTONS_NUM do
		if i ~= nIndex then
			PACK_BUTTONS[i]:SetProperty("Selected", "False");  
			PACK_BUTTONS[i]:SetProperty("RiseOnClick", "False");
		end
	end

	
	BieYeFurnitureBank_ChangeCurrrentRecentPage(nIndex)


	--0是院子  1是居室
	local bIsInner = BieYeFurniture:GetCurInner() 

	local isInCangKuOrPut = BieYeFurniture:GetBieYeFurnitureInCangKuOrPut() 
	if isInCangKuOrPut == 1 then 
		BieYeFurniture:AcquireList(bIsInner,g_CurrentRentBox,0);
	else
		BieYeFurniture:AcquireList(bIsInner,g_CurrentRentBox,7);
	end
		

end


--===============================================
-- 点击关闭
--===============================================
function BieYeFurnitureBank_Close_Clicked()
	PushEvent( "BIEYE_OPEN_MINI" )
	
	--关闭引导任务tips
	if (DataPool:Lua_IsHaveMission(1856) > 0 and DataPool:Lua_IsMissionHaveDone(1856) <= 0) or (DataPool:Lua_IsHaveMission(1862) > 0 and DataPool:Lua_IsMissionHaveDone(1862) <= 0) then
		CloseFreshManGuide()	
	end
	
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeFurnitureBank_Frame_On_ResetPos()
  BieYeFurnitureBank_Frame:SetProperty("UnifiedPosition", g_BieYeFurnitureBank_Frame_UnifiedPosition);
end


function BieYeFurnitureBank_UpPage_Clicked()

    g_CurrentPage = g_CurrentPage - 1
	if g_CurrentPage < 1 then
		g_CurrentPage = 1
	end
	BieYeFurnitureBank_UpdateFrame(g_CurrentRentBox)
	BieYeFurnitureBank_Log()
	
end

function BieYeFurnitureBank_DownPage_Clicked()
	
	g_CurrentPage = g_CurrentPage + 1
	if g_CurrentPage > g_CurrentMaxFurniturePage then
		g_CurrentPage = g_CurrentMaxFurniturePage
	end

	BieYeFurnitureBank_UpdateFrame(g_CurrentRentBox)
	BieYeFurnitureBank_Log()
end



function BieYeFurnitureBank_Buy_Clicked()
	

	--0是院子  1是居室
	local bIsInner = BieYeFurniture:GetCurInner() 
	--local nCount = BieYeFurniture:GetFurCntInCangku(g_Index)
	local nCount = BieYeFurniture:GetBieYeFurnitureTypeCount()
	local nCountLimit = BieYeFurniture:GetBieYeFurnitureLimitByBieYeLevel()

	local strNumText =""
	if bIsInner == 0 then 
	--居室内
			strNumText = ScriptGlobal_Format("#{BYFUR_160531_96}", g_DescriptionOuter[g_CurrentRentBox])
	
	else
		
		    strNumText = ScriptGlobal_Format("#{BYFUR_160531_115}", g_DescriptionInner[g_CurrentRentBox])		
	
	end

	if nCount >= nCountLimit  then
		PushDebugMessage(strNumText)
		return 
	end
	-- 打开背包道具栏
	if( IsWindowShow("Packet") == false ) then
		ToggleContainer()
	end

	PushEvent( "FURNITURE_TEMP_OPEN",g_CurrentRentBox )
	
	--关闭引导任务tips
	if DataPool:Lua_IsHaveMission(1862) > 0 and DataPool:Lua_IsMissionHaveDone(1862) <= 0 then
		CloseFreshManGuide()	
		BieYeFurnitureBank_Buy_Animate:Play(false)
	end
end

function BieYeFurnitureBank_ItemBtnSubClicked( nLine,nRow )

	local nIndex = ( nLine - 1 ) * GRID_LINE_NUM + nRow;
	if(nIndex < 1 or nIndex > GRID_BUTTONS_NUM) then
		return;
	end
	ActionButton[nIndex]:DoSubAction()
end



function BieYeFurnitureBank_Log()
	
	 BieYeFurniture:SetCurRentIndex(g_CurrentRentBox);
	 BieYeFurniture:SetPageIndex(g_CurrentPage);
	
	 --PushDebugMessage("g_CurrentRentBox"..g_CurrentRentBox.."g_CurrentPage"..g_CurrentPage.."g_SelIndex"..g_SelIndex)
end
--打开关于界面
function BieYeFurnitureBank_OpenAllHelp(Help)
	
	local posX, posY = Player:GetPos();
	--0是院子  1是居室
	local bIsInner = BieYeFurniture:GetCurInner() 
	if Help == 1 then
		
		if bIsInner == 1 then

			PushEvent("OPEN_BIEYEALLHELP",3)
		else

			PushEvent("OPEN_BIEYEALLHELP",1)		
		end

	elseif Help == 2 then
		if bIsInner == 1 then
			PushEvent("OPEN_BIEYEALLHELP",4)	
		else
			PushEvent("OPEN_BIEYEALLHELP",2)		
		end
		
	elseif Help == 3 then
		PushEvent("OPEN_BIEYEALLHELP",5)	
	
	end
end
function BieYeFurnitureBank_Check()
	
	if g_CurrentRentBox > PACK_BUTTONS_NUM then
		BieYeFurnitureBank_ChangeCurrrentRecentPage(PACK_BUTTONS_NUM)
	end

	local nFurnitureCount = BieYeFurniture:GetBieYeFurnitureCurCount()

	local nPct = math.mod(nFurnitureCount, GRID_BUTTONS_NUM)

	local nDev = math.floor(nFurnitureCount / GRID_BUTTONS_NUM)
	
    if nPct > 0 then
        g_CurrentMaxFurniturePage = nDev + 1
	else
	    g_CurrentMaxFurniturePage = nDev
	end	
	

	if g_CurrentPage > g_CurrentMaxFurniturePage then
		g_CurrentPage = g_CurrentMaxFurniturePage
		BieYeFurniture:SetPageIndex(g_CurrentPage);

	end
		
	if nFurnitureCount == 0 then 
		g_CurrentPage = 1
		BieYeFurniture:SetPageIndex(1);	
	end
end
function BieYeFurnitureBank_Fresh()
	BieYeFurnitureBank_Check()
	if g_CurrentPage >= g_CurrentMaxFurniturePage  then
		BieYeFurnitureBank_Item_PageDown:Disable()
	else
		BieYeFurnitureBank_Item_PageDown:Enable()		
	end
	
	if g_CurrentPage <= 1 then
		BieYeFurnitureBank_Item_PageUp:Disable()
	else
		BieYeFurnitureBank_Item_PageUp:Enable()		
	end
end
function BieYeFurnitureBank_ChangeCurrrentRecentPage(CurRcentPage)
	g_CurrentRentBox = CurRcentPage
	BieYeFurniture:SetCurRentIndex(g_CurrentRentBox);
	PushEvent("UPDATE_BUHUO_EQUIPINDEX",g_CurrentRentBox)	
end
function BieYeFurnitureBank_OnHiden()

	BieYeFurnitureBank_Close_Clicked()
	
end
function BieYeFurnitureBank_HCBieYeFurniture()

	PushEvent("SHOWFURNITURE_CKHC",0)
	BieYeFurnitureBank_Close_Clicked()

end
function BieYeFurnitureBank_ZHBieYeFurniture()

	PushEvent("SHOWFURNITURE_CKZH")
	BieYeFurnitureBank_Close_Clicked()

end

function BieYeFurnitureBank_PutFurniture()
	Lua_SetBieYeFurniture(0)
	--关闭引导任务tips
	if (DataPool:Lua_IsHaveMission(1856) > 0 and DataPool:Lua_IsMissionHaveDone(1856) <= 0) or (DataPool:Lua_IsHaveMission(1862) > 0 and DataPool:Lua_IsMissionHaveDone(1862) <= 0) then
		CloseFreshManGuide()	
	end
end

function BieYeFurnitureBank_PutFurnitureBatch()
	Lua_SetBieYeFurniture(1)
	--关闭引导任务tips
	if (DataPool:Lua_IsHaveMission(1856) > 0 and DataPool:Lua_IsMissionHaveDone(1856) <= 0) or (DataPool:Lua_IsHaveMission(1862) > 0 and DataPool:Lua_IsMissionHaveDone(1862) <= 0) then
		CloseFreshManGuide()	
	end
end

function BieYeFurnitureBank_OnMoved()
    if "BieYeFurnitureBank" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
end

function BieYeFurnitureBank_OnTransferClick()
	PushEvent("BIEYE_OPENFURNITURE_TRANSFER")
end
function BieYeFurnitureBank_ChangeFurnitureIn()
		BieYeFurniture:SetBieYeFurnitureInCangKuOrPut(1) 
		BieYeFurnitureBank_ChangeFurnitureInOrOutFresh()
end

function BieYeFurnitureBank_ChangeFurnitureOut()
		BieYeFurniture:SetBieYeFurnitureInCangKuOrPut(0) 
		BieYeFurnitureBank_ChangeFurnitureInOrOutFresh()
end
function BieYeFurnitureBank_ChangeFurnitureInOrOutFresh()
	

	SetDefaultMouse();
	
	--重置页面
	local str = 0 .. "/" ..0
	local bIsInner = BieYeFurniture:GetCurInner() 
	if bIsInner == 1 then
		local strNumText_tools1 = ScriptGlobal_Format("#{BFYH_170209_13}", g_DescriptionInner[g_CurrentRentBox],str)
		BieYeFurnitureBank_Text1_number:SetText(strNumText_tools1)
		local strNumText = ScriptGlobal_Format("#{BYFUR_160531_191}", g_DescriptionInner[g_CurrentRentBox],str)	
		BieYeFurnitureBank_Allnumber:SetText(strNumText)
		local Allnumber1 = ScriptGlobal_Format("#{BFYH_170209_18}", 0,0)		
		BieYeFurnitureBank_Allnumber1:SetText(Allnumber1)
		BieYeFurnitureBank_DragTitle:SetText("#{BFYH_170209_12}")
	else
		local strNumText_tools1 = ScriptGlobal_Format("#{BFYH_170209_13}", g_DescriptionOuter[g_CurrentRentBox],str)
		BieYeFurnitureBank_Text1_number:SetText(strNumText_tools1)
		local strNumText = ScriptGlobal_Format("#{BYFUR_160531_191}", g_DescriptionOuter[g_CurrentRentBox],str)	
		BieYeFurnitureBank_Allnumber:SetText(strNumText)
		local Allnumber1 = ScriptGlobal_Format("#{BFYH_170209_16}", 0,0)		
		BieYeFurnitureBank_Allnumber1:SetText(Allnumber1)
		BieYeFurnitureBank_DragTitle:SetText("#{BFYH_170209_11}")
	end

			
	--页签上的红点
	BieYeFurnitureBank_OnChoice()	
			
	local isInCangKuOrPut = BieYeFurniture:GetBieYeFurnitureInCangKuOrPut() 
	if isInCangKuOrPut == 1 then 
		--隐藏面板
		BieYeFurnitureBank_Control1:SetProperty("Visible","False")
		BieYeFurnitureBank_Control1:Hide()
		
		BieYeFurnitureBank_Control:SetProperty("Visible","True")
		
		--0是院子  1是居室
		BieYeFurniture:AcquireList(bIsInner,g_CurrentRentBox,0);


		
	else
			--隐藏面板
		BieYeFurnitureBank_Control:SetProperty("Visible","False")
		BieYeFurnitureBank_Control:Hide()
		
		BieYeFurnitureBank_Control1:SetProperty("Visible","True")
		
		
		local bIsInner = BieYeFurniture:GetCurInner() 
		BieYeFurniture:AcquireList(bIsInner,g_CurrentRentBox,7);
	end

	if(IsWindowShow("BieYeFurnitureDestroy")) then
	    CloseWindow("BieYeFurnitureDestroy", true);
	end

end

function BieYeFurnitureBank_GetInnerHavePutFurnitureCount()
	--新版本界面处理
	local nCount =0
	for i =1,PACK_BUTTONS_NUM do
		local bShow = BieYeFurniture:Lua_GetBieYeFurnitureBoxHaveFur(i,1) 
		if bShow > 0 then 
			nCount = nCount + bShow
		end
	end		
	
	return  nCount	
end


function BieYeFurnitureBank_GetOutterHavePutFurnitureCount()
	--新版本界面处理
	local nCount =0
	for i = 1,PACK_BUTTONS_NUM do
		local bShow = BieYeFurniture:Lua_GetBieYeFurnitureBoxHaveFur(i,0) 
		if bShow > 0 then 
			nCount = nCount + bShow
		end
	end		
	
	return  nCount	
end




function BieYeFurnitureBank_OnChoice()

	
	local bcheck1 = BieYeFurnitureBank_HavedCheckButton:GetCheck()
	local bIsInner = BieYeFurniture:GetCurInner() 



	for i =1,PACK_BUTTONS_NUM do
		PACK_BUTTONS_tips[i]:Hide()
	end		

	if bcheck1 == 1 then
		--新版本界面处理
		
		for i =1,PACK_BUTTONS_NUM do
			local bShow = BieYeFurniture:Lua_GetBieYeFurnitureBoxHaveFur(i,bIsInner) 
			if bShow > 0 then 
				
				PACK_BUTTONS_tips[i]:Show()
			end
		end		
	end
end