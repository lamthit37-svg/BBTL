-- 界面的默认位置
local g_ChoosePresentFriend_UnifiedXPosition
local g_ChoosePresentFriend_UnifiedYPosition

local g_Current_Clicked = -1;
local g_Friend_GroupID = -1
local g_Friend_Index = -1
local g_DefaultTitle = "#{ZSGN_101129_43}"
local g_UseForWhat = ""
--===============================================
-- OnLoad()
--===============================================
function XuanPresent_ChooseFriend_PreLoad()

	this:RegisterEvent("UPDATE_FRIEND");
	this:RegisterEvent("OPEN_XUANPRESENT_CHOOSEFRIEND");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);

end

function XuanPresent_ChooseFriend_OnLoad()

	-- 保存图鉴书界面的默认相对位置
	g_ChoosePresentFriend_UnifiedXPosition	= XuanPresent_ChooseFriend_Frame:GetProperty("UnifiedXPosition");
	g_ChoosePresentFriend_UnifiedYPosition	= XuanPresent_ChooseFriend_Frame:GetProperty("UnifiedYPosition");

	g_Current_Clicked = -1
	g_Friend_GroupID = -1
	g_Friend_Index = -1

	XuanPresent_ChooseFriend_OK_Button:Disable();

end

--===============================================
-- OnEvent()
--===============================================
function XuanPresent_ChooseFriend_OnEvent( event )

	if( event == "OPEN_XUANPRESENT_CHOOSEFRIEND" ) then
			--如果xuanshop界面已经显示
			if (IsWindowShow("XuanShop")) then
				CloseWindow("XuanShop",true)
			end
			g_UseForWhat = arg0
			if g_UseForWhat == "XuanGift" then
				XuanPresent_ChooseFriend_DragTitle:SetText(g_DefaultTitle)
				XuanPresent_ChooseFriend_Text:SetText("#{ZSGN_101129_44}")
			elseif g_UseForWhat == "YuanBaoGift" then
				XuanPresent_ChooseFriend_DragTitle:SetText("#{FFSDGZ_120615_16}")
				XuanPresent_ChooseFriend_Frame:SetProperty("AbsoluteXPosition", tonumber(arg1))
				XuanPresent_ChooseFriend_Frame:SetProperty("AbsoluteYPosition", tonumber(arg2))
				XuanPresent_ChooseFriend_Text:SetText("#{FFSDGZ_120615_120}")
			end
			g_Current_Clicked = -1
			g_Friend_GroupID = -1
			g_Friend_Index = -1
			XuanPresent_ChooseFriend_OK_Button:Disable();
			XuanPresent_ChooseFriend_Update();
			this:Show()
	elseif( event == "UPDATE_FRIEND" ) then
		g_Current_Clicked = XuanPresent_ChooseFriend_FriendList:GetCurrentFirstItem();
		XuanPresent_ChooseFriend_Update();
	elseif( event == "ADJEST_UI_POS" ) then
		XuanPresent_ChooseFriend_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		XuanPresent_ChooseFriend_ResetPos()
	end
end

function XuanPresent_ChooseFriend_Update()
	XuanPresent_ChooseFriend_FriendList:ClearListBoxEx();
	--一共7组 ，临时好友单独处理
	for i = 1 , 4 do
		local j = i
		local iStart = j*10000;
		local friendnumber = DataPool:GetFriendNumber( tonumber( j ) );
		local index=0;
		while index < friendnumber  do
			XuanPresent_ChooseFriend_AddFriendItem(j , index)
			index = index + 1;
		end
	end

	if g_Current_Clicked ~= -1 then
		XuanPresent_ChooseFriend_FriendList:SetCurrentFirstItem(g_Current_Clicked);
		g_Current_Clicked = -1
	end

end


function XuanPresent_ChooseFriend_AddFriendItem( nChannel, nIndex )
	local name = DataPool:GetFriend( nChannel, nIndex, "NAME" );
	if 1 == SystemSetup:IsClassic() then
		XuanPresent_ChooseFriend_FriendList:AddItem( name , nChannel*10000 + nIndex + 1, "FFFFFFFF", 4 );
	else
		XuanPresent_ChooseFriend_FriendList:AddItem( "#W"..name , nChannel*10000 + nIndex + 1, "FFFFFFFF", 4 );
	end
end

function XuanPresent_ChooseFriend_SelectChanged()
	local nSelIndex = XuanPresent_ChooseFriend_FriendList:GetFirstSelectItem();
	g_Friend_Index = math.mod( nSelIndex, 10000 ) - 1
	g_Friend_GroupID = math.floor( nSelIndex / 10000 );
	XuanPresent_ChooseFriend_OK_Button:Enable();
end

function XuanPresent_ChooseFriend_OK()

	if tonumber(g_Friend_GroupID) == -1 or tonumber(g_Friend_Index) == -1 then
		return
	end
	local friendguid = DataPool:GetFriend( g_Friend_GroupID, g_Friend_Index, "ID"  )
	local friendRelationType = DataPool:GetFriend( g_Friend_GroupID, g_Friend_Index, "RELATION_TYPE"  )
	local friendName = DataPool:GetFriend( g_Friend_GroupID, g_Friend_Index, "NAME"  )
	if g_UseForWhat == "XuanGift" then
		--如果xuanshop界面已经显示
		if (IsWindowShow("XuanShop")) then
			CloseWindow("XuanShop",true)
		end

		PushEvent("OPEN_IMDRESSPRESENT_YUANBAOSHOP", friendguid)
		XuanPresent_ChooseFriend_Hide();
	elseif g_UseForWhat == "YuanBaoGift" then
		PushEvent("OPEN_GIVEGIFT_COMPLETE_CHOOSE", friendguid, friendName)
		XuanPresent_ChooseFriend_Hide();
	end


end

function XuanPresent_ChooseFriend_ResetPos()
	XuanPresent_ChooseFriend_Frame:SetProperty("UnifiedXPosition", g_ChoosePresentFriend_UnifiedXPosition);
	XuanPresent_ChooseFriend_Frame:SetProperty("UnifiedYPosition", g_ChoosePresentFriend_UnifiedYPosition);
end

function XuanPresent_ChooseFriend_Hide()
	this:Hide();
end
