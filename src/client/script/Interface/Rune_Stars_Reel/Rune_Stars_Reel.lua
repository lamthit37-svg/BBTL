--!!!reloadscript =Rune_Stars_Reel

local g_CurrentUIType = 0
local g_Rune_Stars_Reel_UnifiedPosition = ""
local g_MaxBarNum = 100

local g_BarListA = {}
local g_BarListB = {}

local g_CurrentFilterA = 0
local g_CurrentFilterB = 0
local g_CurrentFilterC = 0

local g_ListAInit = 0
local g_ListBInit = 0

local g_CurrentSelXingJuanID = 0
local g_CurrentSelChipID = 0
local g_MaxXingJuanLevel = 10
local g_MaxXingJuanOrder = 5

local g_LevelAttr = {}

local g_XingJuanOrderImg = {
	"set:Rune_Star01 image:Rune_Level01",
	"set:Rune_Star01 image:Rune_Level02",
	"set:Rune_Star01 image:Rune_Level03",
	"set:Rune_Star01 image:Rune_Level04",
	"set:Rune_Star01 image:Rune_Level05",
}

local g_TargetXingJuanID = 0
local g_NeedChangeScrollSize = 0

function Rune_Stars_Reel_PreLoad()

	this:RegisterEvent("OPEN_XINGZHEN_UPGRADE")	
	this:RegisterEvent("XINGZHEN_UPDATE",false)
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	--更新装备
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("XINGJUAN_STOREEXP",false)
	this:RegisterEvent("XINGJUAN_CHIPDRE",false)
	this:RegisterEvent("XINGJUAN_CHIPESS",false)

	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("XINGJUAN_STOREEXP",false)
	this:RegisterEvent("YINGXIONG_REDPOINT")
	this:RegisterEvent("CLOSE_XINGZHENUI_GROUP",false)
	
end

function Rune_Stars_Reel_OnLoad()
	
	g_Rune_Stars_Reel_UnifiedPosition = Rune_Stars_Reel_Frame:GetProperty("UnifiedPosition")	
	
	Rune_Stars_Reel_SkillBind:AddTextItem("#{XZJC_200309_72}" ,1)	--全部
	Rune_Stars_Reel_SkillBind:AddTextItem("#{XZJC_200309_73}" ,2)	--橙色
	Rune_Stars_Reel_SkillBind:AddTextItem("#{XZJC_200309_74}" ,3)	--紫色
	Rune_Stars_Reel_SkillBind:AddTextItem("#{XZJC_200309_75}" ,4)	--蓝色
	Rune_Stars_Reel_SkillBind:AddTextItem("#{XZJC_200309_76}" ,5)	--绿色
	
	Rune_Stars_Reel_PatchBind1:AddTextItem("#{XZJC_200309_69}" ,1)	--全部
	Rune_Stars_Reel_PatchBind1:AddTextItem("#{XZJC_200309_70}" ,2)	--激活
	Rune_Stars_Reel_PatchBind1:AddTextItem("#{XZJC_200309_71}" ,3)	--未激活
	
	Rune_Stars_Reel_PatchBind2:AddTextItem("#{XZJC_200309_72}" ,1)	--全部
	Rune_Stars_Reel_PatchBind2:AddTextItem("#{XZJC_200309_73}" ,2)	--橙色
	Rune_Stars_Reel_PatchBind2:AddTextItem("#{XZJC_200309_74}" ,3)	--紫色
	Rune_Stars_Reel_PatchBind2:AddTextItem("#{XZJC_200309_75}" ,4)	--蓝色
	Rune_Stars_Reel_PatchBind2:AddTextItem("#{XZJC_200309_76}" ,5)	--绿色	
	
	g_LevelAttr = {attr_name = {}, attr_text1 = {}, attr_text2 = {}, icon = {}}
	g_LevelAttr.attr_name[1] = Rune_Stars_Reelup_Text1
	g_LevelAttr.attr_name[2] = Rune_Stars_Reelup_Text2
	g_LevelAttr.attr_name[3] = Rune_Stars_Reelup_Text3
	g_LevelAttr.attr_name[4] = Rune_Stars_Reelup_Text4
	g_LevelAttr.attr_name[5] = Rune_Stars_Reelup_Text5
	g_LevelAttr.attr_name[6] = Rune_Stars_Reelup_Text6
	
	g_LevelAttr.attr_text1[1] = Rune_Stars_Reelup_Text01
	g_LevelAttr.attr_text1[2] = Rune_Stars_Reelup_Text02
	g_LevelAttr.attr_text1[3] = Rune_Stars_Reelup_Text03
	g_LevelAttr.attr_text1[4] = Rune_Stars_Reelup_Text04
	g_LevelAttr.attr_text1[5] = Rune_Stars_Reelup_Text05
	g_LevelAttr.attr_text1[6] = Rune_Stars_Reelup_Text06
	
	g_LevelAttr.attr_text2[1] = Rune_Stars_Reelup_Text001
	g_LevelAttr.attr_text2[2] = Rune_Stars_Reelup_Text002
	g_LevelAttr.attr_text2[3] = Rune_Stars_Reelup_Text003
	g_LevelAttr.attr_text2[4] = Rune_Stars_Reelup_Text004
	g_LevelAttr.attr_text2[5] = Rune_Stars_Reelup_Text005
	g_LevelAttr.attr_text2[6] = Rune_Stars_Reelup_Text006
	
	g_LevelAttr.icon[1] = Rune_Stars_Reelup_Up1
	g_LevelAttr.icon[2] = Rune_Stars_Reelup_Up2
	g_LevelAttr.icon[3] = Rune_Stars_Reelup_Up3
	g_LevelAttr.icon[4] = Rune_Stars_Reelup_Up4
	g_LevelAttr.icon[5] = Rune_Stars_Reelup_Up5
	g_LevelAttr.icon[6] = Rune_Stars_Reelup_Up6
	
	Rune_Stars_Reelup_DemandMoney:SetProperty("MoneyColor", "ff6a3906")
	Rune_Stars_Reelup_SelfJiaozi:SetProperty("MoneyColor", "ff6a3906")
	Rune_Stars_Reelup_SelfMoney:SetProperty("MoneyColor", "ff6a3906")
	
	Rune_Stars_Reelup_DemandMoney2:SetProperty("MoneyColor", "ff6a3906")
	Rune_Stars_Reelup_SelfJiaozi2:SetProperty("MoneyColor", "ff6a3906")
	Rune_Stars_Reelup_SelfMoney2:SetProperty("MoneyColor", "ff6a3906")
