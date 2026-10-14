-- 2018Q4春节引导任务-任务领取界面

local g_Frame_UnifiedPosition

local g_ButtonList = {}

--=========
-- PreLoad
--=========
function SpringFestival_Get_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad
--=========
function SpringFestival_Get_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_Get_Frame:GetProperty("UnifiedPosition") 
	
	g_ButtonList = 
	{
		{ btn = SpringFestival_Get_Item1, id = 39921584, num = 1, },
		{ btn = SpringFestival_Get_Item2, id = 39921639, num = 1, },
		{ btn = SpringFestival_Get_Item3, id = 39921579, num = 1, },
	}
	
end

--=========
-- OnEvent
--=========
function SpringFestival_Get_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89298503 then
	
		local bFlag = Get_XParam_INT(0)
		if bFlag ~= nil and bFlag == 1 then
			SpringFestival_Get_Update()
		else
			SpringFestival_Get_Close()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_Get_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival_Get_On_ResetPos()

	end

end

--=========
-- 重置
--=========
function SpringFestival_Get_On_ResetPos()

	SpringFestival_Get_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 打开
--=========
function SpringFestival_Get_Update()

	-- 设置图标
	for i = 1, table.getn(g_ButtonList) do
		local theAction = DataPool:CreateActionItemForShow(g_ButtonList[i].id, g_ButtonList[i].num)
		if theAction:GetID() ~= 0 then
			g_ButtonList[i].btn:SetActionItem(theAction:GetID())
		end
	end
	
	-- 设置内容
	--local strName = Player:GetName()
	--local strText = ScriptGlobal_Format("#{RACL_181206_04}",strName)
	--SpringFestival_Get_Text:SetText(strText)
	
	-- 显示
	this:Show()
	
end

--=========
-- 关闭
--=========
function SpringFestival_Get_Close()

	SpringFestival_Get_OnHiden()
	this:Hide()
	
end

--=========
-- 隐藏
--=========
function SpringFestival_Get_OnHiden()

end

--=========
-- 确定
--=========
function SpringFestival_Get_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnAccept" )
		Set_XSCRIPT_ScriptID( 892986 )
	Send_XSCRIPT()
	
end



