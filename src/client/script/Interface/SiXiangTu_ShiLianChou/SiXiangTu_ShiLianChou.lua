-- SiXiangTu_ShiLianChou 四象图 十连抽界面 2020-8-3 lishilong
-- !!!reloadscript =SiXiangTu_ShiLianChou
--

local g_SiXiangTu_ShiLianChou_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 1
local bCaredObj 			= 1
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0

local g_nMainUICommandID	= 79005001
local g_nMaxNumForShow		= 10
local g_tabRewardIndex		= {0,0,0,0,0,0,0,0,0,0}
local g_nTimeTickCountDown	= 0
local g_controlActionButton = {}
local g_controlAnimate 		= {}

-- 完成了几次十连抽
local g_nFinishTime			= 0
-- 十连抽的二次确认是否点过
local g_nComfirmForShiLian	= 0

-- 四象图ID
local g_nUsedItemIDUnBind	= 38004876
local g_nUsedItemIDBind		= 38004877

local g_tabRewardInfo = 
{
	[1] = {nRan = 5000,   nItemID = 20310167, nShowItemID = 39920084, nNum = 3, bBind = 0, bSys = 0, nShowIndex = 1, },
	[2] = {nRan = 10000,   nItemID = 20502003, nShowItemID = 39920104, nNum = 1, bBind = 0, bSys = 1, nShowIndex = 2, },
	-- [3] = {nRan = 7000,   nItemID = 20310175, nShowItemID = 20310175, nNum = 2, bBind = 0, bSys = 0, nShowIndex = 3, },
	-- [4] = {nRan = 8200,   nItemID = 38000992, nShowItemID = 38000992, nNum = 2, bBind = 0, bSys = 0, nShowIndex = 4, },
	-- [5] = {nRan = 9400,   nItemID = 10125230, nShowItemID = 10125230, nNum = 1, bBind = 0, bSys = 1, nShowIndex = 5, },
	-- [6] = {nRan = 9700,   nItemID = 20501003, nShowItemID = 20501003, nNum = 1, bBind = 0, bSys = 0, nShowIndex = 6, },
	-- [7] = {nRan = 10000,  nItemID = 20502003, nShowItemID = 20502003, nNum = 1, bBind = 0, bSys = 0, nShowIndex = 7, },

	-- 注意这个索引和服务器的不一样！！！！！ 别直接拷贝服务器
	[101] = {nRan = 5000,   nItemID = 20310168, nShowItemID = 39920085, nNum = 3, bBind = 1, bSys = 0, nShowIndex = 101, },
	[102] = {nRan = 10000,   nItemID = 20502003, nShowItemID = 39920397, nNum = 1, bBind = 1, bSys = 1, nShowIndex = 102, },
	-- [103] = {nRan = 7000,   nItemID = 20310175, nShowItemID = 20310175, nNum = 2, bBind = 1, bSys = 0, nShowIndex = 103, },
	-- [104] = {nRan = 8200,   nItemID = 38000992, nShowItemID = 38000992, nNum = 2, bBind = 1, bSys = 0, nShowIndex = 104, },
	-- [105] = {nRan = 9400,   nItemID = 10125230, nShowItemID = 10125230, nNum = 1, bBind = 1, bSys = 1, nShowIndex = 105, },
	-- [106] = {nRan = 9700,   nItemID = 20501003, nShowItemID = 20501003, nNum = 1, bBind = 1, bSys = 0, nShowIndex = 106, },
	-- [107] = {nRan = 10000,  nItemID = 20502003, nShowItemID = 20502003, nNum = 1, bBind = 1, bSys = 0, nShowIndex = 107, },
}

--=========================================================
-- PreLoad
--=========================================================
function SiXiangTu_ShiLianChou_PreLoad()
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
end

