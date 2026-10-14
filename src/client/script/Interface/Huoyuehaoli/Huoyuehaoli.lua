--******************************************************************************
--
-- 活跃好礼抽奖界面 by 陈永帅
--
--******************************************************************************
-- 好友界面的默认位置
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition; 
local g_FrameInfo = -1
local FrameInfoList =
{
	QUIT_INIT			= 0,
	QUIT_GAME			= 1,
	QUIT_LOGIN    = 2,
};
 
function Huoyuehaoli_PreLoad()

	-- 注册事件
	this:RegisterEvent("UI_COMMAND") 

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	-- 退出游戏
	this:RegisterEvent("QUEST_QUIT_GAME")

	-- 返回登陆界面
	this:RegisterEvent("QUEST_SERVER_LOGIN")

	-- 离开场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")

end

function Huoyuehaoli_OnLoad() 
	-- 保存好友界面的默认相对位置
	g_Frame_UnifiedXPosition	= Huoyuehaoli_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Huoyuehaoli_Frame:GetProperty("UnifiedYPosition");

end

function Huoyuehaoli_OnEvent( event )

	if ( event == "UI_COMMAND" and tonumber(arg0) == UI_Command_S )then
		local pos = Get_XParam_INT(0)
		TBL_Anim[pos]:Show()
		Huoyuehaoli_Timer_StopWatch1:SetProperty("Timer", "1")
	elseif( event == "ADJEST_UI_POS" ) then
		Huoyuehaoli_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Huoyuehaoli_ResetPos() 

	-- 退出游戏流程
	elseif( event == "QUEST_QUIT_GAME" ) then
		g_FrameInfo = FrameInfoList.QUIT_GAME
		Huoyuehaoli_OK()
	-- 返回登陆界面
	elseif( event == "QUEST_SERVER_LOGIN" ) then
		g_FrameInfo = FrameInfoList.QUIT_LOGIN
		Huoyuehaoli_OK()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide(); 
	end

end
 

--================================================
-- 恢复好礼界面的默认相对位置
--================================================
function Huoyuehaoli_ResetPos()
	Huoyuehaoli_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Huoyuehaoli_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

-- 窗口关闭
function Huoyuehaoli_Hide()
 
	g_FrameInfo = -1 
end
  
--================================================
-- 退出/返回登陆 游戏按钮
--================================================
function Huoyuehaoli_OK()

	if (g_FrameInfo == FrameInfoList.QUIT_GAME) then
		--modify by kaibin 根据是否这只了进行离线摆摊来走不同下线流程
		local nStallOfflineState = StallSale:GetStallOfflineState();
		if(nStallOfflineState ~= nil and nStallOfflineState > 0) then
			CheckSOSecond(0) --2次检测并进行离线摆摊流程
		else
			EnterQuitWait(0) --原来下线流程
		end

	elseif (g_FrameInfo == FrameInfoList.QUIT_LOGIN) then
		--modify by kaibin 根据是否这只了进行离线摆摊来走不同下线流程
		local nStallOfflineState = StallSale:GetStallOfflineState();
		if(nStallOfflineState ~= nil and nStallOfflineState > 0) then
			CheckSOSecond(1) --2次检测并进行离线摆摊流程
		else
			EnterQuitWait(1) --原来下线流程
		end
	end

	-- 关闭对话框
	Huoyuehaoli_Hide()

end
 