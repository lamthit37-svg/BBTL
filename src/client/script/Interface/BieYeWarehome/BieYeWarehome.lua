local g_BieYeWarehome_Frame_UnifiedXPosition;
local g_BieYeWarehome_Frame_UnifiedYPosition;
local g_FurnitureListImage = "Ach_AchIcon_Cup"
local g_FurnitureListImageSet = "Ach"
local g_Bag_Index_Item = -1
local g_nFurnitureLeftButton = {}			--左侧列表
local g_nFurnitureTypeID = {}			--家具ID
local g_FurnitureListScrollbarPos = 0.0
local g_nCurSelectListIndex = 1	--当前选中的列表项
local g_nCurSelectMBF = 0
local g_nCurSelectJDId = 0
local g_nSecType = 1  --家具绑定二次确认
local g_level = 50
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
--local g_nFurnitureConfirm = 0  --家具合成确认

function BieYeWarehome_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_BIEYEHC_CANGKU")
	this:RegisterEvent("UPDATE_FURNITUREBAG_SEC")	
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("SHOWFURNITURE_CKHC");
	this:RegisterEvent("SCENE_DATA_READY");	
	this:RegisterEvent("UPDATE_BIEYEFURNITURE_CK_LIST");	
	this:RegisterEvent("BIEYE_OPEN_FURNITURE_BANK");		
end

function BieYeWarehome_OnLoad()
	-- 保存界面的默认相对位置
	g_BieYeWarehome_Frame_UnifiedXPosition	= BieYeWarehomeFrame : GetProperty("UnifiedXPosition");
	g_BieYeWarehome_Frame_UnifiedYPosition	= BieYeWarehomeFrame : GetProperty("UnifiedYPosition");
end		
		
				
function BieYeWarehome_OnEvent(event)


	if event == "MONEY_CHANGE_EX" and this:IsVisible() then
			BieYeWarehome_UpdateMoneyDisp()
	elseif event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
			BieYeWarehome_UpdateMoneyDisp()
	elseif event == "UPDATE_BIEYEHC_CANGKU" and this:IsVisible() then
		if arg0~= nil then
			--BieYeWarehome_UpdateMBF(arg0)
		end
	elseif event == "BIEYE_OPEN_FURNITURE_BANK" and this:IsVisible() then
		if tonumber(arg0) == 0 then 		
			BieYeWarehome_Close()
		end
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then
		local nType = Get_XParam_INT(0)
		
		if nType == 30 then --打开界面
			BieYeWarehome_Close()
		end

		if nType == 28 then --用了免爆符，合成失败 需要刷新界面
			BieYeWarehome_UpdateMoneyDisp()
			BieYeWarehome_IconUpdate()
			g_nSecType = 0
			BieYeWarehome_OK_Enable()	

		end
	
	elseif event == "SCENE_DATA_READY" then
		if ( BieYeFurniture:IsBieYeScene() == false ) then
			this:Hide()
		end
	elseif event == "UPDATE_BIEYEFURNITURE_CK_LIST" then
			BieYeWarehome_UpdateMoneyDisp()
			BieYeWarehome_IconUpdate()

			g_nSecType = 0
			
			BieYeWarehome_OK_Enable()
			BieYeWarehome_Fresh()
	elseif event == "SHOWFURNITURE_CKHC" then

			BieYeFurniture:AcquireListWithCangKuHC()
			if(IsWindowShow("BieYeDecoration")) then
				CloseWindow("BieYeDecoration",true)
			end
			if(IsWindowShow("BieYeFurniture")) then
				CloseWindow("BieYeFurniture",true)
			end
			this:Show()	
			
			local posX, posY = Player:GetPos();
			--local bIsInner = BieYeUI:GetBieYeAreaType(posX,posY)
			local bIsInner = BieYeFurniture:GetCurInner() 
			if bIsInner == 1 then
				g_nTableIndex = 1
			else
				g_nTableIndex = 0
			end

			if g_nTableIndex == 0 then
					BieYeWarehome_Button01:SetCheck(1)
					BieYeWarehome_Button02:SetCheck(0)
			else 
					BieYeWarehome_Button01:SetCheck(0)
					BieYeWarehome_Button02:SetCheck(1)
			end

			BieYeWarehome_Title:SetText("#{JJHC_160620_67}")
			BieYeWarehome_Explain:SetText("#{JJHC_160620_68}")
			--BieYeWarehome_Check:SetCheck(1)
			--g_nFurnitureConfirm = 1
			BieYeWarehome_LeftLoad()
			BieYeWarehome_UpdateMoneyDisp()
			BieYeWarehome_SetLeftButtonSelected(1)		--设置选中的类型高亮
			BieYeWarehome_ShowIcon(1)
			g_nSecType = 0
			

			BieYeWarehome_ButtownShow()	
	elseif event == "UPDATE_FURNITUREBAG_SEC" then
		local nType = tonumber(arg0)
		if nType == 1 then
			g_nSecType = 1
		elseif nType == 2 then	
			g_nSecType = 1		
		end
		
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeWarehome_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化		
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		BieYeWarehome_Frame_On_ResetPos();
	end
