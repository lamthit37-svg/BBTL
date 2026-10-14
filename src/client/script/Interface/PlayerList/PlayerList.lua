--   PlayerList
--   PlayerList_List
local pl = {}
local MAX_PLAYER_IDX = 16


local g_PlayerList_Frame_UnifiedXPosition;
local g_PlayerList_Frame_UnifiedYPosition;
local g_flag = false
local g_PLAYERLIST_SELECT = {}
local g_PLAYERLIST_SELECT_ENEMY = {}

local g_check2_data = {
}
g_check2_data.scenes = {
	671, 672, 673, 674, 675, 676
}
g_check2_data.buffids = {
	3307, 3311, 3315, 3319, 3323, 3308, 3312, 3316, 3320, 3324,
}

function PlayerList_PreLoad()
	this:RegisterEvent("PLAYERLIST_SHOW");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


function PlayerList_OnLoad()

	pl = {
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
		{id=-1,name="",level=0,guild="",menpai="",isFriend=false,iconstr="ENEMY",enemyFlag = 0,teamPower = 0, alliance="",perhp=0,buffid={0,0,0,0,0},havemskbuff=0},
	   }

	g_PlayerList_Frame_UnifiedXPosition	= PlayerList_Frame:GetProperty("UnifiedXPosition");
	g_PlayerList_Frame_UnifiedYPosition	= PlayerList_Frame:GetProperty("UnifiedYPosition");
	
	--这个checkbtn现在被check的时候是显示，默认是隐藏
	PlayerList_HideCheck:SetCheck(0)
	
	g_PLAYERLIST_SELECT[1] = "Designatedguild"
	g_PLAYERLIST_SELECT[2] = "DiffAlliance"
	g_PLAYERLIST_SELECT[3] = "CheckShaolin"
	g_PLAYERLIST_SELECT[4] = "CheckMingjiao"
	g_PLAYERLIST_SELECT[5] = "CheckGaibang"
	g_PLAYERLIST_SELECT[6] = "CheckWudang"
	g_PLAYERLIST_SELECT[7] = "CheckEmei"
	g_PLAYERLIST_SELECT[8] = "CheckXingxiu"
	g_PLAYERLIST_SELECT[9] = "CheckTianlong"
	g_PLAYERLIST_SELECT[10] = "CheckTianshan"
	g_PLAYERLIST_SELECT[11] = "CheckXiaoyao"
	g_PLAYERLIST_SELECT[12] = "CheckMurong"
	g_PLAYERLIST_SELECT[13] = "CheckTangmen"
	g_PLAYERLIST_SELECT[14] = "DiffGuildLeague"
	g_PLAYERLIST_SELECT[15] = "CheckGuigu"
	g_PLAYERLIST_SELECT[16] = "CheckTaohuadao" --桃花岛
	g_PLAYERLIST_SELECT[17] = "CheckMenpai14"
	g_PLAYERLIST_SELECT[18] = "CheckUnBreakable"
	g_PLAYERLIST_SELECT[19] = "CheckMenpai15"--menpai15 mptodo 遍历g_PLAYERLIST_SELECT时的数量从18改为19

	g_PLAYERLIST_SELECT_ENEMY[1] = "DesignatedguildEnemy"
	g_PLAYERLIST_SELECT_ENEMY[2] = "PersonalEnemy"
	g_PLAYERLIST_SELECT_ENEMY[3] = "CheckShaolinEnemy"
	g_PLAYERLIST_SELECT_ENEMY[4] = "CheckMingjiaoEnemy"
	g_PLAYERLIST_SELECT_ENEMY[5] = "CheckGaibangEnemy"
	g_PLAYERLIST_SELECT_ENEMY[6] = "CheckWudangEnemy"
	g_PLAYERLIST_SELECT_ENEMY[7] = "CheckEmeiEnemy"
	g_PLAYERLIST_SELECT_ENEMY[8] = "CheckXingxiuEnemy"
	g_PLAYERLIST_SELECT_ENEMY[9] = "CheckTianlongEnemy"
	g_PLAYERLIST_SELECT_ENEMY[10] = "CheckTianshanEnemy"
	g_PLAYERLIST_SELECT_ENEMY[11] = "CheckXiaoyaoEnemy"
	g_PLAYERLIST_SELECT_ENEMY[12] = "CheckMurongEnemy"
	g_PLAYERLIST_SELECT_ENEMY[13] = "CheckTangmenEnemy"
	g_PLAYERLIST_SELECT_ENEMY[14] = "DiffGuildLeagueEnemy"
	g_PLAYERLIST_SELECT_ENEMY[15] = "CheckGuiguEnemy"
	g_PLAYERLIST_SELECT_ENEMY[16] = "CheckTaohuadaoEnemy" --桃花岛
	g_PLAYERLIST_SELECT_ENEMY[17] = "CheckMenpai14Enemy"
	g_PLAYERLIST_SELECT_ENEMY[18] = "CheckUnBreakableEnemy"
	g_PLAYERLIST_SELECT_ENEMY[19] = "CheckMenpai15Enemy"--menpai15 mptodo 遍历g_PLAYERLIST_SELECT_ENEMY时的数量从18改为19

