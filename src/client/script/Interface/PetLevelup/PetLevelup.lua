--UI COMMAND ID 19823 by hukai 39440~39446

local PETSKILL_BUTTONS_NUM = 12;
local PETSKILL_BUTTONS = {};
local PETSKILL_BUTTONS_RED = {};

local g_clientNpcId = -1;
local g_selectindex = -1;
local g_selectskill = -1;
local g_selectgood = -1;
local g_ConsumeGoodsID = -1;
local g_ConsumeMoney = -1;

local g_PetLevelup_Frame_UnifiedPosition;
--local g_PageIdx=-1 --0,1

function PetLevelup_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("REPLY_MISSION_PET");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("PETSKILLLEVELUP");
	this:RegisterEvent("DELETE_PET");
	this:RegisterEvent("UPDATE_PET_PAGE", false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PETSKILLUP_ITEMBUY")
	
end

function PetLevelup_OnLoad()

	PETSKILL_BUTTONS[1] = PetLevelup_Skill1;
	PETSKILL_BUTTONS[2] = PetLevelup_Skill2;
	PETSKILL_BUTTONS[3] = PetLevelup_Skill3;
	PETSKILL_BUTTONS[4] = PetLevelup_Skill4;
	PETSKILL_BUTTONS[5] = PetLevelup_Skill5;
	PETSKILL_BUTTONS[6] = PetLevelup_Skill6;
	PETSKILL_BUTTONS[7] = PetLevelup_Skill7;
	PETSKILL_BUTTONS[8] = PetLevelup_Skill8;
	PETSKILL_BUTTONS[9] = PetLevelup_Skill9;
	PETSKILL_BUTTONS[10] = PetLevelup_Skill10;
	PETSKILL_BUTTONS[11] = PetLevelup_Skill11;
	PETSKILL_BUTTONS[12] = PetLevelup_Skill12;

	PETSKILL_BUTTONS_RED={
	PetLevelup_Skill1_Mask, PetLevelup_Skill2_Mask, PetLevelup_Skill3_Mask, PetLevelup_Skill4_Mask,
	PetLevelup_Skill5_Mask, PetLevelup_Skill6_Mask, PetLevelup_Skill7_Mask, PetLevelup_Skill8_Mask,
	PetLevelup_Skill9_Mask, PetLevelup_Skill10_Mask, PetLevelup_Skill11_Mask, PetLevelup_Skill12_Mask
	}
	g_PetLevelup_Frame_UnifiedPosition=PetLevelup_Frame:GetProperty("UnifiedPosition");
	
end

function PetLevelup_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 19823) then
		if this : IsVisible() then									-- 如果界面开着，则不处理
			return
		end
		local npcObjId = Get_XParam_INT(0)
		g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
		if g_clientNpcId == -1 then
			PushDebugMessage("未发现 NPC")
			PetLevelup_Hide()
			return
		end
		
		this : CareObject( g_clientNpcId, 1, "PetLevelup" )
		PetLevelup_Clear()
		PetLevelup_UpdateMoney()
		this : Show()
		Pet:ShowPetList(1)
	elseif ( event == "REPLY_MISSION_PET" and this:IsVisible() ) then
		PetLevelup_Selected(tonumber(arg0))
	elseif ( event == "OBJECT_CARED_EVENT" ) then
		if(tonumber(arg0) ~= g_clientNpcId) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
			PetLevelup_Hide()
		end
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then

		if( arg0 ~= nil and -1 == tonumber(arg0)) then
			return;
		end
		if g_selectgood == tonumber(arg0) then --已选中物品并且更新的物品是当前选中的物品
			PetLevelup_UpdateGoods(tonumber(arg0), 0)
		end
	elseif ( event == "PETSKILLLEVELUP" and this:IsVisible() ) then
		if( arg0 == nil or arg1 == nil ) then
			return;
		end

		local typeidx = tonumber(arg0)
		if typeidx == 1 then --拖动到物品栏
			PetLevelup_UpdateGoods(tonumber(arg1), 1)
		elseif typeidx == 2 then --拖动到技能栏，不使用PetLevelup_Skill_Clicked是因为索引计算方式不一样
			PetLevelup_Skill_Drag(tonumber(arg1), 1)
		end
		
	elseif ( event == "DELETE_PET" and this:IsVisible() ) then
		PetLevelup_Hide()
		
	elseif ( event == "UPDATE_PET_PAGE" and this:IsVisible() ) then
		for i=1, PETSKILL_BUTTONS_NUM do
			PETSKILL_BUTTONS[i]:SetActionItem(-1);
