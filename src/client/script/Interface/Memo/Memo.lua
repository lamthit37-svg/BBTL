
 local g_Flag = 0
local 	g_nContentButton = {}
local 	g_nCurrentPage = 1
local 	g_nSubType = 0
-- 界面的默认相对位置
local g_Memo_Frame_UnifiedXPosition
local g_Memo_Frame_UnifiedYPosition
local g_Memo_CheckBoxTable={}
local g_Memo_pos = 0
-- local g_IDX = 1

-- 键：BeiWangLu.txt 中的 ID
-- 如要增项，则须同步修改 NEIGUA_MEMO_ITEM_NUM 的大小
local g_Mission_keys = {
	[50] = "s", --戍卫帮会
	[54] = "1", --惩凶打图
	[55] = "0", --师门任务
	[56] = "3", --百花缘
	[44] = "4", --清剿九黎余孽
	[118]= "5", --寻影九黎
	[128]= "z", --闲常治务
	[134]= "x", --天下父母心
	[135]= "y", --子女素质（五艺）培养
	[140]= "z", --闲常治务
}
local g_Memo_NeiGuaConfig = {
	["z"] = {"OPEN_CFGWINDOW_CXDT", "XianCh"},--闲常治务设置
	["1"] = {"OPEN_CFGWINDOW_CXDT", "ChengX"} --惩凶打图设置
}
local g_Memo_NeiGuaEnabled = 0 --是否开启自动化功能
local g_Memo_NeiGuaType = "" --g_Mission_keys中的值，正在运行的
local g_Memo_ItemBarIndex_NG = {} --记录自动化相关Item在列表中的位置
local g_Memo_NeiGuaBranchs = {
	tianxfmx	= "x", --天下父母心
	wuyipeiyang	= "y", --子女五艺培养
	xianchangzw = "z",	--闲常治务
	qjjlyn = "4",		--清剿九黎余孽
	xunyjl = "5",		--寻影九黎
	saolei = "s",		--戍卫帮会
	chengx = "1",		--惩凶打图
	shimen = "0",		--师门任务
	baihua = "3"		--百花缘
}

function Memo_PreLoad()

	this:RegisterEvent("SHOW_MEMO")
	
	this:RegisterEvent("SET_MEMO_RET")

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("NEIGUA_SECOND_CONFIRM")
	this:RegisterEvent("ON_NEIGUA_STOP_RUNNING")

	for i, v in pairs(g_Mission_keys) do
		Lua_SetNeiGuaMemoId(i)
	end
end


function Memo_OnLoad()
	
	-- 保存界面的默认相对位置
	g_Memo_Frame_UnifiedXPosition	= Memo_Frame:GetProperty("UnifiedXPosition")
	g_Memo_Frame_UnifiedYPosition	= Memo_Frame:GetProperty("UnifiedYPosition")
	g_Memo_CheckBoxTable[0] = Memo_CheckBox2_Yeqian1
	g_Memo_CheckBoxTable[1] = Memo_CheckBox2_Yeqian2
	g_Memo_CheckBoxTable[2] = Memo_CheckBox2_Yeqian3
	g_Memo_CheckBoxTable[3] = Memo_CheckBox2_Yeqian4
	g_Memo_CheckBoxTable[4] = Memo_CheckBox2_Yeqian5
	g_Memo_CheckBoxTable[5] = Memo_CheckBox2_Yeqian6
	g_Memo_CheckBoxTable[6] = Memo_CheckBox2_Yeqian7
end

-- OnEvent
function Memo_OnEvent(event)

	if ( event == "SHOW_MEMO" ) then
		
		if not this:IsVisible() then
			if g_Flag == 0 then
				g_Flag = 1
				Lua_SendMemoCountMsg()
			else
				if tonumber(arg0) == 4 then
					g_Memo_NeiGuaEnabled = 1
					BattleAssist:AskIsNeiGuaOpen("Memo")
				else
					g_Memo_NeiGuaEnabled = 0
				end
				this:Show()
				if g_Flag == 1 then
					Memo_SwitchPage(1, 0)
				elseif g_Flag == 2 then
					Memo_ShowNeiGuaItem()
				end
				g_Flag = 0
			end
		else
			g_Flag = 0
			this:Hide()
			Memo_TryResetNeiGuaData()
		end
		
	elseif ( event == "SET_MEMO_RET" ) then
		
		if this:IsVisible() then
			
			Memo_ShowPageNew(g_nCurrentPage)

		end
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then

		Memo_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then

		Memo_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
		Memo_TryResetNeiGuaData()

	-- 弹出二次确认界面
	elseif event == "NEIGUA_SECOND_CONFIRM" then
		g_Memo_NeiGuaType = string.char(tonumber(arg0) + string.byte("0"))
		MessageBoxSelf3("Memo_OnNeiGuaComfirmed", {["Content"] = arg1, ["Type"] = "YesNo"})

	-- 内挂结束运行
	elseif event == "ON_NEIGUA_STOP_RUNNING" then
		if not this:IsVisible() then
			if g_Flag == 0 then
				g_Flag = 2
				Lua_SendMemoCountMsg()
			end
		end
	end

