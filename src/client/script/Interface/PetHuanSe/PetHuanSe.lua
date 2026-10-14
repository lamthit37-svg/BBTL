
local g_Huanse_Frame_UnifiedPosition

local g_Huanse_YuanBaoPay = 1	--元宝购买确认
local g_Huanse_NeedMoney = 50000

local g_ExteriorType = 2 --附体
local g_MaxBarNum
local g_CurSelExteriorID = 0
local g_Huanse_CurColorIndex = -1   --当前选中的颜色图标下标 从1开始
local g_Huanse_MaxColorCount = 9    --幻色上限值

local g_clientNpcId = -1

--附体外形染色图标名称
local g_Huanse_IconList = {}

--附体外形染色蒙红图标名称
local g_Huanse_IconMaskList = {}

--附体外形染色动画图标名称
local g_Huanse_IconAniList = {}

--索引对应MD的位数
local g_Huanse_PetPossNameList = {
	[1] = "#{FTWX_110511_02}",	--附体：默认
	[2] = "#{FTWX_110511_03}",	--附体：游龙
	[3] = "#{FTWX_110511_04}",	--附体：幻蝶
	[4] = "#{FTWX_110511_05}",	--附体：飞凤
	[5] = "#{ZSHT_110301_03}",	--附体：清羽
	[6] = "#{FTHS_140417_01}",	--附体：霸魂
	[7] = "#{FTHS_150113_01}",	--附体：锦鳞
	[8] = "#{FTHS_150805_01}",	--附体：灵鹊
	[9] = "#{FTSH_190415_01}",	--附体：瑞鹤
	[10] = "#{ZNLSG_230215_359}",	--十六周年庆新附体
	[11] = "#{ZNLSG_230818_07}" ,
	[12] = "#{YYLL_240730_10}",
	[13] = "#{JWFT_231115_2}",
	[14] = "#{RCLS_250228_05}",
	[15] = "#{RCLS_250826_06}",
	[16] = "#{JWFT_251105_2}",
	[17] = "#{RCLS_260303_03}",
}

--附体融合度列表
local PetHuanSe_CboSearchItem = 
{
	[1] = "0~2",		--0~2
	[2] = "3~5",		--3~5
	[3] = "6~7",		--6~7
	[4] = "8~9",		--8~9
	[5] = "10",		    --10
}

local g_PetHuanSeTbl = 
{
	[1] = 0, 	--融合度：0-2
	[2] = 3, 	--融合度：3-5
	[3] = 6, 	--融合度：6-7
	[4] = 8, 	--融合度：8-9
	[5] = 10,	--融合度：10
}
local g_Huanse_IndexToExterior = {}


function PetHuanSe_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	-- this:RegisterEvent("PETPOSSSHOWUPDATE")
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("UPDATE_FAKE_OBJECT",false)
	this:RegisterEvent("RESET_ALLUI")				-- 返回登录界面, 重置所有UI
	-- this:RegisterEvent("UPDATE_EXTERIOR",false)
	this:RegisterEvent("EXTERIOR_FUTI_VISUAL_INDEX",false)
	-- this:RegisterEvent("ADD_EXTERIOR",false)
	this:RegisterEvent("EXTERIOR_ID_CHANGED",false)
	
end

