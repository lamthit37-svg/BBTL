local g_NewFriend_ST_Frame_UnifiedXPosition = 0
local g_NewFriend_ST_Frame_UnifiedYPosition = 0

local g_NewFriend_ST_Init = 0

local g_NewFriend_ST_MasterNULL = 0
local g_NewFriend_ST_PrenticeNULL = 0

local g_NewFriend_ST_GUIDLIST = {}
local g_NewFriend_ST_INDEXLIST = {}

-- 师徒关系优化，我的师门界面增加私聊、添加好友按钮 by lishilong 2016-8-1
-- 师门界面同门姓名
local g_NewFriend_S_CharName = {}
-- 同门对“我”的同门称呼前缀
local g_NewFriend_S_SelfFellowTitlePrefixes = ""
-- 同门对“我”的同门称呼后缀
local g_NewFriend_S_SelfFellowTitleSuffixes = {}

local g_NewFriend_ST_Gongfeng = 0
local g_NewFriend_ST_Gongfenged = 0

function NewFriend_ST_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("SHIMEN_UI")

	this:RegisterEvent("ADJEST_UI_POS",false)

	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("ASK_SHIMENINFO")

end

function NewFriend_ST_OnLoad()

	g_NewFriend_ST_Frame_UnifiedXPosition = NewFriend_ST_Frame:GetProperty("UnifiedXPosition")
	g_NewFriend_ST_Frame_UnifiedYPosition = NewFriend_ST_Frame:GetProperty("UnifiedYPosition")
end

function NewFriend_ST_ResetPos()
	NewFriend_ST_Frame : SetProperty("UnifiedXPosition", g_NewFriend_ST_Frame_UnifiedXPosition);
	NewFriend_ST_Frame : SetProperty("UnifiedYPosition", g_NewFriend_ST_Frame_UnifiedYPosition);
end

