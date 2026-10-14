local g_NeedTipID = -1
local g_CurSelectSceneID = -1 --选择的地图场景
local g_DungeonsTable = {}   --地下城
local g_DungeonsIndex = -1	 --记录地下城索引
local g_IsTServerMapSizeSelect = 0 --Tserver场景，默认为最小化的地图
local g_OldMapMode = -1 --原地图大小

local g_SceneMapUsage = 0		--UI当前的用处 0是默认场景地图
local g_initial_size = ""
local g_initial_pos = ""
local g_scene_filename = ""
local g_screensize = ""

local g_MenPaiorZongMenSceneID = -1 --门派和宗门选项切换
local g_SceneMap_ShenbingLevel = 1
local MapInfoList = {

	SHOW_SCENE_MAP	=	0,
	SBG_HUMANINFO	=	1 ,		--神兵阁人员情况

}


local g_KvKMaZeiSceneList = {
	[573]={	sceneName="漠南青原",	ServerResID=466  },
	[574]={	sceneName="忘川花海",	ServerResID=467  },
	[575]={	sceneName="天岐南淮",	ServerResID=468  },
	[569]={	sceneName="林海溪谷",	ServerResID=465  },
	[613]={	sceneName="水月洞天",	ServerResID=498  },
	[669]={	sceneName="沁水丹林",	ServerResID=583  },
	[670]={	sceneName="云遥鹊岭",	ServerResID=582  },
}

--运矿活动场景
local g_KvKMineralSceneList = {
	[671]={	ServerResID=985  },
	[672]={	ServerResID=986  },
	[673]={	ServerResID=987  },
	[674]={	ServerResID=988  },
	[675]={	ServerResID=989  },
	[676]={	ServerResID=990  },
}

local g_SameSceneId = {
	[0] = 242,
	[242] = 0,
}

local g_SceneMapShenbingge = {
	[1] =  { [1] = {resid = 640} , [2] = { resid = 1033}},
	[2] =  { [1] = {resid = 641} , [2] = { resid = 1034}},
	[3] =  { [1] = {resid = 642} , [2] = { resid = 1035}},
	[4] =  { [1] = {resid = 643} , [2] = { resid = 1036}},
	[5] =  { [1] = {resid = 644} , [2] = { resid = 1037}},
}


local g_MenPai_To_ZongMen_List = {--menpai15 mptodo
	[9] = 883,
	[10] = 891,
	[11] = 887,
	[12] = 886,
	[13] = 889,
	[14] = 888,
	[15] = 890,
	[16] = 885,
	[17] = 884,
	[284] = 892,
	[615] = 893,
	[678] = 894,
	[731] = 895,
	[824] = 896,
	[987] = 988

}


local g_ZongMen_To_MenPai_List = {--menpai15 mptodo
	[883] = 9,
	[891] = 10,
	[887] = 11,
	[886] = 12,
	[889] = 13,
	[888] = 14,
	[890] = 15,
	[885] = 16,
	[884] = 17,
	[892] = 284,
	[893] = 615,
	[894] = 678,
	[895] = 731,
	[896] = 824,
	[988] = 987

}

local g_ZongMen_ToolTip_List = {

	[9] = { ToolTip="#{ZMCJ_230719_21}", ButtonText="#{ZMCJ_230719_93}" },
	[10] = { ToolTip="#{ZMCJ_230719_20}", ButtonText="#{ZMCJ_230719_92}" },
	[11] = { ToolTip="#{ZMCJ_230719_27}", ButtonText="#{ZMCJ_230719_99}" },
	[12] = { ToolTip="#{ZMCJ_230719_22}", ButtonText="#{ZMCJ_230719_94}" },
	[13] = { ToolTip="#{ZMCJ_230719_24}", ButtonText="#{ZMCJ_230719_96}" },
	[14] = { ToolTip="#{ZMCJ_230719_23}", ButtonText="#{ZMCJ_230719_95}" },
	[15] = { ToolTip="#{ZMCJ_230719_19}", ButtonText="#{ZMCJ_230719_91}" },
	[16] = { ToolTip="#{ZMCJ_230719_25}", ButtonText="#{ZMCJ_230719_97}" },
	[17] = { ToolTip="#{ZMCJ_230719_26}", ButtonText="#{ZMCJ_230719_98}" },
	[284] = { ToolTip="#{ZMCJ_230719_18}", ButtonText="#{ZMCJ_230719_90}" },
	[615] = { ToolTip="#{ZMCJ_230719_28}", ButtonText="#{ZMCJ_230719_100}" },
	[678] = { ToolTip="#{ZMCJ_230719_17}", ButtonText="#{ZMCJ_230719_89}" },
	[731] = { ToolTip="#{ZMCJ_230719_29}", ButtonText="#{ZMCJ_230719_101}" },
	[824] = { ToolTip="#{ZMCJ_230719_16}", ButtonText="#{ZMCJ_230719_88}" },
	[987] = { ToolTip="#{ZMCJ_240709_04}", ButtonText="#{ZMCJ_240709_05}" },
}


