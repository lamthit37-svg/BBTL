-- 2020春节主界面
-- 页签效果使用SpringFestival2_Guide
-- 滑动效果使用SpringFestival_Guide

local g_Frame_UnifiedPosition

--任务界面阶段
--1：引导任务执行界面 or 2：春节第一阶段界面
--2：春节第二阶段界面
--3：春节第三阶段界面
local g_CurPage = -1
local g_CurStep = -1
local g_PageCount = 3

--活动时间
local g_StartDay = 20210125	--第一阶段：20210125-20210207
local g_MidDay1 = 20210207	--第二阶段：20210208-20210218
local g_MidDay2 = 20210218	--第二阶段：20210208-20210218
local g_MidDay3 = 20210219	--第三阶段：20210219-20210314
local g_EndDay = 20210314

--活动按钮小红点
local g_RedPointInfo = {}

--活动页签
local g_PageButton = {}
local g_PageImages = 
{
	[1] = { pushimage="set:Springfestival04 image:SpringPage1_Pushed", normalimage="set:Springfestival04 image:SpringPage1_Normal", hovelimage="set:Springfestival04 image:SpringPage1_Hover"},
	[2] = { pushimage="set:Springfestival04 image:SpringPage2_Pushed", normalimage="set:Springfestival04 image:SpringPage2_Normal", hovelimage="set:Springfestival04 image:SpringPage2_Hover"},
	[3] = { pushimage="set:Springfestival04 image:SpringPage3_Pushed", normalimage="set:Springfestival04 image:SpringPage3_Normal", hovelimage="set:Springfestival04 image:SpringPage3_Hover"},
}

--npc关闭
local g_ObjCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

-- 活动等级限制
local g_LimitLevel = 30

--显隐列表
local g_ButtonShowList = {}
local g_isFstStart = 1		-- 是否开始第一阶段第一次更新 2021.01.25
local g_isFst_SecStart = 1		-- 是否开始第一阶段第二次更新 2021.01.28
local g_isSecStart = 1		-- 是否启动第二阶段 2021.02.08
local g_isThdStart = 1		-- 是否启动第三阶段，目前默认不用管 2021.02.18
local g_isThd_SecStart = 1		-- 是否启动第三阶段的第二次更新，目前默认不用管 2021.02.25

