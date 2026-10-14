
local g_DecorateWeaponLevelUp_new_Frame_UnifiedPosition
local g_clientNpcId = -1

local g_DecorateWeaponLevelUp_new_YuanBaoPay = 1	--元宝购买确认

local g_WeaponLevelAction = {}  --幻武等级框ui集合
local g_WeaponLevelLock = {}--幻武等级框遮罩ui集合

local g_BarList = {}	--幻武图鉴ui集合
local g_MaxBarNum = 0 --图鉴总数
local g_CurSelExteriorWeaponGroupID = 0		--当前选择的幻武外观ID，从1开始 Exterior_WeaponGroup表的id 
local g_CurSelExteriorWeaponID = 0 -- Exterior_Weapon表的id
local g_CurSelExteriorWeaponLevel = 1	--当前选择的幻武等级
local g_IsNeedRestCurSelExteriorWeaponLevel = 0
local g_CurSelItemIndex = 1
local g_ExteriorType = 1 --幻武
local g_DataListCount = 0

local g_GroupIDTable = {}  --通过GroupId 获取选中的itemIndex

function DecorateWeaponLevelUp_new_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
--背包右键添加使用幻武的事件 升级界面需要刷新
	this:RegisterEvent("ADD_EXTERIOR",false)
	-- this:RegisterEvent("DELETE_EXTERIOR",false)
	this:RegisterEvent("UPDATE_EXTERIOR",false)
	this:RegisterEvent("EXTERIOR_OUTTIME",false)	
	this:RegisterEvent("EXTERIOR_ID_CHANGED",false)
--幻武升级成功 界面也需要刷新
end

function DecorateWeaponLevelUp_new_OnLoad() 
	g_DecorateWeaponLevelUp_new_Frame_UnifiedPosition = DecorateWeaponLevelUp_new_Frame:GetProperty("UnifiedPosition")

	g_WeaponLevelAction[1] = DecorateWeaponLevelUp_new_WeaponLV1
	g_WeaponLevelAction[2] = DecorateWeaponLevelUp_new_WeaponLV2
	g_WeaponLevelAction[3] = DecorateWeaponLevelUp_new_WeaponLV3
	g_WeaponLevelAction[4] = DecorateWeaponLevelUp_new_WeaponLV4
	g_WeaponLevelAction[5] = DecorateWeaponLevelUp_new_WeaponLV5

	g_WeaponLevelLock[1] = DecorateWeaponLevelUp_new_WeaponLV1_Mask
	g_WeaponLevelLock[2] = DecorateWeaponLevelUp_new_WeaponLV2_Mask
	g_WeaponLevelLock[3] = DecorateWeaponLevelUp_new_WeaponLV3_Mask
	g_WeaponLevelLock[4] = DecorateWeaponLevelUp_new_WeaponLV4_Mask
	g_WeaponLevelLock[5] = DecorateWeaponLevelUp_new_WeaponLV5_Mask

	g_DecorateWeaponLevelUp_new_YuanBaoPay = 1
	g_CurSelExteriorWeaponGroupID = 0
	g_CurSelExteriorWeaponID = 0
	g_CurSelExteriorWeaponLevel = 1
	g_CurSelItemIndex = 1
end

