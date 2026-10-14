--******************************************
--新杀星副本	玩家技能界面
--create by  limengyue 
--2022-07-29
--******************************************

local RouGe_Skill_Frame_UnifiedPosition;

local g_RouGe_Skill_PlayerIdx = {}--记录下玩家顺序 第几个玩家
--g_RouGe_Skill_PlayerIdx[1]={nIndex = 1,nPlayerName = "aa", nSkillID = 5002, nMenpai = 2}
local g_menpaiName = {
	[0] = "少林", [1] = "明教", [2] = "丐帮", [3] = "武当", [4] = "峨嵋", [5] = "星宿", [6] = "天龙",
	[7] = "天山", [8] = "逍遥", [9] = "无门派", [10] = "慕容", [11] = "唐门", [12] = "鬼谷", [13] = "#{XQ_MP_15}", [14] = "#{XMPHM_210604_01}", --桃花岛
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}"--menpai15 mptodo
}


--控件
local RouGe_Skill_SkillBtn = {}--展示框
local RouGe_Skill_SkillNameList = {}--技能列表
local RouGe_Skill_SkillList = {}--技能列表
local RouGe_Skill_Namelist = {}	--下拉框


--=========================================================
--PreLoad
--=========================================================
function RouGe_Skill_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--=========================================================
--OnLoad
--=========================================================
function RouGe_Skill_OnLoad()
	RouGe_Skill_Frame_UnifiedPosition = RouGe_Skill_Frame:GetProperty("UnifiedPosition");
	--展示框
	RouGe_Skill_SkillBtn[1] = RouGe_Skill_Client6_Item1
	RouGe_Skill_SkillBtn[2] = RouGe_Skill_Client6_Item2
	RouGe_Skill_SkillBtn[3] = RouGe_Skill_Client6_Item3
	RouGe_Skill_SkillBtn[4] = RouGe_Skill_Client6_Item4
	RouGe_Skill_SkillBtn[5] = RouGe_Skill_Client6_Item5
	RouGe_Skill_SkillBtn[6] = RouGe_Skill_Client6_Item6
	--名字
	RouGe_Skill_SkillNameList[1] = RouGe_Skill_Client6_Item1_Text
	RouGe_Skill_SkillNameList[2] = RouGe_Skill_Client6_Item2_Text
	RouGe_Skill_SkillNameList[3] = RouGe_Skill_Client6_Item3_Text
	RouGe_Skill_SkillNameList[4] = RouGe_Skill_Client6_Item4_Text
	RouGe_Skill_SkillNameList[5] = RouGe_Skill_Client6_Item5_Text
	RouGe_Skill_SkillNameList[6] = RouGe_Skill_Client6_Item6_Text
	--控件
	RouGe_Skill_SkillList[1] = RouGe_Skill_Client6_Item1_Icon
	RouGe_Skill_SkillList[2] = RouGe_Skill_Client6_Item2_Icon
	RouGe_Skill_SkillList[3] = RouGe_Skill_Client6_Item3_Icon
	RouGe_Skill_SkillList[4] = RouGe_Skill_Client6_Item4_Icon
	RouGe_Skill_SkillList[5] = RouGe_Skill_Client6_Item5_Icon
	RouGe_Skill_SkillList[6] = RouGe_Skill_Client6_Item6_Icon
	--下拉框
	RouGe_Skill_Namelist[1] = RouGe_Skill_Client6_Item1_Namelist
	RouGe_Skill_Namelist[2] = RouGe_Skill_Client6_Item2_Namelist
	RouGe_Skill_Namelist[3] = RouGe_Skill_Client6_Item3_Namelist
	RouGe_Skill_Namelist[4] = RouGe_Skill_Client6_Item4_Namelist
	RouGe_Skill_Namelist[5] = RouGe_Skill_Client6_Item5_Namelist
	RouGe_Skill_Namelist[6] = RouGe_Skill_Client6_Item6_Namelist
	
end