end

function Rune_Stars_Reel_OnEvent(event)

	if event == "OPEN_XINGZHEN_UPGRADE" then
		local selfUnionPos = Variable:GetVariable("RuneStarPos")
		if selfUnionPos ~= nil then
			Rune_Stars_Reel_Frame:SetProperty("UnifiedPosition", selfUnionPos)
		end
		this:Show()
		g_CurrentFilterA = 1
		g_CurrentFilterB = 1
		g_CurrentFilterC = 1
		g_CurrentUIType = 1
		g_CurrentSelXingJuanID = 0
		g_CurrentSelChipID = 0
		g_NeedChangeScrollSize = 1
		Rune_Stars_Reel_SkillBind:SetText("#{XZJC_200309_72}")
		Rune_Stars_Reel_PatchBind1:SetText("#{XZJC_200309_69}")
		Rune_Stars_Reel_PatchBind2:SetText("#{XZJC_200309_72}")
		Rune_Stars_Reel_Update()
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
		if arg1 == "unlock" then
			g_TargetXingJuanID = tonumber(arg0)
		end
		
		if arg1 == "levelup" then
		
		end
		
		if arg1 == "orderup" then
			local nOrder = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelXingJuanID, "Order")
			if nOrder == g_MaxXingJuanOrder then
				g_CurrentSelXingJuanID = 0
			end
		end
		
		Rune_Stars_Reel_Update()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Rune_Stars_Reel_On_ResetPos()
	end
	
	if event == "MONEY_CHANGE_EX" and this:IsVisible()  then
		Rune_Stars_Reelup_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		Rune_Stars_Reelup_SelfMoney2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		if g_CurrentUIType == 1 then
			Rune_Stars_Reel_Update()
		end
		return
	end
	
	if event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		Rune_Stars_Reelup_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		Rune_Stars_Reelup_SelfJiaozi2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		if g_CurrentUIType == 1 then
			Rune_Stars_Reel_Update()		
		end
		return
	end
	
	if event == "XINGJUAN_STOREEXP" then
		if g_CurrentUIType == 1 then
			Rune_Stars_Reel_Update_LevelUpDetail()
		end
	end
	
	if event == "YINGXIONG_REDPOINT" then
		if tonumber(arg0)==1 or tonumber(arg1)==1 or tonumber(arg2) == 1 then 
			Rune_Stars_Reel_FenYe4_Buttontips:Show()
		else
			Rune_Stars_Reel_FenYe4_Buttontips:Hide()
		end
	end
end

