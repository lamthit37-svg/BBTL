local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_Current_ParaGraph = 1
local ScoreStr

local g_1_NiuQi_num = 0
local g_1_NiuQu_num = 0
local g_1_WangYan_num = 0
local g_1_TuFei_num = 0

local g_2_SiFengMo_num = 0
local g_2_LieDiXingZhe_num = 0
local g_2_WuDuMoShi_num = 0
local g_2_WuXuanJiang_num = 0
local g_2_PoYanZunZhe_num = 0
local g_2_HongJiYaoWang_num = 0

local g_3_HuoYanYaoMo_num = 0

function Yanmoshan_PreLoad()

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("YANMOSHAN_OPEN_MINI")
	this:RegisterEvent("YANMOSHAN_OPEN_RESULT")

end

function Yanmoshan_OnLoad()
	-- 保存界面的默认相对位置
	Yanmoshan_BK1:Hide()
	Yanmoshan_BK2:Hide()
	Yanmoshan_BK3:Hide()
end

function Yanmoshan_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Yanmoshan_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		Yanmoshan_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then

		this:Hide()
		Yanmoshan_BK1:Hide()
		Yanmoshan_BK2:Hide()
		Yanmoshan_BK3:Hide()
		 g_1_NiuQi_num = 0
		 g_1_NiuQu_num = 0
		 g_1_WangYan_num = 0
		 g_1_TuFei_num = 0

		 g_2_SiFengMo_num = 0
		 g_2_LieDiXingZhe_num = 0
		 g_2_WuDuMoShi_num = 0
		 g_2_WuXuanJiang_num = 0
		 g_2_PoYanZunZhe_num = 0
		 g_2_HongJiYaoWang_num = 0

		 g_3_HuoYanYaoMo_num = 0

		 g_Current_ParaGraph = 1
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20150401 ) then
		g_Current_ParaGraph = tonumber(Get_XParam_INT(1))
		PushEvent("YANMOSHAN_OPEN_RESULT",  0 )
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20150402 ) then
	--刷数据
			g_Current_ParaGraph = tonumber(Get_XParam_INT(1))
			local ListNum	 = tonumber(Get_XParam_INT(2))
			local KilledNum  = tonumber(Get_XParam_INT(3))

			if g_Current_ParaGraph ==  1 then
			--阶段一
				if ListNum == 3 then
				--niuqi --牛曲 --土匪
				--之前ListNum分别是1、2、3  后来龙门出现了一个问题，如果这三种怪一起挂了，UICommand只同步一个
				--因此，最后决定第一阶段的UICommand同步三种怪
					g_1_TuFei_num  = KilledNum
					g_1_NiuQi_num	 = tonumber(Get_XParam_INT(4))
					g_1_NiuQu_num 	 = tonumber(Get_XParam_INT(5))
				elseif ListNum == 4 then
					g_1_WangYan_num  = KilledNum
				end
			elseif g_Current_ParaGraph ==  2 then
			--阶段二
				if ListNum == 1 then
					g_2_SiFengMo_num   = KilledNum
				elseif ListNum == 2 then
					g_2_LieDiXingZhe_num  = KilledNum
				elseif ListNum == 3 then
					g_2_WuDuMoShi_num   = KilledNum
				elseif ListNum == 4 then
					g_2_WuXuanJiang_num   = KilledNum
				elseif ListNum == 5 then
					g_2_PoYanZunZhe_num   = KilledNum
				elseif ListNum == 6 then
					g_2_HongJiYaoWang_num   = KilledNum
				end
			elseif g_Current_ParaGraph == 3 then
			--阶段三
				g_3_HuoYanYaoMo_num  = KilledNum
			end

			Yanmoshan_RefreshData()
	elseif( event == "YANMOSHAN_OPEN_MINI" ) then
	--打开Mini
		this:Hide()
	elseif (event == "YANMOSHAN_OPEN_RESULT" ) then
	--打开大UI

		if (this:IsVisible()) then
		else
			this:Show()
		end
		Yanmoshan_RefreshData()
	end
end

--================================================
-- 填充数据
--================================================
function Yanmoshan_RefreshData( )

		if (this:IsVisible())   then
			if g_Current_ParaGraph == 1 then
				Yanmoshan_BK1:Show()
				Yanmoshan_BK2:Hide()
				Yanmoshan_BK3:Hide()

				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_115}", g_1_TuFei_num)
				Yanmoshan_Image1Info2:SetText(ScoreStr)

				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_116}", g_1_NiuQu_num)
				Yanmoshan_Image1Info3:SetText(ScoreStr)
				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_117}", g_1_NiuQi_num)
				Yanmoshan_Image1Info4:SetText(ScoreStr)

				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_118}", g_1_WangYan_num)
				Yanmoshan_Image1Info5:SetText(ScoreStr)



			elseif g_Current_ParaGraph == 2 then
				Yanmoshan_BK2:Show()
				Yanmoshan_BK1:Hide()
				Yanmoshan_BK3:Hide()


				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_120}", g_2_SiFengMo_num )
				Yanmoshan_Image2Info2:SetText(ScoreStr)
				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_121}", g_2_LieDiXingZhe_num )
				Yanmoshan_Image2Info3:SetText(ScoreStr)
				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_122}", g_2_WuDuMoShi_num )
				Yanmoshan_Image2Info4:SetText(ScoreStr)
				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_123}", g_2_WuXuanJiang_num )
				Yanmoshan_Image2Info5:SetText(ScoreStr)
				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_124}", g_2_PoYanZunZhe_num )
				Yanmoshan_Image2Info6:SetText(ScoreStr)
				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_125}", g_2_HongJiYaoWang_num )
				Yanmoshan_Image2Info7:SetText(ScoreStr)

			elseif g_Current_ParaGraph == 3 then
				Yanmoshan_BK3:Show()
				Yanmoshan_BK2:Hide()
				Yanmoshan_BK1:Hide()

				ScoreStr = ScriptGlobal_Format( "#{XSHYH_150211_127}", g_3_HuoYanYaoMo_num )
				Yanmoshan_Image3Info2:SetText(ScoreStr)

			end
		end

end


--================================================
-- 恢复界面的默认相对位置
--================================================
function Yanmoshan_ResetPos()
	Yanmoshan_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Yanmoshan_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Yanmoshan_Closed()
	this:Hide()
	PushEvent( "YANMOSHAN_OPEN_MINI", 1 )
end
