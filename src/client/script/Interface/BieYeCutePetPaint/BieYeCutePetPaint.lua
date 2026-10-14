local BieYeCutePetPaint_g_MengChongOutType =
{
	[1] = "狸花猫",
	[2] = "暹罗猫",
	[3] = "布偶猫",
}
local BieYeCutePetPaint_g_ColorLevel =
{
	[1] = "【普通】",	--
	[2] = "【普通】",
	[3] = "【高级】",
	[4] = "【稀有】",
}
local BieYeCutePetPaint_g_Color =
{
	[1] = "#G",
	[2] = "#G",
	[3] = "#B", 
	[4] = "#cff33cc",
}
local BieYeCutePetPaint_g_MaxType = 3 
local BieYeCutePetPaint_g_LeftLastSelectId = 0 
local BieYeCutePetPaint_g_DeleteMCID =0;
local BieYeCutePetPaint_g_AddMCID =0;
local BieYeCutePetPaint_g_DescMCID = 0
local g_serverNpcId = -1;
local BieYeCutePetPaint_g_FurImage = "Ach_AchIcon_Cup"
local BieYeCutePetPaint_g_FurImageSet = "Ach"
local BieYeCutePetPaint_g_Comfirm = 1
local	g_ZiDongState  =0
local g_NeedMoney = 50000
local g_ItemPos = -1;
local MAX_OBJ_DISTANCE = 3.0
-- 界面的默认相对位置
local g_BieYeCutePetPaint_Frame_UnifiedXPosition;
local g_BieYeCutePetPaint_Frame_UnifiedYPosition;
local g_BieYeCutePetPaint_objCared;
local BieYeCutePetPaint_g_AllLeftButton = {}
local g_ChoiceData ={}
local g_AllOutMengChongIndex = {}
local g_AllMengChongData = {}
local g_RareColorComfirm = 0;
local g_BieYeCutePetPaint_ColorItem = 38002091;
local g_TimeClick = 0;	--上次点击时间
local g_BieYeCutePetPaint_YuanbaoPay = 1;
g_BieYePet_Paint_Buy = -1;
local g_BieYeCutePetPaint_AnyRare =0;
--===============================================
-- OnLoad()
--===============================================
function BieYeCutePetPaint_PreLoad()

	this:RegisterEvent("UPDATE_BIEYECUTEPET_LIST")
	this:RegisterEvent( "MONEY_CHANGE_EX", false )
	this:RegisterEvent( "MONEYJZ_CHANGE_EX", false )
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)			-- 关心 NPC 的存在和范围
end

function BieYeCutePetPaint_OnLoad()
	-- 保存界面的默认相对位置
	g_BieYeCutePetPaint_Frame_UnifiedXPosition	= BieYeCutePetPaintFrame : GetProperty("UnifiedXPosition");
	g_BieYeCutePetPaint_Frame_UnifiedYPosition	= BieYeCutePetPaintFrame : GetProperty("UnifiedYPosition");

end


