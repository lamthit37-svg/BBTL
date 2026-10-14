--!!!reloadscript =NameBoardEx_Visual
local g_NameBoardEx_Visual_UnifiedPosition = ""

local g_TargetNameBoardExIndex			= 0		--定位的外观索引，从1开始
local g_TargetNameBoardExRealID			= 0		--定位的外观ID

local g_CurSelNameBoardExRealID			= 0		--当前选择的外观ID，从1开始

local g_CurSelNameBoardExIndex			= 0		--当前选择的外观索引

local g_NeedChangeScrollSize		= 1

local g_Distance					= 1
local g_Distance_Ori				= 3
local g_Distance_Max				= 4
local g_InitList1					= 0
local g_InitList2					= 0
local g_MaxBarNum					= 0
local g_BarList						= {}


local g_SliderChange				= 0
local g_TextChange					= 0


local g_NameBoardExState = 
{
	INVALID	= 0,	-- 无效
	EMPTY	= 1,	-- 空闲
	TIME	= 2,	-- 限时
	TIMEOUT	= 3,	-- 过期
	FOREVER	= 4,	-- 永久
}

--=========
--PreLoad==
--=========
function NameBoardEx_Visual_PreLoad()
	this:RegisterEvent("NAMEBOARDEX_OPEN")
	this:RegisterEvent("UI_COMMAND", false)
	

	this:RegisterEvent("UNIT_LEVEL",false)
	
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("EXERIOR_SAVEALL_RET", false)
	
	this:RegisterEvent("OPEN_STALL_SALE",false)
	this:RegisterEvent("PROGRESSBAR_SHOW",false)
	this:RegisterEvent("MODELID_CHANGE",false)
	this:RegisterEvent("NAMEBOARDEX_DISPLAYUPDATE",false)
	this:RegisterEvent("NAMEBOARDEX_SAVE_RET",false)
	
	
	this:RegisterEvent("XUNZHANG_DATA_UPDATE",false)
	
	this:RegisterEvent("XUNZHANG_BASE_OPEN")
	

end

--=========
--OnLoad
--=========
function NameBoardEx_Visual_OnLoad()
	
	g_NameBoardEx_Visual_UnifiedPosition = NameBoardEx_Visual_Frame:GetProperty("UnifiedPosition")

end
--=========
--OnEvent
--=========
function NameBoardEx_Visual_OnEvent(event)

	if event == "NAMEBOARDEX_OPEN" then

		if this:IsVisible() then
			if tonumber(arg0) == 0 then
				NameBoardEx_Visual_SaveWindowPosition()
				this:Hide()
			elseif tonumber(arg0) == 1 then  --enGCNameBoardExDataUpdate_AskAllData_OpenUI
		
				NameBoardEx_Visual_SetWindowPosition()
				
				NameBoardEx_Visual_CloseAllExteriorWindow()
				this:Show()
				NameBoardEx_Visual_InitAndShow(0)
				NameBoardEx_Visual_FindDefaultAndClick()
			end
		end
		
		if tonumber(arg0) == 3 then  --enGCNameBoardExDataUpdate_AskAllData_OpenUI
		
			NameBoardEx_Visual_SetWindowPosition()
			
			NameBoardEx_Visual_CloseAllExteriorWindow()
			this:Show()
			NameBoardEx_Visual_InitAndShow(0)
			NameBoardEx_Visual_FindDefaultAndClick()
		end	
		return
	end
	
	if event == "UI_COMMAND" and tonumber(arg0) == 99911301 then
		NameBoardEx_Visual_InitAndShow(0)
		NameBoardEx_Visual_FindDefaultAndClick()
	end
	

	if ( event == "OPEN_STALL_SALE" ) -- 开始摆摊，还原试穿
		or ( event == "PROGRESSBAR_SHOW" )		-- 读进度条中，还原试穿
		or ( event == "MODELID_CHANGE" ) -- 变身 关闭界面
		then
		NameBoardEx_Visual_CloseClick()
		return
	end

	if event == "NAMEBOARDEX_DISPLAYUPDATE" then
		-- 刷新模型
		XunzhangSysScript:LuaFnUpdateNameBoardExPlayerData()
		NameBoardEx_Visual_UpdateRightItemList()
		--NameBoardEx_Visual_ItemClicked(g_CurSelNameBoardExIndex, 0)
			NameBoardEx_Visual_FindDefaultAndClick()
		--PushDebugMessage("debuggg  NAMEBOARDEX_DISPLAYUPDATE "..g_CurSelNameBoardExIndex)	
		return
	end
	
	if event == "NAMEBOARDEX_SAVE_RET" then
		XunzhangSysScript:SetCurrentNameBoardExSetInfo("RESET",0)
		XunzhangSysScript:LuaFnInitCurrentNameBoardExSet()
		NameBoardEx_Visual_ResetItemSelected()
		NameBoardEx_Visual_InitAndShow(0)	
	--	NameBoardEx_Visual_InitAndShow()
		--NameBoardEx_Visual_ItemClicked(g_CurSelNameBoardExIndex, 0)
	end
	
	if event == "XUNZHANG_BASE_OPEN" then
		
		NameBoardEx_Visual_SetWindowPosition()
		this:Show()
		NameBoardEx_Visual_TuJian_InitAndShow()

		return
	end
	
	

	if event == "UNIT_LEVEL" and arg0 == "player" then
	
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		NameBoardEx_Visual_Frame:SetProperty("UnifiedPosition", g_NameBoardEx_Visual_UnifiedPosition)
	end
	
	if event == "UPDATE_REDPOINT_IN_UI" and this:IsVisible() then
		--NameBoardEx_Visual_UpdateLeftRedPoint()
	end

