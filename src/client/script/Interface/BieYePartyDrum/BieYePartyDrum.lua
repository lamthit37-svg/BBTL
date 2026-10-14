
--家宴行酒令界面

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0 
local g_BieYePartyDrum_Frame_UnifiedPosition; 
local g_BieYePartyDrum_Frame_ItemIcon; 
local g_ButtonLastTime = 0;
local g_ButtonCDTime = 0.2
local g_ButtonDrumCount = 0;
local g_BieYePartyDrum_FirstRemainTime = 5
local g_DrumImage = {}
function BieYePartyDrum_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND");  
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("OPEN_STALL_SALE"); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	 
end 

function BieYePartyDrum_OnLoad()
	g_BieYePartyDrum_Frame_UnifiedPosition	=BieYePartyDrum_Frame:GetProperty("UnifiedPosition"); 
	g_DrumImage[1] = "set:Sign image:Signorange_0";
	g_DrumImage[2] = "set:Sign image:Signorange_1";
	g_DrumImage[3] = "set:Sign image:Signorange_2";
	g_DrumImage[4] = "set:Sign image:Signorange_3";
	g_DrumImage[5] = "set:Sign image:Signorange_4";
	g_DrumImage[6] = "set:Sign image:Signorange_5";
	g_DrumImage[7] = "set:Sign image:Signorange_6";
	g_DrumImage[8] = "set:Sign image:Signorange_7";
	g_DrumImage[9] = "set:Sign image:Signorange_8";
	g_DrumImage[10] = "set:Sign image:Signorange_9";
	 
end

function BieYePartyDrum_Frame_On_ResetPos()
  BieYePartyDrum_Frame:SetProperty("UnifiedPosition", g_BieYePartyDrum_Frame_UnifiedPosition);
end

function BieYePartyDrum_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		BieYePartyDrum_OnHiden();
	end

	-- 开始摆摊
	if ( event == "OPEN_STALL_SALE" ) then
		if (this:IsVisible()) then
			BieYePartyDrum_OnClosed();										-- 关闭“镶嵌预览”试衣间，重新激活“镶嵌预览”按钮
		end
	end
  
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		BieYePartyDrum_Frame_On_ResetPos()
	end
		 
	--  
	if (event == "BIEYE_UPDATE_JIAYAN_USER") then
		 BieYePartyDrum_OnInitial(); 
		 this:Show();
	end 
	--显示界面
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016112401) then  
		BieYePartyDrum_OnInitial(); 
		
		BieYePartyDrum_Times_Begin:SetProperty("Animate", "BieYeParty_CountDown")
		BieYePartyDrum_Times_Begin:Show();
		BieYePartyDrum_Times_Push:Hide();
		BieYePartyDrum_Times_Victory:Hide();
		BieYePartyDrum_Times_Failure:Hide();
		SetTimer( "BieYePartyDrum", "BieYePartyDrumTimer()", 3000 )
		BieYePartyDrum_Times_picture1:SetProperty("Image", "set:Sign image:Signorange_0")
		BieYePartyDrum_Times_picture2:SetProperty("Image", "set:Sign image:Signorange_0")	
		BieYePartyDrum_State:SetText("#{PZJY_160722_294}")
		BieYePartyDrum_State:Show();
		BieYePartyDrum_Drum:Disable();
		BieYePartyDrum_Explain_Text:SetText("#{PZJY_160722_261}")
		BieYePartyDrum_CountDown:Hide(); 
		this:Show();
		
	end
	--关闭界面
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016111501) then  
		BieYePartyDrum_OnHiden();
	end
	
	--击鼓结束
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016112901) then  
		 BieYePartyDrum_CountDown_Watch:SetProperty("Timer",tostring(0) );  
		 BieYePartyDrum_Drum:Disable();
		 BieYePartyDrum_CountDown:Hide(); 
		 BieYePartyDrum_State:SetText("#{PZJY_160722_295}")
		 BieYePartyDrum_State:Show();
		 BieYePartyDrum_Times_Push:Hide();
	end
	
	--击鼓失败
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016120601) then   
		 VictoryCount = Get_XParam_INT(0);
		 VictoryName  = Get_XParam_STR(0); 
		 BieYePartyDrum_Explain_Text:SetText(ScriptGlobal_Format("#{PZJY_160722_297}", VictoryName , VictoryCount)); 
		 BieYePartyDrum_Times_Victory:Hide();
		 BieYePartyDrum_Times_Failure:Show();
	end
	--击鼓成功
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016120602) then    
		 BieYePartyDrum_Explain_Text:SetText("#{PZJY_160722_298}"); 
		 BieYePartyDrum_Times_Failure:Hide();
		 BieYePartyDrum_Times_Victory:Show();
	end	
	--无人击鼓
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016121201) then    
		 BieYePartyDrum_Explain_Text:SetText("#{PZJY_160722_327}");  
		 BieYePartyDrum_CountDown:Hide(); 
		 BieYePartyDrum_State:SetText("#{PZJY_160722_295}")
		 BieYePartyDrum_State:Show();
		 BieYePartyDrum_Times_Failure:Show();
		 BieYePartyDrum_Times_Victory:Hide();
		 BieYePartyDrum_Drum:Disable();
		 BieYePartyDrum_Times_Push:Hide();
	end	
	--下发关闭 阻挡传出时
	if(event == "UI_COMMAND" and tonumber(arg0) == 2016121202) then    
		 BieYePartyDrum_OnHiden();
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
function BieYePartyDrum_OnHiden() 
	--取消关心
	this:CareObject(objCared, 0, "BieYePartyDrum");
	objCared = -1;
	BieYePartyDrum_OnClear();
	this:Hide();
