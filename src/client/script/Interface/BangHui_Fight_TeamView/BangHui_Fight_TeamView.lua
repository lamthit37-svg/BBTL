--帮会属地争夺-排行榜详细信息查看(客户端)

--//
--控件列表
local m_Controls = {} 				--控件列表

local g_Frame_UnifiedPosition
local g_targetID = -1
local g_objCared = -1
local MAX_OBJ_DISTANCE = 3.0
local g_ViewIndex = -1

local sMenPaiName={"少林","明教","丐帮","武当","峨嵋","星宿","天龙","天山","逍遥","无门派","慕容","唐门","鬼谷", "#{XQ_MP_15}", "#{XMPHM_210604_01}", "#{BHSD_20240709_1}"} --menpai14 menpai15

local g_nMenPaiCount = 16 --menpai14 menpai15

function BangHui_Fight_TeamView_PreLoad()
	--PushDebugMessage("BangHui_Fight_TeamView_PreLoad")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("OPEN_BANGHUI_TEAMVIEW_UI")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BangHui_Fight_TeamView_OnLoad()
	m_Controls = {
		m_Title = BangHui_Fight_TeamView_PageHeader,
		m_BanghuiTitle = BangHui_Fight_TeamView_BanghuiText,
		m_BanghuiName = BangHui_Fight_TeamView_BanghuiInput,
		m_CapacityTitle = BangHui_Fight_TeamView_CapacityText,
		m_CapacityName = BangHui_Fight_TeamView_CapacityInput,
		m_TeamInfoList = BangHui_Fight_TeamView_List,
		m_ButtonInvite = BangHui_Fight_TeamView_Invite,
		m_ButtonPickOut = BangHui_Fight_TeamView_PickOut,
		m_Frame = BangHui_Fight_TeamView_Frame,
		m_pic1 = BangHui_Fight_TeamView_Pic1,
		m_pic2 = BangHui_Fight_TeamView_Pic2,
		m_pic3 = BangHui_Fight_TeamView_Pic3,
		m_pic4 = BangHui_Fight_TeamView_Pic4,
		m_pic5 = BangHui_Fight_TeamView_Pic5,
		m_pic6 = BangHui_Fight_TeamView_Pic6,
	}
	
	g_Frame_UnifiedPosition=m_Controls.m_Frame:GetProperty("UnifiedPosition")
end

function BangHui_Fight_TeamView_OnEvent(event)
	if (event == "VIEW_RESOLUTION_CHANGED") then
		BangHui_Fight_TeamView_Frame_On_ResetPos()
		BangHui_Fight_TeamView_Open(g_ViewIndex)
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			BangHui_Fight_TeamView_Close()
		end
	elseif (event == "OPEN_BANGHUI_TEAMVIEW_UI") then
		--PushDebugMessage("111111111111111111")
		g_targetID = tonumber(arg0)
		g_objCared = DataPool : GetNPCIDByServerID(g_targetID)
		if g_objCared == -1 then
			PushDebugMessage("传过来的数据有问题。")
			return
		end
		local paiInd = tonumber(arg1)
		BangHui_Fight_TeamView_Open(paiInd)
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then 
		this:Hide()
	end
end

