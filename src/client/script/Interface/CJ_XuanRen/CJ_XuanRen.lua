-- 选人界面
local g_unifiedposistion
local g_select = 0
local g_identity_max = 3

local g_ui_list = {}
local g_ui_skill_list = {}
local g_IdentityInfo = {
    [0] = {name="#{TLCJ_20240709_182}",image="set:ModifyMenPai2 image:Modify_ShaoLin",},
    [1] = {name="#{TLCJ_20240709_184}",image="set:ModifyMenPai2 image:Modify_MingJiao",},
    [2] = {name="#{TLCJ_20240709_183}",image="set:ModifyMenPai image:Modify_GaiBang",},
    [3] = {name="#{TLCJ_20240709_185}",image="set:ModifyMenPai4 image:Modify_WuDang",},
	[4] = {name="#{TLCJ_20240709_188}",image="set:ModifyMenPai image:Modify_Emei",},
    [5] = {name="#{TLCJ_20240709_189}",image="set:ModifyMenPai4 image:Modify_XingXiu",},
    [6] = {name="#{TLCJ_20240709_186}",image="set:ModifyMenPai3 image:Modify_TianLong",},
    [7] = {name="#{TLCJ_20240709_190}",image="set:ModifyMenPai3 image:Modify_TianShan",},
    [8] = {name="#{TLCJ_20240709_187}",image="set:ModifyMenPai4 image:Modify_XiaoYao",},
	[9] = {name="???",image="set:NewFreshMan_TM image:NewFreshMan_TM_Man",},
    [10] = {name="#{TLCJ_20240709_191}",image="set:ModifyMenPai2 image:Modify_MuRong",},
    [11] = {name="#{TLCJ_20240709_181}",image="set:ModifyMenPai3 image:Modify_TangMen",},
    [12] = {name="#{TLCJ_20240709_180}",image="set:ModifyMenPai image:Modify_GuiGu",},
    [13] = {name="#{TLCJ_20240709_179}",image="set:ModifyMenPai14 image:Modify_TaoHuaDao",},
    [14] = {name="#{TLCJ_20240709_178}",image="set:ModifyMenPai14 image:Modify_HongMing",},
    [15] = {name="#{TLCJ_20240709_192}",image="set:ModifyMenPai14 image:Modify_ERenGu",},
}

local g_SkillInfo = {
	[0] = {1,2,3,4,5,6,7,},
	[1] = {8,9,10,11,12,13,14,},
	[2] = {15,16,17,18,19,20,21,},
	[3] = {22,23,24,25,26,27,28,},
	[4] = {29,30,31,32,33,34,35,},
	[5] = {36,37,38,39,40,41,42,},
	[6] = {43,44,45,46,47,48,49,},
	[7] = {50,51,52,53,54,55,56,},
	[8] = {57,58,59,60,61,62,63,},
	[10] = {64,65,66,67,68,69,70,},
	[11] = {71,72,73,74,75,76,77,},
	[12] = {78,79,80,81,82,83,84,},
	[13] = {85,86,87,88,89,90,91,},
	[14] = {92,93,94,95,96,97,98,},
	[15] = {99,100,101,102,103,104,105},

}


