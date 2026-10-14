--蒸粽子
local g_Zhuzongzi_UnifiedPosition;

local g_Zhuzongzi_bagIndex = -1

local g_Zhuzongzi_LeftTime = 0

local g_Zhuzongzi_State = 0

local g_Zhuzongzi_Finish = 0

local g_Zhuzongzi_IsGetGift = 0

local g_Zhuzongzi_Image = {
	[1] = "set:Zhuzongzi1 image:Zongzi_Danhuangzong",
	[2] = "set:Zhuzongzi1 image:Zongzi_Dazaozong",
	[3] = "set:Zhuzongzi1 image:Zongzi_Rouzong",
}

function Zhuzongzi_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function Zhuzongzi_OnLoad()
	g_Zhuzongzi_UnifiedPosition = Zhuzongzi_Frame:GetProperty("UnifiedPosition")
	
end

function Zhuzongzi_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99801802 ) then 
		
		if Get_XParam_INT(0) == 0 then
			Zhuzongzi_OnHide()
			return 
		end
		
		if Get_XParam_INT(0) == 2 then
			--Zhuzongzi_Goto()
			Zhuzongzi_Close:Show()
			Zhuzongzi_After_Succeed_GetButton:Hide()
			return 
		end

		if IsWindowShow("SpecialGift_ThreeChoiceTongyong") then
			CloseWindow("SpecialGift_ThreeChoiceTongyong", true);
		end
		
		g_Zhuzongzi_bagIndex = Get_XParam_INT(1)
		g_Zhuzongzi_Choose = Get_XParam_INT(2)
		g_Zhuzongzi_State = Get_XParam_INT(3)
		g_Zhuzongzi_Finish = Get_XParam_INT(4)
		g_Zhuzongzi_IsGetGift = Get_XParam_INT(5)
		g_Zhuzongzi_LeftTime = Get_XParam_INT(6)
		
		Zhuzongzi_OnShow()
	
	elseif (event == "ADJEST_UI_POS" ) then
		Zhuzongzi_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Zhuzongzi_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Zhuzongzi_OnHide()
	end

end

--=========================================================
--初始化界面
--=========================================================
function Zhuzongzi_OnShow()

	this:Show()
	Zhuzongzi_Before1:Hide()
	Zhuzongzi_Before2:Hide()
	Zhuzongzi_After1:Hide()
	Zhuzongzi_After2:Hide()

	if g_Zhuzongzi_State == 0 then
		Zhuzongzi_Close:Show()
		--Zhuzongzi_CloseAnimate:Play(false)
		Zhuzongzi_Before1:Show()
		LifeAbility:Lock_Packet_Item(g_Zhuzongzi_bagIndex, 1)
	else
		Zhuzongzi_Close:Hide()
		--Zhuzongzi_CloseAnimate:Play(false)
	end
	

	
	-- 煮中 开始 或 刷新
	if g_Zhuzongzi_State == 2 or g_Zhuzongzi_State == 1 then	
		if g_Zhuzongzi_LeftTime > 0 then
			Zhuzongzi_Before2_Watch:SetProperty("Timer", g_Zhuzongzi_LeftTime);
		end
		Zhuzongzi_Before2:Show()
		return
	end
	
	-- 失败 结束
	if g_Zhuzongzi_State == 4 then	
		Zhuzongzi_Close:Show()
		--Zhuzongzi_CloseAnimate:Play(true)	
		Zhuzongzi_After1:Show()
		return 
	end
	
	-- 成功 结束
	if g_Zhuzongzi_State == 3 then
		Zhuzongzi_After2:Show()
		Zhuzongzi_After_Succeed_GetButton:Show()
		if g_Zhuzongzi_Image[g_Zhuzongzi_Choose] ~= nil then
			Zhuzongzi_After_Succeed_Get:Show()
			Zhuzongzi_After_Succeed_Get:SetProperty("Image", g_Zhuzongzi_Image[g_Zhuzongzi_Choose])
		end
		if g_Zhuzongzi_IsGetGift == 0 then
			Zhuzongzi_After_Succeed_GetButton_Tips:Show()
		else
			Zhuzongzi_After_Succeed_GetButton_Tips:Hide()
		end
		
		return
	end
	
end

--=========================================================
--开始煮粽子
--=========================================================
function Zhuzongzi_OnOKClicked()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BeginZhuZongZi" )
		Set_XSCRIPT_ScriptID(998018)
		Set_XSCRIPT_Parameter(0, g_Zhuzongzi_bagIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

--=========================================================
--领取熟粽子
--=========================================================
function Zhuzongzi_GetClicked()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetShuZongZi" )
		Set_XSCRIPT_ScriptID(998018)
		Set_XSCRIPT_Parameter(0, g_Zhuzongzi_bagIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	Zhuzongzi_After_Succeed_GetButton_Tips:Hide()
end

--=========================================================
--关闭
--=========================================================
function Zhuzongzi_OnHide()
	LifeAbility:Lock_Packet_Item(g_Zhuzongzi_bagIndex, 0)
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function Zhuzongzi_On_ResetPos()
	Zhuzongzi_Frame:SetProperty("UnifiedPosition", g_Zhuzongzi_UnifiedPosition);
end

function Zhuzongzi_StopWatch_TimeOut()

	Zhuzongzi_Before2:Hide()
	
end

function Zhuzongzi_Goto()
	local bRet = AutoRuntoTargetExWithName(296, 188, 1, "邢护卫")
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end
	Zhuzongzi_OnHide()
end