end
		
--更新主界面位置
function BieYeWarehome_Frame_On_ResetPos()

	BieYeWarehomeFrame : SetProperty("UnifiedXPosition", g_BieYeWarehome_Frame_UnifiedXPosition);
	BieYeWarehomeFrame : SetProperty("UnifiedYPosition", g_BieYeWarehome_Frame_UnifiedYPosition);

end

--左侧家具类型加载		
function BieYeWarehome_LeftLoad()
		BieYeWarehome_ListContent:CleanAllElement("BieYeWarehome")
		BieYeWarehome_ListContent:SetVertScrollbarHide()
		g_nFurnitureLeftButton = {}
		g_nFurnitureTypeID = {}
		if g_nTableIndex == 0 then
			for i=0,table.getn(g_FurnitureOuterType) do

				BieYeWarehome_AddCatalog("#e010101#cFDEACA"..g_FurnitureOuterType[i].Name)
				BieYeWarehome_AddID(i*5,0,g_FurnitureOuterType[i].Type,g_FurnitureOuterType[i].Pos)
				
				for j=1,4 do
					local nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(j+1,g_FurnitureOuterType[i].Type,0,0,0)
				    nname = string.format("#e010101#cFDEACA%s",nname)
					BieYeWarehome_AddText(nname)
					BieYeWarehome_AddID(i*5+j,j+1,g_FurnitureOuterType[i].Type,g_FurnitureOuterType[i].Pos)	
				end			
			end
		end

		if g_nTableIndex == 1 then
			for i=0,table.getn(g_FurnitureInnerType) do

				BieYeWarehome_AddCatalog("#e010101#cFDEACA"..g_FurnitureInnerType[i].Name)
				BieYeWarehome_AddID(i*5,0,g_FurnitureInnerType[i].Type,g_FurnitureInnerType[i].Pos)
				
				for j=1,4 do
					local nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(j+1,g_FurnitureInnerType[i].Type,1,0,0)
				    nname = string.format("#e010101#cFDEACA%s",nname)
					BieYeWarehome_AddText(nname)
					BieYeWarehome_AddID(i*5+j,j+1,g_FurnitureInnerType[i].Type,g_FurnitureInnerType[i].Pos)	
				end			
			end			
		end

		
		BieYeWarehome_ListContent:SetVertScrollbarPosition(g_FurnitureListScrollbarPos)
		BieYeWarehome_ListContent:SetVertScrollbarHide()
		BieYeWarehome_ListContent:Flash()		
end
		
function BieYeWarehome_Close()
	BieYeWarehome_ListContent:CleanAllElement("BieYeWarehome")
	BieYeWarehome_ListContent:SetVertScrollbarHide()
	--BieYeWarehome_ListContent:SetVertScrollbarHide()
	g_nFurnitureLeftButton = {}
	g_nFurnitureTypeID = {}	
	BieYeWarehome_Resume(0)
	this:Hide()
end


