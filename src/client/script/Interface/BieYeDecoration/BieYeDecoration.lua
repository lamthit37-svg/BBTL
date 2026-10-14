local g_BieYeDecoration_Frame_UnifiedXPosition;
local g_BieYeDecoration_Frame_UnifiedYPosition;
local g_FurnitureListImage = "Ach_AchIcon_Cup"
local g_FurnitureListImageSet = "Ach"

local g_nFurnitureLeftButton = {}			--左侧列表
local g_nFurnitureTypeID = {}			--家具ID
local g_FurnitureListScrollbarPos = 0.0
local g_nCurSelectListIndex = 1	--当前选中的列表项
local g_nCurSelectMBF = 0
local g_nCurSelectJDId = 0
local g_nCurSelectJDIdBind = 0
local g_nCurSelectJDIdXiYou = 0
local g_HC_Gain_NPCID = -1
local g_BIEYE_OBJ_DISTANCE = 3.0
local g_nSecType = 1  --家具绑定二次确认
local g_nTableIndex = 0
local g_nFurnitureConfirm = 1  --家具合成确认
local g_FurnitureInnerType =
{
	[0] = {Name="床帐"  ,Pos=1 ,Type=1},
	[1] = {Name="桌"    ,Pos=1 ,Type=2},
	[2] = {Name="条案"  ,Pos=1 ,Type=3},
	[3] = {Name="茶几"  ,Pos=1 ,Type=4},
	[4] = {Name="椅"    ,Pos=1 ,Type=5},
	[5] = {Name="凳"    ,Pos=1 ,Type=6},
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
	[0] = {ID=38001858,isBind=0},
	[1] = {ID=38001828,isBind=1},

}
local g_InnerType =
{
	[0]  = {Name="皇室风格"      ,Pos=0 ,nQuality=1},
--	[1]  = {Name="欧式院桌"      ,Pos=0 ,nQuality=2},
--	[2]  = {Name="沙漠风格"      ,Pos=0 ,nQuality=3},
--	[3]  = {Name="简约风格"      ,Pos=0 ,nQuality=4},
}
local g_OuterType =
{
	[0]  = {Name="皇室风格"      ,Pos=1 ,nQuality=1},
--	[1]  = {Name="欧式院桌"      ,Pos=1 ,nQuality=2},
--	[2]  = {Name="沙漠风格"      ,Pos=1 ,nQuality=3},
--	[3]  = {Name="简约风格"      ,Pos=1 ,nQuality=4},
}
local g_FurnitureMaxLevel = 5    --家具最高等级5
local g_CostMoney = 200000 --装潢需要花费的金钱

function BieYeDecoration_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_DECORATION_BAG")
	this:RegisterEvent("UPDATE_FURNITUREBAG_SEC")	
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("BIEYE_OPEN_FURNITURE_BANK")
end


function BieYeDecoration_OnLoad()
	-- 保存界面的默认相对位置
	g_BieYeDecoration_Frame_UnifiedXPosition	= BieYeDecorationFrame : GetProperty("UnifiedXPosition");
	g_BieYeDecoration_Frame_UnifiedYPosition	= BieYeDecorationFrame : GetProperty("UnifiedYPosition");
end		
		
		
				
