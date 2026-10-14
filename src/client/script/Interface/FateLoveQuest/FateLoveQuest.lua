--情缘设置二次确认
FateLoveQuest_g_type = 0
FateLoveQuest_g_ParamList = {}
--===============================================
-- OnLoad()
--===============================================
function FateLoveQuest_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("TALENT_LEARN_CONFIRM")
	
	this:RegisterEvent("MARTIAL_ADVACEN_CONFIRM")
	
	this:RegisterEvent("MARTIAL_ZHAOHUI_COMFIRM")
    --this:RegisterEvent("JINFENGHAODU_CONFIRM")
    --this:RegisterEvent("JINFENGHAODU_REWARD_CONFIRM")
	
end

function FateLoveQuest_OnLoad()
	-- 保存界面的默认相对位置
	g_FateLoveQuest_Frame_UnifiedXPosition	= FateLoveQuest_Frame : GetProperty("UnifiedXPosition");
	g_FateLoveQuest_Frame_UnifiedYPosition	= FateLoveQuest_Frame : GetProperty("UnifiedYPosition");
end
--===============================================
-- OnEvent()
--===============================================
function FateLoveQuest_OnEvent(event)

	if(event == "TALENT_LEARN_CONFIRM") then
		local nStrTip = tostring(arg0)
		local nLayer = tonumber(arg1)
		local nTalentId = tonumber(arg2)
		FateLoveQuest_MartialTalentLearnConfirm(nStrTip,nLayer,nTalentId)
	elseif(event == "MARTIAL_ADVACEN_CONFIRM") then
		local nStrTip = tostring(arg0)
		FateLoveQuest_MartialAdvanceConfirm(nStrTip)
	elseif(event == "MARTIAL_ZHAOHUI_COMFIRM" ) then
		local nType = tonumber(arg0)
		local nMonsterNum = tonumber(arg1)
		local nCostNum = tonumber(arg2)
		local nRewardExp = tonumber(arg3)
		local LastLeftNum = tonumber(arg4)
		FateLoveQuest_MartialZhaoHuiConfirm(nType,nMonsterNum,nCostNum,nRewardExp,LastLeftNum)
    elseif(event =="JINFENGHAODU_CONFIRM") then
        FL_JF_Confirm(tonumber(arg0), tonumber(arg1), tonumber(arg2))
    elseif(event == "JINFENGHAODU_REWARD_CONFIRM") then
        FL_JF_Reward_Confirm(tonumber(arg0), tonumber(arg1))
  elseif  (event == "UI_COMMAND") and (arg0 == "50701001") then		 
		local szMsg 			 = Get_XParam_STR(0); 
		local Type				 = Get_XParam_INT(0) 
		FateLoveQuest_MartialZhaoHuiConfirmBySvr(szMsg,Type)	
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		FateLoveQuest_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		FateLoveQuest_Frame_On_ResetPos()
	end
end

--===============================================
-- OnHiden
--===============================================
function FateLoveQuest_Frame_OnHiden()
	FateLoveQuest_ClaerParamList()
	this:Hide()
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function FateLoveQuest_Frame_On_ResetPos()

	FateLoveQuest_Frame : SetProperty("UnifiedXPosition", g_FateLoveQuest_Frame_UnifiedXPosition);
	FateLoveQuest_Frame : SetProperty("UnifiedYPosition", g_FateLoveQuest_Frame_UnifiedYPosition);

end
function FateLoveQuest_UpdateRect()
	local nWidth, nHeight = FateLoveQuest_InfoWindow:GetWindowSize();
	local nTitleHeight = 23;
	local nBottomHeight = 25;
	local nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	FateLoveQuest_Frame_sub:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end

function FateLoveQuest_ShowWindow(bShowBtn1,bShowBtn2)
	if(bShowBtn1 == true) then
		FateLoveQuest_Button1:Show()
	else
		FateLoveQuest_Button1:Hide()
	end
	if(bShowBtn2 == true) then
		FateLoveQuest_Button2:Show()
	else
		FateLoveQuest_Button2:Hide()
	end
	FateLoveQuest_UpdateRect()
	this:Show()
end

function FateLoveQuest_ClaerParamList()
	FateLoveQuest_g_ParamList = {}
end

