local g_SummerVacation_FrameNULL_UnifiedXPosition = 0
local g_DataTime = 20211104
local g_prizeflag={0,0,0,0,0,0,0}
local g_SummerVacation_ActionButton = {};
local g_SummerVacation_Prizes={
[1]={id = 39920181, num = 1,  date = 20211029, namestr = "#{SJFL_150608_52}"},         
[2]={id = 39920085, num = 10,  date = 20211030, namestr = "#{SJFL_150608_53}"},		  
[3]={id = 39920396, num = 1,  date = 20211031, namestr = "#{SJFL_150608_54}"},		  
[4]={id = 39920181, num = 1,  date = 20211101, namestr = "#{SJFL_150608_55}"},         
[5]={id = 39920298, num = 2,  date = 20211102, namestr = "#{SJFL_150608_56}"},		  
[6]={id = 39920397, num = 1,  date = 20211103, namestr = "#{SJFL_150608_57}"},		  
[7]={id = 39920977, num = 1,  date = 20211104, namestr = "#{SJFL_150608_66}"},	
}
local g_SummerVacation_Btn ={
	[1] = {prize = "",
		   btn = "",
		   tips = "",
		   mark = "",
		   text = "",
		   resign = "",
	},
	[2] = {prize = "",
		   btn = "",
		   tips = "",
		   mark = "",
		   text = "",
		   resign = "",
	},
	[3] = {prize = "",
		   btn = "",
		   tips = "",
		   mark = "",
		   text = "",
		   resign = "",
	},
	[4] = {prize = "",
		   btn = "",
		   tips = "",
		   mark = "",
		   text = "",
		   resign = "",
	},
	[5] = {prize = "",
		   btn = "",
		   tips = "",
		   mark = "",
		   text = "",
		   resign = "",
	},
	[6] = {prize = "",
		   btn = "",
		   tips = "",
		   mark = "",
		   text = "",
		   resign = "",
	},
	[7] = {prize = "",
		   btn = "",
		   tips = "",
		   mark = "",
		   text = "",
		   resign = "",
	},
}

local g_BtnImage = {
									"set:NationalDay image:AnniversaryLotteryButton_Pushed",
									"set:NationalDay image:AnniversaryLotteryButton_Normal",
									"set:NationalDay image:AnniversaryLotteryButton_Hover"
								}


local g_BtnToolTips = {
									"#{SJFL_150608_35}",
									"#{SJFL_150608_36}",
									"#{SJFL_150608_37}",
									"#{SJFL_150608_38}",
									"#{SJFL_150608_39}",
									"#{SJFL_150608_40}",
									"#{SJFL_150608_40}"
								}

local g_SummerVacation_tabs = {}

local g_curPage = 0

local g_ButtonPos = {
											[1] = {x =0, y = 0},
											[2] = {x =0, y = 0},
											[3] = {x =0, y = 0},
											[4] = {x =0, y = 0},
											[5] = {x =0, y = 0},
											[6] = {x =0, y = 0},
										}
local g_SummerVacation_ButtontabBK = {}
							
local g_StartDayTime = 20260813 --	 盛宴狂欢按钮显示时间
local g_EndDayTime = 20260912 --	 盛宴狂欢按钮显示时间

local g_PageShowEndTime1 = 20211104 --登录有礼页签显示时间
local g_PageShowEndTime2 = 20260823 --黄金逆袭页签显示时间
local g_PageShowEndTime3 = 20260826 --双倍内息显示时间
----多倍助力--------
local g_zhuli_curstate = 0
local g_zhuli_curcount = 0
local g_zhuli_reward_flag = {0,0,0,0}
local g_zhuli_reward_item = {39922698,39922702,39922703,39922704}

local g_zhuli_stage = {
	[1] = {Image = "", curstr = "#{DBLL_200628_08}", nextstr = ""}, --1105~1108
	[2] = {Image = "set:BK_LiLianHuiKui image:16", curstr = "#{DBLL_200628_08}", nextstr = "#{DBLL_200628_14}"},--1109~1115
	[3] = {Image = "set:BK_LiLianHuiKui image:18", curstr = "#{DBLL_200628_08}", nextstr = "#{DBLL_200628_15}"},--1116~1122
	[4] = {Image = "set:BK_LiLianHuiKui image:2", curstr = "#{DBLL_200628_08}", nextstr = "#{DBLL_200628_72}"},--1123~1129 (27号特殊更新需修改字典)
	[5] = {Image = "set:BK_LiLianHuiKui image:2", curstr = "#{DBLL_200628_08}", nextstr = "#{DBLL_200628_16}"},--1130~1220
}			

local g_Zhuli_ActionButton = {}	
local g_Zhuli_GetImage = {}	
local g_Zhuli_Animate = {}	
local g_Zhuli_RewardText = {}
local g_Zhuli_ZhuliText = {}
		

