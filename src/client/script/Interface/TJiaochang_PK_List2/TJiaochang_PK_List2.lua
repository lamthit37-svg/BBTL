--T服校场休息室人员列表
--!!!reloadscript =TJiaochang_PK_List22

local g_Timers = 0
local g_Seconds = 2

local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_List_PageCount = 20;
local g_Challenge_CurPage = 0;



--加载
function TJiaochang_PK_List2_PreLoad()
    this:RegisterEvent("SHOW_CHALLENGE_ROOM_FILTERMEMBER_LIST")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function TJiaochang_PK_List2_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= TJiaochang_PK_List2_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= TJiaochang_PK_List2_Frame:GetProperty("UnifiedYPosition");
end


function TJiaochang_PK_List2_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		TJiaochang_PK_List2_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TJiaochang_PK_List2_ResetPos()
	elseif( event == "SHOW_CHALLENGE_ROOM_FILTERMEMBER_LIST" ) then
		TJiaochang_PK_List2_ShowData()
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function TJiaochang_PK_List2_ClearItemList()
	TJiaochang_PK_List2_PkList:Clear()
	TJiaochang_PK_List2_UpButton:Disable()
	TJiaochang_PK_List2_DownButton:Disable()
	TJiaochang_PK_List2_PkListNull:Hide()
	TJiaochang_PK_List2_CountFenye : SetText("")
end

function TJiaochang_PK_List2_ShowData()
	TJiaochang_PK_List2_ClearItemList()
	local nCount = DataPool:Lua_GetChallengeRoomFilterMemberCount()
	if nCount <= 0 then
		g_Challenge_CurPage = 0
		TJiaochang_PK_List2_PkListNull:Show()
	else
		g_Challenge_CurPage = 0
		TJiaochang_PK_List2_FillListData()
	end

	this:Show()
end

function TJiaochang_PK_List2_NextPage()
	local nCount = DataPool:Lua_GetChallengeRoomFilterMemberCount()
	if g_Challenge_CurPage*g_List_PageCount + g_List_PageCount >= nCount then
		return
	end
	g_Challenge_CurPage = g_Challenge_CurPage + 1
	TJiaochang_PK_List2_FillListData()
end
function TJiaochang_PK_List2_PrePage()
	if g_Challenge_CurPage <= 0 then
		return
	end
	g_Challenge_CurPage = g_Challenge_CurPage - 1
	TJiaochang_PK_List2_FillListData()
end


function TJiaochang_PK_List2_FillListData()

	TJiaochang_PK_List2_ClearItemList()
	local startpos = g_Challenge_CurPage * g_List_PageCount
	local endpos = startpos + g_List_PageCount
	local nCount = DataPool:Lua_GetChallengeRoomFilterMemberCount()
	if startpos >= nCount then
		return
	end
	
	if g_Challenge_CurPage > 0 then
		TJiaochang_PK_List2_UpButton:Enable()
	else	
		TJiaochang_PK_List2_UpButton:Disable()
	end
	
	if endpos < nCount then
		TJiaochang_PK_List2_DownButton:Enable()
	else
		TJiaochang_PK_List2_DownButton:Disable()
	end
	
	local maxpages = math.ceil( tonumber(nCount/g_List_PageCount) )
	TJiaochang_PK_List2_CountFenye : SetText(tostring(g_Challenge_CurPage+1).."/"..tostring(maxpages))

	for i=startpos, endpos-1 do	
		local curpos = i - startpos
		if curpos < 0 or curpos >= g_List_PageCount then
			break
		end
		
		local ret,guid,objId,name,menpai,level,score,zoneWorldId = DataPool:Lua_GetChallengeRoomFilterMemberInfo(i)	
		if ret == 0 then
			break
		end
		
		local ItemBar = TJiaochang_PK_List2_PkList:AddChild("TJiaochang_PK_List2_PkAItem")
		
		local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
		if selfZoneWorldID ~= -1 and selfZoneWorldID ~= zoneWorldId then
			local serverName = DataPool:GetServerName( zoneWorldId )
			name = name.."@"..tostring(serverName)
		end
		if selfZoneWorldID ~= -1 and Lua_GetAnonymousSceneInfo() == 1 and selfZoneWorldID ~= zoneWorldId  then--在需要匿名的场景并且A玩家与观战者的worldid不同
			name = ScriptGlobal_Format("#{YCXX_20220712_01}"," ")
		end
		
		ItemBar:GetSubItem("TJiaochang_PK_List2_PkAItem_Name"):SetText(name)
		local mempaiName = GetMenpaiByID(menpai)
		ItemBar:GetSubItem("TJiaochang_PK_List2_PkAItemSchool"):SetText(mempaiName)
		ItemBar:GetSubItem("TJiaochang_PK_List2_PkAItemLevel"):SetText(level)
		ItemBar:GetSubItem("TJiaochang_PK_List2_PkAItemNum"):SetText(score)
		
		ItemBar:SetEvent("MouseRClick", string.format("TJiaochang_PK_List2_MemberClicked(%d)", i))
	end
end


function TJiaochang_PK_List2_MemberClicked(index)
	local ret,guid,objId,name,menpai,level,score,zoneWorldId = DataPool:Lua_GetChallengeRoomFilterMemberInfo(index)	
	if ret == 0 then
		return
	end
	
	DataPool:Lua_ShowChallengePopMemu(index)
end


function TJiaochang_PK_List2_CloseClicked()
    this:Hide()
end

function TJiaochang_PK_List2_RefreshButtonClicked()
	if not TJiaochang_PK_List2_PassTime(g_Seconds) then
		PushDebugMessage("#{TFXC_20220921_56}");
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnSeekRoomMember" )
		Set_XSCRIPT_ScriptID( 999847 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end


function TJiaochang_PK_List2_SeekButtonClicked()
	PushEvent("SHOW_CHALLENGE_ROOM_FILTER")
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function TJiaochang_PK_List2_ResetPos()
	TJiaochang_PK_List2_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	TJiaochang_PK_List2_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function TJiaochang_PK_List2_PassTime(iSeconds)
   local iCur = FindFriendDataPool:GetTickCount()
   if ( iCur - g_Timers < iSeconds * 1000) then
      return false;
   else
      g_Timers = iCur;
   	  return true;
   end
end
