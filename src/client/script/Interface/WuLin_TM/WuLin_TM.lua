local g_WuLin_TM_decade = {}
local g_WuLin_TM_Effect = {
	[1] = "set:GuanShanHai03 image:QianJi25",
	[2] = "set:GuanShanHai03 image:QianJi50",
	[3] = "set:GuanShanHai03 image:QianJi75",
}

local WuLIn_TM_nlast = 0
local WuLIn_TM_texiao = 0
function WuLin_TM_PreLoad()
	this:RegisterEvent("REFRESH_SONGLIAOWAR_SINGLE_SCORE");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("SONGLIAOSINGLE_MINI");
	this:RegisterEvent("UI_COMMAND");
end

function WuLin_TM_OnLoad()
	for i = 0,9 do 
		local image = "set:GuanShanHai03 image:QianJi"..i
		table.insert(g_WuLin_TM_decade,i,image)
	end
	WuLIn_TM_texiao = 0
    WuLIn_TM_nlast = 0
end

function WuLin_TM_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		WuLin_TM_ImageNumber:SetProperty("Image",g_WuLin_TM_decade[0])
		WuLin_TM_ImageNumber:SetProperty("Image",g_WuLin_TM_decade[0])
		this:Hide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2020040902 then
		local nOpen = Get_XParam_INT(0)		
		local nProcess = Get_XParam_INT(1)		
		
		if nOpen ==  1 then
			this:Show()
		else
			this:Hide()
		end
		local decade = math.mod(nProcess , 100)
		decade = math.floor(decade / 10)
		local unit = math.mod(nProcess , 10)
	
		WuLin_TM_ImageNumber:SetProperty("Image",g_WuLin_TM_decade[decade])
		WuLin_TM_ImageNumber2:SetProperty("Image",g_WuLin_TM_decade[unit])

		--WuLin_TM_Text:SetText(nProcess)
		WuLIn_TM_texiao = 0

		if nProcess >= 75 then

			WuLin_TM_Image1:Show()

			WuLin_TM_Image1:SetProperty("Image",g_WuLin_TM_Effect[3])
		elseif nProcess >= 50 then

			WuLin_TM_Image1:Show()

			WuLin_TM_Image1:SetProperty("Image",g_WuLin_TM_Effect[2])
		elseif nProcess >= 25 then

			WuLin_TM_Image1:Show()
			
			WuLin_TM_Image1:SetProperty("Image",g_WuLin_TM_Effect[1])
		elseif nProcess >= 0 then

			WuLIn_TM_texiao = 0
			WuLin_TM_Image1:Hide()
		end

		
		if WuLIn_TM_nlast > nProcess  then
			WuLIn_TM_nlast = nProcess
			WuLin_TM_Animate1:Play( true )
			WuLin_TM_Animate2:Play( true )
		end
	end
end
