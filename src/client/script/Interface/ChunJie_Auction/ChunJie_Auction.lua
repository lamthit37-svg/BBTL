--!!!reloadscript =ChunJie_Auction

local g_ChunJie_Auction_UnifiedPosition = ""

local g_CurRound = 0

local g_BarList = {}

local g_PreShow = 0
--===============================================
-- PreLoad
--===============================================
function ChunJie_Auction_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("SPRING_FESTIVAL_SHOWLIST")
	--游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS", false)
	--游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

--===============================================
-- OnLoad
--===============================================
function ChunJie_Auction_OnLoad()
	g_ChunJie_Auction_UnifiedPosition = ChunJie_Auction_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent
--===============================================
function ChunJie_Auction_OnEvent(event)
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000308 then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
	if event == "UI_COMMAND"  and tonumber(arg0) == 44000310 then
	--	PushDebugMessage(tostring(Get_XParam_INT(0))..":"..tostring(Get_XParam_INT(1)))
		if Get_XParam_INT(0) == 1 then
			ChunJie_Auction_WuPintips:Show()
		else
			ChunJie_Auction_WuPintips:Hide()
		end
		
		if Get_XParam_INT(1) == 1 then
			ChunJie_Auction_DaiBitips:Show()
		else
			ChunJie_Auction_DaiBitips:Hide()
		end
		return
	end
	
	if event == "SPRING_FESTIVAL_SHOWLIST" then
		
		local bShowOrRefresh 	= tonumber(arg0)
		g_CurRound 				= tonumber(arg1)
		g_PreShow				= tonumber(arg2)
	--	PushDebugMessage(tostring(g_CurRound)..":"..tostring(bShowOrRefresh))
		
		if bShowOrRefresh == 0 then
			ChunJie_Auction_CleanUp()
			this:Show()
			ChunJie_Auction_Update()
		elseif bShowOrRefresh == 1 then
			if this:IsVisible() then
				ChunJie_Auction_Update()
			end
		end
		
		ChunJie_Auction_GetNumText03:SetText("#G"..tostring(Player:GetData("YUANBAO")))
		
		return
	end
	
	--刷新元宝
	if event == "UPDATE_YUANBAO" and this:IsVisible() then
		ChunJie_Auction_GetNumText03:SetText("#G"..tostring(Player:GetData("YUANBAO")))
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ChunJie_Auction_Frame_On_ResetPos()
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
end

function ChunJie_Auction_Update()
	
	if g_CurRound < 0 then
		
		if g_PreShow ~= 1 then
			ChunJie_Auction_Lace:Hide()
			ChunJie_Auction_Text:Show()
			ChunJie_Auction_Text:SetText("#{CJPM_191126_46}")		
			ChunJie_Auction_GetNumText:SetText("#{CJPM_191126_30}")
			
			ChunJie_Auction_Intro:SetText("#{CJPM_191126_147}")
			
			ChunJie_Auction_F5:Hide()
			ChunJie_Auction_GetNumTextBK:Hide()
		else			
				
			ChunJie_Auction_Lace:Show()
			ChunJie_Auction_Text:Hide()
			
			ChunJie_Auction_Intro:SetText("#{CJPM_191126_27}")
			
			local bFinish = 1
			local bPreTime = 0
			
			ChunJie_Auction_CleanUp()		
			
			for i = 1, 10 do
				
				local nBonusItemIndex = DataPool:Lua_GetSpringFestivalBonusInfo(0, i - 1,"BONUS")
				if tonumber(nBonusItemIndex) <= 0 then
					break
				end
				
				ChunJie_Auction_AddItem(0, i)				

			end

			ChunJie_Auction_F5:Hide()
			ChunJie_Auction_GetNumTextBK:Show()
			ChunJie_Auction_GetNumText:SetText("#{CJPM_220421_26}")
		end
	else
	
		ChunJie_Auction_Lace:Show()
		ChunJie_Auction_Text:Hide()
		
		ChunJie_Auction_Intro:SetText("#{CJPM_191126_27}")
		
		local bFinish = 1
		local bPreTime = 0
		
		ChunJie_Auction_CleanUp()		
		
		for i = 1, 10 do
			
			local nBonusItemIndex = DataPool:Lua_GetSpringFestivalBonusInfo(g_CurRound, i - 1,"BONUS")
			if tonumber(nBonusItemIndex) <= 0 then
				break
			end
			
			ChunJie_Auction_AddItem(g_CurRound, i)
			
			local nTimeFlag = DataPool:Lua_GetSpringFestivalBiddingInfo(i - 1,"TIMEFLAG")
			if nTimeFlag == 1 then
				bPreTime = 1
			elseif nTimeFlag == 2 then
				bFinish = 0
			end			
		end
		
		ChunJie_Auction_F5:Show()
		ChunJie_Auction_GetNumTextBK:Show()
		if bPreTime == 1 then
			ChunJie_Auction_GetNumText:SetText("#{CJPM_191126_28}")
		elseif bFinish == 1 then
			ChunJie_Auction_GetNumText:SetText("#{CJPM_191126_30}")
		else
			ChunJie_Auction_GetNumText:SetText("#{CJPM_191126_29}")
		end
	end	
	
	--玉牌
	if Lua_IsDWFanLiReceived(11) == 1 then
		ChunJie_Auction_GetNumText02_Pai:SetText("#{CJPM_220421_02}")
	else
		ChunJie_Auction_GetNumText02_Pai:SetText("#{CJPM_220421_03}")
	end
	
	--玉牒
	if Lua_IsDWFanLiReceived(12) == 1 then
		ChunJie_Auction_GetNumText02_Pan:SetText("#{CJPM_220421_20}")
	else
		ChunJie_Auction_GetNumText02_Pan:SetText("#{CJPM_220421_21}")
	end
	
	--ChunJie_Auction_GetNumText02_Pan:Hide()
	--ChunJie_Auction_GetNumText02_Pai:Hide()
