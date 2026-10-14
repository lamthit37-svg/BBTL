--2026砸金蛋 1

local g_Xichunchi_Prize2_Frame_UnifiedPosition
local g_Xichunchi_Prize2_UIRed = {}
local g_Xichunchi_Critical_Image = {
	[1] = "set:Xuanshang2 image:critical25",
	[2] = "set:Xuanshang2 image:critical30",
	[3] = "set:Xuanshang2 image:critical40",
	[4] = "set:Xuanshang2 image:critical50",
	[5] = "set:Xuanshang2 image:critical60",
	[6] = "set:Xuanshang2 image:critical80",
	[7] = "set:Xuanshang2 image:critical100",
	[8] = "set:Xuanshang2 image:critical120",
	[9] = "set:Xuanshang2 image:critical200",
	[10] = "set:Xuanshang2 image:critica500",
}

local g_Xichunchi_AnimateTick = 0
local g_Xichunchi_Prize2_ButtonTick = 0
local g_Xichunchi_Prize2_RetPoint = 0
local g_Xichunchi_MD_2026 = 3466

--=========
-- PreLoad()
--=========
function Xichunchi_Prize2_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	
	this:RegisterEvent("UPDATE_XINFU_DAIBI", false)
	this:RegisterEvent("MONEYJZ_CHANGE", false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	
end

--=========
-- OnLoad()
--=========
function Xichunchi_Prize2_OnLoad()
	g_Xichunchi_Prize2_Frame_UnifiedPosition = Xichunchi_Prize2_Frame:GetProperty("UnifiedPosition")
	g_Xichunchi_Prize2_UIRed[1] = Xichunchi_Prize2_Reward_Button1_tips
	Xichunchi_Prize2_Critical:Hide()
	g_Xichunchi_AnimateTick = 0
	Xichunchi_Prize2_Qijin_VFX:Play(false)
	Xichunchi_Prize2_Yingfu_VFX_1:Play(false)
	Xichunchi_Prize2_Yingfu_VFX_2:Play(false)
	Xichunchi_Prize2_Yingfu_VFX_3:Play(false)
	g_Xichunchi_Prize2_RetPoint = 0
end

--=========
-- Event
--=========
function Xichunchi_Prize2_OnEvent(event)
	if event == "UI_COMMAND" then
		local commandIndex = tonumber(arg0)
 		if commandIndex == 8855771 then
			local operInd = Get_XParam_INT(0)
			if operInd == 1 then
				g_Xichunchi_Prize2_RetPoint = Get_XParam_INT(1)
				Xichunchi_Prize2_Update_Data()
				this:Show()
			elseif operInd == 2 then
				if this:IsVisible() then
					local cInd = Get_XParam_INT(1)
					Xichunchi_Prize2_Update_Critial(cInd)
					g_Xichunchi_Prize2_RetPoint = Get_XParam_INT(9)
					Xichunchi_Prize2_Update_Data()
				end
			elseif operInd == 3 then
				Xichunchi_Prize2_Qijin_VFX:Play(true)
			end
		elseif commandIndex == 8855772 then
			if this:IsVisible() then
				g_Xichunchi_Prize2_RetPoint = Get_XParam_INT(9)
				Xichunchi_Prize2_Update_Data()
			end			
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Xichunchi_Prize2_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Xichunchi_Prize2_On_ResetPos()
	elseif event == "UPDATE_XINFU_DAIBI" then
		Xichunchi_Prize2_Update_Data()
	elseif event == "MONEYJZ_CHANGE" then
		Xichunchi_Prize2_Update_Data()
	elseif event == "UPDATE_YUANBAO" then
		Xichunchi_Prize2_Update_Data()
	elseif (event == "MONEY_CHANGE_EX") then
		Xichunchi_Prize2_Update_Data()
	end

end


--=========
-- 重置
--=========
function Xichunchi_Prize2_On_ResetPos()

	Xichunchi_Prize2_Frame:SetProperty("UnifiedPosition", g_Xichunchi_Prize2_Frame_UnifiedPosition)

end

function Xichunchi_Prize2_Close()
	this:Hide()
end

--=========
-- 问号帮助
--=========
function Xichunchi_Prize2_Help_Clicked()
	PushEvent("CCSHOP_HELP", 246)
end

--=========
-- 点击抽奖
--=========
function Xichunchi_Prize2_Reward_Clicked( ind )
	if IsInTServer() == 1 then
		PushDebugMessage("#{DKZJ_260521_27}")--("#{GQKJ_190722_22}")
		return
	end
	if g_Xichunchi_Prize2_ButtonTick == 1 then
		PushDebugMessage("#{DKZJ_260521_39}")--("#{ZJWF_201231_21}")
		return
	end
	g_Xichunchi_Prize2_ButtonTick = 1
	SetTimer("Xichunchi_Prize2", "Xichunchi_Prize2_ButtonProc()", 1000)
	if ind == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientAskReward")
			Set_XSCRIPT_ScriptID(885577)
			Set_XSCRIPT_Parameter(0, ind)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		MessageBoxSelf3("Xichunchi_Prize2_Reward2", {["Content"] = "#{DKZJ_260521_46}", ["Type"] = "YesNo"})
	end
end

function Xichunchi_Prize2_Reward2(strRet)
	if nil == strRet then
		return
	end
	
	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Reward2Logic")
			Set_XSCRIPT_ScriptID(885577)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

--=============
-- 刷新界面数据
--=============
function Xichunchi_Prize2_Update_Data()
	local BeginDay,EndDay = DataPool:Lua_2026ZaJinDanTime() 
	local temp = math.mod(BeginDay, 10000)
	local month_1 = math.floor(temp/100)
	local day_1 = math.mod(temp, 100)
	temp = math.mod(EndDay, 10000)
	local month_2 = math.floor(temp/100)
	local day_2 = math.mod(temp, 100)	
	Xichunchi_Prize2_Client_Info:SetText(ScriptGlobal_Format("#{DKZJ_260521_05}", month_1, day_1, month_2, day_2))
	if g_Xichunchi_Prize2_RetPoint==1 then
		Xichunchi_Prize2_Daibi_BuyTips:Show()
	else
		Xichunchi_Prize2_Daibi_BuyTips:Hide()
	end
	
	local nDaiBiNum = DataPool:GetPlayerMission_DataRound(g_Xichunchi_MD_2026) --DataPool:LuaFnGetXinFuDaiBi()
	local nJiaoZiNum = Player:GetData("MONEY_JZ")
	local nYuanBaoNum = Player:GetData("YUANBAO")
	local nMoney = Player:GetData("MONEY")
	local sDaiBiNum = ScriptGlobal_Format("#{DKZJ_260521_14}",nDaiBiNum)--ScriptGlobal_Format("#{ZJWF_201231_46}",nDaiBiNum)	
	local sJiaoZiNum = ScriptGlobal_Format("#{DKZJ_260521_15}",math.floor(nJiaoZiNum/10000))--ScriptGlobal_Format("#{ZJWF_201231_47}",math.floor(nJiaoZiNum/10000))	
	local sMoney = ScriptGlobal_Format("#{DKZJ_260521_16}",math.floor(nMoney/10000))--ScriptGlobal_Format("#{ZJWF_201231_48}",math.floor(nMoney/10000))	
	local sYuanBaoNum = ScriptGlobal_Format("#{DKZJ_260521_17}",nYuanBaoNum)--ScriptGlobal_Format("#{ZJWF_201231_49}",nYuanBaoNum)	
	
	Xichunchi_Prize2_Daibi:SetText(sDaiBiNum)
	Xichunchi_Prize2_Jiaozi:SetText(sJiaoZiNum)
	Xichunchi_Prize2_Jinbi:SetText(sMoney)
	Xichunchi_Prize2_Yuanbao:SetText(sYuanBaoNum)
end

function Xichunchi_Prize2_Update_Critial( nInd )
	if nInd <= 0 or nInd > table.getn(g_Xichunchi_Critical_Image) then
		return
	end
	Xichunchi_Prize2_Yingfu_VFX_1:Play(true)
	Xichunchi_Prize2_Yingfu_VFX_2:Play(true)
	Xichunchi_Prize2_Yingfu_VFX_3:Play(true)
	local imageName = g_Xichunchi_Critical_Image[nInd]
	Xichunchi_Prize2_Critical:SetProperty("Image",imageName)
	Xichunchi_Prize2_Critical:SetProperty("Alpha",1)
	Xichunchi_Prize2_Critical:Show()
	
	KillTimer("Xichunchi_Prize2_TimerProc()")
	g_Xichunchi_AnimateTick = 0
	SetTimer("Xichunchi_Prize2", "Xichunchi_Prize2_TimerProc()", 200)
	
end

function Xichunchi_Prize2_TimerProc()
	g_Xichunchi_AnimateTick = g_Xichunchi_AnimateTick + 200
	if g_Xichunchi_AnimateTick == 800 then
		Xichunchi_Prize2_Critical:SetProperty("Alpha",0.8)
	elseif g_Xichunchi_AnimateTick == 1000 then
		Xichunchi_Prize2_Critical:SetProperty("Alpha",0.5)
	elseif g_Xichunchi_AnimateTick == 1200 then
		Xichunchi_Prize2_Critical:SetProperty("Alpha",0.3)
	elseif g_Xichunchi_AnimateTick >= 1500 then
		KillTimer("Xichunchi_Prize2_TimerProc()")
		Xichunchi_Prize2_Critical:Hide()
		g_Xichunchi_AnimateTick = 0
	end
	
end

function Xichunchi_Prize2_ButtonProc()
	g_Xichunchi_Prize2_ButtonTick = 0
	KillTimer("Xichunchi_Prize2_ButtonProc()")
end

function Xichunchi_Prize2_Daibi_Buy_Clicked()
	local curDay = tonumber(DataPool:GetServerDayTime());
	local nLevel = Player:GetLevel();
	local nIsOpen = DataPool:Lua_2026ZaJinDanIsOpen() --DataPool:Lua_XinFuZhengHeIsOpen()
	local BeginDay,EndDay = DataPool:Lua_2026ZaJinDanTime() --DataPool:Lua_XinFuZhengHeTime()
	--总开关
	if nIsOpen ~= 1 then
		Xichunchi_Prize2_Close()
		return
	end
	--时间判断
	if BeginDay < 0 or EndDay < 0 or curDay < BeginDay or curDay > EndDay then
		PushDebugMessage("#{DKZJ_260521_04}")
		Xichunchi_Prize2_Close()		
		return
	end
	--等级判断
	if nLevel < 30 then
		PushDebugMessage("#{DKZJ_260521_03}")
		Xichunchi_Prize2_Close()
		return
	end
	
	if IsWindowShow("Xichunchi_Reward") then
		CloseWindow("Xichunchi_Reward", true)
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OpenUI2")
			Set_XSCRIPT_ScriptID(885577)
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	end	

end