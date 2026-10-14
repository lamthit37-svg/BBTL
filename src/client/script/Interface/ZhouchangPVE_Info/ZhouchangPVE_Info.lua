-- weekpveinfo
local g_PreText = {	
	[1] = "#{FHCL_240708_224}", --金币
	[2] = "#{FHCL_240708_258}", --五行
	[3] = "#{FHCL_240708_253}", --boos1
	[4] = "#{FHCL_240708_254}", --金币
	[5] = "#{FHCL_240708_255}", --金币
	[6] = "#{FHCL_240708_270}", --金币
	[7] = "#{FHCL_240708_271}", --金币
	[8] = "#{FHCL_240708_272}", --金币
	[9] = "#{FHCL_240708_256}", --最终boss
	[10] = "#{FHCL_240708_257}", --霜影
}

local g_SkillText = {	
	[1] = "#{FHCL_240708_325}", --减1
	[2] = "#{FHCL_240708_326}", --停止
	[3] = "#{FHCL_240708_327}", --随机传送
}

local g_SkillType = {	
	[1] = 0, --金币
	[2] = 0, --五行
	[3] = 800, --boos1
	[4] = 800, --boos2
	[5] = 800, --boos3
	[6] = 0, --金币
	[7] = 0, --金币
	[8] = 0, --金币
	[9] = 1000, --最终boss
	[10] = 1600, --霜影
}

local g_GamingText = {	
	[1] = "#{FHCL_240708_231}", --金币
	[2] = "#{FHCL_240708_235}", --五行
	[3] = "#{FHCL_240708_225}", --boos1
	[4] = "#{FHCL_240708_226}", --boos2
	[5] = "#{FHCL_240708_227}", --boos3
	[6] = "#{FHCL_240708_273}", --金币
	[7] = "#{FHCL_240708_274}", --金币
	[8] = "#{FHCL_240708_275}", --金币
	[9] = "#{FHCL_240708_228}", --最终boss
	[10] = "#{FHCL_240708_260}", --霜影
}

local g_EndText = {	
	[1] = "#{FHCL_240708_238}", --金币
	[2] = "#{FHCL_240708_238}", --五行
	[3] = "#{FHCL_240708_238}", --boos1
	[4] = "#{FHCL_240708_238}", --金币
	[5] = "#{FHCL_240708_238}", --金币
	[6] = "#{FHCL_240708_238}", --金币
	[7] = "#{FHCL_240708_238}", --金币
	[8] = "#{FHCL_240708_238}", --金币
	[9] = "#{FHCL_240708_239}", --最终boss
	[10] = "#{FHCL_240708_238}", --霜影
}

local g_Coe = {
	[1] = 1,
	[2] = 1,
	[3] = 1,
	[4] = 1.1,	
	[5] = 1.1,
	[6] = 1.1,
	[7] = 1.2,
	[8] = 1.2,
	[9] = 1.2,
	[10] = 1.3,
	[11] = 1.3,
	[12] = 1.3,
	[13] = 1.3,
	[14] = 1.3,
	[15] = 1.3,
	[16] = 1.3,	
	[17] = 1.3,
	[18] = 1.3,
	[19] = 1.3,
	[20] = 1.3,
	[21] = 1.3,
	[22] = 1.3,
	[23] = 1.3,
	[24] = 1.3,
	[25] = 1.3,
	[26] = 1.3,
	[27] = 1.3,
	[28] = 1.3,	
	[29] = 1.3,
	[30] = 1.3,

}

local g_nLevelInfo = {
	[0] = {pointmin = 400, pointmax = 1199, PropertyBagSpace = 2, MaterialBagSpace = 2},
	[1] = {pointmin = 1200, pointmax = 3499, PropertyBagSpace = 2, MaterialBagSpace = 2},
	[2] = {pointmin = 3500, pointmax = 4999, PropertyBagSpace = 2, MaterialBagSpace = 2},
	[3] = {pointmin = 5000, pointmax = 9999999, PropertyBagSpace = 2, MaterialBagSpace = 2},
}

local g_BossMoveStep = 2

local g_GameItemNeedPoint = 400
local g_GameItemNeedTime = 120


-- 保存UI默认位置
local ZhouchangPVE_Info_Frame_UnifiedPosition = nil

