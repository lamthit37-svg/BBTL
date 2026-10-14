-- 界面的默认相对位置
local g_SweepAll_Frame_UnifiedXPosition;
local g_SweepAll_Frame_UnifiedYPosition;

local g_nContentButton = {}

--按照扫荡等级进行排序
local g_SweepAll_Index = {}

local g_SweepAll_DoubleStartTime = 20251011
local g_SweepAll_DoubleEndTime   = 20251019

local g_SweepAll_GaoXiaofbid = 0
local g_SweepAll_GaoXiao_idx = {1,2,4,7,9}
local g_SweepAll_GaoXiao_tips = {"#{GXB_220725_21}","#{GXB_220725_15}","#{GXB_220725_18}","#{GXB_220725_19}","#{GXB_220725_20}"}

local g_SweepAll_Ctlidx_Tblidx = {}
--活动扫荡
local g_SweepAll_LastWeekCostYuanBao = 1200
function SweepAll_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	this:RegisterEvent("SHOW_SECKILL_LIST")
	this:RegisterEvent("OPEN_SECKILL_LIST")

	this:RegisterEvent("UI_COMMAND")
end

function SweepAll_OnLoad()
	g_SweepAll_Frame_UnifiedXPosition	= SweepAll_Frame : GetProperty("UnifiedXPosition");
	g_SweepAll_Frame_UnifiedYPosition	= SweepAll_Frame : GetProperty("UnifiedYPosition");
end

-- OnEvent
function SweepAll_OnEvent(event)
	if (event == "OPEN_SECKILL_LIST" ) then
		if not this:IsVisible() then
			SendSecKillDataMsg()
		end

	elseif(event == "SHOW_SECKILL_LIST" ) then
		if not this:IsVisible() then
			InitSecKillHuoDong()
			this:Show()
			SweepAll_Tab_1_OnClick()
		end

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		SweepAll_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		SweepAll_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		SweepAll_OnClosed()

	elseif event == "UI_COMMAND" and tonumber(arg0) == 20260115 then
		if SweepAll_Tab_2:GetCheck() == 1 and SweepAll_Tab_1:GetCheck() == 0 then
			SweepAll_Tab_2_OnClick()	
		end
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SweepAll_Frame_On_ResetPos()
	SweepAll_Frame : SetProperty("UnifiedXPosition", g_SweepAll_Frame_UnifiedXPosition);
	SweepAll_Frame : SetProperty("UnifiedYPosition", g_SweepAll_Frame_UnifiedYPosition);
end

