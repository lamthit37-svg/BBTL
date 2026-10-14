--XiGuaJie_Activity
local g_XiGuaJie_Activity_UnifiedPosition;
local XiGuaJie_Activity_pagebuttonleft = {}
local XiGuaJie_Activity_Reward = {
	[1] = {},
	[2] = {},
	[3] = {},
}
local XiGuaJie_Activity_Reward_Limit = {
	[1] = {},
	[2] = {},
	[3] = {},
}
local XiGuaJie_Activity_Reward_Get = {}
local XiGuaJie_Activity_Licheng_Reward = {}
local XiGuaJie_Activity_Licheng_Mask = {}
local XiGuaJie_Activity_Licheng_RedDot = {}
local XiGuaJie_Activity_Licheng_Text = {}
local XiGuaJie_Activity_OnceReturn_Animate = {}
----------
local XiGuaJie_Activity_Change_ActionButton = {
	[1] = {},
	[2] = {},
	[3] = {},
}
local XiGuaJie_Activity_Change_Mask = {
	[1] = {},
	[2] = {},
	[3] = {},
}
local XiGuaJie_Activity_Change_Limit = {
	[1] = {},
	[2] = {},
	[3] = {},
}
local XiGuaJie_Activity_Change_level = {}
local XiGuaJie_Activity_Change_Animate = {}

local XiGuaJie_Activity_BGImage = {
	[1] = "set:XiGuaJie15 image:XBHFX_Level3_Tip",
	[2] = "set:XiGuaJie15 image:XBHFX_Level2_Tip",
	[3] = "set:XiGuaJie15 image:XBHFX_Level1_Tip",
}
local g_AnimateTick = 0
local g_curpageIndex = 0
local g_curDaibiCount = 0

--抽奖一次所需代币数
local g_Choujiang_Need = 4
local g_ChouajiangState = 0

local g_rewardlist = {}
g_rewardlist[1] = {
  [1] ={id=38006065,num =1,nBind = 0,isLimit=1,nbroad = 1},
  [2] ={id=38006410,num =1,nBind = 0,isLimit=1,nbroad = 1},
  [3] ={id=10141452,num =1,nBind = 0,isLimit=0,nbroad = 1},
  [4] ={id=38004734,num =10,nBind = 0,isLimit=0,nbroad = 0},
  [5] ={id=38004805,num =10,nBind = 0,isLimit=0,nbroad = 0},
  [6] ={id=38004358,num =2,nBind = 1,isLimit=0,nbroad = 0},
  [7] ={id=38004359,num =1,nBind = 1,isLimit=0,nbroad = 0},
  [8] ={id=38005317,num =1,nBind = 0,isLimit=0,nbroad = 0},
 
}
 g_rewardlist[2] = {
   	[1] ={id=20502003,num =1,nBind = 1,isLimit=0,nbroad = 0}, 
    [2] ={id=20501003,num =1,nBind = 1,isLimit=0,nbroad = 0},
    [3] ={id=20502004,num =1,nBind = 1,isLimit=0,nbroad = 0},
    [4] ={id=20501004,num =1,nBind = 1,isLimit=0,nbroad = 0},
    [5] ={id=20502015,num =1,nBind = 1,isLimit=0,nbroad = 0},
    [6] ={id=20501009,num =1,nBind = 1,isLimit=0,nbroad = 0},
   	[7] ={id=38000992,num =1,nBind = 0,isLimit=0,nbroad = 0}, 
    [8] ={id=38001595,num =1,nBind = 1,isLimit=0,nbroad = 0},
    [9] ={id=38000443,num =1,nBind = 0,isLimit=0,nbroad = 0},
    [10] ={id=38005288,num =2,nBind = 0,isLimit=0,nbroad = 0 },
    [11] ={id=38005898,num =1,nBind = 0,isLimit=0,nbroad = 1},
    [12] ={id=38006510,num =1,nBind = 0,isLimit=1,nbroad = 1},

}
g_rewardlist[3] = {
 [1] ={id=38000807,num =1,nBind = 0,isLimit=0,nbroad = 0},
 [2] ={id=38000807,num =2,nBind = 1,isLimit=0,nbroad = 0},
 [3] ={id=30503188,num =2,nBind = 0,isLimit=0,nbroad = 0},
 [4] ={id=30503188,num =4,nBind = 1,isLimit=0,nbroad = 0},
 [5] ={id=38000378,num =1,nBind = 0,isLimit=0,nbroad = 0},
 [6] ={id=38000378,num =2,nBind = 0,isLimit=0,nbroad = 0},
 [7] ={id=38000571,num =1,nBind = 0,isLimit=0,nbroad = 0},
 [8] ={id=38000571,num =2,nBind = 0,isLimit=0,nbroad = 0},
 [9] ={id=20310168,num =2,nBind = 0,isLimit=0,nbroad = 0},
 [10] ={id=20310168,num =4,nBind = 0,isLimit=0,nbroad = 0},
 [11] ={id=30008034,num =1,nBind = 1,isLimit=0,nbroad = 0},
 [12] ={id=30008034,num =2,nBind = 1,isLimit=0,nbroad = 0},
 [13] ={id=38000656,num =1,nBind = 0,isLimit=0,nbroad = 0},
 [14] ={id=38000656,num =2,nBind = 0,isLimit=0,nbroad = 0},
}
local g_rewardlist_Kaji = {}
g_rewardlist_Kaji[1] = {
 [1] ={id=38006065,num =1,nBind = 0,isLimit=1,nbroad = 1},
 [2] ={id=38006410,num =1,nBind = 0,isLimit=1,nbroad = 1},
 [3] ={id=10141452,num =1,nBind = 0,isLimit=0,nbroad = 1},
 [4] ={id=38000658,num =4,nBind = 0,isLimit=0,nbroad = 0},
 [5] ={id=38000658,num =2,nBind = 0,isLimit=0,nbroad = 0},
 [6] ={id=30700241,num =20,nBind = 1,isLimit=0,nbroad = 0},
 [7] ={id=30700241,num =10,nBind = 1,isLimit=0,nbroad = 0},
 [8] ={id=30008048,num =2,nBind = 0,isLimit=0,nbroad = 0},
 
}
 g_rewardlist_Kaji[2] = {
 [1] ={id=20502003,num =1,nBind = 1,isLimit=0,nbroad = 0}, 
 [2] ={id=20501003,num =1,nBind = 1,isLimit=0,nbroad = 0},
 [3] ={id=20502004,num =1,nBind = 1,isLimit=0,nbroad = 0},
 [4] ={id=20501004,num =1,nBind = 1,isLimit=0,nbroad = 0},
 [5] ={id=20502015,num =1,nBind = 1,isLimit=0,nbroad = 0},
 [6] ={id=20501009,num =1,nBind = 1,isLimit=0,nbroad = 0},
 [7] ={id=38000992,num =1,nBind = 0,isLimit=0,nbroad = 0}, 
 [8] ={id=38001595,num =1,nBind = 1,isLimit=0,nbroad = 0},
 [9] ={id=38000443,num =1,nBind = 0,isLimit=0,nbroad = 0},
 [10] ={id=38005288,num =2,nBind = 0,isLimit=0,nbroad = 0},
 [11] ={id=38005898,num =1,nBind = 0,isLimit=0,nbroad = 1},
 [12] ={id=38006510,num =1,nBind = 0,isLimit=1,nbroad = 1},

}

