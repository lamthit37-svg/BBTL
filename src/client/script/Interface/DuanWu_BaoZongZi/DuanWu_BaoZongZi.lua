--端午包粽子

local g_DuanWu_BaoZongZi_Frame_UnifiedPosition;

local g_DuanWu_BaoZongZi_SelectButtons = {}

local g_DuanWu_BaoZongZi_GetBounsButtons = {}
local g_DuanWu_BaoZongZi_GetBounsDisableImg = {}
local g_DuanWu_BaoZongZi_GetBounsButtonsTips = {}


local g_DuanWu_BaoZongZi_CaiLiaoAItemId = 39921700
local g_DuanWu_BaoZongZi_CaiLiaoBItemId = 39921701


local g_DuanWu_BaoZongZi_Script_ID = 505088
local g_DuanWu_BaoZongZi_Script_BaoZongZiName = "OnBaoZongZi"
local g_DuanWu_BaoZongZi_Script_OpenName = "OnOpen"
local g_DuanWu_BaoZongZi_Script_GetZongYe = "OnGetZongYe"
local g_DuanWu_BaoZongZi_Script_GetPointBouns = "OnGetPointBouns"

local g_DuanWu_BaoZongZi_CurSelect = -1 -- 选择要包的粽子 默认1

local g_DuanWu_BaoZongZi_ActivityPoint_Bouns = 450
local g_DuanWu_BaoZongZi_BounsPoint_List ={9,27,45,63,81}
local g_DuanWu_BaoZongZi_BounsPointMax = 81
local MD_2022_DUANWU_BOUNSFLAG_FROM_POINT = 2503 --重开不用改
local MD_2022_DUANWU_POINT_FROM_USEZONGZI = 2504 --重开不用改
local MD_2022_DUANWU_GETZONGYE_DATE = 2502

local g_DuanWu_BaoZongZi_KaJiType = 78


--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function DuanWu_BaoZongZi_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("DUANWU_ZONGZI_CONFIRM") --

	--this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)


	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--=========================================================
-- 载入初始化
--=========================================================
function DuanWu_BaoZongZi_OnLoad()

	g_DuanWu_BaoZongZi_SelectButtons[1] = DuanWu_BaoZongZi_ZongZi1
	g_DuanWu_BaoZongZi_SelectButtons[2] = DuanWu_BaoZongZi_ZongZi2

	g_DuanWu_BaoZongZi_GetBounsButtons[1] = DuanWu_BaoZongZi_Icon1
	g_DuanWu_BaoZongZi_GetBounsButtons[2] = DuanWu_BaoZongZi_Icon2
	g_DuanWu_BaoZongZi_GetBounsButtons[3] = DuanWu_BaoZongZi_Icon3
	g_DuanWu_BaoZongZi_GetBounsButtons[4] = DuanWu_BaoZongZi_Icon4
	g_DuanWu_BaoZongZi_GetBounsButtons[5] = DuanWu_BaoZongZi_Icon5

	g_DuanWu_BaoZongZi_GetBounsDisableImg[1] = DuanWu_BaoZongZi_Icon1Disabled
	g_DuanWu_BaoZongZi_GetBounsDisableImg[2] = DuanWu_BaoZongZi_Icon2Disabled
	g_DuanWu_BaoZongZi_GetBounsDisableImg[3] = DuanWu_BaoZongZi_Icon3Disabled
	g_DuanWu_BaoZongZi_GetBounsDisableImg[4] = DuanWu_BaoZongZi_Icon4Disabled
	g_DuanWu_BaoZongZi_GetBounsDisableImg[5] = DuanWu_BaoZongZi_Icon5Disabled

	g_DuanWu_BaoZongZi_GetBounsButtonsTips[1] = DuanWu_BaoZongZi_Icon1Tip
	g_DuanWu_BaoZongZi_GetBounsButtonsTips[2] = DuanWu_BaoZongZi_Icon2Tip
	g_DuanWu_BaoZongZi_GetBounsButtonsTips[3]= DuanWu_BaoZongZi_Icon3Tip
	g_DuanWu_BaoZongZi_GetBounsButtonsTips[4] = DuanWu_BaoZongZi_Icon4Tip
	g_DuanWu_BaoZongZi_GetBounsButtonsTips[5] = DuanWu_BaoZongZi_Icon5Tip

	g_DuanWu_BaoZongZi_Frame_UnifiedPosition=DuanWu_BaoZongZi_FrameNULL:GetProperty("UnifiedPosition");

end

