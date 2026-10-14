--VIP特权功能界面

local g_VIP_Shop_Frame_UnifiedPosition

local g_VIP_ShopList = {}		--左边栏按钮列表
local g_VIP_ShopNum = 8 --local g_VIP_ShopNum = 7 --test by yuanpeilong

local g_VIP_ShopMaxNum = 20		--功能的最大数目
local g_VIP_Shop_Check = nil;

local g_VIP_ShopBKWindow = {}
local g_VIP_ShopBKIcon = {}		--功能选项图标列表
local g_VIP_ShopBKList = {}		--功能选项按钮列表
local g_VIP_ShopBKId = {		--用于保存按钮对应的功能ID
	0,0,0,0,0,0,0,0,
}

--VIP年终回馈宝匣 Start
local g_VIP_StartDay = 20260101
local g_VIP_EndDay = 20260131
--VIP年终回馈宝匣 End

--VIP年中回馈宝匣 Start
local g_VIP_StartDay_M = 20260801
local g_VIP_EndDay_M = 20260831
--VIP年中回馈宝匣 End

--vip领奖功能设计-2014-YPL
local g_2014_vip_List = {
[1] = 5091,
[2] = 5092,
}

local g_VIP_Start = 20181102
local g_VIP_End = 20181202

local g_2017_vip_show = 0

local g_RPIU = {}
local g_VipFunc_2_RPIU = {

	[3] = 4 ,
	[5] = 5 ,
	[6] = 6 ,
	[12] = 7,
	[4] = 8,
	[17] = 30,
	[22] = 29,

}
																		
local g_Max_Vip_Level = 9
local g_VIP_ShopImageList = {	--功能图标，目前12个
	"set:TaskTools15 image:TaskTools15_8",		--随身珍兽商店
	"set:TaskTools15 image:TaskTools15_7",		--随身银行
	"set:TaskTools15 image:TaskTools15_12",		--领取专属表情
	"set:TaskTools15 image:TaskTools15_14",		--领取专属炫装
	"set:TaskTools15 image:TaskTools15_11",		--领取周道具奖励
	"set:TaskTools15 image:TaskTools15_4",		--多人组队传送
	----------我是分割线----------
	"set:TaskTools15 image:TaskTools15_9",					--随身装备修理
	"set:CircularTaskTool28 image:CircularTaskTool28_16",	--增加装备可修理次数
	"set:TaskTools15 image:TaskTools15_5",					--随身神器修理
	"set:TaskTools15 image:TaskTools15_6",					--随身衣柜
	"set:CircularTaskTool28 image:CircularTaskTool28_15",	--随身冻结（解冻）双倍时间
	"set:TaskTools15 image:TaskTools15_13",					--领取双人动作包
	--------------------------------------------
	"set:TaskTools15 image:TaskTools15_16",				--珍兽银行
	"",													--额外直接激活高级凝炼
	"" ,               								 	--单人繁殖珍兽时间缩短
	"",   --随身附体外形
	"set:CircularTaskTool57 image:CircularTaskTool57_2",  --领取年终回馈宝匣
	"set:TaskTools17 image:TaskTools17_2",  --随身装备修理
	"set:TaskTools17 image:TaskTools17_4",  --vip领奖功能设计-2014-YPL
	"set:TaskTools17 image:TaskTools17_13", --易容阁
	"set:TaskTools17 image:TaskTools17_15", --2015 VIP随身移功能 By YuanPeiLong --这个是替代，策划没给东西啊，别提bug
	"set:CircularTaskTool109 image:CircularTaskTool109_9",  --领取年中回馈宝匣
	"set:Huodong_21 image:Huodong_21_6",  --玄灵丹冻结解冻
}

local g_VIP_ShopToolTips = {	--按钮的tooltips
	"#{VIPTQ_110908_80}",
	"#{VIPTQ_110908_81}",
	"#{VIPTQ_110908_83}",
	"#{VIPTQ_110908_84}",
	"#{VIPTQ_110908_85}",
	"#{VIPTQ_110908_82}",
	----------我是分割线----------
	"#{VIPSSXL_180814_5}",--7武器VIPTQ_120221_22
	"#{VIPTQ_120221_25}",
	"#{VIPTQ_120221_23}",
	"#{VIPTQ_120221_24}",
	"#{VIPTQ_120221_26}",
	"#{VIPTQ_120221_27}",
	-------------------------
	"#{VIPTQ3_120517_46}",
	"",
	"",
	"",
	"#{VIPBS_131125_03}",
	"#{VIPWH_140707_01}",
	"#{VLQJL_140910_4}",	--vip领奖功能设计-2014-YPL
	"#{GXHDZ_141121_92}", --易容阁
	"#{VIPZY_141216_01}", --2015 VIP随身移功能 By YuanPeiLong
	"#{NZHK_200622_04}", -- 年中回馈宝匣
	"#{TLZL_231107_55}", -- 玄灵丹冻结解冻
}

