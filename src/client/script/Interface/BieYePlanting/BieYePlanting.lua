-------------------------------------------------------
--家园养成材料产出玩法设计
-----------------------------------------------------------

local MAX_OBJ_DISTANCE = 3.0
local objCared = -1

local g_BieYePlanting_Index = -1--0：建筑1 1：建筑2--该参数仅传值

local g_BieYePlanting_TypeMax = 3--最大任务类型数：1：挖矿 2：养鱼 3：种树
local g_BieYePlanting_Type = 0--当前任务类型：1：挖矿 2：养鱼 3：种树

local g_BieYePlanting_LevelMax = 5--建筑等级最大值
local g_BieYePlanting_Level = 0--当前建筑等级

local g_BieYePlanting_Page = 0--默认选择的消费方式 1：金钱 2：元宝
local g_BieYePlanting_BtnIndex = 1--默认选项下标

--三种界面分别对应的静态显示内容
local g_BieYePlanting_Text = 
{
	[1] = {title="#{JYYC_160622_70}", desc="#{JYYC_160622_71}", tab1="#{JYYC_160622_147}", tab2="#{JYYC_160622_148}", content="#{JYYC_160622_73}", confirm="#{JYYC_160622_80}", timetext="#{JYYC_160622_77}", output="#{JYYC_160622_79}", star="#{JYYC_160622_167}", checktext="#{JYYC_160622_306}", checktips="#{JYYC_160622_307}", },
	[2] = {title="#{JYYC_160622_106}", desc="#{JYYC_160622_107}", tab1="#{JYYC_160622_149}", tab2="#{JYYC_160622_150}", content="#{JYYC_160622_109}", confirm="#{JYYC_160622_116}", timetext="#{JYYC_160622_113}", output="#{JYYC_160622_115}", star="#{JYYC_160622_172}", checktext="#{JYYC_160622_309}", checktips="#{JYYC_160622_310}", },
	[3] = {title="#{JYYC_160622_21}", desc="#{JYYC_160622_22}", tab1="#{JYYC_160622_142}", tab2="#{JYYC_160622_143}", content="#{JYYC_160622_24}", confirm="#{JYYC_160622_31}", timetext="#{JYYC_160622_28}", output="#{JYYC_160622_30}", star="#{JYYC_160622_159}", checktext="#{JYYC_160622_303}", checktips="#{JYYC_160622_304}", },
}

--左侧列表数据
local g_BieYePlanting_ListImage = "Ach_AchIcon_Cup"
local g_BieYePlanting_ListImageSet = "Ach"
local g_BieYePlanting_LeftButton = {}	--左侧列表控件集合（包含一级二级控件）
local g_BieYePlanting_ItemID = {}			--左侧列表数据集合（包含一级二级数据）
local g_BieYePlanting_Select = {}--默认选中列表项

--一级菜单数据：button控件 name显示内容 time代表的时间值 CurShowList当前一级菜单下的子列表是否展开
local g_BieYePlanting_ItemData = 
{
	[1] = {ctrl = nil, name = "#{JYYC_160622_144}", time = 2, CurShowList = 0, },
	[2] = {ctrl = nil, name = "#{JYYC_160622_145}", time = 6, CurShowList = 0, },
	[3] = {ctrl = nil, name = "#{JYYC_160622_146}", time = 10, CurShowList = 0, },
}

--二级菜单数据
local g_BieYePlanting_SubItemData = 
{
	[1] = {button = {}, name = {}, nID = {}, },
	[2] = {button = {}, name = {}, nID = {}, },
	[3] = {button = {}, name = {}, nID = {}, },
}

--星级显示
local g_BieYePlanting_Stars = {}

--二次确认是否按下
local g_BieYePlanting_SecConfirm = 1

function BieYePlanting_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("UPDATE_YUANBAO")
end

function BieYePlanting_OnLoad()
	g_BieYePlanting_Stars={
			BieYePlanting_Star1,
			BieYePlanting_Star2,
			BieYePlanting_Star3,
			BieYePlanting_Star4,
			BieYePlanting_Star5,
	}
	for i=1,g_BieYePlanting_LevelMax do
		g_BieYePlanting_Stars[i]:Hide()
	end
