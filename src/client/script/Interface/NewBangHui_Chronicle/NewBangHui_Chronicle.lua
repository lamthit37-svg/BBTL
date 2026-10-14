local g_NewBangHui_Chronicle_Frame_UnifiedPosition;   
local g_TimeClick = 0;
local g_PageIndex = 0;
local g_PageCount = 0;

local g_NewBanHui_ChronicCtl ={
}
local g_NewBanHui_ChronicText ={
}

local g_PageMaxCount = 10;

function NewBangHui_Chronicle_PreLoad() 

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	this:RegisterEvent("GUILD_SHOW_GUILDBATTLEHIS")  
	this:RegisterEvent("GUILD_OPEN_GUILDBATTLEHIS ")  
end

function NewBangHui_Chronicle_OnLoad()

	 
	g_NewBanHui_ChronicCtl = {	
									Chronicle_GotoEditBox						= NewBangHui_Chronicle_Bottom_GotoEditBox,
									Chronicle_CurrentlyPage					= NewBangHui_Chronicle_Bottom_CurrentlyPage,
									Chronicle_Bottom_GotoButton 		= NewBangHui_Chronicle_Bottom_GotoButton,
									Chronicle_Bottom_FirstPage 			= NewBangHui_Chronicle_Bottom_FirstPage,
									Chronicle_Bottom_UpPage 				= NewBangHui_Chronicle_Bottom_UpPage,
									Chronicle_Bottom_DownPage 			= NewBangHui_Chronicle_Bottom_DownPage,
									Chronicle_Bottom_LastPage 			= NewBangHui_Chronicle_Bottom_LastPage,
									Chronicle_Frame_His   					= NewBangHui_Chronicle_Frame1_Right,
									
	};
	
	g_NewBanHui_ChronicText[1] 	= NewBangHui_Chronicle_Frame1_Text1       
	g_NewBanHui_ChronicText[2] 	= NewBangHui_Chronicle_Frame1_Text2       
	g_NewBanHui_ChronicText[3] 	= NewBangHui_Chronicle_Frame1_Text3       
	g_NewBanHui_ChronicText[4] 	= NewBangHui_Chronicle_Frame1_Text4       
	g_NewBanHui_ChronicText[5] 	= NewBangHui_Chronicle_Frame1_Text5       
	g_NewBanHui_ChronicText[6] 	= NewBangHui_Chronicle_Frame1_Text6       
	g_NewBanHui_ChronicText[7] 	= NewBangHui_Chronicle_Frame1_Text7       
	g_NewBanHui_ChronicText[8] 	= NewBangHui_Chronicle_Frame1_Text8       
	g_NewBanHui_ChronicText[9]	= NewBangHui_Chronicle_Frame1_Text9      
	g_NewBanHui_ChronicText[10] = NewBangHui_Chronicle_Frame1_Text10    
	g_NewBanHui_ChronicText[11] = NewBangHui_Chronicle_Frame1_Text11   
	g_NewBanHui_ChronicText[12] = NewBangHui_Chronicle_Frame1_Text12   
	g_NewBanHui_ChronicText[13] = NewBangHui_Chronicle_Frame1_Text13   
	g_NewBanHui_ChronicText[14] = NewBangHui_Chronicle_Frame1_Text14     
	g_NewBanHui_ChronicText[15] = NewBangHui_Chronicle_Frame1_Text15   
	g_NewBanHui_ChronicText[16] = NewBangHui_Chronicle_Frame1_Text16   
	g_NewBanHui_ChronicText[17] = NewBangHui_Chronicle_Frame1_Text17   
	g_NewBanHui_ChronicText[18] = NewBangHui_Chronicle_Frame1_Text18   
	g_NewBanHui_ChronicText[19] = NewBangHui_Chronicle_Frame1_Text19   
	g_NewBanHui_ChronicText[20] = NewBangHui_Chronicle_Frame1_Text20
	
	g_NewBangHui_Chronicle_Frame_UnifiedPosition = NewBangHui_Chronicle_Frame:GetProperty("UnifiedPosition")
	 
