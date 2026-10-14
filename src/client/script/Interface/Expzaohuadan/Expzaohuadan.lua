local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_yuanbao = {20,80,200,500}; --花费元宝交子数
local g_ExpPernum = {0.4, 1, 1.6, 2.5}
local g_Exp = {};
local g_num;
local g_bagId = -1;
local g_Expzaohuadan_Button ={}

function Expzaohuadan_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Expzaohuadan_OnEvent(event)
	if event == "UI_COMMAND"  and tonumber(arg0) == 890130 then
		Expzaohuadan_OnShown()
	elseif( event == "ADJEST_UI_POS" ) then
		Expzaohuadan_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Expzaohuadan_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function Expzaohuadan_OnLoad()
	g_Expzaohuadan_Button[1] = Expzaohuadan_Frame1_Button1;
	g_Expzaohuadan_Button[2] = Expzaohuadan_Frame1_Button2;
	g_Expzaohuadan_Button[3] = Expzaohuadan_Frame1_Button3;
	g_Expzaohuadan_Button[4] = Expzaohuadan_Frame1_Button4;
		-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Expzaohuadan_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Expzaohuadan_Frame:GetProperty("UnifiedYPosition");
		
end

function Expzaohuadan_OnShown()
	if g_bagId >=0 then
		LifeAbility : Lock_Packet_Item(g_bagId,0);
	end
	for i=1, 4 do
		g_Expzaohuadan_Button[i]:SetProperty("Selected", "False")
	end
	
	local nLittleIncomeMonsterCount = Player : GetData("LITTLEINCOMEMONSTERCOUNT");
	
	local baseExp = Get_XParam_INT(0);
	local AddKill = Get_XParam_INT(1);
	local curKill = Get_XParam_INT(2);
	g_bagId = Get_XParam_INT(3);
	local iCount = Get_XParam_INT(4);
	local sumKill = AddKill + curKill;
	
	local tempstr = ScriptGlobal_Format( "#{LZZHD_130520_34}", AddKill, curKill, sumKill);
	local tempStr1
	if sumKill <= nLittleIncomeMonsterCount then
		tempStr1 = "#{LZZHD_130520_35}";
	elseif sumKill > nLittleIncomeMonsterCount and curKill < nLittleIncomeMonsterCount then
		local moreKill = sumKill-nLittleIncomeMonsterCount;
		tempStr1 = ScriptGlobal_Format("#{LZZHD_130520_36}", moreKill);
	elseif sumKill > nLittleIncomeMonsterCount and curKill >= nLittleIncomeMonsterCount then
		tempStr1 = ScriptGlobal_Format("#{LZZHD_130520_37}", AddKill);
	else
		return
	end
	local tempStr3 = ScriptGlobal_Format( "#{LZZHD_130520_49}", iCount)
	Expzaohuadan_Frame1_Info1:SetText(tempstr..tempStr1..tempStr3);

	local finalExp
	--提升后杀怪值大于7000，收益缩减
	if sumKill > nLittleIncomeMonsterCount then		
		local tempNum = nLittleIncomeMonsterCount - curKill
		if tempNum < 0 then 
			tempNum = 0
		end
		--策划给的公式
		finalExp = math.floor((baseExp/AddKill)*tempNum + (baseExp/AddKill)*(AddKill-tempNum)/2)
	else
		--收益百分百
		finalExp = baseExp
	end	
	for i=1, 4 do
		 g_Exp[i] = math.floor(finalExp*g_ExpPernum[i]);
	end
	
	local tempStr2;
	tempStr2 = ScriptGlobal_Format("#{LZZHD_130520_39}", g_yuanbao[1], g_Exp[1]);
	Expzaohuadan_Frame2_Info1:SetText(tempStr2);
	tempStr2 = ScriptGlobal_Format("#{LZZHD_130520_45}", g_yuanbao[2], g_Exp[2]);
	Expzaohuadan_Frame2_Info2:SetText(tempStr2);
	tempStr2 = ScriptGlobal_Format("#{LZZHD_130520_45}", g_yuanbao[3], g_Exp[3]);
	Expzaohuadan_Frame2_Info3:SetText(tempStr2);
	tempStr2 = ScriptGlobal_Format("#{LZZHD_130520_45}", g_yuanbao[4], g_Exp[4]);
	Expzaohuadan_Frame2_Info4:SetText(tempStr2);
	
	LifeAbility : Lock_Packet_Item(g_bagId,1);
	Expzaohuadan_OK:Disable();
	this:Show();
end

function Expzaohuadan_Buttons_Clicked()

	--经验处理
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("AddExpFunc");
				Set_XSCRIPT_ScriptID(890130);
				Set_XSCRIPT_Parameter(0, g_bagId);
				Set_XSCRIPT_Parameter(1, g_num);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
	this:Hide();
end
--================================================
-- 界面的默认相对位置
--================================================
function Expzaohuadan_ResetPos()
	Expzaohuadan_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Expzaohuadan_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Expzaohuadan_SelResult(num)
	if num<1 or num>4 then
		return
	end
	g_num = num;
	for i=1, 4 do
		g_Expzaohuadan_Button[i]:SetProperty("Selected", "False")
	end
	g_Expzaohuadan_Button[num]:SetProperty("Selected", "True")
	Expzaohuadan_OK:Enable();
end

function Expzaohuadan_OnHiden()
	LifeAbility : Lock_Packet_Item(g_bagId,0)
	this:Hide();
end