--*********************************************
--珍兽套装升级界面
--*********************************************

local PetEquipSuitUpName = "PetEquipSuitUp"
local g_PetEquipItemPos  = -1
local g_PetEquipItemID	 = -1
local g_PetEquipProductID= -1
local g_ObjCareID		 = -1
local g_ProductNeedMoney = 0
local g_PetEquipUiIndex	 = 19831204
local MAX_OBJ_DISTANCE 	 = 3.0;
local g_PetEquipFunCtrl  = -1	--功能控制
--*********************************************
--动态改变界面需要的常量
--*********************************************
--0表示为4星级装备升星界面   1表示为5星级及以上装备升星界面
local g_PetEquipUIMark	 = 1

--选择删除材料的个数
local g_PetEquipMaterialNum	 = 0
--当前的成功率值
local g_SuccessPercent 	 = -1
local g_DynamicConst1 	 = 58
local g_DynamicConst2 	 = 25


local g_PetEquipSuitUp_Frame_UnifiedPosition;

local g_PetEquipSuitUp_PB_SceneIDList = {
	70500163,
	70501163,
	70502163,
	70503163,
	70504163,
}
--**********************************************
--事件注册
--**********************************************
function PetEquipSuitUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UNIT_MONEY",false)
	this:RegisterEvent("MONEYJZ_CHANGE",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_PETEQUIP_UP") --新建一个这样的事件
	this:RegisterEvent("PACKAGE_ITEM_CHANGED")
	this:RegisterEvent("COMMON_CLIENT_MESSAGE")
	-- this:RegisterEvent("NEW_DEBUGMESSAGE")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


--**********************************************
--
--**********************************************
function PetEquipSuitUp_OnLoad()
	PetEquipSuitUp_NumberList:ComboBoxAddItem("0",0)
	PetEquipSuitUp_NumberList:ComboBoxAddItem("1",1)
	PetEquipSuitUp_NumberList:ComboBoxAddItem("2",2)
	PetEquipSuitUp_NumberList:ComboBoxAddItem("3",3)
	PetEquipSuitUp_NumberList:ComboBoxAddItem("4",4)
	PetEquipSuitUp_NumberList:ComboBoxAddItem("5",5)
	PetEquipSuitUp_NumberList:SetCurrentSelect(0)
	g_PetEquipSuitUp_Frame_UnifiedPosition=PetEquipSuitUp_Frame:GetProperty("UnifiedPosition");
end


--**********************************************
--事件响应
--**********************************************
function PetEquipSuitUp_OnEvent( event )
	if (event == "UI_COMMAND") then
		PetEquipSuitUp_UiCommand(arg0)
	elseif (event == "UNIT_MONEY") then
		PetEquipSuitUp_UnitMoney()
	elseif (event == "MONEYJZ_CHANGE") then
		PetEquipSuitUp_JZMChange()
	elseif (event == "RESUME_ENCHASE_GEM") then
		PetEquipSuitUp_GetDownItem(arg0)
	elseif (event == "OBJECT_CARED_EVENT") then
		PetEquipSuitUp_CareEvent(arg0,arg1,arg2)
	elseif (event == "UPDATE_PETEQUIP_UP") then
		PetEquipSuitUp_Update(arg0,arg1)
	elseif (event == "PACKAGE_ITEM_CHANGED") then
		PetEquipSuitUp_PackageItemChange(arg0)
	elseif (event == "COMMON_CLIENT_MESSAGE") then
		PetEquipSuitUp_CommonClientMessage(arg0)
		
	elseif (event == "ADJEST_UI_POS" ) then
		PetEquipSuitUp_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetEquipSuitUp_Frame_On_ResetPos()
	end
end


--**********************************************
--确定按钮
--**********************************************
function PetEquipSuitUp_Buttons_Clicked()
	--是否旧宠物装备正常放入
	if (g_PetEquipItemPos == -1 or g_PetEquipProductID == -1) then
		return
	end

	--放入的旧装备的Table中的ID
	if (g_PetEquipItemID == -1) then
		return
	end

	--判断物品是否加锁和足够在服务器端判断

	--判断金钱是不是够
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if (selfMoney < g_ProductNeedMoney) then
		PushDebugMessage( "没有足够的金钱，不能进行珍兽装备升级！" )
		return
	end

	local szName, nIndex  = PetEquipSuitUp_NumberList:GetCurrentSelect()
	local nSuccessPercent = g_SuccessPercent + nIndex * 15
	g_PetEquipMaterialNum = nIndex
	if ( nSuccessPercent >= 100 ) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnPetEquipSuitUp")
			Set_XSCRIPT_ScriptID(800109)
			Set_XSCRIPT_Parameter(0,g_PetEquipItemPos)
			Set_XSCRIPT_Parameter(1,g_ObjCareID)
			Set_XSCRIPT_Parameter(2,g_PetEquipMaterialNum)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
		PetEquipSuitUp_Clear()
		PetEquipSuitUp_Explain3_Text2:SetText("#cff0000"..tostring(0).."%")
		PetEquipSuitUp_SmallShow()
	else
		PetEquipSuitUp:SendSuitUpConfirm(26, g_PetEquipItemPos,
											 g_ObjCareID,
											 g_PetEquipMaterialNum,
											 nSuccessPercent)
	end
end


--*************************************************
--重置界面
--*************************************************
function PetEquipSuitUp_Clear()
	if (g_PetEquipItemPos ~= -1) then
		LifeAbility : Lock_Packet_Item(g_PetEquipItemPos,0);
	end

	PetEquipSuitUp_Accept:Disable()
	PetEquipSuitUp_GemItem:SetActionItem(-1)
	PetEquipSuitUp_ProductItem:SetActionItem(-1)
	PetEquipSuitUp_ProductItem:Hide();
	PetEquipSuitUp_Explain2_Info:SetText("#{ZSZBSJ_XML_05}")
	PetEquipSuitUp_Explain4:SetText("#{ZSZBSJ_XML_03}")
	PetEquipSuitUp_Demand_Jiaozi:SetProperty("MoneyNumber", "")
	PetEquipSuitUp_Explain3_Text2:SetText("")
	g_PetEquipItemPos  = -1
	g_PetEquipItemID   = -1
	g_PetEquipProductID= -1
	g_ProductNeedMoney = 0
end

--*************************************************
--处理UI_COMMAND逻辑
--*************************************************
function PetEquipSuitUp_UiCommand(arg0)

	--检查是否呼叫该界面
	local nUiIdx = tonumber(arg0)
	if (nUiIdx ~= g_PetEquipUiIndex) then
		return
	end

	--关心当前对话的NPC
	local targetId = Get_XParam_INT(0)
	g_ObjCareID = DataPool:GetNPCIDByServerID(targetId);
	if (g_ObjCareID == -1) then
		PushDebugMessage("server传过来的数据有问题。");
		return
	end
	PetEquipSuitUp_UnitMoney()
	PetEquipSuitUp_JZMChange()
	
	--获取是那个分支功能的控制符
	--1 为珍兽装备升星功能
	g_PetEquipFunCtrl = Get_XParam_INT(1)

	PetEquipSuitUp_BeginCareObject()
	PetEquipSuitUp_Clear()

  	PetEquipSuitUp_SmallShow()
	this:Show();
end

--*************************************************
--处理UNIT_MONEY逻辑
--*************************************************
function PetEquipSuitUp_UnitMoney()
	PetEquipSuitUp_Currently_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
end

--*************************************************
--处理MONEYJZ_CHANGE逻辑
--*************************************************
function PetEquipSuitUp_JZMChange()
	PetEquipSuitUp_Currently_Jiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
end

--*************************************************
--处理RESUME_ENCHASE_GEM逻辑
--*************************************************
function PetEquipSuitUp_Resume_Equip(Index)
	if (Index == nil) then
		return
	end

	if (Index < 0 or Index > 5) then
		return
	end

	if (Index == 0) then
		LifeAbility:Lock_Packet_Item(g_PetEquipItemPos, 0)
		PetEquipSuitUp_GemItem:SetActionItem(-1)
		g_PetEquipItemPos=-1
		PetEquipSuitUp_Clear()
		PetEquipSuitUp_ProductItem:SetActionItem(-1)
		g_PetEquipProductID=-1
		PetEquipSuitUp_Demand_Jiaozi:SetProperty("MoneyNumber", "")
		PetEquipSuitUp_Accept:Disable()
		--显示4星界面
		PetEquipSuitUp_SmallShow()
		return
	end
end

--*************************************************
--处理OBJECT_CARED_EVENT逻辑
--*************************************************
function PetEquipSuitUp_CareEvent(arg0,arg1,arg2)
	local ObjCaredID = tonumber(arg0)
	if( ObjCaredID ~= g_ObjCareID) then
		return
	end

	local ObjDistance = tonumber(arg2)
	if( (arg1 == "distance" and ObjDistance>MAX_OBJ_DISTANCE) or arg1=="destroy") then
		PetEquipSuitUp_Close()
	end
end

--*************************************************
--处理UPDATE_PETEQUIP_UP逻辑 界面更新
--*************************************************
function PetEquipSuitUp_Update( pos_ui, pos_packet )
	if (pos_packet == nil) then
		return
	end

	local BagPos = tonumber(pos_packet)
	local UiPos  = tonumber(pos_ui)

	--deleted by guochenshu for TT:66411
	--是否加锁....
	--if (PlayerPackage:IsLock(BagPos) == 1) then
	--	PushDebugMessage("#{Item_Locked}")
	--	return
	--end

	local theAction = EnumAction(UiPos, "packageitem")
	if (theAction == 0) then
		return
	end

	local ItemID = PlayerPackage:GetItemTableIndex(BagPos)
	local nClass = math.floor(ItemID/10000000)

	--珍兽装备
	if (nClass == 7) then
		local nRet = PetEquipSuitUp_5DownUpdate(BagPos)
		if (nRet == 0) then
			return
		end

		local nIs5LevelUp = PetEquipSuitUp:GetPetEquip5LevelupMark(ItemID)
		--放入界面的装备是5星以下的装备
		if (nIs5LevelUp <= 6) then
			if (g_PetEquipUIMark == 1) then
				--改变成5星以下界面
				PetEquipSuitUp_SmallShow()
			end
		elseif(nIs5LevelUp > 6 ) then
			if (g_PetEquipUIMark == 0) then
				--改变成5星以上界面
				PetEquipSuitUp_BigShow()
			end
		else
			return
		end
	end
end


--*************************************************
--处理PACKAGE_ITEM_CHANGED逻辑
--*************************************************
function PetEquipSuitUp_PackageItemChange(arg0)
	if (this:IsVisible() == 0) then
		return
	end

	if (arg0 == nil) then
		return
	end

	local NumArg0 = tonumber(arg0)
	if (-1 == NumArg0) then
		return
	end

	if (g_PetEquipItemPos == NumArg0) then
		PetEquipSuitUp_Resume_Equip(0)
	end
end

--*************************************************
--开始关心NPC，就是确认玩家当前操作的NPC，如果离NPC
--太远就会关闭窗口在开始关心之前需要先确定这个界面
--是不是已经有“关心”的NPC，如果有的话，先取消已经
--有的“关心”
--*************************************************
function PetEquipSuitUp_BeginCareObject()
	this:CareObject(g_ObjCareID, 1, "PetEquipSuitUp");
end


--*************************************************
--停止对某NPC的关心
--*************************************************
function PetEquipSuitUp_StopCareObject()
	this:CareObject(g_ObjCareID, 0, "PetEquipSuitUp");
end

--*************************************************
--关闭界面
--*************************************************
function PetEquipSuitUp_Close()
	this:Hide()
	PetEquipSuitUp_StopCareObject()
	PetEquipSuitUp_Clear()
end

--*************************************************
--关闭界面
--*************************************************
function PetEquipSuitUp_OnHide()
	PetEquipSuitUp_Close()
end

--*************************************************
--动态显示增加的部分
--*************************************************
function PetEquipSuitUp_BigShow()

	if (g_PetEquipUIMark == 0) then
	 	local nSuitUpFramHeightOld = PetEquipSuitUp_Frame:GetProperty("AbsoluteHeight")
	 	local nFunctionFramHeightOld = PetEquipSuitUp_Function_Frame:GetProperty("AbsoluteHeight")
		local nExplain3PosY  = PetEquipSuitUp_Explain3:GetProperty("AbsoluteYPosition")
		local nExplain2PosY  = PetEquipSuitUp_Explain2_Bk:GetProperty("AbsoluteYPosition")

		--设置窗口大小，各个控件位置
		PetEquipSuitUp_Frame:SetProperty("AbsoluteHeight", nSuitUpFramHeightOld+g_DynamicConst1)
		PetEquipSuitUp_Function_Frame:SetProperty("AbsoluteHeight", nFunctionFramHeightOld+g_DynamicConst1)

		PetEquipSuitUp_Explain3:SetProperty("AbsoluteYPosition", nExplain3PosY+g_DynamicConst2)
		PetEquipSuitUp_Explain2_Bk:SetProperty("AbsoluteYPosition", nExplain2PosY+g_DynamicConst1)
		PetEquipSuitUp_5LevelUiShow()
		PetEquipSuitUp_NumberList:SetCurrentSelect(0)
	end
	g_PetEquipUIMark = 1
end

--*************************************************
--动态隐藏增加的部分
--*************************************************
function PetEquipSuitUp_SmallShow()
	if (g_PetEquipUIMark == 1) then
	 	local nSuitUpFramHeightOld = PetEquipSuitUp_Frame:GetProperty("AbsoluteHeight")
	 	local nFunctionFramHeightOld = PetEquipSuitUp_Function_Frame:GetProperty("AbsoluteHeight")
		local nExplain3PosY  = PetEquipSuitUp_Explain3:GetProperty("AbsoluteYPosition")
		local nExplain2PosY  = PetEquipSuitUp_Explain2_Bk:GetProperty("AbsoluteYPosition")

		--设置窗口大小，各个控件位置
		PetEquipSuitUp_Frame:SetProperty("AbsoluteHeight", nSuitUpFramHeightOld-g_DynamicConst1)
		PetEquipSuitUp_Function_Frame:SetProperty("AbsoluteHeight", nFunctionFramHeightOld-g_DynamicConst1)

		PetEquipSuitUp_Explain3:SetProperty("AbsoluteYPosition", nExplain3PosY-g_DynamicConst2)
		PetEquipSuitUp_Explain2_Bk:SetProperty("AbsoluteYPosition", nExplain2PosY-g_DynamicConst1)
		PetEquipSuitUp_NumberList:SetCurrentSelect(0)
		PetEquipSuitUp_5LevelUiHide()
	end
	g_PetEquipUIMark = 0
end


--*************************************************
--5星及以上装备升星时，需要显示材料框（圣兽牙）
--*************************************************
function PetEquipSuitUp_5LevelUiShow()
	PetEquipSuitUp_Explain5:Show()
	PetEquipSuitUp_Explain6:Show()
	PetEquipSuitUp_NumberList:Show()
end

--*************************************************
--5星及以上装备升星时，需要隐藏材料框（圣兽牙）
--*************************************************
function PetEquipSuitUp_5LevelUiHide()
	PetEquipSuitUp_Explain5:Hide()
	PetEquipSuitUp_Explain6:Hide()
	PetEquipSuitUp_NumberList:Hide()
end


--*************************************************
--珍兽装备放入界面处理UPDATE_PETEQUIP_UP逻辑 界面更新
--*************************************************
function PetEquipSuitUp_5DownUpdate( BagPos )
	if (BagPos == nil or BagPos == -1) then
		return 0
	end

	local ItemID = PlayerPackage:GetItemTableIndex(BagPos)
	--通过表获取生成物品ID、需要金钱数目、升级几率、材料种类
	local nProductID,nPercent,nNeedMoney,nMaterialKind, strImpact= PetEquipSuitUp:GetPetEquipUpProductInfo(ItemID, 0) --debug

	local equip_id_ret = PetEquipSuitUp_IsSpecial_Equip_ID(ItemID)
	if equip_id_ret == 1 then
		PushDebugMessage("#{MDZB_260625_01}")
		return 0		
	end

	if (-1 == nProductID) then
		PushDebugMessage("#{ZSZBSJ_090706_03}")
		return 0
	end

	--更新需求物品格的Action....
	local theAction = EnumAction(BagPos, "packageitem");
	if (theAction:GetID() == 0) then
		return 0
	end

	if (g_PetEquipItemPos ~= -1) then
		LifeAbility:Lock_Packet_Item(g_PetEquipItemPos, 0)
	end
	LifeAbility:Lock_Packet_Item(BagPos, 1)
	PetEquipSuitUp_GemItem:SetActionItem(theAction:GetID())

	g_PetEquipItemPos=BagPos
	--更新生成物品的Action
	g_PetEquipItemID	= ItemID
	g_PetEquipProductID = nProductID
	g_ProductNeedMoney  = nNeedMoney
	g_SuccessPercent 	= nPercent

	PetEquipSuitUp_Explain4:SetText("#{ZSZBSJ_XML_04}")
	local ProductAction = PetEquipSuitUp:UpdateProductAction(nProductID,BagPos) --debug
	if (ProductAction and ProductAction:GetID() ~= 0) then
		PetEquipSuitUp_ProductItem:SetActionItem(ProductAction:GetID());
		PetEquipSuitUp_ProductItem:Show()
	else
		PetEquipSuitUp_ProductItem:SetActionItem(-1)
	end

	--更新需要金钱数目
	PetEquipSuitUp_Demand_Jiaozi:SetProperty("MoneyNumber", tostring(g_ProductNeedMoney))
	if (nPercent < 100) then
		PetEquipSuitUp_Explain3_Text2:SetText("#cff0000"..tostring(nPercent).."%")
	else
		nPercent = 100
		PetEquipSuitUp_Explain3_Text2:SetText("#G"..tostring(nPercent).."%")
	end

	--根据Table中的ID获取所需要的材料
	local nMaterial = {
					  [1] = {id=0,num=0,name="",},
					  [2] = {id=0,num=0,name="",},
					  [3] = {id=0,num=0,name="",},
					  }
	local szTipInfo = "#{ZSZBSJ_XML_06}"
	if (nMaterialKind > 0) then
		for i=1,nMaterialKind do
			nMaterial[i].id,nMaterial[i].num,nMaterial[i].name = PetEquipSuitUp:GetPetEquipUpMaterial(g_PetEquipItemID, 0, i) --debug
			if (-1 ~= nMaterial[i].id) then
				szTipInfo = szTipInfo..nMaterial[i].name.."#G"..nMaterial[i].num.."#cfff263个；"
			end
		end

		if (strImpact ~= nil) then
			szTipInfo = szTipInfo.."\n"..strImpact
		end

		PetEquipSuitUp_Explain2_Info:SetText(szTipInfo)
	end

	local nMaxCount = PetEquipSuitUp_MaxCount(nPercent)
	if (nMaxCount > 0) then
		PetEquipSuitUp_NumberList:ResetList()
		for i=0, nMaxCount do
			PetEquipSuitUp_NumberList:ComboBoxAddItem(tostring(i),i)
		end
	end

	PetEquipSuitUp_NumberList:SetCurrentSelect(0)
	PetEquipSuitUp_Accept:Enable()
	return 1
end


--*************************************************
--找到放入第几个圣兽牙后，成功率为100%
--*************************************************
function PetEquipSuitUp_FindCriticalValue(nPercent)
	for i=1,5 do
		local nTmp = nPercent + i * 15
		if (nTmp >=100) then
			return i
		end
	end
	return 5
end


--*************************************************
--取下界面中的珍兽装备
--*************************************************
function PetEquipSuitUp_GetDownItem(arg0)
	if (arg0 == nil) then
		return
	end

	--取下界面上的装备
	local nIndex = tonumber(arg0)
	PetEquipSuitUp_Resume_Equip(nIndex)
end

--*************************************************
--下拉列表框中选择的数字改变
--*************************************************
function PetEquipSuitUp_ComboListProvinceChanged(nIndex)
	local szName, nIndex = PetEquipSuitUp_NumberList:GetCurrentSelect()
	if (nIndex == 0) then
		PetEquipSuitUp_Explain3_Text2:SetText("#cff0000"..tostring(g_SuccessPercent).."%")
		return
	end

	if (nIndex < 1 or nIndex > 5) then
		return
	end

	if (g_SuccessPercent == -1) then
		return
	end

	local nCriticalValue  = PetEquipSuitUp_FindCriticalValue(g_SuccessPercent)
	if (nCriticalValue == 0) then
		return
	end

	if (nCriticalValue < nIndex) then
		PetEquipSuitUp_NumberList:SetCurrentSelect(0)
		PetEquipSuitUp_Explain3_Text2:SetText("#cff0000"..tostring(g_SuccessPercent).."%")
		PushDebugMessage("#{ZSZB_100510_1}")
	else
		local nPercent = g_SuccessPercent + nIndex * 15
		if (nPercent < 100) then
			PetEquipSuitUp_Explain3_Text2:SetText("#cff0000"..tostring(nPercent).."%")
		else
			PetEquipSuitUp_Explain3_Text2:SetText("#G"..tostring(nPercent).."%")
		end
	end
end


--*************************************************
--根据百分比设定圣兽牙的最大数目
--*************************************************
function PetEquipSuitUp_MaxCount(nPercent)

	local nRet = 0
	local nCount = 100 - nPercent
	if (nCount > 0) then
		nRet = math.ceil(nCount/15)
	end

	if (nRet > 0) then
		return nRet
	end
	return 0
end


function PetEquipSuitUp_CommonClientMessage(arg0)
	if (tonumber(arg0) == 20100524) then
		PetEquipSuitUp_NumberList:SetCurrentSelect(0)
	end
end

function PetEquipSuitUp_Frame_On_ResetPos()
  PetEquipSuitUp_Frame:SetProperty("UnifiedPosition", g_PetEquipSuitUp_Frame_UnifiedPosition);
end

function PetEquipSuitUp_IsSpecial_Equip_ID( nOldID )
	--检查这件物品是否为特殊套装的类型
	for i = 1,table.getn(g_PetEquipSuitUp_PB_SceneIDList) , 1 do
		if nOldID == g_PetEquipSuitUp_PB_SceneIDList[i] then
			return 1
		end
	end
	return 0
end

