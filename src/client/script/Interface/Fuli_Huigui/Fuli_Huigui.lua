local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},
											[6] = {x =0, y = 0, tipx =0, tipy =0},
											[7] = {x =0, y = 0, tipx =0, tipy =0},
										}

local Fuli_Huigui_Action = {};
local Fuli_Huigui_TEXTS = {};
local Fuli_Huigui_TEXTS_TIPS = {};
local Fuli_Huigui_BUTTONS = {};
local Fuli_Huigui_YuanBao_Array = {};
local Fuli_Huigui_Num1_Array = {20,2,50,40,5,10,2};
local Fuli_Huigui_Num2_Array = {30,3,75,60,8,15,3};
local Fuli_Huigui_Name_Array = {"金蚕丝","3级秘银","精金石","豪侠勋章","真元精珀","至尊强化精华","3级棉布"};
local CreateDate = 904691712			-- 2013年08月22日08:00:00
local nCharCreateDate = -1;
local g_bIsNewServerGiftsForLevelUpValid = 0
local g_bIsNewServerGiftsForLevelUpValid_2023 = 0
local g_Fuli_Huigui_YuanBao1_Array = {1050,2700,1500,2400,2080,3000,2700};		--购买总价值
local g_Fuli_Huigui_YuanBao2_Array = {175,450,250,400,390,500,450};				--购买价格
local g_Fuli_Huigui_YuanBao3_Array = {700,1800,1000,1600,1300,2000,1800};		--免费的价值

local g_Fuli_Huigui_YuanBao1 = 1000;
local g_Fuli_Huigui_YuanBao2 = 1200;
local g_Fuli_Huigui_YuanBao3 = 1500;
local g_Fuli_Huigui_HuiguiStatus = {}			-- 7日领奖状态

local g_Fuli_Huigui_DiffDay = 0;
local g_Fuli_Huigui_DiffDay1 = 0;

function Fuli_Huigui_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("OPEN_HUIGUI")
	this:RegisterEvent("COMMON_CONFIRM_RET")

	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
end

function Fuli_Huigui_OnEvent(event)
	--Fuli_Huigui_Button5tips : Hide()
	if event == "UI_COMMAND" and tonumber( arg0 ) == 201707051 then
		if (0 == Get_XParam_INT(0)) then		-- 点击按钮返回状态
			Fuli_Huigui_UpdateInfo(Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4))
		elseif(1 == Get_XParam_INT(0)) then		-- 进入界面
			if(tonumber(arg0) == 0) then
				Fuli_Huigui_ResetPos()
			else
				Fuli_Huigui_SetLastPos()
			end
			Fuli_Huigui_UpdateButtonStatus()
			Fuli_Huigui_OnShown()
		elseif(2 == Get_XParam_INT(0)) then		-- 是否显示<归来好礼>按钮
			DataPool:Lua_SetUpdateTipsFlag(2,1)
			DataPool:Lua_SetUpdateTipsFlag(1,1)
--PushDebugMessage("是否显示<归来好礼>按钮")
		elseif(3 == Get_XParam_INT(0)) then		-- 更新小红点,显示提示
			DataPool:Lua_SetUpdateTipsFlag(1,1)
