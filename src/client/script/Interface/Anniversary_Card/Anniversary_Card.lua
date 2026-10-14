
local g_Frame_UnifiedPosition

local g_Anniversary_Card_UnActiveCtrl = {}
--local g_Anniversary_Card_ActiveCtrl = {}
local g_Anniversary_Card_RewardCtrl = {}

local g_Anniversary_Card_Page = -1
local g_Anniversary_Card_MaxPage = 3

local g_Anniversary_Card_Image = {}
local g_Anniversary_Card_Tooltips = {}


local g_Anniversary_Card_StdCount=19
local g_AC_StagePrizeMF = {
	5474,5475,5476,5477,5478,5479,5480,5481,5482,5483,
	5484,5485,5486,5487,5488,5489,5490,5491,5492,
}

local g_AC_KaCeMF = 5493	--19周年应景 卡册领奖	

--=========
-- PreLoad
--=========
function Anniversary_Card_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

--=========
-- OnLoad
--=========
function Anniversary_Card_OnLoad()

	g_Frame_UnifiedPosition = Anniversary_Card_Frame:GetProperty("UnifiedPosition") 
	g_Anniversary_Card_UnActiveCtrl = {
		Anniversary_Card1_UnActive,		Anniversary_Card2_UnActive,		Anniversary_Card3_UnActive,		Anniversary_Card4_UnActive,
		Anniversary_Card5_UnActive,		Anniversary_Card6_UnActive,		Anniversary_Card7_UnActive,		Anniversary_Card8_UnActive,
	}
--	g_Anniversary_Card_ActiveCtrl = {
--		Anniversary_Card1_Active,		Anniversary_Card2_Active,		Anniversary_Card3_Active,		Anniversary_Card4_Active,
--		Anniversary_Card5_Active,		Anniversary_Card6_Active,		Anniversary_Card7_Active,		Anniversary_Card8_Active,
--	}
	g_Anniversary_Card_RewardCtrl = {
		redtips=Anniversary_Card_Reward1_tips,	gotimg=Anniversary_Card_Reward1BtnOK
	}
	g_Anniversary_Card_Image = {
		--	济苍生亮		济苍生暗	
		[1]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light1", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark1"	},
		[2]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light2", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark2"	},
		[3]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light3", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark3"	},
		[4]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light4", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark4"	},
		[5]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light5", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark5"	},
		[6]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light6", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark6"	},
		[7]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light7", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark7"	},
		[8]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light8", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark8"	},
		[9]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light9", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark9"	},
		[10]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light10", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark10"	},
		[11]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light11", dark=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Dark11"	},
		[12]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light12", dark=	"set:Anniversary_Gift17 image:Anniversary_Gift17_BK_Dark12"	},
		[13]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light13", dark=	"set:Anniversary_Gift17 image:Anniversary_Gift17_BK_Dark13"	},
		[14]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light14", dark=	"set:Anniversary_Gift17 image:Anniversary_Gift17_BK_Dark14"	},
		[15]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light15", dark=	"set:Anniversary_Gift17 image:Anniversary_Gift17_BK_Dark15"	},
		[16]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light16", dark=	"set:Anniversary_Gift17 image:Anniversary_Gift17_BK_Dark16"	},
		[17]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light17", dark=	"set:Anniversary_Gift17 image:Anniversary_Gift17_BK_Dark17"	},
		[18]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light18", dark=	"set:Anniversary_Gift17 image:Anniversary_Gift17_BK_Dark18"	},
		[19]={light=	"set:Anniversary_Gift16 image:Anniversary_Gift16_BK_Light19", dark=	"set:Anniversary_Gift17 image:Anniversary_Gift17_BK_Dark19"	},
	}
	g_Anniversary_Card_Tooltips = {
		"#{ZNQYJ_220215_47}",		"#{ZNQYJ_220215_48}",		"#{ZNQYJ_220215_49}",		"#{ZNQYJ_220215_50}",
		"#{ZNQYJ_220215_51}",		"#{ZNQYJ_220215_52}",		"#{ZNQYJ_220215_53}",		"#{ZNQYJ_220215_54}",
		"#{ZNQYJ_220215_55}",		"#{ZNQYJ_220215_56}",		"#{ZNQYJ_220215_57}",		"#{ZNQYJ_220215_58}",
		"#{ZNQYJ_220215_59}",		"#{ZNQYJ_220215_60}",		"#{ZNQYJ_220215_61}",		"#{ZNQYJ_220215_62}",
		"#{ZNQYJ_240201_05}",		"#{ZNQYJ_250228_03}",		"#{ZNQYJ_260122_23}",
	}
