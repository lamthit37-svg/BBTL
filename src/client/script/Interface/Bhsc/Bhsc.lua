local strList = {
	tip1 = "#{BHXH_QTE_XML_01}" ,
	tip2 = "#{BHXH_QTE_XML_08}#{BHXH_QTE_XML_02}" ,
}

local opList = {
	[1]  = "#{BHXH_QTE_XML_03}" ,
	[2]  = "#{BHXH_QTE_XML_04}" ,
	[3]  = "#{BHXH_QTE_XML_05}" ,
	[4]  = "#{BHXH_QTE_XML_06}" ,
}

local opImage = {
	[1] = "set:CommonLiveSkill3 image:CommonLiveSkill3_13" ,
	[2] = "set:CommonLiveSkill3 image:CommonLiveSkill3_11" ,
	[3] = "set:CommonLiveSkill3 image:CommonLiveSkill3_12" ,
	[4] = "set:CommonLiveSkill3 image:CommonLiveSkill3_15" ,
}
	
local Bhsc_UnifiedPosition
function Bhsc_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("CLOSE_AGNAME");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Bhsc_OnLoad()
	Bhsc_UnifiedPosition=Bhsc_Frame:GetProperty("UnifiedPosition");
end

function Bhsc_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 20110603 then
		if Get_XParam_INT(0) == 0 then
			this:Hide()
		end
		
		if Get_XParam_INT(0) == 1 then
			this:Show()
			local op = Get_XParam_INT(1)
			if op >= 1 and op <= 4 then
				Bhsc_Frame_Client:SetText(strList.tip1..opList[op]..strList.tip2)
				Bhsc_PlayerHead:SetProperty("Image" , opImage[op])
			end
			Bhsc_Jishi_Client:SetProperty("Timer","5")
		end 
	end
	
	if (event == "ADJEST_UI_POS" ) then
		Bhsc_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Bhsc_On_ResetPos()
	end	
end

function Bhsc_OnCloseClicked()
	this:Hide()
end

function Bhsc_Jishi_TimeReach() 
	Bhsc_Jishi_Client:SetProperty("Timer","0")
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Bhsc_On_ResetPos()
  Bhsc_Frame:SetProperty("UnifiedPosition", Bhsc_UnifiedPosition);
end
