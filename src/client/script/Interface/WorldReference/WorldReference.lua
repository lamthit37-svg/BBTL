
local g_WorldReference_Frame_UnifiedXPosition;
local g_WorldReference_Frame_UnifiedYPosition;

function WorldReference_PreLoad()

    this:RegisterEvent("OPEN_WORLDREFERENCE",true)
    this:RegisterEvent("OPEN_WORLDREFERENCE_TIME",false)
    this:RegisterEvent("OPEN_PKDESC",true)
    this:RegisterEvent("OPEN_ACCOUNT_SAFE",true)
    this:RegisterEvent("WR_SHOWBOSSINFO",true)
    this:RegisterEvent("OPEN_MONSTER_TABLE",true)

    this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ZHENFA_DESC",true)
	this:RegisterEvent("OPEN_SHIDEINFO",true)
	this:RegisterEvent("UI_COMMAND",true)
end

function WorldReference_OnLoad()

g_WorldReference_Frame_UnifiedXPosition	= WorldReference_Frame:GetProperty("UnifiedXPosition");
g_WorldReference_Frame_UnifiedYPosition	= WorldReference_Frame:GetProperty("UnifiedYPosition");

end

function WorldReference_OpenPKDesc()
    WorldReferenceGreeting_Desc:ClearAllElement()
    --WorldReference_PageHeader:SetText("#{INTERFACE_XML_39}")
    WorldReference_PageHeader:SetText("#{PK_HELP_03}")
    
  local isCompatPKServer = Player:GetData("IsPKServer_JD")
  if isCompatPKServer == nil or isCompatPKServer == 0 then
		--根据服务器配置是否在K服保留"帮会同盟",显示不同的PK模式说明
		if KVKInterface:IsEnableGuildLeagueInKServer() <= 0 then
			WorldReferenceGreeting_Desc:AddTextElement( "#{PK_HELP_02}")
		else
			WorldReferenceGreeting_Desc:AddTextElement( "#{PK_HELP_001}")
		end
  else
   	WorldReferenceGreeting_Desc:AddTextElement( "#{PKPK_20251021_1}")
	end
    this:Show();
end

function WorldReference_OpenZhenfaDesc()
	 WorldReferenceGreeting_Desc:ClearAllElement()
	 WorldReference_PageHeader:SetText("")
	if Lua_IsChangeBroship() > 0 then
	 	WorldReferenceGreeting_Desc:AddTextElement( "#{XDJB_0401_06}")
	elseif Player:GetData("Is2606S") == 1 then
		WorldReferenceGreeting_Desc:AddTextElement( "#{QXF_260623_32}")
	else
		WorldReferenceGreeting_Desc:AddTextElement( "#{JBGXW_150526_219}")
	end	
	 
	 this:Show();
end

function WorldReference_ShowYingJieHelp()
	 WorldReferenceGreeting_Desc:ClearAllElement()
		WorldReference_PageHeader:SetText("#{BZYJ_151123_66}")
		WorldReferenceGreeting_Desc:AddTextElement( "#{BZYJ_151123_67}")
	 this:Show();
end

function WorldReference_OpenShideDesc(infotype)
	 WorldReferenceGreeting_Desc:ClearAllElement()
	 if infotype == "1" then
		WorldReference_PageHeader:SetText("#{STGZ_150514_477}")
		WorldReferenceGreeting_Desc:AddTextElement( "#{STGZ_150514_478}")
	 elseif infotype == "2" then
		WorldReference_PageHeader:SetText("#{STGZ_150514_480}")
		WorldReferenceGreeting_Desc:AddTextElement( "#{STGZ_150514_481}")
	 end	 
	 this:Show();
end

--=========================================================
-- 事件处理
--=========================================================
function WorldReference_OnEvent(event)
    WorldReference_PageHeader:SetText("#{INTERFACE_XML_39}")

	if(event == "OPEN_WORLDREFERENCE") then
      WorldReference_DispatchMainPage()
	end

	if(event == "OPEN_WORLDREFERENCE_TIME") then
	  local Date = tostring( arg0 )

	  WorldReference_DispatchServerTime( Date )
	end

	if(event == "OPEN_PKDESC") then
        WorldReference_OpenPKDesc()
	end
	
	if(event == "ZHENFA_DESC") then
		WorldReference_OpenZhenfaDesc()
	end
	
	if(event == "OPEN_SHIDEINFO") then
		WorldReference_OpenShideDesc(arg0)
	end

	if( event == "OPEN_ACCOUNT_SAFE") then
		WorldReference_OpenAccountSafeDesc();
	end

	if(event == "WR_SHOWBOSSINFO") then
        WorldReference_OpenBossInfo( arg0 )
	end

	if(event == "OPEN_MONSTER_TABLE") then
     WorldReferenceGreeting_Desc:ClearAllElement()
     WorldReference_DispatchMonsterTable()
     this:Show();
	end

	if( event == "ADJEST_UI_POS" ) then
		WorldReference_ResetPos()
	end

	if( event == "VIEW_RESOLUTION_CHANGED" ) then
		WorldReference_ResetPos()
	end
	
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 2015112403 then--百战英杰铸精通
			WorldReference_ShowYingJieHelp()
		end
	end

