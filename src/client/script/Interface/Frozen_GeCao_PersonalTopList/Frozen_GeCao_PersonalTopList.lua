-- bxjgecaolist


-- 保存UI默认位置
local Frozen_GeCao_PersonalTopList_Frame_UnifiedPosition = nil

local g_TeamNameStr = {
	[1] = "#{BXDR_20240920_214}",
	[2] = "#{BXDR_20240920_215}",
	[3] = "#{BXDR_20240920_216}",
	[4] = "#{BXDR_20240920_217}",
	[5] = "#{BXDR_20240920_218}",
}


local g_PlayerNumMax = 15

local g_KillPoints = 20
local g_LevelPoints = 5
local g_LevelBasePoints = 10
local g_DamagePoints = 0.2
local g_OccupyPoint = 10

local g_Rank = {
}

local g_TeamName = {
}

local g_TeamPoint = {
}

function Frozen_GeCao_PersonalTopList_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("BXJGECAO_SELFINFO")

end -- end func Frozen_GeCao_PersonalTopList_Frame_PreLoad()

function Frozen_GeCao_PersonalTopList_OnLoad()
    Frozen_GeCao_PersonalTopList_Frame_UnifiedPosition = Frozen_GeCao_PersonalTopList_Frame:GetProperty("UnifiedPosition")
	
	
	
end -- end func Frozen_GeCao_PersonalTopList_Frame_OnLoad()

function Frozen_GeCao_PersonalTopList_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        Frozen_GeCao_PersonalTopList_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Frozen_GeCao_PersonalTopList_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Frozen_GeCao_PersonalTopList_Frame_UnifiedPos()
	elseif event == "BXJGECAO_SELFINFO"  then	--服务端传数据
	
		
		
		Frozen_GeCao_PersonalTopList_Frame_Updata()
		
		this:Show()
	
	end
end -- end func Frozen_GeCao_PersonalTopList_Frame_OnEvent()

