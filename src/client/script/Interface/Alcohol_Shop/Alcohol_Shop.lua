local g_Alcohol_Shop_Frame_UnifiedPosition;

local g_nPriceItem =
{
	[1] = {Index = 39921579, nCnt = 10 ,nNeedYuanBao =500},
	[2] = {Index = 39921579, nCnt = 10	,nNeedYuanBao =1000},
	[3] = {Index = 39921579, nCnt = 25,nNeedYuanBao =2000},
	[4] = {Index = 39921579, nCnt = 35,nNeedYuanBao =4000},
};

local g_Alcohol_Shop_Begin	= 20200106
local g_Alcohol_Shop_End	= 20200123

-- MD值
local g_MD_CAIQUANSHOP_COST = 1747--猜拳商店每日元宝消耗数量 日清数据  --2019重开复用
local g_MD_CAIQUANDAIBI_A = 1732  --猜拳商店代币A  --2019重开复用
local g_MD_CAIQUANDAIBI_B = 1733  --猜拳商店代币B  --2019重开复用
local g_MD_CAIQUANSHOP_ZUIYI = 1753--猜拳商店醉意值  --2019重开复用
local g_MD_CAIQUANSHOP_CAIQUANSTATE = 1764--猜拳商店猜拳次数、猜拳状态  --2019重开复用

local g_objCared = -1
local g_nTargetID = -1
local g_nCurPage = -1

local g_AcctionItem_Buy={}
local g_AcctionItem_Price={}
local g_AcctionItem_PriceMoney={}
local g_AcctionItem_PriceCnt={}
local g_AcctionItem_PriceIcon={}
local g_AcctionItem_OrgMoney={}
local g_AcctionItem_RealMoney={}
local g_AcctionItem_MoneyNoDiscnt={}
local g_AcctionItem_MoneyIcon2={}
local g_CaiQuanImage={}
local g_ChuQuanButton={}
local g_CaiQuanButton={}
local g_AcctionItem_Mask={}
local g_AcctionItem_Line={}
local g_AcctionItem_IsNeedBind={}
local g_nMF =
{
	[1] = 2212,
	[2] = 2213,
	[3] = 2214,
	[4] = 2215,	
}	
local g_nType = 0
local g_nJiuLing =8
local g_nChuQuan =1
local g_nCaiQuanRes =0

local g_JiuLingStr =
{
	[2] ="#{ZHHD1_181128_60}",
	[3] ="#{ZHHD1_181128_61}",
	[4] ="#{ZHHD1_181128_62}",
	[5] ="#{ZHHD1_181128_63}",
	[6] ="#{ZHHD1_181128_64}",
	[7] ="#{ZHHD1_181128_65}",
	[8] ="#{ZHHD1_181128_66}",
	[9] ="#{ZHHD1_181128_67}",
	[10] ="#{ZHHD1_181128_68}",
}

local g_ChuQuanStr =
{
	[1] ="#{ZHHD1_181128_71}",
	[2] ="#{ZHHD1_181128_72}",
	[3] ="#{ZHHD1_181128_73}",
	[4] ="#{ZHHD1_181128_74}",
	[5] ="#{ZHHD1_181128_75}",
}

local g_ResImage = 
{
	[1] = "set:RedPacket2 image:WanSheng",
	[2] = "set:RedPacket2 image:Ping",
	[3] = "set:RedPacket2 image:ShiBai",
}

local g_PirceImage = 
{
	[1] = "set:RedPacket2 image:KeLingqu",
	[2] = "set:RedPacket2 image:YiLingqu",
	[3] = "set:RedPacket2 image:WeiLingqu",
}

local g_ResText = 
{
	[1] = "#{ZHHD1_181128_79}",
	[2] = "#{ZHHD1_181128_80}",
	[3] = "#{ZHHD1_181128_81}",
}

local g_ResText2 = 
{
	[1] = "#{ZHHD1_181128_177}",
	[2] = "#{ZHHD1_181128_178}",
	[3] = "#{ZHHD1_181128_179}",
}

local g_ZuiYiMaxLevel = 11
local g_ZuiYiLevel =
{
	[0] = {min=0, 		max=199,		discount=95,	pic="set:Alcohol8 image:Sale95", showtips="9.5"},
	[1] = {min=200, 	max=599,		discount=91,	pic="set:Alcohol5 image:Sale91", showtips="9.1"},
	[2] = {min=600, 	max=1199, 	discount=88,	pic="set:Alcohol5 image:Sale88", showtips="8.8"},
	[3] = {min=1200, 	max=1999, 	discount=85,	pic="set:Alcohol8 image:Sale85", showtips="8.5"},
	[4] = {min=2000, 	max=2999,		discount=82,	pic="set:Alcohol8 image:Sale82", showtips="8.2"},
	[5] = {min=3000,	max=4099,		discount=79,	pic="set:Alcohol5 image:Sale79", showtips="7.9"},
	[6] = {min=4100,	max=5299,		discount=76,	pic="set:Alcohol7 image:Sale76", showtips="7.6"},
	[7] = {min=5300,	max=6599,		discount=74,	pic="set:Alcohol7 image:Sale74", showtips="7.4"},
	[8] = {min=6600,	max=7999,		discount=72,	pic="set:Alcohol5 image:Sale72", showtips="7.2"},
	[9] = {min=8000,	max=9499,		discount=71,	pic="set:Alcohol7 image:Sale71", showtips="7.1"},
	[10]= {min=9500,	max=10999,	discount=70,	pic="set:Alcohol5 image:Sale70", showtips="7"},
	[11]= {min=11000,	max=11000,	discount=69,	pic="set:Alcohol5 image:Sale69", showtips="6.9"},
}

