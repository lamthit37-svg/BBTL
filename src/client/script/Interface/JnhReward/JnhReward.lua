--13年经典典藏礼盒界面
local g_JnhReward_Frame_UnifiedPosition

local g_bagId = -1;
local g_ItemID={
	10146495,--	坐骑：霞上仙
	10146596,--	坐骑：水客乘鲤去
	10146598,--	坐骑：添福锦鳞
	10146599,--	坐骑：熔岩魔犀
	10146600,--	坐骑：四喜送鲤台
	10146601,--	坐骑：月白龙马
}

function JnhReward_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("CLOSE_WINDOW");
end

function JnhReward_OnLoad()
	g_JnhReward_Frame_UnifiedPosition = JnhReward_Frame:GetProperty("UnifiedPosition")

end

function JnhReward_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 202010191) then
		JnhReward_OnShown()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		JnhReward_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		JnhReward_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		JnhReward_Close()
	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "JnhReward") then
			JnhReward_Close()
		end
	end
	
end

function JnhReward_SelectMount(index)
	if g_ItemID[index]==nil then
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	-- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{MDJH_130507_14}")
		return
	end
	-- 物品加锁与否，服务器判断
	-- 判断角色背包道具栏剩余空间是否大于等于1，服务器判断
	PushEvent("JIANIANHUA_DIANCANGLIHE_SELECTCONFIRM",index,g_bagId,g_ItemID[index])
end

function JnhReward_OnShown()
	if g_bagId >=0 then
		LifeAbility : Lock_Packet_Item(g_bagId,0);
	end

	g_bagId = Get_XParam_INT(0);
	LifeAbility : Lock_Packet_Item(g_bagId,1);
	this:Show();
end

function JnhReward_On_ResetPos()
	JnhReward_Frame:SetProperty("UnifiedPosition", g_JnhReward_Frame_UnifiedPosition)

end

function JnhReward_Close()
	this:Hide()
end

function JnhReward_OnHiden()
	LifeAbility : Lock_Packet_Item(g_bagId,0)
end