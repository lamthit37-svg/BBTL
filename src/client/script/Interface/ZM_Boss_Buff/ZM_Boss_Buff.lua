-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_GameItemImage = {
	[1] = "set:HuodongSkill_5 image:HuodongSkill_5_11",
	[2] = "set:HuodongSkill_5 image:HuodongSkill_5_3",
	[3] = "set:HuodongSkill_6 image:HuodongSkill_6_3",
	[4] = "set:HuodongSkill_6 image:HuodongSkill_6_12",
	[5] = "set:HuodongSkill_4 image:HuodongSkill_4_15",
	[6] = "set:HuodongSkill_5 image:HuodongSkill_5_7",
	[7] = "set:HuodongSkill_6 image:HuodongSkill_6_16",
	[8] = "set:HuodongSkill_4 image:HuodongSkill_4_11",
	[9] = "set:HuodongSkill_6 image:HuodongSkill_6_7",
	[10] = "set:HuodongSkill_5 image:HuodongSkill_5_15",
	[11] = "set:HuodongSkill_6 image:HuodongSkill_6_11",
	[12] = "set:HuodongSkill_4 image:HuodongSkill_4_10",


}


local g_GameItemText = {
	[1] = "#{ZMB_241021_18}",
	[2] = "#{ZMB_241021_19}",
	[3] = "#{ZMB_241021_20}",
	[4] = "#{ZMB_241021_21}",
	[5] = "#{ZMB_241021_22}",
	[6] = "#{ZMB_241021_23}",
	[7] = "#{ZMB_241021_24}",
	[8] = "#{ZMB_241021_25}",
	[9] = "#{ZMB_241021_26}",
	[10] = "#{ZMB_241021_28}",
	[11] = "#{ZMB_241021_29}",
	[12] = "#{ZMB_241021_30}",
}

local g_GameItemTipsText = {
	[1] = "#{ZMB_241021_39}",
	[2] = "#{ZMB_241021_40}",
	[3] = "#{ZMB_241021_41}",
	[4] = "#{ZMB_241021_42}",
	[5] = "#{ZMB_241021_43}",
	[6] = "#{ZMB_241021_44}",
	[7] = "#{ZMB_241021_45}",
	[8] = "#{ZMB_241021_46}",
	[9] = "#{ZMB_241021_47}",
	[10] = "#{ZMB_241021_49}",
	[11] = "#{ZMB_241021_50}",
	[12] = "#{ZMB_241021_51}",
}

local g_Timer = -1

function ZM_Boss_Buff_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND",true)

end

function ZM_Boss_Buff_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ZM_Boss_Buff_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ZM_Boss_Buff_Frame:GetProperty("UnifiedYPosition");
	
	g_Timer = 3
	
end



function ZM_Boss_Buff_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		ZM_Boss_Buff_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		ZM_Boss_Buff_ResetPos()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 999029011  ) then
		--this:Hide()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 999029010  ) then
		local nGameItem1  = Get_XParam_INT(0) 
		local nGameItem2  = Get_XParam_INT(1) 
		local nGameItemMark1  = Get_XParam_INT(2) 
		local nGameItemMark2  = Get_XParam_INT(3) 
		local nNextTime  = Get_XParam_INT(4) 
		local nTickCount =  Get_XParam_INT(5) 
		if g_GameItemImage[nGameItem1] ~= nil then
			ZM_Boss_Buff_Item1:SetProperty("Image", g_GameItemImage[nGameItem1])
			ZM_Boss_Buff_Item1:SetToolTip(g_GameItemTipsText[nGameItem1])
			ZM_Boss_Buff_Item1:Show()
			if nGameItemMark1 == 0 then
				ZM_Boss_Buff_Item1_Mask:Show()
				ZM_Boss_Buff_Item1_select:SetText("#{ZMB_241021_31}")
				ZM_Boss_Buff_Item1_Mask:SetToolTip(g_GameItemTipsText[nGameItem1])
			else
				ZM_Boss_Buff_Item1_Mask:Hide()
				ZM_Boss_Buff_Item1_select:SetText("#{ZMB_241021_7}")
			end
			
		end
		
		if g_GameItemImage[nGameItem2] ~= nil then
			ZM_Boss_Buff_Item2:SetProperty("Image", g_GameItemImage[nGameItem2])
			ZM_Boss_Buff_Item2:SetToolTip(g_GameItemTipsText[nGameItem2])
			ZM_Boss_Buff_Item2:Show()
			if nGameItemMark2 == 0 then
				ZM_Boss_Buff_Item2_Mask:Show()
				ZM_Boss_Buff_Item2_select:SetText("#{ZMB_241021_31}")
				ZM_Boss_Buff_Item2_Mask:SetToolTip(g_GameItemTipsText[nGameItem2])
			else
				ZM_Boss_Buff_Item2_Mask:Hide()
				ZM_Boss_Buff_Item2_select:SetText("#{ZMB_241021_7}")
			end
			
		end
		if nTickCount <= 30 then
			ZM_Boss_Buff_MenpaiInfo_Text:SetText("#{ZMB_241021_3}")
			ZM_Boss_Buff_MenpaiInfo_Time:Hide()
			ZM_Boss_Buff_MenpaiInfo_Text:Show()
			ZM_Boss_Buff_MenpaiInfo_Timetxt:Hide()
		elseif nNextTime >= 0 then
			ZM_Boss_Buff_MenpaiInfo_Timetxt:SetText("#{ZMB_241021_4}")
			ZM_Boss_Buff_MenpaiInfo_Time:SetProperty("Timer", nNextTime)
			ZM_Boss_Buff_MenpaiInfo_Time:Show()
			ZM_Boss_Buff_MenpaiInfo_Text:Hide()
			ZM_Boss_Buff_MenpaiInfo_Timetxt:Show()
		else
			ZM_Boss_Buff_MenpaiInfo_Text:SetText("#{ZMB_241021_6}")
			ZM_Boss_Buff_MenpaiInfo_Time:Hide()
			ZM_Boss_Buff_MenpaiInfo_Text:Show()
			ZM_Boss_Buff_MenpaiInfo_Timetxt:Hide()
		end
	
		this:Show()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if (GetSceneID() >= 952 and GetSceneID() <= 965) or (GetSceneID() == 1004) then
		
		else
			this:Hide()
		end
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZM_Boss_Buff_ResetPos()
	ZM_Boss_Buff_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ZM_Boss_Buff_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function ZM_Boss_Buff_Confirm()
	this:Hide()
end

function ZM_Boss_Buff_Click(index)
	if index ~= 1 and index ~= 2 then
		return 0
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UseGoodBuff" )
		Set_XSCRIPT_ScriptID(999029)
		Set_XSCRIPT_Parameter(0, index);	
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

function ZM_Boss_Buff_Help()
	
end

