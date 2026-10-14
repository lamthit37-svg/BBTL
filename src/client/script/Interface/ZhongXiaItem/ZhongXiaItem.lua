--- 新仲夏节气界面 界面重构，原界面废弃
--- 虽然命名都还带有Item，但是已经和道具没有关系了
--- Author: lishilong 2016-6-1
--!!!reloadscript =ZhongXiaItem

local g_ZhongXiaItem_UICommand = 20160602
local g_ZhongXiaItem_Path_UICommand = 20160604

local g_UIServerScript = 891920
local g_ZhongXiaItem_Frame_UnifiedPosition

--最大祈福数量
local g_MaxPrayNum = 6			--最大祈福数量
local g_ActivateSeason_Need	= 3				-- 凝聚需要的蒲风雪

-- 节气数量
local g_MaxSeasonNum = 6
local g_ZhongXia_Season_Msg = {
    [1] = { TipMsg ="" , 	TipMsgDic = "#{ZXJQ_120516_47}", CostValue = 3 },
    [2] = { TipMsg ="" , 	TipMsgDic = "#{ZXJQ_120516_48}", CostValue = 6 },
    [3] = { TipMsg ="" , 	TipMsgDic = "#{ZXJQ_120516_49}", CostValue = 9 },
    [4] = { TipMsg ="" , 	TipMsgDic = "#{ZXJQ_120516_50}", CostValue = 12 },
    [5] = { TipMsg ="" , 	TipMsgDic = "#{ZXJQ_120516_51}", CostValue = 15 },
    [6] = { TipMsg ="" , 	TipMsgDic = "#{ZXJQ_120516_52}", CostValue = 18 },
}

local g_ZhongXia_Season_Button_Locked = {}
local g_ZhongXia_Season_Button_Iced = {}
local g_ZhongXia_Season_Button_BianZhi = {}
local g_ZhongXia_Season_Tips = {}



function ZhongXiaItem_PreLoad()
    this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function ZhongXiaItem_OnLoad()
    g_ZhongXiaItem_Frame_UnifiedPosition = ZhongXiaItem_FrameNULL:GetProperty("UnifiedPosition")
	
	g_ZhongXia_Season_Button_Locked[1] = ZhongXiaItem_Active_1_Locked
	g_ZhongXia_Season_Button_Locked[2] = ZhongXiaItem_Active_2_Locked
	g_ZhongXia_Season_Button_Locked[3] = ZhongXiaItem_Active_3_Locked
	g_ZhongXia_Season_Button_Locked[4] = ZhongXiaItem_Active_4_Locked
	g_ZhongXia_Season_Button_Locked[5] = ZhongXiaItem_Active_5_Locked
	g_ZhongXia_Season_Button_Locked[6] = ZhongXiaItem_Active_6_Locked
	
	g_ZhongXia_Season_Button_Iced[1] = ZhongXiaItem_Active_1_Iced
	g_ZhongXia_Season_Button_Iced[2] = ZhongXiaItem_Active_2_Iced
	g_ZhongXia_Season_Button_Iced[3] = ZhongXiaItem_Active_3_Iced
	g_ZhongXia_Season_Button_Iced[4] = ZhongXiaItem_Active_4_Iced
	g_ZhongXia_Season_Button_Iced[5] = ZhongXiaItem_Active_5_Iced
	g_ZhongXia_Season_Button_Iced[6] = ZhongXiaItem_Active_6_Iced
	
	g_ZhongXia_Season_Button_BianZhi[1] = ZhongXiaItem_Active_1_Null
	g_ZhongXia_Season_Button_BianZhi[2] = ZhongXiaItem_Active_2_Null
	g_ZhongXia_Season_Button_BianZhi[3] = ZhongXiaItem_Active_3_Null
	g_ZhongXia_Season_Button_BianZhi[4] = ZhongXiaItem_Active_4_Null
	g_ZhongXia_Season_Button_BianZhi[5] = ZhongXiaItem_Active_5_Null
	g_ZhongXia_Season_Button_BianZhi[6] = ZhongXiaItem_Active_6_Null
	
	g_ZhongXia_Season_Tips[1] = ZhongXiaItem_Tips_1
	g_ZhongXia_Season_Tips[2] = ZhongXiaItem_Tips_2
	g_ZhongXia_Season_Tips[3] = ZhongXiaItem_Tips_3
	g_ZhongXia_Season_Tips[4] = ZhongXiaItem_Tips_4
	g_ZhongXia_Season_Tips[5] = ZhongXiaItem_Tips_5
	g_ZhongXia_Season_Tips[6] = ZhongXiaItem_Tips_6
end

function ZhongXiaItem_OnEvent(event)
    if ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_ZhongXiaItem_UICommand then
		local bShow = Get_XParam_INT(0)
		if 1 == bShow then
			ZhongXia_OnShow()
		else
			ZhongXia_OnClosed()
		end
		
	elseif ( event == "UI_COMMAND" ) and tonumber( arg0 ) == g_ZhongXiaItem_Path_UICommand then
		ZhongXia_AutoPathNPC()
		
	elseif event == "HIDE_ON_SCENE_TRANSED"  then
		ZhongXia_OnClosed()
		
	elseif (event == "ADJEST_UI_POS" ) then
		ZhongXiaItem_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZhongXiaItem_On_ResetPos()
	end
end