function BieYeDecoration_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 20160707 then
		
		--if(IsWindowShow("BieYeDecorationBank")) then
		--  	PushEvent("BIEYE_OPEN_MINI")
		--end
		local nType = Get_XParam_INT(0)
		
		if nType == 0 then --打开界面
			PushEvent( "BIEYEFURNITUREBANKHIDE" )
			if(IsWindowShow("BieYeFuniture")) then
				CloseWindow("BieYeFuniture",true)
			end
			if(IsWindowShow("BieYeWarehome")) then
				CloseWindow("BieYeWarehome",true)
			end
			this:Show()	
			g_nTableIndex = 0
			BieYeDecoration_Button01:SetCheck(1)
			BieYeDecoration_Button02:SetCheck(0)

			BieYeDecoration_Title:SetText("#{JJHC_160620_77}")
			BieYeDecoration_Explain:SetText("#{JJHC_160620_121}")


			BieYeDecoration_LeftLoad()
			BieYeDecoration_UpdateMoneyDisp()
			BieYeDecoration_SetLeftButtonSelected(1)		--设置选中的类型高亮
			BieYeDecoration_ShowIcon(1)
			g_nSecType = 0
			local Confirm = tonumber(NpcShop:GetFurnitureComfirmDirectly())
			if Confirm ==1 then 
				g_nFurnitureConfirm = 0
				BieYeDecoration2_Check:SetCheck(0)
			else
				g_nFurnitureConfirm = 1
				BieYeDecoration2_Check:SetCheck(1)		
			end

			------------------------------------------------
			local npcObjID = Get_XParam_INT(1)	;
			BieYeDecoration_BeginCareObject( npcObjID )	
			------------------------------------------------
			BieYeDecoration_ButtownShow()
			------------------------------------------------
		elseif nType == 1 then --更新界面
			BieYeDecoration_UpdateMoneyDisp()
			BieYeDecoration_IconUpdate()
			g_nSecType = 0
		end
		BieYeDecoration_Fresh()
	elseif event == "MONEY_CHANGE_EX" and this:IsVisible() then
			BieYeDecoration_UpdateMoneyDisp()
	elseif (event == "BIEYE_OPEN_FURNITURE_BANK") and this:IsVisible() then
		if tonumber(arg0) == 0 then 
			BieYeDecoration_Close()
		end
	elseif (event == "UI_COMMAND") and tonumber(arg0) == 20160620 then
		local nType = Get_XParam_INT(0)
		
		if nType == 30 then --打开界面
			BieYeDecoration_Close()
		end
	
	elseif event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
			BieYeDecoration_UpdateMoneyDisp()
	elseif event == "UPDATE_DECORATION_BAG" and this:IsVisible() then

	elseif ( event == "OBJECT_CARED_EVENT" and this : IsVisible() ) then
        if( tonumber(arg0) ~= g_HC_Gain_NPCID ) then
			return
		end
       	--- 如果和NPC的距离大于一定的距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > g_BIEYE_OBJ_DISTANCE or arg1=="destroy") then
					BieYeDecoration_Close()
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
		BieYeDecoration_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化		
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		BieYeDecoration_Frame_On_ResetPos();

	end
end
--更新主界面位置
function BieYeDecoration_Frame_On_ResetPos()

	BieYeDecorationFrame : SetProperty("UnifiedXPosition", g_BieYeDecoration_Frame_UnifiedXPosition);
	BieYeDecorationFrame : SetProperty("UnifiedYPosition", g_BieYeDecoration_Frame_UnifiedYPosition);

