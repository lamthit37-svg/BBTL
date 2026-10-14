local g_TreasureBox_MBuy_UnifiedPosition
local g_TreasureBox_MBuy_MaxLibaoCount = 3
local g_TreasureBox_MBuy_ItemSelectIndex
local g_TreasureBox_MBuy_SinglePrice = 1
local g_TreasureBox_MBuy_ReduceNum = 0
local g_TreasureBox_MBuy_LimitNum = 0
local g_TreasureBox_MBuy_PageNum = 0
local g_TreasureBox_MBuy_MaxMoney = 0
local g_TreasureBox_MBuy_MaxOnceNum = 500

function TreasureBox_MBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function TreasureBox_MBuy_OnLoad()	
	g_TreasureBox_MBuy_UnifiedPosition = TreasureBox_MBuy_Frame:GetProperty("UnifiedPosition")

	g_TreasureBox_MBuy_SinglePrice = 1
	g_TreasureBox_MBuy_ReduceNum = 0
	g_TreasureBox_MBuy_LimitNum = 0
	g_TreasureBox_MBuy_PageNum = 0
	g_TreasureBox_MBuy_MaxMoney = 0
end

function TreasureBox_MBuy_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88819002 ) then
		TreasureBox_MBuy_Update( tonumber(arg1), tonumber(arg2), tonumber(arg3) )
		g_TreasureBox_MBuy_PageNum = 1
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88819004 ) then
		TreasureBox_MBuy_Update2( tonumber(arg1), tonumber(arg2), tonumber(arg3), tonumber(arg4), tonumber(arg5), tonumber(arg6) )
		this:Show()
	elseif (event == "ADJEST_UI_POS" ) then
		TreasureBox_MBuy_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TreasureBox_MBuy_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function TreasureBox_MBuy_On_ResetPos()
	TreasureBox_MBuy_Frame:SetProperty("UnifiedPosition", g_TreasureBox_MBuy_UnifiedPosition);
end

function TreasureBox_MBuy_Update( tbIndex, nIndex, curbuynum )
	TreasureBox_MBuy_DragTitle:SetText("#{RCLS_200731_142}")

	local nCount = GetLashouShopLibaoCount(tbIndex)
	if nCount == 0  or nCount > g_TreasureBox_MBuy_MaxLibaoCount then
		return
	end

	g_TreasureBox_MBuy_ItemSelectIndex = nIndex

	local nItemShowId, nItemNum, nLimit, nDisCount, nYB = GetLashouShopLibaoItem( tbIndex, nIndex )
	
	if nItemShowId < 0 then
		return
	end
	
	local theAction = DataPool:CreateActionItemForShow(nItemShowId, nItemNum)
	TreasureBox_MBuy_But:SetActionItem(theAction:GetID())
	TreasureBox_MBuy_ItemInfo_Text:SetText( ScriptGlobal_Format( "#{RCLS_200731_143}", theAction:GetName() ) )

	if nDisCount < 100 then
		TreasureBox_MBuy_ItemInfo_Text2:SetText(ScriptGlobal_Format( "#{RCLS_200731_156}", (400*nItemNum)))
		TreasureBox_MBuy_ItemInfo_Text2_OriginalLine:Show()
		TreasureBox_MBuy_ItemInfo_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_144}", nYB))
	else
		TreasureBox_MBuy_ItemInfo_Text2:SetText("")
		TreasureBox_MBuy_ItemInfo_Text2_OriginalLine:Hide()
		TreasureBox_MBuy_ItemInfo_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_156}", nYB))
	end

	g_TreasureBox_MBuy_SinglePrice = nYB	
	g_TreasureBox_MBuy_ReduceNum = curbuynum
	
	if nLimit ~= nil and nLimit > 0 then
		g_TreasureBox_MBuy_LimitNum = nLimit
		if g_TreasureBox_MBuy_ReduceNum >= nLimit then
			TreasureBox_MBuy_ItemInfo_Lilianzhi2:SetText("#{RCLS_200731_154}") --售罄
		else
			TreasureBox_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format( "#{RCLS_200731_155}", g_TreasureBox_MBuy_ReduceNum, nLimit))
		end
	else
		g_TreasureBox_MBuy_LimitNum = 0
		TreasureBox_MBuy_ItemInfo_Lilianzhi2:SetText("#{RCLS_260330_03}")
	end
	
	TreasureBox_MBuy_Price:SetText("#{RCLS_200731_147}")
	TreasureBox_MBuy_Cash:SetText("#{RCLS_200731_149}")

	TreasureBox_MBuy_InputNum:SetProperty("DefaultEditBox", "True");
	TreasureBox_MBuy_InputNum:SetText("1")
	TreasureBox_MBuy_InputNum:SetSelected( 0, -1 );
	local num = tonumber(TreasureBox_MBuy_InputNum:GetText())
	TreasureBox_MBuy_Price_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_148}", nYB*num))

	local takeYB = Player:GetData("YUANBAO")

	if takeYB >= nYB*num then
		TreasureBox_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_151}", Player:GetData("YUANBAO")))
	else
		TreasureBox_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_150}", Player:GetData("YUANBAO")))
	end
