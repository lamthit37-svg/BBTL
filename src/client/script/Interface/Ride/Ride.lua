local Current_Ride_Index = -1;
local RIDE_TAB_TEXT = {};
local  g_Ride = {};			--骑乘对象
local  g_EquipMask = {};

-- 界面的默认相对位置
local g_Ride_Frame_UnifiedXPosition;
local g_Ride_Frame_UnifiedYPosition;

local g_LastTimer = -1 --增加点击激活的冷却时间
local MIN_PASS_TIME = 1 --冷却时间1秒
local g_LastShowWhat = 1 --最后次显示的是召唤还是收回 1:召唤 2:收回
local Have_Select_Ride = false -- Modify By YuanPeiLong, 2013/02/01
local Time_Select_Ride = 0 -- Modify By YuanPeiLong, 2013/02/01
local g_ShowFreshMan = 0

function Ride_PreLoad()

	-- 打开界面
	this:RegisterEvent("OPEN_RIDE_PAGE",true);

	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	--玩家更换骑乘
	this:RegisterEvent("PLAYER_UPDATE_RIDE",false);

	this:RegisterEvent("REFRESH_EQUIP",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK",false);		--升级

	this:RegisterEvent("TOGGLE_UPDATE_INFANT",false); --子女有变化 刷新按钮状态

	this:RegisterEvent("FINISH_MISSION",false);
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	
	this:RegisterEvent("SWITCHMENPAI",false)

end

function Ride_OnLoad()

	RIDE_TAB_TEXT = {
		[0] = "装备",
		"资料",
		"珍兽",
		"骑乘",
		"其他",
		"经脉",
	};
	g_Ride[8] = Ride_Equip1;
	g_Ride[19] = Ride_Equip2;
	g_Ride[20] = Ride_Equip3;
	g_Ride[21] = Ride_Equip4;
	g_Ride[22] = Ride_Equip5;
	g_EquipMask[8]	= Ride_Equip_Mask1;
	g_EquipMask[19] = Ride_Equip_Mask2;
	g_EquipMask[20] = Ride_Equip_Mask3;
	g_EquipMask[21] = Ride_Equip_Mask4;
	g_EquipMask[22] = Ride_Equip_Mask5;

	-- 保存界面的默认相对位置
	g_Ride_Frame_UnifiedXPosition	= Ride_Frame : GetProperty("UnifiedXPosition");
	g_Ride_Frame_UnifiedYPosition	= Ride_Frame : GetProperty("UnifiedYPosition");

end

-- OnEvent
function Ride_OnEvent(event)

	if ( event == "UPDATE_WILLGET_MISSION_TRACK" )  or (event=="TOGGLE_UPDATE_INFANT") or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		 Ride_Refresh_Page_Button(nLevel)
	end
	if ( event == "OPEN_RIDE_PAGE" ) then

		-- if(this:IsVisible()) then

		-- 	this:Hide();
		-- 	return;
		-- end

		-- -- 更新位置
		-- local selfUnionPos = Variable:GetVariable("SelfUnionPos");
		-- if(selfUnionPos ~= nil) then
		-- 	Ride_Frame:SetProperty("UnifiedPosition", selfUnionPos);
		-- end
		-- this:Show();
		-- Ride_OnShow();
		-- local nLevel =Player:GetLevel()
		--  Ride_Refresh_Page_Button(nLevel)

	end

	if( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	end

	if("REFRESH_EQUIP" == event) then
		if(this:IsVisible()) then

			Ride_OnShow();
			return;
		end
	end

	if("PLAYER_UPDATE_RIDE" == event)then
		if(this:IsVisible()) then
			Ride_OnShow();
			local nItemID = DataPool:GetCurrentFreshManGuideItemValue()
			if nItemID > 0 and nItemID == 10 then
				--	显示引导UI，添加后续UI显示
				Ride_ShowFreshManGuide()
				SetTimer("Ride", "Ride_ShowFreshManGuide()", 3000)
			end
		end
	end

	if("REFRESH_EQUIP" == event)then
		if(this:IsVisible()) then
			Ride_Object_Update();
		end
	end

	if ( event == "SWITCHMENPAI" ) then
		Ride_OnShow();
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Ride_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Ride_Frame_On_ResetPos()
	elseif(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		Ride_RefreshWuYiTip()
	end

	return;
end

function Ride_OnShow()
	Ride_Ride : SetCheck(1);
	--local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	--if(selfUnionPos ~= nil) then
	--	Ride_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	--end

--~ 	Ride_List : ClearListBox();
	Ride_FakeObject : SetFakeObject( "" );
	--得到当前激活的骑乘点(默认为装备第8点)
	local nCurActivePoint = DataPool:GetCurActiveRidePoint()
	local nRideIndex = LifeAbility : Get_RideEquip_VisualID_ByActivePoint(nCurActivePoint)
	Player : SetHorseModel(nRideIndex);
	if (nRideIndex ~= -1) then
		Ride_FakeObject : SetFakeObject( "My_Horse" );
	end

	--local nCount = 0
	nRideIndex = -1
	local nTotalRideNum = Player : GetTotalHorseNum();
	if nTotalRideNum == -1 then
		return
	end
	while nRideIndex < nTotalRideNum do
		nRideIndex = nRideIndex + 1;
		StrName = Player : GetMyHorse(nRideIndex);

--~ 		if StrName ~= "-1" then
--~ 			Ride_List : AddItem(StrName, nRideIndex);
--~ 			--nCount = nCount + 1
--~ 		end
	end

	--设置学会了多少种
	--策划又要直接显示成 已学会骑术列表 了
	--local strTipsQS = string.format("已学会骑术:#G%d#W种", nCount)
	--Ride_qishu_text:SetText(strTipsQS)

	Ride_Equip_Update();
--	local nItemID = DataPool:GetCurrentFreshManGuideItemValue()
--	if nItemID > 0 and nItemID == 10141451 then
--		--	显示引导UI，添加后续UI显示
--		Ride_ShowFreshManGuide()
--		SetTimer("Ride", "Ride_ShowFreshManGuide()", 3000)
--	end
end

--~ function Ride_ListBox_Selected()
--~ 	Ride_List : ClearSelectState();
--~ 	if 1 == 0 then
--~ 		Current_Ride_Index = Ride_List : GetFirstSelectItem();

--~ 		if 	Current_Ride_Index ~= -1 then

--~ 			Player:GetMyHorse(Current_Ride_Index);
--~ 			Ride_FakeObject : SetFakeObject( "" );
--~ 			Player : SetHorseModel(Current_Ride_Index);
--~ 			Ride_FakeObject : SetFakeObject( "My_Horse" );
--~ 		end
--~ 	end
--~ end

----------------------------------------------------------------------------------
--
-- 选装玩家模型（向左)
--
function Ride_Modle_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			Ride_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			Ride_FakeObject:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
-- 选装玩家模型（向右)
--
function Ride_Modle_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			Ride_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			Ride_FakeObject:RotateEnd();
		end
	end
end

function Ride_ShowFreshManRideSlot()
	local fX = 0
	local fY = 0
	local nPosX = tonumber(Ride_Frame:GetProperty("AbsoluteXPosition"))
	local nPosY = tonumber(Ride_Frame:GetProperty("AbsoluteYPosition"))
	fX, fY = this:GetChildOffset("Ride_Equip1")
	local fH = tonumber(Ride_Equip1:GetProperty("AbsoluteHeight"))
	local fW = tonumber(Ride_Equip1:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + nPosX + fW))
	fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)))
	DataPool:SetCurrentFreshManGuideItemValue(11)
	OpenFreshManGuideNew(g_ShowFreshMan, fX, fY, fW, fH, 19, 3, "Ride")
