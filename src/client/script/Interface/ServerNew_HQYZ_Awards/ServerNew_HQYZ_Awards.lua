--ServerNew_HQYZ_Awards

local g_ServerNew_HQYZ_Awards_Frame_UnifiedPosition

local g_ServerNew_HQYZ_Awards_BigPrize = {
	[1] = {10101052, 20502005, 10141427, 0},
	[2] = {10126805, 20501005, 10146246, 1},
	[3] = {10101059, 20502005, 10141678, 0},
	[4] = {10127659, 20501005, 10125028, 1},
	[5] = {10102976, 20502005, 10141562, 0},
	[6] = {10127236, 20501005, 10147495, 0},
	[7] = {10141518, 10102808, 10422155, 1},
}

local g_ServerNew_HQYZ_Awards_NormalPrize = {
	--一档,无门槛
  [1] = {
  	{GiftItemID = 10126800, count=1},
    {GiftItemID = 10127654, count=1},
    {GiftItemID = 10127231, count=1},
    {GiftItemID = 10146614, count=1},
    {GiftItemID = 10146680, count=1},
    {GiftItemID = 10146745, count=1},
    {GiftItemID = 38000992, count=1},
    {GiftItemID = 38001595, count=1},
    {GiftItemID = 20502003, count=1},
    {GiftItemID = 20501003, count=1},
  },
  --二档,8万元宝
  [2] = {
    {GiftItemID = 10126801, count=1},
    {GiftItemID = 10127655, count=1},
    {GiftItemID = 10127232, count=1},
    {GiftItemID = 10125128, count=1},
    {GiftItemID = 10128889, count=1},
    {GiftItemID = 10146615, count=1},
    {GiftItemID = 10146681, count=1},
    {GiftItemID = 10146746, count=1},
    {GiftItemID = 10147931, count=1},
    {GiftItemID = 10146496, count=1},
    {GiftItemID = 10146449, count=1},
    {GiftItemID = 10146328, count=1},
    {GiftItemID = 10147932, count=1},
    {GiftItemID = 38000992, count=2},
    {GiftItemID = 38001595, count=2},
    {GiftItemID = 20502003, count=2},
    {GiftItemID = 20501003, count=2},
  },
  --三档,40万元宝
  [3] = {
    {GiftItemID = 10126802, count=1},
    {GiftItemID = 10127656, count=1},
    {GiftItemID = 10127233, count=1},
    {GiftItemID = 10124726, count=1},
    {GiftItemID = 10128890, count=1},
    {GiftItemID = 10146616, count=1},
    {GiftItemID = 10146682, count=1},
    {GiftItemID = 10146747, count=1},
    {GiftItemID = 10141452, count=1},
    {GiftItemID = 10146157, count=1},
    {GiftItemID = 10146193, count=1},
    {GiftItemID = 10141520, count=1},
    {GiftItemID = 10146244, count=1},
    {GiftItemID = 38000992, count=3},
    {GiftItemID = 38001595, count=3},
    {GiftItemID = 20502003, count=3},
    {GiftItemID = 20501003, count=3},
  }
}

function ServerNew_HQYZ_Awards_PreLoad()
	this:RegisterEvent("OPEN_SERVERNEW_HQYZ_INTRO",true);
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
end

function ServerNew_HQYZ_Awards_OnLoad()
	--ServerNew_HQYZ_Awards_List_Info1_Rank1
	g_ServerNew_HQYZ_Awards_Frame_UnifiedPosition = ServerNew_HQYZ_Awards_Frame:GetProperty("UnifiedPosition")
end

function ServerNew_HQYZ_Awards_OnEvent(event)
	if (event == "OPEN_SERVERNEW_HQYZ_INTRO") then
		ServerNew_HQYZ_Awards_BigPrizeShow()
		this:Show()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		ServerNew_HQYZ_Awards_Close_Clicked()
	elseif (event == "ADJEST_UI_POS") then
		ServerNew_HQYZ_Awards_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ServerNew_HQYZ_Awards_On_ResetPos()
	end
end

