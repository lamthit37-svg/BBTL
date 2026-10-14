function PullPCU_PreLoad()
	this:RegisterEvent("UI_COMMAND");
end

function PullPCU_OnLoad()
end

function PullPCU_Watch1TimeOut()
	--PullPCU_Frame:SetProperty("UnifiedSize", "{{0.000000,66.000000},{0.000000,66.000000}}" )
	--PullPCU_Animate:SetProperty("Visible", "True")
	--策划要不同的奖励显示不同的界面，晕死，只有到服务器请求一次了
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ReqTheReawardType" )
		Set_XSCRIPT_ScriptID( 889450 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function PullPCU_Watch2TimeOut()
	if(this:IsVisible()) then
		--PullPCU_Animate:SetProperty("Visible", "False")
		this:Hide()
		--PushEvent("PULLPCU_CHANGESTATE")
	end
end

function PullPCU_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20110630 ) then
		local state = Get_XParam_INT(0)--表示该UICommand是玩家领取buff时发送的，还是领奖成功后发送的
		if state == 1 then
			PullPCU_Frame:SetProperty("UnifiedSize", "{{0.000000,0.000000},{0.000000,0.000000}}" )
			PullPCU_StopWatch1:SetProperty("Timer",tostring(3600));--一小时
			PullPCU_StopWatch2:SetProperty("Timer",tostring(5400));--1.5小时
			this:Show()
		end
		if state == 2 then
			--FlashPacketButton()
			--PullPCU_Animate:SetProperty("Visible", "False")
			this:Hide()
		end
		if state == 3 then
			local ReawardType = Get_XParam_INT(1)
			if ReawardType == 0 then ---乾坤丹
				PullPCU_Frame:SetProperty("UnifiedSize", "{{0.000000,66.000000},{0.000000,66.000000}}" )
				PullPCU_Animate1:SetProperty("Visible", "True")
			elseif ReawardType == 1 then --玄灵丹
				PullPCU_Frame:SetProperty("UnifiedSize", "{{0.000000,66.000000},{0.000000,66.000000}}" )
				PullPCU_Animate2:SetProperty("Visible", "True")
			end
		end
	end		
	
end

function PullPCU_ButtonClick()
	local isInHell = IsInHell()
	if isInHell == 1 then--在地府中不能领取奖品
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetTheAward" )
		Set_XSCRIPT_ScriptID( 889450 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
