-- 快捷功能入口 乾坤袋
-- PushDebugMessage
-- this:Show();
-- this:Hide();

local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},
											[6] = {x =0, y = 0, tipx =0, tipy =0},
											[7] = {x =0, y = 0, tipx =0, tipy =0},
										}
										
local Fuli_QiankunBagButton = {}
local Fuli_QiankunBagIcon = {}	-- 乾坤袋icon
local Fuli_QiankunBag_FrameInfo = {}	-- 乾坤袋Frame
local Fuli_QiankunBag_Info = {}	-- 乾坤袋Info
local Fuli_QiankunBagLevel = {	-- 领奖等级限制
	[1] = 10,
	[2] = 20,
	[3] = 30,
	[4] = 35,
	[5] = 40,
	[6] = 45,
	[7] = 50,
	[8] = 55,
}
local Fuli_QiankunBagBtnState = {		-- 乾坤袋按钮状态
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}

local Fuli_QiankunBagText1Info = {		-- TextInfo
	[1] = "#{SJJLYH_160315_01}",	-- #cfff263 10级奖励
	[2] = "#{SJJLYH_160315_02}",	-- #cfff263 20级奖励
	[3] = "#{SJJLYH_160315_03}",	-- #cfff263 30级奖励
	[4] = "#{SJJLYH_160315_04}",	-- #cfff263 35级奖励
	[5] = "#{SJJLYH_160315_05}",	-- #cfff263 40级奖励
	[6] = "#{SJJLYH_160315_06}",	-- #cfff263 45级奖励
	[7] = "#{SJJLYH_160315_07}",	-- #cfff263 50级奖励
	[8] = "#{SJJLYH_160315_08}",	-- #cfff263 55级奖励
}

local Fuli_QiankunBagText2Info = {		-- TextInfo
	[1] = "#{SJJLYH_160315_09}",	-- #cfff263 10级奖励
	[2] = "#{SJJLYH_160315_10}",	-- #cfff263 20级奖励
	[3] = "#{SJJLYH_160315_11}",	-- #cfff263 30级奖励
	[4] = "#{SJJLYH_160315_12}",	-- #cfff263 35级奖励
	[5] = "#{SJJLYH_160315_13}",	-- #cfff263 40级奖励
	[6] = "#{SJJLYH_160315_14}",	-- #cfff263 45级奖励
	[7] = "#{SJJLYH_160315_15}",	-- #cfff263 50级奖励
	[8] = "#{SJJLYH_160315_16}",	-- #cfff263 55级奖励
}

--2023新【新服欢乐月·升级送好礼】Begin
local g_Fuli_QiankunBag_Frame2023_TotalEnum = 13   --总行数

local g_Fuli_QiankunBag_Frame2023_LoadFirstTime = 1

local g_Fuli_QiankunBag_Frame2023_GetGiftLevel = {		-- 领奖等级限制/消费限制
	[1] = { level = 10, consume1 = 40000, consume2 = 250000},
	[2] = { level = 20, consume1 = 40000, consume2 = 250000},
	[3] = { level = 30, consume1 = 40000, consume2 = 250000},
	[4] = { level = 35, consume1 = 40000, consume2 = 250000},
	[5] = { level = 40, consume1 = 40000, consume2 = 250000},
	[6] = { level = 45, consume1 = 40000, consume2 = 250000},
	[7] = { level = 50, consume1 = 40000, consume2 = 250000},
	[8] = { level = 55, consume1 = 40000, consume2 = 250000},
	[9] = { level = 60, consume1 = 40000, consume2 = 250000},
	[10] = { level = 70, consume1 = 40000, consume2 = 250000},
	[11] = { level = 80, consume1 = 40000, consume2 = 250000},
	[12] = { level = 90, consume1 = 40000, consume2 = 250000},
	[13] = { level = 100, consume1 = 40000, consume2 = 250000},
	[14] = { level = 999, consume1 = 999999, consume2 = 999999},
}

local g_Fuli_QiankunBag_Frame2023_BtnState = {			-- 领取按钮的状态
	[1] = { level = 1, consume1 = 1, consume2 = 1},
	[2] = { level = 1, consume1 = 1, consume2 = 1},
	[3] = { level = 1, consume1 = 1, consume2 = 1},
	[4] = { level = 1, consume1 = 1, consume2 = 1},
	[5] = { level = 1, consume1 = 1, consume2 = 1},
	[6] = { level = 1, consume1 = 1, consume2 = 1},
	[7] = { level = 1, consume1 = 1, consume2 = 1},
	[8] = { level = 1, consume1 = 1, consume2 = 1},
	[9] = { level = 1, consume1 = 1, consume2 = 1},
	[10] = { level = 1, consume1 = 1, consume2 = 1},
	[11] = { level = 1, consume1 = 1, consume2 = 1},
	[12] = { level = 1, consume1 = 1, consume2 = 1},
	[13] = { level = 1, consume1 = 1, consume2 = 1},
}

local g_Fuli_QiankunBag_Frame2023_List = ""   --superlist name

local g_Fuli_QiankunBag_Frame2023_List_Item = { }

local g_Fuli_QiankunBag_Frame2023_ListItemText = 
{
	[1] = "#{XSJNH_180111_96}",
	[2] = "#{XSJNH_180111_97}",
	[3] = "#{XSJNH_180111_98}",
	[4] = "#{XSJNH_180111_99}",
	[5] = "#{XSJNH_180111_100}",
	[6] = "#{XSJNH_180111_101}",
	[7] = "#{XSJNH_180111_102}",
	[8] = "#{XSJNH_180111_103}",
	[9] = "#{XSJNH_180111_104}",
	[10] = "#{XSJNH_180111_105}",
	[11] = "#{XSJNH_180111_106}",
	[12] = "#{XSJNH_180111_107}",
	[13] = "#{XSJNH_180111_108}",
}

--界面上显示奖励物品的ICON表
local g_Fuli_QiankunBag_Frame2023_GiftsIcons = 
{
	Normal  = { [1] = "Fuli_QiankunBag_Frame10_Bk1_Icon1", [2] = "Fuli_QiankunBag_Frame10_Bk1_Icon2", [3] = "Fuli_QiankunBag_Frame10_Bk1_Icon3" },
	Consume1 = { [1] = "Fuli_QiankunBag_Frame10_Bk2_Icon1" , [2] = "Fuli_QiankunBag_Frame10_Bk2_Icon2"},
	Consume2 = { [1] = "Fuli_QiankunBag_Frame10_Bk3_Icon1" , [2] = "Fuli_QiankunBag_Frame10_Bk3_Icon2"},
}
--界面上显示奖励物品的ICON右上角的小图标
local g_Fuli_QiankunBag_Frame2023_GiftsIconsImages = 
{
	Normal  = { [1] = "Fuli_QiankunBag_Frame10_Bk1_Icon1_Xin" , [2] = "Fuli_QiankunBag_Frame10_Bk1_Icon2_Xin", [3] = "Fuli_QiankunBag_Frame10_Bk1_Icon3_Xin"},
	Consume1 = { [1] = "Fuli_QiankunBag_Frame10_Bk2_Icon1_Xin" , [2] = "Fuli_QiankunBag_Frame10_Bk2_Icon2_Xin" }, 
	Consume2 = { [1] = "Fuli_QiankunBag_Frame10_Icon1_Xin" , [2] = "Fuli_QiankunBag_Frame10_Bk3_Icon2_Xin" },
}

