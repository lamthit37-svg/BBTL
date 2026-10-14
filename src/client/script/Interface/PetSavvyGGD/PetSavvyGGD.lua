-- PetSavvyGGD.lua
-- 珍兽提升悟性（用根骨丹）

local mainPet = { idx = -1, guid = { high = -1, low = -1 } }
local assisPet = { idx = -1, guid = { high = -1, low =-1 } }

local theNPC = -1													-- 功能 NPC
local MAX_OBJ_DISTANCE = 3.0
local g_PetSavvyGGD_YuanbaoPay=1

local currentChoose = -1

local moneyCosts = {													-- 索引是珍兽的当前悟性值
	[0] = 100,
	[1] = 110,
	[2] = 121,
	[3] = 133,
	[4] = 146,
	[5] = 161,
	[6] = 177,
	[7] = 194,
	[8] = 214,
	[9] = 235,
	[10] = 25937,
	[11] = 28531,
	[12] = 31384,
	[13] = 34523,
	[14] = 37975,
}
-- 悟性等级对应元宝
local YuanBaoCosts = {
	[0] = 28880,
	[1] = 28860,
	[2] = 28820,
	[3] = 28740,
	[4] = 28580,
	[5] = 28380,
	[6] = 27780,
	[7] = 25840,
	[8] = 24120,
	[9] = 500,
}

local WX_10 = 0
local WX_15 = 1
local UI_TYPE = 0

local g_PetSavvyGGD_Frame_UnifiedPosition;

function PetSavvyGGD_PreLoad()
	this : RegisterEvent( "UI_COMMAND",true )
	this : RegisterEvent( "REPLY_MISSION_PET",false )				-- 玩家从列表选定一只珍兽
	this : RegisterEvent( "UPDATE_PET_PAGE",false )					-- 玩家身上的珍兽数据发生变化
	this : RegisterEvent( "DELETE_PET",false )							-- 玩家身上减少一只珍兽
	this : RegisterEvent( "OBJECT_CARED_EVENT",false )			-- 关心 NPC 的存在和范围
	this : RegisterEvent( "MONEY_CHANGE_EX",false );
	this : RegisterEvent( "MONEYJZ_CHANGE_EX",false )					--交子普及 Vega
	this : RegisterEvent( "OPEN_EXCHANGE_FRAME",false );		--打开交易界面
	this : RegisterEvent("ADJEST_UI_POS",false)
	this : RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this : RegisterEvent("QUICKUP_PET_SENDMSG",true)				--二次确认
end

function PetSavvyGGD_OnLoad()
	PetSavvyGGD_Clear()
	 g_PetSavvyGGD_Frame_UnifiedPosition=PetSavvyGGD_Frame:GetProperty("UnifiedPosition");
end


function PetSavvyGGD_OK_Clicked()

	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	-- 首先判定玩家是否放入需要提升的珍兽，如果没有放入NPC将会弹出对话并返回：
	if mainPet.idx == -1 then
	-- 请放入您要提升悟性等级的珍兽。
		ShowSystemTipInfo( "请放入您要提升悟性等级的珍兽。" )
		return
	end

	-- 判定玩家的金钱是否足够，如果不够将会弹出对话。
	local savvy = Pet : GetSavvy( mainPet.idx )
	local cost = moneyCosts[savvy]
	if not cost then
		cost = 0
	end	

	-- 您的金钱不足，请确认
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ");	--交子普及 Vega
	if selfMoney < cost then
		ShowSystemTipInfo( "您的金钱不足，请确认。" )
		return
	end
	
	--检查根骨丹
	local nSavvyNeed = savvy+1;	
	local nItemIdGenGuDan = 0;
	local nItemIdGenGuDanBind = 0; --绑定的根骨丹
	local msgTemp;
	
	if nSavvyNeed >= 1 and nSavvyNeed <= 3 then
		msgTemp = "低";
		nItemIdGenGuDan = 30502000;
		nItemIdGenGuDanBind = 30504038;
	elseif nSavvyNeed >= 4 and nSavvyNeed <= 6 then
		msgTemp = "中"
		nItemIdGenGuDan = 30502001;
		nItemIdGenGuDanBind = 30503187;
	elseif nSavvyNeed >= 7 and nSavvyNeed <= 10 then
		msgTemp = "高"
		nItemIdGenGuDan = 30502002;
		nItemIdGenGuDanBind = 30503188;
	elseif nSavvyNeed >= 11 and nSavvyNeed <= 15 then
		msgTemp = "超"
		nItemIdGenGuDan = 30502004;
	end
	
	local bExist = IsItemExist( nItemIdGenGuDan );
	if(bExist <= 0 and nItemIdGenGuDanBind ~= 0) then
		bExist = IsItemExist( nItemIdGenGuDanBind );
	end
	
	if bExist <= 0 then
		local msg = "提升该珍兽悟性到"..nSavvyNeed.."需要"..msgTemp.."级根骨丹。";
		PetSavvyGGD_GGD : SetText( msg );
		--SetNotifyTip( msg );
		--return;
	end
	
	-- 发送 UI_Command 进行合成
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PetSavvy" )
		Set_XSCRIPT_ScriptID( 800106 )
		Set_XSCRIPT_Parameter( 0, mainPet.guid.high )
		Set_XSCRIPT_Parameter( 1, mainPet.guid.low )	
		Set_XSCRIPT_Parameter( 2, g_PetSavvyGGD_YuanbaoPay )			
		Set_XSCRIPT_ParamCount( 3 )
	Send_XSCRIPT()
	
