--*********************
--真元主界面
--*********************
local ZhenYuan_GFPage=0--0是攻击，1是防御

local ZhenYuan_EquipActionBtn={}
local ZhenYuan_EquipPneumaActionBtn={}
local ZhenYuan_EquipPneumaActionBtn_Name={}
local ZhenYuan_BagPneumaActionBtn={}
local ZhenYuan_InfoText = {}
local ZhenYuan_UpgradeButton={}
local ZhenYuan_UpgradeButton_Name={}

local ZhenYuan_UpgradeTipsBtn={}
local ZhenYuan_EquipImage={}
local ZhenYuan_FengBtn={}

local ZhenYuan_EquipPos=0
local ZhenYuan_Bag=36
local ZhenYuan_SmeltBag=72
local ZhenYuan_Size=24

local ZhenYuanPageSize = 6
local ZhenYuan_TabIndex=0

local ZhenYuan_UXP;
local ZhenYuan_UYP;
local ZhenYuan_MF={589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602}
local ZhenYuan_LevelUp_ActMission_JieZhenYuan = 1604
local ZhenYuan_LevelUp_ActMission_HanRuHai = 1603
local ZhenYuan_LevelUp_ActMission_MiZhenZhi = 1602
local ZhenYuan_SelectItem=0

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_ZhenYuan_Page = {
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

local g_ZhenYuan_PageButton = {}
local g_ZhenYuan_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function ZhenYuan_PreLoad()
	this:RegisterEvent("PNEUMAITEM_CHANGED");
	this:RegisterEvent("PNEUMALIST_CHANGED");
	this:RegisterEvent("TOGGLE_PNEUMA_UI");
	this:RegisterEvent("REFRESH_EQUIP");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PNEUMA_EXPCHIP_CHANGED")

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("PNEUMA_MISSIONFLAG");
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级
	this:RegisterEvent("TOGGLE_UPDATE_INFANT"); --子女有变化 刷新按钮状态
	this:RegisterEvent("FINISH_MISSION");
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end


function ZhenYuan_OnLoad()
	--和槽位对应
	ZhenYuan_EquipActionBtn={
	ZhenYuan_Equip1, ZhenYuan_Equip2, ZhenYuan_Equip3,
	ZhenYuan_Equip4, ZhenYuan_Equip5, ZhenYuan_Equip6,
	}
	ZhenYuan_EquipPneumaActionBtn={
	ZhenYuan_Slots1, ZhenYuan_Slots2, ZhenYuan_Slots3,
	ZhenYuan_Slots4, ZhenYuan_Slots5, ZhenYuan_Slots6
	}
	ZhenYuan_EquipPneumaActionBtn_Name={
	"ZhenYuan_Slots1", "ZhenYuan_Slots2", "ZhenYuan_Slots3",
	"ZhenYuan_Slots4", "ZhenYuan_Slots5", "ZhenYuan_Slots6"
	}
	ZhenYuan_BagPneumaActionBtn={
	ZhenYuan_Item1,ZhenYuan_Item2,ZhenYuan_Item3,ZhenYuan_Item4,ZhenYuan_Item5,ZhenYuan_Item6,ZhenYuan_Item7,ZhenYuan_Item8,
	ZhenYuan_Item9,ZhenYuan_Item10,ZhenYuan_Item11,ZhenYuan_Item12,ZhenYuan_Item13,ZhenYuan_Item14,ZhenYuan_Item15,ZhenYuan_Item16,
	ZhenYuan_Item17,ZhenYuan_Item18,ZhenYuan_Item19,ZhenYuan_Item20,ZhenYuan_Item21,ZhenYuan_Item22,ZhenYuan_Item23,ZhenYuan_Item24,
	}
	ZhenYuan_InfoText={
	ZhenYuan_Info1,ZhenYuan_Info2,ZhenYuan_Info3,ZhenYuan_Info4,ZhenYuan_Info5,ZhenYuan_Info6,
	}
	ZhenYuan_UpgradeButton = {
	ZhenYuan_Button1,ZhenYuan_Button2,ZhenYuan_Button3,ZhenYuan_Button4,ZhenYuan_Button5,ZhenYuan_Button6,}
	ZhenYuan_UpgradeButton_Name = {
	"ZhenYuan_Button1", "ZhenYuan_Button2", "ZhenYuan_Button3", "ZhenYuan_Button4", "ZhenYuan_Button5", "ZhenYuan_Button6",}

	ZhenYuan_UpgradeTipsBtn = {
	ZhenYuan_Tips1,ZhenYuan_Tips2,ZhenYuan_Tips3,ZhenYuan_Tips4,ZhenYuan_Tips5,ZhenYuan_Tips6,}

	ZhenYuan_UXP	= ZhenYuan_Frame : GetProperty("UnifiedXPosition");
	ZhenYuan_UYP	= ZhenYuan_Frame : GetProperty("UnifiedYPosition");
	ZhenYuan_FengBtn={
	ZhenYuan_Feng1,ZhenYuan_Feng2,ZhenYuan_Feng3,ZhenYuan_Feng4,ZhenYuan_Feng5,ZhenYuan_Feng6,
	}
	--设置客户端界面使用的图片资源，根据是否为唯美版选择不同的图片资源集
	--"衣服","腰带","护手","鞋","帽子","护肩","项链","戒指","戒指","护腕","护符","护符"
	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图标资源为唯美版对应的资源
		ZhenYuan_EquipImage={
		"set:WM_Button2 image:Equip_Necklace",
		"set:WM_Button2 image:Equip_Ring",
		"set:WM_Button2 image:Equip_Ring",
		"set:WM_Button2 image:Equip_Wrist",
		"set:WM_Button2 image:Equip_Cloak",
		"set:WM_Button2 image:Equip_Cloak",
		"set:WM_Button2 image:Equip_Cloth",
		"set:WM_Button2 image:Equip_Sash",
		"set:WM_Button2 image:Equip_Hand",
		"set:WM_Button2 image:Equip_Shoe",
		"set:WM_Button2 image:Equip_Cap",
		"set:WM_Button2 image:Equip_Shoulder",
		}
	else
		ZhenYuan_EquipImage={
		"set:UIIcons image:Equip_Nacket",
		"set:UIIcons image:Equip_Ring",
		"set:UIIcons image:Equip_Ring",
		"set:UIIcons image:Equip_Wrist",
		"set:UIIcons image:Equip_Pifeng",
		"set:UIIcons image:Equip_Pifeng",
		"set:UIIcons image:Equip_Armo",
		"set:UIIcons image:Equip_Sash",
		"set:UIIcons image:Equip_Hand",
		"set:UIIcons image:Equip_Shot",
		"set:UIIcons image:Equip_Cap",
		"set:UIIcons image:Equip_Shoulder",
		}
	end
	
	g_ZhenYuan_PageButton[1] = ZhenYuan_SelfEquip
	g_ZhenYuan_PageButton[2] = ZhenYuan_SelfData
	g_ZhenYuan_PageButton[3] = ZhenYuan_Pet
	g_ZhenYuan_PageButton[4] = ZhenYuan_Infant
	g_ZhenYuan_PageButton[5] = ZhenYuan_Wuhun
	g_ZhenYuan_PageButton[6] = ZhenYuan_Xiulian
	g_ZhenYuan_PageButton[7] = ZhenYuan_Miji
	g_ZhenYuan_PageButton[8] = ZhenYuan_ZhenYuan
	g_ZhenYuan_PageButton[9] = ZhenYuan_JingMai
	g_ZhenYuan_PageButton[10] = ZhenYuan_ShenDing
	g_ZhenYuan_PageButton[11] = ZhenYuan_JueWei
	g_ZhenYuan_PageButton[12] = ZhenYuan_BaoJian
	g_ZhenYuan_PageButton[13] = ZhenYuan_WuYi
	g_ZhenYuan_PageButton[14] = ZhenYuan_ShenQi
	g_ZhenYuan_PageButton[15] = ZhenYuan_Armor
	g_ZhenYuan_PageButton[16] = ZhenYuan_CangPin
	g_ZhenYuan_PageButton[17] = ZhenYuan_OtherInfo
	
	g_ZhenYuan_PageMask[1] = ZhenYuan_SelfEquip_tips
	g_ZhenYuan_PageMask[2] = ZhenYuan_SelfData_tips
	g_ZhenYuan_PageMask[3] = ZhenYuan_Pet_tips
	g_ZhenYuan_PageMask[4] = ZhenYuan_Infant_tips
	g_ZhenYuan_PageMask[5] = ZhenYuan_Wuhun_tips
	g_ZhenYuan_PageMask[6] = ZhenYuan_Xiulian_tips
	g_ZhenYuan_PageMask[7] = ZhenYuan_Miji_tips
	g_ZhenYuan_PageMask[8] = ZhenYuan_ZhenYuan_tips
	g_ZhenYuan_PageMask[9] = ZhenYuan_JingMai_tips
	g_ZhenYuan_PageMask[10] = ZhenYuan_ShenDing_tips
	g_ZhenYuan_PageMask[11] = ZhenYuan_JueWei_tips
	g_ZhenYuan_PageMask[12] = ZhenYuan_BaoJian_tips
	g_ZhenYuan_PageMask[13] = ZhenYuan_WuYi_tips
	g_ZhenYuan_PageMask[14] = ZhenYuan_ShenQi_tips
	g_ZhenYuan_PageMask[15] = ZhenYuan_Armor_tips
	g_ZhenYuan_PageMask[16] = ZhenYuan_CangPin_tips
	g_ZhenYuan_PageMask[17] = ZhenYuan_OtherInfo_tips
	
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


function ZhenYuan_Close()
	this:Hide()
	ZhenYuan_TabIndex = 0
	ZhenYuan_SelectItem=0
	if "ZhenYuan" == GetFreshManGuideOwner() then
        CloseFreshManGuide()
    end
end


function ZhenYuan_OnEvent( event )

	if ( event == "UPDATE_WILLGET_MISSION_TRACK" )  or (event=="TOGGLE_UPDATE_INFANT") or (event == "FINISH_MISSION")  then
		local nLevel =Player:GetLevel()
		ZhenYuan_Refresh_Page_Button(nLevel)
		ZhenYuan_ShowPage()
	end
	if ( event == "PNEUMAITEM_CHANGED" or event=="PNEUMALIST_CHANGED" or event=="REFRESH_EQUIP" or event=="PNEUMA_EXPCHIP_CHANGED") then
		if(this:IsVisible()) then
			ZhenYuan_OnUpdate()
		end
		if event == "PNEUMAITEM_CHANGED" and arg0~=nil then
			if(arg1~=nil )then
--				PushDebugMessage(arg1)
				return
			end
			--ZhenYuan_BagPneumaActionBtn[tonumber(arg0)]:Disable();
		end
	elseif (event=="TOGGLE_PNEUMA_UI") or (event=="UI_COMMAND" and tonumber(arg0) == 80800799) then
		local selfUnionPos = Variable:GetVariable("SelfUnionPos");
		if(selfUnionPos ~= nil) then
		  ZhenYuan_Frame:SetProperty("UnifiedPosition", selfUnionPos);
		end
		local mizhenyuanTips = tonumber(arg0)
		ZhenYuan_OnShow()
		ZhenYuan_OnUpdate()
		--引导tips 觅真知
		local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_LevelUp_ActMission_MiZhenZhi)
		local paramIfCompelete = 0
		local haveActive = 0
		if missionIndex >= 0 and missionIndex < 20 then
			paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
			haveActive = DataPool:GetPlayerMission_Variable(missionIndex, 2)
		end
		if haveActive ==1 and paramIfCompelete ~= 1 and ( (event == "TOGGLE_PNEUMA_UI" and mizhenyuanTips == 1 ) or (Pneuma:IsMissionAcc(ZhenYuan_LevelUp_ActMission_MiZhenZhi) > 0) ) then
			local startIndex = 0
			local ActionEquip={}
			local firstActSlot = 0
			for i = 1, table.getn(ZhenYuan_MF) do
				if Pneuma:GetMF(ZhenYuan_MF[i]) ~= 0 then
					firstActSlot = i
					break;
				end
			end
			if firstActSlot <= ZhenYuanPageSize then
				ZhenYuan_ChangeTabIndex(0)
			else
				ZhenYuan_ChangeTabIndex(1)
			end

			if(ZhenYuan_TabIndex == 0) then
				startIndex = 0
			elseif (ZhenYuan_TabIndex == 1) then
				startIndex = ZhenYuanPageSize
			end
			for i=1, ZhenYuanPageSize do
				if Pneuma:GetMF(ZhenYuan_MF[i+startIndex]) ~= 0 then
					local fX, fY = this:GetChildOffset(ZhenYuan_EquipPneumaActionBtn_Name[i])
					fX = fX + ZhenYuan_EquipPneumaActionBtn[i]:GetProperty("AbsoluteWidth") / 2
					OpenFreshManGuide(1, 27, fX, fY, "ZhenYuan", "northwest")
					break
				end
			end
		end
		--解真元
		local paramIfCompelete_jiezhenyuan = 0
		local missionIndex_jiezhenyuan = DataPool:GetPlayerMissionIndexByID(ZhenYuan_LevelUp_ActMission_JieZhenYuan)
		if missionIndex_jiezhenyuan >= 0 and missionIndex_jiezhenyuan < 20 then
			paramIfCompelete_jiezhenyuan = DataPool:GetPlayerMission_Variable(missionIndex_jiezhenyuan, 0)
		end
		if Pneuma:IsMissionAcc(ZhenYuan_LevelUp_ActMission_JieZhenYuan) > 0 and paramIfCompelete_jiezhenyuan == 0 then
			local startIndex = 0
			local ActionEquip={}
			local firstActSlot = 0
			for i = 1, table.getn(ZhenYuan_MF) do
				if Pneuma:GetMF(ZhenYuan_MF[i]) ~= 0 then
					firstActSlot = i
					break;
				end
			end
			if firstActSlot <= ZhenYuanPageSize then
				ZhenYuan_ChangeTabIndex(0)
			else
				ZhenYuan_ChangeTabIndex(1)
			end
			if(ZhenYuan_TabIndex == 0) then
				startIndex = 0
			elseif (ZhenYuan_TabIndex == 1) then
				startIndex = ZhenYuanPageSize
			end

			for i=1, ZhenYuanPageSize do
				local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", i+startIndex-1);--36打头
				if theAction:GetID() ~= 0 then
					local fX, fY = this:GetChildOffset(ZhenYuan_UpgradeButton_Name[i])
					fX = fX + ZhenYuan_UpgradeButton[i]:GetProperty("AbsoluteWidth") / 2
					OpenFreshManGuide(1, 33, fX, fY, "ZhenYuan", "northwest")
					break
				end
			end
		end
		--引导tips 翰如海任务
		local missionIndex = DataPool:GetPlayerMissionIndexByID(ZhenYuan_LevelUp_ActMission_HanRuHai)
		local paramIfCompelete = 0
		if missionIndex >= 0 and missionIndex < 20 then
			paramIfCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
		end
		if Pneuma:IsMissionAcc(ZhenYuan_LevelUp_ActMission_HanRuHai) > 0 and paramIfCompelete ~= 1 then
			local fX, fY = this:GetChildOffset("ZhenYuan_LianHua")
			fX = fX + ZhenYuan_LianHua:GetProperty("AbsoluteWidth") / 2
			fY = fY + 6
			OpenFreshManGuide(1, 32, fX, fY, "ZhenYuan", "northwest")
		end
		local nLevel =Player:GetLevel()
		ZhenYuan_Refresh_Page_Button(nLevel)
		ZhenYuan_ShowPage()
	elseif (event == "ADJEST_UI_POS" or "VIEW_RESOLUTION_CHANGED" == event) then
		-- 更新背包界面位置
		ZhenYuan_Frame_On_ResetPos()
	elseif (event=="PNEUMA_MISSIONFLAG" and this:IsVisible()) then
		ZhenYuan_OnUpdate()
	elseif ( event == "OPEN_WINDOW" ) then
		if (arg0 == "ZhenYuan") then
			this:Hide()
			local selfUnionPos = Variable:GetVariable("SelfUnionPos");
			if(selfUnionPos ~= nil) then
			  ZhenYuan_Frame:SetProperty("UnifiedPosition", selfUnionPos);
			end
			ZhenYuan_OnUpdate()
			ZhenYuan_OnShow()
		end
	elseif(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		ZhenYuan_RefreshWuYiTip()
	end

	if event == "UPDATE_TOY_TIP" then
		ZhenYuan_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		ZhenYuan_RefreshCangPinTip()
	end
end

function ZhenYuan_OnUpdate()
	ZhenYuan_OnUpdateBag()
	ZhenYuan_OnUpdateEquip()
end

function ZhenYuan_OnShow()
	ZhenYuan_ZhenYuan:SetCheck(1)
	this:Show()
end

function ZhenYuan_OnUpdateBag()

	--真元背包显示
	local Lock_Flag=0
	for i=1, ZhenYuan_Size do
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", i+ZhenYuan_Bag-1);--36打头
		if theAction:GetID() ~= 0 then
			ZhenYuan_BagPneumaActionBtn[i]:SetActionItem(theAction:GetID());
		else
			ZhenYuan_BagPneumaActionBtn[i]:SetActionItem(-1);
		end
		--是否灰化 只有真元背包中的物品
		if bLocked == 1 then
			ZhenYuan_BagPneumaActionBtn[i]:Disable();
			Lock_Flag = 1
		else
			ZhenYuan_BagPneumaActionBtn[i]:Enable();
		end
	end
	if Lock_Flag == 0 then
		ZhenYuan_Arrange_Button : Enable();
	else
		ZhenYuan_Arrange_Button : Disable();
	end
	ZhenYuan_LianHua:SetProperty("DragAcceptName", "s")
	ZhenYuan_UpdateDragAcceptName()
	ZhenYuan_ZhenYuanSuiPian_Amount:SetText(Pneuma:GetPneumaChip())
	ZhenYuan_YuanJing_Amount:SetText(Pneuma:GetPneumaExp())
	ZhenYuan_SelectItem=0
end

function ZhenYuan_Refuse_Click()
	ZhenYuan_Close()
end

function ZhenYuan_ChangeTabIndex(nTabIndex)
	ZhenYuan_TabIndex = nTabIndex
	ZhenYuan_OnUpdateEquip()
	ZhenYuan_UpdateDragAcceptName()
	--炼化按钮
	ZhenYuan_LianHua:SetProperty("DragAcceptName", "s")
end

function ZhenYuan_OnUpdateEquip()
	local startIndex = 0
	local ActionEquip={}
	if(ZhenYuan_TabIndex == 0) then
		ZhenYuan_FenYe1:SetText("#{ZYXT_120528_166}")--#G乾天
		ZhenYuan_FenYe2:SetText("#{ZYXT_120528_21}")
		startIndex = 0
		--ActionEquip[1]=EnumAction(2, "equip")
		--ActionEquip[2]=EnumAction(5, "equip")
		--ActionEquip[3]=EnumAction(3, "equip")
		--ActionEquip[4]=EnumAction(4, "equip")
		--ActionEquip[5]=EnumAction(1, "equip")
		--ActionEquip[6]=EnumAction(15, "equip")
		ActionEquip[1]=EnumAction(7, "equip")	--项链
		ActionEquip[2]=EnumAction(6, "equip")	--戒指
		ActionEquip[3]=EnumAction(11, "equip")	--第二个戒指
		ActionEquip[4]=EnumAction(14, "equip")	--护腕
		ActionEquip[5]=EnumAction(12, "equip")	--护符
		ActionEquip[6]=EnumAction(13, "equip")	--第二个护符
	elseif (ZhenYuan_TabIndex == 1) then
		ZhenYuan_FenYe1:SetText("#{ZYXT_120528_22}")--乾天
		ZhenYuan_FenYe2:SetText("#{ZYXT_120528_165}")
		startIndex = ZhenYuanPageSize
		--ActionEquip[1]=EnumAction(7, "equip")
		--ActionEquip[2]=EnumAction(6, "equip")
		--ActionEquip[3]=EnumAction(11, "equip")
		--ActionEquip[4]=EnumAction(14, "equip")
		--ActionEquip[5]=EnumAction(12, "equip")
		--ActionEquip[6]=EnumAction(13, "equip")
		ActionEquip[1]=EnumAction(2, "equip")	--衣服
		ActionEquip[2]=EnumAction(5, "equip")	--腰带
		ActionEquip[3]=EnumAction(3, "equip")	--手套
		ActionEquip[4]=EnumAction(4, "equip")	--鞋
		ActionEquip[5]=EnumAction(1, "equip")	--帽子
		ActionEquip[6]=EnumAction(15, "equip")	--护肩
	end

	for i=1, ZhenYuanPageSize do
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", i+startIndex-1);--36打头
		local MF= Pneuma:GetMF(ZhenYuan_MF[i+startIndex])
		if MF==1 then
			ZhenYuan_FengBtn[i]:SetProperty("Visible","False")
			ZhenYuan_EquipPneumaActionBtn[i]:SetProperty("Visible","True")
			if theAction:GetID() ~= 0 then
				ZhenYuan_EquipPneumaActionBtn[i]:SetActionItem(theAction:GetID());
			else
				ZhenYuan_EquipPneumaActionBtn[i]:SetActionItem(-1);
			end
		else
			ZhenYuan_FengBtn[i]:SetProperty("Visible","True")
			ZhenYuan_EquipPneumaActionBtn[i]:SetProperty("Visible","False")
		end
	end



	for j=1, ZhenYuanPageSize do
		ZhenYuan_EquipActionBtn[j]:SetActionItem(ActionEquip[j]:GetID())
		if ActionEquip[j]:GetID()==0 then
			ZhenYuan_EquipActionBtn[j]:SetProperty("BackImage", ZhenYuan_EquipImage[j+startIndex])
		end
	end

	ZhenYuan_SetInfoText()
	ZhenYuan_SetUpgradeButton()
	--女or男
	local iSexy = Player:GetMySex()
	if iSexy==1 then
		ZhenYuan_NV:Hide()
		ZhenYuan_NAN:Show()
	else
		ZhenYuan_NV:Show()
		ZhenYuan_NAN:Hide()
	end

	ZhenYuan_UpdatePneumaSet()
end

function ZhenYuan_UpdateDragAcceptName()
	local startIndex = 0
	if(ZhenYuan_TabIndex == 0) then
		startIndex = 0
	elseif (ZhenYuan_TabIndex == 1) then
		startIndex = ZhenYuanPageSize
	end

	--从36开始，36-71表示背包里的真元
	for i = 1, ZhenYuan_Size do
		ZhenYuan_BagPneumaActionBtn[i]:SetProperty("DragAcceptName", "B"..tostring(ZhenYuan_Bag+i-1))
	end

	for j = 1, ZhenYuanPageSize do
		ZhenYuan_EquipPneumaActionBtn[j]:SetProperty("DragAcceptName", "E"..tostring(j+startIndex-1))
	end
end




function ZhenYuan_Pet_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);

	TogglePetPage();
	ZhenYuan_Close()
