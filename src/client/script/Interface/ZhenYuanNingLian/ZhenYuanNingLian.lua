--*********************
--真元凝练界面
--*********************
local ActionButtonName={}
local NingLianBtnName ={}

local Pneuma_EquipPos=0
local Pneuma_Bag=36
local Pneuma_SmeltBag=72
local Pneuma_Size=24

local g_CurSelect=-1
local g_bOpened=0

local g_InAllNingLian=0
local g_InQuickNingLian=0
local g_PneumaChip_Needed=20

local nLevelFlag={1,0,0,0,0}
local nALevelFlag={0,0}

local g_targetId=-1

local g_TipsNum_ZhuShenBing = 0 --显示到第几个tips了
local g_TipsNum_HanRuHai = 0 --显示到第几个tips了
local g_bShowTips=0
local ZhenYuan_NewerMission_HanRuHai = 1603
local ZhenYuan_Mission_ZhuShenBing = 1601
local g_MissionFlag={
-1,604,605,606,607,
}
local g_MissionFlag_A={
601,602,
}
local g_Max_Vip_Level = 9
local g_QuikNiangLian_JC={--次数
250,500,2500,5000
}
local g_QuikNiangLian_Sel=1

function ZhenYuanNingLian_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("PNEUMAITEM_CHANGED");
	this:RegisterEvent("PNEUMA_EXPCHIP_CHANGED");
	this:RegisterEvent("PNEUMA_MISSIONFLAG");
	this:RegisterEvent("NINGLAINALL_CUIJIECONFIRM_OK")
	this:RegisterEvent("NINGLAINALL_CUIJIECONFIRM_CANCEL")
	this:RegisterEvent("SHOW_VIP_BUTTON")
	this:RegisterEvent("UPDATE_YUANBAO");
	this:RegisterEvent("PNEUMA_QUICKONCENY_BACK")--服务器回包
	this:RegisterEvent("PNEUMA_QUICKONCENY_QR")
	this:RegisterEvent("OPEN_ONE_PARAM_WINDOW")--其实只是传参
end


function ZhenYuanNingLian_OnLoad()
	ActionButtonName={
	ZhenYuanNingLian_Item1, ZhenYuanNingLian_Item2, ZhenYuanNingLian_Item3, ZhenYuanNingLian_Item4,
	ZhenYuanNingLian_Item5, ZhenYuanNingLian_Item6, ZhenYuanNingLian_Item7, ZhenYuanNingLian_Item8,
	ZhenYuanNingLian_Item9, ZhenYuanNingLian_Item10, ZhenYuanNingLian_Item11, ZhenYuanNingLian_Item12,
	ZhenYuanNingLian_Item13, ZhenYuanNingLian_Item14, ZhenYuanNingLian_Item15, ZhenYuanNingLian_Item16,
	ZhenYuanNingLian_Item17, ZhenYuanNingLian_Item18, ZhenYuanNingLian_Item19, ZhenYuanNingLian_Item20,
	ZhenYuanNingLian_Item21, ZhenYuanNingLian_Item22, ZhenYuanNingLian_Item23, ZhenYuanNingLian_Item24
	}
	NingLianBtnName={
	ZhenYuanNingLian_Level1_Button,ZhenYuanNingLian_Level2_Button,ZhenYuanNingLian_Level3_Button,
	ZhenYuanNingLian_Level4_Button,ZhenYuanNingLian_Level5_Button,
	}
	g_InAllNingLian=0
	g_InQuickNingLian=0
	ZhenYuanNingLian_NingLianAll_Button:SetText("#{ZYXT_120528_73}")--开始一键凝练
end


function ZhenYuanNingLian_Close()

end

