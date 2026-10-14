
local g_DecorateWeaponLevelDown_new_Frame_UnifiedPosition
local g_clientNpcId = -1

local g_WeaponLevelAction = {}  --幻武等级框ui集合
local g_WeaponLevelLock = {}--幻武等级框遮罩ui集合

local g_BarList = {}	--幻武图鉴ui集合
local g_MaxBarNum = 0 --图鉴总数
local g_CurSelExteriorWeaponGroupID = 0		--当前选择的幻武外观ID，从1开始 Exterior_WeaponGroup表的id 
local g_CurSelExteriorWeaponID = 0 -- Exterior_Weapon表的id
local g_CurEWLevel = -1	--当前选择的幻武永久等级
local g_CurLimitEWLevel = -1	--当前选择幻武限时等级
local g_CurSelExteriorWeaponLevel = -1	--当前选择的幻武等级
local g_CurSelItemIndex = 1
local g_ExteriorType = 1 --幻武
local g_DataListCount = 0

local g_GroupIDTable = {}  --通过GroupId 获取选中的itemIndex
local g_CurClickDecoWeaponLevel = -1

function DecorateWeaponLevelDown_new_PreLoad()
	this:RegisterEvent("UI_COMMAND")
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

function DecorateWeaponLevelDown_new_OnLoad() 
	g_DecorateWeaponLevelDown_new_Frame_UnifiedPosition = DecorateWeaponLevelDown_new_Frame:GetProperty("UnifiedPosition")

	g_WeaponLevelAction[1] = DecorateWeaponLevelDown_new_WeaponLV1
	g_WeaponLevelAction[2] = DecorateWeaponLevelDown_new_WeaponLV2
	g_WeaponLevelAction[3] = DecorateWeaponLevelDown_new_WeaponLV3
	g_WeaponLevelAction[4] = DecorateWeaponLevelDown_new_WeaponLV4

	g_WeaponLevelLock[1] = DecorateWeaponLevelDown_new_WeaponLV1_Mask
	g_WeaponLevelLock[2] = DecorateWeaponLevelDown_new_WeaponLV2_Mask
	g_WeaponLevelLock[3] = DecorateWeaponLevelDown_new_WeaponLV3_Mask
	g_WeaponLevelLock[4] = DecorateWeaponLevelDown_new_WeaponLV4_Mask

	g_CurSelExteriorWeaponGroupID = 0
	g_CurSelExteriorWeaponID = 0
	g_CurSelExteriorWeaponLevel = -1
	g_CurEWLevel = -1
	g_CurLimitEWLevel = -1
	g_CurSelItemIndex = 1
end

function DecorateWeaponLevelDown_new_OnEvent(event) 
	if (event == "ADJEST_UI_POS" ) then
		DecorateWeaponLevelDown_new_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DecorateWeaponLevelDown_new_Frame_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DecorateWeaponLevelDown_new_OnHiden()
	elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 89178601 then
		PushEvent( "CLOSE_DRESSPREVIEW")
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")
		Exterior:LuaFnUpdateDressPreviewPlayerData(-1, -1, -1, -1, Player:GetMySex(), 0)
		
		local Type = Get_XParam_INT(0)
		if Type == 1 then       --打开界面
			if this : IsVisible() then	-- 如果界面开着，则不处理
				return
			end

			g_clientNpcId = Get_XParam_INT(1)
			npcObjId = DataPool : GetNPCIDByServerID(g_clientNpcId)
			if npcObjId == -1 then
				PushDebugMessage("未发现 NPC")
				DecorateWeaponLevelDown_new_CloseBtnClick()
				return
			end
		
			this:CareObject( npcObjId, 1, "DecorateWeaponLevelDown_new" )

			this:Show()

			DecorateWeaponLevelDown_new_Init()
		elseif Type == -1 then
			local tolevel = Get_XParam_INT(1)
			if tolevel <1 then
				tolevel = 1
			end
			DecorateWeaponLevelDown_new_SelectLevel(tolevel)--g_CurSelExteriorWeaponLevel)
