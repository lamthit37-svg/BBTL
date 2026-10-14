--BieYeCutePetProcreateSingle.lua
--家园单人珍兽繁殖界面 
local g_currentChoose = -1
local g_wastemoney 	= 20000
--庄园珍兽1 
local g_ItemPos1 					= -1
--庄园珍兽2 
local g_ItemPos2 					= -1
--庄园道具 
local g_MengChongItemPos  = -1 
local MAX_OBJ_DISTANCE = 3.0
--单人珍兽繁殖材料ID 萌宠小窝
local g_ItemTblID   = 38002108 
local g_BieYeCutePetProcreateSingle_objCared = -1
local g_serverNpcId = -1 
local g_BieYeCutePetProcreateSingle_Frame_UnifiedPosition;  
local g_BieYeCutePetProcreateSingle_YuanbaoPay=1
g_BieYePet_SignleProcreate_Buy = -1
--*************************************************
--
--*************************************************
function BieYeCutePetProcreateSingle_PreLoad()
	-- this : RegisterEvent( "MONEY_CHANGE_EX" , false)
	this : RegisterEvent( "UI_COMMAND" )
	-- this : RegisterEvent( "MONEYJZ_CHANGE_EX" , false) 
	this : RegisterEvent( "OBJECT_CARED_EVENT" )			-- 关心 NPC 的存在和范围 
	this : RegisterEvent( "PACKAGE_ITEM_CHANGED_EX" )  
	this : RegisterEvent( "ADJEST_UI_POS" , false)
	this : RegisterEvent("UPDATE_BIEYE_PETCREATE_MENGCHONG") 
	this : RegisterEvent("UPDATE_BIEYE_PETCREATE_XIAOWO") 
	this : RegisterEvent("VIEW_RESOLUTION_CHANGED", false) 
	this : RegisterEvent("RESUME_ENCHASE_GEM_EX")
	this : RegisterEvent("BUY_ITEM")
	
end

function BieYeCutePetProcreateSingle_OnLoad()
 	g_BieYeCutePetProcreateSingle_Frame_UnifiedPosition=BieYeCutePetProcreateSingle_Frame:GetProperty("UnifiedPosition");
end

--*************************************************
--
--*************************************************
function BieYeCutePetProcreateSingle_OnEvent(event)

	if ( event == "UI_COMMAND" ) then
		BieYeCutePetProcreateSingle_UICommand(arg0)

	-- elseif ( event == "MONEY_CHANGE_EX" )		then
		--BieYeCutePetProcreateSingle_ShowMoney()

	-- elseif ( event == "MONEYJZ_CHANGE_EX")		then
		--BieYeCutePetProcreateSingle_ShowJZ() 
   
	elseif ( event == "OBJECT_CARED_EVENT" )		then
		BieYeCutePetProcreateSingle_CareObj(arg0,arg1,arg2)
	--elseif event == "BUY_ITEM" and this:IsVisible() then
 
	--	--PushDebugMessage("BUY_ITEM")
	--	--PushDebugMessage("g_BieYePet_SignleProcreate_Buy:"..g_BieYePet_SignleProcreate_Buy)
	--	--PushDebugMessage("tonumber(arg1):"..tonumber(arg1))
	--	if g_BieYePet_SignleProcreate_Buy > 0 then
	--		local item = tonumber(arg1)
	--		if item > 0 then
	--			if g_ItemTblID ~= item then 
	--				return 
	--			end
	--			local itemIdx = PlayerPackage:GetBagPosByItemIndex(item)
	--			PushDebugMessage("itemIdx:"..itemIdx)
	--			if itemIdx >= 0 then
	--				g_BieYePet_SignleProcreate_Buy = -1
	--				BieYeCutePetProcreateSingle_Update_XiaoWo( itemIdx ) 
	--			end
	--		end
	--	end	  
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" ) 		then
		if ( arg0 ~= nil and -1 == tonumber(arg0)) 	then
			return
		end
		if tonumber(arg0) == g_ItemPos1    then
			BieYeCutePetProcreateSingle_Resume_Object1()
		end  
		if tonumber(arg0) == g_ItemPos2    then
			BieYeCutePetProcreateSingle_Resume_Object2()
		end 
		if tonumber(arg0) == g_MengChongItemPos    then
			BieYeCutePetProcreateSingle_Resume_Object3()
		end 
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeCutePetProcreateSingle_Frame_On_ResetPos()
	
	elseif (event == "UPDATE_BIEYE_PETCREATE_MENGCHONG" ) then 
		BieYeCutePetProcreateSingle_Update_Pet(tonumber(arg0)) 
	elseif (event == "UPDATE_BIEYE_PETCREATE_XIAOWO" ) then 
		--BieYeCutePetProcreateSingle_Update_XiaoWo(tonumber(arg0))
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeCutePetProcreateSingle_Frame_On_ResetPos() 
	
	elseif event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() then
		if(arg0~=nil and tonumber(arg0) == 187) then
			BieYeCutePetProcreateSingle_Resume_Object1()
		elseif (arg0~=nil and tonumber(arg0) == 188) then
			BieYeCutePetProcreateSingle_Resume_Object2()
		elseif (arg0~=nil and tonumber(arg0) == 189) then
			BieYeCutePetProcreateSingle_Resume_Object3()
		end
		
	end
