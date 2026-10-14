
local g_Frame_UnifiedPosition

local g_Anniversary_Gift_CurPage = -1
local g_Anniversary_Gift_MaxPage = 5

local g_AG_ServerProgressMax = 19
local g_AG_ServerRXJCount = 0
local g_AG_PersonalRXJ = 0
local g_AG_LiBaoGetFlag = 0


local g_AG_curState = 0

local g_Anniversary_Gift_MaxPage = 5
local g_AG_BackImageCtrl = {}
local g_AG_LineCtrl = {}
local g_AG_ItemLockImage ={}
local g_AG_PersonalProCtrl ={}

local g_AG_StagePrizeMF = {
	5474,5475,5476,5477,5478,5479,5480,5481,5482,5483,
	5484,5485,5486,5487,5488,5489,5490,5491,5492,
}
local g_AG_KaCe_MF = 5493	--19周年应景 卡册领奖	

-- 服务器进度 阶梯值（进度值>=第i个阶梯值，就能领第i个阶段的奖励）
local g_AG_Progress_Level = {
10000,
30000,
60000,
90000,
120000,
160000,
200000,
240000,
280000,
340000,
400000,
460000,
520000,
580000,
640000,
700000,
780000,
850000,
900000,
}-- 领奖时间节点：第XXXXXXXXXXXX天

--个人星火值
local g_PersonalProgress_Level = {
10,
20,
30,
40,
50,
60,
70,
80,
90,
110,
130,
150,
170,
190,
210,
230,
260,
290,
320,
}

local g_AG_CurDay = 0

local g_Anniversary_Gift_ItemCtrl = {}
local g_Anniversary_Gift_Tooltips = {
[1]=	{normal=	"#{ZNQYJ_220215_67}",	kaji=	"#{ZNQYJ_240201_09}",	original=	"#{ZNQYJ_260122_02}"	},
[2]=	{normal=	"#{ZNQYJ_220215_68}",	kaji=	"#{ZNQYJ_240201_10}",	original=	"#{ZNQYJ_260122_03}"	},
[3]=	{normal=	"#{ZNQYJ_220215_69}",	kaji=	"#{ZNQYJ_240201_11}",	original=	"#{ZNQYJ_260122_04}"	},
[4]=	{normal=	"#{ZNQYJ_220215_70}",	kaji=	"#{ZNQYJ_240201_12}",	original=	"#{ZNQYJ_260122_05}"	},
[5]=	{normal=	"#{ZNQYJ_220215_71}",	kaji=	"#{ZNQYJ_240201_13}",	original=	"#{ZNQYJ_260122_06}"	},
[6]=	{normal=	"#{ZNQYJ_220215_72}",	kaji=	"#{ZNQYJ_240201_14}",	original=	"#{ZNQYJ_260122_07}"	},
[7]=	{normal=	"#{ZNQYJ_220215_73}",	kaji=	"#{ZNQYJ_240201_15}",	original=	"#{ZNQYJ_260122_08}"	},
[8]=	{normal=	"#{ZNQYJ_220215_74}",	kaji=	"#{ZNQYJ_240201_16}",	original=	"#{ZNQYJ_260122_09}"	},
[9]=	{normal=	"#{ZNQYJ_220215_75}",	kaji=	"#{ZNQYJ_240201_17}",	original=	"#{ZNQYJ_260122_10}"	},
[10]=	{normal=	"#{ZNQYJ_220215_76}",	kaji=	"#{ZNQYJ_240201_18}",	original=	"#{ZNQYJ_260122_11}"	},
[11]=	{normal=	"#{ZNQYJ_220215_77}",	kaji=	"#{ZNQYJ_240201_19}",	original=	"#{ZNQYJ_260122_12}"	},
[12]=	{normal=	"#{ZNQYJ_220215_78}",	kaji=	"#{ZNQYJ_240201_20}",	original=	"#{ZNQYJ_260122_13}"	},
[13]=	{normal=	"#{ZNQYJ_220215_79}",	kaji=	"#{ZNQYJ_240201_21}",	original=	"#{ZNQYJ_260122_14}"	},
[14]=	{normal=	"#{ZNQYJ_220215_80}",	kaji=	"#{ZNQYJ_240201_22}",	original=	"#{ZNQYJ_260122_15}"	},
[15]=	{normal=	"#{ZNQYJ_220215_81}",	kaji=	"#{ZNQYJ_240201_23}",	original=	"#{ZNQYJ_260122_16}"	},
[16]=	{normal=	"#{ZNQYJ_220215_82}",	kaji=	"#{ZNQYJ_240201_24}",	original=	"#{ZNQYJ_260122_17}"	},
[17]=	{normal=	"#{ZNQYJ_240201_04}",	kaji=	"#{ZNQYJ_240201_25}",	original=	"#{ZNQYJ_260122_18}"	},
[18]=	{normal=	"#{ZNQYJ_250228_01}",	kaji=	"#{ZNQYJ_250228_02}",	original=	"#{ZNQYJ_260122_19}"	},
[19]=	{normal=	"#{ZNQYJ_260122_22}",	kaji=	"#{ZNQYJ_260122_21}",	original=	"#{ZNQYJ_260122_20}"	},
}


