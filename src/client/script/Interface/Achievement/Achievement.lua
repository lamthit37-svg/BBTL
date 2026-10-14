local g_UnifiedPosition = ""
local g_nCurSelectListIndex = 1	--当前选中的列表项
local g_CurSelectAchvIndex = 1
local g_ListScrollbarPos = 0.0
local g_nAchieveTypeID = {}			--成就ID
local g_nAchieveContent = {}		--成就内容
local g_nAchieveContentGain = {}	--最近获得成就内容
local g_nAchieveContentGet = {}		--该类型成就中已经获得的成就
local g_nAchieveContentButton = {}		--成就内容bar
local g_nAchieveLeftButton = {}			--左侧列表
local g_AchieveListImage = "Ach_AchIcon_Cup"
local g_AchieveListImageSet = "Ach"
local g_nAchieveGuangHuiTypeID = 10
local g_nRecentAchvShowNum = 50		--显示最近获得成就的最大数目
local g_TypeProgress = {}
local g_TotalAchvScore = 0
local g_TotalAchvCount = 0
local g_AchievePointIconImages = {
																	[1] = {set="Ach_Fen", image="Ach_Fen_10"},
																	[2] = {set="Ach_Fen", image="Ach_Fen_20"},
																	[3] = {set="Ach_Fen", image="Ach_Fen_30"},
																	[4] = {set="Ach_Fen", image="Ach_Fen_40"},
																	[5] = {set="Ach_Fen", image="Ach_Fen_50"},
																	[10] = {set="Ach_Fen", image="Ach_Fen_100"},
																}

--===============================================
-- OnLoad()
--===============================================
function AchievementFrame_PreLoad()
	this:RegisterEvent("OPEN_ACHIEVEMENT")
	this:RegisterEvent("UPDATE_ACHIEVEMENT")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function AchievementFrame_OnLoad()
	g_UnifiedPosition = AchievementFrame:GetProperty("UnifiedPosition")
	g_TotalAchvCount = Achievement:GetActiveAchvCount()
	g_TotalAchvScore = Achievement:GetTotalAchvScore()
end