end

----------------------------------------------------------------------------------
--
-- 关闭
--
function BieYePartyDrum_OnClosed()

	--取消关心
	this:CareObject(objCared, 0, "BieYePartyDrum");
	objCared = -1;	
	BieYePartyDrum_OnClear();	  
	this:Hide();

end

function BieYePartyDrum_OnClear() 
	g_ButtonDrumCount = 0; 
	BieYePartyDrum_Times_Text:SetText(ScriptGlobal_Format("#{PZJY_160722_262}", g_ButtonDrumCount)) 
end

function BieYePartyDrum_OnInitial() 
	BieYePartyDrum_CountDown_Watch:SetProperty("Timer",tostring(g_BieYePartyDrum_FirstRemainTime) ); 
	BieYePartyDrum_CountDown_Watch:Show()
	BieYePartyDrum_OnClear(); 
end 

function BieYePartyDrum_ClickCancel()
	BieYePartyDrum_OnHiden();
end

function BieYePartyDrum_Drum_Click() 
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then 
   	--PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
		return
	end
	g_ButtonLastTime = curTime;
	g_ButtonDrumCount = g_ButtonDrumCount + 1; 
	--BieYePartyDrum_Times_Text:SetText(ScriptGlobal_Format("#{PZJY_160722_262}", g_ButtonDrumCount)) 
	
	local DrumTenCount = math.floor(g_ButtonDrumCount/10)
	local DrumModCount = math.mod(g_ButtonDrumCount, 10) 
	BieYePartyDrum_Times_picture1:SetProperty("Image", g_DrumImage[DrumTenCount+1])
	BieYePartyDrum_Times_picture2:SetProperty("Image", g_DrumImage[DrumModCount+1])
	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoJiaYanDrum")
		Set_XSCRIPT_ScriptID(891951)   
		Set_XSCRIPT_ParamCount(0)		
	Send_XSCRIPT()	 
end

function BieYePartyDrumTimer()
	KillTimer("BieYePartyDrumTimer()")
	BieYePartyDrum_Times_Begin:Hide();
	BieYePartyDrum_Times_Push:Show();
	BieYePartyDrum_Times_Victory:Hide();
	BieYePartyDrum_Times_Failure:Hide();
	BieYePartyDrum_Drum:Enable();
	BieYePartyDrum_Times_picture1:SetProperty("Image", "set:Sign image:Signorange_0")
	BieYePartyDrum_Times_picture2:SetProperty("Image", "set:Sign image:Signorange_0")
	BieYePartyDrum_State:SetText("#{PZJY_160722_263}")
	BieYePartyDrum_State:Hide();
	BieYePartyDrum_CountDown_Watch:SetProperty("Timer",tostring(g_BieYePartyDrum_FirstRemainTime) ); 
	BieYePartyDrum_CountDown:Show()
	BieYePartyDrum_CountDown_Watch:Show()
	BieYePartyDrum_Explain_Text:SetText("#{PZJY_160722_261}"); 
end