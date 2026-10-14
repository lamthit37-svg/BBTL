local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_UI_NoClose = 0

local g_Acitvity_Desc = ""

--当前是活动几
local g_CurActivityMini =1

local g_CurValueMini =1

local g_ActivityImage = {
"set:BieYeQiYu01 image:BieYeQiYu_1",
"set:BieYeQiYu01 image:BieYeQiYu_2",
"set:BieYeQiYu02 image:BieYeQiYu_3",
"set:BieYeQiYu02 image:BieYeQiYu_4",
}



function BieYe_QiYu_Mini_PreLoad()

	--切换场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")				-- 界面

	this:RegisterEvent("BIEYE_ACITVITY1_UI_MINI_OPEN")

	this:RegisterEvent("BIEYE_ACITVITY2_UI_MINI_OPEN")

	this:RegisterEvent("BIEYE_ACITVITY3_UI_MINI_OPEN")

	this:RegisterEvent("BIEYE_ACITVITY4_UI_MINI_OPEN")
	--关闭

end

function BieYe_QiYu_Mini_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BieYe_QiYu_Mini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BieYe_QiYu_Mini_Frame:GetProperty("UnifiedYPosition");

end

function BieYe_QiYu_Mini_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		BieYe_QiYu_Mini_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BieYe_QiYu_Mini_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then

		local ret =BieYeUI:IsBieYeScene()
		if ( ret == false ) then
			this:Hide()
		end
	--活动一
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 892273) then
		local CommandType = Get_XParam_INT(0)
		g_CurValueMini = Get_XParam_INT(1)
		local leftTime = Get_XParam_INT(2)
		g_Acitvity_Desc = Get_XParam_STR(0)
		g_CurActivityMini = 1
		if CommandType == 1 then
		--打开界面
			BieYe_QiYu_Mini_RefreshData_Activity1(leftTime,g_CurValueMini)
		end
		if CommandType == 2 then
		--关闭界面
			if (this:IsVisible()) then
				this:Hide()
			end
		end
		if CommandType == 3 then
		--更新界面
			BieYe_QiYu_Mini_RefreshData_Activity1(leftTime,g_CurValueMini)
		end
	--活动三
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 892294) then
		local CommandType = Get_XParam_INT(0)
		g_CurValueMini = Get_XParam_INT(1)
		local leftTime = Get_XParam_INT(2)
		g_Acitvity_Desc = Get_XParam_STR(0)
		g_CurActivityMini = 3
		if CommandType == 1 then
		--打开界面
			BieYe_QiYu_Mini_RefreshData_Activity3(leftTime,g_CurValueMini)
		end
		if CommandType == 2 then
		--关闭界面
			if (this:IsVisible()) then
				this:Hide()
			end
		end
		if CommandType == 3 then
		--更新界面
			BieYe_QiYu_Mini_RefreshData_Activity3(leftTime,g_CurValueMini)
		end
	--活动四
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 892280) then
		local CommandType = Get_XParam_INT(0)
		g_CurValueMini = Get_XParam_INT(1)
		local leftTime = Get_XParam_INT(2)
		g_Acitvity_Desc = Get_XParam_STR(0)
		g_CurActivityMini = 4
		if CommandType == 1 then
		--打开界面
			BieYe_QiYu_Mini_RefreshData_Activity4(leftTime,g_CurValueMini)
		end
		if CommandType == 2 then
		--关闭界面
			if (this:IsVisible()) then
				this:Hide()
			end
		end
		if CommandType == 3 then
		--更新界面
			BieYe_QiYu_Mini_RefreshData_Activity4(leftTime,g_CurValueMini)
		end
	elseif( event == "BIEYE_ACITVITY1_UI_MINI_OPEN" ) then
		local leftTime= tonumber(arg0)
		local CurValue= tonumber(arg1)
		BieYe_QiYu_Mini_OpenUI_Activity1(leftTime,CurValue)

	elseif( event == "BIEYE_ACITVITY3_UI_MINI_OPEN" ) then
		local leftTime= tonumber(arg0)
		local CurValue= tonumber(arg1)
		BieYe_QiYu_Mini_OpenUI_Activity3(leftTime,CurValue)

	elseif( event == "BIEYE_ACITVITY4_UI_MINI_OPEN" ) then
		local leftTime= tonumber(arg0)
		local CurValue= tonumber(arg1)
	--	PushDebugMessage("CurValue="..CurValue)
		BieYe_QiYu_Mini_OpenUI_Activity4(leftTime,CurValue)

	end
