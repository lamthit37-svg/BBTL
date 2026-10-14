-- 全民8星主界面
-- !!!reloadscript =StarEquip_Main

local g_StarEquip_Main_Frame_UnifiedPosition = nil
local g_StarEquip_Main_Step = {}
local g_StarEquip_Main_StepInfo = {}
local g_StarEquip_Main_Steplock = {}
local g_StarEquip_Main_DayGet = {}
local g_StarEquip_Main_DayTips = {}
local g_StarEquip_Main_DayReceived = {}

local g_StarEquip_Main_Day = {
	[1] = 1,
	[2] = 3,
	[3] = 7,
	[4] = 11,
	[5] = 15,
}

local g_StarEquip_Main_Unlock = {
[1] = 0,
[2] = 4,
[3] = 6,
[4] = 8,
}

function StarEquip_Main_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("QM8X_OPEN_MAINUI");
	this:RegisterEvent("QM8X_UPDATA_MAINUI",false);
	this:RegisterEvent("QM8X_UPDATA_GETEQUIP",false);
	this:RegisterEvent("QM8X_OPEN_CHANGE",false);
	this:RegisterEvent("QM8X_UPDATA_TIMES",false);
	
	--玩家切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function StarEquip_Main_OnLoad()

	g_StarEquip_Main_Frame_UnifiedPosition = StarEquip_Main_Frame:GetProperty("UnifiedPosition");
	
	g_StarEquip_Main_DayGet = {
		StarEquip_Main_Frame_Get1,
		StarEquip_Main_Frame_Get2,
		StarEquip_Main_Frame_Get3,
		StarEquip_Main_Frame_Get4,
		StarEquip_Main_Frame_Get5,
		}
		
	g_StarEquip_Main_DayTips = {
		StarEquip_Main_Frame_Get_Tips1,
		StarEquip_Main_Frame_Get_Tips2,
		StarEquip_Main_Frame_Get_Tips3,
		StarEquip_Main_Frame_Get_Tips4,
		StarEquip_Main_Frame_Get_Tips5,
		}
		
	g_StarEquip_Main_DayReceived = {
		StarEquip_Main_Frame_Get_Received1,
		StarEquip_Main_Frame_Get_Received2,
		StarEquip_Main_Frame_Get_Received3,
		StarEquip_Main_Frame_Get_Received4,
		StarEquip_Main_Frame_Get_Received5,
		}
	
	g_StarEquip_Main_Step = { 
		[1] = {StarEquip_Main_EquipClient1_Step1, StarEquip_Main_EquipClient1_Step2},
		[2] = {StarEquip_Main_EquipClient2_Step1, StarEquip_Main_EquipClient2_Step2},
		[3] = {StarEquip_Main_EquipClient3_Step1, StarEquip_Main_EquipClient3_Step2},
		[4] = {StarEquip_Main_EquipClient4_Step1, StarEquip_Main_EquipClient4_Step2},
		}
		
	g_StarEquip_Main_Steplock = {
		[1] = {StarEquip_Main_EquipClient1_Step1_Text2, StarEquip_Main_EquipClient1_Step1_Start},
		[2] = {StarEquip_Main_EquipClient2_Step1_Text2, StarEquip_Main_EquipClient2_Step1_Start},
		[3] = {StarEquip_Main_EquipClient3_Step1_Text2, StarEquip_Main_EquipClient3_Step1_Start},
		[4] = {StarEquip_Main_EquipClient4_Step1_Text2, StarEquip_Main_EquipClient4_Step1_Start},
		}
	
	g_StarEquip_Main_StepInfo = {
		[1] = {
			itemaction = StarEquip_Main_EquipClient1_Step2_Item,
			itemname = StarEquip_Main_EquipClient1_Step2_ItemName,
			itemattr = StarEquip_Main_EquipClient1_Step2_Attribute,
			refreshbutton = StarEquip_Main_EquipClient1_Step2_Refresh,
			getbutton = StarEquip_Main_EquipClient1_Step2_Get,
			receivedimage = StarEquip_Main_EquipClient1_Step2_Received,
			itemStarsSet = StarEquip_Main_EquipClient1_StarSet,
			itemStars={
				StarEquip_Main_EquipClient1_Star1,
				StarEquip_Main_EquipClient1_Star2,
				StarEquip_Main_EquipClient1_Star3,
				StarEquip_Main_EquipClient1_Star4,
				StarEquip_Main_EquipClient1_Star5,
				StarEquip_Main_EquipClient1_Star6,
				StarEquip_Main_EquipClient1_Star7,
				StarEquip_Main_EquipClient1_Star8,
				StarEquip_Main_EquipClient1_Star9,
				},
			},
		[2] = {
			itemaction = StarEquip_Main_EquipClient2_Step2_Item,
			itemname = StarEquip_Main_EquipClient2_Step2_ItemName,
			itemattr = StarEquip_Main_EquipClient2_Step2_Attribute,
			refreshbutton = StarEquip_Main_EquipClient2_Step2_Refresh,
			getbutton = StarEquip_Main_EquipClient2_Step2_Get,
			receivedimage = StarEquip_Main_EquipClient2_Step2_Received,
			itemStarsSet = StarEquip_Main_EquipClient2_StarSet,
			itemStars={
				StarEquip_Main_EquipClient2_Star1,
				StarEquip_Main_EquipClient2_Star2,
				StarEquip_Main_EquipClient2_Star3,
				StarEquip_Main_EquipClient2_Star4,
				StarEquip_Main_EquipClient2_Star5,
				StarEquip_Main_EquipClient2_Star6,
				StarEquip_Main_EquipClient2_Star7,
				StarEquip_Main_EquipClient2_Star8,
				StarEquip_Main_EquipClient2_Star9,
				},
			},
		[3] = {
			itemaction = StarEquip_Main_EquipClient3_Step2_Item,
			itemname = StarEquip_Main_EquipClient3_Step2_ItemName,
			itemattr = StarEquip_Main_EquipClient3_Step2_Attribute,
			refreshbutton = StarEquip_Main_EquipClient3_Step2_Refresh,
			getbutton = StarEquip_Main_EquipClient3_Step2_Get,
			receivedimage = StarEquip_Main_EquipClient3_Step2_Received,
			itemStarsSet = StarEquip_Main_EquipClient3_StarSet,
			itemStars={
				StarEquip_Main_EquipClient3_Star1,
				StarEquip_Main_EquipClient3_Star2,
				StarEquip_Main_EquipClient3_Star3,
				StarEquip_Main_EquipClient3_Star4,
				StarEquip_Main_EquipClient3_Star5,
				StarEquip_Main_EquipClient3_Star6,
				StarEquip_Main_EquipClient3_Star7,
				StarEquip_Main_EquipClient3_Star8,
				StarEquip_Main_EquipClient3_Star9,
				},
			},
		[4] = {
			itemaction = StarEquip_Main_EquipClient4_Step2_Item,
			itemname = StarEquip_Main_EquipClient4_Step2_ItemName,
			itemattr = StarEquip_Main_EquipClient4_Step2_Attribute,
			refreshbutton = StarEquip_Main_EquipClient4_Step2_Refresh,
			getbutton = StarEquip_Main_EquipClient4_Step2_Get,
			receivedimage = StarEquip_Main_EquipClient4_Step2_Received,
			itemStarsSet = StarEquip_Main_EquipClient4_StarSet,
			itemStars={
				StarEquip_Main_EquipClient4_Star1,
				StarEquip_Main_EquipClient4_Star2,
				StarEquip_Main_EquipClient4_Star3,
				StarEquip_Main_EquipClient4_Star4,
				StarEquip_Main_EquipClient4_Star5,
				StarEquip_Main_EquipClient4_Star6,
				StarEquip_Main_EquipClient4_Star7,
				StarEquip_Main_EquipClient4_Star8,
				StarEquip_Main_EquipClient4_Star9,
				},
			},
	}

