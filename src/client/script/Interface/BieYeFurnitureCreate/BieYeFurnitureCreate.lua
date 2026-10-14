--庭院家具制造、室内家具制造
local BieYeFurnitureCreate_UnifiedPosition = 0
local g_ButtonList = {}
local g_TingYuanCreateInfo = {}
local g_ShiNeiCreateInfo = {}
local g_MaxType = 30
--当前界面类型 1庭院制造 2室内制造
local g_CurInterfaceType = 0
--当前选中的button index
local g_CurSelIndex  = 0
local g_MaxDistance = 15
local g_Server_Script_Function = "CreateFurniture"
local g_Server_Script = 891923
local g_CaredNpc = -1
--用于制造按钮点击限制
local g_ClickTime = 0
--是否处于批量制作中
local g_IsMbuy = 0
--批量制作剩余次数
local g_nMbuyCount = 0
--批量制作总个数
local g_nMbuyAllCount = 0
--是否读条中
local g_IsDuTiao = 0
--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function BieYeFurnitureCreate_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("MBUY2BIEYEFURCREATE")--界面间通信事件
	this:RegisterEvent("BIEYERESUPDATE") --资源数据有更新
	--界面互斥事件
	this:RegisterEvent("OPEN_EQUIP"); --人物基础信息
	this:RegisterEvent("TEAM_OPEN_TEAMINFO_DLG")--组队界面
	this:RegisterEvent("GUILD_SHOW_MEMBERINFO")--帮会界面
	this:RegisterEvent("TOGLE_PET_PAGE")--珍兽界面
	this:RegisterEvent("ON_SHOWQUESTLOGWINDOW")--任务日志
	this:RegisterEvent("YIGUI_OPEN")--储衣柜

	
	--BieYeFurnitureCreate_InitTingYuanInfo()
	--BieYeFurnitureCreate_InitShiNeiInfo()
	BieYeFurnitureCreate_InitFurInfo()
end

--=========================================================
-- 载入初始化
--=========================================================
function BieYeFurnitureCreate_OnLoad()
	BieYeFurnitureCreate_UnifiedPosition=BieYeFurnitureCreate_Frame:GetProperty("UnifiedPosition");
end

function BieYeFurnitureCreate_OnHiden()
	BieYeFurnitureCreate_Close()
end
--=========================================================
-- 事件处理
--=========================================================
function BieYeFurnitureCreate_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 891923) then
		local npcServerId = Get_XParam_INT(0)
		g_CaredNpc = DataPool:GetNPCIDByServerID(npcServerId)
		if g_CaredNpc == -1 then
			PushDebugMessage("server传过来的数据有问题。")
			return
		end
		local ifType = Get_XParam_INT(1) --打开界面的类型
		if(this:IsVisible())  then
			if(g_CurInterfaceType == ifType) then
				return
			end
			BieYeFurnitureCreate_Close()
		end
		PushEvent("ONOPENBIEYEFURCREATE")
		BeginCareObject_BieYeFurnitureCreate()
		this:Show()
		BieYeFurnitureCreate_OK_Animate:Play(false) --初始关闭按钮特效
		if(1 == ifType) then 
			BieYeFurnitureCreate_ShowTingYuanButton()
		elseif (2 == ifType) then
			BieYeFurnitureCreate_ShowShiNeiButton()
			--引导任务tips
			if DataPool:Lua_IsHaveMission(1860) > 0 then
				local misIndex = DataPool:GetPlayerMissionIndexByID(1860)
				if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
					CloseFreshManGuide()	
					local fX, fY = this:GetChildOffset("BieYeFurnitureCreate_OK")
					OpenFreshManGuide(1, 124, fX+40, fY+20, "BieYeFurnitureCreate", "southwest")	
					BieYeFurnitureCreate_OK_Animate:Play(true)
				end
			end
			
		else
			return
		end
		BieYeFurnitureCreate_CurSetText()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 8919231) then
		local nRetId = Get_XParam_INT(0)
		local nFurId = Get_XParam_INT(1)
		BieYeFurnitureCreate_OnRetClickCreate(nFurId,nRetId)
	elseif(event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") then
		if(this:IsVisible()) then
			BieYeFurnitureCreate_CurSetText()
		end
		--刷新一下批量界面
		BieYeFurnitureCreate_FreshMBuy(2)
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if (tonumber(arg0) ~= g_CaredNpc) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > g_MaxDistance) or arg1=="destroy") then
			BieYeFurnitureCreate_Close()
		end
	elseif (event == "BIEYERESUPDATE") then
		if(this:IsVisible()) then
			BieYeFurnitureCreate_CurSetText()
		end
		--刷新一下批量界面
		BieYeFurnitureCreate_FreshMBuy(2)
	elseif(event == "MBUY2BIEYEFURCREATE") then --批量界面数据传回
		BieYeFurnitureCreate_StartMBuy(tonumber(arg0))
	elseif (event == "ADJEST_UI_POS")  then
		BieYeFurnitureCreate_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeFurnitureCreate_ResetPos()
	elseif (event =="OPEN_EQUIP" or 
			event == "TEAM_OPEN_TEAMINFO_DLG" or 
			event == "GUILD_SHOW_MEMBERINFO" or 
			event == "TOGLE_PET_PAGE" or 
			event == "ON_SHOWQUESTLOGWINDOW" or 
			event == "YIGUI_OPEN"  )then
	    if(this:IsVisible()) then
			BieYeFurnitureCreate_Close()
		end
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 201611031) then --家园引导任务5完成 关闭界面
		local nMission = Get_XParam_INT(0)
		if this:IsVisible() and nMission == 5 then
			BieYeFurnitureCreate_Close()
		end
	end
	
