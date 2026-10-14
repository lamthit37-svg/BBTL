--新的二次确认框
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

--二次确认框打开类型 类型不能重复 对应的数据
--标题名字 描述 确认按钮名字 取消按钮名字
--如果没有自己点击函数可以指定为nil 则使用默认的点击 
--所有点击函数执行完后 会由默认点击自动进行界面关闭
local m_ConfirmData = {}
--二次确认类型
local ConfirmType = 
{
	TEST_CONFIRM="TestConfirm",--测试用例
	TEST_CONFIRM1="TestConfirm1",--测试用例
	SHSHOP_BUY_ITEM_CONFIRM = "SHSHOP_BUY_ITEM_CONFIRM",
	XKDITEMGIFTUSE = "XKDItemGiftUse",--侠客到道具礼包使用
	XKDITEMGIFTUSE_LASTLIHE = "XKDItemGiftUseLiHe",--侠客到道具礼包使用最终礼盒
}
local m_curConfirmType = ""

--接受到的一些参数
local g_msgFrameVar = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function GuiShi_MessageSelf2_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("GUISHI_OPEN_MESSAGE_SELE2")
	this:RegisterEvent("SHSHOP_BUY_ITEM_CONFIRM")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function GuiShi_MessageSelf2_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= GuiShi_MessageSelf2_Window:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedXPosition	= GuiShi_MessageSelf2_Window:GetProperty("UnifiedYPosition");
	--注册二次确认事件 --如果 OKStr CancelStr 为 "" 测隐藏该按钮
	m_ConfirmData[ConfirmType.TEST_CONFIRM] = {Desc="#{GSDG_190729_111}", OKStr="#{GSDG_190729_113}", CancelStr="#{GSDG_190729_114}", 
		ClickOkExeFunc = GuiShi_MessageSelf2_OK_TestConfirm, ClickCancelExeFunc = GuiShi_MessageSelf2_Cancel_TestConfirm} --测试用例
	m_ConfirmData[ConfirmType.TEST_CONFIRM1] = {Desc="#{GSDG_190729_111}", OKStr="#{GSDG_190729_113}", CancelStr="#{GSDG_190729_114}", 
		ClickOkExeFunc = GuiShi_MessageSelf2_OK_TestConfirm, ClickCancelExeFunc = nil} --测试用例1
	m_ConfirmData["Confirm_OnlyText"] = {Desc="", OKStr="#{GSQL_190731_98}", CancelStr="", ClickOkExeFunc = nil, ClickCancelExeFunc = nil} --鬼市青楼红颜刷新提示
	m_ConfirmData[ConfirmType.SHSHOP_BUY_ITEM_CONFIRM] = {Desc = nil, OKStr = nil, CancelStr = nil, 
		ClickOkExeFunc = GuiShi_MessageSelf2_OK_SHShop_Buy, ClickCancelExeFunc = GuiShi_MessageSelf2_OK_SHShop_Buy_Cancel} --观山海商店兑换
	m_ConfirmData[ConfirmType.XKDITEMGIFTUSE] = {Desc = nil, OKStr = "#{XKKCGS_220112_272}", CancelStr = "#{XKKCGS_220112_273}", 
			ClickOkExeFunc = GuiShi_MessageSelf2_OK_XKDItemGiftUse, ClickCancelExeFunc = nil} --侠客到道具礼包使用
	m_ConfirmData[ConfirmType.XKDITEMGIFTUSE_LASTLIHE] = {Desc = nil, OKStr = "#{XKKCGS_220112_272}", CancelStr = "#{XKKCGS_220112_273}", 
			ClickOkExeFunc = GuiShi_MessageSelf2_OK_XKDItemGiftUseLiHe, ClickCancelExeFunc = nil} --侠客到道具礼包使用
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function GuiShi_MessageSelf2_ResetPos()
	GuiShi_MessageSelf2_Window:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	GuiShi_MessageSelf2_Window:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function GuiShi_MessageSelf2_OnEvent(event)
	--增加一部分通用的响应接口 不够用的话，自己可以扩充
	if event == "UI_COMMAND" and tonumber(arg0) == 89319490 then --通用接口1
		m_curConfirmType = Get_XParam_STR(0) --二次确认窗口打开类型 上面自己定义 不能重复
		g_msgFrameVar[0] = Get_XParam_INT(0) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = Get_XParam_INT(1)
		g_msgFrameVar[2] = Get_XParam_INT(2)
		g_msgFrameVar[3] = Get_XParam_INT(3)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local desc = m_ConfirmData[m_curConfirmType].Desc
			local okStr = m_ConfirmData[m_curConfirmType].OKStr
			local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr
			GuiShi_MessageSelf2_Update(desc, okStr, cancelStr)
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89319491 then --通用接口3
		m_curConfirmType = Get_XParam_STR(0) --二次确认窗口打开类型 上面自己定义 不能重复
		local desc = Get_XParam_STR(1) --内容
		g_msgFrameVar[0] = Get_XParam_INT(0) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = Get_XParam_INT(1)
		g_msgFrameVar[2] = Get_XParam_INT(2)
		g_msgFrameVar[3] = Get_XParam_INT(3)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local okStr = m_ConfirmData[m_curConfirmType].OKStr
			local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr
			GuiShi_MessageSelf2_Update(desc, okStr, cancelStr)
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89319492 then --通用接口2
		m_curConfirmType = Get_XParam_STR(0) --二次确认窗口打开类型 上面自己定义 不能重复
		local desc = Get_XParam_STR(1) --内容
		local okStr = Get_XParam_STR(2) --确认按钮内容
		local cancelStr = Get_XParam_STR(3) --取消按钮内容
		g_msgFrameVar[0] = Get_XParam_INT(0) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = Get_XParam_INT(1)
		g_msgFrameVar[2] = Get_XParam_INT(2)
		g_msgFrameVar[3] = Get_XParam_INT(3)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			GuiShi_MessageSelf2_Update(desc, okStr, cancelStr)
		end
	elseif event == "GUISHI_OPEN_MESSAGE_SELE2" and tostring(arg0) == "COMMON1" then --通用接口1 客户端用
		m_curConfirmType = tostring(arg1) --二次确认窗口打开类型 上面自己定义 不能重复
		g_msgFrameVar[0] = tonumber(arg2) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = tonumber(arg3)
		g_msgFrameVar[2] = tonumber(arg4)
		g_msgFrameVar[3] = tonumber(arg5)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local desc = m_ConfirmData[m_curConfirmType].Desc
			local okStr = m_ConfirmData[m_curConfirmType].OKStr
			local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr
			GuiShi_MessageSelf2_Update(desc, okStr, cancelStr)
		end
	elseif event == "GUISHI_OPEN_MESSAGE_SELE2" and tostring(arg0) == "COMMON2" then --通用接口1 客户端用
		m_curConfirmType = tostring(arg1) --二次确认窗口打开类型 上面自己定义 不能重复
		local desc = tostring(arg2) --内容
		g_msgFrameVar[0] = tonumber(arg3) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = tonumber(arg4)
		g_msgFrameVar[2] = tonumber(arg5)
		g_msgFrameVar[3] = tonumber(arg6)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local okStr = m_ConfirmData[m_curConfirmType].OKStr
			local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr
			GuiShi_MessageSelf2_Update(desc, okStr, cancelStr)
		end
	elseif event == "GUISHI_OPEN_MESSAGE_SELE2" and tostring(arg0) == "COMMON3" then --通用接口1 客户端用
		m_curConfirmType = tostring(arg1) --二次确认窗口打开类型 上面自己定义 不能重复
		local desc = tostring(arg2) --内容
		local okStr = tostring(arg3) --确认按钮内容
		local cancelStr = tostring(arg4) --取消按钮内容
		g_msgFrameVar[0] = tonumber(arg5) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = tonumber(arg6)
		g_msgFrameVar[2] = tonumber(arg7)
		g_msgFrameVar[3] = tonumber(arg8)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			GuiShi_MessageSelf2_Update(desc, okStr, cancelStr)
		end	
	elseif event == "SHSHOP_BUY_ITEM_CONFIRM" then
		m_curConfirmType = "SHSHOP_BUY_ITEM_CONFIRM"
		g_msgFrameVar[1] = tostring(arg0) 	--商品名称
		g_msgFrameVar[2] = tonumber(arg1) 	--商品位置	
		g_msgFrameVar[3] = tonumber(arg2) 	--商品售价
		g_msgFrameVar[4] = tonumber(arg3)	--商品数量
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local desc = ScriptGlobal_Format("#{XDBS_200417_29}", tostring(g_msgFrameVar[3]), "#{XDBS_200417_34}", tostring(g_msgFrameVar[4]), tostring(g_msgFrameVar[1]))
			GuiShi_MessageSelf2_Update(desc, "#{GSPM_190729_43}", "#{GSPM_190729_44}")
			DataPool:SetCanUseHotKey(0)
			if IsWindowShow("NewDungeon_DaibiShop_MBuy") then
				CloseWindow("NewDungeon_DaibiShop_MBuy", true)
			end
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		GuiShi_MessageSelf2_Hide()
	elseif event == "ADJEST_UI_POS" then
		GuiShi_MessageSelf2_ResetPos()
	end
