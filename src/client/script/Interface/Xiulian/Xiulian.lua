local SELFEQUIP_TAB_TEXT = {}
local XIULIAN_BOOKS = {}
local XIULIAN_MIJI = {}
local XIULIAN_MIJI_TEXT = {}

local XIULIAN_BOOK_SELECT = 1;
local XIULIAN_MIJI_SELECT = -1;

local MIJI_CAN_SELECT = false;

-- 界面的默认相对位置
local g_Xiulian_Frame_UnifiedXPosition;
local g_Xiulian_Frame_UnifiedYPosition;

local strZhiyeTip = {}
strZhiyeTip[1] = "#{XLZY_120330_02}" --少林
strZhiyeTip[2] = "#{XLZY_120330_04}" --明教
strZhiyeTip[3] = "#{XLZY_120330_03}" --丐帮
strZhiyeTip[4] = "#{XLZY_120330_05}" --武当
strZhiyeTip[5] = "#{XLZY_120330_08}" --峨嵋
strZhiyeTip[6] = "#{XLZY_120330_09}" --星宿
strZhiyeTip[7] = "#{XLZY_120330_06}" --天龙
strZhiyeTip[8] = "#{XLZY_120330_10}" --天山
strZhiyeTip[9] = "#{XLZY_120330_07}" --逍遥
strZhiyeTip[10] = " " --无门派
strZhiyeTip[11] = "#{XLZY_120330_11}" --慕容
strZhiyeTip[12] = "#{XMPTM_130123_08}" --唐门
strZhiyeTip[13] = "#{GGJJ_160606_174}" --鬼谷
strZhiyeTip[14] = "#{THJJ_190724_115}" --桃花岛
strZhiyeTip[15] = "#{XLZY_120330_24}" --
strZhiyeTip[16] = "#{XMPHM_210604_35}" --menpai15


