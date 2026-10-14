
local g_ZhouNian12_Wenwu_Frame_UnifiedPosition; 
local g_ZhouNian12_image ={ 
	[1] = "set:Sign image:Signorange_0";
	[2] = "set:Sign image:Signorange_1";
	[3] = "set:Sign image:Signorange_2";
	[4] = "set:Sign image:Signorange_3";
	[5] = "set:Sign image:Signorange_4";
	[6] = "set:Sign image:Signorange_5"; 
}
function ZhouNian12_Wenwu_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("OPEN_WENWU");  
	this:RegisterEvent("OBJECT_CARED_EVENT",false); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	 
end 

function ZhouNian12_Wenwu_OnLoad()
	g_ZhouNian12_Wenwu_Frame_UnifiedPosition	= ZhouNian12_Wenwu_Frame:GetProperty("UnifiedPosition"); 	 
end

function ZhouNian12_Wenwu_Frame_On_ResetPos()
  	ZhouNian12_Wenwu_Frame:SetProperty("UnifiedPosition", g_ZhouNian12_Wenwu_Frame_UnifiedPosition);
end

function ZhouNian12_Wenwu_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ZhouNian12_Wenwu_Close();
	end
  
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		ZhouNian12_Wenwu_Frame_On_ResetPos()
	end
		 
	--  
	if (event == "OPEN_WENWU") then 
		 ZhouNian12_Wenwu_OnInitial(); 
		 this:Show();
	end  
end 
----------------------------------------------------------------------------------
--
-- 关闭
--	
function ZhouNian12_Wenwu_Close()  
	this:Hide(); 
end 

function ZhouNian12_Wenwu_OnInitial()    
end