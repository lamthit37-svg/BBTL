--华尚阁
local g_ObjCareID = -1
local MAX_OBJ_DISTANCE 	 = 3.0;
local m_Frame_UnifiedPosition = 0

local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度

local m_CameraLevel = 0
local m_CameraPosition =
{
	--女性相关位置
	[0] = { 
				[0] = { fHeight = 0.95, fDistance = 5.4, },
				[1] = { fHeight = 1.55, fDistance = 2, },
				[2] = { fHeight = 1.65, fDistance = 1.2, }, 
			},
			
	--男性相关位置
	[1] = {
				[0] = { fHeight = 1,	fDistance = 6, },
				[1] = { fHeight = 1.65,	fDistance = 2.2,},
				[2] = { fHeight = 1.82,	fDistance = 1.2,},
			},
}  


local m_InfantDressBoxFrame_CameraHeight = 1		--摄影机高度
local m_InfantDressBoxFrame_CameraDistance = 2		--摄影机距离
local m_InfantDressBoxFrame_CameraPitch = 3			--摄影机角度

--UI控件
local m_UITitle = nil
local m_UIShowModel = nil
local m_UIShowName = nil
local m_UIShowItem = nil
local m_UIItemList = {}
local m_UIPageText = nil
local m_UIReturnButton = nil

-----------------------
local m_clickItemPos = -1 --点击的item位置
local m_fashionDepotType = 0 --仓库类型 1 玩家时装仓库 2 子女时装仓库
local m_curPage = 0
local m_maxPage = 4
local m_everyPageMaxSlotNum = 40

