--VIP专属炫装

local g_VIP_XuanShop_Frame_UnifiedPosition

local g_VIP_XuanShop_SelIdx = -1	--选中炫装的index
local g_VIP_XuanShop_Dress = {}		--与Animate对应
local g_VIP_XuanShop_Item = {}		--可选炫装按钮
local g_VIP_XuanShop_ItemText = {}	--炫装说明
local g_VIP_XuanShop_TempDress = {}	--临时数据
local g_VIP_XuanShop_ItemNum = 12

local g_VIP_XuanShop_DressPoint = {
	BackGround	= 0,
	Leg			= 1,
	Body		= 2,
	Head		= 3,
	Front		= 4,
	Suit		= 5,
}

local g_VIP_XuanShop_Male_Default = {}
g_VIP_XuanShop_Male_Default[0] = nil
g_VIP_XuanShop_Male_Default[1] = "Base_M_DownBody"
g_VIP_XuanShop_Male_Default[2] = "Base_M_UpBody"
g_VIP_XuanShop_Male_Default[3] = "Base_M_Head"
g_VIP_XuanShop_Male_Default[4] = nil
g_VIP_XuanShop_Male_Default[5] = nil

local g_VIP_XuanShop_Female_Default = {}
g_VIP_XuanShop_Female_Default[0] = nil
g_VIP_XuanShop_Female_Default[1] = "Base_F_DownBody"
g_VIP_XuanShop_Female_Default[2] = "Base_F_UpBody"
g_VIP_XuanShop_Female_Default[3] = "Base_F_Head"
g_VIP_XuanShop_Female_Default[4] = nil
g_VIP_XuanShop_Female_Default[5] = nil

local g_VIP_XuanShop_ItemId = {}	--可选择的炫装ID
g_VIP_XuanShop_ItemId[0] = -1
g_VIP_XuanShop_ItemId[1] = -1
g_VIP_XuanShop_ItemId[2] = -1

function VIP_XuanShop_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	
	this:RegisterEvent("IMDRESSCHEST_ITEM_CHANGED")
	this:RegisterEvent("IMDRESS_SELECT")
	this:RegisterEvent("UPDATE_MYSELF_IMDRESS")
end

-- 注册onLoad事件
function VIP_XuanShop_OnLoad()
	g_VIP_XuanShop_Frame_UnifiedPosition = VIP_XuanShop_Frame:GetProperty("UnifiedPosition")
	
	g_VIP_XuanShop_Dress[0] = VIP_XuanShop_fitting_BK
	g_VIP_XuanShop_Dress[1] = VIP_XuanShop_fitting_DownBody
	g_VIP_XuanShop_Dress[2] = VIP_XuanShop_fitting_UpBody
	g_VIP_XuanShop_Dress[3] = VIP_XuanShop_fitting_Head
	g_VIP_XuanShop_Dress[4] = VIP_XuanShop_fitting_FK
	g_VIP_XuanShop_Dress[5] = VIP_XuanShop_fitting_Suit
	
	g_VIP_XuanShop_Item[0] = VIP_XuanShop_Item1
	g_VIP_XuanShop_Item[1] = VIP_XuanShop_Item2
	g_VIP_XuanShop_Item[2] = VIP_XuanShop_Item3
	g_VIP_XuanShop_Item[3] = VIP_XuanShop_Item4
	g_VIP_XuanShop_Item[4] = VIP_XuanShop_Item5
	g_VIP_XuanShop_Item[5] = VIP_XuanShop_Item6
	g_VIP_XuanShop_Item[6] = VIP_XuanShop_Item7
	g_VIP_XuanShop_Item[7] = VIP_XuanShop_Item8
	g_VIP_XuanShop_Item[8] = VIP_XuanShop_Item9
	g_VIP_XuanShop_Item[9] = VIP_XuanShop_Item10
	g_VIP_XuanShop_Item[10] = VIP_XuanShop_Item11
	g_VIP_XuanShop_Item[11] = VIP_XuanShop_Item12
	
	g_VIP_XuanShop_ItemText[0] = VIP_XuanShop_ItemInfo1_Text
	g_VIP_XuanShop_ItemText[1] = VIP_XuanShop_ItemInfo2_Text
	g_VIP_XuanShop_ItemText[2] = VIP_XuanShop_ItemInfo3_Text
	g_VIP_XuanShop_ItemText[3] = VIP_XuanShop_ItemInfo4_Text
	g_VIP_XuanShop_ItemText[4] = VIP_XuanShop_ItemInfo5_Text
	g_VIP_XuanShop_ItemText[5] = VIP_XuanShop_ItemInfo6_Text
	g_VIP_XuanShop_ItemText[6] = VIP_XuanShop_ItemInfo7_Text
	g_VIP_XuanShop_ItemText[7] = VIP_XuanShop_ItemInfo8_Text
	g_VIP_XuanShop_ItemText[8] = VIP_XuanShop_ItemInfo9_Text
	g_VIP_XuanShop_ItemText[9] = VIP_XuanShop_ItemInfo10_Text
	g_VIP_XuanShop_ItemText[10] = VIP_XuanShop_ItemInfo11_Text
	g_VIP_XuanShop_ItemText[11] = VIP_XuanShop_ItemInfo12_Text
	
	g_VIP_XuanShop_TempDress[0] = -1
	g_VIP_XuanShop_TempDress[1] = -1
	g_VIP_XuanShop_TempDress[2] = -1
	g_VIP_XuanShop_TempDress[3] = -1
	g_VIP_XuanShop_TempDress[4] = -1
	g_VIP_XuanShop_TempDress[5] = -1
