local g_TongTianTaThree_Data = {}
local g_TongTianTaThree_Scene = 0
local g_TongTianTaThree_UnifiedPosition;
local g_TongTianTaThree_UI = {}
local g_TongTianTaThree_select = -1

local g_TongTianTaThree_BaoXiang = 
{
	-- [1] = nil,
	-- [2] = nil,
	-- [3] = nil,
	-- [4] = nil,
}
local g_TongTianTaThree_Str = 
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

function TongTianTaThree_PreLoad()
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
function TongTianTaThree_OnLoad()	

	g_TongTianTaThree_BaoXiang[1] = TongTianTaThree_DiHunEnt2
	g_TongTianTaThree_BaoXiang[2] = TongTianTaThree_DiJiang1Ent2
	g_TongTianTaThree_BaoXiang[3] = TongTianTaThree_DiJiang2Ent2
	g_TongTianTaThree_BaoXiang[4] = TongTianTaThree_DiJiang3Ent2	
	g_TongTianTaThree_UnifiedPosition  =TongTianTaThree_Frame:GetProperty("UnifiedPosition");
end

function TongTianTaThree_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 20000519 then
		local flashtype = Get_XParam_INT(0)
		local floor =  Get_XParam_INT( 1 );
		if floor ~= 3 then
			this:Hide()
		else
			local state = Get_XParam_INT(2)
			local round = Get_XParam_INT(3)
			local monstercount = Get_XParam_INT(4)
			local bosscount = Get_XParam_INT(5)
			local baoxiang1 = Get_XParam_INT(6)
			local baoxiang2 = Get_XParam_INT(7)
			local baoxiang3 = Get_XParam_INT(8)
			local baoxiang4 = Get_XParam_INT(9)
			if flashtype == 1000 then
				this:Hide()
				return
			end

			TongTianTaThree_InitFrame(state,round,baoxiangstate,monstercount,bosscount)
			TongTianTaThree_InitBaoXiang(1,baoxiang1)
			TongTianTaThree_InitBaoXiang(2,baoxiang2)
			TongTianTaThree_InitBaoXiang(3,baoxiang3)
			TongTianTaThree_InitBaoXiang(4,baoxiang4)
			if IsWindowShow("TongTianTa_Mini") == false then
				this:Show()
			end
		end

	end

	if event == "NEWDIGONG_SWITCH" then
		if tonumber(arg0) == 3 then
			this:Show()
		else
			this:Hide()
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		TongTianTaThree_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TongTianTaThree_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
		
end


function TongTianTaThree_InitBaoXiang(index,info)
	if info == 2 then
		g_TongTianTaThree_BaoXiang[index]:SetText("#{JDQL_230322_44}")
	else
		g_TongTianTaThree_BaoXiang[index]:SetText("#{JDQL_230322_43}")
	end

end


function TongTianTaThree_On_ResetPos()
	TongTianTaThree_Frame:SetProperty("UnifiedPosition", g_TongTianTaThree_UnifiedPosition);
end

function TongTianTaThree_InitFrame(state,round,baoxiangstate,monstercount,bosscount)

	if state == 1 or state == 2 then
		TongTianTaThree_Text:SetText("#{JDQL_230322_32}")	
	elseif state == 3 or state == 4 then
		TongTianTaThree_Text:SetText("#{JDQL_230322_34}")	
	else
		TongTianTaThree_Text:SetText("")
	end

	local sec = 0
	if round == 1 then
		sec = Lua_GetDiffTime_InSecond_ServerTime(13,39,59)
	elseif round == 2 then
		sec = Lua_GetDiffTime_InSecond_ServerTime(21,39,59)
	end
	TongTianTaThree_Time2:SetProperty("TextColor","FB00FF00")
	TongTianTaThree_Time2:SetProperty("Timer",sec)
	
	TongTianTaThree_Boss_Num:SetText("#cfff263"..bosscount)
	TongTianTaThree_NumTitle:SetText("#{JDQL_230322_11}")
	TongTianTaThree_Num:SetText(g_TongTianTaThree_Str[round][state])
	TongTianTaThree_Time:SetText("#cfff263"..monstercount)



	-- local strInfo = g_TongTianTaThree_Data[index];
	-- if strInfo then
	-- 	if g_TongTianTaThree_select < 0 then
	-- 		g_TongTianTaThree_select = 0
	-- 		TongTianTaThree_DiHunEntBtn:SetCheck(1)
	-- 	end
	-- 	TongTianTaThree_DragTitle:SetText(strInfo.title)
	-- 	TongTianTaThree_Text:SetText(strInfo.board)
	-- 	TongTianTaThree_Pair_Title1:SetText(strInfo.msg)
	-- 	local left = 1-info[1].calltime
	-- 	if info[1].calltime >= 1 then
	-- 		TongTianTaThree_DiHunEnt2:SetText("#{JLQX_211206_39}")
	-- 	else
	-- 		if info[1].difftime >= 600 then

	-- 			TongTianTaThree_DiHunEnt2:SetText(ScriptGlobal_Format("#{JLQX_211206_37}",left))
	-- 		else
	-- 			info[1].difftime = 600 - info[1].difftime
	-- 			local min = math.floor(info[1].difftime/60)
	-- 			local sec = math.mod(info[1].difftime,60)
	-- 			local str = ScriptGlobal_Format("#{JLQX_211206_38}",min,sec)
	-- 			TongTianTaThree_DiHunEnt2:SetText(str)
	-- 		end
	-- 	end

	-- 	for i = 1,10 do
	-- 		TongTianTaThree_InsertData(i,info[i+1])
	-- 	end
		
	-- end
end


function TongTianTaThree_InsertData(index,info)




end

function TongTianTaThree_OpenMini()
	PushEvent("NEWDIGONG_SWITCH",0,3)
end

function TongTianTaThree_Goto()
	g_TongTianTaThree_select = 0
end

function TongTianTaThree_GotoJitan()


end


function TongTianTaThree_Click(index)
	g_TongTianTaThree_select = index

end