local g_JDTS_SceneMapFile = {
	["dali_new_320"]="dali_new_320_SJ",
	["dali_new_320_SP"]="dali_new_320_SP_SJ",
	["petisland_new"]="petisland_new_SJ",
	["suzhou_new"]="suzhou_new_SJ",
	["suzhou_new_SP"]="suzhou_new_SP_SJ",
	["xihuscene"]="xihuscene_SJ",
	["jiangescene"]="jiangescene_SJ",
	["yannanscene"]="yannanscene_SJ",
	["PCity"]="PCity_SJ",
	["luoyang_new_SP"]="luoyang_new_SP_SJ",
	["luoyang_new"]="luoyang_new_SJ",
	["luoyang_new_snow"]="luoyang_new_snow_SJ",
}

local g_2606S_SceneMapFile = {
	["dali_new_320_SP"]="dali_new_320_SP_QX",
	["dali_new_320"]="dali_new_320_QX",
	["luoyang_new"]="luoyang_new_QX",
	["luoyang_new_snow"]="luoyang_new_snow_QX",
	["luoyang_new_SP"]="luoyang_new_SP_QX",
	["suzhou_new"]="suzhou_new_QX",
	["suzhou_new_SP"]="suzhou_new_SP_QX",
	["PCity"]="PCity_QX",
	["petisland_new"]="petisland_QX",
	["qinhuanggong_4"]="qinhuanggong_4_QX",
	["shuhe"]="shuhe_QX",

}

--FalagardWorldMap 中也有
local  g_JDTS_ForbiddenSceneRes = {
	[731]=1,[824]=1,[987]=1,
	[597]=1,[615]=1,[678]=1,
};

local  g_2606S_ForbiddenSceneRes = {
	[755]=1,[597]=1,[1016]=1,
	[993]=1,[994]=1,
};

function SceneMap_PreLoad()
	this:RegisterEvent("SCENE_TRANSED",false)
	this:RegisterEvent("TOGLE_SCENE_MAP",true)
	this:RegisterEvent("UPDATE_MAP",false)
	this:RegisterEvent("NEW_MISSION",false)
   -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ACC_CHANGE_TIPS",false)
	this:RegisterEvent("PLAYER_ENTERING_WORLD",true )	-- 进入world
	this:RegisterEvent("RESET_ALLUI",true)				-- 返回登录界面, 重置所有UI
	this:RegisterEvent("SCENEMAP_SHOW_SBGHUMANINFO",true)
	this:RegisterEvent("ZOOMOUT_BLUECIRCLE",false)
	this:RegisterEvent("SHOW_BLUECIRCLE",false)
	this:RegisterEvent("COMMANDERFLAG_REFRESH",false)
	this:RegisterEvent("UI_COMMAND",false)
end

function SceneMap_OnLoad()


	g_DungeonsTable[1]={maplist={}}
	g_DungeonsTable[1].maplist[1] = {sceneId = 166, name = "宝藏洞一层"}
	g_DungeonsTable[1].maplist[2] = {sceneId = 169, name = "宝藏洞二层"}
	g_DungeonsTable[1].maplist[3] = {sceneId = 191, name = "宝藏洞三层"}
	g_DungeonsTable[1].maplist[4] = {sceneId = 192, name = "宝藏洞四层"}
	g_DungeonsTable[1].maplist[5] = {sceneId = 193, name = "宝藏洞五层"}

	g_DungeonsTable[2]={maplist={}}
	g_DungeonsTable[2].maplist[1] = {sceneId = 202, name = "燕王古墓一层"}
	g_DungeonsTable[2].maplist[2] = {sceneId = 203, name = "燕王古墓二层"}
	g_DungeonsTable[2].maplist[3] = {sceneId = 204, name = "燕王古墓三层"}
	g_DungeonsTable[2].maplist[4] = {sceneId = 205, name = "燕王古墓四层"}
	g_DungeonsTable[2].maplist[5] = {sceneId = 206, name = "燕王古墓五层"}
	g_DungeonsTable[2].maplist[6] = {sceneId = 207, name = "燕王古墓六层"}
	g_DungeonsTable[2].maplist[7] = {sceneId = 208, name = "燕王古墓七层"}
	g_DungeonsTable[2].maplist[8] = {sceneId = 209, name = "燕王古墓八层"}
	g_DungeonsTable[2].maplist[9] = {sceneId = 210, name = "燕王古墓九层"}

	g_DungeonsTable[3]={maplist={}}
	g_DungeonsTable[3].maplist[1] = {sceneId = 262, name = "秦皇地宫一层"}
	g_DungeonsTable[3].maplist[2] = {sceneId = 263, name = "秦皇地宫二层"}
	g_DungeonsTable[3].maplist[3] = {sceneId = 264, name = "秦皇地宫三层"}
	g_DungeonsTable[3].maplist[4] = {sceneId = 292, name = "秦皇地宫四层"}
	g_DungeonsTable[3].maplist[5] = {sceneId = 1042, name = "秦皇地宫五层"}

	g_DungeonsTable[4]={maplist={}}
	g_DungeonsTable[4].maplist[1] = {sceneId = 295, name = "通天塔地宫"}
	g_DungeonsTable[4].maplist[2] = {sceneId = 296, name = "通天塔一层"}
	g_DungeonsTable[4].maplist[3] = {sceneId = 297, name = "通天塔二层"}
	g_DungeonsTable[4].maplist[4] = {sceneId = 298, name = "通天塔三层"}
	g_DungeonsTable[4].maplist[5] = {sceneId = 299, name = "通天塔塔顶"}

	g_initial_size = SceneMap_Frame:GetProperty("UnifiedSize")
	g_initial_pos = SceneMap_Frame:GetProperty("UnifiedPosition")



	sceneMap_Zongmen:SetEvent( "Clicked", "SceneMap_ZongMenScene_Clicked()")
	sceneMap_Zongmen:Hide()

