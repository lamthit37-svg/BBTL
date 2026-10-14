
local g_ThreeCity_WangQuan_Up_UnifiedPosition = nil 

local g_ObjServerID = -1

local m_WangQuan_Up_HuanShuNeed = 4

local m_ThreeCity_WangQuan_Up_Times = 0
local m_ThreeCity_WangQuan_Up_HuanShu = 0

function ThreeCity_WangQuan_Up_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
	this:RegisterEvent("OBJECT_CARED_EVENT")
	--this:RegisterEvent("ZHIZUN_EQUIP_UPGRADE_EXCHANGE")

end 

function ThreeCity_WangQuan_Up_OnLoad()

	g_ThreeCity_WangQuan_Up_UnifiedPosition = ThreeCity_WangQuan_Up_Frame:GetProperty("UnifiedPosition");
	
end

function ThreeCity_WangQuan_Up_OnEvent(event)

	if(event == "ADJEST_UI_POS") then
		ThreeCity_WangQuan_Up_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		ThreeCity_WangQuan_Up_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		ThreeCity_WangQuan_Up_OnHiden()
		
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		ThreeCity_WangQuan_Up_CareObj()
		
	elseif (event == "ZHIZUN_EQUIP_UPGRADE_EXCHANGE") then
		g_ObjServerID = tonumber( arg0 )
		m_ThreeCity_WangQuan_Up_Times = tonumber( arg1 )
		m_ThreeCity_WangQuan_Up_HuanShu = tonumber( arg2 )
		ThreeCity_WangQuan_Up_Init()	
		this:Show()
		
		if IsWindowShow("Packet") == false then
			ToggleContainer()
		end
		
		ThreeCity_WangQuan_Up_BeginCareObject(g_ObjServerID)
		
	end
	
end

function ThreeCity_WangQuan_Up_UpdateHuanShu( nHuanShu )

	if nHuanShu >= m_WangQuan_Up_HuanShuNeed then
		ThreeCity_WangQuan_Up_Text5:SetText( ScriptGlobal_Format("#{ZZZB_20220712_17}", nHuanShu) )
	else
		ThreeCity_WangQuan_Up_Text5:SetText( ScriptGlobal_Format("#{ZZZB_20220712_28}", nHuanShu) )
	end
	
end

function ThreeCity_WangQuan_Up_Init()
	
	ThreeCity_WangQuan_Up_UpdateHuanShu( m_ThreeCity_WangQuan_Up_HuanShu )
	
	if m_ThreeCity_WangQuan_Up_Times == 0 then
		ThreeCity_WangQuan_Up_Text7:SetText( "#{ZZZB_20220712_06}" )
	else
		ThreeCity_WangQuan_Up_Text7:SetText( "#{ZZZB_20220712_07}" )
	end
		
end

function ThreeCity_WangQuan_Up_OnOK()

	--判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZZZB_150811_15}")
		return
	end
	
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ExchangeItem" )
		Set_XSCRIPT_ScriptID( 880036 )
		Set_XSCRIPT_Parameter( 0, g_ObjServerID )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()	
	
end

function ThreeCity_WangQuan_Up_On_ResetPos()

	ThreeCity_WangQuan_Up_Frame:SetProperty("UnifiedPosition", g_ThreeCity_WangQuan_Up_UnifiedPosition)
	
end

function ThreeCity_WangQuan_Up_OnCloseClicked()

	this:Hide()
	
end

-- 关心npc
function ThreeCity_WangQuan_Up_CareObj()

	if(tonumber(arg0) ~= g_objCareID) then
		return;
	end
	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
		--取消关心
		ThreeCity_WangQuan_Up_StopCareObject(g_objCareID)
		ThreeCity_WangQuan_Up_OnHiden()
	end	
	
end

function ThreeCity_WangQuan_Up_StopCareObject(objCaredId)

	this:CareObject(objCaredId, 0, "ThreeCity_WangQuan_Up");
	g_objCareID = -1;
	
end

function ThreeCity_WangQuan_Up_BeginCareObject(objid)

	local nID = DataPool : GetNPCIDByServerID( objid )
	g_Object = nID
	this:CareObject(g_Object, 1);
	
end

