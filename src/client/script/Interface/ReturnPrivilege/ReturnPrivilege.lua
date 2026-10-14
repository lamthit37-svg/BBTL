--ReturnPrivilege.lua

local g_Frame_UnifiedPosition;
local g_ReturnPrivilege_FenYeBtn={};
local g_ReturnPrivilege_Pages={};
local g_ReturnPrivilege_LoginDays = 0;
local g_ReturnPrivilege_UI_RedPoint = 0;
local g_ReturnPrivilege_Ctrl_RedPoint={};
local g_ReturnPrivilege_PageIndex=0;

-- 荣归好礼
local g_ReturnPrivilege_RGHL_ActBtn={};
local g_ReturnPrivilege_RGHL_BtnGet={};
local g_ReturnPrivilege_RGHL_BtnImage={};
local g_ReturnPrivilege_RGHL_BtnState = { 1, 1, 1 };
local g_ReturnPrivilege_RGHL_RequestText={};
local g_ReturnPrivilege_RGHL_MisNameText={};

-- 登录领奖
local g_ReturnPrivilege_DLLJ_ActBtn={};
local g_ReturnPrivilege_DLLJ_BtnGet={};
local g_ReturnPrivilege_DLLJ_BtnImage={};
local g_ReturnPrivilege_DLLJ_BtnState = { 1, 1 };
local g_ReturnPrivilege_DLLJ_RedPoint={};

local g_ReturnPrivilege_DLLJ_GiftBtn = {}
local g_ReturnPrivilege_DLLJ_GiftAni = {}
local g_ReturnPrivilege_DLLJ_GiftEmpty = {}
local g_ReturnPrivilege_DLLJ_GiftText = {}
local g_ReturnPrivilege_DLLJ_GiftState = { 1, 1, 1, 1 };
local g_ReturnPrivilege_DLLJ_Days = {1, 3, 5, 7};

-- 限时放送
local g_ReturnPrivilege_XSFS_ActBtn={};
local g_ReturnPrivilege_XSFS_Button={};
local g_ReturnPrivilege_XSFS_Name={};
local g_ReturnPrivilege_XSFS_Price={};
local g_ReturnPrivilege_XSFS_Rate={};
local g_ReturnPrivilege_XSFS_Mask={};
local g_ReturnPrivilege_XSFS_BuyFlag = { 1, 1, 1 };
local g_ReturnPrivilege_XSFS_ItemId = {};
local g_ReturnPrivilege_XSFS_BuyTime=0;

local g_ReturnPrivilege_LevelImage = {
	[1] = "set:JieBan6 image:jie1", -- 1级
	[2] = "set:JieBan6 image:jie2", -- 2级
	[3] = "set:JieBan6 image:jie3", -- 3级
	[4] = "set:JieBan6 image:jie4", -- 4级
}

function ReturnPrivilege_PreLoad()
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")	
end

