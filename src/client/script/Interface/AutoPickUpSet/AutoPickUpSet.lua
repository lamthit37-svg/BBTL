local g_unifiedposistion= nil
local g_InitList		= 0
local g_SubInitList		= 0
local g_MaxBarNum		= 0
local g_SubMaxBarNum	= 0
local g_RealMaxBarNum	= 0
local g_opType			= 0
local g_TypeSelect		= 0
local g_BarList			= {}
local g_data			= {}
local g_configchange	= 0
--==================================下面为固定常量===============================================
local g_enOpType		= {
	open = 1,
	close = 2,
}
--===================================固定常量END==========================================================
function AutoPickUpSet_PreLoad()
	this:RegisterEvent("QIANKUNPOT_TYPE_SHOW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
end

function AutoPickUpSet_OnLoad()
	g_unifiedposistion = AutoPickUpSet_Frame:GetProperty("UnifiedPosition")
end

function AutoPickUpSet_OnEvent(event)
	if event == "QIANKUNPOT_TYPE_SHOW" then
		AutoPickUpSet_OnShow(arg0, arg1, arg2, arg3)
	elseif event == "ADJEST_UI_POS"  then
		AutoPickUpSet_OnResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		AutoPickUpSet_OnResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		AutoPickUpSet_OnClose()
	end
end

function AutoPickUpSet_OnShow(posx, posy, sizex, sizey)
	AutoPickUpSet_CleanUp()
	AutoPickUpSet_SetPosition(posx, posy, sizex, sizey)
	AutoPickUpSet_InitList()
	AutoPickUpSet_UpdateList()
	this:Show()
end

function AutoPickUpSet_InitList()
	if g_InitList == 0 then
		QianKunPotScript:InitQianKunPotTypeList()
		
		g_data = {}
		g_RealMaxBarNum = 0
		g_MaxBarNum = QianKunPotScript:GetQianKunPotTypeMax()
		for i = 1, g_MaxBarNum do
			g_RealMaxBarNum = g_RealMaxBarNum + 1
			local bar = AutoPickUpSet_CategoryList:AddChild("AutoPickUpSet_TitListItem")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			bar:GetSubItem("AutoPickUpSet_Tit"):SetEvent("Clicked", string.format("AutoPickUpSet_ItemClicked(%d)", i))
			bar:GetSubItem("AutoPickUpSet_Tit"):SetEvent("MouseButtonUp", string.format("AutoPickUpSet_ItemCheckUpdate()"))
			g_BarList[g_RealMaxBarNum] = bar
			g_data[g_RealMaxBarNum] = {}
			g_data[g_RealMaxBarNum].fold = 1
			g_data[g_RealMaxBarNum].btn = 0
			g_data[g_RealMaxBarNum].type = i
			g_data[g_RealMaxBarNum].subtype = 0

			g_SubMaxBarNum = QianKunPotScript:GetQianKunPotSubTypeMax(i)
			if g_SubMaxBarNum > 1 then
				-- 只有大于1的情况下才会有全选按钮
				g_RealMaxBarNum = g_RealMaxBarNum + 1
				local sub_bar = AutoPickUpSet_CategoryList:AddChild("AutoPickUpSet_SetListItem2")
				sub_bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
				local checkbtn = sub_bar:GetSubItem("AutoPickUpSet_PickUpBtn")
				checkbtn:SetProperty("Empty", "False")
				checkbtn:SetEvent("Clicked", string.format("AutoPickUpSet_AllSubItemClicked(%d,%d)", i, g_RealMaxBarNum))
				sub_bar:GetSubItem("AutoPickUpSet_PickUpTxt"):SetText("")
				g_BarList[g_RealMaxBarNum] = sub_bar
				g_data[g_RealMaxBarNum] = {}
				g_data[g_RealMaxBarNum].fold = 0
				g_data[g_RealMaxBarNum].btn = 1
				g_data[g_RealMaxBarNum].type = i
				g_data[g_RealMaxBarNum].subtype = 0
			end

			for j=1, g_SubMaxBarNum do
				g_RealMaxBarNum = g_RealMaxBarNum + 1
				local sub_bar = AutoPickUpSet_CategoryList:AddChild("AutoPickUpSet_SetListItem2")
				sub_bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
				local checkbtn = sub_bar:GetSubItem("AutoPickUpSet_PickUpBtn")
				checkbtn:SetProperty("Empty", "False")
				checkbtn:SetEvent("Clicked", string.format("AutoPickUpSet_SubItemClicked(%d,%d)", i, g_RealMaxBarNum))
				sub_bar:GetSubItem("AutoPickUpSet_PickUpTxt"):SetText("")
				g_BarList[g_RealMaxBarNum] = sub_bar
				g_data[g_RealMaxBarNum] = {}
				g_data[g_RealMaxBarNum].fold = 0
				g_data[g_RealMaxBarNum].btn = 0
				g_data[g_RealMaxBarNum].type = i
				g_data[g_RealMaxBarNum].subtype = j
			end
		end

		g_InitList = 1
	end
end

function AutoPickUpSet_UpdateList()
	local max = table.getn(g_data)
	if max ~= g_RealMaxBarNum then
		return
	end

	for i = 1, g_RealMaxBarNum do
		local bar = g_BarList[i]
		if g_SubInitList == 0 then
			if g_data[i].fold == 1 then
				local sztype,szsubtype,own = QianKunPotScript:GetQianKunPotTypeInfo(g_data[i].type, 0)
				bar:GetSubItem("AutoPickUpSet_Tit"):SetText(sztype)
				bar:GetSubItem("AutoPickUpSet_Tit"):SetToolTip("")
			else
				if g_data[i].btn == 1 then
					bar:GetSubItem("AutoPickUpSet_PickUpBtn"):SetToolTip("")
					bar:GetSubItem("AutoPickUpSet_PickUpTxt"):SetText("#{QKH_20220802_29}")
					bar:GetSubItem("AutoPickUpSet_PickUpTxt"):SetToolTip("")
				else
					local sztype,szsubtype,own = QianKunPotScript:GetQianKunPotTypeInfo(g_data[i].type, g_data[i].subtype-1)
					bar:GetSubItem("AutoPickUpSet_PickUpBtn"):SetCheck(own)
					bar:GetSubItem("AutoPickUpSet_PickUpBtn"):SetToolTip("")
					bar:GetSubItem("AutoPickUpSet_PickUpTxt"):SetText(szsubtype)
					bar:GetSubItem("AutoPickUpSet_PickUpTxt"):SetToolTip("")
				end
			end
		end
		if g_opType == g_enOpType.close then
			if g_data[i].fold == 1 then
				bar:Show()
			else
				bar:Hide()
			end
		else
			if g_data[i].fold == 1 then
				bar:Show()
			else
				if g_data[i].type == g_TypeSelect then
					bar:Show()
				else
					bar:Hide()
				end
			end
		end

		if g_data[i].fold == 1 then
			if g_data[i].type == g_TypeSelect and g_opType == g_enOpType.open then
				bar:GetSubItem("AutoPickUpSet_Tit"):SetCheck(1)
			else
				bar:GetSubItem("AutoPickUpSet_Tit"):SetCheck(0)
			end
		end
	end

	AutoPickUpSet_UpdateCheckList()

	if g_SubInitList == 0 then
		g_SubInitList = 1
	end
	AutoPickUpSet_CategoryList:RefreshLayout()
end

function AutoPickUpSet_UpdateCheckList()

	local subtypecnt = 0
	local subtypemax = QianKunPotScript:GetQianKunPotSubTypeMax(g_TypeSelect)
	for i=1, g_RealMaxBarNum do
		if g_data[i].type == g_TypeSelect then
			if g_data[i].fold == 0 and g_data[i].btn == 0 then
				local sztype,szsubtype,own = QianKunPotScript:GetQianKunPotTypeInfo(g_data[i].type, g_data[i].subtype-1)
				if own > 0 then
					subtypecnt = subtypecnt + 1
				end
			end
		end
	end

	for i=1, g_RealMaxBarNum do
		if g_data[i].type == g_TypeSelect and g_data[i].btn == 1 then
			local bar = g_BarList[i]
			if subtypecnt == subtypemax then
				bar:GetSubItem("AutoPickUpSet_PickUpBtn"):SetCheck(1)
			else
				bar:GetSubItem("AutoPickUpSet_PickUpBtn"):SetCheck(0)
			end
			break
		end
	end
end

function AutoPickUpSet_ItemClicked(typeidx)
	if typeidx > g_MaxBarNum then
		return
	end

	if g_TypeSelect == typeidx then
		if g_opType == g_enOpType.open then
			g_opType = g_enOpType.close
		elseif g_opType == g_enOpType.close then
			g_opType = g_enOpType.open
		end
	else
		g_TypeSelect = typeidx
		g_opType = g_enOpType.open
	end

	-- 刷新大界面
	AutoPickUpSet_UpdateList()
end

function AutoPickUpSet_AllSubItemClicked(typeidx, subidx)
	if typeidx > g_MaxBarNum then
		return
	end

	if g_opType == g_enOpType.close then
		return
	end
	if typeidx ~= g_TypeSelect then
		return
	end

	local bar = g_BarList[subidx]
	if bar == nil then
		return
	end

	local subdata = g_data[subidx]
	if subdata == nil then
		return
	end

	g_configchange = 1

	local check = bar:GetSubItem("AutoPickUpSet_PickUpBtn"):GetCheck()
	if check > 0 then
		QianKunPotScript:AddQianKunPotAllType(0, typeidx)
	else
		QianKunPotScript:DeleteQianKunPotAllType(0, typeidx)
	end

	for i=1, g_RealMaxBarNum do
		if g_data[i].type == typeidx then
			if g_data[i].fold ~= 1 and g_data[i].btn ~= 1 then
				g_BarList[i]:GetSubItem("AutoPickUpSet_PickUpBtn"):SetCheck(check)
			end
		end
	end
end

function AutoPickUpSet_SubItemClicked(typeidx, subidx)
	if subidx > g_RealMaxBarNum or subidx < 1 then
		return
	end
	-- 进这里说明有Bug
	if g_opType == g_enOpType.close then
		return
	end
	if typeidx ~= g_TypeSelect then
		return
	end
	-- 这里不用刷界面
	local bar = g_BarList[subidx]
	if bar == nil then
		return
	end
	local subdata = g_data[subidx]
	if subdata == nil then
		return
	end
	local sztype,szsubtype,own = QianKunPotScript:GetQianKunPotTypeInfo(g_TypeSelect, subdata.subtype-1)
	if sztype == "" then
		return
	end

	g_configchange = 1

	local check = bar:GetSubItem("AutoPickUpSet_PickUpBtn"):GetCheck()
	if check > 0 then
		QianKunPotScript:AddQianKunPotType(0, szsubtype)
	else
		QianKunPotScript:DeleteQianKunPotType(0, szsubtype)
	end

	AutoPickUpSet_UpdateCheckList()
end

function AutoPickUpSet_ItemCheckUpdate()
	AutoPickUpSet_UpdateList()
end

function AutoPickUpSet_OnResetPos()
	if g_unifiedposistion ~= nil then
		AutoPickUpSet_Frame:SetProperty("UnifiedPosition",g_unifiedposistion)
	end
end

function AutoPickUpSet_CalculateProperty(property)
	if property == nil or property == "" then
		return nil
	end

	local scale = string.find(property,"{")
	local x = string.find(property,",")
	local y = string.find(property,"}")

	local retscale = string.sub(property, scale+1, x-1)
	local retvalue = string.sub(property, x+1, y-1)

	return retscale, retvalue
end

-- 计算界面坐标
function AutoPickUpSet_SetPosition(posx, posy, sizex, sizey)

	-- 相对位置
	local pos_xs, pos_x = AutoPickUpSet_CalculateProperty(posx)
	if pos_xs == nil then
		return
	end

	local pos_ys, pos_y = AutoPickUpSet_CalculateProperty(posy)
	if pos_ys == nil then
		return
	end

	-- 相对大小
	local pos_sxs, pos_sx = AutoPickUpSet_CalculateProperty(sizex)
	if pos_sxs == nil then
		return
	end

	local pos_sys, pos_sy = AutoPickUpSet_CalculateProperty(sizey)
	if pos_sys == nil then
		return
	end

	-- 计算我本身的界面大小
	local unifiedwidth = AutoPickUpSet_Frame:GetProperty("UnifiedWidth")
	local my_s, my_width = AutoPickUpSet_CalculateProperty(unifiedwidth)
	if my_s == nil then
		return
	end

	local xmax, ymax = GetCurClientSize()
	local destx = pos_xs*xmax + pos_x + pos_sxs*xmax + pos_sx
	local desty = pos_ys*ymax + pos_y + pos_sys*ymax + pos_sy

	if destx + my_width > xmax then
		destx = pos_xs*xmax + pos_x - my_width
	end

	if not this:IsVisible() then
		AutoPickUpSet_Frame:SetProperty("UnifiedXPosition", "{0,"..(destx).."}")
		AutoPickUpSet_Frame:SetProperty("UnifiedYPosition", posy)
	end
end


function AutoPickUpSet_CleanUp()
	g_opType = g_enOpType.open
	g_TypeSelect = 1
	g_SubMaxBarNum = 0
	g_configchange = 0
end

function AutoPickUpSet_CloseClicked()
	AutoPickUpSet_OnClose()
end

function AutoPickUpSet_OnClose()
	AutoPickUpSet_ConfigChange()
	this:Hide()
end

function AutoPickUpSet_OnHide()

end

function AutoPickUpSet_ConfigChange()
	if g_configchange > 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("QKHConfigChange")
			Set_XSCRIPT_ScriptID(888851)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()

		g_configchange = 0
	end
end