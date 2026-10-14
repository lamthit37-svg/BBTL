local g_PinTuanNeiGou_ShiZhuang_Frame_UnifiedPosition;  
local g_PinTuanNeiGou_ShiZhuang_NeedMoney =0;
local g_PinTuanNeiGou_ShiZhuang_bagIndex =0;
local g_PinTuanNeiGou_ShiZhuang_FanChang_ZhenShou =39922042
function PinTuanNeiGou_ShiZhuang_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	 
end 

function PinTuanNeiGou_ShiZhuang_OnLoad()
	g_PinTuanNeiGou_ShiZhuang_Frame_UnifiedPosition	= PinTuanNeiGou_ShiZhuang_Frame:GetProperty("UnifiedPosition"); 	 
end

function PinTuanNeiGou_ShiZhuang_Frame_On_ResetPos()
  	PinTuanNeiGou_ShiZhuang_Frame:SetProperty("UnifiedPosition", g_PinTuanNeiGou_ShiZhuang_Frame_UnifiedPosition);
end

function PinTuanNeiGou_ShiZhuang_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		PinTuanNeiGou_ShiZhuang_Close();
	end
  
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		PinTuanNeiGou_ShiZhuang_Frame_On_ResetPos()
	end
		 
	--  
	if (event == "UI_COMMAND" and tonumber(arg0) == 893372) then --Open
		if this:IsVisible() then
			this:Hide()
			return
		end
		 g_PinTuanNeiGou_ShiZhuang_Discount 	   = Get_XParam_INT(0) 
		 g_PinTuanNeiGou_ShiZhuang_NeedMoney = Get_XParam_INT(1) 
		 g_PinTuanNeiGou_ShiZhuang_bagIndex      = Get_XParam_INT(2) 
		 PinTuanNeiGou_ShiZhuang_OnInitial(); 
		 this:Show();
	end  
	if (event == "UI_COMMAND" and tonumber(arg0) == 89337002) then --Open
		if this:IsVisible() then
			this:Hide()
			return
		end 
	end  
end 
----------------------------------------------------------------------------------
--
-- 关闭
--	
function PinTuanNeiGou_ShiZhuang_Close()  
	this:Hide(); 
end 

function PinTuanNeiGou_ShiZhuang_OnInitial()    
	PinTuanNeiGou_ShiZhuang_Lace_Fashion_text1:SetText(ScriptGlobal_Format("#{XFTG_191206_32}",9000))
	PinTuanNeiGou_ShiZhuang_Lace_Fashion_text2:SetText(ScriptGlobal_Format("#{XFTG_191206_33}",g_PinTuanNeiGou_ShiZhuang_NeedMoney))
	PinTuanNeiGou_ShiZhuang_ZheKou_text:SetText(ScriptGlobal_Format("#{XFTG_191206_07}",math.floor(g_PinTuanNeiGou_ShiZhuang_Discount/10),math.mod(g_PinTuanNeiGou_ShiZhuang_Discount,10)))
	local theAction_ZhenShou = DataPool:CreateActionItemForShow(g_PinTuanNeiGou_ShiZhuang_FanChang_ZhenShou, 1)
	if theAction_ZhenShou:GetID() ~= 0 then
		PinTuanNeiGou_ShiZhuangItem:SetActionItem(theAction_ZhenShou:GetID());
		PinTuanNeiGou_ShiZhuangItem:Show();
	end
	
end

function PinTuanNeiGou_ShiZhuang_Buy_Click()
   	Clear_XSCRIPT()
   		Set_XSCRIPT_Function_Name("OnBuyItem")
   		Set_XSCRIPT_ScriptID(893372)
   		Set_XSCRIPT_Parameter(0,g_PinTuanNeiGou_ShiZhuang_bagIndex);
   		Set_XSCRIPT_Parameter(1,0);
   		Set_XSCRIPT_ParamCount(2)
   	Send_XSCRIPT()	 
end
 