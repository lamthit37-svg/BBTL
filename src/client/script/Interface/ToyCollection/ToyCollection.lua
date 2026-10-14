--!!!reloadscript =ToyCollection
local g_ToyCollection_UnifiedPosition = ""

local EXTERIORFILTTING_TOTALKIND = 6;
local g_TargetToyIndex = 0		--定位的外观索引，从1开始
local g_TargetToyID = 0			--定位的外观ID

local g_MaxToyPerPage = 6

local g_CurCategory = 0
local g_CurSubType = 0

local g_CurSelToyID = 0			--当前选择的玩具ID
local g_NeedChangeScrollSize = 1

local g_InitList = 0
local g_ExteriorType = 3 --脸型
local g_MaxBarNum = 0
local g_ToyItemList = {}
local g_CategoryList = {}

local g_Category = {
--	[1] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
--	[2] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
--	[3] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
--	[4] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
--	[5] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
--	[6] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
--	[7] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
--	[8] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
--	[9] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
--	[10] = {Image = {}, fold = 1, sub_count = 0, subtype = {}},
	[1] = {Image = {}, epImage = {}, fold = 1, sub_count = 9, subtype = {}},
	[2] = {Image = {}, epImage = {}, fold = 1, sub_count = 3, subtype = {}},
	[3] = {Image = {}, epImage = {}, fold = 1, sub_count = 2, subtype = {}}, --替代
--	[5] = {txt = "Category 5", fold = 1, sub_count = 5, subtype = {"Sub Type 1","Sub Type 1","Sub Type 1","Sub Type 1","Sub Type 1"}},
--	[6] = {txt = "Category 6", fold = 1, sub_count = 6, subtype = {"Sub Type 1","Sub Type 1","Sub Type 1","Sub Type 1","Sub Type 1","Sub Type 1"}},
}


local g_CurPage = 1
local g_MaxPage = 1

--=========
--PreLoad==
--=========
function ToyCollection_PreLoad()
	
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_TOY_COLLECTION")
	this:RegisterEvent("ADD_TOY")
	this:RegisterEvent("TOY_OUTTIME")
	this:RegisterEvent("UPDATE_TOY")
	this:RegisterEvent("UPDATE_TOY_TIP")
	
	this:RegisterEvent("ON_SCENE_TRANS", false)
	this:RegisterEvent("ON_SERVER_TRANS", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)

end