end

function BieYePlanting_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 2016062111 ) then
		local objid = Get_XParam_INT(0)
		local ntype = Get_XParam_INT(1)
		local nindex = Get_XParam_INT(2)
		local nlevel = Get_XParam_INT(3)
		--打开界面
		if ntype ~= nil and ntype > 0 and ntype <= g_BieYePlanting_TypeMax and nindex ~= nil and nindex >= 0 and nindex <= 1 and nlevel ~= nil and nlevel > 0 and nlevel <= g_BieYePlanting_LevelMax then
			--关注npc
			if objid ~= nil and objid ~= -1 then
				objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				this:CareObject(objCared, 1, "BieYePlanting")
			end
			--显示界面
			this:Show()
			g_BieYePlanting_Type = ntype--1：挖矿 2：养鱼 3：种树
			g_BieYePlanting_Index = nindex--0：建筑1 1：建筑2
			g_BieYePlanting_Level = nlevel--建筑等级	
			--更新数据
			BieYePlanting_UpdateList()
			
			--引导任务tips
			BieYePlanting_OK_Animate:Play(false)
			if ntype == 1 then
				if DataPool:Lua_IsHaveMission(1857) > 0 then
					local misIndex = DataPool:GetPlayerMissionIndexByID(1857)
					if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
						CloseFreshManGuide()	
						local fX, fY = this:GetChildOffset("BieYePlanting_OK")
						OpenFreshManGuide(1, 121, fX+40, fY+25, "BieYePlanting", "southwest")	
						BieYePlanting_OK_Animate:Play(true)
					end
				end
			elseif ntype == 3 then
				if DataPool:Lua_IsHaveMission(1858) > 0 then
					local misIndex = DataPool:GetPlayerMissionIndexByID(1858)
					if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
						CloseFreshManGuide()	
						local fX, fY = this:GetChildOffset("BieYePlanting_OK")
						OpenFreshManGuide(1, 122, fX+40, fY+25, "BieYePlanting", "southwest")	
						BieYePlanting_OK_Animate:Play(true)
					end
				end
			elseif ntype == 2 then
				if DataPool:Lua_IsHaveMission(1859) > 0 then
					local misIndex = DataPool:GetPlayerMissionIndexByID(1859)
					if DataPool:GetPlayerMission_Variable(misIndex, 1) == 0 then
						CloseFreshManGuide()	
						local fX, fY = this:GetChildOffset("BieYePlanting_OK")
						OpenFreshManGuide(1, 123, fX+40, fY+25, "BieYePlanting", "southwest")	
						BieYePlanting_OK_Animate:Play(true)
					end
				end
			end
		else
			--关闭界面
			if this:IsVisible() then
				BieYePlanting_Close()
			end
		end
  elseif ( event == "OBJECT_CARED_EVENT" ) then
		if(tonumber(arg0) ~= objCared) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--关闭界面
			BieYePlanting_Close()
		end	
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		--关闭界面
		BieYePlanting_Close()
	-- 金钱变更
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		BieYePlanting_MoneyUpdate()
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		BieYePlanting_YuanbaoUpdate()
	end
end

--=========================================================
--金钱刷新
--=========================================================
function BieYePlanting_MoneyUpdate()
	BieYePlanting_Cost_HaveJiaoZiNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	BieYePlanting_Cost_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--=========================================================
--元宝刷新
--=========================================================
function BieYePlanting_YuanbaoUpdate()
	BieYePlanting_Cost_HaveYuanBaoNum : SetText (tostring(Player:GetData("YUANBAO")))
end

