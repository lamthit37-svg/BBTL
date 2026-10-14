
--最多显示的效果数量
local IMPACT_NUM = 40;

local IMPACT_DESC = {};
IMPACT_DESC[1] = 0;
IMPACT_DESC[2] = 0;
IMPACT_DESC[3] = 0;
IMPACT_DESC[4] = 0;
IMPACT_DESC[5] = 0;
IMPACT_DESC[6] = 0;
IMPACT_DESC[7] = 0;
IMPACT_DESC[8] = 0;
IMPACT_DESC[9] = 0;
IMPACT_DESC[10] = 0;
IMPACT_DESC[11] = 0;
IMPACT_DESC[12] = 0;
IMPACT_DESC[13] = 0;
IMPACT_DESC[14] = 0;
IMPACT_DESC[15] = 0;
IMPACT_DESC[16] = 0;
IMPACT_DESC[17] = 0;
IMPACT_DESC[18] = 0;
IMPACT_DESC[19] = 0;
IMPACT_DESC[20] = 0;
IMPACT_DESC[21] = 0;
IMPACT_DESC[22] = 0;
IMPACT_DESC[23] = 0;
IMPACT_DESC[24] = 0;
IMPACT_DESC[25] = 0;
IMPACT_DESC[26] = 0;
IMPACT_DESC[27] = 0;
IMPACT_DESC[28] = 0;
IMPACT_DESC[29] = 0;
IMPACT_DESC[30] = 0;

IMPACT_DESC[31] = 0;
IMPACT_DESC[32] = 0;
IMPACT_DESC[33] = 0;
IMPACT_DESC[34] = 0;
IMPACT_DESC[35] = 0;
IMPACT_DESC[36] = 0;
IMPACT_DESC[37] = 0;
IMPACT_DESC[38] = 0;
IMPACT_DESC[39] = 0;
IMPACT_DESC[40] = 0;


local PlayerImpactFrame_TimeCtrl = {};
PlayerImpactFrame_TimeCtrl[1] = 0;
PlayerImpactFrame_TimeCtrl[2] = 0;
PlayerImpactFrame_TimeCtrl[3] = 0;
PlayerImpactFrame_TimeCtrl[4] = 0;
PlayerImpactFrame_TimeCtrl[5] = 0;
PlayerImpactFrame_TimeCtrl[6] = 0;
PlayerImpactFrame_TimeCtrl[7] = 0;
PlayerImpactFrame_TimeCtrl[8] = 0;
PlayerImpactFrame_TimeCtrl[9] = 0;
PlayerImpactFrame_TimeCtrl[10] = 0;
PlayerImpactFrame_TimeCtrl[11] = 0;
PlayerImpactFrame_TimeCtrl[12] = 0;
PlayerImpactFrame_TimeCtrl[13] = 0;
PlayerImpactFrame_TimeCtrl[14] = 0;
PlayerImpactFrame_TimeCtrl[15] = 0;
PlayerImpactFrame_TimeCtrl[16] = 0;
PlayerImpactFrame_TimeCtrl[17] = 0;
PlayerImpactFrame_TimeCtrl[18] = 0;
PlayerImpactFrame_TimeCtrl[19] = 0;
PlayerImpactFrame_TimeCtrl[20] = 0;
PlayerImpactFrame_TimeCtrl[21] = 0;
PlayerImpactFrame_TimeCtrl[22] = 0;
PlayerImpactFrame_TimeCtrl[23] = 0;
PlayerImpactFrame_TimeCtrl[24] = 0;
PlayerImpactFrame_TimeCtrl[25] = 0;
PlayerImpactFrame_TimeCtrl[26] = 0;
PlayerImpactFrame_TimeCtrl[27] = 0;
PlayerImpactFrame_TimeCtrl[28] = 0;
PlayerImpactFrame_TimeCtrl[29] = 0;
PlayerImpactFrame_TimeCtrl[30] = 0;

