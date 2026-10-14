--******************************************************************************
-- 青梅煮酒活动界面 by 李梦月
--******************************************************************************
local g_Qingmeizhujiu_Frame_UnifiedXPosition;
local g_Qingmeizhujiu_Frame_UnifiedYPosition;

local g_Qingmeizhujiu_BeginTime = 20220328
local g_Qingmeizhujiu_EndTime = 20220424
local g_Qingmeizhujiu_LimitLevel = 30


local g_Qingmeizhujiu_ExChangeNeed = 3

local g_Qingmeizhujiu_FubenNum = 0
local g_Qingmeizhujiu_IsFinshExchange = 0
local g_Qingmeizhujiu_nHuaquanCount = 0
local g_Qingmeizhujiu_FanLiData = 0

local g_Qingmeizhujiu_ZhuJiuButton
local g_Qingmeizhujiu_ZhuJiuRedPoint
local g_Qingmeizhujiu_FanLiButton
local g_Qingmeizhujiu_FanLiRedPoint

local g_Qingmeizhujiu_ZhuJiuFrame
local g_Qingmeizhujiu_FanLiFrame

local g_Qingmeizhujiu_Have
local g_Qingmeizhujiu_Need
local g_Qingmeizhujiu_Button
local g_Qingmeizhujiu_Anime

local g_Qingmeizhujiu_nContentButton = {}

local g_Qingmeizhujiu_FanLiInfo = {
	[1] = {
		imageshow = "set:Spring24 image:1",
		caiquanNum=2,
		staticItem = {
			{id=39920181, num=1},
		},

		selectItem = {
			{id=39920162, num=10, bShowPreView=0},
			{id=39920085, num=5, bShowPreView=0},
		},
	},

	[2] = {
		imageshow = "set:Spring24 image:2",
		caiquanNum=6,
		staticItem = {
			{id=39920565, num=2},
		},

		selectItem = {
			{id=39920537, num=5, bShowPreView=0},
			{id=39920538, num=5, bShowPreView=0},
		},
	},

	[3] = {
		imageshow = "set:Spring24 image:3",
		caiquanNum=10,
		staticItem = {
			{id=39920566, num=2, bShowPreView=0},
		},

		selectItem = {
			{id=39921023, num=1, bShowPreView=0},
			{id=39920093, num=1, bShowPreView=0},
		},
	},

	[4] = {
		imageshow = "set:Spring24 image:4",
		caiquanNum=14,
		staticItem = {
			{id=39920977, num=1},
		},

		selectItem = {
			{id=39920999, num=1, bShowPreView=0},
			{id=39920329, num=5, bShowPreView=0},
		},
	},

	[5] = {
		imageshow = "set:Spring24 image:5",
		caiquanNum=18,
		staticItem = {
			{id=39922767, num=2},
		},

		selectItem = {
			{id=39921023, num=2, bShowPreView=0},
			{id=39921415, num=5, bShowPreView=0},
		},
	},

	[6] = {
		imageshow = "set:Spring24 image:6",
		caiquanNum=22,
		staticItem = {
			{id=39921363, num=1},
		},

		selectItem = {
			{id=39921051, num=15, bShowPreView=0},
			{id=39920538, num=15, bShowPreView=0},
		},
	},

	[7] = {
		imageshow = "set:Spring24 image:7",
		caiquanNum=26,
		staticItem = {
			{id=39921362, num=1},
		},

		selectItem = {
			{id=39920093, num=3, bShowPreView=0},
			{id=39921689, num=3, bShowPreView=0},
		},
	},

	[8] = {
		imageshow = "set:Spring24 image:8",
		caiquanNum=30,
		staticItem = {
			{id=39922767, num=5},
		},

		selectItem = {
			{id=39921023, num=3, bShowPreView=0},
			{id=39920329, num=15, bShowPreView=0},
			{id=10101059, num=1, bShowPreView=1},
		},
	},
}


