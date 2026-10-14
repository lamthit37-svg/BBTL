-- PetSavvy.lua
-- 珍兽提升悟性（用成年珍兽）

local mainPet = { idx = -1, guid = { high = -1, low = -1 } }
local assisPet = { idx = -1, guid = { high = -1, low =-1 } }

local theNPC = -1													-- 功能 NPC
local MAX_OBJ_DISTANCE = 3.0

local currentChoose = -1

local moneyCosts = {													-- 索引是珍兽的当前悟性值
	[0] = 10000,
	[1] = 11000,
	[2] = 12100,
	[3] = 13310,
	[4] = 14641,
	[5] = 16105,
	[6] = 17716,
	[7] = 19487,
	[8] = 21436,
	[9] = 23579,
}

local g_PetSavvy_Frame_UnifiedPosition;

function PetSavvy_PreLoad()
	this : RegisterEvent( "UI_COMMAND",true )
	this : RegisterEvent( "REPLY_MISSION_PET",false )				-- 玩家从列表选定一只珍兽
	this : RegisterEvent( "UPDATE_PET_PAGE",false )					-- 玩家身上的珍兽数据发生变化
	this : RegisterEvent( "DELETE_PET",false )							-- 玩家身上减少一只珍兽
	this : RegisterEvent( "OBJECT_CARED_EVENT",false )			-- 关心 NPC 的存在和范围
	this : RegisterEvent( "MONEY_CHANGE_EX",false );
	this : RegisterEvent( "MONEYJZ_CHANGE_EX",false )					--交子普及 Vega
	this : RegisterEvent( "OPEN_EXCHANGE_FRAME",false );		--打开交易界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function PetSavvy_OnLoad()
	PetSavvy_Clear()
	    g_PetSavvy_Frame_UnifiedPosition=PetSavvy_Frame:GetProperty("UnifiedPosition");
end

