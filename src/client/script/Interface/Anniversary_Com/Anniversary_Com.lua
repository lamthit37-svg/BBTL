local g_Anniversary_Com_Frame_UnifiedPosition;

local g_Anniversary_Com_Title ={
"#{QZN_180322_127}",  --师傅需要我用竹桶装1斤火药
"#{QZN_180322_128}",  --师傅需要我用竹桶装2斤火药
"#{QZN_180322_129}",  --师傅需要我用木桶装1斤火药
"#{QZN_180322_130}",  --师傅需要我用木桶装2斤火药
}

local g_Anniversary_Com_tips ={
"#{QZN_180322_197}",
"#{QZN_180322_198}",
"#{QZN_180322_199}",
"#{QZN_180322_200}",
}

local g_Anniversary_Com_Result = {
[1] = {0,1},
[2] = {0,2},
[3] = {1,0},
[4] = {2,0},
}

local g_Anniversary_OBJ = -1;
local g_Anniversary_target= -1;
local MAX_OBJ_DISTANCE = 6.0;

local g_Anniversary_CurTitle = -1;
local g_Anniversary_IsFinish = -1;
local g_Anniversary_LeftNum = 0;
local g_Anniversary_RightNum = 0;

local g_Anniversary_ControlLeft = {}

local g_Anniversary_ControlRight = {}

local g_Anniversary_ControlPicLeft = {}

local g_Anniversary_ControlPicRight = {}

local g_Anniversary_ControlTextLeft = {}

local g_Anniversary_ControlTextRight = {}

local g_Anniversary_Com_ControlText ={
"#{QZN_180322_185}",
"#{QZN_180322_186}",
"#{QZN_180322_187}",
"#{QZN_180322_188}",
"#{QZN_180322_189}",
}

--===============================================
-- PreLoad()
--===============================================
function Anniversary_Com_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)		-- 进入游戏世界
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

--===============================================
-- OnEvent()
--===============================================
function Anniversary_Com_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 89273001) then
		if Get_XParam_INT( 3 ) == 0 then 
			Anniversary_Com_Close()
			return
		end
		g_Anniversary_IsFinish = Get_XParam_INT( 0 );
		g_Anniversary_CurTitle = Get_XParam_INT( 1 );
		
		--关注NPC
		g_Anniversary_target = Get_XParam_INT(2)
		g_Anniversary_OBJ = Target:GetServerId2ClientId( tonumber( g_Anniversary_target ) );
		this:CareObject(g_Anniversary_OBJ, 1, "Anniversary_Com");
		
		Anniversary_Com_Open()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		Anniversary_Com_Close()
	elseif (event == "ADJEST_UI_POS") then
		Anniversary_Com_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Anniversary_Com_On_ResetPos()
	elseif (event == "PLAYER_ENTERING_WORLD" ) then	
		Anniversary_Com_On_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_Anniversary_OBJ) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();

			--取消关心
			this:CareObject(g_Anniversary_OBJ, 0, "Anniversary_Com");
		end
	end
end

--===============================================
-- OnLoad()
--===============================================
function Anniversary_Com_OnLoad()
	g_Anniversary_Com_Frame_UnifiedPosition = Anniversary_Com_Frame:GetProperty("UnifiedPosition")
	
	g_Anniversary_ControlLeft = {
			Anniversary_Com_Left1,
			Anniversary_Com_Left3,
			Anniversary_Com_Left2,
		}
	g_Anniversary_ControlRight = {
			Anniversary_Com_Right1,
			Anniversary_Com_Right3,
			Anniversary_Com_Right2,
		}
	g_Anniversary_ControlPicLeft = {
			Anniversary_Com_Left_Pic5,
			Anniversary_Com_Left_Pic4,
			Anniversary_Com_Left_Pic3,
			Anniversary_Com_Left_Pic2,
			Anniversary_Com_Left_Pic1,
		}
	g_Anniversary_ControlPicRight = {
			Anniversary_Com_Right_Pic3,
			Anniversary_Com_Right_Pic2,
			Anniversary_Com_Right_Pic1,
		}
	g_Anniversary_ControlTextLeft = {
			Anniversary_Com_Left_Text5,
			Anniversary_Com_Left_Text4,
			Anniversary_Com_Left_Text3,
			Anniversary_Com_Left_Text2,
			Anniversary_Com_Left_Text1,			
	}
	g_Anniversary_ControlTextRight = {
			Anniversary_Com_Right_Text3,
			Anniversary_Com_Right_Text2,
			Anniversary_Com_Right_Text1,
	}
end

--===============================================
-- Close()
--===============================================
function Anniversary_Com_Close() 	
	this:Hide();
	
	this:CareObject(g_Anniversary_OBJ, 0, "Anniversary_Com");