end

function Memo_Help()
	Helper:GotoHelper("*Memo")
end

function Memo_Close()
	
	Memo_List1_Frame:CleanAllElement("Memo")
	g_nContentButton = {}
	g_Memo_ItemBarIndex_NG = {}
	g_nSubType = 0
	g_Memo_pos = 0
	-- g_IDX = 1
	this:Hide()

	Memo_TryResetNeiGuaData()
end

function Memo_CheckBox2_Page(subType)
	g_Memo_pos = 0
	Memo_CheckBox2_Check(subType)
end

function Memo_CheckBox2_Check(subType)
	g_nSubType = subType
	Lua_FilterMemoList(g_nCurrentPage, subType)
	Memo_List1_Frame:CleanAllElement("Memo")

	for i=0,6 do
		if i ==  subType then
			g_Memo_CheckBoxTable[i]:SetCheck(1)
		else
			g_Memo_CheckBoxTable[i]:SetCheck(0)
		end
	end

	g_nContentButton = {}
	g_Memo_ItemBarIndex_NG = {}
	local nPageMemoCount = Lua_GetTempMemoCount()
	-- PushDebugMessage("nPageMemoCount:"..tostring(nPageMemoCount))
	for i = 0, nPageMemoCount - 1 do
		local nIsInValid = Lua_EnumTempMemo(  i, "ISINVALID" )
		if nIsInValid ~= 1 then
			local nID = Lua_EnumTempMemo( i, "ID" )
			-- PushDebugMessage("nID:"..tostring(nID))
			-- 活动名
			local strMemo = Lua_EnumTempMemo( i, "Name" )

			--每天活动次数
			local nMemoPlayCount = Lua_EnumTempMemo( i, "PlayNum" )
		
			--最低参加等级
			local nLevel = Lua_EnumTempMemo(  i, "MinLevel" )
			
			--图标
			local strIconString = Lua_EnumTempMemo(  i, "IconString" )
			
			--参与次数
			local strCampaignTimes = Lua_EnumTempMemo(  i, "CampaignTimes" )
			
			local nGotoOpType = Lua_EnumTempMemo( i, "GotoOpType" )
			
			local nDetailOpType = Lua_EnumTempMemo( i, "DetailOpType" )
			
			local nMyCount = Lua_GetMemoCountNum( nID  )
				
			if g_nCurrentPage == 1 then
				local ItemBar = Memo_List1_Frame:AddItemElement( "SuperBarButtonMemo1", "LEFT", "Memo","" ,"")

				if strIconString ~= nil and strIconString ~= "" then
					local sPos,_ = string.find(strIconString," ");
					local IconImageSet = string.sub(strIconString,5,sPos-1);
					local IconIamge = string.sub(strIconString,sPos+7)
					if nil ~= IconImageSet and nil ~= IconIamge then
						ItemBar:SetImage1(IconImageSet,IconIamge)
					end
				end
				
				ItemBar:SetCheckButton1Selected(true)
				ItemBar:SetCheckButton1Tips("#{RCTX_150129_23}")
				
				ItemBar:SetText1( strMemo )
				
				ItemBar:SetText2( tostring(nLevel) )
				
				ItemBar:SetText3( strCampaignTimes )
				if nMemoPlayCount == -1 then
					ItemBar:SetImage2Hide()
					ItemBar:SetText4("-")
				else
					if nMyCount >= nMemoPlayCount then
						ItemBar:SetImage2Show()
					else
						ItemBar:SetImage2Hide()
						ItemBar:SetText4( tostring(nMyCount).."/"..tostring(nMemoPlayCount) )
					end
				end
				
				if g_Memo_NeiGuaEnabled == 0 or not g_Mission_keys[nID] or not g_Memo_NeiGuaConfig[g_Mission_keys[nID]] then
					ItemBar:SetButton2Hide() --隐藏“设置”按钮
				else
					ItemBar:SetButton2Tips("#{BWYH_20240520_4}")
				end

				ItemBar:SetButton1Text("#{RCTX_150129_26}")
				
				if g_Mission_keys[nID] and g_Memo_NeiGuaEnabled > 0 then
					if g_Memo_NeiGuaBranchs[BattleAssist:IsWorking()] == g_Mission_keys[nID] then
						ItemBar:SetButton1Text("#{BWLYH_230215_06}") --正在完成
					else
						ItemBar:SetButton1Text("#{BWLYH_230215_01}") --开始完成
					end
					g_Memo_ItemBarIndex_NG[g_Mission_keys[nID]] = table.getn(g_nContentButton) + 1
				elseif nGotoOpType == 3 then
					ItemBar:SetButton1Text("#{RCTX_150129_31}")
				end
	
				table.insert(g_nContentButton,ItemBar)

			end
			if g_nCurrentPage == 2 then
				local ItemBar = Memo_List1_Frame:AddItemElement( "SuperBarButtonMemo2", "LEFT", "Memo","" ,"")

				if strIconString ~= nil and strIconString ~= "" then
					local sPos,_ = string.find(strIconString," ");
					local IconImageSet = string.sub(strIconString,5,sPos-1);
					local IconIamge = string.sub(strIconString,sPos+7)
						if nil ~= IconImageSet and nil ~= IconIamge then
							ItemBar:SetImage1(IconImageSet,IconIamge)
						end
					end
					
					ItemBar:SetCheckButton1Selected(false)
					ItemBar:SetCheckButton1Tips("#{RCTX_150129_27}")
					
					ItemBar:SetText1( strMemo )
					
					ItemBar:SetText2( tostring(nLevel) )
					
					local myLevel = Player:GetLevel()
					if myLevel < nLevel then
						ItemBar:SetText2( "#cFF0000"..tostring(nLevel) )
					end
					
					ItemBar:SetText3( strCampaignTimes )
					if nMemoPlayCount == -1 then
						ItemBar:SetImage2Hide()
						ItemBar:SetText4("-")
					else
						if nMyCount >= nMemoPlayCount then
							ItemBar:SetImage2Show()
						else
							ItemBar:SetImage2Hide()
							ItemBar:SetText4( tostring(nMyCount).."/"..tostring(nMemoPlayCount) )
						end
					end
		
					ItemBar:SetButton1Text("#{RCTX_150129_09}")
		
					table.insert(g_nContentButton,ItemBar)
			end

		end
	end
	if g_nCurrentPage == 1 and  table.getn(g_nContentButton) == 0 then
		Memo_List_tips:Show()
		Memo_List_tips1:Hide()
	elseif g_nCurrentPage == 2 and  table.getn(g_nContentButton) == 0 then
		Memo_List_tips:Hide()
		Memo_List_tips1:Show()
	else
		Memo_List_tips:Hide()
		Memo_List_tips1:Hide()
	end
	Memo_List1_Frame:Flash()

	Memo_List1_Frame:SetVertScrollbarPosition(g_Memo_pos)