local g_FeiyuNewDressID = {
10126162,--	新锦衣卫嫣然
10126163,--	新锦衣卫红翡
10126164,--	新锦衣卫青蓝
}
local g_FeiyuDressStr = {
"#{FYYR_200610_34}",
"#{FYYR_200610_35}",
"#{FYYR_200610_36}",
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function DressClosetFrame_PreLoad()
	this:RegisterEvent("FASHION_DEPOT_OP")
	this:RegisterEvent("FASHION_DEPOT_UPDATE", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- FakeObject模型界面互斥
	this:RegisterEvent("OPEN_EQUIP",false);										-- 角色资料界面
	this:RegisterEvent("OPEN_SHOP_FITTING",false);			-- 普通商店试衣间
	this:RegisterEvent("OPEN_DRESS_PAINT_FITTING",false);			-- 时装染色试衣间
	this:RegisterEvent("OPEN_DRESS_ENCHASE_FITTING",false);		-- 时装镶嵌试衣间
	this:RegisterEvent("YIGUI_OPEN",false);				-- 衣柜
	this:RegisterEvent("FEIYUSHOW_WINDOW",false);
	this:RegisterEvent("OPEN_SPECIALDRESSPAINT", false)	
	this:RegisterEvent("UI_COMMAND",false);				-- 变性
	this:RegisterEvent("OPEN_YB_SHOP_FITTING",false)

end

--加载窗口的时候调用的函数，加载窗口时调用一次
function DressClosetFrame_OnLoad()
	m_Frame_UnifiedPosition = DressCloset_Frame:GetProperty("UnifiedPosition")
	m_UITitle = DressCloset_DragTitle
	m_UIShowModel = DressCloset_ShowModel
	m_UIShowName = DressCloset_ShowName
	m_UIShowItem = DressCloset_Show_Item
	m_UIItemList[1] = DressCloset_Bank1
	m_UIItemList[2] = DressCloset_Bank2
	m_UIItemList[3] = DressCloset_Bank3
	m_UIItemList[4] = DressCloset_Bank4
	m_UIItemList[5] = DressCloset_Bank5
	m_UIItemList[6] = DressCloset_Bank6
	m_UIItemList[7] = DressCloset_Bank7
	m_UIItemList[8] = DressCloset_Bank8
	m_UIItemList[9] = DressCloset_Bank9
	m_UIItemList[10] = DressCloset_Bank10
	m_UIItemList[11] = DressCloset_Bank11
	m_UIItemList[12] = DressCloset_Bank12
	m_UIItemList[13] = DressCloset_Bank13
	m_UIItemList[14] = DressCloset_Bank14
	m_UIItemList[15] = DressCloset_Bank15
	m_UIItemList[16] = DressCloset_Bank16
	m_UIItemList[17] = DressCloset_Bank17
	m_UIItemList[18] = DressCloset_Bank18
	m_UIItemList[19] = DressCloset_Bank19
	m_UIItemList[20] = DressCloset_Bank20
	m_UIItemList[21] = DressCloset_Bank21
	m_UIItemList[22] = DressCloset_Bank22
	m_UIItemList[23] = DressCloset_Bank23
	m_UIItemList[24] = DressCloset_Bank24
	m_UIItemList[25] = DressCloset_Bank25
	m_UIItemList[26] = DressCloset_Bank26
	m_UIItemList[27] = DressCloset_Bank27
	m_UIItemList[28] = DressCloset_Bank28
	m_UIItemList[29] = DressCloset_Bank29
	m_UIItemList[30] = DressCloset_Bank30
	m_UIItemList[31] = DressCloset_Bank31
	m_UIItemList[32] = DressCloset_Bank32
	m_UIItemList[33] = DressCloset_Bank33
	m_UIItemList[34] = DressCloset_Bank34
	m_UIItemList[35] = DressCloset_Bank35
	m_UIItemList[36] = DressCloset_Bank36
	m_UIItemList[37] = DressCloset_Bank37
	m_UIItemList[38] = DressCloset_Bank38
	m_UIItemList[39] = DressCloset_Bank39
	m_UIItemList[40] = DressCloset_Bank40

	m_UIPageText = DressCloset_BankText
	m_UIReturnButton = DressCloset_ShowReturn
end

--响应事件的函数，当注册的事件发生时会调用的函数
function DressClosetFrame_OnEvent(event)

	if 1 == 1 then
		return
	end
	
	if event == "FASHION_DEPOT_OP" then
		local opType = tonumber(arg0)
		if opType == 1 then --打开界面
			local fashionDepotType = tonumber(arg1)
			g_ObjCareID = tonumber(arg2)
			if(this:IsVisible()) then
				return
			end
			
			if IsWindowShow("VIP_Shop") then
				CloseWindow("VIP_Shop", true)
			end
			if(IsWindowShow("YuanbaoShop")) then
				CloseWindow("YuanbaoShop", true)
			end
			if(IsWindowShow("ShowShop")) then
				CloseWindow("ShowShop", true)
			end
			if(IsWindowShow("XuanShop")) then
				CloseWindow("XuanShop", true)
			end
			m_fashionDepotType = fashionDepotType
			m_curPage = 1
			DressClosetFrame_Show()
			FashionDepot:LuaFnRestoreFashionDepot(m_fashionDepotType, 0)
			DressClosetFrame_Update()
		elseif opType == 2 then --关闭界面
			DressClosetFrame_Hide()
		elseif opType == 3 then --//点击背包中的物品存入时装仓库
			if(this:IsVisible()) then
				local nSourcePos = tonumber(arg1)
				local targetPos = -1
				if m_curPage < 1 or m_curPage > m_maxPage then
					return
				end
				DressClosetFrame_BagToFashionDepot(1, nSourcePos, targetPos)
			end
		elseif opType == 4 then --//拖拽时装仓库的物品存入背包
			if(this:IsVisible()) then
				local nSourcePos = tonumber(arg1)
				local targetPos = tonumber(arg2)
				if m_curPage < 1 or m_curPage > m_maxPage then
					return
				end
				FashionDepot:LuaFnSendFashionDepotOperation(m_fashionDepotType, 2, nSourcePos, targetPos, m_curPage)
			end
		elseif opType == 5 then --//点击时装仓库中的物品 存入背包
			if(this:IsVisible()) then
				local nSourcePos = tonumber(arg1)
				local targetPos = -1
				if m_curPage < 1 or m_curPage > m_maxPage then
					return
				end
				FashionDepot:LuaFnSendFashionDepotOperation(m_fashionDepotType, 2, nSourcePos, targetPos, m_curPage)
			end
		elseif opType == 6 then --//拖拽背包的物品存入时装仓库
			if(this:IsVisible()) then
				local nSourcePos = tonumber(arg1)
				local index = tonumber(arg2)
				if m_curPage < 1 or m_curPage > m_maxPage then
					return
				end
				local targetPos = DressClosetFrame_ItemListDragIndexToPos(index)
				if targetPos == -1 then
					return
				end
				DressClosetFrame_BagToFashionDepot(1, nSourcePos, targetPos)
			end
		elseif opType == 7 then --//左键点击时装仓库中的道具
			if(this:IsVisible()) then
				local nSourcePos = tonumber(arg1)
				FashionDepot:LuaFnReWearFromFashionDepot(m_fashionDepotType, nSourcePos)
			end
		elseif opType == 8 then --//时装仓库内部拖拽
			if(this:IsVisible()) then
				local nSourcePos = tonumber(arg1)
				local index = tonumber(arg2)
				if m_curPage < 1 or m_curPage > m_maxPage then
					return
				end
				local targetPos = DressClosetFrame_ItemListDragIndexToPos(index)
				if targetPos == -1 then
					return
				end
				if nSourcePos == targetPos then --相同格子不用进行移动
					return
				end
				FashionDepot:LuaFnSendFashionDepotOperation(m_fashionDepotType, 3, nSourcePos, targetPos, m_curPage)
			end
		elseif opType == 9 then --只进行刷新
			if(this:IsVisible()) then
				if(this:IsVisible()) then
					if m_fashionDepotType == 1 then
						m_UIShowModel:SetFakeObject("FashionDepot_Player")
						DressClosetFrame_setCameraPosition()
					elseif m_fashionDepotType == 2 then

						m_UIShowModel:SetFakeObject("My_Infant_Fashion_Depot")

						FakeObj_SetCamera( "My_Infant_Fashion_Depot", m_InfantDressBoxFrame_CameraHeight, 0.7 )
						FakeObj_SetCamera( "My_Infant_Fashion_Depot", m_InfantDressBoxFrame_CameraDistance, 4 )
						FakeObj_RestoreCamera( "My_Infant_Fashion_Depot" )
					end
				end
			end
		end

	elseif event == "FASHION_DEPOT_UPDATE" then
		local opType = tonumber(arg0)
		if opType == 1 or opType == 2 then --请求时装仓库返回的结果
		elseif opType == 3 or opType == 4 then
			if(this:IsVisible()) then
				local opTypeEx = tonumber(arg1)
				local nPos = tonumber(arg2)
				-- local page = DressClosetFrame_PosToPage(nPos)
				FashionDepot:LuaFnSlotChangeRestoreFashionDepot(m_fashionDepotType, nPos)
				-- if page == m_curPage then
					DressClosetFrame_UpdatePos(nPos)
				-- else
				-- 	m_curPage = page
				-- 	DressClosetFrame_Update()
				-- end
			end
		elseif opType == 5 then
			local nPos = tonumber(arg1)
			DressClosetFrame_UpdatePos(nPos)
		elseif opType == 6 then --开始整理
			DressCloset_ShowClearUp:Disable()
		elseif opType == 7 then --结束整理
			DressCloset_ShowClearUp:Enable()
			DressClosetFrame_Update()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DressClosetFrame_On_ResetPos()
	elseif (event == "ADJEST_UI_POS") then
		DressClosetFrame_On_ResetPos()
	elseif event == "OBJECT_CARED_EVENT" then
		DressClosetFrame_CareEvent(arg0,arg1,arg2)
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DressClosetFrame_Hide()
	--各种互斥
	elseif ( event == "OPEN_EQUIP" ) or						-- 角色资料界面
		(event == "OPEN_SHOP_FITTING") or				--普通商店试衣间
		( event == "OPEN_YB_SHOP_FITTING" )or			--元宝商店试衣间
		 ( event == "OPEN_DRESS_PAINT_FITTING" ) or		-- 时装染色试衣间
		 ( event == "OPEN_DRESS_ENCHASE_FITTING" ) or	-- 时装镶嵌试衣间
		 ( event == "YIGUI_OPEN") or					-- 衣柜
		 ((event == "UI_COMMAND" and tonumber(arg0) == 20120406)) or--变性
		 (event == "FEIYUSHOW_WINDOW" and tonumber(arg0) >= 0) or
		 (event == "OPEN_SPECIALDRESSPAINT" and tonumber(arg0) >= 0) 
		then
		if this:IsVisible() then
			DressClosetFrame_Hide()
		end
	end
end
--背包到时装仓库
function DressClosetFrame_BagToFashionDepot(opType, nSourcePos, targetPos)

	local theAction,bLocked,bProtect,nElapsedTime = PlayerPackage:EnumItem("base", nSourcePos);
	if theAction:GetID() ~= 0  then 
		local opResult = FashionDepot:LuaFnJudgeBagItem(m_fashionDepotType, nSourcePos)
		if opResult == 2 then --不是时装
			PushDebugMessage("#{HCG_190117_18}")
		elseif opResult == 3 then --镶嵌有 密语金丝
			PushDebugMessage("#{HCG_190117_36}")
		elseif opResult == 4 then --计时时装
			PushDebugMessage("#{HCG_190117_18}")
		elseif opResult == 5 then --解除锁定倒计时中 -使用了二级密码进行了解锁 需要二次确认
			PushEvent("FASHION_DEPOT_UPDATE", 1000, m_fashionDepotType, opType, nSourcePos, targetPos, m_curPage) --二次确认
		elseif opResult == 100 then --不是子女时装
			PushDebugMessage("#{HCG_190117_32}")
		elseif opResult == 101 then --子女计时时装
			PushDebugMessage("#{HCG_190117_32}")
		elseif opResult == 102 then --子女解除锁定倒计时中 -使用了二级密码进行了解锁 需要二次确认
			PushEvent("FASHION_DEPOT_UPDATE", 1000, m_fashionDepotType, opType, nSourcePos, targetPos, m_curPage) --二次确认
		elseif opResult == 1 then
			FashionDepot:LuaFnSendFashionDepotOperation(m_fashionDepotType, opType, nSourcePos, targetPos, m_curPage)
		end
	end
end
function DressClosetFrame_GetPosBeginAndEndFromPage(page)
	local beginPos = (page - 1) * m_everyPageMaxSlotNum
	local endPos = page * m_everyPageMaxSlotNum - 1
	return beginPos, endPos
end

function DressClosetFrame_PosToItemListIndex(pos)
	if pos < 0 then
		return 0
	end
	return math.mod(pos, m_everyPageMaxSlotNum) + 1
end
function DressClosetFrame_ItemListDragIndexToPos(index)
	if index < 0 then
		return -1
	end
	return index +  m_everyPageMaxSlotNum*(m_curPage - 1)
end
function DressClosetFrame_PosToPage(pos)
	if pos < 0 then
		return 0
	end
	return math.floor(pos/m_everyPageMaxSlotNum) + 1
end
--显示UI
function DressClosetFrame_Show()
	if g_ObjCareID ~= -1 then
		this:CareObject(g_ObjCareID, 1, "DressClosetFrame")
	end
	this:Show()
	m_UIShowName:SetText("")
	DressCloset_ShowClearUp:Enable()
	-- DressCloset_ShowRestore:Disable()
	DressCloset_ShowRestore:Hide()
	m_clickItemPos = -1
end
--隐藏UI
function DressClosetFrame_Hide()
	FashionDepot:LuaFnRestoreFashionDepot(m_fashionDepotType, 0)
	DressClosetFrame_ClearData()
   --取消关心
	if g_ObjCareID ~= -1 then
		this:CareObject(g_ObjCareID, 0, "DressClosetFrame")
	end
	this:Hide()
end

--清除数据
function DressClosetFrame_ClearData()
	m_UIShowModel:SetFakeObject("")
	m_curPage = 1
	m_clickItemPos = -1
end
--更新
function DressClosetFrame_Update()
	if m_curPage < 1 or m_curPage > m_maxPage then
		return
	end
	DressCloset_BankFrontBtn:Enable()
	DressCloset_BankNextBtn:Enable()
	if m_curPage <= 1 then
		DressCloset_BankFrontBtn:Disable()
	elseif m_curPage >= m_maxPage then
		DressCloset_BankNextBtn:Disable()
	end
	m_UIPageText:SetText(ScriptGlobal_Format("#{HCG_190117_13}", m_curPage))
	if m_fashionDepotType == 1 then
		m_UITitle:SetText("#{HCG_190117_07}")
		m_UIReturnButton:SetProperty("PushedImage","set:ButtonCloset image:ReturnCloset_Btn_Push")
		m_UIReturnButton:SetProperty("NormalImage","set:ButtonCloset image:ReturnCloset_Btn_Normal")
		m_UIReturnButton:SetProperty("HoverImage","set:ButtonCloset image:ReturnCloset_Btn_Hover")
		m_UIReturnButton:SetToolTip("#{HCG_190117_11}")
		m_UIShowItem:SetToolTip("#{HCG_190117_08}")
		m_UIShowItem:SetActionItem(-1)
		local ActionDress 		= EnumAction(16, "equip")
		m_UIShowItem:SetActionItem(ActionDress:GetID())
		if ActionDress:GetID() == 0 then

		end
		m_UIShowModel:SetFakeObject("")
		m_UIShowModel:SetFakeObject("FashionDepot_Player")
		DressClosetFrame_setCameraPosition()
		
	elseif m_fashionDepotType == 2 then
		m_UITitle:SetText("#{HCG_190117_28}")

		m_UIReturnButton:SetProperty("PushedImage","set:ButtonCloset image:ReturnChildCloset_Btn_Push")
		m_UIReturnButton:SetProperty("NormalImage","set:ButtonCloset image:ReturnChildCloset_Btn_Normal")
		m_UIReturnButton:SetProperty("HoverImage","set:ButtonCloset image:ReturnChildCloset_Btn_Hover")

		m_UIReturnButton:SetToolTip("#{HCG_190117_31}")
		m_UIShowItem:SetToolTip("#{HCG_190117_29}")

		m_UIShowItem:SetActionItem(-1)
		local ActionDress = EnumAction(6, "infantcard" )
		m_UIShowItem:SetActionItem(ActionDress:GetID())
		if ActionDress:GetID() == 0 then

		end

		m_UIShowModel:SetFakeObject( "" )
		m_UIShowModel:SetFakeObject("My_Infant_Fashion_Depot")

		FakeObj_SetCamera( "My_Infant_Fashion_Depot", m_InfantDressBoxFrame_CameraHeight, 0.7 )
		FakeObj_SetCamera( "My_Infant_Fashion_Depot", m_InfantDressBoxFrame_CameraDistance, 4 )
		FakeObj_RestoreCamera( "My_Infant_Fashion_Depot" )
	end
	local beginPos, endPos = DressClosetFrame_GetPosBeginAndEndFromPage(m_curPage)

	local isHave, equipID, equipPoint, visualID, savePos = FashionDepot:LuaFnGetWearEndCacheData(m_fashionDepotType)
	for pos = beginPos, endPos do
		local theAction,bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_fashionDepotType, pos)
		local index = DressClosetFrame_PosToItemListIndex(pos)
		if nil ~= m_UIItemList[index] then
			m_UIItemList[index]:Show()
			if theAction:GetID() ~= 0 then
				m_UIItemList[index]:SetActionItem(theAction:GetID());
				if nil ~= isHave and 1 == isHave and savePos == pos then
					theAction:SetSelectStatus(1)
				else
					theAction:SetSelectStatus(0)
				end
			else
				m_UIItemList[index]:SetActionItem(-1);
			end
			-- if bLocked == 1 then
			-- 	m_UIItemList[index]:Disable();
			-- else
			-- 	m_UIItemList[index]:Enable();
			-- end
		end
	end
	
end
--更新
function DressClosetFrame_UpdatePos(nPos)

	local theAction,bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_fashionDepotType, nPos)
	local index = DressClosetFrame_PosToItemListIndex(nPos)
	if nil ~= m_UIItemList[index] then
		local beginPos, endPos = DressClosetFrame_GetPosBeginAndEndFromPage(m_curPage)
		if nPos >= beginPos and nPos <= endPos then
			m_UIItemList[index]:Show()
			if theAction:GetID() ~= 0 then
				m_UIItemList[index]:SetActionItem(theAction:GetID());
				theAction:SetSelectStatus(0)
			else
				m_UIItemList[index]:SetActionItem(-1);
			end
		end

		
		-- if bLocked == 1 then
		-- 	m_UIItemList[index]:Disable();
		-- else
		-- 	m_UIItemList[index]:Enable();
		-- end
	end
	local isHave, equipID, equipPoint, visualID, savePos = FashionDepot:LuaFnGetWearEndCacheData(m_fashionDepotType)
	local saveIndex = DressClosetFrame_PosToItemListIndex(savePos)
	local theSaveAction,bLocked = FashionDepot:LuaFnGetFashionDepotItem(m_fashionDepotType, savePos)
	if nil ~= isHave and 1 == isHave then
		local name = FashionDepot:LuaFnGetFashionName(m_fashionDepotType,  savePos)
		if equipID==g_FeiyuNewDressID[1] then
			m_UIShowName:SetText(ScriptGlobal_Format("#{HCG_190117_09}", name, g_FeiyuDressStr[1]))
		elseif equipID==g_FeiyuNewDressID[2] then
			m_UIShowName:SetText(ScriptGlobal_Format("#{HCG_190117_09}", name, g_FeiyuDressStr[2]))
		elseif equipID==g_FeiyuNewDressID[3] then
			m_UIShowName:SetText(ScriptGlobal_Format("#{HCG_190117_09}", name, g_FeiyuDressStr[3]))
		else
			local VisualDesc = FashionDepot:LuaFnGetFashionDataVisualDesc(m_fashionDepotType, savePos, equipID, visualID)
			if nil ~= VisualDesc and "" ~= VisualDesc then
				m_UIShowName:SetText(ScriptGlobal_Format("#{HCG_190117_09}", name, VisualDesc))
			else
				m_UIShowName:SetText("#cfff263"..name)
			end
		end

		-- DressCloset_ShowRestore:Enable()
		m_clickItemPos = savePos
		if theSaveAction:GetID() ~= 0 then
			theSaveAction:SetSelectStatus(1)
		end
	else
		m_UIShowName:SetText("")
		-- DressCloset_ShowRestore:Disable()
		m_clickItemPos = -1
		if theSaveAction:GetID() ~= 0 then
			theSaveAction:SetSelectStatus(0)
		end
	end