g_rewardlist_Kaji[3] = {
  [1] ={id=38000807,num =1,nBind = 0,isLimit=0,nbroad = 0},
  [2] ={id=38000807,num =2,nBind = 1,isLimit=0,nbroad = 0},
  [3] ={id=30503188,num =2,nBind = 0,isLimit=0,nbroad = 0},
  [4] ={id=30503188,num =4,nBind = 1,isLimit=0,nbroad = 0},
  [5] ={id=30700249,num =2,nBind = 0,isLimit=0,nbroad = 0},
  [6] ={id=30700249,num =4,nBind = 0,isLimit=0,nbroad = 0},
  [7] ={id=38000571,num =1,nBind = 0,isLimit=0,nbroad = 0},
  [8] ={id=38000571,num =2,nBind = 0,isLimit=0,nbroad = 0},
  [9] ={id=20310168,num =2,nBind = 0,isLimit=0,nbroad = 0},
  [10] ={id=20310168,num =4,nBind = 0,isLimit=0,nbroad = 0},
  [11] ={id=30008034,num =1,nBind = 1,isLimit=0,nbroad = 0},
  [12] ={id=30008034,num =2,nBind = 1,isLimit=0,nbroad = 0},
  [13] ={id=38000656,num =1,nBind = 0,isLimit=0,nbroad = 0},
  [14] ={id=38000656,num =2,nBind = 0,isLimit=0,nbroad = 0},
}
--累计奖励
local g_LichengReward = {
    [1] ={need = 3,tips1="#{XGJHD_220427_42}",tips2="#{XGJHD_220427_32}",text="#{XGJHD_220427_52}",text1="#{XGJHD_220427_97}"},    
    [2] ={need = 9,tips1="#{XGJHD_220427_43}",tips2="#{XGJHD_220427_33}",text="#{XGJHD_220427_53}",text1="#{XGJHD_220427_98}"},   
    [3] ={need = 15,tips1="#{XGJHD_220427_44}",tips2="#{XGJHD_220427_34}",text="#{XGJHD_220427_54}",text1="#{XGJHD_220427_99}"},    
    [4] ={need = 21,tips1="#{XGJHD_220427_45}",tips2="#{XGJHD_220427_35}",text="#{XGJHD_220427_55}",text1="#{XGJHD_220427_100}"},    
    [5] ={need = 36,tips1="#{XGJHD_220427_46}",tips2="#{XGJHD_220427_36}",text="#{XGJHD_220427_56}",text1="#{XGJHD_220427_101}"},   
}
local g_LichengRewardKaji = {
    [1] ={need = 3,tips1="#{XGJHD_220427_47}",tips2="#{XGJHD_220427_37}",text="#{XGJHD_220427_52}",text1="#{XGJHD_220427_97}"},    
    [2] ={need = 9,tips1="#{XGJHD_220427_48}",tips2="#{XGJHD_220427_38}",text="#{XGJHD_220427_53}",text1="#{XGJHD_220427_98}"},   
    [3] ={need = 15,tips1="#{XGJHD_220427_49}",tips2="#{XGJHD_220427_39}",text="#{XGJHD_220427_54}",text1="#{XGJHD_220427_99}"},    
    [4] ={need = 21,tips1="#{XGJHD_220427_50}",tips2="#{XGJHD_220427_40}",text="#{XGJHD_220427_55}",text1="#{XGJHD_220427_100}"},    
    [5] ={need = 36,tips1="#{XGJHD_220427_51}",tips2="#{XGJHD_220427_41}",text="#{XGJHD_220427_56}",text1="#{XGJHD_220427_101}"},   
}

local g_max_reward = {2,4,6}

local g_curRewardItemIndex = {}

local g_rewardflag = {0,0,0}
local g_lichengrewardflag = {0,0,0,0,0}
local g_TotalChoujiang = 0
local g_nlevel = 0
local g_nIndex = 0
local g_nBonusID = 0
local g_nBonusNum = 0
local g_currewardlist = {}
local g_rewardSelect = 0

local g_BeginTime = 20260723
local g_EndTime = 20260806
local g_GetRewardTime = 20260803

