
local g_Frame_UnifiedXPosition_Sancai;
local g_Frame_UnifiedYPosition_Sancai;
local g_Current_ParaGraph = 1
local ScoreStr

local g_1_SongBing_num = 0
local g_1_FuDuTong_num = 0
local g_1_FeiLei_num = 0
local g_1_DuTong_num = 0
local g_1_YuDu_num = 0
local g_2_HongXiong_num = 0
local g_2_HongXiong_Boss_num = 0
local g_3_GeRong_num = 0

function Sancai_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("3HUAN_OPEN_UI_MINI")
	this:RegisterEvent("3HUAN_OPEN_UI_RESULT")
end

function Sancai_OnLoad()
	Sancai_BK1:Hide()
	Sancai_BK2:Hide()
	Sancai_BK3:Hide()
	g_Frame_UnifiedXPosition_Sancai	= Sancai_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition_Sancai	= Sancai_Frame:GetProperty("UnifiedYPosition");		
end

function Sancai_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Sancai_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		Sancai_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		if this:IsVisible() then
			this:Hide()
		end
		g_1_SongBing_num = 0
		g_1_FuDuTong_num = 0
		g_1_FeiLei_num = 0
		g_1_DuTong_num = 0
		g_1_YuDu_num = 0
		g_2_HongXiong_num = 0
		g_2_HongXiong_Boss_num = 0
		g_3_GeRong_num = 0		
		g_Current_ParaGraph = 1
		if NG_GetInt("FB") ~= 0 then
			NGSetInt("FB", 0)
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2015040710 ) then
		NGSetInt("FB", Get_XParam_INT(0))
		g_Current_ParaGraph = tonumber(Get_XParam_INT(1))
		if g_Current_ParaGraph == 1 then
			g_1_SongBing_num = 0
			g_1_FuDuTong_num = 0
			g_1_FeiLei_num = 0
			g_1_DuTong_num = 0
			g_1_YuDu_num = 0
			g_2_HongXiong_num = 0
			g_2_HongXiong_Boss_num = 0
			g_3_GeRong_num = 0	
		end
		Sancai_RefreshData()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2015040711 ) then
		NGSetInt("FB", Get_XParam_INT(0))
		--刷数据
			g_Current_ParaGraph = tonumber(Get_XParam_INT(1))
			local ListNum	 = tonumber(Get_XParam_INT(2))
			local KilledNum  = tonumber(Get_XParam_INT(3))
			if g_Current_ParaGraph ==  1 then
			--阶段一
				if ListNum == 1 then
					g_1_SongBing_num = KilledNum
				elseif ListNum == 2 then
					g_1_FuDuTong_num = KilledNum
				elseif ListNum == 3 then
					g_1_FeiLei_num = KilledNum
				elseif ListNum == 4 then
					g_1_DuTong_num = KilledNum
				elseif ListNum == 5 then
					g_1_YuDu_num = KilledNum
				end
			elseif g_Current_ParaGraph ==  2 then
			--阶段二
				if ListNum == 1 then
					g_2_HongXiong_num = KilledNum
				elseif ListNum == 2 then
					g_2_HongXiong_Boss_num = KilledNum
				end
			elseif g_Current_ParaGraph == 3 then
			--阶段三
				g_3_GeRong_num = KilledNum
			end
			Sancai_RefreshData()		
	elseif (event == "3HUAN_OPEN_UI_RESULT" ) then
		local operate = tonumber(arg0)
		if operate == 1 then
			if (this:IsVisible()) then
			else
				this:Show()
			end
			Sancai_RefreshData()
		else
			this:Hide()
		end
	end

end

--================================================
-- 填充数据
--================================================
function Sancai_RefreshData( )

		if (this:IsVisible())   then
			PushEvent( "3HUAN_OPEN_UI_MINI", 0, g_Current_ParaGraph )
			if g_Current_ParaGraph == 1 then
				Sancai_BK1:Show()
				Sancai_BK2:Hide()
				Sancai_BK3:Hide()
				
				--宋兵
				ScoreStr = ScriptGlobal_Format( "#{LSHYH_150210_113}", g_1_SongBing_num)
				Sancai_Image1Info2:SetText(ScoreStr)
				
				--副都统
				ScoreStr = ScriptGlobal_Format( "#{LSHYH_150210_114}", g_1_FuDuTong_num)
				Sancai_Image1Info3:SetText(ScoreStr)
				
				--匪类
				ScoreStr = ScriptGlobal_Format( "#{LSHYH_150210_115}", g_1_FeiLei_num)
				Sancai_Image1Info4:SetText(ScoreStr)
				
				--都统
				ScoreStr = ScriptGlobal_Format( "#{LSHYH_150210_116}", g_1_DuTong_num)
				Sancai_Image1Info5:SetText(ScoreStr)
				
				--余毒
				ScoreStr = ScriptGlobal_Format( "#{LSHYH_150210_117}", g_1_YuDu_num)
				Sancai_Image1Info6:SetText(ScoreStr)
				
			elseif g_Current_ParaGraph == 2 then
				Sancai_BK2:Show()
				Sancai_BK1:Hide()
				Sancai_BK3:Hide()
				
				--红熊
				ScoreStr = ScriptGlobal_Format( "#{LSHYH_150210_119}", g_2_HongXiong_num)
				Sancai_Image2Info2:SetText(ScoreStr)
				
				--红熊王
				ScoreStr = ScriptGlobal_Format( "#{LSHYH_150210_120}", g_2_HongXiong_Boss_num)
				Sancai_Image2Info3:SetText(ScoreStr)

			elseif g_Current_ParaGraph == 3 then
				Sancai_BK3:Show()
				Sancai_BK2:Hide()
				Sancai_BK1:Hide()
				
				--葛荣
				ScoreStr = ScriptGlobal_Format( "#{LSHYH_150210_122}", g_3_GeRong_num)
				Sancai_Image3Info2:SetText(ScoreStr)
			end
		else
			PushEvent( "3HUAN_OPEN_UI_MINI", 1, g_Current_ParaGraph )
		end

end

function Sancai_ResetPos()
	Sancai_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition_Sancai);
	Sancai_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition_Sancai);
end

function Sancai_Frame_Mini_Clicked()
	this:Hide()
	PushEvent( "3HUAN_OPEN_UI_MINI", 1, g_Current_ParaGraph )
end