function ZhouchangPVE_Info_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")

end -- end func ZhouchangPVE_Info_Frame_PreLoad()

function ZhouchangPVE_Info_OnLoad()
    ZhouchangPVE_Info_Frame_UnifiedPosition = ZhouchangPVE_Info_Frame:GetProperty("UnifiedPosition")
	
	
end -- end func ZhouchangPVE_Info_Frame_OnLoad()

function ZhouchangPVE_Info_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        ZhouchangPVE_Info_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        ZhouchangPVE_Info_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        ZhouchangPVE_Info_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331105003) then	--服务端传数据
	
		local nEventId = Get_XParam_INT(0)	
		local nGamePoint  = Get_XParam_INT(1) 
		local nCurRoundGamePoint  = Get_XParam_INT(2) 
		local nCurRound  = Get_XParam_INT(3) 
		local bCurRoomState = Get_XParam_INT(4) 
		local nDis  = Get_XParam_INT(5) 
		local nBossGoSteps  = Get_XParam_INT(6) 
		local nGameItem  = Get_XParam_INT(7) 
		local nGameTimer =  Get_XParam_INT(8) 
		local nLeaveTime = Get_XParam_INT(9) 
		
		ZhouchangPVE_Info_Frame_Updata(nEventId, nGamePoint, nCurRoundGamePoint, nCurRound, bCurRoomState, nDis, nBossGoSteps, nGameItem, nGameTimer, nLeaveTime)
		this:Show()
	end
end -- end func ZhouchangPVE_Info_Frame_OnEvent()