--===============================================
-- OnEvent()
--===============================================
function AchievementFrame_OnEvent( event )

	if( event == "OPEN_ACHIEVEMENT") then
		--打开成就界面

		local AchievementID = -1
		if nil ~= arg0 and "" ~= arg0 then
			AchievementID = tonumber(arg0)
		end

		AchievementFrame_Close()
		AchievementFrame_AchievementScore()
		this:Show()

		--更新左侧成就列表
		AchievementFrame_AchievementListUpdate()

		if AchievementID >= 0 then    --达成某项成就时，从提示框打开成就界面
			--获得左侧列表中的位置索引
			local nIndex,nSubIndex = AchievementFrame_GetLeftIndex(AchievementID)
			if nIndex > 0 then
				g_nCurSelectListIndex = nIndex
			else
				g_nCurSelectListIndex = 1
			end
			AchievementFrame_SetLeftButtonSelected(g_nCurSelectListIndex)
			g_ListScrollbarPos = AchievementFrame_CalcListScrollPos(g_nCurSelectListIndex)
			AchievementFrame_ListContent:SetVertScrollbarPosition(g_ListScrollbarPos)

			--更新右侧成就内容
			g_CurSelectAchvIndex = 1
			AchievementFrame_AchievementUpdate(g_nCurSelectListIndex, AchievementID)
			AchievementFrame_SetButtonSelected(g_CurSelectAchvIndex)
			AchievementFrame_ChengJiu:SetVertScrollbarPosition((g_CurSelectAchvIndex - 1) * 69)
			AchievementFrame_ChengJiu:Flash()
		elseif AchievementID == -1 then   --从成就按钮打开成就界面
			g_nCurSelectListIndex = 1		--默认显示最近完成
			g_ListScrollbarPos = 0.0

			--设置当前查看成就高亮
			AchievementFrame_SetLeftButtonSelected(g_nCurSelectListIndex)
		  AchievementFrame_ListContent:SetVertScrollbarPosition(g_ListScrollbarPos)
			AchievementFrame_AchievementUpdate(g_nCurSelectListIndex, -1)
			AchievementFrame_ClearButtonSelectedDesc()
		end

	elseif ( event == "UPDATE_ACHIEVEMENT") then
		--更新成就界面

		if (true ~= this:IsVisible()) then
			return
		end

		local AchievementID = -1
		local IsDone = 0
		if nil ~= arg0 and "" ~= arg0 and nil ~= arg1 and "" ~= arg1 then
			AchievementID = tonumber(arg0)
			IsDone = tonumber(arg1)
		else
			return
		end

		if -1 == AchievementID then
			return
		end

		if IsDone == 1 then
				AchievementFrame_AchievementScore()
		end

		if g_nCurSelectListIndex == 1 then
			if IsDone == 1 then
				AchievementFrame_AchievementUpdate(g_nCurSelectListIndex, -1)
				AchievementFrame_SetButtonSelected(1)
				AchievementFrame_ChengJiu:SetVertScrollbarPosition(0)
			end
		elseif g_nCurSelectListIndex == 2 then
			if IsDone == 1 then
				AchievementFrame_AchievementUpdate(g_nCurSelectListIndex, -1)
			end
		else
			local IsShow = false
			local Count = table.getn(g_nAchieveContent)
			local ShowIndex = -1
			for Index = 1,Count do
				if AchievementID == g_nAchieveContent[Index].ID then
					IsShow = true
					ShowIndex = Index
					break
				end
			end

			if IsShow == false then
				return
			end

			if IsDone == 1 then
				--更新右侧成就内容
				AchievementFrame_AchievementUpdate(g_nCurSelectListIndex, -1)
				AchievementFrame_SetButtonSelected(1)
				AchievementFrame_ChengJiu:SetVertScrollbarPosition(0)
			else
				if -1 == ShowIndex or nil == g_nAchieveContentButton[ShowIndex] then
					return
				end
				if g_nAchieveContent[ShowIndex].Data > 0 then
					local nAchieveProgress = Achievement:GetAchvProgressByID(g_nAchieveContent[ShowIndex].ID)
					g_nAchieveContentButton[ShowIndex]:SetPorgressStep(nAchieveProgress, g_nAchieveContent[ShowIndex].Data)
					g_nAchieveContentButton[ShowIndex]:AddBarProgressName("#e010101#cFFD890"..nAchieveProgress.."/"..g_nAchieveContent[ShowIndex].Data)
				end
			end
			AchievementFrame_ChengJiu:Flash()
		end

	elseif ( event == "HIDE_ON_SCENE_TRANSED") then
		--切场景，关界面
		AchievementFrame_Close()
		return

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		if this:IsVisible() then
			AchievementFrame:SetProperty("UnifiedPosition", g_UnifiedPosition)
		end
	end
end


function AchievementFrame_OnHide()
  AchievementFrame_ListContent:CleanAllElement("AchievementFrame")
  AchievementFrame_ChengJiu:CleanAllElement("AchievementFrame")
  g_nAchieveLeftButton = {}
  g_nAchieveContentButton = {}

	--清空显示数据
	g_nAchieveTypeID = {}
	g_TypeProgress = {}
	g_nAchieveContent = {}		--成就内容
	g_nAchieveContentGain = {}	--最近获得成就内容
	g_nAchieveContentGet = {}	--该类型成就中已经获得的成就
end


function AchievementFrame_Close()
	this:Hide()
  AchievementFrame_ListContent:CleanAllElement("AchievementFrame")
  AchievementFrame_ChengJiu:CleanAllElement("AchievementFrame")
  g_nAchieveLeftButton = {}
  g_nAchieveContentButton = {}

	--清空显示数据
	g_nAchieveTypeID = {}
	g_TypeProgress = {}
	g_nAchieveContent = {}		--成就内容
	g_nAchieveContentGain = {}	--最近获得成就内容
	g_nAchieveContentGet = {}	--该类型成就中已经获得的成就
end


--更新成就分数
function AchievementFrame_AchievementScore()
--取消骑术成就，还要保留成就值，只能在脚本里单写，成就ID分别为21、22、23
    local nReCount = 0
	local nReNumber = 0
	if Achievement:GetAchvStatusByID(21) == true then
		nReCount = nReCount+1
		nReNumber = nReNumber+10
	end
	if Achievement:GetAchvStatusByID(22) == true then
        nReCount = nReCount+1
		nReNumber = nReNumber+10
	end
	if Achievement:GetAchvStatusByID(23) == true then
        nReCount = nReCount+1
		nReNumber = nReNumber+20
	end

	local compCount = Achievement:GetCompletiveAchvCount()
	AchievementFrame_GetedAchNumber:SetText("#{CJXT_100317_09}#cfff263" .. tostring(compCount+nReCount) .. "/" .. tostring(g_TotalAchvCount))

	local MyScore,_ = Achievement:GetCompletiveAchvScore()
	if nil == MyScore or MyScore < 0 or g_TotalAchvScore < 0 then
		return
	end
	AchievementFrame_FenShu:SetText("#{CJXT_100317_04}#cfff263" .. tostring(MyScore+nReNumber).. "/" .. tostring(g_TotalAchvScore))
