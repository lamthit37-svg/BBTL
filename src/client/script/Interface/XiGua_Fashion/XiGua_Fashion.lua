
local g_XiGua_Fashion_UnifiedPosition;

local g_XiGua_Fashion_List = {};
local g_UICommandType =0;
local g_CaiQuan_Index =0;

local g_FairShopType = 0;
local g_FairShopindex = 0;
local g_FairShopshowid = 0;
local g_FairShopitemIdx = 0;
local g_FairShopindex2 = 0;

local g_XiGuaShopFlag = 0;

function XiGua_Fashion_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OPEN_YUANBAOSHOP",false);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function XiGua_Fashion_OnLoad()
	g_XiGua_Fashion_UnifiedPosition = XiGua_Fashion:GetProperty("UnifiedPosition")
	
	g_XiGua_Fashion_List[1] = XiGua_Fashion_Yuanbao_Icon
	g_XiGua_Fashion_List[2] = XiGua_Fashion_Yuanbao2_Icon
	
end

function XiGua_Fashion_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89286904 ) then	
		if Get_XParam_INT(0) == 0 then
			XiGua_Fashion_Close()
			return
		end
		
		g_XiGuaShopFlag = Get_XParam_INT(1)
		
		XiGua_Fashion_Init()
		g_UICommandType = 89286904
		this:Show()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20181227 ) then
		if Get_XParam_INT(0) == 0 then
			XiGua_Fashion_Close()
			return
		end
		g_CaiQuan_Index = Get_XParam_INT(1)
		XiGua_Fashion_CaiQuan_Init()
		g_UICommandType = 20181227
		this:Show()		
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89071309 ) then
		
		g_FairShopType = Get_XParam_INT(0)
		if g_FairShopType == 0 then
			XiGua_Fashion_Close()
			return
		end
		
		g_FairShopindex = Get_XParam_INT(1)
		g_FairShopshowid = Get_XParam_INT(2)
		g_FairShopitemIdx = Get_XParam_INT(3)
		g_FairShopindex2 = Get_XParam_INT(4)
		
		XiGua_Fashion_FairShop_Init()
		g_UICommandType = 89071309
		this:Show()		
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89300801 ) then	--2018Q4春节引导任务--龙凤和鸣礼盒
		if Get_XParam_INT(0) == 0 then
			XiGua_Fashion_Close()
			return
		end
		
		XiGua_Fashion_SpringGuideMission_Init()
		g_UICommandType = 89300801
		this:Show()
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88807701 ) then	--绣春刀礼盒1
		if Get_XParam_INT(0) == 0 then
			XiGua_Fashion_Close()
			return
		end
		
		XiGua_Fashion_XiuChunDao_Init()
		g_UICommandType = 88807701
		this:Show()
	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 50100801 ) then	--预充值-清鸿醉月礼盒
		if Get_XParam_INT(0) == 0 then
			XiGua_Fashion_Close()
			return
		end
		
		XiGua_Fashion_XinFuYuChong_Init()
		g_UICommandType = 50100801
		this:Show()
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88555901 ) then	--幻武盒子
		if Get_XParam_INT(0) == 0 then
			XiGua_Fashion_Close()
			return
		end
		
		XiGua_Fashion_HuanWuHeZi_Init()
		g_UICommandType = 88555901
		this:Show()
		
	elseif (event == "OPEN_YUANBAOSHOP" ) then
		XiGua_Fashion_Close()
		
	elseif (event == "ADJEST_UI_POS" ) then
		XiGua_Fashion_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XiGua_Fashion_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		XiGua_Fashion_Close()
	end

end