function DecorateWeaponLevelUp_new_OnEvent(event) 
	if (event == "ADJEST_UI_POS" ) then
		DecorateWeaponLevelUp_new_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DecorateWeaponLevelUp_new_Frame_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DecorateWeaponLevelUp_new_OnHiden()
	elseif (event == "MONEY_CHANGE_EX") then
		local playerMoney = Player:GetData("MONEY")
		DecorateWeaponLevelUp_new_SelfMoney:SetProperty("MoneyNumber", playerMoney)
	elseif (event == "MONEYJZ_CHANGE_EX") then
		local playerJZ = Player:GetData("MONEY_JZ")
		DecorateWeaponLevelUp_new_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
	elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 891788 then
		PushEvent( "CLOSE_DRESSPREVIEW")
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")
		Exterior:LuaFnUpdateDressPreviewPlayerData(-1, -1, -1, -1, Player:GetMySex(), 0)
		
		local Type = Get_XParam_INT(0)
		if Type == 1 then       --打开界面
			if this : IsVisible() then	-- 如果界面开着，则不处理
				return
			end

			local npcObjId = Get_XParam_INT(1)
			g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
			if g_clientNpcId == -1 then
				PushDebugMessage("未发现 NPC")
				DecorateWeaponLevelUp_new_CloseBtnClick()
				return
			end
		
			this:CareObject( g_clientNpcId, 1, "DecorateWeaponLevelUp_new" )

			this:Show()

			DecorateWeaponLevelUp_new_Init()
		end
	elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 202101131 then
		if (this : IsVisible() == false) then
			return
		end
		g_CurSelExteriorWeaponLevel = Get_XParam_INT(0)
		DecorateWeaponLevelUp_new_SelectLevel(g_CurSelExteriorWeaponLevel)

	elseif event == "ADD_EXTERIOR" or event == "UPDATE_EXTERIOR" or event == "EXTERIOR_OUTTIME" or event == "EXTERIOR_ID_CHANGED" then
		-- 解锁了新的幻武图鉴 
		-- PushDebugMessage("xtcsadasds")
		if tonumber(arg0) == g_ExteriorType and arg1 ~= nil then
			--先区分这个幻武groupid是否是已经拥有的
			local nExteriorWeaponID = tonumber(arg1)
			
			--先区分这个幻武id是否是属于CurSelExteriorWeaponGroupID这个组里
			local nIsWeaponIDInGroup = Exterior:LuaFnIsWeaponIDInGroup(g_CurSelExteriorWeaponGroupID, nExteriorWeaponID)
			if nIsWeaponIDInGroup ==1 then
				--在当前组
				if Exterior:LuaFnIsHaveExteriorWeaponGroup(g_CurSelExteriorWeaponGroupID) == 1 then
					--拥有当前组 这种情况不用重新刷新列表
					DecorateWeaponLevelUp_new_ItemClicked(g_CurSelItemIndex)
				end
			else
				DecorateWeaponLevelUp_new_Update()
			end
		end

	end
	
	-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			DecorateWeaponLevelUp_new_OnHiden()
			this:Hide()
		end
	end	
end

function DecorateWeaponLevelUp_new_Frame_On_ResetPos()
	DecorateWeaponLevelUp_new_Frame:SetProperty("UnifiedPosition", g_DecorateWeaponLevelUp_new_Frame_UnifiedPosition);
end

function DecorateWeaponLevelUp_new_Init()
	--左侧展示模型 初始化
	DecorateWeaponLevelUp_new_FakeObject:AttachWindowEx("DecoWeapon_Player")
	SetFakeObjDataEx("DecoWeapon_Player")
	--元宝确认框ui状态
	if g_DecorateWeaponLevelUp_new_YuanBaoPay == 1 or g_DecorateWeaponLevelUp_new_YuanBaoPay == 0 then
		DecorateWeaponLevelUp_new_YuanBaoPay:SetCheck(g_DecorateWeaponLevelUp_new_YuanBaoPay)
	end

	local playerMoney = Player:GetData("MONEY")
	DecorateWeaponLevelUp_new_SelfMoney:SetProperty("MoneyNumber", playerMoney)
	local playerJZ = Player:GetData("MONEY_JZ")
	DecorateWeaponLevelUp_new_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
	DecorateWeaponLevelUp_new_Update()

	DecorateWeaponLevelUp_new_OK:SetToolTip("#{HWSJ_201218_13}")
end

