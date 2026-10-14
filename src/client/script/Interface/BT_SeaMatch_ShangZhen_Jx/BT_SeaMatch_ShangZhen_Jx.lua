--试剑天下上阵界面
local g_ObjCareID = 0
local MAX_OBJ_DISTANCE 	 = 3.0;
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition
--目标ID
local m_targetId = 0

local m_round = 0
local m_isStart = 0
local m_remainTime = 0
local m_upDataNameList = {}
local m_upDataHeadImageList = {}
local m_upDataMenPeiList = {}

local m_MenPaiNameList =
{
	[0]  ={Name="#{SCGZ_180816_30}" , Color="#cff6600", }, --少林
	[1]  ={Name="#{SCGZ_180816_36}" , Color="#cffcc00", }, --明教
	[2]  ={Name="#{SCGZ_180816_37}" , Color="#c00ff00", }, --丐帮
	[3]  ={Name="#{SCGZ_180816_31}" , Color="#c0000ff", }, --武当
	[4]  ={Name="#{SCGZ_180816_33}" , Color="#cff99cc", }, --峨嵋
	[5]  ={Name="#{SCGZ_180816_32}" , Color="#c007700", }, --星宿
	[6]  ={Name="#{SCGZ_180816_41}" , Color="#cffff00", }, --天龙
	[7]  ={Name="#{SCGZ_180816_35}" , Color="#cffffff", }, --天山
	[8]  ={Name="#{SCGZ_180816_34}" , Color="#c7700ff", }, --逍遥
	[9]  ={Name="无门派"     , Color="#c999999", },	
	[10] ={Name="#{SCGZ_180816_40}", Color="#c007fff", }, --慕容
	[11] ={Name="#{SCGZ_180816_38}", Color="#ccc00ff", }, --唐门
	[12] ={Name="#{SCGZ_180816_39}", Color="#c24dec6", },   --鬼谷
	[13] ={Name="#{SCGZ_180816_119}", Color="#c24dec6", },   --桃花岛
	[14] ={Name="#{XMPHM_210604_01}", Color="#c24dec6", }, 
	[15] ={Name="#{GMGameInterface_Script_DataPool_Info_ERenGu}", Color="#c656ab4", },--menpai15
}
--预加载函数，可以而且只能在这里注册脚本关心的事件
function BT_SeaMatch_ShangZhen_Jx_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_SeaMatch_ShangZhen_Jx_ResetPos()
	BT_SeaMatch_ShangZhen_Jx_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_SeaMatch_ShangZhen_Jx_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function BT_SeaMatch_ShangZhen_Jx_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= BT_SeaMatch_ShangZhen_Jx_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedXPosition	= BT_SeaMatch_ShangZhen_Jx_Frame:GetProperty("UnifiedYPosition");
end


