-- 新比武大会2018排行榜

local g_nCurSel_MatchID = -1
local g_myMatchId = -1
local g_nCurSel_MatchBtn ={}
local g_nMyInfo = {}
local g_nObjID = -1 --关心obj 咋不关心下我呢= =
local g_isGetAward = -1
local g_myLevel = -1
local g_RankType = -1
local g_NewMatchLevelName={
[0]="#{BWPH_210908_01}", --鹤鸣
[1]="#{BWPH_180815_15}", --侠士
[2]="#{BWPH_180815_16}", --豪侠
}
local g_Image = {
						[1] = "set:Ach1 image:WDTXPMBtn_1_Normal",
						[2] = "set:Ach1 image:WDTXPMBtn_2_Normal",
						[3] = "set:Ach1 image:WDTXPMBtn_3_Normal",
					
}
local g_DuanWei1 = {
	[1] = "#{BWDH_180804_131}",
	[2] = "#{BWDH_180804_132}",
	[3] = "#{BWDH_180804_133}",
	[4] = "#{BWDH_180804_134}",
	[5] = "#{BWDH_180804_135}",
	[6] = "#{BWDH_180804_136}",
}
local g_DuanWei2 = {
	[1] = "#{BWDH_180804_141}",
	[2] = "#{BWDH_180804_140}",
	[3] = "#{BWDH_180804_139}",
	[4] = "#{BWDH_180804_138}",
	[5] = "#{BWDH_180804_137}",
}
local g_DuanWei3 = {
	[1] = "#{BWDH_180804_141}",
	[2] = "#{BWDH_180804_140}",
	[3] = "#{BWDH_180804_139}",
	[4] = "#{BWDH_180804_138}",
	[5] = "#{BWDH_180804_137}",
}
local g_RankList_nContentButton = {}
local g_MenPaiNameList =
{
	-- [0]  ={Name="#{SCGZ_180816_30}" , Color="#cff6600", }, --shaolin
	-- [1]  ={Name="#{SCGZ_180816_31}" , Color="#c0000ff", }, --wudang
	-- [2]  ={Name="#{SCGZ_180816_32}" , Color="#c007700", }, --xingxiu
	-- [3]  ={Name="#{SCGZ_180816_33}" , Color="#cff99cc", }, --emei
	-- [4]  ={Name="#{SCGZ_180816_34}" , Color="#c7700ff", }, --xiaoyao
	-- [5]  ={Name="#{SCGZ_180816_35}" , Color="#cffffff", }, --tianshan
	-- [6]  ={Name="#{SCGZ_180816_36}" , Color="#cffcc00", }, --mingjiao
	-- [7]  ={Name="#{SCGZ_180816_37}" , Color="#c00ff00", }, --gaibang
	-- [8]  ={Name="#{SCGZ_180816_38}" , Color="#ccc00ff", }, --tangmen
	-- [9]  ={Name="#{SCGZ_180816_39}"     , Color="#c24dec6", }, --guigu
	-- [10] ={Name="#{SCGZ_180816_40}", Color="#c007fff", }, --murong
	-- [11] ={Name="#{SCGZ_180816_41}", Color="#cffff00", }, --tianlong
	-- [12] ={Name="无门派", Color="#c999999", },   --wumenpai
	[0]  ={Name="#{XQ_MP_1}" , Color="#cff6600", },
	[1]  ={Name="#{XQ_MP_2}" , Color="#cffcc00", },
	[2]  ={Name="#{XQ_MP_3}" , Color="#c00ff00", },
	[3]  ={Name="#{XQ_MP_4}" , Color="#c0000ff", },
	[4]  ={Name="#{XQ_MP_5}" , Color="#cff99cc", },
	[5]  ={Name="#{XQ_MP_6}" , Color="#c007700", },
	[6]  ={Name="#{XQ_MP_7}" , Color="#cffff00", },
	[7]  ={Name="#{XQ_MP_8}" , Color="#cffffff", },
	[8]  ={Name="#{XQ_MP_9}" , Color="#c7700ff", },
	[9]  ={Name="无门派"     , Color="#c999999", },	
	[10] ={Name="#{XQ_MP_10}", Color="#c007fff", },
	[11] ={Name="#{XQ_MP_13}", Color="#ccc00ff", },
	[12] ={Name="#{XMPGG_160524_02}", Color="#c24dec6", },   --鬼谷 待修改
	[13] ={Name="#{SCGZ_180816_119}", Color="#ca1d6da", },   --桃花岛
	[14] ={Name="#{XMPHM_210604_01}", Color="#cd61313", },   --
	[15] ={Name="#{GMGameInterface_Script_DataPool_Info_ERenGu}", Color="#c656ab4", },--menpai15
}
-- 闭合图片
local g_Image1 = {
						[1] = "set:Button14  image:Xingui_Pushed",
						[2] = "set:Button14  image:Xingui_Normal",
						[3] = "set:Button14  image:Xingui_Hover",
						[4] = "set:Button14  image:Xingui_Disable",
						[5] = "set:Button14  image:Zungui_Pushed",
						[6] = "set:Button14  image:Zungui_Normal",
						[7] = "set:Button14  image:Zungui_Hover",
						[8] = "set:Button14  image:Zungui_Disable",
						[9] = "set:Button14  image:Huagui_Pushed",
						[10] = "set:Button14  image:Huagui_Normal",
						[11] = "set:Button14  image:Huagui_Hover",
						[12] = "set:Button14  image:Huagui_Disable",
						[13] = "set:Button14  image:Xingui_Pushed",
						[14] = "set:Button14  image:Xingui_Normal",
						[15] = "set:Button14  image:Xingui_Hover",
						[16] = "set:Button14  image:Xingui_Disable",
						[17] = "set:Button14  image:Fugui_Pushed",
						[18] = "set:Button14  image:Fugui_Normal",
						[19] = "set:Button14  image:Fugui_Hover",
						[20] = "set:Button14  image:Fugui_Disable",
						[21] = "set:Button14  image:Huagui_Pushed",
						[22] = "set:Button14  image:Huagui_Normal",
						[23] = "set:Button14  image:Huagui_Hover",
						[24] = "set:Button14  image:Huagui_Disable",
					
}
--打开图片
local g_Image2 = {
						[1] = "set:Button15  image:Xingui_kong_Pushed",
						[2] = "set:Button15  image:Xingui_kong_Normal",
						[3] = "set:Button15  image:Xingui_kong_Hover",
						[4] = "set:Button15  image:Xingui_kong_Disable",
						[5] = "set:Button15  image:Zungui_kong_Pushed",
						[6] = "set:Button15  image:Zungui_kong_Normal",
						[7] = "set:Button15  image:Zungui_kong_Hover",
						[8] = "set:Button15  image:Zungui_kong_Disable",
						[9] = "set:Button15  image:Huagui_kong_Pushed",
						[10] = "set:Button15  image:Huagui_kong_Normal",
						[11] = "set:Button15  image:Huagui_kong_Hover",
						[12] = "set:Button15  image:Huagui_kong_Disable",
						[13] = "set:Button15  image:Xingui_kong_Pushed",
						[14] = "set:Button15  image:Xingui_kong_Normal",
						[15] = "set:Button15  image:Xingui_kong_Hover",
						[16] = "set:Button15  image:Xingui_kong_Disable",
						[17] = "set:Button15  image:Huagui_kong_Pushed",
						[18] = "set:Button15  image:Fugui_kong_Normal",
						[19] = "set:Button15  image:Fugui_kong_Hover",
						[20] = "set:Button15  image:Huagui_kong_Disable",
						[21] = "set:Button15  image:Huagui_kong_Pushed",
						[22] = "set:Button15  image:Huagui_kong_Normal",
						[23] = "set:Button15  image:Huagui_kong_Hover",
						[24] = "set:Button15  image:Huagui_kong_Disable",
					
}
function BW_RankingList_PreLoad()
	 this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("BWTROOP_UPDATE_RANKINGCHARTS2018")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BW_RankingList_OnLoad()
	g_nCurSel_MatchBtn={
	[0]=BW_RankingList_CheckBox_Yeqian1,
	[1]=BW_RankingList_CheckBox_Yeqian2,
	[2]=BW_RankingList_CheckBox_Yeqian3,
	}
	g_nMyInfo = {
	[0]=BW_RankingList_MyClient_Rank,
	[1]=BW_RankingList_MyClient_Name,
	[2]=BW_RankingList_MyClient_Step,
	[3]=BW_RankingList_MyClient_Level,
	[4]=BW_RankingList_MyClient_Menpai,
	[5]=BW_RankingList_MyClient_WinNum,
	--[6]=BW_RankingList_MyClient_WinPercent,
	--[7]=BW_RankingList_MyClient_WinReward,
	}