local g_VIP_ShopInfo = {
	--type：1，快捷功能；2，道具奖励功能；3，游戏功能
	--flag：type=1时：1，按次数的；0，无限次。 type=2时：暂时没用到，无意义。type=3时：0，无限次；1，按次数！
	--[0] 有次数限制，没用完 [1] 无次数限制  [2] 有次数限制，用完了 [4]仅用于道具领取，表示未激活

	{type=1,flag=1, [0]="#{VIPTQ_110908_52}"	, [1]="#{VIPTQ_170508_05}"	, [2]="#{VIPTQ_110908_53}"	,[3]="#{XFVIP_120516_03}",[4]="" },	--随身珍兽商店 1
	{type=1,flag=1, [0]="#{VIPTQ_110908_54}"	, [1]="#{VIPTQ_170509_01}"	, [2]="#{VIPTQ_110908_55}"	,[3]="#{XFVIP_120516_04}",[4]="" },	--随身银行 2
	{type=2,flag=0, [0]="#{VIPTQ_110908_58}"	, [1]=""				   	, [2]="#{VIPTQ_110908_59}"	,[3]="#{XFVIP_120516_14}",[4]="#{VIPTQ_160630_5}" },	--领取专属表情 3
	{type=2,flag=0, [0]="#{VIPTQ_110908_60}"	, [1]=""				   	, [2]="#{VIPTQ_110908_61}"	,[3]="#{XFVIP_120516_15}",[4]="#{VIPTQ_160630_3}" },	--领取专属炫装 4
	{type=2,flag=0, [0]="#{VIPTQ_110908_62}"	, [1]=""				   	, [2]="#{VIPTQ_110908_63}"	,[3]="#{XFVIP_120516_17}",[4]="#{VIPTQ_160630_7}" },	--领取周道具奖励 5
	{type=2,flag=0, [0]="#{VIPTQ_110908_56}"	, [1]=""			   	   	, [2]="#{VIPTQ_110908_57}"	,[3]="#{XFVIP_120516_13}",[4]="#{VIPTQ_160630_4}" },	--多人组队传送 6
	{type=1,flag=1, [0]="#{VIPTQ3_120517_58}"	, [1]="#{VIPTQ_120221_28}"	, [2]="#{VIPTQ3_120517_59}"	,[3]="#{XFVIP_120516_06}",[4]="" },	--随身装备修理 7
	{type=1,flag=1, [0]="#{VIPTQ3_120517_60}"	, [1]="#{VIPTQ_120221_29}"	, [2]="#{VIPTQ3_120517_61}"	,[3]="#{XFVIP_120516_07}",[4]="" },	--增加装备可修理次数 8
	{type=1,flag=1, [0]="#{VIPTQ_120221_30}"	, [1]="#{VIPTQ_170508_06}"	, [2]="#{VIPTQ_120221_31}"	,[3]="#{XFVIP_120516_05}",[4]="" },	--随身神器修理 9
	{type=1,flag=0, [0]=""					 	, [1]="#{VIPTQ_120221_32}"	, [2]="#{VIPTQ_120221_32}"	,[3]="#{XFVIP_120516_08}",[4]="" },	--随身衣柜 10
	{type=1,flag=0, [0]=""					 	, [1]="#{VIPTQ_120221_33}"	, [2]="#{VIPTQ_120221_33}"	,[3]="#{XFVIP_120516_09}",[4]="" },	--随身冻结双倍时间 11
	{type=2,flag=0, [0]="#{VIPTQ_120221_34}"	, [1]=""                  	, [2]="#{VIPTQ_120221_35}"	,[3]="#{XFVIP_120516_16}",[4]="#{VIPTQ_160630_6}" },	--领取双人动作包 12
	{type=1,flag=1, [0]="#{VIPTQ3_120517_21}"	, [1]="#{VIPTQ3_120517_20}"	, [2]="#{VIPTQ3_120517_43}"	,[3]="#{XFVIP_120516_10}",[4]="" },	--随身珍兽银行 13
	{type=3,flag=1, [0]="#{VIPTQ3_120517_24}"	, [1]="#{VIPTQ3_120517_23}"	, [2]="#{VIPTQ3_120517_24}"	,[3]="#{XFVIP_120516_19}",[4]="" },	--额外直接激活高级凝炼 14
	{type=3,flag=0, [0]="#{VIPTQ3_120517_26}"	, [1]="#{VIPTQ3_120517_25}"	, [2]="#{VIPTQ3_120517_26}"	,[3]="#{XFVIP_120516_20}",[4]="" },	--单人繁殖珍兽时间缩短 15
	{type=1,flag=0, [0]=""	, [1]="#{VIP_FT_121109_05}"	, [2]="#{VIP_FT_121109_05}"	,[3]="#{VIP_FT_121109_06}",[4]="" },	-- 随身更换附体外形 16
	{type=2,flag=0, [0]=""	, [1]="#{VIP_FT_121109_05}"	, [2]="#{VIP_FT_121109_05}"	,[3]="#{VIP_FT_121109_06}",[4]="" },	-- VIP年终回馈 17
	{type=1,flag=1, [0]="#{VIPWH_140707_06}"	, [1]="#{VIPWH_140707_08}"	, [2]="#{VIPWH_140707_07}"	,[3]="#{VIPWH_140707_09}",[4]="" },	-- 随身武魂修理 18
	{type=2,flag=0, [0]=""	, [1]=""	, [2]=""	,[3]="",[4]="" },	--vip领奖功能设计-2014-YPL
	{type=1,flag=0, [0]=""	, [1]="#{GXHDZ_141121_111}"	, [2]=""	,[3]="#{GXHDZ_141121_112}",[4]="" },	--易容阁
	{type=1,flag=0, [0]=""	, [1]="#{VIPZY_141216_13}"	, [2]=""	,[3]="",[4]="" },	--2015 VIP随身移功能 By YuanPeiLong
	{type=2,flag=0, [0]=""	, [1]="#{VIP_FT_121109_05}"	, [2]="#{VIP_FT_121109_05}"	,[3]="#{VIP_FT_121109_06}",[4]="" },	-- VIP年中回馈 22
	{type=1,flag=0, [0]=""	, [1]=""	, [2]=""	,[3]="",[4]="" },	-- 玄灵丹冻结解冻
}

local g_itemtimes = {
	[1] = "", [2] = "", [3] = "", [4] = "",	[5] = "", [6] = "10", [7] = "15", [8] = "20", [9] = "30",
}

local g_VipPrizeTwelve = {	--专属动作包
	[1] = "", [2] = "", [3] = "", [4] = "",	[5] = "", [6] = "", [7] = "7", [8] = "15", [9] = "30",
}
--设置经典版使用的VIP图标集合
local g_VIP_Image = {	--VIP图标
	[0] = "set:CommonFrame19 image:VIPLevel_0",
	[1] = "set:CommonFrame19 image:VIPLevel_1",
	[2] = "set:CommonFrame19 image:VIPLevel_2",
	[3] = "set:CommonFrame19 image:VIPLevel_3",
	[4] = "set:CommonFrame19 image:VIPLevel_4",
	[5] = "set:CommonFrame19 image:VIPLevel_5",
	[6] = "set:CommonFrame19 image:VIPLevel_6",
	[7] = "set:CommonFrame19 image:VIPLevel_7",
	[8] = "set:CommonFrame19 image:VIPLevel_8",
	[9] = "set:CommonFrame19 image:VIPLevel_9",
--	[10] = "set:CommonFrame19 image:VIPLevel_10",
--	[11] = "set:CommonFrame19 image:VIPLevel_11",
--	[12] = "set:CommonFrame19 image:VIPLevel_12",
--	[13] = "set:CommonFrame19 image:VIPLevel_13",
--	[14] = "set:CommonFrame19 image:VIPLevel_14",
--	[15] = "set:CommonFrame19 image:VIPLevel_15",
--	[16] = "set:CommonFrame19 image:VIPLevel_16",
--	[17] = "set:CommonFrame19 image:VIPLevel_17",
--	[18] = "set:CommonFrame19 image:VIPLevel_18",
--	[19] = "set:CommonFrame19 image:VIPLevel_19",
--	[20] = "set:CommonFrame19 image:VIPLevel_20",
}

local g_BnPos = {}

local g_VipText = {
	[1] = "#{VIPTQ3_120517_49}" ,
	[2] = "#{VIPTQ3_120517_50}",
	[3] = "#{VIPTQ3_120517_51}",
	[4] = "#{VIPTQ3_120517_52}",
	[5] = "#{VIPTQ3_120517_53}",
	[6] = "#{VIPTQ3_120517_54}",
	[7] = "#{VIPTQ3_120517_55}",
	[8] = "#{VIPTQ3_120517_56}",
	[9] = "#{VIPTQ3_120517_57}",


}

local g_nContentButton = {} --2015 VIP随身移功能 By YuanPeiLong
local g_VIP_Shop_XuanLingItemBar = nil

function VIP_Shop_PreLoad()
	this:RegisterEvent("OPEN_VIP_SHOP")			--打开界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OPEN_VIP_NEXTLEVEL")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
	this:RegisterEvent("FRESH_VIP_SHOP")
	this:RegisterEvent("UNIT_LEVEL");				-- 升级   
	this:RegisterEvent("UPDATE_VIP_INFO");				--     
	this:RegisterEvent("UPDATE_DOUBLE_EXP",false)
end

