--DailyShop_LiBao_LiBao
local g_DailyShop_LiBao_UnifiedPosition;

local g_IsSelect = {}
local g_nGroup = 0
local g_nPool = 0
local g_Mask = {}
local g_ActionButton = {}
function DailyShop_LiBao_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OPEN_DAILYSHOP_LIBAO",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

end

function DailyShop_LiBao_OnLoad()	

	g_DailyShop_LiBao_UnifiedPosition = DailyShop_LiBao_Frame:GetProperty("UnifiedPosition")
	
end

function DailyShop_LiBao_OnEvent(event)

	if ( event == "OPEN_DAILYSHOP_LIBAO" ) then
		g_nGroup = tonumber(arg0)
		g_nPool = tonumber(arg1)
		DailyShop_LiBao_Update()

	elseif (event == "ADJEST_UI_POS" ) then
		DailyShop_LiBao_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DailyShop_LiBao_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

function DailyShop_LiBao_ClearData()
	for i = 1, 20 do
		g_IsSelect[i] = 0
	end
end
--=========================================================
--更新界面
--=========================================================
function DailyShop_LiBao_Update()

	DailyShop_LiBao_ClearData()

	DailyShop_LiBao_ListClient:Clear()

	local nCanSelectNum = DataPool:LuaFnGetDailyShopSelectNum(g_nGroup, g_nPool)
	DailyShop_LiBao_Explain:SetText(ScriptGlobal_Format("#{RXLB_240709_09}", nCanSelectNum))

	local nChooseNum = DataPool:LuaFnGetDailyShopChooseNum(g_nGroup, g_nPool)
	if nChooseNum <= 0 then
		return
	end

	local j = 0
	for i = 1, nChooseNum do
		local bar1 = DailyShop_LiBao_ListClient:AddChild("DailyShop_LiBao_ListContent")
		if not bar1 then
    		break
  		end		
		
		local nItemID, num = DataPool:LuaFnGetDailyShopItemInPool(g_nGroup, g_nPool, i)
		
		local oActionBtn = bar1:GetSubItem("DailyShop_LiBao_Item");	
		if oActionBtn ~= nil then
			local theAction = DataPool:CreateActionItemForShow(nItemID, num)
			oActionBtn:Show()
			oActionBtn:SetActionItem( theAction:GetID() );
			g_Mask[i]  = bar1:GetSubItem("DailyShop_LiBao_Item1_Mask")
			g_Mask[i]:Hide();
			oActionBtn:SetEvent( "Clicked", string.format("DailyShop_LiBao_ItemClicked(%d)",i) )	
			g_ActionButton[i] =  oActionBtn
		end

	end
	
	this:Show()
	this:Activate()

	DailyShop_LiBao_OK:SetToolTip("#{RXLB_240709_13}")
end	


function DailyShop_LiBao_ItemClicked(index)
	if index <= 0 or index > 20 then
		return
	end

	if g_IsSelect[index] == 1 then
		g_Mask[index]:Hide()
		g_IsSelect[index] = 0
	else
		local nSelectNum = 0
		for i = 1, 20 do
			if g_IsSelect[i] == 1 then
				nSelectNum = nSelectNum + 1
			end	
		end

		local nCanSelectNum = DataPool:LuaFnGetDailyShopSelectNum(g_nGroup, g_nPool)
		if nCanSelectNum <= 0 then
			return
		end

		if nSelectNum < nCanSelectNum then
			g_Mask[index]:Show()
			g_IsSelect[index] = 1
			return
		else
			PushDebugMessage("多了不让选！！！")
		end

		
	end
end

--=========================================================
--商店说明
--=========================================================
function DailyShop_LiBao_Help_Clicked()
	PushEvent("CCSHOP_HELP", 118)
end

--=========================================================
--关闭
--=========================================================
function DailyShop_LiBao_Close_Clicked()
	for i = 1, table.getn(g_ActionButton) do
		if g_ActionButton[i] ~= nil then
			g_ActionButton[i]:SetActionItem(-1)
			g_ActionButton[i] = nil
		end
	end
	
	DailyShop_LiBao_ListClient:Clear()
	DailyShop_LiBao_ClearData()
	this:Hide()
end

function DailyShop_LiBao_OnHiden()
	DailyShop_LiBao_Close_Clicked()
end

--=========================================================
--刷新位置
--=========================================================
function DailyShop_LiBao_On_ResetPos()
	DailyShop_LiBao_Frame:SetProperty("UnifiedPosition", g_DailyShop_LiBao_UnifiedPosition);
end


function DailyShop_LiBao_OK_Clicked()

	local nSelectNum = 0
	local userSelectIndex = {0,0,0,0}
	local j = 1
	for i = 1, 20 do
		if g_IsSelect[i] == 1 then
			nSelectNum = nSelectNum + 1
			userSelectIndex[j] = i
			j = j + 1
		end	
	end

	local nCanSelectNum = DataPool:LuaFnGetDailyShopSelectNum(g_nGroup, g_nPool)
	if nCanSelectNum <= 0 then
		return
	end

	if nSelectNum ~= nCanSelectNum then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "SelectItem" )
		Set_XSCRIPT_ScriptID(999360)
		Set_XSCRIPT_Parameter(0,g_nPool)
		Set_XSCRIPT_Parameter(1,userSelectIndex[1])
		Set_XSCRIPT_Parameter(2,userSelectIndex[2])
		Set_XSCRIPT_Parameter(3,userSelectIndex[3])
		Set_XSCRIPT_Parameter(4,userSelectIndex[4])
		Set_XSCRIPT_ParamCount(5)
	Send_XSCRIPT()

	DailyShop_LiBao_OnHiden()
end

