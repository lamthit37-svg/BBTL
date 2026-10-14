-- WildBoss_Info 野外Boss信息 2024-8-20 lishilong
-- !!!reloadscript =WildBoss_Info
--

local g_WildBoss_Info_Frame_UnifiedPosition
-- local g_WildBoss_Info_Frame_UnifiedXPosition
-- local g_WildBoss_Info_Frame_UnifiedYPosition
local MAX_OBJ_DISTANCE 		= 3.0
local g_nObjCaredIDClient 	= -1
local g_nServerObjID 		= -1
local bCaredItem 			= 0
local bCaredObj 			= 0
local bCaredMoney 			= 0
local bCaredYuanBao			= 0
local g_nComfirmParam1		= 0


local g_bShowAll			= 0
local g_nBossFullHPPercent	= 100
local g_nMiniShowYDec		= 150
local g_nShowTeamNum		= 3
local g_cTeamName			= {}
local g_cTeamDamage			= {}

-- 索引是场景的ServerID
local g_tBossInfoByScene	= 
{
	-- 千年冰魄 
	[32] 	= {strPosInfo = "#{YFYW_240806_27}", },

	-- 白明启
	[20] 	= {strPosInfo = "#{YFYW_240806_25}", },

	-- 玄击金刚
	[25] 	= {strPosInfo = "#{YFYW_240806_26}", },

	-- 毒蛤王
	[39] 	= {strPosInfo = "#{YFYW_240806_24}", },

	-- 镜湖六霸
	[5] 	= {strPosInfo = "#{YFYW_240806_28}", },
}
-- local g_nUICommandID		= 79003501

--=========================================================
-- PreLoad
--=========================================================
function WildBoss_Info_PreLoad()
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
	this:RegisterEvent("UPDATE_YWBOSS_INFO");
end

--=========================================================
-- OnLoad
--=========================================================
function WildBoss_Info_OnLoad()
	g_WildBoss_Info_Frame_UnifiedPosition = WildBoss_Info_Frame:GetProperty("UnifiedPosition")

	-- g_WildBoss_Info_Frame_UnifiedXPosition	= WildBoss_Info_Frame:GetProperty("UnifiedXPosition");
	-- g_WildBoss_Info_Frame_UnifiedYPosition	= WildBoss_Info_Frame:GetProperty("UnifiedYPosition");

	g_cTeamName[1]		= WildBoss_Info_Team1NameText
	g_cTeamName[2]		= WildBoss_Info_Team2NameText
	g_cTeamName[3]		= WildBoss_Info_Team3NameText

	g_cTeamDamage[1]	= WildBoss_Info_Team1DamageText
	g_cTeamDamage[2]	= WildBoss_Info_Team2DamageText
	g_cTeamDamage[3]	= WildBoss_Info_Team3DamageText

	-- WildBoss_Info_OK_Button : SetEvent("Clicked", "WildBoss_Info_ConfirmClick()")
end