end

function BieYe_QiYu_Mini_OpenUI_Activity1(leftTime,CurValue)
	this:Show()
	BieYe_QiYu_Mini_RefreshData_Activity1(leftTime,CurValue)
end

function BieYe_QiYu_Mini_RefreshData_Activity1(leftTime,CurValue)
--this:Show()
	BieYe_QiYu_Mini_DragTitle : SetText("#{JYQY_160810_46}")
	BieYe_QiYu_Mini_Text1:SetText( "当前财源值：")
	BieYe_QiYu_Mini_Text2:SetText( CurValue.."/100")
	BieYe_QiYu_Mini_StopWatch:SetProperty("Timer", tostring(leftTime))
	if leftTime == 0 then
		BieYe_QiYu_Mini_StopWatchText:SetText("")
	else
		BieYe_QiYu_Mini_StopWatchText:SetText("#{JYQY_160810_52}")
	end

end

function BieYe_QiYu_Mini_OpenUI_Activity3(leftTime,CurValue)
	this:Show()
	BieYe_QiYu_Mini_RefreshData_Activity3(leftTime,CurValue)
end

function BieYe_QiYu_Mini_RefreshData_Activity3(leftTime,CurValue)
--this:Show()
	BieYe_QiYu_Mini_DragTitle : SetText("#{JYQY_160810_199}")

	BieYe_QiYu_Mini_Text1:SetText( "舞技熟练度：")
	BieYe_QiYu_Mini_Text2:SetText( CurValue.."/100")
	BieYe_QiYu_Mini_StopWatch:SetProperty("Timer", tostring(leftTime))
	if leftTime == 0 then
		BieYe_QiYu_Mini_StopWatchText:SetText("")
	else
		BieYe_QiYu_Mini_StopWatchText:SetText("#{JYQY_160810_52}")
	end

end


function BieYe_QiYu_Mini_OpenUI_Activity4(leftTime,CurValue)
	this:Show()
	BieYe_QiYu_Mini_RefreshData_Activity4(leftTime,CurValue)
end

function BieYe_QiYu_Mini_RefreshData_Activity4(leftTime,CurValue)
--this:Show()
	BieYe_QiYu_Mini_DragTitle : SetText("#{JYQY_160810_234}")

	BieYe_QiYu_Mini_Text1:SetText( "#{JYQY_160810_235}")
	BieYe_QiYu_Mini_Text2:SetText( CurValue.."/100")
	BieYe_QiYu_Mini_StopWatch:SetProperty("Timer", tostring(leftTime))
	if leftTime == 0 then
		BieYe_QiYu_Mini_StopWatchText:SetText("")
	else
		BieYe_QiYu_Mini_StopWatchText:SetText("#{JYQY_160810_52}")
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYe_QiYu_Mini_ResetPos()
	BieYe_QiYu_Mini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BieYe_QiYu_Mini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 打开活动追踪mini界面
--================================================
function BieYe_QiYu_Mini_Open_UI_Clicked()
	local timer = BieYe_QiYu_Mini_StopWatch:GetProperty("Timer")
	if g_CurActivityMini == 1 then
		PushEvent("BIEYE_ACITVITY1_UI_OPEN",timer,g_CurValueMini)
	elseif g_CurActivityMini == 2 then
	elseif g_CurActivityMini == 3 then
		PushEvent("BIEYE_ACITVITY3_UI_OPEN",timer,g_CurValueMini)
	elseif g_CurActivityMini == 4 then
		PushEvent("BIEYE_ACITVITY4_UI_OPEN",timer,g_CurValueMini)
	end
	this:Hide()
end

