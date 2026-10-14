-- 2019七夕制婚服 婚服升级

local g_Frame_UnifiedPosition
local g_Index = -1
local g_ItemIndex = -1
local g_StartTime = 20220729
local g_EndTime = 20220817
--local objCared = -1;
function QiXi_Levelup_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HUNFU_UPDATA",false)

end

function QiXi_Levelup_OnLoad()
	
	g_Frame_UnifiedPosition = QiXi_Levelup_Frame:GetProperty("UnifiedPosition") 
	
	QiXi_Levelup_Clear()
	
end

function QiXi_Levelup_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 893126004 then
	
		if this:IsVisible() then
			QiXi_Levelup_OnClosed()
		end
		-- index:1.限时升级永久,2.低级升级高级
		local index = Get_XParam_INT(0)
		
		-- objCared = -1;
		-- local xx = Get_XParam_INT(1);
		-- objCared = DataPool : GetNPCIDByServerID(xx);

		-- if objCared == nil or objCared == -1 then
			-- return;
		-- end
		
		-- QiXi_Levelup_CareObj(objCared)
		
		if index == 1 then
			-- QiXi_Levelup_Button01:SetCheck(1)
			-- QiXi_Levelup_Button02:SetCheck(0)
			QiXi_Levelup_Pic1:Show()
			--QiXi_Levelup_Pic2:Hide()
			QiXi_Levelup_DragTitle:SetText("#{QXHF_190620_84}")
			QiXi_Levelup_Text:SetText("#{QXHF_190620_85}")
			QiXi_Levelup_Cloth:SetText("#{QXHF_190620_86}")
			QiXi_Levelup_Goods:SetText("#{QXHF_190620_87}")
			g_Index = 1
			local theAction1 = DataPool:CreateActionItemForShow(39921755, 1)
			if theAction1:GetID() ~= 0 then
				QiXi_Levelup_Item02:SetActionItem(theAction1:GetID())
			else
				QiXi_Levelup_Item02:SetActionItem(-1);		
			end
			this:Show()
		elseif index == 2 then
			-- QiXi_Levelup_Button02:SetCheck(1)
			-- QiXi_Levelup_Button01:SetCheck(0)
			-- QiXi_Levelup_Pic1:Hide()
			-- QiXi_Levelup_Pic2:Show()
			-- QiXi_Levelup_DragTitle:SetText("#{QXHF_190620_96}")
			-- QiXi_Levelup_Text:SetText("#{QXHF_190620_97}")
			-- QiXi_Levelup_Cloth:SetText("#{QXHF_190620_98}")
			-- QiXi_Levelup_Goods:SetText("#{QXHF_190620_99}")
			-- g_Index = 2
			-- local theAction1 = DataPool:CreateActionItemForShow(39921756, 1)
			-- if theAction1:GetID() ~= 0 then
				-- QiXi_Levelup_Item02:SetActionItem(theAction1:GetID())
			-- else
				-- QiXi_Levelup_Item02:SetActionItem(-1);		
			-- end
			-- this:Show()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		QiXi_Levelup_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
	
		QiXi_Levelup_OnClosed()
		
	elseif event == "ADJEST_UI_POS" then
	
		QiXi_Levelup_On_ResetPos()
		
	elseif event == "HUNFU_UPDATA" then
	
		if g_Index == 1 then
			
			if arg0~= nil then
				if tonumber(arg0) == 2 then
					PushDebugMessage("#{QXHF_190620_88}")
					return
				end
				if tonumber(arg0) == 3 then
					PushDebugMessage("#{QXHF_190620_145}")
					return
				end
				QiXi_Levelup_Updata1(arg0,arg1)
			end	
			
		elseif g_Index == 2 then
			
			if arg0~= nil then
				if tonumber(arg0) == 2 then
					PushDebugMessage("#{QXHF_190620_101}")
					return
				end
				if tonumber(arg0) == 3 then
					PushDebugMessage("#{QXHF_190620_145}")
					return
				end
				QiXi_Levelup_Updata2(arg0,arg1)
			end	
			
		end
	end
	
end

--=========
-- 重置
--=========
function QiXi_Levelup_On_ResetPos()

	QiXi_Levelup_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 关闭
--=========
function QiXi_Levelup_OnClosed()
	
	QiXi_Levelup_Clear()
	--QiXi_Levelup_StopCareObj(objCared)
	this:Hide()
	
end

function QiXi_Levelup_Clear()

	LifeAbility : Lock_Packet_Item(g_ItemIndex,0)
	QiXi_Levelup_DragTitle:SetText("")
	QiXi_Levelup_Text:SetText("")
	QiXi_Levelup_Cloth:SetText("")
	QiXi_Levelup_Goods:SetText("")
	QiXi_Levelup_Item02:SetActionItem(-1);		
	QiXi_Levelup_Item:SetActionItem(-1);		
	g_Index = -1
	g_ItemIndex = -1
	-- QiXi_Levelup_Button01:SetCheck(0)
	-- QiXi_Levelup_Button02:SetCheck(0)
	QiXi_Levelup_Pic1:Hide()
	--QiXi_Levelup_Pic2:Hide()
	
