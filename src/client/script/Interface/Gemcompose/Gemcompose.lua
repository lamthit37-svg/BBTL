
local theNPC = -1											-- 功能 NPC
local MAX_OBJ_DISTANCE = 3.0

local g_Gemcompose_YuanbaoPay = 1

local g_GemTableIndex = -1

local g_DummyGemLayed = 0
local g_DummyNewGem = 1

local RuleTable = {
	msgLackMoney = "您身上的金钱不足#{_EXCHG%d}。",
	maxGrade = 9,
	msgGradeLimited = "合成的宝石最高等级为9级，您的宝石不能继续合成。",
	[1] = { SpecialStuff = 30900015, MoneyCost = 5000, CountTable = { [3] = { SuccOdds = 25, SuccOddsWithSpecStuff = 50, }, [4] = { SuccOdds = 50, SuccOddsWithSpecStuff = 75, }, [5] = { SuccOdds = 75, SuccOddsWithSpecStuff = 100, }, }, },
	[2] = { SpecialStuff = 30900015, MoneyCost = 6000, CountTable = { [3] = { SuccOdds = 25, SuccOddsWithSpecStuff = 50, }, [4] = { SuccOdds = 50, SuccOddsWithSpecStuff = 75, }, [5] = { SuccOdds = 75, SuccOddsWithSpecStuff = 100, }, }, },
	[3] = { SpecialStuff = 30900015, MoneyCost = 7000, CountTable = { [3] = { SuccOdds = 25, SuccOddsWithSpecStuff = 50, }, [4] = { SuccOdds = 50, SuccOddsWithSpecStuff = 75, }, [5] = { SuccOdds = 75, SuccOddsWithSpecStuff = 100, }, }, },
	[4] = { SpecialStuff = 30900016, MoneyCost = 8000, CountTable = { [3] = { SuccOdds = 25, SuccOddsWithSpecStuff = 50, }, [4] = { SuccOdds = 50, SuccOddsWithSpecStuff = 75, }, [5] = { SuccOdds = 75, SuccOddsWithSpecStuff = 100, }, }, },
	[5] = { SpecialStuff = 30900016, MoneyCost = 9000, CountTable = { [3] = { SuccOdds = 25, SuccOddsWithSpecStuff = 50, }, [4] = { SuccOdds = 50, SuccOddsWithSpecStuff = 75, }, [5] = { SuccOdds = 75, SuccOddsWithSpecStuff = 100, }, }, },
	[6] = { SpecialStuff = 30900016, MoneyCost = 10000, CountTable = { [3] = { SuccOdds = 25, SuccOddsWithSpecStuff = 50, }, [4] = { SuccOdds = 50, SuccOddsWithSpecStuff = 75, }, [5] = { SuccOdds = 75, SuccOddsWithSpecStuff = 100, }, }, },
	[7] = { SpecialStuff = 30900128, MoneyCost = 11000, CountTable = { [4] = { SuccOdds = 75, SuccOddsWithSpecStuff = 100, }, [5] = { SuccOdds = 75, SuccOddsWithSpecStuff = 100, }, }, },
	[8] = { SpecialStuff = 30900016, MoneyCost = 12000, CountTable = { [3] = { SuccOdds = 25, SuccOddsWithSpecStuff = 50, }, [4] = { SuccOdds = 50, SuccOddsWithSpecStuff = 75, }, [5] = { SuccOdds = 75, SuccOddsWithSpecStuff = 100, }, }, },
}

local g_ActionButton_Gem
local g_ActionButton_GemNew
local g_ActionButton_ComposeItem

local g_Gemcompose_Frame_UnifiedPosition
local npcObjId = -1

local g_ItemBagIndex = -1			--合成符背包索引
local g_ComposeMode = 0				--默认5合1

local g_CurrentOdds = 0

local g_nMaxShowNum = 250