function XiGuaJie_Activity_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function XiGuaJie_Activity_OnLoad()

	XiGuaJie_Activity_Reward[1][1] = XiGuaJie_Activity_Reward1_Item1
	XiGuaJie_Activity_Reward[1][2] = XiGuaJie_Activity_Reward1_Item2
	
	XiGuaJie_Activity_Reward[2][1] = XiGuaJie_Activity_Reward2_Item1
	XiGuaJie_Activity_Reward[2][2] = XiGuaJie_Activity_Reward2_Item2
	XiGuaJie_Activity_Reward[2][3] = XiGuaJie_Activity_Reward2_Item3
	XiGuaJie_Activity_Reward[2][4] = XiGuaJie_Activity_Reward2_Item4
	
	XiGuaJie_Activity_Reward[3][1] = XiGuaJie_Activity_Reward3_Item1
	XiGuaJie_Activity_Reward[3][2] = XiGuaJie_Activity_Reward3_Item2
	XiGuaJie_Activity_Reward[3][3] = XiGuaJie_Activity_Reward3_Item3
	XiGuaJie_Activity_Reward[3][4] = XiGuaJie_Activity_Reward3_Item4
	XiGuaJie_Activity_Reward[3][5] = XiGuaJie_Activity_Reward3_Item5
	XiGuaJie_Activity_Reward[3][6] = XiGuaJie_Activity_Reward3_Item6
	
	XiGuaJie_Activity_Reward_Get[1] = XiGuaJie_Activity_Reward1_Get
	XiGuaJie_Activity_Reward_Get[2] = XiGuaJie_Activity_Reward2_Get
	XiGuaJie_Activity_Reward_Get[3] = XiGuaJie_Activity_Reward3_Get
	
	XiGuaJie_Activity_Reward_Limit[1][1] = XiGuaJie_Activity_Reward1_Item1_BuyLimit
	XiGuaJie_Activity_Reward_Limit[1][2] = XiGuaJie_Activity_Reward1_Item2_BuyLimit
	
	XiGuaJie_Activity_Reward_Limit[2][1] = XiGuaJie_Activity_Reward2_Item1_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][2] = XiGuaJie_Activity_Reward2_Item2_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][3] = XiGuaJie_Activity_Reward2_Item3_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][4] = XiGuaJie_Activity_Reward2_Item4_BuyLimit

	XiGuaJie_Activity_Licheng_Reward[1] = XiGuaJie_Activity_Client2_Reward_Lace1Item
	XiGuaJie_Activity_Licheng_Reward[2] = XiGuaJie_Activity_Client2_Reward_Lace2Item
	XiGuaJie_Activity_Licheng_Reward[3] = XiGuaJie_Activity_Client2_Reward_Lace3Item
	XiGuaJie_Activity_Licheng_Reward[4] = XiGuaJie_Activity_Client2_Reward_Lace4Item
	XiGuaJie_Activity_Licheng_Reward[5] = XiGuaJie_Activity_Client2_Reward_Lace5Item

	XiGuaJie_Activity_Licheng_Mask[1] = XiGuaJie_Activity_Client2_Reward_Lace1Item_Mask
	XiGuaJie_Activity_Licheng_Mask[2] = XiGuaJie_Activity_Client2_Reward_Lace2Item_Mask
	XiGuaJie_Activity_Licheng_Mask[3] = XiGuaJie_Activity_Client2_Reward_Lace3Item_Mask
	XiGuaJie_Activity_Licheng_Mask[4] = XiGuaJie_Activity_Client2_Reward_Lace4Item_Mask
	XiGuaJie_Activity_Licheng_Mask[5] = XiGuaJie_Activity_Client2_Reward_Lace5Item_Mask
	
	XiGuaJie_Activity_Licheng_RedDot[1] = XiGuaJie_Activity_Client2_Reward_Lace1Item_RedDot
	XiGuaJie_Activity_Licheng_RedDot[2] = XiGuaJie_Activity_Client2_Reward_Lace2Item_RedDot
	XiGuaJie_Activity_Licheng_RedDot[3] = XiGuaJie_Activity_Client2_Reward_Lace3Item_RedDot
	XiGuaJie_Activity_Licheng_RedDot[4] = XiGuaJie_Activity_Client2_Reward_Lace4Item_RedDot
	XiGuaJie_Activity_Licheng_RedDot[5] = XiGuaJie_Activity_Client2_Reward_Lace5Item_RedDot
	
	XiGuaJie_Activity_Licheng_Text[1] = XiGuaJie_Activity_Client2_Reward_Lace1Item_Tip
	XiGuaJie_Activity_Licheng_Text[2] = XiGuaJie_Activity_Client2_Reward_Lace2Item_Tip
	XiGuaJie_Activity_Licheng_Text[3] = XiGuaJie_Activity_Client2_Reward_Lace3Item_Tip
	XiGuaJie_Activity_Licheng_Text[4] = XiGuaJie_Activity_Client2_Reward_Lace4Item_Tip
	XiGuaJie_Activity_Licheng_Text[5] = XiGuaJie_Activity_Client2_Reward_Lace5Item_Tip
	
	XiGuaJie_Activity_OnceReturn_Animate[1] = XiGuaJie_Activity_OnceReturn_Animate3
	XiGuaJie_Activity_OnceReturn_Animate[2] = XiGuaJie_Activity_OnceReturn_Animate2
	XiGuaJie_Activity_OnceReturn_Animate[3] = XiGuaJie_Activity_OnceReturn_Animate1
	
	XiGuaJie_Activity_ChangeFrame_OnLoad()
	
	g_XiGuaJie_Activity_UnifiedPosition = XiGuaJie_Activity_MainFrame:GetProperty("UnifiedPosition")
	
end

