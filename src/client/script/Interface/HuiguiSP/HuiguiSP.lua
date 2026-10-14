local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},
										}

local HuiguiSP_Action = {};
local HuiguiSP_TEXTS = {};
local HuiguiSP_TEXTS_TIPS = {};
local HuiguiSP_BUTTONS = {};
local HuiguiSP_YuanBao_Array = {};
local HuiguiSP_Num1_Array = {20,2,50,40,5,10,2};
local HuiguiSP_Num2_Array = {30,3,75,60,8,15,3};
local HuiguiSP_Name_Array = {"金蚕丝","3级秘银","精金石","豪侠勋章","真元精珀","至尊强化精华","3级棉布"};
local CreateDate = 904691712			-- 2013年08月22日08:00:00
local nCharCreateDate = 0;
local g_bIsNewServerGiftsForLevelUpValid = 0
local g_HuiguiSP_YuanBao1_Array = {1050,2700,1500,2400,2080,3000,2700};		--购买总价值
local g_HuiguiSP_YuanBao2_Array = {175,450,250,400,390,500,450};				--购买价格
local g_HuiguiSP_YuanBao3_Array = {700,1800,1000,1600,1300,2000,1800};		--免费的价值

local g_HuiguiSP_YuanBao1 = 1000;
local g_HuiguiSP_YuanBao2 = 1200;
local g_HuiguiSP_YuanBao3 = 1500;
local g_HuiguiSP_HuiguiStatus = {}			-- 7日领奖状态

local g_HuiguiSP_DiffDay = 0;
local g_HuiguiSP_DiffDay1 = 0;

function HuiguiSP_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("OPEN_HUIGUI_SP")
	this:RegisterEvent("COMMON_CONFIRM_RET")

end

function HuiguiSP_OnEvent(event)
	--HuiguiSP_Button5tips : Hide()
	if event == "UI_COMMAND" and tonumber( arg0 ) == 201707052 then
		if (0 == Get_XParam_INT(0)) then		-- 点击按钮返回状态
			HuiguiSP_UpdateInfo(Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4))
		elseif(1 == Get_XParam_INT(0)) then		-- 进入界面
			if(tonumber(arg0) == 0) then
				HuiguiSP_ResetPos()
			else
				HuiguiSP_SetLastPos()
			end
			HuiguiSP_UpdateButtonStatus()
			HuiguiSP_OnShown()
		elseif(2 == Get_XParam_INT(0)) then		-- 是否显示<归来好礼>按钮
			DataPool:Lua_SetUpdateTipsFlag(2,1)
			DataPool:Lua_SetUpdateTipsFlag(1,1)
--PushDebugMessage("是否显示<归来好礼>按钮")
		elseif(3 == Get_XParam_INT(0)) then		-- 更新小红点,显示提示
			DataPool:Lua_SetUpdateTipsFlag(1,1)
--PushDebugMessage("更新小红点,显示提示")
		end
	elseif( event == "ADJEST_UI_POS" ) then
		HuiguiSP_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		HuiguiSP_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif event == "OPEN_HUIGUI_SP" then
		-- PushDebugMessage("HuiguiSP_OnEvent.....OPEN_HUIGUI")
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
				Set_XSCRIPT_Parameter(1,g_HuiguiSP_DiffDay)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
		end
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8889072 ) then
		nCharCreateDate = Get_XParam_INT( 8 );
		g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
	end
end

