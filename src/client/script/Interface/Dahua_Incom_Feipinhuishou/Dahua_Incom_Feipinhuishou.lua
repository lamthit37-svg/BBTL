--!!!reloadscript =Dahua_Incom_Feipinhuishou
local g_Dahua_Incom_Feipinhuishou_Frame_UnifiedPosition = 0

local MAX_OBJ_DISTANCE = 3.0
local g_Dahua_Incom_Feipinhuishou_NpcId = -1;
local g_Dahua_Incom_Feipinhuishou_TargetId = -1 
local g_Dahua_Incom_Feipinhuishou_ItemPos = -1
local g_Dahua_Incom_Iteminfo = {
	[38006874] = 280,
	[10192099] = 238,
	[10101093] = 315,
	[39910146] = 210,
}
--===============================================
-- PreLoad()
--===============================================
function Dahua_Incom_Feipinhuishou_PreLoad()
	this:RegisterEvent("OPEN_DAHUA_INCOM_FEIPINHUISHOU")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)		-- 游戏分辨率发生了变化 
	this:RegisterEvent("DAHUA_INCOM_FEIPINHUISHOU_ITEM",false)	-- 从背包放入道具  
end

--===============================================
-- OnLoad()
--===============================================
function Dahua_Incom_Feipinhuishou_OnLoad()	
	g_Dahua_Incom_Feipinhuishou_Frame_UnifiedPosition = Dahua_Incom_Feipinhuishou_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function Dahua_Incom_Feipinhuishou_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" and this:IsVisible()then
		Dahua_Incom_Feipinhuishou_OnHidden()
	elseif event == "ADJEST_UI_POS" and this:IsVisible()then
		Dahua_Incom_Feipinhuishou_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()then
		Dahua_Incom_Feipinhuishou_On_ResetPos()
	end 	
	if event == "DAHUA_INCOM_FEIPINHUISHOU_ITEM" and this:IsVisible()then
		Dahua_Incom_Feipinhuishou_UpdateItem(arg0)
	end
	if event == "OPEN_DAHUA_INCOM_FEIPINHUISHOU" then 
 		Dahua_Incom_Feipinhuishou_Open() 
	end
end

function Dahua_Incom_Feipinhuishou_Open()
	this:Show()
	OpenWindow("Packet")
	Dahua_Incom_Feipinhuishou_UpdateItem(-1)
end

function Dahua_Incom_Feipinhuishou_UpdateItem(index) 
	if(tonumber(index) < 0 or index == nil)then 
		Dahua_Incom_Feipinhuishou_BeforeIcon:SetActionItem(-1) 
		if (g_Dahua_Incom_Feipinhuishou_ItemPos ~= -1) then
			LifeAbility:Lock_Packet_Item( g_Dahua_Incom_Feipinhuishou_ItemPos, 0 )
			g_Dahua_Incom_Feipinhuishou_ItemPos = -1
		end 
		Dahua_Incom_Feipinhuishou_AfterText1:SetText(ScriptGlobal_Format("#{DHLS_240611_102}",0))	
	else
		local BagPos = tonumber(index)
 
		--判断 是否已加锁
		if (PlayerPackage:IsLock(BagPos) == 1) then
			PushDebugMessage("#{DHLS_240611_104}")
			return
		end

		--判断 是否是可回收道具
		local itemid = PlayerPackage:GetItemTableIndex(BagPos)
		if(itemid < 0)then
			return
		end
		 
		if g_Dahua_Incom_Iteminfo[itemid] == nil or type(g_Dahua_Incom_Iteminfo[itemid]) ~= "number"  then
			PushDebugMessage("#{DHLS_240611_103}")
			return
		end

		local BindStatus = PlayerPackage:GetItemBindStatusByIndex(BagPos)
		if BindStatus == 1 then
			PushDebugMessage("#{DHLS_240611_103}")
			return
		end
		
		--清除当前道具
		Dahua_Incom_Feipinhuishou_BeforeIcon:SetActionItem(-1)
		if (g_Dahua_Incom_Feipinhuishou_ItemPos ~= -1) then
			LifeAbility:Lock_Packet_Item( g_Dahua_Incom_Feipinhuishou_ItemPos, 0 )
			g_Dahua_Incom_Feipinhuishou_ItemPos = -1
		end

		--锁定道具
		LifeAbility:Lock_Packet_Item( BagPos, 1 )
		g_Dahua_Incom_Feipinhuishou_ItemPos = BagPos

		local nItemNum = PlayerPackage:GetBagItemNum(BagPos);

		local theAction = DataPool:CreateActionItemForShow(itemid, nItemNum)
		if (theAction:GetID() == 0) then
			return
		end 
		Dahua_Incom_Feipinhuishou_BeforeIcon:SetActionItem(theAction:GetID())
		Dahua_Incom_Feipinhuishou_AfterText1:SetText(ScriptGlobal_Format("#{DHLS_240611_102}",g_Dahua_Incom_Iteminfo[itemid]*nItemNum))	
		
	end
end

function Dahua_Incom_Feipinhuishou_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID( 501006 )
		Set_XSCRIPT_Function_Name( "FenJie" )
		Set_XSCRIPT_Parameter(0, g_Dahua_Incom_Feipinhuishou_ItemPos)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	this:Hide();
end

function Dahua_Incom_Feipinhuishou_Clear()
	Dahua_Incom_Feipinhuishou_UpdateItem(-1)
end

function Dahua_Incom_Feipinhuishou_OnClose()
	Dahua_Incom_Feipinhuishou_OnHidden()
end

function Dahua_Incom_Feipinhuishou_OnHidden()
	Dahua_Incom_Feipinhuishou_UpdateItem(-1) 
    this:Hide();
end

--=========================================================
-- 界面位置
--=========================================================
function Dahua_Incom_Feipinhuishou_On_ResetPos()
	Dahua_Incom_Feipinhuishou_Frame:SetProperty("UnifiedPosition", g_Dahua_Incom_Feipinhuishou_Frame_UnifiedPosition)
end
 
function Dahua_Incom_Feipinhuishou_checkitem(itemid)
	for i = 1, table.getn(g_Dahua_Incom_Iteminfo) do
		if g_Dahua_Incom_Iteminfo[i] == itemid then
			return 1
		end
	end
	return 0
end

function Dahua_Incom_Feipinhuishou_Help()
	PushEvent("CCSHOP_HELP", 220)
end