end

function NameBoardEx_Visual_FindDefaultAndClick()
	
	local curUseRealId = XunzhangSysScript:GetNameBoardExUseID()
	local result = 1
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local findId = XunzhangSysScript:GetNameBoardExListID(i - 1)   --index 1开始  接口索引 0开始
			if findId == curUseRealId then
				result = i
			end
		end
	end
	if result >= g_MaxBarNum then
		result = 1
	end
	
	NameBoardEx_Visual_ItemClicked(result, 0)
--	PushDebugMessage("NameBoardEx_Visual_FindDefaultAndClick "..result)	
end

function NameBoardEx_Visual_OpenTujian()
	
	--PushDebugMessage("debuggg  NameBoardEx_Visual_OpenTujian")	
	XunzhangSysScript:LuaFnAskXunzhangDBBaseData(DataPool : GetMySelfServerID())
	--NameBoardEx_Visual_CloseClick()
	NameBoardEx_Visual_CleanUp()
	XunzhangSysScript:SetCurrentNameBoardExSetInfo("RESET",0)
	XunzhangSysScript:LuaFnUpdateNameBoardExPlayerData()
end

function NameBoardEx_Visual_ShowNameBoardEx()
	local cur = SystemSetup:Lua_GetShowXunzhangNameboardEx()
	
	if cur == 1 then
		SystemSetup:Lua_SetShowXunzhangNameboardEx(1)
	else
		SystemSetup:Lua_SetShowXunzhangNameboardEx(0)
	end
	
	--PushDebugMessage("debuggg  NameBoardEx_Visual_ShowNameBoardEx cur = "..1-cur)	
end