--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_Xiulian_Page = {
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

local g_Xiulian_PageButton = {}
local g_Xiulian_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function Xiulian_PreLoad()

	-- 打开界面
	this:RegisterEvent("OPEN_XIULIAN_PAGE");

	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UNIT_XIULIAN");
	this:RegisterEvent("UINT_POWER");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级

	this:RegisterEvent("TOGGLE_UPDATE_INFANT"); --子女有变化 刷新按钮状态

	this:RegisterEvent("FINISH_MISSION");
	
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function Xiulian_OnLoad()

	XIULIAN_BOOKS[1] = Xiulian_XinfaSkill_1
	XIULIAN_BOOKS[2] = Xiulian_XinfaSkill_2
	XIULIAN_BOOKS[3] = Xiulian_XinfaSkill_3
	XIULIAN_BOOKS[4] = Xiulian_XinfaSkill_4

	XIULIAN_MIJI[1] = Xiulian_ZhaoshiSkill_1
	XIULIAN_MIJI[2] = Xiulian_ZhaoshiSkill_2
	XIULIAN_MIJI[3] = Xiulian_ZhaoshiSkill_3
	XIULIAN_MIJI[4] = Xiulian_ZhaoshiSkill_4
	XIULIAN_MIJI[5] = Xiulian_ZhaoshiSkill_5
	XIULIAN_MIJI[6] = Xiulian_ZhaoshiSkill_6

	XIULIAN_MIJI_TEXT[1] = Xiulian_ZhaoshiSkill_level1
	XIULIAN_MIJI_TEXT[2] = Xiulian_ZhaoshiSkill_level2
	XIULIAN_MIJI_TEXT[3] = Xiulian_ZhaoshiSkill_level3
	XIULIAN_MIJI_TEXT[4] = Xiulian_ZhaoshiSkill_level4
	XIULIAN_MIJI_TEXT[5] = Xiulian_ZhaoshiSkill_level5
	XIULIAN_MIJI_TEXT[6] = Xiulian_ZhaoshiSkill_level6

	-- 保存界面的默认相对位置
	g_Xiulian_Frame_UnifiedXPosition	= Xiulian_Frame : GetProperty("UnifiedXPosition");
	g_Xiulian_Frame_UnifiedYPosition	= Xiulian_Frame : GetProperty("UnifiedYPosition");

	g_Xiulian_PageButton[1] = Xiulian_SelfEquip
	g_Xiulian_PageButton[2] = Xiulian_SelfData
	g_Xiulian_PageButton[3] = Xiulian_Pet
	g_Xiulian_PageButton[4] = Xiulian_Infant
	g_Xiulian_PageButton[5] = Xiulian_Wuhun
	g_Xiulian_PageButton[6] = Xiulian_Xiulian
	g_Xiulian_PageButton[7] = Xiulian_Miji
	g_Xiulian_PageButton[8] = Xiulian_ZhenYuan
	g_Xiulian_PageButton[9] = Xiulian_JingMai
	g_Xiulian_PageButton[10] = Xiulian_ShenDing
	g_Xiulian_PageButton[11] = Xiulian_JueWei
	g_Xiulian_PageButton[12] = Xiulian_BaoJian
	g_Xiulian_PageButton[13] = Xiulian_WuYi
	g_Xiulian_PageButton[14] = Xiulian_ShenQi
	g_Xiulian_PageButton[15] = Xiulian_Armor
	g_Xiulian_PageButton[16] = Xiulian_CangPin
	g_Xiulian_PageButton[17] = Xiulian_OtherInfo
	
	g_Xiulian_PageMask[1] = Xiulian_SelfEquip_tips
	g_Xiulian_PageMask[2] = Xiulian_SelfData_tips
	g_Xiulian_PageMask[3] = Xiulian_Pet_tips
	g_Xiulian_PageMask[4] = Xiulian_Infant_tips
	g_Xiulian_PageMask[5] = Xiulian_Wuhun_tips
	g_Xiulian_PageMask[6] = Xiulian_Xiulian_tips
	g_Xiulian_PageMask[7] = Xiulian_Miji_tips
	g_Xiulian_PageMask[8] = Xiulian_ZhenYuan_tips
	g_Xiulian_PageMask[9] = Xiulian_JingMai_tips
	g_Xiulian_PageMask[10] = Xiulian_ShenDing_tips
	g_Xiulian_PageMask[11] = Xiulian_JueWei_tips
	g_Xiulian_PageMask[12] = Xiulian_BaoJian_tips
	g_Xiulian_PageMask[13] = Xiulian_WuYi_tips
	g_Xiulian_PageMask[14] = Xiulian_ShenQi_tips
	g_Xiulian_PageMask[15] = Xiulian_Armor_tips
	g_Xiulian_PageMask[16] = Xiulian_CangPin_tips
	g_Xiulian_PageMask[17] = Xiulian_OtherInfo_tips
	
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
function Xiulian_OnEvent(event)

	if ( event == "UPDATE_WILLGET_MISSION_TRACK" )  or (event=="TOGGLE_UPDATE_INFANT")  or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		Xiulian_Refresh_Page_Button(nLevel)
		Xiulian_ShowPage()
	end

	if ( event == "OPEN_XIULIAN_PAGE" ) then

	    if(this:IsVisible()) then
			this:Hide();
			return;
		end

	    local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	    if(selfUnionPos ~= nil) then
		    Xiulian_Frame:SetProperty("UnifiedPosition", selfUnionPos);
    	end

	    XIULIAN_BOOK_SELECT = 1;
			XIULIAN_MIJI_SELECT = -1;
			this:Show();
			Xiulian_Update()

			Xiulian_SetTabState()

			Xiulian_SetHappyMonth()
			Xiulian_SetMergeMonth()
		local nLevel =Player:GetLevel()
		Xiulian_Refresh_Page_Button(nLevel)
		Xiulian_ShowPage()
	end

	if( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	end

	if( event == "UNIT_XIULIAN" ) then
		local normalsize = 3
		if Player:GetData("Is2606S") == 1 then
			normalsize = 2
		end
	    for i = 1, normalsize do
			local theAction = EnumAction(i - 1, "xiulianbook")
			if(theAction:GetID() ~= 0) then
				--if i == 3 then
					--第3本需要完成进阶任务
					--if Player:GetXiuLianBookInfo(2,"HasActived") == 1 then
						--XIULIAN_BOOKS[i] : SetActionItem(theAction:GetID())
					--end
				--else
				    --XIULIAN_BOOKS[i] : SetActionItem(theAction:GetID())
				--end
				XIULIAN_BOOKS[i] : SetActionItem(theAction:GetID())
			end
		end
		Xiulian_JingJie_Selected_Update()
		Xiulian_Skill_Clicked_Update()
		Xiulian_SetSelectState()
	end

	if(event == "UINT_POWER" ) then
             --设置功力
            Xiulian_Gongli_Text:SetText("#{XL_XML_87}")
            local nPower =  Player:GetData("POWER")
		local attch =""

		Xiulian_Gongli_Text:SetProperty("UnifiedSize","{{0.000000,120.000000},{0.000000,20.000000}}");
		Xiulian_Gongli_Text:SetProperty("UnifiedPosition","{{0.500000,-56.000000},{1.000000,-22.000000}}");
		if Xiulian_OnHappyMonth() == 1 then
			local powValue = DataPool : Lua_GetPowfixValue()
			attch ="#{FXDL_120910_36}".."#b"..powValue.."#{FXDL_120910_37}"
			Xiulian_Gongli_Text:SetProperty("UnifiedSize","{{0.000000,274.000000},{0.000000,20.000000}}");
			Xiulian_Gongli_Text:SetProperty("UnifiedPosition","{{0.500000,-139.000000},{1.000000,-22.000000}}");
		end


		if Xiulian_OnMergeServerMonth() == 1 then
			local powerValue = DataPool : Lua_GetPowerValue()
			attch ="#{HFHLY_121123_29}".."#b"..powerValue.."#{HFHLY_121123_31}"
			Xiulian_Gongli_Text:SetProperty("UnifiedSize","{{0.000000,274.000000},{0.000000,20.000000}}");
			Xiulian_Gongli_Text:SetProperty("UnifiedPosition","{{0.500000,-139.000000},{1.000000,-22.000000}}");
		end

		if Player:GetData("IsExpandLevelPlayer") > 0 then
	    Xiulian_Vigor:SetText( ScriptGlobal_Format("#{KDJX_250815_03}",nPower))
	    Xiulian_Vigor:SetToolTip("#{KDJX_250815_04}")
	    Xiulian_Gongli_Text:SetToolTip("#{KDJX_250815_04}")
	  else
	  	Xiulian_Vigor:SetText(nPower.."/100")
	  	Xiulian_Vigor:SetToolTip("#{XL_XML_88}")
		Xiulian_Gongli_Text:SetToolTip("#{XL_XML_88}")
	  end
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Xiulian_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Xiulian_Frame_On_ResetPos()
	end
	
	if(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		Xiulian_RefreshWuYiTip()
	end

	if event == "UPDATE_TOY_TIP" then
		Xiulian_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		Xiulian_RefreshCangPinTip()
	end
end

function Xiulian_SelfEquip_Page_Switch()

	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);

	OpenEquip(1);
	this:Hide();
end

function Xiulian_Pet_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);

	TogglePetPage();
	this:Hide();
end

--神木王鼎
function Xiulian_ShenDing_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);

	local nRet = OpenShenDingPage();
	if nRet == 1 then
		this:Hide();
		Xiulian_Xiulian:SetCheck(0)
	else
		Xiulian_ShenDing:SetCheck(0)
	end