--			PETSKILL_BUTTONS_RED[i]:Hide()
		end

		PetLevelup_Skill02:SetActionItem(-1);
		PetLevelup_Skill03:SetActionItem(-1);
--		PetLevelup_Skill01:SetActionItem(-1);
		PetLevelup_Money1:SetProperty("MoneyNumber", "")
		--对于有灵兽丹，如果已经选中，但是使用了快捷提升，则
		PetLevelup_CancelGoods()

		PetLevelup_PetModel:SetFakeObject("")

		if g_selectindex<0 then
			return
		else
			Pet:SetPetLocation(g_selectindex,-1);
		end
		
		--珍兽出战和附体时不显示珍兽信息
		if (Pet:GetIsPossession(g_selectindex)) or (Pet : GetIsFighting(g_selectindex)) then
			g_selectindex = -1
			return
		end
		
		Pet:SetSkillLevelupModel(g_selectindex);
		Pet:SetPetLocation(g_selectindex,1);
		PetLevelup_PetModel:SetFakeObject( "My_PetLevelup" );
		
		local i=1;
		local k=1;
		
		while i <= PETSKILL_BUTTONS_NUM do
			local theSkillAction = Pet:EnumPetSkill( g_selectindex, i-1, "petskill");

			if theSkillAction:GetID() ~= 0 then
				PETSKILL_BUTTONS[k]:SetActionItem(theSkillAction:GetID());
				--技能是否可以升级
				local skillID = Pet:GetSkillIDbyIndex(g_selectindex, i-1)
				local SkillLevelUpID,WantGoodsID,GoodsCostYB,WantMoney,HighestSkillID,WantHighestYB = Pet:GetPetSkillLevelupInfo(skillID,g_selectindex)
				if WantGoodsID==-1 or HighestSkillID==-1 then
					PETSKILL_BUTTONS_RED[k]:Show()
				else
					PETSKILL_BUTTONS_RED[k]:Hide()
				end
				k = k+1;
			end
			i = i + 1;
		end
		
		Pet:SetPetLocation(g_selectindex,-1);
		PetLevelup_Skill_Drag(g_selectskill, 0)
	elseif (event == "PETSKILLUP_ITEMBUY" and this:IsVisible()) then
		PetLevelup_UpdateGoods(tonumber(arg0), 0)
	elseif (event == "ADJEST_UI_POS" ) then
		PetLevelup_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetLevelup_Frame_On_ResetPos()
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		--金币
		PetLevelup_Money3:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		--交子
		PetLevelup_Money2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	end
end

function PetLevelup_CancelGoods()
	g_ConsumeGoodsID = -1 --选物品的时候设置了这两个值，所以取消物品的时候清空这两个值
	g_ConsumeMoney = -1


	PetLevelup_Skill01:SetActionItem(-1);
--	PetLevelup_Money1:SetProperty("MoneyNumber", "")

	if g_selectgood ~= -1 then
		LifeAbility : Lock_Packet_Item(g_selectgood,0);
	end
	g_selectgood = -1;

end

function PetLevelup_CancelSkill()

	PetLevelup_Skill02:SetActionItem(-1);
	PetLevelup_Skill03:SetActionItem(-1);
	PetLevelup_Money1:SetProperty("MoneyNumber", "")

	g_selectskill = -1;
	for i=1, PETSKILL_BUTTONS_NUM do
		PETSKILL_BUTTONS[i]:SetPushed(0);
	end
	PetLevelup_Accept:Disable()
	PetLevelup_Up:Disable()
	PetLevelup_Animate:Play(false)
end

function PetLevelup_Clear()

	if( g_selectindex ~= -1 )then
		Pet:SetPetLocation(g_selectindex,-1);
	end
	
	g_selectindex = -1

	for i=1, PETSKILL_BUTTONS_NUM do
		PETSKILL_BUTTONS[i]:SetActionItem(-1);
		PETSKILL_BUTTONS_RED[i]:Hide()
	end

	PetLevelup_CancelSkill()
	PetLevelup_CancelGoods()
	PetLevelup_PetModel:SetFakeObject("")

end

function PetLevelup_Hide()
	g_clientNpcId = -1
	this:CareObject(g_clientNpcId, 0, "PetLevelup")
	this:Hide()
	Pet:ShowPetList(-1)
	PetLevelup_Clear()
end

function PetLevelup_Frame_OnHiden()
	PetLevelup_Hide()
end

--选中珍兽
function PetLevelup_Selected(selectindex)
	if( -1 == selectindex ) then
		return;
	end
	