function PetHuanSe_OnLoad()
	g_Huanse_Frame_UnifiedPosition = PetHuanSe_Frame:GetProperty("UnifiedPosition")

	--附体外形染色图标名称
	g_Huanse_IconList[1] = PetHuanSe_Icon0
	g_Huanse_IconList[2] = PetHuanSe_Icon1
	g_Huanse_IconList[3] = PetHuanSe_Icon2
	g_Huanse_IconList[4] = PetHuanSe_Icon3
	g_Huanse_IconList[5] = PetHuanSe_Icon4
	g_Huanse_IconList[6] = PetHuanSe_Icon5
	g_Huanse_IconList[7] = PetHuanSe_Icon6
	g_Huanse_IconList[8] = PetHuanSe_Icon7
	g_Huanse_IconList[9] = PetHuanSe_Icon8


	--附体外形染色蒙红图标名称
	g_Huanse_IconMaskList[1] = PetHuanSe_Mask0
	g_Huanse_IconMaskList[2] = PetHuanSe_Mask1
	g_Huanse_IconMaskList[3] = PetHuanSe_Mask2
	g_Huanse_IconMaskList[4] = PetHuanSe_Mask3
	g_Huanse_IconMaskList[5] = PetHuanSe_Mask4
	g_Huanse_IconMaskList[6] = PetHuanSe_Mask5
	g_Huanse_IconMaskList[7] = PetHuanSe_Mask6
	g_Huanse_IconMaskList[8] = PetHuanSe_Mask7
	g_Huanse_IconMaskList[9] = PetHuanSe_Mask8

	--附体外形染色动画图标名称
	g_Huanse_IconAniList[1] = PetHuanSe_Animate0
	g_Huanse_IconAniList[2] = PetHuanSe_Animate1
	g_Huanse_IconAniList[3] = PetHuanSe_Animate2
	g_Huanse_IconAniList[4] = PetHuanSe_Animate3
	g_Huanse_IconAniList[5] = PetHuanSe_Animate4
	g_Huanse_IconAniList[6] = PetHuanSe_Animate5
	g_Huanse_IconAniList[7] = PetHuanSe_Animate6
	g_Huanse_IconAniList[8] = PetHuanSe_Animate7
	g_Huanse_IconAniList[9] = PetHuanSe_Animate8

	for i=1,g_Huanse_MaxColorCount do
		g_Huanse_IconList[i] : SetPushed(0)
		g_Huanse_IconList[i] : SetProperty("NormalImage","")
		g_Huanse_IconList[i] : SetProperty("HoverImage","")
		g_Huanse_IconList[i] : SetToolTip("")
		g_Huanse_IconMaskList[i] : SetProperty("Image", "")
		g_Huanse_IconMaskList[i] : SetToolTip("")
		g_Huanse_IconAniList[i] : SetProperty("Visible","False")
	end
end

