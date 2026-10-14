--**************************
--至尊豪礼客户端界面
--**************************

local g_tpye = 0;
local g_Prizelevel = 0;
local g_CtrlData = {}
local Zhizunhaoli_Page1_IconName={}
local Zhizunhaoli_Page2_IconName={}
local Zhizunhaoli_Page1_TextName={}
local Zhizunhaoli_Page2_TextName1={}
local Zhizunhaoli_Page2_TextName2={}
local Zhizunhaoli_Page1_BtnName={}
local Zhizunhaoli_Page2_BtnName={}
local Zhizunhaoli_Page2_HuihuaTipName={}
local g_Zhizunhaoli_Frame_UnifiedPosition;

--MF部分
local g_MissionFlagOfZhiZunHaoLi={
[1]={976,977,978,979,980},
[2]={981,982,983,984,985},
[3]={986,987,988,989,990},
[4]={991,992,993,994,995},
[5]={996,997,998,999,1000},
[6]={1001,1002,1003,1004,1005},
[7]={1006,1007,1008,1009,1010},
}

local g_EnhanceCnt={
20,30,40,50,60
}
local g_EnhanceItemCnt={
5,10,30,50,80,
}

local g_CurPage=0
--===============================================
-- OnLoad()
--===============================================
function Zhizunhaoli_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("REFRESH_EQUIP");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
end