--=========
--OnLoad
--=========
function ToyCollection_OnLoad()
	
	g_ToyCollection_UnifiedPosition = ToyCollection_Frame:GetProperty("UnifiedPosition")
	
	--1级
	g_Category[1].Image[1] = "set:ToyCollection6 image:BKButton2021_Normal_Down"
	g_Category[1].Image[2] = "set:ToyCollection6 image:BKButton2021_Hover_Down"
	g_Category[1].Image[3] = "set:ToyCollection6 image:BKButton2021_Hover_Down"
	g_Category[1].Image[4] = "set:ToyCollection6 image:BKButton2021_Normal_Down"
	
	g_Category[1].epImage[1] = "set:ToyCollection6 image:BKButton2021_Normal_UP"
	g_Category[1].epImage[2] = "set:ToyCollection6 image:BKButton2021_Hover_UP"
	g_Category[1].epImage[3] = "set:ToyCollection6 image:BKButton2021_Hover_UP"
	g_Category[1].epImage[4] = "set:ToyCollection6 image:BKButton2021_Normal_Up"
	
	g_Category[2].Image[1] = "set:ToyCollection6 image:BKButton2022_Normal_Down"
	g_Category[2].Image[2] = "set:ToyCollection6 image:BKButton2022_Hover_Down"
	g_Category[2].Image[3] = "set:ToyCollection6 image:BKButton2022_Hover_Down"
	g_Category[2].Image[4] = "set:ToyCollection6 image:BKButton2022_Normal_Down"
	
	g_Category[2].epImage[1] = "set:ToyCollection6 image:BKButton2022_Normal_UP"
	g_Category[2].epImage[2] = "set:ToyCollection6 image:BKButton2022_Hover_UP"
	g_Category[2].epImage[3] = "set:ToyCollection6 image:BKButton2022_Hover_UP"
	g_Category[2].epImage[4] = "set:ToyCollection6 image:BKButton2022_Normal_UP"

	g_Category[3].Image[1] = "set:ToyCollection6 image:BKButton2023_Normal_Down"
	g_Category[3].Image[2] = "set:ToyCollection6 image:BKButton2023_Hover_Down"
	g_Category[3].Image[3] = "set:ToyCollection6 image:BKButton2023_Hover_Down"
	g_Category[3].Image[4] = "set:ToyCollection6 image:BKButton2023_Normal_Down"
	
	g_Category[3].epImage[1] = "set:ToyCollection6 image:BKButton2023_Normal_UP"
	g_Category[3].epImage[2] = "set:ToyCollection6 image:BKButton2023_Hover_UP"
	g_Category[3].epImage[3] = "set:ToyCollection6 image:BKButton2023_Hover_UP"
	g_Category[3].epImage[4] = "set:ToyCollection6 image:BKButton2023_Normal_UP"
	
	--2级
	g_Category[1].subtype[1] = {Image = {}}
	g_Category[1].subtype[1].Image[1] = "set:ToyCollection image:BKButton_Normal"
	g_Category[1].subtype[1].Image[2] = "set:ToyCollection image:BKButton_Hover"
	g_Category[1].subtype[1].Image[3] = "set:ToyCollection image:BKButton_Hover"
	g_Category[1].subtype[1].Image[4] = "set:ToyCollection image:BKButton_Normal"
	
	g_Category[1].subtype[2] = {Image = {}}
	g_Category[1].subtype[2].Image[1] = "set:ToyCollection1 image:LSCF_Normal"
	g_Category[1].subtype[2].Image[2] = "set:ToyCollection1 image:LSCF_Hover"
	g_Category[1].subtype[2].Image[3] = "set:ToyCollection1 image:LSCF_Hover"
	g_Category[1].subtype[2].Image[4] = "set:ToyCollection1 image:BLSCF_Normal"	
	
	g_Category[1].subtype[3] = {Image = {}}
	g_Category[1].subtype[3].Image[1] = "set:ToyCollection1 image:ETJYJ_Normal"
	g_Category[1].subtype[3].Image[2] = "set:ToyCollection1 image:ETJYJ_Hover"
	g_Category[1].subtype[3].Image[3] = "set:ToyCollection1 image:ETJYJ_Hover"
	g_Category[1].subtype[3].Image[4] = "set:ToyCollection1 image:ETJYJ_Normal"
	
	g_Category[1].subtype[4] = {Image = {}}
	g_Category[1].subtype[4].Image[1] = "set:ToyCollection2 image:DYZX_Normal"
	g_Category[1].subtype[4].Image[2] = "set:ToyCollection2 image:DYZX_Hover"
	g_Category[1].subtype[4].Image[3] = "set:ToyCollection2 image:DYZX_Hover"
	g_Category[1].subtype[4].Image[4] = "set:ToyCollection2 image:DYZX_Normal"
	
	g_Category[1].subtype[5] = {Image = {}}
	g_Category[1].subtype[5].Image[1] = "set:ToyCollection2 image:CAT_Normal"
	g_Category[1].subtype[5].Image[2] = "set:ToyCollection2 image:CAT_Hover"
	g_Category[1].subtype[5].Image[3] = "set:ToyCollection2 image:CAT_Hover"
	g_Category[1].subtype[5].Image[4] = "set:ToyCollection2 image:CAT_Normal"
	
	g_Category[1].subtype[6] = {Image = {}}
	g_Category[1].subtype[6].Image[1] = "set:ToyCollection3 image:QXYXX_Normal"
	g_Category[1].subtype[6].Image[2] = "set:ToyCollection3 image:QXYXX_Hover"
	g_Category[1].subtype[6].Image[3] = "set:ToyCollection3 image:QXYXX_Hover"
	g_Category[1].subtype[6].Image[4] = "set:ToyCollection3 image:QXYXX_Normal"
	
	g_Category[1].subtype[7] = {Image = {}}
	g_Category[1].subtype[7].Image[1] = "set:ToyCollection3 image:JQ_Normal"
	g_Category[1].subtype[7].Image[2] = "set:ToyCollection3 image:JQ_Hover"
	g_Category[1].subtype[7].Image[3] = "set:ToyCollection3 image:JQ_Hover"
	g_Category[1].subtype[7].Image[4] = "set:ToyCollection3 image:JQ_Normal"
	
	g_Category[1].subtype[8] = {Image = {}}
	g_Category[1].subtype[8].Image[1] = "set:ToyCollection4 image:ZQ_Normal"
	g_Category[1].subtype[8].Image[2] = "set:ToyCollection4 image:ZQ_Hover"
	g_Category[1].subtype[8].Image[3] = "set:ToyCollection4 image:ZQ_Hover"
	g_Category[1].subtype[8].Image[4] = "set:ToyCollection4 image:ZQ_Normal"
	
	g_Category[1].subtype[9] = {Image = {}}
	g_Category[1].subtype[9].Image[1] = "set:ToyCollection4 image:XFYJ_Nomal"
	g_Category[1].subtype[9].Image[2] = "set:ToyCollection4 image:XFYJ_Hover"
	g_Category[1].subtype[9].Image[3] = "set:ToyCollection4 image:XFYJ_Hover"
	g_Category[1].subtype[9].Image[4] = "set:ToyCollection4 image:XFYJ_Nomal"
	
	g_Category[2].subtype[1] = {Image = {}}
	g_Category[2].subtype[1].Image[1] = "set:ToyCollection5 image:Qixi_normal"
	g_Category[2].subtype[1].Image[2] = "set:ToyCollection5 image:Qixi_hover"
	g_Category[2].subtype[1].Image[3] = "set:ToyCollection5 image:Qixi_hover"
	g_Category[2].subtype[1].Image[4] = "set:ToyCollection5 image:Qixi_normal"

	g_Category[2].subtype[2] = {Image = {}}
	g_Category[2].subtype[2].Image[1] = "set:ToyCollection5 image:ZNYR_Normal"
	g_Category[2].subtype[2].Image[2] = "set:ToyCollection5 image:ZNYR_Hover"
	g_Category[2].subtype[2].Image[3] = "set:ToyCollection5 image:ZNYR_Hover"
	g_Category[2].subtype[2].Image[4] = "set:ToyCollection5 image:ZNYR_Normal"
	
	g_Category[2].subtype[3] = {Image = {}}
	g_Category[2].subtype[3].Image[1] = "set:ToyCollection7 image:Fuxia_Normal"
	g_Category[2].subtype[3].Image[2] = "set:ToyCollection7 image:Fuxia_Hover"
	g_Category[2].subtype[3].Image[3] = "set:ToyCollection7 image:Fuxia_Hover"
	g_Category[2].subtype[3].Image[4] = "set:ToyCollection7 image:Fuxia_Normal"

	g_Category[3].subtype[1] = {Image = {}}
	g_Category[3].subtype[1].Image[1] = "set:ToyCollection7 image:Rabbit_Normal"
	g_Category[3].subtype[1].Image[2] = "set:ToyCollection7 image:Rabbit_Hover"
	g_Category[3].subtype[1].Image[3] = "set:ToyCollection7 image:Rabbit_Hover"
	g_Category[3].subtype[1].Image[4] = "set:ToyCollection7 image:Rabbit_Normal"
	
	g_Category[3].subtype[2] = {Image = {}}
	g_Category[3].subtype[2].Image[1] = "set:ToyCollection8 image:Valentine_Normal"
	g_Category[3].subtype[2].Image[2] = "set:ToyCollection8 image:Valentine_Hover"
	g_Category[3].subtype[2].Image[3] = "set:ToyCollection8 image:Valentine_Hover"
	g_Category[3].subtype[2].Image[4] = "set:ToyCollection8 image:Valentine_Normal"
