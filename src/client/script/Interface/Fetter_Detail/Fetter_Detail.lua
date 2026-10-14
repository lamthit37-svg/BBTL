--Fetter_Detail.lua
--星阵-羁绊详细信息界面
local g_Frame_UnifiedPosition
local g_Award_Group_Id = 0

local g_ListInfo_UIControl = {}
local g_tab_NowAttrInfo = {}
local g_tab_NextAttrInfo = {}
local g_tabInterests = {}
local g_Select_YingXiongId = 0
local g_ListInfo_PageIndex = 0
local g_ListInfo_MaxPageNum = 0

local g_Fetter_GroupInfo = {}
local g_Fetter_PageIndex = 0
local g_Fetter_MaxPageNum = 0
local g_Select_AwardIndex = 0

local g_GroupImage = {
	{szName="#{XZYX_200309_357}", imgBk="set:Rune_Star09 image:HerosBK4", imgName="set:Rune_Star07 image:JLZY"},		--金兰之义
	{szName="#{XZYX_200309_358}", imgBk="set:Rune_Star09 image:HerosBK3", imgName="set:Rune_Star07 image:BanYuanJun"},	--半缘君
	{szName="#{XZYX_200309_359}", imgBk="set:Rune_Star08 image:HerosBK1", imgName="set:Rune_Star07 image:XYZK"},		--西域之客
	{szName="#{XZYX_200309_360}", imgBk="set:Rune_Star09 image:HerosBK2", imgName="set:Rune_Star07 image:QCHC"},		--取次花丛
	{szName="#{XZYX_200309_361}", imgBk="set:Rune_Star09 image:HerosBK3", imgName="set:Rune_Star07 image:AiBieLi"},		--爱别离
	{szName="#{XZYX_200309_362}", imgBk="set:Rune_Star09 image:HerosBK4", imgName="set:Rune_Star07 image:QBS"},			--前半生
	{szName="#{XZYX_200309_363}", imgBk="set:Rune_Star09 image:HerosBK2", imgName="set:Rune_Star07 image:SSDC"},		--世事洞察
	{szName="#{XZYX_200309_364}", imgBk="set:Rune_Star09 image:HerosBK3", imgName="set:Rune_Star07 image:YSY"},			--一生缘
	{szName="#{XZYX_200309_365}", imgBk="set:Rune_Star09 image:HerosBK4", imgName="set:Rune_Star07 image:YNZJ"},		--一念之间
	{szName="#{XZYX_200309_366}", imgBk="set:Rune_Star09 image:HerosBK3", imgName="set:Rune_Star07 image:ChiKuangRen"},	--痴狂人
	{szName="#{XZYX_200309_367}", imgBk="set:Rune_Star09 image:HerosBK2", imgName="set:Rune_Star07 image:DLDS"},		--大理段氏
	{szName="#{XZYX_200309_368}", imgBk="set:Rune_Star08 image:HerosBK1", imgName="set:Rune_Star07 image:XZLZS"},		--杏子林中事
	{szName="#{XZYX_200309_369}", imgBk="set:Rune_Star08 image:HerosBK1", imgName="set:Rune_Star07 image:WXDH"},		--万仙大会
}