end

function Ride_ShowFreshManClose()
	local fX = 0
	local fY = 0
	local nPosX = tonumber(Ride_Frame:GetProperty("AbsoluteXPosition"))
	local nPosY = tonumber(Ride_Frame:GetProperty("AbsoluteYPosition"))
	fX, fY = this:GetChildOffset("Ride_Close")
	local fH = tonumber(Ride_Close:GetProperty("AbsoluteHeight"))
	local fW = tonumber(Ride_Close:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + nPosX + fW))
	fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)))
	OpenFreshManGuideNew(g_ShowFreshMan, fX, fY, fW, fH, 14, 3, "Ride")
	DataPool:SetCurrentFreshManGuideItemValue(12)
end

function Ride_ShowFreshManGuide()
	--KillTimer("Ride_ShowFreshManGuide")
	local nItemID = DataPool:GetCurrentFreshManGuideItemValue()
	if nItemID > 0 and nItemID == 10 then
		g_ShowFreshMan = 1
		Ride_ShowFreshManRideSlot()
	elseif nItemID > 0 and nItemID == 11 then
		KillTimer("Ride_ShowFreshManGuide()")
		g_ShowFreshMan = 1
		Ride_ShowFreshManClose()
	end
end


function Ride_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);

	OpenEquip(1);
	Ride_SelfEquip : SetCheck(0);
	Ride_SelfData : SetCheck(0);
	Ride_Pet : SetCheck(0)
	Ride_Ride : SetCheck(1);
	Ride_OtherInfo : SetCheck(0);
	Ride_JingMai : SetCheck(0);