function Zhizunhaoli_OnLoad()
	-- g_NewBangHui_YXSS_Frame_UnifiedPosition=NewBangHui_YXSS_Frame:GetProperty("UnifiedPosition");
	Zhizunhaoli_Page1_IconName={
	Zhizunhaoli_Frame2_Icon1,
	Zhizunhaoli_Frame2_Icon2,
	Zhizunhaoli_Frame2_Icon3,
	Zhizunhaoli_Frame2_Icon4,
	Zhizunhaoli_Frame2_Icon5,
	Zhizunhaoli_Frame2_Icon6,
	Zhizunhaoli_Frame2_Icon7,
	}
	Zhizunhaoli_Page2_IconName={
	Zhizunhaoli_Frame3_Icon1,
	Zhizunhaoli_Frame3_Icon2,
	Zhizunhaoli_Frame3_Icon3,
	Zhizunhaoli_Frame3_Icon4,
	Zhizunhaoli_Frame3_Icon5,
	Zhizunhaoli_Frame3_Icon6,
	Zhizunhaoli_Frame3_Icon7,
	}
	Zhizunhaoli_Page1_TextName={
	Zhizunhaoli_Frame2_Text1,
	Zhizunhaoli_Frame2_Text2,
	Zhizunhaoli_Frame2_Text3,
	Zhizunhaoli_Frame2_Text4,
	Zhizunhaoli_Frame2_Text5,
	Zhizunhaoli_Frame2_Text6,
	Zhizunhaoli_Frame2_Text7,
	}
	Zhizunhaoli_Page2_TextName1={
	Zhizunhaoli_Frame3_Text1_1,
	Zhizunhaoli_Frame3_Text2_1,
	Zhizunhaoli_Frame3_Text3_1,
	Zhizunhaoli_Frame3_Text4_1,
	Zhizunhaoli_Frame3_Text5_1,
	Zhizunhaoli_Frame3_Text6_1,
	Zhizunhaoli_Frame3_Text7_1,
	}
	Zhizunhaoli_Page2_TextName2={
	Zhizunhaoli_Frame3_Text1_2,
	Zhizunhaoli_Frame3_Text2_2,
	Zhizunhaoli_Frame3_Text3_2,
	Zhizunhaoli_Frame3_Text4_2,
	Zhizunhaoli_Frame3_Text5_2,
	Zhizunhaoli_Frame3_Text6_2,
	Zhizunhaoli_Frame3_Text7_2,
	}
	Zhizunhaoli_Page1_BtnName={
	Zhizunhaoli_Frame2_Button1,
	Zhizunhaoli_Frame2_Button2,
	Zhizunhaoli_Frame2_Button3,
	Zhizunhaoli_Frame2_Button4,
	Zhizunhaoli_Frame2_Button5,
	Zhizunhaoli_Frame2_Button6,
	Zhizunhaoli_Frame2_Button7,
	}
	Zhizunhaoli_Page2_BtnName={
	Zhizunhaoli_Frame3_Button1,
	Zhizunhaoli_Frame3_Button2,
	Zhizunhaoli_Frame3_Button3,
	Zhizunhaoli_Frame3_Button4,
	Zhizunhaoli_Frame3_Button5,
	Zhizunhaoli_Frame3_Button6,
	Zhizunhaoli_Frame3_Button7,
	}
	
	Zhizunhaoli_Paga1_Tips=
	{
		Zhizunhaoli_Frame2_Button1_tips,
		Zhizunhaoli_Frame2_Button2_tips,
		Zhizunhaoli_Frame2_Button3_tips,
		Zhizunhaoli_Frame2_Button4_tips,
		Zhizunhaoli_Frame2_Button5_tips,
		Zhizunhaoli_Frame2_Button6_tips,
		Zhizunhaoli_Frame2_Button7_tips,
	}

	Zhizunhaoli_Page2_HuihuaTipName={
	Zhizunhaoli_Frame3_Button1_tips,
	Zhizunhaoli_Frame3_Button2_tips,
	Zhizunhaoli_Frame3_Button3_tips,
	Zhizunhaoli_Frame3_Button4_tips,
	Zhizunhaoli_Frame3_Button5_tips,
	Zhizunhaoli_Frame3_Button6_tips,
	Zhizunhaoli_Frame3_Button7_tips,
	}
		g_CtrlData = {
		[1] = {itemcount = 10, freecount = 4,costyuanbao = 2000,bagepos = 1,tips=""},
		[2] = { itemcount = 25, freecount = 12,costyuanbao = 5000,bagepos = 1,tips="#{ZZQH_140606_66}"},
		[3] = { itemcount = 50, freecount = 26, costyuanbao = 10000,bagepos = 1,tips="#{ZZQH_140606_93}"},
		[4] = { itemcount = 100, freecount = 55, costyuanbao = 20000,bagepos = 1,tips="#{ZZQH_140606_94}"},
		[5] = { itemcount = 250, freecount = 150, costyuanbao = 50000,bagepos = 2,tips="#{ZZQH_140606_95}"},
		[6] = { itemcount = 500, freecount = 320,costyuanbao = 100000,bagepos = 4,tips="#{ZZQH_140606_96}"},
		[7] = { itemcount = 1250, freecount = 900,costyuanbao = 250000,bagepos = 1,tips="#{ZZQH_140606_97}"},

		}
		
		g_Zhizunhaoli_Frame_UnifiedPosition = Zhizunhaoli_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function Zhizunhaoli_OnEvent( event )

	if (event == "UI_COMMAND") and (tonumber(arg0) == 20140607) then
		local ntype = Get_XParam_INT(0)
		local ndate = Get_XParam_INT(1)
		local nLevel = Get_XParam_INT(2)
		g_Prizelevel = nLevel;
		Zhizunhaoli_SetLeaveTime(ntype,ndate)
		Zhizunhaoli_Frame2:Show()
		Zhizunhaoli_Frame3:Hide()
		g_CurPage=1
		Zhizunhaoli_UpdataFame2()
		--说明：这里有问题，UI记忆上次的分页，再次打开会出现混乱
		--由于第一个分页未区分打开还是更新，故，这里暂时先用setcheck方法来解决
		--结果：通过playerframe打开的界面永远是第一个分页，点击本UI上面的分页Button才能切换到第二个分页
		--Zhizunhaoli_Frame1_ZjjhczzFenye:SetCheck(1)
		--Zhizunhaoli_Frame1_SzqhhkzFenye:SetCheck(0)
		Zhizunhaoli_Frame1:Hide()
		Zhizunhaoli_Frame1_ZjjhczzFenye:Hide()
		Zhizunhaoli_Frame1_SzqhhkzFenye:Hide()
		this:Show()
	elseif (event == "UI_COMMAND") and (tonumber(arg0) == 8908500) then
		local ntype = Get_XParam_INT(0)
		local ndate = Get_XParam_INT(1)
		local nOpenFlag = Get_XParam_INT(2)
		Zhizunhaoli_SetLeaveTime(ntype,ndate)	
		Zhizunhaoli_UpdatePage2()
		if nOpenFlag==1 then
			Zhizunhaoli_Frame1_ZjjhczzFenye:SetCheck(0)
			Zhizunhaoli_Frame1_SzqhhkzFenye:SetCheck(1)
			this:Show()
		end
		g_CurPage=2
	elseif (event == "REFRESH_EQUIP" and this:IsVisible()) then
		if (g_CurPage==2) then
			Zhizunhaoli_UpdatePage2()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "ADJEST_UI_POS") then
		Zhizunhaoli_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Zhizunhaoli_On_ResetPos()
	end
	--MissionFlag还是由server端发起吧
	--装备拖拽不更新剩余多少时间了！！
