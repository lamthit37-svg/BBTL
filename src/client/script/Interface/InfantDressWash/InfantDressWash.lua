local MAX_OBJ_DISTANCE = 3.0
local DRESS_POS = -1
local g_NeedMoney = 50000
local g_ObjCared = -1

local g_InfantDressWash_Frame_UnifiedPosition;

local InfantDressWash_CameraHeight = 1		--摄影机高度
local InfantDressWash_CameraDistance = 2		--摄影机距离
local InfantDressWash_CameraPitch = 3		--摄影机角度

local InfantDressWash_CaredObjId = -1		--关注ncp的ObjId
local InfantDressWash_TryItemIdx = -1		--选中的背包索引
local InfantDressWash_PaintDressConfirm = 0	--染色时装剪裁的确认标志

--PreLoad
function InfantDressWash_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_INFANT_DRESS_WASH") --
	--this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false) --让镶嵌UI中的宝石还原
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("OPEN_STALL_SALE")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OPEN_INFANTDRESSWASH_FENYE3")
	
end

--OnLoad
function InfantDressWash_OnLoad()

	g_InfantDressWash_Frame_UnifiedPosition=InfantDressWash_Frame:GetProperty("UnifiedPosition");
end

--OnEvent
function InfantDressWash_OnEvent(event)
	if event == "UI_COMMAND" then
	 	if arg0 ~= nil and tonumber(arg0) == 20141111 then
			if this:IsVisible() then
				this:Hide()
			end
			InfantDressWash_OK:Disable()
			
			this:Show()
			local xx = Get_XParam_INT(0);
			local objCared = DataPool:GetNPCIDByServerID(xx);
			if objCared == -1 then
				return;
			end
			InfantDressWash_BeginCareObject(objCared)
		
			InfantDressWash_DemandMoney:SetProperty("MoneyNumber", g_NeedMoney)
			local playerMoney = Player:GetData("MONEY")
			InfantDressWash_SelfMoney:SetProperty("MoneyNumber", playerMoney)
			local playerJZ = Player:GetData("MONEY_JZ")
			InfantDressWash_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
		
			InfantDressWash_UpdateInfantModel()
		--elseif arg0 ~= nil and tonumber(arg0) == 910283 then
			--if this:IsVisible() then
				--InfantDressWash_Clear()
			--end			
		end			
	    if arg0 ~= nil and tonumber(arg0) == 1411189 then
			InfantDressWash_Clear()
		end
	elseif event == "OPEN_INFANTDRESSWASH_FENYE3" then
		
		local objCared = tonumber(arg0);
		if this:IsVisible() then
			this:Hide()
		end
		InfantDressWash_OK:Disable()
		
		g_InfantDressWash_Frame_UnifiedPosition = Variable:GetVariable("DressClothPos")
		InfantDressWash_Frame:SetProperty("UnifiedPosition", g_InfantDressWash_Frame_UnifiedPosition);
		
		this:Show()
		if objCared == -1 then
			return;
		end
		InfantDressWash_BeginCareObject(objCared)
		InfantDressWash_DemandMoney:SetProperty("MoneyNumber", g_NeedMoney)
		local playerMoney = Player:GetData("MONEY")
		InfantDressWash_SelfMoney:SetProperty("MoneyNumber", playerMoney)
		local playerJZ = Player:GetData("MONEY_JZ")
		InfantDressWash_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)
	
		InfantDressWash_FenYe1:SetProperty("Selected", "False")
		InfantDressWash_FenYe2:SetProperty("Selected", "False")
		InfantDressWash_FenYe3:SetProperty("Selected", "True")
		
		InfantDressWash_UpdateInfantModel()
	elseif event ==	"UPDATE_INFANT_DRESS_WASH" then
		if arg0 ~= nil then
			InfantDressWash_Update(tonumber(arg0))
		end
	elseif event == "OBJECT_CARED_EVENT" then
		if(arg0 ~= nil and tonumber(arg0) ~= objCared) then
			return;
		end		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then		
			--取消关心
			this:Hide()
		end	
			
	--elseif event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() then		
		--if(arg0~=nil and tonumber(arg0) == 100) then
			--InfantDressWash_Resume_Equip()
		--end
	elseif event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() then
		if this:IsVisible() and DRESS_POS == tonumber(arg0) then
			InfantDressWash_Update(tonumber(arg0))
		end
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		InfantDressWash_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		InfantDressWash_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

	elseif (event == "OPEN_STALL_SALE" and this:IsVisible()) then
		--和摆摊界面互斥
		this:Hide()
		
	elseif (event == "ADJEST_UI_POS" ) then
		InfantDressWash_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		InfantDressWash_Frame_On_ResetPos()

	end
end

function InfantDressWash_Update(Pos)
	--InfantDressWash_Clear()
	local theAction = EnumAction(Pos, "packageitem")
	if theAction:GetID() ~= 0 then
		--物品是否已加锁
		if PlayerPackage:IsLock(Pos) == 1 then
			PushDebugMessage("#{ZNRSHY_141101_11}")
			--InfantDressWash_Clear()
			return
		end
			
		local bRet,nVisual,nRare,Style = Infant:GetInfantDressRareByItem(Pos)
		--物品是否是子女时装
		if bRet == 0 then
			PushDebugMessage("#{ZNRSHY_141101_12}")
			return
		end	
		----不是已染色（可还原）时装 (不能在这里加，因为还原成功后会发2遍PACKAGE_ITEM_CHANGED，所以还会走到这里，底层机制决定的)
		--if nVisual <= 0 then
			--PushDebugMessage("该物品没染过色")
			--return
		--end

		InfantDressWash_Clear()
			
		DRESS_POS = Pos;
		
		--if Pos ~= DRESS_POS then
		--	DRESS_POS = Pos
		--end
		
		LifeAbility:Lock_Packet_Item(DRESS_POS, 1)	
		InfantDressWash_Object:SetActionItem(theAction:GetID())
		
		--启用确定按钮
		InfantDressWash_OK:Enable()	
		--更新模型
		InfantDressWash_UpdateInfantModel()
		return
	end