end		
--左侧家具类型加载		
function BieYeDecoration_LeftLoad()
		BieYeDecoration_ListContent:CleanAllElement("BieYeDecoration")
		--BieYeDecoration_ListContent:SetVertScrollbarHide()
		g_nFurnitureLeftButton = {}
		g_nFurnitureTypeID = {}
		if g_nTableIndex == 0 then
			for i=0,table.getn(g_FurnitureOuterType) do

				BieYeDecoration_AddCatalog("#e010101#cFDEACA"..g_FurnitureOuterType[i].Name)
				BieYeDecoration_AddID(i*5,5,g_FurnitureOuterType[i].Type,g_FurnitureOuterType[i].Pos,0)
				local nXiYouCount = BieYeFurniture:GetFurTypeCntQulityInTbl(5,g_FurnitureOuterType[i].Type,g_FurnitureOuterType[i].Pos,0)
				for j=1,nXiYouCount  do
					local nQuality =  BieYeFurniture:GetFurQulityInTbl(5,g_FurnitureOuterType[i].Type,g_FurnitureOuterType[i].Pos,0,j)
					local nName =  BieYeFurniture:GetFurNamenTbl(5,g_FurnitureOuterType[i].Type,g_FurnitureOuterType[i].Pos,0,j)
					local nname = string.format("#e010101#cFDEACA%s",nName)
					BieYeDecoration_AddText(nname)
					BieYeDecoration_AddID(i*5+j,5,g_FurnitureOuterType[i].Type,g_FurnitureOuterType[i].Pos,nQuality)
				end			
			end
		end

		if g_nTableIndex == 1 then
			for i=0,table.getn(g_FurnitureInnerType) do

				BieYeDecoration_AddCatalog("#e010101#cFDEACA"..g_FurnitureInnerType[i].Name)
				BieYeDecoration_AddID(i*5,5,g_FurnitureInnerType[i].Type,g_FurnitureInnerType[i].Pos,0)
				local nXiYouCount = BieYeFurniture:GetFurTypeCntQulityInTbl(5,g_FurnitureInnerType[i].Type,g_FurnitureInnerType[i].Pos,0)

				for j=1,nXiYouCount do
					local nQuality =  BieYeFurniture:GetFurQulityInTbl(5,g_FurnitureInnerType[i].Type,g_FurnitureInnerType[i].Pos,0,j)
					local nName =  BieYeFurniture:GetFurNamenTbl(5,g_FurnitureInnerType[i].Type,g_FurnitureInnerType[i].Pos,0,j)				
					local nname = string.format("#e010101#cFDEACA%s",nName)
					BieYeDecoration_AddText(nname)
					BieYeDecoration_AddID(i*5+j,5,g_FurnitureInnerType[i].Type,g_FurnitureInnerType[i].Pos,nQuality)
				end			
			end			
		end

		
		BieYeDecoration_ListContent:SetVertScrollbarPosition(g_FurnitureListScrollbarPos)
		--BieYeDecoration_ListContent:SetVertScrollbarHide()
		BieYeDecoration_ListContent:Flash()		
end
		
function BieYeDecoration_Close()
	BieYeDecoration_ListContent:CleanAllElement("BieYeDecoration")
	--BieYeDecoration_ListContent:SetVertScrollbarHide()
	--BieYeDecoration_ListContent:SetVertScrollbarHide()
	g_nFurnitureLeftButton = {}
	g_nFurnitureTypeID = {}	
	BieYeDecoration_Resume(0)
	this:Hide()
end


--增加类型控件
function BieYeDecoration_AddCatalog(nText)
	local FurnitureCatalog = BieYeDecoration_ListContent:AddItemElement( "BieYeFurniture", "LEFT", "BieYeDecoration","" ,"")
	FurnitureCatalog:SetProperty("AchievementWindowCatalogButtonHover","AchievementHoverSection")
	FurnitureCatalog:AddTextCatalogTextAndImage(nText,g_FurnitureListImage,g_FurnitureListImageSet)
	table.insert(g_nFurnitureLeftButton,FurnitureCatalog)
end

--增加子类型控件
function BieYeDecoration_AddText(nText)
	local FurnitureText = BieYeDecoration_ListContent:AddItemElement("BieYeFurnitureText","LEFT","BieYeDecoration","","")
	FurnitureText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	FurnitureText:AddTextTextAndImage(nText,"","")
	FurnitureText:Hide()		--刚开始子控件不可见
	table.insert(g_nFurnitureLeftButton,FurnitureText)
end

--增加类型ID和子类型ID数据
function BieYeDecoration_AddID(num,Level,TypeID,nPos,nQuality)
	local nItem = {}
	nItem.num = num
	nItem.Level = Level
	nItem.TypeID = TypeID
	nItem.Pos = nPos
	nItem.nQuality = nQuality
	table.insert(g_nFurnitureTypeID,nItem)
end

