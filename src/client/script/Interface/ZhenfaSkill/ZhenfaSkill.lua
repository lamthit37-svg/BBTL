local g_SKillAction = {}
local g_ZhenfaSkill_Skill = {}
local g_ZhenfaActionID = {}
local g_ZhenfaName = {}
local g_ZhenfaCurSel = 1

local g_ZhenfaSkill_Frame_UnifiedXPosition = nil
local g_ZhenfaSkill_Frame_UnifiedYPosition = nil

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_ZhenfaSkill_Page = {
	[1] = {Text = "#e010101".."#{INTERFACE_XML_494}",	NeedCheck = 0, Tip = ""},
	[2] = {Text = "#e010101".."#{INTERFACE_XML_448}",	NeedCheck = 0, Tip = ""},
	[3] = {Text = "#e010101#Y".."#{JBGXW_150526_215}",	NeedCheck = 0, Tip = ""},
	[4] = {Text = "#e010101".."#{INTERFACE_XML_635}",	NeedCheck = 0, Tip = ""},
	[5] = {Text = "#e010101".."#{ZDZD_200724_08}",		NeedCheck = 0, Tip = ""},
	[6] = {Text = "#e010101".."#{ZMTF_230628_20}",		NeedCheck = 0, Tip = ""},
}
local g_ZhenfaSkill_PageButton = {}
local g_ZhenfaSkill_PageOrder = {}
local g_PageTipsPos = {}

function ZhenfaSkill_PreLoad()
	this:RegisterEvent("OPEN_ZHENFAFREAM");
	this:RegisterEvent("UPDATE_BROTHERSHIP");
	this:RegisterEvent("SKILL_UPDATE")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	
	this:RegisterEvent("CLOSE_SKILL_BOOK")

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND", true)
end


function ZhenfaSkill_OnLoad()
	g_SKillAction[1] = ZhenfaSkill_Zhen1
	g_SKillAction[2] = ZhenfaSkill_Zhen2
	g_SKillAction[3] = ZhenfaSkill_Zhen3
	g_SKillAction[4] = ZhenfaSkill_Zhen4
	
	g_ZhenfaSkill_Skill[1] = 3229
	g_ZhenfaSkill_Skill[2] = 3250
	g_ZhenfaSkill_Skill[3] = 3251
	g_ZhenfaSkill_Skill[4] = 3252
	
	g_ZhenfaName[1] = "#{JBGXW_150526_138}"
	g_ZhenfaName[2] = "#{JBGXW_150526_139}"
	g_ZhenfaName[3] = "#{JBGXW_150526_140}"
	g_ZhenfaName[4] = "#{JBGXW_150526_141}"
	
	--ZhenfaSkill_SetTabColor()

	-- 保存界面的默认相对位置
	g_ZhenfaSkill_Frame_UnifiedXPosition	= ZhenfaSkill_Frame : GetProperty("UnifiedXPosition");
	g_ZhenfaSkill_Frame_UnifiedYPosition	= ZhenfaSkill_Frame : GetProperty("UnifiedYPosition");
	
	g_ZhenfaSkill_PageButton[1] = ZhenfaSkill_CommonlySkill
	g_ZhenfaSkill_PageButton[2] = ZhenfaSkill_ActionSkill
	g_ZhenfaSkill_PageButton[3] = ZhenfaSkill_ZhenfaSkill
	g_ZhenfaSkill_PageButton[4] = ZhenfaSkill_LifeSkill
	g_ZhenfaSkill_PageButton[5] = ZhenfaSkill_AutoAttack
	g_ZhenfaSkill_PageButton[6] = ZhenfaSkill_ZongMenSkill
	
	g_PageTipsPos[1] = "{0.000000,28.000000}" 
	g_PageTipsPos[2] = "{0.000000,64.000000}" 
	g_PageTipsPos[3] = "{0.000000,100.000000}"
	g_PageTipsPos[4] = "{0.000000,136.000000}"
	g_PageTipsPos[5] = "{0.000000,172.000000}"
	g_PageTipsPos[6] = "{0.000000,208.000000}"
	
end


function ZhenfaSkill_OnEvent(event)
	if event == "OPEN_ZHENFAFREAM" then
		local selfUnionPos = Variable:GetVariable("SkillUnionPos");
		if(selfUnionPos ~= nil) then
			ZhenfaSkill_Frame:SetProperty("UnifiedPosition", selfUnionPos);
		end
		ZhenfaSkill_UpdataSkill()
		ZhenfaSkill_SetData()
		ZhenfaSkill_ShowPage()
		this:Show()
	elseif (event == "ADJEST_UI_POS")  then
		ZhenfaSkill_Frame_OnResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZhenfaSkill_Frame_OnResetPos()
	elseif (event == "UPDATE_BROTHERSHIP" and this:IsVisible() ) then
		ZhenfaSkill_Updataqingyi()
	elseif (event == "SKILL_UPDATE" and this:IsVisible()) then
		ZhenfaSkill_UpdataSkill()
	elseif (event == "CLOSE_SKILL_BOOK") then
		ZhenfaSkill_OnClose()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633007) then	--服务端传数据
	
		local bIsShowHotPoint = Get_XParam_INT(0)	
		if bIsShowHotPoint == 1 then
			ZhenfaSkill_ZongMenSkill_Tips:Show()	
		else
			ZhenfaSkill_ZongMenSkill_Tips:Hide()		
		end
		
	end