function PetHuanSe_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 8893832) then  --打开附体幻色界面
		--关闭关联界面
		if(IsWindowShow("PetPossJian")) then
			CloseWindow("PetPossJian", true);
		end	
		local npcObjId = Get_XParam_INT(0)
		g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
		if g_clientNpcId == -1 then
			PushDebugMessage("未发现 NPC")
			PetHuanSe_CloseBtnClick()()
			return
		end
		
		this:CareObject( g_clientNpcId, 1, "PetHuanSe" )
		this:Show()
		PetHuanSe_OnShown()
	elseif( event == "ADJEST_UI_POS" ) then
		PetHuanSe_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		PetHuanSe_ResetPos()
	elseif(event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		PetHuanSe_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))		
	elseif(event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		PetHuanSe_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	-- elseif( event == "UPDATE_EXTERIOR") then
	-- 	--激活新幻色会下发该消息
	-- 	-- PushDebugMessage("UPDATE_EXTERIOR  xtyc")
	-- 	if tonumber(arg0) == g_ExteriorType then
	-- 		PetHuanSe_Update()
	-- 	end
	elseif( event == "EXTERIOR_FUTI_VISUAL_INDEX") then
		PetHuanSe_Update()
	elseif( event == "UPDATE_FAKE_OBJECT" ) then	
		if( arg0 == "" and this:IsVisible() ) then
			FakeObj_SetCamera( "My_PetPossColorRate", 2,9)
		end
	elseif (event == "RESET_ALLUI") then				
		g_Huanse_YuanBaoPay = 1
	elseif (event == "EXTERIOR_ID_CHANGED") then
		PetHuanSe_Update()
	end

end

function PetHuanSe_YBPay_Clicked()
	if g_Huanse_YuanBaoPay==1 then
		g_Huanse_YuanBaoPay = 0
	else
		g_Huanse_YuanBaoPay = 1
	end
	PetHuanSe_YuanBaoPay_Button:SetCheck(g_Huanse_YuanBaoPay)
end

function PetHuanSe_OnShown()
	-- PushDebugMessage("PetHuanSe_OnShown  xtyc")
	PetHuanSe_FakeObject:SetFakeObject("")
	PetHuanSe_FakeObject:SetFakeObject("My_PetPossColorRate")
	FakeObj_SetCamera( "My_PetPossColorRate", 2,9)
	
	--元宝确认框ui状态
	if g_Huanse_YuanBaoPay == 1 or g_Huanse_YuanBaoPay == 0 then
		PetHuanSe_YuanBaoPay_Button:SetCheck(g_Huanse_YuanBaoPay)
	end
	--更新金钱
	PetHuanSe_Money:SetProperty("MoneyNumber", g_Huanse_NeedMoney)
	local playerMoney = Player:GetData("MONEY")
	PetHuanSe_SelfMoney:SetProperty("MoneyNumber", playerMoney)
	local playerJZ = Player:GetData("MONEY_JZ")
	PetHuanSe_SelfJiaozi:SetProperty("MoneyNumber", playerJZ)

	--更新融合度列表
	PetHuanSe_SearchMode:ResetList()
	for i = 1, table.getn(PetHuanSe_CboSearchItem) do
		PetHuanSe_SearchMode:AddTextItem(PetHuanSe_CboSearchItem[i], i)
	end
	PetHuanSe_SearchMode:SetCurrentSelect(4)

	PetHuanSe_Update()
end

function PetHuanSe_Update()
	Exterior:LuaFnInitExteriorList(g_ExteriorType,1)
	g_MaxBarNum = Exterior:LuaFnGetExteriorMaxCount(g_ExteriorType)
	local cacheExteriorID = Exterior:LuaFnGetExteriorInUse(g_ExteriorType)
	-- PushDebugMessage("cacheExteriorID:"..tostring(cacheExteriorID))
	if cacheExteriorID > 0 then
		g_CurSelExteriorID = cacheExteriorID
	end
	local selectIndex = 1
	--先清空当前列表
	PetHuanSe_EquiptShapeList:ClearListBox()
	for index = 1, g_MaxBarNum do
		local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, index - 1)
		-- PushDebugMessage("index:"..tostring(index))
		-- PushDebugMessage("nExteriorID:"..tostring(nExteriorID))
		local szPossName = g_Huanse_PetPossNameList[nExteriorID]
		if	Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) == 1 then
			
			-- PushDebugMessage("nExteriorID:"..tostring(nExteriorID))
			szPossName = "#cfff263"..szPossName		--黄色
			PetHuanSe_EquiptShapeList:AddItem(szPossName, index)
			g_Huanse_IndexToExterior[index] = nExteriorID
			if g_CurSelExteriorID == nExteriorID then
				selectIndex = index
			end
		-- else
		-- 	szPossName = "#c808080"..szPossName	--灰色
		end
		
	end
	for index = 1, g_MaxBarNum do
		local nExteriorID 	= Exterior:LuaFnGetExteriorIDFromList(g_ExteriorType, index - 1)
		local szPossName = g_Huanse_PetPossNameList[nExteriorID]
		if	Exterior:LuaFnIsHaveExterior(g_ExteriorType, nExteriorID) ~= 1 then
		-- 	szPossName = "#cfff263"..szPossName		--黄色
		-- else
			szPossName = "#c808080"..szPossName	--灰色
			PetHuanSe_EquiptShapeList:AddItem(szPossName, index)
			g_Huanse_IndexToExterior[index] = nExteriorID
		end
		
	end
	-- if cacheExteriorID == nExteriorID then
	-- 	PetHuanSe_EquiptShapeList:SetItemSelect(index - 1)
	-- end
	PetHuanSe_EquiptShapeList:SetItemSelectByItemID(selectIndex)
	PetHuanSe_ListBox_Selected()
end