end

function SceneMap_IsBieYeMap()
	if string.sub(g_scene_filename,1,7) == "jiayuan" then
		return true
	else
		return false
	end
end

function SceneMap_IsMinMapScene()
	if Lua_IsInTXiongBa()==1 then return 1 end
	if Lua_IsInTXbwScene()==1 then return 1 end
	return 0
end

function SceneMap_GM_GotoPos()

	if g_SceneMapUsage == MapInfoList.SHOW_SCENE_MAP then
		local coordinatex,coordinatey
		coordinatex, coordinatey = SceneMap_Board:GetMouseScenePos()
		local str
		str = "goto ="..tostring( coordinatex )..","..tostring( coordinatey )
		local nSceneID = tonumber(g_CurSelectSceneID)
		local curSceneID = GetSceneID()
		if nSceneID ~= -1 and nSceneID ~= curSceneID then
			--增加一层转换，由于原来该场景ID只是单纯客户端的资源ID，和服务器的场景ID可能对不上，所以做一次转换 modify 2018-06-26 by guopengjie
			nSceneID = Lua_GetSceneIDByResID(nSceneID)
			if nSceneID ~= -1 then
				str = str.."="..tostring(nSceneID)
			end
			str = str.."=9"
		end
		SendGMCommand( str )
	end
	
end

function SceneMap_GotoDirectly()

	if g_SceneMapUsage == MapInfoList.SHOW_SCENE_MAP then
		local coordinatex,coordinatey,curSceneID
		coordinatex, coordinatey = SceneMap_Board:GetMouseScenePos()
		-- 检测是否进入指挥操作
		local enterCommanderLogic = SceneMap_CheckEnterCommanderFlag(coordinatex,coordinatey)
		if enterCommanderLogic > 0 then
			return
		end
		curSceneID = GetSceneID()
		if	g_CurSelectSceneID ~= -1 and g_CurSelectSceneID ~= curSceneID then
			if g_SameSceneId[ g_CurSelectSceneID ] and g_SameSceneId[ g_CurSelectSceneID ]  == curSceneID then
				AutoRunToTarget(coordinatex, coordinatey)
			else
				AutoRunToTargetEx(coordinatex,coordinatey,tonumber(g_CurSelectSceneID))
			end
		else
			AutoRunToTarget(coordinatex, coordinatey)
		end

		if g_NeedTipID == 1 then
			CloseFreshManGuide() --这里得先hide一下,因为这俩窗口都是alwaysontop
			SceneMap_FreshManGuide(1, 16, 1)
			g_NeedTipID = -1
		end

	end

end