end

function Xiulian_Ride_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);

	OpenRidePage();
	this:Hide();
end

function Xiulian_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);

	SystemSetup:OpenPrivatePage("self");
	this:Hide();
end

function Xiulian_Xiulian_Switch()
    Xiulian_Xiulian:SetCheck(1)
end

function Xiulian_Other_Info_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);

	OtherInfoPage();
	this:Hide();
end

function Xiulian_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
	this:Hide();
end

function Xiulian_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		this:Hide();
		Xiulian_Xiulian:SetCheck(0)
	else
		Xiulian_JingMai:SetCheck(0)
	end
end

function Xiulian_SetTabState()
	Xiulian_SelfEquip:SetCheck(0)
	Xiulian_SelfData:SetCheck(0)
	Xiulian_Miji:SetCheck(0)
	Xiulian_Pet:SetCheck(0)
	Xiulian_Xiulian:SetCheck(1)
	Xiulian_Ride:SetCheck(0)
	Xiulian_OtherInfo:SetCheck(0)
	Xiulian_JingMai:SetCheck(0)
end


function Xiulian_Xinfa_Clicked(nIndex)
	if Player:GetData("Is2606S") == 1 and nIndex == 3 then
		return
	end
	if(nIndex < 4 and nIndex > 0) then
		--if nIndex == 3 then
			--第3本需要判断是否完成门派进阶
			--if Player:GetXiuLianBookInfo(2,"HasActived") ~= 1 then
				--return
			--end
		--end 
		XIULIAN_BOOK_SELECT = nIndex
		XIULIAN_MIJI_SELECT = -1
		Xiulian_JingJie_Selected_Update()
	else
	    --PushDebugMessage("#{XL_090707_50}")
	end
end
--===============================================
-- 更新
--===============================================
function Xiulian_Update()
	local normalsize = 3
	if Player:GetData("Is2606S") == 1 then
		normalsize = 2
	end
	for i = 1, normalsize do
		local theAction = EnumAction(i - 1, "xiulianbook")
		if(theAction:GetID() ~= 0) then
			--if i == 3 then
				--第3本需要完成进阶任务
				--if Player:GetXiuLianBookInfo(2,"HasActived") == 1 then
					--XIULIAN_BOOKS[i] : SetActionItem(theAction:GetID())
				--end
			--else
				--XIULIAN_BOOKS[i] : SetActionItem(theAction:GetID())
			--end
			XIULIAN_BOOKS[i] : SetActionItem(theAction:GetID())
		end
	end
    Xiulian_JingJie_Selected_Update()
    --设置功力
    Xiulian_Gongli_Text:SetText("#{XL_XML_87}")
    local nPower =  Player:GetData("POWER")
	local attch =""
	Xiulian_Gongli_Text:SetProperty("UnifiedSize","{{0.000000,120.000000},{0.000000,20.000000}}");
	Xiulian_Gongli_Text:SetProperty("UnifiedPosition","{{0.500000,-56.000000},{1.000000,-22.000000}}");
	if Xiulian_OnHappyMonth()  == 1 then
		local powValue = DataPool : Lua_GetPowfixValue()
		attch ="#{FXDL_120910_20}".."#b"..powValue.."#{FXDL_120910_33}"
		Xiulian_Gongli_Text:SetProperty("UnifiedSize","{{0.000000,274.000000},{0.000000,20.000000}}");
		Xiulian_Gongli_Text:SetProperty("UnifiedPosition","{{0.500000,-139.000000},{1.000000,-22.000000}}");
	end

	if Xiulian_OnMergeServerMonth() == 1 then
		local powerValue = DataPool : Lua_GetPowerValue()
		attch ="#{HFHLY_121123_29}".."#b"..powerValue.."#{HFHLY_121123_31}"
		Xiulian_Gongli_Text:SetProperty("UnifiedSize","{{0.000000,274.000000},{0.000000,20.000000}}");
		Xiulian_Gongli_Text:SetProperty("UnifiedPosition","{{0.500000,-139.000000},{1.000000,-22.000000}}");
	end
	-- PushDebugMessage("attch="..attch)
	Xiulian_Gongli_Tooltip:SetText(attch)
	
	if Player:GetData("IsExpandLevelPlayer") > 0 then
	  Xiulian_Vigor:SetText( ScriptGlobal_Format("#{KDJX_250815_03}",nPower))
	  Xiulian_Vigor:SetToolTip("#{KDJX_250815_04}")
	  Xiulian_Gongli_Text:SetToolTip("#{KDJX_250815_04}")
	else
		Xiulian_Vigor:SetText(nPower.."/100")
		Xiulian_Vigor:SetToolTip("#{XL_XML_88}")
		Xiulian_Gongli_Text:SetToolTip("#{XL_XML_88}")
	end