--=========================================================
--恢复界面的默认相对位置
--=========================================================
function RouGe_Skill_On_ResetPos()

	
	RouGe_Skill_Frame:SetProperty("UnifiedPosition", RouGe_Skill_Frame_UnifiedPosition);

end

--=========================================================
--OnEvent
--=========================================================
function RouGe_Skill_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99894710 ) then
		--打开界面
		if(IsWindowShow("RouGe_Skill")) then
			CloseWindow("RouGe_Skill", true)
		end
		RouGe_Skill_Open(Get_XParam_INT(0),Get_XParam_STR(0),Get_XParam_INT(1),Get_XParam_STR(1),Get_XParam_INT(2),Get_XParam_STR(2),Get_XParam_INT(3),Get_XParam_STR(3),Get_XParam_INT(4),Get_XParam_STR(4),Get_XParam_INT(5),Get_XParam_STR(5),Get_XParam_INT(6),Get_XParam_INT(7),Get_XParam_INT(8),Get_XParam_INT(9),Get_XParam_INT(10),Get_XParam_INT(11),Get_XParam_INT(12),Get_XParam_INT(13))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99894713 ) then
		--一键分配
		RouGe_Skill_Default(Get_XParam_INT(0),Get_XParam_STR(0),Get_XParam_INT(1),Get_XParam_STR(1),Get_XParam_INT(2),Get_XParam_STR(2),Get_XParam_INT(3),Get_XParam_STR(3),Get_XParam_INT(4),Get_XParam_STR(4),Get_XParam_INT(5),Get_XParam_STR(5),Get_XParam_INT(6),Get_XParam_INT(7),Get_XParam_INT(8),Get_XParam_INT(9),Get_XParam_INT(10),Get_XParam_INT(11),Get_XParam_INT(12),Get_XParam_INT(13))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99894711 ) then
		--关闭界面
		RouGe_Skill_Close()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 99894712 ) then
		--选技能失败 重置技能
		RouGe_Skill_SelectError(Get_XParam_INT(0))
	end
	if (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			RouGe_Skill_Close()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		RouGe_Skill_On_ResetPos();
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then	
		RouGe_Skill_On_ResetPos();
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       RouGe_Skill_Close()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			RouGe_Skill_Close()
		end
    end	
end

--=========================================================
--打开界面
--=========================================================
function RouGe_Skill_Open(bLeader,nPlayer1,nSkill1,nPlayer2,nSkill2,nPlayer3,nSkill3,nPlayer4,nSkill4,nPlayer5,nSkill5,nPlayer6,nSkill6,nSkillTime,nMenpai1,nMenpai2,nMenpai3,nMenpai4,nMenpai5,nMenpai6)
	--PushDebugMessage("test  RouGe_Skill_Open bLeader="..bLeader.." nPlayer1="..tostring(nPlayer1).." nSkill1="..nSkill1.." nPlayer2="..tostring(nPlayer2).." nSkill2="..nSkill2)
	--PushDebugMessage("test  nPlayer3="..tostring(nPlayer3).." nSkill3="..nSkill3.." nPlayer4="..tostring(nPlayer4).." nSkill4="..nSkill4)
	--PushDebugMessage("test  nPlayer5="..tostring(nPlayer5).." nSkill5="..nSkill5.." nPlayer6="..tostring(nPlayer6).." nSkill6="..nSkill6)
	g_RouGe_Skill_PlayerIdx = {}

	local nCount = 0
	if tonumber(nSkill1) > 0 then	
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 1,nPlayerName = tostring(nPlayer1), nSkillID = tonumber(nSkill1),nMenpai =  tonumber(nMenpai1)}
	end

	if tonumber(nSkill2)  > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 2,nPlayerName = tostring(nPlayer2), nSkillID = tonumber(nSkill2),nMenpai =  tonumber(nMenpai2)}
	end
	if tonumber(nSkill3) > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 3,nPlayerName = tostring(nPlayer3), nSkillID = tonumber(nSkill3),nMenpai =  tonumber(nMenpai3)}
	end

	if tonumber(nSkill4) > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 4,nPlayerName = tostring(nPlayer4), nSkillID = tonumber(nSkill4),nMenpai =  tonumber(nMenpai4)}
	end
	if tonumber(nSkill5) > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 5,nPlayerName = tostring(nPlayer5), nSkillID = tonumber(nSkill5),nMenpai =  tonumber(nMenpai5)}
	end
	if tonumber(nSkill6) > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 6,nPlayerName = tostring(nPlayer6), nSkillID = tonumber(nSkill6),nMenpai =  tonumber(nMenpai6)}
	end
	
	if table.getn(g_RouGe_Skill_PlayerIdx) < 1 then
		--数据异常
		PushDebugMessage("数据异常")
		return
	end

	--显示下拉框 
	--PushDebugMessage("test   listnum="..table.getn(g_RouGe_Skill_PlayerIdx))
	for index=1,table.getn(RouGe_Skill_SkillBtn)  do
		if index <= table.getn(g_RouGe_Skill_PlayerIdx) and g_RouGe_Skill_PlayerIdx[index].nSkillID > 0 then
			RouGe_Skill_SkillBtn[index]:Show()
			RouGe_Skill_Namelist[index]:ResetList()
			RouGe_Skill_Namelist[index]:AddTextItem("#{RGPT_231130_205}", 0)
			if bLeader == 1 then
				RouGe_Skill_Namelist[index]:Enable()
				for j=1,table.getn(g_RouGe_Skill_PlayerIdx)  do
					if  g_RouGe_Skill_PlayerIdx[j].nPlayerName ~= nil and string.len(g_RouGe_Skill_PlayerIdx[j].nPlayerName) > 0 then	
						local nCurName = g_RouGe_Skill_PlayerIdx[j].nPlayerName.."("..g_menpaiName[g_RouGe_Skill_PlayerIdx[j].nMenpai]..")"
						RouGe_Skill_Namelist[index]:AddTextItem(nCurName, g_RouGe_Skill_PlayerIdx[j].nIndex)
					end
				end
				RouGe_Skill_Namelist[index]:SetCurrentSelect(0)	
			else
				RouGe_Skill_Namelist[index]:SetCurrentSelect(0)	
				RouGe_Skill_Namelist[index]:Disable()
			end
			
			--展示技能图标
			local nSkillImg =GetRougepataSkillImg(g_RouGe_Skill_PlayerIdx[index].nSkillID)
			local nTips = GetRougepataSkillTips(g_RouGe_Skill_PlayerIdx[index].nSkillID);
			local nSkillName = GetRougepataSkillName(g_RouGe_Skill_PlayerIdx[index].nSkillID);
			--PushDebugMessage("test   nSkillImg="..nSkillImg)
			RouGe_Skill_SkillList[index]:SetProperty( "Image",nSkillImg )
			RouGe_Skill_SkillList[index]:SetToolTip( nTips)
			RouGe_Skill_SkillNameList[index]:SetText(ScriptGlobal_Format("#{RGPT_231130_436}",nSkillName))
		else
			RouGe_Skill_SkillBtn[index]:Hide()
			RouGe_Skill_Namelist[index]:SetCurrentSelect(0)	
			RouGe_Skill_Namelist[index]:Disable()
		end
	end

	if bLeader == 1 then
		RouGe_Skill_Tips:Hide()
		RouGe_Skill_Ok:Show()
		RouGe_Skill_ALLOk:Show()
		RouGe_Skill_ALLReset:Show()
	else
		RouGe_Skill_Tips:Show()
		RouGe_Skill_Ok:Hide()
		RouGe_Skill_ALLOk:Hide()
		RouGe_Skill_ALLReset:Hide()
	end

	--5分钟倒计时
	RouGe_Skill_Time:SetProperty("Timer", tostring(nSkillTime));

	--PushDebugMessage("test   RouGe_Skill= ok")

	this:Show()
