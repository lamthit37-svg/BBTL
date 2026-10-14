local g_BieYeFurniture_Frame_UnifiedXPosition;
local g_BieYeFurniture_Frame_UnifiedYPosition;
local g_FurnitureListImage = "Ach_AchIcon_Cup"
local g_FurnitureListImageSet = "Ach"
local g_nFurnitureLeftButton = {}			--左侧列表
local g_nFurnitureTypeID = {}			--家具ID
local g_FurnitureListScrollbarPos = 0.0
local g_nCurSelectListIndex = 1	--当前选中的列表项
local g_nCurSelectMBF = 0
local g_nCurSelectJDId = 0
local g_nCurSelectJDIdBind = 0
local g_HC_Gain_NPCID = -1
local g_BIEYE_OBJ_DISTANCE = 3.0
local g_nSecType = 1  --家具绑定二次确认
local g_nTableIndex = 0
local g_QiaoJiangFu_Name = {[1] = "#{JJHC_160620_167}",[2] = "#{JJHC_160620_168}",[3] = "#{JJHC_160620_169}",[4] = "#{JJHC_160620_170}"}
local g_FurnitureInnerType =
{
	[0] = {Name="床帐"  ,Pos=1 ,Type=1},
	[1] = {Name="居室桌"    ,Pos=1 ,Type=2},
	[2] = {Name="条案"  ,Pos=1 ,Type=3},
	[3] = {Name="茶几"  ,Pos=1 ,Type=4},
	[4] = {Name="椅"    ,Pos=1 ,Type=5},
	[5] = {Name="居室凳"    ,Pos=1 ,Type=6},
	[6] = {Name="柜架"  ,Pos=1 ,Type=7},
	[7] = {Name="屏风"  ,Pos=1 ,Type=8},
	[8] = {Name="灯烛"  ,Pos=1 ,Type=9},
	[9] = {Name="装饰"  ,Pos=1 ,Type=10},
	[10] = {Name="隔断"   ,Pos=1 ,Type=11},	
	[11] = {Name="地毯" ,Pos=1 ,Type=12},	
}
local g_FurnitureOuterType =
{
	[0]  = {Name="庭院桌"    ,Pos=0 ,Type=1},
	[1]  = {Name="庭院凳"    ,Pos=0 ,Type=2},
	[2]  = {Name="喷泉"  ,Pos=0 ,Type=3},
	[3]  = {Name="影壁"  ,Pos=0 ,Type=4},
	[4]  = {Name="风灯"  ,Pos=0 ,Type=5},
	[5]  = {Name="鼎"    ,Pos=0 ,Type=6},
	[6]  = {Name="奇石"  ,Pos=0 ,Type=7},
	[7]  = {Name="树木"  ,Pos=0 ,Type=8},
	[8]  = {Name="植栽"  ,Pos=0 ,Type=9},
	[9]  = {Name="玩物"  ,Pos=0 ,Type=10},
	[10] = {Name="栏杆"  ,Pos=0 ,Type=11},
	[11] = {Name="花草"  ,Pos=0 ,Type=12},
}
local g_FurnitureMBF =
{
	[0] = {ID=38001824,Level=1},
	[1] = {ID=38001825,Level=2},
	[2] = {ID=38001826,Level=3},
	[3] = {ID=38001827,Level=4},
	[4] = {ID=38001854,Level=1},
	[5] = {ID=38001855,Level=2},
	[6] = {ID=38001856,Level=3},
	[7] = {ID=38001857,Level=4},
}

local g_FurnitureMaxLevel = 5    --家具最高等级5
local g_CostMoney = {[2] = 20000,[3] = 20000,[4] = 30000,[5] = 50000} --合成需要花费的金钱
local g_Bag_Index = -1
--local g_nFurnitureConfirm = 1  --家具合成确认

function BieYeFurniture_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--this:RegisterEvent("UPDATE_FURNITURE_BAG")
	this:RegisterEvent("UPDATE_FURNITUREBAG_SEC")	
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("BIEYE_OPEN_FURNITURE_BANK")
end


function BieYeFurniture_OnLoad()
	-- 保存界面的默认相对位置
	g_BieYeFurniture_Frame_UnifiedXPosition	= BieYeFurnitureFrame : GetProperty("UnifiedXPosition");
	g_BieYeFurniture_Frame_UnifiedYPosition	= BieYeFurnitureFrame : GetProperty("UnifiedYPosition");