function ReturnPrivilege_OnLoad()

	-- 分页按钮
	g_ReturnPrivilege_FenYeBtn[1] = ReturnPrivilege_RGHL_Btn;
	g_ReturnPrivilege_FenYeBtn[2] = ReturnPrivilege_DLLJ_Btn;
	g_ReturnPrivilege_FenYeBtn[3] = ReturnPrivilege_XSFS_Btn;
	g_ReturnPrivilege_FenYeBtn[4] = ReturnPrivilege_SBJX_Btn;
	
	g_ReturnPrivilege_Pages[1] = ReturnPrivilege_Middle;
	g_ReturnPrivilege_Pages[2] = ReturnPrivilege_DengLuLingJiang;
	g_ReturnPrivilege_Pages[3] = ReturnPrivilege_XianShiFangSong;
	g_ReturnPrivilege_Pages[4] = ReturnPrivilege_DoubleSurprise;

	g_ReturnPrivilege_Ctrl_RedPoint[1] = ReturnPrivilege_Left_Buttontab01_Tips
	g_ReturnPrivilege_Ctrl_RedPoint[2] = ReturnPrivilege_Left_Buttontab03_Tips
	g_ReturnPrivilege_Ctrl_RedPoint[3] = ReturnPrivilege_Left_Buttontab02_Tips
	g_ReturnPrivilege_Ctrl_RedPoint[4] = ReturnPrivilege_Left_Buttontab04_Tips

	-- 荣归好礼
	g_ReturnPrivilege_RGHL_ActBtn[1] = ReturnPrivilege1Icon;
	g_ReturnPrivilege_RGHL_ActBtn[2] = ReturnPrivilege2Icon;
	g_ReturnPrivilege_RGHL_ActBtn[3] = ReturnPrivilege3Icon;
	
	g_ReturnPrivilege_RGHL_BtnGet[1] = ReturnPrivilege_GetBtn; 
	g_ReturnPrivilege_RGHL_BtnGet[2] = ReturnPrivilege_GetBtn2;
	g_ReturnPrivilege_RGHL_BtnGet[3] = ReturnPrivilege_GetBtn3;
	
	g_ReturnPrivilege_RGHL_BtnImage[1] = ReturnPrivilege_ReceivedBtn; 
	g_ReturnPrivilege_RGHL_BtnImage[2] = ReturnPrivilege_ReceivedBtn2;
	g_ReturnPrivilege_RGHL_BtnImage[3] = ReturnPrivilege_ReceivedBtn3;
	
	g_ReturnPrivilege_RGHL_RequestText[1] = ReturnPrivilege_GetRequest_1; 
	g_ReturnPrivilege_RGHL_RequestText[2] = ReturnPrivilege_GetRequest_2;
	g_ReturnPrivilege_RGHL_RequestText[3] = ReturnPrivilege_GetRequest_3;
	
	g_ReturnPrivilege_RGHL_MisNameText[1] = ReturnPrivilege_Mission1Name; 
	g_ReturnPrivilege_RGHL_MisNameText[2] = ReturnPrivilege_Mission2Name;
	g_ReturnPrivilege_RGHL_MisNameText[3] = ReturnPrivilege_Mission3Name;
		
	-- 登录领奖
	g_ReturnPrivilege_DLLJ_ActBtn[1] = ReturnPrivilege_DengLuLingJiang_PartA_Item1_Icon;
	g_ReturnPrivilege_DLLJ_ActBtn[2] = ReturnPrivilege_DengLuLingJiang_PartA_Item2_Icon;	
	g_ReturnPrivilege_DLLJ_BtnGet[1] = ReturnPrivilege_DengLuLingJiang_PartA_Item1_GetBtn;
	g_ReturnPrivilege_DLLJ_BtnGet[2] = ReturnPrivilege_DengLuLingJiang_PartA_Item2_GetBtn2;	
	g_ReturnPrivilege_DLLJ_BtnImage[1] = ReturnPrivilege_DengLuLingJiang_PartA_Item1_ReceivedBtn;
	g_ReturnPrivilege_DLLJ_BtnImage[2] = ReturnPrivilege_DengLuLingJiang_PartA_Item2_ReceivedBtn2;
	
	g_ReturnPrivilege_DLLJ_GiftBtn[1] = ReturnPrivilege_DengLuLingJiang_PartB_Item1;
	g_ReturnPrivilege_DLLJ_GiftBtn[2] = ReturnPrivilege_DengLuLingJiang_PartB_Item2;
	g_ReturnPrivilege_DLLJ_GiftBtn[3] = ReturnPrivilege_DengLuLingJiang_PartB_Item3;
	g_ReturnPrivilege_DLLJ_GiftBtn[4] = ReturnPrivilege_DengLuLingJiang_PartB_Item4;	
	g_ReturnPrivilege_DLLJ_GiftAni[1] = ReturnPrivilege_DengLuLingJiang_PartB_Item1_Ani;
	g_ReturnPrivilege_DLLJ_GiftAni[2] = ReturnPrivilege_DengLuLingJiang_PartB_Item2_Ani;
	g_ReturnPrivilege_DLLJ_GiftAni[3] = ReturnPrivilege_DengLuLingJiang_PartB_Item3_Ani;
	g_ReturnPrivilege_DLLJ_GiftAni[4] = ReturnPrivilege_DengLuLingJiang_PartB_Item4_Ani;	
	g_ReturnPrivilege_DLLJ_GiftEmpty[1] = ReturnPrivilege_DengLuLingJiang_PartB_Item1_Empty;
	g_ReturnPrivilege_DLLJ_GiftEmpty[2] = ReturnPrivilege_DengLuLingJiang_PartB_Item2_Empty;
	g_ReturnPrivilege_DLLJ_GiftEmpty[3] = ReturnPrivilege_DengLuLingJiang_PartB_Item3_Empty;
	g_ReturnPrivilege_DLLJ_GiftEmpty[4] = ReturnPrivilege_DengLuLingJiang_PartB_Item4_Empty;
	g_ReturnPrivilege_DLLJ_GiftText[1] = ReturnPrivilege_DengLuLingJiang_PartB_Item1_Text;
	g_ReturnPrivilege_DLLJ_GiftText[2] = ReturnPrivilege_DengLuLingJiang_PartB_Item2_Text;
	g_ReturnPrivilege_DLLJ_GiftText[3] = ReturnPrivilege_DengLuLingJiang_PartB_Item3_Text;
	g_ReturnPrivilege_DLLJ_GiftText[4] = ReturnPrivilege_DengLuLingJiang_PartB_Item4_Text;
	g_ReturnPrivilege_DLLJ_RedPoint[1] = ReturnPrivilege_Btn_RedDot1;
	g_ReturnPrivilege_DLLJ_RedPoint[2] = ReturnPrivilege_Btn_RedDot2;
	g_ReturnPrivilege_DLLJ_RedPoint[3] = ReturnPrivilege_Btn_RedDot3;
	g_ReturnPrivilege_DLLJ_RedPoint[4] = ReturnPrivilege_Btn_RedDot4;
		
	-- 限时放送
	g_ReturnPrivilege_XSFS_ActBtn[1] = ReturnPrivilege_XianShiFangSong_Item1_Icon;
	g_ReturnPrivilege_XSFS_ActBtn[2] = ReturnPrivilege_XianShiFangSong_Item2_Icon;
	g_ReturnPrivilege_XSFS_ActBtn[3] = ReturnPrivilege_XianShiFangSong_Item3_Icon;
	
	g_ReturnPrivilege_XSFS_Button[1] = ReturnPrivilege_XianShiFangSong_Item1_Btn;
	g_ReturnPrivilege_XSFS_Button[2] = ReturnPrivilege_XianShiFangSong_Item2_Btn;
	g_ReturnPrivilege_XSFS_Button[3] = ReturnPrivilege_XianShiFangSong_Item_Btn;	
	
	g_ReturnPrivilege_XSFS_Name[1] = ReturnPrivilege_XianShiFangSong_Item1_Text1;
	g_ReturnPrivilege_XSFS_Name[2] = ReturnPrivilege_XianShiFangSong_Item2_Text1;
	g_ReturnPrivilege_XSFS_Name[3] = ReturnPrivilege_XianShiFangSong_Item3_Text1;	
	
	g_ReturnPrivilege_XSFS_Price[1] = ReturnPrivilege_XianShiFangSong_Item1_Text2;
	g_ReturnPrivilege_XSFS_Price[2] = ReturnPrivilege_XianShiFangSong_Item2_Text2;
	g_ReturnPrivilege_XSFS_Price[3] = ReturnPrivilege_XianShiFangSong_Item3_Text2;	
	
	g_ReturnPrivilege_XSFS_Mask[1] = ReturnPrivilege_XianShiFangSong_Item1_Icon_Mask;
	g_ReturnPrivilege_XSFS_Mask[2] = ReturnPrivilege_XianShiFangSong_Item2_Icon_Mask;
	g_ReturnPrivilege_XSFS_Mask[3] = ReturnPrivilege_XianShiFangSong_Item3_Icon_Mask;	
	
	g_ReturnPrivilege_XSFS_Rate[1] = ReturnPrivilege_XianShiFangSong_Item1_Discount_text;
	g_ReturnPrivilege_XSFS_Rate[2] = ReturnPrivilege_XianShiFangSong_Item2_Discount_text;
	g_ReturnPrivilege_XSFS_Rate[3] = ReturnPrivilege_XianShiFangSong_Item3_Discount_text;
	
	g_Frame_UnifiedPosition = ReturnPrivilege:GetProperty("UnifiedPosition") 