function BangHui_Fight_TeamView_Open(index)
	if g_objCared ~= -1 then
		this:CareObject(g_objCared, 0, "BangHui_Fight_TeamView")
		this:CareObject(g_objCared, 1, "BangHui_Fight_TeamView")
	else
		return
	end
	if index == nil or index == -1 then
		return
	end
	g_ViewIndex = index
	--报名队伍信息查看
	m_Controls.m_Title:SetText("#{BHSDZ_150310_52}")
	--所属帮会XXX
	local guildName = GangT:GetGangTerritoryInfo(index, "GuildName")
	if guildName ~= nil and guildName ~= "" then
		local msgName = ScriptGlobal_Format("#{BHSDZ_150310_53}", guildName)
		m_Controls.m_BanghuiTitle:SetText("#{BHSDZ_150310_53}")
		m_Controls.m_BanghuiName:SetText(guildName)
	end
	
	
	--参战总战斗力：XXX
	local zongzhanli = GangT:GetGangTerritoryInfo(index, "ZhanLi")
	if zongzhanli ~= nil and zongzhanli ~= -1 then
		local msgzhanli = ScriptGlobal_Format("#{BHSDZ_150310_54}",zongzhanli)
		m_Controls.m_CapacityTitle:SetText("#{BHSDZ_150310_54}")
		m_Controls.m_CapacityName:SetText(zongzhanli)
	end
	
		
	--list赋值
	-----------------
	m_Controls.m_TeamInfoList:RemoveAllItem()
	local leaderName = ""
	local leaderMenPaiID = -1
	local leaderLevel = -1
	leaderName = GangT:GetGangTerritoryInfo(index, "LeaderName")
	leaderMenPaiID = GangT:GetGangTerritoryInfo(index, "LeaderMenPai")
	leaderLevel = GangT:GetGangTerritoryInfo(index, "LeaderLevel")
	if leaderName ~= nil and leaderMenPaiID ~= nil and leaderLevel ~= nil and leaderName ~= "" and leaderMenPaiID ~= -1 and leaderLevel ~= -1 then
		m_Controls.m_TeamInfoList:AddNewItem("", 0 , 0)	
		m_Controls.m_TeamInfoList:AddNewItem(leaderName, 1 , 0)
		local menpaiID = leaderMenPaiID + 1
		if menpaiID >=1 and menpaiID <=g_nMenPaiCount then
			m_Controls.m_TeamInfoList:AddNewItem(sMenPaiName[menpaiID], 2 , 0)
		end
		m_Controls.m_TeamInfoList:AddNewItem(tostring(leaderLevel), 3 , 0)
		m_Controls.m_pic1:Show()
	else
		m_Controls.m_pic1:Hide()
	end
	
	
	local mem1name = GangT:GetGangTerritoryInfo(index, "MemIName")
	local mem1MenPaiID = GangT:GetGangTerritoryInfo(index, "MemIMenPai")
	local mem1Level = GangT:GetGangTerritoryInfo(index, "MemILevel")	
	if mem1name ~= nil and mem1MenPaiID ~= nil and mem1Level ~= nil and mem1name ~= "" and mem1MenPaiID ~= -1 and mem1Level ~= -1 then
		m_Controls.m_TeamInfoList:AddNewItem("", 0 , 1)	
		m_Controls.m_TeamInfoList:AddNewItem(mem1name, 1 , 1)
		local menpaiID = mem1MenPaiID + 1
		if menpaiID >=1 and menpaiID <=g_nMenPaiCount then
			m_Controls.m_TeamInfoList:AddNewItem(sMenPaiName[menpaiID], 2 , 1)
		end
		m_Controls.m_TeamInfoList:AddNewItem(tostring(mem1Level), 3 , 1)
		m_Controls.m_pic2:Show()
	else
		m_Controls.m_pic2:Hide()
	end
	
	local mem2name = GangT:GetGangTerritoryInfo(index, "MemIIName")
	local mem2MenPaiID = GangT:GetGangTerritoryInfo(index, "MemIIMenPai")
	local mem2Level = GangT:GetGangTerritoryInfo(index, "MemIILevel")	
	if mem2name ~= nil and mem2MenPaiID ~= nil and mem2Level ~= nil and mem2name ~= "" and mem2MenPaiID ~= -1 and mem2Level ~= -1 then
		m_Controls.m_TeamInfoList:AddNewItem("", 0 , 2)	
		m_Controls.m_TeamInfoList:AddNewItem(mem2name, 1 , 2)
		local menpaiID = mem2MenPaiID + 1
		if menpaiID >=1 and menpaiID <=g_nMenPaiCount then
			m_Controls.m_TeamInfoList:AddNewItem(sMenPaiName[menpaiID], 2 , 2)
		end
		m_Controls.m_TeamInfoList:AddNewItem(tostring(mem2Level), 3 , 2)
		m_Controls.m_pic3:Show()
	else
		m_Controls.m_pic3:Hide()	
	end
	
	
	local mem3name = GangT:GetGangTerritoryInfo(index, "MemIIIName")
	local mem3MenPaiID = GangT:GetGangTerritoryInfo(index, "MemIIIMenPai")
	local mem3Level = GangT:GetGangTerritoryInfo(index, "MemIIILevel")	
	if mem3name ~= nil and mem3MenPaiID ~= nil and mem3Level ~= nil and mem3name ~= "" and mem3MenPaiID ~= -1 and mem3Level ~= -1 then
		m_Controls.m_TeamInfoList:AddNewItem("", 0 , 3)	
		m_Controls.m_TeamInfoList:AddNewItem(mem3name, 1 , 3)
		local menpaiID = mem3MenPaiID + 1
		if menpaiID >=1 and menpaiID <=g_nMenPaiCount then
			m_Controls.m_TeamInfoList:AddNewItem(sMenPaiName[menpaiID], 2 , 3)
		end
		
		m_Controls.m_TeamInfoList:AddNewItem(tostring(mem3Level), 3 , 3)
		m_Controls.m_pic4:Show()
	else
		m_Controls.m_pic4:Hide()
	end

	local mem4name = GangT:GetGangTerritoryInfo(index, "MemIXName")
	local mem4MenPaiID = GangT:GetGangTerritoryInfo(index, "MemIXMenPai")
	local mem4Level = GangT:GetGangTerritoryInfo(index, "MemIXLevel")	
	if mem4name ~= nil and mem4MenPaiID ~= nil and mem4Level ~= nil and mem4name ~= "" and mem4MenPaiID ~= -1 and mem4Level ~= -1 then
		m_Controls.m_TeamInfoList:AddNewItem("", 0 , 4)	
		m_Controls.m_TeamInfoList:AddNewItem(mem4name, 1 , 4)
		local menpaiID = mem4MenPaiID + 1
		if menpaiID >=1 and menpaiID <=g_nMenPaiCount then
			m_Controls.m_TeamInfoList:AddNewItem(sMenPaiName[menpaiID], 2 , 4)
		end
		m_Controls.m_TeamInfoList:AddNewItem(tostring(mem4Level), 3 , 4)	
		m_Controls.m_pic5:Show()
	else
		m_Controls.m_pic5:Hide()
	end
	
	local mem5name = GangT:GetGangTerritoryInfo(index, "MemXName")
	local mem5MenPaiID = GangT:GetGangTerritoryInfo(index, "MemXMenPai")
	local mem5Level = GangT:GetGangTerritoryInfo(index, "MemXLevel")	
	if mem5name ~= nil and mem5MenPaiID ~= nil and mem5Level ~= nil and mem5name ~= "" and mem5MenPaiID ~= -1 and mem5Level ~= -1 then
		m_Controls.m_TeamInfoList:AddNewItem("", 0 , 5)	
		m_Controls.m_TeamInfoList:AddNewItem(mem5name, 1 , 5)
		local menpaiID = mem5MenPaiID + 1
		if menpaiID >=1 and menpaiID <=g_nMenPaiCount then
			m_Controls.m_TeamInfoList:AddNewItem(sMenPaiName[menpaiID], 2 , 5)
		end
		m_Controls.m_TeamInfoList:AddNewItem(tostring(mem5Level), 3 , 5)
		m_Controls.m_pic6:Show()
	else
		m_Controls.m_pic6:Hide()
	end
	
	--查看资料
	m_Controls.m_ButtonPickOut:SetText("#{BHSDZ_150310_58}")
	--设为私聊
	m_Controls.m_ButtonInvite:SetText("#{BHSDZ_150310_59}")
	
	--this:Show()