local g_YingXiongLevel_Flag = {
	"set:Rune_Star01 image:JiaoBiao1",
	"set:Rune_Star01 image:JiaoBiao4",
	"set:Rune_Star01 image:JiaoBiao5",
	"set:Rune_Star01 image:JiaoBiao3",
	"set:Rune_Star01 image:JiaoBiao2",
}
--预加载函数，可以而且只能在这里注册脚本关心的事件
function Fetter_Detail_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("YINGXIONG_REDPOINT")
	this:RegisterEvent("YINGXIONG_CHANGE",false)
	this:RegisterEvent("XINGZHEN_UPDATE",false)
	this:RegisterEvent("CLOSE_XINGZHENUI_GROUP",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Fetter_Detail_OnLoad()
	g_Frame_UnifiedPosition = Fetter_Detail_Frame:GetProperty("UnifiedPosition")
	Fetter_Detail_Frame_Part2:Hide()
	g_ListInfo_UIControl = {
		{id=0,uiBk = Fetter_Detail_BonusItem_1_Frame,uiName = Fetter_Detail_BonusItem_1_Title,uiImage = Fetter_Detail_BonusItem_1_Icon, uiNum = Fetter_Detail_BonusItem_1_likability},
		{id=0,uiBk = Fetter_Detail_BonusItem_2_Frame,uiName = Fetter_Detail_BonusItem_2_Title,uiImage = Fetter_Detail_BonusItem_2_Icon, uiNum = Fetter_Detail_BonusItem_2_likability},
		{id=0,uiBk = Fetter_Detail_BonusItem_3_Frame,uiName = Fetter_Detail_BonusItem_3_Title,uiImage = Fetter_Detail_BonusItem_3_Icon, uiNum = Fetter_Detail_BonusItem_3_likability},
		{id=0,uiBk = Fetter_Detail_BonusItem_4_Frame,uiName = Fetter_Detail_BonusItem_4_Title,uiImage = Fetter_Detail_BonusItem_4_Icon, uiNum = Fetter_Detail_BonusItem_4_likability},
		{id=0,uiBk = Fetter_Detail_BonusItem_5_Frame,uiName = Fetter_Detail_BonusItem_5_Title,uiImage = Fetter_Detail_BonusItem_5_Icon, uiNum = Fetter_Detail_BonusItem_5_likability},
		{id=0,uiBk = Fetter_Detail_BonusItem_6_Frame,uiName = Fetter_Detail_BonusItem_6_Title,uiImage = Fetter_Detail_BonusItem_6_Icon, uiNum = Fetter_Detail_BonusItem_6_likability},
	}
	g_tab_NowAttrInfo = {
		{ uiAttrName=Fetter_Detail_UpFrame_DamageBuff_1_InsideDamage,uiAttrNum=Fetter_Detail_UpFrame_DamageBuff_1_InsideDamageUp},
		{ uiAttrName=Fetter_Detail_UpFrame_DamageBuff_2_InsideDamage,uiAttrNum=Fetter_Detail_UpFrame_DamageBuff_2_InsideDamageUp},
		{ uiAttrName=Fetter_Detail_UpFrame_DamageBuff_3_InsideDamage,uiAttrNum=Fetter_Detail_UpFrame_DamageBuff_3_InsideDamageUp},
	}
	g_tab_NextAttrInfo = {
		{ uiAttrName=Fetter_Detail_TotalFetter_Text3,uiAttrNum=Fetter_Detail_TotalFetter_Text3Up},
		{ uiAttrName=Fetter_Detail_TotalFetter_Text4,uiAttrNum=Fetter_Detail_TotalFetter_Text4Up},
		{ uiAttrName=Fetter_Detail_TotalFetter_Text5,uiAttrNum=Fetter_Detail_TotalFetter_Text5Up},
	}
	g_tabInterests = {
		{nId=0, uiAwardItem=Fetter_DetailInfo_HeroInfo_GiftIcon,uiAwardNum=Fetter_DetailInfo_GiftItem1_GiftInfo,uiGiveNum=Fetter_DetailInfo_GiftItem1_TotalGive1, uiGiveOver=Fetter_DetailInfo_GiftItem1_TotalGive1Over, uiItemNum=Fetter_DetailInfo_HeroInfo_GiftIcon_Num},
		{nId=0, uiAwardItem=Fetter_DetailInfo_HeroInfo_GiftIcon2,uiAwardNum=Fetter_DetailInfo_GiftItem1_GiftInfo2,uiGiveNum=Fetter_DetailInfo_GiftItem1_TotalGive2, uiGiveOver=Fetter_DetailInfo_GiftItem1_TotalGive2Over, uiItemNum=Fetter_DetailInfo_HeroInfo_GiftIcon2_Num},
	}
end

--响应事件的函数，当注册的事件发生时会调用的函数
function Fetter_Detail_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		Fetter_Detail_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 14250001 ) then
		if Get_XParam_INT( 0 ) == 0 then 
			this:Hide()
			return
		end
		g_Award_Group_Id = Get_XParam_INT( 1 )
		Fetter_Detail_FullUpInfo()

		Fetter_Detail_Frame:SetProperty("UnifiedPosition", Variable:GetVariable("RuneStarPos") or g_Frame_UnifiedPosition)
		this:Show()
		Fetter_Detail_UpdateXingZhenRedPoint()
		Fetter_Detail_ResetTagButton()
	elseif ( event == "YINGXIONG_CHANGE" ) then
		Fetter_Detail_UpdateSelectPosition()
		if tonumber(arg0) == g_Select_YingXiongId then
			Fetter_Detail_DetailInfo_Show(g_Select_YingXiongId)
		end
	elseif ( event == "YINGXIONG_REDPOINT" ) then
		Fetter_Detail_UpdateRedPoint(arg0,arg1,arg2)
	elseif event == "XINGZHEN_UPDATE" then
		Fetter_Detail_UpdateXingZhenRedPoint()
	elseif event == "CLOSE_XINGZHENUI_GROUP" then 
		this:Hide()
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then 
		Fetter_Detail_UpdateDetail_ItemNum()
	end
end

--以下是用户自定义的函数
function Fetter_Detail_UpdateXingZhenRedPoint()
	Fetter_Detail_Left_Buttontab01_Tips:Hide()
	Fetter_Detail_Left_Buttontab02_Tips:Hide()
	Fetter_Detail_Left_Buttontab03_Tips:Hide()
	
	if DataPool:LuaFnHaveXingJuanToSlot() == 1 then
		--有星卷可以上阵
		Fetter_Detail_Left_Buttontab01_Tips:Show()
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
			Fetter_Detail_Left_Buttontab01_Tips:Show()
		elseif DataPool:LuaFnHaveNewXingJuan() == 1 then
			--有新的星卷
			Fetter_Detail_Left_Buttontab01_Tips:Show()
		elseif DataPool:LuaFnHaveNewSkillCard() == 1 then
			--有新的技能
			Fetter_Detail_Left_Buttontab01_Tips:Show()
		end
	end	
	
	if DataPool:LuaFnHaveXingJuanToUpgrade() == 1 then
		--有星卷可以升阶
		Fetter_Detail_Left_Buttontab02_Tips:Show()
	end
	
	if DataPool:LuaFnHaveXingJuanToUnLock() == 1 then	
		--有星卷可以激活
		Fetter_Detail_Left_Buttontab02_Tips:Show()
	end
	
	--有技能可以升级
	if DataPool:LuaFnHaveSkillCardToLevelUp() == 1 then
		Fetter_Detail_Left_Buttontab03_Tips:Show()	
	end
