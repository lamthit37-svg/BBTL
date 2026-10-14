--Blockade.lua

local g_Eventid=0;
local g_UserName=nil;
local g_GUIDH = -1;
local g_GUIDL = -1;
local g_ZoneWorldId = -1;
local g_SelIndex=-1;

function Blockade_PreLoad()

	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Blockade_OnLoad()

	Blockade_List:AddTextItem("#{FTXX_150702_2}" ,0)
	Blockade_List:AddTextItem("#{FTXX_150702_3}" ,1)
	Blockade_List:AddTextItem("#{FTXX_150702_4}" ,2)
	--Blockade_List:AddTextItem("#{FTXX_150702_5}" ,3)
	Blockade_List:SetCurrentSelect(0)
	g_SelIndex = 0;
		
	Blockade_Input:SetText("");
	Blockade_Input:Hide();
	Blockade_FengTingA:SetCheck( 1 );
	Blockade_FengTingC:SetCheck( 0 );
		
	g_Eventid = 0;
	g_UserName = nil;
		
end

-- OnEvent
function Blockade_OnEvent(event)
	if( event == "HIDE_ON_SCENE_TRANSED") then
		Blockade_Close();
		return;		
	end

end

function Blockade_LineChanged()
	local str , nIndex = Blockade_List:GetCurrentSelect()
	--if nIndex == 3 then
	--	Blockade_Input:Show();
	--else
	--	Blockade_Input:Hide();
	--end
	
	g_SelIndex = nIndex;
end

function Blockade_CheckClicked( index )
	if index == 0 then
		Blockade_FengTingC:SetCheck( 0 );
	end
	if index == 1 then
		Blockade_FengTingA:SetCheck( 0 );
	end
end

function Blockade_OK()

	local strReason = "";
	--if g_SelIndex == 3 then
	--	strReason = Blockade_Input:GetText();
	--	if strReason == nil or strReason == "" then
	--		PushDebugMessage("请输入封停原因");
	--		return
	--	end
	--end
	
	local nFengTingType = 1;	--1是A类封停，2是C类封停，默认为1
	if Blockade_FengTingA:GetCheck() == 1 then
		nFengTingType = 1;
	end
	if Blockade_FengTingC:GetCheck() == 1 then
		nFengTingType = 2;
	end
	
	-- if g_Eventid == 1 then
	-- 	Target:Lua_ForbidItConfirm(g_SelIndex, strReason, nFengTingType );
	-- end
	
	-- if g_Eventid == 2 and g_UserName ~= nil then
	-- 	FriendSearcher:ForbidItByNameAndGuidConfirm( g_UserName, g_GUIDH, g_GUIDL, g_ZoneWorldId, g_SelIndex, strReason, nFengTingType )
	-- end
	
	Blockade_Close()
	
end

function Blockade_Close()
	this:Hide();
end