end

--=========================================================
-- 关闭相应
--=========================================================
function WorldReference_Close()
end

--=========================================================
-- 显示任务列表
--=========================================================
function WorldReference_EventListUpdate()
end

--=========================================================
-- 显示任务信息
--=========================================================
function WorldReference_WorldReferenceInfoUpdate()
end

--=========================================================
--Continue任务的对话框
--=========================================================
function WorldReference_MissionContinueUpdate(bDone)
end

--=========================================================
--收取奖励物品的对话框
--=========================================================
function WorldReference_MissionRewardUpdate()
end


function WorldReference_OpenAccountSafeDesc()
		WorldReferenceGreeting_Desc:ClearAllElement()
    --WorldReference_PageHeader:SetText("#{JIANGHU_ACCOUNT_SAFE_1}")
		WorldReference_DispatchAccountSafeTable(8);
    this:Show();
end


--=========================================================
--显示首页
--=========================================================
function WorldReference_DispatchMainPage()

	WorldReferenceGreeting_Desc:ClearAllElement();
	local level = Player:GetData("LEVEL")
	WRCollectVisiableContex( 0, level )

	local NumVisiable = tonumber( WRGetVisiableContexCount() )

	WorldReferenceGreeting_Desc:AddTextElement( "　　记得每到一个新的级别就打开我来看看，我会告诉你很多江湖当中的事情。")

	WorldReferenceGreeting_Desc:AddOptionElement( "#{TLTJ_110114_05}".. "&0,-2$0" );

	local nVisableCount = ExcitPoint:GetVisableCount();
	if nVisableCount > 0 then  --最少要有一个可以显示的才增加.
		--增加一个武林图鉴， 为0,-1   $0这里的0表示IMAGE TYPE？CEGUI源码中
		WorldReferenceGreeting_Desc:AddOptionElement( "#{XFD_XML_02}" .. "&0,-1$0" );
	end

	for i=0, NumVisiable-1 do
	    local VisiableID = WRGetVisiableContexID( i )
	    if( -1 ~= VisiableID ) then
	        --local strContex = WRGetVisiableContex( 0, VisiableID )
	        local strContex = WRGetTitle( 0, VisiableID )
	        local strTemp = strContex.."&0,"..(VisiableID+1).."$0"
	        WorldReferenceGreeting_Desc:AddOptionElement( strTemp );
	    end

	end

--	WorldReference_Frame_Debug:SetText("江湖指南")



	this:Show();
end

function WorldReference_DispatchTable( TableID )
    WorldReferenceGreeting_Desc:ClearAllElement();

	local level = Player:GetData("LEVEL")
	WRCollectVisiableContex( TableID, level )   --任务表内容
	local NumVisiable = tonumber( WRGetVisiableContexCount() )
	if(NumVisiable>0 and TableID == 1)then
		local strTemp = "查看可接任务".."&"..TableID..","..(-1).."$0"
	        WorldReferenceGreeting_Desc:AddOptionElement( strTemp );
	end
	for i=0, NumVisiable-1 do
	    local VisiableID = WRGetVisiableContexID( i )
	    if( -1 ~= VisiableID ) then
	        local strTitle = WRGetTitle( TableID, VisiableID )


	        local strTemp = strTitle.."&"..TableID..","..(VisiableID).."$0"
	        WorldReferenceGreeting_Desc:AddOptionElement( strTemp );
	    end

	end

    local strBack = "回首页".."&0,0".."$0"
	WorldReferenceGreeting_Desc:AddOptionElement( strBack );
end

--=========================================================
--显示任务页
--=========================================================
function WorldReference_DispatchMissionTable()
    WorldReference_DispatchTable( 1 )
end

--=========================================================
--显示怪物页
--=========================================================
function WorldReference_DispatchMonsterTable()
    WorldReference_DispatchTable( 2 )
end

--=========================================================
--显示"其他"页
--=========================================================
function WorldReference_DispatchOtherTable()
    WorldReference_DispatchTable( 5 )
end

