--  PetXuelizi
--  炼制珍兽血利子

local Guid_Pet_H = -1
local Guid_Pet_L = -1
local Index_Pet = -1
local UITYPE_XUELIZI = 889966
local UITYPE_XUELIZI_NOTIFY = 889965
local CareNpcID = -1
local minLevel=30
local Pet_DBName=""
local g_Grade = 0;
local g_Level = 0;
local NEEDMONEY = 50000
local g_MaxJinJieLvl = 100
local g_JinJieLvlPerGrade = 10
local g_ConfirFlag = 0;
function PetXuelizi_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "REPLY_MISSION_PET" )						-- 玩家从列表选定一只珍兽
	-- this : RegisterEvent( "UPDATE_PET_PAGE" )						-- 玩家身上的珍兽数据发生变化，包括增加一只珍兽
	this : RegisterEvent( "DELETE_PET" )							-- 玩家身上减少一只珍兽
	this : RegisterEvent( "OBJECT_CARED_EVENT" )						-- 关心 NPC 的存在和范围
	this : RegisterEvent("MONEY_CHANGE_EX", false);
	this : RegisterEvent("MONEYJZ_CHANGE_EX", false)
end


function PetXuelizi_OnLoad()
	PetXuelizi_FormReset()
end

function PetXuelizi_OnEvent(event)
	if event == "UI_COMMAND" then

		local CommandType = tonumber( arg0 )
		if UITYPE_XUELIZI == CommandType then
			local npcObjId = Get_XParam_INT( 0 )
			PetXuelizi_OnUICommand( CommandType, tonumber( npcObjId ) )
		end

		if UITYPE_XUELIZI_NOTIFY == CommandType then
			g_Grade = Get_XParam_INT( 0 )
			g_Level = Get_XParam_INT( 1 )
			if g_Grade <= 0 and g_Level <= 0 then
				PushDebugMessage("#{JJKHD_120808_40}")
			else
				PetXuelizi_Demand_Money:SetProperty("MoneyNumber", NEEDMONEY)

				Guid_Pet_H, Guid_Pet_L = Pet : GetGUID( Index_Pet )
				Pet : SetPetLocation( Index_Pet , 2 )
				Pet : UpdatePetList()
				PetXuelizi_Pet1_Text : SetText(tostring(Pet_DBName))
				g_ConfirFlag = 0;
				PetXuelizi_OK:Enable()
			end
		end
	elseif (event == "MONEY_CHANGE_EX") then
		PetXuelizi_Currently_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX") then
		PetXuelizi_Currently_Jiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	elseif event == "REPLY_MISSION_PET" and this : IsVisible() then
		PetXuelizi_OnSelectPet( tonumber( arg0 ) )

	elseif event == "OBJECT_CARED_EVENT" and this : IsVisible() then	-- 关心 NPC 的存在和范围
		Pet : ShowPetList( 0 )
		if tonumber( arg0 ) ~= CareNpcID then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		local MAX_OBJ_DISTANCE = 3.0
		if arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
			PetXuelizi_Cancel_Clicked()
			PetXuelizi_OnHidden()
		end

	end
end

function PetXuelizi_OnUICommand( CommandType, NpcObjID )
	local Type = tonumber( CommandType )
	if Type == UITYPE_XUELIZI then
		PetXuelizi_FormReset()
		PetXuelizi_BeginCareObject( NpcObjID )
		PetXuelizi_Currently_Money:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetXuelizi_Currently_Jiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		PetXuelizi_Demand_Money:SetProperty("MoneyNumber", 0);
		-- 增加界面互斥关闭逻辑			
		if(IsWindowShow("BieYePetBar_Awake")) then
		  CloseWindow("BieYePetBar_Awake", true);
		end
		this:Show()
		Pet : ShowPetList( 1 )
	end

end


function PetXuelizi_SelectPet_Clicked()

	Pet : ShowPetList( 0 )
	Pet : ShowPetList( 1 )
end