end

function ZhenYuan_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);

	OpenEquip(1);
	ZhenYuan_Close()
end

function ZhenYuan_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
	ZhenYuan_Close()
end

function ZhenYuan_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
	ZhenYuan_Close()
end


function ZhenYuan_Xiulian_Switch()
	nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
		ZhenYuan_Close()
	else
	    ZhenYuan_Xiulian : SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

--神木王鼎
function ZhenYuan_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if nRet == 1 then
		ZhenYuan_ZhenYuan:SetCheck(0)
		ZhenYuan_Close()
	else
		ZhenYuan_ShenDing:SetCheck(0)
	end
end

function ZhenYuan_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();
	ZhenYuan_Close()
end

function ZhenYuan_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		ZhenYuan_ZhenYuan:SetCheck(0)
		ZhenYuan_Close()
	else
		ZhenYuan_JingMai:SetCheck(0)
	end

end

function ZhenYuan_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);

	OtherInfoPage();
	ZhenYuan_Close()
end

function ZhenYuan_Frame_On_ResetPos()
	ZhenYuan_Frame : SetProperty("UnifiedXPosition", ZhenYuan_UXP);
	ZhenYuan_Frame : SetProperty("UnifiedYPosition", ZhenYuan_UYP);
end

function ZhenYuan_ShowPneumaToolTips(idx)
	local startIdx = 0
	if( ZhenYuan_TabIndex == 1) then
			startIdx = 6
	end

	local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", idx+startIdx-1)

	if Pneuma:GetMF(ZhenYuan_MF[idx+startIdx])==0 then --未激活
		--当前插槽所对应的盘眼未激活，你可以到NPC处激活盘眼后，即可将真元装载到本插槽上。
		ZhenYuan_EquipPneumaActionBtn[idx]:SetToolTip("#{ZYXT_120528_27}")--未激活--需要字典..idx
	else
		if theAction:GetID() == 0 then --是否装备了真元
			--当前插槽未装载任何真元，你可以将真元背包中的真元装载到本插槽。
			ZhenYuan_EquipPneumaActionBtn[idx]:SetToolTip("#{ZYXT_120528_28}")
		end
	end