--礼金宝石的ID
local g_GemLiJinIdx = { --跟服务器变量名一致 内容一致
	50301003, 50301004, 50302009, 50302010, 50302011, 50302012, 50302013, 50302014, 50302015, 50302016,
	50303002, 50304003, 50311003, 50311004, 50312009, 50312010, 50312011, 50312012, 50312013, 50312014,
	50312015, 50312016, 50313007, 50313008, 50313009, 50313010, 50313011, 50313012, 50314002, 50321005,
	50321006, 50321007, 50321008,
	50401003, 50401004, 50402009, 50402010, 50402011, 50402012, 50402013, 50402014, 50402015, 50402016,
	50403002, 50404003, 50411003, 50411004, 50412009, 50412010, 50412011, 50412012, 50412013, 50412014,
	50412015, 50412016, 50413007, 50413008, 50413009, 50413010, 50413011, 50413012, 50414002, 50421005,
	50421006, 50421007, 50421008,
	50501003, 50501004, 50502009, 50502010, 50502011, 50502012, 50502013, 50502014, 50502015, 50502016,
	50503002, 50504003, 50511003, 50511004, 50512009, 50512010, 50512011, 50512012, 50512013, 50512014,
	50512015, 50512016, 50513007, 50513008, 50513009, 50513010, 50513011, 50513012, 50514002, 50521005,
	50521006, 50521007, 50521008,
	50601003, 50601004, 50602009, 50602010, 50602011, 50602012, 50602013, 50602014, 50602015, 50602016,
	50603002, 50604003, 50611003, 50611004, 50612009, 50612010, 50612011, 50612012, 50612013, 50612014,
	50612015, 50612016, 50613007, 50613008, 50613009, 50613010, 50613011, 50613012, 50614002, 50621005,
	50621006, 50621007, 50621008,
	50701003, 50701004, 50702009, 50702010, 50702011, 50702012, 50702013, 50702014, 50702015, 50702016,
	50703002, 50704003, 50711003, 50711004, 50712009, 50712010, 50712011, 50712012, 50712013, 50712014,
	50712015, 50712016, 50713007, 50713008, 50713009, 50713010, 50713011, 50713012, 50714002, 50721005,
	50721006, 50721007, 50721008,
	50801003, 50801004, 50802009, 50802010, 50802011, 50802012, 50802013, 50802014, 50802015, 50802016,
	50803002, 50804003, 50811003, 50811004, 50812009, 50812010, 50812011, 50812012, 50812013, 50812014,
	50812015, 50812016, 50813007, 50813008, 50813009, 50813010, 50813011, 50813012, 50814002, 50821005,
	50821006, 50821007, 50821008,
	50901003, 50901004, 50902009, 50902010, 50902011, 50902012, 50902013, 50902014, 50902015, 50902016,
	50903002, 50904003, 50911003, 50911004, 50912009, 50912010, 50912011, 50912012, 50912013, 50912014,
	50912015, 50912016, 50913007, 50913008, 50913009, 50913010, 50913011, 50913012, 50914002, 50921005,
	50921006, 50921007, 50921008
}

-- 注册事件
function Gemcompose_PreLoad()

	this:RegisterEvent("UI_COMMAND")						--激活界面事件
	this:RegisterEvent("COMPOSE_GEM_PUTIN_ITEM")			--宝石合成界面放进物品
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)			--背包中物品改变需要判断
	this:RegisterEvent("OBJECT_CARED_EVENT",false)				--关注实施合成的NPC
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)				--合成完毕
	this:RegisterEvent("CLOSE_SYNTHESIZE_ENCHASE")			--关闭本界面
	this:RegisterEvent("MONEY_CHANGE_EX",false)					--金钱变化
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)					--交子变化
	this:RegisterEvent("BUY_ITEM")							--快捷购买，更新界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

--界面载入
function Gemcompose_OnLoad()
	
	g_ActionButton_Gem = Gemcompose_Space1
	g_ActionButton_GemNew = Gemcompose_Space2
	g_ActionButton_ComposeItem = Gemcompose_Special_Button
	
	g_Gemcompose_YuanbaoPay = 1
	
	g_Gemcompose_Frame_UnifiedPosition=Gemcompose_Frame:GetProperty("UnifiedPosition")

end