end

function BieYeFurnitureCreate_ResetPos()
  BieYeFurnitureCreate_Frame:SetProperty("UnifiedPosition", BieYeFurnitureCreate_UnifiedPosition);
end
--显示庭院家具制造页
function BieYeFurnitureCreate_ShowTingYuanButton()
	g_CurInterfaceType = 1
	for nButtonIndex = 1,table.getn(g_TingYuanCreateInfo) do
		BieYeFurnitureCreate_AddTingYuanButton(g_TingYuanCreateInfo[nButtonIndex])
	end
	BieYeFurnitureCreate_SelButtonIndex(1)
	BieYeFurnitureCreate_SetTitle("#{BYFUR_160531_37}")
	BieYeFurnitureCreate_Button:Flash()
end
--显示室内家具制造页
function BieYeFurnitureCreate_ShowShiNeiButton()
	g_CurInterfaceType = 2
	for nButtonIndex = 1,table.getn(g_ShiNeiCreateInfo) do
		BieYeFurnitureCreate_AddShiNeiButton(g_ShiNeiCreateInfo[nButtonIndex])
	end
	BieYeFurnitureCreate_SelButtonIndex(1)
	BieYeFurnitureCreate_SetTitle("#{BYFUR_160531_59}")
	BieYeFurnitureCreate_Button:Flash()
end
--列表按钮选中
function BieYeFurnitureCreate_SelButtonIndex(nIndex)
	if(nIndex ~= g_CurSelIndex) then
		if(g_IsMbuy ~= 0 ) then
			PushDebugMessage("#{BYFUR_160531_240}")
			if(0 ~= nIndex and nil ~= g_ButtonList[nIndex]) then
			g_ButtonList[nIndex]:SetBarButtonSelected(false)
		end	
			return
		end
		if(0 ~= g_CurSelIndex ) and nil ~= g_ButtonList[g_CurSelIndex] then
			g_ButtonList[g_CurSelIndex]:SetBarButtonSelected(false)
		end
		if(0 ~= nIndex and nil ~= g_ButtonList[nIndex]) then
			g_ButtonList[nIndex]:SetBarButtonSelected(true)
		end	
		g_CurSelIndex = nIndex
		BieYeFurnitureCreate_OnSelButtonIndex(nIndex)
	end
