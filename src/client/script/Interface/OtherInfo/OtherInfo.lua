
--师德相关ToolTip内容	--add by xindefeng
local g_ShiDeTbl = {
											[0] = {"无#r", "0#r", 0},
											[1] = {"初级师傅#r", "2#r", 30},
											[2] = {"中级师傅#r", "3#r", 35},
											[3] = {"高级师傅#r", "5#r", 50},
											[4] = {"一代名师#r", "8#r", 70}
										}

-- 界面的默认相对位置
local g_OtherInfo_Frame_UnifiedXPosition;
local g_OtherInfo_Frame_UnifiedYPosition;

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_OtherInfo_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = "#{RWYQ_150707_01}"},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = "#{RWYQ_150707_02}"},
	[6] = {Text = "#{XL_XML_35}",				NeedCheck = 0, Tip = "#{RWYQ_150707_03}"},
	[7] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = "#{RWYQ_150707_04}"},
	[8] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = "#{RWYQ_150707_05}"},
	[9] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_06}"},
	[10] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = "#{RWYQ_150707_07}"},
	[11] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_08}"},
	[12] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = "#{ZZZB_150811_114}"},
	[13] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = "#{WYXT_20170907_302}"},
	[14] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = "#{JXSQ_170829_217}"},
	[15] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = "#{NJBZ_220816_12}"},
	[16] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = "#{CPSJ_260112_2}"},
	[17] = {Text = "#{INTERFACE_XML_496}",		NeedCheck = 0, Tip = ""},
}

local g_OtherInfo_PageButton = {}
local g_OtherInfo_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}


function OtherInfo_PreLoad()

	-- 打开界面
	this:RegisterEvent("OPEN_OTHER_INFO",true);

	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UPDATE_DOUBLE_EXP",false);

	-- 任务数据发生变化
	this:RegisterEvent("UPDATE_MISSION_DATA",false);

	--玩家使用兽栏--add by xindefeng
	this:RegisterEvent("UPDATE_PET_EXTRANUM",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK",false);		--升级

	this:RegisterEvent("TOGGLE_UPDATE_INFANT",false); --子女有变化 刷新按钮状态

	this:RegisterEvent("FINISH_MISSION",false);
	
	this:RegisterEvent("MARTIAL_UPDATE",false)
	
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)

	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)

	this:RegisterEvent("ZONGMEN_DIZILEVEL_UPDATE", false)
end