--界面【领取奖励】按钮表 g_Fuli_QiankunBag_Frame2023_GetGiftLevel

--奖励物品配表
local g_Fuli_QiankunBag_Frame2023_Gifts = {
	[1] ={
			Normal = {
				{GiftItemID = 30008080, num = 1},{GiftItemID = 10124418, num = 1},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			},
		},
	[2] ={ 
			Normal = {
				{GiftItemID = 31000006, num = 1},{GiftItemID = 30607003, num = 1},
			}, 
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[3] ={
			Normal = {
				{GiftItemID = 30008027, num = 1},{GiftItemID = 31000007, num = 1},{GiftItemID = 30505216, num = 1}
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[4] ={ 
			Normal = {
				{GiftItemID = 30008027, num = 1},{GiftItemID = 31000006, num = 1},{GiftItemID = 30503132, num = 2}
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[5] ={ 
			Normal = {
				{GiftItemID = 30008027, num = 2},{GiftItemID = 30309985, num = 1},{GiftItemID = 31000007, num = 1}
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[6] ={ 
			Normal = {
				{GiftItemID = 30008027, num = 1},{GiftItemID = 30900124, num = 1},{GiftItemID = 38001553, num = 2}
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 4},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 4},
			}
		},
	[7] ={ 
			Normal = {
				{GiftItemID = 30008027, num = 2},{GiftItemID = 20310168, num = 5},{GiftItemID = 20310021, num = 10},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 6},{GiftItemID = 38001553, num = 5},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 6},{GiftItemID = 38001554, num = 1},
			}
		},
	[8] ={ 
			Normal = {
				{GiftItemID = 30008027 ,num = 2},{GiftItemID = 30700241, num = 1},{GiftItemID = 38000833, num = 3},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 6},{GiftItemID = 38006284, num = 1},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 6},{GiftItemID = 38006285, num = 1},
			}
		},	
	[9] ={  
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 20310158, num = 2},{GiftItemID = 30700249, num = 5},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 8},{GiftItemID = 30700241, num = 3},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 8},{GiftItemID = 20310131, num = 10},
			}
		},
	[10] ={ 	
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 38000831, num = 2},{GiftItemID = 30008027, num = 2},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 8},{GiftItemID = 20502003, num = 1},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 8},{GiftItemID = 20502003, num = 3},
			}
		},
	[11] ={ 
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 38000989, num = 3},{GiftItemID = 38000930, num = 50},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 10},{GiftItemID = 20501003, num = 1},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 10},{GiftItemID = 20501003, num = 3},
			}
		},
	[12] ={
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 30505805, num = 1},{GiftItemID = 30505817, num = 5},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 10},{GiftItemID = 30505805, num = 5},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 10},{GiftItemID = 30505817, num = 10},
			}
		},
	[13] ={ 
			Normal = {
				{GiftItemID = 30008130 ,num = 1},{GiftItemID = 30505806, num = 1},{GiftItemID = 30505908, num = 5},
			},
			Consume1 = {
				{GiftItemID = 30008080, num = 20},{GiftItemID = 30505908, num = 10},
			},
			Consume2 = {
				{GiftItemID = 20310168, num = 20},{GiftItemID = 30505706, num = 1},
			}
		},
}
--2023新【新服欢乐月·升级送好礼】End

local g_Fuli_QiankunBag_Frame_UnifiedPosition;

local g_Fuli_QiankunBag_FrameOld = ""
local g_Fuli_QiankunBag_Frame2023 = ""

local g_PlayerLevel = 0
local g_CurConsume = 0
local g_CurExch = 0

local g_XinShouNew_MD = 1533 			--新手嘉年华MD 结束时间 YYMMDDHHMM  --MD_XINSHOUCARN_DATE

local g_KajiTable_XSJNH = {
	--升级赠好礼 需要隐藏的奖励等级index段
	[4] = {
		[0] = {0,0},
		[1] = {10,13}
	},
}

--**********************************
-- PRELOAD
--**********************************
function Fuli_QiankunBag_PreLoad()

	this:RegisterEvent("OPEN_QIANKUNDAI");		-- 打开UI
	this:RegisterEvent("UNIT_LEVEL");			-- 升级
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	-- 离开场景
	this:RegisterEvent("UI_COMMAND")			-- 界面
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")


end


