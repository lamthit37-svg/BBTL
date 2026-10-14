--端午抽奖
local g_Position = 0
local g_HaveNum = 0
local g_Tab = {}
local g_TabFinish = {}
local g_Client1Item= {}
local g_Client1Mask= {}
local g_Client2Item= {}
local g_Client2Mask= {}
local g_Client3Item= {}
local g_Client3Mask= {}
local g_Client4Item= {}
local g_Client4Mask = {}
local g_Client5Item= {}
local g_Client5Mask = {}
local g_Client6Item= {}
local g_Client6Mask = {}
local g_Client7Item= {}
local g_Client7Mask = {}
local g_Client6ItemAnimate = {}
local g_Client1ItemNum = {}
local g_Client2ItemNum = {}
local g_Client3ItemNum = {}
local g_Client4ItemNum = {}
local g_Client5ItemNum = {}
local g_Client6ItemNum = {}
local g_Select = 0--当前选中的页签
local g_MaxReward = 12
local g_Result = 0
local g_AnimatePos = 0
local g_MaxPoolSelect = {
	[1] = 4,
	[2] = 3,
	[3] = 2,
	[4] = 2,
	[5] = 1,
}
local g_StartTime = 20260528
local g_EndTime = 20260614
local g_StartFanLiTime = 20260528
local g_EndFanLiTime = 20260617
local g_ClientSelected = {0,0,0,0,0,0,0,0,0,0}
local g_LastClickTime = 0
local g_LotteryNeedNum = {
	[1] = 10,
	[2] = 15,
	[3] = 25,
	[4] = 40,
	[5] = 60,
	[6] = 85,
	[7] = 120,
	[8] = 180,
	[9] = 280,
	[10] = 420,
	[11] = 750,
	[12] = 1650,
}
local g_FanLiNeed = {
	[1] = 10,
	[2] = 25,
	[3] = 50,
	[4] = 90,
	[5] = 150,
	[6] = 235,
	[7] = 355,
	[8] = 535,
	[9] = 815,
	[10] = 1235,
	[11] = 1985,
	[12] = 3635,
}
local g_FanLiList = {}

local g_GiftsImage = {
	[1] = {Set ="DuanWu1" , Image = "DWAward1", },
	[2] = {Set ="DuanWu1" , Image = "DWAward2", },
	[3] = {Set ="DuanWu1" , Image = "DWAward3", },
	[4] = {Set ="DuanWu2" , Image = "DWAward4", },
	[5] = {Set ="DuanWu2" , Image = "DWAward5", },
	[6] = {Set ="DuanWu2" , Image = "DWAward6", },
	[7] = {Set ="DuanWu2" , Image = "DWAward7", },
	[8] = {Set ="DuanWu2" , Image = "DWAward8", },
	[9] = {Set ="DuanWu2" , Image = "DWAward9", },
	[10] ={Set ="DuanWu2" , Image = "DWAward10", },
	[11] ={Set ="DuanWu3" , Image = "DWAward11", },
	[12] ={Set ="DuanWu3" , Image = "DWAward12", },
}
local g_LastClickItem = 0
local g_Map = {
	[1] = 1,
	[2] = 8,
	[3] = 5,
	[4] = 2,
	[5] = 3,
	[6] = 10,
	[7] = 11,
	[8] = 4,
	[9] = 9,
	[10] = 12,
	[11] = 7,
	[12] = 6,
}

local g_MapSelected = {}
local g_Gifts = {
	[1] = 	{{GiftItemID = 38002214, num = 1,isBind = 1},},
	[2] =	{{GiftItemID = 38002214, num = 1,isBind = 1},},
	[3] =   {{GiftItemID = 38002214, num = 1,isBind = 1},},
	[4] = 	{{GiftItemID = 38002214, num = 1,isBind = 1},},
	[5] =	{{GiftItemID = 38002214, num = 2,isBind = 1},},
	[6] =   {{GiftItemID = 38002214, num = 3,isBind = 1},},
	[7] = 	{{GiftItemID = 38002214, num = 2,isBind = 1},{GiftItemID = 38002244, num = 1,isBind = 1},},
	[8] =	{{GiftItemID = 38002244, num = 2,isBind = 1},{GiftItemID = 20501003, num = 1,isBind = 1},},
	[9] =   {{GiftItemID = 38002244, num = 2,isBind = 1},{GiftItemID = 20502003, num = 1,isBind = 1},{GiftItemID = 38008594, num = 1,isBind = 1},{GiftItemID = 38008612, num = 1,isBind = 1},},
	[10] =  {{GiftItemID = 20502003, num = 1,isBind = 1},{GiftItemID = 20501003, num = 1,isBind = 1},},
	[11] =  {{GiftItemID = 20502003, num = 2,isBind = 1},{GiftItemID = 20501003, num = 2,isBind = 1},{GiftItemID = 38008612, num = 1,isBind = 1},},
	[12] =  {{GiftItemID = 20502004, num = 2,isBind = 1},{GiftItemID = 20501004, num = 2,isBind = 1},{GiftItemID = 38005871, num = 1,isBind = 1},{GiftItemID = 38008612, num = 2,isBind = 1},},
}
local g_Gifts_Ori = {
	[1] = 	{{GiftItemID = 38002214, num = 1,isBind = 1},},
	[2] =	{{GiftItemID = 38002214, num = 1,isBind = 1},},
	[3] =   {{GiftItemID = 38002214, num = 1,isBind = 1},},
	[4] = 	{{GiftItemID = 38002214, num = 1,isBind = 1},},
	[5] =	{{GiftItemID = 38002214, num = 2,isBind = 1},},
	[6] =   {{GiftItemID = 38002214, num = 3,isBind = 1},},
	[7] = 	{{GiftItemID = 38002214, num = 2,isBind = 1},{GiftItemID = 38002244, num = 1,isBind = 1},},
	[8] =	{{GiftItemID = 38002244, num = 2,isBind = 1},{GiftItemID = 20501003, num = 1,isBind = 1},},
	[9] =   {{GiftItemID = 38002244, num = 2,isBind = 1},{GiftItemID = 20502003, num = 1,isBind = 1},{GiftItemID = 38008594, num = 1,isBind = 1},{GiftItemID = 38008612, num = 1,isBind = 1},},
	[10] =  {{GiftItemID = 20502003, num = 1,isBind = 1},{GiftItemID = 20501003, num = 1,isBind = 1},},
	[11] =  {{GiftItemID = 20502003, num = 2,isBind = 1},{GiftItemID = 20501003, num = 2,isBind = 1},{GiftItemID = 38008612, num = 1,isBind = 1},},
	[12] =  {{GiftItemID = 20502004, num = 2,isBind = 1},{GiftItemID = 20501004, num = 2,isBind = 1},{GiftItemID = 38008612, num = 2,isBind = 1},},
}
local g_YiLingQu = {}
local g_WeiLingQu = {}
local g_BuKeLingQu = {}
local g_lottery = {round = 2, minSpeed = 20, decay = 5}
local g_Step = 0
local g_Round = 0
local g_Bonus = 0
local g_ViewId = 39923373
local g_EyeSign = {}
--*********************************
-- PreLoad
--*********************************
function DuanWu_Boat_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" , false);		-- 游戏分辨率发生了变化
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED", false);		-- 离开场景
	this : RegisterEvent( "ADJEST_UI_POS" , false);
	this : RegisterEvent( "DUANWU_BOAT_CHANGEFRAME", false);
	--this : RegisterEvent("PACKAGE_ITEM_CHANGED_EX", true)--先去掉等重开再改造
end