function VIP_Shop_OnLoad()
	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置VIP图标资源为唯美版对应的资源
		g_VIP_Image = {
		[0] = "set:WM_Button2 image:VIP0",
		[1] = "set:WM_Button2 image:VIP1",
		[2] = "set:WM_Button2 image:VIP2",
		[3] = "set:WM_Button2 image:VIP3",
		[4] = "set:WM_Button2 image:VIP4",
		[5] = "set:WM_Button2 image:VIP5",
		[6] = "set:WM_Button2 image:VIP6",
		[7] = "set:WM_Button2 image:VIP7",
		[8] = "set:WM_Button2 image:VIP8",
		[9] = "set:WM_Button2 image:VIP9",
		}
	end

	g_VIP_Shop_Frame_UnifiedPosition = VIP_Shop_Frame:GetProperty("UnifiedPosition")

	g_VIP_ShopList[1] = VIP_Shop_Button01
	g_VIP_ShopList[2] = VIP_Shop_Button02
	g_VIP_ShopList[3] = VIP_Shop_Button03
	g_VIP_ShopList[4] = VIP_Shop_Button04
	g_VIP_ShopList[5] = VIP_Shop_Button05
	g_VIP_ShopList[6] = VIP_Shop_Button06
	g_VIP_ShopList[7] = VIP_Shop_ButtonOnlineGM
	g_VIP_ShopList[8] = VIP_Shop_ButtonZhuanshuGM --test by yuanpeilong

	for i = 1, table.getn(g_VIP_ShopList) do
		g_VIP_ShopList[i]:SetCheck(0)
	end

	g_VIP_ShopBKWindow[1] = VIP_Shop_BK1
	g_VIP_ShopBKWindow[2] = VIP_Shop_BK2
	g_VIP_ShopBKWindow[3] = VIP_Shop_BK3
	g_VIP_ShopBKWindow[4] = VIP_Shop_BK4
	g_VIP_ShopBKWindow[5] = VIP_Shop_BK5
	g_VIP_ShopBKWindow[6] = VIP_Shop_BK6
	g_VIP_ShopBKWindow[7] = VIP_Shop_BK7
	g_VIP_ShopBKWindow[8] = VIP_Shop_BK8
	g_VIP_ShopBKWindow[9] = VIP_Shop_BK9
	g_VIP_ShopBKWindow[10] = VIP_Shop_BK10
	g_VIP_ShopBKWindow[11] = VIP_Shop_BK11 --2015 VIP随身移功能 By YuanPeiLong

	g_VIP_ShopBKIcon[1] = VIP_Shop_BK1_Back
	g_VIP_ShopBKIcon[2] = VIP_Shop_BK2_Back
	g_VIP_ShopBKIcon[3] = VIP_Shop_BK3_Back
	g_VIP_ShopBKIcon[4] = VIP_Shop_BK4_Back
	g_VIP_ShopBKIcon[5] = VIP_Shop_BK5_Back
	g_VIP_ShopBKIcon[6] = VIP_Shop_BK6_Back
	g_VIP_ShopBKIcon[7] = VIP_Shop_BK7_Back
	g_VIP_ShopBKIcon[8] = VIP_Shop_BK8_Back
	g_VIP_ShopBKIcon[9] = VIP_Shop_BK9_Back
	g_VIP_ShopBKIcon[10] = VIP_Shop_BK10_Back
	g_VIP_ShopBKIcon[11] = VIP_Shop_BK11_Back --2015 VIP随身移功能 By YuanPeiLong

	g_VIP_ShopBKList[1] = VIP_Shop_BK1_Button
	g_VIP_ShopBKList[2] = VIP_Shop_BK2_Button
	g_VIP_ShopBKList[3] = VIP_Shop_BK3_Button
	g_VIP_ShopBKList[4] = VIP_Shop_BK4_Button
	g_VIP_ShopBKList[5] = VIP_Shop_BK5_Button
	g_VIP_ShopBKList[6] = VIP_Shop_BK6_Button
	g_VIP_ShopBKList[7] = VIP_Shop_BK7_Button
	g_VIP_ShopBKList[8] = VIP_Shop_BK8_Button
	g_VIP_ShopBKList[9] = VIP_Shop_BK9_Button
	g_VIP_ShopBKList[10] = VIP_Shop_BK10_Button
	g_VIP_ShopBKList[11] = VIP_Shop_BK11_Button --2015 VIP随身移功能 By YuanPeiLong

	g_BnPos[1] = g_VIP_ShopList[1]:GetProperty("UnifiedPosition")
	g_BnPos[2] = g_VIP_ShopList[2]:GetProperty("UnifiedPosition")
	g_BnPos[3] = g_VIP_ShopList[3]:GetProperty("UnifiedPosition")
	g_BnPos[4] = g_VIP_ShopList[4]:GetProperty("UnifiedPosition")
	g_BnPos[5] = g_VIP_ShopList[5]:GetProperty("UnifiedPosition")
	g_BnPos[6] = g_VIP_ShopList[6]:GetProperty("UnifiedPosition")
	g_BnPos[7] = g_VIP_ShopList[8]:GetProperty("UnifiedPosition") --test by yuanpeilong
	
	g_RPIU[1] = VIP_Shop_BK1_Buttontips
	g_RPIU[2] = VIP_Shop_BK2_Buttontips
	g_RPIU[3] = VIP_Shop_BK3_Buttontips
	g_RPIU[4] = VIP_Shop_BK4_Buttontips
	g_RPIU[5] = VIP_Shop_BK5_Buttontips
	g_RPIU[6] = VIP_Shop_BK6_Buttontips
	g_RPIU[7] = VIP_Shop_BK7_Buttontips
	g_RPIU[8] = VIP_Shop_BK8_Buttontips
	g_RPIU[9] = VIP_Shop_BK9_Buttontips
	g_RPIU[10] = VIP_Shop_BK10_Buttontips
	g_RPIU[11] = VIP_Shop_BK11_Buttontips
	g_RPIU[12] = VIP_Shop_ButtonZhuanshuGM_tips --test by yuanpeilong
end

