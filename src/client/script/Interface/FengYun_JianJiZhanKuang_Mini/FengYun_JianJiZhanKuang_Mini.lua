-- fypvpzhankuang


-- 保存UI默认位置
local FengYun_JianJiZhanKuang_Mini_Frame_UnifiedPosition = nil

local g_AwardLevel = {
	
	[1] = {point = 40000, text = "#{FYPVP_260106_270}"},
	[2] = {point = 20000, text = "#{FYPVP_260106_269}"},
	[3] = {point = 10000, text = "#{FYPVP_260106_268}"},
	[4] = {point = 2000, text = "#{FYPVP_260106_267}"},
	[5] = {point = 0, text = "#{FYPVP_260106_293}"},

	
}



function FengYun_JianJiZhanKuang_Mini_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("FYJCPVP_SMALL")     -- 窗口分辨率发生变化

end -- end func FengYun_JianJiZhanKuang_Mini_Frame_PreLoad()

function FengYun_JianJiZhanKuang_Mini_OnLoad()
    FengYun_JianJiZhanKuang_Mini_Frame_UnifiedPosition = FengYun_JianJiZhanKuang_Mini_Frame:GetProperty("UnifiedPosition")
	
	
	
end -- end func FengYun_JianJiZhanKuang_Mini_Frame_OnLoad()

function FengYun_JianJiZhanKuang_Mini_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        FengYun_JianJiZhanKuang_Mini_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        FengYun_JianJiZhanKuang_Mini_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        FengYun_JianJiZhanKuang_Mini_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331200004) then	--服务端传数据
	
		local teampoint = Get_XParam_INT(0)	
		local nLeaveTime  = Get_XParam_INT(1) 
		local nALLeaveTime  = Get_XParam_INT(2) 
		local nRoomType  = Get_XParam_INT(3) 
		local nRoomTeamNum = Get_XParam_INT(4) 
		local nRoomMonasterNun = Get_XParam_INT(5) 
		local bIsOut = Get_XParam_INT(6)  
		local nSmallBossNum = Get_XParam_INT(7) 
		
		FengYun_JianJiZhanKuang_Mini_Frame_Updata(teampoint, nLeaveTime, nALLeaveTime, nRoomType, nRoomTeamNum, nRoomMonasterNun, bIsOut, nSmallBossNum)
	 elseif (event == "FYJCPVP_SMALL") then
		this:Show()
		
	end
end -- end func FengYun_JianJiZhanKuang_Mini_Frame_OnEvent()

function FengYun_JianJiZhanKuang_Mini_Frame_Updata(teampoint, nLeaveTime, nALLeaveTime, nRoomType, nRoomTeamNum, nRoomMonasterNun, bIsOut, nSmallBossNum)

	if nLeaveTime <= 0 or nSmallBossNum == 0 then
		FengYun_JianJiZhanKuang_Mini_NowText:SetText("#{FYPVP_260106_243}")
		FengYun_JianJiZhanKuang_Mini_NowText:SetToolTip("#{FYPVP_260106_244}")
		
	else

		FengYun_JianJiZhanKuang_Mini_NowText:SetText("#{FYPVP_260106_241}")
		FengYun_JianJiZhanKuang_Mini_NowText:SetToolTip("#{FYPVP_260106_242}")
		
	end
	
	FengYun_JianJiZhanKuang_Mini_Countdown_Time:SetProperty("Timer", nALLeaveTime)
	

	for i = 1, table.getn(g_AwardLevel) do
		if teampoint >= g_AwardLevel[i].point then
			FengYun_JianJiZhanKuang_Mini_NumText:SetText(ScriptGlobal_Format("#{FYPVP_260106_265}",teampoint, g_AwardLevel[i].text))
			break
		end
	end

	
end -- end func FengYun_JianJiZhanKuang_Mini_Frame_Updata()


-- 界面默认位置
function FengYun_JianJiZhanKuang_Mini_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (FengYun_JianJiZhanKuang_Mini_Frame_UnifiedPosition ~= nil) then
            FengYun_JianJiZhanKuang_Mini_Frame:SetProperty("UnifiedPosition", FengYun_JianJiZhanKuang_Mini_Frame_UnifiedPosition)
        end
    end
end -- end func FengYun_JianJiZhanKuang_Mini_Frame_UnifiedPos()

function FengYun_JianJiZhanKuang_Mini_Frame_Hide()
    this:Hide()
end -- end func FengYun_JianJiZhanKuang_Mini_Frame_Hide()


function FengYun_JianJiZhanKuang_Mini_Help_Clicked()
    PushEvent("CCSHOP_HELP", 32)
end -- end func FengYun_JianJiZhanKuang_Mini_Frame_Help()

function FengYun_JianJiZhanKuang_Mini_Frame_Leave()
  	
end -- end func FengYun_JianJiZhanKuang_Mini_Frame_OpenMap()

function FengYun_JianJiZhanKuang_Mini_ScenceBtn()
    if (IsWindowShow("FengYun_JianJiSceneFb")) then
		CloseWindow("FengYun_JianJiSceneFb", true)
	else
		 Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenMap")
			Set_XSCRIPT_ScriptID(331200)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end -- end func FengYun_JianJiZhanKuang_Mini_Frame_OpenAward()

function FengYun_JianJiZhanKuang_Mini_Frame_Close_Clicked()
	FengYun_JianJiZhanKuang_Mini_Frame_Hide()
	PushEvent("FYJCPVP_BIG")
end 


function FengYun_JianJiZhanKuang_Mini_RankList()
	if (IsWindowShow("FengYun_JianJiTeamInfo2")) then
		CloseWindow("FengYun_JianJiTeamInfo2", true)
	else
		 Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenRankList")
			Set_XSCRIPT_ScriptID(331200)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
	
end -- end func FengYun_JianJiZhanKuang_Frame_OpenAward()