end

function ReturnPrivilege_OnEvent(event)

	--显示荣归大礼界面
	if event == "UI_COMMAND" then
		-- 荣归好礼
		if tonumber(arg0) == 80811001 then
			local bShow = Get_XParam_INT(0);
			if bShow <= 0 and (this:IsVisible()~=true or g_ReturnPrivilege_PageIndex ~= 1) then
				return
			end
						
			local nLeftTime = Get_XParam_INT(1);
			local nVipGiftItemID = Get_XParam_INT(2);
			local nGiftData = Get_XParam_INT(3);
			g_ReturnPrivilege_RGHL_BtnState[1] = math.mod( nGiftData, 10);
			g_ReturnPrivilege_RGHL_BtnState[2] = math.mod( math.floor(nGiftData/10), 10);
			g_ReturnPrivilege_RGHL_BtnState[3] = math.mod( math.floor(nGiftData/100), 10);
			
			local nShowSBJX = Get_XParam_INT(4);	
			g_ReturnPrivilege_UI_RedPoint = Get_XParam_INT(5)
			local nHLLevel = Get_XParam_INT(6);			
			ReturnPrivilege_ShowContent( 1, nLeftTime, nHLLevel, 0, 0, nShowSBJX );
			ReturnPrivilege_ShowPage_RongGui( nVipGiftItemID )
			
			ReturnPrivilege_UpdateRedPointInUI();
			
			ReturnPrivilege_ResetPos( bShow )
			this:Show();
			
		-- 登录领奖
		elseif tonumber(arg0) == 80811002 then
			local bShow = Get_XParam_INT(0);
			if bShow <= 0 and (this:IsVisible()~=true or g_ReturnPrivilege_PageIndex ~= 2) then
				return
			end
		
			local nLeftTime = Get_XParam_INT(1);
			g_ReturnPrivilege_LoginDays = Get_XParam_INT(2);			
			g_ReturnPrivilege_DLLJ_BtnState[1] = Get_XParam_INT(3);
			g_ReturnPrivilege_DLLJ_BtnState[2] = Get_XParam_INT(4);
			
			local nGiftData = Get_XParam_INT(5);
			g_ReturnPrivilege_DLLJ_GiftState[1] = math.mod( nGiftData, 10);
			g_ReturnPrivilege_DLLJ_GiftState[2] = math.mod( math.floor(nGiftData/10), 10);
			g_ReturnPrivilege_DLLJ_GiftState[3] = math.mod( math.floor(nGiftData/100), 10);
			g_ReturnPrivilege_DLLJ_GiftState[4] = math.mod( math.floor(nGiftData/1000), 10);

			local nShowSBJX = Get_XParam_INT(6);			
			g_ReturnPrivilege_UI_RedPoint = Get_XParam_INT(7)
			local nHLLevel = Get_XParam_INT(8);			
			ReturnPrivilege_ShowContent( 2, nLeftTime, nHLLevel, 0, g_ReturnPrivilege_LoginDays, nShowSBJX );
			ReturnPrivilege_ShowPage_LingJiang( nHLLevel )
			ReturnPrivilege_UpdateRedPointInUI();
			
			ReturnPrivilege_ResetPos( bShow )
			this:Show();
			
		-- 限时放送
		elseif tonumber(arg0) == 80811003 then
			local bShow = Get_XParam_INT(0);
			if bShow <= 0 and (this:IsVisible()~=true or g_ReturnPrivilege_PageIndex ~= 3) then
				return
			end
		
			g_ReturnPrivilege_XSFS_BuyTime = Get_XParam_INT(1);
			local nBuyData = Get_XParam_INT(2);
			g_ReturnPrivilege_XSFS_BuyFlag[1] = math.mod( math.floor(nBuyData/100), 10);
			g_ReturnPrivilege_XSFS_BuyFlag[2] = math.mod( math.floor(nBuyData/10), 10);
			g_ReturnPrivilege_XSFS_BuyFlag[3] = math.mod( nBuyData, 10);
			
			local nhlLevel	= Get_XParam_INT(3);
			local nTime			= Get_XParam_INT(4);			
			local nShowSBJX = Get_XParam_INT(5);
			g_ReturnPrivilege_UI_RedPoint = Get_XParam_INT(6)
			local nLeftTime = Get_XParam_INT(7);
			ReturnPrivilege_ShowContent( 3, nLeftTime, nhlLevel, g_ReturnPrivilege_XSFS_BuyTime, 0, nShowSBJX );
			ReturnPrivilege_ShowPage_FangSong( nhlLevel, nTime )
			ReturnPrivilege_UpdateRedPointInUI();
			
			ReturnPrivilege_ResetPos( bShow )
			this:Show();
			
		-- 双倍惊喜
		elseif tonumber(arg0) == 80811004 then
		
			local bShow = Get_XParam_INT(0);
			if bShow <= 0 and (this:IsVisible()~=true or g_ReturnPrivilege_PageIndex ~= 4) then
				return
			end
		
			local nLeftTime = Get_XParam_INT(1);
			g_ReturnPrivilege_UI_RedPoint = Get_XParam_INT(2)
			local nhlLevel	= Get_XParam_INT(3);
			ReturnPrivilege_ShowContent( 4, nLeftTime, nhlLevel, 0, 0, 1 );
			ReturnPrivilege_ShowPage_JingXi()
			ReturnPrivilege_UpdateRedPointInUI();
			
			ReturnPrivilege_ResetPos( bShow )
			this:Show();
			
		-- 领奖，显示动画
		elseif tonumber(arg0) == 80811007 then
			
			local nEnable = Get_XParam_INT(0);
			local nIndex = Get_XParam_INT(1);
			ReturnPrivilege_DLLJ_PlayAni(nEnable, nIndex)
			
		elseif tonumber(arg0) == 89319510 and this:IsVisible() then
			--红点
			g_ReturnPrivilege_UI_RedPoint = Get_XParam_INT(0)*1000+Get_XParam_INT(1)*100+Get_XParam_INT(2)*10+Get_XParam_INT(3);
			--刷新红点
			ReturnPrivilege_UpdateRedPointInUI()
		end	
		
	end
	
	if event == "UPDATE_REDPOINT_IN_UI" and this:IsVisible() then
		ReturnPrivilege_UpdateRedPointInUI()	
		return
	end
	
	if event == "VIEW_RESOLUTION_CHANGED" then
		ReturnPrivilege_On_ResetPos();
		return
	end
	
	if event == "ADJEST_UI_POS" then
		ReturnPrivilege_On_ResetPos();
		return
	end
	
	if ( event == "SCENE_TRANSED" ) then
		ReturnPrivilege_OnClosed()
		return
	end
	
