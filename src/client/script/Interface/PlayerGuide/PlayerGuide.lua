local g_PlayerGuide_Frame_UnifiedXPosition;
local g_PlayerGuide_Frame_UnifiedYPosition;

local g_PlayerGuide_const_interval = 5

local g_PlayerGuide_Data_Cache = {};
local g_nCurrentTableIndex = -1;
local g_nCurrentPicIdx = -1;
local g_nNumPics = -1;
local g_PlayerGuide_button_DZMP = {}
--=========================================================
-- 预加载， 窗口还没打开， 只能用THIS注册事件
--=========================================================
function PlayerGuide_PreLoad()
	this:RegisterEvent("OPEN_PLAYERGUIDE")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


--=========================================================
-- 窗口加载后回调， 在第一次激发本窗口RegisterEvent的Event后触发
-- 此后， 可以调用窗口的操作，窗口恒存在，在没此回调之前，是没有窗口存在的。
--=========================================================
function PlayerGuide_OnLoad()
	g_PlayerGuide_Frame_UnifiedXPosition	= PlayerGuide_Frame:GetProperty("UnifiedXPosition");
	g_PlayerGuide_Frame_UnifiedYPosition	= PlayerGuide_Frame:GetProperty("UnifiedYPosition");
			
	PlayerGuide_Bar:Hide();
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text1);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text2);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text3);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text4);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text5);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text6);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text7);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text8);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text9);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text10);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text11);
	_PlayerGuide_EnableCtrlMouse(PlayerGuide_Text12);
	
	PlayerGuide_StopWatch:Hide();	--玩家手动打开时，不会出现N/A字样
	
	g_PlayerGuide_button_DZMP[1] = PlayerGuide_MenPai_ShaoLin
	g_PlayerGuide_button_DZMP[2] = PlayerGuide_MenPai_MingJiao
	g_PlayerGuide_button_DZMP[3] = PlayerGuide_MenPai_GaiBang
	g_PlayerGuide_button_DZMP[4] = PlayerGuide_MenPai_WuDang
	g_PlayerGuide_button_DZMP[5] = PlayerGuide_MenPai_EMei
	g_PlayerGuide_button_DZMP[6] = PlayerGuide_MenPai_XingXiu
	g_PlayerGuide_button_DZMP[7] = PlayerGuide_MenPai_Tianlong
	g_PlayerGuide_button_DZMP[8] = PlayerGuide_MenPai_TianShan
	g_PlayerGuide_button_DZMP[9] = PlayerGuide_MenPai_XiaoYao
	g_PlayerGuide_button_DZMP[10] = PlayerGuide_MenPai_MuRong
	g_PlayerGuide_button_DZMP[11] = PlayerGuide_MenPai_TangMen
	g_PlayerGuide_button_DZMP[12] = PlayerGuide_MenPai_GuiGu
	g_PlayerGuide_button_DZMP[13] = PlayerGuide_MenPai_TaoHuaDao
	g_PlayerGuide_button_DZMP[14] = PlayerGuide_MenPai_HongMing
	g_PlayerGuide_button_DZMP[15] = PlayerGuide_MenPai_ERenGu
end


--=========================================================
-- Game事件处理 arg0, arg1.. is the Event param.
--=========================================================
function PlayerGuide_OnEvent(event)

	if(event == "OPEN_PLAYERGUIDE") then 
		-- tt86959 参数不为-1表示是由升级触发的，界面强制显示5秒
		if tonumber(arg0) ~= -1 then
			PlayerGuide_Close:Disable();
			PlayerGuide_StopWatch:Show();
			PlayerGuide_StopWatch:SetProperty("Timer", "5");
		end
		if tonumber(arg0) == 14 and Player:GetData("Is2606S") == 1 then
			return
		end 
		_PlayerGuide_ShowItem( tonumber(arg0) );
		PlayerGuide_DingZhiMenPai()
	end

	if( event == "ADJEST_UI_POS" ) then
		_PlayerGuide_ResetPos()
	end

	if( event == "VIEW_RESOLUTION_CHANGED" ) then
		_PlayerGuide_ResetPos()
	end

end

--=========================================================
--UI 事件  arg0 is the CEGUI:Window's name
--=========================================================
-- 下拉框选择
function PlayerGuide_OnSelectAccepted()
	local __txt, id = PlayerGuide_Select:GetCurrentSelect();
	if id == -1 then
		_PlayerGuide_CleanForm();
	else
		_PlayerGuide_SetControlData(id);
	end