function ZhenYuanNingLian_OnEvent( event )
	if ( event=="UI_COMMAND" and tonumber(arg0) == 88990001 ) then
		local xx = Get_XParam_INT(0);
		g_targetId = DataPool : GetNPCIDByServerID(xx);
		if g_targetId == -1 then
			return
		end
		ZhenYuanNingLian_BeginCareObject()
		g_bShowTips = 0
		---如果有任务增加引到tips
		local missionIndex_zhushenbing = DataPool:GetPlayerMissionIndexByID(ZhenYuan_Mission_ZhuShenBing)
		local paramIfCompelete_zhenshenbing = 0
		local haveAcc_zhushenbing = 0
		if missionIndex_zhushenbing >= 0 and missionIndex_zhushenbing < 20 then
			haveAcc_zhushenbing = 1
			paramIfCompelete_zhenshenbing = DataPool:GetPlayerMission_Variable(missionIndex_zhushenbing, 0)
		end
		if haveAcc_zhushenbing == 1 and paramIfCompelete_zhenshenbing == 0 then
			g_bShowTips = 1
		end
		g_TipsNum_ZhuShenBing = 0
		g_TipsNum_HanRuHai = 0
		if (g_bShowTips == 1) and (g_TipsNum_ZhuShenBing == 0) then
			local fX, fY = this:GetChildOffset("ZhenYuanNingLian_NingYuan_Button")
			fX = fX + ZhenYuanNingLian_NingYuan_Button:GetProperty("AbsoluteWidth") / 2
			fY = fY + 20
			OpenFreshManGuide(1, 24, fX, fY, "ZhenYuanNingLian", "northwest")
			g_TipsNum_ZhuShenBing = 1
		end
		--引导tips 翰如海
		local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_NewerMission_HanRuHai)
		local paramIfCompelete = 0
		local paramIfCompelete1 = 0
		--local paramIfCompelete2 = 0
		if missionIndex >= 0 and missionIndex < 20 then
			paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
			if paramIfCompelete == 0 then
				g_bShowTips = 2
			end
			--是否第一次点击凝元
			paramIfCompelete1 = DataPool:GetPlayerMission_Variable(missionIndex, 2)
			--是否已经第二次点击凝元
			--paramIfCompelete2 = DataPool:GetPlayerMission_Variable(missionIndex, 3)
		end
		if (g_bShowTips == 2) and (g_TipsNum_HanRuHai == 0) and ( paramIfCompelete ~= 1) and (paramIfCompelete1 == 0) then
			local fX, fY = this:GetChildOffset("ZhenYuanNingLian_NingYuan_Button")
			fX = fX + ZhenYuanNingLian_NingYuan_Button:GetProperty("AbsoluteWidth") / 2
			fY = fY + 20
			OpenFreshManGuide(1, 29, fX, fY, "ZhenYuanNingLian", "northwest")
			g_TipsNum_HanRuHai = 1
		end

		--if paramIfCompelete1 == 1 and g_bShowTips == 2 and paramIfCompelete2 == 0 then-- nClk == 1 and
		--	local fX, fY = this:GetChildOffset("ZhenYuanNingLian_Level2_Button")
		--	fY = fY + 23
		--	fX = fX + ZhenYuanNingLian_Level2_Button:GetProperty("AbsoluteWidth") / 2
		--	OpenFreshManGuide(1, 30, fX, fY, "ZhenYuanNingLian", "northwest")
		--	g_TipsNum_HanRuHai = 2
		--end

		if paramIfCompelete ~= 1  and g_bShowTips == 2 and paramIfCompelete1 == 1 then--and nClk == 2
			local fX, fY = this:GetChildOffset("ZhenYuanNingLian_Item1")
			fX = fX + ZhenYuanNingLian_Item1:GetProperty("AbsoluteWidth") / 2
			fY = fY + 20
			OpenFreshManGuide(1, 31, fX, fY, "ZhenYuanNingLian", "northwest")
		end
		--
		ZhenYuanNingLian_OnShow()
		--聚元
		ZhenYuanNingLian_JuYuanShow()
		--显示凝练过程中的淬解选项
		ZhenYuanNingLian_ChioceShow()
		this:Show()
		return
	elseif (event=="PNEUMAITEM_CHANGED" and this:IsVisible()) then
		ZhenYuanNingLian_OnShow()
	elseif (event=="PNEUMA_QUICKONCENY_BACK") then
		if this:IsVisible() then
			if tonumber(arg0)==0 then--error
			else--ok
				ZhenYuanNingLian_OnShow()
			end
		end
		g_InQuickNingLian=0
	elseif (event=="PNEUMA_QUICKONCENY_QR" and this:IsVisible() and tonumber(arg0)==1) then
		ZhenYuanNingLian_QuickNingYuan(1)
	elseif (event=="PNEUMA_EXPCHIP_CHANGED" and this:IsVisible()) then
		local exp=Pneuma:GetPneumaExp()
		ZhenYuanNingLian_ZhenYuanYuanJing_Text2:SetText(exp)
		local chip=Pneuma:GetPneumaChip()
		ZhenYuanNingLian_ZhenYuanSuiPian_Text2:SetText(chip)
	elseif (event=="NINGLAINALL_CUIJIECONFIRM_OK") then
	--PushDebugMessage("NINGLAINALL_CUIJIECONFIRM_OK")
		--开始特殊的一键凝练
		ZhenYuanNingLian_SPAllNingLian_Start()
	elseif (event=="NINGLAINALL_CUIJIECONFIRM_CANCEL") then
		ZhenYuanNingLian_AllNingLian_StrongEnd(0)
	elseif ((event=="SHOW_VIP_BUTTON" or event=="UPDATE_YUANBAO" or event=="PNEUMA_MISSIONFLAG") and this:IsVisible()) then
		ZhenYuanNingLian_ShowNingLianBtn()
		ZhenYuanNingLian_JuYuanShow()
	elseif (event=="OPEN_ONE_PARAM_WINDOW" and tostring(arg0)=="ZhenYuanNingLian") then
		local sel=tonumber(arg1)
		if g_QuikNiangLian_JC[sel]~=nil then
			g_QuikNiangLian_Sel=sel
		end
	end