PlayerImpactFrame_TimeCtrl[31] = 0;
PlayerImpactFrame_TimeCtrl[32] = 0;
PlayerImpactFrame_TimeCtrl[33] = 0;
PlayerImpactFrame_TimeCtrl[34] = 0;
PlayerImpactFrame_TimeCtrl[35] = 0;
PlayerImpactFrame_TimeCtrl[36] = 0;
PlayerImpactFrame_TimeCtrl[37] = 0;
PlayerImpactFrame_TimeCtrl[38] = 0;
PlayerImpactFrame_TimeCtrl[39] = 0;
PlayerImpactFrame_TimeCtrl[40] = 0;

local BUFFINDEX_LIST = {};
BUFFINDEX_LIST[1] = -1;
BUFFINDEX_LIST[2] = -1;
BUFFINDEX_LIST[3] = -1;
BUFFINDEX_LIST[4] = -1;
BUFFINDEX_LIST[5] = -1;
BUFFINDEX_LIST[6] = -1;
BUFFINDEX_LIST[7] = -1;
BUFFINDEX_LIST[8] = -1;
BUFFINDEX_LIST[9] = -1;
BUFFINDEX_LIST[10] = -1;
BUFFINDEX_LIST[11] = -1;
BUFFINDEX_LIST[12] = -1;
BUFFINDEX_LIST[13] = -1;
BUFFINDEX_LIST[14] = -1;
BUFFINDEX_LIST[15] = -1;
BUFFINDEX_LIST[16] = -1;
BUFFINDEX_LIST[17] = -1;
BUFFINDEX_LIST[18] = -1;
BUFFINDEX_LIST[19] = -1;
BUFFINDEX_LIST[20] = -1;
BUFFINDEX_LIST[21] = -1;
BUFFINDEX_LIST[22] = -1;
BUFFINDEX_LIST[23] = -1;
BUFFINDEX_LIST[24] = -1;
BUFFINDEX_LIST[25] = -1;
BUFFINDEX_LIST[26] = -1;
BUFFINDEX_LIST[27] = -1;
BUFFINDEX_LIST[28] = -1;
BUFFINDEX_LIST[29] = -1;
BUFFINDEX_LIST[30] = -1;

BUFFINDEX_LIST[31] = -1;
BUFFINDEX_LIST[32] = -1;
BUFFINDEX_LIST[33] = -1;
BUFFINDEX_LIST[34] = -1;
BUFFINDEX_LIST[35] = -1;
BUFFINDEX_LIST[36] = -1;
BUFFINDEX_LIST[37] = -1;
BUFFINDEX_LIST[38] = -1;
BUFFINDEX_LIST[39] = -1;
BUFFINDEX_LIST[40] = -1;

local IMPACT_BUTTONS = {};

function PlayerImpactFrame_PreLoad()
	this:RegisterEvent("IMPACT_SELF_UPDATE",true);
	this:RegisterEvent("IMPACT_SELF_UPDATE_TIME",true);
	this:RegisterEvent("HIDE_THIS_UI",false)

end