--增加类型控件
function BieYeWarehome_AddCatalog(nText)
	local FurnitureCatalog = BieYeWarehome_ListContent:AddItemElement( "BieYeFurniture", "LEFT", "BieYeWarehome","" ,"")
	FurnitureCatalog:SetProperty("AchievementWindowCatalogButtonHover","AchievementHoverSection")
	FurnitureCatalog:AddTextCatalogTextAndImage(nText,g_FurnitureListImage,g_FurnitureListImageSet)
	table.insert(g_nFurnitureLeftButton,FurnitureCatalog)
end

--增加子类型控件
function BieYeWarehome_AddText(nText)
	local FurnitureText = BieYeWarehome_ListContent:AddItemElement("BieYeFurnitureText","LEFT","BieYeWarehome","","")
	FurnitureText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	FurnitureText:AddTextTextAndImage(nText,"","")
	FurnitureText:Hide()		--刚开始子控件不可见
	table.insert(g_nFurnitureLeftButton,FurnitureText)
end

--增加类型ID和子类型ID数据
function BieYeWarehome_AddID(num,Level,TypeID,nPos)
	local nItem = {}
	nItem.num = num
	nItem.Level = Level
	nItem.TypeID = TypeID
	nItem.Pos = nPos
	table.insert(g_nFurnitureTypeID,nItem)
end

--点击左侧选项
function BieYeWarehome_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if CurClickIndex + 1 > 0 and CurClickIndex + 1~=g_nCurSelectListIndex then
		BieYeWarehome_Resume(0)
		g_nCurSelectMBF = 0
		g_nCurSelectListIndex =	CurClickIndex + 1
		BieYeWarehome_SetLeftButtonSelected(g_nCurSelectListIndex)		--设置选中的类型高亮
		BieYeWarehome_ShowIcon(g_nCurSelectListIndex)	
		BieYeWarehome_ButtownShow()	
		BieYeWarehome_UpdateMoneyDisp()
	else
		return
	end
end


--设置左侧列表中选中的目录
function BieYeWarehome_SetLeftButtonSelected(nIndex)
	
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
	BieYeWarehome_ListContent:SetVertScrollbarHide()
	BieYeWarehome_ListContent:Flash()
end

--显示图标
function BieYeWarehome_ShowIcon(nIndex)
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
		BieYeWarehome_Item:SetActionItem(-1);
		BieYeWarehome1_Item:SetActionItem(-1);
--		BieYeWarehome1_Item1:SetActionItem(-1);
		BieYeWarehome1_Amount:SetText("")
--		BieYeWarehome1_Amount1:SetText("")
		g_nCurSelectJDId = 0
		return
	end
	
	BieYeWarehome1_Amount:SetText("")
--	BieYeWarehome1_Amount1:SetText("")
--	BieYeWarehome1_Amount1:SetProperty("Visible","False")
	
	local ItemID_up = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,0,0)
	DataPool:Lua_SetBieYeOperateActionItem(2,ItemID_up);
	DataPool:Lua_UpdateBieYeOperateActionItem()
	local theAction_Up = EnumAction(2, "bieye_operate");
	if theAction_Up:GetID() ~= 0 then	
		BieYeWarehome_Item:SetActionItem(theAction_Up:GetID());
	end		
	
	
	
	local ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel-1,nType,nPos,0,0)
		
	DataPool:Lua_SetBieYeOperateActionItem(0,ItemID);
	DataPool:Lua_UpdateBieYeOperateActionItem()
	
	local theAction2 = EnumAction(0, "bieye_operate");

	if theAction2:GetID() ~= 0 then	
		local ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel-1,nType,nPos,0,1)
		g_nCurSelectJDId = ItemID
		BieYeWarehome1_Item:SetActionItem(theAction2:GetID());

		local itemcount = BieYeFurniture:GetFurCntInCangkuHC(ItemID)


		if  itemcount == 0 then
			BieYeWarehome1_Amount:SetText("#W#e0000010")	
		elseif itemcount < 2 then
			BieYeWarehome1_Amount:SetText("#W#e000001"..itemcount)	
		else
			BieYeWarehome1_Amount:SetText("#W#e000001"..itemcount)
		end
	end		
