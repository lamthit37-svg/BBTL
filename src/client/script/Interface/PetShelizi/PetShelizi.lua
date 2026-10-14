--  PetShelizi
--  炼制珍兽舍利子

local Guid_Pet_H = -1
local Guid_Pet_L = -1
local Index_Pet = -1
local UITYPE_SHELIZI = 8050191
local UITYPE_SHELIZI_NOTIFY = 8050192
local UITYPE_SHELIZI_CLOSE = 8050193
local CareNpcID = -1
local minLevel=30
local Pet_DBName=""
local slzExp = 0
local needmoney = 0

local applyState = 0  --炼制悟性大于7的珍兽的申请状态 0：未申请， 1：申请中， 2：申请成功， 3：申请过期 

function PetShelizi_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "REPLY_MISSION_PET" )						-- 玩家从列表选定一只珍兽
	-- this : RegisterEvent( "UPDATE_PET_PAGE" )						-- 玩家身上的珍兽数据发生变化，包括增加一只珍兽
	this : RegisterEvent( "DELETE_PET" )							-- 玩家身上减少一只珍兽
	this : RegisterEvent( "OBJECT_CARED_EVENT" )						-- 关心 NPC 的存在和范围
	this : RegisterEvent("MONEY_CHANGE_EX", false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
end


function PetShelizi_OnLoad()
	PetShelizi_FormReset()
end

function PetShelizi_OnEvent(event)
	if event == "UI_COMMAND" then

		local CommandType = tonumber( arg0 )
		
		if UITYPE_SHELIZI == CommandType then
			local npcObjId = Get_XParam_INT( 0 )
			applyState = Get_XParam_INT( 1 )
			PetShelizi_OnUICommand( CommandType, tonumber( npcObjId ) )
		end

		if UITYPE_SHELIZI_NOTIFY == CommandType then
			slzExp = Get_XParam_INT( 0 )
			needmoney = math.floor(slzExp /100)
			if needmoney < 1 then
				needmoney = 1
			end
			PetShelizi_Demand_Money:SetProperty("MoneyNumber", needmoney)

			Guid_Pet_H, Guid_Pet_L = Pet : GetGUID( Index_Pet )
			PetShelizi_Pet1_Text : SetText(tostring(Pet_DBName))

			PetShelizi_OK:Enable()
		end
		
		if UITYPE_SHELIZI_CLOSE == CommandType then
			local arg = Get_XParam_INT( 0 )
			if arg==100 then
				PetShelizi_Cancel_Clicked()
				PetShelizi_OnHidden()
			else
				applyState=arg
			end
		end
		
	elseif (event == "MONEY_CHANGE_EX") then
		PetShelizi_Currently_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX") then
		PetShelizi_Currently_Jiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	elseif event == "REPLY_MISSION_PET" and this : IsVisible() then

		PetShelizi_OnSelectPet( tonumber( arg0 ) )

	elseif event == "OBJECT_CARED_EVENT" and this : IsVisible() then	-- 关心 NPC 的存在和范围
		Pet : ShowPetList( 0 )
		if tonumber( arg0 ) ~= CareNpcID then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		local MAX_OBJ_DISTANCE = 3.0
		if arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
			PetShelizi_Cancel_Clicked()
			PetShelizi_OnHidden()
		end

	end
end

function PetShelizi_OnUICommand( CommandType, NpcObjID )
	local Type = tonumber( CommandType )
	if Type == UITYPE_SHELIZI then
		PetShelizi_FormReset()
		PetShelizi_BeginCareObject( NpcObjID )
		PetShelizi_Currently_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetShelizi_Currently_Jiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		PetShelizi_Demand_Money:SetProperty("MoneyNumber", 0);
		this:Show()
		Pet : ShowPetList( 1 )
	end

end


function PetShelizi_SelectPet_Clicked()

	Pet : ShowPetList( 0 )
	Pet : ShowPetList( 1 )
end

function PetShelizi_OnSelectPet( PetIndex )
	--舍利子的判断有一部分是在服务器做的，服务器返回特定的舍利子相关错误，会push一个
	--REPLY_MISSION_PET事件，并且设置petindex为-1
	if PetIndex < 0 then
		if( Index_Pet ~= -1 )then
			Pet:SetPetLocation(Index_Pet,-1);
			Index_Pet = -1;
		end
		return
	end
	
	--珍兽已被其它界面选中
	if (Pet:GetPetLocation(PetIndex) ~= -1) then
		return;
	end

	local savvy = Pet:GetSavvy(PetIndex)
	if savvy ~= nil and savvy >= 7 and applyState~=2 then
		--PushDebugMessage("#{GDWPBH_100111_1}")    --你的珍兽悟性等级大于等于7级
		if applyState==0 then
			PushDebugMessage("#{GZSL_100525_9}")
		elseif applyState==1 then
			PushDebugMessage("#{GZSL_100525_10}")
		elseif applyState==3 then
			PushDebugMessage("#{GZSL_100525_9}")
		end
		
		return
	end

	if( Index_Pet ~= -1 )then
		Pet:SetPetLocation(Index_Pet,-1);
	end

	Index_Pet = PetIndex

	Pet : SetPetLocation( Index_Pet, 4 )
	PetShelizi_FormReset()

	local petGen , petDBName = Pet:GetPetTypeName(Index_Pet)
	local strName , strName2 = Pet:GetName(Index_Pet)

	if petGen == 1 then
		strName2 = "二代"..petDBName;
	end

	Pet_DBName = strName2

	local guidPetH, guidPetL = Pet : GetGUID( PetIndex )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PetShelizi" )
		Set_XSCRIPT_ScriptID( 805019 )
		Set_XSCRIPT_Parameter( 0, guidPetH )
		Set_XSCRIPT_Parameter( 1, guidPetL )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
end

function PetShelizi_OnHidden()
	if Index_Pet ~= -1 then
		Pet : SetPetLocation( Index_Pet, -1 )
	end
	Index_Pet = -1
	Pet : ShowPetList( 0 )
	Pet : ClearSheliziPet();
end

function PetShelizi_FormReset()
	Guid_Pet_H = -1
	Guid_Pet_L = -1
	--Index_Pet  = -1
	Pet_DBName = ""
	slzExp = 0
	needmoney =0
	PetShelizi_Demand_Money:SetProperty("MoneyNumber", needmoney)
	PetShelizi_Pet1_Text : SetText( Pet_DBName )
	PetShelizi_OK:Disable()
end



--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function PetShelizi_BeginCareObject( objCaredId )
	CareNpcID = DataPool : GetNPCIDByServerID( objCaredId )
	if CareNpcID == -1 then
		this : Hide()
		return
	end

	this : CareObject( CareNpcID, 1, "PetShelizi" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function PetShelizi_StopCareObject()
	this : CareObject( CareNpcID, 0, "PetShelizi" )
	Pet : ShowPetList( 0 )
	CareNpcID = -1
end


function PetShelizi_Cancel_Clicked()
	PetShelizi_FormReset()
	PetShelizi_StopCareObject()
	this:Hide()
end

function PetShelizi_OK_Clicked()
	PetShelizi_Check()
end

function PetShelizi_Check()

	if Guid_Pet_H == -1 or Guid_Pet_L == -1 then
		return
	end
--	放开等级限制
	-- 判定珍兽的等级是否大于等于30
--	local Level = Pet : GetLevel( Index_Pet )
--	if Level < minLevel then
--		PushDebugMessage("#{ZSKSSJ_081113_08}")
--		return
--	end
	--是否在安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	local selfMoney = Player : GetData( "MONEY" ) + Player : GetData( "MONEY_JZ" )
	if needmoney > selfMoney then
		PushDebugMessage("#{no_money}")
		return
	end

	PetShelizi_Notify(slzExp)

end

function PetShelizi_Notify(AllExp)


	local isNotify = Pet:PetToShelizi(Index_Pet , AllExp)
	if isNotify == 0 then
		return
	end


	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PetShelizi_Done" )
		Set_XSCRIPT_ScriptID( 805019 )
		Set_XSCRIPT_Parameter( 0, Guid_Pet_H )
		Set_XSCRIPT_Parameter( 1, Guid_Pet_L )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()

	PetShelizi_Cancel_Clicked()
end
