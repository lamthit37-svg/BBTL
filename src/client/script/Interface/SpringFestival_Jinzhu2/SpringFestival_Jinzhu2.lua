-- SpringFestival_Jinzhu2 卯兔闹春 前端
-- !!!reloadscript =SpringFestival_Jinzhu2



--所需代币（闹春情）
local tabNeedCoin = 
{
	[1] = 30, 
	[2] = 70, 
	[3] = 115, 
	[4] = 160, 
	[5] = 240, 
	[6] = 340, 
	[7] = 440, 
	[8] = 540, 
	--[9] = 1500, 
	--[10] = 1800, 
}

local g_SpringFestival_Jinzhu2_Frame_UnifiedPosition
local g_nUICommandID		= 99833201


local g_nCoinNum = 0  --拥有的代币（闹春情）数量
local g_isKaJiServer = 0 
local g_isOriginalJDServer = 0 
local g_nFlagRewardRecord ={}

local g_Button_Tips = {}
local g_Button = {}
--=========================================================
-- PreLoad
--=========================================================
function SpringFestival_Jinzhu2_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end


--=========================================================
-- OnLoad
--=========================================================
function SpringFestival_Jinzhu2_OnLoad()
	g_SpringFestival_Jinzhu2_Frame_UnifiedPosition =  SpringFestival_Jinzhu2_Frame:GetProperty("UnifiedPosition")
	
	g_Button_Tips[1]= SpringFestival_Jinzhu2_Button1_Tips
	g_Button_Tips[2]= SpringFestival_Jinzhu2_Button2_Tips
	g_Button_Tips[3]= SpringFestival_Jinzhu2_Button3_Tips
	g_Button_Tips[4]= SpringFestival_Jinzhu2_Button4_Tips
	g_Button_Tips[5]= SpringFestival_Jinzhu2_Button5_Tips
	g_Button_Tips[6]= SpringFestival_Jinzhu2_Button6_Tips
	g_Button_Tips[7]= SpringFestival_Jinzhu2_Button7_Tips
	g_Button_Tips[8]= SpringFestival_Jinzhu2_Button8_Tips

	g_Button[1] = SpringFestival_Jinzhu2_Button1
	g_Button[2] = SpringFestival_Jinzhu2_Button2
	g_Button[3] = SpringFestival_Jinzhu2_Button3
	g_Button[4] = SpringFestival_Jinzhu2_Button4
	g_Button[5] = SpringFestival_Jinzhu2_Button5
	g_Button[6] = SpringFestival_Jinzhu2_Button6
	g_Button[7] = SpringFestival_Jinzhu2_Button7
	g_Button[8] = SpringFestival_Jinzhu2_Button8
	
	g_nFlagRewardRecord[1] = 0
	g_nFlagRewardRecord[2] = 0
	g_nFlagRewardRecord[3] = 0
	g_nFlagRewardRecord[4] = 0
	g_nFlagRewardRecord[5] = 0
	g_nFlagRewardRecord[6] = 0
	g_nFlagRewardRecord[7] = 0
	g_nFlagRewardRecord[8] = 0

	g_isKaJiServer = 0
	g_isOriginalJDServer = 0

end

--=========================================================
-- OnEvent
--=========================================================
function SpringFestival_Jinzhu2_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID ) then
		-- 0 关闭, 1 打开, 2 刷新
		local nOpType 	= Get_XParam_INT(0)

		--PushDebugMessage("UI_COMMAND nOpType"..nOpType)

		-- 关闭界面
		if 0 == nOpType then	
			if this:IsVisible() then
				 SpringFestival_Jinzhu2_OnClosed()
			end
		end

		-- 打开界面
		if 1 == nOpType then
			--PushDebugMessage("打开界面")
			
			SpringFestival_Jinzhu2_Reset()

			this:Show()
			SpringFestival_Jinzhu2_CheckRedPoint()
			SpringFestival_Jinzhu2_ParamInit()
			SpringFestival_Jinzhu2_Update()
		end
		
		if 2 == nOpType then
			SpringFestival_Jinzhu2_ParamInit()
			SpringFestival_Jinzhu2_Update()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		SpringFestival_Jinzhu2_OnHide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_Jinzhu2_Frame_On_ResetPos()
	elseif (event == "ADJEST_UI_POS") then
		SpringFestival_Jinzhu2_Frame_On_ResetPos()
	end
end
--=========================================================
-- 打开界面检查红点是否需要消失
--=========================================================
function SpringFestival_Jinzhu2_CheckRedPoint()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "UpdateRedPoint" )
			Set_XSCRIPT_ScriptID(998332)			
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
end

