local g_Fuli_ExpZhaoHui_Frame_UnifiedPosition; 
local g_Fuli_ExpZhaoHui_CanBackCount;
local g_Fuli_ExpZhaoHui_NeedYuanBao; 			
local g_Fuli_ExpZhaoHui_NeedJinBi; 				
local g_Fuli_ExpZhaoHui_GainExpYuanBao; 		
local g_Fuli_ExpZhaoHui_GainExpJinBi; 			

function Fuli_ExpZhaoHui_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)  
	this:RegisterEvent("OBJECT_CARED_EVENT",false)  
	this:RegisterEvent("UPDATE_YUANBAO")  
	this:RegisterEvent("MONEY_CHANGE_EX",false)  
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)   
end


function Fuli_ExpZhaoHui_OnLoad()
	g_Fuli_ExpZhaoHui_Frame_UnifiedPosition	=Fuli_ExpZhaoHui_Frame:GetProperty("UnifiedPosition");	
end

function Fuli_ExpZhaoHui_OnEvent(event)
		-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Fuli_ExpZhaoHui_OnHiden();
	end 
	
	
	if (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		Fuli_ExpZhaoHui_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	end
	
	if (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		Fuli_ExpZhaoHui_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	end
	
	if (event == "UPDATE_YUANBAO" and this:IsVisible() ) then
		Fuli_ExpZhaoHui_SelfYuanbao:SetText(tostring(Player:GetData("YUANBAO")))
	end
	if event == "UI_COMMAND" and tonumber(arg0) == 2017121601 then 
		g_Fuli_ExpZhaoHui_CanBackCount 						= Get_XParam_INT( 0 ); 
		g_Fuli_ExpZhaoHui_NeedYuanBao 						= Get_XParam_INT( 1 );
		g_Fuli_ExpZhaoHui_NeedJinBi 							= Get_XParam_INT( 2 );
		g_Fuli_ExpZhaoHui_GainExpYuanBao 					= Get_XParam_INT( 3 );
		g_Fuli_ExpZhaoHui_GainExpJinBi 						= Get_XParam_INT( 4 );
		Fuli_ExpZhaoHui_Flush(); 
	end	
	
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Fuli_ExpZhaoHui_On_ResetPos()
	-- 游戏分辨率发生了变化
	end
	if (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Fuli_ExpZhaoHui_On_ResetPos()
	end	
	if event == "UI_COMMAND" and tonumber(arg0) == 2017122201 then  
		Fuli_ExpZhaoHui_OnClosed(); 
	end	
end 

function Fuli_ExpZhaoHui_Flush()
	if Player:GetData("Is2606S") == 1 then
		Fuli_ExpZhaoHuiBasicInfo_Explain:SetText( ScriptGlobal_Format("#{JYZH_260617_26}", g_Fuli_ExpZhaoHui_GainExpJinBi) )
	else
		Fuli_ExpZhaoHuiBasicInfo_Explain:SetText( ScriptGlobal_Format("#{XTZY_171213_17}", g_Fuli_ExpZhaoHui_CanBackCount) )
	end

	Fuli_ExpZhaoHui_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	Fuli_ExpZhaoHui_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	Fuli_ExpZhaoHui_SelfYuanbao:SetText(tostring(Player:GetData("YUANBAO")))
	Fuli_ExpZhaoHuiContent2_RightText1:SetText(  ScriptGlobal_Format("#{XTZY_171213_22}",g_Fuli_ExpZhaoHui_NeedJinBi ))
	Fuli_ExpZhaoHuiContent2_RightText2:SetText(  ScriptGlobal_Format("#{XTZY_171213_20}",g_Fuli_ExpZhaoHui_GainExpJinBi) )
	Fuli_ExpZhaoHuiContentText1:SetText(  ScriptGlobal_Format("#{XTZY_171213_19}",g_Fuli_ExpZhaoHui_NeedYuanBao ) )
	Fuli_ExpZhaoHuiContentText2:SetText(  ScriptGlobal_Format("#{XTZY_171213_20}",g_Fuli_ExpZhaoHui_GainExpYuanBao ) )
	this:Show();
	
end
function Fuli_ExpZhaoHui_OnClosed() 
	this:Hide();
end

function Fuli_ExpZhaoHui_OnHiden() 
	this:Hide();
end

function Fuli_ExpZhaoHui_On_ResetPos()
  Fuli_ExpZhaoHui_Frame:SetProperty("UnifiedPosition", g_Fuli_ExpZhaoHui_Frame_UnifiedPosition);
end

function Fuli_ExpZhaoHui_GetBackExp_ByYuanbao()  
	Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("GetExp_ByYuanBao");
			Set_XSCRIPT_ScriptID(892659);
			Set_XSCRIPT_Parameter(0, 0 )  
			Set_XSCRIPT_Parameter(1, 0 )  
			Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end
function Fuli_ExpZhaoHui_GetBackExp_ByJinBi() 
	g_ExpZhaoHui_SelectMatchCount = 1;
	g_ExpZhaoHui_SelectMatchType  = 1;
	Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("GetExp_ByMoney");
			Set_XSCRIPT_ScriptID(892659); 
			Set_XSCRIPT_Parameter(0, 0 )  
			Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	
end  