end
function Fetter_Detail_UpdateRedPoint(gift_flag,level_flag,attr_flag)
	gift_flag=tonumber(gift_flag);level_flag=tonumber(level_flag);attr_flag=tonumber(attr_flag)
	if gift_flag==1 or level_flag==1 or attr_flag==1 then 
		Fetter_Detail_Left_Buttontab04_Tips:Show()
	else
		Fetter_Detail_Left_Buttontab04_Tips:Hide()
	end
	if gift_flag==1 or level_flag==1 then 
		Fetter_Detail_Tab_Hero_RedDot:Show()
	else
		Fetter_Detail_Tab_Hero_RedDot:Hide()
	end
end
function Fetter_Detail_OnHidden()
	this:Hide()
	Fetter_Detail_DetailInfo_Hide()
end
function Fetter_Detail_ResetTagButton()
	Fetter_Detail_Left_Buttontab01:SetCheck(0)
	Fetter_Detail_Left_Buttontab02:SetCheck(0)
	Fetter_Detail_Left_Buttontab03:SetCheck(0)
	Fetter_Detail_Left_Buttontab04:SetCheck(1)
	Fetter_Detail_Tab_Hero:SetCheck(0)
	Fetter_Detail_Tab_Fetter:SetCheck(1)
end
function  Fetter_Detail_XingZhen_Clicked()
	Variable:SetVariable("RuneStarPos",  Fetter_Detail_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhen(true, 0, 0)
end
function  Fetter_Detail_YangCheng_Clicked()
	Variable:SetVariable("RuneStarPos",  Fetter_Detail_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhenUpgrade()
end
function  Fetter_Detail_SuiPian_Clicked()
	Variable:SetVariable("RuneStarPos",  Fetter_Detail_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhenSkill()
end
function Fetter_Detail_YingXiong_Clicked()
end
function Fetter_Detail_OpenHeroes_Clicked()
	Variable:SetVariable("RuneStarPos",  Fetter_Detail_Frame:GetProperty("UnifiedPosition"), 1)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenXZ_Heroes" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
function Fetter_Detail_OpenFetter_Clicked()
end

function Fetter_Detail_GetYingXiongLevel()
	local nHaogandu = 0
	local nMaxLevel = 0
	local nMin, nMax = DataPool:LuaFnGetXingZhen_JiBanAwardRange(g_Award_Group_Id)
	local tabInfo = {}
	tabInfo[1],tabInfo[2],tabInfo[3],tabInfo[4],tabInfo[5],tabInfo[6],tabInfo[7],tabInfo[8],tabInfo[9],tabInfo[10] = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nMin, "YingXiongIds")
	for _, nYingXiongId in pairs(tabInfo) do 
		nHaogandu = nHaogandu + DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
		local tabIds = {}
		tabIds[1],tabIds[2],tabIds[3],tabIds[4],tabIds[5] = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Interests")
		for _, nInterestsId in pairs(tabIds) do
			nMaxLevel = nMaxLevel + DataPool:LuaFnGetXingZhen_InterestsInfo(nInterestsId, "MaxLevel")
		end
	end
	return nHaogandu, nMaxLevel*50
end
function Fetter_Detail_GroupAllLevel(nAwardIndex)
	local nAllLevel = 0
	local Ids = {}
	Ids[1],Ids[2],Ids[3],Ids[4],Ids[5],Ids[6],Ids[7],Ids[8],Ids[9],Ids[10] = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nAwardIndex, "YingXiongIds")
	for i, v in pairs(Ids) do 
		nAllLevel = nAllLevel + Fetter_GetYingXiongLevel(v)
	end
	return nAllLevel
end
function Fetter_Detail_UpdateSelectPosition()
	local tabAttrInfo = {}
	local tabAttrIndex = {}
	local nNexthaogandu = 0
	local nAwardhaogandu = 0
	local nYingXiongHaogandu, nMaxhaogandu = Fetter_Detail_GetYingXiongLevel()
	-- PushDebugMessage("Fetter_Detail_UpdateSelectPosition:"..nYingXiongHaogandu..":"..nMaxhaogandu)
	
	-- 0级初始属性
	local nMin, nMax = DataPool:LuaFnGetXingZhen_JiBanAwardRange(g_Award_Group_Id)
	local id1,_,id2,_,id3,_,id4 = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nMin, "AddAttr") 
	if id1 then tabAttrInfo[id1] = 0; table.insert(tabAttrIndex, id1) end
	if id2 then tabAttrInfo[id2] = 0; table.insert(tabAttrIndex, id2) end
	if id3 then tabAttrInfo[id3] = 0; table.insert(tabAttrIndex, id3) end
	if id4 then tabAttrInfo[id4] = 0; table.insert(tabAttrIndex, id4) end
	local nAwardMaxHaogandu = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nMax, "AddLevel") 
	-- 累计增加属性
	local nHaveRedPoint = 0
	local tabNextIds={ {id=0,num=0},{id=0,num=0},{id=0,num=0},{id=0,num=0}}
	for nAwardId =nMin,nMax do
		tabNextIds[1].id,tabNextIds[1].num,tabNextIds[2].id,tabNextIds[2].num,tabNextIds[3].id,tabNextIds[3].num,tabNextIds[4].id,tabNextIds[4].num = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nAwardId, "AddAttr") 
		local nAddLevel = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nAwardId, "AddLevel") 
		if not DataPool:LuaFnGetXingZhen_JiBanAwardFlag(nAwardId) then 
			nNexthaogandu = nAddLevel
			if nYingXiongHaogandu >= nAddLevel then 
				nHaveRedPoint = 1
			end
			break
		end
		nAwardhaogandu = nAddLevel

		local tabIds={ {id=0,num=0},{id=0,num=0},{id=0,num=0},{id=0,num=0}}
		tabIds[1].id,tabIds[1].num,tabIds[2].id,tabIds[2].num,tabIds[3].id,tabIds[3].num,tabIds[4].id,tabIds[4].num = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nAwardId, "AddAttr") 
		for _, attr in pairs(tabIds) do 
			if attr.id then 
				if not tabAttrInfo[attr.id] then tabAttrInfo[attr.id] = 0 end
				tabAttrInfo[attr.id] = tabAttrInfo[attr.id] + attr.num
			end
		end
	end
	if nHaveRedPoint == 1 then 
		Fetter_Detail_Tab_Fetter_RedDot:Show()
		Fetter_Detail_GetBonus_Btn_RedDot:Show()
	else
		Fetter_Detail_Tab_Fetter_RedDot:Hide()
		Fetter_Detail_GetBonus_Btn_RedDot:Hide()
	end
	if nAwardhaogandu >= nAwardMaxHaogandu then 
		-- Fetter_Detail_TotalFetter_Text2:Hide()
		tabNextIds={ {id=0,num=-1},{id=0,num=-1},{id=0,num=-1},{id=nil,num=nil}}
		-- Fetter_Detail_TotalFetter_Progress:SetProgress(1, 1)
		-- Fetter_Detail_TotalFetter_Progress_Text:SetText("#{XZYX_200309_325}")
		Fetter_Detail_TotalFetter_Text6:SetText("#{XZYX_200309_325}")
	else
		-- Fetter_Detail_TotalFetter_Text2:Show()
		Fetter_Detail_TotalFetter_Text6:SetText( ScriptGlobal_Format("#{XZYX_200309_377}", nNexthaogandu) )
		-- Fetter_Detail_TotalFetter_Progress:SetProgress(nYingXiongHaogandu, nNexthaogandu)
		-- Fetter_Detail_TotalFetter_Progress_Text:SetText(ScriptGlobal_Format("#{XZYX_200309_324}", nYingXiongHaogandu, nNexthaogandu))
	end
	-- 当前总计增加属性
	local nIndex = 1
	for _, i in pairs(tabAttrIndex) do 
		local nAttrNum = tabAttrInfo[i]
		g_tab_NowAttrInfo[nIndex].uiAttrName:Show()
		g_tab_NowAttrInfo[nIndex].uiAttrName:SetText( ScriptGlobal_Format("#{XZYX_200309_379}", "#{"..i.."}") )
		g_tab_NowAttrInfo[nIndex].uiAttrNum:Show()
		g_tab_NowAttrInfo[nIndex].uiAttrNum:SetText( ScriptGlobal_Format("#{XZYX_200309_380}", nAttrNum) )
		g_tab_NowAttrInfo[nIndex].uiAttrName:SetToolTip("")
		g_tab_NowAttrInfo[nIndex].uiAttrNum:SetToolTip("")
		if i == "XZJC_200309_235" then 
			g_tab_NowAttrInfo[nIndex].uiAttrName:SetToolTip("#{XZYX_200309_220}")
			g_tab_NowAttrInfo[nIndex].uiAttrNum:SetToolTip("#{XZYX_200309_220}")
		end
		if i == "XZJC_200309_236" then 
			g_tab_NowAttrInfo[nIndex].uiAttrName:SetToolTip("#{XZYX_200309_222}")
			g_tab_NowAttrInfo[nIndex].uiAttrNum:SetToolTip("#{XZYX_200309_222}")
		end
		nIndex = nIndex + 1
	end
	for i=nIndex,table.getn(g_tab_NowAttrInfo) do 
		g_tab_NowAttrInfo[i].uiAttrName:Hide()
		g_tab_NowAttrInfo[i].uiAttrNum:Hide()
	end
	-- 下一级属性
	nIndex = 1
	for _, v in pairs(tabNextIds) do 
		if v.num and v.num>=0 then 
			g_tab_NextAttrInfo[nIndex].uiAttrName:SetToolTip("")
			g_tab_NextAttrInfo[nIndex].uiAttrNum:SetToolTip("")
			g_tab_NextAttrInfo[nIndex].uiAttrName:Show()
			g_tab_NextAttrInfo[nIndex].uiAttrNum:Show()
			Fetter_Detail_TotalFetter_TextFull:Hide()
			g_tab_NextAttrInfo[nIndex].uiAttrName:SetText( ScriptGlobal_Format("#{XZYX_200309_379}", "#{"..v.id.."}") )
			if v.num == 0 then 
				g_tab_NextAttrInfo[nIndex].uiAttrNum:SetText( ScriptGlobal_Format("#{XZYX_200309_380}", v.num+tabAttrInfo[v.id]) )
			else
				g_tab_NextAttrInfo[nIndex].uiAttrNum:SetText( "#M+"..v.num+tabAttrInfo[v.id] )
			end
			if v.id == "XZJC_200309_235" then 
				g_tab_NextAttrInfo[nIndex].uiAttrName:SetToolTip("#{XZYX_200309_220}")
				g_tab_NextAttrInfo[nIndex].uiAttrNum:SetToolTip("#{XZYX_200309_220}")
			end
			if v.id == "XZJC_200309_236" then 
				g_tab_NextAttrInfo[nIndex].uiAttrName:SetToolTip("#{XZYX_200309_222}")
				g_tab_NextAttrInfo[nIndex].uiAttrNum:SetToolTip("#{XZYX_200309_222}")
			end
			nIndex = nIndex + 1
		elseif v.num and v.num == -1 then
			g_tab_NextAttrInfo[nIndex].uiAttrName:Hide()
			g_tab_NextAttrInfo[nIndex].uiAttrNum:Hide()
			Fetter_Detail_TotalFetter_TextFull:Show()
			nIndex = nIndex + 1
		end
	end
	for i=nIndex,table.getn(g_tab_NextAttrInfo) do 
		g_tab_NextAttrInfo[i].uiAttrName:Hide()
		g_tab_NextAttrInfo[i].uiAttrNum:Hide()
	end
	-- 英雄好感度
	local tabIds = {}
	tabIds[1],tabIds[2],tabIds[3],tabIds[4],tabIds[5],tabIds[6],tabIds[7],tabIds[8],tabIds[9],tabIds[10] = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nMin, "YingXiongIds")
	nIndex = 1
	local nTotalHaogan = 0
	for i, nYingXiongId in pairs(tabIds) do 
		local nHaogandu =  DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
		nTotalHaogan = nTotalHaogan + nHaogandu
		g_ListInfo_UIControl[nIndex].id = nYingXiongId
		g_ListInfo_UIControl[nIndex].uiNum:SetText( ScriptGlobal_Format("#{XZYX_200309_332}", nHaogandu))
		nIndex = nIndex + 1
	end
	Fetter_Detail_TotalFetter_Text1:SetText( ScriptGlobal_Format("#{XZYX_200309_323}",nTotalHaogan) )
	g_ListInfo_MaxPageNum = table.getn(tabIds)