--===============================================
-- OnEvent()
--===============================================
function BieYeCutePetPaint_OnEvent(event)
	if ( event == "BIEYE_OPENCUTEPET_PAINT" or (event == "UI_COMMAND" and tonumber(arg0) == 2017082901)) then
		BieYeMengChong:AcquireList(1,1);
		BieYeCutePetPaint_DisableAllButton()
		BieYeCutePetPaint_UpdateFrame()
		BieYeCutePetPaint_SetObj()
		this:Show()
	elseif (event == "UPDATE_BIEYECUTEPET_LIST") then
		if g_ZiDongState == 1 then
			return;
		end
		if(IsWindowShow("BieYeCutePetPaint")) then
			BieYeCutePetPaint_LoadData()
			BieYeCutePetPaint_UpdateFrame()
		end
	elseif ( event == "MONEY_CHANGE_EX" )		then
		BieYeCutePetPaint_ShowMoney()

	elseif ( event == "MONEYJZ_CHANGE_EX")		then
		BieYeCutePetPaint_ShowJZ()

	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		BieYeCutePetPaint_Frame_OnHiden()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		BieYeCutePetPaint_Frame_On_ResetPos()
	elseif ( event == "OBJECT_CARED_EVENT" )		then
		BieYeCutePetPaint_CareObj(arg0,arg1,arg2)
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		BieYeCutePetPaint_Frame_On_ResetPos()

	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2017083101) then
		local result 										= Get_XParam_INT(0)
		BieYeCutePetPaint_g_DeleteMCID 	= Get_XParam_INT(1)
		BieYeCutePetPaint_g_AddMCID 		= Get_XParam_INT(2)
		local IsRequestData 						= Get_XParam_INT(3)
		g_RareColorComfirm = 0
		--失败了
		if result == 0 then
			if g_ZiDongState == 1 then
				g_ZiDongState = 0; 
				local nTemp = BieYeCutePetPaint_GetButtonIndexById(BieYeCutePetPaint_g_LeftLastSelectId)
				if(nTemp ~= nil and nTemp >= 0) then
					BieYeCutePetPaint_SetLeftButtonSelected(nTemp,true) 
				end 
			end
			if IsRequestData == 1 then
				BieYeCutePetPaint_g_LeftLastSelectId = -1;
				BieYeMengChong:AcquireList(1,1);
			end
			return
		end
		local _name,ComIdx = BieYeCutePetPaint_Zidong_ALLChoice:GetCurrentSelect()
		BieYeCutePetPaint_g_DescMCID = g_ChoiceData[ComIdx];
		--不是自动染色  成功了
		if g_ZiDongState == 0 then 
			BieYeCutePetPaint_g_LeftLastSelectId 	= BieYeCutePetPaint_g_AddMCID 
			
			local nTemp = BieYeCutePetPaint_GetButtonIndexById(BieYeCutePetPaint_g_LeftLastSelectId)
			if(nTemp ~= nil and nTemp >= 0) then
				BieYeCutePetPaint_SetLeftButtonSelected(nTemp,true) 
			end
			return
		end
		
		local PinZhi = BieYeMengChong:GetBieYeMengChongInfo(BieYeCutePetPaint_g_AddMCID,7)
		
		--染出目标染色
		if BieYeCutePetPaint_g_AddMCID == BieYeCutePetPaint_g_DescMCID and g_ZiDongState == 1 then 
			BieYeCutePetPaint_g_LeftLastSelectId 	= BieYeCutePetPaint_g_AddMCID
			g_ZiDongState = 0; 
			BieYeMengChong:AcquireList(1,1);
			local ColorName = BieYePetCreateColor:GetColorName(BieYeCutePetPaint_g_AddMCID)
			PushDebugMessage( ScriptGlobal_Format("#{MCFZ_20170807_108}",ColorName) )
		elseif g_BieYeCutePetPaint_AnyRare == 1 and PinZhi == 3 then
			BieYeCutePetPaint_g_LeftLastSelectId 	= BieYeCutePetPaint_g_AddMCID
			g_ZiDongState = 0; 
			BieYeMengChong:AcquireList(1,1);
			local ColorName = BieYePetCreateColor:GetColorName(BieYeCutePetPaint_g_AddMCID)
			PushDebugMessage( ScriptGlobal_Format("#{MCFZ_20170807_108}",ColorName) )
			g_BieYeCutePetPaint_AnyRare = 0;
		else 
			local nTemp = BieYeCutePetPaint_GetButtonIndexById(BieYeCutePetPaint_g_AddMCID)
			BieYeCutePetPaint_g_LeftLastSelectId = BieYeCutePetPaint_g_AddMCID
			if(nTemp ~= nil and nTemp >= 0) then
				BieYeCutePetPaint_RefreshObject(nTemp,true) 
			end
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnCutePetPaint_Auto")
			Set_XSCRIPT_ScriptID(892496)
			Set_XSCRIPT_Parameter(0, BieYeCutePetPaint_g_AddMCID) 
			Set_XSCRIPT_Parameter(1, BieYeCutePetPaint_g_DescMCID) 
			Set_XSCRIPT_Parameter(2, g_BieYeCutePetPaint_YuanbaoPay)
			Set_XSCRIPT_Parameter(3, 0)
			Set_XSCRIPT_ParamCount(4)
			Send_XSCRIPT()
		end
	end
end


--===============================================
-- OnHiden
--===============================================
function BieYeCutePetPaint_Frame_OnHiden()
	BieYeCutePetPaint_ListContent:CleanAllElement("BieYeCutePetPaint")
	BieYeCutePetPaint_ClearAllFakeobject()
	this:CareObject(g_BieYeCutePetPaint_objCared, 0, "BieYeCutePetPaint")

--	BieYeCutePetPaint_g_LeftCurSelectList = 0
	BieYeCutePetPaint_g_LeftLastSelectId = 0