function FateLoveQuest_Bn1Click()
	if(1 == FateLoveQuest_g_type) then
	elseif(2 == FateLoveQuest_g_type) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "LearnTalent" )
			Set_XSCRIPT_ScriptID( 507011 )
			Set_XSCRIPT_Parameter(0,FateLoveQuest_g_ParamList[1])
			Set_XSCRIPT_Parameter(1,FateLoveQuest_g_ParamList[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (4 == FateLoveQuest_g_type ) then
		-- 这里只保留金币找回
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "MartialLastDayMonsterReward" )
			Set_XSCRIPT_ScriptID( 507010 )
			Set_XSCRIPT_Parameter(0,FateLoveQuest_g_ParamList[1])
			Set_XSCRIPT_Parameter(1,0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
    elseif (5 == FateLoveQuest_g_type) then
        PushEvent("JINFENGHAODU_SELECT_UI")
    elseif (6 == FateLoveQuest_g_type) then
        PushEvent("JINFENGHAODU_REWARD_RESP", 1)
  elseif (7 == FateLoveQuest_g_type) then      
    Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "MartialLastDayMonsterReward" )
			Set_XSCRIPT_ScriptID( 507010 )
			Set_XSCRIPT_Parameter(0,FateLoveQuest_g_ParamList[1])
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
	FateLoveQuest_ClaerParamList()
	this:Hide()
end

function FateLoveQuest_Bn2Click()
    if (6 == FateLoveQuest_g_type) then
        PushEvent("JINFENGHAODU_REWARD_RESP", 2)
    end

	FateLoveQuest_ClaerParamList()
	this:Hide()
end

function FateLoveQuest_MartialTalentLearnConfirm(Tip,layer,nTalentId)
	FateLoveQuest_g_type = 2
	FateLoveQuest_g_ParamList[1] = layer
	FateLoveQuest_g_ParamList[2] = nTalentId
	FateLoveQuest_InfoWindow:SetText(Tip)
	FateLoveQuest_Button1:SetText("#{WYXT_20170803_52}") 	--狠心的关闭
	FateLoveQuest_Button2:SetText("#{WYXT_20170803_53}") 	--我在考虑下
	FateLoveQuest_ShowWindow(true,true)
end

function FateLoveQuest_MartialAdvanceConfirm(Tip)
	FateLoveQuest_g_type = 3
	FateLoveQuest_InfoWindow:SetText(Tip)
	FateLoveQuest_Button2:SetText("#{WYXT_20170907_328}") 	--我在考虑下
	FateLoveQuest_ShowWindow(false,true)
end

function FateLoveQuest_MartialZhaoHuiConfirm(nType,nMonsterNum,nCostNum,nRewardExp,LastLeftNum)
	FateLoveQuest_g_type = 4
	FateLoveQuest_g_ParamList[1] = nType
	local strTip = ""
	if(nType == 1) then
		if(nMonsterNum == LastLeftNum) then
			strTip = ScriptGlobal_Format("#{WYXT_20170907_434}",LastLeftNum,nCostNum,nRewardExp)
		else
			strTip = ScriptGlobal_Format("#{WYXT_20170907_427}",nMonsterNum,nCostNum,nMonsterNum,nRewardExp)
		end
	else
		return
	end
	FateLoveQuest_InfoWindow:SetText(strTip)
	FateLoveQuest_Button1:SetText("#{WYXT_20170907_425}") 	--确认
	FateLoveQuest_Button2:SetText("#{WYXT_20170907_426}") 	--取消
	FateLoveQuest_ShowWindow(true,true)
end

function FateLoveQuest_MartialZhaoHuiConfirmBySvr(szMsg,Type)
	FateLoveQuest_g_type = 7
	FateLoveQuest_g_ParamList[1] = Type
	FateLoveQuest_InfoWindow:SetText(szMsg)
	FateLoveQuest_Button1:SetText("#{NXHS_20201111_03}") 	--确认
	FateLoveQuest_Button2:SetText("#{NXHS_20201111_04}") 	--取消
	FateLoveQuest_ShowWindow(true,true)
end

function FL_JF_Confirm(fengyebi, win, lose)
    FateLoveQuest_g_type = 5

    local msg = ScriptGlobal_Format("#{JFHD_180803_33}", fengyebi, win, lose)
    FateLoveQuest_InfoWindow:SetText(msg)
	FateLoveQuest_Button1:SetText("#{WYXT_20170907_425}") 	--确认
	FateLoveQuest_Button2:SetText("#{WYXT_20170907_426}") 	--取消
	FateLoveQuest_ShowWindow(true,true)
end

function FL_JF_Reward_Confirm(fengyebi, remain_times)
    FateLoveQuest_g_type = 6

    local msg
    if remain_times and remain_times >= 3 then
        msg = ScriptGlobal_Format("#{JFHD_180803_40}", fengyebi)
    else
        msg = ScriptGlobal_Format("#{JFHD_180803_41}", remain_times, fengyebi)
    end
    FateLoveQuest_InfoWindow:SetText(msg)
	FateLoveQuest_Button1:SetText("#{WYXT_20170907_425}") 	--确认
	FateLoveQuest_Button2:SetText("#{WYXT_20170907_426}") 	--取消
	FateLoveQuest_ShowWindow(true,true)
end
