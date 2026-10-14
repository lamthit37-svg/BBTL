-- 快捷功能入口 乾坤袋
-- PushDebugMessage
-- this:Show();
-- this:Hide();

local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},
										}
local QiankunBagSPButton = {}
local QiankunBagSPIcon = {}	-- 乾坤袋icon
local QiankunBagSP_FrameInfo = {}	-- 乾坤袋Frame
local QiankunBagSP_Info = {}	-- 乾坤袋Info
local QiankunBagSPLevel = {	-- 领奖等级限制
	[1] = 10,
	[2] = 20,
	[3] = 30,
	[4] = 35,
	[5] = 40,
	[6] = 45,
	[7] = 50,
	[8] = 55,
}
local QiankunBagSPBtnState = {		-- 乾坤袋按钮状态
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}

local QiankunBagSPText1Info = {		-- TextInfo
	[1] = "#{SJJLYH_160315_01}",	-- #cfff263 10级奖励
	[2] = "#{SJJLYH_160315_02}",	-- #cfff263 20级奖励
	[3] = "#{SJJLYH_160315_03}",	-- #cfff263 30级奖励
	[4] = "#{SJJLYH_160315_04}",	-- #cfff263 35级奖励
	[5] = "#{SJJLYH_160315_05}",	-- #cfff263 40级奖励
	[6] = "#{SJJLYH_160315_06}",	-- #cfff263 45级奖励
	[7] = "#{SJJLYH_160315_07}",	-- #cfff263 50级奖励
	[8] = "#{SJJLYH_160315_08}",	-- #cfff263 55级奖励
}

local QiankunBagSPText2Info = {		-- TextInfo
	[1] = "#{SJJLYH_160315_09}",	-- #cfff263 10级奖励
	[2] = "#{SJJLYH_160315_10}",	-- #cfff263 20级奖励
	[3] = "#{SJJLYH_160315_11}",	-- #cfff263 30级奖励
	[4] = "#{SJJLYH_160315_12}",	-- #cfff263 35级奖励
	[5] = "#{SJJLYH_160315_13}",	-- #cfff263 40级奖励
	[6] = "#{SJJLYH_160315_14}",	-- #cfff263 45级奖励
	[7] = "#{SJJLYH_160315_15}",	-- #cfff263 50级奖励
	[8] = "#{SJJLYH_160315_16}",	-- #cfff263 55级奖励
}

local g_QiankunBagSP_Frame_UnifiedPosition;

--**********************************
-- PRELOAD
--**********************************
function QiankunBagSP_PreLoad()

	this:RegisterEvent("OPEN_QIANKUNDAI_SP");		-- 打开UI
	this:RegisterEvent("UNIT_LEVEL");			-- 升级
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	-- 离开场景
	this:RegisterEvent("UI_COMMAND")			-- 界面
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")


end