--*********************************
-- OnLoad
--*********************************
function DuanWu_Boat_OnLoad()
	g_Tab[1] = DuanWu_Boat_tab1
	g_Tab[2] = DuanWu_Boat_tab2
	g_Tab[3] = DuanWu_Boat_tab3
	g_Tab[4] = DuanWu_Boat_tab4
	g_Tab[5] = DuanWu_Boat_tab5
	g_Tab[6] = DuanWu_Boat_tab6
	g_Tab[7] = DuanWu_Boat_tab7

	g_TabFinish[1] = DuanWu_Boat_tab1Finish
	g_TabFinish[2] = DuanWu_Boat_tab2Finish
	g_TabFinish[3] = DuanWu_Boat_tab3Finish
	g_TabFinish[4] = DuanWu_Boat_tab4Finish
	g_TabFinish[5] = DuanWu_Boat_tab5Finish
	g_TabFinish[6] = DuanWu_Boat_tab6Finish
	g_TabFinish[7] = DuanWu_Boat_tab7Finish

	g_Client1Item[1] = DuanWu_Boat_Client1Item1
	g_Client1Item[2] = DuanWu_Boat_Client1Item2
	g_Client1Item[3] = DuanWu_Boat_Client1Item3
	g_Client1Item[4] = DuanWu_Boat_Client1Item4
	g_Client1Item[5] = DuanWu_Boat_Client1Item5
	g_Client1Item[6] = DuanWu_Boat_Client1Item6
	g_Client1Item[7] = DuanWu_Boat_Client1Item7
	g_Client1Item[8] = DuanWu_Boat_Client1Item8
	g_Client1Item[9] = DuanWu_Boat_Client1Item9
	g_Client1Item[10] = DuanWu_Boat_Client1Item10

	g_Client1Mask[1] = DuanWu_Boat_Client1Item1Mask
	g_Client1Mask[2] = DuanWu_Boat_Client1Item2Mask
	g_Client1Mask[3] = DuanWu_Boat_Client1Item3Mask
	g_Client1Mask[4] = DuanWu_Boat_Client1Item4Mask
	g_Client1Mask[5] = DuanWu_Boat_Client1Item5Mask
	g_Client1Mask[6] = DuanWu_Boat_Client1Item6Mask
	g_Client1Mask[7] = DuanWu_Boat_Client1Item7Mask
	g_Client1Mask[8] = DuanWu_Boat_Client1Item8Mask
	g_Client1Mask[9] = DuanWu_Boat_Client1Item9Mask
	g_Client1Mask[10] = DuanWu_Boat_Client1Item10Mask

	g_Client2Item[1] = DuanWu_Boat_Client2Item1
	g_Client2Item[2] = DuanWu_Boat_Client2Item2
	g_Client2Item[3] = DuanWu_Boat_Client2Item3
	g_Client2Item[4] = DuanWu_Boat_Client2Item4
	g_Client2Item[5] = DuanWu_Boat_Client2Item5
	g_Client2Item[6] = DuanWu_Boat_Client2Item6
	g_Client2Item[7] = DuanWu_Boat_Client2Item7
	g_Client2Item[8] = DuanWu_Boat_Client2Item8

	g_Client2Mask[1] = DuanWu_Boat_Client2Item1Mask
	g_Client2Mask[2] = DuanWu_Boat_Client2Item2Mask
	g_Client2Mask[3] = DuanWu_Boat_Client2Item3Mask
	g_Client2Mask[4] = DuanWu_Boat_Client2Item4Mask
	g_Client2Mask[5] = DuanWu_Boat_Client2Item5Mask
	g_Client2Mask[6] = DuanWu_Boat_Client2Item6Mask
	g_Client2Mask[7] = DuanWu_Boat_Client2Item7Mask
	g_Client2Mask[8] = DuanWu_Boat_Client2Item8Mask

	g_Client3Item[1] = DuanWu_Boat_Client3Item1
	g_Client3Item[2] = DuanWu_Boat_Client3Item2
	g_Client3Item[3] = DuanWu_Boat_Client3Item3
	g_Client3Item[4] = DuanWu_Boat_Client3Item4
	g_Client3Item[5] = DuanWu_Boat_Client3Item5
	g_Client3Item[6] = DuanWu_Boat_Client3Item6

	g_Client3Mask[1] = DuanWu_Boat_Client3Item1Mask
	g_Client3Mask[2] = DuanWu_Boat_Client3Item2Mask
	g_Client3Mask[3] = DuanWu_Boat_Client3Item3Mask
	g_Client3Mask[4] = DuanWu_Boat_Client3Item4Mask
	g_Client3Mask[5] = DuanWu_Boat_Client3Item5Mask
	g_Client3Mask[6] = DuanWu_Boat_Client3Item6Mask

	g_Client4Item[1] = DuanWu_Boat_Client4Item1
	g_Client4Item[2] = DuanWu_Boat_Client4Item2
	g_Client4Item[3] = DuanWu_Boat_Client4Item3
	g_Client4Item[4] = DuanWu_Boat_Client4Item4
	g_Client4Item[5] = DuanWu_Boat_Client4Item5

	g_Client4Mask[1] = DuanWu_Boat_Client4Item1Mask
	g_Client4Mask[2] = DuanWu_Boat_Client4Item2Mask
	g_Client4Mask[3] = DuanWu_Boat_Client4Item3Mask
	g_Client4Mask[4] = DuanWu_Boat_Client4Item4Mask
	g_Client4Mask[5] = DuanWu_Boat_Client4Item5Mask

	g_Client5Item[1] = DuanWu_Boat_Client5Item1
	g_Client5Item[2] = DuanWu_Boat_Client5Item2
	g_Client5Item[3] = DuanWu_Boat_Client5Item3
	g_Client5Item[4] = DuanWu_Boat_Client5Item4
	g_Client5Item[5] = DuanWu_Boat_Client5Item5

	g_Client5Mask[1] = DuanWu_Boat_Client5Item1Mask
	g_Client5Mask[2] = DuanWu_Boat_Client5Item2Mask
	g_Client5Mask[3] = DuanWu_Boat_Client5Item3Mask
	g_Client5Mask[4] = DuanWu_Boat_Client5Item4Mask
	g_Client5Mask[5] = DuanWu_Boat_Client5Item5Mask

	g_Client6Item[1] = DuanWu_Boat_Client6Item1
	g_Client6Item[2] = DuanWu_Boat_Client6Item2
	g_Client6Item[3] = DuanWu_Boat_Client6Item3
	g_Client6Item[4] = DuanWu_Boat_Client6Item4
	g_Client6Item[5] = DuanWu_Boat_Client6Item5
	g_Client6Item[6] = DuanWu_Boat_Client6Item6
	g_Client6Item[7] = DuanWu_Boat_Client6Item7
	g_Client6Item[8] = DuanWu_Boat_Client6Item8
	g_Client6Item[9] = DuanWu_Boat_Client6Item9
	g_Client6Item[10] = DuanWu_Boat_Client6Item10
	g_Client6Item[11] = DuanWu_Boat_Client6Item11
	g_Client6Item[12] = DuanWu_Boat_Client6Item12

	g_Client6Mask[1] = DuanWu_Boat_Client6Item1Mask
	g_Client6Mask[2] = DuanWu_Boat_Client6Item2Mask
	g_Client6Mask[3] = DuanWu_Boat_Client6Item3Mask
	g_Client6Mask[4] = DuanWu_Boat_Client6Item4Mask
	g_Client6Mask[5] = DuanWu_Boat_Client6Item5Mask
	g_Client6Mask[6] = DuanWu_Boat_Client6Item6Mask
	g_Client6Mask[7] = DuanWu_Boat_Client6Item7Mask
	g_Client6Mask[8] = DuanWu_Boat_Client6Item8Mask
	g_Client6Mask[9] = DuanWu_Boat_Client6Item9Mask
	g_Client6Mask[10] = DuanWu_Boat_Client6Item10Mask
	g_Client6Mask[11] = DuanWu_Boat_Client6Item11Mask
	g_Client6Mask[12] = DuanWu_Boat_Client6Item12Mask

	g_Client6ItemAnimate[1] = DuanWu_Boat_Client6Item1_Animate
	g_Client6ItemAnimate[2] = DuanWu_Boat_Client6Item2_Animate
	g_Client6ItemAnimate[3] = DuanWu_Boat_Client6Item3_Animate
	g_Client6ItemAnimate[4] = DuanWu_Boat_Client6Item4_Animate
	g_Client6ItemAnimate[5] = DuanWu_Boat_Client6Item5_Animate
	g_Client6ItemAnimate[6] = DuanWu_Boat_Client6Item6_Animate
	g_Client6ItemAnimate[7] = DuanWu_Boat_Client6Item7_Animate
	g_Client6ItemAnimate[8] = DuanWu_Boat_Client6Item8_Animate
	g_Client6ItemAnimate[9] = DuanWu_Boat_Client6Item9_Animate
	g_Client6ItemAnimate[10] = DuanWu_Boat_Client6Item10_Animate
	g_Client6ItemAnimate[11] = DuanWu_Boat_Client6Item11_Animate
	g_Client6ItemAnimate[12] = DuanWu_Boat_Client6Item12_Animate

	g_Client1ItemNum[1] = DuanWu_Boat_Client1Item1Num
	g_Client1ItemNum[2] = DuanWu_Boat_Client1Item2Num
	g_Client1ItemNum[3] = DuanWu_Boat_Client1Item3Num
	g_Client1ItemNum[4] = DuanWu_Boat_Client1Item4Num
	g_Client1ItemNum[5] = DuanWu_Boat_Client1Item5Num
	g_Client1ItemNum[6] = DuanWu_Boat_Client1Item6Num
	g_Client1ItemNum[7] = DuanWu_Boat_Client1Item7Num
	g_Client1ItemNum[8] = DuanWu_Boat_Client1Item8Num
	g_Client1ItemNum[9] = DuanWu_Boat_Client1Item9Num
	g_Client1ItemNum[10] = DuanWu_Boat_Client1Item10Num

	g_Client2ItemNum[1] = DuanWu_Boat_Client2Item1Num
	g_Client2ItemNum[2] = DuanWu_Boat_Client2Item2Num
	g_Client2ItemNum[3] = DuanWu_Boat_Client2Item3Num
	g_Client2ItemNum[4] = DuanWu_Boat_Client2Item4Num
	g_Client2ItemNum[5] = DuanWu_Boat_Client2Item5Num
	g_Client2ItemNum[6] = DuanWu_Boat_Client2Item6Num
	g_Client2ItemNum[7] = DuanWu_Boat_Client2Item7Num
	g_Client2ItemNum[8] = DuanWu_Boat_Client2Item8Num

	g_Client3ItemNum[1] = DuanWu_Boat_Client3Item1Num
	g_Client3ItemNum[2] = DuanWu_Boat_Client3Item2Num
	g_Client3ItemNum[3] = DuanWu_Boat_Client3Item3Num
	g_Client3ItemNum[4] = DuanWu_Boat_Client3Item4Num
	g_Client3ItemNum[5] = DuanWu_Boat_Client3Item5Num
	g_Client3ItemNum[6] = DuanWu_Boat_Client3Item6Num

	g_Client4ItemNum[1] = DuanWu_Boat_Client4Item1Num
	g_Client4ItemNum[2] = DuanWu_Boat_Client4Item2Num
	g_Client4ItemNum[3] = DuanWu_Boat_Client4Item3Num
	g_Client4ItemNum[4] = DuanWu_Boat_Client4Item4Num
	g_Client4ItemNum[5] = DuanWu_Boat_Client4Item5Num

	g_Client5ItemNum[1] = DuanWu_Boat_Client5Item1Num
	g_Client5ItemNum[2] = DuanWu_Boat_Client5Item2Num
	g_Client5ItemNum[3] = DuanWu_Boat_Client5Item3Num
	g_Client5ItemNum[4] = DuanWu_Boat_Client5Item4Num
	g_Client5ItemNum[5] = DuanWu_Boat_Client5Item5Num

	g_Client6ItemNum[1] = DuanWu_Boat_Client6Item1Num
	g_Client6ItemNum[2] = DuanWu_Boat_Client6Item2Num
	g_Client6ItemNum[3] = DuanWu_Boat_Client6Item3Num
	g_Client6ItemNum[4] = DuanWu_Boat_Client6Item4Num
	g_Client6ItemNum[5] = DuanWu_Boat_Client6Item5Num
	g_Client6ItemNum[6] = DuanWu_Boat_Client6Item6Num
	g_Client6ItemNum[7] = DuanWu_Boat_Client6Item7Num
	g_Client6ItemNum[8] = DuanWu_Boat_Client6Item8Num
	g_Client6ItemNum[9] = DuanWu_Boat_Client6Item9Num
	g_Client6ItemNum[10] = DuanWu_Boat_Client6Item10Num
	g_Client6ItemNum[11] = DuanWu_Boat_Client6Item11Num
	g_Client6ItemNum[12] = DuanWu_Boat_Client6Item12Num

	g_EyeSign[1] = DuanWu_Boat_Client6Item1_EyeSign
	g_EyeSign[2] = DuanWu_Boat_Client6Item2_EyeSign
	g_EyeSign[3] = DuanWu_Boat_Client6Item3_EyeSign
	g_EyeSign[4] = DuanWu_Boat_Client6Item4_EyeSign
	g_EyeSign[5] = DuanWu_Boat_Client6Item5_EyeSign
	g_EyeSign[6] = DuanWu_Boat_Client6Item6_EyeSign
	g_EyeSign[7] = DuanWu_Boat_Client6Item7_EyeSign
	g_EyeSign[8] = DuanWu_Boat_Client6Item8_EyeSign
	g_EyeSign[9] = DuanWu_Boat_Client6Item9_EyeSign
	g_EyeSign[10] = DuanWu_Boat_Client6Item10_EyeSign
	g_EyeSign[11] = DuanWu_Boat_Client6Item11_EyeSign
	g_EyeSign[12] = DuanWu_Boat_Client6Item12_EyeSign

	g_Position = DuanWu_Boat_Frame_BK:GetProperty("UnifiedPosition")
