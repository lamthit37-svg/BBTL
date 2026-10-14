local g_QinHuangTime_Data = {}
local g_QinHuangTime_Scene = 0
local g_QinHuangTime_UnifiedPosition;
function QinHuangTime_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)	
	this:RegisterEvent("QIHUANTIME_SWITCH")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")	
end
--界面21点50到24点显示
function QinHuangTime_OnLoad()	
	g_QinHuangTime_Data[1] = {title = "#{JLQX_211206_7}",board="#{JLQX_211206_8}",msg="#{JLQX_211206_9}"}
	g_QinHuangTime_Data[2] = {title = "#{JLQX_211206_19}",board="#{JLQX_211206_20}",msg="#{JLQX_211206_21}"}
	g_QinHuangTime_Data[3] = {title = "#{JLQX_211206_25}",board="#{JLQX_211206_26}",msg="#{JLQX_211206_27}"}
	g_QinHuangTime_Data[4] = {title = "#{JLQX_211206_33}",board="#{JLQX_211206_34}",msg="#{JLQX_211206_35}"}
	g_QinHuangTime_UnifiedPosition  =QinHuangTime:GetProperty("UnifiedPosition");
end

function QinHuangTime_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 20210510 then
		local sceneId =  Get_XParam_INT( 0 );
		local state = Get_XParam_INT(1)
		local count = Get_XParam_INT(2)
		--PushDebugMessage("ssss="..sceneId)
		if sceneId == 400 then			
			QinHuangTime_InitFrame(1,state,count)
			if IsWindowShow("QinHuangTime_Mini") == false then
				this:Show()
			end
		elseif sceneId == 401 then
			QinHuangTime_InitFrame(2,state,count)
			if IsWindowShow("QinHuangTime_Mini") == false then
				this:Show()
			end
		elseif sceneId == 402 then
			QinHuangTime_InitFrame(3,state,count)
			if IsWindowShow("QinHuangTime_Mini") == false then
				this:Show()
			end
		else
			this:Hide()
		end

		g_QinHuangTime_Scene = sceneId
		
	end

	if event == "QIHUANTIME_SWITCH" then
		if tonumber(arg0) == 400 or tonumber(arg0) == 401 or tonumber(arg0) == 402 then
			this:Show()
		else
			this:Hide()
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		QinHuangTime_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QinHuangTime_On_ResetPos()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		this:Hide()
	end
end


function QinHuangTime_On_ResetPos()
	QinHuangTime:SetProperty("UnifiedPosition", g_QinHuangTime_UnifiedPosition);
end

function QinHuangTime_InitFrame(index,state,count)

	local showstate = function(state)
		if state == 1 or state == 0 then		--0应该关闭界面先这么写着
			QinHuangTime_Num:SetText("#{JLQX_211206_11}")
		elseif state == 2 then
			QinHuangTime_Num:SetText("#{JLQX_211206_12}")
		elseif state == 3 then
			QinHuangTime_Num:SetText("#{JLQX_211206_13}")
		elseif state == 4 then
			QinHuangTime_Num:SetText("#{JLQX_211206_14}")
		end
	end
	local strInfo = g_QinHuangTime_Data[index];
	if strInfo then
		QinHuangTime_DragTitle:SetText(strInfo.title)
		QinHuangTime_Text:SetText(strInfo.board)
		QinHuangTime_Pair_Title1:SetText(strInfo.msg)
		QinHuangTime_TimeTitle:SetText("#{JLQX_211206_15}")
		QinHuangTime_Time:SetText(ScriptGlobal_Format("#{JLQX_211206_16}",count))
		showstate(state)
	end
end

function QinHuangTime_OpenMini()
	PushEvent("QIHUANTIME_SWITCH",0,g_QinHuangTime_Scene)
end