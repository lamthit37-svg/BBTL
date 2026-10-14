

------------------------------------------------------------------------------------------------------
--
-- 全局变量区
--
--
-- 下面的这个类型不准，好多没记
-- 可以用下面正则查一下
-- .*g_iYesNoType\s*=\s*\d+
------------------------------
local g_iYesNoType = -1;	-- yes-no 对话框类型
													-- -1 -- 普通信息提示
													-- 0 - 退出游戏
													-- 1 - 删除角色
													-- 2 - 更换帐号
													-- 3 - 断开网络
													-- 4 - 确认是否删除10级以上玩家
													-- 5 - 7天内提醒删除10级以上玩家
													-- 6 - 7天后，14天内提醒删除10级以上玩家
													-- 7 - 是否删除10级以下玩家
													-- 8 删除玩家
													-- 9 是否注册
													--25 更新服务器列表
													--30 变性确认
													--32 真元淬解确认按钮
													--33全部淬解
													--34 淬解后超过上限
													--35 全部淬解超过上限
													--36 一键凝练过程中自动淬解
													--37 一键换宝石装备绑定
													--39 宝石转换确认按钮
													--42 分期付款首付二次确认
													--43 分期付款还款二次确认
													--44 时装绑定状态二次确认
													--45 帮会聚宝盆领双二次确认
													--46 子女卡牌直升9星
													--47 子女时装剪裁染色二次确认
													--48 子女时装剪裁买道具二次确认
													--52 子女时装染色，绑定确认
													--54 帮会聚宝盆补领双二次确认
													--76 收回同类家具二次确认
													--77 更新舒适度排行榜数据
													--81 登录提示 激活帐号
													--82 暂时没用
													--83 武意乾坤丹150满级使用的二次确认
													--84 2018清明节活动占用
													--85 到95已占用
													--98 2018千里共婵娟类型1二次确认
													--99 2018千里共婵娟类型2二次确认
													--100 2018千里共婵娟类型3二次确认
													--101 2018千里共婵娟无类型二次确认
													--102 2019元宵节扣碗猜球活动
													--110 朋友圈打开确认
													--111 限制登录，未成年人，未满18岁，时间内
													--112 限制登录，未成年人，未满18岁
													--113 限制登录，注销帐号
													--114 限制登录，实名格式不对
													--115 飞鱼印染 稀有确认
													--116 飞鱼印染 绑定确认
													--117 2020T300预热 1127整合奖励
													--118 2020T300预热 汴京八景补绘制
													--119 2020T300预热 汴京30分钟点卡
													--121 2021特殊时装染色二次确认
													--122 2021周年预热活动--重来一次按钮 二次确认
													--123 2021周年预热活动--确认领取按钮 二次确认
													--124 限制登录，实名格式不对
													--125 限制登录，未成年人，未满18岁
													--126 2021争霸赛 第二角色变性确认
													--127 2021御猫探宝玩法 二次确认
													--128 2021中秋玉兔礼盒 二次确认
													--129 限制登录，正在审核中
													--130 2021Q3投壶预热
													--131 禁止起名
													--132 春风送暖
													--133 代币整合召唤NPC，二次确认
													--134 代币整合兑换召唤券，二次确认
													--135 使用周年十五载礼包 二次确认
													--136 使用周年十六载礼包 二次确认
													--137 FlagB
													--138 内丹升阶二次确认
													--139 内丹降阶二次确认
													--146 200金交子开启经脉分页2二次确认
													--159 登录时20秒倒计时

local g_strMessageData;

local g_bagIndex = -1
local g_bagIndex2 = -1
local g_item = -1
local g_itemNum = -1
local g_objCared = -1
local g_pos = -1
local g_iWeddingDay = -1
--local g_equipSrc = -1
--local g_equipDst = -1
--local g_equipFu = -1
-- 5星及以上珍兽装备升星需要的材料位置
local g_percent

--是否短期封停
local g_IsThreedForbit = -1
local g_showbuttonStr = nil

--真元淬解
local g_PneumaSmeltBag_Pos=-1
--真元
local g_PneumaSmeltBag_Pos34 = -1
local g_PneumaSmeltBag_Pos36 = -1
local ZhenYuan_NewerMission_HanRuHai = 1603

local g_IsNoMIBAO = 0

local g_DownPayIndex = -1
local g_RePayIndex = -1

local g_card_stepup_bagindex = -1

local g_TargetID = -1

local g_CostNum	 = -1
local g_ChengZhangZhi = -1

local g_FurnitureDelItemID = -1

local g_FurnitureType = -1
local g_FurnitureLevel = -1
local g_FurniturePos = -1

local g_ItemBagIDXiYou = -1
local g_ItemBagID = -1
local g_ItemBagIDBind = -1
local g_BagItemIndex = -1
local g_ZHFBagIndex = -1

local g_ExchangeIndex = -1
local g_tmpData = {}

local g_HappyTLTenYearsIndex = -1

local g_JiuJiuXiaoHan_Summer_Index = -1

local g_HuoyueWeeklyGift_Index = -1

local g_CaiQiu_TargetID = -1;

-- 2021御猫探宝玩法 二次确认
local g_MissionIndex = 0
local g_CatId = {0,0,0,}

local g_nWaitSec=0;
local g_nWaitErrCode=0;

-- LoginSelectServerQuest_OnEvent中的upvalue已经达到上限 不要再添加新的临时变量啦 请使用g_tmpData保存临时数据



-- 注册onLoad事件
function LoginSelectServerQuest_PreLoad()

	-- 打开界面
	this:RegisterEvent("GAMELOGIN_SHOW_SYSTEM_INFO",true);

	-- 关闭界面
	this:RegisterEvent("GAMELOGIN_CLOSE_SYSTEM_INFO",true);


	-- 点击确定按钮关闭网络
	this:RegisterEvent("GAMELOGIN_SHOW_SYSTEM_INFO_CLOSE_NET",true);

	-- 显示不带按钮的信息
	this:RegisterEvent("GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON",true);
	-- 显示yes-no信息
	this:RegisterEvent("GAMELOGIN_SYSTEM_INFO_YESNO",true);
	this:RegisterEvent("GAMELOGIN_SYSTEM_INFO_OK",true);
	this:RegisterEvent("GAMELOGIN_SYSTEM_INFO_CANCEL",true);
	this:RegisterEvent("GAMELOGIN_SYSTEM_INFO_CLOSE",true);
	this:RegisterEvent("UI_COMMAND",true);
	-- 珍兽装备分解确认
	this:RegisterEvent("PET_EQUIP_DEPART_CONFIRM",true)
	-- 绑定元宝商店玩家绑定元宝不足时，二次确认的界面
	--this:RegisterEvent("BINDYUANBAO_NOTENOUGH_YESNO",true)
--~ 	-- 珍兽装备升星几率不足100%确认
--~ 	this:RegisterEvent("PET_EQUIP_SUITUP_CONFIRM",true)
	this:RegisterEvent("DISPLACEGEM_CONFIRM",true)
	this:RegisterEvent( "DISPLACE_CLOSE_MSGBOX",true );
	--支持enter键关闭新建角色时弹出的重名提示框
	this:RegisterEvent("CREATECHAR_CLOSE_RENAME_NOTE",true);
	this:RegisterEvent( "PNEUMA_CUIJIE_CONFIRM" ,true)
	this:RegisterEvent( "PNEUMA_CUIJIEALL_CONFIRM" ,true)
--	this:RegisterEvent( "PNEUMA_CUIJIE_CONFIRM_MAX" ,true)
--	this:RegisterEvent( "PNEUMA_CUIJIEALL_CONFIRM_MAX" ,true)
	this:RegisterEvent( "NINGLAINALL_CUIJIECONFIRM" ,true)
	--附体幻色二次确认
	--this:RegisterEvent( "PETPOSSHUANSE_SELECTSERVER",true )--取消二次确认
	--时装染色二次确认
	this:RegisterEvent( "DRESSPAINT_SELECTSERVER" ,true)
	--减抗石头绑定确认
	this:RegisterEvent( "BIND_DOUBLEGEM_ZHUOKE" ,true)
	--珍兽进阶
	this:RegisterEvent( "PETJINJIE_XUELIZI_CONFIRM" ,true)
	-- Start: Add By YPL, 宝石转换
	this:RegisterEvent( "BAOSHI_CHANGE_CONFIRM" ,true)

	--时装染色绑定二次确认
	this:RegisterEvent( "DRESSPAINT_BINDDRESS" ,true)
	this:RegisterEvent( "INFANT_CARD_STEPUP_CONFIRM" ,true)
	this:RegisterEvent( "DRESSPAINT_SP_BINDDRESS" ,true)

	this:RegisterEvent( "INFANTDRESSPAINT_BIND_CONFIRM" ,true)
	this:RegisterEvent( "FATIE_SECCONFIRM" ,true)
	this:RegisterEvent( "BIEYE_RESERVE_TYPE_CONFIRM",true )

	--  分期付款首付二次确认
	--this:RegisterEvent( "BUDGETPLANINFO_DOWNPAY" ,true)
	--	分期付款还款二次确认
	--this:RegisterEvent( "BUDGETPLANINFO_REPAY" ,true)
	this:RegisterEvent( "BIEYE_PETCOLOR_CONFIRM" ,true)

	this:RegisterEvent("FEIYUDRESS_PAINT_EXPSURE",true)
	this:RegisterEvent("FEIYUDRESS_PAINT_BINDSURE",true)

	--内丹升阶二次确认
	this:RegisterEvent("NEIDANUPGRADE_CONFIRM",true)
	--内丹降阶二次确认
	this:RegisterEvent("NEIDANDOWNGRADE_CONFIRM",true)

	-- 凤鸣城战轮换玩法
	this:RegisterEvent("TCITYWARLIMIT_ASSIGNCONFIRM", true)
	this:RegisterEvent("TCITYWARLIMIT_CANCELCONFIRM", true)
	this:RegisterEvent("TCITYWARLIMIT_SAVECONFIRM", true)
	this:RegisterEvent("TCITYWARLIMIT_REFRESHCONFIRM", true)
	this:RegisterEvent("TCITYWARLIMIT_EXITCONFIRM", true)
	this:RegisterEvent("TCITYWARLIMIT_REMOVEASSISTCONFIRM", true)
	this:RegisterEvent("TCITYWARLIMIT_CANCELASSISTCONFIRM", true)
end

function LoginSelectServerQuest_OnLoad()

	-- 设置总是在最上层显示
	SelectServerQuest_Frame_sub:SetProperty("AlwaysOnTop", "True");

	--
	SelectServerQuest_Button1:Enable()

end

function LoginSelectUpdateRect()
	local nWidth, nHeight = SelectServerQuest_InfoWindow:GetWindowSize();
	local nTitleHeight = 23;
	local nBottomHeight = 25;
	local nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	SelectServerQuest_Frame_sub:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );

	--SelectServerQuest_Frame_sub:SetWindowSize( nWindowWidth, nWindowHeight );
end

