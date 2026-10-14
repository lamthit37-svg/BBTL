local g_targetId=-1
local g_CurSelInfantIndex= 0
local g_MaxInfantCount = 0;
local g_TotalSex = 2;
local NEEDMONEY = 50000
local g_CurSelSkill = -1;

local Infant_Skill_Icon = {};
local Infant_Skill_CheckBtn = {};
local Infant_Skill_Name_Text = {};
local Infant_Skill_Value_Text = {};

local g_Infant_SkillLevelUp_YuanBaoPay = 1

local g_Infant_Head_Image = {
		"set:InfantHeader image:InfantHeader_2",		--襁褓期 女
		"set:InfantHeader image:InfantHeader_1",		--襁褓期 男
		"set:InfantHeader image:InfantHeader_4",		--婴儿期 女
		"set:InfantHeader image:InfantHeader_3",		--婴儿期 男
		"set:InfantHeader image:InfantHeader_6",		--幼儿期 女
		"set:InfantHeader image:InfantHeader_5",		--幼儿期 男
		"set:InfantHeader image:InfantHeader_8",		--儿童期 女
		"set:InfantHeader image:InfantHeader_7",		--儿童期 男
};

function Infant_SkillLevelUp_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("TOGGLE_UPDATE_INFANT");
	this : RegisterEvent("UNIT_MONEY");
	this : RegisterEvent("MONEYJZ_CHANGE")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Infant_SkillLevelUp_OnLoad()
	g_MaxInfantCount = Infant:GetInfantMaxCount()
	Infant_Skill_Icon[1] = Infant_SkillLevelUp_Skill_1_Image
	Infant_Skill_Icon[2] = Infant_SkillLevelUp_Skill_2_Image
	Infant_Skill_Icon[3] = Infant_SkillLevelUp_Skill_3_Image
	Infant_Skill_Icon[4] = Infant_SkillLevelUp_Skill_4_Image

	Infant_Skill_CheckBtn[1] = Infant_SkillLevelUp_Skill_1_ButtonCheck
	Infant_Skill_CheckBtn[2] = Infant_SkillLevelUp_Skill_2_ButtonCheck
	Infant_Skill_CheckBtn[3] = Infant_SkillLevelUp_Skill_3_ButtonCheck
	Infant_Skill_CheckBtn[4] = Infant_SkillLevelUp_Skill_4_ButtonCheck

	Infant_Skill_Name_Text[1] = Infant_SkillLevelUp_SkillNameText1
	Infant_Skill_Name_Text[2] = Infant_SkillLevelUp_SkillNameText2
	Infant_Skill_Name_Text[3] = Infant_SkillLevelUp_SkillNameText3
	Infant_Skill_Name_Text[4] = Infant_SkillLevelUp_SkillNameText4

	Infant_Skill_Value_Text[1] = Infant_SkillLevelUp_SkillNumText1
	Infant_Skill_Value_Text[2] = Infant_SkillLevelUp_SkillNumText2
	Infant_Skill_Value_Text[3] = Infant_SkillLevelUp_SkillNumText3
	Infant_Skill_Value_Text[4] = Infant_SkillLevelUp_SkillNumText4
	
	g_Infant_SkillLevelUp_YuanBaoPay = 1;
	Infant_SkillLevelUp_YuanBaoPay:SetCheck(g_Infant_SkillLevelUp_YuanBaoPay)
end