function PlayerImpactFrame_OnLoad()

	IMPACT_BUTTONS[1] = PlayerImpact_Image1;
	IMPACT_BUTTONS[2] = PlayerImpact_Image2;
	IMPACT_BUTTONS[3] = PlayerImpact_Image3;
	IMPACT_BUTTONS[4] = PlayerImpact_Image4;
	IMPACT_BUTTONS[5] = PlayerImpact_Image5;
	IMPACT_BUTTONS[6] = PlayerImpact_Image6;
	IMPACT_BUTTONS[7] = PlayerImpact_Image7;
	IMPACT_BUTTONS[8] = PlayerImpact_Image8;
	IMPACT_BUTTONS[9] = PlayerImpact_Image9;
	IMPACT_BUTTONS[10] = PlayerImpact_Image10;
	IMPACT_BUTTONS[11] = PlayerImpact_Image11;
	IMPACT_BUTTONS[12] = PlayerImpact_Image12;
  IMPACT_BUTTONS[13] = PlayerImpact_Image13;
	IMPACT_BUTTONS[14] = PlayerImpact_Image14;
	IMPACT_BUTTONS[15] = PlayerImpact_Image15;
	IMPACT_BUTTONS[16] = PlayerImpact_Image16;
	IMPACT_BUTTONS[17] = PlayerImpact_Image17;
	IMPACT_BUTTONS[18] = PlayerImpact_Image18;
	IMPACT_BUTTONS[19] = PlayerImpact_Image19;
	IMPACT_BUTTONS[20] = PlayerImpact_Image20;
	IMPACT_BUTTONS[21] = PlayerImpact_Image21;
	IMPACT_BUTTONS[22] = PlayerImpact_Image22;
	IMPACT_BUTTONS[23] = PlayerImpact_Image23;
	IMPACT_BUTTONS[24] = PlayerImpact_Image24;
	IMPACT_BUTTONS[25] = PlayerImpact_Image25;
	IMPACT_BUTTONS[26] = PlayerImpact_Image26;
	IMPACT_BUTTONS[27] = PlayerImpact_Image27;
	IMPACT_BUTTONS[28] = PlayerImpact_Image28;
	IMPACT_BUTTONS[29] = PlayerImpact_Image29;
	IMPACT_BUTTONS[30] = PlayerImpact_Image30;

	IMPACT_BUTTONS[31] = PlayerImpact_Image31;
	IMPACT_BUTTONS[32] = PlayerImpact_Image32;
	IMPACT_BUTTONS[33] = PlayerImpact_Image33;
	IMPACT_BUTTONS[34] = PlayerImpact_Image34;
	IMPACT_BUTTONS[35] = PlayerImpact_Image35;
	IMPACT_BUTTONS[36] = PlayerImpact_Image36;
	IMPACT_BUTTONS[37] = PlayerImpact_Image37;
	IMPACT_BUTTONS[38] = PlayerImpact_Image38;
	IMPACT_BUTTONS[39] = PlayerImpact_Image39;
	IMPACT_BUTTONS[40] = PlayerImpact_Image40;


	PlayerImpactFrame_TimeCtrl[1] = PlayerImpact_Text1;
	PlayerImpactFrame_TimeCtrl[2] = PlayerImpact_Text2;
	PlayerImpactFrame_TimeCtrl[3] = PlayerImpact_Text3;
	PlayerImpactFrame_TimeCtrl[4] = PlayerImpact_Text4;
	PlayerImpactFrame_TimeCtrl[5] = PlayerImpact_Text5;
	PlayerImpactFrame_TimeCtrl[6] = PlayerImpact_Text6;
	PlayerImpactFrame_TimeCtrl[7] = PlayerImpact_Text7;
	PlayerImpactFrame_TimeCtrl[8] = PlayerImpact_Text8;
	PlayerImpactFrame_TimeCtrl[9] = PlayerImpact_Text9;
	PlayerImpactFrame_TimeCtrl[10] = PlayerImpact_Text10;
	PlayerImpactFrame_TimeCtrl[11] = PlayerImpact_Text11;
	PlayerImpactFrame_TimeCtrl[12] = PlayerImpact_Text12;
	PlayerImpactFrame_TimeCtrl[13] = PlayerImpact_Text13;
	PlayerImpactFrame_TimeCtrl[14] = PlayerImpact_Text14;
	PlayerImpactFrame_TimeCtrl[15] = PlayerImpact_Text15;
	PlayerImpactFrame_TimeCtrl[16] = PlayerImpact_Text16;
	PlayerImpactFrame_TimeCtrl[17] = PlayerImpact_Text17;
	PlayerImpactFrame_TimeCtrl[18] = PlayerImpact_Text18;
	PlayerImpactFrame_TimeCtrl[19] = PlayerImpact_Text19;
	PlayerImpactFrame_TimeCtrl[20] = PlayerImpact_Text20;
	PlayerImpactFrame_TimeCtrl[21] = PlayerImpact_Text21;
	PlayerImpactFrame_TimeCtrl[22] = PlayerImpact_Text22;
	PlayerImpactFrame_TimeCtrl[23] = PlayerImpact_Text23;
	PlayerImpactFrame_TimeCtrl[24] = PlayerImpact_Text24;
	PlayerImpactFrame_TimeCtrl[25] = PlayerImpact_Text25;
	PlayerImpactFrame_TimeCtrl[26] = PlayerImpact_Text26;
	PlayerImpactFrame_TimeCtrl[27] = PlayerImpact_Text27;
	PlayerImpactFrame_TimeCtrl[28] = PlayerImpact_Text28;
	PlayerImpactFrame_TimeCtrl[29] = PlayerImpact_Text29;
	PlayerImpactFrame_TimeCtrl[30] = PlayerImpact_Text30;

	PlayerImpactFrame_TimeCtrl[31] = PlayerImpact_Text31;
	PlayerImpactFrame_TimeCtrl[32] = PlayerImpact_Text32;
	PlayerImpactFrame_TimeCtrl[33] = PlayerImpact_Text33;
	PlayerImpactFrame_TimeCtrl[34] = PlayerImpact_Text34;
	PlayerImpactFrame_TimeCtrl[35] = PlayerImpact_Text35;
	PlayerImpactFrame_TimeCtrl[36] = PlayerImpact_Text36;
	PlayerImpactFrame_TimeCtrl[37] = PlayerImpact_Text37;
	PlayerImpactFrame_TimeCtrl[38] = PlayerImpact_Text38;
	PlayerImpactFrame_TimeCtrl[39] = PlayerImpact_Text39;
	PlayerImpactFrame_TimeCtrl[40] = PlayerImpact_Text40;