end

--===============================================
-- 关闭
--===============================================
function Xiulian_Close_Cilcked()
		this:Hide()
end

function Xiulian_Skill_Clicked(nIndex)
	if MIJI_CAN_SELECT == false then
		return
	end
	if(XIULIAN_BOOK_SELECT == 1) then
	   if (nIndex ~= 6)  then
         XIULIAN_MIJI_SELECT  = nIndex
	   else
	     XIULIAN_MIJI_SELECT  = -1
	   end
	elseif(XIULIAN_BOOK_SELECT == 2)  then
	     XIULIAN_MIJI_SELECT  = nIndex + 5
	--add by kaibin for 开启第3本修炼
	elseif XIULIAN_BOOK_SELECT == 3 then
		if nIndex >= 1 and nIndex <= 4 then
			XIULIAN_MIJI_SELECT = nIndex + 11
		else
			XIULIAN_MIJI_SELECT = -1
		end
		
	else
         XIULIAN_MIJI_SELECT = -1
	end
	Xiulian_Skill_Clicked_Update()
end

function  Xiulian_Skill_Clicked_Update()
	Xiulian_SetSelectState()
    	--刷新中间图标
	if (XIULIAN_MIJI_SELECT ~= -1)   then
        --PushDebugMessage("Refresh XiuLian MiJi--"..XIULIAN_MIJI_SELECT)
		local	theAction = EnumAction(XIULIAN_MIJI_SELECT-1, "xiulianmiji")
		Xiulian_SkillIcon : SetActionItem(theAction:GetID())
		local XiuLianMiJiName = Player:GetXiuLianMiJiInfo(XIULIAN_MIJI_SELECT-1,"Name");
		local XiuLianMiJiJingJie = Player:GetXiuLianMiJiInfo(XIULIAN_MIJI_SELECT-1,"JingJie")
		local XiuLianMiJiLevel = Player:GetXiuLianMiJiInfo(XIULIAN_MIJI_SELECT-1,"Level")
		local CurMaxLevel = Player:GetXiuLianMiJiInfo(XIULIAN_MIJI_SELECT-1,"MaxLevel")
		local XiuLianMiJiExplain = Player:GetXiuLianMiJiInfo(XIULIAN_MIJI_SELECT-1,"Explain")
		--add:lby2015修炼下一等级需要的金钱和经验
		local nNeedMoney = Player:GetXiuLianMiJiInfo(XIULIAN_MIJI_SELECT-1,"UpLevelNeedMoney")
		local nNeedExp = Player:GetXiuLianMiJiInfo(XIULIAN_MIJI_SELECT-1,"UpLevelNeedExp")

		local StrJingJie = "#{XL_XML_32}".."#{XL_XML_85}"..XiuLianMiJiJingJie.."#{XL_XML_86}"
		local StrDengJi = "#{XL_XML_33}"..XiuLianMiJiLevel.."/"..CurMaxLevel
		
		
		local StrExp =  "#{XFXL_151203_01}"..nNeedExp
		
		if (XiuLianMiJiLevel == 120	) then
			StrExp ="#{XFXL_151203_01}".. "#{XFXL_151203_04}"
	
		end
		 
		
		Xiulian_SkillName:SetText(XiuLianMiJiName);
		Xiulian_SkillJingjie:SetText(StrJingJie);
		Xiulian_SkillLevel:SetText(StrDengJi);
		
		Xiulian_LearnExp:SetText(StrExp);
		Xiulian_LearnDemand_Jiaozi:Show()
		Xiulian_LearnDemand_Jiaozi_Text:SetText("#{XFXL_151203_02}")
		
		if (XiuLianMiJiLevel == 120	) then
			Xiulian_LearnDemand_Jiaozi:Hide()
			Xiulian_LearnDemand_Jiaozi_Text:SetText("#{XFXL_151203_02}".."#{XFXL_151203_04}")
		else
			Xiulian_LearnDemand_Jiaozi:Show()
			Xiulian_LearnDemand_Jiaozi:SetProperty("MoneyNumber", tostring(nNeedMoney))
			Xiulian_LearnDemand_Jiaozi_Text:SetText("#{XFXL_151203_02}")
		end
		
		local strCondition = ""
		if(XIULIAN_BOOK_SELECT == 1) then
			if(Player:GetData("LEVEL") >= 70) then
				strCondition = "\n#G#{XL_XML_30}"
			else
				strCondition = "\n#cff0000#{XL_XML_30}"
			end
		elseif XIULIAN_BOOK_SELECT == 2 then
			local XiuLianBook1Level = Player:GetXiuLianBookInfo(0,"Level")
			if (XiuLianBook1Level >= 3) then
				strCondition = "\n#G#{XL_XML_34}"
			else
				strCondition = "\n#cff0000#{XL_XML_34}"
			end
		--开启第3本修炼
		elseif XIULIAN_BOOK_SELECT == 3 then
			---------------------------------------需要判断是否完成门派进阶任务
	--------------------------------------------------------------------------------------
			--等级限制
			--if(Player:GetData("LEVEL") >= 90) then
				--strCondition = "\n#{XLZY_120330_12}"
			--else
				--strCondition = "\n#{XLZY_120330_01}"
			--end
			--完成进阶任务
			--if Player:GetXiuLianBookInfo(2,"HasActived") == 1 then
			    --strCondition = strCondition.."\n#{XLZY_120330_23}"
			--else
				--strCondition = strCondition.."\n#{XLZY_120330_22}"
			--end

			--门派信息
			--local nZhiye = Player:GetData("MEMPAI")
			--nZhiye = nZhiye + 1
			--PushDebugMessage(tostring(nZhiye))
			--if nZhiye > -1 and nZhiye < 11 then
				--strCondition = strCondition..strZhiyeTip[nZhiye]
			--end
	---------------------------------------------------------------------------------------
	        if XIULIAN_MIJI_SELECT-1 == 11 then
	            --等级限制
				if(Player:GetData("LEVEL") >= 90) then
					strCondition = "\n#{XLZY_120330_12}"
				else
					strCondition = "\n#{XLZY_120330_01}"
				end
				--完成进阶任务
				if Player:GetXiuLianBookInfo(2,"HasActived") == 1 then
					strCondition = strCondition.."\n#{XLZY_120330_23}"
				else
					strCondition = strCondition.."\n#{XLZY_120330_22}"
				end

				--门派信息
				local nZhiye = Player:GetData("MEMPAI")
				nZhiye = nZhiye + 1
				if nZhiye >= 1 and nZhiye <= 16 then--menpai15 mptodo
					strCondition = strCondition..strZhiyeTip[nZhiye]
				end

			elseif  XIULIAN_MIJI_SELECT-1 == 12 then
				local level = Player:GetXiuLianMiJiInfo(11,"Level")
				if tonumber(level) >= 10 then
					strCondition = "\n#{XLZY_120330_14}"
				else
					strCondition = "\n#{XLZY_120330_13}"
				end
	        elseif  XIULIAN_MIJI_SELECT-1 == 13 or XIULIAN_MIJI_SELECT-1 == 14 then
	            local level_11 = Player:GetXiuLianMiJiInfo(11,"Level")
	            local level_12 = Player:GetXiuLianMiJiInfo(12,"Level")
	            if tonumber(level_11) >= 20 and tonumber(level_12) >= 20 then
					strCondition = "\n#{XLZY_120330_16}"
				else
					strCondition = "\n#{XLZY_120330_15}"
				end
	        end
		end
		Xiulian_SkillInfo:SetText(XiuLianMiJiExplain.."\n#{XL_XML_31}"..strCondition);

	else
		if(XIULIAN_BOOK_SELECT == -1)	then
			Xiulian_SkillIcon : SetActionItem(-1)
		end
	end


