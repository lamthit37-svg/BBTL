-- 典藏坐骑礼盒
-- 界面的默认位置

local g_PaySelectReward_Frame_UnifiedPosition

local g_bagId = -1;
local g_ItemID={
10141372,--	坐骑：添福锦鳞
10141373,--	坐骑：熔岩魔犀
10141375,--	坐骑：月白龙马
10141374,--	坐骑：四喜送鲤台
}

function PaySelectReward_PreLoad()

	this:RegisterEvent("CLOSE_WINDOW");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function PaySelectReward_OnLoad()
	-- 保存界面的默认相对位置
	g_PaySelectReward_Frame_UnifiedPosition=PaySelectReward_Frame:GetProperty("UnifiedPosition");
	--初始化
	PaySelectReward_InitUIData();
end

--初始化控件数据
function PaySelectReward_InitUIData()

end


function PaySelectReward_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		PaySelectReward_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		PaySelectReward_ResetPos()

	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "PaySelectReward") then
			PaySelectReward_OnHiden()
		end
	elseif(event == "UI_COMMAND") then
	  if tonumber(arg0) == 340023 then
	  	PaySelectReward_OnShown()
		end
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		PaySelectReward_OnHiden()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function PaySelectReward_ResetPos()
	PaySelectReward_Frame:SetProperty("UnifiedPosition", g_PaySelectReward_Frame_UnifiedPosition)
end


function PaySelectReward_OnShown()
	if g_bagId >=0 then
		LifeAbility : Lock_Packet_Item(g_bagId,0);
	end

	g_bagId = Get_XParam_INT(0);
	LifeAbility : Lock_Packet_Item(g_bagId,1);
	this:Show();
end

function PaySelectReward_Buttons_Clicked(index)
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
	PushEvent("MESSSAGEBOX2_SURE",index,g_bagId,g_ItemID[index])

--	this:Hide();
end

function PaySelectReward_OnHiden()
	LifeAbility : Lock_Packet_Item(g_bagId,0)
	this:Hide();
end
