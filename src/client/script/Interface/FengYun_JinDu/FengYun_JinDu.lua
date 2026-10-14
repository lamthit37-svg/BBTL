--FengYun_JinDu_Frame.lua
local g_FengYun_JinDu_Frame_UnifiedPosition
local g_FengYun_JinDu_Frame_UnifiedXPosition
local g_FengYun_JinDu_Frame_UnifiedYPosition

local g_FengYun_JinDu_Tip = {}
local g_FengYun_JinDu_DaiBiNeed = {}
local g_FengYun_JinDu_Received = {}
local g_FengYun_JinDu_Item = {}
local g_FengYun_JinDu_IMG = {}
local g_FengYun_JinDu_IMG_Line = {}
local g_FengYun_JinDu_DaiBiNeedList={200,400,600,900,1200,1500,1900,2300,2700,3200}

function FengYun_JinDu_PreLoad()
	--第二个参数表示界面隐藏时是否响应事件 默认为true
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)

end

function FengYun_JinDu_OnLoad()
	g_FengYun_JinDu_Frame_UnifiedXPosition	= FengYun_JinDu_MainFrame:GetProperty("UnifiedXPosition");
	g_FengYun_JinDu_Frame_UnifiedYPosition	= FengYun_JinDu_MainFrame:GetProperty("UnifiedYPosition");
	
	g_FengYun_JinDu_Tip[1] = FengYun_JinDu_RedDot1
	g_FengYun_JinDu_Tip[2] = FengYun_JinDu_RedDot2
	g_FengYun_JinDu_Tip[3] = FengYun_JinDu_RedDot3
	g_FengYun_JinDu_Tip[4] = FengYun_JinDu_RedDot4
	g_FengYun_JinDu_Tip[5] = FengYun_JinDu_RedDot5
	g_FengYun_JinDu_Tip[6] = FengYun_JinDu_RedDot6
	g_FengYun_JinDu_Tip[7] = FengYun_JinDu_RedDot7
	g_FengYun_JinDu_Tip[8] = FengYun_JinDu_RedDot8
	g_FengYun_JinDu_Tip[9] = FengYun_JinDu_RedDot9
	g_FengYun_JinDu_Tip[10] = FengYun_JinDu_RedDot10
	
	g_FengYun_JinDu_DaiBiNeed[1] = FengYun_JinDu_Text1
	g_FengYun_JinDu_DaiBiNeed[2] = FengYun_JinDu_Text2
	g_FengYun_JinDu_DaiBiNeed[3] = FengYun_JinDu_Text3
	g_FengYun_JinDu_DaiBiNeed[4] = FengYun_JinDu_Text4
	g_FengYun_JinDu_DaiBiNeed[5] = FengYun_JinDu_Text5
	g_FengYun_JinDu_DaiBiNeed[6] = FengYun_JinDu_Text6
	g_FengYun_JinDu_DaiBiNeed[7] = FengYun_JinDu_Text7
	g_FengYun_JinDu_DaiBiNeed[8] = FengYun_JinDu_Text8
	g_FengYun_JinDu_DaiBiNeed[9] = FengYun_JinDu_Text9
	g_FengYun_JinDu_DaiBiNeed[10] = FengYun_JinDu_Text10
	
	g_FengYun_JinDu_Received[1] = FengYun_JinDu_Received1
	g_FengYun_JinDu_Received[2] = FengYun_JinDu_Received2
	g_FengYun_JinDu_Received[3] = FengYun_JinDu_Received3
	g_FengYun_JinDu_Received[4] = FengYun_JinDu_Received4
	g_FengYun_JinDu_Received[5] = FengYun_JinDu_Received5
	g_FengYun_JinDu_Received[6] = FengYun_JinDu_Received6
	g_FengYun_JinDu_Received[7] = FengYun_JinDu_Received7
	g_FengYun_JinDu_Received[8] = FengYun_JinDu_Received8
	g_FengYun_JinDu_Received[9] = FengYun_JinDu_Received9
	g_FengYun_JinDu_Received[10] = FengYun_JinDu_Received10
	
	g_FengYun_JinDu_Item[1] = FengYun_JinDu_Item1
	g_FengYun_JinDu_Item[2] = FengYun_JinDu_Item2
	g_FengYun_JinDu_Item[3] = FengYun_JinDu_Item3
	g_FengYun_JinDu_Item[4] = FengYun_JinDu_Item4
	g_FengYun_JinDu_Item[5] = FengYun_JinDu_Item5
	g_FengYun_JinDu_Item[6] = FengYun_JinDu_Item6
	g_FengYun_JinDu_Item[7] = FengYun_JinDu_Item7
	g_FengYun_JinDu_Item[8] = FengYun_JinDu_Item8
	g_FengYun_JinDu_Item[9] = FengYun_JinDu_Item9
	g_FengYun_JinDu_Item[10] = FengYun_JinDu_Item10

	g_FengYun_JinDu_IMG[0] = FengYun_JinDu_Image
	g_FengYun_JinDu_IMG[1] = FengYun_JinDu_Image_1
	g_FengYun_JinDu_IMG[2] = FengYun_JinDu_Image_1
	g_FengYun_JinDu_IMG[3] = FengYun_JinDu_Image_2
	g_FengYun_JinDu_IMG[4] = FengYun_JinDu_Image_2
	g_FengYun_JinDu_IMG[5] = FengYun_JinDu_Image_3
	g_FengYun_JinDu_IMG[6] = FengYun_JinDu_Image_3
	g_FengYun_JinDu_IMG[7] = FengYun_JinDu_Image_4
	g_FengYun_JinDu_IMG[8] = FengYun_JinDu_Image_4
	g_FengYun_JinDu_IMG[9] = FengYun_JinDu_Image_5
	g_FengYun_JinDu_IMG[10] = FengYun_JinDu_Image_5
	
	--g_FengYun_JinDu_IMG_Line[0] = FengYun_JinDu_Image
	g_FengYun_JinDu_IMG_Line[1] = FengYun_JinDu_Image_1_Line
	g_FengYun_JinDu_IMG_Line[2] = FengYun_JinDu_Image_1_Line
	g_FengYun_JinDu_IMG_Line[3] = FengYun_JinDu_Image_2_Line
	g_FengYun_JinDu_IMG_Line[4] = FengYun_JinDu_Image_2_Line
	g_FengYun_JinDu_IMG_Line[5] = FengYun_JinDu_Image_3_Line
	g_FengYun_JinDu_IMG_Line[6] = FengYun_JinDu_Image_3_Line
	g_FengYun_JinDu_IMG_Line[7] = FengYun_JinDu_Image_4_Line
	g_FengYun_JinDu_IMG_Line[8] = FengYun_JinDu_Image_4_Line
	g_FengYun_JinDu_IMG_Line[9] = FengYun_JinDu_Image_5_Line
	g_FengYun_JinDu_IMG_Line[10] = FengYun_JinDu_Image_5_Line

