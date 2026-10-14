----------------------
-- ChristmasTree_Aim ---
----------------------
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_ShowInfo =
{
	[1] = {image="set:ChristmasUI image:ChristmasUI_1", title="#{QCBF_20151119_43}", text="#{QCBF_20151119_46}", button="#{QCBF_20151119_49}"},
	[2] = {image="set:ChristmasUI2 image:ChristmasUI2_1", title="#{QCBF_20151119_44}", text="#{QCBF_20151119_47}", button="#{QCBF_20151119_50}"},
	[3] = {image="set:ChristmasUI3 image:ChristmasUI3_1", title="#{QCBF_20151119_45}", text="#{QCBF_20151119_48}", button="#{QCBF_20151119_51}"},
}

local g_ShowInfoNewYear =
{
	[1] = {image="set:ChristmasUI image:ChristmasUI_1", title="#{QCBF_161122_43}", text="#{QCBF_161122_46}", button="#{QCBF_20151119_49}"},
	[2] = {image="set:ChristmasUI2 image:ChristmasUI2_2", title="#{QCBF_161122_44}", text="#{QCBF_161122_47}", button="#{QCBF_20151119_50}"},
	[3] = {image="set:ChristmasUI3 image:ChristmasUI3_2", title="#{QCBF_161122_45}", text="#{QCBF_161122_48}", button="#{QCBF_20151119_51}"},
}

local g_Step = 0
local g_bNewYear = 0
--===============================================
-- PreLoad()
--===============================================
function ChristmasTree_Aim_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--===============================================
-- OnLoad()
--===============================================
function ChristmasTree_Aim_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ChristmasTree_Aim_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ChristmasTree_Aim_Frame:GetProperty("UnifiedYPosition");
end

--===============================================
-- OnEvent()
--===============================================
function ChristmasTree_Aim_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		ChristmasTree_Aim_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ChristmasTree_Aim_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		ChristmasTree_Aim_Close_Clicked()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20151120) then
		if (this:IsVisible())  then
			return
		end
		g_bNewYear = Get_XParam_INT(0)
		g_Step = 0
		ChristmasTree_Aim_Show()
	end
end

--===============================================
-- Close_Clicke()
--===============================================
function ChristmasTree_Aim_Close_Clicked()
	g_Step = 0
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ChristmasTree_Aim_ResetPos()
	ChristmasTree_Aim_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ChristmasTree_Aim_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--===============================================
--点击下一步
--===============================================
function ChristmasTree_Aim_NextStep_Clicked()
	g_Step = g_Step + 1
	if g_Step > 3 then
		g_Step = 1
	end
	ChristmasTree_Aim_Show(g_Step)
end

--===============================================
--打开界面
--===============================================
function ChristmasTree_Aim_Show()
	g_Step = g_Step + 1
	if g_Step > 3 then
		g_Step = g_Step - 3
	end
	
	if g_Step<1 or g_Step>3 then
		return
	end
	
	if 1 == g_bNewYear then
		--ChristmasTree_Aim_Image:SetImage(g_ShowInfo[g_Step].image)
		-- 大标题单独设置
		ChristmasTree_Aim_DragTitle:SetText("#{QCBF_161122_42}")
		
		ChristmasTree_Aim_Image:SetProperty("Image",g_ShowInfoNewYear[g_Step].image)
		ChristmasTree_Aim_title:SetText(g_ShowInfoNewYear[g_Step].title)
		ChristmasTree_Aim_InfoText:SetText(g_ShowInfoNewYear[g_Step].text)
		ChristmasTree_Aim_Anniu:SetText(g_ShowInfoNewYear[g_Step].button)
	else
		--ChristmasTree_Aim_Image:SetImage(g_ShowInfo[g_Step].image)
		ChristmasTree_Aim_Image:SetProperty("Image",g_ShowInfo[g_Step].image)
		ChristmasTree_Aim_title:SetText(g_ShowInfo[g_Step].title)
		ChristmasTree_Aim_InfoText:SetText(g_ShowInfo[g_Step].text)
		ChristmasTree_Aim_Anniu:SetText(g_ShowInfo[g_Step].button)
	end
	
	this:Show()
end
