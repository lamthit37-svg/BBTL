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
function GuiShi_MessageSelf_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("GUISHI_OPEN_MESSAGE_SELE")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("GUISHI_SELL_RECONFIRM")
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function GuiShi_MessageSelf_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= GuiShi_MessageSelf_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedXPosition	= GuiShi_MessageSelf_Frame:GetProperty("UnifiedYPosition");
	--注册二次确认事件
	m_ConfirmData[ConfirmType.TEST_CONFIRM] = {Title="#{GSDG_190729_112}", Desc="#{GSDG_190729_111}", OKStr="#{GSDG_190729_113}", CancelStr="#{GSDG_190729_114}", 
		ClickOkExeFunc = GuiShi_MessageSelf_OK_TestConfirm, ClickCancelExeFunc = GuiShi_MessageSelf_Cancel_TestConfirm} --测试用例
	m_ConfirmData[ConfirmType.TEST_CONFIRM1] = {Title="#{GSDG_190729_112}", Desc="#{GSDG_190729_111}", OKStr="#{GSDG_190729_113}", CancelStr="#{GSDG_190729_114}", 
		ClickOkExeFunc = GuiShi_MessageSelf_OK_TestConfirm, ClickCancelExeFunc = nil} --测试用例1
	m_ConfirmData["89319001"] = {Title="#{GSHB_190801_100}", Desc="", OKStr="#{GSQL_190731_21}", CancelStr="#{GSQL_190731_20}", isCareObject=1,
		ClickOkExeFunc = GuiShi_MessageSelf_OK_89319001, ClickCancelExeFunc = nil}
	m_ConfirmData["89319002"] = {Title="#{GSHB_190801_102}", Desc="", OKStr="#{GSQL_190731_21}", CancelStr="#{GSQL_190731_20}", isCareObject=1,
		ClickOkExeFunc = GuiShi_MessageSelf_OK_89319002, ClickCancelExeFunc = nil}
	m_ConfirmData["89319003"] = {Title="#{GSHB_190801_101}", Desc="", OKStr="#{GSQL_190731_21}", CancelStr="#{GSQL_190731_20}", isCareObject=1,
		ClickOkExeFunc = GuiShi_MessageSelf_OK_89319003, ClickCancelExeFunc = nil}
	m_ConfirmData["40212901"] = {Title="#{GSCX_190727_439}", Desc="", OKStr="#{GSCX_190727_35}", CancelStr="#{GSCX_190727_36}", isCareObject=1,
		ClickOkExeFunc = GuiShi_MessageSelf_OK_40212901, ClickCancelExeFunc = nil}	--鬼市-产销-兑换重楼
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function GuiShi_MessageSelf_ResetPos()
	GuiShi_MessageSelf_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	GuiShi_MessageSelf_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function GuiShi_MessageSelf_OnEvent(event)
	--增加一部分通用的响应接口 不够用的话，自己可以扩充
	if event == "UI_COMMAND" and tonumber(arg0) == 89319480 then --通用接口1
		m_curConfirmType = Get_XParam_STR(0) --二次确认窗口打开类型 上面自己定义 不能重复
		g_msgFrameVar[0] = Get_XParam_INT(0) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = Get_XParam_INT(1)
		g_msgFrameVar[2] = Get_XParam_INT(2)
		g_msgFrameVar[3] = Get_XParam_INT(3)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local title = m_ConfirmData[m_curConfirmType].Title
			local desc = m_ConfirmData[m_curConfirmType].Desc
			local okStr = m_ConfirmData[m_curConfirmType].OKStr
			local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr
			if m_ConfirmData[m_curConfirmType].isCareObject ~= nil and m_ConfirmData[m_curConfirmType].isCareObject == 1 then
				objCared = DataPool : GetNPCIDByServerID(g_msgFrameVar[0])
				this:CareObject(objCared, 1, "GuiShi_MessageSelf"); 
			end
			GuiShi_MessageSelf_Update(title, desc, okStr, cancelStr)
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89319481 then --通用接口2
		m_curConfirmType = Get_XParam_STR(0) --二次确认窗口打开类型 上面自己定义 不能重复
		local desc = Get_XParam_STR(1) --内容
		g_msgFrameVar[0] = Get_XParam_INT(0) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = Get_XParam_INT(1)
		g_msgFrameVar[2] = Get_XParam_INT(2)
		g_msgFrameVar[3] = Get_XParam_INT(3)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local title = m_ConfirmData[m_curConfirmType].Title
			local okStr = m_ConfirmData[m_curConfirmType].OKStr
			local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr
			if m_ConfirmData[m_curConfirmType].isCareObject ~= nil and m_ConfirmData[m_curConfirmType].isCareObject == 1 then
				objCared = DataPool : GetNPCIDByServerID(g_msgFrameVar[0])
				this:CareObject(objCared, 1, "GuiShi_MessageSelf"); 
			end
			
			GuiShi_MessageSelf_Update(title, desc, okStr, cancelStr)
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 89319482 then --通用接口3
		m_curConfirmType = Get_XParam_STR(0) --二次确认窗口打开类型 上面自己定义 不能重复
		local title = Get_XParam_STR(1) --标题
		local desc = Get_XParam_STR(2) --内容
		local okStr = Get_XParam_STR(3) --确认按钮内容
		local cancelStr = Get_XParam_STR(4) --取消按钮内容
		g_msgFrameVar[0] = Get_XParam_INT(0) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = Get_XParam_INT(1)
		g_msgFrameVar[2] = Get_XParam_INT(2)
		g_msgFrameVar[3] = Get_XParam_INT(3)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			if m_ConfirmData[m_curConfirmType].isCareObject ~= nil and m_ConfirmData[m_curConfirmType].isCareObject == 1 then
				objCared = DataPool : GetNPCIDByServerID(g_msgFrameVar[0])				
				this:CareObject(objCared, 1, "GuiShi_MessageSelf"); 
			end
			GuiShi_MessageSelf_Update(title, desc, okStr, cancelStr)
		end
	elseif event == "GUISHI_OPEN_MESSAGE_SELE" and tostring(arg0) == "COMMON1" then --通用接口1 客户端用
		m_curConfirmType = tostring(arg1) --二次确认窗口打开类型 上面自己定义 不能重复
		g_msgFrameVar[0] = tonumber(arg2) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = tonumber(arg3)
		g_msgFrameVar[2] = tonumber(arg4)
		g_msgFrameVar[3] = tonumber(arg5)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local title = m_ConfirmData[m_curConfirmType].Title
			local desc = m_ConfirmData[m_curConfirmType].Desc
			local okStr = m_ConfirmData[m_curConfirmType].OKStr
			local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr
			GuiShi_MessageSelf_Update(title, desc, okStr, cancelStr)
		end
	elseif event == "GUISHI_OPEN_MESSAGE_SELE" and tostring(arg0) == "COMMON2" then --通用接口1 客户端用
		m_curConfirmType = tostring(arg1) --二次确认窗口打开类型 上面自己定义 不能重复
		local desc = tostring(arg2) --内容
		g_msgFrameVar[0] = tonumber(arg3) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = tonumber(arg4)
		g_msgFrameVar[2] = tonumber(arg5)
		g_msgFrameVar[3] = tonumber(arg6)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local title = m_ConfirmData[m_curConfirmType].Title
			local okStr = m_ConfirmData[m_curConfirmType].OKStr
			local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr
			GuiShi_MessageSelf_Update(title, desc, okStr, cancelStr)
		end
	elseif event == "GUISHI_OPEN_MESSAGE_SELE" and tostring(arg0) == "COMMON3" then --通用接口1 客户端用
		m_curConfirmType = tostring(arg1) --二次确认窗口打开类型 上面自己定义 不能重复
		local title = tostring(arg2) --标题
		local desc = tostring(arg3) --内容
		local okStr = tostring(arg4) --确认按钮内容
		local cancelStr = tostring(arg5) --取消按钮内容
		g_msgFrameVar[0] = tonumber(arg6) --扩展参数 用几个传几个的值就行
		g_msgFrameVar[1] = tonumber(arg7)
		g_msgFrameVar[2] = tonumber(arg8)
		g_msgFrameVar[3] = tonumber(arg9)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			GuiShi_MessageSelf_Update(title, desc, okStr, cancelStr)
		end
		
	elseif event == "GUISHI_SELL_RECONFIRM" then
		m_curConfirmType = tostring(arg0)
		local desc = tostring(arg1) --内容
		local npcId = tonumber(arg2) --扩展参数 用几个传几个的值就行
		this:CareObject(npcId, 1, "GuiShi_MessageSelf"); 
		
		g_msgFrameVar[0] = tonumber(arg3)
		if nil ~= m_ConfirmData[m_curConfirmType] then
			local title = m_ConfirmData[m_curConfirmType].Title
			local okStr = m_ConfirmData[m_curConfirmType].OKStr
			local cancelStr = m_ConfirmData[m_curConfirmType].CancelStr		
			GuiShi_MessageSelf_Update(title, desc, okStr, cancelStr)
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		GuiShi_MessageSelf_Hide()
	elseif event == "ADJEST_UI_POS" then
		GuiShi_MessageSelf_ResetPos()
	end
