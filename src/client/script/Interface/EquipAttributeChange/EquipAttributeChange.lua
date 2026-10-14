-- 手工装备属性重铸 2019-2-19
-- !!!reloadscript =EquipAttributeChange

local g_ContralList = {}
local g_IsWashed = 0
local g_EquipAttributeChange_Item = -1
local g_EquipAttributeChange_Confirm = -1	--绑定状态二次确认
-- Type1 = 38002727, --紫金玉　1	绑定
-- Type2 = 38002728, --紫金玉　1	非绑定
-- Type3 = 38002729, --紫金玉　1	元宝交易
-- Name  = "紫金玉",
local g_binditem 	= {38000953, 38000956, 38002727}
local g_unbinditem 	= {38000954, 38000957, 38002728}
local g_yuanbaoitem = {38000955, 38000958, 38002729}

local g_EquipAttributeChange_NPCID = -1
local g_EquipAttributeChange_objCared = -1
local g_EquipAttributeChange_OBJDISTANCE =3.0;

local g_EquipAttributeChange_Frame_UnifiedPosition = nil

-- 放入装备的错误提示 分别对应 1、不是手工装备 2、是武器也不行 3、等级 4、未鉴定;
local strInputErrorMsgFor9 	= {"#{JXCZ_190213_61}", "#{ZBCZ_140618_18}", "#{JXCZ_190213_61}", "#{ZBCZ_140618_30}"}
local strInputErrorMsgFor78 = {"#{ZBCZ_140618_17}", "#{ZBCZ_140618_18}", "#{ZBCZ_140618_19}", "#{ZBCZ_140618_20}"}

-- 检测装备的错误提示 分别对应 1、不是手工装备 2、是武器也不行 3、等级 4、未鉴定;
local strCheckErrorMsgFor9 	= {"#{JXCZ_190213_61}", "#{ZBCZ_140618_18}", "#{JXCZ_190213_61}", "#{ZBCZ_140618_30}"}
local strCheckErrorMsgFor78 = {"#{ZBCZ_140618_28}", "#{ZBCZ_140618_29}", "#{ZBCZ_140618_28}", "#{ZBCZ_140618_30}"}

-- 界面类型，1:9星，其他7、8星
local g_nUIType		= 0

function EquipAttributeChange_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("EQUIP_CHANGE_ATTR");
	this:RegisterEvent("EQUIPATTR_CHANGEEQUIP_CONFIRM_OK")
	this:RegisterEvent("RESUME_ENCHASE_GEM")
	this:RegisterEvent("EQUIPATTR_BIND_CONFIRM_OK")
	this:RegisterEvent("EUQIPATTR_UPDATE_RECOIN")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function EquipAttributeChange_OnLoad()
	g_ContralList = {
								ActionButton = EquipAttributeChange_Object,
								TextBefore = EquipAttributeChange_Bk1_Text2,
								TextAfter = EquipAttributeChange_Bk2_Text2,
								recoinButton = EquipAttributeChange_OK,
								obj2 = EquipAttributeChange_Object2,
							}
	g_EquipAttributeChange_Frame_UnifiedPosition = EquipAttributeChange_Frame:GetProperty("UnifiedPosition");

end