end

function VIP_XuanShop_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 889644) then	-- 打开界面
		this:Show()
		SendAskIMDressChestPacket()	--请求炫装信息
		
		for i = 0, 2 do
			g_VIP_XuanShop_ItemId[i] = -1
		end
		local nCount = Get_XParam_INT_Count()
		for i = 0, nCount-1 do
			g_VIP_XuanShop_ItemId[i] = Get_XParam_INT(i)
		end
		
		VIP_XuanShop_UpdateChest()
	
	elseif (event == "IMDRESSCHEST_ITEM_CHANGED") then
		if this:IsVisible() == false then
			return
		end
		
		DataPool:SetVipDressChest(0, 0)
		for i = 0, 2 do
			if g_VIP_XuanShop_ItemId[i] ~= -1 then
				DataPool:SetVipDressChest(g_VIP_XuanShop_ItemId[i], i)
			end
		end
		DataPool:SetVipDressChest(1, 1)
		
		VIP_XuanShop_ShowMyDress()
		VIP_XuanShop_UpdateChest()
	
	elseif (event == "IMDRESS_SELECT") then
		if this:IsVisible() == false then
			return
		end
		VIP_XuanShop_PutOnDress()
	
	elseif (event == "UPDATE_MYSELF_IMDRESS") then
		if this:IsVisible() == false then
			return
		end
		VIP_XuanShop_ShowMyDress()
	
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		VIP_XuanShop_Frame_On_ResetPos()
	
	elseif (event == "ADJEST_UI_POS") then
		VIP_XuanShop_Frame_On_ResetPos()
	
	end
end

--显示默认形象
function VIP_XuanShop_ShowDefault()
	local tempTable = g_VIP_XuanShop_Female_Default
	if GetMySelfRaceId() == 1 then
		tempTable = g_VIP_XuanShop_Male_Default
	end
	
	for i = 0, 5 do
		g_VIP_XuanShop_Dress[i]:Play(false)
		if tempTable[i] ~= nil then
			g_VIP_XuanShop_Dress[i]:SetProperty("Animate", tempTable[i])
			g_VIP_XuanShop_Dress[i]:Play(true)
		end
	end
	
	for _, item in g_VIP_XuanShop_Item do
		item:SetPushed(0)
	end
end