end

function BW_RankingList_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 20180831 then
	    
	--	PushDebugMessage("22222")
		BW_RankingList_ResetControl()
		local targetId=Get_XParam_INT(0)
        g_nObjID = Target:GetServerId2ClientId(targetId)
        if not g_nObjID or g_nObjID < 0 then
            return
        end
		this:CareObject(g_nObjID, 1)
		local nMatchID=Get_XParam_INT(1)
		BW_RankingList_SetColor(nMatchID)
--		PushDebugMessage("2="..Get_XParam_INT(2))
		g_nCurSel_MatchID = nMatchID
		g_myMatchId = nMatchID
		local nRankType = Get_XParam_INT(2)
		g_RankType = nRankType
		local mLevel = Get_XParam_INT(3)
		g_myLevel = mLevel
		--g_nSelf_TroopID =	Get_XParam_INT(3)
		--show myteaminfo
		--BW_RankingList_ShowMyTeam()
		--BW_RankingList_IsGetAward()
		BW_RankingList_Title:SetText("#{BWPH_180815_02}")
		BW_RankingList_ClientText:SetText("#{BWPH_180815_70}")

		--卡级服
		local kjtype   = KaJi:LuaFnGetKaJiType(28)
		if kjtype == 1 then
			BW_RankingList_CheckBox_Yeqian1:Show()
			BW_RankingList_CheckBox_Yeqian2:Hide()
			BW_RankingList_CheckBox_Yeqian3:Hide()
		else
			BW_RankingList_CheckBox_Yeqian1:Show()
			BW_RankingList_CheckBox_Yeqian2:Show()
			BW_RankingList_CheckBox_Yeqian3:Show()	
		end
		this:Show()
	-- elseif event == "UI_COMMAND" and tonumber(arg0) == 180910 then
		-- local isGetAward = Get_XParam_INT(0)
		-- g_isGetAward = isGetAward
		-- BW_RankingList_Update()
	elseif event == "BWTROOP_UPDATE_RANKINGCHARTS2018" then
		--PushDebugMessage("2222")
	    if not this:IsVisible() then
	        return
	    end
		local nRankType = BWDH2018:GetRankType()
		if nRankType ~= 1 then
			return
		end
		g_RankList_nContentButton = {}
		--PushDebugMessage("11111")
	    BW_RankingList_Update()
	    --show myteaminfo
	    --BW_RankingList_ShowMyTeam()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

