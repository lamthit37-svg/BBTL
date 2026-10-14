-- author: wanghongao

local MAX_OBJ_DISTANCE = 5.0
local g_Item_Pos = -1
local g_ObjCared = -1
local g_T3BangHuiBoss_Frame_UnifiedPosition
local g_UI_Type = 0   -- 1：物品兑换；2：物品上架

local g_Confirm_Flags = {
	0,  -- 兑换二次确认标记
	0   -- 上架二次确认标记
}

local g_UsableItemIDs = {
	{
		38005010,  -- 魔尊魂武兑换券
		38005011,  -- 星岩玄晶兑换券
		38005012,  -- 攻守兼备残印兑换券
		38005013,  -- 流光千机兑换券
		38005014,  -- 重楼玉兑换券
		38005015,  -- 重楼戒兑换券
		38005016   -- 金色秘技：攻守兼备兑换券
	},
	-- 可上架物品展示ID（顺序须与上表一一对应）
	{
		39920319,  -- 魔尊魂武
		39922899,  -- 星岩玄晶
		39922900,  -- 攻守兼备残印
		39922423,  -- 流光千极
		39922901,  -- 重楼玉
		39922902,  -- 重楼戒
		39922634,  -- 金色秘技：攻守兼备
	},
	-- 兑换后/实际上架 的物品ID（顺序须与上表一一对应）
	{
		38000539,  -- 魔尊魂武
	    38004960,  -- 星岩玄晶
		38005055,  -- 秘技碎片
		34000050,  -- 流光千机
		10423026,  -- 重楼玉
		10422150,  -- 重楼戒
		38004620  -- 金色秘技：攻守兼备
	}
}


function T3BangHuiBoss_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("UPDATE_T3BANGHUIBOSS_PAINT", false)
	-- this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	-- this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)

	-- this:RegisterEvent("PROGRESSBAR_SHOW")
	-- this:RegisterEvent("OPEN_STALL_SALE")

	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function T3BangHuiBoss_OnLoad()
	g_T3BangHuiBoss_Frame_UnifiedPosition = T3BangHuiBoss_Frame:GetProperty("UnifiedPosition")
end