end

function Zhizunhaoli_Frame2_GetGift1()
	Zhizunhaoli_AskBuyQianghua(1)
end

function Zhizunhaoli_Frame2_GetGift2()
	Zhizunhaoli_AskBuyQianghua(2)
end

function Zhizunhaoli_Frame2_GetGift3()
	Zhizunhaoli_AskBuyQianghua(3)
end

function Zhizunhaoli_Frame2_GetGift4()
	Zhizunhaoli_AskBuyQianghua(4)
end

function Zhizunhaoli_Frame2_GetGift5()
	Zhizunhaoli_AskBuyQianghua(5)
end

function Zhizunhaoli_Frame2_GetGift6()
	Zhizunhaoli_AskBuyQianghua(6)
end

function Zhizunhaoli_Frame2_GetGift7()
	Zhizunhaoli_AskBuyQianghua(7)
end

function Zhizunhaoli_UpdataFame2()
	for i=1,7 do
		if g_Prizelevel >= i then
			Zhizunhaoli_Page1_BtnName[i]:Disable()
			Zhizunhaoli_Paga1_Tips[i]:Show()
		else
			Zhizunhaoli_Page1_BtnName[i]:Enable()
			Zhizunhaoli_Paga1_Tips[i]:Hide()
		end
	end
end

function Zhizunhaoli_ZjjhczzClick()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ClientAskOpenFrame");
		Set_XSCRIPT_ScriptID(890890);
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT();		
end

function Zhizunhaoli_AskBuyQianghua(nType)
	--活动已经结束
	if g_tpye == 5 then
		PushDebugMessage("#{ZZQH_140606_59}");
		return
	end
	--等级不够
	if Player:GetLevel() < 15 then
		PushDebugMessage("#{ZZQH_140606_60}")
		return
	end
	-- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZQH_140606_61}")
		return
	end	
	--判断高级密保
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end	
	--判断是否购买过这个等级的
	if g_Prizelevel >= nType then
		PushDebugMessage("#{ZZQH_140606_67}")
		return
	end
	
	--判断是否可以买这个
	if nType ~= g_Prizelevel+1 then
		local sendmsg = g_CtrlData[nType].tips;
		PushDebugMessage(sendmsg)
		return	
	end
	
	--元宝判断
	local nYuanBao=Player:GetData("YUANBAO")
	if nYuanBao < g_CtrlData[nType].costyuanbao then
		PushDebugMessage("#{ZZQH_140606_69}")
		return
	end
	--弹二次确认框
	
	PushEvent("ZHIZUNHAOLI_CONFIRM",tostring(g_CtrlData[nType].costyuanbao),
					tostring(g_CtrlData[nType].itemcount), tostring(g_CtrlData[nType].freecount),tostring(nType))
	-- Clear_XSCRIPT();
		-- Set_XSCRIPT_Function_Name("ClientAskAward");
		-- Set_XSCRIPT_ScriptID(890890);
		-- Set_XSCRIPT_Parameter(0,nType);
		-- Set_XSCRIPT_ParamCount(1)
	-- Send_XSCRIPT();		
end

function Zhizunhaoli_AskOpenFrame()

end

function Zhizunhaoli_SetLeaveTime(ntype,ndate)
	local nowtype = tonumber(ntype)
	local nowdate = tonumber(ndate)
	local strneed = ""
	strneed = Zhizunhaoli_SetTimetipsData("#{ZZQH_140606_06}", nowtype, nowdate)
	Zhizunhaoli_Shuoming_Frame_lace_Text:SetText(strneed)
	g_tpye = ntype;
end

function Zhizunhaoli_SetTimetipsData(DirStr, nowtype,nowdate)
	local lstrneed = ""
		if(nowtype == 1) then
			lstrneed = ScriptGlobal_Format(DirStr,nowdate.."天")
		elseif(nowtype == 2) then
			lstrneed = ScriptGlobal_Format(DirStr,nowdate.."小时")
		elseif(nowtype == 3) then
			lstrneed = ScriptGlobal_Format(DirStr,nowdate.."分")
		elseif(nowtype == 4) then
			lstrneed = ScriptGlobal_Format(DirStr,"不足一分钟")
		elseif(nowtype == 5) then
			lstrneed = ScriptGlobal_Format(DirStr,"#{ZZQH_140606_08}")
		end
		return lstrneed
