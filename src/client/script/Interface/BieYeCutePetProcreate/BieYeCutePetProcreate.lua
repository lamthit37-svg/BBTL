local g_BieYeCutePetProcreate_Frame_UnifiedPosition;
local bIsSelfLock = 0
local bIsOtherLock = 0
local bIsConfirm = 0
local objCared = -1
local MAX_OBJ_DISTANCE = 15.0;
local g_ItemPosMySelf = -1;
local g_ItemIDOther  = -1;
function BieYeCutePetProcreate_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("BIEYE_PETPROCREATE_MYSELF");
	this:RegisterEvent("BIEYE_PETPROCREATE_OTHER");
	this:RegisterEvent("BIEYE_PETPROCREATE_OTHER_LOCK");
	this:RegisterEvent("BIEYE_PETPROCREATE_OTHER_OK");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("BIEYE_PETPROCREATE_KEY_STATE"); 
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化  
end

function BieYeCutePetProcreate_OnLoad()
	g_BieYeCutePetProcreate_Frame_UnifiedPosition = BieYeCutePetProcreate_Frame:GetProperty("UnifiedPosition")
end

function BieYeCutePetProcreate_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 2017082401 ) then
 
		local xx = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(xx);

		if objCared == -1 then
				PushDebugMessage("server传过来的数据有问题。");
				return;
		end
		BeginCareObject_BieYeCutePetProcreate(objCared)
		BieYePetCreateColor : BieYeCutePetProcreate_Clear();
		BieYeCutePetProcreate_OnUICommand();

	elseif  ( event == "BIEYE_PETPROCREATE_MYSELF" ) then
		local BagPos = tonumber(arg0)
		if g_ItemPosMySelf ~= -1 then
			LifeAbility : Lock_Packet_Item( g_ItemPosMySelf, 0 )
			BieYeCutePetProcreate_Item1 : SetActionItem( -1 )
			g_ItemPosMySelf = -1 
		end
		LifeAbility : Lock_Packet_Item( BagPos, 1 )
		g_ItemPosMySelf = BagPos
  	
		local theAction = EnumAction( BagPos, "packageitem" )
		if (theAction : GetID() == 0) then
			return
		end 
		BieYeCutePetProcreate_Item1 : SetActionItem( theAction : GetID() ) 
		BieYeCutePetProcreate_SelfJian:Hide()
		BieYeCutePetProcreate_Self_PetModel : SetFakeObject( "" );
		
		local ModelID = BieYeMengChong:Lua_GetModelIDByMengChongIndex(PlayerPackage : GetItemTableIndex(BagPos)) 
		DataPool:ShowMengChongSelf_SetNPCModel(tonumber(ModelID), 1) 
		BieYeCutePetProcreate_Self_PetModel : SetFakeObject( "ShowMengChongSelf" ); 
		BieYeCutePetProcreate_ViewDesc_Self : Enable();
		BieYeCutePetProcreate_Self_Lock:Enable();
		BieYeCutePetProcreate_Self_Lock:SetCheck(0);
		bIsSelfLock = 0
		bIsConfirm = 0
		BieYeCutePetProcreate_Accept:Enable();
		BieYeCutePetProcreate_Refresh_Confirm();
	elseif  ( event == "BIEYE_PETPROCREATE_OTHER" ) then
		local OtherID = tonumber(arg0)
		if g_ItemIDOther ~= -1 then 
			BieYeCutePetProcreate_Item2 : SetActionItem( -1 )
			g_ItemIDOther = -1 
		end 
		g_ItemIDOther = OtherID
  	local theAction = DataPool:CreateActionItemForShow(g_ItemIDOther, 1) 
		if (theAction : GetID() == 0) then
			return
		end 
		BieYeCutePetProcreate_Item2 : SetActionItem( theAction : GetID() )  
		BieYeCutePetProcreate_OtherJian:Hide()
		BieYeCutePetProcreate_Other_PetModel : SetFakeObject( "" ); 
		local ModelID = BieYeMengChong:Lua_GetModelIDByMengChongIndex(g_ItemIDOther) 
		DataPool:ShowMengChongOther_SetNPCModel(tonumber(ModelID), 1) 
		BieYeCutePetProcreate_Other_PetModel : SetFakeObject( "ShowMengChongOther" ); 
		BieYeCutePetProcreate_Other_Lock : SetCheck(0)
		bIsOtherLock = 0
		BieYeCutePetProcreate_Refresh_Confirm() 
	elseif  ( event == "BIEYE_PETPROCREATE_OTHER_LOCK" ) then
		if tonumber(arg0) == 1 then
			BieYeCutePetProcreate_Other_Lock : SetCheck(1)
			bIsOtherLock = 1
			BieYeCutePetProcreate_Refresh_Confirm()
		else
			BieYeCutePetProcreate_Other_Lock : SetCheck(0)
			bIsOtherLock = 0
			if bIsSelfLock == 1 then
				BieYeCutePetProcreate_Lock_Clicked();
				PushDebugMessage("#{MCFZ_20170905_174}")
			end
			BieYeCutePetProcreate_Refresh_Confirm()
		end
	elseif (event == "ADJEST_UI_POS") then
		BieYeCutePetProcreate_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeCutePetProcreate_On_ResetPos()  
		
	elseif  ( event == "BIEYE_PETPROCREATE_OTHER_OK" ) then
		if tonumber(arg0) == 1 then
			PushDebugMessage("对方确认了繁殖。")
			BieYeCutePetProcreate_Refresh_Confirm_Ok()
		elseif this:IsVisible() then
			PushDebugMessage("繁殖被取消。")
			BieYeCutePetProcreate_Close2(1)
		end
	elseif ( event == "BIEYE_PETPROCREATE_KEY_STATE")then
		BieYeCutePetProcreate_Refresh_BtnOK(tonumber(arg0));
	elseif (event == "OBJECT_CARED_EVENT") then
		if(not this:IsVisible() ) then
			return;
		end

		if(tonumber(arg0) ~= objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			BieYeCutePetProcreate_Close2(1)
		end 
	end

	return
end

function BieYeCutePetProcreate_OnUICommand()  
	BieYeCutePetProcreate_Show();
end

function BieYeCutePetProcreate_Show() 
	this:Show();
	BieYeCutePetProcreate_Accept:Enable();  

	BieYeCutePetProcreate_Other_Lock : SetCheck(0);
	BieYeCutePetProcreate_Other_Lock : Disable();
	BieYeCutePetProcreate_Self_Lock:SetCheck(0);
	BieYeCutePetProcreate_Self_Lock:Disable();

	BieYeCutePetProcreate_ViewDesc_Self:Disable();
	BieYeCutePetProcreate_ViewDesc_Other:Disable();
	bIsSelfLock = 0
	bIsOtherLock = 0
	BieYeCutePetProcreate_Self_PetModel : SetFakeObject( "" )
	BieYeCutePetProcreate_Other_PetModel : SetFakeObject( "" )
	BieYeCutePetProcreate_SelfJian:Hide()
	BieYeCutePetProcreate_OtherJian:Hide()
end

function BieYeCutePetProcreate_Lock_Clicked() 
	--BieYePetCreateColor:LockBieYeCutePetProcreate()
	--if bIsSelfLock == 0 then
	--	bIsSelfLock = 1
	--else
	--	bIsSelfLock = 0
	--end
	--BieYeCutePetProcreate_Self_Lock:SetCheck(bIsSelfLock); 
	--BieYeCutePetProcreate_Refresh_Confirm()
end

function BieYeCutePetProcreate_OK_Clicked(IsOK) 	
	if g_ItemIDOther == -1 and IsOK == 1 then
		PushDebugMessage("#{MCFZ_20170905_188}")
		return
	end
	if g_ItemPosMySelf == -1 and IsOK == 1 then
		PushDebugMessage("#{MCFZ_20170905_187}")
		return
	end
	
	if IsOK == 1 then
		BieYeCutePetProcreate_Accept:Enable();
		bIsConfirm  = IsOK
	else 
	end
 	BieYePetCreateColor:ConfirmBieYeCutePetProcreate(IsOK);
end

function BieYeCutePetProcreate_Close()
	StopCareObject_Carriage(objCared); 
end

--===============================================
-- 右键点击(查看对方的珍兽资料)
--===============================================
function BieYeCutePetProcreate_Other_PetList_RClick()
	if BieYeCutePetProcreate_Other_Pet:GetText() ~= "" then
		--BieYePetCreateAndColor:ViewPetDetailData("other");
	end
end

--===============================================
-- 右键点击(查看自己的珍兽资料)
--===============================================
function BieYeCutePetProcreate_Self_PetList_RClick()
	if BieYeCutePetProcreate_Self_Pet:GetText() ~= "" then
		--Pet:ViewPetDetailData("self");
	end
end

----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function BieYeCutePetProcreate_Self_TurnLeft(start)
	--向左旋转开始
	if(start == 1) then
		BieYeCutePetProcreate_Self_PetModel:RotateBegin(-0.3);
	--向左旋转结束
	else
		BieYeCutePetProcreate_Self_PetModel:RotateEnd();
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function BieYeCutePetProcreate_Self_TurnRight(start)
	--向右旋转开始
	if(start == 1) then
		BieYeCutePetProcreate_Self_PetModel:RotateBegin(0.3);
	--向右旋转结束
	else
		BieYeCutePetProcreate_Self_PetModel:RotateEnd();
	end
end


----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function BieYeCutePetProcreate_Other_TurnLeft(start)
	--向左旋转开始
	if(start == 1) then
		BieYeCutePetProcreate_Other_PetModel:RotateBegin(-0.3);
	--向左旋转结束
	else
		BieYeCutePetProcreate_Other_PetModel:RotateEnd();
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function BieYeCutePetProcreate_Other_TurnRight(start)
	--向右旋转开始
	if(start == 1) then
		BieYeCutePetProcreate_Other_PetModel:RotateBegin(0.3);
	--向右旋转结束
	else
		BieYeCutePetProcreate_Other_PetModel:RotateEnd();
	end
end 

function BieYeCutePetProcreate_Refresh_BtnOK(isEnable)
	if(isEnable > 0) then
		BieYeCutePetProcreate_Accept:Enable()
	else
		BieYeCutePetProcreate_Accept:Enable()
	end
end

function BieYeCutePetProcreate_Refresh_Confirm()
	if g_ItemIDOther ~= -1 and g_ItemPosMySelf ~= -1 then
		BieYeCutePetProcreate_Accept:Enable()
	else
		BieYeCutePetProcreate_Accept:Enable()
	end

end

function BieYeCutePetProcreate_Refresh_Confirm_Ok()
	if bIsConfirm == 1  then
		BieYeCutePetProcreate_Close2(0)
	end
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_BieYeCutePetProcreate(objCaredId)

	g_Object = objCaredId;

	this:CareObject(g_Object, 1, "BieYeCutePetProcreate");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_BieYeCutePetProcreate(objCaredId)
	this:CareObject(objCaredId, 0, "BieYeCutePetProcreate");
	g_Object = -1;

end


function BieYeCutePetProcreate_Frame_OnHide()

	--关掉相关界面
	BieYeCutePetProcreate_Close();
	--发取消消息
	BieYePetCreateColor:ConfirmBieYeCutePetProcreate(0);
	bIsSelfLock 	= 0
	bIsOtherLock 	= 0
	bIsConfirm 		= 0 
	this:Hide()
end

function BieYeCutePetProcreate_Close2(var)
	--设置变量
	BieYePetCreateColor:SetCanFanzhiPet(tonumber(var))
	if g_ItemIDOther ~= -1 then 
			BieYeCutePetProcreate_Item2 : SetActionItem( -1 )
			g_ItemIDOther = -1 
		end 
	if g_ItemPosMySelf ~= -1 then
			LifeAbility : Lock_Packet_Item( g_ItemPosMySelf, 0 )
			BieYeCutePetProcreate_Item1 : SetActionItem( -1 )
			g_ItemPosMySelf = -1 
		end
	BieYeCutePetProcreate_Frame_OnHide();
end

function BieYeCutePetProcreate_Self_Jian()
	if g_ItemPosMySelf ~= -1 then 
		PushEvent("OPEN_MEGNCHONG_SHOW_PETCREATE",PlayerPackage : GetItemTableIndex(g_ItemPosMySelf))
	end
end

function BieYeCutePetProcreate_Other_Jian()
	if g_ItemIDOther ~= -1 then 
		PushEvent("OPEN_MEGNCHONG_SHOW_PETCREATE",g_ItemIDOther)
	end
end

function BieYeCutePetProcreate_On_ResetPos()
	BieYeCutePetProcreate_Frame:SetProperty("UnifiedPosition", g_BieYeCutePetProcreate_Frame_UnifiedPosition)
end