function XiGuaJie_Activity_ChangeFrame_OnLoad()	

	XiGuaJie_Activity_Change_ActionButton[1][1] = XiGuaJie_Activity_Change_Old_level3_Icon1
	XiGuaJie_Activity_Change_ActionButton[1][2] = XiGuaJie_Activity_Change_Old_level3_Icon2
	
	XiGuaJie_Activity_Change_ActionButton[2][1] = XiGuaJie_Activity_Change_Old_level2_Icon1
	XiGuaJie_Activity_Change_ActionButton[2][2] = XiGuaJie_Activity_Change_Old_level2_Icon2
	XiGuaJie_Activity_Change_ActionButton[2][3] = XiGuaJie_Activity_Change_Old_level2_Icon3
	XiGuaJie_Activity_Change_ActionButton[2][4] = XiGuaJie_Activity_Change_Old_level2_Icon4
	
	XiGuaJie_Activity_Change_ActionButton[3][1] = XiGuaJie_Activity_Change_Old_level1_Icon1
	XiGuaJie_Activity_Change_ActionButton[3][2] = XiGuaJie_Activity_Change_Old_level1_Icon2
	XiGuaJie_Activity_Change_ActionButton[3][3] = XiGuaJie_Activity_Change_Old_level1_Icon3
	XiGuaJie_Activity_Change_ActionButton[3][4] = XiGuaJie_Activity_Change_Old_level1_Icon4
	XiGuaJie_Activity_Change_ActionButton[3][5] = XiGuaJie_Activity_Change_Old_level1_Icon5
	XiGuaJie_Activity_Change_ActionButton[3][6] = XiGuaJie_Activity_Change_Old_level1_Icon6
	
	XiGuaJie_Activity_Change_Limit[1][1] = XiGuaJie_Activity_Change_Old_level3_Icon1_BuyLimit
	XiGuaJie_Activity_Change_Limit[1][2] = XiGuaJie_Activity_Change_Old_level3_Icon2_BuyLimit
	
	XiGuaJie_Activity_Change_Limit[2][1] = XiGuaJie_Activity_Change_Old_level2_Icon1_BuyLimit
	XiGuaJie_Activity_Change_Limit[2][2] = XiGuaJie_Activity_Change_Old_level2_Icon2_BuyLimit
	XiGuaJie_Activity_Change_Limit[2][3] = XiGuaJie_Activity_Change_Old_level2_Icon3_BuyLimit
	XiGuaJie_Activity_Change_Limit[2][4] = XiGuaJie_Activity_Change_Old_level2_Icon4_BuyLimit
	
	XiGuaJie_Activity_Change_Mask[1][1] = XiGuaJie_Activity_Change_Old_level3_Icon1_Mask
	XiGuaJie_Activity_Change_Mask[1][2] = XiGuaJie_Activity_Change_Old_level3_Icon2_Mask
	
	XiGuaJie_Activity_Change_Mask[2][1] = XiGuaJie_Activity_Change_Old_level2_Icon1_Mask
	XiGuaJie_Activity_Change_Mask[2][2] = XiGuaJie_Activity_Change_Old_level2_Icon2_Mask
	XiGuaJie_Activity_Change_Mask[2][3] = XiGuaJie_Activity_Change_Old_level2_Icon3_Mask
	XiGuaJie_Activity_Change_Mask[2][4] = XiGuaJie_Activity_Change_Old_level2_Icon4_Mask
	
	XiGuaJie_Activity_Change_Mask[3][1] = XiGuaJie_Activity_Change_Old_level1_Icon1_Mask
	XiGuaJie_Activity_Change_Mask[3][2] = XiGuaJie_Activity_Change_Old_level1_Icon2_Mask
	XiGuaJie_Activity_Change_Mask[3][3] = XiGuaJie_Activity_Change_Old_level1_Icon3_Mask
	XiGuaJie_Activity_Change_Mask[3][4] = XiGuaJie_Activity_Change_Old_level1_Icon4_Mask
	XiGuaJie_Activity_Change_Mask[3][5] = XiGuaJie_Activity_Change_Old_level1_Icon5_Mask
	XiGuaJie_Activity_Change_Mask[3][6] = XiGuaJie_Activity_Change_Old_level1_Icon6_Mask
	
	XiGuaJie_Activity_Change_level[1] = XiGuaJie_Activity_Change_Old_level3
	XiGuaJie_Activity_Change_level[2] = XiGuaJie_Activity_Change_Old_level2
	XiGuaJie_Activity_Change_level[3] = XiGuaJie_Activity_Change_Old_level1
	
	XiGuaJie_Activity_Change_Animate[1] = XiGuaJie_Activity_Change_Animate3
	XiGuaJie_Activity_Change_Animate[2] = XiGuaJie_Activity_Change_Animate2
	XiGuaJie_Activity_Change_Animate[3] = XiGuaJie_Activity_Change_Animate1
	
end

function XiGuaJie_Activity_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99801701 ) then

		local operator = Get_XParam_INT(0)
		local point = 1
		for i = 1, 3 do
			for j = 1, g_max_reward[i] do
				local itemindex = Get_XParam_INT(point)
				g_curRewardItemIndex[point] = itemindex
				point = point + 1
			end
		end
			
		g_curDaibiCount = Get_XParam_INT(point)
		g_TotalChoujiang = Get_XParam_INT(point+1)
			
		if operator == 1 then
			g_curpageIndex = 1

			XiGuaJie_Activity_Update()
		elseif operator == 2 then
			XiGuaJie_Activity_Update_Client1()		
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99801702 ) then 
		local operator = Get_XParam_INT(0)
		for i = 1, 5 do
			g_lichengrewardflag[i] = Get_XParam_INT(i)
		end
		g_TotalChoujiang = Get_XParam_INT(6)
		
		if operator == 1 then
			--g_curpageIndex = 2
			--if IsWindowShow("XiGuaJie_Activity_OnceReturn") then
			--	CloseWindow("XiGuaJie_Activity_OnceReturn", true)
			--end
			--if IsWindowShow("XiGuaJie_Activity_Reward") then
			--	CloseWindow("XiGuaJie_Activity_Reward", true)
			--end
			
			--XiGuaJie_Activity_Update()	
		elseif operator == 2 then
			XiGuaJie_Activity_Update_Client2()
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99801703 ) then --获奖界面
		local operator = Get_XParam_INT(0)
		if operator == 1 then
			g_nlevel = Get_XParam_INT(1)
			g_nIndex = Get_XParam_INT(2)
			g_nBonusID = Get_XParam_INT(3)
			g_nBonusNum = Get_XParam_INT(4)
			
			XiGuaJie_Activity_Update_Client3()
			g_ChouajiangState = 1
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99801705 ) then
		for i = 1, 3 do
			g_rewardflag[i] = Get_XParam_INT(i-1)
		end	
		XiGuaJie_Activity_Update_Client1()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99801706 ) then --替换界面
		local operator = Get_XParam_INT(0)
		if operator == 1 then
			g_nlevel = Get_XParam_INT(1)
			g_nIndex = Get_XParam_INT(2)
			g_nBonusID = Get_XParam_INT(3)
			g_nBonusNum = Get_XParam_INT(4)
			g_curDaibiCount = Get_XParam_INT(5)
			for i = 1, g_max_reward[g_nlevel] do
				g_currewardlist[i] = Get_XParam_INT(i+5)
			end
			XiGuaJie_Activity_Update_Client4()
			g_ChouajiangState = 3
		elseif operator == 0 then --关闭
			XiGuaJie_Activity_Change_Close()
		end
	elseif (event == "ADJEST_UI_POS" ) then
		XiGuaJie_Activity_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiGuaJie_Activity_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()

	end