--=========
-- PreLoad
--=========
function SpringFestival2_Guide_PreLoad()
	
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
function SpringFestival2_Guide_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival2_Guide_Frame:GetProperty("UnifiedPosition") 
	g_PageButton = 
	{
		{ btn = SpringFestival2_Guide_Buttontab01, tips = SpringFestival2_Guide_Buttontab01_Tips, },
		{ btn = SpringFestival2_Guide_Buttontab02, tips = SpringFestival2_Guide_Buttontab02L_Tips, },
		{ btn = SpringFestival2_Guide_Buttontab03, tips = SpringFestival2_Guide_Buttontab03_Tips, },
	}
	
	g_RedPointInfo = 
	{
	--春节第一阶段界面
		{ page = 1, btn = SpringFestival2_Guide_YuReBtn, tips = SpringFestival2_Guide_YuReBtn_Tips, nScriptID = 888334, nUICommandID = 88833402, bShow = 0, }, --新增：春节预热活动设计--2020新增-锦宋觅清音
		{ page = 1, btn = SpringFestival2_Guide_HuameiBtn, tips = SpringFestival2_Guide_HuameiBtn_Tips, nScriptID = 892655, nUICommandID = 89265501, bShow = 0, }, --画梅--2020重开-朔雪寻梅
		{ page = 1, btn = SpringFestival2_Guide_QianLiBtn, tips = SpringFestival2_Guide_QianLiBtn_Tips, nScriptID = 888331, nUICommandID = 88833102, bShow = 0, }, --新增：千里江山图鉴--2020新增-山河雅韵鉴
		{ page = 1, btn = SpringFestival2_Guide_LiChengBtn, tips = SpringFestival2_Guide_LiChengBtn_Tips, nScriptID = 888333, nUICommandID = 88833301, bShow = 0, }, --新增：里程暴击--2020新增-繁花有赠
		{ page = 1, btn = SpringFestival2_Guide_DaSongBtn, tips = SpringFestival2_Guide_DaSongBtn_Tips, nScriptID = 888326, nUICommandID = 20122901, bShow = 0, }, --新增：春行大宋--2020新增-春暖踏歌行
		{ page = 1, btn = SpringFestival2_Guide_RiliBtn, tips = SpringFestival2_Guide_RiliBtn_Tips, nScriptID = 890801, nUICommandID = 89080102, bShow = 0, }, --日历--2020重开-千秋辞岁
		{ page = 1, btn = SpringFestival2_Guide_ZhuanpanBtn, tips = SpringFestival2_Guide_ZhuanpanBtn_Tips, nScriptID = 890803, nUICommandID = 89080302, bShow = 0, }, --转盘--2020重开-竹爆平安
		{ page = 1, btn = SpringFestival2_Guide_LicaiBtn, tips = SpringFestival2_Guide_LicaiBtn_Tips, nScriptID = 893324, nUICommandID = 89332400, bShow = 0, }, --理财--2020重开-新岁昇金
		{ page = 1, btn = SpringFestival2_Guide_WXH5Btn, tips = SpringFestival2_Guide_WXH5Btn_Tips, nScriptID = 893335, nUICommandID = 89333502, bShow = 0, }, --新增：春节微信活动游戏内部分--2020重开-乐暖春江
		{ page = 1, btn = SpringFestival2_Guide_GiftBtn, tips = SpringFestival2_Guide_GiftBtn_Tips, nScriptID = 888328, nUICommandID = 88832802, bShow = 0, }, --节日礼包--2020新增-春日礼包
		--春节第二阶段界面
		{ page = 2, btn = SpringFestival2_Guide_QifenBtn, tips = SpringFestival2_Guide_QifenBtn_Tips, nScriptID = 806030, nUICommandID = 80603001, bShow = 0, }, --汴京气氛--2020新增-琳琅艺闻录
		{ page = 2, btn = SpringFestival2_Guide_DaNianshouBtn, tips = SpringFestival2_Guide_DaNianshouBtn_Tips, nScriptID = 892662, nUICommandID = 89266201, bShow = 0, }, --打年兽--2020重开-戏年兽
		{ page = 2, btn = SpringFestival2_Guide_FeastBtn, tips = SpringFestival2_Guide_FeastBtn_Tips, nScriptID = 892660, nUICommandID = 89266202, bShow = 0, }, --团圆宴--2020重开-团圆宴
		{ page = 2, btn = SpringFestival2_Guide_ShanZhuangBtn, tips = SpringFestival2_Guide_ShanZhuangBtn_Tips, nScriptID = 893351, nUICommandID = 89335102, bShow = 0, }, --春节微信--2020重开-梦探江山
	--春节第三阶段界面		
		{ page = 3, btn = SpringFestival2_Guide_RiddleBtn, tips = SpringFestival2_Guide_RiddleBtn_Tips, nScriptID = 892384, nUICommandID = 89238400, bShow = 0, }, --猜灯谜--2020重开-花灯隐语
		{ page = 3, btn = SpringFestival2_Guide_PigBtn, tips = SpringFestival2_Guide_PigBtn_Tips, nScriptID = 892980, nUICommandID = 89298008, bShow = 0, }, --猜金猪--2020重开-三仙归位
		{ page = 3, btn = SpringFestival2_Guide_ShootBtn, tips = SpringFestival2_Guide_ShootBtn_Tips, nScriptID = 893021, nUICommandID = 89302126, bShow = 0, }, --射箭--2020重开-神射竞春
		{ page = 3, btn = SpringFestival2_Guide_MiaohuiShopBtn, tips = SpringFestival2_Guide_MiaohuiShopBtn_Tips, nScriptID = 890712, nUICommandID = 89071204, bShow = 0, }, --庙会商店--2020重开-百戏集市
		{ page = 3, btn = SpringFestival2_Guide_AuctionBtn, tips = SpringFestival2_Guide_AuctionBtn_Tips, nScriptID = -1, nUICommandID = -1, bShow = 0, }, --鬼市拍卖--2020重开-银锤金案
		{ page = 3, btn = SpringFestival2_Guide_DividendBtn, tips = SpringFestival2_Guide_DividendBtn_Tips, nScriptID = -1, nUICommandID = -1, bShow = 0, }, --拍卖分红--2020重开-朱门传裕
		{ page = 3, btn = SpringFestival2_Guide_SignBtn, tips = SpringFestival2_Guide_SignBtn_Tips, nScriptID = 893336, nUICommandID = 89333602, bShow = 0, }, --预热--2020重开-东风夜放
		{ page = 3, btn = SpringFestival2_Guide_LiumeituBtn, tips = SpringFestival2_Guide_LiumeituBtn_Tips, nScriptID = 893356, nUICommandID = 89335602, bShow = 0, }, --上元节六美图--2020重开-锦才会遇
		{ page = 3, btn = SpringFestival2_Guide_HuanwuBtn, tips = SpringFestival2_Guide_HuanwuBtn_Tips, nScriptID = 888345, nUICommandID = 88834502, bShow = 0, }, --新增：三阶段幻武放出--2020新增
	}
	
	g_ButtonShowList = {
		--春节第一阶段界面
		{ page = 1, btn = SpringFestival2_Guide_YuReBtn, image=SpringFestival2_Guide_YuReBtn_Image, starttime = 20210125, endtime = 20210131, showtime = 20210125, bshow = g_isFstStart, btntips_unbeg="#{SYCY_201225_177}", btntips_doing="#{SYCY_201225_176}", btntips_end="#{SYCY_201225_178}",btnName="YuReBtn", }, --新增：春节预热活动设计--2020新增-锦宋觅清音
		{ page = 1, btn = SpringFestival2_Guide_HuameiBtn, image=SpringFestival2_Guide_HuameiBtn_Image,  starttime = 20210128, endtime = 20210214, showtime = 20210128, bshow = g_isFst_SecStart, btntips_unbeg="#{HMLZ_210107_01}", btntips_doing="#{HMLZ_210107_02}", btntips_end="#{HMLZ_210107_03}",btnName="HuameiBtn", }, --画梅--2020重开-朔雪寻梅
		{ page = 1, btn = SpringFestival2_Guide_QianLiBtn, image=nil, starttime = 20210125, endtime = 20210314, showtime = 20210125, bshow = g_isFstStart, btntips_unbeg="#{RACL_201224_38}", btntips_doing="#{DHSZ_201218_03}", btntips_end="#{RACL_201224_40}",btnName="QianLiBtn",}, --新增：千里江山图鉴--2020新增-山河雅韵鉴
		{ page = 1, btn = SpringFestival2_Guide_LiChengBtn,image=nil, starttime = 20210128, endtime = 20210210, showtime = 20210128, bshow = g_isFst_SecStart, btntips_unbeg="#{SRLQY_210115_01}", btntips_doing="#{SRLQY_210115_02}", btntips_end="#{SRLQY_210115_03}",btnName="LiChengBtn", }, --新增：里程暴击--2020新增-繁花有赠
		{ page = 1, btn = SpringFestival2_Guide_DaSongBtn, image=nil, starttime = 20210125, endtime = 20210210, showtime = 20210125, bshow = g_isFstStart, btntips_unbeg="#{CXDS_201224_02}", btntips_doing="#{CXDS_201224_01}", btntips_end="#{CXDS_201224_02}", btnName="DaSongBtn",}, --新增：春行大宋--2020新增-春暖踏歌行
		{ page = 1, btn = SpringFestival2_Guide_RiliBtn, image=nil, starttime = 20220117, endtime = 20220131, showtime = 20220117, bshow = g_isFst_SecStart, btntips_unbeg="#{LYYJ_181206_68}", btntips_doing="#{LYYJ_181206_67}", btntips_end="#{LYYJ_181206_69}", btnName="RiliBtn",}, --日历--2020重开-千秋辞岁
		{ page = 1, btn = SpringFestival2_Guide_ZhuanpanBtn, image=SpringFestival2_Guide_ZhuanpanBtn_Image, starttime = 20220117, endtime = 20220130, showtime = 20220117, bshow = g_isFst_SecStart, btntips_unbeg="#{LYYJ_181206_71}", btntips_doing="#{LYYJ_181206_70}", btntips_end="#{LYYJ_181206_69}", btnName="ZhuanpanBtn",}, --转盘--2020重开-竹爆平安
		{ page = 1, btn = SpringFestival2_Guide_LicaiBtn, image=nil, starttime = 20210125, endtime = 20210225, showtime = 20210125, bshow = g_isFstStart, btntips_unbeg="#{SZYG_210115_01}", btntips_doing="#{SZYG_210115_02}", btntips_end="#{SZYG_210115_03}", btnName="LicaiBtn",}, --理财--2020重开-新岁昇金
		{ page = 1, btn = SpringFestival2_Guide_WXH5Btn, image=SpringFestival2_Guide_WXH5Btn_Image, starttime = 20210128, endtime = 20210203, showtime = 20210128, bshow = g_isFst_SecStart, btntips_unbeg="#{SZYS_210104_04}", btntips_doing="#{SZYS_210104_03}", btntips_end="#{SZYS_210104_05}", btnName="WXH5Btn",}, --新增：春节微信活动游戏内部分--2020重开-乐暖春江
		{ page = 1, btn = SpringFestival2_Guide_GiftBtn, image=nil, starttime = 20210128, endtime = 20210210, showtime = 20210128, bshow = g_isFst_SecStart, btntips_unbeg="#{RACL_201224_43}", btntips_doing="#{RACL_201224_13}", btntips_end="#{RACL_201224_40}", btnName="GiftBtn",}, --节日礼包--2020新增-春日礼包
		--春节第二阶段界面
		{ page = 2, btn = SpringFestival2_Guide_QifenBtn, image=nil, starttime = 20210208, endtime = 20210228, showtime = 20210208, bshow = g_isSecStart, btntips_unbeg="#{RACL_201224_38}", btntips_doing="#{BJFW_210105_04}", btntips_end="#{BJFW_210105_05}", btnName="QifenBtn",}, --汴京气氛--2020新增-琳琅艺闻录
		{ page = 2, btn = SpringFestival2_Guide_DaNianshouBtn, image=nil, starttime = 20210208, endtime = 20210218, showtime = 20210208, bshow = g_isSecStart, btntips_unbeg="#{YSTYY_180106_165}", btntips_doing="#{YSTYY_180106_164}", btntips_end="#{YSTYY_180106_166}", btnName="DaNianshouBtn",}, --打年兽--2020重开-戏年兽
		{ page = 2, btn = SpringFestival2_Guide_FeastBtn, image=nil, starttime = 20210208, endtime = 20210218, showtime = 20210208, bshow = g_isSecStart, btntips_unbeg="#{YSTYY_180106_168}", btntips_doing="#{YSTYY_180106_167}", btntips_end="#{YSTYY_180106_166}", btnName="FeastBtn",}, --团圆宴--2020重开-团圆宴
		{ page = 2, btn = SpringFestival2_Guide_ShanZhuangBtn, image=nil, starttime = 20210211, endtime = 20210218, showtime = 20210208, bshow = g_isSecStart, btntips_unbeg="#{CJWX_191207_17}", btntips_doing="#{CJWX_191207_18}", btntips_end="#{CJWX_191207_19}", btnName="ShanZhuangBtn",}, --春节微信--2020重开-梦探江山
		--春节第三阶段界面		
		{ page = 3, btn = SpringFestival2_Guide_RiddleBtn, image=nil, starttime = 20210219, endtime = 20210310, showtime = 20210219, bshow = g_isThdStart, btntips_unbeg="#{YXCDM_210108_02}", btntips_doing="#{YXCDM_210108_01}", btntips_end="#{YXCDM_210108_03}", btnName="RiddleBtn",}, --猜灯谜--2020重开-花灯隐语
		{ page = 3, btn = SpringFestival2_Guide_PigBtn, image=nil, starttime = 20210219, endtime = 20210310, showtime = 20210219, bshow = g_isThdStart, btntips_unbeg="#{KWCQ_201225_09}", btntips_doing="#{KWCQ_201225_05}", btntips_end="#{KWCQ_201225_06}", btnName="PigBtn",}, --猜金猪--2020重开-三仙归位
		{ page = 3, btn = SpringFestival2_Guide_ShootBtn, image=nil, starttime = 20210219, endtime = 20210310, showtime = 20210219, bshow = g_isThdStart, btntips_unbeg="#{YXSJ_181204_78}", btntips_doing="#{YXSJ_181204_77}", btntips_end="#{YXSJ_181204_79}", btnName="ShootBtn",}, --射箭--2020重开-神射竞春
		{ page = 3, btn = SpringFestival2_Guide_MiaohuiShopBtn, image=nil, starttime = 20210219, endtime = 20210314, showtime = 20210219, bshow = g_isThdStart, btntips_unbeg="#{RACL_201224_38}", btntips_doing="#{MHSD_210104_16}", btntips_end="#{RACL_201224_40}", btnName="MiaohuiShopBtn",}, --庙会商店--2020重开-百戏集市
		{ page = 3, btn = SpringFestival2_Guide_AuctionBtn, image=nil, starttime = 20210219, endtime = 20210228, showtime = 20210219, bshow = g_isThdStart, btntips_unbeg="#{CJPM_191126_24}", btntips_doing="#{CJPM_191126_24}", btntips_end="#{CJPM_191126_24}", btnName="AuctionBtn",}, --鬼市拍卖--2020重开-银锤金案
		{ page = 3, btn = SpringFestival2_Guide_DividendBtn, image=nil, starttime = 20210227, endtime = 20210310, showtime = 20210225, bshow = g_isThd_SecStart, btntips_unbeg="#{RACL_201224_38}", btntips_doing="#{RACL_201224_39}", btntips_end="#{RACL_201224_40}", btnName="DividendBtn",}, --拍卖分红--2020重开-朱门传裕
		{ page = 3, btn = SpringFestival2_Guide_SignBtn, image=nil, starttime = 20210219, endtime = 20210226, showtime = 20210219, bshow = g_isThdStart, btntips_unbeg="#{SYYR_191204_49}", btntips_doing="#{SYYR_191204_48}", btntips_end="#{SYYR_191204_50}", btnName="SignBtn",}, --预热--2020重开-东风夜放
		{ page = 3, btn = SpringFestival2_Guide_LiumeituBtn, image=nil, starttime = 20210225, endtime = 20210226, showtime = 20210225, bshow = g_isThd_SecStart, btntips_unbeg="#{RACL_201224_38}", btntips_doing="#{RACL_201224_39}", btntips_end="#{RACL_201224_40}", btnName="LiumeituBtn",}, --上元节六美图--2020重开-锦才会遇
		{ page = 3, btn = SpringFestival2_Guide_HuanwuBtn, image=nil, starttime = 20210219, endtime = 20210310, showtime = 20210219, bshow = g_isThdStart, btntips_unbeg="#{YHSQ_210105_05}", btntips_doing="#{YHSQ_210105_05}", btntips_end="#{YHSQ_210105_05}", btnName="HuanwuBtn",}, --新增：三阶段幻武放出--2020新增
	}
	--请求所有小红点
	SpringFestival2_Guide_InitRedPoint()

