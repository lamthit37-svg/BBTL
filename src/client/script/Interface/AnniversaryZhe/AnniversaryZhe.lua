--2021周年预热活动
--签到折扣界面

local g_Frame_UnifiedPosition

local g_AnniversaryZhe_InitDisc = 80
--local g_AnniversaryZhe_MaxDisc = 5	--最大折扣力度0.5折

local g_AnniversaryZhe_RedImg = {}
local g_AnniversaryZhe_BlackImg = {}

local g_AnniversaryZhe_Tick = 0
local g_Prize = 
{
	[1] = { pic = "set:Jincheng03 image:Zunguinvwang", picname = "set:Jincheng01 image:Tag_Zunguinvwang", }, 
	[2] = { pic = "set:Jincheng02 image:Taohuaxianzi", picname = "set:Jincheng01 image:Tag_Taohuaxianzi", }, 
	[3] = { pic = "set:Jincheng03 image:Yumiangongzi", picname = "set:Jincheng01 image:Tag_Yumiangongzi", }, 
	[4] = { pic = "set:Jincheng02 image:Yulanxianzi", picname = "set:Jincheng01 image:Tag_Yulanxianzi", }, 
	[5] = { pic = "set:Jincheng02 image:Mudanxianzi", picname = "set:Jincheng01 image:Tag_Mudanxianzi", }, 
}
--=========
-- PreLoad()
--=========
function AnniversaryZhe_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function AnniversaryZhe_OnLoad()	
	g_Frame_UnifiedPosition = AnniversaryZhe_Frame_BK:GetProperty("UnifiedPosition")
	g_AnniversaryZhe_RedImg = {
		[0]="set:Jincheng01 image:Red_0",
		[1]="set:Jincheng01 image:Red_1",
		[2]="set:Jincheng01 image:Red_2",
		[3]="set:Jincheng01 image:Red_3",
		[4]="set:Jincheng01 image:Red_4",
		[5]="set:Jincheng01 image:Red_5",
		[6]="set:Jincheng01 image:Red_6",
		[7]="set:Jincheng01 image:Red_7",
		[8]="set:Jincheng01 image:Red_8",
		[9]="set:Jincheng01 image:Red_9",
	}
	g_AnniversaryZhe_BlackImg = {
		[0]="set:Jincheng01 image:Black_0",
		[1]="set:Jincheng01 image:Black_1",
		[2]="set:Jincheng01 image:Black_2",
		[3]="set:Jincheng01 image:Black_3",
		[4]="set:Jincheng01 image:Black_4",
		[5]="set:Jincheng01 image:Black_5",
		[6]="set:Jincheng01 image:Black_6",
		[7]="set:Jincheng01 image:Black_7",
		[8]="set:Jincheng01 image:Black_8",
		[9]="set:Jincheng01 image:Black_9",
	}
end

--=========
-- Event
--=========
function AnniversaryZhe_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 88839801) then
		local nUIShow = Get_XParam_INT(0)
		local nDiscountValue = Get_XParam_INT(1)
		local nTodaySHFlag = Get_XParam_INT(2)
		local nSSIndex = Get_XParam_INT(3)
		AnniversaryZhe_ZKUpdate(nDiscountValue, nTodaySHFlag, nSSIndex)
		if nUIShow==1 then

			AnniversaryZhe_BKUpdate(nTodaySHFlag)
			this:Show()
		elseif nUIShow==2 then
			AnniversaryZhe_BKUpdate(0)
			--播放完成动画
			g_AnniversaryZhe_Tick = 0
			AnniversaryZhe_BK_1:Show()
			AnniversaryZhe_BK_1:SetProperty("Alpha",0)
--			AnniversaryZhe_Client2:Tween_Play("Alpha", true, true)
			SetTimer("AnniversaryZhe","AnniversaryZhe_SH_Timer()", 200)
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then	
		AnniversaryZhe_OnCloseClk()	
	elseif event == "VIEW_RESOLUTION_CHANGED" then		
		AnniversaryZhe_On_ResetPos()	
	elseif event == "ADJEST_UI_POS" then	
		AnniversaryZhe_On_ResetPos()	
	end		