end		
		
		
				
function BieYeFurniture_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 20160620 then
		
		--if(IsWindowShow("BieYeFurnitureBank")) then
		--  	PushEvent("BIEYE_OPEN_MINI")
		--end
		local nType = Get_XParam_INT(0)
		
		if nType == 0 then --打开界面
			PushEvent( "BIEYEFURNITUREBANKHIDE" )
			if(IsWindowShow("BieYeDecoration")) then
				CloseWindow("BieYeDecoration",true)
			end
			if(IsWindowShow("BieYeWarehome")) then
				CloseWindow("BieYeWarehome",true)
			end
			
			this:Show()	
			g_nTableIndex = 0
			BieYeFurniture_Button01:SetCheck(1)
			BieYeFurniture_Button02:SetCheck(0)

			BieYeFurniture_Title:SetText("#{JJHC_160620_13}")
			BieYeFurniture_Explain:SetText("#{JJHC_160620_68}")
--[[			if g_nFurnitureConfirm == 1 then 
				BieYeFurniture_Check:SetCheck(1)				
			else
				BieYeFurniture_Check:SetCheck(0)
			end
--]]

			BieYeFurniture_LeftLoad()
			BieYeFurniture_UpdateMoneyDisp()
			BieYeFurniture_SetLeftButtonSelected(1)		--设置选中的类型高亮
			BieYeFurniture_ShowIcon(1)
			g_nSecType = 0
			
			------------------------------------------------
			local npcObjID = Get_XParam_INT(1)	;
			BieYeFurniture_BeginCareObject( npcObjID )	
			------------------------------------------------
			BieYeFurniture_OK_Animate:Play(false)
			BieYeFurniture_ButtownShow()
		elseif nType == 1 then --更新界面
			BieYeFurniture_UpdateMoneyDisp()
			BieYeFurniture_IconUpdate()
			g_nSecType = 0
		elseif nType == 600 then --家园引导任务 打开界面 改变默认显示
			PushEvent( "BIEYEFURNITUREBANKHIDE" )
			if(IsWindowShow("BieYeDecoration")) then
				CloseWindow("BieYeDecoration",true)
			end
			if(IsWindowShow("BieYeWarehome")) then
				CloseWindow("BieYeWarehome",true)
			end
			this:Show()	
			g_nTableIndex = 1
			BieYeFurniture_Button01:SetCheck(0)
			BieYeFurniture_Button02:SetCheck(1)

			BieYeFurniture_Title:SetText("#{JJHC_160620_13}")
			BieYeFurniture_Explain:SetText("#{JJHC_160620_68}")
			BieYeFurniture_LeftLoad()
			BieYeFurniture_UpdateMoneyDisp()
			BieYeFurniture_SetLeftButtonSelected(2)		--设置选中的类型高亮
			BieYeFurniture_ShowIcon(1)
			g_nSecType = 0
			
			------------------------------------------------
			local npcObjID = Get_XParam_INT(1)	;
			BieYeFurniture_BeginCareObject( npcObjID )	
			------------------------------------------------
			BieYeFurniture_OK_Animate:Play(false)
			if DataPool:Lua_IsHaveMission(1861) > 0 then	--引导任务tips
				local misIndex = DataPool:GetPlayerMissionIndexByID(1861)
				if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
					CloseFreshManGuide()	
					local fX, fY = this:GetChildOffset("BieYeFurniture_ListContent_title")
					OpenFreshManGuide(1, 129, fX, fY+40, "BieYeFurniture", "northwest")	
				end
			end
		end
		BieYeFurniture_Fresh()
	elseif event == "MONEY_CHANGE_EX" and this:IsVisible() then
			BieYeFurniture_UpdateMoneyDisp()
	elseif event == "BIEYE_OPEN_FURNITURE_BANK" and this:IsVisible() then
		if tonumber(arg0) == 0 then 		
			BieYeFurniture_Close()
		end
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then
		local nType = Get_XParam_INT(0)
		
		if nType == 30 then --打开界面
			BieYeFurniture_Close()
		end
	
	elseif event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
			BieYeFurniture_UpdateMoneyDisp()
	--elseif event == "UPDATE_FURNITURE_BAG" and this:IsVisible() then
	--	if arg0~= nil then
	--		BieYeFurniture_UpdateMBF(arg0)
	--	end
	elseif ( event == "OBJECT_CARED_EVENT" and this : IsVisible() ) then
        if( tonumber(arg0) ~= g_HC_Gain_NPCID ) then
			return
		end
       	--- 如果和NPC的距离大于一定的距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > g_BIEYE_OBJ_DISTANCE or arg1=="destroy") then
					BieYeFurniture_Close()
		end
	elseif event == "UPDATE_FURNITUREBAG_SEC" then
		local nType = tonumber(arg0)
		if nType == 1 then
			g_nSecType = 1
		elseif nType == 2 then	
			g_nSecType = 1		
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeFurniture_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化		
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		BieYeFurniture_Frame_On_ResetPos();

	end
