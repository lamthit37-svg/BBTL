--!!!reloadscript =Rune_Stars_Skill

local g_Rune_Stars_Skill_UnifiedPosition = ""
local g_MaxBarNum = 100

local g_BarList = {}

local g_CurrentFilter = 0
local g_InitList = 0
local g_CurrentSelSkill = 0
local g_MaxCardLevel = 5
local g_NeedChangeScrollSize = 0

function Rune_Stars_Skill_PreLoad()

	this:RegisterEvent("OPEN_XINGZHEN_SKILL")	
	this:RegisterEvent("XINGZHEN_UPDATE",false)
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	--更新装备
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("XINGJUAN_STOREEXP",false)
	this:RegisterEvent("XINGJUAN_CHIPDRE",false)
	this:RegisterEvent("XINGJUAN_CHIPESS",false)
	
	this:RegisterEvent("YINGXIONG_REDPOINT")
	this:RegisterEvent("CLOSE_XINGZHENUI_GROUP",false)

end

function Rune_Stars_Skill_OnLoad()
	
	g_Rune_Stars_Skill_UnifiedPosition = Rune_Stars_Skill_Frame:GetProperty("UnifiedPosition")
	Rune_Stars_Skill_Bind:AddTextItem("#{XZJC_200309_72}" ,1)	--全部
	Rune_Stars_Skill_Bind:AddTextItem("#{XZJC_200309_73}" ,2)	--已激活
	Rune_Stars_Skill_Bind:AddTextItem("#{XZJC_200309_74}" ,3)	--未激活
	Rune_Stars_Skill_Bind:AddTextItem("#{XZJC_200309_75}" ,4)	--未激活
	Rune_Stars_Skill_Bind:AddTextItem("#{XZJC_200309_76}" ,5)	--未激活
	
end

function Rune_Stars_Skill_OnEvent(event)

	if event == "OPEN_XINGZHEN_SKILL" then
		this:Show()
		g_CurrentFilter = 1
		g_CurrentSelSkill = 0
		g_NeedChangeScrollSize = 1
		Rune_Stars_Skill_Bind:SetText("#{XZJC_200309_72}")		
		Rune_Stars_Skill_Update()		
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
	if event == "CLOSE_XINGZHENUI_GROUP" then
		this:Hide()
		return
	end

	if event == "XINGZHEN_UPDATE"  and this:IsVisible() then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Skill_Frame:GetProperty("UnifiedPosition"), 1)
		Rune_Stars_Skill_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Rune_Stars_Skill_On_ResetPos()
	end
	
	if event == "YINGXIONG_REDPOINT" then
		if tonumber(arg0)==1 or tonumber(arg1)==1 or tonumber(arg2) == 1 then 
			Rune_Stars_Skill_FenYe4_Buttontips:Show()
		else
			Rune_Stars_Skill_FenYe4_Buttontips:Hide()
		end
	end

end