end

--function ZhenYuan_ShowEquipToolTips(idx)
--
--	local startIdx = 0
--	local ActionEquip={}
--	if(ZhenYuan_TabIndex == 0) then
--		startIdx = 0
--		ActionEquip[1]=EnumAction(2, "equip")
--		ActionEquip[2]=EnumAction(5, "equip")
--		ActionEquip[3]=EnumAction(3, "equip")
--		ActionEquip[4]=EnumAction(4, "equip")
--		ActionEquip[5]=EnumAction(1, "equip")
--		ActionEquip[6]=EnumAction(15, "equip")
--	elseif (ZhenYuan_TabIndex == 1) then
--		startIdx = ZhenYuanPageSize
--		ActionEquip[1]=EnumAction(7, "equip")
--		ActionEquip[2]=EnumAction(6, "equip")
--		ActionEquip[3]=EnumAction(11, "equip")
--		ActionEquip[4]=EnumAction(14, "equip")
--		ActionEquip[5]=EnumAction(12, "equip")
--		ActionEquip[6]=EnumAction(13, "equip")
--	end
--
--
--
--	if Pneuma:GetMF(ZhenYuan_MF[idx+startIdx]) == 0 then --未激活
--		ZhenYuan_EquipActionBtn[idx]:SetToolTip("#{ZYXT_120528_26}")--"未激活--需要字典"..idx
--	else
--		if ActionEquip[idx]:GetID()==0 then --是否装备了equip
--			ZhenYuan_EquipActionBtn[idx]:SetToolTip("")--"未装备equip--需要字典"..idx----空着
--		end
--	end
--end