end
--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function ZhenYuanNingLian_BeginCareObject()
	this:CareObject(g_targetId, 1, "ZhenYuanNingLian")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ZhenYuanNingLian_StopCareObject()
	this:CareObject(g_targetId, 0, "ZhenYuanNingLian")
end

function ZhenYuanNingLian_JuYuanShow()
	--VIP 显示
	local nLevel = DataPool:GetAccVipLevel()
	if nLevel < 1 or nLevel > g_Max_Vip_Level  then
		ZhenYuanNingLian_JuYuan_Button:Hide()
		ZhenYuanNingLian_JuYuanDisabled_Button:Hide()
		--隐藏聚元确认按钮和文本
		ZhenYuanNingLian_JvYuanQueRen:Hide()
		ZhenYuanNingLian_JvYuanQueRen_Text:Hide()
		return
	end
	local func1,func2=DataPool:GetvipInfoByVipID(nLevel, 14)
	if func2==nil or func2<= 0 then
		ZhenYuanNingLian_JuYuan_Button:Hide()
		ZhenYuanNingLian_JuYuanDisabled_Button:Hide()
		--隐藏聚元确认按钮和文本
		ZhenYuanNingLian_JvYuanQueRen:Hide()
		ZhenYuanNingLian_JvYuanQueRen_Text:Hide()
		return
	end

	ZhenYuanNingLian_JvYuanQueRen:Show()
	ZhenYuanNingLian_JvYuanQueRen_Text:Show()
	--境界判断
	nLevelFlag[4]=Pneuma:GetMF(g_MissionFlag[4])
	nLevelFlag[5]=Pneuma:GetMF(g_MissionFlag[5])
	nALevelFlag[1]=Pneuma:GetMF(g_MissionFlag_A[1])
	nALevelFlag[2]=Pneuma:GetMF(g_MissionFlag_A[2])
	if nALevelFlag[2]==1 or nLevelFlag[5]==1 then
		ZhenYuanNingLian_JuYuan_Button:Hide()
		ZhenYuanNingLian_JuYuanDisabled_Button:Show()
		ZhenYuanNingLian_JuYuanDisabled_Button : SetToolTip("#{ZYXT_120528_220}")
		return
	end
	if nALevelFlag[1]==1 or nLevelFlag[4]==1 then
		ZhenYuanNingLian_JuYuan_Button:Hide()
		ZhenYuanNingLian_JuYuanDisabled_Button:Show()
		ZhenYuanNingLian_JuYuanDisabled_Button : SetToolTip("#{ZYXT_120528_219}")
		return
	end
	--是否符合显示条件
	for i = 1, 20 do--功能的最大数目
		local funcId, funcType, funcMaxUseTimes, funcUsedTimes = DataPool:GetVipInfoByIdx(i-1)--14-1
		if funcId and funcId == 14 then   --额外直接激活高级凝炼
--			PushDebugMessage("funcUsedTimes="..funcUsedTimes.." funcMaxUseTimes="..funcMaxUseTimes)
			if (funcMaxUseTimes-funcUsedTimes)<=0 then
				ZhenYuanNingLian_JuYuan_Button:Hide()
				ZhenYuanNingLian_JuYuanDisabled_Button:Show()
				ZhenYuanNingLian_JuYuanDisabled_Button : SetToolTip("#{ZYXT_120528_225}")
				return
			end
		end
	end
	--元宝
	local nYuanBao=Player:GetData("YUANBAO")
	if nYuanBao<480 then
		ZhenYuanNingLian_JuYuan_Button:Hide()
		ZhenYuanNingLian_JuYuanDisabled_Button:Show()
		ZhenYuanNingLian_JuYuanDisabled_Button : SetToolTip("#{ZYXT_120528_221}")
		return
	end
	--通过检测
	ZhenYuanNingLian_JuYuanDisabled_Button:Hide()
	ZhenYuanNingLian_JuYuan_Button:Show()
	ZhenYuanNingLian_JuYuan_Button : SetToolTip("#{ZYXT_120528_138}")

end

function ZhenYuanNingLian_OnShow()
	--真元熔炼背包显示
	for i=1, Pneuma_Size do
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", i+Pneuma_SmeltBag-1);--72打头
		if theAction:GetID() ~= 0 then
			ActionButtonName[i]:SetActionItem(theAction:GetID());
		else
			ActionButtonName[i]:SetActionItem(-1);
		end
	end
	if g_bOpened==0 then
		g_bOpened=1;
		ZhenYuanNingLian_LianHuaQueRen:SetCheck(1);
		ZhenYuanNingLian_JvYuanQueRen:SetCheck(1);
	end
	ZhenYuanNingLian_ShowNingLianBtn()
	local exp=Pneuma:GetPneumaExp()
	ZhenYuanNingLian_ZhenYuanYuanJing_Text2:SetText(exp)
	--拥有真元碎片
	local chip=Pneuma:GetPneumaChip()
	ZhenYuanNingLian_ZhenYuanSuiPian_Text2:SetText(chip)
	g_CurSelect=-1