end

function TreasureBox_MBuy_Update2( tbIndex, shoptype, curpage, nIndex, curbuycnt, money )
	TreasureBox_MBuy_DragTitle:SetText("#{RCLS_200731_172}")

	local nID, nNeedDaibi, nShowItemId, nItemNum, nLimit, nLimitType = GetLashouShopDuihuanItem( tbIndex, shoptype, nIndex+(curpage-1)*9 )

	if nID < 0 then
		return
	end

	local theAction = DataPool:CreateActionItemForShow(nShowItemId, nItemNum)
	TreasureBox_MBuy_But:SetActionItem(theAction:GetID())
	TreasureBox_MBuy_ItemInfo_Text:SetText( ScriptGlobal_Format( "#{RCLS_200731_143}", theAction:GetName() ) )

	if shoptype == 1 then
		TreasureBox_MBuy_ItemInfo_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_173}", nNeedDaibi ) )
	else
		TreasureBox_MBuy_ItemInfo_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_174}", nNeedDaibi ) )
	end

	TreasureBox_MBuy_ItemInfo_Text2:SetText("")
	TreasureBox_MBuy_ItemInfo_Text2_OriginalLine:Hide()

	if nLimit == 0 then
		TreasureBox_MBuy_ItemInfo_Lilianzhi2:SetText("")
	elseif curbuycnt >= nLimit then
		if nLimitType == 1 then
			TreasureBox_MBuy_ItemInfo_Lilianzhi2:SetText( ScriptGlobal_Format("#{RCLS_200731_175}",nLimit,nLimit) )
		else
			TreasureBox_MBuy_ItemInfo_Lilianzhi2:SetText( ScriptGlobal_Format("#{RCLS_200731_177}",nLimit,nLimit) )
		end
	else
		if nLimitType == 1 then
			TreasureBox_MBuy_ItemInfo_Lilianzhi2:SetText( ScriptGlobal_Format( "#{RCLS_200731_176}", curbuycnt, nLimit ) )
		else
			TreasureBox_MBuy_ItemInfo_Lilianzhi2:SetText( ScriptGlobal_Format( "#{RCLS_200731_178}", curbuycnt, nLimit ) )
		end
	end

	g_TreasureBox_MBuy_ItemSelectIndex = nIndex+(curpage-1)*9
	g_TreasureBox_MBuy_SinglePrice = nNeedDaibi
	g_TreasureBox_MBuy_LimitNum = nLimit
	g_TreasureBox_MBuy_MaxMoney = money
	g_TreasureBox_MBuy_ReduceNum = curbuycnt

	TreasureBox_MBuy_InputNum:SetProperty("DefaultEditBox", "True");
	TreasureBox_MBuy_InputNum:SetText("1")
	TreasureBox_MBuy_InputNum:SetSelected( 0, -1 );
	local num = tonumber(TreasureBox_MBuy_InputNum:GetText())
	if shoptype == 1 then
		TreasureBox_MBuy_Price:SetText("#{RCLS_200731_179}")
		TreasureBox_MBuy_Cash:SetText("#{RCLS_200731_181}")

		TreasureBox_MBuy_Price_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_148}", nNeedDaibi*num ) )

		if money >= nNeedDaibi*num then
			TreasureBox_MBuy_Cash_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_151}", money ) )
		else
			TreasureBox_MBuy_Cash_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_150}", money ) )
		end

		g_TreasureBox_MBuy_PageNum = 2
	elseif shoptype == 2 then
		TreasureBox_MBuy_Price:SetText("#{RCLS_200731_180}")
		TreasureBox_MBuy_Cash:SetText("#{RCLS_200731_182}")

		TreasureBox_MBuy_Price_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_148}", nNeedDaibi*num ) )

		if money >= nNeedDaibi*num then
			TreasureBox_MBuy_Cash_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_151}", money ) )
		else
			TreasureBox_MBuy_Cash_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_150}", money ) )
		end

		g_TreasureBox_MBuy_PageNum = 3
	end
