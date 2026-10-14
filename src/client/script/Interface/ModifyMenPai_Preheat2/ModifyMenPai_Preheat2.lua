local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function ModifyMenPai_Preheat2_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("SCENE_TRANSED")
end

function ModifyMenPai_Preheat2_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition = ModifyMenPai_Preheat2_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition = ModifyMenPai_Preheat2_Frame:GetProperty("UnifiedYPosition");		
end

function ModifyMenPai_Preheat2_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		ModifyMenPai_Preheat2_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ModifyMenPai_Preheat2_ResetPos()
	elseif( event == "SCENE_TRANSED") then
		this:Hide()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 89295103) then	
		local param0 = Get_XParam_INT(0)
		local param1 = Get_XParam_INT(1)
		local param2 = Get_XParam_INT(2)
		local param3 = Get_XParam_INT(3)
		local param4 = Get_XParam_INT(4)
		if param0 == 1 then
			ModifyMenPai_Preheat2_UpdateUI(param1, param2, param3, param4)
			this:Show()
		elseif param0 == 99 then
			if this:IsVisible() then
				ModifyMenPai_Preheat2_UpdateUI(param1, param2, param3, param4)
				this:Show()				
			end		
		else
			this:Hide()
		end
	end
end

function ModifyMenPai_Preheat2_UpdateUI(param1, param2, param3, param4)
	
	ModifyMenPai_Preheat2_ClientBK:Show()
	
	ModifyMenPai_Preheat2_UpPageClient:Show()
	ModifyMenPai_Preheat2_UpPage:Show()
	
	ModifyMenPai_Preheat2_DownPageClient:Show()
	ModifyMenPai_Preheat2_DownPage:Show()
	
	ModifyMenPai_Preheat2_ClientPic1Cut1Text:SetText("")
	ModifyMenPai_Preheat2_ClientPic1Cut2Text:SetText("")
	ModifyMenPai_Preheat2_ClientPic1Cut3Text:SetText("")
	
	ModifyMenPai_Preheat2_ClientPic1Cut:Show()
	ModifyMenPai_Preheat2_ClientPic1CutTitle:Show()
	
	ModifyMenPai_Preheat2_ClientPic1Text:SetText("")
	
	if param1 == 1 and param2 == 1 and param3 == 1 then
	
		ModifyMenPai_Preheat2_ClientPic1Cut1Frame:Hide()
		ModifyMenPai_Preheat2_ClientPic1Cut2Frame:Hide()
		ModifyMenPai_Preheat2_ClientPic1Cut3Frame:Hide()
		ModifyMenPai_Preheat2_ClientPic1Frame:Show()
		
		if param4 == 1 then
			ModifyMenPai_Preheat2_ClientPic1Text:SetText("#{ZPRW_180928_242}")
		elseif param4 == 2 then
			ModifyMenPai_Preheat2_ClientPic1Text:SetText("#{ZPRW_180928_243}")
		elseif param4 == 3 then
			ModifyMenPai_Preheat2_ClientPic1Text:SetText("#{ZPRW_180928_244}")
		elseif param4 == 4 then
			ModifyMenPai_Preheat2_ClientPic1Text:SetText("#{ZPRW_180928_245}")
		end
		
	else
		
		ModifyMenPai_Preheat2_ClientPic1Frame:Hide()		
		ModifyMenPai_Preheat2_ClientPic1Cut1Frame:Show()
		ModifyMenPai_Preheat2_ClientPic1Cut2Frame:Show()
		ModifyMenPai_Preheat2_ClientPic1Cut3Frame:Show()
		
		if param1 == 1 then
			ModifyMenPai_Preheat2_ClientPic1Cut1Grey:Hide()
			ModifyMenPai_Preheat2_ClientPic1Cut1:Show()
			--ModifyMenPai_Preheat2_ClientPic1Cut1Text:SetText("#{ZPRW_180928_09}")
		else
			ModifyMenPai_Preheat2_ClientPic1Cut1:Hide()
			ModifyMenPai_Preheat2_ClientPic1Cut1Grey:Show()
			ModifyMenPai_Preheat2_ClientPic1Cut1Text:SetText("#{ZPRW_180928_08}")
		end

		if param2 == 1 then
			ModifyMenPai_Preheat2_ClientPic1Cut2Grey:Hide()
			ModifyMenPai_Preheat2_ClientPic1Cut2:Show()
			--ModifyMenPai_Preheat2_ClientPic1Cut2Text:SetText("#{ZPRW_180928_11}")
		else
			ModifyMenPai_Preheat2_ClientPic1Cut2:Hide()
			ModifyMenPai_Preheat2_ClientPic1Cut2Grey:Show()
			ModifyMenPai_Preheat2_ClientPic1Cut2Text:SetText("#{ZPRW_180928_10}")
		end

		if param3 == 1 then
			ModifyMenPai_Preheat2_ClientPic1Cut3Grey:Hide()
			ModifyMenPai_Preheat2_ClientPic1Cut3:Show()
			--ModifyMenPai_Preheat2_ClientPic1Cut3Text:SetText("#{ZPRW_180928_13}")
		else
			ModifyMenPai_Preheat2_ClientPic1Cut3:Hide()
			ModifyMenPai_Preheat2_ClientPic1Cut3Grey:Show()
			ModifyMenPai_Preheat2_ClientPic1Cut3Text:SetText("#{ZPRW_180928_12}")
		end
	
	end
	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ModifyMenPai_Preheat2_ResetPos()
	ModifyMenPai_Preheat2_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ModifyMenPai_Preheat2_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function ModifyMenPai_Preheat2_Close()
	this:Hide()
end