local g_Qingmeizhujiu_FanLiInfo_KaJi = {
	[1] = {
		imageshow = "set:Spring24 image:1",
		caiquanNum=2,
		staticItem = {
			{id=39920181, num=1},
		},

		selectItem = {
			{id=20310131, num=3, bShowPreView=0}, --润魂石·击（1级）*3
			{id=39920085, num=5, bShowPreView=0},
		},
	},

	[2] = {
		imageshow = "set:Spring24 image:2",
		caiquanNum=6,
		staticItem = {
			{id=39920565, num=2},
		},

		selectItem = {
			{id=39920537, num=5, bShowPreView=0},
			{id=39920538, num=5, bShowPreView=0},
		},
	},

	[3] = {
		imageshow = "set:Spring24 image:3",
		caiquanNum=10,
		staticItem = {
			{id=39920566, num=2, bShowPreView=0},
		},

		selectItem = {
			{id=30008034, num=5, bShowPreView=0}, --金刚砂*5
			{id=38000807, num=2, bShowPreView=0}, --典籍注解*2
		},
	},

	[4] = {
		imageshow = "set:Spring24 image:4",
		caiquanNum=14,
		staticItem = {
			{id=39920977, num=1},
		},

		selectItem = {
			{id=39920999, num=1, bShowPreView=0},
			{id=39920329, num=5, bShowPreView=0},
		},
	},

	[5] = {
		imageshow = "set:Spring24 image:5",
		caiquanNum=18,
		staticItem = {
			{id=20310168, num=5}, --金蚕丝*5
		},

		selectItem = {
			{id=30008034, num=10, bShowPreView=0}, --金刚砂*10
			{id=30503188, num=10, bShowPreView=0}, --高级根骨丹*10
		},
	},

	[6] = {
		imageshow = "set:Spring24 image:6",
		caiquanNum=22,
		staticItem = {
			{id=39921363, num=1},
		},

		selectItem = {
			{id=39921051, num=15, bShowPreView=0},
			{id=39920538, num=15, bShowPreView=0},
		},
	},

	[7] = {
		imageshow = "set:Spring24 image:7",
		caiquanNum=26,
		staticItem = {
			{id=39921362, num=1},
		},

		selectItem = {
			{id=20310175, num=12, bShowPreView=0}, --灵兽精魄*12
			{id=30503188, num=20, bShowPreView=0}, --高级根骨丹*20
		},
	},

	[8] = {
		imageshow = "set:Spring24 image:8",
		caiquanNum=30,
		staticItem = {
			{id=20500005, num=1}, --5级精铁*1
		},

		selectItem = {
			{id=30503133, num=10, bShowPreView=0}, --千萃神玉*10
			{id=39920329, num=15, bShowPreView=0},
			{id=10101059, num=1, bShowPreView=1},
		},
	},
}

local g_Qingmeizhujiu_Static_Reward = {
	"Qingmeizhujiu_Reward_BasicItem1",
	--"Qingmeizhujiu_Reward_BasicItem2",
}

local g_Qingmeizhujiu_Select_Reward = {
	"Qingmeizhujiu_Reward_BasicItem3",
	"Qingmeizhujiu_Reward_BasicItem4",
	"Qingmeizhujiu_Reward_BasicItem5",
}

local g_Qingmeizhujiu_RewardMask = {
	[1] = "Qingmeizhujiu_Reward_BasicItem3_Mask",
	[2] = "Qingmeizhujiu_Reward_BasicItem4_Mask",
	[3] = "Qingmeizhujiu_Reward_BasicItem5_Mask",
}

