local g_NewBangHuiBZTX_Campare_Frame_UnifiedPosition = nil 
local g_NewBangHuiBZTX_Campare_leftBarlist = {}
local g_NewBangHuiBZTX_Campare_RightBarlist = {}
local g_NewBangHuiBZTX_Campare_TempRightBarlist = {}
local g_NewBangHuiBZTX_Campare_InviteIndex = -1
local g_NewBanghuiBZTX_Campare_KickIndex = -1
function NewBangHuiBZTX_Campare_PreLoad()

	-- -- 游戏窗口尺寸发生了变化
	-- this:RegisterEvent("ADJEST_UI_POS",false)
	-- -- 游戏分辨率发生了变化
	-- this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- this:RegisterEvent("TCITYMEMBERLIST")
	-- this:RegisterEvent("RAID_UPDATE_MEMBER_CHAGNE",false)

end 

-- NewBangHuiBZTX_Campare_Client => DefaultWindow
-- NewBangHuiBZTX_Campare_Close => TLBB_ButtonClose
-- NewBangHuiBZTX_Campare_PageHeader_Name => TLBB_DragTitle
-- NewBangHuiBZTX_Campare_Help => TLBB_ButtonHelp
function NewBangHuiBZTX_Campare_OnLoad()
	g_NewBangHuiBZTX_Campare_Frame_UnifiedPosition = NewBangHuiBZTX_Campare_Frame:GetProperty("UnifiedPosition");
end

function NewBangHuiBZTX_Campare_OnEvent(event)
	-- if(event == "ADJEST_UI_POS") then
	-- 	NewBangHuiBZTX_Campare_On_ResetPos()
	-- elseif(event == "VIEW_RESOLUTION_CHANGED") then
	-- 	NewBangHuiBZTX_Campare_On_ResetPos()
	-- elseif(event == "HIDE_ON_SCENE_TRANSED") then
	-- 	NewBangHuiBZTX_Campare_On_Hide()
	-- elseif(event == "TCITYMEMBERLIST") then
	-- 	NewBangHuiBZTX_Campare_Init()
	-- 	this:Show()
	-- elseif(event == "RAID_UPDATE_MEMBER_CHAGNE") then
	-- 	--重置界面吧
	-- 	NewBangHuiBZTX_Campare_Init()
	-- end
end



function NewBangHuiBZTX_Campare_Init()
	local list = DataPool:GetTCityMemberList()
	--	INT	PlayerMySelf::GetMyRaidIndex(LuaPlus::LuaState* state)
	-- for i=1,list.m_Count do 
	 	--PushDebugMessage("list="..list.m_Count)
	-- 	local ret = DataPool:TCityMemberIsRaidMember(i-1)
	-- end
	if list then
		for i=1,list.m_Count do
			local str = string.format("BZTX index=%d,name=%s,groupid=%d",i,list.m_member[i].m_name,list.m_member[i].m_groupid)
			Lua_TDU_Log(str)

		end

	end
	g_NewBanghuiBZTX_Campare_KickIndex = -1
	g_NewBangHuiBZTX_Campare_InviteIndex = -1
	g_NewBangHuiBZTX_Campare_leftBarlist = {}
	g_NewBangHuiBZTX_Campare_RightBarlist = {}
	g_NewBangHuiBZTX_Campare_TempRightBarlist = {}
	NewBangHuiBZTX_Campare_Left_List:Clear()
	NewBangHuiBZTX_Campare_Right_List:Clear()
	local leftcount = 1
	local rgithcount = 1
	local mygroup = list.m_MyGroupId
	NewBangHuiBZTX_Campare_Left_TitleText:SetText(ScriptGlobal_Format("#{GCQH_240429_231}",mygroup))
	NewBangHuiBZTX_Campare_Right_TitleText:SetText(ScriptGlobal_Format("#{GCQH_240429_233}",mygroup))

	for i = 1, 5 do
		for j = 1, 6 do
			local name, menpai, level, dead, offline, scene = Raid:GetMemberInfoByIdx(i - 1, j - 1)
			if string.len(name) > 0 and name ~= "???" then
				--有效值
				local bFind = 0;
				for ii = 1, list.m_Count do
					if name == list.m_member[ii].m_name then
						--PushDebugMessage("name="..name..",cname="..list.m_member[ii].m_name)
						bFind = 1
						if mygroup ~= list.m_member[ii].m_groupid then
							--给加到左边列表
							NewBangHuiBZTX_Campare_AddLeft(name,leftcount,list.m_member[ii].m_groupid,i,j )
							leftcount = leftcount+1

						end
						list.m_member[ii].value = 1
					end
				end

				if bFind == 0 then
					NewBangHuiBZTX_Campare_AddLeft(name,leftcount,0,i,j)
					leftcount = leftcount+1
				end

			end
		end

	end

	for ii = 1, list.m_Count do
		if list.m_member[ii].value ~= nil then
			--已经处理过的了
		else

			--没处理过的加到右边,还要踢出掉与我不同
			if mygroup == list.m_member[ii].m_groupid then
				NewBangHuiBZTX_Campare_AddTempRight(list.m_member[ii].m_name,rgithcount,list.m_member[ii].m_bOnline,ii)
				--NewBangHuiBZTX_Campare_AddRight(list.m_member[ii].m_name,rgithcount,ii)
				rgithcount = rgithcount+1
			end
		end
	end
	
	


	NewBangHuiBZTX_Campare_ProduceTempRight()
	--遍历团队
	--1.列出不在我的group的队员
	--2.列出我队伍的我的group的队员
	--PushDebugMessage("list="..type(list.m_Count))