--=========================================================
-- OnEvent
--=========================================================
function WildBoss_Info_OnEvent(event)
	if event == "UPDATE_YWBOSS_INFO" then

		-- 显示界面
		-- 为了解决界面被遮挡的问题，先把界面关了
		if this:IsVisible() then
			-- WildBoss_Info_OnClose()
		else
			g_bShowAll = 1
		end
		WildBoss_Info_Reset()
		-- WildBoss_Info_Frame_On_ResetPos()
		this:Show()
		WildBoss_Info_ParamInit()
		WildBoss_Info_MoneyUpdate()
		WildBoss_Info_YuanBaoUpdate()
		WildBoss_Info_Update(1)

	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_nObjCaredIDClient) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			WildBoss_Info_OnClose()
		end	

	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() and 1 == bCaredItem ) then
		-- 刷新界面
		if this:IsVisible() then
			WildBoss_Info_Update(0)
		end

	-- 金钱改变
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and 1 == bCaredMoney then
		WildBoss_Info_MoneyUpdate()

	-- 元宝改变
	elseif event == "UPDATE_YUANBAO" and 1 == bCaredYuanBao then
		WildBoss_Info_YuanBaoUpdate()

	elseif event == "HIDE_ON_SCENE_TRANSED" then
		WildBoss_Info_OnClose()
	
	elseif (event == "ADJEST_UI_POS" ) then
		WildBoss_Info_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WildBoss_Info_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function WildBoss_Info_ParamInit()
	local nServerObjID 	= Get_XParam_INT(1)
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function WildBoss_Info_OnComfirmedBack(strRet)
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
-- !!!reloadscript =WildBoss_Info
function WildBoss_Info_Update(bOpen)

	local nCurBossShamHpPercent100 = DataPool : Lua_GetBossShamHpPercent100()
	local nCurYwBossMonsterDataId = DataPool : Lua_GetShamHpBossDataId()
	local strBossName = TServerUI:GetMonsterNamebyDataID(nCurYwBossMonsterDataId)

	-- 界面标题
	WildBoss_Info_DragTitle : SetText( ScriptGlobal_Format("#{YFYW_240806_5}", strBossName ))

	-- 是否最小化
	if 1 == g_bShowAll then
		WildBoss_Info_MainClient : Show()
		WildBoss_Info_Frame : SetProperty("AbsoluteSize", "w:320 h:204");
	else
		WildBoss_Info_MainClient : Hide()
		WildBoss_Info_Frame : SetProperty("AbsoluteSize", "w:320 h:30");
	end

	WildBoss_Info_InfoBK_Client1 : Hide()
	WildBoss_Info_InfoBK_Client2 : Hide()
	WildBoss_Info_InfoBK_Client3 : Hide()
	-- WildBoss_Info_InfoBK_Client4 : Hide()

	-- Boss满血状态
	-- if nCurBossShamHpPercent100 >= g_nBossFullHPPercent then
	-- 	WildBoss_Info_InfoBK_Client1 : Show()
	-- end

	-- Boss死了
	if nCurBossShamHpPercent100 <= 0 then
		WildBoss_Info_InfoBK_Client3 : Show()
		-- Boss状态显示
		WildBoss_Info_EndText : SetText( ScriptGlobal_Format("#{YFYW_240806_9}", strBossName ))
		local nTeamId, nDamage, strShowName = DataPool : Lua_GetBossDamageInfoByIndex(0)
		if nil == nTeamId or nTeamId < 0 then				
			WildBoss_Info_WinnerText : SetText( "#{YFYW_240806_21}")
		else
			if "" == strShowName then
				-- WildBoss_Info_WinnerText : SetText( "#{}")
				-- WildBoss_Info_WinnerText : SetText( "#{YFYW_240806_21}")
				WildBoss_Info_WinnerText : SetText( ScriptGlobal_Format("#{YFYW_240806_10}", "#{YFYW_240806_40}" ))			
			else
				WildBoss_Info_WinnerText : SetText( ScriptGlobal_Format("#{YFYW_240806_10}", strShowName ))
			end
		end
	end

	-- Boss活着
	if nCurBossShamHpPercent100 > 0 then
		WildBoss_Info_InfoBK_Client2 : Show()

		-- Boss状态显示
		local strBossPosInfo = g_tBossInfoByScene[GetSceneServerID()]
		if nil ~= strBossPosInfo then
			WildBoss_Info_InBattleText : SetText( ScriptGlobal_Format("#{YFYW_240806_7}", strBossName, strBossPosInfo.strPosInfo ))
		end
		
		for i = 1, g_nShowTeamNum do
			local nTeamId, nDamage, strShowName = DataPool : Lua_GetBossDamageInfoByIndex(i -1)
			if nil == nTeamId or nTeamId < 0 then				
				g_cTeamName[i] : SetText( "#{YFYW_240806_16}")
				g_cTeamDamage[i] : SetText( ScriptGlobal_Format("#{YFYW_240806_17}", 0 ))
			else
				if "" == strShowName then
					g_cTeamName[i] : SetText( "#{YFYW_240806_30}")
				else
					g_cTeamName[i] : SetText( ScriptGlobal_Format("#{YFYW_240806_17}", strShowName ))
				end
				g_cTeamDamage[i] : SetText( ScriptGlobal_Format("#{YFYW_240806_17}", nDamage ))
			end
		end	
	end

	-- 个人信息
	-- 注意！！！ 后面不要再写逻辑了，这段逻辑比较绕 中间有些逻辑直接 return 了
	-- 队伍排名
	WildBoss_Info_MyTeamText : Hide()
	-- 队伍名字 固定叫我的队伍
	WildBoss_Info_MyTeamNameText : Hide()
	-- 队伍伤害
	WildBoss_Info_MyTeamDamageText : Hide()
	-- 未参与的提示
	WildBoss_Info_OtherText : Show()

	-- 默认信息 有队伍没伤害或者伤害未上榜
	WildBoss_Info_OtherText : SetText( "#{YFYW_240806_23}")

	local nTotalRecordNum = DataPool : Lua_GetBossDamageInfoCount()
	local nMyTeamId, nMyDamage, strMyShowName = DataPool : Lua_GetBossDamageInfoByIndex(nTotalRecordNum -1)
	-- 策划改了需求，懒得扩了，借用TeamId来传了伤害排名
	-- -2 表示没上榜 -1 表示没有队伍 > 0 表示排名

	-- 未组队
	if nil ~= nMyTeamId and -1 == nMyTeamId then
		WildBoss_Info_OtherText : SetText( ScriptGlobal_Format("#{YFYW_240806_22}", strBossName ))
		return
	end

	-- -- 队伍排名：大于20名YFYW_240806_23
	-- WildBoss_Info_MyTeamText : SetText( "#{YFYW_240806_23}")

	-- 有排名 显示排名
	if nil ~= nMyTeamId and nMyTeamId > 0 then
		-- 未参与的提示
		WildBoss_Info_OtherText : Hide()
		-- 队伍排名
		WildBoss_Info_MyTeamText : Show()
		-- 队伍名字 固定叫我的队伍
		WildBoss_Info_MyTeamNameText : Show()
		-- 队伍伤害
		WildBoss_Info_MyTeamDamageText : Show()
		-- WildBoss_Info_MyTeamText : SetText( ScriptGlobal_Format("#{YFYW_240806_8}", nMyTeamId ))
		WildBoss_Info_MyTeamText : SetText( nMyTeamId)
		WildBoss_Info_MyTeamDamageText : SetText( ScriptGlobal_Format("#{YFYW_240806_17}", nMyDamage ))
	end

	-- 没伤害 显示没参与
	-- if nil ~= nMyDamage and nMyDamage == 0 then
	-- 	WildBoss_Info_MyTeamText : SetText( "#{YFYW_240806_29}")
	-- end
	