--	if PlayerPackage:IsPetLock(selectindex) == 1 then
--		PushDebugMessage("珍兽已加锁")
--		return
--	end
	--珍兽已被其它界面选中
	if (Pet:GetPetLocation(selectindex) ~= -1) then
		return;
	end
	
	PetLevelup_Clear()
	
	PetLevelup_PetModel:SetFakeObject("");
	Pet:SetSkillLevelupModel(selectindex);
	Pet:SetPetLocation(selectindex,1);
	PetLevelup_PetModel:SetFakeObject( "My_PetLevelup" );
	
	local i=1;
	local k=1;
	
	while i <= PETSKILL_BUTTONS_NUM do
		local theSkillAction = Pet:EnumPetSkill( selectindex, i-1, "petskill");
		if theSkillAction:GetID() ~= 0 then
			PETSKILL_BUTTONS[k]:SetActionItem(theSkillAction:GetID());
			--技能是否可以升级
			local skillID = Pet:GetSkillIDbyIndex(selectindex, i-1)
			local SkillLevelUpID,WantGoodsID,GoodsCostYB,WantMoney,HighestSkillID,WantHighestYB = Pet:GetPetSkillLevelupInfo(skillID,selectindex)
			if WantGoodsID==-1 or HighestSkillID==-1 then
				PETSKILL_BUTTONS_RED[k]:Show()
			else
				PETSKILL_BUTTONS_RED[k]:Hide()
			end

--local f=assert(io.open("petlevelup.log","wr+"))
--f:write(string.format("%d %d %d %d\r",i,k,SkillLevelUpID,HighestSkillID))
--f:close()
			k = k+1;
		end
		i = i + 1;
	end

	if( g_selectindex ~= -1 )then
		Pet:SetPetLocation(g_selectindex,-1);
	end

	g_selectindex = selectindex
end

function PetLevelup_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1) then
		PetLevelup_PetModel:RotateBegin(-0.3);
	--向左旋转结束
	else
		PetLevelup_PetModel:RotateEnd();
	end
end

function PetLevelup_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1) then
		PetLevelup_PetModel:RotateBegin(0.3);
	--向右旋转结束
	else
		PetLevelup_PetModel:RotateEnd();
	end
end


--鼠标左击PetLevelup_Skill1等控件，选中某一个技能
function PetLevelup_Skill_Clicked(nSkillIndex)
	if( -1 == g_selectindex ) then
		return;
	end
	
	local i=1;
	local k=1;

	while i <= PETSKILL_BUTTONS_NUM do --中间可能有空的技能，而显示的时候是往前塞的，所以要找到显示的技能对应的实际位置
		local theSkillAction = Pet:EnumPetSkill( g_selectindex, i-1, "petskill");
		if theSkillAction:GetID() ~= 0 then
			if k == nSkillIndex then
				g_selectskill = i-1

				--当前技能是否可以升级
				local skillID = Pet:GetSkillIDbyIndex(g_selectindex,g_selectskill)
				local SkillLevelUpID,WantGoodsID,GoodsCostYB,WantMoney,HighestSkillID,WantHighestYB = Pet:GetPetSkillLevelupInfo(skillID,g_selectindex)
				--技能是否可以升级
				if WantGoodsID == -1 then
					g_selectskill = -1
					PushDebugMessage("#{ZSYH_170111_52}")
					return
				end
				if HighestSkillID==-1 then
					PetLevelup_CancelSkill()
					PushDebugMessage("#{ZSYH_170111_52}")
					return
				end


				PetLevelup_Skill02:SetActionItem(theSkillAction:GetID());
				--升级需要消耗的道具
				PetLevelup_UpdateRequireGood()
				break;
			end
			
			k = k+1;
		end
		
		i = i + 1;
	end

end
function PetLevelup_UpdateRequireGood()
	PetLevelup_Skill03:SetActionItem(-1);