function SceneMap_OnEvent(event)

	if ( event == "TOGLE_SCENE_MAP" ) then
		local curSceneID = GetSceneID(); --周常pve屏蔽地图
		if curSceneID == 999 then
			if(IsWindowShow("ZhouchangPVE_SceneFb")) then
				CloseWindow("ZhouchangPVE_SceneFb", true)
			else 
				 Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("OpenMap")
					Set_XSCRIPT_ScriptID(331105)
					Set_XSCRIPT_ParamCount(0)
				Send_XSCRIPT()
			end
			return 
		end
		
		--风云pvp屏蔽地图
		if curSceneID == 1049 then
			if(IsWindowShow("FengYun_JianJiSceneFb")) then
				CloseWindow("FengYun_JianJiSceneFb", true)
			else 
				 Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("OpenMap")
					Set_XSCRIPT_ScriptID(331200)
					Set_XSCRIPT_ParamCount(0)
				Send_XSCRIPT()
			end
			return 
		end
		if ( arg1 == "2" ) then
			if this:IsVisible() and g_SceneMapUsage == MapInfoList.SHOW_SCENE_MAP then
				SceneMap_Close()
				ToggleAutoSearch(0)
			else
				g_SceneMapUsage = MapInfoList.SHOW_SCENE_MAP
				SceneMap_Text3:SetText("#{KCJXL_130417_1}")
				sceneMap_ComboList:ResetList() 	--显示前重置一下下拉列表
				SceneMap_Show( arg0 )
				ToggleAutoSearch(1)
			end
			return
		end
		if ( arg1 == "1" ) then
			g_SceneMapUsage = MapInfoList.SHOW_SCENE_MAP
			SceneMap_Text3:SetText("#{KCJXL_130417_1}")
			sceneMap_ComboList:ResetList() 		--显示前重置一下下拉列表
			SceneMap_Show( arg0 )
			ToggleAutoSearch(1)
			return
		end
		if ( arg1 == "3" ) then
			g_SceneMapUsage = MapInfoList.SHOW_SCENE_MAP
			if tonumber(arg2) == GetSceneID() then
				SceneMap_Text3:SetText("#{KCJXL_130417_1}")
			else
				SceneMap_Text3:SetText("#{KCJXL_130417_3}")
			end
			sceneMap_ComboList:ResetList() 		--显示前重置一下下拉列表
			SceneMap_Show_OhterScene(tostring(arg0), tonumber(arg2))
			--判断是否是K服的五个场景，其他的不响应
			local nIsFiveScene = tonumber(arg2)
			Lua_SetCurSelectedSceneID(nIsFiveScene)
			if nIsFiveScene == 569 or
				nIsFiveScene == 573 or
				nIsFiveScene == 574 or
				nIsFiveScene== 575 or
				nIsFiveScene == 613 then
				--只有请求的是这个五个场景，才转发发包
				if KVKInterface:IsInKVKServer() == 1 then
					Lua_SendMazeiRequest(g_KvKMaZeiSceneList[nIsFiveScene].ServerResID)
				end
			end

			return
		end

		SceneMap_Close()
		ToggleAutoSearch(0)
		return
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		g_screensize = arg1
		SceneMap_Frame_On_ResetPos()
	elseif ( event == "UPDATE_MAP" ) then
		SceneMap_Update()
	elseif( event == "SCENE_TRANSED" ) then
		SceneMap_Close()
	elseif ( event == "ACC_CHANGE_TIPS" )	then
		SceneMap_ChangeButtonTip()
		return
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		g_IsTServerMapSizeSelect = 0
	elseif ( event == "RESET_ALLUI" ) then
		-- g_OldMapMode = -1
		
	elseif ( event == "ZOOMOUT_BLUECIRCLE") then
		SceneMap_Board:ZoomOutBlueCircle(tonumber(arg0))
		
	elseif ( event == "SHOW_BLUECIRCLE" ) then
		if this:IsVisible() then
			local sceneID = GetSceneID()
			if sceneID == 992 then
				SceneMap_Board:ShowBuleCircle()
			end
	  end
	elseif ( event == "COMMANDERFLAG_REFRESH" ) then
		CommanderFlag:CommanderShow(g_CurSelectSceneID)
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20160620) then
		local nType = Get_XParam_INT(0)
		if nType == 30 then -- 别墅切换区域
			SceneMap_Close()
		end
	end

	if event == "SCENEMAP_SHOW_SBGHUMANINFO" then


			g_SceneMapUsage = MapInfoList.SBG_HUMANINFO
			SceneMap_SbgHumanInfo_Show(tonumber(arg0))
	end


end

function SceneMap_SbgHumanInfo_New()
	SceneMap_Board:UpdateSbgHumanFlag()
end

function SceneMap_Close()
	SceneMap_Board:CloseSceneMap()
	this:Hide()
	ToggleAutoSearch(0) --likun
	-- local x,z = SceneMap_Board:GetBaseOffset()
	-- PushDebugMessage(x)
	-- PushDebugMessage(z)

	g_MenPaiorZongMenSceneID = -1
end