end
--=========
--OnEvent
--=========
function ToyCollection_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 99990301 then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
	if event == "OPEN_TOY_COLLECTION" then
		if this:IsVisible() then
			--this:Hide()
		else
			this:Show()
			ToyCollection_InitList()
			g_NeedChangeScrollSize = 1
			ToyCollection_CleanUp()
			g_CurSelToyID = 0

			ToyCollection_Update()
		end

		return
	end

	if event == "ADD_TOY" or event == "UPDATE_TOY" or event == "TOY_OUTTIME" then
		local nToyID = tonumber(arg0)
		local nCategory = Exterior:LuaFnGetToyInfo(nToyID, "Category")
		local nSubType = Exterior:LuaFnGetToyInfo(nToyID, "SubType")

		if nCategory == g_CurCategory and nSubType == g_CurSubType then
			
			g_CurPage = 1
	
			--玩具列表
			ToyCollection_UpdatToyeList()
			--使用按钮
			ToyCollection_UpdateUseButton()
			
			ToyCollection_UpdatePageButton()
		end
		return
	end

	if event == "UPDATE_TOY_TIP" then
		ToyCollection_UpdateRedPoint()
		return
	end

	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		ToyCollection_Frame:SetProperty("UnifiedPosition", g_ToyCollection_UnifiedPosition)
	end