function OtherInfo_OnLoad()

	-- OTHERINFO_TAB_TEXT = {
		-- [0] = "装备",
		-- "资料",
		-- "珍兽",
		-- "骑乘",
		-- "其他",
		-- "经脉",
	-- };

	-- 保存界面的默认相对位置
	g_OtherInfo_Frame_UnifiedXPosition	= OtherInfo_Frame : GetProperty("UnifiedXPosition");
	g_OtherInfo_Frame_UnifiedYPosition	= OtherInfo_Frame : GetProperty("UnifiedYPosition");

		
	g_OtherInfo_PageButton[1] = OtherInfo_SelfEquip
	g_OtherInfo_PageButton[2] = OtherInfo_SelfData
	g_OtherInfo_PageButton[3] = OtherInfo_Pet
	g_OtherInfo_PageButton[4] = OtherInfo_Infant
	g_OtherInfo_PageButton[5] = OtherInfo_Wuhun
	g_OtherInfo_PageButton[6] = OtherInfo_Xiulian
	g_OtherInfo_PageButton[7] = OtherInfo_Miji
	g_OtherInfo_PageButton[8] = OtherInfo_ZhenYuan
	g_OtherInfo_PageButton[9] = OtherInfo_JingMai
	g_OtherInfo_PageButton[10] = OtherInfo_ShenDing
	g_OtherInfo_PageButton[11] = OtherInfo_JueWei
	g_OtherInfo_PageButton[12] = OtherInfo_BaoJian
	g_OtherInfo_PageButton[13] = OtherInfo_WuYi
	g_OtherInfo_PageButton[14] = OtherInfo_ShenQi
	g_OtherInfo_PageButton[15] = OtherInfo_Armor
	g_OtherInfo_PageButton[16] = OtherInfo_CangPin
	g_OtherInfo_PageButton[17] = OtherInfo_OtherInfo
	
	g_OtherInfo_PageMask[1] = OtherInfo_SelfEquip_tips
	g_OtherInfo_PageMask[2] = OtherInfo_SelfData_tips
	g_OtherInfo_PageMask[3] = OtherInfo_Pet_tips
	g_OtherInfo_PageMask[4] = OtherInfo_Infant_tips
	g_OtherInfo_PageMask[5] = OtherInfo_Wuhun_tips
	g_OtherInfo_PageMask[6] = OtherInfo_Xiulian_tips
	g_OtherInfo_PageMask[7] = OtherInfo_Miji_tips
	g_OtherInfo_PageMask[8] = OtherInfo_ZhenYuan_tips
	g_OtherInfo_PageMask[9] = OtherInfo_JingMai_tips
	g_OtherInfo_PageMask[10] = OtherInfo_ShenDing_tips
	g_OtherInfo_PageMask[11] = OtherInfo_JueWei_tips
	g_OtherInfo_PageMask[12] = OtherInfo_BaoJian_tips
	g_OtherInfo_PageMask[13] = OtherInfo_WuYi_tips
	g_OtherInfo_PageMask[14] = OtherInfo_ShenQi_tips
	g_OtherInfo_PageMask[15] = OtherInfo_Armor_tips
	g_OtherInfo_PageMask[16] = OtherInfo_CangPin_tips
	g_OtherInfo_PageMask[17] = OtherInfo_OtherInfo_tips
	
	g_PageButtonTipsPos[1] = "{0.000000,28.000000}" 
	g_PageButtonTipsPos[2] = "{0.000000,64.000000}" 
	g_PageButtonTipsPos[3] = "{0.000000,100.000000}"
	g_PageButtonTipsPos[4] = "{0.000000,136.000000}"
	g_PageButtonTipsPos[5] = "{0.000000,172.000000}"
	g_PageButtonTipsPos[6] = "{0.000000,208.000000}"
	g_PageButtonTipsPos[7] = "{0.000000,244.000000}"
	g_PageButtonTipsPos[8] = "{0.000000,280.000000}"
	g_PageButtonTipsPos[9] = "{0.000000,316.000000}" 
	g_PageButtonTipsPos[10] = "{0.000000,352.000000}" 
	g_PageButtonTipsPos[11] = "{0.000000,388.000000}" 
	g_PageButtonTipsPos[12] = "{0.000000,424.000000}" 
	g_PageButtonTipsPos[13] = "{0.000000,460.000000}" 
	g_PageButtonTipsPos[14] = "{0.000000,496.000000}"
	g_PageButtonTipsPos[15] = "{0.000000,532.000000}"
	g_PageButtonTipsPos[16] = "{0.000000,568.000000}"
	g_PageButtonTipsPos[17] = "{0.000000,604.000000}"
	
end

