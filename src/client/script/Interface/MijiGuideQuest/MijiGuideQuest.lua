-- 武林秘籍新手引导任务QTE
-- MijiGuideQuest / MijiGuideQuest.lua
-- PushDebugMessage()
--------------------------------------------------------------------------------------------------

-- 秘籍技能图标
local mijiSkillIcom = {
	[2500] = {iconname = "set:FightSkillTianShan image:FightSkillTianShan_3"} ,
	[2501] = {iconname = "set:FightSkillTianShan image:FightSkillTianShan_2"} ,
	[2502] = {iconname = "set:FightSkillTianShan1 image:FightSkillTianShan1_6"} ,
	[2503] = {iconname = "set:FightSkillMingJiao image:FightSkillMingJiao_3"} ,
	[2504] = {iconname = "set:FightSkillMingJiao image:FightSkillMingJiao_2"} ,
	[2505] = {iconname = "set:FightSkillMingJiao1 image:FightSkillMingJiao1_6"} ,
	[2506] = {iconname = "set:FightSkillShaoLin1 image:FightSkillShaoLin1_3"} ,
	[2507] = {iconname = "set:FightSkillShaoLin1 image:FightSkillShaoLin1_2"} ,
	[2508] = {iconname = "set:FightSkillShaoLin2 image:FightSkillShaoLin2_6"} ,
	[2509] = {iconname = "set:FightSkillGaiBang1 image:FightSkillGaiBang1_3"} ,
	[2510] = {iconname = "set:FightSkillGaiBang1 image:FightSkillGaiBang1_2"} ,
	[2511] = {iconname = "set:FightSkillGaiBang image:FightSkillGaiBang_6"} ,
	[2512] = {iconname = "set:MiJiSkill3 image:MiJiSkill3_14"} ,
	[2513] = {iconname = "set:MiJiSkill3 image:MiJiSkill3_15"} ,
	[2514] = {iconname = "set:MiJiSkill3 image:MiJiSkill3_16"} ,
	[2515] = {iconname = "set:FightSkillEMei1 image:FightSkillEMei1_2"} ,
	[2516] = {iconname = "set:FightSkillEMei1 image:FightSkillEMei1_3"} ,
	[2517] = {iconname = "set:FightSkillEMei1 image:FightSkillEMei1_4"} ,
	[2518] = {iconname = "set:FightSkillXiaoYao image:FightSkillXiaoYao_2"} ,
	[2519] = {iconname = "set:FightSkillXiaoYao image:FightSkillXiaoYao_3"} ,
	[2520] = {iconname = "set:FightSkillXiaoYao image:FightSkillXiaoYao_4"} ,
	[2521] = {iconname = "set:FightSkillWuDang1 image:FightSkillWuDang1_2"} ,
	[2522] = {iconname = "set:FightSkillWuDang1 image:FightSkillWuDang1_3"} ,
	[2523] = {iconname = "set:FightSkillWuDang1 image:FightSkillWuDang1_4"} ,
	[2524] = {iconname = "set:FightSkillXinXiu1 image:FightSkillXinXiu1_2"} ,
	[2525] = {iconname = "set:FightSkillXinXiu1 image:FightSkillXinXiu1_3"} ,
	[2526] = {iconname = "set:FightSkillXinXiu1 image:FightSkillXinXiu1_4"} ,
	[2527] = {iconname = "set:FightSkillDaLi image:FightSkillDaLi_2"} ,
	[2528] = {iconname = "set:FightSkillDaLi image:FightSkillDaLi_3"} ,
	[2529] = {iconname = "set:FightSkillDaLi image:FightSkillDaLi_4"} ,
	[2530] = {iconname = "set:FightSkillDaLi image:FightSkillDaLi_5"} ,
	[2531] = {iconname = "set:FightSkillDaLi image:FightSkillDaLi_7"} ,
	[2532] = {iconname = "set:FightSkillDaLi2 image:FightSkillDaLi2_1"} ,
	[2533] = {iconname = "set:FightSkillWuDang1 image:FightSkillWuDang1_5"} ,
	[2534] = {iconname = "set:FightSkillWuDang1 image:FightSkillWuDang1_7"} ,
	[2535] = {iconname = "set:FightSkillWuDang1 image:FightSkillWuDang1_11"} ,
	[2536] = {iconname = "set:FightSkillTianShan image:FightSkillTianShan_5"} ,
	[2537] = {iconname = "set:FightSkillTianShan image:FightSkillTianShan_8"} ,
	[2538] = {iconname = "set:FightSkillTianShan1 image:FightSkillTianShan1_4"} ,
	[2539] = {iconname = "set:FightSkillShaoLin1 image:FightSkillShaoLin1_5"} ,
	[2540] = {iconname = "set:FightSkillXinXiu2 image:FightSkillXinXiu2_9"} ,
	[2541] = {iconname = "set:FightSkillXinXiu1 image:FightSkillXinXiu1_15"} ,
	[2542] = {iconname = "set:FightSkillGaiBang1 image:FightSkillGaiBang1_8"} ,
	[2543] = {iconname = "set:FightSkillMurong2 image:FightSkillMurong2_8"} ,
	[2544] = {iconname = "set:FightSkillWuDang2 image:FightSkillWuDang2_9"} ,
	[2545] = {iconname = "set:FightSkillTianShan image:FightSkillTianShan_9"} ,
	[2546] = {iconname = "set:FightSkillEMei2 image:FightSkillEMei2_5"} ,
	[2547] = {iconname = "set:FightSkillXiaoYao image:FightSkillXiaoYao_11"} ,
}