function SceneMap_Show( parfilename )


	local sceneX, sceneY
	sceneX,sceneY = GetSceneSize()		--这都是当前场景的函数啊
	local filename = parfilename
	if Player:GetData("IsOriginalJD") == 1 and g_JDTS_SceneMapFile[filename] then
		filename = g_JDTS_SceneMapFile[filename]
	end
	if Player:GetData("Is2606S") == 1 and g_2606S_SceneMapFile[filename] then
		filename = g_2606S_SceneMapFile[filename]
	end
	SceneMap_Board:SetSceneFileName( sceneX,sceneY,filename,1)
	SceneMap_FixZoom(filename)
	g_bieye_last_inhouse = BieYeUI:GetBieYeAreaType(Player:GetPos())

	local scenename
	scenename = GetCurrentSceneName()
	SceneMap_SceneName:SetText("#gFF0FA0".. scenename )

	g_DungeonsIndex = -1
	-- 如果非大场景，还需要重置其缩放模式
	local mode = SceneMap_Board:GetSceneZoomMode()
    if mode == 1 then  -- 1模式为512X512独有。。。擦
        local sceneX, sceneY = GetSceneSize()
        if sceneX < 512 and sceneY < 512 then
            -- 重置为像素比例模式
            SceneMap_Board:SetSceneZoomMode(2)
        end
    end

	ToggleLargeMap(0)

	--换按钮名称
	if IsInFengMingServer() == 1 then
		sceneMap_LargeMap:SetText("#{TQDTCJ_20220725_07}")
		sceneMap_LargeMap:SetToolTip("#{TQDTCJ_20220725_08}")
	else
		sceneMap_LargeMap:SetText("#{DTQH_090305_2}")
		local noChatActiveMode = Variable:GetVariable("NonChatActive")
		if noChatActiveMode == "1" then
			sceneMap_LargeMap						:SetToolTip("#{JPYD_130822_17}")
		else
			sceneMap_LargeMap						:SetToolTip("#{DTQH_090305_4}")
		end
	end


	--是否是多层场景
	local sceneID = GetSceneID()
	g_CurSelectSceneID = sceneID --记录一下当前选择场景ID
	Lua_SetCurSelectedSceneID(g_CurSelectSceneID)
	CommanderFlag:SetSceneMapSelect(g_CurSelectSceneID)
	local tempIndex = nil
	for i = 1, table.getn(g_DungeonsTable) do
		for j = 1, table.getn(g_DungeonsTable[i].maplist) do
			if g_DungeonsTable[i].maplist[j].sceneId == sceneID then
				g_DungeonsIndex = i
				tempIndex = j
				--sceneMap_ComboList:SetProperty("Disabled", "True")
				break
			end
		end
	end

	if (g_DungeonsIndex ~= -1 and tempIndex ~= nil ) then		--是多层场景
		--sceneMap_ComboList:ResetList()
		sceneMap_ComboList:SetProperty("Visible", "True")
		for i = 1, table.getn(g_DungeonsTable[g_DungeonsIndex].maplist) do
			if  not (g_DungeonsIndex == 3 and  Player:GetData("Is2606S") == 1) or i ~= 5 then
				sceneMap_ComboList:ComboBoxAddItem(g_DungeonsTable[g_DungeonsIndex].maplist[i].name,i)
			end
		end
		sceneMap_ComboList:SetCurrentSelect(tempIndex-1)
	else
		sceneMap_ComboList:ComboBoxAddItem(scenename,1)       --普通场景
		sceneMap_ComboList:SetProperty("Visible", "False")
		sceneMap_ComboList:SetCurrentSelect(0)
	end

	if SceneMap_IsMinMapScene()==1 and g_IsTServerMapSizeSelect==0 then
		if g_OldMapMode == -1 then
			g_OldMapMode = SceneMap_Board:GetSceneZoomMode()
		end
		SceneMap_Board:SetSceneZoomMode(0)
		g_IsTServerMapSizeSelect = 1
	elseif SceneMap_IsMinMapScene()==0 and g_OldMapMode~=-1  then --表示去过T服
		if g_OldMapMode~=nil and g_OldMapMode>=0 and g_OldMapMode<=3 then
			SceneMap_Board:SetSceneZoomMode(g_OldMapMode)
			g_OldMapMode = -1
		end
	end



	if 	sceneID == 9 or sceneID == 10 or sceneID == 11 or sceneID == 12 or
	sceneID == 13 or sceneID == 14 or sceneID == 15 or sceneID == 16 or
	sceneID == 17 or sceneID == 284 or sceneID == 615 or sceneID == 678 or
	sceneID == 731 or sceneID == 824 or sceneID == 987 then

		g_MenPaiorZongMenSceneID = 0

		if g_ZongMen_ToolTip_List[sceneID] ~= nil then
			sceneMap_Zongmen:SetText(g_ZongMen_ToolTip_List[sceneID].ButtonText)
			sceneMap_Zongmen:SetToolTip(g_ZongMen_ToolTip_List[sceneID].ToolTip)
		end

		sceneMap_Zongmen:Show()

	elseif	sceneID == 883 or sceneID == 891 or sceneID == 887 or sceneID == 886 or
	sceneID == 889 or sceneID == 888 or sceneID == 890 or sceneID == 885 or
	sceneID == 884 or sceneID == 892 or sceneID == 893 or sceneID == 894 or
	sceneID == 895 or sceneID == 896 or sceneID == 988 then

		g_MenPaiorZongMenSceneID = 1

		sceneMap_Zongmen:SetText("#{ZMCJ_230719_30}")
		sceneMap_Zongmen:SetToolTip("#{ZMCJ_230719_31}")
		sceneMap_Zongmen:Show()


	else
		sceneMap_Zongmen:Hide()

	end
	
	if sceneID == 992 or sceneID == 1015 then
		SceneMap_Board:ShowBuleCircle()
	else
		SceneMap_Board:HideBuleCircle()
	end

	this:Show()

	sceneMap_LargeMap:Show()
	sceneMap_back:Show()

	CommanderFlag:CommanderShow(g_CurSelectSceneID)
end

function SceneMap_SbgHumanInfo_Show( nClientResID )

	
	sceneMap_ComboList:ResetList()
	SceneMap_Text3:SetText("#{SBGYH_151123_12}")

	local sceneX, sceneY = GetSceneSizeByID(tonumber(nClientResID))
	local mapname = GetSceneMapByID(tonumber(nClientResID))
	SceneMap_Board:SetSceneFileName( sceneX,sceneY,mapname,1)

	local scenename = GetSceneNameByResID(tonumber(nClientResID))
	SceneMap_SceneName:SetText("#gFF0FA0"..scenename)

	-- 如果非大场景，还需要重置其缩放模式
	local mode = SceneMap_Board:GetSceneZoomMode()
    if mode == 1 then  -- 1模式为512X512独有。。。擦
        if sceneX < 512 and sceneY < 512 then
            -- 重置为像素比例模式
            SceneMap_Board:SetSceneZoomMode(2)
        end
    end

	sceneMap_ComboList:SetProperty("Visible", "False")
	sceneMap_ComboList:ComboBoxAddItem(scenename,1)
	sceneMap_ComboList:SetCurrentSelect(0)

	this:Show()

	sceneMap_LargeMap:Hide()
	sceneMap_back:Hide()

	SceneMap_Board:UpdateSbgHumanFlag()

end

function SceneMap_Update()
	if( this:IsVisible() ) then
		if g_SceneMapUsage == MapInfoList.SHOW_SCENE_MAP then
			SceneMap_Board:UpdateFlag()
		end
	else
		-- 帮会交互设计特写
		--DataPool : UpdateSceneMapPos( 0 )
	end