end

function PlayerList_IsSelectAnyCustom()
	if g_flag == true then
		for i = 1, 19 do
			local temp = SystemSetup:GetCustomPlayerList(g_PLAYERLIST_SELECT[i]);
			if temp == 1 then
				return 1;
			end
		end
	end
	if g_flag == false then
		for i = 1, 19 do
			local temp = SystemSetup:GetCustomPlayerList(g_PLAYERLIST_SELECT_ENEMY[i]);
			if temp == 1 then
				return 1;
			end
		end
	end
	
	return 0;
end
function PlayerList_OnEvent( event )
	if ( event == "PLAYERLIST_SHOW" ) then
		if( this:IsVisible() ) then
			PlayerList_Hide();
		else
			PlayerList_Show();
		end
	elseif( event == "ADJEST_UI_POS" ) then
		PlayerList_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		PlayerList_ResetPos()


	end
end

function PlayerList_Update(flag)

	PlayerList_List:ClearListBoxEx();

	local color = "";
	local color_real = "";
	local icostr = "";
	if flag == false then
		color = "#cFF0000"
	elseif flag == true then
		if SystemSetup:IsClassic() == 1 then
			color = "#c00FF00"
		else
			color = "#c00FF00"
		end
	end

	for i = 1 ,MAX_PLAYER_IDX do
		if (pl[i].id ~= -1) then
			local na = pl[i].name
			if na == "" then na = "N/A" end

			local lv = pl[i].level

			local bp = pl[i].guild
			if bp == "" then bp = "N/A" end
			
			local stralli = pl[i].alliance
			if stralli ~= " " and bp ~= "N/A" and string.len(stralli) ~= 0 then
				bp = bp.."（"..stralli.."）"
			end

			local mp = pl[i].menpai
			if mp == "" then mp= "无" end

			if pl[i].iconstr == "ENEMY" then
				icostr="#-18"
				color_real = color

				if pl[i].havemskbuff == 1 then
					icostr = "  "
				end 
			elseif pl[i].iconstr == "FLAG" then
				icostr="#-22"
				color_real = color.."#b"
			elseif pl[i].teamPower == 1 or pl[i].teamPower == 3 then
				icostr="#-17"
				color_real = color
			elseif pl[i].teamPower == 2 or pl[i].teamPower == 4 then
				icostr="#-49"
				color_real = color
			else
				icostr="  "
				color_real = color
			end

			local havemaskbuff = false
			local ef = pl[i].enemyFlag
			if pl[i].havemskbuff == 1 then
				lv = "?"
				mp = "?"
				bp = "?"
			end
			local str = ""
