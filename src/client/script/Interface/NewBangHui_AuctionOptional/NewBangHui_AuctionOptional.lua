local g_NewBangHui_AuctionOptional_Frame_UnifiedPosition

local g_NewBangHuiAucitonOptionalItemIndex = -1
local g_NewBangHuiAucitonOptionalItemId = -1
local g_NewBangHuiAucitonOptionalItemType = -1

-----------------------------------------------------------------------
-- OnGameEvent
-----------------------------------------------------------------------
function NewBangHui_AuctionOptional_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)

end

function NewBangHui_AuctionOptional_OnLoad()
	g_NewBangHui_AuctionOptional_Frame_UnifiedPosition = NewBangHui_AuctionOptional_Frame:GetProperty("UnifiedPosition")
end



function NewBangHui_AuctionOptional_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 9997101) then
		NewBangHui_AuctionOptional_Close()
		g_NewBangHuiAucitonOptionalItemIndex  = Get_XParam_INT( 0 )
		g_NewBangHuiAucitonOptionalItemId = Get_XParam_INT( 1 )
		local nPirce = Get_XParam_INT(4)
		g_NewBangHuiAucitonOptionalItemType = Get_XParam_INT(5)
		NewBangHui_AuctionOptional_Show(g_NewBangHuiAucitonOptionalItemId,Get_XParam_INT(2),Get_XParam_INT(3),nPirce,g_NewBangHuiAucitonOptionalItemType)
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 9997106) then
		NewBangHui_AuctionOptional_Close()
		this:Hide()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		NewBangHui_AuctionOptional_OnHiden()
	elseif (event == "ADJEST_UI_POS") then
		NewBangHui_AuctionOptional_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_AuctionOptional_On_ResetPos()
	elseif (event == "PLAYER_ENTERING_WORLD" ) then	
		NewBangHui_AuctionOptional_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED" ) then
		NewBangHui_AuctionOptional_OnHiden()
	end
end

function NewBangHui_AuctionOptional_On_ResetPos()
	NewBangHui_AuctionOptional_Frame:SetProperty("UnifiedPosition", g_NewBangHui_AuctionOptional_Frame_UnifiedPosition)

end

--===============================================
-- NewBangHui_AuctionOptional_Close()
--===============================================
function NewBangHui_AuctionOptional_Close() 
	-- 解除背包格子蒙红锁定
	if g_NewBangHuiAucitonOptionalItemIndex >= 0 then
		LifeAbility : Lock_Packet_Item( g_NewBangHuiAucitonOptionalItemIndex, 0 )
	end
end
 

function NewBangHui_AuctionOptional_Show(libaoId, ItemIndex, ncount, price,ntype)
	-- 标题
	local strName=	ScriptGlobal_Format("#{SCBHPM_20220815_164}",DataPool:Lua_GetItemNameByIndex(libaoId))
	NewBangHui_AuctionOptional_DragTitle:SetText(strName)

	strName=	ScriptGlobal_Format("#{SCBHPM_20220815_206}",DataPool:Lua_GetItemNameByIndex(ItemIndex))
	NewBangHui_AuctionOptional_ItemText:SetText(strName)

	--描述
	if ntype == 0 then -- 上架到帮会
		strName=	ScriptGlobal_Format("#{SCBHPM_20220815_165}",price)
	else
		strName=	ScriptGlobal_Format("#{SCBHPM_20220815_165}",price)
	end
	NewBangHui_AuctionOptional_Info:SetText(strName)

	local theAction = DataPool:CreateBindActionItemForShow(ItemIndex, ncount)
	if theAction:GetID() ~= 0 then
		NewBangHui_AuctionOptional_Item:SetActionItem( theAction:GetID() )
	end	

	-- 背包格子蒙红锁定
	LifeAbility : Lock_Packet_Item( g_NewBangHuiAucitonOptionalItemIndex, 1 )
	
end

----------------------------------------------------------------------
-- on events
-----------------------------------------------------------------------

function NewBangHui_AuctionOptional_Choose(nfalg)
	if nfalg == 1 then  -- 上架物品
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnUpItem")
			Set_XSCRIPT_ScriptID(999710)
			Set_XSCRIPT_Parameter(0,0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif nfalg == 2 then -- 自己领取
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnReciveItem")
			Set_XSCRIPT_ScriptID(999710)
			Set_XSCRIPT_Parameter(0,0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	end
end

function NewBangHui_AuctionOptional_OnHiden()
	NewBangHui_AuctionOptional_Close()
	this:Hide()
end

function NewBangHui_AuctionOptional_Help_Clicked() 
	PushEvent("CCSHOP_HELP", 236)
end