function HuiguiSP_OnLoad()

	--PushDebugMessage("HuiguiSP_OnLoad")

	HuiguiSP_Action[1] = HuiguiSP_Frame1_Icon
	HuiguiSP_Action[2] = HuiguiSP_Frame2_Icon1
	HuiguiSP_Action[3] = HuiguiSP_Frame2_Icon1
	HuiguiSP_Action[4] = HuiguiSP_Qitian_Frame_Icon

	HuiguiSP_BUTTONS[1] = HuiguiSP_Frame1_Button
	HuiguiSP_BUTTONS[2] = HuiguiSP_Frame2_Button
	HuiguiSP_BUTTONS[3] = HuiguiSP_Frame2_Button
	HuiguiSP_BUTTONS[4] = HuiguiSP_Qitian_Bk1_Button


	HuiguiSP_TEXTS[1] = HuiguiSP_Gift_1
	HuiguiSP_TEXTS[2] = HuiguiSP_Gift_2
	HuiguiSP_TEXTS[3] = HuiguiSP_Gift_3
	HuiguiSP_TEXTS[4] = HuiguiSP_Gift_4
	HuiguiSP_TEXTS[5] = HuiguiSP_Gift_5
	HuiguiSP_TEXTS[6] = HuiguiSP_Gift_6
	HuiguiSP_TEXTS[7] = HuiguiSP_Gift_7

	HuiguiSP_TEXTS_TIPS[1] = HuiguiSP_Gift1tips
	HuiguiSP_TEXTS_TIPS[2] = HuiguiSP_Gift2tips
	HuiguiSP_TEXTS_TIPS[3] = HuiguiSP_Gift3tips
	HuiguiSP_TEXTS_TIPS[4] = HuiguiSP_Gift4tips
	HuiguiSP_TEXTS_TIPS[5] = HuiguiSP_Gift5tips
	HuiguiSP_TEXTS_TIPS[6] = HuiguiSP_Gift6tips
	HuiguiSP_TEXTS_TIPS[7] = HuiguiSP_Gift7tips

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= HuiguiSP_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= HuiguiSP_Frame:GetProperty("UnifiedYPosition");

	g_ButtonPos[1].x	= HuiguiSP_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= HuiguiSP_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= HuiguiSP_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= HuiguiSP_Button3tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[2].x	= HuiguiSP_Button6:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= HuiguiSP_Button6:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= HuiguiSP_Button6tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= HuiguiSP_Button6tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[3].x	= HuiguiSP_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= HuiguiSP_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= HuiguiSP_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= HuiguiSP_Button5tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= HuiguiSP_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= HuiguiSP_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= HuiguiSP_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= HuiguiSP_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[5].x	= HuiguiSP_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= HuiguiSP_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= HuiguiSP_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= HuiguiSP_Button8tips:GetProperty("UnifiedYPosition");

end