--=========================================================
-- OnLoad
--=========================================================
function SiXiangTu_ShiLianChou_OnLoad()
	g_SiXiangTu_ShiLianChou_Frame_UnifiedPosition = SiXiangTu_ShiLianChou_Frame:GetProperty("UnifiedPosition")

	-- SiXiangTu_ShiLianChou_OK_Button : SetEvent("Clicked", "SiXiangTu_ShiLianChou_ConfirmClick()")

	g_controlActionButton[1] 	= SiXiangTu_ShiLianChou_Award_Item1
	g_controlActionButton[2] 	= SiXiangTu_ShiLianChou_Award_Item2
	g_controlActionButton[3] 	= SiXiangTu_ShiLianChou_Award_Item3
	g_controlActionButton[4] 	= SiXiangTu_ShiLianChou_Award_Item4
	g_controlActionButton[5] 	= SiXiangTu_ShiLianChou_Award_Item5
	g_controlActionButton[6] 	= SiXiangTu_ShiLianChou_Award_Item6
	g_controlActionButton[7] 	= SiXiangTu_ShiLianChou_Award_Item7
	g_controlActionButton[8] 	= SiXiangTu_ShiLianChou_Award_Item8
	g_controlActionButton[9] 	= SiXiangTu_ShiLianChou_Award_Item9
	g_controlActionButton[10] 	= SiXiangTu_ShiLianChou_Award_Item10

	g_controlAnimate[1] 		= SiXiangTu_ShiLianChou_Award_Item1_Animate
	g_controlAnimate[2] 		= SiXiangTu_ShiLianChou_Award_Item2_Animate
	g_controlAnimate[3] 		= SiXiangTu_ShiLianChou_Award_Item3_Animate
	g_controlAnimate[4] 		= SiXiangTu_ShiLianChou_Award_Item4_Animate
	g_controlAnimate[5] 		= SiXiangTu_ShiLianChou_Award_Item5_Animate
	g_controlAnimate[6] 		= SiXiangTu_ShiLianChou_Award_Item6_Animate
	g_controlAnimate[7] 		= SiXiangTu_ShiLianChou_Award_Item7_Animate
	g_controlAnimate[8] 		= SiXiangTu_ShiLianChou_Award_Item8_Animate
	g_controlAnimate[9] 		= SiXiangTu_ShiLianChou_Award_Item9_Animate
	g_controlAnimate[10] 		= SiXiangTu_ShiLianChou_Award_Item10_Animate
end