end


--更新成就内容
function AchievementFrame_AchievementUpdate(nIndex, curID)
	AchievementFrame_ChengJiu:CleanAllElement("AchievementFrame")
	g_nAchieveContent = {}
	g_nAchieveContentGain = {}
	g_nAchieveContentGet = {}
	g_nAchieveContentButton = {}
	if nIndex < 0 then
		return
	end

	if nil == g_nAchieveTypeID[nIndex] or nil == g_nAchieveTypeID[nIndex].typeID or nil == g_nAchieveTypeID[nIndex].subtypeID then
		return
	end

	--最近获得成就
	if 1 == nIndex then
		AchievementFrame_AddAchieveContentGain()
		AchievementFrame_ShowAchieveContentGain()
		AchievementFrame_ListContent:Flash()
		AchievementFrame_ChengJiu:Flash()
		return
	end

	--显示总览
	if 2 == nIndex then
		AchievementFrame_ShowAchieveContentSummary()
		AchievementFrame_ListContent:Flash()
		AchievementFrame_ChengJiu:Flash()
		return
	end

	if true == AchievementFrame_IsSubType(nIndex) then  --如果是子类型
		AchievementFrame_AddAchieveContent(g_nAchieveTypeID[nIndex].typeID,g_nAchieveTypeID[nIndex].subtypeID,g_nAchieveTypeID[nIndex].image)
		AchievementFrame_AddAchieveContentGet(g_nAchieveTypeID[nIndex].typeID,g_nAchieveTypeID[nIndex].subtypeID,g_nAchieveTypeID[nIndex].image)
	else  --如果是类型
		AchievementFrame_AddAchieveContent(g_nAchieveTypeID[nIndex].typeID,-1,g_nAchieveTypeID[nIndex].image)
		AchievementFrame_AddAchieveContentGet(g_nAchieveTypeID[nIndex].typeID,-1,g_nAchieveTypeID[nIndex].image)
	end
	AchievementFrame_SortAchieveContent()
	AchievementFrame_AddAchieveGetToAchieveTable()
	AchievementFrame_ShowAchieveContent(curID)
	AchievementFrame_ListContent:Flash()
 	AchievementFrame_ChengJiu:Flash()
end


--更新成就左侧列表
function AchievementFrame_AchievementListUpdate()
	AchievementFrame_ListContent:CleanAllElement("AchievementFrame")
	AchievementFrame_ListContent:SetVertScrollbarHide()
	g_nAchieveLeftButton = {}
	g_nAchieveTypeID = {}

	--最近获得成就
	AchievementFrame_AddCatalog("#e010101#cFDEACA".."#{CJXT_100317_05}")
	AchievementFrame_AddID(-1,-1,"")

	--总览
	AchievementFrame_AddCatalog("#e010101#cFDEACA".."#{CJXT_100317_10}")
	AchievementFrame_AddID(-1,-1,"")

	local nTypeCount = Achievement:GetAchvTypeCount()
	if nil == nTypeCount or nTypeCount<= 0 then
		return
	end

	for TypeIdx = 1,nTypeCount do
		local nTypeID = Achievement:GetAchvTypeIDByIndex(TypeIdx - 1)
		if nil ~= nTypeID and nTypeID >= 0 then
			local nTypeName,TypeImage,nSubTypeCount = Achievement:GetAchvTypeInfoByID(nTypeID)
			if nil ~= nTypeName and nil ~= nSubTypeCount then
				AchievementFrame_AddCatalog("#e010101#cFDEACA"..nTypeName)
				AchievementFrame_AddID(nTypeID,-1,TypeImage)
				--如果含有子类型
				if nSubTypeCount >0 then
					for nSubCount = 1,nSubTypeCount do
						local nSubTypeID,nSubTypeName,subTypeImage = Achievement:GetAchvSubTypeInfoByIndex(nTypeID,nSubCount-1)
						if nil == nSubTypeID or nil == nSubTypeName or 0 > nSubTypeID or "" == nSubTypeName then
							break
						end
						AchievementFrame_AddText("#e010101#cFDEACA"..nSubTypeName)
						AchievementFrame_AddID(nTypeID,nSubTypeID,subTypeImage)
					end
				end
			end
		end
	end
