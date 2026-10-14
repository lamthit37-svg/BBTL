--******************************************************************************
-- 2021 感恩节节日礼包
--******************************************************************************
local g_Thanksgiving_Gift_Frame_UnifiedPosition	= nil

local g_Thanksgiving_Gift_BeginTime				= 20251117	--活动开始时间
local g_Thanksgiving_Gift_FinalEndTime			= 20251203	--活动结束时间
local g_Thanksgiving_Gift_LimitLevel			= 30		--活动限制等级

local g_Thanksgiving_Gift_KJID					= 27		--卡级ID
local g_Thanksgiving_Gift_FestivalGiftFlag		= 3368		--礼包领奖标识
local g_Thanksgiving_Gift_FestivalGift_ID		= 
{
	[0] = 38005569,											--原服礼包ID
	[1] = 38002994,											--卡级服礼包ID
}
--===============================================
-- OnLoad()
--===============================================
function Thanksgiving_Gift_PreLoad()
	this:RegisterEvent("THANKSGIVING_GIFT_OPENUI")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
	-- 切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Thanksgiving_Gift_OnLoad()
	-- 保存界面的默认相对位置
	g_Thanksgiving_Gift_Frame_UnifiedPosition = Thanksgiving_Gift_Frame:GetProperty("UnifiedPosition");
end


--===============================================
-- OnEvent()
--===============================================

function Thanksgiving_Gift_OnEvent(event)
	if event == "THANKSGIVING_GIFT_OPENUI" then
		Thanksgiving_Gift_OnShow()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		Thanksgiving_Gift_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Thanksgiving_Gift_Frame_On_ResetPos()
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Thanksgiving_Gift_Close()
	end
end

	
--===============================================
-- OnHiden
--===============================================
function Thanksgiving_Gift_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Thanksgiving_Gift_Frame_On_ResetPos()
	Thanksgiving_Gift_Frame:SetProperty("UnifiedPosition", g_Thanksgiving_Gift_Frame_UnifiedPosition)
end

function Thanksgiving_Gift_OnShow()

	-- 显示名字
	local szPlayerName = Player:GetName()
	Thanksgiving_Gift_LetterName:SetText(ScriptGlobal_Format("#{GEHJ_181026_109}", szPlayerName))
	-- 内容
	Thanksgiving_Gift_LetterText:SetText("#{GEHJ_181026_110}")
	-- 签名
	Thanksgiving_Gift_LetterNpc:SetText("#{GEHJ_181026_111}")

	-- 显示礼包内容
	Thanksgiving_Gift_GiftItem:SetActionItem(-1)
	local showID = Thanksgiving_Gift_GetGiftShowID()
	local theAction = DataPool:CreateActionItemForShow(showID, 1)
	if theAction:GetID() ~= 0 then
		Thanksgiving_Gift_GiftItem:SetActionItem(theAction:GetID())
		Thanksgiving_Gift_GiftItem:Show()
	end

	this:Show()

	this:Activate()
end

function Thanksgiving_Gift_CheckRightTime()
	local curDayTime = tonumber(DataPool:GetServerDayTime())
	if curDayTime >= g_Thanksgiving_Gift_BeginTime and curDayTime <= g_Thanksgiving_Gift_FinalEndTime then
		return 1  --在活动时间
	else
		return 0  --不在活动时间
	end
end

function Thanksgiving_Gift_GetGiftShowID()
	local kajiType = KaJi:LuaFnGetKaJiType(g_Thanksgiving_Gift_KJID)
	if kajiType >= 0 and kajiType <= table.getn(g_Thanksgiving_Gift_FestivalGift_ID) then
		return g_Thanksgiving_Gift_FestivalGift_ID[kajiType]
	end

	-- 默认原服
	return g_Thanksgiving_Gift_KJID[0]
end

-- 节日礼包
function Thanksgiving_Gift_GetClick()
	-- 活动时间判断
	if Thanksgiving_Gift_CheckRightTime() == 0 then  --不在活动时间
		PushDebugMessage("#{GEHJ_181026_112}")
		return
	end
	
    -- 玩家等级是否已达到30级
    local level = Player : GetData( "LEVEL" )
    if level < g_Thanksgiving_Gift_LimitLevel then
        PushDebugMessage( "#{GEHJ_181026_113}" ) 
        return
	end
	
	--是否领取过节日礼包
	if Pneuma:GetMF(g_Thanksgiving_Gift_FestivalGiftFlag) > 0 then
		PushDebugMessage( "#{GEHJ_181026_114}" )
		return
	end

	local showID = Thanksgiving_Gift_GetGiftShowID()
	-- 背包空间
	if (CalcItemSpace(showID) < 1) then
		PushDebugMessage("#{GEHJ_181026_115}")
		return
	end	

	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "FestivalGiftGet" )	-- 脚本号
		Set_XSCRIPT_ScriptID( 892831 )					-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 )						-- 参数个数
	Send_XSCRIPT()
	

	-- 关闭界面
	Thanksgiving_Gift_Close()

end