end
--更新主界面位置
function BieYeFurniture_Frame_On_ResetPos()

	BieYeFurnitureFrame : SetProperty("UnifiedXPosition", g_BieYeFurniture_Frame_UnifiedXPosition);
	BieYeFurnitureFrame : SetProperty("UnifiedYPosition", g_BieYeFurniture_Frame_UnifiedYPosition);

end		
--左侧家具类型加载		
function BieYeFurniture_LeftLoad()
		BieYeFurniture_ListContent:CleanAllElement("BieYeFurniture")
		BieYeFurniture_ListContent:SetVertScrollbarHide()
		g_nFurnitureLeftButton = {}
		g_nFurnitureTypeID = {}
		if g_nTableIndex == 0 then
			for i=0,table.getn(g_FurnitureOuterType) do

				BieYeFurniture_AddCatalog("#e010101#cFDEACA"..g_FurnitureOuterType[i].Name)
				BieYeFurniture_AddID(i*5,0,g_FurnitureOuterType[i].Type,g_FurnitureOuterType[i].Pos)
				
				for j=1,4 do
					local nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(j+1,g_FurnitureOuterType[i].Type,0,0,0)
				        nname = string.format("#e010101#cFDEACA%s",nname)
					BieYeFurniture_AddText(nname)
					BieYeFurniture_AddID(i*5+j,j+1,g_FurnitureOuterType[i].Type,g_FurnitureOuterType[i].Pos)	
				end			
			end
		end

		if g_nTableIndex == 1 then
			for i=0,table.getn(g_FurnitureInnerType) do
				
				BieYeFurniture_AddCatalog("#e010101#cFDEACA"..g_FurnitureInnerType[i].Name)
				BieYeFurniture_AddID(i*5,0,g_FurnitureInnerType[i].Type,g_FurnitureInnerType[i].Pos)
				
				for j=1,4 do
					local nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(j+1,g_FurnitureInnerType[i].Type,1,0,0)
					nname = string.format("#e010101#cFDEACA%s",nname)
					BieYeFurniture_AddText(nname)
					BieYeFurniture_AddID(i*5+j,j+1,g_FurnitureInnerType[i].Type,g_FurnitureInnerType[i].Pos)	
				end			
			end			
		end

		
		BieYeFurniture_ListContent:SetVertScrollbarPosition(g_FurnitureListScrollbarPos)
		BieYeFurniture_ListContent:SetVertScrollbarHide()
		BieYeFurniture_ListContent:Flash()		
end
		
function BieYeFurniture_Close()
	BieYeFurniture_ListContent:CleanAllElement("BieYeFurniture")
	BieYeFurniture_ListContent:SetVertScrollbarHide()
	g_nFurnitureLeftButton = {}
	g_nFurnitureTypeID = {}	
	BieYeFurniture_Resume(0)
	
	--关闭引导任务tips
	if DataPool:Lua_IsHaveMission(1861) > 0 and DataPool:Lua_IsMissionHaveDone(1861) <= 0 then
		CloseFreshManGuide()	
	end
	
	this:Hide()
end


--增加类型控件
function BieYeFurniture_AddCatalog(nText)
	local FurnitureCatalog = BieYeFurniture_ListContent:AddItemElement( "BieYeFurniture", "LEFT", "BieYeFurniture","" ,"")
	FurnitureCatalog:SetProperty("AchievementWindowCatalogButtonHover","AchievementHoverSection")
	FurnitureCatalog:AddTextCatalogTextAndImage(nText,g_FurnitureListImage,g_FurnitureListImageSet)
	table.insert(g_nFurnitureLeftButton,FurnitureCatalog)
end

--增加子类型控件
function BieYeFurniture_AddText(nText)
	local FurnitureText = BieYeFurniture_ListContent:AddItemElement("BieYeFurnitureText","LEFT","BieYeFurniture","","")
	FurnitureText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	FurnitureText:AddTextTextAndImage(nText,"","")
	FurnitureText:Hide()		--刚开始子控件不可见
	table.insert(g_nFurnitureLeftButton,FurnitureText)