function PetXuelizi_OnSelectPet( PetIndex )
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

	if( Index_Pet ~= -1 )then
		Pet:SetPetLocation(Index_Pet,-1);
	end
	Index_Pet = PetIndex
	Pet : SetPetLocation( Index_Pet, 20 )
	PetXuelizi_FormReset()

	local petGen , petDBName = Pet:GetPetTypeName(Index_Pet)
	local strName , strName2 = Pet:GetName(Index_Pet)

	if petGen == 1 then
		strName2 = "二代"..petDBName;
	end

	Pet_DBName = strName2

	local guidPetH, guidPetL = Pet : GetGUID( PetIndex )
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PetXuelizi_Select" )
		Set_XSCRIPT_ScriptID( 889966 )
		Set_XSCRIPT_Parameter( 0, guidPetH )
		Set_XSCRIPT_Parameter( 1, guidPetL )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
end

function PetXuelizi_OnHidden()
	if Index_Pet ~= -1 then
		Pet : SetPetLocation( Index_Pet, -1 )
	end
	Index_Pet = -1
	Pet : ShowPetList( 0 )
	g_ConfirFlag = 0;
end

function PetXuelizi_FormReset()
	Guid_Pet_H = -1
	Guid_Pet_L = -1
	--Index_Pet  = -1
	Pet_DBName = ""
	slzExp = 0
	PetXuelizi_Demand_Money:SetProperty("MoneyNumber", 0)
	PetXuelizi_Pet1_Text : SetText( Pet_DBName )
	PetXuelizi_OK:Disable()
end



--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function PetXuelizi_BeginCareObject( objCaredId )
	CareNpcID = DataPool : GetNPCIDByServerID( objCaredId )
	if CareNpcID == -1 then
		this : Hide()
		return
	end

	this : CareObject( CareNpcID, 1, "PetXuelizi" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function PetXuelizi_StopCareObject()
	this : CareObject( CareNpcID, 0, "PetXuelizi" )
	Pet : ShowPetList( 0 )
	CareNpcID = -1
end


function PetXuelizi_Cancel_Clicked()
	PetXuelizi_FormReset()
	PetXuelizi_StopCareObject()
	this:Hide()
end

function PetXuelizi_OK_Clicked()
	PetXuelizi_Check()
end

function PetXuelizi_Check()

	if Guid_Pet_H == -1 or Guid_Pet_L == -1 then
		return
	end
	--是否在安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	local selfMoney = Player : GetData( "MONEY" ) + Player : GetData( "MONEY_JZ" )
	if NEEDMONEY > selfMoney then
		PushDebugMessage("#{JJKHD_120808_45}")
		return
	end

	PetXuelizi_Notify()

end

function PetXuelizi_Notify()
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	if IsIdleLogic() ~= 1 then
		PushDebugMessage("#{YBSD_081225_100}");
		return 0;
	end
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	if Pet:IsPresent(Index_Pet) then
		local nGrade = Pet : GetJinJieGrade(Index_Pet);
		local nCurLevel = Pet : GetJinJieLvl(Index_Pet);
		if nGrade <= 0 and nCurLevel <= 0 then
			PushDebugMessage("#{JJKHD_120808_40}")
			return
		end

		local szMsg = ScriptGlobal_Format("#{JJKHD_120808_34}",Pet_DBName, tostring(nGrade), tostring(nCurLevel))
		if g_ConfirFlag == 0 then
			PushEvent( "PETJINJIE_XUELIZI_CONFIRM", szMsg, "-1" )
			g_ConfirFlag = 1
			return
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "PetXuelizi_Done" )
			Set_XSCRIPT_ScriptID( 889966 )
			Set_XSCRIPT_Parameter( 0, Guid_Pet_H )
			Set_XSCRIPT_Parameter( 1, Guid_Pet_L )
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
	else
		PushDebugMessage("#{YBSD_081225_100}");
	end
	PetXuelizi_Cancel_Clicked()
end
