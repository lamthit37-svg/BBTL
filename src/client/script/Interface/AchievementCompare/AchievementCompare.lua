local g_UnifiedPosition = ""
local g_nAchieveCompareTypeID = {}			--成就ID
local g_nAchieveCompareType  = {} 			--成就类型
local g_nAchieveCompareContent = {}		--成就内容
local g_nAchieveCompareContentGet = {}
--local g_nAchieveCompareContentGain = {}
local	g_nAchieveCompareLeftButton = {}
local g_AchieveCompareListImage = "Ach_AchIcon_Cup"
local g_AchieveCompareListImageSet = "Ach";
--local g_nRecentAchvShowNum = 50
local g_nAchieveGuangHuiTypeID = 10
--当前选中的对比成就索引
local g_nCurSelectListIndex = 1

--===============================================
-- OnLoad()
--===============================================
function AchievementCompare_PreLoad()
 this:RegisterEvent("UPDATE_ACHIEVEMENT_COMPARE")
 this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
 this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function AchievementCompare_OnLoad()
	g_UnifiedPosition = AchievementCompare:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function AchievementCompare_OnEvent( event )
	if (event == "UPDATE_ACHIEVEMENT_COMPARE") then
		if nil == arg0 or "" == arg0 then
			return
		end

		if tonumber(arg0) == 1 then --打开界面
			if (this:IsVisible()) then
				AchievementCompare_Close()
			end
			this:Show()
			g_nCurSelectListIndex = 1
			AchievementCompare_InitCharInfo()
			AchievementCompare_AchievementListUpdate()
			AchievementCompare_SetLeftButtonSelected(g_nCurSelectListIndex)		--设置选中的类型高亮
			AchievementCompare_ListContent:SetVertScrollbarPosition(0)
			AchievementCompare_AchievementUpdate(g_nCurSelectListIndex)
		elseif tonumber(arg0) == 0 then --关闭界面
			if (this:IsVisible()) then
				AchievementCompare_Close()
			end
		end

	elseif ( event == "HIDE_ON_SCENE_TRANSED") then
		--切场景，关界面
		AchievementCompare_Close()
		Achievement:ClearCompareTarget()
		return

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		if this:IsVisible() then
			AchievementCompare:SetProperty("UnifiedPosition", g_UnifiedPosition)
		end
	end
end

--更新成就分数
function AchievementCompare_InitCharInfo()
	local MyPortrait = Player:GetData( "PORTRAIT" )
	local MyName = Player:GetName()
	local TargetName,_,TargetPortrait = Achievement:GetTargetInfo()
	local MyScore,TargetScore = Achievement:GetCompletiveAchvScore()
	local TotalScore = Achievement:GetTotalAchvScore()
	local MyCount,TargetCount,TotalCount = Achievement:GetCompletiveAchvCountInType(-1,-1)

	--begin
	--取消骑术成就，还要保留成就值，只能在脚本里单写，成就ID分别为21、22、23
	if Achievement:GetAchvStatusByID(21) == true then
		MyCount = MyCount+1
		MyScore = MyScore+10
	end
	if Achievement:GetAchvStatusByID(22) == true then
        MyCount = MyCount+1
		MyScore = MyScore+10
	end
	if Achievement:GetAchvStatusByID(23) == true then
        MyCount = MyCount+1
		MyScore = MyScore+20
	end

	if Achievement:GetTargetAchvStatusByID(21) == true then
		TargetCount = TargetCount+1
		TargetScore = TargetScore+10
	end
	if Achievement:GetTargetAchvStatusByID(22) == true then
        TargetCount = TargetCount+1
		TargetScore = TargetScore+10
	end
	if Achievement:GetTargetAchvStatusByID(23) == true then
        TargetCount = TargetCount+1
		TargetScore = TargetScore+20
	end
	--end

	if nil ~= MyName then
		MyName = "#cfff263"..MyName
		AchievementCompare_SelfName:SetText(MyName)
	end
	if nil ~= MyScore and nil ~= TotalScore then
		AchievementCompare_FenShu:SetText("#{CJXT_100317_04}".."#cfff263"..tostring(MyScore).."/"..tostring(TotalScore))
	end
	if nil ~= MyPortrait and '' ~= MyPortrait then
		AchievementCompare_SelfHead:SetProperty("Image", tostring(MyPortrait))
	end
	AchievementCompare_SelfAchGeted:SetText("#{CJXT_100317_09}")
	if nil ~= MyCount and nil ~= TotalCount and TotalCount ~= 0 then
		AchievementCompare_SelfPro:SetProgress(MyCount, TotalCount)
		AchievementCompare_SelfProText:SetText("#cfff263"..tostring(MyCount).."/"..tostring(TotalCount))
	end

	if nil ~= TargetName then
		TargetName = "#cfff263"..TargetName
		AchievementCompare_WanJia:SetText(TargetName)
	end
	if nil ~= TargetScore and nil ~= TotalScore then
		AchievementCompare_DeFen:SetText("#{CJXT_100317_04}".."#cfff263"..tostring(TargetScore).."/"..tostring(TotalScore))
	end
	if nil ~= TargetPortrait and '' ~= TargetPortrait then
		AchievementCompare_OtherHead:SetProperty("Image", tostring(TargetPortrait))
	end
	AchievementCompare_OtherAchGeted:SetText("#{CJXT_100317_09}")
	if nil ~= TargetCount and nil ~= TotalCount and TotalCount ~= 0 then
		AchievementCompare_OtherPro:SetProgress(TargetCount, TotalCount)
		AchievementCompare_OtherProText:SetText("#cfff263"..tostring(TargetCount).."/"..tostring(TotalCount))
	end
