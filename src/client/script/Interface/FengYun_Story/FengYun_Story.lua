--FengYun_Story.lua
local g_FengYun_Story_UnifiedXPosition
local g_FengYun_Story_UnifiedYPosition
local g_FengYun_Story_MaxProgress = 10 --一册最多10页
local g_FengYun_Story_ProgressImage = --上下册的图片
{
	[1] = {
		[1] = "set:FengYun_Story2 image:FengYun_Story_Comic1",
		[2] = "set:FengYun_Story2 image:FengYun_Story_Comic2",
		[3] = "set:FengYun_Story3 image:FengYun_Story_Comic3",
		[4] = "set:FengYun_Story3 image:FengYun_Story_Comic4",
		[5] = "set:FengYun_Story4 image:FengYun_Story_Comic5",
		[6] = "set:FengYun_Story4 image:FengYun_Story_Comic6",
		[7] = "set:FengYun_Story5 image:FengYun_Story_Comic7",
		[8] = "set:FengYun_Story5 image:FengYun_Story_Comic8",
		[9] = "set:FengYun_Story6 image:FengYun_Story_Comic9",
		[10] = "set:FengYun_Story6 image:FengYun_Story_Comic10",
	},
	[2] = {
		[1] = "set:FengYun_Story7 image:FengYun_Story_Comic11",
		[2] = "set:FengYun_Story7 image:FengYun_Story_Comic12",
		[3] = "set:FengYun_Story8 image:FengYun_Story_Comic13",
		[4] = "set:FengYun_Story8 image:FengYun_Story_Comic14",
		[5] = "set:FengYun_Story9 image:FengYun_Story_Comic15",
		[6] = "set:FengYun_Story9 image:FengYun_Story_Comic16",
		[7] = "set:FengYun_Story10 image:FengYun_Story_Comic17",
		[8] = "set:FengYun_Story10 image:FengYun_Story_Comic18",
		[9] = "set:FengYun_Story11 image:FengYun_Story_Comic19",
		[10] = "set:FengYun_Story11 image:FengYun_Story_Comic20",
	},
}
local g_FengYun_Story_LineText = --上下册的文字图片
{
	[1] = {
		[1] = "set:FengYun_Story1 image:FengYun_Story_Text1",
		[2] = "set:FengYun_Story1 image:FengYun_Story_Text2",
		[3] = "set:FengYun_Story1 image:FengYun_Story_Text3",
		[4] = "set:FengYun_Story1 image:FengYun_Story_Text4",
		[5] = "set:FengYun_Story1 image:FengYun_Story_Text5",
		[6] = "set:FengYun_Story1 image:FengYun_Story_Text6",
		[7] = "set:FengYun_Story1 image:FengYun_Story_Text7",
		[8] = "set:FengYun_Story1 image:FengYun_Story_Text8",
		[9] = "set:FengYun_Story1 image:FengYun_Story_Text9",
		[10] = "set:FengYun_Story1 image:FengYun_Story_Text10",
	},
	[2] = {
		[1] = "set:FengYun_Story1 image:FengYun_Story_Text11",
		[2] = "set:FengYun_Story1 image:FengYun_Story_Text12",
		[3] = "set:FengYun_Story1 image:FengYun_Story_Text13",
		[4] = "set:FengYun_Story1 image:FengYun_Story_Text14",
		[5] = "set:FengYun_Story14 image:FengYun_Story_Text15",
		[6] = "set:FengYun_Story14 image:FengYun_Story_Text16",
		[7] = "set:FengYun_Story14 image:FengYun_Story_Text17",
		[8] = "set:FengYun_Story14 image:FengYun_Story_Text18",
		[9] = "set:FengYun_Story14 image:FengYun_Story_Text19",
		[10] = "set:FengYun_Story14 image:FengYun_Story_Text20",
	},
}
local g_FengYun_Story_FengmianImage1 = "set:FengYun_Story13 image:FengYun_Story_Comic_top" --封面上册
local g_FengYun_Story_FengmianImage2 = "set:FengYun_Story13 image: FengYun_Story_Comic_down" --封面下册
local g_FengYun_Story_HaveTodoImage = "set:Anniversary_Gift5 image:BK_Dark6" --有可以做的流程
local g_FengYun_Story_NotEndImage = "set:FengYun_Story1 image:FengYun_Story_ww" --未完待续 文字
local g_FengYun_Story_EndImage = "set:FengYun_Story1 image: FengYun_Story_jz" --结局 文字