end

function DressClosetFrame_setCameraPosition()
		local Sex = GetMySelfRaceId()
		if Sex > 1 or Sex < 0 then 
			return
		end
		
		FakeObj_SetCamera( "FashionDepot_Player", g_CameraDistance,m_CameraPosition[Sex][m_CameraLevel].fDistance)
		FakeObj_SetCamera( "FashionDepot_Player", g_CameraHeight,m_CameraPosition[Sex][m_CameraLevel].fHeight)
end
--##############点击事件##############
--关闭
function DressClosetFrame_ClickClose()
	DressClosetFrame_Hide()
end
--
-- 选装玩家模型（向左)
--
function DressClosetFrame_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			m_UIShowModel:RotateBegin(-0.3);
		--向左旋转结束
		else
			m_UIShowModel:RotateEnd();
		end
	end
end

--
-- 选装玩家模型（向右)
--
function DressClosetFrame_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			m_UIShowModel:RotateBegin(0.3);
		--向右旋转结束
		else
			m_UIShowModel:RotateEnd();
		end
	end
end
--上一页
function DressClosetFrame_ClickFrontBtn()
	if m_curPage <= 1 then
		m_curPage = 1
		return
	end
	m_curPage = m_curPage - 1
	DressClosetFrame_Update()
end
--下一页
function DressClosetFrame_ClickNextBtn()
	if m_curPage >= m_maxPage then
		m_curPage = m_maxPage
		return
	end
	m_curPage = m_curPage + 1
	DressClosetFrame_Update()
