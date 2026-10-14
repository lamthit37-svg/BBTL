-- 2018Q4春节引导任务-任务总界面

local g_Frame_UnifiedPosition

--任务界面阶段
--1：引导任务执行界面 or 2：春节第一阶段界面
--2：春节第二阶段界面
--3：春节第三阶段界面
local g_CurPage = -1
local g_CurStep = -1
local g_PageCount = 3

--任务号
local g_MissionId1 = 1909
local g_MissionId2 = 1910
local g_MissionId3 = 1911
local g_MissionId4 = 1912
local g_MissionId5 = 1913
local g_MissionId6 = 1914

--活动时间
local g_StartDay = 20210125	--第一阶段：20210125-20210207
local g_MidDay1 = 20210207	--第二阶段：20210208-20210218
local g_MidDay2 = 20210218	--第二阶段：20210208-20210218
local g_MidDay3 = 20210219	--第三阶段：20210219-20210314
local g_EndDay = 20210314

local g_SecDay = 20210125--20210128-20200106	-- 巅峰赛联动延后开始日期

--活动按钮小红点
local g_RedPointInfo = {}

--活动页签
local g_PageButton = {}

--npc关闭
local g_ObjCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

-- 活动等级限制
local g_LimitLevel = 30

--显隐列表
local g_ButtonShowList = {}
local g_2019Q4_isOpen = 1	--  2019Q4活动UI显示的开关
local g_2019Q4_isFstStart = 1		-- 是否开始第一阶段第一次更新 2021.01.25
local g_2019Q4_isFst_SecStart = 1	-- 是否启动第一阶段的第二次更新 2021.01.28
local g_2019Q4_isFst_ThdStart = 1	-- 是否启动第一阶段得第三次更新	2021.02.01
local g_2019Q4_isSecStart = 1		-- 是否启动第二阶段 2021.02.08
local g_2019Q4_isThdStart = 1		-- 是否启动第三阶段，目前默认不用管 2021.02.18
local g_2019Q4_isThd_SecStart = 1		-- 是否启动第三阶段的第二次更新，目前默认不用管 2021.02.25
local g_Tween_Page = 0
local g_Tween_PosX = 1048
local g_Tween_PosX_Sec = 1137
local g_Tween_Playing = 0
local from_to_info1 = string.format("curve:Liner mode:Once duration:1.5 startx:0 starty:0 endx:-%s endy:0",g_Tween_PosX)
local from_to_info2 = string.format("curve:Liner mode:Once duration:1.5 startx:0 starty:0 endx:%s endy:0",g_Tween_PosX)
local from_to_info3 = string.format("curve:Liner mode:Once duration:1.5 startx:0 starty:0 endx:-%s endy:0",g_Tween_PosX_Sec)
local from_to_info4 = string.format("curve:Liner mode:Once duration:1.5 startx:0 starty:0 endx:%s endy:0",g_Tween_PosX_Sec)
--=========
-- PreLoad
--=========
function SpringFestival_Guide_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("CLOSE_SPRINGFES_GUIDE", false);

end

