--【2021Q2】西瓜节整合界面设计-节日礼包界面

local g_Frame_UnifiedPosition

--=========
-- PreLoad()
--=========
function XiGua_Shop_Gift_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function XiGua_Shop_Gift_OnLoad()
	
	g_Frame_UnifiedPosition = XiGua_Shop_Gift_Frame_BK:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function XiGua_Shop_Gift_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88809701) then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			XiGua_Shop_Gift_Open()
			this:Show()
		elseif bShow == 2 then		
			this:Hide()
		end
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		XiGua_Shop_Gift_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		XiGua_Shop_Gift_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		XiGua_Shop_Gift_On_ResetPos()

	end
end


function XiGua_Shop_Gift_Close()
	XiGua_Shop_Gift_Page_Item:SetActionItem(-1)
	this:Hide()
end

--=========
-- 重置
--=========
function XiGua_Shop_Gift_On_ResetPos()

	XiGua_Shop_Gift_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开
--=========
function XiGua_Shop_Gift_Open()

	local nItemid = 38006409
	local g_KJ_XIGUAJIELIBAO = 92--卡级服
	if Player:GetData("IsOriginalJD") == 1 then--删减服
		nItemid = 38008650
	elseif KaJi:LuaFnGetKaJiType(g_KJ_XIGUAJIELIBAO) == 1 then--卡级服
		nItemid = 38003049
	end

	XiGua_Shop_Gift_Page_Item:SetActionItem(-1)
	local MyName = Player:GetName()
	XiGua_Shop_Gift_Page_Title:SetText(ScriptGlobal_Format("#{XGZH_200628_14}",MyName))
	local theAction = DataPool:CreateActionItemForShow(nItemid, 1)
	if theAction:GetID() ~= 0 then
		XiGua_Shop_Gift_Page_Item:SetActionItem(theAction:GetID());
		XiGua_Shop_Gift_Page_Item:Show();
	end
	
end	

--=========
-- 点击领奖
--=========
function XiGua_Shop_Gift_GetClick(  )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" )
		Set_XSCRIPT_ScriptID( 888097 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()	
	
end
	