end
function Fetter_Detail_PrePage_Clicked()
	if g_Fetter_PageIndex <= 1 then return end
	g_Fetter_PageIndex = g_Fetter_PageIndex -1
	Fetter_Detail_FullUpInfo()
end
function Fetter_Detail_NextPage_Clicked()
	if g_Fetter_PageIndex >= g_Fetter_MaxPageNum then return end
	g_Fetter_PageIndex = g_Fetter_PageIndex +1
	Fetter_Detail_FullUpInfo()
end

function Fetter_Detail_FullUpInfo()
	if not this:IsVisible() then 
		g_Fetter_GroupInfo = {}
		local nAllNum = DataPool:LuaFnGetXingZhen_JiBanAwardNum()
		local tabGroupExist = {}
		local nAllLevel = 0
		for i=1,nAllNum do 
			local nGroupId = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(i, "GroupId")
			if not tabGroupExist[nGroupId] then
				nAllLevel = Fetter_Detail_GroupAllLevel(i)
				tabGroupExist[nGroupId] = 1
				local tabInfo = {}
				tabInfo.nIndex = i
				tabInfo.nGroupId = nGroupId
				tabInfo.nAllLevel = nAllLevel
				table.insert(g_Fetter_GroupInfo, tabInfo)
			end
		end
		table.sort(g_Fetter_GroupInfo, function(a, b)
				if a.nAllLevel ~= b.nAllLevel then 
					return a.nAllLevel>b.nAllLevel
				end
				return a.nGroupId<b.nGroupId
			end)
		for i, v in pairs(g_Fetter_GroupInfo) do 
			if v.nGroupId == g_Award_Group_Id then 
				g_Fetter_PageIndex = i
			end
		end

		g_Fetter_MaxPageNum = table.getn(g_Fetter_GroupInfo)
	end
	g_Award_Group_Id = g_Fetter_GroupInfo[g_Fetter_PageIndex].nGroupId
	Fetter_Detail_Frame_Part_LeftArrow_Btn:Enable()
	Fetter_Detail_Frame_Part_RightArrow_Btn:Enable()
	if g_Fetter_PageIndex <= 1 then 
		g_Fetter_PageIndex = 1
		Fetter_Detail_Frame_Part_LeftArrow_Btn:Disable()
	else
		local nPreGroupId = g_Fetter_GroupInfo[g_Fetter_PageIndex-1].nGroupId
		local szTipName = g_GroupImage[nPreGroupId].szName
		Fetter_Detail_Frame_Part_LeftArrow_Btn:SetToolTip( ScriptGlobal_Format("#{XZYX_200309_355}",szTipName) )
	end
	local nMaxPageNum = table.getn(g_GroupImage)
	if g_Fetter_PageIndex >= nMaxPageNum then 
		g_Fetter_PageIndex = nMaxPageNum
		Fetter_Detail_Frame_Part_RightArrow_Btn:Disable()
	else
		local nNextGroupId = g_Fetter_GroupInfo[g_Fetter_PageIndex+1].nGroupId
		local szTipName = g_GroupImage[nNextGroupId].szName
		Fetter_Detail_Frame_Part_RightArrow_Btn:SetToolTip( ScriptGlobal_Format("#{XZYX_200309_355}",szTipName) )
	end


	if g_GroupImage[g_Award_Group_Id] then 
		Fetter_Detail_Actor:SetProperty("Image", g_GroupImage[g_Award_Group_Id].imgBk)
		Fetter_Detail_Actor_HeroBK:SetProperty("Image", g_GroupImage[g_Award_Group_Id].imgName)
	end
	local nMin, nMax = DataPool:LuaFnGetXingZhen_JiBanAwardRange(g_Award_Group_Id)
	local tabIds = {}
	tabIds[1],tabIds[2],tabIds[3],tabIds[4],tabIds[5],tabIds[6],tabIds[7],tabIds[8],tabIds[9],tabIds[10] = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nMin, "YingXiongIds")
	local nIndex = 1
	for i, nYingXiongId in pairs(tabIds) do 
		g_ListInfo_UIControl[nIndex].uiBk:Show()
		g_ListInfo_UIControl[nIndex].uiName:SetText(DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name"))
		g_ListInfo_UIControl[nIndex].uiImage:SetProperty( "Image", DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "HeadImage") );
		local nHaogandu =  DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
		g_ListInfo_UIControl[nIndex].uiNum:SetText( ScriptGlobal_Format("#{XZYX_200309_332}", nHaogandu))

		nIndex = nIndex + 1
	end
	for i=nIndex,table.getn(g_ListInfo_UIControl) do 
		g_ListInfo_UIControl[i].uiBk:Hide()
	end

	Fetter_Detail_UpdateSelectPosition()
