--2024Q2大话西游第三阶段主线剧情
--待办清单
--!!!reloadscript =DaHua_DaiBanList

local g_Frame_Pos = nil

local g_AnimateTick = 0
local g_YinJiAnimateTick = 0
local g_YinJiFlag = 0--0从0-1--1从1-0

local g_ObjId = -1

--=========
-- PreLoad
--=========
function DaHua_DaiBanList_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
end

--=========
-- OnLoad
--=========
function DaHua_DaiBanList_OnLoad()
	g_Frame_Pos = DaHua_DaiBanList_Frame:GetProperty("UnifiedPosition")
end

--=========
-- OnEvent
--=========
function DaHua_DaiBanList_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99919601 )  then 
		g_ObjId = Get_XParam_INT(0)
		local flag = Get_XParam_INT(1)
		local flag1 = Get_XParam_INT(2)
		local flag2 = Get_XParam_INT(3)
		if flag == nil or flag <= 0 then
			DaHua_DaiBanList_Closed()
		elseif flag == 1 then
			--显示界面
			this:Show()
			DaHua_DaiBanList_ClearAnimate()--清动画
			DaHua_DaiBanList_ClearYinJiAnimate()--清动画
			DaHua_DaiBanList_Open(tonumber(flag1),tonumber(flag2))
		elseif flag == 2 then
			--播放动画
			if( this:IsVisible() ) then
				g_YinJiFlag = 0
				DaHua_DaiBanList_PlayAnimate()
				DaHua_DaiBanList_PlayYinJiAnimate()
			end
		elseif flag == 3 then
			--播放动画
			if( this:IsVisible() ) then
				g_YinJiFlag = 1
				DaHua_DaiBanList_PlayYinJiAnimate()
			end
		end
	elseif event == "ADJEST_UI_POS" then
		DaHua_DaiBanList_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DaHua_DaiBanList_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DaHua_DaiBanList_Closed()
	end
end

--=========
-- 重置
--=========
function DaHua_DaiBanList_On_ResetPos()
	DaHua_DaiBanList_Frame:SetProperty("UnifiedPosition", g_Frame_Pos)
end

--=========
-- 打开
--=========
function DaHua_DaiBanList_Open(flag1,flag2)
	if flag1 == nil or flag2 == nil then
		return
	end
	
	--背景图
	if flag1 == 1 then--新图
		DaHua_DaiBanList_Function_Image1:Show()
		DaHua_DaiBanList_Function_Image2:Show()
	else--旧图
		DaHua_DaiBanList_Function_Image1:Show()
		DaHua_DaiBanList_Function_Image2:Hide()
	end
	
	--按钮部分
	if flag2 == 0 then--未签约
		DaHua_DaiBanList_OK:Show()
		DaHua_DaiBanList_OKTps:Show()
		DaHua_DaiBanList_NoTps:Hide()
		DaHua_DaiBanList_YinJi:Hide()		
		DaHua_DaiBanList_Function_Animate:Show()
	elseif flag2 == 1 then--已签约
		DaHua_DaiBanList_OK:Hide()
		DaHua_DaiBanList_OKTps:Hide()
		DaHua_DaiBanList_NoTps:Hide()
		DaHua_DaiBanList_YinJi:Show()
		DaHua_DaiBanList_Function_Animate:Hide()
	elseif flag2 == 2 then--未解约
		DaHua_DaiBanList_OK:Show()
		DaHua_DaiBanList_OKTps:Hide()
		DaHua_DaiBanList_NoTps:Show()
		DaHua_DaiBanList_Function_Animate:Show()
		DaHua_DaiBanList_YinJi:Show()
	elseif flag2 == 3 then--已解约
		DaHua_DaiBanList_OK:Hide()
		DaHua_DaiBanList_OKTps:Hide()
		DaHua_DaiBanList_NoTps:Hide()
		DaHua_DaiBanList_Function_Animate:Hide()
		DaHua_DaiBanList_YinJi:Hide()
	end
end

