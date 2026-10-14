-- Rune_Stars_BatchSplit 无字谱分解所有满级的残印
-- !!!reloadscript =Rune_Stars_BatchSplit
--

local g_Rune_Stars_BatchSplit_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0

local g_nUICommandID		= 88855502
local g_Chip2Token 			= {5,45,200,50}
local g_nMaxOrder 			= 5
local g_bBarListInited 		= 0
local g_BarList				= {}
--=========================================================
-- PreLoad
--=========================================================
function Rune_Stars_BatchSplit_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	if 1 == bCaredItem then
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	end
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	if 1 == bCaredYuanBao then
		this:RegisterEvent("UPDATE_YUANBAO", false)
	end
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")

	this:RegisterEvent("XINGZHEN_UPDATE",false)
end

--=========================================================
-- OnLoad
--=========================================================
function Rune_Stars_BatchSplit_OnLoad()
	g_Rune_Stars_BatchSplit_Frame_UnifiedPosition = Rune_Stars_BatchSplit_Frame:GetProperty("UnifiedPosition")

	-- Rune_Stars_BatchSplit_OK_Button : SetEvent("Clicked", "Rune_Stars_BatchSplit_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function Rune_Stars_BatchSplit_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				Rune_Stars_BatchSplit_CloseClicked()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						Rune_Stars_BatchSplit_CloseClicked()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_Rune_Stars_BatchSplit()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			if this:IsVisible() then
				Rune_Stars_BatchSplit_CloseClicked()
			end
			Rune_Stars_BatchSplit_Reset()
			Rune_Stars_BatchSplit_Frame_On_ResetPos()
			this:Show()
			Rune_Stars_BatchSplit_ParamInit()
			Rune_Stars_BatchSplit_MoneyUpdate()
			Rune_Stars_BatchSplit_YuanBaoUpdate()
			Rune_Stars_BatchSplit_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						Rune_Stars_BatchSplit_CloseClicked()
					end
				end
			end
			if this:IsVisible() then
				Rune_Stars_BatchSplit_ParamInit()
				Rune_Stars_BatchSplit_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("Rune_Stars_BatchSplit_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		end

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			Rune_Stars_BatchSplit_CloseClicked()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			Rune_Stars_BatchSplit_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		Rune_Stars_BatchSplit_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		Rune_Stars_BatchSplit_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Rune_Stars_BatchSplit_CloseClicked()
	
	elseif (event == "ADJEST_UI_POS" ) then
		Rune_Stars_BatchSplit_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Rune_Stars_BatchSplit_Frame_On_ResetPos()

	elseif (event == "XINGZHEN_UPDATE") then
		-- 刷新界面
		if this:IsVisible() then
			Rune_Stars_BatchSplit_Update(0)
		end
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function Rune_Stars_BatchSplit_ParamInit()

	-- 顺便在这里加个list初始化
	if 1 ~= g_bBarListInited then
		local nXingJuanMaxCount = DataPool:LuaFnGetXingJuanMaxCount()
		for i = 1, nXingJuanMaxCount do
			local bar = Rune_Stars_BatchSplit_PatchLace:AddChild("Rune_Stars_BatchSplit_PatchCoinAItem")
			-- bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			-- bar:GetSubItem("Rune_Stars_BatchSplit_PatchCoinAItemOption"):SetEvent("MouseLButtonDown", string.format("Rune_Stars_BatchSplit_ItemClicked_B(%d)", i))
			g_BarList[i] = bar
		end

		g_bBarListInited = 1
	end
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function Rune_Stars_BatchSplit_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then

	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =Rune_Stars_BatchSplit
function Rune_Stars_BatchSplit_Update(bOpen)

	-- if 0 == bOpen then
		
	-- end
	-- Rune_Stars_BatchSplit_PatchLace : RefreshLayout()
	Rune_Stars_BatchSplit_PatchLace : SetScrollPosition(0)

	local nXingJuanMaxCount = DataPool:LuaFnGetXingJuanMaxCount()
	-- 先全部隐藏
	for i = 1, nXingJuanMaxCount do
		g_BarList[i] : Hide()
	end

	-- 遍历所有残印，找到满级的显示
	local nBarIndex = 1
	local nReturnCountH = 0
	local nReturnCountL = 0
	for nXingJuanID = 1, nXingJuanMaxCount do

		local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
		local nChipCount = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "ChipCount")

		if nOrder >= g_nMaxOrder and nChipCount > 0 then

			-- PushDebugMessage("nBarIndex:"..nBarIndex)

			local bar = g_BarList[nBarIndex]
			nBarIndex = nBarIndex + 1
			bar : Show()
			local ctrlAction = bar:GetSubItem("Rune_Stars_BatchSplit_PatchCoinAItemOption")
			if ctrlAction ~= nil then
				ctrlAction:SetActionItem(-1)		
				local theAction = EnumAction(nXingJuanID,"xingjuanchip")
				if theAction:GetID() ~= 0 then
					ctrlAction:SetActionItem(theAction:GetID())
				end	
				ctrlAction:SetProperty("DraggingEnabled","False")
				
				-- if g_CurrentSelChipID == nXingJuanID then
				-- 	ctrlAction:SetPushed(1)
				-- else
				-- 	ctrlAction:SetPushed(0)
				-- end		
			end

			-- local nActiveNeedChipCount = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "ActiveNeedChipCount")
			local nQuality = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Quality")
			-- local strNameColor = Rune_Stars_BatchSplit_GetQualColor(nQuality)
			-- local nUnLocked = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "UnLocked")
			-- local nLevel = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Level")
			-- local nSlot = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Slot")
			local strName = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Name")
			-- bar:GetSubItem("Rune_Stars_BatchSplit_CoinAItemOptionName") : SetText(tostring("#L"..strName.."#{XZJC_200309_276}"))
			local strShowName = ScriptGlobal_Format("#{WZPCY_20220419_08}", strName)
			strShowName = strShowName.."#{XZJC_200309_276}"
			bar:GetSubItem("Rune_Stars_BatchSplit_CoinAItemOptionName") : SetText(strShowName)
			-- bar:GetSubItem("Rune_Stars_BatchSplit_PatchRank"):SetText("#e010101"..tostring(nChipCount))
			local strShowCount = ScriptGlobal_Format("#{WZPCY_20220419_07}",tostring(nChipCount))
			bar:GetSubItem("Rune_Stars_BatchSplit_PatchRank") : SetText(strShowCount)

			if 4 == nQuality then
				nReturnCountH = nReturnCountH + g_Chip2Token[4] * nChipCount
			else
				nReturnCountL = nReturnCountL + g_Chip2Token[nQuality] * nChipCount
			end
		end
	end

	Rune_Stars_BatchSplit_Text1Num : SetText(ScriptGlobal_Format("#{WZPCY_20220419_10}",tostring(nReturnCountH)) )
	Rune_Stars_BatchSplit_Text2Num : SetText(ScriptGlobal_Format("#{WZPCY_20220419_12}",tostring(nReturnCountL)) )