--响应事件的函数，当注册的事件发生时会调用的函数
function BT_SeaMatch_ShangZhen_Jx_OnEvent(event)
	-- PushDebugMessage(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 29151601) then
		local nType = Get_XParam_INT(0)
		if nType == 1 then --打开上阵界面
			local targetId = Get_XParam_INT(1)
			m_targetId = targetId
			m_round = Get_XParam_INT(2)
			m_isStart = Get_XParam_INT(3)
			m_remainTime = Get_XParam_INT(4)
			local dataLength = Get_XParam_INT(5)
			m_upDataNameList = {}
			m_upDataHeadImageList = {}
			m_upDataMenPeiList = {}
			local addIntIndex = 6
			local addStrIndex = 0
			for index = 1, dataLength do
				local name = Get_XParam_STR(addStrIndex)
				addStrIndex = addStrIndex + 1
				local headImage = Get_XParam_INT(addIntIndex)
				addIntIndex = addIntIndex + 1
				local menPai = Get_XParam_INT(addIntIndex)
				addIntIndex = addIntIndex + 1
				m_upDataNameList[index] = name
				m_upDataHeadImageList[index] = headImage
				m_upDataMenPeiList[index] = menPai
			end
			if (this:IsVisible()) then
				BT_SeaMatch_ShangZhen_Jx_Update()
				return
			end
			g_ObjCareID = DataPool:GetNPCIDByServerID(targetId)
			BT_SeaMatch_ShangZhen_Jx_Show()
			BT_SeaMatch_ShangZhen_Jx_Update()
		elseif nType == 2 or --上阵成功刷新界面
			nType == 3 or --上阵数量达到刷新界面
			nType == 4 then  --下阵成功刷新界面
			if (this:IsVisible()) then
				m_round = Get_XParam_INT(1)
				m_isStart = Get_XParam_INT(2)
				m_remainTime = Get_XParam_INT(3)
				local dataLength = Get_XParam_INT(4)
				m_upDataNameList = {}
				m_upDataHeadImageList = {}
				m_upDataMenPeiList = {}
				local addIntIndex = 5
				local addStrIndex = 0
				for index = 1, dataLength do
					local name = Get_XParam_STR(addStrIndex)
					addStrIndex = addStrIndex + 1
					local headImage = Get_XParam_INT(addIntIndex)
					addIntIndex = addIntIndex + 1
					local menPai = Get_XParam_INT(addIntIndex)
					addIntIndex = addIntIndex + 1
					m_upDataNameList[index] = name
					m_upDataHeadImageList[index] = headImage
					m_upDataMenPeiList[index] = menPai
				end
				BT_SeaMatch_ShangZhen_Jx_Update()
				return
			end
		elseif nType == 5 then  --比赛开始刷新界面
			if (this:IsVisible()) then
				m_isStart = Get_XParam_INT(1)
				m_remainTime = Get_XParam_INT(2)
				BT_SeaMatch_ShangZhen_Jx_UpdateTime()
				BT_SeaMatch_ShangZhen_Jx_StartTimer()
				return
			end
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BT_SeaMatch_ShangZhen_Jx_Hide()
	elseif event == "ADJEST_UI_POS" then
		BT_SeaMatch_ShangZhen_Jx_ResetPos()
	elseif event == "OBJECT_CARED_EVENT" then
		BT_SeaMatch_ShangZhen_Jx_CareEvent(arg0,arg1,arg2)
	end
end

--显示UI
function BT_SeaMatch_ShangZhen_Jx_Show()
	BT_SeaMatch_ShangZhen_Jx_ClearData()
	this:CareObject(g_ObjCareID, 1, "BT_SeaMatch_ShangZhen_Jx");
	BT_SeaMatch_ShangZhen_Jx_StartTimer()

	this:Show()

end
function BT_SeaMatch_ShangZhen_Jx_AutoClick_Timer()
	if m_remainTime <= 0 then
		BT_SeaMatch_ShangZhen_Jx_Hide()
		PushEvent("UI_COMMAND", 1000)
		return
	end
	m_remainTime = m_remainTime - 1
	BT_SeaMatch_ShangZhen_Jx_UpdateTime()
end
--隐藏UI
function BT_SeaMatch_ShangZhen_Jx_Hide()
	BT_SeaMatch_ShangZhen_Jx_ClearData()

	this:Hide()
end

--清除数据
function BT_SeaMatch_ShangZhen_Jx_ClearData()
	KillTimer("BT_SeaMatch_ShangZhen_Jx_AutoClick_Timer()")