end

function StarEquip_Main_OnEvent(event)

	if (event == "QM8X_OPEN_MAINUI") then
	
		if this:IsVisible() then
			StarEquip_Main_OnClosed()
			return
		end
		
		StarEquip_Main_Show()
		
		this:Show()
		
	elseif (event == "QM8X_UPDATA_MAINUI" or event == "QM8X_OPEN_CHANGE") then
	
		if this:IsVisible() then
			StarEquip_Main_Show()
		end
		
	elseif (event == "QM8X_UPDATA_GETEQUIP") then
	
		if this:IsVisible() then
			local dazaoidx = tonumber(arg0) + 1
			StarEquip_Main_Start_UpdateLuZi(dazaoidx)
		end
		
	elseif (event == "QM8X_UPDATA_TIMES") then
		if this:IsVisible() then
			StarEquip_Main_UpdateTimes()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		StarEquip_Main_OnClosed()
			
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS") then
		StarEquip_Main_ResetPos()
		
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		StarEquip_Main_ResetPos()
	end
	
end

function StarEquip_Main_UpdateTimes()
	
	-- 剩余打造次数
	local nCanUseDaZaoCount = Player:LuaFnGetQM8XCanUseDaZaoCount()
	local str = ScriptGlobal_Format("#{XFXB_230823_26}", nCanUseDaZaoCount)
	StarEquip_Main_Frame_LeftText:SetText(str)
				
	local nLen = table.getn(g_StarEquip_Main_Day)
	local nIdx, nVal = Player:LuaFnGetQM8XActivePointInfo()
		
	-- 活跃相关
	if nVal ~= nil then
		StarEquip_Main_Frame_RightText:Show()
		str = ScriptGlobal_Format("#{XFXB_230823_28}", nVal)	
		StarEquip_Main_Frame_RightText:SetText(str)
	end
		
	if g_StarEquip_Main_Day[nIdx+1] ~= nil then	
	
		for idx = 1, nLen do
			if idx < nIdx + 1 then
				g_StarEquip_Main_DayGet[idx]:Hide()
				g_StarEquip_Main_DayReceived[idx]:Show()
			else
				g_StarEquip_Main_DayGet[idx]:Show()
				g_StarEquip_Main_DayReceived[idx]:Hide()
			end
			
			g_StarEquip_Main_DayTips[idx]:Hide()			
			if idx >= nIdx + 1 then
				if nVal >= g_StarEquip_Main_Day[idx] then
					g_StarEquip_Main_DayTips[idx]:Show()
				end
			end
		end
	else
		for idx = 1, nLen do	
			g_StarEquip_Main_DayGet[idx]:Hide()
			g_StarEquip_Main_DayReceived[idx]:Show()	
			g_StarEquip_Main_DayTips[idx]:Hide()
		end
	end
	
