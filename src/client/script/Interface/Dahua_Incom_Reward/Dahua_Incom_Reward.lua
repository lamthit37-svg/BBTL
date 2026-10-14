local g_Dahua_Incom_RewardFrame_UnifiedPosition 

-- 活动奖励
local g_Dahua_Incom_JiangLi = 
{
	[1] = {	name = "#{DHLS_240611_12}", item = {39924763,39924764,39924761,39924762,39924765},num={1,1,1,1,1,},},  
	[2] = {	name = "#{DHLS_240611_14}", item = {39924760,39924760,39924760,39924760,},num={20,10,5,2,},}, 
} 

local g_Dahua_Incom_ctl = {} 
--=========
-- PreLoad()
--=========
function Dahua_Incom_Reward_PreLoad()
	this:RegisterEvent("OPEN_DAHUA_GIFT_PREVIEW", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false) 
end

--=========
-- OnLoad()
--=========
function Dahua_Incom_Reward_OnLoad() 
	g_Dahua_Incom_RewardFrame_UnifiedPosition = Dahua_Incom_Reward_Frame:GetProperty("UnifiedPosition")
	Dahua_Incom_Reward_LoadControl()
end

--=========
-- Event
--=========
function Dahua_Incom_Reward_OnEvent(event)

	if(event == "OPEN_DAHUA_GIFT_PREVIEW") then	
		Dahua_Incom_Reward_Open()
		this:Show()
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Dahua_Incom_Reward_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Dahua_Incom_Reward_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

        Dahua_Incom_Reward_On_ResetPos()
        		 
	end

end

function Dahua_Incom_Reward_Close() 
	this:Hide()
end

--=========
-- 重置
--=========
function Dahua_Incom_Reward_On_ResetPos()

	Dahua_Incom_Reward_Frame:SetProperty("UnifiedPosition", g_Dahua_Incom_RewardFrame_UnifiedPosition)

end
 
--=========
-- 打开
--=========
function Dahua_Incom_Reward_Open()
    Dahua_Incom_Reward_Updata()
end 
   
function Dahua_Incom_Reward_LoadControl()
    g_Dahua_Incom_ctl[1] = {}
    g_Dahua_Incom_ctl[1].text = Dahua_Incom_Reward_AwardInfo1
    g_Dahua_Incom_ctl[1].icon = {}
    g_Dahua_Incom_ctl[1].icon[1] = Dahua_Incom_Reward_Icon1
    g_Dahua_Incom_ctl[1].icon[2] = Dahua_Incom_Reward_Icon1_2
    g_Dahua_Incom_ctl[1].icon[3] = Dahua_Incom_Reward_Icon1_3
    g_Dahua_Incom_ctl[1].icon[4] = Dahua_Incom_Reward_Icon1_4
    g_Dahua_Incom_ctl[1].icon[5] = Dahua_Incom_Reward_Icon1_5 
    
    g_Dahua_Incom_ctl[2] = {}
    g_Dahua_Incom_ctl[2].text = Dahua_Incom_Reward_AwardInfo3
    g_Dahua_Incom_ctl[2].icon = {}
    g_Dahua_Incom_ctl[2].icon[1] = Dahua_Incom_Reward_Icon3
    g_Dahua_Incom_ctl[2].icon[2] = Dahua_Incom_Reward_Icon3_2
    g_Dahua_Incom_ctl[2].icon[3] = Dahua_Incom_Reward_Icon3_3
    g_Dahua_Incom_ctl[2].icon[4] = Dahua_Incom_Reward_Icon3_4 
end 

--=========
-- 填充活动奖励界面
--=========
function Dahua_Incom_Reward_Updata()
    for ctl = 1, table.getn(g_Dahua_Incom_ctl) do
        for icon = 1, table.getn(g_Dahua_Incom_ctl[ctl].icon) do
            g_Dahua_Incom_ctl[ctl].icon[icon]:Hide()
        end
    end
    
    for ctl = 1, table.getn(g_Dahua_Incom_JiangLi) do 
        g_Dahua_Incom_ctl[ctl].text:SetText(g_Dahua_Incom_JiangLi[ctl].name)
        for idx = 1, table.getn(g_Dahua_Incom_JiangLi[ctl].item) do
            local theAction = DataPool:CreateActionItemForShow(g_Dahua_Incom_JiangLi[ctl].item[idx], g_Dahua_Incom_JiangLi[ctl].num[idx])
            if theAction:GetID() ~= 0 then
                g_Dahua_Incom_ctl[ctl].icon[idx]:Show( )
                g_Dahua_Incom_ctl[ctl].icon[idx]:SetActionItem(theAction:GetID()) 
            end   
        end
    end
end 