--=========
-- PreLoad
--=========
function Anniversary_Gift_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

--=========
-- OnLoad
--=========
function Anniversary_Gift_OnLoad()

	g_Frame_UnifiedPosition = Anniversary_Gift_Frame:GetProperty("UnifiedPosition") 
	g_Anniversary_Gift_ItemCtrl = {
	[1]={BK=Anniversary_Gift_Item1BK, addtext=Anniversary_Gift_Item1_Progress,	btn=Anniversary_Gift_Item1_Gift,	redimg=Anniversary_Gift_Item1_Gift_Tips,	gotimg=Anniversary_Gift_Item1_Gift_Got},
	[2]={BK=Anniversary_Gift_Item2BK, addtext=Anniversary_Gift_Item2_Progress,	btn=Anniversary_Gift_Item2_Gift,	redimg=Anniversary_Gift_Item2_Gift_Tips,	gotimg=Anniversary_Gift_Item2_Gift_Got},
	[3]={BK=Anniversary_Gift_Item3BK, addtext=Anniversary_Gift_Item3_Progress,	btn=Anniversary_Gift_Item3_Gift,	redimg=Anniversary_Gift_Item3_Gift_Tips,	gotimg=Anniversary_Gift_Item3_Gift_Got},
	[4]={BK=Anniversary_Gift_Item4BK, addtext=Anniversary_Gift_Item4_Progress,	btn=Anniversary_Gift_Item4_Gift,	redimg=Anniversary_Gift_Item4_Gift_Tips,	gotimg=Anniversary_Gift_Item4_Gift_Got},
	}
	g_AG_BackImageCtrl={
		Anniversary_Gift_Item1,		Anniversary_Gift_Item2,		Anniversary_Gift_Item3,		Anniversary_Gift_Item4,
	}
	g_AG_BackImageLightDark = {
		--	剑护江山安亮		剑护江山安暗	
		[1]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light1", dark=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Dark1"	},
		[2]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light2", dark=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Dark2"	},
		[3]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light3", dark=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Dark3"	},
		[4]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light4", dark=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Dark4"	},
		[5]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light5", dark=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Dark5"	},
		[6]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light6", dark=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Dark6"	},
		[7]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light7", dark=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Dark7"	},
		[8]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light8", dark=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Dark8"	},
		[9]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light9", dark=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Dark9"	},
		[10]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light10", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark10"	},
		[11]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light11", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark11"	},
		[12]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light12", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark12"	},
		[13]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light13", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark13"	},
		[14]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light14", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark14"	},
		[15]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light15", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark15"	},
		[16]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light16", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark16"	},
		[17]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light17", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark17"	},
		[18]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light18", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark18"	},
		[19]={light=	"set:Anniversary_Gift14 image:Anniversary_Gift14_BK_Light19", dark=	"set:Anniversary_Gift15 image:Anniversary_Gift15_BK_Dark19"	},
	}

	g_AG_LineCtrl = {
		Anniversary_Gift_Line1,Anniversary_Gift_Line2,Anniversary_Gift_Line3,Anniversary_Gift_Line4,Anniversary_Gift_Line5
	}
	g_AG_ItemLockImage = {
		Anniversary_Gift_Item1_Gift_Lock,Anniversary_Gift_Item2_Gift_Lock,Anniversary_Gift_Item3_Gift_Lock,Anniversary_Gift_Item4_Gift_Lock
	}
	g_AG_PersonalProCtrl = {
		Anniversary_Gift_Item1_Progress2,Anniversary_Gift_Item2_Progress2,Anniversary_Gift_Item3_Progress2,Anniversary_Gift_Item4_Progress2
	}