function DecorateWeaponLevelUp_new_Update()
		--右侧上面图鉴列表初始化
	Exterior:LuaFnInitExteriorWeaponGroupList()
	g_MaxBarNum = Exterior:LuaFnGetExteriorWeaponGroupCount()
	g_DataListCount = Exterior:LuaFnGetExteriorListCount(g_ExteriorType, 0)

	DecorateWeaponLevelUp_new_SuperList:Clear()
	for i = 1, g_MaxBarNum do
		local bar = DecorateWeaponLevelUp_new_SuperList:AddChild("DecorateWeaponLevelUp_new_SuperListItem")
		bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
		g_BarList[i] = bar	
		bar:GetSubItem("DecorateWeaponLevelUp_new_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("DecorateWeaponLevelUp_new_ItemClicked(%d)", i))
		bar:GetSubItem("DecorateWeaponLevelUp_new_SuperListItemAction"):SetEvent("MouseMove", string.format("DecorateWeaponLevelUp_new_ItemMouseMove(%d)", i))
		DecorateWeaponLevelUp_new_SetItem(i)
	end
	local curGroupId = Exterior:LuaFnGetWeaponGroupInUse()
	if g_GroupIDTable[curGroupId] ~= nil then
		g_CurSelItemIndex = g_GroupIDTable[curGroupId]
	end
			
	DecorateWeaponLevelUp_new_ItemClicked(g_CurSelItemIndex)
	
end

--初始化每个图鉴item
function DecorateWeaponLevelUp_new_SetItem(index)
	if g_BarList[index] == nil then
		return
	end
	if index > g_DataListCount then
		g_BarList[index]:Hide()
		return
	end
	local bar = g_BarList[index]
	bar:Show()

	local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(index - 1)
	local strIcon 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Icon")
	local strName 	= Exterior:LuaFnGetExteriorWeaponGroupInfo(nGroupID, "Name")
	g_GroupIDTable[nGroupID] = index
	local ctrlAction = bar:GetSubItem("DecorateWeaponLevelUp_new_SuperListItemAction")
	if ctrlAction ~= nil then	
		local strImage = GetIconFullName(strIcon)
		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_78}", strName)
		ctrlAction:SetToolTip(strTemp)
	end

	bar:GetSubItem("DecorateWeaponLevelUp_new_SuperListItemActionTime"):Hide()
	--锁
	if Exterior:LuaFnIsHaveExteriorWeaponGroup(nGroupID) == 1 then
		bar:GetSubItem("DecorateWeaponLevelUp_new_SuperListItemActionLock"):Hide()
	else		
		bar:GetSubItem("DecorateWeaponLevelUp_new_SuperListItemActionLock"):Show()
	end	

end

