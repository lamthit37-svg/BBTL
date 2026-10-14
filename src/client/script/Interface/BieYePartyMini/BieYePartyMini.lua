--家宴界面Mini

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0 
local g_BieYePartyMini_Frame_UnifiedPosition; 
local g_BieYePartyMini_Frame_ItemIcon;
local g_BieYePartyMini_Item = -1; 
local g_BieYePartyMini_RemainTime = 10;  
local g_BieYePartyMini_TenTime = 10;  
local g_BieYePartyMini_TimeStatus = 1;  --1进行中 2 结束期
local g_BieYePartyMini_IsLastDuiShi = 0;
local g_BieYePartyMini_Round = 0; 
local g_BieYePartyMini_StatusStr = {
	[1] = "#{PZJY_160722_308}",
	[2] = "#{PZJY_160722_314}",
	[3] = "#{PZJY_160722_309}",
	[4] = "#{PZJY_160722_310}",
	[5] = "#{PZJY_160722_311}",
	[6] = "#{PZJY_160722_312}",
	[7] = "#{PZJY_160722_313}",
}
function BieYePartyMini_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND");  
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("OPEN_STALL_SALE"); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	 
	this:RegisterEvent("JIAYANMINITRANS") 	  
end 

function BieYePartyMini_OnLoad()
	g_BieYePartyMini_Frame_UnifiedPosition	=	BieYePartyMini_Frame:GetProperty("UnifiedPosition");  
end

function BieYePartyMini_Frame_On_ResetPos()
  BieYePartyMini_Frame:SetProperty("UnifiedPosition", g_BieYePartyMini_Frame_UnifiedPosition);
end