end

--*************************************************
--单人珍兽繁殖界面接受命令
--*************************************************
function BieYeCutePetProcreateSingle_UICommand(arg0)
	local nOpt = tonumber(arg0)
	if (nOpt == 2017081201) then 
		LifeAbility : Lock_Packet_Item( 0, 0 )
		BieYeCutePetProcreateSingle_Show()
	end
	if (nOpt == 2017091301) then 
		BieYeCutePetProcreateSingle_OnHidden()
	end
end

--*************************************************
--处理玩家确认要做的事情
--*************************************************
function BieYeCutePetProcreateSingle_OK_Clicked() 
	
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{KPWFS_131112_20}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
  --- 角色当前未处于全沉迷或半沉迷状态；
  if IsInFatigueState() <= 0 then
    PushDebugMessage( "#{FCMX_90609_22}" )
		return  
  end
  
	if g_ItemPos1 == -1 or g_ItemPos2 == -1 then 
		PushDebugMessage("#{MCFZ_20170807_35}")
		return
	end
	Clear_XSCRIPT()								
		Set_XSCRIPT_Function_Name( "OnBieYePetProcreateSingle_Register" )
		Set_XSCRIPT_ScriptID( 892493 )
		Set_XSCRIPT_Parameter( 0, g_serverNpcId )
		Set_XSCRIPT_Parameter( 1, g_ItemPos1 )
		Set_XSCRIPT_Parameter( 2, g_ItemPos2 )
		Set_XSCRIPT_Parameter( 3, g_MengChongItemPos ) 
		Set_XSCRIPT_Parameter( 4, g_BieYeCutePetProcreateSingle_YuanbaoPay ) 
		Set_XSCRIPT_ParamCount( 5 )
	Send_XSCRIPT()
end

--*************************************************
--点击X按钮，隐藏窗口。
--*************************************************
function BieYeCutePetProcreateSingle_OnHidden()
	if (this : IsVisible() == false) then
		return
	end

	if (g_serverNpcId ~= -1) then
		this : CareObject(g_serverNpcId, 0, "BieYeCutePetProcreateSingle")
	end

	BieYeCutePetProcreateSingle_Clear() 
	this : Hide()
end

--*************************************************
--点击取消按钮，窗口隐藏函数
--*************************************************
function BieYeCutePetProcreateSingle_Close_Window()
	if (this : IsVisible() == false) then
		return
	end

	if (g_serverNpcId ~= -1) then
		this : CareObject(g_serverNpcId, 0, "BieYeCutePetProcreateSingle")
	end

	BieYeCutePetProcreateSingle_Clear() 
	this : Hide()
end

--*************************************************
--关心NPC
--*************************************************
function BieYeCutePetProcreateSingle_CareObj(careId, op, distance)
	if(nil == careId or nil == op or nil == distance) then
		return;
	end

	if(tonumber(careId) ~= g_serverNpcId) then
		return;
	end

	if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
		BieYeCutePetProcreateSingle_OnHidden()
	end
end

