local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local nCharCreateDate = -1;
local CreateDate = 904691712			-- 2013年08月22日08:00:00
local g_bIsNewServerGiftsForLevelUpValid =0;
local g_bIsNewServerGiftsForLevelUpValid_2023 = 0
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
   
function Fuli_ZhaoHui_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OPEN_ZHAOHUI",true)
	this:RegisterEvent("REFRESH_ZHAHUI_DATA",true)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI",true)
end

function Fuli_ZhaoHui_OnEvent(event) 
	if ( event == "REFRESH_ZHAHUI_DATA" ) then
		 Fuli_ZhaoHui_OnShown()
		 Fuli_ZhaoHui_LoadData()
	elseif event == "OPEN_ZHAOHUI" then
		 Fuli_ZhaoHui_RequstOpenZhaoHui()
		 if(tonumber(arg0) == 0) then
			Fuli_ZhaoHui_ResetPos()
		else 
			Fuli_ZhaoHui_SetLastPos()
		end
		
	elseif( event == "ADJEST_UI_POS" ) then
		Fuli_ZhaoHui_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Fuli_ZhaoHui_ResetPos()
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
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 2017121602 ) then 
		this:Hide();
	elseif event == "UPDATE_REDPOINT_IN_UI" then 
		Fuli_ZhaoHui_Refresh_ButtonTips() 
--	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 2018012201 ) then 
--	 
--		local IsSpring = Get_XParam_INT(0)
--		local IsDiff   = 0;
--		if IsSpring ~= DataPool:Lua_GetIsInSpringFlag() then
--			IsDiff =1;
--		end
--		DataPool:Lua_SetIsInSpringFlag( IsSpring )
--		if IsDiff == 1 then
--			OpenZhaoHui(1)
--		end
	end
end

function Fuli_ZhaoHui_OnLoad()
  
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Fuli_ZhaoHui_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Fuli_ZhaoHui_Frame:GetProperty("UnifiedYPosition");

	g_ButtonPos[1].x	= Fuli_ZhaoHui_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= Fuli_ZhaoHui_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= Fuli_ZhaoHui_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= Fuli_ZhaoHui_Button3tips:GetProperty("UnifiedYPosition");



	g_ButtonPos[2].x	= Fuli_ZhaoHui_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= Fuli_ZhaoHui_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= Fuli_ZhaoHui_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= Fuli_ZhaoHui_Button5tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[3].x	= Fuli_ZhaoHui_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= Fuli_ZhaoHui_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= Fuli_ZhaoHui_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= Fuli_ZhaoHui_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= Fuli_ZhaoHui_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= Fuli_ZhaoHui_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= Fuli_ZhaoHui_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= Fuli_ZhaoHui_Button8tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[5].x	= Fuli_ZhaoHui_Button9:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= Fuli_ZhaoHui_Button9:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= Fuli_ZhaoHui_Button9tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= Fuli_ZhaoHui_Button9tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[6].x	= Fuli_ZhaoHui_Button10:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].y	= Fuli_ZhaoHui_Button10:GetProperty("UnifiedYPosition");
	g_ButtonPos[6].tipx	= Fuli_ZhaoHui_Button10tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].tipy	= Fuli_ZhaoHui_Button10tips:GetProperty("UnifiedYPosition");

end 

