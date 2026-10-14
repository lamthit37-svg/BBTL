--!!!reloadscript =OtherXunzhang_TuJian
local g_OtherXunzhang_TuJian_UnifiedPosition = ""

local g_NeedChangeScrollSize		= 1

local g_InitList					= 0

local g_MaxBarNum					= 0
local g_BarList						= {}

local g_curPage  = 1
local g_perPageMaxNum = 15
local g_objCared = -1;

--=========
--PreLoad==
--=========
function OtherXunzhang_TuJian_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", false)
	
	this:RegisterEvent("UNIT_LEVEL",false)
	
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("XUNZHANG_DATA_UPDATE_OTHER",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)	
	
	this:RegisterEvent("XUNZHANG_BASE_OPEN_OTHER")

end

--=========
--OnLoad
--=========
function OtherXunzhang_TuJian_OnLoad()
	
	g_OtherXunzhang_TuJian_UnifiedPosition = OtherXunzhang_TuJian_Frame:GetProperty("UnifiedPosition")

end
--=========
--OnEvent
--=========
function OtherXunzhang_TuJian_OnEvent(event)

	if event == "XUNZHANG_BASE_OPEN_OTHER" then
		
		
		if this:IsVisible() then
			if tonumber(arg0) == 0 then
				OtherXunzhang_TuJian_SaveWindowPosition()
				this:Hide()
			end
		else
		
			OtherXunzhang_TuJian_SetWindowPosition()
			

			this:Show()
			OtherXunzhang_TuJian_InitAndShow()
			
			g_objCared = CachedTarget:GetData("NPCID", 1)
			if (type(g_objCared) ~="number") then
				----PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
				return
			end

			-- 开始关心OBJ
			OtherXunzhang_TuJian_BeginCareObject(g_objCared);
	
			return
		end
	end

	if (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if( arg1=="destroy") then
			OtherXunzhang_TuJian_CloseClick();
			return;
		end
	end

	if event == "UNIT_LEVEL" and arg0 == "player" then
	
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		OtherXunzhang_TuJian_Frame:SetProperty("UnifiedPosition", g_OtherXunzhang_TuJian_UnifiedPosition)
	end


end

function OtherXunzhang_TuJian_InitList()
	
	if g_InitList == 0 then		
		
		g_MaxBarNum = XunzhangSysScript:LuaFnGetXunzhangBaseMaxCount_Other()
		
		for i = 1, g_MaxBarNum do
			local bar = OtherXunzhang_TuJian_Frame_RightClient_ItemList:AddChild("OtherXunzhang_TuJian_Frame_RightClient_ItemFrame")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			g_BarList[i] = bar	
			bar:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_Item"):SetEvent("MouseLButtonDown", string.format("OtherXunzhang_TuJian_ItemClicked(%d)", i))
			bar:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_Item"):SetEvent("MouseMove", string.format("OtherXunzhang_TuJian_ItemMouseMove(%d)", i))
			bar:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_Item"):SetProperty("Empty", "False")
			bar:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_Item"):SetProperty("UseDefaultTooltip", "True")
		end
		g_InitList = 1
	end
	
	--OtherXunzhang_TuJian_Frame_RightClient_UpPage:Disable()
	--OtherXunzhang_TuJian_Frame_RightClient_DownPage:Disable()
end

function OtherXunzhang_TuJian_InitAndShow()

	g_NeedChangeScrollSize = 1

	OtherXunzhang_TuJian_InitList()
	
	OtherXunzhang_TuJian_CleanUp()

	--刷新右侧item列表
	OtherXunzhang_TuJian_UpdateRightItemList()
end

--列表
function OtherXunzhang_TuJian_UpdateRightItemList()
	
	--PushDebugMessage("debuggg  OtherXunzhang_TuJian_UpdateRightItemList")	
	
	XunzhangSysScript:LuaFnInitXunzhangDataList_Other()
	local count = XunzhangSysScript:LuaFnGetXunzhangBaseMaxCount_Other()
	if count > g_MaxBarNum then
		count = g_MaxBarNum
	end
	
	for i = 1, count do	
		OtherXunzhang_TuJian_SetItem(i, count)
	end
	
	if g_NeedChangeScrollSize == 1 then
		OtherXunzhang_TuJian_Frame_RightClient_ItemList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
end

function OtherXunzhang_TuJian_SetItem(index, max_count)  --index 1开头

	if g_BarList[index] == nil then
		return
	end
	
	if index > max_count then
		g_BarList[index]:Hide()
		return
	end
	
	local bar = g_BarList[index]
	bar:Show()

	local nXunzhangBaseRealID = XunzhangSysScript:LuaFnGetXunzhangRealIdByListId_Other(index - 1)   --index 1开始  接口索引 0开始

	local strIconN 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "IconNormal")
	local strName 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "Name")
	--local strImageN	= GetIconFullName(strIconN)
	local strIconH 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "IconHover")
	--local strImageH	= GetIconFullName(strIconH)
	local strIconP 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "IconPushed")
	--local strImageP	= GetIconFullName(strIconP)
	local strIconGN	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "IconGreyNormal")
	local strIconGH	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "IconGreyHover")
	local strIconGP	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "IconGreyPushed")
	--local strImageG	= GetIconFullName(strIconG)
	local strSource 	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "Source")
	local nActivateType = XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "ActivateType")
	local nCondition1	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "Condition1")
	local nCondition2	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "Condition2")
	local nFirstActDate	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "FirstActDate")
	local nCurAccTimes	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "CurAccTimes")
	local nIsActivate	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "IsActivate")
	local strRecordDict1	= XunzhangSysScript:LuaFnGetXunzhangAllDataByRealId_Other(nXunzhangBaseRealID, "RecordDict1")

	local ctrlAction = bar:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_Item")
	if ctrlAction ~= nil then
	--PushDebugMessage("debuggg  OtherXunzhang_TuJian_SetItem "..nXunzhangBaseRealID)	
		ctrlAction:SetProperty("NormalImage", strIconN)
		ctrlAction:SetProperty("HoverImage", strIconH)
		ctrlAction:SetProperty("PushedImage", strIconP)
		--ctrlAction:SetProperty("DisabledImage", strIconG)
		
		--local strToolTip = XunzhangSysScript:GetXunzhangBaseToolTip(nXunzhangBaseRealID)
		strToolTip = ScriptGlobal_Format("#{XZXT_240517_51}",strName)
		ctrlAction:SetToolTip(strToolTip)

		if nIsActivate ~= 1 then
			
			ctrlAction:SetProperty("NormalImage", strIconGN)
			ctrlAction:SetProperty("HoverImage", strIconGH)
			ctrlAction:SetProperty("PushedImage", strIconGP)
		--	bar:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_ItemLock"):Hide()
		--else
		--	bar:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_ItemLock"):Show()
		end
		
		bar:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_ItemText"):SetText(strName)
			

	end

	
