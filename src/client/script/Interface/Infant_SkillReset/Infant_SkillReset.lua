local g_targetId=-1
local g_CurSelInfantIndex= 0
local g_MaxInfantCount = 0;
local g_TotalSex = 2;
local NEEDMONEY = 50000

local Infant_Skill_Icon = {};
local Infant_Skill_Name_Text = {};
local Infant_Skill_Value_Text = {};
local g_Infant_SkillReset_state =0

local g_Infant_SkillRest_YuanBaoPay = 1

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

function Infant_SkillReset_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("TOGGLE_UPDATE_INFANT");
	this : RegisterEvent("UNIT_MONEY");
	this : RegisterEvent("MONEYJZ_CHANGE")
	this : RegisterEvent("INFANT_SKILL_UPDATE_RECOIN")
	this:RegisterEvent("INFANT_SKILL_RECOIN_CONFIRM_OK");
end

function Infant_SkillReset_OnLoad()
	g_MaxInfantCount = Infant:GetInfantMaxCount()
	Infant_Skill_Icon[1] = Infant_SkillRest_Skill1
	Infant_Skill_Icon[2] = Infant_SkillRest_Skill2
	Infant_Skill_Icon[3] = Infant_SkillRest_Skill3
	Infant_Skill_Icon[4] = Infant_SkillRest_Skill4

	Infant_Skill_Icon[5] = Infant_SkillRest_Skill5
	Infant_Skill_Icon[6] = Infant_SkillRest_Skill6
	Infant_Skill_Icon[7] = Infant_SkillRest_Skill7
	Infant_Skill_Icon[8] = Infant_SkillRest_Skill8


	Infant_Skill_Name_Text[1] = Infant_SkillRest_SkillNameText1
	Infant_Skill_Name_Text[2] = Infant_SkillRest_SkillNameText2
	Infant_Skill_Name_Text[3] = Infant_SkillRest_SkillNameText3
	Infant_Skill_Name_Text[4] = Infant_SkillRest_SkillNameText4

	Infant_Skill_Name_Text[5] = Infant_SkillRest_SkillNameText5
	Infant_Skill_Name_Text[6] = Infant_SkillRest_SkillNameText6
	Infant_Skill_Name_Text[7] = Infant_SkillRest_SkillNameText7
	Infant_Skill_Name_Text[8] = Infant_SkillRest_SkillNameText8

	Infant_Skill_Value_Text[1] = Infant_SkillRest_SkillNumText1
	Infant_Skill_Value_Text[2] = Infant_SkillRest_SkillNumText2
	Infant_Skill_Value_Text[3] = Infant_SkillRest_SkillNumText3
	Infant_Skill_Value_Text[4] = Infant_SkillRest_SkillNumText4

	Infant_Skill_Value_Text[5] = Infant_SkillRest_SkillNumText5
	Infant_Skill_Value_Text[6] = Infant_SkillRest_SkillNumText6
	Infant_Skill_Value_Text[7] = Infant_SkillRest_SkillNumText7
	Infant_Skill_Value_Text[8] = Infant_SkillRest_SkillNumText8
	
	g_Infant_SkillRest_YuanBaoPay = 1;
	Infant_SkillRest_YuanBaoPay:SetCheck(g_Infant_SkillRest_YuanBaoPay)
end

function Infant_SkillReset_OnEvent( event )
	if ( event=="UI_COMMAND" and tonumber(arg0) == 89061 ) then
		local xx = Get_XParam_INT(0);
		g_targetId = DataPool : GetNPCIDByServerID(xx);
		if g_targetId == -1 then
			return
		end
		Infant_SkillReset_UpdateInfo(1);
		Infant_SkillReset_BeginCareObject()
		if g_Infant_SkillRest_YuanBaoPay == 1 or g_Infant_SkillRest_YuanBaoPay == 0 then
			Infant_SkillRest_YuanBaoPay:SetCheck(g_Infant_SkillRest_YuanBaoPay)
		end
		this:Show()
		return
	elseif (event=="TOGGLE_UPDATE_INFANT") then
		Infant_SkillReset_UpdateInfo(0);
	elseif (event == "UNIT_MONEY") then
		Infant_SkillRest_Demand_Jiaozi:SetProperty("MoneyNumber", NEEDMONEY)
		Infant_SkillRest_Currently_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE") then
		Infant_SkillRest_Demand_Jiaozi:SetProperty("MoneyNumber", NEEDMONEY)
		Infant_SkillRest_Currently_Jiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	--重洗子女技能生成新的数据
	elseif (event == "INFANT_SKILL_UPDATE_RECOIN" and this:IsVisible()) then
		Infant_SkillRest_UpDateRecoin();
	elseif (event == "INFANT_SKILL_RECOIN_CONFIRM_OK") then
			Infant_SkillRest_Reset(1)
			g_Infant_SkillRest_YuanBaoPay = Infant_SkillRest_YuanBaoPay:GetCheck();
			this:Hide()

	end