end

--=========
-- 重置
--=========
function AnniversaryZhe_On_ResetPos()
	AnniversaryZhe_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 关闭界面
--=========
function AnniversaryZhe_OnCloseClk()
	this:Hide()
end

function AnniversaryZhe_OnHide()
--PushDebugMessage("AnniversaryZhe_OnHide")
	KillTimer("AnniversaryZhe_SH_Timer()")
end
--=========
-- 折扣显示
--=========
function AnniversaryZhe_ZKUpdate(nDiscountValue, nTodaySHFlag, nSSIndex)
	if nSSIndex == nil or nSSIndex < 0 then
		return
	end
	local tData = g_Prize[nSSIndex]
	if tData == nil then
		return
	end
	local theAction = DataPool:CreateActionItemForShow(39923346, 1)
	AnniversaryZhe_AwardItemShow:SetActionItem(theAction:GetID())

	local nLastDiscount = 100-math.floor(nDiscountValue/100)
	local nCurDiscount = 100-math.mod(nDiscountValue,100)
	--当前折扣
	local dis1=math.floor(nCurDiscount/10)
	local dis2=math.mod(nCurDiscount,10)

	AnniversaryZhe_Zhe1:SetProperty("Image",g_AnniversaryZhe_RedImg[dis1])
	AnniversaryZhe_Zhe2:SetProperty("Image",g_AnniversaryZhe_RedImg[dis2])
	--控件待定
--	PushDebugMessage("nCurDiscount="..nCurDiscount)

	if nCurDiscount==g_AnniversaryZhe_InitDisc then
		--8折
		AnniversaryZhe_Yuan1:SetProperty("Image","")
		AnniversaryZhe_Yuan2:SetProperty("Image","")

		AnniversaryZhe_Xian:Hide()
	else
		--其他折扣
		--之前折扣
		local lastdis1=math.floor(nLastDiscount/10)
		local lastdis2=math.mod(nLastDiscount,10)
		AnniversaryZhe_Yuan1:SetProperty("Image",g_AnniversaryZhe_BlackImg[lastdis1])
		AnniversaryZhe_Yuan2:SetProperty("Image",g_AnniversaryZhe_BlackImg[lastdis2])
		AnniversaryZhe_Xian:Show()
	end

	--小红点
	--无最低折扣值
	if nTodaySHFlag==0 then
		AnniversaryZhe_Tips_Point:Show()
	else
		AnniversaryZhe_Tips_Point:Hide()
	end
	-- 图标
	AnniversaryZhe_BKPic5:SetProperty( "Image", tData.pic )
			
	-- 名字
	AnniversaryZhe_BKPic6:SetProperty( "Image", tData.picname )	
end
function AnniversaryZhe_BKUpdate(nTodaySHFlag)
	--无最低折扣值
	if nTodaySHFlag==0 then
		AnniversaryZhe_BK_1:Hide()
	else
		AnniversaryZhe_BK_1:Show()
	end
end
--=========
-- 赏花按钮
--=========
function AnniversaryZhe_ShangHua_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnShangHuaClk")
		Set_XSCRIPT_ScriptID(888398)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
function AnniversaryZhe_SH_Timer()
--PushDebugMessage("AnniversaryZhe_SH_Timer")
	g_AnniversaryZhe_Tick = g_AnniversaryZhe_Tick+1
	
	if g_AnniversaryZhe_Tick > 0 and g_AnniversaryZhe_Tick < 10 then
		AnniversaryZhe_BK_1:SetProperty("Alpha",g_AnniversaryZhe_Tick*0.1)
--		PushDebugMessage("Alpha="..g_AnniversaryZhe_Tick*0.1)
	elseif g_AnniversaryZhe_Tick >= 10 then
		AnniversaryZhe_BK_1:SetProperty("Alpha",1)
		g_AnniversaryZhe_Tick = -1
		AnniversaryZhe_BKUpdate(1)
		KillTimer("AnniversaryZhe_SH_Timer()")
	end
end

--=========
-- 小问号
--=========
function AnniversaryZhe_HelpClk()
		PushEvent("CCSHOP_HELP", 132)	
end
