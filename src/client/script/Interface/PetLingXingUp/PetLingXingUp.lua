local m_UI_NUM = 20090805	--珍兽灵性提升

local m_PetIndex = -1
local m_ObjCared = -1
local g_Lingxing_YBConfirm = 1 --add:lby2015
--灵性1-10的金钱消耗
local m_money = { 10000 , 12000 , 14400 ,17280 , 20736,  24883 , 29860 , 35832 ,42998 , 51598}

-- 灵性等级对应元宝
local m_YuanBaoCosts = {
	[0] = 29880,
	[1] = 29760,
	[2] = 29560,
	[3] = 29220,
	[4] = 28620,
	[5] = 27600,
	[6] = 26040,
	[7] = 23560,
	[8] = 19340,
	[9] = 12960,
}

--【修改人：陈永帅】
--【TT：78725】
function PetLingXingUp_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "REPLY_MISSION_PET", false )						-- 玩家从列表选定一只珍兽
	--this : RegisterEvent( "UPDATE_PET_PAGE" )						-- 玩家身上的珍兽数据发生变化，包括增加一只珍兽
	this : RegisterEvent( "DELETE_PET" )							-- 玩家身上减少一只珍兽
	this : RegisterEvent("MONEY_CHANGE_EX", false);
	this : RegisterEvent("MONEYJZ_CHANGE_EX", false)	
	this : RegisterEvent("QUICKUP_PET_SENDMSG")
end



function PetLingXingUp_OnLoad()

--PetLingXingUp_Yuanbao_Bind:SetCheck(g_Lingxing_YBConfirm) --add:lby2015

end



function PetLingXingUp_OnEvent(event)

	if event == "UI_COMMAND" and tonumber( arg0 ) == m_UI_NUM then
		
		if this : IsVisible() then
			return
		end
		
		local check  = tonumber(Pet:GetYuanbaoBuyState(1));--add:lby 2015
		if(check>=1)then
			PetLingXingUp_Yuanbao_Bind:SetCheck(0);
		else
			PetLingXingUp_Yuanbao_Bind:SetCheck(1);
		end	
		
		PetLingXingUp_CleanUp()
		PetLingXingUp_BeginCareObj( Get_XParam_INT(0) );
		this:Show()
		Pet : ShowPetList( 1 )
		PetLingXingUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetLingXingUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
			
		PetLingXingUp_Quick_Up : Disable()
		PetLingXingUp_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
		PetLingXingUp_Quick_Up_Animate:Play(false)

	elseif (event == "MONEY_CHANGE_EX" and this : IsVisible()) then
		PetLingXingUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetLingXingUp_UICheck()
	elseif (event == "MONEYJZ_CHANGE_EX" and this : IsVisible() ) then
		PetLingXingUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		PetLingXingUp_UICheck()
	elseif event == "REPLY_MISSION_PET" and this : IsVisible() then
		
		PetLingXingUp_OnSelectPet( tonumber( arg0 ) )
	elseif event == "UPDATE_PET_PAGE"  and this:IsVisible() then
		PetLingXingUp_CleanUp()
	elseif event == "DELETE_PET"  and this:IsVisible() then
		this:Hide()
	end
	
	if (event == "QUICKUP_PET_SENDMSG") and (tonumber(arg0) == 2) then
		PetLingXingUp_Quick_ExeLXUp()
	end

end


--Close
function PetLingXingUp_Close_Window()

	--关闭二次确认界面
	PushEvent("CONVENIENT_BUY_CONFIRM_CLOSE");
	
	this:Hide();
end

--OK
function PetLingXingUp_OK_Clicked()

	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	if m_PetIndex == -1  then
		return
	end
	
	local isExist = IsItemExist(20310116)
	if isExist == 0 then
		isExist = IsItemExist(20310160)
		if isExist == 0 then
			isExist = IsItemExist(20310175)
			if isExist == 0 then
				--PushDebugMessage("#{RXZS_090804_15}")  --你身上缺少灵性提升材料：灵兽精魄。
				--增加自己的函数
				PetYuanbaoBuyLingxingAsk()
				return
			end
		end
	end
	local hid,lid = Pet:GetGUID(m_PetIndex);
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Pet_LXUP" )
		Set_XSCRIPT_ScriptID( 800124 )
		Set_XSCRIPT_Parameter( 0, hid )
		Set_XSCRIPT_Parameter( 1, lid )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
end

