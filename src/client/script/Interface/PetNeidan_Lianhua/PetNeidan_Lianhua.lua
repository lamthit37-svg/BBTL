--  
--  炼制珍兽内丹

local Guid_Pet_H = -1
local Guid_Pet_L = -1
local Index_Pet = 0
local g_ScriptId = 998499
local g_UICMD = 99849901
local g_UICMD_Select = 99849902
local g_UIRefreshLianhuaState = 99849903
local CareNpcID = -1
local CareNpcServerID = -1
local Pet_DBName=""
local g_Pet_ShuXing = {}
local G_CURRENT_SELECT =-1;
local g_LianhuaType = -1

local tabNeiDanLianHuaNeedGrowLevel =  --想要炼化需要的成长率 petlianhua  +pet +服务器都要改
{
	{tl = 65,gl=1325},
	{tl = 75,gl=1443},
	{tl = 85,gl=1560},
	{tl = 95,gl=1677},
}

function PetNeidan_Lianhua_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "REPLY_MISSION_PET", false )						-- 玩家从列表选定一只珍兽
	-- this : RegisterEvent( "UPDATE_PET_PAGE" )						-- 玩家身上的珍兽数据发生变化，包括增加一只珍兽
	this : RegisterEvent( "DELETE_PET" )							-- 玩家身上减少一只珍兽
	this : RegisterEvent( "OBJECT_CARED_EVENT", false )						-- 关心 NPC 的存在和范围
	--this : RegisterEvent("MONEY_CHANGE_EX") 
	--this : RegisterEvent("MONEYJZ_CHANGE_EX")
	
	
	this:RegisterEvent("PET_NEIDAN_LIANHUA_UPDATE")
end

-- 界面的默认相对位置
local g_PetNeidan_Lianhua_Frame_UnifiedXPosition;
local g_PetNeidan_Lianhua_Frame_UnifiedYPosition;

function PetNeidan_Lianhua_OnLoad()
	g_PetNeidan_Lianhua_Frame_UnifiedXPosition	= PetNeidan_Lianhua_Frame : GetProperty("UnifiedXPosition");
	g_PetNeidan_Lianhua_Frame_UnifiedYPosition	= PetNeidan_Lianhua_Frame : GetProperty("UnifiedYPosition");
	PetNeidan_Lianhua_FormReset()
end