end

function Memo_ShowPageNew(idx)

	if idx == 1 then
	
		Memo_Title2_Frame:Hide()
		Memo_Title1_Frame:Show()
		
		if 1 == g_Memo_NeiGuaEnabled then
			Memo_CheckBox_tips:SetText("#{BWYH_20240520_3}")
		else
			Memo_CheckBox_tips:SetText("#{RCTX_150129_20}")
		end
			
	elseif idx == 2 then
	
		Memo_Title2_Frame:Show()
		Memo_Title1_Frame:Hide()
		
		Memo_CheckBox_tips:SetText("#{RCTX_150129_22}")
			
	end

	-- g_IDX = idx
	Lua_ResetMemoList()
	Memo_CheckBox2_Check(g_nSubType)
end

-- function Memo_ShowPage(idx)
	
-- 	if idx == 1 then
	
-- 		Memo_Title2_Frame:Hide()
-- 		Memo_Title1_Frame:Show()
		
-- 		Memo_CheckBox_tips:SetText("#{RCTX_150129_20}")
			
-- 	elseif idx == 2 then
	
-- 		Memo_Title2_Frame:Show()
-- 		Memo_Title1_Frame:Hide()
		
-- 		Memo_CheckBox_tips:SetText("#{RCTX_150129_22}")
			