--	BieYeCutePetPaint_g_FirtstContent = 0
 	BieYeCutePetPaint_g_DeleteMCID =0;
 	BieYeCutePetPaint_g_AddMCID =0;
 	BieYeCutePetPaint_g_DescMCID = 0
 	g_serverNpcId = -1;
 	BieYeCutePetPaint_g_Comfirm = 1
	g_ZiDongState  =0
 	g_ItemPos = -1;
 	BieYeCutePetPaint_g_AllLeftButton = {}
 	g_ChoiceData ={}
 	g_AllOutMengChongIndex = {}
 	g_AllMengChongData = {}
 	g_RareColorComfirm = 0;
	this:Hide()
end
function BieYeCutePetPaint_Close()
	BieYeCutePetPaint_Frame_OnHiden()
end

function BieYeCutePetPaint_ClearAllFakeobject()
	BieYeCutePetPaint_Fitting_FakeObject:SetFakeObject("") 
	BieYeCutePetPaint_Text2:SetText("") 
	BieYeCutePetPaint_Text1:SetText("")
	BieYeCutePetPaint_Jian:Hide() 
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeCutePetPaint_Frame_On_ResetPos()

	BieYeCutePetPaintFrame : SetProperty("UnifiedXPosition", g_BieYeCutePetPaint_Frame_UnifiedXPosition);
	BieYeCutePetPaintFrame : SetProperty("UnifiedYPosition", g_BieYeCutePetPaint_Frame_UnifiedYPosition);

end

function BieYeCutePetPaint_UpdateFrame()
	BieYeCutePetPaint_ClearAllFakeobject()
	BieYeCutePetPaint_LoadLeft()
	local nTemp = BieYeCutePetPaint_GetButtonIndexById(BieYeCutePetPaint_g_LeftLastSelectId)
	if(nTemp ~= nil and nTemp >= 0) then
		--PushDebugMessage("nTemp"..nTemp)
		BieYeCutePetPaint_SetLeftButtonSelected(nTemp,true)
	else
--		BieYeCutePetPaint_SetLeftButtonSelected(BieYeCutePetPaint_g_LeftCurSelectList,true)
	end
	local theAction = DataPool:CreateActionItemForShow(g_BieYeCutePetPaint_ColorItem, 1)
	if theAction:GetID() ~= 0 then
	  	BieYeCutePetPaint1_Item:SetActionItem(theAction:GetID())
	end
	BieYeCutePetPaint_CurrentlyJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	BieYeCutePetPaint_CurrentlyMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	BieYeCutePetPaint_DemandMoney:SetProperty("MoneyNumber", tostring( g_NeedMoney ))
	BieYeCutePetPaint_Blank_Queren:SetCheck(g_BieYeCutePetPaint_YuanbaoPay)	  
	
end
function BieYeCutePetPaint_LoadData()
	local nNum = BieYePetCreateColor:GetMengChongTypeNum()
	g_AllOutMengChongIndex = {}
	g_AllMengChongData = {}
	--Lua_TDU_Log("--Lua_TDU_Log-------BieYeCutePetPaint_LoadData")
	for i = 1,BieYeCutePetPaint_g_MaxType do
		local bStop = false
		local j = 0
		while(bStop ~= true) do 
			j = j + 1
			local nId,name1,CanBeColor,ColorLevel,Weight = BieYePetCreateColor:GetMengChongCanColorInfo(0,i,0,j)
			local ColorName = ""
			--if ColorLevel == 0 then
			--	ColorName = ""
			--else
				ColorName = BieYePetCreateColor:GetColorName(nId)
			--end 
			if(nId == -1) then
				bStop = true
			else
				if(g_AllMengChongData[nId] == nil and CanBeColor == 1) then 
					local tp1 = {}
					tp1.name = ColorName..BieYeCutePetPaint_g_ColorLevel[ColorLevel+1]
					tp1.num = 0
					tp1.nType = i
					tp1.pos = 0
					tp1.CanBeColor = CanBeColor
					tp1.ColorLevel = ColorLevel
					g_AllMengChongData[nId] = tp1 
					if(g_AllOutMengChongIndex[i] == nil) then 
						local tempList ={}
						tempList.list = {}
						tempList.name = "#e010101#cFDEACA"..BieYeCutePetPaint_g_MengChongOutType[i]
						tempList.CanBeColorCount = CanBeColor
						tempList.HasItem = 0
						tempList.ItemTypeCount = 1
						--table.insert(tempList.list,nId)
						
						local TableList = {}
						TableList.id = nId
						TableList.Weight = Weight
						table.insert(tempList.list,TableList) 
		
						g_AllOutMengChongIndex[i] = tempList 
					else  
						g_AllOutMengChongIndex[i].CanBeColorCount = g_AllOutMengChongIndex[i].CanBeColorCount + CanBeColor
						g_AllOutMengChongIndex[i].ItemTypeCount = g_AllOutMengChongIndex[i].ItemTypeCount + 1
						local TableList = {}
						TableList.id = nId
						TableList.Weight = Weight			
						table.insert(g_AllOutMengChongIndex[i].list,TableList)  
					end 
				end
			end
		end
	end
	
	BieYeCutePetPaint_SortMengChongIndex()
	for i=0,nNum - 1 do
		local nIndex,_nNum  = BieYePetCreateColor:GetMengChongInfoByIndex(i) 
		if(nIndex ~= nil and nIndex ~= -1) then
			if(g_AllMengChongData[nIndex] ~= nil) then
				g_AllMengChongData[nIndex].num = _nNum
				local pos = g_AllMengChongData[nIndex].pos
				local Type = g_AllMengChongData[nIndex].nType
				if( pos == 0 and _nNum > 0) then
					if(g_AllOutMengChongIndex[Type] ~= nil and
					g_AllOutMengChongIndex[Type].HasItem ~= 1) then
						g_AllOutMengChongIndex[Type].HasItem = 1
					end
				end
			end
		end
	end