-- 回归按钮和文字状态同步
function HuiguiSP_UpdateButtonStatus()
	--PushDebugMessage("==:"..Get_XParam_INT(1).."==="..Get_XParam_INT(2).."==="..Get_XParam_INT(3).."==="..Get_XParam_INT(4).."==="..Get_XParam_INT(5).."==="..Get_XParam_INT(6).."==="..Get_XParam_INT(7).."==="..Get_XParam_INT(8).."==="..Get_XParam_INT(9).."==="..Get_XParam_INT(10).."==="..Get_XParam_INT(11))

	-- 7日领奖状态
	-- local nHuiguiStatus = {}
	-- 最终大奖
	local nHuiguiFinishStatus = {}

	local nStr = "";
	local nShowTips = 0;
	-- 8天的状态
	for i = 1, 8 do
		g_HuiguiSP_HuiguiStatus[i] = Get_XParam_INT(i)
		nStr = nStr..g_HuiguiSP_HuiguiStatus[i].."==";
		if (1 == g_HuiguiSP_HuiguiStatus[i]) then
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
	--	HuiguiSP_BUTTONS[i]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_WeiDaCheng")
	--	HuiguiSP_BUTTONS[i]:Disable()
	--elseif (1 == tonumber(nHuiguiStatus[i])) then
	--	HuiguiSP_BUTTONS[i]:SetProperty("PushedImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Pushed")
	--	HuiguiSP_BUTTONS[i]:SetProperty("NormalImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Normal")
	--	HuiguiSP_BUTTONS[i]:SetProperty("HoverImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Hover")
	--	HuiguiSP_BUTTONS[i]:SetProperty("DisabledImage", "set:ServerNewUI2 image:ServerNewUI_LQ_Disable")
	--	HuiguiSP_BUTTONS[i]:Enable()
	--elseif (2 == tonumber(nHuiguiStatus[i])) then
	--	HuiguiSP_BUTTONS[i]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_Disable")
	--	HuiguiSP_BUTTONS[i]:Disable()
	--end

	-- 完成指定副本次数
	if (30 > nCount) then
		local str = ScriptGlobal_Format("#{HLZS_170705_07}", tostring(nCount))
		HuiguiSP_text2:SetText(str)
	else
		HuiguiSP_text2:SetText ("#{HLZS_170705_08}")
	end
	-- 帮会城市
	if (0 == nHuiguiGuildCity) then
		HuiguiSP_text1:SetText ("#{HLZS_170705_05}")
	else
		HuiguiSP_text1:SetText ("#{HLZS_170705_06}")
	end

	-- 7日归来好礼
	if (2 == g_HuiguiSP_HuiguiStatus[8]) then
		-- 已领取
		HuiguiSP_Qitian_Bk1_Button:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		HuiguiSP_Qitian_Bk1_Button:Disable()
	elseif (0 == nHuiguiGuildCity or 30 > nCount) then
		HuiguiSP_Qitian_Bk1_Button:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		HuiguiSP_Qitian_Bk1_Button:Disable()
	else
		HuiguiSP_Qitian_Bk1_Button:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		HuiguiSP_Qitian_Bk1_Button:Enable()
	end

	local nHuiguiSP_Month1 = ""
	local nHuiguiSP_Day1 = ""
	local nHuiguiSP_Month7 = ""
	local nHuiguiSP_Day7 = ""
	-- 回流第一次登录时间
	for i = 1, 7 do
		local nCuryear, nCurmonth, nCurday = ZhanTuanInterface:GetConvertUT(nHuiGuiFirstTime + ((i-1) * 86400));
		HuiguiSP_TEXTS[i] : SetText(nCurmonth.."月"..nCurday.."日");
		if (1 == i) then			-- 第一天
			nHuiguiSP_Month1 = tostring(nCurmonth)
			nHuiguiSP_Day1 = tostring(nCurday)
		elseif (7 == i) then		-- 第七天
			nHuiguiSP_Month7 = tostring(nCurmonth)
			nHuiguiSP_Day7 = tostring(nCurday)
		end

		if(1 == g_HuiguiSP_HuiguiStatus[i]) then
			HuiguiSP_TEXTS_TIPS[i]:Show();
		else
			HuiguiSP_TEXTS_TIPS[i]:Hide();
		end
	end

	-- 文字说明
	local str22 = ScriptGlobal_Format("#{HLZS_170705_03}", tostring(nHuiguiSP_Month1), tostring(nHuiguiSP_Day1), tostring(nHuiguiSP_Month7),
	tostring(nHuiguiSP_Day7), tostring(nHuiguiSP_Month7), tostring(nHuiguiSP_Day7), tostring(nHuiguiSP_Month7), tostring(nHuiguiSP_Day7))
	HuiguiSP_RightFrame_Info:SetText(str22);

	g_HuiguiSP_DiffDay1 = tonumber(diffday+1);
	-- 切换物品显示
	HuiguiSP_SwitchItemShow(tonumber(diffday+1));
end