end

-- 转到江湖指南
function PlayerGuide_OnGotoWorldRefence()
	OpenWordrefence();
	_PlayerGuide_CleanForm();
	this:Hide();
end

-- 定时器事件到了
function PlayerGuide_OnTimer()
	g_nCurrentPicIdx = g_nCurrentPicIdx+1;
	if (g_nCurrentPicIdx > g_nNumPics) then
		g_nCurrentPicIdx = 1 --循环播放
	end
	
	local t_Data = g_PlayerGuide_Data_Cache[g_nCurrentTableIndex];
	local strImage = t_Data.Image[g_nCurrentPicIdx];
	_PlayerGuide_SetImage(strImage);
	_PlayerGuide_SetTimer(g_PlayerGuide_const_interval);
end

-- 隐藏是调用，咱们的CEGUI:Window不关闭的（销毁的），只是隐藏
-- 比如说：PlayerGuide_Close控件Clicked事件会调用this:Hide
-- 这个是Hide事件的额外处理
function PlayerGuide_OnHide()
	_PlayerGuide_CleanForm();
end

function PlayerGuide_DingZhiMenPai()
	if DataPool:Lua_IsNewServerPlayer() == 0 then
		return
	end
	local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	local MenPaiInfo = Lua_GetDingZhiMenPaiSvrInfo(selfZoneWorldID)
	if type(MenPaiInfo) ~= "table" then
		return
	end 
	for index=1, table.getn(MenPaiInfo) do 
		if MenPaiInfo[index] == 0 then
			g_PlayerGuide_button_DZMP[index]:Disable()
		end
	end 
end

function PlayerGuide_OnMouseWheel()
--	PushDebugMessage("PlayerGuide_OnMouseWheel");
end
--=========================================================
-- 显示某个条目(id)
--=========================================================
function _PlayerGuide_ShowItem(nItemId)
	-- pre do
	this:Hide();
	_PlayerGuide_CleanForm();


	--construct data.	
	local nVisableCount = ExcitPoint:GetVisableCount(); 
	if nVisableCount > 0 then
		local __nCombIndex = nVisableCount-1;
		local __nTableIndex = ExcitPoint:GetVisableTableIndexByIndex(__nCombIndex);
		
		-- combobox [list]
		for i=0, nVisableCount-1 do
			local nTableIndex = ExcitPoint:GetVisableTableIndexByIndex(i);
			local t_Data = g_PlayerGuide_Data_Cache[nTableIndex]; 
			if Player:GetData("Is2606S") == 1 and nTableIndex == 14 then
				continue
			end
			PlayerGuide_Select:AddTextItem(t_Data.Title, nTableIndex);
			if nItemId == nTableIndex then
				__nCombIndex = i;
				__nTableIndex = nTableIndex;
			end
		end
		 
		-- combobox [select]  && other control. 
		if Player:GetData("Is2606S") == 1 and __nCombIndex >= 13 then
			__nCombIndex = 12;
			__nTableIndex = 13;
		end
		PlayerGuide_Select:SetCurrentSelect(__nCombIndex);  
		_PlayerGuide_SetControlData(__nTableIndex);  
	end

	if nItemId == 1 then
		PlayerGuide_ShowFreshManGuide(1)
	end
  -- final do
	this:Show();
end

--=========================================================
--界面布局操作
--=========================================================

-- 重置位置
function _PlayerGuide_ResetPos()
	PlayerGuide_Frame:SetProperty("UnifiedXPosition", g_PlayerGuide_Frame_UnifiedXPosition);
	PlayerGuide_Frame:SetProperty("UnifiedYPosition", g_PlayerGuide_Frame_UnifiedYPosition);
end