end

--对需要显示的成就进行优先级排序
function BieYeCutePetPaint_SortMengChongIndex()
	local IsPriorityHigher = function( a, b ) 
								return ( a.Weight < b.Weight )
							  end
							  
	for i =1,BieYeCutePetPaint_g_MaxType do 
		table.sort( g_AllOutMengChongIndex[i].list, IsPriorityHigher )
	end 
end

function BieYeCutePetPaint_LoadLeft()
	BieYeCutePetPaint_ListContent:CleanAllElement("BieYeCutePetPaint")
	BieYeCutePetPaint_g_AllLeftButton = {}
	--排序
	--BieYeCutePetPaint_UpDateOrder()
	local bShow = 1
	local DataIndex = {}
	DataIndex = g_AllOutMengChongIndex
	for i=1,BieYeCutePetPaint_g_MaxType do
		if(DataIndex[i] ~= nil ) then
			if  DataIndex[i].CanBeColorCount ~= nil and DataIndex[i].CanBeColorCount > 1 then
				local ShowName = DataIndex[i].name
				if(DataIndex[i].ItemTypeCount > 1 and DataIndex[i].HasItem > 0) then
					ShowName = ShowName .. "(可美容)"
				end
				BieYeCutePetPaint_AddCatalog(BieYeCutePetPaint_g_AllLeftButton,ShowName,i)
				for j=1,table.getn(DataIndex[i].list) do
					local nId = DataIndex[i].list[j].id
					if(g_AllMengChongData[nId] ~= nil) then
						if(g_AllMengChongData[nId].name == nil) then
							PushDebugMessage("出现未知错误 id="..nId)
						end
						if(g_AllMengChongData[nId].CanBeColor == 1) then
							local str = ScriptGlobal_Format("#{XYJJ_170216_07}",tostring(g_AllMengChongData[nId].name),g_AllMengChongData[nId].num)
							if(g_AllMengChongData[nId].num == 0) then
								str = "#c666666"..str
							end
							BieYeCutePetPaint_AddText(BieYeCutePetPaint_g_AllLeftButton,str,i,nId,bShow)
						end
					end
				end
				bShow = 0
			end
		end
	end
	BieYeCutePetPaint_ListContent:Flash()

end
--增加类型控件
function BieYeCutePetPaint_AddCatalog(BtnList,nText,nType)
	local FurBtn = {}
	local CutePetCatalog = BieYeCutePetPaint_ListContent:AddItemElement( "BieYeFurniture", "LEFT", "BieYeCutePetPaint","" ,"")
	CutePetCatalog:SetProperty("AchievementWindowCatalogButtonHover","AchievementHoverSection")
	CutePetCatalog:AddTextCatalogTextAndImage(nText,BieYeCutePetPaint_g_FurImage,BieYeCutePetPaint_g_FurImageSet)
	FurBtn.bFirstContent = 1
	FurBtn.btn = CutePetCatalog
	FurBtn.Type = nType
	FurBtn.id = 0
	FurBtn.name = nText
	table.insert(BtnList,FurBtn)
end

--增加子类型控件
function BieYeCutePetPaint_AddText(BtnList,nText,nType,nId,bShow)
	local FurBtn = {}
	local szText = string.format("#e010101#cFDEACA%s", nText)
	local FurnitureText = BieYeCutePetPaint_ListContent:AddItemElement("BieYeFurnitureText","LEFT","BieYeCutePetPaint","","")
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