--=================================================
--打开扫荡界面
--==================================================
function SweepAll_On_Open()
	local isInSecKill,fubenIndexId,BossIndex,DoubleExp = GetSecKillData()
	local SecKillFubenCount = GetSecKillFuBenCount()

	SweepAll_List:CleanAllElement("SweepAll")
	g_nContentButton = {}
	
	if Player:GetData("Is2606S") == 1 then
		SweepAll_Explain:SetText("#{QXFSG_260622_11}")	
	else
		SweepAll_Explain:SetText("#{FBSD_150126_11}")	
	end

	local ctlidx = 0
	for i = 0, SecKillFubenCount - 1 do
		local Id, IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillNeedNumType,SecKillNeedNum,CanDoubleExp, numYuanbao, ActionID, fubenIndexID, gaoxiaofbid,Is2606sHide = EnumSecKillTable(i)
		if Is2606sHide == 1 and Player:GetData("Is2606S") == 1 then
			continue;
		end
		g_SweepAll_Ctlidx_Tblidx[ctlidx] = i
		ctlidx = ctlidx + 1
		SweepAll_Currency_Text1:SetText(ScriptGlobal_Format("#{SDXG_20210624_15}", HightSecKillNum))
		SweepAll_Currency_Text2:SetText(ScriptGlobal_Format("#{SDXG_20210624_26}", LowSecKillNum))
		
		local ItemBar = SweepAll_List:AddItemElement( "SweepButton", "LEFT", "SweepAll","" ,"")
		ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")

		--set:hdrc_02 image:hdrc_02_chuju
		if IconName ~= nil and IconName ~= "" then
			local sPos,_ = string.find(IconName," ");
			local IconImageSet = string.sub(IconName,5,sPos-1);
			local IconIamge = string.sub(IconName,sPos+7)
			if nil ~= IconImageSet and nil ~= IconIamge then
				ItemBar:SetImage1(IconImageSet,IconIamge)
				ItemBar:SetImage1Show()
			end
		end

		ItemBar:SetImage2Hide()

		ItemBar:SetText1( "#G"..FubenName )
		ItemBar:SetText2( "#G"..needLevel )

		ItemBar:SetImage2Hide()
		
		if fubenIndexID == gaoxiaofbid then
			ItemBar:SetImage3Show() 
			SweepAll_Currency_Text3:SetText(ScriptGlobal_Format("#{GXB_220725_09}",FubenName)) 
		end

		if gaoxiaofbid > 0 then
			if Player:GetData("Is2606S") == 1 then
				SweepAll_Explain:SetText("#{QXFSG_260622_20}")	
			else
				SweepAll_Explain:SetText("#{GXB_220725_08}")	
			end
			g_SweepAll_GaoXiaofbid = gaoxiaofbid
			local tblidx = 0
			for i = 1, table.getn(g_SweepAll_GaoXiao_idx) do
				if(1 == DataPool:GetPlayerMission_DataBinary(1525,g_SweepAll_GaoXiao_idx[i])) then
					tblidx = i
				end
				if(1 == DataPool:GetPlayerMission_DataBinary(1546,g_SweepAll_GaoXiao_idx[i])) then
					tblidx = i
			   	end 
			end	
			if tblidx > 0  then
				SweepAll_Currency_Text3:SetToolTip(g_SweepAll_GaoXiao_tips[tblidx])	
			else
				SweepAll_Currency_Text3:SetToolTip("")	
			end
		else
			if Player:GetData("Is2606S") == 1 then
				SweepAll_Explain:SetText("#{QXFSG_260622_11}")	
			else
				SweepAll_Explain:SetText("#{FBSD_150126_11}")	
			end
			SweepAll_Currency_Text3:SetText("")		
			SweepAll_Currency_Text3:SetToolTip("")	

		end
		if SecKillNeedNumType == 2 then
			-- ItemBar:SetImage3("GuiShi_Clue_1","ClueType5")
			-- ItemBar:SetImage3Show()
			local str = ScriptGlobal_Format("#{SDXG_20210624_28}", SecKillNeedNum)
			if HightSecKillNum < SecKillNeedNum then
				ItemBar:SetText3( "#cff0000"..str)
			else
				ItemBar:SetText3( "#G"..str)
			end
		else
			-- ItemBar:SetImage3("GuiShi_Clue_1","ClueType1")
			-- ItemBar:SetImage3Show()
			local str = ScriptGlobal_Format("#{SDXG_20210624_27}", SecKillNeedNum)
			if LowSecKillNum < SecKillNeedNum then
				ItemBar:SetText3( "#cff0000"..str )
			else
				ItemBar:SetText3( "#G"..str)
			end
		end

		local Number = GetCampaignTotalNum(ActionID)
		local Micount = Number - GetCampaignCountNum( ActionID )

		if Micount == 0 then
			ItemBar:SetText4( "#cff0000"..tostring(Micount).."/"..tostring(Number) )
		else
			ItemBar:SetText4( "#G"..tostring(Micount).."/"..tostring(Number) )
		end

		ItemBar:SetText5("")
		ItemBar:SetCheckButton1Hide()

		ItemBar:SetButton1Show()
		ItemBar:SetButton1Text("#{FBSD_150126_66}")
		ItemBar:SetButton1Tips("#{FBSD_150126_19}")
	--	if Micount == 0 then
	--		ItemBar:SetButton1State(false)
	--	end

		table.insert(g_nContentButton,ItemBar);
	end

	local Index = Lua_SecKillGetIndexFromFuBenIndexID(fubenIndexId)

	if isInSecKill == 1 and Index ~= -1 and Index < table.getn(g_nContentButton) then
	--	g_nContentButton[Index+1]:SetButton1State(true)
		if DoubleExp == 1 then
			g_nContentButton[Index+1]:SetButton1Text("#{FBSD_150126_68}")
			g_nContentButton[Index+1]:SetButton1Tips("#{FBSD_150126_21}")
		elseif DoubleExp == 2 then
			g_nContentButton[Index+1]:SetButton1Text("#{FBSD_220704_09}")
			g_nContentButton[Index+1]:SetButton1Tips("#{FBSD_220704_10}")
		else
			g_nContentButton[Index+1]:SetButton1Text("#{FBSD_150126_67}")
			g_nContentButton[Index+1]:SetButton1Tips("#{FBSD_150126_20}")
		end

		local IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillNeedNumType,SecKillNeedNum,CanDoubleExp = Lua_GetSecKillInfoByFuBenIndexID(fubenIndexId)
		local strTemp
		if SweepAll_CheckHuoDongTime() > 0 then
			strTemp = ScriptGlobal_Format("#{FBSD_200805_03}",FubenName)
		else
			strTemp = ScriptGlobal_Format("#{FBSD_150126_73}",FubenName)
		end

		SweepAll_Explain1:SetText(strTemp)
	else
		if SweepAll_CheckHuoDongTime() > 0 then
			SweepAll_Explain1:SetText("#{FBSD_200805_02}")
		else
			SweepAll_Explain1:SetText("#{FBSD_150126_72}")
		end
	end

	SweepAll_List:Flash()