--监控各种事件
function Gemcompose_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 23 then	--宝石合成
		
		if g_Gemcompose_YuanbaoPay == 1 or g_Gemcompose_YuanbaoPay == 0 then
			Gemcompose_YuanBaoPay:SetCheck(g_Gemcompose_YuanbaoPay)
		end
		Gemcompose_Clear()

		Gemcompose_SuccessValue_Text:SetText("")

		Gemcompose_Info:SetText("#{BSQHB_120830_01}")
		Gemcompose_Static1:Show()
		Gemcompose_Special:Show()
		
		local GemUnionPos = Variable:GetVariable("GemUnionPos")
		if(GemUnionPos ~= nil) then
		  Gemcompose_Frame:SetProperty("UnifiedPosition", GemUnionPos)
		end
		Gemcompose_FenYe1:SetCheck(1)
		this:Show()

		npcObjId = tonumber(Variable:GetVariable("GemNPCObjId"))
		Variable:SetVariable("GemNPCObjId", "", 1)
		if(npcObjId == nil) then
			npcObjId = Get_XParam_INT( 0 )
		end
		Gemcompose_BeginCareObject( npcObjId )
		Gemcompose_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		Gemcompose_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		
		Gemcompose_Special_Choice:ResetList()
		
		Gemcompose_Special_Choice:AddTextItem("#{BSDJ_170811_04}",0)
		Gemcompose_Special_Choice:AddTextItem("#{BSDJ_170811_05}",1)
		Gemcompose_Special_Choice:AddTextItem("#{BSDJ_170811_06}",2)
		Gemcompose_Special_Choice:SetCurrentSelect(0)
		return
	end

	if event == "OBJECT_CARED_EVENT" and this : IsVisible() then
		if tonumber( arg0 ) ~= theNPC then
			return
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
			Gemcompose_Cancel_Clicked()
		end
		Gemcompose_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		Gemcompose_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end

	if event == "COMPOSE_GEM_PUTIN_ITEM" and this:IsVisible() then
		Gemcompose_Update(arg0, arg1)
		Gemcompose_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		Gemcompose_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end
	
	if event == "BUY_ITEM" and this:IsVisible() then	--快捷购买，更新界面
		local itemId = tonumber(arg1)
		if itemId == Gemcompose_GetSpecialMaterial() then
			Gemcompose_Update(0,tonumber(PlayerPackage:GetBagPosByItemIndex(itemId)))	
			Gemcompose_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
			Gemcompose_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		end
		return
	end

	if event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() then
		
		if not arg0 or tonumber(arg0) == -1 then
			return
		end
		
		Gemcompose_RefreshItem()

		Gemcompose_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		Gemcompose_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end

	if event == "RESUME_ENCHASE_GEM_EX" and this : IsVisible() then
		if arg0 then
			Gemcompose_Remove( tonumber( arg0 ) - 6 )
		end
		return
	end

	if event == "CLOSE_SYNTHESIZE_ENCHASE" and this : IsVisible() then
		Gemcompose_Cancel_Clicked()
		Gemcompose_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if event == "MONEY_CHANGE_EX" and this:IsVisible() then
		Gemcompose_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		return
	end
	
	if event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		Gemcompose_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		return
	end
	
	if event == "ADJEST_UI_POS" then
		Gemcompose_Frame_On_ResetPos()
		return
	end
	
	if event == "VIEW_RESOLUTION_CHANGED" then
		Gemcompose_Frame_On_ResetPos()
		return
	end
	
end