function BieYeCutePetPaint_ListContentItemClick()

	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if CurClickIndex + 1 > 0 then
--		BieYeCutePetPaint_g_LeftCurSelectList =	CurClickIndex + 1
		return BieYeCutePetPaint_SetLeftButtonSelected(CurClickIndex + 1)		--设置选中的类型高亮
	else
		return
	end
end

function BieYeCutePetPaint_OnTimer(nIndex)
	local strFunc = "BieYeCutePetPaint_OnTimer("..nIndex..")"
	if(BieYeCutePetPaint_g_AllLeftButton[nIndex] ~= nil and BieYeCutePetPaint_g_AllLeftButton[nIndex].bFirstContent == 0) then
		BieYeCutePetPaint_g_AllLeftButton[nIndex].btn:SetTextCatalogSelected(false)
	end
	KillTimer(strFunc)
end

function BieYeCutePetPaint_SetLeftButtonSelected(nIndex,bFresh)
	if nIndex ==nil or nIndex <= 0 then return end
	if(BieYeCutePetPaint_g_AllLeftButton[nIndex] == nil) then
		return
	end

	if g_ZiDongState == 1 then
		--PushDebugMessage("Auto Color No Admit")
		local strFunc = "BieYeCutePetPaint_OnTimer("..nIndex..")"
		SetTimer("BieYeCutePetPaint",strFunc,20)
		return
	end

	local nId = BieYeCutePetPaint_g_AllLeftButton[nIndex].id
	local num = g_AllMengChongData[nId].num 
	if(BieYeCutePetPaint_g_AllLeftButton[nIndex].bFirstContent == 0 ) then

		if((num == nil or num == 0) and (bFresh == nil or bFresh == false)) then
			PushDebugMessage("#{MCFZ_20170905_157}") 
			local strFunc = "BieYeCutePetPaint_OnTimer("..nIndex..")"
			SetTimer("BieYeCutePetPaint",strFunc,20)
			return
		end
	else
--		BieYeCutePetPaint_g_FirtstContent = nIndex
		--PushDebugMessage("BieYeCutePetPaint_g_FirtstContent"..BieYeCutePetPaint_g_FirtstContent)
	end

	for BtnIndex = 1,table.getn(BieYeCutePetPaint_g_AllLeftButton) do
		local bHigth = false
		if(BieYeCutePetPaint_g_AllLeftButton[BtnIndex].bFirstContent == 1) then
			if(BieYeCutePetPaint_g_AllLeftButton[BtnIndex].Type == BieYeCutePetPaint_g_AllLeftButton[nIndex].Type) then
				bHigth = true
			end
			BieYeCutePetPaint_g_AllLeftButton[BtnIndex].btn:SetCatalogButtonSelect(bHigth)

		else
			if(nIndex == BtnIndex and (num ~= nil and num > 0)) then
				bHigth = true
			end
			BieYeCutePetPaint_g_AllLeftButton[BtnIndex].btn:SetTextCatalogSelected(bHigth)
			if(BieYeCutePetPaint_g_AllLeftButton[BtnIndex].Type == BieYeCutePetPaint_g_AllLeftButton[nIndex].Type) then
				BieYeCutePetPaint_g_AllLeftButton[BtnIndex].btn:Show()
			else
				BieYeCutePetPaint_g_AllLeftButton[BtnIndex].btn:Hide()
			end
		end
	end
--	BieYeCutePetPaint_g_LeftCurSelectList = BieYeCutePetPaint_g_FirtstContent
	BieYeCutePetPaint_g_LeftLastSelectId = nId
	BieYeCutePetPaint_ClearAllFakeobject()
	BieYeCutePetPaint_OnLeftButtonSelected(nIndex,bFresh)
	BieYeCutePetPaint_ListContent:Flash()
	g_ChoiceData 			= {};
	BieYeCutePetPaint_UpdateChoiceListAndButton()
end
 
function BieYeCutePetPaint_GetButtonIndexById(Id)
	if(Id == nil or Id <= 0) then
		return -1
	end
	for BtnIndex = 1,table.getn(BieYeCutePetPaint_g_AllLeftButton) do
		if(BieYeCutePetPaint_g_AllLeftButton[BtnIndex].id == Id) then
			return BtnIndex
		end
	end
	return -1
end

