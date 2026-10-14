--Fetter.lua
--星阵-羁绊总览界面
local g_Frame_UnifiedPosition
local g_tab_GroupInfo = {}
local g_ListInfo_UIControl = {}
local g_ListInfo_PageIndex = 0
local g_ListInfo_SeleIndex = 0
local g_ListInfo_OnePageNum = 4
local g_ListInfo_MaxPageNum = 0

local g_tab_AllAttrInfo = {}
local g_GroupImage = {
	{imgBk="set:Rune_Star09 image:HerosBK4", imgName="set:Rune_Star07 image:JLZY"},		--金兰之义
	{imgBk="set:Rune_Star09 image:HerosBK3", imgName="set:Rune_Star07 image:BanYuanJun"},--半缘君
	{imgBk="set:Rune_Star08 image:HerosBK1", imgName="set:Rune_Star07 image:XYZK"},		--西域之客
	{imgBk="set:Rune_Star09 image:HerosBK2", imgName="set:Rune_Star07 image:QCHC"},		--取次花丛
	{imgBk="set:Rune_Star09 image:HerosBK3", imgName="set:Rune_Star07 image:AiBieLi"},	--爱别离
	{imgBk="set:Rune_Star09 image:HerosBK4", imgName="set:Rune_Star07 image:QBS"},		--前半生
	{imgBk="set:Rune_Star09 image:HerosBK2", imgName="set:Rune_Star07 image:SSDC"},		--世事洞察
	{imgBk="set:Rune_Star09 image:HerosBK3", imgName="set:Rune_Star07 image:YSY"},		--一生缘
	{imgBk="set:Rune_Star09 image:HerosBK4", imgName="set:Rune_Star07 image:YNZJ"},		--一念之间
	{imgBk="set:Rune_Star09 image:HerosBK3", imgName="set:Rune_Star07 image:ChiKuangRen"},--痴狂人
	{imgBk="set:Rune_Star09 image:HerosBK2", imgName="set:Rune_Star07 image:DLDS"},--大理段氏
	{imgBk="set:Rune_Star08 image:HerosBK1", imgName="set:Rune_Star07 image:XZLZS"},		--杏子林中事
	{imgBk="set:Rune_Star08 image:HerosBK1", imgName="set:Rune_Star07 image:WXDH"},		--万仙大会
}
--预加载函数，可以而且只能在这里注册脚本关心的事件
function Fetter_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("YINGXIONG_REDPOINT")
	this:RegisterEvent("XINGZHEN_UPDATE",false)
	this:RegisterEvent("CLOSE_XINGZHENUI_GROUP",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Fetter_OnLoad()
	g_Frame_UnifiedPosition = Fetter_Frame:GetProperty("UnifiedPosition")

	g_ListInfo_UIControl = {
		{uiBk = Fetter_Actor_1, uiImage = Fetter_Actor_1Info, uiRedPoint = Fetter_Actor_1_HeroBK_RedDot,
			tabHeadImg = {
				Fetter_Actor_1_HeroBK_Head1,
				Fetter_Actor_1_HeroBK_Head2,
				Fetter_Actor_1_HeroBK_Head3,
				Fetter_Actor_1_HeroBK_Head4,
				Fetter_Actor_1_HeroBK_Head5,
				Fetter_Actor_1_HeroBK_Head6,
			}
		},
		{uiBk = Fetter_Actor_2, uiImage = Fetter_Actor_2Info, uiRedPoint = Fetter_Actor_2_HeroBK_RedDot,
			tabHeadImg = {
				Fetter_Actor_2_HeroBK_Head1,
				Fetter_Actor_2_HeroBK_Head2,
				Fetter_Actor_2_HeroBK_Head3,
				Fetter_Actor_2_HeroBK_Head4,
				Fetter_Actor_2_HeroBK_Head5,
				Fetter_Actor_2_HeroBK_Head6,
			}
		},
		{uiBk = Fetter_Actor_3, uiImage = Fetter_Actor_3Info, uiRedPoint = Fetter_Actor_3_HeroBK_RedDot,
			tabHeadImg = {
				Fetter_Actor_3_HeroBK_Head1,
				Fetter_Actor_3_HeroBK_Head2,
				Fetter_Actor_3_HeroBK_Head3,
				Fetter_Actor_3_HeroBK_Head4,
				Fetter_Actor_3_HeroBK_Head5,
				Fetter_Actor_3_HeroBK_Head6,
			}
		},
		{uiBk = Fetter_Actor_4, uiImage = Fetter_Actor_4Info, uiRedPoint = Fetter_Actor_4_HeroBK_RedDot,
			tabHeadImg = {
				Fetter_Actor_4_HeroBK_Head1,
				Fetter_Actor_4_HeroBK_Head2,
				Fetter_Actor_4_HeroBK_Head3,
				Fetter_Actor_4_HeroBK_Head4,
				Fetter_Actor_4_HeroBK_Head5,
				Fetter_Actor_4_HeroBK_Head6,
			}
		},
	}
	g_tab_AllAttrInfo = {
		{uiName = Fetter_TotalFetter_Text1, uiNum = Fetter_TotalFetter_Text1up},
		{uiName = Fetter_TotalFetter_Text2, uiNum = Fetter_TotalFetter_Text2up},
		{uiName = Fetter_TotalFetter_Text3, uiNum = Fetter_TotalFetter_Text3up},
		{uiName = Fetter_TotalFetter_Text4, uiNum = Fetter_TotalFetter_Text4up},
		{uiName = Fetter_TotalFetter_Text5, uiNum = Fetter_TotalFetter_Text5up},
		{uiName = Fetter_TotalFetter_Text6, uiNum = Fetter_TotalFetter_Text6up},
		{uiName = Fetter_TotalFetter_Text7, uiNum = Fetter_TotalFetter_Text7up},
		{uiName = Fetter_TotalFetter_Text8, uiNum = Fetter_TotalFetter_Text8up},
		{uiName = Fetter_TotalFetter_Text9, uiNum = Fetter_TotalFetter_Text9up},
		{uiName = Fetter_TotalFetter_Text10, uiNum = Fetter_TotalFetter_Text10up},
		{uiName = Fetter_TotalFetter_Text11, uiNum = Fetter_TotalFetter_Text11up},
	}
end

--响应事件的函数，当注册的事件发生时会调用的函数
function Fetter_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		Fetter_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 14240001 ) then
		if Get_XParam_INT( 0 ) == 0 then 
			this:Hide()
			return
		end
		local nStayPos = Get_XParam_INT( 1 )
		if nStayPos == 0 then 
			g_ListInfo_PageIndex = 0
		end
		Fetter_FullUp_JibanGroup()
		Fetter_List_SetPageIndex(g_ListInfo_PageIndex)

		Fetter_Frame:SetProperty("UnifiedPosition", Variable:GetVariable("RuneStarPos") or g_Frame_UnifiedPosition)
		this:Show()
		Fetter_UpdateXingZhenRedPoint()
		Fetter_ResetTagButton()
		Fetter_UpdateTotalAttr()
	elseif ( event == "YINGXIONG_REDPOINT" ) then
		Fetter_UpdateRedPoint(arg0,arg1,arg2)
	elseif event == "XINGZHEN_UPDATE" then
		Fetter_UpdateXingZhenRedPoint()
	elseif event == "CLOSE_XINGZHENUI_GROUP" then 
		this:Hide()
	end
