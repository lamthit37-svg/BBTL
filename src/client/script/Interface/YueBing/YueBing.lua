-- 月饼制作界面
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_type = 0
local g_targetID = -1
local g_Mooncake_ActionItem = {};
local g_Material_ActionItem = {};

function YueBing_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")
end

function YueBing_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= YueBing_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= YueBing_Frame:GetProperty("UnifiedYPosition");

	g_Mooncake_ActionItem[1] = YueBing_Frame_Tu1
	g_Mooncake_ActionItem[2] = YueBing_Frame_Tu2
	g_Mooncake_ActionItem[3] = YueBing_Frame_Tu3
	
	g_Material_ActionItem[1] = YueBing_MaterialIcon1
	g_Material_ActionItem[2] = YueBing_MaterialIcon3
	g_Material_ActionItem[3] = YueBing_MaterialIcon4
	g_Material_ActionItem[4] = YueBing_MaterialIcon6
	g_Material_ActionItem[5] = YueBing_MaterialIcon7
end

function YueBing_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		YueBing_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		YueBing_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		YueBing_Close_Clicked()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 8916551) then --打开界面
		if (this:IsVisible())  then
			return
		end
		g_targetID = Get_XParam_INT(0)
		local ObjCaredID = DataPool : GetNPCIDByServerID(g_targetID);
		if ObjCaredID ~= -1 then
			--开始关心NPC
			this:CareObject(ObjCaredID, 1, "MessageBox_Self2");
		end
		--清空数据
		YueBing_InitData()
		--显示界面
		YueBing_FillData(Get_XParam_INT(1), Get_XParam_INT(2), Get_XParam_INT(3), Get_XParam_INT(4))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 8916552) then --更新界面
		if (this:IsVisible())  then
			--清空数据
			YueBing_InitData()
			--显示界面
			YueBing_FillData(Get_XParam_INT(1), Get_XParam_INT(2), Get_XParam_INT(3), Get_XParam_INT(4))
		end
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function YueBing_ResetPos()
	YueBing_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	YueBing_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function YueBing_Close_Clicked()
	g_type = 0
	g_targetID = -1
	this:Hide()
end

function YueBing_SetType(type)
	for i=1,3 do
		g_Mooncake_ActionItem[i]:SetPushed(0)
	end
	g_type = type
	g_Mooncake_ActionItem[type]:SetPushed(1)
end

function YueBing_InitData()
	for i=1,3 do
		g_Mooncake_ActionItem[i]:SetPushed(0)
	end
	
	YueBing_MaterialIcon1_Mask1:Hide()
	YueBing_MaterialIcon2_Mask1:Hide()
	YueBing_MaterialIcon2_Mask2:Hide()
	YueBing_MaterialIcon3_Mask1:Hide()
	YueBing_MaterialIcon3_Mask2:Hide()
	
	YueBing_MaterialIcon1_Amount1:SetText("0/0")
	YueBing_MaterialIcon2_Amount1:SetText("0/0")
	YueBing_MaterialIcon2_Amount2:SetText("0/0")
	YueBing_MaterialIcon3_Amount1:SetText("0/0")
	YueBing_MaterialIcon3_Amount2:SetText("0/0")
	YueBing_Text1:SetText("")
	YueBing_AllMake:Disable()
end

function YueBing_FillData(mianfen, dousha, wuren, cake)
	local theAction = DataPool:CreateActionItemForShowWithMaxNum(38001465, 1, 1)
	if theAction:GetID() ~= 0 then
		YueBing_Frame_Tu1:SetActionItem(theAction:GetID());
		YueBing_Frame_Tu1:Show()
	end
	
	theAction = DataPool:CreateActionItemForShowWithMaxNum(38001466, 1, 1)
	if theAction:GetID() ~= 0 then
		YueBing_Frame_Tu2:SetActionItem(theAction:GetID());
	end
	
	theAction = DataPool:CreateActionItemForShowWithMaxNum(38001467, 1, 1)
	if theAction:GetID() ~= 0 then
		YueBing_Frame_Tu3:SetActionItem(theAction:GetID());
	end
	
	if g_type>=1 and g_type<=3 then
		g_Mooncake_ActionItem[g_type]:SetPushed(1)
	end
	
	--面粉图标
	theAction = DataPool:CreateActionItemForShowWithMaxNum(38001462, 1, 1)
	if theAction:GetID() ~= 0 then
		g_Material_ActionItem[1]:SetActionItem(theAction:GetID());
		g_Material_ActionItem[2]:SetActionItem(theAction:GetID());
		g_Material_ActionItem[4]:SetActionItem(theAction:GetID());
	end
	
	--豆沙图标
	theAction = DataPool:CreateActionItemForShowWithMaxNum(38001464, 1, 1)
	if theAction:GetID() ~= 0 then
		g_Material_ActionItem[3]:SetActionItem(theAction:GetID());
	end
	
	--五仁图标
	theAction = DataPool:CreateActionItemForShowWithMaxNum(38001463, 1, 1)
	if theAction:GetID() ~= 0 then
		g_Material_ActionItem[5]:SetActionItem(theAction:GetID());
	end
	
	if mianfen < 1 then
		YueBing_MaterialIcon1_Mask1:Show()
		YueBing_MaterialIcon2_Mask1:Show()
		YueBing_MaterialIcon3_Mask1:Show()
	end
	if dousha < 1 then
		YueBing_MaterialIcon2_Mask2:Show()
	end
	if wuren < 1 then
		YueBing_MaterialIcon3_Mask2:Show()
	end
	
	local text = ""
	if mianfen >= 1 then
		text = "#G"..tostring(mianfen).."/1"
	else
		text = tostring(mianfen).."/1"
	end
	YueBing_MaterialIcon1_Amount1:SetText(text)
	YueBing_MaterialIcon2_Amount1:SetText(text)
	YueBing_MaterialIcon3_Amount1:SetText(text)
	
	text = ""
	if dousha >= 1 then
		text = "#G"..tostring(dousha).."/1"
	else
		text = tostring(dousha).."/1"
	end
	YueBing_MaterialIcon2_Amount2:SetText(text)
	
	text = ""
	if wuren >= 1 then
		text = "#G"..tostring(wuren).."/1"
	else
		text = tostring(wuren).."/1"
	end
	YueBing_MaterialIcon3_Amount2:SetText(text)
	
	local text = ScriptGlobal_Format("#{ZZYB_150911_08}", tostring(cake))
	YueBing_Text1:SetText(text)
	if cake >= 5 then --已制作五次月饼
		YueBing_AllMake:Disable()
	else
		YueBing_AllMake:Enable()
	end
	this:Show()
end

function YueBing_Make()
	
	-- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZYB_150911_11}")
		return
	end

	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	
	if type == 0 then
		PushDebugMessage("#{ZZYB_150911_16}")
	end
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnMakeCake");
		Set_XSCRIPT_ScriptID(891655);
		Set_XSCRIPT_Parameter(0, g_targetID);
		Set_XSCRIPT_Parameter(1, g_type);
		Set_XSCRIPT_Parameter(2, 0);
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
end