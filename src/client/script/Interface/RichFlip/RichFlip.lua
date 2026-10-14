--RichFlip
local g_RichFlip_UnifiedPosition;


local RichFlip_DrawCard_Lock = {}
local RichFlip_DrawCard_Image = {}
local RichFlip_DrawCard_Item = {}
local RichFlip_DrawCard_Animate = {}
local RichFlip_DrawCard_AnimateSR = {}
local RichFlip_DrawCard_AnimateSSR = {}
local RichFlip_DrawCard_RewardBtn = {}
local RichFlip_DrawCard_Tips = {}
local RichFlip_DrawCard_OK = {}

local RichFlip_Storage_Client_BagFrame = {}
local RichFlip_Storage_Client_BagFrame_Item = {}
local RichFlip_Storage_Client_BagFrame_Mask = {}
local RichFlip_Storage_Client_BagFrame_Limit = {}
local RichFlip_Storage_Client_BagFrame_Name = {}
local RichFlip_Storage_Client_BagFrame_Currency = {}
local RichFlip_Storage_Client_BagFrame_BK = {}
local RichFlip_Storage_Client_BagFrame_CurrencyIcon = {}
local RichFlip_Shop_Client_ShopFrame = {}
local RichFlip_Shop_Client_ShopFrame_Item = {}
local RichFlip_Shop_Client_ShopFrame_Mask = {}
local RichFlip_Shop_Client_ShopFrame_LimitBK = {}
local RichFlip_Shop_Client_ShopFrame_LimitNum = {}
local RichFlip_Shop_Client_ShopFrame_LimitMark = {}
local RichFlip_Shop_Client_ShopFrame_Name = {}
local RichFlip_Shop_Client_ShopFrame_Currency = {}
local RichFlip_Shop_Client_ShopFrame_SoldOut = {}
local RichFlip_Shop_Client_ShopFrame_FanpaiNum = {}

--变量
local g_curpage = 0
local g_ActiveBlockFlag = {0}
local g_ActiveBlockRewardFlag = {0}
local g_ChoujiangDaibi = 0
local g_DuiHuanDaibi = 0
local g_BaodiCount = 0
local g_SingleRewardId = 0
local g_SingleRewardNum = 0
local g_TenTimesBlocklist = {0}
local g_TenTimesRewardlist = {0}
local g_IsSingleTime = 0
local g_curAnimateTimes = 0
local g_ChoujiangRound = 0
local g_ChoujiangCount = 0
local g_totalbuynum = 0

local g_rewardcount = 0
local g_rewardItemId = {0}
local g_rewardItemNum = {0}
local g_StoragePage = 1
local g_dhdaibi = 0

local g_curShopPage = 1
local g_ShopLimitData = {0}
local g_ItemCanBuy = {0}


--抽奖一次所需代币数
local g_Choujiang_Need = 4
local g_ChouajiangState = 0

local g_Quality_Image = {
	[0] = "set:RichFlip_01 image:R_BK", --普通（蓝色）
	[1] = "set:RichFlip_01 image:SR_BK", --稀有（紫色）
	[2] = "set:RichFlip_01 image:SSR_BK", --稀有（金色）
}

local g_Storage_Image = {
	[1] = "set:RichFlip_01 image:Storage_RBK", --普通（蓝色）
	[2] = "set:RichFlip_01 image:Storage_SRBK", --稀有（紫色）
	[3] = "set:RichFlip_01 image:Storage_SSRBK", --稀有（金色）
}

local g_RoundReward_Need = {40, 80, 160, 280, 400, 560, 900}

local g_SpecialItem = 38008185 

local g_SpecialItemNum = 10

