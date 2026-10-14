-- SiXiangTu_XunBao 四象图 寻宝界面 2020-8-3 lishilong
-- !!!reloadscript =SiXiangTu_XunBao
--

local g_SiXiangTu_XunBao_Frame_UnifiedPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0

local g_nMainUICommandID	= 79005101
local g_nShowUICommandID	= 79005002

-- 坐标Index
local g_nPosIndex			= 0
local g_nMaxIndex			= 20
-- 展示控件
local g_controlShow = {}

--=========================================================
-- PreLoad
--=========================================================
function SiXiangTu_XunBao_PreLoad()
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
function SiXiangTu_XunBao_OnLoad()
	g_SiXiangTu_XunBao_Frame_UnifiedPosition = SiXiangTu_XunBao_Frame:GetProperty("UnifiedPosition")

	-- SiXiangTu_XunBao_OK_Button : SetEvent("Clicked", "SiXiangTu_XunBao_ConfirmClick()")

	g_controlShow[1] 	= SiXiangTu_XunBao_Client1
	g_controlShow[2] 	= SiXiangTu_XunBao_Client2
	g_controlShow[3] 	= SiXiangTu_XunBao_Client3
	g_controlShow[4] 	= SiXiangTu_XunBao_Client4
	g_controlShow[5] 	= SiXiangTu_XunBao_Client5
	g_controlShow[6] 	= SiXiangTu_XunBao_Client6
	g_controlShow[7] 	= SiXiangTu_XunBao_Client7
	g_controlShow[8] 	= SiXiangTu_XunBao_Client8
	g_controlShow[9] 	= SiXiangTu_XunBao_Client9
	g_controlShow[10] 	= SiXiangTu_XunBao_Client10	
	g_controlShow[11] 	= SiXiangTu_XunBao_Client11
	g_controlShow[12] 	= SiXiangTu_XunBao_Client12
	g_controlShow[13] 	= SiXiangTu_XunBao_Client13
	g_controlShow[14] 	= SiXiangTu_XunBao_Client14
	g_controlShow[15] 	= SiXiangTu_XunBao_Client15
	g_controlShow[16] 	= SiXiangTu_XunBao_Client16
	g_controlShow[17] 	= SiXiangTu_XunBao_Client17
	g_controlShow[18] 	= SiXiangTu_XunBao_Client18
	g_controlShow[19] 	= SiXiangTu_XunBao_Client19
	g_controlShow[20] 	= SiXiangTu_XunBao_Client20
end

--=========================================================
-- OnEvent
--=========================================================
function SiXiangTu_XunBao_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nMainUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新, 3 二次确认框
		local nOpType 	= Get_XParam_INT(0)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				SiXiangTu_XunBao_OnClose()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SiXiangTu_XunBao_OnClose()
					end
				end
				g_nServerObjID = nServerObjID
				g_nObjCaredIDClient = DataPool : GetNPCIDByServerID(tonumber(nServerObjID))
				BeginCareObject_SiXiangTu_XunBao()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	SiXiangTu_XunBao_OnClose()
			-- end
			SiXiangTu_XunBao_Reset()
			SiXiangTu_XunBao_Frame_On_ResetPos()
			this:Show()
			SiXiangTu_XunBao_ParamInit()
			SiXiangTu_XunBao_MoneyUpdate()
			SiXiangTu_XunBao_YuanBaoUpdate()
			SiXiangTu_XunBao_Update(1)
		end
			
		-- 刷新界面
		if 2 == nOpType then
			-- 关注npc
			if 1 == bCaredObj then
				local nServerObjID 	= Get_XParam_INT(1)
				if nServerObjID == nil or nServerObjID < 0 then
					if this:IsVisible() then
						SiXiangTu_XunBao_OnClose()
					end
				end
			end
			if this:IsVisible() then
				SiXiangTu_XunBao_ParamInit()
				SiXiangTu_XunBao_Update(0)
			end
		end

		-- 二次确认框
		if 3 == nOpType then
			local strMsg = Get_XParam_STR(0)
			-- g_nComfirmParam1 = Get_XParam_INT(1)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("SiXiangTu_XunBao_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
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
			SiXiangTu_XunBao_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			SiXiangTu_XunBao_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		SiXiangTu_XunBao_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		SiXiangTu_XunBao_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		SiXiangTu_XunBao_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		SiXiangTu_XunBao_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SiXiangTu_XunBao_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function SiXiangTu_XunBao_ParamInit()
	g_nPosIndex = Get_XParam_INT(1)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function SiXiangTu_XunBao_OnComfirmedBack(strRet)
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
-- !!!reloadscript =SiXiangTu_XunBao
function SiXiangTu_XunBao_Update(bOpen)
	if g_nPosIndex < 0 or g_nPosIndex > g_nMaxIndex then
		return
	end

	if nil == g_controlShow[g_nPosIndex] then
		return
	end

	for i = 1, table.getn(g_controlShow) do
		if i == g_nPosIndex then
			g_controlShow[i] : Show()
		else
			g_controlShow[i] : Hide()
		end
	end
end

--=========================================================
-- 重置界面
--=========================================================
function SiXiangTu_XunBao_Reset()
	g_nPosIndex = 0
end

--=========================================================
-- 界面确认按钮
--=========================================================
function SiXiangTu_XunBao_ViewClick()
	PushEvent("UI_COMMAND", 79005002, 1 )
end

--=========================================================
-- 关闭界面
--=========================================================
function SiXiangTu_XunBao_OnClose()	
	this:Hide()
	StopCareObject_SiXiangTu_XunBao()
	-- 重置
	SiXiangTu_XunBao_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="SiXiangTu_XunBao_OnHiden();" />
--=========================================================
function SiXiangTu_XunBao_OnHiden()
	StopCareObject_SiXiangTu_XunBao()
	-- 重置
	SiXiangTu_XunBao_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_SiXiangTu_XunBao()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "SiXiangTu_XunBao")
end

function StopCareObject_SiXiangTu_XunBao()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "SiXiangTu_XunBao")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function SiXiangTu_XunBao_MoneyUpdate()
	-- SiXiangTu_XunBao_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- SiXiangTu_XunBao_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function SiXiangTu_XunBao_YuanBaoUpdate()
	-- SiXiangTu_XunBao_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function SiXiangTu_XunBao_Frame_On_ResetPos()
	SiXiangTu_XunBao_Frame:SetProperty("UnifiedPosition", g_SiXiangTu_XunBao_Frame_UnifiedPosition)
end