--设置模型
function BieYeCutePetPaint_OnLeftButtonSelected(nIndex,bFresh)
	local nId = BieYeCutePetPaint_g_AllLeftButton[nIndex].id
	local num = g_AllMengChongData[nId].num
	if(BieYeCutePetPaint_g_AllLeftButton[nIndex].id == 0) then
		return
	end
	if(num == nil or num == 0) then
		BieYeCutePetPaint_Fitting_FakeObject:SetFakeObject("")
		BieYeCutePetPaint_Jian:Hide() 
		BieYeCutePetPaint_Text2:SetText("") 
		BieYeCutePetPaint_Text1:SetText("")
		return
	end
	BieYeCutePetPaint_Fitting_FakeObject:SetFakeObject("")
	local ModelID = BieYeMengChong:Lua_GetModelIDByMengChongIndex(nId)
	DataPool:ShowMengChongPaint_SetNPCModel(tonumber(ModelID), 1)
	BieYeCutePetPaint_Fitting_FakeObject:SetFakeObject("ShowMengChongPaint")
	local PinZhi = BieYeMengChong:GetBieYeMengChongInfo(nId,7) + 1
	local ColorName = BieYePetCreateColor:GetColorName(nId)
	BieYeCutePetPaint_Text2:SetText(BieYeCutePetPaint_g_Color[PinZhi]..ColorName..BieYeCutePetPaint_g_ColorLevel[PinZhi])
	local nName = BieYeMengChong:GetBieYeMengChongInfo(nId,2)	
	BieYeCutePetPaint_Text1:SetText("#cfff263"..nName)
	BieYeCutePetPaint_Jian:Show()

end
--设置模型
function BieYeCutePetPaint_RefreshObject(nIndex,bFresh)
	local nId = BieYeCutePetPaint_g_AllLeftButton[nIndex].id
	local num = g_AllMengChongData[nId].num
	if(BieYeCutePetPaint_g_AllLeftButton[nIndex].id == 0) then
		return
	end 
	BieYeCutePetPaint_Fitting_FakeObject:SetFakeObject("")
	local ModelID = BieYeMengChong:Lua_GetModelIDByMengChongIndex(nId)
	DataPool:ShowMengChongPaint_SetNPCModel(tonumber(ModelID), 1)
	BieYeCutePetPaint_Fitting_FakeObject:SetFakeObject("ShowMengChongPaint")
	local PinZhi = BieYeMengChong:GetBieYeMengChongInfo(nId,7) + 1
	local ColorName = BieYePetCreateColor:GetColorName(nId)
	BieYeCutePetPaint_Text2:SetText(BieYeCutePetPaint_g_Color[PinZhi]..ColorName..BieYeCutePetPaint_g_ColorLevel[PinZhi])
	local nName = BieYeMengChong:GetBieYeMengChongInfo(nId,2)	
	BieYeCutePetPaint_Text1:SetText("#cfff263"..nName)
	BieYeCutePetPaint_Jian:Show()

end
function BieYeCutePetPaint_TurnRight(start)
	--向右旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeCutePetPaint_Fitting_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			BieYeCutePetPaint_Fitting_FakeObject:RotateEnd();
		end
	end
end

function BieYeCutePetPaint_TurnLeft(start)
	--向左旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeCutePetPaint_Fitting_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			BieYeCutePetPaint_Fitting_FakeObject:RotateEnd();
		end
	end
end

function BieYeCutePetPaint_OnMoved()
	return
end

function BieYeCutePetPaint_OK_Clicked()
	if g_ZiDongState == 1 then
		PushDebugMessage("#{MCFZ_20170807_102}")
		return
	end
	
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < g_NeedMoney then
		PushDebugMessage("#{RXZS_090804_11}")
		return
	end

	if BieYeCutePetPaint_g_LeftLastSelectId <= 0 then
		PushDebugMessage("#{MCFZ_20170905_150}")
		return
	end 
	--检查CD 
  if not BieYeCutePetPaint_PassCD() then 
     PushDebugMessage("#{ZYPT_081127_2}")  --"不可连续点击，请稍等片刻后再点击。";
     return
  end 
  
	if g_AllMengChongData[BieYeCutePetPaint_g_LeftLastSelectId].ColorLevel == 3 and g_RareColorComfirm == 0 then
		ColorName = BieYePetCreateColor:GetColorName(BieYeCutePetPaint_g_LeftLastSelectId)
		PushEvent("BIEYE_PETCOLOR_CONFIRM",tostring(ColorName))
		g_RareColorComfirm = 1;
		return
	end
	  

	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnCutePetPaint")
	Set_XSCRIPT_ScriptID(892496)
	Set_XSCRIPT_Parameter(0, BieYeCutePetPaint_g_LeftLastSelectId) 
	Set_XSCRIPT_Parameter(1, g_BieYeCutePetPaint_YuanbaoPay)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
	--BieYeCutePetPaint_OK:Disable();
	--SetTimer("BieYeCutePetPaint","BieYeCutePetPaint_Click_OnTimer()",3000)