--			DecorateWeaponLevelDown_new_Init()
			DecorateWeaponLevelDown_new_ItemClicked(g_CurSelItemIndex)
		end
	elseif event == "ADD_EXTERIOR" or event == "UPDATE_EXTERIOR" or event == "EXTERIOR_OUTTIME" or event == "EXTERIOR_ID_CHANGED" then
		if tonumber(arg0) == g_ExteriorType and arg1 ~= nil then
			--先区分这个幻武groupid是否是已经拥有的
			local nExteriorWeaponID = tonumber(arg1)
			
			--先区分这个幻武id是否是属于CurSelExteriorWeaponGroupID这个组里
			g_CurSelExteriorWeaponID = 0
			g_CurSelExteriorWeaponLevel = -1
			g_CurEWLevel = -1
			g_CurLimitEWLevel = -1
			local nIsWeaponIDInGroup = Exterior:LuaFnIsWeaponIDInGroup(g_CurSelExteriorWeaponGroupID, nExteriorWeaponID)
			if nIsWeaponIDInGroup ==1 then
				--在当前组
				if Exterior:LuaFnIsHaveExteriorWeaponGroup(g_CurSelExteriorWeaponGroupID) == 1 then
					--拥有当前组 这种情况不用重新刷新列表
					DecorateWeaponLevelDown_new_ItemClicked(g_CurSelItemIndex)
				end
			else
				DecorateWeaponLevelDown_new_Update()
			end
		end

	end
	
	-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			DecorateWeaponLevelDown_new_OnHiden()
			this:Hide()
		end
	end	
end

function DecorateWeaponLevelDown_new_Frame_On_ResetPos()
	DecorateWeaponLevelDown_new_Frame:SetProperty("UnifiedPosition", g_DecorateWeaponLevelDown_new_Frame_UnifiedPosition);
end

function DecorateWeaponLevelDown_new_Init()
	--左侧展示模型 初始化
	DecorateWeaponLevelDown_new_FakeObject:AttachWindowEx("DecoWeapon_Player")
	SetFakeObjDataEx("DecoWeapon_Player")

	DecorateWeaponLevelDown_new_Update()

--	DecorateWeaponLevelDown_new_RongLianButton:SetToolTip("#{HWSJ_201218_13}")
end