--=========================================================
-- 事件处理
--=========================================================
function DuanWu_BaoZongZi_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 50508802) then --打开界面

		if this:IsVisible() == false then
			DuanWu_BaoZongZi_Clear()
			DuanWu_BaoZongZi_InitItem()
			DuanWu_BaoZongZi_UpdateData()
			this:Show()

		else
			DuanWu_BaoZongZi_UpdateData()

		end

	--elseif ( event == "PACKAGE_ITEM_CHANGED_EX" ) then
		--向服务器请求刷新界面
	--	Clear_XSCRIPT()
	--		Set_XSCRIPT_Function_Name(g_DuanWu_BaoZongZi_Script_OpenName)
	--		Set_XSCRIPT_ScriptID(g_DuanWu_BaoZongZi_Script_ID)
	--		Set_XSCRIPT_ParamCount( 0 )
	--	Send_XSCRIPT()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 50508501) then --刷新界面
		DuanWu_BaoZongZi_Clear()
		DuanWu_BaoZongZi_InitItem()
		DuanWu_BaoZongZi_UpdateData()

	elseif ( event == "DUANWU_ZONGZI_CONFIRM" ) then
		DuanWu_BaoZongZi_SendMsg2Server( 1 )

	elseif (event == "ADJEST_UI_POS" ) then
		DuanWu_BaoZongZi_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DuanWu_BaoZongZi_Frame_On_ResetPos()

	elseif ( event == "HIDE_ON_SCENE_TRANSED") then
		--切场景，关界面
		DuanWu_BaoZongZi_Close()
		return
	end
end

--=========================================================
-- 更新基本显示信息
--=========================================================
function DuanWu_BaoZongZi_UpdateData()
	local nCaiLiao11 = Get_XParam_INT(0)
	local nCaiLiao12 = Get_XParam_INT(1)

	local nCaiLiao21 = Get_XParam_INT(2)
	local nCaiLiao22 = Get_XParam_INT(3)

--	local nZongZi2_NotMakeDay = Get_XParam_INT(4)

	local numMsg11 = ""
	if nCaiLiao11 < 1 then
		numMsg11 = ScriptGlobal_Format("#{DWPF_190428_49}", nCaiLiao11, 1)
	else
		numMsg11 = ScriptGlobal_Format("#{DWPF_190428_22}", nCaiLiao11, 1)
	end
	DuanWu_BaoZongZi_ZongZi1_Item1Num:SetText(numMsg11)

	local numMsg21 = ""
	if nCaiLiao21 < 1 then
		numMsg21 = ScriptGlobal_Format("#{DWPF_190428_49}", nCaiLiao21, 1)
	else
		numMsg21 = ScriptGlobal_Format("#{DWPF_190428_22}", nCaiLiao21, 1)
	end

	local numMsg22 = ""
	if nCaiLiao22 < 1 then
		numMsg22 = ScriptGlobal_Format("#{DWPF_190428_49}", nCaiLiao22, 1)
	else
		numMsg22 = ScriptGlobal_Format("#{DWPF_190428_22}", nCaiLiao22, 1)
	end

	DuanWu_BaoZongZi_ZongZi2_Item1Num:SetText(numMsg21)
	DuanWu_BaoZongZi_ZongZi2_Item2Num:SetText(numMsg22)

	--活跃度领奖
	local kjtype   = KaJi:LuaFnGetKaJiType(78)
	if kjtype == 1 then
		DuanWu_BaoZongZi_GetButton:SetToolTip("#{DWPF_220420_47}")
	else
		DuanWu_BaoZongZi_GetButton:SetToolTip("#{DWPF_220420_05}")
	end
	
	local nToadyActivePoint = Player:GetData("TODAYACTIVEPOINT")
	local nToadyActivePointStr = ScriptGlobal_Format("#{DWPF_220420_31}",nToadyActivePoint)
	DuanWu_BaoZongZi_HuoYueText:SetText(nToadyActivePointStr)
	local nServerTime = DataPool:GetServerDayTime()
	local nLastDate = DataPool:GetPlayerMission_DataRound( MD_2022_DUANWU_GETZONGYE_DATE )
	if nToadyActivePoint >= g_DuanWu_BaoZongZi_ActivityPoint_Bouns  and  nServerTime ~= nLastDate then
		DuanWu_BaoZongZi_GetButtonTip:Show()
	else
		DuanWu_BaoZongZi_GetButtonTip:Hide()
	end
