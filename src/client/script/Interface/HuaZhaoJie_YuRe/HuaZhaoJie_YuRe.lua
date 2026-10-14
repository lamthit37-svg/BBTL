-- 2022花朝节预热
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_StartTime = 20230227
local g_MidTime = 20230305
local g_EndTime = 20230326

local g_NeedYuanBao = 20000


local g_NumberImage1 = {

	[0] = "set:HuaZhaoJie_YuRe image:Light_0",
	[1] = "set:HuaZhaoJie_YuRe image:Light_1",
	[2] = "set:HuaZhaoJie_YuRe image:Light_2",
	[3] = "set:HuaZhaoJie_YuRe image:Light_3",
	[4] = "set:HuaZhaoJie_YuRe image:Light_4",
	[5] = "set:HuaZhaoJie_YuRe image:Light_5",
	[6] = "set:HuaZhaoJie_YuRe image:Light_6",
	[7] = "set:HuaZhaoJie_YuRe image:Light_7",
	[8] = "set:HuaZhaoJie_YuRe image:Light_8",
	[9] = "set:HuaZhaoJie_YuRe image:Light_9",
	
}

local g_NumberImage2 = {

	[0] = "set:HuaZhaoJie_YuRe image:Dark_0",
	[1] = "set:HuaZhaoJie_YuRe image:Dark_1",
	[2] = "set:HuaZhaoJie_YuRe image:Dark_2",
	[3] = "set:HuaZhaoJie_YuRe image:Dark_3",
	[4] = "set:HuaZhaoJie_YuRe image:Dark_4",
	[5] = "set:HuaZhaoJie_YuRe image:Dark_5",
	[6] = "set:HuaZhaoJie_YuRe image:Dark_6",
	[7] = "set:HuaZhaoJie_YuRe image:Dark_7",
	[8] = "set:HuaZhaoJie_YuRe image:Dark_8",
	[9] = "set:HuaZhaoJie_YuRe image:Dark_9",
	
}

local g_PointImage = {
	[1] = "set:HuaZhaoJie_YuRe image: Light_Point",
	[2] = "set:HuaZhaoJie_YuRe image:Dark_Point",
}
function HuaZhaoJie_YuRe_PreLoad()

	this:RegisterEvent("UI_COMMAND", true);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function HuaZhaoJie_YuRe_OnLoad()

	g_Frame_UnifiedXPosition	= HuaZhaoJie_YuReFrame_BK:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= HuaZhaoJie_YuReFrame_BK:GetProperty("UnifiedYPosition");
		
end

function HuaZhaoJie_YuRe_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		HuaZhaoJie_YuRe_ResetPos()	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HuaZhaoJie_YuRe_ResetPos()	
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88888601 then
		local curDayTime = Get_XParam_INT(0)
		local nZheKou = Get_XParam_INT(1)
		local nKanJiaTime = Get_XParam_INT(2)
		local isSignUp = Get_XParam_INT(3)
		local nBuyLimit = Get_XParam_INT(4)
		local ntype = Get_XParam_INT(5)
		local nAnimate = Get_XParam_INT(6)
		HuaZhaoJie_YuRe_Updata(curDayTime, nZheKou, nKanJiaTime, isSignUp, nBuyLimit, ntype, nAnimate)
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88888604 then
		local isSignUpHotPoint = Get_XParam_INT(1)
		local isKanJiahotPoint = Get_XParam_INT(2)
		HuaZhaoJie_YuRe_UpdataHotPoint(isSignUpHotPoint, isKanJiahotPoint)
	end
end

