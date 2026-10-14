--上新家具界面
local BieYeFurnitureNew_g_InnerNews = {}
local BieYeFurnitureNew_g_OuterNews = {}
local BieYeFurnitureNew_g_AllFurInfo = {}
local BieYeFurnitureNew_g_MaxType = 13
local BieYeFurnitureNew_g_FurIm = "Ach_AchIcon_Cup"
local BieYeFurnitureNew_g_FurImSet = "Ach"
local BieYeFurnitureNew_g_AllBtn = {}
local BieYeFurnitureNew_g_LeftCurSelectList = 0
local BieYeFurnitureNew_g_NPCID = -1
local BieYeFurnitureNew_g_MaxDistance = 15
local BieYeFurnitureNew_g_InType =
{
	[1] = "床帐",
	[2] = "居室桌",
	[3] = "条案",
	[4] = "茶几",
	[5] = "椅",
	[6] = "居室凳",
	[7] = "柜架",
	[8] = "屏风",
	[9] = "灯烛",
	[10] = "装饰",
	[11] = "隔断",
	[12] = "地毯",
	[13] = "瑰宝",
}
local BieYeFurnitureNew_PosName = 
{
	[0] = "庭院",
	[1] = "居室",
}

local BieYeFurnitureNew_g_OutType =
{
	[1] = "庭院桌",
	[2] = "庭院凳",
	[3] = "喷泉",
	[4] = "影壁",
	[5] = "风灯",
	[6] = "鼎",
	[7] = "奇石",
	[8] = "树木",
	[9] = "植栽",
	[10] = "玩物",
	[11] = "栏杆",				
	[12] = "花草",		
	[13] = "奇珍",	
}
--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function BieYeFurnitureNew_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

--=========================================================
-- 载入初始化
--=========================================================
function BieYeFurnitureNew_OnLoad()
	-- 保存界面的默认相对位置
	g_BieYeFurnitureNew_Frame_UnifiedXPosition	= BieYeFurnitureNew_Frame : GetProperty("UnifiedXPosition");
	g_BieYeFurnitureNew_Frame_UnifiedYPosition	= BieYeFurnitureNew_Frame : GetProperty("UnifiedYPosition");
	BieYeFurnitureNew_LoadData()
end


function BieYeFurnitureNew_OnHiden()
	BieYeFurnitureNew_Close()
	BieYeFurnitureNew_FakeObject:SetFakeObject("")
end


--=========================================================
-- 事件处理
--=========================================================
function BieYeFurnitureNew_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 20170228) then
		--BieYeFurnitureNew_LoadData()
		local npcServerId = Get_XParam_INT(0)
		BieYeFurnitureNew_g_NPCID = DataPool:GetNPCIDByServerID(npcServerId)
		if BieYeFurnitureNew_g_NPCID == -1 then
			PushDebugMessage("server传过来的数据有问题。")
			return
		end
		BieYeFurnitureNew_Open()
	elseif(event == "OBJECT_CARED_EVENT") then
		if (tonumber(arg0) ~= BieYeFurnitureNew_g_NPCID) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > BieYeFurnitureNew_g_MaxDistance) or arg1=="destroy") then
			BieYeFurnitureNew_OnHiden()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		BieYeFurnitureNew_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		BieYeFurnitureNew_Frame_On_ResetPos()
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BieYeFurnitureNew_Frame_On_ResetPos()

	BieYeFurnitureNew_Frame : SetProperty("UnifiedXPosition", g_BieYeFurnitureNew_Frame_UnifiedXPosition);
	BieYeFurnitureNew_Frame : SetProperty("UnifiedYPosition", g_BieYeFurnitureNew_Frame_UnifiedYPosition);

end

function BieYeFurnitureNew_Open()
	local nCount = 0
	for key,Value in pairs(BieYeFurnitureNew_g_AllFurInfo) do
		nCount = nCount + 1
	end
	if(nCount <= 0) then
		PushDebugMessage("#{BFYH_170306_50}")
		this:Hide()
		return
	end
	this:CareObject(BieYeFurnitureNew_g_NPCID, 1, "BieYeFurnitureNew")
	this:Show()
	BieYeFurnitureNew_FreshWindow()
	
end

function BieYeFurnitureNew_ListContentItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local CurClickIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if CurClickIndex + 1 > 0 and CurClickIndex + 1~=BieYeFurnitureNew_g_LeftCurSelectList then
		--BieYeFurnitureNew_g_LeftCurSelectList =	CurClickIndex + 1
		return BieYeFurnitureNew_SetLeftButtonSelected(CurClickIndex + 1)		--设置选中的类型高亮
	else
		return
	end
end