function PetSavvy_OnEvent(event)

	--PushDebugMessage("PetSavvy : "..event);

	if event == "UI_COMMAND" and tonumber( arg0 ) == 19820424 then	-- 打开界面
		if this : IsVisible() then									-- 如果界面开着，则不处理
			return
		end
		Pet : ShowPetList( 0 )
		PetSavvy_Clear()
		this : Show()

		local npcObjId = Get_XParam_INT( 0 )
		BeginCareObject( npcObjId )
		PetSavvy_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetSavvy_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		return
	end

	-- 玩家选了一只珍兽
	if event == "REPLY_MISSION_PET" and this : IsVisible() then
		PetSavvy_SelectPet( tonumber( arg0 ) )
		PetSavvy_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetSavvy_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		return
	end

	-- 玩家身上的珍兽数据发生变化，包括珍兽出战、休息、增加一只珍兽
	if event == "UPDATE_PET_PAGE" and this : IsVisible() then
		PetSavvy_UpdateSelected()
		PetSavvy_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetSavvy_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		return
	end

	-- 玩家身上减少一只珍兽
	if event == "DELETE_PET" and this : IsVisible() then
		PetSavvy_UpdateSelected()
		PetSavvy_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
		PetSavvy_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
		return
	end

	-- 关心 NPC 的存在和范围
	if event == "OBJECT_CARED_EVENT" and this : IsVisible() then
		if tonumber( arg0 ) ~= theNPC then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
			PetSavvy_Cancel_Clicked()
		end
		return
	end

	if (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		PetSavvy_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	end

	if (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		PetSavvy_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	end

	-- 打开交易界面的同时关闭该界面，但是需要刷新一下珍兽列表
	if (event == "OPEN_EXCHANGE_FRAME" and this:IsVisible()) then
		StopCareObject()
		PetSavvy_Clear()
		Pet : ShowPetList( 0 )
		Pet : ShowPetList( 1 )
		this:Hide()
	end
	
	if (event == "ADJEST_UI_POS" ) then
		PetSavvy_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetSavvy_Frame_On_ResetPos()
	end	
		

end

function PetSavvy_Choose_Clicked( type )
	if type == "main" then
		currentChoose = 1
		PetSavvy_Other_PetList1_Select : Disable()
		PetSavvy_Other_PetList2_Select : Enable()
	elseif type == "assis" then
		currentChoose = 2
		PetSavvy_Other_PetList1_Select : Enable()
		PetSavvy_Other_PetList2_Select : Disable()
	else
		return
	end

	-- 关一下再开，清空数据
	Pet : ShowPetList( 0 )
	Pet : ShowPetList( 1 )
end

-- 确定
function PetSavvy_OK_Clicked()
	-- 首先判定玩家是否放入需要提升的珍兽，如果没有放入NPC将会弹出对话并返回：
	if mainPet.idx == -1 then
	-- 请放入您要提升悟性等级的珍兽。
		ShowSystemTipInfo( "请放入您要提升悟性等级的珍兽。" )
		return
	end

	-- 判定玩家是否放入参与合成的珍兽，如果没有放入NPC将会弹出对话并返回：
	if assisPet.idx == -1 then
		-- 请放入您要参与合成的珍兽。
		ShowSystemTipInfo( "请放入您要参与合成的珍兽。" )
		return
	end

	-- 判断辅助宠是否符合条件
	if PetSavvy_Check() == 0 then
		-- 如果不符合则返回
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

	-- 发送 UI_Command 进行合成
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PetSavvy" )
		Set_XSCRIPT_ScriptID( 800104 )
		Set_XSCRIPT_Parameter( 0, mainPet.guid.high )
		Set_XSCRIPT_Parameter( 1, mainPet.guid.low )
		Set_XSCRIPT_Parameter( 2, assisPet.guid.high )
		Set_XSCRIPT_Parameter( 3, assisPet.guid.low )
		Set_XSCRIPT_ParamCount( 4 )
	Send_XSCRIPT()
end

-- 关闭、取消
function PetSavvy_Cancel_Clicked()	
	this:Hide()
end

-- 隐藏
function PetSavvy_Close()
	StopCareObject()
	Pet : ShowPetList( 0 )
	PetSavvy_Clear()
end

function PetSavvy_RemoveMainPet()
	if mainPet.idx ~= -1 then
		Pet : SetPetLocation( mainPet.idx, -1 )
		-- 更新珍兽列表界面
		Pet:UpdatePetList()
	end

	mainPet.idx = -1
	mainPet.guid.high = -1
	mainPet.guid.low = -1
	PetSavvy_Pet1_Text : SetText( "" )
end

function PetSavvy_RemoveAssisPet()
	if assisPet.idx ~= -1 then
		Pet : SetPetLocation( assisPet.idx, -1 )
		-- 更新珍兽列表界面
		Pet:UpdatePetList()
	end

	assisPet.idx = -1
	assisPet.guid.high = -1
	assisPet.guid.low = -1
	PetSavvy_Pet2_Text : SetText( "" )
end

function PetSavvy_Clear()
	PetSavvy_RemoveMainPet()
	PetSavvy_RemoveAssisPet()

	PetSavvy_Text2 : SetText( "#cFF0000成功率" )
	PetSavvy_NeedMoney : SetProperty( "MoneyNumber", tostring( 0 ) )

	PetSavvy_OK : Disable()

	currentChoose = -1
	PetSavvy_Other_PetList1_Select : Enable()
	PetSavvy_Other_PetList2_Select : Enable()
end

function PetSavvy_Check()
	if mainPet.idx == -1 or assisPet.idx == -1 then
		return 0
	end

	if mainPet.idx == assisPet.idx then
		ShowSystemTipInfo( "请放入两只不同的珍兽。" )
		return 0
	end

	-- 判定参与珍兽的携带等级是否大于等于需要提升的珍兽的携带等级，如果不是，则弹出对话并返回：
	local mainCarryLevel = Pet : GetTakeLevel( mainPet.idx )
	local assisCarryLevel = Pet : GetTakeLevel( assisPet.idx )
	if assisCarryLevel < mainCarryLevel then
		-- 您的参与合成的珍兽携带等级为a，必须要找携带等级大于等于b的才能参与合成。（a为参与合成珍兽的携带等级、b为需要提升的珍兽的携带等级）
		ShowSystemTipInfo( "您的参与合成的珍兽携带等级为" .. assisCarryLevel .. "，必须要找携带等级大于等于" .. mainCarryLevel .. "的才能参与合成。" )
		return 0
	end

	-- 判定参与合成的珍兽的根骨是否大于等于需要提升的珍兽的悟性等级，如果判定不成立则弹出对话并返回：
	local savvy = Pet : GetSavvy( mainPet.idx )
	local con = Pet : GetBasic( assisPet.idx )
	if con < savvy then
		-- 参与合成的珍兽的根骨必须大于等于a（a为需要提升的珍兽的悟性等级）
		ShowSystemTipInfo( "参与合成的珍兽的根骨必须大于等于" .. savvy .. "。" )
		return 0
	end

	return 1
end

-- 计算成功率
function PetSavvy_CalcSuccOdds()
	if mainPet.idx == -1 then
		PetSavvy_Text2 : SetText( "#cFF0000成功率" )
		PetSavvy_OK : Disable()
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
		[9] = 60,
	}

	local savvy = Pet : GetSavvy( mainPet.idx )
	local str = "#cFF0000成功率："
	local odds = succOdds[savvy]
	if not odds then
		str = "无法提升"
		PetSavvy_OK : Disable()
	else
		str = str .. math.floor( odds / 10 ) .. "%"
		PetSavvy_OK : Enable()
	end

	PetSavvy_Text2 : SetText( str )
end

-- 计算金钱消耗
function PetSavvy_CalcCost()
	if mainPet.idx == -1 then
		PetSavvy_NeedMoney : SetProperty( "MoneyNumber", tostring( 0 ) )
		return
	end

	local savvy = Pet : GetSavvy( mainPet.idx )
	local cost = moneyCosts[savvy]
	if not cost then
		cost = 0
	end

	PetSavvy_NeedMoney : SetProperty( "MoneyNumber", tostring( cost ) )
end

function PetSavvy_SelectPet( petIdx )
	if -1 == petIdx then
		return
	end
	
	--珍兽已被其它界面选中且排除珍兽合成提高悟性界面，由后面判断
	if (Pet:GetPetLocation(petIdx) ~= -1 and Pet:GetPetLocation(petIdx) ~= 12) then
		return;
	end

	local petName = Pet : GetPetList_Appoint( petIdx )
	local guidH, guidL = Pet : GetGUID( petIdx )

	-- 判断 petIdex 代表的是被提升的宠还是辅助宠
	-- 如果是被提升的宠
	if currentChoose == 1 then

		--判断是否被提升的和辅助的是否是同一个
		if assisPet.idx ~= -1 and assisPet.idx == petIdx then
			ShowSystemTipInfo( "请放入两只不同的珍兽。" )
			return
		end

		-- 如果原来已经选择了一个被提升的宠
		-- 则清空原来的数据
		PetSavvy_RemoveMainPet()

		-- XX 如果原来就有辅助宠并且辅助宠不符合新的条件
		-- XX 则清空辅助宠的数据
		-- 记录该宠的位置号、GUID
		mainPet.idx = petIdx
		mainPet.guid.high = guidH
		mainPet.guid.low = guidL

		-- 将珍兽名字填到文本框中
		PetSavvy_Pet1_Text : SetText( petName )

		-- 给珍兽上锁，设置珍兽已经提交到2号界面容器
		Pet : SetPetLocation( petIdx, 12 )
		-- 更新珍兽列表界面
		Pet:UpdatePetList()

	-- 如果是辅助宠
	elseif currentChoose == 2 then
		if PlayerPackage:IsPetLock(petIdx) == 1 then
			PushDebugMessage("珍兽已加锁")
			return
		end

		--判断是否被提升的和辅助的是否是同一个
		if mainPet.idx ~= -1 and mainPet.idx == petIdx then
			ShowSystemTipInfo( "请放入两只不同的珍兽。" )
			return
		end

		-- 辅助宠不能穿装备 zchw
		if Pet:IsPetHaveEquip(petIdx) == 1 then
			PushDebugMessage("#{ZSZB_090211_18}")
			return
		end
		
		--有内丹限制操作 Vega
		if Pet:LuaFnIsPetEquipNeiDan(petIdx) == 1 then
			PushDebugMessage("#{ZSND_230428_131}")
			return
		end
		-- XX 如果没有被提升的宠存在
		-- XX 则提示需要先放入被提升的宠并返回
		-- XX 判断辅助宠是否符合条件
		-- XX 如果不符合则返回
		-- 如果原来就有辅助宠
		-- 则清空原来的数据
		PetSavvy_RemoveAssisPet()

		-- 记录该宠的位置号、GUID
		assisPet.idx = petIdx
		assisPet.guid.high = guidH
		assisPet.guid.low = guidL

		-- 将珍兽名字填到文本框中
		PetSavvy_Pet2_Text : SetText( petName )

		-- 给珍兽上锁，设置珍兽已经提交到2号界面容器
		Pet : SetPetLocation( petIdx, 12 )
		-- 更新珍兽列表界面
		Pet:UpdatePetList()
	end

	-- 更新金钱和几率显示
	PetSavvy_CalcSuccOdds()
	PetSavvy_CalcCost()

end

function PetSavvy_UpdateSelected()
	
	-- 判断被选中的珍兽是否还在背包里
	if mainPet.idx ~= -1 then
		local newIdx = Pet : GetPetIndexByGUID( mainPet.guid.high, mainPet.guid.low )
		Pet : SetPetLocation( mainPet.idx, -1 )
		-- 如果不在则删掉
		if newIdx == -1 then
			mainPet.idx = -1
			mainPet.guid.high = -1
			mainPet.guid.low = -1
			PetSavvy_Pet1_Text : SetText( "" )
			PetSavvy_Text2 : SetText( "#cFF0000成功率" )
			PetSavvy_OK : Disable()
		-- 否则判断珍兽的位置是否发生变化
		elseif newIdx ~= mainPet.idx then
			-- 如果发生变化则对位置进行更新
			mainPet.idx = newIdx
		end
	end

	-- 判断被选中的珍兽是否还在背包里
	if assisPet.idx ~= -1 then
		local newIdx = Pet : GetPetIndexByGUID( assisPet.guid.high, assisPet.guid.low )
		Pet : SetPetLocation( assisPet.idx, -1 )
		-- 如果不在则删掉
		if newIdx == -1 then
			assisPet.idx = -1
			assisPet.guid.high = -1
			assisPet.guid.low = -1
			PetSavvy_Pet2_Text : SetText( "" )
		-- 否则判断珍兽的位置是否发生变化
		elseif newIdx ~= assisPet.idx then
			-- 如果发生变化则对位置进行更新
			assisPet.idx = newIdx
		end
	end

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

	this : CareObject( theNPC, 1, "PetSavvy" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject()
	this : CareObject( theNPC, 0, "PetSavvy" )
	theNPC = -1
end


function PetSavvy_Frame_On_ResetPos()
  PetSavvy_Frame:SetProperty("UnifiedPosition", g_PetSavvy_Frame_UnifiedPosition);
end