--**********************************
-- ONLOAD
--**********************************
function Fuli_QiankunBag_OnLoad()
	
	g_Fuli_QiankunBag_FrameOld = Fuli_QiankunBag_RightBK
	g_Fuli_QiankunBag_Frame2023 = Fuli_QiankunBag_RightBK2
	
	g_Fuli_QiankunBag_Frame2023_List = Fuli_QiankunBag_Frame10_List

	-- icon
	Fuli_QiankunBagIcon[1] = {Fuli_QiankunBag_Frame2_Icon1, Fuli_QiankunBag_Frame2_Icon2, Fuli_QiankunBag_Frame2_Icon3}
	Fuli_QiankunBagIcon[2] = {Fuli_QiankunBag_Frame3_Icon1, Fuli_QiankunBag_Frame3_Icon2, Fuli_QiankunBag_Frame3_Icon3}
	Fuli_QiankunBagIcon[3] = {Fuli_QiankunBag_Frame4_Icon1, Fuli_QiankunBag_Frame4_Icon2, Fuli_QiankunBag_Frame4_Icon3}
	Fuli_QiankunBagIcon[4] = {Fuli_QiankunBag_Frame5_Icon1, Fuli_QiankunBag_Frame5_Icon2, Fuli_QiankunBag_Frame5_Icon3}
	Fuli_QiankunBagIcon[5] = {Fuli_QiankunBag_Frame6_Icon1, Fuli_QiankunBag_Frame6_Icon2, Fuli_QiankunBag_Frame6_Icon3}
	Fuli_QiankunBagIcon[6] = {Fuli_QiankunBag_Frame7_Icon1, Fuli_QiankunBag_Frame7_Icon2, Fuli_QiankunBag_Frame7_Icon3}
	Fuli_QiankunBagIcon[7] = {Fuli_QiankunBag_Frame8_Icon1, Fuli_QiankunBag_Frame8_Icon2, Fuli_QiankunBag_Frame8_Icon3}
	Fuli_QiankunBagIcon[8] = {Fuli_QiankunBag_Frame9_Icon1, Fuli_QiankunBag_Frame9_Icon2, Fuli_QiankunBag_Frame9_Icon3}

	-- Frame
	Fuli_QiankunBag_FrameInfo[1] = Fuli_QiankunBag_Frame2_Info
	Fuli_QiankunBag_FrameInfo[2] = Fuli_QiankunBag_Frame3_Info
	Fuli_QiankunBag_FrameInfo[3] = Fuli_QiankunBag_Frame4_Info
	Fuli_QiankunBag_FrameInfo[4] = Fuli_QiankunBag_Frame5_Info
	Fuli_QiankunBag_FrameInfo[5] = Fuli_QiankunBag_Frame6_Info
	Fuli_QiankunBag_FrameInfo[6] = Fuli_QiankunBag_Frame7_Info
	Fuli_QiankunBag_FrameInfo[7] = Fuli_QiankunBag_Frame8_Info
	Fuli_QiankunBag_FrameInfo[8] = Fuli_QiankunBag_Frame9_Info


	-- Text
	Fuli_QiankunBag_Info[1] = Fuli_QiankunBag_Frame2_Info1
	Fuli_QiankunBag_Info[2] = Fuli_QiankunBag_Frame3_Info1
	Fuli_QiankunBag_Info[3] = Fuli_QiankunBag_Frame4_Info1
	Fuli_QiankunBag_Info[4] = Fuli_QiankunBag_Frame5_Info1
	Fuli_QiankunBag_Info[5] = Fuli_QiankunBag_Frame6_Info1
	Fuli_QiankunBag_Info[6] = Fuli_QiankunBag_Frame7_Info1
	Fuli_QiankunBag_Info[7] = Fuli_QiankunBag_Frame8_Info1
	Fuli_QiankunBag_Info[8] = Fuli_QiankunBag_Frame9_Info1

	Fuli_QiankunBagButton[1] = {button=Fuli_QiankunBag_Frame2_Button,mask1=Fuli_QiankunBag_Frame2_Mask1,mask2=Fuli_QiankunBag_Frame2_Mask2,mask3=Fuli_QiankunBag_Frame2_Mask3,tips=Fuli_QiankunBag_Frame2_ButtonTips}
	Fuli_QiankunBagButton[2] = {button=Fuli_QiankunBag_Frame3_Button,mask1=Fuli_QiankunBag_Frame3_Mask1,mask2=Fuli_QiankunBag_Frame3_Mask2,mask3=Fuli_QiankunBag_Frame3_Mask3,tips=Fuli_QiankunBag_Frame3_ButtonTips}
	Fuli_QiankunBagButton[3] = {button=Fuli_QiankunBag_Frame4_Button,mask1=Fuli_QiankunBag_Frame4_Mask1,mask2=Fuli_QiankunBag_Frame4_Mask2,mask3=Fuli_QiankunBag_Frame4_Mask3,tips=Fuli_QiankunBag_Frame4_ButtonTips}
	Fuli_QiankunBagButton[4] = {button=Fuli_QiankunBag_Frame5_Button,mask1=Fuli_QiankunBag_Frame5_Mask1,mask2=Fuli_QiankunBag_Frame5_Mask2,mask3=Fuli_QiankunBag_Frame5_Mask3,tips=Fuli_QiankunBag_Frame5_ButtonTips}
	Fuli_QiankunBagButton[5] = {button=Fuli_QiankunBag_Frame6_Button,mask1=Fuli_QiankunBag_Frame6_Mask1,mask2=Fuli_QiankunBag_Frame6_Mask2,mask3=Fuli_QiankunBag_Frame6_Mask3,tips=Fuli_QiankunBag_Frame6_ButtonTips}
	Fuli_QiankunBagButton[6] = {button=Fuli_QiankunBag_Frame7_Button,mask1=Fuli_QiankunBag_Frame7_Mask1,mask2=Fuli_QiankunBag_Frame7_Mask2,mask3=Fuli_QiankunBag_Frame7_Mask3,tips=Fuli_QiankunBag_Frame7_ButtonTips}
	Fuli_QiankunBagButton[7] = {button=Fuli_QiankunBag_Frame8_Button,mask1=Fuli_QiankunBag_Frame8_Mask1,mask2=Fuli_QiankunBag_Frame8_Mask2,mask3=Fuli_QiankunBag_Frame8_Mask3,tips=Fuli_QiankunBag_Frame8_ButtonTips}
	Fuli_QiankunBagButton[8] = {button=Fuli_QiankunBag_Frame9_Button,mask1=Fuli_QiankunBag_Frame9_Mask1,mask2=Fuli_QiankunBag_Frame9_Mask2,mask3=Fuli_QiankunBag_Frame9_Mask10,tips=Fuli_QiankunBag_Frame9_ButtonTips}

	-- Fuli_QiankunBagButton[1] = Fuli_QiankunBag_Frame2_Button
	-- Fuli_QiankunBagButton[2] = Fuli_QiankunBag_Frame3_Button
	-- Fuli_QiankunBagButton[3] = Fuli_QiankunBag_Frame4_Button
	-- Fuli_QiankunBagButton[4] = Fuli_QiankunBag_Frame5_Button
	-- Fuli_QiankunBagButton[5] = Fuli_QiankunBag_Frame6_Button
	-- Fuli_QiankunBagButton[6] = Fuli_QiankunBag_Frame7_Button
	-- Fuli_QiankunBagButton[7] = Fuli_QiankunBag_Frame8_Button
	-- Fuli_QiankunBagButton[8] = Fuli_QiankunBag_Frame9_Button
	g_Fuli_QiankunBag_Frame_UnifiedPosition = Fuli_QiankunBag_Frame:GetProperty("UnifiedPosition")
	
	
	g_ButtonPos[1].x	= Fuli_QiankunBag_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= Fuli_QiankunBag_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= Fuli_QiankunBag_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= Fuli_QiankunBag_Button3tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[2].x	= Fuli_QiankunBag_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= Fuli_QiankunBag_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= Fuli_QiankunBag_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= Fuli_QiankunBag_Button5tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[3].x	= Fuli_QiankunBag_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= Fuli_QiankunBag_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= Fuli_QiankunBag_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= Fuli_QiankunBag_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= Fuli_QiankunBag_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= Fuli_QiankunBag_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= Fuli_QiankunBag_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= Fuli_QiankunBag_Button8tips:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[5].x	= Fuli_QiankunBag_Button9:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= Fuli_QiankunBag_Button9:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= Fuli_QiankunBag_Button9tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= Fuli_QiankunBag_Button9tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[6].x	= Fuli_QiankunBag_Button10:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].y	= Fuli_QiankunBag_Button10:GetProperty("UnifiedYPosition");
	g_ButtonPos[6].tipx	= Fuli_QiankunBag_Button10tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].tipy	= Fuli_QiankunBag_Button10tips:GetProperty("UnifiedYPosition");
	
		g_Fuli_QiankunBag_FrameOld:Hide()
		g_Fuli_QiankunBag_Frame2023:Hide()
	