--点击左侧选项
function BieYeDecoration_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if CurClickIndex + 1 > 0 and CurClickIndex + 1~=g_nCurSelectListIndex then
		BieYeDecoration_Resume(0)
		g_nCurSelectMBF = 0 -- 点击了左面的 就需要更新下免爆符的初始状态
		g_nCurSelectListIndex =	CurClickIndex + 1
		BieYeDecoration_SetLeftButtonSelected(g_nCurSelectListIndex)		--设置选中的类型高亮
		BieYeDecoration_ShowIcon(g_nCurSelectListIndex)		
		BieYeDecoration_ButtownShow()
	else
		return
	end
end


--设置左侧列表中选中的目录
function BieYeDecoration_SetLeftButtonSelected(nIndex)
	
	if nIndex <= 0 then return end
	for BtnIndex = 0,table.getn(g_nFurnitureLeftButton) do
		if nil ~= g_nFurnitureTypeID[BtnIndex] and nil ~= g_nFurnitureLeftButton[BtnIndex] then
			if g_nFurnitureTypeID[BtnIndex].nQuality == 0 then		--如果是一级目录
				if g_nFurnitureTypeID[nIndex].TypeID == g_nFurnitureTypeID[BtnIndex].TypeID and g_nFurnitureTypeID[nIndex].Pos == g_nFurnitureTypeID[BtnIndex].Pos then
					g_nFurnitureLeftButton[BtnIndex]:SetCatalogButtonSelect(true);
				else
					g_nFurnitureLeftButton[BtnIndex]:SetCatalogButtonSelect(false);
				end
			elseif g_nFurnitureTypeID[BtnIndex].nQuality > 0 then	--如果是二级目录
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
	--BieYeDecoration_ListContent:SetVertScrollbarHide()
	BieYeDecoration_ListContent:Flash()
end

--显示图标
function BieYeDecoration_ShowIcon(nIndex)
	if nIndex <= 0 then 
		return 
	end
	if nil == g_nFurnitureTypeID[nIndex] then
		return
	end

	local nLevel = g_nFurnitureTypeID[nIndex].Level
	local nType = g_nFurnitureTypeID[nIndex].TypeID
	local nPos = g_nFurnitureTypeID[nIndex].Pos
	local nQuality = g_nFurnitureTypeID[nIndex].nQuality
	
	if nQuality == 0 then
		BieYeDecoration1_Item:SetActionItem(-1);
		BieYeDecoration1_Item1:SetActionItem(-1);
		BieYeDecoration1_Item2:SetActionItem(-1);
		BieYeDecoration1_Item3:SetText("");
		BieYeDecoration1_Amount1:SetText("")
		BieYeDecoration1_Amount2:SetText("")
		g_nCurSelectJDId = 0
		g_nCurSelectJDIdBind = 0
		g_nCurSelectJDIdXiYou = 0
		return
	end
	
	--BieYeDecoration1_Amount:SetText("")
	--BieYeDecoration1_Amount1:SetText("")
	--BieYeDecoration1_Amount1:SetProperty("Visible","False")
	
	local ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,nQuality,0)

	local ItemID1 = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,0,0)
	local ItemID1Bind = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,0,1)

	-------------	
	DataPool:Lua_SetBieYeOperateActionItem(0,ItemID);
	DataPool:Lua_UpdateBieYeOperateActionItem()
	local theAction2 = EnumAction(0, "bieye_operate");
	if theAction2:GetID() ~= 0 then	
		g_nCurSelectJDIdXiYou = ItemID
		BieYeDecoration1_Item:SetActionItem(theAction2:GetID());
	end	
	-------------
	
	

		
	DataPool:Lua_SetBieYeOperateActionItem(1,ItemID1);
	DataPool:Lua_UpdateBieYeOperateActionItem()
	local theAction3 = EnumAction(1, "bieye_operate");
	if theAction3:GetID() ~= 0 then	
		g_nCurSelectJDId = ItemID1
		g_nCurSelectJDIdBind = ItemID1Bind
		BieYeDecoration1_Item1:SetActionItem(theAction3:GetID());
		local itemcount = PlayerPackage:CountAvailableItemByIDTable(ItemID1)
		local itemcountBind = PlayerPackage:CountAvailableItemByIDTable(ItemID1Bind)
		itemcount = itemcount + itemcountBind
		if itemcount == 0 then
			BieYeDecoration1_Amount1:SetText("#W#e0000010")				
		elseif itemcount < 2 then
			BieYeDecoration1_Amount1:SetText("#W#e000001"..itemcount)	
		else
			BieYeDecoration1_Amount1:SetText("#W#e000001"..itemcount)
		end
	end	
	-------------	
			

	local ZHFcount = 0
	----加锁、蒙红

	for BtnIndex = 0,table.getn(g_FurnitureMBF) do

		local itemcount = PlayerPackage:CountAvailableItemByIDTable(g_FurnitureMBF[BtnIndex].ID)
		ZHFcount = ZHFcount + itemcount
	end
	
	if ZHFcount == 0 then
		BieYeDecoration1_Amount2:SetText("#W#e0000010")				
	elseif ZHFcount < 2 then
		BieYeDecoration1_Amount2:SetText("#W#e000001"..ZHFcount)	
	else
		BieYeDecoration1_Amount2:SetText("#W#e000001"..ZHFcount)
	end	
	
	if ZHFcount >= 0 then
		DataPool:Lua_SetBieYeOperateActionItem(2,g_FurnitureMBF[0].ID);
		DataPool:Lua_UpdateBieYeOperateActionItem()	
		local theAction1 = EnumAction(2, "bieye_operate");
		BieYeDecoration1_Item2:SetActionItem(theAction1:GetID());
	end

	local nCost= BieYeUI:GetFurnitureCostZH(ItemID)
	local strCount = ScriptGlobal_Format("#{JJHC_160620_180}", nCost)
	
	BieYeDecoration1_Item3:SetText(strCount)