end

-- 快捷提升
function PetSavvyGGD_check()
	--增加15级判断
	local mylevel = Player:GetData("LEVEL");
	if mylevel < 15 then
		PushDebugMessage("#{ZSKJT_130717_01}")
		return 1
	end
	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return 1
	end
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return 1
	end
	
	-- 首先判定玩家是否放入需要提升的珍兽，如果没有放入NPC将会弹出对话并返回：
	if mainPet.idx == -1 then
	-- 请放入您要提升悟性等级的珍兽。
		ShowSystemTipInfo( "#{ZSKJT_130428_3}" )
		return 1
	end
	
	-- 判断当前珍兽的悟性是否小于10
	local savvy = Pet : GetSavvy( mainPet.idx )
	if savvy >= 10 then 
		PushDebugMessage("#{ZSKJT_130428_4}")
		return 1
	end
	
	return 0
end

function PetSavvyGGD_Quick_Up_Clicked()
	if PetSavvyGGD_check() == 0 then 
		local savvy = Pet : GetSavvy( mainPet.idx )	
		local petName = Pet : GetPetList_Appoint( mainPet.idx )
		local cost = YuanBaoCosts[savvy]
		--弹出确认框
		PushEvent("QUICKUP_PET_CONFIRM", 1, tonumber(savvy), tonumber(cost),0, tostring(petName))
	end	
end

function PetSavvyGGD_ExeScript()	
	if PetSavvyGGD_check() == 0 then 
		-- 发送 UI_Command 进行合成
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "QuickPetSavvy" )
			Set_XSCRIPT_ScriptID( 800106 )
			Set_XSCRIPT_Parameter( 0, mainPet.guid.high )
			Set_XSCRIPT_Parameter( 1, mainPet.guid.low )		
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
	end
	
end

-- 关闭、取消
function PetSavvyGGD_Cancel_Clicked()

	--关闭二次确认界面
	PushEvent("CONVENIENT_BUY_CONFIRM_CLOSE");
	
	this : Hide()
end