-- OnEvent
function OtherInfo_OnEvent(event)
OtherInfo_SetTabColor(4);
	if ( event == "UPDATE_WILLGET_MISSION_TRACK" )  or (event=="TOGGLE_UPDATE_INFANT")  or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		 OtherInfo_Refresh_Page_Button(nLevel)
		 OtherInfo_ShowPage()
	end
	if ( event == "OPEN_OTHER_INFO" ) then

		if(this:IsVisible()) then

			this:Hide();
			return;
		end

		-- 执行服务器脚本，请求更新打劫数据
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("UpdataDacoityData");
			Set_XSCRIPT_ScriptID(311012);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();

		OtherInfo_OnShow();
		this:Show();
		local nLevel =Player:GetLevel()
		 OtherInfo_Refresh_Page_Button(nLevel)
		 OtherInfo_ShowPage()
	end

	if ( event == "ZONGMEN_DIZILEVEL_UPDATE" ) then
		if arg0 == "con" then
			if (this:IsVisible()) then
				local zmcon = Player : GetData( "ZONGMENCON" )
				if tonumber(zmcon) <= 0 then
					zmcon = 0
				end
				--OtherInfo_19:SetText(tostring(zmcon))
			end
		end
	end

	if( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	end

	if( event == "UPDATE_DOUBLE_EXP") then
		local str = SystemSetup:GetDoubleExp( "count" )
		OtherInfo_6 : SetText(str.."小时")
		local str1 = SystemSetup:GetDoubleExp( "juqing" )
		OtherInfo_7 : SetText(str1 .. "")
		return;
	end

	if(event == "UPDATE_MISSION_DATA")  then
		OtherInfo_OnShow();
	end

	--处理兽栏事件--add by xindefeng
	if(event == "UPDATE_PET_EXTRANUM") then
		if(this:IsVisible()) then
			OtherInfo_OnShow()
		end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		OtherInfo_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		OtherInfo_Frame_On_ResetPos()
	end
	
	if(event == "MARTIAL_UPDATE"  or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		OtherInfo_RefreshWuYiTip()
	end
	
	if event == "UPDATE_TOY_TIP" then
		OtherInfo_UpdateWanjuTip()
		OtherInfo_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		OtherInfo_RefreshCangPinTip()
	end
	
end

function OtherInfo_OnShow()
	OtherInfo_OtherInfo : SetCheck(1);
	local str;
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		OtherInfo_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end

	str = Player : GetData("GOODBADVALUE");
	OtherInfo_1 : SetText(str)
	SetOtherInfo_1_Tooltip()	--设置其ToolTips	-- add by xindefeng

	str = Player : GetData("PKVALUE");
	OtherInfo_2 : SetText(str)

	local prenticeNum = Player : GetData("PRENTICCOUNT");
	local masterLvl = Player : GetData("MASTERLEVEL");
	local availRecruitNum = 0;
	if masterLvl == 1 then
		availRecruitNum = 2;
	elseif masterLvl == 2 then
		availRecruitNum = 3;
	elseif masterLvl == 3 then
		availRecruitNum = 5;
	elseif masterLvl == 4 then
		availRecruitNum = 8;
	end
	OtherInfo_9_Text:SetText("收徒数量:");
	OtherInfo_9:SetText(prenticeNum.."/".."5");
--	str = Player : GetData("MORALPOINT");
--	OtherInfo_3 : SetText(str)

	str = Player : GetData("MENPAIPOINT");
	OtherInfo_4 : SetText(str)

	str = SystemSetup:GetDoubleExp( "count" )
	OtherInfo_6 : SetText(str.."小时")
	str = Guild:GetGuildContri();
	OtherInfo_5 : SetText(str);

	local nCount = DataPool:GetPlayerMission_DataRound(150)
	OtherInfo_3:SetText(tostring(nCount))

	OtherInfo_8:SetText(tonumber(Player:GetData("PET_EXTRANUM")))	--显示兽栏空间--add by xindefeng

	OtherInfo_10 : SetText(Player : GetData("HONOR"));

	OtherInfo_11 : SetText(Player : GetData("RECOMMENDER"));

	--显示已击败怪物数
	local nKillMonsterCount = Player : GetData("KILLMONSTERCOUNT");
	local nLittleIncomeMonsterCount = Player : GetData("LITTLEINCOMEMONSTERCOUNT");
	local nNilIncomeMonsterCount = Player : GetData("NILINCOMEMONSTERCOUNT");
	local nNilDropBoxMonsterCount = Player : GetData("NILDORPBOXMONSTERCOUNT");
	if nKillMonsterCount > nNilDropBoxMonsterCount then
		nKillMonsterCount = nNilDropBoxMonsterCount;
	end
	local szKillMonsterText = "";
	if Player:GetData("Is2606S") == 1 then
		if nKillMonsterCount >= nNilDropBoxMonsterCount then
			szKillMonsterText = "#{QXFSG_260622_4}";
		elseif nKillMonsterCount >= nNilIncomeMonsterCount then
			szKillMonsterText = "#{QXFSG_260622_3}";
		elseif nKillMonsterCount >= nLittleIncomeMonsterCount then
			szKillMonsterText = "#{QXFSG_260622_2}";
		else
			szKillMonsterText = "#{QXFSG_260622_1}";
		end
	else
		if nKillMonsterCount >= nNilDropBoxMonsterCount then
			szKillMonsterText = "#{SGSYH_220407_04}";
		elseif nKillMonsterCount >= nNilIncomeMonsterCount then
			szKillMonsterText = "#{SGSYH_220407_03}";
		elseif nKillMonsterCount >= nLittleIncomeMonsterCount then
			szKillMonsterText = "#{SGSYH_220407_02}";
		else
			szKillMonsterText = "#{SGSYH_220407_01}";
		end
	end
	
	OtherInfo_12 : SetText(nKillMonsterCount.."/"..nNilDropBoxMonsterCount..szKillMonsterText);
	
	local szTooltips = "";
	if Player:GetData("Is2606S") == 1 then
		szTooltips = "#{QXFSG_260622_5}";
	else
		szTooltips = "#{FCMTS_091021_1}";
	end	
	OtherInfo_12_Text:SetToolTip(szTooltips);
	OtherInfo_12:SetToolTip(szTooltips)
	
	-- 改成累计活跃值
	--显示活跃值
	local nActivePoint = Player : GetData("ACCACTIVEPOINT") 
	OtherInfo_13 : SetText(nActivePoint);

	--显示婚姻数据
	-- 得到配偶信息
	str = SystemSetup:GetPrivateInfo("self","Consort");
	OtherInfo_14:SetText(str);

	--得到结婚时间
	str = SystemSetup:GetPrivateInfo("self","Weddingtime");
	OtherInfo_15:SetText(str)

	--显示离线经验值
	local LixianExp = Player : GetData("LIXIANEXP");
	OtherInfo_16:SetText( tostring(LixianExp) )
	OtherInfo_Wujing_16:SetText( tostring(LixianExp) )

	-- 显示回流专属经验
	local HuiLiuExp = Player : GetData( "HUILIUEXP" );
	OtherInfo_17:SetText( tostring( HuiLiuExp ) );
	OtherInfo_Wujing_17:SetText( tostring( HuiLiuExp ) );

	-- 显示补偿功力值
	local HuiLiuGongLi = Player : GetData( "HUILIUGONGLI" );
	OtherInfo_18:SetText( tostring( HuiLiuGongLi ) );
	OtherInfo_Wujing_18:SetText( tostring( HuiLiuGongLi ) );
	
	if Player:GetData("IsExpandLevelPlayer") > 0 then
		OtherInfo_18_Text:SetToolTip("#{KDJX_250815_31}")
		OtherInfo_18:SetToolTip("#{KDJX_250815_31}")
		OtherInfo_Wujing_18:SetToolTip("#{KDJX_250815_31}")
	else
		OtherInfo_18_Text:SetToolTip("#{HLJYBC_120813_28}")
		OtherInfo_18:SetToolTip("#{HLJYBC_120813_28}")
		OtherInfo_Wujing_18:SetToolTip("#{HLJYBC_120813_28}")
	end

	local zmcon = Player : GetData( "ZONGMENCON" )
	if tonumber(zmcon) <= 0 then
		zmcon = 0
	end
	--OtherInfo_19:SetText(tostring(zmcon))
	
	local nPlayerLevel = Player:GetData("LEVEL");
	if nPlayerLevel >= 120 then
		OtherInfo_16:Hide()
		OtherInfo_17:Hide()
		OtherInfo_18:Hide()
		OtherInfo_Wujing_16:Show()
		OtherInfo_Wujing_17:Show()
		OtherInfo_Wujing_18:Show()
		OtherInfo_Wujing_19:Show()
		
		--处理纳元
		--x888908_g_MD_Exp = MD_2025EXPBALL_EXP  --经验球当前累计经验 MD_2025EXPBALL_EXP=3260        --经验球当前累计经验
		--MF_2025EXPBALL_SWITCH=5201	        --经验球开关
		--MF_2025EXPBALL_GAINEXP=5202	        --经验球状态
		if Pneuma:GetMF(5201) == 0 then --经验球开关
			OtherInfo_Wujing_19_Image:SetProperty("Image", "set:WuJingJYQ image:WuJingJYQ_Off");
			OtherInfo_Wujing_19_Image:SetToolTip("#{JYQQ_250801_71}")
			OtherInfo_Wujing_19_text:Hide();
			OtherInfo_Wujing_19_info:Hide();
		else
			local nExpCount = DataPool:GetPlayerMission_DataRound(3260)
			if nExpCount >= 100000000 then
				OtherInfo_Wujing_19_Image:SetProperty("Image", "set:WuJingJYQ image:WuJingJYQ_Max");
			else
				if Pneuma:GetMF(5202) == 0 then --经验球状态
					OtherInfo_Wujing_19_Image:SetProperty("Image", "set:WuJingJYQ image:WuJingJYQ_Stop");
				else
					OtherInfo_Wujing_19_Image:SetProperty("Image", "set:WuJingJYQ image:WuJingJYQ_Doing");
				end
			end
			OtherInfo_Wujing_19_Image:SetToolTip("#{JYQQ_250801_74}")			
			OtherInfo_Wujing_19_info:SetText(tostring(DataPool:GetPlayerMission_DataRound(3260)) );
			OtherInfo_Wujing_19_text:Show();
			OtherInfo_Wujing_19_info:Show();
		end
		
	else
		OtherInfo_16:Show()
		OtherInfo_17:Show()
		OtherInfo_18:Show()
		OtherInfo_Wujing_16:Hide()
		OtherInfo_Wujing_17:Hide()
		OtherInfo_Wujing_18:Hide()
		OtherInfo_Wujing_19:Hide()
	end
	
	OtherInfo_UpdateWanjuTip()
end


function OtherInfo_SetTabColor(idx)
	-- if(idx == nil or idx < 0 or idx > 5) then
		-- return;
	-- end


	-- local i = 0;
	-- local selColor = "#Y";
	-- local noselColor = "";
	-- local tab = {
								-- [0] = OtherInfo_SelfEquip,
								-- OtherInfo_SelfData,
								-- OtherInfo_Pet,
								-- OtherInfo_Ride,
								-- OtherInfo_OtherInfo,
								-- OtherInfo_JingMai,
							-- };

	-- while i < 6 do
		-- if(i == idx) then
			-- tab[i]:SetText(selColor..OTHERINFO_TAB_TEXT[i]);
		-- else
			-- tab[i]:SetText(noselColor..OTHERINFO_TAB_TEXT[i]);
		-- end
		-- i = i + 1;
	-- end
end

function OtherInfo_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);

	OpenEquip(1);
	this:Hide();
	OtherInfo_SelfEquip : SetCheck(0);
	OtherInfo_SelfData : SetCheck(0);
	OtherInfo_Pet : SetCheck(0)
	OtherInfo_Ride : SetCheck(0);
	OtherInfo_OtherInfo : SetCheck(1);
	OtherInfo_SetTabColor(4);
end

--打开自己的资料页面
function OtherInfo_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
	this:Hide();
end

function OtherInfo_Pet_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);

	TogglePetPage();
	this:Hide();
	OtherInfo_SelfEquip : SetCheck(0);
	OtherInfo_SelfData : SetCheck(0);
	OtherInfo_Pet : SetCheck(0);
	OtherInfo_Ride : SetCheck(0);
	OtherInfo_OtherInfo : SetCheck(1);
	OtherInfo_SetTabColor(4);
