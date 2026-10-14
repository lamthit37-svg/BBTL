--拭剑天下休息室伤害界面
--!!!reloadscript =BW_Xiuxi_ShowDamage
local g_Frame_UnifiedPosition;

-----可变的
local g_IsStart = 0; --是否开始计算
local g_MaxDamage = 0; --最高伤害
local g_DamageCount = 0; --伤害次数
local g_TotalDamageNum = 0; --总伤害量
local g_DamageSecond = 0; --秒数

-----固定不变的
local g_MaxTotalSecond = 30; --30s
local g_RoomResId = 967; --休息室资源id
local g_RoomResId_HYG = 243; --寒玉谷资源id


function BW_Xiuxi_ShowDamage_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)				-- 界面 
	this:RegisterEvent("XBW_PLAYER_DAMAGE", false)
	
	this:RegisterEvent("ON_SCENE_TRANS", false)
	this:RegisterEvent("ON_SERVER_TRANS",false)

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


function BW_Xiuxi_ShowDamage_OnLoad()
	g_Frame_UnifiedPosition = BW_Xiuxi_ShowDamage_Frame:GetProperty("UnifiedPosition")
end

-- OnEvent
function BW_Xiuxi_ShowDamage_OnEvent(event)
	--
	if( event == "UI_COMMAND" and tonumber( arg0 ) == 89289601 ) then
		BW_Xiuxi_ShowDamage_Show()
	elseif ( event == "XBW_PLAYER_DAMAGE" ) then
		BW_Xiuxi_ShowDamage_OnDamageChange(0 - tonumber(arg0))

	elseif ( event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" ) then
		BW_Xiuxi_ShowDamage_CloseWindow()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		BW_Xiuxi_ShowDamage_OnResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BW_Xiuxi_ShowDamage_OnResetPos()
	end
end

function BW_Xiuxi_ShowDamage_Init()
	g_IsStart = 0
	g_MaxDamage = 0
	g_DamageCount = 0
	g_TotalDamageNum = 0
	g_DamageSecond = 0
end

function BW_Xiuxi_ShowDamage_Reset()
	g_IsStart = 0
	g_DamageCount = 0
	g_DamageSecond = 0
end

function BW_Xiuxi_ShowDamage_Show()
	BW_Xiuxi_ShowDamage_Init()
	BW_Xiuxi_ShowDamage_Data()	
	this:Show()
end


function BW_Xiuxi_ShowDamage_Data()
	local max_text = ScriptGlobal_Format("#{BWDH_240911_19}", g_MaxDamage)
	BW_Xiuxi_ShowDamage_MaxDamage:SetText(max_text)
	
	local average = math.floor(g_TotalDamageNum / g_MaxTotalSecond)
	if g_DamageSecond > 0 then
		average = math.floor(g_TotalDamageNum / g_DamageSecond)
	end
	local average_text = ScriptGlobal_Format("#{BWDH_240911_20}", average)
	BW_Xiuxi_ShowDamage_AverageDamage:SetText(average_text)

	if g_IsStart <= 0 then
		BW_Xiuxi_ShowDamage_Cancel:SetText("#{BWDH_240911_21}")
	else
		local second = g_MaxTotalSecond - g_DamageSecond
		local text = ScriptGlobal_Format("#{BWDH_240911_23}", second)
		BW_Xiuxi_ShowDamage_Cancel:SetText(text)
	end

	local curSceneID = GetSceneID()
	if curSceneID == g_RoomResId  then
		BW_Xiuxi_ShowDamage_Explain_Text:SetText("#{BWDH_240911_17}")
		BW_Xiuxi_ShowDamage_DragTitle:SetText("#{BWDH_240911_16}")
	else
		BW_Xiuxi_ShowDamage_Explain_Text:SetText("#{HYYH_250311_01}")
		BW_Xiuxi_ShowDamage_DragTitle:SetText("#{HYYH_250311_10}")
	end

end


function BW_Xiuxi_ShowDamage_OnDamageChange(damage)
	local curSceneID = GetSceneID()
	if curSceneID ~= g_RoomResId and curSceneID ~= g_RoomResId_HYG then
		return
	end
	
	if g_IsStart == 0 then
		return
	end
	
	if g_MaxDamage < damage then
		g_MaxDamage = damage
	end
	g_DamageCount = g_DamageCount + 1
	g_TotalDamageNum = g_TotalDamageNum + damage
end


function BW_Xiuxi_ShowDamage_OnStartClick()
	if g_IsStart >= 1 then
		return
	end
	
	BW_Xiuxi_ShowDamage_Init()
	g_IsStart = 1
	SetTimer("BW_Xiuxi_ShowDamage", "BW_Xiuxi_ShowDamage_Timer()", 1*1000)
end

function BW_Xiuxi_ShowDamage_Timer()
	g_DamageSecond = g_DamageSecond + 1
	if g_DamageSecond >= g_MaxTotalSecond then
		KillTimer("BW_Xiuxi_ShowDamage_Timer()")
		BW_Xiuxi_ShowDamage_Reset()
	end
	
	BW_Xiuxi_ShowDamage_Data()
end


function BW_Xiuxi_ShowDamage_CloseWindow()
	if g_IsStart > 0 then
		KillTimer("BW_Xiuxi_ShowDamage_Timer()")
		BW_Xiuxi_ShowDamage_Reset()
	end
	
	this:Hide()
end


function BW_Xiuxi_ShowDamage_OnHiden()
	BW_Xiuxi_ShowDamage_CloseWindow()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BW_Xiuxi_ShowDamage_OnResetPos()
  BW_Xiuxi_ShowDamage_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition);
end

