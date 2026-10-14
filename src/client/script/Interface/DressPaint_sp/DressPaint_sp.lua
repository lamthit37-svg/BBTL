
local MAX_OBJ_DISTANCE = 3.0
local DRESS_POS = -1
local DRESSITEM_POS = -1
local g_ObjCared = -1

local g_NeedMoney = 50000
local g_DressPaint_sp_Frame_UnifiedPosition;
g_DressPaint_sp_TipsBind = 0
local g_DressPaint_sp_YuanbaoPay = 1

--PreLoad
function DressPaint_sp_PreLoad()
	this:RegisterEvent("OPEN_SPECIALDRESSPAINT")
	this:RegisterEvent("UPDATE_SPECIAL_DRESS_PAINT",false)
	
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("PROGRESSBAR_SHOW")
	this:RegisterEvent("OPEN_STALL_SALE");
	this:RegisterEvent("SEX_CHANGED");
	
	this:RegisterEvent("UI_COMMAND");
	
	this:RegisterEvent("OPEN_EQUIP");
	this:RegisterEvent("YIGUI_OPEN")
	this:RegisterEvent("FASHION_DEPOT_OP", false);				-- 华裳�?
	this:RegisterEvent("FEIYUSHOW_WINDOW", false);				-- 飞鱼
end

--OnLoad
function DressPaint_sp_OnLoad() 
	g_DressPaint_sp_Frame_UnifiedPosition=DressPaint_sp_Frame:GetProperty("UnifiedPosition");
end