--===============================================
-- OnLoad()
--===============================================
function Qingmeizhujiu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Qingmeizhujiu_OnLoad()
	-- 保存界面的默认相对位置
	g_Qingmeizhujiu_Frame_UnifiedXPosition = Qingmeizhujiu:GetProperty("UnifiedXPosition");
	g_Qingmeizhujiu_Frame_UnifiedYPosition = Qingmeizhujiu:GetProperty("UnifiedYPosition");

	g_Qingmeizhujiu_ZhuJiuButton = Qingmeizhujiu_Buttontab01
	g_Qingmeizhujiu_ZhuJiuRedPoint = Qingmeizhujiu_Buttontab01_Tips
	g_Qingmeizhujiu_FanLiButton = Qingmeizhujiu_Buttontab02
	g_Qingmeizhujiu_FanLiRedPoint = Qingmeizhujiu_Buttontab02_Tips

	g_Qingmeizhujiu_ZhuJiuFrame = Qingmeizhujiu_Frame
	g_Qingmeizhujiu_FanLiFrame = Qingmeizhujiu_Frame2

	--青梅煮酒
	g_Qingmeizhujiu_Have = Qingmeizhujiu_Chaihuo
	g_Qingmeizhujiu_Need = Qingmeizhujiu_Drinking_Info1
	g_Qingmeizhujiu_Button = Qingmeizhujiu_Drinking
	g_Qingmeizhujiu_Anime = Qingmeihuaquan_Drinking_Animate

end


--===============================================
-- OnEvent()
--===============================================

function Qingmeizhujiu_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 89271902) then
		if(IsWindowShow("Qingmeizhujiu")) then
			CloseWindow("Qingmeizhujiu", true)
		end

		local curDay = tonumber(DataPool:GetServerDayTime());
		local nLevel = Player:GetLevel();
		if curDay < g_Qingmeizhujiu_BeginTime or curDay > g_Qingmeizhujiu_EndTime or nLevel < g_Qingmeizhujiu_LimitLevel then
			return
		end

		g_Qingmeizhujiu_FubenNum = Get_XParam_INT(0)
		g_Qingmeizhujiu_IsFinshExchange = Get_XParam_INT(1)
		g_Qingmeizhujiu_nHuaquanCount = Get_XParam_INT(2)
		g_Qingmeizhujiu_FanLiData = Get_XParam_INT(3)

		this:Show()
		Open_Qingmeizhujiu_ZhuJiu( )
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89271903) then
		local curDay = tonumber(DataPool:GetServerDayTime());
		local nLevel = Player:GetLevel();
		if curDay < g_Qingmeizhujiu_BeginTime or curDay > g_Qingmeizhujiu_EndTime or nLevel < g_Qingmeizhujiu_LimitLevel then
			return
		end
		Qingmeizhujiu_CanAutoNPC(Get_XParam_INT(0))
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89271904) then
		--更新数据
		local curDay = tonumber(DataPool:GetServerDayTime());
		local nLevel = Player:GetLevel();
		if curDay < g_Qingmeizhujiu_BeginTime or curDay > g_Qingmeizhujiu_EndTime or nLevel < g_Qingmeizhujiu_LimitLevel then
			return
		end

		g_Qingmeizhujiu_FubenNum = Get_XParam_INT(0)
		g_Qingmeizhujiu_IsFinshExchange = Get_XParam_INT(1)
		g_Qingmeizhujiu_nHuaquanCount = Get_XParam_INT(2)
		g_Qingmeizhujiu_FanLiData = Get_XParam_INT(3)
		local pagIndex = Get_XParam_INT(4)

		if pagIndex == 0 then
			Open_Qingmeizhujiu_ZhuJiu( )
		else
			Open_Qingmeizhujiu_FanLi( )
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Qingmeizhujiu_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Qingmeizhujiu_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Qingmeizhujiu_Close()
	end
end


--===============================================
-- OnHiden
--===============================================
function Qingmeizhujiu_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Qingmeizhujiu_Frame_On_ResetPos()
	Qingmeizhujiu : SetProperty("UnifiedXPosition", g_Qingmeizhujiu_Frame_UnifiedXPosition);
	Qingmeizhujiu : SetProperty("UnifiedYPosition", g_Qingmeizhujiu_Frame_UnifiedYPosition);
