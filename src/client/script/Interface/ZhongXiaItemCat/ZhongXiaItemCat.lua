-- 新仲夏节气 选择猫猫
-- !!!reloadscript =ZhongXiaItemCat

local g_Frame_UnifiedPosition = nil

local g_curIndex = -1
local g_catId = -1

local g_ItemLowId = 38005330
local g_ItemMiddleId = 38005331

local g_ItemLowIndex = 1
local g_ItemMiddleIndex = 2

local g_CatImage = {
	[g_ItemLowIndex] = "set:ZhongXiaCat image:ZhongXiaCatImage1",
	[g_ItemMiddleIndex] = "set:ZhongXiaCat image:ZhongXiaCatImage2",
}

local g_CatText = {
	[g_ItemLowIndex] = "#{ZXJQ_210512_15}",
	[g_ItemMiddleIndex] = "#{ZXJQ_210512_16}",
}

-- 控件
local g_ItemBtns = {}

g_ItemBtns[g_ItemLowIndex] = {}
g_ItemBtns[g_ItemMiddleIndex] = {}

-- 数据
local g_Data = {}

g_Data[g_ItemLowIndex] =
{
	[1] = 9,
	[2] = 10,
}

g_Data[g_ItemMiddleIndex] =
{
	[1] = 5,
	[2] = 8,
	[3] = 6,
	[4] = 7,
}


--=========
-- PreLoad()
--=========
function ZhongXiaItemCat_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
end

--=========
-- OnLoad()
--=========
function ZhongXiaItemCat_OnLoad()
	g_Frame_UnifiedPosition = ZhongXiaItemCat_Frame:GetProperty("UnifiedPosition")

	g_ItemBtns[g_ItemLowIndex] = {ZhongXiaItemCat_ItemA, ZhongXiaItemCat_ItemB}	
	g_ItemBtns[g_ItemMiddleIndex] = {ZhongXiaItemCat_ItemC, ZhongXiaItemCat_ItemD, ZhongXiaItemCat_ItemE, ZhongXiaItemCat_ItemF}

end

--=========
-- Event
--=========
function ZhongXiaItemCat_OnEvent(event)
	
	if (event == "UI_COMMAND" and tonumber(arg0) == 89192101) then
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			-- 显示界面
			local catItemId = Get_XParam_INT(1)
			ZhongXiaItemCat_Show(catItemId)
		else
			ZhongXiaItemCat_OnHiden()
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ZhongXiaItemCat_OnHiden()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZhongXiaItemCat_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then
		ZhongXiaItemCat_On_ResetPos()
	end
end

--=========
-- 重置
--=========
function ZhongXiaItemCat_On_ResetPos()
	ZhongXiaItemCat_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 关闭界面
--=========
function ZhongXiaItemCat_OnHiden()
	
	this:Hide()
end

--=========
-- 打开界面
--=========
function ZhongXiaItemCat_Show(catItemId)

	if catItemId == g_ItemLowId then
		g_catId = g_ItemLowIndex
	elseif catItemId == g_ItemMiddleId then
		g_catId = g_ItemMiddleIndex
	else
		return
	end
	
	local data = g_Data[ g_catId ]
	if data == nil then
		return
	end

	g_curIndex = -1
	
	for i=1, table.getn(g_ItemBtns) do
		for k=1, table.getn(g_ItemBtns[i]) do
			g_ItemBtns[i][k]:Hide()
		end
	end

	local itemBtns = g_ItemBtns[g_catId]
	for i=1, table.getn(data) do
		itemBtns[i]:Show()
		itemBtns[i]:SetCheck(0)
	end
	
	ZhongXiaItemCat_Item_SP_Info : SetProperty("Image", g_CatImage[g_catId])

	ZhongXiaItemCat_Text:SetText( g_CatText[g_catId] )
	--界面显示
	this:Show()
end

--=========
-- 点击领取
--=========
function ZhongXiaItemCat_OK_Clicked()
	local data = g_Data[g_catId]
	local count = table.getn(data)
	
	if g_curIndex <= 0 or g_curIndex > count then
		PushDebugMessage("#{ZXJQ_210512_11}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientActivateOnce")
		Set_XSCRIPT_ScriptID(891921)
		Set_XSCRIPT_Parameter( 0, g_curIndex )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()

end

--=========
-- 点击选中
--=========
function ZhongXiaItemCat_OnSelect_Clicked(nIndex)
	local data = g_Data[g_catId]
	local count = table.getn(data)
	
	if nIndex == nil or nIndex <= 0 or nIndex > count then
		return
	end

	local itemBtns = g_ItemBtns[g_catId]
	--选中当前
	if g_curIndex == nIndex then
		itemBtns[g_curIndex]:SetCheck(0)
		g_curIndex = -1
		return
	end

	-- 原有清空
	if g_curIndex > 0 and g_curIndex <= count then
		itemBtns[g_curIndex]:SetCheck(0)
		g_curIndex = -1
	end

	g_curIndex = nIndex
	itemBtns[g_curIndex]:SetCheck(1)
end