--=========================================================
--显示BOSS首页
--=========================================================
function WorldReference_DispatchBossTable()

	WorldReferenceGreeting_Desc:ClearAllElement();

	local menuLevel = -1
	local parentId = -1

	local level = Player:GetData("LEVEL")
	WRCollectVisiableContex( 3, level )
	local NumVisiable = tonumber( WRGetVisiableContexCount() )

	for i=0, NumVisiable-1 do
		local VisiableID = WRGetVisiableContexID( i )
		if -1 ~= VisiableID then
			menuLevel,parentId = WRBOSSTblGetContexInfo( VisiableID )
			if -1 == parentId then
				local strTitle = WRGetTitle( 3, VisiableID )
				local strTemp = strTitle.."&"..(3)..","..VisiableID.."$0"
				WorldReferenceGreeting_Desc:AddOptionElement( strTemp )
			end
		end
	end

	local strBack = "回首页".."&0,0".."$0"
	WorldReferenceGreeting_Desc:AddOptionElement( strBack )

end

--=========================================================
--显示"帐号安全"页
--=========================================================
function WorldReference_DispatchAccountSafeTable( TableID )
 WorldReferenceGreeting_Desc:ClearAllElement();

	WRCollectVisiableContexEx( TableID, -1, 1 )   --帐号安全表内容
	WorldReferenceGreeting_Desc:AddTextElement( "    下列内容介绍了账号安全的信息，包括如何设置密码，如何使用游戏内保护功能等。详细信息请点击查看目录中的内容。")	--帐号  to  账号
	local NumVisiable = tonumber( WRGetVisiableContexCount() )
	for i=0, NumVisiable-1 do
	    local VisiableID = WRGetVisiableContexID( i )
	    if( -1 ~= VisiableID ) then
	        local strTitle = WRGetVisiableContex( TableID, VisiableID )


	        local strTemp = strTitle.."&"..TableID..","..(VisiableID).."$0"
	        WorldReferenceGreeting_Desc:AddOptionElement( strTemp );
	    end

	end

  local strBack = "回首页".."&0,0".."$0"
	WorldReferenceGreeting_Desc:AddOptionElement( strBack );
end

--分派帐号安全 子项的函数
function WorldReference_DispatchContexAccount(TableID, ContexID)
  	WorldReferenceGreeting_Desc:ClearAllElement()
  	if( ContexID < 0) then
  		WRCollectVisiableContexEx( TableID, -ContexID, 0 )		--上一步
  	else
  		WRCollectVisiableContexEx( TableID, ContexID, 1 )   --帐号安全表内容
  	end
		local NumVisiable = tonumber( WRGetVisiableContexCount() )
		local VisiableID =-1;
		for i=0, NumVisiable-1 do
	     VisiableID = WRGetVisiableContexID( i )
	     if( -1 ~= VisiableID ) then
        local strTitle = WRGetVisiableContex( TableID, VisiableID )

        if WRGetContexType( TableID, VisiableID ) == 3 then
        	WorldReferenceGreeting_Desc:AddTextElement( strTitle );
        else
          local strTemp = strTitle.."&"..TableID..","..(VisiableID).."$0"
        	WorldReferenceGreeting_Desc:AddOptionElement( strTemp );
        end
	    end
		end
		local strBack;
		--VisiableID = WRGetVisiableContexID( 0 )
    if VisiableID ~= -1  and WRGetContexType( TableID, VisiableID ) > 1 then
    	strBack = "上一步".."&"..TableID..","..(-VisiableID).."$0"
    else
    	strBack = "回首页".."&0,0".."$0"
    end
		WorldReferenceGreeting_Desc:AddOptionElement( strBack );
end

--=========================================================
--处理点击BOSS表中某一项的事件....
--=========================================================
function WorldReference_BOSSOptionClicked( Data2 )

	WorldReferenceGreeting_Desc:ClearAllElement()

	local menuLevel = -1
	local parentId = -1

	--如果点的是返回上级菜单的选项....则相当于点击-Date2菜单....
	if Data2 < 0 then
		Data2 = -Data2
	end

	--获取所选条目的信息....
	menuLevel,parentId = WRBOSSTblGetContexInfo( Data2 )

	--如果选的不是菜单而是文字描述项则显示内容....
	if menuLevel == -1 then

		--加入内容文字....
    local strContex = WRGetVisiableContex( 3, Data2 )
    WorldReferenceGreeting_Desc:AddTextElement( strContex )

	else --如果选的是菜单则显示其子项的Title....

		--收集父项ID为Data2的可项目....
		WRBOSSTblCollectVisiableContex( Data2 )

		--加入项目到界面中....
		local NumVisiable = WRGetVisiableContexCount()
		for i=0, NumVisiable-1 do
	    local VisiableID = WRGetVisiableContexID( i )
	    if -1 ~= VisiableID then
				local strTitle = WRGetTitle( 3, VisiableID )
				local strTemp = strTitle.."&"..(3)..","..VisiableID.."$0"
				WorldReferenceGreeting_Desc:AddOptionElement( strTemp )
	    end
		end

	end

	--加入返回上层的选项....
	local strBack
	if -1 == parentId then
			strBack = "上一步".."&0,"..(3).."$0"
	else
		strBack = "上一步".."&3,"..-parentId.."$0"
	end
	WorldReferenceGreeting_Desc:AddOptionElement( strBack )

