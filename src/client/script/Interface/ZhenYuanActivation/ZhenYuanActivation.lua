--真元激活界面

local ZhenYuanActivation_EquipArray
local ZhenYuanActivation_PneumaArray
local ZhenYuanActivation_Feng={}
--local ZhenYuanActivation_InfoText={}
local ZhenYuanActivation_Animate={}
local ZhenYuanActivation_EquipImage={}
local ZhenYuanActivation_PageNum = 6
local ZhenYuanActivation_TabIndex = 0
local ZhenYuanActivation_SelectIndex = 0
local ZhenYuanActivation_ObjCared
local ZhenYuanActivation_MF={589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600}
local ZhenYuanActivation_Mid = 1602

local g_TipsNum_MiZhenZhi = 0 --显示到第几个tips了
local g_bShowTips=0
local g_MissionID_MiZhenZhi = 1602
--数据显示
local ZhenYuanActivation_JiaoZi={
10,
15,
20,
25,
30,
35,
40,
45,
50,
56,
61,
66,
0,
}

function ZhenYuanActivation_PreLoad()
	this:RegisterEvent("PNEUMAITEM_CHANGED")
	this:RegisterEvent("REFRESH_EQUIP")
	this:RegisterEvent("PNEUMA_EXPCHIP_CHANGED")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("MONEY_CHANGE_EX",false);
end