--PushDebugMessage("更新小红点,显示提示")
		end
	elseif( event == "ADJEST_UI_POS" ) then
		Fuli_Huigui_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Fuli_Huigui_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif event == "OPEN_HUIGUI" then
		-- PushDebugMessage("Fuli_Huigui_OnEvent.....OPEN_HUIGUI")
		--领取奖品请求
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("UpdateToClient")
			Set_XSCRIPT_ScriptID(892460)
			Set_XSCRIPT_Parameter(0,0);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif event == "COMMON_CONFIRM_RET" then

		if not this:IsVisible() then
			return
		end


		if (2 == tonumber(arg0)) then
			--领取奖品请求
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "GetHuiLiuGift" )
				Set_XSCRIPT_ScriptID( 892460 )
				Set_XSCRIPT_Parameter(0,tonumber(arg1))
				Set_XSCRIPT_Parameter(1,g_Fuli_Huigui_DiffDay)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		end
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8889072 ) then
		nCharCreateDate = Get_XParam_INT( 8 );
		g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = 0
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 99847904 ) then
		nCharCreateDate = Get_XParam_INT( 0 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = Get_XParam_INT( 1 );
		g_bIsNewServerGiftsForLevelUpValid = 0
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		Fuli_Huigui_Refresh_ButtonTips()
	end
end

function Fuli_Huigui_OnLoad()

	--PushDebugMessage("Fuli_Huigui_OnLoad")

	Fuli_Huigui_Action[1] = Fuli_Huigui_Frame1_Icon
	Fuli_Huigui_Action[2] = Fuli_Huigui_Frame2_Icon1
	Fuli_Huigui_Action[3] = Fuli_Huigui_Frame2_Icon1
	Fuli_Huigui_Action[4] = Fuli_Huigui_Qitian_Frame_Icon

	Fuli_Huigui_BUTTONS[1] = Fuli_Huigui_Frame1_Button
	Fuli_Huigui_BUTTONS[2] = Fuli_Huigui_Frame2_Button
	Fuli_Huigui_BUTTONS[3] = Fuli_Huigui_Frame2_Button
	Fuli_Huigui_BUTTONS[4] = Fuli_Huigui_Qitian_Bk1_Button


	Fuli_Huigui_TEXTS[1] = Fuli_Huigui_Gift_1
	Fuli_Huigui_TEXTS[2] = Fuli_Huigui_Gift_2
	Fuli_Huigui_TEXTS[3] = Fuli_Huigui_Gift_3
	Fuli_Huigui_TEXTS[4] = Fuli_Huigui_Gift_4
	Fuli_Huigui_TEXTS[5] = Fuli_Huigui_Gift_5
	Fuli_Huigui_TEXTS[6] = Fuli_Huigui_Gift_6
	Fuli_Huigui_TEXTS[7] = Fuli_Huigui_Gift_7

	Fuli_Huigui_TEXTS_TIPS[1] = Fuli_Huigui_Gift1tips
	Fuli_Huigui_TEXTS_TIPS[2] = Fuli_Huigui_Gift2tips
	Fuli_Huigui_TEXTS_TIPS[3] = Fuli_Huigui_Gift3tips
	Fuli_Huigui_TEXTS_TIPS[4] = Fuli_Huigui_Gift4tips
	Fuli_Huigui_TEXTS_TIPS[5] = Fuli_Huigui_Gift5tips
	Fuli_Huigui_TEXTS_TIPS[6] = Fuli_Huigui_Gift6tips
	Fuli_Huigui_TEXTS_TIPS[7] = Fuli_Huigui_Gift7tips

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Fuli_Huigui_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Fuli_Huigui_Frame:GetProperty("UnifiedYPosition");

	g_ButtonPos[1].x	= Fuli_Huigui_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= Fuli_Huigui_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= Fuli_Huigui_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= Fuli_Huigui_Button3tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[2].x	= Fuli_Huigui_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= Fuli_Huigui_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= Fuli_Huigui_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= Fuli_Huigui_Button5tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[3].x	= Fuli_Huigui_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= Fuli_Huigui_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= Fuli_Huigui_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= Fuli_Huigui_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= Fuli_Huigui_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= Fuli_Huigui_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= Fuli_Huigui_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= Fuli_Huigui_Button8tips:GetProperty("UnifiedYPosition");
	
	
	g_ButtonPos[5].x	= Fuli_Huigui_Button9:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= Fuli_Huigui_Button9:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= Fuli_Huigui_Button9tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= Fuli_Huigui_Button9tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[6].x	= Fuli_Huigui_Button10:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].y	= Fuli_Huigui_Button10:GetProperty("UnifiedYPosition");
	g_ButtonPos[6].tipx	= Fuli_Huigui_Button10tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].tipy	= Fuli_Huigui_Button10tips:GetProperty("UnifiedYPosition");
	