end

function ToyCollection_InitList()
	
	if g_InitList == 0 then	
		
		g_MaxCategoryNum = 0
		-- PushDebugMessage("table.getn(g_Category) {"..table.getn(g_Category).."}")
		for i = 1, table.getn(g_Category) do
			local bar = ToyCollection_CategoryList:AddChild("ToyCollection_CategoryListItem")
		--	bar:SetProperty("SuperBarButtonHover", "SuperBarHoverSection")
			g_MaxCategoryNum = g_MaxCategoryNum + 1
			g_CategoryList[g_MaxCategoryNum] = bar			
			
			bar:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetEvent("MouseButtonUp", "ToyCollection_UpdateCategoryCheckState()")
			
			if g_Category[i].sub_count > 0 then
				
				bar:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetEvent("Clicked", string.format("ToyCollection_UnfoldCatetory(%d)", i))
				
				--暂时没有先不写了
				
				for j = 1,  g_Category[i].sub_count do
					local sub_bar = ToyCollection_CategoryList:AddChild("ToyCollection_CategoryListItem2")
					g_MaxCategoryNum = g_MaxCategoryNum + 1
					g_CategoryList[g_MaxCategoryNum] = sub_bar
					
					sub_bar:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetEvent("Clicked", string.format("ToyCollection_ShowCategory(%d, %d)", i, j))
					sub_bar:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetEvent("MouseButtonUp", "ToyCollection_UpdateCategoryCheckState()")

					sub_bar:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetProperty("CheckMode", "2")
					sub_bar:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetProperty("NormalImage", g_Category[i].subtype[j].Image[1])
					sub_bar:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetProperty("HoverImage", g_Category[i].subtype[j].Image[2])
					sub_bar:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetProperty("PushedImage", g_Category[i].subtype[j].Image[3])
					sub_bar:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetProperty("DisabledImage", g_Category[i].subtype[j].Image[4])

				end
				
			else
				bar:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetEvent("Clicked", string.format("ToyCollection_ShowCategory(%d, 0)", i))
			end			
			
			bar:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("CheckMode", "2")
			bar:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("NormalImage", g_Category[i].Image[1])
			bar:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("HoverImage", g_Category[i].Image[2])
			bar:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("PushedImage", g_Category[i].Image[3])
			bar:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("DisabledImage", g_Category[i].Image[4])
			
		end

		for i = 1, g_MaxToyPerPage do
			local bar = ToyCollection_ToyList:AddChild("ToyCollection_ToyListItem")
		--	bar:SetProperty("SuperBarButtonHover", "SuperBarHoverSection")
			g_ToyItemList[i] = bar
			bar:SetEvent("MouseLClick", string.format("ToyCollection_ToyClicked(%d)", i))
		--	bar:GetSubItem("ToyCollection_ToyListItem_Action"):SetEvent("Clicked", string.format("ToyCollection_ToyClicked(%d)", i))
			bar:GetSubItem("ToyCollection_ToyListItem_Action"):SetProperty("UseDefaultTooltip", "False")
		end
		g_InitList = 1
	end
end

function ToyCollection_Update()

	--分类列表
	ToyCollection_Update_CategoryList()
	ToyCollection_CategoryList:RefreshLayout()
	
	--玩具列表
	ToyCollection_UpdatToyeList()
	--使用按钮
	ToyCollection_UpdateUseButton()
	ToyCollection_UpdatePageButton()
	
	ToyCollection_RemoveTip(g_CurSelToyID)
	ToyCollection_UpdateRedPoint()

end

function ToyCollection_UpdatToyeList()
	
	if g_CurSubType == 0 then
		ToyCollection_ToyList:Hide()
		return
	else
		ToyCollection_ToyList:Show()
	end
--	ToyCollection_UpdateRedPoint()
	
	Exterior:LuaFnInitToyList(g_CurCategory, g_CurSubType)
	local count = Exterior:LuaFnGetToyListCount()