function HuaZhaoJie_YuRe_Updata(curDayTime, nZheKou, nKanJiaTime, isSignUp, nBuyLimit, ntype, nAnimate)
	
	--计算折扣
	nZheKou = math.mod(nZheKou,1000)
	local nDiscount = 100-nZheKou
	local num1 = math.mod(nDiscount,10) --个位
	local num2 = math.floor(math.mod(nDiscount,100)/10) --十位
	local num3 = math.floor(nDiscount/100) --百位
	
	if curDayTime >= g_StartTime and curDayTime <= g_MidTime then
		HuaZhaoJie_YuReClient1:Show()
		HuaZhaoJie_YuReClient2:Hide()
		if num3 == 1 then --无折扣
			HuaZhaoJie_YuReCurrentDiscount_Original:Show()
			HuaZhaoJie_YuReCurrentDiscount_Numb1:Hide()
			HuaZhaoJie_YuReCurrentDiscount_Numb2:Hide()
			HuaZhaoJie_YuReOriginalPrice_Line:Hide()
			HuaZhaoJie_YuReCurrentDiscount_Point:Hide()
			HuaZhaoJie_YuReCurrentDiscount_Zhe:Show()
			HuaZhaoJie_YuReCurrentDiscount_NumbBK:Hide()
		elseif (num2 < 5 or (num2 == 5 and num1 == 0)) then
			HuaZhaoJie_YuReCurrentDiscount_Original:Hide()
			HuaZhaoJie_YuReCurrentDiscount_Numb1:Show()
			HuaZhaoJie_YuReCurrentDiscount_Numb2:Show()
			HuaZhaoJie_YuReCurrentDiscount_Numb1:SetProperty("Image", g_NumberImage2[num2])	
			HuaZhaoJie_YuReCurrentDiscount_Numb2:SetProperty("Image", g_NumberImage2[num1])	
			HuaZhaoJie_YuReCurrentDiscount_Point:SetProperty("Image", g_PointImage[2])	
			HuaZhaoJie_YuReOriginalPrice_Line:Show()
			HuaZhaoJie_YuReCurrentDiscount_Point:Show()
			HuaZhaoJie_YuReCurrentDiscount_Zhe:Show()
			HuaZhaoJie_YuReCurrentDiscount_NumbBK:Show()
		else
			HuaZhaoJie_YuReCurrentDiscount_Original:Hide()
			HuaZhaoJie_YuReCurrentDiscount_Numb1:Show()
			HuaZhaoJie_YuReCurrentDiscount_Numb2:Show()
			HuaZhaoJie_YuReCurrentDiscount_Numb1:SetProperty("Image", g_NumberImage1[num2])	
			HuaZhaoJie_YuReCurrentDiscount_Numb2:SetProperty("Image", g_NumberImage1[num1])	
			HuaZhaoJie_YuReCurrentDiscount_Point:SetProperty("Image", g_PointImage[1])	
			HuaZhaoJie_YuReOriginalPrice_Line:Show()
			HuaZhaoJie_YuReCurrentDiscount_Point:Show()
			HuaZhaoJie_YuReCurrentDiscount_Zhe:Show()
			HuaZhaoJie_YuReCurrentDiscount_NumbBK:Hide()
		end
		HuaZhaoJie_YuReCurrentPrice_Numb:SetText(ScriptGlobal_Format("#{HZYR_211222_33}", math.floor(g_NeedYuanBao*nDiscount/100)))
	else
		HuaZhaoJie_YuReClient2:Show()
		HuaZhaoJie_YuReClient1:Hide()
		if num3 == 1 then --无折扣
			HuaZhaoJie_Client2_YuReCurrentDiscount_Original:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb1:Hide()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb2:Hide()
			HuaZhaoJie_Client2_YuReOriginalPrice_Line:Hide()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Point:Hide()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Zhe:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_NumbBK:Hide()
		elseif (num2 < 5 or (num2 == 5 and num1 == 0)) then
			HuaZhaoJie_Client2_YuReCurrentDiscount_Original:Hide()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb1:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb2:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb1:SetProperty("Image", g_NumberImage2[num2])	
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb2:SetProperty("Image", g_NumberImage2[num1])	
			HuaZhaoJie_Client2_YuReCurrentDiscount_Point:SetProperty("Image", g_PointImage[2])	
			HuaZhaoJie_YuReOriginalPrice_Line:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Point:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Zhe:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_NumbBK:Show()
		else
			HuaZhaoJie_Client2_YuReCurrentDiscount_Original:Hide()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb1:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb2:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb1:SetProperty("Image", g_NumberImage1[num2])	
			HuaZhaoJie_Client2_YuReCurrentDiscount_Numb2:SetProperty("Image", g_NumberImage1[num1])	
			HuaZhaoJie_Client2_YuReCurrentDiscount_Point:SetProperty("Image", g_PointImage[1])	
			HuaZhaoJie_YuReOriginalPrice_Line:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Point:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_Zhe:Show()
			HuaZhaoJie_Client2_YuReCurrentDiscount_NumbBK:Hide()
		end
		HuaZhaoJie_Client2_YuReCurrentPrice_Numb:SetText(ScriptGlobal_Format("#{HZYR_211222_33}", math.floor(g_NeedYuanBao*nDiscount/100)))
	end
	HuaZhaoJie_YuReCurrentDiscount_Success:Hide()
	HuaZhaoJie_YuReCurrentDiscount_Lucky:Hide()
	
	if isSignUp == 1 then
		HuaZhaoJie_YuReSignIn:Show()
		HuaZhaoJie_YuReGetGift:Hide()
	else
		HuaZhaoJie_YuReSignIn:Hide()
		HuaZhaoJie_YuReGetGift:Show()
	end
	
	if nBuyLimit == 1 then
		HuaZhaoJie_YuReReceived:Show()
		HuaZhaoJie_Client2_YuReReceived:Show()
	else
		HuaZhaoJie_YuReReceived:Hide()
		HuaZhaoJie_Client2_YuReReceived:Hide()
	end
	
	if ntype == 1 then
		if nAnimate == 0 then
			HuaZhaoJie_YuReCurrentDiscount_Success:Play(true)
			HuaZhaoJie_YuReCurrentDiscount_Success:Show()		
		else
			HuaZhaoJie_YuReCurrentDiscount_Lucky:Play(true)
			HuaZhaoJie_YuReCurrentDiscount_Lucky:Show()		
		end
	end
	if KaJi:LuaFnIsKaJiServer() == 1 then
		HuaZhaoJie_YuReItem_Icon:SetToolTip("#{HZYR_211222_83}")
	else
		HuaZhaoJie_YuReItem_Icon:SetToolTip("#{HZYR_211222_34}")
	end
	