--=========
-- OnLoad
--=========
function SpringFestival_Guide_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_Guide_Frame:GetProperty("UnifiedPosition") 
	g_PageButton = 
	{
		{ btn = {SpringFestival_Guide_Buttontab01}, tips = {SpringFestival_Guide_Buttontab01_Tips}, },
		{ btn = {SpringFestival_Guide_Buttontab02L,SpringFestival_Guide_Buttontab02R}, tips = {SpringFestival_Guide_Buttontab02L_Tips,SpringFestival_Guide_Buttontab02R_Tips}, },
		{ btn = {SpringFestival_Guide_Buttontab03}, tips = {SpringFestival_Guide_Buttontab03_Tips}, },
	}
	
	g_RedPointInfo = 
	{
	--引导任务阶段特殊处理
		{ page = 1, btn = nil, 		tips = nil, 		nScriptID = 892985, 	nUICommandID = 89298501, bShow = 0, },			--引导任务阶段仅控制主界面小红点
	--春节第一阶段界面
		{ page = 1, btn = SpringFestival_Guide_YuReBtn, tips = SpringFestival_Guide_YuReBtn_Tips, nScriptID = -1, nUICommandID = -1, bShow = 0, }, --新增：春节预热活动设计--2020新增
		{ page = 1, btn = SpringFestival_Guide_HuameiBtn, tips = SpringFestival_Guide_HuameiBtn_Tips, nScriptID = 892655, nUICommandID = 89265501, bShow = 0, }, --画梅--2020重开-朔雪寻梅
		{ page = 1, btn = SpringFestival_Guide_QianLiBtn, tips = SpringFestival_Guide_QianLiBtn_Tips, nScriptID = 888331, nUICommandID = 88833102, bShow = 0, }, --新增：千里江山图鉴--2020新增
		{ page = 1, btn = SpringFestival_Guide_LiChengBtn, tips = SpringFestival_Guide_LiChengBtn_Tips, nScriptID = 888333, nUICommandID = 88833301, bShow = 0, }, --新增：里程暴击--2020新增
		{ page = 1, btn = SpringFestival_Guide_DaSongBtn, tips = SpringFestival_Guide_DaSongBtn_Tips, nScriptID = 888326, nUICommandID = 20122901, bShow = 0, }, --新增：春行大宋--2020新增
		{ page = 1, btn = SpringFestival_Guide_RiliBtn, tips = SpringFestival_Guide_RiliBtn_Tips, nScriptID = 890801, nUICommandID = 89080102, bShow = 0, }, --日历--2020重开-千秋辞岁
		{ page = 1, btn = SpringFestival_Guide_ZhuanpanBtn, tips = SpringFestival_Guide_ZhuanpanBtn_Tips, nScriptID = 890803, nUICommandID = 89080302, bShow = 0, }, --转盘--2020重开-竹爆平安
		{ page = 1, btn = SpringFestival_Guide_LicaiBtn, tips = SpringFestival_Guide_LicaiBtn_Tips, nScriptID = 893324, nUICommandID = 89332400, bShow = 0, }, --理财--2020重开-经财有时
		{ page = 1, btn = SpringFestival_Guide_WXH5Btn, tips = SpringFestival_Guide_WXH5Btn_Tips, nScriptID = 893335, nUICommandID = 89333502, bShow = 0, }, --新增：春节微信活动游戏内部分--2020重开-参考年货急速运--
		{ page = 1, btn = SpringFestival_Guide_GiftgBtn, tips = SpringFestival_Guide_GiftgBtn_Tips, nScriptID = 888328, nUICommandID = 88832802, bShow = 0, }, --节日礼包--2020新增
		--春节第二阶段界面
		{ page = 2, btn = SpringFestival_Guide_DaNianshouBtn, tips = SpringFestival_Guide_DaNianshouBtn_Tips, nScriptID = 892662, nUICommandID = 89266201, bShow = 0, }, --打年兽--2020重开-戏年兽
		{ page = 2, btn = SpringFestival_Guide_FeastBtn, tips = SpringFestival_Guide_FeastBtn_Tips, nScriptID = 892660, nUICommandID = 89266202, bShow = 0, }, --团圆宴--2020重开-团圆宴
		{ page = 2, btn = SpringFestival_Guide_ShanZhuangBtn, tips = SpringFestival_Guide_ShanZhuangBtn_Tips, nScriptID = 893351, nUICommandID = 89335102, bShow = 0, }, --春节微信--2020重开-与师有约
	--春节第三阶段界面		
		{ page = 3, btn = SpringFestival_Guide_RiddleBtn, tips = SpringFestival_Guide_RiddleBtn_Tips, nScriptID = 892384, nUICommandID = 89238400, bShow = 0, }, --猜灯谜--2020重开-花灯隐语
		{ page = 3, btn = SpringFestival_Guide_PigBtn, tips = SpringFestival_Guide_PigBtn_Tips, nScriptID = 892980, nUICommandID = 89298008, bShow = 0, }, --猜金猪--2020重开-三仙归位
		{ page = 3, btn = SpringFestival_Guide_ShootBtn, tips = SpringFestival_Guide_ShootBtn_Tips, nScriptID = 893021, nUICommandID = 89302126, bShow = 0, }, --射箭--2020重开-神射竞春
		{ page = 3, btn = SpringFestival_Guide_MiaohuiShopBtn, tips = SpringFestival_Guide_MiaohuiShopBtn_Tips, nScriptID = 890712, nUICommandID = 89071204, bShow = 0, }, --庙会商店--2020重开-百戏集市
		{ page = 3, btn = SpringFestival_Guide_AuctionBtn, tips = SpringFestival_Guide_AuctionBtn_Tips, nScriptID = -1, nUICommandID = -1, bShow = 0, }, --鬼市拍卖--2020重开-银锤金案
		{ page = 3, btn = SpringFestival_Guide_DividendBtn, tips = SpringFestival_Guide_DividendBtn_Tips, nScriptID = -1, nUICommandID = -1, bShow = 0, }, --拍卖分红--2020重开-朱门传裕
		{ page = 3, btn = SpringFestival_Guide_SignBtn, tips = SpringFestival_Guide_SignBtn_Tips, nScriptID = 893336, nUICommandID = 89333602, bShow = 0, }, --预热--2020重开-东风夜放
		{ page = 3, btn = SpringFestival_Guide_LicaiPao, tips = SpringFestival_Guide_LicaiPao, nScriptID = 893325, nUICommandID = 89332500, bShow = 0, }, --理财提示按钮--2020重开-经财有时
	}
	
	g_ButtonShowList = {
		--春节第一阶段界面
		{ page = 1, btn = SpringFestival_Guide_YuReBtn, starttime = 20210125, endtime = 20210131, showtime = 20210125, bshow = g_2019Q4_isFstStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --新增：春节预热活动设计--2020新增
		{ page = 1, btn = SpringFestival_Guide_HuameiBtn,  starttime = 20210128, endtime = 20210214, showtime = 20210125, bshow = g_2019Q4_isFstStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --画梅--2020重开-朔雪寻梅
		{ page = 1, btn = SpringFestival_Guide_QianLiBtn,  starttime = 20210125, endtime = 20210310, showtime = 20210125, bshow = g_2019Q4_isFstStart, btntips_unbeg="", btntips_doing="#{DHSZ_201218_03}", btntips_end="", }, --新增：千里江山图鉴--2020新增
		{ page = 1, btn = SpringFestival_Guide_LiChengBtn,  starttime = 20210128, endtime = 20210210, showtime = 20210125, bshow = g_2019Q4_isFstStart, btntips_unbeg="#{SRLQY_201230_38}", btntips_doing="#{SRLQY_201230_39}", btntips_end="", }, --新增：里程暴击--2020新增
		{ page = 1, btn = SpringFestival_Guide_DaSongBtn,  starttime = 20210125, endtime = 20210210, showtime = 20210125, bshow = g_2019Q4_isFstStart, btntips_unbeg="#{CXDS_201224_02}", btntips_doing="#{CXDS_201224_01}", btntips_end="#{CXDS_201224_02}", }, --新增：春行大宋--2020新增
		{ page = 1, btn = SpringFestival_Guide_RiliBtn,  starttime = 20220117, endtime = 20220131, showtime = 20220117, bshow = g_2019Q4_isFstStart, btntips_unbeg="#{LYYJ_181206_68}", btntips_doing="#{LYYJ_181206_67}", btntips_end="#{LYYJ_181206_69}", }, --日历--2020重开-千秋辞岁
		{ page = 1, btn = SpringFestival_Guide_ZhuanpanBtn,  starttime = 20220117, endtime = 20220130, showtime = 20220117, bshow = g_2019Q4_isFstStart, btntips_unbeg="#{LYYJ_181206_71}", btntips_doing="#{LYYJ_181206_70}", btntips_end="#{LYYJ_181206_69}", }, --转盘--2020重开-竹爆平安
		{ page = 1, btn = SpringFestival_Guide_LicaiBtn,  starttime = 20210125, endtime = 20210225, showtime = 20210125, bshow = g_2019Q4_isFstStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --理财--2020重开-经财有时
		{ page = 1, btn = SpringFestival_Guide_WXH5Btn,  starttime = 20210128, endtime = 20210203, showtime = 20210125, bshow = g_2019Q4_isFstStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --新增：春节微信活动游戏内部分--2020重开-参考年货急速运
		{ page = 1, btn = SpringFestival_Guide_GiftgBtn,  starttime = 20210125, endtime = 20210210, showtime = 20210125, bshow = g_2019Q4_isFstStart, btntips_unbeg="#{RACL_201224_14}", btntips_doing="#{RACL_201224_13}", btntips_end="#{RACL_201224_20}", }, --节日礼包--2020新增
		--春节第二阶段界面
		{ page = 2, btn = SpringFestival_Guide_DaNianshouBtn,  starttime = 20210208, endtime = 20210217, showtime = 20210208, bshow = g_2019Q4_isSecStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --打年兽--2020重开-戏年兽
		{ page = 2, btn = SpringFestival_Guide_FeastBtn,  starttime = 20210208, endtime = 20210217, showtime = 20210208, bshow = g_2019Q4_isSecStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --团圆宴--2020重开-团圆宴
		{ page = 2, btn = SpringFestival_Guide_ShanZhuangBtn,  starttime = 20210211, endtime = 20210217, showtime = 20210208, bshow = g_2019Q4_isSecStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --春节微信--2020重开-与师有约
		--春节第三阶段界面		
		{ page = 3, btn = SpringFestival_Guide_RiddleBtn, starttime = 20210219, endtime = 20210310, showtime = 20210219, bshow = g_2019Q4_isThdStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --猜灯谜--2020重开-花灯隐语
		{ page = 3, btn = SpringFestival_Guide_PigBtn,  starttime = 20210219, endtime = 20210310, showtime = 20210219, bshow = g_2019Q4_isThdStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --猜金猪--2020重开-三仙归位
		{ page = 3, btn = SpringFestival_Guide_ShootBtn,  starttime = 20210219, endtime = 20210310, showtime = 20210219, bshow = g_2019Q4_isThdStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --射箭--2020重开-神射竞春
		{ page = 3, btn = SpringFestival_Guide_MiaohuiShopBtn, starttime = 20210219, endtime = 20210314, showtime = 20210219, bshow = g_2019Q4_isThdStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --庙会商店--2020重开-百戏集市
		{ page = 3, btn = SpringFestival_Guide_AuctionBtn, starttime = 20210219, endtime = 20210226, showtime = 20210219, bshow = g_2019Q4_isThdStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --鬼市拍卖--2020重开-银锤金案
		{ page = 3, btn = SpringFestival_Guide_DividendBtn,  starttime = 20210227, endtime = 20210310, showtime = 20210225, bshow = g_2019Q4_isThd_SecStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --拍卖分红--2020重开-朱门传裕
		{ page = 3, btn = SpringFestival_Guide_SignBtn,  starttime = 20210219, endtime = 20210226, showtime = 20210219, bshow = g_2019Q4_isThdStart, btntips_unbeg="", btntips_doing="", btntips_end="", }, --预热--2020重开-东风夜放
	}
	--请求所有小红点
	SpringFestival_Guide_InitRedPoint()

end

--=========
-- 初始化活动小红点
--=========
function SpringFestival_Guide_InitRedPoint()

	-- 清空小红点
	for i = 1, table.getn(g_RedPointInfo) do
		g_RedPointInfo[i].bShow = 0
	end
	
	-- 请求全部活动小红点
	--if (IsInTServer() == 1) then
		--PushDebugMessage("#{BHKF_140909_327}")
		--return
	--end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateAllRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()

	-- 更新主界面快捷按钮小红点
	SpringFestival_Guide_UpdateQuickEnter()
	
end

--=========
-- 更新活动小红点
--=========
function SpringFestival_Guide_UpdateRedPoint()

	--活动小红点
	for i = 1, table.getn(g_RedPointInfo) do
		if g_RedPointInfo[i].tips ~= nil then
			g_RedPointInfo[i].tips:Hide()
			if g_RedPointInfo[i].page == g_CurPage and g_RedPointInfo[i].bShow == 1 then
				g_RedPointInfo[i].tips:Show()
			end
		end
	end
	
	--页签小红点
	--SpringFestival_Guide_UpdatePageRedPoint0117()
	--SpringFestival_Guide_UpdatePageRedPoint0131()
	--SpringFestival_Guide_UpdatePageRedPoint0211()
	-- 是否有更新标识
	
	if g_2019Q4_isThdStart > 0 then
		SpringFestival_Guide_UpdatePageRedPoint0211()
	elseif g_2019Q4_isSecStart > 0 then
		SpringFestival_Guide_UpdatePageRedPoint0131()
	elseif g_2019Q4_isFstStart > 0 then
		SpringFestival_Guide_UpdatePageRedPoint0117()
	end
end

--=========
-- 更新活动小红点
--=========
function SpringFestival_Guide_UpdatePageRedPoint0117()
	
	local validIndex = 1
	for i=1, table.getn(g_PageButton) do
		local nCount = 0
		for j=1, table.getn(g_RedPointInfo) do
			if g_RedPointInfo[j].tips ~= nil and g_RedPointInfo[j].page == i and g_RedPointInfo[j].bShow == 1 then
				nCount = nCount + 1
			end
		end

		for i, c in ipairs( g_PageButton[i].tips or {} ) do
			if nCount > 0 and i <= validIndex then
				c:Show()
			else
				c:Hide()
			end
		end
	end
	
end

--=========
-- 更新活动小红点
--=========
function SpringFestival_Guide_UpdatePageRedPoint0131()
	
	local validIndex = 2
	for i=1, table.getn(g_PageButton) do
		local nCount = 0
		for j=1, table.getn(g_RedPointInfo) do
			if g_RedPointInfo[j].tips ~= nil and g_RedPointInfo[j].page == i and g_RedPointInfo[j].bShow == 1 then
				nCount = nCount + 1
			end
		end

		for i, c in ipairs( g_PageButton[i].tips or {} ) do
			if nCount > 0 and i <= validIndex then
				c:Show()
			else
				c:Hide()
			end
		end
	end
	
end

--=========
-- 更新活动小红点
--=========
function SpringFestival_Guide_UpdatePageRedPoint0211()
	
	local validIndex = 3
	for i=1, table.getn(g_PageButton) do
		local nCount = 0
		for j=1, table.getn(g_RedPointInfo) do
			if g_RedPointInfo[j].tips ~= nil and g_RedPointInfo[j].page == i and g_RedPointInfo[j].bShow == 1 then
				nCount = nCount + 1
			end
		end

		for i, c in ipairs( g_PageButton[i].tips or {} ) do
			if nCount > 0 and i <= validIndex then
				c:Show()
			else
				c:Hide()
			end
		end
	end
	
end

--=========
-- 更新主界面快捷按钮小红点
--=========
function SpringFestival_Guide_UpdateQuickEnter()

	local bShow = 0
	
	for i = 1, table.getn(g_RedPointInfo) do
		if 1 == g_RedPointInfo[i].bShow then
			bShow = 1
			break
		end
	end

	--local str = ""
	--for i = 1, table.getn(g_RedPointInfo) do
	--	str = str.." "..g_RedPointInfo[i].bShow
	--end
	--PushDebugMessage("bShow="..bShow.." g_RedPointInfo="..str)
	
	--PushEvent("SPRINGGUIDEMISSION_QUICKENTER", bShow)
	Lua_ShowQuickEnterPointTip(15, bShow)
end

--=========
-- OnEvent
--=========
function SpringFestival_Guide_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89298502 then
	
		local nPage = Get_XParam_INT(0)
		local nStep = Get_XParam_INT(1)
		if nPage > 0 then
			if nPage == 1 and nStep == 999 then--特写：若当前页面开着则更新页签选中状态
				if this:IsVisible() then
					--for i=1, table.getn(g_PageButton) do
					--	for i, c in ipairs( g_PageButton[i].btn or {} ) do
					--		if g_CurPage == i then
					--			g_PageButton[i].btn:SetCheck(1)
					--		else
					--			g_PageButton[i].btn:SetCheck(0)
					--		end
					--	end
					--end
				end
			else	
				if nPage == 1 and nStep == 888 then--特写：界面未打开则不刷新
					if not this:IsVisible() then
						return
					end
				end
				if nPage == 1 and nStep >= 0 and nStep <= 1 then
					local TargetServerID = Get_XParam_INT(2);
					g_ObjCared = DataPool:GetNPCIDByServerID(TargetServerID);
					if g_ObjCared ~= -1 then
						this:CareObject(g_ObjCared, 1, "SpringFestival_Guide");
					end
				end
				--SpringFestival_Guide_InitRedPoint()--请求所有小红点
				SpringFestival_Guide_Update(nPage,nStep)
			end
		end
		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88832801) then	--节日礼包特写
	
		local bShow = Get_XParam_INT(0)
		if bShow == 2 then
			g_ButtonShowList[10].btn:Hide()
		end
		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20181205 then
		
		local bShow = tonumber(Get_XParam_INT(0));
		if bShow == 4 then
			if (this:IsVisible()) then
				if g_2019Q4_isOpen <= 0 then							
					local nJXFCnt = DataPool:GetPlayerMission_DataRound(1759)	--吉祥符数量				
					local nRYFCnt = DataPool:GetPlayerMission_DataRound(1760)	--如意符数量				
					if g_CurPage == 1 and g_CurStep == 1 then--春节第一阶段
						SpringFestival_Guide_JiXiangFuText1:SetText(ScriptGlobal_Format("#{RACL_181206_406}", nJXFCnt))
						SpringFestival_Guide_RuYiFuText0:SetText(ScriptGlobal_Format("#{RACL_181206_641}", nRYFCnt))
					elseif g_CurPage == 2 then--春节第二阶段
						SpringFestival_Guide_JiXiangFuText2:SetText(ScriptGlobal_Format("#{RACL_181206_415}", nJXFCnt))
						SpringFestival_Guide_RuYiFuText1:SetText(ScriptGlobal_Format("#{RACL_181206_408}", nRYFCnt))
					elseif g_CurPage == 3 then--春节第三阶段
						SpringFestival_Guide_JiXiangFuText3:SetText(ScriptGlobal_Format("#{RACL_181206_422}", nJXFCnt))
						SpringFestival_Guide_RuYiFuText2:SetText(ScriptGlobal_Format("#{RACL_181206_424}", nRYFCnt))
					end
				end
			end
		end
				
	elseif event == "UI_COMMAND" then
	
		for i = 1, table.getn(g_RedPointInfo) do
			if tonumber( arg0 ) == tonumber(g_RedPointInfo[i].nUICommandID) then
				local nScriptID = Get_XParam_INT(0)
				local bShow = Get_XParam_INT(1)
				--PushDebugMessage("nUICommandID="..tonumber( arg0 ).." nScriptID="..nScriptID.." bShow="..bShow)
				if tonumber( nScriptID ) ~= nil and tonumber( nScriptID ) > 0 and tonumber( nScriptID ) == tonumber(g_RedPointInfo[i].nScriptID) then
					g_RedPointInfo[i].bShow = bShow
					--PushDebugMessage("g_RedPointInfo[1].bShow="..g_RedPointInfo[1].bShow.." g_RedPointInfo[2].bShow"..g_RedPointInfo[2].bShow.." g_RedPointInfo[3].bShow"..g_RedPointInfo[3].bShow)
					--刷新界面
					if this:IsVisible() then
						--SpringFestival_Guide_Update(g_CurPage)
						--更新活动小红点
						SpringFestival_Guide_UpdateRedPoint()
						--更新主界面快捷按钮小红点
						SpringFestival_Guide_UpdateQuickEnter()
					else
						--更新主界面快捷按钮小红点
						SpringFestival_Guide_UpdateQuickEnter()
					end
				end
				--跳出
				break
			end
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_Guide_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
	
		SpringFestival_Guide_Close()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival_Guide_On_ResetPos()

	elseif (event == "OBJECT_CARED_EVENT") then
	
		--AxTrace(0, 0, "arg0"..arg0.." arg1"..arg1.." arg2"..arg2);
		if(g_ObjCared == -1) then
			return
		end
		if(tonumber(arg0) ~= g_ObjCared) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			SpringFestival_Guide_Close()
		end
	elseif (event == "CLOSE_SPRINGFES_GUIDE") then
		SpringFestival_Guide_Close()
	end

end

--=========
-- 重置
--=========
function SpringFestival_Guide_On_ResetPos()

	SpringFestival_Guide_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 切换分页
--=========
function SpringFestival_Guide_Switch(nPage)

	if nPage == nil or nPage <= 0 or nPage > g_PageCount then
		return
	end
	-- 播放动画的时候，不让点击
	if g_Tween_Playing > 0 then
		PushDebugMessage("#{RACL_181206_687}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenSpringGuideMission" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0,nPage) --默认根据当前时间打开对应分页
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
end

--=========
-- 打开
--=========
function SpringFestival_Guide_Update(nPage,nStep)

	if nPage == nil or nPage <= 0 or nPage > g_PageCount then	
		return		
	end
	if nStep == nil or nStep < 0 then
		return
	end
	
	-- 播放中，屏蔽该消息
	if g_Tween_Playing > 0 then
		return
	end
	g_Tween_Page = g_CurPage
	g_CurPage = nPage
	g_CurStep = nStep
	--for i=1, table.getn(g_PageButton) do
	--	if g_CurPage == i then
	--		g_PageButton[i].btn:SetCheck(1)
	--	else
	--		g_PageButton[i].btn:SetCheck(0)
	--	end
	--end
	
	-- 全部隐藏
	SpringFestival_Guide_Client1:Hide()
	SpringFestival_Guide_Client2:Hide()
	SpringFestival_Guide_Client3:Hide()
	
	-- 更新当前页
	if nPage == 1 then--引导任务执行阶段 or 春节第一阶段
		if nStep == 1 then
			SpringFestival_Guide_Update1()
		end
	elseif nPage == 2 then--春节第二阶段
		SpringFestival_Guide_Update2()
	elseif nPage == 3 then--春节第三阶段
		SpringFestival_Guide_Update3()
	end
	
	SpringFestival_Guide_BtnShowByTime(nPage)
	SpringFestival_Guide_TweenButtonShow()

	-- 显示
	this:Show()	

	--更新活动小红点
	SpringFestival_Guide_UpdateRedPoint()
	--更新主界面快捷按钮小红点
	SpringFestival_Guide_UpdateQuickEnter()
	
	--设置页签tips
	--SpringFestival_Guide_UpdatePageButtonTips0117()
	--SpringFestival_Guide_UpdatePageButtonTips0131()
	--SpringFestival_Guide_UpdatePageButtonTips0211()
	-- 2019Q4重开
	--SpringFestival_Guide_UpdatePageButtonTips2019Q4()
	
end

--=========
-- 更新页签tips
--=========
function SpringFestival_Guide_UpdatePageButtonTips0117()

	local curDay = tonumber(DataPool:GetServerDayTime());
	
	--页签1
	if curDay >= g_StartDay and curDay < g_MidDay1 then--1.17-1.30
		SpringFestival_Guide_Buttontab01 : SetToolTip("#{RACL_181206_612}")
	elseif curDay >= g_MidDay1 then--1.31-
		SpringFestival_Guide_Buttontab01 : SetToolTip("#{RACL_181206_613}")
	end

	--页签2
	if curDay >= g_StartDay and curDay <= g_MidDay1 then--1.17-1.31
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_614}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_614}")
	elseif curDay > g_MidDay1 and curDay < g_MidDay2 then--2.1-2.10
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_619}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_619}")
	elseif curDay >= g_MidDay2 then--2.11-
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_615}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_615}")
	end	
	
	--页签3
	if curDay >= g_StartDay and curDay <= g_MidDay2 then--1.17-2.11
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_616}")
	elseif curDay > g_MidDay2 and curDay <= g_EndDay then--2.12-3.6
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_620}")
	elseif curDay > g_EndDay then--3.7-
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_617}")
	end
		
end
--=========
-- 更新页签tips
--=========
function SpringFestival_Guide_UpdatePageButtonTips0131()

	local curDay = tonumber(DataPool:GetServerDayTime());
	
	--页签1
	if curDay >= g_StartDay and curDay < g_MidDay1 then--1.17-1.30
		SpringFestival_Guide_Buttontab01 : SetToolTip("#{RACL_181206_612}")
	elseif curDay >= g_MidDay1 then--1.31-
		SpringFestival_Guide_Buttontab01 : SetToolTip("#{RACL_181206_613}")
	end

	--页签2
	if curDay >= g_StartDay and curDay < g_MidDay1 then--1.17-1.30--------------------------
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_614}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_614}")
	elseif curDay >= g_MidDay1 and curDay < g_MidDay2 then--1.31-2.10--------------------------
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_619}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_619}")
	elseif curDay >= g_MidDay2 then--2.11-
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_615}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_615}")
	end	
	
	--页签3
	if curDay >= g_StartDay and curDay <= g_MidDay2 then--1.17-2.11
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_616}")
	elseif curDay > g_MidDay2 and curDay <= g_EndDay then--2.12-3.6
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_620}")
	elseif curDay > g_EndDay then--3.7-
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_617}")
	end
	