function RichFlip_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function RichFlip_OnLoad()
	
	for i = 1, 20 do
		RichFlip_DrawCard_Lock[i] = _G["RichFlip_DrawCard_Client_ImageFrame_Box"..i.."_Lock"]
		RichFlip_DrawCard_Image[i] = _G["RichFlip_DrawCard_Client_ImageFrame_Box"..i.."_CardAward"]
		RichFlip_DrawCard_Item[i] = _G["RichFlip_DrawCard_Client_ImageFrame_Box"..i.."_CardAward_Item"]
		RichFlip_DrawCard_Animate[i] = _G["RichFlip_DrawCard_Client_ImageFrame_Box"..i.."_Animate"]
		RichFlip_DrawCard_AnimateSR[i] = _G["RichFlip_DrawCard_Client_ImageFrame_Box"..i.."_AnimateSR"]
		RichFlip_DrawCard_AnimateSSR[i] = _G["RichFlip_DrawCard_Client_ImageFrame_Box"..i.."_AnimateSSR"]
	end
	
	for i = 1, 7 do
		RichFlip_DrawCard_RewardBtn[i] = _G["RichFlip_DrawCard_Client_ProgressBtn"..i]
		RichFlip_DrawCard_Tips[i] = _G["RichFlip_DrawCard_Client_ProgressTips"..i]
		RichFlip_DrawCard_OK[i] = _G["RichFlip_DrawCard_Client_ProgressGetMark"..i]
	end
	
	for i = 1, 12 do
		RichFlip_Storage_Client_BagFrame[i] = _G["RichFlip_Storage_Client_BagFrame_Item"..i.."BK"]
		RichFlip_Storage_Client_BagFrame_Item[i] = _G["RichFlip_Storage_Client_BagFrame_Item"..i]
		RichFlip_Storage_Client_BagFrame_Mask[i] = _G["RichFlip_Storage_Client_BagFrame_Item"..i.."_Mask"]
		RichFlip_Storage_Client_BagFrame_Limit[i] = _G["RichFlip_Storage_Client_BagFrame_Item"..i.."_BuyLimitNum"]
		RichFlip_Storage_Client_BagFrame_Name[i] = _G["RichFlip_Storage_Client_BagFrame_Item"..i.."_Text"]
		RichFlip_Storage_Client_BagFrame_Currency[i] = _G["RichFlip_Storage_Client_BagFrame_Item"..i.."_Currency"]
		RichFlip_Storage_Client_BagFrame_BK[i] = _G["RichFlip_Storage_Client_BagFrame_Item"..i.."BK"]
		RichFlip_Storage_Client_BagFrame_CurrencyIcon[i] = _G["RichFlip_Storage_Client_BagFrame_Item"..i.."_CurrencyIcon"]
	end

	for i = 1, 12 do
		RichFlip_Shop_Client_ShopFrame[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i.."BK"]
		RichFlip_Shop_Client_ShopFrame_Item[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i]
		RichFlip_Shop_Client_ShopFrame_Mask[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i.."_Mask"]
		RichFlip_Shop_Client_ShopFrame_LimitBK[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i.."_BuyLimitNumBK"]
		RichFlip_Shop_Client_ShopFrame_LimitNum[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i.."_BuyLimitNum"]
		RichFlip_Shop_Client_ShopFrame_LimitMark[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i.."_BuyLimitMark"]
		RichFlip_Shop_Client_ShopFrame_Name[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i.."_Text"]
		RichFlip_Shop_Client_ShopFrame_Currency[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i.."_Currency"]
		RichFlip_Shop_Client_ShopFrame_SoldOut[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i.."_SoldOut"]
		RichFlip_Shop_Client_ShopFrame_FanpaiNum[i] = _G["RichFlip_Shop_Client_ShopFrame_Item"..i.."_LimitText"]
	end
		
	g_RichFlip_UnifiedPosition = RichFlip_MainFrame_BK:GetProperty("UnifiedPosition")
	
end


function RichFlip_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99944101 ) then
		local UIdataTbl = {0}
		local UIdataTbl2 = {0}
		local operator = Get_XParam_INT(0)
		UIdataTbl[1] = Get_XParam_INT(1)
		UIdataTbl[2] = Get_XParam_INT(2)
		UIdataTbl[3] = Get_XParam_INT(3)
		UIdataTbl[4] = Get_XParam_INT(4)
		UIdataTbl[5] = Get_XParam_INT(5)
		UIdataTbl2[1] = Get_XParam_INT(6)
		g_ChoujiangDaibi = Get_XParam_INT(7)
		g_DuiHuanDaibi = Get_XParam_INT(8)
		g_BaodiCount = Get_XParam_INT(9)
		g_ChoujiangRound = Get_XParam_INT(10)
		g_ChoujiangCount = Get_XParam_INT(11)
		g_totalbuynum = Get_XParam_INT(12)
		
		local retactivelist = {0}
		retactivelist = RichFlip_UICommandarry(20, 2, UIdataTbl)
		for i, v in retactivelist do
			g_ActiveBlockFlag[i] = v
			--PushDebugMessage(v)
		end

		local retactivelist2 = {0}
		retactivelist2 = RichFlip_UICommandarry(7, 1, UIdataTbl2)
		for i, v in retactivelist2 do
			g_ActiveBlockRewardFlag[i] = v
			--PushDebugMessage(v)
		end
			
		if operator == 1 then
			g_curpage = 1			
			RichFlip_Update()
		elseif operator == 2 and this:IsVisible() then
			if g_curpage == 1 then
				RichFlip_Update_Client1()	
			end	
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99944107 and this:IsVisible() ) then
		if g_curpage == 1 then
			local activeidx = Get_XParam_INT(0)
			local rewardIdx = Get_XParam_INT(1)
			g_ChoujiangDaibi = Get_XParam_INT(2)
			g_BaodiCount = Get_XParam_INT(3)
			g_DuiHuanDaibi = Get_XParam_INT(4)
			g_ChoujiangCount = Get_XParam_INT(5)
			if activeidx > 0 then
				RichFlip_Active_Client1_Block_Animate(activeidx, rewardIdx)	
			end
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99944108 and this:IsVisible() ) then
		if g_curpage == 1 then
			local UIactivelist = {0}
			local UIrewardlist = {0}
			for i = 1, 2 do
				UIactivelist[i] = Get_XParam_INT(i-1)
			end
			for i = 1, 2 do
				UIrewardlist[i] = Get_XParam_INT(i+1)
			end
			g_ChoujiangDaibi = Get_XParam_INT(4)
			g_BaodiCount = Get_XParam_INT(5)
			g_DuiHuanDaibi = Get_XParam_INT(6)	
			g_ChoujiangCount = Get_XParam_INT(7)
			RichFlip_Active_Client1_TenTimes_Block_Animate(UIactivelist, UIrewardlist)		
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99944105 ) then 
		RichFlip_CleanUp()
		if ( IsWindowShow( "RichFlip_MSplit" ) ) then
			CloseWindow( "RichFlip_MSplit", true );
		end 
		if ( IsWindowShow( "RichFlip_MReceive" ) ) then
			CloseWindow( "RichFlip_MReceive", true );
		end 
	
		local paramcount = Get_XParam_INT_Count()
		--PushDebugMessage(paramcount)
		local operator = Get_XParam_INT(0)
		g_rewardcount =  Get_XParam_INT(1)
		g_dhdaibi = Get_XParam_INT(2)
		local nPage = Get_XParam_INT(3)
		if nPage > 0 then
			g_StoragePage = nPage
		end
		
		for i = 4, paramcount-1 do
			local itemdata = Get_XParam_INT(i)
			g_rewardItemId[i-3] = math.floor(itemdata/1000)+1
			g_rewardItemNum[i-3] = math.mod(itemdata, 1000)
		end
		
		if operator == 1 then
			g_curpage = 2
			RichFlip_Update()
		elseif operator == 2 and this:IsVisible() then
			if g_curpage == 2 then
				RichFlip_Update_Client2()	
			end	
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99944109 ) then
		if ( IsWindowShow( "RichFlip_MBuy" ) ) then
			CloseWindow( "RichFlip_MBuy", true );
		end 
		local paramcount = Get_XParam_INT_Count()		
		local operator = Get_XParam_INT(0)
		g_dhdaibi =  Get_XParam_INT(1) 
		
		for i = 2, paramcount do
			g_ShopLimitData[i-1] = Get_XParam_INT(i) 
		end
		
		if operator == 1 then
			g_curpage = 3
			g_curShopPage = 1
			RichFlip_Update()
		elseif operator == 2 and this:IsVisible() then
			if g_curpage == 3 then
				RichFlip_Update_Client3()	
			end	
		end		
	elseif (event == "ADJEST_UI_POS" ) then
		RichFlip_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		RichFlip_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "PACKAGE_ITEM_CHANGED_EX") and this:IsVisible() then	
		RichFlip_UpdateDress()
	end

