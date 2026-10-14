
local PayReward_Button = {}			--领奖按钮
local PayReward_Button_Tip = {}	
local PayReward_ButtonState = {			-- 按钮状态 0:未达成/1:可领取/2:已领取
	[1] = 0,
	[2] = 0,
	[3] = 0,
}
local bLimitTimePrize = 1				-- 限时奖励物品领取状态
local MD_KAIKACHONGZHI3_EXCH = 726		-- 开卡充值送好礼，累计兑换的元宝
local MD_KAIKACHONGZHI3_COST = 727		-- 开卡充值送好礼，累计消费的元宝
local PayReward_SurplusTime = 0		-- 剩余时间




--**********************************
-- PRELOAD
--**********************************
function PayReward_PreLoad()

	this:RegisterEvent("OPEN_SHOUKAIKA")		-- 打开UI
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	-- 离开场景
	this:RegisterEvent("UI_COMMAND")			-- 界面

end


--**********************************
-- ONLOAD
--**********************************
function PayReward_OnLoad()

	PayReward_Button[ 1 ] = PayReward_Frame2_Bk1_Button
	PayReward_Button[ 2 ] = PayReward_Frame2_Bk2_Button
	PayReward_Button[ 3 ] = PayReward_Frame2_Bk3_Button
	PayReward_Button[ 4 ] = PayReward_Frame2_Bk4_Button
	
	
	PayReward_Button_Tip[ 1 ] = PayReward_Frame2_Bk1_Button_tips
	PayReward_Button_Tip[ 2 ] = PayReward_Frame2_Bk2_Button_tips
	PayReward_Button_Tip[ 3 ] = PayReward_Frame2_Bk3_Button_tips
	PayReward_Button_Tip[ 4 ] = PayReward_Frame2_Bk4_Button_tips

end


--**********************************
-- ONEvent
--**********************************
function PayReward_OnEvent( event )

	if ( event == "OPEN_SHOUKAIKA" ) then
		-- 关闭UI
		if ( IsWindowShow( "PayReward" ) == true ) then
			this : Hide()
			return
		end
		-- 更新
		PayReward_UpdateButtonReq()
		this:Show()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8898532 ) then

		if ( IsWindowShow( "PayReward" ) == false ) then
			return
		end

		PayReward_ButtonState[ 1 ] = Get_XParam_INT( 0 )
		PayReward_ButtonState[ 2 ] = Get_XParam_INT( 1 )
		PayReward_ButtonState[ 3 ] = Get_XParam_INT( 2 )
		bLimitTimePrize = Get_XParam_INT( 3 )
		PayReward_SurplusTime = Get_XParam_INT( 4 )
		-- 更新Btn状态
		PayReward_UpdateButtonAck()
	end

end


--**********************************
-- 更新数据
--**********************************
function PayReward_UpdateData( )

	-- 更新Icon
	PayReward_UpdateIcon()
	
	PayReward_UpdateButton()
	
	PayReward_UpdateText()

end


--**********************************
-- 更新checkbox
--**********************************
function PayReward_UpdateCheckBox( nIndex )


end


--**********************************
-- 更新Button
--**********************************
function PayReward_UpdateButton()
	
	for nIndex = 1 , 3 do
	
		-- 三档奖励
		if ( PayReward_ButtonState[ nIndex ] == 1 ) then
			PayReward_Button[ nIndex ] : Enable()												-- 领取
			PayReward_Button_Tip[ nIndex ] : Hide()
		elseif ( PayReward_ButtonState[ nIndex ] == 2 ) then
			PayReward_Button[ nIndex ] : Disable()
			PayReward_Button[ nIndex ] : SetProperty( "DisabledImage" , "set:ServerNewUI2 image:ServerNewUI_LQ_Disable")		-- 已领取
			PayReward_Button_Tip[ nIndex ] : Show()
			PayReward_Button_Tip[ nIndex ] : SetToolTip( "#{SCJMY_150325_7}")
		else
			PayReward_Button[ nIndex ] : Disable()
			PayReward_Button[ nIndex ] : SetProperty( "DisabledImage" , "set:ServerNewUI2 image:ServerNewUI_LQ_WDC")	-- 未达成
			PayReward_Button_Tip[ nIndex ] : Show()
			PayReward_Button_Tip[ nIndex ] : SetToolTip("#{SCJMY_150325_5}")
		end
	
	end
	
	-- 限时奖励
	if ( bLimitTimePrize == 0 ) then
		if ( PayReward_SurplusTime == -1 ) then
			PayReward_Button[ 4 ] : Enable()
			PayReward_Button_Tip[ 4 ] : Hide()
		else
			PayReward_Button[ 4 ] : Disable()
			PayReward_Button[ 4 ] : SetProperty( "DisabledImage" , "set:ServerNewUI2 image:ServerNewUI_LQ_WDC")	-- 未达成
			PayReward_Button_Tip[ 4 ] : Show()
			PayReward_Button_Tip[ 4 ] : SetToolTip("#{SCJMY_150325_5}")
		end
	else
		PayReward_Button[ 4 ] : Disable()
		PayReward_Button[ 4 ] : SetProperty( "DisabledImage" , "set:ServerNewUI2 image:ServerNewUI_LQ_Disable")			-- 已领取
		PayReward_Button_Tip[ 4 ] : Show()
		PayReward_Button_Tip[ 4 ] : SetToolTip( "#{SCJMY_150325_7}")
	end