--设置ZhenYuan_Info系列控件的显示文字
function ZhenYuan_SetInfoText()
	for i = 1,ZhenYuanPageSize do
		ZhenYuan_SetSubInfoText(i)
	end
end

function ZhenYuan_SetSubInfoText(idx)
	local startIdx = 0
	local ActionEquip={}
	if(ZhenYuan_TabIndex == 0) then
		startIdx = 0
		ActionEquip[1]=EnumAction(7, "equip")
		ActionEquip[2]=EnumAction(6, "equip")
		ActionEquip[3]=EnumAction(11, "equip")
		ActionEquip[4]=EnumAction(14, "equip")
		ActionEquip[5]=EnumAction(12, "equip")
		ActionEquip[6]=EnumAction(13, "equip")
	elseif (ZhenYuan_TabIndex == 1) then
		startIdx = ZhenYuanPageSize
		ActionEquip[1]=EnumAction(2, "equip")
		ActionEquip[2]=EnumAction(5, "equip")
		ActionEquip[3]=EnumAction(3, "equip")
		ActionEquip[4]=EnumAction(4, "equip")
		ActionEquip[5]=EnumAction(1, "equip")
		ActionEquip[6]=EnumAction(15, "equip")
	end

	local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", idx+startIdx-1)

	if Pneuma:GetMF(ZhenYuan_MF[idx+startIdx]) == 0 then --当前idx未激活
		ZhenYuan_InfoText[idx]:SetText( "#{ZYXT_120528_159}" )
	elseif theAction:GetID() == 0 then --未装备真元
		ZhenYuan_InfoText[idx]:SetText( "#{ZYXT_120528_29}" )--真元未装载到插槽上
	elseif ActionEquip[idx]:GetID()==0 then --未装备equip
		--local szEquip={"衣服","腰带","护手","鞋","帽子","护肩","项链","戒指","戒指","护腕","护符","护符",}
		--local szEquip={"#{ZYXT_120528_192}","#{ZYXT_120528_193}","#{ZYXT_120528_194}","#{ZYXT_120528_195}","#{ZYXT_120528_196}","#{ZYXT_120528_197}",
			--"#{ZYXT_120528_198}","#{ZYXT_120528_199}","#{ZYXT_120528_199}","#{ZYXT_120528_201}","#{ZYXT_120528_202}","#{ZYXT_120528_202}",}
			local szEquip={"#{ZYXT_120528_198}","#{ZYXT_120528_199}","#{ZYXT_120528_199}","#{ZYXT_120528_201}","#{ZYXT_120528_202}","#{ZYXT_120528_202}",
			"#{ZYXT_120528_192}","#{ZYXT_120528_193}","#{ZYXT_120528_194}","#{ZYXT_120528_195}","#{ZYXT_120528_196}","#{ZYXT_120528_197}",}
		local szShow=ScriptGlobal_Format( "#{ZYXT_120528_30}", szEquip[idx+startIdx])
		ZhenYuan_InfoText[idx]:SetText( szShow )--角色装备位没有穿上装备
	elseif ActionEquip[idx]:GetRemainRepairCount()<=0 then
		ZhenYuan_InfoText[idx]:SetText( "#{ZYXT_120528_173}" )--装备可修理次数为0
	elseif ActionEquip[idx]:GetEquipDur() <= 0 then --装备耐久为0
		ZhenYuan_InfoText[idx]:SetText( "#{ZYXT_120528_32}" )--装备耐久为0，增强无效
	elseif ActionEquip[idx]:IsLevelEnoughEquip() <= 0 then
		ZhenYuan_InfoText[idx]:SetText( "#{ZYXT_120528_229}" )--资格不够
	else --显示tips
		local szName, nLevel, szAdd, nAdd, nNextAdd=Pneuma:GetPneumaAddingInfo(idx+startIdx-1)