function Fuli_ZhaoHui_OnShown()

	local nShaoDang = 2
	local nOneDay = 3
	local nHuiGui = 4 
	local nSuperSave		= 5
	local nZhanLing = 6

	-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1) then
		Fuli_ZhaoHui_Button3 : Hide();

		nShaoDang = nShaoDang-1
		nOneDay = nOneDay-1
		nHuiGui = nHuiGui-1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
	else
		Fuli_ZhaoHui_Button3 : Show();
	end
	

	local nLevel = Player:GetLevel();
	
	Fuli_ZhaoHui_Button5:Show()
	--if ( nLevel < 60 ) then
	--	Fuli_ZhaoHui_Button5:Hide()
	--	nShaoDang = -1
	--	nOneDay = nOneDay-1
	--	nHuiGui = nHuiGui-1
	--end

	nOneDay = -1
	if nOneDay == -1  then
		nHuiGui   = nHuiGui - 1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
		Fuli_ZhaoHui_Button7:Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_ZhaoHui_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_ZhaoHui_Button8 : Hide()
		nHuiGui = -1
		nSuperSave = nSuperSave -1
		nZhanLing = nZhanLing -1
	end
	
	
	  if DataPool:Lua_GetUpdateTipsFlag( 3 ) == 1 then
	  	Fuli_ZhaoHui_Button9 : Show()
	  elseif DataPool:Lua_GetUpdateTipsFlag( 3 ) == 0 then
	  	Fuli_ZhaoHui_Button9 : Hide()
		  nSuperSave =-1; 
		  nZhanLing = nZhanLing -1
	  end

	  Fuli_ZhaoHui_Button10:Show()
		if ( nLevel < 30 ) then
			Fuli_ZhaoHui_Button10:Hide()
			nZhanLing = nZhanLing -1
		end
	    



	if nShaoDang ~= -1 then
		Fuli_ZhaoHui_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
		Fuli_ZhaoHui_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
		Fuli_ZhaoHui_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
		Fuli_ZhaoHui_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);

	end

	if nOneDay ~= -1 then
		Fuli_ZhaoHui_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
		Fuli_ZhaoHui_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
		Fuli_ZhaoHui_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
		Fuli_ZhaoHui_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);
	end

	if nHuiGui ~= -1 then
		Fuli_ZhaoHui_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].x);
		Fuli_ZhaoHui_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].y);
		Fuli_ZhaoHui_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].tipx);
		Fuli_ZhaoHui_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].tipy);
	end
	
	
	if nSuperSave ~= -1 then
		Fuli_ZhaoHui_Button9:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].x);
		Fuli_ZhaoHui_Button9:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].y);
		Fuli_ZhaoHui_Button9tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].tipx);
		Fuli_ZhaoHui_Button9tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].tipy);
	end
		 
	if nZhanLing ~= -1 then
		Fuli_ZhaoHui_Button10:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].x);
		Fuli_ZhaoHui_Button10:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].y);
		Fuli_ZhaoHui_Button10tips:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].tipx);
		Fuli_ZhaoHui_Button10tips:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].tipy);
	end
		 	 
	Fuli_ZhaoHui_Refresh_ButtonTips()
	
	Fuli_ZhaoHui_SetCheck() 
	
	if Player:GetData("Is2606S") == 1 then
		Fuli_ZhaoHui_Frame_ExplainText:SetText("#{QXF_260623_165}")
	else
		Fuli_ZhaoHui_Frame_ExplainText:SetText("#{XTZY_171213_03}")
	end
	this:Show();
end


 
--================================================
-- 界面的默认相对位置
--================================================
function Fuli_ZhaoHui_ResetPos()
	Fuli_ZhaoHui_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Fuli_ZhaoHui_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
 

function Fuli_ZhaoHui_OnHiden()
	this:Hide();
end

function Fuli_ZhaoHui_Button1_Click()
	OpenMonthlySign(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhaoHui_Frame:GetProperty("UnifiedPosition"), 1) 
end