end

--=========
-- 初始化活动小红点
--=========
function SpringFestival2_Guide_InitRedPoint()

	-- 清空小红点
	for i = 1, table.getn(g_RedPointInfo) do
		g_RedPointInfo[i].bShow = 0
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateAllRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()

	-- 更新主界面快捷按钮小红点
	SpringFestival2_Guide_UpdateQuickEnter()
	
end

--=========
-- 更新活动小红点
--=========
function SpringFestival2_Guide_UpdateRedPoint()

	--活动小红点
	for i = 1, table.getn(g_RedPointInfo) do
		if g_RedPointInfo[i].tips ~= nil then
			g_RedPointInfo[i].tips:Hide()
			if g_RedPointInfo[i].page == g_CurPage and g_RedPointInfo[i].bShow == 1 then
				g_RedPointInfo[i].tips:Show()
			end
		end
	end

	-- 是否有更新标识	
	if g_isThdStart > 0 then
		SpringFestival2_Guide_UpdatePageRedPoint0211()
	elseif g_isSecStart > 0 then
		SpringFestival2_Guide_UpdatePageRedPoint0131()
	elseif g_isFstStart > 0 then
		SpringFestival2_Guide_UpdatePageRedPoint0117()
	end
end

--=========
-- 更新活动小红点
--=========
function SpringFestival2_Guide_UpdatePageRedPoint0117()
	
	local validIndex = 1
	for i=1, table.getn(g_PageButton) do
		local nCount = 0
		for j=1, table.getn(g_RedPointInfo) do
			if g_RedPointInfo[j].tips ~= nil and g_RedPointInfo[j].page == i and g_RedPointInfo[j].bShow == 1 then
				nCount = nCount + 1
			end
		end

		if nCount > 0 and i <= validIndex then
			g_PageButton[i].tips:Show()
		else
			g_PageButton[i].tips:Hide()
		end
	end
	