end

function Fuli_QiankunBag_Debug(str)
	Lua_TDU_Log("Fuli_QiankunBag_Debug : "..str)
	--PushDebugMessage("Fuli_QiankunBag_Debug : "..str)
end

--**********************************
-- ONEvent
--**********************************
function Fuli_QiankunBag_OnEvent( event )

	--Fuli_QiankunBag_Button5tips : Hide()
	if ( event == "OPEN_QIANKUNDAI" ) then
		--Fuli_QiankunBag_Debug("OPEN_QIANKUNDAI")
		-- 关闭UI
		if ( IsWindowShow( "Fuli_QiankunBag" ) == true ) then
			this : Hide();
			return
		end
			
		g_Fuli_QiankunBag_Frame2023_LoadFirstTime = 1		
		
		if (tonumber(arg0) == 0) then
			Fuli_QiankunBag_On_ResetPos()
		else
			Fuli_QiankunBag_On_SetLastPos()
		end
		-- 更新数据
		Fuli_QiankunBag_UpdateData();
		Fuli_QiankunBag_FlushWindow(2)

	elseif ( event == "UNIT_LEVEL" ) then
		-- UI状态
		if ( IsWindowShow( "Fuli_QiankunBag" ) == false ) then
			return
		end
		-- 更新数据
		Fuli_QiankunBag_UpdateData();
		Fuli_QiankunBag_FlushWindow(2)

	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 8889071 ) then
	--Fuli_QiankunBag_Debug("UI_COMMAND  8889071")
		g_Fuli_QiankunBag_Frame2023:Hide()
		g_Fuli_QiankunBag_FrameOld:Show()
		-- 取参数
		Fuli_QiankunBagBtnState[ 1 ] = Get_XParam_INT( 0 );
		Fuli_QiankunBagBtnState[ 2 ] = Get_XParam_INT( 1 );
		Fuli_QiankunBagBtnState[ 3 ] = Get_XParam_INT( 2 );
		Fuli_QiankunBagBtnState[ 4 ] = Get_XParam_INT( 3 );
		Fuli_QiankunBagBtnState[ 5 ] = Get_XParam_INT( 4 );
		Fuli_QiankunBagBtnState[ 6 ] = Get_XParam_INT( 5 );
		Fuli_QiankunBagBtnState[ 7 ] = Get_XParam_INT( 6 );
		Fuli_QiankunBagBtnState[ 8 ] = Get_XParam_INT( 7 );
		-- 更新TextInfo
		Fuli_QiankunBag_UpdateTextInfo();
		-- 更新Btn
		Fuli_QiankunBag_UpdateButtonAck();
		-- icon
		Fuli_QiankunBag_UpdateIcon();
		Fuli_QiankunBag_Refresh_ButtonTips()
	elseif (event == "ADJEST_UI_POS") then
		Fuli_QiankunBag_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Fuli_QiankunBag_On_ResetPos()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 888907 ) then
		Fuli_QiankunBag_UpdateData();
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		if this:IsVisible() then
			Fuli_QiankunBag_UpdateData();
			Fuli_QiankunBag_FlushWindow(2)
		else
			Fuli_QiankunBag_Refresh_ButtonTips()
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99847901 ) then	--【新服欢乐月·升级送好礼】
	--	Fuli_QiankunBag_Debug("UI_COMMAND  99847901")
		g_Fuli_QiankunBag_FrameOld:Hide()
		g_Fuli_QiankunBag_Frame2023:Show()
		-- 取参数
		local uiType = Get_XParam_INT( 0 )
		for i = 1, table.getn(g_Fuli_QiankunBag_Frame2023_BtnState) do
			g_Fuli_QiankunBag_Frame2023_BtnState[i].level = Get_XParam_INT( i-1 )
		end
		g_PlayerLevel = Get_XParam_INT( table.getn(g_Fuli_QiankunBag_Frame2023_BtnState))
		g_CurConsume = Get_XParam_INT( table.getn(g_Fuli_QiankunBag_Frame2023_BtnState)+1)
		g_CurExch = Get_XParam_INT( table.getn(g_Fuli_QiankunBag_Frame2023_BtnState)+2)
		-- 更新Btn
		Fuli_QiankunBag_FlushWindow(2); 	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99847902 ) then	--【新服欢乐月·升级送好礼】
		g_Fuli_QiankunBag_FrameOld:Hide()
		g_Fuli_QiankunBag_Frame2023:Show()
		-- 取参数
		local uiType = Get_XParam_INT( 0 )
		for i = 1, table.getn(g_Fuli_QiankunBag_Frame2023_BtnState) do
			g_Fuli_QiankunBag_Frame2023_BtnState[i].consume1 = Get_XParam_INT( i-1 )
		end
		g_PlayerLevel = Get_XParam_INT( table.getn(g_Fuli_QiankunBag_Frame2023_BtnState))
		g_CurConsume = Get_XParam_INT( table.getn(g_Fuli_QiankunBag_Frame2023_BtnState)+1)
		g_CurExch = Get_XParam_INT( table.getn(g_Fuli_QiankunBag_Frame2023_BtnState)+2)
		-- 更新Btn
		Fuli_QiankunBag_FlushWindow(2); 
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99847903 ) then	--【新服欢乐月·升级送好礼】
		g_Fuli_QiankunBag_FrameOld:Hide()
		g_Fuli_QiankunBag_Frame2023:Show()
		-- 取参数
		local uiType = Get_XParam_INT( 0 )
		for i = 1, table.getn(g_Fuli_QiankunBag_Frame2023_BtnState) do
			g_Fuli_QiankunBag_Frame2023_BtnState[i].consume2 = Get_XParam_INT( i-1 )
		end
		--PushDebugMessage(g_Fuli_QiankunBag_Frame2023_BtnState[1].consume2)
		g_PlayerLevel = Get_XParam_INT( table.getn(g_Fuli_QiankunBag_Frame2023_BtnState))
		g_CurConsume = Get_XParam_INT( table.getn(g_Fuli_QiankunBag_Frame2023_BtnState)+1)
		g_CurExch = Get_XParam_INT( table.getn(g_Fuli_QiankunBag_Frame2023_BtnState)+2)
		-- 更新Btn
		Fuli_QiankunBag_FlushWindow(2); 
	end

end


--**********************************
-- 更新Data
--**********************************
function Fuli_QiankunBag_UpdateData()

