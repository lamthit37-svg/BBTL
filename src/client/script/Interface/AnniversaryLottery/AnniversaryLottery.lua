local g_AnniversaryLottery_Frame_UnifiedPosition;

--===============================================
-- PreLoad()
--===============================================
function AnniversaryLottery_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD",false)		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)		-- 进入游戏世界
	this:RegisterEvent("UPDATE_ZHOUNIANYUAN_NAME",false )	
	this:RegisterEvent("UPDATE_QIANWEN",true )	
end

--===============================================
-- OnEvent()
--===============================================
function AnniversaryLottery_OnEvent(event)

	if( event == "UPDATE_QIANWEN"  ) then
		local nQianWenIndex = tonumber(arg0)
		if 3 == nQianWenIndex then
			AnniversaryLottery_Page0_BK:Show()
			AnniversaryLottery_Page1_BK:Hide()
			AnniversaryLottery_Page2_BK:Hide()
			this:Show()
		elseif 2 == nQianWenIndex then
			AnniversaryLottery_Page0_BK:Hide()
			AnniversaryLottery_Page1_BK:Show()
			AnniversaryLottery_Page2_BK:Hide()
			this:Show()
		elseif 1 == nQianWenIndex then
			AnniversaryLottery_Page0_BK:Hide()
			AnniversaryLottery_Page1_BK:Hide()
			AnniversaryLottery_Page2_BK:Show()
			this:Show()
		end

	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	elseif (event == "ADJEST_UI_POS") then
		AnniversaryLottery_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		AnniversaryLottery_On_ResetPos()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20180417) then
		local nQianWenIndex = Get_XParam_INT(0);

		if 3 == nQianWenIndex then
			AnniversaryLottery_Page0_BK:Show()
			AnniversaryLottery_Page1_BK:Hide()
			AnniversaryLottery_Page2_BK:Hide()
			this:Show()
		elseif 2 == nQianWenIndex then
			AnniversaryLottery_Page0_BK:Hide()
			AnniversaryLottery_Page1_BK:Show()
			AnniversaryLottery_Page2_BK:Hide()
			this:Show()
		elseif 1 == nQianWenIndex then
			AnniversaryLottery_Page0_BK:Hide()
			AnniversaryLottery_Page1_BK:Hide()
			AnniversaryLottery_Page2_BK:Show()
			this:Show()
		end

	end
end

--===============================================
-- OnLoad()
--===============================================
function AnniversaryLottery_OnLoad()

	g_AnniversaryLottery_Frame_UnifiedPosition = AnniversaryLottery_Frame:GetProperty("UnifiedPosition")
	

end


--===============================================
-- Hide()
--===============================================
function AnniversaryLottery_Hide() 	

end

--===============================================
-- Close()
--===============================================
function AnniversaryLottery_Close() 

	this:Hide();
end
--===============================================
-- ResetPos()
--===============================================
function AnniversaryLottery_On_ResetPos()
	AnniversaryLottery_Frame:SetProperty("UnifiedPosition", g_AnniversaryLottery_Frame_UnifiedPosition)
end

--===============================================
-- Open()
--===============================================
function  AnniversaryLottery_Open()


end