--**********************************
-- ONLOAD
--**********************************
function QiankunBagSP_OnLoad()

	-- icon
	QiankunBagSPIcon[1] = {QiankunBagSP_Frame2_Icon1, QiankunBagSP_Frame2_Icon2, QiankunBagSP_Frame2_Icon3}
	QiankunBagSPIcon[2] = {QiankunBagSP_Frame3_Icon1, QiankunBagSP_Frame3_Icon2, QiankunBagSP_Frame3_Icon3}
	QiankunBagSPIcon[3] = {QiankunBagSP_Frame4_Icon1, QiankunBagSP_Frame4_Icon2, QiankunBagSP_Frame4_Icon3}
	QiankunBagSPIcon[4] = {QiankunBagSP_Frame5_Icon1, QiankunBagSP_Frame5_Icon2, QiankunBagSP_Frame5_Icon3}
	QiankunBagSPIcon[5] = {QiankunBagSP_Frame6_Icon1, QiankunBagSP_Frame6_Icon2, QiankunBagSP_Frame6_Icon3}
	QiankunBagSPIcon[6] = {QiankunBagSP_Frame7_Icon1, QiankunBagSP_Frame7_Icon2, QiankunBagSP_Frame7_Icon3}
	QiankunBagSPIcon[7] = {QiankunBagSP_Frame8_Icon1, QiankunBagSP_Frame8_Icon2, QiankunBagSP_Frame8_Icon3}
	QiankunBagSPIcon[8] = {QiankunBagSP_Frame9_Icon1, QiankunBagSP_Frame9_Icon2, QiankunBagSP_Frame9_Icon3}

	-- Frame
	QiankunBagSP_FrameInfo[1] = QiankunBagSP_Frame2_Info
	QiankunBagSP_FrameInfo[2] = QiankunBagSP_Frame3_Info
	QiankunBagSP_FrameInfo[3] = QiankunBagSP_Frame4_Info
	QiankunBagSP_FrameInfo[4] = QiankunBagSP_Frame5_Info
	QiankunBagSP_FrameInfo[5] = QiankunBagSP_Frame6_Info
	QiankunBagSP_FrameInfo[6] = QiankunBagSP_Frame7_Info
	QiankunBagSP_FrameInfo[7] = QiankunBagSP_Frame8_Info
	QiankunBagSP_FrameInfo[8] = QiankunBagSP_Frame9_Info


	-- Text
	QiankunBagSP_Info[1] = QiankunBagSP_Frame2_Info1
	QiankunBagSP_Info[2] = QiankunBagSP_Frame3_Info1
	QiankunBagSP_Info[3] = QiankunBagSP_Frame4_Info1
	QiankunBagSP_Info[4] = QiankunBagSP_Frame5_Info1
	QiankunBagSP_Info[5] = QiankunBagSP_Frame6_Info1
	QiankunBagSP_Info[6] = QiankunBagSP_Frame7_Info1
	QiankunBagSP_Info[7] = QiankunBagSP_Frame8_Info1
	QiankunBagSP_Info[8] = QiankunBagSP_Frame9_Info1

	QiankunBagSPButton[1] = {button=QiankunBagSP_Frame2_Button,mask1=QiankunBagSP_Frame2_Mask1,mask2=QiankunBagSP_Frame2_Mask2,mask3=QiankunBagSP_Frame2_Mask3,tips=QiankunBagSP_Frame2_ButtonTips}
	QiankunBagSPButton[2] = {button=QiankunBagSP_Frame3_Button,mask1=QiankunBagSP_Frame3_Mask1,mask2=QiankunBagSP_Frame3_Mask2,mask3=QiankunBagSP_Frame3_Mask3,tips=QiankunBagSP_Frame3_ButtonTips}
	QiankunBagSPButton[3] = {button=QiankunBagSP_Frame4_Button,mask1=QiankunBagSP_Frame4_Mask1,mask2=QiankunBagSP_Frame4_Mask2,mask3=QiankunBagSP_Frame4_Mask3,tips=QiankunBagSP_Frame4_ButtonTips}
	QiankunBagSPButton[4] = {button=QiankunBagSP_Frame5_Button,mask1=QiankunBagSP_Frame5_Mask1,mask2=QiankunBagSP_Frame5_Mask2,mask3=QiankunBagSP_Frame5_Mask3,tips=QiankunBagSP_Frame5_ButtonTips}
	QiankunBagSPButton[5] = {button=QiankunBagSP_Frame6_Button,mask1=QiankunBagSP_Frame6_Mask1,mask2=QiankunBagSP_Frame6_Mask2,mask3=QiankunBagSP_Frame6_Mask3,tips=QiankunBagSP_Frame6_ButtonTips}
	QiankunBagSPButton[6] = {button=QiankunBagSP_Frame7_Button,mask1=QiankunBagSP_Frame7_Mask1,mask2=QiankunBagSP_Frame7_Mask2,mask3=QiankunBagSP_Frame7_Mask3,tips=QiankunBagSP_Frame7_ButtonTips}
	QiankunBagSPButton[7] = {button=QiankunBagSP_Frame8_Button,mask1=QiankunBagSP_Frame8_Mask1,mask2=QiankunBagSP_Frame8_Mask2,mask3=QiankunBagSP_Frame8_Mask3,tips=QiankunBagSP_Frame8_ButtonTips}
	QiankunBagSPButton[8] = {button=QiankunBagSP_Frame9_Button,mask1=QiankunBagSP_Frame9_Mask1,mask2=QiankunBagSP_Frame9_Mask2,mask3=QiankunBagSP_Frame9_Mask10,tips=QiankunBagSP_Frame9_ButtonTips}

	-- QiankunBagSPButton[1] = QiankunBagSP_Frame2_Button
	-- QiankunBagSPButton[2] = QiankunBagSP_Frame3_Button
	-- QiankunBagSPButton[3] = QiankunBagSP_Frame4_Button
	-- QiankunBagSPButton[4] = QiankunBagSP_Frame5_Button
	-- QiankunBagSPButton[5] = QiankunBagSP_Frame6_Button
	-- QiankunBagSPButton[6] = QiankunBagSP_Frame7_Button
	-- QiankunBagSPButton[7] = QiankunBagSP_Frame8_Button
	-- QiankunBagSPButton[8] = QiankunBagSP_Frame9_Button


	g_QiankunBagSP_Frame_UnifiedPosition = QiankunBagSP_Frame:GetProperty("UnifiedPosition")

	g_ButtonPos[1].x	= QiankunBagSP_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= QiankunBagSP_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= QiankunBagSP_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= QiankunBagSP_Button3tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[2].x	= QiankunBagSP_Button6:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= QiankunBagSP_Button6:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= QiankunBagSP_Button6tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= QiankunBagSP_Button6tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[3].x	= QiankunBagSP_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= QiankunBagSP_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= QiankunBagSP_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= QiankunBagSP_Button5tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= QiankunBagSP_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= QiankunBagSP_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= QiankunBagSP_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= QiankunBagSP_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[5].x	= QiankunBagSP_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= QiankunBagSP_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= QiankunBagSP_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= QiankunBagSP_Button8tips:GetProperty("UnifiedYPosition");