end

--以下是用户自定义的函数
function Fetter_UpdateXingZhenRedPoint()
	Fetter_Left_Buttontab01_Tips:Hide()
	Fetter_Left_Buttontab02_Tips:Hide()
	Fetter_Left_Buttontab03_Tips:Hide()
	
	if DataPool:LuaFnHaveXingJuanToSlot() == 1 then
		--有星卷可以上阵
		Fetter_Left_Buttontab01_Tips:Show()
	else
		local bHaveSkillCardToSlot = 0
		for i = 1, 4 do
			if DataPool:LuaFnHaveSkillCardToSlot(i) == 1 then
				bHaveSkillCardToSlot = 1
				break
			end
		end
		if bHaveSkillCardToSlot == 1 then
			--有技能可以上阵	
			Fetter_Left_Buttontab01_Tips:Show()
		elseif DataPool:LuaFnHaveNewXingJuan() == 1 then
			--有新的星卷
			Fetter_Left_Buttontab01_Tips:Show()
		elseif DataPool:LuaFnHaveNewSkillCard() == 1 then
			--有新的技能
			Fetter_Left_Buttontab01_Tips:Show()
		end
	end
	
	if DataPool:LuaFnHaveXingJuanToUpgrade() == 1 then
		--有星卷可以升阶
		Fetter_Left_Buttontab02_Tips:Show()
	end
	
	if DataPool:LuaFnHaveXingJuanToUnLock() == 1 then	
		--有星卷可以激活
		Fetter_Left_Buttontab02_Tips:Show()
	end
	
	--有技能可以升级
	if DataPool:LuaFnHaveSkillCardToLevelUp() == 1 then
		Fetter_Left_Buttontab03_Tips:Show()	
	end
