local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


local BieYePersonnelManage_ctrlTexts = {}

local BieYePersonnelManage_ctrlPlayerFlash = {}


local BieYePersonnelManage_ItemIndex_Select = {} 	-- 选中的物品下标
local BieYePersonnelManage_ItemCount_Select = 0 	-- 当前选中的物品数

local BieYePersonnelManage_ItemCount_Show = 0 		-- 当前显示的物品数
local BieYePersonnelManage_ItemIndex_Show = {}		-- 显示的物品下标

local g_RefreshListTypeNext = 2

local CurPage = 1

local CurMaxPage = 1

local g_clientNpcId = -1

local g_MenPaiCount = 15;--menpai15 mptodo

--门派名称
local BieYePersonnelManage_sMenPaiNameArry={"少林","明教","丐帮","武当","峨嵋","星宿","天龙","天山","逍遥","无门派","慕容","唐门","鬼谷", "#{XQ_MP_15}", "#{XMPHM_210604_01}","#{GMGameInterface_Script_DataPool_Info_ERenGu}"} --桃花岛 menpai15 mptodo

function BieYePersonnelManage_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--刷新成员信息
	this:RegisterEvent("BIEYE_UPDATE_SCENEPLAYERINFOLIST")
	this:RegisterEvent("UI_COMMAND")			-- 界面


end

function BieYePersonnelManage_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BieYePersonnelManage_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BieYePersonnelManage_Frame:GetProperty("UnifiedYPosition");

	BieYePersonnelManage_ctrlTexts =
	{
		[1]  = {BieYePersonnelManage_List1_Text_1,  BieYePersonnelManage_List1_Text_2,  BieYePersonnelManage_List1_Text_3, BieYePersonnelManage_List1_Text_4, },
		[2]  = {BieYePersonnelManage_List2_Text_1,  BieYePersonnelManage_List2_Text_2,  BieYePersonnelManage_List2_Text_3, BieYePersonnelManage_List2_Text_4, },
		[3]  = {BieYePersonnelManage_List3_Text_1,  BieYePersonnelManage_List3_Text_2,  BieYePersonnelManage_List3_Text_3, BieYePersonnelManage_List3_Text_4, },
		[4]  = {BieYePersonnelManage_List4_Text_1,  BieYePersonnelManage_List4_Text_2,  BieYePersonnelManage_List4_Text_3, BieYePersonnelManage_List4_Text_4, },
		[5]  = {BieYePersonnelManage_List5_Text_1,  BieYePersonnelManage_List5_Text_2,  BieYePersonnelManage_List5_Text_3, BieYePersonnelManage_List5_Text_4, },
		[6]  = {BieYePersonnelManage_List6_Text_1,  BieYePersonnelManage_List6_Text_2,  BieYePersonnelManage_List6_Text_3, BieYePersonnelManage_List6_Text_4, },
		[7]  = {BieYePersonnelManage_List7_Text_1,  BieYePersonnelManage_List7_Text_2,  BieYePersonnelManage_List7_Text_3, BieYePersonnelManage_List7_Text_4, },
		[8]  = {BieYePersonnelManage_List8_Text_1,  BieYePersonnelManage_List8_Text_2,  BieYePersonnelManage_List8_Text_3, BieYePersonnelManage_List8_Text_4, },
		[9]  = {BieYePersonnelManage_List9_Text_1,  BieYePersonnelManage_List9_Text_2,  BieYePersonnelManage_List9_Text_3, BieYePersonnelManage_List9_Text_4, },
		[10] = {BieYePersonnelManage_List10_Text_1,  BieYePersonnelManage_List10_Text_2,  BieYePersonnelManage_List10_Text_3, BieYePersonnelManage_List10_Text_4, },

	}

	BieYePersonnelManage_ctrlPlayerFlash =
	{
		BieYePersonnelManage_List1_Flash, BieYePersonnelManage_List2_Flash, BieYePersonnelManage_List3_Flash, BieYePersonnelManage_List4_Flash, BieYePersonnelManage_List5_Flash,
		BieYePersonnelManage_List6_Flash, BieYePersonnelManage_List7_Flash, BieYePersonnelManage_List8_Flash, BieYePersonnelManage_List9_Flash, BieYePersonnelManage_List10_Flash,
	}

	BieYePersonnelManage_ClearPlayerList()

	BieYePersonnelManage_ItemCount_Select = 0
	for i = 1,10 do
		BieYePersonnelManage_ItemIndex_Select[i] = 0
	end