end


--**********************************
-- ONEvent
--**********************************
function QiankunBagSP_OnEvent( event )
	--QiankunBagSP_Button5tips : Hide()

	if ( event == "OPEN_QIANKUNDAI_SP" ) then
		-- 关闭UI
		if ( IsWindowShow( "QiankunBagSP" ) == true ) then
			this : Hide();
			return
		end
		if (tonumber(arg0) == 0) then
			QiankunBagSP_On_ResetPos()
		else
			QiankunBagSP_On_SetLastPos()
		end
		-- 更新数据
		QiankunBagSP_UpdateData();

	elseif ( event == "UNIT_LEVEL" ) then
		-- UI状态
		if ( IsWindowShow( "QiankunBagSP" ) == false ) then
			return
		end
		-- 更新数据
		QiankunBagSP_UpdateData();
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 8889073 ) then
		-- 取参数
		QiankunBagSPBtnState[ 1 ] = Get_XParam_INT( 0 );
		QiankunBagSPBtnState[ 2 ] = Get_XParam_INT( 1 );
		QiankunBagSPBtnState[ 3 ] = Get_XParam_INT( 2 );
		QiankunBagSPBtnState[ 4 ] = Get_XParam_INT( 3 );
		QiankunBagSPBtnState[ 5 ] = Get_XParam_INT( 4 );
		QiankunBagSPBtnState[ 6 ] = Get_XParam_INT( 5 );
		QiankunBagSPBtnState[ 7 ] = Get_XParam_INT( 6 );
		QiankunBagSPBtnState[ 8 ] = Get_XParam_INT( 7 );
		-- 更新TextInfo
		QiankunBagSP_UpdateTextInfo();
		-- 更新Btn
		QiankunBagSP_UpdateButtonAck();
		-- icon
		QiankunBagSP_UpdateIcon();
		QiankunBagSP_Refresh_ButtonTips()
	elseif (event == "ADJEST_UI_POS") then
		QiankunBagSP_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QiankunBagSP_On_ResetPos()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8889074 ) then
		QiankunBagSP_UpdateData();
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		if this:IsVisible() then
			QiankunBagSP_UpdateData();
		else
			QiankunBagSP_Refresh_ButtonTips()
		end
	end

end


--**********************************
-- 更新Data
--**********************************
function QiankunBagSP_UpdateData()

--PushDebugMessage("QiankunBag")


	local nSalaryTask = 3
	local nShaoDang = 4
	local nOneDay = 5

	local nLevel = Player:GetLevel();
	if ( nLevel < 35 or DataPool:GetServerDayTime() > 20211016) then
		QiankunBagSP_Button6:Hide()
		nSalaryTask = -1
		nShaoDang = nShaoDang - 1
		nOneDay = nOneDay-1
	else
		QiankunBagSP_Button6:Show()
	end

	QiankunBagSP_Button5:Show()
	if ( nLevel < 60 ) then
		QiankunBagSP_Button5:Hide()
		nShaoDang = -1
		nOneDay = nOneDay-1
	end

	if nSalaryTask ~= -1 then
		QiankunBagSP_Button6:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].x);
		QiankunBagSP_Button6:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].y);
		QiankunBagSP_Button6tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].tipx);
		QiankunBagSP_Button6tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].tipy);
	end

	if nShaoDang ~= -1 then
		QiankunBagSP_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
		QiankunBagSP_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
		QiankunBagSP_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
		QiankunBagSP_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);
	end

	if nOneDay ~= -1 then
		QiankunBagSP_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		QiankunBagSP_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		QiankunBagSP_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		QiankunBagSP_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);

		QiankunBagSP_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay+1].x);
		QiankunBagSP_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay+1].y);
		QiankunBagSP_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay+1].tipx);
		QiankunBagSP_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay+1].tipy);
	end

	-- button
	QiankunBagSP_UpdateButtonReq();
	-- 打开UI

	--左侧按钮选择状态
	QiankunBagSP_Button1:SetCheck(0)
	QiankunBagSP_Button2:SetCheck(0)
	QiankunBagSP_Button3:SetCheck(1)
	QiankunBagSP_Button5:SetCheck(0)
	QiankunBagSP_Button6:SetCheck(0)


	--红点显示
	QiankunBagSP_Refresh_ButtonTips()

	this : Show();