--		PushDebugMessage("szAdd="..szAdd.." nAdd="..nAdd)
		local szShowText=szName.."#r#W等级："..nLevel.."#r"
		if szAdd~="" and nAdd>0 then
			szShowText=szShowText..szAdd.." +"..nAdd
		elseif szAdd~="" then
			szShowText=szShowText..ScriptGlobal_Format( "#{ZYXT_120528_33}", szAdd)
			--szShowText=szShowText.."装备无"..szAdd
		end
		ZhenYuan_InfoText[idx]:SetText(szShowText)--真元属性描述:待策划字典、数值补充之后补齐
	end
end

function ZhenYuan_UpgradeToolTips(idx)
--PushDebugMessage("idx="..idx)
	local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1)
	local needExp = Pneuma:GetPneumaProperty(idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1,6)--需要元晶
	local curLevel = Pneuma:GetPneumaItemProperty(idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1,6)
	if Pneuma:GetMF(ZhenYuan_MF[idx+ZhenYuanPageSize*ZhenYuan_TabIndex]) == 0 then
		ZhenYuan_UpgradeTipsBtn[idx]:SetToolTip("#{ZYXT_120528_34}")
	elseif theAction:GetID() == 0 then
		ZhenYuan_UpgradeTipsBtn[idx]:SetToolTip("#{ZYXT_120528_37}")
	elseif Pneuma:GetPneumaExp() <  needExp and curLevel<9 then
		--按钮置灰状态下的判断
		--ZhenYuan_UpgradeTipsBtn[idx]:SetToolTip(ScriptGlobal_Format( "#{ZYXT_120528_40}", tostring(needExp)))
		local indexequip={7,6,11,14,12,13}
		local indexequip2={2,5,3,4,1,15}
		local curActionEquip=nil
		local startIdx = 0
		if(ZhenYuan_TabIndex == 0) then
			startIdx = 0
			curActionEquip=EnumAction(indexequip[idx], "equip")
		elseif (ZhenYuan_TabIndex == 1) then
			startIdx = ZhenYuanPageSize
			curActionEquip=EnumAction(indexequip2[idx], "equip")
		end
		local szName, nLevel, szAdd, nAdd, nNextAdd=Pneuma:GetPneumaAddingInfo(idx+startIdx-1)
		local szDes,_=Pneuma:GetNextLevelAddingInfo(idx+startIdx-1)
		if curActionEquip:GetID()==0 then --未装备equip
			local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_06}",needExp,szDes)
			ZhenYuan_UpgradeTipsBtn[idx]:SetToolTip(levelBtnTip)
		else--有装备
			if nAdd>0 and nNextAdd>0 then
				--local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_04}",needExp,szDes)
				local diffAdd = nNextAdd - nAdd
				if diffAdd > 0 then
					local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_04}",needExp,szDes,diffAdd,szAdd,szAdd,nNextAdd)
					ZhenYuan_UpgradeTipsBtn[idx]:SetToolTip(levelBtnTip)
				else
					local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_08}",needExp,szDes,szAdd,nNextAdd)
					ZhenYuan_UpgradeTipsBtn[idx]:SetToolTip(levelBtnTip)
				end
			else
				local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_05}",needExp,szDes,szAdd)
				ZhenYuan_UpgradeTipsBtn[idx]:SetToolTip(levelBtnTip)
			end
		end
	elseif tonumber(curLevel)>=9 then
		ZhenYuan_UpgradeTipsBtn[idx]:SetToolTip(ScriptGlobal_Format( "#{ZYXT_120528_38}", tostring(9)))
	else
		ZhenYuan_UpgradeTipsBtn[idx]:SetToolTip("")
	end

