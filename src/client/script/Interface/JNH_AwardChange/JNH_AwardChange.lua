--嘉年华多余头饰替换
--!!!reloadscript =JNH_AwardChange
local g_JNH_AwardChange_Frame_UnifiedPosition = 0

local MAX_OBJ_DISTANCE = 3.0
local g_JNH_AwardChange_NpcId = -1;
local g_JNH_AwardChange_TargetId = -1

local g_ItemPos = -1

--===============================================
-- PreLoad()
--===============================================
function JNH_AwardChange_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	
	this:RegisterEvent("UPDATE_JNH_ITEM",false)	-- 从背包放入道具

	this:RegisterEvent("OBJECT_CARED_EVENT",false);           --某逻辑对象的某些发生改变，用于距离NPC够远则关闭界面
end

--===============================================
-- OnLoad()
--===============================================
function JNH_AwardChange_OnLoad()	
	g_JNH_AwardChange_Frame_UnifiedPosition = JNH_AwardChange_Frame:GetProperty("UnifiedPosition")

end

--===============================================
-- OnEvent()
--===============================================
function JNH_AwardChange_OnEvent(event)

	if event == "HIDE_ON_SCENE_TRANSED" and this:IsVisible()then
		JNH_AwardChange_OnHidden()
	elseif event == "ADJEST_UI_POS" and this:IsVisible()then
		JNH_AwardChange_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" and this:IsVisible()then
		JNH_AwardChange_On_ResetPos()
	end
	if event == "OBJECT_CARED_EVENT" then
		if(tonumber(arg0) ~= g_JNH_AwardChange_NpcId) then
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
			JNH_AwardChange_OnClose()
		end
	
		return
	end
	
	if event == "UPDATE_JNH_ITEM" and this:IsVisible()then
		JNH_AwardChange_UpdateItem(arg0)
	end

	if event == "UI_COMMAND" and tonumber(arg0) == 99976501 then
		local updateOrOpen = Get_XParam_INT(0)
		if(updateOrOpen == 1)then
			g_JNH_AwardChange_TargetId = Get_XParam_INT( 1 )
			JNH_AwardChange_BeginCareObject( g_JNH_AwardChange_TargetId )
			JNH_AwardChange_Open()
		elseif(updateOrOpen == 2)then
			JNH_AwardChange_UpdateItem(-1)
			JNH_AwardChange_OnHidden()
		end
		
	end
end

function JNH_AwardChange_Open()
	this:Show()
	OpenWindow("Packet")
	JNH_AwardChange_UpdateItem(-1)
end

function JNH_AwardChange_UpdateItem(index)
	if(tonumber(index) < 0 or index == nil)then

		JNH_AwardChange_Special_Button:SetActionItem(-1)

		if (g_ItemPos ~= -1) then
			LifeAbility:Lock_Packet_Item( g_ItemPos, 0 )
			g_ItemPos = -1
		end

	else
		local BagPos = tonumber(index)
		local itemid = PlayerPackage:GetItemTableIndex(BagPos)

		if(itemid < 0)then
			return
		end

		if itemid ~= 38008174 then
			PushDebugMessage("#{JJNH_251024_03}")
			return
		end
			
		--清除当前道具
		JNH_AwardChange_Special_Button:SetActionItem(-1)
		if (g_ItemPos ~= -1) then
			LifeAbility:Lock_Packet_Item( g_ItemPos, 0 )
			g_ItemPos = -1
		end

		--锁定道具
		LifeAbility:Lock_Packet_Item( BagPos, 1 )
		g_ItemPos = BagPos

		local theAction = DataPool:CreateActionItemForShow(itemid, 1)
		if (theAction:GetID() == 0) then
			return
		end

		JNH_AwardChange_Special_Button:SetActionItem(theAction:GetID())
		
	end
end

function JNH_AwardChange_OK_Clicked()

	if g_ItemPos == -1 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID( 999765 )
		Set_XSCRIPT_Function_Name( "ExchangeForRide" )
		Set_XSCRIPT_Parameter(0, g_JNH_AwardChange_TargetId)
		Set_XSCRIPT_Parameter(1, g_ItemPos)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function JNH_AwardChange_Resume()
	JNH_AwardChange_UpdateItem(-1)
end

function JNH_AwardChange_Cancel_Clicked()
	JNH_AwardChange_OnHidden()
end

function JNH_AwardChange_OnHidden()
	JNH_AwardChange_UpdateItem(-1)
	JNH_AwardChange_StopCareObject()
    this:Hide();
end

function JNH_AwardChange_On_ResetPos()
	JNH_AwardChange_Frame:SetProperty("UnifiedPosition", g_JNH_AwardChange_Frame_UnifiedPosition)
end

function JNH_AwardChange_BeginCareObject( objCaredId )
	g_JNH_AwardChange_NpcId = DataPool : GetNPCIDByServerID( objCaredId )
	if g_JNH_AwardChange_NpcId == -1 then
		this : Hide()
		return
	end
	this : CareObject( g_JNH_AwardChange_NpcId, 1, "JNH_AwardChange" )
end

function JNH_AwardChange_StopCareObject()
	this : CareObject( g_JNH_AwardChange_NpcId, 0, "JNH_AwardChange" )
	g_JNH_AwardChange_NpcId = -1
end