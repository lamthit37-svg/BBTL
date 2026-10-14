--XiGuaJie_Activity_Reward
local g_XiGuaJie_Activity_Reward_UnifiedPosition;

local XiGuaJie_Activity_Reward_ActionButton = {
	[1] = {},
	[2] = {},
	[3] = {},
}
local XiGuaJie_Activity_Reward_Limit = {
	[1] = {},
	[2] = {},
	[3] = {},
}
local XiGuaJie_Activity_Reward_Num = {}
local XiGuaJie_Activity_Reward_Cost = {}
local XiGuaJie_Activity_Reward_Mark = {}
local XiGuaJie_Activity_Reward_Mark2 = {}

local g_curTBIndex = 0
local g_CurItemIndex = 0
local g_RewardItem_MD_List = {}

local g_rewardlist = {}
g_rewardlist[1] = {
  [1] ={id=38006065,num =1,nBind = 0,isLimit=1},
  [2] ={id=38006410,num =1,nBind = 0,isLimit=1},
  [3] ={id=10141452,num =1,nBind = 0,isLimit=0},
  [4] ={id=38004734,num =10,nBind = 0,isLimit=0},
  [5] ={id=38004805,num =10,nBind = 0,isLimit=0},
  [6] ={id=38004358,num =2,nBind = 1,isLimit=0},
  [7] ={id=38004359,num =1,nBind = 1,isLimit=0},
  [8] ={id=38005317,num =1,nBind = 1,isLimit=0},
 
}
 g_rewardlist[2] = {
   	[1] ={id=20502003,num =1,nBind = 1,isLimit=0}, 
    [2] ={id=20501003,num =1,nBind = 1,isLimit=0},
    [3] ={id=20502004,num =1,nBind = 1,isLimit=0},
    [4] ={id=20501004,num =1,nBind = 1,isLimit=0},
    [5] ={id=20502015,num =1,nBind = 1,isLimit=0},
    [6] ={id=20501009,num =1,nBind = 1,isLimit=0},
   	[7] ={id=38000992,num =1,nBind = 0,isLimit=0}, 
    [8] ={id=38001595,num =1,nBind = 1,isLimit=0},
    [9] ={id=38000443,num =1,nBind = 0,isLimit=0},
    [10] ={id=38005288,num =2,nBind = 0,isLimit=0 },
    [11] ={id=38005898,num =1,nBind = 0,isLimit=0},
    [12] ={id=38006510,num =1,nBind = 0,isLimit=1},

}
g_rewardlist[3] = {
 [1] ={id=38000807,num =1,nBind = 0,isLimit=0},
 [2] ={id=38000807,num =2,nBind = 1,isLimit=0},
 [3] ={id=30503188,num =2,nBind = 0,isLimit=0},
 [4] ={id=30503188,num =4,nBind = 1,isLimit=0},
 [5] ={id=38000378,num =1,nBind = 0,isLimit=0},
 [6] ={id=38000378,num =2,nBind = 0,isLimit=0},
 [7] ={id=38000571,num =1,nBind = 0,isLimit=0},
 [8] ={id=38000571,num =2,nBind = 0,isLimit=0},
 [9] ={id=20310168,num =2,nBind = 0,isLimit=0},
 [10] ={id=20310168,num =4,nBind = 0,isLimit=0},
 [11] ={id=30008034,num =1,nBind = 1,isLimit=0},
 [12] ={id=30008034,num =2,nBind = 1,isLimit=0},
 [13] ={id=38000656,num =1,nBind = 0,isLimit=0},
 [14] ={id=38000656,num =2,nBind = 0,isLimit=0},
}
local g_rewardlist_Kaji = {}
g_rewardlist_Kaji[1] = {
 [1] ={id=38006065,num =1,nBind = 0,isLimit=1},
 [2] ={id=38006410,num =1,nBind = 0,isLimit=1},
 [3] ={id=10141452,num =1,nBind = 0,isLimit=0},
 [4] ={id=38000658,num =4,nBind = 0,isLimit=0},
 [5] ={id=38000658,num =2,nBind = 0,isLimit=0},
 [6] ={id=30700241,num =20,nBind = 1,isLimit=0},
 [7] ={id=30700241,num =10,nBind = 1,isLimit=0},
 [8] ={id=30008048,num =2,nBind = 0,isLimit=0},
 
}
 g_rewardlist_Kaji[2] = {
 [1] ={id=20502003,num =1,nBind = 1,isLimit=0}, 
 [2] ={id=20501003,num =1,nBind = 1,isLimit=0},
 [3] ={id=20502004,num =1,nBind = 1,isLimit=0},
 [4] ={id=20501004,num =1,nBind = 1,isLimit=0},
 [5] ={id=20502015,num =1,nBind = 1,isLimit=0},
 [6] ={id=20501009,num =1,nBind = 1,isLimit=0},
 [7] ={id=38000992,num =1,nBind = 0,isLimit=0}, 
 [8] ={id=38001595,num =1,nBind = 1,isLimit=0},
 [9] ={id=38000443,num =1,nBind = 0,isLimit=0},
 [10] ={id=38005288,num =2,nBind = 0,isLimit=0},
 [11] ={id=38005898,num =1,nBind = 0,isLimit=0},
 [12] ={id=38006510,num =1,nBind = 0,isLimit=1},

}