function BieYePartyMini_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		BieYePartyMini_OnHiden();
	end
	
	  -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		BieYePartyMini_Frame_On_ResetPos()
	end
	
	-- 开始摆摊
	if ( event == "OPEN_STALL_SALE" ) then
		if (this:IsVisible()) then
			BieYePartyMini_OnClosed();										-- 关闭“镶嵌预览”试衣间，重新激活“镶嵌预览”按钮
		end
	end 
	if ( event == "JIAYANMINITRANS" ) then 
		BieYePartyMini_OnInitial(); 
		BieYePartyMini_CountDown_Watch:SetProperty("Timer",tostring(arg0) );  
		BieYePartyMini_CountDown_Watch:Hide();
		g_BieYePartyMini_TimeStatus = tonumber(arg1);
		g_BieYePartyMini_IsLastDuiShi = tonumber(arg2); 
		g_BieYePartyMini_Round = tonumber(arg3);  
		BieYePartyMini_CountDown:SetText(g_BieYePartyMini_StatusStr[g_BieYePartyMini_TimeStatus])  
		if g_BieYePartyMini_TimeStatus == 1  then
			BieYePartyMini_CountDown_Watch:Hide();
		else
			BieYePartyMini_CountDown_Watch:Hide();
		end
		
		this:Show();
	end
		--服务器下发 
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016101001) then  
		g_BieYePartyMini_TimeStatus = 1; 
		g_BieYePartyMini_IsLastDuiShi = 0;  
		if g_BieYePartyMini_IsLastDuiShi == 1 then
			BieYePartyMini_CountDown:SetText("#{PZJY_160722_314}")
		else	
			BieYePartyMini_CountDown:SetText("#{PZJY_160722_308}")
		end
		BieYePartyMini_CountDown_Watch:SetProperty("Timer",tostring(g_BieYePartyMini_TenTime) );  
		BieYePartyMini_CountDown_Watch:Hide(); 
	end
	
	--服务器下发 
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016101002) then  
		g_BieYePartyMini_TimeStatus = 1; 
		g_BieYePartyMini_IsLastDuiShi = 0;  
		if g_BieYePartyMini_IsLastDuiShi == 1 then
			BieYePartyMini_CountDown:SetText("#{PZJY_160722_314}")
		else	
			BieYePartyMini_CountDown:SetText("#{PZJY_160722_308}")
		end
		g_BieYePartyMini_Round =  Get_XParam_INT(0);
		BieYePartyMini_CountDown_Watch:SetProperty("Timer",tostring(g_BieYePartyMini_RemainTime) );  
		BieYePartyMini_CountDown_Watch:Hide(); 
	end  
	
	--服务器下发 
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016101004) then    
		BieYePartyMini_OnHiden();
	end   
	
	--服务器下发 
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016101005) then    
		g_BieYePartyMini_TimeStatus = 2;
		g_BieYePartyMini_IsLastDuiShi = 1; 
			PushEvent("JIAYANMAXTRANS",20,g_BieYePartyMini_TimeStatus ,g_BieYePartyMini_IsLastDuiShi ); 
		BieYePartyMini_OnClosed(); 
	end  
	
	--最后一次对诗 设置状态
	if(event == "UI_COMMAND" and tonumber(arg0) == 20161011) then    
		BieYePartyMini_CountDown:SetText("#{PZJY_160722_314}")
		g_BieYePartyMini_IsLastDuiShi = 1;
	end 
	
	--设置状态 击鼓行酒令
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016120603) then     
		BieYePartyMini_CountDown:SetText("#{PZJY_160722_309}")
		local TimerRemain = Get_XParam_INT(0);
		g_BieYePartyMini_TimeStatus = 3;
		BieYePartyMini_CountDown_Watch:SetProperty("Timer",tostring(TimerRemain) );  
		BieYePartyMini_CountDown_Watch:Hide();
	end 
	
	--设置状态 等待行驶特权
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016120604) then      
	end 
	
	--设置状态 行驶特权
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016120605) then       
	end 
	
	--设置状态 等待美食出现
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016120606) then      
	end
	
	--设置状态 享受美食
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016120607) then     
		BieYePartyMini_CountDown:SetText("#{PZJY_160722_313}")
		local TimerRemain = Get_XParam_INT(0);
		g_BieYePartyMini_TimeStatus = 7;
		BieYePartyMini_CountDown_Watch:SetProperty("Timer",tostring(TimerRemain) );  
		BieYePartyMini_CountDown_Watch:Hide();
	end
	--设置状态 等待美食出现
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016121202) then  
		BieYePartyMini_OnHiden();    
	end
	
end

--*******************************************************************************
-- 注意！！！
-- OnHiden() 函数关闭界面的时候，不会再次激活“镶嵌预览”按钮
-- OnClosed() 函数关闭界面的时候，会再次激活“镶嵌预览”按钮
-- 这两个函数不能通用~~
--*******************************************************************************
----------------------------------------------------------------------------------
--
-- 隐藏
--
function BieYePartyMini_OnHiden() 
	--取消关心
	this:CareObject(objCared, 0, "BieYePartyMini");
	objCared = -1;
	BieYePartyMini_OnClear();
	this:Hide();
end

----------------------------------------------------------------------------------
--
-- 关闭
--
function BieYePartyMini_OnClosed()

	--取消关心
	this:CareObject(objCared, 0, "BieYePartyMini");
	objCared = -1;	
	BieYePartyMini_OnClear();	  
	this:Hide();

end 

function BieYePartyMini_OnClear()  
end
function BieYePartyMini_OnInitial() 
	g_BieYePartyMini_IsLastDuiShi = 0;
	BieYePartyMini_OnClear(); 
end
 

function BieYePartyMini_Cliecked()
	local RemainTime =  BieYePartyMini_CountDown_Watch:GetProperty("Timer"); 
	PushEvent("JIAYANMAXTRANS",RemainTime,g_BieYePartyMini_TimeStatus ,g_BieYePartyMini_IsLastDuiShi,g_BieYePartyMini_Round );
	BieYePartyMini_OnClosed();
end