-- 2021春节金株主界面
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

-- 年画控件
local g_NianHua = {}
-- local g_ProcessTimes = {}
-- local g_ProcessTimesBK = {}
local g_NianHuaButton = {}
local g_NianHuaButtonTips = {}
local g_NianHuaButtonGet = {}
-- local g_NianHuaImage = {
	-- [0] = "set:Spring3 image:FuPic2",
	-- [1] = "set:Spring3 image:FuPic2",
	-- [2] = "set:Spring3 image:FuPic2",
	-- [3] = "set:Spring3 image:FuPic2",
	-- [4] = "set:Spring3 image:FuPic2",
-- }

-- local g_NianHuaImageNull = {
	-- [1] = "set:Spring3 image:Fu_Pic1",
	-- [2] = "set:Spring3 image:Fu_Pic1",
	-- [3] = "set:Spring3 image:Fu_Pic1",
	-- [4] = "set:Spring3 image:Fu_Pic1",
	-- [5] = "set:Spring3 image:Fu_Pic1",
-- }

local g_MaxProcess = 5
local g_Process = 
{
	[0] = {NeedCostTimes = 1, NeedItemNum = 40, GiveJinZhuNum = 100, PropertySpace = 1, MaterialSpace = 1, item = { {id=20502004   ,num=2}, {id=38004273,num=10}, {id=-1,num=0}, {id=-1,num=0}, {id=-1,num=0}, }, },
	[1] = {NeedCostTimes = 1, NeedItemNum = 80, GiveJinZhuNum = 200, PropertySpace = 1, MaterialSpace = 1, item = { {id=20501004,num=2}, {id=38004273,num=10}, {id=-1,num=0}, {id=-1,num=0}, {id=-1,num=0}, }, },
	[2] = {NeedCostTimes = 1, NeedItemNum = 120, GiveJinZhuNum = 300, PropertySpace = 2, MaterialSpace = 0, item = { {id=30900130,num=1}, {id=38004273,num=10}, {id=-1,num=0}, {id=-1,num=0}, {id=-1,num=0}, }, },
	[3] = {NeedCostTimes = 1, NeedItemNum = 120, GiveJinZhuNum = 300, PropertySpace = 2, MaterialSpace = 0, item = { {id=38004697,num=10}, {id=38004273,num=10}, {id=-1,num=0}, {id=-1,num=0}, {id=-1,num=0}, }, },
	[4] = {NeedCostTimes = 1, NeedItemNum = 120, GiveJinZhuNum = 300, PropertySpace = 2, MaterialSpace = 0, item = { {id=38004698,num=10}, {id=38005618,num=1}, {id=-1,num=0}, {id=-1,num=0}, {id=-1,num=0}, }, },
}