end

function BieYePersonnelManage_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BieYePersonnelManage_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BieYePersonnelManage_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
	--切换场景关闭界面，清楚计时器,情况客户端的城战信息

		BieYePersonnelManage_StopCareObject()
		this:Hide()
	elseif (event == "BIEYE_UPDATE_SCENEPLAYERINFOLIST" ) then

		BieYePersonnelManage_RefreshMenberList(tonumber(arg0) , tonumber(arg1))
	--	end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 891946 ) then  --打开界面
	--	PushDebugMessage("OPen")
		g_clientNpcId = DataPool:GetNPCIDByServerID(Get_XParam_INT(0))
		BieYePersonnelManage_BeginCareObject()
		BieYePersonnelManage_BtnListCtrl_BtnUpPage:Disable()
		BieYePersonnelManage_BtnListCtrl_BtnDownPage:Disable()
		--BieYePersonnelManage_Clear()
		this:Show()

	--	BieYePersonnelManage_Refresh_PlayerList()

	end
end

--================================================
-- 想服务器请求数据 刷新成员列表
--================================================
function BieYePersonnelManage_AskRefresh()
	if (this:IsVisible()) then

	end
end



--================================================
-- 刷新成员列表数据
--================================================
function BieYePersonnelManage_RefreshMenberList(nPage,MaxPage)
--PushDebugMessage(nPage.."/"..MaxPage)

		BieYePersonnelManage_Clear()
		CurPage = nPage
		CurMaxPage = MaxPage
		local count = 1
		local Num = DataPool:GetBieYeScenePlayerCount();
		if Num > 0 then
			for nIdx=0, Num-1 do
				local playerName,
				nLevel,
				nMenpaiId,
				GuildName= DataPool:GetBieYeScenePlayerInfo(nIdx)		--攻击方成员信息


				if playerName == nil or playerName == "" then
					break
				end

				local sMenPaiName =""
				if nMenpaiId >= 0 and nMenpaiId <= g_MenPaiCount then
					sMenPaiName = BieYePersonnelManage_sMenPaiNameArry[nMenpaiId + 1]
				end

				if GuildName == nil then
					GuildName = ""
				end

				BieYePersonnelManage_InsertPlayerList(count, playerName, nLevel, sMenPaiName, GuildName)

				BieYePersonnelManage_ItemIndex_Show[count] = 1
				BieYePersonnelManage_ItemCount_Show = BieYePersonnelManage_ItemCount_Show + 1

				count = count+1

			end
		end

		BieYePersonnelManage_BtnListCtrl_TextSplitPage:SetText(nPage.."/"..MaxPage)
		if nPage == 1 then
			BieYePersonnelManage_BtnListCtrl_BtnUpPage:Disable()
		else
			BieYePersonnelManage_BtnListCtrl_BtnUpPage:Enable()
		end
		if nPage == MaxPage then
			BieYePersonnelManage_BtnListCtrl_BtnDownPage:Disable()
		else
			BieYePersonnelManage_BtnListCtrl_BtnDownPage:Enable()
		end


end




--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYePersonnelManage_ResetPos()
	BieYePersonnelManage_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BieYePersonnelManage_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 关闭当前界面-需要清楚计时器
--================================================
function BieYePersonnelManage_Closed()
--	PushDebugMessage("close")
--	KillTimer("KVKLeague_ChengZhan_AskRefresh()")
--	g_IsTimeropen = 0
	BieYePersonnelManage_StopCareObject()
	this:Hide()
end

-- 插入玩家信息
function BieYePersonnelManage_InsertPlayerList(line, PlayerName, Level, Menpai, GuildName)
	local i = line
	BieYePersonnelManage_ctrlTexts[i][1]:SetText(PlayerName)
	BieYePersonnelManage_ctrlTexts[i][2]:SetText(Level)
	BieYePersonnelManage_ctrlTexts[i][3]:SetText(Menpai)
	BieYePersonnelManage_ctrlTexts[i][4]:SetText(GuildName)
