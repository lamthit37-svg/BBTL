-- 战队组建UI
-- 界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_clientNpcId = -1
local g_ServerNpcId = -1

local g_SendInfo =
{
[1] = {guid="0XFFFFFFFFFFFFFFFF", chosemp=9},
[2] = {guid="0XFFFFFFFFFFFFFFFF", chosemp=9},
[3] = {guid="0XFFFFFFFFFFFFFFFF", chosemp=9},
[4] = {guid="0XFFFFFFFFFFFFFFFF", chosemp=9},
[5] = {guid="0XFFFFFFFFFFFFFFFF", chosemp=9},
[6] = {guid="0XFFFFFFFFFFFFFFFF", chosemp=9},
}

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

local g_Pictures ={}
local g_Name ={}
local g_Menpai ={}
local g_Level ={}
local g_SelectMp ={}
local g_MaxMemberNum = 6

function NoDiffMatch_CreateTeam_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_CreateTeam_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_CreateTeam_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_CreateTeam_Frame:GetProperty("UnifiedYPosition");
	
	g_Pictures[1] = NoDiffMatch_CreateTeam_List1_Pic;
	g_Pictures[2] = NoDiffMatch_CreateTeam_List2_Pic;
	g_Pictures[3] = NoDiffMatch_CreateTeam_List3_Pic;
	g_Pictures[4] = NoDiffMatch_CreateTeam_List4_Pic;
	g_Pictures[5] = NoDiffMatch_CreateTeam_List5_Pic;
	g_Pictures[6] = NoDiffMatch_CreateTeam_List6_Pic;
	
	g_Name[1] = NoDiffMatch_CreateTeam_List1_1;
	g_Name[2] = NoDiffMatch_CreateTeam_List2_1;
	g_Name[3] = NoDiffMatch_CreateTeam_List3_1;
	g_Name[4] = NoDiffMatch_CreateTeam_List4_1;
	g_Name[5] = NoDiffMatch_CreateTeam_List5_1;
	g_Name[6] = NoDiffMatch_CreateTeam_List6_1;
	
	g_Menpai[1] = NoDiffMatch_CreateTeam_List1_2;
	g_Menpai[2] = NoDiffMatch_CreateTeam_List2_2;
	g_Menpai[3] = NoDiffMatch_CreateTeam_List3_2;
	g_Menpai[4] = NoDiffMatch_CreateTeam_List4_2;
	g_Menpai[5] = NoDiffMatch_CreateTeam_List5_2;
	g_Menpai[6] = NoDiffMatch_CreateTeam_List6_2;
	
	g_Level[1] = NoDiffMatch_CreateTeam_List1_3;
	g_Level[2] = NoDiffMatch_CreateTeam_List2_3;
	g_Level[3] = NoDiffMatch_CreateTeam_List3_3;
	g_Level[4] = NoDiffMatch_CreateTeam_List4_3;
	g_Level[5] = NoDiffMatch_CreateTeam_List5_3;
	g_Level[6] = NoDiffMatch_CreateTeam_List6_3;
	
	g_SelectMp[1] = NoDiffMatch_CreateTeam_List1_MenPaiChoice;
	g_SelectMp[2] = NoDiffMatch_CreateTeam_List2_MenPaiChoice;
	g_SelectMp[3] = NoDiffMatch_CreateTeam_List3_MenPaiChoice;
	g_SelectMp[4] = NoDiffMatch_CreateTeam_List4_MenPaiChoice;
	g_SelectMp[5] = NoDiffMatch_CreateTeam_List5_MenPaiChoice;
	g_SelectMp[6] = NoDiffMatch_CreateTeam_List6_MenPaiChoice;
	
end

--初始化控件数据
function NoDiffMatch_CreateTeam_InitUIData()

	NoDiffMatch_CreateTeam_Top_NameInput:SetText("");

	for i=1, g_MaxMemberNum do
		g_SendInfo[i].guid = "0XFFFFFFFFFFFFFFFF"
		g_SendInfo[i].chosemp = 9
		
		g_Pictures[i]:Hide()
		g_Name[i]:SetText("")
		g_Menpai[i]:SetText("")
		g_Level[i]:SetText("")

		g_SelectMp[i]:ResetList()
		g_SelectMp[i]:ComboBoxAddItem("请选择参赛门派", -1 );
		g_SelectMp[i]:ComboBoxAddItem("少林", 0 );
		g_SelectMp[i]:ComboBoxAddItem("明教", 1 );
		g_SelectMp[i]:ComboBoxAddItem("丐帮", 2 );
		g_SelectMp[i]:ComboBoxAddItem("武当", 3 );
		g_SelectMp[i]:ComboBoxAddItem("峨嵋", 4 );
		g_SelectMp[i]:ComboBoxAddItem("星宿", 5 );
		g_SelectMp[i]:ComboBoxAddItem("天龙", 6 );
		g_SelectMp[i]:ComboBoxAddItem("天山", 7 );
		g_SelectMp[i]:ComboBoxAddItem("逍遥", 8 );
		g_SelectMp[i]:ComboBoxAddItem("慕容", 10);
		g_SelectMp[i]:ComboBoxAddItem("唐门", 11);
		g_SelectMp[i]:ComboBoxAddItem("鬼谷", 12);
		g_SelectMp[i]:ComboBoxAddItem("桃花岛", 13);
		g_SelectMp[i]:ComboBoxAddItem("绝情谷", 14);
		g_SelectMp[i]:ComboBoxAddItem("恶人谷", 15);--menpai15 mptodo
		g_SelectMp[i]:SetText("#{WCBZ_180128_137}")
		g_SelectMp[i]:SetCurrentSelect( -1 );
		g_SelectMp[i]:Hide()
	end
	
	g_clientNpcId = -1