-- 	end
	
-- 	Lua_ResetMemoList()
	
-- 	Memo_List1_Frame:CleanAllElement("Memo")
-- 	g_nContentButton = {}
	
-- 	local nPageMemoCount = Lua_GetMemoCount( idx )
	
-- 	for i = 0, nPageMemoCount - 1 do
	
-- 		local nIsInValid = Lua_EnumMemo( idx, i, "ISINVALID" )
-- 		if nIsInValid ~= 1 then
		
-- 			local nID = Lua_EnumMemo( idx, i, "ID" )
			
-- 			-- 活动名
-- 			local strMemo = Lua_EnumMemo( idx, i, "Name" )
			
-- 			--每天活动次数
-- 			local nMemoPlayCount = Lua_EnumMemo( idx, i, "PlayNum" )
			
-- 			--最低参加等级
-- 			local nLevel = Lua_EnumMemo( idx, i, "MinLevel" )
			
-- 			--图标
-- 			local strIconString = Lua_EnumMemo( idx, i, "IconString" )
			
-- 			--参与次数
-- 			local strCampaignTimes = Lua_EnumMemo( idx, i, "CampaignTimes" )
			
-- 			local nGotoOpType = Lua_EnumMemo( idx, i, "GotoOpType" )
			
-- 			local nDetailOpType = Lua_EnumMemo( idx, i, "DetailOpType" )
			
-- 			local nMyCount = Lua_GetMemoCountNum( nID  )
			
-- 			if idx == 1 then
			
-- 				local ItemBar = Memo_List1_Frame:AddItemElement( "SuperBarButtonMemo1", "LEFT", "Memo","" ,"")
-- 			--	ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
				
-- 				if strIconString ~= nil and strIconString ~= "" then
-- 					local sPos,_ = string.find(strIconString," ");
-- 					local IconImageSet = string.sub(strIconString,5,sPos-1);
-- 					local IconIamge = string.sub(strIconString,sPos+7)
-- 					if nil ~= IconImageSet and nil ~= IconIamge then
-- 						ItemBar:SetImage1(IconImageSet,IconIamge)
-- 					end
-- 				end
				
-- 				ItemBar:SetCheckButton1Selected(true)
-- 				ItemBar:SetCheckButton1Tips("#{RCTX_150129_23}")
				
-- 				ItemBar:SetText1( strMemo )
				
-- 				ItemBar:SetText2( tostring(nLevel) )
				
-- 				ItemBar:SetText3( strCampaignTimes )
				
-- 				if nMyCount >= nMemoPlayCount then
-- 					ItemBar:SetImage2Show()
-- 				else
-- 					ItemBar:SetImage2Hide()
-- 					ItemBar:SetText4( tostring(nMyCount).."/"..tostring(nMemoPlayCount) )
-- 				end
				
				
-- 				ItemBar:SetButton1Text("#{RCTX_150129_26}")
				
-- 				if nGotoOpType == 3 then
				
-- 					ItemBar:SetButton1Text("#{RCTX_150129_31}")
-- 				end
	
-- 				table.insert(g_nContentButton,ItemBar)
			
-- 			end
			
			
			
-- 			if idx == 2 then
			
-- 				local ItemBar = Memo_List1_Frame:AddItemElement( "SuperBarButtonMemo2", "LEFT", "Memo","" ,"")
-- 			--	ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
				
-- 				if strIconString ~= nil and strIconString ~= "" then
-- 				local sPos,_ = string.find(strIconString," ");
-- 				local IconImageSet = string.sub(strIconString,5,sPos-1);
-- 				local IconIamge = string.sub(strIconString,sPos+7)
-- 					if nil ~= IconImageSet and nil ~= IconIamge then
-- 						ItemBar:SetImage1(IconImageSet,IconIamge)
-- 					end
-- 				end
				
-- 				ItemBar:SetCheckButton1Selected(false)
-- 				ItemBar:SetCheckButton1Tips("#{RCTX_150129_27}")
				
-- 				ItemBar:SetText1( strMemo )
				
-- 				ItemBar:SetText2( tostring(nLevel) )
				
-- 				local myLevel = Player:GetLevel()
-- 				if myLevel < nLevel then
-- 					ItemBar:SetText2( "#cFF0000"..tostring(nLevel) )
-- 				end
				