function NameBoardEx_Visual_InitList()
	
	if g_InitList1 == 0 then		
		
		g_MaxBarNum = XunzhangSysScript:GetNameBoardExMaxCount()
		
		for i = 1, g_MaxBarNum do
			local bar = NameBoardEx_Visual_SuperList:AddChild("NameBoardEx_Visual_SuperListItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			g_BarList[i] = bar	
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemAction"):SetEvent("MouseLButtonDown", string.format("NameBoardEx_Visual_ItemClicked(%d,0)", i))
			--bar:GetSubItem("NameBoardEx_Visual_SuperListItemAction"):SetEvent("MouseRButtonDown", string.format("NameBoardEx_Visual_TakeOff(%d)", i))
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemAction"):SetEvent("MouseMove", string.format("NameBoardEx_Visual_ItemMouseMove(%d)", i))
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemAction"):SetProperty("Empty", "False")
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemAction"):SetProperty("UseDefaultTooltip", "True")
		end
		g_InitList1 = 1
	end
end

function NameBoardEx_Visual_InitAndShow(notReset)
	
		
	NameBoardEx_Visual_TuJian_Function_Frame:Hide()
	NameBoardEx_Visual_Function_Frame:Show()
		
	g_Distance = g_Distance_Ori

	g_NeedChangeScrollSize = 1
	
	NameBoardEx_Visual_OK:SetText("#{XZXT_240517_24}")  --装备
	NameBoardEx_Visual_OK:SetToolTip("#{XZXT_240517_25}")
	
	NameBoardEx_Visual_InitList()
	
	NameBoardEx_Visual_CleanUp()
	if notReset ~= 1 then
		XunzhangSysScript:SetCurrentNameBoardExSetInfo("RESET",0)
	end
	XunzhangSysScript:LuaFnInitCurrentNameBoardExSet()
	XunzhangSysScript:LuaFnUpdateNameBoardExPlayerData()
	
	g_CurSelNameBoardExRealID = 0
	g_CurSelNameBoardExIndex = 0
	
	g_SliderChange = 0
	g_TextChange = 0

	local cacheNameBoardExID = XunzhangSysScript:GetCurrentNameBoardExSetInfo("NAMEBOARDEX")
	if cacheNameBoardExID ~= nil and cacheNameBoardExID > 0 then
		g_TargetNameBoardExRealID = cacheNameBoardExID
		g_CurSelNameBoardExRealID = cacheNameBoardExID
	end
	
	--PushDebugMessage("debuggg  g_CurSelNameBoardExRealID = "..g_CurSelNameBoardExRealID)	
	
	--刷新右侧item列表
	NameBoardEx_Visual_UpdateRightItemList()

	--刷新模型
	NameBoardEx_Visual_UpdateObj()
	
	--移除当前点击位置的红点
	NameBoardEx_Visual_RemoveItemRedPoint(g_CurSelNameBoardExRealID)
	
	NameBoardEx_Visual_UpdateLeftRedPoint()

	NameBoardEx_Visual_TuJian_Tip:Hide()
	
	NameBoardEx_Visual_LeftClient_Lace2_GetWay:SetText("")
	NameBoardEx_Visual_LeftClient_Lace1_Animate:Hide()
	local MyName = Player:GetName()
	local nameColour = "#c3c00ff#effffff"

	NameBoardEx_Visual_LeftClient_Lace1_PlayerName:SetText(nameColour..MyName)
	
	NameBoardEx_Visual_TuJian:SetProperty("Selected", "False");
	NameBoardEx_Visual_WaiGuan:SetProperty("Selected", "True");

end

--列表
function NameBoardEx_Visual_UpdateRightItemList()
	
	--PushDebugMessage("debuggg  NameBoardEx_Visual_UpdateRightItemList")	
	
	NameBoardEx_Visual_UpdateLeftRedPoint()
	
	XunzhangSysScript:InitNameBoardExListInfo()
	local count = XunzhangSysScript:GetNameBoardExMaxCount()
	if count > g_MaxBarNum then
		count = g_MaxBarNum
	end
	
	for i = 1, count do	
		NameBoardEx_Visual_SetItem(i, count)
	end
	
	if g_NeedChangeScrollSize == 1 then
		NameBoardEx_Visual_SuperList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
	if g_TargetNameBoardExIndex ~= 0 then
		NameBoardEx_Visual_SuperList:SetScrollPosition4Index(g_TargetNameBoardExIndex - 1)
		g_TargetNameBoardExRealID = 0
		g_TargetNameBoardExIndex = 0
	else
		NameBoardEx_Visual_SuperList:SetScrollPosition4Index(0)
	end

end

function NameBoardEx_Visual_SetItem(index, max_count)  --index 1开头

	if g_BarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_BarList[index]:Hide()
		return
	end
	
	local bar = g_BarList[index]
	bar:Show()
	

	local curUseRealId = XunzhangSysScript:GetNameBoardExUseID()

	local nNameBoardExRealID = XunzhangSysScript:GetNameBoardExListID(index - 1)   --index 1开始  接口索引 0开始
	
	
	local strIcon 	 = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "Icon")
	local strName 	 = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "Name")
	local strImage	 = GetIconFullName(strIcon)
	local strDesc 	 = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "Desc")
	local strSource	 = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "Source")
	local strAnimate = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "Animate")

	 
	local ctrlAction = bar:GetSubItem("NameBoardEx_Visual_SuperListItemAction")
	if ctrlAction ~= nil then
	
		ctrlAction:SetProperty("NormalImage", strImage)
		ctrlAction:SetProperty("HoverImage", strImage)
		
		local strToolTip = XunzhangSysScript:GetNameBoardExToolTip(nNameBoardExRealID)
		ctrlAction:SetToolTip(strToolTip)

		
		--当前选择的id 和本次点选的id 相同
		if g_CurSelNameBoardExRealID == nNameBoardExRealID then
			ctrlAction:SetPushed(1)
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionTry"):Show()
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionEqu"):Hide()

			--当前选择的序列id
			g_CurSelNameBoardExIndex = index
		else
			ctrlAction:SetPushed(0)
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionTry"):Hide()
		end			

		--当前使用的id 和本次点选的id 相同
		if curUseRealId == nNameBoardExRealID then
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionTry"):Hide()
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionEqu"):Show()
		else
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionEqu"):Hide()
		end

		if g_TargetNameBoardExRealID == nNameBoardExRealID then
			g_TargetNameBoardExIndex = index
		end

		--解锁&限时标志
		local nIdx, nX, nY, nZ, nState = XunzhangSysScript:GetPlayerNameBoardExInfo(nNameBoardExRealID, 0)
		if nIdx > 0 and nState == g_NameBoardExState.TIME then
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionTime"):Show()
		else
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionTime"):Hide()
		end	

		if nIdx > 0 and (nState == g_NameBoardExState.TIME or nState == g_NameBoardExState.FOREVER) then
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionLock"):Hide()
		else
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionLock"):Show()
		end
		
		--红点
		local nTip = XunzhangSysScript:GetPlayerNameBoardExTip(nNameBoardExRealID)
		if nTip == 1 then
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionTip"):Show()
		else
			bar:GetSubItem("NameBoardEx_Visual_SuperListItemActionTip"):Hide()
		end		

	end

	