function T3BangHuiBoss_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 79005601 then
		local op = Get_XParam_INT(0)

		-- 放入道具
		if op == 100 then
			T3BangHuiBoss_PutInItem(Get_XParam_INT(1), Get_XParam_INT(2))
			return
		-- 兑换二次确认
		elseif op == 201 then
			local str = Get_XParam_STR(0)
			MessageBoxSelf3("T3BangHuiBoss_OnComfirmedBack1", {["Content"] = str, ["Type"] = "Ok"})
			return
		-- 上架二次确认
		elseif op == 202 then
			local str = Get_XParam_STR(0)
			MessageBoxSelf3("T3BangHuiBoss_OnComfirmedBack2", {["Content"] = str, ["Type"] = "Ok"})
			return
		-- 清空物品
		elseif op == 300 then
			T3BangHuiBoss_ClearItem()
			return
		end

		-- 打开界面
		local objCared = DataPool:GetNPCIDByServerID(Get_XParam_INT(1))
		T3BangHuiBoss_Init(op, objCared)
		this:Show()
		-- 打开背包道具栏
	    if IsWindowShow("Packet") == false then
		    ToggleContainer()
	    end
		if objCared == -1 then
			return
		end
		BeginCareObject_T3BangHuiBoss(objCared)

	-- 放入道具
	elseif event ==	"UPDATE_T3BANGHUIBOSS_PAINT" then
		if arg0 ~= nil then
			T3BangHuiBoss_TryPutItem(tonumber(arg0))
		end

	elseif event == "OBJECT_CARED_EVENT" then
		if(arg0 ~= nil and tonumber(arg0) ~= objCared) then
			return
		end
		if(arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy") then
			T3BangHuiBoss_OnHide()
		end

	elseif (event == "ADJEST_UI_POS" ) then
		T3BangHuiBoss_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		T3BangHuiBoss_Frame_On_ResetPos()

	-- 离开游戏世界
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		T3BangHuiBoss_OnHide()
	end

end

-- 尝试放入道具
function T3BangHuiBoss_TryPutItem(pos)

	local item_index = T3BangHuiBoss_IsUsableItem(pos)
	if item_index == nil then
		PushDebugMessage("参数g_UI_Type错误")
		return
	end

    if item_index == 0 then
		PushDebugMessage("#{SHQX_200903_97}")
		return
	end

	if PlayerPackage:IsLock(pos) == 1 then
		PushDebugMessage("#{SHQX_200903_98}")
		return
	end

	-- 如果能放，返回UICommand arg0=100
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("CanItemBePutIn")
		Set_XSCRIPT_ScriptID(790056)
		Set_XSCRIPT_Parameter(0, g_UsableItemIDs[1][item_index])
		Set_XSCRIPT_Parameter(1, pos)
		Set_XSCRIPT_Parameter(2, g_UI_Type)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

-- 道具是否可用
function T3BangHuiBoss_IsUsableItem(pos)
	if g_UI_Type ~= 1 and g_UI_Type ~= 2 then
		return nil
	end
    local table_id = PlayerPackage:GetItemTableIndex(pos)
    for i = 1, table.getn(g_UsableItemIDs[1]) do
        if table_id == g_UsableItemIDs[1][i] then
            return i
        end
	end
	return 0
end

-- 放入道具
function T3BangHuiBoss_PutInItem(pos, item_index)
	if PlayerPackage:GetItemTableIndex(pos) ~= item_index then
		PushDebugMessage("PutItem: 第"..pos.."格上的物品ID发生改变")
		return
	end

	local idx = T3BangHuiBoss_IsUsableItem(pos)
	if idx == nil then
		PushDebugMessage("参数g_UI_Type错误")
		return
	end

	local action_id = EnumAction(pos, "packageitem"):GetID()
	local action_id_show = DataPool:CreateActionItemForShow(g_UsableItemIDs[2][idx], 1):GetID()

	if action_id ~= 0 and action_id_show ~= 0 then
		if g_Item_Pos >= 0 then
			T3BangHuiBoss_ClearItem()
		end
		g_Item_Pos = pos

		LifeAbility:Lock_Packet_Item(pos, 1)
		T3BangHuiBoss_Text2_But:SetActionItem(action_id)
		T3BangHuiBoss_Text1_But:SetActionItem(action_id_show)

		-- 提示上架的起拍价
		if g_UI_Type == 2 then
			local prize = DataPool:LuaFnGetBianJingBiddingBonusInfo(g_UsableItemIDs[3][idx], "BASEPRICE")
			if prize == 0 then
				PushDebugMessage("获取起拍底价失败")
			else
				T3BangHuiBoss_Text3:SetText(ScriptGlobal_Format("#{SHQX_200903_133}", tostring(prize)))
			end
		end
	else
		T3BangHuiBoss_ClearItem()
	end
end

-- 清除道具栏
function T3BangHuiBoss_ClearItem()
	T3BangHuiBoss_Text3:SetText("")
	g_Confirm_Flags = {0, 0}
	if g_Item_Pos ~= -1 then
		T3BangHuiBoss_Text2_But:SetActionItem(-1)
		T3BangHuiBoss_Text1_But:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(g_Item_Pos, 0)
		g_Item_Pos = -1
	end
end

-- 初始化界面
function T3BangHuiBoss_Init(type_id, obj_cared)
	SetDefaultMouse()
	StopCareObject_T3BangHuiBoss(obj_cared)
	T3BangHuiBoss_ClearItem()
	g_UI_Type = type_id
	g_ObjCared = obj_cared

	if type_id == 1 then
		T3BangHuiBoss_DragTitle:SetText("#{SHQX_200903_92}")
		T3BangHuiBoss_Text:SetText("#{SHQX_200903_93}")
		T3BangHuiBoss_Text1:SetText("#{SHQX_200903_94}")
		T3BangHuiBoss_Text2:SetText("#{SHQX_200903_95}")
		T3BangHuiBoss_Btn:SetText("#{SHQX_200903_96}")
	elseif type_id == 2 then
		T3BangHuiBoss_DragTitle:SetText("#{SHQX_200903_110}")
		T3BangHuiBoss_Text:SetText("#{SHQX_200903_131}")
		T3BangHuiBoss_Text1:SetText("#{SHQX_200903_111}")
		T3BangHuiBoss_Text2:SetText("#{SHQX_200903_112}")
		T3BangHuiBoss_Btn:SetText("#{SHQX_200903_113}")
	end
end

-- 清空界面
function T3BangHuiBoss_Clear(objCared)
	SetDefaultMouse()
	StopCareObject_T3BangHuiBoss(objCared)
	T3BangHuiBoss_ClearItem()
	g_UI_Type = 0
	g_ObjCared = -1
	T3BangHuiBoss_DragTitle:SetText("")
	T3BangHuiBoss_Text:SetText("")
	T3BangHuiBoss_Text1:SetText("")
	T3BangHuiBoss_Text2:SetText("")
	T3BangHuiBoss_Btn:SetText("")
end

-- 隐藏界面
function T3BangHuiBoss_OnHide()
	T3BangHuiBoss_Clear()
	this:Hide()
end

-- 关心NPC
function BeginCareObject_T3BangHuiBoss(objCaredId)
	g_ObjCared = objCaredId
	this:CareObject(g_ObjCared, 1, "T3BangHuiBoss")
end
function StopCareObject_T3BangHuiBoss(objCaredId)
	this:CareObject(g_ObjCared, 0, "T3BangHuiBoss")
	g_ObjCared = -1
end

-- 重置界面位置
function T3BangHuiBoss_Frame_On_ResetPos()
  T3BangHuiBoss_Frame:SetProperty("UnifiedPosition", g_T3BangHuiBoss_Frame_UnifiedPosition);
end

-- 点击确认按钮
function T3BangHuiBoss_OKClick()
	-- 是否放入兑换券
	if g_Item_Pos == -1 then
		PushDebugMessage("#{SHQX_200903_102}")
		return
	end

	-- 物品类型判断
	local item_id = PlayerPackage:GetItemTableIndex(g_Item_Pos)
	local idx = T3BangHuiBoss_IsUsableItem(g_Item_Pos)
	if idx == nil or idx == 0 or item_id ~= g_UsableItemIDs[1][idx] then
		return
	end

	-- 兑换券是否加锁
	if PlayerPackage:IsLock(g_Item_Pos) == 1 then
		PushDebugMessage("#{SHQX_200903_98}")
		return
	end

	local func_name = ""
	if g_UI_Type == 1 then
		func_name = "DoExChangeItem"
	elseif g_UI_Type == 2 then
		func_name = "DoAuctionItem"
	end

	-- 没看过二次确认，弹出二次确认框
	if func_name ~= "" and g_Confirm_Flags[g_UI_Type] == 0 then
		local prize = DataPool:LuaFnGetBianJingBiddingBonusInfo(g_UsableItemIDs[3][idx], "BASEPRICE")
		if prize > 0 then
		    Clear_XSCRIPT()
			    Set_XSCRIPT_Function_Name(func_name)
		        Set_XSCRIPT_ScriptID(790056)
		        Set_XSCRIPT_Parameter(0, g_Item_Pos)
		        Set_XSCRIPT_Parameter(1, item_id)
		        Set_XSCRIPT_Parameter(2, prize)
		        Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		end

	-- 已经看过二次确认提示，直接执行兑换/上架。
	elseif func_name ~= "" and g_Confirm_Flags[g_UI_Type] == 1 then
		Clear_XSCRIPT()
		    Set_XSCRIPT_Function_Name(func_name)
		    Set_XSCRIPT_ScriptID(790056)
		    Set_XSCRIPT_Parameter(0, g_Item_Pos)
		    Set_XSCRIPT_Parameter(1, item_id)
		    Set_XSCRIPT_Parameter(2, 0)
		    Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
end

-- 兑换二次确认回调
function T3BangHuiBoss_OnComfirmedBack1(strRet)
	if nil == strRet then
		return
	end
	local item_id = PlayerPackage:GetItemTableIndex(g_Item_Pos)
	if "Yes" == strRet or "Ok" == strRet then
		if g_UI_Type == 1 then
			g_Confirm_Flags[g_UI_Type] = 1
		end
	end
end

-- 上架二次确认回调
function T3BangHuiBoss_OnComfirmedBack2(strRet)
	if nil == strRet then
		return
	end
	local item_id = PlayerPackage:GetItemTableIndex(g_Item_Pos)
	if "Yes" == strRet or "Ok" == strRet then
		if g_UI_Type == 2 then
			g_Confirm_Flags[g_UI_Type] = 1
		end
	end
end