end

function ZhenYuanNingLian_ChioceShow()
	ZhenYuanNingLian_NinglianALLChoice:ResetList()
	ZhenYuanNingLian_NinglianALLChoice:AddTextItem("#{ZYXT_120528_206}" ,0)--不自动淬解
	ZhenYuanNingLian_NinglianALLChoice:AddTextItem("#{ZYXT_120528_207}" ,1)--绿色品质以下
	ZhenYuanNingLian_NinglianALLChoice:AddTextItem("#{ZYXT_120528_208}" ,2)--蓝色品质以下
	ZhenYuanNingLian_NinglianALLChoice:AddTextItem("#{ZYXT_120528_209}" ,3)--紫色品质以下
--	ZhenYuanNingLian_NinglianALLChoice:AddTextItem("#{ZYXT_120528_210}",4)--橙色品质以下
	ZhenYuanNingLian_NinglianALLChoice:SetCurrentSelect(0);
	ZhenYuanNingLian_NinglianALLChoice:Enable()
end

function ZhenYuanNingLian_ShowNingLianBtn()
--	NingLianBtnName[1]:SetProperty("Image","set:UIIcons image:Icon_Lock")
	--凝练按钮的可点击设置
	for i=2,5 do
		nLevelFlag[i]=Pneuma:GetMF(g_MissionFlag[i])
	end
	nALevelFlag[1]=Pneuma:GetMF(g_MissionFlag_A[1])
	nALevelFlag[2]=Pneuma:GetMF(g_MissionFlag_A[2])
--	PushDebugMessage("nLevelFlag:"..nLevelFlag[2].." "..nLevelFlag[3].." "..nLevelFlag[4].." "..nLevelFlag[5].." ac="..nALevelFlag[1].." "..nALevelFlag[2])
	--show
	if nALevelFlag[2]==1 or nLevelFlag[5]==1 then
		for i=2,5 do
			NingLianBtnName[i]:Show()
		end
	elseif nALevelFlag[1]==1 or nLevelFlag[4]==1 then
		for i=2,4 do
			NingLianBtnName[i]:Show()
		end
		NingLianBtnName[5]:Hide()
	elseif nLevelFlag[3]==1 then
		NingLianBtnName[2]:Show()
		NingLianBtnName[3]:Show()
		NingLianBtnName[4]:Hide()
		NingLianBtnName[5]:Hide()
	elseif nLevelFlag[2]==1 then
		NingLianBtnName[2]:Show()
		for i=3,5 do
			NingLianBtnName[i]:Hide()
		end
	else
		for i=2,5 do
			NingLianBtnName[i]:Hide()
		end
	end
end
--取消或者关闭界面
function ZhenYuanNingLian_Exit_Click()
	if "ZhenYuanNingLian" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
	if g_InAllNingLian==1 then
		ZhenYuanNingLian_AllNingLian_StrongEnd(1)
	end
	ZhenYuanNingLian_StopCareObject()
	g_CurSelect=-1
	this:Hide()
end

--点击凝炼背包中的ActionButton
function ZYNL_ActionButton_Clicked(index)
	if index~=g_CurSelect and g_CurSelect>0 then
		ActionButtonName[g_CurSelect]:SetPushed(0);
	end
	g_CurSelect = index;
	ActionButtonName[index]:SetPushed(1);
	ActionButtonName[g_CurSelect]:DoAction()
end

--淬解按钮
function ZYNL_CuiJie_Click()
	local bHaveMission = Pneuma:IsMissionAcc(ZhenYuan_NewerMission_HanRuHai)
	local bHaveDone = Pneuma:IsHaveMissionComplete(ZhenYuan_NewerMission_HanRuHai)
	if bHaveMission <= 0 and bHaveDone <= 0 then
		PushDebugMessage( "#{ZYRW_120522_20}" )
		ZhenYuanNingLian_Exit_Click()
		return
	end
	if ZhenYuanNingLian_CheckCanClick()==0 then
		return
	end
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	if g_CurSelect==-1 then
		PushDebugMessage("#{ZYXT_120528_90}")
		return
	end
	--如果没有真元
	local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", g_CurSelect-1+Pneuma_SmeltBag)
	if(theAction:GetID() == 0 ) then
		PushDebugMessage("#{ZYXT_120528_90}")
		return
	end
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then
		return
	end
	if "ZhenYuanNingLian" == GetFreshManGuideOwner() and g_bShowTips == 2 then
        CloseFreshManGuide()
    end
	--淬解确认
	if ZhenYuanNingLian_LianHuaQueRen:GetCheck()==1 then
		--messagebox
		PushEvent( "PNEUMA_CUIJIE_CONFIRM", g_CurSelect+Pneuma_SmeltBag-1)
		return
	end
	--获取该真元经验值
	local nGetExp=Pneuma:GetPneumaProperty(g_CurSelect+Pneuma_SmeltBag-1,7)
	local nPlayerOwnExp=Pneuma:GetPneumaExp()
	local nMaxExp=Pneuma:GetPneumaExpMax()

	if nPlayerOwnExp>(nMaxExp-nGetExp) then
		PushDebugMessage("#{ZYXT_120528_91}")