function Fuli_ZhaoHui_Button2_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{FLRK_160608_10}")
		return
	end
	OpenStrongRoadDiaoWen(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhaoHui_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhaoHui_Button3_Click()
	OpenQianKunDai(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhaoHui_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhaoHui_Button4_Click()

end

function Fuli_ZhaoHui_Button5_Click()
	--local nLevel = Player:GetLevel();
	--if ( nLevel < 60 ) then
	--	PushDebugMessage("#{JFRW_170217_4}")
	--	return
	--end
  --
	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OpenDailyFuBen")
	--	Set_XSCRIPT_ScriptID(892428)
	--	Set_XSCRIPT_Parameter(0,0);
	--	Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT()
end



function Fuli_ZhaoHui_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end 
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhaoHui_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhaoHui_Button8_Click()
	OpenHuiGui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhaoHui_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhaoHui_Button9_Click()
	OpenSuperSaveUp(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhaoHui_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_ZhaoHui_Button10_Click()
	local nLevel = Player:GetLevel();
	if( nLevel < 30 ) then
		PushDebugMessage("#{TLZL_190802_03}")	
		return
	end
	OpenZhanLing(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_ZhaoHui_Frame:GetProperty("UnifiedPosition"), 1)
end

-- 更新小红点
function Fuli_ZhaoHui_Refresh_ButtonTips()

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_ZhaoHui_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_ZhaoHui_Button7tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		Fuli_ZhaoHui_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_ZhaoHui_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_ZhaoHui_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_ZhaoHui_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		if nCharCreateDate ~= -1 and ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1)then
			DataPool:Lua_SetRedPointInUIShow(39, 0)
			Fuli_ZhaoHui_Button3tips : Hide()
		else
			Fuli_ZhaoHui_Button3tips : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_ZhaoHui_Button3tips : Hide()
	end
	
	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		Fuli_ZhaoHui_Button5tips : Show()
	else
		Fuli_ZhaoHui_Button5tips : Hide()
	end
	
	
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_ZhaoHui_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_ZhaoHui_Button7tips : Hide()
	end
	
	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_ZhaoHui_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_ZhaoHui_Button8tips : Hide()
	end
		
	-- 福利 累充 
	if DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 then
		Fuli_ZhaoHui_Button9tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 4 ) == 0 then
		Fuli_ZhaoHui_Button9tips : Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 then
		Fuli_ZhaoHui_Button10tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 5 ) == 0 then
		Fuli_ZhaoHui_Button10tips : Hide()
	end
	
end

function Fuli_ZhaoHui_OnClosed()
    this:Hide()
    return
end
 
function Fuli_ZhaoHui_SetCheck()
		Fuli_ZhaoHui_Button1:SetCheck(0)
		Fuli_ZhaoHui_Button2:SetCheck(0)
		Fuli_ZhaoHui_Button3:SetCheck(0)
		Fuli_ZhaoHui_Button5:SetCheck(1)
		Fuli_ZhaoHui_Button7:SetCheck(0)
		Fuli_ZhaoHui_Button8:SetCheck(0) 
end