end

--=========
-- 更新活动小红点
--=========
function SpringFestival2_Guide_UpdatePageRedPoint0131()
	
	local validIndex = 2
	for i=1, table.getn(g_PageButton) do
		local nCount = 0
		for j=1, table.getn(g_RedPointInfo) do
			if g_RedPointInfo[j].tips ~= nil and g_RedPointInfo[j].page == i and g_RedPointInfo[j].bShow == 1 then
				nCount = nCount + 1
			end
		end

		if nCount > 0 and i <= validIndex then
			g_PageButton[i].tips:Show()
		else
			g_PageButton[i].tips:Hide()
		end
	end
	
end

--=========
-- 更新活动小红点
--=========
function SpringFestival2_Guide_UpdatePageRedPoint0211()
	
	local validIndex = 3
	for i=1, table.getn(g_PageButton) do
		local nCount = 0
		for j=1, table.getn(g_RedPointInfo) do
			if g_RedPointInfo[j].tips ~= nil and g_RedPointInfo[j].page == i and g_RedPointInfo[j].bShow == 1 then
				nCount = nCount + 1
			end
		end

		if nCount > 0 and i <= validIndex then
			g_PageButton[i].tips:Show()
		else
			g_PageButton[i].tips:Hide()
		end
	end
	
end