end

--刷新荣归大礼界面
function ReturnPrivilege_ShowPage_RongGui( nVipGiftItemID )

	ReturnPrivilege_FenYeBtnClick( 1 );
	
	local nGiftItemId={ 39921014, 39921015, nVipGiftItemID};	
	local szMisName={ "#{JBHL_190803_376}", "#{JBHL_190803_375}", "#{JBHL_190803_374}" };	
	for i=1, 3 do
		--显示图标
		local theAction = DataPool:CreateActionItemForShow(nGiftItemId[i], 1)
		if theAction:GetID() ~= 0 then	
			g_ReturnPrivilege_RGHL_ActBtn[i]:SetActionItem(theAction:GetID())
			g_ReturnPrivilege_RGHL_MisNameText[i]:SetText( szMisName[i] );
		end
			
		if g_ReturnPrivilege_RGHL_BtnState[i] == 0 then	--已领取
			g_ReturnPrivilege_RGHL_BtnGet[i]:Hide();
			g_ReturnPrivilege_RGHL_BtnImage[i]:Show();			
			g_ReturnPrivilege_RGHL_RequestText[i]:Hide();
		elseif g_ReturnPrivilege_RGHL_BtnState[i] == 1 then	--可领取
			g_ReturnPrivilege_RGHL_BtnGet[i]:Show();
			g_ReturnPrivilege_RGHL_BtnImage[i]:Hide();
			g_ReturnPrivilege_RGHL_BtnGet[i]:Enable();
			g_ReturnPrivilege_RGHL_RequestText[i]:Hide();
		else  -- 未领取，但不可领取
			g_ReturnPrivilege_RGHL_BtnGet[i]:Show();
			g_ReturnPrivilege_RGHL_BtnImage[i]:Hide();
			g_ReturnPrivilege_RGHL_BtnGet[i]:Disable();
			g_ReturnPrivilege_RGHL_RequestText[i]:Show();
		end		
	end
	
