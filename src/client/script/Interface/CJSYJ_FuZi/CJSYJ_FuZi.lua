--辞旧岁应景活动-贴春联
-- !!!reloadscript =CJSYJ_FuZi
local g_CJSYJ_FuZi_Frame_UnifiedXPosition
local g_CJSYJ_FuZi_Frame_UnifiedYPosition

local g_CJSYJ_FuZi_CurDir = 0

local g_CJSYJ_FuZi_HasFinsh = 0

local g_CJSYJ_FuZi_DirImage = 
{
	[0] = "set:CJSYJ04 image:CJSYJ_TDF_Zheng",
	[1] = "set:CJSYJ04 image:CJSYJ_TDF_You",
	[2] = "set:CJSYJ04 image:CJSYJ_TDF_Dao",
	[3] = "set:CJSYJ04 image:CJSYJ_TDF_Zuo",
}
local g_CareObj = -1

--===============================================
-- OnLoad()
--===============================================
function CJSYJ_FuZi_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)
end

function CJSYJ_FuZi_OnLoad()
	
	-- 保存界面的默认相对位置
	g_CJSYJ_FuZi_Frame_UnifiedXPosition	= CJSYJ_FuZi_Frame : GetProperty("UnifiedXPosition");
	g_CJSYJ_FuZi_Frame_UnifiedYPosition	= CJSYJ_FuZi_Frame : GetProperty("UnifiedYPosition");
end
--===============================================
-- OnEvent()
--===============================================
function CJSYJ_FuZi_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 2018010503) then	
		local npcid = Get_XParam_INT(0)
		if( npcid ~= -1 ) then
			g_CareObj = DataPool:GetNPCIDByServerID(npcid)
		end
		g_CJSYJ_FuZi_CurDir = 0
		g_CJSYJ_FuZi_HasFinsh = 0
		CJSYJ_FuZi_FreshFuzi()
		this:Show()
		CJSYJ_FuZi_CareObject()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		CJSYJ_FuZi_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		CJSYJ_FuZi_Frame_On_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if (tonumber(arg0) ~= g_CareObj) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > 15) or arg1=="destroy") then
			CJSYJ_FuZi_Frame_OnHiden()
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		CJSYJ_FuZi_Frame_OnHiden()
	end
end

--===============================================
-- OnHiden
--===============================================
function CJSYJ_FuZi_Frame_OnHiden()
	CJSYJ_FuZi_StopCareObject()
	KillTimer("CJSYJ_FuZi_OnFinshTimer()")
	this:Hide()
end

function CJSYJ_FuZi_Quit_Clicked()
	CJSYJ_FuZi_Frame_OnHiden()
end

--=========================================================
-- 开始关心NPC，
-- 在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
-- 如果有的话，先取消已经有的“关心”
--=========================================================
function CJSYJ_FuZi_CareObject()
	this:CareObject(g_CareObj, 1, "CJSYJ_FuZi")
	return
end

--=========================================================
-- 停止对某NPC的关心
--=========================================================
function CJSYJ_FuZi_StopCareObject()
	this:CareObject(g_CareObj, 0, "CJSYJ_FuZi")
	g_CareObj = -1
	return
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function CJSYJ_FuZi_Frame_On_ResetPos()

	CJSYJ_FuZi_Frame : SetProperty("UnifiedXPosition", g_CJSYJ_FuZi_Frame_UnifiedXPosition);
	CJSYJ_FuZi_Frame : SetProperty("UnifiedYPosition", g_CJSYJ_FuZi_Frame_UnifiedYPosition);

end

function CJSYJ_FuZi_FreshFuzi()
	if(g_CJSYJ_FuZi_CurDir < 0 or g_CJSYJ_FuZi_CurDir > 3) then
		g_CJSYJ_FuZi_CurDir = 0
	end
	CJSYJ_FuZi_Image:SetProperty("Image",g_CJSYJ_FuZi_DirImage[g_CJSYJ_FuZi_CurDir])
	if(g_CJSYJ_FuZi_HasFinsh == 1) then
		CJSYJ_FuZi_Finish:Show()
		CJSYJ_FuZi_OK:Hide()
		CJSYJ_FuZi_TurnLeft:Disable()
		CJSYJ_FuZi_TurnRight:Disable()
		SetTimer("CJSYJ_FuZi","CJSYJ_FuZi_OnFinshTimer()",2000)
		PushDebugMessage("#{CJSX_180103_34}")
	else
		CJSYJ_FuZi_TurnLeft:Enable()
		CJSYJ_FuZi_TurnRight:Enable()
		CJSYJ_FuZi_OK:Show()
		CJSYJ_FuZi_Finish:Hide()
	end
end

function CJSYJ_FuZi_OnFinshTimer()
	CJSYJ_FuZi_Finish:Hide()
	KillTimer("CJSYJ_FuZi_OnFinshTimer()")
end



function CJSYJ_FuZi_TurnLeftClick()
	g_CJSYJ_FuZi_CurDir = g_CJSYJ_FuZi_CurDir - 1
	if(g_CJSYJ_FuZi_CurDir < 0) then
		g_CJSYJ_FuZi_CurDir = 3
	end
	CJSYJ_FuZi_FreshFuzi()
end

function CJSYJ_FuZi_TurnRightClick()
	g_CJSYJ_FuZi_CurDir = g_CJSYJ_FuZi_CurDir + 1
	if(g_CJSYJ_FuZi_CurDir > 3) then
		g_CJSYJ_FuZi_CurDir = 0
	end
	CJSYJ_FuZi_FreshFuzi()
end

function CJSYJ_FuZi_ConfirmFuzi()
	if(g_CJSYJ_FuZi_CurDir ~= 2) then
		PushDebugMessage("#{CJSX_180103_33}")
		return
	end
	g_CJSYJ_FuZi_HasFinsh = 1
	CJSYJ_FuZi_FreshFuzi()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnTieFuzi" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892665 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end