--更新界面
function BieYePlanting_UpdateList()	
	if g_BieYePlanting_Index == nil or g_BieYePlanting_Index < 0 or g_BieYePlanting_Index > 1 then
		return
	end	
	if g_BieYePlanting_Type == nil or g_BieYePlanting_Type <= 0 or g_BieYePlanting_Type > g_BieYePlanting_TypeMax then
		return
	end
	if g_BieYePlanting_Level == nil or g_BieYePlanting_Level <= 0 or g_BieYePlanting_Level > g_BieYePlanting_LevelMax then
		return
	end
	
	--标题
	BieYePlanting_DragTitle:SetText( ScriptGlobal_Format( g_BieYePlanting_Text[g_BieYePlanting_Type].title, g_BieYePlanting_Index+1 ) )
	--描述
	BieYePlanting_Info:SetText( g_BieYePlanting_Text[g_BieYePlanting_Type].desc )
	--Tab内容
	BieYePlanting_Button1:SetText( g_BieYePlanting_Text[g_BieYePlanting_Type].tab1 )
	BieYePlanting_Button2:SetText( g_BieYePlanting_Text[g_BieYePlanting_Type].tab2 )	
	--详情--删除~不要了又~
	--BieYePlanting_TXT:SetText( g_BieYePlanting_Text[g_BieYePlanting_Type].content )	
	--星星
	BieYePlanting_Info2:SetText( g_BieYePlanting_Text[g_BieYePlanting_Type].star )
	--按钮
	BieYePlanting_OK:	SetText( g_BieYePlanting_Text[g_BieYePlanting_Type].confirm )	
	--金钱
	BieYePlanting_MoneyUpdate()
	--元宝
	BieYePlanting_YuanbaoUpdate()
	
	--清空页签
	g_BieYePlanting_Page = 0
	g_BieYePlanting_BtnIndex = 1
	--默认选中金钱页并切换到该页
	local nPage = 1
	BieYePlanting_SwitchPage(nPage)
end

--切换到指定页签：打开界面调用一次 页签点选调用一次
function BieYePlanting_SwitchPage( nPage )
	if nPage == nil or nPage < 1 or nPage > 2 then
		return
	end
	if g_BieYePlanting_Type == nil or g_BieYePlanting_Type <= 0 or g_BieYePlanting_Type > g_BieYePlanting_TypeMax then
		return
	end	

	--页签没变
	if nPage == g_BieYePlanting_Page then
		return
	end
	
	--取消原按钮选中
	if g_BieYePlanting_Page == 1 then
		BieYePlanting_Button1:SetCheck(0)
	elseif g_BieYePlanting_Page == 2 then
		BieYePlanting_Button2:SetCheck(0)
	end

	--新按钮选中
	if nPage == 1 then
		BieYePlanting_Button1:SetCheck(1)
	elseif nPage == 2 then
		BieYePlanting_Button2:SetCheck(1)
	end
	
	--保存当前页签
	g_BieYePlanting_Page = nPage
	
	--元宝确认
	if g_BieYePlanting_Page == 1 then
		BieYePlanting_Bk3:Hide()
	elseif g_BieYePlanting_Page == 2 then
		BieYePlanting_Bk3:Show()
		BieYePlanting_Bk3_Check_Text:SetText( g_BieYePlanting_Text[g_BieYePlanting_Type].checktext )	
		BieYePlanting_Bk3_Check:SetToolTip( g_BieYePlanting_Text[g_BieYePlanting_Type].checktips )	
		g_BieYePlanting_SecConfirm = tonumber(NpcShop:GetBieYePlantingComfirmDirectly(g_BieYePlanting_Type))
		if g_BieYePlanting_SecConfirm == 0 then
			BieYePlanting_Bk3_Check:SetCheck(1)
		else
			BieYePlanting_Bk3_Check:SetCheck(0)
		end
	end
	
	--加载当前页签下的列表数据
	BieYePlanting_LeftLoad()
	
	--计算当前默认选项
	BieYePlanting_ItemDataChanged(g_BieYePlanting_BtnIndex)--默认第一个一级菜单
end

