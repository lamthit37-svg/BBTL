local g_T3BianJingGashapon_MBuy_UnifiedPosition
local g_T3BianJingGashapon_MBuy_MaxLibaoCount = 3
local g_T3BianJingGashapon_MBuy_ItemSelectIndex
local g_T3BianJingGashapon_MBuy_SinglePrice = 1
local g_T3BianJingGashapon_MBuy_ReduceNum = 0
local g_T3BianJingGashapon_MBuy_LimitNum = 0
local g_T3BianJingGashapon_MBuy_PageNum = 0
local g_T3BianJingGashapon_MBuy_MaxMoney = 0

function T3BianJingGashapon_MBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function T3BianJingGashapon_MBuy_OnLoad()	
	g_T3BianJingGashapon_MBuy_UnifiedPosition = T3BianJingGashapon_MBuy_Frame:GetProperty("UnifiedPosition")

	g_T3BianJingGashapon_MBuy_SinglePrice = 1
	g_T3BianJingGashapon_MBuy_ReduceNum = 0
	g_T3BianJingGashapon_MBuy_LimitNum = 0
	g_T3BianJingGashapon_MBuy_PageNum = 0
	g_T3BianJingGashapon_MBuy_MaxMoney = 0
end

function T3BianJingGashapon_MBuy_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88820602 ) then
		T3BianJingGashapon_MBuy_Update( Get_XParam_INT(0), Get_XParam_INT(1), Get_XParam_INT(2), Get_XParam_INT(3), Get_XParam_INT(4) )
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		T3BianJingGashapon_MBuy_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		T3BianJingGashapon_MBuy_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function T3BianJingGashapon_MBuy_On_ResetPos()
	T3BianJingGashapon_MBuy_Frame:SetProperty("UnifiedPosition", g_T3BianJingGashapon_MBuy_UnifiedPosition);
end

function T3BianJingGashapon_MBuy_Update(  shoptype, curpage, nIndex, curbuycnt, money )

	local nID, nNeedDaibi, nShowItemId, nItemNum, nLimit = GetNiudanShopDuihuanItem( shoptype, nIndex+(curpage-1)*12 )
	if nID < 0 then
		return
	end

	local theAction = DataPool:CreateActionItemForShow(nShowItemId, nItemNum)
	T3BianJingGashapon_MBuy_Item:SetActionItem(theAction:GetID())
	T3BianJingGashapon_MBuy_ItemInfo_Text:SetText( ScriptGlobal_Format( "#{PTLS_200902_41}", theAction:GetName() ) )

	if shoptype == 1 then
		T3BianJingGashapon_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format( "#{PTLS_200902_42}", nNeedDaibi ) )
	else
		T3BianJingGashapon_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format( "#{PTLS_200902_143}", nNeedDaibi ) )
	end

	if nLimit == 0 then
		T3BianJingGashapon_MBuy_Item_BuyLimitNumBK:Hide()
		T3BianJingGashapon_MBuy_Item_BuyLimit:Hide()
	else
		T3BianJingGashapon_MBuy_Item_BuyLimitNumBK:Show()
		T3BianJingGashapon_MBuy_Item_BuyLimitNum:SetText(nLimit-curbuycnt)
		T3BianJingGashapon_MBuy_Item_BuyLimit:Show()
	end

	g_T3BianJingGashapon_MBuy_ItemSelectIndex = nIndex+(curpage-1)*12
	g_T3BianJingGashapon_MBuy_SinglePrice = nNeedDaibi
	g_T3BianJingGashapon_MBuy_LimitNum = nLimit
	g_T3BianJingGashapon_MBuy_MaxMoney = money
	g_T3BianJingGashapon_MBuy_ReduceNum = curbuycnt

	T3BianJingGashapon_MBuy_InputNum:SetProperty("DefaultEditBox", "True");
	T3BianJingGashapon_MBuy_InputNum:SetText("1")
	
	local num = tonumber(T3BianJingGashapon_MBuy_InputNum:GetText())
	if shoptype == 1 then
		T3BianJingGashapon_MBuy_Price:SetText("#{PTLS_200902_45}")
		T3BianJingGashapon_MBuy_Cash:SetText("#{PTLS_200902_47}")
		T3BianJingGashapon_MBuy_PriceNum:SetText("#L".. nNeedDaibi*num)

		if money >= nNeedDaibi*num then
			T3BianJingGashapon_MBuy_CashNum:SetText( "#M".. tostring(money) )
		else
			T3BianJingGashapon_MBuy_CashNum:SetText( "#cff0000" .. tostring(money) )
		end

		g_T3BianJingGashapon_MBuy_PageNum = 1
	elseif shoptype == 2 then
		T3BianJingGashapon_MBuy_Price:SetText("#{PTLS_200902_162}")
		T3BianJingGashapon_MBuy_Cash:SetText("#{PTLS_200902_163}")
		T3BianJingGashapon_MBuy_PriceNum:SetText("#L".. nNeedDaibi*num)

		if money >= nNeedDaibi*num then
			T3BianJingGashapon_MBuy_CashNum:SetText( "#M".. tostring(money) )
		else
			T3BianJingGashapon_MBuy_CashNum:SetText( "#cff0000" .. tostring(money) )
		end

		g_T3BianJingGashapon_MBuy_PageNum = 2
	end
