-- 快捷功能入口 乾坤袋
-- PushDebugMessage
-- this:Show();
-- this:Hide();

local QiankunBagButton = {}
local QiankunBagIcon = {}	-- 乾坤袋icon
local QiankunBag_FrameInfo = {}	-- 乾坤袋Frame
local QiankunBag_Info = {}	-- 乾坤袋Info
local QiankunBagLevel = {	-- 领奖等级限制
	[1] = 10,
	[2] = 20,
	[3] = 30,
	[4] = 35,
	[5] = 40,
	[6] = 45,
	[7] = 50,
	[8] = 55,
}
local QiankunBagBtnState = {		-- 乾坤袋按钮状态
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}

local QianKunBagText1Info = {		-- TextInfo
	[1] = "#{SJJLYH_160315_01}",	-- #cfff263 10级奖励
	[2] = "#{SJJLYH_160315_02}",	-- #cfff263 20级奖励
	[3] = "#{SJJLYH_160315_03}",	-- #cfff263 30级奖励
	[4] = "#{SJJLYH_160315_04}",	-- #cfff263 35级奖励
	[5] = "#{SJJLYH_160315_05}",	-- #cfff263 40级奖励
	[6] = "#{SJJLYH_160315_06}",	-- #cfff263 45级奖励
	[7] = "#{SJJLYH_160315_07}",	-- #cfff263 50级奖励
	[8] = "#{SJJLYH_160315_08}",	-- #cfff263 55级奖励
}

local QianKunBagText2Info = {		-- TextInfo
	[1] = "#{SJJLYH_160315_09}",	-- #cfff263 10级奖励
	[2] = "#{SJJLYH_160315_10}",	-- #cfff263 20级奖励
	[3] = "#{SJJLYH_160315_11}",	-- #cfff263 30级奖励
	[4] = "#{SJJLYH_160315_12}",	-- #cfff263 35级奖励
	[5] = "#{SJJLYH_160315_13}",	-- #cfff263 40级奖励
	[6] = "#{SJJLYH_160315_14}",	-- #cfff263 45级奖励
	[7] = "#{SJJLYH_160315_15}",	-- #cfff263 50级奖励
	[8] = "#{SJJLYH_160315_16}",	-- #cfff263 55级奖励
}

--**********************************
-- PRELOAD
--**********************************
function QiankunBag_PreLoad()

	this:RegisterEvent("OPEN_QIANKUNDAI");		-- 打开UI
	this:RegisterEvent("UNIT_LEVEL");			-- 升级
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	-- 离开场景
	this:RegisterEvent("UI_COMMAND")			-- 界面

end