end

function ZhenfaSkill_Frame_OnResetPos()
	ZhenfaSkill_Frame : SetProperty("UnifiedXPosition", g_ZhenfaSkill_Frame_UnifiedXPosition);
	ZhenfaSkill_Frame : SetProperty("UnifiedYPosition", g_ZhenfaSkill_Frame_UnifiedYPosition);

end

function ZhenfaSkill_OnClose()
	Variable:SetVariable("SkillUnionPos", ZhenfaSkill_Frame:GetProperty("UnifiedPosition"), 1);
	this:Hide()
end

function ZhenfaSkill_OnHidden()

end

function ZhenfaSkill_Updataqingyi()
	local bsNum = Player:GetBrotherShip()
	ZhenfaSkill_QingyiNum_All:SetText("#{JBGXW_150526_10}"..bsNum)
	local wbsNum = Player:GetWeekBrotherShip()
	ZhenfaSkill_QingyiNum_Have:SetText("#{JBGXW_150526_12}"..wbsNum.."/1500")
end
function ZhenfaSkill_SetData()

	ZhenfaSkill_Updataqingyi()
	ZhenfaSkill_SetSelectSkillInfo(1)
end


function ZhenfaSkill_Update_Cliecked(nIndex)
	ZhenfaSkill_SetSelectSkillInfo(nIndex)
end
function ZhenfaSkill_SetSelectSkillInfo(Index)

	for i=1,4 do
		g_SKillAction[i]:SetPushed(0)
	end
	local temp1,temp2,temp3,temp4 = Player:GetData("ZHENFAINFO")
	local zhenfainfo = {temp1,temp2,temp3,temp4}	
	g_SKillAction[Index]:SetPushed(1);
	ZhenfaSkill_ZhenfaTarget:SetActionItem(g_ZhenfaActionID[Index])
	ZhenfaSkill_Info_Name:SetText(g_ZhenfaName[Index])
	ZhenfaSkill_Info_Level:SetText(ZhenfaSkill_DecoZhenFaDesc(zhenfainfo[Index]))
	local str = Player:GetStrZhenfaSkill(Index-1)
	ZhenfaSkill_Explain:SetText(str)
end

function ZhenfaSkill_DecoZhenFaDesc(info)
	advance  = math.floor(tonumber(info)/1000)
	level	 = math.mod(tonumber(info),1000)
	if level == 100 then
		return "#{JBGXW_150526_145}"
	else
		return advance.."阶"..(level-advance*10).."级"
	end
end

function ZhenfaSkill_UpdataSkill()

	local temp1,temp2,temp3,temp4 = Player:GetData("ZHENFAINFO")
	local zhenfainfo = {temp1,temp2,temp3,temp4}
	for i = 1, 4 do
		local level = ZhenfaSkill_DecoZhenFaInfo(zhenfainfo[i])
		-- if level == 0 then
			for i = 1, table.getn(g_ZhenfaSkill_Skill) do
				local thetempAction = EnumAction(g_ZhenfaSkill_Skill[i], "zhenfaskill");
				if thetempAction ~= nil then
					g_SKillAction[i] : SetActionItem(thetempAction : GetID())
					g_ZhenfaActionID[i] = thetempAction : GetID()
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
				if g_ZhenfaSkill_Skill[i] == nCommonId then
					g_SKillAction[i] : SetActionItem(thetempAction : GetID())
					g_ZhenfaActionID[i] = thetempAction : GetID()
				end
			end			
		end
	end
	

end

function ZhenfaSkill_DecoZhenFaInfo(info)
	advance = math.floor(info/1000)
	level = math.mod(info,1000)
	return level, advance
end


function ZhenfaSkill_OnMoved()

end

function ZhenfaSkill_Common_Page_Switch()
	OpenCommonSkillPage();
	ZhenfaSkill_OnClose();
	
end

function ZhenfaSkill_Life_Page_Switch()
	OpenLifePage();
	ZhenfaSkill_OnClose();
	
end

function ZhenfaSkill_Action_Page_Switch(nPageNumber)
	local menpai = Player:GetData("MEMPAI");
	if(menpai == 9) then 
		if g_ZhenfaSkill_PageButton[nPageNumber] ~= nil then
			g_ZhenfaSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ZhenfaSkill_ClearPage()
		PushDebugMessage("你还没有拜入门派。");
		return; 
	end;
	OpenSkillBook();
	ZhenfaSkill_OnClose();

end