end

--更新成就对比
function AchievementCompare_AchievementUpdate( nIndex )
	AchievementCompare_PaiHang:CleanAllElement("AchievementCompare")
	g_nAchieveCompareContent = {}
	g_nAchieveCompareContentGet = {}
--	g_nAchieveCompareContentGain = {}

	if nIndex < 0 then
		return
	end

	if nil == g_nAchieveCompareTypeID[nIndex] or nil == g_nAchieveCompareTypeID[nIndex].typeID or nil == g_nAchieveCompareTypeID[nIndex].subtypeID then
		return
	end

		--显示最近获得成就
--	if 1 == nIndex then
--		AchievementCompare_AddAchieveContentGain()
--		AchievementCompare_ShowAchieveContentGain()
--		AchievementCompare_ListContent:Flash()
--		AchievementCompare_PaiHang:Flash()
--		return
--	end

	if true == AchievementCompare_IsSubType(nIndex) then  --如果是子类型
		AchievementCompare_AddAchieveContent(g_nAchieveCompareTypeID[nIndex].typeID,g_nAchieveCompareTypeID[nIndex].subtypeID,g_nAchieveCompareTypeID[nIndex].image)
		AchievementCompare_AddAchieveContentGet(g_nAchieveCompareTypeID[nIndex].typeID,g_nAchieveCompareTypeID[nIndex].subtypeID,g_nAchieveCompareTypeID[nIndex].image)
	else  --如果是类型
		AchievementCompare_AddAchieveContent(g_nAchieveCompareTypeID[nIndex].typeID,-1,g_nAchieveCompareTypeID[nIndex].image)
		AchievementCompare_AddAchieveContentGet(g_nAchieveCompareTypeID[nIndex].typeID,-1,g_nAchieveCompareTypeID[nIndex].image)
	end

	AchievementCompare_SortAchieveContent()
	AchievementCompare_AddAchieveGetToAchieveTable()
	AchievementCompare_ShowAchieveContent()
	AchievementCompare_ListContent:Flash()
 	AchievementCompare_PaiHang:Flash()
end