--	PushDebugMessage(tostring(g_CurCategory)..":"..tostring(g_CurSubType)..":"..tostring(count))
	g_MaxPage = math.floor(count / g_MaxToyPerPage)
	if math.mod(count, g_MaxToyPerPage) ~= 0 then
		g_MaxPage = g_MaxPage + 1
	end
	
	if g_CurPage > g_MaxPage then
		g_CurPage = g_MaxPage
	end	
	
	if g_CurPage < 1 then
		g_CurPage = 1
	end
	
	for i = 1, g_MaxToyPerPage do	
		ToyCollection_SetItem((g_CurPage - 1) * g_MaxToyPerPage + i, count)
	end
	
	if g_NeedChangeScrollSize == 1 then
		ToyCollection_ToyList:RefreshLayout()
		g_NeedChangeScrollSize = 0
	end
	
	if g_TargetToyIndex ~= 0 then
		ToyCollection_ToyList:SetScrollPosition4Index(g_TargetToyIndex - 1)
		g_TargetToyID = 0
		g_TargetToyIndex = 0
	else
		ToyCollection_ToyList:SetScrollPosition4Index(0)
	end	

	
end

function ToyCollection_SetItem(index, max_count)
	
	if g_ToyItemList[index] == nil then
		return
	end
	
	if index > max_count then
		g_ToyItemList[index]:Hide()
		return
	end
	
	local bar = g_ToyItemList[index]
	bar:Show()
	
	local nToyID = Exterior:LuaFnGetToyIDFromList(index - 1)
	local strName 	= Exterior:LuaFnGetToyInfo(nToyID, "Name")
	local strIcon 	= Exterior:LuaFnGetToyInfo(nToyID, "Icon")	
	local strImage = GetIconFullName(strIcon)	
	
	if g_CurSelToyID == nToyID then
		bar:SetSelect(1)
	else
		bar:SetSelect(0)
	end
	
	if g_TargetToyID == nToyID then
		g_TargetToyIndex = index
	end
	
	local ctrlAction = bar:GetSubItem("ToyCollection_ToyListItem_Action")
	if ctrlAction ~= nil then			
		
		ctrlAction:SetActionItem(-1)
		local toyAction = Exterior:LuaFnEnumToyAction(nToyID)
		if toyAction:GetID() ~= -1 then
			ctrlAction:SetActionItem(toyAction:GetID())		
		end		
		
		if g_CurSelToyID == nToyID then
			bar:GetSubItem("ToyCollection_ToyListItem_BK"):SetCheck(1)
			ctrlAction:SetPushed(1)
		else
			bar:GetSubItem("ToyCollection_ToyListItem_BK"):SetCheck(0)
			ctrlAction:SetPushed(0)
		end

		if Exterior:LuaFnIsHaveToy(nToyID) == 1 then
			ctrlAction:SetProperty("DraggingEnabled", "True")
		else
			ctrlAction:SetProperty("DraggingEnabled", "False")
		end
	end
	
	bar:GetSubItem("ToyCollection_ToyListItem_Name"):SetText(tostring(strName))	
	
	if Exterior:LuaFnGetToyLeftTime(nToyID) > 0 then
		bar:GetSubItem("ToyCollection_ToyListItem_Time"):Show()
	else
		bar:GetSubItem("ToyCollection_ToyListItem_Time"):Hide()
	end	
	
	--锁	
	local strBigImage = Exterior:LuaFnGetToyInfo(nToyID, "BigImage")
	bar:GetSubItem("ToyCollection_ToyListItem_Image"):SetProperty("Image", strBigImage)
	
	local strBKImage = Exterior:LuaFnGetToyInfo(nToyID, "BKImage")
	local strGrayBKImage = Exterior:LuaFnGetToyInfo(nToyID, "GrayBKImage")
	if Exterior:LuaFnIsHaveToy(nToyID) == 1 then
	--	bar:GetSubItem("ToyCollection_ToyListItem_BK"):SetProperty("Image", strBKImage)
		bar:GetSubItem("ToyCollection_ToyListItem_Lock"):Hide()		
	else
	--	bar:GetSubItem("ToyCollection_ToyListItem_BK"):SetProperty("Image", strGrayBKImage)
		bar:GetSubItem("ToyCollection_ToyListItem_Lock"):Show()
	end
	
	--红点
	local nTip = Exterior:LuaFnGetToyTip(nToyID)
	if nTip == 1 then
		bar:GetSubItem("ToyCollection_ToyListItem_Tip"):Show()
	else
		bar:GetSubItem("ToyCollection_ToyListItem_Tip"):Hide()
	end