end

function HuaZhaoJie_YuRe_UpdataHotPoint(isSignUpHotPoint, isKanJiahotPoint)

	if isSignUpHotPoint == 1 then
		HuaZhaoJie_YuReGetGift_Tips:Show()
		HuaZhaoJie_YuReSignIn:Hide()
		HuaZhaoJie_YuReGetGift:Show()
	else
		HuaZhaoJie_YuReGetGift_Tips:Hide()
	end
	
	-- if isKanJiahotPoint == 1 then
		-- HuaZhaoJie_YuReDiscount_Tips:Show()
	-- else
		-- HuaZhaoJie_YuReDiscount_Tips:Hide()
	-- end
	
end

function HuaZhaoJie_YuRe_Buy()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("Buy");
		Set_XSCRIPT_ScriptID(888886);
		Set_XSCRIPT_Parameter(0,0);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
end

function HuaZhaoJie_YuRe_Preview()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, 10127044)
		Set_XSCRIPT_Parameter(1, 169)
		Set_XSCRIPT_Parameter(2, 135)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end


function HuaZhaoJie_YuRe_SignUp()
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("SignUp");
		Set_XSCRIPT_ScriptID(888886);
		Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT();
end



function HuaZhaoJie_YuRe_Help()
	PushEvent("CCSHOP_HELP", 145)
end

function HuaZhaoJie_YuRe_OnHiden()	
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function HuaZhaoJie_YuRe_ResetPos()
	HuaZhaoJie_YuReFrame_BK:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	HuaZhaoJie_YuReFrame_BK:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end