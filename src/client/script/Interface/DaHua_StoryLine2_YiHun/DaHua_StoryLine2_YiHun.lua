
local g_IsAnimate = 0

-- 界面的默认相对位置
local g_DaHua_StoryLine2_YiHun_Frame_UnifiedXPosition;
local g_DaHua_StoryLine2_YiHun_Frame_UnifiedYPosition;

local g_MySel = 0
--local g_SelectBackCtrl = {}
local g_SelectTextCtrl = {}
local g_SelectWrongImCtrl = {}--错图
local g_SelectRightImCtrl = {}--对图
local g_YiHun_Animate = {}

function DaHua_StoryLine2_YiHun_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_FAKE_OBJECT")
end

function DaHua_StoryLine2_YiHun_OnLoad()

	-- 保存界面的默认相对位置
	g_DaHua_StoryLine2_YiHun_Frame_UnifiedXPosition	= DaHua_StoryLine2_YiHun_Frame : GetProperty("UnifiedXPosition");
	g_DaHua_StoryLine2_YiHun_Frame_UnifiedYPosition	= DaHua_StoryLine2_YiHun_Frame : GetProperty("UnifiedYPosition");
--	g_SelectBackCtrl = {
--		DaHua_StoryLine2_YiHun_Name1_TipsBk, DaHua_StoryLine2_YiHun_Name2_TipsBk	
--	}
--	g_SelectTextCtrl = {
--		DaHua_StoryLine2_YiHun_Name1_Tips, DaHua_StoryLine2_YiHun_Name2_Tips
--	}
	g_SelectWrongImCtrl = {
		DaHua_StoryLine2_YiHun_Name1_Tips_XuanCuo, DaHua_StoryLine2_YiHun_Name2_Tips_XuanCuo
	}--错图
	g_SelectRightImCtrl = {
		DaHua_StoryLine2_YiHun_Name1_Tips_XuanDui, DaHua_StoryLine2_YiHun_Name2_Tips_XuanDui
	}--对图
	g_YiHun_Animate = {
		DaHua_StoryLine2_YiHun_Animate1,--唐僧起唐僧结束 跳三下 
		DaHua_StoryLine2_YiHun_Animate4,--孙悟空起唐僧结束 跳两下
		DaHua_StoryLine2_YiHun_Animate2,--唐僧起孙悟空结束 跳两下
		DaHua_StoryLine2_YiHun_Animate3,--孙悟空起孙悟空结束 跳三下
	}
end

function DaHua_StoryLine2_YiHun_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0)==99916501 then
		local xx = Get_XParam_INT(0);
		if tonumber(xx) == 1 then
			if g_IsAnimate >= 1 then
				--特效中
				return
			end
			DaHua_StoryLine2_YiHun_Init()
			DaHua_StoryLine2_YiHun_SetCount()
			this:Show()
		elseif tonumber(xx) == 2 then
			--刷新界面
			if this:IsVisible() then
				--播放特效
				local ans = Get_XParam_INT(1);
				--PushDebugMessage("ans="..ans)
				g_IsAnimate = 1
				DaHua_StoryLine2_YiHun_Name1_Btn:Disable()
				DaHua_StoryLine2_YiHun_Name2_Btn:Disable()
				DaHua_StoryLine2_YiHun_Pic_Btn:SetText("#{DHEJ_240521_298}")
				DaHua_StoryLine2_YiHun_Pic_Btn:Disable()
				if ans == 1 then
					--唐僧移魂动画
					local ts = math.random(1,2)
					g_YiHun_Animate[ts]:Show()
					g_YiHun_Animate[ts]:Play(true)
				else
					--孙悟空移魂动画
					local wk = math.random(3,4)
					g_YiHun_Animate[wk]:Show()
					g_YiHun_Animate[wk]:Play(true)
				end
				SetTimer("DaHua_StoryLine2_YiHun","DaHua_StoryLine2_YiHun_AnimateTimerProc()", 4000)
			end
		elseif tonumber(xx) == 3 then
			--结果反馈
			local bCorrect = Get_XParam_INT(1);
			if bCorrect == 1 then
				g_SelectRightImCtrl[g_MySel]:Show()
