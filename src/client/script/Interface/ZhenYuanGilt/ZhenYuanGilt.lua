--ZhenYuanGilt.lua
--皇朝御礼

local g_UnifiedPosition;
local g_ActionButton={};

function ZhenYuanGilt_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function ZhenYuanGilt_OnLoad()

	g_ActionButton[0] = ZhenYuanGilt_BuyFrame_Icon0;
	g_ActionButton[1] = ZhenYuanGilt_BuyFrame_Icon0_1;
	g_ActionButton[2] = ZhenYuanGilt_BuyFrame_Icon0_2;
	g_ActionButton[3] = ZhenYuanGilt_BuyFrame_Icon1;
	g_ActionButton[4] = ZhenYuanGilt_BuyFrame_Icon1_1;
	g_ActionButton[5] = ZhenYuanGilt_BuyFrame_Icon1_2;
	g_ActionButton[6] = ZhenYuanGilt_BuyFrame_Icon2;
	g_ActionButton[7] = ZhenYuanGilt_BuyFrame_Icon2_1;
	g_ActionButton[8] = ZhenYuanGilt_BuyFrame_Icon2_2;
	
	ZhenYuanGilt_BuyFrame_Text2_3:Hide()
end

function ZhenYuanGilt_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 88995803 ) then
		local nType = Get_XParam_INT(0)		--如果为0，则开启/关闭；如果为1，则只更新
		if nType == 0 then
			if this:IsVisible() then
				ZhenYuanGilt_Close();
			else
				this:Show();
			end
		end
		
		--更新数据
		if this:IsVisible() then
			local bIsBuyDuJin = Get_XParam_INT(1);
			local bIsBuyDiaoZhuo = Get_XParam_INT(2);
			local bIsBuyJingJin = Get_XParam_INT(3);
			
			if bIsBuyDuJin == 0 then
				ZhenYuanGilt_BuyFrame_Button0:Enable()
			else
				ZhenYuanGilt_BuyFrame_Button0:Disable()
			end
			if bIsBuyDiaoZhuo > 0 then
				ZhenYuanGilt_BuyFrame_Button1:Enable()
			else
				ZhenYuanGilt_BuyFrame_Button1:Disable()
			end
			if bIsBuyJingJin == 0 then
				ZhenYuanGilt_BuyFrame_Button2:Enable()
			else
				ZhenYuanGilt_BuyFrame_Button2:Disable()
			end
			
			local str = ScriptGlobal_Format("#{HCYL_150304_06}", bIsBuyDiaoZhuo)
			ZhenYuanGilt_Info:SetText(str)
			
			DataPool:Lua_ClearZhenYuanGiftActionItem();
			DataPool:Lua_SetZhenYuanGiftActionItem( 0, 38001179, 1 );
			DataPool:Lua_SetZhenYuanGiftActionItem( 1, 38001178, 2 );
			DataPool:Lua_SetZhenYuanGiftActionItem( 2, 38001182, 1 );
			DataPool:Lua_SetZhenYuanGiftActionItem( 3, 38001545, bIsBuyDiaoZhuo );
			DataPool:Lua_SetZhenYuanGiftActionItem( 4, 38000445, 1 );
			DataPool:Lua_SetZhenYuanGiftActionItem( 5, 38001183, 1 );
			DataPool:Lua_SetZhenYuanGiftActionItem( 6, 38001180, 1 );
			DataPool:Lua_SetZhenYuanGiftActionItem( 7, 20700055, 100 );
			DataPool:Lua_SetZhenYuanGiftActionItem( 8, 39901017, 1 );
			DataPool:Lua_UpdateZhenYuanGiftActionItem();
			
			for i=0, 8 do
				local theAction = EnumAction( i, "zhenyuangift_item");
				if theAction:GetID() ~= 0 then
					g_ActionButton[i]:SetActionItem( theAction:GetID() );
				else
					g_ActionButton[i]:SetActionItem( -1 );
				end
			end			
			
		end
	
	elseif event == "ADJEST_UI_POS" then
		ZhenYuanGilt_ResetPos();
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZhenYuanGilt_ResetPos();	
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
end

function ZhenYuanGilt_OnBuyDuJinGift()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnBuyGift" )
		Set_XSCRIPT_ScriptID( 889958 )
		Set_XSCRIPT_Parameter(0,0)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
		
end

function ZhenYuanGilt_OnBuyJingJinGift()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnBuyGift" )
		Set_XSCRIPT_ScriptID( 889958 )
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

function ZhenYuanGilt_OnBuyNewLibaoGift()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnBuyGift" )
		Set_XSCRIPT_ScriptID( 889958 )
		Set_XSCRIPT_Parameter(0,2)
		Set_XSCRIPT_Parameter(1,0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end

function ZhenYuanGilt_Close()
	DataPool:Lua_ClearZhenYuanGiftActionItem();
	this:Hide();
end

function ZhenYuanGilt_ResetPos()
	ZhenYuanGilt_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition);
end