function VIP_Shop_OnEvent(event)
	if (event == "OPEN_VIP_SHOP") then
		--if (KVKInterface:IsInKVKServer() == 1) then
		--	return
		--end
		if ( IsWindowShow( "VIP_Shop" ) == true ) then
			this:Hide();
			return
		end
		
		g_VIP_Shop_Check = nil;
		
		--打开界面的时候，去获取玩具是否可以领取江湖义士锦囊
		local today = DataPool : GetServerDayTime()
		if today >= g_VIP_Start and today <= g_VIP_End then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("CheckIsInPrizeList")
				Set_XSCRIPT_ScriptID(889644)
				Set_XSCRIPT_ParamCount(0)
		  Send_XSCRIPT()
		end

		if tonumber(arg0) >= 1 then	--这个参数是VIP的等级
			local nChkIdx = tonumber(arg1);
			if nChkIdx == nil then
				nChkIdx = 1;
			end
			VIP_Shop_Init()
			g_VIP_ShopList[nChkIdx]:SetCheck(1)
			this:Show()
			VIP_Shop_UpdateBnPos()
			VIP_Shop_UpdateShop(nChkIdx)

			if IsWindowShow("Bank") then
				CloseWindow("Bank", true)
			end
			if IsWindowShow("Shop") then
				CloseWindow("Shop", true)
			end
			if IsWindowShow("DressBoxFrame") then
				CloseWindow("DressBoxFrame", true)
			end
			if IsWindowShow("BieYeBank") then
				CloseWindow("BieYeBank", true)
			end
			if IsWindowShow("DuanWu_JiFenShop") then
				CloseWindow("DuanWu_JiFenShop", true)
			end
			if IsWindowShow("BieYeFurnitureBank") then
				PushEvent( "BIEYE_OPEN_MINI" );
			end
		end
		
	elseif ( event == "FRESH_VIP_SHOP" ) then
		local nLastCheck = tonumber(arg0);
		if g_VIP_ShopList[nLastCheck] ~= nil then
			--VIP_Shop_UpdateShop(nLastCheck)
			g_VIP_ShopList[nLastCheck]:SetCheck(1)
		end

	elseif ( event == "OPEN_VIP_NEXTLEVEL" ) then
		if ( IsWindowShow( "VIP_Shop" ) == true ) then
			this:Hide();
			return
		end

		VIP_Shop_Init()

		for i=1, table.getn(g_VIP_ShopList) do --test by yuanpeilong for i = 1, 7 do
			g_VIP_ShopList[ i ] : Hide();
		end
		
		g_VIP_ShopList[ 1 ] : Show();
		g_VIP_ShopList[ 1 ] : SetCheck( 1 );
		
		g_VIP_ShopList[ 5 ] : Show();
		g_VIP_ShopList[ 5 ] : SetProperty( "UnifiedPosition",g_BnPos[ 2 ] );
		this:Show();
		VIP_Shop_UpdateShop( 1 );

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		VIP_Shop_Frame_On_ResetPos()

	elseif (event == "ADJEST_UI_POS") then
		VIP_Shop_Frame_On_ResetPos()

	elseif ( event == "UI_COMMAND" ) then
		local nRet = tonumber( arg0 )
		if nRet == 20131231 and Get_XParam_INT(0) == 0 then
			this:Hide();
		end

		if nRet == 89105702 then
			this:Hide();
			return
		end
		
		if nRet == 810208171 then
			this:Hide();
			return
		end
		
		if nRet == 20170706 then
			if Get_XParam_INT(0) == 0 then 
				g_2017_vip_show = 0
			else
				g_2017_vip_show = 1
			end
			
		end
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		if this:IsVisible() then
			if VIP_Shop_Button02:GetCheck() == 1 then
				VIP_Shop_UpdateRedPointInUI(2)
			else
				VIP_Shop_UpdateRedPointInUI(-1)
			end
		end
	elseif event == "UNIT_LEVEL" then
		local nLevel = Player:GetLevel();
		if nLevel >= 15 then
			Lua_ShowQuickEnter(2,1)
		end
	elseif event == "UPDATE_VIP_INFO" then
		local nAccVipLevel = DataPool:GetAccVipLevel();
		if nAccVipLevel >= 1 then
			Lua_ShowQuickEnter(2,1)
		end
	elseif event == "UPDATE_DOUBLE_EXP" and this:IsVisible() then
		if g_VIP_ShopToolTips[23] ~= nil and g_VIP_Shop_XuanLingItemBar ~= nil then
			local sSubTitle = g_VIP_ShopToolTips[23]
			local nXuanLingLockTime = SystemSetup : GetDoubleExp("xuanlinglocktime");
			nXuanLingLockTime = math.floor( nXuanLingLockTime / 60 );
			if nXuanLingLockTime > 0 then
				sSubTitle = sSubTitle..ScriptGlobal_Format("#{TLZL_260409_01}", nXuanLingLockTime)
			end
			g_VIP_Shop_XuanLingItemBar:SetToolTip(sSubTitle)
		end
	end
end

--界面初始化
function VIP_Shop_Init()
	local str = ScriptGlobal_Format("#{VIPTQ_110908_09}", tostring(DataPool:GetAccVipLevel()))
	VIP_Shop_Text:SetText(str.."#{VIPTQ3_120517_02}")

	for i = 1, table.getn(g_VIP_ShopBKIcon) do
		g_VIP_ShopBKIcon[i]:SetProperty("Image", "")
		g_VIP_ShopBKIcon[i]:Hide()
	end
	for i = 1, table.getn(g_VIP_ShopBKList) do
		g_VIP_ShopBKList[i]:SetText("")
		g_VIP_ShopBKList[i]:Disable()
		g_VIP_ShopBKList[i]:Hide()
	end
	for i = 1, table.getn(g_VIP_ShopBKWindow) do
		g_VIP_ShopBKWindow[i]:Hide()
	end
	for i = 1, table.getn(g_RPIU) do
		g_RPIU[i]:Hide()
	end
	
	VIP_Shop_Client4:Hide()

	VIP_Shop_Text1:Hide()
	VIP_Shop_Lace1:Hide()
	VIP_Shop_ClientGM:Hide()
	VIP_Shop_VIP_Nextleveldis:Hide()
	VIP_Shop_VIP_Nextlevel:Hide()
	VIP_Shop_ZhuanshuGM_Text2:Hide() --test by yuanpeilong
	VIP_Shop_ZhuanshuGM:Hide() --test by yuanpeilong
end

--2015 VIP随身移功能 By YuanPeiLong
function VIP_Shop_YPL_Init()
	--TLBB_VIPShopYPL_Button:Enable()
	TLBB_VIPShopYPL_Button:CleanAllElement("VIP_Shop")
	TLBB_VIPShopYPL_Button:Show()
	VIP_Shop_AddItem()
	
	TLBB_VIPShopYPL_Button:Flash()

	TLBB_VIPShopYPL_Button:SetElementsInView(1)		
	
	--VIP_Shop_AddOneItem()
	--VIP_Shop_YPLButtonShow()
end

