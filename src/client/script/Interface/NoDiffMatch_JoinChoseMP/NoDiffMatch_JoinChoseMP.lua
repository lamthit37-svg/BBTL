-- 界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_MenPaiNameList =
{
	[0]  ="#{WCBZ_180128_59}",	--少林
	[1]  ="#{WCBZ_180128_65}",	--明教
	[2]  ="#{WCBZ_180128_67}",	--丐帮
	[3]  ="#{WCBZ_180128_61}",	--武当
	[4]  ="#{WCBZ_180128_68}",	--峨嵋
	[5]  ="#{WCBZ_180128_66}",	--星宿
	[6]  ="#{WCBZ_180128_60}",	--天龙
	[7]  ="#{WCBZ_180128_63}",	--天山
	[8]  ="#{WCBZ_180128_64}",	--逍遥
	[9]  ="#{WCBZ_180128_57}",	--无门派
	[10] ="#{WCBZ_180128_62}",	--慕容
	[11] ="#{WCBZ_180128_69}",	--唐门
	[12] ="#{WCBZ_180128_70}",	--鬼谷
	[13] ="#{WCBZ_180516_646}",	--桃花岛
	[14] ="#{XMPHM_210604_01}",
	[15] ="#{GMGameInterface_Script_DataPool_Info_ERenGu}", --menpai15 mptodo
}

local g_TarGuid = ""
local g_TarMenpai = 9
local g_TarName = ""

function NoDiffMatch_JoinChoseMP_PreLoad()
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
    this:RegisterEvent("CORPS_INVITE_MEM_AGREE_2018")
	--战队相关的UI都要关闭
	this:RegisterEvent("CORPS_ALL_UI_CLOSED_2018")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_JoinChoseMP_OnLoad()
	
end

function NoDiffMatch_JoinChoseMP_OnEvent(event)

	if event == "CORPS_INVITE_MEM_AGREE_2018" then
		NoDiffMatch_JoinChoseMP_Show()
		
	elseif( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_JoinChoseMP_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NoDiffMatch_JoinChoseMP_ResetPos()
	end

end

function NoDiffMatch_JoinChoseMP_Show()
		g_TarName = tostring(arg0)
		g_TarGuid = tostring(arg1)
		g_TarMenpai = 9
		
		local toptext = ScriptGlobal_Format("#{WCBZ_180128_135}" , g_TarName );
		NoDiffMatch_JoinChoseMP_TopText:SetText(toptext)
		
		local maintext = ScriptGlobal_Format("#{WCBZ_180128_136}" , g_TarName );
		NoDiffMatch_JoinChoseMP_MainText:SetText(maintext)
		
		
		NoDiffMatch_JoinChoseMP_Choice:ResetList();
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("请选择参赛门派", -1 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("少林", 0 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("明教", 1 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("丐帮", 2 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("武当", 3 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("峨嵋", 4 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("星宿", 5 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("天龙", 6 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("天山", 7 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("逍遥", 8 );
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("慕容", 10);
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("唐门", 11);
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("鬼谷", 12);
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("桃花岛", 13);
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("绝情谷", 14);
		NoDiffMatch_JoinChoseMP_Choice:ComboBoxAddItem("恶人谷", 15);--menpai15 mptodo
		NoDiffMatch_JoinChoseMP_Choice:SetText("#{WCBZ_180128_137}")
		NoDiffMatch_JoinChoseMP_Choice:SetCurrentSelect( 0 );
			
		this:Show()
end

function NoDiffMatch_JoinChoseMP_Choice_Clicked()
	
	local _name,ComIdx = NoDiffMatch_JoinChoseMP_Choice:GetCurrentSelect()
	
	if ComIdx >= 0 and ComIdx <= 15 then --menpai15 mptodo
		NoDiffMatch_JoinChoseMP_Choice:SetText(g_MenPaiNameList[ComIdx])
		g_TarMenpai = ComIdx
	end
	
end

function NoDiffMatch_JoinChoseMP_OK_Clicked()
	
	if g_TarMenpai < 0 or g_TarMenpai > 15 or g_TarMenpai == 9 then--menpai15 mptodo
		local tips = ScriptGlobal_Format("#{WCBZ_180128_138}" , g_TarName );
		PushDebugMessage(tips)
		return
	end
	
	local nRet = CorpsUI_2018:CorpsOper_InviteCorps(2, g_TarMenpai)

	if nRet == nil then
		this:Hide()
		return
	end
	--0、没队伍
	if nRet == 0 then
		PushDebugMessage("#{WCBZ_180128_115}")
		this:Hide()
		return
	end
	--1、只有战队的队长或副队长作为队长时，才可邀请队员加入战队
	if nRet == 1 then
		PushDebugMessage("#{WCBZ_180128_115}")
		this:Hide()
		return
	end
	-- 只有战队的队长或副队长作为队长时，才可邀请队员加入战队
	if nRet == 2 then
		PushDebugMessage("#{WCBZ_180128_115}")
		this:Hide()
		return
	end
	
	if nRet == 3 then
		PushDebugMessage("#{WCBZ_180128_116}")
		this:Hide()
		return
	end
	
	-- 不足2人
	if nRet == 4 then
		PushDebugMessage("#{WCBZ_180128_118}")
		this:Hide()
		return
	end
	
	if nRet == 5 then
		PushDebugMessage("#{WCBZ_180128_139}")
		return
	end
	
	--调用接口
	this:Hide()
end

function NoDiffMatch_JoinChoseMP_Close_Clicked()
	PushEvent("CORPS_INVITE_CANCLECHOOSEMP_2018", g_TarName)
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_JoinChoseMP_ResetPos()
	NoDiffMatch_JoinChoseMP_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_JoinChoseMP_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