--		PushDebugMessage("nToadyActivePoint="..nToadyActivePoint)
--		DuanWu_BaoZongZi_GetButton:Disable()
--	else
--		DuanWu_BaoZongZi_GetButton:Enable()
--	end

	--累计奖励显示
	local mPoint = DuanWu_GetPointFromUseZongzi()	-- 获取累计积分
	DuanWu_BaoZongZi_ScoreBK_Jindu:SetProgress(mPoint , g_DuanWu_BaoZongZi_BounsPointMax)
	local nPointStr = ScriptGlobal_Format("#{DWPF_220420_06}",mPoint)
	DuanWu_BaoZongZi_ScoreText:SetText(nPointStr)

	for i=1,5 do
		if mPoint>=g_DuanWu_BaoZongZi_BounsPoint_List[i] then
			local nBounsFlag = DuanWu_GetBouseFlag(i)
			if nBounsFlag == 1 then
				g_DuanWu_BaoZongZi_GetBounsButtons[i]:Disable()
				g_DuanWu_BaoZongZi_GetBounsButtonsTips[i]:Hide()
				g_DuanWu_BaoZongZi_GetBounsDisableImg[i]:Show()
				g_DuanWu_BaoZongZi_GetBounsDisableImg[i]:SetToolTip("#{DWPF_220420_33}")
			else
				g_DuanWu_BaoZongZi_GetBounsButtons[i]:Enable()
				g_DuanWu_BaoZongZi_GetBounsButtonsTips[i]:Show()
				g_DuanWu_BaoZongZi_GetBounsDisableImg[i]:Hide()
			end
		else
			g_DuanWu_BaoZongZi_GetBounsButtons[i]:Enable()
			g_DuanWu_BaoZongZi_GetBounsButtonsTips[i]:Hide()
			g_DuanWu_BaoZongZi_GetBounsDisableImg[i]:Hide()
		end
	end

--	local curDay = DataPool:GetServerDayTime()
--	if curDay > nZongZi2_NotMakeDay then
--		DuanWu_BaoZongZi_ZongZi2_Finish:Show()
--	end
end

function DuanWu_GetPointFromUseZongzi()
	local mData = DataPool:GetPlayerMission_DataRound( MD_2022_DUANWU_POINT_FROM_USEZONGZI )
	local nPoint = math.mod(mData,1000)
	local nYear = math.floor(mData/1000)
	local ServerDayTime = DataPool:GetServerDayTime()
	local CurYear = math.floor(ServerDayTime/10000)
	if nYear == CurYear then
		return nPoint
	else
		return 0

	end
end
function DuanWu_GetBouseFlag(nIndex)
	local mData = DataPool:GetPlayerMission_DataRound( MD_2022_DUANWU_BOUNSFLAG_FROM_POINT )
	local nBounsFlag = math.mod(mData,1000000)
	local nYear = math.floor(mData/1000000)
	local ServerDayTime = DataPool:GetServerDayTime()
	local CurYear = math.floor(ServerDayTime/10000)
	local nflag = 0
	if nYear == CurYear then
		if nIndex == 1 then
			nflag = math.mod(nBounsFlag,10)
		elseif nIndex == 2 then
			local temp = math.floor(nBounsFlag/10)
			nflag = math.mod(temp,10)
		elseif nIndex == 3 then
			local temp = math.floor(nBounsFlag/100)
			nflag = math.mod(temp,10)
		elseif nIndex == 4 then
			local temp = math.floor(nBounsFlag/1000)
			nflag = math.mod(temp,10)
		elseif nIndex == 5 then
			local temp = math.floor(nBounsFlag/10000)
			nflag = math.mod(temp,10)
		end
	end
	return nflag
end

--=========================================================
-- 重置界面
--=========================================================
function DuanWu_BaoZongZi_Clear()

	g_DuanWu_BaoZongZi_CurSelect = -1

	for select=1, table.getn(g_DuanWu_BaoZongZi_SelectButtons) do
		g_DuanWu_BaoZongZi_SelectButtons[select]:SetCheck(0)
	end


	DuanWu_BaoZongZi_ZongZi1_Item1:SetActionItem(-1)
	DuanWu_BaoZongZi_ZongZi1_Item1Num:SetText("")

	DuanWu_BaoZongZi_ZongZi2_Item1:SetActionItem(-1)
	DuanWu_BaoZongZi_ZongZi2_Item2:SetActionItem(-1)
	DuanWu_BaoZongZi_ZongZi2_Item1Num:SetText("")
	DuanWu_BaoZongZi_ZongZi2_Item2Num:SetText("")

end

