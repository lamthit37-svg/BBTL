--******************************************************************************
--
-- 门派进阶
--
--******************************************************************************

--门派对应技能显示图标
local SkllImage = {
	[0] = {
			[1] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_15", skillname = "#{BianshenSkill2_15}"} ,
			[2] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_2", skillname = "#{BianshenSkill3_2}"} ,
			[3] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_16", skillname = "#{BianshenSkill2_16}"} ,
			[4] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_3", skillname = "#{BianshenSkill3_3}"} ,
			[5] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_1", skillname = "#{BianshenSkill3_1}"}
		  },
	[1] = {
	        [1] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_4", skillname = "#{BianshenSkill3_4}"} ,
			[2] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_7", skillname = "#{BianshenSkill3_7}"} ,
			[3] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_6", skillname = "#{BianshenSkill3_6}"} ,
			[4] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_8", skillname = "#{BianshenSkill3_8}"} ,
			[5] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_5", skillname = "#{BianshenSkill3_5}"}
	      },
	[2] = {
			[1] = {iconname = "set:BianshenSkill image:BianshenSkill_5", skillname = "#{BianshenSkill_5}"} ,
			[2] = {iconname = "set:BianshenSkill image:BianshenSkill_6", skillname = "#{BianshenSkill_6}"} ,
			[3] = {iconname = "set:BianshenSkill image:BianshenSkill_7", skillname = "#{BianshenSkill_7}"} ,
			[4] = {iconname = "set:BianshenSkill image:BianshenSkill_8", skillname = "#{BianshenSkill_8}"}
		  },
	[3] = {
	        [1] = {iconname = "set:BianshenSkill image:BianshenSkill_9", skillname = "#{BianshenSkill_9}"} ,
			[2] = {iconname = "set:BianshenSkill image:BianshenSkill_10", skillname = "#{BianshenSkill_10}"} ,
			[3] = {iconname = "set:BianshenSkill image:BianshenSkill_11", skillname = "#{BianshenSkill_11}"} ,
			[4] = {iconname = "set:BianshenSkill image:BianshenSkill_12", skillname = "#{BianshenSkill_12}"}
	      },
	[4] = {
			[1] = {iconname = "set:BianshenSkill image:BianshenSkill_13", skillname = "#{BianshenSkill_13}"} ,
			[2] = {iconname = "set:BianshenSkill image:BianshenSkill_14", skillname = "#{BianshenSkill_14}"} ,
			[3] = {iconname = "set:BianshenSkill image:BianshenSkill_15", skillname = "#{BianshenSkill_15}"} ,
			[4] = {iconname = "set:BianshenSkill image:BianshenSkill_16", skillname = "#{BianshenSkill_16}"}
          },
	[5] = {
	        [1] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_1", skillname = "#{BianshenSkill2_1}"} ,
			[2] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_2", skillname = "#{BianshenSkill2_2}"} ,
			[3] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_3", skillname = "#{BianshenSkill2_3}"} ,
			[4] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_4", skillname = "#{BianshenSkill2_4}"} ,
			[5] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_5", skillname = "#{BianshenSkill2_5}"}
	      },
	[6] = {
	        [1] = {iconname = "set:FightSkillDaLi image:FightSkillDaLi_1", skillname = "#{FightSkillDaLi_1}"} ,
			[2] = {iconname = "set:FightSkillDaLi image:FightSkillDaLi_7", skillname = "#{FightSkillDaLi_7}"} ,
			[3] = {iconname = "set:FightSkillDaLi1 image:FightSkillDaLi1_3", skillname = "#{FightSkillDaLi1_3}"} ,
			[4] = {iconname = "set:FightSkillDaLi image:FightSkillDaLi_3", skillname = "#{FightSkillDaLi_3}"} ,
			[5] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_3", skillname = "#{BianshenSkill3_3TL}"}
	      },
	[7] = {
	        [1] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_6", skillname = "#{BianshenSkill2_6}"} ,
			[2] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_7", skillname = "#{BianshenSkill2_7}"} ,
			[3] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_8", skillname = "#{BianshenSkill2_8}"} ,
			[4] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_9", skillname = "#{BianshenSkill2_9}"} ,
			[5] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_10", skillname = "#{BianshenSkill2_10}"}
	      },
	[8] = {
	        [1] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_11", skillname = "#{BianshenSkill2_11}"} ,
			[2] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_12", skillname = "#{BianshenSkill2_12}"} ,
			[3] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_13", skillname = "#{BianshenSkill2_13}"} ,
			[4] = {iconname = "set:BianshenSkill2 image:BianshenSkill2_14", skillname = "#{BianshenSkill2_14}"}
	      },
	[10] = {
	        [1] = {iconname = "set:FightSkillShaoLin1 image:FightSkillShaoLin1_1", skillname = "#{FightSkillShaoLin1_1}"} ,
			[2] = {iconname = "set:FightSkillMingJiao1 image:FightSkillMingJiao1_9", skillname = "#{FightSkillMingJiao1_9}"} ,
			[3] = {iconname = "set:FightSkillWuDang2 image:FightSkillWuDang2_5", skillname = "#{FightSkillWuDang2_5}"} ,
			[4] = {iconname = "set:FightSkillEMei2 image:FightSkillEMei2_5", skillname = "#{FightSkillEMei2_5}"},
			[5] = {iconname = "set:FightSkillTianShan1 image:FightSkillTianShan1_2", skillname = "#{FightSkillTianShan1_2}"}
	      },
	[11] = {
			[1] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_11", skillname = "#{MPJJRW_130801_17}"} ,
			[2] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_12", skillname = "#{MPJJRW_130801_18}"},
	        [3] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_9", skillname = "#{MPJJRW_130801_15}"} ,
			[4] = {iconname = "set:BianshenSkill3 image:BianshenSkill3_10", skillname = "#{MPJJRW_130801_16}"} ,
	      },
	[12] = {
			[1] = {iconname = "set:BianshenSkill4 image:BianshenSkill4_2", skillname = "#{GGJJ_160606_148}"} ,
			[2] = {iconname = "set:BianshenSkill4 image:BianshenSkill4_3", skillname = "#{GGJJ_160606_149}"},
	        [3] = {iconname = "set:BianshenSkill4 image:BianshenSkill4_4", skillname = "#{GGJJ_160606_150}"} ,
			[4] = {iconname = "set:BianshenSkill4 image:BianshenSkill4_5", skillname = "#{GGJJ_160606_151}"} ,
	      },
	[13] = { --桃花岛
			[1] = {iconname = "set:FightSkillTaoHuaDao image:FightSkillTaoHuaDao_5", skillname = "#{THJJ_190724_37}"} ,
			[2] = {iconname = "set:FightSkillTaoHuaDao image:FightSkillTaoHuaDao_4", skillname = "#{THJJ_190724_38}"},
	        [3] = {iconname = "set:FightSkillTaoHuaDao image:FightSkillTaoHuaDao_2", skillname = "#{THJJ_190724_39}"} ,
			[4] = {iconname = "set:FightSkillTaoHuaDao image:FightSkillTaoHuaDao_1", skillname = "#{THJJ_190724_40}"} ,
	      },
	[14] = { 
			[1] = {iconname = "set:Menpaijinjie3 image:Menpaijinjie3_13", 	skillname = "#{SSMPJJ_210603_37}"} ,
			[2] = {iconname = "set:Menpaijinjie3 image:Menpaijinjie3_14", 	skillname = "#{SSMPJJ_210603_38}"},
	        [3] = {iconname = "set:Menpaijinjie3 image:Menpaijinjie3_15", 	skillname = "#{SSMPJJ_210603_39}"} ,
			[4] = {iconname = "set:Menpaijinjie3 image:Menpaijinjie3_16",	skillname = "#{SSMPJJ_210603_40}"} ,
	      },
	[15] = { --menpai15 mptodo --新门派-恶人谷-ypl-门派进阶任务
			[1] = {iconname = "set:FightSkillERenGu2 image:FightSkillERenGu2_13", 	skillname = "#{ERGJJ_240710_35}"} ,
			[2] = {iconname = "set:FightSkillERenGu2 image:FightSkillERenGu2_12", 	skillname = "#{ERGJJ_240710_36}"},
	        [3] = {iconname = "set:FightSkillERenGu2 image:FightSkillERenGu2_11", 	skillname = "#{ERGJJ_240710_37}"} ,
			[4] = {iconname = "set:FightSkillERenGu2 image:FightSkillERenGu2_14 ",	skillname = "#{ERGJJ_240710_38}"} ,
	      }
}

