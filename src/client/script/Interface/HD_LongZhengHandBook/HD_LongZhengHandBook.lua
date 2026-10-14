-------------------------------------------------------
-- 龙征11载纪念册 by lishilong 2018-3-17
-------------------------------------------------------
local ITEM_ID = -1
local FIVEYEAR_NPC_ID = -1
local objCared = -1
local MAX_OBJ_DISTANCE = 3.0;
local g_HD_LongZhengHandBook_Frame_UnifiedPosition = nil;
local g_nUICommand	= 920170216

local g_nSelectedPage = 1

-- 2018年重开
-- 1	首页	set:LZ_HandBook8 image:HandBook_Page_L	set:LZ_HandBook20 image:HandBook_Page_R
-- 2	2007年	set:LZ_HandBook17 image:HandBook_Page_07L	set:LZ_HandBook23 image:HandBook_Page_07R
-- 3	20082009	set:LZ_HandBook16 image:HandBook_Page_0809L	set:LZ_HandBook23 image:HandBook_Page_1011R
-- 4	20102011	set:LZ_HandBook15 image:HandBook_Page_1011L	set:LZ_HandBook22 image:HandBook_Page_1011R
-- 5	20122013	set:LZ_HandBook14 image:HandBook_Page_1213L	set:LZ_HandBook22 image:HandBook_Page_1213R
-- 6	20142015	set:LZ_HandBook13 image:HandBook_Page_1415L	set:LZ_HandBook22 image:HandBook_Page_1415R
-- 7	20162017	set:LZ_HandBook12 image:HandBook_Page_1617L	set:LZ_HandBook21 image:HandBook_Page_1617R
-- 8	天龙、峨嵋	set:LZ_HandBook4 image:HandBook_Page_TEL	set:LZ_HandBook19 image:HandBook_Page_TER
-- 9	少林、天上	set:LZ_HandBook6 image:HandBook_Page_SLL	set:LZ_HandBook19 image:HandBook_Page_SLR
-- 10	丐帮、武当	set:LZ_HandBook10 image:HandBook_Page_GWL	set:LZ_HandBook21 image:HandBook_Page_GWR
-- 11	明教、星宿	set:LZ_HandBook7 image:HandBook_Page_MXL	set:LZ_HandBook20 image:HandBook_Page_MXR
-- 12	逍遥、慕容	set:LZ_HandBook3 image:HandBook_Page_XML	set:LZ_HandBook18 image:HandBook_Page_XMR
-- 13	唐门、鬼谷	set:LZ_HandBook11 image:HandBook_Page_GTL	set:LZ_HandBook21 image:HandBook_Page_GTR
-- 14	时装篇	set:LZ_HandBook5 image:HandBook_Page_ZSL	set:LZ_HandBook19 image:HandBook_Page_ZSR
-- 15	坐骑篇	set:LZ_HandBook2 image:HandBook_Page_ZQL	set:LZ_HandBook18 image:HandBook_Page_ZQR
-- 16	珍兽篇	set:LZ_HandBook1 image:HandBook_Page_ZSL	set:LZ_HandBook18 image:HandBook_Page_ZSR
-- 17	场景篇	set:LZ_HandBook9 image:HandBook_Page_HLL	set:LZ_HandBook20 image:HandBook_Page_HLR
-- 18	信	set:LZ_HandBook24 image:HandBook_Page_LetterL	set:LZ_HandBook25 image:HandBook_Page_LetterR