end

function NewBangHui_Chronicle_OnEvent(event)
	if event == "GUILD_OPEN_GUILDBATTLEHIS" then 
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHui_Chronicle_OnClose()
	elseif (event == "ADJEST_UI_POS") then
		NewBangHui_Chronicle_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		NewBangHui_Chronicle_On_ResetPos()   
	elseif (event == "GUILD_SHOW_GUILDBATTLEHIS") then
		NewBangHui_Chronicle_UpdateData()   
	elseif (event == "GUILD_OPEN_GUILDBATTLEHIS") then
		NewBangHui_Chronicle_UpdateData()   
	end
end

function NewBangHui_Chronicle_On_ResetPos()
	NewBangHui_Chronicle_Frame:SetProperty("UnifiedPosition", g_NewBangHui_Chronicle_Frame_UnifiedPosition)
end

-- 更新数据
function NewBangHui_Chronicle_UpdateData() 
	NewBangHui_Chronicle_InitData();
	--设置 XX/XX 页
	local CurPage 	 = City:AskGuildBattleHisInfo("CurPage");
	local TotalPage  = City:AskGuildBattleHisInfo("TotalPage");
	local PageNum 	 = tostring(CurPage).."/"..tostring(TotalPage);
	
	g_PageIndex = CurPage;
	g_PageCount = TotalPage;
	g_NewBanHui_ChronicCtl.Chronicle_CurrentlyPage:SetText(PageNum);
	
	for i = 0, g_PageMaxCount-1 do 
		local isValid 	= City:AskGuildBattleHisData(i,"IsValid"); 
		if isValid == 1 then
			local SelfGuildName 	= City:AskGuildBattleHisData(i,"SelfGuildName"); 
			local RivalGuildName 	= City:AskGuildBattleHisData(i,"RivalGuildName"); 
			local SelfScore 			= City:AskGuildBattleHisData(i,"SelfScore"); 
			local RivalScore 			= City:AskGuildBattleHisData(i,"RivalScore"); 
			local BattleTime_Year = City:AskGuildBattleHisData(i,"BattleTime_Year"); 
			local BattleTime_Mon 	= City:AskGuildBattleHisData(i,"BattleTime_Mon"); 
			local BattleTime_Day 	= City:AskGuildBattleHisData(i,"BattleTime_Day"); 
			local BattleTime_Hour = City:AskGuildBattleHisData(i,"BattleTime_Hour");  
			g_NewBanHui_ChronicText[i+1]:SetText( ScriptGlobal_Format("#{BHXZ_150831_41}",
				 "20"..tostring(BattleTime_Year), 
				 tostring(BattleTime_Mon),
				 tostring(BattleTime_Day), 
				 tostring(SelfGuildName),
				 tostring(RivalGuildName),
				 tostring(SelfScore),
				 tostring(RivalScore)
				 ));
				 
			--if SelfScore == RivalScore then
			--	g_NewBanHui_ChronicText[i+1]:SetText( ScriptGlobal_Format("#{BHXZ_150831_42}",
			--	 "20"..tostring(BattleTime_Year), 
			--	 tostring(BattleTime_Mon),
			--	 tostring(BattleTime_Day),
			--	 tostring(BattleTime_Hour),
			--	 tostring(SelfGuildName),
			--	 tostring(RivalGuildName),
			--	 tostring(SelfScore),
			--	 tostring(RivalScore)
			--	 ));
			--end
			--if SelfScore > RivalScore then
			--	g_NewBanHui_ChronicText[i+1]:SetText( ScriptGlobal_Format("#{BHXZ_150831_41}",
			--	 "20"..tostring(BattleTime_Year), 
			--	 tostring(BattleTime_Mon),
			--	 tostring(BattleTime_Day),
			--	 tostring(BattleTime_Hour),
			--	 tostring(SelfGuildName),
			--	 tostring(SelfScore),
			--	 tostring(RivalScore),
			--	 tostring(RivalGuildName)
			--	 ));
			--end
			--if SelfScore < RivalScore then
			--	g_NewBanHui_ChronicText[i+1]:SetText( ScriptGlobal_Format("#{BHXZ_150831_41}",
			--	 "20"..tostring(BattleTime_Year), 
			--	 tostring(BattleTime_Mon),
			--	 tostring(BattleTime_Day),
			--	 tostring(BattleTime_Hour),
			--	 tostring(RivalGuildName),
			--	 tostring(RivalScore),
			--	 tostring(SelfScore),
			--	 tostring(SelfGuildName)
			--	 ));
			--end
		end  
	end   
	this:Show();
	
