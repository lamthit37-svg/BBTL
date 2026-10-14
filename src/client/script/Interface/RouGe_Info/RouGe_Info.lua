--******************************************
--周常肉鸽爬塔副本	提示界面
--create by  limengyue 
--2024-03-15
--******************************************

local g_RouGe_Info_Frame_UnifiedPosition;


--服务器不传字典 直接传编号提示
local g_RouGe_Info_TipsList = 
{
	[1] = {tips="#{RGPT_231130_456}"},--杀怪
	[2] = {tips="#{RGPT_231130_458}"},--小游戏2-1
	[3] = {tips="#{RGPT_231130_460}"},--小游戏2-2
	[4] = {tips="#{RGPT_231130_460}"},--小游戏2-3
	[5] = {tips="#{RGPT_231130_464}"},--捡金币
}


--=========================================================
--PreLoad
--=========================================================
function RouGe_Info_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--距离NPC距离
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--=========================================================
--OnLoad
--=========================================================
function RouGe_Info_OnLoad()
	g_RouGe_Info_Frame_UnifiedPosition	= RouGe_Info_Frame:GetProperty("UnifiedPosition");
end

--=========================================================
--恢复界面的默认相对位置
--=========================================================
function RouGe_Info_On_ResetPos()
	RouGe_Info_Frame : SetProperty("UnifiedPosition", g_RouGe_Info_Frame_UnifiedPosition);
end

--=========================================================
--OnEvent
--=========================================================
function RouGe_Info_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99894901 ) then
		--打开界面
		if(IsWindowShow("RouGe_Info")) then
			CloseWindow("RouGe_Info", true)
		end
		RouGe_Info_Open(Get_XParam_INT(0))
	end
	-- 窗口变化
	if (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		RouGe_Info_On_ResetPos();
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then	
		RouGe_Info_On_ResetPos();
    elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
       RouGe_Info_Close()
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
    end	
end

--=========================================================
--打开界面
--=========================================================
function RouGe_Info_Open(nTipsIdx)
	if nTipsIdx < 0 then
		--关闭界面
		RouGe_Info_Close()
	else
		if g_RouGe_Info_TipsList[nTipsIdx] then
			RouGe_Info_Client_Text:SetText(g_RouGe_Info_TipsList[nTipsIdx].tips)
			this:Show()
		end
	end

end
--=========================================================
--关闭界面
--=========================================================
function RouGe_Info_Close()
	this:Hide()
end