end

function ChunJie_Auction_AddItem(nRound, idx)

	local bar1 = ChunJie_Auction_Lace:AddChild("ChunJie_Auction_CoinAItem")	
		g_BarList[idx] = bar1
	local nHighPrice = DataPool:Lua_GetSpringFestivalBiddingInfo(idx - 1,"TOPBID")
	local nHighName = DataPool:Lua_GetSpringFestivalBiddingInfo(idx - 1,"NAME")
	local nMyPrice = DataPool:Lua_GetSpringFestivalBiddingInfo(idx - 1,"MYBID")
	local nTimeFlag = DataPool:Lua_GetSpringFestivalBiddingInfo(idx - 1,"TIMEFLAG")
	
	local bNobody = 0
	if nHighName == "" then
		nHighPrice = DataPool:Lua_GetSpringFestivalBonusInfo(nRound, idx - 1,"BASEPRICE")	
		nHighName = "#{CJPM_191126_144}"
		bNobody = 1
	end
	
	local nBonusItemIndex = DataPool:Lua_GetSpringFestivalBonusInfo(nRound, idx - 1,"BONUS")
	local nBonusCount = DataPool:Lua_GetSpringFestivalBonusInfo(nRound, idx - 1,"BONUSCOUNT")
	local theAction = DataPool:CreateActionItemForShow(nBonusItemIndex,nBonusCount)
	if theAction:GetID() ~= 0 then
		local ctrlAction = bar1:GetSubItem("ChunJie_Auction_CoinAItem_Icon")
		if ctrlAction ~= nil then
			ctrlAction:SetActionItem(theAction:GetID())
		end
	end
	
	local item_name = DataPool:Lua_GetItemNameByIndex(nBonusItemIndex)	
	bar1:GetSubItem("ChunJie_Auction_CoinAItem_Art"):SetText("#M"..tostring(item_name).."*"..tostring(nBonusCount))