g_GetPrice_MF =
{
	[1] =2212,
	[2] =2213,
	[3] =2214,
	[4] =2215,
}	

local g_JiuLingImage = 
{
	[2] = "set:Alcohol3 image:Brother_Normal",
	[3] = "set:Alcohol1 image:Three_Normal",
	[4] = "set:Alcohol2 image:Four_Normal",
	[5] = "set:Alcohol2 image:Five_Normal",
	[6] = "set:Alcohol2 image:Six_Normal",
	[7] = "set:Alcohol2 image:Seven_Normal",
	[8] = "set:Alcohol3 image:Eight_Normal",
	[9] = "set:Alcohol2 image:Nine_Normal",
	[10] = "set:Alcohol2 image:Red_Normal",
}

local g_ChuQuanResImage = 
{
	[1] = "set:Alcohol2 image:Num_One",
	[2] = "set:Alcohol2 image:Num_Two",
	[3] = "set:Alcohol2 image:Num_Three",
	[4] = "set:Alcohol2 image:Num_Four",
	[5] = "set:Alcohol2 image:Num_Five",			
}

local g_ShouShiLImage = 
{
	[1] = 
	{
		Hover = "set:Alcohol4 image:Hand1_L_Hover",
		Normal = "set:Alcohol4 image:Hand1_L_Normal",
		Push = "set:Alcohol4 image:Hand1_L_Push",
	},
	[2] = 
	{
		Hover = "set:Alcohol4 image:Hand2_L_Hover",
		Normal = "set:Alcohol4 image:Hand2_L_Normal",
		Push = "set:Alcohol4 image:Hand2_L_Push",
	},
	[3] = 
	{
		Hover = "set:Alcohol4 image:Hand3_L_Hover",
		Normal = "set:Alcohol3 image:Hand3_L_Normal",
		Push = "set:Alcohol3 image:Hand3_L_Push",
	},
	[4] = 
	{
		Hover = "set:Alcohol3 image:Hand4_L_Hover",
		Normal = "set:Alcohol3 image:Hand4_L_Normal",
		Push = "set:Alcohol3 image:Hand4_L_Push",
	},
	[5] = 
	{
		Hover = "set:Alcohol3 image:Hand5_L_Hover",
		Normal = "set:Alcohol3 image:Hand5_L_Normal",
		Push = "set:Alcohol2 image:Hand5_L_Push",
	},		
}

local g_ShouShiRImage = 
{
	[1] = 
	{
		Hover = "set:Alcohol4 image:Hand1_R_Hover",
		Normal = "set:Alcohol4 image:Hand1_R_Normal",
		Push = "set:Alcohol4 image:Hand1_R_Push",
	},
	[2] = 
	{
		Hover = "set:Alcohol4 image:Hand2_R_Hover",
		Normal = "set:Alcohol4 image:Hand2_R_Normal",
		Push = "set:Alcohol4 image:Hand2_R_Push",
	},
	[3] = 
	{
		Hover = "set:Alcohol3 image:Hand3_R_Hover",
		Normal = "set:Alcohol3 image:Hand3_R_Normal",
		Push = "set:Alcohol3 image:Hand3_R_Push",
	},
	[4] = 
	{
		Hover = "set:Alcohol3 image:Hand4_R_Hover",
		Normal = "set:Alcohol3 image:Hand4_R_Normal",
		Push = "set:Alcohol3 image:Hand4_R_Push",
	},
	[5] = 
	{
		Hover = "set:Alcohol2 image:Hand5_R_Hover",
		Normal = "set:Alcohol2 image:Hand5_R_Normal",
		Push = "set:Alcohol2 image:Hand5_R_Push",
	},		
}


local g_MaleImage = 
{
	[1] = "set:Alcohol7 image:man_smile",
	[2] = "set:Alcohol7 image:man_normal",
	[3] = "set:Alcohol7 image:man_cry",
}

local g_FeMaleImage = 
{
	[1] = "set:Alcohol7 image:woman_smile",
	[2] = "set:Alcohol7 image:woman_normal",
	[3] = "set:Alcohol7 image:woman_cry",
}

local g_JingNianImage = 
{
	[1] = "set:Alcohol5 image:nian_cry",	
	[2] = "set:Alcohol2 image:nian_normal",
	[3] = "set:Alcohol6 image:nian_smile",	
}

