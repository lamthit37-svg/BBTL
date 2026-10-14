local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_Current_ParaGraph = 1
function YanmoshanMini_PreLoad()

	this:RegisterEvent("SCENE_TRANSED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("YANMOSHAN_OPEN_MINI")

	this:RegisterEvent("YANMOSHAN_OPEN_RESULT")

end

function YanmoshanMini_OnLoad()

	g_Frame_UnifiedXPosition	= YanmoshanMini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= YanmoshanMini_Frame:GetProperty("UnifiedYPosition");
end



function YanmoshanMini_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
			YanmoshanMini_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
			YanmoshanMini_ResetPos()
	elseif( event == "SCENE_TRANSED" ) then
		local curSceneID = GetSceneID()
		if (curSceneID >=651 and curSceneID <=651 ) then
				g_Current_ParaGraph = 1
				YanmoshanMini_RefreshData();
				this:Show()
		else
			this:Hide()
		end
	--比赛开始，向客户端发送包，显示出来小图片
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20150401 ) then
		g_Current_ParaGraph = tonumber(Get_XParam_INT(1))
		YanmoshanMini_RefreshData();
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20150402 ) then
		g_Current_ParaGraph = tonumber(Get_XParam_INT(1))
		local ListNum	 = tonumber(Get_XParam_INT(2))
		local KilledNum  = tonumber(Get_XParam_INT(3))

		if g_Current_ParaGraph == 2 and ListNum == 6 then
			if KilledNum ==  1 then
				g_Current_ParaGraph = 3
			end
		elseif g_Current_ParaGraph == 1 and ListNum == 4 then
			if KilledNum == 1 then
				g_Current_ParaGraph = 2
			end
		end

		YanmoshanMini_RefreshData();
	elseif( event == "YANMOSHAN_OPEN_MINI" ) then
		YanmoshanMini_RefreshData();
		this:Show()

	--关注一下这个事件，如果结束了；清掉
	elseif( event == "YANMOSHAN_OPEN_RESULT" ) then
		this:Hide()
	end
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function YanmoshanMini_ResetPos()
	YanmoshanMini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	YanmoshanMini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function YanmoshanMini_OpenFame()
	--打开大的UI
	PushEvent("YANMOSHAN_OPEN_RESULT",  0 )
	this:Hide()
end





--================================================
-- 填充数据
--================================================
function YanmoshanMini_RefreshData( )


			if g_Current_ParaGraph == 1 then
				YanmoshanMiniBK1_DragTitle:SetProperty("Visible" , "True" )
				YanmoshanMiniBK2_DragTitle:SetProperty("Visible" , "False" )
				YanmoshanMiniBK3_DragTitle:SetProperty("Visible" , "False" )
				YanmoshanMiniBK1_DragTitle:Show()
				YanmoshanMiniBK2_DragTitle:Hide()
				YanmoshanMiniBK3_DragTitle:Hide()
				YanmoshanMiniBK1_PageHeader:SetProperty("Visible" , "True" )
				YanmoshanMiniBK1_PageHeader:SetText("#{XSHYH_150211_111}")



			elseif g_Current_ParaGraph == 2 then
				YanmoshanMiniBK2_DragTitle:SetProperty("Visible" , "True" )
				YanmoshanMiniBK1_DragTitle:SetProperty("Visible" , "False" )
				YanmoshanMiniBK3_DragTitle:SetProperty("Visible" , "False" )
				YanmoshanMiniBK2_DragTitle:Show()
				YanmoshanMiniBK1_DragTitle:Hide()
				YanmoshanMiniBK3_DragTitle:Hide()
				YanmoshanMiniBK2_PageHeader:SetProperty("Visible" , "True" )
				YanmoshanMiniBK2_PageHeader:SetText("#{XSHYH_150211_112}")

			elseif g_Current_ParaGraph == 3 then
				YanmoshanMiniBK3_DragTitle:SetProperty("Visible" , "True" )
				YanmoshanMiniBK1_DragTitle:SetProperty("Visible" , "False" )
				YanmoshanMiniBK2_DragTitle:SetProperty("Visible" , "False" )

				YanmoshanMiniBK3_DragTitle:Show()
				YanmoshanMiniBK1_DragTitle:Hide()
				YanmoshanMiniBK2_DragTitle:Hide()


				YanmoshanMiniBK3_PageHeader:SetProperty("Visible" , "True" )
				YanmoshanMiniBK3_PageHeader:SetText("#{XSHYH_150211_113}")

			end


end