end

--=========================================================
--更新界面
--=========================================================
function RichFlip_Update()
	if g_curpage == 1 then
		RichFlip_DrawCard_Client:Show()
		RichFlip_Storage_Client:Hide()
		RichFlip_Shop_Client:Hide()
		RichFlip_ClothPiece_Client:Hide()
		RichFlip_PageBtn_Sift1:SetCheck(1)
		RichFlip_PageBtn_Sift2:SetCheck(0)
		RichFlip_PageBtn_Sift3:SetCheck(0)
		RichFlip_PageBtn_Sift4:SetCheck(0)
		RichFlip_Update_Client1()
	elseif g_curpage == 2 then
		RichFlip_DrawCard_Client:Hide()
		RichFlip_Storage_Client:Show()
		RichFlip_Shop_Client:Hide()
		RichFlip_ClothPiece_Client:Hide()
		RichFlip_PageBtn_Sift1:SetCheck(0)
		RichFlip_PageBtn_Sift2:SetCheck(1)
		RichFlip_PageBtn_Sift3:SetCheck(0)
		RichFlip_PageBtn_Sift4:SetCheck(0)
		RichFlip_Update_Client2()
	elseif g_curpage == 3 then
		RichFlip_DrawCard_Client:Hide()
		RichFlip_Storage_Client:Hide()
		RichFlip_Shop_Client:Show()
		RichFlip_ClothPiece_Client:Hide()
		RichFlip_PageBtn_Sift1:SetCheck(0)
		RichFlip_PageBtn_Sift2:SetCheck(0)
		RichFlip_PageBtn_Sift3:SetCheck(1)
		RichFlip_PageBtn_Sift4:SetCheck(0)
		RichFlip_Update_Client3()
	elseif g_curpage == 4 then
		RichFlip_DrawCard_Client:Hide()
		RichFlip_Storage_Client:Hide()
		RichFlip_Shop_Client:Hide()
		RichFlip_ClothPiece_Client:Show()
		RichFlip_PageBtn_Sift1:SetCheck(0)
		RichFlip_PageBtn_Sift2:SetCheck(0)
		RichFlip_PageBtn_Sift3:SetCheck(0)
		RichFlip_PageBtn_Sift4:SetCheck(1)
		RichFlip_Description_Text:SetText("#{FPLS_240715_162}")
		--RichFlip_UpdateDress()
	end
	
	RichFlip_UpdateDress()
	this:Show()
end

function RichFlip_CleanUp()
	g_rewardcount = 0
	for i = 1, 12 do
		g_rewardItemId[i] = -1
		g_rewardItemNum[i] = 0
	end
	g_StoragePage = 1	
end

function RichFlip_Update_Client1()
	RichFlip_Description_Text:SetText("#{FPLS_240715_13}")
	for i = 1, 20 do
		RichFlip_DrawCard_Animate[i]:Play(false)
		RichFlip_DrawCard_AnimateSR[i]:Play(false)
		RichFlip_DrawCard_AnimateSSR[i]:Play(false)
	end	
	
	RichFlip_DrawCard_Client_SingleDrawBtn:Enable()
	RichFlip_DrawCard_Client_TenTimesDrawBtn:Enable()
	RichFlip_DrawCard_Client_NextRound_Tip:Hide()
	for i = 1, 20 do
		RichFlip_Update_Client1_OneCard(i, 0)
	end

	RichFlip_Update_Client1_Reward()
	