function ZhenYuanActivation_OnLoad()
	ZhenYuanActivation_EquipArray={
	ZhenYuanActivation_Equip1, ZhenYuanActivation_Equip2, ZhenYuanActivation_Equip3, ZhenYuanActivation_Equip4, ZhenYuanActivation_Equip5, ZhenYuanActivation_Equip6,
	}
	ZhenYuanActivation_PneumaArray={
	ZhenYuanActivation_Slots1, ZhenYuanActivation_Slots2, ZhenYuanActivation_Slots3, ZhenYuanActivation_Slots4, ZhenYuanActivation_Slots5, ZhenYuanActivation_Slots6,
	}
	ZhenYuanActivation_Feng={
	ZhenYuanActivation_Feng1,ZhenYuanActivation_Feng2,ZhenYuanActivation_Feng3,ZhenYuanActivation_Feng4,ZhenYuanActivation_Feng5,ZhenYuanActivation_Feng6,
	}
	--ZhenYuanActivation_InfoText={
	--ZhenYuanActivation_Info1,ZhenYuanActivation_Info2,ZhenYuanActivation_Info3,ZhenYuanActivation_Info4,ZhenYuanActivation_Info5,ZhenYuanActivation_Info6,
	--}
	ZhenYuanActivation_Animate={
	ZhenYuanActivation_Animate1,ZhenYuanActivation_Animate2,ZhenYuanActivation_Animate3,ZhenYuanActivation_Animate4,ZhenYuanActivation_Animate5,ZhenYuanActivation_Animate6,
	}

	--设置客户端界面使用的图片资源，根据是否为唯美版选择不同的图片资源集
	--"衣服","腰带","护手","鞋","帽子","护肩","项链","戒指","戒指","护腕","护符","护符"
	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图标资源为唯美版对应的资源
		ZhenYuanActivation_EquipImage={
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
		ZhenYuanActivation_EquipImage={
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
end


function ZhenYuanActivation_Close()
	if "ZhenYuanActivation" == GetFreshManGuideOwner() then
        CloseFreshManGuide()
    end
	this:Hide()
end


function ZhenYuanActivation_OnEvent( event )
	--this:Show()
	--PushDebugMessage(event)
	if event=="UI_COMMAND" and tonumber(arg0) == 88990099 then--88990099在889903脚本中
		local xx = Get_XParam_INT(0);
			objCared = DataPool : GetNPCIDByServerID(xx);
			if objCared == -1 then
					return;
			end
		ZhenYuanActivation_ObjCared = objCared;
		this:CareObject(objCared, 1, "ZhenYuanActivation")

		this:Show()
		ZhenYuanActivation_OnUpdate()
		--增加引导tips
		g_bShowTips = 0
		g_TipsNum_MiZhenZhi = 0
		--是否完成了激活步骤
		local missionIndex = DataPool:GetPlayerMissionIndexByID(g_MissionID_MiZhenZhi)
		local param = 0
		local ifCompelete = 0
		if missionIndex >= 0 and missionIndex < 20 then
			ifCompelete = DataPool:GetPlayerMission_Variable(missionIndex, 0)
			param = DataPool:GetPlayerMission_Variable(missionIndex, 2)
			if ifCompelete == 0 then
				g_bShowTips = 1
			end
		end
		if (g_bShowTips == 1) and (g_TipsNum_MiZhenZhi == 0) and ( param ~= 1 ) then
			local fX, fY = this:GetChildOffset("ZhenYuanActivation_Activation_Button")
			fX = fX + ZhenYuanActivation_Activation_Button:GetProperty("AbsoluteWidth") / 2
			--fY = fY + MissionTrack_Frame_Context:GetProperty("AbsoluteHeight")
			OpenFreshManGuide(1, 26, fX, fY, "ZhenYuanActivation", "northwest")
			g_TipsNum_MiZhenZhi = 1
		end
	elseif event=="REFRESH_EQUIP" or event=="PNEUMAITEM_CHANGED" or event=="PNEUMA_EXPCHIP_CHANGED" or event== "MONEYJZ_CHANGE_EX"
	or event=="MONEY_CHANGE_EX" or (event=="UI_COMMAND" and tonumber(arg0) == 88990098) then
		if this:IsVisible() then
			ZhenYuanActivation_OnUpdate()
		end
	end

end


function ZhenYuanActivation_OnUpdate()
	local AE={}
	local startIndex = 0
	if(ZhenYuanActivation_TabIndex == 0) then
		ZhenYuanActivation_FenYe1:SetText("#{ZYXT_120528_166}")--#G乾天
		ZhenYuanActivation_FenYe2:SetText("#{ZYXT_120528_21}")
		startIndex = 0
		--AE[1]=EnumAction(2, "equip")
		--AE[2]=EnumAction(5, "equip")
		--AE[3]=EnumAction(3, "equip")
		--AE[4]=EnumAction(4, "equip")
		--AE[5]=EnumAction(1, "equip")
		--AE[6]=EnumAction(15, "equip")
		AE[1]=EnumAction(7, "equip")
		AE[2]=EnumAction(6, "equip")
		AE[3]=EnumAction(11, "equip")
		AE[4]=EnumAction(14, "equip")
		AE[5]=EnumAction(12, "equip")
		AE[6]=EnumAction(13, "equip")
	elseif (ZhenYuanActivation_TabIndex == 1) then
		ZhenYuanActivation_FenYe1:SetText("#{ZYXT_120528_22}")--乾天
		ZhenYuanActivation_FenYe2:SetText("#{ZYXT_120528_165}")
		startIndex = ZhenYuanActivation_PageNum
		--AE[1]=EnumAction(7, "equip")
		--AE[2]=EnumAction(6, "equip")
		--AE[3]=EnumAction(11, "equip")
		--AE[4]=EnumAction(14, "equip")
		--AE[5]=EnumAction(12, "equip")
		--AE[6]=EnumAction(13, "equip")
		AE[1]=EnumAction(2, "equip")
		AE[2]=EnumAction(5, "equip")
		AE[3]=EnumAction(3, "equip")
		AE[4]=EnumAction(4, "equip")
		AE[5]=EnumAction(1, "equip")
		AE[6]=EnumAction(15, "equip")
	end
	for i = 1, ZhenYuanActivation_PageNum do
		ZhenYuanActivation_Animate[i]:Hide()
	end
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	--if(selfZoneWorldID~=9015 and selfZoneWorldID~=9031) then
		--ZhenYuanActivation_Miaoshu:SetText("#{ZYXT_120528_223}")
	--else
		ZhenYuanActivation_Miaoshu:SetText("#{ZYXT_120528_98}")
	--end

	ZhenYuanActivation_SelectIndex = 0
	local startIdx = 0
	if( ZhenYuanActivation_TabIndex == 1) then
		startIdx = 6
	end
	for i=1, ZhenYuanActivation_PageNum do
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", i+startIndex-1);--36打头

		if Pneuma:GetMF(ZhenYuanActivation_MF[i+startIdx]) == 0 then
			ZhenYuanActivation_Feng[i]:SetProperty("Image", "set:ZhenYuanUI1 image:ZhenYuanActivation_Feng")
			ZhenYuanActivation_Feng[i]:SetProperty("Visible","True")
			ZhenYuanActivation_PneumaArray[i]:SetProperty("Visible","False")
--			--ZhenYuanActivation_InfoText[i]:SetText( "#{ZYXT_120528_159}" )--当前idx未激活
		else
			ZhenYuanActivation_Feng[i]:SetProperty("Visible","False")
			ZhenYuanActivation_PneumaArray[i]:SetProperty("Visible","True")
			ZhenYuanActivation_PneumaArray[i]:SetActionItem(theAction:GetID());
--			if theAction:GetID() == 0 then --未装备真元
--				--ZhenYuanActivation_InfoText[i]:SetText( "#{ZYXT_120528_29}" )--真元未装载到插槽上
--			elseif AE[i]:GetID()==0 then --未装备equip
--				local szEquip={"衣服","腰带","护手","鞋","帽子","护肩","项链","戒指","戒指","护腕","护符","护符",}
--				local szShow=ScriptGlobal_Format( "#{ZYXT_120528_30}", szEquip[i+startIdx])
--				--ZhenYuanActivation_InfoText[i]:SetText( szShow )--角色装备位没有穿上装备
--			--剩余修理次数
--			elseif AE[i]:GetRemainRepairCount()<=0 then
--				--ZhenYuanActivation_InfoText[i]:SetText( "#cff0000装备修理次数为0" )--
--			elseif AE[i]:GetEquipDur() < 0.1 then --装备耐久为0
--				--ZhenYuanActivation_InfoText[i]:SetText( "#{ZYXT_120528_32}" )--装备耐久为0，增强无效
--			else --显示tips
--				local szName, nLevel, szAdd, nAdd=Pneuma:GetPneumaAddingInfo(i+startIdx-1)
--				local szShowText=szName.."#r#W等级："..nLevel.."#r"
--				if szAdd~="" and nAdd>0 then
--					szShowText=szShowText..szAdd.."+"..nAdd
--				elseif szAdd~="" then
--					szShowText=szShowText..ScriptGlobal_Format( "#{ZYXT_120528_33}", szAdd)
--					--szShowText=szShowText.."装备无"..szAdd
--				end
--				--ZhenYuanActivation_InfoText[i]:SetText(szShowText)--真元属性描述:待策划字典、数值补充之后补齐
--			end
		end
	end


	for j=1, ZhenYuanActivation_PageNum do
		ZhenYuanActivation_EquipArray[j]:SetActionItem(AE[j]:GetID())
		if AE[j]:GetID()==0 then
			ZhenYuanActivation_EquipArray[j]:SetProperty("BackImage", ZhenYuanActivation_EquipImage[j+startIdx])
		end
	end

	local nActive = ZhenYuanActivation_GetActiveCount()
	--0-11 is valid
	local needjiaozi = ZhenYuanActivation_JiaoZi[nActive+1]*10000
	local needChip = nActive*30
	if nActive==12 then
		needChip=0
	end

	ZhenYuanActivation_Yuanjing:SetProperty("Text", needChip)
	ZhenYuanActivation_DemandMoney:SetProperty("MoneyNumber", needjiaozi)

	ZhenYuanActivation_SelfYuanjing:SetProperty("Text", tostring(Pneuma:GetPneumaChip()))
	ZhenYuanActivation_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	ZhenYuanActivation_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	--性别显示
	--女or男
	local iSexy =Player:GetMySex()
	if iSexy==1 then
		ZhenYuanActivation_NV:Hide()
		ZhenYuanActivation_NAN:Show()
	else
		ZhenYuanActivation_NV:Show()
		ZhenYuanActivation_NAN:Hide()
	end
end


function ZhenYuanActivation_ChangeTabIndex(nTabIndex)
	ZhenYuanActivation_TabIndex = nTabIndex
	ZhenYuanActivation_OnUpdate()
end

function ZhenYuanActivation_SlotClicked(idx)
--PushDebugMessage("idx="..idx)
	if idx < 1 or idx > ZhenYuanActivation_PageNum then
		return;
	end

	for i = 1, ZhenYuanActivation_PageNum do
		ZhenYuanActivation_PneumaArray[i]:SetPushed(0)
		ZhenYuanActivation_Animate[i]:Hide()
	end
	ZhenYuanActivation_PneumaArray[idx]:SetPushed(1)
	--显示的是封还是actionbutton
	local startIdx = 0
	if (ZhenYuanActivation_TabIndex == 1) then
		startIdx = 6
	end
--	if ZhenYuanActivation_SelectIndex>=1 and ZhenYuanActivation_SelectIndex<=ZhenYuanActivation_PageNum then
--		if Pneuma:GetMF(ZhenYuanActivation_MF[ZhenYuanActivation_SelectIndex+startIdx]) == 0 then
----			ZhenYuanActivation_Feng[ZhenYuanActivation_SelectIndex]:SetProperty("Image", "set:ZhenYuanUI1 image:ZhenYuanActivation_Feng")
--			ZhenYuanActivation_Feng[ZhenYuanActivation_SelectIndex]:SetProperty("Visible","True")
--			ZhenYuanActivation_PneumaArray[ZhenYuanActivation_SelectIndex]:SetProperty("Visible","False")
--		end
--	end
	ZhenYuanActivation_SelectIndex = idx
	if ZhenYuanActivation_SelectIndex>=1 and ZhenYuanActivation_SelectIndex<=ZhenYuanActivation_PageNum then
		if Pneuma:GetMF(ZhenYuanActivation_MF[ZhenYuanActivation_SelectIndex+startIdx]) == 0 then
----			ZhenYuanActivation_Feng[ZhenYuanActivation_SelectIndex]:SetProperty("Image", "set:ZhenYuanUI1 image:ZhenYuanActivation_Feng2")
--			ZhenYuanActivation_Feng[ZhenYuanActivation_SelectIndex]:SetProperty("Visible","True")
--			ZhenYuanActivation_PneumaArray[ZhenYuanActivation_SelectIndex]:SetProperty("Visible","False")
			ZhenYuanActivation_Animate[ZhenYuanActivation_SelectIndex]:Show()
		end
	end
end

function ZhenYuanActivation_Quit()
	ZhenYuanActivation_SelectIndex = 0
	ZhenYuanActivation_TabIndex = 0

	if "ZhenYuanActivation" == GetFreshManGuideOwner() then
        CloseFreshManGuide()
    end
	this:Hide()
end

function ZhenYuanActivation_Refuse_Click()
	ZhenYuanActivation_Quit()
end

function ZhenYuanActivation_GetActiveCount()
	local ac = 0
	for i = 1,table.getn(ZhenYuanActivation_MF) do
		if Pneuma:GetMF(ZhenYuanActivation_MF[i]) == 1 then
			ac = ac + 1
		end
	end
	return ac
end

function ZhenYuanActivation_ActiveClicked()
--PushDebugMessage("click activation")
	if	ZhenYuanActivation_SelectIndex <= 0 or ZhenYuanActivation_SelectIndex > 6 or ZhenYuanActivation_TabIndex<0 or ZhenYuanActivation_TabIndex>1 then
		PushDebugMessage("#{ZYXT_120528_106}")--你需要选择一个盘眼后，才可以进行激活操作。
		return
	end

--	if(Pneuma:IsHaveMissionComplete(ZhenYuanActivation_Mid) == 0 and Pneuma:IsMissionAcc(ZhenYuanActivation_Mid)==0) then
--		PushDebugMessage("need accept or complete pneuma task")
--		return
--	end
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	--if(ZhenYuanActivation_TabIndex==1 and selfZoneWorldID~=9015 and selfZoneWorldID~=9031) then
		--PushDebugMessage("#{ZYXT_120528_224}")--张士心对真元的研究尚未达到极致，还无法为大侠启封坤地内的盘眼。
		--return
	--end

	local nActive = ZhenYuanActivation_GetActiveCount()
	--0-11 is valid
	local needjiaozi = ZhenYuanActivation_JiaoZi[nActive+1]*10000
	local needChip = nActive*30
	if nActive==12 then
		needChip=0
	end
	if (Pneuma:GetMF(ZhenYuanActivation_MF[ZhenYuanActivation_SelectIndex + ZhenYuanActivation_TabIndex*6]) == 1) then
		PushDebugMessage("#{ZYXT_120528_107}")--current slot is already actived
		return
	end

	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

	if Pneuma:GetPneumaChip() < needChip then
		PushDebugMessage("#{ZYXT_120528_108}")--真元碎片不足
		return
	end
	local playerMoneyPlusJZ = Player:GetData("MONEY_JZ") + Player:GetData("MONEY")
	if playerMoneyPlusJZ < needjiaozi then
		PushDebugMessage("#{ZYXT_120528_109}")
		return
	end

	--电话密保，二级密码在服务器判断

	Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("OnActivePneumaSlot");
				Set_XSCRIPT_ScriptID(889903);
				Set_XSCRIPT_Parameter(0,ZhenYuanActivation_SelectIndex + ZhenYuanActivation_TabIndex*6);
				Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	--是否完成了激活步骤
	local missionIndex = DataPool:GetPlayerMissionIndexByID(g_MissionID_MiZhenZhi)
	local param = 0
	if missionIndex >= 0 and missionIndex < 20 then
		param = DataPool:GetPlayerMission_Variable(missionIndex, 2)
	end

	local missionIndex_zhenzhi = DataPool:GetPlayerMissionIndexByID(g_MissionID_MiZhenZhi)
	local paramIfCompelete_zhenzhi = 0
	local bHaveZhenZhiMis = 0
	if missionIndex_zhenzhi >= 0 and missionIndex_zhenzhi < 20 then
		bHaveZhenZhiMis = 1
		paramIfCompelete_zhenzhi = DataPool:GetPlayerMission_Variable(missionIndex, 0)
	end

	if bHaveZhenZhiMis > 0 and paramIfCompelete_zhenzhi <= 0  then
		SetTimer("ZhenYuanActivation","ZhenYuanActivation_OpenZhenYuanPanLater()", 100)
	end
	if "ZhenYuanActivation" == GetFreshManGuideOwner() then
		CloseFreshManGuide()
	end
end
function ZhenYuanActivation_OnMoved()
    if "ZhenYuanActivation" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
end
function ZhenYuanActivation_OnHidden()
	if "ZhenYuanActivation" == GetFreshManGuideOwner() then
        CloseFreshManGuide()
    end
end
function ZhenYuanActivation_OpenZhenYuanPanLater()
	--是否完成了激活步骤
	PushEvent( "TOGGLE_PNEUMA_UI", g_bShowTips)
	KillTimer("ZhenYuanActivation_OpenZhenYuanPanLater()")
end