end

function T3BianJingGashapon_MBuy_TextChanged()
	local text = T3BianJingGashapon_MBuy_InputNum:GetText()
	if text == "" then
		num = 0
	else
		num = tonumber(T3BianJingGashapon_MBuy_InputNum:GetText())
	end

	if(num == nil or num < 0) then
		T3BianJingGashapon_MBuy_InputNum:SetText("")
		return
	end

	local ClaMax = 1
	if g_T3BianJingGashapon_MBuy_PageNum ~= nil then
		ClaMax = math.floor(tonumber(g_T3BianJingGashapon_MBuy_MaxMoney)/tonumber(g_T3BianJingGashapon_MBuy_SinglePrice))
		if g_T3BianJingGashapon_MBuy_LimitNum ~= 0 then
			if ClaMax > (g_T3BianJingGashapon_MBuy_LimitNum-g_T3BianJingGashapon_MBuy_ReduceNum) then
				ClaMax = g_T3BianJingGashapon_MBuy_LimitNum-g_T3BianJingGashapon_MBuy_ReduceNum
			end
		end
	end

	if num > ClaMax and ClaMax > 0 then
		num = ClaMax
		T3BianJingGashapon_MBuy_InputNum:SetText(tostring(num))
	end

	if g_T3BianJingGashapon_MBuy_PageNum == 1 then
		T3BianJingGashapon_MBuy_PriceNum:SetText("#L".. g_T3BianJingGashapon_MBuy_SinglePrice*num) --需要代币
		if g_T3BianJingGashapon_MBuy_MaxMoney >= g_T3BianJingGashapon_MBuy_SinglePrice*num then
			T3BianJingGashapon_MBuy_CashNum:SetText( "#M".. tostring(g_T3BianJingGashapon_MBuy_MaxMoney) ) --拥有代币
		else
			T3BianJingGashapon_MBuy_CashNum:SetText( "#cff0000" .. tostring(g_T3BianJingGashapon_MBuy_MaxMoney) )
		end
	elseif g_T3BianJingGashapon_MBuy_PageNum == 2 then
		T3BianJingGashapon_MBuy_PriceNum:SetText("#L".. g_T3BianJingGashapon_MBuy_SinglePrice*num)
		if g_T3BianJingGashapon_MBuy_MaxMoney >= g_T3BianJingGashapon_MBuy_SinglePrice*num then
			T3BianJingGashapon_MBuy_CashNum:SetText( "#M".. tostring(g_T3BianJingGashapon_MBuy_MaxMoney) )
		else
			T3BianJingGashapon_MBuy_CashNum:SetText( "#cff0000" .. tostring(g_T3BianJingGashapon_MBuy_MaxMoney) )
		end
	end
end

function T3BianJingGashapon_MBuy_Close_Clicked()
	this:Hide()
end

function T3BianJingGashapon_MBuy_CalMax()
	local reduce = 1

	reduce = math.floor(tonumber(g_T3BianJingGashapon_MBuy_MaxMoney)/tonumber(g_T3BianJingGashapon_MBuy_SinglePrice))

	if g_T3BianJingGashapon_MBuy_LimitNum ~= 0 then
		if reduce > (g_T3BianJingGashapon_MBuy_LimitNum-g_T3BianJingGashapon_MBuy_ReduceNum) then --剩余次数
			reduce = g_T3BianJingGashapon_MBuy_LimitNum-g_T3BianJingGashapon_MBuy_ReduceNum
		end
	end

	T3BianJingGashapon_MBuy_InputNum:SetText(tostring(reduce))

	return reduce
end

function T3BianJingGashapon_MBuy_OK_Clicked()
	local text = T3BianJingGashapon_MBuy_InputNum:GetText()
	if text == "" then
		PushDebugMessage("#{PTLS_200902_93}")
		return
	end
	
	local num = tonumber(T3BianJingGashapon_MBuy_InputNum:GetText())

	if g_T3BianJingGashapon_MBuy_PageNum ~= 1 and g_T3BianJingGashapon_MBuy_PageNum ~= 2 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoExchange" )
		Set_XSCRIPT_ScriptID(888206)
		Set_XSCRIPT_Parameter(0,g_T3BianJingGashapon_MBuy_PageNum)
		Set_XSCRIPT_Parameter(1,g_T3BianJingGashapon_MBuy_ItemSelectIndex)
		Set_XSCRIPT_Parameter(2,tonumber(num))
		Set_XSCRIPT_Parameter(3,1)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()

end

function T3BianJingGashapon_MBuy_OnHidden()
	this:Hide()
end