end


--*********************************
-- OnEvent
--*********************************
function DuanWu_Boat_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 50508701) then
		g_Select = tonumber(Get_XParam_INT(0));
		g_HaveNum = tonumber(Get_XParam_INT(1));
		this:Show()
		DuanWu_Boat_ShowFrame()
		DuanWu_Boat_FlashRedPoint()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508702) then--添加奖励刷新界面
		if (not this:IsVisible()) then
			return
		end
		g_Select = tonumber(Get_XParam_INT(0));
		DuanWu_Boat_ShowFrame()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508705) then--抽奖刷新界面
		if (not this:IsVisible()) then
			return
		end
		g_Select = tonumber(Get_XParam_INT(0));
		g_HaveNum = tonumber(Get_XParam_INT(1));
		g_Text = tostring(Get_XParam_STR(0))
		for i = 1, 12 do
			if g_Map[i] == tonumber(Get_XParam_INT(2)) then
				g_Result = i
			end
		end
		g_Bonus = tonumber(Get_XParam_INT(3))
		DuanWu_Boat_Start()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508707) then--刷新拥有条目
		if (not this:IsVisible()) then
			return
		end
		g_HaveNum = tonumber(Get_XParam_INT(0));
		local opt = tonumber(Get_XParam_INT(1));
		if opt == 1 then
			DuanWu_Boat_ShowFrame()
		elseif opt == 2 then
			if g_Select == 6 then
				DuanWu_Boat_FlashNeedNumber()
			end
		else

		end
		DuanWu_Boat_ShowLotteryHotPoint()
		DuanWu_Boat_ShowFanLiHotPoint()
		PushEvent("CLOSE_DUANWU_BOAT_MBUY")

	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508708) then--刷新返利按钮
		if (not this:IsVisible()) then
			return
		end
		if g_Select ~= 7 then
			return
		end
		local index = tonumber(Get_XParam_INT(0));
		if g_FanLiList[index] ~= nil then
			g_FanLiList[index]:SetButton1Hide()
			g_FanLiList[index]:Setm_newImage(7,"DuanWu6", "BWBoatBtn_Dis2")
			g_FanLiList[index]:Setm_newImageShow(7)
			DuanWu_Boat_ShowFanLiHotPoint()
		end
		local revNum = Lua_GetDWReceivedNum()
		DuanWu_Boat_Client7ListText:SetText(ScriptGlobal_Format("#{DWKC_190502_80}", g_FanLiNeed[revNum]))
		DuanWu_Boat_ShowTab()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 恢复默认位置
		DuanWu_Boat_Frame_BK:SetProperty("UnifiedPosition", g_Position)
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DuanWu_Boat_OnHide()
	elseif (event == "ADJEST_UI_POS") then
		DuanWu_Boat_Frame_BK:SetProperty("UnifiedPosition", g_Position)
	elseif (event == "DUANWU_BOAT_CHANGEFRAME") then
		local index = tonumber(arg0);
		DuanWu_Boat_ChangeFrameBack(index)

	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
		local isinT = Bank:CheckIsInTServer()

		if isinT == 1 then
			return
	    end

		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		if curTime2Day < g_StartFanLiTime or curTime2Day > g_EndFanLiTime then
			return
		end
		
		if true ~= this:IsVisible() then
			DuanWu_Boat_FlashRedPoint()
			return
		end
		if 1 then
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientAskItemNum")
			Set_XSCRIPT_ScriptID(505087)
			Set_XSCRIPT_Parameter(0,2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		DuanWu_Boat_FlashRedPoint()
	end 
end

function DuanWu_Boat_ShowFrame()
	DuanWu_Boat_ShowLotteryHotPoint()
	DuanWu_Boat_ShowFanLiHotPoint()
	DuanWu_Boat_CleanData()
	DuanWu_Boat_ShowTab()
	if g_Select == 1 then
		DuanWu_Boat_ShowJackPotA()
	elseif g_Select == 2 then
		DuanWu_Boat_ShowJackPotB()
	elseif g_Select == 3 then
		DuanWu_Boat_ShowJackPotC()
	elseif g_Select == 4 then
		DuanWu_Boat_ShowJackPotD()
	elseif g_Select == 5 then
		DuanWu_Boat_ShowJackPotE()
	elseif g_Select == 6 then
		DuanWu_Boat_ShowLottery()
	elseif g_Select == 7 then
		DuanWu_Boat_ShowFanLiFrame()
	else
		return
	end
end

function DuanWu_Boat_ShowTab()
	for i = 1, 5 do
		if DuanWu_Boat_CheckIsFull(i) == 1 then
			g_TabFinish[i]:Show()
		else
			g_TabFinish[i]:Hide()
		end
	end
	local revNum = Lua_GetDWReceivedNum()
	if revNum >= 12 then
		g_TabFinish[6]:Show()
	else
		g_TabFinish[6]:Hide()
	end
	if Lua_GetDWFanLiNum() >= 12 then
		g_TabFinish[7]:Show()
	else
		g_TabFinish[7]:Hide()
	end
	g_Tab[g_Select]:SetCheck(1)
end

function DuanWu_Boat_CleanData()
	for i = 1, table.getn(g_ClientSelected) do
		g_ClientSelected[i] = 0
	end
	DuanWu_Boat_DaibiBuy_Btn:Hide()
end

function DuanWu_Boat_ShowJackPotA()
	DuanWu_Boat_Client1:Show()
	DuanWu_Boat_Client2:Hide()
	DuanWu_Boat_Client3:Hide()
	DuanWu_Boat_Client4:Hide()
	DuanWu_Boat_Client5:Hide()
	DuanWu_Boat_Client6:Hide()
	DuanWu_Boat_Client6Get:Hide()
	DuanWu_Boat_Client7:Hide()

	for i = 1, table.getn(g_Client1Item) do
		g_Client1Item[i]:SetActionItem(-1)
		g_Client1Mask[i]:Hide()
		g_Client1ItemNum[i]:SetText("")
	end
	local selectedNum = 0
	for j = 1, table.getn(g_Client1Item) do
		local poolId,ShowItemId,ItemCount = Lua_GetDuanWuItemInfo(j)
		local isSelect = Lua_GetDuanWuIsSelected(j)
		
		if poolId == g_Select then
			if isSelect == 1 then
				selectedNum = selectedNum + 1
				g_Client1Mask[j]:Show()--已经选择了要对勾
			end

			if selectedNum >= g_MaxPoolSelect[g_Select] then
			    --已经选完了
				DuanWu_Boat_Client1_Num:SetText("#{DWKC_190502_16}")
				DuanWu_Boat_Client1_Btn:Hide()
			else
				DuanWu_Boat_Client1_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", selectedNum, g_MaxPoolSelect[1]))
				DuanWu_Boat_Client1_Btn:Show()
			end

			local theAction = DataPool:CreateActionItemForShow(ShowItemId, 1)
			if (theAction:GetID() ~= 0) then
				g_Client1Item[j]:SetActionItem(theAction:GetID())
				if ItemCount > 1 then
					g_Client1ItemNum[j]:SetText(ItemCount)
				end
			end

		end
	end
	
end

function DuanWu_Boat_ShowJackPotB()
	DuanWu_Boat_Client1:Hide()
	DuanWu_Boat_Client2:Show()
	DuanWu_Boat_Client3:Hide()
	DuanWu_Boat_Client4:Hide()
	DuanWu_Boat_Client5:Hide()
	DuanWu_Boat_Client6:Hide()
	DuanWu_Boat_Client6Get:Hide()
	DuanWu_Boat_Client7:Hide()

	local idxStart = table.getn(g_Client1Item)
	for i = 1, table.getn(g_Client2Item) do
		g_Client2Item[i]:SetActionItem(-1)
		g_Client2Mask[i]:Hide()
		g_Client2ItemNum[i]:SetText("")
	end
	local selectedNum = 0
	for j = 1, table.getn(g_Client2Item) do
		local poolId,ShowItemId,ItemCount = Lua_GetDuanWuItemInfo(j + idxStart)
		local isSelect = Lua_GetDuanWuIsSelected(j + idxStart)
		
		if poolId == g_Select then
			if isSelect == 1 then
				selectedNum = selectedNum + 1
				g_Client2Mask[j]:Show()--已经选择了要对勾
			end

			if selectedNum >= g_MaxPoolSelect[g_Select] then
			    --已经选完了
				DuanWu_Boat_Client2_Num:SetText("#{DWKC_190502_20}")
				DuanWu_Boat_Client2_Btn:Hide()
			else
				DuanWu_Boat_Client2_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", selectedNum,g_MaxPoolSelect[2]))
				DuanWu_Boat_Client2_Btn:Show()
			end

			local theAction = DataPool:CreateActionItemForShow(ShowItemId, 1)
			if (theAction:GetID() ~= 0) then
				g_Client2Item[j]:SetActionItem(theAction:GetID())
				if ItemCount > 1 then
					g_Client2ItemNum[j]:SetText(ItemCount)
				end
			end
		end
	end
end

function DuanWu_Boat_ShowJackPotC()
	DuanWu_Boat_Client1:Hide()
	DuanWu_Boat_Client2:Hide()
	DuanWu_Boat_Client3:Show()
	DuanWu_Boat_Client4:Hide()
	DuanWu_Boat_Client5:Hide()
	DuanWu_Boat_Client6:Hide()
	DuanWu_Boat_Client6Get:Hide()
	DuanWu_Boat_Client7:Hide()

	local idxStart = table.getn(g_Client1Item) + table.getn(g_Client2Item)
	for i = 1, table.getn(g_Client3Item) do
		g_Client3Item[i]:SetActionItem(-1)
		g_Client3Mask[i]:Hide()
		g_Client3ItemNum[i]:SetText("")
	end
	local selectedNum = 0
	for j = 1, table.getn(g_Client3Item) do
		local poolId,ShowItemId,ItemCount = Lua_GetDuanWuItemInfo(j+idxStart)--获得表里的道具
		local isSelect = Lua_GetDuanWuIsSelected(j+idxStart)--看看这个索引是否已经选择了!!
		
		if poolId == g_Select then
			if isSelect == 1 then
				selectedNum = selectedNum + 1
				g_Client3Mask[j]:Show()--已经选择了要对勾
			end
			if selectedNum >= g_MaxPoolSelect[g_Select] then
			    --已经选完了
				DuanWu_Boat_Client3_Num:SetText("#{DWKC_190502_24}")
				DuanWu_Boat_Client3_Btn:Hide()
			else
				DuanWu_Boat_Client3_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", selectedNum,g_MaxPoolSelect[3]))
				DuanWu_Boat_Client3_Btn:Show()
			end

			local theAction = DataPool:CreateActionItemForShow(ShowItemId, 1)
			if (theAction:GetID() ~= 0) then
				g_Client3Item[j]:SetActionItem(theAction:GetID())
				if ItemCount > 1 then
					g_Client3ItemNum[j]:SetText(ItemCount)
				end
			end
		end
	end
end


function DuanWu_Boat_ShowJackPotD()
	DuanWu_Boat_Client1:Hide()
	DuanWu_Boat_Client2:Hide()
	DuanWu_Boat_Client3:Hide()
	DuanWu_Boat_Client4:Show()
	DuanWu_Boat_Client5:Hide()
	DuanWu_Boat_Client6:Hide()
	DuanWu_Boat_Client6Get:Hide()
	DuanWu_Boat_Client7:Hide()

	local idxStart = table.getn(g_Client1Item) + table.getn(g_Client2Item) + table.getn(g_Client3Item) 
	for i = 1, table.getn(g_Client4Item) do
		g_Client4Item[i]:SetActionItem(-1)
		g_Client4Mask[i]:Hide()
		g_Client4ItemNum[i]:SetText("")
	end
	local selectedNum = 0
	for j = 1, table.getn(g_Client4Item) do
		local poolId,ShowItemId,ItemCount = Lua_GetDuanWuItemInfo(j+idxStart)--获得表里的道具
		local isSelect = Lua_GetDuanWuIsSelected(j+idxStart)--看看这个索引是否已经选择了
		
		if poolId == g_Select then
			if isSelect == 1 then
				selectedNum = selectedNum + 1
				g_Client4Mask[j]:Show()--已经选择了要对勾
			end

			if selectedNum >= g_MaxPoolSelect[g_Select] then
			    --已经选完了
				DuanWu_Boat_Client4_Num:SetText("#{DWKC_190502_24}")
				DuanWu_Boat_Client4_Btn:Hide()
			else
				DuanWu_Boat_Client4_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", selectedNum,g_MaxPoolSelect[4]))
				DuanWu_Boat_Client4_Btn:Show()
			end

			local theAction = DataPool:CreateActionItemForShow(ShowItemId, 1)
			if (theAction:GetID() ~= 0) then
            	g_Client4Item[j]:SetActionItem(theAction:GetID())
            	if ItemCount > 1 then
            		g_Client4ItemNum[j]:SetText(ItemCount)
            	end
			end
			
		end
	end
end

function DuanWu_Boat_ShowJackPotE()
	DuanWu_Boat_Client1:Hide()
	DuanWu_Boat_Client2:Hide()
	DuanWu_Boat_Client3:Hide()
	DuanWu_Boat_Client4:Hide()
	DuanWu_Boat_Client5:Show()
	DuanWu_Boat_Client6:Hide()
	DuanWu_Boat_Client6Get:Hide()
	DuanWu_Boat_Client7:Hide()

	local idxStart = table.getn(g_Client1Item) + table.getn(g_Client2Item) + table.getn(g_Client3Item) + table.getn(g_Client4Item)
	for i = 1, table.getn(g_Client5Item) do
		g_Client5Item[i]:SetActionItem(-1)
		g_Client5Mask[i]:Hide()
		g_Client5ItemNum[i]:SetText("")
		g_Client5Item[i]:Hide()
	end
	local selectedNum = 0
	for j = 1, table.getn(g_Client5Item) do
		local poolId,ShowItemId,ItemCount = Lua_GetDuanWuItemInfo(j+idxStart)--获得表里的道具
		if ShowItemId == nil or ShowItemId <= 0 then
			return
		end
		local isSelect = Lua_GetDuanWuIsSelected(j+idxStart)--看看这个索引是否已经选择了
		
		if poolId == g_Select then
			if isSelect == 1 then
				selectedNum = selectedNum + 1
				g_Client5Mask[j]:Show()--已经选择了要对勾
			end

			if selectedNum >= g_MaxPoolSelect[g_Select] then
			    --已经选完了
				DuanWu_Boat_Client5_Num:SetText("#{DWKC_190502_24}")
				DuanWu_Boat_Client5_Btn:Hide()
			else
				DuanWu_Boat_Client5_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", selectedNum, g_MaxPoolSelect[5]))
				DuanWu_Boat_Client5_Btn:Show()
			end

			local theAction = DataPool:CreateActionItemForShow(ShowItemId, 1)
			if (theAction:GetID() ~= 0) then
				g_Client5Item[j]:Show()
				g_Client5Item[j]:SetActionItem(theAction:GetID())
				if ItemCount > 1 then
					g_Client5ItemNum[j]:SetText(ItemCount)
				end
			end
		end
	end
end

function DuanWu_Boat_CheckIsFull(poolId)
	--先看看五个池子是否都选择完了
	local selectedNum = 0
	if poolId == 1 then
		for i = 1, table.getn(g_Client1Item) do
			local isSelect = Lua_GetDuanWuIsSelected(i)--看看这个索引是否已经选择了
			if isSelect ~= nil and isSelect == 1 then
				selectedNum = selectedNum + 1
			end
		end
	elseif poolId == 2 then
		local idxStart = table.getn(g_Client1Item) + 1
		local idxEnd = table.getn(g_Client1Item) + table.getn(g_Client2Item)
		for i = idxStart, idxEnd do
			local isSelect = Lua_GetDuanWuIsSelected(i)--看看这个索引是否已经选择了
			if isSelect ~= nil and isSelect == 1 then
				selectedNum = selectedNum + 1
			end
		end
	elseif poolId == 3 then
		local idxStart = table.getn(g_Client1Item) + table.getn(g_Client2Item) + 1
		local idxEnd = table.getn(g_Client1Item) + table.getn(g_Client2Item)+table.getn(g_Client3Item) 
		for i = idxStart, idxEnd do
			local isSelect = Lua_GetDuanWuIsSelected(i)--看看这个索引是否已经选择了
			if isSelect ~= nil and isSelect == 1 then
				selectedNum = selectedNum + 1
			end
		end
	elseif poolId == 4 then
		local idxStart = table.getn(g_Client1Item) + table.getn(g_Client2Item) + table.getn(g_Client3Item) +1
		local idxEnd = table.getn(g_Client1Item) + table.getn(g_Client2Item)+table.getn(g_Client3Item) +table.getn(g_Client4Item)
		for i = idxStart, idxEnd  do
			local isSelect = Lua_GetDuanWuIsSelected(i)--看看这个索引是否已经选择了
			if isSelect ~= nil and isSelect == 1 then
				selectedNum = selectedNum + 1
			end
		end
	elseif poolId == 5 then
		local idxStart = table.getn(g_Client1Item) + table.getn(g_Client2Item) + table.getn(g_Client3Item) + table.getn(g_Client4Item) +1
		local idxEnd = table.getn(g_Client1Item) + table.getn(g_Client2Item)+table.getn(g_Client3Item) +table.getn(g_Client4Item)+ table.getn(g_Client5Item) 
		for i = idxStart , idxEnd do
			local isSelect = Lua_GetDuanWuIsSelected(i)--看看这个索引是否已经选择了
			if isSelect ~= nil and isSelect == 1 then
				selectedNum = selectedNum + 1
			end
		end
	else
		return 0
	end
	if selectedNum >= g_MaxPoolSelect[poolId] then
		return 1
	end
	return 0
end

function DuanWu_Boat_ShowLottery()
	DuanWu_Boat_Client1:Hide()
	DuanWu_Boat_Client2:Hide()
	DuanWu_Boat_Client3:Hide()
	DuanWu_Boat_Client4:Hide()
	DuanWu_Boat_Client5:Hide()
	DuanWu_Boat_Client6:Show()
	DuanWu_Boat_Client6Get:Hide()
	DuanWu_Boat_Client7:Hide()
	DuanWu_Boat_Client6_ItemClient:Show()
	g_MapSelected = {}
	DuanWu_Boat_DaibiBuy_Btn:Hide()
	--判断一下是否全满了
	for i = 1, table.getn(g_Client6Mask) do
		g_Client6Mask[i]:Hide()
		g_Client6ItemAnimate[i]:Hide()
		g_Client6Item[i]:Show()
		g_Client6Item[i]:SetActionItem(-1)
		g_Client6ItemNum[i]:SetText("")
		g_EyeSign[i]:Hide()
	end
	local selectNum = Lua_GetDWSelectNum()
	local hasRev = 0
	if selectNum ~= nil and selectNum >= g_MaxReward then--池子满了 取map
		for i = 1, selectNum do
			local pos = g_Map[i]
			local poolId,ShowItemId,ItemCount = Lua_GetSelectedAward(pos)--获得表里的道具
			local theAction = DataPool:CreateActionItemForShow(ShowItemId, 1)
			if (theAction:GetID()~=0) then
				g_Client6Item[i]:Show()
				g_Client6Item[i]:SetActionItem(theAction:GetID())
				if ItemCount > 1 then
					g_Client6ItemNum[i]:SetText(ItemCount)
				end
				
			end
			if 1 == Lua_IsDWReceived(pos) then
				g_Client6Mask[i]:Show()
				hasRev = hasRev + 1
				g_MapSelected[i] = 1
			else
				g_MapSelected[i] = 0
			end
			if ShowItemId == g_ViewId then
				g_EyeSign[i]:Show()
			end
		end
		DuanWu_Boat_Client6_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_66}", hasRev, 12))--12/12
		DuanWu_Boat_Client6_NumClient:Show()
		if hasRev >= g_MaxReward then--抽光了
			DuanWu_Boat_Client6_Num1:SetText("#{DWKC_190502_28}")--需要
			DuanWu_Boat_Client6_Num2:SetText("")	
			DuanWu_Boat_Client6_Btn:Hide()
			DuanWu_Boat_Client6_NumClient:Hide()
		else
			DuanWu_Boat_Client6_Num1:SetText(ScriptGlobal_Format("#{DWKC_190502_27}", g_LotteryNeedNum[hasRev+1]))--需要
			DuanWu_Boat_Client6_Btn:Show()
			if g_LotteryNeedNum[hasRev + 1] > g_HaveNum then
				DuanWu_Boat_Client6_Num2:SetText(ScriptGlobal_Format("#{DWKC_190502_29}", g_HaveNum))--拥有 red
			else
				DuanWu_Boat_Client6_Num2:SetText(ScriptGlobal_Format("#{DWKC_190502_44}", g_HaveNum))--拥有
			end
		end
		DuanWu_Boat_DaibiBuy_Btn:Show()
	local revNum = Lua_GetDWReceivedNum()
	local nCostNum = 0
	if revNum > 0 then
		nCostNum = g_FanLiNeed[revNum]
	end
	if g_HaveNum + nCostNum >= g_FanLiNeed[12] then
		DuanWu_Boat_DaibiBuy_Btn:Hide()
	end
	elseif selectNum ~= nil and selectNum < g_MaxReward  and selectNum > 0 then--如果没满 按位置填
		local selectIdx = {}
		local pos = 1
		selectIdx[1],selectIdx[2],selectIdx[3],selectIdx[4],selectIdx[5],selectIdx[6],selectIdx[7],selectIdx[8],selectIdx[9],selectIdx[10],selectIdx[11],selectIdx[12] = Lua_GetDWNotFullIndex()
		for i = 1, 12 do
			if (selectIdx[i] ~= nil and selectIdx[i] > 0) then
				local poolId,ShowItemId,ItemCount = Lua_GetSelectedAwardByTableIndex(selectIdx[i])--获得表里的道具
				local theAction = DataPool:CreateActionItemForShow(ShowItemId, 1)
				if (theAction:GetID()~=0) then
					g_Client6Item[pos]:Show()
					g_Client6Item[pos]:SetActionItem(theAction:GetID())
					if ShowItemId == g_ViewId then
						g_EyeSign[pos]:Show()
					end
					if ItemCount > 1 then
						g_Client6ItemNum[pos]:SetText(ItemCount)
					end
					pos = pos+1
				end
				
			end
		end
		for i = pos, 12 do
			g_Client6Item[i]:SetActionItem(-1)
		end
		DuanWu_Boat_Client6_NumClient:Hide()
		DuanWu_Boat_Client6_Num1:SetText("")--需要
		DuanWu_Boat_Client6_Num2:SetText("")
		DuanWu_Boat_Client6_Btn:Hide()
		DuanWu_Boat_Client6_Num:SetText("")
		DuanWu_Boat_Client6_Hint:SetText("#{DWKC_190502_26}")
		DuanWu_Boat_Client6_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_83}", selectNum, 12))--12/12
	else
		DuanWu_Boat_Client6_NumClient:Hide()
		DuanWu_Boat_Client6_Num1:SetText("")--需要
		DuanWu_Boat_Client6_Num2:SetText("")
		DuanWu_Boat_Client6_Btn:Hide()
		DuanWu_Boat_Client6_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_83}", 0, 12))--12/12
		DuanWu_Boat_Client6_Hint:SetText("#{DWKC_190502_26}")
		return
	end
	