--	YbMarket_ctrlEquipActions[i]:Show()
end

--清除玩家信息
function BieYePersonnelManage_ClearPlayerList()
	local i
	for i = 1, 10 do
		--for j = 1, 4 do
		--	BieYePersonnelManage_ctrlTexts[i][j]:SetText("")
		BieYePersonnelManage_ctrlTexts[i][1]:SetText("")
		BieYePersonnelManage_ctrlTexts[i][2]:SetText("")
		BieYePersonnelManage_ctrlTexts[i][3]:SetText("")
		BieYePersonnelManage_ctrlTexts[i][4]:SetText("")
		--end
	end

	BieYePersonnelManage_ItemCount_Show = 0
	for i = 1,10 do
		BieYePersonnelManage_ItemIndex_Show[i] = 0
	end

	for i = 1, 10 do
		BieYePersonnelManage_ctrlPlayerFlash[i]:Hide()
	end
	--PushDebugMessage("clear")
end

--选中
function BieYePersonnelManage_PlayerSelect(index)
	if index < 1 or index > 10 then
		return
	end
	if index>BieYePersonnelManage_ItemCount_Show then
		return
	end

	--判断当前选中状态
	local bCheck = BieYePersonnelManage_ItemIndex_Select[index]
	if bCheck == 1 then--已经选中的取消选中
		BieYePersonnelManage_ctrlPlayerFlash[index]:Hide()
		--YbMarket_ctrlItemChecks[index] : SetCheck(0)--取消选中
		BieYePersonnelManage_ItemIndex_Select[index] = 0
		BieYePersonnelManage_ItemCount_Select = BieYePersonnelManage_ItemCount_Select - 1--数量自减
		if BieYePersonnelManage_ItemCount_Select ~= BieYePersonnelManage_ItemCount_Show then--不满足勾选上限
		--	BieYePersonnelManage_BtnListCtrl_BtnQX:SetCheck(0)--取消全选
			BieYePersonnelManage_BtnListCtrl_BtnQX:SetText("#{JYGZ_160707_235}")
			BieYePersonnelManage_BtnListCtrl_BtnQX:SetToolTip("#{JYGZ_160809_426}")
		end
	else	--未选中的进入勾选逻辑
		if BieYePersonnelManage_ItemCount_Select >= 10 then--超过勾选上限
			PushDebugMessage("#{SHPLGM_150428_01}")--勾选已达上限，每次最多可勾选10项物品。
			return
		else--可以选中
			BieYePersonnelManage_ctrlPlayerFlash[index]:Show()
			--YbMarket_ctrlItemChecks[index] : SetCheck(1)--选中
			BieYePersonnelManage_ItemIndex_Select[index] = 1
			BieYePersonnelManage_ItemCount_Select = BieYePersonnelManage_ItemCount_Select + 1--数量自增
			if BieYePersonnelManage_ItemCount_Select == BieYePersonnelManage_ItemCount_Show then--达到勾选上限
			--	BieYePersonnelManage_BtnListCtrl_BtnQX:SetCheck(1)--选中全选
				BieYePersonnelManage_BtnListCtrl_BtnQX:SetText("#{JYGZ_160809_427}")
				BieYePersonnelManage_BtnListCtrl_BtnQX:SetToolTip("#{JYGZ_160809_428}")
			end
		end
	end
end

--全选
function BieYePersonnelManage_PlayerSelectAll()