--				if g_SelectTextCtrl[g_MySel] ~= nil then
--					g_SelectBackCtrl[g_MySel]:Show()
--					g_SelectTextCtrl[g_MySel]:SetText("#{DHEJ_240521_301}")
--				end
			else
				g_SelectWrongImCtrl[g_MySel]:Show()
--				if g_SelectTextCtrl[g_MySel] ~= nil then
--					g_SelectBackCtrl[g_MySel]:Show()
--					g_SelectTextCtrl[g_MySel]:SetText("#{DHEJ_240521_98}")
--				end
			end
			g_IsAnimate = 0
			DaHua_StoryLine2_YiHun_Name1_Btn:Disable()
			DaHua_StoryLine2_YiHun_Name2_Btn:Disable()
			DaHua_StoryLine2_YiHun_Pic_Btn:Show()
			DaHua_StoryLine2_YiHun_Pic_Btn:Enable()
			DaHua_StoryLine2_YiHun_Pic_Btn:SetText("")
			DaHua_StoryLine2_YiHun_SetCount()
		elseif tonumber(xx) == 4 then
			--finish
			DaHua_StoryLine2_YiHun_ClientBK:Hide()
			DaHua_StoryLine2_YiHun_Client2:Hide()
			DaHua_StoryLine2_YiHun_Client2_PicBK:Show()
			SetTimer("DaHua_StoryLine2_YiHun","DaHua_StoryLine2_YiHun_AnimateFinishProc()", 3000)
			DaHua_StoryLine2_YiHun_Pic_Btn:Hide()
			DaHua_StoryLine2_YiHun_SetCount()
		else
			this:Hide()
		end

	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		DaHua_StoryLine2_YiHun_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		DaHua_StoryLine2_YiHun_Frame_On_ResetPos()
	end

end

function DaHua_StoryLine2_YiHun_Init()
	--DaHua_StoryLine2_YiHun_Client:Show()
	DaHua_StoryLine2_YiHun_Info:Show()
	DaHua_StoryLine2_YiHun_Help:Show()
	DaHua_StoryLine2_YiHun_Tips:Show()
	DaHua_StoryLine2_YiHun_ClientBK:Show()
	DaHua_StoryLine2_YiHun_Client2:Hide()
	DaHua_StoryLine2_YiHun_Client2_PicBK:Hide()
	DaHua_StoryLine2_YiHun_Name1_Btn:Disable()
	DaHua_StoryLine2_YiHun_Name2_Btn:Disable()
--	g_SelectBackCtrl[1]:Hide()
--	g_SelectBackCtrl[2]:Hide()
--	g_SelectTextCtrl[1]:SetText("")
--	g_SelectTextCtrl[2]:SetText("")
	g_SelectWrongImCtrl[1]:Hide()
	g_SelectWrongImCtrl[2]:Hide()
	g_SelectRightImCtrl[1]:Hide()
	g_SelectRightImCtrl[2]:Hide()
	DaHua_StoryLine2_YiHun_Pic_Btn:Show()
	DaHua_StoryLine2_YiHun_Pic_Btn:Enable()
	DaHua_StoryLine2_YiHun_Pic_Btn:SetText("")
	for i=1,4 do
		g_YiHun_Animate[i]:Hide()
		g_YiHun_Animate[i]:Play(false)
	end
	DaHua_StoryLine2_YiHun_Client2:Hide()
	g_SelectWrongImCtrl[1]:Hide()
	g_SelectWrongImCtrl[2]:Hide()
	g_SelectRightImCtrl[1]:Hide()
	g_SelectRightImCtrl[2]:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DaHua_StoryLine2_YiHun_Frame_On_ResetPos()

	DaHua_StoryLine2_YiHun_Frame : SetProperty("UnifiedXPosition", g_DaHua_StoryLine2_YiHun_Frame_UnifiedXPosition);
	DaHua_StoryLine2_YiHun_Frame : SetProperty("UnifiedYPosition", g_DaHua_StoryLine2_YiHun_Frame_UnifiedYPosition);

