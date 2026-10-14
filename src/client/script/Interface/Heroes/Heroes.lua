--Heroes.lua
--星阵-英雄总览界面
local g_Frame_UnifiedPosition

local g_tab_HeroesList = {}
local g_tabInterests = {}
local g_Select_YingXiongId = 0
local g_ListInfo_PageIndex = 0
local g_ListInfo_MaxPageNum = 0
local g_Select_AwardIndex = 0

local g_YingXiongLevel_Flag = {
	"set:Rune_Star01 image:JiaoBiao1",
	"set:Rune_Star01 image:JiaoBiao4",
	"set:Rune_Star01 image:JiaoBiao5",
	"set:Rune_Star01 image:JiaoBiao3",
	"set:Rune_Star01 image:JiaoBiao2",
}
--预加载函数，可以而且只能在这里注册脚本关心的事件
function Heroes_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("YINGXIONG_REDPOINT")
	this:RegisterEvent("XINGZHEN_UPDATE",false)
	this:RegisterEvent("CLOSE_XINGZHENUI_GROUP",false)
	this:RegisterEvent("YINGXIONG_CHANGE",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Heroes_OnLoad()
	g_Frame_UnifiedPosition = Heroes_Frame:GetProperty("UnifiedPosition")
	Heroes_List:Clear()
	Heroes_Frame_Part2:Hide()

	g_tabInterests = {
		{uiAwardItem=Heroes_Detail_HeroInfo_GiftIcon,uiAwardNum=Heroes_Detail_GiftItem1_GiftInfo,uiGiveNum=Heroes_Detail_GiftItem1_TotalGive1,uiGiveOver=Heroes_DetailInfo_GiftItem1_TotalGive1Over, uiItemNum=Heroes_Detail_HeroInfo_GiftIcon_Num},
		{uiAwardItem=Heroes_Detail_HeroInfo_GiftIcon2,uiAwardNum=Heroes_Detail_GiftItem1_GiftInfo2,uiGiveNum=Heroes_Detail_GiftItem1_TotalGive2,uiGiveOver=Heroes_DetailInfo_GiftItem1_TotalGive2Over, uiItemNum=Heroes_Detail_HeroInfo_GiftIcon2_Num},
	}

	Heroes_Bind:AddTextItem("#{XZYX_200309_348}", 0);
	Heroes_Bind:AddTextItem("#{XZYX_200309_349}", 1);
	Heroes_Bind:AddTextItem("#{XZYX_200309_350}", 2);
	Heroes_Bind:AddTextItem("#{XZYX_200309_351}", 3);
	Heroes_Bind:AddTextItem("#{XZYX_200309_352}", 4);
end

--响应事件的函数，当注册的事件发生时会调用的函数
function Heroes_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		Heroes_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 14220001 ) then
		if Get_XParam_INT( 0 ) == 0 then 
			this:Hide()
			return
		end

		Heroes_Frame:SetProperty("UnifiedPosition", Variable:GetVariable("RuneStarPos") or g_Frame_UnifiedPosition)
		this:Show()
		Heroes_ResetTagButton()
		Heroes_UpdateXingZhenRedPoint()
		Heroes_Bind:SetCurrentSelect(0);
		Heroes_Quality_Changed()
	elseif ( event == "YINGXIONG_REDPOINT" ) then
		Heroes_UpdateRedPoint(arg0,arg1,arg2)
	elseif ( event == "YINGXIONG_CHANGE" ) then
		if tonumber(arg0) == g_Select_YingXiongId then
			Heroes_DetailInfo_Show(g_Select_YingXiongId)
			Heroes_FullUpHeroesList_OneInfo(g_Select_YingXiongId)
		end
	end
	
	if event == "XINGZHEN_UPDATE" then
		Heroes_UpdateXingZhenRedPoint()
		return
	end
	
	if event == "CLOSE_XINGZHENUI_GROUP" then
		this:Hide()
		return
	end

	if event == "PACKAGE_ITEM_CHANGED_EX" then 
		Heroes_UpdateDetail_ItemNum()
	end
