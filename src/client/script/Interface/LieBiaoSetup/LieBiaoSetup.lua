local g_LieBiaoSetup_Frame_UnifiedPosition = nil 

local PLAYERLIST_SELECT = {}
local PLAYERLIST_CHECKBUTTON = {}
local PLAYERLIST_CHECKBUTTON_ENEMY = {}
local PLAYERLIST_SELECT_ENEMY = {}
local g_Page = 0
function LieBiaoSetup_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	this:RegisterEvent("SET_PLAYERLIST_CUSTOM")
end 

function LieBiaoSetup_OnLoad()
	g_LieBiaoSetup_Frame_UnifiedPosition = LieBiaoSetup_Frame:GetProperty("UnifiedPosition");
	
	
	PLAYERLIST_CHECKBUTTON[1] = nil
	PLAYERLIST_CHECKBUTTON[2] = LieBiaoSetup_Frame_BK1_Check --CheckShaolin
	PLAYERLIST_CHECKBUTTON[3] = LieBiaoSetup_Frame_BK2_Check --CheckMingjiao
	PLAYERLIST_CHECKBUTTON[4] = LieBiaoSetup_Frame_BK1_Check1 --CheckGaibang
	PLAYERLIST_CHECKBUTTON[5] = LieBiaoSetup_Frame_BK2_Check1 --CheckWudang
	PLAYERLIST_CHECKBUTTON[6] = LieBiaoSetup_Frame_BK3_Check --CheckEmei
	PLAYERLIST_CHECKBUTTON[7] = LieBiaoSetup_Frame_BK3_Check1 --CheckXingxiu
	PLAYERLIST_CHECKBUTTON[8] = LieBiaoSetup_Frame_BK4_Check --CheckTianlong
	PLAYERLIST_CHECKBUTTON[9] = LieBiaoSetup_Frame_BK4_Check1 --CheckTianshan
	PLAYERLIST_CHECKBUTTON[10] = LieBiaoSetup_Frame_BK5_Check --CheckXiaoyao
	PLAYERLIST_CHECKBUTTON[11] = LieBiaoSetup_Frame_BK5_Check1 --CheckMurong
	PLAYERLIST_CHECKBUTTON[12] = LieBiaoSetup_Frame_BK6_Check --CheckTangmen
	PLAYERLIST_CHECKBUTTON[13] = LieBiaoSetup_Frame_BK_Check2 --DiffGuildLeague --
	PLAYERLIST_CHECKBUTTON[14] = LieBiaoSetup_Frame_BK6_Check1 --CheckGuigu
	PLAYERLIST_CHECKBUTTON[15] = LieBiaoSetup_Frame_BK7_Check --CheckTaohuadao
	PLAYERLIST_CHECKBUTTON[16] = LieBiaoSetup_Frame_BK7_Check1 --CheckMenpai14
	PLAYERLIST_CHECKBUTTON[17] = LieBiaoSetup_Frame_BK_Check5	--Designatedguild --
	PLAYERLIST_CHECKBUTTON[18] = LieBiaoSetup_Frame_BK_Check4	--CheckUnBreakable
	PLAYERLIST_CHECKBUTTON[19] = LieBiaoSetup_Frame_BK8_Check --CheckMenpai15  menpai15 mptodo

	PLAYERLIST_CHECKBUTTON_ENEMY[1] = LieBiaoSetup_Frame_BK_Check3 --PersonalEnemy --
	PLAYERLIST_CHECKBUTTON_ENEMY[2] = LieBiaoSetup_Frame_BK1_Check --CheckShaolinEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[3] = LieBiaoSetup_Frame_BK2_Check --CheckMingjiaoEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[4] = LieBiaoSetup_Frame_BK1_Check1 --CheckGaibangEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[5] = LieBiaoSetup_Frame_BK2_Check1 --CheckWudangEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[6] = LieBiaoSetup_Frame_BK3_Check --CheckEmei
	PLAYERLIST_CHECKBUTTON_ENEMY[7] = LieBiaoSetup_Frame_BK3_Check1 --CheckXingxiuEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[8] = LieBiaoSetup_Frame_BK4_Check --CheckTianlongEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[9] = LieBiaoSetup_Frame_BK4_Check1 --CheckTianshanEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[10] = LieBiaoSetup_Frame_BK5_Check --CheckXiaoyaoEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[11] = LieBiaoSetup_Frame_BK5_Check1 --CheckMurongEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[12] = LieBiaoSetup_Frame_BK6_Check --CheckTangmenEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[13] = LieBiaoSetup_Frame_BK_Check2 --DiffGuildLeagueEnemy --
	PLAYERLIST_CHECKBUTTON_ENEMY[14] = LieBiaoSetup_Frame_BK6_Check1 --CheckGuiguEnemy --
	PLAYERLIST_CHECKBUTTON_ENEMY[15] = LieBiaoSetup_Frame_BK7_Check --CheckTaohuadaoEnemy
	PLAYERLIST_CHECKBUTTON_ENEMY[16] = LieBiaoSetup_Frame_BK7_Check1 --CheckMenpai14Enemy
	PLAYERLIST_CHECKBUTTON_ENEMY[17] = LieBiaoSetup_Frame_BK_Check5 --DesignatedguildEnemy --
	PLAYERLIST_CHECKBUTTON_ENEMY[18] = LieBiaoSetup_Frame_BK_Check4 --CheckUnBreakableEnemy --
	PLAYERLIST_CHECKBUTTON_ENEMY[19] = LieBiaoSetup_Frame_BK8_Check --CheckMenpai15Enemy  menpai15 mptodo
	
	PLAYERLIST_SELECT[1] = ""
	PLAYERLIST_SELECT[2] = "CheckShaolin"
	PLAYERLIST_SELECT[3] = "CheckMingjiao"
	PLAYERLIST_SELECT[4] = "CheckGaibang"
	PLAYERLIST_SELECT[5] = "CheckWudang"
	PLAYERLIST_SELECT[6] = "CheckEmei"
	PLAYERLIST_SELECT[7] = "CheckXingxiu"
	PLAYERLIST_SELECT[8] = "CheckTianlong"
	PLAYERLIST_SELECT[9] = "CheckTianshan"
	PLAYERLIST_SELECT[10] = "CheckXiaoyao"
	PLAYERLIST_SELECT[11] = "CheckMurong"
	PLAYERLIST_SELECT[12] = "CheckTangmen"
	PLAYERLIST_SELECT[13] = "DiffGuildLeague"
	PLAYERLIST_SELECT[14] = "CheckGuigu"
	PLAYERLIST_SELECT[15] = "CheckTaohuadao" --桃花岛
	PLAYERLIST_SELECT[16] = "CheckMenpai14"
	PLAYERLIST_SELECT[17] = "Designatedguild"
	PLAYERLIST_SELECT[18] = "CheckUnBreakable"
	PLAYERLIST_SELECT[19] = "CheckMenpai15" --menpai15 mptodo

	PLAYERLIST_SELECT_ENEMY[1] = "PersonalEnemy"
	PLAYERLIST_SELECT_ENEMY[2] = "CheckShaolinEnemy"
	PLAYERLIST_SELECT_ENEMY[3] = "CheckMingjiaoEnemy"
	PLAYERLIST_SELECT_ENEMY[4] = "CheckGaibangEnemy"
	PLAYERLIST_SELECT_ENEMY[5] = "CheckWudangEnemy"
	PLAYERLIST_SELECT_ENEMY[6] = "CheckEmeiEnemy"
	PLAYERLIST_SELECT_ENEMY[7] = "CheckXingxiuEnemy"
	PLAYERLIST_SELECT_ENEMY[8] = "CheckTianlongEnemy"
	PLAYERLIST_SELECT_ENEMY[9] = "CheckTianshanEnemy"
	PLAYERLIST_SELECT_ENEMY[10] = "CheckXiaoyaoEnemy"
	PLAYERLIST_SELECT_ENEMY[11] = "CheckMurongEnemy"
	PLAYERLIST_SELECT_ENEMY[12] = "CheckTangmenEnemy"
	PLAYERLIST_SELECT_ENEMY[13] = "DiffGuildLeagueEnemy"
	PLAYERLIST_SELECT_ENEMY[14] = "CheckGuiguEnemy"
	PLAYERLIST_SELECT_ENEMY[15] = "CheckTaohuadaoEnemy" --桃花岛
	PLAYERLIST_SELECT_ENEMY[16] = "CheckMenpai14Enemy"
	PLAYERLIST_SELECT_ENEMY[17] = "DesignatedguildEnemy"
	PLAYERLIST_SELECT_ENEMY[18] = "CheckUnBreakableEnemy"
	PLAYERLIST_SELECT_ENEMY[19] = "CheckMenpai15Enemy" --menpai15 mptodo 下面的控件for循环遍历数量记得修改 本次18改19

	LieBiaoSetup_Frame_BK_Text5_List:AddTextItem("本帮", 0)
	LieBiaoSetup_Frame_BK_Text5_List:AddTextItem("非本帮", 1)
	LieBiaoSetup_Frame_BK_Text5_List:AddTextItem("本服", 2)
	LieBiaoSetup_Frame_BK_Text5_List:AddTextItem("天外", 3)
	local isel = SystemSetup:GetCustomPlayerList("Designatedguildsel");
	if g_Page == 1 then
		isel = SystemSetup:GetCustomPlayerList("Designatedguildsel");
	elseif g_Page == 2 then
		isel = SystemSetup:GetCustomPlayerList("DesignatedguildselEnemy");
	end
	
	if isel >= 0 and isel <= 3 then
		LieBiaoSetup_Frame_BK_Text5_List:SetCurrentSelect( isel )
		if isel >= 2 and isel <= 3 then
			LieBiaoSetup_Frame_BK_Text5_Input:Show()
			LieBiaoSetup_Frame_BK_Text5_ID:Show()
		else
			LieBiaoSetup_Frame_BK_Text5_Input:Hide()
			LieBiaoSetup_Frame_BK_Text5_ID:Hide()
		end
	end