function Rune_Stars_Reel_InitListBar()
	if g_ListAInit ~= 1 then
		g_MaxBarNum = DataPool:LuaFnGetXingJuanMaxCount()
		for i = 1, g_MaxBarNum do
			local bar = Rune_Stars_Reel_SkillLace:AddChild("Rune_Stars_Reel_SkillCoinAItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			bar:GetSubItem("Rune_Stars_Reel_SkillCoinAItemOption"):SetEvent("MouseLButtonDown", string.format("Rune_Stars_Reel_ItemClicked_A(%d)", i))
			g_BarListA[i] = bar
		end
		g_ListAInit = 1
	end
	
	if g_ListBInit ~= 1 then
		g_MaxBarNum = DataPool:LuaFnGetXingJuanMaxCount()
		for i = 1, g_MaxBarNum do
			local bar = Rune_Stars_Reel_PatchLace:AddChild("Rune_Stars_Reel_PatchCoinAItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			bar:GetSubItem("Rune_Stars_Reel_PatchCoinAItemOption"):SetEvent("MouseLButtonDown", string.format("Rune_Stars_Reel_ItemClicked_B(%d)", i))
			g_BarListB[i] = bar
		end
		g_ListBInit = 1
	end
end

--刷新
function Rune_Stars_Reel_Update()	
	
	Rune_Stars_Reel_Refresh_Page_Button()
	Rune_Stars_Reel_UpdateRedPoint()
	Rune_Stars_Reel_InitListBar()
	
	if g_CurrentUIType == 1 then
		Rune_Stars_Reel_Update_LevelUp()		
		return 
	elseif g_CurrentUIType == 2 then
		Rune_Stars_Reel_Update_Chip()
		return
	end
end

function Rune_Stars_Reel_Update_LevelUp()

	Rune_Stars_ReelUp:Show()
	Rune_Stars_ReelPatch:Hide()
	
	Rune_Stars_Reel_Skill:Show()
	Rune_Stars_Reel_Patch:Hide()
	
	DataPool:LuaFnInitXingJuanList(0, 1, g_CurrentFilterA)
	local nCount = DataPool:LuaFnGetXingJuanListCount()	
	
	for i = 1, g_MaxBarNum do
		Rune_Stars_Reel_SetItemA(i, nCount)
	end
	
	if g_NeedChangeScrollSize == 1 then		
		Rune_Stars_Reel_SkillLace:RefreshLayout()
		Rune_Stars_Reel_SkillLace:SetScrollPosition(0)
		g_NeedChangeScrollSize = 0
	end
	
	Rune_Stars_Reel_Update_LevelUpDetail()
	
end

function Rune_Stars_Reel_Update_LevelUpDetail()
	
	for i = 1, 6 do
		g_LevelAttr.attr_name[i]:SetText("")
		g_LevelAttr.attr_text1[i]:SetText("")
		g_LevelAttr.attr_text2[i]:SetText("")
		g_LevelAttr.icon[i]:Hide()
	end
		
	Rune_Stars_ReelupLevelupNeed2:SetText("")
		
	if g_CurrentSelXingJuanID == 0 then
	
		Rune_Stars_ReelupBtn:SetActionItem(-1)
		Rune_Stars_ReelupBtnRank:Hide()
		Rune_Stars_ReelupBtnFight:Hide()
		
		Rune_Stars_ReelupLevelupInfo:Show()
		Rune_Stars_ReelupDanupInfo:Hide()
		
		Rune_Stars_ReelupJianTou:Hide()
		Rune_Stars_ReelupTitle1:SetText("")
		Rune_Stars_ReelupTitle2:SetText("")
		
		local have_exp = Player:GetData("XJSTOREEXP")
		Rune_Stars_ReelupLevelupNow2:SetText("#L"..tostring(have_exp))
		
		Rune_Stars_SkillName:SetText("")
	else
		
		local nUnLocked = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelXingJuanID, "UnLocked")
		local nLevel = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelXingJuanID, "Level")
		local nSlot = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelXingJuanID, "Slot")
		local nOrder = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelXingJuanID, "Order")
		local nChipCount = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelXingJuanID, "ChipCount")
		local nQuality = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelXingJuanID, "Quality")
		local strName = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelXingJuanID, "Name")
		local strNameColor = Rune_Stars_Reel_GetQualColor(nQuality)
		
		Rune_Stars_SkillName:SetText("#L"..strName)
		Rune_Stars_ReelupJianTou:Show()
		
		if nOrder > 0 then
			Rune_Stars_ReelupBtnRank:Show()
			Rune_Stars_ReelupBtnRank:SetProperty("Image",g_XingJuanOrderImg[nOrder])
		else
			Rune_Stars_ReelupBtnRank:Hide()
		end

		--上阵标识
		if nSlot > 0 then
			Rune_Stars_ReelupBtnFight:Show()
		else
			Rune_Stars_ReelupBtnFight:Hide()
		end

		Rune_Stars_ReelupBtn:SetActionItem(-1)

		local theAction = EnumAction(g_CurrentSelXingJuanID,"xingjuan")
		if theAction:GetID() ~= 0 then
			Rune_Stars_ReelupBtn:SetActionItem(theAction:GetID())
		end
		Rune_Stars_ReelupBtn:SetProperty("DraggingEnabled","False")

		if nUnLocked == 1 then
			if nOrder ~= g_MaxXingJuanOrder then
				local strTemp = ScriptGlobal_Format("#{XZJC_200309_224}", tostring(nOrder), tostring(nLevel))
			Rune_Stars_ReelupTitle1:SetText(strTemp)
			else
				Rune_Stars_ReelupTitle1:SetText("#{XZJC_200309_229}")
			end
		else
			Rune_Stars_ReelupTitle1:SetText("#{XZJC_200309_343}")
		end
		
		if nOrder ~= g_MaxXingJuanOrder then
			if nLevel == g_MaxXingJuanLevel then
				if nOrder == g_MaxXingJuanOrder - 1 then					
					Rune_Stars_ReelupTitle2:SetText("#{XZJC_200309_229}")
				else
					local strTemp = ScriptGlobal_Format("#{XZJC_200309_224}", tostring(nOrder + 1), "0")
					Rune_Stars_ReelupTitle2:SetText(strTemp)
				end
			else
				local strTemp = ScriptGlobal_Format("#{XZJC_200309_224}", tostring(nOrder),tostring(nLevel + 1))
				Rune_Stars_ReelupTitle2:SetText(strTemp)
			end
		else
			Rune_Stars_ReelupTitle2:SetText("#{XZJC_200309_230}")
		end

		local ctrl_index = 1
		
		for i = 1, 6 do
			
			local strAttr = ""
			local attr_value = ""
			local attr_value_next = ""
			
			if nUnLocked == 1 then
				if i <= 3 then
					strAttr, attr_value = DataPool:LuaFnGetXingJuanSlotAttr(g_CurrentSelXingJuanID, nOrder, nLevel, i - 1)
				else
					strAttr, attr_value = DataPool:LuaFnGetXingJuanAttr(g_CurrentSelXingJuanID, nOrder, nLevel, i - 4)
				end
			else
				if i <= 3 then
					strAttr, attr_value = DataPool:LuaFnGetXingJuanSlotAttr(g_CurrentSelXingJuanID, 0, 1, i - 1)
				else
					strAttr, attr_value = DataPool:LuaFnGetXingJuanAttr(g_CurrentSelXingJuanID, 0, 1, i - 4)
				end
				
				attr_value = "0"
			end
			
			if strAttr ~= "" then
				
				if i <= 3 then
					g_LevelAttr.attr_name[ctrl_index]:SetText("#L"..strAttr)
				else
					g_LevelAttr.attr_name[ctrl_index]:SetText("#L"..strAttr)
					g_LevelAttr.icon[ctrl_index]:Show()
				end
				
				g_LevelAttr.attr_text1[ctrl_index]:SetText("#L"..attr_value)
			
				if nOrder ~= g_MaxXingJuanOrder then
					if nLevel == 10 then
						if i <= 3 then
							strAttr, attr_value_next = DataPool:LuaFnGetXingJuanSlotAttr(g_CurrentSelXingJuanID, nOrder + 1, 0, i - 1)
						else
							strAttr, attr_value_next = DataPool:LuaFnGetXingJuanAttr(g_CurrentSelXingJuanID, nOrder + 1, 0, i - 4)
						end
					
						if attr_value_next == attr_value then
							g_LevelAttr.attr_text2[ctrl_index]:SetText("#L"..attr_value_next)
						else
							g_LevelAttr.attr_text2[ctrl_index]:SetText("#M"..attr_value_next)
						end
					else
						if i <= 3 then
							strAttr, attr_value_next = DataPool:LuaFnGetXingJuanSlotAttr(g_CurrentSelXingJuanID, nOrder, nLevel + 1, i - 1)
						else
							strAttr, attr_value_next = DataPool:LuaFnGetXingJuanAttr(g_CurrentSelXingJuanID, nOrder, nLevel + 1, i - 4)
						end
					
						if attr_value_next == attr_value then
							g_LevelAttr.attr_text2[ctrl_index]:SetText("#L"..attr_value_next)
						else
							g_LevelAttr.attr_text2[ctrl_index]:SetText("#M"..attr_value_next)
						end
					end
				else
				--	g_LevelAttr.attr_text2[ctrl_index]:SetText("#L"..attr_value)
				end
				
				ctrl_index = ctrl_index + 1
			end
		end
		
		if nLevel == 10 then
			
			Rune_Stars_ReelupLevelupInfo:Hide()
			Rune_Stars_ReelupDanupInfo:Show()
			
			local need_chip, need_money = DataPool:LuaFnGetXingJuanOrderNeed(g_CurrentSelXingJuanID, nOrder + 1)			
			
			Rune_Stars_ReelupDanUpBtn:SetActionItem(-1)
			local theAction = EnumAction(g_CurrentSelXingJuanID,"xingjuanchip")
			if theAction:GetID() ~= 0 then
				Rune_Stars_ReelupDanUpBtn:SetActionItem(theAction:GetID())
			end
			
			if nChipCount >= need_chip then
				local strTemp = ScriptGlobal_Format("#{XZJC_200309_32}",tostring(nChipCount), tostring(need_chip))
				Rune_Stars_ReelupDanUpBtn_Text:SetText(strTemp)
			else
				local strTemp = ScriptGlobal_Format("#{XZJC_200309_56}",tostring(nChipCount), tostring(need_chip))
				Rune_Stars_ReelupDanUpBtn_Text:SetText(strTemp)
			end
			
			Rune_Stars_Reelup_DemandMoney2:SetProperty("MoneyNumber", tostring(need_money))
			Rune_Stars_Reelup_SelfJiaozi2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
			Rune_Stars_Reelup_SelfMoney2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
			
		else
		
			Rune_Stars_ReelupLevelupInfo:Show()
			Rune_Stars_ReelupDanupInfo:Hide()
			
			local need_exp, need_money = DataPool:LuaFnGetXingJuanLevelNeed(g_CurrentSelXingJuanID, nOrder, nLevel)
			local have_exp = Player:GetData("XJSTOREEXP")
			
			if need_exp > 0 then
				if have_exp >= need_exp then
					Rune_Stars_ReelupLevelupNeed2:SetText("#M"..tostring(need_exp))
				else
					Rune_Stars_ReelupLevelupNeed2:SetText("#cff0000"..tostring(need_exp))
				end
			end
			
			Rune_Stars_ReelupLevelupNow2:SetText("#L"..tostring(have_exp))
			
			Rune_Stars_Reelup_DemandMoney:SetProperty("MoneyNumber", tostring(need_money))
			Rune_Stars_Reelup_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
			Rune_Stars_Reelup_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		end
	end
