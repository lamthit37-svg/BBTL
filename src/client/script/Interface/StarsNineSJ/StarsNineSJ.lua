-- 手工装备属性重铸材料升级 2019-2-15 lishilong
-- !!!reloadscript =StarsNineSJ
--
local MAX_OBJ_DISTANCE = 3.0
local g_objCared = -1
local g_npcObjId = -1
local g_StarsNineSJ_Frame_UnifiedPosition
local bCaredObj = 1

-- 紫金玉	38002727	绑定
-- 紫金玉	38002728	非绑定
-- 紫金玉	38002729	不用的id
-- 流光焰	38002730	绑定
-- 流光焰	38002731	非绑定
-- 流觞水	38002732	绑定
-- 流觞水	38002733	非绑定
-- 分别对应7星、8星、9星手工的重铸材料
-- 砂 石 玉
local g_tabBindMainItem     = {38000953, 38000956, 38002727}
local g_tabUnbindMainItem   = {38000954, 38000957, 38002728}
local g_tabYuanbaoMainItem  = {38000955, 38000958, 38002729}

local g_tabBindSupportItem     = {38002730, 38002732}
local g_tabUnbindSupportItem   = {38002731, 38002733}

-- 需求的金钱 5 G
local g_nNeedMoney			= 5 * 100 * 100

-- 变量
-- 主材料新背包位置
local g_nNewBagPosMainItem     = -1
-- 辅助材料新背包位置
local g_nNewBagPosSupportItem  = -1

-- 主材料旧背包位置
local g_nOldBagPosMainItem     = -1
-- 辅助材料旧背包位置
local g_nOldBagPosSupportItem  = -1
-- 是否二次确认过
local g_bComfirm               = 0

--=========================================================
-- PreLoad
--=========================================================
function StarsNineSJ_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("ADJEST_UI_POS")
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
    
    -- 放入事件
    this:RegisterEvent("CHONGZHU_CAILIAO_UP_INPUT", false)
    this:RegisterEvent("CHONGZHU_CAILIAO_UP_COMFIRM_RET", false)
end

--=========================================================
-- OnLoad
--=========================================================
function StarsNineSJ_OnLoad()
	g_StarsNineSJ_Frame_UnifiedPosition = StarsNineSJ_Frame:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function StarsNineSJ_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 920190215 ) then
		-- 0 关闭，1打开， 2刷新
		local nOpType 	= Get_XParam_INT(0)
		local objid 	= Get_XParam_INT(1)
        
        -- PushDebugMessage("nOpType"..nOpType.."objid"..objid)
		if 1 == bCaredObj then
			if objid == nil or objid < 0 then
				if this:IsVisible() then
					StarsNineSJ_OnClose()
				end
			end
		end
		
		if 0 == nOpType then
			-- 关闭界面
			if this:IsVisible() then
				StarsNineSJ_OnClose()
			end
			
		elseif 1 == nOpType then
			-- 打开界面
			-- 关注npc
			if 1 == bCaredObj then
				g_npcObjId = objid
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				BeginCareObject_StarsNineSJ()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			if this:IsVisible() then
				StarsNineSJ_OnClose()
			end
            StarsNineSJ_Reset()
            -- 关掉商店界面
            if(IsWindowShow("Shop")) then
                CloseWindow("Shop", true)
            end
			this:Show()
			StarsNineSJ_MoneyUpdate()
			StarsNineSJ_Update(1)
			
		elseif 2 == nOpType then
			-- 刷新界面
            if this:IsVisible() then
                -- g_bComfirm = 0
                -- 刷新改成清空界面了，如果哪天要改成保留的话，注意处理两种情况：1、背包物品使用之后没有物品了；2、新生成的道具占用了以前的背包格子
                StarsNineSJ_Reset()
				StarsNineSJ_Update(0)
			end
		end
	
	-- 物品改变
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		-- 刷新界面
		if this:IsVisible() then
			StarsNineSJ_Update(0)
		end
	
	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			StarsNineSJ_OnClose()
		end	
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		StarsNineSJ_OnClose()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	-- elseif event == "MONEYJZ_CHANGE_EX" then
		StarsNineSJ_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		StarsNineSJ_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        StarsNineSJ_Frame_On_ResetPos()
        
    elseif (event == "CHONGZHU_CAILIAO_UP_INPUT") then
        if this:IsVisible() and arg0 ~= nil and arg1 ~= nil then
            StarsNineSJ_Input(tonumber(arg0), tonumber(arg1))
        end		
    elseif (event == "CHONGZHU_CAILIAO_UP_COMFIRM_RET") then
        if this:IsVisible() then
            g_bComfirm = 1
        end	
	end