end

--================================================
-- 计时
--================================================
function RouGe_Skill_TimeReach()
	this:Hide()
end
--=========================================================
--关闭界面
--=========================================================
function RouGe_Skill_Close()
	this:Hide()
end

--=========================================================
--确认分配
--=========================================================
function RouGe_Skill_OkClicked()
	--按钮状态选择
	local szName1, bPlayerCheck1 = RouGe_Skill_Namelist[1]:GetCurrentSelect();
	local szName2, bPlayerCheck2 = RouGe_Skill_Namelist[2]:GetCurrentSelect();
	local szName3, bPlayerCheck3 = RouGe_Skill_Namelist[3]:GetCurrentSelect();
	local szName4, bPlayerCheck4 = RouGe_Skill_Namelist[4]:GetCurrentSelect();
	local szName5, bPlayerCheck5 = RouGe_Skill_Namelist[5]:GetCurrentSelect();
	local szName6, bPlayerCheck6 = RouGe_Skill_Namelist[6]:GetCurrentSelect();
	
	--PushDebugMessage("test bPlayerCheck1="..bPlayerCheck1.." bPlayerCheck2="..bPlayerCheck2.." bPlayerCheck3="..bPlayerCheck3.." bPlayerCheck4="..bPlayerCheck4.." bPlayerCheck5="..bPlayerCheck5.." bPlayerCheck6="..bPlayerCheck6)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "SkillChoiceConfirm" )
		Set_XSCRIPT_ScriptID( 998947)	
		if bPlayerCheck1 > 0 then
			Set_XSCRIPT_Parameter( 0 ,bPlayerCheck1)
		else
			Set_XSCRIPT_Parameter( 0 ,0)
		end
		if bPlayerCheck2 > 0 then
			Set_XSCRIPT_Parameter( 1 ,bPlayerCheck2)
		else
			Set_XSCRIPT_Parameter( 1 ,0)
		end
		if bPlayerCheck3 > 0 then
			Set_XSCRIPT_Parameter( 2 ,bPlayerCheck3)
		else
			Set_XSCRIPT_Parameter( 2 ,0)
		end
		if bPlayerCheck4 > 0 then
			Set_XSCRIPT_Parameter( 3 ,bPlayerCheck4)
		else
			Set_XSCRIPT_Parameter( 3 ,0)
		end
		if bPlayerCheck5 > 0 then
			Set_XSCRIPT_Parameter( 4 ,bPlayerCheck5)
		else
			Set_XSCRIPT_Parameter( 4 ,0)
		end
		if bPlayerCheck6 > 0 then
			Set_XSCRIPT_Parameter( 5 ,bPlayerCheck6)
		else
			Set_XSCRIPT_Parameter( 5 ,0)
		end
		Set_XSCRIPT_ParamCount( 6 )
	Send_XSCRIPT()