--===============================================
-- OnLoad()
--===============================================
function Alcohol_Shop_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_CCSHOP")	
	this:RegisterEvent("UPDATE_CCSHOP")		
	this:RegisterEvent("CCSHOP_CHUQUANCONFIRM")			
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function Alcohol_Shop_OnLoad()
	g_AcctionItem_Buy[1] = Alcohol_Shop_DownBegin_Item1
	g_AcctionItem_Buy[2] = Alcohol_Shop_DownBegin_Item2
	g_AcctionItem_Buy[3] = Alcohol_Shop_DownBegin_Item3
	g_AcctionItem_Buy[4] = Alcohol_Shop_DownBegin_Item4
	g_AcctionItem_Buy[5] = Alcohol_Shop_DownBegin_Item5

	g_AcctionItem_OrgMoney[1] = Alcohol_Shop_DownBegin_Item1_text1
	g_AcctionItem_OrgMoney[2] = Alcohol_Shop_DownBegin_Item2_text1
	g_AcctionItem_OrgMoney[3] = Alcohol_Shop_DownBegin_Item3_text1
	g_AcctionItem_OrgMoney[4] = Alcohol_Shop_DownBegin_Item4_text1
	g_AcctionItem_OrgMoney[5] = Alcohol_Shop_DownBegin_Item5_text1

	g_AcctionItem_RealMoney[1] = Alcohol_Shop_DownBegin_Item1_text2
	g_AcctionItem_RealMoney[2] = Alcohol_Shop_DownBegin_Item2_text2
	g_AcctionItem_RealMoney[3] = Alcohol_Shop_DownBegin_Item3_text2
	g_AcctionItem_RealMoney[4] = Alcohol_Shop_DownBegin_Item4_text2
	g_AcctionItem_RealMoney[5] = Alcohol_Shop_DownBegin_Item5_text2

	g_AcctionItem_MoneyNoDiscnt[1] = Alcohol_Shop_DownBegin_Item1_text3
	g_AcctionItem_MoneyNoDiscnt[2] = Alcohol_Shop_DownBegin_Item2_text3
	g_AcctionItem_MoneyNoDiscnt[3] = Alcohol_Shop_DownBegin_Item3_text3
	g_AcctionItem_MoneyNoDiscnt[4] = Alcohol_Shop_DownBegin_Item4_text3
	g_AcctionItem_MoneyNoDiscnt[5] = Alcohol_Shop_DownBegin_Item5_text3
	
	g_AcctionItem_Mask[1] = Alcohol_Shop_DownBegin_Item1_Mask
	g_AcctionItem_Mask[2] = Alcohol_Shop_DownBegin_Item2_Mask
	g_AcctionItem_Mask[3] = Alcohol_Shop_DownBegin_Item3_Mask
	g_AcctionItem_Mask[4] = Alcohol_Shop_DownBegin_Item4_Mask
	g_AcctionItem_Mask[5] = Alcohol_Shop_DownBegin_Item5_Mask

	g_AcctionItem_Line[1] = Alcohol_Shop_DownBegin_Item1_text1Line
	g_AcctionItem_Line[2] = Alcohol_Shop_DownBegin_Item2_text1Line
	g_AcctionItem_Line[3] = Alcohol_Shop_DownBegin_Item3_text1Line
	g_AcctionItem_Line[4] = Alcohol_Shop_DownBegin_Item4_text1Line
	g_AcctionItem_Line[5] = Alcohol_Shop_DownBegin_Item5_text1Line
	
	g_AcctionItem_IsNeedBind[1] = Alcohol_Shop_DownBegin_Item1_Unbind
	g_AcctionItem_IsNeedBind[2] = Alcohol_Shop_DownBegin_Item2_Unbind
	g_AcctionItem_IsNeedBind[3] = Alcohol_Shop_DownBegin_Item3_Unbind
	g_AcctionItem_IsNeedBind[4] = Alcohol_Shop_DownBegin_Item4_Unbind
	g_AcctionItem_IsNeedBind[5] = Alcohol_Shop_DownBegin_Item5_Unbind

	g_AcctionItem_Price[1] = Alcohol_Shop_DownBegin_Down_Item1
	g_AcctionItem_Price[2] = Alcohol_Shop_DownBegin_Down_Item2
	g_AcctionItem_Price[3] = Alcohol_Shop_DownBegin_Down_Item3
	g_AcctionItem_Price[4] = Alcohol_Shop_DownBegin_Down_Item4

	g_AcctionItem_PriceMoney[1] = Alcohol_Shop_DownBegin_Down_Item1Text1
	g_AcctionItem_PriceMoney[2] = Alcohol_Shop_DownBegin_Down_Item2Text1
	g_AcctionItem_PriceMoney[3] = Alcohol_Shop_DownBegin_Down_Item3Text1
	g_AcctionItem_PriceMoney[4] = Alcohol_Shop_DownBegin_Down_Item4Text1

	g_AcctionItem_PriceCnt[1] = Alcohol_Shop_DownBegin_Down_Item1Text
	g_AcctionItem_PriceCnt[2] = Alcohol_Shop_DownBegin_Down_Item2Text
	g_AcctionItem_PriceCnt[3] = Alcohol_Shop_DownBegin_Down_Item3Text
	g_AcctionItem_PriceCnt[4] = Alcohol_Shop_DownBegin_Down_Item4Text


	g_AcctionItem_PriceIcon[1] = Alcohol_Shop_DownBegin_Down_Item1Image
	g_AcctionItem_PriceIcon[2] = Alcohol_Shop_DownBegin_Down_Item2Image
	g_AcctionItem_PriceIcon[3] = Alcohol_Shop_DownBegin_Down_Item3Image
	g_AcctionItem_PriceIcon[4] = Alcohol_Shop_DownBegin_Down_Item4Image

	g_CaiQuanImage[1] = Alcohol_Shop_Down_PlayImage1
	g_CaiQuanImage[2] = Alcohol_Shop_Down_PlayImage2
	g_CaiQuanImage[3] = Alcohol_Shop_Down_PlayImage3
	g_CaiQuanImage[4] = Alcohol_Shop_Down_PlayImage4
	g_CaiQuanImage[5] = Alcohol_Shop_Down_PlayImage5
	g_CaiQuanImage[6] = Alcohol_Shop_Down_PlayImage6
	g_CaiQuanImage[7] = Alcohol_Shop_Down_PlayImage7
	g_CaiQuanImage[8] = Alcohol_Shop_Down_PlayImage8
	g_CaiQuanImage[9] = Alcohol_Shop_Down_PlayImage9

	g_CaiQuanButton[1] = Alcohol_Shop_Down_PlayText1
	g_CaiQuanButton[2] = Alcohol_Shop_Down_PlayText2
	g_CaiQuanButton[3] = Alcohol_Shop_Down_PlayText3
	g_CaiQuanButton[4] = Alcohol_Shop_Down_PlayText4
	g_CaiQuanButton[5] = Alcohol_Shop_Down_PlayText5
	g_CaiQuanButton[6] = Alcohol_Shop_Down_PlayText6
	g_CaiQuanButton[7] = Alcohol_Shop_Down_PlayText7
	g_CaiQuanButton[8] = Alcohol_Shop_Down_PlayText8
	g_CaiQuanButton[9] = Alcohol_Shop_Down_PlayText9	
	
	g_ChuQuanButton[1] = Alcohol_Shop_Down_PlayGameButton1
	g_ChuQuanButton[2] = Alcohol_Shop_Down_PlayGameButton2
	g_ChuQuanButton[3] = Alcohol_Shop_Down_PlayGameButton3
	g_ChuQuanButton[4] = Alcohol_Shop_Down_PlayGameButton4
	g_ChuQuanButton[5] = Alcohol_Shop_Down_PlayGameButton5

	g_Alcohol_Shop_Frame_UnifiedPosition = Alcohol_Shop:GetProperty("UnifiedPosition");
	Alcohol_Shop_DownVictory_VS_Animate:Hide()	
