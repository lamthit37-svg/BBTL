-- 排行榜界面

-- 保存UI默认位置
local Chengzhan_BangHui_TopList_UnifiedPosition = nil

local g_menpaistr = {
  [0] = "#{BZTX_250811_30}",
  [1] = "#{BZTX_250811_31}",
  [2] = "#{BZTX_250811_32}",
  [3] = "#{BZTX_250811_33}",
  [4] = "#{BZTX_250811_34}",
  [5] = "#{BZTX_250811_35}",
  [6] = "#{BZTX_250811_36}",
  [7] = "#{BZTX_250811_37}",
  [8] = "#{BZTX_250811_38}",
  [9] = "",
  [10] = "#{BZTX_250811_39}",
  [11] = "#{BZTX_250811_40}",
  [12] = "#{BZTX_250811_41}",
  [13] = "#{BZTX_250811_42}",
  [14] = "#{BZTX_250811_43}",
  [15] = "#{BZTX_250811_44}",
}


function Chengzhan_BangHui_TopList_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("TCITYWAR_UPDATA_RANKLIST")
end -- end func Chengzhan_BangHui_TopList_PreLoad()

function Chengzhan_BangHui_TopList_OnLoad()
    Chengzhan_BangHui_TopList_UnifiedPosition = Chengzhan_BangHui_TopList_Frame:GetProperty("UnifiedPosition")	
	

end -- end func Chengzhan_BangHui_TopList_OnLoad()

function Chengzhan_BangHui_TopList_OnEvent(event)
    if (event == "TCITYWAR_UPDATA_RANKLIST") then
		local nRankPeopleNum = tonumber( arg0 )
		local nMyRank = tonumber( arg1 )
		Chengzhan_BangHui_TopList_UpdateRankList(nRankPeopleNum, nMyRank)
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		
			Chengzhan_BangHui_TopList_Hide()

    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Chengzhan_BangHui_TopList_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Chengzhan_BangHui_TopList_UnifiedPos()
	
    end
end -- end func Chengzhan_BangHui_TopList_OnEvent()

-- 界面默认位置
function Chengzhan_BangHui_TopList_UnifiedPos()
    if (this:IsVisible()) then
        if (Chengzhan_BangHui_TopList_UnifiedPosition ~= nil) then
            Chengzhan_BangHui_TopList_Frame:SetProperty("UnifiedPosition", Chengzhan_BangHui_TopList_UnifiedPosition)
        end
    end
end -- end func Chengzhan_BangHui_TopList_UnifiedPos()

function Chengzhan_BangHui_TopList_Show()
    if (not this:IsVisible()) then
        this:Show()
    end
end -- end func Chengzhan_BangHui_TopList_Show()

function Chengzhan_BangHui_TopList_Hide()
    this:Hide()
end -- end func Chengzhan_BangHui_TopList_Hide()

-- 关闭按钮点击事件
function Chengzhan_BangHui_TopList_OnClose()
    Chengzhan_BangHui_TopList_Hide()
end  -- end func Chengzhan_BangHui_TopList_Close_Clicked()