end

-- 显示 登录领奖 界面
function ReturnPrivilege_ShowPage_LingJiang( nHLLevel )

	ReturnPrivilege_FenYeBtnClick( 2 );
	
	ReturnPrivilege_DengLuLingJiang_PartA_Text:Hide();
	
	local lstItemId = {39921016, 39921017};
	for i=1, 2 do
		--显示图标
		local theAction = DataPool:CreateActionItemForShow(lstItemId[i], 1)
		if theAction:GetID() ~= 0 then	
			g_ReturnPrivilege_DLLJ_ActBtn[i]:SetActionItem(theAction:GetID())
		end
		
		if g_ReturnPrivilege_DLLJ_BtnState[i] == 1 then	--可领取
			g_ReturnPrivilege_DLLJ_BtnGet[i]:Show();
			g_ReturnPrivilege_DLLJ_BtnImage[i]:Hide();
			g_ReturnPrivilege_DLLJ_BtnGet[i]:Enable();
		elseif g_ReturnPrivilege_DLLJ_BtnState[i] == 0 then	--已领取
			g_ReturnPrivilege_DLLJ_BtnGet[i]:Hide();
			g_ReturnPrivilege_DLLJ_BtnImage[i]:Show();
		else -- 未领取，但不可领取
			g_ReturnPrivilege_DLLJ_BtnGet[i]:Show();
			g_ReturnPrivilege_DLLJ_BtnImage[i]:Hide();
			g_ReturnPrivilege_DLLJ_BtnGet[i]:Disable();
			if i == 2 then
				ReturnPrivilege_DengLuLingJiang_PartA_Text:Show();
			end
		end		
				
	end	
	
	local szListTooltip = {
		[1] = {"#{JBHL_190803_397}", "#{JBHL_190803_398}", "#{JBHL_190803_399}", "#{JBHL_190803_400}"},
		[2] = {"#{JBHL_190803_401}", "#{JBHL_190803_402}", "#{JBHL_190803_403}", "#{JBHL_190803_404}"},
		[3] = {"#{JBHL_190803_405}", "#{JBHL_190803_406}", "#{JBHL_190803_407}", "#{JBHL_190803_408}"},
		[4] = {"#{JBHL_190803_409}", "#{JBHL_190803_410}", "#{JBHL_190803_411}", "#{JBHL_190803_412}"},
	};
	
	for i=1, 4 do
		g_ReturnPrivilege_DLLJ_GiftText[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_326}", g_ReturnPrivilege_DLLJ_Days[i] ) );
		if g_ReturnPrivilege_DLLJ_Days[i] <= g_ReturnPrivilege_LoginDays then
			if g_ReturnPrivilege_DLLJ_GiftState[i] == 1 then
				g_ReturnPrivilege_DLLJ_GiftBtn[i]:Show()
				g_ReturnPrivilege_DLLJ_GiftEmpty[i]:Hide()
				g_ReturnPrivilege_DLLJ_GiftAni[i]:Hide()
				g_ReturnPrivilege_DLLJ_RedPoint[i]:Show()
			else
				g_ReturnPrivilege_DLLJ_GiftBtn[i]:Hide()
				g_ReturnPrivilege_DLLJ_GiftEmpty[i]:Show()
				g_ReturnPrivilege_DLLJ_GiftAni[i]:Hide()
				g_ReturnPrivilege_DLLJ_RedPoint[i]:Hide()
			end
		else
			g_ReturnPrivilege_DLLJ_GiftEmpty[i]:Hide()
			g_ReturnPrivilege_DLLJ_GiftBtn[i]:Show()
			g_ReturnPrivilege_DLLJ_GiftAni[i]:Hide()
			g_ReturnPrivilege_DLLJ_RedPoint[i]:Hide()
		end
				
		if szListTooltip[nHLLevel] ~= nil then
			local lstTooltip = szListTooltip[nHLLevel];
			g_ReturnPrivilege_DLLJ_GiftBtn[i]:SetToolTip( lstTooltip[i] );
		end

	end
	
