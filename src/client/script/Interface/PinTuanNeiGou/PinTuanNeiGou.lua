local g_PinTuanNeiGou_Frame_UnifiedXPosition;

local g_PinTuanNeiGou_Frame_UnifiedYPosition;
local g_PinTuanNeiGou_tuangou_Item1 =39920945
local g_PinTuanNeiGou_tuangou_Item2 =39925304
local g_PinTuanNeiGou_tuangou_Item3 =39922710


local g_PinTuanNeiGou_tuangoujuan1 =38002954
local g_PinTuanNeiGou_tuangoujuan2 =38002955
local g_PinTuanNeiGou_tuangoujuan3 =38002956
local g_MF1 = 5600
local g_MF2 = 5601
local g_MF3 = 5602
-----------各个模块的得分 begin-------

local objCared = -1
local g_obj_target = -1
function PinTuanNeiGou_PreLoad()
	--开启界面

 	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX")

end	

function PinTuanNeiGou_OnLoad()

	-- 保存界面的默认相对位置
	g_PinTuanNeiGou_Frame_UnifiedXPosition	= PinTuanNeiGou_Frame : GetProperty("UnifiedXPosition");
	g_PinTuanNeiGou_Frame_UnifiedYPosition	= PinTuanNeiGou_Frame : GetProperty("UnifiedYPosition");


end

function PinTuanNeiGou_OnEvent(event)

	if (event == "ADJEST_UI_POS" ) then
		PinTuanNeiGou_Frame_On_ResetPos();
	-- 游戏分辨率发生了变化		
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		PinTuanNeiGou_Frame_On_ResetPos();
		--g_obj_target = tonumber(arg0)
		--objCared = DataPool : GetNPCIDByServerID(g_obj_target); --targetid ：客户端
		--MenPai_Dadizi_BeginCareObject()	
	elseif event == "UI_COMMAND" and tonumber(arg0) == 893375 then	
		
		g_obj_target = Get_XParam_INT(0)
		objCared = DataPool : GetNPCIDByServerID(g_obj_target); --targetid ：客户端
		PinTuanNeiGou_BeginCareObject()
		PinTuanNeiGou_Open()

	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		PinTuanNeiGou_Fresh()
	end
	
end	
--===============================================
-- 					切换界面
--===============================================
--打开评分界面 也就是主界面--
function PinTuanNeiGou_Open()
	local theAction = DataPool:CreateActionItemForShow(g_PinTuanNeiGou_tuangou_Item1, 1)
	if theAction:GetID() ~= 0 then
		PinTuanNeiGou_Page_Lace1Item:SetActionItem(theAction:GetID());
		PinTuanNeiGou_Page_Lace1Item:Show();
	end
	theAction = DataPool:CreateActionItemForShow(g_PinTuanNeiGou_tuangou_Item2, 1)
	if theAction:GetID() ~= 0 then
		PinTuanNeiGou_Page_Lace2Item:SetActionItem(theAction:GetID());
		PinTuanNeiGou_Page_Lace2Item:Show();
	end
	theAction = DataPool:CreateActionItemForShow(g_PinTuanNeiGou_tuangou_Item3, 1)
	if theAction:GetID() ~= 0 then
		PinTuanNeiGou_Page_Lace3Item:SetActionItem(theAction:GetID());
		PinTuanNeiGou_Page_Lace3Item:Show();
	end


	PinTuanNeiGou_Page_Lace1_YuanBao_text:SetText(ScriptGlobal_Format("#{XFTG_191206_06}",2138))
	PinTuanNeiGou_Page_Lace2_YuanBao_text:SetText(ScriptGlobal_Format("#{XFTG_191206_06}",9000))
	PinTuanNeiGou_Page_Lace3_YuanBao_text:SetText(ScriptGlobal_Format("#{XFTG_191206_06}",20000))

	
	
	PinTuanNeiGou_Page_Lace1_YuanBao2_text:SetText(ScriptGlobal_Format("#{XFTG_191206_08}",1818))
	PinTuanNeiGou_Page_Lace2_YuanBao2_text:SetText(ScriptGlobal_Format("#{XFTG_191206_08}",5850))
	PinTuanNeiGou_Page_Lace3_YuanBao2_text:SetText(ScriptGlobal_Format("#{XFTG_191206_08}",9000))


		
	PinTuanNeiGou_Page_Lace1_ZheKou_text:SetText(ScriptGlobal_Format("#{XFTG_191206_07}",tostring(8),tostring(5)))
	PinTuanNeiGou_Page_Lace2_ZheKou_text:SetText(ScriptGlobal_Format("#{XFTG_191206_07}",tostring(6),tostring(5)))
	PinTuanNeiGou_Page_Lace3_ZheKou_text:SetText(ScriptGlobal_Format("#{XFTG_191206_07}",tostring(4),tostring(5)))

	local num1 = PlayerPackage:CountAvailableItemByIDTable(tonumber(g_PinTuanNeiGou_tuangoujuan1))
	if num1 <= 0 then
		PinTuanNeiGou_Page_Lace1_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_09}",0))
	else
		PinTuanNeiGou_Page_Lace1_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_10}",num1))
	end



	local num2 = PlayerPackage:CountAvailableItemByIDTable(tonumber(g_PinTuanNeiGou_tuangoujuan2))
	if num2 <= 0 then
		PinTuanNeiGou_Page_Lace2_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_09}",0))
	else
		PinTuanNeiGou_Page_Lace2_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_10}",num2))
	end

	local num3 = PlayerPackage:CountAvailableItemByIDTable(tonumber(g_PinTuanNeiGou_tuangoujuan3))
	if num3 <= 0 then
		PinTuanNeiGou_Page_Lace3_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_09}",0))
	else
		PinTuanNeiGou_Page_Lace3_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_10}",num3))
	end

	local MF1 = Pneuma:GetMF(g_MF1)
	local MF2 = Pneuma:GetMF(g_MF2)
	local MF3 = Pneuma:GetMF(g_MF3)

	if MF1 == 1 then
	
		PinTuanNeiGou_Page_Lace1_ReFresh_Btn:Disable()
	else
	
		PinTuanNeiGou_Page_Lace1_ReFresh_Btn:Enable()
	end
	if MF2 == 1 then
		
		PinTuanNeiGou_Page_Lace2_ReFresh_Btn:Disable()
	else
	
		PinTuanNeiGou_Page_Lace2_ReFresh_Btn:Enable()
	end
	if MF3 == 1 then
	
		PinTuanNeiGou_Page_Lace3_ReFresh_Btn:Disable()
	else

		PinTuanNeiGou_Page_Lace3_ReFresh_Btn:Enable()
	end

	this:Show()