end

--===============================================
-- OnEvent()
--===============================================
function Alcohol_Shop_OnEvent( event )

	if (event == "UI_COMMAND") and (arg0 == "20181205") then
		g_nType = Get_XParam_INT(0)		
		if g_nType == 0 then
			
		elseif g_nType == 1 then
			g_nTargetID = Get_XParam_INT(1);
			g_objCared = Target:GetServerId2ClientId(g_nTargetID);
			Alcohol_Shop_ClearData()
			Alcohol_Shop_BeginCaiQuan()
			this:Show()
		elseif g_nType == 2 then
			g_nCaiQuanRes = Get_XParam_INT(1)		
			local g_nNpcJiuLing = Get_XParam_INT(2)		
			local g_nNpcChuQuan = Get_XParam_INT(3)		
			local isFull = Get_XParam_INT(4)		
			local isAnimate = Get_XParam_INT(5)		
			Alcohol_Shop_EndCaiQuan(g_nNpcJiuLing,g_nNpcChuQuan,isFull,isAnimate)			
		elseif g_nType == 3 then
			Alcohol_Shop_FirstShow()		
		elseif g_nType == 4 then			
			Alcohol_Shop_RefreshNum()
		end
	elseif event == "OPEN_CCSHOP" then
		Alcohol_Shop_FirstShow()
		this:Show()
	elseif event == "UPDATE_CCSHOP" then
		if arg0 == "0" then
			Alcohol_Shop_FirstShow()
			this:Show()	
		end	
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Alcohol_Shop_Close()
	elseif event == "ADJEST_UI_POS" then
		Alcohol_Shop_Frame_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Alcohol_Shop_Frame_On_ResetPos()
	end
end