end
--模型
function NameBoardEx_Visual_UpdateObj()
	
	--local cacheNameBoardExID, cacheNameBoardExX, cacheNameBoardExY, cacheNameBoardExZ = Exterior:LuaFnGetCurrentExteriorSetInfo("NameBoardEx")
	--PushDebugMessage("debuggg  NameBoardEx_Visual_UpdateObj 本次刷新的id= "..cacheNameBoardExID)	

	XunzhangSysScript:LuaFnUpdateNameBoardExPlayerData()
		
end

function NameBoardEx_Visual_TakeOff(nIndex)
	
	local useID = XunzhangSysScript:GetNameBoardExUseID()
	local nNameBoardExRealID = XunzhangSysScript:GetNameBoardExListID(nIndex - 1)
		
	--点击的按钮对应真实id和上一次点击的 不同  预览新的
	if useID == nNameBoardExRealID and useID > 0 then
		XunzhangSysScript:TakeOffNameBoardEx()		
		XunzhangSysScript:SetCurrentNameBoardExSetInfo("NAMEBOARDEX", 0)
		XunzhangSysScript:LuaFnRestoreNameBoardExFittingData()
		XunzhangSysScript:LuaFnUpdateNameBoardExPlayerData()
		g_BarList[nIndex]:GetSubItem("NameBoardEx_Visual_SuperListItemActionEqu"):Hide()
	end

end