end

function DuanWu_Boat_FlashNeedNumber()
	local hasRev = 0
	local selectNum = Lua_GetDWSelectNum()
	if selectNum ~= nil and selectNum >= g_MaxReward then
		for i = 1, selectNum do
			local pos = g_Map[i]
			if 1 == Lua_IsDWReceived(pos) then
				hasRev = hasRev + 1
			end
		end
	end
	if hasRev >= g_MaxReward then
		DuanWu_Boat_Client6_Num1:SetText("#{DWKC_190502_28}")--需要
		DuanWu_Boat_Client6_Btn:Hide()
		DuanWu_Boat_Client6_Num2:SetText("")
	else
		DuanWu_Boat_Client6_Num1:SetText(ScriptGlobal_Format("#{DWKC_190502_27}", g_LotteryNeedNum[hasRev+1]))--需要
		DuanWu_Boat_Client6_Btn:Show()
		if g_LotteryNeedNum[hasRev + 1] > g_HaveNum then
			DuanWu_Boat_Client6_Num2:SetText(ScriptGlobal_Format("#{DWKC_190502_29}", g_HaveNum))--拥有 red
		else
			DuanWu_Boat_Client6_Num2:SetText(ScriptGlobal_Format("#{DWKC_190502_44}", g_HaveNum))--拥有
		end
	end
	DuanWu_Boat_DaibiBuy_Btn:Show()
	local revNum = Lua_GetDWReceivedNum()
	local nCostNum = 0
	if revNum > 0 then
		nCostNum = g_FanLiNeed[revNum]
	end
	if g_HaveNum + nCostNum >= g_FanLiNeed[12] then
		DuanWu_Boat_DaibiBuy_Btn:Hide()
	end

