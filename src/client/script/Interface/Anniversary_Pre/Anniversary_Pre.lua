local g_Anniversary_Pre_Frame_UnifiedPosition;

--迎庆典
local g_Anniversary_Pre_IsShow = 0
local g_Anniversary_Pre_CurJLnum = 0
local g_Anniversary_Pre_AllJLnum = 0
local g_Anniversary_Pre_Prize = {0,0,0}
local g_Anniversary_Pre_Isopen = 0
local g_Anniversary_Pre_IsGetPot = 0
local g_Anniversary_Pre_PetId = 31379
local g_Anniversary_Pre_GiftIcon = {}
local g_Anniversary_Pre_need = {20,40,70}

--===============================================
-- PreLoad()
--===============================================
function Anniversary_Pre_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)		-- 进入游戏世界
end

--===============================================
-- OnEvent()
--===============================================
function Anniversary_Pre_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 89271601) then
		--迎庆典
		g_Anniversary_Pre_IsShow = Get_XParam_INT(0)
		if g_Anniversary_Pre_IsShow == 0 then
			Anniversary_Pre_Close()
			return
		end
		g_Anniversary_Pre_CurJLnum = Get_XParam_INT(1)
		g_Anniversary_Pre_AllJLnum = Get_XParam_INT(2)
		
		g_Anniversary_Pre_Prize[1] = Get_XParam_INT(5) 
		g_Anniversary_Pre_Prize[2] = Get_XParam_INT(6)
		g_Anniversary_Pre_Prize[3] = Get_XParam_INT(7)
		
		g_Anniversary_Pre_IsGetPot = Get_XParam_INT(3)
		
		g_Anniversary_Pre_Isopen = Get_XParam_INT(8)
		Anniversary_Pre_OpenPreview()
		if Get_XParam_INT(4) == 1 then
			Anniversary_Pre_Page0_Info1 : SetText("#{QZN_180322_05}")
			Anniversary_Pre_Page0_Function : Show()
			Anniversary_Pre_Down : Show()
		else
			Anniversary_Pre_Page0_Info1 : SetText("#{QZN_180322_202}")
			--隐藏图标
			Anniversary_Pre_Page0_Function : Hide()
			Anniversary_Pre_Down : Hide()
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89271605) then	
		AutoRunToTargetEx(248,346,0)
		SetAutoRunTargetNPCName("枫年")
		Anniversary_Pre_Close() 
	elseif (event == "PLAYER_LEAVE_WORLD") then
		Anniversary_Pre_Close()
	elseif (event == "ADJEST_UI_POS") then
		Anniversary_Pre_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Anniversary_Pre_On_ResetPos()
	elseif (event == "PLAYER_ENTERING_WORLD" ) then	
		Anniversary_Pre_On_ResetPos()
	end
end

--===============================================
-- OnLoad()
--===============================================
function Anniversary_Pre_OnLoad()
	g_Anniversary_Pre_Frame_UnifiedPosition = Anniversary_Pre_Frame_BK:GetProperty("UnifiedPosition")
		
	g_Anniversary_Pre_GiftIcon = {
		[1] = {Anniversary_Pre_Page0_Icon1, Anniversary_Pre_Icon1_Animate, Anniversary_Pre_Page0_Icon1_tips, Anniversary_Pre_Page0_Icon1_Finish},
		[2] = {Anniversary_Pre_Page0_Icon2, Anniversary_Pre_Icon2_Animate, Anniversary_Pre_Page0_Icon2_tips, Anniversary_Pre_Page0_Icon2_Finish},
		[3] = {Anniversary_Pre_Page0_Icon3, Anniversary_Pre_Icon3_Animate, Anniversary_Pre_Page0_Icon3_tips, Anniversary_Pre_Page0_Icon3_Finish},
	}
	
end

--===============================================
-- Close()
--===============================================
function Anniversary_Pre_Close() 	
	this:Hide();
end

--===============================================
-- ResetPos()
--===============================================
function Anniversary_Pre_On_ResetPos()
	Anniversary_Pre_Frame_BK:SetProperty("UnifiedPosition", g_Anniversary_Pre_Frame_UnifiedPosition)
end