end
--返回
function DressClosetFrame_ClickBackBtn()
	--PushDebugMessage("DressClosetFrame_ClickBackBtn")
	DressClosetFrame_Hide()
	PushEvent("YIGUI_OPEN", m_fashionDepotType-1)
end
--还原
function DressClosetFrame_ClickRestoreBtn()
	FashionDepot:LuaFnRestoreFashionDepot(m_fashionDepotType, 1)
end
--整理
function DressClosetFrame_ClickClearUpBtn()
	FashionDepot:LuaFnRestoreFashionDepot(m_fashionDepotType, 0)
	if m_curPage < 1 or m_curPage > m_maxPage then
		return
	end
	local beginPos, endPos = DressClosetFrame_GetPosBeginAndEndFromPage(m_curPage)
	FashionDepot:LuaFnRefreshFashionDepot(m_fashionDepotType, beginPos, endPos, m_curPage)
end
function DressClosetFrame_ItemBtnClicked(index)
	if nil == m_UIItemList[index] then
		return
	end
	m_UIItemList[index]:DoAction()
end
function DressClosetFrame_ItemBtnSubClicked(index)
	if nil == m_UIItemList[index] then
		return
	end
	local savePage = DressClosetFrame_PosToPage(m_clickItemPos)
	if savePage == m_curPage then
		local saveIndex = DressClosetFrame_PosToItemListIndex(m_clickItemPos)
		if index == saveIndex then
			FashionDepot:LuaFnRestoreFashionDepot(m_fashionDepotType, 1)
			return
		end
	end

	m_UIItemList[index]:DoSubAction()
end
--####################################

--以下是用户自定义的函数
function DressClosetFrame_CareEvent(arg0,arg1,arg2)
	local ObjCaredID = tonumber(arg0)
	if( ObjCaredID ~= g_ObjCareID or g_ObjCareID == -1 ) then
		return
	end
	local ObjDistance = tonumber(arg2)
	if( (arg1 == "distance" and ObjDistance>MAX_OBJ_DISTANCE) or arg1=="destroy") then
		DressClosetFrame_Hide()
	end
end

function DressClosetFrame_On_ResetPos()
	DressCloset_Frame:SetProperty("UnifiedPosition",m_Frame_UnifiedPosition);
end