--			if SystemSetup:IsClassic() == 1 then
				if ef == 1 then
					--仇敌 
					local choudi = ""
					if  Lua_GetAnonymousCommonSceneInfo() == 0 then
						choudi = "#-47"
					end

					if pl[i].havemskbuff == 1 then 
						choudi = ""
					end

					if pl[i].havemskbuff == 1 then
						lv = "?"
						mp = "?"
						bp = "?"
						str = string.format("%s%s%-23s#cFFFF00%7s  #c00B0F0%-15s#r%24s    #cFFFFFF%-3s级",icostr, color_real ,na ,mp, bp,choudi,lv)
					else
						str = string.format("%s%s%-23s#cFFFF00%15s #c00B0F0%-15s#r%24s    #cFFFFFF%-3d级",icostr, color_real ,na ,mp, bp,choudi,lv)
					end

				elseif ef == 2 then
					--仇人
					local chouren = ""
					if  Lua_GetAnonymousCommonSceneInfo() == 0 then
						chouren = "#-48"
					end

					if pl[i].havemskbuff == 1 then 
						chouren = ""
					end

					if pl[i].havemskbuff == 1 then
					    str = string.format("%s%s%-23s#cFFFF00%7s  #c00B0F0%-15s#r%24s    #cFFFFFF%-3s级",icostr, color_real ,na ,mp, bp,chouren,lv)
					else
						str = string.format("%s%s%-23s#cFFFF00%15s #c00B0F0%-15s#r%24s    #cFFFFFF%-3d级",icostr, color_real ,na ,mp, bp,chouren,lv)
					end
				else
					if pl[i].havemskbuff == 1 then
						str = string.format("%s%s%-23s#cFFFF00%7s  #c00B0F0%-15s#r%27s    #cFFFFFF%-3s级",icostr, color_real ,na ,mp, bp,"",lv)
					else
						str = string.format("%s%s%-23s#cFFFF00%15s #c00B0F0%-15s#r%27s    #cFFFFFF%-3d级",icostr, color_real ,na ,mp, bp,"",lv)
					end
				end
--			else
--				if ef == 1 then
--					--仇敌
--					na = na.." #-47"
--					str = string.format("%s%s%-22s#cFFFFFF%4d级#r  #c0A61CC%-20s#cFFFF00%6s",icostr, color_real ,na ,lv, bp, mp)
--				elseif ef == 2 then
--					--仇人
--					na = na.." #-48"
--					str = string.format("%s%s%-22s#cFFFFFF%4d级#r  #c0A61CC%-20s#cFFFF00%6s",icostr, color_real ,na ,lv, bp, mp)
--				else
--					str = string.format("%s%s%-20s#cFFFFFF%4d级#r  #c0A61CC%-20s#cFFFF00%6s",icostr, color_real ,na ,lv, bp, mp)
--				end
--			end
		--	PlayerList_List:AddItem( str, i, "FFFFFFFF", 4 );
			if flag == false then
				PlayerList_List:AddItemExWithoutLayout(str , i ,12, "FFFFFFFF", 4,0,0,0);
			elseif flag == true then
				PlayerList_List:AddItemExWithoutLayout(str , i ,9, "FFFFFFFF", 4,0,0,0);
			end

			PlayerList_List:SetBarCompareProgress(i-1,pl[i].perhp*100,100)

			for j=1,5 do
				local buffId = pl[i].buffid[j]
				if buffId ~= nil and buffId > 0 then
					local szIconName,szTipInfo = Lua_GetBuffInfo(buffId)
					local szfullIconName = GetIconFullName(tostring(szIconName))
					local sPos,_ = string.find(szfullIconName," ");
					local IconImageSet = string.sub(szfullIconName,5,sPos-1);
					local IconIamge = string.sub(szfullIconName,sPos+7)
					if nil ~= IconImageSet and nil ~= IconIamge then
						PlayerList_List:SetBuffImageShow(i-1,1,j-1)
						PlayerList_List:SetBuffImage(i-1,j-1,IconImageSet,IconIamge,szTipInfo)
					else
						PlayerList_List:SetBuffImageShow(i-1,0,j-1)
					end
				else
                    PlayerList_List:SetBuffImageShow(i-1,0,j-1)
				end
			end
		end
	end

end

--选择目标
function PlayerList_PlayerSelect(isAttack )
	local idx = PlayerList_List:GetFirstSelectItem()

	if idx < 1 or idx > MAX_PLAYER_IDX then
		return
	end

	local iii = PlayerList_Item_Check4:GetCheck()

	if isAttack == 1 and pl[idx].isFriend == false and iii == 1 then
		SetMainTargetFromList(pl[idx].id , pl[idx].isFriend ,true)
	else
		SetMainTargetFromList(pl[idx].id , pl[idx].isFriend ,false)
	end
end

--关闭
function PlayerList_Hide()
	this:Hide();
end

--弹出
function PlayerList_Show()

	PlayerList_ChannalChange(false);
	PlayerList_EnmeyList:SetCheck(1);
	PlayerList_PlayerList1:SetCheck(0);


	if tonumber(Variable:GetVariable("DBAttack")) == 1 then
		PlayerList_Item_Check4:SetCheck( 1 )
	else
		PlayerList_Item_Check4:SetCheck( 0 )
	end
	PlayerList_UpdateScene()
	this:Show();