end

--增加类型ID和子类型ID数据
function BieYeFurniture_AddID(num,Level,TypeID,nPos)
	local nItem = {}
	nItem.num = num
	nItem.Level = Level
	nItem.TypeID = TypeID
	nItem.Pos = nPos
	table.insert(g_nFurnitureTypeID,nItem)
end

--点击左侧选项
function BieYeFurniture_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	
	if DataPool:Lua_IsHaveMission(1861) > 0 and g_nTableIndex == 1 then	--引导任务tips
		local misIndex = DataPool:GetPlayerMissionIndexByID(1861)
		if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
			if CurClickIndex == 0 then
				CloseFreshManGuide()	
				local fX, fY = this:GetChildOffset("BieYeFurniture_ListContent_title")
				OpenFreshManGuide(1, 130, fX, fY+60, "BieYeFurniture", "southwest")	
				BieYeFurniture_OK_Animate:Play(true)
			elseif CurClickIndex == 1 then
				CloseFreshManGuide()	
				local fX, fY = this:GetChildOffset("BieYeFurniture_OK")
				OpenFreshManGuide(1, 125, fX+30, fY+20, "BieYeFurniture", "southwest")	
			end
		end
	end
	
	if CurClickIndex + 1 > 0 and CurClickIndex + 1~=g_nCurSelectListIndex then
		BieYeFurniture_Resume(0)
		g_nCurSelectMBF = 0 -- 点击了左面的 就需要更新下免爆符的初始状态
		g_nCurSelectListIndex =	CurClickIndex + 1
		BieYeFurniture_SetLeftButtonSelected(g_nCurSelectListIndex)		--设置选中的类型高亮
		BieYeFurniture_ShowIcon(g_nCurSelectListIndex)		

	else
		return
	end
	BieYeFurniture_ButtownShow()
	BieYeFurniture_UpdateMoneyDisp()
end


--设置左侧列表中选中的目录
function BieYeFurniture_SetLeftButtonSelected(nIndex)
	
	if nIndex <= 0 then return end
	for BtnIndex = 1,table.getn(g_nFurnitureLeftButton) do
		if nil ~= g_nFurnitureTypeID[BtnIndex] and nil ~= g_nFurnitureLeftButton[BtnIndex] then
			if g_nFurnitureTypeID[BtnIndex].Level == 0 then		--如果是一级目录
				if g_nFurnitureTypeID[nIndex].TypeID == g_nFurnitureTypeID[BtnIndex].TypeID and g_nFurnitureTypeID[nIndex].Pos == g_nFurnitureTypeID[BtnIndex].Pos then
					g_nFurnitureLeftButton[BtnIndex]:SetCatalogButtonSelect(true);
				else
					g_nFurnitureLeftButton[BtnIndex]:SetCatalogButtonSelect(false);
				end
			elseif g_nFurnitureTypeID[BtnIndex].Level > 0 then	--如果是二级目录
				if nIndex == BtnIndex then
					g_nFurnitureLeftButton[BtnIndex]:SetTextCatalogSelected(true)
				else
					g_nFurnitureLeftButton[BtnIndex]:SetTextCatalogSelected(false)
					if g_nFurnitureTypeID[BtnIndex].TypeID ~= g_nFurnitureTypeID[nIndex].TypeID then
						g_nFurnitureLeftButton[BtnIndex]:Hide()
					end					
				end
			end
		end
	end
	BieYeFurniture_ListContent:SetVertScrollbarHide()
	BieYeFurniture_ListContent:Flash()
end

--显示图标
function BieYeFurniture_ShowIcon(nIndex)
	if nIndex <= 0 then 
		return 
	end
	if nil == g_nFurnitureTypeID[nIndex] then
		return
	end
	
	local nLevel = g_nFurnitureTypeID[nIndex].Level
	local nType = g_nFurnitureTypeID[nIndex].TypeID
	local nPos = g_nFurnitureTypeID[nIndex].Pos
	
	if nLevel == 0 then
		BieYeFurniture_Item:SetActionItem(-1);
		BieYeFurniture1_Item:SetActionItem(-1);
	--	BieYeFurniture1_Item1:SetActionItem(-1);
		BieYeFurniture1_Amount:SetText("")
	--	BieYeFurniture1_Amount1:SetText("")
		g_nCurSelectJDId = 0
		g_nCurSelectJDIdBind = 0
		return
	end
	
	BieYeFurniture1_Amount:SetText("")