--PushDebugMessage("QiankunBag")
	-- button
	Fuli_QiankunBag_UpdateButtonReq();
	-- 打开UI

	--左侧按钮选择状态
	Fuli_QiankunBag_Button1:SetCheck(0)
	Fuli_QiankunBag_Button2:SetCheck(0)
	Fuli_QiankunBag_Button3:SetCheck(1)
	Fuli_QiankunBag_Button5:SetCheck(0)
	
	
	local nShaoDang = 2
	local nOneDay = 3
	local nHuiGui 		= 4
	local nSuperSave		= 5
	local nZhanLing =6

	
	local nLevel = Player:GetLevel();
	
	Fuli_QiankunBag_Button5:Show()
	if ( nLevel < 60 ) then
		Fuli_QiankunBag_Button5:Hide()
		nShaoDang = -1
		nOneDay = nOneDay-1
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1

	end

	nOneDay = -1 
	if nOneDay == -1  then
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
		Fuli_QiankunBag_Button7:Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_QiankunBag_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_QiankunBag_Button8 : Hide()
		nHuiGui   = - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1

	end

	if DataPool:Lua_GetUpdateTipsFlag( 3 ) == 1 then
		Fuli_QiankunBag_Button9 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 3 ) == 0 then
		Fuli_QiankunBag_Button9 : Hide()
		nSuperSave =-1; 
		nZhanLing = nZhanLing -1

	end

	Fuli_QiankunBag_Button10:Show()
		if ( nLevel < 30 ) then
			Fuli_QiankunBag_Button10:Hide()
			nZhanLing = nZhanLing -1
		end
	
	
	
	if nShaoDang ~= -1 then
		Fuli_QiankunBag_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
		Fuli_QiankunBag_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
		Fuli_QiankunBag_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
		Fuli_QiankunBag_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);
		
	end
	
	if nOneDay ~= -1 then
		Fuli_QiankunBag_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		Fuli_QiankunBag_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		Fuli_QiankunBag_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		Fuli_QiankunBag_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);
	end
	
	if nHuiGui ~= -1 then		
		Fuli_QiankunBag_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].x);
		Fuli_QiankunBag_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].y);
		Fuli_QiankunBag_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].tipx);
		Fuli_QiankunBag_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].tipy);
	end
	
	if nSuperSave ~= -1 then
		Fuli_QiankunBag_Button9:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].x);
		Fuli_QiankunBag_Button9:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].y);
		Fuli_QiankunBag_Button9tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].tipx);
		Fuli_QiankunBag_Button9tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].tipy);
		
	end

	if nZhanLing ~= -1 then
		Fuli_QiankunBag_Button10:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].x);
		Fuli_QiankunBag_Button10:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].y);
		Fuli_QiankunBag_Button10tips:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].tipx);
		Fuli_QiankunBag_Button10tips:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].tipy);
	end
	
	--红点显示
	Fuli_QiankunBag_Refresh_ButtonTips()

	this : Show();

end


--**********************************
-- 更新TextInfo
--**********************************
function Fuli_QiankunBag_UpdateTextInfo()

	local nLevel = Player : GetLevel();

	for i = 1, table.getn( Fuli_QiankunBagBtnState ) do
		if ( nLevel < Fuli_QiankunBagLevel[ i ] ) then
			Fuli_QiankunBag_Info[ i ] : SetText( Fuli_QiankunBagText1Info[ i ] );
		else
			Fuli_QiankunBag_Info[ i ] : SetText( Fuli_QiankunBagText2Info[ i ] );
		end
	end

end


--**********************************
-- 更新icon
--**********************************
function Fuli_QiankunBag_UpdateIcon()

	-- 刷新Item
	DataPool : Lua_UpdateQiankunBagItem();

	-- 玩家未领取的奖励
	local nBegin = 1;
	local nNext = table.getn( Fuli_QiankunBagBtnState );
	-- for i = 1, table.getn( Fuli_QiankunBagBtnState ) do
		-- if ( Fuli_QiankunBagBtnState[ i ] == 0 ) then
			-- nBegin = i
			-- nNext = nBegin + 1;
			-- if ( nNext >= table.getn( Fuli_QiankunBagBtnState ) ) then
				-- nNext = table.getn( Fuli_QiankunBagBtnState );
			-- end
			-- break
		-- end
	-- end

	-- 无效值
	if ( nBegin == -1 or nNext == -1 ) then
		this:Hide();
		return
	end

	-- 修改FrameUI的高度
--	if ( nBegin == table.getn( Fuli_QiankunBagBtnState ) and nNext == table.getn( Fuli_QiankunBagBtnState ) ) then
--		Fuli_QiankunBag_Frame : SetProperty("UnifiedSize", "{{0.000000,560.000000},{0.000000,205.000000}");
--		if SystemSetup:IsClassic() == 0 then
--			Fuli_QiankunBag_Frame : SetProperty("UnifiedSize", "{{0.000000,580.000000},{0.000000,225.000000}");
--		end
--	else
--		Fuli_QiankunBag_Frame : SetProperty("UnifiedSize", "{{0.000000,560.000000},{0.000000,420.000000}");
--		if SystemSetup:IsClassic() == 0 then
--			Fuli_QiankunBag_Frame : SetProperty("UnifiedSize", "{{0.000000,580.000000},{0.000000,420.000000}");
--		end
--	end

	-- 隐藏Frame
	for i = 1, table.getn( Fuli_QiankunBag_FrameInfo ) do
		Fuli_QiankunBag_FrameInfo[ i ] : Hide();
	end

	-- Frame
	for row = 1, nNext - nBegin + 1 do
		Fuli_QiankunBag_FrameInfo[ row ] : Show();
		-- Icon
		for col = 1, table.getn( Fuli_QiankunBagIcon[ row ] ) do
			-- 初始化
			Fuli_QiankunBagIcon[ row	][ col ] : SetActionItem( -1 );
			Fuli_QiankunBagIcon[ row ][ col ] : Hide();

			-- 设置
			local theAction = EnumAction( ( row + nBegin - 2 ) * table.getn( Fuli_QiankunBagIcon[ row ] ) + ( col - 1 ), "qiankundai_item" );
			if ( theAction : GetID() ~= 0 ) then
				Fuli_QiankunBagIcon[ row ][ col ] : SetActionItem( theAction : GetID() );
				Fuli_QiankunBagIcon[ row ][ col ] : Show();
			end
		end
	end

end


--**********************************
-- 请求更新Btn状态
--**********************************
function Fuli_QiankunBag_UpdateButtonReq()

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateBtnState" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888907 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 0 );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()
	
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateBtnState_2023" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 998479 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 0 );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()
end