end

--友好敌对切换
function PlayerList_ChannalChange( flag )

	g_flag = flag
	if flag == true and PlayerList_IsSelectAnyCustom() == 1 then
		PlayerList_PriorityF5_Click();
		return
	end

	if flag == false and PlayerList_IsSelectAnyCustom() == 1 then
		PlayerList_PriorityF5_Click();
		return
	end

	UpdatePlayerList(flag);
	
	-- if flag == false then
		-- PlayerList_PriorityF5:SetProperty("Disabled", "True");
	-- else
		-- PlayerList_PriorityF5:SetProperty("Disabled", "False");
	-- end

	for i = 1 ,MAX_PLAYER_IDX do
		pl[i].id = -1;
	end
	
	local bhide = PlayerList_HideSpecificBuffer()
	local player_index = 1
	for i=1, 512 do
		pl[player_index].id ,
		pl[player_index].name ,
		pl[player_index].level,
		pl[player_index].guild,
		pl[player_index].menpai,
		pl[player_index].iconstr,
		pl[player_index].enemyFlag,
		pl[player_index].teamPower,
		pl[player_index].alliance,
		pl[player_index].perhp,
		pl[player_index].buffid[1],
		pl[player_index].buffid[2],
		pl[player_index].buffid[3],
		pl[player_index].buffid[4],
		pl[player_index].buffid[5],
		pl[i].havemskbuff
		= GetPlayerFromList(i - 1)
		pl[player_index].isFriend = flag;
		if pl[player_index].id ~= -1 and  pl[player_index].id ~= -2 then
			if bhide == 1 and PlayerList_OtherHaveBuffer( pl[player_index].id ) == 1 then
				pl[player_index].id = -1
			else
				player_index = player_index + 1
			end
			if player_index > 10 then
				break
			end			
		end
	end
	PlayerList_Update(flag);
	
end

--帮助
function PlayerList_OnHelp()
	Helper:GotoHelper("*PlayerList");
end

--右键菜单
function PlayerList_OpenMenu()

end


function PlayerList_DBAttack_Clicked()

	local temp = PlayerList_Item_Check4:GetCheck();

	Variable:SetVariable("DBAttack",tostring(temp), 0);

end

function PlayerList_ResetPos()
	PlayerList_Frame:SetProperty("UnifiedXPosition", g_PlayerList_Frame_UnifiedXPosition);
	PlayerList_Frame:SetProperty("UnifiedYPosition", g_PlayerList_Frame_UnifiedYPosition);

end

--这个函数用来刷新客户端的"附近玩家列表"中玩家世族信息,2014Q1大世界帮会功能改造,废弃之
function PlayerList_UpdateClanName(clanid, clanname)
	if this:IsVisible() then
		PlayerList_Update(g_flag)

		for i=1, MAX_PLAYER_IDX   do

			if pl[i].clanid == clanid then
				local color = ""
				local color_real = ""
				local icostr = ""
				if g_flag == false then
					color = "#cFF0000"
				elseif g_flag == true then
					color = "#c00FF00"
				end
				pl[i].guild = clanname

				if (pl[i].id ~= -1) then
					local na = pl[i].name
					if na == "" then na = "N/A" end
					local lv = pl[i].level

					local bp = pl[i].guild
					if bp == "" then bp = "N/A" end

					local mp = pl[i].menpai
					if mp == "" then mp= "无" end

					if pl[i].iconstr == "ENEMY" then
						icostr="#-18"
						color_real = color
					elseif pl[i].iconstr == "FLAG" then
						icostr="#-22"
						color_real = color.."#b"
					elseif pl[i].teamPower == 1 or pl[i].teamPower == 3 then
						icostr="#-17"
						color_real = color
					elseif pl[i].teamPower == 2 or pl[i].teamPower == 4 then
						icostr="#-49"
						color_real = color
					else
						icostr="  "
						color_real = color
					end

			local havemaskbuff = false
			local ef = pl[i].enemyFlag
			if pl[i].havemskbuff == 1 then
				lv = "?"
				mp = "?"
				bp = "?"
			end
		
			local str = ""
					if ef == 1 then
						--仇敌
						na = na.." #-47"
						str = string.format("%s%s%-22s #cFFFFFF%4d级#r  #c00B0F0%-20s#cFFFF00%6s",icostr, color_real ,na ,lv, bp, mp)
					elseif ef == 2 then
						--仇人
						na = na.." #-48"
						str = string.format("%s%s%-22s #cFFFFFF%4d级#r  #c00B0F0%-20s#cFFFF00%6s",icostr, color_real ,na ,lv, bp, mp)
					else
						str = string.format("%s%s%-20s#cFFFFFF%4d级#r  #c00B0F0%-20s#cFFFF00%6s",icostr, color_real ,na ,lv, bp, mp)
					end

					PlayerList_List:SetListItemText( i-1, str )
				end
			end
		end
	end
