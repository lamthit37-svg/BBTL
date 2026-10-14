local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local nCharCreateDate = -1;
local CreateDate = 904691712			-- 2013年08月22日08:00:00
local g_bIsNewServerGiftsForLevelUpValid =0;
local g_nCurSelectID;
local g_nContentButton = {}
local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},
											[6] = {x =0, y = 0, tipx =0, tipy =0},
											[7] = {x =0, y = 0, tipx =0, tipy =0},									
										}
 
 --===============================================
-- 充值超值赠
--===============================================
local g_Fuli_SuperSaveUp_LoadFirstTime = 1
local g_Fuli_SuperSaveUp_ScrollbarPosition = 0
--显示奖励物品配表
local g_KajiTable_SuperSaveUp_Gifts = {
	[0] = {
		[1] = 	{
			{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920977, num = 2,}
			,},
		[2] =	{
				{GiftItemID = 39921376, num = 1,},{GiftItemID = 39920977, num = 3,},{ GiftItemID = 39920181, num = 2,}		 
			,},
		[3] =   {
				{GiftItemID = 39920977, num = 4,},{GiftItemID = 39920181, num = 2,},{GiftItemID = 38005782, num = 1,}	 
			,},
		[4] = 	{
				{GiftItemID = 39920397, num = 1,},{GiftItemID = 39920396, num = 1,},{ GiftItemID = 39920383, num = 1,}
			,},
		[5] =	{
				{GiftItemID = 39920181, num = 2,},{GiftItemID = 38005789, num = 1,},{ GiftItemID = 38005785, num = 5,}		 
			,},
		[6] =   {
				{GiftItemID = 39921379, num = 1,},{GiftItemID = 38005786, num = 1,},{GiftItemID = 39920490, num = 5,}	 
			,},
		[7] = 	{
				{GiftItemID = 39920181, num = 3,},{GiftItemID = 38005787, num = 1,},{ GiftItemID = 38005785, num = 10,}
			,},
		[8] =	{
				{GiftItemID = 38005788, num = 1,},{GiftItemID = 38005789, num = 2,},{ GiftItemID = 38005786, num = 2,}	 
			,},
		[9] =   {
				{GiftItemID = 39920181, num = 4,},{GiftItemID = 38005787, num = 2,},{GiftItemID = 38005785, num = 20,}	 
			,},
		[10] =   {
				{GiftItemID = 39921380, num = 1,},{GiftItemID = 39921668, num = 1,},{GiftItemID = 39920981, num = 1,}	 
			,},
	},
	[1] = {
		[1] = 	{
			{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920977, num = 2,}
			,},
		[2] =	{
				{GiftItemID = 39921376, num = 1,},{GiftItemID = 39920977, num = 3,},{ GiftItemID = 39920181, num = 2,}		 
			,},
		[3] =   {
				{GiftItemID = 39920977, num = 4,},{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920267, num = 5,}	 
			,},
		[4] = 	{
				{GiftItemID = 39920397, num = 1,},{GiftItemID = 39920396, num = 1,},{ GiftItemID = 39920383, num = 1,}
			,},
		[5] =	{
				{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920490, num = 5,},{ GiftItemID = 39920329, num = 5,}		 
			,},
		[6] =   {
				{GiftItemID = 39921379, num = 1,},{GiftItemID = 39922089, num = 1,},{GiftItemID = 39920490, num = 5,}	 
			,},
		[7] = 	{
				{GiftItemID = 39920181, num = 3,},{GiftItemID = 39920089, num = 25,},{ GiftItemID = 39920329, num = 10,}
			,},
		[8] =	{
				{GiftItemID = 39920329, num = 15,},{GiftItemID = 39920383, num = 2,},{ GiftItemID = 39920334, num = 5,}	 
			,},
		[9] =   {
				{GiftItemID = 39920181, num = 4,},{GiftItemID = 39923526, num = 2,},{GiftItemID = 39920329, num = 20,}	 
			,},
		[10] =   {
				{GiftItemID = 39921380, num = 1,},{GiftItemID = 39923527, num = 1,} 
			,},
	}
}