--左侧类型加载		
function BieYePlanting_LeftLoad()
	if g_BieYePlanting_Type == nil or g_BieYePlanting_Type <= 0 or g_BieYePlanting_Type > g_BieYePlanting_TypeMax then
		return
	end
	if g_BieYePlanting_Page == nil or g_BieYePlanting_Page < 1 or g_BieYePlanting_Page > 2 then
		return
	end

	--数据清空
	BieYePlanting_Bk1:CleanAllElement("BieYePlanting")
	BieYePlanting_Bk1:SetVertScrollbarHide()
	g_BieYePlanting_LeftButton = {}
	g_BieYePlanting_ItemID = {}
	g_BieYePlanting_Select = {}--默认选中
	for i=1,table.getn(g_BieYePlanting_ItemData) do
		g_BieYePlanting_ItemData[i].ctrl = nil
	end

	--增加类型控件：按时长分类2、6、10
	for i=1,table.getn(g_BieYePlanting_ItemData) do
		BieYePlanting_AddCatalog(i)
		BieYePlanting_AddID(i,0)--0-一级菜单
		--增加子类型控件：按等级分类1-5
		for j=1,g_BieYePlanting_LevelMax do
			local	nID, szName = BieYeUI:GetMaterialOutputName(g_BieYePlanting_Page,g_BieYePlanting_Type,j,g_BieYePlanting_ItemData[i].time)
			BieYePlanting_AddText(i,j,nID,szName)
			BieYePlanting_AddID(i,j)--1-二级菜单
		end			
	end
	
	--BieYePlanting_Bk1:SetVertScrollbarPosition(g_BieYePlanting_ScrollbarPos)
	--把所有的状态置为不显示
	BieYePlanting_ClearAllShowListStatus()
	BieYePlanting_Bk1:Flash()
end

--增加类型控件
function BieYePlanting_AddCatalog(nIndex)
	if nIndex == nil or nIndex <= 0 or nIndex > table.getn(g_BieYePlanting_ItemData) then
		return
	end
	local itemCatalog = BieYePlanting_Bk1:AddItemElement( "BieYeFurniturePlant", "LEFT", "BieYePlanting","" ,"")
	itemCatalog:SetProperty("AchievementWindowCatalogButtonHover","AchievementHoverSection")
	local szText = "#e010101#cFDEACA"..g_BieYePlanting_ItemData[nIndex].name
	itemCatalog:AddTextCatalogTextAndImage(szText,g_BieYePlanting_ListImage,g_BieYePlanting_ListImageSet)
	g_BieYePlanting_ItemData[nIndex].ctrl = itemCatalog
	table.insert(g_BieYePlanting_LeftButton,itemCatalog)
end

--增加子类型控件
function BieYePlanting_AddText(nIndex,nSubIndex,nID,szName)
	if nIndex == nil or nIndex <= 0 or nIndex > table.getn(g_BieYePlanting_ItemData) then
		return
	end
	if nSubIndex == nil or nSubIndex <= 0 or nSubIndex > g_BieYePlanting_LevelMax then
		return
	end
	if g_BieYePlanting_Level == nil or g_BieYePlanting_Level <= 0 or g_BieYePlanting_Level > g_BieYePlanting_LevelMax then
		return
	end
	if nID == nil or nID <= 0 or szName == nil then
		return
	end
	
	local itemText = BieYePlanting_Bk1:AddItemElement("BieYeFurniturePlantText","LEFT","BieYePlanting","","")
	itemText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	local szText = ""
	if nSubIndex <= g_BieYePlanting_Level then 
		szText = "#e010101#cFDEACA"..szName
	else
		szText = "#c787777"..szName
	end
	itemText:AddTextTextAndImage(szText,"","")
	itemText:Hide()		--刚开始子控件不可见
	g_BieYePlanting_SubItemData[nIndex].button[nSubIndex] = itemText
	g_BieYePlanting_SubItemData[nIndex].name[nSubIndex] = szText
	g_BieYePlanting_SubItemData[nIndex].nID[nSubIndex] = nID
	table.insert(g_BieYePlanting_LeftButton,itemText)
end

--增加类型ID和子类型ID数据
function BieYePlanting_AddID(nIndex,nSubIndex)
	if nIndex == nil or nIndex <= 0 or nIndex > table.getn(g_BieYePlanting_ItemData) then
		return
	end
	if nSubIndex == nil or nSubIndex < 0 or nSubIndex > g_BieYePlanting_LevelMax then
		return
	end
	
	local nItem = {}
	nItem.nIndex = nIndex
	nItem.nSubIndex = nSubIndex
	table.insert(g_BieYePlanting_ItemID,nItem)