function PetNeidan_Lianhua_OnEvent(event)

	if event == "UI_COMMAND" then

		local CommandType = tonumber( arg0 )
		if g_UICMD == CommandType then
			--打开界面
			local ntype = Get_XParam_INT( 0 )
			if ntype == 1 then
				--打开界面
				local npcObjId = Get_XParam_INT( 1 )
				Pet : ShowPetList( 0 )
				Pet : ShowPetList( 1 )
				Pet : UpdatePetList()
				if npcObjId >= 0 then
					PetNeidan_Lianhua_BeginCareObject( npcObjId )
				end
				

				--PetNeidan_Lianhua_FakeObject : AttachWindowEx( "My_Pet" );
				PetNeidan_Lianhua_FormReset()
				G_CURRENT_SELECT =-1
				PetNeidan_Lianhua_Frame : SetProperty("UnifiedXPosition", g_PetNeidan_Lianhua_Frame_UnifiedXPosition);
				PetNeidan_Lianhua_Frame : SetProperty("UnifiedYPosition", g_PetNeidan_Lianhua_Frame_UnifiedYPosition);
				
			
				PetNeidan_Lianhua_Text3:SetText("#{ZSLH_230426_44}")	--当前未选择想要炼化的珍兽
				--PetNeidan_Lianhua_Text4:SetText("")
				PetNeidan_Lianhua_FakeObject:SetFakeObject("")
				PetNeidan_Lianhua_WuXing:SetText("#{ZSLH_230426_35}")
				PetNeidan_Lianhua_LingXing:SetText("#{ZSLH_230426_36}")
				PetNeidan_Lianhua_RongHeDu:SetText("#{ZSLH_230426_37}")


				PetNeidan_Lianhua_StrAptitude:SetText("")
				PetNeidan_Lianhua_NimbusAptitude:SetText("")
				PetNeidan_Lianhua_PhysicalStrengthAptitude:SetText("")
				PetNeidan_Lianhua_StabilityAptitude:SetText("")
				PetNeidan_Lianhua_DexterityAptitude:SetText("")
				
				PetNeidan_Lianhua_RefreshNeidanLianhuaTip()
				-- 增加界面互斥关闭逻辑			
				if(IsWindowShow("BieYePetBar_Awake")) then
				  CloseWindow("BieYePetBar_Awake", true) 
				end
				this:Show()
			
			end
			if ntype == 2 then
				--PushDebugMessage("confirm") 
				--confirm
				local strMsg = Get_XParam_STR(0)	
				MessageBoxSelf3("PetNeidan_Lianhua_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
			end
		end

		if g_UICMD_Select == CommandType then  --点珍兽切换之后
			local nType = Get_XParam_INT( 0 )
			if nType == 0 then
				--不能切换
				--应该不会走到这里，不能切换的在服务器就已经重新打开ui了
				if Index_Pet ~= -1 then
					Pet : SetPetLocation( Index_Pet, -1 )
				end
				Index_Pet = -1
				PetNeidan_Lianhua_WuXing:SetText("#{ZSLH_230426_35}")
				PetNeidan_Lianhua_LingXing:SetText("#{ZSLH_230426_36}")
				PetNeidan_Lianhua_RongHeDu:SetText("#{ZSLH_230426_37}")
				PetNeidan_Lianhua_StrAptitude:SetText("")
				PetNeidan_Lianhua_NimbusAptitude:SetText("")
				PetNeidan_Lianhua_PhysicalStrengthAptitude:SetText("")
				PetNeidan_Lianhua_StabilityAptitude:SetText("")
				PetNeidan_Lianhua_DexterityAptitude:SetText("")
				PetNeidan_Lianhua_Text3:SetText("")
				--PetNeidan_Lianhua_Text4:SetText("")
			elseif nType == 1 then

				g_Pet_ShuXing[1] = Pet:GetSavvy(Index_Pet)
				g_Pet_ShuXing[2] = Pet:GetLixing(Index_Pet)
				g_Pet_ShuXing[3] = Pet:GetFitValue(Index_Pet)
				g_Pet_ShuXing[4] = Pet:GetStrAptitude(Index_Pet)
				g_Pet_ShuXing[5] = Pet:GetIntAptitude(Index_Pet)
				g_Pet_ShuXing[6] = Pet:GetPFAptitude(Index_Pet)
				g_Pet_ShuXing[7] = Pet:GetStaAptitude(Index_Pet)
				g_Pet_ShuXing[8] = Pet:GetDexAptitude(Index_Pet)
				g_LianhuaType = Get_XParam_INT( 1 )

				PetNeidan_Lianhua_WuXing:SetText("#{ZSLH_230426_35}"..tostring(g_Pet_ShuXing[1]))
				PetNeidan_Lianhua_LingXing:SetText("#{ZSLH_230426_36}"..tostring(g_Pet_ShuXing[2]))
				PetNeidan_Lianhua_RongHeDu:SetText("#{ZSLH_230426_37}"..tostring(g_Pet_ShuXing[3]))
				PetNeidan_Lianhua_StrAptitude:SetText(ScriptGlobal_Format("#{ZSLH_230426_43}", tostring(g_Pet_ShuXing[4])) )
				PetNeidan_Lianhua_NimbusAptitude:SetText(ScriptGlobal_Format("#{ZSLH_230426_43}", tostring(g_Pet_ShuXing[5])) )
				PetNeidan_Lianhua_PhysicalStrengthAptitude:SetText(ScriptGlobal_Format("#{ZSLH_230426_43}", tostring(g_Pet_ShuXing[6])) )
				PetNeidan_Lianhua_StabilityAptitude:SetText(ScriptGlobal_Format("#{ZSLH_230426_43}", tostring(g_Pet_ShuXing[7])) )
				PetNeidan_Lianhua_DexterityAptitude:SetText(ScriptGlobal_Format("#{ZSLH_230426_43}", tostring(g_Pet_ShuXing[8])) )
				

				--下方的炼化信息，品质和内丹/碎片的概率描述
				local nInfoStr_1  = Get_XParam_STR(0)	
				--local nInfoStr_2  = Get_XParam_STR(1)	
				PetNeidan_Lianhua_Text3:SetText(tostring(nInfoStr_1))
				--PetNeidan_Lianhua_Text4:SetText(tostring(nInfoStr_2))
				
				
				Guid_Pet_H, Guid_Pet_L = Pet : GetGUID( Index_Pet )
				Pet : SetPetLocation( Index_Pet , 2 )
				Pet : UpdatePetList()
				G_CURRENT_SELECT = Index_Pet
				
				PetNeidan_Lianhua_FakeObject:Hide()
				if G_CURRENT_SELECT >= 0 then
					PetNeidan_Lianhua_FakeObject:Show()
					Pet:SetModel(G_CURRENT_SELECT)
					PetNeidan_Lianhua_FakeObject:SetFakeObject("")
					--PetNeidan_Lianhua_FakeObject:SetFakeObject( "My_Pet" )	
					
					Pet:SetSkillStudyModel(G_CURRENT_SELECT)
					PetNeidan_Lianhua_FakeObject:SetFakeObject( "My_PetStudySkill" )	
					
				end
				
				

				PetNeidan_Lianhua_Pet_Text :SetText(tostring(Pet_DBName))
				--炼化标识
				PetNeidan_Lianhua_RefreshNeidanLianhuaTip()
			end
		
			
		end
		
		if g_UIRefreshLianhuaState == CommandType then 
			local nLianHuaType = Get_XParam_INT( 0 )			--通知客户端刷新炼化状态 申请到时间  +过期 
			PetNeidan_Lianhua_RefreshNeidanLianhuaTip()
		end

	elseif event == "REPLY_MISSION_PET" and this : IsVisible() then
		PetNeidan_Lianhua_PetList_OnSelect(tonumber(arg0))

	elseif event == "OBJECT_CARED_EVENT" and this : IsVisible() then	-- 关心 NPC 的存在和范围
		Pet : ShowPetList( 0 )
		if tonumber( arg0 ) ~= CareNpcID then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		local MAX_OBJ_DISTANCE = 3.0
		if arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
			PetNeidan_Lianhua_OnCancel()
			PetNeidan_Lianhua_OnHidden()
		end
	end	
end
--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function PetNeidan_Lianhua_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		if Guid_Pet_H == -1 or Guid_Pet_L == -1 then
			return
		end	
		if Pet:IsPresent(Index_Pet) then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnLianHua" )
				Set_XSCRIPT_ScriptID( 998499 )
				Set_XSCRIPT_Parameter( 0, Guid_Pet_H )
				Set_XSCRIPT_Parameter( 1, Guid_Pet_L )
				Set_XSCRIPT_Parameter( 2, CareNpcServerID )
				
				Set_XSCRIPT_ParamCount( 3 )
			Send_XSCRIPT()	
		else
			PushDebugMessage("#{ZSLH_230426_92}")
			PetNeidan_Lianhua_Cancel_Clicked()
			return 
		end
	end

	if "No" == strRet then
		-- 关闭二次确认框
	end
	
end


function PetNeidan_Lianhua_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1 ) then
		PetNeidan_Lianhua_FakeObject:RotateBegin( -0.3);
	--向左旋转结束
	else
		PetNeidan_Lianhua_FakeObject:RotateEnd();
	end