end

function LieBiaoSetup_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		LieBiaoSetup_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		LieBiaoSetup_On_ResetPos()
	elseif(event == "SET_PLAYERLIST_CUSTOM") then
		g_Page = 2
		LieBiaoSetup_Updata()
		this:Show()
	end
end


function LieBiaoSetup_Updata()
	if g_Page == 1 then
		LieBiaoSetup_Frame_Page1:SetCheck(1)
		LieBiaoSetup_Frame_Page2:SetCheck(0)
		LieBiaoSetup_Frame_BK_Check3:Hide()
		LieBiaoSetup_Frame_BK_Text3:Hide()
		LieBiaoSetup_Blank_Text:SetText("#{FJLB_160114_22}")
		for i = 1, 19 do
			if PLAYERLIST_CHECKBUTTON[i] ~= nil then
				local temp = SystemSetup:GetCustomPlayerList(PLAYERLIST_SELECT[i]);
				PLAYERLIST_CHECKBUTTON[i]:SetCheck(temp);
			end
		end

		local isel = SystemSetup:GetCustomPlayerList("Designatedguildsel");
		if isel >= 0 and isel <= 3 then
			LieBiaoSetup_Frame_BK_Text5_List:SetCurrentSelect( isel )
			if isel >= 2 and isel <= 3 then
				LieBiaoSetup_Frame_BK_Text5_Input:Show()
				LieBiaoSetup_Frame_BK_Text5_ID:Show()
			else
				LieBiaoSetup_Frame_BK_Text5_Input:Hide()
				LieBiaoSetup_Frame_BK_Text5_ID:Hide()
			end
		end

		local temp = SystemSetup:GetCustomPlayerList("Designatedguildid");

		LieBiaoSetup_Frame_BK_Text5_Input:SetText(temp)
	end
	
	if g_Page == 2 then
		LieBiaoSetup_Frame_Page1:SetCheck(0)
		LieBiaoSetup_Frame_Page2:SetCheck(1)
		LieBiaoSetup_Frame_BK_Check3:Show()
		LieBiaoSetup_Frame_BK_Text3:Show()
		LieBiaoSetup_Blank_Text:SetText("#{FJLB_160817_33}")
		for i = 1, 19 do
			if PLAYERLIST_CHECKBUTTON_ENEMY[i] ~= nil then
				local temp = SystemSetup:GetCustomPlayerList(PLAYERLIST_SELECT_ENEMY[i]);
				PLAYERLIST_CHECKBUTTON_ENEMY[i]:SetCheck(temp);
			end
		end
		local isel = SystemSetup:GetCustomPlayerList("DesignatedguildselEnemy");
		if isel >= 0 and isel <= 3 then
			LieBiaoSetup_Frame_BK_Text5_List:SetCurrentSelect( isel )
			if isel >= 2 and isel <= 3 then
				LieBiaoSetup_Frame_BK_Text5_Input:Show()
				LieBiaoSetup_Frame_BK_Text5_ID:Show()
			else
				LieBiaoSetup_Frame_BK_Text5_Input:Hide()
				LieBiaoSetup_Frame_BK_Text5_ID:Hide()
			end
		end

		local temp = SystemSetup:GetCustomPlayerList("DesignatedguildidEnemy");
		LieBiaoSetup_Frame_BK_Text5_Input:SetText(temp)
	end
