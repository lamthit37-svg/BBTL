-- PetPossJian.lua
-- 兽魂附图图鉴

local g_ModelTypeId = -1

local g_PetPossTbl = {
	{rhd=0, name="#{FTWX_110511_08}"},	--融合度：0-2
	{rhd=3, name="#{FTWX_110511_09}"},	--融合度：3-5
	{rhd=6, name="#{FTWX_110511_10}"},	--融合度：6-7
	{rhd=8, name="#{FTWX_110511_11}"},	--融合度：8-9
	{rhd=10, name="#{FTWX_110511_12}"},	--融合度：10
}

local g_PetPossJian_Frame_UnifiedPosition

function PetPossJian_PreLoad()
	this:RegisterEvent("OPEN_POSSJIAN_DLG")
	this:RegisterEvent("CLOSE_POSSJIAN_DLG")
	
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	this:RegisterEvent("UPDATE_FAKE_OBJECT",false)
end

function PetPossJian_OnLoad()
	-- 保存界面的默认相对位置
	g_PetPossJian_Frame_UnifiedPosition = PetPossJian_Frame:GetProperty("UnifiedPosition")
end

function PetPossJian_OnEvent(event)
	if (event == "OPEN_POSSJIAN_DLG") then	-- 打开界面
		g_ModelTypeId = tonumber(arg0)
		PetPossJian_Init()
		this:Show()
	
	elseif (event == "CLOSE_POSSJIAN_DLG") then
		this:Hide()
	
	elseif (event == "ADJEST_UI_POS") then
		PetPossJian_Frame_On_ResetPos()
	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetPossJian_Frame_On_ResetPos()
	elseif( event == "UPDATE_FAKE_OBJECT" ) then
		if( arg0 == "My_PetPossColorJian" and this:IsVisible() ) then
			PetPossJian_SetFakeCamera()
		end
	end
end

function PetPossJian_Init()
	PetPossJian_List:ClearListBox()
	PetPossJian_FakeObject:SetFakeObject("")
	
	for i=1, table.getn(g_PetPossTbl) do
		PetPossJian_List:AddItem(g_PetPossTbl[i].name, i)
	end
	
	PetPossJian_List:SetItemSelectByItemID(1)	--默认选中第一项
end

function PetPossJian_List_Click()
	local nIndex = PetPossJian_List:GetFirstSelectItem()
	if nIndex ~= -1 then
		--Model
		PetPossJian_FakeObject:SetFakeObject("")
		Pet:SetPetJianColorRateByFitValue(g_ModelTypeId, g_PetPossTbl[nIndex].rhd)
		PetPossJian_FakeObject:SetFakeObject("My_PetPossColorJian")
		PetPossJian_SetFakeCamera()
		local strName = Pet:GetPetPossModelNameById(g_ModelTypeId)
		if strName == nil or strName == "" then
			return
		end
		PetPossJian_Pet_Type:SetText(strName)
	end
end

function PetPossJian_SetFakeCamera()
	FakeObj_SetCamera( "My_PetPossColorJian", 2,9)
end

--model turn left
function PetPossJian_Model_TurnLeft(start)
	--start
	if (start == 1 and CEArg:GetValue("MouseButton") == "LeftButton") then
		PetPossJian_FakeObject:RotateBegin(-0.3)
	else
		PetPossJian_FakeObject:RotateEnd()
	end
end

--model turn right
function PetPossJian_Model_TurnRight(start)
	--start
	if (start == 1 and CEArg:GetValue("MouseButton") == "LeftButton") then
		PetPossJian_FakeObject:RotateBegin(0.3)
	else
		PetPossJian_FakeObject:RotateEnd()
	end
end

function PetPossJian_OnHiden()
	g_ModelTypeId = -1
	Pet:ClearUpPetJianColorRate()
	PetPossJian_FakeObject:SetFakeObject("")
end

function PetPossJian_Frame_On_ResetPos()
	PetPossJian_Frame:SetProperty("UnifiedPosition", g_PetPossJian_Frame_UnifiedPosition)
end