--PushDebugMessage("UpdateRequireGood g_selectindex="..g_selectindex.." g_selectskill="..g_selectskill)
	--升级需要消耗的道具
	if g_selectindex == -1 then
		return
	end

	--是否选技能
	if g_selectskill == -1 then
		return
	end

	local skillID = Pet:GetSkillIDbyIndex(g_selectindex,g_selectskill)
	local SkillLevelUpID,WantGoodsID,GoodsCostYB,WantMoney,HighestSkillID,WantHighestYB = Pet:GetPetSkillLevelupInfo(skillID,g_selectindex)
	--技能是否可以升级
	if WantGoodsID == -1 or HighestSkillID==-1 then
		return
	end
	

	local ProductAction = Pet:UpdateProductAction( WantGoodsID )
	if ProductAction and ProductAction:GetID() ~= 0 then
		PetLevelup_Skill03:SetActionItem(ProductAction:GetID());
	end

	local i=1
	local k=1
	while i <= PETSKILL_BUTTONS_NUM do
		local theSkillAction = Pet:EnumPetSkill( g_selectindex, i-1, "petskill");
		if theSkillAction:GetID() ~= 0 then
			--技能是否可以升级
			local iSkillID = Pet:GetSkillIDbyIndex(g_selectindex, i-1)
			if iSkillID==skillID then
				PETSKILL_BUTTONS[k]:SetPushed(1);
			else
				PETSKILL_BUTTONS[k]:SetPushed(0);
			end
			k = k+1;
		end
		i = i + 1;
	end

	PetLevelup_Money1:SetProperty("MoneyNumber", tostring(WantMoney))
	PetLevelup_Accept:Enable()
	PetLevelup_Up:Enable()
	PetLevelup_Animate:Play(true)
end

--这个函数跟前面不一样的地方是技能索引是玩家身上实际索引，而不是图标索引，所以需要新写一个函数
--选中某一个技能
function PetLevelup_Skill_Drag(nSkillIndex, bNotice)
	if( -1 == g_selectindex ) then
		return;
	end
	
	local theSkillAction = Pet:EnumPetSkill( g_selectindex, nSkillIndex, "petskill");
	if theSkillAction:GetID() ~= 0 then
		g_selectskill = nSkillIndex

		--当前技能是否可以升级
		local skillID = Pet:GetSkillIDbyIndex(g_selectindex,g_selectskill)
		local SkillLevelUpID,WantGoodsID,GoodsCostYB,WantMoney,HighestSkillID,WantHighestYB = Pet:GetPetSkillLevelupInfo(skillID,g_selectindex)
		--技能是否可以升级
		if WantGoodsID == -1  then
			g_selectskill = -1
--			if bNotice==1 then
--				PushDebugMessage("#{ZSYH_170111_52}")
--			end
			return
		end
		if HighestSkillID == -1 then
			PetLevelup_CancelSkill()
--			if bNotice==1 then
--				PushDebugMessage("#{ZSYH_170111_52}")
--			end
			return
		end

		PetLevelup_Skill02:SetActionItem(theSkillAction:GetID());
		--升级需要消耗的道具
		PetLevelup_UpdateRequireGood()
	end

end

function PetLevelup_UpdateGoods(nGoodsIndex, bNotice)

	--if g_PageIdx~=0 then	return end;

	local theAction = EnumAction(nGoodsIndex, "packageitem");
	
	if theAction:GetID() ~= 0 then

		local goodsID = PlayerPackage : GetItemTableIndex( nGoodsIndex )
		if g_selectgood ~= -1 then
			LifeAbility : Lock_Packet_Item(g_selectgood,0);
		end
		--是否加锁....
		if PlayerPackage:IsLock(nGoodsIndex) == 1 then
			if bNotice==1 then
				PushDebugMessage("#{Item_Locked}")
			end
			return
		end
		
		--是否选技能
		if g_selectskill == -1 then
			if bNotice==1 then
				PushDebugMessage("#{JNHC_81015_06}")
			end
			return
		end
		
		local skillID = Pet:GetSkillIDbyIndex(g_selectindex,g_selectskill)
		local SkillLevelUpID,WantGoodsID,GoodsCostYB,WantMoney,HighestSkillID,WantHighestYB = Pet:GetPetSkillLevelupInfo(skillID,g_selectindex)
		
		--技能是否可以升级
		if WantGoodsID == -1 then
			if bNotice==1 then
				PushDebugMessage("#{JNHC_81015_03}")
			end
			return
		end

		if HighestSkillID == -1 then
			PetLevelup_CancelSkill()
			if bNotice==1 then
				PushDebugMessage("#{ZSYH_170111_52}")
			end
			return
		end
		
		if goodsID ~= WantGoodsID then
			if bNotice==1 then
				PushDebugMessage("#{JNHC_81015_04}")
			end
			return
		end

		g_ConsumeGoodsID = WantGoodsID
		g_ConsumeMoney = WantMoney


		--如果前面选了物品，则让之前的东西变亮
		PetLevelup_Skill01:SetActionItem(theAction:GetID());
		g_selectgood = nGoodsIndex;
		LifeAbility : Lock_Packet_Item(g_selectgood,1);
		--todo wangye
	else
		PetLevelup_CancelGoods()
	end
	