--**********************************
-- ONLOAD
--**********************************
function QiankunBag_OnLoad()

	-- icon
	QiankunBagIcon[1] = {QiankunBag_Frame2_Icon1, QiankunBag_Frame2_Icon2, QiankunBag_Frame2_Icon3}
	QiankunBagIcon[2] = {QiankunBag_Frame3_Icon1, QiankunBag_Frame3_Icon2, QiankunBag_Frame3_Icon3}
	QiankunBagIcon[3] = {QiankunBag_Frame4_Icon1, QiankunBag_Frame4_Icon2, QiankunBag_Frame4_Icon3}
	QiankunBagIcon[4] = {QiankunBag_Frame5_Icon1, QiankunBag_Frame5_Icon2, QiankunBag_Frame5_Icon3}
	QiankunBagIcon[5] = {QiankunBag_Frame6_Icon1, QiankunBag_Frame6_Icon2, QiankunBag_Frame6_Icon3}
	QiankunBagIcon[6] = {QiankunBag_Frame7_Icon1, QiankunBag_Frame7_Icon2, QiankunBag_Frame7_Icon3}
	QiankunBagIcon[7] = {QiankunBag_Frame8_Icon1, QiankunBag_Frame8_Icon2, QiankunBag_Frame8_Icon3}
	QiankunBagIcon[8] = {QiankunBag_Frame9_Icon1, QiankunBag_Frame9_Icon2, QiankunBag_Frame9_Icon3}	

	-- Frame
	QiankunBag_FrameInfo[1] = QiankunBag_Frame2_Info
	QiankunBag_FrameInfo[2] = QiankunBag_Frame3_Info
	QiankunBag_FrameInfo[3] = QiankunBag_Frame4_Info
	QiankunBag_FrameInfo[4] = QiankunBag_Frame5_Info
	QiankunBag_FrameInfo[5] = QiankunBag_Frame6_Info
	QiankunBag_FrameInfo[6] = QiankunBag_Frame7_Info
	QiankunBag_FrameInfo[7] = QiankunBag_Frame8_Info
	QiankunBag_FrameInfo[8] = QiankunBag_Frame9_Info
	

	-- Text
	QiankunBag_Info[1] = QiankunBag_Frame2_Info1
	QiankunBag_Info[2] = QiankunBag_Frame3_Info1
	QiankunBag_Info[3] = QiankunBag_Frame4_Info1
	QiankunBag_Info[4] = QiankunBag_Frame5_Info1
	QiankunBag_Info[5] = QiankunBag_Frame6_Info1
	QiankunBag_Info[6] = QiankunBag_Frame7_Info1
	QiankunBag_Info[7] = QiankunBag_Frame8_Info1
	QiankunBag_Info[8] = QiankunBag_Frame9_Info1	
	
	QiankunBagButton[1] = {button=QiankunBag_Frame2_Button,mask1=QiankunBag_Frame2_Mask1,mask2=QiankunBag_Frame2_Mask2,mask3=QiankunBag_Frame2_Mask3,tips=QiankunBag_Frame2_ButtonTips}
	QiankunBagButton[2] = {button=QiankunBag_Frame3_Button,mask1=QiankunBag_Frame3_Mask1,mask2=QiankunBag_Frame3_Mask2,mask3=QiankunBag_Frame3_Mask3,tips=QiankunBag_Frame3_ButtonTips}
	QiankunBagButton[3] = {button=QiankunBag_Frame4_Button,mask1=QiankunBag_Frame4_Mask1,mask2=QiankunBag_Frame4_Mask2,mask3=QiankunBag_Frame4_Mask3,tips=QiankunBag_Frame4_ButtonTips}
	QiankunBagButton[4] = {button=QiankunBag_Frame5_Button,mask1=QiankunBag_Frame5_Mask1,mask2=QiankunBag_Frame5_Mask2,mask3=QiankunBag_Frame5_Mask3,tips=QiankunBag_Frame5_ButtonTips}
	QiankunBagButton[5] = {button=QiankunBag_Frame6_Button,mask1=QiankunBag_Frame6_Mask1,mask2=QiankunBag_Frame6_Mask2,mask3=QiankunBag_Frame6_Mask3,tips=QiankunBag_Frame6_ButtonTips}
	QiankunBagButton[6] = {button=QiankunBag_Frame7_Button,mask1=QiankunBag_Frame7_Mask1,mask2=QiankunBag_Frame7_Mask2,mask3=QiankunBag_Frame7_Mask3,tips=QiankunBag_Frame7_ButtonTips}
	QiankunBagButton[7] = {button=QiankunBag_Frame8_Button,mask1=QiankunBag_Frame8_Mask1,mask2=QiankunBag_Frame8_Mask2,mask3=QiankunBag_Frame8_Mask3,tips=QiankunBag_Frame8_ButtonTips}
	QiankunBagButton[8] = {button=QiankunBag_Frame9_Button,mask1=QiankunBag_Frame9_Mask1,mask2=QiankunBag_Frame9_Mask2,mask3=QiankunBag_Frame9_Mask10,tips=QiankunBag_Frame9_ButtonTips}
	
	-- QiankunBagButton[1] = QiankunBag_Frame2_Button
	-- QiankunBagButton[2] = QiankunBag_Frame3_Button
	-- QiankunBagButton[3] = QiankunBag_Frame4_Button
	-- QiankunBagButton[4] = QiankunBag_Frame5_Button
	-- QiankunBagButton[5] = QiankunBag_Frame6_Button
	-- QiankunBagButton[6] = QiankunBag_Frame7_Button
	-- QiankunBagButton[7] = QiankunBag_Frame8_Button
	-- QiankunBagButton[8] = QiankunBag_Frame9_Button	

end


--**********************************
-- ONEvent
--**********************************
function QiankunBag_OnEvent( event )


	if ( event == "OPEN_QIANKUNDAI" ) then
		-- 关闭UI
		if ( IsWindowShow( "QiankunBag" ) == true ) then
			this : Hide();
			return
		end
		-- 更新数据
		QiankunBag_UpdateData();
	elseif ( event == "UNIT_LEVEL" ) then
		-- UI状态
		if ( IsWindowShow( "QiankunBag" ) == false ) then
			return
		end
		-- 更新数据
		QiankunBag_UpdateData();
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 8889071 ) then
		-- 取参数
		QiankunBagBtnState[ 1 ] = Get_XParam_INT( 0 );
		QiankunBagBtnState[ 2 ] = Get_XParam_INT( 1 );
		QiankunBagBtnState[ 3 ] = Get_XParam_INT( 2 );
		QiankunBagBtnState[ 4 ] = Get_XParam_INT( 3 );
		QiankunBagBtnState[ 5 ] = Get_XParam_INT( 4 );
		QiankunBagBtnState[ 6 ] = Get_XParam_INT( 5 );
		QiankunBagBtnState[ 7 ] = Get_XParam_INT( 6 );
		QiankunBagBtnState[ 8 ] = Get_XParam_INT( 7 );
		-- 更新TextInfo
		QiankunBag_UpdateTextInfo();
		-- 更新Btn
		QiankunBag_UpdateButtonAck();
		-- icon
		QiankunBag_UpdateIcon();
	end

end


--**********************************
-- 更新Data
--**********************************
function QiankunBag_UpdateData()

	-- button
	QiankunBag_UpdateButtonReq();
	-- 打开UI
	this : Show();

end