end

--神木王鼎
function OtherInfo_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);

	local nRet = OpenShenDingPage();
	if nRet == 1 then
		this:Hide();
		OtherInfo_OtherInfo:SetCheck(0)
	else
		OtherInfo_ShenDing:SetCheck(0)
	end
end

function OtherInfo_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);

	OpenRidePage();
	this:Hide();
	OtherInfo_SelfEquip : SetCheck(0);
	OtherInfo_SelfData : SetCheck(0);
	OtherInfo_Pet : SetCheck(0);
	OtherInfo_Ride : SetCheck(0);
	OtherInfo_OtherInfo : SetCheck(1);
	OtherInfo_SetTabColor(4);
end

function OtherInfo_Xiulian_Switch()
	local nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
	else
	    OtherInfo_Xiulian : SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

function OtherInfo_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		this:Hide();
		OtherInfo_OtherInfo:SetCheck(0)
	else
		OtherInfo_JingMai:SetCheck(0)
	end
end

function OnOtherInfo_OpenReputationClick()

	OpenWindow( "Reputation" );

end

-- lihe add 服务器编年史
-- function OnOtherInfo_OpenServerChronicleClick()

-- 	OpenWindow( "ServerChronicle" );

-- end

-- 打开关系界面
function OtherInfo_OpenGuanXi_Click()
	OpenWindow( "Relation" );