--点击合成按钮
function Gemcompose_OK_Clicked()
	
	--根据当前所处的界面进行检查
	local Notify = 0

	--判断是否为安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	
	if g_GemTableIndex == -1 then
		return
	end
	
	local nGemCount = PlayerPackage:Lua_GetUnLockItemCount(g_GemTableIndex)
	local nGemLevel = Gemcompose_GetGemLevel(g_GemTableIndex)
	
	--检查材料是否是最高等级
	if nGemLevel >= RuleTable.maxGrade then
		PushDebugMessage( RuleTable.msgGradeLimited )
		return
	end
	
	--合成8，9级宝石功能关闭；放开8级宝石。[LiChengjie]
	if nGemLevel > 7 then
		PushDebugMessage( "#{BSHC_090313_1}" )
		return
	end
	
	if Gemcompose_IsGemLiJin(g_GemTableIndex) == 1 then
		if nGemLevel >= 6 then
			PushDebugMessage( "#{HLBS_260107_01}" )
			return
		end
	end

	local _,nSel = Gemcompose_Special_Choice:GetCurrentSelect()
	
	if nSel == 0 and nGemCount < 5 then
		local msg =ScriptGlobal_Format( "#{BSDJ_170811_13}", "5")
		PushDebugMessage(msg)
		return
	elseif nSel == 1 and nGemCount < 4 then
		local msg =ScriptGlobal_Format( "#{BSDJ_170811_13}", "4")
		PushDebugMessage(msg)
		return
	elseif nSel == 2 and nGemCount < 3 then
		local msg =ScriptGlobal_Format( "#{BSDJ_170811_13}", "3")
		PushDebugMessage(msg)
		return
	end
	
	-- 检查身上的金钱是否足够
	local selfMoney = Player : GetData( "MONEY" ) + Player : GetData( "MONEY_JZ" )
	if selfMoney < RuleTable[nGemLevel].MoneyCost then
		PushDebugMessage( string.format( RuleTable.msgLackMoney, RuleTable[nGemLevel].MoneyCost ) )
		return
	end

	--如果是宝石合成界面，则如果没有放入特殊材料将给出界面提示
	if g_ItemBagIndex == -1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnBuySpecialMaterail")
			Set_XSCRIPT_ScriptID(701602)
			Set_XSCRIPT_Parameter(0, tonumber(Gemcompose_YuanBaoPay:GetCheck()) )
			Set_XSCRIPT_Parameter(1, nGemLevel )
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		return
	end
	
	LifeAbility:Do_Combine(g_GemTableIndex,g_ItemBagIndex,nSel,g_CurrentOdds)
end

--点击取消或者关闭按钮
function Gemcompose_Cancel_Clicked()
	Gemcompose_Close()
	Gemcompose_StopCareObject()
end

--关闭界面
function Gemcompose_Close()
	this:Hide()
	Gemcompose_Clear()
end

--清空界面元素
function Gemcompose_Clear()

	g_Gemcompose_YuanbaoPay = Gemcompose_YuanBaoPay:GetCheck()

	Gemcompose_SuccessValue_Text:SetText("")
	Gemcompose_NeedMoney:SetProperty( "MoneyNumber", "0" )

	g_ActionButton_Gem:SetActionItem(-1)
	g_ActionButton_GemNew:SetActionItem(-1)
	g_ActionButton_ComposeItem:SetActionItem(-1)
	
	if g_GemTableIndex ~= -1 then
		LifeAbility:Lock_Packet_ItemByID(g_GemTableIndex,0)
		DataPool:Lua_GemComposeLayedItem_Update(0)
		g_GemTableIndex = -1
	end	
	
	if g_ItemBagIndex ~=  -1 then
		LifeAbility:Lock_Packet_Item(g_ItemBagIndex,0)
		g_ItemBagIndex = -1
	end
	
	LifeAbility:Lua_SetGemComposeNotify(1)

end

--得到当前界面应该匹配的特殊材料号
--如果不是宝石界面则返回 -1
--如果是宝石界面但是还没有放任何宝石则返回 -1
function Gemcompose_GetSpecialMaterial()
	
	if g_GemTableIndex == -1 then
		return -1
	end
	
	local nGemLevel = Gemcompose_GetGemLevel(g_GemTableIndex)

	if RuleTable[nGemLevel] ~= nil then
		return RuleTable[nGemLevel].SpecialStuff
	end

	return -1
end

--是不是合成符
function Gemcompose_IsComposeItem(bagPos)
	
	local nItemTableIndex =  PlayerPackage:GetItemTableIndex(bagPos)
	if nItemTableIndex == 30900015 or nItemTableIndex == 30900016 or nItemTableIndex == 30900128 then
		return 1
	end
	
	return 0
	
end

--刷新合成界面上的物品
function Gemcompose_Update(pos0, pos1)
	
	local slot = tonumber(pos0)
	local bagPos = tonumber(pos1)

	--验证物品有效性
	local bagItem = EnumAction(bagPos, "packageitem")
	if bagItem:GetID() == 0 then
		return
	end
	
	if slot == 0 then
		
		if PlayerPackage:IsGem(bagPos) == 1 then
			Gemcompose_PutInGem(bagPos)
		elseif Gemcompose_IsComposeItem(bagPos) == 1 then
			Gemcompose_PutInComposeItem(bagPos)
		else
			PushDebugMessage("#{BSQHB_120830_03}")
			return
		end
	
	elseif slot == 1 then
		
		Gemcompose_PutInGem(bagPos)
		
	elseif slot == 2 then
	
		Gemcompose_PutInComposeItem(bagPos)
	
	end

