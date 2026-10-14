local PET_MAX_NUMBER = 6+4;
local PET_BUFF_MAX = 6;

local PET_HP = 0;
local PET_MAXHP = 1;
local PET_EXP = 0;
local PET_MAXEXP = 1;
local MousePos = 0;		--0,鼠标不在窗体内 1,鼠标在窗体内

local PET_IMPACT_CTL = {};
local g_FightPet = -1;

function PetFrame_PreLoad()
	this:RegisterEvent("UPDATE_PET_PAGE",true);
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true);

	this:RegisterEvent("UI_SHOW_2DHEAD",true)	--显示2D头像
	this:RegisterEvent("UPDATE_FAKE_OBJECT",true)
end

function PetFrame_OnLoad()
	PET_IMPACT_CTL[1] = PetFrame_Buff1;
	PET_IMPACT_CTL[2] = PetFrame_Buff2;
	PET_IMPACT_CTL[3] = PetFrame_Buff3;
	PET_IMPACT_CTL[4] = PetFrame_Buff4;
	PET_IMPACT_CTL[5] = PetFrame_Buff5;
	PET_IMPACT_CTL[6] = PetFrame_Buff6;
end

function PetFrame_OnEvent( event )
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		--this:Show();
		PetFrame_Update();
		return;
	elseif( event == "UPDATE_PET_PAGE") then
		PetFrame_Update();
	end

	if ( event == "UI_SHOW_2DHEAD" ) then
		PetFrame_UpdateShow2DHead()
		return
	end
	
	if ( event == "UPDATE_FAKE_OBJECT" ) then
		if( arg0 == "My_PetHead" and this:IsVisible() ) then
			PetFrame_Update()
		end
	end
end

function PetFrame_Update()
	--查找战斗珍兽
	local nPetCount = Pet : GetPet_Count();

	if nPetCount < 1 then
		PetFrame_Clear();
		this:Hide();
		return;
	end

	g_FightPet = -1;
	for	i=1, PET_MAX_NUMBER do
		if Pet:IsPresent(i-1) then
			if(Pet : GetIsFighting(i-1)) then
				g_FightPet = i-1;
			end
		end
	end

	if(g_FightPet < 0 ) then
		PetFrame_Clear();
		this:Hide();
		return;
	end

	--战斗珍兽头像
	local szPortrait = Pet:GetPetPortraitByIndex(g_FightPet);
	--是否幻灵
	local szHLPortrait = Pet:GetPetHuanlingPortraitByIndex(g_FightPet);
	if szHLPortrait ~= nil and szHLPortrait ~= "" then
		szPortrait = szHLPortrait
	end
	
	if(nil ~= szPortrait and "" ~= szPortrait) then
		PetFrame_Head_2D:SetProperty("Image", tostring(szPortrait));
		--AxTrace(0,0, "珍兽头像" .. szPortrait);
	end

	--战斗珍兽的HP/HPMAX
	PET_HP = Pet : GetHP(g_FightPet);
	PET_MAXHP = Pet:	GetMaxHP(g_FightPet);

	PetFrame_HP:SetProgress(PET_HP, PET_MAXHP);
	if( PET_HP / PET_MAXHP > 0.3 ) then
		PetFrame_HP_Flash:Play( false );
	else
		PetFrame_HP_Flash:Play( true );
	end

	PET_EXP,PET_MAXEXP = Pet : GetExp(g_FightPet);
	PetFrame_Exp:SetProgress(PET_EXP, PET_MAXEXP);
	PetFrame_Update_Tooltip( 1 );


	--战斗珍兽的Buf
	local nBuffNum = Pet:GetPetImpactNum(g_FightPet);
	if(nBuffNum > PET_BUFF_MAX) then nBuffNum = PET_BUFF_MAX; end

	local i = 0;
	while i < nBuffNum do
		local szIconName;
		local szTipInfo;

		szIconName,szTipInfo = Pet:GetPetImpactIconNameByIndex(g_FightPet, i);
		PET_IMPACT_CTL[i+1]:SetProperty("ShortImage", szIconName);
		PET_IMPACT_CTL[i+1]:Show();
		PET_IMPACT_CTL[i+1]:SetToolTip(szTipInfo);
		i = i + 1;
	end

	while i < PET_BUFF_MAX do
		PET_IMPACT_CTL[i+1]:SetToolTip("");
		PET_IMPACT_CTL[i+1]:Hide();
		i = i + 1;
	end
	--显示等级
	local nNumber = Pet:GetLevel(g_FightPet);
	PetFrame_Level:SetText("#cDED784"..tostring(nNumber));
	this:Show();

	PetFrame_UpdateShow2DHead()
end

function PetFrame_Clear()
	local i = 0;
	while i < PET_BUFF_MAX do
		PET_IMPACT_CTL[i+1]:SetToolTip("");
		PET_IMPACT_CTL[i+1]:Hide();
		i = i + 1;
	end

	PET_HP = 0;
	PET_MAXHP = 1;
	PetFrame_HP:SetProgress(PET_HP, PET_MAXHP);
	PetFrame_Exp:SetProgress(PET_EXP, PET_MAXEXP);
	PetFrame_Head_2D:Hide();
	PetFrame_Head_3D:SetFakeObject("");
	--PetFrame_HP_Text:SetText("");
	--PetFrame_HP_Text:SetProperty("MouseHollow", "True");
	PetFrame_HP:SetToolTip("");
end

function PetFrame_ShowMenu()
	Pet:ShowMyPetContexMenu();
end

function PetFrame_HP_Text_MouseEnter()
	PetFrame_Update_Tooltip( 1 );
end

function PetFrame_HP_Text_MouseLeave()
	MousePos = 0;
	--PetFrame_Update_Tooltip( 0 );
end

function PetFrame_Update_Tooltip( arg )
	PetFrame_HP:SetToolTip("血:"..tostring( PET_HP ) .. "/" .. tostring( PET_MAXHP).."#r".."经验:"..tostring( PET_EXP ).."/"..tostring( PET_MAXEXP ) );
	PetFrame_Exp:SetToolTip("血:"..tostring( PET_HP ) .. "/" .. tostring( PET_MAXHP).."#r".."经验:"..tostring( PET_EXP ).."/"..tostring( PET_MAXEXP ) );

end

function PetFrame_SetFightPetAsTarget()
	Pet:SetFightPetAsMainTarget();
end

function PetFrame_UpdateShow2DHead()
	PetFrame_Head_2D:Show()
	PetFrame_3DHead_Parent:Hide()
	if SystemSetup:IsClassic() == 1 then
		PetFrame_Frame:SetProperty("UnifiedSize", "{{0.000000,141.000000},{0.000000,53.000000}}");
		PetFrame_Frame:SetProperty("UnifiedPosition", "{{0.000000,94.000000},{0.000000,75.000000}}");
		PetFrame_Background:SetProperty("Image", "set:CommonFrame18 image:PetFrame_BK");
		PetFrame_Background:SetProperty("UnifiedSize", "{{0.000000,141.000000},{0.000000,41.000000}}");
		PetFrame_Level:SetProperty("UnifiedPosition", "{{0.000000,36.000000},{0.000000,21.000000}}");
		PetFrame_DataBack:SetProperty("UnifiedPosition", "{{0.000000,41.000000},{0.000000,3.000000}}");
		PetFrame_BufBack:SetProperty("UnifiedPosition", "{{0.000000,89.000000},{0.000000,23.000000}}");
	end
end