end

--点击扫荡按钮
function SweepAll_OnButtonClick()
	
	
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	local tblid = g_SweepAll_Ctlidx_Tblidx[nIndex] 
	local fubenIndexID = Lua_SecKillGetFuBenIndexID_New(tblid)
	if fubenIndexId ~= -1 then
		OpenSecKillPage(fubenIndexID)
	end
	
end
function SweepAll_OnCheckClick_HuoDong(nIndex)

	local Id, IconName,FubenName,_,needLevel,nSeckillNum1,nSeckillNum2,nSeckillNum3,xinfalevel,SecKillNeedNum,BossNum,_,_,_,_,ScriptID,ActionID,ActionID_Kaji = EnumSecKillTable_HuoDong(nIndex)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnFuBenSecKill");
		Set_XSCRIPT_ScriptID(100003);
		Set_XSCRIPT_Parameter(0,Id);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();

end

function SweepAll_OnCheckClick()
end

function SweepAll_OnClosed()
	this:Hide();
end

function SweepAll_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		SweepAll_SetButtonSelected(nIndex + 1)
		SweepAll_List:Flash()
	end
end

function SweepAll_SetButtonSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_nContentButton) do
		if nil ~= g_nContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

function SweepAll_CheckHuoDongTime()
	--检查是否活动时间
	local myDayTime = tonumber(GetTime2Day())
	if (myDayTime < g_SweepAll_DoubleStartTime or myDayTime > g_SweepAll_DoubleEndTime) then
		return 0
	end

	return 1
end

function SweepAll_ExplainHelp_Clicked()
	
end


function SweepAll_ExplainHelp_Clicked_SeckillHuoDong()
	if SweepAll_Tab_2:GetCheck() == 0 and SweepAll_Tab_1:GetCheck() == 1 then
		PushEvent("OPEN_SWEEPPAGE_QUEST", "SweepAll_ExplainHelp", g_SweepAll_GaoXiaofbid) 
	elseif SweepAll_Tab_2:GetCheck() == 1 and SweepAll_Tab_1:GetCheck() == 0 then
		PushEvent("OPEN_SWEEPPAGE_QUEST", "SweepAll_ExplainHelp_HuoDongSecKill") 
	end
