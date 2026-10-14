
local g_JieBaiZF_Skill = {}
local g_JieBaiZF_SkillAction = {}
local g_JieBaiZF_Property = {}
local g_JieBaiZF_LevelupButton = {}
local g_JieBaiZF_Levelstr = {}
local g_JieBaiZF_AttrStr = {}
local g_JieBaiZF_DisTips = {}
local g_JieBaiZF_ForgetButton = {}
local g_JieBaiZF_UnifiedPosition = nil

local g_JieBaiZF_SkillName = {"#{JBGXW_150526_138}","#{JBGXW_150526_139}","#{JBGXW_150526_140}","#{JBGXW_150526_141}"}
function JieBaiZF_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SKILL_UPDATE");
	this:RegisterEvent("UPDATA_ZHENFAINFO")
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UPDATE_BROTHERSHIP");
	
end

function JieBaiZF_OnLoad()

	g_JieBaiZF_UnifiedPosition = JieBaiZF_Frame:GetProperty("UnifiedPosition")
	g_JieBaiZF_Skill[1] = 3229
	g_JieBaiZF_Skill[2] = 3250
	g_JieBaiZF_Skill[3] = 3251
	g_JieBaiZF_Skill[4] = 3252
	
	g_JieBaiZF_SkillAction[1] = JieBaiZF_BK1_Zhen01_Skill1
	g_JieBaiZF_SkillAction[2] = JieBaiZF_BK1_Zhen02_Skill1
	g_JieBaiZF_SkillAction[3] = JieBaiZF_BK1_Zhen03_Skill1
	g_JieBaiZF_SkillAction[4] = JieBaiZF_BK1_Zhen04_Skill1
	
	-- g_JieBaiZF_Property[1] = JieBaiZF_Perporty1;
	-- g_JieBaiZF_Property[2] = JieBaiZF_Perporty2;
	-- g_JieBaiZF_Property[3] = JieBaiZF_Perporty3;
	-- g_JieBaiZF_Property[4] = JieBaiZF_Perporty4;
	-- g_JieBaiZF_Property[5] = JieBaiZF_Perporty5;
	
	g_JieBaiZF_LevelupButton[1] = JieBaiZF_BK1_Zhen01_Button1
	g_JieBaiZF_LevelupButton[2] = JieBaiZF_BK1_Zhen02_Button1
	g_JieBaiZF_LevelupButton[3] = JieBaiZF_BK1_Zhen03_Button1
	g_JieBaiZF_LevelupButton[4] = JieBaiZF_BK1_Zhen04_Button1
	g_JieBaiZF_DisTips[1] = JieBaiZF_BK1_Zhen01_Tips1
	g_JieBaiZF_DisTips[2] = JieBaiZF_BK1_Zhen02_Tips1
	g_JieBaiZF_DisTips[3] = JieBaiZF_BK1_Zhen03_Tips1
	g_JieBaiZF_DisTips[4] = JieBaiZF_BK1_Zhen04_Tips1
	
	g_JieBaiZF_ForgetButton[1] =JieBaiZF_BK1_Zhen01_Button2
	g_JieBaiZF_ForgetButton[2] =JieBaiZF_BK1_Zhen02_Button2
	g_JieBaiZF_ForgetButton[3] =JieBaiZF_BK1_Zhen03_Button2
	g_JieBaiZF_ForgetButton[4] =JieBaiZF_BK1_Zhen04_Button2
	g_JieBaiZF_Levelstr[0] = "#{JBGXW_150526_98}"
	g_JieBaiZF_Levelstr[18] = "#{JBGXW_150526_99}"
	g_JieBaiZF_Levelstr[26] = "#{JBGXW_150526_100}"
	g_JieBaiZF_Levelstr[36] = "#{JBGXW_150526_101}"
	g_JieBaiZF_Levelstr[48] = "#{JBGXW_150526_102}"
	g_JieBaiZF_Levelstr[62] = "#{JBGXW_150526_103}"
	g_JieBaiZF_Levelstr[78] = "#{JBGXW_150526_104}"
	g_JieBaiZF_Levelstr[96] = "#{JBGXW_150526_105}"
	g_JieBaiZF_Levelstr[116] = "#{JBGXW_150526_106}"
	g_JieBaiZF_Levelstr[138] = "#{JBGXW_150526_107}"
	g_JieBaiZF_Levelstr[162] = "#{JBGXW_150526_108}"
	
	g_JieBaiZF_AttrStr[1] = {jifen=1500,str="#{JBGXW_150526_172}"}
	g_JieBaiZF_AttrStr[2] = {jifen=3000,str="#{JBGXW_150526_173}"}
	g_JieBaiZF_AttrStr[3] = {jifen=4500,str="#{JBGXW_150526_174}"}
	g_JieBaiZF_AttrStr[4] = {jifen=6000,str="#{JBGXW_150526_175}"}
	g_JieBaiZF_AttrStr[5] = {jifen=9000,str="#{JBGXW_150526_176}"}
	g_JieBaiZF_AttrStr[6] = {jifen=13500,str="#{JBGXW_150526_177}" }
	g_JieBaiZF_AttrStr[7] = {jifen=18000,str="#{JBGXW_150526_178}"}
	g_JieBaiZF_AttrStr[8] = {jifen=24000,str="#{JBGXW_150526_179}"}
	g_JieBaiZF_AttrStr[9] = {jifen=30000,str="#{JBGXW_150526_180}"}
	g_JieBaiZF_AttrStr[10] = {jifen=37500,str="#{JBGXW_150526_181}"}
	g_JieBaiZF_AttrStr[11] = {jifen=45000,str="#{JBGXW_150526_182}"}
	g_JieBaiZF_AttrStr[12] = {jifen=54000,str="#{JBGXW_150526_183}"}
	g_JieBaiZF_AttrStr[13] = {jifen=63000,str="#{JBGXW_150526_184}"}
	g_JieBaiZF_AttrStr[14] = {jifen=73500,str="#{JBGXW_150526_185}"}
	g_JieBaiZF_AttrStr[15] = {jifen=84000,str="#{JBGXW_150526_186}"}
	g_JieBaiZF_AttrStr[16] = {jifen=96000,str="#{JBGXW_150526_187}"}
	g_JieBaiZF_AttrStr[17] = {jifen=108000,str="#{JBGXW_150526_188}"}
	g_JieBaiZF_AttrStr[18] = {jifen=121500,str="#{JBGXW_150526_189}"}
	g_JieBaiZF_AttrStr[19] = {jifen=135000,str="#{JBGXW_150526_190}"}
	g_JieBaiZF_AttrStr[20] = {jifen=150000,str="#{JBGXW_150526_191}"}
	