end

function TreasureBox_MBuy_TextChanged()
	local num = tonumber(TreasureBox_MBuy_InputNum:GetText())
	if(num == nil or num < 1) then
		TreasureBox_MBuy_InputNum:SetText("1")
		return
	end

	local ClaMax = 1
	if g_TreasureBox_MBuy_PageNum ~= nil and g_TreasureBox_MBuy_PageNum == 1 then
		local takeYB = Player:GetData("YUANBAO")
		ClaMax = math.floor(tonumber(takeYB)/tonumber(g_TreasureBox_MBuy_SinglePrice))

		if g_TreasureBox_MBuy_LimitNum > 0 then
			if ClaMax > (g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum) then
				ClaMax = g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum
			end
		else
			if ClaMax > g_TreasureBox_MBuy_MaxOnceNum then
				ClaMax = g_TreasureBox_MBuy_MaxOnceNum
			end
		end
	elseif g_TreasureBox_MBuy_PageNum ~= nil and g_TreasureBox_MBuy_PageNum == 2 then
		ClaMax = math.floor(tonumber(g_TreasureBox_MBuy_MaxMoney)/tonumber(g_TreasureBox_MBuy_SinglePrice))

		if g_TreasureBox_MBuy_LimitNum ~= 0 then
			if ClaMax > (g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum) then
				ClaMax = g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum
			end
		end
	elseif g_TreasureBox_MBuy_PageNum ~= nil and g_TreasureBox_MBuy_PageNum == 3 then
		ClaMax = math.floor(tonumber(g_TreasureBox_MBuy_MaxMoney)/tonumber(g_TreasureBox_MBuy_SinglePrice))

		if g_TreasureBox_MBuy_LimitNum ~= 0 then
			if ClaMax > (g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum) then
				ClaMax = g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum
			end
		end
	end

	if num > ClaMax and ClaMax > 0 then
		num = ClaMax
		TreasureBox_MBuy_InputNum:SetText(tostring(num))
	end

	if g_TreasureBox_MBuy_PageNum == 1 then
		TreasureBox_MBuy_Price_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_148}", g_TreasureBox_MBuy_SinglePrice*num))

		local takeYB = Player:GetData("YUANBAO")
		if takeYB >= g_TreasureBox_MBuy_SinglePrice*num then
			TreasureBox_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_151}", Player:GetData("YUANBAO")))
		else
			TreasureBox_MBuy_Cash_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_150}", Player:GetData("YUANBAO")))
		end
	elseif g_TreasureBox_MBuy_PageNum == 2 then
		TreasureBox_MBuy_Price_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_148}", g_TreasureBox_MBuy_SinglePrice*num))

		if g_TreasureBox_MBuy_MaxMoney >= g_TreasureBox_MBuy_SinglePrice*num then
			TreasureBox_MBuy_Cash_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_151}", g_TreasureBox_MBuy_MaxMoney ) )
		else
			TreasureBox_MBuy_Cash_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_150}", g_TreasureBox_MBuy_MaxMoney ) )
		end
	elseif g_TreasureBox_MBuy_PageNum == 3 then
		TreasureBox_MBuy_Price_Lilianzhi:SetText(ScriptGlobal_Format( "#{RCLS_200731_148}", g_TreasureBox_MBuy_SinglePrice*num))

		if g_TreasureBox_MBuy_MaxMoney >= g_TreasureBox_MBuy_SinglePrice*num then
			TreasureBox_MBuy_Cash_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_151}", g_TreasureBox_MBuy_MaxMoney ) )
		else
			TreasureBox_MBuy_Cash_Lilianzhi:SetText( ScriptGlobal_Format( "#{RCLS_200731_150}", g_TreasureBox_MBuy_MaxMoney ) )
		end
	end
