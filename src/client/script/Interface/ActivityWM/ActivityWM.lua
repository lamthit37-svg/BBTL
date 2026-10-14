local g_ActivityWM_UnifiedPosition    

--===============================================
--付费
--===============================================
local g_ActivityWM_LoadFirstTime = 1
local g_ActivityWM_ScrollbarPosition = 0
--显示奖励物品配表
local g_ActivityWM_Gifts = {
	[1] = 	{
        {GiftItemID = 38004734, num = 10,},{GiftItemID = 38006287, num = 2,}
		,},
	[2] =	{         
        {GiftItemID = 38004734, num = 30,},{GiftItemID = 38006287, num = 4,}
		,},
	[3] =   {
        {GiftItemID = 38004734, num = 60,},{GiftItemID = 38006317, num = 1,},{GiftItemID = 38006287, num = 6,}
		,}, 
}
 
local g_ActivityWM_ButtonState = {
	[1] =0,
	[2] =0,
	[3] =0, 
};
local g_ActivityWM_GetGiftsCondition =
{
	[1] = { Exch = 8000, Cost = 0, },
	[2] = { Exch = 20000, Cost = 0, },
	[3] = { Exch = 40000, Cost = 0, }, 
}
local g_ActivityWM_Cost =0;
local g_ActivityWM_Exch =0;
local g_ActivityWM_ContentButton = {}
local g_ActivityWM_CurrentSelect = 0;
-- 
local g_ActivityWM_GiftsImage = {
	[1] = "set:BaiBao image:BaiBao_1",
	[2] = "set:BaiBao image:BaiBao_2",
	[3] = "set:BaiBao image:BaiBao_3",
}

--=========
-- PreLoad()
--=========
function ActivityWM_PreLoad() 
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("OPEN_ActivityWM",true)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)  
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("OPEN_WANMEITIANLONG", true)--打开or刷新界面
end

--=========
-- OnLoad()
--=========
function ActivityWM_OnLoad() 
	g_ActivityWM_UnifiedPosition = ActivityWM_Frame:GetProperty("UnifiedPosition") 
end

--=========
-- Event
--=========
function ActivityWM_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99846901) then
        ActivityWM_UpdateInfo()
    elseif event == "OPEN_WANMEITIANLONG" then
		this:Show() 
        ActivityWM_Show() 
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ActivityWM_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		ActivityWM_OnHiden()
	elseif event == "ADJEST_UI_POS" then
        ActivityWM_On_ResetPos() 	
	end 
end
 

--=========
-- 重置
--=========
function ActivityWM_On_ResetPos()
	ActivityWM_Frame:SetProperty("UnifiedPosition", g_ActivityWM_UnifiedPosition) 
end

function ActivityWM_OnHiden()
    this:Hide()
end

function ActivityWM_Show()
	ActivityWM_UpdateButtonReq();   
end

function ActivityWM_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsInfo" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998469 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function ActivityWM_UpdateInfo() 
	g_ActivityWM_Exch  = Get_XParam_INT(0)
	g_ActivityWM_Cost  = Get_XParam_INT(1)
	for i=1,table.getn(g_ActivityWM_ButtonState) do
		g_ActivityWM_ButtonState[i] = Get_XParam_INT(i+1)		
	end 
	ActivityWM_FlushWindow()
end

function ActivityWM_FlushWindow()
	ActivityWM_ItemClient:Clear()	
	for i = 1, table.getn(g_ActivityWM_Gifts) do
		local bar = ActivityWM_ItemClient:AddChild("ActivityWM_RightAItem1")
		if not bar then
			PushDebugMessage("break")
		   	break
		end	  
		for j = 1, 3 do
			if g_ActivityWM_Gifts[i][j] == nil then
				local ctlname = string.format("ActivityWM_Icon0%d", j) 
				bar:GetSubItem(ctlname):Hide()
				continue
			end
			local ctlname = string.format("ActivityWM_Icon0%d", j) 
			bar:GetSubItem(ctlname):Show()
			local GiftID = g_ActivityWM_Gifts[i][j].GiftItemID
			local num    = g_ActivityWM_Gifts[i][j].num
			local theAction = DataPool:CreateActionItemForShow(GiftID, num)
			if theAction:GetID() ~= 0 then
				bar:GetSubItem(ctlname):SetActionItem(theAction:GetID());
				bar:GetSubItem(ctlname):Show();
			end 
		end 
		
		bar:GetSubItem("ActivityWM_Btn"):SetEvent("MouseLClick", string.format("ActivityWM_GetGiftsForCostYuanBao(%d)", i))	
		if g_ActivityWM_ButtonState[i] == 0 then --未达成
			bar:GetSubItem("ActivityWM_Btn"):Disable()
			bar:GetSubItem("ActivityWM_Btn"):SetText("#{WMTL_230301_08}")
		elseif g_ActivityWM_ButtonState[i] == 1 then --领取
			bar:GetSubItem("ActivityWM_Btn"):Enable()
			bar:GetSubItem("ActivityWM_Btn"):SetText("#{WMTL_230301_07}")
		elseif g_ActivityWM_ButtonState[i] == 2 then --已领取
			bar:GetSubItem("ActivityWM_Btn"):Disable()
			bar:GetSubItem("ActivityWM_Btn"):SetText("#{WMTL_230301_31}")
		end
		if g_ActivityWM_Exch >= g_ActivityWM_GetGiftsCondition[i].Exch then
			local exchstr = ScriptGlobal_Format("#{WMTL_230301_06}",g_ActivityWM_GetGiftsCondition[i].Exch,g_ActivityWM_GetGiftsCondition[i].Exch)
			bar:GetSubItem("ActivityWM_RightAItem1_Name"):SetText(exchstr)
		else
			local exchstr = ScriptGlobal_Format("#{WMTL_230301_32}",g_ActivityWM_Exch,g_ActivityWM_GetGiftsCondition[i].Exch)
			bar:GetSubItem("ActivityWM_RightAItem1_Name"):SetText(exchstr)
		end  
		bar:GetSubItem("ActivityWM_Img"):SetProperty("Image", g_ActivityWM_GiftsImage[i])
		
		if i == 3 then
			bar:GetSubItem("ActivityWM_IconShow"):Show()
			bar:GetSubItem("ActivityWM_IconShow"):SetEvent("MouseLClick", "ActivityWM_PreviewClicked()")	 
		else
			bar:GetSubItem("ActivityWM_IconShow"):Hide()			
		end	
	end
end 
 
function ActivityWM_GetGiftsForCostYuanBao( Index )
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGifts" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998469 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, Index );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
end 


function ActivityWM_PreviewClicked()
	Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
			Set_XSCRIPT_Parameter(0, 10127079)
			Set_XSCRIPT_Parameter(1, 172)
			Set_XSCRIPT_Parameter(2, 137)
			Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end