function JinJieRenWu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end

function JinJieRenWu_OnLoad()

end

function JinJieRenWu_OnEvent( event )
	if event == "UI_COMMAND" and tonumber(arg0) == 20110888 then
		if Get_XParam_INT(0) == 0 then
			this:Hide()
		elseif Get_XParam_INT(0) == 1 then
			this:Show()
			local op = Get_XParam_INT(1)
			local nmenpai = Get_XParam_INT(2)
			if SkllImage[nmenpai] ~= nil and op >= 1 and op <= table.getn(SkllImage[nmenpai]) then
				local tmpdic = SkllImage[nmenpai]
				local ttttips = string.format("#{MPJJRW_110805_37}%s#{MPJJRW_110805_38}#{MPJJRW_110805_39}",tmpdic[op].skillname)
				--JinJieRenWu_Info:SetText(tmpdic[op].skillname .. "#{MPJJRW_110805_39}")
				JinJieRenWu_Info:SetText(ttttips)
				JinJieRenWu_Object:SetProperty("Image" , tmpdic[op].iconname)
			end
			JinJieRenWu_Jishi:SetProperty("Timer","5")
		end
	end
end

function JinJieRenWu_Jishi_TimeReach()
	JinJieRenWu_Jishi:SetProperty("Timer","0")
	this:Hide()
end

function JinJieRenWu_OnCloseClicked()
	this:Hide()
end