end

function NewBangHuiBZTX_Campare_ProduceTempRight()


	table.sort(g_NewBangHuiBZTX_Campare_TempRightBarlist, function(a, b)

			return a.bonline>b.bonline

	end)


	for i,v in ipairs(g_NewBangHuiBZTX_Campare_TempRightBarlist) do 

		NewBangHuiBZTX_Campare_AddRight(v.usename,i,v.datapos,v.bonline)
	end
end

function NewBangHuiBZTX_Campare_AddTempRight(name,Index,bonline,datapos)

	table.insert(g_NewBangHuiBZTX_Campare_TempRightBarlist,{usename = name, bonline = bonline, datapos = datapos})

end

function NewBangHuiBZTX_Campare_AddLeft(name,Index,bGroup,squadIdx,memIdx)
	
	
	local bar = NewBangHuiBZTX_Campare_Left_List:AddChild("NewBangHuiBZTX_Campare_Left_ListItem")
	if (bGroup ~= 0 ) then
			
		bar:GetSubItem("NewBangHuiBZTX_Campare_Left_ListItemText"):SetText(string.format("%s(%d编队)",name,bGroup))
	else
		bar:GetSubItem("NewBangHuiBZTX_Campare_Left_ListItemText"):SetText(string.format(name))
	end
	bar:SetEvent("MouseLClick", string.format("NewBangHuiBZTX_Campare_LeftClicked(%d)", Index)) 
	bar:SetEvent("MouseRClick", string.format("NewBangHuiBZTX_Campare_LeftPoped(%d)", Index)) 
	g_NewBangHuiBZTX_Campare_leftBarlist[Index] = {uictrl = bar,usename = name, squadIdx = squadIdx, memIdx = memIdx};


end


function NewBangHuiBZTX_Campare_AddRight(name,Index,datapos,bonline)

	local bar = NewBangHuiBZTX_Campare_Right_List:AddChild("NewBangHuiBZTX_Campare_Right_ListItem")
	if bonline > 0 then
		bar:GetSubItem("NewBangHuiBZTX_Campare_Right_ListItemText"):SetText(name)
	else
		bar:GetSubItem("NewBangHuiBZTX_Campare_Right_ListItemText"):SetText("#c808080"..name)
	end

	bar:SetEvent("MouseLClick", string.format("NewBangHuiBZTX_Campare_RightClicked(%d)", Index)) 
	bar:SetEvent("MouseRClick", string.format("NewBangHuiBZTX_Campare_RightPoped(%d)", Index)) 
	g_NewBangHuiBZTX_Campare_RightBarlist[Index] = {usename = name,uictrl = bar,datapos = datapos}
end


function NewBangHuiBZTX_Campare_LeftPoped(Index)


	local data = g_NewBangHuiBZTX_Campare_leftBarlist[Index]
	if data then
		local name = data.usename
		ShowBZTXListPopMenu(1,name)
	end


	
	