function NameBoardEx_Visual_ItemClicked(nIndex, spec)
	
	local curUseID = XunzhangSysScript:GetNameBoardExUseID()
	
	local nNameBoardExRealID = XunzhangSysScript:GetNameBoardExListID(nIndex - 1)
	--PushDebugMessage("debuggg NameBoardEx_Visual_ItemClicked"..nNameBoardExRealID)				
	--点击的按钮对应真实id和上一次点击的 不同  预览新的
	if g_CurSelNameBoardExRealID ~= nNameBoardExRealID or spec == 1 then
		
		--PushDebugMessage("debuggg g_CurSelNameBoardExRealID ~= nNameBoardExRealID  试穿预览")	
		g_CurSelNameBoardExRealID = nNameBoardExRealID
		g_CurSelNameBoardExIndex = nIndex
		
		XunzhangSysScript:SetCurrentNameBoardExSetInfo("NAMEBOARDEX", g_CurSelNameBoardExRealID)
		--PushDebugMessage("debuggg 试穿预览 LuaFnSetCurrentExteriorSetInfo 要试穿的id= "..g_CurSelNameBoardExRealID)			

		NameBoardEx_Visual_SetItemSelected(nIndex)
		
		NameBoardEx_Visual_UpdateObj()

		NameBoardEx_Visual_RemoveItemRedPoint(g_CurSelNameBoardExRealID)
		NameBoardEx_Visual_UpdateLeftRedPoint()
		
		local strSource	= XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "Source")
		NameBoardEx_Visual_LeftClient_Lace2_GetWay:SetText(strSource)
		local strAnimate = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "Animate")
		local strTextColor = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "TextColor")
		local AnimateX = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "AnimateX")
		local AnimateY = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "AnimateY")
		local AnimateW = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "AnimateW")
		local AnimateH = XunzhangSysScript:GetNameBoardExInfo(nNameBoardExRealID, "AnimateH")
		local colorName = strTextColor..Player:GetName()
		NameBoardEx_Visual_LeftClient_Lace1_PlayerName:SetText(colorName)
		
		NameBoardEx_Visual_LeftClient_Lace1_Animate:SetProperty("AbsoluteSize", "w:"..AnimateW.." ".."h:"..AnimateH)
		NameBoardEx_Visual_LeftClient_Lace1_Animate:SetProperty("Animate", strAnimate)
		
		local nameLength = tonumber(string.len(Player:GetName()))
		local realLength = nameLength * 19 / 2   --一个汉字19像素
	
		local bgPosX = tonumber(NameBoardEx_Visual_LeftClient_Lace1:GetProperty("AbsoluteXPosition"))
		local bgPosY = tonumber(NameBoardEx_Visual_LeftClient_Lace1:GetProperty("AbsoluteYPosition"))
		local bgSizeH = tonumber(NameBoardEx_Visual_LeftClient_Lace1:GetProperty("AbsoluteHeight"))
		local bgSizeW = tonumber(NameBoardEx_Visual_LeftClient_Lace1:GetProperty("AbsoluteWidth"))

		local newPosX = math.floor(tonumber(bgPosX + bgSizeW / 2 - realLength / 2 - AnimateX))
		local newPosY = math.floor(tonumber(bgPosY + bgSizeH / 2 - AnimateH / 2)) 

		NameBoardEx_Visual_LeftClient_Lace1_Animate:SetProperty("AbsoluteXPosition", newPosX);	
		NameBoardEx_Visual_LeftClient_Lace1_Animate:SetProperty("AbsoluteYPosition", newPosY);

		NameBoardEx_Visual_LeftClient_Lace1_Animate:Show()
		
		if curUseID == g_CurSelNameBoardExRealID then
			NameBoardEx_Visual_OK:SetText("#{XZXT_240517_28}")  --卸下
			NameBoardEx_Visual_OK:SetToolTip("#{XZXT_240517_29}")
		else
			NameBoardEx_Visual_OK:SetText("#{XZXT_240517_24}")  --装备
			NameBoardEx_Visual_OK:SetToolTip("#{XZXT_240517_25}")
		end
	
	--点击的按钮对应真实id和上一次点击的 相同 撤销预览
	else
		--PushDebugMessage("debuggg g_CurSelNameBoardExRealID == nNameBoardExRealID  撤销预览")			
		local defNameBoardExID = XunzhangSysScript:GetNameBoardExUseID()

		XunzhangSysScript:SetCurrentNameBoardExSetInfo("NAMEBOARDEX", defNameBoardExID)
		--PushDebugMessage("debuggg 撤销预览 LuaFnSetCurrentExteriorSetInfo 身上穿的id= "..defNameBoardExID)
		
		NameBoardEx_Visual_InitAndShow(0)	
		
		
	end	


end

function NameBoardEx_Visual_ItemMouseMove(nIndex)

end

function NameBoardEx_Visual_SetItemSelected(nIndex)

		

	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemAction")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
					g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemActionTry"):Show()
					if XunzhangSysScript:GetNameBoardExUseID() == g_CurSelNameBoardExRealID then
						g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemActionTry"):Hide()
					end
				else
					ctrlAction:SetPushed(0)	
					g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemActionTry"):Hide()
				end
			end
		end
	end
	
end

function NameBoardEx_Visual_ResetItemSelected()

	
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemAction")
			if ctrlAction ~= nil then
				ctrlAction:SetPushed(0)	
				g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemActionTry"):Hide()
				--g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemActionEqu"):Hide()
				if XunzhangSysScript:GetNameBoardExUseID() == g_CurSelNameBoardExRealID and g_CurSelNameBoardExRealID ~= 0 then
					g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemActionEqu"):Show()
				end
			end
		end
	end
	
	g_CurSelNameBoardExIndex = 0
	g_TargetNameBoardExRealID = 0
	g_CurSelNameBoardExRealID = 0
	