function ZhenfaSkill_AutoAttack_Page_Switch(nPageNumber)
	local myLevel = Player:GetData("LEVEL")
	local nMenpai = Player:GetData("MEMPAI")
	local nCanShow = 1
	if myLevel >= 50 and nMenpai ~= 9 then
		PushEvent("TRIGGER_ZIDONGZHANDOU","config")
		DataPool:Lua_SetLastSkill_UI(6)
		ZhenfaSkill_OnClose()
	elseif myLevel < 50 then
		PushDebugMessage("#{ZDZD_200724_62}")
		nCanShow = 0
	else
		PushDebugMessage("#{ZDZD_200724_63}")
		nCanShow = 0
	end

	if nCanShow == 0 then
		if g_ZhenfaSkill_PageButton[nPageNumber] ~= nil then
			g_ZhenfaSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ZhenfaSkill_ClearPage()
	end
end

function ZhenfaSkill_ZongMen_Page_Switch(nPageNumber)
	if DataPool:Lua_CheckOpenTalent() == 1 then
		ToggleTalentPage()
		ZhenfaSkill_OnClose();
	else
		if g_ZhenfaSkill_PageButton[nPageNumber] ~= nil then
			g_ZhenfaSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ZhenfaSkill_ClearPage()	
	end
	
end

function ZhenfaSkill_Use_Clicked()
	ZhenfaSkill_ZhenfaTarget:DoAction()
end

function ZhenfaSkill_Button_Clicked()
	PushEvent("UI_COMMAND",20150608)
end

function ZhenfaSkill_SetTabColor()
	

	local selColor = "#e010101#Y";
	local noselColor = "#e010101";
	local tab = {
								[0] = ZhenfaSkill_CommonlySkill,
								ZhenfaSkill_ActionSkill,
								ZhenfaSkill_ZhenfaSkill,
								ZhenfaSkill_LifeSkill,
								ZhenfaSkill_AutoAttack,
								ZhenfaSkill_ZongMenSkill,
							};

	local TAB_TEXT = {
		[0] = "#{INTERFACE_XML_494}",
		"#{INTERFACE_XML_448}",
		"#{JBGXW_150526_215}",
		"#{INTERFACE_XML_635}",
		"#{ZDZD_200724_08}",
		"#{ZMTF_230628_20}",
	};
	
	tab[0]:SetText(noselColor..TAB_TEXT[0]);
	tab[1]:SetText(noselColor..TAB_TEXT[1]);
	tab[2]:SetText(selColor..TAB_TEXT[2]);
	tab[3]:SetText(noselColor..TAB_TEXT[3]);
	tab[4]:SetText(noselColor..TAB_TEXT[4]);
	tab[5]:SetText(noselColor..TAB_TEXT[5]);
end


function ZhenfaSkill_ShowPage()

	for i = 1, table.getn(g_ZhenfaSkill_PageButton) do
		g_ZhenfaSkill_PageButton[i]:Hide()
	end
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	ZhenfaSkill_ClearPage()
	
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_ZhenfaSkill_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_ZhenfaSkill_PageButton) do
			if i ~= nPageNumber then
				g_ZhenfaSkill_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_ZhenfaSkill_PageOrder = {}
	local g_ZhenfaSkill_PageCount = 0
	
	for i = 1, table.getn(g_ZhenfaSkill_PageButton) do
		if ZhenfaSkill_CheckPage(i) == 1 then
			g_ZhenfaSkill_PageCount = g_ZhenfaSkill_PageCount + 1
			g_ZhenfaSkill_PageButton[g_ZhenfaSkill_PageCount]:Show()
			g_ZhenfaSkill_PageButton[g_ZhenfaSkill_PageCount]:SetText(g_ZhenfaSkill_Page[i].Text)	
			g_ZhenfaSkill_PageOrder[g_ZhenfaSkill_PageCount] = i
		end
	end
	
	for idx = 1, table.getn(g_ZhenfaSkill_PageOrder) do
		if g_ZhenfaSkill_PageOrder[idx] == 6 and g_PageTipsPos[idx] then -- 其他
			local newpos = g_PageTipsPos[idx]
			ZhenfaSkill_ZongMenSkill_Tips:SetProperty("UnifiedXPosition", newpos);
		end
	end
		
end

function ZhenfaSkill_OnPageClicked(idx)

	Variable:SetVariable("SkillPageNumber", tostring(idx), 1);
	idx = g_ZhenfaSkill_PageOrder[idx]
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	
	if idx == 1 then--普通
		ZhenfaSkill_Common_Page_Switch()
	elseif idx == 2 then--门派
		ZhenfaSkill_Action_Page_Switch(nPageNumber)
	elseif idx == 3 then--阵法
		ZhenfaSkill_ClearPage()
	elseif idx == 4 then--生活
		ZhenfaSkill_Life_Page_Switch()
	elseif idx == 5 then--战斗
		ZhenfaSkill_AutoAttack_Page_Switch(nPageNumber)
	elseif idx == 6 then --绝学
		ZhenfaSkill_ZongMen_Page_Switch(nPageNumber)
	end
end

function ZhenfaSkill_CheckPage(idx)
	if idx == 1 then--普通
		return 1
	elseif idx == 2 then--门派
		return 1
	elseif idx == 3 then--阵法
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 4 then--生活
		return 1
	elseif idx == 5 then--战斗
		return 1
	elseif idx == 6 then--绝学
		return 1
	end
	return 0
end

function ZhenfaSkill_ClearPage()
	Variable:SetVariable("SkillPageNumber", tostring(0), 1)
end