--显示已有的炫装形象
function VIP_XuanShop_ShowMyDress()
	local anims = {}
	anims[0], anims[1], anims[2], anims[3], anims[4], anims[5] = DataPool:GetMySelfIMDress()
	for i = 0, 5 do
		g_VIP_XuanShop_TempDress[i] = IMDressGetIndexByDressPoint(i)
		g_VIP_XuanShop_Dress[i]:Play(false)
		if anims[i] ~= nil then
			g_VIP_XuanShop_Dress[i]:SetProperty("Animate", anims[i])
			g_VIP_XuanShop_Dress[i]:Play(true)
		end
	end
end

--更新可领取的炫装
function VIP_XuanShop_UpdateChest()
	for i = 0, g_VIP_XuanShop_ItemNum-1 do
		local theAction = EnumAction(i, "imdress")
		if theAction:GetID() ~= 0 then
			g_VIP_XuanShop_Item[i]:SetActionItem(theAction:GetID())
			g_VIP_XuanShop_ItemText[i]:SetText(theAction:GetName())
		else
			g_VIP_XuanShop_Item[i]:SetActionItem(-1)
			g_VIP_XuanShop_ItemText[i]:SetText("")
		end
	end
	
	g_VIP_XuanShop_SelIdx = -1
end

function VIP_XuanShop_GoodButton_Clicked(index)
	if index < 0 or index > table.getn(g_VIP_XuanShop_Item) then
		return
	end
	
	g_VIP_XuanShop_Item[index]:DoAction()
end

--按钮选中具体逻辑
function VIP_XuanShop_PutOnDress()
	local index = IMDressChestGetSelIndex()
	local dressPoint, animate = IMDressGetDressInfo(index, "imdress")
	if dressPoint == nil or animate == nil or (dressPoint < 0 or dressPoint > table.getn(g_VIP_XuanShop_Dress)) then
		return
	end
	
	for _, item in g_VIP_XuanShop_Item do
		item:SetPushed(0)
	end
	
	--穿的是不是套装
	if g_VIP_XuanShop_TempDress[g_VIP_XuanShop_DressPoint.Suit] ~= -1 then
		VIP_XuanShop_ShowDefault()
	else
		VIP_XuanShop_ShowMyDress()
	end
	
	g_VIP_XuanShop_Item[index]:SetPushed(1)
	g_VIP_XuanShop_Dress[dressPoint]:SetProperty("Animate", animate)
	g_VIP_XuanShop_Dress[dressPoint]:Play(true)
	
	g_VIP_XuanShop_SelIdx = index
end

function VIP_XuanShop_ShowXuanShop()
	PushEvent("OPEN_IMDRESS_YUANBAOSHOP")
end

function VIP_XuanShop_Close_Clicked()
	this:Hide()
end

--领取炫装
function VIP_XuanShop_Present_Clicked()
	local index = IMDressChestGetSelIndex()
	if g_VIP_XuanShop_SelIdx ~= -1 and g_VIP_XuanShop_SelIdx == index then
		local theAction = EnumAction(index, "imdress")
		if theAction:GetID() ~= 0 then
			-- 向服务器发送领取炫装消息
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnGetIMDress")
				Set_XSCRIPT_ScriptID(889644)
				Set_XSCRIPT_Parameter(0, theAction:GetDefineID())
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
		
		local count = 0
		for i = 0, table.getn(g_VIP_XuanShop_ItemId) do
			if g_VIP_XuanShop_ItemId[i] ~= -1 then
				count = count + 1
			end
		end
		g_VIP_XuanShop_ItemId[g_VIP_XuanShop_SelIdx] = g_VIP_XuanShop_ItemId[count-1]
		g_VIP_XuanShop_ItemId[count-1] = -1
		if count > 1 then
			this:Show()
		else
			this:Hide()
		end
	else
		PushDebugMessage("#{VIPTQ_110908_69}")
	end
end

--关闭界面，这坑爹的名字
function VIP_XuanShop_PayMoney_Clicked()
	this:Hide()
end

function VIP_XuanShop_Frame_On_ResetPos()
	VIP_XuanShop_Frame:SetProperty("UnifiedPosition", g_VIP_XuanShop_Frame_UnifiedPosition)
end