end

function StarEquip_Main_Show()
	
	-- 详情
	local isOpen, beginTime, endTime = DataPool:Lua_GetNewServerQuanMin8XingTime()
	local nbeginYear = math.floor(beginTime/10000)
	local nbeginMonth = math.mod(math.floor(beginTime/100), 100)
	local nbeginDay = math.mod(beginTime, 100)		
	local nendYear = math.floor(endTime/10000)
	local nendMonth = math.mod(math.floor(endTime/100), 100)
	local nendDay = math.mod(endTime, 100)
	
	local nYear, nMonth, nDay = Player:LuaFnGetQM8XActEndTime()
	local str = ScriptGlobal_Format("#{XFXB_230823_04}", nbeginYear, nbeginMonth, nbeginDay, nendYear, nendMonth, nendDay, nYear, nMonth, nDay)
	StarEquip_Main_Frame_Info:SetText(str)
	
	StarEquip_Main_UpdateTimes()
	
	StarEquip_Main_EquipClient1_Step1_Text2:Hide()
	
	for i = 1, 4 do
		StarEquip_Main_Start_UpdateLuZi(i)
	end
	
end

function StarEquip_Main_Start_UpdateLuZi(idx)

	if idx < 1 or idx > 4 then
		return
	end

	local nDaZaoIdx, nIsUnLock, nIsDaZao, nIsReceive, nItemId = Player:LuaFnGetQM8XDaZaoDataByIdx(idx-1)
	if nDaZaoIdx >= 0 then
		if nIsUnLock == 0 then
		-- 未解锁
			g_StarEquip_Main_Step[idx][1]:Show()
			g_StarEquip_Main_Step[idx][2]:Hide()
				
			if g_StarEquip_Main_Unlock[idx] ~= 0 then
				g_StarEquip_Main_Steplock[idx][1]:Show()
				str = ScriptGlobal_Format("#{XFXB_230823_08}", g_StarEquip_Main_Unlock[idx])
				g_StarEquip_Main_Steplock[idx][1]:SetText(str)
			else	
				g_StarEquip_Main_Steplock[idx][1]:Hide()
			end
			g_StarEquip_Main_Steplock[idx][2]:Hide()
		else
			if nIsDaZao == 0 then
			-- 未开炉
				g_StarEquip_Main_Step[idx][1]:Show()
				g_StarEquip_Main_Step[idx][2]:Hide()
					
				g_StarEquip_Main_Steplock[idx][1]:Hide()
				g_StarEquip_Main_Steplock[idx][2]:Show()
			else
				g_StarEquip_Main_Step[idx][1]:Hide()
				g_StarEquip_Main_Step[idx][2]:Show()
					
				if nIsReceive == 1 then
				-- 已领取
					g_StarEquip_Main_StepInfo[idx].receivedimage:Show()
					g_StarEquip_Main_StepInfo[idx].refreshbutton:Hide()
					g_StarEquip_Main_StepInfo[idx].getbutton:Hide()
				else
					g_StarEquip_Main_StepInfo[idx].receivedimage:Hide()
					g_StarEquip_Main_StepInfo[idx].refreshbutton:Show()
					g_StarEquip_Main_StepInfo[idx].getbutton:Show()
				end
					
				g_StarEquip_Main_StepInfo[idx].itemStarsSet:Hide()	
				if nItemId > 0 then
					
					local nEquipColor = "#cFFFF00"
					local theAction = EnumAction(idx-1, "quanmin8xing");
					if theAction:GetID() ~= 0 then
						g_StarEquip_Main_StepInfo[idx].itemaction:SetActionItem(theAction:GetID());
						
						local num = theAction:GetEquipAttrCount()
						local str = ""
						for i = 0, num-1 do
							local tempstr = theAction:EnumEquipExtAttr(i)
							str = str..tempstr
						end
						g_StarEquip_Main_StepInfo[idx].itemattr:SetText(str)
						
						if num <= 2 then
							nEquipColor = "#c9AFF67"
						elseif num <= 4 then
							nEquipColor = "#c00D000"
						elseif num <= 6 then
							nEquipColor = "#c43DBFF"
						elseif num <= 8 then
							nEquipColor = "#c2980FF"
						elseif num <= 10 then
							nEquipColor = "#cFF8001"
						elseif num <= 12 then
							nEquipColor = "#cF25600"
						elseif num <= 14 then
							nEquipColor = "#cE6BA00"
						end
					end
						
					local nItemName = PlayerPackage:GetEquipItemName(nItemId)
					g_StarEquip_Main_StepInfo[idx].itemname:SetText(nEquipColor..nItemName)
					
					g_StarEquip_Main_StepInfo[idx].itemStarsSet:Show()	
					for i=1,8 do
						g_StarEquip_Main_StepInfo[idx].itemStars[i]:SetProperty("Animate", "Animate_Star");
					end
					g_StarEquip_Main_StepInfo[idx].itemStars[9]:SetProperty("Animate", "Animate_StarDark");
				end
			end
		end
	end
	