end
function Fetter_UpdateRedPoint(gift_flag,level_flag,attr_flag)
	gift_flag=tonumber(gift_flag);level_flag=tonumber(level_flag);attr_flag=tonumber(attr_flag)
	if gift_flag==1 or level_flag==1 or attr_flag==1 then 
		Fetter_Left_Buttontab04_Tips:Show()
	else
		Fetter_Left_Buttontab04_Tips:Hide()
	end
	if gift_flag==1 or level_flag==1 then 
		Fetter_Tab_Hero_RedDot:Show()
	else
		Fetter_Tab_Hero_RedDot:Hide()
	end
	if attr_flag==1 then 
		Fetter_Tab_Fetter_RedDot:Show()
	else
		Fetter_Tab_Fetter_RedDot:Hide()
	end

end
function Fetter_UpdateTotalAttr()
	local tabInfo = {}
	tabInfo[1],tabInfo[2],tabInfo[3],tabInfo[4],tabInfo[5],tabInfo[6],tabInfo[7],tabInfo[8],tabInfo[9],tabInfo[10],tabInfo[11],tabInfo[12],tabInfo[13],tabInfo[14],tabInfo[15],tabInfo[16],tabInfo[17],tabInfo[18],tabInfo[19],tabInfo[20],tabInfo[21],tabInfo[22] = DataPool:LuaFnGetXingZhen_JiBanTotalAttr()
	local nIndex = 1
	for i=1,21,2 do 
		local szAttrName = tabInfo[i]
		local nAttrNum = tabInfo[i+1] or 0
		if nAttrNum > 0 then 
			g_tab_AllAttrInfo[nIndex].uiName:Show()
			g_tab_AllAttrInfo[nIndex].uiNum:Show()
			g_tab_AllAttrInfo[nIndex].uiName:SetText( ScriptGlobal_Format("#{XZYX_200309_379}", "#{"..szAttrName.."}") )
			g_tab_AllAttrInfo[nIndex].uiNum:SetText( ScriptGlobal_Format("#{XZYX_200309_380}", nAttrNum) )
			g_tab_AllAttrInfo[nIndex].uiName:SetToolTip("")
			g_tab_AllAttrInfo[nIndex].uiNum:SetToolTip("")
			if szAttrName == "XZJC_200309_235" then 
				g_tab_AllAttrInfo[nIndex].uiName:SetToolTip("#{XZYX_200309_220}")
				g_tab_AllAttrInfo[nIndex].uiNum:SetToolTip("#{XZYX_200309_220}")
			end
			if szAttrName == "XZJC_200309_236" then 
				g_tab_AllAttrInfo[nIndex].uiName:SetToolTip("#{XZYX_200309_222}")
				g_tab_AllAttrInfo[nIndex].uiNum:SetToolTip("#{XZYX_200309_222}")
			end
			nIndex = nIndex + 1
		end
	end
	for i=nIndex,table.getn(g_tab_AllAttrInfo) do 
		g_tab_AllAttrInfo[i].uiName:Hide()
		g_tab_AllAttrInfo[i].uiNum:Hide()
	end
end
function Fetter_OnHidden()
	this:Hide()