end
--=========
-- 更新页签tips
--=========
function SpringFestival_Guide_UpdatePageButtonTips0211()

	local curDay = tonumber(DataPool:GetServerDayTime());
	
	--页签1
	if curDay >= g_StartDay and curDay < g_MidDay1 then--1.17-1.30
		SpringFestival_Guide_Buttontab01 : SetToolTip("#{RACL_181206_612}")
	elseif curDay >= g_MidDay1 then--1.31-
		SpringFestival_Guide_Buttontab01 : SetToolTip("#{RACL_181206_613}")
	end

	--页签2
	if curDay >= g_StartDay and curDay < g_MidDay1 then--1.17-1.30
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_614}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_614}")
	elseif curDay >= g_MidDay1 and curDay < g_MidDay2 then--1.31-2.10
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_619}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_619}")
	elseif curDay >= g_MidDay2 then--2.11-
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_615}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_615}")
	end	
	
	--页签3
	if curDay >= g_StartDay and curDay < g_MidDay2 then--1.17-2.10--------------------------
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_616}")
	elseif curDay >= g_MidDay2 and curDay <= g_EndDay then--2.11-3.6--------------------------
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_620}")
	elseif curDay > g_EndDay then--3.7-
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_617}")
	end
	
end

--=========
-- 更新页签tips, Q4重开
--=========
function SpringFestival_Guide_UpdatePageButtonTips2019Q4()

	local curDay = tonumber(DataPool:GetServerDayTime())
	--页签1
	if curDay >= g_SecDay and curDay <= g_MidDay1 then	--2020.01.06-2020.01.19
		SpringFestival_Guide_Buttontab01 : SetToolTip("#{RACL_181206_612}")
	elseif curDay > g_MidDay1 then
		SpringFestival_Guide_Buttontab01 : SetToolTip("#{RACL_181206_613}")
	end

	--页签2
	if (curDay >= g_SecDay and curDay <= g_MidDay1) or g_2019Q4_isSecStart < 1 then--2020年1月6日更新后至1月19日24时
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_614}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_614}")
	elseif curDay > g_MidDay1 and curDay <= g_MidDay2 then--2020年1月20日更新后至1月29日24时
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_619}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_619}")
	elseif curDay > g_MidDay2 then--2020年1月31日24时及以后
		SpringFestival_Guide_Buttontab02L : SetToolTip("#{RACL_181206_615}")
		SpringFestival_Guide_Buttontab02R : SetToolTip("#{RACL_181206_615}")
	end	
	
	--页签3
	if curDay >= g_SecDay and curDay < g_MidDay3 then--2020年1月6日更新后至1月29日24时,这里文档应该误写，换成2019.01.31
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_616}")
	elseif curDay >= g_MidDay3 and curDay <= g_EndDay then--2.11-3.6--------------------------
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_620}")
	elseif curDay > g_EndDay then--2月26日及以后
		SpringFestival_Guide_Buttontab03 : SetToolTip("#{RACL_181206_617}")
	end
	