end

function Heroes_UpdateXingZhenRedPoint()
	
	Heroes_Left_Buttontab01_Tips:Hide()
	Heroes_Left_Buttontab02_Tips:Hide()
	Heroes_Left_Buttontab03_Tips:Hide()
	
	if DataPool:LuaFnHaveXingJuanToSlot() == 1 then
		--有星卷可以上阵
		Heroes_Left_Buttontab01_Tips:Show()
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
			Heroes_Left_Buttontab01_Tips:Show()
		elseif DataPool:LuaFnHaveNewXingJuan() == 1 then
			--有新的星卷
			Heroes_Left_Buttontab01_Tips:Show()
		elseif DataPool:LuaFnHaveNewSkillCard() == 1 then
			--有新的技能
			Heroes_Left_Buttontab01_Tips:Show()
		end
	end
	
	if DataPool:LuaFnHaveXingJuanToUpgrade() == 1 then
		--有星卷可以升阶
		Heroes_Left_Buttontab02_Tips:Show()
	end
	
	if DataPool:LuaFnHaveXingJuanToUnLock() == 1 then	
		--有星卷可以激活
		Heroes_Left_Buttontab02_Tips:Show()
	end
	
	--有技能可以升级
	if DataPool:LuaFnHaveSkillCardToLevelUp() == 1 then
		Heroes_Left_Buttontab03_Tips:Show()	
	end
end

--以下是用户自定义的函数
function Heroes_UpdateRedPoint(gift_flag,level_flag,attr_flag)
	gift_flag=tonumber(gift_flag);level_flag=tonumber(level_flag);attr_flag=tonumber(attr_flag)
	if gift_flag==1 or level_flag==1 or attr_flag==1 then 
		Heroes_Left_Buttontab04_Tips:Show()
	else
		Heroes_Left_Buttontab04_Tips:Hide()
	end
	if gift_flag==1 or level_flag==1 then 
		Heroes_Tab_Hero_RedDot:Show()
	else
		Heroes_Tab_Hero_RedDot:Hide()
	end
	if attr_flag==1 then 
		Heroes_Tab_Fetter_RedDot:Show()
	else
		Heroes_Tab_Fetter_RedDot:Hide()
	end
end
function Heroes_OnHidden()
	this:Hide()
	Heroes_DetailInfo_Hide()
end
function Heroes_ResetTagButton()
	Heroes_Left_Buttontab01:SetCheck(0)
	Heroes_Left_Buttontab02:SetCheck(0)
	Heroes_Left_Buttontab03:SetCheck(0)
	Heroes_Left_Buttontab04:SetCheck(1)
	Heroes_Tab_Hero:SetCheck(1)
	Heroes_Tab_Fetter:SetCheck(0)