--=========================================================
-- 领取奖励
--=========================================================
function SpringFestival_Jinzhu2_GetRewardsBtnClick(param)
	if param >=1 and param <= 8 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetReward" )
			Set_XSCRIPT_ScriptID(998332)	
			Set_XSCRIPT_Parameter(0, param)			
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	
	end
end

--=========================================================
-- 界面参数初始化
--=========================================================
function SpringFestival_Jinzhu2_ParamInit()
	g_nCoinNum 				= Get_XParam_INT(1)
	g_nFlagRewardRecord[1]	= Get_XParam_INT(2)
	g_nFlagRewardRecord[2]	= Get_XParam_INT(3)
	g_nFlagRewardRecord[3]	= Get_XParam_INT(4)
	g_nFlagRewardRecord[4]	= Get_XParam_INT(5)
	g_nFlagRewardRecord[5]	= Get_XParam_INT(6)
	g_nFlagRewardRecord[6]	= Get_XParam_INT(7)
	g_nFlagRewardRecord[7]	= Get_XParam_INT(8)
	g_nFlagRewardRecord[8]	= Get_XParam_INT(9)
	g_isKaJiServer			= Get_XParam_INT(10)
	g_isOriginalJDServer	= Get_XParam_INT(11)
	
end

--=========================================================
-- 界面更新
--=========================================================
function SpringFestival_Jinzhu2_Update()

	if g_isKaJiServer == 0 then
		if g_isOriginalJDServer == 1 then
			--典中典
			if g_nFlagRewardRecord[1] == 0 then
				SpringFestival_Jinzhu2_Button1:SetToolTip("#{MTNC_221101_02}")
			else
				SpringFestival_Jinzhu2_Button1:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[2] == 0 then
				SpringFestival_Jinzhu2_Button2:SetToolTip("#{MTNC_221101_03}")
			else
				SpringFestival_Jinzhu2_Button2:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[3] == 0 then
				SpringFestival_Jinzhu2_Button3:SetToolTip("#{MTNC_221101_04}")
			else
				SpringFestival_Jinzhu2_Button3:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[4] == 0 then
				SpringFestival_Jinzhu2_Button4:SetToolTip("#{MTNC_221101_05}")
			else
				SpringFestival_Jinzhu2_Button4:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[5] == 0 then
				SpringFestival_Jinzhu2_Button5:SetToolTip("#{MTNC_221101_06}")
			else
				SpringFestival_Jinzhu2_Button5:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[6] == 0 then
				SpringFestival_Jinzhu2_Button6:SetToolTip("#{MTNC_221101_07}")
			else
				SpringFestival_Jinzhu2_Button6:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[7] == 0 then
				SpringFestival_Jinzhu2_Button7:SetToolTip("#{MTNC_221101_08}")
			else
				SpringFestival_Jinzhu2_Button7:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[8] == 0 then
				SpringFestival_Jinzhu2_Button8:SetToolTip("#{MTNC_221101_09}")
			else
				SpringFestival_Jinzhu2_Button8:SetToolTip("#{MTNC_221101_33}")
			end
		else
			if g_nFlagRewardRecord[1] == 0 then
				SpringFestival_Jinzhu2_Button1:SetToolTip("#{MTNC_221101_23}")
			else
				SpringFestival_Jinzhu2_Button1:SetToolTip("#{MTNC_221101_33}")
			end		
			if g_nFlagRewardRecord[2] == 0 then
				SpringFestival_Jinzhu2_Button2:SetToolTip("#{MTNC_221101_24}")
			else
				SpringFestival_Jinzhu2_Button2:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[3] == 0 then
				SpringFestival_Jinzhu2_Button3:SetToolTip("#{MTNC_221101_25}")
			else
				SpringFestival_Jinzhu2_Button3:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[4] == 0 then
				SpringFestival_Jinzhu2_Button4:SetToolTip("#{MTNC_221101_26}")
			else
				SpringFestival_Jinzhu2_Button4:SetToolTip("#{MTNC_221101_33}")
			end		
			if g_nFlagRewardRecord[5] == 0 then
				SpringFestival_Jinzhu2_Button5:SetToolTip("#{MTNC_221101_27}")
			else
				SpringFestival_Jinzhu2_Button5:SetToolTip("#{MTNC_221101_33}")
			end		
			if g_nFlagRewardRecord[6] == 0 then
				SpringFestival_Jinzhu2_Button6:SetToolTip("#{MTNC_221101_28}")
			else
				SpringFestival_Jinzhu2_Button6:SetToolTip("#{MTNC_221101_33}")
			end		
			if g_nFlagRewardRecord[7] == 0 then
				SpringFestival_Jinzhu2_Button7:SetToolTip("#{MTNC_221101_29}")
			else
				SpringFestival_Jinzhu2_Button7:SetToolTip("#{MTNC_221101_33}")
			end
			if g_nFlagRewardRecord[8] == 0 then
				SpringFestival_Jinzhu2_Button8:SetToolTip("#{MTNC_221101_30}")
			else
				SpringFestival_Jinzhu2_Button8:SetToolTip("#{MTNC_221101_33}")
			end
		end
	else
		--卡级服
		if g_nFlagRewardRecord[1] == 0 then
			SpringFestival_Jinzhu2_Button1:SetToolTip("#{MTNC_221101_87}")
		else
			SpringFestival_Jinzhu2_Button1:SetToolTip("#{MTNC_221101_33}")
		end
		if g_nFlagRewardRecord[2] == 0 then
			SpringFestival_Jinzhu2_Button2:SetToolTip("#{MTNC_221101_88}")
		else
			SpringFestival_Jinzhu2_Button2:SetToolTip("#{MTNC_221101_33}")
		end
		if g_nFlagRewardRecord[3] == 0 then
			SpringFestival_Jinzhu2_Button3:SetToolTip("#{MTNC_221101_89}")
		else
			SpringFestival_Jinzhu2_Button3:SetToolTip("#{MTNC_221101_33}")
		end
		if g_nFlagRewardRecord[4] == 0 then
			SpringFestival_Jinzhu2_Button4:SetToolTip("#{MTNC_221101_90}")
		else
			SpringFestival_Jinzhu2_Button4:SetToolTip("#{MTNC_221101_33}")
		end		
		if g_nFlagRewardRecord[5] == 0 then
			SpringFestival_Jinzhu2_Button5:SetToolTip("#{MTNC_221101_91}")
		else
			SpringFestival_Jinzhu2_Button5:SetToolTip("#{MTNC_221101_33}")
		end		
		if g_nFlagRewardRecord[6] == 0 then
			SpringFestival_Jinzhu2_Button6:SetToolTip("#{MTNC_221101_92}")
		else
			SpringFestival_Jinzhu2_Button6:SetToolTip("#{MTNC_221101_33}")
		end		
		if g_nFlagRewardRecord[7] == 0 then
			SpringFestival_Jinzhu2_Button7:SetToolTip("#{MTNC_221101_93}")
		else
			SpringFestival_Jinzhu2_Button7:SetToolTip("#{MTNC_221101_33}")
		end	
		if g_nFlagRewardRecord[8] == 0 then
			SpringFestival_Jinzhu2_Button8:SetToolTip("#{MTNC_221101_94}")
		else
			SpringFestival_Jinzhu2_Button8:SetToolTip("#{MTNC_221101_33}")
		end
	end
	
	SpringFestival_Jinzhu2_LeijiText2:SetText(ScriptGlobal_Format("#{MTNC_221101_35}", g_nCoinNum))
	SpringFestival_Jinzhu2_LeijiText2:Show()
	
	
	SpringFestival_Jinzhu2_Object1:Show()
	SpringFestival_Jinzhu2_Object2:Show()
	SpringFestival_Jinzhu2_Object3:Show()
	SpringFestival_Jinzhu2_Object4:Show()
	
	SpringFestival_Jinzhu2_Object5:Show()
	SpringFestival_Jinzhu2_Object6:Show()
	SpringFestival_Jinzhu2_Object7:Show()
	SpringFestival_Jinzhu2_Object8:Show()

	SpringFestival_Set_GetReward_Tips(1)
	SpringFestival_Set_BoxOpen()
	--右翻页按钮的红点

	SpringFestival_Jinzhu2_RightBtn_Tips:Hide()
	SpringFestival_Jinzhu2_RightBtn:Hide()
	SpringFestival_Jinzhu2_LeftBtn:Hide()
	SpringFestival_Jinzhu2_LeftBtn_Tips:Hide()
	
