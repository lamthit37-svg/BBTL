
local g_SelectCharHeadFrame_Frame_UnifiedPosition;
local g_ExteriorType = 6 --头像框
local g_clientNpcId = -1
local g_MaxBarNum = 0
local g_BarList = {}
local g_CurSelExteriorID = 0		--当前选择的外观ID，从1开始
local g_CurSelExteriorIndex = 0		--当前选择的外观索引，从1开始
--物品在背包中的位置
local g_posItem	= -1

--女神称号id
local nNvShenTitleID = 289
local nNvShenTitleIDEx = 290

local g_ExteriorIDTable = {}  --通过charheadframe表中的id 获取的exteriorid

function SelectCharHeadFrame_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("REFRESH_SELFHEADFRAME",false)
	this:RegisterEvent("UNIT_HEADFRAME",false)
	this:RegisterEvent("UPDATE_HEADFRAMEITEM",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("NVSHEN_UI_SHOW_2DHEAD",false)

	this:RegisterEvent("UPDATE_EXTERIOR",false)
	this:RegisterEvent("EXTERIOR_OUTTIME",false)	
end

--==================================
-- SelectCharHeadFrame_OnLoad
--==================================
function SelectCharHeadFrame_OnLoad()
	g_SelectCharHeadFrame_Frame_UnifiedPosition=SelectCharHeadFrame_Frame:GetProperty("UnifiedPosition");
	-- SelectCharHeadFrame_LeftClient_StyleList:Hide()
end

function SelectCharHeadFrame_Frame_On_ResetPos()
  	SelectCharHeadFrame_Frame:SetProperty("UnifiedPosition", g_SelectCharHeadFrame_Frame_UnifiedPosition);
end
--==================================
-- SelectCharHeadFrame_OnEvent
--==================================
function SelectCharHeadFrame_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 201702171) then
		local npcObjId = Get_XParam_INT(0)
		g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
		if g_clientNpcId == -1 then
			PushDebugMessage("未发现 NPC")
			SelectCharHeadFrame_Close()
			return
		end
		this:CareObject( g_clientNpcId, 1, "SelectCharHeadFrame" )

		if(IsWindowShow("SelectHeadstyle")) then
			CloseWindow("SelectHeadstyle", true);
		end

		if(IsWindowShow("SelectHairstyle")) then
			CloseWindow("SelectHairstyle", true);
		end

		if(IsWindowShow("SelectHairColor")) then
			CloseWindow("SelectHairColor", true);
		end

		if(IsWindowShow("SelectFacestyle")) then
			CloseWindow("SelectFacestyle", true);
		end

		SelectCharHeadFrame_OnShown();
		this:Show();
	
	elseif (event == "ADJEST_UI_POS" ) then
		SelectCharHeadFrame_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SelectCharHeadFrame_Frame_On_ResetPos()
			
	elseif( event == "UPDATE_HEADFRAMEITEM" ) then
		--更新放入物品
		if arg0 == nil then
			return
		end
		-- PushDebugMessage("UPDATE_HEADFRAMEITEM")
		local pos = tonumber(arg0)
		--取消道具
		if g_posItem ~= -1 and g_posItem == pos then
			if SelectCharHeadFrame_RightClient2:IsVisible() then
				SelectCharHeadFrame_ItemClear()
			elseif SelectCharHeadFrame_RightClient5:IsVisible() then
				SelectCharHeadFrame_ItemClear_XuQi()
				-- if g_ExteriorIDTable[nId] ~= nil then
				-- 	SelectCharHeadFrame_ItemClicked(g_ExteriorIDTable[nId]) --跳转到放入的头像框道具对应的头像框展示
				-- end
			end
			return
		end
		local theAction	= EnumAction( pos, "packageitem" )
		if theAction:GetID() == 0 then
			PushDebugMessage("#{TXKS_170208_47}")
			return
		end
		local ItemId = PlayerPackage : GetItemTableIndex( pos )
		local nId, nCanUseTime, nExpiryDate = DataPool : GetHeadFrameTimeFromTable(ItemId)
		if nId < 1 then
			PushDebugMessage("#{TXKS_170208_47}")
			return
		end

		if g_ExteriorIDTable[nId] ~= nil then
			SelectCharHeadFrame_LeftClient_StyleList:SetScrollPosition4Index(g_ExteriorIDTable[nId] - 1)
			SelectCharHeadFrame_ItemClicked(g_ExteriorIDTable[nId]) --跳转到放入的头像框道具对应的头像框展示
		end
		if SelectCharHeadFrame_RightClient2:IsVisible() then
			SelectCharHeadFrame_ItemClear()
			SelectCharHeadFrame_ItemUpdate( pos )
			return
		end

		if SelectCharHeadFrame_RightClient5:IsVisible() then
			SelectCharHeadFrame_ItemClear_XuQi()
			SelectCharHeadFrame_ItemUpdate_XuQi( pos )
		end

	elseif( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		if( arg0 ~= nil and -1 == tonumber(arg0) ) then
			return
		end
		if( arg0 ~= nil and g_posItem == tonumber(arg0) ) then
			if SelectCharHeadFrame_RightClient2:IsVisible() then
				SelectCharHeadFrame_ItemClear()
				SelectCharHeadFrame_ItemUpdate( tonumber(arg0) )
			elseif SelectCharHeadFrame_RightClient5:IsVisible() then
				SelectCharHeadFrame_ItemClear_XuQi()
				SelectCharHeadFrame_ItemUpdate_XuQi( tonumber(arg0) )
			end
		end
	elseif (event == "REFRESH_SELFHEADFRAME") then
		SelectCharHeadFrame_Update()
	elseif (event == "UPDATE_EXTERIOR") then
		SelectCharHeadFrame_Update()
	elseif (event == "REFRESH_SELFHEADFRAME") then
		SelectCharHeadFrame_Update()
	elseif( (event == "EXTERIOR_OUTTIME") and (arg0 == "player") ) then
		SelectCharHeadFrame_Update()
	elseif ( event == "NVSHEN_UI_SHOW_2DHEAD" ) then
		SelectCharHeadFrame_Update()
	end

end


function SelectCharHeadFrame_OnShown()

	local cacheExteriorFrameID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
	if cacheExteriorFrameID > 0 then
		g_CurSelExteriorID = cacheExteriorFrameID
	end

	-- 得到当前的头像
	local strFaceImage = Player:GetData( "PORTRAIT" );
	SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_CharHead:SetProperty("NormalImage", tostring(strFaceImage))
	SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_CharHead:SetProperty("HoverImage", tostring(strFaceImage))

	SelectCharHeadFrame_Update()

end

function SelectCharHeadFrame_Update()

	SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_CharHeadFrame:SetProperty("Image", "")
	SelectCharHeadFrame_RightClient1_CharHeadFrameTitle_text:SetText("")
	SelectCharHeadFrame_RightClient1_CharHeadFrameFrom:SetText("")
	SelectCharHeadFrame_RightClient1_CharHeadFrameLimitTime:SetText("")
	SelectCharHeadFrame_RightClient2:Hide()
	SelectCharHeadFrame_RightClient5:Hide()
	SelectCharHeadFrame_RightClient3_Dec:SetText("")
	SelectCharHeadFrame_RightClient3:Show()
	SelectCharHeadFrame_ItemClear()


	Exterior:LuaFnInitExteriorList(g_ExteriorType)
	g_MaxBarNum = Exterior:LuaFnGetExteriorMaxCount(g_ExteriorType)
	SelectCharHeadFrame_LeftClient_StyleList:Clear()
	for i = 1, g_MaxBarNum do
		local bar = SelectCharHeadFrame_LeftClient_StyleList:AddChild("SelectCharHeadFrame_LeftClient_List1")
		g_BarList[i] = bar	
		bar:GetSubItem("SelectCharHeadFrame_List1_Lace_BKG"):SetEvent("MouseLButtonDown", string.format("SelectCharHeadFrame_ItemClicked(%d)", i))
		bar:GetSubItem("SelectCharHeadFrame_List1_Lace_BKG"):SetEvent("MouseMove", string.format("SelectCharHeadFrame_ItemMouseMove(%d)", i))
		SelectCharHeadFrame_SetItem(i)
	end
	
	SelectCharHeadFrame_ShowDetail()
end

function SelectCharHeadFrame_SetItem(index)
	if g_BarList[index] == nil then
		return
	end
	local bar = g_BarList[index]
	bar:Show()
	local nExteriorID = Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, index - 1)

	local nId, nFrameName, nDisplayItem, nCostMoney, nGetInfo, nType, nIconFile, nAnimate = Exterior:LuaFnGetExteriorFrameStyleInfo(nExteriorID)
	
	-- local MyHeadFrameID = Player:GetData( "HEADFRAMEID" )
	-- --女神特写
	-- if Player:Player_GetTitleType() == nNvShenTitleID or Player:Player_GetTitleType() == nNvShenTitleIDEx then
	-- 	MyHeadFrameID = 2
	-- end

	if nId>0 then
		g_ExteriorIDTable[nId] = index
		local ctrlAction = bar:GetSubItem("SelectCharHeadFrame_List1_Lace_BKG")
		if ctrlAction ~= nil then
				-- 女神边框进行特写
			if nId == 2 then
				nIconFile = "CharHeadFrame1_GirlPlayer"
			end
			
			if nType == 1 then			
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				
				bar:GetSubItem("SelectCharHeadFrame_List1_Lace_Animate"):Show()
				bar:GetSubItem("SelectCharHeadFrame_List1_Lace_Animate"):SetProperty("Animate", tostring(nAnimate))
			else
				bar:GetSubItem("SelectCharHeadFrame_List1_Lace_Animate"):SetProperty("Animate", "")
				bar:GetSubItem("SelectCharHeadFrame_List1_Lace_Animate"):Hide()
				
				local IconFile = GetIconFullName(nIconFile)
				ctrlAction:SetProperty("NormalImage", IconFile)
				ctrlAction:SetProperty("HoverImage", IconFile)				
			end
			
			ctrlAction:SetToolTip("")
			bar:GetSubItem("SelectCharHeadFrame_List1_Lace_Nothing"):Hide()
			bar:GetSubItem("SelectCharHeadFrame_List1_text"):SetText("#cfff263"..nFrameName)
			if g_CurSelExteriorID == nExteriorID then
				ctrlAction:SetPushed(1)
				bar:GetSubItem("SelectCharHeadFrame_List1_Lace_Use"):Show()
			else
				ctrlAction:SetPushed(0)
				bar:GetSubItem("SelectCharHeadFrame_List1_Lace_Use"):Hide()
			end
		end
		if Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then		
			bar:GetSubItem("SelectCharHeadFrame_List1_Lace_Lock"):Hide()
		else
			bar:GetSubItem("SelectCharHeadFrame_List1_Lace_Lock"):Show()
		end	
	end
	
