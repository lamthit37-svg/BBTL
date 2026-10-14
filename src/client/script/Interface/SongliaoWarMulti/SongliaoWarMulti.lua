local g_LiaoColor = "ffff0000"
local g_SongColor = "ffffff00"
local g_myColor = "ff00ff00"

function SongliaoWarMulti_PreLoad()
	this:RegisterEvent("REFRESH_SONGLIAOWAR_SCORE");
	this:RegisterEvent("SHOW_SONGLIAOWAR_SCORE_M");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	--this:RegisterEvent("UI_COMMAND");
end

function SongliaoWarMulti_OnLoad()
	SongliaoWarMulti_List:SetProperty( "ColumnsSizable", "False" )
	SongliaoWarMulti_List:SetProperty( "ColumnsAdjust", "True" )
	SongliaoWarMulti_List:SetProperty( "ColumnsMovable", "False" )
end

function SongliaoWarMulti_OnHiden()
	CSongliaoWarData:CloseSongliaoWarMulti()
end

function SongliaoWarMulti_OnEvent(event)
	--PushDebugMessage(event)
	if( event == "SHOW_SONGLIAOWAR_SCORE_M" ) then
		if arg0 == "0" and this:IsVisible() then
			this:Hide();
		elseif arg0 == "1" and this:IsVisible() == false then
			--PushDebugMessage(event)
			this:Show()
			SongliaoWarMulti_GetData()
		end 
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
	elseif (event=="REFRESH_SONGLIAOWAR_SCORE" and this:IsVisible()) then
		SongliaoWarMulti_GetData()
	end
end


function SongliaoWarMulti_Close()
	CSongliaoWarData:CloseSongliaoWarMulti()
end

function SongliaoWarMulti_GetData()
	local myRet, myName, myCamp, myScore, mykillNum = CSongliaoWarData:GetMyScore()
	if myRet~=nil and myRet==1 then
		SongliaoWarMulti_SetInterface(0,myName,myCamp,myScore, g_myColor)
	else
		return
	end
	for i=0,59 do
		local ret, charname, camp, score = CSongliaoWarData:GetScoreByIndex(i)
		--PushDebugMessange(ret)
		if ret~=nil and ret==1 then
			if camp==156 then
				SongliaoWarMulti_SetInterface(i+1,charname,camp,score, g_SongColor)
			elseif camp==157 then
				SongliaoWarMulti_SetInterface(i+1,charname,camp,score, g_LiaoColor)
			else
				SongliaoWarMulti_SetInterface(i+1,charname,camp,score, g_myColor)--impossible
			end
		else
			--SongliaoWarMulti_SetInterface(i+1,"N/A",156,0)--测试用，注意用完要删除
		end
	end
end


function SongliaoWarMulti_SetInterface(index, charname, camp, score, color)
	SongliaoWarMulti_List:AddNewItem(charname, 0, index, color)
	if camp==156 then
		--PushDebugMessage(score)
		SongliaoWarMulti_List:AddNewItem("#{SLDZ_100805_118}", 1, index, color)
	elseif camp==157 then
		SongliaoWarMulti_List:AddNewItem("#{SLDZ_100805_119}", 1, index, color)
	else
		SongliaoWarMulti_List:AddNewItem("N/A", 1, index, color)
	end
	SongliaoWarMulti_List:AddNewItem(score, 2, index, color)
end