end

	
function NameBoardEx_Visual_ShowModel()
	
end


function NameBoardEx_Visual_SaveCurrent()
	
	local curUseID = XunzhangSysScript:GetNameBoardExUseID()
	if curUseID == g_CurSelNameBoardExRealID then
		
		NameBoardEx_Visual_TakeOff(g_CurSelNameBoardExIndex)
		
	else
	
		if XunzhangSysScript:LuaFnIsHaveNameBoardExChange() ~= 1 then
			PushDebugMessage("#{WGTJ_201222_72}")
			return
		end
		--XunzhangSysScript:LuaFnRestoreNameBoardExFittingData()
		XunzhangSysScript:LuaFnSaveNameBoardExChange()
		--XunzhangSysScript:LuaFnUpdateNameBoardExPlayerData()
	end	
	
	
	

end


function NameBoardEx_Visual_Undo()
	if XunzhangSysScript:LuaFnIsHaveNameBoardExChange() == 0 then
		PushDebugMessage("#{WGTJ_201222_76}")
		return
	end	
	
	XunzhangSysScript:SetCurrentNameBoardExSetInfo("RESET",0)
	XunzhangSysScript:LuaFnInitCurrentNameBoardExSet()
	NameBoardEx_Visual_InitAndShow(0)
	PushDebugMessage("#{WGTJ_201222_98}")
end

function NameBoardEx_Visual_CloseClick()
	--PushDebugMessage("debuggg NameBoardEx_Visual_CloseClick")
		
	XunzhangSysScript:SetCurrentNameBoardExSetInfo("RESET",0)
	XunzhangSysScript:LuaFnUpdateNameBoardExPlayerData()
	NameBoardEx_Visual_SaveWindowPosition()
	this:Hide()
end

function NameBoardEx_Visual_OnHidden()
	XunzhangSysScript:SetCurrentNameBoardExSetInfo("RESET",0)
	NameBoardEx_Visual_CleanUp()

end

function NameBoardEx_Visual_CleanUp()
	
	
	XunzhangSysScript:LuaFnRestoreNameBoardExFittingData()
	--XunzhangSysScript:GetCurrentNameBoardExSetInfo("RESET")
	XunzhangSysScript:LuaFnInitCurrentNameBoardExSet()
	XunzhangSysScript:LuaFnUpdateNameBoardExPlayerData()	
	
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	
	NameBoardEx_Visual_CleanUp_LeftButton()
	
	NameBoardEx_Visual_ResetItemSelected()
	
	SetDefaultMouse();
end

function NameBoardEx_Visual_CleanUp_LeftButton()

end

function NameBoardEx_Visual_CloseAllExteriorWindow()
--	CloseWindow("SelfEquip", true)
	CloseWindow("NewExterior_DressBox", true)
	CloseWindow("NewExterior_Ride", true)
	CloseWindow("NewExterior_Weapon", true)
	CloseWindow("NewExterior_PetPossJian", true)
	CloseWindow("NewExterior_Facestyle", true)
	CloseWindow("NewExterior_HairStyle", true)
	CloseWindow("NewExterior_PlayerFrame", true)
	CloseWindow("NewExterior_Widget", true)
	CloseWindow("NewExterior_Headdress", true)
	CloseWindow("NewExterior_DressStyle", true)
	CloseWindow("NewExterior_GemEffect", true)
	CloseWindow("NewExterior_PlanSetting", true)
	CloseWindow("NewExterior_TuJing", true)
end

function NameBoardEx_Visual_SaveWindowPosition()
	
	Variable:SetVariable("NameBoardExUnionPos", NameBoardEx_Visual_Frame:GetProperty("UnifiedPosition"), 1)
	
end

function NameBoardEx_Visual_SetWindowPosition()
	
	local nNameBoardExUnionPos = Variable:GetVariable("NameBoardExUnionPos")
	if nNameBoardExUnionPos ~= nil then
		NameBoardEx_Visual_Frame:SetProperty("UnifiedPosition", nNameBoardExUnionPos)
	end

end

