local g_autoattack_btn_unpos = nil
local g_autoattack_btn_level = 50
-- local g_autoattack_btn_nomp = 9

local g_qiankun_item_name = {
	"乾坤壶", "乾坤杯", "乾坤缶"
}
local g_qiankun_buff_id = {
	343, 705, 9815
}

local g_FB_keys = {
	piaomiao			= "0", --缥缈峰
	cangjingge_80JQTZ	= "1", --少室山
	langhuanfudi		= "2", --琅嬛福地
	sanshenhuanjing		= "3", --三神幻境
	fengmingwangling_new= "4", --凤鸣王陵
	zhenlongscene		= "5", --珍珑棋局
	loulanxunbao		= "6", --楼兰寻宝
	touxi_menpai		= "7", --偷袭门派
	zeibing_ruqin		= "8", --贼兵入侵
	new_yanziwu			= "9", --燕子坞
	sijuezhuang			= "A", --四绝庄
	sancaixiagu		 	= "B", --老三环
}

local g_Map_Branch = {
	[173]		= "touxi_menpai",
	[174]		= "touxi_menpai",
	[175]		= "touxi_menpai",
	[176]		= "touxi_menpai",
	[177]		= "touxi_menpai",
	[178]		= "touxi_menpai",
	[179]		= "touxi_menpai",
	[180]		= "touxi_menpai",
	[181]		= "touxi_menpai",
	[288]		= "touxi_menpai",
	[618]		= "touxi_menpai",
	[681]		= "touxi_menpai",
	[742]		= "touxi_menpai",
	[829]		= "touxi_menpai",
	[1001]		= "touxi_menpai",
	[170]		= "zeibing_ruqin"
}

function AutoAttack_Button_GetAutoFBKey(branch)
	return g_FB_keys[branch]
end