end

--=========================================================
--刷新文字区域
--=========================================================
function RichFlip_Update_Client1_Reward()
	RichFlip_DrawCard_Client_Currency1_Text:SetText(ScriptGlobal_Format("#{FPLS_240715_50}", g_ChoujiangDaibi))
	RichFlip_DrawCard_Client_Currency2_Text:SetText(ScriptGlobal_Format("#{FPLS_240715_51}", g_DuiHuanDaibi))
	RichFlip_DrawCard_Client_RoundText:SetText(ScriptGlobal_Format("#{FPLS_240715_140}", g_ChoujiangRound))
	RichFlip_DrawCard_Client_Self:SetText(ScriptGlobal_Format("#{FPLS_240715_142}", g_ChoujiangCount))
	RichFlip_DrawCard_Client_Currency1_LimitText:SetText(ScriptGlobal_Format("#{FPLS_240715_169}", g_totalbuynum))
	
	local isGetHuanYu = math.mod(g_BaodiCount,10)
	if isGetHuanYu == 1 then
		RichFlip_DrawCard_Client_MinDrawText:SetText("#{FPLS_251020_02}")
		RichFlip_DrawCard_Client_MinDrawText:SetToolTip("#{FPLS_251020_01}")
	else
		RichFlip_DrawCard_Client_MinDrawText:SetText(ScriptGlobal_Format("#{FPLS_240715_141}", g_ChoujiangCount))
		RichFlip_DrawCard_Client_MinDrawText:SetToolTip("#{FPLS_251020_01}")
	end
		
	for i = 1, 7 do
		if g_ActiveBlockRewardFlag[i] > 0 then
			RichFlip_DrawCard_OK[i]:Show()
			RichFlip_DrawCard_RewardBtn[i]:Disable()
			RichFlip_DrawCard_Tips[i]:Hide()
		else
			if g_ChoujiangCount >= g_RoundReward_Need[i] then --可领取
				RichFlip_DrawCard_OK[i]:Hide()
				RichFlip_DrawCard_RewardBtn[i]:Enable()
				RichFlip_DrawCard_Tips[i]:Show()				
			else
				RichFlip_DrawCard_OK[i]:Hide()
				RichFlip_DrawCard_RewardBtn[i]:Enable()
				RichFlip_DrawCard_Tips[i]:Hide()			
			end
		end
	end	
end

--=========================================================
--刷新单个牌
--=========================================================
function RichFlip_Update_Client1_OneCard(idx, isShowAnim)
	if idx < 1 or idx > 20 then
		return
	end
	
	if g_ActiveBlockFlag[idx] > 0 then
		RichFlip_DrawCard_Lock[idx]:Hide()
		RichFlip_DrawCard_Item[idx]:Show()
		local nShowItemId,nItemNum,nIsBind,nFenjie,nType = DataPool:LuaFnGetLuckyLineChoujiangItemInfo(g_ActiveBlockFlag[idx])
		if nShowItemId ~= nil and nShowItemId > 0 then
			local theAction = nil
			if nIsBind == 1 then
				theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
			else
				theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
			end
			if theAction ~= nil then
				RichFlip_DrawCard_Item[idx]:SetActionItem(theAction:GetID())
			end			
		end
		if nType ~= nil and nType >= 0 and nType <= 2 then
			RichFlip_DrawCard_Image[idx]:Show()
			RichFlip_DrawCard_Image[idx]:SetProperty("Image", g_Quality_Image[nType])
			if isShowAnim == 1 and nType == 1 then
				RichFlip_DrawCard_AnimateSR[idx]:Play(true)
			elseif isShowAnim == 1 and nType == 2 then
				RichFlip_DrawCard_AnimateSSR[idx]:Play(true)
			end
			if nType >= 1 and nType <= 2 then
				RichFlip_DrawCard_Client_SingleDrawBtn:Disable()
				RichFlip_DrawCard_Client_TenTimesDrawBtn:Disable()
				local curDay = tonumber(DataPool:GetServerDayTime());
				if curDay >= 20251031 and curDay <= 20251112 then
					RichFlip_DrawCard_Client_NextRound_Tip:Show()
				end
			end
		end
	else
		RichFlip_DrawCard_Lock[idx]:Show()
		RichFlip_DrawCard_Item[idx]:Hide()
		--RichFlip_DrawCard_Item[idx]:SetActionItem(-1)
		RichFlip_DrawCard_Image[idx]:Hide()
	end	
end
--=========================================================
--单次开始
--=========================================================
function RichFlip_Active_Client1_Block_Animate(activeidx, rewardidx)
	g_IsSingleTime = 1
	for i = 1, 20 do
		if activeidx == i then
			RichFlip_DrawCard_Animate[i]:Play(true)
			g_ActiveBlockFlag[activeidx] = rewardidx
		else
			RichFlip_DrawCard_Animate[i]:Play(false)
		end
	end

end