end

function StarEquip_Main_Start_OKClicked(idx)
	if idx < 1 or idx > 4 then
		return
	end
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ClickKaiLuDaZaoButton");
		Set_XSCRIPT_ScriptID(998847);
		Set_XSCRIPT_Parameter(0, idx);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();	

	if IsWindowShow("StarEquip_Change") then
		CloseWindow("StarEquip_Change", true)
	end	
end

function StarEquip_Main_RefreshClicked(idx)
	if idx < 1 or idx > 4 then
		return
	end
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ClickChongZhuDaZao");
		Set_XSCRIPT_ScriptID(998847);
		Set_XSCRIPT_Parameter(0, idx);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();	

	if IsWindowShow("StarEquip_Orientation") then
		CloseWindow("StarEquip_Orientation", true)
	end	
end

function StarEquip_Main_GetEquipClicked(idx)
	if idx < 1 or idx > 4 then
		return
	end
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ReceiveDaZaoEquip");
		Set_XSCRIPT_ScriptID(998847);
		Set_XSCRIPT_Parameter(0, idx);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();	
	
	if IsWindowShow("StarEquip_Change") then
		CloseWindow("StarEquip_Change", true)
	end	

	if IsWindowShow("StarEquip_Orientation") then
		CloseWindow("StarEquip_Orientation", true)
	end	
end

function StarEquip_Main_GetClicked(idx)

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ReceiveHuoYuePointDayCount");
		Set_XSCRIPT_ScriptID(998847);
		Set_XSCRIPT_Parameter(0, idx);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();	
	
end

function StarEquip_Main_OnHidden()
	StarEquip_Main_Clear(1) --先把原来的清空了
end

function StarEquip_Main_OnClosed()
	StarEquip_Main_Clear(1)
	this:Hide()
end

function StarEquip_Main_Clear(cleanaction)
	
	StarEquip_Main_EquipClient1_Step1_Text2:Hide()

	if cleanaction == 1 then
		for i = 1, table.getn(g_StarEquip_Main_StepInfo) do
			g_StarEquip_Main_StepInfo[i].itemaction:SetActionItem(-1)
			g_StarEquip_Main_StepInfo[i].itemname:SetText("")
			g_StarEquip_Main_StepInfo[i].itemattr:SetText("")
			g_StarEquip_Main_StepInfo[i].itemStarsSet:Hide()
		end
	end
	
	for i = 1, table.getn(g_StarEquip_Main_StepInfo) do
		g_StarEquip_Main_StepInfo[i].receivedimage:Hide()
	end
	
end

function StarEquip_Main_OnHelp()

	--PushEvent("OPEN_SWEEPPAGE_QUEST", "StarEquip_Main_Help")
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnShowStarEquipHelp");
		Set_XSCRIPT_ScriptID(998847);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();	
	
end

function StarEquip_Main_ResetPos()

	StarEquip_Main_Frame:SetProperty("UnifiedPosition", g_StarEquip_Main_Frame_UnifiedPosition)
	
end