end

function JieBaiZF_OnEvent(event)

	if (event == "UI_COMMAND") then
		if (tonumber(arg0) == 20150608) then
			JieBaiZF_UpdataSkill()
			JieBaiZF_SetFreamInfo()
			this:Show()
			
			CloseFreshManGuide()
			
			if DataPool:Lua_IsHaveMission(1361) > 0 and DataPool:Lua_IsMissionHaveDone(1361) <= 0 then
				--结拜引导任务 显示tips 
				local fX, fY = this:GetChildOffset("JieBaiZF_BK1_Zhen02")
	    	OpenFreshManGuide(1, 79, fX, fY, "JieBaiZF", "northwest")
				SetTimer("JieBaiZF", "CloseFreshManGuide()", 10000)
				
				--通知服务器任务完成
				Clear_XSCRIPT();
						Set_XSCRIPT_Function_Name("ComMission");
						Set_XSCRIPT_ScriptID(891318);
						Set_XSCRIPT_ParamCount(1);
				Send_XSCRIPT();	

			end
			if DataPool:Lua_IsHaveMission(1362) > 0 and DataPool:Lua_IsMissionHaveDone(1362) <= 0 then
				--结拜引导任务 显示tips 
				local fX, fY = this:GetChildOffset("JieBaiZF_BK_QingYi")
	    	OpenFreshManGuide(1, 78, fX+120, fY, "JieBaiZF", "northwest")
				SetTimer("JieBaiZF", "CloseFreshManGuide()", 10000)
				
				local temp1,temp2,temp3,temp4 = Player:GetData("ZHENFAINFO")
				local zhenfainfo = {temp1,temp2,temp3,temp4}
				for i = 1, 4 do
					local level = JieBaiZF_DecoZhenFaInfo(zhenfainfo[i])
					if level >= 1 then
						--通知服务器任务完成
						Clear_XSCRIPT();
								Set_XSCRIPT_Function_Name("ComMission");
								Set_XSCRIPT_ScriptID(891319);
								Set_XSCRIPT_ParamCount(1);
						Send_XSCRIPT();	
						return
					end
				end
			end
		end
	elseif (event == "SKILL_UPDATE") then
		JieBaiZF_UpdataSkill()
	elseif (event == "UPDATA_ZHENFAINFO") then
		if this:IsVisible() then
			JieBaiZF_SetFreamInfo()
		end
	elseif (event == "ADJEST_UI_POS") or (event == "VIEW_RESOLUTION_CHANGED") then
		JieBaiZF_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "UPDATE_BROTHERSHIP" and this:IsVisible() ) then
		JieBaiZF_Updataqingyi()
	end
end