function DecorateWeaponLevelDown_new_Update()
		--右侧上面图鉴列表初始化
	Exterior:LuaFnInitExteriorWeaponGroupList()
	g_MaxBarNum = Exterior:LuaFnGetExteriorWeaponGroupCount()
	g_DataListCount = Exterior:LuaFnGetExteriorListCount(g_ExteriorType, 0)

	DecorateWeaponLevelDown_new_SuperList:Clear()
	for i = 1, g_MaxBarNum do
		local bar = DecorateWeaponLevelDown_new_SuperList:AddChild("DecorateWeaponLevelDown_new_SuperListItem")
		bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
		g_BarList[i] = bar	
		bar:GetSubItem("DecorateWeaponLevelDown_new_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("DecorateWeaponLevelDown_new_ItemClicked(%d)", i))
		bar:GetSubItem("DecorateWeaponLevelDown_new_SuperListItemAction"):SetEvent("MouseMove", string.format("DecorateWeaponLevelDown_new_ItemMouseMove(%d)", i))
		DecorateWeaponLevelDown_new_SetItem(i)
	end
	local curGroupId = Exterior:LuaFnGetWeaponGroupInUse()
	if g_GroupIDTable[curGroupId] ~= nil then
		g_CurSelItemIndex = g_GroupIDTable[curGroupId]
	end
	DecorateWeaponLevelDown_new_ItemClicked(g_CurSelItemIndex)
	
end

--初始化每个图鉴item
function DecorateWeaponLevelDown_new_SetItem(index)
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
	local ctrlAction = bar:GetSubItem("DecorateWeaponLevelDown_new_SuperListItemAction")
	if ctrlAction ~= nil then	
		local strImage = GetIconFullName(strIcon)
		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strTemp = ScriptGlobal_Format("#{WGTJ_201222_78}", strName)
		ctrlAction:SetToolTip(strTemp)
	end

	bar:GetSubItem("DecorateWeaponLevelDown_new_SuperListItemActionTime"):Hide()
	--锁
	if Exterior:LuaFnIsHaveExteriorWeaponGroup(nGroupID) == 1 then
		bar:GetSubItem("DecorateWeaponLevelDown_new_SuperListItemActionLock"):Hide()
	else		
		bar:GetSubItem("DecorateWeaponLevelDown_new_SuperListItemActionLock"):Show()
	end	

end

--点击幻武图鉴item
function DecorateWeaponLevelDown_new_ItemClicked(nIndex)
	local nGroupID 	= Exterior:LuaFnGetWeaponGroupIDFromList(nIndex - 1)	
	if nGroupID<=0 then
		return
	end
	g_CurSelExteriorWeaponGroupID = nGroupID
	if g_CurSelItemIndex ~= nIndex then
		g_CurSelItemIndex = nIndex
		g_CurSelExteriorWeaponLevel = -1
		g_CurEWLevel = -1
		g_CurLimitEWLevel = -1
	end

	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("DecorateWeaponLevelDown_new_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
	
	for i = 1, 5 do	
		local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorWeaponGroupID, i - 1)
		if nExteriorWeaponID ~= nil and nExteriorWeaponID > 0 then
			if i <= 4 then
				g_WeaponLevelAction[i]:Show()
				local strIcon 	= Exterior:LuaFnGetExteriorWeaponInfo(nExteriorWeaponID, "Icon")
				local strName 	= Exterior:LuaFnGetExteriorWeaponInfo(nExteriorWeaponID, "Name")
				local strImage = GetIconFullName(strIcon)
				g_WeaponLevelAction[i]:SetProperty("NormalImage", strImage)
				g_WeaponLevelAction[i]:SetProperty("HoverImage", strImage)
				
				local strTemp = Exterior:LuaFnGetExteriorWeaponToolTip(nExteriorWeaponID)
				g_WeaponLevelAction[i]:SetToolTip(strTemp)
			end
			
			if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorWeaponID) == 1 then
				--有
				local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, nExteriorWeaponID)
				if nLeftTime and nLeftTime >= 0 then
					g_CurLimitEWLevel = i
				else
					g_CurEWLevel = i
				end
			end
		else
			if i <= 4 then
				g_WeaponLevelAction[i]:Hide()
			end
		end			
	end
	--永久
	if g_CurEWLevel > 0 then
		DecorateWeaponLevelDown_new_DangQianDengJiInfo:SetText(ScriptGlobal_Format("#{HSRL_220214_7}", g_CurEWLevel))
	elseif g_CurLimitEWLevel > 0 then
		DecorateWeaponLevelDown_new_DangQianDengJiInfo:SetText(ScriptGlobal_Format("#{HSRL_220214_7}", g_CurLimitEWLevel))
	else
		DecorateWeaponLevelDown_new_DangQianDengJiInfo:SetText("#{HSRL_220214_34}")--未激活
	end
	if g_CurEWLevel <= 1 then
		for i=1,4 do
			g_WeaponLevelLock[i]:Show()
		end
	else
		for i=1,g_CurEWLevel-1 do
			g_WeaponLevelLock[i]:Hide()
		end
		for i=g_CurEWLevel,4 do
			g_WeaponLevelLock[i]:Show()
		end
	end
	DecorateWeaponLevelDown_new_SelectLevel(g_CurSelExteriorWeaponLevel)
end

--悬浮幻武图鉴item
function DecorateWeaponLevelDown_new_ItemMouseMove(nIndex)

end