--	bar1:GetSubItem("ChunJie_Auction_CoinAItem_Num"):SetText("#L"..tostring(idx))	

	if nMyPrice > 0 then
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_SelfIcon"):Show()
		if nMyPrice >= nHighPrice then
			bar1:GetSubItem("ChunJie_Auction_CoinAItem_Price"):SetText("#M"..tostring(nHighPrice))
			bar1:GetSubItem("ChunJie_Auction_CoinAItem_Name"):SetText("#M"..tostring(nHighName))
			bar1:GetSubItem("ChunJie_Auction_CoinAItem_Self"):SetText("#M"..tostring(nMyPrice))
		else
			bar1:GetSubItem("ChunJie_Auction_CoinAItem_Price"):SetText("#N"..tostring(nHighPrice))
			bar1:GetSubItem("ChunJie_Auction_CoinAItem_Name"):SetText("#N"..tostring(nHighName))
			bar1:GetSubItem("ChunJie_Auction_CoinAItem_Self"):SetText("#N"..tostring(nMyPrice))
		end
		
	else
		
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Price"):SetText("#L"..tostring(nHighPrice))
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Name"):SetText("#L"..tostring(nHighName))
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Self"):SetText("#{CJPM_191126_145}")
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_SelfIcon"):Hide()
	end
	
	bar1:GetSubItem("ChunJie_Auction_CoinAItem_ZhuangTai"):Hide()
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Button"):SetEvent( "Clicked", string.format("ChunJie_Auction_OpenBidUI(%d)", idx))
	
	if g_PreShow == 1 then
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_ZhuangTai"):Show()
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_ZhuangTai"):SetProperty("Image","set:Spring15 image:JingPai_Wait")
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Button"):Hide()
	elseif nTimeFlag == 1 then
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_ZhuangTai"):Show()
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_ZhuangTai"):SetProperty("Image","set:Spring15 image:JingPai_Wait")
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Button"):Hide()
	elseif nTimeFlag == 2 then
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_ZhuangTai"):Hide()
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Button"):Show()
	elseif nTimeFlag == 3 or nTimeFlag == 4 then
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_ZhuangTai"):Show()
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Button"):Hide()
		if bNobody == 1 then
			bar1:GetSubItem("ChunJie_Auction_CoinAItem_ZhuangTai"):SetProperty("Image","set:Spring15 image:JingPai_YilLiuPai")
		else
			bar1:GetSubItem("ChunJie_Auction_CoinAItem_ZhuangTai"):SetProperty("Image","set:Spring15 image:JingPai_YiChengJiao")
		end
	end
	
	bar1:GetSubItem("ChunJie_Auction_CoinAItem_Look"):SetEvent("Clicked", string.format("ChunJie_Auction_OpenLook(%d)", idx))
	if nBonusItemIndex == 38006373 or nBonusItemIndex == 38004733 then
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Look"):Show()
	else
		bar1:GetSubItem("ChunJie_Auction_CoinAItem_Look"):Hide()
	end
end

function ChunJie_Auction_OpenBidUI(idx)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowClientUI" )
		Set_XSCRIPT_ScriptID(440003)
		Set_XSCRIPT_Parameter(0, 0)				--竞拍
		Set_XSCRIPT_Parameter(1, 1)				--打开
		Set_XSCRIPT_Parameter(2, g_CurRound)	--轮次	
		Set_XSCRIPT_Parameter(3, idx - 1)		--索引
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function ChunJie_Auction_TakeBonus()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "TakeBonus" )
		Set_XSCRIPT_ScriptID( 440003 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ChunJie_Auction_TakeTokens()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "TakeBackTokens" )
		Set_XSCRIPT_ScriptID( 440003 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ChunJie_Auction_Refresh()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowClientUI" )
		Set_XSCRIPT_ScriptID(440003)
		Set_XSCRIPT_Parameter(0, 1)		--列表
		Set_XSCRIPT_Parameter(1, 0)		--刷新
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

function ChunJie_Auction_CleanUp()
	
	for i = 1 , 10 do		
		if g_BarList[i] then			
			local ctrlAction = g_BarList[i]:GetSubItem("ChunJie_Auction_CoinAItem_Icon")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end	
	end
	
	g_BarList = {}
	ChunJie_Auction_Lace:Clear()
end

function ChunJie_Auction_CloseClicked()
	this:Hide()
end

function ChunJie_Auction_OnHidden()
	ChunJie_Auction_CleanUp()
	CloseWindow("SpecialGift_DoubleLook", true)
end

function ChunJie_Auction_HelpClick()
	PushEvent("SRPING_FESTIVAL_BIDDINGLIST_HELP")
end

function ChunJie_Auction_Frame_On_ResetPos()
	if g_ChunJie_Auction_UnifiedPosition ~= nil then
		ChunJie_Auction_Frame:SetProperty("UnifiedPosition",g_ChunJie_Auction_UnifiedPosition)
	end
end

function ChunJie_Auction_OpenLook(idx)

	local nBonusItemIndex = 0
	if g_CurRound < 0 and g_PreShow == 1 then
		nBonusItemIndex = DataPool:Lua_GetSpringFestivalBonusInfo(0, idx - 1,"BONUS")
	else
		nBonusItemIndex = DataPool:Lua_GetSpringFestivalBonusInfo(g_CurRound, idx - 1,"BONUS")
	end
	
	if nBonusItemIndex == 38006373 then
		LuaFnShowDressPreviewChoice(2, 1)
	elseif nBonusItemIndex == 38004733 then
		LuaFnOpenSkillCardDetail(35)
	end	
end