end

function ZhenYuan_UpgradeBtnToolTips(idx)
	local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1)
	local needExp = Pneuma:GetPneumaProperty(idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1,6)
	local curLevel = Pneuma:GetPneumaItemProperty(idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1,6)
	if Pneuma:GetPneumaExp() >= needExp and curLevel<9 then
		--按钮点亮状态下的判断
		--ZhenYuan_UpgradeButton[idx]:SetToolTip(ScriptGlobal_Format( "#{ZYXT_120528_39}", tostring(needExp)))
		local indexequip={7,6,11,14,12,13}
		local indexequip2={2,5,3,4,1,15}
		local curActionEquip=nil
		local startIdx = 0
		if(ZhenYuan_TabIndex == 0) then
			startIdx = 0
			curActionEquip=EnumAction(indexequip[idx], "equip")
		elseif (ZhenYuan_TabIndex == 1) then
			startIdx = ZhenYuanPageSize
			curActionEquip=EnumAction(indexequip2[idx], "equip")
		end
		local szName, nLevel, szAdd, nAdd, nNextAdd=Pneuma:GetPneumaAddingInfo(idx+startIdx-1)
		local szDes,_=Pneuma:GetNextLevelAddingInfo(idx+startIdx-1)
		if curActionEquip:GetID()==0 then --未装备equip
			local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_03}",needExp,szDes)
			ZhenYuan_UpgradeButton[idx]:SetToolTip(levelBtnTip)
		else--有装备
			if nAdd>0 and nNextAdd>0 then
				--local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_01}",needExp,szDes)
				local diffAdd = nNextAdd - nAdd
				if diffAdd > 0 then
					local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_01}",needExp,szDes,diffAdd,szAdd,szAdd,nNextAdd)
					ZhenYuan_UpgradeButton[idx]:SetToolTip(levelBtnTip)
				else
					local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_07}",needExp,szDes,szAdd,nNextAdd)
					ZhenYuan_UpgradeButton[idx]:SetToolTip(levelBtnTip)
				end
			else
				local levelBtnTip=ScriptGlobal_Format( "#{ZYSJAN_150416_02}",needExp,szDes,szAdd)
				ZhenYuan_UpgradeButton[idx]:SetToolTip(levelBtnTip)
			end
		end

	end
end

function ZhenYuan_Quit()
	ZhenYuan_Close()
end

function ZhenYuan_Tidy()
	Pneuma:TidyBagPneuma()

end
function ZhenYuan_SlotClicked(idx)
	if idx<1 or idx>6 then
		return
	end
	ZhenYuan_EquipPneumaActionBtn[idx]:DoAction()
end

function ZhenYuan_ItemClicked(idx)
	if(idx < 1 or idx > ZhenYuan_Size) then
		return
	end
	ZhenYuan_SelectItem = idx
	for i = 1, ZhenYuan_Size do
		ZhenYuan_BagPneumaActionBtn[i]:SetPushed(0)
	end
	ZhenYuan_BagPneumaActionBtn[idx]:SetPushed(1)
	ZhenYuan_BagPneumaActionBtn[idx]:DoAction()
end

function ZhenYuan_UpgradeClicked(idx)
--	PushDebugMessage("ZhenYuan_UpgradeClicked"..idx + ZhenYuan_TabIndex*6-1)
	Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("OnUpgradeClicked");
			Set_XSCRIPT_ScriptID(889900);
			Set_XSCRIPT_Parameter(0,idx + ZhenYuan_TabIndex*6-1);
			Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	--停止闪烁
	if "ZhenYuan" == GetFreshManGuideOwner() then
        CloseFreshManGuide()
    end
end