function Anniversary_Pre_OpenPreview()

	local numstr = "" 	
	if g_Anniversary_Pre_CurJLnum >= 2 then
		--Anniversary_Pre_Page0_Call:Disable()
		numstr = ScriptGlobal_Format("#{QZN_180322_98}",g_Anniversary_Pre_CurJLnum)
	else
		--Anniversary_Pre_Page0_Call:Enable()
		numstr = ScriptGlobal_Format("#{QZN_180322_215}",g_Anniversary_Pre_CurJLnum)
	end
	
	if g_Anniversary_Pre_IsGetPot == 1 then
	--	Anniversary_Pre_Page0_Info1_BK:Show()
		Anniversary_Pre_Page0_Find:Hide()
		Anniversary_Pre_Page0_Call:Show()
	else
	--	Anniversary_Pre_Page0_Info1_BK:Hide()
		Anniversary_Pre_Page0_Find:Show()
		Anniversary_Pre_Page0_Call:Hide()
	end
	
	Anniversary_Pre_Page0_Num : SetText(numstr)
		
	--Anniversary_Pre_Page0_FakeObject : SetFakeObject( "" );
	--Pet : SetPetForZNQModel(g_Anniversary_Pre_PetId);
	--Anniversary_Pre_Page0_FakeObject : SetFakeObject("ShowPetforZNQ");
	
	--FakeObj_SetCamera("ShowPetforZNQ", 1, 1.3)
	--FakeObj_SetCamera("ShowPetforZNQ", 2, 8)
	--FakeObj_SetCamera("ShowPetforZNQ", 3, 0.1)
	
	--local str = ScriptGlobal_Format("#{QZN_180322_191}", g_Anniversary_Pre_AllJLnum)
	--Anniversary_Pre_Progress_Pic_Text : SetProperty("Tooltip", ""..g_Anniversary_Pre_AllJLnum)
	Anniversary_Pre_Progress_Pic_Text : SetText(tostring(g_Anniversary_Pre_AllJLnum))
	
	DataPool:Lua_ClearAnniversaryPreActionItem();	
		DataPool:Lua_SetAnniversaryPreActionItem( 0, 39920089, 2 );
		DataPool:Lua_SetAnniversaryPreActionItem( 1, 39921139, 3 );
		DataPool:Lua_SetAnniversaryPreActionItem( 2, 39921389, 1 );
	DataPool:Lua_UpdateAnniversaryPreActionItem();
	for i=1, 3 do
		g_Anniversary_Pre_GiftIcon[i][1]:Show();
		local theAction = EnumAction( i-1, "anniversary_pre");
		if theAction:GetID() ~= 0 then
			g_Anniversary_Pre_GiftIcon[i][1]:SetActionItem( theAction:GetID() );
		else
			g_Anniversary_Pre_GiftIcon[i][1]:SetActionItem( -1 );
		end
		
		if g_Anniversary_Pre_AllJLnum >= g_Anniversary_Pre_need[i] then
			if g_Anniversary_Pre_Prize[i] == 0 then
				g_Anniversary_Pre_GiftIcon[i][2]:Show();
				g_Anniversary_Pre_GiftIcon[i][2]:Play(true);
					
				g_Anniversary_Pre_GiftIcon[i][3]:Show();
		
				g_Anniversary_Pre_GiftIcon[i][4]:Hide();
					
				if i == 3 and g_Anniversary_Pre_Isopen == 0 then
					g_Anniversary_Pre_GiftIcon[i][2]:Hide();
					g_Anniversary_Pre_GiftIcon[i][3]:Hide();
					g_Anniversary_Pre_GiftIcon[i][4]:Hide();
				end
			else
				g_Anniversary_Pre_GiftIcon[i][2]:Hide();
				g_Anniversary_Pre_GiftIcon[i][3]:Hide();
				g_Anniversary_Pre_GiftIcon[i][4]:Show();
			end
		else
			g_Anniversary_Pre_GiftIcon[i][2]:Hide();
			g_Anniversary_Pre_GiftIcon[i][3]:Hide();
			g_Anniversary_Pre_GiftIcon[i][4]:Hide();
		end
	end
		
	this:Show()
end

--领奖
function Anniversary_Pre_Preview_PickClick( idx )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetPrize" )
		Set_XSCRIPT_ScriptID( 892716 )
		Set_XSCRIPT_Parameter(0, idx)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()		
end

--召唤
function Anniversary_Pre_Preview_CallClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCallPetSoul" )
		Set_XSCRIPT_ScriptID( 892716 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

--图鉴
function Anniversary_Pre_Preview_JianClick()
	Pet:AnniversaryOpenPetJian(g_Anniversary_Pre_PetId);
end

--帮助
function Anniversary_Pre_Preview_HelpClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCallHelp" )
		Set_XSCRIPT_ScriptID( 892716 )
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

--NPC
function Anniversary_Pre_Preview_FindClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCallHelp" )
		Set_XSCRIPT_ScriptID( 892716 )
		Set_XSCRIPT_Parameter(0, 2)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

function Anniversary_Pre_Modle_TurnLeft( start )
	--向左旋转开始
	if(start == 1) then
		--Anniversary_Pre_Page0_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		--Anniversary_Pre_Page0_FakeObject:RotateEnd();
	end

end

function Anniversary_Pre_Modle_TurnRight( start )
	--向右旋转开始
	if(start == 1) then
		--Anniversary_Pre_Page0_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		--Anniversary_Pre_Page0_FakeObject:RotateEnd();
	end
end
