local g_MoneyChallengeSide = -1;

local g_MChallenge_MsgSize = 27
local g_MChallenge_ErrorMsg =
{
[1] = "#{SJBW_130823_02}";			--不在校场
[2] = "#{SJBW_130823_03}";			--对方不在校场
[3] = "#{SJBW_130823_04}";				--等级不足15
[4] = "#{SJBW_130823_05}";				--对方等级不足15
[5] = "#{SJBW_130823_06}";				--赏金池有钱未领
[6] = "#{SJBW_130823_07}";				--对方赏金池有钱未领
[7] = "#{SJBW_130823_08}";				--疑似被盗,短信验证
[8] = "#{SJBW_130823_09}";				--禁止交易
[9] = "#{ZYXT_120528_16}";				--安全时间
[10] = "#{SJBW_130823_10}";				--贴身硬件密保
[11] = "";				--电话密保(这个有提示了)
[12] = "#{SJBW_130823_13}";				--自己有小队
[13] = "#{SJBW_130823_14}";				--对方有小队
[14] = "#{SJBW_130823_15}";				--自己有团队
[15] = "#{SJBW_130823_16}";				--对方有团队
[16] = "";				--自己有确认框
[17] = "#{SJBW_130823_17}";				--对方有确认框
[18] = "#{SJBW_130823_24}";				--自己拒绝
[19] = "#{SJBW_130823_25}";				--对方拒绝
[20] = "#{SJBW_130823_24}";				--自己取消
[21] = "#{SJBW_130823_25}";				--对方取消
[22] = "#{SJBW_130823_29}";				--钱数不对
[23] = "#{SJBW_130823_30}";				--钱不够
[24] = "#{SJBW_130823_34}";				--钱不够
[25] = "#{SJBW_130823_33}";				--挑战方钱不够
[26] = "#{SJBW_130823_35}";				--对方不在确认状态
[27] = "#{SJBW_130823_64}";				--赏金比武没有开放
}
function MoneyChallenge_PreLoad()

	-- 打开界面
	this:RegisterEvent("MONEY_CHALLENGE_OPEN");

	this:RegisterEvent("MONEY_CHALLENGE_CLOSE");
	this:RegisterEvent("MONEY_CHALLENGE_UPDATE");
	this:RegisterEvent("MONEY_CHALLENGE_MESSAGE");

end

-- 注册onLoad事件
function MoneyChallenge_OnLoad()

end

-- OnEvent
function MoneyChallenge_OnEvent(event)

	-- 打开界面事件.
	--
	
	if ( event == "MONEY_CHALLENGE_OPEN" ) then
		g_MoneyChallengeSide = tonumber(arg0);
		if g_MoneyChallengeSide ~= 0 and g_MoneyChallengeSide ~= 1 then
			MoneyChallenge_CloseAll()
			return
		end
		MoneyChallenge_Open(arg1)
		this:Show()
		DataPool:SetCanUseHotKey(0);
		return
	end;

	if ( event == "MONEY_CHALLENGE_CLOSE" ) then
		g_MoneyChallengeSide = -1
		this:Hide()
		return
	end;

	if ( event == "MONEY_CHALLENGE_UPDATE" ) then
		local nMoney = arg0
		MoneyChallenge_MoneyEditorText:Hide()
		MoneyChallenge_MoneySimpleText:SetText(nMoney)
		MoneyChallenge_MoneyLace:Show()
		MoneyChallenge_InviteButton:Disable()
		MoneyChallenge_AcceptButton:Hide()
		MoneyChallenge_RefuseButton:Hide()
		MoneyChallenge_WaitText:Show()
		return;
	end;

	--if(event == "HIDE_ON_SCENE_TRANSED" and this:IsVisible()) then
	--	this:Hide();
	--end
	if ( event == "MONEY_CHALLENGE_MESSAGE" ) then
		local errID = tonumber(arg0)
		if errID < 1 or errID > g_MChallenge_MsgSize then
			return
		end
		PushDebugMessage(g_MChallenge_ErrorMsg[errID])
	end
	
end