function ZhongXia_OnShow()
	-- 服务器参数
	-- 参数1：节气值，参数2：最大节气值，参数3：激活节气数，参数4：最大激活节气数，参数5：祈福次数
	local nSeasonValue 			= Get_XParam_INT(1)
	local nMaxSeasonValue		= Get_XParam_INT(2)
	local nActivatedSeason		= Get_XParam_INT(3)
	local nMaxActivatedSeason	= Get_XParam_INT(4)
	local nPrayNum				= Get_XParam_INT(5)
	
	-- 节气值显示
	local strMsg = ScriptGlobal_Format("#{ZXJQ_120516_45}", nSeasonValue, nMaxSeasonValue)
	ZhongxiaItem_Valuetext : SetText(strMsg)
	
	--激活节气数量显示
	local strMsg = ScriptGlobal_Format("#{ZXJQ_120516_72}", nActivatedSeason)
	ZhongxiaItem_Seasontext : SetText(strMsg)
	
	-- 祈福按钮
	if nPrayNum < 1 then
		local kjtype   = KaJi:LuaFnGetKaJiType(88)
		if kjtype == 0 then	
			ZhongXiaItem_Button2 : SetToolTip( "#{ZXJQ_120516_84}" )
		else
			ZhongXiaItem_Button2 : SetToolTip( "#{ZXJQ_210512_21}" )
		end
		
		ZhongXiaItem_Button2 : Enable()

	elseif g_MaxPrayNum == nPrayNum then
		ZhongXiaItem_Button2 : Disable()
		
	else
		local kjtype   = KaJi:LuaFnGetKaJiType(88)
		if kjtype == 0 then	
			local strMsg = ScriptGlobal_Format("#{ZXJQ_120516_85}", nPrayNum)
			ZhongXiaItem_Button2 : SetToolTip( strMsg )
		else
			local strMsg = ScriptGlobal_Format("#{ZXJQ_210512_22}", nPrayNum)
			ZhongXiaItem_Button2 : SetToolTip( strMsg )
		end
		
		ZhongXiaItem_Button2 : Enable()
	end
	
	if nPrayNum < nActivatedSeason then
		ZhongXiaItem_Button2_Tips:Show()
	else
		ZhongXiaItem_Button2_Tips:Hide()
	end
	
	-- 凝聚按钮
	local nCanActNum = math.floor(nSeasonValue / g_ActivateSeason_Need)
	if nCanActNum > nActivatedSeason then
		ZhongXiaItem_Button1 : SetToolTip( "#{ZXJQ_120516_55}" )
		ZhongXiaItem_Button1_Tips : Show()
			
	else
		ZhongXiaItem_Button1 : SetToolTip( "#{ZXJQ_210512_19}" )
		ZhongXiaItem_Button1_Tips : Hide()
	end
	
	--	冰盆环绕高亮特效
	if g_MaxPrayNum == nPrayNum then
		ZhongXiaItem_BKG : Show() --未激活
		ZhongXiaItem_BKG2 : Hide()
		
		ZhongXiaItem_Tips_7 : Show()
	else
		ZhongXiaItem_Tips_7 : Hide()
		if nActivatedSeason == g_MaxSeasonNum then
			ZhongXiaItem_BKG : Hide()
			ZhongXiaItem_BKG2 : Show() --已激活高亮
		else
			ZhongXiaItem_BKG : Show()
			ZhongXiaItem_BKG2 : Hide() --已激活高亮
		end
	end
	
	-- 茉莉花、菱角、甜瓜、清藕、鱼脍、美酒
	for i=1, table.getn(g_ZhongXia_Season_Button_Locked) do
	
		if i <= nActivatedSeason then
			g_ZhongXia_Season_Button_Locked[i] : Hide()
			g_ZhongXia_Season_Button_Iced[i] : Show() --已凝冰
			g_ZhongXia_Season_Button_BianZhi[i] : Hide()
			g_ZhongXia_Season_Tips[i] : Hide()
		else
			g_ZhongXia_Season_Button_Locked[i] : Show()
			g_ZhongXia_Season_Button_Iced[i] : Hide() --已凝冰
			g_ZhongXia_Season_Button_BianZhi[i] : Hide()
				
			g_ZhongXia_Season_Tips[i] : Show()
			local tips = ScriptGlobal_Format(g_ZhongXia_Season_Msg[i].TipMsgDic, g_ZhongXia_Season_Msg[i].CostValue)
			g_ZhongXia_Season_Tips[i] : SetToolTip( tips )
		end
	end
	
	this:Show()
end


function ZhongXia_OnPray()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnPray")
		Set_XSCRIPT_ScriptID(g_UIServerScript)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function ZhongXia_OnActivate()
    Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnActivate")
	Set_XSCRIPT_ScriptID(g_UIServerScript)
	Send_XSCRIPT()
end

function ZhongXia_OnClosed()
	this:Hide()
end

function ZhongXiaItem_On_ResetPos()
    ZhongXiaItem_FrameNULL:SetProperty("UnifiedPosition", g_ZhongXiaItem_Frame_UnifiedPosition)
end

--*****************************************
--自动寻路
--*****************************************
function ZhongXia_AutoPathNPC()
	
	AutoRunToTargetEx(367, 163, 1)
	SetAutoRunTargetNPCName("祈福台")
	
end

function ZhongXiaItem_Help_Click()
	if Player:GetData("IsOriginalJD") == 1 then
		PushEvent( "OPEN_HUODONGTEXT_HELP", "ZhongXiaItem_Help", "#{ZXJQ_260629_01}" )
		return
	end
	
	local kjtype   = KaJi:LuaFnGetKaJiType(88)
	if kjtype == 0 then	
		PushEvent( "OPEN_HUODONGTEXT_HELP", "ZhongXiaItem_Help", "#{ZXJQ_120516_77}" )
	else
		PushEvent( "OPEN_HUODONGTEXT_HELP", "ZhongXiaItem_Help", "#{ZXJQ_210512_20}" )
	end
	
end