end
--切换页签
function DuanWu_Boat_ChangeFrame(index)
	if g_Select == index then
		return
	end
	g_Tab[index]:SetCheck(0)
	--领奖角色等级是否大于等于30级
	if Player:GetLevel() < 30 then
		PushDebugMessage("#{DWKC_190502_32}")
		return
	end
	--当前服务器时间是否处于活动时间
	if index >= 1 and index <= 6 then
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		if curTime2Day < g_StartTime or curTime2Day > g_EndTime then
			PushDebugMessage("#{DWKC_190502_33}")
			g_Tab[index]:SetCheck(0)
			g_Tab[g_Select]:SetCheck(1)
			return 
		end
	end
	if index == 7 then
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		if curTime2Day < g_StartFanLiTime or curTime2Day > g_EndFanLiTime then
			PushDebugMessage("#{DWKC_190502_33}")
			g_Tab[index]:SetCheck(0)
			g_Tab[g_Select]:SetCheck(1)
			return 
		end
	end
	--当前奖池是否是正在选择状态
	KillTimer("DuanWu_Boat_Tick()")
	if g_Bonus > 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GongGao")
			Set_XSCRIPT_ScriptID(505087)
			Set_XSCRIPT_Parameter(0,g_Bonus)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		g_Bonus = 0
	end
	if g_Text ~= nil and g_Text ~= 0 then
		PushDebugMessage(g_Text)
		g_Text = 0
	end
	if g_Select ~= 6 and g_Select ~= 7 then
		for i = 1, table.getn(g_ClientSelected) do
			if g_ClientSelected[i] == 1 then
				PushEvent("UI_COMMAND", 50508704, index)
				return
			end
		end
	end

	if index >= 1 and index <= 7 then
		g_Tab[g_Select]:SetCheck(0)
		g_Select = index
		g_Tab[g_Select]:SetCheck(1)
		DuanWu_Boat_CleanData()
		--如果是兑奖界面刷新一下物品数量
		if index == 6 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("ClientAskItemNum")
				Set_XSCRIPT_ScriptID(505087)
				Set_XSCRIPT_Parameter(0,1)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		else
			DuanWu_Boat_ShowFrame()
		end
		
	end