--更新成就左侧列表
function AchievementCompare_AchievementListUpdate()
	AchievementCompare_ListContent:CleanAllElement("AchievementCompare")
	AchievementCompare_ListContent:SetVertScrollbarHide()
	g_nAchieveCompareLeftButton = {}

	--最近获得成就特殊处理
	--AchievementCompare_AddCatalog("#e010101#cFDEACA".."#{CJXT_100317_05}")
	--AchievementCompare_AddID(-1,-1,"")

	--获得成就类型数量
	local nTypeCount = Achievement:GetAchvTypeCount()
	if nil == nTypeCount or nTypeCount<= 0 then
		return
	end

	for TypeIdx = 1,nTypeCount do
		--成就类型ID，名称和子类型数量
		local nTypeID = Achievement:GetAchvTypeIDByIndex(TypeIdx - 1)
		if nil ~= nTypeID and nTypeID >= 0 then
			local nTypeName,TypeImage,nSubTypeCount = Achievement:GetAchvTypeInfoByID(nTypeID)
			if nil ~= nTypeName and nil ~= nSubTypeCount  then
					AchievementCompare_AddCatalog("#e010101#cFDEACA"..nTypeName)
					AchievementCompare_AddID(nTypeID,-1,TypeImage)

					--如果含有子类型
					if nSubTypeCount >0 then
						for nSubCount = 1,nSubTypeCount do
							local nSubTypeID,nSubTypeName,subTypeImage = Achievement:GetAchvSubTypeInfoByIndex(nTypeID,nSubCount-1)
							if nil == nSubTypeID or nil == nSubTypeName or 0 > nSubTypeID or "" == nSubTypeName then
								break
							end

							AchievementCompare_AddText("#e010101#cFDEACA"..nSubTypeName)
							AchievementCompare_AddID(nTypeID,nSubTypeID,subTypeImage)
						end
					end
--				end
			end
		end
	end
end

--最近获得的成就
--function AchievementCompare_AddAchieveContentGain()
--	g_nAchieveCompareContentGain = {}
--	local nCount = Achievement:GetCompletiveAchvCount()
--	if nCount > g_nRecentAchvShowNum then
--		nCount = g_nRecentAchvShowNum
--	end
--	for nIndex = 1,nCount do
--		local nAchieveID,nAchieveTitle,_,nAchieveType,nAchieveSubType,nAchieveData,nAchieveScore,nAchievePriority = Achievement:GetCompletiveAchvInfoByIndex(nIndex-1)
--		local nStatus = Achievement:GetAchvStatusByID(nAchieveID)
--		local _, TypeImage, _ = Achievement:GetAchvTypeInfoByID(nAchieveType)
--		if nil == TypeImage then
--			TypeImage = ""
--		end
--		if true == nStatus then
--			local nAContent = {}
--				nAContent.ID 		=	nAchieveID
--				nAContent.Title 	=	nAchieveTitle
--				--nAContent.Desc 		=	nAchieveDesc
--				nAContent.Image 	=	TypeImage
--				nAContent.Type 		=	nAchieveType
--				nAContent.SubType 	=	nAchieveSubType
--				nAContent.Score 	=	nAchieveScore
--				nAContent.Data 		=	nAchieveData
--				nAContent.Priority 	=	nAchievePriority
--				table.insert(g_nAchieveCompareContentGain,nAContent)
--		end
--	end
--end

--显示最近获得的成就
--function AchievementCompare_ShowAchieveContentGain()
--	g_nAchieveContentButton = {}
--	local nCount = table.getn(g_nAchieveCompareContentGain)
--	if nCount > g_nRecentAchvShowNum then
--		nCount = g_nRecentAchvShowNum
--	end
--	for nIndex = 1,nCount do
--		AchievementCompare_AddAchieveBar(g_nAchieveCompareContentGain[nIndex])
--	end
--end

