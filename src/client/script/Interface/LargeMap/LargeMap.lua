local g_BackGroupName = {[0] = "WorldMap", [1] = "WorldMap_KVK", [2] = "WorldMap_KVK"}
local g_CurWorldMapType = 0 --0:世界地图，1大世界地图，2-昆吾秘境

local g_Image = {
	[1] = "",
	[2] = "",
	[3] = "",
}

local g_ManorId = {432,434,202}
local g_ManorName = {"汗血岭","昆仑福地","圣火宫"}

local g_pic ={"set:BHSDUI1 image:BHSD_Gold","set:BHSDUI1 image:BHSD_Silver","set:BHSDUI1 image:BHSD_Copper"}
local g_KVKSCENE_FAKEID = 597		
local g_T300SCENE_BianJing = 755

local gd_ownerInfo =
{
	[18]= {id =763, name ="#r此地处于中立状态", valid = 0,},
	[19]= {id =764, name ="#r此地处于中立状态", valid = 0,},
	[20]= {id =767, name ="#r此地处于中立状态", valid = 0,},
	[21]= {id =765, name ="#r此地处于中立状态", valid = 0,},
	[22]= {id =766, name ="#r此地处于中立状态", valid = 0,},
	[23]= {id =768, name ="#r此地处于中立状态", valid = 0,},
	[24]= {id =756, name ="#r此地处于中立状态", valid = 0,},
	[25]= {id =759, name ="#r此地处于中立状态", valid = 0,},
	[26]= {id =758, name ="#r此地处于中立状态", valid = 0,},
	[27]= {id =762, name ="#r此地处于中立状态", valid = 0,},
}
--有多少个场景
function LargeMap_PreLoad()
	this:RegisterEvent("TOGLE_LARGEMAP",true);
	this:RegisterEvent("TEAM_CHANGE_WORLD",true);
	--每一个场景得数据
   -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("ACC_CHANGE_TIPS",true)
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("REFRESH_LARGEMAP_KBUILDINGOCCUPIEDINFO",false)
	this:RegisterEvent("LARGEMAP_GUILDDOMAIN",true)
end

function LargeMap_OnLoad()
	g_Image[1] = LargeMap_hanxueling
	g_Image[2] = LargeMap_kunlunfudi
	g_Image[3] = LargeMap_shenghuogong
end