--清空信息
function BW_RankingList_ResetControl()
	BW_RankingList_List1_Frame:CleanAllElement("BW_RankingList")
	for i = 0, 5 do
		g_nMyInfo[i]: SetText("")
	end
end

function BW_RankingList_SetCheck()
	local nMatchID = BWDH2018:GetRankMatchID()
	--PushDebugMessage(nMatchID)
	if g_nCurSel_MatchID~=nMatchID then
		BW_RankingList_SetColor(nMatchID)
	end
end

--填充数据
function BW_RankingList_Update()
	BW_RankingList_ResetControl()
	BW_RankingList_SetCheck()
	local nListNum = BWDH2018:GetRankListNum()
	local nRankType = BWDH2018:GetRankType()
	--PushDebugMessage(nListNum)
	if nListNum ~= 0 and nListNum ~= nil then
		for i = 0, nListNum-1 do
		--PushDebugMessage("0")
			local szName,nDuanWei,nLevel,nMenPai,nTotalCnt,nTotalWinCnt,nDuanWei1,nStar,serverid = BWDH2018:GetRankListInfoByIndex(i)
			--PushDebugMessage("1")
			local ItemBar = BW_RankingList_List1_Frame:AddItemElement( "BWRanking_List", "LEFT", "BW_RankingList","" ,"")
			ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			--PushDebugMessage("2")
			if nRankType == 1 then
				ItemBar:SetText2(szName)
			elseif nRankType == 2 then
				ItemBar:SetText2(szName .. "@" .. DataPool:GetServerName(serverid))
			end
			if nDuanWei == 6 then
				ItemBar:SetText3(g_DuanWei1[nDuanWei]..nStar.."星")
			else
				ItemBar:SetText3(g_DuanWei1[nDuanWei]..g_DuanWei2[nDuanWei1])
			end
			ItemBar:SetText4(nLevel)
			ItemBar:SetText5(g_MenPaiNameList[nMenPai].Name)
			ItemBar:SetText6(nTotalWinCnt)
			
			if i == 0 or i == 1 or i == 2 then
				local childImg1 = ItemBar:GetChildItem("BW_RankingList","__auto_SuperBarImage1__")
				childImg1:Show()
				ItemBar:SetImage1("Ach1",string.format("WDTXPMBtn_%d_Normal",i+1))
			else
				local childImg1 = ItemBar:GetChildItem("BW_RankingList","__auto_SuperBarImage1__")
				childImg1:Hide()
				ItemBar:SetText1(i+1)
			end
			--PushDebugMessage("3")
			-- local childBtn1 = ItemBar:GetChildItem("BW_RankingList","__auto_SuperBarButton1__")
			-- childBtn1:Show()
			
			-- if i == 0 or i == 1 or i == 2 then
				-- if g_nCurSel_MatchID == 0 then
					-- childBtn1:SetProperty("PushedImage",g_Image1[5])
					-- childBtn1:SetProperty("NormalImage",g_Image1[6])
					-- childBtn1:SetProperty("HoverImage",g_Image1[7])
				-- elseif g_nCurSel_MatchID == 1 then
					-- childBtn1:SetProperty("PushedImage",g_Image1[13])
					-- childBtn1:SetProperty("NormalImage",g_Image1[14])
					-- childBtn1:SetProperty("HoverImage",g_Image1[15])
				-- elseif g_nCurSel_MatchID == 2 then
					-- childBtn1:SetProperty("PushedImage",g_Image1[21])
					-- childBtn1:SetProperty("NormalImage",g_Image1[22])
					-- childBtn1:SetProperty("HoverImage",g_Image1[23])
				-- end
			-- else
				-- if g_nCurSel_MatchID == 0 then
					-- childBtn1:SetProperty("PushedImage",g_Image1[1])
					-- childBtn1:SetProperty("NormalImage",g_Image1[2])
					-- childBtn1:SetProperty("HoverImage",g_Image1[3])
				-- elseif g_nCurSel_MatchID == 1 then
					-- childBtn1:SetProperty("PushedImage",g_Image1[9])
					-- childBtn1:SetProperty("NormalImage",g_Image1[10])
					-- childBtn1:SetProperty("HoverImage",g_Image1[11])
				-- elseif g_nCurSel_MatchID == 2 then
					-- childBtn1:SetProperty("PushedImage",g_Image1[17])
					-- childBtn1:SetProperty("NormalImage",g_Image1[18])
					-- childBtn1:SetProperty("HoverImage",g_Image1[19])
				-- end
			-- end
				
			-- if g_isGetAward == 0 and g_myMatchId ~= -1 and g_myMatchId == g_nCurSel_MatchID then
				-- local mRank,mName,mLevel,nMenPai,mDW1,mDW2,mDW3,mWinCnt,mTotalCnt = BWDH2018:GetSelfInfo()
				-- if mRank <= 50 and mRank > 0  then
					-- if i == 0 or i == 1 or i == 2 and nRank == i+1 then
						-- if g_nCurSel_MatchID == 0 then
							-- childBtn1:SetProperty("PushedImage",g_Image2[5])
							-- childBtn1:SetProperty("NormalImage",g_Image2[6])
							-- childBtn1:SetProperty("HoverImage",g_Image2[7])
						-- elseif g_nCurSel_MatchID == 1 then
							-- childBtn1:SetProperty("PushedImage",g_Image2[13])
							-- childBtn1:SetProperty("NormalImage",g_Image2[14])
							-- childBtn1:SetProperty("HoverImage",g_Image2[15])
						-- elseif  g_nCurSel_MatchID == 2 then
							-- childBtn1:SetProperty("PushedImage",g_Image2[21])
							-- childBtn1:SetProperty("NormalImage",g_Image2[22])
							-- childBtn1:SetProperty("HoverImage",g_Image2[23])
						-- end
					-- elseif nRank == i+1 then
						-- if g_nCurSel_MatchID == 0 then
							-- childBtn1:SetProperty("PushedImage",g_Image2[1])
							-- childBtn1:SetProperty("NormalImage",g_Image2[2])
							-- childBtn1:SetProperty("HoverImage",g_Image2[3])
						-- elseif g_nCurSel_MatchID == 1 then
							-- childBtn1:SetProperty("PushedImage",g_Image2[9])
							-- childBtn1:SetProperty("NormalImage",g_Image2[10])
							-- childBtn1:SetProperty("HoverImage",g_Image2[11])
						-- elseif g_nCurSel_MatchID == 2 then
							-- childBtn1:SetProperty("PushedImage",g_Image2[17])
							-- childBtn1:SetProperty("NormalImage",g_Image2[18])
							-- childBtn1:SetProperty("HoverImage",g_Image2[19])
						-- end
					-- end
				-- end
			-- end
			table.insert(g_RankList_nContentButton,ItemBar)
		end
	end
	BW_RankingList_List1_Frame:Flash()
	--PushDebugMessage(g_myMatchId)
	--if g_myMatchId ~= -1 and g_myMatchId == g_nCurSel_MatchID then
		--设置自己的数据
	local mRank,mName,mLevel,nMenPai,mDW1,mDW2,mDW3,mWinCnt,mTotalCnt = BWDH2018:GetSelfInfo()
	if g_myMatchId ~= -1 and g_myMatchId == g_nCurSel_MatchID then
		if mRank < 0 or mRank >= 100 then
			g_nMyInfo[0]:SetText("未上榜")
		else
			g_nMyInfo[0]:SetText(mRank+1)
		end
	else
		g_nMyInfo[0]:SetText("未上榜")
	end
	g_nMyInfo[1]:SetText(mName)
	g_nMyInfo[3]:SetText(mLevel)
	g_nMyInfo[4]:SetText(g_MenPaiNameList[nMenPai].Name)
	--PushDebugMessage(g_myLevel)
	local nLevelIndex = Player:Lua_GetXbwData_2018( "LevelIndex" )
	local maxLevelIndex = BWDH2018:GetMaxLevelIndex()
	if nLevelIndex >= 0 and  nLevelIndex < maxLevelIndex then
		if mDW1 ~= 6 then
			if mDW3 == 0 then
				g_nMyInfo[2]:SetText(g_NewMatchLevelName[nLevelIndex]..g_DuanWei1[mDW1]..g_DuanWei2[mDW2].."阶")--.."零".."星")
			else
				g_nMyInfo[2]:SetText(g_NewMatchLevelName[nLevelIndex]..g_DuanWei1[mDW1]..g_DuanWei2[mDW2].."阶")--..g_DuanWei3[mDW3].."星")
			end
		else
			if mDW3 == 0 then
				g_nMyInfo[2]:SetText(g_NewMatchLevelName[nLevelIndex]..g_DuanWei1[mDW1].."0".."星")
			else
				g_nMyInfo[2]:SetText(g_NewMatchLevelName[nLevelIndex]..g_DuanWei1[mDW1]..mDW3.."星")
			end
		end
	else
		g_nMyInfo[2]:SetText("无")
	end
	g_nMyInfo[5]:SetText(mWinCnt)

	--end
	