--*************************************************
--打开单人珍兽繁殖界面
--*************************************************
function BieYeCutePetProcreateSingle_Show()
	BieYeCutePetProcreateSingle_Title:SetText("#{MCFZ_20170807_23}") 
	if (this : IsVisible()) then									-- 如果界面开着，则不处理
		return
	end

	--界面的主人
	g_serverNpcId = Get_XParam_INT(0)  
	if (g_serverNpcId == -1) then
		return
	end
	g_BieYeCutePetProcreateSingle_objCared = DataPool : GetNPCIDByServerID(g_serverNpcId);
	this:CareObject(g_BieYeCutePetProcreateSingle_objCared, 1);
	  
	--珍兽显示界面
	BieYeCutePetProcreateSingle_Clear()
	
	BieYeCutePetProcreateSingle_Blank_Queren:SetCheck(g_BieYeCutePetProcreateSingle_YuanbaoPay)
	
	BieYeCutePetProcreateSingle_Jian:Hide()
	this : Show()

	local npcObjId = Get_XParam_INT( 0 )
	BeginCareObject( npcObjId )
	
	local theAction = DataPool:CreateActionItemForShow(g_ItemTblID, 1)
	if theAction:GetID() ~= 0 then
	  	BieYeCutePetProcreateSingle_Object3:SetActionItem(theAction:GetID())
	end
	 
	BieYeCutePetProcreateSingle_CalcCost() 
end  
 
--****************************************************
--计算金钱消耗
--****************************************************
function BieYeCutePetProcreateSingle_CalcCost()
--	BieYeCutePetProcreateSingle_DemandMoney : SetProperty( "MoneyNumber", tostring( g_wastemoney ) )
end


--****************************************************
--装载爱心小窝
--****************************************************
function BieYeCutePetProcreateSingle_Update_XiaoWo( pos_packet ) 
	if (pos_packet == nil) then
		return
	end

	local BagPos = tonumber( pos_packet )

	--是否加锁....
	if (PlayerPackage:IsLock(BagPos) == 1) then
		PushDebugMessage("#{Item_Locked}")
		return
	end

	--更新单人珍兽繁殖材料界面
	local ItemID = PlayerPackage : GetItemTableIndex( BagPos )
	if ( ItemID <= 0) then 
		return
	end

	--查看物品是否是“爱心小窝”
	if ( ItemID ~= g_ItemTblID) then
		PushDebugMessage("#{MCFZ_20170807_34}")
		return
	end

	--珍兽物品位置是否合法
	if (g_MengChongItemPos ~= -1) then
		LifeAbility : Lock_Packet_Item( g_MengChongItemPos, 0 )
	end

	LifeAbility : Lock_Packet_Item( BagPos, 1 )
	g_MengChongItemPos = BagPos
 
	local theAction = EnumAction( BagPos, "packageitem" )
	if (theAction : GetID() == 0) then
		return
	end 
	BieYeCutePetProcreateSingle_Object3 : SetActionItem( theAction : GetID() )
	 
end

--****************************************************
--装载庄园萌宠
--****************************************************
function BieYeCutePetProcreateSingle_Update_Pet( pos_packet ) 
	if (pos_packet == nil) then
		return
	end

	local BagPos = tonumber( pos_packet )

	--是否加锁....
	if (PlayerPackage:IsLock(BagPos) == 1) then
		PushDebugMessage("#{Item_Locked}")
		return
	end
 	 
 	if g_ItemPos1 == -1 then  
		local petType = PlayerPackage : GetItemSubTableIndex(BagPos,2) 
		 
		LifeAbility : Lock_Packet_Item( BagPos, 1 )
		g_ItemPos1 = BagPos
  	
		local theAction = EnumAction( BagPos, "packageitem" )
		if (theAction : GetID() == 0) then
			return
		end 
		BieYeCutePetProcreateSingle_Object1 : SetActionItem( theAction : GetID() ) 
		BieYeCutePetProcreateSingle_Jian:Hide()
 	elseif g_ItemPos2 == -1 then 		
		local petType = PlayerPackage : GetItemSubTableIndex(BagPos,2)  
		
 		LifeAbility : Lock_Packet_Item( BagPos, 1 )
		g_ItemPos2 = BagPos 
		local theAction = EnumAction( BagPos, "packageitem" )
		if (theAction : GetID() == 0) then
			return
		end 
		BieYeCutePetProcreateSingle_Object2 : SetActionItem( theAction : GetID() )
		BieYeCutePetProcreateSingle_Jian:Hide()
 	end
	 
	 
	
end 
--*************************************************
--
--*************************************************
function BieYeCutePetProcreateSingle_Resume_Object1()
	LifeAbility : Lock_Packet_Item( g_ItemPos1, 0 )
	BieYeCutePetProcreateSingle_Object1 : SetActionItem( -1 )