function BieYeFurnitureNew_SetLeftButtonSelected(nIndex)
	if nIndex <= 0 then return end
	if(BieYeFurnitureNew_g_AllBtn[nIndex] == nil) then
		BieYeFurnitureNew_UpDateLables()
		BieYeFurnitureNew_UpDateFakeobject()
		return
	end
	if(BieYeFurnitureNew_g_AllBtn[nIndex].bFirstContent == 1 and BieYeFurnitureNew_g_AllBtn[nIndex + 1] ~= nil) then
		nIndex = nIndex + 1
	end
	for BtnIndex = 1,table.getn(BieYeFurnitureNew_g_AllBtn) do
		local bHigth = false
		if(BieYeFurnitureNew_g_AllBtn[BtnIndex].bFirstContent == 1) then
			if(BieYeFurnitureNew_g_AllBtn[BtnIndex].Type == BieYeFurnitureNew_g_AllBtn[nIndex].Type
			and BieYeFurnitureNew_g_AllBtn[BtnIndex].Pos == BieYeFurnitureNew_g_AllBtn[nIndex].Pos) then
				bHigth = true
			end
			BieYeFurnitureNew_g_AllBtn[BtnIndex].btn:SetCatalogButtonSelect(bHigth)
		else
			if(nIndex == BtnIndex) then
				bHigth = true
			end
			if(BieYeFurnitureNew_g_AllBtn[BtnIndex].Type == BieYeFurnitureNew_g_AllBtn[nIndex].Type
			and BieYeFurnitureNew_g_AllBtn[BtnIndex].Pos == BieYeFurnitureNew_g_AllBtn[nIndex].Pos) then
				BieYeFurnitureNew_g_AllBtn[BtnIndex].btn:Show()
			else
				BieYeFurnitureNew_g_AllBtn[BtnIndex].btn:Hide()
			end
			BieYeFurnitureNew_g_AllBtn[BtnIndex].btn:SetTextCatalogSelected(bHigth)
		end
	end
	BieYeFurnitureNew_g_LeftCurSelectList = nIndex
	BieYeFurnitureNew_Left_List:Flash()
	BieYeFurnitureNew_UpDateLables()
	BieYeFurnitureNew_UpDateFakeobject()
end

function BieYeFurnitureNew_FreshWindow()
	BieYeFurnitureNew_g_AllBtn = {}
	BieYeFurnitureNew_Left_List:CleanAllElement("BieYeFurnitureNew")
	--先显示庭院的
	local bShow = 1
	for i = 1,BieYeFurnitureNew_g_MaxType do
		if(BieYeFurnitureNew_g_OuterNews[i] ~= nil) then
			BieYeFurnitureNew_AddCatalog(BieYeFurnitureNew_g_AllBtn,"#e010101#cFDEACA"..BieYeFurnitureNew_g_OutType[i],i,0)
			for j = 1,table.getn(BieYeFurnitureNew_g_OuterNews[i]) do
				local nID = BieYeFurnitureNew_g_OuterNews[i][j]
				local info = BieYeFurnitureNew_g_AllFurInfo[nID]
				BieYeFurnitureNew_AddText(BieYeFurnitureNew_g_AllBtn,info.name,i,0,nID,bShow)
			end
			bShow = 0
		end
	end
	for i = 1,BieYeFurnitureNew_g_MaxType do
		if(BieYeFurnitureNew_g_InnerNews[i] ~= nil) then
			BieYeFurnitureNew_AddCatalog(BieYeFurnitureNew_g_AllBtn,"#e010101#cFDEACA"..BieYeFurnitureNew_g_InType[i],i,1)
			for j = 1,table.getn(BieYeFurnitureNew_g_InnerNews[i]) do
				local nID = BieYeFurnitureNew_g_InnerNews[i][j]
				local info = BieYeFurnitureNew_g_AllFurInfo[nID]
				BieYeFurnitureNew_AddText(BieYeFurnitureNew_g_AllBtn,info.name,i,1,nID)
			end
		end
	end
	--BieYeFurnitureNew_Left_List:SetVertScrollbarHide()
	BieYeFurnitureNew_SetLeftButtonSelected(2)
	--BieYeFurnitureNew_Left_List:SetVertScrollbarHide()
end
--刷新所有文字
function BieYeFurnitureNew_UpDateLables()
	BieYeFurnitureNew_Txet1:SetText("")
	BieYeFurnitureNew_Txet2:SetText("")
	BieYeFurnitureNew_Explain:SetText("")
	if(BieYeFurnitureNew_g_LeftCurSelectList > 0) then
		local nID = BieYeFurnitureNew_g_AllBtn[BieYeFurnitureNew_g_LeftCurSelectList].id
		if(nID == 0) then
			BieYeFurnitureNew_Explain:SetText("#{BYFUR_170405_314}")
			return
		end
		local info = BieYeFurnitureNew_g_AllFurInfo[nID]
		local szName = ScriptGlobal_Format("#{BYFUR_160531_253}",BieYeFurnitureNew_PosName[info.pos],info.name)
		BieYeFurnitureNew_Txet1:SetText(szName)
		local szQuality = "#{BFYH_170209_06}"
		if(info.quality ~= 0) then
			szQuality = "#{BFYH_170209_07}"
		end
		BieYeFurnitureNew_Txet2:SetText(szQuality)
		BieYeFurnitureNew_Explain:SetText(info.tips)
	end
end