end

--=========
-- 春节第一阶段显示
--=========
function SpringFestival_Guide_Update1()
	
	SpringFestival_Guide_Client1:Show()
	if g_2019Q4_isOpen <= 0 then
		--吉祥符数量
		local nJXFCnt = DataPool:GetPlayerMission_DataRound(1759)	
		SpringFestival_Guide_JiXiangFuText1:SetText(ScriptGlobal_Format("#{RACL_181206_406}", nJXFCnt))
		--如意符数量
		local nRYFCnt = DataPool:GetPlayerMission_DataRound(1760)	
		SpringFestival_Guide_RuYiFuText0:SetText(ScriptGlobal_Format("#{RACL_181206_641}", nRYFCnt))
	else
		SpringFestival_Guide_IntegralClient1:Hide()
	end
end

--=========
-- 春节第二阶段显示
--=========
function SpringFestival_Guide_Update2()
	SpringFestival_Guide_Client2:Show()

	if g_2019Q4_isOpen <= 0 then
		--吉祥符数量
		local nJXFCnt = DataPool:GetPlayerMission_DataRound(1759)	
		SpringFestival_Guide_JiXiangFuText2:SetText(ScriptGlobal_Format("#{RACL_181206_415}", nJXFCnt))
		--如意符数量
		local nRYFCnt = DataPool:GetPlayerMission_DataRound(1760)	
		SpringFestival_Guide_RuYiFuText1:SetText(ScriptGlobal_Format("#{RACL_181206_408}", nRYFCnt))
	else
		SpringFestival_Guide_IntegralClient2:Hide()
	end