function DecorateWeaponLevelDown_new_SelectLevel(nLevel)
	if nLevel>4 then
		return
	end
	g_CurSelExteriorWeaponLevel = nLevel
	for i = 1, 4 do
		g_WeaponLevelAction[i]:SetPushed(0)			
	end

	if nLevel>0 then
		g_WeaponLevelAction[nLevel]:SetPushed(1)
	end

	DecorateWeaponLevelDown_new_ShowExteriorWeaponLevelUp()
end

--根据选中的幻武表(Exterior_Weapon)中的id 得到幻武升级相关的数据并显示
function DecorateWeaponLevelDown_new_ShowExteriorWeaponLevelUp()
	--立绘
	if g_CurSelExteriorWeaponLevel == -1 then
		if g_CurEWLevel > 0 then
			local nWeaponID = Exterior:LuaFnGetWeaponEquipIDFromGroup(g_CurSelExteriorWeaponGroupID, g_CurEWLevel - 1)
			--group lel
			
			if nWeaponID ~= nil and nWeaponID > 0 then
				DecoWeaponUI:DecoWeaponAvatarChangeWeapon(nWeaponID)
			end
		elseif g_CurLimitEWLevel > 0 then
			local nWeaponID = Exterior:LuaFnGetWeaponEquipIDFromGroup(g_CurSelExteriorWeaponGroupID, g_CurLimitEWLevel - 1)
			if nWeaponID ~= nil and nWeaponID > 0 then
				DecoWeaponUI:DecoWeaponAvatarChangeWeapon(nWeaponID)
			end
		else

			for i = 1, 5 do	
				local nWeaponID = Exterior:LuaFnGetWeaponEquipIDFromGroup(g_CurSelExteriorWeaponGroupID, i - 1)
				if nWeaponID ~= nil and nWeaponID > 0 then
					DecoWeaponUI:DecoWeaponAvatarChangeWeapon(nWeaponID)
					break;
				end
			end
		end
	else

		local nWeaponID = Exterior:LuaFnGetWeaponEquipIDFromGroup(g_CurSelExteriorWeaponGroupID, g_CurSelExteriorWeaponLevel-1)
		if nWeaponID ~= nil and nWeaponID > 0 then
			DecoWeaponUI:DecoWeaponAvatarChangeWeapon(nWeaponID)
		end
	end
	if g_CurEWLevel < 1 then
		if g_CurLimitEWLevel > 0 then
			DecorateWeaponLevelDown_new_RongLian:Hide()
			DecorateWeaponLevelDown_new_MinLevel:Show()
			DecorateWeaponLevelDown_new_MinLevel:SetText("#{HSRL_220214_27}")
		else
			DecorateWeaponLevelDown_new_RongLian:Hide()
			DecorateWeaponLevelDown_new_MinLevel:Show()
			DecorateWeaponLevelDown_new_MinLevel:SetText("#{HSRL_220214_32}")
		end
	elseif g_CurEWLevel == 1 then
		DecorateWeaponLevelDown_new_RongLian:Hide()
		DecorateWeaponLevelDown_new_MinLevel:Show()
		DecorateWeaponLevelDown_new_MinLevel:SetText("#{HSRL_220214_11}")
		return
	else
		if g_CurSelExteriorWeaponLevel == -1 then
			DecorateWeaponLevelDown_new_RongLian:Hide()
			DecorateWeaponLevelDown_new_MinLevel:Show()
			DecorateWeaponLevelDown_new_MinLevel:SetText("#{HSRL_220214_35}")
			return
		elseif g_CurSelExteriorWeaponLevel >= g_CurEWLevel then
			DecorateWeaponLevelDown_new_RongLian:Hide()
			DecorateWeaponLevelDown_new_MinLevel:Show()
			DecorateWeaponLevelDown_new_MinLevel:SetText("#{HSRL_220214_31}")
			return
		else
			local nExteriorWeaponID = Exterior:LuaFnGetWeaponIDFromGroup(g_CurSelExteriorWeaponGroupID, g_CurSelExteriorWeaponLevel)-- - 1)
			g_CurSelExteriorWeaponID = nExteriorWeaponID
			local DestDecoWeaponId,BindItemId,NeedNum = DecoWeaponUI:GetDecoWeaponLevelDownDataByGroupId(g_CurSelExteriorWeaponGroupID,g_CurEWLevel,g_CurSelExteriorWeaponLevel)
			if DestDecoWeaponId > 0 then
				DecorateWeaponLevelDown_new_RongLian:Show()
				DecorateWeaponLevelDown_new_MinLevel:Hide()
				DecorateWeaponLevelDown_new_HuanWuRongLianInfo:SetText( ScriptGlobal_Format("#{HSRL_220214_10}", NeedNum) )
