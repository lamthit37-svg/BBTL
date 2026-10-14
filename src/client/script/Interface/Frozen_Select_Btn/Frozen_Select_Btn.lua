--!!!reloadscript =Frozen_Select_Btn

local g_Frozen_Select_Btn_Frame_UnifiedPosition;

local g_Frozen_Select_Btn_Group = {}
local g_Frozen_Select_Btn_Btn = {}
local g_Frozen_Select_Btn_Animate = {}

local g_Frozen_Select_Btn_Max_Point = 150
local g_Frozen_Select_Btn_Max_Level = 3

local g_Frozen_Select_Btn_TempID = -1

--===============================================
-- OnLoad()
--===============================================
function Frozen_Select_Btn_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--===============================================
-- OnLoad()
--===============================================
function Frozen_Select_Btn_OnLoad()   
	-- 保存界面的默认相对位置
	g_Frozen_Select_Btn_Frame_UnifiedPosition = Frozen_Select_Btn_Frame:GetProperty("UnifiedPosition")
	
	g_Frozen_Select_Btn_Group[1] = Frozen_Select_Btn01_Group
	g_Frozen_Select_Btn_Group[2] = Frozen_Select_Btn02_Group
	g_Frozen_Select_Btn_Group[3] = Frozen_Select_Btn03_Group
	g_Frozen_Select_Btn_Group[4] = Frozen_Select_Btn04_Group
	g_Frozen_Select_Btn_Group[5] = Frozen_Select_Btn05_Group
	g_Frozen_Select_Btn_Btn[1] = Frozen_Select_Btn01
	g_Frozen_Select_Btn_Btn[2] = Frozen_Select_Btn02
	g_Frozen_Select_Btn_Btn[3] = Frozen_Select_Btn03
	g_Frozen_Select_Btn_Btn[4] = Frozen_Select_Btn04
	g_Frozen_Select_Btn_Btn[5] = Frozen_Select_Btn05
	g_Frozen_Select_Btn_Animate[1] = Frozen_Select_Btn01_Animate
	g_Frozen_Select_Btn_Animate[2] = Frozen_Select_Btn02_Animate
	g_Frozen_Select_Btn_Animate[3] = Frozen_Select_Btn03_Animate
	g_Frozen_Select_Btn_Animate[4] = Frozen_Select_Btn04_Animate
	g_Frozen_Select_Btn_Animate[5] = Frozen_Select_Btn05_Animate
	
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_Select_Btn_Frame_On_ResetPos()
	Frozen_Select_Btn_Frame:SetProperty("UnifiedPosition", g_Frozen_Select_Btn_Frame_UnifiedPosition);
end

--===============================================
-- OnEvent()
--===============================================
function Frozen_Select_Btn_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 99949501) then
		--开还是关
		
		local lastBtnIdx = Get_XParam_INT(0)
		if lastBtnIdx > 0 and lastBtnIdx <= 5 then
			Frozen_Select_Btn_FreshNewBtn(lastBtnIdx)	
		elseif lastBtnIdx == 0 then
			Frozen_Select_Btn_Open()
		else
			Frozen_Select_Btn_OnClose()
		end
		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 99949502) then
		local curLevel = Get_XParam_INT(0)
		local curPoint = Get_XParam_INT(1)
		Frozen_Select_Btn_FreshProgress(curLevel, curPoint)
		--PushDebugMessage("99949502 curLevel = "..curLevel.."  curPoint = "..curPoint)
	end
	
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		Frozen_Select_Btn_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Frozen_Select_Btn_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       Frozen_Select_Btn_OnClose()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			Frozen_Select_Btn_OnClose()
		end
    end
         
end

--===============================================
-- Frozen_Select_Btn_OnClose()
--===============================================
function Frozen_Select_Btn_OnClose()
	
	Frozen_Select_Btn_OnHidden()
	this:Hide()
	
end

function Frozen_Select_Btn_OnHidden()
	
	for i = 1, 5 do
		g_Frozen_Select_Btn_Group[i]:Hide()
		g_Frozen_Select_Btn_Animate[i]:Play(false)
	end

end


--=========================================================
--默认打开界面
--=========================================================
function Frozen_Select_Btn_Open()
	
--	PushDebugMessage(" Frozen_Select_Btn_Open")
	local randomIdx = math.random( 1, 5 )
	for i = 1, 5 do
		if randomIdx ~= i then
			g_Frozen_Select_Btn_Group[i]:Hide()
			g_Frozen_Select_Btn_Btn[i]:Hide()
			g_Frozen_Select_Btn_Animate[i]:Play(false)
		else
			g_Frozen_Select_Btn_Group[i]:Show()
			g_Frozen_Select_Btn_Btn[i]:Show()
			g_Frozen_Select_Btn_Animate[i]:Play(false)
		end
	end
	this:Show()		
end

function Frozen_Select_Btn_Snow_Click(btnIdx)

--	PushDebugMessage(" Frozen_Select_Btn_Snow_Click")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UseSkill" )	 	-- 函数名
		Set_XSCRIPT_ScriptID( 999495 );					-- 脚本编号
		Set_XSCRIPT_Parameter( 0, btnIdx );				-- 参数一
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
	--Frozen_Select_Btn_OnClose()
	
	g_Frozen_Select_Btn_TempID = btnIdx
	--g_Frozen_Select_Btn_Group[btnIdx]:Hide()
	g_Frozen_Select_Btn_Btn[btnIdx]:Hide()
	g_Frozen_Select_Btn_Animate[btnIdx]:Play(true)
	
	SetTimer("Frozen_Select_Btn","Frozen_Select_Btn_Snow_Click_Timer()", 1*1200)
	
	
end

function Frozen_Select_Btn_Snow_Click_Timer()
	g_Frozen_Select_Btn_Animate[g_Frozen_Select_Btn_TempID]:Play(false)
	g_Frozen_Select_Btn_Group[g_Frozen_Select_Btn_TempID]:Hide()
	KillTimer("Frozen_Select_Btn_Snow_Click_Timer()")
end

function Frozen_Select_Btn_FreshNewBtn(lastBtnIdx)
	
	local newIdx = lastBtnIdx
	while newIdx == lastBtnIdx do
		newIdx = math.random( 1, 5 )
	end
	for i = 1, 5 do
		if newIdx == i then
			g_Frozen_Select_Btn_Group[i]:Show()
			g_Frozen_Select_Btn_Btn[i]:Show()
			g_Frozen_Select_Btn_Animate[i]:Play(false)
		end
	end
	
end

function Frozen_Select_Btn_FreshProgress(curLevel, curPoint)
	
	if curPoint < 0 then curPoint = 0 end
	if curPoint > g_Frozen_Select_Btn_Max_Point then curPoint = g_Frozen_Select_Btn_Max_Point end
	Frozen_Select_Btn_Progress:SetProgress(curPoint, g_Frozen_Select_Btn_Max_Point)

end