end


--=========================================================
--队员选择
--=========================================================
function RouGe_Skill_Select_Clicked(nIndex)
	if nIndex < 1 or nIndex > 6 then
		return
	end
	
	local szName, nSelectIdx = RouGe_Skill_Namelist[nIndex]:GetCurrentSelect();

	--PushDebugMessage("test btn  nIndex="..nIndex.." nSelectIdx="..nSelectIdx)

	--去服务器问下能不能选
	if nSelectIdx > 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "PlayerSelect" )
			Set_XSCRIPT_ScriptID( 998947)	
			Set_XSCRIPT_Parameter( 0 ,g_RouGe_Skill_PlayerIdx[nIndex].nIndex)
			Set_XSCRIPT_Parameter( 1 ,nSelectIdx)
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "PlayerSelect" )
			Set_XSCRIPT_ScriptID( 998947)	
			Set_XSCRIPT_Parameter( 0 ,g_RouGe_Skill_PlayerIdx[nIndex].nIndex)
			Set_XSCRIPT_Parameter( 1 ,0)
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
	end
	
	RouGe_Skill_Update()
end


--=========================================================
--分配技能失败
--=========================================================
function RouGe_Skill_SelectError(nPlayerIdx)
	for index=1,table.getn(g_RouGe_Skill_PlayerIdx)  do
		if g_RouGe_Skill_PlayerIdx[index].nIndex == nPlayerIdx then
			RouGe_Skill_Namelist[index]:SetCurrentSelect(0)	
		end
	end
	--PushDebugMessage("test RouGe_Skill_SelectError")
	RouGe_Skill_Update()
