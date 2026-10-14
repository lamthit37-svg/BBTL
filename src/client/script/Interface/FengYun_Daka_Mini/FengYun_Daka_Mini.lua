-- !!!reloadscript =FengYun_Daka_Mini
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_Score = 0
--local g_targetId = -1
--local MAX_OBJ_DISTANCE = 5.0
--预加载函数，可以而且只能在这里注册脚本关心的事件
local g_TodayText = {"#{FYDK_260129_43}","#{FYDK_260129_75}","#{FYDK_260129_76}",}
local g_idx = 0
function FengYun_Daka_Mini_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	--this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FengYun_Daka_Mini_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= FengYun_Daka_Mini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= FengYun_Daka_Mini_Frame:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FengYun_Daka_Mini_ResetPos()
	FengYun_Daka_Mini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	FengYun_Daka_Mini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function FengYun_Daka_Mini_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 89360201) then--
		-- PushDebugMessage("111111111111111111")
		local opType = Get_XParam_INT(0)
		g_Score = Get_XParam_INT(1)
		if opType == 1 then
			if (this:IsVisible()) then
				FengYun_Daka_Mini_Update()
				return
			end
			g_idx = Get_XParam_INT(2)
			--local xx = Get_XParam_INT(2);
			--g_targetId = DataPool : GetNPCIDByServerID(xx);
			--if g_targetId == -1 then
				--return
			--end
			--this:CareObject(g_targetId, 1, "FengYun_Daka_Mini")
			FengYun_Daka_Mini_Show()
			FengYun_Daka_Mini_Update()

		else
			FengYun_Daka_Mini_Hide()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_Daka_Mini_Hide()
	elseif event == "ADJEST_UI_POS" then
		FengYun_Daka_Mini_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengYun_Daka_Mini_ResetPos()
	--elseif (event == "OBJECT_CARED_EVENT") then
		--AxTrace(0, 0, "arg0"..arg0.." arg1"..arg1.." arg2"..arg2);
		--if(tonumber(arg0) ~= objCared) then
			--return;
		--end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		--if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--this:Hide();

			--取消关心
			--this:CareObject(g_targetId, 0, "FengYun_Daka_Mini");
		--end
	end
end

--显示UI
function FengYun_Daka_Mini_Show()
	this:Show()
	
end
--隐藏UI
function FengYun_Daka_Mini_Hide()
	FengYun_Daka_Mini_ClearData()
	--this:CareObject(g_targetId, 0, "FengYun_Daka_Mini");
	this:Hide()
end

--清除数据
function FengYun_Daka_Mini_ClearData()
	g_idx = 0
	g_Score = 0
	FengYun_Daka_Progress:SetProgress(0, 100)
end

--更新
function FengYun_Daka_Mini_Update()
	FengYun_Daka_Mini_Text1:SetText(g_TodayText[g_idx])
	FengYun_Daka_Mini_Text2:SetText(ScriptGlobal_Format("#{FYDK_260129_44}", g_Score))
	if g_Score >= 100 then
		g_Score	= 100
		FengYun_Daka_Mini_Text1:SetText("#{FYDK_260129_61}")
	end
	FengYun_Daka_Progress:SetProgress(g_Score, 100)
end