--**********************************
-- 更新Btn状态
--**********************************
function Fuli_QiankunBag_UpdateButtonAck()

	-- 等级
	local nLevel = Player : GetLevel();

	-- 玩家未领取的奖励
	for i = 1, table.getn( Fuli_QiankunBagBtnState ) do
		if ( Fuli_QiankunBagBtnState[ i ] == 0 ) then
			if ( nLevel >= Fuli_QiankunBagLevel[ i ] ) then
				Fuli_QiankunBagButton[i].button : SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover");
				Fuli_QiankunBagButton[i].button : Enable();
				Fuli_QiankunBagButton[i].mask1 : Hide();
				Fuli_QiankunBagButton[i].mask2 : Hide();
				Fuli_QiankunBagButton[i].mask3 : Hide();
				Fuli_QiankunBagButton[i].tips : Hide()
			else
				Fuli_QiankunBagButton[i].button : SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable");
				Fuli_QiankunBagButton[i].button : Disable();
				Fuli_QiankunBagButton[i].mask1 : Show();
				Fuli_QiankunBagButton[i].mask2 : Show();
				Fuli_QiankunBagButton[i].mask3 : Show();
				Fuli_QiankunBagButton[i].tips : Show()
			end
		else
			Fuli_QiankunBagButton[i].button : SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_Disable");
			Fuli_QiankunBagButton[i].button : Disable();
			Fuli_QiankunBagButton[i].mask1 : Hide();
			Fuli_QiankunBagButton[i].mask2 : Hide();
			Fuli_QiankunBagButton[i].mask3 : Hide();
			Fuli_QiankunBagButton[i].tips : Show()
		end
	end

end



--**********************************
-- 按钮
--**********************************
function Fuli_QiankunBag_Clicked( nIndex )

	-- 玩家未领取的奖励
	-- local nBegin = -1;
	-- for i = 1, table.getn( Fuli_QiankunBagBtnState ) do
		-- if ( Fuli_QiankunBagBtnState[ i ] == 0 ) then
			-- nBegin = i
			-- break
		-- end
	-- end

	-- -- 无效值
	-- if ( nBegin == -1 ) then
		-- this:Hide();
		-- return
	-- end

	if nIndex > table.getn( Fuli_QiankunBagBtnState ) then
		return
	end

	if ( Fuli_QiankunBagBtnState[ nIndex ] == 1 ) then
		return
	end

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetQianKunDaiPrize" ); 	-- 脚本号
		Set_XSCRIPT_ScriptID( 888907 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()

end


--**********************************
-- 关闭UI
--**********************************
function Fuli_QiankunBag_OnHiden()
	
	g_Fuli_QiankunBag_Frame2023_LoadFirstTime = 1
end



function Fuli_QiankunBag_Button1_Click()

	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_9}")
		return
	end
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name("OpenWindowRequest")
--		Set_XSCRIPT_ScriptID(891106)
--		Set_XSCRIPT_ParamCount(0)
--	Send_XSCRIPT()
	OpenMonthlySign(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_QiankunBag_Frame:GetProperty("UnifiedPosition"), 1)
--	this:Hide()
end

function Fuli_QiankunBag_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end
	OpenStrongRoadDiaoWen(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_QiankunBag_Frame:GetProperty("UnifiedPosition"), 1)

end

function Fuli_QiankunBag_Button3_Click()
--	OpenQianKunDai()

end

function Fuli_QiankunBag_Button4_Click()

end

function Fuli_QiankunBag_Button5_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end
	
	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OpenDailyFuBen")
	--	Set_XSCRIPT_ScriptID(892428)
	--	Set_XSCRIPT_Parameter(0,0);
	--	Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT()
	
	OpenZhaoHui(1)
	
	Variable:SetVariable("SelfFuliUIPos", Fuli_QiankunBag_Frame:GetProperty("UnifiedPosition"), 1)
end