end

--打开自己的资料页面
function Ride_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
end

function Ride_Pet_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);

	TogglePetPage();
	Ride_SelfEquip : SetCheck(0);
	Ride_SelfData : SetCheck(0);
	Ride_Pet : SetCheck(0);
	Ride_Ride : SetCheck(1);
	Ride_OtherInfo : SetCheck(0);
	Ride_JingMai : SetCheck(0);
end

function Ride_Other_Info_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);

	OtherInfoPage();
	Ride_SelfEquip : SetCheck(0);
	Ride_SelfData : SetCheck(0);
	Ride_Pet : SetCheck(0);
	Ride_Ride : SetCheck(1);
	Ride_OtherInfo : SetCheck(0);
	Ride_JingMai : SetCheck(0);
end

--function AddExtAttr_PassTime()
--   local iCur = Exchange:GetTickCount();
--   local nCantOperEndTime = DataPool:GetCantManualActiveTime()

--	local bCanActive = 1
--	if iCur - nCantOperEndTime < 0 then
--		bCanActive = 0
--	end

--	if g_LastTimer == -1 then
--		g_LastTimer = iCur;
--		if bCanActive == 1 then
--			return 1
--		end
--		return 0
--	end

--   if (iCur - g_LastTimer < MIN_PASS_TIME * 1000) then
--      return 0
--   else
--      g_LastTimer = iCur;
--	  if bCanActive == 1 then
--		return 1
--	  end
--	  return 0
--   end
--end

function AddExtAttr_PassTime()
   local iCur = Exchange:GetTickCount();

	if g_LastTimer == -1 then
		g_LastTimer = iCur;
		return 1
	end

   if (iCur - g_LastTimer < MIN_PASS_TIME * 1000) then
      return 0
   else
      g_LastTimer = iCur;
	  return 1
   end
end

function Ride_Equip_Click( buttonIn )
	local button = tonumber( buttonIn );
	if (g_Ride[buttonIn]) then
		g_Ride[buttonIn]:DoAction();	--骑乘
		--设置激活
		local ActionMount
		if buttonIn == 8 then
			ActionMount = EnumAction(buttonIn, "equip");
		else
			ActionMount = EnumAction(buttonIn - 19, "ridebag");
		end
		if(ActionMount and ActionMount:GetID() ~= 0) then
			--冷却时间
			if AddExtAttr_PassTime() == 0 then
				PushDebugMessage("#{ZQGZ_110512_23}") -- 请不要操作过快
				return
			end

			-- Modify By YuanPeiLong, 2013/02/01
			if ( Exchange:GetTickCount() - Time_Select_Ride < 4000 and  Have_Select_Ride == true) then
				return
			else
				Time_Select_Ride = Exchange:GetTickCount()
				Have_Select_Ride = false
			end
			if (Have_Select_Ride == true)  then
				return
			end
			--end
			if(buttonIn == 8) then
				DataPool:SetCurActiveRidePoint(0)
			else
				DataPool:SetCurActiveRidePoint(buttonIn - 19 + 1)
			end

			--刷新
			Ride_OnShow();
		end
	end
end

function Ride_Equip_RClick(buttonIn)
	local button = tonumber( buttonIn );
	if (g_Ride[buttonIn]) then
		g_Ride[buttonIn]:DoSubAction();  --骑乘
	end
end