end

--=========================================================
-- 重置界面
--=========================================================
function Rune_Stars_BatchSplit_Reset()
	if 1 == g_bBarListInited then
		local nXingJuanMaxCount = DataPool:LuaFnGetXingJuanMaxCount()
		for i = 1, nXingJuanMaxCount do
			local ctrlAction = g_BarList[i]:GetSubItem("Rune_Stars_BatchSplit_PatchCoinAItemOption")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
	end
end

--=========================================================
-- 界面确认按钮
--=========================================================
function Rune_Stars_BatchSplit_OKClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "MeltAllFullChip" )
		Set_XSCRIPT_ScriptID(888555)							
		Set_XSCRIPT_Parameter(0, 0)								
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function Rune_Stars_BatchSplit_CloseClicked()	
	this:Hide()
	StopCareObject_Rune_Stars_BatchSplit()
	-- 重置
	Rune_Stars_BatchSplit_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="Rune_Stars_BatchSplit_OnHidden();" />
--=========================================================
function Rune_Stars_BatchSplit_OnHidden()
	StopCareObject_Rune_Stars_BatchSplit()
	-- 重置
	Rune_Stars_BatchSplit_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_Rune_Stars_BatchSplit()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "Rune_Stars_BatchSplit")
end

function StopCareObject_Rune_Stars_BatchSplit()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "Rune_Stars_BatchSplit")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function Rune_Stars_BatchSplit_MoneyUpdate()
	-- Rune_Stars_BatchSplit_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- Rune_Stars_BatchSplit_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function Rune_Stars_BatchSplit_YuanBaoUpdate()
	-- Rune_Stars_BatchSplit_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function Rune_Stars_BatchSplit_Frame_On_ResetPos()
	Rune_Stars_BatchSplit_Frame:SetProperty("UnifiedPosition", g_Rune_Stars_BatchSplit_Frame_UnifiedPosition)
end