--**********************************
-- 更新TextInfo
--**********************************
function QiankunBag_UpdateTextInfo()

	local nLevel = Player : GetLevel();
	
	for i = 1, table.getn( QiankunBagBtnState ) do
		if ( nLevel < QiankunBagLevel[ i ] ) then
			QiankunBag_Info[ i ] : SetText( QianKunBagText1Info[ i ] );
		else
			QiankunBag_Info[ i ] : SetText( QianKunBagText2Info[ i ] );
		end
	end

end


--**********************************
-- 更新icon
--**********************************
function QiankunBag_UpdateIcon()

	-- 刷新Item
	DataPool : Lua_UpdateQiankunBagItem();

	-- 玩家未领取的奖励
	local nBegin = 1;
	local nNext = table.getn( QiankunBagBtnState );
	-- for i = 1, table.getn( QiankunBagBtnState ) do
		-- if ( QiankunBagBtnState[ i ] == 0 ) then
			-- nBegin = i
			-- nNext = nBegin + 1;
			-- if ( nNext >= table.getn( QiankunBagBtnState ) ) then
				-- nNext = table.getn( QiankunBagBtnState );
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
	if ( nBegin == table.getn( QiankunBagBtnState ) and nNext == table.getn( QiankunBagBtnState ) ) then
		QiankunBag_Frame : SetProperty("UnifiedSize", "{{0.000000,560.000000},{0.000000,205.000000}");
		if SystemSetup:IsClassic() == 0 then
			QiankunBag_Frame : SetProperty("UnifiedSize", "{{0.000000,580.000000},{0.000000,225.000000}");
		end
	else
		QiankunBag_Frame : SetProperty("UnifiedSize", "{{0.000000,560.000000},{0.000000,420.000000}");
		if SystemSetup:IsClassic() == 0 then
			QiankunBag_Frame : SetProperty("UnifiedSize", "{{0.000000,580.000000},{0.000000,420.000000}");
		end
	end
	
	-- 隐藏Frame
	for i = 1, table.getn( QiankunBag_FrameInfo ) do
		QiankunBag_FrameInfo[ i ] : Hide();
	end

	-- Frame
	for row = 1, nNext - nBegin + 1 do
		QiankunBag_FrameInfo[ row ] : Show();
		-- Icon
		for col = 1, table.getn( QiankunBagIcon[ row ] ) do
			-- 初始化
			QiankunBagIcon[ row	][ col ] : SetActionItem( -1 );
			QiankunBagIcon[ row ][ col ] : Hide();

			-- 设置
			local theAction = EnumAction( ( row + nBegin - 2 ) * table.getn( QiankunBagIcon[ row ] ) + ( col - 1 ), "qiankundai_item" );
			if ( theAction : GetID() ~= 0 ) then
				QiankunBagIcon[ row ][ col ] : SetActionItem( theAction : GetID() );
				QiankunBagIcon[ row ][ col ] : Show();
			end
		end
	end

end


--**********************************
-- 请求更新Btn状态
--**********************************
function QiankunBag_UpdateButtonReq()

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateBtnState" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888907 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 0 );						-- 参数一
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()

end


--**********************************
-- 更新Btn状态
--**********************************
function QiankunBag_UpdateButtonAck()

	-- 等级
	local nLevel = Player : GetLevel();

	-- 玩家未领取的奖励
	for i = 1, table.getn( QiankunBagBtnState ) do
		if ( QiankunBagBtnState[ i ] == 0 ) then
			if ( nLevel >= QiankunBagLevel[ i ] ) then
				QiankunBagButton[i].button : SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover");
				QiankunBagButton[i].button : Enable();
				QiankunBagButton[i].mask1 : Hide();
				QiankunBagButton[i].mask2 : Hide();
				QiankunBagButton[i].mask3 : Hide();
				QiankunBagButton[i].tips : Hide()
			else
				QiankunBagButton[i].button : SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable");
				QiankunBagButton[i].button : Disable();
				QiankunBagButton[i].mask1 : Show();
				QiankunBagButton[i].mask2 : Show();
				QiankunBagButton[i].mask3 : Show();	
				QiankunBagButton[i].tips : Show()
			end
		else
			QiankunBagButton[i].button : SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_Disable");
			QiankunBagButton[i].button : Disable();
			QiankunBagButton[i].mask1 : Hide();
			QiankunBagButton[i].mask2 : Hide();
			QiankunBagButton[i].mask3 : Hide();	
			QiankunBagButton[i].tips : Show()			
		end
	end

end



--**********************************
-- 按钮
--**********************************
function QiankunBag_Clicked( nIndex )

	-- 玩家未领取的奖励
	-- local nBegin = -1;
	-- for i = 1, table.getn( QiankunBagBtnState ) do
		-- if ( QiankunBagBtnState[ i ] == 0 ) then
			-- nBegin = i
			-- break
		-- end
	-- end

	-- -- 无效值
	-- if ( nBegin == -1 ) then
		-- this:Hide();
		-- return
	-- end
	
	if nIndex > table.getn( QiankunBagBtnState ) then
		return
	end
	
	if ( QiankunBagBtnState[ nIndex ] == 1 ) then
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
function QiankunBag_OnHiden()
end
