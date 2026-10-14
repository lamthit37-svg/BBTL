local g_Frame_UnifiedXPosition_AnniversaryGift;
local g_Frame_UnifiedYPosition_AnniversaryGift;

local objCared = -1;

function AnniversaryGift_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("UI_COMMAND")
	
end

function AnniversaryGift_OnLoad()
	g_Frame_UnifiedXPosition_AnniversaryGift	= AnniversaryGift_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition_AnniversaryGift	= AnniversaryGift_Frame:GetProperty("UnifiedYPosition");	
end

function AnniversaryGift_OnEvent(event)

	if(event == "UI_COMMAND") then
		local comefrom = tonumber(arg0)	
		if comefrom == 89067501 then
		
			if this:IsVisible() then
				return
			end

			--关心NPC
			objCared = DataPool : GetNPCIDByServerID(Get_XParam_INT(0))
			this:CareObject(objCared, 1, "AnniversaryGift");				
		
			AnniversaryGift_UpdateUI( )
		end
	
	elseif (event == "ADJEST_UI_POS" ) then
		AnniversaryGift_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		AnniversaryGift_ResetPos()			
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		AnniversaryGift_Clear()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			--取消关心
			this:CareObject(objCared, 0, "AnniversaryGift");
		end
	end
	
end

function AnniversaryGift_UpdateUI( )
	AnniversaryGift_Clear()
	this:Show()
end

function AnniversaryGift_ResetPos()
	AnniversaryGift_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition_AnniversaryGift);
	AnniversaryGift_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition_AnniversaryGift);
end

function AnniversaryGift_OnHiden()
	AnniversaryGift_Clear()
end

function AnniversaryGift_Clear()
	--取消关心
	this:CareObject(objCared, 0, "WanJieGu_Mission1");	
	this:Hide()
end

-- function AnniversaryGift_Help_Clicked(index)
	-- -- Clear_XSCRIPT()
		-- -- Set_XSCRIPT_Function_Name("ZhouNianTalk")
		-- -- Set_XSCRIPT_ScriptID(890675)
		-- -- Set_XSCRIPT_Parameter(0,objCared)
		-- -- Set_XSCRIPT_ParamCount(1)
	-- -- Send_XSCRIPT()	
-- end