function Infant_SkillLevelUp_OnEvent( event )
	if ( event=="UI_COMMAND" and tonumber(arg0) == 89062 ) then
		local xx = Get_XParam_INT(0);
		g_targetId = DataPool : GetNPCIDByServerID(xx);
		if g_targetId == -1 then
			return
		end
		g_CurSelSkill = -1
		for i = 1,4 do
			Infant_Skill_CheckBtn[i]:SetCheck(0)
		end
		Infant_SkillLevelUp_UpdateInfo();
		Infant_SkillLevelUp_BeginCareObject()

		if g_Infant_SkillLevelUp_YuanBaoPay == 1 or g_Infant_SkillLevelUp_YuanBaoPay == 0 then
			Infant_SkillLevelUp_YuanBaoPay:SetCheck(g_Infant_SkillLevelUp_YuanBaoPay)
		end
				
		this:Show()
		return
	elseif (event=="TOGGLE_UPDATE_INFANT") then
		Infant_SkillLevelUp_UpdateInfo();
	elseif event == "HIDE_ON_SCENE_TRANSED"  then
		Infant_SkillRest_Close()
	elseif (event == "UNIT_MONEY") then
		Infant_SkillLevelUp_Demand_Jiaozi:SetProperty("MoneyNumber", NEEDMONEY)
		Infant_SkillLevelUp_Currently_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE") then
		Infant_SkillLevelUp_Demand_Jiaozi:SetProperty("MoneyNumber", NEEDMONEY)
		Infant_SkillLevelUp_Currently_Jiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	end
end

function Infant_SkillLevelUp_UpdateInfo()
	Infant_SkillLevelUp_Demand_Jiaozi:SetProperty("MoneyNumber", NEEDMONEY)
	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		return
	end
	local szName = Infant:GetInfantName(g_CurSelInfantIndex);
	Infant_SkillLevelUp_BabyName_Text:SetText(szName);
	local nStage = Infant:GetStage(g_CurSelInfantIndex)
	local nSex = Infant:GetInfantSex(g_CurSelInfantIndex)
	--技能
	local nSkillCount = Infant:GetMaxSkillNum()
	for i = 1, nSkillCount do
		local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(g_CurSelInfantIndex, i - 1)

		if nSkillID == -1 then
			Infant_Skill_Icon[i]:SetToolTip("#{ZNJCS_130825_61}");
			Infant_Skill_Icon[i]:SetProperty("Image", "")
			Infant_Skill_Name_Text[i]:SetText("")
			Infant_Skill_Value_Text[i]:SetText("")
		else
			if szIcon ~= nil then
				Infant_Skill_Icon[i]:SetProperty("Image", szIcon)
				Infant_Skill_Name_Text[i]:SetText(szSkillName.."("..nSkillLevel.."#{WH_090729_12}"..")")
				Infant_Skill_Value_Text[i]:SetText("+"..nSkillEffect)
			end
		end
	end
	-- 头像
	Infant_SkillLevelUp_BabyFace_Image:SetProperty("Image", g_Infant_Head_Image[nStage*g_TotalSex + nSex + 1])

	if g_CurSelSkill < 0 or g_CurSelSkill >= 4 then
		Infant_SkillLevelUp_SkillLevelupLaceText:SetText("#{ZNJCS_130825_85}");
	else
		local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(g_CurSelInfantIndex, g_CurSelSkill)
		if nSkillLevel >= 9 then
			Infant_SkillLevelUp_SkillLevelupLaceText:SetText("已提升至最高级");
			--清空花费
			Infant_SkillLevelUp_Demand_Jiaozi:SetProperty("MoneyNumber", 0)
		else
			Infant_SkillLevelUp_SkillLevelupLaceText:SetText("#{ZNJCS_130825_85}"..":"..nSkillUpRate.."%");
			Infant_SkillLevelUp_Demand_Jiaozi:SetProperty("MoneyNumber", NEEDMONEY)
		end
	end
end

function Infant_SkillLevelUp_UpLevel_Clicked()
	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		return
	end
	local guid_H = -1;
	local guid_L = -1;
	guid_H, guid_L = Infant:GetInfantGUID(g_CurSelInfantIndex);
	if guid_H == -1 and guid_L == -1 then
		return
	end
	if g_CurSelSkill < 0 or g_CurSelSkill >= 4 then
		PushDebugMessage("#{ZNJCS_130825_86}")
		return;
	end
	local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(g_CurSelInfantIndex, g_CurSelSkill)
	if nSkillID == -1 then
		return;
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("InfantSkillLevelUp");
		Set_XSCRIPT_ScriptID(890600);
		Set_XSCRIPT_Parameter(0,guid_H);
		Set_XSCRIPT_Parameter(1,guid_L);
		Set_XSCRIPT_Parameter(2,nSkillID);
		Set_XSCRIPT_Parameter(3,tonumber(Infant_SkillLevelUp_YuanBaoPay:GetCheck()));
		Set_XSCRIPT_ParamCount(4);
	Send_XSCRIPT();