g_rewardlist_Kaji[3] = {
  [1] ={id=38000807,num =1,nBind = 0,isLimit=0},
  [2] ={id=38000807,num =2,nBind = 1,isLimit=0},
  [3] ={id=30503188,num =2,nBind = 0,isLimit=0},
  [4] ={id=30503188,num =4,nBind = 1,isLimit=0},
  [5] ={id=30700249,num =2,nBind = 0,isLimit=0},
  [6] ={id=30700249,num =4,nBind = 0,isLimit=0},
  [7] ={id=38000571,num =1,nBind = 0,isLimit=0},
  [8] ={id=38000571,num =2,nBind = 0,isLimit=0},
  [9] ={id=20310168,num =2,nBind = 0,isLimit=0},
  [10] ={id=20310168,num =4,nBind = 0,isLimit=0},
  [11] ={id=30008034,num =1,nBind = 1,isLimit=0},
  [12] ={id=30008034,num =2,nBind = 1,isLimit=0},
  [13] ={id=38000656,num =1,nBind = 0,isLimit=0},
  [14] ={id=38000656,num =2,nBind = 0,isLimit=0},
}
function XiGuaJie_Activity_Reward_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function XiGuaJie_Activity_Reward_OnLoad()	

	XiGuaJie_Activity_Reward_ActionButton[1][1] = XiGuaJie_Activity_Reward_List1_RewardItem1
	XiGuaJie_Activity_Reward_ActionButton[1][2] = XiGuaJie_Activity_Reward_List1_RewardItem2
	XiGuaJie_Activity_Reward_ActionButton[1][3] = XiGuaJie_Activity_Reward_List1_RewardItem3
	XiGuaJie_Activity_Reward_ActionButton[1][4] = XiGuaJie_Activity_Reward_List1_RewardItem4
	XiGuaJie_Activity_Reward_ActionButton[1][5] = XiGuaJie_Activity_Reward_List1_RewardItem5
	XiGuaJie_Activity_Reward_ActionButton[1][6] = XiGuaJie_Activity_Reward_List1_RewardItem6
	XiGuaJie_Activity_Reward_ActionButton[1][7] = XiGuaJie_Activity_Reward_List1_RewardItem7
	XiGuaJie_Activity_Reward_ActionButton[1][8] = XiGuaJie_Activity_Reward_List1_RewardItem8
		
	XiGuaJie_Activity_Reward_ActionButton[2][1] = XiGuaJie_Activity_Reward_List2_RewardItem1
	XiGuaJie_Activity_Reward_ActionButton[2][2] = XiGuaJie_Activity_Reward_List2_RewardItem2
	XiGuaJie_Activity_Reward_ActionButton[2][3] = XiGuaJie_Activity_Reward_List2_RewardItem3
	XiGuaJie_Activity_Reward_ActionButton[2][4] = XiGuaJie_Activity_Reward_List2_RewardItem4
	XiGuaJie_Activity_Reward_ActionButton[2][5] = XiGuaJie_Activity_Reward_List2_RewardItem5
	XiGuaJie_Activity_Reward_ActionButton[2][6] = XiGuaJie_Activity_Reward_List2_RewardItem6
	XiGuaJie_Activity_Reward_ActionButton[2][7] = XiGuaJie_Activity_Reward_List2_RewardItem7
	XiGuaJie_Activity_Reward_ActionButton[2][8] = XiGuaJie_Activity_Reward_List2_RewardItem8
	XiGuaJie_Activity_Reward_ActionButton[2][9] = XiGuaJie_Activity_Reward_List2_RewardItem9
	XiGuaJie_Activity_Reward_ActionButton[2][10] = XiGuaJie_Activity_Reward_List2_RewardItem10
	XiGuaJie_Activity_Reward_ActionButton[2][11] = XiGuaJie_Activity_Reward_List2_RewardItem11
	XiGuaJie_Activity_Reward_ActionButton[2][12] = XiGuaJie_Activity_Reward_List2_RewardItem12
		
	XiGuaJie_Activity_Reward_ActionButton[3][1] = XiGuaJie_Activity_Reward_List3_RewardItem1
	XiGuaJie_Activity_Reward_ActionButton[3][2] = XiGuaJie_Activity_Reward_List3_RewardItem2
	XiGuaJie_Activity_Reward_ActionButton[3][3] = XiGuaJie_Activity_Reward_List3_RewardItem3
	XiGuaJie_Activity_Reward_ActionButton[3][4] = XiGuaJie_Activity_Reward_List3_RewardItem4
	XiGuaJie_Activity_Reward_ActionButton[3][5] = XiGuaJie_Activity_Reward_List3_RewardItem5
	XiGuaJie_Activity_Reward_ActionButton[3][6] = XiGuaJie_Activity_Reward_List3_RewardItem6
	XiGuaJie_Activity_Reward_ActionButton[3][7] = XiGuaJie_Activity_Reward_List3_RewardItem7
	XiGuaJie_Activity_Reward_ActionButton[3][8] = XiGuaJie_Activity_Reward_List3_RewardItem8
	XiGuaJie_Activity_Reward_ActionButton[3][9] = XiGuaJie_Activity_Reward_List3_RewardItem9
	XiGuaJie_Activity_Reward_ActionButton[3][10] = XiGuaJie_Activity_Reward_List3_RewardItem10
	XiGuaJie_Activity_Reward_ActionButton[3][11] = XiGuaJie_Activity_Reward_List3_RewardItem11
	XiGuaJie_Activity_Reward_ActionButton[3][12] = XiGuaJie_Activity_Reward_List3_RewardItem12
	XiGuaJie_Activity_Reward_ActionButton[3][13] = XiGuaJie_Activity_Reward_List3_RewardItem13
	XiGuaJie_Activity_Reward_ActionButton[3][14] = XiGuaJie_Activity_Reward_List3_RewardItem14
		
	XiGuaJie_Activity_Reward_Limit[1][1] = XiGuaJie_Activity_Reward_List1_RewardItem1_BuyLimit
	XiGuaJie_Activity_Reward_Limit[1][2] = XiGuaJie_Activity_Reward_List1_RewardItem2_BuyLimit
	XiGuaJie_Activity_Reward_Limit[1][3] = XiGuaJie_Activity_Reward_List1_RewardItem3_BuyLimit
	XiGuaJie_Activity_Reward_Limit[1][4] = XiGuaJie_Activity_Reward_List1_RewardItem4_BuyLimit
	XiGuaJie_Activity_Reward_Limit[1][5] = XiGuaJie_Activity_Reward_List1_RewardItem5_BuyLimit
	XiGuaJie_Activity_Reward_Limit[1][6] = XiGuaJie_Activity_Reward_List1_RewardItem6_BuyLimit
	XiGuaJie_Activity_Reward_Limit[1][7] = XiGuaJie_Activity_Reward_List1_RewardItem7_BuyLimit
	XiGuaJie_Activity_Reward_Limit[1][8] = XiGuaJie_Activity_Reward_List1_RewardItem8_BuyLimit
		
	XiGuaJie_Activity_Reward_Limit[2][1] = XiGuaJie_Activity_Reward_List2_RewardItem1_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][2] = XiGuaJie_Activity_Reward_List2_RewardItem2_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][3] = XiGuaJie_Activity_Reward_List2_RewardItem3_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][4] = XiGuaJie_Activity_Reward_List2_RewardItem4_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][5] = XiGuaJie_Activity_Reward_List2_RewardItem5_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][6] = XiGuaJie_Activity_Reward_List2_RewardItem6_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][7] = XiGuaJie_Activity_Reward_List2_RewardItem7_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][8] = XiGuaJie_Activity_Reward_List2_RewardItem8_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][9] = XiGuaJie_Activity_Reward_List2_RewardItem9_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][10] = XiGuaJie_Activity_Reward_List2_RewardItem10_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][11] = XiGuaJie_Activity_Reward_List2_RewardItem11_BuyLimit
	XiGuaJie_Activity_Reward_Limit[2][12] = XiGuaJie_Activity_Reward_List2_RewardItem12_BuyLimit		
		
		
	g_XiGuaJie_Activity_Reward_UnifiedPosition = XiGuaJie_Activity_Reward_Frame:GetProperty("UnifiedPosition")
	
