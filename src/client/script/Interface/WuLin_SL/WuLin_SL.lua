
local g_WuLin_SL_WuXiang_Image = {
	[1] = "set:GuanShanHai10 image:FoZhang01",
	[2] = "set:GuanShanHai10 image:FoZhang02",
	[3] = "set:GuanShanHai10 image:FoZhang03",
	[4] = "set:GuanShanHai10 image:FoZhang04",
}
local g_WuLin_SL_JinZhongZhao_Image = {
	[1] = "set:GuanShanHai09 image:JinZhongZhao01",
	[2] = "set:GuanShanHai09 image:JinZhongZhao02",
	[3] = "set:GuanShanHai09 image:JinZhongZhao03",
	[4] = "set:GuanShanHai09 image:JinZhongZhao04",
}
local g_WuLin_SL_WuXiang_decade = {}
local g_WuLin_SL_JZZ_decade = {}
function WuLin_SL_PreLoad()
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("SONGLIAOSINGLE_MINI");
	this:RegisterEvent("UI_COMMAND");
end

function WuLin_SL_OnLoad()
	for i = 0,9 do 
		local image = "set:GuanShanHai03 image:QianJi"..i
		table.insert(g_WuLin_SL_WuXiang_decade,i,image)
	end
	for i = 0,9 do 
		local image = "set:GuanShanHai03 image:QianJi"..i
		table.insert(g_WuLin_SL_JZZ_decade,i,image)
	end
end

function WuLin_SL_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		WuLin_SL_JinZhong_ImageNumber:SetProperty("Image",g_WuLin_SL_JZZ_decade[0])
		WuLin_SL_JinZhong_ImageNumber2:SetProperty("Image",g_WuLin_SL_JZZ_decade[0])
		WuLin_SL_WuXiang_ImageNumber:SetProperty("Image",g_WuLin_SL_WuXiang_decade[0])
		WuLin_SL_WuXiang_ImageNumber2:SetProperty("Image",g_WuLin_SL_WuXiang_decade[0])
		this:Hide()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 2020040901 then

		local nOpen = Get_XParam_INT(0)		
		local WXnum = Get_XParam_INT(1)	
		local decade = math.mod(WXnum , 100)
		decade = math.floor(decade / 10)
		local unit = math.mod(WXnum , 10)	
		WuLin_SL_WuXiang_ImageNumber:SetProperty("Image",g_WuLin_SL_WuXiang_decade[decade])
		WuLin_SL_WuXiang_ImageNumber2:SetProperty("Image",g_WuLin_SL_WuXiang_decade[unit])
		local JZZnum = Get_XParam_INT(2)	
		decade = math.mod(JZZnum , 100)
		decade = math.floor(decade / 10)
		local unit = math.mod(JZZnum , 10)	
		WuLin_SL_JinZhong_ImageNumber:SetProperty("Image",g_WuLin_SL_JZZ_decade[decade])
		WuLin_SL_JinZhong_ImageNumber2:SetProperty("Image",g_WuLin_SL_JZZ_decade[unit])
		
		if nOpen ==  1 then
			this:Show()
		else
			this:Hide()
			return
		end

		
		if JZZnum >=20 then
			WuLin_SL_WuXiang_Animate:SetProperty("Image", g_WuLin_SL_WuXiang_Image[4])
		elseif JZZnum >= 15 then
			WuLin_SL_WuXiang_Animate:SetProperty("Image", g_WuLin_SL_WuXiang_Image[3])
		elseif JZZnum >= 10 then
			WuLin_SL_WuXiang_Animate:SetProperty("Image", g_WuLin_SL_WuXiang_Image[2])
		elseif JZZnum >= 5 then
			WuLin_SL_WuXiang_Animate:SetProperty("Image", g_WuLin_SL_WuXiang_Image[1])
		end
		
		if JZZnum >=20 then
			WuLin_SL_JinZhong_Animate:SetProperty("Image", g_WuLin_SL_JinZhongZhao_Image[4])
		elseif JZZnum >= 15 then
			WuLin_SL_JinZhong_Animate:SetProperty("Image", g_WuLin_SL_JinZhongZhao_Image[3])
		elseif JZZnum >= 10 then
			WuLin_SL_JinZhong_Animate:SetProperty("Image", g_WuLin_SL_JinZhongZhao_Image[2])
		elseif JZZnum >= 5 then
			WuLin_SL_JinZhong_Animate:SetProperty("Image", g_WuLin_SL_JinZhongZhao_Image[1])
		end

		
	end
end