function EquipAttributeChange_OnEvent(event)
	if (event == "UI_COMMAND") and  tonumber(arg0) == 20140618 then
		g_EquipAttributeChange_NPCID = Get_XParam_INT(0);
		g_nUIType	= Get_XParam_INT(1) 
		if nil == g_nUIType then
			g_nUIType = 0
		end
		g_EquipAttributeChange_objCared = DataPool:GetNPCIDByServerID(g_EquipAttributeChange_NPCID);
		EquipAttributeChange_BeginCareObject(g_EquipAttributeChange_objCared)
		-- 根据界面类型设置标题和介绍
		if 1 == g_nUIType then
			-- 9星
			EquipAttributeChange_Title 		: SetText("#{JXCZ_190213_10}")
			EquipAttributeChange_Info		: SetText("#{JXCZ_190213_11}")
			EquipAttributeChange_PutText	: SetText("#{JXCZ_190213_12}")
		else
			-- 7、8星
			EquipAttributeChange_Title 		: SetText("#{ZBCZ_140618_03}")
			EquipAttributeChange_Info		: SetText("#{ZBCZ_140618_04}")
			EquipAttributeChange_PutText	: SetText("#{ZBCZ_140618_05}")
		end

		EquipAttributeChange_Clear(1)
		-- 关掉材料升级界面和商店界面
		if(IsWindowShow("Shop")) then
			CloseWindow("Shop", true)
		end
		if(IsWindowShow("StarsNineSJ")) then
			CloseWindow("StarsNineSJ", true)
		end
		this:Show()
	elseif (event == "UI_COMMAND" ) and tonumber(arg0) == 201406181 then
		EquipAttributeChange_Clear(0)
		EquipAttributeChange_Update(g_EquipAttributeChange_Item)	
	elseif(event == "EQUIP_CHANGE_ATTR") then
		-- 放入事件 Action逻辑
		if this:IsVisible() then
			EquipAttributeChange_Input(tonumber(arg0), tonumber(arg1), tonumber(arg2))
		end
		
	elseif (event == "EQUIPATTR_CHANGEEQUIP_CONFIRM_OK") then
		if tonumber(arg1) == 1 then
			EquipAttributeChange_Clear(1) --先把原来的清空了
			EquipAttributeChange_Update(arg0) --再放上新的~
		elseif tonumber(arg1) == 0 then
			EquipAttributeChange_Clear(1)
			this:Hide()
		elseif tonumber(arg1) == 2 then
			EquipAttributeChange_Clear(1) --先把原来的清空了
		end
	elseif (event == "RESUME_ENCHASE_GEM") then
		EquipAttributeChange_TryClear()
	elseif (event == "EQUIPATTR_BIND_CONFIRM_OK") then
		g_EquipAttributeChange_Confirm = 1
	elseif (event == "EUQIPATTR_UPDATE_RECOIN") then
		--更新重启的属性
		EquipAttributeChange_UpDateRecoin()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_EquipAttributeChange_objCared) then
			return;
		end
		
		if(arg1 == "distance" and tonumber(arg2) > g_EquipAttributeChange_OBJDISTANCE or arg1=="destroy" ) then
			EquipAttributeChange_Clear(1) --先把原来的清空了
			this:Hide()
		end	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
			EquipAttributeChange_Clear(1) --先把原来的清空了
			this:Hide()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		EquipAttributeChange_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipAttributeChange_ResetPos()
	end
end

--=========================================================
-- 放入事件 处理错误提示
--=========================================================
function EquipAttributeChange_Input(nErrorNo, nBagPos, nEquipQual)
	if nil == nErrorNo or nil == nBagPos or nil == nEquipQual then
		return
	end

	-- PushDebugMessage("nErrorNo"..nErrorNo.."nBagPos"..nBagPos.."nEquipQual"..nEquipQual)

	-- 各种错误提示
	if 1 == g_nUIType then
		-- 9星界面
		if nErrorNo > 0 then
			local strErrorMsg = strInputErrorMsgFor9[nErrorNo]
			if nil == strErrorMsg then
				strErrorMsg = tostring(nErrorNo)
			end
			PushDebugMessage(strErrorMsg)
			return
		end

		if nEquipQual ~= 9 then
			PushDebugMessage("#{JXCZ_190213_62}")
			return
		end
	else
		-- 非九星界面
		if nErrorNo > 0 then
			local strErrorMsg = strInputErrorMsgFor78[nErrorNo]
			if nil == strErrorMsg then
				strErrorMsg = tostring(nErrorNo)
			end
			PushDebugMessage(strErrorMsg)
			return
		end

		if nEquipQual ~= 7 and nEquipQual ~= 8 then
			PushDebugMessage("#{ZBCZ_140618_21}")
			return
		end
	end

	-- 更新ActionButton
	EquipAttributeChange_Update(nBagPos)

end

function EquipAttributeChange_UpDateRecoin()
	local num =  DataPool : Lua_GetRecoinNum();
	
	local str = ""
	for i = 0, num-1 do
		local tempstr = DataPool :Lua_GetRecoinEnumAttr(i)
		str = str..tempstr
	end	
	
	g_ContralList.TextAfter:SetText(str)
	EquipAttributeChange_Bk1_Btn:Enable()
	EquipAttributeChange_Bk2_Btn:Enable()
end


function EquipAttributeChange_OnHiden()
	EquipAttributeChange_Clear(1) --先把原来的清空了
end


function EquipAttributeChange_Close()
	--关闭前也要来个二次确认
	if g_EquipAttributeChange_Item ~= -1 and  g_IsWashed == 1 then
		EquipEducation_SendChageEquipConfirm(g_EquipAttributeChange_Item,0)
		return
	end
	EquipAttributeChange_Clear(1)
	this:Hide()
end