end

--=========================================================
--更新界面
--=========================================================
function XiGuaJie_Activity_Update()
	g_ChouajiangState = 0
	if g_curpageIndex == 1 then
		XiGuaJie_Activity_OnceReturn_Frame:Hide()
		XiGuaJie_Activity_Change_Frame:Hide()
		XiGuaJie_Activity_Frame_Client:Show()
		XiGuaJie_Activity_Reward1_Item:Show()
		XiGuaJie_Activity_Reward2_Item:Show()
		XiGuaJie_Activity_Reward3_Item:Show()
		XiGuaJie_Activity_Frame_XiGuaNum:Show()
		XiGuaJie_Activity_Update_Client1()
	end

	this:Show()
end

--更新抽奖界面
function XiGuaJie_Activity_Update_Client1()
	local point = 1
	local rewardCount = {0,0,0}
	for i = 1, 3 do
		for j = 1, g_max_reward[i] do
			if i >= 1 and i <= 2 then
				XiGuaJie_Activity_Reward_Limit[i][j]:Hide()
			end
			local ItemIndex = g_curRewardItemIndex[point]
			if ItemIndex > 0 then
				local rewardlist = nil
				local kajiType = KaJi:LuaFnGetKaJiType(83)
				if kajiType == 1 then
					rewardlist = g_rewardlist_Kaji
				else
					rewardlist = g_rewardlist
				end
				if Player:GetData("IsOriginalJD") == 1 then
					rewardlist = g_rewardlist_Kaji
				end
				local nShowItemId = rewardlist[i][ItemIndex].id
				local nItemNum = rewardlist[i][ItemIndex].num
				local nIsBind = rewardlist[i][ItemIndex].nBind
				local IsLimit = rewardlist[i][ItemIndex].isLimit
				if nIsBind == 1 then
					local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
					XiGuaJie_Activity_Reward[i][j]:SetActionItem(theAction:GetID())
				else
					local theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
					XiGuaJie_Activity_Reward[i][j]:SetActionItem(theAction:GetID())
				end
				
				--限量
				if i >= 1 and i <= 2 then
					if IsLimit == 1 then
						XiGuaJie_Activity_Reward_Limit[i][j]:Show()
					else
						XiGuaJie_Activity_Reward_Limit[i][j]:Hide()
					end
				end
				rewardCount[i] = rewardCount[i]+1
			end
			point = point + 1
		end
	end
	XiGuaJie_Activity_XiGuaNum:SetText(ScriptGlobal_Format( "#{XGJHD_220427_07}",g_curDaibiCount))
	--XiGuaJie_Activity_ChouJiangNum:SetText(ScriptGlobal_Format( "#{XGJHD_220427_08}",g_TotalChoujiang))
	
	--按钮显示
	local curDay = tonumber(DataPool:GetServerDayTime());
	if curDay >= g_BeginTime and curDay < g_GetRewardTime then
		XiGuaJie_Activity_Frame_ChouQu:Show()
		XiGuaJie_Activity_Reward1_Get:Hide()
		XiGuaJie_Activity_Reward2_Get:Hide()
		XiGuaJie_Activity_Reward3_Get:Hide()
		if g_curDaibiCount >= g_Choujiang_Need then --红点
			XiGuaJie_Activity_ChouQu_Tips:Show()
		else
			XiGuaJie_Activity_ChouQu_Tips:Hide()
		end
		
	elseif curDay >= g_GetRewardTime and curDay <= g_EndTime then
		XiGuaJie_Activity_Frame_ChouQu:Hide()
		XiGuaJie_Activity_Reward1_Get:Show()
		XiGuaJie_Activity_Reward2_Get:Show()
		XiGuaJie_Activity_Reward3_Get:Show()	
		for i = 1, 3 do
			if g_rewardflag[i] == 0 then
				XiGuaJie_Activity_Reward_Get[i]:Enable()
				if rewardCount[i] > 0 then
				end
			elseif g_rewardflag[i] == 1 then
				XiGuaJie_Activity_Reward_Get[i]:Disable()
			end
		end
	end
	

end

--更新累计奖励界面
function XiGuaJie_Activity_Update_Client2()
	for i = 1, 5 do
		if g_lichengrewardflag[i] == 1 then --已领取
			XiGuaJie_Activity_Licheng_Mask[i]:Show()
			XiGuaJie_Activity_Licheng_Reward[i]:Disable()
			XiGuaJie_Activity_Licheng_RedDot[i]:Hide()
		else
			XiGuaJie_Activity_Licheng_Mask[i]:Hide()
			XiGuaJie_Activity_Licheng_Reward[i]:Enable()
			if g_TotalChoujiang >= g_LichengReward[i].need then --可领取
				XiGuaJie_Activity_Licheng_RedDot[i]:Show()
				local kajiType = KaJi:LuaFnGetKaJiType(83)
				if Player:GetData("IsOriginalJD") == 1 then
					XiGuaJie_Activity_Licheng_Reward[i]:SetToolTip(g_LichengRewardKaji[i].tips2)
				else				
					if kajiType == 1 then
						XiGuaJie_Activity_Licheng_Reward[i]:SetToolTip(g_LichengRewardKaji[i].tips2)
					else
						XiGuaJie_Activity_Licheng_Reward[i]:SetToolTip(g_LichengReward[i].tips2)
					end
				end
			else
				XiGuaJie_Activity_Licheng_RedDot[i]:Hide()
				local kajiType = KaJi:LuaFnGetKaJiType(83)
				if Player:GetData("IsOriginalJD") == 1 then
					XiGuaJie_Activity_Licheng_Reward[i]:SetToolTip(g_LichengRewardKaji[i].tips1)
				else
					if kajiType == 1 then
						XiGuaJie_Activity_Licheng_Reward[i]:SetToolTip(g_LichengRewardKaji[i].tips1)
					else
						XiGuaJie_Activity_Licheng_Reward[i]:SetToolTip(g_LichengReward[i].tips1)
					end
				end
			end
		end
		
		if g_TotalChoujiang >= g_LichengReward[i].need then
			local str = ScriptGlobal_Format( g_LichengReward[i].text, g_LichengReward[i].need)
			XiGuaJie_Activity_Licheng_Text[i]:SetText(str) 
		else
			local str = ScriptGlobal_Format( g_LichengReward[i].text1, g_TotalChoujiang)
			XiGuaJie_Activity_Licheng_Text[i]:SetText(str) 
		end
	end
	