end


--=========================================================
--动态显示下拉框
--=========================================================
function RouGe_Skill_Update()
	
	
	--按钮状态选择
	local szName1, bPlayerCheck1 = RouGe_Skill_Namelist[1]:GetCurrentSelect();
	local szName2, bPlayerCheck2 = RouGe_Skill_Namelist[2]:GetCurrentSelect();
	local szName3, bPlayerCheck3 = RouGe_Skill_Namelist[3]:GetCurrentSelect();
	local szName4, bPlayerCheck4 = RouGe_Skill_Namelist[4]:GetCurrentSelect();
	local szName5, bPlayerCheck5 = RouGe_Skill_Namelist[5]:GetCurrentSelect();
	local szName6, bPlayerCheck6 = RouGe_Skill_Namelist[6]:GetCurrentSelect();
	--PushDebugMessage("test RouGe_Skill_Update  bPlayerCheck1="..bPlayerCheck1)
	--PushDebugMessage("test RouGe_Skill_Update bPlayerCheck2="..bPlayerCheck2)
	--PushDebugMessage("test RouGe_Skill_Update bPlayerCheck3="..bPlayerCheck3)
	--PushDebugMessage("test RouGe_Skill_Update bPlayerCheck4="..bPlayerCheck4)
	--PushDebugMessage("test RouGe_Skill_Update bPlayerCheck5="..bPlayerCheck5)
	--PushDebugMessage("test RouGe_Skill_Update bPlayerCheck6="..bPlayerCheck6)

	local nTotalNum = table.getn(g_RouGe_Skill_PlayerIdx)
	--PushDebugMessage("test RouGe_Skill_Update nTotalNum="..nTotalNum)
	local nPlayerListSelect = {}
	if nTotalNum >= 1 then
		nPlayerListSelect[1] = bPlayerCheck1
	end
	if nTotalNum >= 2 then
		nPlayerListSelect[2] = bPlayerCheck2
	end
	if nTotalNum >= 3 then
		nPlayerListSelect[3] = bPlayerCheck3
	end
	if nTotalNum >= 4 then
		nPlayerListSelect[4] = bPlayerCheck4
	end
	if nTotalNum >= 5 then
		nPlayerListSelect[5] = bPlayerCheck5
	end
	if nTotalNum >= 6 then
		nPlayerListSelect[6] = bPlayerCheck6
	end
	--local nSelectNum = table.getn(nPlayerListSelect)
	--PushDebugMessage("test RouGe_Skill_Update nSelectNum="..nSelectNum)

	--遍历所有带信息的
	for index=1,table.getn(RouGe_Skill_SkillBtn)  do
		if index <= table.getn(g_RouGe_Skill_PlayerIdx) then
			--都要动态变
			RouGe_Skill_Namelist[index]:ResetList()
			--第一个一定是未选择
			RouGe_Skill_Namelist[index]:AddTextItem("#{RGPT_231130_205}", 0)
			--其他选项都是 去掉已选名字
			local nSelectIndex = 1
			local mCount = 1
			for j=1,table.getn(g_RouGe_Skill_PlayerIdx)  do
				local nAddFlag = 1
				for k=1,table.getn(g_RouGe_Skill_PlayerIdx) do
					if nPlayerListSelect[k] > 0 then
						--PushDebugMessage("test 对比参数 "..g_RouGe_Skill_PlayerIdx[j].nIndex.." 遍历 "..nPlayerListSelect[k].." 不能等于 "..nPlayerListSelect[index])
						if g_RouGe_Skill_PlayerIdx[j].nIndex == nPlayerListSelect[k] and g_RouGe_Skill_PlayerIdx[j].nIndex ~= nPlayerListSelect[index] then
							nAddFlag = 0
						end
					end
				end
				if nAddFlag == 1 then
					if  g_RouGe_Skill_PlayerIdx[j].nPlayerName ~= nil and string.len(g_RouGe_Skill_PlayerIdx[j].nPlayerName) > 0 then	
						local nCurName = g_RouGe_Skill_PlayerIdx[j].nPlayerName.."("..g_menpaiName[g_RouGe_Skill_PlayerIdx[j].nMenpai]..")"
						--PushDebugMessage("test 添加名字 "..nCurName)
						RouGe_Skill_Namelist[index]:AddTextItem(nCurName, g_RouGe_Skill_PlayerIdx[j].nIndex)
						if g_RouGe_Skill_PlayerIdx[j].nIndex == nPlayerListSelect[index] then
							--PushDebugMessage("test nAddFlag mCount="..mCount.." index="..nPlayerListSelect[index])
							nSelectIndex = mCount
						end
						mCount = mCount + 1
					end
				end
				
			end
				
			if nPlayerListSelect[index] > 0 then
				--默认显示之前选的
				--PushDebugMessage("test 第"..index.."个动态显示idx="..nSelectIndex)	
				RouGe_Skill_Namelist[index]:SetCurrentSelect(nSelectIndex)	
			else
				RouGe_Skill_Namelist[index]:SetCurrentSelect(0)	
			end
		end
	end