--增加成就内容
function AchievementCompare_AddAchieveContent(nTypeID,nSubTypeID,TypeImage)
	if nil == nTypeID or nil == nSubTypeID then return end
	if nSubTypeID < 0 then
		local nAchievementContentCount = Achievement:GetAchvCount()
		for nIndex = 1,nAchievementContentCount do
			local nAchieveID,nAchieveTitle,_,nAchieveType,nAchieveSubType,nAchieveData,nAchieveScore,nAchievePriority = Achievement:GetAchvInfoByIndex(nIndex-1)
			if nil ~= nAchieveID and nTypeID == nAchieveType then
				if g_nAchieveGuangHuiTypeID ~= nTypeID then
					local nAContent = {}
					local nStatus = Achievement:GetAchvStatusByID(nAchieveID)
					if false == nStatus then
						nAContent.ID 		=	nAchieveID
						nAContent.Title 	=	nAchieveTitle
						--nAContent.Desc 		=	nAchieveDesc
						nAContent.Image 	=	TypeImage
						nAContent.Type 		=	nAchieveType
						nAContent.SubType 	=	nAchieveSubType
						nAContent.Score 	=	nAchieveScore
						nAContent.Data 		=	nAchieveData
						nAContent.Priority 	=	nAchievePriority
						table.insert(g_nAchieveCompareContent,nAContent)
					end
				end
			end
		end
	else
		local nAchievementContentCount = Achievement:GetAchvCount()
		for nIndex = 1,nAchievementContentCount do
			local nAchieveID,nAchieveTitle,_,nAchieveType,nAchieveSubType,nAchieveData,nAchieveScore,nAchievePriority = Achievement:GetAchvInfoByIndex(nIndex-1)
			if nil ~= nAchieveID and nTypeID == nAchieveType and nSubTypeID == nAchieveSubType then
				if g_nAchieveGuangHuiTypeID ~= nTypeID then
					local nAContent = {}
					local nStatus = Achievement:GetAchvStatusByID(nAchieveID)
					if false == nStatus then
						nAContent.ID 		=	nAchieveID
						nAContent.Title 	=	nAchieveTitle
						--nAContent.Desc 		=	nAchieveDesc
						nAContent.Image 	=	TypeImage
						nAContent.Type 		=	nAchieveType
						nAContent.SubType 	=	nAchieveSubType
						nAContent.Score 	=	nAchieveScore
						nAContent.Data 		=	nAchieveData
						nAContent.Priority 	=	nAchievePriority
						table.insert(g_nAchieveCompareContent,nAContent)
					end
				end
			end
		end
	end
end

function AchievementCompare_AddAchieveContentGet(nTypeID,nSubTypeID,TypeImage)
	g_nAchieveCompareContentGet = {}
	local nAchieveGetNum = 0;
	nAchieveGetNum = Achievement:InitCompletiveAchvListInType(nTypeID,nSubTypeID);
	if nil == nAchieveGetNum or nAchieveGetNum <= 0 then
		return
	end

	for nAchieveGetIndex = 0,(nAchieveGetNum - 1) do
		local nAchieveGetID = Achievement:GetCompletiveAchvIDByIndexInType(nAchieveGetIndex)
		local nAchieveID,nAchieveTitle,_,nAchieveType,nAchieveSubType,nAchieveData,nAchieveScore,nAchievePriority = Achievement:GetAchvInfoByID(nAchieveGetID)
		if nil ~= nAchieveID then
			local nAContent = {}
			nAContent.ID 		=	nAchieveID
			nAContent.Title 	=	nAchieveTitle
			--nAContent.Desc 		=	nAchieveDesc
			nAContent.Image 	=	TypeImage
			nAContent.Type 		=	nAchieveType
			nAContent.SubType 	=	nAchieveSubType
			nAContent.Score 	=	nAchieveScore
			nAContent.Data 		=	nAchieveData
			nAContent.Priority 	=	nAchievePriority
			table.insert(g_nAchieveCompareContentGet,nAContent)
		end
	end
	Achievement:ClearCompletiveAchvListInType()
end

--对需要显示的成就进行优先级排序
function AchievementCompare_SortAchieveContent()
	local IsPriorityHigher = function( a, b )
								if a.Priority == b.Priority  then
									return ( a.ID < b.ID )
								end
								return ( a.Priority < b.Priority )
							  end
	table.sort( g_nAchieveCompareContent, IsPriorityHigher )
end

--将某类型按时间排好序的已获得成就添加到显示table中
function AchievementCompare_AddAchieveGetToAchieveTable()
	local nAchieveGetNum = table.getn(g_nAchieveCompareContentGet)
	if nil == nAchieveGetNum or nAchieveGetNum <=0 then
		return
	end

	for nAchieveGetIndex = nAchieveGetNum,1,-1 do
		if nil ~= g_nAchieveCompareContentGet[nAchieveGetIndex] and nil ~= g_nAchieveCompareContentGet[nAchieveGetIndex].ID then
			table.insert(g_nAchieveCompareContent,1,g_nAchieveCompareContentGet[nAchieveGetIndex])
		end
	end
end