end

--===============================================
-- 是否显示返利的小红点
--===============================================
function Qingmeizhujiu_bNeedShowFanLiPoint( )
	local FanLiInfo = nil
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(55) > 0 then
		FanLiInfo = g_Qingmeizhujiu_FanLiInfo_KaJi
	else
		FanLiInfo = g_Qingmeizhujiu_FanLiInfo
	end
	
	local tableLen = table.getn(FanLiInfo)
	for i=1, tableLen do
		local bRet, bGetFanLi = GetBitValueInUINT(g_Qingmeizhujiu_FanLiData, (i-1)*3, 1)
		if bRet >= 1 and bGetFanLi <= 0 and g_Qingmeizhujiu_nHuaquanCount >= FanLiInfo[i].caiquanNum then
			return 1
		end
	end

	return 0
end


function Open_Qingmeizhujiu_ZhuJiu( )
	g_Qingmeizhujiu_ZhuJiuButton:SetCheck(1)
	if g_Qingmeizhujiu_FubenNum >= g_Qingmeizhujiu_ExChangeNeed then
		g_Qingmeizhujiu_ZhuJiuRedPoint:Show()
	else
		g_Qingmeizhujiu_ZhuJiuRedPoint:Hide()
	end
	
	g_Qingmeizhujiu_FanLiButton:SetCheck(0)

	if Qingmeizhujiu_bNeedShowFanLiPoint( ) >= 1 then
		g_Qingmeizhujiu_FanLiRedPoint:Show()
	else
		g_Qingmeizhujiu_FanLiRedPoint:Hide()
	end

	g_Qingmeizhujiu_ZhuJiuFrame:Show()
	g_Qingmeizhujiu_FanLiFrame:Hide()

	--当前拥有柴火数
	local nHave = ScriptGlobal_Format("#{QMZJ_180308_74}", g_Qingmeizhujiu_FubenNum)
	g_Qingmeizhujiu_Have:SetText(nHave)
	--兑换需要柴火数
	g_Qingmeizhujiu_Need:SetText( "#{QMZJ_180308_75}" )
	--tips
	g_Qingmeizhujiu_Button:SetToolTip("#{QMZJ_180308_76}")
	--Anime
	if g_Qingmeizhujiu_IsFinshExchange == 0 then
		g_Qingmeizhujiu_Anime:Play(false)
		g_Qingmeizhujiu_Anime:Hide()
	else
		g_Qingmeizhujiu_Anime:Play(true)
		g_Qingmeizhujiu_Anime:Show()
	end
end


