local curHistroyPointer = 0;
local maxHistroyNumber = 0;
local curFriendGroup = 0;
local curFriendIndex = 0;
local numberPerPage = 10;
local g_HistoryCorrespondence_Frame_UnifiedXPosition;
local g_HistoryCorrespondence_Frame_UnifiedYPosition;
--===============================================
-- OnLoad()
--===============================================
function HistoryCorrespondence_PreLoad()

	this:RegisterEvent("OPEN_HISTROY",true);
	this:RegisterEvent("OPEN_SYSTEMINFO",true);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function HistoryCorrespondence_OnLoad()
	g_HistoryCorrespondence_Frame_UnifiedXPosition	= HistoryCorrespondence_Frame:GetProperty("UnifiedXPosition");
	g_HistoryCorrespondence_Frame_UnifiedYPosition	= HistoryCorrespondence_Frame:GetProperty("UnifiedYPosition");
end

--===============================================
-- OnEvent()
--===============================================
function HistoryCorrespondence_OnEvent(event)
	
	if ( event == "OPEN_HISTROY" ) then
		HistoryCorrespondence_Show( arg0, arg1 );
	elseif( event == "OPEN_SYSTEMINFO" ) then
		HistoryCorrespondence_System_Show();
	elseif( event == "ADJEST_UI_POS" ) then
		HistoryCorrespondence_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		HistoryCorrespondence_ResetPos()
	end
end
function HistoryCorrespondence_System_Show()
	this:Show();
	HistoryCorrespondence_Log:ClearListBox();
	HistoryCorrespondence_PageHeader:SetText( "#gFF0FA0系统信息" );
	HistoryCorrespondence_PageDown:Disable();
	HistoryCorrespondence_PageUp:Disable();
	local nNumber = DataPool:GetSystemHistroyNumber();
	local nIndex = nNumber - 100;
	if( nIndex < 0 ) then
		nIndex = 0;
	end
	local i = nNumber - 1;
	while i >= nIndex do 
		str = DataPool:GetSystemHistroy( tonumber( i ), "TIME" );
		str = str.."#r";
		str = str..DataPool:GetSystemHistroy( tonumber( i ), "CONTEX" );
		if SystemSetup:IsClassic() == 1 then
			HistoryCorrespondence_Log:AddItem( str, i, "FFFFFFFF", 4 );
		else
			HistoryCorrespondence_Log:AddItem( str, i, "FFFFFFFF", 4 );
		end
		i = i - 1;
	end
end
function HistoryCorrespondence_Show( nChannel, nIndex )
	
	maxHistroyNumber = Friend:GetHistroyNumber( tonumber( nChannel ), tonumber( nIndex ) );
	curHistroyPointer = maxHistroyNumber;
	curFriendGroup = nChannel;
	curFriendIndex = nIndex;
	HistoryCorrespondence_Update();
	HistoryCorrespondence_PageHeader:SetText( "#gFF0FA0历史信件" );
	this:Show();
end

function HistoryCorrespondence_Update()
	local curPageStriing;
	local i = curHistroyPointer -1 ;
	local minHistroyPointer = curHistroyPointer - numberPerPage;
	if( minHistroyPointer < 0 ) then 
		minHistroyPointer = 0;
	end
	if( minHistroyPointer == 0 ) then
		HistoryCorrespondence_PageDown:Disable();
	else
		HistoryCorrespondence_PageDown:Enable();
	end
	if( curHistroyPointer == maxHistroyNumber ) then
		HistoryCorrespondence_PageUp:Disable();
	else
		HistoryCorrespondence_PageUp:Enable();
	end
	HistoryCorrespondence_Log:ClearListBox();
	local str = ""; 
	while i >= minHistroyPointer do 
		str = Friend:GetHistroyData( tonumber( curFriendGroup ), tonumber( curFriendIndex ), tonumber(i), "TIME" );
		str = str..Friend:GetHistroyData( tonumber( curFriendGroup ), tonumber( curFriendIndex ), tonumber(i), "SENDER" );
		str = str.."#r";
		str = str..Friend:GetHistroyData( tonumber( curFriendGroup ), tonumber( curFriendIndex ), tonumber(i), "CONTEX" )
		
		if SystemSetup:IsClassic() == 1 then
			HistoryCorrespondence_Log:AddItem( str, i, "FFFFFFFF", 4 );
		else
			HistoryCorrespondence_Log:AddItem( str, i, "FFFFFFFF", 4 );
		end
		i = i - 1;
	end
	
end

function HistoryCorrespondence_OnPageDown()
	curHistroyPointer = curHistroyPointer - numberPerPage;
	if( curHistroyPointer < 0 ) then
		curHistroyPointer = 0;
	end
	HistoryCorrespondence_Update();
end

function HistoryCorrespondence_OnPageUp()
	curHistroyPointer = curHistroyPointer + numberPerPage;
	if( curHistroyPointer > maxHistroyNumber ) then
		curHistroyPointer = maxHistroyNumber;
	end
	HistoryCorrespondence_Update();
end

function HistoryCorrespondence_OnHelp()
	
end

function HistoryCorrespondence_OnClose()
	this:Hide();
end
function HistoryCorrespondence_ResetPos()
	HistoryCorrespondence_Frame:SetProperty("UnifiedXPosition", g_HistoryCorrespondence_Frame_UnifiedXPosition);
	HistoryCorrespondence_Frame:SetProperty("UnifiedYPosition", g_HistoryCorrespondence_Frame_UnifiedYPosition);

end