function AutoAttack_Button_PreLoad()
	-- this:RegisterEvent("PLAYER_ENTERING_WORLD",true)
	this:RegisterEvent("SCENE_TRANSED",true)
	this:RegisterEvent("UNIT_LEVEL",true)
	-- this:RegisterEvent("UNIT_MENPAI",true)
	this:RegisterEvent("HIDE_THIS_UI",true)

	this:RegisterEvent("NEIGUA_FUBEN_EVENT",true)
	-- this:RegisterEvent("BATTLE_ASSIST_EVENT",false)
	-- this:RegisterEvent("CHANGE_ACCE_SETUP",false)

	this:RegisterEvent("HIDE_TLBB_MAIN",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function AutoAttack_Button_OnLoad()
	g_autoattack_btn_unpos = AutoAttack_Button_Frame:GetProperty("UnifiedPosition")
end

function AutoAttack_Button_OnEvent(event)
	if DataPool:LuaFnGetGMVisibleType() ~= 0 then
		this:Hide()
		return
	end

	if event == "SCENE_TRANSED"  then
		AutoAttack_Button_OnShow()
	elseif event == "UNIT_LEVEL"  then
		AutoAttack_Button_OnShow()
	elseif event == "HIDE_THIS_UI"  then
		if this:IsVisible() then
			this:Hide()
		else
			AutoAttack_Button_OnShow()
		end

	elseif event == "NEIGUA_FUBEN_EVENT" then
		if arg0 == "show" or arg0 == "hide" then
			AutoAttack_Button_OnShow()
		elseif arg0 == "update" then
			if this:IsVisible() then
				AutoAttack_Button_UpdateState()
			end
		end

	elseif event == "HIDE_TLBB_MAIN" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		AutoAttack_Button_OnResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		AutoAttack_Button_OnResetPos()
	end
end

function AutoAttack_Button_OnShow()
	if not BattleAssist:AskIsNeiGuaOpen("FB") then
		this:Hide()
		return
	end
	if not AutoAttack_Button_GetFBKeyAndBranchName() then
		local ng_type = BattleAssist:IsWorking()
		if g_FB_keys[ng_type] then
			BattleAssist:Stop() --切到非副本场景后，如果副本自动化在运行，就把它关闭
		end
		this:Hide()
		return
	end
	local nLevel = Player:GetData("LEVEL")
	if nLevel >= g_autoattack_btn_level then
		AutoAttack_Button_UpdateState()
		this:Show()
	else
		this:Hide()
	end
end

-- 根据场景获取副本类型
function AutoAttack_Button_GetFBKeyAndBranchName()
	local sceneid = GetSceneID()
	if nil == sceneid then
		return
	end
	local branch
	if g_Map_Branch[sceneid] then
		branch = g_Map_Branch[sceneid]
	else
		branch = GetSceneMapByID(tonumber(sceneid)) or ""
	end
	-- Lua_TDU_Log("branch "..branch)
	return g_FB_keys[branch], branch
end

-- 更新UI
function AutoAttack_Button_UpdateState()
	local ng_type = BattleAssist:IsWorking() --NeiGua running branch name
	if type(ng_type) == "string" and g_FB_keys[ng_type] then
		AutoAttack_Button_Frame_Button:Show()
		AutoAttack_Button_Frame_Button_OFF:Hide()
	else
		AutoAttack_Button_Frame_Button_OFF:Show()
		AutoAttack_Button_Frame_Button:Hide()
	end
end

-- 检查开启自动打副本的条件
function AutoAttack_Button_CheckOpenAutoFB()
	if not BattleAssist:CheckConditions("FB") then
		return 0
	end

	-- 检查buff
	for i = 1, 3 do
		local left_time = Player:CheckBuffImpactExist(g_qiankun_buff_id[i])
		if left_time then
			if left_time < 1200 then
				MessageBoxSelf3("AutoAttack_Button_OnComfirmed_QianKun", {
					["Content"] = g_qiankun_item_name[i].."剩余时间不足20分钟，逾期后将不再自动拾取物品，是否确认继续开启自动战斗？",
					["Type"] = "YesNo"
				})
				return 0
			else
				return 1
			end
		end
	end

	MessageBoxSelf3("AutoAttack_Button_OnComfirmed_QianKun", {
		["Content"] = "#{NGGZ_230511_3}", --您当前尚未使用乾坤壶，自动战斗不会自动帮您拾取物品，是否确认继续开启自动战斗？
		["Type"] = "YesNo"
	})
	return 0
end

-- 弹窗回调
function AutoAttack_Button_OnComfirmed_QianKun(strRet)
	if nil == strRet then
		return
	end
	if "Yes" == strRet or "Ok" == strRet then
		local fb_key, _ = AutoAttack_Button_GetFBKeyAndBranchName()
		if fb_key ~= nil then
			BattleAssist:Start("FB", fb_key)
		end
	end
end

function AutoAttack_Button_OnClick()
	local fb_key, branch = AutoAttack_Button_GetFBKeyAndBranchName()
	local ng_run = BattleAssist:IsWorking()

	-- 在副本场景中，且服务器允许开启内挂
	if fb_key and BattleAssist:AskIsNeiGuaOpen("FB") then
		if branch ~= ng_run then
			-- 开启自动副本
			if AutoAttack_Button_CheckOpenAutoFB() == 1 then
				BattleAssist:Start("FB", fb_key)
			end
		else
			-- 关闭自动副本
			BattleAssist:Stop()
		end
	else
		PushDebugMessage("#{ZDZD_200724_32}") --该场景中不可使用自动战斗。
	end

	-- if ng_run == "true" then
	-- 	PushEvent("TRIGGER_ZIDONGZHANDOU","stop")
	-- else
	-- 	PushEvent("TRIGGER_ZIDONGZHANDOU","start")
	-- end
end

function AutoAttack_Button_ConfigOnClick()
	
end


function AutoAttack_Button_OnResetPos()
	AutoAttack_Button_Frame:SetProperty("UnifiedPosition",g_autoattack_btn_unpos)
end