end


--根据成就ID，获得左侧列表的索引
function AchievementFrame_GetLeftIndex(nAchievementID)
	if nAchievementID < 0 then
		return
	end

	local nTypeIndex = -1
	local nSubTypeIndex = -1
	local ID,_,_,nType,nSubType,_,_,_ = Achievement:GetAchvInfoByID(nAchievementID)
	if nil == ID or ID < 0 then
		return
	end

	for nIndex = 1,table.getn(g_nAchieveTypeID) do
		if nSubType < 0 then
			if g_nAchieveTypeID[nIndex].typeID == nType then
				nTypeIndex = nIndex
				nSubTypeIndex = -1
				break
			end
		else
			if g_nAchieveTypeID[nIndex].typeID == nType then
				if	g_nAchieveTypeID[nIndex].subtypeID == -1 then
					nTypeIndex = nIndex
				elseif g_nAchieveTypeID[nIndex].subtypeID == nSubType then
					nSubTypeIndex = nIndex
					break
				end
			end
		end
	end
	if nTypeIndex <= 0 or nTypeIndex > table.getn(g_nAchieveTypeID) or nSubTypeIndex > table.getn(g_nAchieveTypeID) then
		nTypeIndex = 1
		nSubTypeIndex = -1
	end

	return nTypeIndex, nSubTypeIndex
end


--根据成就ID，获得成就显示的索引
function AchievementFrame_GetShowIndex(nAchievementID)
	local nShowIndex = -1
	for nIndex = 1,table.getn(g_nAchieveContent) do
		if nAchievementID == g_nAchieveContent[nIndex].ID then
			nShowIndex = nIndex
			break
		end
	end
	if nShowIndex <= 0 or nShowIndex > table.getn(g_nAchieveContent) then
		nShowIndex = 1
	end
	return nShowIndex
end


--最近获得的成就
function AchievementFrame_AddAchieveContentGain()
	g_nAchieveContentGain = {}
	local nCount = Achievement:GetCompletiveAchvCount()
	if nCount > g_nRecentAchvShowNum then
		nCount = g_nRecentAchvShowNum
	end
	for nIndex = 1,nCount do
		local nAchieveID,nAchieveTitle,nAchieveDesc,nAchieveType,nAchieveSubType,nAchieveData,nAchieveScore,nAchievePriority = Achievement:GetCompletiveAchvInfoByIndex(nIndex-1)
		local nStatus = Achievement:GetAchvStatusByID(nAchieveID)
		local _, TypeImage, _ = Achievement:GetAchvTypeInfoByID(nAchieveType)
		if nil == TypeImage then
			TypeImage = ""
		end
		if true == nStatus then
			local nAContent = {}
				nAContent.ID 		=	nAchieveID
				nAContent.Title 	=	nAchieveTitle
				nAContent.Desc 		=	nAchieveDesc
				nAContent.Image 	=	TypeImage
				nAContent.Type 		=	nAchieveType
				nAContent.SubType 	=	nAchieveSubType
				nAContent.Score 	=	nAchieveScore
				nAContent.Data 		=	nAchieveData
				nAContent.Priority 	=	nAchievePriority
				table.insert(g_nAchieveContentGain,nAContent)
		end
	end
end


--显示最近获得的成就
function AchievementFrame_ShowAchieveContentGain()
	g_nAchieveContentButton = {}
	local nCount = table.getn(g_nAchieveContentGain)
	if nCount > g_nRecentAchvShowNum then
		nCount = g_nRecentAchvShowNum
	end
	for nIndex = 1,nCount do
		AchievementFrame_AddAchieveBar(g_nAchieveContentGain[nIndex])
	end
end


