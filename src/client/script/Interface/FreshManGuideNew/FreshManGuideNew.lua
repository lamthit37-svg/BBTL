
local g_AnimateInterFace = nil
local g_Frame_Width =43
local g_Frame_Height = 84

local g_Step = -2
local g_ArrowTextList = 
{
	[1]  = {strName = "FreshMan_LeftMouse_Flash", dTime = 20000 },			--	
	[2]  = {strName = "FreshMan_RightMouse_Flash", dTime = 20000 },			--	
	[3]  = {strName = "FreshMan_WASD_Flash", dTime = 20000 },		--	
}


local g_ArrowSizeList = 
{
	[1]  = {width = 43, height = 84},
	[2]  = {width = 43, height = 84},
	[3]  = {width = 100, height = 65},
}
function FreshManGuideNew_PreLoad()
	this:RegisterEvent("OPEN_FRESHMAN_GUIDE_NEW2013Q3")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("CLOSE_FRESHMAN_GUIDE")
	this:RegisterEvent("GAMELOGIN_SELECTCHARACTER")
end



function FreshManGuideNew_OnLoad()
	g_AnimateInterFace=FreshManGuideNew_Frame
	--g_Frame_Width  = g_AnimateInterFace:GetProperty("AbsoluteWidth")
	--g_Frame_Height = g_AnimateInterFace:GetProperty("AbsoluteHeight")	
end

function FreshManGuideNew_OnEvent(event)
	if event == "OPEN_FRESHMAN_GUIDE_NEW2013Q3" then
		FreshManGuideNew_ResetSize(tonumber(arg0),tonumber(arg1),tonumber(arg2))
		SetTimer("FreshManGuideNew", "FreshManGuideNew_Close()", 20000)
		this:Show()
	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then

		--将鼠标固定到泡泡的右下角右上侧
 		--获得Client分辨率
		local nWidth ,nHeight = GetCurClientSize()
		local TempX = math.floor(tonumber(nWidth/24)) + 300 
		local TempY = -math.floor(tonumber(nHeight/2.8)) + 400
		
		--取合适坐标
		local ScreenXPoint = "{0.5,"..TempX.."}"
		local ScreenYPoint = "{0.5,"..TempY.."}"

		FreshManGuideNew_Frame : SetProperty("UnifiedXPosition", ScreenXPoint);
		FreshManGuideNew_Frame : SetProperty("UnifiedYPosition", ScreenYPoint);

	elseif event == "GAMELOGIN_SELECTCHARACTER" then
		g_Step = -2
	elseif event == "CLOSE_FRESHMAN_GUIDE" then
		local temp = DataPool:GetCurrentFreshManGuideItemValue()

		if temp == 100 then
			g_Step = -1
			DataPool:SetCurrentFreshManGuideItemValue(0)
		end
		if g_Step ~= -2 then
			FreshManGuideNew_Close()
		end

	end
end

function FreshManGuideNew_Close()
	if not this:IsVisible() then
		return
	end
	
	KillTimer("FreshManGuideNew_Close()")
	this:Hide()
end
function FreshManGuideNew_To(nXPos, nYPos)
	FreshManGuideNew_Frame:SetProperty("AbsoluteXPosition", nXPos)
	FreshManGuideNew_Frame:SetProperty("AbsoluteYPosition", nYPos)
end

function FreshManGuideNew_ResetSize(nIndex,nPosX, nPosY)
	FreshManGuideNew_To(nPosX+300,nPosY+400)
	FreshManGuideNew_Frame:SetProperty("AbsoluteHeight", g_ArrowSizeList[nIndex].height)
	FreshManGuideNew_Frame:SetProperty("AbsoluteWidth", g_ArrowSizeList[nIndex].width)

	FreshManGuideNew_Frame:SetProperty("Animate", g_ArrowTextList[nIndex].strName)
	
end

function FreshManGuideNew_OnHide()

		this:Hide()
end