local g_tablePageImageRight2018 = 
{
	[1] = 	{strImageSet = "LZ_HandBook20", 	strImage = "HandBook_Page_R"}, 	-- Home页
	[2] = 	{strImageSet = "LZ_HandBook23",		strImage = "HandBook_Page_07R"}, 	
	[3] = 	{strImageSet = "LZ_HandBook23",		strImage = "HandBook_Page_0809R"}, 
	[4] = 	{strImageSet = "LZ_HandBook22",		strImage = "HandBook_Page_1011R"}, 
	[5] = 	{strImageSet = "LZ_HandBook22", 	strImage = "HandBook_Page_1213R"}, 
	[6] = 	{strImageSet = "LZ_HandBook22", 	strImage = "HandBook_Page_1415R"}, 
	[7] = 	{strImageSet = "LZ_HandBook21", 	strImage = "HandBook_Page_1617R"}, 	
	[8] = 	{strImageSet = "LZ_HandBook19", 	strImage = "HandBook_Page_TER"}, 	
	[9] = 	{strImageSet = "LZ_HandBook19", 	strImage = "HandBook_Page_SLR"}, 
	[10] = 	{strImageSet = "LZ_HandBook21", 	strImage = "HandBook_Page_GWR"}, 
	[11] = 	{strImageSet = "LZ_HandBook20", 	strImage = "HandBook_Page_MXR"}, 
	[12] = 	{strImageSet = "LZ_HandBook18", 	strImage = "HandBook_Page_XMR"}, 	
	[13] = 	{strImageSet = "LZ_HandBook21", 	strImage = "HandBook_Page_GTR"}, 	
	[14] = 	{strImageSet = "LZ_HandBook19", 	strImage = "HandBook_Page_SZR"}, 	
	[15] = 	{strImageSet = "LZ_HandBook18", 	strImage = "HandBook_Page_ZQR"}, 	
	[16] = 	{strImageSet = "LZ_HandBook18", 	strImage = "HandBook_Page_ZSR"}, 	
	[17] = 	{strImageSet = "LZ_HandBook20", 	strImage = "HandBook_Page_HLR"}, 	
	[18] = 	{strImageSet = "LZ_HandBook25", 	strImage = "HandBook_Page_LetterR"}, 	
}

local g_tablePageImageLeft2018 = 
{
	[1] = 	{strImageSet = "LZ_HandBook8", 		strImage = "HandBook_Page_L"}, 	-- Home页
	[2] = 	{strImageSet = "LZ_HandBook17",		strImage = "HandBook_Page_07L"}, 	
	[3] = 	{strImageSet = "LZ_HandBook16",		strImage = "HandBook_Page_0809L"}, 
	[4] = 	{strImageSet = "LZ_HandBook15",		strImage = "HandBook_Page_1011L"}, 
	[5] = 	{strImageSet = "LZ_HandBook14", 	strImage = "HandBook_Page_1213L"}, 
	[6] = 	{strImageSet = "LZ_HandBook13", 	strImage = "HandBook_Page_1415L"}, 
	[7] = 	{strImageSet = "LZ_HandBook12", 	strImage = "HandBook_Page_1617L"}, 	
	[8] = 	{strImageSet = "LZ_HandBook4", 		strImage = "HandBook_Page_TEL"}, 	
	[9] = 	{strImageSet = "LZ_HandBook6", 		strImage = "HandBook_Page_SLL"}, 
	[10] = 	{strImageSet = "LZ_HandBook10", 	strImage = "HandBook_Page_GWL"}, 
	[11] = 	{strImageSet = "LZ_HandBook7", 		strImage = "HandBook_Page_MXL"}, 
	[12] = 	{strImageSet = "LZ_HandBook3", 		strImage = "HandBook_Page_XML"}, 	
	[13] = 	{strImageSet = "LZ_HandBook11", 	strImage = "HandBook_Page_GTL"}, 	
	[14] = 	{strImageSet = "LZ_HandBook5", 		strImage = "HandBook_Page_SZL"}, 	
	[15] = 	{strImageSet = "LZ_HandBook2", 		strImage = "HandBook_Page_ZQL"}, 	
	[16] = 	{strImageSet = "LZ_HandBook1", 		strImage = "HandBook_Page_ZSL"}, 	
	[17] = 	{strImageSet = "LZ_HandBook9", 		strImage = "HandBook_Page_HLL"}, 	
	[18] = 	{strImageSet = "LZ_HandBook24", 	strImage = "HandBook_Page_LetterL"}, 	
}