end


--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =StarsNineSJ
function StarsNineSJ_Update(bAutoPos)

    -- PushDebugMessage("StarsNineSJ_Update")

    -- 更新的时候如果发现已有位置的物品已经消失了，全部清空并且退出刷新逻辑
    if (g_nOldBagPosMainItem > 0 and PlayerPackage : GetBagItemNum(g_nOldBagPosMainItem) <= 0)
    or (g_nOldBagPosSupportItem > 0 and PlayerPackage : GetBagItemNum(g_nOldBagPosSupportItem) <= 0) then
        StarsNineSJ_Reset()
        return
    end

    -- 清空ActionButton
    StarsNineSJ_Object1 : SetActionItem(-1)
    StarsNineSJ_Object2 : SetActionItem(-1)
    StarsNineSJ_Object3 : SetActionItem(-1)

    -- 释放老的材料背包位置
    if g_nOldBagPosMainItem >= 0 then
        LifeAbility : Lock_Packet_Item( g_nOldBagPosMainItem, 0 )
    end
    if g_nOldBagPosSupportItem >= 0 then
        LifeAbility : Lock_Packet_Item( g_nOldBagPosSupportItem, 0 )
    end

    -- 更新背包位置
    g_nOldBagPosMainItem = g_nNewBagPosMainItem
    g_nOldBagPosSupportItem = g_nNewBagPosSupportItem

    -- 锁定新的材料背包位置，显示新的ActionButton
    if g_nNewBagPosMainItem >= 0 then
        LifeAbility : Lock_Packet_Item( g_nNewBagPosMainItem, 1 )
        local theAction = EnumAction( g_nNewBagPosMainItem, "packageitem" )
        if nil ~= theAction then
            local nActionID = theAction : GetID()
            if nActionID > 0 then 
                StarsNineSJ_Object1 : SetActionItem(nActionID)
            end
        end
    end
    if g_nNewBagPosSupportItem >= 0 then
        LifeAbility : Lock_Packet_Item( g_nNewBagPosSupportItem, 1 )
        local theAction = EnumAction( g_nNewBagPosSupportItem, "packageitem" )
        if nil ~= theAction then
            local nActionID = theAction : GetID()
            if nActionID > 0 then 
                StarsNineSJ_Object3 : SetActionItem(nActionID)
            end
        end   
    end

    -- 新生成的材料显示
    if g_nNewBagPosMainItem >= 0 then
        -- 绑定状态有三种非0值
        local nBindStatusDestItem = PlayerPackage : GetItemBindStatusByIndex(g_nNewBagPosMainItem)
        if g_nNewBagPosSupportItem >= 0 then
            nBindStatusDestItem = nBindStatusDestItem + PlayerPackage : GetItemBindStatusByIndex(g_nNewBagPosSupportItem)
        end

        local nMainLevel, bIsMatch = StarsNineSJ_GetMaterialMatchLevel(g_nNewBagPosSupportItem)

        local nDestItemID = 0
        if nBindStatusDestItem > 0 then
            -- 绑定
            nDestItemID = g_tabBindMainItem[nMainLevel + 1]
        else
            -- 非绑定
            nDestItemID = g_tabUnbindMainItem[nMainLevel + 1]
        end

        if nil ~= nDestItemID and nDestItemID > 0 then
            local theAction = DataPool:CreateActionItemForShow(nDestItemID, 1)
            if nil ~= theAction and nil ~= theAction:GetID() and theAction:GetID() > 0 then
                StarsNineSJ_Object2 : SetActionItem(theAction:GetID())
            end
        end
    end

    -- 金钱显示
    StarsNineSJ_Money   : SetProperty( "MoneyNumber", tostring(g_nNeedMoney) )

end

