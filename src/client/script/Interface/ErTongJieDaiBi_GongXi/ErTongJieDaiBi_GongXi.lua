--【2022Q2】儿童节代币转换
-- 累计领奖界面

local g_Frame_UnifiedPosition

local g_ItemId2 = 39924296
local g_ItemId1 = 39924297

--=========
-- PreLoad()
--=========
function ErTongJieDaiBi_GongXi_PreLoad()
		--this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
		--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		--this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		--this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function ErTongJieDaiBi_GongXi_OnLoad()	
		g_Frame_UnifiedPosition = ErTongJieDaiBi_GongXi_MainFrame:GetProperty("UnifiedPosition")
		ErTongJieDaiBi_GongXi_Clear()		
end

--=========
-- Event
--=========
function ErTongJieDaiBi_GongXi_OnEvent(event)
		if event == "UI_COMMAND" and tonumber(arg0) == 99802505 then
				if( this:IsVisible() ) then
		    	ErTongJieDaiBi_GongXi_Close()
				end
				local itemId = Get_XParam_INT(0)
				local itemNum = Get_XParam_INT(1)
				local itemId1 = Get_XParam_INT(2)
				local itemNum1 = Get_XParam_INT(3)
				local itemId2 = Get_XParam_INT(4)
				local itemNum2 = Get_XParam_INT(5)
				local num2 = Get_XParam_INT(6)
				local num1 = Get_XParam_INT(7)				
				if itemId > 0 and itemNum > 0 then
					ErTongJieDaiBi_GongXi_Update2(itemId, itemNum, itemId1, itemNum1, itemId2, itemNum2, num2, num1)
				else
					ErTongJieDaiBi_GongXi_Update1(itemId1, itemNum1, itemId2, itemNum2, num2, num1)
				end
				this : Show()
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				ErTongJieDaiBi_GongXi_Close()	
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				ErTongJieDaiBi_GongXi_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				ErTongJieDaiBi_GongXi_On_ResetPos()
		end		
end

--=========
-- 重置
--=========
function ErTongJieDaiBi_GongXi_On_ResetPos()
		ErTongJieDaiBi_GongXi_MainFrame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 清数据
--=========
function ErTongJieDaiBi_GongXi_Clear()
	ErTongJieDaiBi_GongXi_OnceReturn_Item1:SetActionItem(-1)
	ErTongJieDaiBi_GongXi_OnceReturn_Item2:SetActionItem(-1)
	ErTongJieDaiBi_GongXi_OnceReturn_Item3:SetActionItem(-1)
	ErTongJieDaiBi_GongXi_OnceReturn_Item4:SetActionItem(-1)
	ErTongJieDaiBi_GongXi_OnceReturn2_Item1_Animate:Play(false)
	ErTongJieDaiBi_GongXi_OnceReturn2_Item1:SetActionItem(-1)
	ErTongJieDaiBi_GongXi_OnceReturn2_Item2:SetActionItem(-1)
	ErTongJieDaiBi_GongXi_OnceReturn2_Item3:SetActionItem(-1)
	ErTongJieDaiBi_GongXi_OnceReturn2_Item4:SetActionItem(-1)
	ErTongJieDaiBi_GongXi_OnceReturn2_Item5:SetActionItem(-1)
end

--=========
-- 关闭界面
--=========
function ErTongJieDaiBi_GongXi_Close()
		ErTongJieDaiBi_GongXi_Clear()
		this:Hide()
end