end

--把所有的状态置为不显示
function BieYePlanting_ClearAllShowListStatus()
	for nIndex = 1, table.getn(g_BieYePlanting_ItemData) do	
		if g_BieYePlanting_ItemData[nIndex] ~= nil and g_BieYePlanting_ItemData[nIndex].ctrl ~= nil then
			g_BieYePlanting_ItemData[nIndex].CurShowList = 0
		end
	end
end

--清除区域控件的所有状态
function BieYePlanting_ClearAllStatus()
	for nIndex = 1, table.getn(g_BieYePlanting_ItemData) do	
		--清空一级菜单选中
		if g_BieYePlanting_ItemData[nIndex].ctrl ~= nil then
			g_BieYePlanting_ItemData[nIndex].ctrl:SetCatalogButtonSelect(false)
		end
		--清空二级菜单选中		
		for nSubIndex = 1, g_BieYePlanting_LevelMax do
			if nil ~= g_BieYePlanting_SubItemData[nIndex].button[nSubIndex] then
				g_BieYePlanting_SubItemData[nIndex].button[nSubIndex]:Hide()	--子区全部隐藏
				g_BieYePlanting_SubItemData[nIndex].button[nSubIndex]:SetTextCatalogSelected(false)	--不选中
			end
		end		
	end	
end

--切换到指定选项：切换页签调用一次 点选选项调用一次
function BieYePlanting_ItemDataChanged( nBtnIndex )
	if nBtnIndex == nil or nBtnIndex <= 0 or nBtnIndex > table.getn(g_BieYePlanting_LeftButton) then 
		return
	end
	
	local nItem = g_BieYePlanting_ItemID[nBtnIndex]
	if nItem == nil then
		return
	end
	
	--记录选中项
	g_BieYePlanting_BtnIndex = nBtnIndex
	
	--清空所有状态
	BieYePlanting_ClearAllStatus()
	
	--刷新选中状态，刷新菜单对应的详细信息
	if nItem.nSubIndex == 0 then		--一级菜单	
		BieYePlanting_ItemButtonUpdate( nItem.nIndex )	
		BieYePlanting_ItemDetailUpdate( nItem.nIndex )	
	else		--二级菜单	
		BieYePlanting_SubItemButtonUpdate( nItem.nIndex, nItem.nSubIndex )	
		BieYePlanting_SubItemDetailUpdate( nItem.nIndex, nItem.nSubIndex )	
	end

	BieYePlanting_Bk1:Flash()
end

--点击一级菜单，更新一级菜单状态
function BieYePlanting_ItemButtonUpdate( nIndex )
	if nIndex <= 0 or nIndex > table.getn(g_BieYePlanting_ItemData) then
		return
	end
		
	--先把所有的状态置为不显示
	local iOldCurShowList = g_BieYePlanting_ItemData[nIndex].CurShowList
	BieYePlanting_ClearAllShowListStatus()
	
	--如果展开状态，则关闭；如果关闭状态，则展开
	if iOldCurShowList > 0 then
		g_BieYePlanting_ItemData[nIndex].CurShowList = 0	
		g_BieYePlanting_ItemData[nIndex].ctrl:SetCatalogButtonSelect(false)	
	else			
		g_BieYePlanting_ItemData[nIndex].CurShowList = 1
		g_BieYePlanting_ItemData[nIndex].ctrl:SetCatalogButtonSelect(true)		
		--显示所有子区域
		for SubIndex = 1, g_BieYePlanting_LevelMax do
			if nil ~= g_BieYePlanting_SubItemData[nIndex].button[SubIndex] then
				g_BieYePlanting_SubItemData[nIndex].button[SubIndex]:Show()	--全部显示
				g_BieYePlanting_SubItemData[nIndex].button[SubIndex]:SetTextCatalogSelected(false)	--不选中
			end
		end
	end	