end

-- 刷新附近玩家列表
function PlayerList_Refresh( )

	if g_flag == true and PlayerList_IsSelectAnyCustom() == 1 then
		PlayerList_PriorityF5_Click();
		return
	end
	if g_flag == false and PlayerList_IsSelectAnyCustom() == 1 then
		PlayerList_PriorityF5_Click();
		return
	end
	PlayerList_ChannalChange( g_flag )
	PlayerList_UpdateScene()
end

function PlayerList_UpdateScene()
	local sceneid = GetSceneID()
	PlayerList_HideCheck:Hide()
	PlayerList_HideCheck_Text:Hide()
	if not sceneid then
		return
	end
	for i,v in g_check2_data.scenes do
		if v == sceneid then
			PlayerList_HideCheck:Show()
			PlayerList_HideCheck_Text:Show()
			return
		end
	end
end

function PlayerList_HideSpecificBuffer()
	local ischeck = PlayerList_HideCheck:GetCheck()
	if ischeck ~= 1 then
		return 0
	end
	local sceneid = GetSceneID()
	for i,v in g_check2_data.scenes do
		if v == sceneid then
			return 1
		end
	end
	return 0
end

function PlayerList_OtherHaveBuffer( tarid )
	for i,v in g_check2_data.buffids do
		if OtherPlayerHaveImpact( tonumber(tarid), tonumber(v) ) then
			return 1
		end
	end
	return 0
end

function PlayerList_OnCheck2()
	PlayerList_Refresh( )
end

-- 点击宣战按钮
function PlayerList_ButtonClickForXuanZhan()

	local index = PlayerList_List:GetClickedButtonItem();
	if index < 1 or index > MAX_PLAYER_IDX then
		return
	end

--	local iii = PlayerList_Item_CheckXuanZhan:GetCheck()
--	if pl[index].isFriend == true and iii == 1 then
	local ret =SetMainTargetFromList(pl[index].id , pl[index].isFriend ,false)
	if ret == 1 then
		Player:PVP_Challenge( 1 );     --1为弹出宣战确认对话框
	end
--	else
--		SetMainTargetFromList(pl[index].id , pl[index].isFriend ,false)
--		Player:PVP_Challenge( 2 );     --2为直接宣战
--		end
end

function PlayerList_PriorityF5_Click()
	if g_flag == true then
		UpdatePlayerListCustom()
	else
		UpdateEnemyPlayerListCustom()
	end

	for i = 1 ,MAX_PLAYER_IDX do
		pl[i].id = -1;
	end
	
	local bhide = PlayerList_HideSpecificBuffer()
	local player_index = 1
	for i=1, 512 do
		pl[player_index].id ,
		pl[player_index].name ,
		pl[player_index].level,
		pl[player_index].guild,
		pl[player_index].menpai,
		pl[player_index].iconstr,
		pl[player_index].enemyFlag,
		pl[player_index].teamPower,
		pl[player_index].alliance,
		pl[player_index].perhp,
		pl[player_index].buffid[1],
		pl[player_index].buffid[2],
		pl[player_index].buffid[3],
		pl[player_index].buffid[4],
		pl[player_index].buffid[5],
		pl[i].havemskbuff
		= GetPlayerFromList(i - 1)

		pl[player_index].isFriend = g_flag;
		if pl[player_index].id == -1 then
			break
		end

		if pl[player_index].id ~= -1 and pl[player_index].id ~= -2 then
			if bhide == 1 and PlayerList_OtherHaveBuffer( pl[player_index].id ) == 1 then
				pl[player_index].id = -1
			else
				player_index = player_index + 1
			end
			if player_index > 10 then
				break
			end		
		end

	end
	PlayerList_Update(g_flag);
	
	PlayerList_UpdateScene()
end

function PlayerList_Setup()
	PushEvent("SET_PLAYERLIST_CUSTOM")
end