--=========================================================
--刷新单次奖励界面
--=========================================================
function RichFlip_DrawCard_Show_Client1_Single_Reward()

end

--=========================================================
--多次开始
--=========================================================
function RichFlip_Active_Client1_TenTimes_Block_Animate(activelist, rewardlist)
	g_IsSingleTime = 0
	
	local retactivelist = {0}
	local retrewardlist = {0} 
	retactivelist = RichFlip_UICommandarry(5, 2, activelist)
	retrewardlist = RichFlip_UICommandarry(5, 2, rewardlist)
	
	for i = 1, 5 do
		local blockidx = retactivelist[i]
		if blockidx >= 1 and blockidx <= 20 then
			g_ActiveBlockFlag[blockidx] = retrewardlist[i]
			g_TenTimesBlocklist[i] = blockidx
		end	
	end
	
	
	for i, rewardidx in retrewardlist do
		g_TenTimesRewardlist[i] = rewardidx+1
	end	
		
	for i = 1, 5 do
		local NextBlockidx = g_TenTimesBlocklist[i]
		if NextBlockidx > 0 and NextBlockidx <= 20 then
			RichFlip_DrawCard_Animate[NextBlockidx]:Play(true)
			--g_curAnimateTimes = 1		
		end
	end
	
end
--=========================================================
--多次结束
--=========================================================
function RichFlip_DrawCard_Box_Animate_End(nIndex)
	if g_IsSingleTime == 1 then --单次结束
		RichFlip_Update_Client1_OneCard(nIndex, 1)
		RichFlip_Update_Client1_Reward()
		return
	end
	
	--多次动画
	if g_IsSingleTime == 0 then
		g_IsSingleTime = 2
		for i = 1, 5 do
			local curBlockidx = g_TenTimesBlocklist[i]
			RichFlip_Update_Client1_OneCard(curBlockidx, 1)
		end
		RichFlip_Update_Client1_Reward()
	end
	--if g_curAnimateTimes > 0 and g_curAnimateTimes < 5 then
	--	local curBlockidx = g_TenTimesBlocklist[g_curAnimateTimes]
	--	RichFlip_Update_Client1_OneCard(curBlockidx)
	
	--	local NextBlockidx = g_TenTimesBlocklist[g_curAnimateTimes+1]
	--	if NextBlockidx > 0 then
	--		RichFlip_DrawCard_Animate[NextBlockidx]:Play(true)
	--		g_curAnimateTimes = g_curAnimateTimes+1	
	--	end
	--elseif g_curAnimateTimes == 5 then --结束
	--	local curBlockidx = g_TenTimesBlocklist[g_curAnimateTimes]
	--	RichFlip_Update_Client1_OneCard(curBlockidx)
		
	--	RichFlip_Update_Client1_Reward()
	--end

end
--=========================================================
--刷新多次奖励界面
--=========================================================
function RichFlip_DrawCard_Show_Client1_Times_Reward()

end

--=========================================================
--刷新仓库
--=========================================================
function RichFlip_Update_Client2()
	RichFlip_Description_Text:SetText("#{FPLS_240715_166}")
	if g_rewardcount <= 0 then
		RichFlip_Storage_Client_EmptyBagFrame:Show()
		RichFlip_Storage_Client_BagFrameFrame:Hide()
	else
		RichFlip_Storage_Client_EmptyBagFrame:Hide()
		RichFlip_Storage_Client_BagFrameFrame:Show()
		
		for i = 1, 12 do
			RichFlip_Storage_Client_BagFrame[i]:Hide()
			
			if g_rewardItemId[i] > 0 then
			--PushDebugMessage(g_rewardItemId[i])
				RichFlip_Storage_Client_BagFrame[i]:Show()
				RichFlip_Storage_Client_BagFrame_Item[i]:SetActionItem(-1)
				RichFlip_Storage_Client_BagFrame_Name[i]:SetText("")
				RichFlip_Storage_Client_BagFrame_Limit[i]:SetText("")
				RichFlip_Storage_Client_BagFrame_Currency[i]:SetText("")
				RichFlip_Storage_Client_BagFrame_BK[i]:SetProperty("Image", g_Storage_Image[1])
				RichFlip_Storage_Client_BagFrame_CurrencyIcon[i]:Show()
				local nShowItemId,nItemNum,nIsBind,nFenjie,nType = DataPool:LuaFnGetLuckyLineChoujiangItemInfo(g_rewardItemId[i])
				if nShowItemId ~= nil and nShowItemId > 0 then
					local theAction = nil
					if nIsBind == 1 then
						theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
					else
						theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
					end
					if theAction ~= nil then
						RichFlip_Storage_Client_BagFrame_Item[i]:SetActionItem(theAction:GetID())
						RichFlip_Storage_Client_BagFrame_Name[i]:SetText(ScriptGlobal_Format("#{FPLS_240715_66}",theAction:GetName()))
						RichFlip_Storage_Client_BagFrame_Limit[i]:SetText(tostring(g_rewardItemNum[i]))
						if nFenjie > 0 then
							RichFlip_Storage_Client_BagFrame_Currency[i]:SetText(ScriptGlobal_Format("#{FPLS_240715_67}",nFenjie))
						else
							RichFlip_Storage_Client_BagFrame_Currency[i]:SetText("#{FPLS_240715_68}")
							RichFlip_Storage_Client_BagFrame_CurrencyIcon[i]:Hide()
						end
						RichFlip_Storage_Client_BagFrame_Mask[i]:Hide()
					end		
					if nType == 1 then
						RichFlip_Storage_Client_BagFrame_BK[i]:SetProperty("Image", g_Storage_Image[2])
					elseif nType == 2 then
						RichFlip_Storage_Client_BagFrame_BK[i]:SetProperty("Image", g_Storage_Image[3])
					end	
				end
			end
		end				
	end
	
	RichFlip_Storage_Client_Currency:SetText(ScriptGlobal_Format("#L".."#{FPLS_240715_80}",g_dhdaibi))
	
	--上下页
	local maxPageNum = math.ceil(g_rewardcount/12)
	if maxPageNum<1 then
		maxPageNum = 1
	end

	if g_StoragePage == 1 then
		RichFlip_Storage_Client_PageUpBtn:Disable()
	else
		RichFlip_Storage_Client_PageUpBtn:Enable()
	end

	if g_StoragePage == maxPageNum then
		RichFlip_Storage_Client_PageDownDrawBtn:Disable()
	else
		RichFlip_Storage_Client_PageDownDrawBtn:Enable()
	end

	RichFlip_Storage_Client_PageNum_Text:SetText(ScriptGlobal_Format("#{FPLS_240715_78}", g_StoragePage,maxPageNum))
	