end
--显示UI
function GuiShi_MessageSelf_Show()
	this:Show()
	
end
--隐藏UI
function GuiShi_MessageSelf_Hide()
	m_curConfirmType = ""
	this:Hide()
end

function GuiShi_MessageSelf_Update(title, desc, okStr, cancelStr)
	GuiShi_MessageSelf_DragTitle:SetText(title)
	GuiShi_MessageSelf_Text:SetText(desc)
	if nil == okStr or okStr == "" then
		GuiShi_MessageSelf_OK:Hide()
	else
		GuiShi_MessageSelf_OK:Show()
		GuiShi_MessageSelf_OK:SetText(okStr)
	end
	if nil == cancelStr or cancelStr == "" then
		GuiShi_MessageSelf_Cancel:Hide()
	else
		GuiShi_MessageSelf_Cancel:Show()
		GuiShi_MessageSelf_Cancel:SetText(cancelStr)
	end
	GuiShi_MessageSelf_UpdateRect()
	GuiShi_MessageSelf_Show()
end
function  GuiShi_MessageSelf_UpdateRect()
	local nWidth, nHeight = GuiShi_MessageSelf_Text:GetWindowSize();
	local nTitleHeight = 36;
	local nBottomHeight = 75;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	GuiShi_MessageSelf_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );

end

--##############点击事件##############
function GuiShi_MessageSelf_ClickClose()
	if nil ~= m_ConfirmData[m_curConfirmType] and 
		nil ~= m_ConfirmData[m_curConfirmType].ClickCancelExeFunc then
		m_ConfirmData[m_curConfirmType].ClickCancelExeFunc()
	end
	GuiShi_MessageSelf_Hide()
end
function GuiShi_MessageSelf_OK_Clicked()
	if nil ~= m_ConfirmData[m_curConfirmType] and 
		nil ~= m_ConfirmData[m_curConfirmType].ClickOkExeFunc then
		m_ConfirmData[m_curConfirmType].ClickOkExeFunc()
	end
	GuiShi_MessageSelf_Hide()
end
function GuiShi_MessageSelf_Cancel_Clicked()
	if nil ~= m_ConfirmData[m_curConfirmType] and 
		nil ~= m_ConfirmData[m_curConfirmType].ClickCancelExeFunc then
		m_ConfirmData[m_curConfirmType].ClickCancelExeFunc()
	end
	GuiShi_MessageSelf_Hide()
	
end
--####################################

--####################扩展点击函数##########
--测试用例的点击和取消 TestConfirm
function GuiShi_MessageSelf_OK_TestConfirm()
	PushDebugMessage("GuiShi_MessageSelf_OK_TestConfirm"..g_msgFrameVar[0].." "..g_msgFrameVar[1].." "..g_msgFrameVar[2].. ""..g_msgFrameVar[3])
end
function GuiShi_MessageSelf_Cancel_TestConfirm()
	PushDebugMessage("GuiShi_MessageSelf_Cancel_TestConfirm"..g_msgFrameVar[0].." "..g_msgFrameVar[1].." "..g_msgFrameVar[2].. ""..g_msgFrameVar[3])
end


function GuiShi_MessageSelf_OK_89319001()
	PushEvent("GUISHI_ONBUY", -1, g_msgFrameVar[1], 0, g_msgFrameVar[2], 0)
end

function GuiShi_MessageSelf_OK_89319002()
	PushEvent("GUISHI_ONREPO", g_msgFrameVar[1], 0)
end

function GuiShi_MessageSelf_OK_89319003()
	PushEvent("GUISHI_SELL", g_msgFrameVar[0])
end

--鬼市-产销-兑换重楼
function GuiShi_MessageSelf_OK_40212901()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnExchangeChongLou")
		Set_XSCRIPT_ScriptID(402129)
		Set_XSCRIPT_Parameter(0, g_msgFrameVar[0])
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

-- 鬼市确认基本状态
function GuiShi_MessageSelf_IsNormalStatus()
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

--######################################