end

--=========
-- OnEvent
--=========
function Anniversary_Card_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 8884802 then

		local bShow = Get_XParam_INT(0)
		if bShow > 0 then
			g_Anniversary_Card_Page = -1
			Anniversary_Card_Update()
			if bShow == 1 then
				this:Show()
				CloseWindow("Anniversary_Gift",true)
			end
		else
			Anniversary_Card_OnHiden()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Anniversary_Card_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		Anniversary_Card_On_ResetPos()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
	
		Anniversary_Card_OnHiden();

	end

end

--=========
-- 打开
--=========
function Anniversary_Card_Update()
	local flag={}
	local isActiveTotal=0
	for i=1,g_Anniversary_Card_StdCount do
		flag[i] = Pneuma:GetMF(g_AC_StagePrizeMF[i])
		isActiveTotal = isActiveTotal + flag[i]
	end
	if g_Anniversary_Card_Page == -1 then
		local curIdx = 1
	
		for i=g_Anniversary_Card_StdCount,1,-1 do
			if flag[i] == 1 then
				curIdx = i
				break;
			end
		end
		g_Anniversary_Card_Page = math.floor((curIdx+7)/8)
	end

	if g_Anniversary_Card_Page == 1 then
		--首页
		Anniversary_Card_LeftArrow_Btn:Hide()
		Anniversary_Card_RightArrow_Btn:Show()
	elseif g_Anniversary_Card_Page == g_Anniversary_Card_MaxPage then
		--尾页
		Anniversary_Card_LeftArrow_Btn:Show()
		Anniversary_Card_RightArrow_Btn:Hide()
	else
		--中间页
		Anniversary_Card_LeftArrow_Btn:Show()
		Anniversary_Card_RightArrow_Btn:Show()
	end
	
	for i=1,8 do
		local nCardIdx = (g_Anniversary_Card_Page-1)*8+i
		if nCardIdx > g_Anniversary_Card_StdCount then
			g_Anniversary_Card_UnActiveCtrl[i]:Hide()
		else
			g_Anniversary_Card_UnActiveCtrl[i]:Show()
			if flag[nCardIdx] == 1 then
				g_Anniversary_Card_UnActiveCtrl[i]:SetProperty("Image", g_Anniversary_Card_Image[nCardIdx].light)
			else
				g_Anniversary_Card_UnActiveCtrl[i]:SetProperty("Image", g_Anniversary_Card_Image[nCardIdx].dark)
			end
			g_Anniversary_Card_UnActiveCtrl[i]:SetToolTip(g_Anniversary_Card_Tooltips[nCardIdx])
		end
	end

	if Pneuma:GetMF(g_AC_KaCeMF) == 1 then
		g_Anniversary_Card_RewardCtrl.redtips:Hide()
		g_Anniversary_Card_RewardCtrl.gotimg:Show()
	else
		g_Anniversary_Card_RewardCtrl.gotimg:Hide()
		if isActiveTotal >= g_Anniversary_Card_StdCount then
			g_Anniversary_Card_RewardCtrl.redtips:Show()
		else
			g_Anniversary_Card_RewardCtrl.redtips:Hide()
		end
	end

end

function Anniversary_Card_LeftArrowClick()
	if g_Anniversary_Card_Page > 1 then
		g_Anniversary_Card_Page = g_Anniversary_Card_Page - 1
		Anniversary_Card_Update()
	end
end
function Anniversary_Card_RightArrowClick()
	if g_Anniversary_Card_Page < g_Anniversary_Card_MaxPage then
		g_Anniversary_Card_Page = g_Anniversary_Card_Page + 1
		Anniversary_Card_Update()
	end
end
--=========
-- 关闭
--=========
function Anniversary_Card_OnHiden()
	this:Hide()
end

--=========
-- 重置
--=========
function Anniversary_Card_On_ResetPos()
	Anniversary_Card_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

function Anniversary_Card_Close()
	this:Hide()
end

function Anniversary_Card_Reward_OnRewardClick(idx)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnGetKaCeLiBao")
		Set_XSCRIPT_ScriptID(888480)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