end

function InfantDressWash_UpdateInfantModel()
	InfantDressWash_FakeObject:SetFakeObject( "" )
	InfantDressWash_ColorText:SetText( "" )
	if DRESS_POS == -1 then
		InfantDressWash_Jian : Hide()
		return
	end
	if not this:IsVisible() then
		InfantDressWash_Jian : Hide()
		return
	end
	
	Infant:SetSpecialObjProperty(1,"CopyFrom","0")
	Infant:SetSpecialObjProperty(1,"Dir","0.0")
	--强制成年模式
	local s = Infant:GetInfantSex(0)
	if s == 0 then
		Infant:SetSpecialObjProperty(1,"RaceId","16542")
	else
		Infant:SetSpecialObjProperty(1,"RaceId","16543")
	end
	
	local bRet,nVisual,nRare,szDesc = Infant:GetInfantDressVisualByItem(DRESS_POS)
	if bRet == 1 then
		Infant:SetSpecialObjProperty( 1, "BodyVisual", tostring(nVisual) )
	end
	
	if DRESS_POS ~= -1 then
		InfantDressWash_Jian : Hide()
		InfantDressWash_Jian : Show()
		InfantDressWash_FakeObject:SetFakeObject( "Special_Infant_1" )
	end
	
	FakeObj_SetCamera( "Special_Infant_1", InfantDressWash_CameraHeight, 0.7 )
	FakeObj_SetCamera( "Special_Infant_1", InfantDressWash_CameraDistance, 4 )
	
	FakeObj_RestoreCamera( "Special_Infant_1" )
end

-- function InfantDressWash_UIClear()
-- 	if InfantDressWash_TryItemIdx and InfantDressWash_TryItemIdx ~= -1 then
-- 		LifeAbility:Lock_Packet_Item(InfantDressWash_TryItemIdx, 0)
--   	end
-- 	InfantDressWash_TryItemIdx = -1
-- 	InfantDressWash_Item:SetActionItem(-1)
-- end

function InfantDressWash_Model_TurnLeft_Handler(start)
	if ( start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" ) then
		InfantDressWash_FakeObject:RotateBegin(-0.3)
	else
		InfantDressWash_FakeObject:RotateEnd()
	end
end

function InfantDressWash_Model_TurnRight_Handler(start)
	if ( start == 1 and CEArg:GetValue("MouseButton") == "LeftButton" ) then
		InfantDressWash_FakeObject:RotateBegin(0.3)
	else
		InfantDressWash_FakeObject:RotateEnd()
	end
end

function InfantDressWash_OnJian()
	if not DRESS_POS or DRESS_POS == -1 then
		return
	end
	
	local itemTableIndex = PlayerPackage:GetItemTableIndex(DRESS_POS)
	
	PushEvent( "OPEN_INFANT_DRESS_JIAN", itemTableIndex )
end

function InfantDressWash_Resume_Equip()	
	InfantDressWash_Clear()	
	InfantDressWash_UpdateInfantModel()
end

function InfantDressWash_Clear()
	if(DRESS_POS ~= -1) then
		--禁用确定按钮
		InfantDressWash_OK:Disable()
		InfantDressWash_Object:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(DRESS_POS, 0)
		DRESS_POS = -1
	end
end

function InfantDressWash_OnHiden()
	InfantDressWash_StopCareObject(objCared)
	InfantDressWash_Clear()
	InfantDressWash_FakeObject:SetFakeObject("")
	if IsWindowShow("InfantDressJian") then
		CloseWindow("InfantDressJian", true)
	end 
	return
end

function InfantDressWash_OK_Clicked()
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	--金钱是否足够
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < g_NeedMoney then
		PushDebugMessage("#{RXZS_090804_11}")
		return
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnInfantDressWash")
	Set_XSCRIPT_ScriptID(890985)
	Set_XSCRIPT_Parameter(0, DRESS_POS)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


function InfantDressWash_BeginCareObject(objCaredId)
	g_ObjCared = objCaredId
	this:CareObject(g_ObjCared, 1, "InfantDressWash")
end


function InfantDressWash_StopCareObject(objCaredId)
	this:CareObject(g_ObjCared, 0, "InfantDressWash")
	g_ObjCared = -1
end

function InfantDressWash_Frame_On_ResetPos()
  InfantDressWash_Frame:SetProperty("UnifiedPosition", g_InfantDressWash_Frame_UnifiedPosition);
end

function InfantDressWash_FenYe1_Clicked()
	--PushDebugMessage("InfantDressWash_FenYe1_Clicked"..g_ObjCared)
	Variable:SetVariable("DressClothPos", InfantDressWash_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("OPEN_INFANTDRESSWASH_FENYE1", g_ObjCared);
end

function InfantDressWash_FenYe2_Clicked()
	--PushDebugMessage("InfantDressWash_FenYe2_Clicked"..g_ObjCared)
	Variable:SetVariable("DressClothPos", InfantDressWash_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("OPEN_INFANTDRESSWASH_FENYE2", g_ObjCared);
end
