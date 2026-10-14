local g_BeiZhu_Channel = -1
local g_BeiZhu_Index = -1
local g_BeiZhu_Id = -1
local g_BeiZhu_ZoneworldId = -1
local g_BeiZhu_Name = ""
local g_BeiZhu_Remark = ""

function BeiZhu_PreLoad()
	this:RegisterEvent("OPEN_REMARK");
end

function BeiZhu_OnLoad()

end

function BeiZhu_OnEvent( event )
	if( event == "OPEN_REMARK" ) then
		g_BeiZhu_Channel = tonumber(arg0)
		g_BeiZhu_Index = tonumber(arg1)
		g_BeiZhu_Id = DataPool:GetFriend( g_BeiZhu_Channel, g_BeiZhu_Index, "ID" )
		g_BeiZhu_ZoneworldId = DataPool:GetFriend( g_BeiZhu_Channel, g_BeiZhu_Index, "ZONEWORLDID" )
		g_BeiZhu_Name = DataPool:GetFriend( g_BeiZhu_Channel, g_BeiZhu_Index, "NAME" )
		g_BeiZhu_Remark = DataPool:GetFriend( g_BeiZhu_Channel, g_BeiZhu_Index, "REMARK" )
		local str = ScriptGlobal_Format("#{BZXX_140915_15}", g_BeiZhu_Name)
		BeiZhu_Text1:SetText( str )
		BeiZhu_FeudalName:SetText( g_BeiZhu_Remark )
		BeiZhu_FeudalName:SetProperty("DefaultEditBox", "true")
		this:Show()
	end

end

function BeiZhu_Release_Button_Clicked()
	local strRemark = BeiZhu_FeudalName:GetText()
	DataPool:SetRemark( g_BeiZhu_Id, g_BeiZhu_ZoneworldId, strRemark )
	this:Hide()
end
