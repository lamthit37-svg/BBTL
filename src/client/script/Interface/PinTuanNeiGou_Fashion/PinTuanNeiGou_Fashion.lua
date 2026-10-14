local PinTuanNeiGou_Fashion_Frame_UnifiedPosition;  
local PinTuanNeiGou_Fashion_NeedMoney =0;
local PinTuanNeiGou_Fashion_bagIndex =0;
local PinTuanNeiGou_Fashion_FanChang_ZhenShou =39922080
function PinTuanNeiGou_Fashion_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	 
end 

function PinTuanNeiGou_Fashion_OnLoad()
	PinTuanNeiGou_Fashion_Frame_UnifiedPosition	= PinTuanNeiGou_Fashion_Frame:GetProperty("UnifiedPosition"); 	 
end

function PinTuanNeiGou_Fashion_Frame_On_ResetPos()
  	PinTuanNeiGou_Fashion_Frame:SetProperty("UnifiedPosition", PinTuanNeiGou_Fashion_Frame_UnifiedPosition);
end

function PinTuanNeiGou_Fashion_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		PinTuanNeiGou_Fashion_Close();
	end
  
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		PinTuanNeiGou_Fashion_Frame_On_ResetPos()
	end
		 
	--  
	if (event == "UI_COMMAND" and tonumber(arg0) == 898104) then --Open
		if this:IsVisible() then
			this:Hide()
			return
		end
		 PinTuanNeiGou_Fashion_Discount 	   = Get_XParam_INT(0) 
		 PinTuanNeiGou_Fashion_NeedMoney = Get_XParam_INT(1) 
		 PinTuanNeiGou_Fashion_bagIndex      = Get_XParam_INT(2) 
		 PinTuanNeiGou_Fashion_OnInitial(); 
		 this:Show();
	end  
	if (event == "UI_COMMAND" and tonumber(arg0) == 89810402) then --Open
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
function PinTuanNeiGou_Fashion_Close()  
	this:Hide(); 
end 

function PinTuanNeiGou_Fashion_OnInitial()    
	PinTuanNeiGou_Fashion_Lace_Fashion_text1:SetText(ScriptGlobal_Format("#{XFTG_191206_32}",20000))
	PinTuanNeiGou_Fashion_Lace_Fashion_text2:SetText(ScriptGlobal_Format("#{XFTG_191206_33}",PinTuanNeiGou_Fashion_NeedMoney))
	PinTuanNeiGou_Fashion_ZheKou_text:SetText(ScriptGlobal_Format("#{XFTG_191206_07}",math.floor(PinTuanNeiGou_Fashion_Discount/10),math.mod(PinTuanNeiGou_Fashion_Discount,10)))
	local theAction_ZhenShou = DataPool:CreateActionItemForShow(PinTuanNeiGou_Fashion_FanChang_ZhenShou, 1)
	if theAction_ZhenShou:GetID() ~= 0 then
		PinTuanNeiGou_FashionItem:SetActionItem(theAction_ZhenShou:GetID());
		PinTuanNeiGou_FashionItem:Show();
	end
	
end

function PinTuanNeiGou_Fashion_Buy_Click()
   	Clear_XSCRIPT()
   		Set_XSCRIPT_Function_Name("OnBuyItem")
   		Set_XSCRIPT_ScriptID(898104)
   		Set_XSCRIPT_Parameter(0,PinTuanNeiGou_Fashion_bagIndex);
   		Set_XSCRIPT_Parameter(1,0);
   		Set_XSCRIPT_ParamCount(2)
   	Send_XSCRIPT()	 
end
 