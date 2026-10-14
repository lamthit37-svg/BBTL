--20150701-七夕交互任务-by yuanpeilong

local g_Frame_UnifiedXPosition_Tanabata_Mini;
local g_Frame_UnifiedYPosition_Tanabata_Mini;

local Param0 = 0
local Param2 = 0
local MsgStr = ""

function Tanabata_Mini_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("2015QIXI_JH_SMALL")
	this:RegisterEvent("2015QIXI_JH_BIG")
end

function Tanabata_Mini_OnLoad()
	g_Frame_UnifiedXPosition_Tanabata_Mini	= Tanabata_Mini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition_Tanabata_Mini	= Tanabata_Mini_Frame:GetProperty("UnifiedYPosition");	
end


function Tanabata_Mini_OnEvent(event)

	if( event == "2015QIXI_JH_SMALL" ) then
	
		Tanabata_Mini_Clean()
		
		Param0 = tonumber( arg0 )
		Param2 = tonumber( arg1 )
		MsgStr = tostring( arg2 )
		
		if Param0 == 1234567 then
			
			Tanabata_Mini_Clean()
			
		else
		
			Tanabata_Mini_Small:Show()
			Tanabata_Mini:Show()
			Tanabata_Mini_DragTitle:Show()
			Tanabata_Mini_Frame:Show()
		
		end
		
	-- elseif(event == "UI_COMMAND") then
		
		-- local comefrom = tonumber(arg0)
		-- if comefrom == 891335 or comefrom == 891336 or comefrom == 891337 or comefrom == 891338 or comefrom == 891339 or comefrom == 891340 or comefrom == 891357 then
		
			-- local JieMina = Get_XParam_INT(0)
			
			-- if JieMina == 0 or JieMina == 1 or JieMina == 2 or JieMina == 3 or JieMina == 4 or JieMina == 5 then
			
				-- Tanabata_Mini_Clean()
				
				-- local Int0 = Get_XParam_INT(0)
				-- local Int1 = Get_XParam_INT(1)
				-- local Int2 = Get_XParam_INT(2)

				-- if Int1 == 0 then
					-- --关闭界面
					-- Tanabata_Mini_Clean()
					-- this:Hide()
				-- end
			-- end
		-- end
		
	end
	
end

function Tanabata_Mini_Clean()
	Tanabata_Mini:Hide()
	Tanabata_Mini_Frame:Hide()
	this:Hide()
end

function Tanabata_Mini_ResetPos()
	Tanabata_Mini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition_Tanabata_Mini);
	Tanabata_Mini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition_Tanabata_Mini);
end

function Tanabata_Mini_Small_Cliecked()
	PushEvent( "2015QIXI_JH_BIG", Param0, Param2, MsgStr );
	Tanabata_Mini_Clean()
	this:Hide()
end
