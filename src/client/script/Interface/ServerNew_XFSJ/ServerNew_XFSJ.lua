
local g_unifiedposistion
local g_scene_res_ids ={
	[1027] = 1,   --scenedefine
}
local g_EnterCloseUI = {
	"ActionSkill",
}

local g_ServerNew_XFSJ_MaxCount = 6
local g_ServerNew_XFSJ_CurCount = 0

local g_ServerNew_XFSJ_Player = {}
local g_ServerNew_XFSJ_FakeObj = {}
local g_ServerNew_XFSJ_AllCtl = {}
local g_ServerNew_XFSJ_Model = {}
local g_ServerNew_XFSJ_ModelPopular = {}
local g_ServerNew_XFSJ_ModelFaceAuth = {}
local g_ServerNew_XFSJ_ModelChatBtn = {}
local g_ServerNew_XFSJ_ModelFriendBtn = {}
local g_ServerNew_XFSJ_Name = {}
local g_ServerNew_XFSJ_Level = {}
local g_ServerNew_XFSJ_Menpai = {}

local g_ServerNew_XFSJ_MenPaiName = {"少林", "明教", "丐帮", "武当", "峨嵋", "星宿", "天龙", "天山", "逍遥", "无门派", "慕容", "唐门", "鬼谷", "桃花岛", "绝情谷", "恶人谷"}  --menpai15 mptodo

local g_ServerNew_XFSJ_CDTime = 2
local g_ServerNew_XFSJ_LastTime = 0

function ServerNew_XFSJ_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("SCENE_TRANSED",false);
	this:RegisterEvent("XFSJ_OPENMAIN",true);
end

function ServerNew_XFSJ_OnLoad()	
	g_unifiedposistion = ServerNew_XFSJ_Frame:GetProperty("UnifiedPosition")
	
	for i = 1, g_ServerNew_XFSJ_MaxCount do
		g_ServerNew_XFSJ_AllCtl[i]	= "ServerNew_XFSJ_Player"..i.."_ObjClient"
		g_ServerNew_XFSJ_FakeObj[i]	= "ServerNew_XFSJFrame_FakeObject"..i
		g_ServerNew_XFSJ_Model[i]   = "ServerNew_XFSJ_Model_"..i
		--g_ServerNew_XFSJ_ModelPopular[i]= {}
		--g_ServerNew_XFSJ_ModelPopular[i][1] = "ServerNew_XFSJ_Model"..i.."_Icon_Level1"
		--g_ServerNew_XFSJ_ModelPopular[i][2] = "ServerNew_XFSJ_Model"..i.."_Icon_Level2"
		--g_ServerNew_XFSJ_ModelPopular[i][3] = "ServerNew_XFSJ_Model"..i.."_Icon_Level3"
		g_ServerNew_XFSJ_ModelFaceAuth[i] = {}
		g_ServerNew_XFSJ_ModelFaceAuth[i][0] = "ServerNew_XFSJ_Model"..i.."_Target_Unknown"
		g_ServerNew_XFSJ_ModelFaceAuth[i][1] = "ServerNew_XFSJ_Model"..i.."_Target_Man"
		g_ServerNew_XFSJ_ModelFaceAuth[i][2] = "ServerNew_XFSJ_Model"..i.."_Target_Woman" 
		g_ServerNew_XFSJ_ModelChatBtn[i] 	= "ServerNew_XFSJ_Model"..i.."_Chat_Btn"
		g_ServerNew_XFSJ_ModelFriendBtn[i] 	= "ServerNew_XFSJ_Model"..i.."_Friend_Btn"
		g_ServerNew_XFSJ_Name[i] 	= "ServerNew_XFSJ_PlayerInfo"..i.."_Name"
		g_ServerNew_XFSJ_Level[i]  = "ServerNew_XFSJ_PlayerInfo"..i.."_Level"
		g_ServerNew_XFSJ_Menpai[i]  = "ServerNew_XFSJ_PlayerInfo"..i.."_Menpai"		
	end
	
	for i = 1, g_ServerNew_XFSJ_MaxCount do
		g_ServerNew_XFSJ_Player[i] = {
			allCtl		= _G[g_ServerNew_XFSJ_AllCtl[i]],
			fakeObj		= _G[g_ServerNew_XFSJ_FakeObj[i]],
			modelCtl 	= _G[g_ServerNew_XFSJ_Model[i]],
			---modelPopular = { _G[g_ServerNew_XFSJ_ModelPopular[i][1]],_G[g_ServerNew_XFSJ_ModelPopular[i][2]],_G[g_ServerNew_XFSJ_ModelPopular[i][3]],},
			modelFaceAuth = {_G[g_ServerNew_XFSJ_ModelFaceAuth[i][0]],_G[g_ServerNew_XFSJ_ModelFaceAuth[i][1]],_G[g_ServerNew_XFSJ_ModelFaceAuth[i][2]],},
			modelChatBtn 	= _G[g_ServerNew_XFSJ_ModelChatBtn[i]],
			modelFriendBtn 	= _G[g_ServerNew_XFSJ_ModelFriendBtn[i]],
			modelCtl 	= _G[g_ServerNew_XFSJ_Model[i]],
			name  	= _G[g_ServerNew_XFSJ_Name[i]],
			nameStr  	= "",
			level   = _G[g_ServerNew_XFSJ_Level[i]],
			menpai  = _G[g_ServerNew_XFSJ_Menpai[i]],
			isValid = 0,
			guid = -1,
			}
			
		g_ServerNew_XFSJ_Player[i].fakeObj:DetachWindowEx()


	end
	