--=========
-- 显示界面
--=========
function ErTongJieDaiBi_GongXi_Update1(itemId1, itemNum1, itemId2, itemNum2, num2, num1)
	ErTongJieDaiBi_GongXi_ItemFrame1:Show()
	ErTongJieDaiBi_GongXi_ItemFrame2:Hide()	
	if itemId1 > 0 and itemNum1 > 0 then
		local theAction = DataPool:CreateActionItemForShow(itemId1, itemNum1)
		if theAction:GetID() ~= 0 then
				ErTongJieDaiBi_GongXi_OnceReturn_Item1:SetActionItem(theAction:GetID())
				local strName = DataPool:Lua_GetItemNameByIndex(itemId1)
				ErTongJieDaiBi_GongXi_OnceReturn_Item1_Text:SetText(ScriptGlobal_Format("#{DBZH_230426_12}",strName))
		end
	end
	if itemId2 > 0 and itemNum2 > 0 then
		local theAction = DataPool:CreateActionItemForShow(itemId2, itemNum2)
		if theAction:GetID() ~= 0 then
				ErTongJieDaiBi_GongXi_OnceReturn_Item2:SetActionItem(theAction:GetID())
				local strName = DataPool:Lua_GetItemNameByIndex(itemId2)
				ErTongJieDaiBi_GongXi_OnceReturn_Item2_Text:SetText(ScriptGlobal_Format("#{DBZH_230426_12}",strName))
		end
	end
	if num2 > 0 then
		local theAction = DataPool:CreateActionItemForShow(g_ItemId2, num2)
		if theAction:GetID() ~= 0 then
				ErTongJieDaiBi_GongXi_OnceReturn_Item3:SetActionItem(theAction:GetID())
				local strName = DataPool:Lua_GetItemNameByIndex(g_ItemId2)
				ErTongJieDaiBi_GongXi_OnceReturn_Item3_Text:SetText(ScriptGlobal_Format("#{DBZH_230426_12}",strName))
		end
	end
	if num1 > 0 then
		local theAction = DataPool:CreateActionItemForShow(g_ItemId1, num1)
		if theAction:GetID() ~= 0 then
				ErTongJieDaiBi_GongXi_OnceReturn_Item4:SetActionItem(theAction:GetID())
				local strName = DataPool:Lua_GetItemNameByIndex(g_ItemId1)
				ErTongJieDaiBi_GongXi_OnceReturn_Item4_Text:SetText(ScriptGlobal_Format("#{DBZH_230426_12}",strName))
		end
	end
end

--=========
-- 显示界面
--=========
function ErTongJieDaiBi_GongXi_Update2(itemId, itemNum, itemId1, itemNum1, itemId2, itemNum2, num2, num1)
	ErTongJieDaiBi_GongXi_ItemFrame1:Hide()
	ErTongJieDaiBi_GongXi_ItemFrame2:Show()	
	if itemId > 0 and itemNum > 0 then
		local theAction = DataPool:CreateActionItemForShow(itemId, itemNum)
		if theAction:GetID() ~= 0 then
				ErTongJieDaiBi_GongXi_OnceReturn2_Item1:SetActionItem(theAction:GetID())
				local strName = DataPool:Lua_GetItemNameByIndex(itemId)
				ErTongJieDaiBi_GongXi_OnceReturn2_Item1_Text:SetText(ScriptGlobal_Format("#{DBZH_230426_12}",strName))
				ErTongJieDaiBi_GongXi_OnceReturn2_Item1_Animate:Play(true)
		end
	end
	if itemId1 > 0 and itemNum1 > 0 then
		local theAction = DataPool:CreateActionItemForShow(itemId1, itemNum1)
		if theAction:GetID() ~= 0 then
				ErTongJieDaiBi_GongXi_OnceReturn2_Item2:SetActionItem(theAction:GetID())
				local strName = DataPool:Lua_GetItemNameByIndex(itemId1)
				ErTongJieDaiBi_GongXi_OnceReturn2_Item2_Text:SetText(ScriptGlobal_Format("#{DBZH_230426_12}",strName))
		end
	end
	if itemId2 > 0 and itemNum2 > 0 then
		local theAction = DataPool:CreateActionItemForShow(itemId2, itemNum2)
		if theAction:GetID() ~= 0 then
				ErTongJieDaiBi_GongXi_OnceReturn2_Item3:SetActionItem(theAction:GetID())
				local strName = DataPool:Lua_GetItemNameByIndex(itemId2)
				ErTongJieDaiBi_GongXi_OnceReturn2_Item3_Text:SetText(ScriptGlobal_Format("#{DBZH_230426_12}",strName))
		end
	end
	if num2 > 0 then
		local theAction = DataPool:CreateActionItemForShow(g_ItemId2, num2)
		if theAction:GetID() ~= 0 then
				ErTongJieDaiBi_GongXi_OnceReturn2_Item4:SetActionItem(theAction:GetID())
				local strName = DataPool:Lua_GetItemNameByIndex(g_ItemId2)
				ErTongJieDaiBi_GongXi_OnceReturn2_Item4_Text:SetText(ScriptGlobal_Format("#{DBZH_230426_12}",strName))
		end
	end
	if num1 > 0 then
		local theAction = DataPool:CreateActionItemForShow(g_ItemId1, num1)
		if theAction:GetID() ~= 0 then
				ErTongJieDaiBi_GongXi_OnceReturn2_Item5:SetActionItem(theAction:GetID())
				local strName = DataPool:Lua_GetItemNameByIndex(g_ItemId1)
				ErTongJieDaiBi_GongXi_OnceReturn2_Item5_Text:SetText(ScriptGlobal_Format("#{DBZH_230426_12}",strName))
		end
	end
end
