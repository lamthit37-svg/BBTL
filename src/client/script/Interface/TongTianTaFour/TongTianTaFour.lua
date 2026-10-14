local g_TongTianTaFour_Data = {}
local g_TongTianTaFour_Scene = 0
local g_TongTianTaFour_UnifiedPosition;
local g_TongTianTaFour_UI = {}
local g_TongTianTaFour_select = -1
local g_TongTianTaFour_BaoXiang = 
{
	-- [1] = nil,
	-- [2] = nil,
	-- [3] = nil,
	-- [4] = nil,
}
local g_TongTianTaFour_Str = 
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

function TongTianTaFour_PreLoad()
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
function TongTianTaFour_OnLoad()	

	g_TongTianTaFour_BaoXiang[1] = TongTianTaFour_DiHunEnt2
	g_TongTianTaFour_BaoXiang[2] = TongTianTaFour_DiJiang1Ent2
	g_TongTianTaFour_BaoXiang[3] = TongTianTaFour_DiJiang2Ent2
	g_TongTianTaFour_BaoXiang[4] = TongTianTaFour_DiJiang3Ent2
	g_TongTianTaFour_UnifiedPosition  =TongTianTaFour_Frame:GetProperty("UnifiedPosition");
end

function TongTianTaFour_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 20000519 then
		local flashtype = Get_XParam_INT(0)
		local floor =  Get_XParam_INT( 1 );
		if floor ~= 4 then
			this:Hide()
		else

			
			if flashtype == 1000 then
				this:Hide()
				return
			end
			local state = Get_XParam_INT(2)
			local round = Get_XParam_INT(3)
			local monstercount = Get_XParam_INT(4)
			local bosscount = Get_XParam_INT(5)
			local baoxiang1 = Get_XParam_INT(6)
			local baoxiang2 = Get_XParam_INT(7)
			local baoxiang3 = Get_XParam_INT(8)
			local baoxiang4 = Get_XParam_INT(9)
			TongTianTaFour_InitFrame(state,round,baoxiangstate,monstercount,bosscount)
			TongTianTaFour_InitBaoXiang(1,baoxiang1)
			TongTianTaFour_InitBaoXiang(2,baoxiang2)
			TongTianTaFour_InitBaoXiang(3,baoxiang3)
			TongTianTaFour_InitBaoXiang(4,baoxiang4)
			if IsWindowShow("TongTianTa_Mini") == false then
				this:Show()
			end
		end

	end

	if event == "NEWDIGONG_SWITCH" then
		if tonumber(arg0) == 4 then
			this:Show()
		else
			this:Hide()
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		TongTianTaFour_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TongTianTaFour_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
		
end

function TongTianTaFour_On_ResetPos()
	TongTianTaFour_Frame:SetProperty("UnifiedPosition", g_TongTianTaFour_UnifiedPosition);
end

function TongTianTaFour_InitFrame(state,round,baoxiangstate,monstercount,bosscount)

	if state == 1 or state == 2 then
		TongTianTaFour_Text:SetText("#{JDQL_230322_32}")	
	elseif state == 3 or state == 4 then
		TongTianTaFour_Text:SetText("#{JDQL_230322_34}")	
	else
		TongTianTaFour_Text:SetText("")
	end

	local sec = 0
	if round == 1 then
		sec = Lua_GetDiffTime_InSecond_ServerTime(13,39,59)
	elseif round == 2 then
		sec = Lua_GetDiffTime_InSecond_ServerTime(21,39,59)
	end
	TongTianTaFour_Time2:SetProperty("TextColor","FB00FF00")
	TongTianTaFour_Time2:SetProperty("Timer",sec)


	TongTianTaFour_NumTitle:SetText("#{JDQL_230322_11}")
	TongTianTaFour_Num:SetText(g_TongTianTaFour_Str[round][state])
	TongTianTaFour_Time:SetText("#cfff263"..monstercount)
	TongTianTaFour_Num2:SetText("#cfff263"..bosscount)


end


function TongTianTaFour_InitBaoXiang(index,info)
	if info == 2 then
		g_TongTianTaFour_BaoXiang[index]:SetText("#{JDQL_230322_44}")
	else
		g_TongTianTaFour_BaoXiang[index]:SetText("#{JDQL_230322_43}")
	end

end

function TongTianTaFour_InsertData(index,info)



end

function TongTianTaFour_OpenMini()
	PushEvent("NEWDIGONG_SWITCH",0,4)
end

function TongTianTaFour_Goto()
	g_TongTianTaFour_select = 0
end

function TongTianTaFour_GotoJitan()


end


function TongTianTaFour_Click(index)
	g_TongTianTaFour_select = index

end