end

--===============================================
-- ResetPos()
--===============================================
function Anniversary_Com_On_ResetPos()
	Anniversary_Com_Frame:SetProperty("UnifiedPosition", g_Anniversary_Com_Frame_UnifiedPosition)
end

function Anniversary_Com_InitData()

	if g_Anniversary_CurTitle >= 1 and g_Anniversary_CurTitle <= 4 then 
		Anniversary_Com_Info:SetText(g_Anniversary_Com_Title[g_Anniversary_CurTitle])
		local str = ScriptGlobal_Format("#{QZN_180322_196}",g_Anniversary_Com_tips[g_Anniversary_CurTitle])
		Anniversary_Com_Weixin_Key:SetText(str)
	end
	
	g_Anniversary_LeftNum = 0;
	g_Anniversary_RightNum = 0;
	
	Anniversary_Com_Finish:Hide()
	Anniversary_Com_Frame_Disabled:Hide()
	Anniversary_Com_Submit_Animate:Hide()
	
	for i = 1, 5 do
		g_Anniversary_ControlPicLeft[i]:Hide()
	end
	
	for i = 1, 3 do
		g_Anniversary_ControlPicRight[i]:Hide()
	end
	
	g_Anniversary_ControlLeft[1]:SetToolTip("#{QZN_180322_133}")
	g_Anniversary_ControlRight[1]:SetToolTip("#{QZN_180322_137}")
	
	g_Anniversary_ControlLeft[2]:SetToolTip("#{QZN_180322_134}")
	g_Anniversary_ControlRight[2]:SetToolTip("#{QZN_180322_138}")
	
	g_Anniversary_ControlLeft[3]:SetToolTip("#{QZN_180322_135}")
	g_Anniversary_ControlRight[3]:SetToolTip("#{QZN_180322_139}")
	
	Anniversary_Com_RefreshData()
end

function Anniversary_Com_RefreshData()
	for i = 1, 5 do
		g_Anniversary_ControlPicLeft[i]:Hide()
		g_Anniversary_ControlTextLeft[i]:SetText("#e7a4d36#W"..g_Anniversary_Com_ControlText[i])
	end
	
	for i = 1, 3 do
		g_Anniversary_ControlPicRight[i]:Hide()
		g_Anniversary_ControlTextRight[i]:SetText("#e7a4d36#W"..g_Anniversary_Com_ControlText[i])
	end
	
	if g_Anniversary_LeftNum >= 1 and g_Anniversary_LeftNum <= 5 then
		for leftidx = 1, g_Anniversary_LeftNum do
			g_Anniversary_ControlPicLeft[leftidx]:Show()
		end
		g_Anniversary_ControlTextLeft[g_Anniversary_LeftNum] : SetText("#e7a4d36#G"..g_Anniversary_Com_ControlText[g_Anniversary_LeftNum])
	end
	
	if g_Anniversary_RightNum >= 1 and g_Anniversary_RightNum <= 3 then
		for rightidx = 1, g_Anniversary_RightNum do
			g_Anniversary_ControlPicRight[rightidx]:Show()
		end
		g_Anniversary_ControlTextRight[g_Anniversary_RightNum] : SetText("#e7a4d36#G"..g_Anniversary_Com_ControlText[g_Anniversary_RightNum])
	end
	
	Anniversary_Com_CheckResult()
end

function Anniversary_Com_Open()
	
	Anniversary_Com_InitData()
	if g_Anniversary_IsFinish == 1 then
		Anniversary_Com_FinishShow()
	else
		Anniversary_Com_StartShow()
	end
	
	this:Show()
end

function Anniversary_Com_FinishShow()
	
	Anniversary_Com_Finish:Show()
	Anniversary_Com_Frame_Disabled:Show()
		
	--g_Anniversary_ControlLeft[1]:Disable()
	--g_Anniversary_ControlRight[1]:Disable()
	
	--g_Anniversary_ControlLeft[2]:Disable()
	--g_Anniversary_ControlRight[2]:Disable()
	
	--g_Anniversary_ControlLeft[3]:Disable()
	--g_Anniversary_ControlRight[3]:Disable()
	
	--Anniversary_Com_Submit:Disable()
	--Anniversary_Com_Reset:Disable()
end

function Anniversary_Com_StartShow()
	Anniversary_Com_Finish:Hide()
	Anniversary_Com_Frame_Disabled:Hide()
	
	--g_Anniversary_ControlLeft[1]:Enable()
	--g_Anniversary_ControlRight[1]:Enable()
	
	--g_Anniversary_ControlLeft[2]:Enable()
	--g_Anniversary_ControlRight[2]:Enable()
	
	--g_Anniversary_ControlLeft[3]:Enable()
	--g_Anniversary_ControlRight[3]:Enable()
	
	--Anniversary_Com_Submit:Enable()
	--Anniversary_Com_Reset:Enable()