end

--更新金钱 
function BieYeDecoration_UpdateMoneyDisp()
		local playerMoney = Player:GetData("MONEY");
		local playerMoneyJZ = Player:GetData("MONEY_JZ");
		BieYeDecoration_DemandMoney:SetProperty("MoneyNumber", g_CostMoney);
		BieYeDecoration_CurrentlyJiaozi:SetProperty("MoneyNumber", playerMoneyJZ);
		BieYeDecoration_CurrentlyMoney:SetProperty("MoneyNumber", playerMoney);
end


function BieYeDecoration_Resume(MBF)


	BieYeDecoration1_Item2:SetActionItem(-1);
	BieYeDecoration1_Amount2:SetText("")
	--BieYeDecoration1_Amount1:SetProperty("Visible","False")
		
	if MBF == 0 then
		g_nCurSelectListIndex = 1
	end

end

function BieYeDecoration_HeCheng()

	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnDecoration" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_Parameter(0,g_nCurSelectJDIdXiYou);
			Set_XSCRIPT_Parameter(1,g_nCurSelectJDId);		
			Set_XSCRIPT_Parameter(2,g_nCurSelectJDIdBind);		
			Set_XSCRIPT_Parameter(3,0);
			Set_XSCRIPT_Parameter(4,0);
			Set_XSCRIPT_Parameter(5,g_nFurnitureConfirm);	
			Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()
end