end

-- 回归按钮和文字状态同步
function Fuli_Huigui_UpdateButtonStatus()
	--PushDebugMessage("==:"..Get_XParam_INT(1).."==="..Get_XParam_INT(2).."==="..Get_XParam_INT(3).."==="..Get_XParam_INT(4).."==="..Get_XParam_INT(5).."==="..Get_XParam_INT(6).."==="..Get_XParam_INT(7).."==="..Get_XParam_INT(8).."==="..Get_XParam_INT(9).."==="..Get_XParam_INT(10).."==="..Get_XParam_INT(11))

	-- 7日领奖状态
	-- local nHuiguiStatus = {}
	-- 最终大奖
	local nHuiguiFinishStatus = {}

	local nStr = "";
	local nShowTips = 0;
	-- 8天的状态
	for i = 1, 8 do
		g_Fuli_Huigui_HuiguiStatus[i] = Get_XParam_INT(i)
		nStr = nStr..g_Fuli_Huigui_HuiguiStatus[i].."==";
		if (1 == g_Fuli_Huigui_HuiguiStatus[i]) then
			nShowTips = 1;
		end
	end

	--显示小红点
	if nShowTips == 1 then
		DataPool:Lua_SetUpdateTipsFlag(1,1)
	else
		DataPool:Lua_SetUpdateTipsFlag(1,0)
	end

	-- 完成指定副本次数
	local nCount = Get_XParam_INT(9);
	local nHuiguiGuildCity =  Get_XParam_INT(10);
	local nHuiGuiFirstTime = Get_XParam_INT(11);
	-- 回流第一次登录时间
	local diffday = Get_XParam_INT(12);
--PushDebugMessage("nHuiguiStatus:"..nStr..",nCount:"..nCount..",nHuiguiGuildCity:"..nHuiguiGuildCity..",nHuiGuiFirstTime:"..nHuiGuiFirstTime..",diffday:"..diffday)

	--if (0 == tonumber(nHuiguiStatus[i])) then
	--	Fuli_Huigui_BUTTONS[i]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_WeiDaCheng")
	--	Fuli_Huigui_BUTTONS[i]:Disable()
	--elseif (1 == tonumber(nHuiguiStatus[i])) then
	--	Fuli_Huigui_BUTTONS[i]:SetProperty("PushedImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Pushed")
	--	Fuli_Huigui_BUTTONS[i]:SetProperty("NormalImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Normal")
	--	Fuli_Huigui_BUTTONS[i]:SetProperty("HoverImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Hover")
	--	Fuli_Huigui_BUTTONS[i]:SetProperty("DisabledImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Disable")
	--	Fuli_Huigui_BUTTONS[i]:Enable()
	--elseif (2 == tonumber(nHuiguiStatus[i])) then
	--	Fuli_Huigui_BUTTONS[i]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_Disable")
	--	Fuli_Huigui_BUTTONS[i]:Disable()
	--end

	-- 完成指定副本次数
	if (30 > nCount) then
		local str = ScriptGlobal_Format("#{HLZS_170705_07}", tostring(nCount))
		Fuli_Huigui_text2:SetText(str)
	else
		Fuli_Huigui_text2:SetText ("#{HLZS_170705_08}")
	end
	-- 帮会城市
	if (0 == nHuiguiGuildCity) then
		Fuli_Huigui_text1:SetText ("#{HLZS_170705_05}")
	else
		Fuli_Huigui_text1:SetText ("#{HLZS_170705_06}")
	end

	-- 7日归来好礼
	if (2 == g_Fuli_Huigui_HuiguiStatus[8]) then
		-- 已领取
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		Fuli_Huigui_Qitian_Bk1_Button:Disable()
	elseif (0 == nHuiguiGuildCity or 30 > nCount) then
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		Fuli_Huigui_Qitian_Bk1_Button:Disable()
	else
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		Fuli_Huigui_Qitian_Bk1_Button:Enable()
	end

	local nFuli_Huigui_Month1 = ""
	local nFuli_Huigui_Day1 = ""
	local nFuli_Huigui_Month7 = ""
	local nFuli_Huigui_Day7 = ""
	-- 回流第一次登录时间
	for i = 1, 7 do
		local nCuryear, nCurmonth, nCurday = ZhanTuanInterface:GetConvertUT(nHuiGuiFirstTime + ((i-1) * 86400));
		Fuli_Huigui_TEXTS[i] : SetText(nCurmonth.."月"..nCurday.."日");
		if (1 == i) then			-- 第一天
			nFuli_Huigui_Month1 = tostring(nCurmonth)
			nFuli_Huigui_Day1 = tostring(nCurday)
		elseif (7 == i) then		-- 第七天
			nFuli_Huigui_Month7 = tostring(nCurmonth)
			nFuli_Huigui_Day7 = tostring(nCurday)
		end

		if(1 == g_Fuli_Huigui_HuiguiStatus[i]) then
			Fuli_Huigui_TEXTS_TIPS[i]:Show();
		else
			Fuli_Huigui_TEXTS_TIPS[i]:Hide();
		end
	end

	-- 文字说明
	local str22 = ScriptGlobal_Format("#{HLZS_170705_03}", tostring(nFuli_Huigui_Month1), tostring(nFuli_Huigui_Day1), tostring(nFuli_Huigui_Month7),
	tostring(nFuli_Huigui_Day7), tostring(nFuli_Huigui_Month7), tostring(nFuli_Huigui_Day7), tostring(nFuli_Huigui_Month7), tostring(nFuli_Huigui_Day7))
	Fuli_Huigui_RightFrame_Info:SetText(str22);

	g_Fuli_Huigui_DiffDay1 = tonumber(diffday+1);
	-- 切换物品显示
	Fuli_Huigui_SwitchItemShow(tonumber(diffday+1));
