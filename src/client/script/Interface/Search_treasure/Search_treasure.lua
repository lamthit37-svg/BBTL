
local g_Search_treasure_Frame_UnifiedXPosition;
local g_Search_treasure_Frame_UnifiedYPosition;

function Search_treasure_PreLoad()

	this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function Search_treasure_OnLoad()

	g_Search_treasure_Frame_UnifiedXPosition	= Search_treasure_Frame:GetProperty("UnifiedXPosition");
	g_Search_treasure_Frame_UnifiedYPosition	= Search_treasure_Frame:GetProperty("UnifiedYPosition");

end


--=========================================================
-- 事件处理
--=========================================================
function Search_treasure_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 891375) then
		this:Hide()
		Search_treasure_Desc:ClearAllElement()
		Search_treasure_DragTitle:SetText("#{STRW_150514_328}")	
		local msg = Get_XParam_STR(0)
		if msg ~= nil and msg ~= "" then
			Search_treasure_Desc:AddTextElement(tostring(msg))
			this:Show();
		end	
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 891210) then
		this:Hide()
		Search_treasure_Desc:ClearAllElement()	
		Search_treasure_DragTitle:SetText("")	
		local msg = Get_XParam_STR(0)
		if msg ~= nil and msg ~= "" then
			Search_treasure_Desc:AddTextElement(tostring(msg))
			this:Show();
		end	
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 891211) then
		if this:IsVisible() then
			this:Hide()
			Search_treasure_Desc:ClearAllElement()
			Search_treasure_DragTitle:SetText("")	
		end
	end

	if( event == "ADJEST_UI_POS" ) then
		Search_treasure_ResetPos()
	end

	if( event == "VIEW_RESOLUTION_CHANGED" ) then
		Search_treasure_ResetPos()
	end	
end

--=========================================================
-- 关闭相应
--=========================================================
function Search_treasure_Close()

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_Search_treasure(objCaredId)

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_Search_treasure(objCaredId)

end

function Search_treasure_ResetPos()
	Search_treasure_Frame:SetProperty("UnifiedXPosition", g_Search_treasure_Frame_UnifiedXPosition);
	Search_treasure_Frame:SetProperty("UnifiedYPosition", g_Search_treasure_Frame_UnifiedYPosition);
end