--=========
-- 关闭
--=========
function DaHua_DaiBanList_Closed()
	DaHua_DaiBanList_ClearAnimate()--清动画
	DaHua_DaiBanList_ClearYinJiAnimate()--清动画
	this:Hide()
end

--=========
-- 取消
--=========
function DaHua_DaiBanList_Cancel_Clicked()
	DaHua_DaiBanList_Closed()
end

--=========
-- 确认
--=========
function DaHua_DaiBanList_OK_Clicked()	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Confirm")
		Set_XSCRIPT_ScriptID(999196)
		Set_XSCRIPT_Parameter(0,g_ObjId) 
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========
-- 清动画
--=========
function DaHua_DaiBanList_ClearAnimate()
		g_AnimateTick = 0
		KillTimer("DaHua_DaiBanList_AnimateTimer()")
end

--=========
-- 播放动画
--=========
function DaHua_DaiBanList_PlayAnimate()
		DaHua_DaiBanList_ClearAnimate()--清动画
		DaHua_DaiBanList_Function_Image2:Show()
		DaHua_DaiBanList_Function_Image2:SetProperty("Alpha",0)
		SetTimer("DaHua_DaiBanList","DaHua_DaiBanList_AnimateTimer()", 200)--计时器
end

--=========
-- 计时器
--=========
function DaHua_DaiBanList_AnimateTimer()
		g_AnimateTick = g_AnimateTick+1	
		if g_AnimateTick > 0 and g_AnimateTick < 10 then
				DaHua_DaiBanList_Function_Image2:SetProperty("Alpha",g_AnimateTick*0.1)
		elseif g_AnimateTick >= 10 then
				g_AnimateTick = 0
				DaHua_DaiBanList_Function_Image2:SetProperty("Alpha",1)
				KillTimer("DaHua_DaiBanList_AnimateTimer()")
		end
end

--=========
-- 清动画
--=========
function DaHua_DaiBanList_ClearYinJiAnimate()
		g_YinJiAnimateTick = 0
		KillTimer("DaHua_DaiBanList_YinJiAnimateTimer()")
end

--=========
-- 播放动画
--=========
function DaHua_DaiBanList_PlayYinJiAnimate()
		DaHua_DaiBanList_ClearYinJiAnimate()--清动画
		DaHua_DaiBanList_OK:Hide()
		DaHua_DaiBanList_OKTps:Hide()
		DaHua_DaiBanList_NoTps:Hide()
		DaHua_DaiBanList_Function_Animate:Hide()
		DaHua_DaiBanList_YinJi:Show()
		if g_YinJiFlag ~= 1 then--从0-1
			DaHua_DaiBanList_YinJi:SetProperty("Alpha",0)
		else
			DaHua_DaiBanList_YinJi:SetProperty("Alpha",1)
		end
		SetTimer("DaHua_DaiBanList","DaHua_DaiBanList_YinJiAnimateTimer()", 200)--计时器
end

--=========
-- 计时器
--=========
function DaHua_DaiBanList_YinJiAnimateTimer()
		g_YinJiAnimateTick = g_YinJiAnimateTick+1
		if g_YinJiFlag ~= 1 then--从0-1
				if g_YinJiAnimateTick > 0 and g_YinJiAnimateTick < 10 then
						DaHua_DaiBanList_YinJi:SetProperty("Alpha",g_YinJiAnimateTick*0.1)						
				elseif g_YinJiAnimateTick >= 10 then
						g_YinJiAnimateTick = 0
						DaHua_DaiBanList_YinJi:SetProperty("Alpha",1)
						KillTimer("DaHua_DaiBanList_YinJiAnimateTimer()")
				end
		else--从1-0
				if g_YinJiAnimateTick > 0 and g_YinJiAnimateTick < 10 then
						DaHua_DaiBanList_YinJi:SetProperty("Alpha",(10-g_YinJiAnimateTick)*0.1)						
				elseif g_YinJiAnimateTick >= 10 then
						g_YinJiAnimateTick = 0
						DaHua_DaiBanList_YinJi:SetProperty("Alpha",0)
						KillTimer("DaHua_DaiBanList_YinJiAnimateTimer()")
				end
		end
end

