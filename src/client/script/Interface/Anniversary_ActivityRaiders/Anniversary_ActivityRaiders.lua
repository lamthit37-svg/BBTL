local g_AnniversaryFrame_UnifiedPosition 

-- 活动奖励
local g_AnniversaryJiangLi = 
{
	[0] = {
		[1] = {	name = "#{HZJZH_211221_17}", item = {39921547,39921549,39922184,39920574,39921313},}, 
		[2] = {	name = "#{HZJZH_211221_19}", item = {39923742,39921965,39924024,39923743,39923747,},}, 
	},
	[1] = {
		[1] = {	name = "#{HZJZH_211221_17}", item = {39921547,39921549,39920235,39920574,39921313},}, 
		[2] = {	name = "#{HZJZH_211221_19}", item = {39923742,39921965,39924024,39923743,39920817,},}, 
	}
} 

local g_Anniversary_nContentButton = {}
local g_Anniversary_Reward = {
"Anniversary_ActivityRaiders_RewardItem1",
"Anniversary_ActivityRaiders_RewardItem2",
"Anniversary_ActivityRaiders_RewardItem3",
"Anniversary_ActivityRaiders_RewardItem4",
"Anniversary_ActivityRaiders_RewardItem5",
}

--=========
-- PreLoad()
--=========
function Anniversary_ActivityRaiders_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false) 
	
end

--=========
-- OnLoad()
--=========
function Anniversary_ActivityRaiders_OnLoad()
	
	g_AnniversaryFrame_UnifiedPosition = Anniversary_ActivityRaiders_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function Anniversary_ActivityRaiders_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 23200400) then	
	
		Anniversary_ActivityRaiders_Open()
		this:Show()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Anniversary_ActivityRaiders_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Anniversary_ActivityRaiders_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

        Anniversary_ActivityRaiders_On_ResetPos()
        		 
	end

end

function Anniversary_ActivityRaiders_OnClose()

	for i = 1, table.getn(g_Anniversary_nContentButton) do
		for j = 1, table.getn(g_Anniversary_Reward) do
			g_Anniversary_nContentButton[i]:GetSubItem(g_Anniversary_Reward[j]):SetActionItem(-1)
		end
	end			
	Anniversary_ActivityRaiders_Page2List:Clear()		
	g_Anniversary_nContentButton = {}
	this:Hide()
	
end

--=========
-- 重置
--=========
function Anniversary_ActivityRaiders_On_ResetPos()

	Anniversary_ActivityRaiders_Frame:SetProperty("UnifiedPosition", g_AnniversaryFrame_UnifiedPosition)

end

--=========
-- 打开
--=========
function Anniversary_ActivityRaiders_Open()

    Anniversary_ActivityRaiders_Updata_HDJL()
	
end  

--=========
-- 填充活动奖励界面
--=========
function Anniversary_ActivityRaiders_Updata_HDJL()

	for i = 1, table.getn(g_Anniversary_nContentButton) do
		for j = 1, table.getn(g_Anniversary_Reward) do
            g_Anniversary_nContentButton[i]:GetSubItem(g_Anniversary_Reward[j]):SetActionItem(-1)            
		end
	end			
	Anniversary_ActivityRaiders_Page2List:Clear()		
	g_Anniversary_nContentButton = {}
	local kjtype   = KaJi:LuaFnGetKaJiType(71)
	local iteminfo = g_AnniversaryJiangLi[kjtype]
	for nIndex=1,table.getn(iteminfo) do
		local bar = Anniversary_ActivityRaiders_Page2List:AddChild("Anniversary_ActivityRaiders_Page2List_Content")
		if nil ~= bar then
            bar:GetSubItem("Anniversary_ActivityRaiders_RewardText"):SetText(iteminfo[nIndex].name)
            for index=1, table.getn(g_Anniversary_Reward) do
                if iteminfo[nIndex].item[index] ~= nil and  iteminfo[nIndex].item[index] > 0 then
                    local theAction = DataPool:CreateActionItemForShow(iteminfo[nIndex].item[index], 1)
				    if theAction:GetID() ~= 0 then
				    	bar:GetSubItem(g_Anniversary_Reward[index]):SetActionItem(theAction:GetID());
				    	bar:GetSubItem(g_Anniversary_Reward[index]):Show()
                    end                
			    else
				    bar:GetSubItem(g_Anniversary_Reward[index]):Hide()
                end
            end  
			g_Anniversary_nContentButton[nIndex] = bar
		end
	end
	
end 
