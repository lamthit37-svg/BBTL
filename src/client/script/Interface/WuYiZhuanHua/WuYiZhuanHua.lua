local g_WuYiZhuanHua_Frame_UnifiedPosition

local g_WuYiZhuanHua_RemoveCheck = {}
local g_WuYiZhuanHua_RemoveText = {}
local g_WuYiZhuanHua_AddCheck = {}
local g_WuYiZhuanHua_AddText = {}

local g_WuYiZhuanHua_LeftSel = 0
local g_WuYiZhuanHua_RightSel = 0

local g_WuYiZhuanHua_ItemId = 38006722

local g_WuYiZhuanHua_AttrText = {
	[1] = {def="#{WYZH_240125_09}", decrease="#{WYZH_240125_10}", increase="#{WYZH_240125_11}"},--血上限
	[2] = {def="#{WYZH_240125_12}", decrease="#{WYZH_240125_13}", increase="#{WYZH_240125_14}"},--冰攻击
	[3] = {def="#{WYZH_240125_15}", decrease="#{WYZH_240125_16}", increase="#{WYZH_240125_17}"},--火攻击
	[4] = {def="#{WYZH_240125_18}", decrease="#{WYZH_240125_19}", increase="#{WYZH_240125_20}"},--玄攻击
	[5] = {def="#{WYZH_240125_21}", decrease="#{WYZH_240125_22}", increase="#{WYZH_240125_23}"},--毒攻击
	[6] = {def="#{WYZH_240125_33}", decrease="#{WYZH_240125_34}", increase="#{WYZH_240125_35}"},--命中
	[7] = {def="#{WYZH_240125_30}", decrease="#{WYZH_240125_31}", increase="#{WYZH_240125_32}"},--闪避
	[8] = {def="#{WYZH_240125_27}", decrease="#{WYZH_240125_28}", increase="#{WYZH_240125_29}"},--穿刺伤害
	[9] = {def="#{WYZH_240125_24}", decrease="#{WYZH_240125_25}", increase="#{WYZH_240125_26}"},--穿刺减免
}

local g_WuYiZhuanHua_AttrMax = 9
local g_WuYiZhuanHua_Attr = {
	"#{WYZH_240125_45}",--血上限
	"#{WYZH_240125_46}",--冰攻击
	"#{WYZH_240125_47}",--火攻击
	"#{WYZH_240125_48}",--玄攻击
	"#{WYZH_240125_49}",--毒攻击
	"#{WYZH_240125_53}",--命中
	"#{WYZH_240125_52}",--闪避
	"#{WYZH_240125_51}",--穿刺伤害
	"#{WYZH_240125_50}",--穿刺减免
}

--废弃
local g_WuYiZhuanHua_Pos = -1

function WuYiZhuanHua_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function WuYiZhuanHua_OnLoad()
	g_WuYiZhuanHua_Frame_UnifiedPosition = WuYiZhuanHua_Frame:GetProperty("UnifiedPosition")
	g_WuYiZhuanHua_RemoveCheck = {
		WuYiZhuanHua_Remove_Line1_Choose,		WuYiZhuanHua_Remove_Line2_Choose,		WuYiZhuanHua_Remove_Line3_Choose,
		WuYiZhuanHua_Remove_Line4_Choose,		WuYiZhuanHua_Remove_Line5_Choose,		WuYiZhuanHua_Remove_Line6_Choose,
		WuYiZhuanHua_Remove_Line7_Choose,		WuYiZhuanHua_Remove_Line8_Choose,		WuYiZhuanHua_Remove_Line9_Choose,
	}
	g_WuYiZhuanHua_RemoveText = {
		WuYiZhuanHua_Remove_Line1_Text,		WuYiZhuanHua_Remove_Line2_Text,		WuYiZhuanHua_Remove_Line3_Text,
		WuYiZhuanHua_Remove_Line4_Text,		WuYiZhuanHua_Remove_Line5_Text,		WuYiZhuanHua_Remove_Line6_Text,
		WuYiZhuanHua_Remove_Line7_Text,		WuYiZhuanHua_Remove_Line8_Text,		WuYiZhuanHua_Remove_Line9_Text,
	}
	g_WuYiZhuanHua_AddCheck = {
		WuYiZhuanHua_Add_Line1_Choose,		WuYiZhuanHua_Add_Line2_Choose,		WuYiZhuanHua_Add_Line3_Choose,
		WuYiZhuanHua_Add_Line4_Choose,		WuYiZhuanHua_Add_Line5_Choose,		WuYiZhuanHua_Add_Line6_Choose,
		WuYiZhuanHua_Add_Line7_Choose,		WuYiZhuanHua_Add_Line8_Choose,		WuYiZhuanHua_Add_Line9_Choose,
	}
	g_WuYiZhuanHua_AddText = {
		WuYiZhuanHua_Add_Line1_Text,		WuYiZhuanHua_Add_Line2_Text,		WuYiZhuanHua_Add_Line3_Text,
		WuYiZhuanHua_Add_Line4_Text,		WuYiZhuanHua_Add_Line5_Text,		WuYiZhuanHua_Add_Line6_Text,
		WuYiZhuanHua_Add_Line7_Text,		WuYiZhuanHua_Add_Line8_Text,		WuYiZhuanHua_Add_Line9_Text,
	}