local g_FengYun_Story_NowStage = 1 --上册还是下册
local g_FengYun_Story_Progress = 0 --当前进度
local g_FengYun_Story_IsHaveProgressToDo = 0 --是否有流程可以做
local g_FengYun_Story_NowIndex = 0 --当前在第几页
local g_FengYun_Story_Svrtype = 0
local g_FengYun_Story_IsFromItem = 0

function FengYun_Story_PreLoad()
	--第二个参数表示界面隐藏时是否响应事件 默认为true
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false);
	this:RegisterEvent("SCENE_TRANSED", false)
end

function FengYun_Story_OnLoad()
	-- 保存界面的默认相对位置
	g_FengYun_Story_UnifiedXPosition = FengYun_Story_Frame:GetProperty("UnifiedXPosition");
	g_FengYun_Story_UnifiedYPosition = FengYun_Story_Frame:GetProperty("UnifiedYPosition");
end

function FengYun_Story_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 30015201) then
		local nFuncType = Get_XParam_INT(0)
		if nFuncType == 2 then
			FengYun_Story_InitialData()
			g_FengYun_Story_NowStage = Get_XParam_INT(1)
			g_FengYun_Story_Svrtype = Get_XParam_INT(2)
			g_FengYun_Story_Progress = Get_XParam_INT(3)
			if g_FengYun_Story_Progress < 0 then
				g_FengYun_Story_Progress = 0
			elseif g_FengYun_Story_Progress > g_FengYun_Story_MaxProgress then
				g_FengYun_Story_Progress = g_FengYun_Story_MaxProgress
			end
			g_FengYun_Story_IsHaveProgressToDo = Get_XParam_INT(4)
			g_FengYun_Story_NowIndex = 0
			FengYun_Story_Update()
			this:Show()
		elseif nFuncType == 6 then
			local npcposx = Get_XParam_INT(1)
			local npcposz = Get_XParam_INT(2)
			local npcresid = Get_XParam_INT(3)
			local autoFlag = Get_XParam_INT(4)
			local npcname = Get_XParam_STR(0)
			if autoFlag == 0 then
				AutoRuntoTargetExWithName(npcposx, npcposz, npcresid, npcname)
			else
				AutoRunToTargetEx(npcposx, npcposz, npcresid)
			end
			FengYun_Story_Close()
		elseif nFuncType == 7 then
			FengYun_Story_InitialData()
			this:Show()
			local stage = Get_XParam_INT(1)
			local svrType = Get_XParam_INT(2)
			local targetImage = Get_XParam_INT(3)
			FengYun_Story_ShowIndexImage(stage, svrType, targetImage)
		elseif nFuncType == 9 then
			FengYun_Story_InitialData()
			g_FengYun_Story_NowStage = Get_XParam_INT(1)
			g_FengYun_Story_Svrtype = 0
			g_FengYun_Story_Progress = g_FengYun_Story_MaxProgress
			g_FengYun_Story_IsHaveProgressToDo = 0
			g_FengYun_Story_NowIndex = 0
			g_FengYun_Story_IsFromItem = 1
			FengYun_Story_Update()
			this:Show()
		end
	elseif (event == "ADJEST_UI_POS") then
		FengYun_Story_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_Story_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_Story_Close()
	elseif (event == "SCENE_TRANSED") then
		FengYun_Story_Close()
	end
end