--	BieYeFurniture1_Amount1:SetText("")
--	BieYeFurniture1_Amount1:SetProperty("Visible","False")
	local ItemID_up = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,0,0)
	local ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel-1,nType,nPos,0,0)
	local ItemIDBind = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel-1,nType,nPos,0,1)


	DataPool:Lua_SetBieYeOperateActionItem(2,ItemID_up);
	DataPool:Lua_UpdateBieYeOperateActionItem()
	local theAction_Up = EnumAction(2, "bieye_operate");
	if theAction_Up:GetID() ~= 0 then	
		BieYeFurniture_Item:SetActionItem(theAction_Up:GetID());
	end	
	
	
	DataPool:Lua_SetBieYeOperateActionItem(0,ItemID);
	DataPool:Lua_UpdateBieYeOperateActionItem()
	local theAction2 = EnumAction(0, "bieye_operate");
	if theAction2:GetID() ~= 0 then	
		g_nCurSelectJDId = ItemID
		g_nCurSelectJDIdBind = ItemIDBind
		BieYeFurniture1_Item:SetActionItem(theAction2:GetID());
		local itemcount = PlayerPackage:CountAvailableItemByIDTable(ItemID)
		local itemcountBind = PlayerPackage:CountAvailableItemByIDTable(ItemIDBind)
		itemcount = itemcount + itemcountBind
		if itemcount == 0 then
			BieYeFurniture1_Amount:SetText("#W#e0000010")				
		elseif itemcount < 2 then
			BieYeFurniture1_Amount:SetText("#W#e000001"..itemcount)	
		else
			BieYeFurniture1_Amount:SetText("#W#e000001"..itemcount)
		end
	end		
end

--更新金钱 
function BieYeFurniture_UpdateMoneyDisp()
	
		if g_nCurSelectListIndex >= 0 then 
			local nType = g_nFurnitureTypeID[g_nCurSelectListIndex].TypeID
			local nLevel = g_nFurnitureTypeID[g_nCurSelectListIndex].Level
			if(nLevel == 0 or nLevel == "" or nLevel == nil) then
				BieYeFurniture_DemandMoney:SetProperty("MoneyNumber", 0);
				return 
			end
			local nPos = g_nFurnitureTypeID[g_nCurSelectListIndex].Pos
			local ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,0,0) 

			if g_nCurSelectJDId > 0 then 
				BieYeFurniture_DemandMoney:SetProperty("MoneyNumber", g_CostMoney[nLevel]);
			else
				BieYeFurniture_DemandMoney:SetProperty("MoneyNumber", 0);
			end
		end
	
	
	
		local playerMoney = Player:GetData("MONEY");
		local playerMoneyJZ = Player:GetData("MONEY_JZ");

		BieYeFurniture_CurrentlyJiaozi:SetProperty("MoneyNumber", playerMoneyJZ);
		BieYeFurniture_CurrentlyMoney:SetProperty("MoneyNumber", playerMoney);
end

--[[--免爆符拖拽更新
function BieYeFurniture_UpdateMBF(Item_index)	
	local i_index = tonumber(Item_index)


	if i_index > 0  then
		local ItemID = PlayerPackage : GetItemTableIndex( i_index )
		if PlayerPackage:IsLock(i_index) == 1 then
			PushDebugMessage("#{JJHC_160620_32}")
			return
		end	
		
		local isFu = 0
		local FuLevel = 0
		for i=0,table.getn(g_FurnitureMBF) do
			if ItemID == g_FurnitureMBF[i].ID then
				isFu = 1
				FuLevel = g_FurnitureMBF[i].Level
			end
		end
		
		if isFu ~= 1 then
			PushDebugMessage("#{JJHC_160620_33}")
			return
		end
		
		
		if nil == g_nFurnitureTypeID[g_nCurSelectListIndex] then
			PushDebugMessage("#{JJHC_160620_34}")
			return
		end
		
		if g_nFurnitureTypeID[g_nCurSelectListIndex].Level < 2 then
			PushDebugMessage("#{JJHC_160620_35}")
			return
		end
		
		--判断一下免爆符的等级
		if FuLevel+1 ~= g_nFurnitureTypeID[g_nCurSelectListIndex].Level then
			local str = g_QiaoJiangFu_Name[g_nFurnitureTypeID[g_nCurSelectListIndex].Level - 1]
			PushDebugMessage(str)
			return		
		end
		
		BieYeFurniture_Resume(1)


	
		DataPool:Lua_SetBieYeOperateActionItem(1,ItemID);
		DataPool:Lua_UpdateBieYeOperateActionItem()
		local theAction = EnumAction(1, "bieye_operate");
		
		g_nCurSelectMBF = ItemID
		
		BieYeFurniture1_Item1:SetActionItem(theAction:GetID());
		g_Bag_Index = i_index
		LifeAbility : Lock_Packet_Item(i_index,1)	
		local itemcount = PlayerPackage:GetBagItemNum(g_Bag_Index)
		--local itemcount = PlayerPackage:CountAvailableItemByIDTable(ItemID)
		if itemcount < 1 then
			BieYeFurniture1_Amount1:SetText(itemcount)	
			BieYeFurniture1_Amount1:SetProperty("Visible","False")
		else
			BieYeFurniture1_Amount1:SetText(itemcount)
			BieYeFurniture1_Amount1:SetProperty("Visible","True")
		end
	end
end--]]


