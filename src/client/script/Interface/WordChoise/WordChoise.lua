--	新手指引UI
--	Created by lixiang, may 23th, 2013

local g_Frame;
local g_LastTime = 10000	--	显示持续时间


function WordChoise_PreLoad()
	this:RegisterEvent("CLOSE_FRESHMAN_GUIDE")
	this:RegisterEvent("OPEN_FRESHMANGUIDE_QUESTPOINT")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function WordChoise_OnLoad()
	g_Frame = WordChoiseImageFrame
end

function WordChoise_OnEvent(event)
	if event == "CLOSE_FRESHMAN_GUIDE" then
		WordChoise_CloseFunction()
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED"then
		WordChoise_CloseFunction();
		return
	end

	--	参数列表	父窗口名	显示类型、X位置、Y位置
	if event == "OPEN_FRESHMANGUIDE_QUESTPOINT" then
		local parentName = tostring(arg0)
		local nType = tonumber(arg1)
		local nParPosX = tonumber(arg2)
		local nParPosY = tonumber(arg3)
		if nType == 1 then
			WordChoise_ResetFrame(nParPosX, nParPosY)
		elseif nType == 2 then
			WordChoise_ModifyFrame(nParPosX, nParPosY)
		else
			WordChoise_CloseFunction()
		end
	end
end

function WordChoise_CloseFunction()
	KillTimer("WordChoise_CloseFunction()")
	this:Hide()
end

function WordChoise_ModifyFrame(nPosX, nPosY)
	WordChoise_MoveToPos(nPosX, nPosY)
	this:Show()
end

function WordChoise_ResetFrame(nPosX, nPosY)
	SetTimer("WordChoise", "WordChoise_CloseFunction()", g_LastTime)
	WordChoise_ModifyFrame(nPosX, nPosY)
end

function WordChoise_MoveToPos(nPosX, nPosY)	
	WordChoiseImageFrame:SetProperty("AbsoluteXPosition", nPosX)
	WordChoiseImageFrame:SetProperty("AbsoluteYPosition", nPosY)
	WordChoiseImageFrame:SetProperty("AbsoluteHeight", 35)
	WordChoiseImageFrame:SetProperty("AbsoluteWidth", 100)
end