-- 2019年重开
-- 1	首页	set:LZ_HandBook8 image:HandBook_Page_L	set:LZ_HandBook20 image:HandBook_Page_R
-- 2	2007年	set:LZ_HandBook17 image:HandBook_Page_07L	set:LZ_HandBook23 image:HandBook_Page_07R
-- 3	20082009	set:LZ_HandBook16 image:HandBook_Page_0809L	set:LZ_HandBook23 image:HandBook_Page_1011R
-- 4	20102011	set:LZ_HandBook15 image:HandBook_Page_1011L	set:LZ_HandBook22 image:HandBook_Page_1011R
-- 5	20122013	set:LZ_HandBook14 image:HandBook_Page_1213L	set:LZ_HandBook22 image:HandBook_Page_1213R
-- 6	20142015	set:LZ_HandBook13 image:HandBook_Page_1415L	set:LZ_HandBook22 image:HandBook_Page_1415R
-- 7	20162017	set:LZ_HandBook12 image:HandBook_Page_1617L	set:LZ_HandBook21 image:HandBook_Page_1617R
-- 8	天龙、峨嵋	set:LZ_HandBook4 image:HandBook_Page_TEL	set:LZ_HandBook19 image:HandBook_Page_TER
-- 9	少林、天上	set:LZ_HandBook6 image:HandBook_Page_SLL	set:LZ_HandBook19 image:HandBook_Page_SLR
-- 10	丐帮、武当	set:LZ_HandBook10 image:HandBook_Page_GWL	set:LZ_HandBook21 image:HandBook_Page_GWR
-- 11	明教、星宿	set:LZ_HandBook7 image:HandBook_Page_MXL	set:LZ_HandBook20 image:HandBook_Page_MXR
-- 12	逍遥、慕容	set:LZ_HandBook3 image:HandBook_Page_XML	set:LZ_HandBook18 image:HandBook_Page_XMR
-- 13	唐门、鬼谷	set:LZ_HandBook11 image:HandBook_Page_GTL	set:LZ_HandBook21 image:HandBook_Page_GTR
-- 14	时装篇	set:LZ_HandBook5 image:HandBook_Page_ZSL	set:LZ_HandBook19 image:HandBook_Page_ZSR
-- 15	坐骑篇	set:LZ_HandBook2 image:HandBook_Page_ZQL	set:LZ_HandBook18 image:HandBook_Page_ZQR
-- 16	珍兽篇	set:LZ_HandBook1 image:HandBook_Page_ZSL	set:LZ_HandBook18 image:HandBook_Page_ZSR
-- 17	场景篇	set:LZ_HandBook9 image:HandBook_Page_HLL	set:LZ_HandBook20 image:HandBook_Page_HLR
-- 18	信	set:LZ_HandBook24 image:HandBook_Page_LetterL	set:LZ_HandBook25 image:HandBook_Page_LetterR

local g_tablePageImageRight2019 =  -- todochongkai
{
	[1] = 	{strImageSet = "LZ_HandBook20", 	strImage = "HandBook_Page_R"}, 	-- Home页
	[2] = 	{strImageSet = "LZ_HandBook23",		strImage = "HandBook_Page_07R"}, 	
	[3] = 	{strImageSet = "LZ_HandBook23",		strImage = "HandBook_Page_0809R"}, 
	[4] = 	{strImageSet = "LZ_HandBook22",		strImage = "HandBook_Page_1011R"}, 
	[5] = 	{strImageSet = "LZ_HandBook22", 	strImage = "HandBook_Page_1213R"}, 
	[6] = 	{strImageSet = "LZ_HandBook22", 	strImage = "HandBook_Page_1415R"}, 
	[7] = 	{strImageSet = "LZ_HandBook21", 	strImage = "HandBook_Page_1617R"}, 	
	[8] = 	{strImageSet = "LZ_HandBook19", 	strImage = "HandBook_Page_TER"}, 	
	[9] = 	{strImageSet = "LZ_HandBook19", 	strImage = "HandBook_Page_SLR"}, 
	[10] = 	{strImageSet = "LZ_HandBook21", 	strImage = "HandBook_Page_GWR"}, 
	[11] = 	{strImageSet = "LZ_HandBook20", 	strImage = "HandBook_Page_MXR"}, 
	[12] = 	{strImageSet = "LZ_HandBook18", 	strImage = "HandBook_Page_XMR"}, 	
	[13] = 	{strImageSet = "LZ_HandBook21", 	strImage = "HandBook_Page_GTR"}, 	
	[14] = 	{strImageSet = "LZ_HandBook19", 	strImage = "HandBook_Page_SZR"}, 	
	[15] = 	{strImageSet = "LZ_HandBook18", 	strImage = "HandBook_Page_ZQR"}, 	
	[16] = 	{strImageSet = "LZ_HandBook18", 	strImage = "HandBook_Page_ZSR"}, 	
	[17] = 	{strImageSet = "LZ_HandBook20", 	strImage = "HandBook_Page_HLR"}, 	
	[18] = 	{strImageSet = "LZ_HandBook25", 	strImage = "HandBook_Page_LetterR"}, 	
}