end

function Fuli_Huigui_OnShown()

	local nShaoDang = 2
	local nOneDay = 3
	local nHuiGui = 4
	local nSuperSave		= 5
	local nZhanLing = 6

	-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1) then
		Fuli_Huigui_Button3 : Hide();

		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
		nHuiGui = nHuiGui-1
		nSuperSave =nSuperSave -1
		nZhanLing = nZhanLing -1
	--	return
	else
		Fuli_Huigui_Button3 : Show();

	end
	
	Fuli_Huigui_Button5:Show()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		Fuli_Huigui_Button5:Hide()
		nShaoDang = -1
		nOneDay = nOneDay-1
		nHuiGui = nHuiGui-1
		nSuperSave =nSuperSave -1
		nZhanLing = nZhanLing -1
	end
	
	nOneDay = -1
	if nOneDay == -1  then
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
		Fuli_Huigui_Button7:Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_Huigui_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_Huigui_Button8 : Hide()
		nHuiGui   = - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
	end

	if DataPool:Lua_GetUpdateTipsFlag( 3 ) == 1 then
		Fuli_Huigui_Button9 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 3 ) == 0 then
		Fuli_Huigui_Button9 : Hide()
		nSuperSave =-1; 
		nZhanLing = nZhanLing -1

	end

	Fuli_Huigui_Button10:Show()
		if ( nLevel < 30 ) then
			Fuli_Huigui_Button10:Hide()
			nZhanLing = nZhanLing -1
		end


	if nShaoDang ~= -1 then
		Fuli_Huigui_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
		Fuli_Huigui_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
		Fuli_Huigui_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
		Fuli_Huigui_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);

	end

	if nOneDay ~= -1 then
		Fuli_Huigui_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		Fuli_Huigui_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		Fuli_Huigui_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		Fuli_Huigui_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);
	end

	if nHuiGui ~= -1 then
		Fuli_Huigui_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].x);
		Fuli_Huigui_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].y);
		Fuli_Huigui_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].tipx);
		Fuli_Huigui_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].tipy);
	end
	 
	
	if nSuperSave ~= -1 then
		Fuli_Huigui_Button9:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].x);
		Fuli_Huigui_Button9:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].y);
		Fuli_Huigui_Button9tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].tipx);
		Fuli_Huigui_Button9tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].tipy);
	end
	
	if nZhanLing ~= -1 then
		Fuli_Huigui_Button10:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].x);
		Fuli_Huigui_Button10:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].y);
		Fuli_Huigui_Button10tips:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].tipx);
		Fuli_Huigui_Button10tips:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].tipy);
	end

	--更新小红点
	-- if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
	-- 	DataPool:Lua_SetUpdateTipsFlag(1,1)
	-- end

	-- 已领取
	-- Fuli_Huigui_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_Disable")
	-- Fuli_Huigui_Qitian_Bk1_Button:Disable()
	-- Fuli_Huigui_Day1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_WeiDaCheng")
	-- Fuli_Huigui_Day1_Button:Disable()

	Fuli_Huigui_Refresh_ButtonTips()

	-- for i = 0, 2 do
	-- 	local theAction = EnumAction(i, "huigui_item");
	-- 	if theAction:GetID() ~= 0 then
	-- 		Fuli_Huigui_Action[i+1]:SetActionItem(theAction:GetID());
	-- 		-- if ( i >= nIndex) then
	-- 		-- 	Fuli_Huigui_BUTTONS[i+1] : Enable()
	-- 		-- else
	-- 		-- 	Fuli_Huigui_BUTTONS[i+1] : Disable()
	-- 		-- end
	-- 	end
	-- end

	--
	Fuli_Huigui_SetCheck()

	-- DataPool:Lua_UpdateHuiGuiItem()

	this:Show();
