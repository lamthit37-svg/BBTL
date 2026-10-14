local g_MenpaiList = {}
local g_WLBook_button_DZMP = {}
local g_WLBook_UnifiedPosition =nil;
function WLBook_PreLoad()
	this:RegisterEvent("OPEN_WLBOOK")
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
end

function WLBook_OnLoad()
	g_MenpaiList[1] = { Info1 = "#{XSZY_130909_75}",Info2="#{XSZY_130909_76}",Joinstr="#{XSZY_130909_77}",
		male="set:NewFreshMan_TM image:NewFreshMan_TM_Man",
		female="set:NewFreshMan_TM image:NewFreshMan_TM_Girl"}  --唐门
	g_MenpaiList[2] = { Info1 = "#{XSZY_130909_51}",Info2="#{XSZY_130909_52}",Joinstr="#{XSZY_130909_53}",
		male="set:NewFreshMan_SL image:NewFreshMan_SL_Man",
		female="set:NewFreshMan_SL image:NewFreshMan_SL_Girl"}  --少林
	g_MenpaiList[3] = { Info1 = "#{XSZY_130909_35}",Info2="#{XSZY_130909_36}",Joinstr="#{XSZY_130909_37}",
		male="set:NewFreshMan_GB image:NewFreshMan_GB_Man",
		female="set:NewFreshMan_GB image:NewFreshMan_GB_Girl",}  --丐帮
	g_MenpaiList[4] = { Info1 = "#{XSZY_130909_39}",Info2="#{XSZY_130909_40}",Joinstr="#{XSZY_130909_41}",
		male="set:NewFreshMan_MJ image:NewFreshMan_MJ_Man",
		female="set:NewFreshMan_MJ image:NewFreshMan_MJ_Girl"}  --明教
	g_MenpaiList[5] = { Info1 = "#{XSZY_130909_43}",Info2="#{XSZY_130909_44}",Joinstr="#{XSZY_130909_45}",
		male="set:NewFreshMan_WD image:NewFreshMan_WD_Man",
		female="set:NewFreshMan_WD image:NewFreshMan_WD_Girl"}  --武当
	g_MenpaiList[6] = { Info1 = "#{XSZY_130909_59}",Info2="#{XSZY_130909_60}",Joinstr="#{XSZY_130909_61}",
		male="set:NewFreshMan_TL image:NewFreshMan_TL_Man",
		female="set:NewFreshMan_TL image:NewFreshMan_TL_Girl",}  --天龙
	g_MenpaiList[7] = { Info1 = "#{XSZY_130909_67}",Info2="#{XSZY_130909_68}",Joinstr="#{XSZY_130909_69}",
		male="set:NewFreshMan_XY image:NewFreshMan_XY_Man",
		female="set:NewFreshMan_XY image:NewFreshMan_XY_Girl",}  --逍遥
	g_MenpaiList[8] = { Info1 = "#{XSZY_130909_47}",Info2="#{XSZY_130909_48}",Joinstr="#{XSZY_130909_49}",
		male="set:NewFreshMan_EM image:NewFreshMan_EM_Man",
		female="set:NewFreshMan_EM image:NewFreshMan_EM_Girl",}  --峨眉
	g_MenpaiList[9] = { Info1 = "#{XSZY_130909_55}",Info2="#{XSZY_130909_56}",Joinstr="#{XSZY_130909_57}",
		male="set:NewFreshMan_XS image:NewFreshMan_XS_Man",
		female="set:NewFreshMan_XS image:NewFreshMan_XS_Girl",}  --星宿
	g_MenpaiList[10] = { Info1 = "#{XSZY_130909_63}",Info2="#{XSZY_130909_64}",Joinstr="#{XSZY_130909_65}",
		male="set:NewFreshMan_TS image:NewFreshMan_TS_Man",
		female="set:NewFreshMan_TS image:NewFreshMan_TS_Girl",}  --天山
	g_MenpaiList[11] = { Info1 = "#{XSZY_130909_71}",Info2="#{XSZY_130909_72}",Joinstr="#{XSZY_130909_73}",
		male="set:NewFreshMan_MR image:NewFreshMan_MR_Man",
		female="set:NewFreshMan_MR image:NewFreshMan_MR_Girl",}  --慕容
	g_MenpaiList[12] = { Info1 = "#{XMPGG_160524_06}",Info2="#{XMPGG_160524_07}",Joinstr="#{XMPGG_160524_08}",
		male="set:NewFreshMan_GG image:NewFreshMan_GG_Man",
		female="set:NewFreshMan_GG image:NewFreshMan_GG_Girl",}  --鬼谷
	g_MenpaiList[13] = { Info1 = "#{THDJS_190719_01}",Info2="#{THDJS_190719_02}",Joinstr="#{THDJS_190719_03}",
		male="set:NewFreshMan_THD image:NewFreshMan_THD_Man",
		female="set:NewFreshMan_THD image:NewFreshMan_THD_Girl",}  --桃花岛
	g_MenpaiList[14] = { Info1 = "#{XMPHM_210604_12}",Info2="#{XMPHM_210604_13}",Joinstr="#{XMPHM_210604_14}",
		male="set:NewFreshMan_HM image:NewFreshMan_HM_Man",
		female="set:NewFreshMan_HM image:NewFreshMan_HM_Girl",}  --
	g_MenpaiList[15] = { Info1 = "#{MPSC_240701_1}",Info2="#{MPSC_240701_2}",Joinstr="#{MPSC_240701_3}",
		male="set:NewFreshMan_ERG image:NewFreshMan_ERG_Man",
		female="set:NewFreshMan_ERG image:NewFreshMan_ERG_Girl",}--menpai15 mptodo --新门派-恶人谷-ypl-江湖指南等 缺少：male 和 famale的图片

	g_WLBook_button_DZMP[1] = WLBook_MenPai_ShaoLin
	g_WLBook_button_DZMP[2] = WLBook_MenPai_MingJiao
	g_WLBook_button_DZMP[3] = WLBook_MenPai_GaiBang
	g_WLBook_button_DZMP[4] = WLBook_MenPai_WuDang
	g_WLBook_button_DZMP[5] = WLBook_MenPai_EMei
	g_WLBook_button_DZMP[6] = WLBook_MenPai_XingXiu
	g_WLBook_button_DZMP[7] = WLBook_MenPai_Tianlong
	g_WLBook_button_DZMP[8] = WLBook_MenPai_TianShan
	g_WLBook_button_DZMP[9] = WLBook_MenPai_XiaoYao
	g_WLBook_button_DZMP[10] = WLBook_MenPai_MuRong
	g_WLBook_button_DZMP[11] = WLBook_MenPai_TangMen
	g_WLBook_button_DZMP[12] = WLBook_MenPai_GuiGu
	g_WLBook_button_DZMP[13] = WLBook_MenPai_TaoHuaDao
	g_WLBook_button_DZMP[14] = WLBook_MenPai_HongMing
	g_WLBook_button_DZMP[15] = WLBook_MenPai_ERenGu--menpai15 mptodo