end

--设置otherinfo_1的tooltip	--add by xindefeng
function SetOtherInfo_1_Tooltip()
	local MasterLevel = Player:GetData("MASTERLEVEL")	--获取师德等级
	if(MasterLevel < 0)then
		return
	end

	local ShanEValue = Player:GetData("GOODBADVALUE")						--获取善恶值
	local TuDiCount = Player:GetData("PRENTICCOUNT")						--获取徒弟数量
	local TuDiSupplyExp = Player:GetData("PRENTICSUPPLYEXP")		--获取当前徒弟贡献的经验值
	local ShanEExp = ShanEValue * (g_ShiDeTbl[MasterLevel][3])	--计算与善恶值挂钩可以领取的经验值
	local TrueExp = ((TuDiSupplyExp < ShanEExp) and TuDiSupplyExp) or ShanEExp	--获取二者最小值

	local str = "#{STGZ_150514_409}"

	OtherInfo_1:SetToolTip(str)
end

--显示武魂UI
function OtherInfo_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function OtherInfo_Frame_On_ResetPos()

	OtherInfo_Frame : SetProperty("UnifiedXPosition", g_OtherInfo_Frame_UnifiedXPosition);
	OtherInfo_Frame : SetProperty("UnifiedYPosition", g_OtherInfo_Frame_UnifiedYPosition);