function SpringFestival_Jinzhu_PreLoad()

	this:RegisterEvent("UI_COMMAND", true);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function SpringFestival_Jinzhu_OnLoad()

	g_Frame_UnifiedXPosition	= SpringFestival_Jinzhu_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= SpringFestival_Jinzhu_Frame:GetProperty("UnifiedYPosition");
	
	g_NianHua[1] = SpringFestival_Jinzhu_Image1;
	g_NianHua[2] = SpringFestival_Jinzhu_Image2;
	g_NianHua[3] = SpringFestival_Jinzhu_Image3;
	g_NianHua[4] = SpringFestival_Jinzhu_Image4;
	g_NianHua[5] = SpringFestival_Jinzhu_Image5;
	
	-- g_ProcessTimes[1] = SpringFestival_Jinzhu_Image1_Text;
	-- g_ProcessTimes[2] = SpringFestival_Jinzhu_Image2_Text;
	-- g_ProcessTimes[3] = SpringFestival_Jinzhu_Image3_Text;
	-- g_ProcessTimes[4] = SpringFestival_Jinzhu_Image4_Text;
	-- g_ProcessTimes[5] = SpringFestival_Jinzhu_Image5_Text;
	
	-- g_ProcessTimesBK[1] = SpringFestival_Jinzhu_Image1_TextBK;
	-- g_ProcessTimesBK[2] = SpringFestival_Jinzhu_Image2_TextBK;
	-- g_ProcessTimesBK[3] = SpringFestival_Jinzhu_Image3_TextBK;
	-- g_ProcessTimesBK[4] = SpringFestival_Jinzhu_Image4_TextBK;
	-- g_ProcessTimesBK[5] = SpringFestival_Jinzhu_Image5_TextBK;
	
	g_NianHuaButton[1] = SpringFestival_JinzhuItem1;
	g_NianHuaButton[2] = SpringFestival_JinzhuItem2;
	g_NianHuaButton[3] = SpringFestival_JinzhuItem3;
	g_NianHuaButton[4] = SpringFestival_JinzhuItem4;
	g_NianHuaButton[5] = SpringFestival_JinzhuItem5;
	
	g_NianHuaButtonTips[1] = SpringFestival_JinzhuItem1_Tips;
	g_NianHuaButtonTips[2] = SpringFestival_JinzhuItem2_Tips;
	g_NianHuaButtonTips[3] = SpringFestival_JinzhuItem3_Tips;
	g_NianHuaButtonTips[4] = SpringFestival_JinzhuItem4_Tips;
	g_NianHuaButtonTips[5] = SpringFestival_JinzhuItem5_Tips;
	
	g_NianHuaButtonGet[1] = SpringFestival_JinzhuItem1_Get;
	g_NianHuaButtonGet[2] = SpringFestival_JinzhuItem2_Get;
	g_NianHuaButtonGet[3] = SpringFestival_JinzhuItem3_Get;
	g_NianHuaButtonGet[4] = SpringFestival_JinzhuItem4_Get;
	g_NianHuaButtonGet[5] = SpringFestival_JinzhuItem5_Get;
	
	
end

function SpringFestival_Jinzhu_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		SpringFestival_Jinzhu_ResetPos()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_Jinzhu_ResetPos()	
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88884204 then
		local nowProcess = Get_XParam_INT(0)
		local nowProcessTimes = Get_XParam_INT(1)
		local isGetPrize0 = Get_XParam_INT(2)
		local isGetPrize1 = Get_XParam_INT(3)
		local isGetPrize2 = Get_XParam_INT(4)
		local isGetPrize3 = Get_XParam_INT(5)
		local isGetPrize4 = Get_XParam_INT(6)
		local itemAnum = Get_XParam_INT(7)
		local nowJinZhu1 = Get_XParam_INT(8)
		
		SpringFestival_Jinzhu_Updata(nowProcess, nowProcessTimes, isGetPrize0, isGetPrize1, isGetPrize2, isGetPrize3, isGetPrize4, itemAnum, nowJinZhu1)
		this:Show()
	
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88884206 then
		-- 刷新红点
		local nEnterUIHotPoint = Get_XParam_INT(0)
		local nDrewHotPoint = Get_XParam_INT(1)
		local nGetJinZhuHotPoint = Get_XParam_INT(2)
		local nIsGetPrizeHotPoint = {0,0,0,0,0}
		for i = 1, g_MaxProcess do 
			nIsGetPrizeHotPoint[i] = Get_XParam_INT(2+i)
		end
		SpringFestival_Jinzhu_UpdataHotPoint(nDrewHotPoint, nGetJinZhuHotPoint, nIsGetPrizeHotPoint[1], nIsGetPrizeHotPoint[2], nIsGetPrizeHotPoint[3], nIsGetPrizeHotPoint[4], nIsGetPrizeHotPoint[5])
	
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88884201 then --绘画之后刷新界面
		
		local nowProcess = Get_XParam_INT(0)
		local nowProcessTimes = Get_XParam_INT(1)
		local isGetPrize0 = Get_XParam_INT(2)
		local isGetPrize1 = Get_XParam_INT(3)
		local isGetPrize2 = Get_XParam_INT(4)
		local isGetPrize3 = Get_XParam_INT(5)
		local isGetPrize4 = Get_XParam_INT(6)
		local itemAnum = Get_XParam_INT(7)
		local nowJinZhu1 = Get_XParam_INT(8)
		SpringFestival_Jinzhu_Updata(nowProcess, nowProcessTimes, isGetPrize0, isGetPrize1, isGetPrize2, isGetPrize3, isGetPrize4, itemAnum, nowJinZhu1)
		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88884202 then --领奖之后刷新界面
		
		local nowProcess = Get_XParam_INT(0)
		local nowProcessTimes = Get_XParam_INT(1)
		local isGetPrize0 = Get_XParam_INT(2)
		local isGetPrize1 = Get_XParam_INT(3)
		local isGetPrize2 = Get_XParam_INT(4)
		local isGetPrize3 = Get_XParam_INT(5)
		local isGetPrize4 = Get_XParam_INT(6)
		local itemAnum = Get_XParam_INT(7)
		local nowJinZhu1 = Get_XParam_INT(8)
		SpringFestival_Jinzhu_Updata(nowProcess, nowProcessTimes, isGetPrize0, isGetPrize1, isGetPrize2, isGetPrize3, isGetPrize4, itemAnum, nowJinZhu1)
		
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88884203 then --领金株之后刷新界面
		
		local nowProcess = Get_XParam_INT(0)
		local nowProcessTimes = Get_XParam_INT(1)
		local isGetPrize0 = Get_XParam_INT(2)
		local isGetPrize1 = Get_XParam_INT(3)
		local isGetPrize2 = Get_XParam_INT(4)
		local isGetPrize3 = Get_XParam_INT(5)
		local isGetPrize4 = Get_XParam_INT(6)
		local itemAnum = Get_XParam_INT(7)
		local nowJinZhu1 = Get_XParam_INT(8)
		SpringFestival_Jinzhu_Updata(nowProcess, nowProcessTimes, isGetPrize0, isGetPrize1, isGetPrize2, isGetPrize3, isGetPrize4, itemAnum, nowJinZhu1)
		
	end
