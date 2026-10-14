--装备资质重新洗练二次提醒
local Item_Identify = 0
local g_Arrow_Hong = "set:UIIcons1 image:ZizhiHong";
local g_Arrow_Lv = "set:UIIcons1 image:ZizhiLv";
--===============================================
-- OnLoad()
--===============================================
function IdentifyTwiceQuest_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("UI_COMMAND")
	
end

function IdentifyTwiceQuest_OnLoad()
	-- 保存界面的默认相对位置
	g_IdentifyTwiceQuest_Frame_UnifiedXPosition	= IdentifyTwiceQuest_Frame : GetProperty("UnifiedXPosition");
	g_IdentifyTwiceQuest_Frame_UnifiedYPosition	= IdentifyTwiceQuest_Frame : GetProperty("UnifiedYPosition");
	IdentifyTwiceQuest_Info1:SetText("#{ZBZZYH_170531_31}")
	IdentifyTwiceQuest_Info2:SetText("#{ZBZZYH_170531_32}")
end
--===============================================
-- OnEvent()
--===============================================
function IdentifyTwiceQuest_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 20170613) then	
		Item_Identify = Get_XParam_INT(0);
		IdentifyTwiceQuest_Update()
		this:Show()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		IdentifyTwiceQuest_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		IdentifyTwiceQuest_Frame_On_ResetPos()
	end
end

--===============================================
-- OnHiden
--===============================================
function IdentifyTwiceQuest_Frame_OnHiden()
	if(IsWindowShow("AntiJDY")) then    --简单游互斥界面显示时，不激活快捷键 for 69994
	else
		DataPool:SetCanUseHotKey(1);
	end
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function IdentifyTwiceQuest_Frame_On_ResetPos()

	IdentifyTwiceQuest_Frame : SetProperty("UnifiedXPosition", g_IdentifyTwiceQuest_Frame_UnifiedXPosition);
	IdentifyTwiceQuest_Frame : SetProperty("UnifiedYPosition", g_IdentifyTwiceQuest_Frame_UnifiedYPosition);

end

function IdentifyTwiceQuest_Bn1Click()
	PushEvent("IDENTIFYTWICEQUEST_CONFIRM_RET",1)
	this:Hide()
end
function IdentifyTwiceQuest_Bn2Click()
	PushEvent("IDENTIFYTWICEQUEST_CONFIRM_RET",0)
	this:Hide()
end

function IdentifyTwiceQuest_Update()
	if(Item_Identify ~= -1) then
		local strOldIdentify = DataPool:GetEquipZiZhiDesc(Item_Identify)
		IdentifyTwiceQuest_qualityInfo1:SetText("\n"..strOldIdentify)

		local strNewIdentify = DataPool : GetEquipZiZhiRefreshDesc(Item_Identify);
		IdentifyTwiceQuest_qualityInfo2:SetText("\n"..strNewIdentify)
		IdentifyTwiceQuest_Arrow1:SetProperty("Image","")
		IdentifyTwiceQuest_Arrow2:SetProperty("Image","")
		IdentifyTwiceQuest_Arrow3:SetProperty("Image","")
		local type1,value1,type2,value2 = DataPool : GetEquipZiZhiCompare(Item_Identify);
		if(type1 ~= nil and type1 >= 0 and type2 ~= nil and type2 >= 0) then
			if(value1 > 0) then
				IdentifyTwiceQuest_Arrow3:SetProperty("Image",g_Arrow_Lv)
			end
			if(value1 < 0) then
				IdentifyTwiceQuest_Arrow3:SetProperty("Image",g_Arrow_Hong)
			end
			if(value2 > 0) then
				IdentifyTwiceQuest_Arrow1:SetProperty("Image",g_Arrow_Lv)
			end
			if(value2 < 0) then
				IdentifyTwiceQuest_Arrow1:SetProperty("Image",g_Arrow_Hong)
			end
		else
			if(type1 ~= nil and type1 >= 0) then
				if(value1 > 0) then
					IdentifyTwiceQuest_Arrow2:SetProperty("Image",g_Arrow_Lv)
				end
				if(value1 < 0) then
					IdentifyTwiceQuest_Arrow2:SetProperty("Image",g_Arrow_Hong)
				end
			end
		end
		DataPool:SetCanUseHotKey(0);
	end
end
