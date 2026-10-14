--家宴界面MAX

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0 
local g_BieYeParty_Frame_UnifiedPosition; 
local g_BieYeParty_Frame_ItemIcon;
local g_BieYeParty_Item = -1; 
local g_BieYeParty_RemainTime = 10;
local g_BieYeParty_FirstRemainTime = 10;  
local g_BieYeParty_EndRemainTime = 20;  
local g_CurSelectIndex = 1;
local g_BieYeParty_TenTime =10;
local g_BieYePartyMini_TimeStatus = 1;  --1进行中 2 结束期 3 击鼓行酒令 4 等待行驶特权 5 行驶特权 6 等待美食出现 7 享受美食
local g_BieYePartyMini_IsLastDuiShi = 0;

local g_BieYeParty_Round  = 0;
local g_BieYeParty_DuiShiStatus = 0;

local g_BieYeParty_StatusStr = {
	[1] = "#{PZJY_160722_308}",
	[2] = "#{PZJY_160722_314}",
	[3] = "#{PZJY_160722_309}",
	[4] = "#{PZJY_160722_310}",
	[5] = "#{PZJY_160722_311}",
	[6] = "#{PZJY_160722_312}",
	[7] = "#{PZJY_160722_313}",
}

local g_BieYeParty_ImagenInfoStr = { 

	[1] = "#{PZJY_160722_345}",
	[2] = "#{PZJY_160722_228}",
	[3] = "#{PZJY_160722_346}",
	[4] = "#{PZJY_160722_228}",
	[5] = "#{PZJY_160722_228}",
	[6] = "#{PZJY_160722_228}",
	[7] = "#{PZJY_160722_347}",
}


function BieYeParty_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND");  
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("OPEN_STALL_SALE"); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	 
	this:RegisterEvent("JIAYANMAXTRANS") 	  
end 

function BieYeParty_OnLoad()
	g_BieYeParty_Frame_UnifiedPosition	=	BieYeParty_Frame:GetProperty("UnifiedPosition"); 
	--界面上显示奖励物品的ICON表  
end

function BieYeParty_Frame_On_ResetPos()
  BieYeParty_Frame:SetProperty("UnifiedPosition", g_BieYeParty_Frame_UnifiedPosition);
end