function BieYeFurnitureNew_UpDateFakeobject()
	BieYeFurnitureNew_FakeObject:SetFakeObject("")
	BieYeFurnitureNew_Mode_Text:SetText("")
	if(BieYeFurnitureNew_g_AllBtn[BieYeFurnitureNew_g_LeftCurSelectList] ~= nil) then
		local nID = BieYeFurnitureNew_g_AllBtn[BieYeFurnitureNew_g_LeftCurSelectList].id
		if(nID == 0) then
			return
		end
		local info = BieYeFurnitureNew_g_AllFurInfo[nID]
		local szComfort = ScriptGlobal_Format("#{BYFUR_160531_84}",tostring(info.comfort))
		BieYeFurniture:SetFurnitureNewsModel(nID)
		BieYeFurnitureNew_FakeObject:SetFakeObject("BieYeFurnitureNews")
		BieYeFurnitureNew_Mode_Text:SetText(szComfort)
	end
end


--这可以在第一次进场景的时候加载一次
function BieYeFurnitureNew_LoadData()
	local nIndex = 0
	local bStop = false
	BieYeFurnitureNew_g_AllFurInfo = {}
	BieYeFurnitureNew_g_OuterNews = {}
	BieYeFurnitureNew_g_InnerNews = {}
	while(bStop ~= true) do
		nIndex = nIndex + 1
		local nID,szName,Pos,Type,Quality,Comfort,Tips = BieYeFurniture:GetFurnitureNews(nIndex)
		if(nID == -1) then
			bStop = true
		else
			local Info = {}
			Info.name = szName
			Info.pos = Pos
			Info.type = Type
			Info.quality = Quality
			Info.comfort = Comfort
			Info.tips = Tips
			BieYeFurnitureNew_g_AllFurInfo[nID] = Info
			if(Pos == 0) then
				if(BieYeFurnitureNew_g_OuterNews[Type] == nil) then
					local List = {}
					table.insert(List,nID)
					BieYeFurnitureNew_g_OuterNews[Type] = List
				else
					table.insert(BieYeFurnitureNew_g_OuterNews[Type],nID)
				end
			else
				if(BieYeFurnitureNew_g_InnerNews[Type] == nil) then
					local List = {}
					table.insert(List,nID)
					BieYeFurnitureNew_g_InnerNews[Type] = List
				else
					table.insert(BieYeFurnitureNew_g_InnerNews[Type],nID)
				end
			end
		end
	end
end

--增加类型控件
function BieYeFurnitureNew_AddCatalog(BtnList,nText,nType,nPos)
	local FurBtn = {}
	local FurnitureCatalog = BieYeFurnitureNew_Left_List:AddItemElement( "BieYeFurniture", "LEFT", "BieYeFurnitureNew","" ,"")
	FurnitureCatalog:SetProperty("AchievementWindowCatalogButtonHover","AchievementHoverSection")
	FurnitureCatalog:AddTextCatalogTextAndImage(nText,BieYeFurnitureNew_g_FurIm,BieYeFurnitureNew_g_FurImSet)
	FurBtn.bFirstContent = 1
	FurBtn.btn = FurnitureCatalog
	FurBtn.Type = nType
	FurBtn.id = 0
	FurBtn.name = nText
	FurBtn.Pos = nPos
	table.insert(BtnList,FurBtn)
end

--增加子类型控件
function BieYeFurnitureNew_AddText(BtnList,nText,nType,nPos,nId,bShow)
	local FurBtn = {}
	local szText = string.format("#e010101#cFDEACA%s", nText)
	local FurnitureText = BieYeFurnitureNew_Left_List:AddItemElement("BieYeFurnitureText","LEFT","BieYeFurnitureNew","","")
	FurnitureText:SetProperty("AchievementWindowButtonTextHover","AchievementHoverSection")
	FurnitureText:AddTextTextAndImage(szText,"","")
	FurnitureText:Hide()		--刚开始子控件不可见
	if(bShow ~= nil and bShow == 1) then
		FurnitureText:Show()
	end
	FurBtn.bFirstContent = 0
	FurBtn.Type = nType
	FurBtn.btn = FurnitureText
	FurBtn.id = nId
	FurBtn.name = szText
	FurBtn.Pos = nPos
	table.insert(BtnList,FurBtn)
end
function BieYeFurnitureNew_TurnLeft(start)
	--向左旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeFurnitureNew_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			BieYeFurnitureNew_FakeObject:RotateEnd();
		end
	end
end

function BieYeFurnitureNew_TurnRight(start)
	--向右旋转开始
	if(CEArg:GetValue("MouseButton")=="LeftButton") then
		if(start == 1) then
			BieYeFurnitureNew_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			BieYeFurnitureNew_FakeObject:RotateEnd();
		end
	end
end
function BieYeFurnitureNew_Close()
	if(this:IsVisible()) then
		this:Hide()
	end
	this:CareObject(BieYeFurnitureNew_g_NPCID, 0, "BieYeFurnitureNew")
	BieYeFurnitureNew_g_NPCID = -1
	return
end