end

function FengYun_JinDu_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 99984101) then
		local bShow = Get_XParam_INT(0)
		local nPoint = Get_XParam_INT(1)
		local nflag = Get_XParam_INT(2)
		local nWeekpoint = Get_XParam_INT(3)
		if bShow == 1 then
			FengYun_JinDu_Open(nPoint,nflag,nWeekpoint)
			this:Show()
		elseif bShow == 2 then
			this:Hide()
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		FengYun_JinDu_Close_OnClick()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengYun_JinDu_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		FengYun_JinDu_On_ResetPos()
	end
end

function FengYun_JinDu_Close_OnClick()
	this:Hide()
end

function FengYun_JinDu_OnHiden()
	this:Hide()
end

function FengYun_JinDu_On_ResetPos()
	FengYun_JinDu_MainFrame:SetProperty("UnifiedXPosition", g_FengYun_JinDu_Frame_UnifiedXPosition);
	FengYun_JinDu_MainFrame:SetProperty("UnifiedYPosition", g_FengYun_JinDu_Frame_UnifiedYPosition);
end

--获取领奖标记
function FengYun_JinDu_GetBounsFlag(nParam, nIndex)

	local ndivisor = math.pow(10,nIndex - 1)
	return math.mod(math.floor(nParam/ndivisor), 10)
end

function FengYun_JinDu_Open(npoint,nflag,nWeekpoint)
	--活动介绍
	FengYun_JinDu_Introduction:SetText("#{FYJD_250113_10}")
	--本周获得代币
	local strWeek = ScriptGlobal_Format("#{FYJD_250113_65}",nWeekpoint)
	FengYun_JinDu_Text:SetText(strWeek)
	--当前代币
	local str = ScriptGlobal_Format("#{FYJD_250113_11}",npoint)
	FengYun_JinDu_DBHaveText:SetText(str)
	--FengYun_JinDu_EXPLace:SetProgress(npoint,3200)
	local GetBounsNum =0
	--按钮
	for i=1,10 do
		local str = ScriptGlobal_Format("#{FYJD_250113_12}",g_FengYun_JinDu_DaiBiNeedList[i])
		g_FengYun_JinDu_DaiBiNeed[i]:SetText(str)
		
		g_FengYun_JinDu_Received[i]:Hide()
		g_FengYun_JinDu_Item[i]:Show()
		if(npoint>=g_FengYun_JinDu_DaiBiNeedList[i]) then
			if(FengYun_JinDu_GetBounsFlag(nflag,i) == 0)  then
				g_FengYun_JinDu_Tip[i]:Show()
			else
				--已经领奖
				GetBounsNum = GetBounsNum+1
				g_FengYun_JinDu_Received[i]:Show()
				g_FengYun_JinDu_Item[i]:Hide()
				g_FengYun_JinDu_Tip[i]:Hide()
			end
		else
			g_FengYun_JinDu_Tip[i]:Hide()
		end
		g_FengYun_JinDu_IMG_Line[i]:Hide()
	end
	
	--图片显示
	for i=0,10 do
		g_FengYun_JinDu_IMG[i]:Hide()
	end
	if GetBounsNum >= 0 and GetBounsNum <= 10 then
		g_FengYun_JinDu_IMG[GetBounsNum]:Show()
		if GetBounsNum >=1 and GetBounsNum <= 10 then
			g_FengYun_JinDu_IMG_Line[GetBounsNum]:Show()
		end
	end
	
	

end

function FengYun_JinDu_Reward_OnRewardClick(nIndex)
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("GetPrize")
	Set_XSCRIPT_ScriptID(999841)
	Set_XSCRIPT_Parameter(0,nIndex); 
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--新增购买火麒麟
function FengYun_JinDu_BuyBtn_OnClick()
	local nLevel = Player:GetLevel();
    -- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
    end
	if nLevel < 30  then        
		PushDebugMessage("#{FYJD_250113_40}")
		return
    end
	
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OpenBuyDaiBi")
	Set_XSCRIPT_ScriptID(999841)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function FengYun_JinDu_HelpBtn_OnClick()
	PushEvent("QUEST_HELPINFO", "#{FYJD_250113_27}")
end