function CJ_XuanRen_PreLoad()
	this:RegisterEvent("TLCJ_BATTLE_SELECTUI_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CJ_XuanRen_OnLoad()

	g_ui_list = {}
	g_ui_list[1] = {} 
	g_ui_list[1].image = CJ_XuanRen_Img_1
	g_ui_list[1].check = CJ_XuanRen_Select_1
	g_ui_list[1].name = CJ_XuanRen_ContentTitle_Info_1
	g_ui_list[2] = {} 
	g_ui_list[2].image = CJ_XuanRen_Img_2
	g_ui_list[2].check = CJ_XuanRen_Select_2
	g_ui_list[2].name = CJ_XuanRen_ContentTitle_Info_2
	g_ui_list[3] = {} 
	g_ui_list[3].image = CJ_XuanRen_Img_3
	g_ui_list[3].check = CJ_XuanRen_Select_3
	g_ui_list[3].name = CJ_XuanRen_ContentTitle_Info_3

	g_ui_skill_list = {
		[1] = {
			CJ_XuanRen_SkillBK_1_SkillActionBtn_1,
			CJ_XuanRen_SkillBK_1_SkillActionBtn_2,
			CJ_XuanRen_SkillBK_1_SkillActionBtn_3,
			CJ_XuanRen_SkillBK_1_SkillActionBtn_4,
			CJ_XuanRen_SkillBK_1_SkillActionBtn_5,
			CJ_XuanRen_SkillBK_1_SkillActionBtn_6,
			CJ_XuanRen_SkillBK_1_SkillActionBtn_7,
		},
		[2] = {
			CJ_XuanRen_SkillBK_2_SkillActionBtn_1,
			CJ_XuanRen_SkillBK_2_SkillActionBtn_2,
			CJ_XuanRen_SkillBK_2_SkillActionBtn_3,
			CJ_XuanRen_SkillBK_2_SkillActionBtn_4,
			CJ_XuanRen_SkillBK_2_SkillBK_2_SkillActionBtn_5,
			CJ_XuanRen_SkillBK_2_SkillActionBtn_6,
			CJ_XuanRen_SkillBK_2_SkillActionBtn_7,
		},
		[3] = {
			CJ_XuanRen_SkillBK_3_SkillActionBtn_1,
			CJ_XuanRen_SkillBK_3_SkillActionBtn_2,
			CJ_XuanRen_SkillBK_3_SkillActionBtn_3,
			CJ_XuanRen_SkillBK_3_SkillActionBtn_4,
			CJ_XuanRen_SkillBK_3_SkillBK_2_SkillActionBtn_5,
			CJ_XuanRen_SkillBK_3_SkillActionBtn_6,
			CJ_XuanRen_SkillBK_3_SkillActionBtn_7,
		},
	}
	-- 保存界面的默认相对位置
	g_unifiedposistion = CJ_XuanRen_Frame:GetProperty("UnifiedPosition")
end

function CJ_XuanRen_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		CJ_XuanRen_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		CJ_XuanRen_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		CJ_XuanRen_CloseClicked()
	elseif(event == "TLCJ_BATTLE_SELECTUI_SHOW") then
		CJ_XuanRen_OnShow(tonumber(arg0), tonumber(arg1))
	end

end

function CJ_XuanRen_OnShow(isShow, lastTime)
	if isShow > 0 then
		-- 先初始化一下
		local ret = CJ_XuanRen_InitUIData(lastTime)
		if ret > 0 then
			this:Show()
		else
			this:Hide()
		end
	elseif isShow < 0 then
		CJ_XuanRen_RefreshTime(lastTime)
	else
		this:Hide()
	end
end

-- 初始化控件数据
function CJ_XuanRen_InitUIData(lastTime)

	local data = TLCJ:GetPlayerSelectInfo("group")
	if data == nil or type(data) ~= "table" then
		this:Hide()
		return -1
	end

	for i=1, g_identity_max do
		g_ui_list[i].check:SetCheck(0)

		local skillinfo = g_ui_skill_list[i]
		for _, ui in (skillinfo or {}) do
			ui:SetProperty("Empty", "False")
			ui:SetProperty("UseDefaultTooltip", "True")
			ui:Hide()
		end
	end
	
	g_select = 0
	local group = {data.group1,data.group2,data.group3}
	for i=1, g_identity_max do
		local curSelect = group[i]
		local resData = g_IdentityInfo[curSelect]
		if resData ~= nil then
			g_ui_list[i].image:SetProperty("Image", resData.image)
			g_ui_list[i].name:SetText(resData.name)
			if data.select == curSelect then
				g_select = i
				g_ui_list[i].check:SetCheck(1)
			else
				g_ui_list[i].check:SetCheck(0)
			end
		end

		-- 处理技能图标
		local skillList = g_ui_skill_list[i]
		local skillData = g_SkillInfo[curSelect]
		if skillList ~= nil and skillData ~= nil then
			for skillIndex, skillId in (skillData or {}) do
				if skillList[skillIndex] ~= nil then
					local image, desc = TLCJ:GetSkillTips(skillId)
					if image ~= nil then
						local strImage = GetIconFullName(tostring(image))
						skillList[skillIndex]:SetProperty("Empty", "False")
						skillList[skillIndex]:SetProperty("UseDefaultTooltip", "True")
						skillList[skillIndex]:SetProperty("NormalImage", strImage)
						skillList[skillIndex]:SetProperty("HoverImage", strImage)
						skillList[skillIndex]:SetToolTip(desc)
						skillList[skillIndex]:Show()
					end
				end
			end
		end
	end

	-- 显示剩余时间
	if lastTime ~= nil and lastTime > 0 then
		CJ_XuanRen_Time_StopWatch:SetProperty("Timer", lastTime)
	else
		CJ_XuanRen_Time_StopWatch:SetProperty("Timer", 0)
	end
	CJ_XuanRen_Time_StopWatch:SetProperty("TextColor", "FF00FF00")
	
	return 1
end

function CJ_XuanRen_RefreshTime(lastTime)
	if this:IsVisible() then
		-- 显示剩余时间
		if lastTime ~= nil and lastTime > 0 then
			CJ_XuanRen_Time_StopWatch:SetProperty("Timer", lastTime)
		else
			CJ_XuanRen_Time_StopWatch:SetProperty("Timer", 0)
		end
		CJ_XuanRen_Time_StopWatch:SetProperty("TextColor", "FF00FF00")
	end
end

function CJ_XuanRen_Select(index)
	if index < 0 or index > g_identity_max then
		return
	end

	g_select = index
end

function CJ_XuanRen_OK()
	if g_select < 0 or g_select > g_identity_max then
		return
	end

	local data = TLCJ:GetPlayerSelectInfo("group")
	if data == nil or type(data) ~= "table" then
		return
	end

	local group = {data.group1,data.group2,data.group3}
	local destSelect =  group[g_select]
	if destSelect == nil then
		return
	end

	if TLCJ:IsInTLCJScene() > 0 then
		if TLCJ:IsInTLCJScene_Team() > 0 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnPlayerSelectIdentity")
				Set_XSCRIPT_ScriptID(999337)
				Set_XSCRIPT_Parameter(0, destSelect)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnPlayerSelectIdentity")
				Set_XSCRIPT_ScriptID(999321)
				Set_XSCRIPT_Parameter(0, destSelect)
				Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		end
	end
end

function CJ_XuanRen_TransformName(name, zoneid)
	if zoneid < 0 then
		return name
	end

	local retname = name
	if g_trasname > 0 then
		local selfzoneid = DataPool:GetSelfZoneWorldID()
		if selfzoneid ~= zoneid then
			local serverName = DataPool:GetServerName( zoneid )
			retname = name.."@"..tostring(serverName)
		end
	end

	return retname
end

--================================================
-- 关闭
--================================================
function CJ_XuanRen_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CJ_XuanRen_ResetPos()
	CJ_XuanRen_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

