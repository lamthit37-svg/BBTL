
--家宴界面

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0 
local g_BieYeParty_KingGame_Frame_UnifiedPosition; 
local g_BieYeParty_KingGame_Frame_ItemIcon;
local g_BieYeParty_KingGame_Item = -1; 
 
local g_BieYeParty_KingGame_WanFaIndex = 0; 
local g_BieYeParty_KingGame_RemainTime = 15;

local g_BieYeParty_KingGame_ShowClinet_Button = 
{ 
} 

function BieYeParty_KingGame_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND");  
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("OPEN_STALL_SALE"); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	
	this:RegisterEvent("BIEYE_UPDATE_JIAYAN_USER") 	
	 
end 

function BieYeParty_KingGame_OnLoad()
	g_BieYeParty_KingGame_Frame_UnifiedPosition	=BieYeParty_KingGame_Frame:GetProperty("UnifiedPosition"); 
	
	g_BieYeParty_KingGame_ShowClinet_Button[1] = BieYeParty_KingGame_ShowClinet1_PRE_Button
	g_BieYeParty_KingGame_ShowClinet_Button[2] = BieYeParty_KingGame_ShowClinet2_PRE_Button
	g_BieYeParty_KingGame_ShowClinet_Button[3] = BieYeParty_KingGame_ShowClinet3_PRE_Button
	g_BieYeParty_KingGame_ShowClinet_Button[4] = BieYeParty_KingGame_ShowClinet4_PRE_Button
	g_BieYeParty_KingGame_ShowClinet_Button[5] = BieYeParty_KingGame_ShowClinet5_PRE_Button
	g_BieYeParty_KingGame_ShowClinet_Button[6] = BieYeParty_KingGame_ShowClinet6_PRE_Button
	
end

function BieYeParty_KingGame_Frame_On_ResetPos()
  BieYeParty_KingGame_Frame:SetProperty("UnifiedPosition", g_BieYeParty_KingGame_Frame_UnifiedPosition);
end

function BieYeParty_KingGame_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		BieYeParty_KingGame_OnHiden();
	end

	-- 开始摆摊
	if ( event == "OPEN_STALL_SALE" ) then
		if (this:IsVisible()) then
			BieYeParty_KingGame_OnClosed();										-- 关闭“镶嵌预览”试衣间，重新激活“镶嵌预览”按钮
		end
	end
  
  -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		BieYeParty_KingGame_Frame_On_ResetPos()
	end
		
 	--服务器下发可以打卡 去请求数据
	if(event == "UI_COMMAND" and tonumber(arg0) == 20160803) then  
		--BieYeParty_KingGame_OnAskData(); 
		BieYeParty_KingGame_OnInitial(); 
		this:Show();
	end
	
	if(event == "UI_COMMAND" and tonumber(arg0) == 20160808) then  
		BieYeParty_KingGame_OnHiden();
	end
	 
	if (event == "BIEYE_UPDATE_JIAYAN_USER") then
		 --BieYeParty_KingGame_OnInitial(); 
		 --this:Show();
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
function BieYeParty_KingGame_OnHiden() 
	--取消关心
	this:CareObject(objCared, 0, "BieYeParty_KingGame");
	objCared = -1;
	BieYeParty_KingGame_OnClear();
	this:Hide();
end

----------------------------------------------------------------------------------
--
-- 关闭
--
function BieYeParty_KingGame_OnClosed()

	--取消关心
	this:CareObject(objCared, 0, "BieYeParty_KingGame");
	objCared = -1;	
	BieYeParty_KingGame_OnClear();	  
	this:Hide();

end

function BieYeParty_KingGame_OnClear() 
	for i = 1, 6 do
		g_BieYeParty_KingGame_ShowClinet_Button[i]:SetCheck(0);
	end 
	g_BieYeParty_KingGame_WanFaIndex = 0;
end
function BieYeParty_KingGame_OnInitial() 
	BieYeParty_Game_CountDown_Watch:SetProperty("Timer",tostring(g_BieYeParty_KingGame_RemainTime) ); 
	BieYeParty_KingGame_OnClear();
	  
end
 

function BieYeParty_KingGame_ClickOK() 
	if g_BieYeParty_KingGame_WanFaIndex == 0 then
		return;
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSignleAction")
		Set_XSCRIPT_ScriptID(891951)
		Set_XSCRIPT_Parameter(0, g_BieYeParty_KingGame_WanFaIndex) 
		Set_XSCRIPT_ParamCount(1)		
	Send_XSCRIPT()	
end

function BieYeParty_KingGame_StartDoActionSingle()
	if g_BieYeParty_KingGame_SingleSelectIndex == -1 then
		PushDebugMessage("#{PZJY_160722_203}")
		return;
	end 
	local UserName,UserGuid = BieYeUI:GetBieYeJiaYanUserInfo( g_BieYeParty_KingGame_SingleSelectIndex ) 
	local GuidH,GuidL = SplitGUID64(UserGuid) 
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSignleAction")
		Set_XSCRIPT_ScriptID(891951)
		Set_XSCRIPT_Parameter(0, GuidH)
		Set_XSCRIPT_Parameter(1, GuidL)	 
		Set_XSCRIPT_ParamCount(2)		
	Send_XSCRIPT()	
		
end
 
function BieYeParty_KingGame_ShowClient_Click( index )
	g_BieYeParty_KingGame_WanFaIndex = index;
	for i = 1, 6 do
		g_BieYeParty_KingGame_ShowClinet_Button[i]:SetCheck(0);
	end 
	g_BieYeParty_KingGame_ShowClinet_Button[index]:SetCheck(1);
end