--幻武盒子
function XiGua_Fashion_HuanWuHeZi_Init()
	XiGua_Fashion_DragTitle:SetText("#{FYJD_250113_62}")-- 界面标题
	XiGua_Fashion_Jinfen_text:SetText("#{FYJD_250113_33}")--左侧免费道具名字
	XiGua_Fashion_Giftbox_text:SetText("#{FYJD_250113_34}")--右侧购买道具名字
	XiGua_Fashion_Yuanbao_text:SetText("")
	XiGua_Fashion_Yuanbao2_text:SetText("#{FYJD_250113_36}")-- 右侧界面元宝数量
	XiGua_Fashion_Refresh1_Text:SetText("#{FYJD_250113_66}") --下面说明文字
	XiGua_Fashion_ReFresh_Btn:SetText("#{FYJD_250113_35}") --左侧免费领取按钮文字
	XiGua_Fashion_ReFresh_Btn:SetToolTip("")
	XiGua_Fashion_ReFresh_Btn2:SetText("#{FYJD_250113_37}") -- 右侧购买礼盒按钮文字
	XiGua_Fashion_ReFresh_Btn2:SetToolTip("")
	DataPool:Lua_SetXiGuaShopActionItem( 10, 10192272, 1 );  --待修改 第一个道具id
	DataPool:Lua_SetXiGuaShopActionItem( 11, 10192266, 1 );  --待修改 第二个道具id
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 2 do
		local theAction = EnumAction( i+9, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[i]:SetActionItem( theAction:GetID() );
		else
			g_XiGua_Fashion_List[i]:SetActionItem( -1 );
		end
	end		
end

--绣春刀礼盒
function XiGua_Fashion_XiuChunDao_Init()
	XiGua_Fashion_DragTitle:SetText("#{DWPF_200529_02}")
	XiGua_Fashion_Jinfen_text:SetText("#{DWPF_200529_03}")
	XiGua_Fashion_Giftbox_text:SetText("#{DWPF_200529_04}")
	XiGua_Fashion_Yuanbao_text:SetText("")
	XiGua_Fashion_Yuanbao2_text:SetText("#{DWPF_200529_06}")
	XiGua_Fashion_Refresh1_Text:SetText("#{DWPF_200529_08}")
	XiGua_Fashion_ReFresh_Btn:SetText("#{DWPF_200529_05}")
	XiGua_Fashion_ReFresh_Btn:SetToolTip("")
	XiGua_Fashion_ReFresh_Btn2:SetText("#{DWPF_200529_07}")
	XiGua_Fashion_ReFresh_Btn2:SetToolTip("")
	DataPool:Lua_SetXiGuaShopActionItem( 10, 38002031, 1 );
	DataPool:Lua_SetXiGuaShopActionItem( 11, 38004731, 1 );
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 2 do
		local theAction = EnumAction( i+9, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[i]:SetActionItem( theAction:GetID() );
		else
			g_XiGua_Fashion_List[i]:SetActionItem( -1 );
		end
	end		
end

--2018Q4春节引导任务--龙凤和鸣礼盒
function XiGua_Fashion_SpringGuideMission_Init()
	XiGua_Fashion_DragTitle:SetText("#{RACL_181206_545}")
	XiGua_Fashion_Jinfen_text:SetText("#{RACL_181206_558}")
	XiGua_Fashion_Giftbox_text:SetText("#{RACL_181206_559}")
	XiGua_Fashion_Yuanbao_text:SetText("#{RACL_181206_546}")
	XiGua_Fashion_Yuanbao2_text:SetText("#{RACL_181206_547}")
	XiGua_Fashion_Refresh1_Text:SetText("#{RACL_181206_548}")
	XiGua_Fashion_ReFresh_Btn:SetText("#{RACL_181206_549}")
	XiGua_Fashion_ReFresh_Btn:SetToolTip("#{RACL_181206_550}")
	XiGua_Fashion_ReFresh_Btn2:SetText("#{RACL_181206_551}")
	XiGua_Fashion_ReFresh_Btn2:SetToolTip("#{RACL_181206_552}")
	DataPool:Lua_SetXiGuaShopActionItem( 10, 10125207, 1 );
	DataPool:Lua_SetXiGuaShopActionItem( 11, 38002694, 1 );
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 2 do
		local theAction = EnumAction( i+9, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[i]:SetActionItem( theAction:GetID() );
		else
			g_XiGua_Fashion_List[i]:SetActionItem( -1 );
		end
	end		
end

function XiGua_Fashion_FairShop_Init()
	XiGua_Fashion_DragTitle:SetText("#{ZHHD1_181128_162}")
	XiGua_Fashion_Jinfen_text:SetText("#{ZHHD1_181128_146}")
	XiGua_Fashion_Giftbox_text:SetText("#{ZHHD1_181128_147}")
	XiGua_Fashion_Yuanbao_text:SetText("#{MHSD_181126_169}")
	XiGua_Fashion_Yuanbao2_text:SetText("#{MHSD_181126_170}")
	XiGua_Fashion_Refresh1_Text:SetText("#{MHSD_181126_176}")
	XiGua_Fashion_ReFresh_Btn:SetText("#{MHSD_181126_175}")
	XiGua_Fashion_ReFresh_Btn:SetToolTip("#{MHSD_181126_172}")
	XiGua_Fashion_ReFresh_Btn2:SetText("#{MHSD_181126_173}")
	XiGua_Fashion_ReFresh_Btn2:SetToolTip("#{MHSD_181126_174}")
	if g_FairShopitemIdx == 103 then
		local theAction = DataPool:CreateActionItemForShow( 10125207, 1 );
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[1]:SetActionItem( theAction:GetID() );
		end
		theAction = DataPool:CreateActionItemForShow( 38002694, 1 );
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[2]:SetActionItem( theAction:GetID() );
		end
	else
		local theAction = DataPool:CreateActionItemForShow( 10125199, 1 );
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[1]:SetActionItem( theAction:GetID() );
		end
		theAction = DataPool:CreateActionItemForShow( 38002703, 1 );
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[2]:SetActionItem( theAction:GetID() );
		end
	end
end

function XiGua_Fashion_CaiQuan_Init()
	XiGua_Fashion_DragTitle:SetText("#{ZHHD1_181128_162}")
	XiGua_Fashion_Jinfen_text:SetText("#{ZHHD1_181128_146}")
	XiGua_Fashion_Giftbox_text:SetText("#{ZHHD1_181128_147}")
	XiGua_Fashion_Yuanbao_text:SetText("#{ZHHD1_181128_148}")
	XiGua_Fashion_Yuanbao2_text:SetText("#{ZHHD1_181128_149}")
	XiGua_Fashion_Refresh1_Text:SetText("#{ZHHD1_181128_150}")
	XiGua_Fashion_ReFresh_Btn:SetText("#{ZHHD1_181128_151}")
	XiGua_Fashion_ReFresh_Btn:SetToolTip("#{ZHHD1_181128_152}")
	XiGua_Fashion_ReFresh_Btn2:SetText("#{ZHHD1_181128_153}")
	XiGua_Fashion_ReFresh_Btn2:SetToolTip("#{ZHHD1_181128_154}")
	DataPool:Lua_SetXiGuaShopActionItem( 10, 39921625, 1 );
	DataPool:Lua_SetXiGuaShopActionItem( 11, 39921627, 1 );
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 2 do
		local theAction = EnumAction( i+9, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[i]:SetActionItem( theAction:GetID() );
		else
			g_XiGua_Fashion_List[i]:SetActionItem( -1 );
		end
	end	
end

function XiGua_Fashion_XinFuYuChong_Init()
	XiGua_Fashion_DragTitle:SetText("#{YCLB_240911_01}")
	XiGua_Fashion_Jinfen_text:SetText("#{YCLB_240911_03}")
	XiGua_Fashion_Giftbox_text:SetText("#{YCLB_240911_04}")
	XiGua_Fashion_Yuanbao_text:SetText("#{YCLB_240911_06}")
	XiGua_Fashion_Yuanbao2_text:SetText("#{YCLB_240911_06}")
	XiGua_Fashion_Refresh1_Text:SetText("#{YCLB_240911_02}")
	XiGua_Fashion_ReFresh_Btn:SetText("#{YCLB_240911_07}")
	XiGua_Fashion_ReFresh_Btn:SetToolTip("")
	XiGua_Fashion_ReFresh_Btn2:SetText("#{YCLB_240911_07}")
	XiGua_Fashion_ReFresh_Btn2:SetToolTip("")
	DataPool:Lua_SetXiGuaShopActionItem( 10, 38005872, 1 );
	DataPool:Lua_SetXiGuaShopActionItem( 11, 38006411, 1 );
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 2 do
		local theAction = EnumAction( i+9, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[i]:SetActionItem( theAction:GetID() );
		else
			g_XiGua_Fashion_List[i]:SetActionItem( -1 );
		end
	end	
end
--=========================================================
--初始化界面
--=========================================================
function XiGua_Fashion_Init()	
	local theActionlist = {10125133, 38002267}
	
	-- 隐藏预览按钮
	XiGua_Fashion_Preview_Btn:Hide()

	if g_XiGuaShopFlag == 3 then
		XiGua_Fashion_DragTitle:SetText("#{SJSD_180817_56}")
		XiGua_Fashion_Jinfen_text:SetText("#{SJSD_180817_57}")
		XiGua_Fashion_Giftbox_text:SetText("#{SJSD_180817_61}")
		XiGua_Fashion_Yuanbao_text:SetText("#{SJSD_180817_58}")
		XiGua_Fashion_Yuanbao2_text:SetText("#{SJSD_180817_64}")
		XiGua_Fashion_Refresh1_Text:SetText("#{SJSD_180817_67}")
		XiGua_Fashion_ReFresh_Btn:SetText("#{SJSD_180817_59}")
		XiGua_Fashion_ReFresh_Btn:SetToolTip("#{SJSD_180817_60}")
		XiGua_Fashion_ReFresh_Btn2:SetText("#{SJSD_180817_65}")
		XiGua_Fashion_ReFresh_Btn2:SetToolTip("#{SJSD_180817_66}")
		
		--DataPool:Lua_SetXiGuaShopActionItem( 10, 10105023, 1 );
		--DataPool:Lua_SetXiGuaShopActionItem( 11, 38002554, 1 );
		theActionlist[1] = 10105023
		theActionlist[2] = 38002554
	elseif g_XiGuaShopFlag == 4 then
		XiGua_Fashion_DragTitle:SetText("#{XGSD_200609_57}")
		XiGua_Fashion_Jinfen_text:SetText("#{XGSD_200609_58}")
		XiGua_Fashion_Giftbox_text:SetText("#{XGSD_200609_59}")
		XiGua_Fashion_Yuanbao_text:SetText("#{XGSD_200609_60}")
		XiGua_Fashion_Yuanbao2_text:SetText("#{XGSD_200609_61}")
		XiGua_Fashion_Refresh1_Text:SetText("#{XGSD_200609_64}")
		XiGua_Fashion_ReFresh_Btn:SetText("#{XGSD_200609_62}")
		XiGua_Fashion_ReFresh_Btn:SetToolTip("")
		XiGua_Fashion_ReFresh_Btn2:SetText("#{XGSD_200609_63}")
		XiGua_Fashion_ReFresh_Btn2:SetToolTip("")
		
		-- 显示预览按钮
		XiGua_Fashion_Preview_Btn:Show()
		
		--DataPool:Lua_SetXiGuaShopActionItem( 10, 10105023, 1 );
		--DataPool:Lua_SetXiGuaShopActionItem( 11, 38002554, 1 );
		theActionlist[1] = 10126161
		theActionlist[2] = 38004833
	else
		XiGua_Fashion_DragTitle:SetText("#{XGSD_180608_71}")
		XiGua_Fashion_Jinfen_text:SetText("#{XGSD_180608_72}")
		XiGua_Fashion_Giftbox_text:SetText("#{XGSD_180608_73}")
		XiGua_Fashion_Yuanbao_text:SetText("#{XGSD_180608_51}")
		XiGua_Fashion_Yuanbao2_text:SetText("#{XGSD_180608_52}")
		XiGua_Fashion_Refresh1_Text:SetText("#{XGSD_180608_53}")
		XiGua_Fashion_ReFresh_Btn:SetText("#{XGSD_180608_75}")
		XiGua_Fashion_ReFresh_Btn:SetToolTip("#{XGSD_180608_54}")
		XiGua_Fashion_ReFresh_Btn2:SetText("#{XGSD_180608_74}")
		XiGua_Fashion_ReFresh_Btn2:SetToolTip("#{XGSD_180608_55}")
		
		--DataPool:Lua_SetXiGuaShopActionItem( 10, 10125133, 1 );
		--DataPool:Lua_SetXiGuaShopActionItem( 11, 38002267, 1 );
		theActionlist[1] = 10125133
		theActionlist[2] = 38002267
	end
		
	--DataPool:Lua_ClearXiGuaShopActionItem();	
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 2 do
		--local theAction = EnumAction( i+9, "xiguashop_item");
		local theAction = DataPool:CreateActionItemForShow(theActionlist[i], 1)
		if theAction:GetID() ~= 0 then
			g_XiGua_Fashion_List[i]:SetActionItem( theAction:GetID() );
		else
			g_XiGua_Fashion_List[i]:SetActionItem( -1 );
		end
	end
	
end
	
--=========================================================
--购买时装
--=========================================================
function XiGua_Fashion_FashionBuy()
	if g_UICommandType == 89286904 then
		Clear_XSCRIPT()
			if g_XiGuaShopFlag == 3 then
				Set_XSCRIPT_Function_Name( "OnWeaponBuy" )
			elseif g_XiGuaShopFlag == 4 then
				Set_XSCRIPT_Function_Name( "OnFeiYuBuy" )
			else
				Set_XSCRIPT_Function_Name( "OnFashionBuy" )
			end
			Set_XSCRIPT_ScriptID(892869)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif g_UICommandType == 20181227 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItem")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,g_CaiQuan_Index) 
			Set_XSCRIPT_Parameter(1,1) 			
			Set_XSCRIPT_Parameter(2,1) 			
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif g_UICommandType == 89071309 then
		if g_FairShopType == 2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "BigFairShopBuyItem" )
				Set_XSCRIPT_ScriptID(890713)
				Set_XSCRIPT_Parameter(0, g_FairShopindex)
				Set_XSCRIPT_Parameter(1, g_FairShopindex2)
				if g_FairShopitemIdx == 103 then
					Set_XSCRIPT_Parameter(2, 103)
				else
					Set_XSCRIPT_Parameter(2, 42)
				end
				Set_XSCRIPT_Parameter(3, 2)
				Set_XSCRIPT_Parameter(4, 0)
				Set_XSCRIPT_Parameter(5, 0)
				Set_XSCRIPT_ParamCount(6)
			Send_XSCRIPT()
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "FairBuyItem" )
				Set_XSCRIPT_ScriptID(890713)
				Set_XSCRIPT_Parameter(0, g_FairShopindex)
				Set_XSCRIPT_Parameter(1, g_FairShopshowid)
				if g_FairShopitemIdx == 103 then
					Set_XSCRIPT_Parameter(2, 103)
				else
					Set_XSCRIPT_Parameter(2, 42)
				end
				Set_XSCRIPT_Parameter(3, 2)
				Set_XSCRIPT_Parameter(4, 0)
				Set_XSCRIPT_Parameter(5, 0)
				Set_XSCRIPT_ParamCount(6)
			Send_XSCRIPT()
		end
	elseif g_UICommandType == 89300801 then--2018Q4春节引导任务--龙凤和鸣礼盒
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ReceiveFashion" )
			Set_XSCRIPT_ScriptID(893008)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	--
	elseif g_UICommandType == 88807701 then --绣春刀礼盒
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ReceiveFreeLiHe" )
			Set_XSCRIPT_ScriptID(888077)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	

	elseif g_UICommandType == 50100801 then --
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyLiHe" )
			Set_XSCRIPT_Parameter(0, 1)
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ScriptID(501008)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
		
	elseif g_UICommandType == 88555901 then --幻武盒子
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ReceiveFreeLiHe" )
			Set_XSCRIPT_ScriptID(885559)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
			
	end

end

--=========================================================
--购买礼盒
--=========================================================
function XiGua_Fashion_FashionLiHeBuy()
	if g_UICommandType == 89286904 then	
		Clear_XSCRIPT()
			if g_XiGuaShopFlag == 3 then
				Set_XSCRIPT_Function_Name( "OnWeaponLiHeBuy" )
			elseif g_XiGuaShopFlag == 4 then
				Set_XSCRIPT_Function_Name( "OnFeiYuLiHeBuy" )
			else
				Set_XSCRIPT_Function_Name( "OnFashionLiHeBuy" )
			end
			Set_XSCRIPT_ScriptID(892869)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	elseif g_UICommandType == 20181227 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("BuyItem")
			Set_XSCRIPT_ScriptID(893010)
			Set_XSCRIPT_Parameter(0,g_CaiQuan_Index) 
			Set_XSCRIPT_Parameter(1,1) 			
			Set_XSCRIPT_Parameter(2,2) 			
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif	g_UICommandType == 89071309 then
		if g_FairShopType == 2 then
			Set_XSCRIPT_Function_Name( "BigFairShopBuyItem" )
				Set_XSCRIPT_ScriptID(890713)
				Set_XSCRIPT_Parameter(0, g_FairShopindex)
				Set_XSCRIPT_Parameter(1, g_FairShopindex2)		
				if g_FairShopitemIdx == 103 then
					Set_XSCRIPT_Parameter(2, 102)
				else
					Set_XSCRIPT_Parameter(2, 41)
				end
				Set_XSCRIPT_Parameter(3, 2)
				Set_XSCRIPT_Parameter(4, 0)
				Set_XSCRIPT_Parameter(5, 0)
				Set_XSCRIPT_ParamCount(6)
			Send_XSCRIPT()
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "FairBuyItem" )
				Set_XSCRIPT_ScriptID(890713)
				Set_XSCRIPT_Parameter(0, g_FairShopindex)
				Set_XSCRIPT_Parameter(1, g_FairShopshowid)			
				if g_FairShopitemIdx == 103 then
					Set_XSCRIPT_Parameter(2, 102)
				else
					Set_XSCRIPT_Parameter(2, 41)
				end
				Set_XSCRIPT_Parameter(3, 2)
				Set_XSCRIPT_Parameter(4, 0)
				Set_XSCRIPT_Parameter(5, 0)
				Set_XSCRIPT_ParamCount(6)
			Send_XSCRIPT()
		end
	elseif g_UICommandType == 89300801 then--2018Q4春节引导任务--龙凤和鸣礼盒
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyFashionLiHe" )
			Set_XSCRIPT_ScriptID(893008)
			Set_XSCRIPT_Parameter(0,0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
		
	elseif g_UICommandType == 88807701 then --绣春刀礼盒
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyLiHe" )
			Set_XSCRIPT_ScriptID(888077)
			Set_XSCRIPT_Parameter(0,0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	
	elseif g_UICommandType == 50100801 then --
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyLiHe" )
			Set_XSCRIPT_Parameter(0, 2)
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_ScriptID(501008)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	

	elseif g_UICommandType == 88555901 then --幻武盒子
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "BuyLiHe" )
			Set_XSCRIPT_ScriptID(885559)
			Set_XSCRIPT_Parameter(0,0)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()	
	end
end

--=========================================================
--关闭
--=========================================================
function XiGua_Fashion_Close()
	
	if(IsWindowShow("XiGua_Preview")) then
		CloseWindow("XiGua_Preview", true)
	end
	
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function XiGua_Fashion_On_ResetPos()
	XiGua_Fashion:SetProperty("UnifiedPosition", g_XiGua_Fashion_UnifiedPosition);
end

function XiGua_Fashion_FashionPreview()
	if g_UICommandType == 89286904 and g_XiGuaShopFlag == 4 then
		PushEvent( "UI_COMMAND", 2020062901 )
	end
end

