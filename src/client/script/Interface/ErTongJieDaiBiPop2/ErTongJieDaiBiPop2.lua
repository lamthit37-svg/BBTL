--【2022Q2】儿童节代币转换
-- 元宝兑换界面

local g_Frame_UnifiedPosition

local g_ItemId = 38005877
local g_RateB1 = 10--1个道具+800个元宝==10个低级代币+1个高级代币
local g_RateB2 = 1--1个道具+800个元宝==10个低级代币+1个高级代币
local g_YBRate = 800--1个道具+800个元宝==10个低级代币+1个高级代币

--=========
-- PreLoad()
--=========
function ErTongJieDaiBiPop2_PreLoad()
		--this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
   		--this:RegisterEvent("UPDATE_YUANBAO",false)--元宝变化
		--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		--this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		--this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function ErTongJieDaiBiPop2_OnLoad()	
		g_Frame_UnifiedPosition = ErTongJieDaiBiPop2_Frame:GetProperty("UnifiedPosition")
		ErTongJieDaiBiPop2_Clear()		
end

--=========
-- Event
--=========
function ErTongJieDaiBiPop2_OnEvent(event)
		if event == "UI_COMMAND" and tonumber(arg0) == 99802502 then
				local nType = Get_XParam_INT(0)
				if nType == nil or nType ~= 2 then-- 非当前界面						
						return
				end
				local bFlag = Get_XParam_INT(1)
				if bFlag == nil or bFlag ~= 1 then-- 关界面						
						if( this:IsVisible() ) then
								ErTongJieDaiBiPop2_Close()	
						end
						return
				end
				if( this:IsVisible() ) then
						ErTongJieDaiBiPop2_Close()	
				end
				ErTongJieDaiBiPop2_FeudalName:SetText("1")
				ErTongJieDaiBiPop2_FeudalName:SetProperty("DefaultEditBox", "True")
				ErTongJieDaiBiPop2_FeudalName:SetSelected(0, -1)
				this : Show()
    elseif event == "UPDATE_YUANBAO" then
    		ErTongJieDaiBiPop2_Update()
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				ErTongJieDaiBiPop2_Close()	
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				ErTongJieDaiBiPop2_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				ErTongJieDaiBiPop2_On_ResetPos()
		end		
end

--=========
-- 重置
--=========
function ErTongJieDaiBiPop2_On_ResetPos()
		ErTongJieDaiBiPop2_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 清数据
--=========
function ErTongJieDaiBiPop2_Clear()
end

--=========
-- 关闭界面
--=========
function ErTongJieDaiBiPop2_Close()
		ErTongJieDaiBiPop2_Clear()
		this:Hide()
end

--=========
-- 更新代币数量
--=========
function ErTongJieDaiBiPop2_Update()
		local yuanbao = Player:GetData("YUANBAO")
		local nCurNum = 0
		local strCurNum = ErTongJieDaiBiPop2_FeudalName:GetText()
		if strCurNum ~= nil and strCurNum ~= "" then
			nCurNum = tonumber(strCurNum)
		end
		if nCurNum <= 0 then
				ErTongJieDaiBiPop2_Text3_Num:SetText("#L"..0)
				ErTongJieDaiBiPop2_Text4_Num:SetText("#L"..yuanbao)					
				ErTongJieDaiBiPop2_Text5_Num:SetText("#L"..0)
				ErTongJieDaiBiPop2_Text6_Num:SetText("#L"..0)
				return
		end
		if nCurNum*g_YBRate > yuanbao  then
			ErTongJieDaiBiPop2_Text3_Num:SetText("#cFF0000"..nCurNum*g_YBRate)
		else
			ErTongJieDaiBiPop2_Text3_Num:SetText("#L"..nCurNum*g_YBRate)
		end
		ErTongJieDaiBiPop2_Text4_Num:SetText("#L"..yuanbao)					
		ErTongJieDaiBiPop2_Text5_Num:SetText("#L"..nCurNum*g_RateB2)
		ErTongJieDaiBiPop2_Text6_Num:SetText("#L"..nCurNum*g_RateB1)
end

--=========
-- 数量改变
--=========
function ErTongJieDaiBiPop2_NumChange()

		local	nNum = 0
		local strNum = ErTongJieDaiBiPop2_FeudalName:GetText()
		if strNum ~= nil and strNum ~= "" then
			nNum =	tonumber(strNum)
		end
		local maxNum = PlayerPackage:Lua_GetUnLockItemCount(g_ItemId)
		if nNum > maxNum then
				ErTongJieDaiBiPop2_FeudalName:SetText(tostring(maxNum))
				return
		end
		ErTongJieDaiBiPop2_Update()

end

--=========
-- 最大按钮
--=========
function ErTongJieDaiBiPop2_MaxClicked()
		local maxNum = PlayerPackage:Lua_GetUnLockItemCount(g_ItemId)
		ErTongJieDaiBiPop2_FeudalName:SetText(maxNum)
		ErTongJieDaiBiPop2_FeudalName:SetProperty("DefaultEditBox", "True")
		ErTongJieDaiBiPop2_FeudalName:SetSelected(0, -1)
end

--=========
-- 兑换按钮
--=========
function ErTongJieDaiBiPop2_DuiHuanClicked()
	local maxNum = PlayerPackage:Lua_GetUnLockItemCount(g_ItemId)
	 if maxNum <= 0 then
			PushDebugMessage("#{DBZH_220419_50}")
			return
	end
	local nCurNum = 0
	local strCurNum = ErTongJieDaiBiPop2_FeudalName:GetText()
	if strCurNum ~=nil and strCurNum ~= "" then
		nCurNum = tonumber(strCurNum)
	end
	if nCurNum <= 0 then
			PushDebugMessage("#{DBZH_220419_48}")
			return
	end
end