end


function PetNeidan_Lianhua_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1 ) then
		PetNeidan_Lianhua_FakeObject:RotateBegin( 0.3);
	--向右旋转结束
	else
		PetNeidan_Lianhua_FakeObject:RotateEnd();
	end
end
	
	
	


function PetNeidan_Lianhua_SelectPet_Clicked()	
	Pet : ShowPetList( 0 )
	Pet : ShowPetList( 1 )
end

function PetNeidan_Lianhua_PetList_OnSelect( PetIndex )
	--舍利子的判断有一部分是在服务器做的，服务器返回特定的舍利子相关错误，会push一个
	--REPLY_MISSION_PET事件，并且设置petindex为-1
	if PetIndex < 0 then
		if( Index_Pet ~= -1 )then
			Pet:SetPetLocation(Index_Pet,-1) 
			Index_Pet = -1 
		end
		return
	end

	--珍兽已被其它界面选中
	if (Pet:GetPetLocation(PetIndex) ~= -1) then
		return 
	end

	if( Index_Pet ~= -1 )then
		Pet:SetPetLocation(Index_Pet,-1) 
	end
	Index_Pet = PetIndex
	Pet : SetPetLocation( Index_Pet, 21 )
	PetNeidan_Lianhua_FormReset()
	
	
	local petGen , petDBName = Pet:GetPetTypeName(Index_Pet)
	local strName , strName2 = Pet:GetName(Index_Pet)

	if petGen == 1 then
		strName2 = "二代"..petDBName 
	end

	Pet_DBName = strName2

	local guidPetH, guidPetL = Pet : GetGUID( PetIndex )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PetLianHua_Select" )
		Set_XSCRIPT_ScriptID( g_ScriptId )
		Set_XSCRIPT_Parameter( 0, guidPetH )
		Set_XSCRIPT_Parameter( 1, guidPetL )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