--增加成就内容
function AchievementFrame_AddAchieveContent(nTypeID,nSubTypeID,TypeImage)
	if nil == nTypeID or nil == nSubTypeID then return end
	if nSubTypeID < 0 then
		local nAchievementContentCount = Achievement:GetAchvCount()
		for nIndex = 1,nAchievementContentCount do
			local nAchieveID,nAchieveTitle,nAchieveDesc,nAchieveType,nAchieveSubType,nAchieveData,nAchieveScore,nAchievePriority = Achievement:GetAchvInfoByIndex(nIndex-1)
			if nil ~= nAchieveID and nTypeID == nAchieveType then
				local nAContent = {}
				if g_nAchieveGuangHuiTypeID ~= nTypeID then		--如果是光辉成就，需要是已经完成的
					local nStatus = Achievement:GetAchvStatusByID(nAchieveID)
					if false == nStatus then
						nAContent.ID 		=	nAchieveID
						nAContent.Title 	=	nAchieveTitle
						nAContent.Desc 		=	nAchieveDesc
						nAContent.Image 	=	TypeImage
						nAContent.Type 		=	nAchieveType
						nAContent.SubType 	=	nAchieveSubType
						nAContent.Score 	=	nAchieveScore
						nAContent.Data 		=	nAchieveData
						nAContent.Priority 	=	nAchievePriority
						table.insert(g_nAchieveContent,nAContent)
					end
				end
			end
		end
	else
		local nAchievementContentCount = Achievement:GetAchvCount()
		for nIndex = 1,nAchievementContentCount do
			local nAchieveID,nAchieveTitle,nAchieveDesc,nAchieveType,nAchieveSubType,nAchieveData,nAchieveScore,nAchievePriority = Achievement:GetAchvInfoByIndex(nIndex-1)
			if nil ~= nAchieveID and nTypeID == nAchieveType and nSubTypeID == nAchieveSubType then
				local nAContent = {}
				if g_nAchieveGuangHuiTypeID ~= nTypeID then		--如果是光辉成就，需要是已经完成的
					local nStatus = Achievement:GetAchvStatusByID(nAchieveID)
					if false == nStatus then
						nAContent.ID 		=	nAchieveID
						nAContent.Title 	=	nAchieveTitle
						nAContent.Desc 		=	nAchieveDesc
						nAContent.Image 	=	TypeImage
						nAContent.Type 		=	nAchieveType
						nAContent.SubType 	=	nAchieveSubType
						nAContent.Score 	=	nAchieveScore
						nAContent.Data 		=	nAchieveData
						nAContent.Priority 	=	nAchievePriority
						table.insert(g_nAchieveContent,nAContent)
					end
				end
			end
		end
	end
end


--对需要显示的成就进行优先级排序
function AchievementFrame_SortAchieveContent()
	local IsPriorityHigher = function( a, b )
								if a.Priority == b.Priority  then
									return ( a.ID < b.ID )
								end
								return ( a.Priority < b.Priority )
							  end
	table.sort( g_nAchieveContent, IsPriorityHigher )
end


--显示成就内容
function AchievementFrame_ShowAchieveContent(SelectID)
	local nCount = table.getn(g_nAchieveContent)

	for nIndex = 1,nCount do
		AchievementFrame_AddAchieveBar(g_nAchieveContent[nIndex])
		if SelectID ~= -1 and g_nAchieveContent[nIndex].ID == SelectID then
			g_CurSelectAchvIndex = nIndex
		end
	end
end


--增加某类型已获得的成就
function AchievementFrame_AddAchieveContentGet(nTypeID,nSubTypeID,TypeImage)
	g_nAchieveContentGet = {}
	local nAchieveGetNum = 0;
	nAchieveGetNum = Achievement:InitCompletiveAchvListInType(nTypeID,nSubTypeID);
	if nil == nAchieveGetNum or nAchieveGetNum <= 0 then
		return
	end

	for nAchieveGetIndex = 0,(nAchieveGetNum - 1) do
		local nAchieveGetID = Achievement:GetCompletiveAchvIDByIndexInType(nAchieveGetIndex)
		local nAchieveID,nAchieveTitle,nAchieveDesc,nAchieveType,nAchieveSubType,nAchieveData,nAchieveScore,nAchievePriority = Achievement:GetAchvInfoByID(nAchieveGetID)
		if nil~= nAchieveID then
			local nAContent = {}
			nAContent.ID 		=	nAchieveID
			nAContent.Title 	=	nAchieveTitle
			nAContent.Desc 		=	nAchieveDesc
			nAContent.Image 	=	TypeImage
			nAContent.Type 		=	nAchieveType
			nAContent.SubType 	=	nAchieveSubType
			nAContent.Score 	=	nAchieveScore
			nAContent.Data 		=	nAchieveData
			nAContent.Priority 	=	nAchievePriority
			table.insert(g_nAchieveContentGet,nAContent)
		end
	end
	Achievement:ClearCompletiveAchvListInType()