end
--=========================================================
--购买
--=========================================================
function RichFlip_DrawCard_Buy_BtnClicked()
	if g_totalbuynum >= 1000 then
		PushDebugMessage("#{FPLS_240715_172}")
		return
	end
	PushEvent("LUCKYLINE_OPEN_BUYDICE", g_totalbuynum)
end
--=========================================================
--分解
--=========================================================
function RichFlip_Storage_Client_Resolve_Click()
	LuckyLinePrepearCursor();
end

--=========================================================
--点击仓库物品
--=========================================================
function RichFlip_Storage_Client_BagFrame_ItemClicked(nIndex)
	if nIndex < 1 or nIndex > 12 then
		return
	end
	
	if g_rewardItemId[nIndex] <= 0 then
		return
	end
				
	local nShowItemId,nItemNum,nIsBind,nFenjie = DataPool:LuaFnGetLuckyLineChoujiangItemInfo(g_rewardItemId[nIndex])
	if nShowItemId == nil or nShowItemId <= 0 then
		return
	end
	
	if LuckyLineCheckMult() == 1 then --分解
		if nFenjie < 0 then
			PushDebugMessage("#{FPLS_240715_84}")
			return
		end
		PushEvent("LUCKYLINE_OPEN_MULIT_RESOLVE", g_rewardItemId[nIndex], g_rewardItemNum[nIndex], tonumber(g_StoragePage))
	else
		PushEvent("LUCKYLINE_OPEN_MULIT_GET", g_rewardItemId[nIndex], g_rewardItemNum[nIndex], tonumber(g_StoragePage))
	end
end

--=========================================================
--上一页
--=========================================================
function RichFlip_Storage_Client_PageUp()
	if g_curpage ~= 2 then
		return
	end
	if g_StoragePage > 1 then
		g_StoragePage = g_StoragePage - 1
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenStorage" )
			Set_XSCRIPT_ScriptID( 999441 )
    		Set_XSCRIPT_Parameter(0,g_StoragePage)
    		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end
--=========================================================
--下一页
--=========================================================
function RichFlip_Storage_Client_PageDown()
	if g_curpage ~= 2 then
		return
	end
	local maxPageNum = math.ceil(g_rewardcount/12)
	if g_StoragePage < maxPageNum then
		g_StoragePage = g_StoragePage + 1
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenStorage" )
			Set_XSCRIPT_ScriptID( 999441 )
    		Set_XSCRIPT_Parameter(0,g_StoragePage)
    		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

