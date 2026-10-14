-- !!!reloadscript =NewBangHui_FightGroup_Manager
local m_Frame_UnifiedPosition

local m_opType = 0
local m_zhanTuanID = 0

local m_MemberSortOrder = 0
local m_ListToMember = {}
local m_MemberNum = 0
local m_curSelectMem = -1

local m_isShowZhanTuanData = 0

local m_myZhanTuanPos = 0

local m_menpaiInfo = {
	"#{XQ_MP_1}",    --少林
	"#{XQ_MP_2}",    --明教
	"#{XQ_MP_3}",    --丐帮
	"#{XQ_MP_4}",    --武当
	"#{XQ_MP_5}",    --峨眉
	"#{XQ_MP_6}",    --星宿
	"#{XQ_MP_7}",    --天龙
	"#{XQ_MP_8}",    --天山
	"#{XQ_MP_9}",    --逍遥
	"#{WCBZ_180128_57}",  --无门派
	"#{XQ_MP_10}",  
	"#{XQ_MP_13}",   
	"#{XMPGG_160524_02}",   --鬼谷
	"#{XQ_MP_15}",   --桃花岛
	"#{XMPHM_210604_01}",   
	"#{GMGameInterface_Script_DataPool_Info_ERenGu}",   
};
--预加载函数，可以而且只能在这里注册脚本关心的事件
function NewBangHui_FightGroup_Manager_PreLoad()
	this:RegisterEvent("GUILD_ZHANTUAN_OP_UPDATE", true)
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function NewBangHui_FightGroup_Manager_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedPosition	= NewBangHui_FightGroup_Manager_Frame:GetProperty("UnifiedPosition");

	NewBangHui_FightGroup_Manager_Filter_SearchMode:AddTextItem("#{ZTXT_260511_16}" ,1)			--默认：姓名
	NewBangHui_FightGroup_Manager_Filter_SearchMode:AddTextItem("#{ZTXT_260511_17}" ,2)			-- 等级
	NewBangHui_FightGroup_Manager_Filter_SearchMode:AddTextItem("#{ZTXT_260511_18}" ,3)			--装备评分
	NewBangHui_FightGroup_Manager_Filter_SearchMode:AddTextItem("#{ZTXT_260511_19}" ,4)			--门派
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NewBangHui_FightGroup_Manager_ResetPos()
	NewBangHui_FightGroup_Manager_Frame:SetProperty("UnifiedPosition", m_Frame_UnifiedPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function NewBangHui_FightGroup_Manager_OnEvent(event)
	if( event == "GUILD_ZHANTUAN_OP_UPDATE" ) then--
		local opType = tonumber(arg0)
		if opType == 10000 or opType == 10001 then
			m_opType = opType
			m_zhanTuanID = tonumber(arg1)
			if (this:IsVisible()) then
				NewBangHui_FightGroup_Manager_Hide()
				-- return
			end
			NewBangHui_FightGroup_Manager_Filter_SearchMode:SetCurrentSelect(0)
			GuildZhanTuanUI:LuaFnInitTempGuildManagerZhanTuanData()
			NewBangHui_FightGroup_Manager_Show()
			NewBangHui_FightGroup_Manager_Update()
		elseif opType == 1 or 
			opType == 2 or
			opType == 3 or
			opType == 4 then
			if (this:IsVisible()) then
				-- NewBangHui_FightGroup_Manager_Update()
				-- NewBangHui_FightGroup_Manager_Filter_SearchMode:SetCurrentSelect(0)
				GuildZhanTuanUI:LuaFnInitTempGuildManagerZhanTuanData()
				NewBangHui_FightGroup_Manager_Update()
			end
		end
	elseif event == "ADJEST_UI_POS" then
		NewBangHui_FightGroup_Manager_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHui_FightGroup_Manager_Hide()
	end
end

--显示UI
function NewBangHui_FightGroup_Manager_Show()
	NewBangHui_FightGroup_Manager_ClearData()
	this:Show()
	
end
--隐藏UI
function NewBangHui_FightGroup_Manager_Hide()
	NewBangHui_FightGroup_Manager_ClearData()

	this:Hide()
end

--清除数据
function NewBangHui_FightGroup_Manager_ClearData()
	m_MemberSortOrder = 0
	m_isShowZhanTuanData = 0
end
--更新
function NewBangHui_FightGroup_Manager_Update()

	-- PushDebugMessage(NewBangHui_FightGroup_Manager_CheckBox:GetCheck().." "..m_isShowZhanTuanData.." "..m_zhanTuanID)
	GuildZhanTuanUI:LuaFnSortTempGuildManagerZhanTuanData(m_MemberSortOrder)

	if m_opType == 10000 then
		NewBangHui_FightGroup_Manager_CheckBoxBK:Show()
		NewBangHui_FightGroup_Manager_GroupInfo2:Show()
		NewBangHui_FightGroup_Manager_LeaderSet:Show()
		NewBangHui_FightGroup_Manager_MemberSet:Hide()
		NewBangHui_FightGroup_Manager_MemberSet2:Hide()
		NewBangHui_FightGroup_Manager_CheckBoxState()
		NewBangHui_FightGroup_Manager_DragTitle:SetText("#{ZTXT_260511_34}")
		
	else
		NewBangHui_FightGroup_Manager_CheckBoxBK:Hide()
		NewBangHui_FightGroup_Manager_GroupInfo2:Hide()
		NewBangHui_FightGroup_Manager_LeaderSet:Hide()
		NewBangHui_FightGroup_Manager_MemberSet:Show()
		NewBangHui_FightGroup_Manager_MemberSet2:Show()
		NewBangHui_FightGroup_Manager_DragTitle:SetText("#{ZTXT_260511_39}")
	end
	NewBangHui_FightGroup_Manager_GroupInfo2:SetText("#{ZTXT_260511_28}")
	
	m_ListToMember = {}
	local curZhanTuanNum = 0
	m_myZhanTuanPos = 0
	for memIdx = 0, GuildZhanTuanUI:LuaFnGetZhanTuanMemMaxNum()-1 do
		local IsValid,IsMe,MemIndex,Name,Level,MenPai,EquipPoint,Pos,ZhanTuanID,IsOnline,Guid = GuildZhanTuanUI:LuaFnGuildZhanTuanData(m_zhanTuanID, memIdx)
		if IsValid == 1 then
			curZhanTuanNum = curZhanTuanNum + 1
			if Pos == 1 then
				NewBangHui_FightGroup_Manager_GroupInfo2:SetText(ScriptGlobal_Format("#{ZTXT_260511_37}", Name))
			end
			if IsMe == 1 then
				m_myZhanTuanPos = Pos
			end
		end
	end
	NewBangHui_FightGroup_Manager_GroupInfo:SetText(ScriptGlobal_Format("#{ZTXT_260511_36}", curZhanTuanNum))

	NewBangHui_FightGroup_Manager_List:RemoveAllItem()
	m_MemberNum = 0
	local totalNum = GuildZhanTuanUI:LuaFnTempGuildManagerZhanTuanDataLength()
	-- PushDebugMessage(totalNum)
	for memIdx = 0, totalNum-1 do
		local IsValid,IsMe,MemIndex,Name,Level,MenPai,EquipPoint,Pos,ZhanTuanID,IsOnline = GuildZhanTuanUI:LuaFnTempGuildManagerZhanTuanData(memIdx)
		if IsValid == 1 and Level >= 85 then--
			local isAdd = 0
			if m_opType == 10000 then
				if m_isShowZhanTuanData == 1 then
					if ZhanTuanID == m_zhanTuanID then
						isAdd = 1
					end
				else
					if ZhanTuanID <=0 or ZhanTuanID == m_zhanTuanID then
						isAdd = 1
					end
				end
			else
				if ZhanTuanID <=0 then
					isAdd = 1
				end
			end
			if isAdd == 1 then
				local onlineColor = "#c808080"
				if IsOnline == 1 then
					onlineColor = "#W"
				end

				NewBangHui_FightGroup_Manager_List:AddNewItem(onlineColor..Name, 0, m_MemberNum)
				NewBangHui_FightGroup_Manager_List:AddNewItem(onlineColor..Level, 1, m_MemberNum)
				NewBangHui_FightGroup_Manager_List:AddNewItem(onlineColor..m_menpaiInfo[MenPai+1], 2, m_MemberNum)
				NewBangHui_FightGroup_Manager_List:AddNewItem(onlineColor..EquipPoint, 3, m_MemberNum)

				m_ListToMember[m_MemberNum] = MemIndex
				m_MemberNum = m_MemberNum + 1
			end
		end
	end
	if m_MemberNum > 0 then
		NewBangHui_FightGroup_Manager_List:SetSelectItem(0)
	end
end
function NewBangHui_FightGroup_Manager_CheckBoxState()
	if m_isShowZhanTuanData == 1 then
		NewBangHui_FightGroup_Manager_CheckBox:SetCheck(1)	
	else
		NewBangHui_FightGroup_Manager_CheckBox:SetCheck(0)	
	end
end
--##############点击事件##############
function NewBangHui_FightGroup_Manager_CloseClicked()
	NewBangHui_FightGroup_Manager_Hide()
end
function NewBangHui_FightGroup_Manager_CheckBoxClicked()
	if m_opType ~= 10000 then
		return
	end
	local nCheck = NewBangHui_FightGroup_Manager_CheckBox:GetCheck()
	if nCheck == m_isShowZhanTuanData then
		return
	end
	m_isShowZhanTuanData = nCheck
	NewBangHui_FightGroup_Manager_Update()
end
function NewBangHui_FightGroup_Manager_Filter_SearchMode_Changed()
	if not this:IsVisible() then
		return	
	end
	
	local _, nIndex = NewBangHui_FightGroup_Manager_Filter_SearchMode:GetCurrentSelect()
	if m_MemberSortOrder == nIndex then
		return
	end
	m_MemberSortOrder = nIndex

	NewBangHui_FightGroup_Manager_Update()
end

function NewBangHui_FightGroup_Manager_SelectChanged()
	m_curSelectMem = NewBangHui_FightGroup_Manager_List:GetSelectItem()
	-- PushDebugMessage(m_curSelectMem)
end
--任命
function NewBangHui_FightGroup_Manager_LeaderSetClicked()
	if m_opType ~= 10000 then
		return
	end
	local myPos = Guild:GetMyPosition()
	if myPos ~= 9 then
		PushDebugMessage("#{ZTXT_260511_44}")
		return
	end
	if nil == m_ListToMember[m_curSelectMem] then
		PushDebugMessage("#{ZTXT_260511_46}")
		return
	end
	GuildZhanTuanUI:LuaFnGuildZhanTuanAppoint(m_zhanTuanID, m_ListToMember[m_curSelectMem])
end
function NewBangHui_FightGroup_Manager_MemberSetClicked(index)	
	if m_opType ~= 10001 then
		return
	end
	local myPos = Guild:GetMyPosition()
	if myPos ~= 9 and m_myZhanTuanPos ~= 1 then
		PushDebugMessage("#{ZTXT_260511_58}")
		return
	end
	if index == 1 then --一键添加
		if m_MemberNum <= 0 then--
			PushDebugMessage("#{ZTXT_260511_61}")
			return
		end
		GuildZhanTuanUI:LuaFnGuildZhanTuanOneAdd(m_zhanTuanID)
	else
		if nil == m_ListToMember[m_curSelectMem] then
			PushDebugMessage("#{ZTXT_260511_61}")
			return
		end
		GuildZhanTuanUI:LuaFnGuildZhanTuanAdd(m_zhanTuanID, m_ListToMember[m_curSelectMem])
	end
end
--####################################