end

--往宝石框放入一个物品
function Gemcompose_PutInGem(bagPos)
	
	if Gemcompose_IsComposeItem(bagPos) == 1 then
		PushDebugMessage("#{BSQHB_120830_09}")		--请放入宝石合成符框
		return
	elseif PlayerPackage:IsGem(bagPos) ~= 1 then
		PushDebugMessage("#{BSQHB_120830_03}")		--材料类型不符
		return
	end
	
	--是否是双属性宝石
	local bDoubleGem = DoubleGem:IsDoubleGem(bagPos)
	if bDoubleGem > 0 then
		PushDebugMessage("#{BSZK_121012_43}")
		return
	end
	
	--分期付款宝石
	local bBP_Gem = BudgetPlanGem:IsBudgetPlanGem(bagPos)
	if bBP_Gem > 0 then
		PushDebugMessage("#{FQBS_140508_55}")
		return
	end
	
	local nGemLevel = PlayerPackage:GetItemSubTableIndex(bagPos, 1)
	if nGemLevel == 8 then
		PushDebugMessage("#{BSQHB_120830_04}")		--用8级宝石合成9级宝石功能目前尚未开放
		return
	end


	
	local gemItem = EnumAction(bagPos, "packageitem")
	if gemItem:GetID() == 0 then
		return
	end
	
	g_ActionButton_Gem:SetActionItem(-1)
	g_ActionButton_GemNew:SetActionItem(-1)
	
	if g_GemTableIndex ~= -1 then
		LifeAbility:Lock_Packet_ItemByID(g_GemTableIndex,0)
		g_GemTableIndex = -1
	end
	
	local nItemTableIndex =  PlayerPackage:GetItemTableIndex(bagPos)
	if Gemcompose_IsGemLiJin(nItemTableIndex) == 1 then
		if nGemLevel >= 6 then
			PushDebugMessage( "#{HLBS_260107_01}" )
			return
		end
	end

	local nHaveCount = PlayerPackage:CountAvailableItemByIDTable(nItemTableIndex)
	local nHaveBindCount = PlayerPackage:Lua_GetUnLockBindItemCount(nItemTableIndex)

	-- PushDebugMessage("nHaveBindCount1"..nHaveBindCount)

	if nHaveCount > g_nMaxShowNum then
		nHaveCount = g_nMaxShowNum
	end
	
	local theAction = nil 
	if nHaveBindCount > 0 then
		theAction = DataPool:CreateBindActionItemForShow(nItemTableIndex, nHaveCount)
	else
		theAction = DataPool:CreateActionItemForShow(nItemTableIndex, nHaveCount)
	end
	 
	if 0 ~= theAction:GetID() then
		g_ActionButton_Gem : SetActionItem(theAction:GetID())
		LifeAbility : Lock_Packet_ItemByID(nItemTableIndex, 1)
		g_GemTableIndex = nItemTableIndex
	end

	DataPool:Lua_GemComposeLayedItem_Update(nItemTableIndex)
	
	local layedGemItem = EnumAction(g_DummyGemLayed, "Gem_Layed")
	-- if layedGemItem:GetID() ~= 0 then
	-- 	g_ActionButton_Gem:SetActionItem(layedGemItem:GetID())
	-- 	LifeAbility:Lock_Packet_ItemByID(nItemTableIndex,1)
	-- 	g_GemTableIndex = nItemTableIndex
	-- end

	local newGemItem = EnumAction(g_DummyNewGem, "Gem_Layed")
	if newGemItem:GetID() ~= 0 then
		g_ActionButton_GemNew:SetActionItem(newGemItem:GetID())
	end
	
	if g_ItemBagIndex ~= -1 then
	
		local nComposeItemTableIndex = PlayerPackage:GetItemTableIndex(g_ItemBagIndex)
		
		if Gemcompose_GetSpecialMaterial() ~= nComposeItemTableIndex then
			
			g_ActionButton_ComposeItem:SetActionItem(-1)
			LifeAbility:Lock_Packet_Item(g_ItemBagIndex,0)
			g_ItemBagIndex = -1

		end
	end
	
	if nGemLevel == 7 then
		Gemcompose_Special_Choice:SetCurrentSelect(1)
	else
		Gemcompose_Special_Choice:SetCurrentSelect(0)
	end
	
	LifeAbility:Lua_SetGemComposeNotify(1)
	
	Gemcompose_RecalcCost()
	Gemcompose_RecalcSuccOdds()
	