local g_KajiTable_SuperSaveUp_Gifts_2606S = {
	--累充
	[1] = 	{
		{GiftItemID = 30008027, num = 2,},{GiftItemID = 30900077, num = 2,}
		,},
	[2] =	{
			{GiftItemID = 39921376, num = 1,},{GiftItemID = 30900077, num = 3,},{GiftItemID = 30008027, num = 2,}	  
		,},
	[3] =   {
			{GiftItemID = 30900077, num = 4,},{GiftItemID = 30008027, num = 2,},{GiftItemID = 38005782, num = 1,}
		,},
	[4] =   {
			{GiftItemID = 20502003, num = 1,},{GiftItemID = 20501003, num = 1,},{GiftItemID = 30008048, num = 1,}
		,},
	[5] =   {
			{GiftItemID = 30008027, num = 2,},{GiftItemID = 38008712, num = 1,},{GiftItemID = 38005785, num = 5,}
		,},
	[6] = 	{
			{GiftItemID = 38002176, num = 1,},{GiftItemID = 38005786, num = 1,},{GiftItemID = 38000992, num = 5,}
		,},
	[7] =	{
			{GiftItemID = 30008027, num = 3,},{GiftItemID = 38005786, num = 1,},{GiftItemID = 38005785, num = 10,}
		,},
	[8] =   {
			{GiftItemID = 38005788, num = 1,},{GiftItemID = 38008712, num = 2,},{GiftItemID = 38005786, num = 2,}
		,},
	[9] =   {
			{GiftItemID = 30008027, num = 4,},{GiftItemID = 38005786, num = 2,},{GiftItemID = 38005785, num = 20,}
		,},
	[10] =   {
			{GiftItemID = 10125108, num = 1,},{GiftItemID = 10141411, num = 1,},{GiftItemID = 38008711, num = 1,}
		,},
}
--Button
local g_Fuli_SuperSaveUp_Buttons = {
}
local g_Fuli_SuperSaveUp_ButtonState = {
	[1] =0,
	[2] =0,
	[3] =0,
	[4] =0,
	[5] =0,
	[6] =0,
	[7] =0,
	[8] =0,
	[9] =0,
	[10]=0,
};
local g_Fuli_SuperSaveUp_GetGiftsCondition =
{
	[1] = { Exch = 2000, Cost = 2000, },
	[2] = { Exch = 8000, Cost = 8000, },
	[3] = { Exch = 20000, Cost = 20000, },
	[4] = { Exch = 40000, Cost = 40000, },
	[5] = { Exch = 80000, Cost = 80000, },
	[6] = { Exch = 150000, Cost = 150000, },
	[7] = { Exch = 250000, Cost = 250000, },
	[8] = { Exch = 400000, Cost = 400000, },
	[9] = { Exch = 800000, Cost = 800000, },
	[10] ={ Exch = 2000000, Cost = 2000000, },
}
local g_Fuli_SuperSaveUp_Cost =0;
local g_Fuli_SuperSaveUp_Exch =0;
local g_Fuli_SuperSaveUp_ContentButton = {}
local g_Fuli_SuperSaveUp_CurrentSelect = 0;
--
--set:ZhizunHaoli","")
local g_Fuli_LimitedSaveUp_GiftsImage = {
	[1] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_1", },
	[2] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_2", },
	[3] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_3", },
	[4] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_4", },
	[5] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_5", },
	[6] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_6", },
	[7] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_7", },
	[8] = {Set ="ZhizunHaoli" , Image = "ZhizunHaoli_8", },
	[9] = {Set ="XSYNewBK02" , Image = "XSYNewBK_LeiChong_HLicon9", },
	[10] ={Set ="XSYNewBK02" , Image = "XSYNewBK_LeiChong_HLicon10", },
}

local g_bIsNewServerGiftsForLevelUpValid_2023 = 0

function Fuli_SuperSaveUp_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OPEN_FULI_SUPERSAVEUP",true)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI",true) 
end

