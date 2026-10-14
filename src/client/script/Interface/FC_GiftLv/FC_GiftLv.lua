-- !!!reloadscript =FC_GiftLv
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local m_AwardData = 
{
	[1] = { --第一名
		{ItemId=39925309, Num=1, Bind=1,},
		{ItemId=10147566, Num=1, Bind=1},
		{ItemId=38008499, Num=10, Bind=1},
		{ItemId=20502004, Num=5, Bind=1},
		{ItemId=20501004, Num=5, Bind=1},
	},
	[2] = { --第二名
		{ItemId=39925310, Num=1, Bind=1,},
		{ItemId=10147565, Num=1, Bind=1},
		{ItemId=38008499, Num=8, Bind=1},
		{ItemId=20502004, Num=4, Bind=1},
		{ItemId=20501004, Num=4, Bind=1},
	},
	[3] = { --第3到4名
		{ItemId=39925311, Num=1, Bind=1,},
		{ItemId=10147564, Num=1, Bind=1},
		{ItemId=38008499, Num=6, Bind=1},
		{ItemId=20502004, Num=3, Bind=1},
		{ItemId=20501004, Num=3, Bind=1},
	},
	[4] = { --第5到8名
		{ItemId=38008499, Num=4, Bind=1},
		{ItemId=20502004, Num=2, Bind=1},
		{ItemId=20501004, Num=2, Bind=1},
	},
	[5] = { --第9到16名
		{ItemId=38008499, Num=3, Bind=1},
		{ItemId=20502004, Num=1, Bind=1},
		{ItemId=20501004, Num=1, Bind=1},
	},
	[6] = { --第17到32名
		{ItemId=38008499, Num=2, Bind=1},
		{ItemId=20502003, Num=1, Bind=1},
		{ItemId=20501003, Num=1, Bind=1},
	},
}
local m_AwardIconUI = {}
--预加载函数，可以而且只能在这里注册脚本关心的事件
function FC_GiftLv_PreLoad()
	this:RegisterEvent("ZJZDPVP_UIOP", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FC_GiftLv_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= FC_GiftLv_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= FC_GiftLv_Frame:GetProperty("UnifiedYPosition");

	for i=1, 6 do
		m_AwardIconUI[i] = {}
		for k=1, 6 do
			m_AwardIconUI[i][k] = _G["FC_GiftLv_Icon"..i.."_"..k]
		end
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FC_GiftLv_ResetPos()
	FC_GiftLv_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	FC_GiftLv_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function FC_GiftLv_OnEvent(event)
	if( event == "ZJZDPVP_UIOP" ) then--
		-- PushDebugMessage("111111111111111111")
		local opType = tonumber(arg0)
		if opType == 10 then
			if (this:IsVisible()) then
				FC_GiftLv_Update()
				return
			end
			FC_GiftLv_Show()
			FC_GiftLv_Update()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FC_GiftLv_Hide()
	elseif event == "ADJEST_UI_POS" then
		FC_GiftLv_ResetPos()
	end
end

--显示UI
function FC_GiftLv_Show()
	FC_GiftLv_ClearData()
	this:Show()
	
end
--隐藏UI
function FC_GiftLv_Hide()
	FC_GiftLv_ClearData()

	this:Hide()
end

--清除数据
function FC_GiftLv_ClearData()
end
--更新
function FC_GiftLv_Update()
	for i = 1, 6 do
		local dataLength = table.getn(m_AwardData[i])
		for k = 1, dataLength do
			local theAction = DataPool:CreateBindActionItemForShow(m_AwardData[i][k].ItemId, m_AwardData[i][k].Num)
			if theAction:GetID() ~= 0 then
				m_AwardIconUI[i][k]:Show()
				m_AwardIconUI[i][k]:SetActionItem(theAction:GetID())
			end
		end
		for m = dataLength + 1, 6 do
			m_AwardIconUI[i][m]:Hide()
		end

	end
end
--##############点击事件##############
--####################################