end


--将某类型按时间排好序的已获得成就添加到显示table中
function AchievementFrame_AddAchieveGetToAchieveTable()
	local nAchieveGetNum = table.getn(g_nAchieveContentGet)
	if nil == nAchieveGetNum or nAchieveGetNum <=0 then return end
	for nAchieveGetIndex = nAchieveGetNum,1,-1 do
		if nil ~= g_nAchieveContentGet[nAchieveGetIndex] and nil ~= g_nAchieveContentGet[nAchieveGetIndex].ID then
			table.insert(g_nAchieveContent,1,g_nAchieveContentGet[nAchieveGetIndex]);
		end
	end
end


--增加一个成就内容控件
function AchievementFrame_AddAchieveBar(nAContent)

	if nil == nAContent then
		return
	end

	if nil == nAContent.Title or nil == nAContent.Desc or nil == nAContent.Score then
		return
	end

	local nAchieveStatus = Achievement:GetAchvStatusByID(nAContent.ID)
	local nTextColor = ""
	if true == nAchieveStatus then
		nTextColor = "#e010101#c80CF8D"
	elseif false == nAchieveStatus then
		nTextColor = "#e010101#cABBDC7"
	end

	local AchieveBar = AchievementFrame_ChengJiu:AddItemElement( "AchievementBar", "LEFT", "AchievementFrame","" ,"")
	AchieveBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
	AchieveBar:AddBarText(nTextColor..nAContent.Title);
	if true == nAchieveStatus then
		AchieveBar:SetPointDisImageHide()
	elseif false == nAchieveStatus then
		AchieveBar:SetPointDisImageShow()
	end

	if nil == g_AchievePointIconImages[(nAContent.Score/10)].set or nil == g_AchievePointIconImages[(nAContent.Score/10)].image then
		AchieveBar:SetBarPointImageHide()
	else
		AchieveBar:AddBarPointImage(g_AchievePointIconImages[(nAContent.Score/10)].set, g_AchievePointIconImages[(nAContent.Score/10)].image)
	end

	if nil ~= nAContent.Image and "" ~= nAContent.Image then
		local sPos,_ = string.find(nAContent.Image," ");
		local IconImageSet = string.sub(nAContent.Image,5,sPos-1);
		local IconIamge = string.sub(nAContent.Image,sPos+7)
		if nil ~= IconImageSet and nil ~= IconIamge then
			AchieveBar:AddBarIconImage(IconImageSet,IconIamge)
		end
	end

	if true == nAchieveStatus then
		local nAchieveEndDate = Achievement:GetAchvDateByID(nAContent.ID)
		if nil ~= nAchieveEndDate then
			local strDate = string.sub(nAchieveEndDate,1,4).."/"..string.sub(nAchieveEndDate,5,6).."/"..string.sub(nAchieveEndDate,7,8)
			AchieveBar:AddBarDateText("#e010101#c7ED090"..strDate)
			AchieveBar:SetDateShow()
			AchieveBar:SetProgressHide()
		else
			AchieveBar:SetDateHide()
		end
		AchieveBar:SetAchvGetedShow()
	elseif false == nAchieveStatus then
		if nAContent.Data >0 then
			local nAchieveProgress = Achievement:GetAchvProgressByID(nAContent.ID)
			AchieveBar:SetPorgressStep(nAchieveProgress,nAContent.Data)
			AchieveBar:AddBarProgressName("#e010101#cFFD890"..nAchieveProgress.."/"..nAContent.Data)
			AchieveBar:SetProgressShow()
			AchieveBar:SetDateHide()
		else
			AchieveBar:SetDateHide()
			AchieveBar:SetProgressHide()
		end
		AchieveBar:SetAchvGetedHide()
	end
	table.insert(g_nAchieveContentButton,AchieveBar);
end


--增加成就类型ID和子类型ID数据
function AchievementFrame_AddID(nTypeID,nSubTypeID,TypeImage)
	local nItem = {}
	nItem.typeID = nTypeID
	nItem.subtypeID = nSubTypeID
	nItem.image = TypeImage
	table.insert(g_nAchieveTypeID,nItem)
end


--增加类型控件
function AchievementFrame_AddCatalog(nText)
	local AchievementCatalog = AchievementFrame_ListContent:AddItemElement( "AchievementCatalog", "LEFT", "AchievementFrame","" ,"")
	AchievementCatalog:SetProperty("AchievementWindowCatalogButtonHover","AchievementHoverSection")
	AchievementCatalog:AddTextCatalogTextAndImage(nText,g_AchieveListImage,g_AchieveListImageSet)
	table.insert(g_nAchieveLeftButton,AchievementCatalog)