--点击左侧list幻色框的事件
function PetHuanSe_ListBox_Selected()
	--获得列表选项
	local tempIndex = PetHuanSe_EquiptShapeList:GetFirstSelectItem()--选择的附体类型
	g_CurSelExteriorID = g_Huanse_IndexToExterior[tempIndex]
	-- PushDebugMessage("g_CurSelExteriorID:"..tostring(g_CurSelExteriorID))
	--参数有效性判断
	if g_CurSelExteriorID <= 0 or g_CurSelExteriorID > g_MaxBarNum then 
		return
	end
	PetHuanse_UpdateColorList()
	--通过左侧的附体名称进行选择时，默认选中正在使用的颜色
	local colorIndex = Exterior:LuaFnGetExteriorFutiVisualIndex()
	g_Huanse_CurColorIndex = colorIndex+1
	-- PushDebugMessage("colorIndex:"..tostring(colorIndex))
	PetHuanSe_ColorBox_Selected(g_Huanse_CurColorIndex)
	if g_CurSelExteriorID == 12 or g_CurSelExteriorID == 15 or g_CurSelExteriorID == 17 then
		PetHuanSe_shuoming_Info:SetText("#{DHLS_240611_108}")
	else 
		PetHuanSe_shuoming_Info:SetText("#{FTHS_120719_21}")
	end
end

--选中右侧不同颜色的附体
function PetHuanSe_ColorBox_Selected(value)
	-- PushDebugMessage("value:"..tostring(value))
	-- Exterior:LuaFnGetExteriorFutiVisualIndex()--获取当前正在使用的幻色
	if value <= 0 or value > g_Huanse_MaxColorCount then
		return
	end
	g_Huanse_CurColorIndex = value
	for i=1, g_Huanse_MaxColorCount do
		if g_Huanse_CurColorIndex == i then
			g_Huanse_IconList[i]:SetPushed(1)--设置新的选中
		else
			g_Huanse_IconList[i]:SetPushed(0)--取消原来的选中 
		end
	end
	PetHuanSe_SearchMode_Changed()
end


--更新右侧颜色列表
function PetHuanse_UpdateColorList()
	for i=1, g_Huanse_MaxColorCount do
		g_Huanse_IconList[i] : SetProperty("NormalImage","")
		g_Huanse_IconList[i] : SetProperty("HoverImage","")
		g_Huanse_IconList[i] : SetToolTip("")
		g_Huanse_IconList[i] : Hide()
		-- g_Huanse_IconList[i] : SetProperty("Visible","False")
		g_Huanse_IconMaskList[i] : SetToolTip("")
		g_Huanse_IconMaskList[i] : SetProperty("Image", "")
	end	
	--显示图标
	-- PushDebugMessage("g_Huanse_MaxColorCount:"..tostring(g_Huanse_MaxColorCount))
	local curCount = 0
	if g_CurSelExteriorID == 1 or g_CurSelExteriorID == 13 or g_CurSelExteriorID == 14 then  --默认的附体还有一种幻色
		curCount = 1
	elseif g_CurSelExteriorID == 16 then
		curCount = 2
	else
		curCount = g_Huanse_MaxColorCount
	end
	for i=1, curCount do
		-- PushDebugMessage("i:"..tostring(i))
		--设置icon
		if Exterior:LuaFnIsExteriorFutiVisualUnlocked(g_CurSelExteriorID, i - 1) ~= 1 then  --当前的幻色是否解锁
			--未解锁
			g_Huanse_IconMaskList[i]:SetProperty("Image", "set:Face_04 image:Remind_Bak")
		end
		g_Huanse_IconList[i] : Show()
		local strImage 	= Exterior:LuaFnGetExteriorFutiInfo(g_CurSelExteriorID, "VisualIcon", i-1)
		g_Huanse_IconList[i] : SetProperty("NormalImage",strImage)
		g_Huanse_IconList[i] : SetProperty("HoverImage",strImage)
	end
	

end