-- 清除全部界面
function _PlayerGuide_CleanForm()
	--cache all data
	local nTotalCount = ExcitPoint:GetTotalCount();
	if nTotalCount>0 then
		for i=0, nTotalCount-1 do
			-- for each tableindex, cache
			local nTableIndex = ExcitPoint:GetTotalTableIndexByIndex(i);
			g_PlayerGuide_Data_Cache[nTableIndex] = ExcitPoint:GetItemByTableIndex(nTableIndex);
		end
	end

	PlayerGuide_Select:ResetList();
	_PlayerGuide_SetText(PlayerGuide_Select, "");
	_PlayerGuide_SetText(PlayerGuide_Text, "");
	_PlayerGuide_SetText(PlayerGuide_Text1, "");
	_PlayerGuide_SetText(PlayerGuide_Text2, "");
	_PlayerGuide_SetText(PlayerGuide_Text3, "");
	_PlayerGuide_SetText(PlayerGuide_Text4, "");
	_PlayerGuide_SetText(PlayerGuide_Text5, "");
	_PlayerGuide_SetText(PlayerGuide_Text6, "");
	_PlayerGuide_SetText(PlayerGuide_Text7, "");
	_PlayerGuide_SetText(PlayerGuide_Text8, "");
	_PlayerGuide_SetText(PlayerGuide_Text9, "");
	_PlayerGuide_SetText(PlayerGuide_Text10, "");
	_PlayerGuide_SetText(PlayerGuide_Text11, "");
	_PlayerGuide_SetText(PlayerGuide_Text12, "");
	g_nCurrentTableIndex = -1;
	g_nCurrentPicIdx = -1;
	g_nNumPics = -1;	
	_PlayerGuide_ClearImage();
	_PlayerGuide_KillTimer();
end

-- 设置控件内容(CombList除外)
function _PlayerGuide_SetControlData(nTableIndex)
	--10级门派的控件隐藏
	PlayerGuide_MenPaiJieShao_Client:Hide();
	PlayerGuide_MenPai_ShaoLin:Hide();
	PlayerGuide_MenPai_GaiBang:Hide();
	PlayerGuide_MenPai_MingJiao:Hide();
	PlayerGuide_MenPai_WuDang:Hide();
	PlayerGuide_MenPai_Tianlong:Hide();
	PlayerGuide_MenPai_XiaoYao:Hide();
	PlayerGuide_MenPai_EMei:Hide();
	PlayerGuide_MenPai_XingXiu:Hide();
	PlayerGuide_MenPai_TianShan:Hide();
	PlayerGuide_MenPai_MuRong:Hide();
	PlayerGuide_MenPai_TangMen:Hide();
	PlayerGuide_MenPai_GuiGu:Hide();
	PlayerGuide_MenPai_TaoHuaDao:Hide();
	PlayerGuide_MenPai_HongMing:Hide();
	PlayerGuide_MenPai_ERenGu:Hide(); --新门派-恶人谷-ypl-江湖指南等
	PlayerGuide_HongDong1:Show();
	PlayerGuide_HongDong2:Show();
	PlayerGuide_HongDong3:Show();
	PlayerGuide_MenPai_Client_Normal:Hide()
	PlayerGuide_MenPai_Client_SJ:Hide()
	if g_nCurrentTableIndex == nTableIndex and g_nCurrentTableIndex ~= 1 then
		return;
	end
	g_nCurrentTableIndex = nTableIndex
	
	local t_Data = g_PlayerGuide_Data_Cache[nTableIndex];

-- layout.
-- ---------------------------------------------	
-- |	[TLBB_SelfWindow] PlayerGuide_Text       |
-- ---------------------------------------------
--                                             |
-- ---------------------------------------------
-- |  [DefaultWindow] PlayerGuide_HongDong1    |
-- |                                           |
-- |  --------------------------------------   |
-- |  |[TLBB_SimpleText] PlayerGuide_Text1 |   |
-- |  --------------------------------------   |
-- |                                           |
-- |  --------------------------------------   |
-- |  |[TLBB_SimpleText] PlayerGuide_Text2 |   |
-- |  --------------------------------------   |
-- |                                           |
-- |  --------------------------------------   |
-- |  |[DefaultWindow] PlayerGuide_Text3   |   |
-- |  --------------------------------------   |
-- ---------------------------------------------
-- |                                           |
-- ---------------------------------------------
-- |  [DefaultWindow] PlayerGuide_HongDong2    |
-- |                                           |
-- |  --------------------------------------   |
-- |  |[TLBB_SimpleText] PlayerGuide_Text4 |   |
-- |  --------------------------------------   |
-- |                                           |
-- |  --------------------------------------   |
-- |  |[TLBB_SimpleText] PlayerGuide_Text5 |   |
-- |  --------------------------------------   |
-- |                                           |
-- |  --------------------------------------   |
-- |  |[DefaultWindow] PlayerGuide_Text6   |   |
-- |  --------------------------------------   |
-- ---------------------------------------------

	_PlayerGuide_SetText(PlayerGuide_Text, t_Data.Content);
	if nTableIndex == 14 and Lua_GetDingZhiMenPaiCJFlag() == 1 then
		_PlayerGuide_SetText(PlayerGuide_Text, "#{SJF_251024_7}");
	end
	
	local __x, y = PlayerGuide_Text:GetWindowSize();