function MoneyChallenge_Open(nMoney)
		MoneyChallenge_FakeObject1:SetFakeObject("")--先清空已经显示的模型,否则可能会出crash
		MoneyChallenge_FakeObject2:SetFakeObject("")--一个模型被多个窗口绘制,必崩
	if g_MoneyChallengeSide == 0 then
	
		--自己是主挑战方,自己在左边,对方在右边
		local strModelName, strCharName, nlevel, menpai = DataPool:MoneyChallengeGetInfo(0)
		--local strCharName =  Player:GetName();
		--local menpai = Player:GetData("MEMPAI");
		--local nlevel = Player:GetData("LEVEL")
		MoneyChallenge_Name1:SetText(strCharName)
		MoneyChallenge_menpai1:SetText(MoneyChallenge_GetMenpaiName(menpai))
		MoneyChallenge_level1:SetText(tostring(nlevel))
		MoneyChallenge_FakeObject1:SetFakeObject(strModelName);
		
		strModelName, strCharName, nlevel, menpai = DataPool:MoneyChallengeGetInfo(1)
		MoneyChallenge_Name2:SetText(strCharName)
		MoneyChallenge_menpai2:SetText(MoneyChallenge_GetMenpaiName(menpai))
		MoneyChallenge_level2:SetText(tostring(nlevel))
		MoneyChallenge_FakeObject2:SetFakeObject(strModelName)
		
		MoneyChallenge_MoneyEditorText:Show()
		MoneyChallenge_MoneyEditorText:SetText(nMoney)
		MoneyChallenge_MoneyLace:Hide()
		MoneyChallenge_InviteButton:Show()
		MoneyChallenge_InviteButton:Enable()
		MoneyChallenge_AcceptButton:Hide()
		MoneyChallenge_RefuseButton:Hide()
		MoneyChallenge_WaitText:Hide()
		
		this:Show();
		
	elseif g_MoneyChallengeSide == 1 then
		--自己是被挑战方,自己在右边,对方在左边
		local strModelName, strCharName, nlevel, menpai = DataPool:MoneyChallengeGetInfo(0)
		--local strCharName =  Player:GetName();
		--local menpai = Player:GetData("MEMPAI");
		--local nlevel = Player:GetData("LEVEL")
		MoneyChallenge_Name2:SetText(strCharName)
		MoneyChallenge_menpai2:SetText(MoneyChallenge_GetMenpaiName(menpai))
		MoneyChallenge_level2:SetText(tostring(nlevel))
		MoneyChallenge_FakeObject2:SetFakeObject(strModelName);
		
		local strModelName = ""
		strModelName, strCharName, nlevel, menpai = DataPool:MoneyChallengeGetInfo(1)
		MoneyChallenge_Name1:SetText(strCharName)
		MoneyChallenge_menpai1:SetText(MoneyChallenge_GetMenpaiName(menpai))
		MoneyChallenge_level1:SetText(tostring(nlevel))
		MoneyChallenge_FakeObject1:SetFakeObject(strModelName)
		
		MoneyChallenge_MoneyEditorText:Hide()
		MoneyChallenge_MoneySimpleText:SetText(nMoney)
		MoneyChallenge_MoneyLace:Show()
		MoneyChallenge_InviteButton:Hide()
		MoneyChallenge_AcceptButton:Show()
		MoneyChallenge_RefuseButton:Show()
		MoneyChallenge_WaitText:Hide()
		this:Show();
	else
		this:Hide();
	end
end
function MoneyChallenge_CloseAll()
	g_MoneyChallengeSide = -1
	this:Hide();
end

function MoneyChallenge_OnInviteButtonClick()
	if g_MoneyChallengeSide ~= 0 then
		return
	end
	local nMoney = tonumber(MoneyChallenge_MoneyEditorText:GetText());
	if nMoney == nil or nMoney < 1 or nMoney > 100 then
		PushDebugMessage("#{SJBW_130823_26}");
		return
	end
	DataPool:MoneyChallengeInvite2(nMoney)
end

function MoneyChallenge_OnAcceptButtonClick()
	if g_MoneyChallengeSide ~= 1 then
		return
	end
	DataPool:MoneyChallengeAccept()
end

function MoneyChallenge_MoneyEditorText_Change()
	local nMoney = tonumber(MoneyChallenge_MoneyEditorText:GetText());
	if nMoney == nil or nMoney < 1 then
		MoneyChallenge_MoneyEditorText:SetText("1")
		--PushDebugMessage("#{SJBW_130823_26}");
		return
	end
	if nMoney > 100 then
		MoneyChallenge_MoneyEditorText:SetText("100")
		PushDebugMessage("#{SJBW_130823_26}");
		return
	end
end

--===============================================
-- 窗口关闭执行的   Hidden
--===============================================
function MoneyChallenge_Cancel()

	DataPool:MoneyChallengeClose(g_MoneyChallengeSide)
	
	DataPool:SetCanUseHotKey(1);

end



function MoneyChallenge_GetMenpaiName(menpai)
		local strMenPai = ""
		if(0 == menpai) then
			strMenPai = "少林";
		elseif(1 == menpai) then
			strMenPai = "明教";
		elseif(2 == menpai) then
			strMenPai = "丐帮";
		elseif(3 == menpai) then
			strMenPai = "武当";
		elseif(4 == menpai) then
			strMenPai = "峨嵋";
		elseif(5 == menpai) then
			strMenPai = "星宿";
		elseif(6 == menpai) then
			strMenPai = "天龙";
		elseif(7 == menpai) then
			strMenPai = "天山";
		elseif(8 == menpai) then
			strMenPai = "逍遥";
		elseif(10 == menpai) then
			strMenPai = "慕容";
		elseif(11 == menpai) then
			strMenPai = "唐门";
		elseif(12 == menpai) then
			strMenPai = "鬼谷";
		elseif(13 == menpai) then
			strMenPai = "#{XQ_MP_15}"; --桃花岛
		elseif(14 == menpai) then
			strMenPai = "#{XMPHM_210604_01}"; 
		elseif(15 == menpai) then--menpai15 mptodo
			strMenPai = "#{GMGameInterface_Script_DataPool_Info_ERenGu}"; 
		else
			strMenPai = "无门派";
		end
		return strMenPai
end