end


--增加子类型控件
function AchievementFrame_AddText(nText)
	local AchievementText = AchievementFrame_ListContent:AddItemElement("AchievementText","LEFT","AchievementFrame","","")
	AchievementText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	AchievementText:AddTextTextAndImage(nText,"","")
	AchievementText:Hide()		--刚开始子控件不可见
	table.insert(g_nAchieveLeftButton,AchievementText)
end


function AchievementFrame_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if CurClickIndex + 1 > 0 then
		g_nCurSelectListIndex =	CurClickIndex + 1
	else
		return
	end
	AchievementFrame_SetLeftButtonSelected(g_nCurSelectListIndex)		--设置选中的类型高亮
	AchievementFrame_AchievementUpdate(g_nCurSelectListIndex);
	AchievementFrame_ClearButtonSelectedDesc()
end


function AchievementFrame_ChengJiu_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1

	--总览页面没有点击
	if g_nCurSelectListIndex == 2 then
		return
	end

	if nIndex > 0 then
		AchievementFrame_SetButtonSelected(nIndex)
		AchievementFrame_ChengJiu:Flash()
	end
end


--判断当前选中的类型是不是子类型
function AchievementFrame_IsSubType(nIndex)
	if nIndex < 0 then return false end
	if nil ~= g_nAchieveTypeID[nIndex] and g_nAchieveTypeID[nIndex].typeID >= 0 and g_nAchieveTypeID[nIndex].subtypeID >= 0 then
		return true;
	else
		return false;
	end
end

--设置选中的子控件
function AchievementFrame_SetButtonSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_nAchieveContentButton) do
		if nil ~= g_nAchieveContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_nAchieveContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_nAchieveContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
	AchievementFrame_SetButtonSelectedDesc(nIndex)
end


--设置选中的成就的详细介绍
function AchievementFrame_SetButtonSelectedDesc(nIndex)
	local sDetailInfo
	local nID = -1

	if g_nCurSelectListIndex == 2 then  --总览界面的项目没有详细描述
		return
	end

	if g_nCurSelectListIndex == 1 then
		if nil ~= g_nAchieveContentGain[nIndex] then
			sDetailInfo = "#e010101#cfff263"..g_nAchieveContentGain[nIndex].Desc
			nID = g_nAchieveContentGain[nIndex].ID
		end
	else
		if nil ~= g_nAchieveContent[nIndex] then
			sDetailInfo = "#e010101#cfff263"..g_nAchieveContent[nIndex].Desc
			nID = g_nAchieveContent[nIndex].ID
		end
	end

	--子条件成就
	if nil == nID or nID < 0 then
		return
	end

	local nSubCount = Achievement:GetSubCondCountByID(nID)
	if nSubCount > 0 then
		local totalDone = Achievement:GetAchvStatusByID(nID)
		for nIndex = 1,nSubCount do
			local SubName, isDone = Achievement:GetAchvSubCondInfoByIndex(nID,nIndex - 1)
			if nil ~= SubName and nil ~= isDone then
				if true == totalDone or true == isDone then
					sDetailInfo = sDetailInfo.."#e010101#c80CF8D"..SubName
				else
					sDetailInfo = sDetailInfo.."#e010101#cABBDC7"..SubName
				end
				sDetailInfo = sDetailInfo.."    "
			end
		end
	end

	AchievementFrame_ContentListText:SetText(sDetailInfo)
end


--设置左侧列表中选中的目录
function AchievementFrame_SetLeftButtonSelected(nIndex)
	if nIndex <= 0 then return end
	for BtnIndex = 1,table.getn(g_nAchieveLeftButton) do
		if nil ~= g_nAchieveTypeID[BtnIndex] and nil ~= g_nAchieveLeftButton[BtnIndex] then
			if g_nAchieveTypeID[BtnIndex].subtypeID < 0 then		--如果是一级目录
				if nIndex == BtnIndex then
					g_nAchieveLeftButton[BtnIndex]:SetCatalogButtonSelect(true);
				else
					g_nAchieveLeftButton[BtnIndex]:SetCatalogButtonSelect(false);
				end
			elseif g_nAchieveTypeID[BtnIndex].subtypeID >= 0 then	--如果是二级目录
				if nIndex == BtnIndex then
					g_nAchieveLeftButton[BtnIndex]:SetTextCatalogSelected(true)
				else
					g_nAchieveLeftButton[BtnIndex]:SetTextCatalogSelected(false)
					if g_nAchieveTypeID[BtnIndex].typeID ~= g_nAchieveTypeID[nIndex].typeID then
						g_nAchieveLeftButton[BtnIndex]:Hide()
					end
				end
			end
		end
	end