end

function BieYeCutePetPaint_Click_OnTimer()
	KillTimer("BieYeCutePetPaint_Click_OnTimer()") 
	BieYeCutePetPaint_OK:Enable(); 
end

--点击自动染色事件
function BieYeCutePetPaint_Zidong_Clicked()			--自动开启  开启timer事件

	 if g_ZiDongState == 0 then
		if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
			PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
			return
		end
		--判断电话密保和二级密码保护2012.6.12-LIUBO
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then
			return
		end

		local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
		if selfMoney < g_NeedMoney then
			PushDebugMessage("#{MCFZ_20170807_98}")
			return
		end

		if BieYeCutePetPaint_g_LeftLastSelectId <= 0 then
			PushDebugMessage("#{MCFZ_20170807_88}")
			return
		end

		local _name,ComIdx = BieYeCutePetPaint_Zidong_ALLChoice:GetCurrentSelect()
		if g_ChoiceData[ComIdx] == nil then
			PushDebugMessage("#{MCFZ_20170807_89}")
			return
		end

		if g_AllMengChongData[BieYeCutePetPaint_g_LeftLastSelectId].ColorLevel == 3 and g_RareColorComfirm == 0 then
			ColorName = BieYePetCreateColor:GetColorName(BieYeCutePetPaint_g_LeftLastSelectId)
			PushEvent("BIEYE_PETCOLOR_CONFIRM",tostring(ColorName))
			g_RareColorComfirm = 1;
			return
		end
		g_RareColorComfirm = 0

		BieYeCutePetPaint_g_DescMCID = g_ChoiceData[ComIdx];
		g_ZiDongState 			= 1
    BieYeCutePetPaint_Zidong_ALLChoice:Disable()
		BieYeCutePetPaint_OK:Disable()
    BieYeCutePetPaint_Zidong:SetText("#{MCFZ_20170807_104}")

    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnCutePetPaint_Auto")
		Set_XSCRIPT_ScriptID(892496)
		Set_XSCRIPT_Parameter(0, BieYeCutePetPaint_g_LeftLastSelectId)  
		Set_XSCRIPT_Parameter(1, BieYeCutePetPaint_g_DescMCID) 
		Set_XSCRIPT_Parameter(2, g_BieYeCutePetPaint_YuanbaoPay)
		Set_XSCRIPT_Parameter(3, 1)
		Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()

  else
  	g_ZiDongState 			= 0
  	PushDebugMessage("#{MCFZ_20170807_110}")
    BieYeCutePetPaint_Zidong:SetText("#{MCFZ_20170807_103}")
		BieYeCutePetPaint_OK:Enable()
	end

end

--点击自动染色事件
function BieYeCutePetPaint_UpdateChoiceListAndButton()			--自动开启  开启timer事件
	BieYeCutePetPaint_Zidong_ALLChoice:ResetList()
	BieYeCutePetPaint_Zidong_ALLChoice:SetText("#{MCFZ_20170807_89}")--选择目标染色风格
	local nCount = BieYePetCreateColor:GetCanColorMengChongCountByMCID( BieYeCutePetPaint_g_LeftLastSelectId )
	if nCount == 0 then
		BieYeCutePetPaint_OK:Disable()
		BieYeCutePetPaint_Zidong_ALLChoice:Disable()
		BieYeCutePetPaint_Zidong:Disable()
		BieYeCutePetPaint_Zidong:SetText("#{MCFZ_20170807_103}")
		BieYeCutePetPaint_Zidong_Animate:Play(false)
		return
	end

	BieYeCutePetPaint_OK:Enable()	
	BieYeCutePetPaint_Zidong:Disable()
	BieYeCutePetPaint_Zidong_ALLChoice:Enable()
	BieYeCutePetPaint_Zidong:SetText("#{MCFZ_20170807_103}")
	BieYeCutePetPaint_Zidong_Animate:Play(false)

	for i = 1 , nCount do
		local ColorMcID,MengChongName = BieYePetCreateColor:GetColorInfoMengChongByIndex( BieYeCutePetPaint_g_LeftLastSelectId , i)
		local PinZhi = BieYeMengChong:GetBieYeMengChongInfo(ColorMcID,7) + 1  
	
		BieYeCutePetPaint_Zidong_ALLChoice:AddTextItem(MengChongName..BieYeCutePetPaint_g_ColorLevel[PinZhi] ,i)
		g_ChoiceData[i] = ColorMcID
	end
	--BieYeCutePetPaint_Zidong_ALLChoice:AddTextItem("#{MCFZ_20170905_175}" ,nCount+1)
	--g_ChoiceData[nCount+1] = 0
