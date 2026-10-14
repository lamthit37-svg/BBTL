-- !!!reloadscript =NewBangHui_FightGroup_Compare
local m_Frame_UnifiedPosition

local m_zhanTuanID = 0

local m_myZhanTuanID = 0
local m_myZhanTuanPos = 0

local m_curSelectMemLeft = -1
local m_memInfoLeft = {}
local m_curSelectMemRight = -1
local m_memInfoRight = {}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function NewBangHui_FightGroup_Compare_PreLoad()
	this:RegisterEvent("GUILD_ZHANTUAN_OP_UPDATE", true)
	this:RegisterEvent("RAID_UPDATE_MEMBER_CHAGNE",false)
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function NewBangHui_FightGroup_Compare_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedPosition	= NewBangHui_FightGroup_Compare_Frame:GetProperty("UnifiedPosition");
	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NewBangHui_FightGroup_Compare_ResetPos()
	NewBangHui_FightGroup_Compare_Frame:SetProperty("UnifiedPosition", m_Frame_UnifiedPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function NewBangHui_FightGroup_Compare_OnEvent(event)
	if( event == "GUILD_ZHANTUAN_OP_UPDATE" ) then--
		local opType = tonumber(arg0)
		if opType == 20000 then
			m_zhanTuanID = tonumber(arg1)
			m_myZhanTuanID = tonumber(arg2)
			m_myZhanTuanPos = tonumber(arg3)

			if (this:IsVisible()) then
				NewBangHui_FightGroup_Compare_Update()
				return
			end
			NewBangHui_FightGroup_Compare_Show()
			NewBangHui_FightGroup_Compare_Update()
		elseif opType == 1 or 
			opType == 2 or
			opType == 3 or
			opType == 4 then
			if (this:IsVisible()) then
				NewBangHui_FightGroup_Compare_Update()
				return
			end
		end
	elseif event == "RAID_UPDATE_MEMBER_CHAGNE" then
		if (this:IsVisible()) then
			NewBangHui_FightGroup_Compare_Update()
			return
		end
	elseif event == "ADJEST_UI_POS" then
		NewBangHui_FightGroup_Compare_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHui_FightGroup_Compare_Hide()
	end
end

--显示UI
function NewBangHui_FightGroup_Compare_Show()
	NewBangHui_FightGroup_Compare_ClearData()
	this:Show()
	
end
--隐藏UI
function NewBangHui_FightGroup_Compare_Hide()
	NewBangHui_FightGroup_Compare_ClearData()

	this:Hide()
end

--清除数据
function NewBangHui_FightGroup_Compare_ClearData()

end

--更新
function NewBangHui_FightGroup_Compare_Update()


	NewBangHui_FightGroup_Compare_LList:Clear()
	NewBangHui_FightGroup_Compare_RList:Clear()

	m_curSelectMemLeft = -1
	m_memInfoLeft = {}
	local leftCount = 0
	for squadIdx = 1, 5 do
		for memIdx = 1, 6 do
			local name, menpai, level, dead, offline, scene, zoneWorldID,_,raidGuid,FightScore,GuildName = Raid:GetMemberInfoByIdx(squadIdx - 1, memIdx - 1)
			if string.len(name) > 0 and name ~= "???" then
				--有效值
				local bFind = 0
				for zhanTuanIdx = 0, GuildZhanTuanUI:LuaFnGetZhanTuanMemMaxNum()-1 do
					local IsValid,IsMe,MemIndex,Name,Level,MenPai,EquipPoint,Pos,ZhanTuanID,IsOnline,Guid = GuildZhanTuanUI:LuaFnGuildZhanTuanData(m_zhanTuanID, zhanTuanIdx)
					if raidGuid == Guid then
						bFind = 1
						break
					end
				end
				if bFind ~= 1 then
					leftCount = leftCount + 1
					local bar = NewBangHui_FightGroup_Compare_LList:AddChild("NewBangHui_FightGroup_Compare_LListItem")
					bar:GetSubItem("NewBangHui_FightGroup_Compare_LListItem_Text"):SetText(string.format(name))
					bar:SetEvent("MouseLClick", string.format("NewBangHui_FightGroup_Compare_LListItem_LeftClicked(%d)", leftCount)) 
					bar:SetEvent("MouseRClick", string.format("NewBangHui_FightGroup_Compare_LListItem_RightClicked(%d)", leftCount)) 
					m_memInfoLeft[leftCount] = {}
					m_memInfoLeft[leftCount].RealIndex=squadIdx*10+memIdx
					m_memInfoLeft[leftCount].Name = name
					m_memInfoLeft[leftCount].Guid = raidGuid
					m_memInfoLeft[leftCount].CheckUI=bar:GetSubItem("NewBangHui_FightGroup_Compare_LListItemCheck")
					m_memInfoLeft[leftCount].CheckUISelect=bar:GetSubItem("NewBangHui_FightGroup_Compare_LListItemCheckBK")
					-- PushDebugMessage(name)
				end
			end
		end
	end
	m_curSelectMemRight = -1
	m_memInfoRight = {}
	local rightCount = 0
	for zhanTuanIdx = 0, GuildZhanTuanUI:LuaFnGetZhanTuanMemMaxNum()-1 do
		local IsValid,IsMe,MemIndex,Name,Level,MenPai,EquipPoint,Pos,ZhanTuanID,IsOnline,Guid = GuildZhanTuanUI:LuaFnGuildZhanTuanData(m_zhanTuanID, zhanTuanIdx)
		if IsValid == 1 then
			local bFind = 0
			for squadIdx = 1, 5 do
				for memIdx = 1, 6 do
					local name, menpai, level, dead, offline, scene, zoneWorldID,_,raidGuid,FightScore,GuildName = Raid:GetMemberInfoByIdx(squadIdx - 1, memIdx - 1)
					if raidGuid == Guid then
						bFind = 1
						break
					end
				end
			end
			if bFind ~= 1 then
				
				rightCount = rightCount + 1
				local bar = NewBangHui_FightGroup_Compare_RList:AddChild("NewBangHui_FightGroup_Compare_RListItem")
				if IsOnline == 1 then
					bar:GetSubItem("NewBangHui_FightGroup_Compare_RListItem_Text"):SetText(Name)
				else
					bar:GetSubItem("NewBangHui_FightGroup_Compare_RListItem_Text"):SetText("#c808080"..Name)
				end
				bar:SetEvent("MouseLClick", string.format("NewBangHui_FightGroup_Compare_RListItem_LeftClicked(%d)", rightCount)) 
				bar:SetEvent("MouseRClick", string.format("NewBangHui_FightGroup_Compare_RListItem_RightClicked(%d)", rightCount)) 
				m_memInfoRight[rightCount] = {}
				m_memInfoRight[rightCount].RealIndex=zhanTuanIdx
				m_memInfoRight[rightCount].Name = Name
				m_memInfoRight[rightCount].Guid = Guid
				m_memInfoRight[rightCount].CheckUI=bar:GetSubItem("NewBangHui_FightGroup_Compare_RListItemCheck")		
				m_memInfoRight[rightCount].CheckUISelect=bar:GetSubItem("NewBangHui_FightGroup_Compare_RListItemCheckBK")
			end
		end
	end
	NewBangHui_FightGroup_Compare_LeftItemState(0)
	NewBangHui_FightGroup_Compare_RightItemState(0)
end
function NewBangHui_FightGroup_Compare_LeftItemState(selectIndex)
	for index = 1, table.getn(m_memInfoLeft) do
		if index == selectIndex then
			m_memInfoLeft[index].CheckUI:SetCheck(1)
			m_memInfoLeft[index].CheckUISelect:Show()
		else
			m_memInfoLeft[index].CheckUI:SetCheck(0)
			m_memInfoLeft[index].CheckUISelect:Hide()
		end
	end
end
function NewBangHui_FightGroup_Compare_RightItemState(selectIndex)
	for index = 1, table.getn(m_memInfoRight) do
		if index == selectIndex then
			m_memInfoRight[index].CheckUI:SetCheck(1)
			m_memInfoRight[index].CheckUISelect:Show()
		else
			m_memInfoRight[index].CheckUI:SetCheck(0)
			m_memInfoRight[index].CheckUISelect:Hide()
		end
	end
end


--##############点击事件##############
function NewBangHui_FightGroup_Compare_LListItem_LeftClicked(index)
	if nil == m_memInfoLeft[index] then
		return
	end
	NewBangHui_FightGroup_Compare_LeftItemState(index)
	m_curSelectMemLeft = index
end
function NewBangHui_FightGroup_Compare_LListItem_RightClicked(index)
	if nil == m_memInfoLeft[index] then
		return
	end
	NewBangHui_FightGroup_Compare_LeftItemState(index)
	m_curSelectMemLeft = index
	ShowBZTXListPopMenu(1, m_memInfoLeft[index].Name)
end
function NewBangHui_FightGroup_Compare_RListItem_LeftClicked(index)
	if nil == m_memInfoRight[index] then
		return
	end
	NewBangHui_FightGroup_Compare_RightItemState(index)
	m_curSelectMemRight = index
end
function NewBangHui_FightGroup_Compare_RListItem_RightClicked(index)
	if nil == m_memInfoRight[index] then
		return
	end
	NewBangHui_FightGroup_Compare_RightItemState(index)
	m_curSelectMemRight = index
	ShowBZTXListPopMenu(2, m_memInfoRight[index].Name)
end
--移出团队
function NewBangHui_FightGroup_Compare_LButton1_Clicked()
	if m_curSelectMemLeft <= 0 then
		PushDebugMessage("#{ZTXT_260511_133}")
		return
	end
	if nil == m_memInfoLeft[m_curSelectMemLeft] then
		PushDebugMessage("#{ZTXT_260511_133}")
		return
	end

	if m_myZhanTuanID ~= m_zhanTuanID then
		PushDebugMessage("#{ZTXT_260511_134}")
		return
	end
	if Player:IsInRaid() ~= 1 then
		PushDebugMessage("#{ZTXT_260511_135}")
		return
	end
	if Player:IsRaidLeader() ~= 1 then
		PushDebugMessage("#{ZTXT_260511_136}")
		return
	end
	local realIndex = m_memInfoLeft[m_curSelectMemLeft].RealIndex
	local squadIdx = math.floor(realIndex/10)
	local memIdx = math.mod(realIndex, 10)
	Player:KickRaidMemberByIdx(squadIdx - 1, memIdx - 1)
end
--一键移出
function NewBangHui_FightGroup_Compare_LButton2_Clicked()
	if m_myZhanTuanID ~= m_zhanTuanID then
		PushDebugMessage("#{ZTXT_260511_134}")
		return
	end
	if Player:IsInRaid() ~= 1 then
		PushDebugMessage("#{ZTXT_260511_135}")
		return
	end
	if Player:IsRaidLeader() ~= 1 then
		PushDebugMessage("#{ZTXT_260511_136}")
		return
	end
	local isValid = 0
	for squadIdx = 1, 5 do
		for memIdx = 1, 6 do
			local name, menpai, level, dead, offline, scene, zoneWorldID,_,raidGuid,FightScore,GuildName = Raid:GetMemberInfoByIdx(squadIdx - 1, memIdx - 1)
			if string.len(name) > 0 and name ~= "???" then
				--有效值
				local bFind = 0
				for zhanTuanIdx = 0, GuildZhanTuanUI:LuaFnGetZhanTuanMemMaxNum()-1 do
					local IsValid,IsMe,MemIndex,Name,Level,MenPai,EquipPoint,Pos,ZhanTuanID,IsOnline,Guid = GuildZhanTuanUI:LuaFnGuildZhanTuanData(m_zhanTuanID, zhanTuanIdx)
					if raidGuid == Guid then
						bFind = 1
						break
					end
				end
				if bFind ~= 1 then
					Player:KickRaidMemberByIdx(squadIdx - 1, memIdx - 1)
					isValid = 1
				end
			end
		end
	end
	if isValid ~= 1 then
		PushDebugMessage("#{ZTXT_260511_139}")
		return
	end
end
--邀请入团
function NewBangHui_FightGroup_Compare_RButton1_Clicked()
	if m_curSelectMemRight <= 0 then
		PushDebugMessage("#{ZTXT_260511_133}")
		return
	end
	if nil == m_memInfoRight[m_curSelectMemRight] then
		PushDebugMessage("#{ZTXT_260511_133}")
		return
	end
	if m_myZhanTuanID ~= m_zhanTuanID then
		PushDebugMessage("#{ZTXT_260511_134}")
		return
	end
	if Player:IsInRaid() ~= 1 then
		PushDebugMessage("#{ZTXT_260511_135}")
		return
	end
	if Player:IsRaidLeader() ~= 1 then
		PushDebugMessage("#{ZTXT_260511_136}")
		return
	end
	Target:SendRaidInvitation(m_memInfoRight[m_curSelectMemRight].Name)
end
--一键邀请
function NewBangHui_FightGroup_Compare_RButton2_Clicked()
	if m_myZhanTuanID ~= m_zhanTuanID then
		PushDebugMessage("#{ZTXT_260511_148}")
		return
	end
	if Player:IsInRaid() ~= 1 then
		PushDebugMessage("#{ZTXT_260511_135}")
		return
	end
	if Player:IsRaidLeader() ~= 1 then
		PushDebugMessage("#{ZTXT_260511_136}")
		return
	end
	for zhanTuanIdx = 0, GuildZhanTuanUI:LuaFnGetZhanTuanMemMaxNum()-1 do
		local IsValid,IsMe,MemIndex,Name,Level,MenPai,EquipPoint,Pos,ZhanTuanID,IsOnline,Guid = GuildZhanTuanUI:LuaFnGuildZhanTuanData(m_zhanTuanID, zhanTuanIdx)
		if IsValid == 1 then
			local bFind = 0
			for squadIdx = 1, 5 do
				for memIdx = 1, 6 do
					local name, menpai, level, dead, offline, scene, zoneWorldID,_,raidGuid,FightScore,GuildName = Raid:GetMemberInfoByIdx(squadIdx - 1, memIdx - 1)
					if raidGuid == Guid then
						bFind = 1
						break
					end
				end
			end
			if bFind ~= 1 then
				Target:SendRaidInvitation(Name)
			end
		end
	end
end