--	local bCheck = BieYePersonnelManage_BtnListCtrl_BtnQX : GetCheck()
--	PushDebugMessage("bCheck="..bCheck)
--	if bCheck == 1 then--已经选中的取消选中
	if BieYePersonnelManage_ItemCount_Select == BieYePersonnelManage_ItemCount_Show then
		--YbMarket_DX : SetCheck(0)--取消选中
		BieYePersonnelManage_ItemCount_Select = 0--数量清空
		for i=1,10 do--全部取消选中
			if BieYePersonnelManage_ItemIndex_Show[i] == 1 and BieYePersonnelManage_ItemIndex_Select[i] == 1 then
				BieYePersonnelManage_ctrlPlayerFlash[i] : Hide()
			--	YbMarket_ctrlItemChecks[i] : SetCheck(0)--选中
				BieYePersonnelManage_ItemIndex_Select[i] = 0
			end
		end
		BieYePersonnelManage_BtnListCtrl_BtnQX:SetText("#{JYGZ_160707_235}")
		BieYePersonnelManage_BtnListCtrl_BtnQX:SetToolTip("#{JYGZ_160809_426}")
	else	--未选中的进入勾选逻辑
		if BieYePersonnelManage_ItemCount_Show > 10 then--超过勾选上限
			PushDebugMessage("#{SHPLGM_150428_01}")--勾选已达上限，每次最多可勾选10项物品。
			return
		else--可以选中
			--YbMarket_DX : SetCheck(1)--选中全选
			BieYePersonnelManage_ItemCount_Select = BieYePersonnelManage_ItemCount_Show--数量设置
			for i=1,10 do--全部选中
				if BieYePersonnelManage_ItemIndex_Show[i] == 1 and BieYePersonnelManage_ItemIndex_Select[i] ~= 1 then
					BieYePersonnelManage_ctrlPlayerFlash[i] : Show()
				--	YbMarket_ctrlItemChecks[i] : SetCheck(1)--选中
					BieYePersonnelManage_ItemIndex_Select[i] = 1
				end
			end
		end
		BieYePersonnelManage_BtnListCtrl_BtnQX:SetText("#{JYGZ_160809_427}")
		BieYePersonnelManage_BtnListCtrl_BtnQX:SetToolTip("#{JYGZ_160809_428}")
	end

end

--清除数据
function BieYePersonnelManage_Clear()
	BieYePersonnelManage_ClearPlayerList()

	--BieYePersonnelManage_BtnListCtrl_BtnQX:SetCheck(0)
	BieYePersonnelManage_BtnListCtrl_BtnQX:SetText("#{JYGZ_160707_235}")
	BieYePersonnelManage_BtnListCtrl_BtnQX:SetToolTip("#{JYGZ_160809_426}")

	BieYePersonnelManage_ItemCount_Select = 0
	for i = 1,10 do
		BieYePersonnelManage_ItemIndex_Select[i] = 0
	end
end

--刷新
function BieYePersonnelManage_Refresh_PlayerList()
--	PushDebugMessage("re")
	local isCanDo = DataPool:IsBieyePlayerListCanRefresh()
	if isCanDo == 0 then
		PushDebugMessage("#{YBSC_100111_40}")
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnRefreshPlayerListByPage")
		Set_XSCRIPT_ScriptID(891946)
		Set_XSCRIPT_Parameter(0,CurPage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

-- 上一页
function BieYePersonnelManage_btnUpPageClicked()
	local isCanDo = DataPool:IsBieyePlayerListCanRefresh()
	if isCanDo == 0 then
		PushDebugMessage("#{YBSC_100111_40}")
		return
	end
	local AskPage = CurPage -1
	if AskPage < 1 then
		AskPage = 1
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnRefreshPlayerListByPage")
		Set_XSCRIPT_ScriptID(891946)
		Set_XSCRIPT_Parameter(0,AskPage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

-- 下一页
function BieYePersonnelManage_btnDownPageClicked()
	local isCanDo = DataPool:IsBieyePlayerListCanRefresh()
	if isCanDo == 0 then
		PushDebugMessage("#{YBSC_100111_40}")
		return
	end
	local AskPage = CurPage +1
	if AskPage > CurMaxPage then
		AskPage = CurMaxPage
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnRefreshPlayerListByPage")
		Set_XSCRIPT_ScriptID(891946)
		Set_XSCRIPT_Parameter(0,AskPage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--踢人
function BieYePersonnelManage_TickPlayerClicked()
	for i=1,10 do
		DataPool:SetBieYePlayerSelect(i-1, BieYePersonnelManage_ItemIndex_Select[i])
	end
	DataPool:TickBieYeScenePlayer()
end


--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BieYePersonnelManage_BeginCareObject()
	this:CareObject(g_clientNpcId, 1, "BieYePersonnelManage")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function BieYePersonnelManage_StopCareObject()
	this:CareObject(g_clientNpcId, 0, "BieYePersonnelManage")
end
