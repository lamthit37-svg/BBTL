--- 推荐服务器优化界面

local g_SelectBetterServer_Frame_UnifiedPosition
local g_showbuttonStr
local g_curArea = -1;
local g_curServer = -1;

--流畅服务器数据
local g_FlueServerList = {
	iServerCount = 0;				-- 记载服务器的个数
	strServerName = {};				-- 流畅服务器名字
	iServerIndex = {};				-- 流畅服务器Index
	iServerAreaIndex = {};			-- 流畅服务器区域Index
	iServerStatus = {};				-- 流畅服务器 状态
}
--要登陆的两个服务器
local g_LoginServer1 = {
	strServerName;				-- 流畅服务器名字
	iServerIndex;				-- 流畅服务器Index
	iServerAreaIndex;			-- 流畅服务器区域Index
	iServerStatus;				-- 流畅服务器 状态
}
local g_LoginServer2 = {
	strServerName;				-- 流畅服务器名字
	iServerIndex;				-- 流畅服务器Index
	iServerAreaIndex;			-- 流畅服务器区域Index
	iServerStatus;				-- 流畅服务器 状态
}

local g_tempServerTable = {}
local g_StateFull = 0 	--!< 爆满
local g_StateStop = 4 	--!< 维护
local g_StateNotShow = 10	--不显示
local g_showbuttonStr = nil
local g_iNetProvide = -1;		-- 0 : 电信
								-- 1 : 网通
								-- 2 : 其他
								-- 3：默认
								-- 4：网通青岛
local g_AllNetProvide = {0,1,4,2,3}
local g_IsShow = 1

function SelectBetterServer_PreLoad()
	--打开推荐服务器界面，也就是本界面
	this:RegisterEvent("GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON");
	-- 选择是否使用代理
	this:RegisterEvent("GAMELOGIN_SELECT_USEPROXY")
	-- 关闭界面
	this:RegisterEvent("GAMELOGIN_CLOSE_COUNT_INPUT");
	--改变界面分辨率
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("GAMELOGIN_SHOW_QUEUEMSG_ASK_PHONE");
	this:RegisterEvent("OPEN_RECHECK_CLOSE_ALL_UI")
end

function SelectBetterServer_OnLoad()
	g_SelectBetterServer_Frame_UnifiedPosition = SelectBetterServer_Frame:GetProperty( "UnifiedPosition" )
end

-- OnEvent
function SelectBetterServer_OnEvent(event)
	if (event == "GAMELOGIN_SHOW_SYSTEM_INFO_NO_BUTTON") then
		if( nil ~= arg1 ) then
			local strArg = tostring( arg1 )
			if (strArg and strArg == "ShowButton") then
				g_showbuttonStr = arg0
				if(IsWindowShow("OtherQuest")) then
					return
				end
				g_curArea = tonumber(arg2)
				g_curServer = tonumber(arg3)
				SelectBetterServer_InfoWindow:SetText(tostring(arg0))
				SelectBetterServer_UpdateRect()
				if g_IsShow == 1 then
					--获取推荐流畅服务器
					SelectBetterServer_GetFlueServer()
					g_IsShow = 0
				end
				this:Show()
			end
		end
	elseif( event == "GAMELOGIN_SHOW_QUEUEMSG_ASK_PHONE") then
		this:Hide();
	elseif (event == "OPEN_RECHECK_CLOSE_ALL_UI" ) then
		this:Hide();
	-- 使用代理
	elseif( event == "GAMELOGIN_SELECT_USEPROXY" ) then
		if tonumber(arg0) == 0 then
			g_iNetProvide = 0
		elseif tonumber(arg0) == 1 then
			g_iNetProvide = 1
		elseif tonumber(arg0) == 2 then
			g_iNetProvide = 2
		elseif tonumber(arg0) == 3 then
			g_iNetProvide = 3
		elseif tonumber(arg0) == 4 then
			g_iNetProvide = 4
		end
	elseif( event == "GAMELOGIN_CLOSE_COUNT_INPUT" ) then
		SelectBetterServer_BetterServer1:SetText("")
		SelectBetterServer_BetterServer2:SetText("")
		g_IsShow = 1
		this:Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SelectBetterServer_On_ResetPos()
	end
