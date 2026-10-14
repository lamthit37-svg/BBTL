local objCared = -1;			--关心NPC与否
local GEMSOURCE_BUTTONS = -1 	--控件：源宝石框
local GEMDEST_BUTTONS = -1 		--控件：目的宝石框
local EQUIPITEM_SOURCE = -1		--空否：源宝石框
local EQUIPITEM_DEST = -1		--空否：目的宝石框
local CostYuanBao_Total = ""	--转换需要消耗的元宝
local bConfirm = -1				--二次确认框，弹出来了吗
local Gem_Source_ItemID = -1	--源宝石ID
local Gem_Source_ItemType = -1	--源宝石Type
local Gem_Source_ItemLevel = -1	--源宝石Level
local Gem_Source_Bind = 0		--源宝石Bind与否
local Gem_Select_ItemID = -1	--目的宝石ID
local Gem_Source_Name = ""		--源宝石Name
local Gem_Dest_Name = ""		--目的宝石Name
local MAX_OBJ_DISTANCE = 3.0	--对话框关闭距离
local Cost_YuanBao = {			--不同类型宝石，消耗元宝配表
[5] = {normal=4200, 	special=4200*3},
[6] = {normal=19200, 	special=19200*3},
[7] = {normal=96000, 	special=96000*3},
[8] = {normal=384000,	special=384000*3},
[9] = {normal=1536000, 	special=1536000*3},
}

function GemChange_PreLoad()
	this:RegisterEvent("UI_COMMAND"); 				 --作用：打开宝石转换界面
	this:RegisterEvent("OBJECT_CARED_EVENT",false); 		 --作用：关闭宝石转换界面
	this:RegisterEvent("UPDATE_BAOSHI_CHANGE");		 --作用：宝石转换源宝石刷新
	this:RegisterEvent("UPDATE_YUANBAO", false);			 --作用：宝石转换界面元宝刷新
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);		 --作用：源宝石拖回背包里
	this:RegisterEvent("SHOW_SELECT_BAOSHI");		 --作用：宝石转换目的宝石刷新
	this:RegisterEvent("BAOSHI_CHANGE_CONFIRM");	 --作用：宝石转换的二次确认：打开界面
	this:RegisterEvent("BAOSHI_CHANGE_CONFIRM_TRUE");--作用：宝石转换的二次确认：再次确认，不再打开界面
	this:RegisterEvent("BAOSHI_CHANGE_CONFIRM_CANCEL"); --//By YPL,2013/3/6	
end

function GemChange_OnLoad()
	GEMSOURCE_BUTTONS = GemChange_InputGemIcon;
	GEMDEST_BUTTONS = GemChange_OutputGemIcon;
	EQUIPITEM_SOURCE = -1;
	EQUIPITEM_DEST = -1;
	GemChange_Select:Disable(); --"选择宝石"按钮状态： 置灰
	CostYuanBao_Total = "";
	GemChange_WantNum:SetText(""..CostYuanBao_Total);
	GemChange_HaveNum:SetText(""..tostring(Player:GetData("YUANBAO")));
	GemChange_OK:Disable();	--"确定"按钮状态： 置灰
end

--检查时机：当左键拖动或右键点击背包宝石，到宝石转换界面的框内时
function GemChange_CheckBaoshi(Item_index)

	local pos_packet = tonumber(Item_index)
	
	--条件1：放入物品是宝石吗
	local Item_Class = PlayerPackage : GetItemSubTableIndex(pos_packet,0)
	local Gem_Type = PlayerPackage : GetGemChangeRule(pos_packet)
	if (Item_Class ~= 5) or (Item_Class == 5 and Gem_Type == 6) then
		PushDebugMessage("#{BSZH_130220_14}")
		return 0
	end	

	--条件2：放入的是通宝宝石吗
	if Gem_Type == 4 then
		PushDebugMessage("#{BSZH_130220_15}")
		return 0
	end

	--条件3：放入的是冥晶石吗
	if Gem_Type == 5 then
		PushDebugMessage("#{BSZH_130220_16}")
		return 0
	end

	--条件4：放入的是宝石等级不低于5级吗
	local GemLevel = PlayerPackage : GetItemSubTableIndex(pos_packet,1)
	if GemLevel < 5 then
		PushDebugMessage("#{BSZH_130220_14}")
		return 0
	end
	
	if GemLevel > 8 then
		--PushDebugMessage("#{BSZH_130220_28}")
		return 0
	end
	 
	--条件5：放入的是宝石已加锁了吗
	if PlayerPackage:IsLock(pos_packet) == 1 then
		PushDebugMessage("#{BSZH_130220_17}")
		return 0	
	end

	--条件6：宝石框内有宝石吗
	if PlayerPackage:IsGem(pos_packet) ~= 1 then
		return 0	
	end		
	
	return 1;
