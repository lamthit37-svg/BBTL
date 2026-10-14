-- 界面的默认相对位置
local g_WuLin_MJ_Frame_UnifiedXPosition;
local g_WuLin_MJ_Frame_UnifiedYPosition;
local g_WuLin_MJ_decade = {}
function WuLin_MJ_PreLoad()
	this:RegisterEvent("UI_COMMAND");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("SCENE_TRANSED",false)
end

function WuLin_MJ_OnLoad()
	-- 保存界面的默认相对位置
	g_WuLin_MJ_Frame_UnifiedXPosition	= WuLin_MJ : GetProperty("UnifiedXPosition");
	g_WuLin_MJ_Frame_UnifiedYPosition	= WuLin_MJ : GetProperty("UnifiedYPosition");
	WuLin_MJ_Animate:Hide()
	--WuLin_MJ_Animate:Hide()
	--WuLin_MJ_Animate:Hide()
	for i = 0,9 do 
		local image = "set:GuanShanHai03 image:QianJi"..i
		table.insert(g_WuLin_MJ_decade,i,image)
	end
end

function WuLin_MJ_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88800101 ) and Get_XParam_INT(0) == 1 then	
		
		WuLin_MJ_Updata(Get_XParam_INT(1))
		this:Show()
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88800101 ) and Get_XParam_INT(0) == 0 then		
		this:Hide()
	
	-- 游戏窗口尺寸发生了变化	
	elseif (event == "ADJEST_UI_POS" ) then
		WuLin_MJ_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_MJ_On_ResetPos()
	
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		
	elseif ( event == "SCENE_TRANSED") then 
		this:Hide()
			
	end
end

--================================================
-- 关闭界面
--================================================
function WuLin_MJ_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function WuLin_MJ_On_ResetPos()

	WuLin_MJ : SetProperty("UnifiedXPosition", g_WuLin_MJ_Frame_UnifiedXPosition);
	WuLin_MJ : SetProperty("UnifiedYPosition", g_WuLin_MJ_Frame_UnifiedYPosition);

end

function WuLin_MJ_Updata(num)
	local minu = num

	local decade = math.mod(minu , 100)
	decade = math.floor(decade / 10)
	local unit = math.mod(minu , 10)
	if decade == 0 then
		WuLin_MJ_ImageNumber3:SetProperty("Image",g_WuLin_MJ_decade[unit])
		WuLin_MJ_ImageNumber3:Show()
		WuLin_MJ_ImageNumber:Hide()
		WuLin_MJ_ImageNumber2:Hide()
	else
		WuLin_MJ_ImageNumber:SetProperty("Image",g_WuLin_MJ_decade[decade])
		WuLin_MJ_ImageNumber2:SetProperty("Image",g_WuLin_MJ_decade[unit])
			WuLin_MJ_ImageNumber3:Hide()
			WuLin_MJ_ImageNumber:Show()
			WuLin_MJ_ImageNumber2:Show()
	end

	if num == 5 then
		--WuLin_MJ_Animate1:replayEffect("UI_zaojia_A")
		WuLin_MJ_Animate:SetProperty("Image", "set:GuanShanHai09 image:MingJiaoHuo02")
		WuLin_MJ_Animate:Show()
	elseif num == 10 then
		--WuLin_MJ_Animate2:replayEffect("UI_zaojia_B")
		WuLin_MJ_Animate:SetProperty("Image", "GuanShanHai10 image:MingJiaoHuo03")
		WuLin_MJ_Animate:Show()
	elseif num == 15 then
		--WuLin_MJ_Animate3:replayEffect("UI_zaojia_C")
		WuLin_MJ_Animate:SetProperty("Image", "GuanShanHai10 image:MingJiaoHuo04")
		WuLin_MJ_Animate:Show()
	else
		WuLin_MJ_Animate:Hide()
		--WuLin_MJ_Animate:Hide()
		--WuLin_MJ_Animate:Hide()
	end
end

function WuLin_MJ_OnHiden()
	this:Hide()
end
