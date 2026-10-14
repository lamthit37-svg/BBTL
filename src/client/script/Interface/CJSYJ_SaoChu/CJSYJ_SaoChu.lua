--辞旧岁应景活动-贴春联
-- !!!reloadscript =CJSYJ_SaoChu
local g_CJSYJ_SaoChu_Frame_UnifiedXPosition
local g_CJSYJ_SaoChu_Frame_UnifiedYPosition

local g_CJSYJ_SaoChu_DarkList = {}
local g_CJSYJ_SaoChu_CleanValue = 0
local g_CJSYJ_SaoChu_CleanScore = 1
local g_CJSYJ_SaoChu_NeedScore = 5

local g_CareObj = -1

--===============================================
-- OnLoad()
--===============================================
function CJSYJ_SaoChu_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)

end

function CJSYJ_SaoChu_OnLoad()
	g_CJSYJ_SaoChu_DarkList = 
	{
		[1] = {btn=CJSYJ_SaoChu_Image1,bClean=0	,Show=nil},
		[2] = {btn=CJSYJ_SaoChu_Image2,bClean=0	,Show=nil},
		[3] = {btn=CJSYJ_SaoChu_Image3,bClean=0	,Show=nil},
		[4] = {btn=CJSYJ_SaoChu_Image4_1,bClean=0,Show=CJSYJ_SaoChu_Image4_2},
		[5] = {btn=CJSYJ_SaoChu_Image5_1,bClean=0,Show=CJSYJ_SaoChu_Image5_2},
	}
	-- 保存界面的默认相对位置
	g_CJSYJ_SaoChu_Frame_UnifiedXPosition	= CJSYJ_SaoChu_Frame : GetProperty("UnifiedXPosition");
	g_CJSYJ_SaoChu_Frame_UnifiedYPosition	= CJSYJ_SaoChu_Frame : GetProperty("UnifiedYPosition");
end
--===============================================
-- OnEvent()
--===============================================
function CJSYJ_SaoChu_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 2018010501) then	
		local npcid = Get_XParam_INT(0)
		if( npcid ~= -1 ) then
			g_CareObj = DataPool:GetNPCIDByServerID(npcid)
		end
		local bOpen = Get_XParam_INT(1)
		CJSYJ_SaoChu_CleanData()
		CJSYJ_SaoChu_FreshAll()
		if(bOpen == 1) then
			this:Show()
			CJSYJ_SaoChu_CareObject()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		CJSYJ_SaoChu_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		CJSYJ_SaoChu_Frame_On_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if (tonumber(arg0) ~= g_CareObj) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > 15) or arg1=="destroy") then
			CJSYJ_SaoChu_Frame_OnHiden()
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		CJSYJ_SaoChu_Frame_OnHiden()
	end
end

--===============================================
-- OnHiden
--===============================================
function CJSYJ_SaoChu_Frame_OnHiden()
	CJSYJ_SaoChu_StopCareObject()
	KillTimer("CJSYJ_SaoChu_OnFinshTimer()")
	this:Hide()
end

--=========================================================
-- 开始关心NPC，
-- 在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
-- 如果有的话，先取消已经有的“关心”
--=========================================================
function CJSYJ_SaoChu_CareObject()
	this:CareObject(g_CareObj, 1, "CJSYJ_SaoChu")
	return
end

--=========================================================
-- 停止对某NPC的关心
--=========================================================
function CJSYJ_SaoChu_StopCareObject()
	this:CareObject(g_CareObj, 0, "CJSYJ_SaoChu")
	g_CareObj = -1
	return
end

function CJSYJ_SaoChu_Quit_Clicked()
	CJSYJ_SaoChu_Frame_OnHiden()
end

function CJSYJ_SaoChu_CleanData()
	g_CJSYJ_SaoChu_CleanValue = 0
	for i=1,table.getn(g_CJSYJ_SaoChu_DarkList) do
		g_CJSYJ_SaoChu_DarkList[i].bClean = 0
	end
end