end

function Fetter_Detail_GetAward_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FetterDetail_GetAward" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, g_Award_Group_Id );
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()
end
function Fetter_Detail_GoBack_Clicked()
	Variable:SetVariable("RuneStarPos",  Fetter_Detail_Frame:GetProperty("UnifiedPosition"), 1)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenXZ_Fetter" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()
end
function Fetter_Detail_YingXiong_Clicked(nIndex)
	local nMin, nMax = DataPool:LuaFnGetXingZhen_JiBanAwardRange(g_Award_Group_Id)
	local tabIds = {}
	tabIds[1],tabIds[2],tabIds[3],tabIds[4],tabIds[5],tabIds[6],tabIds[7],tabIds[8],tabIds[9],tabIds[10] = DataPool:LuaFnGetXingZhen_JiBanAwardInfo(nMin, "YingXiongIds")
	local nYingXiongId = tabIds[nIndex]
	if not nYingXiongId then return end
	Variable:SetVariable("RuneStarPos",  Fetter_Detail_Frame:GetProperty("UnifiedPosition"), 1)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenXZ_HeDetail" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, nYingXiongId );
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()
end

function Fetter_Detail_HelpInfo_Clicked()
	PushEvent("OPEN_FETTER_AWARD", g_Award_Group_Id)
