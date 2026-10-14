local g_ConfraternityPKStart_Frame_UnifiedPosition;

local g_IsAcrossServerBattle = 0;		--是否跨服宣战
local g_AddEnemyGuildID 	 = 0;		--宣战帮会ID
local g_AddEnemyZoneWorldID	 = 0;		--若是跨服宣战，则是跨服宣战的帮会所在服务器的ZoneWorld
local g_CDTime =0;
local g_NeedMoney =250000;
local g_Count =0;
function ConfraternityPKStart_PreLoad()
	this:RegisterEvent("CITY_OPEN_ADDENEMY_DLG",true);
	this:RegisterEvent("CITY_OPEN_ADDENEMY_DLG_CONFIRM",true);
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--离开场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function ConfraternityPKStart_OnLoad()
	g_ConfraternityPKStart_Frame_UnifiedPosition=ConfraternityPKStart_Frame:GetProperty("UnifiedPosition");
end


function ConfraternityPKStart_OnEvent(event)
	if ( event == "CITY_OPEN_ADDENEMY_DLG") then

		--ConfraternityPKStart_InitDlg()

		if ( tonumber(arg0) == 0 )	then			--若是本服宣战
			g_IsAcrossServerBattle = 0;
			g_AddEnemyGuildID = tonumber(arg1);
		else										--若是跨服宣战
			g_IsAcrossServerBattle = 1;
			g_AddEnemyGuildID = tonumber(arg1);
			g_AddEnemyZoneWorldID = tonumber(arg2);
		end
		ConfraternityPKStart_Text1:SetText("#{KVKBH_140124_28}")
		this:Show()
	end
	
	if ( event == "CITY_OPEN_ADDENEMY_DLG_CONFIRM") then

		g_IsAcrossServerBattle = 0;
		g_AddEnemyGuildID = tonumber(arg0);  
		local g_CDTimeAndCount  = tonumber(arg1);  
		g_CDTime					= math.floor ( g_CDTimeAndCount / 10 );		
		g_Count					= math.mod ( g_CDTimeAndCount , 10 );
		g_NeedMoney 			 = math.floor (tonumber(arg2)/ 10000 );
		if g_Count == 1 then			 
			local StrText = ScriptGlobal_Format("#{KVKBH_180531_76}", tostring(g_Count),g_NeedMoney)
			ConfraternityPKStart_Text1:SetText(StrText)
		else
			local	StrTime = ""
			if g_CDTime >= 60 then			
				local nHour = math.floor ( g_CDTime / 60 );
				local nMin   = math.mod ( g_CDTime , 60 ); 
				if nMin == 0 then
					StrTime = ScriptGlobal_Format("#{KVKBH_180531_81}", tostring(nHour))
				else	
					StrTime = ScriptGlobal_Format("#{KVKBH_180531_72}", tostring(nHour),tostring(nMin))
				end
			else
				StrTime = ScriptGlobal_Format("#{KVKBH_180531_73}", tostring(g_CDTime))
			end
			local StrText = ScriptGlobal_Format("#{KVKBH_180531_80}", tostring(g_Count),g_NeedMoney,StrTime)
			ConfraternityPKStart_Text1:SetText(StrText)			
		end
		this:Show()
	end
		-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		ConfraternityPKStart_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ConfraternityPKStart_Frame_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
	end
end

function ConfraternityPKStart_InitDlg()
	--ConfraternityPKStart_Input:SetProperty("DefaultEditBox", "True");
	--ConfraternityPKStart_Input:SetText("");
end


function ConfraternityPKStart_Cancel_BtnClick()
	this:Hide();
	--ConfraternityPKStart_OnHide()
end

function ConfraternityPKStart_OnHide()
	--ConfraternityPKStart_Input:SetProperty("DefaultEditBox", "False");
end

function ConfraternityPKStart_Accept_BtnClick()
	--local guid = ConfraternityPKStart_Input:GetText();
	--if(tonumber(guid)==nil)then
		--PushDebugMessage("帮会id不能为空！");
		--return;
	--end
	if g_IsAcrossServerBattle == 0 then				--本服宣战
		City:SendAddEnemyMsg( g_AddEnemyGuildID,1 );
	else											--跨服宣战
		City:AddKServerEnemyList(g_AddEnemyZoneWorldID, g_AddEnemyGuildID);
	end

	this:Hide();
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function ConfraternityPKStart_Frame_On_ResetPos()
  ConfraternityPKStart_Frame:SetProperty("UnifiedPosition", g_ConfraternityPKStart_Frame_UnifiedPosition);
end