end

function OtherInfo_AchievementClick()
	Achievement:OpenAchvWindow("PlayerFrame", -1)
end

function OtherInfo_TujianClick()
	PushEvent("OPEN_TJHANDBOOK", 0, 0, 0)
end

function OtherInfo_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end


function OtherInfo_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherInfo_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherInfo_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function OtherInfo_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

function OtherInfo_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		OtherInfo_ShenDing:Disable()
		OtherInfo_ShenDing_tips:Show()
	--	OtherInfo_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		OtherInfo_ShenDing:Enable()
		OtherInfo_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		OtherInfo_Infant:Disable()
		OtherInfo_Infant_tips:Show()
	--	OtherInfo_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		OtherInfo_Infant:Enable()
		OtherInfo_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		OtherInfo_Wuhun:Disable()
--		OtherInfo_Wuhun_tips:Show()
	--	OtherInfo_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		OtherInfo_Wuhun:Enable()
		OtherInfo_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		OtherInfo_Xiulian:Disable()
		OtherInfo_Xiulian_tips:Show()
	--	OtherInfo_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		OtherInfo_Xiulian:Enable()
		OtherInfo_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		OtherInfo_Miji:Disable()
		OtherInfo_Miji_tips:Show()
	--	OtherInfo_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		OtherInfo_Miji:Enable()
		OtherInfo_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		OtherInfo_ZhenYuan:Disable()
		OtherInfo_ZhenYuan_tips:Show()
	--	OtherInfo_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		OtherInfo_ZhenYuan:Enable()
		OtherInfo_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		OtherInfo_JueWei:Disable()
		OtherInfo_JueWei_tips:Show()
	--	OtherInfo_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		OtherInfo_JueWei:Enable()
		OtherInfo_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		OtherInfo_JingMai:Disable()
		OtherInfo_JingMai_tips:Show()
	--	OtherInfo_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		OtherInfo_JingMai:Enable()
		OtherInfo_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		OtherInfo_BaoJian:Disable()
		OtherInfo_BaoJian_tips:Show()
	else
		OtherInfo_BaoJian:Enable()
		OtherInfo_BaoJian_tips:Hide()
	end
	
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		OtherInfo_WuYi:Enable()
		OtherInfo_WuYi_tips:Hide()
	else
		OtherInfo_WuYi:Disable()
		OtherInfo_WuYi_tips:Show()
	end
	OtherInfo_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		OtherInfo_ShenQi:Enable()
		OtherInfo_ShenQi_tips:Hide()
	else
		OtherInfo_ShenQi:Disable()
		OtherInfo_ShenQi_tips:Show()
	end
	OtherInfo_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		OtherInfo_Armor:Enable()
		OtherInfo_Armor_tips:Hide()
	else
		OtherInfo_Armor:Disable()
		OtherInfo_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		OtherInfo_CangPin:Enable()
		OtherInfo_CangPin_tips:Hide()
	else
		OtherInfo_CangPin:Disable()
		OtherInfo_CangPin_tips:Show()
	end
	
	OtherInfo_RefreshCangPinTip()