end
--更新
function BT_SeaMatch_ShangZhen_Jx_Update()
	if m_round == 3 then
		BT_SeaMatch_ShangZhen_Jx_Hide()
		return
	end
	BT_SeaMatch_ShangZhen_Jx_2:SetProperty("Image", "")
	if m_round == 1 then
		BT_SeaMatch_ShangZhen_Jx_2:SetProperty("Image", "set:BW_Match17 image:TwoVsTwo")
	elseif m_round == 2 then
		BT_SeaMatch_ShangZhen_Jx_2:SetProperty("Image", "set:BW_Match17 image:ThreeVsThree")
	elseif m_round == 4 then
		BT_SeaMatch_ShangZhen_Jx_2:SetProperty("Image", "set:BW_Match17 image:OneVsOne")
	end
	BT_SeaMatch_ShangZhen_Jx_HeadBK1:Hide()
	BT_SeaMatch_ShangZhen_Jx_XingMing_Text1:Hide()
	BT_SeaMatch_ShangZhen_Jx_MenPai_Text1:Hide()
	BT_SeaMatch_ShangZhen_Jx_KongQue_Text1:Hide()
	BT_SeaMatch_ShangZhen_Jx_HeadBK2:Hide()
	BT_SeaMatch_ShangZhen_Jx_XingMing_Text2:Hide()
	BT_SeaMatch_ShangZhen_Jx_MenPai_Text2:Hide()
	BT_SeaMatch_ShangZhen_Jx_KongQue_Text2:Hide()
	BT_SeaMatch_ShangZhen_Jx_HeadBK3:Hide()
	BT_SeaMatch_ShangZhen_Jx_XingMing_Text3:Hide()
	BT_SeaMatch_ShangZhen_Jx_MenPai_Text3:Hide()
	BT_SeaMatch_ShangZhen_Jx_KongQue_Text3:Hide()
	local fillIndex = 0
	if m_round == 1 or m_round == 2 then
		BT_SeaMatch_ShangZhen_Jx_HeadBK1:Show()
		fillIndex = fillIndex + 1
		if m_upDataNameList[fillIndex] == nil then
			BT_SeaMatch_ShangZhen_Jx_KongQue_Text1:Show()
			BT_SeaMatch_ShangZhen_Jx_Head1:SetProperty("Image", "")
		else
			BT_SeaMatch_ShangZhen_Jx_XingMing_Text1:Show()
			BT_SeaMatch_ShangZhen_Jx_MenPai_Text1:Show()
			if m_upDataNameList[fillIndex] == "" then
				BT_SeaMatch_ShangZhen_Jx_XingMing_Text1:SetText("离线")
				BT_SeaMatch_ShangZhen_Jx_MenPai_Text1:SetText("离线")
				BT_SeaMatch_ShangZhen_Jx_Head1:SetProperty("Image", "")
			else
				local portrait =  SJTX:LuaGetPortraitInfo(m_upDataHeadImageList[fillIndex])
				BT_SeaMatch_ShangZhen_Jx_Head1:SetProperty("Image", portrait)
				BT_SeaMatch_ShangZhen_Jx_XingMing_Text1:SetText("#c6a3906"..m_upDataNameList[fillIndex])
				BT_SeaMatch_ShangZhen_Jx_MenPai_Text1:SetText("#c6a3906"..m_MenPaiNameList[m_upDataMenPeiList[fillIndex]].Name)
			end
		end
	end
	if m_round == 2 or m_round == 4 then
		BT_SeaMatch_ShangZhen_Jx_HeadBK2:Show()
		fillIndex = fillIndex + 1
		if m_upDataNameList[fillIndex] == nil then
			BT_SeaMatch_ShangZhen_Jx_KongQue_Text2:Show()
			BT_SeaMatch_ShangZhen_Jx_Head2:SetProperty("Image", "")
		else
			BT_SeaMatch_ShangZhen_Jx_XingMing_Text2:Show()
			BT_SeaMatch_ShangZhen_Jx_MenPai_Text2:Show()
			if m_upDataNameList[fillIndex] == "" then
				BT_SeaMatch_ShangZhen_Jx_XingMing_Text2:SetText("离线")
				BT_SeaMatch_ShangZhen_Jx_MenPai_Text2:SetText("离线")
				BT_SeaMatch_ShangZhen_Jx_Head2:SetProperty("Image", "")
			else
				local portrait =  SJTX:LuaGetPortraitInfo(m_upDataHeadImageList[fillIndex])
				BT_SeaMatch_ShangZhen_Jx_Head2:SetProperty("Image", portrait)
				BT_SeaMatch_ShangZhen_Jx_XingMing_Text2:SetText("#c6a3906"..m_upDataNameList[fillIndex])
				BT_SeaMatch_ShangZhen_Jx_MenPai_Text2:SetText("#c6a3906"..m_MenPaiNameList[m_upDataMenPeiList[fillIndex]].Name)
			end
		end
	end
	if m_round == 1 or m_round == 2 then
		BT_SeaMatch_ShangZhen_Jx_HeadBK3:Show()
		fillIndex = fillIndex + 1
		if m_upDataNameList[fillIndex] == nil then
			BT_SeaMatch_ShangZhen_Jx_KongQue_Text3:Show()
			BT_SeaMatch_ShangZhen_Jx_Head3:SetProperty("Image", "")
		else
			BT_SeaMatch_ShangZhen_Jx_XingMing_Text3:Show()
			BT_SeaMatch_ShangZhen_Jx_MenPai_Text3:Show()
			if m_upDataNameList[fillIndex] == "" then
				BT_SeaMatch_ShangZhen_Jx_XingMing_Text3:SetText("离线")
				BT_SeaMatch_ShangZhen_Jx_MenPai_Text3:SetText("离线")
				BT_SeaMatch_ShangZhen_Jx_Head3:SetProperty("Image", "")
			else
				local portrait =  SJTX:LuaGetPortraitInfo(m_upDataHeadImageList[fillIndex])
				BT_SeaMatch_ShangZhen_Jx_Head3:SetProperty("Image", portrait)
				BT_SeaMatch_ShangZhen_Jx_XingMing_Text3:SetText("#c6a3906"..m_upDataNameList[fillIndex])
				BT_SeaMatch_ShangZhen_Jx_MenPai_Text3:SetText("#c6a3906"..m_MenPaiNameList[m_upDataMenPeiList[fillIndex]].Name)
			end
		end
	end
	BT_SeaMatch_ShangZhen_Jx_UpdateTime()