end
--点击一级菜单
function BieYePlanting_ItemDetailUpdate( nIndex )
	if nIndex <= 0 or nIndex > table.getn(g_BieYePlanting_ItemData) then
		return
	end
	if g_BieYePlanting_Level == nil or g_BieYePlanting_Level <= 0 or g_BieYePlanting_Level > g_BieYePlanting_LevelMax then
		return
	end
		
	--展开与否的状态已更新，只需要检查是否需要显示子列表即可
	if g_BieYePlanting_ItemData[nIndex].CurShowList > 0 then
		--显示
		BieYePlanting_SubItemButtonUpdate( nIndex, g_BieYePlanting_Level )
		BieYePlanting_SubItemDetailUpdate( nIndex, g_BieYePlanting_Level )
	end
end

--点击二级菜单，更新二级菜单状态
function BieYePlanting_SubItemButtonUpdate( nIndex, nSubIndex )
	if nIndex <= 0 or nIndex > table.getn(g_BieYePlanting_ItemData) then
		return
	end
	if nSubIndex <= 0 or nSubIndex > g_BieYePlanting_LevelMax then
		return
	end
		
	--显示当前所在的一级菜单下的所有二级菜单
	for SubIndex = 1, g_BieYePlanting_LevelMax do
		if nil ~= g_BieYePlanting_SubItemData[nIndex].button[SubIndex] then
			g_BieYePlanting_SubItemData[nIndex].button[SubIndex]:Show()	--全部显示
			g_BieYePlanting_SubItemData[nIndex].button[SubIndex]:SetTextCatalogSelected(false)	--不选中
		end
	end
	
	--设置所属一级菜单的选中状态
	if nil ~= g_BieYePlanting_ItemData[nIndex] and nil ~= g_BieYePlanting_ItemData[nIndex].ctrl then
		g_BieYePlanting_ItemData[nIndex].ctrl:SetCatalogButtonSelect(true)
	end
	
	--设置所属的二级菜单的选中状态
	if nil ~= g_BieYePlanting_SubItemData[nIndex].button[nSubIndex] then
		g_BieYePlanting_SubItemData[nIndex].button[nSubIndex]:SetTextCatalogSelected(true)	--选中
	end	
end
--点击二级菜单，显示当前菜单对应的详细信息
function BieYePlanting_SubItemDetailUpdate( nIndex, nSubIndex )
	if nIndex <= 0 or nIndex > table.getn(g_BieYePlanting_ItemData) then
		return
	end
	if nSubIndex <= 0 or nSubIndex > g_BieYePlanting_LevelMax then
		return
	end
	
	--右侧显示当前菜单对应的详细信息
	g_BieYePlanting_Select.nIndex = nIndex
	g_BieYePlanting_Select.nSubIndex = nSubIndex	
	BieYePlanting_ShowDetail( nIndex, nSubIndex )	
end

--点击左侧选项
function BieYePlanting_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local curClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if curClickIndex + 1 > 0 then
		BieYePlanting_ItemDataChanged( curClickIndex + 1 )
	end
end

