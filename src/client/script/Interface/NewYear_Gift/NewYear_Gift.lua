
local NewYear_Gift_g_UnifiedPosition = nil
local NewYear_Gift_Normal = 38002948
local NewYear_Gift_KaJi = 38003009
local NewYear_Gift_ShowItem = 0

function NewYear_Gift_PreLoad()

	
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	this:RegisterEvent("UI_COMMAND")
end

--===============================================
-- OnLoad()
--===============================================
function NewYear_Gift_OnLoad()

end

--===============================================
-- OnEvent()
--===============================================
function NewYear_Gift_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber( arg0 ) == 88880301) then --打开界面消息 2492 1702
		local nFlag = Get_XParam_INT( 0 );
		if nFlag == 1 then
			local szPlayerName = Player:GetName();
			local str = ScriptGlobal_Format("#{SDLB_211020_04}", tostring(szPlayerName))
			NewYear_Gift_LetterName:SetText(str)

			if KaJi:LuaFnGetKaJiType(37) > 0 then
				NewYear_Gift_ShowItem = NewYear_Gift_KaJi
			else
				NewYear_Gift_ShowItem = NewYear_Gift_Normal
			end

			local actionBonus = DataPool:CreateActionItemForShow(NewYear_Gift_ShowItem, 1)
			if actionBonus:GetID() ~= 0 then
				NewYear_Gift_GiftItem:SetActionItem(actionBonus:GetID())	
			end

			this:Show()
		elseif nFlag == 0 then
			NewYear_Gift_Close()
		end
		
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		NewYear_Gift_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		NewYear_Gift_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end


function NewYear_Gift_ResetPos()
    NewYear_Gift_Frame:SetProperty("UnifiedPosition",NewYear_Gift_g_UnifiedPosition)
end



function NewYear_Gift_Close()
	this:Hide()
end

function NewYear_Gift_lingqu()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888803 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
	
end