end
function BieYeFurnitureCreate_SetTitle(szTitle)
	BieYeFurnitureCreate_DragTitle:SetText(szTitle)
end
--列表按钮选中事件
function BieYeFurnitureCreate_OnSelButtonIndex(nIndex)
	local info = nil
	local szText = ""
	if(g_CurInterfaceType == 1) then
		info = g_TingYuanCreateInfo
		szText = "#{BYFUR_160531_40}"
	elseif(g_CurInterfaceType == 2) then
		info = g_ShiNeiCreateInfo	
	    szText = "#{BYFUR_160531_61}"
	end
	if(info == nil) then
		return
	end
	if(info[nIndex] == nil) then
		return
	end
	--设置text
	strText = ScriptGlobal_Format(szText,info[nIndex].ShuShidu)
	BieYeFurnitureCreate_Mode_Text:SetText(strText)
	--更换模型
	BieYeFurnitureCreate_FakeObject : SetFakeObject( "" )
	BieYeFurniture:SetFurnitureCreateModel(info[nIndex].id)
	BieYeFurnitureCreate_FakeObject : SetFakeObject( "BieYeFurnitureCreate")
	BieYeFurnitureCreate_FreshMBuy(2)
	
	if info[nIndex].CanJiaoHun == -1 then
		BieYeFurnitureCreate_Jiaohu_Text:Hide()
	else
		BieYeFurnitureCreate_Jiaohu_Text:Show()
	end
end

function BieYeFurnitureCreate_AddTingYuanButton(ButtonInfo)
	if(nil == ButtonInfo) then
		return
	end
	local ItemBar = BieYeFurnitureCreate_Button:AddItemElement("BieYeFurnitureCreate", "LEFT", "BieYeFurnitureCreate","" ,"")
	ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	local sPos,_ = string.find(ButtonInfo.IconSetStr," ");
	local IconImageSet = string.sub(ButtonInfo.IconSetStr,5,sPos-1);
	local IconIamge = string.sub(ButtonInfo.IconSetStr,sPos+7)
	ItemBar:SetImage1(IconImageSet,IconIamge)
	ItemBar:SetText1(ButtonInfo.Name)
	local shicaiText = ScriptGlobal_Format("#{BYFUR_160531_38}",ButtonInfo.CostShiCai)--石材消耗
	ItemBar:SetText2(shicaiText)
	ItemBar:SetText3("#{BYFUR_160531_39}") --金钱消耗
	--这个控件类型现在只加了SetText4Property接口，模仿写的，要自己加接口
	--ItemBar:SetText4Property("MoneyNumber",""..ButtonInfo.CostJinbi)
	--ItemBar:SetText4("#{_MONEY"..(ButtonInfo.CostJinbi).."}")
	ItemBar:SetText4(math.floor((ButtonInfo.CostJinbi)/10000).."#-14")
	table.insert(g_ButtonList,ItemBar)
end

function BieYeFurnitureCreate_AddShiNeiButton(ButtonInfo)
	if(nil == ButtonInfo) then
		return
	end
	local ItemBar = BieYeFurnitureCreate_Button:AddItemElement("BieYeFurnitureCreate", "LEFT", "BieYeFurnitureCreate","" ,"")
	ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	local sPos,_ = string.find(ButtonInfo.IconSetStr," ");
	local IconImageSet = string.sub(ButtonInfo.IconSetStr,5,sPos-1);
	local IconIamge = string.sub(ButtonInfo.IconSetStr,sPos+7)
	ItemBar:SetImage1(IconImageSet,IconIamge)
	ItemBar:SetText1(ButtonInfo.Name)
	local MuCaiText = ScriptGlobal_Format("#{BYFUR_160531_60}",ButtonInfo.CostMuCai) --木材消耗
	ItemBar:SetText2(MuCaiText)--金钱消耗
	ItemBar:SetText3("#{BYFUR_160531_39}")
	--这个控件类型现在只加了SetText4Property接口，模仿写的，要自己加接口
	--ItemBar:SetText4Property("MoneyNumber",""..ButtonInfo.CostJinbi)
	--ItemBar:SetText4("#{_MONEY"..(ButtonInfo.CostJinbi).."}")
	ItemBar:SetText4(math.floor((ButtonInfo.CostJinbi)/10000).."#-14")
	table.insert(g_ButtonList,ItemBar)