--点击幻武图鉴item
function DecorateWeaponLevelUp_new_ItemClicked(nIndex)
	-- PushDebugMessage("nIndex:"..tostring(nIndex))
	local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(nIndex - 1)	
	if nGroupID<=0 then
		return
	end
	g_CurSelExteriorWeaponGroupID = nGroupID
	if g_CurSelItemIndex ~= nIndex then
		g_CurSelItemIndex = nIndex
		-- local nLowLevelExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorWeaponGroupID, 0)
		-- if nLowLevelExteriorWeaponID ~= nil and nLowLevelExteriorWeaponID < 0 then
		-- 	g_CurSelExteriorWeaponLevel = 5--临时的幻武 默认的等级为5
		-- else
			g_CurSelExteriorWeaponLevel = 1
		-- end
	end
	

	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("DecorateWeaponLevelUp_new_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
	-- local nLowLevelExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorWeaponGroupID, 0)
	-- if nLowLevelExteriorWeaponID ~= nil and nLowLevelExteriorWeaponID < 0 then
	-- 	--临时幻武
	-- 	DecorateWeaponLevelUp_new_EnhanceNot:Show()
	-- 	DecorateWeaponLevelUp_new_Detail_Frame:Hide()
	-- else
	-- 	DecorateWeaponLevelUp_new_EnhanceNot:Hide()
	-- 	DecorateWeaponLevelUp_new_Detail_Frame:Show()
	-- end
	
	for i = 1, 5 do	
		local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorWeaponGroupID, i - 1)
		if nExteriorWeaponID ~= nil and nExteriorWeaponID > 0 then
			g_WeaponLevelAction[i]:Show()
			local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(nExteriorWeaponID, "Icon")
			local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(nExteriorWeaponID, "Name")
			local strImage = GetIconFullName(strIcon)
			g_WeaponLevelAction[i]:SetProperty("NormalImage", strImage)
			g_WeaponLevelAction[i]:SetProperty("HoverImage", strImage)
			
			local strTemp = Exterior:LuaFnGetExteriorWeaponToolTip(nExteriorWeaponID)
			-- PushDebugMessage("strTemp:"..tostring(strTemp))
			g_WeaponLevelAction[i]:SetToolTip(strTemp)

		
			if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorWeaponID) == 1 then
				g_CurSelExteriorWeaponLevel = i
				g_IsNeedRestCurSelExteriorWeaponLevel = 0
				g_WeaponLevelLock[i]:Hide()
			else
				g_WeaponLevelLock[i]:Show()
				if g_IsNeedRestCurSelExteriorWeaponLevel == 1 then
					g_CurSelExteriorWeaponLevel = i
					g_IsNeedRestCurSelExteriorWeaponLevel = 0
				end
			end
		else
			g_WeaponLevelAction[i]:Hide()
			-- g_CurSelExteriorWeaponLevel = 1
			if i == g_CurSelExteriorWeaponLevel then
				g_IsNeedRestCurSelExteriorWeaponLevel = 1
			end
		end			
	end
	-- PushDebugMessage("g_CurSelExteriorWeaponLevel:"..tostring(g_CurSelExteriorWeaponLevel))
	DecorateWeaponLevelUp_new_SelectLevel(g_CurSelExteriorWeaponLevel)
end

--悬浮幻武图鉴item
function DecorateWeaponLevelUp_new_ItemMouseMove(nIndex)

end

--点击幻武等级item
function DecorateWeaponLevelUp_new_SelectLevel(nLevel)
	if nLevel<1 or nLevel>5 then
		return
	end
	g_CurSelExteriorWeaponLevel = nLevel
	
	for i = 1, 5 do			
		g_WeaponLevelAction[i]:SetPushed(0)			
	end
	g_WeaponLevelAction[g_CurSelExteriorWeaponLevel]:SetPushed(1)	

	local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorWeaponGroupID, g_CurSelExteriorWeaponLevel - 1)
	-- PushDebugMessage("nExteriorWeaponID:"..tostring(nExteriorWeaponID))
	g_CurSelExteriorWeaponID = nExteriorWeaponID
	DecorateWeaponLevelUp_new_ShowExteriorWeaponLevelUp(nExteriorWeaponID)
end