-- 				ItemBar:SetText3( strCampaignTimes )
				
-- 				if nMyCount >= nMemoPlayCount then
-- 					ItemBar:SetImage2Show()
-- 				else
-- 					ItemBar:SetImage2Hide()
-- 					ItemBar:SetText4( tostring(nMyCount).."/"..tostring(nMemoPlayCount) )
-- 				end
	
-- 				ItemBar:SetButton1Text("#{RCTX_150129_09}")
	
-- 				table.insert(g_nContentButton,ItemBar)
			
-- 			end	
			
-- 		end	
	
-- 	end
	
-- 	if idx == 1 and  table.getn(g_nContentButton) == 0 then
-- 		Memo_List_tips:Show()
-- 		Memo_List_tips1:Hide()
-- 	elseif idx == 2 and  table.getn(g_nContentButton) == 0 then
-- 		Memo_List_tips:Hide()
-- 		Memo_List_tips1:Show()
-- 	else
-- 		Memo_List_tips:Hide()
-- 		Memo_List_tips1:Hide()
-- 	end
		
-- 	Memo_List1_Frame:Flash()
	
-- end

function Memo_SwitchPage(idx, subId)
	
	if idx ~= 1 and idx ~= 2  then
		return
	end

	if not subId then
		subId = 0
	end
	
	g_nCurrentPage = idx
	g_nSubType = subId
	g_Memo_pos = 0 
	Memo_ShowPageNew(g_nCurrentPage)

end


function Memo_OnItemClick()

	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		
		Memo_SetButtonSelected(nIndex + 1)
		Memo_List1_Frame:Flash()
	end

end

-- 自动化设置
function Memo_OnButton2Click()
	local sPos, ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	-- if nIndex >= 0 then
	-- 	PushDebugMessage(nIndex.." clicked")
	-- end

	for k, v in pairs(g_Memo_ItemBarIndex_NG) do
		if v == nIndex + 1 and g_Memo_NeiGuaConfig[k] then
			local cfg = g_Memo_NeiGuaConfig[k]
			-- PushDebugMessage("PushEvent "..cfg[1]..": "..cfg[2])
			PushEvent(cfg[1], cfg[2])
		end
	end
end

function  Memo_OnButton1Click()

	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		
		if g_nCurrentPage == 1 then
		
			local nID = Lua_EnumTempMemo(  nIndex, "ID" )
			
			local nGotoOpType = Lua_EnumTempMemo(  nIndex, "GotoOpType" )
			local strGotoTip = Lua_EnumTempMemo(  nIndex, "GotoTip" )
			local nXpos , nYpos , nSceneID , strNpcName = Lua_EnumTempMemo(  nIndex, "GotoPos" )

			if g_Mission_keys[nID] and g_Memo_NeiGuaEnabled > 0 then
				if g_Memo_NeiGuaBranchs[BattleAssist:IsWorking()] ~= g_Mission_keys[nID] then
					-- 开始
					Memo_StartNeiGua("Mis", nID, Lua_EnumTempMemo(nIndex, "PlayNum"), Lua_EnumTempMemo(nIndex, "MinLevel"))
				else
					-- 停止
					BattleAssist:Stop()
				end

			elseif 	nGotoOpType == 1 then
			
				PushDebugMessage(tostring(strGotoTip))
			
			elseif nGotoOpType == 2 then
				-- 停止自动化
				BattleAssist:Stop()

				if nID == 4 or nID == 10 or nID == 20 then
					local nCurrentSceneID = GetSceneID()
					if nCurrentSceneID == 0 then
						AutoRunToTargetEx(219,245,0)
						SetAutoRunTargetNPCName("黄云禅")
					
					elseif nCurrentSceneID == 1 then
						AutoRunToTargetEx(200,334,1)
						SetAutoRunTargetNPCName("独孤悔")
						
					else
						AutoRunToTargetEx(206,56,2)
						SetAutoRunTargetNPCName("金忆风")
					
					end
				
				else
					AutoRunToTargetEx(tonumber(nXpos),tonumber(nYpos),tonumber(nSceneID))
					SetAutoRunTargetNPCName(tostring(strNpcName))
					
				end
				
			
			elseif nGotoOpType == 3 then
			
				--打开其他界面
				PushEvent("OPEN_SAFECENTER_SAFESCORE")
			
			end
			
		elseif g_nCurrentPage == 2 then
					
			local nCID = Lua_EnumTempMemo(  nIndex, "CID" )
			
			local strDetailTip = Lua_EnumTempMemo(  nIndex, "DetailTip" )
			
			local nDetailOpType = Lua_EnumTempMemo(  nIndex, "DetailOpType" )
			
			if nDetailOpType == 1 then
			
				PushDebugMessage(tostring(strDetailTip))
				
			elseif nDetailOpType == 2 then
				local StrWeek = Lua_EnumTempMemo(  nIndex, "WEEK" )
				local nNowWeek= Lua_EnumTempMemo(  nIndex, "NOWWEEK" )
				local CIDResult,nCIDSize = SplitStr(nCID,";")  
				
				local CWeekResult,nWeekSize = SplitStr(StrWeek,";")