end

--===============================================
-- 选择修炼境界后刷新
--===============================================
function  Xiulian_JingJie_Selected_Update()

    if XIULIAN_BOOK_SELECT == 1  then
		for i = 1, 5 do
			local theAction = EnumAction(i - 1, "xiulianmiji")
			if theAction ~= 0 then
				XIULIAN_MIJI[i] : SetActionItem(theAction:GetID())
				local CurMaxLevel  = Player:GetXiuLianMiJiInfo(i - 1,"MaxLevel")
				local XiuLianMiJiLevel = Player:GetXiuLianMiJiInfo(i - 1,"Level")
				if (CurMaxLevel == nil) or (XiuLianMiJiLevel == nil) then
					MIJI_CAN_SELECT =false
					return
				else
					MIJI_CAN_SELECT =true
				end
				XIULIAN_MIJI_TEXT[i]:SetText(XiuLianMiJiLevel.."/"..CurMaxLevel);
			end
		end
		XIULIAN_MIJI[6] : SetActionItem(-1)
		XIULIAN_MIJI_TEXT[6]:SetText("");
	elseif XIULIAN_BOOK_SELECT == 2  then
	    for i = 1, 6 do
			local theAction = EnumAction(i + 5 - 1, "xiulianmiji")
			if theAction ~= 0 then
		        XIULIAN_MIJI[i] : SetActionItem(theAction:GetID())
		        local CurMaxLevel = Player:GetXiuLianMiJiInfo(i + 5 - 1,"MaxLevel")
		        local XiuLianMiJiLevel = Player:GetXiuLianMiJiInfo(i + 5 - 1,"Level")
		        if (CurMaxLevel == nil) or (XiuLianMiJiLevel == nil) then
		        	MIJI_CAN_SELECT =false
					return
		        else
		        	MIJI_CAN_SELECT =true
				end
		        XIULIAN_MIJI_TEXT[i]:SetText(XiuLianMiJiLevel.."/"..CurMaxLevel);
			end
		end
	--add by kaibin for 第3本修炼
	elseif XIULIAN_BOOK_SELECT == 3 then
		for i = 1, 4 do
			local theAction = EnumAction(i + 11 - 1, "xiulianmiji")
			if theAction ~= 0 then
		        XIULIAN_MIJI[i] : SetActionItem(theAction:GetID())
		        local CurMaxLevel = Player:GetXiuLianMiJiInfo(i + 11 - 1,"MaxLevel")
		        local XiuLianMiJiLevel = Player:GetXiuLianMiJiInfo(i + 11 - 1,"Level")
		        if (CurMaxLevel == nil) or (XiuLianMiJiLevel == nil) then
		        	MIJI_CAN_SELECT =false
					return
		        else
		        	MIJI_CAN_SELECT =true
				end
		        XIULIAN_MIJI_TEXT[i]:SetText(XiuLianMiJiLevel.."/"..CurMaxLevel);
			end
		end
		XIULIAN_MIJI[5] : SetActionItem(-1)
		XIULIAN_MIJI_TEXT[5]:SetText("");
		XIULIAN_MIJI[6] : SetActionItem(-1)
		XIULIAN_MIJI_TEXT[6]:SetText("");
	--end by kaibin for 第3本修炼
	else
		for i=1, 6 do
	        XIULIAN_MIJI[i] : SetActionItem(-1)
	        XIULIAN_MIJI_TEXT[i]:SetText("")
		end
	end
	Xiulian_SetSelectState()
    	--刷新中间图标
	if (XIULIAN_BOOK_SELECT ~= -1)   then
		local theAction = EnumAction(XIULIAN_BOOK_SELECT-1, "xiulianbook")
		Xiulian_SkillIcon : SetActionItem(theAction:GetID())
		local XiuLianBookName = Player:GetXiuLianBookInfo(XIULIAN_BOOK_SELECT-1,"Name");
		local XiuLianBookLevel = Player:GetXiuLianBookInfo(XIULIAN_BOOK_SELECT-1,"Level")
		local XiuLianBookExplain = Player:GetXiuLianBookInfo(XIULIAN_BOOK_SELECT-1,"Explain")


		local StrJingJie = "#{XL_XML_29}".."#{XL_XML_85}"..XiuLianBookLevel.."#{XL_XML_86}"

		Xiulian_SkillName:SetText(XiuLianBookName);
		Xiulian_SkillJingjie:SetText(StrJingJie);
		Xiulian_SkillLevel:SetText("");
		Xiulian_LearnDemand_Jiaozi_Text:SetText("")
		--add:lby 2015初始化金钱和经验的初始值
	
		Xiulian_LearnExp:SetText("");
		Xiulian_LearnDemand_Jiaozi:Hide()
		
		
		local strCondition = ""
		if(XIULIAN_BOOK_SELECT == 1) then
			if(Player:GetData("LEVEL") >= 70) then
				strCondition = "\n#G#{XL_XML_30}"
			else
				strCondition = "\n#cff0000#{XL_XML_30}"
			end
		elseif XIULIAN_BOOK_SELECT == 2 then
			local XiuLianBook1Level = Player:GetXiuLianBookInfo(0,"Level")
			if (XiuLianBook1Level >= 3) then
				strCondition = "\n#G#{XL_XML_34}"
			else
				strCondition = "\n#cff0000#{XL_XML_34}"
			end
		--开启第3第4本修炼
		elseif XIULIAN_BOOK_SELECT == 3 then
			----------------------------------------------------此处需要判断是否完成门派进阶
			--等级限制
			if(Player:GetData("LEVEL") >= 90) then
				strCondition = "\n#{XLZY_120330_12}"
			else
				strCondition = "\n#{XLZY_120330_01}"
			end
			--完成进阶任务
			if Player:GetXiuLianBookInfo(2,"HasActived") == 1 then
			    strCondition = strCondition.."\n#{XLZY_120330_23}"
			else
				strCondition = strCondition.."\n#{XLZY_120330_22}"
			end

			--门派信息
			local nZhiye = Player:GetData("MEMPAI")
			nZhiye = nZhiye + 1
			--PushDebugMessage(tostring(nZhiye))
			if nZhiye >= 1 and nZhiye <= 16 then--menpai15 mptodo
				strCondition = strCondition..strZhiyeTip[nZhiye]
			end

		end
		Xiulian_SkillInfo:SetText(XiuLianBookExplain.."\n#{XL_XML_31}"..strCondition);
	else
	    Xiulian_SkillIcon : SetActionItem(-1)
	end