end


--**********************************
-- 更新Icon
--**********************************
function PayReward_UpdateIcon()

	-- 刷新Item
	DataPool : Lua_UpdateShouKaiKaItem()
	
	--第一档
	PayReward_Frame2_Bk1_Icon2 : SetActionItem( -1 )
	PayReward_Frame2_Bk1_Icon2 : Hide()
		
	local theAction0 = EnumAction( 0, "shoukaika_item" )
	if ( theAction0 : GetID() ~= 0 ) then
		PayReward_Frame2_Bk1_Icon2 : SetActionItem( theAction0 : GetID() )
		PayReward_Frame2_Bk1_Icon2 : Show()
	end
	
	PayReward_Frame2_Bk1_Icon3 : SetActionItem( -1 )
	PayReward_Frame2_Bk1_Icon3 : Hide()
		
	local theAction1 = EnumAction( 1, "shoukaika_item" )
	if ( theAction1 : GetID() ~= 0 ) then
		PayReward_Frame2_Bk1_Icon3 : SetActionItem( theAction1 : GetID() )
		PayReward_Frame2_Bk1_Icon3 : Show()
	end
	
	
	--第二档
	PayReward_Frame2_Bk2_Icon2 : SetActionItem( -1 )
	PayReward_Frame2_Bk2_Icon2 : Hide()
		
	local theAction12 = EnumAction( 12 , "shoukaika_item" )
	if Player:GetData("Is2606S") == 1 then
		theAction12 = DataPool:CreateActionItemForShow(30008027, 2)
	end
	if ( theAction12 : GetID() ~= 0 ) then
		PayReward_Frame2_Bk2_Icon2 : SetActionItem( theAction12 : GetID() )
		PayReward_Frame2_Bk2_Icon2 : Show()
	end
	
	--第三档
	PayReward_Frame2_Bk3_Icon2 : SetActionItem( -1 )
	PayReward_Frame2_Bk3_Icon2 : Hide()
		
	local theAction24 = EnumAction( 24 , "shoukaika_item" )
	if ( theAction24 : GetID() ~= 0 ) then
		PayReward_Frame2_Bk3_Icon2 : SetActionItem( theAction24 : GetID() )
		PayReward_Frame2_Bk3_Icon2 : Show()
	end
	

	--限时
	PayReward_Frame2_Bk4_Icon2	: SetActionItem( -1 )
	PayReward_Frame2_Bk4_Icon2 : Hide()
	
	local theAction34 = EnumAction( 34 , "shoukaika_item" )
	if Player:GetData("Is2606S") == 1 then
		theAction34 = DataPool:CreateActionItemForShow(30008027, 2)
	end
	if ( theAction34 : GetID() ~= 0 ) then
		PayReward_Frame2_Bk4_Icon2 : SetActionItem( theAction34 : GetID() )
		PayReward_Frame2_Bk4_Icon2 : Show()
	end


end


