--【2022Q2】儿童节代币转换
-- 普通兑换界面

local g_Frame_UnifiedPosition

local g_ItemId = 38005877
local g_RateA = 10--1个道具10个低级代币

--=========
-- PreLoad()
--=========
function ErTongJieDaiBiPop_PreLoad()
		--this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
		--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		--this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		--this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function ErTongJieDaiBiPop_OnLoad()	
		g_Frame_UnifiedPosition = ErTongJieDaiBiPop_Frame:GetProperty("UnifiedPosition")
		ErTongJieDaiBiPop_Clear()		
end

--=========
-- Event
--=========
function ErTongJieDaiBiPop_OnEvent(event)
		if event == "UI_COMMAND" and tonumber(arg0) == 99802502 then
				local nType = Get_XParam_INT(0)
				if nType == nil or nType ~= 1 then-- 非当前界面						
						return
				end
				local bFlag = Get_XParam_INT(1)
				if bFlag == nil or bFlag ~= 1 then-- 关界面						
						if( this:IsVisible() ) then
								ErTongJieDaiBiPop_Close()	
						end
						return
				end
				if( this:IsVisible() ) then
						ErTongJieDaiBiPop_Close()	
				end
				ErTongJieDaiBiPop_FeudalName:SetText("1")
				ErTongJieDaiBiPop_FeudalName:SetProperty("DefaultEditBox", "True")
				ErTongJieDaiBiPop_FeudalName:SetSelected(0, -1)
				this : Show()
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				ErTongJieDaiBiPop_Close()	
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				ErTongJieDaiBiPop_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				ErTongJieDaiBiPop_On_ResetPos()
		end		
end

--=========
-- 重置
--=========
function ErTongJieDaiBiPop_On_ResetPos()
		ErTongJieDaiBiPop_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 清数据
--=========
function ErTongJieDaiBiPop_Clear()
end

--=========
-- 关闭界面
--=========
function ErTongJieDaiBiPop_Close()
		ErTongJieDaiBiPop_Clear()
		this:Hide()
end

--=========
-- 更新代币数量
--=========
function ErTongJieDaiBiPop_Update()
		local nCurNum = 0
		local strCurNum = ErTongJieDaiBiPop_FeudalName:GetText()
		if strCurNum ~= nil and strCurNum ~= "" then
			nCurNum = tonumber(strCurNum)
		end
		if nCurNum <= 0 then
				ErTongJieDaiBiPop_Text1_Num:SetText("#L"..0)
				return
		end
		ErTongJieDaiBiPop_Text1_Num:SetText("#L"..nCurNum*g_RateA)
end

--=========
-- 数量改变
--=========
function ErTongJieDaiBiPop_NumChange()
		local	nNum = 0
		local strNum = ErTongJieDaiBiPop_FeudalName:GetText()
		if strNum ~= nil and strNum ~= "" then
			nNum = tonumber(strNum)
		end
		local maxNum = PlayerPackage:Lua_GetUnLockItemCount(g_ItemId)
		if nNum > maxNum then
				ErTongJieDaiBiPop_FeudalName:SetText(tostring(maxNum))
				return
		end
		ErTongJieDaiBiPop_Update()
end

--=========
-- 最大按钮
--=========
function ErTongJieDaiBiPop_MaxClicked()
		local maxNum = PlayerPackage:Lua_GetUnLockItemCount(g_ItemId)
		ErTongJieDaiBiPop_FeudalName:SetText(maxNum)
		ErTongJieDaiBiPop_FeudalName:SetProperty("DefaultEditBox", "True")
		ErTongJieDaiBiPop_FeudalName:SetSelected(0, -1)
end

--=========
-- 兑换按钮
--=========
function ErTongJieDaiBiPop_DuiHuanClicked()
	local maxNum = PlayerPackage:Lua_GetUnLockItemCount(g_ItemId)
	if maxNum <= 0 then
			PushDebugMessage("#{DBZH_220419_50}")
			return
	end
	local nCurNum = 0
	local strCurNum = ErTongJieDaiBiPop_FeudalName:GetText()
	if strCurNum ~= nil and strCurNum ~= "" then
		nCurNum = tonumber(strCurNum)
	end
	if nCurNum <= 0 then
			PushDebugMessage("#{DBZH_220419_48}")
			return
	end
end