end

function LieBiaoSetup_On_ResetPos()
	LieBiaoSetup_Frame:SetProperty("UnifiedPosition", g_LieBiaoSetup_Frame_UnifiedPosition)
end

    -- SystemSetup:SetIsConfigChanged( 0 )
	-- SystemSetup:Lua_ViewSetupToFile()o  
	
function LieBiaoSetup_OK()
	local sSel,iSel =  LieBiaoSetup_Frame_BK_Text5_List:GetCurrentSelect()
	if g_Page == 1 then
		for i = 1, 19 do
			if PLAYERLIST_CHECKBUTTON[i] ~= nil then
				local temp = PLAYERLIST_CHECKBUTTON[i]:GetCheck();
				SystemSetup:CustomPlayerList(PLAYERLIST_SELECT[i],temp)
			end
		end	

		if iSel >= 0 and iSel <= 3 then
			SystemSetup:CustomPlayerList("Designatedguildsel",tonumber(iSel))
		end

		local text = LieBiaoSetup_Frame_BK_Text5_Input:GetText()
		if text ~= "" and text ~= nil and iSel >= 2 and iSel <= 3 then
			SystemSetup:CustomPlayerList("Designatedguildid",tonumber(text))	
		end


	end

	if g_Page == 2 then
		for i = 1, 19 do  
			if PLAYERLIST_CHECKBUTTON_ENEMY[i] ~= nil then
				local temp = PLAYERLIST_CHECKBUTTON_ENEMY[i]:GetCheck();
				SystemSetup:CustomPlayerList(PLAYERLIST_SELECT_ENEMY[i],temp)
			end
		end

		if iSel >= 0 and iSel <= 3 then
			SystemSetup:CustomPlayerList("DesignatedguildselEnemy",tonumber(iSel))
		end

		local text = LieBiaoSetup_Frame_BK_Text5_Input:GetText()
		if text ~= "" and text ~= nil and iSel >= 2 and iSel <= 3 then
			SystemSetup:CustomPlayerList("DesignatedguildidEnemy",tonumber(text))
		end
	end

	SystemSetup:Lua_ViewSetupToFile()
	
	this:Hide()
