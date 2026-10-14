local g_Expansion_Grade_Yindao_Frame_UnifiedXPosition
local g_Expansion_Grade_Yindao_Frame_UnifiedYPosition

local g_Expansion_Grade_Yindao_Image = {
[1] = {image = "set:Expansion_Grade_Yindao1 image:Expansion_Grade_Yindao_Bk1", Tooltip = "", },			
[2] = {image = "set:Expansion_Grade_Yindao1 image:Expansion_Grade_Yindao_Bk2", Tooltip = "",},			
[3] = {image = "set:Expansion_Grade_Yindao2 image:Expansion_Grade_Yindao_Bk3", Tooltip = "",},		
[4] = {image = "set:Expansion_Grade_Yindao2 image:Expansion_Grade_Yindao_Bk4", Tooltip = "",},
[5] = {image = "set:Expansion_Grade_Yindao3 image:Expansion_Grade_Yindao_Bk5", Tooltip = "",},
}	

local g_Expansion_Grade_Yindao_CurPage = 1

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Expansion_Grade_Yindao_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Expansion_Grade_Yindao_OnLoad()
	-- 保存界面的默认相对位置
	g_Expansion_Grade_Yindao_Frame_UnifiedXPosition	= Expansion_Grade_Yindao_Frame:GetProperty("UnifiedXPosition");
	g_Expansion_Grade_Yindao_Frame_UnifiedYPosition	= Expansion_Grade_Yindao_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Expansion_Grade_Yindao_ResetPos()
	Expansion_Grade_Yindao_Frame:SetProperty("UnifiedXPosition", g_Expansion_Grade_Yindao_Frame_UnifiedXPosition);
	Expansion_Grade_Yindao_Frame:SetProperty("UnifiedYPosition", g_Expansion_Grade_Yindao_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Expansion_Grade_Yindao_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 99974401 then
		--打开界面
		Expansion_Grade_Yindao_Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Expansion_Grade_Yindao_OnHide()
	elseif event == "ADJEST_UI_POS" then
		Expansion_Grade_Yindao_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Expansion_Grade_Yindao_ResetPos()
	end
end

--显示UI
function Expansion_Grade_Yindao_Show()
	g_Expansion_Grade_Yindao_CurPage =1
	Expansion_Grade_Yindao_ImageBk : SetProperty("Image",g_Expansion_Grade_Yindao_Image[g_Expansion_Grade_Yindao_CurPage].image);
	Expansion_Grade_Yindao_LeftArrow : Disable()
	Expansion_Grade_Yindao_RightArrow : Enable()
	this:Show()
end

function Expansion_Grade_Yindao_Page_Left()
	if g_Expansion_Grade_Yindao_CurPage <= 1 then
		return
	end
	g_Expansion_Grade_Yindao_CurPage = g_Expansion_Grade_Yindao_CurPage -1
	if g_Expansion_Grade_Yindao_CurPage < 1 then
		g_Expansion_Grade_Yindao_CurPage = 1
	end
	if g_Expansion_Grade_Yindao_Image[g_Expansion_Grade_Yindao_CurPage] ~= nil then
		Expansion_Grade_Yindao_ImageBk : SetProperty("Image",g_Expansion_Grade_Yindao_Image[g_Expansion_Grade_Yindao_CurPage].image);
	end
	if g_Expansion_Grade_Yindao_CurPage == 1 then
		Expansion_Grade_Yindao_LeftArrow : Disable()
		Expansion_Grade_Yindao_RightArrow : Enable()
	else
		Expansion_Grade_Yindao_LeftArrow : Enable()
		Expansion_Grade_Yindao_RightArrow : Enable()
	end
end

function Expansion_Grade_Yindao_Page_Right()
	if g_Expansion_Grade_Yindao_CurPage >= table.getn(g_Expansion_Grade_Yindao_Image) then
		return
	end
	g_Expansion_Grade_Yindao_CurPage = g_Expansion_Grade_Yindao_CurPage +1
	if g_Expansion_Grade_Yindao_CurPage > table.getn(g_Expansion_Grade_Yindao_Image) then
		g_Expansion_Grade_Yindao_CurPage = table.getn(g_Expansion_Grade_Yindao_Image)
	end
	if g_Expansion_Grade_Yindao_Image[g_Expansion_Grade_Yindao_CurPage] ~= nil then
		Expansion_Grade_Yindao_ImageBk : SetProperty("Image",g_Expansion_Grade_Yindao_Image[g_Expansion_Grade_Yindao_CurPage].image);
	end
	if g_Expansion_Grade_Yindao_CurPage == table.getn(g_Expansion_Grade_Yindao_Image) then
		Expansion_Grade_Yindao_LeftArrow : Enable()
		Expansion_Grade_Yindao_RightArrow : Disable()
		--查看了最后一页，任务完成
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnMissionCom")
			Set_XSCRIPT_ScriptID(999740)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	else
		Expansion_Grade_Yindao_LeftArrow : Enable()
		Expansion_Grade_Yindao_RightArrow : Enable()
	end
end

--隐藏UI
function Expansion_Grade_Yindao_OnHide()
	this:Hide()
end

--关闭界面
function Expansion_Grade_Yindao_OnClose()
	this:Hide()
end