--召唤(1)，收回(0)坐骑
function CallInOutRide(buttonIn)
	local nCurPoint = DataPool:GetCurActiveRidePoint()
	local ActionMount
	if nCurPoint == 0 then
		ActionMount = EnumAction(8, "equip");
	else
		ActionMount = EnumAction(nCurPoint - 1, "ridebag")
	end
	local nCurMountID = Player:GetMountID()
	local button = tonumber( buttonIn );
	if button == 1 then --召唤
		if ActionMount and ActionMount:GetID() ~= 0 then --如果有激活
			-- Modify By YuanPeiLong, 2013/02/01
			Have_Select_Ride = true
			Time_Select_Ride = Exchange:GetTickCount()
			-- end
			if ActionMount:GetID() ~= nCurMountID then --激活的要召唤的，不是当前已经骑乘的
				local nSucc = Player:UseSkillInLua_Const()
				if nSucc == 1 then  --如果服务器和client状态不一致，或者

				end
			else
				PushDebugMessage("#{ZQGZ_110512_24}") -- 您已经将当前激活的坐骑召唤出来了
			end
		else
			PushDebugMessage("#{ZQGZ_110512_25}")  --当前没有坐骑被激活
		end

		return
	end

	if button == 0 then --召回
		if nCurMountID == -1 then
			PushDebugMessage("#{ZQGZ_110512_26}")  --当前没有坐骑被召唤出来
			return
		end
		Player:UseSkillInLua_Const()
	end
end

function Ride_Equip_Update()
	--召唤和收回的设置
	local bIsInMount = Player:GetMountID()
	if bIsInMount == -1 then
		Ride_CallRideIn:Hide()
		Ride_CallRideOut:Show()
		g_LastShowWhat = 1
	else
		local nRet = Player:IsPlayerInFittingState()
		if nRet and nRet == 1 then
			--如果处于试穿状态
			if g_LastShowWhat == 1 then
				Ride_CallRideIn:Hide()
				Ride_CallRideOut:Show()
			else
				Ride_CallRideIn:Show()
				Ride_CallRideOut:Hide()
				g_LastShowWhat = 2
			end
		else
			Ride_CallRideIn:Show()
			Ride_CallRideOut:Hide()
			g_LastShowWhat = 2
		end
	end

	--先清，并设置图标
	local bHaveActive = 0
	local FlashActionMount = nil
	local tmpCurPoint = DataPool:GetCurActiveRidePoint()
	for i,item in g_Ride do
		if item then
			if i == 8 then --装备第8点
				FlashActionMount = EnumAction(i, "equip");
			else--骑乘背包中
				FlashActionMount = EnumAction(i - 19, "ridebag")
			end
			if FlashActionMount then
				local MountId = FlashActionMount:GetID()
				if MountId ~= 0 then
					item:SetActionItem(MountId);
				else
					item:SetActionItem(-1);
				end

				if MountId ~= 0 then
					local realActivePoint = -1
					if i == 8 then
						realActivePoint = 0
					else
						realActivePoint = i - 19 + 1;
					end

					if tmpCurPoint == realActivePoint then
						item:SetPushed(1);
						bHaveActive = 1
					end
				end
			end
		end
	end

	--先清，并设置耐久遮罩
	local ActionMount
	for j,maskItem in g_EquipMask do
		if j == 8 then
			ActionMount = EnumAction(j, "equip");
		else
			ActionMount = EnumAction(j - 19, "ridebag")
		end

		local nMenpai = Player:GetData("MEMPAI")
		if( ActionMount:GetEquipDur() < 0.1 or (ActionMount and ActionMount:GetID() ~= 0 and ( ActionMount:CheckMenPaiLimit(nMenpai) ~= 1 or  ActionMount:Lua_CheckRenaWaTime() == 1)  )  )  
		  then----门派相关 延时坐骑相关
			maskItem:Show();
		else
			maskItem:Hide();
		end
	end

	--设置标题栏
	if bHaveActive == 1 then
		local curActivePoint = DataPool:GetCurActiveRidePoint()
		local ActionMount
		if curActivePoint == 0 then
			ActionMount = EnumAction(8, "equip");
		else
			ActionMount = EnumAction(curActivePoint - 1, "ridebag")
		end

		if ActionMount  and ActionMount:GetID() ~= 0 then  --确实有骑乘
			local strname = ActionMount:GetName()
			Ride_DragTitle:SetText("#gFF0FA0" .. strname)
		else
			Ride_DragTitle:SetText("#{INTERFACE_XML_51}")
		end
	else
		Ride_DragTitle:SetText("#{INTERFACE_XML_51}")
	end
end


