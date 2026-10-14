--新手战令 时装预览 两个时装选择
--!!!reloadscript =FreshMan_GamePass_DoubleLook

local g_FreshMan_GamePass_DoubleLook_Frame_UnifiedPosition = 0
--===============================================
-- PreLoad()
--===============================================
function FreshMan_GamePass_DoubleLook_PreLoad()
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
function FreshMan_GamePass_DoubleLook_OnLoad()	
	g_FreshMan_GamePass_DoubleLook_Frame_UnifiedPosition = FreshMan_GamePass_DoubleLook_Frame_BK:GetProperty("UnifiedPosition")

end

--===============================================
-- OnEvent()
--===============================================
function FreshMan_GamePass_DoubleLook_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" and this:IsVisible()then
		this:Hide();
	elseif event == "ADJEST_UI_POS" and this:IsVisible()then
		FreshMan_GamePass_DoubleLook_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()then
		FreshMan_GamePass_DoubleLook_On_ResetPos()
	end
	
	if event == "OPEN_WINDOW" then --界面打开事件
		if( arg0 ~= "FreshMan_GamePass_DoubleLook") then
            return;
        end
		if(IsWindowShow("FreshMan_GamePass_DoubleLook")) then
			this:Hide()
            return;
		end

		this:Show();

		FreshMan_GamePass_DoubleLook_UpdateItem()
    elseif event == "CLOSE_WINDOW" then --界面关闭事件
		this:Hide()
	end
end

function FreshMan_GamePass_DoubleLook_UpdateItem()
	
	theAction1 = DataPool:CreateActionItemForShow(10126821, 1)
	theAction2 = DataPool:CreateActionItemForShow(10126837, 1)

	if(theAction1 ~= nil and theAction1:GetID() ~= 0)then
		FreshMan_GamePass_DoubleLook_Item1:SetActionItem(theAction1:GetID())
	end

	if(theAction2 ~= nil and theAction2:GetID() ~= 0)then
		FreshMan_GamePass_DoubleLook_Item2:SetActionItem(theAction2:GetID())
	end
end

function FreshMan_GamePass_DoubleLook_Choose(index)
	if(index == 1)then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)		
			Set_XSCRIPT_Function_Name("DressPreview")
			Set_XSCRIPT_Parameter(0, 10126821)
			Set_XSCRIPT_Parameter(1, 148)
			Set_XSCRIPT_Parameter(2, 115)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif(index == 2)then
		Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)		
			Set_XSCRIPT_Function_Name("DressPreview")
			Set_XSCRIPT_Parameter(0, 10126837)
			Set_XSCRIPT_Parameter(1, 149)
			Set_XSCRIPT_Parameter(2, 116)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end

	this:Hide();
end

function FreshMan_GamePass_DoubleLook_OnHidden()
    this:Hide();
end

--=========================================================
-- 界面位置
--=========================================================
function FreshMan_GamePass_DoubleLook_On_ResetPos()
	FreshMan_GamePass_DoubleLook_Frame_BK:SetProperty("UnifiedPosition", g_FreshMan_GamePass_DoubleLook_Frame_UnifiedPosition)
end