end

function Rune_Stars_Reel_Update_Chip()

	Rune_Stars_ReelUp:Hide()
	Rune_Stars_ReelPatch:Show()
	
	Rune_Stars_Reel_Skill:Hide()
	Rune_Stars_Reel_Patch:Show()	
	
	local nOldCount = DataPool:LuaFnGetXingJuanListCount()	
	DataPool:LuaFnInitXingJuanList(1, g_CurrentFilterB, g_CurrentFilterC)
	local nCount = DataPool:LuaFnGetXingJuanListCount()	
	
	for i = 1, g_MaxBarNum do
		Rune_Stars_Reel_SetItemB(i, nCount)
	end
	
	if g_NeedChangeScrollSize == 1 then		
		Rune_Stars_Reel_PatchLace:RefreshLayout()
		Rune_Stars_Reel_PatchLace:SetScrollPosition(0)
		g_NeedChangeScrollSize = 0
	elseif nCount ~= nOldCount then
		Rune_Stars_Reel_PatchLace:RefreshLayout()
	end
	
	if g_TargetXingJuanID == 0 then
		Rune_Stars_Reel_Update_ChipDetail()
	elseif g_TargetXingJuanID == g_CurrentSelChipID then
		local strName = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelChipID, "Name")
		local strTemp = ScriptGlobal_Format("#{XZJC_200309_109}",tostring(strName))
		Rune_Stars_Reelup_Patch_Tips:SetText(strTemp)
		Rune_Stars_Reelup_Patch_Tips:Show()
		Rune_Stars_Reel_Go:Show()
		Rune_Stars_ReelPatchSyn:Hide()
		Rune_Stars_ReelPatchSam:Hide()
		Rune_Stars_ReelBatchSplit:Hide()
	end
	g_TargetXingJuanID = 0