end

function XiGuaJie_Activity_Reward_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99801704 ) then
		XiGuaJie_Activity_Reward_Update()

	elseif (event == "ADJEST_UI_POS" ) then
		XiGuaJie_Activity_Reward_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiGuaJie_Activity_Reward_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--=========================================================
--更新界面
--=========================================================
function XiGuaJie_Activity_Reward_Update()
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
	for i = 1, 3 do
		for j = 1, table.getn(rewardlist[i]) do
			local nShowItemId = rewardlist[i][j].id
			local nItemNum = rewardlist[i][j].num
			local nBind = rewardlist[i][j].nBind
			local IsLimit = rewardlist[i][j].isLimit
			local theAction = nil
			if nBind == 1 then
				theAction = DataPool:CreateBindActionItemForShow( nShowItemId, nItemNum )
			else
				theAction = DataPool:CreateActionItemForShow( nShowItemId, nItemNum )
			end
			if theAction ~= nil then
				XiGuaJie_Activity_Reward_ActionButton[i][j]:SetActionItem(theAction:GetID())
			end
			if i >= 1 and i <= 2 then
				if IsLimit == 1 then
					XiGuaJie_Activity_Reward_Limit[i][j]:Show()
				else
					XiGuaJie_Activity_Reward_Limit[i][j]:Hide()
				end
			end
		end
	end
	this:Show()
end	


--=========================================================
--关闭
--=========================================================
function XiGuaJie_Activity_Reward_Close()
	this:Hide()
end

function XiGuaJie_Activity_Reward_OnHiden()
	XiGuaJie_Activity_Reward_Close()
end

--=========================================================
--刷新位置
--=========================================================
function XiGuaJie_Activity_Reward_On_ResetPos()
	XiGuaJie_Activity_Reward_Frame:SetProperty("UnifiedPosition", g_XiGuaJie_Activity_Reward_UnifiedPosition);
end