--				PushDebugMessage("nWeekSize:"..nWeekSize)
				if nCIDSize ~= nWeekSize then
					return;
				end
				--PushDebugMessage("nNowWeek:"..nNowWeek) 
				
				local nWeekIndex = -1;
				if nCIDSize ~= 1 then
					for i = 1,nCIDSize do
						if tonumber(CWeekResult[i]) == tonumber(nNowWeek) then
							nWeekIndex = i;
						end
					end
					if nWeekIndex == -1 then
						return;
					end	
				elseif nCIDSize == 1 then
					nWeekIndex = 1; 
				end
				
				--PushDebugMessage("nWeekIndex:"..nWeekIndex)
				local nCampaignID = tonumber(CIDResult[nWeekIndex]);
				--PushDebugMessage("nCampaignID:"..nCampaignID)
				--OnOpenCampaign(tonumber(nCampaignID))
				PushEvent("OPEN_CAMPAINLISTNEW",nCampaignID )
			elseif nDetailOpType == 3 then

				PushEvent("OPEN_SAFECENTER_SAFESCORE")	
			end
		
		end
	
	end

end

function Memo_OnCheckButton1Click()

	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		
		local nID = Lua_EnumTempMemo(  nIndex, "ID" )
		local nLevel = Lua_EnumTempMemo(  nIndex, "MinLevel" )
		local myLevel = Player:GetLevel()
		
		if myLevel < nLevel then
			
			PushDebugMessage("#{RCTX_150129_15}")
			return
		end

		g_Memo_pos = Memo_List1_Frame:GetVertScrollbarPosition()

		if g_nCurrentPage == 1 then
			
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "SetMemo" )
				Set_XSCRIPT_ScriptID( 880012 )
				Set_XSCRIPT_Parameter( 0, nID )
				Set_XSCRIPT_Parameter( 1, 0 )
				Set_XSCRIPT_ParamCount( 2 )
			Send_XSCRIPT()
			
		elseif g_nCurrentPage == 2 then
					
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "SetMemo" )
				Set_XSCRIPT_ScriptID( 880012 )
				Set_XSCRIPT_Parameter( 0, nID )
				Set_XSCRIPT_Parameter( 1, 1 )
				Set_XSCRIPT_ParamCount( 2 )
			Send_XSCRIPT()
		
		end
	
	end
end


function Memo_SetButtonSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_nContentButton) do

		if nil ~= g_nContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then

				g_nContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else

				g_nContentButton[nButtonIndex]:SetBarButtonSelected(false)
			end
		end
	end
end

function Memo_UpdateItemButtonText(nMemoID)

	for nButtonIndex = 1,table.getn(g_nContentButton) do

		if nil ~= g_nContentButton[nButtonIndex] then
			
			local nID = Lua_EnumTempMemo(  nButtonIndex - 1, "ID" )
			
			if nID == nMemoID then
			
				local bSet  = DataPool:Lua_IsSetMemo(nID)
				if bSet == 1 then
					g_nContentButton[nButtonIndex]:SetButton1Text("#{RCTX_150129_13}")
				else
					g_nContentButton[nButtonIndex]:SetButton1Text("#{RCTX_150129_14}")
				end

			end
		end
	end

end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Memo_Frame_On_ResetPos()

	Memo_Frame : SetProperty("UnifiedXPosition", g_Memo_Frame_UnifiedXPosition);
	Memo_Frame : SetProperty("UnifiedYPosition", g_Memo_Frame_UnifiedYPosition);

end

