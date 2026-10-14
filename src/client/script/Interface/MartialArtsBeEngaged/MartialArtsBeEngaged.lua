--******************************
--比武招亲榜 订婚确认大界面
--******************************

local g_MartialArtsBeEngaged_Frame_UnifiedPosition

function MartialArtsBeEngaged_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("COMPEMARRY_ENGAGE")
end

function MartialArtsBeEngaged_OnLoad()
	g_MartialArtsBeEngaged_Frame_UnifiedPosition=MartialArtsBeEngaged_Frame:GetProperty("UnifiedPosition");
end

--todo ADJEST_UI_POS VIEW_RESOLUTION_CHANGED
function MartialArtsBeEngaged_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		local curSceneID = GetSceneID();
		if (curSceneID >=687 and curSceneID <=691 ) then
		else
			this:Hide()
		end
	elseif event == "COMPEMARRY_ENGAGE" then
		if tostring(arg0) == "open" then
			if tonumber(arg2)~=nil and tonumber(arg2)==0 then
				tipMsg=ScriptGlobal_Format("#{BWZQ_160623_326}",tostring(arg1),tostring(arg1),tostring(arg1),tostring(arg1))
			else
				tipMsg=ScriptGlobal_Format("#{BWZQ_160623_327}",tostring(arg1),tostring(arg1),tostring(arg1))
			end

			MartialArtsBeEngaged_Info:SetText(tipMsg)
			this:Show()
		elseif tostring(arg0) == "update" then--开启小界面，关闭大界面
			if this:IsVisible() then
				this:Hide()
			end
		elseif tostring(arg0) == "update2" then
			this:Show()
		elseif tostring(arg0) == "close" then
			this:Hide()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		MartialArtsBeEngaged_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MartialArtsBeEngaged_ResetPos()
	end
end

function MartialArtsBeEngaged_ResetPos()
	MartialArtsBeEngaged_Frame:SetProperty("UnifiedPosition", g_MartialArtsBeEngaged_Frame_UnifiedPosition);
end

function MartialArtsBeEngaged_EngageOK(bOK)
	if bOK == 0 then
		MartialArtsBeEngaged_OnShowMiniUI()
	else
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ReplyEngage");
			Set_XSCRIPT_ScriptID(509081);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
	end
end

function MartialArtsBeEngaged_OnShowMiniUI()
	this:Hide()
	PushEvent( "COMPEMARRY_ENGAGE", "update" )
end

function MartialArtsBeEngaged_ReachZero()
	if this:IsVisible() then
		this:Hide()
	end
end
