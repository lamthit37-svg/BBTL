-- 2018Q4春节引导任务-彩蛋界面

local g_Frame_UnifiedPosition

--mf
local g_MFBegin = 2556--mf起始值

--图标控件
local g_IconList = {}

local g_Item_ID = 38002630
--=========
-- PreLoad
--=========
function SpringFestival_CaiDan_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad
--=========
function SpringFestival_CaiDan_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_CaiDan:GetProperty("UnifiedPosition") 
	
	g_IconList = 
	{
		[1] = {dis = SpringFestival_CaiDan_NPC1_Dis, light = SpringFestival_CaiDan_NPC1_Light, }, 
		[2] = {dis = SpringFestival_CaiDan_NPC2_Dis, light = SpringFestival_CaiDan_NPC2_Light, }, 
		[3] = {dis = SpringFestival_CaiDan_NPC3_Dis, light = SpringFestival_CaiDan_NPC3_Light, }, 
		[4] = {dis = SpringFestival_CaiDan_NPC4_Dis, light = SpringFestival_CaiDan_NPC4_Light, }, 
		[5] = {dis = SpringFestival_CaiDan_NPC5_Dis, light = SpringFestival_CaiDan_NPC5_Light, }, 
		[6] = {dis = SpringFestival_CaiDan_NPC6_Dis, light = SpringFestival_CaiDan_NPC6_Light, }, 
		[7] = {dis = SpringFestival_CaiDan_NPC7_Dis, light = SpringFestival_CaiDan_NPC7_Light, }, 
		[8] = {dis = SpringFestival_CaiDan_NPC8_Dis, light = SpringFestival_CaiDan_NPC8_Light, }, 
		[9] = {dis = SpringFestival_CaiDan_NPC9_Dis, light = SpringFestival_CaiDan_NPC9_Light, }, 
	}
	
end

--=========
-- OnEvent
--=========
function SpringFestival_CaiDan_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89300001 then
	
		local bShow = Get_XParam_INT(0)
		if bShow > 0 then
			SpringFestival_CaiDan_Update()
		else
			SpringFestival_CaiDan_Close()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_CaiDan_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival_CaiDan_On_ResetPos()

	end

end

--=========
-- 打开
--=========
function SpringFestival_CaiDan_Update()

	this:Show()
	
	-- 刷新图标状态
	local nCount = 0--收集进度
	for i=1, table.getn(g_IconList) do
		local bFlag = Pneuma:GetMF(g_MFBegin+i-1)
		if bFlag ~= nil and bFlag == 1 then--已收集
			g_IconList[i].light:Show()
			g_IconList[i].dis:Hide()
			--收集进度+1
			nCount = nCount+1
		else
			g_IconList[i].dis:Show()
			g_IconList[i].light:Hide()
		end
	end
	
	--刷新收集进度
	local strText = ScriptGlobal_Format("#{RACL_181206_430}", nCount)
	SpringFestival_CaiDan_Collect:SetText(strText)
	
end

--=========
-- 关闭
--=========
function SpringFestival_CaiDan_Close()

	SpringFestival_CaiDan_OnHiden()
	this:Hide()
	
end

--=========
-- 隐藏
--=========
function SpringFestival_CaiDan_OnHiden()

end

--=========
-- 重置
--=========
function SpringFestival_CaiDan_On_ResetPos()

	SpringFestival_CaiDan:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 答疑
--=========
function SpringFestival_CaiDan_HelpClicked()

	PushEvent("SPRINGGUIDEMISSION_CAIDANHELP")
	
end

--=========
-- 领取道具：山海宝鉴。 2019.Q4 重开
--=========
function SpringFestival_CaiDan_GetBaoJianItemClick()

	--local count = CalcItemSpace(g_Item_ID)
	local count = PlayerPackage:Lua_GetUnLockItemCount(g_Item_ID) + PlayerPackage:Lua_GetUnLockItemCount(g_Item_ID)
	if count >= 1 then
		PushDebugMessage("#{RACL_181206_663}")
		return
	end
	
	local bagspace = CalcItemSpace(g_Item_ID)
	if bagspace < 1 then
		PushDebugMessage("#{RACL_181206_650}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetShanBaoHaiJianItem" )
		Set_XSCRIPT_ScriptID( 892999 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end