end

--=========================================================
--获奖界面
--=========================================================
function XiGuaJie_Activity_Update_Client3()
	XiGuaJie_Activity_Reward1_Item:Hide()
	XiGuaJie_Activity_Reward2_Item:Hide()
	XiGuaJie_Activity_Reward3_Item:Hide()
	XiGuaJie_Activity_Frame_XiGuaNum:Hide()
	
	XiGuaJie_Activity_OnceReturn_Frame:Show()
	
	XiGuaJie_Activity_OnceReturn_TitlePic:Hide()
	XiGuaJie_Activity_OnceReturn_Pic:Hide()

	XiGuaJie_Activity_OnceReturn_Item2_Frame:Hide()
	
	for i = 1, 3 do
		XiGuaJie_Activity_OnceReturn_Animate[i]:Hide()
	end
	XiGuaJie_Activity_OnceReturn_Animate_Pen:Play(false)
	
	if g_nlevel >= 1 and g_nlevel <= 3 then
		XiGuaJie_Activity_OnceReturn_Animate[g_nlevel]:Show()
		XiGuaJie_Activity_OnceReturn_PlayAnimate()
		XiGuaJie_Activity_OnceReturn_Animate_Pen:Play(true)
	end

end

--渐变动画
function XiGuaJie_Activity_OnceReturn_PlayAnimate()
	if g_nlevel >= 1 and g_nlevel <= 3 then
		g_AnimateTick = 0
		XiGuaJie_Activity_OnceReturn_Animate[g_nlevel]:SetProperty("Alpha",0)
		KillTimer("XiGuaJie_Activity_OnceReturn_AnimateTimer()")
	
		SetTimer("XiGuaJie_Activity","XiGuaJie_Activity_OnceReturn_AnimateTimer()", 280)--计时器
	end
end

function XiGuaJie_Activity_OnceReturn_AnimateTimer()
	if g_nlevel >= 1 and g_nlevel <= 3 then
		g_AnimateTick = g_AnimateTick+1
		if g_AnimateTick >= 10 then
			g_AnimateTick = 0
			XiGuaJie_Activity_OnceReturn_Animate[g_nlevel]:SetProperty("Alpha",1)
			KillTimer("XiGuaJie_Activity_OnceReturn_AnimateTimer()")
		else
			XiGuaJie_Activity_OnceReturn_Animate[g_nlevel]:SetProperty("Alpha",g_AnimateTick*0.1)
		end
	end
end

function XiGuaJie_Activity_OnceReturn_Animate_PenEnd()
	g_ChouajiangState = 2
	if g_nlevel < 1 or g_nlevel > 3 then
		return
	end
	
	local rewardlist = nil
	local kajiType = KaJi:LuaFnGetKaJiType(83)
	if kajiType == 1 then
		rewardlist = g_rewardlist_Kaji
	else
		rewardlist = g_rewardlist
	end
	if Player:GetData("IsOriginalJD") == 1 then
		rewardlist = g_rewardlist_Kaji
	end
	if g_nIndex < 1 or g_nIndex > table.getn(rewardlist[g_nlevel]) then
		return
	end
	local nShowItemId = rewardlist[g_nlevel][g_nIndex].id
	local nItemNum = rewardlist[g_nlevel][g_nIndex].num	
	local nBind = rewardlist[g_nlevel][g_nIndex].nBind
	local nIsLimit = rewardlist[g_nlevel][g_nIndex].isLimit
	local nBroad = rewardlist[g_nlevel][g_nIndex].nbroad
	local nBonus = g_nBonusID
	local nBonusNum = g_nBonusNum

	XiGuaJie_Activity_OnceReturn_Item2_Frame:Show()
	
	XiGuaJie_Activity_OnceReturn_TitlePic:Show()
	XiGuaJie_Activity_OnceReturn_Pic:Show()
	XiGuaJie_Activity_OnceReturn_Pic:SetProperty("Image", XiGuaJie_Activity_BGImage[g_nlevel])
	--必得奖励	
	local msg = ScriptGlobal_Format("#{XGJHD_220427_70}", nBonusNum, DataPool:Lua_GetItemNameByIndex(g_nBonusID))
	PushDebugMessage(msg)
	
	if nBind == 1 then
		local theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
		XiGuaJie_Activity_OnceReturn_Item2:SetActionItem(theAction:GetID())
		XiGuaJie_Activity_OnceReturn_Item2_Text:SetText("#L"..theAction:GetName())
		local msg = ScriptGlobal_Format("#{XGJHD_220427_65}", nItemNum, theAction:GetName())
		PushDebugMessage(msg)
	else
		local theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
		XiGuaJie_Activity_OnceReturn_Item2:SetActionItem(theAction:GetID())
		XiGuaJie_Activity_OnceReturn_Item2_Text:SetText("#L"..theAction:GetName())
		local msg = ScriptGlobal_Format("#{XGJHD_220427_65}", nItemNum, theAction:GetName())
		PushDebugMessage(msg)		
	end

	if nIsLimit == 1 then
		XiGuaJie_Activity_OnceReturn_Item2_BuyLimit:Show()
	else
		XiGuaJie_Activity_OnceReturn_Item2_BuyLimit:Hide()
	end
	
	if nBroad == 1 then
		XiGuaJie_Activity_OnceReturn_Item2_Animate:Play(true)
	else
		XiGuaJie_Activity_OnceReturn_Item2_Animate:Play(false)
	end

