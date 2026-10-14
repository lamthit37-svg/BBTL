----------------------
-- GuiGu_YuGao_02 ---

local MAX_OBJ_DISTANCE = 3.0;
local HUANGBANG_NPC_ID = -1;
local objCared = -1;
--===============================================
-- PreLoad()
--===============================================
function GuiGu_YuGao_02_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	
end

--===============================================
-- OnLoad()
--===============================================
function GuiGu_YuGao_02_OnLoad()
	
end

--===============================================
-- OnEvent()
--===============================================
function GuiGu_YuGao_02_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 2016101110) then
		objCared = -1
			
		if Get_XParam_INT(1) == 1 then
			HUANGBANG_NPC_ID = Get_XParam_INT(0);
			objCared = DataPool : GetNPCIDByServerID(HUANGBANG_NPC_ID);
			this:CareObject(objCared, 1, "GuiGu_YuGao_02");
		end
	
		this:Show()
	
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
				--取消关心
			this:CareObject(objCared, 0, "GuiGu_YuGao_02");
			this:Hide()
		end
	end
	
end


--===============================================
-- Close()
--===============================================
function GuiGu_YuGao_02_Close()

	return this:Hide()
end