--=========================================================
-- OnEvent
--=========================================================
function SiXiangTu_ShiLianChou_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nMainUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				SiXiangTu_ShiLianChou_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SiXiangTu_ShiLianChou_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_SiXiangTu_ShiLianChou()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	SiXiangTu_ShiLianChou_OnClose()
			-- end
			SiXiangTu_ShiLianChou_Reset()
			SiXiangTu_ShiLianChou_Frame_On_ResetPos()
			this:Show()
			SiXiangTu_ShiLianChou_ParamInit()
			SiXiangTu_ShiLianChou_MoneyUpdate()
			SiXiangTu_ShiLianChou_YuanBaoUpdate()
			SiXiangTu_ShiLianChou_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SiXiangTu_ShiLianChou_OnClose()
					end
				end
			end
			if this:IsVisible() then

				-- 这里比较特殊，只有成功以后会刷新
				g_nFinishTime = g_nFinishTime + 1
				g_nComfirmForShiLian = 0

				SiXiangTu_ShiLianChou_ParamInit()

				g_nTimeTickCountDown = g_nMaxNumForShow
				SiXiangTu_ShiLianChou_Timeproc()
				SetTimer("SiXiangTu_ShiLianChou", "SiXiangTu_ShiLianChou_Timeproc()", 200)	
				
				SiXiangTu_ShiLianChou_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("SiXiangTu_ShiLianChou_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
		end

		-- 二次确认框
		if 4 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("SiXiangTu_ShiLianChou_OnComfirmedBack2", {["Content"] = strMsg,["Type"] = "YesNo", })
		end

		-- 二次确认框 重楼之芒功能借用一下
		if 5 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("SiXiangTu_ShiLianChou_OnComfirmedBack3", {["Content"] = strMsg,["Type"] = "YesNo", })
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
			SiXiangTu_ShiLianChou_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			SiXiangTu_ShiLianChou_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		SiXiangTu_ShiLianChou_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		SiXiangTu_ShiLianChou_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		SiXiangTu_ShiLianChou_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		SiXiangTu_ShiLianChou_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SiXiangTu_ShiLianChou_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function SiXiangTu_ShiLianChou_ParamInit()

	-- 初始化并排序
	local nSetIndexUnBind 	= 1
	local nSetIndexBind 	= g_nMaxNumForShow

	for i = 1, g_nMaxNumForShow do
		local nIndex = Get_XParam_INT(1 + i)
		if nil ~= Index and Index > 0 and nil ~= g_tabRewardInfo[Index] and 0 == g_tabRewardInfo[Index].bBind then
			g_tabRewardIndex[nSetIndexUnBind] = nIndex
			nSetIndexUnBind = nSetIndexUnBind + 1
		else
			g_tabRewardIndex[nSetIndexBind] = nIndex
			nSetIndexBind = nSetIndexBind - 1
		end
	end

end

--=========================================================
-- 倒计时
--=========================================================
function SiXiangTu_ShiLianChou_Timeproc() 

    -- PushDebugMessage("SiXiangTu_ShiLianChou_Timeproc")

	if g_nTimeTickCountDown <= 0 then
		return
	end

	g_nTimeTickCountDown = g_nTimeTickCountDown - 1

	if g_nTimeTickCountDown < 0 then
        g_nTimeTickCountDown = 0
	end

	SiXiangTu_ShiLianChou_Update(0)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function SiXiangTu_ShiLianChou_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnCompound" )
			Set_XSCRIPT_ScriptID(790050)
			Set_XSCRIPT_Parameter(0, -1)					
			Set_XSCRIPT_Parameter(1, 1)				
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function SiXiangTu_ShiLianChou_OnComfirmedBack2(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		g_nComfirmForShiLian = 1
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function SiXiangTu_ShiLianChou_OnComfirmedBack3(strRet)
	if nil == strRet then
		return
	end

	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnExchange" )
			Set_XSCRIPT_ScriptID(790058)
			Set_XSCRIPT_Parameter(0, -1)					
			Set_XSCRIPT_Parameter(1, 1)				
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end

	if "No" == strRet then
		
	end
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =SiXiangTu_ShiLianChou
function SiXiangTu_ShiLianChou_Update(bOpen)

	for i = 1, table.getn(g_controlActionButton) do
		if nil ~= g_controlActionButton[i] then
			g_controlActionButton[i] : SetActionItem(-1)
		end
	end

	for i = 1, table.getn(g_controlAnimate) do
		if nil ~= g_controlAnimate[i] then
			g_controlAnimate[i] : Hide()
		end
	end

	-- 这里的g_nTimeTickCountDown接收过来的值是9-0
	for i = 1, g_nMaxNumForShow - g_nTimeTickCountDown do
		local nRewardIndex = g_tabRewardIndex[i]
		if nil ~= nRewardIndex and nRewardIndex > 0 then
			local tabItemInfo = g_tabRewardInfo[nRewardIndex]

			if nil ~= tabItemInfo then
				if tabItemInfo.nItemID > 0 and tabItemInfo.nNum > 0 and nil ~= g_controlActionButton[i] then
					-- if 1 == tabItemInfo.bBind then
					-- 	local theAction = DataPool:CreateActionItemForShow(tabItemInfo.nItemID, tabItemInfo.nNum)
					-- 	g_controlActionButton[i] : SetActionItem(theAction:GetID())
					-- else
					-- 	local theAction = DataPool:CreateActionItemForShow(tabItemInfo.nItemID, tabItemInfo.nNum)
					-- 	g_controlActionButton[i] : SetActionItem(theAction:GetID())
					-- end		
					
					local theAction = DataPool:CreateActionItemForShow(tabItemInfo.nShowItemID, tabItemInfo.nNum)
					g_controlActionButton[i] : SetActionItem(theAction:GetID())
				end
	
				if tabItemInfo.bSys > 0 and nil ~= g_controlAnimate[i] then
					g_controlAnimate[i] : Show()
				end
			end

		end
	end

	-- 设置按钮文字
	if g_nFinishTime > 0 then
		SiXiangTu_ShiLianChou_Button : SetText("#{SXTZ_200731_40}")
		SiXiangTu_ShiLianChou_Button : SetToolTip("#{SXTZ_200731_39}")
	else
		SiXiangTu_ShiLianChou_Button : SetText("#{SXTZ_200731_36}")
		SiXiangTu_ShiLianChou_Button : SetToolTip("#{SXTZ_200731_39}")
	end

	-- 倒计时过程中 按钮置灰
	if g_nTimeTickCountDown > 0 then
		SiXiangTu_ShiLianChou_Button : Disable()
	else
		SiXiangTu_ShiLianChou_Button : Enable()
	end

	-- 拥有的四象图数量
	local nHaveNum = PlayerPackage:CountAvailableItemByIDTable(g_nUsedItemIDUnBind) + PlayerPackage:CountAvailableItemByIDTable(g_nUsedItemIDBind)

	if nHaveNum > g_nMaxNumForShow then
		SiXiangTu_ShiLianChou_Exist : SetText(ScriptGlobal_Format("#{SXTZ_200731_37}", nHaveNum))
	else
		SiXiangTu_ShiLianChou_Exist : SetText(ScriptGlobal_Format("#{SXTZ_200731_38}", nHaveNum))
	end
	
end

--=========================================================
-- 重置界面
--=========================================================
function SiXiangTu_ShiLianChou_Reset()
	for i = 1, table.getn(g_tabRewardIndex) do
		g_tabRewardIndex[i] = 0
	end

	g_nTimeTickCountDown 	= 0
	g_nFinishTime			= 0
 	g_nComfirmForShiLian	= 0

	KillTimer("SiXiangTu_ShiLianChou_Timeproc()")
end

--=========================================================
-- 界面确认按钮
--=========================================================
function SiXiangTu_ShiLianChou_ConfirmClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetReward10Times" )
		Set_XSCRIPT_ScriptID(790050)
		Set_XSCRIPT_Parameter(0, g_nServerObjID)					
		Set_XSCRIPT_Parameter(1, g_nComfirmForShiLian)				
		Set_XSCRIPT_Parameter(2, g_nFinishTime)				
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function SiXiangTu_ShiLianChou_OnClose()	
	this:Hide()
	StopCareObject_SiXiangTu_ShiLianChou()
	-- 重置
	SiXiangTu_ShiLianChou_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="SiXiangTu_ShiLianChou_OnHiden();" />
--=========================================================
function SiXiangTu_ShiLianChou_OnHiden()
	StopCareObject_SiXiangTu_ShiLianChou()
	-- 重置
	SiXiangTu_ShiLianChou_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_SiXiangTu_ShiLianChou()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "SiXiangTu_ShiLianChou")
end

function StopCareObject_SiXiangTu_ShiLianChou()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "SiXiangTu_ShiLianChou")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function SiXiangTu_ShiLianChou_MoneyUpdate()
	-- SiXiangTu_ShiLianChou_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- SiXiangTu_ShiLianChou_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function SiXiangTu_ShiLianChou_YuanBaoUpdate()
	-- SiXiangTu_ShiLianChou_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function SiXiangTu_ShiLianChou_Frame_On_ResetPos()
	SiXiangTu_ShiLianChou_Frame:SetProperty("UnifiedPosition", g_SiXiangTu_ShiLianChou_Frame_UnifiedPosition)
end