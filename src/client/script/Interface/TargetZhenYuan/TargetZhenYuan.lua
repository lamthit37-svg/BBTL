--*********************
--查看目标真元界面
--*********************
local EquipActionBtn={}
local SlotsActionBtn={}
local TargetZhenYuan_TextInfo={}
local TargetZhenYuan_Feng={}
local TargetZhenYuan_EquipImage={}
local TargetZhenYuan_Size=24

local ZhenYuanTarget_TabIndex=0 --0,1
local ZhenYuanTargetPageSize = 6
local g_TargetZhenYuan_Frame_UnifiedPosition;

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetZhenYuan_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = ""},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = ""},
	[6] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = ""},
	[7] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = ""},
	[8] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = ""},
	[9] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = ""},
	[10] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = ""},
	[11] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = ""},
	[12] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = ""},
	[13] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = ""},
	[14] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = ""},
	[15] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = ""},
}

local g_TargetPageButton = {}
local g_TargetPageCount = 0
local g_TargetPageOrder = {}

function TargetZhenYuan_PreLoad()

	--open or close this window
	this:RegisterEvent("TOGGLE_TARGETPNEUMA_UI");
	--player quit game
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	--update equip
	this:RegisterEvent("OTHERPLAYER_UPDATE_EQUIP");

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


