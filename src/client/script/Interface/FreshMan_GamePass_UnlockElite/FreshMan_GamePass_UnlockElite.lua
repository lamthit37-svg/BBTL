--新手战令解锁精英档界面
--!!!reloadscript =FreshMan_GamePass_UnlockElite
local g_FreshMan_GamePass_UnlockElite_Frame_UnifiedPosition = 0

--===============================================
-- PreLoad()
--===============================================
function FreshMan_GamePass_UnlockElite_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	
	this:RegisterEvent("OPEN_WINDOW")--打开界面事件
    this:RegisterEvent("CLOSE_WINDOW")--关闭界面事件
end

--===============================================
-- OnLoad()
--===============================================
function FreshMan_GamePass_UnlockElite_OnLoad()	
	g_FreshMan_GamePass_UnlockElite_Frame_UnifiedPosition = FreshMan_GamePass_UnlockElite_Frame_BK:GetProperty("UnifiedPosition")

end

--===============================================
-- OnEvent()
--===============================================
function FreshMan_GamePass_UnlockElite_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" and this:IsVisible()then
		this:Hide();
	elseif event == "ADJEST_UI_POS" and this:IsVisible()then
		FreshMan_GamePass_UnlockElite_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()then
		FreshMan_GamePass_UnlockElite_On_ResetPos()
	end
	
	if event == "OPEN_WINDOW" then --界面打开事件
		if( arg0 ~= "FreshMan_GamePass_UnlockElite") then
            return;
        end
		if(IsWindowShow("FreshMan_GamePass_UnlockElite")) then
			this:Hide()
            return;
		end
		this:Show();
		FreshMan_GamePass_UnlockElite_Open()
    elseif event == "CLOSE_WINDOW" then --界面关闭事件
		this:Hide()
	end
end


function FreshMan_GamePass_UnlockElite_Open()
	theAction1 = DataPool:CreateActionItemForShow(10126817, 1)
	theAction2 = DataPool:CreateActionItemForShow(30900077, 2)--30900130四级宝石兑换卷
	theAction3 = DataPool:CreateActionItemForShow(38005901, 1)
	theAction4 = DataPool:CreateActionItemForShow(10102912, 1)
	theAction5 = DataPool:CreateActionItemForShow(38005902, 1)

	if(theAction1 ~= nil and theAction1:GetID() ~= 0)then
		FreshMan_GamePass_UnlockElite_Page_Lace1Item:SetActionItem(theAction1:GetID())
		FreshMan_GamePass_UnlockElite_Page_Lace1Item_Tip:SetText(ScriptGlobal_Format("#{XSZL_220511_34}",theAction1:GetName() ))
	end
	if(theAction2 ~= nil and theAction2:GetID() ~= 0)then
		FreshMan_GamePass_UnlockElite_Page_Lace2Item:SetActionItem(theAction2:GetID())
		FreshMan_GamePass_UnlockElite_Page_Lace2Item_Tip:SetText(ScriptGlobal_Format("#{XSZL_220511_34}",theAction2:GetName() ))
	end
	if(theAction3 ~= nil and theAction3:GetID() ~= 0)then
		FreshMan_GamePass_UnlockElite_Page_Lace3Item:SetActionItem(theAction3:GetID())
		FreshMan_GamePass_UnlockElite_Page_Lace3Item_Tip:SetText(ScriptGlobal_Format("#{XSZL_220511_34}",theAction3:GetName() ))
	end
	if(theAction4 ~= nil and theAction4:GetID() ~= 0)then
		FreshMan_GamePass_UnlockElite_Page_Lace4Item:SetActionItem(theAction4:GetID())
		FreshMan_GamePass_UnlockElite_Page_Lace4Item_Tip:SetText(ScriptGlobal_Format("#{XSZL_220511_34}",theAction4:GetName() ))
	end
	if(theAction5 ~= nil and theAction5:GetID() ~= 0)then
		FreshMan_GamePass_UnlockElite_Page_Lace5Item:SetActionItem(theAction5:GetID())
		FreshMan_GamePass_UnlockElite_Page_Lace5Item_Tip:SetText(ScriptGlobal_Format("#{XSZL_220511_34}",theAction5:GetName() ))
	end
end

function FreshMan_GamePass_UnlockElite_OKClicked()
    PushEvent("XINSHOUZHANLING_BUY",2)
end

function FreshMan_GamePass_UnlockElite_OnHidden()
    this:Hide();
end

--=========================================================
-- 界面位置
--=========================================================
function FreshMan_GamePass_UnlockElite_On_ResetPos()
	FreshMan_GamePass_UnlockElite_Frame_BK:SetProperty("UnifiedPosition", g_FreshMan_GamePass_UnlockElite_Frame_UnifiedPosition)
end