end

--=========================================================
--显示时间
--=========================================================
function WorldReference_DispatchServerTime( strDate )
    WorldReferenceGreeting_Desc:ClearAllElement()

    WorldReferenceGreeting_Desc:AddTextElement( strDate )

    local strBack = "回首页".."&0,"..(0).."$0"
	WorldReferenceGreeting_Desc:AddOptionElement( strBack );
end

function WorldReference_DispatchContex( TableID, ContexIndex )
    if( TableID == 1 and ContexIndex == -1) then   --江湖指南
            	--打开可接任务列表
		ToggleMissionOutLine();
		return
    end
    WorldReferenceGreeting_Desc:ClearAllElement()
    local strContex = WRGetVisiableContex( TableID, ContexIndex )
    WorldReferenceGreeting_Desc:AddTextElement( strContex )

    local strBack = "上一步".."&0,"..TableID.."$0"
	WorldReferenceGreeting_Desc:AddOptionElement( strBack );

end

--=========================================================
-- 选择一个任务
--=========================================================
function WorldReferenceOption_Clicked()

	--文字的格式是
	--QuestGreeting_option_03&211207,0
	pos1,pos2 = string.find(arg0,"#");
	pos3,pos4 = string.find(arg0,",");

	local strOptionID = -1;
	local strOptionExtra1 = string.sub(arg0, pos2+1,pos3-1 );
	local strOptionExtra2 = string.sub(arg0, pos4+1);

    local Data1 = tonumber( strOptionExtra1 )      --Data1为表的编号
    local Data2 = tonumber( strOptionExtra2 )      --Data2为表中内容的index


    if( Data1 == 0 ) then       --首页

	        if (Data2 == -2) then	--新加的，收藏图鉴
    			PushEvent("OPEN_TJHANDBOOK", 0, 0, 0)
    			this:Hide();
    			return;
    		end

    		if (Data2 == -1) then	--新加的，武林图鉴
    			--PushDebugMessage("这里将要打开武林图鉴")
    			PushEvent("OPEN_PLAYERGUIDE", -1)
    			this:Hide();
    			return;
    		end

        if( Data2 == 0 ) then   --首页
            WorldReference_DispatchMainPage()
        end

        if( Data2 == 1 ) then   --任务表
            WorldReference_DispatchMissionTable()
        end

        if( Data2 == 2 ) then   --怪物
            WorldReference_DispatchMonsterTable()
        end
        if( Data2 == 3 ) then   --BOSS
            WorldReference_DispatchBossTable()
        end

        if( Data2 == 4 ) then   --时间
            WRAskTime()
        end

        if( Data2 == 5 ) then   --其他表
            WorldReference_DispatchOtherTable()
        end

		if (Data2 == 6) then	--用户协议
   			PushEvent("OPEN_AGREEMENT_SECOND_UI", 0, 0, 0)
   			this:Hide();
   			return;
   		end
    		
   		if (Data2 == 7) then	--隐私协议
   			PushEvent("OPEN_AGREEMENT_SECOND_UI", 1, 0, 0)
   			this:Hide();
   			return;
   		end

        if( Data2 == 8) then		--帐号安全表
			--WorldReference_DispatchAccountSafeTable(Data2);
			GameProduceLogin:OpenURL( "http://protect.changyou.com" )
        		return;
        end

        if( Data2 > 8 ) then
            WorldReference_DispatchContex( Data1, Data2 - 1 )
        end

    elseif( Data1 == 3 ) then	--BOSS表为了支持多级菜单需要进行特殊处理....
    	WorldReference_BOSSOptionClicked(Data2);
    elseif( Data1 == 8 ) then	--帐号安全表的子项
    	WorldReference_DispatchContexAccount(Data1, Data2);
    else
			WorldReference_DispatchContex( Data1, Data2 )   --显示一个内容文本
    end

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_WorldReference(objCaredId)
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_WorldReference(objCaredId)
end

--=========================================================
--显示某个BOSS的信息....
--=========================================================
function WorldReference_OpenBossInfo( BossId )

	WorldReference_BOSSOptionClicked( tonumber(BossId) )
	this:Show();

end

function WorldReference_ResetPos()
	WorldReference_Frame:SetProperty("UnifiedXPosition", g_WorldReference_Frame_UnifiedXPosition);
	WorldReference_Frame:SetProperty("UnifiedYPosition", g_WorldReference_Frame_UnifiedYPosition);

end