end

function SceneMap_UpdateInfo()
	local coordinatex,coordinatey
	coordinatex, coordinatey = SceneMap_Board:GetMouseScenePos()
	SceneMap_Crood:SetText( tostring( coordinatex ).."    "..tostring( coordinatey ) )
end

-- 原来这里传入的参数，直接就是缩放模式值
-- 现在改一下，让他只表示，点击了缩小还是放大
function SceneMap_ZoomMode(zoom)
    local mode = SceneMap_Board:GetSceneZoomMode()
    if mode == nil or mode < 0 or mode > 4 then
        return
    end
    -- 512X512 以上3种，小场景2种
	local sceneX,sceneY = GetSceneSize()

	if SceneMap_IsBieYeMap() then
		local bIsInner = BieYeUI:GetBieYeAreaType(Player:GetPos())
		if bIsInner == 1 then
			mode = 3
		else
			mode = 2
		end
		
	else
		if zoom == 0 then
            if mode <= 0 then
                return
            end
            mode = mode - 1
			if ( sceneX < 512 or sceneY < 512 ) and mode == 1 then
				mode = 0
			end
        else
            if mode >= 2 then
                return
            end
            mode = mode + 1
			if ( sceneX < 512 or sceneY < 512 ) and mode == 1 then
				mode = 2
			end
        end
	end
	SceneMap_RawZoom( mode )
end

function SceneMap_RawZoom( n, sceneId )
	n = math.floor(n)
	if n == nil or n < 0 or n > 4 then
        return
    end
	if SceneMap_IsBieYeMap() then
		local bIsInner = BieYeUI:GetBieYeAreaType(Player:GetPos())
		if bIsInner == 1 then
			n = 3
		else
			n = 4
		end
	elseif n > 2 then
		n = 2
	end
	SceneMap_Board:SetSceneZoomMode(n)
end

function SceneMap_fixJiayuan( number )
	local myheight = 600
	if SystemSetup:IsClassic() ~= 1 then
		myheight = 640
	end
	SceneMap_Frame:SetProperty( "AbsoluteSize", string.format( "w:800.000000 h:%.3f", myheight ) )

	if not g_screensize or not tonumber(g_screensize) then
		local rs = Variable:GetVariable( "View_Resoution" )
		number = tonumber( string.sub( rs, 1, string.find( rs, ',' ) - 1 ) )
	else
		number = math.floor(tonumber(g_screensize)/10000)
	end
	if number < 1120 then
		SceneMap_Frame:SetProperty("UnifiedPosition", string.format( "{{0.0,%d},{0.5,%.3f}}", number - 960, -myheight / 2 ) )
	else
		SceneMap_Frame:SetProperty("UnifiedPosition", string.format( "{{0.5,-400},{0.5,%.3f}}", -myheight / 2 ) )
	end
	local bIsInner = BieYeUI:GetBieYeAreaType(Player:GetPos())
	if bIsInner == 1 then
		SceneMap_RawZoom( 3 )
		SceneMap_Board:SetFixMode(true,-0.851,-0.348)
	else
		SceneMap_RawZoom( 4 )
		SceneMap_Board:SetFixMode(true,-0.109,-0.724)
	end
	
end


function SceneMap_FixZoom( filename, sceneId )
	g_scene_filename = filename
	local mode = SceneMap_Board:GetSceneZoomMode()
    if mode == nil or mode < 0 or mode > 4 then
        return
    end
	if SceneMap_IsBieYeMap() then
		SceneMap_fixJiayuan()
		SceneMap_MoveL:Hide()
		SceneMap_MoveR:Hide()
		SceneMap_MoveUp:Hide()
		SceneMap_MoveDown:Hide()
		ScemeMap_ZoomButtons1:Hide()
		ScemeMap_ZoomButtons2:Hide()
		SceneMap_Text2:Hide()
	elseif SceneMap_IsXRZPVPMap() > 0 then
		SceneMap_Board:SetFixMode(false,-0.5,-0.5)
		SceneMap_Frame:SetProperty("UnifiedSize",g_initial_size)
		SceneMap_Frame:SetProperty("UnifiedPosition",g_initial_pos)
		SceneMap_ZoomMode(0, sceneId)
		SceneMap_MoveL:Hide()
		SceneMap_MoveR:Hide()
		SceneMap_MoveUp:Hide()
		SceneMap_MoveDown:Hide()
		ScemeMap_ZoomButtons1:Hide()
		ScemeMap_ZoomButtons2:Hide()
		SceneMap_Text2:Hide()
	else
		SceneMap_Board:SetFixMode(false,-0.5,-0.5)
		SceneMap_Frame:SetProperty("UnifiedSize",g_initial_size)
		SceneMap_Frame:SetProperty("UnifiedPosition",g_initial_pos)
		if mode > 2 and not SceneMap_IsBieYeMap() then
			SceneMap_RawZoom( 2, sceneId )
		end
		SceneMap_MoveL:Show()
		SceneMap_MoveR:Show()
		SceneMap_MoveUp:Show()
		SceneMap_MoveDown:Show()
		ScemeMap_ZoomButtons1:Show()
		ScemeMap_ZoomButtons2:Show()
		SceneMap_Text2:Show()
	end