end

function Infant_SkillLevelUp_CheckSkill_BtnDown( index )
	for i = 1,4 do
		Infant_Skill_CheckBtn[i]:SetCheck(0)
	end
	g_CurSelSkill = index
	local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(g_CurSelInfantIndex, g_CurSelSkill)
	if nSkillLevel >= 9 then
		Infant_SkillLevelUp_SkillLevelupLaceText:SetText("已提升至最高级");
		--清空花费
		Infant_SkillLevelUp_Demand_Jiaozi:SetProperty("MoneyNumber", 0)
	else
		Infant_SkillLevelUp_SkillLevelupLaceText:SetText("#{ZNJCS_130825_85}"..":"..nSkillUpRate.."%");
		Infant_SkillLevelUp_Demand_Jiaozi:SetProperty("MoneyNumber", NEEDMONEY)
	end
end

function Infant_SkillLevelUp_Set_MouseLeave()
	PushEvent("INFANT_SKILL_MOUSE_LEAVE")
end

function Infant_SkillLevelUp_MouseEnter( index )
	local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(g_CurSelInfantIndex, index)
	if nSkillID == -1 then
		return;
	end
	if 1 == SystemSetup:IsClassic() then
		local SetX = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteXPosition") + Infant_SkillLevelUp_Skill_1:GetProperty("AbsoluteXPosition") + Infant_SkillLevelUp_Back:GetProperty("AbsoluteXPosition") + Infant_SkillLevelUp_Frame:GetProperty("AbsoluteXPosition");
		local SetY = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteYPosition") + Infant_SkillLevelUp_Skill_1:GetProperty("AbsoluteYPosition") + Infant_SkillLevelUp_Back:GetProperty("AbsoluteYPosition") + Infant_SkillLevelUp_Frame:GetProperty("AbsoluteYPosition");
		local SetWidth = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteWidth")
		local SetHeight = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteHeight")
		PushEvent("INFANT_SKILL_MOUSE_ENTER",SetX,SetY,SetWidth,SetHeight,g_CurSelInfantIndex,index)
	elseif 0 == SystemSetup:IsClassic() then
		local SetX = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteXPosition") + Infant_SkillLevelUp_Skill_1:GetProperty("AbsoluteXPosition") + Infant_SkillLevelUp_Back:GetProperty("AbsoluteXPosition") + Infant_SkillLevelUp_Frame:GetProperty("AbsoluteXPosition") + Infant_SkillLevelUp_Frame_Client:GetProperty("AbsoluteXPosition");
		local SetY = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteYPosition") + Infant_SkillLevelUp_Skill_1:GetProperty("AbsoluteYPosition") + Infant_SkillLevelUp_Back:GetProperty("AbsoluteYPosition") + Infant_SkillLevelUp_Frame:GetProperty("AbsoluteYPosition") + Infant_SkillLevelUp_Frame_Client:GetProperty("AbsoluteYPosition");
		local SetWidth = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteWidth")
		local SetHeight = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteHeight")
		PushEvent("INFANT_SKILL_MOUSE_ENTER",SetX,SetY,SetWidth,SetHeight,g_CurSelInfantIndex,index)	
	end
end
--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function Infant_SkillLevelUp_BeginCareObject()
	this:CareObject(g_targetId, 1, "Infant_SkillLevelUp")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function Infant_SkillLevelUp_StopCareObject()
	this:CareObject(g_targetId, 0, "Infant_SkillLevelUp")
end

--取消或者关闭界面
function Infant_SkillRest_Close()
	Infant_SkillLevelUp_StopCareObject()
	g_Infant_SkillLevelUp_YuanBaoPay = Infant_SkillLevelUp_YuanBaoPay:GetCheck();
	this:Hide()
end
