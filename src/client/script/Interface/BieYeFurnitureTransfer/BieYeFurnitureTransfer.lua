local BieYeFurnitureTransfer_g_FurnitureInType =
{
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

local BieYeFurnitureTransfer_g_FurnitureOutType =
{
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

local BieYeFurnitureTransfer_g_HasTable = 
{
	[0] = {},
	[1] = {}
}
local BieYeFurnitureTransfer_g_MaxType = 13
local BieYeFurnitureTransfer_g_LeftCurSelectList = 0
local BieYeFurnitureTransfer_g_RightCurSelectList = 0
local BieYeFurnitureTransfer_g_LeftLastSelectId = 0
local BieYeFurnitureTransfer_g_RightLastSetcetId = 0
local BieYeFurnitureTransfer_g_FurImage = "Ach_AchIcon_Cup"
local BieYeFurnitureTransfer_g_FurImageSet = "Ach"
--当前界面类型
local BieYeFurnitureTransfer_g_CurType = 0
local BieYeFurnitureTransfer_g_Comfirm = 1


-- 界面的默认相对位置
local g_BieYeFurnitureTransfer_Frame_UnifiedXPosition;
local g_BieYeFurnitureTransfer_Frame_UnifiedYPosition;

local BieYeFurnitureTransfer_g_AllLeftButton = {}
local BieYeFurnitureTransfer_g_AllRightButton = {}

local g_AllInFurIndex = {}
local g_AllOutFurIndex = {}
local g_AllFurData = {}
--===============================================
-- OnLoad()
--===============================================
function BieYeFurnitureTransfer_PreLoad()

	--
	this:RegisterEvent("BIEYE_OPENFURNITURE_TRANSFER")
	this:RegisterEvent("UPDATE_BIEYEFURNITURE_CK_LIST")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)



end

function BieYeFurnitureTransfer_OnLoad()


	-- 保存界面的默认相对位置
	g_BieYeFurnitureTransfer_Frame_UnifiedXPosition	= BieYeFurnitureTransfer_FrameBK : GetProperty("UnifiedXPosition");
	g_BieYeFurnitureTransfer_Frame_UnifiedYPosition	= BieYeFurnitureTransfer_FrameBK : GetProperty("UnifiedYPosition");

end


--===============================================
-- OnEvent()
--===============================================
function BieYeFurnitureTransfer_OnEvent(event)
	if ( event == "BIEYE_OPENFURNITURE_TRANSFER" or (event == "UI_COMMAND" and tonumber(arg0) == 20170329)) then	
		BieYeFurniture:AcquireListWithCangKuHC()
		if(IsWindowShow("BieYeFuniture")) then
			CloseWindow("BieYeFuniture",true)
		end
		if(IsWindowShow("BieYeWarehome")) then
			CloseWindow("BieYeWarehome",true)
		end
		if(IsWindowShow("BieYeDecoration_InBank")) then
			CloseWindow("BieYeDecoration_InBank",true)
		end
		if(IsWindowShow("BieYeFurnitureBank")) then
			CloseWindow("BieYeFurnitureBank",true)
		end
		if(IsWindowShow("BieYeFurnitureShow")) then
			CloseWindow("BieYeFurnitureShow",true)
		end
		local bIsInner = BieYeFurniture:GetCurInner() 
		if bIsInner == 1 then
			BieYeFurnitureTransfer_g_CurType = 1
		else
			BieYeFurnitureTransfer_g_CurType = 0
		end
		BieYeFurnitureTransfer_g_LeftCurSelectList = 0 
		BieYeFurnitureTransfer_g_RightCurSelectList = 0
		BieYeFurnitureTransfer_UpdateFrame()
		this:Show()
	elseif (event == "UPDATE_BIEYEFURNITURE_CK_LIST") then
		if(IsWindowShow("BieYeFurnitureTransfer")) then
			BieYeFurnitureTransfer_LoadData()
			BieYeFurnitureTransfer_UpdateFrame()
		end
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		BieYeFurnitureTransfer_Frame_OnHiden()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		BieYeFurnitureTransfer_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		BieYeFurnitureTransfer_Frame_On_ResetPos()
	end
end


--===============================================
-- OnHiden
--===============================================
function BieYeFurnitureTransfer_Frame_OnHiden()
	BieYeFurnitureTransfer_ClearAllFakeobject()
	this:Hide()
end
function BieYeFurnitureTransfer_Close()
	BieYeFurnitureTransfer_Frame_OnHiden()
end

function BieYeFurnitureTransfer_ClearAllFakeobject()
	BieYeFurnitureTransfer_Before_FakeObject:SetFakeObject("")
	BieYeFurnitureTransfer_Before_Name:SetText("")
	BieYeFurnitureTransfer_After_FakeObject:SetFakeObject("")
	BieYeFurnitureTransfer_After_Name:SetText("")
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeFurnitureTransfer_Frame_On_ResetPos()

	BieYeFurnitureTransfer_FrameBK : SetProperty("UnifiedXPosition", g_BieYeFurnitureTransfer_Frame_UnifiedXPosition);
	BieYeFurnitureTransfer_FrameBK : SetProperty("UnifiedYPosition", g_BieYeFurnitureTransfer_Frame_UnifiedYPosition);

end

function BieYeFurnitureTransfer_OnChoice(nType)
	if(nType ~= BieYeFurnitureTransfer_g_CurType) then
		BieYeFurnitureTransfer_g_CurType = nType
		BieYeFurnitureTransfer_g_LeftCurSelectList = 0 
		BieYeFurnitureTransfer_g_RightCurSelectList = 0
		BieYeFurnitureTransfer_g_LeftLastSelectId = 0
		BieYeFurnitureTransfer_g_RightLastSetcetId = 0
		BieYeFurnitureTransfer_UpdateFrame()
	end
end

function BieYeFurnitureTransfer_UpdateFrame()
	if(BieYeFurnitureTransfer_g_CurType == 0) then
		BieYeFurnitureTransfer_Button01:SetCheck(1)
	elseif (BieYeFurnitureTransfer_g_CurType == 1) then
		BieYeFurnitureTransfer_Button02:SetCheck(1)
	end
	local Confirm = tonumber(NpcShop:GetFurnitureTransferDirectly())
	if Confirm == 1 then
		BieYeFurnitureTransfer_ZidongCheckButton:SetCheck(0)
		BieYeFurnitureTransfer_g_Comfirm = 0
	else
		BieYeFurnitureTransfer_ZidongCheckButton:SetCheck(1)
		BieYeFurnitureTransfer_g_Comfirm = 1
	end
	BieYeFurnitureTransfer_ClearAllFakeobject()
	BieYeFurnitureTransfer_LoadLeft()
	local nTemp = BieYeFurnitureTransfer_GetButtonIndexById(BieYeFurnitureTransfer_g_LeftLastSelectId)
	if(nTemp ~= nil and nTemp >= 0) then
		BieYeFurnitureTransfer_SetLeftButtonSelected(nTemp,true)
	else
		BieYeFurnitureTransfer_SetLeftButtonSelected(BieYeFurnitureTransfer_g_LeftCurSelectList,true)
	end
	BieYeFurnitureTransfer_UpdateRight()
	local nTemp = BieYeFUrnitureTransfer_GetRightButtonIndexById(BieYeFurnitureTransfer_g_RightLastSetcetId)
	if(nTemp ~=nil and nTemp > 0) then
		BieYeFurnitureTransfer_SetRightListSelected(nTemp - 1,true)
	else
		BieYeFurnitureTransfer_SetRightListSelected(BieYeFurnitureTransfer_g_RightCurSelectList - 1,true)
	end
	
	
end
function BieYeFurnitureTransfer_LoadData()
	local nNum = BieYeFurniture:GetBankFurTypeNum()
	g_AllInFurIndex = {}
	g_AllOutFurIndex = {}
	g_AllFurData = {}

	for i = 1,BieYeFurnitureTransfer_g_MaxType do
		local bStop = false
		local j = 0
		while(bStop ~= true) do
			j = j + 1
			local nId,name1,TransFer,CanBeTransfer = BieYeFurniture:GetFurCanTransferInfo(0,i,0,j)
			if(nId == -1) then
				bStop = true
			else
				if(g_AllFurData[nId] == nil and (TransFer == 1 or CanBeTransfer == 1)) then
					local tp1 = {}
					tp1.name = name1
					tp1.num = 0
					tp1.nType = i
					tp1.pos = 0
					tp1.CanTransfer = TransFer
					tp1.CanBeTransfer = CanBeTransfer
					g_AllFurData[nId] = tp1
					if(g_AllOutFurIndex[i] == nil) then
						local tempList ={}
						tempList.list = {}
						tempList.name = "#e010101#cFDEACA"..BieYeFurnitureTransfer_g_FurnitureOutType[i]
						tempList.CanTransferCount = TransFer
						tempList.CanBeTransferCount = CanBeTransfer
						tempList.HasItem = 0
						tempList.ItemTypeCount = 1
						table.insert(tempList.list,nId)
						g_AllOutFurIndex[i] = tempList
					else
						g_AllOutFurIndex[i].CanTransferCount = g_AllOutFurIndex[i].CanTransferCount + TransFer
						g_AllOutFurIndex[i].CanBeTransferCount = g_AllOutFurIndex[i].CanBeTransferCount + CanBeTransfer
						g_AllOutFurIndex[i].ItemTypeCount = g_AllOutFurIndex[i].ItemTypeCount + 1
						table.insert(g_AllOutFurIndex[i].list,nId)
					end
				end
			end
		end
		bStop = false
		local j = 0
		while(bStop ~= true) do
			j = j + 1
			local nId,name1,TransFer,CanBeTransfer = BieYeFurniture:GetFurCanTransferInfo(0,i,1,j)
			if(nId == -1) then
				bStop = true
			else
				if(g_AllFurData[nId] == nil and (TransFer == 1 or CanBeTransfer == 1)) then
					local tp1 = {}
					tp1.name = name1
					tp1.num = 0
					tp1.nType = i
					tp1.pos = 1
					tp1.CanTransfer = TransFer
					tp1.CanBeTransfer = CanBeTransfer
					g_AllFurData[nId] = tp1
					if(g_AllInFurIndex[i] == nil) then
						local tempList ={}
						tempList.list = {}
						tempList.name = "#e010101#cFDEACA"..BieYeFurnitureTransfer_g_FurnitureInType[i]
						tempList.CanTransferCount = TransFer
						tempList.CanBeTransferCount = CanBeTransfer
						tempList.HasItem = 0
						tempList.ItemTypeCount = 1
						table.insert(tempList.list,nId)
						g_AllInFurIndex[i] = tempList
					else
						g_AllInFurIndex[i].CanTransferCount = g_AllInFurIndex[i].CanTransferCount + TransFer
						g_AllInFurIndex[i].CanBeTransferCount = g_AllInFurIndex[i].CanBeTransferCount + CanBeTransfer
						g_AllInFurIndex[i].ItemTypeCount = g_AllInFurIndex[i].ItemTypeCount + 1
						table.insert(g_AllInFurIndex[i].list,nId)
					end
				end
			end
		end
	end
	for i=0,nNum - 1 do
		local nIndex,_nNum  = BieYeFurniture:GetFurIDInBankByIndex(i)
		--local nPos,nType,nCanTarsfer,nCanBeTrasfer,Name = BieYeFurniture:GetFurTransferInfoById(nIndex)
		if(nIndex ~= nil and nIndex ~= -1) then
			if(g_AllFurData[nIndex] ~= nil) then
				g_AllFurData[nIndex].num = _nNum
				local pos = g_AllFurData[nIndex].pos
				local Type = g_AllFurData[nIndex].nType
				if( pos == 0 and _nNum > 0) then
					if(g_AllOutFurIndex[Type] ~= nil and 
					g_AllOutFurIndex[Type].HasItem ~= 1) then
						g_AllOutFurIndex[Type].HasItem = 1
					end
				end
				if(pos == 1 and _nNum > 0) then
					if(g_AllInFurIndex[Type] ~= nil and 
					g_AllInFurIndex[Type].HasItem ~= 1) then
						g_AllInFurIndex[Type].HasItem = 1
					end
				end
			end
		end
	end
end
function BieYeFUrnitureTransfer_UpDateOrder()
	--排序
	for i = 1,BieYeFurnitureTransfer_g_MaxType do
		BieYeFUrnitureTransfer_OrderMyLoad(g_AllOutFurIndex[i].list)
		BieYeFUrnitureTransfer_OrderMyLoad(g_AllInFurIndex[i].list)
	end
end
function BieYeFUrnitureTransfer_OrderMyLoad(list)
	if(list == nil)then
		return
	end
	local nCount = table.getn(list)
	for i = 2,nCount do
		for j = 0,nCount - i do
			local nIndex = nCount - j
			if(nIndex >=2 and list[nIndex] ~= nil and list[nIndex - 1] ~= nil and g_AllFurData[list[nIndex]] ~= nil and g_AllFurData[list[nIndex - 1]] ~= nil) then
				local num1 = g_AllFurData[list[nIndex]].num
				local num2 = g_AllFurData[list[nIndex - 1]].num
				if(num1 == nil or num2 == nil) then
					return
				end
				if(num1 > num2) then
					local temp = list[nIndex - 1]
					list[nIndex - 1] =  list[nIndex]
					list[nIndex] = temp
				end
			end
		end
	end
end
function BieYeFurnitureTransfer_LoadLeft()
	BieYeFurnitureTransfer_ListContent:CleanAllElement("BieYeFurnitureTransfer")
	BieYeFurnitureTransfer_g_HasTable[BieYeFurnitureTransfer_g_CurType] = {}
	BieYeFurnitureTransfer_g_AllLeftButton = {}
	BieYeFUrnitureTransfer_UpDateOrder()
	local bShow = 1
	local DataIndex = {}
	if(BieYeFurnitureTransfer_g_CurType == 0) then
		DataIndex = g_AllOutFurIndex
	elseif(BieYeFurnitureTransfer_g_CurType == 1) then
		DataIndex = g_AllInFurIndex
	end
	for i=1,BieYeFurnitureTransfer_g_MaxType do
		if(DataIndex[i] ~= nil and DataIndex[i].CanTransferCount >= 1) then
			local ShowName = DataIndex[i].name
			if(DataIndex[i].ItemTypeCount > 1 and DataIndex[i].CanBeTransferCount > 0 and DataIndex[i].HasItem > 0) then 
				ShowName = ShowName .. "(可转换)"
			end
			BieYeFurnitureTransfer_AddCatalog(BieYeFurnitureTransfer_g_AllLeftButton,ShowName,i)
			for j=1,table.getn(DataIndex[i].list) do
				local nId = DataIndex[i].list[j]
				if(g_AllFurData[nId] ~= nil) then
					if(g_AllFurData[nId].name == nil) then
						PushDebugMessage("出现未知错误 id="..nId)
					end
					if(g_AllFurData[nId].CanTransfer == 1) then
						local str = ScriptGlobal_Format("#{XYJJ_170216_07}",tostring(g_AllFurData[nId].name),g_AllFurData[nId].num)
						if(g_AllFurData[nId].num == 0) then
							str = "#c666666"..str
						end
						BieYeFurnitureTransfer_AddText(BieYeFurnitureTransfer_g_AllLeftButton,str,i,nId,bShow)
					end
				end
			end
			bShow = 0
		end
	end
	BieYeFurnitureTransfer_ListContent:Flash()
	BieYeFurnitureTransfer_g_LeftCurSelectList = 0
	
	--BieYeFurnitureTransfer_ListContent:SetVertScrollbarHide()
end
--增加类型控件
function BieYeFurnitureTransfer_AddCatalog(BtnList,nText,nType)
	local FurBtn = {}
	local FurnitureCatalog = BieYeFurnitureTransfer_ListContent:AddItemElement( "BieYeFurniture", "LEFT", "BieYeFurnitureTransfer","" ,"")
	FurnitureCatalog:SetProperty("AchievementWindowCatalogButtonHover","AchievementHoverSection")
	FurnitureCatalog:AddTextCatalogTextAndImage(nText,BieYeFurnitureTransfer_g_FurImage,BieYeFurnitureTransfer_g_FurImageSet)
	FurBtn.bFirstContent = 1
	FurBtn.btn = FurnitureCatalog
	FurBtn.Type = nType
	FurBtn.id = 0
	FurBtn.name = nText
	table.insert(BtnList,FurBtn)
end

--增加子类型控件
function BieYeFurnitureTransfer_AddText(BtnList,nText,nType,nId,bShow)
	local FurBtn = {}
	local szText = string.format("#e010101#cFDEACA%s", nText)
	local FurnitureText = BieYeFurnitureTransfer_ListContent:AddItemElement("BieYeFurnitureText","LEFT","BieYeFurnitureTransfer","","")
	FurnitureText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	FurnitureText:AddTextTextAndImage(szText,"","")
	FurnitureText:Hide()		--刚开始子控件不可见
	if(bShow ~= nil and bShow == 1) then
		FurnitureText:Show()
	end
	FurBtn.bFirstContent = 0
	FurBtn.Type = nType
	FurBtn.btn = FurnitureText
	FurBtn.id = nId
	FurBtn.name = szText
	table.insert(BtnList,FurBtn)
end



function BieYeFurnitureTransfer_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if CurClickIndex + 1 > 0 then
		--BieYeFurnitureTransfer_g_LeftCurSelectList =	CurClickIndex + 1
		return BieYeFurnitureTransfer_SetLeftButtonSelected(CurClickIndex + 1)		--设置选中的类型高亮
	else
		return
	end
end

function BieYeFurnitureTransfer_OnTimer(nIndex)
	local strFunc = "BieYeFurnitureTransfer_OnTimer("..nIndex..")"
	if(BieYeFurnitureTransfer_g_AllLeftButton[nIndex] ~= nil and BieYeFurnitureTransfer_g_AllLeftButton[nIndex].bFirstContent == 0) then
		BieYeFurnitureTransfer_g_AllLeftButton[nIndex].btn:SetTextCatalogSelected(false)
	end
	KillTimer(strFunc)
end
function BieYeFurnitureTransfer_SetLeftButtonSelected(nIndex,bFresh)
	if nIndex <= 0 then return end
	if(BieYeFurnitureTransfer_g_AllLeftButton[nIndex] == nil) then
		return
	end
	local nId = BieYeFurnitureTransfer_g_AllLeftButton[nIndex].id
	local num = g_AllFurData[nId].num
	if(BieYeFurnitureTransfer_g_AllLeftButton[nIndex].bFirstContent == 0 ) then
		
		if((num == nil or num == 0) and (bFresh == nil or bFresh == false)) then
			PushDebugMessage("#{XYJJ_170216_08}")
			local strFunc = "BieYeFurnitureTransfer_OnTimer("..nIndex..")"
			SetTimer("BieYeFurnitureTransfer",strFunc,20)
			return 
		end
	end
	for BtnIndex = 1,table.getn(BieYeFurnitureTransfer_g_AllLeftButton) do
		local bHigth = false
		if(BieYeFurnitureTransfer_g_AllLeftButton[BtnIndex].bFirstContent == 1) then
			if(BieYeFurnitureTransfer_g_AllLeftButton[BtnIndex].Type == BieYeFurnitureTransfer_g_AllLeftButton[nIndex].Type) then
				bHigth = true
			end
			BieYeFurnitureTransfer_g_AllLeftButton[BtnIndex].btn:SetCatalogButtonSelect(bHigth)
		else
			if(nIndex == BtnIndex and (num ~= nil and num > 0)) then
				bHigth = true
			end
			BieYeFurnitureTransfer_g_AllLeftButton[BtnIndex].btn:SetTextCatalogSelected(bHigth)
			if(BieYeFurnitureTransfer_g_AllLeftButton[BtnIndex].Type == BieYeFurnitureTransfer_g_AllLeftButton[nIndex].Type) then
				BieYeFurnitureTransfer_g_AllLeftButton[BtnIndex].btn:Show()
			else
				BieYeFurnitureTransfer_g_AllLeftButton[BtnIndex].btn:Hide()
			end
		end
	end
	BieYeFurnitureTransfer_g_LeftCurSelectList = nIndex
	BieYeFurnitureTransfer_g_LeftLastSelectId = nId
	BieYeFurnitureTransfer_ClearAllFakeobject()
	BieYeFurnitureTransfer_OnLeftButtonSelected(nIndex,bFresh)
	if(bFresh == nil or bFresh == false) then
		BieYeFurnitureTransfer_g_RightCurSelectList = 0
		BieYeFurnitureTransfer_g_RightLastSetcetId = 0
	end
	BieYeFurnitureTransfer_UpdateRight()
	BieYeFurnitureTransfer_ListContent:Flash()
end
function BieYeFurnitureTransfer_GetButtonIndexById(Id)
	if(Id == nil or Id <= 0) then
		return -1
	end
	for BtnIndex = 1,table.getn(BieYeFurnitureTransfer_g_AllLeftButton) do
		if(BieYeFurnitureTransfer_g_AllLeftButton[BtnIndex].id == Id) then
			return BtnIndex
		end
	end
	return -1
end

function BieYeFUrnitureTransfer_GetRightButtonIndexById(Id)
	if(Id == nil or Id <= 0) then
		return -1
	end
	for BtnIndex = 1,table.getn(BieYeFurnitureTransfer_g_AllRightButton) do
		if(BieYeFurnitureTransfer_g_AllRightButton[BtnIndex].id == Id) then
			return BtnIndex
		end
	end
	return -1
end

function BieYeFurnitureTransfer_OnLeftButtonSelected(nIndex,bFresh)
	local nId = BieYeFurnitureTransfer_g_AllLeftButton[nIndex].id
	local num = g_AllFurData[nId].num
	if(BieYeFurnitureTransfer_g_AllLeftButton[nIndex].id == 0) then
		return
	end
	if(num == nil or num == 0) then
		BieYeFurnitureTransfer_Before_FakeObject:SetFakeObject("")
		BieYeFurnitureTransfer_Before_Name:SetText("")
		return
	end
	BieYeFurnitureTransfer_Before_FakeObject:SetFakeObject("")
	BieYeFurniture:SetFurnitureTransferBeforeModel(BieYeFurnitureTransfer_g_AllLeftButton[nIndex].id)
	BieYeFurnitureTransfer_Before_FakeObject:SetFakeObject("BieYeFurnitureTransferBefore")
	BieYeFurnitureTransfer_Before_Name:SetText(g_AllFurData[BieYeFurnitureTransfer_g_AllLeftButton[nIndex].id].name)
	if(bFresh == nil or bFresh == false) then
		PushDebugMessage("#{XYJJ_170216_09}")
	end
end

function BieYeFurnitureTransfer_Before_TurnRight(start)
	--向右旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeFurnitureTransfer_Before_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			BieYeFurnitureTransfer_Before_FakeObject:RotateEnd();
		end
	end
end

function BieYeFurnitureTransfer_Before_TurnLeft(start)
	--向左旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeFurnitureTransfer_Before_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			BieYeFurnitureTransfer_Before_FakeObject:RotateEnd();
		end
	end
end

function BieYeFurnitureTransfer_After_TurnRight(start)
	--向右旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeFurnitureTransfer_After_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			BieYeFurnitureTransfer_After_FakeObject:RotateEnd();
		end
	end
end

function BieYeFurnitureTransfer_After_TurnLeft(start)
	--向左旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeFurnitureTransfer_After_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			BieYeFurnitureTransfer_After_FakeObject:RotateEnd();
		end
	end
end
function BieYeFurnitureTransfer_UpdateRight()
	local nIndex = BieYeFurnitureTransfer_g_LeftCurSelectList
	local nId = BieYeFurnitureTransfer_g_AllLeftButton[nIndex].id
	local num = g_AllFurData[nId].num
	if(nIndex <= 0 or BieYeFurnitureTransfer_g_AllLeftButton[nIndex].id == 0 or num == nil or num == 0) then
		BieYeFurnitureTransfer_ExFrame:Hide()
		return
	end
	BieYeFurnitureTransfer_ExFrame_List:ClearListBox()
	BieYeFurnitureTransfer_g_AllRightButton = {}
	local nType = BieYeFurnitureTransfer_g_AllLeftButton[nIndex].Type
	local TypeList = {}
	if(BieYeFurnitureTransfer_g_CurType == 0) then
		TypeList = g_AllOutFurIndex[nType]
	elseif(BieYeFurnitureTransfer_g_CurType == 1) then
		TypeList = g_AllInFurIndex[nType]
	end
	local nCount = 0
	if(TypeList ~= nil) then
		for i=1,table.getn(TypeList.list) do
			if(TypeList.list[i] ~= nId) then
				local btn = {}
				btn.id = TypeList.list[i]
				btn.name = g_AllFurData[btn.id].name
				if(g_AllFurData[btn.id].CanBeTransfer == 1) then
					table.insert(BieYeFurnitureTransfer_g_AllRightButton,btn)
					BieYeFurnitureTransfer_ExFrame_List:AddItem(btn.name, nCount)
					nCount = nCount + 1
				end
			end
		end
		BieYeFurnitureTransfer_ExFrame:Show()
	end
	--if(BieYeFurnitureTransfer_g_RightLastSetcetId <= 0) then
	--	BieYeFurnitureTransfer_SetRightListSelected(BieYeFurnitureTransfer_g_RightCurSelectList - 1,true)
	--end
end
-- function BieYeFurnitureTransfer_UpdateRight()
	-- local nIndex = BieYeFurnitureTransfer_g_LeftCurSelectList
	-- if(nIndex <= 0 or BieYeFurnitureTransfer_g_AllLeftButton[nIndex].id == 0) then
		-- BieYeFurnitureTransfer_ExFrame:Hide()
		-- return
	-- end
	-- BieYeFurnitureTransfer_ExFrame_List:ClearListBox()
	-- BieYeFurnitureTransfer_g_AllRightButton = {}
	-- local bStop = false
	-- local nCount = 0
	-- while(bStop ~= true) do
		-- nCount = nCount + 1
		-- local nId,name = BieYeFurniture:GetFurCanTransferInfo(BieYeFurnitureTransfer_g_AllLeftButton[nIndex].id,BieYeFurnitureTransfer_g_AllLeftButton[nIndex].Type,BieYeFurnitureTransfer_g_CurType,nCount)
		-- if(nId ~= -1) then
			-- local btn = {}
			-- btn.id = nId
			-- btn.name = name
			-- table.insert(BieYeFurnitureTransfer_g_AllRightButton,btn)
			-- BieYeFurnitureTransfer_ExFrame_List:AddItem(name, nCount - 1)
		-- else
			-- bStop = true
		-- end
	-- end
	-- BieYeFurnitureTransfer_ExFrame:Show()
-- end

function BieYeFurnitureTransfer_RightListSelect(bFresh)
	local nIndex = BieYeFurnitureTransfer_ExFrame_List:GetFirstSelectItem()
	if(nIndex + 1 ~= BieYeFurnitureTransfer_g_RightCurSelectList or bFresh ~= nil and bFresh == true) then
		BieYeFurnitureTransfer_g_RightCurSelectList = nIndex + 1
		BieYeFurnitureTransfer_g_RightLastSetcetId = BieYeFurnitureTransfer_g_AllRightButton[BieYeFurnitureTransfer_g_RightCurSelectList].id
		if(BieYeFurnitureTransfer_g_AllRightButton[BieYeFurnitureTransfer_g_RightCurSelectList] ~= nil) then
			BieYeFurnitureTransfer_After_FakeObject:SetFakeObject("")
			BieYeFurniture:SetFurnitureTransferAfterModel(BieYeFurnitureTransfer_g_AllRightButton[BieYeFurnitureTransfer_g_RightCurSelectList].id)
			BieYeFurnitureTransfer_After_FakeObject:SetFakeObject("BieYeFUrnitureTransferAfter")
			BieYeFurnitureTransfer_After_Name:SetText(BieYeFurnitureTransfer_g_AllRightButton[BieYeFurnitureTransfer_g_RightCurSelectList].name)
		end
	end
end

function BieYeFurnitureTransfer_SetRightListSelected(nIndex,bFresh)
	if(nIndex >=0 and nIndex < BieYeFurnitureTransfer_ExFrame_List:GetItemNumber() and BieYeFurnitureTransfer_ExFrame_List:IsVisible()) then
		BieYeFurnitureTransfer_ExFrame_List:SetItemSelect(nIndex)
		BieYeFurnitureTransfer_RightListSelect(bFresh)
	end
end

function BieYeFurnitureTransfer_OnMoved()
	return
end

function BieYeFurnitureTransfer_HeCheng()
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
	if(BieYeFurnitureTransfer_g_AllLeftButton[BieYeFurnitureTransfer_g_LeftCurSelectList] == nil
	 or BieYeFurnitureTransfer_g_AllLeftButton[BieYeFurnitureTransfer_g_LeftCurSelectList].id == 0) then
		--PushDebugMessage("select="..tostring(BieYeFurnitureTransfer_g_LeftCurSelectList))
		PushDebugMessage("#{XYJJ_170216_19}")
		return
	 end
	 
	 if(BieYeFurnitureTransfer_g_AllRightButton[BieYeFurnitureTransfer_g_RightCurSelectList] == nil 
	 or BieYeFurnitureTransfer_g_AllRightButton[BieYeFurnitureTransfer_g_RightCurSelectList].id == 0) then
		PushDebugMessage("#{XYJJ_170216_21}")
		return
	 end
	local nId = BieYeFurnitureTransfer_g_AllLeftButton[BieYeFurnitureTransfer_g_LeftCurSelectList].id
	local nNum = g_AllFurData[nId].num
	if(nNum == nil or nNum <= 0) then
		--PushDebugMessage("num = "..tostring(nNum).."  ID="..tostring(nId).."  select="..tostring(BieYeFurnitureTransfer_g_LeftCurSelectList))
		--local strTip = ScriptGlobal_Format("#{XYJJ_170216_23}",BieYeFurnitureTransfer_g_AllLeftButton[BieYeFurnitureTransfer_g_LeftCurSelectList].name)
		PushDebugMessage("#{XYJJ_170216_19}")
		return 
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("InBankFurTransfer")
		Set_XSCRIPT_ScriptID( 891837 )
		Set_XSCRIPT_Parameter(0,BieYeFurnitureTransfer_g_AllLeftButton[BieYeFurnitureTransfer_g_LeftCurSelectList].id);
		Set_XSCRIPT_Parameter(1,BieYeFurnitureTransfer_g_AllRightButton[BieYeFurnitureTransfer_g_RightCurSelectList].id);
		Set_XSCRIPT_Parameter(2,BieYeFurnitureTransfer_g_Comfirm);		
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
	BieYeFurnitureTransfer_OK:Disable()
	SetTimer("BieYeFurnitureTransfer","BieYeFurnitureTransfer_ShowButton()",2000)
end

function BieYeFurnitureTransfer_ZidongCheck_Clicked()
	local bConfirm = tonumber(NpcShop:GetFurnitureTransferDirectly())
	if ( bConfirm == 1 ) then
		BieYeFurnitureTransfer_ZidongCheckButton:SetCheck( 1 );
		NpcShop:SetFurnitureTransferDirectly( 0 );
		BieYeFurnitureTransfer_g_Comfirm = 1
	elseif ( bConfirm == 0 ) then
		BieYeFurnitureTransfer_ZidongCheckButton:SetCheck( 0 );
		NpcShop:SetFurnitureTransferDirectly( 1 );
		BieYeFurnitureTransfer_g_Comfirm = 0
	end
end
function BieYeFurnitureTransfer_ShowButton()
	KillTimer("BieYeFurnitureTransfer_ShowButton()")
	BieYeFurnitureTransfer_OK:Enable()
end