end



function SweepAll_GetPlayNum()
	local nCampaignCount = EnumNewCampaign( campaignlistnum, i, "PlayNum" )  
end

function SweepAll_Tab_1_OnClick()
	SweepAll_Tab_1:SetCheck(1)
	SweepAll_Tab_2:SetCheck(0)
	SweepAll_Currency_Text4:Hide()
	SweepAll_Currency_Text2:Show()
	SweepAll_Currency_Text3:Show()
	SweepAll_Currency_Text5:Hide()
	SweepAll_Currency_Text1:Show()
	
	SweepAll_List:Show()
	SweepAll_List2:Hide()
	
	SweepAll_Title_Frame:Show()
	SweepAll_Title2_Frame:Hide()

	SweepAll_Currency_Text5:SetToolTip("")	

	SweepAll_Tab_1:SetText("#{SDJF_260113_06}")
	SweepAll_Tab_2:SetText("#{SDJF_260113_07}")

	SweepAll_Explain1:Show()
	SweepAll_Title_activity:SetText("#{FBSD_150126_12}")
	SweepAll_Title_activity:SetToolTip("#{SDJF_260113_27}")

	SweepAll_Title_level:SetText("#{FBSD_150126_13}")
	SweepAll_Title_level:SetToolTip("#{FBSD_150126_76}")

	SweepAll_Title_point:SetText("#{SDXG_20210624_12}")
	SweepAll_Title_point:SetToolTip("#{FBSD_201119_06}")

	SweepAll_Title_times:SetText("#{FBSD_150126_16}")
	SweepAll_Title_times:SetToolTip("#{FBSD_150126_79}")

	SweepAll_Title_sweep:SetText("#{FBSD_150126_17}")
	SweepAll_Title_sweep:SetToolTip("#{FBSD_150126_80}")
	SweepAll_On_Open()
end