end

function BieYeFurnitureCreate_InitFurInfo()
	local i = 0
	local nTingYuanIndex = 1
	local nShiNeiIndex = 1
	while(i >= 0)
	do
		local nId,nPos,nType,nLevel,szName,szIcon,nShushi,nCostMu,nCostShi,nCostJin,nCanMake, nCanJiaoHun = BieYeFurniture:GetFurCreateInfo(i)
		if(nId ~= -1) then
		 i = i+1
		 if(nCanMake > 0) then
			if(nCostMu ~= -1 or nCostShi ~= -1 or nCostJin ~= -1) then
				local value = {}
				value.id = nId
				value.Name = szName
				value.IconSetStr = szIcon
				value.ShuShidu = nShushi
				value.CostMuCai = nCostMu
				value.CostShiCai = nCostShi
				value.CostJinbi = nCostJin
				value.CanJiaoHun = nCanJiaoHun
				if(nPos == 0) then
					g_TingYuanCreateInfo[nTingYuanIndex] = value
					nTingYuanIndex = nTingYuanIndex + 1
				elseif(nPos == 1) then
					g_ShiNeiCreateInfo[nShiNeiIndex] = value
					nShiNeiIndex = nShiNeiIndex + 1
				end
			end
		 end
		else
		 i = -1
		end
	end
end
-- function BieYeFurnitureCreate_InitTingYuanInfo()
	-- for i = 1,g_MaxType do
		-- local nId,szName,szIcon,nShushi,nCostMu,nCostShi,nCostJin = BieYeFurniture:GetFurCreateInfo(0,i)
		-- if(nId ~= -1) then
			-- if(nCostMu ~= -1 or nCostShi ~= -1 or nCostJin ~= -1) then
				-- local value = {}
				-- value.id = nId
				-- value.Name = szName
				-- value.IconSetStr = szIcon
				-- value.ShuShidu = nShushi
				-- value.CostMuCai = nCostMu
				-- value.CostShiCai = nCostShi
				-- value.CostJinbi = nCostJin
				-- g_TingYuanCreateInfo[i] = value
				-- --PushDebugMessage("IconSet = "..g_TingYuanCreateInfo[i].IconSetStr)
			-- end
		-- end
	-- end
-- end

-- function BieYeFurnitureCreate_InitShiNeiInfo()
	-- for i = 1,g_MaxType do
		-- local nId,szName,szIcon,nShushi,nCostMu,nCostShi,nCostJin = BieYeFurniture:GetFurCreateInfo(1,i)
		-- if(nId ~= -1) then
			-- if(nCostMu ~= -1 or nCostShi ~= -1 or nCostJin ~= -1) then
				-- local value = {}
				-- value.id = nId
				-- value.Name = szName
				-- value.IconSetStr = szIcon
				-- value.ShuShidu = nShushi
				-- value.CostMuCai = nCostMu
				-- value.CostShiCai = nCostShi
				-- value.CostJinbi = nCostJin
				-- g_ShiNeiCreateInfo[i] = value
			-- end
		-- end
	-- end
-- end
function BieYeFurnitureCreate_OnItemClick()

	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		BieYeFurnitureCreate_SelButtonIndex(nIndex + 1)
		BieYeFurnitureCreate_Button:Flash()
	end