function BieYeDecoration_IconUpdate()
	
	--BieYeDecoration1_Amount:SetText("")
	--BieYeDecoration1_Amount1:SetText("")
	--BieYeDecoration1_Amount1:SetProperty("Visible","False")
		----加锁、蒙红


	
	DataPool:Lua_SetBieYeOperateActionItem(1,g_nCurSelectJDId);
	DataPool:Lua_UpdateBieYeOperateActionItem()
	local theAction3 = EnumAction(1, "bieye_operate");
	if theAction3:GetID() ~= 0 then	
		BieYeDecoration1_Item1:SetActionItem(theAction3:GetID());
		local itemcount = PlayerPackage:CountAvailableItemByIDTable(g_nCurSelectJDId)
		local itemcountBind = PlayerPackage:CountAvailableItemByIDTable(g_nCurSelectJDIdBind)
		itemcount = itemcount + itemcountBind
		if itemcount == 0 then
			BieYeDecoration1_Amount1:SetText("#W#e0000010")				
		elseif itemcount < 2 then
			BieYeDecoration1_Amount1:SetText("#W#e000001"..itemcount)	
		else
			BieYeDecoration1_Amount1:SetText("#W#e000001"..itemcount)
		end
	end	
	-------------	
	

	
	

	----加锁、蒙红
	local nZHFCount = 0
	for BtnIndex = 0,table.getn(g_FurnitureMBF) do

		local itemcount = PlayerPackage:CountAvailableItemByIDTable(g_FurnitureMBF[BtnIndex].ID)
		nZHFCount = nZHFCount + itemcount
	end	
	
	if nZHFCount == 0 then
		BieYeDecoration1_Amount2:SetText("#W#e0000010")				
	elseif nZHFCount < 2 then
		BieYeDecoration1_Amount2:SetText("#W#e000001"..nZHFCount)	
	else
		BieYeDecoration1_Amount2:SetText("#W#e000001"..nZHFCount)
	end	

	if nZHFCount >= 0 then
		DataPool:Lua_SetBieYeOperateActionItem(2,g_FurnitureMBF[0].ID);
		DataPool:Lua_UpdateBieYeOperateActionItem()	
		local theAction1 = EnumAction(2, "bieye_operate");
		BieYeDecoration1_Item2:SetActionItem(theAction1:GetID());
	end	
	


end



function BieYeDecoration_BeginCareObject( careObjID )
    g_HC_Gain_NPCID = DataPool : GetNPCIDByServerID( careObjID )
    if -1 == g_HC_Gain_NPCID then
        return 
    end
    this:CareObject( g_HC_Gain_NPCID, 1, "BieYeDecoration" )
end
function BieYeDecoration_EndCareObject( careObjID )
	if g_HC_Gain_NPCID ~= nil and g_HC_Gain_NPCID >= 0 then
        this:CareObject( g_HC_Gain_NPCID, 0, "BieYeDecoration" )
    end
    g_HC_Gain_NPCID = -1
end
function BieYeDecoration_OnChoice(index)

	BieYeDecoration_ListContent:CleanAllElement("BieYeDecoration")
	--BieYeDecoration_ListContent:SetVertScrollbarHide()
	--BieYeDecoration_ListContent:SetVertScrollbarHide()
	g_nFurnitureLeftButton = {}
	g_nFurnitureTypeID = {}	
	BieYeDecoration_Resume(0)


	g_nTableIndex = index
	if g_nTableIndex == 0 then
			BieYeDecoration_Button01:SetCheck(1)
			BieYeDecoration_Button02:SetCheck(0)
	else 
			BieYeDecoration_Button01:SetCheck(0)
			BieYeDecoration_Button02:SetCheck(1)
	end
	
	if(IsWindowShow("BieYeFurniture")) then
		CloseWindow("BieYeFurniture",true)
	end
	if(IsWindowShow("BieYeWarehome")) then
		CloseWindow("BieYeWarehome",true)
	end
	
	BieYeDecoration_Title:SetText("#{JJHC_160620_77}")
	BieYeDecoration_Explain:SetText("#{JJHC_160620_121}")

	
	BieYeDecoration_LeftLoad()
	
	BieYeDecoration_UpdateMoneyDisp()
	
	BieYeDecoration_SetLeftButtonSelected(1)		--设置选中的类型高亮
	
	BieYeDecoration_ShowIcon(1)
	g_nSecType = 0
	
	------------------------------------------------
	local npcObjID = Get_XParam_INT(1)	;
	BieYeDecoration_BeginCareObject( npcObjID )	
	------------------------------------------------
	
	this:Show()	
	
	
	local confirm = tonumber(NpcShop:GetFurnitureComfirmDirectly())
	if confirm ==1 then 
		g_nFurnitureConfirm = 0
		BieYeDecoration2_Check:SetCheck(0)
	else
		BieYeDecoration2_Check:SetCheck(1)			
		g_nFurnitureConfirm = 1
	end

	BieYeDecoration_Fresh()
	BieYeDecoration_ButtownShow()	