end

function DuanWu_Boat_ChangeFrameBack(index)
	if g_Select == index then
		return
	end

	--领奖角色等级是否大于等于30级
	if Player:GetLevel() < 30 then
		PushDebugMessage("#{DWKC_190502_32}")
		return
	end
	--当前服务器时间是否处于活动时间
	if index >= 1 and index <= 6 then
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		if curTime2Day < g_StartTime or curTime2Day > g_EndTime then
			PushDebugMessage("#{DWKC_190502_33}")
			g_Tab[index]:SetCheck(0)
			g_Tab[g_Select]:SetCheck(1)
			return 
		end
	end
	if index == 7 then
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		if curTime2Day < g_StartFanLiTime or curTime2Day > g_EndFanLiTime then
			PushDebugMessage("#{DWKC_190502_33}")
			g_Tab[index]:SetCheck(0)
			g_Tab[g_Select]:SetCheck(1)
			return 
		end
	end
	if index >= 1 and index <= 7 then
		g_Tab[g_Select]:SetCheck(0)
		g_Select = index
		g_Tab[g_Select]:SetCheck(1)
		DuanWu_Boat_CleanData()
		DuanWu_Boat_ShowFrame()
	end

end

--物品选择按钮
function DuanWu_Boat_ChooseReward(index)
	--当前界面是否是兑换界面
	if g_Select == 6 then
		return
	end

	--当前奖池状态是否是已完成状态
	if 1 == DuanWu_Boat_CheckIsFull(g_Select) then
		return
	end
	--领奖角色等级是否大于等于30级
	if Player:GetLevel() < 30 then
		PushDebugMessage("#{DWKC_190502_32}")
		return
	end
	--当前服务器时间是否处于活动时间
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if curTime2Day < g_StartTime or curTime2Day > g_EndTime then
		PushDebugMessage("#{DWKC_190502_33}")
		return 
	end
	local total = 0
	for i = 1, table.getn(g_ClientSelected) do
		if g_ClientSelected[i] == 1 then
			total = total + 1
		end
	end

	--点击的道具状态是否是已选择状态
	if g_ClientSelected[index] == 1 then
		total = total - 1
		if g_Select == 1 then
			g_Client1Mask[index]:Hide()
			DuanWu_Boat_Client1_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[1]))
		elseif g_Select == 2 then
			g_Client2Mask[index]:Hide()
			DuanWu_Boat_Client2_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[2]))
		elseif g_Select == 3 then
			g_Client3Mask[index]:Hide()
			DuanWu_Boat_Client3_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[3]))
		elseif g_Select == 4 then
			g_Client4Mask[index]:Hide()
			DuanWu_Boat_Client4_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[4]))
		elseif g_Select == 5 then
			g_Client5Mask[index]:Hide()
			DuanWu_Boat_Client5_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[5]))
		else
			return
		end
		g_ClientSelected[index] = 0
		return
	end
	--当前已选择的道具栏数是否已超最大值
	
	if total >= g_MaxPoolSelect[g_Select] then
		PushDebugMessage("#{DWKC_190502_34}")
		return
	end

	g_ClientSelected[index] = 1
	total = total + 1
	if g_Select == 1 then
		g_Client1Mask[index]:Show()
		if total >= g_MaxPoolSelect[1] then
			DuanWu_Boat_Client1_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_15}", total, g_MaxPoolSelect[1]))
		else
			DuanWu_Boat_Client1_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[1]))
		end
	elseif g_Select == 2 then
		g_Client2Mask[index]:Show()
		if total >= g_MaxPoolSelect[2] then
			DuanWu_Boat_Client2_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_19}", total, g_MaxPoolSelect[2]))
		else
			DuanWu_Boat_Client2_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[2]))
		end
		
	elseif g_Select == 3 then
		g_Client3Mask[index]:Show()
		if total >= g_MaxPoolSelect[3] then
			DuanWu_Boat_Client3_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_23}", total, g_MaxPoolSelect[3]))
		else
			DuanWu_Boat_Client3_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[3]))
		end
	elseif g_Select == 4 then
		g_Client4Mask[index]:Show()
		if total >= g_MaxPoolSelect[4] then
			DuanWu_Boat_Client4_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_65}", total, g_MaxPoolSelect[4]))
		else
			DuanWu_Boat_Client4_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[4]))
		end
	elseif g_Select == 5 then
		g_Client5Mask[index]:Show()
		if total >= g_MaxPoolSelect[5] then
			DuanWu_Boat_Client5_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_65}", total, g_MaxPoolSelect[5]))
		else
			DuanWu_Boat_Client5_Num:SetText(ScriptGlobal_Format("#{DWKC_190502_69}", total, g_MaxPoolSelect[5]))
		end
	else
		return
	end