function EquipAttributeChange_Clear(cleanaction)

	g_IsWashed = 0
	g_EquipAttributeChange_Confirm = -1
	g_ContralList.TextBefore:SetText("")
	g_ContralList.TextAfter:SetText("")
	EquipAttributeChange_CaiLiaoText:SetText("")
	g_ContralList.recoinButton:Disable()
	g_ContralList.obj2:SetProperty("Image","")
	EquipAttributeChange_Bk1_Btn:Disable()
	EquipAttributeChange_Bk2_Btn:Disable()
	if cleanaction == 1 then
		if g_EquipAttributeChange_Item ~= -1 then
			g_ContralList.ActionButton:SetActionItem(-1)
			LifeAbility:Lock_Packet_Item(g_EquipAttributeChange_Item, 0)
			g_EquipAttributeChange_Item = -1
		end
	end
end

function EquipAttributeChange_Update(pageIndex)
	local index = tonumber(pageIndex)
	
	local theAction = EnumAction(index, "packageitem")
	
	if theAction:GetID() ~= 0 then
	
		-- 如果空格内已经有对应物品了,需要弹一个二次确认……
		if g_EquipAttributeChange_Item ~= -1 and index ~= g_EquipAttributeChange_Item and  g_IsWashed == 1  then
			EquipEducation_SendChageEquipConfirm(index,1)			
			return
		end	
		
		EquipAttributeChange_Clear(1)
		
		g_ContralList.ActionButton:SetActionItem(theAction:GetID())
		LifeAbility:Lock_Packet_Item(index, 1)
		g_EquipAttributeChange_Item = index
		
		local icon =  tostring(LifeAbility : Get_Item_Icon_Name(index))
		g_ContralList.obj2:SetProperty("Image",icon)
		
		local num = theAction:GetEquipAttrCount()
		local str = ""
		for i = 0, num-1 do
			local tempstr = theAction:EnumEquipExtAttr(i)
			str = str..tempstr
		end
		g_ContralList.TextBefore:SetText(str)
		g_ContralList.recoinButton:Enable()
		
		local nErrorNo, nEquipQual = theAction:EquipCanRecoin() 
		-- 各种错误提示
		if 1 == g_nUIType then
			-- 9星界面
			if nErrorNo > 0 then
				local strErrorMsg = strCheckErrorMsgFor9[nErrorNo]
				if nil == strErrorMsg then
					strErrorMsg = tostring(nErrorNo)
				end
				PushDebugMessage(strErrorMsg)
				return
			end

			if nEquipQual ~= 9 then
				PushDebugMessage("#{JXCZ_190213_61}")
				return
			end
		else
			-- 非九星界面
			if nErrorNo > 0 then
				local strErrorMsg = strCheckErrorMsgFor78[nErrorNo]
				if nil == strErrorMsg then
					strErrorMsg = tostring(nErrorNo)
				end
				PushDebugMessage(strErrorMsg)
				return
			end

			if nEquipQual ~= 7 and nEquipQual ~= 8 then
				PushDebugMessage("#{ZBCZ_140618_28}")
				return
			end
		end

		local nItemIndex = 1
		if nEquipQual ~= 7 and nEquipQual ~= 8 and nEquipQual ~= 9 then
			return
		end
		if nEquipQual == 7 then
			nItemIndex = 1
		elseif nEquipQual == 8 then
			nItemIndex = 2
		elseif nEquipQual == 9 then
			nItemIndex = 3
		end	
		
		local itemname = PlayerPackage:GetItemName(tonumber(g_binditem[nItemIndex]))
		local needinfo = ScriptGlobal_Format("#{ZBCZ_140618_41}", 1,itemname)
		EquipAttributeChange_CaiLiaoText:SetText(needinfo)
		
		
	end
end

--保留原有属性
function EquipAttributeChange_Bk1_Btn_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("DoRefreshEquipAttr");
		Set_XSCRIPT_ScriptID(890990);
		Set_XSCRIPT_Parameter(0,g_EquipAttributeChange_Item);
		Set_XSCRIPT_Parameter(1,1)
		Set_XSCRIPT_Parameter(2,g_nUIType)
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();		
	--清空recoin表示
	EquipAttributeChange_Clear(0)
	EquipAttributeChange_Update(g_EquipAttributeChange_Item)
end

--保留新属性
function EquipAttributeChange_Bk2_Btn_Clicked()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("DoRefreshEquipAttr");
		Set_XSCRIPT_ScriptID(890990);
		Set_XSCRIPT_Parameter(0,g_EquipAttributeChange_Item);
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_Parameter(2,g_nUIType)
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();		
end

--发送替换装备二次确认
function EquipEducation_SendChageEquipConfirm(nIndex,keepopen)
	PushEvent("EQUIPATTR_CHANGEEQUIP_CONFIRM",tostring(nIndex),tostring(keepopen))
end

