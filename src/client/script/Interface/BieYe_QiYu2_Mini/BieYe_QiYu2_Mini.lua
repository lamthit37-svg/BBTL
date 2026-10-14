local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_UI_NoClose = 0

local g_Acitvity_Desc = ""

--当前是活动几
local g_CurActivityMini =1

local g_Num1Mini =0
local g_Num2Mini =0
local g_Num3Mini =0
local g_Num4Mini =0

local g_ActivityImage = {
"set:BieYeQiYu01 image:BieYeQiYu_1",
"set:BieYeQiYu01 image:BieYeQiYu_2",
"set:BieYeQiYu02 image:BieYeQiYu_3",
"set:BieYeQiYu02 image:BieYeQiYu_4",
}



function BieYe_QiYu2_Mini_PreLoad()

	--切换场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")				-- 界面

--	this:RegisterEvent("BIEYE_ACITVITY1_UI_MINI_OPEN")

	this:RegisterEvent("BIEYE_ACITVITY2_UI_MINI_OPEN")

--	this:RegisterEvent("BIEYE_ACITVITY3_UI_MINI_OPEN")

--	this:RegisterEvent("BIEYE_ACITVITY4_UI_MINI_OPEN")
	--关闭

end

function BieYe_QiYu2_Mini_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BieYe_QiYu2_Mini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BieYe_QiYu2_Mini_Frame:GetProperty("UnifiedYPosition");

end

function BieYe_QiYu2_Mini_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		BieYe_QiYu2_Mini_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BieYe_QiYu2_Mini_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then

		local ret =BieYeUI:IsBieYeScene()
		if ( ret == false ) then
			this:Hide()
		end
	--活动一
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 892270) then
		local CommandType = Get_XParam_INT(0)
		local leftTime = Get_XParam_INT(1)
		g_Num1Mini = Get_XParam_INT(2)
		g_Num2Mini = Get_XParam_INT(3)
		g_Num3Mini = Get_XParam_INT(4)
		g_Num4Mini = Get_XParam_INT(5)
		g_Acitvity_Desc = Get_XParam_STR(0)
		g_CurActivity = 2

		if CommandType == 1 then
		--打开界面
			BieYe_QiYu2_Mini_RefreshData_Activity1(leftTime,g_Num1Mini,g_Num2Mini,g_Num3Mini,g_Num4Mini)

		end
		if CommandType == 2 then
		--关闭界面
			if (this:IsVisible()) then
				this:Hide()
			end
		end
		if CommandType == 3 then
		--更新界面
			BieYe_QiYu2_Mini_RefreshData_Activity1(leftTime,g_Num1Mini,g_Num2Mini,g_Num3Mini,g_Num4Mini)
		end

	elseif( event == "BIEYE_ACITVITY2_UI_MINI_OPEN" ) then
		local leftTime= tonumber(arg0)
		g_Num1Mini= tonumber(arg1)
		g_Num2Mini= tonumber(arg2)
		g_Num3Mini= tonumber(arg3)
		g_Num4Mini= tonumber(arg4)
		BieYe_QiYu2_Mini_OpenUI_Activity1(leftTime,g_Num1Mini,g_Num2Mini,g_Num3Mini,g_Num4Mini)

	end
end

function BieYe_QiYu2_Mini_OpenUI_Activity1(leftTime,g_Num1Mini,g_Num2Mini,g_Num3Mini,g_Num4Mini)
	this:Show()
	BieYe_QiYu2_Mini_RefreshData_Activity1(leftTime,g_Num1Mini,g_Num2Mini,g_Num3Mini,g_Num4Mini)
end

function BieYe_QiYu2_Mini_RefreshData_Activity1(leftTime,g_Num1Mini,g_Num2Mini,g_Num3Mini,g_Num4Mini)
--this:Show()
	BieYe_QiYu2_Mini_DragTitle : SetText("#{JYQY_160810_102}")
	BieYe_QiYu2_Mini_Text1_2:SetText( g_Num1Mini.."/10")
	BieYe_QiYu2_Mini_Text2_2:SetText( g_Num2Mini.."/10")
	BieYe_QiYu2_Mini_Text3_2:SetText( g_Num3Mini.."/10")
	BieYe_QiYu2_Mini_Text4_2:SetText( g_Num4Mini.."/10")
	BieYe_QiYu2_Mini_StopWatch:SetProperty("Timer", tostring(leftTime))
	if leftTime == 0 then
		BieYe_QiYu2_Mini_StopWatchText:SetText("")
	else
		BieYe_QiYu2_Mini_StopWatchText:SetText("#{JYQY_160810_52}")
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYe_QiYu2_Mini_ResetPos()
	BieYe_QiYu2_Mini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BieYe_QiYu2_Mini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 打开活动追踪mini界面
--================================================
function BieYe_QiYu2_Mini_Open_UI_Clicked()
	local timer = BieYe_QiYu2_Mini_StopWatch:GetProperty("Timer")

	PushEvent("BIEYE_ACITVITY2_UI_OPEN",timer,g_Num1Mini,g_Num2Mini,g_Num3Mini,g_Num4Mini)

	this:Hide()
end