function Fuli_SuperSaveUp_OnEvent(event) 
	if ( event == "REFRESH_ZHAHUI_DATA" ) then
		-- Fuli_SuperSaveUp_OnShown()
		-- Fuli_SuperSaveUp_Show()
	elseif event == "OPEN_FULI_SUPERSAVEUP" then
		 Fuli_SuperSaveUp_OnShown()
		 Fuli_SuperSaveUp_Show()
		 if(tonumber(arg0) == 0) then
			Fuli_SuperSaveUp_ResetPos()
		else 
			Fuli_SuperSaveUp_SetLastPos()
		end
		
	elseif( event == "ADJEST_UI_POS" ) then
		Fuli_SuperSaveUp_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Fuli_SuperSaveUp_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()	
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8889072 ) then
		nCharCreateDate = Get_XParam_INT( 8 );
		g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = 0
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 99847904 ) then
		nCharCreateDate = Get_XParam_INT( 0 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = Get_XParam_INT( 1 );
		g_bIsNewServerGiftsForLevelUpValid = 0
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 89269004 ) then
		if ( IsWindowShow( "Fuli_SuperSaveUp" ) == false ) then
			return
		end  
		Fuli_SuperSaveUp_UpdateInfo()
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 89269002 ) then
		if ( IsWindowShow( "Fuli_SuperSaveUp" ) == false ) then
			return
		end  
		Fuli_SuperSaveUp_UpdateInfo()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89269008 ) then
		local nButtonState = Get_XParam_INT(0)
		local nButtonTips	 = Get_XParam_INT(1)
		DataPool:Lua_SetUpdateTipsFlag(3,nButtonState)	-- Button状态
		DataPool:Lua_SetUpdateTipsFlag(4,nButtonTips)   --  Tips 状态
		PushEvent("BIN_PLAYER_UPDATE_UI", 1)
		if ( IsWindowShow( "Fuli_SuperSaveUp" ) == true ) then
			 Fuli_SuperSaveUp_Refresh_ButtonTips()
		end
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		Fuli_SuperSaveUp_Refresh_ButtonTips()	
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 99840102 ) then
		if 1==  Get_XParam_INT(0) then
			Fuli_SuperSaveUp_VIPBtn_Tips:Show()
		else
			Fuli_SuperSaveUp_VIPBtn_Tips:Hide()
		end
	end
end

function Fuli_SuperSaveUp_OnLoad()
  
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Fuli_SuperSaveUp_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Fuli_SuperSaveUp_Frame:GetProperty("UnifiedYPosition");

	g_ButtonPos[1].x	= Fuli_SuperSaveUp_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= Fuli_SuperSaveUp_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= Fuli_SuperSaveUp_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= Fuli_SuperSaveUp_Button3tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[2].x	= Fuli_SuperSaveUp_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= Fuli_SuperSaveUp_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= Fuli_SuperSaveUp_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= Fuli_SuperSaveUp_Button5tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[3].x	= Fuli_SuperSaveUp_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= Fuli_SuperSaveUp_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= Fuli_SuperSaveUp_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= Fuli_SuperSaveUp_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= Fuli_SuperSaveUp_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= Fuli_SuperSaveUp_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= Fuli_SuperSaveUp_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= Fuli_SuperSaveUp_Button8tips:GetProperty("UnifiedYPosition");	
	
	g_ButtonPos[5].x	= Fuli_SuperSaveUp_Button9:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= Fuli_SuperSaveUp_Button9:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= Fuli_SuperSaveUp_Button9tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= Fuli_SuperSaveUp_Button9tips:GetProperty("UnifiedYPosition");	

	g_ButtonPos[6].x	= Fuli_SuperSaveUp_Button10:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].y	= Fuli_SuperSaveUp_Button10:GetProperty("UnifiedYPosition");
	g_ButtonPos[6].tipx	= Fuli_SuperSaveUp_Button10tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].tipy	= Fuli_SuperSaveUp_Button10tips:GetProperty("UnifiedYPosition");


end 

