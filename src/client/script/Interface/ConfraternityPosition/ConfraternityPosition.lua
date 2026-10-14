local GUILD_POSITION_SIZE = 10; --最多可用职位数
local g_ConfraternityPosition_Frame_UnifiedPosition;
function ConfraternityPosition_PreLoad()
	this:RegisterEvent("GUILD_SHOW_APPOINTPOS",true);
	this:RegisterEvent("GUILD_FORCE_CLOSE",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)		
end

function ConfraternityPosition_OnLoad()
		g_ConfraternityPosition_Frame_UnifiedPosition=ConfraternityPosition_Frame:GetProperty("UnifiedPosition");
end

function ConfraternityPosition_OnEvent(event)
	if(event == "GUILD_SHOW_APPOINTPOS") then
		ConfraternityPosition_PositionList:ClearListBox();
		local i = 0;
		while i < GUILD_POSITION_SIZE do
			local szMsg = Guild:GetMyGuildInfo("Appoint", i);
			--AxTrace(0,0,"Guild Position:"..tostring(i).." pos:"..tostring(szMsg));
			if(nil ~= szMsg and "" ~= szMsg) then
				if DataPool:Lua_IsPaoShangSvr() ~= 1 and ("商人" == szMsg) then
				else
					ConfraternityPosition_PositionList:AddItem(szMsg,i);
				end
			else
				break;
			end
			i = i + 1;
		end
		
		if(nil ~= Guild:GetMyGuildInfo("Appoint", 0)) then
			ConfraternityPosition_PositionList:SetItemSelectByItemID(0);
		end
		this:Show();
	elseif(event == "GUILD_FORCE_CLOSE") then
		this:Hide();
	end
		-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		ConfraternityPosition_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ConfraternityPosition_Frame_On_ResetPos()
	end
end

function Guild_Position_Confirm()
	local selidx = ConfraternityPosition_PositionList:GetFirstSelectItem();
	-- add by zchw 
	local szMsg = Guild:GetMyGuildInfo("Appoint", selidx);
	if szMsg == "商人" then
		local Num = Guild:GetMemberBak();
		local szLvl = Guild:GetMembersInfo(Num, "Level");	
		if szLvl < 40 then
			PushDebugMessage("40级以下的帮众不能被任命为商人！");
			return;
		end
	-- end
	end	
	if(-1 ~= selidx) then
		--调用任命接口
		Guild:AdjustMemberAuth(selidx);
	end
	this:Hide();
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function ConfraternityPosition_Frame_On_ResetPos()
  ConfraternityPosition_Frame:SetProperty("UnifiedPosition", g_ConfraternityPosition_Frame_UnifiedPosition);
end