function BieYeFurniture_Resume(MBF)
	if g_Bag_Index ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Bag_Index,0);
	end

	g_Bag_Index = -1
--	BieYeFurniture1_Item1:SetActionItem(-1);
--	BieYeFurniture1_Amount1:SetText("")
--	BieYeFurniture1_Amount1:SetProperty("Visible","False")
		
	if MBF == 0 then
		g_nCurSelectListIndex = 1
	end

end

function BieYeFurniture_HeCheng()

	local tmpItem = PlayerPackage:GetBagItemNum(g_Bag_Index)
	if tmpItem <= 0 then
		g_nCurSelectMBF = 0
		g_Bag_Index = -1
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCompound" )
		Set_XSCRIPT_ScriptID( 891837 )
		Set_XSCRIPT_Parameter(0,g_nFurnitureTypeID[g_nCurSelectListIndex].TypeID);
		Set_XSCRIPT_Parameter(1,g_nFurnitureTypeID[g_nCurSelectListIndex].Level);
		Set_XSCRIPT_Parameter(2,g_nFurnitureTypeID[g_nCurSelectListIndex].Pos);
		Set_XSCRIPT_Parameter(3,g_Bag_Index);
		Set_XSCRIPT_Parameter(4,g_nSecType);		
		Set_XSCRIPT_Parameter(5,1);		
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()
	
	--关闭引导任务tips
	if DataPool:Lua_IsHaveMission(1861) > 0 and DataPool:Lua_IsMissionHaveDone(1861) <= 0 then
		CloseFreshManGuide()	
	end
end
function BieYeFurniture_OneKey_HeCheng()

	local tmpItem = PlayerPackage:GetBagItemNum(g_Bag_Index)
	if tmpItem <= 0 then
		g_nCurSelectMBF = 0
		g_Bag_Index = -1
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOneKeyCompound" )
		Set_XSCRIPT_ScriptID( 891837 )
		Set_XSCRIPT_Parameter(0,g_nFurnitureTypeID[g_nCurSelectListIndex].TypeID);
		Set_XSCRIPT_Parameter(1,g_nFurnitureTypeID[g_nCurSelectListIndex].Level);
		Set_XSCRIPT_Parameter(2,g_nFurnitureTypeID[g_nCurSelectListIndex].Pos);
		Set_XSCRIPT_Parameter(3,0);
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
	
	--关闭引导任务tips
	if DataPool:Lua_IsHaveMission(1861) > 0 and DataPool:Lua_IsMissionHaveDone(1861) <= 0 then
		CloseFreshManGuide()	
	end
end
function BieYeFurniture_IconUpdate()
		local itemcount1 = PlayerPackage:CountAvailableItemByIDTable(g_nCurSelectJDId)
		local itemcount1Bind = PlayerPackage:CountAvailableItemByIDTable(g_nCurSelectJDIdBind)
		local itemcount1 = itemcount1 + itemcount1Bind
		if itemcount1 == 0 then
			BieYeFurniture1_Amount:SetText("#W#e0000010")				
		elseif itemcount1 < 2 then
			BieYeFurniture1_Amount:SetText("#W#e000001"..itemcount1)	
		else
			BieYeFurniture1_Amount:SetText("#W#e000001"..itemcount1)
		end	
		local itemcount2 = PlayerPackage:GetBagItemNum(g_Bag_Index)
		--local itemcount2 = PlayerPackage:CountAvailableItemByIDTable(g_nCurSelectMBF)
		if itemcount2 < 1 then
			g_Bag_Index = -1
			g_nCurSelectMBF = 0