end

function SelectCharHeadFrame_ItemClicked(nIndex)
	if nIndex<1 or nIndex>g_MaxBarNum then
		return
	end
	SelectCharHeadFrame_ItemClear()
	SelectCharHeadFrame_ItemClear_XuQi()
	
	g_CurSelExteriorIndex = nIndex
	local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, nIndex - 1)
	-- PushDebugMessage("nExteriorID:"..tostring(nExteriorID))
	g_CurSelExteriorID = nExteriorID
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("SelectCharHeadFrame_List1_Lace_BKG")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
	SelectCharHeadFrame_ShowDetail()
end

function SelectCharHeadFrame_ShowDetail()
	local nId, nFrameName, nDisplayItem, nCostMoney, nGetInfo, nType, nIconFile, nAnimate = Exterior:LuaFnGetExteriorFrameStyleInfo(g_CurSelExteriorID)
	SelectCharHeadFrame_RightClient1_CharHeadFrameTitle_text:SetText( ScriptGlobal_Format("#{TXKS_170208_05}", nFrameName) )
	
	if nType == 1 then
		SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_CharHeadFrame:SetProperty("Image", "")
		SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_CharHeadFrame:Hide()
		
		SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_Animate:Show()
		SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_Animate:SetProperty("Animate", tostring(nAnimate))
	else
		SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_CharHeadFrame:Show()
		local IconFile = GetIconFullName(nIconFile)
		SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_CharHeadFrame:SetProperty("Image", IconFile)
		
		SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_Animate:SetProperty("Animate", "")
		SelectCharHeadFrame_RightClient1_CharHeadFrameSelected_Animate:Hide()
	end	
	
	SelectCharHeadFrame_RightClient1_CharHeadFrameFrom:SetText("#cfff263"..nGetInfo)
	local isHave = Exterior:LuaFnIsHaveExterior(g_ExteriorType, g_CurSelExteriorID)
	local nLeftTime = Exterior:LuaFnGetExteriorLeftTime(g_ExteriorType, g_CurSelExteriorID)
	-- PushDebugMessage("nLeftTime:"..tostring(nLeftTime))
	-- PushDebugMessage("nLeftTime:"..tostring(nLeftTime))
	--按钮显示
	if isHave == 1 then
		-- SelectCharHeadFrame_Del:SetText("#{TXKS_170208_13}")
		-- SelectCharHeadFrame_Del:SetToolTip("#{TXKJM_171127_08}")
		-- SelectCharHeadFrame_Del:Show()
		SelectCharHeadFrame_Cancel:SetText("#{TXKS_170208_12}")
		SelectCharHeadFrame_Cancel:Show()
		if nLeftTime<0 then
			-- 永久
			SelectCharHeadFrame_Accept:Hide()
		else
			-- 拥有但不永久
			SelectCharHeadFrame_Accept:SetText("#{TXKYH_170927_01}")
			SelectCharHeadFrame_Accept:SetToolTip("#{TXKYH_170927_02}")
			SelectCharHeadFrame_Accept:Show()
		end
	else
		-- 未拥有
		SelectCharHeadFrame_Accept:SetText("#{TXKS_170208_11}")
		SelectCharHeadFrame_Accept:SetToolTip("#{TXKJM_171127_09}")
		SelectCharHeadFrame_Accept:Show()
		-- SelectCharHeadFrame_Del:Hide()
		SelectCharHeadFrame_Cancel:Hide()
	end
	-- PushDebugMessage("isHave:"..tostring(isHave))
	-- PushDebugMessage("nLeftTime:"..tostring(nLeftTime))
	if isHave == 1 then
		if nLeftTime<0 then
			SelectCharHeadFrame_RightClient1_CharHeadFrameLimitTime:SetText("#{TXKJM_171127_02}")
		else
			--需要设置一下剩余时间
			local nLeftTimeStrFormat = Exterior:LuaFnGetExteriorParam(g_ExteriorType, g_CurSelExteriorID)
			local str =	SelectCharHeadFrame_ConvertToData(nLeftTimeStrFormat)
			-- PushDebugMessage("nLeftTime:"..tostring(nLeftTime))
			SelectCharHeadFrame_RightClient1_CharHeadFrameLimitTime:SetText(str)
		end
	else

		SelectCharHeadFrame_RightClient1_CharHeadFrameLimitTime:SetText("#{TXKJM_171127_01}")
	end

	local MyHeadFrameID = Player:GetData( "HEADFRAMEID" )
	SelectCharHeadFrame_RightClient5:Hide()
	--女神框需要特写  还有续期的处理
	--女神特写
	if Player:Player_GetTitleType() == nNvShenTitleID or Player:Player_GetTitleType() == nNvShenTitleIDEx then
		MyHeadFrameID = 2
	end
	-- 女神边框进行特写 ID为2
	if nId == 2 then
		SelectCharHeadFrame_RightClient3_Dec:SetText("#{TXKS_170208_40}")
		SelectCharHeadFrame_RightClient3:Show()
		SelectCharHeadFrame_RightClient2:Hide()
		if isHave > 0 and MyHeadFrameID == 2 then --已有+正在使用
			SelectCharHeadFrame_Cancel:SetText("#{TXKS_170208_15}")
			SelectCharHeadFrame_Cancel:Show()
			-- SelectCharHeadFrame_Del:Hide()
			SelectCharHeadFrame_Accept:Hide()
		else --未激活 或 未使用中
			SelectCharHeadFrame_Cancel:SetText("#{TXKS_170208_12}")
			SelectCharHeadFrame_Cancel:Show()
			-- SelectCharHeadFrame_Del:Hide()
			SelectCharHeadFrame_Accept:Hide()
		end
		return
	end
	-- PushDebugMessage("isHave:"..tostring(isHave))
	if isHave == 0 then --未拥有
		SelectCharHeadFrame_RightClient2_NeedMoney:SetProperty("MoneyNumber", tostring(nCostMoney))
		SelectCharHeadFrame_RightClient5_NeedMoney:SetProperty("MoneyNumber", tostring(nCostMoney))
		SelectCharHeadFrame_RightClient2:Show()
		SelectCharHeadFrame_RightClient3:Hide()
	elseif MyHeadFrameID == nId then -- 正在使用中
		SelectCharHeadFrame_RightClient3_Dec:SetText("")
		SelectCharHeadFrame_RightClient3:Show()
		SelectCharHeadFrame_RightClient2:Hide()

	else
		SelectCharHeadFrame_RightClient3_Dec:SetText("")
		SelectCharHeadFrame_RightClient3:Show()
		SelectCharHeadFrame_RightClient2:Hide()
	end

	if isHave == 1 and nLeftTime > 0 then
		-- PushDebugMessage("isHave2:"..tostring(isHave))
		--续期界面
		SelectCharHeadFrame_RightClient2:Hide()
		SelectCharHeadFrame_RightClient3:Hide()
		SelectCharHeadFrame_RightClient5:Show()
		SelectCharHeadFrame_ItemClear_XuQi()
	end