function Fuli_SuperSaveUp_OnShown()

	local nShaoDang = 2
	local nOneDay = 3
	local nHuiGui = 4
	local nSuperSaveUp = 5
	local nZhanLing = 6


	-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1) then
		Fuli_SuperSaveUp_Button3 : Hide();
		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
		nHuiGui = nHuiGui-1
		nSuperSaveUp= nSuperSaveUp-1
		nZhanLing = nZhanLing -1
	else
		Fuli_SuperSaveUp_Button3 : Show();
	end
	

	local nLevel = Player:GetLevel();
	
	Fuli_SuperSaveUp_Button5:Show()
	if ( nLevel < 60 ) then
		Fuli_SuperSaveUp_Button5:Hide()
		nShaoDang = -1
		nOneDay = nOneDay-1
		nHuiGui = nHuiGui-1
		nSuperSaveUp= nSuperSaveUp-1
		nZhanLing = nZhanLing -1
	end
	
	nOneDay = -1
	if nOneDay == -1  then
		nHuiGui   = nHuiGui - 1
		nSuperSaveUp = nSuperSaveUp -1
		nZhanLing = nZhanLing -1
		Fuli_SuperSaveUp_Button7:Hide()
	end
	
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_SuperSaveUp_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_SuperSaveUp_Button8 : Hide()
		nHuiGui =-1;
		nSuperSaveUp= nSuperSaveUp-1
		nZhanLing = nZhanLing -1
	end
	
	if DataPool:Lua_GetUpdateTipsFlag( 3 ) == 1 then
		Fuli_SuperSaveUp_Button9 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 3 ) == 0 then
		Fuli_SuperSaveUp_Button9 : Hide()
		nSuperSaveUp =-1; 
		nZhanLing = nZhanLing -1
	end
	
	
	Fuli_SuperSaveUp_Button10:Show()
	if ( nLevel < 30 ) then
		Fuli_SuperSaveUp_Button10:Hide()
		nZhanLing = nZhanLing -1
	end
	



	if nShaoDang ~= -1 then
		Fuli_SuperSaveUp_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
		Fuli_SuperSaveUp_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
		Fuli_SuperSaveUp_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
		Fuli_SuperSaveUp_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);

	end

	if nOneDay ~= -1 then
		Fuli_SuperSaveUp_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		Fuli_SuperSaveUp_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		Fuli_SuperSaveUp_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		Fuli_SuperSaveUp_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);
	end

	if nHuiGui ~= -1 then
		Fuli_SuperSaveUp_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].x);
		Fuli_SuperSaveUp_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].y);
		Fuli_SuperSaveUp_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].tipx);
		Fuli_SuperSaveUp_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].tipy);
	end
	
	if nSuperSaveUp ~= -1 then
		Fuli_SuperSaveUp_Button9:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSaveUp].x);
		Fuli_SuperSaveUp_Button9:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSaveUp].y);
		Fuli_SuperSaveUp_Button9tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSaveUp].tipx);
		Fuli_SuperSaveUp_Button9tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSaveUp].tipy);
	end
		 
	if nZhanLing ~= -1 then
		Fuli_SuperSaveUp_Button10:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].x);
		Fuli_SuperSaveUp_Button10:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].y);
		Fuli_SuperSaveUp_Button10tips:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].tipx);
		Fuli_SuperSaveUp_Button10tips:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].tipy);
	end
	Fuli_SuperSaveUp_Refresh_ButtonTips()
	
	Fuli_SuperSaveUp_SetCheck() 
	
	this:Show();
end


 
--================================================
-- 界面的默认相对位置
--================================================
function Fuli_SuperSaveUp_ResetPos()
	Fuli_SuperSaveUp_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Fuli_SuperSaveUp_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
 

function Fuli_SuperSaveUp_OnHiden()
	this:Hide();
end

function Fuli_SuperSaveUp_Button1_Clicked()
	OpenMonthlySign(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_SuperSaveUp_Frame:GetProperty("UnifiedPosition"), 1) 
end