function JieBaiZF_Updataqingyi()
		local bsNum = Player:GetBrotherShip()
		JieBaiZF_BK_QingYi_Num:SetText("#G"..bsNum)
		local wbsNum = Player:GetWeekBrotherShip()
		JieBaiZF_BK_ZhouQingYi_Num:SetText("#G"..wbsNum.."/1500")
end

function JieBaiZF_ResetPos()
	JieBaiZF_Frame:SetProperty("UnifiedPosition",g_JieBaiZF_UnifiedPosition)
end

function JieBaiZF_QueryLevelup(index)

		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("QueryLevel");
			Set_XSCRIPT_ScriptID(891175);
			Set_XSCRIPT_Parameter(0,index);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();	
end


function JieBaiZF_Forget(index)

		--是否可以遗忘
		--判断电话密保和二级密码保护
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
			return
		end
		-- 判断是否为安全时间
		if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
			PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
			return
		end		
		
		--情义值是否已经达到最大值
		local bsNum = Player:GetBrotherShip()
		local maxnum = 150000
		if bsNum >= maxnum then
			PushDebugMessage("#{JLZFYW_151123_15}")
			return
		end		
		
		local temp1,temp2,temp3,temp4 = Player:GetData("ZHENFAINFO")
		local zhenfainfo = {temp1,temp2,temp3,temp4}
		local level = JieBaiZF_DecoZhenFaInfo(zhenfainfo[index+1])
		
		if level <= 0 then
			local errorstr = ScriptGlobal_Format("#{JLZFYW_151123_7}",g_JieBaiZF_SkillName[index+1])
			PushDebugMessage( errorstr )		
		end
		
		--二次确认
		PushEvent("ZHENFA_FORGET_CONFIRM",index)
		
		-- Clear_XSCRIPT();
			-- Set_XSCRIPT_Function_Name("ForgetZF");
			-- Set_XSCRIPT_ScriptID(891175);
			-- Set_XSCRIPT_Parameter(0,index);
			-- Set_XSCRIPT_ParamCount(1);
		-- Send_XSCRIPT();	
end

function JieBaiZF_UpdataSkill()

	local temp1,temp2,temp3,temp4 = Player:GetData("ZHENFAINFO")
	local zhenfainfo = {temp1,temp2,temp3,temp4}
	for i = 1, 4 do
		local level = JieBaiZF_DecoZhenFaInfo(zhenfainfo[i])
		-- if level == 0 then
			for i = 1, table.getn(g_JieBaiZF_Skill) do
				local thetempAction = EnumAction(g_JieBaiZF_Skill[i], "zhenfaskill");
				if thetempAction ~= nil then
					g_JieBaiZF_SkillAction[i] : SetActionItem(thetempAction : GetID())
					
				end		
			end
		-- end
	end
	local nSumSkill = GetActionNum("skill");
	for i = 1, nSumSkill do
		local thetempAction = EnumAction(i, "skill");
		local temp = thetempAction:GetID();
		local nCommonId = LifeAbility : GetLifeAbility_Number(temp);
		if nCommonId ~=nil and nCommonId > 0 then
		
			for i = 1, 4 do
				if g_JieBaiZF_Skill[i] == nCommonId then
					g_JieBaiZF_SkillAction[i] : SetActionItem(thetempAction : GetID())
				end
			end			
		end
	end
	

end