end

function Infant_SkillReset_UpdateInfo(nflag)
	if nflag == 1 then
		Infant_SkillRest_Reset()
	end
	Infant_SkillRest_Demand_Jiaozi:SetProperty("MoneyNumber", NEEDMONEY)
	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		return
	end
	local szName = Infant:GetInfantName(g_CurSelInfantIndex);
	Infant_SkillRest_BabyName_Text:SetText(szName);
	local nStage = Infant:GetStage(g_CurSelInfantIndex)
	local nSex = Infant:GetInfantSex(g_CurSelInfantIndex)

	Infant_SkillRest_ExplainText:SetText("#{ZNJCS_130825_70}")
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
				Infant_Skill_Icon[i]:SetToolTip("");
				Infant_Skill_Icon[i]:SetProperty("Image", szIcon)
				Infant_Skill_Name_Text[i]:SetText(szSkillName.."("..nSkillLevel.."#{WH_090729_12}"..")")
				Infant_Skill_Value_Text[i]:SetText("+"..nSkillEffect)
			end
		end
	end
	if  g_Infant_SkillReset_state == 0 then
		for i = 1, nSkillCount do
		--	Infant_Skill_Icon[i]:SetToolTip("#{ZNJCS_130825_61}");
			Infant_Skill_Icon[i+4]:SetProperty("Image", "")
			Infant_Skill_Name_Text[i+4]:SetText("")
			Infant_Skill_Value_Text[i+4]:SetText("")

		end
	end
	-- 头像
	Infant_SkillRest_BabyFace_Image:SetProperty("Image", g_Infant_Head_Image[nStage*g_TotalSex + nSex + 1])
end

function Infant_SkillRest_UpDateRecoin()

	for i = 1, 4 do
		local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetRefreshInfantSkillInfo(g_CurSelInfantIndex, i - 1)

		if nSkillID == -1 then

			Infant_Skill_Icon[i+4]:SetProperty("Image", "")
			Infant_Skill_Name_Text[i+4]:SetText("")
			Infant_Skill_Value_Text[i+4]:SetText("")
		else
			if szIcon ~= nil then
				Infant_Skill_Icon[i+4]:SetProperty("Image", szIcon)
				Infant_Skill_Name_Text[i+4]:SetText(szSkillName.."("..nSkillLevel.."#{WH_090729_12}"..")")
				Infant_Skill_Value_Text[i+4]:SetText("+"..nSkillEffect)
			end
		end
	end

	Infant_SkillRest_Btn:Enable()
	g_Infant_SkillReset_state =1
end

function Infant_SkillRest_OK()

		--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
		-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{WHZN_141216_45}")
		return
	end

	local level = Player:GetData("LEVEL");
	if level < 50 then
		PushDebugMessage("#{WHZN_141216_50}")
		return
	end

	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		PushDebugMessage("#{WHZN_141216_51}")
		return
	end
	local guid_H = -1;
	local guid_L = -1;
	guid_H, guid_L = Infant:GetInfantGUID(g_CurSelInfantIndex);
	if guid_H == -1 and guid_L == -1 then
		return
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("GetNewSkillGroup");
		Set_XSCRIPT_ScriptID(890600);
		Set_XSCRIPT_Parameter(0,guid_H);
		Set_XSCRIPT_Parameter(1,guid_L);
		Set_XSCRIPT_Parameter(2, tonumber(Infant_SkillRest_YuanBaoPay:GetCheck()) );
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
end

function Infant_SkillRest_Set_MouseLeave(index)
	if	index <4 then
		PushEvent("INFANT_SKILL_MOUSE_LEAVE")
	else
		PushEvent("INFANT_SKILL_MOUSE_LEAVE_NEW")
	end
end