end

function Zhizunhaoli_SzqhhkzClick()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ZhiZunHaoLiOpenUI");
		Set_XSCRIPT_ScriptID(890850);
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT();		
end

function Zhizunhaoli_UpdatePage2()
	--page1隐藏，page2显示
	Zhizunhaoli_Frame2:Hide()
	Zhizunhaoli_Frame3:Show()
	--说明：按钮分层，隐藏了
	--武器，龙纹，  暗器， 护腕，  项链，	戒指，	护符
--[1 5] [6 10] [11 15] [16 20] [21 25] [26 30] [31 35]
	local ActionEquip={}
	ActionEquip[1]=EnumAction(0, "equip")--武器
	ActionEquip[2]=EnumAction(19, "equip")--龙纹
	ActionEquip[3]=EnumAction(17, "equip")--暗器
	ActionEquip[4]=EnumAction(14, "equip")--护腕
	ActionEquip[5]=EnumAction(7, "equip")--项链
	ActionEquip[6]=EnumAction(6, "equip")--戒指
	ActionEquip[7]=EnumAction(12, "equip")--护符
	ActionEquip[8]=EnumAction(11, "equip")--戒指2
	ActionEquip[9]=EnumAction(13, "equip")--护符2
	local arrEnhanceLevel={}
	local arrBindStatus={}
	local arrIsChongLou={}
	for i=1,9 do
		arrEnhanceLevel[i],arrBindStatus[i],arrIsChongLou[i]=ActionEquip[i]:GetStrengthenLevel()
	end
	local arrRealEnhanceLevel={0,0,0,0,0,0,0,0,0}
	for i=1,9 do
		if arrBindStatus[i]==1 or arrIsChongLou[i]==1 then
			arrRealEnhanceLevel[i]=arrEnhanceLevel[i]
		else
			arrRealEnhanceLevel[i]=0--是否装备，点击确认按钮才会判断
		end
	end
	if arrRealEnhanceLevel[8]>arrRealEnhanceLevel[6] then
		arrRealEnhanceLevel[6]=arrRealEnhanceLevel[8]
	end
	if arrRealEnhanceLevel[9]>arrRealEnhanceLevel[7] then
		arrRealEnhanceLevel[7]=arrRealEnhanceLevel[9]
	end

	local strDictory1={"#{ZZQH_140606_33}","#{ZZQH_140606_38}","#{ZZQH_140606_41}","#{ZZQH_140606_44}","#{ZZQH_140606_47}","#{ZZQH_140606_50}","#{ZZQH_140606_53}"}
	local strBlue={"#{ZZQH_140606_35}","#{ZZQH_140606_82}","#{ZZQH_140606_84}","#{ZZQH_140606_86}","#{ZZQH_140606_88}","#{ZZQH_140606_90}","#{ZZQH_140606_92}"}
	local strRed={"#{ZZQH_140606_34}","#{ZZQH_140606_81}","#{ZZQH_140606_83}","#{ZZQH_140606_85}","#{ZZQH_140606_87}","#{ZZQH_140606_89}","#{ZZQH_140606_91}"}
	for i=1,7 do
		local indexOfFlag,GetOut=Zhizunhaoli_GetPrizePhrase(i)
		if GetOut==1 then
			local szShow={"#{ZZQH_140606_112}","#{ZZQH_140606_113}","#{ZZQH_140606_114}","#{ZZQH_140606_115}","#{ZZQH_140606_116}","#{ZZQH_140606_117}","#{ZZQH_140606_118}"}
			Zhizunhaoli_Page2_TextName1[i]:SetText(szShow[i])
			Zhizunhaoli_Page2_TextName2[i]:SetText("")
		else
			local szShow=ScriptGlobal_Format( strDictory1[i], g_EnhanceCnt[indexOfFlag], g_EnhanceItemCnt[indexOfFlag])
			Zhizunhaoli_Page2_TextName1[i]:SetText(szShow)
	
			local szCurPhase=""
			if (arrRealEnhanceLevel[i] >= g_EnhanceCnt[indexOfFlag]) then
				szCurPhase=ScriptGlobal_Format(strBlue[i],arrRealEnhanceLevel[i],g_EnhanceCnt[indexOfFlag])--绿字
			else
				szCurPhase=ScriptGlobal_Format(strRed[i],arrRealEnhanceLevel[i],g_EnhanceCnt[indexOfFlag])--红字
			end

			Zhizunhaoli_Page2_TextName2[i]:SetText(szCurPhase)
		end
		if GetOut==1 then
			Zhizunhaoli_Page2_BtnName[i]:Disable()
			Zhizunhaoli_Page2_HuihuaTipName[i]:Show()
		else
			Zhizunhaoli_Page2_BtnName[i]:Enable()
			Zhizunhaoli_Page2_HuihuaTipName[i]:Hide()
		end
	end