end

--=========
-- 春节第三阶段显示
--=========
function SpringFestival_Guide_Update3()

	SpringFestival_Guide_Client3:Show()

	if g_2019Q4_isOpen <= 0 then
		--吉祥符数量
		local nJXFCnt = DataPool:GetPlayerMission_DataRound(1759)	
		SpringFestival_Guide_JiXiangFuText3:SetText(ScriptGlobal_Format("#{RACL_181206_422}", nJXFCnt))
		--如意符数量
		local nRYFCnt = DataPool:GetPlayerMission_DataRound(1760)	
		SpringFestival_Guide_RuYiFuText2:SetText(ScriptGlobal_Format("#{RACL_181206_424}", nRYFCnt))
	else
		SpringFestival_Guide_IntegralClient3:Hide()
	end
end

--=========
-- 分阶段显示内容
--=========
function SpringFestival_Guide_BtnShowByTime(page)
	if page <= 0 or page > g_PageCount then
		return
	end

	local listcount = table.getn(g_ButtonShowList)
	for i=1, listcount do
		local item = g_ButtonShowList[i]
		if item ~= nil then
			if item.page == page then
				if item.starttime == -1 or item.endtime == -1 or item.showtime == -1 or item.bshow < 1 then
					item.btn:Hide()
				else
					local curDay = tonumber(DataPool:GetServerDayTime())
					if curDay >= item.showtime and curDay <= item.endtime then
						item.btn:Show()
						--增加按钮tips分时间显示
						if curDay < item.starttime then
							item.btn:SetToolTip(item.btntips_unbeg)
						elseif curDay >= item.starttime and curDay <= item.endtime then
							item.btn:SetToolTip(item.btntips_doing)
						elseif curDay > item.endtime then
							item.btn:SetToolTip(item.btntips_end)
						end
					else
						item.btn:Hide()
					end
				end
			end
		end
	end
	
	if Pneuma:GetMF(3019) == 1 then--节日礼包特写
		g_ButtonShowList[10].btn:Hide()
	end

end

function SpringFestival_Guide_BtnHideByTime()
	local listcount = table.getn(g_ButtonShowList)
	for i=1, listcount do
		local item = g_ButtonShowList[i]
		if item ~= nil then	
			item.btn:Hide()
		end
	end
end

--=========
-- 是否正确的时间
--=========
function SpringFestival_Guide_IsRightTime(nIndex)
	-- 判定边界
	local listcount = table.getn(g_ButtonShowList)
	if nIndex < 1 or listcount < nIndex then
		return 0
	end

	-- 判定时间
	local item = g_ButtonShowList[nIndex]
	if item ~= nil then
		-- 默认为无效时间
		if item.starttime == -1 or item.endtime == -1 then
			return 0
		else
			local curDay = tonumber(DataPool:GetServerDayTime())
			if curDay >= item.starttime and curDay <= item.endtime then
				return 1
			elseif curDay > item.endtime then
				return -1
			end

		end
	end

	return 0
end

--=========
-- 活动页面UI重置，都隐藏或动画还原
--=========
function SpringFestival_Guide_TweenBtnUIReset()
	-- 还原动画
	SpringFestival_Guide_BKClient:Tween_Reset("Position",true)
	-- 隐藏所有
	for i=1, table.getn(g_PageButton) do
		for i, c in ipairs( g_PageButton[i].btn or {} ) do
			c:Hide()
		end
	end
	SpringFestival_Guide_Next:Hide()
	SpringFestival_Guide_ButtonLeft:Hide()
	SpringFestival_Guide_ButtonRight:Hide()
	SpringFestival_Guide_Client_ALLBKNone1:Hide()
	SpringFestival_Guide_Client_ALLBKNone2:Hide()
	SpringFestival_Guide_Client1_Title:Hide()
	SpringFestival_Guide_Client2_Title:Hide()
	SpringFestival_Guide_Client3_Title:Hide()
	SpringFestival_Guide_ScrollUIReset()
end

--=========
-- 活动调相关的UI显示还原
--=========
function SpringFestival_Guide_ScrollUIReset()
	SpringFestival_Guide_ScrollUp:Hide()
	SpringFestival_Guide_ScrollMid:Hide()
	SpringFestival_Guide_ScrollDown:Hide()
	SpringFestival_Guide_ScrollLeftMid01:Hide()
	SpringFestival_Guide_ScrollLeftMid02:Hide()
	SpringFestival_Guide_ScrollRightMid01:Hide()
	SpringFestival_Guide_ScrollRightMid02:Hide()
end
--=========
-- 处理左右按钮
--=========
function SpringFestival_Guide_TweenButtonShow()
	-- 还原UI
	SpringFestival_Guide_TweenBtnUIReset()
	-- 不同分页，在不同时间内，进行不同的显示
	local leftbtn,rightbtn,leftarrows,rightarrows,bottomtitle
	local curDay = tonumber(DataPool:GetServerDayTime())
	if g_CurPage == 1 then
		if (curDay >= g_StartDay and curDay <= g_MidDay1) or g_2019Q4_isSecStart < 1 then
			rightbtn = SpringFestival_Guide_Next
		elseif curDay > g_MidDay1 then
			rightbtn = SpringFestival_Guide_Buttontab02R
		end
		rightarrows = SpringFestival_Guide_ButtonRight
		bottomtitle = SpringFestival_Guide_Client1_Title
	elseif g_CurPage == 2 then
		if curDay > g_MidDay1 and curDay <= g_MidDay2 then
			leftbtn = SpringFestival_Guide_Buttontab01
			rightbtn = SpringFestival_Guide_Next
		elseif curDay >= g_MidDay3 then
			leftbtn = SpringFestival_Guide_Buttontab01
			rightbtn = SpringFestival_Guide_Buttontab03
		end
		leftarrows = SpringFestival_Guide_ButtonLeft
		rightarrows = SpringFestival_Guide_ButtonRight
		bottomtitle = SpringFestival_Guide_Client2_Title		
	elseif g_CurPage == 3 then
		if curDay >= g_MidDay3 and curDay <= g_EndDay then
			leftbtn = SpringFestival_Guide_Buttontab02L
		end
		leftarrows = SpringFestival_Guide_ButtonLeft
		bottomtitle = SpringFestival_Guide_Client3_Title
	end

	if leftbtn ~= nil then
		leftbtn:Show()
	end

	if rightbtn ~= nil then
		if rightbtn == SpringFestival_Guide_Next then
			local curDay = tonumber(DataPool:GetServerDayTime())
			-- 是否还在第一阶段
			if curDay <= g_MidDay1 or g_2019Q4_isSecStart < 1 then	-- 是否可以去第二阶段
				rightbtn : SetToolTip("#{RACL_181206_675}")
			else
				rightbtn : SetToolTip("#{RACL_181206_676}")
			end
			--SpringFestival_Guide_Client_ALLBKNone1:Show()
			--SpringFestival_Guide_Client_ALLBKNone2:Show()
		end
		rightbtn:Show()
	end
	
	if leftarrows ~= nil then
		leftarrows:Show()
	end

	if rightarrows ~= nil then
		rightarrows:Show()
	end
	
	if bottomtitle ~= nil then
		bottomtitle:Show()
	end
	SpringFestival_Guide_TweenPlay(g_Tween_Page)
