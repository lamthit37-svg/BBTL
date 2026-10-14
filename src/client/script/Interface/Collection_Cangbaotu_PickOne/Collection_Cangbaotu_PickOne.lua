local g_Collection_Cangbaotu_PickOne_UnifiedPosition = nil 
local g_Collection_Cangbaotu_PickOne_bagpos = -1
function Collection_Cangbaotu_PickOne_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("CLOSE_UNIDENT",false)

end 

-- Collection_Cangbaotu_PickOne_PickOne_FrameNULL_Right2 => TLBB_StaticImageNULL
-- Collection_Cangbaotu_PickOne_PickOne_FrameNULL_Left => TLBB_StaticImageNULL
-- Collection_Cangbaotu_PickOne_PickOne_CloseBK => TLBB_StaticImageNULL
-- Collection_Cangbaotu_PickOne_PickOne_Frame => TLBB_MainFrame16
-- Collection_Cangbaotu_PickOne_PickOne_DragTitleBK => TLBB_Frame_Lace37
-- Collection_Cangbaotu_PickOne_PickOne_DragTitle => TLBB_DragTitle
-- Collection_Cangbaotu_PickOne_PickOne_FrameNULL_Right1 => TLBB_StaticImageNULL
function Collection_Cangbaotu_PickOne_OnLoad()
	g_Collection_Cangbaotu_PickOne_UnifiedPosition = Collection_Cangbaotu_PickOne:GetProperty("UnifiedPosition");
end

function Collection_Cangbaotu_PickOne_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 20260407 ) then
		g_Collection_Cangbaotu_PickOne_bagpos = Get_XParam_INT(0)
		local	theAction1 = DataPool:CreateActionItemForShow(39925326, 1)
		if theAction1 then
			Collection_Cangbaotu_PickOne_Yuanbao_Icon:SetActionItem(theAction1:GetID())
		end
		local theAction2 = DataPool:CreateActionItemForShow(39925327, 1)
		if theAction2 then
			Collection_Cangbaotu_PickOne_Yuanbao2_Icon:SetActionItem(theAction2:GetID())
		end		
		
		this:Show()
	elseif(event == "ADJEST_UI_POS") then
		Collection_Cangbaotu_PickOne_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		Collection_Cangbaotu_PickOne_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Collection_Cangbaotu_PickOne_Close()
	elseif(event == "CLOSE_UNIDENT") then
		if tonumber(arg0) == 1 then
			Collection_Cangbaotu_PickOne_Close()
		end
	end
end


function Collection_Cangbaotu_PickOne_On_ResetPos()
	Collection_Cangbaotu_PickOne:SetProperty("UnifiedPosition", g_Collection_Cangbaotu_PickOne_UnifiedPosition)
end



function Collection_Cangbaotu_PickOne_Close()
	PushEvent("CLOSE_UNIDENT",2)
	this:Hide()
end


function Collection_Cangbaotu_PickOne_FashionBuy()

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ClientAskident")
		Set_XSCRIPT_ScriptID(510113)
		Set_XSCRIPT_Parameter(0, g_Collection_Cangbaotu_PickOne_bagpos)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT();
	this:Hide()
end


function Collection_Cangbaotu_PickOne_FashionLiHeBuy()

	PushEvent("UI_COMMAND",20260121,g_Collection_Cangbaotu_PickOne_bagpos)
end