local g_LuckyBag_Baby_Frame_UnifiedPosition = nil 
local g_LuckyBag_Baby_Gold ={}
local g_LuckyBag_Baby_Silver = {}
local g_LuckyBag_Baby_copper = {}

function LuckyBag_Baby_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT")
	this:RegisterEvent("OPEN_MY_ZNQ_FUDAIINFO")

end 

-- LuckyBag_Baby_Close => TLBB_ButtonClose
-- LuckyBag_Baby_DragTitle => TLBB_DragTitle
-- LuckyBag_Baby_Frame_Client => TLBB_MainFrame16
function LuckyBag_Baby_OnLoad()
	g_LuckyBag_Baby_Frame_UnifiedPosition = LuckyBag_Baby_Frame:GetProperty("UnifiedPosition");
	
	for i = 1,5 do
		g_LuckyBag_Baby_Gold[i] = "LuckyBag_Baby_Bk1_Item"..i
	end
	
	for i = 2,4 do
		for j = 1,5 do
			g_LuckyBag_Baby_Silver[(i-2)*5+j] = "LuckyBag_Baby_Bk"..i.."_Item"..j
		end
	end
	
	for i = 1,30 do
		g_LuckyBag_Baby_copper[i] = "LuckyBag_Baby_Item"..i
	end
	
end

function LuckyBag_Baby_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		LuckyBag_Baby_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		LuckyBag_Baby_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		LuckyBag_Baby_On_Hide()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		LuckyBag_Baby_CareObj()
	elseif (event == "OPEN_MY_ZNQ_FUDAIINFO") then
		if tonumber(arg0) == 1 then
			LuckyBag_Baby_Init()
			this:Show()
		elseif tonumber(arg0) == 2 then
			this:Hide()
		end
		
	end
end


function LuckyBag_Baby_Init()
	
	for i = 1,5 do
		_G[g_LuckyBag_Baby_Gold[i]]:SetActionItem(-1)
	end
	for i = 1,15 do
		_G[g_LuckyBag_Baby_Silver[i]]:SetActionItem(-1)
	end
	
	for i = 1,30 do
		_G[g_LuckyBag_Baby_copper[i]]:SetActionItem(-1)
	end
	local goldIndex = 1
	local silverIndex = 1
	local copperIndex = 1
	
	for i = 1,50 do
		local bonusId = Lua_GetMyZNQItem(i-1)
		if bonusId > 0 then
			-- PushDebugMessage("AAAAAAAAAA")
			local poolId,ShowItemId,ItemCount = Lua_GetZNQfudaiInfoByBonusId(bonusId)
			local theAction = DataPool:CreateActionItemForShow(ShowItemId, ItemCount)
			local ActionButton = nil
			if poolId == 1 then
				ActionButton = _G[g_LuckyBag_Baby_copper[copperIndex]];
				copperIndex = copperIndex+1
			elseif poolId == 2 then
				ActionButton = _G[g_LuckyBag_Baby_Silver[silverIndex]];
				silverIndex = silverIndex+1			
			elseif poolId == 3 then
				ActionButton = _G[g_LuckyBag_Baby_Gold[goldIndex]];
				goldIndex = goldIndex+1
			end
			
			if ActionButton ~= nil then
				ActionButton:SetActionItem(theAction:GetID())
			end
			
		end
	end
	local currencyCopper = Lua_GetMyZNQCurrency(0)	
	local currencySilver = Lua_GetMyZNQCurrency(1)	
	local currencyGold = Lua_GetMyZNQCurrency(2)
	LuckyBag_Baby_MoneyText:SetText(currencyCopper)
	LuckyBag_Baby_Bk1_MoneyText:SetText(currencyGold)
	LuckyBag_Baby_Bk2_MoneyText:SetText(currencySilver)
	local strgold = ScriptGlobal_Format("#{SWZB_190322_10}",goldIndex-1,5)
	LuckyBag_Baby_Bk1_NumText:SetText(strgold)
	local strsilver = ScriptGlobal_Format("#{SWZB_190322_10}",silverIndex-1,15)
	LuckyBag_Baby_Bk2_NumText:SetText(strsilver)
	local strcopper = ScriptGlobal_Format("#{SWZB_190322_10}",copperIndex-1,30)
	LuckyBag_Baby_NumText:SetText(strcopper)	
	
end

function LuckyBag_Baby_Close_Click()
	this:Hide()
end

function LuckyBag_Baby_CareObj()
	if(tonumber(arg0) ~= g_objCareID) then
		return;
	end
	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
		--取消关心
		LuckyBag_Baby_StopCareObject(g_objCareID)
		LuckyBag_Baby_On_Hide()
	end		
end

function LuckyBag_Baby_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "LuckyBag_Baby");
	g_objCareID = -1;
end

function LuckyBag_Baby_BeginCareObject(objid)
	g_Object = objid
	this:CareObject(g_Object, 1, "LuckyBag_Baby");
end

function LuckyBag_Baby_On_ResetPos()
	LuckyBag_Baby_Frame:SetProperty("UnifiedPosition", g_LuckyBag_Baby_Frame_UnifiedPosition)
end

function LuckyBag_Baby_On_Hide()
	this:Hide()
end