end

function WuYiZhuanHua_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 71505701) then
		
		local uiflag = Get_XParam_INT(0)
		if uiflag == 1 then
			WuYiZhuanHua_ClearCheck()
			WuYiZhuanHua_Update()
			this:Show()
		elseif uiflag == 2 then
			WuYiZhuanHua_ClearCheck()
			WuYiZhuanHua_Update()
		else
			WuYiZhuanHua_CloseClk()
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		WuYiZhuanHua_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		WuYiZhuanHua_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		WuYiZhuanHua_CloseClk()
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		local str = ""
		local itemcount = PlayerPackage:CountAvailableItemByIDTable(g_WuYiZhuanHua_ItemId)
		if itemcount >= 1 then
			str = ScriptGlobal_Format("#{WYZH_240125_39}", itemcount)
		else
			str = ScriptGlobal_Format("#{WYZH_240125_40}", itemcount)
		end
		WuYiZhuanHua_Img2_Text2:SetText(str)
	end
	
end

function WuYiZhuanHua_ClearCheck()
	for i = 1, table.getn(g_WuYiZhuanHua_RemoveCheck) do
		g_WuYiZhuanHua_RemoveCheck[i]:SetCheck(0)
		g_WuYiZhuanHua_RemoveCheck[i]:Enable()
	end
	for i = 1, table.getn(g_WuYiZhuanHua_AddCheck) do
		g_WuYiZhuanHua_AddCheck[i]:SetCheck(0)
		g_WuYiZhuanHua_AddCheck[i]:Enable()
	end
	g_WuYiZhuanHua_LeftSel = 0
	g_WuYiZhuanHua_RightSel = 0
end

function WuYiZhuanHua_Update()
	local nNum,attrArray = MaritialSys:GetMaritiaAttrs();
	if(nNum < table.getn(g_WuYiZhuanHua_RemoveText) and attrArray ~= nil) then
		return
	end
	for i = 1,table.getn(g_WuYiZhuanHua_RemoveText) do
		if g_WuYiZhuanHua_LeftSel == i then
			local str = ScriptGlobal_Format(g_WuYiZhuanHua_AttrText[i].decrease, attrArray[i])
			g_WuYiZhuanHua_RemoveText[i]:SetText(str)
		else
			local str = ScriptGlobal_Format(g_WuYiZhuanHua_AttrText[i].def, attrArray[i])
			g_WuYiZhuanHua_RemoveText[i]:SetText(str)
		end
		--check
		if attrArray[i] <= 0 then
			g_WuYiZhuanHua_RemoveCheck[i]:Disable()
		else
			g_WuYiZhuanHua_RemoveCheck[i]:Enable()
		end
		g_WuYiZhuanHua_RemoveCheck[i]:SetCheck(0)
		if g_WuYiZhuanHua_LeftSel == i then
			g_WuYiZhuanHua_RemoveCheck[i]:SetCheck(1)
		end
	end
	for i = 1,table.getn(g_WuYiZhuanHua_AddText) do
		if g_WuYiZhuanHua_RightSel == i then
			local str = ScriptGlobal_Format(g_WuYiZhuanHua_AttrText[i].increase, attrArray[i])
			g_WuYiZhuanHua_AddText[i]:SetText(str)
		else
			local str = ScriptGlobal_Format(g_WuYiZhuanHua_AttrText[i].def, attrArray[i])
			g_WuYiZhuanHua_AddText[i]:SetText(str)
		end
		--check
		local maxPoint = MaritialSys:GetMaritiaAttrMaxPoint(i-1)
		if attrArray[i] >= maxPoint then
			g_WuYiZhuanHua_AddCheck[i]:Disable()
		else
			g_WuYiZhuanHua_AddCheck[i]:Enable()
		end
		g_WuYiZhuanHua_AddCheck[i]:SetCheck(0)
		g_WuYiZhuanHua_AddCheck[i]:Enable()
		if g_WuYiZhuanHua_LeftSel == i then
			g_WuYiZhuanHua_AddCheck[i]:Disable()
		end
		if g_WuYiZhuanHua_RightSel == i then
			g_WuYiZhuanHua_AddCheck[i]:SetCheck(1)
		end
	end
	--
	local str = ""
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(g_WuYiZhuanHua_ItemId)
	if itemcount >= 1 then
		str = ScriptGlobal_Format("#{WYZH_240125_39}", itemcount)
	else
		str = ScriptGlobal_Format("#{WYZH_240125_40}", itemcount)
	end
	WuYiZhuanHua_Img2_Text2:SetText(str)
end