end


--================================================
-- 切换物品显示
--================================================
function Fuli_Huigui_SwitchItemShow(diffday)

	g_Fuli_Huigui_DiffDay = diffday;
	if(8 > diffday and 0 < diffday) then
		-- 显示当前天的tag
		for i = 1, 7 do
			if (i == diffday) then
				Fuli_Huigui_TEXTS[i] : SetProperty("Selected", "True")
			else
				Fuli_Huigui_TEXTS[i] : SetProperty("Selected", "False")
			end
		end

		-- 元宝显示
		local str = ScriptGlobal_Format("#{HLZS_170705_38}", tostring(g_Fuli_Huigui_YuanBao2_Array[diffday]))
		local str1 = ScriptGlobal_Format("#{HLZS_170705_48}", tostring(g_Fuli_Huigui_YuanBao1_Array[diffday]))
		local str2 = ScriptGlobal_Format("#{HLZS_170705_48}", tostring(g_Fuli_Huigui_YuanBao3_Array[diffday]))
		Fuli_Huigui_Frame2_Yuanbao:SetText(str);
		Fuli_Huigui_Frame2_Yuanbao1:SetText(str1);
		Fuli_Huigui_Frame1_Yuanbao1:SetText(str2);

		-- 物品数量
		Fuli_Huigui_Frame1_Num:SetText("#e000001#W"..tostring(Fuli_Huigui_Num1_Array[diffday]));
		--Fuli_Huigui_Frame2_Num:SetText(tostring(Fuli_Huigui_Num1_Array[diffday]));
		Fuli_Huigui_Frame2_Num1:SetText("#e000001#W"..tostring(Fuli_Huigui_Num2_Array[diffday]));
		Fuli_Huigui_Frame_Num:SetText(tostring(2));


		Fuli_Huigui_BUTTONS[1]:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		Fuli_Huigui_BUTTONS[1]:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		Fuli_Huigui_BUTTONS[1]:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		Fuli_Huigui_BUTTONS[1]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		Fuli_Huigui_BUTTONS[2]:SetProperty("set:ImageButtons image:ImageButtons_Buy_Pushed")
		Fuli_Huigui_BUTTONS[2]:SetProperty("NormalImage", "set:ImageButtons image:ImageButtons_Buy_Normal")
		Fuli_Huigui_BUTTONS[2]:SetProperty("HoverImage", "set:ImageButtons image:ImageButtons_Buy_Hover")
		Fuli_Huigui_BUTTONS[2]:SetProperty("DisabledImage", "set:ImageButtons image:ImageButtons_Buy_Gray")
		-- 重置按钮状态
		if (0 == tonumber(g_Fuli_Huigui_HuiguiStatus[diffday])) then
			-- Fuli_Huigui_BUTTONS[1]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_WeiDaCheng")
			-- Fuli_Huigui_BUTTONS[1]:Disable()
			--for i = 1, 2 do
				Fuli_Huigui_BUTTONS[1]:Disable()

				Fuli_Huigui_BUTTONS[2]:Disable()
				local str = ScriptGlobal_Format("#{HLZS_170705_17}", tostring(150))
				Fuli_Huigui_Day_Huoyue1 : SetText(str)
				--Fuli_Huigui_Day_Huoyue2 : SetText(str)
			--end
		elseif (1 == tonumber(g_Fuli_Huigui_HuiguiStatus[diffday])) then
			--for i = 1, 2 do
				Fuli_Huigui_BUTTONS[1]:Enable()

				Fuli_Huigui_BUTTONS[2]:Enable()
			--end
			local str = ScriptGlobal_Format("#{HLZS_170705_18}", tostring(150))
			Fuli_Huigui_Day_Huoyue1 : SetText(str)
			--Fuli_Huigui_Day_Huoyue2 : SetText(str)
		elseif (2 == tonumber(g_Fuli_Huigui_HuiguiStatus[diffday])) then
			--for i = 1, 2 do
				Fuli_Huigui_BUTTONS[1]:Disable()

				Fuli_Huigui_BUTTONS[2]:Disable()
				local str = ScriptGlobal_Format("#{HLZS_170705_18}", tostring(150))
				Fuli_Huigui_Day_Huoyue1 : SetText(str)
				--Fuli_Huigui_Day_Huoyue2 : SetText(str)
			--end
		end

		-- 判断是否是当天
		if(g_Fuli_Huigui_DiffDay1 == diffday) then
			local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
			local str = ScriptGlobal_Format("#{HLZS_170705_18}", tostring(150))
			if (nToadyActivePoint < 150) then
				str = ScriptGlobal_Format("#{HLZS_170705_51}", tostring(nToadyActivePoint))
			end

			Fuli_Huigui_Day_Huoyue1 : SetText(str)
		end
	end

	DataPool:Lua_UpdateHuiGuiItem()
	for i = 0, 1 do
		local theAction = EnumAction(tonumber(g_Fuli_Huigui_DiffDay-1), "huigui_item");
		--PushDebugMessage("==sss=="..theAction:GetID())
		if theAction:GetID() ~= 0 then
			Fuli_Huigui_Action[i+1]:SetActionItem(theAction:GetID());
			-- if ( i >= nIndex) then
			-- 	Fuli_Huigui_BUTTONS[i+1] : Enable()
			-- else
			-- 	Fuli_Huigui_BUTTONS[i+1] : Disable()
			-- end
		end
	end

	local theAction1 = EnumAction(7, "huigui_item");
	if theAction1:GetID() ~= 0 then
		Fuli_Huigui_Qitian_Frame_Icon:SetActionItem(theAction1:GetID());
	end