function JieBaiZF_SetFreamInfo()

		
		if Lua_IsChangeBroship() > 0 then
			JieBaiZF_BK_QingYi:SetToolTip("#{XDJB_0401_05}")
			JieBaiZF_BK_QingYi_Num:SetToolTip("#{XDJB_0401_05}")
		else
			JieBaiZF_BK_QingYi:SetToolTip("#{JBGXW_150526_11}")
			JieBaiZF_BK_QingYi_Num:SetToolTip("#{JBGXW_150526_11}")
		end		
		local bsNum = Player:GetBrotherShip()
		JieBaiZF_BK_QingYi_Num:SetText("#G"..bsNum)
		local wbsNum = Player:GetWeekBrotherShip()
		JieBaiZF_BK_ZhouQingYi_Num:SetText("#G"..wbsNum.."/1500")
		local totaljifen = Player:GetZhenFaTotalpoint()
		
		
		local temp1,temp2,temp3,temp4 = Player:GetData("ZHENFAINFO")
		local zhenfainfo = {temp1,temp2,temp3,temp4}
		JieBaiZF_BK1_Zhen01_Text2:SetText(JieBaiZF_DecoZhenFaDesc(temp1))
		JieBaiZF_BK1_Zhen02_Text2:SetText(JieBaiZF_DecoZhenFaDesc(temp2))
		JieBaiZF_BK1_Zhen03_Text2:SetText(JieBaiZF_DecoZhenFaDesc(temp3))
		JieBaiZF_BK1_Zhen04_Text2:SetText(JieBaiZF_DecoZhenFaDesc(temp4))
		
		local attrnum,nextjifen = JieBaiZF_GetZhenFaAttr(totaljifen);
		JieBaiZF_BK_JiFen_Num:SetText("#G"..totaljifen)
		if attrnum == 162 then
			JieBaiZF_BK_JiFen:SetToolTip("#{JBGXW_150526_114}")
			JieBaiZF_BK_JiFen_Num:SetToolTip("#{JBGXW_150526_114}")
		else			
			local str = "#{JBGXW_150526_15}"
			JieBaiZF_BK_JiFen:SetToolTip(str)
			JieBaiZF_BK_JiFen_Num:SetToolTip(str)
		end
		JieBaiZF_BK3:RemoveAllItem()
		for i = 1,20 do
			if totaljifen >= g_JieBaiZF_AttrStr[i].jifen then
				JieBaiZF_BK3:AddNewItem(" #cfff263"..g_JieBaiZF_AttrStr[i].jifen,0,i-1)
				JieBaiZF_BK3:AddNewItem("#cfff263"..g_JieBaiZF_AttrStr[i].str,1,i-1)
			else
				JieBaiZF_BK3:AddNewItem(" #c808080"..g_JieBaiZF_AttrStr[i].jifen,0,i-1)
				JieBaiZF_BK3:AddNewItem("#c808080"..g_JieBaiZF_AttrStr[i].str,1,i-1)			
			end
		
		end
		--tips设置
		JieBaiZF_BK1_Zhen01_Button1:SetToolTip(JieBaiZF_DecoZhenFaTips(temp1))
		JieBaiZF_BK1_Zhen02_Button1:SetToolTip(JieBaiZF_DecoZhenFaTips(temp2))
		JieBaiZF_BK1_Zhen03_Button1:SetToolTip(JieBaiZF_DecoZhenFaTips(temp3))
		JieBaiZF_BK1_Zhen04_Button1:SetToolTip(JieBaiZF_DecoZhenFaTips(temp4))
		
		for i = 1, 4 do
			JieBaiZF_SetButtonState(i, zhenfainfo[i],bsNum);		
			g_JieBaiZF_DisTips[i]:SetToolTip(JieBaiZF_DecoZhenFaTips(zhenfainfo[i]))
		end
		
		
end

function JieBaiZF_SetButtonState(index, nData, bsNum)
	local level = JieBaiZF_DecoZhenFaInfo(nData)
	if level == 100 then
		g_JieBaiZF_LevelupButton[index]:Disable()
		return
	end
	
		g_JieBaiZF_ForgetButton[index]:Enable()
		g_JieBaiZF_ForgetButton[index]:SetToolTip("#{JLZFYW_151123_1}")
	if level == 0 then
		g_JieBaiZF_ForgetButton[index]:Disable()
	end
		
	local nExp, nMoney, nqingyi = Player:GetZhenFaDemand(level)
	if nqingyi > bsNum then
		g_JieBaiZF_LevelupButton[index]:Disable()
		return
	end
	
	g_JieBaiZF_LevelupButton[index]:Enable()
end

function JieBaiZF_GetZhenFaAttr(totaljifen)
	if(totaljifen < 0) then
		return 0,1500;
	elseif totaljifen>=0 and totaljifen < 150000 then
		return 0,1500;
	else
		return 162,0;
	end
end


function JieBaiZF_DecoZhenFaInfo(info)
	advance = math.floor(info/1000)
	level = math.mod(info,1000)
	return level, advance
end

function JieBaiZF_DecoZhenFaDesc(info)
	advance  = math.floor(tonumber(info)/1000)
	level	 = math.mod(tonumber(info),1000)
	if level == 100 then
		return "#{JBGXW_150526_145}"
	else
		return advance.."阶"..(level-advance*10).."级"
	end
end

function JieBaiZF_DecoZhenFaTips(info)
	advance  = math.floor(tonumber(info)/1000)
	level	 = math.mod(tonumber(info),1000)
	if level == 100 then
		return "#{JBGXW_150526_8}"
	end
	local nExp, nMoney, nqingyi = Player:GetZhenFaDemand(level)
	local badvance = math.mod(tonumber(level),10)
	if badvance == 9 then		
		return ScriptGlobal_Format("#{JBGXW_150526_7}",math.floor(tonumber(nMoney)),nExp )
	else
		return ScriptGlobal_Format("#{JBGXW_150526_6}",nqingyi,math.floor(tonumber(nMoney)),nExp )
	end

end
function JieBaiZF_Close()
	this:Hide()
end

function JieBaiZF_Jieshao()
	PushEvent("ZHENFA_DESC")
end