end

function Anniversary_Com_CheckResult()
	if g_Anniversary_Com_Result[g_Anniversary_CurTitle] ~= nil then
		if g_Anniversary_Com_Result[g_Anniversary_CurTitle][1] ~= 0 then
			if g_Anniversary_LeftNum == g_Anniversary_Com_Result[g_Anniversary_CurTitle][1] then
				--提交按钮闪
				Anniversary_Com_Submit_Animate:Show();
				Anniversary_Com_Submit_Animate:Play(true);
				return
			else
				Anniversary_Com_Submit_Animate:Hide()
			end
		end
		if g_Anniversary_Com_Result[g_Anniversary_CurTitle][2] ~= 0 then
			if g_Anniversary_RightNum == g_Anniversary_Com_Result[g_Anniversary_CurTitle][2] then
				--提交按钮闪
				Anniversary_Com_Submit_Animate:Show();
				Anniversary_Com_Submit_Animate:Play(true);
				return
			else
				Anniversary_Com_Submit_Animate:Hide()
			end
		end
	end
end

function Anniversary_Com_LeftFullClick()	
	if g_Anniversary_LeftNum == 5 then
		PushDebugMessage("#{QZN_180322_144}")
		return
	end
	
	g_Anniversary_LeftNum = 5
	
	Anniversary_Com_RefreshData()
end

function Anniversary_Com_RightFullClick()	
	if g_Anniversary_RightNum == 3 then
		PushDebugMessage("#{QZN_180322_145}")
		return
	end
	
	g_Anniversary_RightNum = 3
	
	Anniversary_Com_RefreshData()
end

function Anniversary_Com_LeftEmptyClick()
	if g_Anniversary_LeftNum == 0 then
		PushDebugMessage("#{QZN_180322_146}")
		return
	end
	g_Anniversary_LeftNum = 0
	
	Anniversary_Com_RefreshData()
end

function Anniversary_Com_RightEmptyClick()
	if g_Anniversary_RightNum == 0 then
		PushDebugMessage("#{QZN_180322_147}")
		return
	end
	
	g_Anniversary_RightNum = 0
	
	Anniversary_Com_RefreshData()
end

function Anniversary_Com_LeftIntoRightClick()
	if g_Anniversary_LeftNum == 0 then
		PushDebugMessage("#{QZN_180322_150}")
		return
	end	
	
	if g_Anniversary_RightNum == 3 then
		PushDebugMessage("#{QZN_180322_151}")
		return
	end
	
	if g_Anniversary_RightNum + g_Anniversary_LeftNum <= 3 then
		g_Anniversary_RightNum = g_Anniversary_RightNum + g_Anniversary_LeftNum
		g_Anniversary_LeftNum = 0
	else
		g_Anniversary_LeftNum = g_Anniversary_RightNum + g_Anniversary_LeftNum - 3
		g_Anniversary_RightNum = 3
	end
	
	Anniversary_Com_RefreshData()

end

function Anniversary_Com_RightIntoLeftClick()
	if g_Anniversary_RightNum == 0 then
		PushDebugMessage("#{QZN_180322_148}")
		return
	end	
	
	if g_Anniversary_LeftNum == 5 then
		PushDebugMessage("#{QZN_180322_149}")
		return
	end

	if g_Anniversary_LeftNum + g_Anniversary_RightNum <= 5 then
		g_Anniversary_LeftNum = g_Anniversary_LeftNum + g_Anniversary_RightNum
		g_Anniversary_RightNum = 0
	else
		g_Anniversary_RightNum = g_Anniversary_RightNum + g_Anniversary_LeftNum - 5
		g_Anniversary_LeftNum = 5 
	end
	
	Anniversary_Com_RefreshData()
end

function Anniversary_Com_ResetClick()
	g_Anniversary_LeftNum = 0
	g_Anniversary_RightNum = 0
	
	Anniversary_Com_RefreshData()
end

function Anniversary_Com_SubmitClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnDeal")
		Set_XSCRIPT_ScriptID(892730)
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1,g_Anniversary_LeftNum)
		Set_XSCRIPT_Parameter(2,g_Anniversary_RightNum)
		Set_XSCRIPT_Parameter(3,g_Anniversary_target)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()	
end

--帮助
function Anniversary_Com_Preview_HelpClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCallHelp" )
		Set_XSCRIPT_ScriptID( 892716 )
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end