--=========================================================
-- 重置界面
--=========================================================
function StarsNineSJ_Reset()

    -- 清空ActionButton
    StarsNineSJ_Object1 : SetActionItem(-1)
    StarsNineSJ_Object2 : SetActionItem(-1)
    StarsNineSJ_Object3 : SetActionItem(-1)

    -- 清蒙红状态
    -- 释放老的材料背包位置
    if g_nOldBagPosMainItem >= 0 then
        LifeAbility : Lock_Packet_Item( g_nOldBagPosMainItem, 0 )
    end
    if g_nOldBagPosSupportItem >= 0 then
        LifeAbility : Lock_Packet_Item( g_nOldBagPosSupportItem, 0 )
    end

    g_nNewBagPosMainItem     = -1
    g_nNewBagPosSupportItem  = -1
    g_nOldBagPosMainItem     = -1
    g_nOldBagPosSupportItem  = -1

    g_bComfirm = 0
end

--=========================================================
-- 界面确认按钮
--=========================================================
function StarsNineSJ_ConfirmClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUpdateMaterial" )
		Set_XSCRIPT_ScriptID(890990)
		Set_XSCRIPT_Parameter(0, g_npcObjId)					
		Set_XSCRIPT_Parameter(1, g_nNewBagPosMainItem)					
        Set_XSCRIPT_Parameter(2, g_nNewBagPosSupportItem)		
        Set_XSCRIPT_Parameter(3, g_bComfirm)		
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--=========================================================
-- 放入事件 蒙红等update函数里统一做，这里只处理主辅材料的背包位置
--=========================================================
function StarsNineSJ_Input(nBagPos, nParam)
    if nil == nBagPos or nil == nParam then
        return
    end

    -- 获取物品ID
	local nItemID = PlayerPackage : GetItemTableIndex( nBagPos )
	if nItemID <= 0 then
		PushDebugMessage("非法操作")
		return
	end

    -- 拖拽放入主材料
    if 1 == nParam then
        if 0 == StarsNineSJ_IsMainMaterial(nItemID) then
            PushDebugMessage("#{JXCZ_190213_36}")
            return
        end

        if 1 == PlayerPackage:IsLock(nBagPos) then
            PushDebugMessage("#{JXCZ_190213_37}")
            return
        end

        -- 放入主材料
        g_nNewBagPosMainItem = nBagPos
        -- 清掉辅助材料
        g_nNewBagPosSupportItem = -1
    end

    -- 拖拽放入辅助材料
    if 2 == nParam then
        if 0 == StarsNineSJ_IsSupportMaterial(nItemID) then
            PushDebugMessage("#{JXCZ_190213_39}")
            return
        end

        if 1 == PlayerPackage:IsLock(nBagPos) then
            PushDebugMessage("#{JXCZ_190213_37}")
            return
        end

        -- 是否放入主材料了
        if g_nNewBagPosMainItem < 0 then
            PushDebugMessage("#{JXCZ_190213_40}")
            return
        end

        -- 材料匹配判断
        local nMainLevel, bIsMatch = StarsNineSJ_GetMaterialMatchLevel(nBagPos)
        if  0 == bIsMatch then
            if 1 == nMainLevel then
                PushDebugMessage("#{JXCZ_190213_41}")
                return
            end
    
            if 2 == nMainLevel then
                PushDebugMessage("#{JXCZ_190213_42}")
                return
            end
            return
        end

        -- 放入新的辅助材料
        g_nNewBagPosSupportItem = nBagPos
    end

    -- 右键放入材料
    if 0 == nParam then
        -- 并非功能所需材料
        if 0 == StarsNineSJ_IsMainMaterial(nItemID) and 0 == StarsNineSJ_IsSupportMaterial(nItemID) then
            PushDebugMessage("#{JXCZ_190213_43}")
            return
        end

        if 1 == PlayerPackage:IsLock(nBagPos) then
            PushDebugMessage("#{JXCZ_190213_37}")
            return
        end

        -- 主材料
        if 1 == StarsNineSJ_IsMainMaterial(nItemID) then
            -- 放入主材料
            g_nNewBagPosMainItem = nBagPos
            -- 清掉辅助材料
            g_nNewBagPosSupportItem = -1
        end

        -- 辅助材料
        if 1 == StarsNineSJ_IsSupportMaterial(nItemID) then
            -- 是否放入主材料了
            if g_nNewBagPosMainItem < 0 then
                PushDebugMessage("#{JXCZ_190213_40}")
                return
            end

            -- 材料匹配判断
            local nMainLevel, bIsMatch = StarsNineSJ_GetMaterialMatchLevel(nBagPos)
            if  0 == bIsMatch then
                if 1 == nMainLevel then
                    PushDebugMessage("#{JXCZ_190213_41}")
                    return
                end
        
                if 2 == nMainLevel then
                    PushDebugMessage("#{JXCZ_190213_42}")
                    return
                end
                return
            end

            -- 放入新的辅助材料
            g_nNewBagPosSupportItem = nBagPos
        end
    end

    -- 刷新界面
    g_bComfirm = 0
    StarsNineSJ_Update(0)