function NewFriend_ST_OnEvent(event)
	if( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif( event == "ADJEST_UI_POS" ) then
		NewFriend_ST_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewFriend_ST_ResetPos()
	elseif(event == "UI_COMMAND" ) then	
		if arg0 == "20150528" then
			if Get_XParam_INT(0) == 1 then
				NewFriend_ST_YQ_shitu:SetCheck(1)
				WenDingUI:ClearShiMenInfo(1,0)
				g_NewFriend_ST_MasterNULL = 1
				NewFriend_ST_YQ1:SetCheck(1)
				NewFriend_ST_YQ2:SetCheck(0)
				NewFriend_ST_FrameS:Show();
				NewFriend_ST_ListS:RemoveAllItem()
				NewFriend_ST_FrameT:Hide();
				
				local nIsOnline = GetMasterIsOnline()
				local szName = GetMasterName()
				local nLevel = GetMasterLevel()
				local szGuildName = GetMasterGuildName()
				
				local color = "#c787777"
				if nIsOnline == 1 then
					color = "#cfff263"
				end
				
				if szName~= "" then
					NewFriend_ST_ListS:AddNewItem(color..szName,0,0)
					NewFriend_ST_ListS:AddNewItem(color..tostring(nLevel),1,0)
					NewFriend_ST_ListS:AddNewItem(color.."师父",2,0)
					NewFriend_ST_ListS:AddNewItem(color..szGuildName,3,0)
					NewFriend_ST_ListS:AddNewItem(color.."----",4,0)
					NewFriend_ST_ListS:AddNewItem(color.."----",5,0)
					if nIsOnline == 1 then
						NewFriend_ST_ListS:AddNewItem(color.."在线",6,0)
					else
						NewFriend_ST_ListS:AddNewItem(color.."离线",6,0)
					end				
				end								
			elseif Get_XParam_INT(0) == 2 then
				NewFriend_ST_YQ_shitu:SetCheck(1)
				NewFriend_ST_YQ1:SetCheck(0)
				NewFriend_ST_YQ2:SetCheck(1)
				NewFriend_ST_FrameS:Hide();
				NewFriend_ST_ListT:RemoveAllItem()
				NewFriend_ST_FrameT:Show();
				g_NewFriend_ST_Init = 0
				g_NewFriend_ST_PrenticeNULL = 1
				--徒弟个数信息
				NewFriend_ST_Text:SetText(ScriptGlobal_Format( "#{STGZ_150514_372}",0))
				NewFriend_ST_Text:SetToolTip("#{STGZ_150514_45}")
				--本周师德
				local weekshide = WenDingUI:GetCurShide()
				NewFriend_ST_Text1:SetText(ScriptGlobal_Format( "#{STGZ_150514_456}",weekshide))				
				NewFriend_ST_Text1:SetToolTip("#{STGZ_150514_458}")	
				--历史师德
				local historyshide = WenDingUI:GetHistoryShide()
				NewFriend_ST_Text2:SetText(ScriptGlobal_Format( "#{STGZ_150514_374}",historyshide))
				NewFriend_ST_Text2:SetToolTip(ScriptGlobal_Format( "#{STGZ_150514_47}",historyshide))
				
				NewFriend_ST_Gongfeng:SetToolTip("#{STGZ_150514_179}")
				
				NewFriend_ST_SetDynamic_Pos()
				this:Show();
			elseif Get_XParam_INT(0) == 5 then			
				NewFriend_ST_ListS:RemoveAllItem()
				WenDingUI:ClearShiMenInfo(1,0)	
			elseif Get_XParam_INT(0) == 6 then						
				WenDingUI:ClearShiMenInfo(2,Get_XParam_INT(1))
				NewFriend_ST_ListT:RemoveAllItem()
				NewFriend_ST_OnShowResult(2)
			elseif Get_XParam_INT(0) == 7 then						
				NewFriend_ST_ListS:RemoveAllItem()
				WenDingUI:ClearShiMenInfo(1,0)
				PushEvent("UPDATE_FRIEND");
			end
		end
	elseif(event == "SHIMEN_UI" ) then
		if arg0 == "1" then
			NewFriend_ST_YQ_shitu:SetCheck(1)
			g_NewFriend_ST_MasterNULL = 0
			NewFriend_ST_YQ1:SetCheck(1)
			NewFriend_ST_YQ2:SetCheck(0)
			NewFriend_ST_FrameS:Show();
			NewFriend_ST_ListS:RemoveAllItem()
			NewFriend_ST_FrameT:Hide();
			NewFriend_ST_OnShowResult(1)
		elseif arg0 == "2" then
			AskServerTimeAgain()
			NewFriend_ST_YQ_shitu:SetCheck(1)
			NewFriend_ST_YQ1:SetCheck(0)
			NewFriend_ST_YQ2:SetCheck(1)
			NewFriend_ST_FrameS:Hide();
			NewFriend_ST_ListT:RemoveAllItem()
			NewFriend_ST_FrameT:Show();
			g_NewFriend_ST_Init = 0			
			g_NewFriend_ST_PrenticeNULL = 0
			g_NewFriend_ST_Gongfeng = 0
			g_NewFriend_ST_Gongfenged = 0
			NewFriend_ST_OnShowResult(2)
			NewFriend_ST_SetDynamic_Pos()
			this:Show()
		end
	elseif(event == "ASK_SHIMENINFO" ) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnAskShiMenInfo")
			Set_XSCRIPT_ScriptID(891116)
			Set_XSCRIPT_Parameter(0,3);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end



function NewFriend_ST_OnShowResult(rtype)
	local titles = {"大","二","三","四","五","六","七","八"}
	local myrank = 8
	local strTips = "#{STGZ_150514_173}"
	if rtype == 1 then
		local nListIdx = 0
		g_NewFriend_S_CharName = {}
		g_NewFriend_S_SelfFellowTitlePrefixes = ""
		g_NewFriend_S_SelfFellowTitleSuffixes = {}
		
		for i=0,8 do
			local nGUID,
			szCharName,
			nType,
			nSex,
			nLevel,
			szGuildName,
			nQinmi,
			nGongfeng,
			nStartDay,
			nIsOnline	= WenDingUI:GetShiMenInfoByIdx( i ,rtype)
			
			local color = "#c787777"
			if nIsOnline == 1 then
				color = "#cfff263"
			end
			
			if i == 0 and nType == 1 and szCharName ~= "" then							
				g_NewFriend_S_CharName[nListIdx+1] = szCharName
				g_NewFriend_S_SelfFellowTitleSuffixes[nListIdx+1] = "师父"
				
				NewFriend_ST_ListS:AddNewItem(color..szCharName,0,nListIdx)
				NewFriend_ST_ListS:AddNewItem(color..tostring(nLevel),1,nListIdx)
				NewFriend_ST_ListS:AddNewItem(color.."师父",2,nListIdx)
				NewFriend_ST_ListS:AddNewItem(color..szGuildName,3,nListIdx)
				NewFriend_ST_ListS:AddNewItem(color.."----",4,nListIdx)
				NewFriend_ST_ListS:AddNewItem(color.."----",5,nListIdx)
				if nIsOnline == 1 then
					NewFriend_ST_ListS:AddNewItem(color.."在线",6,nListIdx)
				else
					NewFriend_ST_ListS:AddNewItem(color.."离线",6,nListIdx)
				end
				nListIdx = nListIdx+1
			elseif nType == 2 and szCharName ~= "" then
				g_NewFriend_S_CharName[nListIdx+1] = szCharName
				
				NewFriend_ST_ListS:AddNewItem(color..szCharName,0,nListIdx)
				NewFriend_ST_ListS:AddNewItem(color..tostring(nLevel),1,nListIdx)
				if szCharName == Player:GetName() then
					NewFriend_ST_ListS:AddNewItem(color.."自己",2,nListIdx)
					g_NewFriend_S_SelfFellowTitleSuffixes[nListIdx+1] = "自己"
					myrank = i
					g_NewFriend_S_SelfFellowTitlePrefixes = titles[i]
				else
					local BigstrSuffixes = "师姐"
					local SmallstrSuffixes = "师妹"
					if 1 == Player:GetMySex() then
						BigstrSuffixes = "师兄"
						SmallstrSuffixes = "师弟"
					end 
					
					if nSex == 1 then
						if i > myrank then
							NewFriend_ST_ListS:AddNewItem(color..titles[i].."师弟",2,nListIdx)
							g_NewFriend_S_SelfFellowTitleSuffixes[nListIdx+1] = BigstrSuffixes
						else
							NewFriend_ST_ListS:AddNewItem(color..titles[i].."师兄",2,nListIdx)
							g_NewFriend_S_SelfFellowTitleSuffixes[nListIdx+1] = SmallstrSuffixes
						end
					else
						if i > myrank then
							NewFriend_ST_ListS:AddNewItem(color..titles[i].."师妹",2,nListIdx)
							g_NewFriend_S_SelfFellowTitleSuffixes[nListIdx+1] = BigstrSuffixes
						else
							NewFriend_ST_ListS:AddNewItem(color..titles[i].."师姐",2,nListIdx)
							g_NewFriend_S_SelfFellowTitleSuffixes[nListIdx+1] = SmallstrSuffixes
						end
					end
				end
				NewFriend_ST_ListS:AddNewItem(color..szGuildName,3,nListIdx)
				NewFriend_ST_ListS:AddNewItem(color..tostring(nQinmi),4,nListIdx)
				if nStartDay > 1000 then
					local year = math.floor(nStartDay/10000)
					local month = math.mod(math.floor(nStartDay/100),100)
					local day = math.mod(nStartDay,100)
					NewFriend_ST_ListS:AddNewItem(color..year.."-"..month.."-"..day,5,nListIdx)
				else
					NewFriend_ST_ListS:AddNewItem(color.."----",5,nListIdx)
				end
				if nIsOnline == 1 then
					NewFriend_ST_ListS:AddNewItem(color.."在线",6,nListIdx)
				else
					NewFriend_ST_ListS:AddNewItem(color.."离线",6,nListIdx)
				end				
				nListIdx = nListIdx+1
			end
		end
	else
		local nListIdx = 0
		g_NewFriend_ST_Gongfenged = 0
		g_NewFriend_ST_Gongfeng = 0
		for i=0,8 do
			local nGUID,
			szCharName,
			nType,
			nSex,
			nLevel,
			szGuildName,
			nQinmi,
			nGongfeng,
			nStartDay,
			nIsOnline	= WenDingUI:GetShiMenInfoByIdx( i ,rtype)
			
			local color = "#c787777"
			if nIsOnline == 1 then
				color = "#cfff263"
			end
			
			if nType == 2 and szCharName ~= "" then
				g_NewFriend_ST_GUIDLIST[nListIdx+1] = nGUID
				g_NewFriend_ST_INDEXLIST[nListIdx+1] = i
				NewFriend_ST_ListT:AddNewItem(color..szCharName,0,nListIdx)
				NewFriend_ST_ListT:AddNewItem(color..tostring(nLevel),1,nListIdx)				
				NewFriend_ST_ListT:AddNewItem(color..titles[i].."徒弟",2,nListIdx)
				NewFriend_ST_ListT:AddNewItem(color..szGuildName,3,nListIdx)
				NewFriend_ST_ListT:AddNewItem(color..tostring(nQinmi),4,nListIdx)
				if nStartDay > 1000 then
					local year = math.floor(nStartDay/10000)
					local month = math.mod(math.floor(nStartDay/100),100)
					local day = math.mod(nStartDay,100)
					NewFriend_ST_ListT:AddNewItem(color..year.."-"..month.."-"..day,5,nListIdx)
				else
					NewFriend_ST_ListT:AddNewItem(color.."----",5,nListIdx)
				end
				if nIsOnline == 1 then
					NewFriend_ST_ListT:AddNewItem(color.."在线",6,nListIdx)
				else
					NewFriend_ST_ListT:AddNewItem(color.."离线",6,nListIdx)
				end				
				nListIdx = nListIdx+1
				--供奉相关
				--local ServerDayTime = DataPool:GetServerDayTime()
				--local locYear = math.floor(ServerDayTime/10000)
				--local locMon = math.mod(ServerDayTime,10000)
				--local serYear = math.floor(nGongfeng/100000)
				--local serMonth = math.floor(math.mod(nGongfeng,100000)/10)
				
				--local nGonfengFlag = math.mod(math.mod(nGongfeng,100000),10)
				--if nGonfengFlag == 1 then
				--	g_NewFriend_ST_Gongfenged = g_NewFriend_ST_Gongfenged + 1
				--else
				--	if locYear == serYear and locMon == serMonth then
				--		g_NewFriend_ST_Gongfeng = g_NewFriend_ST_Gongfeng + 1
				--		if g_NewFriend_ST_Gongfeng == 1 then
				--			strTips = "#{STGZ_150514_173}"..szCharName
				--		elseif g_NewFriend_ST_Gongfeng <= 5 then
				--			strTips = strTips.."#{STGZ_150514_174}"..szCharName
				--		end
				--	end
				--end
			end
		end
		--NewFriend_ST_GongFengBtnTips(g_NewFriend_ST_Gongfeng,g_NewFriend_ST_Gongfenged,strTips)
		--徒弟个数信息
		NewFriend_ST_Text:SetText(ScriptGlobal_Format( "#{STGZ_150514_372}",nListIdx))
		NewFriend_ST_Text:SetToolTip("#{STGZ_150514_45}")
		--当前师德
		local weekshide = WenDingUI:GetCurShide()
		NewFriend_ST_Text1:SetText(ScriptGlobal_Format( "#{STGZ_150514_456}",weekshide))
		if nListIdx>0 then
			NewFriend_ST_Text1:SetToolTip(ScriptGlobal_Format( "#{STGZ_150514_457}",weekshide))
		else
			NewFriend_ST_Text1:SetToolTip("#{STGZ_150514_458}")
		end
		--历史师德
		local historyshide = WenDingUI:GetHistoryShide()
		NewFriend_ST_Text2:SetText(ScriptGlobal_Format( "#{STGZ_150514_374}",historyshide))
		NewFriend_ST_Text2:SetToolTip(ScriptGlobal_Format( "#{STGZ_150514_47}",historyshide))
	end
end

function NewFriend_ST_YQClick(clickid)
	if clickid == 1 then
		NewFriend_ST_YQ1:SetCheck(1)
		NewFriend_ST_YQ2:SetCheck(0)
		NewFriend_ST_FrameS:Show();
		NewFriend_ST_ListS:RemoveAllItem()
		NewFriend_ST_FrameT:Hide();
		if g_NewFriend_ST_Init == 0 then
			g_NewFriend_ST_Init = 1
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnAskShiMenInfo")
				Set_XSCRIPT_ScriptID(891116)
				Set_XSCRIPT_Parameter(0,1);
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif g_NewFriend_ST_MasterNULL == 0 then
			NewFriend_ST_OnShowResult(1)
		else
			local nIsOnline = GetMasterIsOnline()
			local szName = GetMasterName()
			local nLevel = GetMasterLevel()
			local szGuildName = GetMasterGuildName()
			
			local color = "#c787777"
			if nIsOnline == 1 then
				color = "#cfff263"
			end
			
			if szName~= "" then
				NewFriend_ST_ListS:AddNewItem(color..szName,0,0)
				NewFriend_ST_ListS:AddNewItem(color..tostring(nLevel),1,0)
				NewFriend_ST_ListS:AddNewItem(color.."师父",2,0)
				NewFriend_ST_ListS:AddNewItem(color..szGuildName,3,0)
				NewFriend_ST_ListS:AddNewItem(color.."----",4,0)
				NewFriend_ST_ListS:AddNewItem(color.."----",5,0)
				if nIsOnline == 1 then
					NewFriend_ST_ListS:AddNewItem(color.."在线",6,0)
				else
					NewFriend_ST_ListS:AddNewItem(color.."离线",6,0)
				end				
			end				
		end
	elseif clickid == 2 then
		NewFriend_ST_YQ1:SetCheck(0)
		NewFriend_ST_YQ2:SetCheck(1)
		NewFriend_ST_FrameS:Hide();
		NewFriend_ST_ListT:RemoveAllItem()
		NewFriend_ST_FrameT:Show();
		if g_NewFriend_ST_PrenticeNULL == 0 then
			NewFriend_ST_OnShowResult(2)
		end
	end
end

function NewFriend_ST_BetrayClick()
	if IsInTServer() == 1 then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnBetrayMaster")
		Set_XSCRIPT_ScriptID(891116)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function NewFriend_ST_ExpelClick()
	if IsInTServer() == 1 then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	local TuDiCount = Player:GetData("PRENTICCOUNT")						--获取徒弟数量
	if TuDiCount == 0 then
		PushDebugMessage("#{STGZ_150514_57}")
		return
	end
	local nSelIndex = NewFriend_ST_ListT:GetSelectItem();
	if nSelIndex == -1 then
		PushDebugMessage("#{STGZ_150514_58}")
		return
	end	
	local delGuid = g_NewFriend_ST_GUIDLIST[nSelIndex+1]
	local delindex = g_NewFriend_ST_INDEXLIST[nSelIndex+1]
	local delGuidH, delGuidL = SplitGUID64( delGuid )
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnExpelPrentice")
		Set_XSCRIPT_ScriptID(891116)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_Parameter(1, delindex)
		Set_XSCRIPT_Parameter(2, delGuidH)
		Set_XSCRIPT_Parameter(3, delGuidL)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function NewFriend_ST_UpgradeClick()
	PushEvent("OPEN_NEWFRIEND_STCZ")
end

function NewFriend_ST_GongFengClick()
	PushEvent("OPEN_NEWFRIEND_GFSF")
	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("GongfengMaster")
	--	Set_XSCRIPT_ScriptID(891121)
	--	Set_XSCRIPT_ParamCount(0)
	--Send_XSCRIPT()
end

function NewFriend_ST_GongFengBtnTips(gongfeng,gongfenged,strTips)
	local strBtnTips = ""
	local TuDiCount = Player:GetData("PRENTICCOUNT")						--获取徒弟数量
	if TuDiCount == 0 then
		strBtnTips = "#{STGZ_150514_179}"
	
	elseif gongfenged == 0 and gongfeng == 0 then
		strBtnTips = "#{STGZ_150514_176}"
	
	elseif gongfenged < 8 and gongfeng == 0 then
		strBtnTips = ScriptGlobal_Format("#{STGZ_150514_178}", tostring(8-gongfenged))
	
	elseif gongfenged == 8 then
		strBtnTips = "#{STGZ_150514_177}"
	
	elseif gongfeng > 0 and gongfeng < 8 then
		strBtnTips = strTips.."#{STGZ_150514_175}"
	end
	
	NewFriend_ST_Gongfeng:SetToolTip(strBtnTips)
end

-- 显示夫妻关系界面
function NewFriend_ST_FMRClick()
	Variable:SetVariable("SelfFriendClanUnionPos", NewFriend_ST_Frame:GetProperty("UnifiedPosition"), 1);
	ZhanTuanInterface:FriendMaritalRelations();
end

--显示结拜界面
function NewFriend_Jiebai_FMRClick()
	Variable:SetVariable("SelfFriendClanUnionPos", NewFriend_ST_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("NEWFRIEND_JIEBAI_OPEN")
end

function NewFriend_ST_SetDynamic_Pos()
	if (IsWindowShow( "Friend_MaritalRelations")) then
		CloseWindow( "Friend_MaritalRelations", true );
	end
	if ( IsWindowShow( "NewFriend_Jiebai" ) ) then
		CloseWindow( "NewFriend_Jiebai", true );
	end
	if ( IsWindowShow( "Friend_Recall" ) ) then
		CloseWindow( "Friend_Recall", true );
	end	
    local selfFriendClanUnionPos = Variable:GetVariable("SelfFriendClanUnionPos")
	if( selfFriendClanUnionPos ~= nil) then
	    NewFriend_ST_Frame:SetProperty("UnifiedPosition", selfFriendClanUnionPos )
	end
end

--领取供奉界面
function NewFriend_ST_MasterGongfeng()
	if IsInTServer() == 1 then
		PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	local TuDiCount = Player:GetData("PRENTICCOUNT")						--获取徒弟数量
	if TuDiCount == 0 then
		PushDebugMessage("#{STGZ_150514_180}")
		return
	end
	--if g_NewFriend_ST_Gongfeng == 0 then
	--	PushDebugMessage("#{STGZ_150514_181}")
	--	return
	--end
	PushEvent("OPEN_NEWFRIEND_GF")
end

--打开关于界面
function NewFriend_ST_OpenInfo(infotype)
	PushEvent("OPEN_SHIDEINFO",infotype)
end

-- 
function NewFriend_ST_OnAddFriend()
	local nSelIndex = NewFriend_ST_ListS:GetSelectItem();
	if nSelIndex == -1 then
		PushDebugMessage("#{STYH_160801_09}")
		return
	end	
	local nRet, strCharName, strSelfFellowTitle = GetSelectedItemInfo(nSelIndex)
	if 0 == nRet then
		PushDebugMessage("非法操作")
		return
	end
	
	-- 选中了自己
	if strCharName == Player:GetName() then
		PushDebugMessage("#{STYH_160801_10}")
		return
	end
	
	-- 是否已经是好友
	if(1 == Friend:IsPlayerIsFriend(strCharName)) then
		PushDebugMessage("#{STYH_160801_11}")
		return
	end
	
	-- 添加好友
	DataPool:AddFriendAndGrouping( strCharName, -1, strSelfFellowTitle )
end

function NewFriend_ST_OnPrivateChat()
	local nSelIndex = NewFriend_ST_ListS:GetSelectItem();
	if nSelIndex == -1 then
		PushDebugMessage("#{STYH_160801_12}")
		return
	end
	local nRet, strCharName, strSelfFellowTitle = GetSelectedItemInfo(nSelIndex)
	if 0 == nRet then
		PushDebugMessage("非法操作")
		return
	end
	
	-- 选中了自己
	if strCharName == Player:GetName() then
		PushDebugMessage("#{STYH_160801_13}")
		return
	end
	
	-- 私聊
	Talk:ContexMenuTalk( strCharName );
end

-- 取出选择的师门界面的同门名字和称号 
-- nIndex从0计数，table从1计数
function GetSelectedItemInfo(nIndex)
	if nIndex < 0 or nIndex >= table.getn(g_NewFriend_S_CharName) 
		or nIndex >= table.getn(g_NewFriend_S_SelfFellowTitleSuffixes) then
		return 0, 0, 0
	end

	local strCharName = g_NewFriend_S_CharName[nIndex+1]
	local strSelfFellowTitle = g_NewFriend_S_SelfFellowTitlePrefixes..g_NewFriend_S_SelfFellowTitleSuffixes[nIndex+1]
	return 1, strCharName, strSelfFellowTitle
end