end

function NewBangHui_Chronicle_UpdateView()
	City:UpdateGuildBattleHis( g_PageIndex ); 
end

--========================================
--CD检查
--========================================
function NewBangHui_RankingList_PassCD()
   local iCur = OSAPI:GetTickCount()
   if( iCur - g_TimeClick) < 2*1000 then
       return false;
   else
       g_TimeClick = iCur;
       return true;
   end
end
-- 第一页
function NewBangHui_Chronicle_Right_FirstPage_Clicked()
	  --检查CD 
  if not NewBangHui_RankingList_PassCD() then 
     PushDebugMessage("#{ZYPT_081127_2}")  --"不可连续点击，请稍等片刻后再点击。";
     return
  end 
  
	if g_PageIndex ~= 1 then
		g_PageIndex = 1
		NewBangHui_Chronicle_UpdateView() 
	end
end
-- 前一页
function NewBangHui_Chronicle_Right_UpPage_Clicked()
	  --检查CD 
  if not NewBangHui_RankingList_PassCD() then 
     PushDebugMessage("#{ZYPT_081127_2}")  --"不可连续点击，请稍等片刻后再点击。";
     return
  end 
	if g_PageIndex > 1 then
		g_PageIndex = g_PageIndex - 1
		NewBangHui_Chronicle_UpdateView() 
	end
end
-- 下一页
function NewBangHui_Chronicle_Right_DownPage_Clicked()
	  --检查CD 
  if not NewBangHui_RankingList_PassCD() then 
     PushDebugMessage("#{ZYPT_081127_2}")  --"不可连续点击，请稍等片刻后再点击。";
     return
  end 
  
	if g_PageIndex < g_PageCount then

		g_PageIndex = g_PageIndex + 1
		NewBangHui_Chronicle_UpdateView() 
	end
end
-- 最后一页
function NewBangHui_Chronicle_Right_LastPage_Clicked()
	  --检查CD 
  if not NewBangHui_RankingList_PassCD() then 
     PushDebugMessage("#{ZYPT_081127_2}")  --"不可连续点击，请稍等片刻后再点击。";
     return
  end 
	if g_PageIndex ~= g_PageCount then
		g_PageIndex  	=g_PageCount 
		NewBangHui_Chronicle_UpdateView() 
	end
end
--转到
function NewBangHui_Chronicle_Right_Goto_Clicked()
	local pagetext = g_NewBanHui_ChronicCtl.Chronicle_GotoEditBox:GetText()
	if pagetext == "" then
		return
	end
	local gopages = tonumber(pagetext)
	if not gopages then
		return
	end
	 
	if gopages <= g_PageCount then
		g_PageIndex = gopages
		NewBangHui_Chronicle_UpdateView() 
	end
	g_NewBanHui_ChronicCtl.Chronicle_GotoEditBox:SetText("")
end


function NewBangHui_Chronicle_OnClose()
	this:Hide()
	g_TimeClick = 0;
	g_PageIndex = 0;
	g_PageCount = 0;
end

function NewBangHui_Chronicle_InitData()
	g_TimeClick = 0;
	g_PageIndex = 0;
	g_PageCount = 0;
	for i = 0, g_PageMaxCount-1 do 
		 g_NewBanHui_ChronicText[i+1]:SetText("");
	end   
end