end


--**********************************
-- 更新TextInfo
--**********************************
function QiankunBagSP_UpdateTextInfo()

	local nLevel = Player : GetLevel();

	for i = 1, table.getn( QiankunBagSPBtnState ) do
		if ( nLevel < QiankunBagSPLevel[ i ] ) then
			QiankunBagSP_Info[ i ] : SetText( QiankunBagSPText1Info[ i ] );
		else
			QiankunBagSP_Info[ i ] : SetText( QiankunBagSPText2Info[ i ] );
		end
	end

end


--**********************************
-- 更新icon
--**********************************
function QiankunBagSP_UpdateIcon()

	-- 刷新Item
	DataPool : Lua_UpdateQiankunBagItem();

	-- 玩家未领取的奖励
	local nBegin = 1;
	local nNext = table.getn( QiankunBagSPBtnState );
	-- for i = 1, table.getn( QiankunBagSPBtnState ) do
		-- if ( QiankunBagSPBtnState[ i ] == 0 ) then
			-- nBegin = i
			-- nNext = nBegin + 1;
			-- if ( nNext >= table.getn( QiankunBagSPBtnState ) ) then
				-- nNext = table.getn( QiankunBagSPBtnState );
			-- end
			-- break
		-- end
	-- end

	-- 无效值
	if ( nBegin == -1 or nNext == -1 ) then
		this:Hide();
		return
	end

	-- 修改FrameUI的高度
--	if ( nBegin == table.getn( QiankunBagSPBtnState ) and nNext == table.getn( QiankunBagSPBtnState ) ) then
--		QiankunBagSP_Frame : SetProperty("UnifiedSize", "{{0.000000,560.000000},{0.000000,205.000000}");
--		if SystemSetup:IsClassic() == 0 then
--			QiankunBagSP_Frame : SetProperty("UnifiedSize", "{{0.000000,580.000000},{0.000000,225.000000}");
--		end
--	else
--		QiankunBagSP_Frame : SetProperty("UnifiedSize", "{{0.000000,560.000000},{0.000000,420.000000}");
--		if SystemSetup:IsClassic() == 0 then
--			QiankunBagSP_Frame : SetProperty("UnifiedSize", "{{0.000000,580.000000},{0.000000,420.000000}");
--		end
--	end

	-- 隐藏Frame
	for i = 1, table.getn( QiankunBagSP_FrameInfo ) do
		QiankunBagSP_FrameInfo[ i ] : Hide();
	end

	-- Frame
	for row = 1, nNext - nBegin + 1 do
		QiankunBagSP_FrameInfo[ row ] : Show();
		-- Icon
		for col = 1, table.getn( QiankunBagSPIcon[ row ] ) do
			-- 初始化
			QiankunBagSPIcon[ row	][ col ] : SetActionItem( -1 );
			QiankunBagSPIcon[ row ][ col ] : Hide();

			-- 设置
			local theAction = EnumAction( ( row + nBegin - 2 ) * table.getn( QiankunBagSPIcon[ row ] ) + ( col - 1 ), "qiankundai_item" );
			if ( theAction : GetID() ~= 0 ) then
				QiankunBagSPIcon[ row ][ col ] : SetActionItem( theAction : GetID() );
				QiankunBagSPIcon[ row ][ col ] : Show();
			end
		end
	end

end


--**********************************
-- 请求更新Btn状态
--**********************************
function QiankunBagSP_UpdateButtonReq()

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateBtnState" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888907 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()

end