--显示可购买物品和奖励物品
function Alcohol_Shop_FirstShow()
	g_nCurPage = 1
	this:CareObject(-1, 1, "Alcohol_Shop");
	Alcohol_Shop_DragTitle:SetText("#{ZHHD1_181128_21}")
		
	Alcohol_Shop_Client:Show()
	Alcohol_Shop_CoverClient:Hide()
	for i=1,4 do
		DataPool:Lua_SetCCShopActionItem(4+i,g_nPriceItem[i].Index,g_nPriceItem[i].nCnt)	
	end	
	DataPool:Lua_UpdateCCShopActionItem()

	for i=1, 5 do
		local theAction = EnumAction( i-1, "ccshop_item");
		if theAction:GetID() ~= 0 then
			g_AcctionItem_Buy[i]:SetActionItem( theAction:GetID() );
		else
			g_AcctionItem_Buy[i]:SetActionItem( -1 );
		end
	end

	for i=6, 9 do
		local theAction = EnumAction( i-1, "ccshop_item");
		if theAction:GetID() ~= 0 then
			g_AcctionItem_Price[i-5]:SetActionItem( theAction:GetID() );
		else
			g_AcctionItem_Price[i-5]:SetActionItem( -1 );
		end
	end		
	
	--醉意值展示
	local nLevel =    Alcohol_Shop_ShowZuiYi()
 	Alcohol_Shop_TopImage:SetProperty("Image" , g_ZuiYiLevel[nLevel].pic)
	--代币类型
	for i=1,5 do
		local nItemId,nType,nCostMoney,nIsBuy,nGiveCnt,nIsDiscount,nIsNeedBind = DataPool:Lua_GetCCShopItemPro(i-1)
		--if nLevel == 0 then
		--	nIsDiscount = 0--初始就有折扣，所以屏蔽默认折扣0
		--end
		if nIsDiscount == 0 then
			g_AcctionItem_Line[i]:Hide()
			if nType == 1 then --元宝
				g_AcctionItem_MoneyNoDiscnt[i]:SetText(ScriptGlobal_Format("#{ZHHD1_181128_184}",nCostMoney))
				g_AcctionItem_OrgMoney[i]:SetText("")
				g_AcctionItem_RealMoney[i]:SetText("")
			elseif nType == 2 then --代币
				g_AcctionItem_MoneyNoDiscnt[i]:SetText(ScriptGlobal_Format("#{ZHHD1_181128_185}",nCostMoney))
				g_AcctionItem_OrgMoney[i]:SetText("")			
				g_AcctionItem_RealMoney[i]:SetText("")			
			end			
		else
			g_AcctionItem_Line[i]:Show()
			if nType == 1 then --元宝
				g_AcctionItem_MoneyNoDiscnt[i]:SetText("")		
				g_AcctionItem_OrgMoney[i]:SetText(ScriptGlobal_Format("#{ZHHD1_181128_184}",nCostMoney))
				g_AcctionItem_RealMoney[i]:SetText(ScriptGlobal_Format("#{ZHHD1_181128_184}",math.floor(nCostMoney*g_ZuiYiLevel[nLevel].discount/100)))
			elseif nType == 2 then --代币
				g_AcctionItem_MoneyNoDiscnt[i]:SetText("")		
				g_AcctionItem_OrgMoney[i]:SetText(ScriptGlobal_Format("#{ZHHD1_181128_185}",nCostMoney))
				g_AcctionItem_RealMoney[i]:SetText(ScriptGlobal_Format("#{ZHHD1_181128_185}",math.floor(nCostMoney*g_ZuiYiLevel[nLevel].discount/100)))			
			end
		end
		if nIsBuy == 1 then
			g_AcctionItem_Mask[i]:Show()
		else
			g_AcctionItem_Mask[i]:Hide()
		end
		if nIsNeedBind == 0 then
			g_AcctionItem_IsNeedBind[i]:Show()
		else
			g_AcctionItem_IsNeedBind[i]:Hide()
		end
	end	
	
	   
	--每日元宝消耗
	local nCostToday = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANSHOP_COST)
	Alcohol_Shop_DownBegin_DownBKText:SetText(ScriptGlobal_Format("#{ZHHD1_181128_169}",nCostToday))
	for i=1,4 do
		local IsHaveGetPrice = Pneuma:GetMF(g_GetPrice_MF[i])		
		local isCanGetPirce = 0
		if nCostToday >= g_nPriceItem[i].nNeedYuanBao then
			isCanGetPirce = 1 
		end
		--g_AcctionItem_PriceMoney[i]:SetText(g_nPriceItem[i].nNeedYuanBao)
		--g_AcctionItem_PriceCnt[i]:SetText("*"..g_nPriceItem[i].nCnt)
		if isCanGetPirce == 1 then
			if IsHaveGetPrice == 0 then
				g_AcctionItem_PriceIcon[i]:SetProperty("Image" , g_PirceImage[1])
			else
				g_AcctionItem_PriceIcon[i]:SetProperty("Image" , g_PirceImage[2])
			end
		else
			g_AcctionItem_PriceIcon[i]:SetProperty("Image" , g_PirceImage[3])
		end
	end	
	
	--显示刷新次数和tips
	local nData = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANSHOP_CAIQUANSTATE)
	local nShuaXinCnt = math.mod(nData, 10000)
	Alcohol_Shop_DownBegin_textBK_text:SetText(ScriptGlobal_Format("#{ZHHD1_181128_214}", nShuaXinCnt))	
	Alcohol_Shop_DownBegin_textBK_text:SetToolTip(ScriptGlobal_Format("#{ZHHD1_181128_215}", nShuaXinCnt))	
	
	--屠苏酒数量
	local nTSJCnt = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANDAIBI_B)	
	Alcohol_Shop_Icon2Num:SetText(ScriptGlobal_Format("#{ZHHD1_181128_160}",nTSJCnt))
	
	--贺韶光数量
	local nHSGCnt = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANDAIBI_A)	
	Alcohol_Shop_Icon3Num:SetText(ScriptGlobal_Format("#{ZHHD1_181128_161}",nHSGCnt))
		
	--吉祥符数量
	--local nJXFCnt = DataPool:GetPlayerMission_DataRound(1759)	
	--Alcohol_Shop_Icon1Num:SetText(ScriptGlobal_Format("#{ZHHD1_181128_159}",nJXFCnt))	
	