end

function DaHua_StoryLine2_YiHun_ChooseClick(nIdx)
	if g_IsAnimate == 1 then
		--PushDebugMessage("不到选择时间")
		return
	end
	g_MySel = nIdx
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnYiHunChoose")
		Set_XSCRIPT_Parameter( 0, nIdx )
		Set_XSCRIPT_ScriptID(999165)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

function DaHua_StoryLine2_YiHun_StartClick()
	if g_IsAnimate >= 1 then
		--PushDebugMessage("cd中等字典")
		return
	end
--	g_SelectBackCtrl[1]:Hide()
--	g_SelectBackCtrl[2]:Hide()
--	g_SelectTextCtrl[1]:SetText("")
--	g_SelectTextCtrl[2]:SetText("")
	g_SelectWrongImCtrl[1]:Hide()
	g_SelectWrongImCtrl[2]:Hide()
	g_SelectRightImCtrl[1]:Hide()
	g_SelectRightImCtrl[2]:Hide()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnYiHunStart")
		Set_XSCRIPT_ScriptID(999165) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function DaHua_StoryLine2_YiHun_OnHide()
	KillTimer("DaHua_StoryLine2_YiHun_AnimateTimerProc()")
	KillTimer("DaHua_StoryLine2_YiHun_AnimateFinishProc()")
	KillTimer("DaHua_StoryLine2_YiHun_AnimateCloseProc()")
	g_IsAnimate = 0
	g_MySel = 0
	this:Hide()
end

function DaHua_StoryLine2_YiHun_HelpClk()
	PushEvent("QUEST_HELP_MSG", "#{DHEJ_240521_237}")
end

function DaHua_StoryLine2_YiHun_AnimateTimerProc()
	KillTimer("DaHua_StoryLine2_YiHun_AnimateTimerProc()")
	g_IsAnimate = 2
	--请选择
	for i=1,4 do
		g_YiHun_Animate[i]:Hide()
		g_YiHun_Animate[i]:Play(false)
	end
	DaHua_StoryLine2_YiHun_Name1_Btn:Enable()
	DaHua_StoryLine2_YiHun_Name2_Btn:Enable()
	DaHua_StoryLine2_YiHun_Pic_Btn:Disable()
	DaHua_StoryLine2_YiHun_Pic_Btn:SetText("#{DHEJ_240521_299}")
	PushDebugMessage("#{DHEJ_240521_312}")
end

function DaHua_StoryLine2_YiHun_SetCount()
	if DataPool:Lua_IsHaveMission(3050) > 0 then
		local misIndex = DataPool:GetPlayerMissionIndexByID(3050)
		local nCount = DataPool:GetPlayerMission_Variable(misIndex, 4) 
		DaHua_StoryLine2_YiHun_Tips:SetText(ScriptGlobal_Format("#{DHEJ_240521_303}", nCount))
	else
		DaHua_StoryLine2_YiHun_Tips:SetText(ScriptGlobal_Format("#{DHEJ_240521_303}", 0))
	end

end
function DaHua_StoryLine2_YiHun_AnimateFinishProc()
	KillTimer("DaHua_StoryLine2_YiHun_AnimateFinishProc()")
	--DaHua_StoryLine2_YiHun_Client:Hide()
	DaHua_StoryLine2_YiHun_Info:Hide()
	DaHua_StoryLine2_YiHun_Help:Hide()
	DaHua_StoryLine2_YiHun_Tips:Hide()
	DaHua_StoryLine2_YiHun_Client2_PicBK:Hide()
	DaHua_StoryLine2_YiHun_Client2:Show()
	DaHua_StoryLine2_YiHun_Client2_Suwukong:Show()
	DaHua_StoryLine2_YiHun_Client2_Suwukong:Play(true)
	SetTimer("DaHua_StoryLine2_YiHun","DaHua_StoryLine2_YiHun_AnimateCloseProc()", 5000)
end

function DaHua_StoryLine2_YiHun_AnimateCloseProc()
	PushDebugMessage("#{DHEJ_240521_101}")
	DaHua_StoryLine2_YiHun_OnHide()
end