end
function Fetter_ResetTagButton()
	Fetter_Left_Buttontab01:SetCheck(0)
	Fetter_Left_Buttontab02:SetCheck(0)
	Fetter_Left_Buttontab03:SetCheck(0)
	Fetter_Left_Buttontab04:SetCheck(1)
	Fetter_Tab_Hero:SetCheck(0)
	Fetter_Tab_Fetter:SetCheck(1)
end
function  Fetter_XingZhen_Clicked()
	Variable:SetVariable("RuneStarPos",  Fetter_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhen(true, 0, 0)
end
function  Fetter_YangCheng_Clicked()
	Variable:SetVariable("RuneStarPos",  Fetter_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhenUpgrade()
end
function  Fetter_SuiPian_Clicked()
	Variable:SetVariable("RuneStarPos",  Fetter_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhenSkill()
end
function Fetter_YingXiong_Clicked()
end
function Fetter_OpenHeroes_Clicked()
	Variable:SetVariable("RuneStarPos",  Fetter_Frame:GetProperty("UnifiedPosition"), 1)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenXZ_Heroes" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
function Fetter_OpenFetter_Clicked()
end
function Fetter_GetYingXiongLevel(nYingXiongId)
	local nHaogandu = DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
	return nHaogandu
end
function Fetter_GroupAllLevel(nAwardIndex)
	local nAllLevel = 0
	local Ids = {}
	Ids[1],Ids[2],Ids[3],Ids[4],Ids[5],Ids[6],Ids[7],Ids[8],Ids[9],Ids[10] = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nAwardIndex, "YingXiongIds")
	for i, v in pairs(Ids) do 
		nAllLevel = nAllLevel + Fetter_GetYingXiongLevel(v)
	end
	return nAllLevel
end
function Fetter_FullUp_JibanGroup()
	if not this:IsVisible() then 
		g_tab_GroupInfo = {}
		local nAllNum = DataPool:LuaFnGetXingZhen_JiBanAwardNum()
		local tabGroupExist = {}
		local nHaveRedPoint = 0
		local nTableIndex = 0
		local nAllLevel = 0
		for i=1,nAllNum do 
			local nGroupId = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(i, "GroupId")
			if not tabGroupExist[nGroupId] then
				nHaveRedPoint = 0 
				nAllLevel = Fetter_GroupAllLevel(i)
				tabGroupExist[nGroupId] = 1
				local tabInfo = {}
				tabInfo.nIndex = i
				tabInfo.nGroupId = nGroupId
				tabInfo.nAllLevel = nAllLevel
				tabInfo.nHaveRedPoint = 0
				tabInfo.Ids = {}
				tabInfo.Ids[1],tabInfo.Ids[2],tabInfo.Ids[3],tabInfo.Ids[4],tabInfo.Ids[5],tabInfo.Ids[6],tabInfo.Ids[7],tabInfo.Ids[8],tabInfo.Ids[9],tabInfo.Ids[10] = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(i, "YingXiongIds")
				table.insert(g_tab_GroupInfo, tabInfo)
				nTableIndex = nTableIndex + 1
			end
			nAddLevel = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(i, "AddLevel")
			if nHaveRedPoint == 0 and nAllLevel>=nAddLevel and not DataPool:LuaFnGetXingZhen_JiBanAwardFlag(i) then 
				nHaveRedPoint = 1
				g_tab_GroupInfo[nTableIndex].nHaveRedPoint = 1
			end

		end
		table.sort(g_tab_GroupInfo, function(a, b)
				if a.nAllLevel ~= b.nAllLevel then 
					return a.nAllLevel>b.nAllLevel
				end
				return a.nGroupId<b.nGroupId
			end)

		g_ListInfo_MaxPageNum = math.floor(table.getn(g_tab_GroupInfo)/g_ListInfo_OnePageNum)
	end
	-- 按nGroupId顺序显示
end

function Fetter_Choose_Clicked(nIndex)
	local nSelectIndex = g_ListInfo_OnePageNum*g_ListInfo_PageIndex + nIndex
	local tabInfo = g_tab_GroupInfo[nSelectIndex]
	if not tabInfo then 
  		PushDebugMessage("Error:Fetter_Choose_Clicked:"..g_ListInfo_PageIndex..":"..nSelectIndex)
		return
	end
	local nGroupId = tabInfo.nGroupId
	Variable:SetVariable("RuneStarPos",  Fetter_Frame:GetProperty("UnifiedPosition"), 1)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenXZ_FeDetail" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, nGroupId );
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()
end
function Fetter_PrePage_Clicked()
	if g_ListInfo_PageIndex <=0 then return end
	g_ListInfo_PageIndex = g_ListInfo_PageIndex - 1
	Fetter_List_SetPageIndex(g_ListInfo_PageIndex)
end
function Fetter_NextPage_Clicked()
	if g_ListInfo_PageIndex >=g_ListInfo_MaxPageNum then return end
	g_ListInfo_PageIndex = g_ListInfo_PageIndex + 1
	Fetter_List_SetPageIndex(g_ListInfo_PageIndex)
end

function Fetter_List_SetSeleIndex(nIndex)
	g_ListInfo_SeleIndex = nIndex
	Fetter_List_SetPageIndex(math.floor((g_ListInfo_SeleIndex-1)/g_ListInfo_OnePageNum))
end
function Fetter_List_SetPageIndex(nIndex)
	g_ListInfo_PageIndex = nIndex
	Fetter_LeftArrow_Btn:Enable();
	Fetter_RightArrow_Btn:Enable();
	Fetter_LeftArrow_Btn_RedDot:Hide()
	Fetter_RightArrow_Btn_RedDot:Hide()
	if g_ListInfo_PageIndex <=0 then 
		g_ListInfo_PageIndex = 0
		Fetter_LeftArrow_Btn:Disable()
	end
	if g_ListInfo_PageIndex >=g_ListInfo_MaxPageNum then 
		g_ListInfo_PageIndex = g_ListInfo_MaxPageNum
		Fetter_RightArrow_Btn:Disable()
	end
	local nStartIndex = g_ListInfo_OnePageNum*g_ListInfo_PageIndex;
	--左边箭头红点
	for i=1,nStartIndex do 
		local tabInfo = g_tab_GroupInfo[i]
		if tabInfo.nHaveRedPoint==1 then 
			Fetter_LeftArrow_Btn_RedDot:Show()
			break
		end
	end
	--右边箭头红点
	for i=nStartIndex+g_ListInfo_OnePageNum+1,table.getn(g_tab_GroupInfo) do 
		local tabInfo = g_tab_GroupInfo[i]
		if tabInfo.nHaveRedPoint==1 then 
			Fetter_RightArrow_Btn_RedDot:Show()
			break
		end
	end
	for subIndex = 1, g_ListInfo_OnePageNum do 
		local realIndex = nStartIndex + subIndex;
		local tabInfo = g_tab_GroupInfo[realIndex]
		if not tabInfo then 
			g_ListInfo_UIControl[subIndex].uiBk:Hide()
		else
			g_ListInfo_UIControl[subIndex].uiBk:Show()
			
			if tabInfo.nHaveRedPoint == 1 then 
				g_ListInfo_UIControl[subIndex].uiRedPoint:Show()
			else
				g_ListInfo_UIControl[subIndex].uiRedPoint:Hide()
			end
			-- 所属英雄名字
			local nTabIndex = 1
			for i, v in pairs(tabInfo.Ids) do 
				local szImage = DataPool:LuaFnGetXingZhen_YingXiongInfo(v, "HeadImage2")
				g_ListInfo_UIControl[subIndex].tabHeadImg[nTabIndex]:Show()
				g_ListInfo_UIControl[subIndex].tabHeadImg[nTabIndex]:SetProperty("Image", szImage)
				nTabIndex = nTabIndex + 1
			end
			local nMaxTableNum = table.getn(g_ListInfo_UIControl[subIndex].tabHeadImg)
			for i=nTabIndex,nMaxTableNum do 
				g_ListInfo_UIControl[subIndex].tabHeadImg[i]:Hide()
			end
			-- 背景图
			local nGroupId = tabInfo.nGroupId
			if g_GroupImage[nGroupId] then 
				g_ListInfo_UIControl[subIndex].uiBk:SetProperty("Image", g_GroupImage[nGroupId].imgBk)
				g_ListInfo_UIControl[subIndex].uiImage:SetProperty("Image", g_GroupImage[nGroupId].imgName)
			end
		end
	end
end