--显示成就内容
function AchievementCompare_ShowAchieveContent()
	local nCount = table.getn(g_nAchieveCompareContent)
	for nIndex = 1,nCount do
		AchievementCompare_AddAchieveBar(g_nAchieveCompareContent[nIndex])
	end
end

--增加一个成就内容控件
function AchievementCompare_AddAchieveBar(nAContent)
	if nil == nAContent then
		return
	end

	if nil == nAContent.Title or nil == nAContent.Score then
		return
	end

	local nAchieveStatus = Achievement:GetAchvStatusByID(nAContent.ID)
	local nTextColor = ""
	if true == nAchieveStatus then
		nTextColor = "#e010101#c80CF8D"
	elseif false == nAchieveStatus then
		nTextColor = "#e010101#cABBDC7"
	end

	local AchieveBar = AchievementCompare_PaiHang:AddItemElement( "AchievementBarIntegrationCompare", "LEFT", "AchievementCompare","" ,"")
	--AchieveBar:SetProperty("AchievementBarCompareWindowIntegrationButtonHover","AchievementHoverSection")
	AchieveBar:SetIntegrationBarName(nTextColor..nAContent.Title);

	if nil ~= nAContent.Image and "" ~= nAContent.Image then
		local sPos,_ = string.find(nAContent.Image," ");
		local IconImageSet = string.sub(nAContent.Image,5,sPos-1);
		local IconIamge = string.sub(nAContent.Image,sPos+7)
		if nil ~= IconImageSet and nil ~= IconIamge then
			AchieveBar:SetIntegrationBarIconImage(IconImageSet,IconIamge)
			AchieveBar:SetIntegrationBarComparePointImage(IconImageSet,IconIamge)
		end
	end

	if true == nAchieveStatus then
		local nAchieveEndDate = Achievement:GetAchvDateByID(nAContent.ID)
		if nil ~= nAchieveEndDate then
			local strDate = string.sub(nAchieveEndDate,1,4).."/"..string.sub(nAchieveEndDate,5,6).."/"..string.sub(nAchieveEndDate,7,8)
			AchieveBar:SetIntegrationBarDateText("#e010101#c7ED090"..strDate)
			AchieveBar:SetIntegrationBarDateShow()
			AchieveBar:SetIntegrationBarProgressHide()
		else
			AchieveBar:SetIntegrationBarDateHide()
		end
		AchieveBar:SetIntegrationBarPointDisImageHide()
		AchieveBar:SetAchvGetedShow()
	elseif false == nAchieveStatus then
--		if nAContent.Data >0 then
--			local nAchieveProgress = Player:GetPlayerAchieveProgress(nAContent.ID)
--			AchieveBar:SetIntegrationBarProgress(nAchieveProgress,nAContent.Data)
--			AchieveBar:SetIntegrationBarProgressName(nTextColor..nAchieveProgress.."/"..nAContent.Data)
--			AchieveBar:SetIntegrationBarProgressShow()
--			AchieveBar:SetIntegrationBarDateHide()
--		else
			AchieveBar:SetIntegrationBarDateHide()
			AchieveBar:SetIntegrationBarProgressHide()
--		end
		AchieveBar:SetIntegrationBarPointDisImageShow()
		AchieveBar:SetAchvGetedHide()
	end

	local nAchieveCompareStatus = Achievement:GetTargetAchvStatusByID(nAContent.ID)
	local nTextColor = ""
	if true == nAchieveCompareStatus then
		nTextColor = "#e010101#c80CF8D"
	elseif false == nAchieveCompareStatus then
		nTextColor = "#e010101#cABBDC7"
	end
	if true == nAchieveCompareStatus then
		AchieveBar:SetIntegrationBarCompareName(nTextColor.."#{CJXT_100317_11}")
		AchieveBar:SetIntegrationBarCompareIconDisImageHide()
	elseif false == nAchieveCompareStatus then
		AchieveBar:SetIntegrationBarCompareName(nTextColor.."#{CJXT_100317_12}")
		AchieveBar:SetIntegrationBarCompareIconDisImageShow()
	end
	AchieveBar:SetIntegrationBarCompareProgressHide()
	AchieveBar:SetIntegrationBarPointImageHide()
	AchieveBar:SetIntegrationBarCompareFinishNameHide()
	AchieveBar:SetIntegrationBarCompareProgressNameHide()