--PushDebugMessage("==g_Fuli_Huigui_DiffDay=="..g_Fuli_Huigui_DiffDay)
end

--================================================
-- 界面的默认相对位置
--================================================
function Fuli_Huigui_ResetPos()
	Fuli_Huigui_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Fuli_Huigui_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Fuli_Huigui_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
	    Fuli_Huigui_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end

function Fuli_Huigui_OnClosed()
	this:Hide();
end

function Fuli_Huigui_OnHiden()
	this:Hide();
end

function Fuli_Huigui_Button1_Click()

	OpenMonthlySign(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)
--	this:Hide()
end

function Fuli_Huigui_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end

	OpenStrongRoadDiaoWen(1)

	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)

end

function Fuli_Huigui_Button3_Click()
	OpenQianKunDai(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)
--	this:Hide()
end

function Fuli_Huigui_Button4_Click()

end

function Fuli_Huigui_Button5_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end

	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OpenDailyFuBen")
	--	Set_XSCRIPT_ScriptID(892428)
	--	Set_XSCRIPT_Parameter(0,0);
	--	Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT() 
	OpenZhaoHui(1)
end


function Fuli_Huigui_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end
	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_Huigui_Button9_Click()
	OpenSuperSaveUp(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_Huigui_Button10_Click()
	local nLevel = Player:GetLevel();
	if( nLevel < 30 ) then
		PushDebugMessage("#{TLZL_190802_03}")	
		return
	end
	OpenZhanLing(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)
end
-- 更新小红点
function Fuli_Huigui_Refresh_ButtonTips()

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_Huigui_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_Huigui_Button8tips : Hide()
	end

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_Huigui_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_Huigui_Button7tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 41 )== 1 then
		Fuli_Huigui_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_Huigui_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_Huigui_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_Huigui_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if nCharCreateDate ~= -1 and ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1)then
			DataPool:Lua_SetRedPointInUIShow(39, 0)
			Fuli_Huigui_Button3tips : Hide()
		else
			Fuli_Huigui_Button3tips : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_Huigui_Button3tips : Hide()
	end





	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		Fuli_Huigui_Button5tips : Show()
	else
		Fuli_Huigui_Button5tips : Hide()
	end

	
	-- 福利 累充 
	if DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 then
		Fuli_Huigui_Button9tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 4 ) == 0 then
		Fuli_Huigui_Button9tips : Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 then
		Fuli_Huigui_Button10tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 5 ) == 0 then
		Fuli_Huigui_Button10tips : Hide()
	end