end

--=========
-- 限时升级永久
--=========
function QiXi_Levelup_Updata1(UI_index,Item_index)

	local i_index = tonumber(Item_index)
	local u_index = tonumber(UI_index)
	
	QiXi_Levelup_Item:SetActionItem(-1)
	if g_ItemIndex >= 0 then 
		LifeAbility : Lock_Packet_Item(g_ItemIndex,0)
	end
	
	local nitemTableIndex = PlayerPackage : GetItemTableIndex( i_index )
	if nil == nitemTableIndex then
		return
	end
		
	-- 只有限时的才能升级为永久的
	if 10125215 ~= nitemTableIndex then
		PushDebugMessage("#{QXHF_190620_88}")
		return
	end
	
	local theAction = EnumAction(i_index, "packageitem")
	
	g_ItemIndex = i_index
	
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay < g_StartTime or curDay > g_EndTime then
		PushDebugMessage("#{QXHF_190620_81}")
		return
	end

	local nLevel = Player:GetLevel();
	if nLevel < 30 then
		PushDebugMessage("#{QXHF_190620_82}")
		return
	end
	
	if theAction:GetID() ~= 0 then
	
		QiXi_Levelup_Item:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(i_index,1);
		PushDebugMessage("#{QXHF_190620_89}")
	
	else
		QiXi_Levelup_Item:SetActionItem(-1);			
		LifeAbility : Lock_Packet_Item(i_index,0)
	end
	
	
end

--=========
-- 低级升级高级
--=========
function QiXi_Levelup_Updata2(UI_index,Item_index)

	local i_index = tonumber(Item_index)
	local u_index = tonumber(UI_index)
	
	local nitemTableIndex = PlayerPackage : GetItemTableIndex( i_index )
	if nil == nitemTableIndex then
		return
	end
		
	-- 只有低级永久的才能升级为高级的
	if 10125216 ~= nitemTableIndex and nitemTableIndex ~= 10125218 then
		PushDebugMessage("#{QXHF_190620_101}")
		return
	end

	QiXi_Levelup_Item:SetActionItem(-1)
	if g_ItemIndex >= 0 then 
		LifeAbility : Lock_Packet_Item(g_ItemIndex,0)
	end
	
	local theAction = EnumAction(i_index, "packageitem")
	
	g_ItemIndex = i_index
	
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay < g_StartTime or curDay > g_EndTime then
		PushDebugMessage("#{QXHF_190620_93}")
		return
	end

	local nLevel = Player:GetLevel();
	if nLevel < 30 then
		PushDebugMessage("#{QXHF_190620_94}")
		return
	end
	
	
	if theAction:GetID() ~= 0 then
	
		QiXi_Levelup_Item:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(i_index,1);
		PushDebugMessage("#{QXHF_190620_102}")
		
	else
		QiXi_Levelup_Item:SetActionItem(-1);			
		LifeAbility : Lock_Packet_Item(i_index,0)
	end
	
	
end

function QiXi_Levelup_Item_RClick()
	
	if g_ItemIndex >= 0 then 
		local theAction = EnumAction(g_ItemIndex, "packageitem")
		if theAction:GetID() ~= 0 then
			QiXi_Levelup_Item:SetActionItem(-1);			
			LifeAbility : Lock_Packet_Item(g_ItemIndex,0)
			g_ItemIndex = -1
		end
	end
	
end

function QiXi_Levelup_Buttons_Clicked()
	
	if g_Index == 1 then
		if g_ItemIndex == -1 then
			PushDebugMessage("#{QXHF_190620_88}")
			return
		end
	elseif g_Index == 2 then
		if g_ItemIndex == -1 then
			PushDebugMessage("#{QXHF_190620_101}")
			return
		end
	else
		return
	end
	
	if g_ItemIndex == -1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HunFuLevelup" )
		Set_XSCRIPT_ScriptID( 893126 )
		Set_XSCRIPT_Parameter(0, g_Index)
		Set_XSCRIPT_Parameter(1, g_ItemIndex)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	
	
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
-- function QiXi_Levelup_CareObj(objCaredId)

	-- g_Object = objCaredId;

	-- this:CareObject(g_Object, 1, "QiXi_Levelup");

-- end

--=========================================================
--停止对某NPC的关心
--=========================================================
-- function QiXi_Levelup_StopCareObj(objCaredId)
	-- this:CareObject(objCaredId, 0, "QiXi_Levelup");
	-- g_Object = -1;

-- end

function QiXi_Levelup_PageClick(index)
	
	if index ~= 1 and index ~= 2 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenHunFuLevelUpUI" )
		Set_XSCRIPT_ScriptID( 893126 )
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end