function BieYeParty_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		BieYeParty_OnHiden();
	end

	-- 开始摆摊
	if ( event == "OPEN_STALL_SALE" ) then
		if (this:IsVisible()) then
			BieYeParty_OnClosed();										-- 关闭“镶嵌预览”试衣间，重新激活“镶嵌预览”按钮
		end
	end
  
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		BieYeParty_Frame_On_ResetPos()
	end
	
 	--服务器下发  开启家宴
	if(event == "UI_COMMAND" and tonumber(arg0) == 20161009) then    
	end
	
	--服务器下发  10秒校正
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016101001) then    
	end
	
	--服务器下发  开始对诗
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016101002) then  
		BieYeParty_OnInitial();  
		
		g_BieYeParty_Round  =  Get_XParam_INT(0); 
		BieYeParty_Frame1_ImageInfo1:SetText(ScriptGlobal_Format("#{PZJY_160722_306}", g_BieYeParty_Round ))
		g_BieYePartyMini_TimeStatus = 1; 
		g_BieYePartyMini_IsLastDuiShi = 0;
		BieYeParty_OnClear();
		BieYeParty_CountDown:SetText("#{PZJY_160722_308}")
		BieYeParty_Frame1_ImageInfo2:SetText("#{PZJY_160722_345}")
		BieYeParty_CountDown_Watch:SetProperty("Timer",tostring(g_BieYeParty_RemainTime) );  
		BieYeParty_CountDown_Watch:Hide(); 
		BieYeParty_Frame1:Show();
		BieYeParty_Frame7:Hide();
		if g_BieYeParty_Round == 1 then
			this:Show();
		end
	end
	--服务器下发  获取Buff 下发界面
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016101003) then    
	end
	--关闭  关闭家宴 
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016101004) then   
		BieYeParty_OnHiden();
	end
	--结束期 结束期
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016101005) then    
		g_BieYePartyMini_TimeStatus = 2; 
		g_BieYePartyMini_IsLastDuiShi = 1; 
		BieYeParty_CountDown:SetText("#{PZJY_160722_314}")
		BieYeParty_Frame7_ImageInfo2:SetText("#{PZJY_160722_228}")
		BieYeParty_CountDown_Watch:SetProperty("Timer",tostring(g_BieYeParty_EndRemainTime) );
		BieYeParty_CountDown:Show(); 
		BieYeParty_CountDown_Watch:Hide(); 
		BieYeParty_Frame1:Hide();
		BieYeParty_Frame7:Show();
	end 
	--最后一次对诗 设置状态
	if(event == "UI_COMMAND" and tonumber(arg0) == 20161011) then     
	end
	
	--设置状态 击鼓行酒令
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016120603) then     
		BieYeParty_CountDown:SetText("#{PZJY_160722_309}") 
		BieYeParty_Frame1_ImageInfo2:SetText("#{PZJY_160722_346}")
		local TimerRemain = Get_XParam_INT(0);
		g_BieYePartyMini_TimeStatus = 3;
		BieYeParty_CountDown_Watch:SetProperty("Timer",tostring(TimerRemain) );  
		BieYeParty_CountDown_Watch:Hide();
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
		BieYeParty_CountDown:SetText("#{PZJY_160722_313}")
		BieYeParty_Frame1_ImageInfo2:SetText("#{PZJY_160722_347}")
		local TimerRemain = Get_XParam_INT(0);
		g_BieYePartyMini_TimeStatus = 7;
		BieYeParty_CountDown_Watch:SetProperty("Timer",tostring(TimerRemain) );  
		BieYeParty_CountDown_Watch:Hide();
	end
	  
	if ( event == "JIAYANMAXTRANS" ) then 
		BieYeParty_CountDown_Watch:SetProperty("Timer",tostring(arg0) );  
		BieYeParty_CountDown_Watch:Hide();
		g_BieYePartyMini_TimeStatus = tonumber(arg1);
		g_BieYeParty_Round = tonumber(arg3);
		BieYeParty_Frame1_ImageInfo1:SetText(ScriptGlobal_Format("#{PZJY_160722_306}", g_BieYeParty_Round )) 
		g_BieYePartyMini_IsLastDuiShi = tonumber(arg2); 
		if g_BieYePartyMini_IsLastDuiShi == 1 then
			BieYeParty_Frame7:Show(); 
			BieYeParty_Frame1:Hide(); 
		else
			BieYeParty_Frame1:Show(); 
			BieYeParty_Frame7:Hide(); 
		end
		BieYeParty_CountDown:SetText(g_BieYeParty_StatusStr[g_BieYePartyMini_TimeStatus])  
		if g_BieYePartyMini_TimeStatus == 1   then
			BieYeParty_CountDown_Watch:Hide();
		else
			BieYeParty_CountDown_Watch:Hide();
		end
		this:Show();
	end
	--阻挡传出时
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016121202) then  
		BieYeParty_OnHiden();  
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
function BieYeParty_OnHiden() 
	--取消关心
	this:CareObject(objCared, 0, "BieYeParty");
	objCared = -1;
	BieYeParty_OnClear();
	this:Hide();
end

----------------------------------------------------------------------------------
--
-- 关闭
--
function BieYeParty_OnClosed()

	--取消关心
	this:CareObject(objCared, 0, "BieYeParty");
	objCared = -1;	
	BieYeParty_OnClear();	  
	this:Hide();

end 

function BieYeParty_OnClear()  
	BieYeParty_Frame1:Hide();
	BieYeParty_Frame7:Hide();
	if g_BieYePartyMini_TimeStatus ~= 2 then
			BieYeParty_Frame1:Show(); 
	else
			BieYeParty_Frame7:Show(); 
	end   
end
function BieYeParty_OnInitial() 
	g_BieYeParty_Round = 0;
	BieYeParty_OnClear(); 
end
 

function BieYeParty_Frame_Mini_Clicked()
	local RemainTime =  BieYeParty_CountDown_Watch:GetProperty("Timer"); 
	PushEvent("JIAYANMINITRANS",RemainTime,g_BieYePartyMini_TimeStatus,g_BieYePartyMini_IsLastDuiShi,g_BieYeParty_Round ); 
	BieYeParty_OnClosed();
end