end

function ServerNew_XFSJ_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 99971102 then
		local opType =  Get_XParam_INT( 0 )
		if opType == 1 then
			g_ServerNew_XFSJ_LastTime = 0
			ServerNew_XFSJ_UpdateData()
			--this:Show()
		else
			this:Hide()
		end
	elseif event == "XFSJ_OPENMAIN" then
		local opType = tonumber(arg0)
		---PushDebugMessage("XFSJ_OPENMAIN "..opType)
		ServerNew_XFSJ_UpdateData()
		if opType == 0 then		
			g_ServerNew_XFSJ_LastTime = 0
			this:Show()
		end
	elseif event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		ServerNew_XFSJ_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ServerNew_XFSJ_ResetPos()
	elseif event == "SCENE_TRANSED" then
		if not g_scene_res_ids[GetSceneID()] then
			this:Hide()
		end
	end
end


---!!!reloadscript =ServerNew_XFSJ
function ServerNew_XFSJ_ResetPos()
	ServerNew_XFSJ_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function ServerNew_XFSJ_UpdateData()
	
	--清除数据
	for i = 1, g_ServerNew_XFSJ_MaxCount do
		g_ServerNew_XFSJ_Player[i].fakeObj:DetachWindowEx()
		g_ServerNew_XFSJ_Player[i].isValid = 0
	end
	g_ServerNew_XFSJ_CurCount = 0 
	
	
	for i = 1, g_ServerNew_XFSJ_MaxCount do
		g_ServerNew_XFSJ_Player[i].allCtl:Hide()
	end

	--获取数量
	local validCount = DataPool:LuaFnGetXFSJHumanInfoValidCount()
	
	if validCount <= 0 then
		--DataPool:LuaFnAskNewXFSJHumanInfo(0)
		return
	end
	
	local infotbl = DataPool:LuaFnGetXFSJHumanInfo()
	if type(infotbl) ~= "table" then
		return
	end
	
	g_ServerNew_XFSJ_CurCount = table.getn(infotbl)
	
	if g_ServerNew_XFSJ_CurCount ~= validCount then
		g_ServerNew_XFSJ_CurCount = validCount
	end 
	
	for index = 1, g_ServerNew_XFSJ_MaxCount do
		if index <= g_ServerNew_XFSJ_CurCount then
			g_ServerNew_XFSJ_Player[index].fakeObj:DetachWindowEx()
			g_ServerNew_XFSJ_Player[index].fakeObj:AttachWindowEx( "XFSJFakeObj_PlayerNew"..(index-1) )
		else
			g_ServerNew_XFSJ_Player[index].fakeObj:DetachWindowEx()
		end
	end
	
	DataPool:LuaFnUpdateXFSJPlayerData()

	for i = 1, validCount do
		ServerNew_XFSJ_UpdateOne(infotbl, i)
	end

end