end

function SpringFestival_Jinzhu_Updata(nowProcess, nowProcessTimes, isGetPrize0, isGetPrize1, isGetPrize2, isGetPrize3, isGetPrize4, itemAnum, nowJinZhu1)
	
	for i = 1, g_MaxProcess do
		--g_ProcessTimesBK[i]:Hide()
		g_NianHua[i]:Hide()
	end
	local isGetPrize = {isGetPrize0, isGetPrize1, isGetPrize2, isGetPrize3, isGetPrize4}
	-- 把已经激活的年画显示出来
	for i = 0, nowProcess-1 do
		g_NianHua[i+1]:Show()
		--g_ProcessTimesBK[i+1]:Hide()
	end
	
	if nowProcess < g_MaxProcess then
		if itemAnum >= g_Process[nowProcess].NeedItemNum then
			--g_ProcessTimes[nowProcess+1]:SetText(ScriptGlobal_Format("#{JZZH_211125_16}", itemAnum, g_Process[nowProcess].NeedItemNum))
			SpringFestival_Jinzhu_Image_Number:SetText(ScriptGlobal_Format("#{JZZH_211125_16}",g_Process[nowProcess].NeedItemNum))
			SpringFestival_Jinzhu_Image_Number:Show()
		else
			--g_ProcessTimes[nowProcess+1]:SetText(ScriptGlobal_Format("#{JZZH_211125_54}", itemAnum, g_Process[nowProcess].NeedItemNum))
			SpringFestival_Jinzhu_Image_Number:SetText(ScriptGlobal_Format("#{JZZH_211125_54}",g_Process[nowProcess].NeedItemNum))
		end
		--g_ProcessTimesBK[nowProcess+1]:Show()
		SpringFestival_Jinzhu_Image_Print:SetToolTip(ScriptGlobal_Format("#{JZZH_211125_49}",g_Process[nowProcess].NeedItemNum))
	else
		SpringFestival_Jinzhu_Image_Number:Hide()
	end
	
	
	if nowProcess == g_MaxProcess then
		SpringFestival_Jinzhu_Image_Print:Hide()
	else
		SpringFestival_Jinzhu_Image_Print:Show()
	end
	
	for i = 1, g_MaxProcess do
		if isGetPrize[i] == 1 then
			g_NianHuaButtonGet[i]:Show()
		else
			g_NianHuaButtonGet[i]:Hide()
		end
	end
	
	if KaJi:LuaFnIsKaJiServer() ~= 1 then		
		g_NianHuaButton[1]:SetToolTip("#{JZZH_211125_43}")		
		g_NianHuaButton[2]:SetToolTip("#{JZZH_211125_44}")		
		g_NianHuaButton[3]:SetToolTip("#{JZZH_211125_45}")		
		g_NianHuaButton[4]:SetToolTip("#{JZZH_211125_46}")		
		g_NianHuaButton[5]:SetToolTip("#{JZZH_211125_48}")		
	--卡级服
	else
		g_NianHuaButton[1]:SetToolTip("#{JZZH_211125_55}")		
		g_NianHuaButton[2]:SetToolTip("#{JZZH_211125_56}")		
		g_NianHuaButton[3]:SetToolTip("#{JZZH_211125_57}")		
		g_NianHuaButton[4]:SetToolTip("#{JZZH_211125_52}")		
		g_NianHuaButton[5]:SetToolTip("#{JZZH_211125_53}")		
	end

	
	SpringFestival_Jinzhu_Image_Text:SetText(ScriptGlobal_Format("#{JZZH_211125_07}", itemAnum))
	--SpringFestival_Jinzhu_AccountText:SetText(ScriptGlobal_Format("#{JZZH_211125_47}", nowJinZhu1))
	
