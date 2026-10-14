--!!!reloadscript =ZongMen_SectTitle
local g_ZongMen_SectTitle_Frame_UnifiedPosition = ""
--滚动条的位置
local g_Position_Scroll = 0;

local g_ZongMen_SectTitle_Info = 
{
	[0] = { tips = "#{TXYZ_230710_33}", image = "set:SectTitle image:SectTitle_L0" },
	[1] = { tips = "#{TXYZ_230710_03}", image = "set:SectTitle image:SectTitle_L1" },
	[2] = { tips = "#{TXYZ_230710_04}", image = "set:SectTitle image:SectTitle_L2" },
	[3] = { tips = "#{TXYZ_230710_05}", image = "set:SectTitle image:SectTitle_L3" },
	[4] = { tips = "#{TXYZ_230710_06}", image = "set:SectTitle image:SectTitle_L4" },
	[5] = { tips = "#{TXYZ_230710_07}", image = "set:SectTitle image:SectTitle_L5" },
	[6] = { tips = "#{TXYZ_230710_09}", image = "set:SectTitle image:SectTitle_L6" },
	[7] = { tips = "#{TXYZ_230710_10}", image = "set:SectTitle image:SectTitle_L7" },
	[8] = { tips = "#{TXYZ_230710_11}", image = "set:SectTitle image:SectTitle_L8" },
	[9] = { tips = "#{TXYZ_230710_12}", image = "set:SectTitle image:SectTitle_L9" },
	[10] = { tips = "#{TXYZ_230710_13}", image = "set:SectTitle image:SectTitle_L10" },
	[11] = { tips = "#{TXYZ_230710_23}", image = "set:SectTitle image:SectTitle_L11" },
	[12] = { tips = "#{TXYZ_230710_24}", image = "set:SectTitle image:SectTitle_L12" },
	[13] = { tips = "#{TXYZ_230710_25}", image = "set:SectTitle image:SectTitle_L13" },
	[14] = { tips = "#{TXYZ_230710_26}", image = "set:SectTitle image:SectTitle_L14" },
	[15] = { tips = "#{TXYZ_230710_27}", image = "set:SectTitle image:SectTitle_L15" },
	[16] = { tips = "#{TXYZ_230710_28}", image = "set:SectTitle image:SectTitle_L16" },
	[17] = { tips = "#{TXYZ_230710_29}", image = "set:SectTitle image:SectTitle_L17" },
	[18] = { tips = "#{TXYZ_230710_30}", image = "set:SectTitle image:SectTitle_L18" },
	[19] = { tips = "#{TXYZ_230710_31}", image = "set:SectTitle image:SectTitle_L19" },
	[20] = { tips = "#{TXYZ_230710_32}", image = "set:SectTitle image:SectTitle_L20" },
}

--===============================================
-- PreLoad()
--===============================================
function ZongMen_SectTitle_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	this:RegisterEvent("UPDATE_ZONGMENTITLELEVEL",false)	-- 游戏分辨率发生了变化
	this:RegisterEvent("OPEN_SHOWZONGMENTITLELEVEL", true)
end

--===============================================
-- OnEvent()
--===============================================
function ZongMen_SectTitle_OnEvent(event)
	if event == "HIDE_ON_SCENE_TRANSED" then
		ZongMen_SectTitle_OnClose()
	elseif event == "ADJEST_UI_POS" then
		ZongMen_SectTitle_OnResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZongMen_SectTitle_OnResetPos()	
		
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 202308241) then	--
	--	PushDebugMessage("202308241")
	--	ZongMen_SectTitle_OnInit()	
	elseif event == "UPDATE_ZONGMENTITLELEVEL" then
	--	PushDebugMessage("UPDATE_ZONGMENTITLELEVEL")
		ZongMen_SectTitle_OnUpdate()	
	end
	
	if(event == "OPEN_SHOWZONGMENTITLELEVEL" )then
		ZongMen_SectTitle_OnInit()
	end

end



function ZongMen_SectTitle_OnLoad()
	
	g_ZongMen_SectTitle_Frame_UnifiedPosition = ZongMen_SectTitle_Frame:GetProperty("UnifiedPosition")
	
end

function ZongMen_SectTitle_OnUpdate()	
	local sectLevel = Player:GetData("ZONEMENTITLELEVEL");
	local sectImg = g_ZongMen_SectTitle_Info[0].image
	local sectTip = g_ZongMen_SectTitle_Info[0].tips
	--PushDebugMessage("ZongMen_SectTitle_OnUpdate "..sectLevel)
	if g_ZongMen_SectTitle_Info[sectLevel].tips ~= nil then
		sectImg = g_ZongMen_SectTitle_Info[sectLevel].image
		sectTip = g_ZongMen_SectTitle_Info[sectLevel].tips
	end
	ZongMen_SectTitle_Left_Text1:SetText(ScriptGlobal_Format("#{TXYZ_230710_16}",sectTip))
	ZongMen_SectTitle_StageLeft_Image:SetProperty("Image" , sectImg )
	
	local fixRate, expAdd = LuaFnGetCurZongmenTitleInfo()
	
	ZongMen_SectTitle_RightClient_Text2:SetText(ScriptGlobal_Format("#{TXYZ_230710_17}",fixRate))
	ZongMen_SectTitle_Left_Text3:SetText(ScriptGlobal_Format("#{TXYZ_230710_21}",expAdd))
	
	local visableCheck = 1 - Player:LuaFnGetZongmenTitleLevel_IsShow()
	if visableCheck ~= nil then
		ZongMen_SectTitle_VisableCheck:SetCheck(visableCheck)	
	else
		ZongMen_SectTitle_VisableCheck:SetCheck(0)	
	end
	
end


function ZongMen_SectTitle_OnInit()	
	if Player:GetData("Is2606S") == 1 then
		return
	end
	ZongMen_SectTitle_OnUpdate()	
	this:Show()
end

function ZongMen_SectTitle_Help_Clicked()
	PushEvent("QUEST_HELP_MSG", "#{TXYZ_230710_15}")
end

--小红点
function ZongMen_SectTitle_UpdateRedPointUI()

end


function ZongMen_SectTitle_OnHide()

end

function ZongMen_SectTitle_BtnCheck_OnClicked(index)
	PushDebugMessage("Choose "..index)
end

function ZongMen_SectTitle_OnClose()
	this:Hide()
end


function ZongMen_SectTitle_Close_Click()
	ZongMen_SectTitle_OnClose()
	
end

function ZongMen_SectTitle_OnResetPos()
	ZongMen_SectTitle_Frame:SetProperty("UnifiedPosition", g_ZongMen_SectTitle_Frame_UnifiedPosition)
end

--确认按钮
function ZongMen_SectTitle_VisableCheck_Clicked()
	local checkState = ZongMen_SectTitle_VisableCheck:GetCheck()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnVisableCheck_Clicked" ); 	-- 函数名
		Set_XSCRIPT_ScriptID( 998879 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, checkState );			-- 参数一
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
end