end

--增加成就类型ID和子类型ID数据
function AchievementCompare_AddID(nTypeID,nSubTypeID,TypeImage)
	local nItem = {}
	nItem.typeID = nTypeID
	nItem.subtypeID = nSubTypeID
	nItem.image = TypeImage
	table.insert(g_nAchieveCompareTypeID,nItem)
end

--增加类型控件
function AchievementCompare_AddCatalog(nText)
	local ListContentCatalog = AchievementCompare_ListContent:AddItemElement( "AchievementCatalog", "LEFT", "AchievementCompare","" ,"")
	ListContentCatalog:SetProperty("AchievementWindowCatalogButtonHover","AchievementHoverSection")
	ListContentCatalog:AddTextCatalogTextAndImage(nText,g_AchieveCompareListImage,g_AchieveCompareListImageSet)
	table.insert(g_nAchieveCompareLeftButton,ListContentCatalog)
end

--增加子类型控件
function AchievementCompare_AddText(nText)
	local AchievementText = AchievementCompare_ListContent:AddItemElement("AchievementText","LEFT","AchievementCompare","","")
	AchievementText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	AchievementText:AddTextTextAndImage(nText,"","")
	AchievementText:Hide()	--子类型开始不显示
	table.insert(g_nAchieveCompareLeftButton,AchievementText)
end

function AchievementCompare_OnHide()
end

function AchievementCompare_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local g_nCurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if g_nCurClickIndex + 1 > 0 then
		g_nCurSelectListIndex =	g_nCurClickIndex + 1;
	else
		return
	end
	AchievementCompare_SetLeftButtonSelected(g_nCurSelectListIndex)		--设置选中的类型高亮
	AchievementCompare_AchievementUpdate(g_nCurSelectListIndex)
end

--判断当前选中的类型是不是子类型
function AchievementCompare_IsSubType(nIndex)
	if nIndex < 0 then return false end
	if g_nAchieveCompareTypeID[nIndex].typeID and g_nAchieveCompareTypeID[nIndex].subtypeID and g_nAchieveCompareTypeID[nIndex].typeID >=0 and g_nAchieveCompareTypeID[nIndex].subtypeID >=0 then
		return true;
	else
		return false;
	end
end

function AchievementCompare_ChengJiu_OnItemClick()
end

function AchievementCompare_SetLeftButtonSelected(nIndex)
	if nIndex <= 0 then return end
	for BtnIndex = 1,table.getn(g_nAchieveCompareLeftButton) do
		if nil ~= g_nAchieveCompareTypeID[BtnIndex] and nil ~= g_nAchieveCompareTypeID[BtnIndex].subtypeID  and nil ~= g_nAchieveCompareLeftButton[BtnIndex] then
			if g_nAchieveCompareTypeID[BtnIndex].subtypeID <0 then		--如果是一级目录
				if nIndex == BtnIndex then
					g_nAchieveCompareLeftButton[BtnIndex]:SetCatalogButtonSelect(true);
				else
					g_nAchieveCompareLeftButton[BtnIndex]:SetCatalogButtonSelect(false);
				end
			elseif g_nAchieveCompareTypeID[BtnIndex].subtypeID >= 0 then	--如果是二级目录
				if nIndex == BtnIndex then
					g_nAchieveCompareLeftButton[BtnIndex]:SetTextCatalogSelected(true)
				else
					g_nAchieveCompareLeftButton[BtnIndex]:SetTextCatalogSelected(false)
					if g_nAchieveCompareTypeID[BtnIndex].typeID ~= g_nAchieveCompareTypeID[nIndex].typeID then
						g_nAchieveCompareLeftButton[BtnIndex]:Hide()
					end
				end
			end
		end
	end
end

function AchievementCompare_Close()
	this:Hide()
  AchievementCompare_ListContent:CleanAllElement("AchievementCompare")
  AchievementCompare_PaiHang:CleanAllElement("AchievementCompare")
	--清空显示数据
	g_nAchieveCompareContent = {}
	g_nAchieveCompareContentGet = {}
	g_nAchieveCompareContentGain = {}
	g_nCurSelectListIndex = 1
end