--OnEvent
function DressPaint_sp_OnEvent(event) 

	-- 读进度条�?，不能进行染�?
	if ( event == "PROGRESSBAR_SHOW" ) then
		if (this:IsVisible()) then
			DressPaint_sp_OnHiden();
			return
		end
	end

	-- 开始摆摊，不能进�?�染�?
	if ( event == "OPEN_STALL_SALE" ) then
		if (this:IsVisible()) then
			DressPaint_sp_OnHiden();
			return
		end
	end

	if event ==	"OPEN_SPECIALDRESSPAINT" then
	
		if arg0 ~= nil and tonumber(arg0) == -1 then
			DressPaint_sp_OnHiden();
			return
		end
		
		PushEvent( "CLOSE_DRESSPREVIEW") 
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")
		DressPaint_sp_Init()
		
		this:Show()
		
		local targetId = tonumber(arg0);
		if targetId ~= nil and targetId ~= -1 then
			local objCared = DataPool:GetNPCIDByServerID(targetId);
			if objCared == -1 then
				return;
			end
			BeginCareObject_DressPaint_sp(objCared)
		end
		
		return
	end
	
	if event ==	"UPDATE_SPECIAL_DRESS_PAINT" then
		if arg0 ~= nil and arg1 ~= nil then
			DressPaint_sp_Update(tonumber(arg0), tonumber(arg1))
		end
		return
	end
	
	if event == "OBJECT_CARED_EVENT" then
		if(arg0 ~= nil and tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者�??删除，自动关�?
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			DressPaint_sp_OnHiden();
		end
		return
	end
	
	if (event == "ADJEST_UI_POS" ) or (event == "VIEW_RESOLUTION_CHANGED") then
		DressPaint_sp_Frame_On_ResetPos()
		return
	end
	
	-- 变�?
	if event == "SEX_CHANGED" and  this:IsVisible() then
		DressPaint_sp_Fitting_FakeObject : Hide();
		DressPaint_sp_Text : Hide()
		Dress_Jian_sp : Hide()
		
		DressPaint_sp_Fitting_FakeObject : Show();
		DressPaint_sp_Text : Show()
		Dress_Jian_sp : Show()
		DressPaint_sp_Fitting_FakeObject:AttachWindowEx("PlayerDressPaint_sp")
		return
	end	
	
	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		DressPaint_sp_OnHiden();
		return
	end
	
	if (event == "UI_COMMAND" and tonumber(arg0) == 20120406) or-- 不能和变性同时存�?
			( event == "OPEN_EQUIP" ) or -- 试衣的时候不能打开角色资料窗口
			( event == "YIGUI_OPEN" ) or -- 试衣的时候不能打开衣柜
			(event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1) or --华裳�? 
			(event == "FEIYUSHOW_WINDOW" and tonumber(arg0) >= 0) or
			( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
			( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then
		if (this:IsVisible()) then 
			DressPaint_sp_OnHiden();
			return
		end
	end
	
	if event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() then
		if(arg0~=nil and tonumber(arg0) == 96) then
			DressPaint_sp_Resume_Equip()
		end

	--elseif event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() then
	--	if( arg0~= nil and -1 == tonumber(arg0)) then
	--		return
	--	end

	--	if (DRESS_POS == tonumber(arg0)) then
	--		DressPaint_sp_Update(tonumber(arg0), 1)
	--	end

	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		--DressPaint_sp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		--DressPaint_sp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	end
end

function DressPaint_sp_Update(Pos, isEquip)

	if isEquip == 1 then
		local theAction = EnumAction(Pos, "packageitem")
		if theAction:GetID() ~= 0 then
			
			--判断�?不是�?染色时�??
			local canPaint = DressReplaceColor : SpecialDressCanPaint(Pos)
			if canPaint == -2 or canPaint == -3 then
				PushDebugMessage("#{TSRS_210316_17}")
				return
			end
			
			if canPaint == -4 then
				PushDebugMessage("#{TSRS_210316_18}")
				return
			end
			
			if canPaint ~= 1 then
				PushDebugMessage("#{TSRS_210316_16}")
				return
			end

			if PlayerPackage:IsLock(Pos) == 1 then
				PushDebugMessage("#{TSRS_210316_19}")
				return
			end		
			
			DressPaint_sp_DressClear()
			DressPaint_sp_ItemClear()
			
			DRESS_POS = Pos
			
			--锁背包道�?
			LifeAbility:Lock_Packet_Item(DRESS_POS, 1)
			DressPaint_sp_Object:SetActionItem(theAction:GetID())
			
			-- 显示图鉴按钮
			Dress_Jian_sp : Show();		
			DressPaint_sp_Fitting_FakeObject : Show()
						
			DressPaint_sp_Show();
			
			if(IsWindowShow("DressJian_sp") == true) then
				Dress_Jian_sp_Clicked();
			end
			
			g_DressPaint_sp_TipsBind = 0
			return

		else
			PushDebugMessage("#{TSRS_210316_27}")
			return
		end
	else
		if DRESS_POS == -1 then
			PushDebugMessage("#{TSRS_210316_21}")
			return
		else
			local theAction = EnumAction(Pos, "packageitem")
			if theAction:GetID() ~= 0 then
				local IsItem, CostNum = DressReplaceColor : SpecialDressItem(DRESS_POS, Pos)
				if IsItem ~= 1 then
					PushDebugMessage("#{TSRS_210316_22}")
					return
				end

				if PlayerPackage:IsLock(Pos) == 1 then
					PushDebugMessage("#{TSRS_210316_23}")
					return
				end	

				DressPaint_sp_ItemClear()
				DRESSITEM_POS = Pos
				
				DressPaint_sp_Show();
			
				--�?用确定按�?
				DressPaint_sp_OK:Enable(); 
				
				LifeAbility:Lock_Packet_Item(DRESSITEM_POS, 1)
				DressPaint_sp_Object1:SetActionItem(theAction:GetID())
								
				DressPaint_sp_DemandPaintItemNumber:SetProperty("Text", CostNum)
				DressPaint_sp_DemandMoney:SetProperty("MoneyNumber", g_NeedMoney)
			else
				PushDebugMessage("#{TSRS_210316_20}")
				return
			end
		end
	end

end

function DressPaint_sp_Resume_Item() 

	DressPaint_sp_ItemClear()
	
	DressPaint_sp_Show()
	
end

function DressPaint_sp_Resume_Equip() 

	DressPaint_sp_DressClear()
	DressPaint_sp_ItemClear()
	
	DressPaint_sp_Show()
	
	if(IsWindowShow("DressJian_sp") == true) then
		PushEvent("CLOSE_DRESSJIAN_SP_DLG")		
	end
	
end

function DressPaint_sp_DressClear()

	if(DRESS_POS ~= -1) then
		DressPaint_sp_Object:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(DRESS_POS, 0)
		DRESS_POS = -1
	end
	
	DressPaint_sp_Fitting_FakeObject:Hide()
	DressPaint_sp_OK:Disable(); 
	Dress_Jian_sp:Hide() 
	
	DressReplaceColor:RestoreSpecialDressPaint()
	
end

function DressPaint_sp_ItemClear()

	if(DRESSITEM_POS ~= -1) then
		DressPaint_sp_Object1:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(DRESSITEM_POS, 0)
		DRESSITEM_POS = -1
	end
	
	DressPaint_sp_DemandPaintItemNumber:SetProperty("Text", 0)
	DressPaint_sp_DemandMoney:SetProperty("MoneyNumber", 0)
	DressPaint_sp_OK:Disable(); 
	
end

function DressPaint_sp_Init()

	SetDefaultMouse();
	
	DressPaint_sp_DressClear()
	DressPaint_sp_ItemClear()
		
	g_DressPaint_sp_TipsBind = 0
	
	DressPaint_sp_Show()
	
	DressPaint_sp_DemandPaintItemNumber:SetProperty("Text", 0)
	DressPaint_sp_DemandMoney:SetProperty("MoneyNumber", 0)
	
end

function DressPaint_sp_Show()
	-- 先清空当前试衣间的数�?
	DressReplaceColor:RestoreSpecialDressPaint()
	
	DressPaint_sp_Fitting_FakeObject:DetachWindowEx()
	DressPaint_sp_Fitting_FakeObject:AttachWindowEx("PlayerDressPaint_sp")
	SetFakeObjDataEx("PlayerDressPaint_sp")
	
	DressReplaceColor : FittingOnSpecialDress(DRESS_POS, DRESSITEM_POS)
	
	if DRESS_POS == -1 then
		DressPaint_sp_Text:Hide()
	else
		DressPaint_sp_Text:Show()
		local nVisual, nDes, MaterId, MaterBind, nVisualNew, nDesNew, ComPropCost = DressReplaceColor : GetSpecialDressInfo(DRESS_POS, DRESSITEM_POS)
		if nVisualNew ~= nil and nVisualNew > 0 then
			DressPaint_sp_Text:SetText( "#cbe38ff"..nDesNew )
		elseif nVisual > 0 then
			DressPaint_sp_Text:SetText( "#G"..nDes )		
		else
			DressPaint_sp_Text:Hide()
		end
	end
end

function DressPaint_sp_OnHiden() 

	SetDefaultMouse();
	
	StopCareObject_DressPaint_sp(g_ObjCared)
	
	DressPaint_sp_DressClear()
	DressPaint_sp_ItemClear()
	
	Dress_Jian_sp : Hide() 
	this : Hide() 
	
	DressPaint_sp_Fitting_FakeObject:DetachWindowEx()	
	
	if(IsWindowShow("DressJian_sp") == true) then
		PushEvent( "CLOSE_DRESSJIAN_SP_DLG")		
	end
	
	return
end

------------------------------------------------------
--
--	纭?瀹?
--
function DressPaint_sp_OK_Clicked() 

	-- 判断�?否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	--判断电话密保和二级密码保�?2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	
	--- 角色当前�?处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90609_22}" )
		return  
	end
	
	if DRESS_POS==-1 then
		PushDebugMessage( "#{TSRS_210316_27}" )
		return
	end
	
	if DRESSITEM_POS==-1 then
		PushDebugMessage( "#{TSRS_210316_20}" )
		return
	end

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < g_NeedMoney then
		PushDebugMessage("#{TSRS_210316_28}")
		return
	end
	
	local isDressBind = GetItemBindStatus(DRESS_POS)	
	local isItemBind = GetItemBindStatus(DRESSITEM_POS)
	local nVisual, nDes, MaterId, MaterBind, nVisualNew, nDesNew, ComPropCost = DressReplaceColor : GetSpecialDressInfo(DRESS_POS, DRESSITEM_POS)
	
	local nMyComPropNum = PlayerPackage:CountAvailableItemByIDTable(MaterId) 
	local nMyComPropBindNum = PlayerPackage:CountAvailableItemByIDTable(MaterBind) 

	if ComPropCost > 0 and nMyComPropNum + nMyComPropBindNum < ComPropCost then
		PushDebugMessage( "#{TSRS_210316_32}" )
		return
	end
	
	if g_DressPaint_sp_TipsBind == 0 and isDressBind == 0 then
		if isItemBind == 0 then
			if nMyComPropNum < ComPropCost then
				PushEvent( "DRESSPAINT_SP_BINDDRESS", "#{TSRS_210316_40}")
				return
			end
		else
			if nMyComPropNum < ComPropCost then
				PushEvent( "DRESSPAINT_SP_BINDDRESS", "#{TSRS_210316_29}")
				return
			else
				PushEvent( "DRESSPAINT_SP_BINDDRESS", "#{TSRS_210316_39}")
				return
			end
		end
	end
		
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnSpecialDressPaint")
	Set_XSCRIPT_ScriptID(830004)
	Set_XSCRIPT_Parameter(0, DRESS_POS)
	Set_XSCRIPT_Parameter(1, DRESSITEM_POS)
	Set_XSCRIPT_Parameter(2, g_DressPaint_sp_YuanbaoPay)
	Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

------------------------------------------------------
--
--	关心NPC
--
function BeginCareObject_DressPaint_sp(objCaredId)
	g_ObjCared = objCaredId
	this:CareObject(g_ObjCared, 1, "DressPaint_sp")
end

function StopCareObject_DressPaint_sp(objCaredId)
	this:CareObject(g_ObjCared, 0, "DressPaint_sp")
	g_ObjCared = -1
end

function DressPaint_sp_Frame_On_ResetPos()
  DressPaint_sp_Frame:SetProperty("UnifiedPosition", g_DressPaint_sp_Frame_UnifiedPosition);
end

----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向�?)
--
function DressPaint_sp_Fitting_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开�?
		if(start == 1) then
			DressPaint_sp_Fitting_FakeObject:RotateBeginEx("PlayerDressPaint_sp", -0.3)
		--向左旋转结束
		else
			DressPaint_sp_Fitting_FakeObject:RotateEndEx();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向�?)
--
function DressPaint_sp_Fitting_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开�?
		if(start == 1) then
			DressPaint_sp_Fitting_FakeObject:RotateBeginEx("PlayerDressPaint_sp", 0.3);
		--向右旋转结束
		else
			DressPaint_sp_Fitting_FakeObject:RotateEndEx();
		end
	end
end

function Dress_Jian_sp_Clicked()
	DressReplaceColor:OpenSpecialDressJian(DRESS_POS);
end