end

function GemChange_Update(UI_index, Item_index, param2, param3)
	
	local i_index = tonumber(Item_index)
	local ui_index = tonumber(UI_index)
	if ui_index < 0 or ui_index > 1 then
		return
	end
	
	--先判断物品是否符合放入的条件，才可进行后续逻辑 ！！！！！！！！！！！！！！！必须保证这一步，否则会有各种异常问题！！！！！！！！！！！！！！！
	if GemChange_CheckBaoshi(i_index) == 0 then
		return
	end


	--分期付款宝石
	local bBP_Gem = BudgetPlanGem: IsBudgetPlanGem( i_index )
	if bBP_Gem > 0 then
		PushDebugMessage("#{FQBS_140508_63}")
		return
	end

	local theAction = EnumAction(i_index, "packageitem");

	GemChange_HaveNum:SetText(""..tostring(Player:GetData("YUANBAO")));
	
	Gem_Source_ItemID = theAction:GetDefineID();
	Gem_Source_ItemType = PlayerPackage : GetGemChangeRule(i_index)
	Gem_Source_ItemLevel = PlayerPackage : GetItemSubTableIndex(i_index,1)
	Gem_Source_Name = theAction:GetName();
	Gem_Source_Bind = PlayerPackage:GetItemBindStatusByIndex(i_index);

	if theAction:GetID() ~= 0 then
	
		--先判断物品是否符合放入的条件，才可进行后续逻辑 ！！！！！！！！！！！！！！！必须保证这一步，否则会有各种异常问题！！！！！！！！！！！！！！！
		if GemChange_CheckBaoshi(i_index) == 0 then
			return 			
		end
	
		-- --宝石移动：背包->框
		-- --移动方式：右键点击
		-- if ui_index == 0 then
			-- --点击前，框内状态：无宝石
			-- if EQUIPITEM_SOURCE == -1 then
				-- GEMSOURCE_BUTTONS:SetActionItem(theAction:GetID());
				-- LifeAbility : Lock_Packet_Item(i_index,1);
				-- EQUIPITEM_SOURCE = i_index;
				-- GemChange_Select:Enable(); --"选择宝石"按钮状态：可点击
				-- GemChange_Flush_DestGemList(); --刷新匹配宝石列表
			-- --点击前，框内状态：有宝石
			-- else
				-- GemChange_Clear();
				-- GEMSOURCE_BUTTONS:SetActionItem(theAction:GetID());
				-- LifeAbility : Lock_Packet_Item(i_index,1);
				-- EQUIPITEM_SOURCE = i_index;
				-- GemChange_Select:Enable(); --"选择宝石"按钮状态：可点击
				-- GemChange_Flush_DestGemList(); --刷新匹配宝石列表	
			-- end
		-- --宝石移动：背包->框
		-- --移动方式：左键拖动
		-- elseif ui_index == 1 then 
				-- GemChange_Clear();
				-- GEMSOURCE_BUTTONS:SetActionItem(theAction:GetID());
				-- LifeAbility : Lock_Packet_Item(i_index,1);
				-- EQUIPITEM_SOURCE = i_index;	
				-- GemChange_Select:Enable(); --"选择宝石"按钮状态：可点击
				-- GemChange_Flush_DestGemList(); --刷新匹配宝石列表
		-- end
		
		-- GemChange_Need_YuanBao_Flush(param2, param3);
		
		if ui_index == 0 or ui_index == 1 then
				GemChange_Clear();
				GEMSOURCE_BUTTONS:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(i_index,1);
				EQUIPITEM_SOURCE = i_index;	
				GemChange_Select:Enable(); --"选择宝石"按钮状态：可点击
				GemChange_Flush_DestGemList(); --刷新匹配宝石列表
				GemChange_Need_YuanBao_Flush(param2, param3);
		end		
	end