function NameBoardEx_Visual_RemoveItemRedPoint(nNameBoardExID)
	
	local nTip = XunzhangSysScript:GetPlayerNameBoardExTip(nNameBoardExID)
	if nTip == 1 then
		XunzhangSysScript:RemoveNameBoardExTip(nNameBoardExID)
		for i = 1, g_MaxBarNum do
			if g_BarList[i] then
				local nID = XunzhangSysScript:GetNameBoardExListID(i - 1)
				if XunzhangSysScript:RemoveNameBoardExTip(nID) == 1 then
					g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemActionTip"):Show()
				else
					g_BarList[i]:GetSubItem("NameBoardEx_Visual_SuperListItemActionTip"):Hide()
				end
			end
		end
	
	end
end

function NameBoardEx_Visual_UpdateLeftRedPoint()

	if XunzhangSysScript:IsHaveNameBoardExShowTip() == 1 then
		NameBoardEx_Visual_WaiGuan_Tip:Show()
	else
		NameBoardEx_Visual_WaiGuan_Tip:Hide()
	end

end

function NameBoardEx_Visual_Help_Clicked()

	 PushEvent("CCSHOP_HELP", 213)
end


function NameBoardEx_Visual_TuJian_InitList()
	
	if g_InitList2 == 0 then		
		
		g_MaxBarNum = XunzhangSysScript:LuaFnGetXunzhangBaseMaxCount()
		
		for i = 1, g_MaxBarNum do
			local bar = NameBoardEx_Visual_TuJian_Frame_RightClient_ItemList:AddChild("NameBoardEx_Visual_TuJian_Frame_RightClient_ItemFrame")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			g_BarList[i] = bar	
			bar:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_Item"):SetEvent("MouseLButtonDown", string.format("NameBoardEx_Visual_TuJian_ItemClicked(%d)", i))
			bar:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_Item"):SetEvent("MouseMove", string.format("NameBoardEx_Visual_TuJian_ItemMouseMove(%d)", i))
			bar:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_Item"):SetProperty("Empty", "False")
			bar:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_Item"):SetProperty("UseDefaultTooltip", "True")
		end
		g_InitList2 = 1
	end
	
	--NameBoardEx_Visual_TuJian_Frame_RightClient_UpPage:Disable()
	--NameBoardEx_Visual_TuJian_Frame_RightClient_DownPage:Disable()
end

function NameBoardEx_Visual_TuJian_InitAndShow()
	
	NameBoardEx_Visual_TuJian_Function_Frame:Show()
	NameBoardEx_Visual_Function_Frame:Hide()
	

	g_NeedChangeScrollSize = 1

	NameBoardEx_Visual_TuJian_InitList()
	
	NameBoardEx_Visual_TuJian_CleanUp()

	--刷新右侧item列表
	NameBoardEx_Visual_TuJian_UpdateRightItemList()
	
	NameBoardEx_Visual_TuJian_UpdateLeftRedPoint()
	
	
	NameBoardEx_Visual_TuJian:SetProperty("Selected", "True");
	NameBoardEx_Visual_WaiGuan:SetProperty("Selected", "False");
	
end

--列表
function NameBoardEx_Visual_TuJian_UpdateRightItemList()
	
	--PushDebugMessage("debuggg  NameBoardEx_Visual_TuJian_UpdateRightItemList")	
	
	NameBoardEx_Visual_TuJian_UpdateLeftRedPoint()
	
	XunzhangSysScript:LuaFnInitXunzhangDataList()
	local count = XunzhangSysScript:LuaFnGetXunzhangBaseMaxCount()
	if count > g_MaxBarNum then
		count = g_MaxBarNum
	end
	
	for i = 1, count do	
		NameBoardEx_Visual_TuJian_SetItem(i, count)
	end
	
	if g_NeedChangeScrollSize == 1 then
		NameBoardEx_Visual_TuJian_Frame_RightClient_ItemList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
end