function Fuli_SuperSaveUp_Button2_Clicked()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end
	OpenStrongRoadDiaoWen(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_SuperSaveUp_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_SuperSaveUp_Button3_Clicked()
	OpenQianKunDai(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_SuperSaveUp_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_SuperSaveUp_Button4_Clicked()

end 
function Fuli_SuperSaveUp_Button5_Clicked()	
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end
	OpenZhaoHui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_SuperSaveUp_Frame:GetProperty("UnifiedPosition"), 1) 
end


function Fuli_SuperSaveUp_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end 
	Variable:SetVariable("SelfFuliUIPos", Fuli_SuperSaveUp_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_SuperSaveUp_Button8_Click()
	OpenHuiGui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_SuperSaveUp_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_SuperSaveUp_Button9_Click()
	
end

function Fuli_SuperSaveUp_Button10_Click()
	local nLevel = Player:GetLevel();
	if( nLevel < 30 ) then
		PushDebugMessage("#{TLZL_190802_03}")	
		return
	end
	OpenZhanLing(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_SuperSaveUp_Frame:GetProperty("UnifiedPosition"), 1)
end

-- 更新小红点
function Fuli_SuperSaveUp_Refresh_ButtonTips()

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_SuperSaveUp_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_SuperSaveUp_Button7tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		Fuli_SuperSaveUp_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_SuperSaveUp_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_SuperSaveUp_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_SuperSaveUp_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if nCharCreateDate ~= -1 and ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1)then
			DataPool:Lua_SetRedPointInUIShow(39, 0)
			Fuli_SuperSaveUp_Button3tips : Hide()
		else
			Fuli_SuperSaveUp_Button3tips : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_SuperSaveUp_Button3tips : Hide()
	end
	
	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		Fuli_SuperSaveUp_Button5tips : Show()
	else
		Fuli_SuperSaveUp_Button5tips : Hide()
	end

	
	
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_SuperSaveUp_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_SuperSaveUp_Button7tips : Hide()
	end
	
	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_SuperSaveUp_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_SuperSaveUp_Button8tips : Hide()
	end
	
	--福利累充
	if DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 then
		Fuli_SuperSaveUp_Button9tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 4 ) == 0 then
		Fuli_SuperSaveUp_Button9tips : Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 then
		Fuli_SuperSaveUp_Button10tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 5 ) == 0 then
		Fuli_SuperSaveUp_Button10tips : Hide()
	end
end

function Fuli_SuperSaveUp_OnClosed()
    this:Hide()
    return
end
 
function Fuli_SuperSaveUp_SetCheck()
		Fuli_SuperSaveUp_Button1:SetCheck(0)
		Fuli_SuperSaveUp_Button2:SetCheck(0)
		Fuli_SuperSaveUp_Button3:SetCheck(0)
		Fuli_SuperSaveUp_Button5:SetCheck(0)
		Fuli_SuperSaveUp_Button7:SetCheck(0)
		Fuli_SuperSaveUp_Button8:SetCheck(0) 
		Fuli_SuperSaveUp_Button9:SetCheck(1) 
end

function Fuli_SuperSaveUp_LoadData()
	
end
 

function Fuli_SuperSaveUp_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
	    Fuli_SuperSaveUp_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end


function Fuli_SuperSaveUp_LoadControl()
end

function Fuli_SuperSaveUp_Show()
	Fuli_SuperSaveUp_UpdateButtonReq();
end
function Fuli_SuperSaveUp_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetSuperSaveUpGiftsInfo" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892690 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function Fuli_SuperSaveUp_UpdateInfo()
	g_Fuli_SuperSaveUp_Exch  = Get_XParam_INT(0)
	g_Fuli_SuperSaveUp_Cost  = Get_XParam_INT(1)
	for i=1,table.getn(g_Fuli_SuperSaveUp_ButtonState) do
		g_Fuli_SuperSaveUp_ButtonState[i] = Get_XParam_INT(i+1)
	end
	g_Fuli_SuperSaveUp_ScrollbarPosition = Fuli_SuperSaveUp_Supe_MianList:GetVertScrollbarPosition()
	Fuli_SuperSaveUp_FlushWindow()