end

function GemChange_OnEvent(event)

	if (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		if((arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE) or arg1=="destroy") then		
			--取消关心
			GemChange_Cancel_Clicked()
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0)== 201302201 ) then
	
		if this:IsVisible() then
			GemChange_Close()
		end
		
		this:Show();
		GemChange_OnLoad();
		objCared = -1;
		local xx = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(xx);
		if objCared == -1 then
				return;
		end
		GemChange_BeginCareObject(objCared)
		return
	elseif ( event == "UPDATE_BAOSHI_CHANGE" and this:IsVisible() ) then
		GemChange_Update(arg0, arg1, arg2, arg3);
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		GemChange_HaveNum:SetText(""..tostring(Player:GetData("YUANBAO")));
	 elseif event == "RESUME_ENCHASE_GEM_EX" and this : IsVisible() then
		 GemChange_Clear()
		 GemChange_Select:Disable(); --"选择宝石"按钮状态：可点击
		 CloseWindow("GemList", true)
	elseif (event == "SHOW_SELECT_BAOSHI" and this:IsVisible()) then --目的宝石放入目的框内
		bConfirm = -1
		local nProductID = tonumber(arg0)
		local ProductAction = DoubleGem:UpdateProductAction( nProductID)
		if ProductAction and ProductAction:GetID() ~= 0 then
			GEMDEST_BUTTONS:SetActionItem(ProductAction:GetID());
			Gem_Select_ItemID=nProductID
			EQUIPITEM_DEST = nProductID
			Gem_Dest_Name = ProductAction:GetName()
			GemChange_OK:Enable();
		else
			GEMDEST_BUTTONS:SetActionItem(-1);
			Gem_Select_ItemID=-1
		end
	elseif (event == "BAOSHI_CHANGE_CONFIRM_TRUE" and this:IsVisible()) then --作用：宝石转换的二次确认：再次确认，不再打开界面
		GemChange_Buttons_Clicked();
	elseif (event == "BAOSHI_CHANGE_CONFIRM_CANCEL" and this:IsVisible()) then
		bConfirm = -1		
	end

end

function GemChange_Clear()
	if (EQUIPITEM_SOURCE ~= -1) then
		GEMSOURCE_BUTTONS:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(EQUIPITEM_SOURCE,0);
		EQUIPITEM_SOURCE = -1
	end
	
	if (EQUIPITEM_DEST ~= -1) then
		GEMDEST_BUTTONS:SetActionItem(-1);
		EQUIPITEM_DEST = -1
	end	
	
	GemChange_Select:Disable();
	CostYuanBao_Total = ""
	GemChange_WantNum:SetText(""..CostYuanBao_Total);	
	GemChange_OK:Disable();
	bConfirm = -1
	Gem_Source_Bind = 0
end

function GemChange_Close()
	GemChange_Clear()
	this:Hide()
	CloseWindow("GemList", true)
end

function GemChange_Cancel_Clicked()
	GemChange_Close();
	return;
end