--左边栏按钮响应逻辑
function VIP_Shop_UpdateShop(num)
	if num < 1 or num > g_VIP_ShopNum then
		return
	end
		
	local nLastCheck = g_VIP_Shop_Check;
	g_VIP_Shop_Check = num;

	local strTemp = ""
	local strid = ""
	if num == 1 then	--快捷功能使用
		VIP_Shop_Init()
		TLBB_VIPShopYPL_Button:Hide()--2015 VIP随身移功能 By YuanPeiLong
		
		local idx = 1
		for i = 1, g_VIP_ShopMaxNum do
			local funcId, funcType = DataPool:GetVipInfoByIdx(i-1)

			if funcType and funcType == 1 and funcId and g_VIP_ShopInfo[funcId] and g_VIP_ShopInfo[funcId].type == 1 then

				g_VIP_ShopBKId[idx] = funcId

				idx = idx + 1
			end
		end

		VIP_Shop_YPL_Init()--2015 VIP随身移功能 By YuanPeiLong
		
		VIP_Shop_UpdateRedPointInUI(num)

	elseif num == 2 then	--道具奖励领取
	
		-- 账号vip有值, 角色vip不能激活
		local nVipLevel = DataPool:GetVipLevel();
		if ( nVipLevel == -1 ) then
			-- 打开vip激活界面
			PushEvent( "OPEN_VIP_SHOP", -1 );
			return
		end
		if ( nVipLevel < 1 ) then
			PushDebugMessage("#{VIPTQ_160630_1}");
			PushDebugMessage("#{VIPTQ_160630_2}");
			if nLastCheck ~= nil then
				g_VIP_Shop_Check = nLastCheck;
				PushEvent( "FRESH_VIP_SHOP", nLastCheck );
			end
			return
		end
		
		VIP_Shop_Init()
		TLBB_VIPShopYPL_Button:Hide()--2015 VIP随身移功能 By YuanPeiLong
		
		local idx = 1
		--vip领奖功能设计-2014-YPL:start
		local today = DataPool : GetServerDayTime()
		local Show_VipPrize2015 = -1
		if today >= g_VIP_Start and today <= g_VIP_End then
			for i=1, table.getn(g_2014_vip_List) do
				local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
				if selfZoneWorldID == g_2014_vip_List[i] then
					Show_VipPrize2015 = 1
					break
				end
			end
			if g_2017_vip_show == 0 then
				Show_VipPrize2015 = 0
			end
		end

		local Show_NianDiHuiKui2015 = -1;
		if ( today >= g_VIP_StartDay and today <= g_VIP_EndDay ) then
			Show_NianDiHuiKui2015 = 1;
		end

		local Show_NianDiHuiKui2015_M = -1;
		if ( today >= g_VIP_StartDay_M and today <= g_VIP_EndDay_M ) then
			Show_NianDiHuiKui2015_M = 1;
		end

		--vip领奖功能设计-2014-YPL:end			
		for i = 1, g_VIP_ShopMaxNum do
			local funcId, funcType = DataPool:GetVipInfoByIdx(i-1)		
			if funcType and (funcType == 2 or funcType == 3) then
				--vip领奖功能设计-2014-YPL:start
				if funcId == 19 then
					if Show_VipPrize2015 == 1 then
						g_VIP_ShopBKIcon[idx]:SetProperty("Image", g_VIP_ShopImageList[funcId])
						g_VIP_ShopBKIcon[idx]:Show()
						g_VIP_ShopBKList[idx]:SetText(DataPool:GetVipFuncName(funcId))
						g_VIP_ShopBKList[idx]:SetToolTip(g_VIP_ShopToolTips[funcId])
						g_VIP_ShopBKList[idx]:Enable()
						g_VIP_ShopBKList[idx]:Show()
						g_VIP_ShopBKId[idx] = funcId
						g_VIP_ShopBKWindow[idx]:Show()
						idx = idx + 1
					end
				elseif ( funcId == 17 ) then
					if ( Show_NianDiHuiKui2015 == 1 ) then
						g_VIP_ShopBKIcon[idx]:SetProperty("Image", g_VIP_ShopImageList[funcId])
						g_VIP_ShopBKIcon[idx]:Show()
						g_VIP_ShopBKList[idx]:SetText(DataPool:GetVipFuncName(funcId))
						g_VIP_ShopBKList[idx]:SetToolTip(g_VIP_ShopToolTips[funcId])
						g_VIP_ShopBKList[idx]:Enable()
						g_VIP_ShopBKList[idx]:Show()
						g_VIP_ShopBKId[idx] = funcId
						g_VIP_ShopBKWindow[idx]:Show()
						idx = idx + 1
					end
				elseif ( funcId == 22 ) then
					if ( Show_NianDiHuiKui2015_M == 1 ) then
						g_VIP_ShopBKIcon[idx]:SetProperty("Image", g_VIP_ShopImageList[funcId])
						g_VIP_ShopBKIcon[idx]:Show()
						g_VIP_ShopBKList[idx]:SetText(DataPool:GetVipFuncName(funcId))
						g_VIP_ShopBKList[idx]:SetToolTip(g_VIP_ShopToolTips[funcId])
						g_VIP_ShopBKList[idx]:Enable()
						g_VIP_ShopBKList[idx]:Show()
						g_VIP_ShopBKId[idx] = funcId
						g_VIP_ShopBKWindow[idx]:Show()
						idx = idx + 1
					end
				else
					g_VIP_ShopBKIcon[idx]:SetProperty("Image", g_VIP_ShopImageList[funcId])
					g_VIP_ShopBKIcon[idx]:Show()
					g_VIP_ShopBKList[idx]:SetText(DataPool:GetVipFuncName(funcId))
					g_VIP_ShopBKList[idx]:SetToolTip(g_VIP_ShopToolTips[funcId])
					g_VIP_ShopBKList[idx]:Enable()
					g_VIP_ShopBKList[idx]:Show()
					g_VIP_ShopBKId[idx] = funcId
					g_VIP_ShopBKWindow[idx]:Show()
					idx = idx + 1
				end
				--vip领奖功能设计-2014-YPL:end
			end
		end
		VIP_Shop_Client4:Show()
		VIP_Shop_UpdateRedPointInUI(num)
		
	elseif num == 3 then    --游戏功能特权
		VIP_Shop_Init()
		TLBB_VIPShopYPL_Button:Hide()--2015 VIP随身移功能 By YuanPeiLong
		VIP_Shop_Text1:ClearAllElement()
		local strTemp = "#{VIPTQ3_120517_04}"
		for i = 1, g_VIP_ShopMaxNum do
			local funcId, funcType, funcMaxUseTimes, funcUsedTimes = DataPool:GetVipInfoByIdx(i-1)
			if funcId and funcId == 15 then   --珍兽繁殖
				strTemp = strTemp.."#r#{VIPTQ3_120517_05}"
				break
			end
		end

		for i = 1, g_VIP_ShopMaxNum do
			local funcId, funcType, funcMaxUseTimes, funcUsedTimes = DataPool:GetVipInfoByIdx(i-1)
			if funcId and funcId == 14 then   --珍兽繁殖
				local str = ScriptGlobal_Format("#{VIPTQ3_120517_06}", tostring(funcMaxUseTimes),tostring(funcMaxUseTimes))
				strTemp = strTemp.."#r"..str
				break
			end
		end
		
		--金币上限
		strTemp = strTemp.."#r#r#{JBSX_20220126_01}#r    #{JBSX_20220126_02}#r    #{JBSX_20220126_03}"

		VIP_Shop_Text1:AddTextElement(strTemp)	
		VIP_Shop_Text1:Show()
		VIP_Shop_Lace1:Show()
		VIP_Shop_UpdateRedPointInUI(num)
	elseif num == 4 then	--查询特权情况
		VIP_Shop_Init()
		TLBB_VIPShopYPL_Button:Hide()--2015 VIP随身移功能 By YuanPeiLong
		local str = "#{VIPTQ_110908_51}"
		local strTemp1 = "#r#{VIPTQ_120221_36}"
		local strTemp2 = "#r#{VIPTQ_120221_37}"
		local strTemp3 = ""		--快捷功能：限次和不限次的分开显示
		local strTemp4 = "#r#{VIPTQ3_120517_22}"
		local strTemp5 = ""
		local type1 = 0
		local type2 = 0
		local type3 = 0
		local nVipLevel = DataPool:GetVipLevel();
 		for i = 1, g_VIP_ShopMaxNum do
			local funcId, funcType, funcMaxUseTimes, funcUsedTimes = DataPool:GetVipInfoByIdx(i-1)
			if funcId and funcId >= 1 then
				local strTemp = "#r"
				if funcUsedTimes >=  funcMaxUseTimes then
					funcUsedTimes = funcMaxUseTimes;
					if funcMaxUseTimes < 0 then
						strTemp = strTemp..g_VIP_ShopInfo[funcId][1]
					else
						strTemp = strTemp..g_VIP_ShopInfo[funcId][2]
						if g_VIP_ShopInfo[funcId].flag == 1 then
							strTemp = strTemp..(funcMaxUseTimes-funcUsedTimes).."/"..funcMaxUseTimes
						end
					end
				else
					--炫装特写
					if funcId == 4 and funcUsedTimes >= 1 then
						strTemp = strTemp.."#{VIPTQ_110908_89}".."（"..funcUsedTimes.."/"..funcMaxUseTimes.."）"
					else
						strTemp = strTemp..g_VIP_ShopInfo[funcId][0]
						if g_VIP_ShopInfo[funcId].flag == 1 then
							if funcUsedTimes > funcMaxUseTimes then
								funcUsedTimes = funcMaxUseTimes;
							end
							strTemp = strTemp..(funcMaxUseTimes-funcUsedTimes).."/"..funcMaxUseTimes
						end
					end
				end

				if g_VIP_ShopInfo[funcId].type == 1 then
					if g_VIP_ShopInfo[funcId].flag == 1 then
						if  funcMaxUseTimes < 0 then
							strTemp3 = strTemp3..strTemp
						else
							strTemp1 = strTemp1..strTemp
						end
					else
						strTemp3 = strTemp3..strTemp
					end
					type1 = type1 + 1
				elseif g_VIP_ShopInfo[funcId].type == 2 then
					if nVipLevel == -1 then	--未激活
						strTemp2 = strTemp2.."#r"..g_VIP_ShopInfo[funcId][4];
					else
						strTemp2 = strTemp2..strTemp
					end
					type2 = type2 + 1
				elseif g_VIP_ShopInfo[funcId].type == 3 then
					if g_VIP_ShopInfo[funcId].flag == 1 then
						if  funcMaxUseTimes < 0 then
							strTemp5 = strTemp5..strTemp
						else
							strTemp4 = strTemp4..strTemp
						end
					else
						strTemp5 = strTemp5..strTemp
					end
					type3 = type3 + 1
				end
			end
		end

		if type1 > 0 then
			str = str.."#r"..strTemp1..strTemp3
		end

		if type2 > 0 then
			str = str.."#r"..strTemp2
		end

		if type3 > 0 then
			str = str.."#r"..strTemp4..strTemp5
		end
		
		--金币上限
		local nAccLevel = DataPool:GetAccVipLevel();
		if nAccLevel >= 4 then
			local result, money = Player:GetLevelMoneyLimit();
			if result and money then
				local szMaxMoney = ScriptGlobal_Format("#{JBSX_20220126_04}", tostring(money))
				str = str.."#r"..szMaxMoney
			end
		end

		--test by yuanpeilong
		if nAccLevel == 9  then
			str = str.."#r".."#r".."#{VIPTQ_150511_5}"
		end
		
		VIP_Shop_Text1:ClearAllElement()
		VIP_Shop_Text1:AddTextElement(str)
		VIP_Shop_Text1:Show()
		VIP_Shop_Lace1:Show()
		VIP_Shop_UpdateRedPointInUI(num)

	elseif num == 5 then  --下级特权
		VIP_Shop_Init()
		TLBB_VIPShopYPL_Button:Hide()--2015 VIP随身移功能 By YuanPeiLong
		VIP_Shop_VIP_Nextlevel_Text:ClearAllElement()
		local nCost, nNeedCost= DataPool:GetVipAccProgress()
		local nAccLevel = DataPool:GetAccVipLevel();
		if nAccLevel < 0 or nAccLevel >= g_Max_Vip_Level  then
			return
		end
		if nNeedCost > 0 then
			VIP_Shop_Textdis_EXP:SetProgress(tonumber(nCost) , nNeedCost)
		else
			VIP_Shop_Textdis_EXP:SetProgress(100,100)
		end
		local strHead = ScriptGlobal_Format("#{VIPTQ3_120517_16}", tostring(nAccLevel + 1))

		-- vip等级0级, 不显示这个按钮
		if ( nAccLevel == 0 or nAccLevel >= g_Max_Vip_Level ) then
			VIP_Shop_LianJieButton1 : Hide();
		else
			VIP_Shop_LianJieButton1 : Show();
		end

		local strTemp = ""
		local strTemp1 = "#r#r#{VIPTQ3_120517_17}"  	--快捷功能
		local strTemp2 = "#r#r#{VIPTQ3_120517_18}"		--道具领取
		local strTemp3 = "#r#r#{VIPTQ3_120517_22}"	--游戏功能特权
		local strTemp1_1 = ""
		local strTemp2_1 = ""
		local strTemp3_1 = ""

		for i = 1, table.getn(g_VIP_ShopInfo) do
			local funcType, funcMaxUseTimes = DataPool:GetvipInfoByVipID(nAccLevel+1 , i)
			if funcType and funcMaxUseTimes and i ~= 19 then
				if i == 3 then	--表情
					if funcMaxUseTimes > 0 then
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], tostring(funcMaxUseTimes),"30")
					else
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], "无限" , "30")
					end
				elseif i == 4 then  --炫装
					if funcMaxUseTimes > 0 then
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], tostring(funcMaxUseTimes),"15")
					else
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], "无限" , "15")
					end
				elseif i == 6 then   --瞬影符箓
					if funcMaxUseTimes > 0 then
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], tostring(funcMaxUseTimes),g_itemtimes[nAccLevel+1])
					else
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], "无限" , g_itemtimes[nAccLevel+1])
					end
				elseif i == 12 then  --动作包
					if funcMaxUseTimes > 0 then
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], tostring(funcMaxUseTimes),g_VipPrizeTwelve[nAccLevel+1])
					else
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], "无限" , g_VipPrizeTwelve[nAccLevel+1])
					end
				elseif i == 15 then   --单人珍兽繁殖
					strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], "30")
				--2015 VIP随身移功能 By YuanPeiLong : start
				elseif i == 21 then
					strTemp = "#{VIPZY_141216_14}"
				--2015 VIP随身移功能 By YuanPeiLong : end					
				elseif i == 23 then
					strTemp = nil		--策划说这个功能不显示
				else
					if funcMaxUseTimes > 0 then
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], tostring(funcMaxUseTimes))
					else
						strTemp = ScriptGlobal_Format(g_VIP_ShopInfo[i][3], "无限")
					end
				end

				if strTemp ~= nil then
					if g_VIP_ShopInfo[i].type == 1 then
						strTemp1_1 = strTemp1_1.."#r"..strTemp
					elseif g_VIP_ShopInfo[i].type == 2 then
						strTemp2_1 = strTemp2_1.."#r"..strTemp
					elseif g_VIP_ShopInfo[i].type == 3 then
						strTemp3_1 = strTemp3_1.."#r"..strTemp
					end
				end
			end
		end

		if strTemp1_1 == "" then
			strTemp1 = ""
		else
			strTemp1 = strTemp1..strTemp1_1
		end
		if strTemp2_1 == "" then
			strTemp2 = ""
		else
			strTemp2 = strTemp2..strTemp2_1
		end
		if strTemp3_1 == "" then
			strTemp3 = ""
		else
			strTemp3 = strTemp3..strTemp3_1
		end
		
		local str = strHead..strTemp1..strTemp2..strTemp3
		
		--金币上限
		if nAccLevel >= 3 then
			local nMaxMoney = Player:GetLevelMoneyLimitByVip( nAccLevel + 1);
			if nMaxMoney and nMaxMoney > 0 then
				local szMaxMoney = ScriptGlobal_Format("#{JBSX_20220126_05}", tostring(nMaxMoney))
				str = str.."#r"..szMaxMoney
			end
		end
		
		--test by yuanpeilong
		if nAccLevel == 8 then
			str = str.."#r".."#r".."#{VIPTQ_150511_6}"
		end	
		local leveltips = ScriptGlobal_Format("#{VIPTQ3_120517_13}", tostring(nAccLevel))
		local nextleveltips = ScriptGlobal_Format("#{VIPTQ3_120517_14}", tostring(nNeedCost - nCost) , tostring(nAccLevel+1))
		VIP_Shop_Textdis_VIP1:SetProperty("Image" , g_VIP_Image[nAccLevel])
		VIP_Shop_Textdis_VIP2:SetProperty("Image" , g_VIP_Image[nAccLevel+1])
		VIP_Shop_Textdis_VIP1:SetToolTip(leveltips)
		VIP_Shop_Textdis_VIP2:SetToolTip(nextleveltips)
		VIP_Shop_Textdis_EXP:SetToolTip(nextleveltips)
		VIP_Shop_VIP_Nextlevel_Text:AddTextElement(str)
		VIP_Shop_VIP_Nextleveldis:Show()
		VIP_Shop_VIP_Nextlevel:Show()
		
		VIP_Shop_UpdateRedPointInUI(num)

	elseif num == 6 then	--关于VIP特权
		VIP_Shop_Init()
		TLBB_VIPShopYPL_Button:Hide()--2015 VIP随身移功能 By YuanPeiLong
		VIP_Shop_Text1:ClearAllElement()
		local nAccLevel = DataPool:GetAccVipLevel()
		if g_VipText[nAccLevel] then
			if nAccLevel >= 4 then
				local nVip0Money = Player:GetLevelMoneyLimitByVip( 0 );
				local nCurVipMoney = Player:GetLevelMoneyLimitByVip( nAccLevel );
				if nVip0Money == nil then
					nVip0Money = 0;
				end
				if nCurVipMoney == nil then
					nCurVipMoney = 0;
				end
			
				local szVipText = ScriptGlobal_Format(g_VipText[nAccLevel], tostring(nVip0Money), tostring(nCurVipMoney) )
				VIP_Shop_Text1:AddTextElement(szVipText)
				
			else
				VIP_Shop_Text1:AddTextElement( g_VipText[nAccLevel] )
			end
		end

		VIP_Shop_Text1:Show()
		VIP_Shop_Lace1:Show()
		VIP_Shop_UpdateRedPointInUI(num)
		
	elseif num == 7 then	--在线联系GM
		VIP_Shop_Init()
		TLBB_VIPShopYPL_Button:Hide()--2015 VIP随身移功能 By YuanPeiLong
		local nAccLevel = DataPool:GetAccVipLevel()
		if nAccLevel < g_Max_Vip_Level then
			return
		end
		VIP_Shop_UpdateRedPointInUI(num)
	--test by yuanpeilong : start
	elseif num == 8 then
		VIP_Shop_Init()
		TLBB_VIPShopYPL_Button:Hide()--2015 VIP随身移功能 By YuanPeiLong
		
		VIP_Shop_ButtonZhuanshuGM_tips:Hide()
		VIP_Shop_ZhuanshuGM_Text2:ClearAllElement()
		VIP_Shop_ZhuanshuGM_Text2:AddTextElement("#{VIPTQ_150511_4}")		
		VIP_Shop_ZhuanshuGM_Text2:Show()
		VIP_Shop_ZhuanshuGM:Show()		
		this:Show();

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("VIPZhuanShuGM")
			Set_XSCRIPT_ScriptID(889644)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	--test by yuanpeilong : end	
	end
	
	VIP_Shop_UpdateRedPointInUI(num)
	