function Rune_Stars_Skill_InitListBar()	
	if g_InitList == 0 then		
		g_MaxBarNum = DataPool:LuaFnGetSkillCardMaxCount()
		for i = 1, g_MaxBarNum do
			local bar = Rune_Stars_Skill_Lace:AddChild("Rune_Stars_Skill_CoinAItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			g_BarList[i] = bar	
			bar:GetSubItem("Rune_Stars_Skill_CoinAItemOption"):SetEvent("MouseLButtonDown", string.format("Rune_Stars_Skill_ItemClicked(%d)", i))
		end	
		g_InitList = 1
	end
end

--刷新
function Rune_Stars_Skill_Update()
	
	local selfUnionPos = Variable:GetVariable("RuneStarPos")
	if selfUnionPos ~= nil then
		Rune_Stars_Skill_Frame:SetProperty("UnifiedPosition", selfUnionPos)
	end
	
	Rune_Stars_Skill_InitListBar()
	
	Rune_Stars_Skill_Refresh_Page_Button()
	Rune_Stars_Skil_UpdateRedPoint()
	
	Rune_Stars_Skill_ListCleanUpAction()
	DataPool:LuaFnInitSkillCardList(g_CurrentFilter)
	local nCount = DataPool:LuaFnGetSkillCardListCount()	
	
	for i = 1, g_MaxBarNum do
		Rune_Stars_Skill_SetItem(i, nCount)
	end
	
	if g_NeedChangeScrollSize == 1 then		
		Rune_Stars_Skill_Lace:RefreshLayout()
		Rune_Stars_Skill_Lace:SetScrollPosition(0)
		g_NeedChangeScrollSize = 0
	end
	
	Rune_Stars_Skill_UpdateSel()
end

function Rune_Stars_Skill_UpdateSel()
	
	Rune_Stars_Skill_SkillBtn1:SetActionItem(-1)
	Rune_Stars_Skill_SkillBtn2:SetActionItem(-1)
	
	Rune_Stars_Skill_SkillBtn1StepsBK:Hide()
	Rune_Stars_Skill_SkillBtn1Fight:Hide()
	
--	Rune_Stars_SkillInfo1:Show()
--	Rune_Stars_SkillInfo2:Show()
	
	Rune_Stars_Skill_Text1:SetText("")
	Rune_Stars_Skill_Text2:SetText("")
	
	Rune_Stars_SkillTitle1:Hide()
	Rune_Stars_SkillTitle2:Hide()
	
	Rune_Stars_Skill_SkillBtn2Text:Hide()
	
	Rune_Stars_Skill_Look:Hide()
	
	Rune_Stars_Skill_SkillUpText:SetText("")
	
	Rune_Stars_Skill_SkillName:SetText("")
	
	Rune_Stars_Skill_OK:Show()
	Rune_Stars_Skill_SkillBtn2Text2:Hide()
	
	Rune_Stars_Skill_SkillUpText2:Hide()
	Rune_Stars_Skill_SkillUpText3:Hide()
	Rune_Stars_Skill_SkillUpText4:Hide()
	
	if g_CurrentSelSkill ~= 0 then
	
		Rune_Stars_SkillTitle1:Show()
		Rune_Stars_SkillTitle2:Show()
	
		Rune_Stars_Skill_Look:Show()
		
		local nUnLocked = DataPool:LuaFnGetSkillCardInfo(g_CurrentSelSkill, "UnLocked")		
		local nLevel = DataPool:LuaFnGetSkillCardInfo(g_CurrentSelSkill, "Level")
		local nQuality = DataPool:LuaFnGetSkillCardInfo(g_CurrentSelSkill, "Quality")
		local nSlot = DataPool:LuaFnGetSkillCardInfo(g_CurrentSelSkill, "Slot")
		local strName = DataPool:LuaFnGetSkillCardInfo(g_CurrentSelSkill, "Name")
		local strNameColor = Rune_Stars_Skil_GetQualColor(nQuality)
		Rune_Stars_Skill_SkillName:SetText("#L"..strName)
	
		local theAction = EnumAction(g_CurrentSelSkill,"skillcard")
		if theAction:GetID() ~= 0 then
			Rune_Stars_Skill_SkillBtn1:SetActionItem(theAction:GetID())
		end
		
		if nUnLocked == 1 then
		Rune_Stars_Skill_SkillBtn1StepsBK:Show()
		Rune_Stars_Skill_SkillBtn1Steps:SetText(tostring(nLevel))
		end
		
		local nOrderExtra = 0
		--上阵标识
		if nSlot > 0 then
			Rune_Stars_Skill_SkillBtn1Fight:Show()
			local nXingJuanID = DataPool:LuaFnGetActivedXingJuanID(nSlot)
			if nXingJuanID > 0 then
				nOrderExtra = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
			end
		end
		
		local strTitle = ""
		local strDesc = ""
		
		if nUnLocked ~= 1 then
			
		end
		
		if nUnLocked == 1 then
			--left
			strTitle = ScriptGlobal_Format("#{XZJC_200309_143}", tostring(nLevel))
			Rune_Stars_SkillTitle1:SetText(strTitle)
			
			_,_,strDesc = DataPool:LuaFnSkillCardDesc(g_CurrentSelSkill, nLevel, 0)
			Rune_Stars_Skill_Text1:SetText(strDesc)
		
			--right
			if nLevel ~= g_MaxCardLevel then
				strTitle = ScriptGlobal_Format("#{XZJC_200309_143}", tostring(nLevel + 1))
				Rune_Stars_SkillTitle2:SetText(strTitle)
				_,_,strDesc = DataPool:LuaFnSkillCardDesc(g_CurrentSelSkill, nLevel + 1, 0)
				Rune_Stars_Skill_Text2:SetText(strDesc)
			else
				Rune_Stars_SkillTitle2:SetText("#{XZJC_200309_230}")
				Rune_Stars_Skill_Text2:SetText("#{XZJC_200309_351}")
				--Rune_Stars_Skill_Text2:SetProperty("HorzFormatting", "WordWrapCentred")
			end
		
			local heroID, heroRelate = DataPool:LuaFnGetSkillCardLevelNeed(g_CurrentSelSkill, nLevel)
		
			Rune_Stars_Skill_SkillBtn2BK:Hide()
			
			if nLevel ~= g_MaxCardLevel then
				
				Rune_Stars_Skill_SkillUpText2:Show()
				Rune_Stars_Skill_SkillUpText3:Show()
				
				local heroName = DataPool:LuaFnGetXingZhen_YingXiongInfo(heroID, "Name")
				local heroLevel = DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(heroID)
				
				local strTemp = ScriptGlobal_Format("#{XZJC_202106_361}", tostring(heroName), tostring(heroRelate))
				Rune_Stars_Skill_SkillUpText2:SetText(strTemp)
				
				if heroLevel >= heroRelate then
					strTemp = ScriptGlobal_Format("#{XZJC_202106_362}", tostring(heroName), "#M"..tostring(heroLevel))
				else
					strTemp = ScriptGlobal_Format("#{XZJC_202106_362}", tostring(heroName), "#cFF0000"..tostring(heroLevel))
				end				
				Rune_Stars_Skill_SkillUpText3:SetText(strTemp)
			else
				Rune_Stars_Skill_SkillUpText4:Show()
				local strTemp = ScriptGlobal_Format("#{XZJC_202106_365}", strName)
				Rune_Stars_Skill_SkillUpText4:SetText(strTemp)
			end
		else
			--left
			Rune_Stars_SkillTitle1:SetText("#{XZJC_200309_335}")
			Rune_Stars_Skill_Text1:SetText("#{XZJC_200309_350}")
			
			--right
			strTitle = ScriptGlobal_Format("#{XZJC_200309_143}", "1")
			Rune_Stars_SkillTitle2:SetText(strTitle)
			_,_,strDesc = DataPool:LuaFnSkillCardDesc(g_CurrentSelSkill, 1, 0)
			Rune_Stars_Skill_Text2:SetText(strDesc)

			--bottom
			Rune_Stars_Skill_SkillUpText:SetText("#{XZJC_200309_352}")

			Rune_Stars_Skill_OK:Hide()
			Rune_Stars_Skill_SkillBtn2BK:Show()

			local need_item = DataPool:LuaFnGetSkillCardInfo(g_CurrentSelSkill, "ActiveItem")
			local itemAction = DataPool:CreateActionItemForShow(need_item,1)
			if itemAction:GetID() ~= 0 then
				Rune_Stars_Skill_SkillBtn2:SetActionItem(itemAction:GetID())
			end

			local strItemName = DataPool:Lua_GetItemNameByIndex(need_item)

			local nHeroId = DataPool:LuaFnGetSkillCardActiveHeroId(g_CurrentSelSkill)
			if nHeroId > 0 then
				local strNpcName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nHeroId, "Name")
				local strNpcRealName = DataPool:LuaFnGetXingZhen_YingXiongInfo(nHeroId, "SceneName")
				local nSceneId, nPosX, nPosY = DataPool:LuaFnGetXingZhen_YingXiongInfo(nHeroId, "NpcSceneInfo")
				local strSceneName = GetSceneNameByID(nSceneId)
				
				local strTemp = ScriptGlobal_Format("#{XZJC_200309_353}", strItemName, strSceneName, tostring(nPosX), tostring(nPosY), tostring(nSceneId), strNpcRealName, strNpcName)
				
				Rune_Stars_Skill_SkillBtn2Text2:Show()
				Rune_Stars_Skill_SkillBtn2Text2:SetText(strTemp)
			end
		end
	end