end
--设置text信息
function BieYeFurnitureCreate_CurSetText()
	--设置资源数量
	local nZiYuan = 0
	local strZiYuanName = ""
	if(g_CurInterfaceType == 1) then
		
		strZiYuanName = "#{BYFUR_160531_42}"
		nZiYuan = BieYeUI:GetBieYeBaseInfo("ResStones")
	elseif(g_CurInterfaceType == 2) then
		strZiYuanName = "#{BYFUR_160531_41}"
		nZiYuan = BieYeUI:GetBieYeBaseInfo("ResWoods")
	end
	BieYeFurnitureCreate_Cost_Want:SetText(strZiYuanName)
	BieYeFurnitureCreate_Cost_WantNum:SetText(""..nZiYuan)
	--交子
	local nJiaozi = tostring(Player:GetData("MONEY_JZ"))
	BieYeFurnitureCreate_Cost_HaveJiaoZiNum:SetProperty("MoneyNumber",""..nJiaozi)
	--金币
	local nGold = tostring(Player:GetData("MONEY"))
	BieYeFurnitureCreate_Cost_HaveGoldNum:SetProperty("MoneyNumber",""..nGold)

end
--关闭界面
function BieYeFurnitureCreate_Close()
	g_CurSelIndex = 0
	g_CurInterfaceType = 0
	g_ButtonList = {}
	StopCareObject_BieYeFurnitureCreate()
	BieYeFurnitureCreate_Button:CleanAllElement("BieYeFurnitureCreate")
	BieYeFurnitureCreate_FakeObject : SetFakeObject( "" )
	--批量和读条都先屏蔽
	--停止批量制作
	--BieYeFurnitureCreate_StopMBuy()
	--停止读条
	--BieYeFurnitureCreate_CancelCreate()
	--绑定关闭批量界面
	BieYeFurnitureCreate_CloseMBuy()
	
	--关闭引导任务tips
	if DataPool:Lua_IsHaveMission(1860) > 0 and DataPool:Lua_IsMissionHaveDone(1860) <= 0 then
		CloseFreshManGuide()	
	end
	
	this:Hide()
end
function BieYeFurnitureCreate_OnClose()
	BieYeFurnitureCreate_Close()
end
--模型旋转
function BieYeFurnitureCreate_TurnLeft(start)
	--向左旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeFurnitureCreate_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			BieYeFurnitureCreate_FakeObject:RotateEnd();
		end
	end
end
function BieYeFurnitureCreate_TurnRight(start)
	--向右旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeFurnitureCreate_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			BieYeFurnitureCreate_FakeObject:RotateEnd();
		end
	end
end
--=========================================================
-- 开始关心NPC，
-- 在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
-- 如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_BieYeFurnitureCreate()

	this:CareObject(g_CaredNpc, 1, "BieYeFurnitureCreate")
	return
end

--=========================================================
-- 停止对某NPC的关心
--=========================================================
function StopCareObject_BieYeFurnitureCreate()
	this:CareObject(g_CaredNpc, 0, "BieYeFurnitureCreate")
	g_CaredNpc = -1
	return
end
--批量制作点击
function BieYeFurnitureCreate_ClickMBuy()
	--批量制作功能先屏蔽了，先不删代码，万一策划又要了呢
	--return
	if(BieYeFurnitureCreate_CheckBase() ~= 1)then
		return
	end
	if(g_IsMbuy ~= 0) then
		--正在批量制作，点击取消
		BieYeFurnitureCreate_StopMBuy()
		BieYeFurnitureCreate_CancelCreate()
		return
	end
	BieYeFurnitureCreate_FreshMBuy(1)
end
--bFresh 1 表示打开 2表示刷新
function BieYeFurnitureCreate_FreshMBuy(bFresh)
	local FurName=""
	local nCostShi = 0
	local nCostMu = 0
	local nCostJin = 0
	if(g_CurSelIndex ~= 0 )then
		if(g_CurInterfaceType == 1 and g_TingYuanCreateInfo[g_CurSelIndex] ~= nil) then
			FurName = g_TingYuanCreateInfo[g_CurSelIndex].Name
			nCostShi = g_TingYuanCreateInfo[g_CurSelIndex].CostShiCai
			nCostMu = g_TingYuanCreateInfo[g_CurSelIndex].CostMuCai
			nCostJin = g_TingYuanCreateInfo[g_CurSelIndex].CostJinbi
		elseif(g_CurInterfaceType == 2 and g_ShiNeiCreateInfo[g_CurSelIndex] ~= nil) then
			FurName = g_ShiNeiCreateInfo[g_CurSelIndex].Name
			nCostShi = g_ShiNeiCreateInfo[g_CurSelIndex].CostShiCai
			nCostMu = g_ShiNeiCreateInfo[g_CurSelIndex].CostMuCai
			nCostJin = g_ShiNeiCreateInfo[g_CurSelIndex].CostJinbi
		end
	end
	--打开批量制作的界面
	PushEvent("OPEN_BIEYEFURCREATE_MBUY",bFresh,g_CurInterfaceType,FurName,nCostShi,nCostMu,nCostJin)