end

function SelectCharHeadFrame_ItemUpdate(pos)
	local theAction = EnumAction( pos, "packageitem" )
	if theAction:GetID() ~= 0 then

		local ItemId = PlayerPackage : GetItemTableIndex( pos )
		local ret, nCanUseTime, nExpiryDate = DataPool : GetHeadFrameTimeFromTable(ItemId)

		if ret < 1 then
			PushDebugMessage("#{TXKS_170208_47}")
			return
		end

		local ItemName = PlayerPackage:GetItemName(ItemId)
		if PlayerPackage : IsLock( pos ) == 1 then
			PushDebugMessage( ScriptGlobal_Format("#{TXKS_170208_48}", ItemName) )
			return
		end

		SelectCharHeadFrame_RightClient2_Item : SetActionItem( theAction:GetID() )
		if g_posItem ~= -1 then
			LifeAbility : Lock_Packet_Item( g_posItem, 0 )
		end

		--在背包中锁住这个物品
		g_posItem	= pos
		LifeAbility : Lock_Packet_Item( g_posItem, 1 )

		-- 显示日期
		SelectCharHeadFrame_RightClient2_NeedMoney:Show()
		SelectCharHeadFrame_RightClient2_Itemtext2:Show()
		local str
		if nCanUseTime < 1 then
			str = "#{TXKJM_171127_10}"
		else
			str = ScriptGlobal_Format("#{TXKJM_171127_05}", math.floor(nCanUseTime/24) )
		end
		SelectCharHeadFrame_RightClient2_Itemtext2:SetText(str)
		

	else

		SelectCharHeadFrame_ItemClear()
	end
