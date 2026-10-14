-- 无差别争霸赛操作手册
--
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_ReadMeFrameList = {}

local g_NoDiffMatch_Readme_CurPage = 1;

local g_NoDiffMatch_Readme_MaxPage = 11;

function NoDiffMatch_Readme_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function NoDiffMatch_Readme_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= NoDiffMatch_Readme_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= NoDiffMatch_Readme_Frame:GetProperty("UnifiedYPosition");

	g_ReadMeFrameList[1] = NoDiffMatch_Readme_Frame1;
	g_ReadMeFrameList[2] = NoDiffMatch_Readme_Frame2;
	g_ReadMeFrameList[3] = NoDiffMatch_Readme_Frame3;
	g_ReadMeFrameList[4] = NoDiffMatch_Readme_Frame4;
	g_ReadMeFrameList[5] = NoDiffMatch_Readme_Frame5;
	g_ReadMeFrameList[6] = NoDiffMatch_Readme_Frame6;
	g_ReadMeFrameList[7] = NoDiffMatch_Readme_Frame7;
	g_ReadMeFrameList[8] = NoDiffMatch_Readme_Frame8;
	g_ReadMeFrameList[9] = NoDiffMatch_Readme_Frame9;
	g_ReadMeFrameList[10] = NoDiffMatch_Readme_Frame10;
	g_ReadMeFrameList[11] = NoDiffMatch_Readme_Frame11;
	
	g_NoDiffMatch_Readme_CurPage = 1;
end

function NoDiffMatch_Readme_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		NoDiffMatch_Readme_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NoDiffMatch_Readme_ResetPos()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 89279501) then		
		if(IsWindowShow("NoDiffMatch_Readme")) then
			CloseWindow("NoDiffMatch_Readme", true)
			return
		end
		
		if g_NoDiffMatch_Readme_CurPage == 1 then
			NoDiffMatch_Readme_Pre:Disable()
		else
			NoDiffMatch_Readme_Pre:Enable()
		end
		
		if g_NoDiffMatch_Readme_CurPage == g_NoDiffMatch_Readme_MaxPage then
			NoDiffMatch_Readme_Next:Disable()
		else
			NoDiffMatch_Readme_Next:Enable()
		end
		
		for idx = 1, g_NoDiffMatch_Readme_MaxPage do
			if idx == g_NoDiffMatch_Readme_CurPage then
				g_ReadMeFrameList[idx]:Show()
			else
				g_ReadMeFrameList[idx]:Hide()
			end
		end
	
		this:Show()
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function NoDiffMatch_Readme_ResetPos()
	NoDiffMatch_Readme_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	NoDiffMatch_Readme_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function NoDiffMatch_ReadmeFrame_CloseWindow()
	this:Hide()
end

function NoDiffMatch_Readme_Pre_Click()
    if g_NoDiffMatch_Readme_CurPage < 1 or g_NoDiffMatch_Readme_CurPage > g_NoDiffMatch_Readme_MaxPage then
		g_NoDiffMatch_Readme_CurPage = 1
    end
	
	if g_NoDiffMatch_Readme_CurPage - 1 <= 1 then
		g_NoDiffMatch_Readme_CurPage = 1
		NoDiffMatch_Readme_Pre:Disable()
		NoDiffMatch_Readme_Next:Enable()
	else
		NoDiffMatch_Readme_Pre:Enable()
		NoDiffMatch_Readme_Next:Enable()
		g_NoDiffMatch_Readme_CurPage = g_NoDiffMatch_Readme_CurPage - 1
	end	
   
	for idx = 1, g_NoDiffMatch_Readme_MaxPage do
		if idx == g_NoDiffMatch_Readme_CurPage then
			g_ReadMeFrameList[idx]:Show()
		else
			g_ReadMeFrameList[idx]:Hide()
		end
	end
end

function NoDiffMatch_Readme_Next_Click()
    if g_NoDiffMatch_Readme_CurPage < 1 or g_NoDiffMatch_Readme_CurPage > g_NoDiffMatch_Readme_MaxPage then
		g_NoDiffMatch_Readme_CurPage = g_NoDiffMatch_Readme_MaxPage
    end
	
	if g_NoDiffMatch_Readme_CurPage + 1 >= g_NoDiffMatch_Readme_MaxPage then
		g_NoDiffMatch_Readme_CurPage = g_NoDiffMatch_Readme_MaxPage
		NoDiffMatch_Readme_Pre:Enable()
		NoDiffMatch_Readme_Next:Disable()
	else
		NoDiffMatch_Readme_Pre:Enable()
		NoDiffMatch_Readme_Next:Enable()
		g_NoDiffMatch_Readme_CurPage = g_NoDiffMatch_Readme_CurPage + 1
	end	
   
	for idx = 1, g_NoDiffMatch_Readme_MaxPage do
		if idx == g_NoDiffMatch_Readme_CurPage then
			g_ReadMeFrameList[idx]:Show()
		else
			g_ReadMeFrameList[idx]:Hide()
		end
	end
end