end


--=========================================================
-- check left tips
--=========================================================
function SpringFestival_Check_LeftBtn_Tips()
	for i = 1, 4 do
		if g_nFlagRewardRecord[i] ==0 and tabNeedCoin[i] <= g_nCoinNum then
			return 1
		end
	end
	return 0
end

--=========================================================
-- check right tips
--=========================================================
function SpringFestival_Check_RightBtn_Tips()
	for i = 5, 8 do
		if g_nFlagRewardRecord[i] ==0 and tabNeedCoin[i] <= g_nCoinNum then
			return 1
		end
	end
	return 0
end

--=========================================================
-- Set GetReward tips
--=========================================================
function SpringFestival_Set_GetReward_Tips(param)
	for i = 1, 8 do
		if g_nFlagRewardRecord[i] ==0 and tabNeedCoin[i] <= g_nCoinNum then
			g_Button_Tips[i]:Show()
		else
			g_Button_Tips[i]:Hide()
		end
	end
end




--=========================================================
-- Set Box Open   !!!reloadscript =SpringFestival_Jinzhu2
--=========================================================
function SpringFestival_Set_BoxOpen()
	for i = 1, 8 do
		if g_nFlagRewardRecord[i] == 1 then
			--已经领取过了
			g_Button[i]: SetProperty("NormalImage", "set:SpringFestival_JinZhu2_03 image:baoxiang_Open")
			g_Button[i]: SetProperty("HoverImage", "set:SpringFestival_JinZhu2_03 image:baoxiang_Open")
			g_Button[i]: SetProperty("PushedImage", "set:SpringFestival_JinZhu2_03 image:baoxiang_Open")
		else 
			g_Button[i]: SetProperty("NormalImage", "set:SpringFestival_JinZhu2_03 image:baoxiang_Normal")
			g_Button[i]: SetProperty("HoverImage", "set:SpringFestival_JinZhu2_03 image:baoxiang_Hover")
			g_Button[i]: SetProperty("PushedImage", "set:SpringFestival_JinZhu2_03 image:baoxiang_Pushed")
		end
	end