function Open_Qingmeizhujiu_FanLi( )
	g_Qingmeizhujiu_ZhuJiuButton:SetCheck(0)
	if g_Qingmeizhujiu_FubenNum >= g_Qingmeizhujiu_ExChangeNeed then
		g_Qingmeizhujiu_ZhuJiuRedPoint:Show()
	else
		g_Qingmeizhujiu_ZhuJiuRedPoint:Hide()
	end
	
	g_Qingmeizhujiu_FanLiButton:SetCheck(1)

	if Qingmeizhujiu_bNeedShowFanLiPoint( ) >= 1 then
		g_Qingmeizhujiu_FanLiRedPoint:Show()
	else
		g_Qingmeizhujiu_FanLiRedPoint:Hide()
	end

	g_Qingmeizhujiu_ZhuJiuFrame:Hide()
	g_Qingmeizhujiu_FanLiFrame:Show()

	for i = 1, table.getn(g_Qingmeizhujiu_nContentButton) do
		local staticListCount = table.getn(g_Qingmeizhujiu_Static_Reward)
		for btn = 1, staticListCount do
			g_Qingmeizhujiu_nContentButton[i]:GetSubItem(g_Qingmeizhujiu_Static_Reward[btn]):SetActionItem(-1)
		end

		local selectListCount = table.getn(g_Qingmeizhujiu_Select_Reward)
		for btn = 1, selectListCount do
			g_Qingmeizhujiu_nContentButton[i]:GetSubItem(g_Qingmeizhujiu_Select_Reward[btn]):SetActionItem(-1)
		end
	end
	Qingmeizhujiu_UpFrame_RewardList:Clear()

	local FanLiInfo = nil
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(55) > 0 then
		FanLiInfo = g_Qingmeizhujiu_FanLiInfo_KaJi
	else
		FanLiInfo = g_Qingmeizhujiu_FanLiInfo
	end
	
	for i = 1, table.getn(FanLiInfo) do
		local bar = Qingmeizhujiu_UpFrame_RewardList:AddChild("Qingmeizhujiu_UpFrame_RewardContent")
		if nil ~= bar then
			--首列图片
			bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemLevel"):SetProperty("Image", FanLiInfo[i].imageshow)

			-- 累计次数
			local strmsg = ""
			if g_Qingmeizhujiu_nHuaquanCount < FanLiInfo[i].caiquanNum then
				strmsg = ScriptGlobal_Format("#{QMZJ_200217_04}", g_Qingmeizhujiu_nHuaquanCount, FanLiInfo[i].caiquanNum)
			else
				strmsg = ScriptGlobal_Format("#{QMZJ_200217_05}", FanLiInfo[i].caiquanNum, FanLiInfo[i].caiquanNum)
			end
			bar:GetSubItem("Qingmeizhujiu_UpFrame_Reward_PointText2"):SetText(strmsg)

			-- 隐藏对号
			bar:GetSubItem(g_Qingmeizhujiu_RewardMask[1]):Hide()
			bar:GetSubItem(g_Qingmeizhujiu_RewardMask[2]):Hide()
			bar:GetSubItem(g_Qingmeizhujiu_RewardMask[3]):Hide()

			--
			local bRet, nSelectIndex = GetBitValueInUINT(g_Qingmeizhujiu_FanLiData, 1+(i-1)*3, 2)
			if bRet > 0 and nSelectIndex > 0 then
				if g_Qingmeizhujiu_RewardMask[nSelectIndex] ~= nil then
					bar:GetSubItem(g_Qingmeizhujiu_RewardMask[nSelectIndex]):Show()
				end
			end

			--action
			local staticListCount = table.getn(g_Qingmeizhujiu_Static_Reward)
			for btn = 1, staticListCount do
				bar:GetSubItem(g_Qingmeizhujiu_Static_Reward[btn]):Hide()
				if FanLiInfo[i].staticItem[btn] ~= nil then
					local GiftItemID = FanLiInfo[i].staticItem[btn].id
					local GiftCount = FanLiInfo[i].staticItem[btn].num

					local theAction = DataPool:CreateBindActionItemForShow(GiftItemID, GiftCount)
					if theAction:GetID() ~= 0 then
						bar:GetSubItem(g_Qingmeizhujiu_Static_Reward[btn]):SetActionItem(theAction:GetID());
						bar:GetSubItem(g_Qingmeizhujiu_Static_Reward[btn]):Show()
					end
				end
			end


			bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemNone"):Hide()
			local selectListCount = table.getn(g_Qingmeizhujiu_Select_Reward)
			for btn = 1, selectListCount do
				bar:GetSubItem(g_Qingmeizhujiu_Select_Reward[btn]):Hide()
				if FanLiInfo[i].selectItem[btn] ~= nil then
					local GiftItemID = FanLiInfo[i].selectItem[btn].id
					local GiftCount = FanLiInfo[i].selectItem[btn].num
					local bShowPreView = FanLiInfo[i].selectItem[btn].bShowPreView


					-- 显示 图鉴
					if bShowPreView == 1 then
						bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemPreview"):Show()
						bar:SetSubItemEvent("Qingmeizhujiu_Reward_BasicItemPreview", "Clicked", "Qingmeizhujiu_FanLi_PreView_Click()")
					else
						bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemPreview"):Hide()
					end

					local theAction = DataPool:CreateBindActionItemForShow(GiftItemID, GiftCount)
					if theAction:GetID() ~= 0 then
						bar:GetSubItem(g_Qingmeizhujiu_Select_Reward[btn]):SetActionItem(theAction:GetID());
						bar:GetSubItem(g_Qingmeizhujiu_Select_Reward[btn]):Show()
					end
				end
			end

			--按钮
			local bRetLingQu, bHaveLingQu = GetBitValueInUINT(g_Qingmeizhujiu_FanLiData, (i-1)*3, 1)
			if bRetLingQu == 1 then
				if bHaveLingQu == 1 then	-- 已领取
					bar:GetSubItem("Qingmeizhujiu_Reward_Button"):Hide()
					bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemReceived"):Show()
					bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemNotReach"):Hide()
				else
					if g_Qingmeizhujiu_nHuaquanCount < FanLiInfo[i].caiquanNum then	-- 未达成
						bar:GetSubItem("Qingmeizhujiu_Reward_Button"):Hide()
						bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemReceived"):Hide()
						bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemNotReach"):Show()
					else
						bar:GetSubItem("Qingmeizhujiu_Reward_Button"):Show()
						bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemReceived"):Hide()
						bar:GetSubItem("Qingmeizhujiu_Reward_BasicItemNotReach"):Hide()
					end
				end
			end
			bar:SetSubItemEvent("Qingmeizhujiu_Reward_Button", "Clicked", "Qingmeizhujiu_FanLi_Reward_Click("..i..")")

			g_Qingmeizhujiu_nContentButton[i] = bar
		end
	end