end

function Rune_Stars_Reel_Update_ChipDetail()

	Rune_Stars_Reelup_Patch_Tips:Hide()
	Rune_Stars_Reel_Go:Hide()
	Rune_Stars_ReelPatchSyn:Show()
	Rune_Stars_ReelPatchSam:Show()
	Rune_Stars_ReelBatchSplit:Show()
	
	if g_CurrentSelChipID == 0 then
		Rune_Stars_ReelPatchItem:SetActionItem(-1)
		Rune_Stars_ReelPatchItemName:SetText("")
	else
		Rune_Stars_ReelPatchItem:SetActionItem(-1)		
		local theAction = EnumAction(g_CurrentSelChipID,"xingjuanchip")
		if theAction:GetID() ~= 0 then
			Rune_Stars_ReelPatchItem:SetActionItem(theAction:GetID())
		end	
		Rune_Stars_ReelPatchItem:SetProperty("DraggingEnabled","False")

		local nQuality = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelChipID, "Quality")
		local strName = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelChipID, "Name")
		local strNameColor = Rune_Stars_Reel_GetQualColor(nQuality)
		
		Rune_Stars_ReelPatchItemName:SetText("#L"..strName)
	end	
end

function Rune_Stars_Reel_SetItemA(idx, max_count)

	local nXingJuanID = DataPool:LuaFnGetXingJuanID(idx - 1)
	local bar = g_BarListA[idx]
	
	if g_BarListA[idx] == nil then
		return
	end	
	
	if idx > max_count then
		g_BarListA[idx]:Hide()
		return
	end
	
	local bar = g_BarListA[idx]
	bar:Show()	
	
	local nUnLocked = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "UnLocked")
	local nLevel = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Level")
	local nSlot = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Slot")
	local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
	local nChipCount = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "ChipCount")
	local nQuality = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Quality")
	local strName = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Name")
	local strNameColor = Rune_Stars_Reel_GetQualColor(nQuality)
	
	bar:GetSubItem("Rune_Stars_Reel_SkillCoinAItemOptionName"):SetText(tostring("#L"..strName))
	
	--激活锁
	if nUnLocked == 1 then
		bar:GetSubItem("Rune_Stars_Reel_SkillLock"):Hide()
		if nOrder > 0 then
		bar:GetSubItem("Rune_Stars_Reelup_SkillRank"):Show()
			bar:GetSubItem("Rune_Stars_Reelup_SkillRank"):SetProperty("Image",g_XingJuanOrderImg[nOrder])
		else
			bar:GetSubItem("Rune_Stars_Reelup_SkillRank"):Hide()
		end
	else
		bar:GetSubItem("Rune_Stars_Reel_SkillLock"):Show()
		bar:GetSubItem("Rune_Stars_Reelup_SkillRank"):Hide()		
	end
	
	--上阵标识
	if nSlot > 0 then
		bar:GetSubItem("Rune_Stars_Reel_SkillFight"):Show()
	else
		bar:GetSubItem("Rune_Stars_Reel_SkillFight"):Hide()
	end	

	local ctrlAction = bar:GetSubItem("Rune_Stars_Reel_SkillCoinAItemOption")
	if ctrlAction ~= nil then
		ctrlAction:SetActionItem(-1)
		
		local theAction = EnumAction(nXingJuanID,"xingjuan")
		if theAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theAction:GetID())
		end
	
		ctrlAction:SetProperty("DraggingEnabled","False")
		
		if nXingJuanID == g_CurrentSelXingJuanID then
			ctrlAction:SetPushed(1)
		else
			ctrlAction:SetPushed(0)
		end
	end
	
	bar:GetSubItem("Rune_Stars_Reel_SkillUp"):Hide()
	
	if nUnLocked == 1 then
		if nOrder < g_MaxXingJuanOrder then
			--local have_money = Player:GetData("MONEY_JZ") + Player:GetData("MONEY")
			if nLevel == g_MaxXingJuanLevel then
				local need_chip, need_money = DataPool:LuaFnGetXingJuanOrderNeed(nXingJuanID, nOrder + 1)			
				if nChipCount >= need_chip	then --and have_money >= need_money then
					bar:GetSubItem("Rune_Stars_Reel_SkillUp"):Show()
				end
			end
		end
	end