end

function SelectBetterServer_QuitClick()
	--PushEvent("QUENEQUIT_SELECT", 134, g_showbuttonStr)
	GameProduceLogin:ReturnToAccountDlg()
	g_IsShow = 1
	this:Hide()
end

function SelectBetterServer_BetterServer1Click()
	GameProduceLogin:SendQueneQuitMsg()
	GameProduceLogin:SelectLoginServer(g_LoginServer1.iServerAreaIndex, g_LoginServer1.iServerIndex, g_iNetProvide)
	g_IsShow = 1
	this:Hide()
end

function SelectBetterServer_BetterServer2Click()
	GameProduceLogin:SendQueneQuitMsg()
	GameProduceLogin:SelectLoginServer(g_LoginServer2.iServerAreaIndex, g_LoginServer2.iServerIndex, g_iNetProvide)
	g_IsShow = 1
	this:Hide()
end

function SelectBetterServer_On_ResetPos()
	SelectBetterServer_Frame:SetProperty("UnifiedPosition", g_SelectBetterServer_Frame_UnifiedPosition)
end

function SelectBetterServer_UpdateRect()
	local nWidth, nHeight = SelectBetterServer_InfoWindow:GetWindowSize();
	local nTitleHeight = 23;
	local nBottomHeight = 35;
	local nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	SelectBetterServer_Frame_sub:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end

---------------------------------------------------------------------------
--推荐规则是这样的 - -
--如果当前登录的服务器是双线服务器 优先级如下
--一 1-双线 2-双线
--二 1-双线 2-无
--三 1-电信 2-网通
--如果当前登录的服务器是网通服务器 优先级如下 以下括号为:有就显示 没有就算了
--一 1-双线 2-双线
--二 1-双线 2-(网通)
--三 1-(网通) 2-(网通)
--如果当前登录的服务器是电信服务器 优先级如下
--一 1-双线 2-双线
--二 1-双线 2-(电信)
--三 1-(电信) 2-(电信)

--网通和电信一样，双线自己一样
---------------------------------------------------------------------------
function SelectBetterServer_GetFlueServer()

	SelectBetterServer_InsertServerList()
	if g_FlueServerList.iServerCount >= 2 then
		--随机选择两个
		SelectBetterServer_Random()
		SelectBetterServer_Copy(g_LoginServer1, g_tempServerTable[1])
		SelectBetterServer_Copy(g_LoginServer2, g_tempServerTable[2])
		SelectBetterServer_ShowServer(SelectBetterServer_BetterServer1, g_LoginServer1)
		SelectBetterServer_ShowServer(SelectBetterServer_BetterServer2, g_LoginServer2)
	elseif g_FlueServerList.iServerCount == 1 then
		--只有一个双线服务器，就显示这个了
		SelectBetterServer_Copy(g_LoginServer1, 1)
		SelectBetterServer_ShowServer(SelectBetterServer_BetterServer1, g_LoginServer1)
		SelectBetterServer_BetterServer2:Hide()
	else
		SelectBetterServer_BetterServer1:Hide()
		SelectBetterServer_BetterServer2:Hide()
	end
end