end

--往宝石合成符框放入一个物品
function Gemcompose_PutInComposeItem(bagPos)
	
	if PlayerPackage:IsGem(bagPos) == 1 then
		PushDebugMessage("#{BSQHB_120830_08}")		--请放入宝石框中
		return
	elseif Gemcompose_IsComposeItem(bagPos) ~= 1 then
		PushDebugMessage("#{BSQHB_120830_03}")		--材料类型不符
		return
	end
	
	local composeItem = EnumAction(bagPos, "packageitem")
	if composeItem:GetID() == 0 then
		return
	end
	
	if g_GemTableIndex == -1 then
		PushDebugMessage("#{BSQHB_120830_06}")	--请先放入宝石
		return		
	end
	
	local nGemLevel = Gemcompose_GetGemLevel(g_GemTableIndex)
	local nComposeItemTableIndex = PlayerPackage:GetItemTableIndex(bagPos)
	
	if Gemcompose_GetSpecialMaterial() == -1 then
		PushDebugMessage("#{BSQHB_120830_06}")	--请先放入宝石
		return	
	elseif Gemcompose_GetSpecialMaterial() ~= nComposeItemTableIndex then
		
		if nGemLevel < 4 then
			PushDebugMessage( "#{BSQHB_120830_12}" )
		elseif nGemLevel < 7 then
			PushDebugMessage( "#{BSQHB_120830_13}" )
		elseif nGemLevel < 8 then
			PushDebugMessage( "#{BSQHB_120830_07}" )
		end
		return
	end
	
	if g_ItemBagIndex == -1 then
		
		g_ActionButton_ComposeItem:SetActionItem(composeItem:GetID())
		g_ItemBagIndex = bagPos
		LifeAbility:Lock_Packet_Item(g_ItemBagIndex, 1)	
		
	else
	
		g_ActionButton_ComposeItem:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(g_ItemBagIndex,0)
		
		g_ActionButton_ComposeItem:SetActionItem(composeItem:GetID())
		g_ItemBagIndex = bagPos
		LifeAbility:Lock_Packet_Item(g_ItemBagIndex, 1)
	
	end
	
	LifeAbility:Lua_SetGemComposeNotify(1)
	
	Gemcompose_RecalcSuccOdds()
	
end

function Gemcompose_Special_ChoiceChanged()
	
	local _,nSel = Gemcompose_Special_Choice:GetCurrentSelect()
	
	if g_GemTableIndex ~= -1 then
	
		local nGemLevel = Gemcompose_GetGemLevel(g_GemTableIndex)
		if nGemLevel == 7 and nSel ~= 1 then
			PushDebugMessage("#{BSDJ_170811_07}")		--合成8级宝石只能使用四合一模式
			Gemcompose_Special_Choice:SetCurrentSelect(1)
			return
		end		
	end
	
	LifeAbility:Lua_SetGemComposeNotify(1)
	
	Gemcompose_RecalcSuccOdds()

end

--移除一个材料
function Gemcompose_Remove(slot)
	
	if slot == 1 then
	
		Gemcompose_Clear()
		
	elseif slot == 2 then
	
		g_ActionButton_ComposeItem:SetActionItem(-1)
		if g_ItemBagIndex ~=  -1 then
			LifeAbility:Lock_Packet_Item(g_ItemBagIndex,0)
			g_ItemBagIndex = -1
		end
		
		LifeAbility:Lua_SetGemComposeNotify(1)
		
		Gemcompose_RecalcCost()
		Gemcompose_RecalcSuccOdds()
	end	
	
end