end

--开始猜拳的页签
function Alcohol_Shop_BeginCaiQuan()
	g_nCurPage = 2
	this:CareObject(g_objCared, 1, "Alcohol_Shop");
	Alcohol_Shop_DragTitle:SetText("#{ZHHD1_181128_212}")
	Alcohol_Shop_ClearData()
	Alcohol_Shop_Client:Hide()
	Alcohol_Shop_CoverClient:Show()
	Alcohol_Shop_Cover1:Show()
	Alcohol_Shop_Down_Title:Show()
	Alcohol_Shop_CoverHelp:Show()
	Alcohol_Shop_Ok:Show()
	Alcohol_Shop_Shop:Show()	
	Alcohol_Shop_Cover2:Hide()	
	Alcohol_Shop_ProgressWindow:Show()
	Alcohol_Shop_Cover_BK2:Show()
	Alcohol_Shop_BtnCover:Hide()
	Alcohol_Shop_CoverIcon:Show()
	Alcohol_Shop_CoverIconNum:Show()
	Alcohol_Shop_CoverIconNum2:Show()
	
	local iSexy = Player:GetMySex()
	if iSexy==1 then  --男
		Alcohol_Shop_Man1:SetProperty("Image" , g_MaleImage[2])		
	else --女
		Alcohol_Shop_Man1:SetProperty("Image" , g_FeMaleImage[2])		
	end
	Alcohol_Shop_Man2:SetProperty("Image" , g_JingNianImage[2])		
	
	for i=1,9 do
		g_CaiQuanButton[i]:SetCheck(0)
	end
	
	for i=1,5 do
		g_ChuQuanButton[i]:SetCheck(0)
	end

	--屠苏酒数量
	local nTSJCnt = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANDAIBI_B)	
	Alcohol_Shop_CoverIconNum:SetText(ScriptGlobal_Format("#{ZHHD1_181128_203}",nTSJCnt))	
	
	--醉意值展示
	Alcohol_Shop_ShowZuiYi()
end

function Alcohol_Shop_CaiQuanOpenClick()
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay >= g_Alcohol_Shop_Begin and curDay <= g_Alcohol_Shop_End then
	else
		PushDebugMessage("#{RACL_181206_443}")
		return
	end
	
	--if DataPool:Lua_IsMissionHaveDone(1914) ~= 1 then
	--	PushDebugMessage("#{RACL_181206_637}")
	--	return
	--end
	
	AutoRuntoTargetExWithName(242, 269, 0, "景年")
end

function Alcohol_Shop_ClearData()
	g_nJiuLing =0
	g_nChuQuan =0
	g_nCaiQuanRes =0
end

function Alcohol_Shop_Close()
	g_objCared = -1;
	this:CareObject(g_objCared, 1, "Alcohol_Shop");
	
	Alcohol_Shop_ClearData()
	this:Hide()
end