end

function WLBook_OnEvent(event)
	if( event == "OPEN_WLBOOK") then
		CloseFreshManGuide()
		WLBook_MenPaiClicked(15)
		WLBook_MenPai_ERenGu:SetCheck(1)
		WLBook_DingZhiMenPai()
		WLBook_CJDingZhiMenPai()
		this:Show()
	end
end

function WLBook_DingZhiMenPai()	
	if DataPool:Lua_IsNewServerPlayer() == 0 then
		return
	end
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	local MenPaiInfo = Lua_GetDingZhiMenPaiSvrInfo(selfZoneWorldID)
	if type(MenPaiInfo) ~= "table" then
		return
	end
	WLBook_MenPai_ERenGu:SetCheck(0)
	WLBook_MenPai_ShaoLin:SetCheck(1)
	WLBook_MenPaiClicked(2) 
	for index=1, table.getn(MenPaiInfo) do 
		if MenPaiInfo[index] == 0 then
			g_WLBook_button_DZMP[index]:Disable()
		end
	end 
end

function WLBook_CJDingZhiMenPai()	 
	if Lua_GetDingZhiMenPaiCJFlag() ~= 1 then 
		WLBook_MenpaiFrame:Show()
		WLBook_MenpaiFrame_SJ:Hide()
		WLBook_MenPaiClicked(15)
		WLBook_MenPai_ERenGu:SetCheck(1)
		WLBook_MenPai_ShaoLin:SetCheck(0)
	else
		WLBook_MenpaiFrame:Hide()
		WLBook_MenpaiFrame_SJ:Show()	 
		WLBook_MenPai_ShaoLin_SJ:SetCheck(1)	
		WLBook_MenPaiClicked(2)
	end
end

function WLBook_OnHide()
		this:Hide()
end

function WLBook_MenPaiClicked(Index)

	if Index > 15 or Index < 1 then
		return 
	end
	
	WLBook_ExplainFrame1_Text:SetText(g_MenpaiList[Index].Info1);
	WLBook_ExplainFrame2_Text:SetText(g_MenpaiList[Index].Info2);
	WLBook_NpcPoint:SetText(g_MenpaiList[Index].Joinstr);
	
	local iSexy = Player:GetMySex()
	
	if iSexy == 1 then
		WLBook_ImageFrame:SetProperty("Image", g_MenpaiList[Index].male);
	else
		WLBook_ImageFrame:SetProperty("Image", g_MenpaiList[Index].female);
	end
	
end