end

--功能按钮响应逻辑
function VIP_Shop_Button_Clicked(num)
	--vip领奖功能设计-2014-YPL:start
	local today = DataPool : GetServerDayTime()

	local Show_VipPrize2015 = -1
	if today >= g_VIP_Start and today <= g_VIP_End then
			Show_VipPrize2015 = 1
	end			

	if Show_VipPrize2015 == -1 and g_VIP_ShopBKId[num] == 19 then
		PushDebugMessage("#{VLQJL_140910_7}")
		this:Hide()
		return
	end
	--vip领奖功能设计-2014-YPL:end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUseVIP")
		Set_XSCRIPT_ScriptID(889644)
		Set_XSCRIPT_Parameter(0, g_VIP_ShopBKId[num])
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function VIP_Shop_Close()
	this:Hide()
end

function VIP_Shop_Frame_On_ResetPos()
	VIP_Shop_Frame:SetProperty("UnifiedPosition", g_VIP_Shop_Frame_UnifiedPosition)
end

function VIP_Shop_ConnectGM()

	local nAccLevel = DataPool:GetAccVipLevel()
	if nAccLevel < g_Max_Vip_Level then
		PushDebugMessage("#{GMGJTX_111128_02}")
		return
	end

	if GMConnectInfo_IsShow() == 1 then
		if GMConnectInfo_IsConnected() == 0 then
			PushDebugMessage("#{GMGJTX_111128_03}")
		else
			PushDebugMessage("#{GMGJTX_111128_04}")
		end

		return
	elseif  GMChat_IsShow() == 1 then
		if GMChat_IsConnected() == 0 then
			PushDebugMessage("#{GMGJTX_111128_03}")
		else
			PushDebugMessage("#{GMGJTX_111128_04}")
		end

		return
	end