end

function PetLevelup_Btn_Click(nIndex)
	if nIndex == 1 then --取消物品
		PetLevelup_CancelGoods()
	elseif nIndex == 2 then	--取消技能
		PetLevelup_CancelSkill()
	end
end

--"升级"按钮
function PetLevelup_Do()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{JJTZ_090826_26}")
		return
	end
	--判断电话密保和二级密码保护
  if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
    return
  end
	--是否选珍兽
	if g_selectindex == -1 then
		PushDebugMessage("#{JNHC_81015_05}")
		return
	end

	--是否选技能
	if g_selectskill == -1 then
		PushDebugMessage("#{ZSYH_170111_62}")
		return
	end
	--技能是否可以升级
	local skillID = Pet:GetSkillIDbyIndex(g_selectindex,g_selectskill)
	local SkillLevelUpID,WantGoodsID,GoodsCostYB,WantMoney,HighestSkillID,WantHighestYB = Pet:GetPetSkillLevelupInfo(skillID,g_selectindex)

	if WantGoodsID==-1 or WantMoney==-1 or SkillLevelUpID==-1 or HighestSkillID==-1 then
		PushDebugMessage("#{ZSYH_170111_63}")
		return
	end

	--是否选灵兽丹物品
	if g_selectgood == -1 then
		--未放入灵兽丹物品
		--元宝确认
		if PetLevelup_Blank_ButtonCheck:GetCheck() == 1 then
			PushEvent("PETSKILLLEVELUP_CONFIRM","lingshoudan",skillID,WantGoodsID,GoodsCostYB)
			return
		else
			--元宝够不
			local curYB=Player:GetData("YUANBAO")
			if curYB<GoodsCostYB then
				PushDebugMessage("#{ZSYH_170111_65}")
				return
			end
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("PetSkillLevelupItemBuy");
				Set_XSCRIPT_ScriptID(311112);
				Set_XSCRIPT_Parameter(0,skillID);
				Set_XSCRIPT_Parameter(1,WantGoodsID);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
			return
		end
	else
		if g_ConsumeGoodsID ~= PlayerPackage:GetItemTableIndex(g_selectgood) then
			PushDebugMessage("#{ZSYH_170111_110}")
			return
		end
	end

	--是否金钱足够
	if Player:GetData("MONEY")+Player:GetData("MONEY_JZ") < g_ConsumeMoney then
		PushDebugMessage("#{JNHC_81015_08}")--我觉得这个字典更好
		return
	end

	local hid,lid = Pet:GetGUID(g_selectindex)

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("PetSkillLevelup");
		Set_XSCRIPT_ScriptID(311112);
		Set_XSCRIPT_Parameter(0,hid);
		Set_XSCRIPT_Parameter(1,lid);
		Set_XSCRIPT_Parameter(2,g_selectskill);
		Set_XSCRIPT_Parameter(3,g_selectgood);
		Set_XSCRIPT_Parameter(4,0);
		Set_XSCRIPT_ParamCount(5);
	Send_XSCRIPT();

end

--"快捷提升"按钮
function PetLevelup_QuickDo()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{JJTZ_090826_26}")
		return
	end
	--判断电话密保和二级密码保护
  if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
    return
  end
  --是否选珍兽
	if g_selectindex == -1 then
		PushDebugMessage("#{JNHC_81015_05}")
		return
	end
	--是否选技能
	if g_selectskill == -1 then
		PushDebugMessage("#{ZSYH_170111_62}")
		return
	end

	--元宝够否
	local skillID = Pet:GetSkillIDbyIndex(g_selectindex,g_selectskill)
	local SkillLevelUpID,WantGoodsID,GoodsCostYB,WantMoney,HighestSkillID,WantHighestYB = Pet:GetPetSkillLevelupInfo(skillID,g_selectindex)
	if SkillLevelUpID==-1 or HighestSkillID==-1 then
		PushDebugMessage("#{ZSYH_170111_63}")
		return
	end

	local hid,lid = Pet:GetGUID(g_selectindex)
	--无视确认按钮
	PushEvent("PETSKILLLEVELUP_CONFIRM","quick",hid,lid,g_selectskill,g_selectgood,skillID,HighestSkillID,WantHighestYB)
end

function PetLevelup_Frame_On_ResetPos()
  PetLevelup_Frame:SetProperty("UnifiedPosition", g_PetLevelup_Frame_UnifiedPosition);
end

function PetLevelup_UpdateMoney()
	PetLevelup_Money3:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	PetLevelup_Money2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
end