-- 选择珍兽
function PetSavvyGGD_SelectPet( petIdx )
	if -1 == petIdx then
		return
	end
	
	--珍兽已被其它界面选中
	if (Pet:GetPetLocation(petIdx) ~= -1) then
		return;
	end
	
	local petName = Pet : GetPetList_Appoint( petIdx )
	local guidH, guidL = Pet : GetGUID( petIdx )


	-- 如果原来已经选择了一个被提升的宠
	-- 则清空原来的数据
	PetSavvyGGD_RemoveMainPet()
	
	local savvy = Pet : GetSavvy( petIdx )
	local nGen = Pet:GetType(petIdx) ;
	
	if UI_TYPE == WX_10 then
		if savvy <=9 then
			-- 将珍兽名字填到文本框中
			PetSavvyGGD_Pet : SetText( petName )
			-- 给珍兽上锁，设置珍兽已经提交到3号界面容器
			Pet : SetPetLocation( petIdx, 3 )
			-- 更新珍兽列表界面
			Pet:UpdatePetList()	
		else
			PetSavvyGGD_Pet : SetText( "" )
			PetSavvyGGD_GGD : SetText( "" )
			PetSavvyGGD_NeedMoney : SetProperty( "MoneyNumber", 0 )
			PetSavvyGGD_Text2 : SetText( "无法提升" )
			PetSavvyGGD_OK:Disable();
			PetSavvyGGD_Quick_Up:Disable();
			PetSavvyGGD_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
			PetSavvyGGD_Quick_Up_Animate:Play(false)
			return
		end
	end

	if UI_TYPE == WX_15 then
		
		PetSavvyGGD_Pet : SetText( "" )
		PetSavvyGGD_GGD : SetText( "" )	
		PetSavvyGGD_NeedMoney : SetProperty( "MoneyNumber", 0 )
		PetSavvyGGD_Text2 : SetText( "" )
		PetSavvyGGD_OK:Disable();
		PetSavvyGGD_Quick_Up:Disable();
		PetSavvyGGD_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
		PetSavvyGGD_Quick_Up_Animate:Play(false)
		
		--幻化珍兽
		if nGen >= 100 then
			if savvy < 15 then
				if savvy >= 10 then
					-- 将珍兽名字填到文本框中
					PetSavvyGGD_Pet : SetText( petName )
					-- 给珍兽上锁，设置珍兽已经提交到3号界面容器
					Pet : SetPetLocation( petIdx, 3 )
					-- 更新珍兽列表界面
					Pet:UpdatePetList()
				else
					SetNotifyTip("#{RXZS_090804_26}")	--悟性≥10的珍兽才能使用超级根骨丹提升悟性。
					return
				end
			else
				--幻化珍兽悟性大于14就不能再提升了....
				SetNotifyTip("#{RXZS_090804_27}")	--你的珍兽悟性已提升到15，不能再向上提升了。
				return
			end
		else
			--非幻化珍兽
			SetNotifyTip("#{RXZS_090804_25}")	--只有幻化后，且悟性≥10的珍兽才能使用超级根骨丹提升悟性。
			return
		end
	end

	-- 记录该宠的位置号、GUID
	mainPet.idx = petIdx
	mainPet.guid.high = guidH
	mainPet.guid.low = guidL
	
	--更新金钱和几率显示
	PetSavvyGGD_CalcSuccOdds()
	PetSavvyGGD_CalcCost()
	--检查 跟骨 丹
	local nSavvyNeed = savvy+1;	
	local nItemIdGenGuDan = 0;
	local msgTemp;
	
	if nSavvyNeed >= 1 and nSavvyNeed <= 3 then
		msgTemp = "低";		
	elseif nSavvyNeed >= 4 and nSavvyNeed <= 6 then
		msgTemp = "中"		
	elseif nSavvyNeed >= 7 and nSavvyNeed <= 10 then
		msgTemp = "高"		
	elseif nSavvyNeed >= 11 and nSavvyNeed <= 15 then
		msgTemp = "超"		
	end
	
	local bExist = IsItemExist( nItemIdGenGuDan );
	
	if bExist <= 0 then
		local msg = "提升该珍兽悟性到"..nSavvyNeed.."需要"..msgTemp.."级根骨丹。";
		PetSavvyGGD_GGD : SetText( msg );		
		return;
	end

end