function Alcohol_Shop_ShowZuiYi()
	--醉意值展示
	local nZuiYiValue = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANSHOP_ZUIYI)
	local nLevel = 0
	for i=0,g_ZuiYiMaxLevel do
		if nZuiYiValue >= g_ZuiYiLevel[i].min and nZuiYiValue <= g_ZuiYiLevel[i].max then
			nLevel = i
			break;
		end
	end		
	
	--左\右侧折扣图标
	if nZuiYiValue >= g_ZuiYiLevel[g_ZuiYiMaxLevel].max then
		nLevel = g_ZuiYiMaxLevel
		Alcohol_Shop_SaleImage1:SetProperty("Image" , "")		
		Alcohol_Shop_SaleImage2:SetProperty("Image" , g_ZuiYiLevel[nLevel].pic)			
		Alcohol_Shop_ProgressNum:SetText(ScriptGlobal_Format("#{ZHHD1_181128_172}",nZuiYiValue,g_ZuiYiLevel[nLevel].min))
		Alcohol_Shop_Progress:SetProgress(nZuiYiValue, g_ZuiYiLevel[nLevel].min)				
		Alcohol_Shop_SaleImage1:SetToolTip("")						
		Alcohol_Shop_SaleImage2:SetToolTip(ScriptGlobal_Format("#{ZHHD1_181128_190}",g_ZuiYiLevel[nLevel].min))		
		Alcohol_Shop_Progress:SetToolTip(ScriptGlobal_Format("#{ZHHD1_181128_213}",nZuiYiValue,g_ZuiYiLevel[nLevel].showtips,g_ZuiYiLevel[nLevel].min))							
	else
		Alcohol_Shop_SaleImage1:SetProperty("Image" , g_ZuiYiLevel[nLevel].pic)		
		Alcohol_Shop_SaleImage2:SetProperty("Image" , g_ZuiYiLevel[nLevel+1].pic)		
		Alcohol_Shop_ProgressNum:SetText(ScriptGlobal_Format("#{ZHHD1_181128_172}",nZuiYiValue,g_ZuiYiLevel[nLevel+1].min))
		Alcohol_Shop_Progress:SetProgress(nZuiYiValue, g_ZuiYiLevel[nLevel+1].min)				
		Alcohol_Shop_SaleImage1:SetToolTip("#{ZHHD1_181128_189}")	
		Alcohol_Shop_SaleImage2:SetToolTip(ScriptGlobal_Format("#{ZHHD1_181128_190}",g_ZuiYiLevel[nLevel+1].min))			
		Alcohol_Shop_Progress:SetToolTip(ScriptGlobal_Format("#{ZHHD1_181128_213}",nZuiYiValue,g_ZuiYiLevel[nLevel+1].showtips,g_ZuiYiLevel[nLevel+1].min))							
	end
		
	return nLevel
end

function Alcohol_Shop_Frame_On_ResetPos()
	 Alcohol_Shop:SetProperty("UnifiedPosition", g_Alcohol_Shop_Frame_UnifiedPosition)
end



function Alcohol_Shop_JiuLingClick(nIndex)	
	for i=1,9 do
		g_CaiQuanButton[i]:SetCheck(0)
	end
	if g_nCurPage == 3 then
		g_CaiQuanButton[g_nJiuLing-1]:SetCheck(1)
		return
	end
	g_CaiQuanButton[nIndex]:SetCheck(1)
	g_nJiuLing =nIndex+1
end

function Alcohol_Shop_ChuQuanClick(nIndex)	
	for i=1,5 do
		g_ChuQuanButton[i]:SetCheck(0)
	end
	if g_nCurPage == 3 then
		g_ChuQuanButton[g_nChuQuan]:SetCheck(1)
		return
	end	
	g_ChuQuanButton[nIndex]:SetCheck(1)
	g_nChuQuan=nIndex
end

function Alcohol_Shop_ChuQuanOK()
	if g_nJiuLing == 0 then
		PushDebugMessage("#{ZHHD1_181128_92}")
		return
	end

	if g_nChuQuan == 0 then
		PushDebugMessage("#{ZHHD1_181128_91}")
		return
	end
	
	if g_nChuQuan + 1 > g_nJiuLing or g_nChuQuan + 5 < g_nJiuLing then		
		PushEvent("CCSHOP_CHUQUANCONFIRM",g_nJiuLing,g_nChuQuan)
		return
	end
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ChuQuanOk")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,g_nTargetID) 
			Set_XSCRIPT_Parameter(1,g_nJiuLing) 
			Set_XSCRIPT_Parameter(2,g_nChuQuan) 			
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()		
end