end

--=========
-- OnEvent
--=========
function Anniversary_Gift_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 8884801 then
		local bShow = Get_XParam_INT(0)
		if bShow > 0 then
			if bShow == 1 then
				g_Anniversary_Gift_CurPage = -1
			end
			g_AG_CurDay = Get_XParam_INT(1)
			g_AG_ServerRXJCount = Get_XParam_INT(2)
			g_AG_PersonalRXJ  = Get_XParam_INT(3)--累计提交燃星炬数量
			Anniversary_Gift_Update()
			if bShow == 1 then
				this:Show()
			end
		else
			Anniversary_Gift_OnHiden()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Anniversary_Gift_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		Anniversary_Gift_On_ResetPos()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
	
		Anniversary_Gift_OnHiden();

	end

end

--=========
-- 打开
--=========
function Anniversary_Gift_Update()
	if g_AG_ServerRXJCount >= g_AG_Progress_Level[g_AG_ServerProgressMax] then
		Anniversary_Gift_XinghuoProgress:SetText("#{ZNQYJ_220215_126}")
	else
		Anniversary_Gift_XinghuoProgress:SetText( ScriptGlobal_Format("#{ZNQYJ_220215_26}",g_AG_ServerRXJCount) )
	end
	--已提交星火
	Anniversary_Gift_XinghuoProgress2:SetText( ScriptGlobal_Format("#{ZNQYJ_220215_25}",g_AG_PersonalRXJ) )
	local nServerDay = DataPool:GetServerDayTime()
	local daytime = DataPool:DateTime2DayTime(nServerDay)
	if g_AG_CurDay ~= daytime then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("PushMainUI")
			Set_XSCRIPT_ScriptID(888480)
			Set_XSCRIPT_Parameter(0, 2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		return
	end

	if g_Anniversary_Gift_CurPage == -1 then
		g_Anniversary_Gift_CurPage = 1
		g_AG_curState = 0
		if g_AG_ServerRXJCount >= g_AG_Progress_Level[g_AG_ServerProgressMax] then
			g_AG_curState = g_AG_ServerProgressMax
		else
			for i=1,g_AG_ServerProgressMax-1 do
				if g_AG_ServerRXJCount >= g_AG_Progress_Level[i] and g_AG_ServerRXJCount < g_AG_Progress_Level[i+1] then
					g_AG_curState = i
					break;
				end
			end
		end
--		PushDebugMessage("g_AG_ServerRXJCount="..g_AG_ServerRXJCount.." g_AG_curState="..g_AG_curState)
		g_Anniversary_Gift_CurPage = math.ceil(g_AG_curState/4)
		if g_Anniversary_Gift_CurPage == 0 then
			g_Anniversary_Gift_CurPage = 1
		end
	end

	if g_Anniversary_Gift_CurPage <= 1 then
		Anniversary_Gift_LeftArrow_Btn:Hide()
		Anniversary_Gift_RightArrow_Btn:Show()
	elseif g_Anniversary_Gift_CurPage >= g_Anniversary_Gift_MaxPage then
		Anniversary_Gift_LeftArrow_Btn:Show()
		Anniversary_Gift_RightArrow_Btn:Hide()
	else
		Anniversary_Gift_LeftArrow_Btn:Show()
		Anniversary_Gift_RightArrow_Btn:Show()
	end

	for i=1,4 do
		local nCardIdx = (g_Anniversary_Gift_CurPage-1)*4+i
		if nCardIdx > g_AG_ServerProgressMax then
			g_Anniversary_Gift_ItemCtrl[i].BK:Hide()
			g_AG_BackImageCtrl[i]:Hide()
			g_AG_LineCtrl[i]:Hide()
		else
			g_Anniversary_Gift_ItemCtrl[i].BK:Show()
			g_AG_BackImageCtrl[i]:Show()
			--贴图
			if g_AG_ServerRXJCount >= g_AG_Progress_Level[nCardIdx] then
				g_AG_BackImageCtrl[i]:SetProperty("Image", g_AG_BackImageLightDark[nCardIdx].light);
				g_AG_LineCtrl[i]:Show()
			else
				g_AG_BackImageCtrl[i]:SetProperty("Image", g_AG_BackImageLightDark[nCardIdx].dark);
				g_AG_LineCtrl[i]:Hide()
			end
			--服务器星火值
			if g_AG_ServerRXJCount >= g_AG_Progress_Level[nCardIdx] then
				g_Anniversary_Gift_ItemCtrl[i].addtext:SetText( ScriptGlobal_Format("#{ZNQYJ_220215_18}",g_AG_Progress_Level[nCardIdx]) )
			else
				g_Anniversary_Gift_ItemCtrl[i].addtext:SetText( ScriptGlobal_Format("#{ZNQYJ_240201_07}",g_AG_Progress_Level[nCardIdx]) )
			end
			--奖励宝箱
			local isGetReward = Pneuma:GetMF(g_AG_StagePrizeMF[nCardIdx])

			if isGetReward == 1 then
				g_Anniversary_Gift_ItemCtrl[i].btn:Hide()
				g_Anniversary_Gift_ItemCtrl[i].gotimg:Show()
				g_Anniversary_Gift_ItemCtrl[i].redimg:Hide()
				g_AG_ItemLockImage[i]:Hide()
			else
				g_Anniversary_Gift_ItemCtrl[i].gotimg:Hide()
				--小红点
				if g_AG_ServerRXJCount >= g_AG_Progress_Level[nCardIdx] then
					g_Anniversary_Gift_ItemCtrl[i].btn:Show()
					if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(130) > 0 then  --卡级
						g_Anniversary_Gift_ItemCtrl[i].btn:SetToolTip(g_Anniversary_Gift_Tooltips[nCardIdx].kaji)
					elseif Player:GetData("IsOriginalJD") == 1 then
						g_Anniversary_Gift_ItemCtrl[i].btn:SetToolTip(g_Anniversary_Gift_Tooltips[nCardIdx].original)
					else
						g_Anniversary_Gift_ItemCtrl[i].btn:SetToolTip(g_Anniversary_Gift_Tooltips[nCardIdx].normal)
					end
					g_AG_ItemLockImage[i]:Hide()
					if g_AG_PersonalRXJ >= g_PersonalProgress_Level[nCardIdx] then
						g_Anniversary_Gift_ItemCtrl[i].redimg:Show()
					else
						g_Anniversary_Gift_ItemCtrl[i].redimg:Hide()
					end
				else
					g_AG_ItemLockImage[i]:Show()
					if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(130) > 0 then  --卡级
						g_AG_ItemLockImage[i]:SetToolTip(g_Anniversary_Gift_Tooltips[nCardIdx].kaji)
					elseif Player:GetData("IsOriginalJD") == 1 then
						g_AG_ItemLockImage[i]:SetToolTip(g_Anniversary_Gift_Tooltips[nCardIdx].original)
					else
						g_AG_ItemLockImage[i]:SetToolTip(g_Anniversary_Gift_Tooltips[nCardIdx].normal)
					end
					g_Anniversary_Gift_ItemCtrl[i].btn:Hide()
					g_Anniversary_Gift_ItemCtrl[i].redimg:Hide()
				end
			end
			--个人星火值进度
			if g_AG_PersonalRXJ >= g_PersonalProgress_Level[nCardIdx] then
				g_AG_PersonalProCtrl[i]:SetText( ScriptGlobal_Format("#{ZNQYJ_220215_19}",g_PersonalProgress_Level[nCardIdx]) )
			else
				g_AG_PersonalProCtrl[i]:SetText( ScriptGlobal_Format("#{ZNQYJ_240201_08}",g_PersonalProgress_Level[nCardIdx]) )
			end
		end
	end

	--卡册红点 第19次礼包
	if Pneuma:GetMF(g_AG_KaCe_MF) == 1 then
		Anniversary_Gift_Button1_tips:Hide()
	else
		local bRed = 1
		for i=1,g_AG_ServerProgressMax do
			local isGetReward = Pneuma:GetMF(g_AG_StagePrizeMF[i])
			if isGetReward == 0 then
				bRed = 0
				break
			end
		end
		if bRed == 1 then
			Anniversary_Gift_Button1_tips:Show()
		else
			Anniversary_Gift_Button1_tips:Hide()
		end
	end

end

function Anniversary_Gift_PreClick()
	if g_Anniversary_Gift_CurPage > 1 then
		g_Anniversary_Gift_CurPage = g_Anniversary_Gift_CurPage - 1
		Anniversary_Gift_Update()
	end
end

function Anniversary_Gift_NextClick()
	if g_Anniversary_Gift_CurPage < g_Anniversary_Gift_MaxPage then
		g_Anniversary_Gift_CurPage = g_Anniversary_Gift_CurPage + 1
		Anniversary_Gift_Update()
	end
end

--=========
-- 重置
--=========
function Anniversary_Gift_On_ResetPos()

	Anniversary_Gift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end


function Anniversary_Gift_Close()
	this:Hide()
end
function Anniversary_Gift_OnHiden()
	this:Hide()
end

function Anniversary_Gift_Item_GetGift(idx)
	local nCardIdx = (g_Anniversary_Gift_CurPage-1)*4+idx
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGetAnniversaryGift")
		Set_XSCRIPT_ScriptID(888480)
		Set_XSCRIPT_Parameter(0, nCardIdx)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Anniversary_Gift_Click(idx)
	if idx==1 then
		--卡册
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnAskOpenKaCeUI")
			Set_XSCRIPT_ScriptID(888480)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
--	elseif idx==2 then
--		--抽奖
--		Clear_XSCRIPT()
--			Set_XSCRIPT_Function_Name("OnAskOpenChouJiangUI")
--			Set_XSCRIPT_ScriptID(888480)
--			Set_XSCRIPT_ParamCount(0)
--		Send_XSCRIPT()
--	elseif idx==3 then
--		--领取时装
--		Clear_XSCRIPT()
--			Set_XSCRIPT_Function_Name("OnAskOpenDressUI")
--			Set_XSCRIPT_ScriptID(888480)
--			Set_XSCRIPT_ParamCount(0)
--		Send_XSCRIPT()
	end
end

function Anniversary_Gift_Description_Clicked()
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(130) > 0 then  --卡级
		PushEvent("QUEST_HELP_MSG","#{ZNQYJ_240201_06}")
	elseif Player:GetData("IsOriginalJD") == 1 then
		PushEvent("QUEST_HELP_MSG","#{ZNQYJ_260122_01}")
	else
		PushEvent("QUEST_HELP_MSG","#{ZNQYJ_220215_08}")
	end
end