end
--开始批量制作
function BieYeFurnitureCreate_StartMBuy(nCount)
	if(nCount > 0 and nCount < 100) then
		g_nMbuyCount = nCount
		g_nMbuyAllCount = nCount
		g_IsMbuy = 1
		--BieYeFurnitureCreate_Mbuy:SetText("#{BYFUR_160531_220}")
		BieYeFurnitureCreate_CloseMBuy()
		BieYeFurnitureCreate_ClickCreate()
	else
		PushDebugMessage("#{BYFUR_170315_310}")
	end
end
--停止批量制作
function BieYeFurnitureCreate_StopMBuy()
	g_IsMbuy = 0
	g_nMbuyCount = 0
	g_nMbuyAllCount = 0
	--BieYeFurnitureCreate_Mbuy:SetText("#{BYFUR_160531_219}")
end
--停止制作
function BieYeFurnitureCreate_CancelCreate()
	if(g_ClickTime ~= 0 or g_IsDuTiao == 1) then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CancelCreate")
		Set_XSCRIPT_ScriptID(g_Server_Script)
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end
--关闭批量制作界面
function BieYeFurnitureCreate_CloseMBuy()
	PushEvent("CLOSE_BIEYEFURCREATE_MBUY")
end
--客户端增加制作的验证(因为这个设计无论什么操作服务器都会回包，所以在客户端加验证减少发包量)
--服务器同样需要验证，这里只起到拦截发包的作用
function BieYeFurnitureCreate_Check()
	if(BieYeFurnitureCreate_CheckBase() == 1 and BieYeFurnitureCreate_CheckZiYuan() == 1) then
		return 1
	end
	return 0
end
function BieYeFurnitureCreate_CheckZiYuan()
	local CreateInfo ={}
	if(g_CurSelIndex <= 0) then
		return 0
	end
	if(g_CurInterfaceType == 1) then
		CreateInfo = g_TingYuanCreateInfo[g_CurSelIndex]
	elseif(g_CurInterfaceType == 2) then
		CreateInfo = g_ShiNeiCreateInfo[g_CurSelIndex]
	else
		return 0
	end

	local nCount = 1
	if(g_IsMbuy == 1) then
		nCount = g_nMbuyAllCount
	end
	if(nCount <= 0) then
		return 0
	end
	--检查石材
	if(BieYeUI:GetBieYeBaseInfo("ResStones") < CreateInfo.CostShiCai * nCount) then
		local Tips = ScriptGlobal_Format("#{BYFUR_160531_55}",CreateInfo.Name)
		PushDebugMessage(Tips)
		PushDebugMessage("#{BYFUR_160531_289}")
		return 0
	end
	--检查木材
	if(BieYeUI:GetBieYeBaseInfo("ResWoods") < CreateInfo.CostMuCai * nCount) then
		local Tips = ScriptGlobal_Format("#{BYFUR_160531_62}",CreateInfo.Name)
		PushDebugMessage(Tips)
		PushDebugMessage("#{BYFUR_160531_290}")
		return 0 
	end
	--检查金钱
	if(Player:GetData("MONEY_JZ") + Player:GetData("MONEY") < CreateInfo.CostJinbi * nCount) then
		local Tips = ScriptGlobal_Format("#{BYFUR_160531_56}",CreateInfo.Name)
		PushDebugMessage(Tips)
		return 0
	end
	--检查背包空间
	if(CalcItemSpace(tonumber(CreateInfo.id)) < 1) then
		PushDebugMessage("#{BYFUR_160531_57}")
		return 0
	end
	return 1