function Fuli_ZhaoHui_LoadData()
	local nCount = Lua_GetZhaoHuiCount()
	Fuli_ZhaoHui_Frame_List1:CleanAllElement("Fuli_ZhaoHui")
	g_nContentButton = {} 
	local isInSecKill,FubenIDSecKill,BossIndexSecKill,DoubleExpSecKill = GetSecKillData()
	--PushDebugMessage("FubenIDSecKill"..FubenIDSecKill)
	--PushDebugMessage("isInSecKill"..isInSecKill)
	for i = 0 , nCount-1 do 				
			local ID 					= Lua_EnumZhaoHuiData(i,"id")
			local Type 				= Lua_EnumZhaoHuiData(i,"Type")
			local Icon 				= Lua_EnumZhaoHuiData(i,"Icon")
			local nLastDayCount 	= Lua_EnumZhaoHuiData(i,"LastDayCount")
			local NeedLevel 	= Lua_EnumZhaoHuiData(i,"NeedLevel")
			local UICommand 	= Lua_EnumZhaoHuiData(i,"UICommand")
			local FubenID 		= Lua_EnumZhaoHuiData(i,"FubenID")
			local ZhaoHuiName = Lua_EnumZhaoHuiData(i,"ZhaoHuiName")	
			local ZhaoHuiCount = Lua_EnumZhaoHuiData(i,"CurCount")	 
			local ButtonState = Lua_GetZhaoHuiButtonState(Type,FubenID);
			if ButtonState  >= 1 then
				break;
			end 
			local ItemBar
			if Fuli_ZhaoHui_Normal ~= nil then				
				ItemBar = Fuli_ZhaoHui_Frame_List1:AddItemElement( "SuperBarButton_ZhaoHui", "LEFT", "Fuli_ZhaoHui","" ,"")
			elseif Fuli_ZhaoHui_Red ~= nil then			
			    ItemBar = Fuli_ZhaoHui_Frame_List1:AddItemElement( "SuperBarButton_ZhaoHuiSP", "LEFT", "Fuli_ZhaoHui","" ,"")	
			elseif Fuli_ZhaoHui_Summer ~= nil then			
			    ItemBar = Fuli_ZhaoHui_Frame_List1:AddItemElement( "SuperBarButton_ZhaoHuiSum", "LEFT", "Fuli_ZhaoHui","" ,"")	
			end
			ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			
			ItemBar:SetText1( "#G"..ZhaoHuiName )   
			ItemBar:SetButton1Text("找回")
			local sPos,_ = string.find(Icon," ");
		  local IconImageSet = string.sub(Icon,5,sPos-1);
		  local IconIamge = string.sub(Icon,sPos+7) 
		  if nil ~= IconImageSet and nil ~= IconIamge then
		  	ItemBar:SetImage1(IconImageSet,IconIamge) 
		  end
		  
		  local IsZhaoHuiing =0;
		 	if isInSecKill == 3 then 
 				if FubenID == FubenIDSecKill then
 					IsZhaoHuiing =1;
 				end
		 	end
		  
			if Type ~= 4 then
				local TotalCount = 1;
				if Type == 3 then
					TotalCount = 12
				end		
				ItemBar:SetText2( "#G"..TotalCount-ZhaoHuiCount )   
				ItemBar:SetText3( "#G"..NeedLevel )   				
				if ButtonState == 0 then
					ItemBar:SetButton1State(true)
					if ZhaoHuiCount > 0 then
						ItemBar:SetButton1Text("#{XTZY_171213_07}") 
					end
				elseif ButtonState == 1 then
					ItemBar:SetButton1State(false)
					ItemBar:SetText2( "" )  
					ItemBar:SetText3( "#G"..NeedLevel )   				
					ItemBar:SetButton1Text("#{XTZY_171213_07}") 
				elseif ButtonState == 2 then
					ItemBar:SetButton1State(false)
					ItemBar:SetText2( "" )  
					ItemBar:SetText3( "#G"..NeedLevel )   				
					ItemBar:SetButton1Text("不能找回") 
				end		
			
			elseif Type == 4 then 
				local  IconName,FubenName,needLevel,LowSecKillNum,HightSecKillNum,SecKillNeedNumType,SecKillNeedNum,CanDoubleExp, numYuanbao, ActionID = Lua_GetSecKillInfoByFuBenIndexID(FubenID)
				
				local Number 			= GetCampaignTotalNum(ActionID)
				 
				ItemBar:SetText2( "#G"..Number-ZhaoHuiCount )  
				ItemBar:SetText3( "#G"..NeedLevel )   				
				local ButtonState = Lua_GetZhaoHuiButtonState(Type,FubenID);
				if ButtonState == 0 then
					ItemBar:SetButton1State(true)
					if  IsZhaoHuiing == 1 then
						ItemBar:SetButton1Text("#{XTZY_171213_08}") 
					end
				elseif ButtonState == 1 then
					ItemBar:SetButton1State(false) 
					ItemBar:SetText2("")  
					ItemBar:SetText3( "#G"..NeedLevel )   				
					ItemBar:SetButton1Text("#{XTZY_171213_09}") 
				elseif ButtonState == 2 then
					ItemBar:SetButton1State(false)
					ItemBar:SetText2( "" )  
					ItemBar:SetText3( "#G"..NeedLevel )   				
					ItemBar:SetButton1Text("不能找回") 
				end
				
				  
			end
					
			table.insert(g_nContentButton,ItemBar);
			
	end
	if  table.getn(g_nContentButton) == 0 then
		Fuli_ZhaoHui_OverText:Show()
	else
		Fuli_ZhaoHui_OverText:Hide()
	end	
	g_nCurSelectID = 0 
	Fuli_ZhaoHui_Frame_List1:Flash(); 
	  