end
--===============================================
-- 					切换界面
--===============================================
--打开评分界面 也就是主界面--
function PinTuanNeiGou_Fresh()
	
	local num1 = PlayerPackage:CountAvailableItemByIDTable(tonumber(g_PinTuanNeiGou_tuangoujuan1))
	if num1 <= 0 then
		PinTuanNeiGou_Page_Lace1_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_09}",0))
	else
		PinTuanNeiGou_Page_Lace1_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_10}",num1))
	end



	local num2 = PlayerPackage:CountAvailableItemByIDTable(tonumber(g_PinTuanNeiGou_tuangoujuan2))
	if num2 <= 0 then
		PinTuanNeiGou_Page_Lace2_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_09}",0))
	else
		PinTuanNeiGou_Page_Lace2_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_10}",num2))
	end

	local num3 = PlayerPackage:CountAvailableItemByIDTable(tonumber(g_PinTuanNeiGou_tuangoujuan3))
	if num3 <= 0 then
		PinTuanNeiGou_Page_Lace3_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_09}",0))
	else
		PinTuanNeiGou_Page_Lace3_ShengYu_text:SetText(ScriptGlobal_Format("#{XFTG_191206_10}",num3))
	end

	local MF1 = Pneuma:GetMF(g_MF1)
	local MF2 = Pneuma:GetMF(g_MF2)
	local MF3 = Pneuma:GetMF(g_MF3)

	if MF1 == 1 then
		PinTuanNeiGou_Page_Lace1_ReFresh_Btn:Disable()
	else
		PinTuanNeiGou_Page_Lace1_ReFresh_Btn:Enable()
	end
	if MF2 == 1 then
		PinTuanNeiGou_Page_Lace2_ReFresh_Btn:Disable()
	else
		PinTuanNeiGou_Page_Lace2_ReFresh_Btn:Enable()
	end
	if MF3 == 1 then
		PinTuanNeiGou_Page_Lace3_ReFresh_Btn:Disable()
	else
		PinTuanNeiGou_Page_Lace3_ReFresh_Btn:Enable()
	end
	this:Show()
end
function PinTuanNeiGou_Close() 
	this:Hide()
end


--更新主界面位置
function PinTuanNeiGou_Frame_On_ResetPos()
	PinTuanNeiGou_Frame : SetProperty("UnifiedXPosition", g_PinTuanNeiGou_Frame_UnifiedXPosition);
	PinTuanNeiGou_Frame : SetProperty("UnifiedYPosition", g_PinTuanNeiGou_Frame_UnifiedYPosition);
end
--=========================================================
--开始关心NPC
--=========================================================
function PinTuanNeiGou_BeginCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "PinTuanNeiGou");
	end
	this:CareObject(objCared, 1, "PinTuanNeiGou")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function PinTuanNeiGou_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "PinTuanNeiGou");
		objCared = -1;
	end
end


--=========================================================
--确认
--=========================================================
function PinTuanNeiGou_Ok1()

	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnBuyItem1")
	Set_XSCRIPT_ScriptID(893375)
	Set_XSCRIPT_Parameter(0,0);
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	 
end

--=========================================================
--确认
--=========================================================
function PinTuanNeiGou_Ok2()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnBuyItem2")
	Set_XSCRIPT_ScriptID(893375)
	Set_XSCRIPT_Parameter(0,0);
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	 
end

--=========================================================
--确认
--=========================================================
function PinTuanNeiGou_Ok3()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("OnBuyItem3")
	Set_XSCRIPT_ScriptID(893375)
	Set_XSCRIPT_Parameter(0,0);
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	 
end