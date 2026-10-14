--------------------------------------------
-- ZhenYuanGold_FenLi.lua
-- !!!reloadscript =ZhenYuanGold_FenLi
--------------------------------------------

-- 好友界面的默认位置
local g_ZhenYuanGold_FenLiFrame_UnifiedXPosition;
local g_ZhenYuanGold_FenLiFrame_UnifiedYPosition;


local g_ZhenYuanGold_FenLi_CareObj = -1
local g_ZhenYuanGold_FenLi_MaxDistance = 10
local g_ZhenYuanGold_FenLi_MaxRow = 4
local g_ZhenYuanGold_FenLi_MaxLine = 6
local g_ZhenYuanGold_FenLi_BagIndexBegin = 36
local g_ZhenYuanGold_FenLi_SelectBagIndex = -1
local g_ZhenYuanGold_FenLi_SelectNeedQuality = 6
local g_ZhenYuanGold_FenLi_RightItem2_Id = 38001178

local g_ZhenYuanGold_FenLi_BagItemAction = {}
local reward_item = 38001178 


--===============================================
-- PreLoad()
--===============================================
function ZhenYuanGold_FenLi_PreLoad()

	

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("PNEUMA_DRAG_TO_FENLI",false)
	this:RegisterEvent("PNEUMAITEM_CHANGED",false)
	this:RegisterEvent("PNEUMALIST_CHANGED",false)
	
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

--===============================================
-- OnLoad()
--===============================================
function ZhenYuanGold_FenLi_OnLoad()
	
	for i=1,g_ZhenYuanGold_FenLi_MaxLine do
		for j=1,g_ZhenYuanGold_FenLi_MaxRow do
			local nIndex = (i-1)*g_ZhenYuanGold_FenLi_MaxRow+j
			g_ZhenYuanGold_FenLi_BagItemAction[nIndex] = _G[string.format("ZhenYuanGold_FenLi_Space_Line%d_Row%d_button",i,j)]
			g_ZhenYuanGold_FenLi_BagItemAction[nIndex]:SetProperty("DragAcceptName", "B"..tostring(g_ZhenYuanGold_FenLi_BagIndexBegin+nIndex-1))
		end
	end
	ZhenYuanGold_FenLi_ItemFrame_Left_Item:SetProperty("DragAcceptName", "F")
	ZhenYuanGold_FenLi_ItemFrame_Left_Item:SetProperty("DraggingEnabled", "True")
	ZhenYuanGold_FenLi_ItemFrame_Right_Item1:SetProperty("DraggingEnabled", "False")
	ZhenYuanGold_FenLi_ItemFrame_Right_Item2:SetProperty("DraggingEnabled", "False")
	-- 保存好友界面的默认相对位置
	g_ZhenYuanGold_FenLiFrame_UnifiedXPosition	= ZhenYuanGold_FenLi_Frame:GetProperty("UnifiedXPosition");
	g_ZhenYuanGold_FenLiFrame_UnifiedYPosition	= ZhenYuanGold_FenLi_Frame:GetProperty("UnifiedYPosition");

end

--===============================================
-- OnEvent()
--===============================================
function ZhenYuanGold_FenLi_OnEvent( event )
	-- 打开界面
	if ( event == "UI_COMMAND" and 89287801 == tonumber(arg0) ) then
		local npcid = Get_XParam_INT(0)
		if( npcid ~= -1 ) then
			g_ZhenYuanGold_FenLi_CareObj = DataPool:GetNPCIDByServerID(npcid)
		end
		ZhenYuanGold_FenLi_ClearData()
		ZhenYuanGold_FenLi_Select(g_ZhenYuanGold_FenLi_SelectBagIndex)
		this:Show()
		ZhenYuanGold_FenLi_CareObject()
	elseif (event == "PNEUMA_DRAG_TO_FENLI") then
		ZhenYuanGold_FenLi_Select(tonumber(arg0))
	elseif (event == "PNEUMAITEM_CHANGED" or event=="PNEUMALIST_CHANGED") then
		ZhenYuanGold_FenLi_Select(g_ZhenYuanGold_FenLi_SelectBagIndex)
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		ZhenYuanGold_FenLi_Close()
	elseif(event == "OBJECT_CARED_EVENT") then
		if (tonumber(arg0) ~= g_ZhenYuanGold_FenLi_CareObj) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > g_ZhenYuanGold_FenLi_MaxDistance) or arg1=="destroy") then
			ZhenYuanGold_FenLi_Close()
		end
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		ZhenYuanGold_FenLi_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		ZhenYuanGold_FenLi_ResetPos()
	
	end
