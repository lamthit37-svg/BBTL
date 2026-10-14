-- JinLiBook 2019中秋锦鲤 2019-8-1 lishilong
-- !!!reloadscript =JinLiBook
--
local MAX_OBJ_DISTANCE 	= 3.0
local g_objCared 		= -1
local g_npcObjId 		= -1
local g_JinLiBook_Frame_UnifiedPosition
local bCaredObj 		= 0
local bCaredMoney 		= 0

-- 第x天的锦鲤
local g_nJinLiIndex     = 0
-- 全服传递 已传递
local g_bFinish02       = 0 
-- 帮会传递 已传递
local g_bFinish03       = 0  
-- 好友传递 已传递
local g_bFinish04       = 0
-- 全服传递 已领奖
local g_bGetReward02    = 0 
-- 帮会传递 已领奖
local g_bGetReward03    = 0  
-- 好友传递 已领奖 
local g_bGetReward04    = 0

local g_tabShowMsgQuanFu      =
{
    [1] = "#{ZQJL_190725_91}" ,
    [2] = "#{ZQJL_190725_92}" ,
    [3] = "#{ZQJL_190725_93}" ,
    [4] = "#{ZQJL_190725_94}" ,
    [5] = "#{ZQJL_190725_95}" ,
    [6] = "#{ZQJL_190725_96}" ,
    [7] = "#{ZQJL_190725_97}" ,
}

local g_tabShowMsgBangHui     =
{
    [1] = "#{ZQJL_190725_158}" ,
    [2] = "#{ZQJL_190725_158}" ,
    [3] = "#{ZQJL_190725_158}" ,
    [4] = "#{ZQJL_190725_158}" ,
    [5] = "#{ZQJL_190725_158}" ,
    [6] = "#{ZQJL_190725_158}" ,
    [7] = "#{ZQJL_190725_158}" ,
}

local g_tabShowMsgFriend      =
{
    [1] = "#{ZQJL_190725_164}" ,
    [2] = "#{ZQJL_190725_164}" ,
    [3] = "#{ZQJL_190725_164}" ,
    [4] = "#{ZQJL_190725_164}" ,
    [5] = "#{ZQJL_190725_164}" ,
    [6] = "#{ZQJL_190725_164}" ,
    [7] = "#{ZQJL_190725_164}" ,
}

--=========================================================
-- PreLoad
--=========================================================
function JinLiBook_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	-- this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false)
	if 1 == bCaredMoney then
		this:RegisterEvent("MONEY_CHANGE_EX", false)
		this:RegisterEvent("MONEYJZ_CHANGE_EX", false)
	end
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
end

--=========================================================
-- OnLoad
--=========================================================
function JinLiBook_OnLoad()
	g_JinLiBook_Frame_UnifiedPosition = JinLiBook_MainFrame:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function JinLiBook_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 79002002 ) then
		-- 0 关闭，1打开， 2刷新
		local nOpType 	= Get_XParam_INT(0)
		local objid 	= Get_XParam_INT(1)
		
		if 1 == bCaredObj then
			if objid == nil or objid < 0 then
				if this:IsVisible() then
					JinLiBook_OnClose()
				end
			end
		end
		
		if 0 == nOpType then
			-- 关闭界面
			if this:IsVisible() then
				JinLiBook_OnClose()
			end
			
		elseif 1 == nOpType then
			-- 打开界面
			-- 关注npc
			if 1 == bCaredObj then
				g_npcObjId = objid
				g_objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
				BeginCareObject_JinLiBook()
			end

			-- 显示界面
			-- 为了解决界面被遮挡的问题，先把界面关了
			-- if this:IsVisible() then
			-- 	JinLiBook_OnClose()
			-- end
			JinLiBook_Reset()
			JinLiBook_Frame_On_ResetPos()
			this:Show()
			JinLiBook_ParamInit()
			JinLiBook_MoneyUpdate()
			JinLiBook_Update(1)
			
		elseif 2 == nOpType then
			-- 刷新界面
			if this:IsVisible() then
				JinLiBook_ParamInit()
				JinLiBook_Update(0)
			end
		end
	
	-- 物品改变
	-- elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
	-- 	-- 刷新界面
	-- 	if this:IsVisible() then
	-- 		JinLiBook_Update(0)
	-- 	end
	
	-- ============================================
	-- 通用逻辑
	elseif ( event == "OBJECT_CARED_EVENT" ) and 1 == bCaredObj then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			-- 关闭界面
			JinLiBook_OnClose()
		end	
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		JinLiBook_OnClose()
	
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
	-- elseif event == "MONEYJZ_CHANGE_EX" then
		JinLiBook_MoneyUpdate()
	
	elseif (event == "ADJEST_UI_POS" ) then
		JinLiBook_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JinLiBook_Frame_On_ResetPos()
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function JinLiBook_ParamInit()
    g_nJinLiIndex   = Get_XParam_INT(2)
    g_bFinish02     = Get_XParam_INT(3)
    g_bFinish03     = Get_XParam_INT(4)
    g_bFinish04     = Get_XParam_INT(5)
    g_bGetReward02  = Get_XParam_INT(6)
    g_bGetReward03  = Get_XParam_INT(7)
    g_bGetReward04  = Get_XParam_INT(8)