end
--===============================================
-- 设置选中状态
--===============================================
function Xiulian_SetSelectState()

  	for i=1, 3 do
  	  if(i == XIULIAN_BOOK_SELECT) then
  	       XIULIAN_BOOKS[i]:SetPushed(1)
  	  else
  	       XIULIAN_BOOKS[i]:SetPushed(0)
  	  end
	end
	for i=1, 6 do
		if((XIULIAN_MIJI_SELECT <= 5 and i==XIULIAN_MIJI_SELECT) or
		   (XIULIAN_MIJI_SELECT > 5 and XIULIAN_MIJI_SELECT <= 11 and i == XIULIAN_MIJI_SELECT - 5) or
		   (XIULIAN_MIJI_SELECT > 11 and XIULIAN_MIJI_SELECT <= 15 and i == XIULIAN_MIJI_SELECT - 11)) then
		    XIULIAN_MIJI[i]:SetPushed(1);
		else
			XIULIAN_MIJI[i]:SetPushed(0);
		end
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Xiulian_Frame_On_ResetPos()

	Xiulian_Frame : SetProperty("UnifiedXPosition", g_Xiulian_Frame_UnifiedXPosition);
	Xiulian_Frame : SetProperty("UnifiedYPosition", g_Xiulian_Frame_UnifiedYPosition);

end

