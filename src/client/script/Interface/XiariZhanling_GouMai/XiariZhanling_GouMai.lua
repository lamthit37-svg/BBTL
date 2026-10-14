-- XiariZhanling_GouMai 夏日拉收战令 lishilong
-- !!!reloadscript =XiariZhanling_GouMai
--

local g_XiariZhanling_GouMai_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 1
local g_nComfirmParam1		= 0

local g_nCanBuyNumMax		= 1
local g_nCurSetBuyNum		= 1
local g_nCostYBPerNum		= 50
local g_bInClickCD			= 0
-- 点击cd 2s
local g_nCDLast				= 2000

local g_nUICommandID		= 79115002
local g_nMainScriptID		= 791150

--=========================================================
-- PreLoad
--=========================================================
function XiariZhanling_GouMai_PreLoad()
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
function XiariZhanling_GouMai_OnLoad()
	g_XiariZhanling_GouMai_Frame_UnifiedPosition = XiariZhanling_GouMai_Frame:GetProperty("UnifiedPosition")

	-- XiariZhanling_GouMai_OK_Button : SetEvent("Clicked", "XiariZhanling_GouMai_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function XiariZhanling_GouMai_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				XiariZhanling_GouMai_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						XiariZhanling_GouMai_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_XiariZhanling_GouMai()
			end

			-- 显示界面
			-- 实现刷新
			-- if this:IsVisible() then
			-- 	XiariZhanling_GouMai_OnClose()
			-- end
			XiariZhanling_GouMai_Reset()
			XiariZhanling_GouMai_Frame_On_ResetPos()
			this:Show()
			XiariZhanling_GouMai_ParamInit()
			XiariZhanling_GouMai_MoneyUpdate()
			XiariZhanling_GouMai_YuanBaoUpdate()
			XiariZhanling_GouMai_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						XiariZhanling_GouMai_OnClose()
					end
				end
			end
			if this:IsVisible() then
				XiariZhanling_GouMai_ParamInit()
				XiariZhanling_GouMai_Update(0)
			end
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
			XiariZhanling_GouMai_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			XiariZhanling_GouMai_Update(0)
		end

	-- 金钱改变
	elseif (event == "UNIT_MONEY" or event == "MONEYJZ_CHANGE") and 1 == bCaredMoney then
		XiariZhanling_GouMai_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		XiariZhanling_GouMai_YuanBaoUpdate()
	-- elseif event == "UPDATE_BIND_YUANBAO" and 1 == bCaredYuanBao then
	-- 	XiariZhanling_GouMai_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		XiariZhanling_GouMai_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		XiariZhanling_GouMai_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiariZhanling_GouMai_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function XiariZhanling_GouMai_ParamInit()
	g_nCanBuyNumMax = Get_XParam_INT(1)
	g_nCostYBPerNum = Get_XParam_INT(2)
	XiariZhanling_GouMai_Moral_Value : SetText(g_nCurSetBuyNum)
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =XiariZhanling_GouMai
function XiariZhanling_GouMai_Update(bOpen)

	-- XiariZhanling_GouMai_Moral_Value : SetProperty("DefaultEditBox", "True")
	-- XiariZhanling_GouMai_Moral_Value : SetSelected(0, -1)

	XiariZhanling_GouMai_Text3YB : SetText ( ScriptGlobal_Format("#{XRZL_250508_88}", g_nCostYBPerNum * g_nCurSetBuyNum) )
end

--=========================================================
-- 修改购买量
--=========================================================
function XiariZhanling_GouMai_Count_Change()
	local strCurSetNum = XiariZhanling_GouMai_Moral_Value : GetText()

	-- 修正逻辑
	if nil == strCurSetNum or "" == strCurSetNum then
		g_nCurSetBuyNum = 0
		XiariZhanling_GouMai_Text3YB : SetText ( ScriptGlobal_Format("#{XRZL_250508_88}", 0) )
		-- XiariZhanling_GouMai_Moral_Value : SetText(g_nCurSetBuyNum)
		return
	end

	local nCurSetNum = tonumber(strCurSetNum)

	if nil == nCurSetNum then
		g_nCurSetBuyNum = 0
		XiariZhanling_GouMai_Text3YB : SetText ( ScriptGlobal_Format("#{XRZL_250508_88}", 0) )
		-- XiariZhanling_GouMai_Moral_Value : SetText(g_nCurSetBuyNum)
		return
	end

	-- 小于0时
	if nCurSetNum <= 0 then
		g_nCurSetBuyNum = 1
		XiariZhanling_GouMai_Moral_Value : SetText(g_nCurSetBuyNum)
		return
	end
	
	-- 大于最大使用数量
	if nCurSetNum > g_nCanBuyNumMax then
		g_nCurSetBuyNum = g_nCanBuyNumMax
		XiariZhanling_GouMai_Moral_Value : SetText(g_nCurSetBuyNum)
		return
	end

	-- 修正完成 正常逻辑
	g_nCurSetBuyNum = nCurSetNum
	XiariZhanling_GouMai_Text3YB : SetText ( ScriptGlobal_Format("#{XRZL_250508_88}", g_nCostYBPerNum * g_nCurSetBuyNum) )
end

--=========================================================
-- 最大购买量
--=========================================================
function XiariZhanling_GouMai_Max_Clicked()
	XiariZhanling_GouMai_Moral_Value : SetText(g_nCanBuyNumMax)
end

--=========================================================
-- 取消
--=========================================================
function XiariZhanling_GouMai_Cancel_Clicked()
	XiariZhanling_GouMai_OnClose()	
end

--=========================================================
-- 重置界面
--=========================================================
function XiariZhanling_GouMai_Reset()
	g_nCurSetBuyNum = 1
	XiariZhanling_GouMai_Moral_Value : SetText("")
end

--=========================================================
-- 界面确认按钮
--=========================================================
function XiariZhanling_GouMai_OK_Clicked()

	-- 点击cd
	if 1 == g_bInClickCD then
		PushDebugMessage("#{XRZL_250508_26}")
		return
	end

	g_bInClickCD = 1
	KillTimer("XiariZhanling_GouMai_OnTimerEnd()");	
	SetTimer("XiariZhanling_GouMai","XiariZhanling_GouMai_OnTimerEnd()", g_nCDLast)

	if nil == g_nCurSetBuyNum or g_nCurSetBuyNum < 1 then
		PushDebugMessage("#{XRZL_250508_27}")
		return
	end

	-- 1 请求打开购买经验界面
	-- 2 请求解锁高级战令
	-- 3 请求领奖
	-- 4 请求购买外观 1-4
	-- 5 请求购买点数
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUIEvent") 
		Set_XSCRIPT_ScriptID(g_nMainScriptID)
		Set_XSCRIPT_Parameter(0,5)
		Set_XSCRIPT_Parameter(1,g_nCurSetBuyNum)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_Parameter(3,0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 计时器
--=========================================================
function XiariZhanling_GouMai_OnTimerEnd()	
	g_bInClickCD = 0
end

--=========================================================
-- 关闭界面
--=========================================================
function XiariZhanling_GouMai_OnClose()	
	this:Hide()
	StopCareObject_XiariZhanling_GouMai()
	-- 重置
	XiariZhanling_GouMai_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="XiariZhanling_GouMai_OnHidden();" />
--=========================================================
function XiariZhanling_GouMai_OnHidden()
	StopCareObject_XiariZhanling_GouMai()
	-- 重置
	XiariZhanling_GouMai_Reset()

	-- 关掉关联界面
	-- if IsWindowShow("XiariZhanling") then
	-- 	CloseWindow("XiariZhanling", true);
	-- end
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_XiariZhanling_GouMai()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "XiariZhanling_GouMai")
end

function StopCareObject_XiariZhanling_GouMai()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "XiariZhanling_GouMai")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function XiariZhanling_GouMai_MoneyUpdate()
	-- XiariZhanling_GouMai_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- XiariZhanling_GouMai_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function XiariZhanling_GouMai_YuanBaoUpdate()
	XiariZhanling_GouMai_Text1YB : SetText (ScriptGlobal_Format("#{XRZL_250508_88}", Player:GetData("YUANBAO")))
	-- XiariZhanling_GouMai_Text1YB : SetText (ScriptGlobal_Format("#{XRZL_250508_88}", Player:GetData("BIND_YUANBAO")) )
end

--=========================================================
-- 界面位置
--=========================================================
function XiariZhanling_GouMai_Frame_On_ResetPos()
	XiariZhanling_GouMai_Frame:SetProperty("UnifiedPosition", g_XiariZhanling_GouMai_Frame_UnifiedPosition)
end