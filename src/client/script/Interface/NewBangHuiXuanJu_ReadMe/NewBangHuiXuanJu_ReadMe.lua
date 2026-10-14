local g_NewBangHuiXuanJu_ReadMe_Frame_UnifiedPosition = nil 
local g_objCareID = -1;

function NewBangHuiXuanJu_ReadMe_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end 

-- NewBangHuiXuanJu_ReadMe_Client => DefaultWindow
-- NewBangHuiXuanJu_ReadMe_Close => TLBB_ButtonClose
-- NewBangHuiXuanJu_ReadMe_Frame_Title => TLBB_DragTitle
function NewBangHuiXuanJu_ReadMe_OnLoad()
	g_NewBangHuiXuanJu_ReadMe_Frame_UnifiedPosition = NewBangHuiXuanJu_ReadMe_Frame:GetProperty("UnifiedPosition");
end

function NewBangHuiXuanJu_ReadMe_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		NewBangHuiXuanJu_ReadMe_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHuiXuanJu_ReadMe_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHuiXuanJu_ReadMe_On_Hide()
	elseif(event == "UI_COMMAND") then
		local nUIIdx = tonumber(arg0)
		if nUIIdx == 20170620 then
			NewBangHuiXuanJu_ReadMe_Init()
		end		
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_objCareID) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			NewBangHuiXuanJu_ReadMe_StopCareObject(g_objCareID)
			NewBangHuiXuanJu_ReadMe_On_Hide()
		end	
	end
end

function NewBangHuiXuanJu_ReadMe_StopCareObject(objCaredId)
	this:CareObject(objCaredId, 0, "NewBangHuiXuanJu_ReadMe");
	g_objCareID = -1;
end

function NewBangHuiXuanJu_ReadMe_Init()
	g_objCareID = DataPool : GetNPCIDByServerID(2);
	NewBangHuiXuanJu_ReadMe_BeginCareObject(g_objCareID)
	this:Show()
end

function NewBangHuiXuanJu_ReadMe_BeginCareObject(objid)
	g_Object = objid
	this:CareObject(g_Object, 1, "NewBangHuiXuanJu_ReadMe");
end

function NewBangHuiXuanJu_ReadMe_On_ResetPos()
	NewBangHuiXuanJu_ReadMe_Frame:SetProperty("UnifiedPosition", g_NewBangHuiXuanJu_ReadMe_Frame_UnifiedPosition)
end

function NewBangHuiXuanJu_ReadMe_On_Hide()
	this:Hide()
end


function NewBangHuiXuanJu_ReadMe_Close_Click()
end