--填充流畅服务器数组,即选择合适的服务器，loginserver中配置显示，未处于维护、未处于爆满、非配置为不显示的服务器
function SelectBetterServer_InsertServerList()

	--清空数组
	for i=0,g_FlueServerList.iServerCount-1 do
		g_FlueServerList.strServerName[i] = ""
		g_FlueServerList.iServerIndex[i] = -1
		g_FlueServerList.iServerAreaIndex[i] = -1
		g_FlueServerList.iServerStatus[i] = 0
	end
	g_FlueServerList.iServerCount = 0
	--清空完毕

	local iCurAreaCount = GameProduceLogin:GetServerAreaCount()
	local strAreaName = "无服务器"
	local iLoginServerCount = -1
	local ServerName
	local ServerStatus
	local isFlueServer

	for index = 0, iCurAreaCount-1 do
		local strAreaName = GameProduceLogin:GetServerAreaName(index)
		local iPos = string.find(strAreaName, "-")

		local areaName = ""
		if iPos ~= nil then
			areaName = string.sub(strAreaName, iPos+1)
		else
			areaName = strAreaName
		end
		iLoginServerCount = GameProduceLogin:GetAreaLoginServerCount(index)
		--得到流畅服务器列表
		for i=0,iLoginServerCount-1 do
			ServerName,
			ServerStatus,
			_,_,_,_,_
				= GameProduceLogin:GetAreaLoginServerInfo(index, i)
			isFlueServer = GameProduceLogin:GetIsFluencyServer(index, i)
			-- 推荐服务器id
			if(isFlueServer == 1 and ServerStatus ~= g_StateStop and ServerStatus ~= g_StateNotShow) then
				local bAdd = 1
				if (g_curArea == index and g_curServer == i) then
					bAdd = 0
				end
				if (bAdd == 1) then
					g_FlueServerList.iServerCount = g_FlueServerList.iServerCount + 1
					g_FlueServerList.strServerName[g_FlueServerList.iServerCount] = areaName.."-"..ServerName
					g_FlueServerList.iServerIndex[g_FlueServerList.iServerCount] = i
					g_FlueServerList.iServerAreaIndex[g_FlueServerList.iServerCount] = index
					g_FlueServerList.iServerStatus[g_FlueServerList.iServerCount] = ServerStatus
				end
			end
		end
	 end
end

--洗牌算法，取前两个
function SelectBetterServer_Random()
	--清空数组
	for i = 1, g_FlueServerList.iServerCount do
		g_tempServerTable[i] = i
	end
	for i = 1, g_FlueServerList.iServerCount do
		local rdm = math.random(i, g_FlueServerList.iServerCount)
		local temp = g_tempServerTable[rdm]
		g_tempServerTable[rdm] = g_tempServerTable[i]
		g_tempServerTable[i] = temp
	end
end

--复制
function SelectBetterServer_Copy(loginServer, index)
	--逐个复制到loginServer里
	loginServer.strServerName = g_FlueServerList.strServerName[index]
	loginServer.iServerIndex = g_FlueServerList.iServerIndex[index]
	loginServer.iServerAreaIndex = g_FlueServerList.iServerAreaIndex[index]
	loginServer.iServerStatus = g_FlueServerList.iServerStatus[index]
end

--状态：爆满、空闲、极好
function SelectBetterServer_UI_GetServerStatusString( iStatus )	
	--状态
	local strStatus;
	if(0 == iStatus) then
		strStatus = "#{DLYHQF_12121326}"	--"#e010101#cff0000爆满#cffffff";
	elseif(1 == iStatus) then
		strStatus = "#{DLYHQF_12121327}"	--"#e010101#c9E5705繁忙#cffffff";
	elseif(2 == iStatus) then
		strStatus = "#{DLYHQF_12121328}"	--"#e010101#cECE58D良好#cffffff";
	elseif(3 == iStatus) then
		strStatus = "#{DLYHQF_12121329}"	--"#e010101#c4CFA4C极佳#cffffff";
	else
		strStatus = "#{DLYHQF_12121330}"	--"#e010101#c959595维护#cffffff";
	end
	
	local strRet = "#{DLYHQF_12121325}"..strStatus;		--.."#r"..strSpeed
	return strRet;	
end

--显示服务器信息
function SelectBetterServer_ShowServer(betterServer, loginServer)
	local strName = loginServer.strServerName
	if(0 == loginServer.iServerStatus) then
		strName = "#cff0000#e010101"..strName.."#cffffff";
	elseif(1 == loginServer.iServerStatus) then
		strName = "#cff8a00#e010101"..strName.."#cffffff";
	elseif(2 == loginServer.iServerStatus) then
		strName = "#cECE58D#e010101"..strName.."#cffffff";
	elseif(3 == loginServer.iServerStatus) then
		strName = "#c4CFA4C#e010101"..strName.."#cffffff";
	else
		strName = "#c959595#e010101"..strName.."#cffffff";
		betterServer:Disable();
	end	
	betterServer:SetText(strName)
	local strStatus = SelectBetterServer_UI_GetServerStatusString(loginServer.iServerStatus)
	betterServer:SetToolTip(strStatus)
	betterServer:Show()
end

