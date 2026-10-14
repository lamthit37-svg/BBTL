
--!!!reloadscript =HuanyuJian

local g_HuanyuJian_Frame_UnifiedPosition

local HL_List = {3,4,5,6,7,8,9,11}
local UP_List = {10,12}

local g_Flag = 0

local g_HuanYuPet_ActionID = {0,1,2,4,162,163,164}

function HuanyuJian_PreLoad()
	this:RegisterEvent("NIANSHOU_HUANYU_JIAN")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	this:RegisterEvent("OPEN_STALL_SALE",false)
end

function HuanyuJian_OnLoad()

	g_HuanyuJian_Frame_UnifiedPosition = HuanyuJian_Frame:GetProperty("UnifiedPosition")
end

function HuanyuJian_OnEvent(event)
	
	if event == "NIANSHOU_HUANYU_JIAN" then
		
		if this:IsVisible() then
			
			if g_Flag == tonumber(arg0) then
				return
			else
				HuanyuJian_CleanUp()
				g_Flag = tonumber(arg0)
				HuanyuJian_Init()
				return
			end
		end
		
		this:Show()
		g_Flag = tonumber(arg0)
		HuanyuJian_Init()
		
	elseif event == "ADJEST_UI_POS" then
		HuanyuJian_Frame_On_ResetPos()	 
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		HuanyuJian_Frame_On_ResetPos()	
	elseif event == "OPEN_STALL_SALE" then
		this:Hide()
	end

end

--初始化界面
function HuanyuJian_Init()
	
	if g_Flag == 0 then
		for i = 1 , table.getn(HL_List) do			
		
			local strQualText = Pet:Lua_GetPetHuanLingInfo(HL_List[i],"ExText")		
			HuanyuJian_List:AddItem(strQualText , i)
		end
	else
		for i = 1 , table.getn(UP_List) do
			
		--	local strHuanLingName = Pet:Lua_GetPetHuanLingInfo(HL_List[i],"Name")
			local strQualText = Pet:Lua_GetPetHuanLingInfo(UP_List[i],"ExText")		
			HuanyuJian_List:AddItem(strQualText , i)
		end
	end
	
	HuanyuJian_List:SetItemSelectByItemID(1)
	HuanyuJian_Refresh(1)
	
end

function HuanyuJian_Refresh(index)
	
	if g_Flag == 0 then	
		if index < 1 or index > table.getn(HL_List) then
			return
		end
	else
		if index < 1 or index > table.getn(UP_List) then
			return
		end
	end
	
	HuanyuJian_FakeObject:SetFakeObject("")
	
	if g_Flag == 0 then
		Pet:Lua_UpdateNianShouHuanYuPreviewModel(HL_List[index])
	else
		Pet:Lua_UpdateNianShouHuanYuPreviewModel(UP_List[index])
	end
	
	HuanyuJian_FakeObject:SetFakeObject("NianShouHuanYuPreviewPet")
	
end

function HuanyuJian_List_Click()
	local index =  HuanyuJian_List:GetFirstSelectItem()
	HuanyuJian_Refresh(index)
end

--Close
function HuanyuJian_Close()
	this:Hide()
end

--OK
function HuanyuJian_OK_Clicked()

end

function HuanyuJian_OnHidden()
	HuanyuJian_CleanUp()
end

function HuanyuJian_CleanUp()
	
	HuanyuJian_List:ClearListBox()
	HuanyuJian_FakeObject:SetFakeObject("")
	
end

function HuanyuJian_Pet_Modle_TurnLeft( start )
	
	--向左旋转开始
	if start == 1 then
		HuanyuJian_FakeObject:RotateBegin(-0.3)
	--向左旋转结束
	else
		HuanyuJian_FakeObject:RotateEnd()
	end

end

function HuanyuJian_Pet_Modle_TurnRight( start )
	--向右旋转开始
	if start == 1 then
		HuanyuJian_FakeObject:RotateBegin(0.3)
	--向右旋转结束
	else
		HuanyuJian_FakeObject:RotateEnd()
	end
end

function HuanyuJian_ChangePetAction( actionId )
	
	local Mark = 0
	for i = 1,table.getn(g_HuanYuPet_ActionID) do
		if actionId == g_HuanYuPet_ActionID[i] then
			Mark = 1
			break
		end
	end
	
	if Mark == 1 then
		Pet:Lua_NianShouHuanYuPreviewModel_ChangeAction(actionId)
	end
end


function HuanyuJian_Frame_On_ResetPos()
  HuanyuJian_Frame:SetProperty("UnifiedPosition", g_HuanyuJian_Frame_UnifiedPosition)
end

--!!!reloadscript =HuanyuJian