function EquipAttributeChange_TryClear()
	if g_EquipAttributeChange_Item ~= -1 and g_IsWashed == 1  then
		EquipEducation_SendChageEquipConfirm(g_EquipAttributeChange_Item,2)			
		return
	end	
	
	EquipAttributeChange_Clear(1) --先把原来的清空了
	
end

--重铸
function EquipAttributeChange_Buttons_Clicked()
	
	-- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZBCZ_140618_22}")
		return
	end	
	
	--判断高级密保
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end	
	
	if g_EquipAttributeChange_Item < 0 then
		PushDebugMessage("#{ZBCZ_140618_27}")
		return	
	end
	
	local theAction = EnumAction(g_EquipAttributeChange_Item, "packageitem")
	
	local nErrorNo, nEquipQual = theAction:EquipCanRecoin() 
	-- 各种错误提示
	if 1 == g_nUIType then
		-- 9星界面
		if nErrorNo > 0 then
			local strErrorMsg = strCheckErrorMsgFor9[nErrorNo]
			if nil == strErrorMsg then
				strErrorMsg = tostring(nErrorNo)
			end
			PushDebugMessage(strErrorMsg)
			return
		end

		if nEquipQual ~= 9 then
			PushDebugMessage("#{JXCZ_190213_61}")
			return
		end
	else
		-- 非九星界面
		if nErrorNo > 0 then
			local strErrorMsg = strCheckErrorMsgFor78[nErrorNo]
			if nil == strErrorMsg then
				strErrorMsg = tostring(nErrorNo)
			end
			PushDebugMessage(strErrorMsg)
			return
		end

		if nEquipQual ~= 7 and nEquipQual ~= 8 then
			PushDebugMessage("#{ZBCZ_140618_28}")
			return
		end
	end
	local index = 1
	if nEquipQual ~= 7 and nEquipQual ~= 8 and nEquipQual ~= 9 then
		return
	end
	if nEquipQual == 7 then
		index = 1
	elseif nEquipQual == 8 then
		index = 2
	elseif nEquipQual == 9 then
		index = 3
	end
	
	local total = PlayerPackage:CountAvailableItemByIDTable(g_binditem[index]) + PlayerPackage:CountAvailableItemByIDTable(g_unbinditem[index]) +
			PlayerPackage:CountAvailableItemByIDTable(tonumber(g_yuanbaoitem[index])) 
	if nEquipQual > 0 then
		if total <= 0 then
			local itemname = PlayerPackage:GetItemName(tonumber(g_binditem[index]))
			local strInfo = ScriptGlobal_Format("#{ZBCZ_140618_31}", itemname,itemname)
			PushDebugMessage(strInfo)
			return
		end
		--绑定道具够
		if PlayerPackage:CountAvailableItemByIDTable(g_binditem[index]) > 0 then
			if(PlayerPackage:GetItemBindStatusByIndex(g_EquipAttributeChange_Item) == 1 ) then
			--绑定道具，绑定装备
			--直接发到Server
				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("OnGenNewEquipAttr");
					Set_XSCRIPT_ScriptID(890990);
					Set_XSCRIPT_Parameter(0,g_EquipAttributeChange_Item);
					Set_XSCRIPT_Parameter(1,g_nUIType);
					Set_XSCRIPT_ParamCount(2);
				Send_XSCRIPT();				
			elseif g_EquipAttributeChange_Confirm == 1 then
			--经过二次确认过的
				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("OnGenNewEquipAttr");
					Set_XSCRIPT_ScriptID(890990);
					Set_XSCRIPT_Parameter(0,g_EquipAttributeChange_Item);
					Set_XSCRIPT_Parameter(1,g_nUIType);
					Set_XSCRIPT_ParamCount(2);
				Send_XSCRIPT();					
			--直接发到Server
			else
				--去弹二次确认儿吧
				PushEvent("EQUIPATTR_BIND_CONFIRM",tostring(g_binditem[index]));
				return
			end
		else
		--用非绑定道具

			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("OnGenNewEquipAttr");
				Set_XSCRIPT_ScriptID(890990);
				Set_XSCRIPT_Parameter(0,g_EquipAttributeChange_Item);
				Set_XSCRIPT_Parameter(1,g_nUIType);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();				
		
		end
		
	end
	

	
	
	g_ContralList.recoinButton:Disable()
	g_IsWashed = 1
end

function EquipAttributeChange_BeginCareObject(objID)
	g_Object = objID;
	this:CareObject(g_Object, 1, "EquipAttributeChange");
end

function EquipAttributeChange_ResetPos()
	EquipAttributeChange_Frame:SetProperty("UnifiedPosition", g_EquipAttributeChange_Frame_UnifiedPosition)
end