local g_zhuli_StartDayTime	=	20260813
local g_zhuli_EndDayTime	=	20260912

local g_zhuli_RewardTextList = {
	[1] = {time="#{DBLL_200628_49}", nexttime="#{DBLL_200628_18}", zhuli="#{DBLL_200628_53}", nextzhuli="#{DBLL_200628_45}"},
	[2] = {time="#{DBLL_200628_50}", nexttime="#{DBLL_200628_19}", zhuli="#{DBLL_200628_54}", nextzhuli="#{DBLL_200628_46}"},
	[3] = {time="#{DBLL_200628_51}", nexttime="#{DBLL_200628_20}", zhuli="#{DBLL_200628_55}", nextzhuli="#{DBLL_200628_47}"},
	[4] = {time="#{DBLL_200628_52}", nexttime="#{DBLL_200628_21}", zhuli="#{DBLL_200628_56}", nextzhuli="#{DBLL_200628_48}"},
}
function SummerVacation_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("ADJEST_UI_POS",false)

	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("UPDATE_BASE_SHANHAIBI",false)
end

function SummerVacation_OnLoad()
	g_SummerVacation_Btn[1].prize = SummerVacation_Page1_one
	g_SummerVacation_Btn[1].btn = SummerVacation_one_Button
	g_SummerVacation_Btn[1].tips = SummerVacation_one_ButtonTip
	g_SummerVacation_Btn[1].mark = SummerVacation_Page1_oneMark
	g_SummerVacation_Btn[1].text = SummerVacation_Page1_one_LotteryButtonText
	g_SummerVacation_Btn[1].resign = SummerVacation_Page1_oneResign
	
	g_SummerVacation_Btn[2].prize = SummerVacation_Page1_two
	g_SummerVacation_Btn[2].btn = SummerVacation_two_Button
	g_SummerVacation_Btn[2].tips = SummerVacation_two_ButtonTip
	g_SummerVacation_Btn[2].mark = SummerVacation_Page1_twoMark
	g_SummerVacation_Btn[2].text = SummerVacation_Page1_two_LotteryButtonText
	g_SummerVacation_Btn[2].resign = SummerVacation_Page1_twoResign

	g_SummerVacation_Btn[3].prize = SummerVacation_Page1_three
	g_SummerVacation_Btn[3].btn = SummerVacation_three_Button
	g_SummerVacation_Btn[3].tips = SummerVacation_three_ButtonTip
	g_SummerVacation_Btn[3].mark = SummerVacation_Page1_threeMark
	g_SummerVacation_Btn[3].text = SummerVacation_Page1_three_LotteryButtonText
	g_SummerVacation_Btn[3].resign = SummerVacation_Page1_threeResign
	
	g_SummerVacation_Btn[4].prize = SummerVacation_Page1_four
	g_SummerVacation_Btn[4].btn = SummerVacation_four_Button
	g_SummerVacation_Btn[4].tips = SummerVacation_four_ButtonTip
	g_SummerVacation_Btn[4].mark = SummerVacation_Page1_fourMark
	g_SummerVacation_Btn[4].text = SummerVacation_Page1_four_LotteryButtonText
	g_SummerVacation_Btn[4].resign = SummerVacation_Page1_fourResign
	
	g_SummerVacation_Btn[5].prize = SummerVacation_Page1_five
	g_SummerVacation_Btn[5].btn = SummerVacation_five_Button
	g_SummerVacation_Btn[5].tips = SummerVacation_five_ButtonTip
	g_SummerVacation_Btn[5].mark = SummerVacation_Page1_fiveMark
	g_SummerVacation_Btn[5].text = SummerVacation_Page1_five_LotteryButtonText
	g_SummerVacation_Btn[5].resign = SummerVacation_Page1_fiveResign
	
	g_SummerVacation_Btn[6].prize = SummerVacation_Page1_six
	g_SummerVacation_Btn[6].btn = SummerVacation_six_Button
	g_SummerVacation_Btn[6].tips = SummerVacation_six_ButtonTip
	g_SummerVacation_Btn[6].mark = SummerVacation_Page1_sixMark
	g_SummerVacation_Btn[6].text = SummerVacation_sixText
	g_SummerVacation_Btn[6].resign = SummerVacation_Page1_sixResign
	
	g_SummerVacation_Btn[7].prize = SummerVacation_Page1_seven
	g_SummerVacation_Btn[7].btn = SummerVacation_seven_Button
	g_SummerVacation_Btn[7].tips = SummerVacation_seven_ButtonTip
	g_SummerVacation_Btn[7].mark = SummerVacation_Page1_sevenMark
	g_SummerVacation_Btn[7].text = SummerVacation_sevenText
	g_SummerVacation_Btn[7].resign = SummerVacation_Page1_sevevResign
	
	g_SummerVacation_ActionButton[1] = SummerVacation_HJNXReward_item1
	g_SummerVacation_ActionButton[2] = SummerVacation_HJNXReward_item2
	g_SummerVacation_ActionButton[3] = SummerVacation_HJNXReward_item3
	g_SummerVacation_ActionButton[4] = SummerVacation_HJNXReward_item4
	g_SummerVacation_ActionButton[5] = SummerVacation_HJNXReward_item5
	g_SummerVacation_ActionButton[6] = SummerVacation_HJNXReward_item6
	
	g_SummerVacation_tabs[1] = SummerVacation_Buttontab01
	g_SummerVacation_tabs[2] = SummerVacation_Buttontab02
	g_SummerVacation_tabs[3] = SummerVacation_Buttontab03
	g_SummerVacation_tabs[4] = SummerVacation_Buttontab04
	g_SummerVacation_tabs[5] = SummerVacation_Buttontab05
	
	SummerVacation_Client1:Show()
	SummerVacation_Client2:Hide()
	SummerVacation_Client3:Hide()
	SummerVacation_Client4:Hide()
	SummerVacation_Client5:Hide()
	SummerVacation_Client6:Hide()
	
	g_SummerVacation_ButtontabBK[1] = SummerVacation_Buttontab01BK --登陆有礼
	g_SummerVacation_ButtontabBK[2] = SummerVacation_Buttontab03BK --双倍欢享
	g_SummerVacation_ButtontabBK[3] = SummerVacation_Buttontab05BK --黄金逆袭
	g_SummerVacation_ButtontabBK[4] = SummerVacation_Buttontab04BK --历练回馈
	g_SummerVacation_ButtontabBK[5] = SummerVacation_Buttontab02BK --双倍内息
	
	g_SummerVacation_FrameNULL_UnifiedXPosition = SummerVacation_FrameNULL:GetProperty("UnifiedXPosition")
	g_SummerVacation_FrameNULL_UnifiedYPosition = SummerVacation_FrameNULL:GetProperty("UnifiedYPosition")

	g_ButtonPos[1].x	= g_SummerVacation_ButtontabBK[1]:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= g_SummerVacation_ButtontabBK[1]:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[2].x	= g_SummerVacation_ButtontabBK[2]:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= g_SummerVacation_ButtontabBK[2]:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[3].x	= g_SummerVacation_ButtontabBK[3]:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= g_SummerVacation_ButtontabBK[3]:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[4].x	= g_SummerVacation_ButtontabBK[4]:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= g_SummerVacation_ButtontabBK[4]:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[5].x	= g_SummerVacation_ButtontabBK[5]:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= g_SummerVacation_ButtontabBK[5]:GetProperty("UnifiedYPosition");
	
	g_ButtonPos[6].x	= SummerVacation_Buttontab02_Line2:GetProperty("UnifiedXPosition"); --尾巴
	g_ButtonPos[6].y	= SummerVacation_Buttontab02_Line2:GetProperty("UnifiedYPosition");
	
	SummerVacation_Zhuli_OnLoad()