function HuiguiSP_OnShown()

	local nSalaryTask = 2
	local nShaoDang = 3
	local nOneDay = 4
	local nHuiGui = 5

	-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 ) then
		HuiguiSP_Button3 : Hide();

		nSalaryTask = nSalaryTask - 1
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
		nHuiGui = nHuiGui-1
	--	return
	else
		HuiguiSP_Button3 : Show();

	end


	local nLevel = Player:GetLevel();
	if ( nLevel < 35 or DataPool:GetServerDayTime() > 20211016) then
		HuiguiSP_Button6:Hide()
		nSalaryTask = -1
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
		nHuiGui = nHuiGui-1
	else
		HuiguiSP_Button6:Show()
	end

	HuiguiSP_Button5:Show()
	if ( nLevel < 60 ) then
		HuiguiSP_Button5:Hide()
		nShaoDang = -1
		nOneDay = nOneDay-1
		nHuiGui = nHuiGui-1
	end


	if nSalaryTask ~= -1 then
		HuiguiSP_Button6:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].x);
		HuiguiSP_Button6:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].y);
		HuiguiSP_Button6tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSalaryTask].tipx);
		HuiguiSP_Button6tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSalaryTask].tipy);
	end

	if nShaoDang ~= -1 then
		HuiguiSP_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
		HuiguiSP_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
		HuiguiSP_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
		HuiguiSP_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);

	end

	if nOneDay ~= -1 then
		HuiguiSP_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		HuiguiSP_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		HuiguiSP_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		HuiguiSP_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);
	end

	if nHuiGui ~= -1 then
		HuiguiSP_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].x);
		HuiguiSP_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].y);
		HuiguiSP_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].tipx);
		HuiguiSP_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].tipy);
	end

	--更新小红点
	-- if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
	-- 	DataPool:Lua_SetUpdateTipsFlag(1,1)
	-- end

	-- 已领取
	-- HuiguiSP_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_Disable")
	-- HuiguiSP_Qitian_Bk1_Button:Disable()
	-- HuiguiSP_Day1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_WeiDaCheng")
	-- HuiguiSP_Day1_Button:Disable()

	HuiguiSP_Refresh_ButtonTips()

	-- for i = 0, 2 do
	-- 	local theAction = EnumAction(i, "huigui_item");
	-- 	if theAction:GetID() ~= 0 then
	-- 		HuiguiSP_Action[i+1]:SetActionItem(theAction:GetID());
	-- 		-- if ( i >= nIndex) then
	-- 		-- 	HuiguiSP_BUTTONS[i+1] : Enable()
	-- 		-- else
	-- 		-- 	HuiguiSP_BUTTONS[i+1] : Disable()
	-- 		-- end
	-- 	end
	-- end

	--
	HuiguiSP_SetCheck()

	-- DataPool:Lua_UpdateHuiGuiItem()

	this:Show();
end