--设置升级按钮是否灰化
function ZhenYuan_SetUpgradeButton()
	for idx=1, ZhenYuanPageSize do
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1)
		local needExp = Pneuma:GetPneumaProperty(idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1,6)
		if Pneuma:GetMF(ZhenYuan_MF[idx+ZhenYuanPageSize*ZhenYuan_TabIndex]) == 0  or theAction:GetID() == 0 or
		Pneuma:GetPneumaProperty(idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1,4) == 9 or Pneuma:GetPneumaExp() <  needExp then
			ZhenYuan_UpgradeButton[idx]:Disable()
		else
			ZhenYuan_UpgradeButton[idx]:Enable()
		end
	end
end

function ZhenYuan_LockClicked()
	if(ZhenYuan_SelectItem < 1 or ZhenYuan_SelectItem > ZhenYuan_Size) then
		PushDebugMessage("#{ZYXT_120528_115}")
		return
	end
	local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", ZhenYuan_SelectItem-1+ZhenYuan_Bag)
	if(theAction:GetID() == 0 ) then
		PushDebugMessage("#{ZYXT_120528_115}")
		return
	end

	--PushDebugMessage(ZhenYuan_SelectItem)
	--Pneuma:PnuemaLock(ZhenYuan_SelectItem-1+ZhenYuan_Bag, "lock")
	--只检查二级密码
	if CheckMinorPassword() ~= 1 then
		return
	end
	PushEvent( "PNEUMA_LOCK_CONFIRM", ZhenYuan_SelectItem-1+ZhenYuan_Bag)

end


function ZhenYuan_UnLockClicked()
	if(ZhenYuan_SelectItem < 1 or ZhenYuan_SelectItem > ZhenYuan_Size) then
		PushDebugMessage("#{ZYXT_120528_118}")
		return
	end
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	local theAction,bLocked,_,nElapsedTime  = Pneuma:EnumPneumaItem("pneuma", ZhenYuan_SelectItem-1+ZhenYuan_Bag)
--	PushDebugMessage("nElapsedTime="..nElapsedTime)
	if(theAction:GetID() == 0 ) then
		PushDebugMessage("#{ZYXT_120528_118}")
		return
	end

	local unlocktime = Pneuma:GetPneumaItemProperty(ZhenYuan_SelectItem-1+ZhenYuan_Bag,8)
	if unlocktime==nil then
		return
	end

	if unlocktime <= 0 then
		PushDebugMessage("#{ZYXT_120528_119}")
		return
	elseif unlocktime > 1 and 259200>nElapsedTime then--正在解锁中
		PushDebugMessage("#{ZYXT_120528_120}")
		return
	elseif unlocktime >1 and 259200<=nElapsedTime then--解锁完成，即未加锁
		PushDebugMessage("#{ZYXT_120528_119}")
		return
	end
	Pneuma:PnuemaLock(ZhenYuan_SelectItem-1+ZhenYuan_Bag, "unlock")
end
function ZhenYuan_OnMoved()
    if "ZhenYuan" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
end
function ZhenYuan_OnHidden()
	if "ZhenYuan" == GetFreshManGuideOwner() then
        CloseFreshManGuide()
    end
end
function ZhenYuan_PickUpToBag(idx)
	local startIdx = 0
	if( ZhenYuan_TabIndex == 1) then
		startIdx = 6
	end

	local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", idx+startIdx-1)
	if Pneuma:GetMF(ZhenYuan_MF[idx+startIdx])==0 then --未激活
		return
	else
		if theAction:GetID() == 0 then --是否装备了真元
			return
		end
		--开始移动
		Pneuma:UnWearPneumaToBag(idx+startIdx-1)
	end
end


function ZhenYuan_UpdatePneumaSet()
	local minlvl, minqua = ZhenYuan_GetMinLvlQualityInLabel()

	ZhenYuan_Blue:Hide()
	ZhenYuan_Purple:Hide()
	ZhenYuan_Orange:Hide()
	ZhenYuan_Lock:Hide()
	if(minqua == 3) then
		ZhenYuan_Blue:Show()
	elseif (minqua== 4) then
		ZhenYuan_Purple:Show()
	elseif(minqua == 5) then
		ZhenYuan_Orange:Show()
	else
		ZhenYuan_Lock:Show()
	end

end

function ZhenYuan_GetMinLvlQualityInLabel()
	local minlvl = 9
	local minqua = 5
	--判断是否已激活插槽、是否装备真元
	for idx=1, ZhenYuanPageSize do
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1)
		if(Pneuma:GetMF(ZhenYuan_MF[idx+ZhenYuanPageSize*ZhenYuan_TabIndex]) == 0 or theAction:GetID()==0) then
			minlvl=0
			minqua=0
			break
		end

		local curLevel = Pneuma:GetPneumaItemProperty(idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1,6)
		local curQua = Pneuma:GetPneumaItemProperty(idx+ZhenYuanPageSize*ZhenYuan_TabIndex-1,4)
		if( curLevel < minlvl) then
			minlvl = curLevel
		end
		if(curQua < minqua) then
			minqua = curQua
		end
	end
	return minlvl, minqua
end

function ZhenYuan_Set_MouseEnter(idx)
	local minlvl, minqua = ZhenYuan_GetMinLvlQualityInLabel()
	--真圆盘坐标和大小
	local SetX= ZhenYuan_Orange:GetProperty("AbsoluteXPosition") + ZhenYuan_Frame:GetProperty("AbsoluteXPosition")+ZhenYuan_List:GetProperty("AbsoluteXPosition")+ZhenYuan_Frame_Client:GetProperty("AbsoluteXPosition")+ZhenYuan_Main_Frame:GetProperty("AbsoluteXPosition")
	local SetY = ZhenYuan_Orange:GetProperty("AbsoluteYPosition")  + ZhenYuan_Frame:GetProperty("AbsoluteYPosition")+ZhenYuan_List:GetProperty("AbsoluteYPosition")+ZhenYuan_Frame_Client:GetProperty("AbsoluteYPosition")+ZhenYuan_Main_Frame:GetProperty("AbsoluteYPosition")
	local SetWidth = ZhenYuan_Orange:GetProperty("AbsoluteWidth")
	local SetHeight = ZhenYuan_Orange:GetProperty("AbsoluteHeight")
	PushEvent("ZHENYUAN_SET_MOUSEENTER", minlvl, idx, ZhenYuan_TabIndex,SetX,SetY,SetWidth,SetHeight)
end

function ZhenYuan_Set_MouseLeave(idx)
	PushEvent("ZHENYUAN_SET_MOUSELEAVE")