--根据选中的幻武表(Exterior_Weapon)中的id 得到幻武升级相关的数据并显示
function DecorateWeaponLevelUp_new_ShowExteriorWeaponLevelUp(nExteriorWeaponID)
	local NextLevel, DestDecoWeaponId, costMoneyNum, BindItemId, ItemId, NeedNum = DecoWeaponUI:GetDecoWeaponLevelDataByEquipId(nExteriorWeaponID)
	--缺少 幻武满级之后的处理
	if NextLevel == -1 then
		return 
	end

	DecoWeaponUI:DecoWeaponAvatarChangeWeapon(DestDecoWeaponId)
	if NextLevel == 0 then
		--满级
		DecorateWeaponLevelUp_new_MaxLevel:Show()
		DecorateWeaponLevelUp_new_Cost:Hide()
		DecorateWeaponLevelUp_new_EnhanceNot:Hide()
		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorWeaponID) == 1 then
		local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, nExteriorWeaponID)
			if nLeftTime and nLeftTime >= 0 then
				DecorateWeaponLevelUp_new_EnhanceNot:Show()
				DecorateWeaponLevelUp_new_MaxLevel:Hide()
			end
		end
		DecorateWeaponLevelUp_new_DemandMoney:SetProperty("MoneyNumber", 0)
	else
		-- 未满级
		
		DecorateWeaponLevelUp_new_MaxLevel:Hide()
		DecorateWeaponLevelUp_new_Cost:Show()
		DecorateWeaponLevelUp_new_EnhanceNot:Hide()
		DecorateWeaponLevelUp_new_DemandMoney:SetProperty("MoneyNumber", costMoneyNum)

		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorWeaponID) == 1 then

			local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, nExteriorWeaponID)
			
			if nLeftTime and nLeftTime >= 0 then
				--为限时幻武
				DecorateWeaponLevelUp_new_Cost:Hide()
				DecorateWeaponLevelUp_new_EnhanceNot:Show()
			else
				--非限时幻武
				local nNextExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorWeaponGroupID, NextLevel - 1)
				if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nNextExteriorWeaponID) == 1 then
					--下一级已经激活 
					local nNextExteriorLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, nNextExteriorWeaponID)
					if nNextExteriorLeftTime and nNextExteriorLeftTime >= 0 then
						local tempStr = ScriptGlobal_Format("#{HWSJ_201218_37}",NextLevel)
						DecorateWeaponLevelUp_new_LevelInfo:SetText(tempStr)
					else
						DecorateWeaponLevelUp_new_LevelInfo:SetText("#{HWSJ_201218_35}")
					end
					
					
				else
					local tempStr = ScriptGlobal_Format("#{HWSJ_201218_36}",NextLevel)
					DecorateWeaponLevelUp_new_LevelInfo:SetText(tempStr)
				end
			end
			
		else
			--没有 尚未激活
			DecorateWeaponLevelUp_new_LevelInfo:SetText("#{HWSJ_201218_34}")
		end

		DecorateWeaponLevelUp_new_NeedNameInfo:SetText(PlayerPackage:GetItemName(BindItemId).."*"..tostring(NeedNum))
	end
	
end

--点击幻武升级按钮
function DecorateWeaponLevelUp_new_OnOK()

	if g_CurSelExteriorWeaponID <= 0 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryExteriorWeaponLevelUp")
		Set_XSCRIPT_ScriptID(891788)
		Set_XSCRIPT_Parameter(0, g_CurSelExteriorWeaponID)
		Set_XSCRIPT_Parameter(1, g_CurSelExteriorWeaponGroupID)
		Set_XSCRIPT_Parameter(2, g_CurSelExteriorWeaponLevel)
		Set_XSCRIPT_Parameter(3, tonumber(DecorateWeaponLevelUp_new_YuanBaoPay:GetCheck()))
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end


--界面隐藏
function DecorateWeaponLevelUp_new_OnHiden()
	this:CareObject( g_clientNpcId, 0, "DecorateWeaponLevelUp_new" )
	g_clientNpcId = -1
	DecorateWeaponLevelUp_new_FakeObject:DetachWindowEx("DecoWeapon_Player")
	g_DecorateWeaponLevelUp_new_YuanBaoPay = DecorateWeaponLevelUp_new_YuanBaoPay:GetCheck();

	g_CurSelExteriorWeaponGroupID = 0
	g_CurSelExteriorWeaponID = 0
	g_CurSelExteriorWeaponLevel = 1
	g_IsNeedRestCurSelExteriorWeaponLevel = 0
	g_CurSelItemIndex = 1
	g_GroupIDTable = {}

end

--点击关闭按钮
function DecorateWeaponLevelUp_new_CloseBtnClick()
	this:Hide()
end


function DecorateWeaponLevelUp_new_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			DecorateWeaponLevelUp_new_FakeObject:RotateBeginEx("DecoWeapon_Player", -0.3);
		--向左旋转结束
		else
			DecorateWeaponLevelUp_new_FakeObject:RotateEndEx();
		end
	end
end


function DecorateWeaponLevelUp_new_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			DecorateWeaponLevelUp_new_FakeObject:RotateBeginEx("DecoWeapon_Player", 0.3);
		--向右旋转结束
		else
			DecorateWeaponLevelUp_new_FakeObject:RotateEndEx();
		end
	end
end
