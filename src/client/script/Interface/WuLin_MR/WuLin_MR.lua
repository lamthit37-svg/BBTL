local g_WuLin_MR_decade = {}
local g_WuLin_MR_Image = {
	[1] = "set:GuanShanHai09 image:CangJian04",
	[2] = "set:GuanShanHai10 image:CangJian03",
	[3] = "set:GuanShanHai10 image:CangJian02",
	[4] = "set:GuanShanHai10 image:CangJian01",
}
function WuLin_MR_PreLoad()
	this:RegisterEvent("REFRESH_SONGLIAOWAR_SINGLE_SCORE");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("SONGLIAOSINGLE_MINI");
	this:RegisterEvent("UI_COMMAND");
end

function WuLin_MR_OnLoad()
	for i = 0,9 do 
		local image = "set:GuanShanHai03 image:QianJi"..i
		table.insert(g_WuLin_MR_decade,i,image)
	end
end

function WuLin_MR_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		WuLin_MR_ImageNumber:SetProperty("Image",g_WuLin_MR_decade[0])
		WuLin_MR_ImageNumber2:SetProperty("Image",g_WuLin_MR_decade[0])
		this:Hide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2020040903 then
		local nOpen = Get_XParam_INT(0)		
		local num = Get_XParam_INT(1)	
		
		local decade = math.mod(num , 100)
		decade = math.floor(decade / 10)
		local unit = math.mod(num , 10)

		WuLin_MR_ImageNumber:SetProperty("Image",g_WuLin_MR_decade[decade])
		WuLin_MR_ImageNumber2:SetProperty("Image",g_WuLin_MR_decade[unit])

		if nOpen ==  1 then
			this:Show()
		else
			this:Hide()
		end

		if num >= 10 and num < 20 then
			WuLin_MR_Animate:SetProperty("Image", g_WuLin_MR_Image[3])
		elseif num < 10 then
			WuLin_MR_Animate:SetProperty("Image", g_WuLin_MR_Image[2])
		end
	end
end
