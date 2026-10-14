local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_CurIndex = -1
local g_CurChoose = -1

function Fuli_ZhanLing_Choose_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OPEN_ZHANLING_CHOOSE")
end

function Fuli_ZhanLing_Choose_OnEvent(event)
	if event == "OPEN_ZHANLING_CHOOSE"   then
		Fuli_ZhanLing_Choose_OpenChoose()
	elseif( event == "ADJEST_UI_POS" ) then
		Fuli_ZhanLing_Choose_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Fuli_ZhanLing_Choose_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function Fuli_ZhanLing_Choose_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Fuli_ZhanLing_Choose_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Fuli_ZhanLing_Choose_Frame:GetProperty("UnifiedYPosition");
	Fuli_ZhanLing_Choose_Gift1_Icon:SetEvent("Clicked",string.format( "Fuli_ZhanLing_Choose_ClickItem(%d)",1 ))
	Fuli_ZhanLing_Choose_Gift2_Icon:SetEvent("Clicked",string.format( "Fuli_ZhanLing_Choose_ClickItem(%d)",2 ))

end

function Fuli_ZhanLing_Choose_OpenChoose()
	g_CurIndex = -1
	g_CurChoose = -1
	Fuli_ZhanLing_Choose_Gift1_Mask:Hide()
	Fuli_ZhanLing_Choose_Gift2_Mask:Hide()

	g_CurIndex = tonumber(arg0)
	local nShowC1 = tonumber(arg1)
	local nNumC1 = tonumber(arg2)
	local nShowC2 = tonumber(arg3)
	local nNumC2 = tonumber(arg4)

	local theAction =  DataPool:CreateActionItemForShow(nShowC1, nNumC1)
	Fuli_ZhanLing_Choose_Gift1_Icon:SetActionItem(theAction:GetID())
	Fuli_ZhanLing_Choose_Gift1_Tips:SetText(theAction:GetName())
	
	theAction = DataPool:CreateActionItemForShow(nShowC2, nNumC2)
	Fuli_ZhanLing_Choose_Gift2_Icon:SetActionItem(theAction:GetID())
	Fuli_ZhanLing_Choose_Gift2_Tips:SetText(theAction:GetName())
	this:Show()
end

function Fuli_ZhanLing_Choose_ClickItem(nIndex)
	if nIndex == 1 then
		if g_CurChoose == nIndex then
			--再次点击
			Fuli_ZhanLing_Choose_Gift1_Mask:Hide()
			g_CurChoose = -1
			return 
		else
			Fuli_ZhanLing_Choose_Gift1_Mask:Show()
			Fuli_ZhanLing_Choose_Gift2_Mask:Hide()
		end
	elseif nIndex == 2 then
		if g_CurChoose == nIndex then
			--再次点击
			Fuli_ZhanLing_Choose_Gift2_Mask:Hide()
			g_CurChoose = -1
			return 
		else
			Fuli_ZhanLing_Choose_Gift2_Mask:Show()
			Fuli_ZhanLing_Choose_Gift1_Mask:Hide()
		end
	end
	g_CurChoose = nIndex
end

function Fuli_ZhanLing_Choose_Select()
	-- if g_CurIndex == -1 or g_CurChoose == -1 then
	-- 	PushDebugMessage("#{TLZL_190802_116}")
	-- 	return 
	-- end
	-- Clear_XSCRIPT()
	-- Set_XSCRIPT_Function_Name("AskGetReward")  --脚本接口
	-- Set_XSCRIPT_ScriptID(790029) --脚本编号 
	-- Set_XSCRIPT_Parameter(0,g_CurIndex)
	-- Set_XSCRIPT_Parameter(1,1) -- 付费
	-- Set_XSCRIPT_Parameter(2,g_CurChoose)
	-- Set_XSCRIPT_ParamCount(3)
	-- Send_XSCRIPT()	
	-- this:Hide()
end
--================================================
-- 界面的默认相对位置
--================================================
function Fuli_ZhanLing_Choose_ResetPos()
	Fuli_ZhanLing_Choose_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Fuli_ZhanLing_Choose_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Fuli_ZhanLing_Choose_OnHiden()
	this:Hide()
end