local TimerArg = "";
local g_QuitType = 0;    --增加3， 这种类型的和类型0的区别是没取消按钮的！
local g_bIsQuitMsgBox = 0;
-- OnEvent
function LoginSelectServerQuest_OnEvent(event)

	--如果处于显示中，不要初始化,否则UI_COMMAND来出现bug
	if (not this:IsVisible()) then
		g_bIsQuitMsgBox = 0;
    SelectServerQuest_Frame_sub:SetProperty( "UnifiedPosition", "{{0.500000,-173.000000},{0.500000,-118.000000}}" )


		SelectServerQuest_Button2:Hide();
		SelectServerQuest_Button1:Hide();
		SelectServerQuest_LostPassword:Hide()
		SelectServerQuest_Time_Text : Hide();
		SelectServerQuest_InfoWindow:Show();
	end

	SelectServerQuest_BetterServer:Hide()
	SelectServerQuest_Quit:Hide()
	SelectServerQuest_Button1:Enable()

	if( event == "GAMELOGIN_SHOW_SYSTEM_INFO" ) then

		g_iYesNoType = -1;
		g_IsThreedForbit = -1

		if( arg1 ~= "WAITFORQUIT" or arg1 ~= "WAITFORQUIT_SO") then
			SelectServerQuest_InfoWindow:SetText(arg0);
			LoginSelectUpdateRect();
		end
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:SetText("关闭");
		SelectServerQuest_Button1:Enable()


		if( arg1 == "USERONLINE" ) then
		    SelectServerQuest_Time_Text : SetProperty("Timer",tostring(20));
		    SelectServerQuest_Time_Text : Show()
		    SelectServerQuest_Button1:Disable()
		    TimerArg = arg1;
		    arg1 = nil;
		elseif (arg1 == "LOGINR_NO_IPHONE" ) then
			g_iYesNoType = 81
			--设置按钮
			SelectServerQuest_Button1:SetText("#{DLRZSJ_170914_01}") -- 激活
			SelectServerQuest_Button1:Show()
			SelectServerQuest_Button1:Enable()
			SelectServerQuest_Button2:SetText("#{DLRZSJ_170914_02}") -- 关闭
	    SelectServerQuest_Button2:Show()
			SelectServerQuest_Button2:Enable()

			TimerArg = arg1;
		  arg1 = nil;

			GameProduceLogin:OpenURL(GetWeblink("WEB_ACTIVEACC"))	--弹出页面

		elseif (arg1 == "UserId_Password_Err") then
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:Enable()
			
		elseif (arg1 == "CN_UNDERAGE_18") then
			g_iYesNoType = 112;
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:SetText("#{WCN_191119_04}");
			SelectServerQuest_LostPassword:Enable()

		elseif (arg1 == "CN_REMOVEACCOUNT") then
			g_iYesNoType = 113;
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:SetText("#{WCN_191119_06}");
			SelectServerQuest_LostPassword:Enable()
			
		elseif (arg1 == "CN_SHIMING_INVALID") then
			g_iYesNoType = 114;
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:SetText("#{WCN_191119_02}");
			SelectServerQuest_LostPassword:Enable()
			
		elseif (arg1 == "FCM_CERTNUM_CHECKERROR") then
			g_iYesNoType = 124;
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:SetText("#{DLYZFCM_210414_02}");
			SelectServerQuest_LostPassword:Enable()
			
		elseif (arg1 == "CN_UNDERAGE_18_2021") then
			g_iYesNoType = 125;
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:SetText("#{DLYZFCM_210414_05}");
			SelectServerQuest_LostPassword:Enable()
		
		elseif (arg1 == "CN_UNDERREVIEW_2021") then
			g_iYesNoType = 129;
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:SetText("#{DLYZFCM_210414_05}");
			SelectServerQuest_LostPassword:Enable()	
		elseif (arg1 == "CN_NOPHONE") then
			g_iYesNoType = 137;
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:SetText("#{GZSZH_230427_14}");
			SelectServerQuest_LostPassword:Enable()	
		elseif(arg1 == "USERFROMMAINPRO") then
		    SelectServerQuest_Time_Text : SetProperty("Timer",tostring(20));
		    SelectServerQuest_Time_Text : Show()
		    SelectServerQuest_Button1:Hide();
		    SelectServerQuest_Button2:Hide();
		    TimerArg = arg1;
		    arg1 = nil;
		elseif( arg1 == "MIBAOERROR" ) then
		    SelectServerQuest_Time_Text : SetProperty("Timer",tostring(30));
		    SelectServerQuest_Time_Text : Show()
		    SelectServerQuest_Button1:Disable()
		    TimerArg = arg1;
		    arg1 = nil;
		elseif( arg1 == "TURNOVER" ) then
		    SelectServerQuest_Time_Text : SetProperty("Timer",tostring(8));
		    SelectServerQuest_Time_Text : Show()
		    SelectServerQuest_Button1:Disable()
		    TimerArg = arg1;
		    arg1 = nil;
		elseif( arg1 == "WAITFORQUIT" ) then
			if (arg4 ~= nil and tonumber(arg4) ~= nil and tonumber(arg4) > 0) then
				--add by kaibin for炼制玄灵丹
				local nLeftTime = 3
				if (arg5 ~= nil and tonumber(arg5) ~= nil and tonumber(arg5) > 0) then
					nLeftTime = tonumber(arg5)
				end
				SelectServerQuest_Time_Text : SetProperty("Timer", nLeftTime);
				local BuffName = "Error"
				if tonumber(arg4) == 1 then
					--乾坤药尘
					BuffName = "乾坤药尘"
				elseif tonumber(arg4) == 2 then
				    --玄灵药尘
					BuffName = "玄灵药尘"
				end
				local TipsStr = string.format("下线后#R%s#W会自动消散，将不能领取炼制玄灵丹活动奖励！10秒后退出游戏！", BuffName)
				SelectServerQuest_InfoWindow:SetText(TipsStr);
				LoginSelectUpdateRect();
		    elseif(arg3~=nil and tonumber(arg3)~=nil)then
				if(tonumber(arg3)>0)then
					SelectServerQuest_Time_Text : SetProperty("Timer",tostring(10));
					SelectServerQuest_InfoWindow:SetText("10秒后退出游戏！");
					LoginSelectUpdateRect();

				else
					SelectServerQuest_Time_Text : SetProperty("Timer",tostring(3));
					SelectServerQuest_InfoWindow:SetText("3秒后退出游戏！");
					LoginSelectUpdateRect();
				end
		    else
				SelectServerQuest_Time_Text : SetProperty("Timer",tostring(3));
				SelectServerQuest_InfoWindow:SetText("3秒后退出游戏！");
				LoginSelectUpdateRect();
		    end
		    SelectServerQuest_Time_Text : Show()
		    SelectServerQuest_Button1:SetText("取消");
		    SelectServerQuest_Button1:Show();
		    SelectServerQuest_Button1:Enable();
		    TimerArg = arg1;
		    g_QuitType = tonumber(arg2);
		    if g_QuitType == 3 then
		    	SelectServerQuest_Button1:Hide();
		    end
		    g_bIsQuitMsgBox = 1;
		    arg1 = nil;
		elseif ( arg1 == "WAITFORQUIT_SO" ) then
			SelectServerQuest_Time_Text : SetProperty("Timer",tostring(3));
			if (arg2 ~= nil and 0 == tonumber(arg2)) then
				SelectServerQuest_InfoWindow:SetText("#{LXBT_111226_18}"); --3秒退出，离线摆摊12小时
			elseif(arg2 ~= nil and 1 == tonumber(arg2)) then
				SelectServerQuest_InfoWindow:SetText("#{LXBT_111226_17}"); --3秒返回登录界面，离线摆摊12小时
			else
				SelectServerQuest_InfoWindow:SetText("3秒后退出游戏！");
			end
			LoginSelectUpdateRect();
			 SelectServerQuest_Time_Text : Show()
		    SelectServerQuest_Button1:SetText("取消");
		    SelectServerQuest_Button1:Show();
		    SelectServerQuest_Button1:Enable();
		    TimerArg = arg1;
		    g_QuitType = tonumber(arg2);
		    if g_QuitType == 3 then
		    	SelectServerQuest_Button1:Hide();
		    end
		    g_bIsQuitMsgBox = 1;
		    arg1 = nil;
		elseif( arg1 == "LoginCounting" ) then
				local countTime = tonumber(arg2)
				if(countTime >= 0 and countTime <= 20000) then--逻辑上来说arg2应该是在0到20000之间的。
					countTime = math.floor(countTime/1000) + 1
					if countTime==21 then
						countTime=20
					end
					SelectServerQuest_Time_Text : SetProperty("Timer",tostring(countTime));
		    	SelectServerQuest_Time_Text : Show()
		    	SelectServerQuest_Button1:Disable()
		    	TimerArg = arg1;
				end
			  arg1 = nil
			  arg2 = nil
		elseif(arg1 == "ThreedAccForbit") then
			--add by kaibin for 短期封停解权时间提示(用户中心带3天时间停权)
			g_IsThreedForbit = 1
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:SetText("#{FTZH_110318_01}");
			SelectServerQuest_LostPassword:Enable()
			TimerArg = nil;
		    arg1 = nil;
		elseif(arg1 == "LOGNR_Forbit") then
			--add by kaibin for 短期封停解权时间提示，分开写以后加东西不用改client(其他方式停权或用户中心当前已经停权了还没到3天，billing没有时间的)
			g_IsThreedForbit = 1
			SelectServerQuest_LostPassword:Show();
			SelectServerQuest_LostPassword:SetText("#{FTZH_110318_01}");
			SelectServerQuest_LostPassword:Enable()
			TimerArg = nil;
		    arg1 = nil;
		elseif(arg1 == "LOGIN_NO_MIBAO") then
			--登录时如果选择输入密保但没绑定密保，则取消登陆界面中的密保按钮选中状态
			g_IsNoMIBAO = 1;
			TimerArg = nil;
		    arg1 = nil;
		    
		elseif (arg1 == "ForbidName") then
			g_iYesNoType = 131;
			SelectServerQuest_Button1:SetText("#{TCMZ_211027_5}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:Hide();
		elseif (arg1 == "LOGIN_MUST_WAIT") then
			LoginSelectServerQuest_Init_LOGIN_MUST_WAIT( 159, tonumber(arg2), tonumber(arg3) )
		else
		    TimerArg = nil;
		    arg1 = nil;
		    SelectServerQuest_Time_Text : Hide()
		end

		this:Show();
		return;
	end

	if( event == "GAMELOGIN_CLOSE_SYSTEM_INFO") then

		if(IsWindowShow("OtherQuest") and g_showbuttonStr ~= nil) then
		 CloseWindow("OtherQuest", true);
    end
		g_iYesNoType = -1;
		this:Hide();
		return;
	end


	if( event == "GAMELOGIN_SYSTEM_INFO_YESNO") then


		SelectServerQuest_InfoWindow:SetText(arg0);
		LoginSelectUpdateRect();
		g_iYesNoType = tonumber(arg1);

		if g_iYesNoType == 20 and arg2 ~= nil  and arg3 ~= nil then
			g_objCared = tonumber(arg2)
			g_bagIndex = tonumber(arg3)
		end

		if g_iYesNoType == 30 then --变性
			g_objCared = tonumber(arg2)
		end

		--Add By YuanPeiLong 20141121 [子女变性丹设计]
		if g_iYesNoType == 55 then --变性
			g_objCared = tonumber(arg2)
		end
		
		if g_iYesNoType == 126 then -- 争霸赛变性
			g_objCared = tonumber(arg2)
		end

		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button2:SetText("取消");
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		this:Show();
		return;
	end
	if( event == "GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON" ) then
		local strarg0 = arg0
	  if( nil ~= arg1 ) then
	    local strArg = tostring( arg1 )
			if( strArg == "CharSel_EnterGame" ) then
			--if( strArg == "CharSel_EnterGam" ) then
				SelectServerQuest_Frame_sub:SetProperty( "UnifiedPosition", "{{0.500000,-173.000000},{0.900000,-118.000000}}" )
			elseif (strArg and strArg == "ShowButton") then
				--这个事件的逻辑处理转到selectbetterserver.lua中
				this:Hide()
				return
				--g_showbuttonStr = arg0;
				--if(IsWindowShow("OtherQuest")) then
					--return
					--CloseWindow("WuhunQuest", true);
				--end
				--SelectServerQuest_BetterServer:Show();
				--SelectServerQuest_Quit:Show();
			end
			arg1 = nil;
	  end

		g_iYesNoType = tonumber(arg1);
		SelectServerQuest_InfoWindow:SetText(strarg0);
		LoginSelectUpdateRect();
		this:Show();
		SelectServerQuest_Button1:Hide();
		SelectServerQuest_Button2:Hide();
		--if (strArg and strArg == "ShowButton") then
		--	SelectServerQuest_BetterServer:Show();
		--	SelectServerQuest_Quit:Show();
		--end
		return
	end
	if( event == "GAMELOGIN_SYSTEM_INFO_OK" ) then

		g_iYesNoType = tonumber(arg1);
		SelectServerQuest_InfoWindow:SetText(arg0);
		LoginSelectUpdateRect();
		if g_iYesNoType == 0 then
			SelectServerQuest_Button1:SetText("关闭");
		else
			SelectServerQuest_Button1:SetText("确定");
		end
		this:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:Hide();
		return;
	end
	if ( event == "BIND_DOUBLEGEM_ZHUOKE") then

		g_iYesNoType = -1
		SelectServerQuest_InfoWindow:SetText(arg0);
		LoginSelectUpdateRect();

		SelectServerQuest_Button1:SetText("关闭");
		this:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:Hide();
		return;
	end
	if( event == "GAMELOGIN_SYSTEM_INFO_CANCEL" ) then

		g_iYesNoType = tonumber(arg1);
		SelectServerQuest_InfoWindow:SetText(arg0);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:SetText("取消");
		this:Show();
		SelectServerQuest_Button2:Hide();
		return;
	end
	if( event == "GAMELOGIN_SYSTEM_INFO_CLOSE" ) then

		g_iYesNoType = tonumber(arg1);
		SelectServerQuest_InfoWindow:SetText(arg0);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("关闭");
		this:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:Hide();
		return;
	end
	--珍兽进阶
	if ( event == "PETJINJIE_XUELIZI_CONFIRM" ) then
		g_iYesNoType = tonumber(arg1);
		SelectServerQuest_InfoWindow:SetText(arg0);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("关闭");
		this:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:Hide();
		return;
	end

--       if ( event == "PETPOSSHUANSE_SELECTSERVER" ) then
--		g_iYesNoType = -1;
--		local strHuanse = ScriptGlobal_Format("#{FTHS_120719_78}",tostring(arg0))
--		SelectServerQuest_InfoWindow:SetText(strHuanse);
--		LoginSelectUpdateRect();
--		SelectServerQuest_Button1:SetText("#{FTHS_120719_79}");
--		this:Show();
--		SelectServerQuest_Button1:Show();
--		SelectServerQuest_Button2:Hide();
--		return;
--	end

	if( event == "GAMELOGIN_SHOW_SYSTEM_INFO_CLOSE_NET") then


		g_iYesNoType = 3;
		SelectServerQuest_InfoWindow:SetText(arg0);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:SetText("关闭");
		this:Show();
		return;
	end

	-- 血浴神兵——神器铸造
	if ( event == "UI_COMMAND" and tonumber(arg0) == 13906) then
		g_iYesNoType = -1;
		SelectServerQuest_InfoWindow:SetText("#cFFF263#{XYSB_080925_001}");
		LoginSelectUpdateRect();

		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:SetText("关闭");
		SelectServerQuest_Button1:Enable()

		this:Show();
	end


	-- 血浴神兵——神器重铸
	if ( event == "UI_COMMAND" and tonumber(arg0) == 12032203) then
		g_iYesNoType = -1;
		SelectServerQuest_InfoWindow:SetText("#cFFF263#{XYSB_20170620_036}");
		LoginSelectUpdateRect();

		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:SetText("关闭");
		SelectServerQuest_Button1:Enable()

		this:Show();
	end

	--
	if ( event == "UI_COMMAND" and tonumber(arg0) == 2014081322) then
		g_iYesNoType = -1;
		local cardstr = Get_XParam_STR(0)
		local strText = string.format("#{KFCS_140730_47}",cardstr)
		SelectServerQuest_InfoWindow:SetText(strText);
		LoginSelectUpdateRect();

		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button1:Enable()

		this:Show();
	end

	if( event == "UI_COMMAND" and tonumber(arg0) == 300077) then
		g_iYesNoType = 12;
		local slzExp = Get_XParam_INT( 0 )
		local levelCanUp = Get_XParam_INT( 1 )
		local petLevel = Get_XParam_INT( 2 )
		local toMaxLevel = Get_XParam_INT( 3 )
		local PetGuidH = Get_XParam_INT( 4 )
		local PetGuidL = Get_XParam_INT( 5 )
		g_bagIndex = Get_XParam_INT( 6 )
		local petClass = Pet:GetPetDBCName(PetGuidH,PetGuidL)

		if levelCanUp == 0 then
			local strText = string.format("#{SLZSDSJ_090915_2}%s#{SLZSDSJ_090915_3}%d#{SLZSDSJ_090915_4}",petClass,slzExp)
			SelectServerQuest_InfoWindow:SetText( strText );
		elseif levelCanUp > 0 then
			--升级界面不在这里，在PetShelizi_Msg中
			return
		end

		LoginSelectUpdateRect();

		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button2:SetText("取消");
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		this:Show();

	end

	--天元金丹 hzp
	if( event == "UI_COMMAND" and tonumber(arg0) == 332004) then
		g_iYesNoType = 13;
		g_bagIndex = Get_XParam_INT( 0 )
		SelectServerQuest_InfoWindow:SetText("#{TSXF_090408_03}");

		LoginSelectUpdateRect();

		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button2:SetText("取消");
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		this:Show();

	end

	--暗器升级
	if( event == "UI_COMMAND" and tonumber(arg0) == 260001) then
		g_iYesNoType = -1;
		g_bagIndex = Get_XParam_INT( 0 );
		g_bagIndex2 = Get_XParam_INT( 1 )
		SelectServerQuest_InfoWindow:SetText("#{AQSJ_090709_10}");

		LoginSelectUpdateRect();

		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		this:Show();

	end

	--神器升级
	if( event == "UI_COMMAND" and tonumber(arg0) == 500505) then
		g_iYesNoType = -1;
		g_bagIndex = Get_XParam_INT( 0 );
		g_bagIndex2 = Get_XParam_INT( 1 )
		SelectServerQuest_InfoWindow:SetText("#{SQSJ_0708_09}");

		LoginSelectUpdateRect();

		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		this:Show();
	end

	--新舍利子 add by hzp 09-06-29
	if( event == "UI_COMMAND" and tonumber(arg0) == 300088) then
		g_iYesNoType = 14;
		local slzExp = Get_XParam_INT( 0 )
		local levelCanUp = Get_XParam_INT( 1 )
		local petLevel = Get_XParam_INT( 2 )
		local toMaxLevel = Get_XParam_INT( 3 )
		local PetGuidH = Get_XParam_INT( 4 )
		local PetGuidL = Get_XParam_INT( 5 )
		g_bagIndex = Get_XParam_INT( 6 )
		local petClass = Pet:GetPetDBCName(PetGuidH,PetGuidL)

		if levelCanUp == 0 then
			local strText = string.format("#{ZSKSSJ_081113_19}%s#{ZSKSSJ_081113_20}%d#{ZSKSSJ_081113_21}%d#{ZSKSSJ_081113_22}",petClass,slzExp ,toMaxLevel)
			SelectServerQuest_InfoWindow:SetText( strText );
		elseif levelCanUp > 0 then
			local strText = string.format("#{ZSKSSJ_081113_19}%s#{ZSKSSJ_081113_20}%d#{ZSKSSJ_081113_28}%d#{ZSKSSJ_081113_29}%d#{ZSKSSJ_081113_30}%d#{ZSKSSJ_081113_22}",petClass,slzExp ,petLevel ,petLevel + levelCanUp ,toMaxLevel)
			SelectServerQuest_InfoWindow:SetText( strText );
		end

		LoginSelectUpdateRect();

		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button2:SetText("取消");
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		this:Show();

	end

	if( event == "UI_COMMAND" and tonumber(arg0) == 808147) then
		g_iYesNoType = 24;
		g_objCared = Get_XParam_INT(0)
		g_bagIndex = Get_XParam_INT(1)
		local itemName = Get_XParam_STR(0)
		local strText = string.format("#{MYHK_100128_03}%s#{MYHK_100128_04}",itemName)
		SelectServerQuest_InfoWindow:SetText( strText )

		LoginSelectUpdateRect();

		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button2:SetText("取消");
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		this:Show();

	end
	if( event == "UI_COMMAND" and tonumber(arg0) == 20110826) then
		g_iYesNoType = 28;
		g_objCared = Get_XParam_INT(0)
		SelectServerQuest_InfoWindow:SetText( "#{JYZD_KVK_110705_16}" )

		LoginSelectUpdateRect();

		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button2:SetText("取消");
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		this:Show();

	end

	-- 雕纹拆除确认 by lhx tt80366
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20101026) then
		g_iYesNoType = -1;
		SelectServerQuest_InfoWindow:SetText("#{CCDW_101026_01}");
		LoginSelectUpdateRect();

		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:SetText("关闭");
		SelectServerQuest_Button1:Enable()

		this:Show();
	end

	-- 帮会聚宝盆领双二次确认
	-- if ( event == "UI_COMMAND" and tonumber(arg0) == 890841) then
	-- 	g_iYesNoType = 45
	-- 	local strText=ScriptGlobal_Format("#{BHCJ_140523_185}", tostring(Get_XParam_INT(0)) )
	-- 	SelectServerQuest_InfoWindow:SetText( strText )
	-- 	LoginSelectUpdateRect()

	-- 	SelectServerQuest_Button1:SetText("#{BHCJ_140523_183}")
	-- 	SelectServerQuest_Button2:SetText("#{BHCJ_140523_184}")
	-- 	SelectServerQuest_Button1:Enable()
	-- 	SelectServerQuest_Button2:Enable()
	-- 	SelectServerQuest_Button1:Show()
	-- 	SelectServerQuest_Button2:Show()
	-- 	this:Show()
	-- end

	-- 帮会聚宝盆补领双二次确认
	-- if ( event == "UI_COMMAND" and tonumber(arg0) == 20141121) then
	-- 	g_iYesNoType = 54
	-- 	g_TargetID = Get_XParam_INT(0)
	-- 	g_TypeFlag = Get_XParam_INT(1)
	-- 	local strText = Get_XParam_STR(0) --ScriptGlobal_Format("#{DSKQ_141110_70}", tostring(Get_XParam_INT(0)) )
	-- 	SelectServerQuest_InfoWindow:SetText( strText )
	-- 	LoginSelectUpdateRect()

	-- 	SelectServerQuest_Button1:SetText("#{BHCJ_140523_183}")
	-- 	SelectServerQuest_Button2:SetText("#{BHCJ_140523_184}")
	-- 	SelectServerQuest_Button1:Enable()
	-- 	SelectServerQuest_Button2:Enable()
	-- 	SelectServerQuest_Button1:Show()
	-- 	SelectServerQuest_Button2:Show()
	-- 	this:Show()
	-- end

	if (event == "PET_EQUIP_DEPART_CONFIRM") then
		--local equipname = arg0
		--SelectServerQuest_InfoWindow:SetText("#{ZSZBSJ_XML_17}" .. equipname .. "#{ZSZBSJ_XML_18}")
		SelectServerQuest_InfoWindow:SetText(arg0)
		g_iYesNoType = tonumber(arg1)
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button2:SetText("取消");
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		this:Show();
	end

	if (event == "BINDYUANBAO_NOTENOUGH_YESNO" ) then
		g_iYesNoType = tonumber(arg0)
		g_item 		 = tonumber(arg1)
		g_itemNum 	 = tonumber(arg2)
		local nNeedBindYuanbao = tonumber(arg3)
		g_pos = tonumber(arg4)
		local name = arg6
		local nHaveBindYuanbao = Player : GetData( "BIND_YUANBAO" )
		local nCostYuanbao = nNeedBindYuanbao - nHaveBindYuanbao
		--确定你是否购买这个东西 .. g_itemNum.."#{ZSZBSJ_XML_17}"
		SelectServerQuest_InfoWindow:SetText("#{BDYB_XML_1}#G" ..name .."#{BDYB_XML_2}#G"..nNeedBindYuanbao.."#{BDYB_XML_3}#G"..nHaveBindYuanbao.."#{BDYB_XML_4}#G"..nCostYuanbao.."#{BDYB_XML_5}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button2:SetText("取消");
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		this:Show();
	end

	if (event == "DISPLACEGEM_CONFIRM") then
		g_iYesNoType = tonumber(arg0)
		--g_equipSrc = tonumber(arg1)
		--g_equipDst = tonumber(arg2)
		--g_equipFu = tonumber(arg3)
		--SelectServerQuest_Frame_sub:SetProperty( "UnifiedPosition", "{{0.500000,-173.000000},{0.500000,-118.000000}}" )
		SelectServerQuest_Frame_sub:SetProperty( "UnifiedSize", "{{0.000000,346.000000},{0.000000,128.000000}}" )
		local infotype = tonumber(arg1);
		if infotype == 1 then
			SelectServerQuest_InfoWindow:SetText("#{CLJY_120813_04}");
		else
			SelectServerQuest_InfoWindow:SetText("#{BSQKY_20110506_22}");
		end
		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_1173}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		this:Show();
	end
	-- Start: Add By YPL, 宝石转换
	if (event == "BAOSHI_CHANGE_CONFIRM") then
		g_iYesNoType = 39
		SelectServerQuest_Frame_sub:SetProperty( "UnifiedSize", "{{0.000000,346.000000},{0.000000,128.000000}}" )
		local strText=ScriptGlobal_Format("#{BSZH_130220_21}",tostring(arg0),tostring(arg1),tostring(arg2))
		SelectServerQuest_InfoWindow:SetText(strText);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{BSZH_130220_12}");
		--SelectServerQuest_Button2:SetText("#{BSZH_130220_13}");
		--SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		this:Show();
	end
	-- End: Add By YPL, 宝石转换
	if (event == "DISPLACE_CLOSE_MSGBOX") then
		g_iYesNoType = -1
		--g_equipSrc = -1
		--g_equipDst = -1
		--g_equipFu = -1
		this:Hide();
	end
	if (event=="PNEUMA_CUIJIE_CONFIRM") then
		local bHaveMission = Pneuma:IsMissionAcc(1603)
		local bHaveDone =Pneuma:IsHaveMissionComplete(1603)
		if bHaveMission <= 0 and bHaveDone <= 0 then
			PushDebugMessage( "#{ZYRW_120522_20}" )
			if IsWindowShow("ZhenYuan") then
				CloseWindow("ZhenYuan")
			end
			return
		end
		g_iYesNoType=32
		g_PneumaSmeltBag_Pos=tonumber(arg0)
		local szName,level,szDes,smeltGetExp=Pneuma:GetPneumaCuiJieInfo(g_PneumaSmeltBag_Pos)
		local addtype = Pneuma:GetPneumaProperty( g_PneumaSmeltBag_Pos, 3 )
		local quality = Pneuma:GetPneumaProperty( g_PneumaSmeltBag_Pos, 2 )
		if name=="" or level==-1 or szDes=="" or smeltGetExp==-1 or quality<=0 then
			return
		end

		if quality == 6 then	--金色真元
			--:PushDebugMessage("#{ZYFL_180718_23}")
			--:return
            if addtype < 50 then
				SelectServerQuest_InfoWindow:SetText( ScriptGlobal_Format("#{CYZJ_150212_27}",szName,level,szDes,smeltGetExp) )
			elseif addtype > 50 then
				SelectServerQuest_InfoWindow:SetText( ScriptGlobal_Format("#{CYZJ_150212_28}",szName,level,szDes,smeltGetExp) )
			end
		else
			if addtype < 50 then
				SelectServerQuest_InfoWindow:SetText( ScriptGlobal_Format("#{ZYXT_120528_87}",szName,level,szDes,smeltGetExp) )
			elseif addtype > 50 then
				SelectServerQuest_InfoWindow:SetText( ScriptGlobal_Format("#{ZYZH_140618_30}",szName,level,szDes,smeltGetExp) )
			end
		end

		SelectServerQuest_Frame_sub:SetProperty( "UnifiedSize", "{{0.000000,346.000000},{0.000000,168.000000}}" )

		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}");--确定
		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}");--取消
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		this:Show();
	elseif (event=="PNEUMA_CUIJIEALL_CONFIRM") then
		g_iYesNoType=33
		local nGetExp=Pneuma:GetExp_IfSmeltAll()
		local strText=ScriptGlobal_Format( "#{ZYXT_120528_94}", nGetExp)
		SelectServerQuest_InfoWindow:SetText( strText )
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}");--确定
		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}");--取消
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		this:Show();
--	elseif (event=="PNEUMA_CUIJIE_CONFIRM_MAX") then
--		g_iYesNoType=34
--		g_PneumaSmeltBag_Pos34=tonumber(arg0)
--		local strText="#{ZYXT_120528_91}"--淬解本真元后，你拥有的元晶数量将超过上限，超过上限的元晶将会损失，你是否继续淬解，如果继续请确定，放弃淬解请取消。
--		SelectServerQuest_InfoWindow:SetText( strText )
--		LoginSelectUpdateRect()
--		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}");--确定
--		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}");--取消
--		SelectServerQuest_Button2:Show();
--		SelectServerQuest_Button1:Show();
--		SelectServerQuest_Button1:Enable()
--		this:Show();
--	elseif (event=="PNEUMA_CUIJIEALL_CONFIRM_MAX") then
--		g_iYesNoType=35
--		local strText="#{ZYXT_120528_215}"
--		SelectServerQuest_InfoWindow:SetText( strText )
--		LoginSelectUpdateRect()
--		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}");--确定
--		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}");--取消
--		SelectServerQuest_Button2:Show();
--		SelectServerQuest_Button1:Show();
--		SelectServerQuest_Button1:Enable()
--		this:Show();
	elseif (event=="NINGLAINALL_CUIJIECONFIRM") then
		g_iYesNoType=36
		g_PneumaSmeltBag_Pos36=tonumber(arg0)
		if g_PneumaSmeltBag_Pos36<1 or g_PneumaSmeltBag_Pos36>3 then
			return
		end
		local strCuiJie={"#{ZYXT_120528_207}","#{ZYXT_120528_208}","#{ZYXT_120528_209}","#{ZYXT_120528_210}"}
		local strText=ScriptGlobal_Format( "#{ZYXT_120528_212}", strCuiJie[g_PneumaSmeltBag_Pos36])
		SelectServerQuest_InfoWindow:SetText( strText )
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}");--确定
		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}");--取消
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		this:Show();
	elseif (event=="BUDGETPLANINFO_DOWNPAY") then
		g_iYesNoType=42
		g_DownPayIndex = tonumber(arg0)
		local nGemID = tonumber(arg1)
		local DownPayPrice = tonumber(arg2)
		if g_DownPayIndex<1 or g_DownPayIndex>5 then
			return
		end
		local GemName = DoubleGem:GetGemNamebyID(nGemID)
		--为了显示这个时间。。。。。。
		local nServerTime = DataPool:GetServerDayTime()
		local	nServerDayTime = DataPool:DateTime2DayTime(nServerTime) + 30
		if math.mod(nServerDayTime,1000)>365 then
			nServerDayTime = (nServerDayTime/1000 + 1)*1000 + (math.mod(nServerDayTime,1000)-365)
		end
		local year,month,day = BudgetPlanGem:BudgetPlanGemDayTimeToYMD(nServerDayTime)
		local	strYMD = year.."年"..month.."月"..day.."日"
		local strText=ScriptGlobal_Format( "#{FQBS_140508_42}",GemName,DownPayPrice, strYMD)
		SelectServerQuest_InfoWindow:SetText( strText )
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}");--确定
		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}");--取消
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		this:Show();
	elseif (event=="BUDGETPLANINFO_REPAY") then
		g_iYesNoType=43
		g_RePayIndex=tonumber(arg0)
		local nGemID = tonumber(arg1)
		local nPayingYuanBao = tonumber(arg2)
		local nSelcetStage = tonumber(arg3)
		local nPayingDueTime = tonumber(arg4)
		local nCompleteGem = tonumber(arg5)
		local nStage = tonumber(arg6)
		local strText =""
		if g_RePayIndex<0 or g_RePayIndex>4 then
			return
		end

		local GemName = DoubleGem:GetGemNamebyID(nGemID)
		if nStage == 100 then
			local CompleteGemName = DoubleGem:GetGemNamebyID(nCompleteGem)
			strText=ScriptGlobal_Format( "#{FQBS_140508_50}", GemName,nPayingYuanBao,nSelcetStage)
		else
			local year,month,day = BudgetPlanGem:BudgetPlanGemDayTimeToYMD(nPayingDueTime)
			local	strYMD = year.."年"..month.."月"..day.."日"
			strText=ScriptGlobal_Format( "#{FQBS_140508_49}", GemName,nPayingYuanBao,nSelcetStage,strYMD)
		end
		SelectServerQuest_InfoWindow:SetText( strText )
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}");--确定
		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}");--取消
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button1:Enable()
		this:Show();
	end


    if ( event == "UI_COMMAND" and tonumber(arg0) == 2012081302 ) then
        local param = Get_XParam_INT(0)
        if param ~= nil and tonumber( param ) == 1 then
            g_iYesNoType = 37;
    		SelectServerQuest_InfoWindow:SetText("#{WBSS_120727_91}");
	    	LoginSelectUpdateRect();

		    SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}");--确定
    		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}");--取消
	    	SelectServerQuest_Button2:Show();
		    SelectServerQuest_Button1:Show();

    		this:Show();
        end

	end

	if( event == "UI_COMMAND" and tonumber(arg0) == 889967) then
		g_iYesNoType = 38;
		local slzItemJinJieLvl = Get_XParam_INT( 0 )
		local PetGuidH = Get_XParam_INT( 1 )
		local PetGuidL = Get_XParam_INT( 2 )
		g_bagIndex = Get_XParam_INT( 3 )
		local nNeedXueRongDan = Get_XParam_INT( 4 )
		local petClass = Pet:GetPetDBCName(PetGuidH,PetGuidL)
		local g_JinJieLvlPerGrade = 10
		local nGrade = Division(slzItemJinJieLvl, 256*256)
		local nCurLevel = slzItemJinJieLvl - Lua_Multiply(nGrade, 256*256)
		local strText = ScriptGlobal_Format("#{JJKHD_120808_58}",petClass, tostring(nGrade), tostring(nCurLevel), tostring(nNeedXueRongDan) )
		SelectServerQuest_InfoWindow:SetText( strText );

		LoginSelectUpdateRect();

		SelectServerQuest_Button1:SetText("确定");
		SelectServerQuest_Button2:SetText("取消");
		SelectServerQuest_Button2:Show();
		SelectServerQuest_Button1:Show();
		this:Show();

	end

	if (event == "CREATECHAR_CLOSE_RENAME_NOTE") then
		SelectServerQuest_Bn1Click();
		CreateChar_RenameNote_Ret();
	end