end
function BieYeFurnitureCreate_CheckBase()
	--是否家园主人或者配偶
	local BieYeGuid = BieYeUI:GetBieYeBaseInfo("Guid")
	local myGuid = Player:GetGUID()
	local isHaveSpouse , spouseGuid = Friend:Lua_GetSpouseGuid()
	if(myGuid ~= BieYeGuid and (isHaveSpouse ~= 1 or spouseGuid ~= BieYeGuid)) then
		PushDebugMessage("#{BYFUR_160531_47}")
		return 0
	end

	
	--安全时间内不能操作
	if(DataPool:GetForeverLock() == true or DataPool:GetLeftProtectTime() > 0 ) then
		PushDebugMessage("#{BYFUR_160531_48}")
		return 0
	end
	--密保 二级密码
	if(CheckPhoneMibaoAndMinorPassword() == 0) then
		return 0
	end
	--检查玩家等级
	if(Player:GetLevel() < 50) then
		PushDebugMessage("#{BYFUR_160531_53}")
		return 0
	end
	return 1
end
--点击制造
function BieYeFurnitureCreate_ClickCreate()
	if(g_CurSelIndex ~= 0 and g_CurInterfaceType ~= 0) then
	if(g_IsDuTiao == 1) then
		return PushDebugMessage("#{BYFUR_160531_195}")
	end
	--这里做一个点击限制
	local CurTime = OSAPI:GetTickCount()
	if(g_ClickTime ~= 0) then
		if(CurTime - g_ClickTime < 6000) then
			if(g_IsMbuy == 1) then
				PushDebugMessage("#{BYFUR_160531_240}")
			else
				PushDebugMessage("#{BYFUR_160531_241}")
			end
			return
		end
	end
	--直接拦截
	if(BieYeFurnitureCreate_Check() == 0) then
		if(g_IsMbuy == 1) then
			BieYeFurnitureCreate_StopMBuy()
		end
		return
	end
	g_ClickTime = CurTime
	--界面类型判定
	local nItemId = 0
	if(g_CurInterfaceType == 1) then
		if(g_TingYuanCreateInfo ~= nil and g_TingYuanCreateInfo[g_CurSelIndex] ~= nil) then
			nItemId = g_TingYuanCreateInfo[g_CurSelIndex].id
		else
			return
		end
	elseif(g_CurInterfaceType == 2) then
		if(g_ShiNeiCreateInfo ~= nil and g_ShiNeiCreateInfo[g_CurSelIndex] ~= nil) then
			nItemId = g_ShiNeiCreateInfo[g_CurSelIndex].id
		else
			return
		end
	else
		return
	end
	local nCount = 1
	if(g_IsMbuy == 1) then
		nCount = g_nMbuyAllCount
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name(g_Server_Script_Function)
	Set_XSCRIPT_ScriptID(g_Server_Script)
	--Set_XSCRIPT_Parameter(0,g_CurInterfaceType)
	Set_XSCRIPT_Parameter(0,nItemId)
	Set_XSCRIPT_Parameter(1,g_IsMbuy)
	Set_XSCRIPT_Parameter(2,nCount)
	Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
	
	--关闭引导任务tips
	if DataPool:Lua_IsHaveMission(1860) > 0 and DataPool:Lua_IsMissionHaveDone(1860) <= 0 then
		CloseFreshManGuide()	
	end
	end	
end
function BieYeFurnitureCreate_GetInfoById(nFurId)
	for i = 1,table.getn(g_TingYuanCreateInfo) do
		if(g_TingYuanCreateInfo[i] ~= nil and g_TingYuanCreateInfo[i].id == nFurId) then
			return g_TingYuanCreateInfo[i].Name,g_TingYuanCreateInfo[i].CostMuCai,g_TingYuanCreateInfo[i].CostShiCai,g_TingYuanCreateInfo[i].CostJinbi
		end
	end
	for i = 1,table.getn(g_ShiNeiCreateInfo) do
		if(g_ShiNeiCreateInfo[i] ~= nil and g_ShiNeiCreateInfo[i].id == nFurId) then
			return g_ShiNeiCreateInfo[i].Name,g_ShiNeiCreateInfo[i].CostMuCai,g_ShiNeiCreateInfo[i].CostShiCai,g_ShiNeiCreateInfo[i].CostJinbi
		end
	end
	return "-1",-1,-1,-1