--	BieYeCutePetProcreateSingle_Info1:SetText("#{MCFZ_20170829_115}")
	g_ItemPos1 = -1
	if g_ItemPos1 == -1 and g_ItemPos2 == -1 then
		BieYePetCreateColor:SetBieYeCreatePetType(0)
		BieYeCutePetProcreateSingle_Jian:Hide()
	end
	 
end
--*************************************************
--
--*************************************************
function BieYeCutePetProcreateSingle_Resume_Object2()
	LifeAbility : Lock_Packet_Item( g_ItemPos2, 0 )
	BieYeCutePetProcreateSingle_Object2 : SetActionItem( -1 )
--	BieYeCutePetProcreateSingle_Info2:SetText("#{MCFZ_20170829_115}")
	g_ItemPos2 = -1
	if g_ItemPos1 == -1 and g_ItemPos2 == -1 then
		BieYePetCreateColor:SetBieYeCreatePetType(0)
		BieYeCutePetProcreateSingle_Jian:Hide()
	end
	 
end
--*************************************************
--
--*************************************************
function BieYeCutePetProcreateSingle_Resume_Object3()
	--LifeAbility : Lock_Packet_Item( g_MengChongItemPos, 0 )
	--BieYeCutePetProcreateSingle_Object3 : SetActionItem( -1 )
	--g_MengChongItemPos = -1 
end
--*************************************************
--
--*************************************************
function BieYeCutePetProcreateSingle_Clear()
	BieYeCutePetProcreateSingle_ClearActionItem(); 
end
 

--*************************************************
--清空繁殖物品
--*************************************************
function BieYeCutePetProcreateSingle_ClearActionItem()
	if g_ItemPos1 ~= -1 then
		LifeAbility : Lock_Packet_Item( g_ItemPos1, 0 )
		BieYeCutePetProcreateSingle_Object1 : SetActionItem( -1 )
		g_ItemPos1 = -1
	end
	if g_ItemPos2 ~= -1 then
		LifeAbility : Lock_Packet_Item( g_ItemPos2, 0 )
		BieYeCutePetProcreateSingle_Object2 : SetActionItem( -1 )
		g_ItemPos2 = -1
	end
	if g_MengChongItemPos ~= -1 then
		LifeAbility : Lock_Packet_Item( g_MengChongItemPos, 0 )
		BieYeCutePetProcreateSingle_Object3 : SetActionItem( -1 )
		g_MengChongItemPos = -1
	end
	if g_ItemPos1 == -1 and g_ItemPos1 == -1 then
		BieYePetCreateColor:SetBieYeCreatePetType(0)
	end
	
end

--*************************************************
--清空金钱
--*************************************************
function BieYeCutePetProcreateSingle_ClearMoney()
--	BieYeCutePetProcreateSingle_DemandMoney : SetProperty( "MoneyNumber", 0 )
--	BieYeCutePetProcreateSingle_SelfJiaozi : SetProperty( "MoneyNumber", 0 )
--	BieYeCutePetProcreateSingle_SelfMoney  : SetProperty( "MoneyNumber", 0 )
end
 
--********************************************
--显示自身拥有的金钱
--********************************************
function BieYeCutePetProcreateSingle_ShowMoney()
	--BieYeCutePetProcreateSingle_SelfMoney : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--********************************************
--显示自身拥有的交子
--********************************************
function BieYeCutePetProcreateSingle_ShowJZ()
	--BieYeCutePetProcreateSingle_SelfJiaozi : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
end

function BieYeCutePetProcreateSingle_Frame_On_ResetPos()
  BieYeCutePetProcreateSingle_Frame:SetProperty("UnifiedPosition", g_BieYeCutePetProcreateSingle_Frame_UnifiedPosition);
end
 
 
function BieYeCutePetProcreateSingle_Jian_Click() 
	if g_ItemPos1 ~= -1 then 
		PushEvent("OPEN_MEGNCHONG_SHOW_PETCREATE",PlayerPackage : GetItemTableIndex(g_ItemPos1))
	end
end

function BieYeCutePetProcreateSingle_Confirm_Clicked() 
	g_BieYeCutePetProcreateSingle_YuanbaoPay = BieYeCutePetProcreateSingle_Blank_Queren:GetCheck();
end