--	DataPool:GMChat_OpenConnect()
end

function VIP_Shop_NextLevelInfo()
	VIP_Shop_Init()
	VIP_Shop_UpdateShop(5)
	g_VIP_ShopList[5]:SetCheck(1)
end

function VIP_Shop_AllVipInfo()
	GameProduceLogin:OpenURL(GetWeblink("WEB_VIPTEQUAN"))
end

function VIP_Shop_UpdateBnPos()
		local isBn2Show = 0;
		local isBn3Show = 0;
		
		local today = DataPool : GetServerDayTime()
		for i = 1, g_VIP_ShopMaxNum do
			local funcId, funcType, funcMaxUseTimes, funcUsedTimes = DataPool:GetVipInfoByIdx(i-1)
			if funcId and g_VIP_ShopInfo[funcId].type == 2 then
				if funcId ~= 17 or (today >= g_VIP_StartDay and today <= g_VIP_EndDay) then 
					isBn2Show = 1
					break
				end
			end
		end
		for i = 1, g_VIP_ShopMaxNum do
			local funcId, funcType, funcMaxUseTimes, funcUsedTimes = DataPool:GetVipInfoByIdx(i-1)
			if funcId and g_VIP_ShopInfo[funcId].type == 3 then
				isBn3Show = 1
				break
			end
		end
		
		local nAccLevel = DataPool:GetAccVipLevel()
		local j = 1
		for i = 1 ,6 do
			if (i == 2 and isBn2Show == 0) or (i == 3 and isBn3Show == 0) or (i == 5 and nAccLevel >= g_Max_Vip_Level) then
				g_VIP_ShopList[i]:Hide()
			else
				g_VIP_ShopList[i]:Show()
				g_VIP_ShopList[i]:SetProperty("UnifiedPosition",g_BnPos[j])
				if i == 6 then
					g_VIP_ShopList[7]:SetProperty("UnifiedPosition",g_BnPos[j])
				end
				j = j + 1
			end
		end

		-- vip等级0级, 不显示这个按钮
		if ( nAccLevel == 0 or nAccLevel >= g_Max_Vip_Level ) then
			VIP_Shop_LianJieButton1 : Hide();
		else
			VIP_Shop_LianJieButton1 : Show();
		end


		g_VIP_ShopList[7]:Hide()
		--test by yuanpeilong
		if nAccLevel == 9 then
			g_VIP_ShopList[ 8 ] : SetProperty( "UnifiedPosition",g_BnPos[ 7 ] );
			g_VIP_ShopList[ 8 ] : Show();
		else
			g_VIP_ShopList[ 8 ] : Hide();			
		end