-- 秘籍技能图标
local mijiSkillTip = {

	[2500] = {Desc = ""} ,
	[2501] = {Desc = ""} ,
	[2502] = {Desc = ""} ,
	[2503] = {Desc = ""} ,
	[2504] = {Desc = ""} ,
	[2505] = {Desc = ""} ,
	[2506] = {Desc = ""} ,
	[2507] = {Desc = ""} ,
	[2508] = {Desc = ""} ,
	[2509] = {Desc = ""} ,
	[2510] = {Desc = ""} ,
	[2511] = {Desc = ""} ,
	[2512] = {Desc = "#{WLMJRW_20130226_104}"} ,
	[2513] = {Desc = "#{WLMJRW_20130226_105}"} ,
	[2514] = {Desc = "#{WLMJRW_20130226_106}"} ,
	[2515] = {Desc = ""} ,
	[2516] = {Desc = ""} ,
	[2517] = {Desc = ""} ,
	[2518] = {Desc = ""} ,
	[2519] = {Desc = ""} ,
	[2520] = {Desc = ""} ,
	[2521] = {Desc = ""} ,
	[2522] = {Desc = ""} ,
	[2523] = {Desc = ""} ,
	[2524] = {Desc = ""} ,
	[2525] = {Desc = ""} ,
	[2526] = {Desc = ""} ,
	[2527] = {Desc = ""} ,
	[2528] = {Desc = ""} ,
	[2529] = {Desc = ""} ,
	[2530] = {Desc = ""} ,
	[2531] = {Desc = ""} ,
	[2532] = {Desc = ""} ,
	[2533] = {Desc = ""} ,
	[2534] = {Desc = ""} ,
	[2535] = {Desc = ""} ,
	[2536] = {Desc = ""} ,
	[2537] = {Desc = ""} ,
	[2538] = {Desc = ""} ,
	[2539] = {Desc = ""} ,
	[2540] = {Desc = ""} ,
	[2541] = {Desc = ""} ,
	[2542] = {Desc = ""} ,
	[2543] = {Desc = ""} ,
	[2544] = {Desc = ""} ,
	[2545] = {Desc = ""} ,
	[2546] = {Desc = ""} ,
	[2547] = {Desc = ""} ,
}

function MijiGuideQuest_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end

function MijiGuideQuest_OnLoad()
end

function MijiGuideQuest_OnEvent( event )

	if ( event == "UI_COMMAND" and tonumber( arg0 ) == 20130221 ) then

		local bOpenUI = Get_XParam_INT( 0 );		-- 是否开启UI
		if ( bOpenUI == 1 ) then
			local mijiID = Get_XParam_INT( 1 );		-- 秘籍ID
			local nFlag, _, _, _ = DataPool : GetMiJiSkillInfo( mijiID );	-- 成功标识, 秘籍技能名称, 图标名称, 技能描述
			if ( nFlag ~= 1 ) then
				return
			end

			this:Show();																					-- 显示UI
			MijiGuideQuest_Info : SetText( mijiSkillTip[ mijiID ].Desc );									-- 描述信息
			MijiGuideQuest_Frame_Object_Icon : SetProperty( "Image", mijiSkillIcom[ mijiID ].iconname );	-- 图标
			MijiGuideQuest_Num : SetProperty( "Timer", "10" );												-- 倒计时
		else
			this:Hide();	-- 隐藏UI
		end

	end

end

function MijiGuideQuest_Jishi_TimeReach()
	MijiGuideQuest_Num:SetProperty("Timer","0")
	this:Hide()
end

function MijiGuideQuest_OnCloseClicked()
	this:Hide()
end
