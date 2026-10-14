local g_HuazhaoFrame_UnifiedPosition 

-- 活动奖励
local g_HuazhaoHuoDongJiangLi = 
{
	[0] = {
		[1] = {	name = "#{HZJZH_211221_17}", item = {39921547,39921549,39922184,39920574,39921313},}, 
		[2] = {	name = "#{HZJZH_211221_19}", item = {38007787,39922686,39921545,39923747,39925258,},}, 
		[3] = {	name = "#{HZJZH_211221_41}", item = {10147230,39924617,39924618,39924619,39924534,},}, 
	},
	[1] = {
		[1] = {	name = "#{HZJZH_211221_17}", item = {39920397,39920396,39920235,39920574,39921313},}, 
		[2] = {	name = "#{HZJZH_211221_19}", item = {39925258,39923743,39920817,39920566,39920565,},}, 
		[3] = {	name = "#{HZJZH_211221_41}", item = {10147230,39924617,39924618,39924619,39924534,},}, 
	}
} 
local g_HuazhaoHuoDongJiangLi_OriginalJD = 
{
	[1] = {	name = "#{HZJZH_211221_17}", item = {39921547,39921549,39920235,39920574,39921313},}, 
	[2] = {	name = "#{HZJZH_211221_19}", item = {39925258,39923743,39920817,39920566,39920565,},}, 
	[3] = {	name = "#{HZJZH_211221_41}", item = {10147230,39924617,39924618,39924619,39924534,},}, 
} 
local g_Huazhao_nContentButton = {}
local g_Huazhao_Reward = {
"HuaZhaoJie_AllReward_RewardItem1",
"HuaZhaoJie_AllReward_RewardItem2",
"HuaZhaoJie_AllReward_RewardItem3",
"HuaZhaoJie_AllReward_RewardItem4",
"HuaZhaoJie_AllReward_RewardItem5",
}

--=========
-- PreLoad()
--=========
function HuaZhaoJie_AllReward_PreLoad()
 
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false) 
end

--=========
-- OnLoad()
--=========
function HuaZhaoJie_AllReward_OnLoad()

	
	g_HuazhaoFrame_UnifiedPosition = HuaZhaoJie_AllReward_Frame:GetProperty("UnifiedPosition")
	HuaZhaoJie_AllReward_LoadControl()

end

--=========
-- Event
--=========
function HuaZhaoJie_AllReward_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88892600) then	
		HuaZhaoJie_AllReward_Open()
		this:Show()
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		HuaZhaoJie_AllReward_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		HuaZhaoJie_AllReward_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

        HuaZhaoJie_AllReward_On_ResetPos()
        		 
	end

end

function HuaZhaoJie_AllReward_Close()
	for i = 1, table.getn(g_Huazhao_nContentButton) do
		for j = 1, table.getn(g_Huazhao_Reward) do
			g_Huazhao_nContentButton[i]:GetSubItem(g_Huazhao_Reward[j]):SetActionItem(-1)
		end
	end			
	HuaZhaoJie_AllReward_Page2List:Clear()		
	g_Huazhao_nContentButton = {}
	this:Hide()
end

--=========
-- 重置
--=========
function HuaZhaoJie_AllReward_On_ResetPos()

	HuaZhaoJie_AllReward_Frame:SetProperty("UnifiedPosition", g_HuazhaoFrame_UnifiedPosition)

end

--=========
-- 装载控件
--=========
function HuaZhaoJie_AllReward_LoadControl() 
end

--=========
-- 打开
--=========
function HuaZhaoJie_AllReward_Open()
    HuaZhaoJie_AllReward_Updata_HDJL()
end 
  
--=========
-- 问号帮助
--=========
function HuaZhaoJie_AllReward_Help_Clicked()
	PushEvent("CCSHOP_HELP", 116)
end
 

--=========
-- 填充活动奖励界面
--=========
function HuaZhaoJie_AllReward_Updata_HDJL()

	for i = 1, table.getn(g_Huazhao_nContentButton) do
		for j = 1, table.getn(g_Huazhao_Reward) do
            g_Huazhao_nContentButton[i]:GetSubItem(g_Huazhao_Reward[j]):SetActionItem(-1)            
		end
	end			
	HuaZhaoJie_AllReward_Page2List:Clear()		
	g_Huazhao_nContentButton = {}
	local kjtype   = KaJi:LuaFnGetKaJiType(61)
	local iteminfo = g_HuazhaoHuoDongJiangLi[kjtype]
	if Player:GetData("IsOriginalJD") == 1 then
		iteminfo = g_HuazhaoHuoDongJiangLi_OriginalJD
	end
	for nIndex=1,table.getn(iteminfo) do
		local bar = HuaZhaoJie_AllReward_Page2List:AddChild("HuaZhaoJie_AllReward_Page2List_Content")
		if nil ~= bar then
            bar:GetSubItem("HuaZhaoJie_AllReward_RewardText"):SetText(iteminfo[nIndex].name)
            for index=1, table.getn(g_Huazhao_Reward) do
                if iteminfo[nIndex].item[index] ~= nil and  iteminfo[nIndex].item[index] > 0 then
                    local theAction = DataPool:CreateActionItemForShow(iteminfo[nIndex].item[index], 1)
				    if theAction:GetID() ~= 0 then
				    	bar:GetSubItem(g_Huazhao_Reward[index]):SetActionItem(theAction:GetID());
				    	bar:GetSubItem(g_Huazhao_Reward[index]):Show()
                    end                
			    else
				    bar:GetSubItem(g_Huazhao_Reward[index]):Hide()
                end
            end  
			g_Huazhao_nContentButton[nIndex] = bar
		end
	end
	
end 