--**********************************
-- 请求更新Button
--**********************************
function PayReward_UpdateButtonReq()
	
	-- 等级
	local nLevel = Player:GetLevel()
	if ( nLevel < 15 ) then
		return
	end

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateGetPrizeBtnState" ) 
		Set_XSCRIPT_ScriptID( 889853 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end


--**********************************
-- 反馈更新Button
--**********************************
function PayReward_UpdateButtonAck()
	PayReward_UpdateData( )
end


--**********************************
-- 更新Text
--**********************************
function PayReward_UpdateText()
	
	PayReward_Frame2_StopWatch : Hide()
	PayReward_Frame2_StopWatch : SetProperty( "Timer", "0" )
	
	local mdCost = DataPool:GetPlayerMission_DataRound( MD_KAIKACHONGZHI3_COST )		-- 累计消耗元宝数
	local mdExch = DataPool:GetPlayerMission_DataRound( MD_KAIKACHONGZHI3_EXCH )		-- 累计兑换元宝数
	
	local txtInfo = ScriptGlobal_Format( "#{KJRK_130613_46}", mdExch, mdCost )
	PayReward_Blank_Text : SetText( txtInfo )
	
	if PayReward_ButtonState[ 1 ] == 1 or PayReward_ButtonState[ 1 ] == 2 then	
		PayReward_Frame2_Bk1_Text1_1:SetText("#{SCJMY_150325_3}")
		PayReward_Frame2_Bk1_Text1_2:SetText("#{SCJMY_150325_4}")
	
	else
		PayReward_Frame2_Bk1_Text1_1:SetText("#{SCJMY_150325_1}")
		PayReward_Frame2_Bk1_Text1_2:SetText("#{SCJMY_150325_2}")
	
	end
	
	
	if PayReward_ButtonState[ 2 ] == 1 or PayReward_ButtonState[ 2 ] == 2 then	
		PayReward_Frame2_Bk2_Text1_1:SetText("#{SCJMY_150325_11}")
		PayReward_Frame2_Bk2_Text1_2:SetText("#{SCJMY_150325_12}")
		PayReward_Frame2_Bk2_Text2_1:SetText("#{SCJMY_150325_13}")
		PayReward_Frame2_Bk2_Text2_2:SetText("#{SCJMY_150325_12}")
	
	else
		
		if mdExch >= 2000 then
			PayReward_Frame2_Bk2_Text1_1:SetText("#{SCJMY_150325_11}")	
			PayReward_Frame2_Bk2_Text1_2:SetText("#{SCJMY_150325_12}")	
		else
			PayReward_Frame2_Bk2_Text1_1:SetText("#{SCJMY_150325_8}")	
			txtInfo = ScriptGlobal_Format( "#{SCJMY_150325_9}", mdExch )
			PayReward_Frame2_Bk2_Text1_2:SetText(txtInfo)
		end
		
		if mdCost >= 2000 then
			PayReward_Frame2_Bk2_Text2_1:SetText("#{SCJMY_150325_13}")
			PayReward_Frame2_Bk2_Text2_2:SetText("#{SCJMY_150325_12}")
		else
			PayReward_Frame2_Bk2_Text2_1:SetText("#{SCJMY_150325_10}")
			txtInfo = ScriptGlobal_Format( "#{SCJMY_150325_9}", mdCost )
			PayReward_Frame2_Bk2_Text2_2:SetText(txtInfo)
		end
	end
	
	
	if PayReward_ButtonState[ 3 ] == 1 or PayReward_ButtonState[ 3 ] == 2 then	
		PayReward_Frame2_Bk3_Text1_1:SetText("#{SCJMY_150325_11}")
		PayReward_Frame2_Bk3_Text1_2:SetText("#{SCJMY_150325_15}")
		PayReward_Frame2_Bk3_Text2_1:SetText("#{SCJMY_150325_13}")
		PayReward_Frame2_Bk3_Text2_2:SetText("#{SCJMY_150325_15}")
	
	else
		
		local nValue = mdExch
		if mdExch >= 4000 then
			PayReward_Frame2_Bk3_Text1_1:SetText("#{SCJMY_150325_11}")
			PayReward_Frame2_Bk3_Text1_2:SetText("#{SCJMY_150325_15}")
		else
			PayReward_Frame2_Bk3_Text1_1:SetText("#{SCJMY_150325_8}")
			txtInfo = ScriptGlobal_Format( "#{SCJMY_150325_14}", mdExch )
			PayReward_Frame2_Bk3_Text1_2:SetText(txtInfo)
		end
		
		if mdCost >= 4000 then
			PayReward_Frame2_Bk3_Text2_1:SetText("#{SCJMY_150325_13}")
			PayReward_Frame2_Bk3_Text2_2:SetText("#{SCJMY_150325_15}")
		else
			PayReward_Frame2_Bk3_Text2_1:SetText("#{SCJMY_150325_10}")
			txtInfo = ScriptGlobal_Format( "#{SCJMY_150325_14}", mdCost )
			PayReward_Frame2_Bk3_Text2_2:SetText(txtInfo)
		end
	end
	
	-- 限时奖励
	if PayReward_SurplusTime == -1 then
		PayReward_Frame2_Info_Text : Show()
		PayReward_Frame2_Info_Text : SetText("#{SCJMY_150325_19}")						--限时礼馈奖励已达成
		PayReward_Frame2_Info_New2 : Hide()
		
		PayReward_Frame2_Bk4_Text1_1:SetText("#{SCJMY_150325_11}")
		PayReward_Frame2_Bk4_Text1_2:SetText("#{SCJMY_150325_15}")
		PayReward_Frame2_Bk4_Text2_1:SetText("#{SCJMY_150325_13}")
		PayReward_Frame2_Bk4_Text2_2:SetText("#{SCJMY_150325_15}")
	elseif PayReward_SurplusTime == -2 then 
		PayReward_Frame2_Info_Text : Show()
		PayReward_Frame2_Info_Text : SetText("#{SCJMY_150325_20}")						--限时礼馈超时未达成
		PayReward_Frame2_Info_New2 : Hide()
		
		PayReward_Frame2_Bk4_Text1_1:SetText("")
		PayReward_Frame2_Bk4_Text1_2:SetText("")
		PayReward_Frame2_Bk4_Text2_1:SetText("")
		PayReward_Frame2_Bk4_Text2_2:SetText("")
	elseif PayReward_SurplusTime == 0 then
		PayReward_Frame2_Info_Text : Show()
		PayReward_Frame2_Info_Text : SetText("#{SCJMY_150325_16}")						--自达成一重礼馈条件起的72小时内
		PayReward_Frame2_Info_New2 : Hide()
		
		if mdExch >= 4000 then
			PayReward_Frame2_Bk4_Text1_1:SetText("#{SCJMY_150325_11}")
			PayReward_Frame2_Bk4_Text1_2:SetText("#{SCJMY_150325_15}")
		else
			PayReward_Frame2_Bk4_Text1_1:SetText("#{SCJMY_150325_8}")
			txtInfo = ScriptGlobal_Format( "#{SCJMY_150325_14}", mdExch )
			PayReward_Frame2_Bk4_Text1_2:SetText(txtInfo)
		end
		
		if mdCost >= 4000 then
			PayReward_Frame2_Bk4_Text2_1:SetText("#{SCJMY_150325_13}")
			PayReward_Frame2_Bk4_Text2_2:SetText("#{SCJMY_150325_15}")
		else
			PayReward_Frame2_Bk4_Text2_1:SetText("#{SCJMY_150325_10}")
			txtInfo = ScriptGlobal_Format( "#{SCJMY_150325_14}", mdCost )
			PayReward_Frame2_Bk4_Text2_2:SetText(txtInfo)
		end
	elseif PayReward_SurplusTime > 0 then
		
		PayReward_Frame2_Info_Text : Hide()
		PayReward_Frame2_Info_New2 : Show()
		PayReward_Frame2_Info_New2:SetText("#{SCJMY_150325_17}")						--剩余奖励达成时间：

		if mdExch >= 4000 then
			PayReward_Frame2_Bk4_Text1_1:SetText("#{SCJMY_150325_11}")
			PayReward_Frame2_Bk4_Text1_2:SetText("#{SCJMY_150325_15}")
		else
			PayReward_Frame2_Bk4_Text1_1:SetText("#{SCJMY_150325_8}")
			txtInfo = ScriptGlobal_Format( "#{SCJMY_150325_14}", mdExch )
			PayReward_Frame2_Bk4_Text1_2:SetText(txtInfo)
		end
		
		if mdCost >= 4000 then
			PayReward_Frame2_Bk4_Text2_1:SetText("#{SCJMY_150325_13}")
			PayReward_Frame2_Bk4_Text2_2:SetText("#{SCJMY_150325_15}")
		else
			PayReward_Frame2_Bk4_Text2_1:SetText("#{SCJMY_150325_10}")
			txtInfo = ScriptGlobal_Format( "#{SCJMY_150325_14}", mdCost )
			PayReward_Frame2_Bk4_Text2_2:SetText(txtInfo)
		end
		
		PayReward_Frame2_StopWatch : Show();
		PayReward_Frame2_StopWatch : SetProperty( "Timer", tostring(PayReward_SurplusTime) )

	end

end


--**********************************
-- CheckBox
--**********************************
function PayReward_CheckBoxClicked( nIdx )

	

end


--**********************************
-- 按钮
--**********************************
function PayReward_Clicked( nIdx )

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetNewPrizes" )				-- 脚本号
		Set_XSCRIPT_ScriptID( 889853 );											-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIdx ) )					-- 参数一
		Set_XSCRIPT_ParamCount( 1 )												-- 参数个数
	Send_XSCRIPT()
end


--**********************************
-- 关闭
--**********************************
function PayReward_OnHiden()
	
	PayReward_Frame2_Bk1_Icon2 : SetActionItem( -1 )	
	PayReward_Frame2_Bk1_Icon3 : SetActionItem( -1 )
	
	PayReward_Frame2_Bk2_Icon2 : SetActionItem( -1 )
	PayReward_Frame2_Bk3_Icon2 : SetActionItem( -1 )
	PayReward_Frame2_Bk4_Icon2 : SetActionItem( -1 )
end