--		PushEvent( "PNEUMA_CUIJIE_CONFIRM_MAX", g_CurSelect+Pneuma_SmeltBag-1)
		return
	end
	Pneuma:SmeltPneumaItem(g_CurSelect+Pneuma_SmeltBag-1)
	--有翰如海任务则打开真元盘
	local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_NewerMission_HanRuHai)
	local paramIfCompelete  = 0
	local paramIfCompelete1 = 0
	if missionIndex >= 0 and missionIndex < 20 then
		paramIfCompelete1 = DataPool:GetPlayerMission_Variable(missionIndex, 2)
		paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
	end
	if paramIfCompelete == 0 and Pneuma:IsMissionAcc(ZhenYuan_NewerMission_HanRuHai) > 0 and paramIfCompelete1 == 1 then
		PushEvent( "TOGGLE_PNEUMA_UI", 0)
	end
end

--一键淬解按钮
function ZYNL_CuiJie_All_Click()
	local bHaveMission = Pneuma:IsMissionAcc(ZhenYuan_NewerMission_HanRuHai)
	local bHaveDone = Pneuma:IsHaveMissionComplete(ZhenYuan_NewerMission_HanRuHai)
	if bHaveMission <= 0 and bHaveDone <= 0 then
		PushDebugMessage( "#{ZYRW_120522_20}" )
		ZhenYuanNingLian_Exit_Click()
		return
	end
	if ZhenYuanNingLian_CheckCanClick()==0 then
		return
	end
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then
		return
	end

	--一键淬解确认
	if ZhenYuanNingLian_LianHuaQueRen:GetCheck()==1 then
		--messagebox
		PushEvent( "PNEUMA_CUIJIEALL_CONFIRM")
	else
		if Pneuma:IsSmeltAll_OverMaxExp()==1 then--超过上限啦
			PushDebugMessage("#{ZYXT_120528_91}")
--			PushEvent( "PNEUMA_CUIJIEALL_CONFIRM_MAX")
		else
			Pneuma:SmeltAllPneumaItem()
		end
	end
end
--******************************************
--凝炼部分
--******************************************
--凝练按钮:初级凝炼、低级凝炼、中级凝炼、高级凝炼、终极凝炼
function ZYNL_NingLian_Click()
	--任务必须接受或者完成，待添加
	--是否有引导任务或者完成引导任务
	local bHaveMission = Pneuma:IsMissionAcc(ZhenYuan_Mission_ZhuShenBing)
	local bHaveDone = Pneuma:IsHaveMissionComplete(ZhenYuan_Mission_ZhuShenBing)
	if bHaveMission <= 0 and bHaveDone <= 0 then
		PushDebugMessage( "#{ZYRW_120522_20}" )
		return
	end

	if ZhenYuanNingLian_CheckCanClick()==0 then
		return
	end
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	--真元碎片
	local chip=Pneuma:GetPneumaChip()
	if chip<g_PneumaChip_Needed then
		PushDebugMessage("#{ZYXT_120528_56} ")
		return
	end
	--熔炼背包空间
	if Pneuma:GetSmeltBag_SpaceCount() <1 then
		PushDebugMessage("#{ZYXT_120528_57}")
		return
	end

	--按钮点击，更换tips引导
	if g_TipsNum_ZhuShenBing == 1 and g_bShowTips == 1 then--nClk == 1 and
		NewPlayerNotiece_ZhuShenBing()
	end
	--翰如海 begin
	--按钮点击，更换tips引导
	--if g_TipsNum_HanRuHai == 1 and g_bShowTips == 2 then-- nClk == 1 and
	--	local fX, fY = this:GetChildOffset("ZhenYuanNingLian_Level2_Button")
	--	fX = fX + ZhenYuanNingLian_Level2_Button:GetProperty("AbsoluteWidth") / 2
	--	fY = fY + 23
	--	OpenFreshManGuide(1, 30, fX, fY, "ZhenYuanNingLian", "northwest")
	--	g_TipsNum_HanRuHai = 2
	--end

	local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_NewerMission_HanRuHai)
	local paramIfCompelete  = 0
	if missionIndex >= 0 and missionIndex < 20 then
		paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
	end

	--local clickOnce = DataPool:GetPlayerMission_Variable(missionIndex, 2)
	--点击低级凝练，更换tips
	if paramIfCompelete ~= 1  and g_bShowTips == 2 then--and nClk == 2
		local fX, fY = this:GetChildOffset("ZhenYuanNingLian_Item1")
		fX = fX + ZhenYuanNingLian_Item1:GetProperty("AbsoluteWidth") / 2
		fY = fY + 20
		OpenFreshManGuide(1, 31, fX, fY, "ZhenYuanNingLian", "northwest")
	end
	--翰如海 end
	--申请ING
	Clear_XSCRIPT();
	Set_XSCRIPT_Function_Name("ApplyNiangLian");
	Set_XSCRIPT_ScriptID(889902);
	Set_XSCRIPT_Parameter(0, g_targetId);
	Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

