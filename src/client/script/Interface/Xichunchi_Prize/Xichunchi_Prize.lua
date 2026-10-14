--新服整合砸金蛋界面逻辑

local g_Xichunchi_Prize_Frame_UnifiedPosition
local g_Xichunchi_Prize_UIRed = {}
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
local g_Xichunchi_Prize_ButtonTick = 0

--=========
-- PreLoad()
--=========
function Xichunchi_Prize_PreLoad()

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
function Xichunchi_Prize_OnLoad()
	g_Xichunchi_Prize_Frame_UnifiedPosition = Xichunchi_Prize_Frame:GetProperty("UnifiedPosition")
	g_Xichunchi_Prize_UIRed[1] = Xichunchi_Prize_Reward_Button1_tips
	Xichunchi_Prize_Critical:Hide()
	g_Xichunchi_AnimateTick = 0
	Xichunchi_Prize_Qijin_VFX:Play(false)
	Xichunchi_Prize_Yingfu_VFX_1:Play(false)
	Xichunchi_Prize_Yingfu_VFX_2:Play(false)
	Xichunchi_Prize_Yingfu_VFX_3:Play(false)
end

--=========
-- Event
--=========
function Xichunchi_Prize_OnEvent(event)
	if event == "UI_COMMAND" then
		local commandIndex = tonumber(arg0)
 		if commandIndex == 8883421 then
			local operInd = Get_XParam_INT(0)
			if operInd == 1 then
				Xichunchi_Prize_Update_Data()
				this:Show()
			elseif operInd == 2 then
				if this:IsVisible() then
					local cInd = Get_XParam_INT(1)
					Xichunchi_Prize_Update_Critial(cInd)
				end
			elseif operInd == 3 then
				Xichunchi_Prize_Qijin_VFX:Play(true)
			end
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Xichunchi_Prize_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Xichunchi_Prize_On_ResetPos()
	elseif event == "UPDATE_XINFU_DAIBI" then
		Xichunchi_Prize_Update_Data()
	elseif event == "MONEYJZ_CHANGE" then
		Xichunchi_Prize_Update_Data()
	elseif event == "UPDATE_YUANBAO" then
		Xichunchi_Prize_Update_Data()
	elseif (event == "MONEY_CHANGE_EX") then
		Xichunchi_Prize_Update_Data()
	end

end


--=========
-- 重置
--=========
function Xichunchi_Prize_On_ResetPos()

	Xichunchi_Prize_Frame:SetProperty("UnifiedPosition", g_Xichunchi_Prize_Frame_UnifiedPosition)

end

function Xichunchi_Prize_Close()
	this:Hide()
end

--=========
-- 问号帮助
--=========
function Xichunchi_Prize_Description_Clicked()
	PushEvent("CCSHOP_HELP", 131)
end

--=========
-- 点击抽奖
--=========
function Xichunchi_Prize_Reward_Clicked( ind )
	if IsInTServer() == 1 then
		PushDebugMessage("#{GQKJ_190722_22}")
		return
	end
	if g_Xichunchi_Prize_ButtonTick == 1 then
		PushDebugMessage("#{ZJWF_201231_21}")
		return
	end
	g_Xichunchi_Prize_ButtonTick = 1
	SetTimer("Xichunchi_Prize", "Xichunchi_Prize_ButtonProc()", 1000)
	if ind == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ClientAskReward")
			Set_XSCRIPT_ScriptID(888342)
			Set_XSCRIPT_Parameter(0, ind)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		MessageBoxSelf3("Xichunchi_Prize_Reward2", {["Content"] = "#{ZJWF_201231_32}", ["Type"] = "YesNo"})
	end
end

function Xichunchi_Prize_Reward2(strRet)
	if nil == strRet then
		return
	end
	
	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("Reward2Logic")
			Set_XSCRIPT_ScriptID(888342)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

--=============
-- 刷新界面数据
--=============
function Xichunchi_Prize_Update_Data()
	local nDaiBiNum = DataPool:LuaFnGetXinFuDaiBi()
	local nJiaoZiNum = Player:GetData("MONEY_JZ")
	local nYuanBaoNum = Player:GetData("YUANBAO")
	local nMoney = Player:GetData("MONEY")
	local sDaiBiNum = ScriptGlobal_Format("#{ZJWF_201231_46}",nDaiBiNum)	
	local sJiaoZiNum = ScriptGlobal_Format("#{ZJWF_201231_47}",math.floor(nJiaoZiNum/10000))	
	local sMoney = ScriptGlobal_Format("#{ZJWF_201231_48}",math.floor(nMoney/10000))	
	local sYuanBaoNum = ScriptGlobal_Format("#{ZJWF_201231_49}",nYuanBaoNum)	
	
	Xichunchi_Prize_Daibi:SetText(sDaiBiNum)
	Xichunchi_Prize_Jiaozi:SetText(sJiaoZiNum)
	Xichunchi_Prize_Jinbi:SetText(sMoney)
	Xichunchi_Prize_Yuanbao:SetText(sYuanBaoNum)
end

function Xichunchi_Prize_Update_Critial( nInd )
	if nInd <= 0 or nInd > table.getn(g_Xichunchi_Critical_Image) then
		return
	end
	Xichunchi_Prize_Yingfu_VFX_1:Play(true)
	Xichunchi_Prize_Yingfu_VFX_2:Play(true)
	Xichunchi_Prize_Yingfu_VFX_3:Play(true)
	local imageName = g_Xichunchi_Critical_Image[nInd]
	Xichunchi_Prize_Critical:SetProperty("Image",imageName)
	Xichunchi_Prize_Critical:SetProperty("Alpha",1)
	Xichunchi_Prize_Critical:Show()
	
	KillTimer("Xichunchi_Prize_TimerProc()")
	g_Xichunchi_AnimateTick = 0
	SetTimer("Xichunchi_Prize", "Xichunchi_Prize_TimerProc()", 200)
	
end

function Xichunchi_Prize_TimerProc()
	g_Xichunchi_AnimateTick = g_Xichunchi_AnimateTick + 200
	if g_Xichunchi_AnimateTick == 800 then
		Xichunchi_Prize_Critical:SetProperty("Alpha",0.8)
	elseif g_Xichunchi_AnimateTick == 1000 then
		Xichunchi_Prize_Critical:SetProperty("Alpha",0.5)
	elseif g_Xichunchi_AnimateTick == 1200 then
		Xichunchi_Prize_Critical:SetProperty("Alpha",0.3)
	elseif g_Xichunchi_AnimateTick >= 1500 then
		KillTimer("Xichunchi_Prize_TimerProc()")
		Xichunchi_Prize_Critical:Hide()
		g_Xichunchi_AnimateTick = 0
	end
	
end

function Xichunchi_Prize_ButtonProc()
	g_Xichunchi_Prize_ButtonTick = 0
	KillTimer("Xichunchi_Prize_ButtonProc()")
end