end

--=========================================================
-- 界面更新
--=========================================================
-- !!!reloadscript =JinLiBook
function JinLiBook_Update(bOpen)

    -- 全服锦鲤描述文字
    if 1 == g_bFinish02 then
        JinLiBook_InfoBK1_Text : SetText("#{ZQJL_190725_98}")
    else
        JinLiBook_InfoBK1_Text : SetText(g_tabShowMsgQuanFu[1])
        if nil ~= g_tabShowMsgQuanFu[g_nJinLiIndex] then
            JinLiBook_InfoBK1_Text : SetText(g_tabShowMsgQuanFu[g_nJinLiIndex])
        end        
    end

    -- 帮会锦鲤描述文字
    if 1 == g_bFinish03 then
        JinLiBook_InfoBK2_Text : SetText("#{ZQJL_190725_98}")
    else
        JinLiBook_InfoBK2_Text : SetText(g_tabShowMsgBangHui[1])
        if nil ~= g_tabShowMsgBangHui[g_nJinLiIndex] then
            JinLiBook_InfoBK2_Text : SetText(g_tabShowMsgBangHui[g_nJinLiIndex])
        end    
    end

    -- 好友锦鲤描述文字
    if 1 == g_bFinish04 then
        JinLiBook_InfoBK3_Text : SetText("#{ZQJL_190725_104}")
    else
        JinLiBook_InfoBK3_Text : SetText(g_tabShowMsgFriend[1])
        if nil ~= g_tabShowMsgFriend[g_nJinLiIndex] then
            JinLiBook_InfoBK3_Text : SetText(g_tabShowMsgFriend[g_nJinLiIndex])
        end        
    end

    -- 已领取图片
    if 1 == g_bGetReward02 then
        JinLiBook_InfoBK1_Image : Show()
        JinLiBook_InfoBK1_Button : SetToolTip("#{ZQJL_190725_221}") 
    else
        JinLiBook_InfoBK1_Image : Hide()
        JinLiBook_InfoBK1_Button : SetToolTip("#{ZQJL_190725_220}") 
    end

    if 1 == g_bGetReward03 then
        JinLiBook_InfoBK2_Image : Show()
        JinLiBook_InfoBK2_Button : SetToolTip("#{ZQJL_190725_223}") 
    else
        JinLiBook_InfoBK2_Image : Hide()
        JinLiBook_InfoBK2_Button : SetToolTip("#{ZQJL_190725_222}") 
    end

    if 1 == g_bGetReward04 then
        JinLiBook_InfoBK3_Image : Show()
        JinLiBook_InfoBK3_Button : SetToolTip("#{ZQJL_190725_225}") 
    else
        JinLiBook_InfoBK3_Image : Hide()
        JinLiBook_InfoBK3_Button : SetToolTip("#{ZQJL_190725_224}") 
    end
end

--=========================================================
-- 重置界面
--=========================================================
function JinLiBook_Reset()

end

--=========================================================
-- 界面确认按钮
--=========================================================
function JinLiBook_ConfirmClick(nParam)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIEvent" )
		Set_XSCRIPT_ScriptID(790020)
		Set_XSCRIPT_Parameter(0, -1)							
		Set_XSCRIPT_Parameter(1, nParam)							
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--=========================================================
-- 关闭界面
--=========================================================
function JinLiBook_OnClose()	
	this:Hide()
	StopCareObject_JinLiBook()
	-- 重置
	JinLiBook_Reset()
end

--=========================================================
-- 界面隐藏
--=========================================================
function JinLiBook_OnHiden()
	StopCareObject_JinLiBook()
	-- 重置
	JinLiBook_Reset()
end

--=========================================================
-- 关心操作
--=========================================================
function BeginCareObject_JinLiBook()
	-- 关心
	this:CareObject(g_objCared, 1, "JinLiBook")
end

function StopCareObject_JinLiBook()
	-- 取消关心
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "JinLiBook")
	end
	g_npcObjId = -1
end

--=========================================================
-- 金钱刷新：界面更新调用一次 金钱事件调用一次
--=========================================================
function JinLiBook_MoneyUpdate()
end

--=========================================================
-- 界面位置
--=========================================================
function JinLiBook_Frame_On_ResetPos()
	JinLiBook_MainFrame:SetProperty("UnifiedPosition", g_JinLiBook_Frame_UnifiedPosition)
end