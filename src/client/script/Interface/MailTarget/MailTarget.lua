--******************************************************************************
--
-- 收件人选择界面 by 陈永帅
--
--******************************************************************************
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition
local g_IsTeamOutLine = {}
local g_Current_Clicked = -1
local g_imgStatus = {}
local objCared = -1
local MAX_OBJ_DISTANCE = 3.0
--******************************************************************************

-- 处理原始坐标
local g_UnifiedSize = {}

-- 邮件物品
local g_MailEdit_item = {}

function MailTarget_PreLoad()

	-- 注册事件
	this:RegisterEvent("UI_COMMAND")

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	-- 新邮件
	this:RegisterEvent("OPEN_SEND_NEW_MAIL")
	
	-- 关闭界面
	this:RegisterEvent("CLOSE_MAIL_TARGET")
		
	-- 玩家关闭窗口
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
		
	-- 好友列表更新
	this:RegisterEvent("UPDATE_FRIEND")
	
end

function MailTarget_OnLoad()
	
	MailTarget_Page2:Hide()
	MailTarget_Page3:Hide()
	MailTarget_Page4:Hide()
	MailTarget_Page5:Hide()
	g_Frame_UnifiedXPosition	= MailTarget_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= MailTarget_Frame:GetProperty("UnifiedYPosition")
		
	g_IsTeamOutLine = {0,0,0,0}
	g_imgStatus = 
	{
			[0] = { [0] = "#-27" ,[1] = "#-29" ,[2] = "#-30"} ,
			[1] = { [0] = "#-23" ,[1] = "#-25" ,[2] = "#-26"} ,
	}
	g_Current_Clicked = -1
	
end

function MailTarget_OnEvent( event )
	
	if( event == "OPEN_SEND_NEW_MAIL" and tonumber( arg0 ) == 20110603)  then
		if not this:IsVisible() then
			this:Show()
			MailTarget_Update()
		else
			this:Hide()
		end
	elseif (event == "UPDATE_FRIEND") then
		MailTarget_Update()
	elseif ( event == "UI_COMMAND" and  tonumber(arg0) == 20110519 or tonumber(arg0) == 20110518  ) then
		objCared = Get_XParam_INT(0)
		objCared = MailSystem:GetNPCServerID(objCared)
		this:CareObject(objCared, 1, "MailTarget") --关心界面
	elseif( event == "CLOSE_MAIL_TARGET") then
		MailTarget_Close()
	elseif( event == "ADJEST_UI_POS" ) then
		MailTarget_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		MailTarget_ResetPos()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			MailTarget_Close()
		end
	end
	
end

--================================================
-- 默认相对位置
--================================================
function MailTarget_ResetPos()
	MailTarget_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition)
	MailTarget_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition)
end

--================================================
-- 添加好友
--================================================
function MailTarget_AddFriendItem( nChannel, nIndex )
	local name = DataPool:GetFriend( nChannel, nIndex, "NAME" )
	local relationtype = DataPool:GetFriend( nChannel, nIndex, "RELATION_TYPE" )
	local Sex = DataPool:GetFriend( nChannel, nIndex, "SEX" )
	local IMst = DataPool:GetFriend( nChannel, nIndex, "IM_STATUS" )
	local online = DataPool:GetFriend( nChannel, nIndex, "ONLINE" )
	-- 名字
	local palyercolour = "#cC4B299"
	local playerIcon = "    "
	if( online ) then
		if IMst >= 0 and IMst <=2 and Sex >=0 and Sex <= 1 then
			playerIcon = g_imgStatus[Sex][IMst]
			palyercolour ="#cFFFFFF"
		end
	end
	
	local listName = playerIcon..palyercolour..name
	MailTarget_List:AddItem( listName, nChannel*10000 + nIndex + 1 , "FFFFFFFF", 4 );
end

--================================================
-- 更新发邮件的好友
--================================================
function MailTarget_Update()
	MailTarget_List:ClearListBoxEx();
	for j = 1 , 4 do
		local lineName = DataPool:GetGroupingNameByIndex(j-1)
		local strOutlineName = ""
		if g_IsTeamOutLine[j] == 1 then
			strOutlineName = "#gFE7E82- " .. lineName
		else
			strOutlineName = "#gFE7E82+ " .. lineName
		end
		if strOutlineName == "" then
			return
		end
		
		local iStart = j*10000;
		local friendnumber = DataPool:GetFriendNumber( tonumber( j ) )
		if friendnumber < 1 then
			strOutlineName = "#gFE7E82- " .. lineName
		end
		
		MailTarget_List:AddItem(strOutlineName, iStart )
			
		if( 1 == g_IsTeamOutLine[ j ] ) then
			local index=0;
			while index < friendnumber  do
				MailTarget_AddFriendItem(j,index)
			  index = index + 1
			end
		end
	
  end
  
  if g_Current_Clicked ~= -1 then
		MailTarget_List:SetCurrentFirstItem(g_Current_Clicked);
		g_Current_Clicked = -1
	end
end

--================================================
-- 列表元素
--================================================
function MailTarget_List_SelectChanged()
		local nSelIndex = MailTarget_List:GetFirstSelectItem();
		local iMod = math.mod( nSelIndex, 10000 )
		local iFloor = math.floor( nSelIndex / 10000 );
		if( 0 == iMod ) then
			if( 0 == g_IsTeamOutLine[ iFloor ] ) then
				g_IsTeamOutLine[ iFloor ] = 1
			else
				g_IsTeamOutLine[ iFloor ] = 0
			end
			g_Current_Clicked = MailTarget_List:GetCurrentFirstItem()
			MailTarget_Update()
		end
end

--================================================
-- 双击选择好友
--================================================
function MailTarget_FriendSelect()
		local index = MailTarget_List:GetFirstSelectItem();
		if index == -1 then
			return
		end
		local iMod = math.mod( index, 10000 )
		local iFloor = math.floor( index / 10000 );
		local name = DataPool:GetFriend( iFloor, iMod-1, "NAME" )
		local guid =  DataPool:GetFriend( iFloor, iMod-1, "ID" )
		if name == nil or guid == "" or name =="" then
			return
		end
		DataPool:UpdateFriendInfo(name)
		MailSystem:WriteUserName(name)
		MailSystem:WriteUserGUID(guid)
		PushEvent("UPDATE_MAILINAME")
end

--================================================
-- 确定选择好友
--================================================
function MailTarget_FriendSelect_OK()
	MailTarget_FriendSelect()
  MailTarget_Close()
end

--================================================
-- 关闭选择好友
--================================================
function MailTarget_Close()
	this:CareObject(objCared, 0, "MailReply")
	objCared = -1
	this:Hide()
end

--================================================
-- 清空选择好友
--================================================
function MailTarget_ClickDelete()
	MailSystem:WriteUserName("")
	MailSystem:WriteUserGUID("")
	PushEvent("UPDATE_MAILINAME")
end