function GemChange_Buttons_Clicked()

	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
		return
	end
	
	if GemChange_CheckBaoshi(EQUIPITEM_SOURCE) ~=1 then
		return
	end
	
	--条件7：目标宝石是否符合转换规则
	if GetGemChangRule(Gem_Source_ItemID) == -1 or GetGemChangRule(Gem_Select_ItemID) == -1 then
		return
	end
	if GetGemChangRule(Gem_Source_ItemID) ~= GetGemChangRule(Gem_Select_ItemID) then
		PushDebugMessage("#{BSZH_130220_19}")
		return
	end
	
	--条件8：玩家元宝是否足够
	if Player:GetData("YUANBAO") < CostYuanBao_Total then
		PushDebugMessage("#{BSZH_130220_20}")
		return
	end
	
	if bConfirm == -1 then
		PushEvent("BAOSHI_CHANGE_CONFIRM", tostring(Gem_Source_Name), tostring(Gem_Dest_Name), tonumber(CostYuanBao_Total))--弹出确认框
		bConfirm = 1
	elseif bConfirm == 1 then
		bConfirm = 2
	elseif bConfirm == 2 then
		--在这里向Client发包，到server和world上去，开始扣元宝，换宝石
		LifeAbility : Do_Gem_Change("change", tonumber(EQUIPITEM_SOURCE), tonumber(Gem_Select_ItemID))
		GemChange_Clear();
		bConfirm = -1
		--转换确认后，关闭宝石列表界面
		CloseWindow("GemList", true);			
	end
	
end


--宝石移动：框->背包
--移动方式：右键点击
--参数含义：1，源宝石的框；2，目的宝石的框。
function GemChange_Resume_Equip(nIndex)

	if nIndex ~=1 then
		return
	end
	
	if (nIndex == 1) and (EQUIPITEM_SOURCE ~= -1) then
		GEMSOURCE_BUTTONS:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(EQUIPITEM_SOURCE,0);
		EQUIPITEM_SOURCE = -1
		GemChange_Select:Disable(); --"选择宝石"按钮状态：不可点击
		CloseWindow("GemList", true)

		GEMDEST_BUTTONS:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(EQUIPITEM_DEST,0);
		EQUIPITEM_DEST = -1	
		
		--元宝石框清空后，消耗元宝数清空
		CostYuanBao_Total = ""
		GemChange_WantNum:SetText(""..CostYuanBao_Total);
		
		--元宝石框清空后，交易确定按钮变灰
		GemChange_OK:Disable();	
		GemChange_Clear(); ---------------------20130304			
	end
	
end

--打开界面：与源宝石匹配的宝石列表所在的界面(GemList)
function GemChange_Open_DestGemList()
	if EQUIPITEM_SOURCE ~= -1 then
		CGemChangeDataPool:RequestDestGemList(Gem_Source_ItemID, Gem_Source_ItemType, Gem_Source_ItemLevel, Gem_Source_Bind);
		OpenWindow("GemList");
	end
end

--不打开界面，只刷新宝石列表：与源宝石匹配的宝石列表所在的界面(GemList)
function GemChange_Flush_DestGemList()
	if EQUIPITEM_SOURCE ~= -1 then
		CGemChangeDataPool:RequestDestGemList(Gem_Source_ItemID, Gem_Source_ItemType, Gem_Source_ItemLevel, Gem_Source_Bind);
	end
end

function GemChange_BeginCareObject(objCaredId)
	this:CareObject(objCaredId, 1, "GemChange");
end

function GemChange_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "GemChange");
end

function GemChange_OnHidden()
	GemChange_StopCareObject(objCared)
	GemChange_Close()
	return
end

function GemChange_Help_Clicked()
	Helper:GotoHelper("*GemChange")
end

function GemChange_Need_YuanBao_Flush(param2, param3)

	local gem_level = tonumber(param2) --源宝石：等级
	local gem_type  = tonumber(param3) --源宝石：类别
	
	if Cost_YuanBao[gem_level] ~= nil then
		if gem_type == 3 then
			CostYuanBao_Total = Cost_YuanBao[gem_level].special
		else
			CostYuanBao_Total = Cost_YuanBao[gem_level].normal
		end
		GemChange_WantNum:SetText(""..CostYuanBao_Total);
	else
		GemChange_WantNum:SetText("");
	end
	
end