end

-- 显示 限时放送 界面
function ReturnPrivilege_ShowPage_FangSong( nhlLevel, nTime )
	
	ReturnPrivilege_FenYeBtnClick( 3 );
	g_ReturnPrivilege_XSFS_ItemId = {};
		
	for i=1, 3 do
		local nItemId, nShowItemId, nCount, nRawPrice, nPrice = GetHuiLiuShopItem( nhlLevel, nTime, i-1 );
		if nItemId == nil and nShowItemId == nil and nCount <= 0 then
			break;
		end
		
		g_ReturnPrivilege_XSFS_ItemId[i] = nItemId;
	
		--显示图标
		local theAction = DataPool:CreateActionItemForShow(nShowItemId, nCount)
		if theAction:GetID() ~= 0 then	
			g_ReturnPrivilege_XSFS_ActBtn[i]:SetActionItem(theAction:GetID())
			
			-- 道具名
			g_ReturnPrivilege_XSFS_Name[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_418}", theAction:GetName() ) );
		end
		
		local nRateH = math.floor( nPrice*10 / nRawPrice );
		local nRateL = math.floor( math.mod(nPrice*10, nRawPrice)*10 / nRawPrice );
		g_ReturnPrivilege_XSFS_Rate[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_353}", nRateH, nRateL ) );
		
		--可购买
		g_ReturnPrivilege_XSFS_Button[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_354}", nPrice ) );
		if g_ReturnPrivilege_XSFS_BuyFlag[i] == 0 then	
			g_ReturnPrivilege_XSFS_Button[i]:Enable();
			g_ReturnPrivilege_XSFS_Mask[i]:Hide();
		else
			g_ReturnPrivilege_XSFS_Button[i]:Disable();
			g_ReturnPrivilege_XSFS_Mask[i]:Show();
		end		
				
		-- 原价
		g_ReturnPrivilege_XSFS_Price[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_419}", nRawPrice ) );
		
	end	
	
end

-- 显示 双倍惊喜 界面
function ReturnPrivilege_ShowPage_JingXi()
	
	ReturnPrivilege_FenYeBtnClick( 4 );
	
end

function ReturnPrivilege_FenYeBtnClick( index )
	if index == nil or index <= 0 or index > 4 then
		return
	end
		
	for i=1, 4 do
		if g_ReturnPrivilege_Pages[i] ~= nil then
			g_ReturnPrivilege_Pages[i]:Hide();
		end
		if g_ReturnPrivilege_FenYeBtn[i] ~= nil then
			g_ReturnPrivilege_FenYeBtn[i]:SetCheck(0);
		end
	end
	
	if g_ReturnPrivilege_Pages[index] ~= nil then
		g_ReturnPrivilege_Pages[index]:Show();
	end
	if g_ReturnPrivilege_FenYeBtn[index] ~= nil then
		g_ReturnPrivilege_FenYeBtn[index]:SetCheck(1);
	end
end