end


function XiGuaJie_Activity_OnceReturn_Close()
	XiGuaJie_Activity_OnceReturn_Frame:Hide()
	XiGuaJie_Activity_Reward1_Item:Show()
	XiGuaJie_Activity_Reward2_Item:Show()
	XiGuaJie_Activity_Reward3_Item:Show()
	XiGuaJie_Activity_Frame_XiGuaNum:Show()
	g_ChouajiangState = 0

end

--=========================================================
--替换界面
--=========================================================
function XiGuaJie_Activity_Update_Client4()
	XiGuaJie_Activity_Reward1_Item:Hide()
	XiGuaJie_Activity_Reward2_Item:Hide()
	XiGuaJie_Activity_Reward3_Item:Hide()
	XiGuaJie_Activity_Frame_XiGuaNum:Hide()
	
	XiGuaJie_Activity_Change_Frame:Show()
	
	XiGuaJie_Activity_Change_TitlePic:Hide()
	XiGuaJie_Activity_Change_Lace:Hide()
	XiGuaJie_Activity_Change_Pic:Hide()
	XiGuaJie_Activity_Change_Lace2:Hide()
	XiGuaJie_Activity_Change_Yes_Btn:Hide()
	XiGuaJie_Activity_Change_NO_Btn:Hide()
	
	for i = 1, 3 do
		XiGuaJie_Activity_Change_Animate[i]:Hide()
	end
	XiGuaJie_Activity_Change_Animate_Pen:Play(false)
	
	if g_nlevel >= 1 and g_nlevel <= 3 then
		XiGuaJie_Activity_Change_Animate[g_nlevel]:Show()
		XiGuaJie_Activity_Change_PlayAnimate()
		XiGuaJie_Activity_Change_Animate_Pen:Play(true)
	end
end

function XiGuaJie_Activity_Change_Update()
	g_rewardSelect = 0
	if g_nlevel >= 1 and g_nlevel <= 3 then
		for i = 1, 3 do
			if g_nlevel == i then
				XiGuaJie_Activity_Change_level[i]:Show()
			else
				XiGuaJie_Activity_Change_level[i]:Hide()
			end
		end
	else
		return
	end
	
	XiGuaJie_Activity_Change_TitlePic:Show()
	XiGuaJie_Activity_Change_Pic:Show()
	XiGuaJie_Activity_Change_Pic:SetProperty("Image", XiGuaJie_Activity_BGImage[g_nlevel])
	
	local rewardlist = {}
	
	local kajiType = KaJi:LuaFnGetKaJiType(83)
	if kajiType == 1 then
		rewardlist = g_rewardlist_Kaji[g_nlevel]
	else
		rewardlist = g_rewardlist[g_nlevel]
	end
	if Player:GetData("IsOriginalJD") == 1 then
		rewardlist = g_rewardlist_Kaji[g_nlevel]
	end				
	for i = 1, g_max_reward[g_nlevel] do
		if g_nlevel >= 1 and g_nlevel <= 2 then
			XiGuaJie_Activity_Change_Limit[g_nlevel][i]:Hide()
		end
		local ItemIndex = g_currewardlist[i]
		if ItemIndex ~= nil and ItemIndex > 0 then
			local nShowItemId = rewardlist[ItemIndex].id
			local nItemNum = rewardlist[ItemIndex].num
			local nBind = rewardlist[ItemIndex].nBind
			local IsLimit = rewardlist[ItemIndex].isLimit
			local theAction = nil
			if nBind == 1 then
				theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
			else
				theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
			end
			if theAction ~= nil then
				XiGuaJie_Activity_Change_ActionButton[g_nlevel][i]:SetActionItem(theAction:GetID())
			end
			if g_nlevel >= 1 and g_nlevel <= 2 then
				if IsLimit == 1 then
					XiGuaJie_Activity_Change_Limit[g_nlevel][i]:Show()
				else
					XiGuaJie_Activity_Change_Limit[g_nlevel][i]:Hide()
				end
			end
		end
		XiGuaJie_Activity_Change_Mask[g_nlevel][i]:Hide()
	end
	
	if g_nBonusID > 0 and g_nBonusNum > 0 then
		local msg = ScriptGlobal_Format("#{XGJHD_220427_70}", g_nBonusNum, DataPool:Lua_GetItemNameByIndex(g_nBonusID))
		PushDebugMessage(msg)		
	end
	
	if g_nIndex > 0 then
		local nShowItemId = rewardlist[g_nIndex].id
		local nItemNum = rewardlist[g_nIndex].num
		local nBind = rewardlist[g_nIndex].nBind
		local IsLimit = rewardlist[g_nIndex].isLimit
		local nBroad = rewardlist[g_nIndex].nbroad
		local theAction = nil
		if nBind == 1 then
			theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
		else
			theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
		end
		if theAction ~= nil then
			XiGuaJie_Activity_Change_New_Icon:SetActionItem(theAction:GetID())
		end	
		--限量
		if IsLimit == 1 then
			XiGuaJie_Activity_Change_New_Icon_BuyLimit:Show()
		else
			XiGuaJie_Activity_Change_New_Icon_BuyLimit:Hide()
		end
		
		if nBroad == 1 then
			XiGuaJie_Activity_Change_New_Icon_Animate:Play(true)
		else
			XiGuaJie_Activity_Change_New_Icon_Animate:Play(false)
		end
		XiGuaJie_Activity_Change_New_Icon_Text:SetText("#L"..theAction:GetName())
		local msg = ScriptGlobal_Format("#{XGJHD_220427_65}", nItemNum, theAction:GetName())
		PushDebugMessage(msg)
	end
	XiGuaJie_Activity_XiGuaNum:SetText(ScriptGlobal_Format( "#{XGJHD_220427_07}",g_curDaibiCount))
