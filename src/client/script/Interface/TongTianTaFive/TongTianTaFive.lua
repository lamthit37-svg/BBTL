local g_TongTianTaFive_Data = {}
local g_TongTianTaFive_Scene = 0
local g_TongTianTaFive_UnifiedPosition;
local g_TongTianTaFive_UI = {}
local g_TongTianTaFive_select = -1

function TongTianTaFive_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	this:RegisterEvent("NEWDIGONG_SWITCH")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")		
end
--界面21点50到24点显示
function TongTianTaFive_OnLoad()	


	g_TongTianTaFive_UnifiedPosition  =TongTianTaFive_Frame:GetProperty("UnifiedPosition");
end

function TongTianTaFive_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 20000519 then
		local floor =  Get_XParam_INT( 1 );
		local flashtype = Get_XParam_INT(0)
		if floor ~= 5 then
			this:Hide()
		else
			local state = Get_XParam_INT(2)
			local round = Get_XParam_INT(3)
			local baoxiangstate = Get_XParam_INT(4)
			if flashtype == 1000 then
				this:Hide()
				return
			end

			TongTianTaFive_InitFrame(state,round,baoxiangstate)
			if IsWindowShow("TongTianTa_Mini") == false then
				this:Show()
			end
		end


	end

	if event == "NEWDIGONG_SWITCH" then
		if tonumber(arg0) == 5 then
			this:Show()
		else
			this:Hide()
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		TongTianTaFive_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TongTianTaFive_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
		
end

function TongTianTaFive_On_ResetPos()
	TongTianTaFive_Frame:SetProperty("UnifiedPosition", g_TongTianTaFive_UnifiedPosition);
end

function TongTianTaFive_InitFrame(state,round,baoxiangstate)

	if state == 1 or state == 2 then
		TongTianTaFive_Text:SetText("#{JDQL_230322_23}")	
	elseif state == 3 or state == 4 then
		TongTianTaFive_Text:SetText("#{JDQL_230322_29}")	
	else
		TongTianTaFive_Text:SetText("")
	end

	local sec = 0
	if round == 1 then
		sec = Lua_GetDiffTime_InSecond_ServerTime(13,39,59)
	elseif round == 2 then
		sec = Lua_GetDiffTime_InSecond_ServerTime(21,39,59)
	end

	TongTianTaFive_Time:SetProperty("TextColor","FB00FF00")
	TongTianTaFive_Time:SetProperty("Timer",sec)

	TongTianTaFive_NumTitle:SetText("#{JDQL_230322_37}")



	if state == 1 or state == 2 then
		local str = ""
		if round == 1 then
			str = ScriptGlobal_Format("#{JDQL_230322_45}","13","20")
		else
			str = ScriptGlobal_Format("#{JDQL_230322_45}","21","20")
		end
		TongTianTaFive_Num:SetText(str)
	else
		if baoxiangstate == 2 then
			TongTianTaFive_Num:SetText("#{JDQL_230322_44}")
		else
			TongTianTaFive_Num:SetText("#{JDQL_230322_43}")
		end
	end



end


function TongTianTaFive_InsertData(index,info)


end

function TongTianTaFive_OpenMini()
	PushEvent("NEWDIGONG_SWITCH",0,5)
end

function TongTianTaFive_Goto()
	g_TongTianTaFive_select = 0
end

function TongTianTaFive_GotoJitan()


end


function TongTianTaFive_Click(index)
	g_TongTianTaFive_select = index

end