end

--刷新物品 续期
function SelectCharHeadFrame_ItemUpdate_XuQi(pos)
	local theAction	= EnumAction( pos, "packageitem" )
	if theAction:GetID() ~= 0 then
		local ItemId = PlayerPackage : GetItemTableIndex( pos )
		local ret, nCanUseTime, nExpiryDate = DataPool : GetHeadFrameTimeFromTable(ItemId)

		if ret < 1 then
			PushDebugMessage("#{TXKS_170208_47}")
			return
		end

		local ItemName = PlayerPackage:GetItemName(ItemId)
		if PlayerPackage : IsLock( pos ) == 1 then
			PushDebugMessage( ScriptGlobal_Format("#{TXKS_170208_48}", ItemName) )
			return
		end

		SelectCharHeadFrame_RightClient5_Item : SetActionItem( theAction:GetID() )
		if g_posItem ~= -1 then
			LifeAbility : Lock_Packet_Item( g_posItem, 0 )
		end

		--在背包中锁住这个物品
		g_posItem	= pos
		LifeAbility : Lock_Packet_Item( g_posItem, 1 )

		-- 显示日期
		SelectCharHeadFrame_RightClient5_NeedMoney:Show()
		local str = ""
		if nCanUseTime < 1 then
			-- 永久
			str = "#{TXKJM_171127_10}"
		else
			-- 显示有效期 x天
			str = ScriptGlobal_Format("#{TXKJM_171127_05}", math.floor(nCanUseTime/24) )
		end
		SelectCharHeadFrame_RightClient5_Timetext2:SetText(str)
	else
		SelectCharHeadFrame_ItemClear_XuQi()
	end