end

--**********************************
--英雄详细信息
--**********************************
function Fetter_Detail_GetYingXiongLevel_Flag(nYingXiongLevel)
	local nIndex
	if nYingXiongLevel >= 10000 then 
		nIndex = 5
	elseif nYingXiongLevel >= 8000 then 
		nIndex = 4
	elseif nYingXiongLevel >= 5000 then 
		nIndex = 3
	elseif nYingXiongLevel >= 2000 then 
		nIndex = 2
	else
		nIndex = 1
	end
	return g_YingXiongLevel_Flag[nIndex]
end
function Fetter_Detail_ActorDetail_Clicked(nIndex)
	g_ListInfo_PageIndex = nIndex
	Fetter_DetailInfo_LeftArrow_Btn:Enable()
	Fetter_DetailInfo_RightArrow_Btn:Enable()
	if g_ListInfo_PageIndex <= 1 then 
		g_ListInfo_PageIndex = 1
		Fetter_DetailInfo_LeftArrow_Btn:Disable()
	else
		local nYingXiongId = g_ListInfo_UIControl[g_ListInfo_PageIndex-1].id
		local szHeroName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name")
		Fetter_DetailInfo_LeftArrow_Btn:SetToolTip( ScriptGlobal_Format("#{XZYX_200309_354}",szHeroName) )
	end
	if g_ListInfo_PageIndex >= g_ListInfo_MaxPageNum then 
		g_ListInfo_PageIndex = g_ListInfo_MaxPageNum
		Fetter_DetailInfo_RightArrow_Btn:Disable()
	else
		local nYingXiongId = g_ListInfo_UIControl[g_ListInfo_PageIndex+1].id
		local szHeroName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name")
		Fetter_DetailInfo_RightArrow_Btn:SetToolTip( ScriptGlobal_Format("#{XZYX_200309_354}",szHeroName) )
	end
	local nYingXiongId = g_ListInfo_UIControl[nIndex].id
	g_Select_AwardIndex = 0
	Fetter_Detail_DetailInfo_Show(nYingXiongId)