function Frozen_GeCao_PersonalTopList_Frame_Updata()


	local myGuid = Player:GetGUID()
   
    -- 获取阵营排行榜
    local listCount = 0
    local rankList = {}
    for i=1, g_PlayerNumMax, 1 do
        local ret, guid, camp, name, damage, gamelevel, kill = AskBJXGeCaoRankListInfo(i-1)
        if (ret > 0) then
            listCount = listCount + 1
            rankList[listCount] = {}
			rankList[listCount].guid = guid
			rankList[listCount].camp = camp
            rankList[listCount].name = name
            rankList[listCount].damage = damage
			if gamelevel <= 0 then
				gamelevel = 1
			end
            rankList[listCount].gamelevel = gamelevel    	
            rankList[listCount].kill = kill		
			rankList[listCount].score = kill*g_KillPoints + g_LevelPoints*(gamelevel-1) + math.floor(g_DamagePoints*damage) 
			if gamelevel > 1 then
				rankList[listCount].score = rankList[listCount].score + g_LevelBasePoints
			end
        end
    end -- end for
	

	for i = 1, listCount do
		for j = 1, listCount-i do
			local bIsExChange = 0
			if (rankList[j].score < rankList[j+1].score) then
				bIsExChange = 1
			elseif (rankList[j].score == rankList[j+1].score and rankList[j].kill < rankList[j+1].kill) then
				bIsExChange = 1
			elseif (rankList[j].score == rankList[j+1].score and rankList[j].kill == rankList[j+1].kill and rankList[j].gamelevel < rankList[j+1].gamelevel) then
				bIsExChange = 1
			elseif (rankList[j].score == rankList[j+1].score and rankList[j].kill == rankList[j+1].kill and rankList[j].gamelevel == rankList[j+1].gamelevel and rankList[j].damage < rankList[j+1].damage) then
				bIsExChange = 1
			end
			if bIsExChange == 1 then
				local tempguid = rankList[j].guid
				local tempname = rankList[j].name
				local tempscore = rankList[j].score
				local tempdamage = rankList[j].damage
				local tempcamp = rankList[j].camp
				local tempgamelevel = rankList[j].gamelevel
				local tempkill = rankList[j].kill
			
				
				rankList[j].guid = rankList[j+1].guid
				rankList[j].name = rankList[j+1].name
				rankList[j].score = rankList[j+1].score
				rankList[j].damage = rankList[j+1].damage
				rankList[j].kill = rankList[j+1].kill
				rankList[j].camp = rankList[j+1].camp
				rankList[j].gamelevel = rankList[j+1].gamelevel
				
				
				rankList[j+1].guid = tempguid
				rankList[j+1].name = tempname
				rankList[j+1].score = tempscore
				rankList[j+1].damage = tempdamage			
				rankList[j+1].kill = tempkill
				rankList[j+1].camp = tempcamp
				rankList[j+1].gamelevel = tempgamelevel
				
			end
		end	
	end
	
	local myRank = -1
	local myName = ""
	local myCamp = -1
	local myGameLevel = -1
	local myKill = -1
	local myDamage = -1
	local myScore = -1
	Frozen_GeCao_PersonalTopList_List:Clear()
	for i = 1, table.getn(rankList) do
		-- 添加排行榜表项
		local child = Frozen_GeCao_PersonalTopList_List:AddChild("Frozen_GeCao_PersonalTopList_AItem1")
		if (child ~= nil ) then	
			child:GetSubItem("Frozen_GeCao_PersonalTopList_AItem1_Rank"):SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",i)) 	
			child:GetSubItem("Frozen_GeCao_PersonalTopList_AItem1_Name"):SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",rankList[i].name)) 	
			child:GetSubItem("Frozen_GeCao_PersonalTopList_AItem1_Team"):SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",g_TeamNameStr[rankList[i].camp+1])) 	
			local nSbScore = (rankList[i].gamelevel-1)*g_LevelPoints
			if rankList[i].gamelevel > 1 then
				nSbScore = nSbScore +g_LevelBasePoints
			end
			child:GetSubItem("Frozen_GeCao_PersonalTopList_AItem1_LevelScore"):SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",nSbScore) 	)
			child:GetSubItem("Frozen_GeCao_PersonalTopList_AItem1_KillNUM"):SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",rankList[i].kill)) 	
			child:GetSubItem("Frozen_GeCao_PersonalTopList_AItem1_HurtScore"):SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",math.floor(rankList[i].damage*g_DamagePoints))) 	
			child:GetSubItem("Frozen_GeCao_PersonalTopList_AItem1_AllScore"):SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",rankList[i].score)) 	
		end
		if rankList[i].guid == myGuid then
			myRank = i
			myName = rankList[i].name
			myCamp = rankList[i].camp
			myGameLevel = rankList[i].gamelevel
			myKill = rankList[i].kill
			myDamage = rankList[i].damage
			myScore = rankList[i].score
		end
	end
	
	Frozen_GeCao_PersonalTopList_My_Rank:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",myRank))
	Frozen_GeCao_PersonalTopList_My_Name:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",myName))
	Frozen_GeCao_PersonalTopList_My_Team:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",g_TeamNameStr[myCamp+1]))
	local nSSbScore = (myGameLevel-1)*g_LevelPoints
	if myGameLevel > 1 then
		nSSbScore = nSSbScore +g_LevelBasePoints
	end
	Frozen_GeCao_PersonalTopList_My__LevelScore:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",nSSbScore))
	Frozen_GeCao_PersonalTopList_My_KillNUM:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",myKill))
	Frozen_GeCao_PersonalTopList_My_HurtScore:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",math.floor(myDamage*g_DamagePoints)))
	Frozen_GeCao_PersonalTopList_My_AllScore:SetText(ScriptGlobal_Format("#{BXDR_20240920_25}",myScore))
	
	
end -- end func Frozen_GeCao_PersonalTopList_Frame_Updata()


-- 界面默认位置
function Frozen_GeCao_PersonalTopList_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (Frozen_GeCao_PersonalTopList_Frame_UnifiedPosition ~= nil) then
            Frozen_GeCao_PersonalTopList_Frame:SetProperty("UnifiedPosition", Frozen_GeCao_PersonalTopList_Frame_UnifiedPosition)
        end
    end
end -- end func Frozen_GeCao_PersonalTopList_Frame_UnifiedPos()

function Frozen_GeCao_PersonalTopList_Frame_Hide()
    this:Hide()
end -- end func Frozen_GeCao_PersonalTopList_Frame_Hide()

-- 关闭按钮点击事件
function Frozen_GeCao_PersonalTopList_Frame_Close_Clicked()
	Frozen_GeCao_PersonalTopList_Frame_Hide()
end  -- end func Frozen_GeCao_PersonalTopList_Frame_Close_Clicked()

function Frozen_GeCao_PersonalTopList_Help_Clicked()
    PushEvent("CCSHOP_HELP", 228)
end -- end func Frozen_GeCao_PersonalTopList_Frame_Help()