end

--清理物品 清理右侧选中的头像框部分  右键点击激活道具item
function SelectCharHeadFrame_ItemClear()
	SelectCharHeadFrame_RightClient2_Item : SetActionItem( -1 );
	LifeAbility : Lock_Packet_Item( g_posItem, 0 )
	g_posItem	= -1
	SelectCharHeadFrame_RightClient1_CharHeadFrameLimitTime:SetText("#{TXKJM_171127_01}")
	SelectCharHeadFrame_RightClient2_NeedMoney:Hide()
	SelectCharHeadFrame_RightClient2_Itemtext2:Hide()
end

--清理物品 续期
function SelectCharHeadFrame_ItemClear_XuQi()
	SelectCharHeadFrame_RightClient5_Item : SetActionItem( -1 );
	LifeAbility : Lock_Packet_Item( g_posItem, 0 )
	g_posItem	= -1
	SelectCharHeadFrame_RightClient5_Timetext2:SetText(  " " )
	SelectCharHeadFrame_RightClient5_NeedMoney:Hide()
end

function SelectCharHeadFrame_Close()
	this:Hide();
end


--hidden事件
function SelectCharHeadFrame_Cancel_Clicked()
	this:CareObject( g_clientNpcId, 0, "SelectCharHeadFrame" )
	g_clientNpcId = -1
	SelectCharHeadFrame_ItemClear()
