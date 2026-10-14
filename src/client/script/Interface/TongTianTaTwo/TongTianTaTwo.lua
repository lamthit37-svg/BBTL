local g_TongTianTaTwo_Data = {}
local g_TongTianTaTwo_floor = 0
local g_TongTianTaTwo_UnifiedPosition;
local g_TongTianTaTwo_UI = {}
local g_TongTianTaTwo_select = -1
local g_TongTianTaTwo_Str = 
{
	[1] =
	{
		[1] = "#{JDQL_230322_12}",
		[2] = "#{JDQL_230322_13}",
		[3] = "#{JDQL_230322_14}",
		[4] = "#{JDQL_230322_14}",
	},

	[2] = 
	{
		[1] = "#{JDQL_230322_15}",
		[2] = "#{JDQL_230322_16}",
		[3] = "#{JDQL_230322_14}",
		[4] = "#{JDQL_230322_14}",		
	}
}

function TongTianTaTwo_PreLoad()
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
function TongTianTaTwo_OnLoad()	


	g_TongTianTaTwo_UnifiedPosition  =TongTianTaTwo_Frame:GetProperty("UnifiedPosition");
end

function TongTianTaTwo_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 20000519 then
		local flashtype = Get_XParam_INT(0)
		local floor =  Get_XParam_INT( 1 );
		if floor ~= 1 and floor ~= 2 then
			this:Hide()
		else


			local state = Get_XParam_INT(2)
			local round = Get_XParam_INT(3)
			local monstercount = Get_XParam_INT(4)
			if flashtype == 1000 then
				this:Hide()
				return
			end

			g_TongTianTaTwo_floor = floor
			TongTianTaTwo_InitFrame(state,round,baoxiangstate,monstercount,floor)
			if IsWindowShow("TongTianTa_Mini") == false then
				this:Show()
			end
		end
	end

	if event == "NEWDIGONG_SWITCH" then
		if tonumber(arg0) == 1 or tonumber(arg0) == 2 then
			this:Show()
		else
			this:Hide()
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		TongTianTaTwo_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TongTianTaTwo_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
		
end

function TongTianTaTwo_On_ResetPos()
	TongTianTaTwo_Frame:SetProperty("UnifiedPosition", g_TongTianTaTwo_UnifiedPosition);
end

function TongTianTaTwo_InitFrame(state,round,baoxiangstate,monstercount,floor)


	if floor == 1 then
		TongTianTaTwo_DragTitle:SetText("#{JDQL_230322_08}")
		TongTianTaTwo_Pair_Title1:SetText("#{JDQL_230322_10}")
	elseif floor == 2 then

		TongTianTaTwo_DragTitle:SetText("#{JDQL_230322_22}")
		TongTianTaTwo_Pair_Title1:SetText("#{JDQL_230322_24}")
	end


	local sec = 0
	if round == 1 then
		sec = Lua_GetDiffTime_InSecond_ServerTime(13,39,59)
	elseif round == 2 then
		sec = Lua_GetDiffTime_InSecond_ServerTime(21,39,59)
	end

	TongTianTaTwo_Time2:SetProperty("TextColor","FB00FF00")
	TongTianTaTwo_Time2:SetProperty("Timer",sec)

	TongTianTaTwo_NumTitle:SetText("#{JDQL_230322_11}")
	TongTianTaTwo_Num:SetText(g_TongTianTaTwo_Str[round][state])
	TongTianTaTwo_Time:SetText("#cfff263"..monstercount)



end


function TongTianTaTwo_InsertData(index,info)


end

function TongTianTaTwo_OpenMini()
	PushEvent("NEWDIGONG_SWITCH",tonumber(0),g_TongTianTaTwo_floor)
end

function TongTianTaTwo_Goto()
	g_TongTianTaTwo_select = 0
end

function TongTianTaTwo_GotoJitan()

	-- if g_TongTianTaTwo_Pos[g_TongTianTaTwo_select] ~= nil then
	-- 	AutoRunToTarget( g_TongTianTaTwo_Pos[g_TongTianTaTwo_select].x, g_TongTianTaTwo_Pos[g_TongTianTaTwo_select].z )
	-- end
end


function TongTianTaTwo_Click(index)
	g_TongTianTaTwo_select = index

end