--QiXiSongXin
local g_QiXiSongXin_UnifiedPosition;

local QiXiSongXin_Button = {}
local QiXiSongXin_Tips = {}
local QiXiSongXin_Mask = {}
local QiXiSongXin_Text = {}
local QiXiSongXin_ImageN = {}

local g_FanLi = 0;
local g_Data = 0;
local g_Reward = 0;

local g_RewardList = {
	[1] ={need = 1},    
    [2] ={need = 3},   
    [3] ={need = 5},    
    [4] ={need = 8},    
    [5] ={need = 12}, 

}
function QiXiSongXin_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function QiXiSongXin_OnLoad()

	QiXiSongXin_Button[1] = QiXiSongXin_Btn1
	QiXiSongXin_Button[2] = QiXiSongXin_Btn2
	QiXiSongXin_Button[3] = QiXiSongXin_Btn3
	QiXiSongXin_Button[4] = QiXiSongXin_Btn4
	QiXiSongXin_Button[5] = QiXiSongXin_Btn5

	QiXiSongXin_Tips[1] = QiXiSongXin_Btn1_Tips
	QiXiSongXin_Tips[2] = QiXiSongXin_Btn2_Tips
	QiXiSongXin_Tips[3] = QiXiSongXin_Btn3_Tips
	QiXiSongXin_Tips[4] = QiXiSongXin_Btn4_Tips
	QiXiSongXin_Tips[5] = QiXiSongXin_Btn5_Tips
	
	QiXiSongXin_Mask[1] = QiXiSongXin_Btn1_Mask
	QiXiSongXin_Mask[2] = QiXiSongXin_Btn2_Mask
	QiXiSongXin_Mask[3] = QiXiSongXin_Btn3_Mask
	QiXiSongXin_Mask[4] = QiXiSongXin_Btn4_Mask
	QiXiSongXin_Mask[5] = QiXiSongXin_Btn5_Mask
	
	QiXiSongXin_Text[1] = QiXiSongXin_TextBK_1
	QiXiSongXin_Text[2] = QiXiSongXin_TextBK_2
	QiXiSongXin_Text[3] = QiXiSongXin_TextBK_3
	QiXiSongXin_Text[4] = QiXiSongXin_TextBK_4
	QiXiSongXin_Text[5] = QiXiSongXin_TextBK_5
	
	QiXiSongXin_ImageN[1] = QiXiSongXin_Btn1_N
	QiXiSongXin_ImageN[2] = QiXiSongXin_Btn2_N
	QiXiSongXin_ImageN[3] = QiXiSongXin_Btn3_N
	QiXiSongXin_ImageN[4] = QiXiSongXin_Btn4_N
	QiXiSongXin_ImageN[5] = QiXiSongXin_Btn5_N

	
	g_QiXiSongXin_UnifiedPosition = QiXiSongXin_Frame:GetProperty("UnifiedPosition")
	
end

function QiXiSongXin_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99811501 ) then

		local operator = Get_XParam_INT(0)
			
		g_FanLi = Get_XParam_INT(1)
		g_Data = Get_XParam_INT(2)
		g_Reward = Get_XParam_INT(3)
			
		if operator == 1 then
			QiXiSongXin_Update()
		elseif operator == 2 and this:IsVisible() then
			QiXiSongXin_Update()		
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99811502 ) then
		local posX = Get_XParam_INT(0)
		local posZ = Get_XParam_INT(1)
		local sceneId = Get_XParam_INT(2)
		local NpcName = Get_XParam_STR(0)
		local bRet = AutoRuntoTargetExWithName(posX, posZ, sceneId, NpcName)
		if 0 == bRet then
			PushDebugMessage("无法自动寻路")
			return
		end
		
	elseif (event == "ADJEST_UI_POS" ) then
		QiXiSongXin_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QiXiSongXin_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()

	end

end