function Xiulian_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Xiulian_SetHappyMonth()
		local StartTimeLua, EndTimeLua = DataPool : Lua_GetPowfixTime()
		local StartTime = tonumber(StartTimeLua)
		local EndTime = tonumber(EndTimeLua)
		local tipstr = ""
		local classtipstr = "#{FXDL_120910_21}"
		local classattch = ""

		if(StartTime < 0 or EndTime < 0 or Xiulian_OnHappyMonth()  == 0) then
			tipstr = ""
		else
			local StartMonth,StartDay, EndMonth, EndDay
			StartMonth = math.floor( math.mod(StartTime,10000)/100)
			StartDay    = math.mod( math.mod(StartTime,10000),100)
			EndMonth = math.floor( math.mod(EndTime,10000)/100)
			EndDay    = math.mod( math.mod(EndTime,10000),100)
			-- PushDebugMessage("StartMonth="..StartMonth.."||".."StartDay="..StartDay.."||".."EndMonth="..EndMonth.."||".."EndDay="..EndDay)
			local powValue = DataPool : Lua_GetPowfixValue()
			tipstr = string.format("%s#{FXDL_120910_34}%s#{FXDL_120910_35}%s#{FXDL_120910_34}%s#{FXDL_120910_36}%s#{FXDL_120910_37}",
										StartMonth,StartDay,EndMonth,EndDay,powValue)
			classattch = string.format("%s#{FXDL_120910_34}%s#{FXDL_120910_35}%s#{FXDL_120910_34}%s#{FXDL_120910_36}%s#{FXDL_120910_39}",
										StartMonth,StartDay,EndMonth,EndDay,powValue)

		end
		
		if Player:GetData("IsExpandLevelPlayer") > 0 then
			Xiulian_Vigor:SetToolTip("#{KDJX_250815_04}")
	  	Xiulian_Gongli_Text:SetToolTip("#{KDJX_250815_04}")
	  else
			Xiulian_Vigor : SetToolTip(classtipstr..classattch)
			Xiulian_Gongli_Text : SetToolTip(classtipstr..classattch)
		end
		Xiulian_Gongli_Tooltip : SetToolTip(tipstr)
end

function Xiulian_OnHappyMonth()
	local IsHappyMonth = DataPool : Lua_IsSetPowfix()
	local OnHMTime = DataPool : Lua_OnPowfixTime()
	if IsHappyMonth > 0 and  OnHMTime > 0 then
		return 1
	else
		return 0
	end
end

function Xiulian_SetMergeMonth()
		local StartTimeLua, EndTimeLua = DataPool : Lua_GetPowerTime()
		local StartTime = tonumber(StartTimeLua)
		local EndTime = tonumber(EndTimeLua)
		local tipstr = ""
		local classtipstr = "#{HFHLY_121123_30}"
		local classattch = ""

		if(StartTime < 0 or EndTime < 0 or Xiulian_OnMergeServerMonth()  == 0) then
			tipstr = ""
		else
			local StartMonth,StartDay, EndMonth, EndDay
			StartMonth = math.floor( math.mod(StartTime,10000)/100)
			StartDay    = math.mod( math.mod(StartTime,10000),100)
			EndMonth = math.floor( math.mod(EndTime,10000)/100)
			EndDay    = math.mod( math.mod(EndTime,10000),100)
			--PushDebugMessage("StartMonth="..StartMonth.."||".."StartDay="..StartDay.."||".."EndMonth="..EndMonth.."||".."EndDay="..EndDay)
			local powerValue = DataPool : Lua_GetPowerValue()
			tipstr = string.format("%s#{HFHLY_121123_21}%s#{HFHLY_121123_22}%s#{HFHLY_121123_21}%s#{HFHLY_121123_23}%s#{HFHLY_121123_24}",
										StartMonth,StartDay,EndMonth,EndDay,powerValue)
			classattch = string.format("%s#{HFHLY_121123_21}%s#{HFHLY_121123_22}%s#{HFHLY_121123_21}%s#{HFHLY_121123_25}%s#{HFHLY_121123_26}",
										StartMonth,StartDay,EndMonth,EndDay,powerValue)

		end
		if Player:GetData("IsExpandLevelPlayer") > 0 then
			Xiulian_Vigor:SetToolTip("#{KDJX_250815_04}")
	  	Xiulian_Gongli_Text:SetToolTip("#{KDJX_250815_04}")
	  else
			Xiulian_Vigor : SetToolTip(classtipstr..classattch)
			Xiulian_Gongli_Text : SetToolTip(classtipstr..classattch)
		end
		Xiulian_Gongli_Tooltip : SetToolTip(tipstr)
end

function Xiulian_OnMergeServerMonth()
	local IsMergeSMonth = DataPool : Lua_IsSetPower()
	local OnMergeSTime = DataPool : Lua_OnPowerTime()
	if IsMergeSMonth > 0 and  OnMergeSTime > 0 then
		return 1
	else
		return 0
	end
end

function Xiulian_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Xiulian_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Xiulian_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function Xiulian_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

function Xiulian_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		Xiulian_ShenDing:Disable()
		Xiulian_ShenDing_tips:Show()
	--	Xiulian_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		Xiulian_ShenDing:Enable()
		Xiulian_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		Xiulian_Infant:Disable()
		Xiulian_Infant_tips:Show()
	--	Xiulian_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		Xiulian_Infant:Enable()
		Xiulian_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		Xiulian_Wuhun:Disable()
