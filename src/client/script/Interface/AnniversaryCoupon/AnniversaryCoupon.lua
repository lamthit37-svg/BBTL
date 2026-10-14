local g_AnniversaryCoupon_Frame_UnifiedPosition;  
local g_AnniversaryCoupon_NeedMoney =0;
local g_AnniversaryCoupon_bagIndex =0;
local g_AnniversaryCoupon_FanChang_ZhenShou =39921707
function AnniversaryCoupon_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	 
end 

function AnniversaryCoupon_OnLoad()
	g_AnniversaryCoupon_Frame_UnifiedPosition	= AnniversaryCoupon_Frame:GetProperty("UnifiedPosition"); 	 
end

function AnniversaryCoupon_Frame_On_ResetPos()
  	AnniversaryCoupon_Frame:SetProperty("UnifiedPosition", g_AnniversaryCoupon_Frame_UnifiedPosition);
end

function AnniversaryCoupon_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		AnniversaryCoupon_Close();
	end
  
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		AnniversaryCoupon_Frame_On_ResetPos()
	end
		 
	--  
	if (event == "UI_COMMAND" and tonumber(arg0) == 5001801) then --Open
		if this:IsVisible() then
			this:Hide()
			return
		end
		 g_AnniversaryCoupon_Discount 	   = Get_XParam_INT(0) 
		 g_AnniversaryCoupon_NeedMoney = Get_XParam_INT(1) 
		 g_AnniversaryCoupon_bagIndex      = Get_XParam_INT(2) 
		 AnniversaryCoupon_OnInitial(); 
		 this:Show();
	end  
	if (event == "UI_COMMAND" and tonumber(arg0) == 5001803) then --Open
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
function AnniversaryCoupon_Close()  
	this:Hide(); 
end 

function AnniversaryCoupon_OnInitial()    
	AnniversaryCoupon_Lace_Fashion_text1:SetText(ScriptGlobal_Format("#{ZNJB_190315_48}",46888))
	AnniversaryCoupon_Lace_Fashion_text2:SetText(ScriptGlobal_Format("#{ZNJB_190315_48}",g_AnniversaryCoupon_NeedMoney))
	
	local theAction_ZhenShou = DataPool:CreateActionItemForShow(g_AnniversaryCoupon_FanChang_ZhenShou, 1)
	if theAction_ZhenShou:GetID() ~= 0 then
		AnniversaryCouponItem:SetActionItem(theAction_ZhenShou:GetID());
		AnniversaryCouponItem:Show();
	end
	
end

function AnniversaryCoupon_Buy_Click()
   	Clear_XSCRIPT()
   		Set_XSCRIPT_Function_Name("OnBuyItem")
   		Set_XSCRIPT_ScriptID(893087)
   		Set_XSCRIPT_Parameter(0,g_AnniversaryCoupon_bagIndex);
   		Set_XSCRIPT_Parameter(1,0);
   		Set_XSCRIPT_ParamCount(2)
   	Send_XSCRIPT()	 
end
 