end


--================================================
-- 隐藏界面
--================================================
function ZhenYuanGold_FenLi_Close()
	ZhenYuanGold_FenLi_StopCareObject()
	ZhenYuanGold_FenLi_ClearData()
	this:Hide();
end


function ZhenYuanGold_FenLi_ClearData()
	g_ZhenYuanGold_FenLi_SelectBagIndex = -1
end

--================================================
-- 恢复好友界面的默认相对位置
--================================================
function ZhenYuanGold_FenLi_ResetPos()

	ZhenYuanGold_FenLi_Frame:SetProperty("UnifiedXPosition", g_ZhenYuanGold_FenLiFrame_UnifiedXPosition);
	ZhenYuanGold_FenLi_Frame:SetProperty("UnifiedYPosition", g_ZhenYuanGold_FenLiFrame_UnifiedYPosition);
	
end

function ZhenYuanGold_FenLi_Update()
	local nSize = g_ZhenYuanGold_FenLi_MaxRow * g_ZhenYuanGold_FenLi_MaxLine
	for i=1,nSize  do
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", g_ZhenYuanGold_FenLi_BagIndexBegin+i-1)
		g_ZhenYuanGold_FenLi_BagItemAction[i]:SetActionItem(-1)
		if theAction:GetID() ~= 0 then
			g_ZhenYuanGold_FenLi_BagItemAction[i]:SetActionItem(theAction:GetID())
			if g_ZhenYuanGold_FenLi_SelectBagIndex == (g_ZhenYuanGold_FenLi_BagIndexBegin+i-1) then
				g_ZhenYuanGold_FenLi_BagItemAction[i]:Disable()
			else
				g_ZhenYuanGold_FenLi_BagItemAction[i]:Enable()
			end
		end
	end
end

function ZhenYuanGold_FenLi_ItemBtnClicked(x,y)
	local nIndexPos = g_ZhenYuanGold_FenLi_BagIndexBegin+(x-1)*4+y-1
	ZhenYuanGold_FenLi_Select(nIndexPos)
end

function ZhenYuanGold_FenLi_Select(nIndexPos)
	ZhenYuanGold_FenLi_ItemFrame_Left_Item:SetActionItem(-1)
	ZhenYuanGold_FenLi_ItemFrame_Right_Item1:SetActionItem(-1)
	ZhenYuanGold_FenLi_ItemFrame_Right_Item2:SetActionItem(-1)
	if(ZhenYuanGold_FenLi_CheckDrag(nIndexPos) == 0 ) then
		g_ZhenYuanGold_FenLi_SelectBagIndex = -1
		ZhenYuanGold_FenLi_Update()
		return
	end
	g_ZhenYuanGold_FenLi_SelectBagIndex = nIndexPos
	if(g_ZhenYuanGold_FenLi_SelectBagIndex ~= -1 ) then
		g_ZhenYuanGold_FenLi_SelectBagIndex = nIndexPos
		local theAction = Pneuma:SetPneumaBeforeFenLiGold( g_ZhenYuanGold_FenLi_SelectBagIndex )
		if theAction and theAction:GetID() ~= 0 then
			ZhenYuanGold_FenLi_ItemFrame_Left_Item:SetActionItem(theAction:GetID())
		end
		local theAction1 = Pneuma:SetPneumaAfterFenLiGold(g_ZhenYuanGold_FenLi_SelectBagIndex)
		if theAction1 and theAction1:GetID() ~= 0 then
			ZhenYuanGold_FenLi_ItemFrame_Right_Item1:SetActionItem(theAction1:GetID())
		end
		local theAction2 = DataPool:CreateActionItemForShow(g_ZhenYuanGold_FenLi_RightItem2_Id,1)
		if theAction2 and theAction2:GetID() ~= 0 then
			ZhenYuanGold_FenLi_ItemFrame_Right_Item2:SetActionItem(theAction2:GetID())
		end
	end
	ZhenYuanGold_FenLi_Update()