end

function BieYeCutePetPaint_DestMode_Changed()
	local _name,ComIdx = BieYeCutePetPaint_Zidong_ALLChoice:GetCurrentSelect()
	if ComIdx > 0 then 
		BieYeCutePetPaint_Zidong:SetText("#G#{MCFZ_20170807_103}") 
		BieYeCutePetPaint_Zidong:Enable()
		BieYeCutePetPaint_Zidong_Animate:Play(true)
	else
		BieYeCutePetPaint_Zidong:SetText("#{MCFZ_20170807_103}") 
		BieYeCutePetPaint_Zidong:Disable() 
		BieYeCutePetPaint_Zidong_Animate:Play(false)
	end 

	if g_ChoiceData[ComIdx] == BieYeCutePetPaint_g_LeftLastSelectId then --and ComIdx ~= nCount 
			BieYeCutePetPaint_Zidong:SetText("#{MCFZ_20170807_103}") 
			BieYeCutePetPaint_Zidong:Disable()
			BieYeCutePetPaint_Zidong_Animate:Play(false)
			PushDebugMessage("#{MCFZ_20170905_158}") 
	end
	
	local nCount = table.getn(g_ChoiceData)	
	if nCount == ComIdx and g_ChoiceData[ComIdx] == 0 then
		g_BieYeCutePetPaint_AnyRare = 1;
	else
		g_BieYeCutePetPaint_AnyRare = 0;
	end
	    
end

function BieYeCutePetPaint_DisableAllButton()
		BieYeCutePetPaint_OK:Disable()										-- 禁用“确定”按钮
		BieYeCutePetPaint_Zidong:SetText("#{MCFZ_20170807_103}")
		BieYeCutePetPaint_Zidong:Disable()
		BieYeCutePetPaint_Zidong_Animate:Play(false)
		BieYeCutePetPaint_Fitting_FakeObject:SetFakeObject("")
		BieYeCutePetPaint_Zidong_ALLChoice:Disable()	 
		BieYeCutePetPaint_Text2:SetText("") 
		BieYeCutePetPaint_Text1:SetText("")
		BieYeCutePetPaint_Jian:Hide()
		
end

function BieYeCutePetPaint_SetObj()
	g_serverNpcId = Get_XParam_INT(0)
	if (g_serverNpcId == -1) then
		return
	end
	g_BieYeCutePetPaint_objCared = DataPool : GetNPCIDByServerID(g_serverNpcId);
	this:CareObject(g_BieYeCutePetPaint_objCared, 1,"BieYeCutePetPaint");
end

--*************************************************
--关心NPC
--*************************************************
function BieYeCutePetPaint_CareObj(careId, op, distance)
	if(nil == careId or nil == op or nil == distance) then
		return;
	end

	if(tonumber(careId) ~= g_serverNpcId) then
		return;
	end

	if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
		BieYeCutePetPaint_Frame_OnHiden()
	end
end
--********************************************
--显示自身拥有的金钱
--********************************************
function BieYeCutePetPaint_ShowMoney()
	BieYeCutePetPaint_CurrentlyMoney : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--********************************************
--显示自身拥有的交子
--********************************************
function BieYeCutePetPaint_ShowJZ()
	BieYeCutePetPaint_CurrentlyJiaozi : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
end

function BieYeCutePetPaint_Jian_Click()
	if BieYeCutePetPaint_g_LeftLastSelectId > 0 then
		PushEvent("OPEN_MEGNCHONG_SHOW_PETCREATE",BieYeCutePetPaint_g_LeftLastSelectId)
	end
end
--========================================
--CD检查
--========================================
function BieYeCutePetPaint_PassCD()
   local iCur = OSAPI:GetTickCount()
   if( iCur - g_TimeClick) < 2*1000 then
       return false;
   else
       g_TimeClick = iCur;
       return true;
   end
end

function BieYeCutePetPaint_Confirm_Clicked() 
	g_BieYeCutePetPaint_YuanbaoPay = BieYeCutePetPaint_Blank_Queren:GetCheck();
end