end

--=========================================================
-- 清空ActionButton 1 主材料，2 辅助材料
--=========================================================
function StarsNineSJ_ClearActionButton(nIndex)
    if nil == nIndex or nIndex < 1 or nIndex > 2 then
        return
    end

    if 1 == nIndex then
        g_nNewBagPosMainItem = -1
        g_nNewBagPosSupportItem = -1
    end

    if 2 == nIndex then
        g_nNewBagPosSupportItem = -1
    end

    -- 刷新界面
    g_bComfirm = 0
    StarsNineSJ_Update(0)
end

--=========================================================
-- 材料处理函数 -- 材料等级，1：7星，2：8星。
--=========================================================
function StarsNineSJ_IsMainMaterial(nItemID)
    if g_tabBindMainItem[1] == nItemID or g_tabBindMainItem[2] == nItemID 
    or g_tabUnbindMainItem[1] == nItemID or g_tabUnbindMainItem[2] == nItemID 
    or g_tabYuanbaoMainItem[1] == nItemID or g_tabYuanbaoMainItem[2] == nItemID then
        return 1
    end

    return 0
end

function StarsNineSJ_IsSupportMaterial(nItemID)

    if g_tabBindSupportItem[1] == nItemID or g_tabBindSupportItem[2] == nItemID 
    or g_tabUnbindSupportItem[1] == nItemID or g_tabUnbindSupportItem[2] == nItemID then
        return 1
    end

    return 0
end

function StarsNineSJ_GetMaterialMatchLevel(nBagPosSupportItem)

    -- 主材料等级
    local nMainLevel = -1
    -- 辅助材料如果匹配的话，匹配等级
    local bIsMatch = 0

    if g_nNewBagPosMainItem < 0 then
        return nMainLevel, bIsMatch
    end

    local nMainItemID = PlayerPackage : GetItemTableIndex( g_nNewBagPosMainItem )
    if nMainItemID <= 0 then
        return nMainLevel, bIsMatch
    end

    -- 材料等级，1：7星，2：8星。
    if g_tabBindMainItem[1] == nMainItemID or g_tabUnbindMainItem[1] == nMainItemID or g_tabYuanbaoMainItem[1] == nMainItemID then
        nMainLevel = 1
    end

    if g_tabBindMainItem[2] == nMainItemID or g_tabUnbindMainItem[2] == nMainItemID or g_tabYuanbaoMainItem[2] == nMainItemID then
        nMainLevel = 2
    end

    local nSupportItemID = PlayerPackage : GetItemTableIndex( nBagPosSupportItem )
    if nSupportItemID <= 0 then
        return nMainLevel, bIsMatch
    end

    if 1 == nMainLevel then
        if g_tabBindSupportItem[1] == nSupportItemID or g_tabUnbindSupportItem[1] == nSupportItemID then
            bIsMatch = 1   
        end
    end

    if 2 == nMainLevel then
        if g_tabBindSupportItem[2] == nSupportItemID or g_tabUnbindSupportItem[2] == nSupportItemID then
            bIsMatch = 1     
        end
    end

    return nMainLevel, bIsMatch
end

--=========================================================
-- 关闭界面
--=========================================================
function StarsNineSJ_OnClose()	
	this:Hide()
	StopCareObject_StarsNineSJ()
	-- 重置
	StarsNineSJ_Reset()
end

--=========================================================
-- 界面隐藏
--=========================================================
function StarsNineSJ_OnHiden()
	StopCareObject_StarsNineSJ()
	-- 重置
	StarsNineSJ_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_StarsNineSJ()
	-- 关心
	this:CareObject(g_objCared, 1, "StarsNineSJ")
end

function StopCareObject_StarsNineSJ()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "StarsNineSJ")
	end
	g_npcObjId = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function StarsNineSJ_MoneyUpdate()
    StarsNineSJ_SelfMoney   : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
    StarsNineSJ_SelfJiaozi  : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
end

--=========================================================
-- 界面位置
--=========================================================
function StarsNineSJ_Frame_On_ResetPos()
    StarsNineSJ_Frame:SetProperty("UnifiedPosition", g_StarsNineSJ_Frame_UnifiedPosition)
end