--=========================================================
--兑换界面刷新
--=========================================================
function RichFlip_Update_Client3()
	RichFlip_Description_Text:SetText("#{FPLS_240715_167}")
	local sumnum = DataPool:LuaFnGetLuckyLineShopItemInfoCount()
	local maxPageNum = math.ceil(sumnum/12)
	if maxPageNum<1 then
		maxPageNum = 1
	end
	
	if g_curShopPage <= 0 then
		g_curShopPage = 1
	end
	
	if g_curShopPage > maxPageNum then
		g_curShopPage = maxPageNum
	end
	
	local startidx = (g_curShopPage-1)*12+1
	local endidx = startidx + 12 - 1
	if endidx > sumnum then
		endidx = sumnum
	end
	
	local idx = startidx
	local limitidx = 1
	for i = 1, 12 do			
		RichFlip_Shop_Client_ShopFrame[i]:Hide()
				
		if idx <= endidx then
			RichFlip_Shop_Client_ShopFrame[i]:Show()
			RichFlip_Shop_Client_ShopFrame_LimitMark[i]:Hide()
			RichFlip_Shop_Client_ShopFrame_LimitBK[i]:Hide()
			RichFlip_Shop_Client_ShopFrame_SoldOut[i]:Hide()
			RichFlip_Shop_Client_ShopFrame_Mask[i]:Hide()
			RichFlip_Shop_Client_ShopFrame_FanpaiNum[i]:Hide()
				
			local nShowItemId,nItemNum,nIsBind,nMaxnum,nNeedDaibi,nFanpai = DataPool:LuaFnGetLuckyLineShopItemInfo(idx)
			
			if nShowItemId ~= nil and nShowItemId > 0 then
				local theAction = nil
				if nIsBind == 1 then
					theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
				else
					theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
				end
				if theAction ~= nil then
					RichFlip_Shop_Client_ShopFrame_Item[i]:SetActionItem(theAction:GetID())
					RichFlip_Shop_Client_ShopFrame_Name[i]:SetText(ScriptGlobal_Format("#{FPLS_240715_66}",theAction:GetName()))
				end
				--限量
				if nMaxnum > 0 then
					RichFlip_Shop_Client_ShopFrame_LimitMark[i]:Show()
					RichFlip_Shop_Client_ShopFrame_LimitBK[i]:Show()
					if g_ShopLimitData[limitidx] ~= nil and g_ShopLimitData[limitidx] >= 0 then
						local canbuy = nMaxnum - g_ShopLimitData[limitidx]
						if canbuy <= 0 then
							RichFlip_Shop_Client_ShopFrame_SoldOut[i]:Show() --售罄
							RichFlip_Shop_Client_ShopFrame_Mask[i]:Show()
						end
						RichFlip_Shop_Client_ShopFrame_LimitNum[i]:SetText(tostring(canbuy))
						limitidx = limitidx + 1
					end	
				end
				
				if nFanpai > 0 then
					RichFlip_Shop_Client_ShopFrame_FanpaiNum[i]:Show()
					RichFlip_Shop_Client_ShopFrame_FanpaiNum[i]:SetText(ScriptGlobal_Format("#{FPLS_240715_174}",nFanpai))
				end
				RichFlip_Shop_Client_ShopFrame_Currency[i]:SetText(ScriptGlobal_Format("#{FPLS_240715_99}",nNeedDaibi))
			end
			idx = idx + 1
		end
	end		
	RichFlip_Shop_Client_Currency:SetText(ScriptGlobal_Format("#L".."#{FPLS_240715_80}",g_dhdaibi))

	--上下页
	if g_curShopPage == 1 then
		RichFlip_Shop_Client_PageUpBtn:Disable()
	else
		RichFlip_Shop_Client_PageUpBtn:Enable()
	end

	if g_curShopPage == maxPageNum then
		RichFlip_Shop_Client_PageDownBtn:Disable()
	else
		RichFlip_Shop_Client_PageDownBtn:Enable()
	end

	RichFlip_Shop_Client_PageNum_Text:SetText(ScriptGlobal_Format("#{FPLS_240715_78}", g_curShopPage,maxPageNum))
	
end
--=========================================================
--上一页
--=========================================================
function RichFlip_Shop_Client_PageUp_Click()
	if g_curpage ~= 3 then
		return
	end
	
	if g_curShopPage > 1 then
		g_curShopPage = g_curShopPage - 1
		RichFlip_Update_Client3()
	end
end
--=========================================================
--下一页
--=========================================================
function RichFlip_Shop_Client_PageDown_Click()
	if g_curpage ~= 3 then
		return
	end
	local sumnum = DataPool:LuaFnGetLuckyLineShopItemInfoCount()
	local maxPageNum = math.ceil(sumnum/12)
	if g_curShopPage < maxPageNum then
		g_curShopPage = g_curShopPage + 1
		RichFlip_Update_Client3()
	end
end
--=========================================================
--兑换
--=========================================================
function RichFlip_Shop_Client_ShopFrame_ItemClicked(nIndex)
	local sumnum = DataPool:LuaFnGetLuckyLineShopItemInfoCount()
	local limitidx = 0
	local limitdata = -1
	local canbuy = 1
	local idx = (g_curShopPage-1)*12+nIndex
	local nShowItemId,nItemNum,nIsBind,nMaxnum,nNeedDaibi = DataPool:LuaFnGetLuckyLineShopItemInfo(idx)
	if nShowItemId ~= nil and nShowItemId > 0 then
		if nMaxnum > 0 then --限量
			for i = 1, sumnum do
				local _,_,_,maxnum,_ = DataPool:LuaFnGetLuckyLineShopItemInfo(i)
				if maxnum > 0 then 
					limitidx = limitidx + 1
					if idx == i then
						limitdata = g_ShopLimitData[limitidx]
						canbuy = nMaxnum-limitdata
						break;
					end
				end
			end
		end
	end
	if canbuy <= 0 then
		PushDebugMessage("#{FPLS_240715_109}")
		return
	end
	PushEvent("LUCKYLINE_OPEN_MULIT_BUY", idx, canbuy, g_dhdaibi)
end