end

-- 点击换页
function BW_RankingList_ChangeTabIndex(nIdx)
	if nIdx==g_nCurSel_MatchID then
		return
	end
	--g_nCurSel_MatchID = nIdx
	local ClickFlag=BWDH2018:CanQueryRankingAgain()
	if ClickFlag ~= 1 then
	    PushDebugMessage("#{ZBS_YXS_120301_86}")--字典共同吧
	    return
	end
	
	local maxLevelIndex = BWDH2018:GetMaxLevelIndex()
	local nType = BWDH2018:GetRankType()
	if nType ~= g_RankType then
		PushDebugMessage("网络异常，请稍后再进行操作。")
		return
	end
	
	if nIdx>=0 and nIdx < maxLevelIndex then
		BW_RankingList_SetColor(nIdx)
		--BWDH:RequsetRankingCharts(nIdx,0)
		--在这地方去调服务端的脚本的函数,请求排行榜数据
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("QueryRankList")
			Set_XSCRIPT_ScriptID(892897)
			Set_XSCRIPT_Parameter(0, nIdx)
			Set_XSCRIPT_Parameter(1, nType)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT();
		BW_RankingList_ResetControl()
	end
end

function BW_RankingList_SetColor(index)
	local maxLevelIndex = BWDH2018:GetMaxLevelIndex()
	if index>=0 and index < maxLevelIndex then
		g_nCurSel_MatchID = index
		for i=0, maxLevelIndex-1 do
			if i==index then
				g_nCurSel_MatchBtn[i]:SetText("#G"..g_NewMatchLevelName[i])
				g_nCurSel_MatchBtn[i]:SetCheck(1)
			else
				g_nCurSel_MatchBtn[i]:SetText(g_NewMatchLevelName[i])
				g_nCurSel_MatchBtn[i]:SetCheck(0)
			end
		end
	end