end

--2015 VIP随身移功能 By YuanPeiLong : start
function VIP_Shop_AddItem()
	-------------------------------------------------------------------------------------
	g_VIP_Shop_XuanLingItemBar = nil;
	local strTemp = ""
	local strid = ""
	local index = 1
	local total = 0
	local bIs2606S = Player:GetData("Is2606S");
		for i = 1, g_VIP_ShopMaxNum do
			local funcId, funcType = DataPool:GetVipInfoByIdx(i-1)
			strTemp = strTemp..":"..tostring(funcType)
			strid = strid..":"..tostring(funcId)
			if funcType and funcType == 1 and funcId and g_VIP_ShopInfo[funcId] and g_VIP_ShopInfo[funcId].type == 1 then
				if bIs2606S == 0 or funcId ~= 23 then
					total = total + 1
				end
			end
		end		
		for i = 1, g_VIP_ShopMaxNum do
			local funcId, funcType = DataPool:GetVipInfoByIdx(i-1)
			strTemp = strTemp..":"..tostring(funcType)
			strid = strid..":"..tostring(funcId)
			if funcType and funcType == 1 and funcId and g_VIP_ShopInfo[funcId] and g_VIP_ShopInfo[funcId].type == 1 then
				local strIcon = g_VIP_ShopImageList[funcId]
				local sTitle = DataPool:GetVipFuncName(funcId)
				local sSubTitle = g_VIP_ShopToolTips[funcId]
				if ( funcId == 23 ) then
					local nXuanLingLockTime = SystemSetup : GetDoubleExp("xuanlinglocktime");
					nXuanLingLockTime = math.floor( nXuanLingLockTime / 60 );
					if nXuanLingLockTime > 0 then
						sSubTitle = sSubTitle..ScriptGlobal_Format("#{TLZL_260409_01}", nXuanLingLockTime)
					end
				end
				if bIs2606S == 0 or funcId ~= 23 then
					VIP_Shop_AddOneItem(funcId, strIcon, sTitle, sSubTitle, index, total)
					index = index + 1
				end
			end
		end
	-------------------------------------------------------------------------------------		
end
function VIP_Shop_AddOneItem(funcId, strIcon, sTitle, sSubTitle, index, total)
	--PushDebugMessage("index="..index)

	-- local ItemBar = TLBB_VIPShopYPL_Button:AddItemElement( "VIPShopYPL", "LEFT", "VIP_Shop","" ,"")
	local ItemBar = nil

	if math.mod(index,2) == 0 then
		ItemBar = TLBB_VIPShopYPL_Button:AddItemElement( "VIPShopYPL", "RIGHT", "VIP_Shop","" ,"")
	else
		if index == total then
			ItemBar = TLBB_VIPShopYPL_Button:AddItemElement( "VIPShopYPL", "LEFT", "VIP_Shop","" ,"")
		else
			ItemBar = TLBB_VIPShopYPL_Button:AddItemElement( "VIPShopYPL", "TWO1", "VIP_Shop","" ,"")
		end
	end
	if ItemBar ~= nil then
		ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
	else
		return
	end	

	--local strIcon = "Set:Gem6_2 Image:Gem6_2_2"
	--local sTitle , sSubTitle = "宝石", "美国"

	if strIcon ~= nil and strIcon ~= "" then
		local sPos,_ = string.find(strIcon," ");
		local IconImageSet = string.sub(strIcon,5,sPos-1);
		local IconIamge = string.sub(strIcon,sPos+7)
		if nil ~= IconImageSet and nil ~= IconIamge then
			ItemBar:AddBarIconImage(IconImageSet,IconIamge)
		end
	end	
	
	--ItemBar:AddBarText(sTitle)
	--ItemBar:SetBarContentText(sSubTitle)
	ItemBar:SetButton1Text(sTitle)
	
	ItemBar:SetToolTip(sSubTitle)
	
	local ret = 1
	
	if ret == 1 then
		ItemBar:SetAchvGetedShow()
	else
		ItemBar:SetAchvGetedHide()
	end
		ItemBar:SetAchvGetHide()
		
	if funcId == 23 then
		g_VIP_Shop_XuanLingItemBar = ItemBar;
	end

	table.insert(g_nContentButton,ItemBar);
end
function VIP_Shop_YPLButtonShow()

	TLBB_VIPShopYPL_Button:Flash()

	TLBB_VIPShopYPL_Button:SetElementsInView(1)	
end
function VIP_Shop_YPLButton_Clicked()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1
	
	VIP_Shop_Button_Clicked(nIndex)
end
--2015 VIP随身移功能 By YuanPeiLong : end

function VIP_Shop_UpdateRedPointInUI(num)
	
	for i = 1, table.getn(g_RPIU) do
		g_RPIU[i]:Hide()
	end
	
	VIP_Shop_Button02tips:Hide()
	VIP_Shop_ButtonZhuanshuGM_tips:Hide();
	
	if num == 2 then
	
		for i = 1 , table.getn(g_VIP_ShopBKId) do
			
			if g_VipFunc_2_RPIU[ g_VIP_ShopBKId [ i ] ] ~= nil then

				if DataPool:Lua_IsRedPointInUIShow( g_VipFunc_2_RPIU[ g_VIP_ShopBKId [ i ] ] ) == 1 then

					g_RPIU[ i ]:Show()
					
				end
			
			end
			
		end
	
	end
	
	if VIP_Shop_Button02:IsVisible() then
	
		for i = 4 , 8 do
		
			if DataPool:Lua_IsRedPointInUIShow( i ) == 1 then
				VIP_Shop_Button02tips:Show()
				break;
			end
		end
		
		if DataPool:GetVipLevel() == -1 then
			VIP_Shop_Button02tips:Show()
		end
		
		if DataPool:Lua_IsRedPointInUIShow( 29 ) == 1 then
			VIP_Shop_Button02tips:Show()
		end 
		
		if DataPool:Lua_IsRedPointInUIShow( 30 ) == 1 then
			VIP_Shop_Button02tips:Show()
		end 
	end
	
	--test by yuanpeilong
	if DataPool:Lua_IsRedPointInUIShow( 9 ) == 1 and DataPool:GetAccVipLevel() == g_Max_Vip_Level then
		VIP_Shop_ButtonZhuanshuGM_tips:Show()
	else
		VIP_Shop_ButtonZhuanshuGM_tips:Hide()
	end

end

--test by yuanpeilong
function VIP_Shop_ZhuanshuGMLianJie_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_VIPTQ_ZSGM"))
end