end
function Fuli_SuperSaveUp_FlushWindow()
	Fuli_SuperSaveUp_CleanActionItemInfo()
	Fuli_SuperSaveUp_Supe_MianList:CleanAllElement("Fuli_SuperSaveUp")
	local nCurIndex = 0
	local kajiType = KaJi:LuaFnGetKaJiType(10)
	local tableXinShouNew_SuperSaveUp_Gifts = g_KajiTable_SuperSaveUp_Gifts[kajiType]
	if Player:GetData("Is2606S") == 1 then
		tableXinShouNew_SuperSaveUp_Gifts = g_KajiTable_SuperSaveUp_Gifts_2606S
	end
	for i = 1,  table.getn(tableXinShouNew_SuperSaveUp_Gifts) do
		local ItemBar
		-- = Fuli_SuperSaveUp_Supe_MianList:AddItemElement( "SupeValueButton", "LEFT", "Fuli_SuperSaveUp","" ,"")
		if Fuli_SuperSaveUp_Normal ~= nil then	  			
			ItemBar = Fuli_SuperSaveUp_Supe_MianList:AddItemElement( "SupeValueFLButton", "LEFT", "Fuli_SuperSaveUp","" ,"")
		elseif Fuli_SuperSaveUp_Red ~= nil then			
		    ItemBar = Fuli_SuperSaveUp_Supe_MianList:AddItemElement( "SupeValueButtonSP", "LEFT", "Fuli_SuperSaveUp","" ,"")	
		elseif Fuli_SuperSaveUp_Summer ~= nil then			
		    ItemBar = Fuli_SuperSaveUp_Supe_MianList:AddItemElement( "SupeValueButtonSum", "LEFT", "Fuli_SuperSaveUp","" ,"")	
		end
			
		if ItemBar == nil then	 
			return
		end
		ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
		ItemBar:Setm_newImage(1,g_Fuli_LimitedSaveUp_GiftsImage[i].Set, g_Fuli_LimitedSaveUp_GiftsImage[i].Image)

		for j = 1,  table.getn(tableXinShouNew_SuperSaveUp_Gifts[i]) do
			local itemButton  = 	ItemBar:GetLuaActionButton(j,"Fuli_SuperSaveUp")
			local GiftItemID	=		tableXinShouNew_SuperSaveUp_Gifts[i][j].GiftItemID
			local GiftItemNum	= 	tableXinShouNew_SuperSaveUp_Gifts[i][j].num
			local theAction 	= 	DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
			if theAction:GetID() ~= 0 then
				itemButton:SetActionItem(theAction:GetID())
			end
		end

		if i == 1 then
			ItemBar:Setm_newImageHide(4)
		end
		--卡69级服第10档奖励只有2个
		if kajiType == 1 and i == 10 then
			ItemBar:Setm_newImageHide(4)
		end
		--未达成
		if g_Fuli_SuperSaveUp_ButtonState[i] == 0 then
			--ItemBar:SetButton1Text("#{XSJNH_180111_75}")
			if g_Fuli_SuperSaveUp_Exch < g_Fuli_SuperSaveUp_GetGiftsCondition[i].Exch then
				local Text1 = ScriptGlobal_Format("#{XSJNH_180111_71}", g_Fuli_SuperSaveUp_Exch,g_Fuli_SuperSaveUp_GetGiftsCondition[i].Exch)
				ItemBar:Setm_newText(1,Text1)
			else
				local Text1 = ScriptGlobal_Format("#{XSJNH_180111_73}", g_Fuli_SuperSaveUp_GetGiftsCondition[i].Exch,g_Fuli_SuperSaveUp_GetGiftsCondition[i].Exch)
				ItemBar:Setm_newText(1,Text1)
			end
			if g_Fuli_SuperSaveUp_Cost < g_Fuli_SuperSaveUp_GetGiftsCondition[i].Cost then
				local Text2 = ScriptGlobal_Format("#{XSJNH_180111_72}", g_Fuli_SuperSaveUp_Cost,g_Fuli_SuperSaveUp_GetGiftsCondition[i].Cost)
				ItemBar:Setm_newText(2,Text2)
			else
				local Text2 = ScriptGlobal_Format("#{XSJNH_180111_74}", g_Fuli_SuperSaveUp_GetGiftsCondition[i].Cost,g_Fuli_SuperSaveUp_GetGiftsCondition[i].Cost)
				ItemBar:Setm_newText(2,Text2)
			end
			ItemBar:Setm_newImage(7,"CommonFrame34", "SignSummerButton_Weidacheng")
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImageShow(7)
		--可以领取
		elseif g_Fuli_SuperSaveUp_ButtonState[i] == 1 then
			--ItemBar:SetButton1Text("#{XSJNH_180111_79}")
			local Text1 = ScriptGlobal_Format("#{XSJNH_180111_73}", g_Fuli_SuperSaveUp_GetGiftsCondition[i].Exch,g_Fuli_SuperSaveUp_GetGiftsCondition[i].Exch)
			ItemBar:Setm_newText(1,Text1)
			local Text2 = ScriptGlobal_Format("#{XSJNH_180111_74}", g_Fuli_SuperSaveUp_GetGiftsCondition[i].Cost,g_Fuli_SuperSaveUp_GetGiftsCondition[i].Cost)
			ItemBar:Setm_newText(2,Text2)
			--ItemBar:SetButton1Show()
			ItemBar:Setm_newImageHide(7)
			--已经领取
			if nCurIndex == 0 then
				nCurIndex = i
			end
		elseif g_Fuli_SuperSaveUp_ButtonState[i] == 2 then
			local Text1 = ScriptGlobal_Format("#{XSJNH_180111_73}", g_Fuli_SuperSaveUp_GetGiftsCondition[i].Exch,g_Fuli_SuperSaveUp_GetGiftsCondition[i].Exch)
			ItemBar:Setm_newText(1,Text1)
			local Text2 = ScriptGlobal_Format("#{XSJNH_180111_74}", g_Fuli_SuperSaveUp_GetGiftsCondition[i].Cost,g_Fuli_SuperSaveUp_GetGiftsCondition[i].Cost)
			ItemBar:Setm_newText(2,Text2)
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImage(7,"CommonFrame34", "SignSummerButton_Yilingqu")
			ItemBar:Setm_newImageShow(7)
		end
		table.insert(g_Fuli_SuperSaveUp_ContentButton, ItemBar)
	end

	if nCurIndex ~= 0 and g_Fuli_SuperSaveUp_LoadFirstTime == 1 then
		g_Fuli_SuperSaveUp_LoadFirstTime = 0;
		g_Fuli_SuperSaveUp_CurrentSelect = nCurIndex
		Fuli_SuperSaveUp_SetButtonSelected(nCurIndex)
		Fuli_SuperSaveUp_Supe_MianList:Flash()
		local curPos = Fuli_SuperSaveUp_CalcListScrollPos(g_Fuli_SuperSaveUp_CurrentSelect)
		Fuli_SuperSaveUp_Supe_MianList:SetVertScrollbarPosition(curPos)
	else
		Fuli_SuperSaveUp_Supe_MianList:Flash()
		Fuli_SuperSaveUp_Supe_MianList:SetVertScrollbarPosition(g_Fuli_SuperSaveUp_ScrollbarPosition)
	end
	--新服特权商店
	if 1 == DataPool:Lua_XFTQShopIsOpen() then
		Fuli_SuperSaveUp_VIPBtn:Show()
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AskShowShopBtnRedPoint" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998401 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 0 );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
		Send_XSCRIPT()
	else
		Fuli_SuperSaveUp_VIPBtn:Hide()
		Fuli_SuperSaveUp_VIPBtn_Tips:Hide()
	end
	--新服特权卡
	if 1==DataPool:Lua_TeQuanKaIsOpen()   then
		Fuli_SuperSaveUp_Supe_ChaKan_Image:Show()
		local timel,timeh = Lua_GetTeQuanKaTime("jingtong")
		if timeh and timel then
			if  timeh > 0  then
				--激活高级
				Fuli_SuperSaveUp_Supe_ChaKan_Image:SetProperty("Image","set:Xinfu_Tequan image:zunxiang")
				
				local leftdays = math.floor( timeh/1440 )
				if leftdays > 0 then
					Fuli_SuperSaveUp_Supe_ChaKan_Image:SetToolTip( ScriptGlobal_Format("#{XFTQ_230203_91}",leftdays) )
				else
					Fuli_SuperSaveUp_Supe_ChaKan_Image:SetToolTip("#{XFTQ_230203_92}")
				end
			elseif  timel > 0 then
				--激活普通
				Fuli_SuperSaveUp_Supe_ChaKan_Image:SetProperty("Image","set:Xinfu_Tequan image:youxiang")
				local leftdays = math.floor( timel/1440 )
				if leftdays > 0 then
					Fuli_SuperSaveUp_Supe_ChaKan_Image:SetToolTip( ScriptGlobal_Format("#{XFTQ_230203_89}",leftdays) )
				else
					Fuli_SuperSaveUp_Supe_ChaKan_Image:SetToolTip("#{XFTQ_230203_90}")
				end
			else
				Fuli_SuperSaveUp_Supe_ChaKan_Image:SetProperty("Image","set:Xinfu_Tequan image:weijihuo")
				Fuli_SuperSaveUp_Supe_ChaKan_Image:SetToolTip("#{XFTQ_230203_93}")
			end
		end
	else
		Fuli_SuperSaveUp_Supe_ChaKan_Image:Hide()
	end


	