function RichFlip_PageBtn_SwitchPage(nPage)
	if g_curpage == nPage then
		return
	end
	
	if ( IsWindowShow( "RichFlip_BuyDice" ) ) then
		CloseWindow( "RichFlip_BuyDice", true );
	end 
	if ( IsWindowShow( "RichFlip_MSplit" ) ) then
		CloseWindow( "RichFlip_MSplit", true );
	end 
	if ( IsWindowShow( "RichFlip_MReceive" ) ) then
		CloseWindow( "RichFlip_MReceive", true );
	end 
	if ( IsWindowShow( "RichFlip_MBuy" ) ) then
		CloseWindow( "RichFlip_MBuy", true );
	end 
	if ( IsWindowShow( "RichFlip_Reward" ) ) then
		CloseWindow( "RichFlip_Reward", true );
	end 		
	if nPage == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenUI" )
			Set_XSCRIPT_ScriptID( 999441 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif nPage == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenStorage" )
			Set_XSCRIPT_ScriptID( 999441 )
    		Set_XSCRIPT_Parameter(0,1)
    		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif nPage == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenShop" )
			Set_XSCRIPT_ScriptID( 999441 )
    		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif nPage == 4 then
		g_curpage = 4
		RichFlip_Update()
	end
end

--=========================================================
--关闭
--=========================================================
function RichFlip_Close()
	if ( IsWindowShow( "RichFlip_BuyDice" ) ) then
		CloseWindow( "RichFlip_BuyDice", true );
	end 
	if ( IsWindowShow( "RichFlip_MSplit" ) ) then
		CloseWindow( "RichFlip_MSplit", true );
	end 
	if ( IsWindowShow( "RichFlip_MReceive" ) ) then
		CloseWindow( "RichFlip_MReceive", true );
	end 
	if ( IsWindowShow( "RichFlip_MBuy" ) ) then
		CloseWindow( "RichFlip_MBuy", true );
	end 
	if ( IsWindowShow( "RichFlip_Reward" ) ) then
		CloseWindow( "RichFlip_Reward", true );
	end
	this:Hide()
end

function RichFlip_OnHiden()
	RichFlip_Close()
end
--=========================================================
--刷新位置
--=========================================================
function RichFlip_On_ResetPos()
	RichFlip_MainFrame_BK:SetProperty("UnifiedPosition", g_RichFlip_UnifiedPosition);
end


function RichFlip_Help_Clicked()
	PushEvent("CCSHOP_HELP", 224)
end


function RichFlip_DrawCard_Client_SingleDraw_Click()
	if g_curpage == 1 then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DrawOnce" )
			Set_XSCRIPT_ScriptID( 999441 )
    		Set_XSCRIPT_Parameter(0,0)
    		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	end
end

function RichFlip_DrawCard_Client_TenTimes_Click()
	if g_curpage == 1 then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DrawTenTimes" )
			Set_XSCRIPT_ScriptID( 999441 )
    		Set_XSCRIPT_Parameter(0,0)
    		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	end

end

function RichFlip_DrawCard_Client_NextRound_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "EnterNextRound" )
		Set_XSCRIPT_ScriptID( 999441 )
    	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()		
end
--领奖
function RichFlip_DrawCard_Client_ProgressClicked(nIndex)
	if nIndex < 1 or nIndex > 7 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetRoundReward" )
		Set_XSCRIPT_ScriptID( 999441 )
    	Set_XSCRIPT_Parameter(0,nIndex)
    	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()		
end


function RichFlip_DrawCard_Client_Preview_Click()
	PushEvent("LUCKYLINE_OPEN_PREVIEW")
end

--**********************************
--num：元素个数 bit：占位(1、2) t：元素表
--**********************************
function RichFlip_UICommandarry(num, bit, UIdataTbl)
	local retdatalist = {0}
	local perdatanumlist = {9, 4}
	local point = 1
	local bitdata = math.pow(10, bit) 
	local perdatanum = perdatanumlist[bit]
	
	if UIdataTbl ~= nil then
	
		for i = 1, num do
			retdatalist[i] = 0
			if UIdataTbl[point] > 0 then
			--PushDebugMessage(UIdataTbl[point])
				retdatalist[i] = math.mod(math.floor(UIdataTbl[point]/math.pow(bitdata, i-perdatanum*(point-1)-1)), bitdata)
			end		
			if i == perdatanum*point then
				point = point + 1
			end
		end			
	end

	return retdatalist;
end

function RichFlip_UpdateDress()
	local nItemCount = PlayerPackage:Lua_GetUnLockItemCount(g_SpecialItem)
	RichFlip_ClothPiece_PieceNumText:SetText(ScriptGlobal_Format("#{FPLS_240715_151}", nItemCount))
	if nItemCount >= g_SpecialItemNum then
		RichFlip_ClothPiece_GetBtn_Tip:Show()
		RichFlip_PageBtn_Sift4_Tip:Show()
	else
		RichFlip_ClothPiece_GetBtn_Tip:Hide()
		RichFlip_PageBtn_Sift4_Tip:Hide()
	end
end

function RichFlip_ClothPiece_GetCloth()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DressExchange" )
		Set_XSCRIPT_ScriptID( 999441 )
		Set_XSCRIPT_Parameter(0, 0);	
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end


function RichFlip_ClothPiece_Preview_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10128472)
		Set_XSCRIPT_Parameter(1, 276)
		Set_XSCRIPT_Parameter(2, 200)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function RichFlip_DrawCard_Client_Progress_Preview_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10128488)
		Set_XSCRIPT_Parameter(1, 277)
		Set_XSCRIPT_Parameter(2, 201)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end