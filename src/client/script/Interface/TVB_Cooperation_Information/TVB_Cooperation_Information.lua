--TVB植入 TVB_Cooperation_Information
local g_TVB_Cooperation_Information_Frame_UnifiedPosition
local g_TVB_Cooperation_Information_LV = 30 --等级限制
local g_TVB_Cooperation_Information_dist = 5 --距离NPC距离
local g_TVB_Cooperation_Information_UICOMMAND = 99848901 --开启界面
local g_TVB_Cooperation_Information_UICOMMAND2 = 99848902 --关闭界面
local g_MaxPage = 4 --最大页数
local g_Content = {} --要加载的图片

local g_CurPage = 1 --当前页
local g_targetID = -1
local g_TVB_Cooperation_Information_objCared = -1 --NPCid 在uicommand事件中 赋值


function TVB_Cooperation_Information_PreLoad()
    --uicommand
    this:RegisterEvent("UI_COMMAND")
	--场景切换
	this:RegisterEvent("ON_SCENE_TRANS")
    --NPC
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS")
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

function TVB_Cooperation_Information_OnLoad()
    g_TVB_Cooperation_Information_Frame_UnifiedPosition = TVB_Cooperation_Information_Frame_BK:GetProperty("UnifiedPosition")
end

function TVB_Cooperation_Information_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_TVB_Cooperation_Information_UICOMMAND then
        local param = Get_XParam_INT(0)
        local isOpenUrl = Get_XParam_INT(1)
        if isOpenUrl == 1 then
            --打开链接
            GameProduceLogin:OpenURL(GetWeblink("WEB_TVB"))
        else
            g_targetID = param
            g_TVB_Cooperation_Information_objCared = DataPool:GetNPCIDByServerID(param)
            this:CareObject(g_TVB_Cooperation_Information_objCared, 1, "TVB_Cooperation_Information")
            this:Show()
        end
    elseif event == "UI_COMMAND" and tonumber(arg0) == g_TVB_Cooperation_Information_UICOMMAND2 then
        TVB_Cooperation_Information_OnHidden()
    elseif event == "ON_SCENE_TRANS" then
		TVB_Cooperation_Information_OnHidden()
    elseif event == "OBJECT_CARED_EVENT" and this:IsVisible() then
		if tonumber(arg0) ~= g_TVB_Cooperation_Information_objCared then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>g_TVB_Cooperation_Information_dist or arg1=="destroy") then
		    --取消关心
    		TVB_Cooperation_Information_OnHidden()
		end
	elseif (event == "ADJEST_UI_POS" ) then
        TVB_Cooperation_Information_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        TVB_Cooperation_Information_Frame_On_ResetPos()
	end	
end

--关闭按钮
function TVB_Cooperation_Information_OnHidden()
    this:CareObject(g_TVB_Cooperation_Information_objCared, 0, "TVB_Cooperation_Information")
    g_TVB_Cooperation_Information_objCared = -1
    g_targetID = -1
    this:Hide()
end

--完成按钮
function TVB_Cooperation_Information_OKClicked()
    if g_targetID == -1 then
        return
    end
    Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("SetCompleteMF");
		Set_XSCRIPT_ScriptID(998489);
        Set_XSCRIPT_Parameter(0,g_targetID)
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

--游戏窗口尺寸变化
--游戏分辨率变化
function TVB_Cooperation_Information_Frame_On_ResetPos()
    TVB_Cooperation_Information_Frame_BK:SetProperty("UnifiedPosition", g_TVB_Cooperation_Information_Frame_UnifiedPosition)
end