--=========
-- 更新主界面快捷按钮小红点
--=========
function SpringFestival2_Guide_UpdateQuickEnter()

	local bShow = 0
	
	for i = 1, table.getn(g_RedPointInfo) do
		if 1 == g_RedPointInfo[i].bShow then
			bShow = 1
			break
		end
	end
	
	--PushEvent("SPRINGGUIDEMISSION_QUICKENTER", bShow)
	Lua_ShowQuickEnterPointTip(15, bShow)
end

--=========
-- OnEvent
--=========
function SpringFestival2_Guide_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89298502 then
	
		local nPage = Get_XParam_INT(0)
		local nStep = Get_XParam_INT(1)
		if nPage > 0 then
			if nPage == 1 and nStep == 999 then--特写：若当前页面开着则更新页签选中状态
				if this:IsVisible() then
					for i=1, table.getn(g_PageButton) do
						if g_CurPage == i then							
							g_PageButton[i].btn:SetProperty("PushedImage", g_PageImages[i].pushimage)
							g_PageButton[i].btn:SetCheck(1)
						else
							g_PageButton[i].btn:SetProperty("PushedImage", g_PageImages[i].hovelimage)
							g_PageButton[i].btn:SetCheck(0)
						end
					end
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
						this:CareObject(g_ObjCared, 1, "SpringFestival2_Guide");
					end
				end
				--SpringFestival2_Guide_InitRedPoint()--请求所有小红点
				SpringFestival2_Guide_Update(nPage,nStep)
			end
		end
		
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 88832801) then	--节日礼包特写
	
		local bShow = Get_XParam_INT(0)
		if bShow == 2 then
			g_ButtonShowList[10].btn:Hide()
		end
				
	elseif event == "UI_COMMAND" then
	
		for i = 1, table.getn(g_RedPointInfo) do
			if tonumber( arg0 ) == tonumber(g_RedPointInfo[i].nUICommandID) then
				local nScriptID = Get_XParam_INT(0)
				local bShow = Get_XParam_INT(1)
				if tonumber( nScriptID ) ~= nil and tonumber( nScriptID ) > 0 and tonumber( nScriptID ) == tonumber(g_RedPointInfo[i].nScriptID) then
					g_RedPointInfo[i].bShow = bShow
					--刷新界面
					if this:IsVisible() then
						--SpringFestival2_Guide_Update(g_CurPage)
						--更新活动小红点
						SpringFestival2_Guide_UpdateRedPoint()
						--更新主界面快捷按钮小红点
						SpringFestival2_Guide_UpdateQuickEnter()
					else
						--更新主界面快捷按钮小红点
						SpringFestival2_Guide_UpdateQuickEnter()
					end
				end
				--跳出
				break
			end
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival2_Guide_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
	
		SpringFestival2_Guide_Close()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival2_Guide_On_ResetPos()

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
			SpringFestival2_Guide_Close()
		end
	elseif (event == "CLOSE_SPRINGFES_GUIDE") then
		SpringFestival2_Guide_Close()
	end

end

--=========
-- 重置
--=========
function SpringFestival2_Guide_On_ResetPos()

	SpringFestival2_Guide_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 切换分页
--=========
function SpringFestival2_Guide_Switch(nPage)

	if nPage == nil or nPage <= 0 or nPage > g_PageCount then
		return
	end
	
	for i=1, table.getn(g_PageButton) do
		if g_CurPage == i then							
			g_PageButton[i].btn:SetProperty("PushedImage", g_PageImages[i].pushimage)
			g_PageButton[i].btn:SetCheck(1)
		else
			g_PageButton[i].btn:SetProperty("PushedImage", g_PageImages[i].hovelimage)
			g_PageButton[i].btn:SetCheck(0)
		end
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
function SpringFestival2_Guide_Update(nPage,nStep)

	if nPage == nil or nPage <= 0 or nPage > g_PageCount then	
		return		
	end
	if nStep == nil or nStep < 0 then
		return
	end

	g_CurPage = nPage
	g_CurStep = nStep
	for i=1, table.getn(g_PageButton) do
		if g_CurPage == i then							
			g_PageButton[i].btn:SetProperty("PushedImage", g_PageImages[i].pushimage)
			g_PageButton[i].btn:SetCheck(1)
		else
			g_PageButton[i].btn:SetProperty("PushedImage", g_PageImages[i].hovelimage)
			g_PageButton[i].btn:SetCheck(0)
		end
	end
	
	-- 全部隐藏
	SpringFestival2_Guide_Client1:Hide()
	SpringFestival2_Guide_Client2:Hide()
	SpringFestival2_Guide_Client3:Hide()
	
	-- 更新当前页
	if nPage == 1 then--引导任务执行阶段 or 春节第一阶段
		if nStep == 1 then
			SpringFestival2_Guide_Update1()
		end
	elseif nPage == 2 then--春节第二阶段
		SpringFestival2_Guide_Update2()
	elseif nPage == 3 then--春节第三阶段
		SpringFestival2_Guide_Update3()
	end
	
	SpringFestival2_Guide_BtnShowByTime(nPage)

	-- 显示
	this:Show()	

	--更新活动小红点
	SpringFestival2_Guide_UpdateRedPoint()
	--更新主界面快捷按钮小红点
	SpringFestival2_Guide_UpdateQuickEnter()
	
	--设置页签tips
	SpringFestival2_Guide_UpdatePageButtonTips()
	
