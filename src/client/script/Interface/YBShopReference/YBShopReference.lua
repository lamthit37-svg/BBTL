local g_WorldReference_Frame_UnifiedXPosition;
local g_WorldReference_Frame_UnifiedYPosition;
local g_YBShopRefTotalNum = 6
local g_YBShopRefTitle = {
	[1] = "#{FFSDGZ_120615_103}",
	[2] = "#{FFSDGZ_120615_105}",
	[3] = "#{FFSDGZ_120615_107}",
	[4] = "#{FFSDGZ_120615_109}",
	[5] = "#{FFSDGZ_120615_110}",
	[6] = "#{FFSDGZ_120615_112}",
}
local g_YBShopRefContent = {
	[1] = "#{FFSDGZ_120615_84}",
	[2] = "#{FFSDGZ_120615_106}",
	[3] = "#{FFSDGZ_120615_108}",
	[4] = "#{YBSD_081225_070}",
	[5] = "#{FFSDGZ_120615_111}",
	[6] = "#{SMSD_100127_01}",
}
function YBShopReference_PreLoad()
	this:RegisterEvent("OPEN_YBSHOPREFERENCE");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function YBShopReference_OnLoad()
	g_WorldReference_Frame_UnifiedXPosition	= YBShopReference_Frame:GetProperty("UnifiedXPosition");
	g_WorldReference_Frame_UnifiedYPosition	= YBShopReference_Frame:GetProperty("UnifiedYPosition");
end

function YBShopReference_OnEvent( event )
	if (event == "OPEN_YBSHOPREFERENCE") then
		YBShopReferenceGreeting_Desc:ClearAllElement();
		if arg0 == "yuanbao" then
			YBShopReference_PushMain()
		elseif arg0 == "bindyuanbao" then
		elseif arg0 == "gifttoken" then
		else
			YBShopReferenceGreeting_Desc:ClearAllElement();
			YBShopReferenceGreeting_Desc:AddTextElement(arg0)
		end
		this:Show();
	elseif( event == "ADJEST_UI_POS" ) then
		YBShopReference_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		YBShopReference_ResetPos()
	end
end

function YBShopReferenceOption_Clicked()
	pos1,pos2 = string.find(arg0,"#");
	pos3,pos4 = string.find(arg0,",");

	local strOptionID = -1;
	local strOptionExtra1 = string.sub(arg0, pos2+1,pos3-1 );
	local strOptionExtra2 = string.sub(arg0, pos4+1);

    local Data1 = tonumber( strOptionExtra1 )      --Data1为表的编号
    local Data2 = tonumber( strOptionExtra2 )      --Data2为表中内容的index

	YBShopReferenceGreeting_Desc:ClearAllElement();
	if Data2 > 0 and Data2 <= g_YBShopRefTotalNum then
		YBShopReferenceGreeting_Desc:AddTextElement( g_YBShopRefContent[Data2])
		local strBack = "回首页".."&0,"..(0).."$0"
		YBShopReferenceGreeting_Desc:AddOptionElement( strBack );
	elseif Data2 == 0 then
		YBShopReference_PushMain()
	end
end

function YBShopReference_ResetPos()
	YBShopReference_Frame:SetProperty("UnifiedXPosition", g_WorldReference_Frame_UnifiedXPosition);
	YBShopReference_Frame:SetProperty("UnifiedYPosition", g_WorldReference_Frame_UnifiedYPosition);
end

function YBShopReference_PushMain()
	YBShopReferenceGreeting_Desc:ClearAllElement();
	YBShopReferenceGreeting_Desc:AddTextElement( "#{FFSDGZ_120615_83}")
	for i = 1, g_YBShopRefTotalNum do
		YBShopReferenceGreeting_Desc:AddOptionElement( g_YBShopRefTitle[i].."&0,"..i.."$0" );
	end
end
