function SongliaoWarSingle_PreLoad()
	this:RegisterEvent("SHOW_SONGLIAOWAR_SCORE_S");
	this:RegisterEvent("REFRESH_SONGLIAOWAR_SCORE");
	this:RegisterEvent("SHOW_SONGLIAOWAR_SCORE_M");
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

function SongliaoWarSingle_OnLoad()
end

function SongliaoWarSingle_OnEvent(event)
	if (event=="SCENE_TRANSED") then
		-- T300宋辽优化 宋辽改到T300上了 这个UI不用了
		-- if(548~=GetSceneID()) then
		-- 	CSongliaoWarData:ClearSongliaoData()
		-- end
		-- if arg0=="Songliao_War" then
		-- 	this:Show()
		-- 	local myRet, myName, myCamp, myScore = CSongliaoWarData:GetMyScore()
		-- 	--PushDebugMessage(myCamp)
		-- 	if( myCamp == 156) then
		-- 		SongliaoWarSingle_Help_Bk:Show()
		-- 		SongliaoWarSingle_Help_Bk2:Hide()
		-- 	elseif ( myCamp == 157 ) then
		-- 		SongliaoWarSingle_Help_Bk2:Show()
		-- 		SongliaoWarSingle_Help_Bk:Hide()
		-- 	end
		-- 	SongliaoWarSingle_Song_Score:SetText("0")
		-- 	SongliaoWarSingle_Liao_Score:SetText("0")
		-- else
		-- 	this:Hide()
		-- end
	elseif (event=="PLAYER_LEAVE_WORLD") then
		if( this:IsVisible() ) then
			this:Hide()
		end
	elseif (event=="SHOW_SONGLIAOWAR_SCORE_S") then--貌似没用？
		if arg0=="0" and this:IsVisible() then
			this:Hide()
		elseif arg0=="1" and this:IsVisible()==false then
			this:Show()
			local myRet, myName, myCamp, myScore = CSongliaoWarData:GetMyScore()
			--PushDebugMessage(myCamp)
			if( myCamp == 156) then
				SongliaoWarSingle_Help_Bk:Show()
				SongliaoWarSingle_Help_Bk2:Hide()
			elseif ( myCamp == 157 ) then
				SongliaoWarSingle_Help_Bk2:Show()
				SongliaoWarSingle_Help_Bk:Hide()
			end
		end
	elseif (event=="SHOW_SONGLIAOWAR_SCORE_M") then
		if arg0=="0" then
			local myRet, myName, myCamp, myScore = CSongliaoWarData:GetMyScore()
			if myCamp == 156 then
				SongliaoWarSingleOpen:Show();
				SongliaoWarSingleClose:Hide();
			elseif myCamp == 157 then
				--PushDebugMessage("xx")
				--SongliaoWarSingleOpen:Hide()
				--SongliaoWarSingleClose:Hide()
				SongliaoWarSingleOpen2:Show();
				SongliaoWarSingleClose2:Hide();
			end
		end	
	elseif (event=="REFRESH_SONGLIAOWAR_SCORE") then
		
		this:Show()
		local myRet, myName, myCamp, myScore = CSongliaoWarData:GetMyScore()
		--PushDebugMessage(myCamp)
		if( myCamp == 156) then
			SongliaoWarSingle_Help_Bk:Show()
			SongliaoWarSingle_Help_Bk2:Hide()
		elseif ( myCamp == 157 ) then
			SongliaoWarSingle_Help_Bk2:Show()
			SongliaoWarSingle_Help_Bk:Hide()
		end
		local songScore,liaoScore=CSongliaoWarData:GetCampScore()
		if songScore~=nil then
			--PushDebugMessage(songScore.."x"..liaoScore)
		end
		if songScore~=nil and liaoScore~=nil then
			SongliaoWarSingle_Song_Score:SetText(tostring(songScore))
			SongliaoWarSingle_Liao_Score:SetText(tostring(liaoScore))
		end
	end
end

function SongliaoWarSingle_Open()
	CSongliaoWarData:OpenSongliaoWarMulti()
	local myRet, myName, myCamp, myScore = CSongliaoWarData:GetMyScore()
	if myCamp == 156 then
		SongliaoWarSingleOpen:Hide()
		SongliaoWarSingleClose:Show()
	elseif myCamp == 157 then
		--PushDebugMessage("157")
		SongliaoWarSingleOpen2:Hide();
		SongliaoWarSingleClose2:Show();
	end
	SongliaoWarSingleClose3:Show()
	SongliaoWarSingleOpen3:Hide()
	--PushDebugMessage("SongliaoWarSingle_Open")
end

function SongliaoWarSingle_Close()
	--PushDebugMessage("SongliaoWarSingle_Close")
	CSongliaoWarData:CloseSongliaoWarMulti()
	if myCamp == 156 then
		SongliaoWarSingleOpen:Show()
		SongliaoWarSingleClose:Hide()
	elseif myCamp == 157 then
		SongliaoWarSingleOpen2:Show()
		SongliaoWarSingleClose2:Hide()
	end
	SongliaoWarSingleOpen3:Show()
	SongliaoWarSingleClose3:Hide()
end