end

function ZhenYuan_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end

function ZhenYuan_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function ZhenYuan_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function ZhenYuan_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

function ZhenYuan_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		ZhenYuan_ShenDing:Disable()
		ZhenYuan_ShenDing_tips:Show()
	--	ZhenYuan_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		ZhenYuan_ShenDing:Enable()
		ZhenYuan_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		ZhenYuan_Infant:Disable()
		ZhenYuan_Infant_tips:Show()
	--	ZhenYuan_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		ZhenYuan_Infant:Enable()
		ZhenYuan_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		ZhenYuan_Wuhun:Disable()
--		ZhenYuan_Wuhun_tips:Show()
	--	ZhenYuan_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		ZhenYuan_Wuhun:Enable()
		ZhenYuan_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		ZhenYuan_Xiulian:Disable()
		ZhenYuan_Xiulian_tips:Show()
	--	ZhenYuan_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		ZhenYuan_Xiulian:Enable()
		ZhenYuan_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		ZhenYuan_Miji:Disable()
		ZhenYuan_Miji_tips:Show()
	--	ZhenYuan_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		ZhenYuan_Miji:Enable()
		ZhenYuan_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		ZhenYuan_ZhenYuan:Disable()
		ZhenYuan_ZhenYuan_tips:Show()
--		ZhenYuan_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		ZhenYuan_ZhenYuan:Enable()
		ZhenYuan_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		ZhenYuan_JueWei:Disable()
		ZhenYuan_JueWei_tips:Show()
	--	ZhenYuan_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		ZhenYuan_JueWei:Enable()
		ZhenYuan_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		ZhenYuan_JingMai:Disable()
		ZhenYuan_JingMai_tips:Show()
	--	ZhenYuan_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		ZhenYuan_JingMai:Enable()
		ZhenYuan_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		ZhenYuan_BaoJian:Disable()
		ZhenYuan_BaoJian_tips:Show()
	else
		ZhenYuan_BaoJian:Enable()
		ZhenYuan_BaoJian_tips:Hide()
	end
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		ZhenYuan_WuYi:Enable()
		ZhenYuan_WuYi_tips:Hide()
	else
		ZhenYuan_WuYi:Disable()
		ZhenYuan_WuYi_tips:Show()
	end
	ZhenYuan_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		ZhenYuan_ShenQi:Enable()
		ZhenYuan_ShenQi_tips:Hide()
	else
		ZhenYuan_ShenQi:Disable()
		ZhenYuan_ShenQi_tips:Show()
	end
	ZhenYuan_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		ZhenYuan_Armor:Enable()
		ZhenYuan_Armor_tips:Hide()
	else
		ZhenYuan_Armor:Disable()
		ZhenYuan_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		ZhenYuan_CangPin:Enable()
		ZhenYuan_CangPin_tips:Hide()
	else
		ZhenYuan_CangPin:Disable()
		ZhenYuan_CangPin_tips:Show()
	end
	
	ZhenYuan_RefreshCangPinTip()
end

function ZhenYuan_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function ZhenYuan_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ZhenYuan_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_ZhenYuan_PageButton[idx]:GetProperty("UnifiedXPosition");
			ZhenYuan_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		ZhenYuan_WuYi_Buttontips:Show()
	else
		ZhenYuan_WuYi_Buttontips:Hide()
	end
end

function ZhenYuan_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_ZhenYuan_PageButton[idx]:GetProperty("UnifiedXPosition");
			ZhenYuan_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		ZhenYuan_OtherInfo_ButtonTips:Show()
	else
		ZhenYuan_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function ZhenYuan_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function ZhenYuan_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", ZhenYuan_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function ZhenYuan_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_ZhenYuan_PageButton[idx]:GetProperty("UnifiedXPosition");
			ZhenYuan_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		ZhenYuan_CangPin_Buttontips:Show()
	else
		ZhenYuan_CangPin_Buttontips:Hide()
	end
end


function ZhenYuan_ShowPage()

	for i = 1, table.getn(g_ZhenYuan_Page) do
		g_ZhenYuan_PageButton[i]:Hide()
		g_ZhenYuan_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	ZhenYuan_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_ZhenYuan_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_ZhenYuan_Page) do
			if i ~= nPageNumber then
				g_ZhenYuan_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_ZhenYuan_Page) do
		if ZhenYuan_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_ZhenYuan_PageButton[g_PageCount]:Show()
			g_ZhenYuan_PageButton[g_PageCount]:SetText(g_ZhenYuan_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if ZhenYuan_IsPageEnable(i) == 1 then
				g_ZhenYuan_PageButton[g_PageCount]:Enable()
				g_ZhenYuan_PageMask[g_PageCount]:Hide()
			else
				g_ZhenYuan_PageButton[g_PageCount]:Disable()
				g_ZhenYuan_PageMask[g_PageCount]:Show()
				if g_ZhenYuan_Page[i].Tip ~= "" then
					g_ZhenYuan_PageMask[g_PageCount]:SetToolTip(g_ZhenYuan_Page[i].Tip)
				end
			end
		end
	end
	
	ZhenYuan_RefreshWuYiTip()
	ZhenYuan_RefreshOtherInfoTip()
	ZhenYuan_RefreshCangPinTip()
	
end

function ZhenYuan_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		ZhenYuan_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		ZhenYuan_SelfData_Switch()
	elseif idx == 3 then--珍兽
		ZhenYuan_Pet_Switch()
	elseif idx == 4 then--子女
		ZhenYuan_Infant_Switch()
	elseif idx == 5 then--武魂
		ZhenYuan_Wuhun_Switch()
	elseif idx == 6 then--修炼
		ZhenYuan_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		ZhenYuan_Miji_Page_Switch()
	elseif idx == 8 then--真元
		--SelfData_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		ZhenYuan_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		ZhenYuan_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		ZhenYuan_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		ZhenYuan_OpenBaoJian()
	elseif idx == 13 then--武意
		ZhenYuan_OpenWuYi()
	elseif idx == 14 then--神器
		ZhenYuan_OpenShenQi()
	elseif idx == 15 then--星盘
		ZhenYuan_Armor_Page_Switch()
	elseif idx == 16 then--名物
		ZhenYuan_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		ZhenYuan_OtherInfo_Page_Switch()
	end
end

function ZhenYuan_CheckPage(idx)
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

function ZhenYuan_IsPageEnable(idx)
	
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

function ZhenYuan_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