function Ride_Object_Update()

	Ride_FakeObject : SetFakeObject( "" );
	local nCurActivePoint = DataPool:GetCurActiveRidePoint()
	local ActionMount

	if nCurActivePoint == 0 then
		ActionMount = EnumAction(8, "equip");
	else
		ActionMount = EnumAction(nCurActivePoint - 1, "ridebag")
	end
	if ActionMount == nil or ActionMount:GetID() == 0 then
		return
	end

	local nRideIndex = LifeAbility : Get_UserEquip_VisualID(nCurActivePoint)
	Player : SetHorseModel(nRideIndex);
	if (nRideIndex ~= -1) then
		Ride_FakeObject : SetFakeObject( "My_Horse" );
	else
		Ride_FakeObject : SetFakeObject( "" );
	end
end


--显示武魂UI
function Ride_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
end

function Ride_Xiulian_Switch()
    nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
	else
	    Ride_Xiulian : SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

--神木王鼎
function Ride_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if nRet == 1 then
		Ride_Ride:SetCheck(0)
	else
		Ride_JingMai:SetCheck(0)
	end
end

function Ride_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		Ride_Ride:SetCheck(0)
	else
		Ride_JingMai:SetCheck(0)
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Ride_Frame_On_ResetPos()

	Ride_Frame : SetProperty("UnifiedXPosition", g_Ride_Frame_UnifiedXPosition);
	Ride_Frame : SetProperty("UnifiedYPosition", g_Ride_Frame_UnifiedYPosition);

end

function Ride_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Ride_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Ride_OnMoved()
	if "Ride" == GetFreshManGuideOwner() then
		g_ShowFreshMan = 2
		local nItemID = DataPool:GetCurrentFreshManGuideItemValue()
		if nItemID == 11 then
			Ride_ShowFreshManRideSlot()
		elseif nItemID == 12 then
			Ride_ShowFreshManClose()
		end
	end
end

function Ride_CloseFunction()
	KillTimer("Ride_ShowFreshManGuide()")
	if "Ride" == GetFreshManGuideOwner() then
            CloseFreshManGuide()
        end

	local nItemID = DataPool:GetCurrentFreshManGuideItemValue()
	if nItemID > 10 then
		--NotifyPopUITip("MainMenuBar", 1, 8)
		DataPool:SetCurrentFreshManGuideItemValue(0)
		g_ShowFreshMan = 0
	end
	this:Hide();
end

function Ride_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Ride_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function Ride_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

function Ride_Refresh_Page_Button( nLevel)

	--神鼎
	if ( nLevel < 15 ) then
		Ride_ShenDing:Disable()
		Ride_ShenDing_tips:Show()
	--	Ride_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		Ride_ShenDing:Enable()
		Ride_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		Ride_Infant:Disable()
		Ride_Infant_tips:Show()
	--	Ride_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		Ride_Infant:Enable()
		Ride_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		Ride_Wuhun:Disable()
--		Ride_Wuhun_tips:Show()
	--	Ride_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		Ride_Wuhun:Enable()
		Ride_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		Ride_Xiulian:Disable()
		Ride_Xiulian_tips:Show()
	--	Ride_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		Ride_Xiulian:Enable()
		Ride_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		Ride_Miji:Disable()
		Ride_Miji_tips:Show()
	--	Ride_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		Ride_Miji:Enable()
		Ride_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		Ride_ZhenYuan:Disable()
		Ride_ZhenYuan_tips:Show()
	--	Ride_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		Ride_ZhenYuan:Enable()
		Ride_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		Ride_JueWei:Disable()
		Ride_JueWei_tips:Show()
	--	Ride_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		Ride_JueWei:Enable()
		Ride_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		Ride_JingMai:Disable()
		Ride_JingMai_tips:Show()
	--	Ride_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		Ride_JingMai:Enable()
		Ride_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		Ride_BaoJian:Disable()
		Ride_BaoJian_tips:Show()
	else
		Ride_BaoJian:Enable()
		Ride_BaoJian_tips:Hide()
	end
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		Ride_WuYi:Enable()
		Ride_WuYi_tips:Hide()
	else
		Ride_WuYi:Disable()
		Ride_WuYi_tips:Show()
	end
	Ride_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		Ride_ShenQi:Enable()
		Ride_ShenQi_tips:Hide()
	else
		Ride_ShenQi:Disable()
		Ride_ShenQi_tips:Show()
	end

end

function Ride_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function Ride_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Ride_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Ride_RefreshWuYiTip()
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		Ride_WuYi_Buttontips:Show()
	else
		Ride_WuYi_Buttontips:Hide()
	end
end