end

--=========================================================
-- 计算滚动条
--========================================================= 
function Fuli_ZhaoHui_CalcListScrollPos(SelectIdx)
	local BtlIdx = 1
	local ShowIdx = 0
	local ShowCount = 0
	if SelectIdx > table.getn(g_nContentButton) then
		return 0
	end

	for BtlIdx = 1, table.getn(g_nContentButton) do
		if true == g_nContentButton[BtlIdx]:IsVisible() then
			if BtlIdx <= SelectIdx then
				ShowIdx = ShowIdx + 1
			end
			ShowCount = ShowCount + 1
		end
	end
	if ShowCount * 50 < 350 then
		return 0
	else
		return (ShowCount * 50 - 350) * ((ShowIdx - 1) / (ShowCount - 1))
	end
end

--=========================================================
-- 点击 
--=========================================================
function Fuli_ZhaoHui_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		Fuli_ZhaoHui_SetButtonSelected(nIndex + 1) 
		Fuli_ZhaoHui_Frame_List1:Flash()
		g_nCurSelectID = nIndex 
	end
end

--=========================================================
-- 保存点击状态 
--=========================================================
function Fuli_ZhaoHui_SetButtonSelected(nIndex)
																	
	for nButtonIndex = 1,table.getn(g_nContentButton) do
		if nil ~= g_nContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

function Fuli_ZhaoHui_OnButton1Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	 

	if nIndex >= 0 then 	
		Fuli_ZhaoHui_SetButtonSelected(nIndex + 1)
		Fuli_ZhaoHui_Frame_List1:Flash()
		g_nCurSelectID 	= nIndex 
		local nType 		= Lua_EnumZhaoHuiData( g_nCurSelectID, "Type" )
		local nUiCommand= Lua_EnumZhaoHuiData( g_nCurSelectID, "UICommand" ) 
		local nFuBenID	= Lua_EnumZhaoHuiData( g_nCurSelectID, "FubenID" ) 
		--经验找回
		if nType == 1 then
		 	Fuli_ZhaoHui_RequstGetExpBack();
		elseif nType == 2 then --内息找回 
			PushEvent("OPEN_WUYI_ZHAOHUI")
		elseif nType == 4 then --副本找回
			Fuli_ZhaoHui_RequstGetFuBenBack(nFuBenID);
		else
			return;
		end 
	end
	
end

--=========================================================
-- 经验找回
--========================================================= 
function Fuli_ZhaoHui_RequstGetExpBack()  
	Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("RequestGetExpBack");
			Set_XSCRIPT_ScriptID(892659); 
			Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT(); 
end
--=========================================================
-- 副本找回
--========================================================= 
function Fuli_ZhaoHui_RequstGetFuBenBack(nFuBenID)  
	Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("RequestGetFuBenBack"); 
			Set_XSCRIPT_ScriptID(892659); 			
			Set_XSCRIPT_Parameter(0,nFuBenID);
			Set_XSCRIPT_Parameter(1,0);
			Set_XSCRIPT_ParamCount(2); 
	Send_XSCRIPT(); 
end
--=========================================================
-- 打开找回页面 请求数据
--========================================================= 
function Fuli_ZhaoHui_RequstOpenZhaoHui()  
	Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("RequestOpenZhaoHui");
			Set_XSCRIPT_ScriptID(892659); 
			Set_XSCRIPT_ParamCount(0);
	Send_XSCRIPT(); 
end

function Fuli_ZhaoHui_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
	    Fuli_ZhaoHui_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end