function ZhouchangPVE_Info_Frame_Updata(nEventId, nGamePoint, nCurRoundGamePoint, nCurRound, bCurRoomState, nDis, nBossGoSteps, nGameItem, nGameTimer, nLeaveTime)

	local nAwardLevel = -1
	for i = 0, table.getn(g_nLevelInfo) do
		if nGamePoint >=  g_nLevelInfo[i].pointmin and nGamePoint <= g_nLevelInfo[i].pointmax then
			nAwardLevel = i
			break
		end
	end
	if nAwardLevel == -1 then
		 ZhouchangPVE_Info_Client2_Team:SetText(ScriptGlobal_Format("#{FHCL_240708_213}",nGamePoint, g_nLevelInfo[0].pointmin))
		 ZhouchangPVE_Info_Client2_Num2:SetText("#{FHCL_240708_491}")
	else
		if nAwardLevel ~= 3 then
			 ZhouchangPVE_Info_Client2_Team:SetText(ScriptGlobal_Format("#{FHCL_240708_213}",nGamePoint, g_nLevelInfo[nAwardLevel].pointmax+1))
			  ZhouchangPVE_Info_Client2_Num2:SetText(ScriptGlobal_Format("#{FHCL_240708_490}",nAwardLevel+1))
		else
			ZhouchangPVE_Info_Client2_Team:SetText(ScriptGlobal_Format("#{FHCL_240708_213}",nGamePoint, g_nLevelInfo[nAwardLevel].pointmin))
			ZhouchangPVE_Info_Client2_Num2:SetText(ScriptGlobal_Format("#{FHCL_240708_490}",nAwardLevel+1))
		end
	end
   
	--ZhouchangPVE_Info_Client2_Num1:SetText(ScriptGlobal_Format("#{FHCL_240708_214}",nCurRound))
	
	local str = ""
	if nCurRound == 0 then
		str = "#{FHCL_240708_223}"
		ZhouchangPVE_Info_Text3BK:Hide()
		ZhouchangPVE_Info_Text2BK:Hide()
	elseif bCurRoomState == 0 then
		str = g_PreText[nEventId]
		ZhouchangPVE_Info_Text3BK:Hide()
		ZhouchangPVE_Info_Text2BK:Hide()
		if g_SkillText[nGameItem] ~= nil and nEventId ~= 9 then
			if g_SkillType[nEventId] ~= 0 then
				str = str..ScriptGlobal_Format("#{FHCL_240708_229}",g_SkillText[nGameItem])
			else
				str = str..ScriptGlobal_Format("#{FHCL_240708_236}",g_GameItemNeedPoint, g_SkillText[nGameItem])
			end
		end
	elseif bCurRoomState == 1 then
		str = g_GamingText[nEventId]
		ZhouchangPVE_Info_Text3BK:Show()
		if g_SkillType[nEventId] ~= 0 then
			if g_SkillText[nGameItem] ~= nil or nEventId ~= 10 then
				if nLeaveTime >= 0  then
					ZhouchangPVE_Info_Time:SetProperty("Timer", nLeaveTime)
					ZhouchangPVE_Info_Text4:SetText("#{FHCL_240708_413}")
					ZhouchangPVE_Info_Text5:SetText(ScriptGlobal_Format("#{FHCL_240708_414}",g_SkillType[nEventId]))
					ZhouchangPVE_Info_Text4:Show()
					ZhouchangPVE_Info_Time:Show()
					ZhouchangPVE_Info_Text5:Show()
					ZhouchangPVE_Info_Text3:Hide()
					ZhouchangPVE_Info_CountdownIcon:Show()
					ZhouchangPVE_Info_Text7:Hide()
					ZhouchangPVE_Info_Text2BK:Show()
				else
					ZhouchangPVE_Info_Text3:SetText(ScriptGlobal_Format("#{FHCL_240708_414}",g_SkillType[nEventId]))
					ZhouchangPVE_Info_Text4:Hide()
					ZhouchangPVE_Info_Time:Hide()
					ZhouchangPVE_Info_Text5:Hide()
					ZhouchangPVE_Info_Text3:Show()
					ZhouchangPVE_Info_CountdownIcon:Hide()
					ZhouchangPVE_Info_Text7:SetText("#{FHCL_240708_415}")
					ZhouchangPVE_Info_Text7:Show()
					ZhouchangPVE_Info_Text2BK:Show()
				end
			
			else
				
				ZhouchangPVE_Info_Text3:SetText(ScriptGlobal_Format("#{FHCL_240708_414}",g_SkillType[nEventId]))
				ZhouchangPVE_Info_Text4:Hide()
				ZhouchangPVE_Info_Time:Hide()
				ZhouchangPVE_Info_Text5:Hide()
				ZhouchangPVE_Info_Text3:Show()	
				ZhouchangPVE_Info_CountdownIcon:Hide()	
				ZhouchangPVE_Info_Text7:Hide()
				ZhouchangPVE_Info_Text2BK:Hide()
				
			end
		elseif nEventId == 2 then --五行
			ZhouchangPVE_Info_Text7:SetText(ScriptGlobal_Format("#{FHCL_240708_514}",nLeaveTime, 5))
			ZhouchangPVE_Info_Text7:Show()
			ZhouchangPVE_Info_Text3:SetText(ScriptGlobal_Format("#{FHCL_240708_234}",nCurRoundGamePoint))
			ZhouchangPVE_Info_Text4:Hide()
			ZhouchangPVE_Info_Time:Hide()
			ZhouchangPVE_Info_Text5:Hide()
			ZhouchangPVE_Info_Text3:Show()
			ZhouchangPVE_Info_CountdownIcon:Hide()
			ZhouchangPVE_Info_Text2BK:Show()
		else
			ZhouchangPVE_Info_Time:SetProperty("Timer", nLeaveTime)
			ZhouchangPVE_Info_Text5:SetText(ScriptGlobal_Format("#{FHCL_240708_234}",nCurRoundGamePoint))
			ZhouchangPVE_Info_Text4:SetText("#{FHCL_240708_233}")
			ZhouchangPVE_Info_Text4:Show()
			ZhouchangPVE_Info_Time:Show()
			ZhouchangPVE_Info_Text5:Show()
			ZhouchangPVE_Info_Text3:Hide()
			ZhouchangPVE_Info_CountdownIcon:Show()
			ZhouchangPVE_Info_Text7:Hide()
			ZhouchangPVE_Info_Text2BK:Show()
			
		end
		if g_SkillText[nGameItem] ~= nil and nEventId ~= 9 then

			if g_SkillType[nEventId] ~= 0 then
				str = str..ScriptGlobal_Format("#{FHCL_240708_229}",g_SkillText[nGameItem])
			else
				str = str..ScriptGlobal_Format("#{FHCL_240708_236}",g_GameItemNeedPoint, g_SkillText[nGameItem])
			end
		end
	elseif bCurRoomState == 2 then
		str = g_EndText[nEventId]
		ZhouchangPVE_Info_Text3BK:Hide()	
		ZhouchangPVE_Info_Text2BK:Hide()
	end

	ZhouchangPVE_Info_Text2:SetText(str)
	
	
	ZhouchangPVE_Info_Client_BOSS_Text1:SetText(ScriptGlobal_Format("#{FHCL_240708_219}",nDis))
	ZhouchangPVE_Info_Client_BOSS_Text1:Show()
	if nCurRound < g_BossMoveStep then
		ZhouchangPVE_Info_Client_BOSS_Text2:SetText("#{FHCL_240708_487}")
	else
		ZhouchangPVE_Info_Client_BOSS_Text2:SetText(ScriptGlobal_Format("#{FHCL_240708_220}",nBossGoSteps))
	end
	ZhouchangPVE_Info_Client_BOSS_Text2:Show()
	ZhouchangPVE_Info_Client_BOSS_Text3:Hide()

	
	if bCurRoomState == 2 and nEventId == 9 then

		ZhouchangPVE_Info_Client_BOSS_Text3:SetText("#{FHCL_240708_369}")
		ZhouchangPVE_Info_Client_BOSS_Text2:Hide()
		ZhouchangPVE_Info_Client_BOSS_Text1:Hide()
		ZhouchangPVE_Info_Client_BOSS_Text3:Show()
	elseif nEventId == 9 and bCurRoomState ~= 2 then
		ZhouchangPVE_Info_Client_BOSS_Text3:SetText("#{FHCL_240708_375}")
		ZhouchangPVE_Info_Client_BOSS_Text2:Hide()
		ZhouchangPVE_Info_Client_BOSS_Text1:Hide()
		ZhouchangPVE_Info_Client_BOSS_Text3:Show()
	end
	
	
	
	if g_Coe[nCurRound] ~= nil then
		if g_Coe[nCurRound] ~= g_Coe[table.getn(g_Coe)] then
			ZhouchangPVE_Info_Text6:SetToolTip(ScriptGlobal_Format("#{FHCL_240708_316}",nCurRound))
			ZhouchangPVE_Info_Text6:SetText(ScriptGlobal_Format("#{FHCL_240708_412}",g_Coe[nCurRound]))
		else
			ZhouchangPVE_Info_Text6:SetToolTip(ScriptGlobal_Format("#{FHCL_240708_317}",nCurRound))
			ZhouchangPVE_Info_Text6:SetText(ScriptGlobal_Format("#{FHCL_240708_412}",g_Coe[nCurRound]))
		end
	elseif nCurRound == 0 then
		ZhouchangPVE_Info_Text6:SetToolTip(ScriptGlobal_Format("#{FHCL_240708_316}",0))
		ZhouchangPVE_Info_Text6:SetText(ScriptGlobal_Format("#{FHCL_240708_412}",g_Coe[1]))
	end
	