end

function Rune_Stars_Skill_SetItem(idx, max_count)

	if g_BarList[idx] == nil then
		return
	end
	
	if idx > max_count then
		g_BarList[idx]:Hide()
		return
	end
	
	local bar = g_BarList[idx]
	bar:Show()
	
	local nSkillCardID = DataPool:LuaFnGetSkillCardID(idx - 1)	
	local nUnLocked = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "UnLocked")
	local nLevel = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Level")
	local nSlot = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Slot")
	local nQuality = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Quality")
	local strName = DataPool:LuaFnGetSkillCardInfo(nSkillCardID, "Name")
	
	local strNameColor = Rune_Stars_Skil_GetQualColor(nQuality)
	bar:GetSubItem("Rune_Stars_Skill_CoinAItemOptionName"):SetText(tostring("#L"..strName))
	
	--激活锁
	if nUnLocked == 1 then
		bar:GetSubItem("Rune_Stars_Skill_CoinAItemLock"):Hide()
		bar:GetSubItem("Rune_Stars_Skill_CoinAItemStepsBK"):Show()
		bar:GetSubItem("Rune_Stars_Skill_CoinAItemSteps"):SetText(tostring(nLevel))
		
		bar:GetSubItem("Rune_Stars_Skill_SkillUp"):Hide()
		
		if nLevel > 0 and nLevel < g_MaxCardLevel then
			local heroID, heroRelate = DataPool:LuaFnGetSkillCardLevelNeed(nSkillCardID, nLevel)
			if heroID > 0 then					
				local heroLevel = DataPool:LuaFnGetXingZhen_YingXiongHaoganLevel(heroID)
				if heroLevel >= heroRelate then
					bar:GetSubItem("Rune_Stars_Skill_SkillUp"):Show()
				end
			end			
		end
	else
		bar:GetSubItem("Rune_Stars_Skill_CoinAItemLock"):Show()
		bar:GetSubItem("Rune_Stars_Skill_CoinAItemStepsBK"):Hide()
		bar:GetSubItem("Rune_Stars_Skill_SkillUp"):Hide()
	end
	
	--上阵标识
	if nSlot > 0 then
		bar:GetSubItem("Rune_Stars_Skill_CoinAItemFight"):Show()
	else
		bar:GetSubItem("Rune_Stars_Skill_CoinAItemFight"):Hide()
	end	

	local ctrlAction = bar:GetSubItem("Rune_Stars_Skill_CoinAItemOption")
	if ctrlAction ~= nil then
		ctrlAction:SetActionItem(-1)
		
		local theAction = EnumAction(nSkillCardID,"skillcard")
		if theAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theAction:GetID())
		end
	
		ctrlAction:SetProperty("DraggingEnabled","False")
		
		if nSkillCardID == g_CurrentSelSkill then
			ctrlAction:SetPushed(1)
		else
			ctrlAction:SetPushed(0)
		end
	end