function CJSYJ_SaoChu_CalcCleanValue()
	g_CJSYJ_SaoChu_CleanValue = 0
	for i=1,table.getn(g_CJSYJ_SaoChu_DarkList) do
		g_CJSYJ_SaoChu_CleanValue = g_CJSYJ_SaoChu_CleanValue + (g_CJSYJ_SaoChu_DarkList[i].bClean * g_CJSYJ_SaoChu_CleanScore)
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJSYJ_SaoChu_Frame_On_ResetPos()

	CJSYJ_SaoChu_Frame : SetProperty("UnifiedXPosition", g_CJSYJ_SaoChu_Frame_UnifiedXPosition);
	CJSYJ_SaoChu_Frame : SetProperty("UnifiedYPosition", g_CJSYJ_SaoChu_Frame_UnifiedYPosition);

end

function CJSYJ_SaoChu_CleanValueFresh()
	CJSYJ_SaoChu_QJD:SetText(ScriptGlobal_Format("#{CJSX_180103_37}",g_CJSYJ_SaoChu_NeedScore - g_CJSYJ_SaoChu_CleanValue))
end

function CJSYJ_SaoChu_DarkListFresh()
	for i=1,table.getn(g_CJSYJ_SaoChu_DarkList) do
		if(g_CJSYJ_SaoChu_DarkList[i].bClean == 0) then
			g_CJSYJ_SaoChu_DarkList[i].btn:Show()
			if(g_CJSYJ_SaoChu_DarkList[i].Show ~= nil) then
				g_CJSYJ_SaoChu_DarkList[i].Show:Hide()
			end
		else
			g_CJSYJ_SaoChu_DarkList[i].btn:Hide()
			if(g_CJSYJ_SaoChu_DarkList[i].Show ~= nil) then
				g_CJSYJ_SaoChu_DarkList[i].Show:Show()
			end
		end
	end
	if(g_CJSYJ_SaoChu_CleanValue >= g_CJSYJ_SaoChu_NeedScore) then
		CJSYJ_SaoChu_Finish:Show()
		SetTimer("CJSYJ_SaoChu","CJSYJ_SaoChu_OnFinshTimer()",2000)
	else
		CJSYJ_SaoChu_Finish:Hide()
	end
end


function CJSYJ_SaoChu_OnFinshTimer()
	CJSYJ_SaoChu_Finish:Hide()
	KillTimer("CJSYJ_SaoChu_OnFinshTimer()")
end

function CJSYJ_SaoChu_FreshAll()
	CJSYJ_SaoChu_CleanValueFresh()
	CJSYJ_SaoChu_DarkListFresh()
end

function CJSYJ_SaoChu_ClickBtn(nIndex)
	if(nIndex == nil ) then
		return
	end
	if(g_CJSYJ_SaoChu_DarkList[nIndex] == nil) then
		return
	end
	if(g_CJSYJ_SaoChu_DarkList[nIndex].bClean == 1) then
		return
	end

	g_CJSYJ_SaoChu_DarkList[nIndex].bClean = 1
	CJSYJ_SaoChu_CalcCleanValue()
	if(g_CJSYJ_SaoChu_NeedScore - g_CJSYJ_SaoChu_CleanValue > 0) then
		PushDebugMessage(ScriptGlobal_Format("#{CJSX_180103_38}",g_CJSYJ_SaoChu_NeedScore - g_CJSYJ_SaoChu_CleanValue))
	end
	if(g_CJSYJ_SaoChu_CleanValue >= g_CJSYJ_SaoChu_NeedScore) then
		PushDebugMessage("#{CJSX_180103_39}")
	end
	CJSYJ_SaoChu_FreshAll()
	if(g_CJSYJ_SaoChu_CleanValue >= g_CJSYJ_SaoChu_NeedScore) then
		CJSYJ_SaoChu_GetPrize()
	end
end 

function CJSYJ_SaoChu_GetPrize()
	if(g_CJSYJ_SaoChu_CleanValue < g_CJSYJ_SaoChu_NeedScore) then
		PushDebugMessage("#{CJSX_180103_43}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetSaoChuPrize" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892665 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