end

function DuanWu_Boat_OnClientBtnClick()
	--领奖角色等级是否大于等于30级
	if Player:GetLevel() < 30 then
		PushDebugMessage("#{DWKC_190502_32}")
		return
	end
	--当前服务器时间是否处于活动时间
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if curTime2Day < g_StartTime or curTime2Day > g_EndTime then
		PushDebugMessage("#{DWKC_190502_33}")
		return 
	end
	--当前奖池是否选择了对应个数的道具
	local selectIndex = {0,0,0,0}

	local total = 0
	--g_ClientSelected 当前选择的索引 1 - 10
	for i = 1, table.getn(g_ClientSelected) do
		if g_ClientSelected[i] == 1 then
			total = total + 1
			selectIndex[total] = i
		end
	end
	--没选够
	if total < g_MaxPoolSelect[g_Select] then
		PushDebugMessage("#{DWKC_190502_35}")
		return
	end

	if total > g_MaxPoolSelect[g_Select] then
		PushDebugMessage("#{DWKC_190502_34}")
		return
	end
	--弹出确认框
	PushEvent("UI_COMMAND", 50508703, g_Select, selectIndex[1], selectIndex[2], selectIndex[3], selectIndex[4])
	return
end

function DuanWu_Boat_StartLottery()
	--领奖角色等级是否大于等于30级
	if Player:GetLevel() < 30 then
		PushDebugMessage("#{DWKC_190502_32}")
		return
	end
	--当前服务器时间是否处于活动时间
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if curTime2Day < g_StartTime or curTime2Day > g_EndTime then
		PushDebugMessage("#{DWKC_190502_33}")
		return 
	end
	--判断是否处于兑换CD中
	local curTime = OSAPI:GetTickCount();
	if curTime - g_LastClickTime < 4000 then
		PushDebugMessage("#{DWKC_190502_39}")
		return
	end
	g_LastClickTime = curTime
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("StartLottery")
		Set_XSCRIPT_ScriptID(505087)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function DuanWu_Boat_Start()
	if(IsWindowShow("Packet")) then
		CloseWindow("Packet", true)
	end
	g_Client6ItemAnimate[1]:Show()
	SetTimer("DuanWu_Boat","DuanWu_Boat_Tick()", g_lottery.minSpeed)
	g_Step = 1
	g_Round = 1
end

function DuanWu_Boat_Tick()
	KillTimer("DuanWu_Boat_Tick()")
	g_Client6ItemAnimate[g_Step]:Hide()
	if g_Step < 12 and g_Round < g_lottery.round then
		g_Step = g_Step + 1
	elseif g_Step >= 12 and g_Round < g_lottery.round then
		g_Step = 1
		g_Round = g_Round + 1
	elseif g_Round == g_lottery.round and g_Step < g_Result then
		g_Step = g_Step + 1
	elseif g_Round == g_lottery.round and g_Step == g_Result then
		--g_Client6ItemAnimate[g_Step]:Show()
		DuanWu_Boat_End()
		return
	else

	end
	g_Client6ItemAnimate[g_Step]:Show()
	SetTimer("DuanWu_Boat","DuanWu_Boat_Tick()", g_lottery.minSpeed + g_lottery.decay * (g_Step + 12 * g_Round))
end

function DuanWu_Boat_End()
	--KillTimer("DuanWu_Boat_End()")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GongGao")
		Set_XSCRIPT_ScriptID(505087)
		Set_XSCRIPT_Parameter(0,g_Bonus)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	g_Client6ItemAnimate[g_Result]:Hide()
	PushDebugMessage(g_Text)
	DuanWu_Boat_ShowLotteryHotPoint()
	DuanWu_Boat_ShowFanLiHotPoint()
	--DuanWu_Boat_ShowLottery()
	DuanWu_Boat_ShowTab()
	DuanWu_Boat_ShowResult()
	g_Step = 0
	g_Round = 0
	g_Result = 0
	g_Text = 0
	g_Bonus = 0
	--SetNotifyTip(g_Text)
end

function DuanWu_Boat_ShowResult()
	DuanWu_Boat_Client6_ItemClient:Hide()
	DuanWu_Boat_Client6Get:Show()
	local pos = g_Map[g_Result]
	local poolId,ShowItemId,ItemCount = Lua_GetSelectedAward(pos)--获得表里的道具
	local theAction = DataPool:CreateActionItemForShow(ShowItemId, 1)
	if (theAction:GetID()~=0) then
		DuanWu_Boat_Client6GetItem:SetActionItem(theAction:GetID())
		if ItemCount > 1 then
			DuanWu_Boat_Client6GetItemNum:SetText(ItemCount)
		else
			DuanWu_Boat_Client6GetItemNum:SetText("")
		end
	end
end

--*********************************
-- 清空控件
--*********************************
function DuanWu_Boat_CleanupUIControls()
	KillTimer("DuanWu_Boat_Tick()")
	if g_Bonus > 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GongGao")
			Set_XSCRIPT_ScriptID(505087)
			Set_XSCRIPT_Parameter(0,g_Bonus)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
	if g_Text ~= nil and g_Text ~= 0 then
		PushDebugMessage(g_Text)
	end
	SetDefaultMouse()
	g_LastClickItem = 0
	g_Select = 0
	g_HaveNum = 0
	g_Result = 0
	g_Bonus = 0
	g_Text = 0
	DuanWu_Boat_CleanData()
	
end

function DuanWu_Boat_Close()
	DuanWu_Boat_CleanupUIControls()
end

function DuanWu_Boat_OnHide()
	DuanWu_Boat_ClosePetEgg()
	DuanWu_Boat_CleanupUIControls()
	for i = 1, table.getn(g_Tab) do
		g_Tab[i]:SetCheck(0)
	end
	DuanWu_Boat_FlashRedPoint()
	this:Hide()
	PushEvent("CLOSE_DUANWU_BOAT_MBUY")
end