--~ 	if (event == "PET_EQUIP_SUITUP_CONFIRM") then
--~ 		g_iYesNoType = tonumber(arg0)
--~ 		g_pos 		 = tonumber(arg1)
--~ 		g_itemNum	 = tonumber(arg2)
--~ 		g_percent	 = tonumber(arg3)
--~ 		g_objCared	 = tonumber(arg4)
--~ 		--需要换字典号（暂时使用自己配置的）
--~ 		if (g_percent == 100) then
--~ 			SelectServerQuest_InfoWindow:SetText("#{ZSZB_SJ_01}" ..g_itemNum .."#{ZSZB_SJ_02}"..g_percent.."%#{ZSZB_SJ_03}#G")
--~ 		else
--~ 			SelectServerQuest_InfoWindow:SetText("#{ZSZB_SJ_01}" ..g_itemNum .."#{ZSZB_SJ_02}#cff0000"..g_percent.."%#{ZSZB_SJ_03}#G")
--~ 		end

--~ 		LoginSelectUpdateRect()
--~ 		SelectServerQuest_Button1:SetText("确定")
--~ 		SelectServerQuest_Button2:SetText("取消")
--~ 		SelectServerQuest_Button2:Show()
--~ 		SelectServerQuest_Button1:Show()
--~ 		this:Show()
--~ 	end

	if ( event == "DRESSPAINT_SELECTSERVER" ) then
		g_iYesNoType = -1;
		local strDressPaint = ScriptGlobal_Format("#{SZRSYH_120912_20}",tostring(arg0))
		SelectServerQuest_InfoWindow:SetText(strDressPaint);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{FTHS_120719_79}");
		this:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:Hide();
		return;
	end

	if ( event == "BIEYE_PETCOLOR_CONFIRM" ) then
		g_iYesNoType = -1;
		local strDressPaint = ScriptGlobal_Format("#{MCFZ_20170807_95}",tostring(arg0))
		SelectServerQuest_InfoWindow:SetText(strDressPaint);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{FTHS_120719_79}");
		this:Show();
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:Hide();
		return;
	end


	--shitu mission by yuanpeilong 201505
	if ( event == "UI_COMMAND" and tonumber(arg0) == 891143) then
			g_iYesNoType = 59
			SelectServerQuest_Frame_sub:SetProperty( "UnifiedSize", "{{0.000000,346.000000},{0.000000,128.000000}}" )
			SelectServerQuest_InfoWindow:SetText(Get_XParam_STR(0));
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{LDCL_100508_14}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{LDCL_100508_15}");
			SelectServerQuest_Button2:Show();
			this:Show();
	end

	if ( event == "DRESSPAINT_BINDDRESS" ) then
		g_iYesNoType = 44;
		--SelectServerQuest_InfoWindow:SetText("#{RSBD_140704_06}");
		local Str = ScriptGlobal_Format("#{XRSDJ220715_05}", DataPool:Lua_GetItemNameByIndex(tonumber(arg0)))
		SelectServerQuest_InfoWindow:SetText(Str);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{LDCL_100508_14}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{LDCL_100508_15}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return;
	end

	if event == "INFANTDRESSPAINT_BIND_CONFIRM" then
		g_iYesNoType = 52
		SelectServerQuest_InfoWindow:SetText("#{ZNSZ_140718_147}")
		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{BHFB_140731_15}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button2:SetText("#{BHFB_140731_16}")
		SelectServerQuest_Button2:Show()
		this:Show()
	end

	if ( event == "INFANT_CARD_STEPUP_CONFIRM" ) then
		g_iYesNoType = 46;
		g_card_stepup_bagindex=tonumber(arg0)
		local ncard_level = tonumber(arg1)
		local ncard_yuanbao = tonumber(arg2)
		local ncard_name = PlayerPackage:GetBagItemName(g_card_stepup_bagindex)
		local strText=ScriptGlobal_Format("#{ZSJX_140707_07}",ncard_name,ncard_level,ncard_yuanbao)
		SelectServerQuest_InfoWindow:SetText(strText);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{LDCL_100508_14}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{LDCL_100508_15}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return;
	end


		-- 血浴神兵——神器铸造
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20141021) then

		g_iYesNoType 		= 53;
		g_TargetID 			= Get_XParam_INT( 0 )
		g_CostNum				= Get_XParam_INT( 1)
		g_ChengZhangZhi	= Get_XParam_INT( 2 )

		SelectServerQuest_InfoWindow:SetText("#{BHZQ_140820_29}")
		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{BHFB_140731_15}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button2:SetText("#{BHFB_140731_16}")
		SelectServerQuest_Button2:Show()
		this:Show()
	end

	--2015老三环副本玩法优化 By yuanpeilong
	if ( event == "UI_COMMAND" and tonumber(arg0) == 891075) then
		g_iYesNoType = 56
		g_objCared = Get_XParam_INT(0)
		SelectServerQuest_InfoWindow:SetText("#{LSHYH_150210_79}");
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{BHFB_140731_15}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018清明节
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89272104) then
		g_iYesNoType = 84
		g_objCared = Get_XParam_INT(0)
		local num = Get_XParam_INT(1);
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{QMQT_180309_51}",num,name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180401) then
		g_iYesNoType = 85
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180402) then
		g_iYesNoType = 86
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180403) then
		g_iYesNoType = 87
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180404) then
		g_iYesNoType = 88
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180405) then
		g_iYesNoType = 89
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180406) then
		g_iYesNoType = 90
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180412) then
		g_iYesNoType = 91
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180408) then
		g_iYesNoType = 92
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180409) then
		g_iYesNoType = 93
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180410) then
		g_iYesNoType = 94
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2018周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20180411) then
		g_iYesNoType = 95
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--执手共御
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88876901) then
		g_iYesNoType = 130
		g_bagIndex = Get_XParam_INT(0);
		SelectServerQuest_InfoWindow:SetText("#{XJH_210826_38}");
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{XJH_210826_39}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{XJH_210826_40}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--金枫祈愿
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89288501) then
		g_iYesNoType = 97
		g_bagIndex = Get_XParam_INT(0);
		SelectServerQuest_InfoWindow:SetText("#{JFLZ_180806_35}");
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{JFLZ_180806_75}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{JFLZ_180806_76}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	-- 确认结婚日期 by wangbin
	if ( event == "UI_COMMAND" and tonumber(arg0) == 2015061001) then
		local iType = Get_XParam_INT(0);
		local nResult = Get_XParam_INT(1);
		local nType = Get_XParam_INT(2);

		if(0 == iType) then														--结婚日期的设定,等待对方确认
			if(2 == nType) then													--修改结婚确定按钮为等待对方确认
				ZhanTuanInterface:SetMarryDateWaitConfirm(0);					-- 修改结婚确定按钮
			else																--结婚日期的设定,等待对方确认
				g_iYesNoType = 58
				g_iWeddingDay = Get_XParam_INT(1)
				local year = math.floor(g_iWeddingDay/1000000)+2000;
				local month = math.floor(math.mod(g_iWeddingDay,1000000)/10000);
				local day = math.floor(math.mod(g_iWeddingDay,10000)/100);
				local msg = ScriptGlobal_Format("#{HYGX_150515_20}", tostring(year), tostring(month), tostring(day));
				SelectServerQuest_InfoWindow:SetText(msg);
				LoginSelectUpdateRect();
				SelectServerQuest_Button1:SetText("#{BHFB_140731_15}");
				SelectServerQuest_Button1:Show();
				SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
				SelectServerQuest_Button2:Show();
				this:Show();
			end
		elseif(1 == iType) then													--结婚日期的设定确认后结果
			ZhanTuanInterface:SetMarryDateWaitConfirm(1);						-- 修改结婚确定按钮
			if(1 == nResult) then												--确认结婚日期的设定
				PushDebugMessage("#{HYGX_150515_26}");
			elseif(0 == nResult) then											-- 取消结婚日期的设定
				local str = "#{HYGX_150515_28}";
				if(0 == nType) then												--取消结婚日期的设定,1给自己,0给对方
					str = "#{HYGX_150515_29}";
				end
				PushDebugMessage(str);
			end
		elseif(2 == iType) then
			this:Hide();
		end
		return
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 20160620) then
		local nType =  Get_XParam_INT( 0 )
		if nType == 2 then
			nItemIndex = Get_XParam_INT( 1 )
			local szItemName = DataPool:Lua_GetItemNameByIndex(nItemIndex)
			g_iYesNoType = 62
			g_FurnitureType =  Get_XParam_INT( 2 )
			g_FurnitureLevel=  Get_XParam_INT( 3 )
			g_FurniturePos =   Get_XParam_INT( 4 )
			SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{JJHC_160620_48}",szItemName));
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif nType == 3 then
			g_iYesNoType = 63
			SelectServerQuest_InfoWindow:SetText("#{JJHC_160620_51}");
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif nType == 4 then
			g_iYesNoType = 64
			g_FurnitureType =  Get_XParam_INT( 1 )
			g_FurnitureLevel=  Get_XParam_INT( 2 )
			g_FurniturePos =   Get_XParam_INT( 3 )
			local szNeedMBFName = Get_XParam_STR(0)
			SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{JJHC_160620_54}",szNeedMBFName));
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif nType == 5 then   --购买装潢符确认
			g_iYesNoType = 65
			SelectServerQuest_InfoWindow:SetText("#{JJHC_160620_89}");
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif nType == 6 then

			g_iYesNoType = 66
			g_ItemBagIDXiYou = Get_XParam_INT( 1 )
			g_ItemBagID =  Get_XParam_INT( 2 )
			g_ItemBagIDBind =  Get_XParam_INT( 3 )

			SelectServerQuest_InfoWindow:SetText("#{JJHC_160620_93}");
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif nType == 7 then --别墅家具 合成 二次确认
			g_iYesNoType = 67
			g_FurnitureDelItemID = Get_XParam_INT( 1 )

			g_FurnitureType =  Get_XParam_INT( 2 )
			g_FurnitureLevel=  Get_XParam_INT( 3 )
			g_FurniturePos =   Get_XParam_INT( 4 )
			local szNeedMBFName = Get_XParam_STR(0)

			SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{JJHC_160620_54}",szNeedMBFName));

			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif nType == 8 then   --购买装潢符确认
			g_iYesNoType = 68
			SelectServerQuest_InfoWindow:SetText("#{JJHC_160620_89}");
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif nType == 9 then   --购买装潢符确认
			g_iYesNoType = 69
			g_ItemBagIDXiYou = Get_XParam_INT( 1 )
			g_ItemBagID =  Get_XParam_INT( 2 )
			g_ItemBagIDBind =  Get_XParam_INT( 3 )

			local nName =  BieYeFurniture:GetFurNameByFurnitureID(g_ItemBagIDBind)
			SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{JJHC_160620_130}",nName));
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif nType == 10 then   --购买装潢符确认
			g_iYesNoType = 72
			local nAllNum =  Get_XParam_INT( 1 )
			local szNameDel = Get_XParam_STR(0)
			local szNameAdd = Get_XParam_STR(1)
			local nNeedMoney =  Get_XParam_INT( 2 )
			local nNum =  Get_XParam_INT( 3 )

			local bOdd = math.mod(nAllNum,2);
			if bOdd  == 1 then
				nAllNum= nAllNum -1
			end


			g_FurnitureType =  Get_XParam_INT( 4 )
			g_FurnitureLevel=  Get_XParam_INT( 5 )
			g_FurniturePos =   Get_XParam_INT( 6 )


			SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{JJHC_160620_200}",nAllNum,szNameDel,szNameAdd,nNeedMoney,nNum,szNameAdd));
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif nType == 11 then   --购买装潢符确认
			g_iYesNoType = 73
			local nAllNum =  Get_XParam_INT( 1 )
			local szNameDel = Get_XParam_STR(0)
			local szNameAdd = Get_XParam_STR(1)
			local nNeedMoney =  Get_XParam_INT( 2 )
			local nNum =  Get_XParam_INT( 3 )

			g_FurnitureType =  Get_XParam_INT( 4 )
			g_FurnitureLevel=  Get_XParam_INT( 5 )
			g_FurniturePos =   Get_XParam_INT( 6 )

			local bOdd = math.mod(nAllNum,2);
			if bOdd  == 1 then
				nAllNum= nAllNum -1
			end


			if g_FurniturePos ==  0 then
				SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{JJHC_160620_203}",nAllNum,szNameDel,szNameAdd,nNeedMoney,nNum,szNameAdd));
			else
				SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{JJHC_160620_202}",nAllNum,szNameDel,szNameAdd,nNeedMoney,nNum,szNameAdd));
			end

			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{SQSX_120806_73}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		elseif(nType == 12) then --家具转换符购买确认
			g_iYesNoType = 75
			SelectServerQuest_InfoWindow:SetText("#{XYJJ_170216_26}");
			LoginSelectUpdateRect();
			SelectServerQuest_Button1:SetText("#{XYJJ_170216_27}");
			SelectServerQuest_Button1:Show();
			SelectServerQuest_Button2:SetText("#{XYJJ_170216_16}");
			SelectServerQuest_Button2:Show();
			this:Show();
		end
		return
	end

	--新神器升级，86级神器二次确认框 by lishilong 2016-9-29
	if( event == "UI_COMMAND" and tonumber(arg0) == 2016092990) then
		g_iYesNoType = 70
		local strItemNameA = Get_XParam_STR(0)
		local strItemNameB = Get_XParam_STR(1)
		local strText = ScriptGlobal_Format("#{XSQSJ_160812_35}", strItemNameA, strItemNameB)
		SelectServerQuest_InfoWindow:SetText(strText)

		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}") -- 确定
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}") -- 取消
	    SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end

	--新神器升级，42级神器带刻铭二次确认框 by lishilong 2016-9-29
	if( event == "UI_COMMAND" and tonumber(arg0) == 2016092991) then
		g_iYesNoType = 71
		local strItemNameA	 = Get_XParam_STR(0)
		local strItemNameB 	= Get_XParam_STR(1)
		local nNewLevel 	= Get_XParam_INT(0)
		local strText = ScriptGlobal_Format("#{XSQSJ_160812_36}", strItemNameA, nNewLevel, strItemNameB)
		SelectServerQuest_InfoWindow:SetText(strText)

		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}") -- 确定
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}") -- 取消
	    SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 201701041) then
		g_iYesNoType = 74
		g_ExchangeIndex = Get_XParam_INT(0)
		local ItemId = Get_XParam_INT(1)
		local NeedNum = Get_XParam_INT(2)
		local strText = ""
		if ItemId == 50313004 then
			strText = "#{JJXH_161122_151}"
		else
			local ItemName = DataPool:Lua_GetItemNameByIndex(ItemId)
			strText = ScriptGlobal_Format("#{JJXH_161122_135}", NeedNum, ItemName)
		end
		SelectServerQuest_InfoWindow:SetText(strText)
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{BHFB_140731_15}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{BHFB_140731_16}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89272801) then
		g_iYesNoType = 83
		SelectServerQuest_InfoWindow:SetText("#{QMZJ_180308_114}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{QMZJ_180308_46}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMZJ_180308_47}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	if event == "BIEYE_RESERVE_TYPE_CONFIRM" then
		if not arg1 then
			return
		end
		g_iYesNoType = 76
		g_tmpData = {
			objid=arg0,
			objname=arg1
		}
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{BYFUR_170410_317}",arg1))
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}") -- 确定
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}") -- 取消
	    SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
		return
	end

	if event  == "UI_COMMAND" and tonumber(arg0) == 89187702 then
		g_iYesNoType = 77
		g_tmpData = {
			targetId=Get_XParam_INT(0)
		}
		SelectServerQuest_InfoWindow:SetText("#{BYRACE_170214_48}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{INTERFACE_XML_557}") -- 确定
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{INTERFACE_XML_542}") -- 取消
	    SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
		return
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 201704266) then
		SelectServerQuest_HappyTLTenYears(Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2))
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 201706226) then
		SelectServerQuest_JiuJiuXiaoHan_Summer(Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2))
	end

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88897106) then
		SelectServerQuest_JiuJiuXiaoHan_Spring(Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2))
	end
	
	if ( event == "UI_COMMAND" and tonumber(arg0) == 201707211) then
		SelectServerQuest_HuoyueWeeklyGift(Get_XParam_INT(0))
	end
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89290406) then
		local nType =  Get_XParam_INT( 0 )
		if nType == 1 then
			g_iYesNoType = 98
			SelectServerQuest_InfoWindow:SetText("#{QLGCJ_180810_83}")
		elseif nType == 2 then
			g_iYesNoType = 99
			SelectServerQuest_InfoWindow:SetText("#{QLGCJ_180810_84}")
		elseif nType == 3 then
			g_iYesNoType = 100
			SelectServerQuest_InfoWindow:SetText("#{QLGCJ_180810_85}")
		else
			g_iYesNoType = 101
			SelectServerQuest_InfoWindow:SetText("#{QLGCJ_180810_105}")
		end
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{QLGCJ_180810_87}") -- 确定
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{QLGCJ_180810_88}") -- 取消
	    SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89298005) then
		g_iYesNoType = 102
		local nIndex =  Get_XParam_INT( 0 )
		g_CaiQiu_TargetID = Get_XParam_INT( 1 )
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{KWCQ_181201_37}", nIndex))
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{KWCQ_181201_81}") -- 确定
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{KWCQ_181201_82}") -- 取消
	    SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end

	--春节微信红包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89298401) then

		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			if this:IsVisible() then
				this:Hide();
			end

			local nOpType = Get_XParam_INT(1)
			local szMsg = Get_XParam_STR(0)
			SelectServerQuest_InfoWindow:SetText( szMsg )

			LoginSelectUpdateRect()

			--成功，成功的话点确定按钮，会打开红包界面
			if nOpType == 1 then
				g_iYesNoType = 103
			else
				g_iYesNoType = 104
			end

			--如果仅是显示进度，则显示倒计时
			if nOpType == 0 then
				SelectServerQuest_Time_Text : SetProperty("Timer",tostring(20));
		    SelectServerQuest_Time_Text : Show()
		    TimerArg = arg0;
		  else
		  	SelectServerQuest_Time_Text : Hide()
			end

			if nOpType > 0 then
				SelectServerQuest_Button1:SetText("#{CJHB_181207_32}");
				SelectServerQuest_Button1:Show();
			else
				SelectServerQuest_Button1:Hide();
			end

			SelectServerQuest_Button2:Hide();
			this:Show();
		else
			this:Hide();
		end
		return
	end

	-- 周年庆预热访仙活动
	if ( event == "UI_COMMAND" and tonumber(arg0) == 920190320) then

		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			if this:IsVisible() then
				this:Hide();
			end

			local nOpType = Get_XParam_INT(1)
			local nTimeOut = Get_XParam_INT(2)
			local szMsg = Get_XParam_STR(0)
			SelectServerQuest_InfoWindow:SetText( szMsg )

			LoginSelectUpdateRect()

			--成功，成功的话点确定按钮，暂时不会打开界面
			-- if nOpType == 1 then
			-- 	g_iYesNoType = 103
			-- else
			-- 	g_iYesNoType = 104
			-- end

			--如果仅是显示进度，则显示倒计时
			if nOpType == 0 then
				SelectServerQuest_Time_Text : SetProperty("Timer", tostring(nTimeOut));
				SelectServerQuest_Time_Text : Show()
				TimerArg = arg0;
			else
		  		SelectServerQuest_Time_Text : Hide()
			end

			if nOpType > 0 then
				SelectServerQuest_Button1:SetText("#{ZNTZ_190318_20}");
				SelectServerQuest_Button1:Show();
			else
				SelectServerQuest_Button1:Hide();
			end

			SelectServerQuest_Button2:Hide();
			this:Show();
		else
			this:Hide();
		end
		return
	end

	--春节
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89302902) then
		GameProduceLogin:OpenURL(GetWeblink("WEB_2019WXHD"))
		return
	end
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89298007) then
		g_iYesNoType = -1
		local nIndex =  Get_XParam_INT( 0 )
		if nIndex == 5 then
			SelectServerQuest_InfoWindow:SetText("#{KWCQ_181201_60}")
			SelectServerQuest_Button1:SetText("#{KWCQ_181201_61}") -- 确定
		elseif nIndex == 10 then
			SelectServerQuest_InfoWindow:SetText("#{KWCQ_181201_63}")
			SelectServerQuest_Button1:SetText("#{KWCQ_181201_64}") -- 确定
		elseif nIndex == 20 then
			SelectServerQuest_InfoWindow:SetText("#{KWCQ_181201_66}")
			SelectServerQuest_Button1:SetText("#{KWCQ_181201_67}") -- 确定
		else
			SelectServerQuest_Button1:SetText("Error:89298007") -- 确定
		end
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
	    SelectServerQuest_Button2:Hide()
		this:Show()
	end


	--周年庆副本预热
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89306502) then

		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			if this:IsVisible() then
				this:Hide();
			end

			local nOpType = Get_XParam_INT(1)
			local szMsg = Get_XParam_STR(0)
			g_tmpData[1] = Get_XParam_INT(2)
			SelectServerQuest_InfoWindow:SetText( szMsg )

			LoginSelectUpdateRect()

			--成功，成功的话点确定按钮，会打开红包界面
			if nOpType == 0 then  --开始倒计时
				g_iYesNoType = 105
			end
			--如果仅是显示进度，则显示倒计时
			if nOpType == 0 then
				SelectServerQuest_Time_Text : SetProperty("Timer",tostring(20));
		   		SelectServerQuest_Time_Text : Show()
		    	TimerArg = arg0;
		    else
		  		SelectServerQuest_Time_Text : Hide()
			end

			if nOpType > 0 then
				SelectServerQuest_Button1:SetText("#{CJHB_181207_32}");
				SelectServerQuest_Button1:Show();
			else
				SelectServerQuest_Button1:Hide();
			end

			SelectServerQuest_Button2:Hide();
			this:Show();
		else
			this:Hide();
		end
		return
	end

	--周年庆副本预热
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89306503) then

		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			if not this:IsVisible() then
				return
			end

			local nOpType = Get_XParam_INT(1)
			local szMsg 	 = Get_XParam_STR(0)
			g_tmpData[1]  = Get_XParam_INT(2)
			g_tmpData[2]  = Get_XParam_INT(4)
			SelectServerQuest_InfoWindow:SetText( szMsg )

			LoginSelectUpdateRect()

			--成功，成功的话点确定按钮，会打开红包界面
			if nOpType == 1 then --绑定微信 成功
				g_iYesNoType = 106
			elseif nOpType == 2 then--未绑定微信成功
				g_iYesNoType = 107
			elseif nOpType == 3 then--失败
				g_iYesNoType = 108
			else
				return
			end

		    TimerArg = arg0;
		  	SelectServerQuest_Time_Text : Hide()

			if nOpType > 0 then
				SelectServerQuest_Button1:SetText("#{CJHB_181207_32}");
				SelectServerQuest_Button1:Show();
			else
				SelectServerQuest_Button1:Hide();
			end

			SelectServerQuest_Button2:Hide();
			this:Show();
		else
			this:Hide();
		end
		return
	end

	--2019周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89307701) then
		g_iYesNoType = 109
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--周年庆副本预热
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89306507) then

		if this:IsVisible() then
			this:Hide();
		end
	end
	
	--2020周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 89340701) then
		g_iYesNoType = 111
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end
	if ( event == "FEIYUDRESS_PAINT_EXPSURE" ) then
		g_iYesNoType = 115;
		SelectServerQuest_InfoWindow:SetText(tostring(arg0));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{LDCL_100508_14}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{LDCL_100508_15}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return;
	elseif ( event == "FEIYUDRESS_PAINT_BINDSURE" ) then
		g_iYesNoType = 116;
		g_tmpData[1] = tonumber(arg0)
		g_tmpData[2] = tonumber(arg1)
		g_tmpData[3] = tonumber(arg2)
		SelectServerQuest_InfoWindow:SetText("#{FYYR_200610_29}");
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{LDCL_100508_14}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{LDCL_100508_15}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return;
	end
	--2020T300预热-1127整合奖励
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88822801) then
		g_iYesNoType = 117
		local nNum = Get_XParam_INT(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{TWYR_200908_104}",nNum));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{TWYR_200908_105}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{TWYR_200908_106}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end
	--2020T300预热-汴京八景补绘制
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88822802) then
		g_iYesNoType = 118
		SelectServerQuest_InfoWindow:SetText("#{TWYR_200908_118}");
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{TWYR_200908_119}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{TWYR_200908_120}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end
	--2020T300预热-汴京30分钟点卡
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88825201) then
		g_iYesNoType = 119
		g_tmpData[1] = Get_XParam_INT(0)
		-- 背包格子蒙红锁定
		-- LifeAbility : Lock_Packet_Item( g_tmpData[1], 1 )
		SelectServerQuest_InfoWindow:SetText("#{TWYR_200908_125}");
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{TWYR_200908_126}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{TWYR_200908_127}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end
	--2021周年庆礼包
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88838701) then
		g_iYesNoType = 120
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end
	-- 特殊时装染色二次确认
	if ( event == "DRESSPAINT_SP_BINDDRESS" ) then
		g_iYesNoType = 121;
		SelectServerQuest_InfoWindow:SetText(tostring(arg0));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{LDCL_100508_14}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{LDCL_100508_15}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return;
	end
	
	-- 2021周年预热活动--重来一次按钮 二次确认
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88839703) then
		g_iYesNoType = 122;
		SelectServerQuest_InfoWindow:SetText("#{ZNYR_20210318_29}");
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{ZNYR_20210318_30}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{ZNYR_20210318_31}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return;
	end
	-- 2021周年预热活动--确认领取按钮 二次确认
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88839704) then
		g_iYesNoType = 123;
		SelectServerQuest_InfoWindow:SetText(Get_XParam_STR(0));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{ZNYR_20210318_30}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{ZNYR_20210318_31}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return;
	end
	-- 2021御猫探宝玩法 二次确认
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88843803) then
		SelectServerQuest_CatGift_Confirm(Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2), Get_XParam_INT(3))
		return;
	end
	--2021中秋玉兔礼盒 二次确认
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88874101) then
		g_iYesNoType = 128
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{QLGCJ_210818_11}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QLGCJ_210818_12}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QLGCJ_210818_13}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--代币整合召唤NPC，二次确认
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99844301) then
		g_iYesNoType = 133
		g_bagIndex = Get_XParam_INT(0);
		SelectServerQuest_InfoWindow:SetText("#{ZNDB_230215_85}");
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{JFLZ_180806_75}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{JFLZ_180806_76}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--代币整合兑换召唤券，二次确认
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99844403) then
		g_iYesNoType = 134
		local ItemId;
		local changeStrFlag;
		--此处传入的typeID,非bagIndex
		g_bagIndex = Get_XParam_INT(0);
		changeStrFlag = Get_XParam_INT(1);
		if g_bagIndex == 1 then
			ItemId = 38006254
		else
			ItemId = 38006255
		end
		local text
		if changeStrFlag == 1 then
			text = ScriptGlobal_Format("#{ZNDB_230215_120}",1,PlayerPackage:GetItemName( ItemId ));
		else
			text = ScriptGlobal_Format("#{ZNDB_230215_152}",PlayerPackage:GetItemName( ItemId ));
		end
		SelectServerQuest_InfoWindow:SetText(text);
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{JFLZ_180806_75}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{JFLZ_180806_76}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end
	--2023 增加使用十五载礼包 需要弹确认框
	if ( event == "UI_COMMAND" and tonumber(arg0) == 50510601) then
		g_iYesNoType = 135
		local name = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--2023 增加使用十六载礼包 需要弹确认框
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99849601) then
		g_iYesNoType = 136
		local name = Get_XParam_STR(0)
		g_tmpData.scriptId = Get_XParam_INT(0) or nil
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZNQCH_180427_01}",name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{QMQT_180309_52}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{QMQT_180309_53}");
		SelectServerQuest_Button2:Show();
		this:Show();
		return
	end

	--内丹升阶 需要弹确认框
	if ( event == "NEIDANUPGRADE_CONFIRM") then
		g_iYesNoType = 138
		local NeiDanCount =  tonumber(arg0)
		local NeiDanIndex =  tonumber(arg1)
		local YuanYeCount =  tonumber(arg2)
		local MaterialCount =  tonumber(arg3)

		local pnd_name = DataPool:LuaFnGetPetNeiDanName(NeiDanIndex);
		local level = DataPool:LuaFnEnumPetNeiDanLevelByPosIndex(NeiDanIndex);
		local qual = DataPool:LuaFnGetPetNeiDanpnQualByPosIndex(NeiDanIndex);

		local List ={

			[0] = {id = 38007501, name = "精品元液"},
			[1] = {id = 38007502, name = "珍品元液"},
			[2] = {id = 38007503, name = "神品元液"},

		}
		if List[qual] == nil then
			return 0
		end

		local itemName = DataPool:Lua_GetItemNameByIndex(List[qual].id)
		g_bagIndex = NeiDanIndex
		SelectServerQuest_InfoWindow:SetText(ScriptGlobal_Format("#{ZSSJ_230509_104}", NeiDanCount, pnd_name, MaterialCount, itemName, YuanYeCount, List[qual].name, level.."阶"..pnd_name, (level + 1).."阶"..pnd_name));
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{ZSSJ_230509_92}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{ZSSJ_230509_93}");
		SelectServerQuest_Button2:Show();
		DataPool:SetCanUseHotKey(0);
		this:Show();
		return
	end

	--内丹降阶 需要弹确认框
	if ( event == "NEIDANDOWNGRADE_CONFIRM") then
		g_iYesNoType = 139
		g_bagIndex =  tonumber(arg0)
		SelectServerQuest_InfoWindow:SetText("#{ZSSJ_230509_91}");
		LoginSelectUpdateRect();
		SelectServerQuest_Button1:SetText("#{ZSSJ_230509_92}");
		SelectServerQuest_Button1:Show();
		SelectServerQuest_Button2:SetText("#{ZSSJ_230509_93}");
		SelectServerQuest_Button2:Show();
		DataPool:SetCanUseHotKey(0);
		this:Show();
		return
	end


	-- 争霸赛 邀请玩家入队
	if (event == "UI_COMMAND" and tonumber(arg0) == 2022090601) then
		g_iYesNoType = 140

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = Get_XParam_INT(0)
		g_tmpData[2] = Get_XParam_INT(1)
		g_tmpData[3] = Get_XParam_INT(2)

		local strText = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(strText)

		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{WCBZ_180128_124}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()

		SelectServerQuest_Button2:SetText("#{WCBZ_180128_125}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()

		this:Show()
	end
	-- 争霸赛 解散战队
	if (event == "UI_COMMAND" and tonumber(arg0) == 2022090801) then
		g_iYesNoType = 141

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = Get_XParam_INT(0)
		g_tmpData[2] = Get_XParam_INT(1)

		local strText = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(strText)

		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{WCBZ_180128_306}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()

		SelectServerQuest_Button2:SetText("#{WCBZ_180128_133}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()

		this:Show()
	end
	-- 争霸赛 请离战队
	if (event == "UI_COMMAND" and tonumber(arg0) == 2022091401) then
		g_iYesNoType = 142

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = Get_XParam_INT(0)
		g_tmpData[2] = Get_XParam_INT(1)
		g_tmpData[3] = Get_XParam_INT(2)

		local strText = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(strText)

		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{WCBZ_180128_306}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()

		SelectServerQuest_Button2:SetText("#{WCBZ_180128_133}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()

		this:Show()
	end
	-- 争霸赛 退出战队
	if (event == "UI_COMMAND" and tonumber(arg0) == 2022091501) then
		g_iYesNoType = 143

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = Get_XParam_INT(0)
		g_tmpData[2] = Get_XParam_INT(1)

		local strText = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(strText)

		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{WCBZ_180128_306}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()

		SelectServerQuest_Button2:SetText("#{WCBZ_180128_133}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()

		this:Show()
	end
	-- 争霸赛 进入二次确认
	if (event == "UI_COMMAND" and tonumber(arg0) == 99857601) then
		g_iYesNoType = 144

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = Get_XParam_INT(0)
		g_tmpData[2] = Get_XParam_INT(1)
		g_tmpData[3] = Get_XParam_INT(2)

		SelectServerQuest_InfoWindow:SetText("#{WCBZ_230517_8}")

		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{WCBZ_180128_306}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()

		SelectServerQuest_Button2:SetText("#{WCBZ_180128_133}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()

		this:Show()
	end
	-- 单人观山海 入场时删除buff
	if (event == "UI_Command" and tonumber(arg0) == 99852301) then
		g_iYesNoType = 145

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = Get_XParam_INT(0)
		g_tmpData[2] = Get_XParam_INT(1)
		g_tmpData[3] = Get_XParam_INT(2)

		local strText = Get_XParam_STR(0)
		SelectServerQuest_InfoWindow:SetText(strText)

		LoginSelectUpdateRect()

		SelectServerQuest_Button1:SetText("#{WCBZ_180128_306}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()

		SelectServerQuest_Button2:SetText("#{WCBZ_180128_133}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()

		this:Show()
	end
	-- 经脉分页设计 门派传武NPC处 开启经脉分页二次确认框
	if (event == "UI_COMMAND" and tonumber(arg0) == 80081502) then
		g_iYesNoType = 146

		g_tmpData = {0}
		g_tmpData[1] = Get_XParam_INT(0)--要开的是经脉分页二还是三
		--PushDebugMessage(g_tmpData[1])
		SelectServerQuest_InfoWindow:SetText("#{JMQH_230829_26}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{JMQH_230829_27}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{JMQH_230829_28}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 凤鸣城战替换玩法（人数限制玩法） 一键分配确认
	if (event == "TCITYWARLIMIT_ASSIGNCONFIRM") then
		g_iYesNoType = 147
		
		SelectServerQuest_InfoWindow:SetText("#{GCQH_240429_81}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{GCQH_240429_82}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{GCQH_240429_83}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 凤鸣城战替换玩法（人数限制玩法）一键取消确认
	if (event == "TCITYWARLIMIT_CANCELCONFIRM") then
		g_iYesNoType = 148
		
		SelectServerQuest_InfoWindow:SetText("#{GCQH_240429_88}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{GCQH_240429_82}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{GCQH_240429_83}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 凤鸣城战替换玩法（人数限制玩法）保存分配结果确认
	if (event == "TCITYWARLIMIT_SAVECONFIRM") then
		g_iYesNoType = 149
		
		SelectServerQuest_InfoWindow:SetText("")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{GCQH_240429_82}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{GCQH_240429_83}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 凤鸣城战替换玩法（人数限制玩法）未保存直接刷新确认
	if (event == "TCITYWARLIMIT_REFRESHCONFIRM") then
		g_iYesNoType = 150
		
		SelectServerQuest_InfoWindow:SetText("")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{GCQH_240429_82}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{GCQH_240429_83}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 凤鸣城战替换玩法（人数限制玩法） 分配结果未保存退出确认
	if (event == "TCITYWARLIMIT_EXITCONFIRM") then
		g_iYesNoType = 151

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = tonumber(arg0)
		
		SelectServerQuest_InfoWindow:SetText("#{GCQH_240429_129}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{GCQH_240429_82}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{GCQH_240429_83}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 鳄鱼
	if (event == "UI_COMMAND" and tonumber(arg0) == 99927601) then
		g_iYesNoType = 152

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = Get_XParam_INT(0)
		g_tmpData[2] = Get_XParam_INT(1)
		local strText 		=  Get_XParam_STR(0)
		
		SelectServerQuest_InfoWindow:SetText(strText)
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{ERMP_240620_109}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{ERMP_240620_110}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 一叶扁舟
	if (event == "UI_COMMAND" and tonumber(arg0) == 99927801) then
		g_iYesNoType = 153

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = Get_XParam_INT(0)
		g_tmpData[2] = Get_XParam_INT(1)
		local strText 		=  Get_XParam_STR(0)
		
		SelectServerQuest_InfoWindow:SetText(strText)
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{ERMP_240620_109}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{ERMP_240620_110}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 凤鸣城战替换玩法（人数限制玩法） 移除助战玩家二次确认
	if (event == "TCITYWARLIMIT_REMOVEASSISTCONFIRM") then
		g_iYesNoType = 154

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = tonumber(arg0)
		g_tmpData[2] = tonumber(arg1)
		
		SelectServerQuest_InfoWindow:SetText("#{GCQH_240429_198}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{GCQH_240429_82}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{GCQH_240429_83}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 天龙吃鸡 积分奖励
	if (event == "UI_COMMAND" and tonumber(arg0) == 99933201) then
		g_iYesNoType = 155

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = tonumber(arg0)

		SelectServerQuest_InfoWindow:SetText("#{TLCJ_20240709_263}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{TLCJ_20240709_140}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{TLCJ_20240709_141}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 凤鸣城战替换玩法（人数限制玩法） 退出助战二次确认
	if (event == "TCITYWARLIMIT_CANCELASSISTCONFIRM") then
		g_iYesNoType = 156

		g_tmpData = {-1, -1, -1}
		
		SelectServerQuest_InfoWindow:SetText("#{GCQH_240429_286}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{GCQH_240429_82}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{GCQH_240429_83}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 天龙吃鸡 排名奖励（单人模式）
	if (event == "UI_COMMAND" and tonumber(arg0) == 99933202) then
		g_iYesNoType = 157

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = tonumber(arg0)

		SelectServerQuest_InfoWindow:SetText("#{TLCJ_20240709_294}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{TLCJ_20240709_140}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{TLCJ_20240709_141}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
	-- 天龙吃鸡 排名奖励（单人模式）
	if (event == "UI_COMMAND" and tonumber(arg0) == 99933203) then
		g_iYesNoType = 158

		g_tmpData = {-1, -1, -1}
		g_tmpData[1] = tonumber(arg0)

		SelectServerQuest_InfoWindow:SetText("#{TLCJ_20240709_294}")
		LoginSelectUpdateRect()
		SelectServerQuest_Button1:SetText("#{TLCJ_20240709_140}")
		SelectServerQuest_Button1:Show()
		SelectServerQuest_Button1:Enable()
		SelectServerQuest_Button2:SetText("#{TLCJ_20240709_141}")
		SelectServerQuest_Button2:Show()
		SelectServerQuest_Button2:Enable()
		this:Show()
	end
end

function SelectServerQuest_LostPassWord()
	if g_IsThreedForbit == 1 then
		if GameProduceLogin:IsWeGameClient() <= 0 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_THREEDDAYFORBIT"))
		else
			GameProduceLogin:OpenURL(GetWeblink("WEB_WEGAME_ANQUANZHONGXIN_KFZX"))
		end
		return
	end
	
	if g_iYesNoType == 112 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_WCN1"))
		
	elseif g_iYesNoType == 113 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_WCN2"))
		
	elseif g_iYesNoType == 114 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_WCN3"))

	elseif g_iYesNoType == 124 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_DLYZFCM"))
		
	elseif g_iYesNoType == 125 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_DLYZFCM"))
		
	elseif g_iYesNoType == 129 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_DLYZFCM"))
	
	elseif g_iYesNoType == 137 then
		GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_RZSJ"))	
				
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_FORGOTPASSWORD"))
	end

	

	--if(Variable:GetVariable("System_CodePage") == "1258") then
	--	GameProduceLogin:OpenURL(GetWeblink("WEB_CHANGEPWD"))
	--else
    	--	GameProduceLogin:OpenURL(GetWeblink("WEB_CHANGEPWD"))
	--end
end

-------------------------------------------------------------
--
-- 按钮1 点击事件
--
function SelectServerQuest_Bn1Click()
-- 0 - 退出游戏
-- 4 - 确认是否删除10级以上玩家
-- 5 - 7天内提醒删除10级以上玩家
-- 6 - 7天后，14天内提醒删除10级以上玩家
-- 7 - 是否删除10级以下玩家
-- 8 - 大于10级得提示
	if( -1 == g_iYesNoType and 1 == g_bIsQuitMsgBox) then
		ForbidRunCmdLine();
		CancelQuitWait(); --取消退出
	end
	if(0 == g_iYesNoType) then
		QuitApplication("quit");
	elseif(1 == g_iYesNoType) then
	elseif(2==g_iYesNoType) then
		GameProduceLogin:ChangeToAccountInputDlgFromSelectRole();
	elseif( 3 == g_iYesNoType ) then
		GameProduceLogin:CloseNetConnect();
	elseif( 4 == g_iYesNoType ) then
			local strInfo;
		  strInfo ="您的角色不能马上删除，请在3天以后14天以内登录游戏，到洛阳（268，46）找到关汉寿或者到大理（80，136）找到周仓确认，即可永久删除。确认删除时角色不能处于有帮会、结婚、结拜、师徒、开店状态，否则删除将被取消。超过14天没有再次删除则删除操作无效。"
			GameProduceLogin:ShowMessageBox( strInfo, "OK", "8" );
	elseif( 5 == g_iYesNoType ) then
	elseif( 6 == g_iYesNoType ) then
	elseif( 7 == g_iYesNoType ) then
		GameProduceLogin:DelSelRole();
	elseif( 8 == g_iYesNoType ) then
		GameProduceLogin:DelSelRole();
	-- elseif( 9 == g_iYesNoType ) then
	-- 	GameProduceLogin:LoginPlayer( 1 );
	elseif( 10 == g_iYesNoType ) then

	elseif(11 == g_iYesNoType) then
		GameProduceLogin:CheckAccountNoMibao();
	elseif(12 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UseShelizi" )
			Set_XSCRIPT_ScriptID( 300077 )
			Set_XSCRIPT_Parameter( 0, g_bagIndex )
			Set_XSCRIPT_Parameter( 1, 0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif(13 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UseTianYuanJinDan" )
			Set_XSCRIPT_ScriptID( 332004 )
			Set_XSCRIPT_Parameter( 0, g_bagIndex )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif(14 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UseShelizi" )
			Set_XSCRIPT_ScriptID( 300088 )
			Set_XSCRIPT_Parameter( 0, g_bagIndex )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif(15 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Anqi2Shenzhen" )
			Set_XSCRIPT_ScriptID( 260001 )
			Set_XSCRIPT_Parameter( 0, g_bagIndex )
			Set_XSCRIPT_Parameter( 1, g_bagIndex2 )
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (17 == g_iYesNoType) then
		--PushEvent("PET_EQUIP_DEPART_CONFIRM")
		PetEquipSuitDepart:ConfirmDepart()
	elseif (18 == g_iYesNoType) then
		--绑定元宝不足时，确定
		NpcShop:BindYuanBaoNotEnough(g_itemNum, g_item,g_pos)
	elseif (19 == g_iYesNoType) then
		LifeAbility:ConfirmDiaowenShike(1)
	elseif (20 == g_iYesNoType) then
		if g_objCared ~= -1 and g_bagIndex ~= -1 then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("DelProtectGoods");
				Set_XSCRIPT_ScriptID(124);
				Set_XSCRIPT_Parameter(0,tonumber(g_objCared));
				Set_XSCRIPT_Parameter(1,tonumber(g_bagIndex));
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
		end
	elseif (21 == g_iYesNoType) then
		LifeAbility:ConfirmDiaowenHecheng(1)
	elseif (22 == g_iYesNoType) then
		LifeAbility:ConfirmDiaowenQianghua(1)
	elseif (23 == g_iYesNoType) then
		LifeAbility:ConfirmDiaowenShike(2)
	elseif (24 == g_iYesNoType) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("GivePrize");
			Set_XSCRIPT_ScriptID(808147)
			Set_XSCRIPT_Parameter(0,tonumber(g_objCared))
			Set_XSCRIPT_Parameter(1,tonumber(g_bagIndex))
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	elseif (25 == g_iYesNoType) then --取消更新服务器列表
		--如果杀Launch进程失败，不隐藏
		if (GameProduceLogin:KillLaunchProcess() == 0) then
			return;
		end
--~ 	elseif (26 == g_iYesNoType) then
--~ 		Clear_XSCRIPT();
--~ 			Set_XSCRIPT_Function_Name("OnPetEquipSuitUp")
--~ 			Set_XSCRIPT_ScriptID(800109)
--~ 			Set_XSCRIPT_Parameter(0,tonumber(g_pos))
--~ 			Set_XSCRIPT_Parameter(1,tonumber(g_objCared))
--~ 			Set_XSCRIPT_Parameter(2,tonumber(g_itemNum))
--~ 			Set_XSCRIPT_ParamCount(3)
--~ 		Send_XSCRIPT();
--~ 		Player:CommonClientMessage(20100524,0,0,0,0,0)
	elseif (26 == g_iYesNoType) then
		--LifeAbility:Do_Displace(g_equipSrc, g_equipDst, g_equipFu)
	elseif( 27 == g_iYesNoType ) then
		local strInfo;
		strInfo ="#{SCJS_110613_1}"
		GameProduceLogin:ShowMessageBox( strInfo, "OK", "8" );
	elseif (28 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnGiveContentionExp" )
			Set_XSCRIPT_ScriptID( 889429 )
			Set_XSCRIPT_Parameter( 0, g_objCared )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (29 == g_iYesNoType) then
		DataPool:GMChat_ConfirmCancelConnect(1)
	elseif 30 == g_iYesNoType then --变性确认界面
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ChangeSexSure")
			Set_XSCRIPT_ScriptID(250557)
			Set_XSCRIPT_Parameter(0, g_objCared)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif 31 == g_iYesNoType then
		GameProduceLogin:QuitAndUpdate();
	elseif (32==g_iYesNoType) then
		if g_PneumaSmeltBag_Pos>=0 then
			local nGetExp=Pneuma:GetPneumaProperty(g_PneumaSmeltBag_Pos,7)
			local nPlayerOwnExp=Pneuma:GetPneumaExp()
			local nMaxExp=Pneuma:GetPneumaExpMax()
			if nPlayerOwnExp>(nMaxExp-nGetExp) then
--				PushEvent( "PNEUMA_CUIJIE_CONFIRM_MAX", g_PneumaSmeltBag_Pos)
				PushDebugMessage("#{ZYXT_120528_91}")
			else
				Pneuma:SmeltPneumaItem(g_PneumaSmeltBag_Pos)
				--有翰如海任务则打开真元盘
				local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_NewerMission_HanRuHai)
				local paramIfCompelete  = 0
				local paramIfCompelete2 = 0
				if missionIndex >= 0 and missionIndex < 20 then
					paramIfCompelete2 = DataPool:GetPlayerMission_Variable(missionIndex, 3)
					paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
				end
				if (not IsWindowShow("ZhenYuan")) and paramIfCompelete == 0 and Pneuma:IsMissionAcc(ZhenYuan_NewerMission_HanRuHai) > 0 and paramIfCompelete2 == 1 then
					PushEvent( "TOGGLE_PNEUMA_UI", 0)
				end
			end
		end
	elseif (33==g_iYesNoType) then
		--上限判断
		if Pneuma:IsSmeltAll_OverMaxExp()==1 then--超过上限啦
--			PushEvent( "PNEUMA_CUIJIEALL_CONFIRM_MAX")
			PushDebugMessage("#{ZYXT_120528_91}")
		else
			Pneuma:SmeltAllPneumaItem()
		end
--	elseif (34==g_iYesNoType) then
--		if g_PneumaSmeltBag_Pos34>=0 then
--			Pneuma:SmeltPneumaItem(g_PneumaSmeltBag_Pos34)
--			--有翰如海任务则打开真元盘
--			local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_NewerMission_HanRuHai)
--			local paramIfCompelete  = 0
--			local paramIfCompelete2 = 0
--			if missionIndex >= 0 and missionIndex < 20 then
--				paramIfCompelete2 = DataPool:GetPlayerMission_Variable(missionIndex, 3)
--				paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
--			end
--			if (not IsWindowShow("ZhenYuan")) and paramIfCompelete == 0 and Pneuma:IsMissionAcc(ZhenYuan_NewerMission_HanRuHai) > 0 and paramIfCompelete2 == 1 then
--				PushEvent( "TOGGLE_PNEUMA_UI", 0)
--			end
--		end
--	elseif (35==g_iYesNoType) then
--		Pneuma:SmeltAllPneumaItem()
	elseif (36==g_iYesNoType) then
		if g_PneumaSmeltBag_Pos36~=-1 then
			PushEvent( "NINGLAINALL_CUIJIECONFIRM_OK", g_PneumaSmeltBag_Pos36)
		end
    elseif ( 37 == g_iYesNoType ) then
        SelectServerQuest_DoSwitchGems( 1 )
	elseif(38 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UseXuelizi" )
			Set_XSCRIPT_ScriptID( 889967 )
			Set_XSCRIPT_Parameter( 0, g_bagIndex )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif(39 == g_iYesNoType) then
		LifeAbility : Do_Gem_Change("check", tonumber(0), tonumber(0)) --//By YPL,2013/3/6
	elseif(42 == g_iYesNoType) then
		PushEvent( "BUDGETPLANINFO_DOWNPAYOKORCANCEL", 1,g_DownPayIndex)
	elseif(43 == g_iYesNoType) then
		PushEvent( "BUDGETPLANINFO_REPAYOKORCANCEL", 1,g_RePayIndex)
	elseif(44 == g_iYesNoType) then
		g_DressPaint_TipsBind = 1
	-- elseif(45 == g_iYesNoType) then
	-- 	Clear_XSCRIPT()
	-- 		Set_XSCRIPT_Function_Name("LingquDoubleOK")
	-- 		Set_XSCRIPT_ScriptID(890841)
	-- 		Set_XSCRIPT_ParamCount(0)
	-- 	Send_XSCRIPT()

	elseif(46 == g_iYesNoType) then
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("SteppedUpBooks");
		Set_XSCRIPT_ScriptID(890630);
		Set_XSCRIPT_Parameter(0,g_card_stepup_bagindex);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();

	elseif (47 == g_iYesNoType) then
		LifeAbility:ConfirmDiaowenRonghe(2)
	elseif g_iYesNoType == 52 then
		PushEvent("INFANTDRESSPAINT_BIND_CONFIRM_RESULT",1)
	elseif g_iYesNoType == 53 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "SubmitTwice" )
			Set_XSCRIPT_ScriptID( 890991 )
			Set_XSCRIPT_Parameter(0,g_TargetID);
			Set_XSCRIPT_Parameter(1,g_ChengZhangZhi);
			Set_XSCRIPT_Parameter(2,g_CostNum);
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	-- elseif(54 == g_iYesNoType) then
	-- 	Clear_XSCRIPT()
	-- 		Set_XSCRIPT_Function_Name("JubaopenBulingDoubleOK")
	-- 		Set_XSCRIPT_ScriptID(805012)
	-- 		Set_XSCRIPT_Parameter( 0, g_TargetID )
	-- 		Set_XSCRIPT_Parameter( 1, g_TypeFlag )
	-- 		Set_XSCRIPT_ParamCount(2)
	-- 	Send_XSCRIPT()
	--Add By YuanPeiLong 20141121 [子女变性丹设计]
	elseif (55 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ChangeSexChildSure")
			Set_XSCRIPT_ScriptID(250557)
			Set_XSCRIPT_Parameter(0, g_objCared)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	--2015老三环副本玩法优化 By yuanpeilong
	elseif(56 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Second_QueRen" )
			Set_XSCRIPT_ScriptID( 891075 )
			Set_XSCRIPT_Parameter(0, g_objCared)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif(58 == g_iYesNoType) then		--确认结婚日期
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "MarryDateCallBack" )
			Set_XSCRIPT_ScriptID( 000093 )
			Set_XSCRIPT_Parameter(0, 1)	-- 是否确认 0为取消,1为确认
			Set_XSCRIPT_Parameter(1, g_iWeddingDay)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif(61 == g_iYesNoType) then
		GameProduceLogin:CancelDelRole();
	elseif(62 == g_iYesNoType) then		--家具合成二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnCompound" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_Parameter(0,g_FurnitureType);
			Set_XSCRIPT_Parameter(1,g_FurnitureLevel);
			Set_XSCRIPT_Parameter(2,g_FurniturePos);
			Set_XSCRIPT_Parameter(3,-1);
			Set_XSCRIPT_Parameter(4,2);
			Set_XSCRIPT_Parameter(5,0);
			Set_XSCRIPT_ParamCount(6)
		Send_XSCRIPT()
	elseif(63 == g_iYesNoType) then		--家具合成二次确认
		PushEvent("UPDATE_FURNITUREBAG_SEC",2)
	elseif(64 == g_iYesNoType) then		--家具合成二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnCompound" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_Parameter(0,g_FurnitureType);
			Set_XSCRIPT_Parameter(1,g_FurnitureLevel);
			Set_XSCRIPT_Parameter(2,g_FurniturePos);
			Set_XSCRIPT_Parameter(3,-1);
			Set_XSCRIPT_Parameter(4,2);
			Set_XSCRIPT_Parameter(5,0);
			Set_XSCRIPT_ParamCount(6)
		Send_XSCRIPT()
	elseif(65 == g_iYesNoType) then		--家具合成二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyZHF" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif(66 == g_iYesNoType) then		--家具装潢二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnDecoration" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_Parameter(0,g_ItemBagIDXiYou);
			Set_XSCRIPT_Parameter(1,g_ItemBagID);
			Set_XSCRIPT_Parameter(2,g_ItemBagIDBind);

			Set_XSCRIPT_Parameter(3,1);
			Set_XSCRIPT_Parameter(4,1);
			Set_XSCRIPT_Parameter(5,1);
			Set_XSCRIPT_ParamCount(6)
			--PushDebugMessage("g_ItemBagIDXiYou="..g_ItemBagIDXiYou.." g_ItemBagID="..g_ItemBagID.." g_BagItemIndex="..g_BagItemIndex.." g_ZHFBagIndex="..g_ZHFBagIndex)
		Send_XSCRIPT()
	elseif(67 == g_iYesNoType) then		--家具装潢二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "InCangkuOnCompound" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_Parameter(0,g_FurnitureDelItemID);
			Set_XSCRIPT_Parameter(1,0);
			Set_XSCRIPT_Parameter(2,2);
			Set_XSCRIPT_Parameter(3,0);
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif(68 == g_iYesNoType) then		--家具仓库购买装潢符确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyZHF" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif(69 == g_iYesNoType) then		--家具仓库购买装潢符确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnDecoration" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_Parameter(0,g_ItemBagIDXiYou);
			Set_XSCRIPT_Parameter(1,g_ItemBagID);
			Set_XSCRIPT_Parameter(2,g_ItemBagIDBind);
			Set_XSCRIPT_Parameter(3,1);
			Set_XSCRIPT_Parameter(4,1);
			Set_XSCRIPT_Parameter(5,1);
			Set_XSCRIPT_ParamCount(6)
		Send_XSCRIPT()
	elseif(70 == g_iYesNoType) then
		PushEvent("UI_COMMAND", 2016092992)
	elseif(71 == g_iYesNoType) then
		PushEvent("UI_COMMAND", 2016092993)
	elseif( 72 == g_iYesNoType) then		--家具仓库购买装潢符确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOneKeyCompound" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_Parameter(0,g_FurnitureType);
			Set_XSCRIPT_Parameter(1,g_FurnitureLevel);
			Set_XSCRIPT_Parameter(2,g_FurniturePos);
			Set_XSCRIPT_Parameter(3,1);
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()

	elseif( 73 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnInBankOneKeyCompound" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_Parameter(0,g_FurnitureType);
			Set_XSCRIPT_Parameter(1,g_FurnitureLevel);
			Set_XSCRIPT_Parameter(2,g_FurniturePos);
			Set_XSCRIPT_Parameter(3,1);
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif( 74 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangePrize" )
			Set_XSCRIPT_ScriptID( 892394 )
			Set_XSCRIPT_Parameter(0,g_ExchangeIndex);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif(75 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyZhuanHuanFu" )
			Set_XSCRIPT_ScriptID( 891837 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif 76 == g_iYesNoType then
		BieYeUI:ObjReserveAll(tonumber(g_tmpData.objid))
	elseif 77 == g_iYesNoType then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientUpdate")
			Set_XSCRIPT_ScriptID(891877)
			Set_XSCRIPT_Parameter(0, g_tmpData.targetId)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif( 78 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangePrize" )
			Set_XSCRIPT_ScriptID( 892454 )
			Set_XSCRIPT_Parameter(0,g_HappyTLTenYearsIndex);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif( 79 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangePrize" )
			Set_XSCRIPT_ScriptID( 892456 )
			Set_XSCRIPT_Parameter(0,g_JiuJiuXiaoHan_Summer_Index);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif( 80 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
			Set_XSCRIPT_ScriptID( 892466 )
			Set_XSCRIPT_Parameter(0,g_HuoyueWeeklyGift_Index)
			Set_XSCRIPT_Parameter(1,1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif( 81 == g_iYesNoType) then		--登录提示 激活帐号
		GameProduceLogin:OpenURL(GetWeblink("WEB_ACTIVEACC"))	--弹出页面

	elseif( 83 == g_iYesNoType) then		--武意乾坤丹150满级使用的二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ConfirmOk" )
			Set_XSCRIPT_ScriptID( 892728)
			Set_XSCRIPT_ParamCount( 0 )
		Send_XSCRIPT()
	--2018清明节
	elseif (84 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ConfirmOK")
			Set_XSCRIPT_ScriptID(892721)
			Set_XSCRIPT_Parameter(0, g_objCared)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	--2018周年庆礼包
	elseif (85 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(891815)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (86 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(891816)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (87 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(891817)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (88 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(891818)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (89 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(891819)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (90 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(891820)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (91 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(891821)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (92 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(891822)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (93 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(891823)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (94 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(892432)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (95 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(892749)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	--金枫祈愿
	elseif (97 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(892885)
			Set_XSCRIPT_Parameter(0,g_bagIndex);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif(98 == g_iYesNoType or 99 == g_iYesNoType or 100 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnExcuteJump" );
			Set_XSCRIPT_ScriptID( 892904 );
			Set_XSCRIPT_Parameter( 0, g_iYesNoType-97 );
			Set_XSCRIPT_Parameter( 1, 0 );
			Set_XSCRIPT_ParamCount( 2 );
		Send_XSCRIPT()
	elseif(102 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnDayFinalAward" ); 		-- 脚本号
			Set_XSCRIPT_ScriptID( 892980 );						-- 脚本编号
			Set_XSCRIPT_Parameter( 0, g_CaiQiu_TargetID)
			Set_XSCRIPT_Parameter( 1, 1 );						-- 参数一:类型
			Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
		Send_XSCRIPT()
	elseif(103 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnOpenHongBaoUI" ); 		-- 脚本号
			Set_XSCRIPT_ScriptID( 893025 );						-- 脚本编号
			Set_XSCRIPT_Parameter( 0, 1 );						-- 参数一:类型
			Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
		Send_XSCRIPT()
	elseif(106 == g_iYesNoType) or (107 == g_iYesNoType) then
		if g_tmpData[2] == 0 then
			PushEvent("OPEN_WENWU",g_tmpData[1] )
			PushDebugMessage("#{LJYX_190318_53}")
		else
			PushEvent("OPEN_WENWU",g_tmpData[1] )
			PushDebugMessage("#{LJYX_190318_78}")
		end
	elseif(108 == g_iYesNoType) then
		if g_tmpData[2] == 0 then
			PushDebugMessage("#{LJYX_190318_55}")
		else
			PushDebugMessage("#{LJYX_190318_80}")
		end
	elseif (109 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(893077)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (111 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(893407)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (115 == g_iYesNoType) then
		PushEvent( "FEIYUDRESS_PAINT_OK", 1)
	elseif (116 == g_iYesNoType) then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnFeiyuDressPaint")
		Set_XSCRIPT_ScriptID(830003)
		Set_XSCRIPT_Parameter(0, g_tmpData[1])
		Set_XSCRIPT_Parameter(1, g_tmpData[2])
		Set_XSCRIPT_Parameter(2, g_tmpData[3])
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	elseif (117 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("T300FinalAward")
			Set_XSCRIPT_ScriptID(888228)
			Set_XSCRIPT_Parameter( 0, 1 )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (118 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("T300BaJingBuHui")
			Set_XSCRIPT_ScriptID(888228)
			Set_XSCRIPT_Parameter( 0, 1 )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (119 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnAdd30Point")
			Set_XSCRIPT_ScriptID(888252)
			Set_XSCRIPT_Parameter( 0, g_tmpData[1] )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (120 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(888387)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif(121 == g_iYesNoType) then
		g_DressPaint_sp_TipsBind = 1		
	-- 2021周年预热活动--重来一次按钮 二次确认
	elseif (122 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnReset")
			Set_XSCRIPT_ScriptID(888397)
			Set_XSCRIPT_Parameter( 0, 1 )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	-- 2021周年预热活动--确认领取按钮 二次确认
	elseif (123 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnPrize")
			Set_XSCRIPT_ScriptID(888397)
			Set_XSCRIPT_Parameter( 0, 1 )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif 126 == g_iYesNoType then -- 争霸赛 变性确认界面
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ZBSChangeSexSure")
			Set_XSCRIPT_ScriptID(888427)
			Set_XSCRIPT_Parameter(0, g_objCared)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif 127 == g_iYesNoType then -- 2021御猫探宝玩法 二次确认
		SelectServerQuest_CatGift_Click()
	elseif 128 == g_iYesNoType then -- 2021中秋玉兔礼盒 二次确认
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnSecondConfirm")
			Set_XSCRIPT_ScriptID(888741)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (130 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confirm")
			Set_XSCRIPT_ScriptID(888769)
			Set_XSCRIPT_Parameter(0,g_bagIndex);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif( 132 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangePrize" )
			Set_XSCRIPT_ScriptID( 888971 )
			Set_XSCRIPT_Parameter(0,g_JiuJiuXiaoHan_Summer_Index);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (133 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(998443)
			Set_XSCRIPT_Parameter(0,g_bagIndex);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (134 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ExchangeCheckAgain")
			Set_XSCRIPT_ScriptID(998444)
			Set_XSCRIPT_Parameter(0,g_bagIndex);
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (135 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			Set_XSCRIPT_ScriptID(505106)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (136 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Confim")
			if g_tmpData.scriptId and g_tmpData.scriptId > 0 then
				Set_XSCRIPT_ScriptID(g_tmpData.scriptId)
			else
				Set_XSCRIPT_ScriptID(998496)
			end
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (138 == g_iYesNoType) then
		Clear_XSCRIPT();
        	Set_XSCRIPT_Function_Name("OperateUI");
        	Set_XSCRIPT_ScriptID(998552);
        	Set_XSCRIPT_Parameter(0,1);
        	Set_XSCRIPT_Parameter(1,g_bagIndex);
        	Set_XSCRIPT_ParamCount(2);
    	Send_XSCRIPT();
	elseif (139 == g_iYesNoType) then
		Clear_XSCRIPT();
        	Set_XSCRIPT_Function_Name("OperateUI");
        	Set_XSCRIPT_ScriptID(998551);
			Set_XSCRIPT_Parameter(0,1);
			Set_XSCRIPT_Parameter(1,g_bagIndex);
        	Set_XSCRIPT_ParamCount(2);
    	Send_XSCRIPT();
	elseif (140 == g_iYesNoType) then
		-- 争霸赛 邀请玩家入队
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CallBack_InviteConfirm")
			Set_XSCRIPT_ScriptID(998576)	
			Set_XSCRIPT_Parameter(0, g_tmpData[1])
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, g_tmpData[2])
			Set_XSCRIPT_Parameter(3, g_tmpData[3])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif (141 == g_iYesNoType) then
		-- 争霸赛 解散战队
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CallBack_DismissConfirm")
			Set_XSCRIPT_ScriptID(998576)	
			Set_XSCRIPT_Parameter(0, g_tmpData[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (142 == g_iYesNoType) then
		-- 争霸赛 请离战队
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CallBack_DeleteMemberConfirm")
			Set_XSCRIPT_ScriptID(998576)	
			Set_XSCRIPT_Parameter(0, g_tmpData[2])
			Set_XSCRIPT_Parameter(1, g_tmpData[3])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (143 == g_iYesNoType) then
		-- 争霸赛 退出战队
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CallBack_QuitConfirm")
			Set_XSCRIPT_ScriptID(998576)	
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif (144 == g_iYesNoType) then
		-- 争霸赛 进入二次确认
		local funcName = nil
		if (g_tmpData[3] == 1) then
			funcName = "Qualify_TryEnter_Confirm"
		else
			funcName = "Promote_TryEnter_Confirm"
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name(funcName)
			Set_XSCRIPT_ScriptID(998576)
			Set_XSCRIPT_Parameter(0, g_tmpData[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (145 == g_iYesNoType) then
		-- 单人观山海 入场时删除部分buff
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("TryEnterCopyScene")
			Set_XSCRIPT_ScriptID(998523)	
			Set_XSCRIPT_Parameter(0, g_tmpData[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (146 == g_iYesNoType) then
		-- 经脉分页设计 开启经脉分页 二次确认框
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ConfirmOpen")
			Set_XSCRIPT_ScriptID(800815)	
			Set_XSCRIPT_Parameter(0, g_tmpData[1])
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (147 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 一键分配确认结果
		PushEvent("TCITYWARLIMIT_ASSIGNCONFIRMRESULT", 1)
	elseif (148 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 一键取消确认结果
		PushEvent("TCITYWARLIMIT_CANCELCONFIRMRESULT", 1)
	elseif (149 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 保存分配结果确认结果
		PushEvent("TCITYWARLIMIT_SAVECONFIRMRESULT", 1)
	elseif (150 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 分配结果未保存直接刷新确认结果
		PushEvent("TCITYWARLIMIT_REFRESHCONFIRMRESULT", 1)
	elseif (151 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 分配结果未保存直接退出确认结果
		PushEvent("TCITYWARLIMIT_EXITCONFIRMRESULT", 1, g_tmpData[1])
	elseif (152 == g_iYesNoType) then
		--鳄鱼
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ERGConfirm" )
			Set_XSCRIPT_ScriptID(999276)	
			Set_XSCRIPT_Parameter(0, g_tmpData[1])	
			Set_XSCRIPT_Parameter(1, g_tmpData[2])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (153 == g_iYesNoType) then
		--一叶扁舟
		local ret = g_tmpData[2]
		if ret == 1 then
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BusOnePlayer" )
			Set_XSCRIPT_ScriptID(999278)	
			Set_XSCRIPT_Parameter(0, g_tmpData[1])	
			Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif ret == 2 then
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BusTwoPlayer" )
			Set_XSCRIPT_ScriptID(999278)	
			Set_XSCRIPT_Parameter(0, g_tmpData[1])	
			Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
	elseif (154 == g_iYesNoType) then
		PushEvent("TCITYWARLIMIT_REMOVEASSISTCONFIRMRESULT", 1, g_tmpData[1], g_tmpData[2])
	elseif (155 == g_iYesNoType) then
		-- 天龙吃鸡 积分奖励
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Award_Score_Got")
			Set_XSCRIPT_ScriptID(999332)
			Set_XSCRIPT_Parameter(0,  g_tmpData[1])
			Set_XSCRIPT_Parameter(1,  0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (156 == g_iYesNoType) then
		PushEvent("TCITYWARLIMIT_CANCELASSISTCONFIRMRESULT", 1)
	elseif (157 == g_iYesNoType) then
		-- 天龙吃鸡 排名奖励（单人模式）
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Award_Rank_Got")
			Set_XSCRIPT_ScriptID(999332)
			Set_XSCRIPT_Parameter(0,  g_tmpData[1])
			Set_XSCRIPT_Parameter(1,  0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (158 == g_iYesNoType) then
		-- 天龙吃鸡 排名奖励（组队模式）
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Award_Team_Rank_Got")
			Set_XSCRIPT_ScriptID(999332)
			Set_XSCRIPT_Parameter(0,  g_tmpData[1])
			Set_XSCRIPT_Parameter(1,  0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end

	if(g_IsNoMIBAO == 1) then
		PushEvent("LOGIN_NO_MIBAO_CLOSE");
		g_IsNoMIBAO = 0;
	end

	this:Hide();
end


-------------------------------------------------------------
--
-- 按钮2 点击事件
--
function SelectServerQuest_Bn2Click()
	g_showbuttonStr = nil
	if(3 == g_iYesNoType) then
		GameProduceLogin:CloseNetConnect();
	-- elseif( 9 == g_iYesNoType ) then
	-- 	GameProduceLogin:PassportButNotReg();
	elseif( 10 == g_iYesNoType ) then

	elseif(17 == g_iYesNoType )then
		--PushEvent("PET_EQUIP_DEPART_CANCEL")
	elseif (28 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnQuitContentionExp" )
			Set_XSCRIPT_ScriptID( 889429 )
			Set_XSCRIPT_Parameter( 0, g_objCared )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif (32==g_iYesNoType or 33==g_iYesNoType) then
		PushDebugMessage("#{ZYXT_120528_89}")--取消淬解成功。
	elseif ( 36==g_iYesNoType ) then
		PushEvent("NINGLAINALL_CUIJIECONFIRM_CANCEL")
    elseif ( 37 == g_iYesNoType ) then
		SelectServerQuest_DoSwitchGems( 0 )
	elseif(42 == g_iYesNoType) then
		PushEvent( "BUDGETPLANINFO_DOWNPAYOKORCANCEL", 0)
	elseif(43 == g_iYesNoType) then
		PushEvent( "BUDGETPLANINFO_REPAYOKORCANCEL", 0)
	elseif g_iYesNoType == 52 then
		PushEvent("INFANTDRESSPAINT_BIND_CONFIRM_RESULT",0)
	--2015老三环副本玩法优化 By yuanpeilong
	elseif(56 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Second_QueRen" )
			Set_XSCRIPT_ScriptID( 891075 )
			Set_XSCRIPT_Parameter(0, g_objCared)
			Set_XSCRIPT_Parameter(1, 2)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif(58 == g_iYesNoType) then		--确认结婚日期
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "MarryDateCallBack" )
			Set_XSCRIPT_ScriptID( 000093 )
			Set_XSCRIPT_Parameter(0, 0)	-- 是否确认 0为取消,1为确认
			Set_XSCRIPT_Parameter(1, g_iWeddingDay)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	elseif (140 == g_iYesNoType) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Team_CallBack_InviteConfirm")
			Set_XSCRIPT_ScriptID(998576)	
			Set_XSCRIPT_Parameter(0, g_tmpData[1])
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_Parameter(2, g_tmpData[2])
			Set_XSCRIPT_Parameter(3, g_tmpData[3])
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif (147 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 一键分配确认结果
		PushEvent("TCITYWARLIMIT_ASSIGNCONFIRMRESULT", 0)
	elseif (148 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 一键取消确认结果
		PushEvent("TCITYWARLIMIT_CANCELCONFIRMRESULT", 0)
	elseif (149 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 保存分配结果确认结果
		PushEvent("TCITYWARLIMIT_SAVECONFIRMRESULT", 0)
	elseif (150 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 分配结果未保存直接刷新确认结果
		PushEvent("TCITYWARLIMIT_REFRESHCONFIRMRESULT", 0)
	elseif (151 == g_iYesNoType) then
		-- 凤鸣城战替换玩法（人数限制玩法） 分配结果未保存直接退出确认结果
		PushEvent("TCITYWARLIMIT_EXITCONFIRMRESULT", 0, g_tmpData[1])
	elseif (154 == g_iYesNoType) then
		PushEvent("TCITYWARLIMIT_REMOVEASSISTCONFIRMRESULT", 0, g_tmpData[1], g_tmpData[2])
	elseif (156 == g_iYesNoType) then
		PushEvent("TCITYWARLIMIT_CANCELASSISTCONFIRMRESULT", 0)
	end
	--//By YPL,2013/3/6
    --elseif ( 39 == g_iYesNoType ) then
	--	PushEvent("BAOSHI_CHANGE_CONFIRM_CANCEL")
	this:Hide();
end

function SelectServerQuest_TimeOut()
  if( TimerArg == "USERONLINE" ) then
    SelectServerQuest_Button1:Enable()
    TimerArg = nil
  elseif(TimerArg == "MIBAOERROR" ) then
    SelectServerQuest_Button1:Enable()
    TimerArg = nil
  elseif(TimerArg == "USERFROMMAINPRO") then
	this:Hide();
	TimerArg = nil
  elseif(TimerArg == "WAITFORQUIT" or TimerArg == "WAITFORQUIT_SO") then
	if(tonumber(g_QuitType)==0 or tonumber(g_QuitType)==3)then
		QuitApplication("quit");
	else
		AskRet2SelServer();
	end
	this:Hide();
	TimerArg = nil
	g_QuitType = nil
  elseif(TimerArg == "TURNOVER") then
	SelectServerQuest_Button1:Enable()
	TimerArg = nil
	elseif( TimerArg == "LoginCounting" ) then
    SelectServerQuest_Button1:Enable()
    TimerArg = nil
  elseif( TimerArg == "89298401" ) then
  	this:Hide();
		TimerArg = nil

  elseif( TimerArg == "920190320" ) then
		this:Hide();
		TimerArg = nil
  elseif( TimerArg == "89306502" ) then

		this:Hide();
		TimerArg = nil
  end
end

function SelectServerQuest_Frame_OnHiden()
	KillTimer("LoginSelectServerQuest_WaitTimer()")
	
	if(IsWindowShow("AntiJDY")) then          --简单游互斥界面显示时，不激活快捷键 for 69994
		DataPool:SetCanUseHotKey(0);
	else
		DataPool:SetCanUseHotKey(1);
	end
end

function SelectServerQuest_QuitClick()
	--PushEvent("QUENEQUIT_SELECT", 134, g_showbuttonStr);
	this:Hide()
end

function SelectServerQuest_BetterServerClick()
	PushEvent("QUENEQUIT_SELECT", 234, g_showbuttonStr);
	this:Hide()
end

function SelectServerQuest_DoSwitchGems( canBind )
    Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("DoSwitchGems")
		Set_XSCRIPT_ScriptID(701614)
        Set_XSCRIPT_Parameter( 0,  canBind  )
		Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT();
end

function SelectServerQuest_HappyTLTenYears(nParam1, nParam2, nParam3)
	g_iYesNoType = 78
	g_HappyTLTenYearsIndex = nParam1
	local ItemId = nParam2
	local NeedNum = nParam3
	local strText = ""
	local ItemName = DataPool:Lua_GetItemNameByIndex(ItemId)
	strText = ScriptGlobal_Format("#{TYQS_170424_88}", NeedNum, ItemName)
	SelectServerQuest_InfoWindow:SetText(strText)
	LoginSelectUpdateRect()
	SelectServerQuest_Button1:SetText("#{TYQS_170424_89}");
	SelectServerQuest_Button1:Show();
	SelectServerQuest_Button2:SetText("#{TYQS_170424_90}");
	SelectServerQuest_Button2:Show();
	this:Show();
end

function SelectServerQuest_JiuJiuXiaoHan_Summer(nParam1, nParam2, nParam3)
	g_iYesNoType = 79
	g_JiuJiuXiaoHan_Summer_Index = nParam1
	local ItemId = nParam2
	local NeedNum = nParam3
	local strText = ""
	local ItemName = DataPool:Lua_GetItemNameByIndex(ItemId)
	strText = ScriptGlobal_Format("#{QLSX_170620_85}", NeedNum, ItemName)
	SelectServerQuest_InfoWindow:SetText(strText)
	LoginSelectUpdateRect()
	SelectServerQuest_Button1:SetText("#{QLSX_170620_86}");
	SelectServerQuest_Button1:Show();
	SelectServerQuest_Button2:SetText("#{QLSX_170620_87}");
	SelectServerQuest_Button2:Show();
	this:Show();
end

function SelectServerQuest_HuoyueWeeklyGift(nParam)
	g_iYesNoType = 80
	g_HuoyueWeeklyGift_Index = nParam
	-- local ItemId = nParam2
	-- local NeedNum = nParam3
	-- local strText = ""
	-- local ItemName = DataPool:Lua_GetItemNameByIndex(ItemId)
	-- strText = ScriptGlobal_Format("#{QLSX_170620_85}", NeedNum, ItemName)
	SelectServerQuest_InfoWindow:SetText("#{BSTZ_170721_02}")
	LoginSelectUpdateRect()
	SelectServerQuest_Button1:SetText("#{BSTZ_170721_03}");
	SelectServerQuest_Button1:Show();
	SelectServerQuest_Button2:SetText("#{BSTZ_170721_04}");
	SelectServerQuest_Button2:Show();
	this:Show();
end

function SelectServerQuest_CatGift_Confirm(nParam1, nParam2, nParam3, nParam4)
	g_iYesNoType = 127;
	g_MissionIndex = nParam1
	g_CatId[1] = nParam2
	g_CatId[2] = nParam3
	g_CatId[3] = nParam4
	SelectServerQuest_InfoWindow:SetText("#{YMTB_210520_125}");
	LoginSelectUpdateRect();
	SelectServerQuest_Button1:SetText("#{YMTB_210520_126}");
	SelectServerQuest_Button1:Show();
	SelectServerQuest_Button2:SetText("#{YMTB_210520_127}");
	SelectServerQuest_Button2:Show();
	this:Show();
end
function SelectServerQuest_CatGift_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnPaiQianConfirm" )
		Set_XSCRIPT_ScriptID( 888438 )
		Set_XSCRIPT_Parameter(0,g_MissionIndex)
		Set_XSCRIPT_Parameter(1,g_CatId[1])
		Set_XSCRIPT_Parameter(2,g_CatId[2])
		Set_XSCRIPT_Parameter(3,g_CatId[3])
		Set_XSCRIPT_Parameter(4,1)
		Set_XSCRIPT_ParamCount( 5 )
	Send_XSCRIPT()
end

function SelectServerQuest_JiuJiuXiaoHan_Spring(nParam1, nParam2, nParam3)
	g_iYesNoType = 132
	g_JiuJiuXiaoHan_Summer_Index = nParam1
	local ItemId = nParam2
	local NeedNum = nParam3
	local strText = ""
	local ItemName = DataPool:Lua_GetItemNameByIndex(ItemId)
	strText = ScriptGlobal_Format("#{CFSN_220224_101}", NeedNum, ItemName)
	SelectServerQuest_InfoWindow:SetText(strText)
	LoginSelectUpdateRect()
	SelectServerQuest_Button1:SetText("#{CFSN_220224_102}");
	SelectServerQuest_Button1:Show();
	SelectServerQuest_Button2:SetText("#{CFSN_220224_103}");
	SelectServerQuest_Button2:Show();
	this:Show();
end

function LoginSelectServerQuest_Init_LOGIN_MUST_WAIT( nType, nWaitSec, nErrCode )
	g_iYesNoType = nType;
	g_nWaitSec = nWaitSec;
	g_nWaitErrCode = nErrCode;
	SetTimer("LoginSelectServerQuest","LoginSelectServerQuest_WaitTimer()", 1000)
end

function LoginSelectServerQuest_WaitTimer()
	if g_iYesNoType == 159 and g_nWaitSec > 1 then
		g_nWaitSec = g_nWaitSec - 1;
		local szText = ScriptGlobal_Format("#{DLYH_180224_01}",tostring(g_nWaitSec))
		SelectServerQuest_InfoWindow:SetText(szText.."("..g_nWaitErrCode..")");	
	else
		KillTimer("LoginSelectServerQuest_WaitTimer()")
		this:Hide();
	end
end
