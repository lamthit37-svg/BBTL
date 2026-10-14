local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local HuoyueWeeklyGift_GetGift_Action = {};
local HuoyueWeeklyGift_Num_Array = {};

local HuoyueWeeklyGift_RewardList = {
	{GiftItemID = 39920162, num = 25,},
	{GiftItemID = 39920092, num = 5,},
	{GiftItemID = 39920339, num = 1,},
	{GiftItemID = 39920946, num = 15,},
}

function HuoyueWeeklyGift_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
end

function HuoyueWeeklyGift_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 201707212 then
		HuoyueWeeklyGift_OnShown()
	elseif event == "UI_COMMAND" and tonumber( arg0 ) == 201707213 then
		HuoyueWeeklyGift_OnHiden()
	elseif( event == "ADJEST_UI_POS" ) then
		HuoyueWeeklyGift_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		HuoyueWeeklyGift_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function HuoyueWeeklyGift_OnLoad()
	HuoyueWeeklyGift_GetGift_Action[1] = HuoyueWeeklyGift_Gift1_Icon
	HuoyueWeeklyGift_GetGift_Action[2] = HuoyueWeeklyGift_Gift2_Icon
	HuoyueWeeklyGift_GetGift_Action[3] = HuoyueWeeklyGift_Gift2_Icon1
	HuoyueWeeklyGift_GetGift_Action[4] = HuoyueWeeklyGift_Gift3_Icon
	
	HuoyueWeeklyGift_Num_Array[1] = HuoyueWeeklyGift_Gift1_Num
	HuoyueWeeklyGift_Num_Array[2] = HuoyueWeeklyGift_Gift2_Num
	HuoyueWeeklyGift_Num_Array[3] = HuoyueWeeklyGift_Gift2_Num1
	HuoyueWeeklyGift_Num_Array[4] = HuoyueWeeklyGift_Gift3_Num
	
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= HuoyueWeeklyGift_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= HuoyueWeeklyGift_Frame:GetProperty("UnifiedYPosition");

end

function HuoyueWeeklyGift_OnShown()
	
	for i = 1, table.getn(HuoyueWeeklyGift_RewardList) do
		local theAction = DataPool:CreateActionItemForShow(HuoyueWeeklyGift_RewardList[i].GiftItemID, 1)
		if theAction:GetID() ~= 0 then
			HuoyueWeeklyGift_GetGift_Action[i]:SetActionItem(theAction:GetID());
			HuoyueWeeklyGift_GetGift_Action[i]:Show();
		end
		HuoyueWeeklyGift_Num_Array[i]:SetText(HuoyueWeeklyGift_RewardList[i].num)
	end
	
	this:Show();
end

--================================================
-- 界面的默认相对位置
--================================================
function HuoyueWeeklyGift_ResetPos()
	HuoyueWeeklyGift_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	HuoyueWeeklyGift_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function HuoyueWeeklyGift_OnClosed()
	this:Hide();
end

function HuoyueWeeklyGift_OnHiden()
	this:Hide();
end

-- 点击领取
function HuoyueWeeklyGift_Select( nIndex )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientActivateOnce")  
		Set_XSCRIPT_ScriptID(892466)
		Set_XSCRIPT_Parameter(0,tonumber(nIndex))
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end