end

function NoDiffMatch_CreateTeam_InitMemberListData()
	local memCount = DataPool:GetTeamMemberCount();
	-- 如果队伍个数是零, 不显示界面.
	if(memCount <= 0) then
		return 0
	end

	local msg = ScriptGlobal_Format("#{WCBZ_180128_50}", memCount)
	NoDiffMatch_CreateTeam_Top_Text3:SetText(msg)


	local nIter = 2
	for i = 0, memCount - 1 do
			local name ,menpai, level, dead, offline, sex, worldid, score, guildname = DataPool:GetTeamMemInfoByIndex( i );
			local guid = DataPool:GetTeamMemGUIDByUIIndex( i );

			if level <= 0 or guid == "" then
			    break  --根据原有团队设计,小队中间必然没有空位
			end

			if i == 0 then
		    	g_Name[1]:SetText( name )
    			g_Menpai[1]:SetText( g_MenPaiNameList[menpai] )
    			g_Level[1]:SetText( tostring(level) )
				g_Pictures[1]:Show()
				g_SendInfo[1].guid = guid
				
    		elseif (nIter <= g_MaxMemberNum) then
    			g_Name[nIter]:SetText( name )
    			g_Menpai[nIter]:SetText( g_MenPaiNameList[menpai] )
    			g_Level[nIter]:SetText( tostring(level) )
				g_Pictures[nIter]:Show()
				g_SendInfo[nIter].guid = guid
                nIter = nIter + 1
				
            else --居然有多的?
                return 0
            end
	end

	for i=1,memCount do
		g_SelectMp[i]:Show()
	end
	
	return 1
end

function NoDiffMatch_CreateTeam_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_CreateTeam_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NoDiffMatch_CreateTeam_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "NoDiffMatch_CreateTeam") then
			this:Hide();
		end
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 8927011 then
	    --先初始化
		NoDiffMatch_CreateTeam_InitUIData()

		g_ServerNpcId = Get_XParam_INT(0);
		g_clientNpcId = Target:GetServerId2ClientId(g_ServerNpcId);

		if 1 == NoDiffMatch_CreateTeam_InitMemberListData() then
    		this:CareObject(g_clientNpcId, 1, "NoDiffMatch_CreateTeam");
    		this:Show();
        end
	  end
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		this:Hide();
	end

end
--================================================
--关闭
--================================================
function NoDiffMatch_CreateTeam_CloseClicked()
   this:Hide();
end


--================================================
--确定创建
--================================================
function NoDiffMatch_CreateTeam_Accept_Clicked()
	local corpsName = NoDiffMatch_CreateTeam_Top_NameInput:GetText()
	if corpsName ~= nil and corpsName ~="" then
		local nRet = CorpsUI_2018:CreateCorps(corpsName, g_ServerNpcId)
		if nRet ~= nil and nRet == 1 then
			PushDebugMessage("#{WCBZ_180128_74}")
			return
		end
		if nRet ~= nil and nRet == 2 then
			PushDebugMessage("#{WCBZ_180128_75}")
			return
		end
		if nRet ~= nil and nRet == 3 then
			PushDebugMessage("#{WCBZ_180128_614}")
			return
		end
		if nRet ~= nil and nRet == 4 then
			PushDebugMessage("#{WCBZ_180128_76}")
			return
		end
	elseif corpsName == nil then
		PushDebugMessage("#{WCBZ_180128_73}")
		return
	elseif corpsName == "" then
		PushDebugMessage("#{WCBZ_180128_73}")
		return
	end
	this:Hide()
end

function NoDiffMatch_CreateTeam_SelectMp(index) 
	if index < 1 or index > g_MaxMemberNum then
		return
	end
	
	local _name,ComIdx = g_SelectMp[index]:GetCurrentSelect()
	
	if ComIdx >= -1 and ComIdx <= 15 and ComIdx ~= 9 then --menpai15 mptodo
		--g_SelectMp[index]:SetText(g_MenPaiNameList[ComIdx])
		g_SendInfo[index].chosemp = ComIdx
		CorpsUI_2018:SelectMpInfo(index-1, g_SendInfo[index].guid, g_SendInfo[index].chosemp)
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_CreateTeam_ResetPos()
	NoDiffMatch_CreateTeam_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_CreateTeam_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