end

function sceneMap_LargeMap_Clicked()
	ToggleLargeMap( 1 )
end

function SceneMap_OnHidden()
    if "SceneMap" == GetFreshManGuideOwner() then
        CloseFreshManGuide()
    end

	g_SceneMapUsage = MapInfoList.SHOW_SCENE_MAP
	
	if IsWindowShow("WarMarker") then
		CloseWindow("WarMarker", true)
	end
end

function SceneMap_FreshManGuide(nType, nTextID, nPosID)
    if nType ~= 1 and      --1 is reset and open
        nType ~= 2 then    --2 is modify
        return
    end
    if g_NeedTipID < 1 then
        return
    end
    if Player:GetData("LEVEL") > 10 then
        return
    end

    local fX = 0
    local fY = 0
    if 1 == nPosID then
        fX, fY = this:GetChildOffset("SceneMap_Board")
        fX = fX + SceneMap_Board:GetProperty("AbsoluteWidth") / 2
        fY = fY + SceneMap_Board:GetProperty("AbsoluteHeight") / 3
    else
        return                          --unkown position
    end
    OpenFreshManGuide(nType, nTextID, fX, fY, "SceneMap", "northeast")
end

function SceneMap_Click_KVKScene()

end

function SceneMap_Show_OhterScene( parfilename, sceneID )
	--sceneMap_ComboList:ResetList() --看别的场景也要清理一下
	local sceneX, sceneY
	local filename = parfilename
	if Player:GetData("IsOriginalJD") == 1 then 
		if g_JDTS_ForbiddenSceneRes[sceneID] then
			return
		end
		if g_JDTS_SceneMapFile[filename] then
			filename = g_JDTS_SceneMapFile[filename]
		end
	end
	if Player:GetData("Is2606S") == 1 then 
		if g_2606S_ForbiddenSceneRes[sceneID] then
			return
		end
		if g_2606S_SceneMapFile[filename] then
			filename = g_2606S_SceneMapFile[filename]
		end
	end
	sceneX,sceneY = GetSceneSizeByID(sceneID)		--这都是当前场景的函数啊
	if (sceneID == GetSceneID()) then --如果点击的是本场景
		SceneMap_Board:SetSceneFileName( sceneX,sceneY,filename , 1)
	else
		SceneMap_Board:SetSceneFileName( sceneX,sceneY,filename , 0)
	end
	if sceneID == 242 then  --雪景洛阳- -
		sceneID = 0
	end
	g_DungeonsIndex = -1

	local scenename
	scenename = GetSceneNameByResID(tonumber(sceneID))
	SceneMap_SceneName:SetText("#gFF0FA0".. scenename )

	SceneMap_FixZoom(filename)

	g_CurSelectSceneID = sceneID --记录一下当前选择场景ID
	-- 如果非大场景，还需要重置其缩放模式
	local mode = SceneMap_Board:GetSceneZoomMode()
    if mode == 1 then  -- 1模式为512X512独有。。。擦
        local sceneX, sceneY = GetSceneSizeByID(sceneID)
        if sceneX < 512 and sceneY < 512 then
            -- 重置为像素比例模式
            SceneMap_Board:SetSceneZoomMode(2)
        end
    end

	CommanderFlag:SetSceneMapSelect(g_CurSelectSceneID)
	--是否是多层场景
	local tempDungeons = nil
	local tempIndex = nil
	for i = 1, table.getn(g_DungeonsTable) do
		for j = 1, table.getn(g_DungeonsTable[i].maplist) do
			if g_DungeonsTable[i].maplist[j].sceneId == sceneID then
				g_DungeonsIndex  = i
				tempIndex = j
				--sceneMap_ComboList:SetProperty("Disabled", "True")
				break
			end
		end
	end

	--
	if (g_DungeonsIndex ~= -1 and tempIndex ~= nil ) then
		sceneMap_ComboList:SetProperty("Visible", "True")
		sceneMap_ComboList:ResetList()
		for i = 1, table.getn(g_DungeonsTable[g_DungeonsIndex].maplist) do
			if  not (g_DungeonsIndex == 3 and  Player:GetData("Is2606S") == 1) or i ~= 5 then
				sceneMap_ComboList:ComboBoxAddItem(g_DungeonsTable[g_DungeonsIndex].maplist[i].name,i)
			end
		end
		sceneMap_ComboList:SetCurrentSelect(tempIndex-1)
	else
		sceneMap_ComboList:SetProperty("Visible", "False")
		sceneMap_ComboList:ComboBoxAddItem(scenename,1)
		sceneMap_ComboList:SetCurrentSelect(0)
		--sceneMap_ComboList:SetCurrentSelect(tempIndex-1)
	end

	if 	sceneID == 9 or sceneID == 10 or sceneID == 11 or sceneID == 12 or
		sceneID == 13 or sceneID == 14 or sceneID == 15 or sceneID == 16 or
		sceneID == 17 or sceneID == 284 or sceneID == 615 or sceneID == 678 or
		sceneID == 731 or sceneID == 824 or sceneID == 987 then

			g_MenPaiorZongMenSceneID = 0

			if g_ZongMen_ToolTip_List[sceneID] ~= nil then
				sceneMap_Zongmen:SetText(g_ZongMen_ToolTip_List[sceneID].ButtonText)
				sceneMap_Zongmen:SetToolTip(g_ZongMen_ToolTip_List[sceneID].ToolTip)
			end

			sceneMap_Zongmen:Show()
		else
			sceneMap_Zongmen:Hide()

	end

	this:Show()

	sceneMap_LargeMap:Show()
	sceneMap_back:Show()

	CommanderFlag:CommanderShow(g_CurSelectSceneID)
