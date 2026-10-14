--	新手指引UI
--	Created by lixiang, may 23th, 2013

local g_Frame;
local g_LastTime = 10000

function PointChoise_PreLoad()
	this:RegisterEvent("CLOSE_FRESHMAN_GUIDE")
	this:RegisterEvent("OPEN_FRESHMANGUIDE_AUTOPATH")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function PointChoise_OnLoad()
	g_Frame = PointChoiseImageFrame;
end

function PointChoise_OnEvent(event)
	if event == "CLOSE_FRESHMAN_GUIDE" then
		PointChoise_CloseFunction();
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED"then
		PointChoise_CloseFunction();
		return
	end

	if event == "OPEN_FRESHMANGUIDE_AUTOPATH" then
		local parentName = tostring(arg0)
		local nType = tonumber(arg1)
		local nParPosX = tonumber(arg2)
		local nParPosY = tonumber(arg3)
		if nType == 1 then
			PointChoise_ResetFrame(nParPosX, nParPosY)
		elseif nType == 2 then
			PointChoise_ModifyFrame(nParPosX, nParPosY)
		else
			PointChoise_CloseFunction()
		end
	end
end

function PointChoise_CloseFunction()
	KillTimer("PointChoise_CloseFunction()")
	this:Hide()
end

function PointChoise_ModifyFrame(nPosX, nPosY)
	PointChoise_MoveToPos(nPosX, nPosY)
	this:Show()
end

function PointChoise_ResetFrame(nPosX, nPosY)
	SetTimer("PointChoise", "PointChoise_CloseFunction()", g_LastTime)
	PointChoise_ModifyFrame(nPosX, nPosY)
end

function PointChoise_MoveToPos(nPosX, nPosY)
	g_Frame:SetProperty("AbsoluteXPosition", nPosX)
	g_Frame:SetProperty("AbsoluteYPosition", nPosY)
	g_Frame:SetProperty("AbsoluteHeight", 18)
	g_Frame:SetProperty("AbsoluteWidth", 58)
end