local g_tablePageImageLeft2019 = 
{
	[1] = 	{strImageSet = "LZ_HandBook8", 		strImage = "HandBook_Page_L"}, 	-- Home页
	[2] = 	{strImageSet = "LZ_HandBook17",		strImage = "HandBook_Page_07L"}, 	
	[3] = 	{strImageSet = "LZ_HandBook16",		strImage = "HandBook_Page_0809L"}, 
	[4] = 	{strImageSet = "LZ_HandBook15",		strImage = "HandBook_Page_1011L"}, 
	[5] = 	{strImageSet = "LZ_HandBook14", 	strImage = "HandBook_Page_1213L"}, 
	[6] = 	{strImageSet = "LZ_HandBook13", 	strImage = "HandBook_Page_1415L"}, 
	[7] = 	{strImageSet = "LZ_HandBook12", 	strImage = "HandBook_Page_1617L"}, 	
	[8] = 	{strImageSet = "LZ_HandBook4", 		strImage = "HandBook_Page_TEL"}, 	
	[9] = 	{strImageSet = "LZ_HandBook6", 		strImage = "HandBook_Page_SLL"}, 
	[10] = 	{strImageSet = "LZ_HandBook10", 	strImage = "HandBook_Page_GWL"}, 
	[11] = 	{strImageSet = "LZ_HandBook7", 		strImage = "HandBook_Page_MXL"}, 
	[12] = 	{strImageSet = "LZ_HandBook3", 		strImage = "HandBook_Page_XML"}, 	
	[13] = 	{strImageSet = "LZ_HandBook11", 	strImage = "HandBook_Page_GTL"}, 	
	[14] = 	{strImageSet = "LZ_HandBook5", 		strImage = "HandBook_Page_SZL"}, 	
	[15] = 	{strImageSet = "LZ_HandBook2", 		strImage = "HandBook_Page_ZQL"}, 	
	[16] = 	{strImageSet = "LZ_HandBook1", 		strImage = "HandBook_Page_ZSL"}, 	
	[17] = 	{strImageSet = "LZ_HandBook9", 		strImage = "HandBook_Page_HLL"}, 	
	[18] = 	{strImageSet = "LZ_HandBook24", 	strImage = "HandBook_Page_LetterL"}, 	
}

local g_tablePageImageLeft 		= g_tablePageImageLeft2019
local g_tablePageImageRight 	= g_tablePageImageRight2019

--===============================================
-- PreLoad()
--===============================================
function HD_LongZhengHandBook_PreLoad()
	--PushDebugMessage("HD_LongZhengHandBook_PreLoad")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--===============================================
-- OnLoad()
--===============================================
function HD_LongZhengHandBook_OnLoad()
	--PushDebugMessage("HD_LongZhengHandBook_OnLoad")
	g_HD_LongZhengHandBook_Frame_UnifiedPosition = HD_LongZhengHandBook_Frame:GetProperty("UnifiedPosition")