end

function SceneMap_Show_CurrentScene()
	local scenename,sceneID
	sceneID = GetSceneID()
	scenename = GetSceneMapByID(tonumber(sceneID))
	SceneMap_Text3:SetText("#{KCJXL_130417_1}")
	sceneMap_ComboList:ResetList()
	SceneMap_Show(tostring(scenename))
end


function SceneMap_ZongMenScene_Clicked()


	--0宗门 1门派
	if g_MenPaiorZongMenSceneID == 1 then

		if g_ZongMen_To_MenPai_List[g_CurSelectSceneID] == nil then
			return
		end

		local scenename = GetSceneMapByID(tonumber(g_ZongMen_To_MenPai_List[g_CurSelectSceneID]))

		SceneMap_Text3:SetText("#{KCJXL_130417_1}")
		sceneMap_ComboList:ResetList()
		g_MenPaiorZongMenSceneID = 0

		SceneMap_Show_OhterScene( tostring(scenename), tonumber(g_ZongMen_To_MenPai_List[g_CurSelectSceneID]))

	elseif g_MenPaiorZongMenSceneID == 0 then

		if g_MenPai_To_ZongMen_List[g_CurSelectSceneID] == nil then
			return
		end

		local scenename = GetSceneMapByID(tonumber(g_MenPai_To_ZongMen_List[g_CurSelectSceneID]))

		SceneMap_Text3:SetText("#{KCJXL_130417_1}")
		sceneMap_ComboList:ResetList()
		SceneMap_Show_OhterScene( tostring(scenename), tonumber(g_MenPai_To_ZongMen_List[g_CurSelectSceneID]))

		--从新设置按钮
		sceneMap_Zongmen:SetText("#{ZMCJ_230719_30}")
		sceneMap_Zongmen:SetToolTip("#{ZMCJ_230719_31}")
		sceneMap_Zongmen:Show()
		g_MenPaiorZongMenSceneID = 1
	end

end


function sceneMap_ComboList_Changed()	--地图下拉列表改变

	if g_SceneMapUsage ~= MapInfoList.SBG_HUMANINFO then

		if g_DungeonsIndex == -1 then
			return
		end

		local _, Index = sceneMap_ComboList:GetCurrentSelect()
		local sceneId = g_DungeonsTable[g_DungeonsIndex].maplist[Index].sceneId
		local mapname = GetSceneMapByID(tonumber(sceneId))
		if sceneId == nil then
			return		--不是分层场景，直接返回
		end

		SceneMap_Show_OhterScene( mapname , sceneId)
	else
		local _, Index = sceneMap_ComboList:GetCurrentSelect()
		SceneMap_SbgHumanInfo_Show(tonumber(g_SceneMapShenbingge[g_SceneMap_ShenbingLevel][Index].resid),g_SceneMap_ShenbingLevel,Index-1)
	end

end

function SceneMap_Frame_On_ResetPos()
	local curResolution = Variable:GetVariable( "View_Resoution" )
	local split = string.sub(curResolution, 4, 4)
	local curResolutionL
	if split == "," then
		curResolutionL = string.sub(curResolution, 1, 3)
	else
		curResolutionL = string.sub(curResolution, 1, 4)
	end

	local number = tonumber(curResolutionL)

	if SceneMap_IsBieYeMap() then
		SceneMap_fixJiayuan(number)
	end
	
	
	if number == nil or number <= 960 then
		SceneMap_Text3 : SetProperty("UnifiedXPosition", "{0.500000,-306.500000}")
	else
		SceneMap_Text3 : SetProperty("UnifiedXPosition", "{0.500000,-169.000000}")
	end
end

function SceneMap_ChangeButtonTip()
	if KVKInterface:IsInKVKServer() == 1 then

	else
		local noChatActiveMode = Variable:GetVariable("NonChatActive")
		if noChatActiveMode == "1" then
			sceneMap_LargeMap						:SetToolTip("#{JPYD_130822_17}")
		else
			sceneMap_LargeMap						:SetToolTip("#{DTQH_090305_4}")
		end
	end
end

function SceneMap_IsXRZPVPMap()
	if XRZPVP:IsInBattleScene() == 1 then
		return 1
	end

	return 0
end

function SceneMap_CheckEnterCommanderFlag(coordinatex, coordinatez)
	if IsWindowShow("WarMarker") then
		local isAdd = CommanderFlag:IsEnterAddFlag()
		if isAdd > 0 then

			local canAdd = CommanderFlag:IsCanAddCommanderFlag()
			if canAdd == 1 then
				PushEvent("COMMANDERFLAG_ADD", g_CurSelectSceneID, coordinatex, coordinatez)
			end

			CommanderFlag:LeaveAddFlag()
			return 1
		end
	end

	return 0
end