end

--更新金钱 
function BieYeWarehome_UpdateMoneyDisp()
	
	
		if g_nCurSelectListIndex >= 0 then 
			local nType = g_nFurnitureTypeID[g_nCurSelectListIndex].TypeID
			local nLevel = g_nFurnitureTypeID[g_nCurSelectListIndex].Level

			if(nLevel == 0 or nLevel == nil or nLevel == '') then
				BieYeWarehome_DemandMoney:SetProperty("MoneyNumber", 0);
				return 
			end
			
			local nPos = g_nFurnitureTypeID[g_nCurSelectListIndex].Pos

			if g_nCurSelectJDId > 0 then 
				BieYeWarehome_DemandMoney:SetProperty("MoneyNumber", g_CostMoney[nLevel]);
			else
				BieYeWarehome_DemandMoney:SetProperty("MoneyNumber", 0);
			end
		end
		
		local playerMoney = Player:GetData("MONEY");
		local playerMoneyJZ = Player:GetData("MONEY_JZ");
		BieYeWarehome_DemandMoney:SetProperty("MoneyNumber", g_CostMoney);
		BieYeWarehome_CurrentlyJiaozi:SetProperty("MoneyNumber", playerMoneyJZ);
		BieYeWarehome_CurrentlyMoney:SetProperty("MoneyNumber", playerMoney);
	
end

--[[--免爆符拖拽更新
function BieYeWarehome_UpdateMBF(Item_index)	

	local i_index = tonumber(Item_index)
	local ItemID = PlayerPackage : GetItemTableIndex( i_index )
	


	if ItemID > 0 then
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

		BieYeWarehome_Resume(1)
		
		g_nCurSelectMBF = ItemID
		
		DataPool:Lua_SetBieYeOperateActionItem(1,ItemID);
		DataPool:Lua_UpdateBieYeOperateActionItem()
		local theAction = EnumAction(1, "bieye_operate");
		
--		BieYeWarehome1_Item1:SetActionItem(theAction:GetID());
		g_Bag_Index = i_index
		LifeAbility : Lock_Packet_Item(i_index,1)	
	
		local itemcount = PlayerPackage:GetBagItemNum(g_Bag_Index)
		--local itemcount = PlayerPackage:CountAvailableItemByIDTable(ItemID)
--[[		if itemcount < 1 then
			BieYeWarehome1_Amount1:SetText(itemcount)	
			BieYeWarehome1_Amount1:SetProperty("Visible","False")
		else
			BieYeWarehome1_Amount1:SetText(itemcount)
			BieYeWarehome1_Amount1:SetProperty("Visible","True")
		end--]]
	end
end--]]


function BieYeWarehome_Resume(MBF)
	if g_Bag_Index ~= -1 then
		LifeAbility : Lock_Packet_Item(g_Bag_Index,0);
	end
	BieYeWarehome_OK_Enable()
	g_Bag_Index = -1
--	BieYeWarehome1_Item1:SetActionItem(-1);
--	BieYeWarehome1_Amount1:SetText("")
--	BieYeWarehome1_Amount1:SetProperty("Visible","False")

	if MBF == 0 then
		g_nCurSelectListIndex = 1
		if g_Bag_Index_Item ~= -1 then
			LifeAbility : Lock_Packet_Item(g_Bag_Index_Item,0);	
			g_Bag_Index_Item = -1			
		end
	end

end

