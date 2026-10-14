
local g_Frame_UnifiedPosition
local g_itemid = { 
	[0] = 38005693,
	[1] = 38003020,
}
--=========
-- PreLoad()
--=========
function HuaZhaoJie_Gift_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function HuaZhaoJie_Gift_OnLoad()
	
	g_Frame_UnifiedPosition = HuaZhaoJie_Gift_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function HuaZhaoJie_Gift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88892601) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			HuaZhaoJie_Gift_Open()
			this:Show()
		elseif bShow == 2 then		
			this:Hide()
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		HuaZhaoJie_Gift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		HuaZhaoJie_Gift_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		HuaZhaoJie_Gift_On_ResetPos()

	end
end


function HuaZhaoJie_Gift_Close()
	HuaZhaoJie_Gift_GiftItem:SetActionItem(-1)
	this:Hide()
end

--=========
-- 重置
--=========
function HuaZhaoJie_Gift_On_ResetPos()

	HuaZhaoJie_Gift_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function HuaZhaoJie_Gift_Open()

	HuaZhaoJie_Gift_GiftItem:SetActionItem(-1)
	local MyName = Player:GetName()
	HuaZhaoJie_Gift_LetterName:SetText(ScriptGlobal_Format("#{HZJZH_211221_21}",MyName))
	local itemid = g_itemid[KaJi:LuaFnGetKaJiType(61)]
	if Player:GetData("IsOriginalJD") == 1 then
		itemid = 38008437
	end
	local theAction = DataPool:CreateActionItemForShow(itemid, 1)
	if theAction:GetID() ~= 0 then
		HuaZhaoJie_Gift_GiftItem:SetActionItem(theAction:GetID());
		HuaZhaoJie_Gift_GiftItem:Show();
	end
	
end	

--=========
-- 点击领奖
--=========
function HuaZhaoJie_Gift_GetClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888926 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end
	