--			BieYeFurniture1_Amount1:SetText(itemcount2)	
--			BieYeFurniture1_Amount1:SetProperty("Visible","False")
--			BieYeFurniture1_Item1:SetActionItem(-1);
		else
--			BieYeFurniture1_Amount1:SetText(itemcount2)
--			BieYeFurniture1_Amount1:SetProperty("Visible","True")
		end
end


function BieYeFurniture_ConfirmClick()
--[[	local bConfirm = BieYeFurniture_Check:GetCheck();
	if ( bConfirm == 1 ) then
		g_nFurnitureConfirm = 1
	elseif ( bConfirm == 0 ) then
		g_nFurnitureConfirm = 0
	end--]]
end
function BieYeFurniture_BeginCareObject( careObjID )
    g_HC_Gain_NPCID = DataPool : GetNPCIDByServerID( careObjID )
    if -1 == g_HC_Gain_NPCID then
        return 
    end
    this:CareObject( g_HC_Gain_NPCID, 1, "BieYeFurniture" )
end
function BieYeFurniture_EndCareObject( careObjID )
	if g_HC_Gain_NPCID ~= nil and g_HC_Gain_NPCID >= 0 then
        this:CareObject( g_HC_Gain_NPCID, 0, "BieYeFurniture" )
    end
    g_HC_Gain_NPCID = -1
end
function BieYeFurniture_OnChoice(index)

	BieYeFurniture_ListContent:CleanAllElement("BieYeFurniture")
	BieYeFurniture_ListContent:SetVertScrollbarHide()
	g_nFurnitureLeftButton = {}
	g_nFurnitureTypeID = {}	
	BieYeFurniture_Resume(0)

	g_nTableIndex = index
	if g_nTableIndex == 0 then
			BieYeFurniture_Button01:SetCheck(1)
			BieYeFurniture_Button02:SetCheck(0)
	else 
			BieYeFurniture_Button01:SetCheck(0)
			BieYeFurniture_Button02:SetCheck(1)
	end
	
	if(IsWindowShow("BieYeDecoration")) then
		CloseWindow("BieYeDecoration",true)
	end
	if(IsWindowShow("BieYeWarehome")) then
		CloseWindow("BieYeWarehome",true)
	end
	
	BieYeFurniture_Title:SetText("#{JJHC_160620_13}")
	BieYeFurniture_Explain:SetText("#{JJHC_160620_68}")

	
	BieYeFurniture_LeftLoad()
	
	BieYeFurniture_UpdateMoneyDisp()
	
	BieYeFurniture_SetLeftButtonSelected(1)		--设置选中的类型高亮
	
	BieYeFurniture_ShowIcon(1)
	g_nSecType = 0
	
	------------------------------------------------
	local npcObjID = Get_XParam_INT(1)	;
	BieYeFurniture_BeginCareObject( npcObjID )	
	------------------------------------------------
	
	this:Show()	
	
	
--[[	if g_nFurnitureConfirm == 1 then 
		BieYeFurniture_Check:SetCheck(1)				
	else
		BieYeFurniture_Check:SetCheck(0)
	end
--]]

	BieYeFurniture_Fresh()
	BieYeFurniture_ButtownShow()
end
function BieYeFurniture_OnHiden()
	BieYeFurniture_Close()
	
end