--显示细节
function BieYePlanting_ShowDetail(nIndex, nSubIndex)
	if nIndex <= 0 or nIndex > table.getn(g_BieYePlanting_ItemData) then
		return
	end
	if nSubIndex <=0 or nSubIndex > g_BieYePlanting_LevelMax then
		return
	end
	
	local	nID = g_BieYePlanting_SubItemData[nIndex].nID[nSubIndex]
	if nID == nil or nID <= 0 then
		return
	end
	
	if g_BieYePlanting_Page == nil or g_BieYePlanting_Page < 1 or g_BieYePlanting_Page > 2 then
		return
	end
	
	--获得数据
	local nDataID, nMoney, nYuanbao, nTime, nCount = BieYeUI:GetMaterialOutputData(nID)
	if nDataID == nil or nDataID < 0 or nMoney == nil or nMoney < 0 or nYuanbao == nil or nYuanbao < 0 or nTime == nil or nTime <= 0 or nCount == nil or nCount <= 0 then
		return
	end
	
	--显示模型
	BieYePlanting__FakeObject:SetFakeObject("")
	BieYeUI:BieYePlantingSetModel(nDataID)
	BieYePlanting__FakeObject:SetFakeObject("BieYePlanting")
		
	--显示星级
	for i=1,nSubIndex do
		g_BieYePlanting_Stars[i]:SetProperty("Animate", "Animate_Card_NoFlashStar")
		g_BieYePlanting_Stars[i]:Show()
	end
	for i=nSubIndex+1, g_BieYePlanting_LevelMax do
		g_BieYePlanting_Stars[i]:SetProperty("Animate", "Animate_Card_DarkStar")
		g_BieYePlanting_Stars[i]:Show()
	end
		
	--显示详情
  if g_BieYePlanting_Page == 1 then
  	BieYePlanting_Bk2_DemandYuanbao:Hide()
  	BieYePlanting_Bk2_DemandMoney:Show()
		BieYePlanting_Bk2_DemandMoney:SetProperty("MoneyNumber", nMoney)
	elseif g_BieYePlanting_Page == 2 then
  	BieYePlanting_Bk2_DemandMoney:Hide()
  	BieYePlanting_Bk2_DemandYuanbao:Show()
		BieYePlanting_Bk2_DemandYuanbao:SetText( ScriptGlobal_Format( "#{JYYC_160622_26}", nYuanbao ) )
	end
	BieYePlanting_Bk2_Text1Info:SetText( g_BieYePlanting_Text[g_BieYePlanting_Type].timetext )
	BieYePlanting_Bk2_Time:SetText( nTime.."小时" )
	BieYePlanting_Bk2_Number:SetText( ScriptGlobal_Format( g_BieYePlanting_Text[g_BieYePlanting_Type].output, nCount ) )	
end