end

-- function PetNeidan_Lianhua_OnHidden()
-- 	if Index_Pet ~= -1 then
-- 		Pet : SetPetLocation( Index_Pet, -1 )
-- 	end
-- 	Index_Pet = -1
-- 	g_LianhuaType = -1
-- 	Pet : ShowPetList( 0 )
-- 	--PetNeidan_Lianhua_FakeObject : DetachWindowEx( "My_Pet" );
-- 	PushDebugMessage("PetNeidan_Lianhua_OnHidden")
-- end

function PetNeidan_Lianhua_FormReset()
	Guid_Pet_H = -1
	Guid_Pet_L = -1
	Pet_DBName = ""
	g_LianhuaType = -1
	PetNeidan_Lianhua_Pet_Text : SetText( Pet_DBName )
	PetNeidan_Lianhua_FakeObject : Hide()
	PetNeidan_Lianhua_FakeObject : SetFakeObject("")

end



--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function PetNeidan_Lianhua_BeginCareObject( objCaredId )
	CareNpcServerID = objCaredId
	CareNpcID = DataPool : GetNPCIDByServerID( objCaredId )
	if CareNpcID == -1 then
		this : Hide()
		return
	end

	this : CareObject( CareNpcID, 1, "PetNeidan_Lianhua" )
	this : Hide()
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function PetNeidan_Lianhua_StopCareObject()
	this : CareObject( CareNpcID, 0, "PetNeidan_Lianhua" )
	Pet : ShowPetList( 0 )
	CareNpcID = -1
	CareNpcServerID = -1
end



function PetNeidan_Lianhua_OnOK()
	--去做二次确认
	if Guid_Pet_H == -1 or Guid_Pet_L == -1 then
		PushDebugMessage("#{ZSLH_230426_53}")
		return
	end
	if IsIdleLogic() ~= 1 then
		PushDebugMessage("#{YBSD_081225_100}");
		return 0;
	end
	if Pet:IsPresent(Index_Pet) then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnClickOK" )
			Set_XSCRIPT_ScriptID( 998499 )
			Set_XSCRIPT_Parameter( 0, Guid_Pet_H )
			Set_XSCRIPT_Parameter( 1, Guid_Pet_L )
			Set_XSCRIPT_Parameter( 2, CareNpcServerID )		
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	else
		PushDebugMessage("#{ZSLH_230426_92}"); 
		PetNeidan_Lianhua_Cancel_Clicked()
	end
end

function PetNeidan_Lianhua_Cancel_Clicked()
	PetNeidan_Lianhua_OnHidden()
end
-- 右上角x
function PetNeidan_Lianhua_OnClose()
	PetNeidan_Lianhua_OnHidden()
end
function PetNeidan_Lianhua_Close()
	PetNeidan_Lianhua_OnHidden()
end

function PetNeidan_Lianhua_OnHidden()

	if Index_Pet ~= -1 then
		Pet : SetPetLocation( Index_Pet, -1 )
	end
	Index_Pet = -1
	Pet : ShowPetList( 0 )
	PetNeidan_Lianhua_FormReset()
	PetNeidan_Lianhua_StopCareObject()
	this:Hide()
	
end

function  PetNeidan_Lianhua_RefreshNeidanLianhuaTip()
	PetNeidan_Lianhua_FakeObject_Image_Mask:Hide() --平时肯定不蒙红
	g_LianhuaType = PetNeidan_Lianhua_GetLianhuaType(G_CURRENT_SELECT) 
	if g_LianhuaType < 0  then	
			PetNeidan_Lianhua_FakeObject_Image:Hide()
		return 
	end
	PetNeidan_Lianhua_FakeObject_Image:Show()
	if g_LianhuaType == 0   then
		--不可炼化
		--按理说这个界面里，不可炼化就不能被选中，所以不会走到这里，但是pet界面的就可以选到
		--蒙红
		PetNeidan_Lianhua_FakeObject_Image_Mask:Show()
	elseif g_LianhuaType == 1 then
		--普通炼化
		PetNeidan_Lianhua_FakeObject_Image:SetToolTip("#{ZSLH_230426_01}")
	
	elseif  g_LianhuaType == 2  then
		--贵重炼化
		local nNeidanLianhuaState = PetNeidan_Lianhua_GetNeidanLianhuaState()  --根据md算的

		if nNeidanLianhuaState == 2 then
			--可炼化期间 1天	
			PetNeidan_Lianhua_FakeObject_Image:SetToolTip(ScriptGlobal_Format("#{ZSLH_230426_03}", tostring(1) ))
		else
			--不可炼化期间
			PetNeidan_Lianhua_FakeObject_Image:SetToolTip(ScriptGlobal_Format("#{ZSLH_230426_03}", tostring(0) ))
			--蒙红
			PetNeidan_Lianhua_FakeObject_Image_Mask:Show()
			
		
		end
	end