end


function OtherXunzhang_TuJian_ItemClicked(nIndex)
	
	local nRealID = XunzhangSysScript:LuaFnGetXunzhangRealIdByListId_Other(nIndex - 1)   --index 1开始  接口索引 0开始
	if nRealID > 0 then
		--PushEvent( "XUNZHANG_RECORD_OPEN", nRealID )
		XunzhangSysScript:LuaFnAskXunzhangDBDataByRealId_Other(nRealID)
	end
	
end

function OtherXunzhang_TuJian_ItemMouseMove(nIndex)

end

function OtherXunzhang_TuJian_SetItemSelected(nIndex)

	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_Item")
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


--=========================================================
--开始关心OBJ
--在开始关心之前需要先确定这个界面是不是已经有“关心”的OBJ，
--如果有的话，先取消已经有的“关心”
--=========================================================
function OtherXunzhang_TuJian_BeginCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		g_objCared = objCaredId;
		this:CareObject(g_objCared, 1, "OtherXunzhang_TuJian");
	else
		return;
	end

end

--=========================================================
--停止对某OBJ的关心
--=========================================================
function OtherXunzhang_TuJian_StopCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		this:CareObject(objCaredId, 0, "OtherXunzhang_TuJian");
		g_objCared = -1;
	else
		return;
	end

end

function OtherXunzhang_TuJian_CloseClick()
	OtherXunzhang_TuJian_SaveWindowPosition()
	
	-- 取消关心OBJ
	OtherXunzhang_TuJian_StopCareObject(g_objCared);
	this:Hide()
end

function OtherXunzhang_TuJian_OnHidden()
	OtherXunzhang_TuJian_CleanUp()
end

function OtherXunzhang_TuJian_CleanUp()
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then
			local ctrlAction = g_BarList[i]:GetSubItem("OtherXunzhang_TuJian_Frame_RightClient_Item")			
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
			end
		end
	end
	
	SetDefaultMouse();
end


function OtherXunzhang_TuJian_SaveWindowPosition()
	
	Variable:SetVariable("XunzhangBaseUnionPos", OtherXunzhang_TuJian_Frame:GetProperty("UnifiedPosition"), 1)
	
end

function OtherXunzhang_TuJian_SetWindowPosition()
	
	local nXunzhangBaseUnionPos = Variable:GetVariable("XunzhangBaseUnionPos")
	if nXunzhangBaseUnionPos ~= nil then
		OtherXunzhang_TuJian_Frame:SetProperty("UnifiedPosition", nXunzhangBaseUnionPos)
	end

end


--!!!reloadscript =OtherXunzhang_TuJian