--	PushDebugMessage("V2: X=" .. tostring(__x) .. ", Y=" .. tostring(y) );	
	--PlayerGuide_Text:Hide();
	--PlayerGuide_Text:AddTextElement(t_Data.Content);
	

	-- 10级自动弹出的武林图鉴内容修改
	if nTableIndex == 1 then 
		if Lua_GetDingZhiMenPaiCJFlag() ~= 1 then
			PlayerGuide_MenPai_Client_Normal:Show()
			PlayerGuide_MenPai_Client_SJ:Hide()
		else
			PlayerGuide_MenPai_Client_Normal:Hide()
			PlayerGuide_MenPai_Client_SJ:Show()		
			PlayerGuide_MenPai_ShaoLin_SJ:SetCheck(1)
		end
		PlayerGuide_MenPaiJieShao_Client:Show();
		PlayerGuide_MenPai_ShaoLin:Show();
		PlayerGuide_MenPai_GaiBang:Show();
		PlayerGuide_MenPai_MingJiao:Show();
		PlayerGuide_MenPai_WuDang:Show();
		PlayerGuide_MenPai_Tianlong:Show();
		PlayerGuide_MenPai_XiaoYao:Show();
		PlayerGuide_MenPai_EMei:Show();
		PlayerGuide_MenPai_XingXiu:Show();
		PlayerGuide_MenPai_TianShan:Show();
		PlayerGuide_MenPai_MuRong:Show();
		PlayerGuide_MenPai_TangMen:Show();
		PlayerGuide_MenPai_GuiGu:Show();
		PlayerGuide_MenPai_TaoHuaDao:Show();
		PlayerGuide_MenPai_HongMing:Show();
		PlayerGuide_MenPai_ERenGu:Show(); --新门派-恶人谷-ypl-江湖指南等
		
		_PlayerGuide_SetText(PlayerGuide_Text1, "");
		_PlayerGuide_SetText(PlayerGuide_Text2, "");
		_PlayerGuide_SetText(PlayerGuide_Text3, "");
		_PlayerGuide_SetText(PlayerGuide_Text4, "");
		_PlayerGuide_SetText(PlayerGuide_Text5, "");
		_PlayerGuide_SetText(PlayerGuide_Text6, "");
		_PlayerGuide_SetText(PlayerGuide_Text7, "");
		_PlayerGuide_SetText(PlayerGuide_Text8, "");
		_PlayerGuide_SetText(PlayerGuide_Text9, "");
		_PlayerGuide_SetText(PlayerGuide_Text10, "");
		_PlayerGuide_SetText(PlayerGuide_Text11, "");
		_PlayerGuide_SetText(PlayerGuide_Text12, "");
		PlayerGuide_HongDong1:Hide();
		PlayerGuide_HongDong2:Hide();
		PlayerGuide_HongDong3:Hide();
		
		PlayerGuide_MenPai_ShaoLin:SetCheck(1);
		PlayerGuide_MenPai_GaiBang:SetCheck(0);
		PlayerGuide_MenPai_MingJiao:SetCheck(0);
		PlayerGuide_MenPai_WuDang:SetCheck(0);
		PlayerGuide_MenPai_Tianlong:SetCheck(0);
		PlayerGuide_MenPai_XiaoYao:SetCheck(0);
		PlayerGuide_MenPai_EMei:SetCheck(0);
		PlayerGuide_MenPai_XingXiu:SetCheck(0);
		PlayerGuide_MenPai_TianShan:SetCheck(0);
		PlayerGuide_MenPai_MuRong:SetCheck(0);
		PlayerGuide_MenPai_TangMen:SetCheck(0);
		PlayerGuide_MenPai_GuiGu:SetCheck(0);
		PlayerGuide_MenPai_TaoHuaDao:SetCheck(0);
		PlayerGuide_MenPai_HongMing:SetCheck(0);
		PlayerGuide_MenPai_ERenGu:SetCheck(0); --新门派-恶人谷-ypl-江湖指南等
		PlayerGuide_MenPai_ShaoLin_Info();
	end
	
	local nItemHeight = y+10;
	local nAllHeight = nItemHeight;
	local __x1, __x2, __x3, __x4;
  
	-- 1, 2, 3
	PlayerGuide_HongDong1:SetProperty("UnifiedPosition", "{{0.0000000,0.000000},{0.0," .. tostring(nAllHeight) .. "}}" )
	PlayerGuide_Text1:SetText(t_Data.TableData[1][1]);
	PlayerGuide_Text2:SetText(t_Data.TableData[1][2]);
	_PlayerGuide_SetText(PlayerGuide_Text3, t_Data.TableData[1][3]);
	__x1, nItemHeight = PlayerGuide_Text3:GetWindowSize();
	PlayerGuide_HongDong1:SetProperty("UnifiedSize", "{{1.0,0.000000},{0.0," .. tostring(nItemHeight) .. "}}" )  -- 恶心， 父窗口设置大小，会导致selfwindow重新计算resize一下
	_PlayerGuide_FixSpace(PlayerGuide_Text3);
	nAllHeight = nAllHeight + nItemHeight-2; --策划说移动2个像素,下同
  
	-- 4, 5, 6
	PlayerGuide_HongDong2:SetProperty("UnifiedPosition", "{{0.0000000,0.000000},{0.0," .. tostring(nAllHeight) .. "}}" )
	PlayerGuide_Text4:SetText(t_Data.TableData[2][1]);
	PlayerGuide_Text5:SetText(t_Data.TableData[2][2]);
	_PlayerGuide_SetText(PlayerGuide_Text6, t_Data.TableData[2][3]);
	__x2, nItemHeight = PlayerGuide_Text6:GetWindowSize();
	PlayerGuide_HongDong2:SetProperty("UnifiedSize", "{{1.0,0.000000},{0.0," .. tostring(nItemHeight) .. "}}" )
	_PlayerGuide_FixSpace(PlayerGuide_Text6);
	nAllHeight = nAllHeight + nItemHeight-2;



	-- 7, 8, 9
	PlayerGuide_HongDong3:SetProperty("UnifiedPosition", "{{0.0000000,0.000000},{0.0," .. tostring(nAllHeight) .. "}}" )
	PlayerGuide_Text7:SetText(t_Data.TableData[3][1]);
	PlayerGuide_Text8:SetText(t_Data.TableData[3][2]);
	_PlayerGuide_SetText(PlayerGuide_Text9, t_Data.TableData[3][3]);
	__x3, nItemHeight = PlayerGuide_Text9:GetWindowSize();
	PlayerGuide_HongDong3:SetProperty("UnifiedSize", "{{1.0,0.000000},{0.0," .. tostring(nItemHeight) .. "}}" )
	_PlayerGuide_FixSpace(PlayerGuide_Text9);
	nAllHeight = nAllHeight + nItemHeight-2;

	-- 10, 11 12
	PlayerGuide_HongDong4:SetProperty("UnifiedPosition", "{{0.0000000,0.000000},{0.0," .. tostring(nAllHeight) .. "}}" )
	PlayerGuide_Text10:SetText(t_Data.TableData[4][1]);
	PlayerGuide_Text11:SetText(t_Data.TableData[4][2]);
	_PlayerGuide_SetText(PlayerGuide_Text12, t_Data.TableData[4][3]);
	__x4, nItemHeight = PlayerGuide_Text12:GetWindowSize();
	PlayerGuide_HongDong4:SetProperty("UnifiedSize", "{{1.0,0.000000},{0.0," .. tostring(nItemHeight) .. "}}" )
	_PlayerGuide_FixSpace(PlayerGuide_Text12);
	nAllHeight = nAllHeight + nItemHeight-2;
	
	-- fix Max weight
	local __MaxX = __x1;
	if (__MaxX < __x2) then __MaxX = __x2 end;
	if (__MaxX < __x3) then __MaxX = __x3 end;
	if (__MaxX < __x4) then __MaxX = __x4 end;
	__MaxX = __MaxX
		
	PlayerGuide_Text3:SetProperty("UnifiedWidth", "{0.0," .. tostring(__MaxX) .. "}");
	PlayerGuide_Text6:SetProperty("UnifiedWidth", "{0.0," .. tostring(__MaxX) .. "}");
	PlayerGuide_Text9:SetProperty("UnifiedWidth", "{0.0," .. tostring(__MaxX) .. "}");
	PlayerGuide_Text12:SetProperty("UnifiedWidth", "{0.0," .. tostring(__MaxX) .. "}");



	g_nNumPics = table.getn(t_Data.Image);
	if g_nNumPics > 0 then
		g_nCurrentPicIdx = 1;
		_PlayerGuide_SetImage(t_Data.Image[1]);
		_PlayerGuide_SetTimer(g_PlayerGuide_const_interval);
	else
		--no pic
		g_nNumPics = -1;
		g_nCurrentPicIdx = -1;
		_PlayerGuide_ClearImage();
		_PlayerGuide_KillTimer();
	end