--重新计算合成概率
function Gemcompose_RecalcSuccOdds()
	
	g_CurrentOdds = 0
	
	if g_GemTableIndex == -1 then
		Gemcompose_SuccessValue_Text:SetText("")
		return
	end	
	
	local nGemLevel = Gemcompose_GetGemLevel(g_GemTableIndex)
	local nGemCount = PlayerPackage:Lua_GetUnLockItemCount(g_GemTableIndex)

	local str = "#cFF0000"
	
	local _,nSel = Gemcompose_Special_Choice:GetCurrentSelect()
	
	if nSel == 0 and RuleTable[nGemLevel] ~= nil and RuleTable[nGemLevel].CountTable[5] ~= nil then
		
		if nGemCount < 5 then
			Gemcompose_SuccessValue_Text:SetText("#{BSDJ_170811_37}")
		else
		
			local nOdds = RuleTable[nGemLevel].CountTable[5].SuccOdds
			
			if g_ItemBagIndex ~= -1 then
				nOdds = RuleTable[nGemLevel].CountTable[5].SuccOddsWithSpecStuff
			end
			str = str..tostring(nOdds).."%"
			
			Gemcompose_SuccessValue_Text:SetText(str)
			
			g_CurrentOdds = nOdds
		end
		
	elseif nSel == 1 and RuleTable[nGemLevel].CountTable[4] ~= nil  then
		
		if nGemCount < 4 then		
			Gemcompose_SuccessValue_Text:SetText("#{BSDJ_170811_37}")
		else
			local nOdds = RuleTable[nGemLevel].CountTable[4].SuccOdds
			
			if g_ItemBagIndex ~= -1 then
				nOdds = RuleTable[nGemLevel].CountTable[4].SuccOddsWithSpecStuff
			end
			str = str..tostring(nOdds).."%"
			
			Gemcompose_SuccessValue_Text:SetText(str)
			
			g_CurrentOdds = nOdds
		end
	
	elseif nSel == 2 and RuleTable[nGemLevel].CountTable[3] ~= nil then
	
		if nGemCount < 3 then
			Gemcompose_SuccessValue_Text:SetText("#{BSDJ_170811_37}")
		else
		
			local nOdds = RuleTable[nGemLevel].CountTable[3].SuccOdds
			
			if g_ItemBagIndex ~= -1 then
				nOdds = RuleTable[nGemLevel].CountTable[3].SuccOddsWithSpecStuff
			end
			str = str..tostring(nOdds).."%"
			
			Gemcompose_SuccessValue_Text:SetText(str)
			
			g_CurrentOdds = nOdds
		end
	end	
end

--重新计算金钱消耗
function Gemcompose_RecalcCost()
	
	if g_GemTableIndex == -1 then
		Gemcompose_NeedMoney:SetProperty("MoneyNumber", "0")
		return 
	end

	local nGemLevel = Gemcompose_GetGemLevel(g_GemTableIndex)

	if RuleTable[nGemLevel] ~= nil then
		Gemcompose_NeedMoney:SetProperty("MoneyNumber", tostring(RuleTable[nGemLevel].MoneyCost) )
		return
	end

	Gemcompose_NeedMoney:SetProperty("MoneyNumber", "0")
end

function Gemcompose_RefreshItem()
		
	if g_GemTableIndex ~= -1 then
		
		g_ActionButton_Gem:SetActionItem(-1)
		g_ActionButton_GemNew:SetActionItem(-1)
		LifeAbility:Lock_Packet_ItemByID(g_GemTableIndex,0)

		local nHaveCount = PlayerPackage:CountAvailableItemByIDTable(g_GemTableIndex)
		local nHaveBindCount = PlayerPackage:Lua_GetUnLockBindItemCount(g_GemTableIndex)

		-- PushDebugMessage("nHaveBindCount2"..nHaveBindCount)

		if nHaveCount > g_nMaxShowNum then
			nHaveCount = g_nMaxShowNum
		end

		if nHaveCount > 0 then
			local theAction = nil 
			if nHaveBindCount > 0 then
				theAction = DataPool:CreateBindActionItemForShow(g_GemTableIndex, nHaveCount)
			else
				theAction = DataPool:CreateActionItemForShow(g_GemTableIndex, nHaveCount)
			end
			 
			if 0 ~= theAction:GetID() then
				g_ActionButton_Gem : SetActionItem(theAction:GetID())
				LifeAbility:Lock_Packet_ItemByID(g_GemTableIndex, 1)
			end
		end

		DataPool:Lua_GemComposeLayedItem_Update(g_GemTableIndex)

		local layedGemItem = EnumAction(g_DummyGemLayed, "Gem_Layed")
		-- if layedGemItem:GetID() ~= 0 then
		-- 	g_ActionButton_Gem:SetActionItem(layedGemItem:GetID())
		-- 	LifeAbility:Lock_Packet_ItemByID(g_GemTableIndex,1)
		-- end

		local newGemItem = EnumAction(g_DummyNewGem, "Gem_Layed")
		if newGemItem:GetID() ~= 0 then
			g_ActionButton_GemNew:SetActionItem(newGemItem:GetID())
		end		
		
		if g_ItemBagIndex ~=  -1 then
			
			local nComposeItemTableIndex = PlayerPackage:GetItemTableIndex(g_ItemBagIndex)
			
			if Gemcompose_GetSpecialMaterial() ~= nComposeItemTableIndex then
				g_ActionButton_ComposeItem:SetActionItem(-1)
				LifeAbility:Lock_Packet_Item(g_ItemBagIndex,0)
				g_ItemBagIndex = -1
			end
		end
		
		Gemcompose_RecalcCost()
		Gemcompose_RecalcSuccOdds()
	
	end