end

function Fuli_Huigui_OnClosed()
    this:Hide()
    return
end

function Fuli_Huigui_UpdateInfo(param,diffday,nCount,nHuiguiGuild)
	--PushDebugMessage("Fuli_Huigui_UpdateInfo:"..param.."=="..diffday.."=="..nCount.."=="..nHuiguiGuild)
	g_Fuli_Huigui_HuiguiStatus[diffday] = 2;
	if (3 ~= param) then	-- 一，二按钮

		Fuli_Huigui_BUTTONS[1]:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		Fuli_Huigui_BUTTONS[1]:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		Fuli_Huigui_BUTTONS[1]:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		Fuli_Huigui_BUTTONS[1]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		Fuli_Huigui_BUTTONS[2]:SetProperty("set:ImageButtons image:ImageButtons_Buy_Pushed")
		Fuli_Huigui_BUTTONS[2]:SetProperty("NormalImage", "set:ImageButtons image:ImageButtons_Buy_Normal")
		Fuli_Huigui_BUTTONS[2]:SetProperty("HoverImage", "set:ImageButtons image:ImageButtons_Buy_Hover")
		Fuli_Huigui_BUTTONS[2]:SetProperty("DisabledImage", "set:ImageButtons image:ImageButtons_Buy_Gray")
		Fuli_Huigui_BUTTONS[1]:Disable()
		Fuli_Huigui_BUTTONS[2]:Disable()
		--for i = 1, 2 do
		--	Fuli_Huigui_BUTTONS[i]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_Disable")
		--	Fuli_Huigui_BUTTONS[i]:Disable()
		--end
	else					-- 7日归来好礼
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		Fuli_Huigui_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		Fuli_Huigui_Qitian_Bk1_Button:Disable()
	end
	local nShowTips = 0;
	for i = 1, 7 do
		if (1 == g_Fuli_Huigui_HuiguiStatus[i]) then
			nShowTips = 1;
			Fuli_Huigui_TEXTS_TIPS[i]:Show();
		else
			Fuli_Huigui_TEXTS_TIPS[i]:Hide();
		end
	end

	-- 完成30次指定副本，刷新小红点
	if (2 ~= g_Fuli_Huigui_HuiguiStatus[8] and 30 <= nCount and 1 == nHuiguiGuild) then
		nShowTips = 1;
	end

	--是否显示小红点
	if nShowTips == 1 then
		DataPool:Lua_SetUpdateTipsFlag(1,1)
		Fuli_Huigui_Button8tips : Show()
	else
		DataPool:Lua_SetUpdateTipsFlag(1,0)
		Fuli_Huigui_Button8tips : Hide()
	end
	PushEvent("BIN_PLAYER_UPDATE_UI", 1)