end

function ToyCollection_Update_CategoryList()
	
	local category_index = 0

	for i = 1, table.getn(g_Category) do
		category_index = category_index + 1
		if g_CategoryList[category_index] ~= nil then

			g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetCheck(0)
			
			if g_Category[i].fold == 1 then
				g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("NormalImage", g_Category[i].Image[1])
				g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("HoverImage", g_Category[i].Image[2])
				g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("PushedImage", g_Category[i].Image[3])
				g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("DisabledImage", g_Category[i].Image[4])
			else
				if g_CurCategory == i then
					g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetCheck(1)
				end
				g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("NormalImage", g_Category[i].epImage[1])
				g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("HoverImage", g_Category[i].epImage[2])
				g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("PushedImage", g_Category[i].epImage[3])
				g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetProperty("DisabledImage", g_Category[i].epImage[4])
			end
			
			if g_Category[i].sub_count > 0 then

				for j = 1, g_Category[i].sub_count do
					category_index = category_index + 1
					if g_CategoryList[category_index] ~= nil then						
						
						if g_CurCategory == i and g_CurSubType == j then
							g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetCheck(1)
						else
							g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetCheck(0)
						end
						
						if g_Category[i].fold == 1 then
							g_CategoryList[category_index]:Hide()
						else
							g_CategoryList[category_index]:Show()
						end
					end
				end
			end
		end
	end
end

function ToyCollection_UpdateCategoryCheckState()
	
	if g_IsCheckClicked == 1 then
		g_IsCheckClicked = 0
		return
	end
	
	local category_index = 0

	for i = 1, table.getn(g_Category) do
		category_index = category_index + 1
		if g_CategoryList[category_index] ~= nil then
			g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetCheck(0)
			
			if g_Category[i].fold == 0 and g_CurCategory == i then
				g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Btn"):SetCheck(1)
			end
			
			if g_Category[i].sub_count > 0 then
				for j = 1, g_Category[i].sub_count do
					category_index = category_index + 1
					if g_CategoryList[category_index] ~= nil then						
						
						if g_CurCategory == i and g_CurSubType == j then
							g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetCheck(1)
						else
							g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem2_Btn"):SetCheck(0)
						end
					end
				end
			end
		end
	end
end

function ToyCollection_UpdateUseButton()
	
	if g_CurSubType == 0 then
		ToyCollection_Use:Hide()
		return
	else
		ToyCollection_Use:Show()
	end
	
	if g_CurSelToyID == 0 then
		--ToyCollection_SetButtonEnable(0)
		ToyCollection_Use:SetToolTip("#{FWYJ_210318_9}")
	elseif Exterior:LuaFnIsHaveToy(g_CurSelToyID) == 1 then
		--ToyCollection_SetButtonEnable(1)
		ToyCollection_Use:SetToolTip("")		
	else
		--ToyCollection_SetButtonEnable(0)
		ToyCollection_Use:SetToolTip("#{FWYJ_210318_10}")
	end
end

function ToyCollection_UpdatePageButton()

	if g_CurSubType == 0 then
		ToyCollection_PageUp:Hide()
		ToyCollection_PageDown:Hide()
		ToyCollection_Page:Hide()
		return
	else
		ToyCollection_PageUp:Show()
		ToyCollection_PageDown:Show()
		ToyCollection_Page:Show()
	end
	
	if g_CurPage == 1 then
		ToyCollection_SetPageUpEnable(0)
	else
		ToyCollection_SetPageUpEnable(1)
	end
	
	if g_CurPage == g_MaxPage then
		ToyCollection_SetPageDownEnable(0)
	else
		ToyCollection_SetPageDownEnable(1)
	end
	
	ToyCollection_Page:SetText(tostring(g_CurPage).."/"..tostring(g_MaxPage))
end