end

function PlayerImpactFrame_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end

	if ZBS:IsViewerWatching() > 0 then
		this:Hide()
		return
	end

	if ( event == "IMPACT_SELF_UPDATE" ) then
		PlayerImpactFrame_Update( 1, 1 );
		return;
	end

	if ( event == "IMPACT_SELF_UPDATE_TIME" ) then
		PlayerImpactFrame_Update( 0, 1 );
		return;
	end

	if (event == "HIDE_THIS_UI" ) then
		if this:IsVisible() then
			this:Hide()
		end
	end

end

function PlayerImpactFrame_Update( bUpdateImage, bUpdateTime )

	local buff_num = Player:GetBuffNumber();

	if ( buff_num > IMPACT_NUM ) then
		buff_num = IMPACT_NUM;
	end

	if( buff_num == 0) then
		this:Hide();
		return;
	end

	this:Show();

	for jj=1,IMPACT_NUM do
		BUFFINDEX_LIST[jj] = -1;
	end

	local BuffPriority = {}
	for jj=1,buff_num do
		BuffPriority[jj] = {}
		BuffPriority[jj].key = jj-1;
		BuffPriority[jj].val = Player:GetBuffPriorityByIndex(jj-1);
	end

	for jj=buff_num,1,-1 do
		for kk=1,jj-1 do
			if BuffPriority[kk].val < BuffPriority[kk+1].val then
				BuffPriority[kk],BuffPriority[kk+1] = BuffPriority[kk+1],BuffPriority[kk]
			end
		end
	end

	for jj=1,buff_num do
		BUFFINDEX_LIST[jj] = BuffPriority[jj].key;
	end

	if ( bUpdateImage > 0 ) then
		local szIconName, szToolTips;
		local i = 0;
		while i<buff_num do
			szIconName = Player:GetBuffIconNameByIndex(BUFFINDEX_LIST[i+1]);
			szToolTips = Player:GetBuffToolTipsByIndex(BUFFINDEX_LIST[i+1]);
			IMPACT_BUTTONS[i+1]:SetProperty("ShortImage", szIconName);
			IMPACT_BUTTONS[i+1]:SetProperty("MouseHollow","False");
			IMPACT_BUTTONS[i+1]:SetToolTip(szToolTips);
			IMPACT_BUTTONS[i+1]:Show();
			i = i+1;
		end

		while i<IMPACT_NUM do
			IMPACT_BUTTONS[i+1]:SetProperty("MouseHollow","True");
			IMPACT_BUTTONS[i+1]:Hide();
			i = i+1;
		end
	end

	if ( bUpdateTime > 0 ) then
		local szTimeText;
		local i;

		i = 0;
		while i<buff_num do
			szTimeText = Player:GetBuffTimeTextByIndex(BUFFINDEX_LIST[i+1]);