end	

function XiGuaJie_Activity_Change_Animate_PenEnd()
	XiGuaJie_Activity_Change_Lace:Show()
	XiGuaJie_Activity_Change_Lace2:Show()
	XiGuaJie_Activity_Change_Pic:Show()
	XiGuaJie_Activity_Change_Yes_Btn:Show()
	XiGuaJie_Activity_Change_NO_Btn:Show()

	XiGuaJie_Activity_Change_Update()
	g_ChouajiangState = 4
end

--渐变动画
function XiGuaJie_Activity_Change_PlayAnimate()
	if g_nlevel >= 1 and g_nlevel <= 3 then
		g_AnimateTick = 0
		XiGuaJie_Activity_Change_Animate[g_nlevel]:SetProperty("Alpha",0)
		KillTimer("XiGuaJie_Activity_Change_AnimateTimer()")
	
		SetTimer("XiGuaJie_Activity","XiGuaJie_Activity_Change_AnimateTimer()", 280)--计时器
	end
end

function XiGuaJie_Activity_Change_AnimateTimer()
	if g_nlevel >= 1 and g_nlevel <= 3 then
		g_AnimateTick = g_AnimateTick+1
		if g_AnimateTick >= 10 then
			g_AnimateTick = 0
			XiGuaJie_Activity_Change_Animate[g_nlevel]:SetProperty("Alpha",1)
			KillTimer("XiGuaJie_Activity_Change_AnimateTimer()")
		else
			XiGuaJie_Activity_Change_Animate[g_nlevel]:SetProperty("Alpha",g_AnimateTick*0.1)
		end
	end
end

function XiGuaJie_Activity_Change_Select(nIndex)
	if g_nlevel >= 1 and g_nlevel <= 3 then
		for i = 1, g_max_reward[g_nlevel] do
			if nIndex == i then
				XiGuaJie_Activity_Change_Mask[g_nlevel][i]:Show()
				g_rewardSelect = i
			else
				XiGuaJie_Activity_Change_Mask[g_nlevel][i]:Hide()
			end
		end
	end
end

function XiGuaJie_Activity_Change_Confirm()
	if g_nlevel >= 1 and g_nlevel <= 3 then
		if g_rewardSelect > 0 and g_rewardSelect <= g_max_reward[g_nlevel] then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "ChangeReward" )
				Set_XSCRIPT_ScriptID( 998017 )
    			Set_XSCRIPT_Parameter(0,g_rewardSelect)
				Set_XSCRIPT_Parameter(1,0)
    			Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		else
			PushDebugMessage("#{XGJHD_220427_19}")
		end
	end

end	

function XiGuaJie_Activity_Change_Cancel()

	if g_nlevel >= 1 and g_nlevel <= 3 then
		local rewardlist = {}
		local kajiType = KaJi:LuaFnGetKaJiType(83)
		if kajiType == 1 then
			rewardlist = g_rewardlist_Kaji[g_nlevel]
		else
			rewardlist = g_rewardlist[g_nlevel]
		end
		if Player:GetData("IsOriginalJD") == 1 then
			rewardlist = g_rewardlist_Kaji[g_nlevel]
		end
		if g_nIndex > 0 then
			local nItemId = rewardlist[g_nIndex].id
			local nItemNum = rewardlist[g_nIndex].num
			local msg = ScriptGlobal_Format( "#{XGJHD_220427_23}", nItemNum, DataPool:Lua_GetItemNameByIndex(nItemId))
			PushEvent("UI_COMMAND", 99801708, msg)
		end
	end

end	

function XiGuaJie_Activity_Change_Close()
	XiGuaJie_Activity_Change_Frame:Hide()
	XiGuaJie_Activity_Reward1_Item:Show()
	XiGuaJie_Activity_Reward2_Item:Show()
	XiGuaJie_Activity_Reward3_Item:Show()
	XiGuaJie_Activity_Frame_XiGuaNum:Show()
	g_ChouajiangState = 0
end

--=========================================================
--关闭
--=========================================================
function XiGuaJie_Activity_Close()
	--替换界面关闭
	if g_ChouajiangState >= 3 then
		XiGuaJie_Activity_Change_Cancel()
		return
	end
		
	this:Hide()
end

function XiGuaJie_Activity_OnHiden()
	XiGuaJie_Activity_Close()
	g_ChouajiangState = 0
end
--=========================================================
--刷新位置
--=========================================================
function XiGuaJie_Activity_On_ResetPos()
	XiGuaJie_Activity_MainFrame:SetProperty("UnifiedPosition", g_XiGuaJie_Activity_UnifiedPosition);
end


function XiGuaJie_Activity_Client1_InfoHelp_Click()
	PushEvent("CCSHOP_HELP", 162)
end

function XiGuaJie_Activity_Client2_InfoHelp_Click()
	PushEvent("CCSHOP_HELP", 163)
end

--抽奖
function XiGuaJie_Activity_Start_Clicked()
	
	if g_ChouajiangState > 0 then
		PushDebugMessage("请关闭界面后重新开启")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoChouJiang" )
		Set_XSCRIPT_ScriptID( 998017 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function XiGuaJie_Activity_Start_Tick()
	KillTimer("XiGuaJie_Activity_Start_Tick()")
end
--领奖
function XiGuaJie_Activity_GetReward_Clicked(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetReward" )
		Set_XSCRIPT_ScriptID( 998017 )
    	Set_XSCRIPT_Parameter(0,nIndex)
    	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


--累计领奖
function XiGuaJie_Activity_GetLichengReward_Clicked(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetLichengReward" )
		Set_XSCRIPT_ScriptID( 998017 )
    	Set_XSCRIPT_Parameter(0,nIndex)
    	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--奖励预览
function XiGuaJie_Activity_Client1_ViewReward_Click()
	PushEvent("UI_COMMAND", 99801704)
end