end
--显示UI
function GuiShi_MessageSelf2_Show()
	this:Show()
	
end
--隐藏UI
function GuiShi_MessageSelf2_Hide()
	m_curConfirmType = ""
	this:Hide()
end

function GuiShi_MessageSelf2_Update(desc, okStr, cancelStr)
	GuiShi_MessageSelf2_Text:SetText(desc)
	if nil == okStr or okStr == "" then
		GuiShi_MessageSelf2_OK_Button:Hide()
	else
		GuiShi_MessageSelf2_OK_Button:Show()
		GuiShi_MessageSelf2_OK_Button:SetText(okStr)
	end
	if  nil == cancelStr or cancelStr == "" then
		GuiShi_MessageSelf2_Cancel_Button:Hide()
	else
		GuiShi_MessageSelf2_Cancel_Button:Show()
		GuiShi_MessageSelf2_Cancel_Button:SetText(cancelStr)
	end
	GuiShi_MessageSelf2_UpdateRect()
	GuiShi_MessageSelf2_Show()
end
function GuiShi_MessageSelf2_UpdateRect()
	local nWidth, nHeight = GuiShi_MessageSelf2_Text:GetWindowSize();
	local nTitleHeight = 23;
	local nBottomHeight = 25;
	local nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	GuiShi_MessageSelf2_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end