function ReturnPrivilege_ShowContent( index, nLeftTime, nHLLevel, nBuyTime, nLoginDays, nShowSBJX )

	ReturnPrivilege_TimeLeft_Text1:Hide();
	ReturnPrivilege_TimeLeft_Text2:Hide();
	ReturnPrivilege_BuyLeftTime_Text1:Hide();
	ReturnPrivilege_BuyLeftTime_Text2:Hide();
	ReturnPrivilege_AccumulativeDays:Hide();
	ReturnPrivilege_TimeLeft_Text3:Hide();
		
	-- 帮助按钮	
	g_ReturnPrivilege_PageIndex = index;
	ReturnPrivilege_PageInfo_Help:Show();
	
	-- 说明
	local lstDict={"#{JBHL_190803_372}", "#{JBHL_190803_378}", "#{JBHL_190803_381}", "#{JBHL_190803_392}"};
	if lstDict[index] ~= nil then
		ReturnPrivilege_PageInfo:SetText( lstDict[index] );
	end
			
	-- 回流特权剩余时间
	if index == 1 or index == 2 or index == 3 or index == 4 then
		nLeftTime = tonumber(nLeftTime);
		if nLeftTime > 0 then
			local nDay = math.floor(nLeftTime / (3600 * 24));
			local nHour = math.ceil( math.mod( nLeftTime, 3600*24)/ 3600 )
		
			ReturnPrivilege_TimeLeft_Text2:SetText( ScriptGlobal_Format("#{JBHL_190803_288}", nDay, nHour) );
			ReturnPrivilege_TimeLeft_Text1:Show();
			ReturnPrivilege_TimeLeft_Text2:Show();
		end
	
		-- 图片	
		if g_ReturnPrivilege_LevelImage[nHLLevel] ~= nil then
			ReturnPrivilege_TimeLeft_but:SetProperty("Image", g_ReturnPrivilege_LevelImage[nHLLevel])
		end
		ReturnPrivilege_TimeLeft_but:SetToolTip( ScriptGlobal_Format("#{JBHL_190803_417}", nHLLevel) );
	end
		
	-- 剩余购买时间
	if index == 3 then
		nBuyTime = tonumber(nBuyTime)
		if nBuyTime > 0 then
			local nBuyTime = tonumber(g_ReturnPrivilege_XSFS_BuyTime)
			local nDay = math.floor(nBuyTime / (3600 * 24));
			local nHour = math.ceil( math.mod( nBuyTime, 3600*24)/ 3600 )
			ReturnPrivilege_BuyLeftTime_Text2:SetText( ScriptGlobal_Format("#{JBHL_190803_298}", nDay, nHour ) );
		
			ReturnPrivilege_BuyLeftTime_Text1:Show();
			ReturnPrivilege_BuyLeftTime_Text2:Show();
		end
	end
	
	-- 累计登录天数
	if index == 2 then
		nLoginDays = tonumber(nLoginDays)
		if nLoginDays > 0 then
			ReturnPrivilege_AccumulativeDays:SetText( ScriptGlobal_Format("#{JBHL_190803_327}", nLoginDays) );
			ReturnPrivilege_AccumulativeDays:Show();
		end
	end
	
	--
	if index == 4 then
		ReturnPrivilege_TimeLeft_Text3:Show();
	end
		
	-- 双倍惊喜
	if nShowSBJX > 0 then
		ReturnPrivilege_SBJX_Btn:Show();
	else
		ReturnPrivilege_SBJX_Btn:Hide();
	end

end

function ReturnPrivilege_DLLJ_PlayAni(nEnable, nIndex)
	if nEnable == 0 then
		return
	end

	g_ReturnPrivilege_DLLJ_GiftAni[nIndex]:Show()
	g_ReturnPrivilege_DLLJ_RedPoint[nIndex]:Hide()
	g_ReturnPrivilege_DLLJ_GiftAni[nIndex]:SetProperty("Animate", "WeekHuoyuehaoli_open_Flash");
	SetTimer("ReturnPrivilege","ReturnPrivilege_DLLJ_TimeReach()",1000)

end

function ReturnPrivilege_DLLJ_TimeReach()
	KillTimer("ReturnPrivilege_DLLJ_TimeReach()");
	
	for i = 1, 4 do
		local nVisb = g_ReturnPrivilege_DLLJ_GiftAni[i]:IsVisible()
		if nVisb then
			g_ReturnPrivilege_DLLJ_GiftBtn[i]:Hide()
			g_ReturnPrivilege_DLLJ_GiftEmpty[i]:Show()
			g_ReturnPrivilege_DLLJ_RedPoint[i]:Hide()
		end
	end
end

function ReturnPrivilege_DLLJ_NoItemClick( index )
end

-- 刷新小红点
function ReturnPrivilege_UpdateRedPointInUI()

	ReturnPrivilege_Left_Buttontab01:SetProperty("Selected", "False")
	ReturnPrivilege_Left_Buttontab02:SetProperty("Selected", "False")
	ReturnPrivilege_Left_Buttontab03:SetProperty("Selected", "False")
	ReturnPrivilege_Left_Buttontab04:SetProperty("Selected", "True")
	
	if DataPool:Lua_IsRedPointInUIShow( 22 ) == 1 then
		ReturnPrivilege_RGHL_Btn_RedDot:Show()
	else
		ReturnPrivilege_RGHL_Btn_RedDot:Hide()
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 23 ) == 1 then
		ReturnPrivilege_DLLJ_Btn_RedDot:Show()
	else
		ReturnPrivilege_DLLJ_Btn_RedDot:Hide()
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 24 ) == 1 then
		ReturnPrivilege_XSFS_Btn_RedDot:Show()
	else
		ReturnPrivilege_XSFS_Btn_RedDot:Hide()
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 25 ) == 1 then
		ReturnPrivilege_SBJX_Btn_RedDot:Show()
	else
		ReturnPrivilege_SBJX_Btn_RedDot:Hide()
	end
	
	local lstPow = { 1000, 100, 10, 1 };
	for i=1, 4 do
		local nIsShow = math.mod( math.floor(g_ReturnPrivilege_UI_RedPoint/lstPow[i]), 10);
		if nIsShow > 0 then
			g_ReturnPrivilege_Ctrl_RedPoint[i]:Show();
		else
			g_ReturnPrivilege_Ctrl_RedPoint[i]:Hide();
		end
	end
	