--================================================
-- 切换物品显示
--================================================
function HuiguiSP_SwitchItemShow(diffday)

	g_HuiguiSP_DiffDay = diffday;
	if(8 > diffday and 0 < diffday) then
		-- 显示当前天的tag
		for i = 1, 7 do
			if (i == diffday) then
				HuiguiSP_TEXTS[i] : SetProperty("Selected", "True")
			else
				HuiguiSP_TEXTS[i] : SetProperty("Selected", "False")
			end
		end

		-- 元宝显示
		local str = ScriptGlobal_Format("#{HLZS_170705_38}", tostring(g_HuiguiSP_YuanBao2_Array[diffday]))
		local str1 = ScriptGlobal_Format("#{HLZS_170705_48}", tostring(g_HuiguiSP_YuanBao1_Array[diffday]))
		local str2 = ScriptGlobal_Format("#{HLZS_170705_48}", tostring(g_HuiguiSP_YuanBao3_Array[diffday]))
		HuiguiSP_Frame2_Yuanbao:SetText(str);
		HuiguiSP_Frame2_Yuanbao1:SetText(str1);
		HuiguiSP_Frame1_Yuanbao1:SetText(str2);

		-- 物品数量
		HuiguiSP_Frame1_Num:SetText("#e000001#W"..tostring(HuiguiSP_Num1_Array[diffday]));
		--HuiguiSP_Frame2_Num:SetText(tostring(HuiguiSP_Num1_Array[diffday]));
		HuiguiSP_Frame2_Num1:SetText("#e000001#W"..tostring(HuiguiSP_Num2_Array[diffday]));
		HuiguiSP_Frame_Num:SetText(tostring(2));


		HuiguiSP_BUTTONS[1]:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		HuiguiSP_BUTTONS[1]:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		HuiguiSP_BUTTONS[1]:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		HuiguiSP_BUTTONS[1]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		HuiguiSP_BUTTONS[2]:SetProperty("set:ImageButtons image:ImageButtons_Buy_Pushed")
		HuiguiSP_BUTTONS[2]:SetProperty("NormalImage", "set:ImageButtons image:ImageButtons_Buy_Normal")
		HuiguiSP_BUTTONS[2]:SetProperty("HoverImage", "set:ImageButtons image:ImageButtons_Buy_Hover")
		HuiguiSP_BUTTONS[2]:SetProperty("DisabledImage", "set:ImageButtons image:ImageButtons_Buy_Gray")
		-- 重置按钮状态
		if (0 == tonumber(g_HuiguiSP_HuiguiStatus[diffday])) then
			-- HuiguiSP_BUTTONS[1]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_WeiDaCheng")
			-- HuiguiSP_BUTTONS[1]:Disable()
			--for i = 1, 2 do
				HuiguiSP_BUTTONS[1]:Disable()

				HuiguiSP_BUTTONS[2]:Disable()
				local str = ScriptGlobal_Format("#{HLZS_170705_17}", tostring(150))
				HuiguiSP_Day_Huoyue1 : SetText(str)
				--HuiguiSP_Day_Huoyue2 : SetText(str)
			--end
		elseif (1 == tonumber(g_HuiguiSP_HuiguiStatus[diffday])) then
			--for i = 1, 2 do
				HuiguiSP_BUTTONS[1]:Enable()

				HuiguiSP_BUTTONS[2]:Enable()
			--end
			local str = ScriptGlobal_Format("#{HLZS_170705_18}", tostring(150))
			HuiguiSP_Day_Huoyue1 : SetText(str)
			--HuiguiSP_Day_Huoyue2 : SetText(str)
		elseif (2 == tonumber(g_HuiguiSP_HuiguiStatus[diffday])) then
			--for i = 1, 2 do
				HuiguiSP_BUTTONS[1]:Disable()

				HuiguiSP_BUTTONS[2]:Disable()
				local str = ScriptGlobal_Format("#{HLZS_170705_18}", tostring(150))
				HuiguiSP_Day_Huoyue1 : SetText(str)
				--HuiguiSP_Day_Huoyue2 : SetText(str)
			--end
		end

		-- 判断是否是当天
		if(g_HuiguiSP_DiffDay1 == diffday) then
			local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
			local str = ScriptGlobal_Format("#{HLZS_170705_18}", tostring(150))
			if (nToadyActivePoint < 150) then
				str = ScriptGlobal_Format("#{HLZS_170705_51}", tostring(nToadyActivePoint))
			end

			HuiguiSP_Day_Huoyue1 : SetText(str)
		end
	end

	DataPool:Lua_UpdateHuiGuiItem()
	for i = 0, 1 do
		local theAction = EnumAction(tonumber(g_HuiguiSP_DiffDay-1), "huigui_item");
		--PushDebugMessage("==sss=="..theAction:GetID())
		if theAction:GetID() ~= 0 then
			HuiguiSP_Action[i+1]:SetActionItem(theAction:GetID());
			-- if ( i >= nIndex) then
			-- 	HuiguiSP_BUTTONS[i+1] : Enable()
			-- else
			-- 	HuiguiSP_BUTTONS[i+1] : Disable()
			-- end
		end
	end

	local theAction1 = EnumAction(7, "huigui_item");
	if theAction1:GetID() ~= 0 then
		HuiguiSP_Qitian_Frame_Icon:SetActionItem(theAction1:GetID());
	end
--PushDebugMessage("==g_HuiguiSP_DiffDay=="..g_HuiguiSP_DiffDay)
end

--================================================
-- 界面的默认相对位置
--================================================
function HuiguiSP_ResetPos()
	HuiguiSP_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	HuiguiSP_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function HuiguiSP_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SPSelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
	    HuiguiSP_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end