end

function Rune_Stars_Skill_ItemClicked(nIndex)
	
	local nSkillCardID = DataPool:LuaFnGetSkillCardID(nIndex - 1)
	if g_CurrentSelSkill == nSkillCardID then
		return
	end
	
	g_CurrentSelSkill = nSkillCardID
	
	for i = 1, g_MaxBarNum do		
		if g_BarList[i] ~= nil then	
			local ctrlAction = g_BarList[i]:GetSubItem("Rune_Stars_Skill_CoinAItemOption")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end			
		end
	end
	
	Rune_Stars_Skill_UpdateSel()
	
end

function Rune_Stars_Skill_DoOk()
	
	if g_CurrentSelSkill == 0 then
		PushDebugMessage("#{XZJC_200309_164}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SkillLevelUp")
		Set_XSCRIPT_ScriptID(888555)
		Set_XSCRIPT_Parameter(0, g_CurrentSelSkill)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Rune_Stars_Skill_DoCancel()
	Rune_Stars_Skill_OnCloseClicked()
end

function Rune_Stars_Skill_UnActive(nSlotIndex)
	PushDebugMessage(tostring(nSlotIndex))
end

function Rune_Stars_Skill_OnCloseClicked()
	this:Hide()
end

function Rune_Stars_Skill_OnHidden()
	Rune_Stars_Skill_ListCleanUpAction()	
end

function Rune_Stars_Skill_Elements_MouseLeave(nIndex)
	Lua_CloseFiveElementsTip(0 , nIndex)
end

function Rune_Stars_Skill_Elements_MouseEnter(nIndex)

end