end

function Rune_Stars_Reel_SetItemB(idx, max_count)

	local nXingJuanID = DataPool:LuaFnGetXingJuanID(idx - 1)
	local bar = g_BarListB[idx]
	
	if g_BarListB[idx] == nil then
		return
	end	
	
	if idx > max_count then
		g_BarListB[idx]:Hide()
		return
	end
	
	local bar = g_BarListB[idx]
	bar:Show()	
	
	local nUnLocked = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "UnLocked")
	local nLevel = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Level")
	local nSlot = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Slot")
	local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
	local nChipCount = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "ChipCount")
	local nActiveNeedChipCount = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "ActiveNeedChipCount")
	local nQuality = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Quality")
	local strName = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Name")
	local strNameColor = Rune_Stars_Reel_GetQualColor(nQuality)
	bar:GetSubItem("Rune_Stars_Reel_PatchCoinAItemOptionName"):SetText(tostring("#L"..strName.."#{XZJC_200309_276}"))
	
	bar:GetSubItem("Rune_Stars_Reel_PatchCoinAItemOptiontips"):Hide()
	
	--激活锁
	if nUnLocked == 1 then
		bar:GetSubItem("Rune_Stars_Reel_PatchLock"):Hide()
		bar:GetSubItem("Rune_Stars_Reelup_PatchRank"):SetText("#e010101"..tostring(nChipCount))
	else
		bar:GetSubItem("Rune_Stars_Reel_PatchLock"):Show()
		bar:GetSubItem("Rune_Stars_Reelup_PatchRank"):SetText(tostring(nChipCount).."/"..tostring(nActiveNeedChipCount))

		if nChipCount >= nActiveNeedChipCount then
			bar:GetSubItem("Rune_Stars_Reel_PatchCoinAItemOptiontips"):Show()
			
			local strTemp = ScriptGlobal_Format("#{XZJC_200309_32}",tostring(nChipCount), tostring(nActiveNeedChipCount))
			bar:GetSubItem("Rune_Stars_Reelup_PatchRank"):SetText(strTemp)
		else
			local strTemp = ScriptGlobal_Format("#{XZJC_200309_56}",tostring(nChipCount), tostring(nActiveNeedChipCount))
			bar:GetSubItem("Rune_Stars_Reelup_PatchRank"):SetText(strTemp)			
		end
	end
	
	--上阵标识
	if nSlot > 0 then
	--	bar:GetSubItem("Rune_Stars_Reel_SkillFight"):Show()
	else
	--	bar:GetSubItem("Rune_Stars_Reel_SkillFight"):Hide()
	end	

	local ctrlAction = bar:GetSubItem("Rune_Stars_Reel_PatchCoinAItemOption")
	if ctrlAction ~= nil then
		ctrlAction:SetActionItem(-1)		
		local theAction = EnumAction(nXingJuanID,"xingjuanchip")
		if theAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theAction:GetID())
		end	
		ctrlAction:SetProperty("DraggingEnabled","False")
		
		if g_CurrentSelChipID == nXingJuanID then
			ctrlAction:SetPushed(1)
		else
			ctrlAction:SetPushed(0)
		end		
	end
end

function Rune_Stars_Reel_ItemClicked_A(nIndex)
	
	local nXingJuanID = DataPool:LuaFnGetXingJuanID(nIndex - 1)
	if g_CurrentSelXingJuanID == nXingJuanID then
		return
	end
	
	local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
	if nnOrder == g_MaxXingJuanOrder then
		return
	end

	g_CurrentSelXingJuanID = nXingJuanID

	for i = 1, g_MaxBarNum do		
		if g_BarListA[i] ~= nil then	
			local ctrlAction = g_BarListA[i]:GetSubItem("Rune_Stars_Reel_SkillCoinAItemOption")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end			
		end
	end
	
	Rune_Stars_Reel_Update_LevelUpDetail()