function HuiguiSP_OnClosed()
	this:Hide();
end

function HuiguiSP_OnHiden()
	this:Hide();
end

function HuiguiSP_Button1_Click()

	OpenMonthlySignSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", HuiguiSP_Frame:GetProperty("UnifiedPosition"), 1)
--	this:Hide()
end

function HuiguiSP_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end

	OpenStrongRoadDiaoWenSP(1)

	Variable:SetVariable("SPSelfFuliUIPos", HuiguiSP_Frame:GetProperty("UnifiedPosition"), 1)

end

function HuiguiSP_Button3_Click()
	OpenQianKunDaiSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", HuiguiSP_Frame:GetProperty("UnifiedPosition"), 1)
--	this:Hide()
end

function HuiguiSP_Button4_Click()

end

function HuiguiSP_Button5_Click()
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
end

function HuiguiSP_Button6_Click()
end

function HuiguiSP_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end 
	Variable:SetVariable("SPSelfFuliUIPos", HuiguiSP_Frame:GetProperty("UnifiedPosition"), 1)
end

-- 更新小红点
function HuiguiSP_Refresh_ButtonTips()

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		HuiguiSP_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		HuiguiSP_Button8tips : Hide()
	end

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		HuiguiSP_Button7tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		HuiguiSP_Button7tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		HuiguiSP_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		HuiguiSP_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		HuiguiSP_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		HuiguiSP_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 )then
			DataPool:Lua_SetRedPointInUIShow(39, 0)
			HuiguiSP_Button3tips : Hide()
		else
			HuiguiSP_Button3tips : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		HuiguiSP_Button3tips : Hide()
	end


	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		HuiguiSP_Button5tips : Show()
	else
		HuiguiSP_Button5tips : Hide()
	end

	HuiguiSP_Button6tips : Hide()


end

function HuiguiSP_OnClosed()
    this:Hide()
    return
end

function HuiguiSP_UpdateInfo(param,diffday,nCount,nHuiguiGuild)
	--PushDebugMessage("HuiguiSP_UpdateInfo:"..param.."=="..diffday.."=="..nCount.."=="..nHuiguiGuild)
	g_HuiguiSP_HuiguiStatus[diffday] = 2;
	if (3 ~= param) then	-- 一，二按钮

		HuiguiSP_BUTTONS[1]:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		HuiguiSP_BUTTONS[1]:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		HuiguiSP_BUTTONS[1]:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		HuiguiSP_BUTTONS[1]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		HuiguiSP_BUTTONS[2]:SetProperty("set:ImageButtons image:ImageButtons_Buy_Pushed")
		HuiguiSP_BUTTONS[2]:SetProperty("NormalImage", "set:ImageButtons image:ImageButtons_Buy_Normal")
		HuiguiSP_BUTTONS[2]:SetProperty("HoverImage", "set:ImageButtons image:ImageButtons_Buy_Hover")
		HuiguiSP_BUTTONS[2]:SetProperty("DisabledImage", "set:ImageButtons image:ImageButtons_Buy_Gray")
		HuiguiSP_BUTTONS[1]:Disable()
		HuiguiSP_BUTTONS[2]:Disable()
		--for i = 1, 2 do
		--	HuiguiSP_BUTTONS[i]:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Yilingqu_Disable")
		--	HuiguiSP_BUTTONS[i]:Disable()
		--end
	else					-- 7日归来好礼
		HuiguiSP_Qitian_Bk1_Button:SetProperty("set:PlayReturn image:PlayReturn_Lingqu_Pushed")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("NormalImage", "set:PlayReturn image:PlayReturn_Lingqu_Normal")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("HoverImage", "set:PlayReturn image:PlayReturn_Lingqu_Hover")
		HuiguiSP_Qitian_Bk1_Button:SetProperty("DisabledImage", "set:PlayReturn image:PlayReturn_Lingqu_Disable")
		HuiguiSP_Qitian_Bk1_Button:Disable()
	end
	local nShowTips = 0;
	for i = 1, 7 do
		if (1 == g_HuiguiSP_HuiguiStatus[i]) then
			nShowTips = 1;
			HuiguiSP_TEXTS_TIPS[i]:Show();
		else
			HuiguiSP_TEXTS_TIPS[i]:Hide();
		end
	end

	-- 完成30次指定副本，刷新小红点
	if (2 ~= g_HuiguiSP_HuiguiStatus[8] and 30 <= nCount and 1 == nHuiguiGuild) then
		nShowTips = 1;
	end

	--是否显示小红点
	if nShowTips == 1 then
		DataPool:Lua_SetUpdateTipsFlag(1,1)
		HuiguiSP_Button8tips : Show()
	else
		DataPool:Lua_SetUpdateTipsFlag(1,0)
		HuiguiSP_Button8tips : Hide()
	end
	PushEvent("BIN_PLAYER_UPDATE_UI", 1)
