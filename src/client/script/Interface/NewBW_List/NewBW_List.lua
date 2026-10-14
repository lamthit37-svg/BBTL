-- NewBW_List

local MAX_OBJ_DISTANCE = 3.0;
local g_NewBW_List_UnifiedPosition = nil
local g_NPC_ID = -1;
local objCared = -1
local g_season_count = 0;
local g_tab_lastselect = 0
local g_level_lastselect = 0

local NewBW_List_season_Button = {}
local NewBW_List_level_Button = {}
local NewBW_List_member_name = {}
local NewBW_List_member_menpai = {}
local NewBW_List_member_level = {}
local NewBW_List_member_server = {}
local NewBW_List_member_team = {}

local g_NewBWPic = {
												"set:BW_Match21 image:NewBW_Top3",
												"set:BW_Match21 image:NewBW_Top2",
												"set:BW_Match21 image:NewBW_Top1",
												"set:BW_Match21 image:NewBW_Top4",
											
											}
											
local g_NewBWName = {
	[1] = {"#{SJPM_241125_54}", "#{SJPM_241125_53}", "#{SJPM_241125_52}", ""},
	[2] = {"#{SJPM_241125_88}", "#{SJPM_241125_87}", "#{SJPM_241125_86}", ""},
	[3] = {"#{SJPM_241125_91}", "#{SJPM_241125_90}", "#{SJPM_241125_89}", ""},
	[4] = {"#{SJPM_241125_94}", "#{SJPM_241125_93}", "#{SJPM_241125_92}", ""},
	[5] = {"#{SJPM_241125_100}", "#{SJPM_241125_99}", "#{SJPM_241125_98}", "#{SJPM_241125_109}"},
	[6] = {"#{SJPM_241125_104}", "#{SJPM_241125_103}", "#{SJPM_241125_102}", "#{SJPM_241125_101}"},
	[7] = {"#{SJPM_241125_108}", "#{SJPM_241125_107}", "#{SJPM_241125_106}", "#{SJPM_241125_105}"},
	[8] = {"", "", "", ""},
}
local NewBW_List_MenPaiName =
{
	[0] = "#{XQ_MP_1}",    	--少林
	[1] = "#{XQ_MP_2}",    	--明教
	[2] = "#{XQ_MP_3}",    	--丐帮
	[3] = "#{XQ_MP_4}",    	--武当
	[4] = "#{XQ_MP_5}",    	--峨眉
	[5] = "#{XQ_MP_6}",    	--星宿
	[6] = "#{XQ_MP_7}",    	--天龙
	[7] = "#{XQ_MP_8}",    	--天山
	[8] = "#{XQ_MP_9}",    	--逍遥
	[9] = "无门派",	--无门派
	[10] = "#{XQ_MP_10}",		
	[11] = "#{XQ_MP_13}",	
	[12] = "#{XMPGG_160524_02}",	
	[13] = "#{SCGZ_180816_119}",	
	[14] = "#{XMPHM_210604_01}",	
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}",		--恶人谷
} 

--===============================================
-- PreLoad()
--===============================================
function NewBW_List_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	
end

--===============================================
-- OnLoad()
--===============================================
function NewBW_List_OnLoad()

	NewBW_List_season_Button[1] = NewBW_List_Frame_Button1
	NewBW_List_season_Button[2] = NewBW_List_Frame_Button2
	NewBW_List_season_Button[3] = NewBW_List_Frame_Button3
	NewBW_List_season_Button[4] = NewBW_List_Frame_Button4
	NewBW_List_season_Button[5] = NewBW_List_Frame_Button5
	NewBW_List_season_Button[6] = NewBW_List_Frame_Button6
	NewBW_List_season_Button[7] = NewBW_List_Frame_Button7
	NewBW_List_season_Button[8] = NewBW_List_Frame_Button8
	
	NewBW_List_level_Button[1] = NewBW_List_CheckBox_Buttontab01
	NewBW_List_level_Button[2] = NewBW_List_CheckBox_Buttontab02
	NewBW_List_level_Button[3] = NewBW_List_CheckBox_Buttontab03
	NewBW_List_level_Button[4] = NewBW_List_CheckBox_Buttontab04
	
	for i = 1, 6 do
		NewBW_List_member_name[i] = _G["NewBW_List_List"..i.."_1"]
		NewBW_List_member_menpai[i] = _G["NewBW_List_List"..i.."_2"]
		NewBW_List_member_level[i] = _G["NewBW_List_List"..i.."_3"]
		NewBW_List_member_server[i] = _G["NewBW_List_List"..i.."_4"]
		NewBW_List_member_team[i] = _G["NewBW_List_List"..i.."_5"]
	end
	g_NewBW_List_UnifiedPosition = NewBW_List_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function NewBW_List_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 89289703) then
		g_NPC_ID = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(g_NPC_ID);
		BeginCareObject_NewBW_List(objCared)
		NewBW_List_ResetUIInfo()
		this:Show()
		local select_season = Get_XParam_INT(1);
		NewBW_List_ChangeTbl(select_season)

		
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
				--取消关心
			NewBW_List_Cancel_Clicked()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        NewBW_List_ResetPos()
    elseif (event == "ADJEST_UI_POS") then
        NewBW_List_ResetPos()
	end
	