--##############点击事件##############
function GuiShi_MessageSelf2_Frame_OnHiden()
	if nil ~= m_ConfirmData[m_curConfirmType] and 
		nil ~= m_ConfirmData[m_curConfirmType].ClickCancelExeFunc then
		m_ConfirmData[m_curConfirmType].ClickCancelExeFunc()
	end
	GuiShi_MessageSelf2_Hide()
end
function GuiShi_MessageSelf2_Ok_Clicked()
	if nil ~= m_ConfirmData[m_curConfirmType] and 
		nil ~= m_ConfirmData[m_curConfirmType].ClickOkExeFunc then
		m_ConfirmData[m_curConfirmType].ClickOkExeFunc()
	end
	GuiShi_MessageSelf2_Hide()
end
function GuiShi_MessageSelf2_Cancel_Clicked()
	if nil ~= m_ConfirmData[m_curConfirmType] and 
		nil ~= m_ConfirmData[m_curConfirmType].ClickCancelExeFunc then
		m_ConfirmData[m_curConfirmType].ClickCancelExeFunc()
	end
	GuiShi_MessageSelf2_Hide()

end
--####################################

--####################扩展点击函数##########
--测试用例的点击和取消
function GuiShi_MessageSelf2_OK_TestConfirm()
	PushDebugMessage("GuiShi_MessageSelf2_OK_TestConfirm")
end
function GuiShi_MessageSelf2_Cancel_TestConfirm()
	PushDebugMessage("GuiShi_MessageSelf2_Cancel_TestConfirm")
end

-- 鬼市确认基本状态
function GuiShi_MessageSelf2_IsNormalStatus()
	-- 安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return false
	end
	
	-- 电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then
		return false
	end

	-- 全沉迷或半沉迷状态
	if IsInFatigueState() <= 0 then
		PushDebugMessage("#{FCMX_90619_04}")
		return  false
	end
	return true
end

-- 鬼市拍卖行二次确认
function GuiShi_MessageSelf2_Market_Confirm(opstr,desc,param1,param2,param3,param4,param5)
	g_msgFrameVar[0] = tonumber(param1) --扩展参数 用几个传几个的值就行
	g_msgFrameVar[1] = tonumber(param2)
	g_msgFrameVar[2] = tonumber(param3)
	g_msgFrameVar[3] = tonumber(param4)
	g_msgFrameVar[4] = tonumber(param5)
	m_curConfirmType = tostring(opstr)
	if nil ~= m_ConfirmData[m_curConfirmType] then
		local title = m_ConfirmData[m_curConfirmType].Title
		local okStr = m_ConfirmData[m_curConfirmType].OKStr
		local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr
		GuiShi_MessageSelf2_Update(desc, okStr, cancelStr)
	end
end
--######################################

function GuiShi_MessageSelf2_OK_SHShop_Buy()
	NpcShop:BulkBuyItem(g_msgFrameVar[2], 1, 0)
	DataPool:SetCanUseHotKey(1)
end

function GuiShi_MessageSelf2_OK_SHShop_Buy_Cancel()
	DataPool:SetCanUseHotKey(1)
end

-- 侠客岛道具礼包使用
function GuiShi_MessageSelf2_OK_XKDItemGiftUse()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnItemUse");
		Set_XSCRIPT_ScriptID(888943);
		Set_XSCRIPT_Parameter(0, tonumber(g_msgFrameVar[0]));
		Set_XSCRIPT_Parameter(1, tonumber(g_msgFrameVar[1]));
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end

-- 侠客岛道具礼包使用
function GuiShi_MessageSelf2_OK_XKDItemGiftUseLiHe()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnItemUse");
		Set_XSCRIPT_ScriptID(893460);
		Set_XSCRIPT_Parameter(0, tonumber(g_msgFrameVar[0]));
		Set_XSCRIPT_Parameter(1, tonumber(g_msgFrameVar[1]));
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end
--######################################