--旋转模型（向左)
function BieYePlanting_TurnLeft(start)
	--向左旋转开始
	if(start==1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		BieYePlanting__FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		BieYePlanting__FakeObject:RotateEnd();
	end
end

--旋转模型（向右)
function BieYePlanting_TurnRight(start)
	--向右旋转开始
	if( start==1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		BieYePlanting__FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		BieYePlanting__FakeObject:RotateEnd();
	end
end

--关闭界面
function BieYePlanting_Close()
	--数据清空
	g_BieYePlanting_Type = 0--1：挖矿 2：养鱼 3：种树
	g_BieYePlanting_Index = -1--0：建筑1 1：建筑2
	g_BieYePlanting_Level = 0--建筑等级
	g_BieYePlanting_Page = 0--默认选择的消费方式 1：金钱 2：元宝
	g_BieYePlanting_BtnIndex = 1--默认选项下标
	
	--列表清空
	--BieYePlanting_Bk1:CleanAllElement("BieYePlanting")
	--g_BieYePlanting_LeftButton = {}
	--g_BieYePlanting_ItemID = {}
	--g_BieYePlanting_Select = {}--默认选中
	BieYePlanting__FakeObject:SetFakeObject("")
	for i=1,g_BieYePlanting_LevelMax do
		g_BieYePlanting_Stars[i]:Hide()
	end

	--关闭引导任务tips
	if (DataPool:Lua_IsHaveMission(1857) > 0 and DataPool:Lua_IsMissionHaveDone(1857) <= 0) or (DataPool:Lua_IsHaveMission(1858) > 0 and DataPool:Lua_IsMissionHaveDone(1858) <= 0) or (DataPool:Lua_IsHaveMission(1859) > 0 and DataPool:Lua_IsMissionHaveDone(1859) <= 0) then
		CloseFreshManGuide()	
	end
	
	this:Hide()
	--取消关心
	this:CareObject(objCared, 0, "BieYePlanting")
end

function BieYePlanting_Check_Clicked()
	if g_BieYePlanting_Type == nil or g_BieYePlanting_Type <= 0 or g_BieYePlanting_Type > g_BieYePlanting_TypeMax then
		return
	end	

	local bConfirm = BieYePlanting_Bk3_Check:GetCheck();
	if ( bConfirm == 0 ) then
		BieYePlanting_Bk3_Check:SetCheck( 0 );
		NpcShop:SetBieYePlantingComfirmDirectly( g_BieYePlanting_Type,1 );
	elseif ( bConfirm == 1 ) then
		BieYePlanting_Bk3_Check:SetCheck( 1 );
		NpcShop:SetBieYePlantingComfirmDirectly( g_BieYePlanting_Type,0 );
	end
	
end

--确认按钮
function BieYePlanting_Buttons_Clicked()
	if g_BieYePlanting_Type == nil or g_BieYePlanting_Type <= 0 or g_BieYePlanting_Type > g_BieYePlanting_TypeMax then
		return
	end	
	if g_BieYePlanting_Index == nil or g_BieYePlanting_Index < 0 or g_BieYePlanting_Index > 1 then
		return
	end	

	--计算产出id
	if g_BieYePlanting_Select == nil then
		return
	end
	if g_BieYePlanting_Select.nIndex == nil or g_BieYePlanting_Select.nIndex <= 0 or g_BieYePlanting_Select.nIndex > table.getn(g_BieYePlanting_ItemData) then
		return
	end
	if g_BieYePlanting_Select.nSubIndex == nil or g_BieYePlanting_Select.nSubIndex <= 0 or g_BieYePlanting_Select.nSubIndex > g_BieYePlanting_LevelMax then
		return
	end	
	local	nID = g_BieYePlanting_SubItemData[g_BieYePlanting_Select.nIndex].nID[g_BieYePlanting_Select.nSubIndex]
	if nID == nil or nID <= 0 then
		return
	end
	
	-- 元宝确认
	local bCheck = 0
	g_BieYePlanting_SecConfirm = tonumber(NpcShop:GetBieYePlantingComfirmDirectly(g_BieYePlanting_Type))
	if g_BieYePlanting_SecConfirm == 0 then
		bCheck = 1
	else
		bCheck = 0
	end

	if g_BieYePlanting_Type == 1 then
		--确认操作
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnMissionBeginConfirm" )
			Set_XSCRIPT_ScriptID(891943)
			Set_XSCRIPT_Parameter(0,objCared)
			Set_XSCRIPT_Parameter(1,g_BieYePlanting_Index)
			Set_XSCRIPT_Parameter(2,nID)
			Set_XSCRIPT_Parameter(3,bCheck)-- 0元宝购买不需要确认 1元宝购买需要确认
			Set_XSCRIPT_Parameter(4,0)-- 0雇佣园丁未确认 1雇佣园丁确认
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif g_BieYePlanting_Type == 2 then
		--确认操作
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnMissionBeginConfirm" )
			Set_XSCRIPT_ScriptID(891944)
			Set_XSCRIPT_Parameter(0,objCared)
			Set_XSCRIPT_Parameter(1,g_BieYePlanting_Index)
			Set_XSCRIPT_Parameter(2,nID)
			Set_XSCRIPT_Parameter(3,bCheck)-- 0元宝购买不需要确认 1元宝购买需要确认
			Set_XSCRIPT_Parameter(4,0)-- 0雇佣园丁未确认 1雇佣园丁确认
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	elseif g_BieYePlanting_Type == 3 then
		--确认操作
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnMissionBeginConfirm" )
			Set_XSCRIPT_ScriptID(891945)
			Set_XSCRIPT_Parameter(0,objCared)
			Set_XSCRIPT_Parameter(1,g_BieYePlanting_Index)
			Set_XSCRIPT_Parameter(2,nID)
			Set_XSCRIPT_Parameter(3,bCheck)-- 0元宝购买不需要确认 1元宝购买需要确认
			Set_XSCRIPT_Parameter(4,0)-- 0雇佣园丁未确认 1雇佣园丁确认
			Set_XSCRIPT_ParamCount(5)
		Send_XSCRIPT()
	end
	
	--关闭引导任务tips
	if (DataPool:Lua_IsHaveMission(1857) > 0 and DataPool:Lua_IsMissionHaveDone(1857) <= 0) or (DataPool:Lua_IsHaveMission(1858) > 0 and DataPool:Lua_IsMissionHaveDone(1858) <= 0) or (DataPool:Lua_IsHaveMission(1859) > 0 and DataPool:Lua_IsMissionHaveDone(1859) <= 0) then
		CloseFreshManGuide()	
	end
end
function BieYePlanting_OnMoved()
    if "BieYePlanting" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
    end
end