end

function Zhizunhaoli_GetPrizePhrase(index)
	for i=1,5 do
		if Pneuma:GetMF(g_MissionFlagOfZhiZunHaoLi[index][i])==0 then
			return i,0
		end
	end
	return 5,1
end

function Zhizunhaoli_Frame3_GetGift(index)
	if index<1 or index>7 then
		return
	end
	--活动已经结束
	if g_tpye == 5 then
		PushDebugMessage("#{ZZQH_140606_59}");
		return
	end
	--等级不够
	if Player:GetLevel() < 15 then
		PushDebugMessage("#{ZZQH_140606_60}")
		return
	end
	-- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZQH_140606_61}")
		return
	end
	--判断高级密保
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	local indexOfFlag,GetOut=Zhizunhaoli_GetPrizePhrase(index)
	if GetOut==1 then
		PushDebugMessage("#{ZZQH_140606_77}")
		return
	end
	local equipPos={0,19,17,14,7,6,12,11,13}
	local realEnhanceLevel=0
	if index>=1 and index<=5 then
		local ActionEquip=EnumAction(equipPos[index], "equip")
		local EnhanceLevel,BindStatus,IsChongLou=ActionEquip:GetStrengthenLevel()
		--EnhanceLevel==-1表示未穿装备
		if EnhanceLevel==-1 then
			realEnhanceLevel=-1
		elseif BindStatus==1 or IsChongLou==1 then
			realEnhanceLevel=EnhanceLevel
		end
	else
		--realEnhanceLevel=-1表示未装备
		local ActionEquip=EnumAction(equipPos[index], "equip")
		local EnhanceLevel,BindStatus,IsChongLou=ActionEquip:GetStrengthenLevel()
		if EnhanceLevel==-1 then
			realEnhanceLevel=-1
		elseif BindStatus==1 or IsChongLou==1 then
			realEnhanceLevel=EnhanceLevel
		end
		--
		local ActionEquip=EnumAction(equipPos[index+2], "equip")
		local EnhanceLevel2,BindStatus2,IsChongLou2=ActionEquip:GetStrengthenLevel()
		if EnhanceLevel2~=-1 then--修正而已
			if realEnhanceLevel==-1 then
				realEnhanceLevel=0
			end
			if BindStatus2==1 or IsChongLou2==1 then
				if EnhanceLevel2>realEnhanceLevel then
					realEnhanceLevel=EnhanceLevel2
				end
			end
		end
	end
	local strEquipName={"#{ZZQH_140606_98}","#{ZZQH_140606_99}","#{ZZQH_140606_100}","#{ZZQH_140606_101}","#{ZZQH_140606_102}","#{ZZQH_140606_103}","#{ZZQH_140606_104}"}
	if realEnhanceLevel==-1 then
		local szTips=ScriptGlobal_Format("#{ZZQH_140606_119}",strEquipName[index])
		PushDebugMessage(szTips)
		return
	end
	if realEnhanceLevel<g_EnhanceCnt[indexOfFlag] then
		local szTips=ScriptGlobal_Format("#{ZZQH_140606_78}",strEquipName[index],g_EnhanceCnt[indexOfFlag])
		PushDebugMessage(szTips)
		return
	end
	--有空把是否有资格领取也做客户端吧！
	--不繁琐了，其他检测放到服务器端

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ZhiZunHaoLiClick");
		Set_XSCRIPT_ScriptID(890850);
		Set_XSCRIPT_Parameter(0,index);
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();
end

function Zhizunhaoli_On_ResetPos()
	Zhizunhaoli_Frame:SetProperty("UnifiedPosition", g_Zhizunhaoli_Frame_UnifiedPosition)
end