function ToyCollection_SetButtonEnable(flag)
	if flag == 1 then
		ToyCollection_Use:SetProperty("NormalImage", "set:ToyCollection image:Use_Normal")
		ToyCollection_Use:SetProperty("HoverImage", "set:ToyCollection image:Use_Hover")
		ToyCollection_Use:SetProperty("PushedImage", "set:ToyCollection image:Use_Pushed")
	else
		ToyCollection_Use:SetProperty("NormalImage", "set:ToyCollection image:Use_Disabled")
		ToyCollection_Use:SetProperty("HoverImage", "set:ToyCollection image:Use_Disabled")
		ToyCollection_Use:SetProperty("PushedImage", "set:ToyCollection image:Use_Disabled")
	end	
end

function ToyCollection_SetPageUpEnable(flag)
	if flag == 1 then
		ToyCollection_PageUp:SetProperty("NormalImage", "set:ToyCollection image:Last_Normal")
		ToyCollection_PageUp:SetProperty("HoverImage", "set:ToyCollection image:Last_Hover")
		ToyCollection_PageUp:SetProperty("PushedImage", "set:ToyCollection image:Last_Pushed")
	else
		ToyCollection_PageUp:SetProperty("NormalImage", "set:ToyCollection image:Last_Disabled")
		ToyCollection_PageUp:SetProperty("HoverImage", "set:ToyCollection image:Last_Disabled")
		ToyCollection_PageUp:SetProperty("PushedImage", "set:ToyCollection image:Last_Disabled")
	end	
end

function ToyCollection_SetPageDownEnable(flag)
	if flag == 1 then
		ToyCollection_PageDown:SetProperty("NormalImage", "set:ToyCollection image:Next_Normal")
		ToyCollection_PageDown:SetProperty("HoverImage", "set:ToyCollection image:Next_Hover")
		ToyCollection_PageDown:SetProperty("PushedImage", "set:ToyCollection image:Next_Pushed")
	else
		ToyCollection_PageDown:SetProperty("NormalImage", "set:ToyCollection image:Next_Disabled")
		ToyCollection_PageDown:SetProperty("HoverImage", "set:ToyCollection image:Next_Disabled")
		ToyCollection_PageDown:SetProperty("PushedImage", "set:ToyCollection image:Next_Disabled")
	end	
end

function ToyCollection_UnfoldCatetory(category)
	
	if g_Category[category] ~= nil then	
		if g_Category[category].fold == 1 then
			for i = 1, table.getn(g_Category) do
				g_Category[i].fold = 1
			end
			g_Category[category].fold = 0
			ToyCollection_ShowCategory(category, 1)
		else
			g_Category[category].fold = 1
			ToyCollection_ShowCategory(category, 0)
		end
		--ToyCollection_Update_CategoryList()
		
		ToyCollection_CategoryList:RefreshLayout()
	end
end

function ToyCollection_ShowCategory(category, subtype)

	g_IsCheckClicked = 1
	
	if g_CurCategory == category and g_CurSubType == subtype then
		return
	end
	
	g_CurCategory = category
	g_CurSubType = subtype
	
	ToyCollection_Update_CategoryList()
	
	--玩具列表
	g_CurSelToyID = 0
	
	g_CurPage = 1
	g_NeedChangeScrollSize = 1
	ToyCollection_UpdatToyeList()

	ToyCollection_UpdateUseButton()
	
	ToyCollection_UpdatePageButton()
end

function ToyCollection_ToyClicked(nIndex)
	
	local nToyID = Exterior:LuaFnGetToyIDFromList(nIndex - 1)
	if g_CurSelToyID ~= nToyID then
		
		g_CurSelToyID = nToyID		
		ToyCollection_SetToySelected(nIndex)
		ToyCollection_RemoveTip(g_CurSelToyID)
		ToyCollection_UpdateRedPoint()
		ToyCollection_UpdateUseButton()
	end
end

function ToyCollection_SetToySelected(nIndex)
	for i = 1, g_MaxToyPerPage do		
		if g_ToyItemList[i] ~= nil then		
			local ctrlAction = g_ToyItemList[i]:GetSubItem("ToyCollection_ToyListItem_Action")
			if ctrlAction ~= nil then
				if i == nIndex then
					g_ToyItemList[i]:GetSubItem("ToyCollection_ToyListItem_BK"):SetCheck(1)
					ctrlAction:SetPushed(1)
				else
					g_ToyItemList[i]:GetSubItem("ToyCollection_ToyListItem_BK"):SetCheck(0)
					ctrlAction:SetPushed(0)	
				end
			end
		end
	end