end

function ZhenYuanGold_FenLi_CheckDrag(nIndexPos)
	local theAction = Pneuma:EnumPneumaItem("pneuma",  nIndexPos )
	local nQuality 	= Pneuma:GetPneumaProperty( nIndexPos, 2 )
	if theAction:GetID() ~= 0 and nQuality ~= -1 then
		if ZhenYuanConvert_CheckLock( nIndexPos ) == 1 then
            PushDebugMessage("#{ZYFL_180718_14}")
			return 0
		else
			if(nQuality < g_ZhenYuanGold_FenLi_SelectNeedQuality) then
				PushDebugMessage("#{ZYFL_180718_13}")
				return 0
			end
		end
	else
		return 0
	end
	return 1
end

function ZhenYuanConvert_CheckLock( nPosIndex )
	local theAction,bLocked,_,nElapsedTime  = Pneuma:EnumPneumaItem( "pneuma", nPosIndex )
	if(theAction:GetID() == 0 ) then
		return 0
	end
	local unlocktime = Pneuma:GetPneumaItemProperty( nPosIndex, 8 )
	if unlocktime==nil then
		return 0
	end

	if unlocktime <= 0 then
		return 0
	elseif unlocktime > 1 and 259200>nElapsedTime then--正在解锁中
		return 1
	elseif unlocktime >1 and 259200<=nElapsedTime then--解锁完成，即未加锁
		return 0
	else
		return 1
	end
	return 0
end

function ZhenYuanGold_FenLi_FenLiClick()
	if(g_ZhenYuanGold_FenLi_SelectBagIndex <= 0) then
		PushDebugMessage("#{ZYFL_180718_17}")
		return
	end
	if(ZhenYuanConvert_CheckLock( g_ZhenYuanGold_FenLi_SelectBagIndex ) == 1) then
		PushDebugMessage("#{ZYFL_180718_18}")
		return
	end
	if(ZhenYuanGold_FenLi_CheckDrag(g_ZhenYuanGold_FenLi_SelectBagIndex) == 0) then
		return
	end

	if GetBagSpace(reward_item) < 1 then
		PushDebugMessage("#{ZYFL_180718_20}")
		return 
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PneumaDismantling")
		Set_XSCRIPT_ScriptID(892878)
		Set_XSCRIPT_Parameter(0,g_ZhenYuanGold_FenLi_SelectBagIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
	g_ZhenYuanGold_FenLi_SelectBagIndex = -1
	ZhenYuanGold_FenLi_Select(g_ZhenYuanGold_FenLi_SelectBagIndex)
end

function ZhenYuanGold_FenLi_LeftItem_RBClick()
	ZhenYuanGold_FenLi_Select(-1)
end

function ZhenYuanGold_FenLi_CareObject()
	this:CareObject(g_ZhenYuanGold_FenLi_CareObj, 1, "ZhenYuanGold_FenLi")
	return
end

function ZhenYuanGold_FenLi_StopCareObject()
	this:CareObject(g_ZhenYuanGold_FenLi_CareObj, 0, "ZhenYuanGold_FenLi")
	g_ZhenYuanGold_FenLi_CareObj = -1
	return
end