end


--清空选中的成就的内容
function AchievementFrame_ClearButtonSelectedDesc()
	if nil ~= AchievementFrame_ContentListText then
		AchievementFrame_ContentListText:SetText("")
	end
end


function AchievementFrame_CalcListScrollPos(SelectIdx)
	local BtlIdx = 1
	local ShowIdx = 0
	local ShowCount = 0
	if SelectIdx > table.getn(g_nAchieveLeftButton) then
		return 0
	end
	for BtlIdx = 1, table.getn(g_nAchieveLeftButton) do
		if true == g_nAchieveLeftButton[BtlIdx]:IsVisible() then
			if BtlIdx <= SelectIdx then
				ShowIdx = ShowIdx + 1
			end
			ShowCount = ShowCount + 1
		end
	end
	if ShowCount * 30 < 346 then
		return 0
	else
		return (ShowCount * 30 - 346) * ((ShowIdx - 1) / (ShowCount - 1))
	end
end


function AchievementFrame_AddTypeProgress(inTypeID, inTypeName, inGetCount, inCountInType)
	local tmpItem = {}
	tmpItem.TypeID = inTypeID
	tmpItem.TypeName = inTypeName
	tmpItem.GetCount = tonumber(inGetCount)
	tmpItem.CountInType = tonumber(inCountInType)
	table.insert(g_TypeProgress,tmpItem)
end


--显示总览
function AchievementFrame_ShowAchieveContentSummary()
	g_TypeProgress= {}
	--统计各类成就进度
	local TypeCount = Achievement:GetAchvTypeCount()
	if nil == TypeCount or TypeCount <= 0 then
		return
	end
	for TypeIdx = 1,TypeCount do
		local TypeID = Achievement:GetAchvTypeIDByIndex(TypeIdx - 1)
		if nil ~= TypeID and TypeID >= 0 and TypeID ~= g_nAchieveGuangHuiTypeID then
			local TypeName,_ = Achievement:GetAchvTypeInfoByID(TypeID)
			if nil ~= TypeName then
				local AchieveGetNum, _,AchieveCountByType = Achievement:GetCompletiveAchvCountInType(TypeID,-1)
				if AchieveCountByType > 0 and nil ~= AchieveGetNum then
					AchievementFrame_AddTypeProgress(TypeID,TypeName,AchieveGetNum,AchieveCountByType)
				end
			end
		end
	end

	for nIndex = 1, table.getn(g_TypeProgress) do
		local AchieveBar = AchievementFrame_ChengJiu:AddItemElement( "AchievementBar", "LEFT", "AchievementFrame","" ,"")
		AchieveBar:AddBarText(g_TypeProgress[nIndex].TypeName)
		AchieveBar:SetPointDisImageHide()

		local _, TypeImage, _ = Achievement:GetAchvTypeInfoByID(g_TypeProgress[nIndex].TypeID)
		if nil ~= TypeImage and "" ~= TypeImage then
			local sPos,_ = string.find(TypeImage," ");
			local IconImageSet = string.sub(TypeImage,5,sPos-1);
			local IconIamge = string.sub(TypeImage,sPos+7)
			if nil ~= IconImageSet and nil ~= IconIamge then
				AchieveBar:AddBarIconImage(IconImageSet,IconIamge)
			end
		end
		AchieveBar:SetAchvGetedHide()
		AchieveBar:SetBarIconDisImageHide()
		AchieveBar:SetDateHide()
		AchieveBar:SetBarPointImageHide()
		AchieveBar:SetPorgressStep(g_TypeProgress[nIndex].GetCount, g_TypeProgress[nIndex].CountInType)
		AchieveBar:AddBarProgressName("#e010101#cFFD890"..tostring(g_TypeProgress[nIndex].GetCount).."/"..tostring(g_TypeProgress[nIndex].CountInType))
		AchieveBar:SetProgressShow()

		table.insert(g_nAchieveContentButton,AchieveBar)
	end
end