function SweepAll_Tab_2_OnClick()
	
	SweepAll_Tab_1:SetCheck(0)
	SweepAll_Tab_2:SetCheck(1)
	SweepAll_Currency_Text4:Show()
	SweepAll_Currency_Text2:Hide()
	SweepAll_Currency_Text3:Hide()
	SweepAll_Currency_Text5:Show()
	SweepAll_Currency_Text1:Hide()


	SweepAll_Title_Frame:Hide()
	SweepAll_Title2_Frame:Show()

	SweepAll_Tab_1:SetText("#{SDJF_260113_06}")
	SweepAll_Tab_2:SetText("#{SDJF_260113_07}")
	SweepAll_Explain1:Hide()
	SweepAll_Title2_activity:SetText("#{SDJF_260113_09}")
	SweepAll_Title2_activity:SetToolTip("#{SDJF_260113_16}")

	SweepAll_Title2_level:SetText("#{SDJF_260113_10}")
	SweepAll_Title2_level:SetToolTip("#{SDJF_260113_17}")

	SweepAll_Title2_point:SetText("#{SDJF_260113_12}")
	SweepAll_Title2_point:SetToolTip("#{SDJF_260113_19}")

	SweepAll_Title2_times:SetText("#{SDJF_260113_13}")
	SweepAll_Title2_times:SetToolTip("#{SDJF_260113_20}")

	SweepAll_Title2_HavePoint:SetText("#{SDJF_260113_11}")
	if Player:GetData("Is2606S") == 1 then
		SweepAll_Title2_HavePoint:SetToolTip("#{QXF_260623_111}")
	else
		SweepAll_Title2_HavePoint:SetToolTip("#{SDJF_260113_18}")
	end 
	SweepAll_Title2_sweep:SetText("#{SDJF_260113_14}")
	SweepAll_Title2_sweep:SetToolTip("#{SDJF_260113_21}")

	SweepAll_Currency_Text5:SetToolTip("#{SDJF_260113_27}")	

	SweepAll_List:Hide()
	SweepAll_List2:Show()

	local nCheckQuanXian = 0
	local uRMBAction_ExDay ,uCostYuanBao_ExDay , uUseItem_ExDay = LuaGetQuanXianDay_SecKillHuoDong()
	if uRMBAction_ExDay > 0 or uCostYuanBao_ExDay > 0 or uUseItem_ExDay > 0 then
		local month = 0
		local day = 0 
		if uRMBAction_ExDay > uCostYuanBao_ExDay and uRMBAction_ExDay > uUseItem_ExDay then
			month = math.floor( math.mod(uRMBAction_ExDay , 10000) / 100 )
			day =  math.mod(uRMBAction_ExDay , 100)

		elseif uCostYuanBao_ExDay > uRMBAction_ExDay and uCostYuanBao_ExDay > uUseItem_ExDay then
			month = math.floor(  math.mod(uCostYuanBao_ExDay , 10000) / 100 )
			day =  math.mod(uCostYuanBao_ExDay , 100)
		elseif uUseItem_ExDay > uRMBAction_ExDay and uUseItem_ExDay > uCostYuanBao_ExDay then
			month = math.floor(  math.mod(uUseItem_ExDay , 10000) / 100 )
			day =  math.mod(uUseItem_ExDay , 100)
		end

		SweepAll_Currency_Text5:SetText(ScriptGlobal_Format("#{SDJF_260113_25}", month,day))	
	else
		SweepAll_Currency_Text5:SetText("#{SDJF_260113_26}")	
	end

	SweepAll_Currency_Text5:SetToolTip("#{SDJF_260113_27}")

	local curweekyuanbao_tips = "#{SDJF_260113_24}"

	local nLastWeekYuanBao = Lua_GetMissionData(3275)
	local ncurWeekYuanBao = Lua_GetMissionData(3276)

	if nLastWeekYuanBao >= g_SweepAll_LastWeekCostYuanBao then
		SweepAll_Currency_Text4:SetText("#{SDJF_260113_22}")
	else
		SweepAll_Currency_Text4:SetText(ScriptGlobal_Format("#{SDJF_260113_23}", nLastWeekYuanBao))
	end

	if ncurWeekYuanBao >= g_SweepAll_LastWeekCostYuanBao then
		curweekyuanbao_tips = curweekyuanbao_tips .. "#{SDJF_260113_67}"
	else
		local str = ScriptGlobal_Format("#{SDJF_260113_66}", ncurWeekYuanBao)
		curweekyuanbao_tips = curweekyuanbao_tips .. str		
	end

	SweepAll_Currency_Text4:SetToolTip(curweekyuanbao_tips)

	SweepAll_List2:CleanAllElement("SweepAll")
	g_nContentButton = {}
	local SecKillFubenCount_HuoDong = Lua_GetSecKillFuBenCount_HuoDong()
	for i = 0, SecKillFubenCount_HuoDong - 1 do
		local Id, IconName,FubenName,IsOpenKaji,needLevel,nSeckillNum1,nSeckillNum2,nSeckillNum3,xinfalevel,SecKillNeedNum,BossNum,_,_,_,_,ScriptID,ActionID,ActionID_Kaji,ActionID_QX = EnumSecKillTable_HuoDong(i)
		
		local ItemBar = SweepAll_List2:AddItemElement( "SweepButton2", "LEFT", "SweepAll","" ,"")
		ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")

		--set:hdrc_02 image:hdrc_02_chuju
		if IconName ~= nil and IconName ~= "" then
			local sPos,_ = string.find(IconName," ");
			local IconImageSet = string.sub(IconName,5,sPos-1);
			local IconIamge = string.sub(IconName,sPos+7)
			if nil ~= IconImageSet and nil ~= IconIamge then
				ItemBar:SetImage1(IconImageSet,IconIamge)
				ItemBar:SetImage1Show()
			end
		end

		ItemBar:SetImage2Hide()

		ItemBar:SetText1( "#G"..FubenName )
		ItemBar:SetText2( "#G"..needLevel )

		local nYYDS = Lua_GetMissionData(3387)
		if Id == 1 or Id == 2 then
			nYYDS = Lua_GetMissionData(3387)
		elseif Id == 3 or Id == 4 then
			nYYDS = Lua_GetMissionData(3388)
		elseif Id == 5 or Id == 6 then
			nYYDS = Lua_GetMissionData(3389)
		end

		local max_SeckillPoint = Lua_GetMaxSeckillPointByFubenID(i)

		ItemBar:SetText5( "#G"..nYYDS .. "/" ..max_SeckillPoint )
		ItemBar:SetImage2Hide()
		if Player:GetData("Is2606S") == 1 then
			SweepAll_Explain:SetText("#{QXF_260623_110}")	
		else
			SweepAll_Explain:SetText("#{SDJF_260113_08}")	
		end

		-- ItemBar:SetImage3("GuiShi_Clue_1","ClueType1")
		-- ItemBar:SetImage3Show()
		--local str = ScriptGlobal_Format("#{SDXG_20210624_27}", SecKillNeedNum)

		
		local str = SecKillNeedNum
		ItemBar:SetText3( "#G"..str )
		if Id == 1 or Id ==2 then
			if nSeckillNum1 < SecKillNeedNum then
				ItemBar:SetText3( "#cff0000"..str )
			else
				ItemBar:SetText3( "#G"..str)
			end
		elseif Id == 3 or Id == 4 then
			if nSeckillNum2 < SecKillNeedNum then
				ItemBar:SetText3( "#cff0000"..str )
			else
				ItemBar:SetText3( "#G"..str)
			end		
		elseif Id == 5 or Id == 6 then
			if nSeckillNum3 < SecKillNeedNum then
				ItemBar:SetText3( "#cff0000"..str )
			else
				ItemBar:SetText3( "#G"..str)
			end			
		end



		local Number = 0
		local Micount = 0
		local Micount,Number = LuaGetSeckillCampaignTableNew_HuoDong(ActionID_Kaji)

		if Player:GetData("Is2606S") == 1 then
			Micount,Number = LuaGetSeckillCampaignTableNew_HuoDong(ActionID_QX)
		end

		
		-- if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(175) > 0 and IsOpenKaji > 0 then  --卡级
		-- 	local Number,Micount = LuaGetSeckillCampaignTableNew_HuoDong(ActionID_Kaji)
		-- else
		-- 	Number = GetCampaignTotalNum(ActionID)
		-- 	Micount = Number - GetCampaignCountNum( ActionID )			
		-- end

		local lefttimes = Number - Micount
		if lefttimes == 0 then
			ItemBar:SetText4( "#cff0000"..tostring(lefttimes).."/"..tostring(Number) )
		else
			ItemBar:SetText4( "#G"..tostring(lefttimes).."/"..tostring(Number) )
		end

		if Number == 0 then
			ItemBar:SetText4("")
		end

		--ItemBar:SetText5("")
		ItemBar:SetCheckButton1Hide()

		ItemBar:SetButton1Show()
		ItemBar:SetButton1Text("#{FBSD_150126_66}")
		ItemBar:SetButton1Tips("#{FBSD_150126_19}")
	--	if Micount == 0 then
	--		ItemBar:SetButton1State(false)
	--	end

		table.insert(g_nContentButton,ItemBar);
	end

	--这里需要新的字典
	if SweepAll_CheckHuoDongTime() > 0 then
		SweepAll_Explain1:SetText("#{FBSD_200805_02}")
	else
		SweepAll_Explain1:SetText("#{FBSD_150126_72}")
	end

	SweepAll_List2:Flash()

end

function SweepAll_2_OnButtonClick()

	
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))


	SweepAll_OnCheckClick_HuoDong(nIndex)
	
end

function SweepAll_2_OnItemClick(  )
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		SweepAll_SetButtonSelected(nIndex + 1)
		SweepAll_List:Flash()
	end
end