end


--=========
-- 滚动动画结束
--=========
function SpringFestival_Guide_TweenEnd()
	g_Tween_Playing = 0
	-- 显示按钮
	SpringFestival_Guide_BtnShowByTime(g_CurPage)
	-- 滚动条UI显示
	SpringFestival_Guide_ScrollUIReset()
	SpringFestival_Guide_ScrollUIShow(g_CurPage,g_CurPage)
	-- 背景相关内容显示
	SpringFestival_Guide_BKShow()
end

--=========
-- 滚动动画开始
--=========
function SpringFestival_Guide_TweenPlay(nSrcPage)
	-- 还原
	g_Tween_Playing = 0
	SpringFestival_Guide_BtnHideByTime()
	if nSrcPage > 0 and nSrcPage <= g_PageCount and nSrcPage ~= g_CurPage and math.abs(nSrcPage - g_CurPage) <= 1 then
		local dest,destdir,tweenposx
		local destpage,scrollpage = nSrcPage,g_CurPage
		if nSrcPage == 1 then
			-- 向右移
			if g_CurPage - nSrcPage == 1 then
				destdir = from_to_info1
				tweenposx = 0
				destpage = g_CurPage
			end
		elseif nSrcPage == 2 then
			-- 向右移
			if g_CurPage - nSrcPage > 0 then
				destdir = from_to_info3
				tweenposx = -g_Tween_PosX
				destpage = g_CurPage
				scrollpage = nSrcPage
			-- 向左移
			elseif g_CurPage - nSrcPage < 0 then
				destdir = from_to_info2
				tweenposx = -g_Tween_PosX
			end
		elseif nSrcPage == 3 then
			-- 向左移
			if nSrcPage - g_CurPage == 1 then
				destdir = from_to_info4
				tweenposx = -1*(g_Tween_PosX + g_Tween_PosX_Sec)
			end
		end
		dest = SpringFestival_Guide_BKClient
		if dest ~= nil and destdir ~= nil and tweenposx ~= nil then
			dest:Show()
			dest:SetProperty("UnifiedXPosition", string.format("{0.000000,%s.000000}", tweenposx))
			dest:Tween_SetInfo("Position", destdir)
			dest:Tween_Play("Position", true, true)

			g_Tween_Playing = 1
			SpringFestival_Guide_ScrollUIShow(destpage,scrollpage)
		end
	else
		-- 直接显示
		local destbk,posx = SpringFestival_Guide_BKClient,0
		if g_CurPage == 1 then
			posx = 0
		elseif g_CurPage == 2 then
			posx = -g_Tween_PosX
		elseif g_CurPage == 3 then
			posx = -1*(g_Tween_PosX + g_Tween_PosX_Sec)
		end

		if destbk ~= nil then
			destbk:Show()
			destbk:SetProperty("UnifiedXPosition", string.format("{0.000000,%s.000000}", posx))
		end
		SpringFestival_Guide_BtnShowByTime(g_CurPage)
		SpringFestival_Guide_ScrollUIShow(g_CurPage,g_CurPage)
		SpringFestival_Guide_BKShow()
	end
end

--=========
-- 切换转轴动画
--=========
function SpringFestival_Guide_ScrollUIShow(nPage, nScrollPage)

	local left1,left2,right1,right2
	if nPage == 1 then
		right1 = SpringFestival_Guide_ScrollRightMid01
		right2 = SpringFestival_Guide_ScrollRightMid02
	elseif nPage == 2 then
		left1 = SpringFestival_Guide_ScrollLeftMid01
		left2 = SpringFestival_Guide_ScrollLeftMid02
		right1 = SpringFestival_Guide_ScrollRightMid01
		right2 = SpringFestival_Guide_ScrollRightMid02
	elseif nPage == 3 then
		left1 = SpringFestival_Guide_ScrollLeftMid01
		left2 = SpringFestival_Guide_ScrollLeftMid02
	end
	if left1 ~= nil then
		left1:Show()
	end
	if left2 ~= nil then
		left2:Show()
	end
	if right1 ~= nil then
		right1:Show()
	end
	if right2 ~= nil then
		right2:Show()
	end

	SpringFestival_Guide_ScrollUIShowEx(nScrollPage)
end

function SpringFestival_Guide_ScrollUIShowEx(nPage)
	local scroll
	if nPage == 1 then
		scroll = SpringFestival_Guide_ScrollUp
	elseif nPage == 2 then
		scroll = SpringFestival_Guide_ScrollMid
	elseif nPage == 3 then
		scroll = SpringFestival_Guide_ScrollDown
	end
	if scroll ~= nil then
		scroll:Show()
	end
end

--=========
-- 其他背景图显示
--=========
function SpringFestival_Guide_BKShow()
	local isCloudShow = 0
	local curDay = tonumber(DataPool:GetServerDayTime())
	if g_CurPage == 1 then
		if (curDay >= g_StartDay and curDay <= g_MidDay1) or g_2019Q4_isSecStart < 1 then
			isCloudShow = 1
		end
	elseif g_CurPage == 2 then
		if curDay > g_MidDay1 and curDay <= g_MidDay2 then
			isCloudShow = 1
		end
	end
	if isCloudShow > 0 then
		SpringFestival_Guide_Client_ALLBKNone1:Show()
		SpringFestival_Guide_Client_ALLBKNone2:Show()
	end
end

--=========
-- 暂未开放点击
--=========
function SpringFestival_Guide_NextPage()
	local nPage = g_CurPage + 1
	
	if nPage == 2 then--页签2
		local curDay = tonumber(DataPool:GetServerDayTime())
		if curDay <= g_MidDay1 or g_2019Q4_isSecStart < 1 then	-- 是否可以去第二阶段
			PushDebugMessage("#{RACL_181206_677}")
		end
	elseif nPage == 3 then--页签2
		local curDay = tonumber(DataPool:GetServerDayTime())	
		if curDay < g_MidDay3 then	-- 是否可以去第三阶段
			PushDebugMessage("#{RACL_181206_678}")
		end
	end
end

--=========
-- 箭头点击
--=========
function SpringFestival_Guide_ArrowClick(arrow)
	local nPage = 0
	if arrow > 0 then
		nPage = g_CurPage + 1
	else
		nPage = g_CurPage - 1
	end
	
	if nPage == 2 then--页签2
		local curDay = tonumber(DataPool:GetServerDayTime())
		if curDay <= g_MidDay1 or g_2019Q4_isSecStart < 1 then	-- 是否可以去第二阶段
			PushDebugMessage("#{RACL_181206_677}")
			return
		end
	elseif nPage == 3 then--页签2
		local curDay = tonumber(DataPool:GetServerDayTime())	
		if curDay < g_MidDay3 then	-- 是否可以去第三阶段
			PushDebugMessage("#{RACL_181206_678}")
			return
		end
	end
	
	SpringFestival_Guide_Switch(nPage)