end

--=========
-- 更新页签tips
--=========
function SpringFestival2_Guide_UpdatePageButtonTips()

	local curDay = tonumber(DataPool:GetServerDayTime())
	--页签1
	SpringFestival2_Guide_Buttontab01 : SetToolTip("#{RACL_201224_33}")

	--页签2
	if (curDay >= g_StartDay and curDay <= g_MidDay1) or g_isSecStart < 1 then
		SpringFestival2_Guide_Buttontab02 : SetToolTip("#{RACL_181206_675}")
	elseif curDay > g_MidDay1 then
		SpringFestival2_Guide_Buttontab02 : SetToolTip("#{RACL_201224_34}")
	end	
	
	--页签3
	if curDay >= g_StartDay and curDay < g_MidDay3 then
		SpringFestival2_Guide_Buttontab03 : SetToolTip("#{RACL_181206_676}")
	elseif curDay >= g_MidDay3 then
		SpringFestival2_Guide_Buttontab03 : SetToolTip("#{RACL_201224_35}")
	end
	
end

--=========
-- 春节第一阶段显示
--=========
function SpringFestival2_Guide_Update1()	
	SpringFestival2_Guide_Client1:Show()
end

--=========
-- 春节第二阶段显示
--=========
function SpringFestival2_Guide_Update2()
	SpringFestival2_Guide_Client2:Show()
end

--=========
-- 春节第三阶段显示
--=========
function SpringFestival2_Guide_Update3()
	SpringFestival2_Guide_Client3:Show()
end

--=========
-- 分阶段显示内容
--=========
function SpringFestival2_Guide_BtnShowByTime(page)
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
					if item.image ~= nil then
						item.image:Hide()
					end
				else
					local curDay = tonumber(DataPool:GetServerDayTime())
					local curMinute = tonumber(DataPool:GetServerMinuteTime())					
					local curHour = math.floor(curMinute/10000)
					if curDay >= item.showtime and curDay <= item.endtime then
						item.btn:Show()
						if item.image ~= nil then
							item.image:Show()
						end
						if item.btnName=="LiumeituBtn" then
							--六美图需要精确到小时
							--增加按钮tips分时间显示
							if curDay < item.starttime then
								item.btn:SetToolTip(item.btntips_unbeg)
							elseif curDay >= item.starttime and curDay <= item.endtime then
								if curDay == item.endtime  and curHour>=20 then
									item.btn:SetToolTip("#{SYLM_210108_01}")
								else
									item.btn:SetToolTip("#{SYLM_210108_02}")
								end																		
							elseif curDay > item.endtime then
								item.btn:SetToolTip("#{SYLM_210108_03}")
							end
						else
							--增加按钮tips分时间显示
							if curDay < item.starttime then
								item.btn:SetToolTip(item.btntips_unbeg)
							elseif curDay >= item.starttime and curDay <= item.endtime then
								item.btn:SetToolTip(item.btntips_doing)
							elseif curDay > item.endtime then
								item.btn:SetToolTip(item.btntips_end)
							end
						end
					
					else
						item.btn:Hide()
						if item.image ~= nil then
							item.image:Hide()
						end
					end
				end
			end
		end
	end
	
	if Pneuma:GetMF(3019) == 1 then--节日礼包特写
		g_ButtonShowList[10].btn:Hide()
	end

end

function SpringFestival2_Guide_BtnHideByTime()
	local listcount = table.getn(g_ButtonShowList)
	for i=1, listcount do
		local item = g_ButtonShowList[i]
		if item ~= nil then	
			item.btn:Hide()
			if item.image ~= nil then
				item.image:Hide()
			end
		end
	end
end

--=========
-- 是否正确的时间
--=========
function SpringFestival2_Guide_IsRightTime(nIndex)
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
-- 关闭
--=========
function SpringFestival2_Guide_Close()

	SpringFestival2_Guide_OnHiden()
	this:Hide()
	
end

--=========
-- 隐藏
--=========
function SpringFestival2_Guide_OnHiden()

	g_CurPage = -1
	g_CurStep = -1
	
	this:CareObject(g_ObjCared, 0, "SpringFestival2_Guide");
	g_ObjCared = -1;

end

------------------------------------------------------------春节第一阶段
--=========
-- 预热
--=========
function SpringFestival2_Guide_Client1_YuReClicked()
	
	local isrighttime = SpringFestival2_Guide_IsRightTime(1)
	if isrighttime <= 0 then
		PushDebugMessage("#{RACL_181206_443}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWindowRequest")
		Set_XSCRIPT_ScriptID(888334)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--=========
-- 千里江山
--=========
function SpringFestival2_Guide_Client1_QianLiClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(888331)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--=========
-- 里程暴击
--=========
function SpringFestival2_Guide_Client1_LiChengClicked()
	-- 检查活动时间
	local isrighttime = SpringFestival2_Guide_IsRightTime(4)
	if isrighttime <= 0 then
		PushDebugMessage("#{SRLQY_201230_40}")
		return
	end


	if IsInTServer()  == 1 then
		PushDebugMessage("#{SRLQY_201230_42}")
		return 
	end

	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnOpenUI")
	Set_XSCRIPT_ScriptID(888333)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--=========
