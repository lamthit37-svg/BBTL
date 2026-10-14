-- QiXi_JiaShu
-- !!!reloadscript =QiXi_JiaShu
--

local g_QiXi_JiaShu_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0

local g_nUICommandID		= 79115801
local g_nShowPage			= 1
local g_nItemBagPos			= -1
local g_nUseItemId			= -1
local g_tCPageBk			= {}

-- 淡入淡出时间 单位s
local g_nFadeLastTime		= 3

--=========================================================
-- PreLoad
--=========================================================
function QiXi_JiaShu_PreLoad()
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
function QiXi_JiaShu_OnLoad()
	g_QiXi_JiaShu_Frame_UnifiedPosition = QiXi_JiaShu_Frame:GetProperty("UnifiedPosition")

	-- QiXi_JiaShu_OK_Button : SetEvent("Clicked", "QiXi_JiaShu_ConfirmClick()")

	g_tCPageBk[1] = QiXi_JiaShu_BK1
	g_tCPageBk[2] = QiXi_JiaShu_BK2
	g_tCPageBk[3] = QiXi_JiaShu_BK3
	g_tCPageBk[4] = QiXi_JiaShu_BK4
	g_tCPageBk[5] = QiXi_JiaShu_BK5

end

--=========================================================
-- OnEvent
--=========================================================
function QiXi_JiaShu_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				QiXi_JiaShu_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						QiXi_JiaShu_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_QiXi_JiaShu()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	QiXi_JiaShu_OnClose()
			-- end
			QiXi_JiaShu_Reset()
			QiXi_JiaShu_Frame_On_ResetPos()
			this:Show()
			QiXi_JiaShu_ParamInit()
			QiXi_JiaShu_MoneyUpdate()
			QiXi_JiaShu_YuanBaoUpdate()
			QiXi_JiaShu_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						QiXi_JiaShu_OnClose()
					end
				end
			end
			if this:IsVisible() then
				QiXi_JiaShu_ParamInit()
				QiXi_JiaShu_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("QiXi_JiaShu_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
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
			QiXi_JiaShu_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			QiXi_JiaShu_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		QiXi_JiaShu_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		QiXi_JiaShu_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		QiXi_JiaShu_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		QiXi_JiaShu_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QiXi_JiaShu_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function QiXi_JiaShu_ParamInit()
	g_nUseItemId 	= Get_XParam_INT(1)
	g_nItemBagPos 	= Get_XParam_INT(2)
	g_nShowPage 	= Get_XParam_INT(3)
	-- 设置透明度
	-- QiXi_JiaShu_Frame : SetProperty("Alpha", 1)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function QiXi_JiaShu_OnComfirmedBack(strRet)
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
-- !!!reloadscript =QiXi_JiaShu
function QiXi_JiaShu_Update(bOpen)
	for i = 1, table.getn(g_tCPageBk) do
		if i == g_nShowPage then
			g_tCPageBk[i] : Show()
		else
			g_tCPageBk[i] : Hide()
		end	
	end
end

--=========================================================
-- 重置界面
--=========================================================
function QiXi_JiaShu_Reset()
	g_nUseItemId 	= -1
	g_nItemBagPos 	= -1
	g_nShowPage 	= 1
	QiXi_JiaShu_Frame : Tween_Reset("Alpha")
	KillTimer("QiXi_JiaShu_OnRealCloseTimer()")
end

--=========================================================
-- 界面确认按钮
--=========================================================
function QiXi_JiaShu_ClickClose()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnItemUseFromClient" )
		Set_XSCRIPT_ScriptID(791158)
		Set_XSCRIPT_Parameter(0, g_nItemBagPos)								
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	-- 淡入淡出
	-- 参数上应该是起始不透明度，目标不透明度，时间
	-- QiXi_JiaShu_Frame : StartFade(1, 0, g_nFadeLastTime)
	QiXi_JiaShu_Frame : Tween_SetInfo("Alpha", "curve:Liner mode:Once duration:3.0 startx:1 starty:0 endx:0 endy:0")
	QiXi_JiaShu_Frame : Tween_Play("Alpha", true, true)

	-- 定时关闭
	SetTimer("QiXi_JiaShu","QiXi_JiaShu_OnRealCloseTimer()", 1000 * g_nFadeLastTime)
end

--=========================================================
-- 定时关闭
--=========================================================
function QiXi_JiaShu_OnRealCloseTimer()
	KillTimer("QiXi_JiaShu_OnRealCloseTimer()")
	QiXi_JiaShu_OnClose()
end

--=========================================================
-- 关闭界面
--=========================================================
function QiXi_JiaShu_OnClose()	
	
	this:Hide()
	StopCareObject_QiXi_JiaShu()
	-- 重置
	QiXi_JiaShu_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="QiXi_JiaShu_OnHidden();" />
--=========================================================
function QiXi_JiaShu_OnHidden()
	StopCareObject_QiXi_JiaShu()
	-- 重置
	QiXi_JiaShu_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_QiXi_JiaShu()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "QiXi_JiaShu")
end

function StopCareObject_QiXi_JiaShu()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "QiXi_JiaShu")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function QiXi_JiaShu_MoneyUpdate()
	-- QiXi_JiaShu_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- QiXi_JiaShu_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function QiXi_JiaShu_YuanBaoUpdate()
	-- QiXi_JiaShu_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function QiXi_JiaShu_Frame_On_ResetPos()
	QiXi_JiaShu_Frame:SetProperty("UnifiedPosition", g_QiXi_JiaShu_Frame_UnifiedPosition)
end