--激活按钮
function ZYNL_ActivationBtn_Click()
	if ZhenYuanNingLian_CheckCanClick()==0 then
		return
	end
	local nYuanBao=Player:GetData("YUANBAO")
	if nYuanBao<480 then
		PushDebugMessage("#{ZYXT_120528_67}")
		return
	end
	if ZhenYuanNingLian_JvYuanQueRen:GetCheck()==1 then
		--messagebox
		PushEvent( "PNEUMA_JUYUAN_CONFIRM")
		return
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ActivationBtnClk");
		Set_XSCRIPT_ScriptID(889902);
--		Set_XSCRIPT_Parameter(0,tonumber(nClk));
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

--一键凝练按钮点击
function ZYNL_AllNingLian_Click()
	if g_InQuickNingLian==1 then
		PushDebugMessage("#{YJNY_170602_01}")
		return 0
	end
	if g_InAllNingLian==0 then
		-- 检测安全时间
		if tonumber(DataPool:GetLeftProtectTime()) > 0 then
			PushDebugMessage("#{ZYXT_120528_16}")
			return
		end
		-- 二级密码 电话密保检查
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then
			return
		end
		--熔炼背包空间
		if Pneuma:GetSmeltBag_SpaceCount() <1 then
			PushDebugMessage("#{ZYXT_120528_68}")
			return
		end
		--真元碎片
		local chip=Pneuma:GetPneumaChip()
		if chip<g_PneumaChip_Needed then
			PushDebugMessage("#{ZYXT_120528_69} ")
			return
		end

		--按钮点击，更换tips引导
		if g_TipsNum_ZhuShenBing == 1 and g_bShowTips == 1 then--nClk == 1 and
			NewPlayerNotiece_ZhuShenBing()
		end
		--翰如海 begin
		--按钮点击，更换tips引导
		--if g_TipsNum_HanRuHai == 1 and g_bShowTips == 2 then-- nClk == 1 and
		--	local fX, fY = this:GetChildOffset("ZhenYuanNingLian_Level2_Button")
		--	fX = fX + ZhenYuanNingLian_Level2_Button:GetProperty("AbsoluteWidth") / 2
		--	fY = fY + 23
		--	OpenFreshManGuide(1, 30, fX, fY, "ZhenYuanNingLian", "northwest")
		--	g_TipsNum_HanRuHai = 2
		--end

		local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_NewerMission_HanRuHai)
		local paramIfCompelete  = 0
		if missionIndex >= 0 and missionIndex < 20 then
			paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
		end

		--local clickOnce = DataPool:GetPlayerMission_Variable(missionIndex, 2)
		--点击低级凝练，更换tips
		if paramIfCompelete ~= 1  and g_bShowTips == 2 then--and nClk == 2
			local fX, fY = this:GetChildOffset("ZhenYuanNingLian_Item1")
			fX = fX + ZhenYuanNingLian_Item1:GetProperty("AbsoluteWidth") / 2
			fY = fY + 20
			OpenFreshManGuide(1, 31, fX, fY, "ZhenYuanNingLian", "northwest")
		end
		--翰如海 end

		--开始一键凝练
		local sAutoCuiJie, iAutoCuiJie =  ZhenYuanNingLian_NinglianALLChoice:GetCurrentSelect();
		if iAutoCuiJie>=1 and iAutoCuiJie<=3 then--iAutoCuiJie<=4
			local bHaveMission = Pneuma:IsMissionAcc(ZhenYuan_NewerMission_HanRuHai)
			local bHaveDone = Pneuma:IsHaveMissionComplete(ZhenYuan_NewerMission_HanRuHai)
			if bHaveMission <= 0 and bHaveDone <= 0 then
				PushDebugMessage( "#{ZYRW_120522_20}" )
				return
			end
			PushEvent( "NINGLAINALL_CUIJIECONFIRM", iAutoCuiJie)
			return
		elseif iAutoCuiJie==0 then
			--continue
		end
		local bHaveMission = Pneuma:IsMissionAcc(ZhenYuan_Mission_ZhuShenBing)
		local bHaveDone = Pneuma:IsHaveMissionComplete(ZhenYuan_Mission_ZhuShenBing)
		if bHaveMission <= 0 and bHaveDone <= 0 then
			PushDebugMessage( "#{ZYRW_120522_20}" )
			return
		end
		ZhenYuanNingLian_AllNingLian_Start()
	elseif g_InAllNingLian==1 then
		--停止一键凝练
		ZhenYuanNingLian_AllNingLian_StrongEnd(1)
	end
end