function PetLingXingUp_Quick_Check()
	--增加15级判断
	local mylevel = Player:GetData("LEVEL");
	if mylevel < 15 then
		PushDebugMessage("#{ZSKJT_130717_01}")
		return 0
	end
	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return 0
	end
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return 0
	end
	
	if m_PetIndex == -1  then
		ShowSystemTipInfo( "#{ZSKJT_130428_9}" )
		return 0
	end
	
	-- 判断当前珍兽的灵性是否小于10
	local lingxing = Pet : GetLixing( m_PetIndex )
	if lingxing >= 10 then 
		ShowSystemTipInfo("#{RXZS_090804_14}")
		return 0
	end
	
	-- 判断是否幻化
	local nGen = Pet : GetType( m_PetIndex ) 
	if nGen ~= nil and nGen < 100 then	--100以上为幻化珍兽
		ShowSystemTipInfo("#{RXZS_090804_13}")    --你选择的珍兽还未幻化，只有幻化后的珍兽才能提升灵性。
		return 0
	end
		
	return 1
end

function PetLingXingUp_Quick_OK_Clicked()
	if PetLingXingUp_Quick_Check() == 1 then 	
		local lingxing = Pet : GetLixing( m_PetIndex )	
		local petName = Pet : GetPetList_Appoint( m_PetIndex )
		local cost = m_YuanBaoCosts[lingxing]
		--弹出确认框
		PushEvent("QUICKUP_PET_CONFIRM", 2, tonumber(lingxing), tonumber(cost),0, tostring(petName))
	end
end

function PetLingXingUp_Quick_ExeLXUp()
	if PetLingXingUp_Quick_Check() == 1 then 	
		local hid,lid = Pet:GetGUID(m_PetIndex);
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Quick_Pet_LXUP" )
			Set_XSCRIPT_ScriptID( 800124 )
			Set_XSCRIPT_Parameter( 0, hid )
			Set_XSCRIPT_Parameter( 1, lid )
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
	end
end

--Select Pet
function PetLingXingUp_SelectPet_Clicked()
	Pet : ShowPetList( 0 )
	Pet : ShowPetList( 1 )			
	if  m_PetIndex ~= -1 then
		local lingxing = Pet : GetLixing( m_PetIndex )	
		if lingxing >= 10 then	
			PetLingXingUp_Quick_Up : Disable()
			PetLingXingUp_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
			PetLingXingUp_Quick_Up_Animate:Play(false)
		end
	end
end




function PetLingXingUp_Pet_Modle_TurnLeft( start )
	--向左旋转开始
	if(start == 1) then
		PetLingXingUp_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		PetLingXingUp_FakeObject:RotateEnd();
	end

end


function PetLingXingUp_Pet_Modle_TurnRight( start )
	--向右旋转开始
	if(start == 1) then
		PetLingXingUp_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		PetLingXingUp_FakeObject:RotateEnd();
	end
end


function PetLingXingUp_OnHidden()

	Pet:ShowPetList(0);
	PetLingXingUp_CleanUp()
	
	--关闭二次确认界面
	PushEvent("CONVENIENT_BUY_CONFIRM_CLOSE");
end


function PetLingXingUp_OnSelectPet(petIndex)
	
	if( -1 == petIndex ) then
		return;
	end
	
	--珍兽已被其它界面选中
	if (Pet:GetPetLocation(petIndex) ~= -1) then
		return;
	end

	--未幻化
	local gen = Pet:GetType(petIndex)
	if gen ~= nil and gen < 100 then	--100以上为幻化珍兽
		PushDebugMessage("#{RXZS_090804_13}")    --你选择的珍兽还未幻化，只有幻化后的珍兽才能提升灵性。
		return
	end
	--封顶了
	if gen ~= nil and gen >= 110 then
		PushDebugMessage("#{RXZS_090804_14}")    --你选择的珍兽灵性等级已经达到最高，不能再次提升灵性。
		return
	end

	PetLingXingUp_FakeObject:SetFakeObject("");
	Pet:SetSkillStudyModel(petIndex);

	PetLingXingUp_FakeObject:SetFakeObject( "My_PetStudySkill" );
	

	--切换珍兽的时候，释放上一个珍兽
	if(m_PetIndex ~= -1) then
		Pet:SetPetLocation(m_PetIndex,-1);
	end

	m_PetIndex = petIndex;	--已经选好了珍兽
	Pet:SetPetLocation(m_PetIndex,10);