function Alcohol_Shop_EndCaiQuan(g_nNpcJiuLing,g_nNpcChuQuan,isFull,isAnimate)
	g_nCurPage = 3
	Alcohol_Shop_DragTitle:SetText("#{ZHHD1_181128_212}")
	Alcohol_Shop_Client:Hide()
	Alcohol_Shop_CoverClient:Show()
	Alcohol_Shop_Cover1:Show()
	Alcohol_Shop_Down_Title:Hide()
	Alcohol_Shop_CoverHelp:Hide()
	Alcohol_Shop_Ok:Hide()
	Alcohol_Shop_Shop:Hide()
	Alcohol_Shop_Cover2:Show()	
	Alcohol_Shop_ProgressWindow:Show()
	Alcohol_Shop_Cover_BK2:Hide()
	Alcohol_Shop_BtnCover:Show()	
	Alcohol_Shop_CoverIcon:Hide()
	Alcohol_Shop_CoverIconNum:Hide()	
	Alcohol_Shop_CoverIconNum2:Hide()
	
	Alcohol_Shop_DownVictoryLeftText1:SetProperty("Image" , g_ChuQuanResImage[g_nChuQuan])
	Alcohol_Shop_DownVictoryLeftText2:SetProperty("Image" , g_JiuLingImage[g_nJiuLing])
	Alcohol_Shop_DownVictoryRightText1:SetProperty("Image" , g_ChuQuanResImage[g_nNpcChuQuan])
	Alcohol_Shop_DownVictoryRightText2:SetProperty("Image" , g_JiuLingImage[g_nNpcJiuLing])

	Alcohol_Shop_DownVictoryLeftButton:SetProperty("Image",g_ShouShiLImage[g_nChuQuan].Normal)
	Alcohol_Shop_DownVictoryRightButton:SetProperty("Image",g_ShouShiRImage[g_nNpcChuQuan].Normal)
	
	Alcohol_Shop_DownVictory_VS:SetProperty("Image" , g_ResImage[g_nCaiQuanRes])

	local iSexy = Player:GetMySex()
	if iSexy==1 then  --男
		Alcohol_Shop_Man1:SetProperty("Image" , g_MaleImage[g_nCaiQuanRes])		
	else --女
		Alcohol_Shop_Man1:SetProperty("Image" , g_FeMaleImage[g_nCaiQuanRes])		
	end
	Alcohol_Shop_Man2:SetProperty("Image" , g_JingNianImage[g_nCaiQuanRes])		
		
	if isFull == 0 then
		Alcohol_Shop_DownVictory_Text:SetText(g_ResText[g_nCaiQuanRes])
	elseif isFull == 1 then
		Alcohol_Shop_DownVictory_Text:SetText(g_ResText2[g_nCaiQuanRes])
	end	
	
	if isAnimate == 1 then
		Alcohol_Shop_DownVictory_VS_Animate:Show()
		Alcohol_Shop_DownVictory_VS_Animate:Play(true)		
	else
		Alcohol_Shop_DownVictory_VS_Animate:Hide()	
	end
	
	--屠苏酒数量
	local nTSJCnt = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANDAIBI_B)	
	Alcohol_Shop_CoverIconNum:SetText(ScriptGlobal_Format("#{ZHHD1_181128_203}",nTSJCnt))			
		
	--醉意值展示
	Alcohol_Shop_ShowZuiYi()
end


function Alcohol_Shop_BuyItemClicked(nIndex)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItem")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,nIndex) 
			Set_XSCRIPT_Parameter(1,1) 			
			Set_XSCRIPT_Parameter(2,0) 			
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()		
end


function Alcohol_Shop_RefreshItemClick()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("RefreshBuyItem")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,1) 			
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
end

function Alcohol_Shop_GetPirceClick(nIndex)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetDayItemPrice")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,nIndex) 
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
end

function Alcohol_Shop_UpdateHaveGetPirce()
	
end

function Alcohol_Shop_ZaiLaiYiJu()
		Alcohol_Shop_ClearData()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("CheckCaiQuanBegin")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,g_nTargetID) 				
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
end

function Alcohol_Shop_RefreshNum()
	--屠苏酒数量
	local nTSJCnt = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANDAIBI_B)	
	Alcohol_Shop_Icon2Num:SetText(ScriptGlobal_Format("#{ZHHD1_181128_160}",nTSJCnt))
	
	--贺韶光数量
	local nHSGCnt = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANDAIBI_A)	
	Alcohol_Shop_Icon3Num:SetText(ScriptGlobal_Format("#{ZHHD1_181128_161}",nHSGCnt))
		
	--吉祥符数量
	--local nJXFCnt = DataPool:GetPlayerMission_DataRound(1759)	
	--Alcohol_Shop_Icon1Num:SetText(ScriptGlobal_Format("#{ZHHD1_181128_159}",nJXFCnt))

	--屠苏酒数量
	Alcohol_Shop_CoverIconNum:SetText(ScriptGlobal_Format("#{ZHHD1_181128_203}",nTSJCnt))	
	
	--显示刷新次数和tips
	local nData = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANSHOP_CAIQUANSTATE)
	local nShuaXinCnt = math.mod(nData, 10000)
	Alcohol_Shop_DownBegin_textBK_text:SetText(ScriptGlobal_Format("#{ZHHD1_181128_214}", nShuaXinCnt))	
	Alcohol_Shop_DownBegin_textBK_text:SetToolTip(ScriptGlobal_Format("#{ZHHD1_181128_215}", nShuaXinCnt))	

	--每日元宝消耗
	local nCostToday = DataPool:GetPlayerMission_DataRound(g_MD_CAIQUANSHOP_COST)
	Alcohol_Shop_DownBegin_DownBKText:SetText(ScriptGlobal_Format("#{ZHHD1_181128_169}",nCostToday))
	for i=1,4 do
		local IsHaveGetPrice = Pneuma:GetMF(g_GetPrice_MF[i])		
		local isCanGetPirce = 0
		if nCostToday >= g_nPriceItem[i].nNeedYuanBao then
			isCanGetPirce = 1 
		end
		if isCanGetPirce == 1 then
			if IsHaveGetPrice == 0 then
				g_AcctionItem_PriceIcon[i]:SetProperty("Image" , g_PirceImage[1])
			else
				g_AcctionItem_PriceIcon[i]:SetProperty("Image" , g_PirceImage[2])
			end
		else
			g_AcctionItem_PriceIcon[i]:SetProperty("Image" , g_PirceImage[3])
		end
	end	
end

function Alcohol_Shop_HelpClick(nIndex)
	PushEvent("CCSHOP_HELP",nIndex)
end