end

function Rune_Stars_Reel_ItemClicked_B(nIndex)
	
	local nXingJuanID = DataPool:LuaFnGetXingJuanID(nIndex - 1)
	if g_CurrentSelChipID == nXingJuanID then
		return
	end
	
	g_CurrentSelChipID = nXingJuanID
	
	for i = 1, g_MaxBarNum do
		
		if g_BarListB[i] ~= nil then
	
			local ctrlAction = g_BarListB[i]:GetSubItem("Rune_Stars_Reel_PatchCoinAItemOption")
			if ctrlAction ~= nil then
				if i == nIndex then
					ctrlAction:SetPushed(1)
				else
					ctrlAction:SetPushed(0)	
				end
			end			
		end
	end
	
	Rune_Stars_Reel_Update_ChipDetail()

end

function Rune_Stars_Reel_Unlock()
	
	if g_CurrentSelChipID == 0 then
		PushDebugMessage("#{XZJC_200309_113}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ActiveXingJuan")
		Set_XSCRIPT_ScriptID(888555)
		Set_XSCRIPT_Parameter(0, g_CurrentSelChipID)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Rune_Stars_Reel_Melt()

	if g_CurrentSelChipID == 0 then
		PushDebugMessage("#{XZJC_200309_163}")
		return
	end
	
	--local nUnLocked = DataPool:LuaFnGetXingJuanInfo(g_CurrentSelChipID, "UnLocked")
	--if nUnLocked ~= 1 then
	--	PushDebugMessage("#{XZJC_200309_158}")
	--	return
	--end
	
	if nChipCount == 0 then
		PushDebugMessage("#{XZJC_200309_159}")
		return
	end
	
	LuaFnOpenXingZhenChip(g_CurrentSelChipID)
end

function Rune_Stars_Reel_LevelUp()
	
	if g_CurrentSelXingJuanID == 0 then
		PushDebugMessage("#{XZJC_200309_123}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("XingJuanLevelUp")
		Set_XSCRIPT_ScriptID(888555)
		Set_XSCRIPT_Parameter(0, g_CurrentSelXingJuanID)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function Rune_Stars_Reel_LevelUp_Cancel()
	Rune_Stars_Reel_OnCloseClicked()
end

function Rune_Stars_Reel_Upgrade()
	
	if g_CurrentSelXingJuanID == 0 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("XingJuanLevelUp")
		Set_XSCRIPT_ScriptID(888555)
		Set_XSCRIPT_Parameter(0, g_CurrentSelXingJuanID)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function Rune_Stars_Reel_Upgrade_Cancel()
	Rune_Stars_Reel_OnCloseClicked()
end

function Rune_Stars_Reel_GoView()

	if g_CurrentSelChipID == 0 then
		return
	end
	
	Variable:SetVariable("RuneStarPos", Rune_Stars_Reel_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenXingZhen(true, g_CurrentSelChipID, 0)
end

function Rune_Stars_Reel_OnCloseClicked()
	this:Hide()
end

function Rune_Stars_Reel_OnHidden()
	Rune_Stars_Reel_ListCleanUpAction()
	Rune_Stars_ReelupBtn:SetActionItem(-1)
	Rune_Stars_ReelupDanUpBtn:SetActionItem(-1)
	Rune_Stars_ReelPatchItem:SetActionItem(-1)	
	Rune_Stars_Reelup_DemandMoney:SetProperty("MoneyNumber", "0")
	Rune_Stars_Reelup_DemandMoney2:SetProperty("MoneyNumber", "0")
	
	if IsWindowShow("Rune_Stars_Piece") then
		CloseWindow("Rune_Stars_Piece", true)
	end

	if IsWindowShow("Rune_Stars_BatchSplit") then
		CloseWindow("Rune_Stars_BatchSplit", true)
	end
end

function Rune_Stars_Reel_ListCleanUpAction()	
	for i = 1, g_MaxBarNum do
		if g_BarListA[i] then			
			local ctrlAction = g_BarListA[i]:GetSubItem("Rune_Stars_Reel_SkillCoinAItemOption")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end			
		if g_BarListB[i] then			
			local ctrlAction = g_BarListB[i]:GetSubItem("Rune_Stars_Reel_PatchCoinAItemOption")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
	end
end

function Rune_Stars_Reel_OnSelectFilterA()
	local _,nIndex = Rune_Stars_Reel_SkillBind:GetCurrentSelect()
	if g_CurrentFilterA == nIndex then
		return
	end
	g_CurrentFilterA = nIndex
	g_CurrentSelXingJuanID = 0
	g_NeedChangeScrollSize = 1
	Rune_Stars_Reel_Update_LevelUp()
end

function Rune_Stars_Reel_OnSelectFilterB()

	local _,nIndex = Rune_Stars_Reel_PatchBind1:GetCurrentSelect()
	if g_CurrentFilterB == nIndex then
		return
	end
	g_CurrentFilterB = nIndex
	g_CurrentSelChipID = 0
	g_NeedChangeScrollSize = 1
	Rune_Stars_Reel_Update_Chip()
end

function Rune_Stars_Reel_OnSelectFilterC()

	local _,nIndex = Rune_Stars_Reel_PatchBind2:GetCurrentSelect()
	if g_CurrentFilterC == nIndex then
		return
	end
	g_CurrentFilterC = nIndex
	g_CurrentSelChipID = 0
	g_NeedChangeScrollSize = 1
	Rune_Stars_Reel_Update_Chip()
end

function Rune_Stars_Reel_FenYe_Switch(idx)
	--星阵
	if idx == 1 then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Reel_Frame:GetProperty("UnifiedPosition"), 1)
		LuaFnOpenXingZhen(false, 0, 0)
	--技能
	elseif idx == 3 then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Reel_Frame:GetProperty("UnifiedPosition"), 1)
		LuaFnOpenXingZhenSkill()	
	--英雄
	elseif idx == 4 then
		Variable:SetVariable("RuneStarPos", Rune_Stars_Reel_Frame:GetProperty("UnifiedPosition"), 1)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenXZ_Heroes") 		-- 脚本号
			Set_XSCRIPT_ScriptID(888052)					-- 脚本编号
			Set_XSCRIPT_ParamCount(0)						-- 参数个数
		Send_XSCRIPT()		
	end