--***************************************
--正常的一键凝练
--***************************************
function ZhenYuanNingLian_AllNingLian_Start()
	ZhenYuanNingLian_NinglianALLChoice:Disable()
	g_InAllNingLian=1
	ZhenYuanNingLian_NingLianAll_Button:SetText("#{ZYXT_120528_74}")--终止一键凝炼
	ZhenYuanNingLian_StartTimerProc()
	SetTimer("ZhenYuanNingLian","ZhenYuanNingLian_StartTimerProc()", 50)
end

function ZhenYuanNingLian_AllNingLian_StrongEnd(bMsg)
	ZhenYuanNingLian_NinglianALLChoice:Enable()
	g_InAllNingLian=0
	KillTimer("ZhenYuanNingLian_StartTimerProc()")
	KillTimer("ZhenYuanNingLian_SP_StartTimerProc()")
	ZhenYuanNingLian_NingLianAll_Button:SetText("#{ZYXT_120528_73}")
	if bMsg==1 then
		PushDebugMessage("#{ZYXT_120528_130} ")
	end
end

--一键凝练计时器
function ZhenYuanNingLian_StartTimerProc()
	--界面是否关闭
	if this:IsVisible()==false then
		ZhenYuanNingLian_AllNingLian_StrongEnd(1)
		return
	end
	local nChip  =Pneuma:GetPneumaChip()
	if nChip<g_PneumaChip_Needed then
		PushDebugMessage("#{ZYXT_120528_128} ")
		ZhenYuanNingLian_AllNingLian_StrongEnd(0)
		return
	end
	--空间检测
	local nSpace=Pneuma:GetSmeltBag_SpaceCount()
	if nSpace <1 then
		PushDebugMessage("#{ZYXT_120528_129}")
		ZhenYuanNingLian_AllNingLian_StrongEnd(0)
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ApplyNiangLian");
		Set_XSCRIPT_ScriptID(889902);
		Set_XSCRIPT_Parameter(0, g_targetId);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

--***************************************
--特殊的一键凝练(含特殊的淬解)
--***************************************
function ZhenYuanNingLian_SPAllNingLian_Start()
	ZhenYuanNingLian_NinglianALLChoice:Disable()
	g_InAllNingLian=1
	ZhenYuanNingLian_NingLianAll_Button:SetText("#{ZYXT_120528_74}")--终止一键凝炼
	ZhenYuanNingLian_SP_StartTimerProc()
	SetTimer("ZhenYuanNingLian","ZhenYuanNingLian_SP_StartTimerProc()", 50)
end

function ZhenYuanNingLian_SP_StartTimerProc()
--PushDebugMessage("SP_StartTimerProc")
	--界面是否关闭
	if this:IsVisible()==false then
		ZhenYuanNingLian_AllNingLian_StrongEnd(1)
		return
	end
	local sAutoCuiJie, iAutoCuiJie =  ZhenYuanNingLian_NinglianALLChoice:GetCurrentSelect();
	if iAutoCuiJie<1 or iAutoCuiJie>3 then--iAutoCuiJie>4
		ZhenYuanNingLian_AllNingLian_StrongEnd(0)
		return
	end
	local nChip =Pneuma:GetPneumaChip()
	if nChip<g_PneumaChip_Needed then
		Pneuma:SmeltAllItem_WithCuijie(iAutoCuiJie)
		--PushDebugMessage("SmeltAllItem_WithCuijie")
		KillTimer("ZhenYuanNingLian_SP_StartTimerProc()")--不自动特殊凝练，但依旧在特殊淬解中
		return
	end
	--空间检测
	local nSpace=Pneuma:GetSmeltBag_SpaceCount()
	if nSpace <1 then
		Pneuma:SmeltAllItem_WithCuijie(iAutoCuiJie)
		--PushDebugMessage("SmeltAllItem_WithCuijie")
		KillTimer("ZhenYuanNingLian_SP_StartTimerProc()")--不自动特殊凝练，但依旧在特殊淬解中
		return
	end
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ApplyNiangLian");
		Set_XSCRIPT_ScriptID(889902);
		Set_XSCRIPT_Parameter(0, g_targetId);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

function ZhenYuanNingLian_CheckCanClick()
	if g_InAllNingLian==1 then
		PushDebugMessage("#{ZYXT_120528_147}")
		return 0
	end
	if g_InQuickNingLian==1 then
		PushDebugMessage("#{YJNY_170602_01}")
		return 0
	end
	return 1
end

function ZYNL_PickUpToBag_Click()
	if ZhenYuanNingLian_CheckCanClick()==0 then
		return
	end
	if g_CurSelect==-1 then
		PushDebugMessage("#{ZYXT_120528_131} ")
		return
	end
	--如果没有真元
	local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", g_CurSelect-1+Pneuma_SmeltBag)
	if(theAction:GetID() == 0 ) then
		PushDebugMessage("#{ZYXT_120528_131}")
		return
	end
	if ("ZhenYuanNingLian" == GetFreshManGuideOwner()) and (g_TipsNum_ZhuShenBing == 2) then
		CloseFreshManGuide()
	end