end
--获得炼化类型 0 = 不可炼化，1=只普通炼化，2=只贵重炼化
--只与珍兽本身相关4条，1，PetTypeAttr表里，2，宝宝和成年不能炼化，3，可携带等级，4，成长率够不够
function PetNeidan_Lianhua_GetLianhuaType(petIdx)
	
	if petIdx == nil or petIdx < 0 then
		return -1 
	end
	--PetTypeAttr表里根据类型是否可以炼化
	local nflag = Pet : GetPetLianHuaFlag(petIdx) 	
	if (nflag ~= 1) then
		PetNeidan_Lianhua_FakeObject_Image:SetToolTip("#{ZSLH_230426_02}")
		return 0 
	end

	--判断珍兽是不是珍兽宝宝 or成年
	local nType = Pet:GetPetType(petIdx)	
	if (nType ~= 1 ) then
		PetNeidan_Lianhua_FakeObject_Image:SetToolTip("#{ZSLH_230426_89}")
		return 0
	end	
			

	--携带等级65级
	local nTakeLevel = Pet:GetTakeLevel(petIdx)
	local nLimitLvl = 65
	if nTakeLevel < nLimitLvl then
		PetNeidan_Lianhua_FakeObject_Image:SetToolTip("#{ZSLH_230426_88}")
		return 0
	end
	
	--有没有鉴定过成长率
	local PetRate = Pet:GetGrowRate(petIdx)
	local PetCZL_Real = Pet:GetPetGrowLevel(petIdx,PetRate)
	if PetCZL_Real< 0 then	
		PetNeidan_Lianhua_FakeObject_Image:SetToolTip("#{ZSLH_230426_90}")
		return 0
	end
	--成长率够不够
	local	nNeedGrowLevel	= NeidanLianhua_GetNeedGrowLvl(nTakeLevel)
	if nNeedGrowLevel >= PetRate then
		PetNeidan_Lianhua_FakeObject_Image:SetToolTip("#{ZSLH_230426_87}")
		return  0
	end
	--是否贵重
	local nSavvy =  Pet:GetSavvy(petIdx)
	if nSavvy == nil then
		return 0
	end
	if nSavvy >= 7 then
		return 2
	end
	return 1 	
end
--**********************************
--获得需要的成长率
--**********************************
function NeidanLianhua_GetNeedGrowLvl(petTakeLevel)
	local nNeedGrowLevel = -1
	for i=1, table.getn(tabNeiDanLianHuaNeedGrowLevel) do
		if tabNeiDanLianHuaNeedGrowLevel[i].tl <= petTakeLevel then
			nNeedGrowLevel =  tabNeiDanLianHuaNeedGrowLevel[i].gl
		end	
	end
	return nNeedGrowLevel 
end

--获得珍兽内丹炼化的时间阶段
function  PetNeidan_Lianhua_GetNeidanLianhuaState()
	local serverTime = DataPool:GetCurrentServerTime()
	local nNeidanLianhuaShiJianChuo = DataPool:GetPlayerMission_DataRound(2782) --时间戳 服务器SetMD会通知客户端改数据
	--PushDebugMessage("nNeidanLianhuaShiJianChuo="..nNeidanLianhuaShiJianChuo)
	
	if nNeidanLianhuaShiJianChuo <= 0 then
		return 0 
	end
	local g_LianHuaNeiDanApplying =  3*24*3600 
	local g_LianHuaNeiDanApplied = 24*3600 
	local deltaTime = serverTime - nNeidanLianhuaShiJianChuo

	if deltaTime < g_LianHuaNeiDanApplying then
		return 1
	elseif deltaTime < g_LianHuaNeiDanApplied + g_LianHuaNeiDanApplying then
		return 2
	else
		return 3
	end
	return 0 
end