end

--领取
function Fuli_Huigui_Clicked( param )

	--PushDebugMessage("Fuli_Huigui_Clicked:"..g_Fuli_Huigui_DiffDay)
	local str = "";
	if (1 == param) then			-- 免费
		local num = Fuli_Huigui_Num1_Array[g_Fuli_Huigui_DiffDay];
		local name = Fuli_Huigui_Name_Array[g_Fuli_Huigui_DiffDay];
		local yuanbao = g_Fuli_Huigui_YuanBao2_Array[g_Fuli_Huigui_DiffDay];
		local num_new = tonumber(Fuli_Huigui_Num2_Array[g_Fuli_Huigui_DiffDay]);
		str = ScriptGlobal_Format("#{HLZS_170705_40}", tostring(num), tostring(name), tostring(yuanbao), tostring(num_new), tostring(name) )
	elseif (2 == param) then		-- 元宝购买
		local num = Fuli_Huigui_Num1_Array[g_Fuli_Huigui_DiffDay];
		local name = Fuli_Huigui_Name_Array[g_Fuli_Huigui_DiffDay];
		local yuanbao = g_Fuli_Huigui_YuanBao2_Array[g_Fuli_Huigui_DiffDay];
		local num_new = tonumber(Fuli_Huigui_Num2_Array[g_Fuli_Huigui_DiffDay]);
		str = ScriptGlobal_Format("#{HLZS_170705_43}", tostring(yuanbao), tostring(num_new), tostring(name), tostring(yuanbao), tostring(num_new), tostring(name) )
	elseif(3 == param) then			-- 7天领取大礼
		--领取奖品请求
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetHuiLiuGift" )
			Set_XSCRIPT_ScriptID( 892460 )
			Set_XSCRIPT_Parameter(0,param)
			Set_XSCRIPT_Parameter(1,8)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		return 0
	end
	PushEvent("COMMON_CONFIRM",tostring(str), tonumber(2), tonumber(param))

end

-- 每月签到
function Fuli_Huigui_Button1_Clicked()
	OpenMonthlySign(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)
end

--
function Fuli_Huigui_Button2_Clicked()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end

	OpenStrongRoadDiaoWen(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)
end

--
function Fuli_Huigui_Button3_Clicked()
	OpenQianKunDai(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_Huigui_SetCheck()
		Fuli_Huigui_Button1:SetCheck(0)
		Fuli_Huigui_Button2:SetCheck(0)
		Fuli_Huigui_Button3:SetCheck(0)
		Fuli_Huigui_Button5:SetCheck(0)
		Fuli_Huigui_Button7:SetCheck(0)
		Fuli_Huigui_Button8:SetCheck(1)
end

--
function Fuli_Huigui_Button4_Clicked()

end

--
function Fuli_Huigui_Button5_Clicked()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenDailyFuBen")
		Set_XSCRIPT_ScriptID(892428)
		Set_XSCRIPT_Parameter(0,0);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	Variable:SetVariable("SelfFuliUIPos", Fuli_Huigui_Frame:GetProperty("UnifiedPosition"), 1)
end