end
function Heroes_XingZhen_Clicked()
	Variable:SetVariable("RuneStarPos", Heroes_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhen(true, 0, 0)
end
function Heroes_YangCheng_Clicked()
	Variable:SetVariable("RuneStarPos", Heroes_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhenUpgrade()
end
function Heroes_SuiPian_Clicked()
	Variable:SetVariable("RuneStarPos", Heroes_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhenSkill()
end
function Heroes_YingXiong_Clicked()
end
function Heroes_OpenHeroes_Clicked()
end
function Heroes_OpenFetter_Clicked()
	Variable:SetVariable("RuneStarPos",  Heroes_Frame:GetProperty("UnifiedPosition"), 1)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenXZ_Fetter" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end

function Heroes_GetYingXiongLevel_Flag(nYingXiongLevel)
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
function Heroes_FullUpHeroesList_OneInfo(nYingXiongId)
	for i, v in pairs(g_tab_HeroesList) do 
		if v.id == nYingXiongId then 
			local uiPrefab = Heroes_List:GetListItemAt(i)
			v.nLevel = DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
			uiPrefab:GetSubItem("Heroes_Actor_LevelText"):SetText( ScriptGlobal_Format("#{XZYX_200309_332}", v.nLevel))
			return
		end
	end
end
function Heroes_FullUpHeroesList()
	-- local nCount = Heroes_List:GetListItemCount()
	-- for i=1,nCount do 
	-- 	local uiPrefab = Heroes_List:GetListItemAt(i)
	-- 	uiPrefab:GetSubItem("Heroes_Skill"):SetActionItem(-1)
	-- end
	Heroes_List:Clear()
	for i, v in pairs(g_tab_HeroesList) do 
		local nYingXiongId = v.id
		local uiPrefab = Heroes_List:AddChild("Heroes_Actor")
		uiPrefab:GetSubItem("Heroes_Actor_Image"):SetProperty( "Image", DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "HeadImage") );
		uiPrefab:GetSubItem("Heroes_Actor_Name"):SetText( DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name") );
		uiPrefab:GetSubItem("Heroes_Actor_Btn"):SetEvent( "Clicked", string.format("Heroes_ActorDetail_Clicked(%d)", i))
		-- 英雄好感度
		local tabIds = {}
		tabIds[1],tabIds[2],tabIds[3],tabIds[4],tabIds[5] = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Interests")
		-- local nHaogandu = DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
		uiPrefab:GetSubItem("Heroes_Actor_LevelText"):SetText( ScriptGlobal_Format("#{XZYX_200309_332}", v.nLevel))
		uiPrefab:GetSubItem("Heroes_LikeLevel"):SetProperty( "Image", Heroes_GetYingXiongLevel_Flag(v.nLevel) );
		-- 英雄技能
		local nSkillCardID = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "SkillIndex")
		local nSkillQuality = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Quality")
		local szSkillName = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Name")
		local theAction = EnumAction(nSkillCardID,"skillcard")
		uiPrefab:GetSubItem("Heroes_Skill"):SetActionItem(theAction:GetID())

		uiPrefab:GetSubItem("Heroes_SkillName"):SetText("#L"..szSkillName );
		local nUnLocked = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "UnLocked")
		if nUnLocked == 1 then
			uiPrefab:GetSubItem("Heroes_Skill_HeroIntroduction2_SkillLock"):Hide()
			uiPrefab:GetSubItem("Heroes_Skill_HeroIntroduction2_StepsBK"):Show()
			local nLevel = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Level")
			uiPrefab:GetSubItem("Heroes_Skill_HeroIntroduction2_Steps"):SetText(tostring(nLevel))
		else
			uiPrefab:GetSubItem("Heroes_Skill_HeroIntroduction2_SkillLock"):Show()
			uiPrefab:GetSubItem("Heroes_Skill_HeroIntroduction2_StepsBK"):Hide()
		end
	end
	-- Heroes_List:SetSelected(1);
end

function Heroes_OpenFetter_Clicked()
	Variable:SetVariable("RuneStarPos",  Heroes_Frame:GetProperty("UnifiedPosition"), 1)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenXZ_Fetter" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end

--**********************************
--英雄详细信息
--**********************************
function Heroes_ActorDetail_Clicked(nIndex)
	g_ListInfo_PageIndex = nIndex
	Heroes_Detail_LeftArrow_Btn:Enable()
	Heroes_Detail_RightArrow_Btn:Enable()
	if g_ListInfo_PageIndex <= 1 then 
		g_ListInfo_PageIndex = 1
		Heroes_Detail_LeftArrow_Btn:Disable()
	else
		local nYingXiongId = g_tab_HeroesList[g_ListInfo_PageIndex-1].id
		local szHeroName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name")
		Heroes_Detail_LeftArrow_Btn:SetToolTip( ScriptGlobal_Format("#{XZYX_200309_354}",szHeroName) )
	end
	if g_ListInfo_PageIndex >= g_ListInfo_MaxPageNum then 
		g_ListInfo_PageIndex = g_ListInfo_MaxPageNum
		Heroes_Detail_RightArrow_Btn:Disable()
	else
		local nYingXiongId = g_tab_HeroesList[g_ListInfo_PageIndex+1].id
		local szHeroName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name")
		Heroes_Detail_RightArrow_Btn:SetToolTip( ScriptGlobal_Format("#{XZYX_200309_354}",szHeroName) )
	end
	local nYingXiongId = g_tab_HeroesList[nIndex].id
	g_Select_AwardIndex = 0
	Heroes_DetailInfo_Show(nYingXiongId)
end
function Heroes_ActorDetail_PreClick()
	if g_ListInfo_PageIndex <=1 then return end
	g_ListInfo_PageIndex = g_ListInfo_PageIndex - 1
	Heroes_ActorDetail_Clicked(g_ListInfo_PageIndex)
end
function Heroes_ActorDetail_NextClick()
	if g_ListInfo_PageIndex >= g_ListInfo_MaxPageNum then return end
	g_ListInfo_PageIndex = g_ListInfo_PageIndex + 1
	Heroes_ActorDetail_Clicked(g_ListInfo_PageIndex)
end
function Heroes_DetailInfo_Hide()
	-- 显示背景文字
	-- 隐藏详细信息
	Heroes_Frame_Part2:Hide()
	PushEvent("GIVEGIFT_OPEN_CLOSE", 0)
end
function Heroes_DetailInfo_Show(nYingXiongId)
	g_Select_YingXiongId = nYingXiongId
	-- 先隐藏背景文字
	-- 填充详细信息
	Heroes_Frame_Part2:Show()
	Heroes_Detail_HeroInfo_HeroHead:SetProperty( "Image", DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "HeadImage") )
	Heroes_Detail_HeroInfo_HeroName:SetText( DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name") )
	Heroes_Detail_HeroIntroduction:SetText( DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Desc") )
	local nYingXiongLevel = DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
	-- 英雄好感度
	Heroes_Detail_HeroInfo_HeroIntimacy:SetText(ScriptGlobal_Format("#{XZYX_200309_54}", nYingXiongLevel))
	Heroes_Detail_LikeLevel:SetProperty( "Image", Heroes_GetYingXiongLevel_Flag(nYingXiongLevel) );
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
	Heroes_UpdateDetail_ItemNum()
	-- 英雄技能
	local nSkillCardID = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "SkillIndex")
	local szSkillName = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Name")
	local theAction = EnumAction(nSkillCardID,"skillcard")
	Heroes_Detail_HeroIntroduction2:SetActionItem(theAction:GetID())
	Heroes_Detail_HeroIntroduction2Name:SetText("#L"..szSkillName)
	local nUnLocked = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "UnLocked")
	if nUnLocked == 1 then
		Heroes_Detail_HeroIntroduction2_SkillLock:Hide()
		Heroes_Detail_HeroIntroduction2_StepsBK:Show()
		local nLevel = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Level")
		Heroes_Detail_HeroIntroduction2_Steps:SetText(tostring(nLevel))
	else
		Heroes_Detail_HeroIntroduction2_SkillLock:Show()
		Heroes_Detail_HeroIntroduction2_StepsBK:Hide()
	end
	local nSceneId, nPosx, nPosz = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "NpcSceneInfo")
	local szSceneName = GetSceneNameByID(nSceneId)
	local szNpcName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "Name")
	Heroes_Detail_HeroInfo_GoToHeroesBtn:SetToolTip(ScriptGlobal_Format("#{XZYX_200309_226}", szSceneName, nPosx, nPosz, szNpcName))
	-- 英雄好感度奖励
	local nAward_MaxLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardLevel(nYingXiongId)
	local nGroupId = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "AwardIndex")
	local nNextLevel = DataPool:LuaFnGetXingZhen_YingXiongNextAwardLevel(nGroupId, nAward_MaxLevel)
	if not nNextLevel then 
		Heroes_Detail_HeroInfo_BonusCondition2:Hide()
		Heroes_Detail_HeroInfo_QuestionMark:Hide()
		
		local scID = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "SkillIndex")
		local strName = DataPool:LuaFnGetSkillCardInfo(scID, "Name")
		Heroes_Detail_HeroInfo_BonusCondition:SetText(ScriptGlobal_Format("#{XZJC_202106_368}", strName))
	else
		Heroes_Detail_HeroInfo_BonusCondition2:Hide()
		Heroes_Detail_HeroInfo_QuestionMark:Show()
		
		local scID, scLevel = DataPool:LuaFnGetXingZhen_YingXiongAwardInfo(nGroupId, nNextLevel)
		local strName = DataPool:LuaFnGetSkillCardInfo(scID, "Name")
		Heroes_Detail_HeroInfo_BonusCondition:SetText(ScriptGlobal_Format("#{XZJC_202106_367}", nNextLevel, strName, tostring(scLevel)))
	end
	-- 赠送礼物选中状态
	Heroes_SelectZengLi_Clicked(g_Select_AwardIndex)