function Fuli_QiankunBag_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end
	Variable:SetVariable("SelfFuliUIPos", Fuli_QiankunBag_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_QiankunBag_Button8_Click()
	OpenHuiGui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_QiankunBag_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_QiankunBag_Button9_Click()
	OpenSuperSaveUp(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_QiankunBag_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_QiankunBag_Button10_Click()
	local nLevel = Player:GetLevel();
	if( nLevel < 30 ) then
		PushDebugMessage("#{TLZL_190802_03}")	
		return
	end
	OpenZhanLing(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_QiankunBag_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_QiankunBag_Refresh_ButtonTips()

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_QiankunBag_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_QiankunBag_Button7tips : Hide()
	end

	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_QiankunBag_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_QiankunBag_Button8tips : Hide()
	end
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_QiankunBag_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_QiankunBag_Button8 : Hide()
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		Fuli_QiankunBag_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_QiankunBag_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_QiankunBag_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_QiankunBag_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		Fuli_QiankunBag_Button3tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_QiankunBag_Button3tips : Hide()
	end
	
	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		Fuli_QiankunBag_Button5tips : Show()
	else
		Fuli_QiankunBag_Button5tips : Hide()
	end
	
	
	-- 福利 累充 
	if DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 then
		Fuli_QiankunBag_Button9tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 4 ) == 0 then
		Fuli_QiankunBag_Button9tips : Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 then
		Fuli_QiankunBag_Button10tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 5 ) == 0 then
		Fuli_QiankunBag_Button10tips : Hide()
	end

	
end

function Fuli_QiankunBag_On_ResetPos()
	Fuli_QiankunBag_Frame:SetProperty("UnifiedPosition", g_Fuli_QiankunBag_Frame_UnifiedPosition)
end

function Fuli_QiankunBag_On_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
		Fuli_QiankunBag_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end

--2023

--**********************************
-- 更新Data
--**********************************
function Fuli_QiankunBag_OnShow(ShowTime)
	Fuli_QiankunBag_UpdateButtonReq();
	Fuli_QiankunBag_FlushWindow(ShowTime)		--在服务器数据返回之前,根据数据初始值,先初步构建界面
end
--**********************************
-- 【新服欢乐月·升级送好礼】刷新界面
--**********************************
function Fuli_QiankunBag_FlushWindow(ShowTime)

	--如果是第一次调用此函数,需要将物品奖励加载到显示界面上
	if g_Fuli_QiankunBag_Frame2023_LoadFirstTime == 1 then
			
		
		g_Fuli_QiankunBag_Frame2023_List:Clear()	
		
		for levelidx = 1,  g_Fuli_QiankunBag_Frame2023_TotalEnum do

			local singleGift = g_Fuli_QiankunBag_Frame2023_Gifts[levelidx]
			if singleGift == nil then
			   break
			end
			
			local bar = g_Fuli_QiankunBag_Frame2023_List:AddChild("Fuli_QiankunBag_Frame10_Bk")
			if not bar then
			   
			end

			g_Fuli_QiankunBag_Frame2023_List_Item[levelidx] = bar	
			
			local normalBK = 0
			local consume1BK = 0
			local consume2BK = 0
			
			g_Fuli_QiankunBag_Frame2023_List_Item[levelidx]:GetSubItem("Fuli_QiankunBag_Frame10_Bk1_Button1"):SetEvent("MouseLClick", string.format("Fuli_QiankunBag_Frame3_GetGift1(%d)", levelidx))
			g_Fuli_QiankunBag_Frame2023_List_Item[levelidx]:GetSubItem("Fuli_QiankunBag_Frame10_Bk2_Button1"):SetEvent("MouseLClick", string.format("Fuli_QiankunBag_Frame3_GetGift2(%d)", levelidx))  
			g_Fuli_QiankunBag_Frame2023_List_Item[levelidx]:GetSubItem("Fuli_QiankunBag_Frame10_Bk3_Button1"):SetEvent("MouseLClick", string.format("Fuli_QiankunBag_Frame3_GetGift3(%d)", levelidx))  

			
			local singleNormal = singleGift.Normal
			if singleNormal ~= nil then
				bar:GetSubItem("Fuli_QiankunBag_Frame10_Bk1"):Show()
				bar:GetSubItem("Fuli_QiankunBag_Frame10_Bk_Text"):SetText(g_Fuli_QiankunBag_Frame2023_ListItemText[levelidx])
				normalBK = 1
				for j = 1, 3 do
					---local j = 1
					local	giftItemID	=	-1
					local	giftItemNum	=	0		
					if singleNormal[j] ~= nil then									
						giftItemID	=	singleNormal[j].GiftItemID
						giftItemNum	= 	singleNormal[j].num
						local theAction = DataPool:CreateBindActionItemForShow(giftItemID, giftItemNum)
						if theAction:GetID() ~= 0 then
							bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIcons.Normal[j]):SetActionItem(theAction:GetID());
							bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIcons.Normal[j]):Show();
							if singleNormal[j].new ~= nil and singleNormal[j].new == 1 then
								bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIconsImages.Normal[j]) : SetProperty("Image", "set:CommonFrame20 image:Item_New");
							else
								bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIconsImages.Normal[j]) : Hide()
							end
						end					
					else
						bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIcons.Normal[j]):Hide()  
						bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIconsImages.Normal[j]):Hide()
					end
				end
			else
				bar:GetSubItem("Fuli_QiankunBag_Frame10_Bk1"):Hide()
				normalBK = 0
			end
							
			local singleConsume1 = singleGift.Consume1
			if singleConsume1 ~= nil then
				bar:GetSubItem("Fuli_QiankunBag_Frame10_Bk2"):Show()
				local bk2Text = ScriptGlobal_Format("#{XSJNH_230209_13}",g_Fuli_QiankunBag_Frame2023_GetGiftLevel[levelidx].consume1)
				---bar:GetSubItem("Fuli_QiankunBag_Frame3_Bk2_Text1"):SetText(bk2Text)
				consume1BK = 1
				for j = 1, 2 do
					if singleConsume1[j] ~= nil then		
						giftItemID	=	singleConsume1[j].GiftItemID
						giftItemNum	= 	singleConsume1[j].num
						local theAction = DataPool:CreateBindActionItemForShow(giftItemID, giftItemNum)
						if theAction:GetID() ~= 0 then
							bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIcons.Consume1[j]):SetActionItem(theAction:GetID());
							bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIcons.Consume1[j]):Show();
							if singleConsume1[j].new ~= nil and singleConsume1[j].new == 1 then
								bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIconsImages.Consume1[j]) : SetProperty("Image", "set:CommonFrame20 image:Item_New");
							else
								bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIconsImages.Consume1[j]) : Hide()
							end
						end					
					else
						bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIcons.Consume1[j]):Hide()  
						bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIconsImages.Consume1[j]):Hide()  
					end	
				end
			else
				bar:GetSubItem("Fuli_QiankunBag_Frame10_Bk2"):Hide()
				consume1BK = 0				
			end
			
			local singleConsume2 = singleGift.Consume2
			if singleConsume2 ~= nil then
				bar:GetSubItem("Fuli_QiankunBag_Frame10_Bk2"):Show()
				local bk3Text = ScriptGlobal_Format("#{XSJNH_230209_13}",g_Fuli_QiankunBag_Frame2023_GetGiftLevel[levelidx].consume2)
				---bar:GetSubItem("Fuli_QiankunBag_Frame3_Bk3_Text1"):SetText(bk3Text)
				consume2BK = 1
				for j = 1, 2 do
					if singleConsume2[j] ~= nil then		
						giftItemID	=	singleConsume2[j].GiftItemID
						giftItemNum	= 	singleConsume2[j].num
						local theAction = DataPool:CreateBindActionItemForShow(giftItemID, giftItemNum)
						if theAction:GetID() ~= 0 then
							bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIcons.Consume2[j]):SetActionItem(theAction:GetID());
							bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIcons.Consume2[j]):Show();
							if singleConsume2[j].new ~= nil and singleConsume2[j].new == 1 then
								bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIconsImages.Consume2[j]) : SetProperty("Image", "set:CommonFrame20 image:Item_New");
							else
								bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIconsImages.Consume2[j]) : Hide()
							end
						end					
					else
						bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIcons.Consume2[j]):Hide()  
						bar:GetSubItem(g_Fuli_QiankunBag_Frame2023_GiftsIconsImages.Consume2[j]):Hide()  
					end	
				end
			else
				bar:GetSubItem("Fuli_QiankunBag_Frame10_Bk3"):Hide()
				consume2BK = 0				
			end			
			
		end
		
		g_Fuli_QiankunBag_Frame2023_LoadFirstTime = 0
	end

	local nLevel = g_PlayerLevel; --Player : GetLevel();

	local levelGrade = 1;

	for i = 1,table.getn(g_Fuli_QiankunBag_Frame2023_GetGiftLevel)  do
		if nLevel < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[i].level then
			levelGrade = i
			break
		end
	end
	
	--PushDebugMessage("levelGrade = "..levelGrade.."  nLevel = "..nLevel)

	--获取活动起止时间
	local EndDate = DataPool:GetPlayerMissionData42TIME(g_XinShouNew_MD)

	local deEndYear = math.floor(EndDate/100000000)
	local deEndMon = math.mod(math.floor(EndDate/1000000),100)
	local deEndDay = math.mod(math.floor(EndDate/10000),100)
	local deEndHour = math.mod(math.floor(EndDate/100),100)

	--先设置所有可以领取的Button的状态为:"已领取"或者"未领取"
	for i = 1, levelGrade - 1 do

		if g_Fuli_QiankunBag_Frame2023_BtnState[i].level == 1 then
			--设置按钮图片为已领取
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk1_Button1") : SetProperty("DisabledImage","set:XSYNew2023 image:YLQ")
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk1_Button1") : Disable()
		else
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk1_Button1") : Enable()
		end
		
		if g_Fuli_QiankunBag_Frame2023_BtnState[i].consume1 == 1 then
			--设置按钮图片为已领取
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk2_Button1") : SetProperty("DisabledImage","set:XSYNew2023 image:YLQ")
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk2_Button1") : Disable()
		else
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk2_Button1") : Enable()
		end
		
		if g_Fuli_QiankunBag_Frame2023_BtnState[i].consume2 == 1 then
			--设置按钮图片为已领取
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk3_Button1") : SetProperty("DisabledImage","set:XSYNew2023 image:YLQ")
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk3_Button1") : Disable()
		else
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk3_Button1") : Enable()
		end
		
	end
	
	for i = 1, levelGrade - 1 do
		if g_CurConsume < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[i].consume1 or g_CurExch < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[i].consume1 then
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk2_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk2_Button1") : Disable()
		else
		--	g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk2_Button1") : Enable()
		end
		
		if g_CurConsume < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[i].consume2 or g_CurExch < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[i].consume2 then
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk3_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk3_Button1") : Disable()
		else
		--	g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk3_Button1") : Enable()
		end
	end
	
	

	for i = levelGrade, table.getn(g_Fuli_QiankunBag_Frame2023_List_Item) do
			--设置未达成的Button
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk1_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk1_Button1") : Disable()
			
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk2_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk2_Button1") : Disable()

			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk3_Button1") : SetProperty("DisabledImage","set:Spring24 image:NotReach")
			g_Fuli_QiankunBag_Frame2023_List_Item[i]:GetSubItem("Fuli_QiankunBag_Frame10_Bk3_Button1") : Disable()
	end
	

	--设置额外需要隐藏的[按钮]和图标为不可见
	local kajiType = KaJi:LuaFnGetKaJiType(10)
	local extraHideIndexBegin = g_KajiTable_XSJNH[4][kajiType][1]
	local extraHideIndexEnd = g_KajiTable_XSJNH[4][kajiType][2]
	local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
	if nSpecKaJi89 == 1 or nSpecKaJi89 == 2 then
		extraHideIndexBegin = 12
		extraHideIndexEnd = 13
	end
	if  extraHideIndexBegin > 0 and extraHideIndexBegin <= extraHideIndexEnd then
		for i = extraHideIndexBegin, extraHideIndexEnd do
	--		g_Fuli_QiankunBag_Frame2023_List_Item[i] : Hide()
		end
	end