end

function Rune_Stars_Reel_SubFenYe_Switch(idx)	
	if g_CurrentUIType == idx then
		return
	end	
	g_CurrentUIType = idx
	g_CurrentSelChipID = 0
	g_CurrentSelXingJuanID = 0
	g_NeedChangeScrollSize = 1
	Rune_Stars_Reel_Update()
	
	if IsWindowShow("Rune_Stars_Piece") then
		CloseWindow("Rune_Stars_Piece", true)
	end
end

function Rune_Stars_Reel_Refresh_Page_Button()

	Rune_Stars_Reel_FenYe1:SetCheck(0)
	Rune_Stars_Reel_FenYe2:SetCheck(1)
	Rune_Stars_Reel_FenYe3:SetCheck(0)
	Rune_Stars_Reel_FenYe4:SetCheck(0)	
	
	if g_CurrentUIType == 1 then	
		Rune_Stars_Reel_List1FenYe1:SetCheck(1)
		Rune_Stars_Reel_List1FenYe2:SetCheck(0)
	elseif g_CurrentUIType == 2 then
		Rune_Stars_Reel_List1FenYe1:SetCheck(0)
		Rune_Stars_Reel_List1FenYe2:SetCheck(1)
	end
	
	local nLevel = Player:GetLevel()
end

function Rune_Stars_Reel_On_ResetPos()
	if g_Rune_Stars_Reel_UnifiedPosition ~= nil then
		Rune_Stars_Reel_Frame:SetProperty("UnifiedPosition", g_Rune_Stars_Reel_UnifiedPosition)
	end
end

function Rune_Stars_Reel_UpdateRedPoint()

	Rune_Stars_Reel_FenYe1_Buttontips:Hide()
	Rune_Stars_Reel_FenYe2_Buttontips:Hide()
	Rune_Stars_Reel_FenYe3_Buttontips:Hide()

	Rune_Stars_Reel_List1FenYe1tips:Hide()
	Rune_Stars_Reel_List2FenYe1tips:Hide()
	
	if DataPool:LuaFnHaveXingJuanToSlot() == 1 then
		--有星卷可以上阵
		Rune_Stars_Reel_FenYe1_Buttontips:Show()
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
			Rune_Stars_Reel_FenYe1_Buttontips:Show()
		elseif DataPool:LuaFnHaveNewXingJuan() == 1 then
			--有新的星卷
			Rune_Stars_Reel_FenYe1_Buttontips:Show()
		elseif DataPool:LuaFnHaveNewSkillCard() == 1 then
			--有新的技能
			Rune_Stars_Reel_FenYe1_Buttontips:Show()
		end
	end
	
	if DataPool:LuaFnHaveXingJuanToUpgrade() == 1 then
		--有星卷可以升阶
		Rune_Stars_Reel_FenYe2_Buttontips:Show()
		Rune_Stars_Reel_List1FenYe1tips:Show()
	end
	
	if DataPool:LuaFnHaveXingJuanToUnLock() == 1 then	
		--有星卷可以激活
		Rune_Stars_Reel_FenYe2_Buttontips:Show()
		Rune_Stars_Reel_List2FenYe1tips:Show()
	end
	
	--有技能可以升级
	if DataPool:LuaFnHaveSkillCardToLevelUp() == 1 then
		Rune_Stars_Reel_FenYe3_Buttontips:Show()	
	end
end

function Rune_Stars_Reel_GetQualColor(nQual)

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

-- 分解所有满级的残印
function Rune_Stars_Reel_BatchSplit()
	-- PushDebugMessage("Rune_Stars_Reel_BatchSplit")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskOpenMeltAllFullChipUI" )
		Set_XSCRIPT_ScriptID(888555)							
		-- Set_XSCRIPT_Parameter(0, 0)								
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--!!!reloadscript =Rune_Stars
