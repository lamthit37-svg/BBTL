--ValentineAlbum_Diary

local g_ValentineAlbum_Diary_Frame_UnifiedPosition

local g_BindPartnerName = ""
local g_Stage = 0
local g_EventData = 0
local g_EventIndex = 0

local g_LetterInfo = {
	[1] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter1", [2] ="#{QRJJN_221118_47}"}, --未完成、已完成
	[2] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter2", [2] ="#{QRJJN_221118_48}"},
	[3] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter3", [2] ="#{QRJJN_221118_49}"},
	[4] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter4", [2] ="#{QRJJN_221118_50}"},
	[5] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter5", [2] ="#{QRJJN_221118_51}"},
	[6] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter6", [2] ="#{QRJJN_221118_52}"},
	[7] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter7", [2] ="#{QRJJN_221118_53}"},
	[8] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter8", [2] ="#{QRJJN_221118_54}"},
	[9] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter9", [2] ="#{QRJJN_221118_55}"},
	[10] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter10", [2] ="#{QRJJN_221118_56}"},
	[11] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter11", [2] ="#{QRJJN_221118_57}"},
	[12] = {[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryLetter12", [2] ="#{QRJJN_221118_58}"},
}

local g_EventText = {
	[1] = "#{QRJJN_221118_61}",
	[2] = "#{QRJJN_221118_62}",
	[3] = "#{QRJJN_221118_63}",
	[4] = "#{QRJJN_221118_64}",
	[5] = "#{QRJJN_221118_65}",
	[6] = "#{QRJJN_221118_66}",
	[7] = "#{QRJJN_221118_67}",
	[8] = "#{QRJJN_221118_68}",
	[9] = "#{QRJJN_221118_69}",
	[10] = "#{QRJJN_221118_70}",
	[11] = "#{QRJJN_221118_71}",
	[12] = "#{QRJJN_221118_72}",
}

local g_EventImage = {
	[1] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary1",
	[2] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary2",
	[3] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary3",
	[4] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary4",
	[5] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary5",
	[6] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary6",
	[7] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary7",
	[8] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary8",
	[9] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary9",
	[10] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary10",
	[11] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary11",
	[12] = "set:ValentineAlbum1 image:ValentineAlbum_MemorialDiary12",
}

--标题
local g_TitleImage = {
	[1] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle1",
	[2] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle2",
	[3] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle3",
	[4] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle4",
	[5] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle5",
	[6] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle6",
	[7] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle7",
	[8] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle8",
	[9] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle9",
	[10] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle10",
	[11] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle11",
	[12] = "set:ValentineAlbum1 image:ValentineAlbum_DiaryTitle12",
}

function ValentineAlbum_Diary_PreLoad()
    this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function ValentineAlbum_Diary_OnLoad()


    g_ValentineAlbum_Diary_Frame_UnifiedPosition = ValentineAlbum_Diary_Frame:GetProperty("UnifiedPosition")

end

function ValentineAlbum_Diary_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		ValentineAlbum_Diary_Close()

	elseif (event == "ADJEST_UI_POS" ) then
		ValentineAlbum_Diary_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ValentineAlbum_Diary_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 99835604) then
		local operator = Get_XParam_INT( 0 )
		g_EventIndex = Get_XParam_INT( 1 )
		g_Stage = Get_XParam_INT( 2 )
		g_EventData = Get_XParam_INT( 3 )
		g_BindPartnerName = Get_XParam_STR(0)
		if operator == 1 then
			ValentineAlbum_Diary_Update()
		elseif operator == 2 then
			if this:IsVisible() then
				ValentineAlbum_Diary_Update()
			end
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 99835606 then
		local sceneId = Get_XParam_INT( 0 )
		local nPosX = Get_XParam_INT( 1 )
		local nPosZ = Get_XParam_INT( 2 )
		local NpcName = Get_XParam_STR( 0 )
		
		AutoRuntoTargetExWithName(nPosX, nPosZ, sceneId, NpcName)
		ValentineAlbum_Diary_Close()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 99835607) then --纪念册详情
		local operator = tonumber(arg1)
		g_EventIndex = tonumber(arg2)
		g_BindPartnerName = tostring(arg3)
		g_Stage = 4
		g_EventData = 1
		
		if operator == 1 then
			ValentineAlbum_Diary_Update()
		elseif operator == 2 then
			if this:IsVisible() then
				ValentineAlbum_Diary_Update()
			end
		end
	end
end

function ValentineAlbum_Diary_Update()
	if g_EventIndex < 1 or g_EventIndex > 12 then
		return
	end
	ValentineAlbum_Diary_LetterTitle:SetProperty("Image",g_TitleImage[g_EventIndex])
	--信件描述
	if g_EventData > 0 then --已完成
		ValentineAlbum_Diary_TaskStatus1:Hide()
		ValentineAlbum_Diary_TaskStatus2:Show()
		
		ValentineAlbum_MemorialDiary_Image:SetProperty("Image",g_EventImage[g_EventIndex])
		ValentineAlbum_MemorialDiary_Text:SetText(g_LetterInfo[g_EventIndex][2])
	else
		ValentineAlbum_Diary_TaskStatus1:Show()
		ValentineAlbum_Diary_TaskStatus2:Hide()
		
		ValentineAlbum_Diary_LetterInfo:SetProperty("Image",g_LetterInfo[g_EventIndex][1])
		ValentineAlbum_Diary_Task:SetText(g_EventText[g_EventIndex])
			--任务
		if g_Stage < math.floor((g_EventIndex-1)/3)+1 then --未解锁
			ValentineAlbum_Diary_TaskLocked:Show()
			ValentineAlbum_Diary_GotoBtn:Hide()
		else
			ValentineAlbum_Diary_TaskLocked:Hide()
			ValentineAlbum_Diary_GotoBtn:Show()
		end
	end
	
	this:Show()
end

function ValentineAlbum_Diary_GotoClicked()
	if g_EventIndex < 1 or g_EventIndex > 12 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GotoDoMission" )
		Set_XSCRIPT_ScriptID( 998356 )
		Set_XSCRIPT_Parameter( 0, g_EventIndex )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end


--关闭
function ValentineAlbum_Diary_Close()
	this:Hide()
end

function ValentineAlbum_Diary_On_ResetPos()
    ValentineAlbum_Diary_Frame:SetProperty("UnifiedPosition", g_ValentineAlbum_Diary_Frame_UnifiedPosition)
end


function ValentineAlbum_Diary_HelpClick()
	PushEvent("CCSHOP_HELP", 109)
end 