-- 春行大宋
--=========
function SpringFestival2_Guide_Client1_DaSongClicked()
	-- 检查玩家等级
	local curLevel = Player:GetData("LEVEL")
	if (curLevel < 30) then
		PushDebugMessage("#{CXDS_201224_03}")
		return
	end

	-- 检查活动时间
	local isrighttime = SpringFestival2_Guide_IsRightTime(5)
	if isrighttime <= 0 then
		PushDebugMessage("#{CXDS_201224_04}")
		return
	end

	PushEvent("CXDS_UI_OPEN")
	SpringFestival2_Guide_Close()
end

--=========
-- 节日礼包
--=========
function SpringFestival2_Guide_Client1_GiftClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenUI")
		Set_XSCRIPT_ScriptID(888328)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

--=========
-- 彩蛋
--=========
function SpringFestival2_Guide_Client1_CaidanClicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenSpringCaiDan")
		Set_XSCRIPT_ScriptID(893000)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	
end

--=========
-- 喝酒
--=========
function SpringFestival2_Guide_Client1_HejiuClicked()
	local isrighttime = SpringFestival2_Guide_IsRightTime(0)
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
function SpringFestival2_Guide_Client1_ShopClicked()
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
function SpringFestival2_Guide_Client1_ZhuanpanClicked()
	local isrighttime = SpringFestival2_Guide_IsRightTime(7)
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
	SpringFestival2_Guide_Close()
end

--=========
-- 画梅
--=========
function SpringFestival2_Guide_Client1_HuameiClicked()	
	local isrighttime = SpringFestival2_Guide_IsRightTime(2)
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
	
	SpringFestival2_Guide_Close()
	
end

--=========
-- 日历
--=========
function SpringFestival2_Guide_Client1_RiliClicked()

	local isrighttime = SpringFestival2_Guide_IsRightTime(6)
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
function SpringFestival2_Guide_Client1_RedPacketClicked()

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
function SpringFestival2_Guide_Client1_HelpClicked()

	PushEvent("SPRINGGUIDEMISSION_JIXIANGFUHELP",1)
	
end

--=========
-- 琳琅艺闻录--新增：汴京氛围设计
--=========
function SpringFestival2_Guide_Client1_QifenClicked()

	local isrighttime = SpringFestival2_Guide_IsRightTime(11)
	if isrighttime <= 0 then
		PushDebugMessage("#{RACL_181206_443}")
		return
	end
	local nLevel = Player:GetLevel();
	if nLevel < 85 then
		PushDebugMessage("#{BJFW_210105_02}")
		return
	end

	Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OnOpenBJFWUI")
    Set_XSCRIPT_ScriptID(806030)
    Set_XSCRIPT_Parameter(0, 1)
    Set_XSCRIPT_ParamCount(1)
   Send_XSCRIPT()
end

------------------------------------------------------------春节第二阶段
--=========
-- 山庄
--=========
function SpringFestival2_Guide_Client2_ShanZhuangClicked()

	local isrighttime = SpringFestival2_Guide_IsRightTime(14)
	if isrighttime <= 0 then
		if isrighttime < 0 then
			PushDebugMessage("#{CJWX_191207_20}")
		else
			PushDebugMessage("#{CJWX_191207_20}")
		end
		return
	end
	
	local nLevel = Player:GetLevel();
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{CJWX_191207_21}")
		return
	end

	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name( "OnOpenSpringFirstDreamWindow" )
	Set_XSCRIPT_ScriptID( 985577 )
	Set_XSCRIPT_Parameter(0, -1)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
		

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
		Set_XSCRIPT_ScriptID( 892985 )
		Set_XSCRIPT_Parameter(0, 893351)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

--=========
-- 打年兽
--=========
function SpringFestival2_Guide_Client2_DaNianshouClicked()
	local isrighttime = SpringFestival2_Guide_IsRightTime(12)
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
		
	SpringFestival2_Guide_Close()
	
end

--=========
-- 团圆宴
--=========
function SpringFestival2_Guide_Client2_FeastClicked()
	
	local isrighttime = SpringFestival2_Guide_IsRightTime(13)
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
		
	SpringFestival2_Guide_Close()
	
end

--=========
-- 写春联
--=========
function SpringFestival2_Guide_Client2_ChunLianClicked()

	--
	
end

--=========
-- 大扫除
--=========
function SpringFestival2_Guide_Client2_CleanClicked()

	--
	
end

--=========
-- 挂福字
--=========
function SpringFestival2_Guide_Client2_FontClicked()

	--
	
end

--=========
-- 答疑
--=========
function SpringFestival2_Guide_Client2_HelpClicked()

	PushEvent("SPRINGGUIDEMISSION_JIXIANGFUHELP",2)
	
end

------------------------------------------------------------春节第三阶段
--=========
-- 庙会商店
--=========
function SpringFestival2_Guide_Client3_MiaohuiShopClicked()

	local isrighttime = SpringFestival2_Guide_IsRightTime(18)
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
function SpringFestival2_Guide_Client3_PickClicked()
	local isrighttime = SpringFestival2_Guide_IsRightTime(0)
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
	SpringFestival2_Guide_Close()
end