end



--=========================================================
-- 重置界面
--=========================================================
function SpringFestival_Jinzhu2_Reset()
	g_nCoinNum 				= -1
	for i = 1, 8 do
		g_nFlagRewardRecord[i] = 0
	end
end



--=========================================================
-- 帮助
--=========================================================

function SpringFestival_Jinzhu2_Help()
	-- 借用一下别人的通道
	if g_isKaJiServer == 0 then
		if g_isOriginalJDServer == 1 then
			PushEvent("CCSHOP_HELP", 239)
		else
			PushEvent("CCSHOP_HELP", 176)
		end
	else
		PushEvent("CCSHOP_HELP", 179)
	end
    
end

--=========================================================
-- param :1=left ,2=right
--=========================================================
function SpringFestival_Jinzhu2_OnPageBtnClick(param)
	--PushDebugMessage("debug SpringFestival_Jinzhu2_OnPageBtnClick  param="..param)

	if param == 1 then
		SpringFestival_Jinzhu2_Update()
	end
	if param == 2 then
		SpringFestival_Jinzhu2_Object1:Hide()
		SpringFestival_Jinzhu2_Object2:Hide()
		SpringFestival_Jinzhu2_Object3:Hide()
		SpringFestival_Jinzhu2_Object4:Hide()
		
		SpringFestival_Jinzhu2_Object5:Show()
		SpringFestival_Jinzhu2_Object6:Show()
		SpringFestival_Jinzhu2_Object7:Show()
		SpringFestival_Jinzhu2_Object8:Show()
		
		--set getreward tips
		SpringFestival_Set_GetReward_Tips(2)
		

		--左翻页按钮的红点
		if 1 == SpringFestival_Check_LeftBtn_Tips() then
			SpringFestival_Jinzhu2_LeftBtn_Tips:Show()
		else 
			SpringFestival_Jinzhu2_LeftBtn_Tips:Hide()
		end
		SpringFestival_Jinzhu2_LeftBtn:Show()
		SpringFestival_Jinzhu2_RightBtn:Hide()	
		SpringFestival_Jinzhu2_RightBtn_Tips:Hide()	

	end
end

--=========================================================
-- 关闭界面
--=========================================================
function SpringFestival_Jinzhu2_OnClosed()	
	
	-- 重置
	this:Hide()
	SpringFestival_Jinzhu2_Reset()
	
end

--=========================================================
-- 界面隐藏
--=========================================================
function SpringFestival_Jinzhu2_OnHide()
	-- 重置
	this:Hide()
	SpringFestival_Jinzhu2_Reset()

end
--=========================================================
-- 界面隐藏
--=========================================================
function SpringFestival_Jinzhu2_OnHiden()
	-- 重置
	this:Hide()
	SpringFestival_Jinzhu2_Reset()

end


--=========================================================
-- 界面位置
--=========================================================
function SpringFestival_Jinzhu2_Frame_On_ResetPos()
	SpringFestival_Jinzhu2_Frame:SetProperty("UnifiedPosition", g_SpringFestival_Jinzhu2_Frame_UnifiedPosition)
end