function LargeMap_OnEvent(event)
	if ( event == "TOGLE_LARGEMAP" ) then
		if( arg0 == "2" ) then
			if( this:IsVisible() ) then
				LargeMap_Close();
			else
				LargeMap_Show();
			end
		elseif ( arg0 == "1" ) then
			LargeMap_Show()
		else
			LargeMap_Close();
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		LargeMap_Frame_On_ResetPos();	
	elseif ( event == "TEAM_CHANGE_WORLD" ) then
			if( LargeMap_Frondground:IsVisible() ) then
				LargeMap_Frondground:UpdateWorldMap();
			end
	elseif ( event == "ACC_CHANGE_TIPS" )	then
		LargeMap_ChangeButtonTip()
		return;
	elseif(event == "UI_COMMAND" ) then
		if arg0 == "20150414" then
			if g_CurWorldMapType == 0 then
				local guildnames={"#r归属帮会：","#r归属帮会：","#r归属帮会："}
				local manorId={-1,-1,-1}
				
				for i=1,3 do
					guildnames[i] = guildnames[i]..Get_XParam_STR(i-1)
					manorId[i] = Get_XParam_INT(i-1)
					if manorId[i] == 434 then
						manorId[i] = 254
					elseif manorId[i] == 432 then
						manorId[i] = 255
					elseif manorId[i] == 202 then
						manorId[i] = 256
					end
				end
				
				LargeMap_Frondground:InitWorldMap(0,0,manorId[1],manorId[2],manorId[3],guildnames[1],guildnames[2],guildnames[3])
				if IsInFengMingServer() == 1 then 
					LargeMap_Frondground:SetCityCurrentScene(g_KVKSCENE_FAKEID, 1)
				end
			end
						
		end
		if tonumber(arg0) == 99816303 then
			if g_CurWorldMapType == 1 then
				local nCityName = {"", "", ""}
				local nCityWorldId = {-1, -1, -1}
				nCityWorldId[1] = Get_XParam_INT(0)
				nCityWorldId[2] = Get_XParam_INT(1)
				nCityWorldId[3] = Get_XParam_INT(2)
				for i = 1, table.getn(nCityWorldId) do
					nCityName[i] = Get_XParam_STR(i-1)
					if nCityWorldId[i] ~= -1 then
						local top_world_name = DataPool:GetServerName(tonumber(nCityWorldId[i]))
						if nCityName[i] ~= nil and nCityName[i] ~= "" then
							nCityName[i] = nCityName[i].."@"..top_world_name
						end
					end
				end
				local cityresid = {[1] = 853, [2]=851,[3] = 852}
				for i = 1, table.getn(nCityName) do
					if nCityName[i] ~= nil and nCityName[i] ~= "" then
						LargeMap_Frondground:SetFmInfo(cityresid[i],nCityName[i])
						nCityName[i] = ScriptGlobal_Format("#{BZTX_220705_256}", nCityName[i]) --该城市已被%s0帮会占领

					else
						nCityName[i] = "#{BZTX_220705_257}" --该城市目前无人占领
					end
				end
				LargeMap_Frondground:UpdateWorldMapInfoFoGuildDomain(1,
																	 851,nCityName[2],
																	 852,nCityName[3],
																	 853,nCityName[1],
																	 -1,"",
																	 -1,"",
																	 -1,"",
																	 -1,"",
																	 -1,"",
																	 -1,"",
																	 -1,""															 
																	)


			end
						
		end
		
	elseif event == "REFRESH_LARGEMAP_KBUILDINGOCCUPIEDINFO" then
		if this:IsVisible() then
			if g_CurWorldMapType == 1 then
				local KBuildingOccupiedInfo = KBuildingGroup:GetKBuildingOccupiedInfo()
				LargeMap_Frondground:InitWorldMap(1,0,KBuildingOccupiedInfo)
			end
		end
	elseif event == "LARGEMAP_GUILDDOMAIN" then
		if this:IsVisible() then
			if g_CurWorldMapType == 3 then  
				local tbl = Guild:GetGDOwnerInfo();				
				local guildnames= "#r归属帮会：#G" -- 
				for i, value in tbl do
					if gd_ownerInfo[value.id] ~= nil and value.valid == 1 then  
						gd_ownerInfo[value.id].name = guildnames..value.name  
					end
				end
				LargeMap_Frondground:UpdateWorldMapInfoFoGuildDomain(3,
																	 gd_ownerInfo[18].id,gd_ownerInfo[18].name,
																	 gd_ownerInfo[19].id,gd_ownerInfo[19].name,
																	 gd_ownerInfo[20].id,gd_ownerInfo[20].name,
																	 gd_ownerInfo[21].id,gd_ownerInfo[21].name,
																	 gd_ownerInfo[22].id,gd_ownerInfo[22].name,
																	 gd_ownerInfo[23].id,gd_ownerInfo[23].name,
																	 gd_ownerInfo[24].id,gd_ownerInfo[24].name,
																	 gd_ownerInfo[25].id,gd_ownerInfo[25].name,
																	 gd_ownerInfo[26].id,gd_ownerInfo[26].name,
																	 gd_ownerInfo[27].id,gd_ownerInfo[27].name																	 
																	)
			end
		end
	end
end

function LargeMap_Close()
	this:Hide()
	local nCurrentSelectScene = LargeMap_Frondground:GetCurrentSelectScene(); --得到当前选中的场景

	if( nCurrentSelectScene == GetSceneID() ) then
		ToggleSceneMap( 1 );
	end
end

function LargeMap_Show()
	if this:IsVisible() then
		return
	end
	ToggleSceneMap( 0 );--关闭场景地图

	--初始化
	if IsInFengMingServer() == 1 then
		LargeMap_AskTCityWarInfo()
		LargeMap_OpenKVKWorld_Map()
	else
		LargeMap_AskManorInfo()
		LargeMap_OpenNormalWorld_Map()
	end

	this:Show();
end

function LargeMap_Qiehuan_Clicked()
	ToggleSceneMap( 1 )
	ToggleAutoSearch(1) --likun
end

function LargeMap_QiehuanKVK_Clicked()
	if g_CurWorldMapType == 0 then
		LargeMap_AskTCityWarInfo()
		LargeMap_OpenKVKWorld_Map()
	else
		LargeMap_AskManorInfo()
		LargeMap_OpenNormalWorld_Map()
	end	
	
	this:Show()
end

function LargeMap_Click_KVKScene() --点击KVK场景地图 跳转
	--昆吾秘境
	LargeMap_OpenKVKWorld_Map()
end

--昆吾秘境
function LargeMap_OpenKWWorld_Map()
	--场景判断
	LargeMap_Frondground:SetProperty("BackgroundSize", "w:5 h:4")
	if g_CurWorldMapType ~= 2 then
		--当前是普通世界地图
		LargeMap_Frondground:SetProperty("BackgroundName", g_BackGroupName[2])
		LargeMap_Frondground:InitWorldMap(2, 1)--2为新增昆吾秘境 1为kvk 0为普通
		g_CurWorldMapType = 2
		LargeMap_QiehuanKVK:SetProperty("Visible","False")
	else
		LargeMap_Frondground:InitWorldMap(2)
	end