end

function LieBiaoSetup_CloseFream()
	this:Hide()
end

function LieBiaoSetup_Frame_PageClicked(idx)
	
	if g_Page == 1 then
		for i = 1, 19 do
			if PLAYERLIST_CHECKBUTTON[i] ~= nil then
				local temp = PLAYERLIST_CHECKBUTTON[i]:GetCheck();
				SystemSetup:CustomPlayerList(PLAYERLIST_SELECT[i],temp)
			end
		end	
		local sSel,iSel =  LieBiaoSetup_Frame_BK_Text5_List:GetCurrentSelect()
		if iSel >= 0 and iSel <= 3 then
			SystemSetup:CustomPlayerList("Designatedguildsel",tonumber(iSel))
		end

		local text = LieBiaoSetup_Frame_BK_Text5_Input:GetText()
		if text ~= "" and text ~= nil and iSel >= 2 and iSel <= 3 then
			SystemSetup:CustomPlayerList("Designatedguildid",tonumber(text))	
		end
	end

	if g_Page == 2 then
		for i = 1, 19 do
			if PLAYERLIST_CHECKBUTTON_ENEMY[i] ~= nil then
				local temp = PLAYERLIST_CHECKBUTTON_ENEMY[i]:GetCheck();
				SystemSetup:CustomPlayerList(PLAYERLIST_SELECT_ENEMY[i],temp)
			end
		end
		local sSel,iSel =  LieBiaoSetup_Frame_BK_Text5_List:GetCurrentSelect()
		if iSel >= 0 and iSel <= 3 then
			SystemSetup:CustomPlayerList("DesignatedguildselEnemy",tonumber(iSel))
		end
		if text ~= "" and text ~= nil and iSel >= 2 and iSel <= 3 then
			SystemSetup:CustomPlayerList("DesignatedguildidEnemy",tonumber(text))
		end
	end
	SystemSetup:Lua_ViewSetupToFile()

	g_Page = idx

	LieBiaoSetup_Updata()
end



function LieBiaoSetup_Change_SelChanged()

	local sSel,iSel =  LieBiaoSetup_Frame_BK_Text5_List:GetCurrentSelect()
	
	if iSel == 0 then
		LieBiaoSetup_Frame_BK_Text5_Input:Hide()
		LieBiaoSetup_Frame_BK_Text5_ID:Hide()
	elseif iSel == 1 then
		LieBiaoSetup_Frame_BK_Text5_Input:Hide()
		LieBiaoSetup_Frame_BK_Text5_ID:Hide()
	elseif iSel == 2 then
		LieBiaoSetup_Frame_BK_Text5_Input:Show()
		LieBiaoSetup_Frame_BK_Text5_ID:Show()
	else
		LieBiaoSetup_Frame_BK_Text5_Input:Show()
		LieBiaoSetup_Frame_BK_Text5_ID:Show()
	end
end

function LieBiaoSetup_TextChanged()
	local num = tonumber(LieBiaoSetup_Frame_BK_Text5_Input:GetText())
	if(num == nil or num < 0) then
		LieBiaoSetup_Frame_BK_Text5_Input:SetText("0")
		return
	end
end