--=========
-- 猜金猪
--=========
function SpringFestival2_Guide_Client3_PigClicked()

	local isrighttime = SpringFestival2_Guide_IsRightTime(16)
	if isrighttime <= 0 then
		PushDebugMessage("#{KWCQ_201225_07}")
		return
	end

	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{KWCQ_201225_08}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGotoDispatchNPC" );
		Set_XSCRIPT_ScriptID( 892980 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()

	SpringFestival2_Guide_Close()
end

--=========
-- 射箭
--=========
function SpringFestival2_Guide_Client3_ShootClicked()

	local isrighttime = SpringFestival2_Guide_IsRightTime(17)
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
	SpringFestival2_Guide_Close()

end

--=========
-- 猜灯谜
--=========
function SpringFestival2_Guide_Client3_RiddleClicked()

	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	
	local isrighttime = SpringFestival2_Guide_IsRightTime(15)
	if isrighttime > 0 then
		AutoRuntoTargetExWithName(274, 341, 0, "蔡弥")
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateRedPoint" );
			Set_XSCRIPT_ScriptID( 892384 );	
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount( 1 );
		Send_XSCRIPT()			
		PushDebugMessage("#{RACL_181206_658}")
		SpringFestival2_Guide_Close()
	else
		PushDebugMessage("#{RACL_181206_443}")
	end
	
end

--=========
-- 答疑
--=========
function SpringFestival2_Guide_Client3_HelpClicked()

	PushEvent("SPRINGGUIDEMISSION_JIXIANGFUHELP",3)
	
end

--=========
-- 预售
--=========
function SpringFestival2_Guide_Client1_YushouClicked()

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
function SpringFestival2_Guide_Client1_LicaiClicked()

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
function SpringFestival2_Guide_Client1_WXH5Clicked()
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{SZYS_191202_02}") --您的等级不足30级，无法参与此活动。
		return
	end
	-- 这里有第一阶段三期更新开关判断
	local isrighttime = SpringFestival2_Guide_IsRightTime(9)
	if isrighttime > 0 then
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("open")
        Set_XSCRIPT_ScriptID(893335)
        Set_XSCRIPT_Parameter(0, 1)
        Set_XSCRIPT_ParamCount(1)
        Send_XSCRIPT()			
        SpringFestival2_Guide_Close()
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
function SpringFestival2_Guide_Client3_FireworkClicked()
	-- Notice: 判断功能无用，直接干掉就好
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	local isrighttime = SpringFestival2_Guide_IsRightTime(0)
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
function SpringFestival2_Guide_Client3_BeautyClicked()
	-- Notice: 判断功能无用，直接干掉就好
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
	local isrighttime = SpringFestival2_Guide_IsRightTime(0)
	if isrighttime > 0 then
        Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("open")
			Set_XSCRIPT_ScriptID(893356)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
        SpringFestival2_Guide_Close()
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
function SpringFestival2_Guide_Client3_SignClicked()
	-- Notice: 判断功能无用，直接干掉就好
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{RACL_181206_444}")
		return
	end
    local isrighttime = SpringFestival2_Guide_IsRightTime(21)
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
function SpringFestival2_Guide_Client3_AuctionClicked()

	local isrighttime = SpringFestival2_Guide_IsRightTime(19)
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
        SpringFestival2_Guide_Close()
end


--=========
-- 鬼市拍卖 全服分红 :包装名字 朱门传裕
--=========
function SpringFestival2_Guide_Client3_DividendClicked()
	local nLevel = Player:GetLevel()
	if nLevel < 50 then
		PushDebugMessage("#{PMFH_191207_02}")
		return
	end

	local isrighttime = SpringFestival2_Guide_IsRightTime(18)
	if (IsInTServer()  == 1) or (KVKInterface:IsInKVKServer() == 1) then
		PushDebugMessage("#{PMFH_191207_20}")
		return
	end
	if isrighttime > 0 then
		-- Clear_XSCRIPT()
		-- Set_XSCRIPT_Function_Name("OnOpenGSPM")
		-- Set_XSCRIPT_ScriptID(893367) 
		-- Set_XSCRIPT_ParamCount(0)
		-- Send_XSCRIPT()			
        SpringFestival2_Guide_Close()
	else
		if isrighttime < 0 then
			PushDebugMessage("#{PMFH_191207_01}")
		else
			PushDebugMessage("#{RACL_181206_691}")
		end
	end
end

--=========
-- 锦才会遇-上京六美图
--=========
function SpringFestival2_Guide_Liumeitu_Clicked()

	local isrighttime = SpringFestival2_Guide_IsRightTime(22)
	if isrighttime <= 0 then
		PushDebugMessage("#{RACL_181206_443}")
		return
	else
-- 判定时间
		local item = g_ButtonShowList[22]
		local curDay = tonumber(DataPool:GetServerDayTime())
		local curMinute = tonumber(DataPool:GetServerMinuteTime())					
		local curHour = math.floor(curMinute/10000)
		if item ~= nil then
			if curDay == item.endtime then
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("open")
					Set_XSCRIPT_ScriptID(893356)
					Set_XSCRIPT_Parameter(0, 1)
					Set_XSCRIPT_ParamCount(1)
				Send_XSCRIPT()
				SpringFestival2_Guide_Close()				
			else				
				PushDebugMessage("#{RACL_181206_443}")
			end		
		end				
	end
	
end

--=========
-- 三阶段幻武放出
--=========
function SpringFestival2_Guide_Huanwu_Clicked()

	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{YHSQ_210105_06}")
		return
	end

	local isRightTime = SpringFestival2_Guide_IsRightTime(18)

	if isRightTime > 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnOpenHuanwu")
			Set_XSCRIPT_ScriptID(888345) 
			Set_XSCRIPT_ParamCount(0)
        Send_XSCRIPT()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
			Set_XSCRIPT_ScriptID( 892985 )
			Set_XSCRIPT_Parameter(0, 888345)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()			
        SpringFestival2_Guide_Close()
	else
		PushDebugMessage("#{YHSQ_210105_07}")
	end
	
end


--=========
-- 特写，给理财第三阶段提醒按钮使用
--=========

function SpringFestival2_Guide_LicaiPao_Clicked()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClickLiCaiPao")
		Set_XSCRIPT_ScriptID(893325) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
	
end

--========= 特写，给理财第三阶段提醒按钮使用 END =========