--=========================================================
--更新界面
--=========================================================
function QiXiSongXin_Update()
	local Huodong1 = math.mod(g_Data, 10)
	local Huodong2 = math.mod(math.floor(g_Data/10), 10)
	
	if Huodong1 == 1 then
		QiXiSongXin_info_Btn:Hide() --已完成
		QiXiSongXin_info_Btn_D:Show()
	else
		QiXiSongXin_info_Btn:Show() --前往
		QiXiSongXin_info_Btn:Enable()
		QiXiSongXin_info_Btn_D:Hide()
	end
	if Huodong2 == 1 then
		QiXiSongXin_info2_Btn:Hide() --已完成
		QiXiSongXin_info2_Btn_D:Show()
	else
		QiXiSongXin_info2_Btn:Show()  --前往
		QiXiSongXin_info2_Btn:Enable()
		QiXiSongXin_info2_Btn_D:Hide()
	end
	
	for i = 1, 5 do
		local isGet = math.mod(math.floor(g_Reward/math.pow(10, i-1)), 10)
		if isGet == 1 then
			QiXiSongXin_Button[i]:Disable()
			QiXiSongXin_Tips[i]:Hide()
			QiXiSongXin_Mask[i]:Show()
			QiXiSongXin_Text[i]:Show()
			QiXiSongXin_ImageN[i]:Show()
		else
			if tonumber(g_FanLi) >= g_RewardList[i].need then
				QiXiSongXin_Button[i]:Enable()
				QiXiSongXin_Tips[i]:Show()
				QiXiSongXin_Mask[i]:Hide()
			else
				QiXiSongXin_Button[i]:Enable()
				QiXiSongXin_Tips[i]:Hide()
				QiXiSongXin_Mask[i]:Hide()
			end
			QiXiSongXin_Text[i]:Show()
			QiXiSongXin_ImageN[i]:Hide()
		end
	end
	
	QiXiSongXin_Btn_Tips:Hide()
	QiXiSongXin_Btn:Hide()
	QiXiSongXin_Btn_2:Hide()
	QiXiSongXin_Btn_Down:Hide()
	
	local State = math.mod(math.floor(g_Data/100),10)
	if State == 0 then
		QiXiSongXin_Btn_2:Show() --前往取信
		QiXiSongXin_Btn:Enable()
		QiXiSongXin_Btn:SetToolTip("#{QXJSX_20220525_38}")
		if Huodong1 == 1 and Huodong2 == 1 and tonumber(g_FanLi)<12 then
			QiXiSongXin_Btn_Tips:Show() --红点
		end
	elseif State == 1 then
		QiXiSongXin_Btn:Show() --前往送信
		QiXiSongXin_Btn:Enable()
		QiXiSongXin_Btn:SetToolTip("#{QXJSX_20220525_43}")
		if Huodong1 == 1 and Huodong2 == 1 and tonumber(g_FanLi)<12 then
			QiXiSongXin_Btn_Tips:Show() --红点
		end
	elseif State == 2 then
		QiXiSongXin_Btn_Down:Show() --今日已完成
		QiXiSongXin_Btn:Disable()
	end
	

	
	QiXiSongXin_info_text:SetText(ScriptGlobal_Format("#{QXJSX_20220525_10}", tonumber(g_FanLi)))
	this:Show()
end

--========================================================
--关闭
--=========================================================
function QiXiSongXin_Close()
	this:Hide()
end

function QiXiSongXin_OnHiden()
	QiXiSongXin_Close()
end
--=========================================================
--刷新位置
--=========================================================
function QiXiSongXin_On_ResetPos()
	QiXiSongXin_Frame:SetProperty("UnifiedPosition", g_QiXiSongXin_UnifiedPosition);
end


function QiXiSongXin_Help()
	PushEvent("CCSHOP_HELP", 164)
end

--前往活动
function QiXiSongXin_GotoHuodong(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GotoHuodong" )
		Set_XSCRIPT_ScriptID( 998115 )
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--送信
function QiXiSongXin_GotoSongxin()
	local State = math.mod(math.floor(g_Data/100),10)
	if State == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GotoQuxin" )
			Set_XSCRIPT_ScriptID( 998115 )
    		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif State == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GotoSongxin" )
			Set_XSCRIPT_ScriptID( 998115 )
    		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

--领奖
function QiXiSongXin_GetReward(nIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetReward" )
		Set_XSCRIPT_ScriptID( 998115 )
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	

end