end

--=========
-- 关闭
--=========
function SpringFestival_Guide_Close()

	SpringFestival_Guide_OnHiden()
	this:Hide()
	
end

--=========
-- 隐藏
--=========
function SpringFestival_Guide_OnHiden()

	g_CurPage = -1
	g_CurStep = -1
	
	this:CareObject(g_ObjCared, 0, "SpringFestival_Guide");
	g_ObjCared = -1;
	
	g_Tween_Page = 0
	g_Tween_Playing = 0
end

------------------------------------------------------------春节第一阶段
--=========
-- 预热
--=========
function SpringFestival_Guide_Client1_YuReClicked()
	
	local isrighttime = SpringFestival_Guide_IsRightTime(1)
	if isrighttime <= 0 then
		PushDebugMessage("#{RACL_181206_443}")
		return
	end

end

--=========
-- 千里江山
--=========
function SpringFestival_Guide_Client1_QianLiClicked()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(888331)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--=========
-- 里程暴击
--=========
function SpringFestival_Guide_Client1_LiChengClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(888333)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--=========
-- 春行大宋
--=========
function SpringFestival_Guide_Client1_DaSongClicked()
	-- 检查玩家等级
	local curLevel = Player:GetData("LEVEL")
	if (curLevel < 30) then
		PushDebugMessage("#{CXDS_201224_03}")
		return
	end

	-- 检查活动时间
	local isrighttime = SpringFestival_Guide_IsRightTime(5)
	if isrighttime <= 0 then
		PushDebugMessage("#{CXDS_201224_04}")
		return
	end

	PushEvent("CXDS_UI_OPEN")
	SpringFestival_Guide_Close()
end

--=========
-- 节日礼包
--=========
function SpringFestival_Guide_Client1_GiftgClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(888328)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

--=========
-- 彩蛋
--=========
function SpringFestival_Guide_Client1_CaidanClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenSpringCaiDan")
		Set_XSCRIPT_ScriptID(893000)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

--=========
-- 喝酒
--=========
function SpringFestival_Guide_Client1_HejiuClicked()
	local isrighttime = SpringFestival_Guide_IsRightTime(0)
	if isrighttime > 0 then
	else
		PushDebugMessage("#{RACL_181206_443}")
		return
	end

	--if DataPool:Lua_IsMissionHaveDone(g_MissionId6) ~= 1 then
	--	PushDebugMessage("#{RACL_181206_637}")
	--	return
	--end
		
	--寻路
	AutoRuntoTargetExWithName(242, 269, 0, "景年")
end

--=========
-- 商店
--=========
function SpringFestival_Guide_Client1_ShopClicked()
	--
	local nLevel = Player:GetLevel();
	if nLevel < g_LimitLevel then
		--PushDebugMessage("#{ZHHD1_181128_17}")
		PushDebugMessage("#{RACL_181206_444}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenCaiQuanShop")
		Set_XSCRIPT_ScriptID(893010)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
	
end

--=========
-- 转盘
--=========
function SpringFestival_Guide_Client1_ZhuanpanClicked()
	local isrighttime = SpringFestival_Guide_IsRightTime(7)
	if isrighttime > 0 then
	else
		PushDebugMessage("#{RACL_181206_443}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end

	--寻路
	AutoRunToTargetEx(215, 275, 0)	
	PushDebugMessage("#{RACL_181206_680}")
	SpringFestival_Guide_Close()
end

--=========
-- 画梅
--=========
function SpringFestival_Guide_Client1_HuameiClicked()	
	local isrighttime = SpringFestival_Guide_IsRightTime(2)
	if isrighttime > 0 then
	else
		PushDebugMessage("#{RACL_181206_443}")
		return
	end
	
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	
	--if DataPool:Lua_IsMissionHaveDone(g_MissionId6) ~= 1 then
	--	PushDebugMessage("#{RACL_181206_637}")
	--	return
	--end
	
	--寻路
	AutoRuntoTargetExWithName(265, 255, 0, "无崖子")	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0, 892655)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	SpringFestival_Guide_Close()
	
end

--=========
-- 日历
--=========
function SpringFestival_Guide_Client1_RiliClicked()

	local isrighttime = SpringFestival_Guide_IsRightTime(6)
	if isrighttime > 0 then
	else
		PushDebugMessage("#{RACL_181206_443}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end

	--if DataPool:Lua_IsMissionHaveDone(g_MissionId6) ~= 1 then
	--	PushDebugMessage("#{LYYJ_181206_61}")
	--	return
	--end

	if(IsWindowShow("SpringFirst_Calender")) then
		CloseWindow("SpringFirst_Calender", true)
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID( 890801 )
		Set_XSCRIPT_Function_Name( "OnOpenLaYueSiRiLiUI" )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
	
end

--=========
-- 红包
--=========
function SpringFestival_Guide_Client1_RedPacketClicked()

	local nLevel = Player:GetLevel();
	if nLevel < 50 then
		PushDebugMessage("#{CJHB_181207_02}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0, 893025)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenHongBaoUI")
		Set_XSCRIPT_ScriptID(893025)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
	
end

--=========
-- 答疑
--=========
function SpringFestival_Guide_Client1_HelpClicked()

	PushEvent("SPRINGGUIDEMISSION_JIXIANGFUHELP",1)
	
end

------------------------------------------------------------春节第二阶段
--=========
-- 山庄
--=========
function SpringFestival_Guide_Client2_ShanZhuangClicked()

	local isrighttime = SpringFestival_Guide_IsRightTime(13)
	if isrighttime <= 0 then
		if isrighttime < 0 then
			PushDebugMessage("#{RACL_181206_443}")
		else
			PushDebugMessage("#{RACL_181206_688}")
		end
		return
	end
	
	local nLevel = Player:GetLevel();
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end

    PushDebugMessage("#{CJWX_191207_14}")
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("open")
    Set_XSCRIPT_ScriptID(893351)
    Set_XSCRIPT_Parameter(0, 1)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()			
    --SpringFestival_Guide_Close()
end

--=========
-- 打年兽
--=========
function SpringFestival_Guide_Client2_DaNianshouClicked()
	local isrighttime = SpringFestival_Guide_IsRightTime(11)
	if isrighttime <= 0 then
		PushDebugMessage("#{RACL_181206_443}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	
	--寻路
	AutoRuntoTargetExWithName(269, 255, 0, "殷柏舟")
	PushDebugMessage("#{RACL_181206_653}")			
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0, 892662)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
		
	SpringFestival_Guide_Close()
	
end

--=========
-- 团圆宴
--=========
function SpringFestival_Guide_Client2_FeastClicked()
	
	local isrighttime = SpringFestival_Guide_IsRightTime(12)
	if isrighttime <= 0 then
		PushDebugMessage("#{RACL_181206_443}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	
	--寻路
	--AutoRunToTargetEx(256, 285, 0)	
	--PushDebugMessage("#{RACL_181206_654}")	
	-- 打开引导界面
	PushEvent( "UI_COMMAND", 89266002 )
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0, 892660)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
		
	SpringFestival_Guide_Close()
	
end

--=========
-- 写春联
--=========
function SpringFestival_Guide_Client2_ChunLianClicked()

	--
	
end

--=========
-- 大扫除
--=========
function SpringFestival_Guide_Client2_CleanClicked()

	--
	
end

--=========
-- 挂福字
--=========
function SpringFestival_Guide_Client2_FontClicked()

	--
	
end

--=========
-- 答疑
--=========
function SpringFestival_Guide_Client2_HelpClicked()

	PushEvent("SPRINGGUIDEMISSION_JIXIANGFUHELP",2)
	
end

------------------------------------------------------------春节第三阶段
--=========
-- 庙会商店
--=========
function SpringFestival_Guide_Client3_MiaohuiShopClicked()

	local isrighttime = SpringFestival_Guide_IsRightTime(17)
	if isrighttime <= 0 then
		PushDebugMessage("#{RACL_181206_443}")
		return
	end

	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end

	if(IsWindowShow("YuanXiao_Shop")) then
		CloseWindow("YuanXiao_Shop", true)
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenFairShop" )
		Set_XSCRIPT_ScriptID( 890713 )
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	
end

--=========
-- 十连抽
--=========
function SpringFestival_Guide_Client3_PickClicked()
	local isrighttime = SpringFestival_Guide_IsRightTime(0)
	if isrighttime > 0 then
	else
		PushDebugMessage("#{RACL_181206_443}")
		return
	end

	local nLevel = Player:GetLevel();
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	--
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0, 893020)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	AutoRuntoTargetExWithName(291, 357, 0, "付焕津")
	PushDebugMessage("#{RACL_181206_655}")
	SpringFestival_Guide_Close()