--		Xiulian_Wuhun_tips:Show()
	--	Xiulian_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		Xiulian_Wuhun:Enable()
		Xiulian_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		Xiulian_Xiulian:Disable()
		Xiulian_Xiulian_tips:Show()
--		Xiulian_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		Xiulian_Xiulian:Enable()
		Xiulian_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		Xiulian_Miji:Disable()
		Xiulian_Miji_tips:Show()
	--	Xiulian_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		Xiulian_Miji:Enable()
		Xiulian_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		Xiulian_ZhenYuan:Disable()
		Xiulian_ZhenYuan_tips:Show()
	--	Xiulian_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		Xiulian_ZhenYuan:Enable()
		Xiulian_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		Xiulian_JueWei:Disable()
		Xiulian_JueWei_tips:Show()
	--	Xiulian_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		Xiulian_JueWei:Enable()
		Xiulian_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		Xiulian_JingMai:Disable()
		Xiulian_JingMai_tips:Show()
	--	Xiulian_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		Xiulian_JingMai:Enable()
		Xiulian_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		Xiulian_BaoJian:Disable()
		Xiulian_BaoJian_tips:Show()
	else
		Xiulian_BaoJian:Enable()
		Xiulian_BaoJian_tips:Hide()
	end

	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		Xiulian_WuYi:Enable()
		Xiulian_WuYi_tips:Hide()
	else
		Xiulian_WuYi:Disable()
		Xiulian_WuYi_tips:Show()
	end
	Xiulian_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		Xiulian_ShenQi:Enable()
		Xiulian_ShenQi_tips:Hide()
	else
		Xiulian_ShenQi:Disable()
		Xiulian_ShenQi_tips:Show()
	end
	Xiulian_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		Xiulian_Armor:Enable()
		Xiulian_Armor_tips:Hide()
	else
		Xiulian_Armor:Disable()
		Xiulian_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		Xiulian_CangPin:Enable()
		Xiulian_CangPin_tips:Hide()
	else
		Xiulian_CangPin:Disable()
		Xiulian_CangPin_tips:Show()
	end
	
	Xiulian_RefreshCangPinTip()
end

function Xiulian_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function Xiulian_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Xiulian_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Xiulian_PageButton[idx]:GetProperty("UnifiedXPosition");
			Xiulian_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		Xiulian_WuYi_Buttontips:Show()
	else
		Xiulian_WuYi_Buttontips:Hide()
	end
end

function Xiulian_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Xiulian_PageButton[idx]:GetProperty("UnifiedXPosition");
			Xiulian_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		Xiulian_OtherInfo_ButtonTips:Show()
	else
		Xiulian_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function Xiulian_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function Xiulian_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Xiulian_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function Xiulian_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Xiulian_PageButton[idx]:GetProperty("UnifiedXPosition");
			Xiulian_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		Xiulian_CangPin_Buttontips:Show()
	else
		Xiulian_CangPin_Buttontips:Hide()
	end
end


function Xiulian_ShowPage()

	for i = 1, table.getn(g_Xiulian_Page) do
		g_Xiulian_PageButton[i]:Hide()
		g_Xiulian_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	Xiulian_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_Xiulian_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_Xiulian_Page) do
			if i ~= nPageNumber then
				g_Xiulian_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_Xiulian_Page) do
		if Xiulian_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_Xiulian_PageButton[g_PageCount]:Show()
			g_Xiulian_PageButton[g_PageCount]:SetText(g_Xiulian_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if Xiulian_IsPageEnable(i) == 1 then
				g_Xiulian_PageButton[g_PageCount]:Enable()
				g_Xiulian_PageMask[g_PageCount]:Hide()
			else
				g_Xiulian_PageButton[g_PageCount]:Disable()
				g_Xiulian_PageMask[g_PageCount]:Show()
				if g_Xiulian_Page[i].Tip ~= "" then
					g_Xiulian_PageMask[g_PageCount]:SetToolTip(g_Xiulian_Page[i].Tip)
				end
			end
		end
	end
	
	Xiulian_RefreshWuYiTip()
	Xiulian_RefreshOtherInfoTip()
	Xiulian_RefreshCangPinTip()
	
end

function Xiulian_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		Xiulian_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		Xiulian_SelfData_Switch()
	elseif idx == 3 then--珍兽
		Xiulian_Pet_Switch()
	elseif idx == 4 then--子女
		Xiulian_Infant_Switch()
	elseif idx == 5 then--武魂
		Xiulian_Wuhun_Switch()
	elseif idx == 6 then--修炼
		Xiulian_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		Xiulian_Miji_Page_Switch()
	elseif idx == 8 then--真元
		Xiulian_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		Xiulian_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		Xiulian_ShenDing_Switch()
	elseif idx == 11 then--侠印
		Xiulian_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		Xiulian_OpenBaoJian()
	elseif idx == 13 then--武意
		Xiulian_OpenWuYi()
	elseif idx == 14 then--神器
		Xiulian_OpenShenQi()
	elseif idx == 15 then--星盘
		Xiulian_Armor_Page_Switch()
	elseif idx == 16 then--名物
		Xiulian_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		Xiulian_Other_Info_Page_Switch()
	end
end

function Xiulian_CheckPage(idx)
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

function Xiulian_IsPageEnable(idx)
	
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

function Xiulian_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