--			PlayerImpactFrame_TimeCtrl[i+1]:SetText(szTimeText);
			PlayerImpactFrame_TimeCtrl[i+1] : SetProperty("Timer",tostring(szTimeText));
			PlayerImpactFrame_TimeCtrl[i+1]:Show();
			i = i+1;
		end

		while i<IMPACT_NUM do
			PlayerImpactFrame_TimeCtrl[i+1]:SetProperty("Timer","-2");
			PlayerImpactFrame_TimeCtrl[i+1]:Hide();
			i = i+1;
		end
	end

end

function PlayerImpactFrame_Image1_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[1] );
end

function PlayerImpactFrame_Image2_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[2] );
end

function PlayerImpactFrame_Image3_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[3] );
end

function PlayerImpactFrame_Image4_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[4] );
end

function PlayerImpactFrame_Image5_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[5] );
end

function PlayerImpactFrame_Image6_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[6] );
end

function PlayerImpactFrame_Image7_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[7] );
end

function PlayerImpactFrame_Image8_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[8] );
end

function PlayerImpactFrame_Image9_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[9] );
end

function PlayerImpactFrame_Image10_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[10] );
end

function PlayerImpactFrame_Image11_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[11] );
end

function PlayerImpactFrame_Image12_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[12] );
end

function PlayerImpactFrame_Image13_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[13] );
end

function PlayerImpactFrame_Image14_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[14] );
end

function PlayerImpactFrame_Image15_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[15] );
end

function PlayerImpactFrame_Image16_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[16] );
end

function PlayerImpactFrame_Image17_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[17] );
end

function PlayerImpactFrame_Image18_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[18] );
end

function PlayerImpactFrame_Image19_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[19] );
end

function PlayerImpactFrame_Image20_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[20] );
end

function PlayerImpactFrame_Image21_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[21] );
end

function PlayerImpactFrame_Image22_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[22] );
end

function PlayerImpactFrame_Image23_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[23] );
end

function PlayerImpactFrame_Image24_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[24] );
end

function PlayerImpactFrame_Image25_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[25] );
end

function PlayerImpactFrame_Image26_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[26] );
end

function PlayerImpactFrame_Image27_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[27] );
end

function PlayerImpactFrame_Image28_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[28] );
end

function PlayerImpactFrame_Image29_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[29] );
end

function PlayerImpactFrame_Image30_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[30] );
end

function PlayerImpactFrame_Image31_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[31] );
end

function PlayerImpactFrame_Image32_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[32] );
end

function PlayerImpactFrame_Image33_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[33] );
end

function PlayerImpactFrame_Image34_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[34] );
end

function PlayerImpactFrame_Image35_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[35] );
end

function PlayerImpactFrame_Image36_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[36] );
end

function PlayerImpactFrame_Image37_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[37] );
end

function PlayerImpactFrame_Image38_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[38] );
end

function PlayerImpactFrame_Image39_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[39] );
end

function PlayerImpactFrame_Image40_Click()
	Player:DispelBuffByIndex( BUFFINDEX_LIST[40] );
end