end

--=========
-- 猜金猪
--=========
function SpringFestival_Guide_Client3_PigClicked()

	local isrighttime = SpringFestival_Guide_IsRightTime(15)
	if isrighttime <= 0 then
		PushDebugMessage("#{RACL_181206_443}")
		return
	end

	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGotoDispatchNPC" );
		Set_XSCRIPT_ScriptID( 892980 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()

	SpringFestival_Guide_Close()
end

--=========
-- 射箭
--=========
function SpringFestival_Guide_Client3_ShootClicked()

	local isrighttime = SpringFestival_Guide_IsRightTime(16)
	if isrighttime <= 0 then
		PushDebugMessage("#{RACL_181206_443}")
		return
	end

	local nLevel = Player:GetLevel();
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GoToNPC" );
		Set_XSCRIPT_ScriptID( 893021 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0, 893021)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	
	PushDebugMessage("#{RACL_181206_657}")
	SpringFestival_Guide_Close()

end

--=========
-- 猜灯谜
--=========
function SpringFestival_Guide_Client3_RiddleClicked()

	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	
	local isrighttime = SpringFestival_Guide_IsRightTime(14)
	if isrighttime > 0 then
		AutoRuntoTargetExWithName(274, 341, 0, "蔡弥")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateRedPoint" );
			Set_XSCRIPT_ScriptID( 892384 );	
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount( 1 );
		Send_XSCRIPT()			
		PushDebugMessage("#{RACL_181206_658}")
		SpringFestival_Guide_Close()
	else
		PushDebugMessage("#{RACL_181206_443}")
	end
	
end

--=========
-- 答疑
--=========
function SpringFestival_Guide_Client3_HelpClicked()

	PushEvent("SPRINGGUIDEMISSION_JIXIANGFUHELP",3)
	
end

--=========
-- 预售
--=========
function SpringFestival_Guide_Client1_YushouClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenFashionUI" )
		Set_XSCRIPT_ScriptID( 893324 )
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
		
end

--=========
-- 理财
--=========
function SpringFestival_Guide_Client1_LicaiClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenFoundUI" )
		Set_XSCRIPT_ScriptID( 893324 )
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
		
end

--=========
-- H5 年货急速运
--=========
function SpringFestival_Guide_Client1_WXH5Clicked()
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{SZYS_191202_02}") --您的等级不足30级，无法参与此活动。
		return
	end
	-- 这里有第一阶段三期更新开关判断
	local isrighttime = SpringFestival_Guide_IsRightTime(9)
	if isrighttime > 0 and g_2019Q4_isFst_ThdStart > 0 then
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("open")
        Set_XSCRIPT_ScriptID(893335)
        Set_XSCRIPT_Parameter(0, 1)
        Set_XSCRIPT_ParamCount(1)
        Send_XSCRIPT()			
        SpringFestival_Guide_Close()
	else
		if isrighttime < 0 then
			PushDebugMessage("#{RACL_181206_443}") --当前不在活动时间内，无法参与活动。
		else
			PushDebugMessage("#{SZYS_191202_04}") --活动将于1月28日开启，敬请期待。
		end
    end
end

--=========
-- 烟火会 火树银花
-- Notice : 基础判断条件觉得无用，直接删掉就可以，标注，该界面要进行重做，会更换成新UI，换新之后会将原逻辑移到新UI中
--=========
function SpringFestival_Guide_Client3_FireworkClicked()
	-- Notice: 判断功能无用，直接干掉就好
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	local isrighttime = SpringFestival_Guide_IsRightTime(0)
	if isrighttime > 0 then
		PushDebugMessage("#{RACL_181206_682}")
	elseif isrighttime < 0 then
		PushDebugMessage("#{RACL_181206_443}")
	else
		PushDebugMessage("#{RACL_181206_681}")
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UpdateRedPoint")
		Set_XSCRIPT_ScriptID(893378)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--=========
-- 六美图 众里寻她
-- Notice : 基础判断条件觉得无用，直接删掉就可以，标注，该界面要进行重做，会更换成新UI，换新之后会将原逻辑移到新UI中
--=========
function SpringFestival_Guide_Client3_BeautyClicked()
	-- Notice: 判断功能无用，直接干掉就好
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	local isrighttime = SpringFestival_Guide_IsRightTime(0)
	if isrighttime > 0 then
        Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("open")
			Set_XSCRIPT_ScriptID(893356)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
        SpringFestival_Guide_Close()
	else
		if isrighttime < 0 then
			PushDebugMessage("#{RACL_181206_443}")
		else
			PushDebugMessage("#{RACL_181206_690}")
		end
    end
end

--=========
-- 预热 东风夜放
-- Notice : 基础判断条件觉得无用，直接删掉就可以，标注，该界面要进行重做，会更换成新UI，换新之后会将原逻辑移到新UI中
--=========
function SpringFestival_Guide_Client3_SignClicked()
	-- Notice: 判断功能无用，直接干掉就好
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
    local isrighttime = SpringFestival_Guide_IsRightTime(20)
    if isrighttime > 0 then
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("open")
        Set_XSCRIPT_ScriptID(893336)
        Set_XSCRIPT_Parameter(0, 1)
        Set_XSCRIPT_ParamCount(1)
        Send_XSCRIPT()
		
		PushDebugMessage("#{SYYR_191204_03}")
    else
        PushDebugMessage("#{RACL_181206_443}")
    end
end

--=========
-- 鬼市拍卖 银锤金案
--=========
function SpringFestival_Guide_Client3_AuctionClicked()

	local isrighttime = SpringFestival_Guide_IsRightTime(18)
	--local curDay = tonumber(DataPool:GetServerDayTime())
	--if curDay < 20200201 or curDay > 20200210 then
	if isrighttime <= 0 then
		PushDebugMessage("#{CJPM_191126_22}")
		return
	end
	
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{CJPM_191126_23}")
		return
	end

   Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowClientUI")
		Set_XSCRIPT_ScriptID(440003)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_Parameter(2, 0)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
        SpringFestival_Guide_Close()
end


--=========
-- 鬼市拍卖 全服分红 :包装名字 朱门传裕
--=========
function SpringFestival_Guide_Client3_DividendClicked()
	local nLevel = Player:GetLevel()
	if nLevel < 50 then
		PushDebugMessage("#{PMFH_191207_02}")
		return
	end

	local isrighttime = SpringFestival_Guide_IsRightTime(19)
	if (IsInTServer()  == 1) or (KVKInterface:IsInKVKServer() == 1) then
		PushDebugMessage("#{PMFH_191207_20}")
		return
	end
	if isrighttime > 0 then
		--Clear_XSCRIPT()
        --Set_XSCRIPT_Function_Name("OnOpenGSPM")
        --Set_XSCRIPT_ScriptID(893367) 
        --Set_XSCRIPT_ParamCount(0)
        --Send_XSCRIPT()			
        SpringFestival_Guide_Close()
	else
		if isrighttime < 0 then
			PushDebugMessage("#{PMFH_191207_01}")
		else
			PushDebugMessage("#{RACL_181206_691}")
		end
	end
end

--=========
-- 特写，给理财第三阶段提醒按钮使用
--=========

function SpringFestival_Guide_LicaiPao_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClickLiCaiPao")
		Set_XSCRIPT_ScriptID(893325) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
	
end

--========= 特写，给理财第三阶段提醒按钮使用 END =========