function BieYeWarehome_HeCheng()

    --- 角色当前等级需大于等于50级；
    local level = Player : GetData( "LEVEL" )
    if level < g_level then
        PushDebugMessage( "#{ZZJHK_130319_3}" ) 
        return 0
    end

	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{KPWFS_131112_20}")
		return
	end
    --- 角色当前未处于全沉迷或半沉迷状态；
    if IsInFatigueState() <= 0 then
        PushDebugMessage( "#{FCMX_90609_22}" )
		return 0
    end
	--local tmpItem = BieYeWarehome1_Item1:GetActionItem();
	local tmpItem = PlayerPackage:GetBagItemNum(g_Bag_Index)
	if tmpItem <= 0 then
		g_nCurSelectMBF = 0
		g_Bag_Index = -1
	end
	
	if g_nCurSelectJDId <= 0 then
		PushDebugMessage("#{JJHC_160620_43}")
		return 0
	end

	
	local itemcount = BieYeFurniture:GetFurCntInCangkuHC(g_nCurSelectJDId)
	if itemcount >= 2 then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "InCangkuOnCompound" )
		Set_XSCRIPT_ScriptID( 891837 )
		Set_XSCRIPT_Parameter(0,g_nCurSelectJDId);
		Set_XSCRIPT_Parameter(1,g_Bag_Index);
		Set_XSCRIPT_Parameter(2,0);
		Set_XSCRIPT_Parameter(3,1);			
		Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
		
		BieYeWarehome_OK:Disable()
	
		SetTimer("BieYeWarehome","BieYeWarehome_OK_Enable()", 2000)		


	else
		local JDID = BieYeUI:GetFurnitureNeedHeChengFurnitureIDByFurnitureID(g_nCurSelectJDId)
		local highname = BieYeFurniture:GetFurNameByFurnitureID(g_nCurSelectJDId)
		local name = BieYeFurniture:GetFurNameByFurnitureID(JDID)
		
		local strTemp = ScriptGlobal_Format("#{JJHC_160620_71}",highname,name)
		PushDebugMessage(strTemp)
	end

		
end

function BieYeWarehome_OK_Enable()
	KillTimer("BieYeWarehome_OK_Enable()")
	BieYeWarehome_OK:Enable()
end

function BieYeWarehome_IconUpdate()
	
		if g_nCurSelectJDId > 0 then 
			local itemcount1 = BieYeFurniture:GetFurCntInCangkuHC(g_nCurSelectJDId)
			if itemcount1 == 0 then
				BieYeWarehome1_Amount:SetText("#W#e0000010")	
			elseif itemcount1 < 2 then
				BieYeWarehome1_Amount:SetText("#W#e000001"..itemcount1)	
			
			else
				BieYeWarehome1_Amount:SetText("#W#e000001"..itemcount1)
			end	
			
			--local nTableIndex = PlayerPackage : GetItemTableIndex( g_Bag_Index ) 	
			local itemcount2 = PlayerPackage:GetBagItemNum(g_Bag_Index)
			--local itemcount2 = PlayerPackage:CountAvailableItemByIDTable(g_nCurSelectMBF)

			if itemcount2 < 1 then
				g_Bag_Index = -1
				g_nCurSelectMBF = 0
				--BieYeWarehome1_Amount1:SetText(itemcount2)	
				--BieYeWarehome1_Amount1:SetProperty("Visible","False")
--				BieYeWarehome1_Item1:SetActionItem(-1);
			else

				--BieYeWarehome1_Amount1:SetText(itemcount2)
				--BieYeWarehome1_Amount1:SetProperty("Visible","True")
			end
		end
end


function BieYeWarehome_ConfirmClick()
--[[	local bConfirm = BieYeWarehome_Check:GetCheck();
	if ( bConfirm == 1 ) then
		g_nFurnitureConfirm = 1
	elseif ( bConfirm == 0 ) then
		g_nFurnitureConfirm = 0
	end--]]
end