end
function Fuli_SuperSaveUp_CleanActionItemInfo()
	local nListCount = table.getn(g_Fuli_SuperSaveUp_ContentButton)
	if nListCount <= 0 then
		g_Fuli_SuperSaveUp_ContentButton = {}
		return
	end
	for i = 1, nListCount do
		if nil ~= g_Fuli_SuperSaveUp_ContentButton[i] then
			for j = 1, 3 do
				local itemButton = g_Fuli_SuperSaveUp_ContentButton[i]:GetLuaActionButton(j,"Fuli_SuperSaveUp")
				if nil ~= itemButton then
					itemButton:SetActionItem(-1)
				end
			end
		end
	end
	g_Fuli_SuperSaveUp_ContentButton = {}
end
function Fuli_SuperSaveUp_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		Fuli_SuperSaveUp_SetButtonSelected(nIndex + 1)
		Fuli_SuperSaveUp_Supe_MianList:Flash()
		g_Fuli_SuperSaveUp_CurrentSelect = nIndex
	end

end

function Fuli_SuperSaveUp_OnButton1Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if nIndex >= 0 then
		Fuli_SuperSaveUp_SetButtonSelected(nIndex + 1)
		Fuli_SuperSaveUp_Supe_MianList:Flash()
		g_Fuli_SuperSaveUp_CurrentSelect = nIndex+1
		Fuli_SuperSaveUp_GetGiftsForCostYuanBao(g_Fuli_SuperSaveUp_CurrentSelect)
	end
end
function Fuli_SuperSaveUp_GetGiftsForCostYuanBao( Index )
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForSuperSaveUp" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892690 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, Index );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
end
function Fuli_SuperSaveUp_SetButtonSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_Fuli_SuperSaveUp_ContentButton) do
		if nil ~= g_Fuli_SuperSaveUp_ContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_Fuli_SuperSaveUp_ContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_Fuli_SuperSaveUp_ContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

function Fuli_SuperSaveUp_CalcListScrollPos(SelectIdx)
	if	SelectIdx <= 2 then
		return 0
	elseif SelectIdx == 3 then
		return 64
	elseif SelectIdx == 4 then
		return 128
	elseif SelectIdx == 5 then
		return 192
	elseif SelectIdx >= 6 then
		return 270
	end
end
--===============================================
-- 充值超值赠 -end
--===============================================


function Fuli_SuperSaveUp_TeQuanShop_Clicked()
	if 1 ~= DataPool:Lua_XFTQShopIsOpen() then
		PushDebugMessage("#{TQSD_230201_01}")
		return
	end
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenShop" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998401 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );				-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()
end