function WuYiZhuanHua_On_ResetPos()
	WuYiZhuanHua_Frame:SetProperty("UnifiedPosition", g_WuYiZhuanHua_Frame_UnifiedPosition)

end

function WuYiZhuanHua_CloseClk()
	this:Hide()
end

function WuYiZhuanHua_RemoveCheckClk(nIndex)
--	PushDebugMessage("remove nIdx="..nIndex)
	if(nIndex < 1 and nIndex > g_WuYiZhuanHua_AttrMax) then
		return
	end
	local nNum,attrArray = MaritialSys:GetMaritiaAttrs();
	if attrArray[nIndex] == nil then
		return
	end
	if attrArray[nIndex] <= 0 then
		PushDebugMessage("#{WYZH_240125_36}")
		return
	end
	
	g_WuYiZhuanHua_LeftSel = nIndex
	WuYiZhuanHua_Update()

end

function WuYiZhuanHua_AddCheckClk(nIndex)
--	PushDebugMessage("add nIdx="..nIndex)
	if(nIndex < 1 and nIndex > g_WuYiZhuanHua_AttrMax) then
		return
	end
	local nNum,attrArray = MaritialSys:GetMaritiaAttrs();
	if attrArray[nIndex] == nil then
		return
	end
	if g_WuYiZhuanHua_LeftSel == 0 then
		PushDebugMessage("#{WYZH_240125_57}")
		for i = 1, table.getn(g_WuYiZhuanHua_AddCheck) do
			g_WuYiZhuanHua_AddCheck[i]:SetCheck(0)
		end
		return
	end
	local maxPoint = MaritialSys:GetMaritiaAttrMaxPoint(nIndex-1)
	if attrArray[nIndex] >= maxPoint then
		PushDebugMessage("#{WYZH_240125_37}")
		for i = 1, table.getn(g_WuYiZhuanHua_AddCheck) do
			g_WuYiZhuanHua_AddCheck[i]:SetCheck(0)
		end
		return
	end 
	
	g_WuYiZhuanHua_RightSel = nIndex
	WuYiZhuanHua_Update()
end

function WuYiZhuanHua_OKClick()
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(g_WuYiZhuanHua_ItemId)
	if itemcount < 1 then
		PushDebugMessage("#{WYZH_240125_43}")
		return
	end
	--加锁略
	--- 角色当前未处于全沉迷或半沉迷状态；
	if IsInFatigueState() <= 0 then
		PushDebugMessage( "#{FCMX_90619_04}" )
		return
	end
	--任务略
	local nLevel = Player:GetLevel();
	if nLevel < 85 then
		PushDebugMessage("#{WYZH_240125_02}")
		WuYiZhuanHua_CloseClk()
		return
	end
	--分配点数
	local nRemainPoint = MaritialSys:GetMaritiaRemainPoint()--拥有
	local nAlreadyPoint = MaritialSys:GetMaritiaAlreadyPoint()--已分配
	if nAlreadyPoint <= 0 then
		PushDebugMessage("#{WYZH_240125_03}")
		WuYiZhuanHua_CloseClk()
		return
	end
	--主城略
	if g_WuYiZhuanHua_LeftSel == 0 then
		PushDebugMessage("#{WYZH_240125_55}")
--		WuYiZhuanHua_CloseClk()
		return
	end
	local nNum,attrArray = MaritialSys:GetMaritiaAttrs();
	if attrArray[g_WuYiZhuanHua_LeftSel] == nil then
		WuYiZhuanHua_CloseClk()
		return
	end
	if attrArray[g_WuYiZhuanHua_LeftSel] <= 0 then
		PushDebugMessage("#{WYZH_240125_36}")
		WuYiZhuanHua_CloseClk()
		return
	end
	if g_WuYiZhuanHua_RightSel == 0 then
		PushDebugMessage("#{WYZH_240125_42}")
--		WuYiZhuanHua_CloseClk()
		return
	end
	if attrArray[g_WuYiZhuanHua_RightSel] == nil then
		WuYiZhuanHua_CloseClk()
		return
	end
	local maxPoint = MaritialSys:GetMaritiaAttrMaxPoint(g_WuYiZhuanHua_RightSel-1)
	if attrArray[g_WuYiZhuanHua_RightSel] >= maxPoint then
		PushDebugMessage("#{WYZH_240125_37}")
		WuYiZhuanHua_CloseClk()
		return
	end
	--virtual VOID	PushEvent(INT id, LPCTSTR szArg0, INT iArg1, INT iArg2, INT iArg3);
	local strMsg = ScriptGlobal_Format("#{WYZH_240125_44}", g_WuYiZhuanHua_Attr[g_WuYiZhuanHua_LeftSel], g_WuYiZhuanHua_Attr[g_WuYiZhuanHua_RightSel])
	PushEvent("WUYIZHUANHUAN_CONFIRM", strMsg, g_WuYiZhuanHua_Pos, g_WuYiZhuanHua_LeftSel, g_WuYiZhuanHua_RightSel)
end