end

function BeginCareObject_NewBW_List(objCaredId)
	this:CareObject(objCaredId, 1, "NewBW_List");
end

function NewBW_List_ResetUIInfo()
	local islongmen = 0
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
	if selfZoneWorldID == 9031 or selfZoneWorldID == 9015 then
		islongmen = 1
	end
	
	g_season_count = 0
	for i = 1, table.getn(NewBW_List_season_Button) do
		local tabData = NewXBW:GetXbwHonourWallInfo(i, 0, islongmen)
		if tabData ~= nil then
			NewBW_List_season_Button[i]:Show()
			g_season_count = g_season_count + 1
		else
			NewBW_List_season_Button[i]:Hide()
		end
	end
end

function NewBW_List_ChangeTbl(selectIdx)
	if g_season_count < 1 then
		return
	end
	
    for i = 1, g_season_count do
        if i == selectIdx then
            NewBW_List_season_Button[i]:SetCheck(1)
        else
            NewBW_List_season_Button[i]:SetCheck(0)
        end
    end

    g_tab_lastselect = selectIdx
	
	if g_tab_lastselect > 4 then
		NewBW_List_CheckBox_Buttontab04:Show()
	else
		NewBW_List_CheckBox_Buttontab04:Hide()
	end
	NewBW_List_ChangeTopList(1)
end

function NewBW_List_ChangeTopList(index)
	NewBW_List_CheckBox_Buttontab01:SetCheck(0)
	NewBW_List_CheckBox_Buttontab02:SetCheck(0)
	NewBW_List_CheckBox_Buttontab03:SetCheck(0)
	NewBW_List_CheckBox_Buttontab04:SetCheck(0)
	
	if index >= 1 and index <= 4 then
		NewBW_List_level_Button[index]:SetCheck(1)
		g_level_lastselect = index	
		
		NewBW_List_UpdateList()			
	end
	
end
--===============================================
-- Cancel_Clicked
--===============================================
function NewBW_List_UpdateList()
	if g_tab_lastselect <= 0 then
		return
	end
	
	if g_level_lastselect > 4 or g_level_lastselect < 1 then
		return
	end
	for i = 1, 6 do
		NewBW_List_member_name[i]:SetText("")
		NewBW_List_member_menpai[i]:SetText("")
		NewBW_List_member_level[i]:SetText("")
		NewBW_List_member_server[i]:SetText("")
		NewBW_List_member_team[i]:SetText("")
	end
	
	NewBW_List_Frame_Info_Tu : SetProperty("Image", g_NewBWPic[g_level_lastselect])	--选择不同图片
	NewBW_List_Frame_ContentListName : SetText(g_NewBWName[g_tab_lastselect][g_level_lastselect])
	
	local islongmen = 0
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID();
	if selfZoneWorldID == 9031 or selfZoneWorldID == 9015 then
		islongmen = 1
	end
   local tabData = NewXBW:GetXbwHonourWallInfo(g_tab_lastselect, g_level_lastselect-1, islongmen)
    for i = 1, 6 do
        local data = tabData[i]
        if data ~= nil and type(data) == "table" then
			NewBW_List_member_name[i]:SetText(data.name)
			if NewBW_List_MenPaiName[data.menpai] ~= nil then
				NewBW_List_member_menpai[i]:SetText(NewBW_List_MenPaiName[data.menpai])
			end
			NewBW_List_member_level[i]:SetText(data.level)
			local serverName = DataPool:GetServerName( data.world )
			NewBW_List_member_server[i]:SetText(serverName)
			NewBW_List_member_team[i]:SetText(data.teamname)      
        end
    end
	
	return;
end

function NewBW_List_ResetPos()
	NewBW_List_Frame:SetProperty("UnifiedPosition",g_NewBW_List_UnifiedPosition)
end

--===============================================
-- Close()
--===============================================
function NewBW_List_Close()

	return this:Hide()
end

function NewBW_List_OnHiden()
		return this:Hide()
end



--帮助
function NewBW_List_Help_Clicked()
end