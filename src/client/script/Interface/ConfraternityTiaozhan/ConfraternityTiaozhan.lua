
local g_ConfraternityTiaozhan_Frame_UnifiedPosition;
--帮派征讨接受挑战界面

function ConfraternityTiaozhan_PreLoad()
	this:RegisterEvent("GUILD_SHOW_TIAOZHAN");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)			
end

function ConfraternityTiaozhan_OnLoad()
	g_ConfraternityTiaozhan_Frame_UnifiedPosition=ConfraternityTiaozhan_Frame:GetProperty("UnifiedPosition");
end

function ConfraternityTiaozhan_OnEvent(event)
	if ( event == "GUILD_SHOW_TIAOZHAN") then
		local guildName = City : GetAttackGuildName();
		if(guildName == nil) then
			return;
		end
		ConfraternityTiaozhan_Text : SetText(guildName.."#{BHXZ_081103_09}");
		this:Show()
	end
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		ConfraternityTiaozhan_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ConfraternityTiaozhan_Frame_On_ResetPos()
	end
end

function ConfraternityTiaozhan_InitDlg()
	
end

function ConfraternityTiaozhan_Help()
	
end

function ConfraternityTiaozhan_Accept_Click()
	City:ReponseGuildBattle(1);	
	this:Hide();
end

function ConfraternityTiaozhan_Refuse_Click()
	City:ReponseGuildBattle(0);
	this:Hide();
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function ConfraternityTiaozhan_Frame_On_ResetPos()
  ConfraternityTiaozhan_Frame:SetProperty("UnifiedPosition", g_ConfraternityTiaozhan_Frame_UnifiedPosition);
end