function FengYun_Story_Update()
	FengYun_Story_DragTitle:SetText("") --标题不显示文字

	--变量check
	if g_FengYun_Story_NowStage ~= 1 and g_FengYun_Story_NowStage ~= 2 then
		g_FengYun_Story_NowStage = 1
	end
	if g_FengYun_Story_Progress < 0 then
		g_FengYun_Story_Progress = 0
	elseif g_FengYun_Story_Progress > g_FengYun_Story_MaxProgress then
		g_FengYun_Story_Progress = g_FengYun_Story_MaxProgress
	end
	if g_FengYun_Story_NowIndex < 0 then
		g_FengYun_Story_NowIndex = 0
	elseif g_FengYun_Story_NowIndex > g_FengYun_Story_Progress + 1 then
		g_FengYun_Story_NowIndex = g_FengYun_Story_Progress + 1
	end

	--显示封面或者具体页数
	if g_FengYun_Story_NowIndex == 0 then --显示封面
		
		if g_FengYun_Story_NowStage == 1 then
			--FengYun_Story_DragTitle:SetText("#{FYWS_260107_41}") --上册
			FengYun_Story_BK3:SetProperty("Image", g_FengYun_Story_FengmianImage1)
			FengYun_Story_Help:Show()
			FengYun_Story_Help2:Hide()
		elseif g_FengYun_Story_NowStage == 2 then
			--FengYun_Story_DragTitle:SetText("#{FYWS_260107_42}") --下册
			FengYun_Story_BK3:SetProperty("Image", g_FengYun_Story_FengmianImage2)
			FengYun_Story_Help:Hide()
			FengYun_Story_Help2:Show()
		end

		FengYun_Story_Button1:Show() --开始阅读按钮 显示
		FengYun_Story_BK3:Show() --封面页 显示
		FengYun_Story_LeftArrow:Hide() --左右箭头 隐藏
		FengYun_Story_RightArrow:Hide()
		FengYun_Story_Button2:Hide() --点击前往按钮 隐藏
		FengYun_Story_BK:Hide() --显示剧情页图片
		FengYun_Story_BK2:Hide()
		FengYun_Story_BK2_Line:Hide() --显示剧情页的时候才显示的书线 FengYun_Story_BK2_Line_Text用来显示剧情页的文字图片
		FengYun_Story_BK2_Text:Hide() --文字页

	elseif g_FengYun_Story_NowIndex > g_FengYun_Story_Progress and g_FengYun_Story_Progress > 0 then --显示结局页或者未完待续页
		
		FengYun_Story_Help:Hide() 
		FengYun_Story_Help2:Hide()
		FengYun_Story_BK3:Hide() --封面
		FengYun_Story_Button1:Hide()
		FengYun_Story_Button2:Hide()
		FengYun_Story_LeftArrow:Show()
		FengYun_Story_RightArrow:Hide()
		FengYun_Story_BK:Hide() --剧情页
		FengYun_Story_BK2:Show()
		FengYun_Story_BK2_Line:Hide() --剧情页文字

		FengYun_Story_BK2_Text:Show()
		if g_FengYun_Story_Progress < g_FengYun_Story_MaxProgress then --显示未完待续页
			FengYun_Story_BK2_Text:SetProperty("Image", g_FengYun_Story_NotEndImage)
		else --显示结局页
			FengYun_Story_BK2_Text:SetProperty("Image", g_FengYun_Story_EndImage)
		end
	else --中间的页数
		
		FengYun_Story_Help:Hide() 
		FengYun_Story_Help2:Hide()
		FengYun_Story_Button1:Hide()
		FengYun_Story_Button2:Hide()
		FengYun_Story_BK3:Hide() --封面
		FengYun_Story_LeftArrow:Show()
		FengYun_Story_RightArrow:Show()
		FengYun_Story_BK2_Text:Hide()

		if g_FengYun_Story_IsHaveProgressToDo == 1 or g_FengYun_Story_Progress == 0 then --有可以做的流程或者玩家解锁进度为0,那就显示点击前往的页面
			
			FengYun_Story_Button2:Show()
			FengYun_Story_LeftArrow:Hide()
			FengYun_Story_RightArrow:Hide()
			FengYun_Story_BK:Hide() --剧情页
			FengYun_Story_BK2:Show()
			FengYun_Story_BK2_Line:Show() --剧情页文字
			local linetext = g_FengYun_Story_LineText[g_FengYun_Story_NowStage][g_FengYun_Story_Progress+1]
			if linetext ~= nil then
				FengYun_Story_BK2_Line_Text:SetProperty("Image", linetext)
				--PushDebugMessage(linetext)
			end
		else --在已解锁的页数来回切换
			FengYun_Story_BK2:Hide()
			FengYun_Story_BK:Show() --剧情页
			local imageStr = g_FengYun_Story_ProgressImage[g_FengYun_Story_NowStage][g_FengYun_Story_NowIndex]
			if imageStr ~= nil then
				FengYun_Story_BK:SetProperty("Image", imageStr)
			end
		end
	end

	if g_FengYun_Story_IsFromItem == 1 then
		FengYun_Story_Help:Hide()
		FengYun_Story_Help2:Hide()
	end