end

--荣归大礼界面领取按钮
function ReturnPrivilege_RGHL_GetPrize( index )

	if index < 1 or index > 3 then
		return
	end
	
	if g_ReturnPrivilege_RGHL_BtnState[index] ~= 1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetOldFriendBonus" )
		Set_XSCRIPT_ScriptID( 808110 )
		Set_XSCRIPT_Parameter( 0, index )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
				
end

--领取每日登录的奖励
function ReturnPrivilege_DLLJ_GetPrize( index )

	if index < 1 or index > 2 then
		return
	end
	
	if g_ReturnPrivilege_DLLJ_BtnState[index] ~= 1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetOldFriendBonus" )
		Set_XSCRIPT_ScriptID( 808110 )
		Set_XSCRIPT_Parameter( 0, index+3 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
				
end

-- 领取登录天数的奖励
function ReturnPrivilege_GetGiftItemPrize( index )
	if index < 1 or index > 4 then
		return
	end
	
	-- 检查是否领取过
	if g_ReturnPrivilege_DLLJ_GiftState[index] ~= 1 then
		PushDebugMessage("#{JBHL_190803_347}");
		return
	end
	
	-- 检查天数
	if g_ReturnPrivilege_DLLJ_Days[index] == nil or g_ReturnPrivilege_DLLJ_Days[index] > g_ReturnPrivilege_LoginDays then
		PushDebugMessage("#{JBHL_190803_348}");
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetRefluencePrivilegeGift" )
		Set_XSCRIPT_ScriptID( 808110 )
		Set_XSCRIPT_Parameter( 0, index )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--限时放送领取
function ReturnPrivilege_XSFS_GetPrize( index )

	if index < 1 or index > 3 or g_ReturnPrivilege_XSFS_ItemId[index] == nil then
		return
	end
	
	-- 检查是否领取过
	if g_ReturnPrivilege_XSFS_BuyFlag[index] > 0 then
		PushDebugMessage("#{JBHL_190803_347}");
		return
	end
		
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyFangSongItem" )
		Set_XSCRIPT_ScriptID( 808110 )
		Set_XSCRIPT_Parameter( 0, index )
		Set_XSCRIPT_Parameter( 1, g_ReturnPrivilege_XSFS_ItemId[index] )
		Set_XSCRIPT_Parameter( 2, 0 )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
		
end

function ReturnPrivilege_OnHiden()

	KillTimer("ReturnPrivilege_DLLJ_TimeReach()");
	
end

function ReturnPrivilege_OnClosed()
	
	this:Hide();
	
end

function ReturnPrivilege_ResetPos( bReset )
	if bReset <= 0 then
		return
	end
	
	local CurUIPos = Variable:GetVariable("JieBanUIPos")
	if( CurUIPos ~= nil) then
	    ReturnPrivilege:SetProperty("UnifiedPosition", CurUIPos )
	end
	
end

function ReturnPrivilege_On_ResetPos()
  ReturnPrivilege:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--页面切换 1、结伴任务 2、商店 3、回流任务 
function ReturnPrivilege_Project_Clicked(index)
	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenJiebanMission" )
			Set_XSCRIPT_ScriptID( 893195 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif index == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenHuiliuMission" )
			Set_XSCRIPT_ScriptID( 893229 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif index == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenJiebanShop" )
			Set_XSCRIPT_ScriptID( 893196 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif index == 4 then
		return
	end
	
	Variable:SetVariable("JieBanUIPos", ReturnPrivilege:GetProperty("UnifiedPosition"), 1)
end

--页面切换： 1、荣归好礼，2、登录领奖，3，限时放送，4、双倍惊喜
function ReturnPrivilege_FenYe_OnClick( index )
	
	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUIRongGui")
			Set_XSCRIPT_ScriptID(808110)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()

	elseif index == 2 then
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUILingJiang")
			Set_XSCRIPT_ScriptID(808110)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		
	elseif index == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUIXianShiFangSong")
			Set_XSCRIPT_ScriptID(808110)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		
	elseif index == 4 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUIJingXi")
			Set_XSCRIPT_ScriptID(808110)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		
	end
	
	Variable:SetVariable("JieBanUIPos", ReturnPrivilege:GetProperty("UnifiedPosition"), 1)
	
end

function ReturnPrivilege_Description_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnShowHelp")
		Set_XSCRIPT_ScriptID(808110)
		Set_XSCRIPT_Parameter(0, g_ReturnPrivilege_PageIndex) --1: JBHL_190803_373    2:JBHL_190803_377
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end
