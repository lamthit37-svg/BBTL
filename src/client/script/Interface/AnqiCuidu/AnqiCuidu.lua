--暗器金翅翎羽粹毒界面逻辑（客户端）
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local g_Object = -1
local g_CommandType = 1
local g_Dark_Bag_Index = -1
local g_Mainitem = 10155008
local g_CuiduCost = {1000000,1000000}

function AnqiCuidu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_ANQICUIDU")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function AnqiCuidu_OnLoad()
end

function AnqiCuidu_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 800034) then
		
		if this:IsVisible() then									-- 如果界面开着，则不处理
			AnqiCuidu_Close()
		end

		objCared = -1;
		local tempID = Get_XParam_INT(1);
		objCared = DataPool : GetNPCIDByServerID(tempID);

		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end
		
		AnqiCuidu_BeginCareObject(objCared)

		g_CommandType = Get_XParam_INT(0)
		if g_CommandType == 12 then
			AnqiCuidu_InitDlg()
		end
	elseif (event == "UPDATE_ANQICUIDU" and this:IsVisible()) then
		if arg0~= nil then
			AnqiCuidu_Update(arg0)
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			AnqiCuidu_Close()
		end
	elseif(event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible())then
		if(tonumber(arg0) == 176) then
			AnqiCuidu_Resume()
		end
	elseif(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil then
			if (g_Dark_Bag_Index == tonumber(arg0)) then
				AnqiCuidu_Resume()
			end
		end
	end
end

function AnqiCuidu_InitDlg()
	--暗器粹毒
	AnqiCuidu_Reset()
	this:Show()
end

--粹毒按钮回调
function AnqiCuidu_OK_Clicked(index)
	--请先放入暗器。
	if (g_Dark_Bag_Index == -1) then
		PushDebugMessage("#{CXYH_140813_16}")
		return
	end

	local EquipPoint = LifeAbility : Get_Equip_Point(g_Dark_Bag_Index)
	if (EquipPoint ~= 17) then
		PushDebugMessage("#{AQJJ_160127_77}")
		return
	end
	
	--暗器粹毒
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("LingyuCuiduConfim")
		Set_XSCRIPT_ScriptID(260001)
		Set_XSCRIPT_Parameter(0,g_Dark_Bag_Index)
		Set_XSCRIPT_Parameter(1,tonumber(index))
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--关闭界面按钮回调
function AnqiCuidu_CloseUI_Clicked()
	AnqiCuidu_Close()
end

--界面Hide回调
function AnqiCuidu_Clear()
	AnqiCuidu_Reset()
	AnqiCuidu_StopCareObject()
end

function AnqiCuidu_Update(Item_index)
	local i_index = tonumber(Item_index)
	local theAction = EnumAction(i_index, "packageitem");

	if theAction:GetID() ~= 0 then
		if PlayerPackage : GetItemTableIndex( i_index ) ~= g_Mainitem then
			PushDebugMessage("#{AQJJ_160127_77}")
			return
		end
		
		local darkLv = PlayerPackage : GetBagItemDarkLevel(i_index)
		--if darkLv < 90 then
		--	PushDebugMessage("#{AQJJ_160127_77}")
		--	return
		--end
		
		if i_index == g_Dark_Bag_Index then
			return
		end

		--界面清空
		AnqiCuidu_Reset()
		--设置ActionItem
		AnqiCuidu_Item:SetActionItem(theAction:GetID());
		g_Dark_Bag_Index = i_index
		LifeAbility : Lock_Packet_Item(i_index,1)
	end

end

function AnqiCuidu_Reset()
	AnqiCuidu_Item:SetActionItem(-1);
	LifeAbility : Lock_Packet_Item(g_Dark_Bag_Index,0);
	g_Dark_Bag_Index = -1
end

function AnqiCuidu_Close()
	AnqiCuidu_Reset()
	AnqiCuidu_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function AnqiCuidu_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "AnqiCuidu");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "AnqiCuidu")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function AnqiCuidu_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "AnqiCuidu");
		g_Object = -1;
	end
end

function AnqiCuidu_Resume()
	AnqiCuidu_Reset()		
end