end

--=========================================================
--一键分配
--=========================================================
function RouGe_Skill_DefaultSkill()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DefaultSkillToPlayer" )
		Set_XSCRIPT_ScriptID( 998947)	
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end

--=========================================================
--一键重置
--=========================================================
function RouGe_Skill_ReOpen()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ReOpenSkillToPlayer" )
		Set_XSCRIPT_ScriptID( 998947)	
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end

--=========================================================
--一键分配刷新
--=========================================================
function RouGe_Skill_Default(bLeader,nPlayer1,nSkill1,nPlayer2,nSkill2,nPlayer3,nSkill3,nPlayer4,nSkill4,nPlayer5,nSkill5,nPlayer6,nSkill6,nSkillTime,nMenpai1,nMenpai2,nMenpai3,nMenpai4,nMenpai5,nMenpai6)
	--PushDebugMessage("test  RouGe_Skill_Open bLeader="..bLeader.." nPlayer1="..tostring(nPlayer1).." nSkill1="..nSkill1.." nPlayer2="..tostring(nPlayer2).." nSkill2="..nSkill2)
	--PushDebugMessage("test  nPlayer3="..tostring(nPlayer3).." nSkill3="..nSkill3.." nPlayer4="..tostring(nPlayer4).." nSkill4="..nSkill4)
	--PushDebugMessage("test  nPlayer5="..tostring(nPlayer5).." nSkill5="..nSkill5.." nPlayer6="..tostring(nPlayer6).." nSkill6="..nSkill6)
	g_RouGe_Skill_PlayerIdx = {}

	local nCount = 0
	if tonumber(nSkill1) > 0 then	
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 1,nPlayerName = tostring(nPlayer1), nSkillID = tonumber(nSkill1),nMenpai =  tonumber(nMenpai1)}
	end

	if tonumber(nSkill2)  > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 2,nPlayerName = tostring(nPlayer2), nSkillID = tonumber(nSkill2),nMenpai =  tonumber(nMenpai2)}
	end
	if tonumber(nSkill3) > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 3,nPlayerName = tostring(nPlayer3), nSkillID = tonumber(nSkill3),nMenpai =  tonumber(nMenpai3)}
	end

	if tonumber(nSkill4) > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 4,nPlayerName = tostring(nPlayer4), nSkillID = tonumber(nSkill4),nMenpai =  tonumber(nMenpai4)}
	end
	if tonumber(nSkill5) > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 5,nPlayerName = tostring(nPlayer5), nSkillID = tonumber(nSkill5),nMenpai =  tonumber(nMenpai5)}
	end
	if tonumber(nSkill6) > 0 then
		nCount = nCount + 1
		g_RouGe_Skill_PlayerIdx[nCount]={nIndex = 6,nPlayerName = tostring(nPlayer6), nSkillID = tonumber(nSkill6),nMenpai =  tonumber(nMenpai6)}
	end
	
	if table.getn(g_RouGe_Skill_PlayerIdx) < 1 then
		--数据异常
		PushDebugMessage("数据异常")
		return
	end

	--显示下拉框 
	--PushDebugMessage("test   listnum="..table.getn(g_RouGe_Skill_PlayerIdx))
	for index=1,table.getn(RouGe_Skill_SkillBtn)  do
		if index <= table.getn(g_RouGe_Skill_PlayerIdx) and g_RouGe_Skill_PlayerIdx[index].nSkillID > 0 then
			RouGe_Skill_SkillBtn[index]:Show()
			if bLeader == 1 then
				RouGe_Skill_Namelist[index]:Enable()
				RouGe_Skill_Namelist[index]:ResetList()
				RouGe_Skill_Namelist[index]:AddTextItem("#{RGPT_231130_205}", 0)
				if  g_RouGe_Skill_PlayerIdx[index].nPlayerName ~= nil and string.len(g_RouGe_Skill_PlayerIdx[index].nPlayerName) > 0 then	
					local nCurName = g_RouGe_Skill_PlayerIdx[index].nPlayerName.."("..g_menpaiName[g_RouGe_Skill_PlayerIdx[index].nMenpai]..")"	
					RouGe_Skill_Namelist[index]:AddTextItem(nCurName, g_RouGe_Skill_PlayerIdx[index].nIndex)
					RouGe_Skill_Namelist[index]:SetCurrentSelect(1)	
				else
					RouGe_Skill_Namelist[index]:SetCurrentSelect(0)
				end
			else
				RouGe_Skill_Namelist[index]:SetCurrentSelect(0)	
				RouGe_Skill_Namelist[index]:Disable()
			end
			
			--展示技能图标
			local nSkillImg =GetRougepataSkillImg(g_RouGe_Skill_PlayerIdx[index].nSkillID)
			local nTips = GetRougepataSkillTips(g_RouGe_Skill_PlayerIdx[index].nSkillID);
			local nSkillName = GetRougepataSkillName(g_RouGe_Skill_PlayerIdx[index].nSkillID);
			--PushDebugMessage("test   nSkillImg="..nSkillImg)
			RouGe_Skill_SkillList[index]:SetProperty( "Image",nSkillImg )
			RouGe_Skill_SkillList[index]:SetToolTip( nTips)
			RouGe_Skill_SkillNameList[index]:SetText(ScriptGlobal_Format("#{RGPT_231130_436}",nSkillName))
		else
			RouGe_Skill_SkillBtn[index]:Hide()
			RouGe_Skill_Namelist[index]:SetCurrentSelect(0)	
			RouGe_Skill_Namelist[index]:Disable()
		end
	end

	if bLeader == 1 then
		RouGe_Skill_Tips:Hide()
		RouGe_Skill_Ok:Show()
		RouGe_Skill_ALLOk:Show()
		RouGe_Skill_ALLReset:Show()
	else
		RouGe_Skill_Tips:Show()
		RouGe_Skill_Ok:Hide()
		RouGe_Skill_ALLOk:Hide()
		RouGe_Skill_ALLReset:Hide()
	end

	--5分钟倒计时
	RouGe_Skill_Time:SetProperty("Timer", tostring(nSkillTime));
end