end

function _PlayerGuide_SetImage(strImage)
	PlayerGuide_Image:SetProperty("Image", strImage);
end

function _PlayerGuide_ClearImage()
	PlayerGuide_Image:SetProperty("Image", "");
end 

function _PlayerGuide_SetTimer(interval)
	PlayerGuide_Timer:SetProperty("Timer", tostring(interval));
end
function _PlayerGuide_KillTimer()
	PlayerGuide_Timer:SetProperty("Timer", "0");
end

--注意， TLBB_SelfWindow需要SetText后Show一把， 不知道为什么底层要当Text为""的SetText后，Hide窗口。
--不想动底层， 所以这里改哦, 为了方便， 提供此种代码。
function _PlayerGuide_SetText(ctrl, text)
	if text == "" then
		ctrl:SetText(text);
	else
		ctrl:SetText(text);
		ctrl:Show();	
	end
end

-- 修复一下呗， 让策划填充空格， 来增加第2行高度。
-- 但是这样会让第三列不对其， 所以还需要删除空格后再次settext, 然后再设置原有的高度
function _PlayerGuide_FixSpace(ctrl)
	local txt = ctrl:GetText();
	local len = string.len(txt);
	
	local newtxt = _PlayerGuide_StrTrimTail(txt);
	if (txt ~= newtxt) then
		local w, h = ctrl:GetWindowSize();
		ctrl:SetText(newtxt);
		ctrl:SetWindowSize(w, h);
	end