end

function BW_RankingList_Close()
	this:Hide()
end

function BW_RankingList_OnItemRClick()
	
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	local mRank,mName,mLevel,nMenPai,mDW1,mDW2,mDW3,mWinCnt,mTotalCnt = BWDH2018:GetSelfInfo()
	if g_myMatchId ~= -1 and g_myMatchId == g_nCurSel_MatchID and mRank == nIndex then
		return 
	else
		if nIndex >= 0 and nIndex < 100 then
			BWDH2018:Show_PopMemu(nIndex)
		end
	end

end

function BW_RankingList_OnCheckButton1Click()
end

-- 领奖
function BW_RankingList_OnButton1Click()
	local maxLevelIndex = BWDH2018:GetMaxLevelIndex()
	if g_nCurSel_MatchID > 0 and g_nCurSel_MatchID < maxLevelIndex then 
		BWDH2018:GetRankAward(g_nCurSel_MatchID)
	end
	--PushDebugMessage("恭喜云端小哥哥点到了我")
end

function BW_RankingList_OnItemClick()
	
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1
	
	if nIndex >= 0 then
		local nNum = table.getn(g_RankList_nContentButton)
		for nButtonIndex = 1,nNum do
			if nil ~= g_RankList_nContentButton[nButtonIndex] then
				if nButtonIndex ~= nIndex then
					g_RankList_nContentButton[nButtonIndex]:SetBarButtonSelected(false)
				else
					g_RankList_nContentButton[nButtonIndex]:SetBarButtonSelected(true)
				end
			end
		end
	end
	
end

-- function BW_RankingList_IsGetAward()

	-- Clear_XSCRIPT();
		-- Set_XSCRIPT_Function_Name("IsGetAward")
		-- Set_XSCRIPT_ScriptID(892897)
		-- Set_XSCRIPT_ParamCount(0)
	-- Send_XSCRIPT();

-- end