end
function Fetter_Detail_ActorDetail_PreClick()
	if g_ListInfo_PageIndex <=1 then return end
	g_ListInfo_PageIndex = g_ListInfo_PageIndex - 1
	Fetter_Detail_ActorDetail_Clicked(g_ListInfo_PageIndex)
end
function Fetter_Detail_ActorDetail_NextClick()
	if g_ListInfo_PageIndex >= g_ListInfo_MaxPageNum then return end
	g_ListInfo_PageIndex = g_ListInfo_PageIndex + 1
	Fetter_Detail_ActorDetail_Clicked(g_ListInfo_PageIndex)
end
function Fetter_Detail_DetailInfo_Hide()
	-- 显示背景文字
	Fetter_Detail_UpFrame1:Show()
	Fetter_Detail_UpFrame2:Show()
	Fetter_Detail_DownFrame:Show()
	-- 隐藏详细信息
	Fetter_Detail_Frame_Part2:Hide()
	PushEvent("GIVEGIFT_OPEN_CLOSE", 0)
end
function Fetter_Detail_DetailInfo_Show(nYingXiongId)
	-- 先隐藏背景文字
	Fetter_Detail_UpFrame1:Hide()
	Fetter_Detail_UpFrame2:Hide()
	Fetter_Detail_DownFrame:Hide()
	-- 填充详细信息
	Fetter_Detail_Frame_Part2:Show()
	g_Select_YingXiongId = nYingXiongId
	Fetter_DetailInfo_HeroInfo_HeroHead:SetProperty( "Image", DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "HeadImage") )
	Fetter_DetailInfo_HeroInfo_HeroName:SetText( DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name") )
	Fetter_DetailInfo_HeroIntroduction:SetText( DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Desc") )
	local nYingXiongLevel = DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
	-- 英雄好感度
	Fetter_DetailInfo_HeroInfo_HeroIntimacy:SetText(ScriptGlobal_Format("#{XZYX_200309_54}", nYingXiongLevel))
	Fetter_DetailInfo_LikeLevel:SetProperty( "Image", Fetter_Detail_GetYingXiongLevel_Flag(nYingXiongLevel) );
	-- 英雄爱好
	local tabIds = {}
	tabIds[1],tabIds[2],tabIds[3],tabIds[4],tabIds[5] = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Interests")
	for i, nInterestsId in pairs(tabIds) do 
		local nItemId = DataPool:LuaFnGetXingZhen_InterestsInfo(nInterestsId, "Shouli_ItemId1")
		local objAction = DataPool:CreateActionItemForShow(nItemId, 1)
		g_tabInterests[i].uiAwardItem:SetActionItem(objAction:GetID());
		local nGiveNum = DataPool:LuaFnGetXingZhen_InterestsGiveNum(nInterestsId)
		g_tabInterests[i].uiAwardNum:SetText(ScriptGlobal_Format("#{XZYX_200309_382}", 10-nGiveNum))
		local nMaxLevel = DataPool:LuaFnGetXingZhen_InterestsInfo(nInterestsId, "MaxLevel")
		local nTotalGiveNum = DataPool:LuaFnGetXingZhen_InterestsTotalGiveNum(nInterestsId)
		g_tabInterests[i].uiGiveNum:SetText(ScriptGlobal_Format("#{XZYX_200309_334}", nTotalGiveNum, nMaxLevel*10))
		if nTotalGiveNum == nMaxLevel*10 then 
			g_tabInterests[i].uiAwardNum:Hide()
			g_tabInterests[i].uiGiveNum:Hide()
			g_tabInterests[i].uiGiveOver:Show()
		else
			g_tabInterests[i].uiAwardNum:Show()
			g_tabInterests[i].uiGiveNum:Show()
			g_tabInterests[i].uiGiveOver:Hide()
		end
	end
	Fetter_Detail_UpdateDetail_ItemNum()
	-- 英雄技能
	local nSkillCardID = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "SkillIndex")
	local szSkillName = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Name")
	local theAction = EnumAction(nSkillCardID,"skillcard")
	Fetter_DetailInfo_HeroIntroduction2:SetActionItem(theAction:GetID())
	Fetter_DetailInfo_HeroIntroduction2Name:SetText("#L"..szSkillName)
	local nUnLocked = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "UnLocked")
	if nUnLocked == 1 then
		Fetter_DetailInfo_HeroIntroduction2_SkillLock:Hide()
		Fetter_DetailInfo_HeroIntroduction2_StepsBK:Show()
		local nLevel = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Level")
		Fetter_DetailInfo_HeroIntroduction2_Steps:SetText(tostring(nLevel))
	else
		Fetter_DetailInfo_HeroIntroduction2_SkillLock:Show()
		Fetter_DetailInfo_HeroIntroduction2_StepsBK:Hide()
	end
	local nSceneId, nPosx, nPosz = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "NpcSceneInfo")
	local szSceneName = GetSceneNameByID(nSceneId)
	local szNpcName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name")
	Fetter_DetailInfo_HeroInfo_GoToHeroesBtn:SetToolTip(ScriptGlobal_Format("#{XZYX_200309_226}", szSceneName, nPosx, nPosz, szNpcName))
	-- 英雄好感度奖励
	local nAward_MaxLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardLevel(nYingXiongId)
	local nGroupId = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "AwardIndex")
	local nNextLevel = DataPool:LuaFnGetXingZhen_YingXiongNextAwardLevel(nGroupId, nAward_MaxLevel)
	
	if not nNextLevel then 
		Fetter_DetailInfo_HeroInfo_BonusCondition2:Hide()
		Fetter_DetailInfo_HeroInfo_QuestionMark:Hide()
		
		local scID = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "SkillIndex")
		local strName = DataPool:LuaFnGetSkillCardInfo(scID, "Name")
		Fetter_DetailInfo_HeroInfo_BonusCondition:SetText(ScriptGlobal_Format("#{XZJC_202106_368}", strName))		
	else
		Fetter_DetailInfo_HeroInfo_BonusCondition2:Hide()
		Fetter_DetailInfo_HeroInfo_QuestionMark:Show()
		
		local scID, scLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardInfo(nGroupId, nNextLevel)
		local strName = DataPool:LuaFnGetSkillCardInfo(scID, "Name")
		Fetter_DetailInfo_HeroInfo_BonusCondition:SetText(ScriptGlobal_Format("#{XZJC_202106_367}", nNextLevel, strName, tostring(scLevel)))		
	end
	-- 赠送礼物选中状态
	Fetter_Detail_SelectZengLi_Clicked(g_Select_AwardIndex)