--=========================================================
-- 界面控件数据
--=========================================================
function DuanWu_BaoZongZi_InitItem( )
	--

	local caiLiaoActionA = DataPool:CreateActionItemForShow(g_DuanWu_BaoZongZi_CaiLiaoAItemId, 1)
	if caiLiaoActionA:GetID() == 0 then
		return
	end
	DuanWu_BaoZongZi_ZongZi1_Item1:SetActionItem( caiLiaoActionA:GetID() )


	local caiLiaoActionB = DataPool:CreateActionItemForShow(g_DuanWu_BaoZongZi_CaiLiaoBItemId, 1)
	if caiLiaoActionB:GetID() == 0 then
		return
	end
	DuanWu_BaoZongZi_ZongZi2_Item1:SetActionItem( caiLiaoActionA:GetID() )
	DuanWu_BaoZongZi_ZongZi2_Item2:SetActionItem( caiLiaoActionB:GetID() )

	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(g_DuanWu_BaoZongZi_KaJiType) > 0 then  --卡级
		DuanWu_BaoZongZi_ZongZi1:SetToolTip("#{DWPF_220420_02}")
		DuanWu_BaoZongZi_ZongZi2:SetToolTip("#{DWPF_220420_03}")
	elseif 1 == Player:GetData("IsOriginalJD") then
		DuanWu_BaoZongZi_ZongZi1:SetToolTip("#{DWPF_260429_02}")
		DuanWu_BaoZongZi_ZongZi2:SetToolTip("#{DWPF_260429_03}")
	else
		DuanWu_BaoZongZi_ZongZi1:SetToolTip("#{DWPF_190428_52}")
		DuanWu_BaoZongZi_ZongZi2:SetToolTip("#{DWPF_190428_53}")
	end

	DuanWu_BaoZongZi_ZongZi2_Finish:Hide()
end



--=========================================================
-- 确定执行功能
--=========================================================
function DuanWu_BaoZongZi_OK_Clicked()

	--
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{KPWFS_131112_20}")
		return
	end

	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	--- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90609_22}" )
		return
	end

	if g_DuanWu_BaoZongZi_CurSelect == -1 then
		PushDebugMessage( "#{DWPF_190428_33}" )
		return
	end

	DuanWu_BaoZongZi_SendMsg2Server( 0 )
end


function DuanWu_BaoZongZi_SendMsg2Server( bConfirm )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name(g_DuanWu_BaoZongZi_Script_BaoZongZiName)
		Set_XSCRIPT_ScriptID(g_DuanWu_BaoZongZi_Script_ID)
		Set_XSCRIPT_Parameter(0, g_DuanWu_BaoZongZi_CurSelect)
		Set_XSCRIPT_Parameter(1, bConfirm)
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()

end


--=========================================================
-- 关闭界面
--=========================================================
function DuanWu_BaoZongZi_Close()
	this:Hide()
	CloseWindow( "MessageBox_Self", true );

	return
end


function DuanWu_BaoZongZi_Frame_On_ResetPos()
  DuanWu_BaoZongZi_FrameNULL:SetProperty("UnifiedPosition", g_DuanWu_BaoZongZi_Frame_UnifiedPosition);
end


--选择包哪个粽子
function DuanWu_BaoZongZi_Select( curSelect )
	local selectNum = table.getn(g_DuanWu_BaoZongZi_SelectButtons)

	if curSelect <= 0 or curSelect > selectNum then
		return
	end

	--其它粽子选项置未选中，选择的粽子置选中状态
	for select=1, selectNum do
		g_DuanWu_BaoZongZi_SelectButtons[select]:SetCheck(0)
	end
	g_DuanWu_BaoZongZi_SelectButtons[curSelect]:SetCheck(1)

	--记录选中数据
	g_DuanWu_BaoZongZi_CurSelect = curSelect
end


--帮助按钮
function DuanWu_BaoZongZi_Help()
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(g_DuanWu_BaoZongZi_KaJiType) > 0 then  --卡级
		PushEvent( "OPEN_HUODONGTEXT_HELP", 3, "#{DWPF_220420_01}" )
	else
		PushEvent( "OPEN_HUODONGTEXT_HELP", 3, "#{DWPF_190428_05}" )
	end
end


--领取粽叶
function DuanWu_BaoZongZi_GetZongYe_OK_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name(g_DuanWu_BaoZongZi_Script_GetZongYe)
		Set_XSCRIPT_ScriptID(g_DuanWu_BaoZongZi_Script_ID)
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()

end

--领取累计奖励
function DuanWu_BaoZongZi_PointBouns_OK_Clicked(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name(g_DuanWu_BaoZongZi_Script_GetPointBouns)
		Set_XSCRIPT_ScriptID(g_DuanWu_BaoZongZi_Script_ID)
		Set_XSCRIPT_Parameter(0, nIndex)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

function DuanWu_BaoZongZi_DressPreview()
	-- Clear_XSCRIPT()
		-- Set_XSCRIPT_ScriptID(888051)
		-- Set_XSCRIPT_Function_Name("DressPreview")
		-- Set_XSCRIPT_Parameter(0, 10127124)
		-- Set_XSCRIPT_Parameter(1, -1)	-- hairId
		-- Set_XSCRIPT_Parameter(2, -1)	-- faceId
		-- Set_XSCRIPT_ParamCount(3)
	-- Send_XSCRIPT()
end