function NameBoardEx_Visual_TuJian_SetItem(index, max_count)  --index 1开头

	if g_BarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_BarList[index]:Hide()
		return
	end
	
	local bar = g_BarList[index]
	bar:Show()

	local nXunzhangBaseRealID = XunzhangSysScript:LuaFnGetXunzhangRealIdByListId(index - 1)   --index 1开始  接口索引 0开始

	local strIconN 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "IconNormal")
	local strName 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "Name")
	--local strImageN	= GetIconFullName(strIconN)
	local strIconH 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "IconHover")
	--local strImageH	= GetIconFullName(strIconH)
	local strIconP 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "IconPushed")
	--local strImageP	= GetIconFullName(strIconP)
	local strIconGN	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "IconGreyNormal")
	local strIconGH	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "IconGreyHover")
	local strIconGP	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "IconGreyPushed")
	--local strImageG	= GetIconFullName(strIconG)
	local strSource 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "Source")
	local nActivateType = XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "ActivateType")
	local nCondition1	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "Condition1")
	local nCondition2	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "Condition2")
	local nFirstActDate	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "FirstActDate")
	local nCurAccTimes	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "CurAccTimes")
	local nIsActivate	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "IsActivate")
	local strRecordDict1	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId(nXunzhangBaseRealID, "RecordDict1")

	local ctrlAction = bar:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_Item")
	if ctrlAction ~= nil then
	--PushDebugMessage("debuggg  NameBoardEx_Visual_TuJian_SetItem "..nXunzhangBaseRealID)	
		ctrlAction:SetProperty("NormalImage", strIconN)
		ctrlAction:SetProperty("HoverImage", strIconH)
		ctrlAction:SetProperty("PushedImage", strIconP)
	--	ctrlAction:SetProperty("DisabledImage", strIconG)
		
		--local strToolTip = XunzhangSysScript:GetXunzhangBaseToolTip(nXunzhangBaseRealID)
		strToolTip = ScriptGlobal_Format("#{XZXT_240517_51}",strName)
		ctrlAction:SetToolTip(strToolTip)

		local textColour = "#cfff263"

		if nIsActivate ~= 1 then
			
			textColour = "#c959595"
			ctrlAction:SetProperty("NormalImage", strIconGN)
			ctrlAction:SetProperty("HoverImage", strIconGH)
			ctrlAction:SetProperty("PushedImage", strIconGP)			
			
			--bar:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_ItemLock"):Hide()
		--else
			--bar:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_ItemLock"):SetProperty("Image", strIconG)
			--bar:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_ItemLock"):Show()
		end
		
		bar:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_ItemText"):SetText(textColour..strName)
			

	end

	
end


function NameBoardEx_Visual_TuJian_ItemClicked(nIndex)
	
	local nRealID = XunzhangSysScript:LuaFnGetXunzhangRealIdByListId(nIndex - 1)   --index 1开始  接口索引 0开始
	--PushDebugMessage("debuggg  NameBoardEx_Visual_TuJian_ItemClicked "..nIndex.."  "..nRealID)	
	if nRealID > 0 then
		--PushEvent( "XUNZHANG_RECORD_OPEN", nRealID )
		XunzhangSysScript:LuaFnAskXunzhangDBDataByRealId(nRealID, DataPool:GetMySelfServerID())
	end
	
end

function NameBoardEx_Visual_TuJian_ItemMouseMove(nIndex)

end

function NameBoardEx_Visual_TuJian_SetItemSelected(nIndex)

	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_Item")
			if ctrlAction ~= nil then
				if i == nIndex then
					--ctrlAction:SetPushed(1)			
				else
					--ctrlAction:SetPushed(0)	
				end
			end
		end
	end
	
end
	
function NameBoardEx_Visual_TuJian_WaiguanClick()
	--PushDebugMessage("NameBoardEx_Visual_TuJian_WaiguanClick")
	--PushEvent("SHOULDERDECO_OPEN", 1)
	XunzhangSysScript:AskNameBoardExInfo()
	NameBoardEx_Visual_TuJian_CleanUp()
	--NameBoardEx_Visual_TuJian_CloseClick()
end

function NameBoardEx_Visual_TuJian_OnHidden()
	NameBoardEx_Visual_TuJian_CleanUp()
end

function NameBoardEx_Visual_TuJian_CleanUp()
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("NameBoardEx_Visual_TuJian_Frame_RightClient_ItemListItemAction")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	
	SetDefaultMouse();
end


function NameBoardEx_Visual_TuJian_UpdateLeftRedPoint()

--	NameBoardEx_Visual_TuJian_HandBook_Tip:Hide()
--	NameBoardEx_Visual_TuJian_WaiGuan_Tip:Hide()
	NameBoardEx_Visual_TuJian_Competition_Tip:Hide()

end



--!!!reloadscript =NameBoardEx_Visual