-- 刷新排行榜
function Chengzhan_BangHui_TopList_UpdateRankList(nRankPeopleNum, nMyRank)
 
	

    -- 更新排行榜
    Chengzhan_BangHui_TopList_ListInfo:Clear()
	local nRankList = {}
	local nIndex = 1
	
	local nAllScore = 0
	local nAllKill = 0
	
	Chengzhan_BangHui_TopList_MyAItemText1:SetText("未上榜")
	Chengzhan_BangHui_TopList_MyAItemText2:SetText(Player:GetName())
	Chengzhan_BangHui_TopList_MyAItemText3:SetText(Player:GetLevel())
	if g_menpaistr[Player:GetData("MEMPAI")] ~= nil then
		Chengzhan_BangHui_TopList_MyAItemText4:SetText(g_menpaistr[Player:GetData("MEMPAI")])
	end
	Chengzhan_BangHui_TopList_MyAItemText5:SetText(0)
	Chengzhan_BangHui_TopList_MyAItemText6:SetText(0)
	Chengzhan_BangHui_TopList_MyAItemText7:SetText(0)
	Chengzhan_BangHui_TopList_MyAItemText8:SetText(0)
	Chengzhan_BangHui_TopList_MyAItemText9:SetText(0)
	Chengzhan_BangHui_TopList_MyAItemText10:SetText(0)
	
	--服务器不会返回rank==0的数据 rank==0是默认值
	for i=1, nRankPeopleNum do
		local IsValid, m_nRank, m_szName, m_nMenPai, m_nCityWarDamageNum, m_nCityWarKillNum, m_nCityWarCureNum, m_nCityWarAffordDamageNum, m_nCityWarDefendDamageNum, m_nCityWarRankScore, m_nLevel= TCWL:GetGuildRankListData(i-1)
		if IsValid == 1 then	
			nRankList[nIndex] = {}
			nRankList[nIndex].m_nRank = m_nRank
			nRankList[nIndex].m_szName = m_szName
			nRankList[nIndex].m_nMenPai = m_nMenPai
			nRankList[nIndex].m_nCityWarDamageNum = m_nCityWarDamageNum
			nRankList[nIndex].m_nCityWarKillNum = m_nCityWarKillNum
			nRankList[nIndex].m_nCityWarCureNum = m_nCityWarCureNum
			nRankList[nIndex].m_nCityWarAffordDamageNum = m_nCityWarAffordDamageNum
			nRankList[nIndex].m_nCityWarDefendDamageNum = m_nCityWarDefendDamageNum
			nRankList[nIndex].m_nCityWarRankScore = m_nCityWarRankScore
			nRankList[nIndex].m_nLevel = m_nLevel
			nIndex = nIndex + 1
			nAllKill = nAllKill + m_nCityWarKillNum
		end
	end
	
	for i = 1, table.getn(nRankList) do
		for j = 1, table.getn(nRankList)-i do
			local bIsExChange = 0
			if (nRankList[j].m_nRank > nRankList[j+1].m_nRank) then
				bIsExChange = 1
			end
			if bIsExChange == 1 then
				local temprank = nRankList[j].m_nRank
				local tempname = nRankList[j].m_szName
				local tempmenpai = nRankList[j].m_nMenPai
				local tempdamage = nRankList[j].m_nCityWarDamageNum
				local tempkill = nRankList[j].m_nCityWarKillNum
				local tempcure = nRankList[j].m_nCityWarCureNum
				local tempdamageafford = nRankList[j].m_nCityWarAffordDamageNum
				local tempdamagedefend = nRankList[j].m_nCityWarDefendDamageNum
				local tempscore = nRankList[j].m_nCityWarRankScore
				local templevel = nRankList[j].m_nLevel
				
				
				nRankList[j].m_nRank = nRankList[j+1].m_nRank
				nRankList[j].m_szName = nRankList[j+1].m_szName
				nRankList[j].m_nMenPai = nRankList[j+1].m_nMenPai
				nRankList[j].m_nCityWarDamageNum = nRankList[j+1].m_nCityWarDamageNum
				nRankList[j].m_nCityWarKillNum = nRankList[j+1].m_nCityWarKillNum
				nRankList[j].m_nCityWarCureNum = nRankList[j+1].m_nCityWarCureNum
				nRankList[j].m_nCityWarAffordDamageNum = nRankList[j+1].m_nCityWarAffordDamageNum
				nRankList[j].m_nCityWarDefendDamageNum = nRankList[j+1].m_nCityWarDefendDamageNum
				nRankList[j].m_nCityWarRankScore = nRankList[j+1].m_nCityWarRankScore
				nRankList[j].m_nLevel = nRankList[j+1].m_nLevel
			
				
				nRankList[j+1].m_nRank = temprank
				nRankList[j+1].m_szName = tempname
				nRankList[j+1].m_nMenPai = tempmenpai
				nRankList[j+1].m_nCityWarDamageNum = tempdamage
				nRankList[j+1].m_nCityWarKillNum = tempkill
				nRankList[j+1].m_nCityWarCureNum = tempcure
				nRankList[j+1].m_nCityWarAffordDamageNum = tempdamageafford
				nRankList[j+1].m_nCityWarDefendDamageNum = tempdamagedefend
				nRankList[j+1].m_nCityWarRankScore = tempscore
				nRankList[j+1].m_nLevel = templevel
				
			end
		end	
	end
	
	for i=1, table.getn(nRankList) do
		--只显示前20 和1000分以上的
		if i > 20 or nRankList[i].m_nCityWarRankScore < 1000 then
			break
		end
		-- 添加排行榜表项
		local child = Chengzhan_BangHui_TopList_ListInfo:AddChild("Chengzhan_BangHui_TopList_AItem")
		if (child ~= nil ) then	
			
			child:GetSubItem("Chengzhan_BangHui_TopList_AItemText1"):SetText(nRankList[i].m_nRank) 
			child:GetSubItem("Chengzhan_BangHui_TopList_AItemText2"):SetText(nRankList[i].m_szName)
			child:GetSubItem("Chengzhan_BangHui_TopList_AItemText3"):SetText(nRankList[i].m_nLevel)
			if g_menpaistr[nRankList[i].m_nMenPai] ~= nil then
				child:GetSubItem("Chengzhan_BangHui_TopList_AItemText4"):SetText(g_menpaistr[nRankList[i].m_nMenPai])
			end
			child:GetSubItem("Chengzhan_BangHui_TopList_AItemText5"):SetText(nRankList[i].m_nCityWarKillNum)
			child:GetSubItem("Chengzhan_BangHui_TopList_AItemText6"):SetText(nRankList[i].m_nCityWarDamageNum)
			child:GetSubItem("Chengzhan_BangHui_TopList_AItemText7"):SetText(nRankList[i].m_nCityWarCureNum)
			child:GetSubItem("Chengzhan_BangHui_TopList_AItemText8"):SetText(nRankList[i].m_nCityWarAffordDamageNum)
			child:GetSubItem("Chengzhan_BangHui_TopList_AItemText9"):SetText(nRankList[i].m_nCityWarDefendDamageNum)			
			child:GetSubItem("Chengzhan_BangHui_TopList_AItemText10"):SetText(nRankList[i].m_nCityWarRankScore)			
		end
		nAllScore = nAllScore + nRankList[i].m_nCityWarRankScore
		if nRankList[i].m_nRank == nMyRank then
			Chengzhan_BangHui_TopList_MyAItemText1:SetText(nRankList[i].m_nRank)
			Chengzhan_BangHui_TopList_MyAItemText2:SetText(nRankList[i].m_szName)
			Chengzhan_BangHui_TopList_MyAItemText3:SetText(nRankList[i].m_nLevel)
			if g_menpaistr[nRankList[i].m_nMenPai] ~= nil then
				Chengzhan_BangHui_TopList_MyAItemText4:SetText(g_menpaistr[nRankList[i].m_nMenPai])
			end
			Chengzhan_BangHui_TopList_MyAItemText5:SetText(nRankList[i].m_nCityWarKillNum)
			Chengzhan_BangHui_TopList_MyAItemText6:SetText(nRankList[i].m_nCityWarDamageNum)
			Chengzhan_BangHui_TopList_MyAItemText7:SetText(nRankList[i].m_nCityWarCureNum)
			Chengzhan_BangHui_TopList_MyAItemText8:SetText(nRankList[i].m_nCityWarAffordDamageNum)
			Chengzhan_BangHui_TopList_MyAItemText9:SetText(nRankList[i].m_nCityWarDefendDamageNum)
			Chengzhan_BangHui_TopList_MyAItemText10:SetText(nRankList[i].m_nCityWarRankScore)
		end
			

    end
	
	
	local selfIndex = 0
	for i=1, table.getn(nRankList) do
		if nRankList[i].m_nRank == nMyRank then
			selfIndex = i
		end
	end
	if selfIndex ~= 0 then
		if nMyRank > 20 or nRankList[selfIndex].m_nCityWarRankScore < 1000 then
			Chengzhan_BangHui_TopList_MyAItemText1:SetText("未上榜")
			Chengzhan_BangHui_TopList_MyAItemText2:SetText(Player:GetName())
			Chengzhan_BangHui_TopList_MyAItemText3:SetText(Player:GetLevel())
			if g_menpaistr[Player:GetData("MEMPAI")] ~= nil then
				Chengzhan_BangHui_TopList_MyAItemText4:SetText(g_menpaistr[Player:GetData("MEMPAI")])
			end
			Chengzhan_BangHui_TopList_MyAItemText5:SetText(nRankList[selfIndex].m_nCityWarKillNum)
			Chengzhan_BangHui_TopList_MyAItemText6:SetText(nRankList[selfIndex].m_nCityWarDamageNum)
			Chengzhan_BangHui_TopList_MyAItemText7:SetText(nRankList[selfIndex].m_nCityWarCureNum)
			Chengzhan_BangHui_TopList_MyAItemText8:SetText(nRankList[selfIndex].m_nCityWarAffordDamageNum)
			Chengzhan_BangHui_TopList_MyAItemText9:SetText(nRankList[selfIndex].m_nCityWarDefendDamageNum)
			Chengzhan_BangHui_TopList_MyAItemText10:SetText(nRankList[selfIndex].m_nCityWarRankScore)
		end
	end
	
	Chengzhan_BangHui_TopList_GXInfo:SetText(ScriptGlobal_Format("#{BZTX_260602_10}",nAllKill)) 
	Chengzhan_BangHui_TopList_Show()
    
end -- end func Chengzhan_BangHui_TopList_UpdateRankList()

function Chengzhan_BangHui_TopList_Help_Clicked()
    --PushEvent("CCSHOP_HELP", 206)
end -- end func CampPVP2023_Progress_Help()


function Chengzhan_BangHui_TopList_Close()
	Chengzhan_BangHui_TopList_Hide()
end