function BieYeWarehome_OnChoice(index)

	BieYeWarehome_ListContent:CleanAllElement("BieYeWarehome")
	BieYeWarehome_ListContent:SetVertScrollbarHide()
	g_nFurnitureLeftButton = {}
	g_nFurnitureTypeID = {}	
	BieYeWarehome_Resume(0)

	g_nTableIndex = index
	if g_nTableIndex == 0 then
			BieYeWarehome_Button01:SetCheck(1)
			BieYeWarehome_Button02:SetCheck(0)
	else 
			BieYeWarehome_Button01:SetCheck(0)
			BieYeWarehome_Button02:SetCheck(1)
	end
	
	if(IsWindowShow("BieYeDecoration")) then
		CloseWindow("BieYeDecoration",true)
	end
	if(IsWindowShow("BieYeFurniture")) then
		CloseWindow("BieYeFurniture",true)
	end
	
	BieYeWarehome_Title:SetText("#{JJHC_160620_67}")
	BieYeWarehome_Explain:SetText("#{JJHC_160620_68}")

	
	BieYeWarehome_LeftLoad()
	
	BieYeWarehome_UpdateMoneyDisp()
	
	BieYeWarehome_SetLeftButtonSelected(1)		--设置选中的类型高亮
	
	BieYeWarehome_ShowIcon(1)
	g_nSecType = 0
	

	
	this:Show()	
	
	
	--BieYeWarehome_Check:SetCheck(1)
	--g_nFurnitureConfirm = 1
	BieYeWarehome_Fresh()
	BieYeWarehome_ButtownShow()
end
function BieYeWarehome_OnHiden()
	BieYeWarehome_Close()
	
end


--显示文字更改
function BieYeWarehome_Fresh()

	local bCanHC = {}
	local bCanHCCount = -1
	
	--对二级菜单进行处理
	for i=1,table.getn(g_nFurnitureTypeID) do
		local num = g_nFurnitureTypeID[i].num
		local nType = g_nFurnitureTypeID[i].TypeID
		local nPos = g_nFurnitureTypeID[i].Pos				
		local nLevel = g_nFurnitureTypeID[i].Level
		local ItemID = 0

		local nNeed = 0
		local nCount = 0

		local FurnitureText
		if nLevel ==  0 then
			bCanHCCount = bCanHCCount +1 
			bCanHC[bCanHCCount] = 0
		else

			FurnitureText = g_nFurnitureLeftButton[i];


			ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel-1,nType,nPos,0,1) 
			nNeed = 2

			nCount = BieYeFurniture:GetFurCntInCangkuHC(ItemID)
			
			local nname
			if g_nTableIndex == 1 then --室内页签

				for j=0,table.getn(g_FurnitureInnerType) do
					if g_FurnitureInnerType[j].Type == nType and g_FurnitureInnerType[j].Pos == nPos  then
						local mode_i = math.mod(i, 5)
						if mode_i == 0 then
							nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(5,g_FurnitureInnerType[j].Type,1,0,0)
							nname = string.format("#e010101#cFDEACA%s",nname)
						else
							nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(mode_i,g_FurnitureInnerType[j].Type,1,0,0)
							nname = string.format("#e010101#cFDEACA%s",nname)					
						end
					end
				end	
				

				
			else 
				for j=0,table.getn(g_FurnitureOuterType) do
					if g_FurnitureOuterType[j].Type == nType and g_FurnitureOuterType[j].Pos == nPos  then
						local mode_i = math.mod(i, 5)
						if mode_i == 0 then 
						    nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(5,g_FurnitureOuterType[j].Type,0,0,0)
							nname = string.format("#e010101#cFDEACA%s",nname)
						else
							nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(mode_i,g_FurnitureOuterType[j].Type,0,0,0)
							nname = string.format("#e010101#cFDEACA%s",nname)	
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

function BieYeWarehome_Show()

	if g_nCurSelectJDId > 0 then 

		local CurJDID = BieYeUI:GetFurnitureNeedHeChengFurnitureIDByFurnitureID(g_nCurSelectJDId)
		PushEvent("SHOWFURNITURE",CurJDID,1)		
	else
		PushDebugMessage("#{JJHC_160620_189}")
	end
end
function BieYeWarehome_ButtownShow()

	if g_nCurSelectJDId > 0 then
		BieYeWarehome_Item_Frame_Button:Show()
	else
		BieYeWarehome_Item_Frame_Button:Hide()
	end

end

function BieYeWarehome_OneKey_HeCheng()

	local tmpItem = PlayerPackage:GetBagItemNum(g_Bag_Index)
	if tmpItem <= 0 then
		g_nCurSelectMBF = 0
		g_Bag_Index = -1
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnInBankOneKeyCompound" )
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