end
--********************************************************************
-- 按钮,客户端界面"领取奖励"按钮点击响应事件函数
--********************************************************************
function Fuli_QiankunBag_Frame3_GetGift1( nIndex )
	
	--PushDebugMessage("Fuli_QiankunBag_Frame3_GetGift1")
	--客户端进行初步的检测,检测通过由服务器脚本执行发奖逻辑
	--1.检测玩家的等级是否到达可领奖的等级
	local nLevel = Player : GetLevel()
	if nLevel < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[nIndex].level then
		PushDebugMessage("#{SJSHL_140919_24}")					--对不起，您尚未达到可领取奖励的等级，无法领取奖励
		return
	end
	--2.玩家是否未领取该奖励
	if nIndex < 1 or nIndex > 13 then
		return
	elseif g_Fuli_QiankunBag_Frame2023_BtnState[nIndex].level == 1 then					--按钮为"未点亮"状态,说明根据MF判断玩家已经领取过该两例
		PushDebugMessage("#{SJSHL_140919_25}")					--对不起,您已经领取过此奖励,无法再次领取
		return
	end
	--3.判断玩家背包位置数是否足够
--	local nBegin = -1;
	--for i = 1, table.getn( XinShouNew_LevelUpBtnState ) do
		--if ( XinShouNew_LevelUpBtnState[ i ] == 0 ) then
		--	nBegin = i
		--	break
		--end
	--end

	--4.全部检测通过,调用服务器脚本的领奖逻辑
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLevelUp_common" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998479 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()

end

function Fuli_QiankunBag_Frame3_GetGift2( nIndex )
	
	--	PushDebugMessage("Fuli_QiankunBag_Frame3_GetGift2  nIndex = "..nIndex)
	--客户端进行初步的检测,检测通过由服务器脚本执行发奖逻辑
	--1.检测玩家的等级是否到达可领奖的等级
	local nLevel = Player : GetLevel()
	if nLevel < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[nIndex].level then
		PushDebugMessage("#{SJSHL_140919_24}")					--对不起，您尚未达到可领取奖励的等级，无法领取奖励
		return
	end
	
	--判断消费限制
	if g_CurConsume < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[nIndex].consume1 or g_CurExch < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[nIndex].consume1 then
		PushDebugMessage("#{XSJNH_230209_06}")			--对不起，您尚未达到可领取奖励的等级，无法领取奖励
		return
	end
	
	--2.玩家是否未领取该奖励
	if nIndex < 1 or nIndex > 13 then
		return
	elseif g_Fuli_QiankunBag_Frame2023_BtnState[nIndex].consume1 == 1 then					--按钮为"未点亮"状态,说明根据MF判断玩家已经领取过该两例
		PushDebugMessage("#{SJSHL_140919_25}")					--对不起,您已经领取过此奖励,无法再次领取
		return
	end
	--3.判断玩家背包位置数是否足够
--	local nBegin = -1;
	--for i = 1, table.getn( XinShouNew_LevelUpBtnState ) do
		--if ( XinShouNew_LevelUpBtnState[ i ] == 0 ) then
		--	nBegin = i
		--	break
		--end
	--end

	--4.全部检测通过,调用服务器脚本的领奖逻辑
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLevelUp_ljxf1" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998479 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()

end

function Fuli_QiankunBag_Frame3_GetGift3( nIndex )
	
			
	--客户端进行初步的检测,检测通过由服务器脚本执行发奖逻辑
	--1.检测玩家的等级是否到达可领奖的等级
	local nLevel = Player : GetLevel()
	if nLevel < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[nIndex].level then
		PushDebugMessage("#{SJSHL_140919_24}")					--对不起，您尚未达到可领取奖励的等级，无法领取奖励
		return
	end
	
	--判断消费限制
	if g_CurConsume < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[nIndex].consume2 or g_CurExch < g_Fuli_QiankunBag_Frame2023_GetGiftLevel[nIndex].consume2 then
		PushDebugMessage("#{XSJNH_230209_45}")			--对不起，您尚未达到可领取奖励的等级，无法领取奖励
		return
	end

	--2.玩家是否未领取该奖励
	if nIndex < 1 or nIndex > 13 then
		return
	elseif g_Fuli_QiankunBag_Frame2023_BtnState[nIndex].consume2 == 1 then					--按钮为"未点亮"状态,说明根据MF判断玩家已经领取过该两例
		PushDebugMessage("#{SJSHL_140919_25}")					--对不起,您已经领取过此奖励,无法再次领取
		return
	end
	--3.判断玩家背包位置数是否足够
--	local nBegin = -1;
	--for i = 1, table.getn( XinShouNew_LevelUpBtnState ) do
		--if ( XinShouNew_LevelUpBtnState[ i ] == 0 ) then
		--	nBegin = i
		--	break
		--end
	--end

	--4.全部检测通过,调用服务器脚本的领奖逻辑
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForLevelUp_ljxf2" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998479 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()

end