--				DecoWeaponUI:DecoWeaponAvatarChangeWeapon(DestDecoWeaponId)
			end
		end
	end
end

--点击幻武升级按钮
function DecorateWeaponLevelDown_new_OnOK()

	--判断安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
		return
	end
--	if g_CurSelExteriorWeaponID <= 0 then
--		PushDebugMessage("#{HSRL_220214_17}")
--		return
--	end
	if g_CurSelExteriorWeaponLevel < 0 then
		PushDebugMessage("#{HSRL_220214_17}")
		return
	end

	if g_CurEWLevel < 1 and g_CurLimitEWLevel > 0 then
		PushDebugMessage("#{HSRL_220214_28}")
		return
	end

	if g_CurEWLevel < 1 then
		PushDebugMessage("#{HSRL_220214_33}")
		return
	end
	if g_CurEWLevel == 1 then
		PushDebugMessage("#{HSRL_220214_29}")
		return
	end
	if g_CurSelExteriorWeaponLevel < 1 then
		PushDebugMessage("#{HSRL_220214_17}")
		return
	end
--PushDebugMessage("g_CurSelExteriorWeaponLevel="..g_CurSelExteriorWeaponLevel.." g_CurEWLevel="..g_CurEWLevel)
	if g_CurSelExteriorWeaponLevel >= g_CurEWLevel then
		PushDebugMessage("#{HSRL_220214_30}")
		return
	end
	local DestDecoWeaponId,BindItemId,NeedNum = DecoWeaponUI:GetDecoWeaponLevelDownDataByGroupId(g_CurSelExteriorWeaponGroupID,g_CurEWLevel,g_CurSelExteriorWeaponLevel)
	if DestDecoWeaponId > 0 then
		PushEvent("DECOWEAPON_LEVELDOWN_CONFIRM",g_clientNpcId,g_CurSelExteriorWeaponID,g_CurSelExteriorWeaponGroupID,g_CurSelExteriorWeaponLevel,NeedNum)
	end

end


--界面隐藏
function DecorateWeaponLevelDown_new_OnHiden()

	g_clientNpcId = -1
	DecorateWeaponLevelDown_new_FakeObject:DetachWindowEx("DecoWeapon_Player")

	g_CurSelExteriorWeaponGroupID = 0
	g_CurSelExteriorWeaponID = 0
	g_CurSelExteriorWeaponLevel = -1
	g_CurSelItemIndex = 1
	g_GroupIDTable = {}
	g_CurEWLevel = -1
	g_CurLimitEWLevel = -1
end

--点击关闭按钮
function DecorateWeaponLevelDown_new_CloseBtnClick()
	this:Hide()
end


function DecorateWeaponLevelDown_new_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			DecorateWeaponLevelDown_new_FakeObject:RotateBeginEx("DecoWeapon_Player", -0.3);
		--向左旋转结束
		else
			DecorateWeaponLevelDown_new_FakeObject:RotateEndEx();
		end
	end
end


function DecorateWeaponLevelDown_new_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			DecorateWeaponLevelDown_new_FakeObject:RotateBeginEx("DecoWeapon_Player", 0.3);
		--向右旋转结束
		else
			DecorateWeaponLevelDown_new_FakeObject:RotateEndEx();
		end
	end
end