function ServerNew_XFSJ_UpdateOne(infotbl,index)
	
	g_ServerNew_XFSJ_Player[index].isValid = 1
	g_ServerNew_XFSJ_Player[index].allCtl:Show()

	local myPopular = infotbl[index].popular
	local myauthId = infotbl[index].authId
	local isFriend = infotbl[index].isFriend
	
	for i = 1, 3 do
		---if i == myPopular then
		---	g_ServerNew_XFSJ_Player[index].modelPopular[i]:Show()
		---else
		---	g_ServerNew_XFSJ_Player[index].modelPopular[i]:Hide()
		---end
		
		if i-1 == myauthId then
			g_ServerNew_XFSJ_Player[index].modelFaceAuth[i]:Show()
		else
			g_ServerNew_XFSJ_Player[index].modelFaceAuth[i]:Hide()
		end
	end
	
	if isFriend == 1 then
		g_ServerNew_XFSJ_Player[index].modelChatBtn:Show()
		g_ServerNew_XFSJ_Player[index].modelFriendBtn:Hide()
	else
		g_ServerNew_XFSJ_Player[index].modelFriendBtn:Show()
		g_ServerNew_XFSJ_Player[index].modelChatBtn:Hide()
	end
	
	g_ServerNew_XFSJ_Player[index].name:SetText(ScriptGlobal_Format("#{XFSJ_250527_22}",infotbl[index].name))
	g_ServerNew_XFSJ_Player[index].level:SetText(ScriptGlobal_Format("#{XFSJ_250527_24}",infotbl[index].level))
	if g_ServerNew_XFSJ_MenPaiName[infotbl[index].menpaiId+1] ~= nil then
		g_ServerNew_XFSJ_Player[index].menpai:SetText(ScriptGlobal_Format("#{XFSJ_250527_23}",g_ServerNew_XFSJ_MenPaiName[infotbl[index].menpaiId+1]))
	end
	
	g_ServerNew_XFSJ_Player[index].guid = infotbl[index].guid
	g_ServerNew_XFSJ_Player[index].nameStr = infotbl[index].name
	
end

function ServerNew_XFSJ_CloseWindow()
	
	this:Hide()
end

function ServerNew_XFSJ_OnHidden()
	
	--清除数据
	for i = 1, g_ServerNew_XFSJ_MaxCount do
		g_ServerNew_XFSJ_Player[i].fakeObj:DetachWindowEx()
		g_ServerNew_XFSJ_Player[i].isValid = 0
	end
	g_ServerNew_XFSJ_CurCount = 0 
	g_ServerNew_XFSJ_LastTime = 0

end

function ServerNew_XFSJ_Model_Chat_Btn_Clicked(index)
	
	if g_ServerNew_XFSJ_Player[index].isValid ~= 1 then
		return
	end
	
	local nameStr = g_ServerNew_XFSJ_Player[index].nameStr
	local guid = g_ServerNew_XFSJ_Player[index].guid

	if nameStr ~= nil then
		local nGroup , nIndex = DataPool:GetFriendByName(nameStr)
		if nGroup ~= -1 and nIndex ~= -1 then
			
			local level = Player:GetData("LEVEL")
			if level < 31 then
				PushDebugMessage("#{XFSJ_250527_93}") -- 等级不足31级时，单向好友无法好友聊天。
			end
			
			DataPool:Open1On1Chat(nGroup , nIndex)
			
		else
			PushDebugMessage("对方不是你的好友不能发送消息");
			g_ServerNew_XFSJ_Player[index].modelFriendBtn:Show()
			g_ServerNew_XFSJ_Player[index].modelChatBtn:Hide()
		end
	else
		PushDebugMessage("对方不是你的好友不能发送消息");
		g_ServerNew_XFSJ_Player[index].modelFriendBtn:Show()
		g_ServerNew_XFSJ_Player[index].modelChatBtn:Hide()
	end	
	

end


function ServerNew_XFSJ_Model_Friend_Btn_Clicked(index)
	
	
	if g_ServerNew_XFSJ_Player[index].isValid ~= 1 then
		return
	end
	
	--加好友
	local guid = g_ServerNew_XFSJ_Player[index].guid
	
	if guid ~= "" then
		if guid ~= Player:GetGUID() then
			local nameStr = g_ServerNew_XFSJ_Player[index].nameStr
			if( nameStr == nil or nameStr == "") then
				return
			end
			local zwid = SystemSetup:GetCharactZoneWorldId(nameStr)
			---PushDebugMessage("ServerNew_XFSJ_Model_Friend_Btn_Clicked "..nameStr.."  "..zwid)
			
			DataPool:AddFriendAndGrouping(nameStr, zwid)

			g_ServerNew_XFSJ_Player[index].modelChatBtn:Show()
			g_ServerNew_XFSJ_Player[index].modelFriendBtn:Hide()

		else
			---PushDebugMessage("#{TDGZ_100809_83}")
		end
	end
	
end

function ServerNew_XFSJ_Refresh_Clicked()
	
	--按钮CD
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ServerNew_XFSJ_LastTime < g_ServerNew_XFSJ_CDTime * 1000) then
		PushDebugMessage("#{XFSJ_250527_91}"); --当前操作过快，请稍后点击
		return
	end
	
	g_ServerNew_XFSJ_LastTime = curTime;
	--去请求（视同刷新换一批）
	DataPool:LuaFnAskNewXFSJHumanInfo(1)

end