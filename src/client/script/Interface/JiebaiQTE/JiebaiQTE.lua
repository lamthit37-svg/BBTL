
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition
local g_ShowUI = 0

local g_MusicSkillImageCtrl = {}
local g_MusicSkillAnimateCtrl = {}
local g_MusicSkillImage = {

	[ 1 ] = { off = "set:ValentinePoem2 image:Jiebai_Gong_Hover" , on ="set:ValentinePoem2 image:Jiebai_Gong_Normal" },
	[ 2 ] = { off = "set:ValentinePoem2 image:Jiebai_Shang_Hover" , on ="set:ValentinePoem2 image:Jiebai_Shang_Normal" },
	[ 3 ] = { off = "set:ValentinePoem2 image:Jiebai_Jue_Hover" , on ="set:ValentinePoem2 image:Jiebai_Jue_Normal" },
	[ 4 ] = { off = "set:ValentinePoem2 image:Jiebai_Zhi_Hover" , on ="set:ValentinePoem2 image:Jiebai_Zhi_Normal" },
	[ 5 ] = { off = "set:ValentinePoem2 image:Jiebai_Yu_Hover" , on ="set:ValentinePoem2 image:Jiebai_Yu_Normal" },

}

function JiebaiQTE_PreLoad()
	
	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("CLOSE_DUNGEON_SWEAR_QTE")
	
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("UPDATE_DUNGEON_SWEAR_QTE")
	
end

function JiebaiQTE_OnLoad()
	
	g_MusicSkillImageCtrl[ 1 ] = JiebaiQTE_Word1_Image
	g_MusicSkillImageCtrl[ 2 ] = JiebaiQTE_Word2_Image
	g_MusicSkillImageCtrl[ 3 ] = JiebaiQTE_Word3_Image
	g_MusicSkillImageCtrl[ 4 ] = JiebaiQTE_Word4_Image
	g_MusicSkillImageCtrl[ 5 ] = JiebaiQTE_Word5_Image
	
	g_MusicSkillAnimateCtrl[ 1 ] = JiebaiQTE_Word1_AnimateImage
	g_MusicSkillAnimateCtrl[ 2 ] = JiebaiQTE_Word2_AnimateImage
	g_MusicSkillAnimateCtrl[ 3 ] = JiebaiQTE_Word3_AnimateImage
	g_MusicSkillAnimateCtrl[ 4 ] = JiebaiQTE_Word4_AnimateImage
	g_MusicSkillAnimateCtrl[ 5 ] = JiebaiQTE_Word5_AnimateImage
	
	
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= JiebaiQTE_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= JiebaiQTE_Frame:GetProperty("UnifiedYPosition")
end

function JiebaiQTE_OnEvent(event)
	
	if( event == "ADJEST_UI_POS" ) then
		JiebaiQTE_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		JiebaiQTE_ResetPos()
	--elseif( event == "HIDE_ON_SCENE_TRANSED" ) then

	elseif( event == "CLOSE_DUNGEON_SWEAR_QTE" ) then
		this:Hide()
	elseif( event == "UPDATE_DUNGEON_SWEAR_QTE" ) then
		this:Show()
		JiebaiQTE_Explain:SetText(tostring(arg6))
		JiebaiQTE_Update(tonumber(arg0) , tonumber(arg1) , tonumber(arg2) , tonumber(arg3) , tonumber(arg4) , tonumber(arg5))
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20150512 ) then
		g_ShowUI = 1
	end
end

function JiebaiQTE_Update( cNote  , note_1 , note_2 , note_3 , note_4 , note_5 )
	
	local  note = {}
	note[ 1 ] = note_1
	note[ 2 ] = note_2
	note[ 3 ] = note_3
	note[ 4 ] = note_4
	note[ 5 ] = note_5
	
	for i = 1 , 5 do
		
		if g_MusicSkillImage[ note[ i ] ] ~= nil then
			if i < cNote then
				g_MusicSkillImageCtrl[ i ] : SetProperty("Image"  ,g_MusicSkillImage[ note[ i ] ].on  )
			else
				g_MusicSkillImageCtrl[ i ] : SetProperty("Image"  ,g_MusicSkillImage[ note[ i ] ].off  )
			end
			
			g_MusicSkillAnimateCtrl[ i ]:Hide()
			g_MusicSkillAnimateCtrl[ i ]:Play(false)	
		end

	end
	
	if cNote >= 1 and cNote <= 5 then
	
		g_MusicSkillAnimateCtrl[ cNote ]:Show()
		g_MusicSkillAnimateCtrl[ cNote ]:Play(true)

	end

end

function JiebaiQTE_Reset()


end
--================================================
-- 恢复界面的默认相对位置
--================================================
function JiebaiQTE_ResetPos()
	JiebaiQTE_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition)
	JiebaiQTE_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition)
end