end

--领取
function HuiguiSP_Clicked( param )

	--PushDebugMessage("HuiguiSP_Clicked:"..g_HuiguiSP_DiffDay)
	local str = "";
	if (1 == param) then			-- 免费
		local num = HuiguiSP_Num1_Array[g_HuiguiSP_DiffDay];
		local name = HuiguiSP_Name_Array[g_HuiguiSP_DiffDay];
		local yuanbao = g_HuiguiSP_YuanBao2_Array[g_HuiguiSP_DiffDay];
		local num_new = tonumber(HuiguiSP_Num2_Array[g_HuiguiSP_DiffDay]);
		str = ScriptGlobal_Format("#{HLZS_170705_40}", tostring(num), tostring(name), tostring(yuanbao), tostring(num_new), tostring(name) )
	elseif (2 == param) then		-- 元宝购买
		local num = HuiguiSP_Num1_Array[g_HuiguiSP_DiffDay];
		local name = HuiguiSP_Name_Array[g_HuiguiSP_DiffDay];
		local yuanbao = g_HuiguiSP_YuanBao2_Array[g_HuiguiSP_DiffDay];
		local num_new = tonumber(HuiguiSP_Num2_Array[g_HuiguiSP_DiffDay]);
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
function HuiguiSP_Button1_Clicked()
	OpenQianKunDaiSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", HuiguiSP_Frame:GetProperty("UnifiedPosition"), 1)
end

--
function HuiguiSP_Button2_Clicked()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end

	OpenStrongRoadDiaoWenSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", HuiguiSP_Frame:GetProperty("UnifiedPosition"), 1)
end

--
function HuiguiSP_Button3_Clicked()
	OpenQianKunDaiSP(1)
	Variable:SetVariable("SPSelfFuliUIPos", HuiguiSP_Frame:GetProperty("UnifiedPosition"), 1)
end

function HuiguiSP_SetCheck()
		HuiguiSP_Button1:SetCheck(0)
		HuiguiSP_Button2:SetCheck(0)
		HuiguiSP_Button3:SetCheck(0)
		HuiguiSP_Button5:SetCheck(0)
		HuiguiSP_Button6:SetCheck(0)
		HuiguiSP_Button7:SetCheck(0)
		HuiguiSP_Button8:SetCheck(1)
end

--
function HuiguiSP_Button4_Clicked()

end

--
function HuiguiSP_Button5_Clicked()
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
	Variable:SetVariable("SPSelfFuliUIPos", HuiguiSP_Frame:GetProperty("UnifiedPosition"), 1)
end

--
function HuiguiSP_Button6_Clicked()
	local nLevel = Player:GetLevel();
	if ( nLevel < 35 ) then
		return
	end

	OpenNewSalaryTaskSP(1)

	Variable:SetVariable("SPSelfFuliUIPos", HuiguiSP_Frame:GetProperty("UnifiedPosition"), 1)
end