function ServerNew_HQYZ_Awards_YQ_OnClick( index )
	if index == 1 then
		ServerNew_HQYZ_Awards_BigPrizeShow()
	else
		ServerNew_HQYZ_Awards_NormalPrizeShow()
	end
	
end

function ServerNew_HQYZ_Awards_BigPrizeShow()
	ServerNew_HQYZ_Awards_List_ListFrame1:Show();
	ServerNew_HQYZ_Awards_List_Frame1:Hide();
	ServerNew_HQYZ_Awards_YQ_Btn1:SetProperty("Selected", "True");
	ServerNew_HQYZ_Awards_YQ_Btn2:SetProperty("Selected", "False");
	ServerNew_HQYZ_Awards_Info:SetText("#{HQYZ_260803_04}")
	
	for i=1,7 do
		_G["ServerNew_HQYZ_Awards_List_Info"..i.."_Rank1"]:SetText(ScriptGlobal_Format("#{HQYZ_260803_08}", i));
		
		local itemAction = DataPool:CreateBindActionItemForShow( g_ServerNew_HQYZ_Awards_BigPrize[i][1], 1 )
		if itemAction:GetID() ~= 0 then
			_G["ServerNew_HQYZ_Awards_List_Info"..i.."_Reward1"]:SetActionItem(itemAction:GetID())	
		end
		
		local itemAction2 = DataPool:CreateBindActionItemForShow( g_ServerNew_HQYZ_Awards_BigPrize[i][2], 1 )
		if itemAction2:GetID() ~= 0 then
			_G["ServerNew_HQYZ_Awards_List_Info"..i.."_Reward2"]:SetActionItem(itemAction2:GetID())	
		end
		
		local itemAction3 = DataPool:CreateBindActionItemForShow( g_ServerNew_HQYZ_Awards_BigPrize[i][3], 1 )
		if itemAction3:GetID() ~= 0 then
			_G["ServerNew_HQYZ_Awards_List_Info"..i.."_Reward3"]:SetActionItem(itemAction3:GetID())	
		end
		
		if g_ServerNew_HQYZ_Awards_BigPrize[i][4] > 0 then
			_G["ServerNew_HQYZ_Awards_List_Info"..i.."_Award3_Light"]:Show();
		else
			_G["ServerNew_HQYZ_Awards_List_Info"..i.."_Award3_Light"]:Hide();
		end
		
	end
end

function ServerNew_HQYZ_Awards_NormalPrizeShow()
	ServerNew_HQYZ_Awards_List_ListFrame1:Hide();
	ServerNew_HQYZ_Awards_List_Frame1:Show();
	ServerNew_HQYZ_Awards_YQ_Btn1:SetProperty("Selected", "False");
	ServerNew_HQYZ_Awards_YQ_Btn2:SetProperty("Selected", "True");
	ServerNew_HQYZ_Awards_Info:SetText("#{HQYZ_260803_12}")
	
	local nCtrlCount={12, 18, 18};
	
	for i=1, 3 do
		for c=1, nCtrlCount[i] do
			_G["ServerNew_HQYZ_Awards_List"..i.."_RewardItem"..c]:Hide();
		end
				
		local tblPrize = g_ServerNew_HQYZ_Awards_NormalPrize[i];
		for j=1, table.getn(tblPrize) do
			local itemAction = DataPool:CreateBindActionItemForShow( tblPrize[j].GiftItemID, tblPrize[j].count )
			if itemAction:GetID() ~= 0 then
				_G["ServerNew_HQYZ_Awards_List"..i.."_RewardItem"..j]:SetActionItem(itemAction:GetID())	
				_G["ServerNew_HQYZ_Awards_List"..i.."_RewardItem"..j]:Show();
			end
		end
	end
end

function ServerNew_HQYZ_Awards_On_ResetPos()
	ServerNew_HQYZ_Awards_Frame:SetProperty("UnifiedPosition", g_ServerNew_HQYZ_Awards_Frame_UnifiedPosition)

end

function ServerNew_HQYZ_Awards_Close_Clicked()
	this:Hide()
end

function ServerNew_HQYZ_Awards_Close()
end