end

function Heroes_UpdateDetail_ItemNum()
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
function Heroes_GotoHeroes_Clicked()
	local nYingXiongId = g_Select_YingXiongId

	local szName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "SceneName")
	local nSceneId, posx, posz = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "NpcSceneInfo")
	AutoRunToTargetEx(posx,posz,nSceneId)
	SetAutoRunTargetNPCName(szName)
end

function Heroes_Award_HelpInfo_Clicked()
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

	PushEvent( "RUNE_STARS_TEXTINFO", "Heroes", szInfo, "#{XZYX_200309_383}" )
end

function Heroes_Quality_Changed()
	g_tab_HeroesList = {}
	local nSelStr, nSelIndex = Heroes_Bind:GetCurrentSelect();
	-- PushDebugMessage("Heroes_Quality_Changed:"..nSelIndex)
	local nYingXiongNum = DataPool:LuaFnGetXingZhen_YingXiongNum()
	for i=1,nYingXiongNum do 
		local nYingXiongId = i
		local nYingXiongLevel = DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(nYingXiongId)
		local nSkillCardID = DataPool:LuaFnGetXingZhen_YingXiongInfo(nYingXiongId, "SkillIndex")
		local nSkillQuality = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Quality")
		local IsCanInsert = 0
		if nSelIndex == 4 then
			if nSkillQuality==1 then IsCanInsert = 1 end
		elseif nSelIndex == 3 then 
			if nSkillQuality==2 then IsCanInsert = 1 end
		elseif nSelIndex == 2 then 
			if nSkillQuality==3 then IsCanInsert = 1 end
		elseif nSelIndex == 1 then 
			if nSkillQuality==4 then IsCanInsert = 1 end
		else
			IsCanInsert = 1 
		end
		if IsCanInsert == 1 then 
			table.insert(g_tab_HeroesList, {id=nYingXiongId, nLevel=nYingXiongLevel, nQuality=nSkillQuality})
		end
	end
	g_ListInfo_MaxPageNum = table.getn(g_tab_HeroesList)
	table.sort(g_tab_HeroesList, function(a, b)
			if a.nLevel~=b.nLevel then 
				return a.nLevel>b.nLevel
			end
			if a.nQuality~=b.nQuality then 
				return a.nQuality>b.nQuality
			end
			return a.id<b.id
		end)

	Heroes_FullUpHeroesList()
end
function Heroes_SelectZengLi_Clicked(nIndex)
	g_Select_AwardIndex = nIndex
	if g_Select_AwardIndex == 1 then 
		Heroes_Detail_HeroInfo_GiftIcon_Mask:Show()
		Heroes_Detail_HeroInfo_GiftIcon2_Mask:Hide()
	elseif g_Select_AwardIndex == 2 then 
		Heroes_Detail_HeroInfo_GiftIcon_Mask:Hide()
		Heroes_Detail_HeroInfo_GiftIcon2_Mask:Show()
	else
		Heroes_Detail_HeroInfo_GiftIcon_Mask:Hide()
		Heroes_Detail_HeroInfo_GiftIcon2_Mask:Hide()
	end
end
function Heroes_DirectZengLi_Clicked()
	local nYingXiongId = g_Select_YingXiongId
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenXZ3_GiveGift" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 888052 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, nYingXiongId );
		Set_XSCRIPT_Parameter( 1, g_Select_AwardIndex );
		Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
	Send_XSCRIPT()
end