end
function BieYeDecoration_OnHiden()
	BieYeDecoration_Close()
	
end

--显示文字更改
function BieYeDecoration_Fresh()

	local bCanHC = {}
	local bCanHCCount = -1
	

	--对二级菜单进行处理
	for i=1,table.getn(g_nFurnitureTypeID) do
		local num = g_nFurnitureTypeID[i].num
		local nType = g_nFurnitureTypeID[i].TypeID
		local nPos = g_nFurnitureTypeID[i].Pos				
		local nLevel = g_nFurnitureTypeID[i].Level
		local nQuality = g_nFurnitureTypeID[i].nQuality		
		local ItemID = 0
		local ItemIDBind = 0
		local nNeed = 0
		local nCount = 0
		local nCountBind = 0
		
		local FurnitureText
		if nQuality == 0 then
			bCanHCCount = bCanHCCount +1 
			bCanHC[bCanHCCount] = 0
		else

			FurnitureText = g_nFurnitureLeftButton[i];

			ItemIDBind = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,0,1) --5级家具ID
			ItemID = BieYeUI:GetFurnitureIDByTypePosAndQuality(nLevel,nType,nPos,0,0) --5级家具ID
			nNeed = BieYeUI:GetFurnitureNeedByTypePosAndQuality(nLevel,nType,nPos,nQuality,1) --需要的5级家具数量
			
			nCountBind = PlayerPackage:CountAvailableItemByIDTable(ItemIDBind)			
			nCount = PlayerPackage:CountAvailableItemByIDTable(ItemID)
			nCount = nCount + nCountBind

			local nname
			if g_nTableIndex == 1 then --室内页签
					nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(5,nType,1,0,nQuality)
			else 
					nname = BieYeFurniture:GetFurNameByLevelAndTypeTbl(5,nType,0,0,nQuality)
			end
			if nCount >= nNeed then 
				nname = nname.."(可装潢)"
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
		if g_nFurnitureTypeID[i].nQuality == 0 then
			bCanHCCount = bCanHCCount + 1
			if bCanHC[bCanHCCount] > 0 then --可装潢
				if g_nTableIndex == 1 then --室内
					nname = g_FurnitureInnerType[bCanHCCount].Name.. "(可装潢)"
				else --室外
					nname = g_FurnitureOuterType[bCanHCCount].Name.. "(可装潢)"
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

function BieYeDecoration_ConfirmClick()
	local bConfirm = tonumber(NpcShop:GetFurnitureComfirmDirectly())
	if ( bConfirm == 1 ) then
		BieYeDecoration2_Check:SetCheck( 1 );
		NpcShop:SetFurnitureComfirmDirectly( 0 );
		g_nFurnitureConfirm = 1
	elseif ( bConfirm == 0 ) then
		BieYeDecoration2_Check:SetCheck( 0 );
		NpcShop:SetFurnitureComfirmDirectly( 1 );
		g_nFurnitureConfirm = 0
		
	end
end

function BieYeDecoration_Show()
	if g_nCurSelectJDIdXiYou > 0 then 
		PushEvent("SHOWFURNITURE",g_nCurSelectJDIdXiYou,1)		
	else
		PushDebugMessage("#{JJHC_160620_195}")
	end
end
function BieYeDecoration_ButtownShow()

	if g_nCurSelectJDIdXiYou > 0 then
		BieYeDecoration1_Item_Frame_Button:Show()
	else
		BieYeDecoration1_Item_Frame_Button:Hide()
	end
end