end

function SpringFestival_Jinzhu_UpdataHotPoint(nDrewHotPoint, nGetJinZhuHotPoint, nIsGetPrizeHotPoint1, nIsGetPrizeHotPoint2, nIsGetPrizeHotPoint3, nIsGetPrizeHotPoint4, nIsGetPrizeHotPoint5)

	local nIsGetPrizeHotPoint = {nIsGetPrizeHotPoint1, nIsGetPrizeHotPoint2, nIsGetPrizeHotPoint3, nIsGetPrizeHotPoint4, nIsGetPrizeHotPoint5}
	if nDrewHotPoint == 1 then
		SpringFestival_Jinzhu_Image_Print_Tips:Show()
	else
		SpringFestival_Jinzhu_Image_Print_Tips:Hide()
	end
	
	-- if nGetJinZhuHotPoint == 1 then
		-- SpringFestival_Jinzhu_Account_GetButton_Tips:Hide()
	-- else
		-- SpringFestival_Jinzhu_Account_GetButton_Tips:Hide()
	-- end
	
	for i = 1, g_MaxProcess do
		if nIsGetPrizeHotPoint[i] == 1 then
			g_NianHuaButtonTips[i]:Show()
		else
			g_NianHuaButtonTips[i]:Hide()
		end
	end
	
end

function SpringFestival_Jinzhu_Drew()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("Drew");
		Set_XSCRIPT_ScriptID(888842);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

function SpringFestival_Jinzhu_OpenActivityUI()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OpenActivityUI");
		Set_XSCRIPT_ScriptID(888842);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end

function SpringFestival_Jinzhu_GetJinZhu()
	-- Clear_XSCRIPT();
		-- Set_XSCRIPT_Function_Name("GetJinZhuAward");
		-- Set_XSCRIPT_ScriptID(888842);
		-- Set_XSCRIPT_ParamCount(0);
	-- Send_XSCRIPT();
end

function SpringFestival_Jinzhu_GetPrize(index)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("GetAward");
		Set_XSCRIPT_ScriptID(888842);
		Set_XSCRIPT_Parameter(0,index);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

function SpringFestival_Jinzhu_Help()
	PushEvent("CCSHOP_HELP", 141)
end

function SpringFestival_Jinzhu_OnHiden()
	for i = 1, g_MaxProcess do
		g_NianHuaButtonTips[i]:Hide()
		--g_ProcessTimesBK[i]:Hide()
		g_NianHua[i]:Hide()
	end
	SpringFestival_Jinzhu_Image_Print_Tips:Hide()
	--SpringFestival_Jinzhu_Account_GetButton_Tips:Hide()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SpringFestival_Jinzhu_ResetPos()
	SpringFestival_Jinzhu_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	SpringFestival_Jinzhu_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end