function FindStr(strOrg, strSeparator, nFindStartIndex)
	for i=nFindStartIndex, string.len(strOrg),1 do
		local j = 1;
		local k = i;
		while ( string.byte(strOrg,k) == string.byte(strSeparator,j)  and k<=string.len(strOrg) and j<=string.len(strSeparator) )do
			k= k+1
			j= j+1
		end
		if j == string.len(strSeparator)+1 then
			return i;
		end
	end
	return nil;
end

function SplitStr(szFullString, szSeparator)
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}

	while true do
		local nFindLastIndex = FindStr(szFullString, szSeparator, nFindStartIndex)

		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
    		break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1

	end

	return nSplitArray,nSplitIndex
end

-- 开启内挂
function Memo_StartNeiGua(msg_key, beiwang_id, max_times, nLevel)

	if Player:GetLevel() < nLevel then
		PushDebugMessage("#{BWLYH_230215_02}") --角色等级不足，请提升等级。
		return
	end

	if type(max_times) == "number" and max_times > 0 then
		local my_times = Lua_GetMemoCountNum(beiwang_id) --set by GCRetCampaignCountHandler::Execute
		if max_times <= my_times then
			PushDebugMessage("#{BWLYH_230215_03}") --完成次数已达上限，无法完成。
			return
		end
	end

	if g_Mission_keys[beiwang_id] then
		BattleAssist:Start(msg_key, g_Mission_keys[beiwang_id])
		g_Memo_NeiGuaType = g_Mission_keys[beiwang_id] --此时还未真正开始运行
	end
	
end

-- 根据内挂当前运行的分支，重置数据
-- 不能在Memo_OnNeiGuaComfirmed、Memo_ShowNeiGuaItem之前使用
function Memo_TryResetNeiGuaData()
	local isNGRun = IsNGRunning()
	if isNGRun then
		if isNGRun == 0 then
			g_Memo_NeiGuaType = ""
		else
			local ngBranch = BattleAssist:IsWorking()
			if g_Memo_NeiGuaBranchs[ngBranch] and g_Memo_NeiGuaType ~= g_Memo_NeiGuaBranchs[ngBranch] then
				g_Memo_NeiGuaType = g_Memo_NeiGuaBranchs[ngBranch]
			end 
		end
	end
end

-- 二次确认回调函数 by 内挂
function Memo_OnNeiGuaComfirmed(str)
	if str and ("Yes" == str or "Ok" == str) then
		BattleAssist:Start("MisSec", g_Memo_NeiGuaType)
	else
		Memo_TryResetNeiGuaData()
	end
end

-- 定位到具体的行 by 内挂
function Memo_ShowNeiGuaItem()
	local n = 0
	local beiWangId = -1
	for i, v in pairs(g_Mission_keys) do
		if v == g_Memo_NeiGuaType then
			beiWangId = i
			-- Lua_TDU_Log("beiwangId = "..beiWangId)
			break
		end
	end
	if beiWangId ~= -1 then
		local page = Lua_EnumMemo(10, beiWangId, "sub_type")
		-- Lua_TDU_Log("page = "..page)
		if page and page >= 0 then
			Memo_SwitchPage(1, page)
			local nPageMemoCount = Lua_GetTempMemoCount()
			for i = 0, nPageMemoCount - 1 do
				local nIsInValid = Lua_EnumTempMemo(  i, "ISINVALID" )
				if nIsInValid ~= 1 then
					local nID = Lua_EnumTempMemo( i, "ID" )
					if nID == beiWangId then
						n = i
						-- Lua_TDU_Log("n = "..n)
						break
					end
				end
			end
			g_Memo_pos = 42 * n
			-- Lua_TDU_Log("g_Memo_pos = "..g_Memo_pos)
			Memo_List1_Frame:SetVertScrollbarPosition(g_Memo_pos)
		end
	end
	
	Memo_TryResetNeiGuaData()
end

-- 刷新按钮
function Memo_UpdateTextOnButton(ng_running)
	-- PushDebugMessage("UpdateTextOnButton: "..ng_running)
	for k, v in pairs(g_Memo_ItemBarIndex_NG) do
		-- Lua_TDU_Log(k.." = "..v)
		if g_nContentButton[v] then
			if k == g_Memo_NeiGuaBranchs[ng_running] then
				g_nContentButton[v]:SetButton1Text("#{BWLYH_230215_06}") --正在完成
			else
				g_nContentButton[v]:SetButton1Text("#{BWLYH_230215_01}") --开始完成
			end
		end
	end
end