end

--=========================================================
-- 重置界面
--=========================================================
function WildBoss_Info_Reset()

end

--=========================================================
-- 帮助
--=========================================================
function WildBoss_Info_Help_Clicked()
	local nCurYwBossMonsterDataId = DataPool : Lua_GetShamHpBossDataId()
	-- PushDebugMessage("nCurYwBossMonsterDataId"..nCurYwBossMonsterDataId)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIClickHelp" )
		Set_XSCRIPT_ScriptID(810111)
		Set_XSCRIPT_Parameter(0, nCurYwBossMonsterDataId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========================================================
-- 最小化
--=========================================================
function WildBoss_Info_CloseClicked()
	if 1 == g_bShowAll then
		g_bShowAll = 0
	else
		g_bShowAll = 1
	end
	WildBoss_Info_Update(1)
end

-- --=========================================================
-- -- 界面确认按钮
-- --=========================================================
-- function WildBoss_Info_ConfirmClick()
-- 	Clear_XSCRIPT()
-- 		Set_XSCRIPT_Function_Name( "OnUIEvent" )
-- 		Set_XSCRIPT_ScriptID(060225)
-- 		Set_XSCRIPT_Parameter(0, 2)					
-- 		Set_XSCRIPT_Parameter(1, 1)				
-- 		Set_XSCRIPT_ParamCount(2)
-- 	Send_XSCRIPT()
-- end

--=========================================================
-- 关闭界面
--=========================================================
function WildBoss_Info_OnClose()	
	this:Hide()
	StopCareObject_WildBoss_Info()
	-- 重置
	WildBoss_Info_Reset()
end

--=========================================================
-- 界面隐藏
-- <Event Name="Hidden" Function="WildBoss_Info_OnHidden();" />
--=========================================================
function WildBoss_Info_OnHidden()
	StopCareObject_WildBoss_Info()
	-- 重置
	WildBoss_Info_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_WildBoss_Info()
	-- 关心
	this:CareObject(g_nObjCaredIDClient, 1, "WildBoss_Info")
end

function StopCareObject_WildBoss_Info()
	-- 取消关心
	if nil ~= g_nObjCaredIDClient and g_nObjCaredIDClient > 0 then
		this:CareObject(g_nObjCaredIDClient, 0, "WildBoss_Info")
	end
	g_nServerObjID = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function WildBoss_Info_MoneyUpdate()
	-- WildBoss_Info_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	-- WildBoss_Info_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
-- 元宝刷新：界面更新调用一次 元宝事件调用一次
--=========================================================
function WildBoss_Info_YuanBaoUpdate()
	-- WildBoss_Info_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--=========================================================
-- 界面位置
--=========================================================
function WildBoss_Info_Frame_On_ResetPos()
	WildBoss_Info_Frame:SetProperty("UnifiedPosition", g_WildBoss_Info_Frame_UnifiedPosition)

	-- WildBoss_Info_Frame:SetProperty("UnifiedXPosition", g_WildBoss_Info_Frame_UnifiedXPosition);
	-- WildBoss_Info_Frame:SetProperty("UnifiedYPosition", g_WildBoss_Info_Frame_UnifiedYPosition);

end