--	PushDebugMessage("ZYNL_PickUpToBag_Click")
	Pneuma:PickPneumaUpToBag(g_CurSelect-1)
	--有翰如海任务则打开真元盘
	local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_NewerMission_HanRuHai)
	local paramIfCompelete  = 0
	local paramIfCompelete1 = 0
	if missionIndex >= 0 and missionIndex < 20 then
		paramIfCompelete1 = DataPool:GetPlayerMission_Variable(missionIndex, 2)
		paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
	end
	if paramIfCompelete == 0 and Pneuma:IsMissionAcc(ZhenYuan_NewerMission_HanRuHai) > 0 and paramIfCompelete1 == 1 then
		PushEvent( "TOGGLE_PNEUMA_UI", 0)
	end
end

function ZYNL_PickUpToBag(nClk)
	if ZhenYuanNingLian_CheckCanClick()==0 then
		return
    end
    --如果没有真元
	local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", nClk-1+Pneuma_SmeltBag)
	if(theAction:GetID() == 0 ) then
		return
	end
	if nClk>=1 and nClk<=24 then
		Pneuma:PickPneumaUpToBag(nClk-1)
	end
	--有翰如海任务则打开真元盘
	local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_NewerMission_HanRuHai)
	local paramIfCompelete  = 0
	local paramIfCompelete1 = 0
	if missionIndex >= 0 and missionIndex < 20 then
		paramIfCompelete1 = DataPool:GetPlayerMission_Variable(missionIndex, 2)
		paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
	end
	if paramIfCompelete == 0 and Pneuma:IsMissionAcc(ZhenYuan_NewerMission_HanRuHai) > 0 and paramIfCompelete1 == 1 then
		PushEvent( "TOGGLE_PNEUMA_UI", 0)
	end
end
--铸神兵任务timer
function NewPlayerNotiece_ZhuShenBing()
	if g_TipsNum_ZhuShenBing ~= 1 and g_bShowTips == 1 then
		return
	end
	if(not this:IsVisible() ) then
		return
	end
	local fX, fY = this:GetChildOffset("ZhenYuanNingLian_Item1")
	fX = fX + ZhenYuanNingLian_Item1:GetProperty("AbsoluteWidth") / 2
	fY = fY + 20
	OpenFreshManGuide(1, 25, fX, fY, "ZhenYuanNingLian", "northwest")
	g_TipsNum_ZhuShenBing = 2
end
function ZhenYuanNingLian_OnMoved()
    if "ZhenYuanNingLian" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
end
function ZhenYuanNingLian_OnHidden()
	if "ZhenYuanNingLian" == GetFreshManGuideOwner() then
        CloseFreshManGuide()
    end
end
function ZYNL_OpenZYP_Click()
	OpenWindow("ZhenYuan")
end
function ZhenYuanNingLian_KJL_ConfigClk()
	OpenOneParamWindow("ZhenYuanNingLian_KJNLConfig",g_targetId)
end
--bFlag为0表示玩家点击一键凝元按钮，bFlag为1表示玩家点击确认框的确认按钮
function ZhenYuanNingLian_QuickNingYuan(bFlag)
	if g_InAllNingLian==1 then
		PushDebugMessage("#{YJNY_170612_16}")
		return
	end
	if g_InQuickNingLian==1 then
		PushDebugMessage("#{YJNY_170602_04}")
		return
	end
	local bHaveMission = Pneuma:IsMissionAcc(ZhenYuan_NewerMission_HanRuHai)
	local bHaveDone = Pneuma:IsHaveMissionComplete(ZhenYuan_NewerMission_HanRuHai)
	if bHaveMission <= 0 and bHaveDone <= 0 then
		PushDebugMessage( "#{ZYRW_120522_20}" )
		return
	end
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end

	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	--熔炼背包空间
	local SpaceCnt=Pneuma:GetSmeltBag_SpaceCount()
	if SpaceCnt <24 then
		PushDebugMessage("#{YJNY_170602_05}")
		return
	end
	--真元碎片
	local chip=Pneuma:GetPneumaChip()
	if chip<g_QuikNiangLian_JC[g_QuikNiangLian_Sel]*20 then
		local tipText = ScriptGlobal_Format( "#{YJNY_170602_06}", g_QuikNiangLian_JC[g_QuikNiangLian_Sel]*20 )
		PushDebugMessage(tipText)
		return
	end
	local maxExp = Pneuma:GetPneumaExpMax()
	if Pneuma:GetPneumaExp()>maxExp-100000 then
		PushDebugMessage("#{YJNY_170602_07} ")
		return
	end
	if bFlag==0 then
		PushEvent("PNEUMA_QUICKONCENY_QR",0,g_QuikNiangLian_JC[g_QuikNiangLian_Sel])
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("QuickOnceNingYuanClk");
		Set_XSCRIPT_ScriptID(889902);
		Set_XSCRIPT_Parameter(0, g_QuikNiangLian_Sel);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	g_InQuickNingLian=1
end