end

function ToyCollection_UseToy()
	if g_CurSelToyID == 0 then
		PushDebugMessage("#{FWYJ_210318_13}")
		return
	end
	
	local count = Exterior:LuaFnGetToyListCount()
	for i = 1, count do
		local nToyID = Exterior:LuaFnGetToyIDFromList(i - 1)
		if nToyID == g_CurSelToyID then
			if g_ToyItemList[i] ~= nil then
				local ctrlAction = g_ToyItemList[i]:GetSubItem("ToyCollection_ToyListItem_Action")
				if ctrlAction ~= nil then
					ctrlAction:DoAction()
					return
				end
			end
		end		
	end
end

function ToyCollection_CloseClick()
	this:Hide()
end

function ToyCollection_OnHidden()	
	ToyCollection_CleanUp()
end

function ToyCollection_CleanUp()
	
	g_CurPage = 1
	g_MaxPage = 1
	for i = 1, g_MaxToyPerPage do
		if g_ToyItemList[i] then
			local ctrlAction = g_ToyItemList[i]:GetSubItem("ToyCollection_ToyListItem_Action")			
			if ctrlAction then
				ctrlAction:SetActionItem(-1)
			end
		end
	end	
	
	for i = 1, table.getn(g_Category) do
		g_Category[i].fold = 1
		g_CurCategory = i
		g_CurSubType = g_Category[i].sub_count
	end
	
	if g_CurSubType ~= 0 then
		if g_Category[g_CurCategory] ~= nil then
			g_Category[g_CurCategory].fold = 0
		end
	end
	
				
end

function ToyCollection_RemoveTip(nToyID)
	local nTip = Exterior:LuaFnGetToyTip(nToyID)
	if nTip == 1 then
		Exterior:LuaFnRemoveToyTip(nToyID)	
		for i = 1, g_MaxToyPerPage do
			if g_ToyItemList[i] then
				local nID = Exterior:LuaFnGetToyIDFromList(i - 1)
				if Exterior:LuaFnGetToyTip(nID) == 1 then
					g_ToyItemList[i]:GetSubItem("ToyCollection_ToyListItem_Tip"):Show()
				else
					g_ToyItemList[i]:GetSubItem("ToyCollection_ToyListItem_Tip"):Hide()
				end
			end
		end
	--	NewExterior_Ride_UpdateCheckButton()
	end	
end

function ToyCollection_UpdateRedPoint()
	
	local category_index = 0

	for i = 1, table.getn(g_Category) do
		category_index = category_index + 1
		if g_CategoryList[category_index] ~= nil then
			g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem_Tip"):Hide()
			if Exterior:LuaFnIsHaveToyShowTipInCategory(i, 0) == 1 then
				Category1_Bar:GetSubItem("ToyCollection_CategoryListItem_Tip"):Show()
			end
	
			if g_Category[i].sub_count > 0 then
				local Category1_Bar = g_CategoryList[category_index]
				for j = 1, g_Category[i].sub_count do
					category_index = category_index + 1
					if g_CategoryList[category_index] ~= nil then						
						g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem2_Tip"):Hide()
						if Exterior:LuaFnIsHaveToyShowTipInCategory(i, j) == 1 then
							g_CategoryList[category_index]:GetSubItem("ToyCollection_CategoryListItem2_Tip"):Show()
							Category1_Bar:GetSubItem("ToyCollection_CategoryListItem_Tip"):Show()
						end
					end
				end
			end
			
			
		end
	end
end

function ToyCollection_PageUp_Click()
	if g_CurPage <= 1 then
		return
	end
	
	g_CurPage = g_CurPage - 1
	
	g_CurSelToyID = 0
	
	ToyCollection_UpdatToyeList()
	
	--使用按钮
	ToyCollection_UpdateUseButton()
	
	ToyCollection_UpdatePageButton()
end

function ToyCollection_PageDown_Click()
	if g_CurPage >= g_MaxPage then
		return
	end
	
	g_CurPage = g_CurPage + 1
	
	g_CurSelToyID = 0
	
	ToyCollection_UpdatToyeList()
	
	--使用按钮
	ToyCollection_UpdateUseButton()
	
	ToyCollection_UpdatePageButton()
end

--!!!reloadscript =ToyCollection