end

function BangHui_Fight_TeamView_Close()
	if g_objCared ~= -1 then
		this:CareObject(g_objCared, 0, "BangHui_Fight_TeamView")
		g_objCared = -1
	end
	this:Hide()
end

function BangHui_Fight_TeamView_Frame_On_ResetPos()
	 m_Controls.m_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--回调函数-关闭
function BangHui_Fight_TeamView_OnClosed()
	BangHui_Fight_TeamView_Close()
end

--回调函数-队伍查看
function BangHui_Fight_TeamView_OnInvite()
	local listIndex = m_Controls.m_TeamInfoList:GetSelectItem()
	--私聊
	local name = ""
	if listIndex == 0 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "LeaderName")
	elseif listIndex == 1 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemIName")
	elseif listIndex == 2 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemIIName")
	elseif listIndex == 3 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemIIIName")
	elseif listIndex == 4 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemIXName")
	elseif listIndex == 5 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemXName")
	end
	
	local zoneworldid =  DataPool:GetSelfZoneWorldID()
	if name ~= nil and name ~= "" then
		Talk:ContexMenuTalk( name, zoneworldid )
	end
end

function BangHui_Fight_TeamView_OnCheckInfo()
	--详细信息查看
	local listIndex = m_Controls.m_TeamInfoList:GetSelectItem()
	local name = ""
	if listIndex == 0 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "LeaderName")
	elseif listIndex == 1 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemIName")
	elseif listIndex == 2 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemIIName")
	elseif listIndex == 3 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemIIIName")
	elseif listIndex == 4 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemIXName")
	elseif listIndex == 5 then
		name =  GangT:GetGangTerritoryInfo(g_ViewIndex, "MemXName")
	end
	
	local zoneworldid =  DataPool:GetSelfZoneWorldID()
	if name ~= nil and name ~= "" then
		if( Friend:IsPlayerIsFriend( name, -1 ) == 1 ) then
			DataPool:ShowFriendInfo( name, -1 );
		else
			DataPool:ShowChatInfoByZWId( name, zoneworldid )
		end
	end
end