end


function Qingmeizhujiu_Button_Clicked()
	--兑换判断
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetQingMei" )
		Set_XSCRIPT_ScriptID( 892719)
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end

--================================================
-- help tips
--================================================
function Qingmeizhujiu_Help_Clicked()
	--弹出说明
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NPCTalk")
		Set_XSCRIPT_ScriptID(892719)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end



--*****************************************
--青梅煮酒论英雄寻找NPC
--*****************************************
function Qingmeizhujiu_AutoNPC(index)
	if index <1 or index > 3 then
		return
	end
	--还要判断 才寻路
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AutoNPC")
		Set_XSCRIPT_ScriptID(892719)
		Set_XSCRIPT_Parameter( 0, index)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end


--*****************************************
--青梅煮酒论英雄寻找NPC
--*****************************************
function Qingmeizhujiu_CanAutoNPC(index)
	if index <1 or index > 3 then
		return
	end

	if index == 1 then --乔峰
		AutoRunToTargetEx(266,255,0)
		SetAutoRunTargetNPCName("乔峰")
	elseif index == 2 then --虚竹
		AutoRunToTargetEx(208,270,0)
		SetAutoRunTargetNPCName("虚竹")
	elseif index == 3 then --段誉
		AutoRunToTargetEx(330,188,0)
		SetAutoRunTargetNPCName("段誉")
	end
end

--=========================================================
--领取返利
--=========================================================
function Qingmeizhujiu_FanLi_Reward_Click( Idx )

	local FanLiInfo = nil
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(55) > 0 then
		FanLiInfo = g_Qingmeizhujiu_FanLiInfo_KaJi
	else
		FanLiInfo = g_Qingmeizhujiu_FanLiInfo
	end
	
	if Idx < 1 or Idx > table.getn(FanLiInfo) then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetFanLi" )
		Set_XSCRIPT_ScriptID(892719)
		Set_XSCRIPT_Parameter(0, Idx)
		Set_XSCRIPT_Parameter(1, 0) --需要选择的物品
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

--=========================================================
--预览
--=========================================================
function Qingmeizhujiu_FanLi_PreView_Click( )

	PushEvent( "SHOW_QINGMEIZHUJIU_PREVIEW" );

end