end
--点击制造服务器 返回结果 0表示成功 1表示等级不够 2表示木材不足 3表示石材不足 4表示金钱不足 5表示没有操作资格 6表示其他安全时间等 7表示未知错误 8表示背包不足 9表示读条被打断
--11表示家具不支持制造 12表示制造数量不正确
function BieYeFurnitureCreate_OnRetClickCreate(nFurId,nRetId)
	local Name,CostMu,CostShi,CostJin = BieYeFurnitureCreate_GetInfoById(nFurId)
	if(Name == "-1") then
		return
	end
	local Tips = ""
	--拓展的提示
	local TipsExt = ""
	--BieYeUI:AskBieYeBaseInfo(0) --刷新一下数据
	g_ClickTime = 0
	g_IsDuTiao = 0
	--取消批量制作状态
	if(nRetId ~= 0 and g_IsMbuy ~= 0 and nRetId ~= 10) then
		BieYeFurnitureCreate_StopMBuy()
	end
	if(nRetId == 0) then
		if(g_IsMbuy == 1) then
			--Tips = "你通过批量制造成功制造了"..g_nMbuyAllCount.."个"..Name
			Tips = ScriptGlobal_Format("#{BFYH_170209_08}",g_nMbuyAllCount,Name)
			BieYeFurnitureCreate_StopMBuy()
		else
			Tips = ScriptGlobal_Format("#{BYFUR_160531_58}",Name)
		end
		
		--if(g_IsMbuy == 1 and g_nMbuyCount > 1) then
		--	g_nMbuyCount = g_nMbuyCount - 1
		--	BieYeFurnitureCreate_ClickCreate()
		--elseif(g_IsMbuy == 1 and g_nMbuyCount == 1) then --完成批量制作
		--	BieYeFurnitureCreate_StopMBuy()
		--end
	elseif (nRetId == 1) then
		Tips = "#{BYFUR_160531_53}"
	elseif (nRetId == 2) then
		Tips = ScriptGlobal_Format("#{BYFUR_160531_62}",Name)
		TipsExt = "#{BYFUR_160531_289}"
	elseif(nRetId == 3) then
		Tips = ScriptGlobal_Format("#{BYFUR_160531_55}",Name)
		TipsExt = "#{BYFUR_160531_290}"
	elseif(nRetId == 4) then
		Tips = ScriptGlobal_Format("#{BYFUR_160531_56}",Name)
	elseif (nRetId == 5) then
		Tips = "#{BYFUR_160531_47}"
	elseif(nRetId == 6 or nRetId == 7) then
		return
	elseif(nRetId == 8) then
		Tips = "#{BYFUR_160531_57}"
	elseif(nRetId == 9) then --读条被打断
		return
	elseif(nRetId == 10) then
		--if(g_IsMbuy == 1) then
		--	local szTips = ScriptGlobal_Format("#{BYFUR_160531_258}",g_nMbuyAllCount,Name,g_nMbuyAllCount - g_nMbuyCount + 1,g_nMbuyCount - 1)
		--	PushDebugMessage(szTips)
		--end
		g_IsDuTiao = 1 --开始读条了
	elseif(nRetId == 11) then
		Tips = "#{BYFUR_160531_302}"
	elseif(nRetId == 12) then
		Tips = "不正确的批量制造数量"
	end
	PushDebugMessage(Tips)
	if(TipsExt ~= "") then
		PushDebugMessage(TipsExt)
	end
end

function BieYeFurnitureCreate_OnMoved()
    if "BieYeFurnitureCreate" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
end