--**********************************
-- 更新Btn状态
--**********************************
function QiankunBagSP_UpdateButtonAck()

	-- 等级
	local nLevel = Player : GetLevel();

	-- 玩家未领取的奖励
	for i = 1, table.getn( QiankunBagSPBtnState ) do
		if ( QiankunBagSPBtnState[ i ] == 0 ) then
			if ( nLevel >= QiankunBagSPLevel[ i ] ) then
				QiankunBagSPButton[i].button : SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover");
				QiankunBagSPButton[i].button : Enable();
				QiankunBagSPButton[i].mask1 : Hide();
				QiankunBagSPButton[i].mask2 : Hide();
				QiankunBagSPButton[i].mask3 : Hide();
				QiankunBagSPButton[i].tips : Hide()
			else
				QiankunBagSPButton[i].button : SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable");
				QiankunBagSPButton[i].button : Disable();
				QiankunBagSPButton[i].mask1 : Show();
				QiankunBagSPButton[i].mask2 : Show();
				QiankunBagSPButton[i].mask3 : Show();
				QiankunBagSPButton[i].tips : Show()
			end
		else
			QiankunBagSPButton[i].button : SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_Disable");
			QiankunBagSPButton[i].button : Disable();
			QiankunBagSPButton[i].mask1 : Hide();
			QiankunBagSPButton[i].mask2 : Hide();
			QiankunBagSPButton[i].mask3 : Hide();
			QiankunBagSPButton[i].tips : Show()
		end
	end

end



--**********************************
-- 按钮
--**********************************
function QiankunBagSP_Clicked( nIndex )

	-- 玩家未领取的奖励
	-- local nBegin = -1;
	-- for i = 1, table.getn( QiankunBagSPBtnState ) do
		-- if ( QiankunBagSPBtnState[ i ] == 0 ) then
			-- nBegin = i
			-- break
		-- end
	-- end

	-- -- 无效值
	-- if ( nBegin == -1 ) then
		-- this:Hide();
		-- return
	-- end

	if nIndex > table.getn( QiankunBagSPBtnState ) then
		return
	end

	if ( QiankunBagSPBtnState[ nIndex ] == 1 ) then
		return
	end

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetQianKunDaiPrize" ); 	-- 脚本号
		Set_XSCRIPT_ScriptID( 888907 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( nIndex ) );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()

end


--**********************************
-- 关闭UI
--**********************************
function QiankunBagSP_OnHiden()
end



function QiankunBagSP_Button1_Click()

	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_9}")
		return
	end
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name("OpenWindowRequest")
--		Set_XSCRIPT_ScriptID(891106)
--		Set_XSCRIPT_ParamCount(0)
--	Send_XSCRIPT()
	OpenMonthlySignSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", QiankunBagSP_Frame:GetProperty("UnifiedPosition"), 1)
--	this:Hide()
end

function QiankunBagSP_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end

	OpenStrongRoadDiaoWenSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", QiankunBagSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function QiankunBagSP_Button3_Click()

end

function QiankunBagSP_Button4_Click()

end

function QiankunBagSP_Button5_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end

	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OpenDailyFuBen")
	--	Set_XSCRIPT_ScriptID(892428)
	--	Set_XSCRIPT_Parameter(0,1);
	--	Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT()
	
	OpenZhaoHui(1)

	Variable:SetVariable("SPSelfFuliUIPos", QiankunBagSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function QiankunBagSP_Button6_Click()
end

function QiankunBagSP_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end 
	Variable:SetVariable("SPSelfFuliUIPos", QiankunBagSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function QiankunBagSP_Button8_Click()
	OpenHuiGuiSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", QiankunBagSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function QiankunBagSP_Refresh_ButtonTips()

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		QiankunBagSP_Button7tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		QiankunBagSP_Button7tips : Hide()
	end

	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		QiankunBagSP_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		QiankunBagSP_Button8tips : Hide()
	end
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		QiankunBagSP_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		QiankunBagSP_Button8 : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		QiankunBagSP_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		QiankunBagSP_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		QiankunBagSP_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		QiankunBagSP_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		QiankunBagSP_Button3tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		QiankunBagSP_Button3tips : Hide()
	end


	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		QiankunBagSP_Button5tips : Show()
	else
		QiankunBagSP_Button5tips : Hide()
	end

	QiankunBagSP_Button6tips : Hide()
end

function QiankunBagSP_On_ResetPos()
	QiankunBagSP_Frame:SetProperty("UnifiedPosition", g_QiankunBagSP_Frame_UnifiedPosition)
end

function QiankunBagSP_On_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SPSelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
		QiankunBagSP_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end