end

--激活or续期
function SelectCharHeadFrame_OK_Clicked()
	if(g_CurSelExteriorID <= 0 )then
		PushDebugMessage("#{TXKS_170208_35}")
		return
	end
	local isHave = Exterior:LuaFnIsHaveExterior(g_ExteriorType, g_CurSelExteriorID)

	-- -- 判断当前是否正在使用女神边框
	-- if isHave == 0 then
	-- 	if Player:Player_GetTitleType() == nNvShenTitleID or Player:Player_GetTitleType() == nNvShenTitleIDEx then
	-- 		PushDebugMessage("#{TXKS_170208_44}")
	-- 		return
	-- 	end
	-- end
	if isHave == 0 then
		if g_posItem < 0 then
			PushDebugMessage("#{TXKS_170208_49}")
			return
		end
		--激活头像框图鉴
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("UnlockExteriorHeadFrame");
		Set_XSCRIPT_ScriptID(892425);
		Set_XSCRIPT_Parameter(0, g_CurSelExteriorID);
		Set_XSCRIPT_Parameter(1, g_posItem);
		Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	else
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("XuQiExteriorHeadFrame");
		Set_XSCRIPT_ScriptID(892425);
		Set_XSCRIPT_Parameter(0, g_CurSelExteriorID);
		Set_XSCRIPT_Parameter(1, g_posItem);
		Set_XSCRIPT_Parameter(2, 1);
		Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
	end
end

function SelectCharHeadFrame_Use_Clicked()
	if(g_CurSelExteriorID <= 0 )then
		PushDebugMessage("#{TXKS_170208_35}")
		return
	end
	local nId, nFrameName, nDisplayItem, nCostMoney, nGetInfo, nType, nIconFile, nAnimate = Exterior:LuaFnGetExteriorFrameStyleInfo(g_CurSelExteriorID)
	local IsHave = Exterior:LuaFnIsHaveExterior(g_ExteriorType, g_CurSelExteriorID)

	-- 女神边框进行特写
	if nId == 2 then
		if IsHave == 1 then
			if Player:Player_GetTitleType() == nNvShenTitleID or Player:Player_GetTitleType() == nNvShenTitleIDEx then --当前正在使用，点击隐藏称号
				Player:SetNullAgname();
			else	--未使用女神边框，点击顶上称号
				Player:DisplayNvShenTitle()
			end
		else
			PushDebugMessage("#{TXKS_170208_54}")
		end
		return
	end

	-- -- 判断当前是否正在使用女神边框
	-- if Player:Player_GetTitleType() == nNvShenTitleID or Player:Player_GetTitleType() == nNvShenTitleIDEx then
	-- 	PushDebugMessage("#{TXKS_170208_44}")
	-- 	return
	-- end
	-- PushDebugMessage("asdasdasdds")
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ChangeCurExteriorHeadFrameId");
		Set_XSCRIPT_ScriptID(892425);
		Set_XSCRIPT_Parameter(0,g_CurSelExteriorID);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();

end

-- --不需要删除功能了
-- function SelectCharHeadFrame_Delete_Clicked()
-- end
function SelectCharHeadFrame_ConvertToData(nTime)
	-- 计算日期
	local nYear = math.floor(nTime/1000000) + 2000
	local nMonth =  math.mod(math.floor(nTime/10000), 100)
	local nDay = math.mod(math.floor(nTime/100), 100)
	local nHour = math.mod(nTime, 100)
	str = ScriptGlobal_Format("#{TXKJM_171127_06}", nYear.."年"..nMonth.."月"..nDay.."日"..nHour.."时")
	return str
end

function SelectCharHeadFrame_ItemMouseMove(nIndex)

end