function DuanWu_Boat_ShowFanLiFrame()
	DuanWu_Boat_Client1:Hide()
	DuanWu_Boat_Client2:Hide()
	DuanWu_Boat_Client3:Hide()
	DuanWu_Boat_Client4:Hide()
	DuanWu_Boat_Client5:Hide()
	DuanWu_Boat_Client6:Hide()
	DuanWu_Boat_Client6Get:Hide()
	DuanWu_Boat_Client7:Show()
	DuanWu_Boat_AddCatalog()
end

function DuanWu_Boat_AddCatalog() 
	DuanWu_Boat_CleanActionItemInfo()
	DuanWu_Boat_Client7List:CleanAllElement("DuanWu_Boat") 
	--已经抽奖的次数
	local revNum = Lua_GetDWReceivedNum()
	for i = 1,  table.getn(g_GiftsImage) do
		local ItemBar = DuanWu_Boat_Client7List:AddItemElement( "DuanWuBoat", "LEFT", "DuanWu_Boat","" ,"")
		if ItemBar == nil then
			return
		end
		ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
		ItemBar:Setm_newImage(1,g_GiftsImage[i].Set, g_GiftsImage[i].Image)
		
		for x = 1,  4 do
			local itemButton  = 	ItemBar:GetLuaActionButton(x,"DuanWu_Boat")
			itemButton:SetProperty("Visible","False")
		end

		local GiftsList = g_Gifts
		if Player:GetData("IsOriginalJD") == 1 then
			GiftsList = g_Gifts_Ori
		end

		for j = 1,  table.getn(GiftsList[i]) do
			local itemButton  = 	ItemBar:GetLuaActionButton(j,"DuanWu_Boat")
			local GiftItemID	=	GiftsList[i][j].GiftItemID
			local GiftItemNum	= 	GiftsList[i][j].num
			local theAction 	= 	DataPool:CreateBindActionItemForShow(GiftItemID, GiftItemNum)
			if theAction:GetID() ~= 0 then 
				itemButton:SetActionItem(theAction:GetID())
				itemButton:SetProperty("Visible","true")
			end
		end
		if i <= 6 then
			ItemBar:Setm_newImageHide(4)
		end

		if revNum >= i then
			ItemBar:Setm_newText(1,ScriptGlobal_Format("#{DWKC_190502_47}", g_FanLiNeed[i]))
		else
			ItemBar:Setm_newText(1,ScriptGlobal_Format("#{DWKC_190502_48}", g_FanLiNeed[i]))
		end
		local isReceived = Lua_IsDWFanLiReceived(i)
		if isReceived == nil then
			return
		end

		--可领取
		if(revNum >= i and isReceived == 0) then
			ItemBar:Setm_newImageHide(7)
			ItemBar:SetButton1Show()
		elseif (revNum >= i and isReceived == 1) then--已领取
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImage(7,"DuanWu6", "BWBoatBtn_Dis2")
			ItemBar:Setm_newImageShow(7)
		elseif (revNum < i) then--不可领取
			ItemBar:Setm_newImage(7,"DuanWu6", "BWBoatBtn_Dis1")
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImageShow(7)
		end
		
		table.insert(g_FanLiList,ItemBar)
	end
	if revNum > 0 then
		DuanWu_Boat_Client7ListText:SetText(ScriptGlobal_Format("#{DWKC_190502_80}", g_FanLiNeed[revNum]))
	else
		DuanWu_Boat_Client7ListText:SetText(ScriptGlobal_Format("#{DWKC_190502_80}", 0))
	end
	DuanWu_Boat_Client7List:Flash()
end

function DuanWu_Boat_CleanActionItemInfo()
	for i = 1, table.getn(g_GiftsImage) do
		if nil ~= g_FanLiList[i] then
			for j = 1, 4 do
				local itemButton = g_FanLiList[i]:GetLuaActionButton(j,"DuanWu_Boat")
				if nil ~= itemButton then
					itemButton:SetActionItem(-1)
					itemButton:SetProperty("Visible","False")
				end
			end
		end
	end 
	g_FanLiList = {}
end

function DuanWu_Boat_OnLingQuClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1
	if nil ~= g_FanLiList[nIndex] then
	    --begin当前服务器时间是否处于活动时间
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		if curTime2Day < g_StartFanLiTime or curTime2Day > g_EndFanLiTime then
			PushDebugMessage("#{DWKC_190502_51}")
			return 
		end
		--领奖角色等级是否大于等于30级
		if Player:GetLevel() < 30 then
			PushDebugMessage("#{DWKC_190502_52}")
			return
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Fanli")
			Set_XSCRIPT_ScriptID(505087)
			Set_XSCRIPT_Parameter(0,nIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		g_FanLiList[nIndex]:SetBarButtonSelected(false)
		DuanWu_Boat_Client7List:Flash()
	end
end

--帮助按钮
function DuanWu_Boat_Help()
	PushEvent( "OPEN_HUODONGTEXT_HELP", 3, "#{DWKC_190502_5}" )
end

function DuanWu_Boat_ButtonLClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1 --第几条对应第几场
	for i = 1, table.getn(g_FanLiList) do
		if i == nIndex then
			if nil ~= g_FanLiList[i] then
				local itemBar = g_FanLiList[i]
				itemBar:SetBarButtonSelected(true)
			end
		else
			if nil ~= g_FanLiList[i] then
				local itemBar = g_FanLiList[i]
				itemBar:SetBarButtonSelected(false)
			end
		end
	end
	DuanWu_Boat_Client7List:Flash()
end

function DuanWu_Boat_ShowFanLiHotPoint()
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if curTime2Day < g_StartTime or curTime2Day > g_EndFanLiTime then
		DuanWu_Boat_tab7_Tips:Hide()
		return
	end
	local revNum = Lua_GetDWReceivedNum()
	for i = 1, revNum do
		local isReceived = Lua_IsDWFanLiReceived(i)
		if isReceived == 0 then
			DuanWu_Boat_tab7_Tips:Show()
			return
		end
	end
	DuanWu_Boat_tab7_Tips:Hide()
end

function DuanWu_Boat_ShowLotteryHotPoint()
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if curTime2Day < g_StartTime or curTime2Day > g_EndTime then
		DuanWu_Boat_tab6_Tips:Hide()
		return
	end
	local selectNum = Lua_GetDWSelectNum()
	if selectNum < 12 then
		DuanWu_Boat_tab6_Tips:Hide()
		return
	end
	local revNum = Lua_GetDWReceivedNum()
	if revNum < 12 and g_LotteryNeedNum[revNum + 1] <= g_HaveNum then
		 DuanWu_Boat_tab6_Tips:Show()
		 return
	end
	DuanWu_Boat_tab6_Tips:Hide()
end

function DuanWu_Boat_CloseResult()
	DuanWu_Boat_Client6Get:Hide()
	DuanWu_Boat_Client6GetItem:SetActionItem(-1)
	DuanWu_Boat_ShowLottery()
end

function DuanWu_Boat_FlashRedPoint()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowButtonTips")
		Set_XSCRIPT_ScriptID(893117)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function DuanWu_Boat_ShowPetEgg()
	PushEvent("UI_COMMAND", 50508709,1)
end

function DuanWu_Boat_ClosePetEgg()
	PushEvent("UI_COMMAND", 50508709,2)
end

function DuanWu_Boat_OnView()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		--Set_XSCRIPT_Parameter(0, 10126466) 
		--Set_XSCRIPT_Parameter(1, 123)
		--Set_XSCRIPT_Parameter(2, 91)
		Set_XSCRIPT_Parameter(0, 10128736)
		Set_XSCRIPT_Parameter(1, 295)--hair
		Set_XSCRIPT_Parameter(2, 214)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function DuanWu_Boat_DaibiBuy_BtnClicked()
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if curTime2Day < g_StartTime or curTime2Day > g_EndTime then
		PushDebugMessage("#{DWKC_20210508_07}")
		return
	end
	local revNum = Lua_GetDWReceivedNum()
	if revNum > 0 then
		PushEvent("OPEN_DUANWU_BOAT_MBUY", g_HaveNum, g_FanLiNeed[revNum])
	else
		PushEvent("OPEN_DUANWU_BOAT_MBUY", g_HaveNum, 0)
	end
end

function DuanWu_Boat_FanLiView()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		--Set_XSCRIPT_Parameter(0, 10126466) 
		--Set_XSCRIPT_Parameter(1, 123)
		--Set_XSCRIPT_Parameter(2, 91)
		Set_XSCRIPT_Parameter(0, 10128752)
		Set_XSCRIPT_Parameter(1, 296)--hair
		Set_XSCRIPT_Parameter(2, 214)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end