end

--更新
function BT_SeaMatch_ShangZhen_Jx_StartTimer()
	if m_isStart >= 1 then
		BT_SeaMatch_ShangZhen_Jx_ClearData()
		SetTimer("BT_SeaMatch_ShangZhen_Jx", "BT_SeaMatch_ShangZhen_Jx_AutoClick_Timer()", 1000)
	end
end

--更新
function BT_SeaMatch_ShangZhen_Jx_UpdateTime()
	if m_isStart >= 1 then
		BT_SeaMatch_ShangZhen_Jx_StageBK_Text:SetText(ScriptGlobal_Format("#{JHS32_181117_69}", m_remainTime))
	else
		BT_SeaMatch_ShangZhen_Jx_StageBK_Text:SetText( "#{DFSZ_190613_136}" )
	end
end
--##############点击事件##############
function BT_SeaMatch_ShangZhen_Jx_ClickClose()
	BT_SeaMatch_ShangZhen_Jx_Hide()
end
--我要上阵
function BT_SeaMatch_ShangZhen_Jx_ClickOk()
	-- PushDebugMessage("BT_SeaMatch_ShangZhen_Jx_ClickOk")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientJoinUpMatch")
		Set_XSCRIPT_ScriptID( 291516 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
--取消上阵
function BT_SeaMatch_ShangZhen_Jx_ClickCancel()
	-- PushDebugMessage("BT_SeaMatch_ShangZhen_Jx_ClickCancel")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientLeaveUpMatch")
		Set_XSCRIPT_ScriptID( 291516 )
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
--####################################

--以下是用户自定义的函数
function BT_SeaMatch_ShangZhen_Jx_CareEvent(arg0,arg1,arg2)
	local ObjCaredID = tonumber(arg0)
	if( ObjCaredID ~= g_ObjCareID) then
		return
	end
	local ObjDistance = tonumber(arg2)
	if( (arg1 == "distance" and ObjDistance>MAX_OBJ_DISTANCE) or arg1=="destroy") then
		BT_SeaMatch_ShangZhen_Jx_Hide()
	end
end