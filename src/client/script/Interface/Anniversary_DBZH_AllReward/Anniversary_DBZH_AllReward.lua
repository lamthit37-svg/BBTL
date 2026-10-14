local g_Frame_UnifiedPosition

local g_ShowReward =
{
	[1] = {	name = "#{ZNDB_230215_19}", item = {39922684,39920946}, num ={3,2}},
	[2] = {	name = "#{ZNDB_230215_20}", item = {39922684,39920946,39920092}, num ={5,3,1}},
	[3] = {	name = "#{ZNDB_230215_21}", item = {39924239,39922685,39920946,39920092}, num ={1,3,3,1}},
	[4] = {	name = "#{ZNDB_230215_22}", item = {39924239,39922685,39920946,39920092,39920339}, num ={1,5,5,2,1}},
	[5] = {	name = "#{ZNDB_230215_23}", item = {39924239,39922685,39920946,39920093,39920339}, num ={1,5,5,1,2}},
	[6] = {	name = "#{ZNDB_230215_24}", item = {39925305,39920329,39920296,39920574}, num ={1,1,2,2}}
}

local g_ShowReward_kaji =
{
	[1] = {	name = "#{ZNDB_230215_19}", item = {39923970,39923724}, num ={1,1}},
	[2] = {	name = "#{ZNDB_230215_20}", item = {39923970,39920332,39923724}, num ={1,1,2}},
	[3] = {	name = "#{ZNDB_230215_21}", item = {39924239,39924255,39920332,39923724}, num ={1,1,1,2}},
	[4] = {	name = "#{ZNDB_230215_22}", item = {39924239,39924255,39920332,39923724}, num ={1,2,2,3}},
	[5] = {	name = "#{ZNDB_230215_23}", item = {39924239,39920333,39924255,39920332,39923724}, num ={1,1,2,2,3}},
	[6] = {	name = "#{ZNDB_230215_24}", item = {39925305,39920329,39920334,39920574}, num ={1,1,1,2}}
}

local g_ShowReward_origin =
{
	[1] = {	name = "#{ZNDB_230215_19}", item = {39923970,39923724}, num ={1,1}},
	[2] = {	name = "#{ZNDB_230215_20}", item = {39923970,39920332,39923724}, num ={1,1,2}},
	[3] = {	name = "#{ZNDB_230215_21}", item = {39924239,39924255,39920332,39923724}, num ={1,1,1,2}},
	[4] = {	name = "#{ZNDB_230215_22}", item = {39924239,39924255,39920332,39923724}, num ={1,2,2,3}},
	[5] = {	name = "#{ZNDB_230215_23}", item = {39924239,39920333,39924255,39920332,39923724}, num ={1,1,2,2,3}},
	[6] = {	name = "#{ZNDB_230215_24}", item = {39925305,39920329,39920296,39920574}, num ={1,1,2,2}}
}

local g_Item_Reward = {
	"Anniversary_DBZH_AllReward_RewardItem1",
	"Anniversary_DBZH_AllReward_RewardItem2",
	"Anniversary_DBZH_AllReward_RewardItem3",
	"Anniversary_DBZH_AllReward_RewardItem4",
	"Anniversary_DBZH_AllReward_RewardItem5",
	}

local rewardTable = {}

--=========
-- PreLoad()
--=========
function Anniversary_DBZH_AllReward_PreLoad()

	this:RegisterEvent("UI_COMMAND")--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("ADJEST_UI_POS")
	
end

--=========
-- OnLoad()
--=========
function Anniversary_DBZH_AllReward_OnLoad()
	g_Frame_UnifiedPosition = Anniversary_DBZH_AllReward_Frame:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function Anniversary_DBZH_AllReward_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0)== 99844402 ) then
		Anniversary_DBZH_AllReward_SetFrame()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
        this:Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Anniversary_DBZH_AllReward_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Anniversary_DBZH_AllReward_On_ResetPos()
    end

end


function Anniversary_DBZH_AllReward_SetFrame()
	Anniversary_DBZH_AllReward_Page2List:Clear()

	Anniversary_DBZH_AllReward_Page2TopList_Pic1Text:SetText("#{ZNDB_230215_18}")
	Anniversary_DBZH_AllReward_Page2TopList_Pic2Text:SetText("#{ZNDB_230215_25}")


	if Player:GetData("IsOriginalJD") == 1 then
		rewardTable = g_ShowReward_origin
	elseif KaJi:LuaFnIsKaJiServer() == 1 then
		rewardTable = g_ShowReward_kaji
	else
		rewardTable = g_ShowReward
	end



	for nIndex=1,table.getn(rewardTable) do
		local bar = Anniversary_DBZH_AllReward_Page2List:AddChild("Anniversary_DBZH_AllReward_Page2List_Content")
		if nil ~= bar then
            bar:GetSubItem("Anniversary_DBZH_AllReward_RewardText"):SetText(rewardTable[nIndex].name)
            for index=1, table.getn(g_Item_Reward) do
                if rewardTable[nIndex].item[index] ~= nil and  rewardTable[nIndex].item[index] > 0 then
                    local theAction = DataPool:CreateActionItemForShow(rewardTable[nIndex].item[index], rewardTable[nIndex].num[index])
				    if theAction:GetID() ~= 0 then
				    	bar:GetSubItem(g_Item_Reward[index]):SetActionItem(theAction:GetID());
				    	bar:GetSubItem(g_Item_Reward[index]):Show()
                    end                
			    else
				    bar:GetSubItem(g_Item_Reward[index]):Hide()
                end
            end  
			g_BangHuiHuoYue_nContentButton[nIndex] = bar
		end
	end
	this:Show()
end

function Anniversary_DBZH_AllReward_Close()
	this:Hide()
end

--=========
--重置
--=========
function Anniversary_DBZH_AllReward_On_ResetPos()
	Anniversary_DBZH_AllReward_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end