end
function NewBangHuiBZTX_Campare_LeftClicked(Index)
	g_NewBanghuiBZTX_Campare_KickIndex = Index

end


function NewBangHuiBZTX_Campare_Left_MoveAll_Clicked()

	if next(g_NewBangHuiBZTX_Campare_leftBarlist) == nil then
		PushDebugMessage("#{GCQH_240429_283}")
		return
	end

	if Player:IsRaidLeader() == 1 then
		local list = DataPool:GetTCityMemberList()
		local mygroup = list.m_MyGroupId
		for i = 1, 5 do
			for j = 1, 6 do
				local name, menpai, level, dead, offline, scene = Raid:GetMemberInfoByIdx(i - 1, j - 1)
				if  string.len(name) > 0 and name ~= "???" then
					--有效值
					local bFind = 0;
					for ii = 1, list.m_Count do					

						if name == list.m_member[ii].m_name then

							if mygroup ~= list.m_member[ii].m_groupid then

								Player:KickRaidMemberByIdx(i - 1, j - 1)
								
							end
							bFind = 1		--注意这里不太一样
						end
					end


					if bFind == 0 then

						Player:KickRaidMemberByIdx(i - 1, j - 1)
					end

				end
			end

		end	
	else
		PushDebugMessage("#{GCQH_240429_239}")
	end

end


function NewBangHuiBZTX_Campare_Left_Move_Clicked()

	local data = g_NewBangHuiBZTX_Campare_leftBarlist[g_NewBanghuiBZTX_Campare_KickIndex]
	if data ~= nil then
		--PushDebugMessage("Ok, next")
		--PushDebugMessage(string.format("datas=%d,m=%d", data.squadIdx,data.memIdx))
		--if Player:IsRaidLeader() == 1 or Player:IsRaidAssitant() == 1 then
		if Player:IsRaidLeader() == 1 then
			Player:KickRaidMemberByIdx(data.squadIdx-1, data.memIdx-1)
		else
			PushDebugMessage("#{GCQH_240429_239}")
		end
	else
		PushDebugMessage("#{GCQH_240429_236}")
	end
end

function NewBangHuiBZTX_Campare_RightClicked(Index)

	g_NewBangHuiBZTX_Campare_InviteIndex = Index
end

function NewBangHuiBZTX_Campare_RightPoped(Index)

	local data = g_NewBangHuiBZTX_Campare_RightBarlist[Index]
	if data then
		local name = data.usename
		ShowBZTXListPopMenu(2,name)
	end
end

function NewBangHuiBZTX_Campare_CloseClicked()
	this:Hide()
end


function NewBangHuiBZTX_Campare_On_ResetPos()
	NewBangHuiBZTX_Campare_Frame:SetProperty("UnifiedPosition", g_NewBangHuiBZTX_Campare_Frame_UnifiedPosition)
end

function NewBangHuiBZTX_Campare_On_Hide()

end

function NewBangHuiBZTX_Campare_Close_Click()
end

function NewBangHuiBZTX_Campare_Help_Click()
end

function NewBangHuiBZTX_Campare_Right_Invite_Clicked()


	local data = g_NewBangHuiBZTX_Campare_RightBarlist[g_NewBangHuiBZTX_Campare_InviteIndex]
	if data ~= nil then
		--local name =
		if Player:IsInRaid() == 1 then
			if Player:IsRaidLeader() == 1 then
				local name = data.usename

				Target:SendRaidInvitation(name)
			else
				PushDebugMessage("#{GCQH_240429_239}") 
			end
		else
			PushDebugMessage("#{GCQH_240429_238}")
		end
	else
		PushDebugMessage("#{GCQH_240429_243}")
	end
	

end

function NewBangHuiBZTX_Campare_Right_InviteAll_Clicked()

	if next(g_NewBangHuiBZTX_Campare_RightBarlist) == nil then
		PushDebugMessage("#{GCQH_240429_284}")
		return
	end

    --是否有团队

    if Player:IsInRaid() == 1 then

		--是否是团长
		if Player:IsRaidLeader() == 1 then
			Guild:InviteBZTXMember(0)
		else
			PushDebugMessage("#{GCQH_240429_239}")    
		end

    else
        PushDebugMessage("#{GCQH_240429_224}")        
    end
end