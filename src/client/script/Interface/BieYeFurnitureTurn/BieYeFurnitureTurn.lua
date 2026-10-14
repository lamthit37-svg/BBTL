
local BieYeFurnitureTurn_OkState = 0
local BieYeFurnitureTurn_Frame_UnifiedPosition;
local BieYeFurnitureObjId = -1


function BieYeFurnitureTurn_PreLoad()
	this:RegisterEvent("BIEYEFURNITURETRUESHOW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
end

function BieYeFurnitureTurn_OnLoad() 
	BieYeFurnitureTurn_Frame_UnifiedPosition = BieYeFurnitureTurn_Frame:GetProperty("UnifiedPosition");
end

function BieYeFurnitureTurn_OnEvent(event) 

	if event == "BIEYEFURNITURETRUESHOW" then
		if tonumber(arg0) == 1 then
			BieYeFurnitureObjId = tonumber(arg1)
			BieYeFurnitureTurn_OkState = 0
			BieYeUI:BeginRotationFurniture(BieYeFurnitureObjId)
			local sz_BieYeName = BieYeUI:GetFurnitureNameForObjId()
			BieYeFurnitureTurn_Name:SetText(sz_BieYeName)
			this:Show()
		else
			this:Hide()
		end
	
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeFurnitureTurn_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeFurnitureTurn_Frame_On_ResetPos()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide() 
	end
end

function BieYeFurnitureTurn_Frame_On_ResetPos()
  BieYeFurnitureTurn_Frame:SetProperty("UnifiedPosition", BieYeFurnitureTurn_Frame_UnifiedPosition);
end

function BieYeFurnitureTurn_OnHiden()
	BieYeUI:CancelRotationFurniture(BieYeFurnitureObjId,BieYeFurnitureTurn_OkState)
	BieYeFurnitureTurn_OkState = 0
	BieYeFurnitureObjId = -1
end

function OnBieYeFurnitureTurn_TurnLeft()
	BieYeUI:RotationFurniture(1)
end

function OnBieYeFurnitureTurn_TurnRight()
	BieYeUI:RotationFurniture(0)
end

function OnBieYeFurnitureTurn_Ok()
	BieYeFurnitureTurn_OkState = BieYeUI:OkRotationFurniture(BieYeFurnitureObjId)
	if BieYeFurnitureTurn_OkState ~= 1 then
		this:Hide()
	end
end

function OnBieYeFurnitureTurn_Cancel()
	this:Hide()
end