function PetSavvyGGD_OnEvent(event)

	--PushDebugMessage("PetSavvyGGD : "..event);

	if event == "UI_COMMAND" and tonumber( arg0 ) == 19820425 then	-- 打开界面
		if this : IsVisible() then									-- 如果界面开着，则不处理
			return
		end
		UI_TYPE = WX_10
		PetSavvyGGD_Text:SetText("#{INTERFACE_XML_1030}")

		this : Show()
		PetSavvyGGD_Pet : SetText( "" )
		PetSavvyGGD_Text2 : SetText( "" )
		PetSavvyGGD_NeedMoney:SetProperty("MoneyNumber", tostring(0));
		local npcObjId = Get_XParam_INT( 0 )
		BeginCareObject( npcObjId )
		PetSavvyGGD_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetSavvyGGD_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		PetSavvyGGD_OK:Disable();
		PetSavvyGGD_Quick_Up:Disable();
		PetSavvyGGD_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
		PetSavvyGGD_Quick_Up_Animate:Play(false)
		--yuanbaoPay
		if g_PetSavvyGGD_YuanbaoPay == 1 or g_PetSavvyGGD_YuanbaoPay == 0 then
			PetSavvyGGD_Blank_Queren:SetCheck(g_PetSavvyGGD_YuanbaoPay)
		end
		return
	end

	if event == "UI_COMMAND" and tonumber(arg0) == 20090812 then
		if this : IsVisible() then									-- 如果界面开着，则不处理
			return
		end
		UI_TYPE = WX_15
		PetSavvyGGD_Text:SetText("#{RXZS_XML_32}")

		this : Show()
		PetSavvyGGD_Pet : SetText( "" )
		PetSavvyGGD_Text2 : SetText( "" )
		PetSavvyGGD_NeedMoney:SetProperty("MoneyNumber", tostring(0));
		local npcObjId = Get_XParam_INT( 0 )
		BeginCareObject( npcObjId )
		PetSavvyGGD_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetSavvyGGD_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		PetSavvyGGD_OK:Disable();
		PetSavvyGGD_Quick_Up:Disable();
		PetSavvyGGD_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
		PetSavvyGGD_Quick_Up_Animate:Play(false)
		--yuanbaoPay
		if g_PetSavvyGGD_YuanbaoPay == 1 or g_PetSavvyGGD_YuanbaoPay == 0 then
			PetSavvyGGD_Blank_Queren:SetCheck(g_PetSavvyGGD_YuanbaoPay)
		end
		return

	end

	-- 玩家选了一只珍兽
	if ( event == "REPLY_MISSION_PET" and this:IsVisible() )then
		--PetSavvyGGD_GGD : SetText( "" );
		PetSavvyGGD_SelectPet( tonumber( arg0 ) )
	
		PetSavvyGGD_SelfMoney_Text:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetSavvyGGD_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		return
	end

	-- 玩家身上的珍兽数据发生变化，包括珍兽出战、休息、增加一只珍兽
	if event == "UPDATE_PET_PAGE" and this : IsVisible() then
		PetSavvyGGD_UpdateSelected()
		PetSavvyGGD_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetSavvyGGD_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		return
	end

	-- 玩家身上减少一只珍兽
	if event == "DELETE_PET" and this : IsVisible() then
		PetSavvyGGD_UpdateSelected()
		PetSavvyGGD_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetSavvyGGD_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		return
	end

	-- 关心 NPC 的存在和范围
	if event == "OBJECT_CARED_EVENT" and this : IsVisible() then
		Pet : ShowPetList( 0 )
		if tonumber( arg0 ) ~= theNPC then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1 == "destroy" then			
			PetSavvyGGD_Cancel_Clicked()
		end
		return
	end

	if (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		PetSavvyGGD_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	end

	if (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		PetSavvyGGD_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	end
	
	-- 打开交易界面的同时关闭该界面，但是需要刷新一下珍兽列表
	if (event == "OPEN_EXCHANGE_FRAME" and this:IsVisible()) then
		StopCareObject()
		PetSavvyGGD_Clear()
		Pet : ShowPetList( 0 )
		Pet : ShowPetList( 1 )
		this:Hide()
	end
	
	 if (event == "ADJEST_UI_POS" ) then
		PetSavvyGGD_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetSavvyGGD_Frame_On_ResetPos()
	end
		
	if (event == "QUICKUP_PET_SENDMSG") and (tonumber(arg0) == 1) then
		PetSavvyGGD_ExeScript()
	end
end

-- 
function PetSavvyGGD_Blank_Queren_Clicked() 
	g_PetSavvyGGD_YuanbaoPay = PetSavvyGGD_Blank_Queren:GetCheck();
end

function PetSavvyGGD_Choose_Clicked( type )

	-- 关一下再开，清空数据
	Pet : ShowPetList( 0 )
	Pet : ShowPetList( 1 )
end


function PetSavvyGGD_Close()
	Pet : ShowPetList( 0 )
	StopCareObject()
	PetSavvyGGD_Clear()
	
	--关闭二次确认界面
	PushEvent("CONVENIENT_BUY_CONFIRM_CLOSE");
end

function PetSavvyGGD_RemoveMainPet()
	if mainPet.idx ~= -1 then
		Pet : SetPetLocation( mainPet.idx, -1 )
		-- 更新珍兽列表界面
		Pet:UpdatePetList()
	end

	mainPet.idx = -1
	mainPet.guid.high = -1
	mainPet.guid.low = -1
end

function PetSavvyGGD_Clear()
	PetSavvyGGD_RemoveMainPet()
	PetSavvyGGD_GGD : SetText( "" );
	PetSavvyGGD_Pet : SetText( "" );
	PetSavvyGGD_Text2 : SetText( "#cFF0000成功率" )
	PetSavvyGGD_NeedMoney : SetProperty( "MoneyNumber", tostring( 0 ) )

	PetSavvyGGD_OK : Disable()
	PetSavvyGGD_Quick_Up : Disable();
		PetSavvyGGD_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
	PetSavvyGGD_Quick_Up_Animate:Play(false)

	currentChoose = -1
end

-- 计算成功率
function PetSavvyGGD_CalcSuccOdds()
	if mainPet.idx == -1 then
		PetSavvyGGD_Text2 : SetText( "#cFF0000成功率" )
		PetSavvyGGD_OK : Disable()			
		PetSavvyGGD_Quick_Up : Disable();
		PetSavvyGGD_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
		PetSavvyGGD_Quick_Up_Animate:Play(false)
		return
	end

	succOdds = {													-- 索引是珍兽的当前悟性值
		[0] = 1000,
		[1] = 850,
		[2] = 750,
		[3] = 600,
		[4] = 200,
		[5] = 310,
		[6] = 310,
		[7] = 30,
		[8] = 70,
		[9] = 100,
		[10] = 30,
		[11] = 30,
		[12] = 30,
		[13] = 30,
		[14] = 30,

	}

	local savvy = Pet : GetSavvy( mainPet.idx )
	local str = "#cFF0000"
	local odds = succOdds[savvy]
	if not odds then
		str = "无法提升"
		PetSavvyGGD_OK : Disable()	
		PetSavvyGGD_Quick_Up : Disable()
		PetSavvyGGD_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
		PetSavvyGGD_Quick_Up_Animate:Play(false)
	else
		str = str .. math.floor( odds / 10 ) .. "%"
		PetSavvyGGD_OK : Enable()			
		PetSavvyGGD_Quick_Up : Enable()
			PetSavvyGGD_Quick_Up : SetText( "#{ZSKJT_130428_1}" )
		PetSavvyGGD_Quick_Up_Animate:Play(true)
	end

	PetSavvyGGD_Text2 : SetText( str )
end

-- 计算金钱消耗
function PetSavvyGGD_CalcCost()
	if mainPet.idx == -1 then
		PetSavvyGGD_NeedMoney : SetProperty( "MoneyNumber", tostring( 0 ) )
		return
	end

	local savvy = Pet : GetSavvy( mainPet.idx )
	local cost = moneyCosts[savvy]
	if not cost then
		cost = 0
	end

	PetSavvyGGD_NeedMoney : SetProperty( "MoneyNumber", tostring( cost ) )
end


function PetSavvyGGD_UpdateSelected()
	
	-- 判断被选中的珍兽是否还在背包里
	if mainPet.idx ~= -1 then
		local newIdx = Pet : GetPetIndexByGUID( mainPet.guid.high, mainPet.guid.low )
		Pet : SetPetLocation( mainPet.idx, -1 )
		-- 如果不在则删掉
		if newIdx == -1 then
			mainPet.idx = -1
			mainPet.guid.high = -1
			mainPet.guid.low = -1
			PetSavvyGGD_Pet : SetText( "" )
			PetSavvyGGD_Text2 : SetText( "#cFF0000成功率" )
			PetSavvyGGD_OK : Disable()
			PetSavvyGGD_Quick_Up : Disable();
			PetSavvyGGD_Quick_Up : SetText( "#{ZSKJT_130507_1}" )
			PetSavvyGGD_Quick_Up_Animate:Play(false)
		-- 否则判断珍兽的位置是否发生变化
		elseif newIdx ~= mainPet.idx then
			-- 如果发生变化则对位置进行更新
			mainPet.idx = newIdx
		end
	end

	PetSavvyGGD_SelectPet( mainPet.idx );

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject( objCaredId )
	theNPC = DataPool : GetNPCIDByServerID( objCaredId )
	if theNPC == -1 then
		PushDebugMessage("未发现 NPC")
		this : Hide()
		return
	end

	this : CareObject( theNPC, 1, "PetSavvyGGD" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject()
	this : CareObject( theNPC, 0, "PetSavvyGGD" )
	Pet : ShowPetList( 0 )
	theNPC = -1
end


function PetSavvyGGD_Frame_On_ResetPos()
  PetSavvyGGD_Frame:SetProperty("UnifiedPosition", g_PetSavvyGGD_Frame_UnifiedPosition);
end