end

function Fetter_Detail_UpdateDetail_ItemNum()
	if g_Select_YingXiongId == 0 then 
		return 
	end
	local nYingXiongId = g_Select_YingXiongId
	local tabIds = {}
	tabIds[1],tabIds[2],tabIds[3],tabIds[4],tabIds[5] = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Interests")
	for i=1,2 do 
		local nItemId = DataPool:LuaFnGetXingZhen_InterestsInfo(tabIds[i], "Shouli_ItemId1")
		local itemCount	= PlayerPackage:CountAvailableItemByIDTable(nItemId) + PlayerPackage:Lua_GetLockItemCount(nItemId)
		g_tabInterests[i].uiItemNum:SetText(tostring(itemCount))
	end
end

function Fetter_Detail_GotoHeroes_Clicked()
	local nYingXiongId = g_Select_YingXiongId

	local szName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "SceneName")
	local nSceneId, posx, posz = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "NpcSceneInfo")
	AutoRunToTargetEx(posx,posz,nSceneId)
	SetAutoRunTargetNPCName(szName)
end

function Fetter_Detail_Award_HelpInfo_Clicked()
	local nYingXiongId = g_Select_YingXiongId
	local nAward_MaxLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardLevel(nYingXiongId)
	local nGroupId = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "AwardIndex")
	local nNextLevel = DataPool:LuaFnGetXingZhen_YingXiongNextAwardLevel(nGroupId, 0)
	local szInfo = "#{XZJC_202106_370}"
	while nNextLevel do 
		local scID, scLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardInfo(nGroupId,nNextLevel)
		local scName = DataPool:LuaFnGetSkillCardInfo(scID, "Name")
		szInfo = szInfo..ScriptGlobal_Format("#r#{XZJC_202106_371}", nNextLevel, tostring(scName), tostring(scLevel))
		
		if nAward_MaxLevel >= nNextLevel then
			szInfo = szInfo.."#{XZYX_200309_53}"
		end
		nNextLevel = DataPool:LuaFnGetXingZhen_YingXiongNextAwardLevel(nGroupId, nNextLevel)
	end

	PushEvent( "RUNE_STARS_TEXTINFO", "Fetter_Detail", szInfo, "#{XZYX_200309_383}" )
end

function Fetter_Detail_SelectZengLi_Clicked(nIndex)
	g_Select_AwardIndex = nIndex
	if g_Select_AwardIndex == 1 then 
		Fetter_DetailInfo_HeroInfo_GiftIcon_Mask:Show()
		Fetter_DetailInfo_HeroInfo_GiftIcon2_Mask:Hide()
	elseif g_Select_AwardIndex == 2 then 
		Fetter_DetailInfo_HeroInfo_GiftIcon_Mask:Hide()
		Fetter_DetailInfo_HeroInfo_GiftIcon2_Mask:Show()
	else
		Fetter_DetailInfo_HeroInfo_GiftIcon_Mask:Hide()
		Fetter_DetailInfo_HeroInfo_GiftIcon2_Mask:Hide()
	end
end

function Fetter_Detail_DirectZengLi_Clicked()
	local nYingXiongId = g_Select_YingXiongId
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenXZ3_GiveGift" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, nYingXiongId );
		Set_XSCRIPT_Parameter( 1, g_Select_AwardIndex );
		Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
	Send_XSCRIPT()
end