end

function OtherInfo_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function OtherInfo_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function OtherInfo_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_OtherInfo_PageButton[idx]:GetProperty("UnifiedXPosition");
			OtherInfo_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		OtherInfo_WuYi_Buttontips:Show()
	else
		OtherInfo_WuYi_Buttontips:Hide()
	end
end

function OtherInfo_WanjuClick()
	Exterior:LuaFnOpenToyCollection()
end

function OtherInfo_UpdateWanjuTip()
	OtherInfo_Wanju_Tips:Hide()	
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		OtherInfo_Wanju_Tips:Show()
	end
end

function OtherInfo_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_OtherInfo_PageButton[idx]:GetProperty("UnifiedXPosition");
			OtherInfo_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		OtherInfo_OtherInfo_ButtonTips:Show()
	else
		OtherInfo_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function OtherInfo_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function OtherInfo_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", OtherInfo_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function OtherInfo_RefreshCangPinTip()
	local CangPinClassCount = 4
	local bHaveChipToMelt = DataPool:LuaFnIsCanMeltCangPinChip()
	local bTip = 0
	for i = 1, CangPinClassCount do
		if DataPool:LuaFnIsCangPinClassShowTip(i - 1) == 1 then
			bTip = 1
		end
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 16 and g_PageButtonTipsPos[idx] then -- 名物
			local newpos = g_PageButtonTipsPos[idx] --28 + g_OtherInfo_PageButton[idx]:GetProperty("UnifiedXPosition");
			OtherInfo_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		OtherInfo_CangPin_Buttontips:Show()
	else
		OtherInfo_CangPin_Buttontips:Hide()
	end
end