end

function Gemcompose_GetGemLevel(nSN)
	
	if nSN < 0 then
		return 0
	end

	local nLevel = math.floor(math.mod(nSN,10000000) / 100000)
	return nLevel

end
--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function Gemcompose_BeginCareObject( objCaredId )
	theNPC = DataPool : GetNPCIDByServerID( objCaredId )
	-- AxTrace( 0, 1, "theNPC0: " .. theNPC )
	if theNPC == -1 then
		PushDebugMessage("未发现 NPC")
		this : Hide()
		g_Gemcompose_YuanbaoPay = Gemcompose_YuanBaoPay:GetCheck()
		return
	end

	this : CareObject( theNPC, 1, "Gemcompose" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function Gemcompose_StopCareObject()
	this : CareObject( theNPC, 0, "Gemcompose" )
	theNPC = -1
end

function Gemcompose_Help_Clicked()
	Helper:GotoHelper("*Gemcompose")
end

function Gemcompose_Frame_On_ResetPos()
  Gemcompose_Frame:SetProperty("UnifiedPosition", g_Gemcompose_Frame_UnifiedPosition)
end

--判断是否是礼金宝石。这里使用了比较蛋疼的判断方法，就是名字里面是否有"·通"
function Gemcompose_IsLiJinGem( bagIdx )
    if bagIdx == nil or bagIdx == -1 then
        return 1
    end

    local specStr = "·通"
    local itemName = PlayerPackage:GetBagItemName( bagIdx )
    if itemName == nil then
        return 1
    end

    local sPos, ePos = string.find( itemName, specStr )
    if sPos == nil or ePos == nil then
        return 0
    end

    return 1
end

--TAB界面切换，界面名字太坑了
function Gemcompose_ChangeTabIndex( nIndex )
	if nIndex == nil then
		return
	end
	
	if nIndex == 5 or nIndex == 4 or nIndex == 3 then
		if IsZbs2018SpeicalServer() >= 1 then
			PushDebugMessage("#{WCBS_180307_20}")
			return
		end
	end
	
	local nUI = 0
	if 1 == nIndex then
		return
	elseif 2 == nIndex then
		nUI = 112236
	elseif 3 == nIndex then
		nUI = 112237
	elseif 4 == nIndex then
		nUI = 201210120
	elseif 5 == nIndex then
		nUI = 201210121
	elseif 6 == nIndex then
		nUI = 201408140
	else
		return
	end
	if nUI ~= 0 then
		Variable:SetVariable("GemUnionPos", Gemcompose_Frame:GetProperty("UnifiedPosition"), 1)
		Variable:SetVariable("GemNPCObjId", tostring(npcObjId), 1)
		PushEvent("UI_COMMAND", nUI)
		Gemcompose_Close()
	end
end

function Gemcompose_Yuanbao_Click()

end

--判断是否是礼金宝石
function Gemcompose_IsGemLiJin(itemIndex)
	for i = 1, table.getn(g_GemLiJinIdx) do
		if g_GemLiJinIdx[i] == itemIndex then
			return 1
		end
	end
	return 0
end