end

-- !!!reloadscript =HD_LongZhengHandBook
--===============================================
-- OnEvent()
--===============================================
function HD_LongZhengHandBook_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == g_nUICommand) then
		--PushDebugMessage(arg0)
		local nYear = Get_XParam_INT(0)
		if 2018 == nYear then
			g_tablePageImageLeft 	= g_tablePageImageLeft2018
			g_tablePageImageRight 	= g_tablePageImageRight2018
		elseif 2019 == nYear then
			g_tablePageImageLeft 	= g_tablePageImageLeft2019
			g_tablePageImageRight 	= g_tablePageImageRight2019
		end
		HD_LongZhengHandBook_Init()
		this:Show()
	elseif (event == "ADJEST_UI_POS") then
		HD_LongZhengHandBook_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then	
		HD_LongZhengHandBook_ResetPos()
	end
end
      
--===============================================
-- Init()
--===============================================
function HD_LongZhengHandBook_Init()
	HD_LongZhengHandBook_Home_Click()
end

--===============================================
-- click
--===============================================
function HD_LongZhengHandBook_Home_Click()
	g_nSelectedPage = 1
	HD_LongZhengHandBook_ChangePage()
end

function HD_LongZhengHandBook_UpPage_Click()
	g_nSelectedPage = g_nSelectedPage - 1
	HD_LongZhengHandBook_ChangePage()
end

function HD_LongZhengHandBook_NextPage_Click()
	g_nSelectedPage = g_nSelectedPage + 1
	HD_LongZhengHandBook_ChangePage()
end

--===============================================
-- 翻到第x页
--===============================================
function HD_LongZhengHandBook_ChangePage()
	if nil == g_nSelectedPage or g_nSelectedPage < 1 then
		g_nSelectedPage = 1
	end
	if g_nSelectedPage > table.getn(g_tablePageImageLeft) then
		g_nSelectedPage = table.getn(g_tablePageImageLeft)
	end
	
	HD_LongZhengHandBook_ImageFrame : SetImage(g_tablePageImageLeft[g_nSelectedPage].strImageSet, g_tablePageImageLeft[g_nSelectedPage].strImage)
	
	HD_LongZhengHandBook_ImageFrame_R : SetImage(g_tablePageImageRight[g_nSelectedPage].strImageSet, g_tablePageImageRight[g_nSelectedPage].strImage)
	
	-- 设置页数
	--HD_LongZhengHandBook_CurrentlyPage : SetText(tostring(g_nSelectedPage).."/"..tostring(table.getn(g_tablePageImageLeft)))
	HD_LongZhengHandBook_CurrentlyPage : SetText(ScriptGlobal_Format("#{LZWZ_180313_179}", g_nSelectedPage, table.getn(g_tablePageImageLeft)))
	
	-- 按钮处理逻辑
	HD_LongZhengHandBook_Home 			: Show()
	HD_LongZhengHandBook_UpPage 		: Show()
	HD_LongZhengHandBook_NextPage 		: Show()
	
	-- 首页隐藏Home和上翻页
	if 1 == g_nSelectedPage then	
		HD_LongZhengHandBook_Home 		: Hide()
		HD_LongZhengHandBook_UpPage 	: Hide()
	end
	
	-- 末页隐藏后翻页
	if table.getn(g_tablePageImageLeft) == g_nSelectedPage then
		HD_LongZhengHandBook_NextPage 	: Hide()
	end
	
end

--===============================================
-- Close()
--===============================================
function HD_LongZhengHandBook_CloseClicked()
	HD_LongZhengHandBook_Close()
end

--===============================================
-- Close()
--===============================================
function HD_LongZhengHandBook_Close()
	g_nSelectedPage = 1
	this:Hide()
end

function HD_LongZhengHandBook_ResetPos()
	HD_LongZhengHandBook_Frame:SetProperty("UnifiedPosition",g_HD_LongZhengHandBook_Frame_UnifiedPosition)
end