function Rune_Stars_Skill_ListCleanUpAction()	
	for i = 1, g_MaxBarNum do
		if g_BarList[i] then			
			local ctrlAction = g_BarList[i]:GetSubItem("Rune_Stars_Skill_CoinAItemOption")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end	
	end
end

function Rune_Stars_Skill_OnSelectFilter()
	local _,nIndex = Rune_Stars_Skill_Bind:GetCurrentSelect()
	if g_CurrentFilter == nIndex then
		return
	end
	g_CurrentFilter = nIndex
	g_CurrentSelSkill = 0
	g_NeedChangeScrollSize = 1
	Variable:SetVariable("RuneStarPos", Rune_Stars_Skill_Frame:GetProperty("UnifiedPosition"), 1)
	Rune_Stars_Skill_Update()
end

--英雄
function Rune_Stars_Skill_FenYe_Switch(idx)
	--养成
	if idx == 1 then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Skill_Frame:GetProperty("UnifiedPosition"), 1)
		LuaFnOpenXingZhen(false, 0, 0)
	elseif idx == 2 then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Skill_Frame:GetProperty("UnifiedPosition"), 1)
		LuaFnOpenXingZhenUpgrade()
	elseif idx == 4 then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Skill_Frame:GetProperty("UnifiedPosition"), 1)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenXZ_Heroes") 		-- 脚本号
			Set_XSCRIPT_ScriptID(888052)					-- 脚本编号
			Set_XSCRIPT_ParamCount(0)						-- 参数个数
		Send_XSCRIPT()
	end

end

function Rune_Stars_Skill_Refresh_Page_Button()

	Rune_Stars_Skill_FenYe1:SetCheck(0)
	Rune_Stars_Skill_FenYe2:SetCheck(0)
	Rune_Stars_Skill_FenYe3:SetCheck(1)
	Rune_Stars_Skill_FenYe4:SetCheck(0)	
	
	local nLevel = Player:GetLevel()

end

function Rune_Stars_Skill_On_ResetPos()
	if g_Rune_Stars_Skill_UnifiedPosition ~= nil then
		Rune_Stars_Skill_Frame:SetProperty("UnifiedPosition", g_Rune_Stars_Skill_UnifiedPosition)
	end
end

function Rune_Stars_Skil_UpdateRedPoint()

	Rune_Stars_Skill_FenYe1_Buttontips:Hide()
	Rune_Stars_Skill_FenYe2_Buttontips:Hide()
	Rune_Stars_Skill_FenYe3_Buttontips:Hide()
	
	if DataPool:LuaFnHaveXingJuanToSlot() == 1 then
		--有星卷可以上阵
		Rune_Stars_Skill_FenYe1_Buttontips:Show()
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
			Rune_Stars_Skill_FenYe1_Buttontips:Show()
		elseif DataPool:LuaFnHaveNewXingJuan() == 1 then
			--有新的星卷
			Rune_Stars_Skill_FenYe1_Buttontips:Show()
		elseif DataPool:LuaFnHaveNewSkillCard() == 1 then
			--有新的技能
			Rune_Stars_Skill_FenYe1_Buttontips:Show()
		end
	end
	
	if DataPool:LuaFnHaveXingJuanToUpgrade() == 1 then
		--有星卷可以升阶
		Rune_Stars_Skill_FenYe2_Buttontips:Show()
	end
	
	if DataPool:LuaFnHaveXingJuanToUnLock() == 1 then	
		--有星卷可以激活
		Rune_Stars_Skill_FenYe2_Buttontips:Show()
	end
	
	--有技能可以升级
	if DataPool:LuaFnHaveSkillCardToLevelUp() == 1 then
		Rune_Stars_Skill_FenYe3_Buttontips:Show()	
	end
end

function Rune_Stars_Skill_ShowDetail()
	
	if g_CurrentSelSkill == 0 then
		return
	end
	
	LuaFnOpenSkillCardDetail(g_CurrentSelSkill)
end

function Rune_Stars_Skil_GetQualColor(nQual)

	if nQual == 1 then
		return "#G"
	elseif nQual == 2 then
		return "#B"
	elseif nQual == 3 then
		return "#cbe38ff"
	elseif nQual == 4 then
		return "#cfff965"
	end
	
	return ""
end


--!!!reloadscript =Rune_Stars