end

function FengYun_Story_ShowIndexImage(stage, svrType, targetImage)
	if stage ~= 1 and stage ~= 2 then
		stage = 1
	end
	if targetImage < 1 or targetImage > g_FengYun_Story_MaxProgress then
		targetImage = 1
	end
	--先把多余控件都隐藏了
	FengYun_Story_Help:Hide() 
	FengYun_Story_Help2:Hide()
	FengYun_Story_Button1:Hide()
	FengYun_Story_Button2:Hide()
	FengYun_Story_BK3:Hide() --封面
	FengYun_Story_LeftArrow:Hide()
	FengYun_Story_RightArrow:Hide()
	FengYun_Story_BK2:Hide()
	FengYun_Story_BK2_Text:Hide()

	FengYun_Story_BK:Show() --剧情页
	local imageStr = g_FengYun_Story_ProgressImage[stage][targetImage]
	if imageStr ~= nil then
		FengYun_Story_BK:SetProperty("Image", imageStr)
	end
end

--onhidden closebtn
function FengYun_Story_Close()
	this:Hide()
	FengYun_Story_InitialData()
end

function FengYun_Story_InitialData()
	--初始化
	g_FengYun_Story_NowStage = 1 --上册还是下册
	g_FengYun_Story_Progress = 0 --当前进度
	g_FengYun_Story_IsHaveProgressToDo = 0 --是否有流程可以做
	g_FengYun_Story_NowIndex = 0 --当前在第几页
	g_FengYun_Story_Svrtype = 0
	g_FengYun_Story_IsFromItem = 0
end

--help
function FengYun_Story_Clicked()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("HelpMsg")
	Set_XSCRIPT_ScriptID(300152)
	Set_XSCRIPT_Parameter(0, 2)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--start read
function FengYun_Story_Start()
	g_FengYun_Story_NowIndex = 1
	FengYun_Story_Update()
end

--goto
function FengYun_Story_Goto()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("Goto")
	Set_XSCRIPT_ScriptID(300152)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--上一页
function FengYun_Story_Page_Left()
	g_FengYun_Story_NowIndex = g_FengYun_Story_NowIndex - 1
	if g_FengYun_Story_NowIndex < 0 then
		g_FengYun_Story_NowIndex = 0
	elseif g_FengYun_Story_NowIndex > g_FengYun_Story_Progress + 1 then
		g_FengYun_Story_NowIndex = g_FengYun_Story_Progress + 1
	end
	FengYun_Story_Update()
end

--下一页
function FengYun_Story_Page_Right()
	g_FengYun_Story_NowIndex = g_FengYun_Story_NowIndex + 1
	if g_FengYun_Story_NowIndex < 0 then
		g_FengYun_Story_NowIndex = 0
	elseif g_FengYun_Story_NowIndex > g_FengYun_Story_Progress + 1 then
		g_FengYun_Story_NowIndex = g_FengYun_Story_Progress + 1
	end
	FengYun_Story_Update()
end

function FengYun_Story_On_ResetPos()
	FengYun_Story_Frame:SetProperty("UnifiedXPosition", g_FengYun_Story_UnifiedXPosition);
	FengYun_Story_Frame:SetProperty("UnifiedYPosition", g_FengYun_Story_UnifiedYPosition);
end