function TargetZhenYuan_OnLoad()
	EquipActionBtn={
	TargetZhenYuan_Equip1,TargetZhenYuan_Equip2,TargetZhenYuan_Equip3,TargetZhenYuan_Equip4,TargetZhenYuan_Equip5,TargetZhenYuan_Equip6,
	}
	SlotsActionBtn={
	TargetZhenYuan_Slots1,TargetZhenYuan_Slots2,TargetZhenYuan_Slots3,TargetZhenYuan_Slots4,TargetZhenYuan_Slots5,TargetZhenYuan_Slots6,
	}
	TargetZhenYuan_TextInfo={
	TargetZhenYuan_Info1,TargetZhenYuan_Info2,TargetZhenYuan_Info3,TargetZhenYuan_Info4,TargetZhenYuan_Info5,TargetZhenYuan_Info6,
	}
	g_TargetZhenYuan_Frame_UnifiedPosition=TargetZhenYuan_Frame:GetProperty("UnifiedPosition");
	TargetZhenYuan_Feng={
	TargetZhenYuan_Feng1,TargetZhenYuan_Feng2,TargetZhenYuan_Feng3,TargetZhenYuan_Feng4,TargetZhenYuan_Feng5,TargetZhenYuan_Feng6,
	}
	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则设置图片资源为唯美版资源
		--"项链","戒指","戒指","护腕","护符","护符"; "衣服","腰带","护手","鞋","帽子","护肩"
		TargetZhenYuan_EquipImage={
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
	else									--客户端是经典版，设置图片资源为经典版
		TargetZhenYuan_EquipImage={
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
	
	g_TargetPageButton[1] = TargetZhenYuan_Equip
	g_TargetPageButton[2] = TargetZhenYuan_SelfData
	g_TargetPageButton[3] = TargetZhenYuan_Pet
	g_TargetPageButton[4] = TargetZhenYuan_Infant
	g_TargetPageButton[5] = TargetZhenYuan_Wuhun
	g_TargetPageButton[6] = TargetZhenYuan_Miji
	g_TargetPageButton[7] = TargetZhenYuan_ZhenYuan
	g_TargetPageButton[8] = TargetZhenYuan_JingMaiInfo
	g_TargetPageButton[9] = TargetZhenYuan_ShenDing
	g_TargetPageButton[10] = TargetZhenYuan_JueWei
	g_TargetPageButton[11] = TargetZhenYuan_BaoJian
	g_TargetPageButton[12] = TargetZhenYuan_WuYi
	g_TargetPageButton[13] = TargetZhenYuan_ShenQi
	g_TargetPageButton[14] = TargetZhenYuan_Armor
	g_TargetPageButton[15] = TargetZhenYuan_CangPin
	
end


function TargetZhenYuan_OnEvent( event )
	if (event=="TOGGLE_TARGETPNEUMA_UI") then
		if(this:IsVisible()) then
			this:Hide();
			return;
		end

		local obj_id = CachedTarget:GetData("NPCID", 1)
		if (type(obj_id) ~="number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		this:CareObject(obj_id , 1)

	    local OtherUnionPos = Variable:GetVariable("OtherUnionPos");
	    if (OtherUnionPos ~= nil) then
		    TargetZhenYuan_Frame:SetProperty("UnifiedPosition", OtherUnionPos);
		end
		ZhenYuanTarget_TabIndex=0
		TargetZhenYuan_Update()
		TargetZhenYuan_ShowPage()
		TargetZhenYuan_ZhenYuan:SetCheck(1)
		this:Show()
	elseif (event=="HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return
	elseif( event == "OTHERPLAYER_UPDATE_EQUIP" and this:IsVisible() ) then
		Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
		TargetZhenYuan_Update()
	elseif (event=="ADJEST_UI_POS") then
		TargetZhenYuan_Frame_On_ResetPos()
	elseif (event=="VIEW_RESOLUTION_CHANGED") then
		TargetZhenYuan_Frame_On_ResetPos()
	end

end
--================================================
-- 恢复界面的默认相对位置
--================================================
function TargetZhenYuan_Frame_On_ResetPos()
  TargetZhenYuan_Frame:SetProperty("UnifiedPosition", g_TargetZhenYuan_Frame_UnifiedPosition);
end

function TargetZhenYuan_Update()
	local startIndex = 0
	local ActionEquip={}
	if(ZhenYuanTarget_TabIndex == 0) then
		TargetZhenYuan_FenYe1:SetText("#{ZYXT_120528_166}")--#G乾天
		TargetZhenYuan_FenYe2:SetText("#{ZYXT_120528_21}")
		startIndex = 0
--		ActionEquip[1]=EnumAction(2, "targetequip")
--		ActionEquip[2]=EnumAction(5, "targetequip")
--		ActionEquip[3]=EnumAction(3, "targetequip")
--		ActionEquip[4]=EnumAction(4, "targetequip")
--		ActionEquip[5]=EnumAction(1, "targetequip")
--		ActionEquip[6]=EnumAction(15, "targetequip")
		ActionEquip[1]=EnumAction(7, "targetequip")
		ActionEquip[2]=EnumAction(6, "targetequip")
		ActionEquip[3]=EnumAction(11, "targetequip")
		ActionEquip[4]=EnumAction(14, "targetequip")
		ActionEquip[5]=EnumAction(12, "targetequip")
		ActionEquip[6]=EnumAction(13, "targetequip")
	elseif (ZhenYuanTarget_TabIndex == 1) then
		TargetZhenYuan_FenYe1:SetText("#{ZYXT_120528_22}")--乾天
		TargetZhenYuan_FenYe2:SetText("#{ZYXT_120528_165}")
		startIndex = ZhenYuanTargetPageSize
--		ActionEquip[1]=EnumAction(7, "targetequip")
--		ActionEquip[2]=EnumAction(6, "targetequip")
--		ActionEquip[3]=EnumAction(11, "targetequip")
--		ActionEquip[4]=EnumAction(14, "targetequip")
--		ActionEquip[5]=EnumAction(12, "targetequip")
--		ActionEquip[6]=EnumAction(13, "targetequip")
		ActionEquip[1]=EnumAction(2, "targetequip")
		ActionEquip[2]=EnumAction(5, "targetequip")
		ActionEquip[3]=EnumAction(3, "targetequip")
		ActionEquip[4]=EnumAction(4, "targetequip")
		ActionEquip[5]=EnumAction(1, "targetequip")
		ActionEquip[6]=EnumAction(15, "targetequip")
	end
	for j=1, ZhenYuanTargetPageSize do
		EquipActionBtn[j]:SetActionItem(ActionEquip[j]:GetID())
		if ActionEquip[j]:GetID()==0 then
			EquipActionBtn[j]:SetProperty("BackImage", TargetZhenYuan_EquipImage[j+startIndex])
		end
	end

	for i=1, ZhenYuanTargetPageSize do
		local theAction,bLocked = Pneuma:EnumPneumaItem("targetpneuma", i+startIndex-1);--0打头
		local nActiveFlag=Pneuma:GetTargetMFAct(i+startIndex-1)
--		PushDebugMessage("nActiveFlag="..nActiveFlag)
		if nActiveFlag==1 then--盘眼已经激活
			TargetZhenYuan_Feng[i]:SetProperty("Visible","False")
			SlotsActionBtn[i]:SetProperty("Visible","True")
			if theAction:GetID() ~= 0 then
				SlotsActionBtn[i]:SetActionItem(theAction:GetID());
			else
				SlotsActionBtn[i]:SetActionItem(-1);
			end
		else
			TargetZhenYuan_Feng[i]:SetProperty("Visible","True")
			SlotsActionBtn[i]:SetProperty("Visible","False")
		end
	end
	local iSexy = Player:GeTargetSex()
	if iSexy == 1 then
		TargetZhenYuan_NV:Hide();
		TargetZhenYuan_NAN:Show();
	else
		TargetZhenYuan_NV:Show();
		TargetZhenYuan_NAN:Hide();
	end
	--显示文本
	for i = 1,ZhenYuanTargetPageSize do
		local theAction,bLocked = Pneuma:EnumPneumaItem("targetpneuma", i+startIndex-1)
		if Pneuma:GetTargetMFAct(i+startIndex-1)==0 then
	--	if Pneuma:GetMF(ZhenYuan_MF[idx+startIdx]) == 0 then --当前idx未激活
			TargetZhenYuan_TextInfo[i]:SetText( "#{ZYXT_120528_159}" )
		elseif theAction:GetID() == 0 then --未装备真元
			TargetZhenYuan_TextInfo[i]:SetText( "#{ZYXT_120528_29}" )--真元未装载到插槽上
		elseif ActionEquip[i]:GetID()==0 then --未装备equip
			--local szEquip={"衣服","腰带","护手","鞋","帽子","护肩","项链","戒指","戒指","护腕","护符","护符",}
			--local szEquip={"#{ZYXT_120528_192}","#{ZYXT_120528_193}","#{ZYXT_120528_194}","#{ZYXT_120528_195}","#{ZYXT_120528_196}","#{ZYXT_120528_197}",
			--"#{ZYXT_120528_198}","#{ZYXT_120528_199}","#{ZYXT_120528_199}","#{ZYXT_120528_201}","#{ZYXT_120528_202}","#{ZYXT_120528_202}",}
			local szEquip={"#{ZYXT_120528_198}","#{ZYXT_120528_199}","#{ZYXT_120528_199}","#{ZYXT_120528_201}","#{ZYXT_120528_202}","#{ZYXT_120528_202}",
			"#{ZYXT_120528_192}","#{ZYXT_120528_193}","#{ZYXT_120528_194}","#{ZYXT_120528_195}","#{ZYXT_120528_196}","#{ZYXT_120528_197}",}
			local szShow=ScriptGlobal_Format( "#{ZYXT_120528_30}", szEquip[i+startIndex])
			TargetZhenYuan_TextInfo[i]:SetText( szShow )--角色装备位没有穿上装备
		elseif ActionEquip[i]:GetRemainRepairCount()<=0 then
			TargetZhenYuan_TextInfo[i]:SetText( "#{ZYXT_120528_173}" )--#cff0000装备修理次数为0
		elseif ActionEquip[i]:GetEquipDur() <= 0 then --装备耐久为0
			TargetZhenYuan_TextInfo[i]:SetText( "#{ZYXT_120528_32}" )--装备耐久为0，增强无效
		elseif ActionEquip[i]:IsLevelEnoughEquip_Target() <= 0 then
			TargetZhenYuan_TextInfo[i]:SetText( "#{ZYXT_120528_229}" )--资格不够
		else --显示tips
			local szName, nLevel, szAdd, nAdd=Pneuma:GetTargetPneumaAddingInfo(i+startIndex-1)
	--		PushDebugMessage("szAdd="..szAdd.." nAdd="..nAdd)
			local szShowText=szName.."#r#W等级："..nLevel.."#r"
			if szAdd~="" and nAdd>0 then
				szShowText=szShowText..szAdd.." +"..nAdd
			elseif szAdd~="" then
				szShowText=szShowText..ScriptGlobal_Format( "#{ZYXT_120528_33}", szAdd)
				--szShowText=szShowText.."装备无"..szAdd
			end
			TargetZhenYuan_TextInfo[i]:SetText(szShowText)--真元属性描述:待策划字典、数值补充之后补齐
		end
	end

	--更新真元盘
	TargetZhenYuan_UpdatePneumaSet()
end


function TargetZhenYuan_UpdatePneumaSet()
	local minlvl, minqua = TargetZhenYuan_GetMinLvlQualityInLabel()
	TargetZhenYuan_Blue:Hide()
	TargetZhenYuan_Purple:Hide()
	TargetZhenYuan_Orange:Hide()
	TargetZhenYuan_Lock:Hide()
	if(minqua == 3) then
		TargetZhenYuan_Blue:Show()
	elseif (minqua== 4) then
		TargetZhenYuan_Purple:Show()
	elseif(minqua == 5) then
		TargetZhenYuan_Orange:Show()
	else
		TargetZhenYuan_Lock:Show()
	end
end

function TargetZhenYuan_GetMinLvlQualityInLabel()
	local minlvl = 9
	local minqua = 5
	--判断是否已激活插槽、是否装备真元
	for idx=1, ZhenYuanTargetPageSize do
		local theAction,bLocked = Pneuma:EnumPneumaItem("targetpneuma", idx+ZhenYuanTargetPageSize*ZhenYuanTarget_TabIndex-1)
		if((Pneuma:GetTargetMFAct(idx+ZhenYuanTargetPageSize*ZhenYuanTarget_TabIndex-1)==0) or (theAction:GetID()==0)) then
			minlvl=0
			minqua=0
			break
		end
		--获取目标真元属性
		local curLevel = Pneuma:GetTargetPneumaItemProperty(idx+ZhenYuanTargetPageSize*ZhenYuanTarget_TabIndex-1,4)
		local curQua = Pneuma:GetTargetPneumaItemProperty(idx+ZhenYuanTargetPageSize*ZhenYuanTarget_TabIndex-1,2)
		if( curLevel < minlvl) then
			minlvl = curLevel
		end
		if(curQua < minqua) then
			minqua = curQua
		end
	end
	return minlvl, minqua
end

function TargetZhenYuan_Set_MouseEnter(idx)
	local minlvl, minqua = TargetZhenYuan_GetMinLvlQualityInLabel()
	--真圆盘坐标和大小
	local SetX= TargetZhenYuan_Orange:GetProperty("AbsoluteXPosition") + TargetZhenYuan_Frame:GetProperty("AbsoluteXPosition")+TargetZhenYuan_List:GetProperty("AbsoluteXPosition")+TargetZhenYuan_MainFrame:GetProperty("AbsoluteXPosition")
	local SetY = TargetZhenYuan_Orange:GetProperty("AbsoluteYPosition")  + TargetZhenYuan_Frame:GetProperty("AbsoluteYPosition")+TargetZhenYuan_List:GetProperty("AbsoluteYPosition")+TargetZhenYuan_MainFrame:GetProperty("AbsoluteYPosition")
	local SetWidth = TargetZhenYuan_Orange:GetProperty("AbsoluteWidth")
	local SetHeight = TargetZhenYuan_Orange:GetProperty("AbsoluteHeight")
	PushEvent("ZHENYUAN_SET_MOUSEENTER", minlvl, idx, ZhenYuanTarget_TabIndex, SetX,SetY,SetWidth,SetHeight)
end

function TargetZhenYuan_Set_MouseLeave(idx)
	PushEvent("ZHENYUAN_SET_MOUSELEAVE")
end


--取消或者关闭界面
function TargetZhenYuan_Exit()
	this:Hide()
end

--0,1
function TargetZhenYuan_ChangeTabIndex(nPageClk)
	ZhenYuanTarget_TabIndex = nPageClk
	TargetZhenYuan_Update()
end
--***************************************************************
--装备
function TargetZhenYuan_OtherEquip_Down()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
	TargetZhenYuan_Exit()
end

--资料
function TargetZhenYuan_TargetData_Down()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
	TargetZhenYuan_Exit()
end

--珍兽
function TargetZhenYuan_Pet_Down()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPetFrame("other");
	TargetZhenYuan_Exit()
end

--武魂
function TargetZhenYuan_TargetWuhun_Down()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
	TargetZhenYuan_Exit()
end

--经脉
function TargetZhenYuan_JingMai_Down()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
	TargetZhenYuan_Exit()
end

--神木王鼎
function TargetZhenYuan_TargetShenDing_Down()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	local nLevel = CachedTarget:GetData("LEVEL",1);
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" );
	else
		local bRet = SystemSetup:OpenOtherShenDing();
		if bRet == 1 then
			TargetZhenYuan_Exit()
		end
	end	
	
end

--骑乘
function TargetZhenYuan_Ride_Down()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
	TargetZhenYuan_Exit()
end

function TargetZhenYuan_TargetMiji_Down()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	TargetZhenYuan_Exit()
end

function TargetZhenYuan_TargetInfant_Down()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetZhenYuan_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetZhenYuan_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
	TargetZhenYuan_Exit()
end

function TargetZhenYuan_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetZhenYuan_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetZhenYuan_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetZhenYuan_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetZhenYuan_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end


function TargetZhenYuan_ShowPage()

	for i = 1, table.getn(g_TargetZhenYuan_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetZhenYuan_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetZhenYuan_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetZhenYuan_Page) do
		if TargetZhenYuan_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetZhenYuan_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetZhenYuan_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetZhenYuan_OtherEquip_Down();
	elseif idx == 2 then--资料
		TargetZhenYuan_TargetData_Down()
	elseif idx == 3 then--珍兽
		TargetZhenYuan_Pet_Down()
	elseif idx == 4 then--子女
		TargetZhenYuan_TargetInfant_Down()
	elseif idx == 5 then--武魂
		TargetZhenYuan_TargetWuhun_Down()
	elseif idx == 6 then--秘籍
		TargetZhenYuan_TargetMiji_Down()
	elseif idx == 7 then--真元
		--Target_CangPin_ShuXing_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		TargetZhenYuan_JingMai_Down()
	elseif idx == 9 then--神鼎
		TargetZhenYuan_TargetShenDing_Down()
	elseif idx == 10 then--侠印
		TargetZhenYuan_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetZhenYuan_OpenBaoJian()
	elseif idx == 12 then--武意
		TargetZhenYuan_OpenWuYi()
	elseif idx == 13 then--神器
		TargetZhenYuan_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetZhenYuan_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetZhenYuan_CangPin_Page_Switch()
	end
end

function TargetZhenYuan_CheckPage(idx)
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
	elseif idx == 6 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 7 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 8 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 9 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	end
	return 0
end

function TargetZhenYuan_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