end

function LargeMap_OpenKVKWorld_Map()
	LargeMap_Frondground:SetProperty("BackgroundSize", "w:5 h:4")
	if g_CurWorldMapType ~= 1 then
		--当前是普通世界地图
		LargeMap_Frondground:SetProperty("BackgroundName", g_BackGroupName[1])
		LargeMap_Frondground:InitWorldMap(1, 1)
		g_CurWorldMapType = 1
		LargeMap_QiehuanKVK:SetText("#{DTQH_090305_2}")
		LargeMap_QiehuanKVK:SetToolTip("#{KVKGZ_110620_144}")
		LargeMap_QiehuanKVK:SetProperty("Visible","True")
	else
		LargeMap_Frondground:InitWorldMap(1)
	end
end

function LargeMap_OpenNormalWorld_Map()
	LargeMap_QiehuanKVK:SetText("#{TWTB_200818_07}")
	LargeMap_QiehuanKVK:SetToolTip("#{TWTB_200818_06}")
	LargeMap_Frondground:SetProperty("BackgroundSize", "w:5 h:4")
	LargeMap_QiehuanKVK:SetProperty("Visible","False")
	if g_CurWorldMapType ~= 0 then
		--当前是KVK世界地图
		LargeMap_Frondground:SetProperty("BackgroundName", g_BackGroupName[0])
		LargeMap_Frondground:InitWorldMap(0, 1)
		if IsInFengMingServer() == 1 then 
			LargeMap_Frondground:SetCityCurrentScene(g_KVKSCENE_FAKEID, 1)
		end
		g_CurWorldMapType = 0
	else
		LargeMap_Frondground:InitWorldMap(0)
		if IsInFengMingServer() == 1 then 
			LargeMap_Frondground:SetCityCurrentScene(g_KVKSCENE_FAKEID, 1)
		end
	end
end

function LargeMap_Click_NormalScene()
	local g_CurSelectSceneID = LargeMap_Frondground:GetProperty("CurrentScene")
	if  tonumber(g_CurSelectSceneID) == 4294967295 then
		return
	end
	local targetSceneId = tonumber(g_CurSelectSceneID)
	if targetSceneId == g_KVKSCENE_FAKEID then 
		LargeMap_Click_KVKScene()
	else
		local mapname = GetSceneMapByID(g_CurSelectSceneID)
		--发送信息
		PushEvent("TOGLE_SCENE_MAP", tostring(mapname), "3", g_CurSelectSceneID);
		this:Hide()
		--SceneMap_Show_OhterScene( mapname , g_CurSelectSceneID)
	end

end

function LargeMap_Frame_On_ResetPos()
	local curResolution = Variable:GetVariable( "View_Resoution" );
	if curResolution == nil or curResolution == "" then
		return
	end

	local split = string.sub(curResolution, 4, 4);
	local curResolutionL;
	if split == "," then
		curResolutionL = string.sub(curResolution, 1, 3);
	else
		curResolutionL = string.sub(curResolution, 1, 4);
	end
	local number = tonumber(curResolutionL)
	
	if number ~= nil and number <= 900 then
		LargeMap_Frondground_Text : SetProperty("UnifiedXPosition", "{0.500000,-395.000000}");
		LargeMap_Frondground_Text : SetProperty("UnifiedYPosition", "{1.000000,-25.000000}");
	else		
		LargeMap_Frondground_Text : SetProperty("UnifiedXPosition", "{0.500000,-203.000000}");
		LargeMap_Frondground_Text : SetProperty("UnifiedYPosition", "{1.000000,-25.000000}");	
	end
end

function LargeMap_ChangeButtonTip()
	local noChatActiveMode = Variable:GetVariable("NonChatActive");
	if noChatActiveMode == "1" then
		LargeMap_Qiehuan						:SetToolTip("#{JPYD_130822_15}")
	else
		LargeMap_Qiehuan						:SetToolTip("#{DTQH_090305_3}")
	end
end

function LargeMap_AskManorInfo()
	if (IsInTServer() == 1) then
		--PushDebugMessage("#{BHKF_140909_327}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAskMap")
		Set_XSCRIPT_ScriptID(891063) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function LargeMap_AskTCityWarInfo()
	if (IsInTServer() ~= 1) then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAskTCityWarMap")
		Set_XSCRIPT_ScriptID(998163) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

	local cityresid = {[1] = 853, [2]=851,[3] = 852}
	for i = 1, table.getn(cityresid) do
			LargeMap_Frondground:SetFmInfo(cityresid[i],"")
	end	
end