--	Pet:ClosePetSkillStudyMsgBox()

	PetLingXingUp_UICheck()

end


function PetLingXingUp_CleanUp()
	PetLingXingUp_Money:SetProperty("MoneyNumber", 0 );
	PetLingXingUp_Pet_Text:SetText("")
	PetLingXingUp_OK:Disable()
	PetLingXingUp_Quick_Up:Disable()
	PetLingXingUp_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
	PetLingXingUp_Quick_Up_Animate:Play(false)

	PetLingXingUp_FakeObject:SetFakeObject("");

	PetLingXingUp_Probability_Percent:SetText("")
	PetLingXingUp_Wuxing_Percent:SetText("")

	if(m_PetIndex ~= -1) then
		Pet:SetPetLocation(m_PetIndex,-1);
	end
	m_PetIndex = -1
end


function PetLingXingUp_UICheck()
	
	PetLingXingUp_Money:SetProperty("MoneyNumber", 0 );
	PetLingXingUp_Pet_Text:SetText("")
	PetLingXingUp_OK:Disable()
	PetLingXingUp_Quick_Up:Enable()
	PetLingXingUp_Quick_Up : SetText( "#{ZSKJT_130428_1}" )
	PetLingXingUp_Quick_Up_Animate:Play(true)
	if  m_PetIndex ~= -1 then
		local szPetName,szOn = Pet:GetPetList_Appoint(m_PetIndex);
		if  szOn ~= "on_packa"  then 
			Pet:SetPetLocation(m_PetIndex,-1);
			m_PetIndex = -1;
			PetLingXingUp_FakeObject:SetFakeObject("");
			PetLingXingUp_Probability_Percent:SetText("")
			PetLingXingUp_Wuxing_Percent:SetText("")
			return
		end
		
		local strName , strName2 = Pet:GetName(m_PetIndex)
		PetLingXingUp_Pet_Text:SetText(strName)	
		
		local gen = Pet:GetType(m_PetIndex)
		if gen >= 100 and gen < 110 then				 --100以上为幻化珍兽
			PetLingXingUp_Money:SetProperty("MoneyNumber", m_money[gen - 99] );	
			local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ") 

			if selfMoney >=  m_money[gen - 99]  then
				PetLingXingUp_OK:Enable()
			end
			
			local upRate = Pet:GetRate_LxUp(m_PetIndex)
			PetLingXingUp_Probability_Percent:SetText(upRate.."%")
			local upPercent = Pet:GetPercent_LxUp(m_PetIndex)
			local perStr = string.format("%0.1f" , upPercent / 10.0)
			PetLingXingUp_Wuxing_Percent:SetText(perStr.."%")
		else
			PetLingXingUp_Probability_Percent:SetText("")
			PetLingXingUp_Wuxing_Percent:SetText("")
		end
	end
end


--Care Obj
function PetLingXingUp_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end



function PetLingxing_YBPay_Clicked() --add:lby2015增加元宝确认购买
	--if g_Lingxing_YBConfirm==1 then
	--	g_Lingxing_YBConfirm = 0
--	else
	--	g_Lingxing_YBConfirm = 1
	--end
	--PetLingXingUp_Yuanbao_Bind:SetCheck(g_Lingxing_YBConfirm)
		local check  = tonumber(Pet:GetYuanbaoBuyState(1));
	
		if(check>=1)then
			PetLingXingUp_Yuanbao_Bind:SetCheck(1);
			Pet:SetYuanbaoBuyState(1, 0);
		else
			PetLingXingUp_Yuanbao_Bind:SetCheck(0);
			Pet:SetYuanbaoBuyState(1, 1);
		end	
	
end

--add:lby2015
function PetYuanbaoBuyLingxingAsk()


	local _material = 20310116

	local check  = tonumber(Pet:GetYuanbaoBuyState(1))
	
	if check == 1 then
			--不提示 自动购买
		
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("PetLingxing_Yuanbao_Pay")
				Set_XSCRIPT_ScriptID(800124)
				Set_XSCRIPT_Parameter(0,_material)
				Set_XSCRIPT_Parameter(1,0)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
			return 
		elseif check == 0 then
				
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("PetLingxing_Yuanbao_Pay")
				Set_XSCRIPT_ScriptID(800124)
				Set_XSCRIPT_Parameter(0,_material)
				Set_XSCRIPT_Parameter(1,1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
			return
		else return end

end