--显示文字更改
function BieYeFurniture_Fresh()

	local bCanHC = {}
	local bCanHCCount = -1
	
	--对二级菜单进行处理
	for i=1,table.getn(g_nFurnitureTypeID) do
		local num = g_nFurnitureTypeID[i].num
		local nType = g_nFurnitureTypeID[i].TypeID
		local nPos = g_nFurnitureTypeID[i].Pos				
		local nLevel = g_nFurnitureTypeID[i].Level
		local ItemID = 0
		local ItemIDBind = 0
		local nNeed = 0
		local nCount = 0
		local nCountBind = 0
		
		local FurnitureText
		if nLevel ==  0 then
			bCanHCCount = bCanHCCount +1 
			bCanHC[bCanHCCount] = 0
		else

			FurnitureText = g_nFurnitureLeftButton[i];

			ItemIDBind = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel-1,nType,nPos,0,1) 
			ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel-1,nType,nPos,0,0) 
			nNeed = 2

			
			nCountBind = PlayerPackage:CountAvailableItemByIDTable(ItemIDBind)			
			nCount = PlayerPackage:CountAvailableItemByIDTable(ItemID)
			nCount = nCount + nCountBind
			
			
			local nname
			if g_nTableIndex == 1 then --室内页签

				for j=0,table.getn(g_FurnitureInnerType) do
					if g_FurnitureInnerType[j].Type == nType and g_FurnitureInnerType[j].Pos == nPos  then
						local mode_i = math.mod(i, 5)
						if mode_i == 0 then
						        nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(5,nType,1,0,0)
							nname = string.format("#e010101#cFDEACA%s",nname,5)
						else
							nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(mode_i,nType,1,0,0)
							nname = string.format("#e010101#cFDEACA%s",nname,mode_i)					
						end

					else
					
					end
				end	
				

				
			else 
				for j=0,table.getn(g_FurnitureOuterType) do
					if g_FurnitureOuterType[j].Type == nType and g_FurnitureOuterType[j].Pos == nPos  then
						local mode_i = math.mod(i, 5)
						if mode_i == 0 then 
						    nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(5,nType,0,0,0)
							nname = string.format("#e010101#cFDEACA%s",nname,5)
						else
			                nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(mode_i,nType,0,0,0)
							nname = string.format("#e010101#cFDEACA%s",nname,mode_i)
						end
						
					end
				end	
	
			end

			if nCount >= nNeed then 
				nname = nname.."(可合成)"
				bCanHC[bCanHCCount] = 1
			end
		
			nname = string.format("#e010101#cFDEACA%s",nname)
			FurnitureText:AddTextTextAndImage(nname,"","")			
		end
	end

	--对一级菜单进行处理 
	bCanHCCount = -1
	local nname
	for i=1,table.getn(g_nFurnitureTypeID) do
		local FurnitureCatalog
		if g_nFurnitureTypeID[i].Level == 0 then
			bCanHCCount = bCanHCCount + 1
			if bCanHC[bCanHCCount] > 0 then --可装潢
				if g_nTableIndex == 1 then --室内
					nname = g_FurnitureInnerType[bCanHCCount].Name.. "(可合成)"
				else --室外
					nname = g_FurnitureOuterType[bCanHCCount].Name.. "(可合成)"
				end
				nname = string.format("#e010101#cFDEACA%s",nname)
				g_nFurnitureLeftButton[i]:AddTextCatalogText(nname)
			else							--不可合成
				if g_nTableIndex == 1 then --室内
					nname = g_FurnitureInnerType[bCanHCCount].Name
				else --室外
					nname = g_FurnitureOuterType[bCanHCCount].Name
				end
				nname = string.format("#e010101#cFDEACA%s",nname)
				g_nFurnitureLeftButton[i]:AddTextCatalogText(nname)				
			end
		end
	end

end
function BieYeFurniture_Show()
	if g_nCurSelectListIndex >= 0 then 
		local nType = g_nFurnitureTypeID[g_nCurSelectListIndex].TypeID
		local nLevel = g_nFurnitureTypeID[g_nCurSelectListIndex].Level
		local nPos = g_nFurnitureTypeID[g_nCurSelectListIndex].Pos
		local ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,0,0) 
		if(nLevel == 0) then
			PushDebugMessage("#{JJHC_160620_186}")
			return 
		end
		if g_nCurSelectJDId > 0 then 
			PushEvent("SHOWFURNITURE",ItemID,1)		
		end
	end
end
function BieYeFurniture_ButtownShow()

	if g_nCurSelectListIndex >= 0 then 
		local nType = g_nFurnitureTypeID[g_nCurSelectListIndex].TypeID
		local nLevel = g_nFurnitureTypeID[g_nCurSelectListIndex].Level
		local nPos = g_nFurnitureTypeID[g_nCurSelectListIndex].Pos
		local ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,0,0) 
		if(nLevel == 0) then
			BieYeFurniture_Item_Frame_Button:Hide()
			return 
		end
		if g_nCurSelectJDId > 0 then 
			BieYeFurniture_Item_Frame_Button:Show()
		else
			BieYeFurniture_Item_Frame_Button:Hide()
		end
	end
end

function BieYeFurniture_OnMoved()
    if "BieYeFurniture" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
end