function OtherInfo_ShowPage()
	if Player:GetData("Is2606S") == 1 then
		OtherInfo_16_Text:SetToolTip("#{JYZH_260617_37}")
		OtherInfo_Wujing_16:SetToolTip("#{JYZH_260617_37}")
		OtherInfo_16:SetToolTip("#{JYZH_260617_37}")
	else
		OtherInfo_16_Text:SetToolTip("#{XST_110831_125}")
		OtherInfo_Wujing_16:SetToolTip("#{XST_110831_125}")
		OtherInfo_16:SetToolTip("#{XST_110831_125}")
	end

	for i = 1, table.getn(g_OtherInfo_Page) do
		g_OtherInfo_PageButton[i]:Hide()
		g_OtherInfo_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	OtherInfo_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_OtherInfo_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_OtherInfo_Page) do
			if i ~= nPageNumber then
				g_OtherInfo_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_OtherInfo_Page) do
		if OtherInfo_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_OtherInfo_PageButton[g_PageCount]:Show()
			g_OtherInfo_PageButton[g_PageCount]:SetText(g_OtherInfo_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if OtherInfo_IsPageEnable(i) == 1 then
				g_OtherInfo_PageButton[g_PageCount]:Enable()
				g_OtherInfo_PageMask[g_PageCount]:Hide()
			else
				g_OtherInfo_PageButton[g_PageCount]:Disable()
				g_OtherInfo_PageMask[g_PageCount]:Show()
				if g_OtherInfo_Page[i].Tip ~= "" then
					g_OtherInfo_PageMask[g_PageCount]:SetToolTip(g_OtherInfo_Page[i].Tip)
				end
			end
		end
	end
	
	OtherInfo_RefreshWuYiTip()
	OtherInfo_RefreshOtherInfoTip()
	OtherInfo_RefreshCangPinTip()
	
end

function OtherInfo_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		OtherInfo_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		OtherInfo_SelfData_Switch()
	elseif idx == 3 then--珍兽
		OtherInfo_Pet_Switch()
	elseif idx == 4 then--子女
		OtherInfo_Infant_Switch()
	elseif idx == 5 then--武魂
		OtherInfo_Wuhun_Switch()
	elseif idx == 6 then--修炼
		OtherInfo_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		OtherInfo_Miji_Page_Switch()
	elseif idx == 8 then--真元
		OtherInfo_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		OtherInfo_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		OtherInfo_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		OtherInfo_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		OtherInfo_OpenBaoJian()
	elseif idx == 13 then--武意
		OtherInfo_OpenWuYi()
	elseif idx == 14 then--神器
		OtherInfo_OpenShenQi()
	elseif idx == 15 then--星盘
		OtherInfo_Armor_Page_Switch()
	elseif idx == 16 then--名物
		OtherInfo_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		--SelfData_Other_Info_Page_Switch()
	end
end

function OtherInfo_CheckPage(idx)
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--修炼
		return 1
	elseif idx == 7 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 9 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 16 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function OtherInfo_IsPageEnable(idx)
	
	local nLevel = Player:GetLevel()
	
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		local InfantCount = Infant:GetInfantCount();
		if ( nLevel < 50 ) or ( InfantCount <= 0 ) then
			return 0
		end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--修炼
		if ( nLevel < 70 ) then
			return 0
		end
		return 1
	elseif idx == 7 then--秘籍
		local ret = DataPool:Lua_IsMissionHaveDone(1651)
		if ( nLevel < 75 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		local ret = DataPool:Lua_IsMissionHaveDone(1600)
		if ( nLevel < 80 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 9 then--经脉
		local ret = DataPool:Lua_IsMissionHaveDone(1554)
		if ( nLevel < 90 ) or ( ret == 0 )  then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if ( nLevel < 15 ) then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if (MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
			return 1
		end
		return 0
	elseif idx == 14 then--神器
		if (DataPool:Lua_IsMissionHaveDone(1950) == 1) then
			return 1
		end
		return 0
	elseif idx == 15 then--星盘
		if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
			return 1
		end
		return 0
	elseif idx == 16 then--名物
		if nLevel < 30 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function OtherInfo_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