function PetHuanSe_SearchMode_Changed()
	local str,nIndex = PetHuanSe_SearchMode:GetCurrentSelect()

	if nIndex ~= -1 then
		-- PushDebugMessage("str:"..tostring(str))
		--Model
		PetHuanSe_FakeObject:SetFakeObject("")
		local modelId = g_CurSelExteriorID * 1000 + g_Huanse_CurColorIndex
		Pet:SetPetPossColorRateByFitValue(modelId, g_PetHuanSeTbl[nIndex])
		PetHuanSe_FakeObject:SetFakeObject("My_PetPossColorRate")
		FakeObj_SetCamera( "My_PetPossColorRate", 2,9)
		-- local strName = Pet:GetPetPossModelNameById(g_Huanse_Select_IndexId)
		-- if strName == nil or strName == "" then
		-- 	return
		-- end
		-- PetHuanSe_Pet_Type:SetText(strName)
	end

end

--点击“幻色”按钮
function PetHuanSe_OK_Clicked()

	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{JJTZ_090826_26}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
		return
	end
	if Player:GetData("LEVEL") < 45 then
		PushDebugMessage("#{ZSYH_170111_41}")
		return
	end
	-- PushDebugMessage("#{JJTZ_090826_26}")
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnPetFuTiHuanSe")
	Set_XSCRIPT_ScriptID(889383)
	Set_XSCRIPT_Parameter(0, g_CurSelExteriorID)
	Set_XSCRIPT_Parameter(1, g_Huanse_YuanBaoPay)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

end

--点击更换按钮
function PetHuanSe_Visual_Clicked()
	--是否达到45级
	if Player:GetData("LEVEL") < 45 then
		PushDebugMessage("#{FTWX_110511_13}")
		return
	end

	--判断玩家是否选中1个附体颜色
	if g_Huanse_CurColorIndex <= 0 or g_Huanse_CurColorIndex > g_Huanse_MaxColorCount then
		PushDebugMessage("#{GXHDZ_141121_65}")
		return
	end

	--判断当前选中的外形是否正在使用中
	-- local colorIndex = Exterior:LuaFnGetExteriorFutiVisualIndex()
	-- if colorIndex+1 == g_Huanse_CurColorIndex then
	-- 	PushDebugMessage("#{GXHDZ_141121_66}")
	-- 	return
	-- end

	--Server会再次判断这些条件

	-- 向服务器发送更换消息
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnChangeHuanse")
		Set_XSCRIPT_ScriptID(889383)
		Set_XSCRIPT_Parameter(0, g_CurSelExteriorID) 
		Set_XSCRIPT_Parameter(1, g_Huanse_CurColorIndex) 
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end


function PetHuanSe_CloseBtnClick()
	this:Hide()
end

--Hidden事件
function PetHuanSe_Close_Window()
	this:Hide()--回头改按钮事件 把这个删掉
	g_Huanse_YuanBaoPay = PetHuanSe_YuanBaoPay_Button:GetCheck();
	PetHuanSe_FakeObject:SetFakeObject("")
	
	if(IsWindowShow("PetHuanSeJian")) then
		CloseWindow("PetHuanSeJian", true);
	end	
	g_Huanse_CurColorIndex = -1
	this:CareObject( g_clientNpcId, 0, "PetHuanSe" )
	g_clientNpcId = -1
end

--model turn left
function PetHuanSe_Pet_Modle_TurnLeft(start)
	--start
	if (start == 1 and CEArg:GetValue("MouseButton") == "LeftButton") then
		PetHuanSe_FakeObject:RotateBegin(-0.3)
	else
		PetHuanSe_FakeObject:RotateEnd()
	end
end

--model turn right
function PetHuanSe_Pet_Modle_TurnRight(start)
	--start
	if (start == 1 and CEArg:GetValue("MouseButton") == "LeftButton") then
		PetHuanSe_FakeObject:RotateBegin(0.3)
	else
		PetHuanSe_FakeObject:RotateEnd()
	end
end

function PetHuanSe_ResetPos()
	PetHuanSe_Frame:SetProperty("UnifiedPosition", g_Huanse_Frame_UnifiedPosition);
end