end

function SummerVacation_ResetPos()
	SummerVacation_FrameNULL : SetProperty("UnifiedXPosition", g_SummerVacation_FrameNULL_UnifiedXPosition);
	SummerVacation_FrameNULL : SetProperty("UnifiedYPosition", g_SummerVacation_FrameNULL_UnifiedYPosition);
end

function SummerVacation_OnEvent(event)
	if( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif( event == "ADJEST_UI_POS" ) then
		SummerVacation_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SummerVacation_ResetPos()
	elseif(event == "UI_COMMAND" ) and ( tonumber(arg0) == 2015060803 ) and (IsWindowShow("SummerVacation")) then
		if Get_XParam_INT(0) == 1 then
			SummerVacation_Buttontab01_Tips:Show();
		else
			SummerVacation_Buttontab01_Tips:Hide();
		end
	elseif(event == "UI_COMMAND" ) and ( tonumber(arg0) == 2015060802 ) then
			if Get_XParam_INT(0) == 1 then
			    g_curPage = 1
				for i = 1,7 do
					g_prizeflag[i] = Get_XParam_INT(i)
				end
				
				g_DataTime = Get_XParam_INT(8)			
					
				SummerVacation_Buttontab01_Tips:Hide()
				
				for i=1,7 do
					g_SummerVacation_Btn[i].tips:Hide()
					g_SummerVacation_Btn[i].resign:Hide()
					g_SummerVacation_Btn[i].mark:Hide()
					g_SummerVacation_Btn[i].text:SetText("#{SJFL_150608_58}")
					
					local theAction = DataPool:CreateActionItemForShow(g_SummerVacation_Prizes[i].id, g_SummerVacation_Prizes[i].num)
					if theAction:GetID() ~= 0 then
						g_SummerVacation_Btn[i].prize:SetActionItem(theAction:GetID());
					end			
					if g_prizeflag[i] == 1 then
						g_SummerVacation_Btn[i].btn:SetProperty("DisabledImage","set:NationalDay image:AnniversaryLotteryButton_Pushed")
						g_SummerVacation_Btn[i].btn:Disable()
						g_SummerVacation_Btn[i].mark:Show()
						g_SummerVacation_Btn[i].text:SetText("#{SJFL_150608_59}")
						
					elseif Get_XParam_INT(8) > g_SummerVacation_Prizes[i].date then						
						g_SummerVacation_Btn[i].btn:SetProperty("PushedImage", g_BtnImage[1])
						g_SummerVacation_Btn[i].btn:SetProperty("NormalImage", g_BtnImage[2])
						g_SummerVacation_Btn[i].btn:SetProperty("HoverImage", g_BtnImage[3])
						g_SummerVacation_Btn[i].text:SetText("#{SJFL_150608_60}")
						g_SummerVacation_Btn[i].resign:Show()
						
						--改变tooltips
						if i< 7 then
							g_SummerVacation_Btn[i].btn:SetToolTip(g_BtnToolTips[i])
						end
						
						g_SummerVacation_Btn[i].btn:Enable()	
					elseif Get_XParam_INT(8) == g_SummerVacation_Prizes[i].date then	
						g_SummerVacation_Btn[i].btn:Enable()	
						if Player:GetLevel() >= 15 then
							g_SummerVacation_Btn[i].tips:Show()
						end
					else
						g_SummerVacation_Btn[i].btn:Enable()
					end					
				end		
			else
				g_DataTime = Get_XParam_INT(1)
			end
	
			DataPool:Lua_ClearSXKH_NixiActionItem();
			for i = 1 , 6 do
				g_SummerVacation_ActionButton[i]:SetActionItem(-1)
			end
			if Player:GetData("Is2606S") == 1 then
				DataPool:Lua_SetSXKH_NixiActionItem( 0, 39921546 );
				DataPool:Lua_SetSXKH_NixiActionItem( 1, 39920085 );
				DataPool:Lua_UpdateSXKH_NixiActionItem();
				for i = 1 , 2 do
					local theAction = EnumAction(i - 1, "sxkh_nixi")
					if theAction:GetID() ~= 0 then	
						g_SummerVacation_ActionButton[i]:SetActionItem(theAction:GetID())
					end
				end
			else
				DataPool:Lua_SetSXKH_NixiActionItem( 0, 39921309 );
				DataPool:Lua_SetSXKH_NixiActionItem( 1, 39921546 );
				DataPool:Lua_SetSXKH_NixiActionItem( 2, 39920959 );
				DataPool:Lua_SetSXKH_NixiActionItem( 3, 39920946 );
				DataPool:Lua_SetSXKH_NixiActionItem( 4, 39920947 );
				DataPool:Lua_SetSXKH_NixiActionItem( 5, 39920085 );
				DataPool:Lua_UpdateSXKH_NixiActionItem();
				for i = 1 , 6 do
					local theAction = EnumAction(i - 1, "sxkh_nixi")
					if theAction:GetID() ~= 0 then	
						g_SummerVacation_ActionButton[i]:SetActionItem(theAction:GetID())
					end
				end			
			end
			-- 页签更新
			if KaJi:LuaFnIsKaJiServer() == 1 or Player:GetData("IsOriginalJD") == 1 or Player:GetData("Is2606S") == 1 then
				SummerVacation_UpdatePage_Kaji() --卡级
			else
				SummerVacation_UpdatePage()
			end
				
			-- 界面更新
			SummerVacation_UpdateRightClient()

			this:Show()			
				
	elseif (this:IsVisible()) and (event == "UI_COMMAND" ) and ( tonumber(arg0) == 8880911 ) then --多倍历练
		if Get_XParam_INT(0) == 1 then
			g_zhuli_curstate = Get_XParam_INT( 1 )
			g_zhuli_curcount = Get_XParam_INT( 2 )
			for i = 1, 4 do
				g_zhuli_reward_flag[i] = Get_XParam_INT( 2+i )
			end
			SummerVacation_Zhuli_Flush()
			
		end
	elseif(event == "UI_COMMAND" ) and ( tonumber(arg0) == 8880912 ) and (IsWindowShow("SummerVacation")) then
		if Get_XParam_INT(0) == 1 then
			SummerVacation_Buttontab04_Tips:Show();
		else
			SummerVacation_Buttontab04_Tips:Hide();
		end
	elseif (this:IsVisible()) and (event == "UPDATE_BASE_SHANHAIBI" ) and ( g_curPage == 5 ) then --历练值更新
		SummerVacation_Zhuli_Flush()
	end
end

function SummerVacation_OnClick(ClickId)
	
	--检查按钮范围值
	if ClickId < 1 or ClickId > 7 then
		return
	end
	
	if g_DataTime > g_SummerVacation_Prizes[ClickId].date then
		if g_prizeflag[ClickId] == 1 then
			PushDebugMessage( "#{SJFL_150608_26}" )
			return
		end
		
		local itemname = g_SummerVacation_Prizes[ClickId].namestr; --PlayerPackage:GetItemName(g_SummerVacation_Prizes[ClickId].id);
		local num =g_SummerVacation_Prizes[ClickId].num
		local strInfo = ScriptGlobal_Format("#{SJFL_150608_45}", num,itemname)
		
		PushEvent( "RESIGN_SUMMERVACATION" , ClickId, strInfo);
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetPrize")  
			Set_XSCRIPT_ScriptID(891205) 
			Set_XSCRIPT_Parameter(0,ClickId);
			Set_XSCRIPT_Parameter(1,0);
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
	
end

--刷新页签
function SummerVacation_UpdatePage()
	for i = 1, table.getn(g_SummerVacation_ButtontabBK)	do
		g_SummerVacation_ButtontabBK[i]:Show()
	end
	local curDayTime = g_DataTime
	--if curDayTime >= g_StartDayTime and curDayTime <= g_PageShowEndTime1 then
		
	--	g_SummerVacation_ButtontabBK[1]:SetProperty("UnifiedXPosition", g_ButtonPos[1].x);
	--	g_SummerVacation_ButtontabBK[1]:SetProperty("UnifiedYPosition", g_ButtonPos[1].y);

	--	g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedXPosition", g_ButtonPos[2].x);
	--	g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedYPosition", g_ButtonPos[2].y);
		
	--	g_SummerVacation_ButtontabBK[5]:SetProperty("UnifiedXPosition", g_ButtonPos[3].x);
	--	g_SummerVacation_ButtontabBK[5]:SetProperty("UnifiedYPosition", g_ButtonPos[3].y);
		
	--	g_SummerVacation_ButtontabBK[4]:SetProperty("UnifiedXPosition", g_ButtonPos[4].x);
	--	g_SummerVacation_ButtontabBK[4]:SetProperty("UnifiedYPosition", g_ButtonPos[4].y);
		
	--	g_SummerVacation_ButtontabBK[3]:SetProperty("UnifiedXPosition", g_ButtonPos[5].x);
	--	g_SummerVacation_ButtontabBK[3]:SetProperty("UnifiedYPosition", g_ButtonPos[5].y);
		
	--	SummerVacation_Buttontab02_Line2:SetProperty("UnifiedXPosition", g_ButtonPos[6].x);
	--	SummerVacation_Buttontab02_Line2:SetProperty("UnifiedYPosition", g_ButtonPos[6].y);

	if curDayTime >= g_StartDayTime and curDayTime <= g_PageShowEndTime2 then
		g_SummerVacation_ButtontabBK[1]:Hide()
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedXPosition", g_ButtonPos[1].x);
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedYPosition", g_ButtonPos[1].y);
		
		g_SummerVacation_ButtontabBK[5]:SetProperty("UnifiedXPosition", g_ButtonPos[2].x);
		g_SummerVacation_ButtontabBK[5]:SetProperty("UnifiedYPosition", g_ButtonPos[2].y);
		
		g_SummerVacation_ButtontabBK[4]:SetProperty("UnifiedXPosition", g_ButtonPos[3].x);
		g_SummerVacation_ButtontabBK[4]:SetProperty("UnifiedYPosition", g_ButtonPos[3].y);
		
		g_SummerVacation_ButtontabBK[3]:SetProperty("UnifiedXPosition", g_ButtonPos[4].x);
		g_SummerVacation_ButtontabBK[3]:SetProperty("UnifiedYPosition", g_ButtonPos[4].y);
		
		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedXPosition", g_ButtonPos[5].x);
		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedYPosition", g_ButtonPos[5].y);
		
	elseif curDayTime > g_PageShowEndTime2 and curDayTime <= g_PageShowEndTime3 then
		g_SummerVacation_ButtontabBK[1]:Hide()
		g_SummerVacation_ButtontabBK[3]:Hide()
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedXPosition", g_ButtonPos[1].x);
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedYPosition", g_ButtonPos[1].y);
		
		g_SummerVacation_ButtontabBK[5]:SetProperty("UnifiedXPosition", g_ButtonPos[2].x);
		g_SummerVacation_ButtontabBK[5]:SetProperty("UnifiedYPosition", g_ButtonPos[2].y);
		
		g_SummerVacation_ButtontabBK[4]:SetProperty("UnifiedXPosition", g_ButtonPos[3].x);
		g_SummerVacation_ButtontabBK[4]:SetProperty("UnifiedYPosition", g_ButtonPos[3].y);
		
		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedXPosition", g_ButtonPos[4].x);
		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedYPosition", g_ButtonPos[4].y);
	elseif curDayTime > g_PageShowEndTime3 and curDayTime <= g_EndDayTime then
		g_SummerVacation_ButtontabBK[1]:Hide()
		g_SummerVacation_ButtontabBK[3]:Hide()
		g_SummerVacation_ButtontabBK[5]:Hide()
		
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedXPosition", g_ButtonPos[1].x);
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedYPosition", g_ButtonPos[1].y);
		
		g_SummerVacation_ButtontabBK[4]:SetProperty("UnifiedXPosition", g_ButtonPos[2].x);
		g_SummerVacation_ButtontabBK[4]:SetProperty("UnifiedYPosition", g_ButtonPos[2].y);
		
		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedXPosition", g_ButtonPos[3].x);
		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedYPosition", g_ButtonPos[3].y);
	end
	
	
end

--刷新页签
function SummerVacation_UpdatePage_Kaji()
	for i = 1, table.getn(g_SummerVacation_ButtontabBK)	do
		g_SummerVacation_ButtontabBK[i]:Show()
	end
	
	g_SummerVacation_ButtontabBK[5]:Hide()
	g_SummerVacation_ButtontabBK[4]:Hide()
	
	local curDayTime = g_DataTime
	--if curDayTime >= g_StartDayTime and curDayTime <= g_PageShowEndTime1 then
		
	--	g_SummerVacation_ButtontabBK[1]:SetProperty("UnifiedXPosition", g_ButtonPos[1].x);
	--	g_SummerVacation_ButtontabBK[1]:SetProperty("UnifiedYPosition", g_ButtonPos[1].y);

	--	g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedXPosition", g_ButtonPos[2].x);
	--	g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedYPosition", g_ButtonPos[2].y);
		
	--	g_SummerVacation_ButtontabBK[3]:SetProperty("UnifiedXPosition", g_ButtonPos[3].x);
	--	g_SummerVacation_ButtontabBK[3]:SetProperty("UnifiedYPosition", g_ButtonPos[3].y);
		
	--	SummerVacation_Buttontab02_Line2:SetProperty("UnifiedXPosition", g_ButtonPos[4].x);
	--	SummerVacation_Buttontab02_Line2:SetProperty("UnifiedYPosition", g_ButtonPos[4].y);

	if curDayTime >= g_StartDayTime and curDayTime <= g_PageShowEndTime2 then
		g_SummerVacation_ButtontabBK[1]:Hide()
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedXPosition", g_ButtonPos[1].x);
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedYPosition", g_ButtonPos[1].y);
				
		g_SummerVacation_ButtontabBK[3]:SetProperty("UnifiedXPosition", g_ButtonPos[2].x);
		g_SummerVacation_ButtontabBK[3]:SetProperty("UnifiedYPosition", g_ButtonPos[2].y);
		
		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedXPosition", g_ButtonPos[3].x);
		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedYPosition", g_ButtonPos[3].y);
		
	elseif curDayTime > g_PageShowEndTime2 and curDayTime <= g_EndDayTime then
		g_SummerVacation_ButtontabBK[1]:Hide()
		g_SummerVacation_ButtontabBK[3]:Hide()
		
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedXPosition", g_ButtonPos[1].x);
		g_SummerVacation_ButtontabBK[2]:SetProperty("UnifiedYPosition", g_ButtonPos[1].y);

		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedXPosition", g_ButtonPos[2].x);
		SummerVacation_Buttontab02_Line2:SetProperty("UnifiedYPosition", g_ButtonPos[2].y);
	end
	
	
end
function SummerVacation_UpdateRightClient()
	local curDayTime = g_DataTime
	--if curDayTime >= g_StartDayTime and curDayTime <= g_PageShowEndTime1 then
	--	SummerVacation_firstShow()
	--elseif curDayTime > g_PageShowEndTime1 and curDayTime <= g_EndDayTime then
	if curDayTime >= g_StartDayTime and curDayTime <= g_EndDayTime then
		SummerVacation_thirdShow()
	end
end
-- 登陆有礼
function SummerVacation_firstShow()	
	g_curPage = 2
	SummerVacation_Client1:Show()
	SummerVacation_Client2:Hide()
	SummerVacation_Client3:Hide()
	SummerVacation_Client4:Hide()
	SummerVacation_Client5:Hide()
	SummerVacation_Client6:Hide()
	
	g_SummerVacation_tabs[1]:SetCheck(1)
	g_SummerVacation_tabs[2]:SetCheck(0)
	g_SummerVacation_tabs[3]:SetCheck(0)
	g_SummerVacation_tabs[4]:SetCheck(0)
	g_SummerVacation_tabs[5]:SetCheck(0)
	
end

-- 双倍武意
function SummerVacation_SecShow()	
	g_curPage = 3		
	SummerVacation_Client1:Hide()
	SummerVacation_Client2:Hide()
	SummerVacation_Client3:Show()
	SummerVacation_Client4:Hide()
	SummerVacation_Client5:Hide()
	SummerVacation_Client6:Hide()
	
	g_SummerVacation_tabs[1]:SetCheck(0)
	g_SummerVacation_tabs[2]:SetCheck(1)
	g_SummerVacation_tabs[3]:SetCheck(0)
	g_SummerVacation_tabs[4]:SetCheck(0)
	g_SummerVacation_tabs[5]:SetCheck(0)
end

-- 双倍狂欢
function SummerVacation_thirdShow()
	g_curPage = 4
	SummerVacation_Client1:Hide()
	SummerVacation_Client2:Hide()
	SummerVacation_Client3:Hide()
	SummerVacation_Client4:Hide()	
	SummerVacation_Client5:Hide()
	SummerVacation_Client6:Hide()
	if Player:GetData("Is2606S") == 1 then
		SummerVacation_Client6:Show()
	else
		SummerVacation_Client2:Show()
	end
	g_SummerVacation_tabs[1]:SetCheck(0)
	g_SummerVacation_tabs[2]:SetCheck(0)
	g_SummerVacation_tabs[3]:SetCheck(1)
	g_SummerVacation_tabs[4]:SetCheck(0)
	g_SummerVacation_tabs[5]:SetCheck(0)
end

-- 多倍历练
function SummerVacation_fourthShow()
	local curDay = DataPool:GetServerDayTime()	
	if curDay < g_zhuli_StartDayTime then
		PushDebugMessage("#{DBLL_200628_02}")
		g_SummerVacation_tabs[4]:SetCheck(0)
		return
	elseif curDay > g_zhuli_EndDayTime then
		PushDebugMessage("#{DBLL_200628_02}")
		g_SummerVacation_tabs[4]:SetCheck(0)
		return
	else
		local nLevel = Player:GetLevel();
		if nLevel < 30 then
			PushDebugMessage("#{DBLL_200628_03}")
			g_SummerVacation_tabs[4]:SetCheck(0)
			return
		end
	end
	g_curPage = 5		
	SummerVacation_Client1:Hide()
	SummerVacation_Client2:Hide()
	SummerVacation_Client3:Hide()
	
	SummerVacation_Client4:Hide()
	SummerVacation_Client5:Show()
	SummerVacation_Client6:Hide()
	
	g_SummerVacation_tabs[1]:SetCheck(0)
	g_SummerVacation_tabs[2]:SetCheck(0)
	g_SummerVacation_tabs[3]:SetCheck(0)
	g_SummerVacation_tabs[4]:SetCheck(1)
	g_SummerVacation_tabs[5]:SetCheck(0)
	
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenUI")  
			Set_XSCRIPT_ScriptID(888091) 
			Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function SummerVacation_Zhuli_OnLoad()
	g_Zhuli_ActionButton[1] = SummerVacation5_MZXHLReward_Button1
	g_Zhuli_ActionButton[2] = SummerVacation5_MZXHLReward_Button2
	g_Zhuli_ActionButton[3] = SummerVacation5_MZXHLReward_Button3
	g_Zhuli_ActionButton[4] = SummerVacation5_MZXHLReward_Button4
	
	g_Zhuli_GetImage[1] = SummerVacation5_MZXHLReward_Get1
	g_Zhuli_GetImage[2] = SummerVacation5_MZXHLReward_Get2
	g_Zhuli_GetImage[3] = SummerVacation5_MZXHLReward_Get3
	g_Zhuli_GetImage[4] = SummerVacation5_MZXHLReward_Get4
	
	g_Zhuli_Animate[1] = SummerVacation5_MZXHLReward_Button1_Animate
	g_Zhuli_Animate[2] = SummerVacation5_MZXHLReward_Button2_Animate
	g_Zhuli_Animate[3] = SummerVacation5_MZXHLReward_Button3_Animate
	g_Zhuli_Animate[4] = SummerVacation5_MZXHLReward_Button4_Animate
	
	g_Zhuli_RewardText[1] = SummerVacation5_MZXHLReward_Text1
	g_Zhuli_RewardText[2] = SummerVacation5_MZXHLReward_Text2
	g_Zhuli_RewardText[3] = SummerVacation5_MZXHLReward_Text3
	g_Zhuli_RewardText[4] = SummerVacation5_MZXHLReward_Text4
	

	g_Zhuli_ZhuliText[1] = SummerVacation5_MZXHLReward_Text2_2
	g_Zhuli_ZhuliText[2] = SummerVacation5_MZXHLReward_Text3_3
	g_Zhuli_ZhuliText[3] = SummerVacation5_MZXHLReward_Text4_4

	
end

function SummerVacation_Zhuli_Flush()
	if g_zhuli_curstate <= 0 then
		return
	end
	local curDay = tonumber(DataPool:GetServerDayTime())

	for i = 1, table.getn(g_Zhuli_ZhuliText) do
		g_Zhuli_ZhuliText[i]:SetText("")
	end
	
	SummerVacation_Text5_Time:SetText(g_zhuli_stage[g_zhuli_curstate].curstr)

	if g_zhuli_curstate == 1 then
		SummerVacation_Client5_Image3:Show()
		SummerVacation_Client5_Image4:Hide()
		SummerVacation_Add5_1:Hide()
	else
		SummerVacation_Client5_Image3:Hide()
		SummerVacation_Client5_Image4:Show()	
		SummerVacation_Add5_1:Show()
		SummerVacation_Add5_1:SetProperty("Image", g_zhuli_stage[g_zhuli_curstate].Image)
	end
	
	
	local text = ""
	--if g_zhuli_curstate < 4 then
	--	text = ScriptGlobal_Format(g_zhuli_stage[g_zhuli_curstate].nextstr, g_zhuli_curcount)
	--else
	--text = g_zhuli_stage[g_zhuli_curstate].nextstr
	--end
	--SummerVacation_Add5_2:SetText(text)
	
	for i = 1, 4 do
		local theAction = DataPool:CreateActionItemForShow(g_zhuli_reward_item[i], 1)
		if theAction:GetID() ~= 0 then
			g_Zhuli_ActionButton[i]:SetActionItem( theAction:GetID() );
		end
		if g_zhuli_reward_flag[i] == 1 then --已领取
			g_Zhuli_GetImage[i]:Show()
			g_Zhuli_Animate[i]:Hide()
		else
			if i <= g_zhuli_curstate then --可领取
				g_Zhuli_Animate[i]:Show()
			else
				g_Zhuli_Animate[i]:Hide()
			end
			g_Zhuli_GetImage[i]:Hide()
		end
		
		if i >= 1 then
			if i <= g_zhuli_curstate then
				g_Zhuli_RewardText[i]:SetText(g_zhuli_RewardTextList[i].time)
			else
				g_Zhuli_RewardText[i]:SetText(g_zhuli_RewardTextList[i].nexttime)
			end
		end
	end
	--历练值
	local value = DataPool:LuaFnGetBaseShanHaiBi()
	SummerVacation_Tips5:SetText(ScriptGlobal_Format("#{DBLL_200628_22}",value))
	--SummerVacation_Tips5:Hide()
	this:Show()
end
function SummerVacation_Zhuli_RewardClick(nIndex)
	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("GetReward")  
			Set_XSCRIPT_ScriptID(888091) 
			Set_XSCRIPT_Parameter(0,nIndex);
			Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

-- 黄金逆袭
function SummerVacation_fifthShow()		
	g_curPage = 6
	
	SummerVacation_Client1:Hide()
	SummerVacation_Client2:Hide()
	SummerVacation_Client3:Hide()
	
	SummerVacation_Client4:Show()
	SummerVacation_Client5:Hide()
	SummerVacation_Client6:Hide()
	
	g_SummerVacation_tabs[1]:SetCheck(0)
	g_SummerVacation_tabs[2]:SetCheck(0)
	g_SummerVacation_tabs[3]:SetCheck(0)
	g_SummerVacation_tabs[4]:SetCheck(0)
	g_SummerVacation_tabs[5]:SetCheck(1)
end

--关于双倍掉落 SJFL_150608_62  双倍掉落小问号
function SummerVacation_Client2_HelpClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")  
		Set_XSCRIPT_ScriptID(891205) 
		Set_XSCRIPT_Parameter(0,1);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--关于黄金逆袭  SJFL_150608_63 黄金逆袭小问号 
function SummerVacation_Client4_HelpClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")  
		Set_XSCRIPT_ScriptID(891205) 
		Set_XSCRIPT_Parameter(0,2);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function SummerVacation_Client5_HelpClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")  
		Set_XSCRIPT_ScriptID(891205) 
		Set_XSCRIPT_Parameter(0,3);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function SummerVacation_Client5_Help2Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowHelpText")  
		Set_XSCRIPT_ScriptID(891205) 
		Set_XSCRIPT_Parameter(0,4);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
function SummerVacation_OpenUrl()
	GameProduceLogin:OpenURL( "http://event.changyou.com/xtl/202007/summer/pc/index.shtml" )
end

function SummerVacation_OpenUrl2()
	GameProduceLogin:OpenURL( "http://event.changyou.com/xtl/202007/summer/pc/index.shtml" )
end

function SummerVacation_OnHiden()

	for i = 1 , 6 do
		g_SummerVacation_ActionButton[i]:SetActionItem(-1)
	end
	DataPool:Lua_ClearSXKH_NixiActionItem();	
	
end

function SummerVacation_Close()
	SummerVacation_OnHiden()
	this:Hide();
end