end -- end func ZhouchangPVE_Info_Frame_Updata()


-- 界面默认位置
function ZhouchangPVE_Info_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (ZhouchangPVE_Info_Frame_UnifiedPosition ~= nil) then
            ZhouchangPVE_Info_Frame:SetProperty("UnifiedPosition", ZhouchangPVE_Info_Frame_UnifiedPosition)
        end
    end
end -- end func ZhouchangPVE_Info_Frame_UnifiedPos()

function ZhouchangPVE_Info_Frame_Hide()
    this:Hide()
end -- end func ZhouchangPVE_Info_Frame_Hide()

-- 关闭按钮点击事件
function ZhouchangPVE_Info_Frame_Close_Clicked()
	ZhouchangPVE_Info_Frame_Hide()
end  -- end func ZhouchangPVE_Info_Frame_Close_Clicked()

function ZhouchangPVE_Info_Help_Clicked()
    PushEvent("CCSHOP_HELP", 215)
end -- end func ZhouchangPVE_Info_Frame_Help()

function ZhouchangPVE_Info_Frame_OpenMap()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenMap")
		Set_XSCRIPT_ScriptID(331105)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end -- end func ZhouchangPVE_Info_Frame_OpenMap()

function ZhouchangPVE_Info_Frame_OpenAward()
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowAward")
		Set_XSCRIPT_ScriptID(331105)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end -- end func ZhouchangPVE_Info_Frame_OpenAward()