function Infant_SkillRest_MouseEnter( index )
	if index <4 then
		local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(g_CurSelInfantIndex, index)
	else
		local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetRefreshInfantSkillInfo(g_CurSelInfantIndex, index- 4)
	end
	if nSkillID == -1 then
		return;
	end
	if 1 == SystemSetup:IsClassic() then
		local SetX = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteXPosition") + Infant_SkillRest_Back:GetProperty("AbsoluteXPosition") + Infant_SkillRest_Frame:GetProperty("AbsoluteXPosition");
		local SetY = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteYPosition") + Infant_SkillRest_Back:GetProperty("AbsoluteYPosition") + Infant_SkillRest_Frame:GetProperty("AbsoluteYPosition");
		local SetWidth = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteWidth")
		local SetHeight = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteHeight")
		if index <4 then
			PushEvent("INFANT_SKILL_MOUSE_ENTER",SetX,SetY,SetWidth,SetHeight,g_CurSelInfantIndex,index)
		else
			if g_Infant_SkillReset_state ==1 then
				PushEvent("INFANT_SKILL_MOUSE_ENTER_NEW",SetX,SetY,SetWidth,SetHeight,g_CurSelInfantIndex,index-4)
			end
		end
	elseif 0 == SystemSetup:IsClassic() then
		local SetX = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteXPosition") + Infant_SkillRest_Back:GetProperty("AbsoluteXPosition") + Infant_SkillRest_Frame:GetProperty("AbsoluteXPosition") + Infant_SkillRest_Frame_Client:GetProperty("AbsoluteXPosition");
		local SetY = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteYPosition") + Infant_SkillRest_Back:GetProperty("AbsoluteYPosition") + Infant_SkillRest_Frame:GetProperty("AbsoluteYPosition") + Infant_SkillRest_Frame_Client:GetProperty("AbsoluteYPosition");
		local SetWidth = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteWidth")
		local SetHeight = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteHeight")
		if index <4 then
			PushEvent("INFANT_SKILL_MOUSE_ENTER",SetX,SetY,SetWidth,SetHeight,g_CurSelInfantIndex,index)
		else
			if g_Infant_SkillReset_state ==1 then
				PushEvent("INFANT_SKILL_MOUSE_ENTER_NEW",SetX,SetY,SetWidth,SetHeight,g_CurSelInfantIndex,index-4)
			end
		end
	end

end
--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function Infant_SkillReset_BeginCareObject()
	this:CareObject(g_targetId, 1, "Infant_SkillReset")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function Infant_SkillReset_StopCareObject()
	this:CareObject(g_targetId, 0, "Infant_SkillReset")
end

--取消或者关闭界面
function Infant_SkillRest_CloseUI()
	if g_Infant_SkillReset_state == 1  then
		Infant_SkillReset_SendSkillConfirm()
		return
	end
	Infant_SkillReset_StopCareObject()
	Infant_SkillRest_Reset(1)
	g_Infant_SkillRest_YuanBaoPay = Infant_SkillRest_YuanBaoPay:GetCheck();
	this:Hide()
end

function Infant_SkillRest_Reset(flag)
	g_Infant_SkillReset_state =0

	Infant_SkillRest_BabyName_Text:SetText("");
	Infant_SkillRest_BabyFace_Image:SetProperty("Image", "")

	for i = 1, 4 do
		Infant_Skill_Icon[i+4]:SetProperty("Image", "")
		Infant_Skill_Name_Text[i+4]:SetText("")
		Infant_Skill_Value_Text[i+4]:SetText("")
	end

	if flag == 1 then
		for i = 1, 4 do
			Infant_Skill_Icon[i]:SetProperty("Image", "")
			Infant_Skill_Name_Text[i]:SetText("")
			Infant_Skill_Value_Text[i]:SetText("")
		end
	end


	Infant_SkillRest_Btn:Disable();

end

function Infant_SkillRest_OnHiden()
	g_Infant_SkillRest_YuanBaoPay = Infant_SkillRest_YuanBaoPay:GetCheck();
	Infant_SkillRest_Reset(1)
end

function Infant_SkillRest_SaveChange_Clicked()

		--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
		-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{WHZN_141216_45}")
		return
	end

	if g_Infant_SkillReset_state ==1 then

		local guid_H = -1;
		local guid_L = -1;
		guid_H, guid_L = Infant:GetInfantGUID(g_CurSelInfantIndex);
		if guid_H == -1 and guid_L == -1 then
			return
		end
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("RefereshNewInfantSkill");
			Set_XSCRIPT_ScriptID(890600);
			Set_XSCRIPT_Parameter(0,guid_H);
			Set_XSCRIPT_Parameter(1,guid_L);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();

	end

		--设置重洗状态
	g_Infant_SkillReset_state =0

	Infant_SkillRest_Reset(0)
	Infant_SkillReset_UpdateInfo()

end

--发送替换子女技能的二次确认
function Infant_SkillReset_SendSkillConfirm()
	PushEvent("INFANT_SKILL_RECOIN_CONFIRM")
end