end

function TreasureBox_MBuy_Close_Clicked()
	this:Hide()
end

function TreasureBox_MBuy_CalMax()
	local reduce = 1
	if g_TreasureBox_MBuy_PageNum == 1 then
		local takeYB = Player:GetData("YUANBAO")
		reduce = math.floor(tonumber(takeYB)/tonumber(g_TreasureBox_MBuy_SinglePrice))

		if g_TreasureBox_MBuy_LimitNum > 0 then
			if reduce > (g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum) then
				reduce = g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum
			end
		else
			if reduce > g_TreasureBox_MBuy_MaxOnceNum then
				reduce = g_TreasureBox_MBuy_MaxOnceNum
			end
		end

		TreasureBox_MBuy_InputNum:SetText(tostring(reduce))
	elseif g_TreasureBox_MBuy_PageNum == 2 then
		reduce = math.floor(tonumber(g_TreasureBox_MBuy_MaxMoney)/tonumber(g_TreasureBox_MBuy_SinglePrice))

		if g_TreasureBox_MBuy_LimitNum ~= 0 then
			if reduce > (g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum) then
				reduce = g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum
			end
		end

		TreasureBox_MBuy_InputNum:SetText(tostring(reduce))
	elseif g_TreasureBox_MBuy_PageNum == 3 then
		reduce = math.floor(tonumber(g_TreasureBox_MBuy_MaxMoney)/tonumber(g_TreasureBox_MBuy_SinglePrice))

		if g_TreasureBox_MBuy_LimitNum ~= 0 then
			if reduce > (g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum) then
				reduce = g_TreasureBox_MBuy_LimitNum-g_TreasureBox_MBuy_ReduceNum
			end
		end

		TreasureBox_MBuy_InputNum:SetText(tostring(reduce))
	end

	return reduce
end

function TreasureBox_MBuy_OK_Clicked()
	local num = tonumber(TreasureBox_MBuy_InputNum:GetText())

	if g_TreasureBox_MBuy_PageNum == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyLibao" )
			Set_XSCRIPT_ScriptID(888143)
			Set_XSCRIPT_Parameter( 0, g_TreasureBox_MBuy_ItemSelectIndex )
			Set_XSCRIPT_Parameter( 1, num )
			Set_XSCRIPT_Parameter( 2, 1 )
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	elseif g_TreasureBox_MBuy_PageNum == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoExchange" )
			Set_XSCRIPT_ScriptID(888143)
			Set_XSCRIPT_Parameter(0,g_TreasureBox_MBuy_PageNum-1)
			Set_XSCRIPT_Parameter(1,g_TreasureBox_MBuy_ItemSelectIndex)
			Set_XSCRIPT_Parameter(2,tonumber(num))
			Set_XSCRIPT_Parameter(3,1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	elseif g_TreasureBox_MBuy_PageNum == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "DoExchange" )
			Set_XSCRIPT_ScriptID(888143)
			Set_XSCRIPT_Parameter(0,g_TreasureBox_MBuy_PageNum-1)
			Set_XSCRIPT_Parameter(1,g_TreasureBox_MBuy_ItemSelectIndex)
			Set_XSCRIPT_Parameter(2,tonumber(num))
			Set_XSCRIPT_Parameter(3,1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	end
end

function TreasureBox_MBuy_OnHidden()
	this:Hide()
end