end

function _PlayerGuide_StrTrimTail(str)
	local len = string.len(str);
	local count = 0;
	for i=len, 1, -1 do
		local x = string.sub(str, i, i);
		if x == " " then count = count + 1 else break end;
	end
	return string.sub(str, 1, len-count);
end

function _PlayerGuide_EnableCtrlMouse(ctrl)
	ctrl:SetProperty("MouseHollow", "False");
	ctrl:SetProperty("MouseLButtonHollow", "False");
end

function PlayerGuide_TimeReach()
	--时间到了
	PlayerGuide_Close:Enable();
	PlayerGuide_StopWatch:Hide();	--这里还是要加，否则还是会出现N/A字样
end

--10大门派详细介绍
function PlayerGuide_MenPai_ShaoLin_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[1][1]);
end

function PlayerGuide_MenPai_GaiBang_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[1][2]);
end

function PlayerGuide_MenPai_MingJiao_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[1][3]);
end

function PlayerGuide_MenPai_WuDang_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[2][1]);
end

function PlayerGuide_MenPai_Tianlong_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[2][2]);
end

function PlayerGuide_MenPai_EMei_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[2][3]);
end

function PlayerGuide_MenPai_XingXiu_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[3][2]);
end

function PlayerGuide_MenPai_XiaoYao_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[3][1]);
end

function PlayerGuide_MenPai_TianShan_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[3][3]);
end

function PlayerGuide_MenPai_MuRong_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[4][1]);
end

function PlayerGuide_ShowFreshManGuide(nType)
	local fX = 0
	local fY = 0
	local nPosX = tonumber(PlayerGuide_Frame:GetProperty("AbsoluteXPosition"))
	local nPosY = tonumber(PlayerGuide_Frame:GetProperty("AbsoluteYPosition"))
	if nType == 1 then
		fX, fY = this:GetChildOffset("PlayerGuide_All")
		local fH = tonumber(PlayerGuide_All:GetProperty("AbsoluteHeight"))
		local fW = tonumber(PlayerGuide_All:GetProperty("AbsoluteWidth"))
		fX = tonumber(fX + nPosX + fW - 120)
		fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)) - 30)
		OpenFreshManGuideNew(1, fX, fY, fW, fH, 20, 3, "PlayerGuide")
	end
end

function PlayerGuide_MenPai_TangMen_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[4][2]);
end

function PlayerGuide_MenPai_GuiGu_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[4][3]);
end

function PlayerGuide_MenPai_TaoHuaDao_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[5][1]);
end

function PlayerGuide_MenPai_HongMing_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[5][2]);
end

--新门派-恶人谷-ypl-江湖指南等
function PlayerGuide_MenPai_ERenGu_Info()
	local t_Data = g_PlayerGuide_Data_Cache[1];
	PlayerGuide_MenPaiJieShao_Text:SetText(t_Data.TableData[5][3]);
end
