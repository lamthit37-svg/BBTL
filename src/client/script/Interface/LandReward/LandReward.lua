
local g_LandReward_Frame_UnifiedPosition;

local g_LandReward_Button = {}
local g_LandReward_Frames = {}
local g_LandReward_GiftsButton = {}

local g_ButtonCDTime = 1; --按钮冷却时间
local g_ButtonLastTime = 0;
local g_LastClickedId = -1; --上次选中的选项

local g_AccountDay = 0
local g_IsGetGift = {0,0,0,0,0,0}

local g_Fengyecount = 0

local g_LandReward_Gifts = {
	[1] = 	{ 
			{GiftItemID = 39920296, num = 3,}, -- 真元珀
			},
	[2] =	{	
			{GiftItemID = 39920332, num = 5,}, -- 悟灵珠
			},
	[3] =   {
			{GiftItemID = 39920298, num = 3,}, -- 真元精珀
			},
	[4] =   {
			{GiftItemID = 39920162, num = 30,}, -- 精金石*30
			},
	[5] =   {
			{GiftItemID = 39920462, num = 1,}, -- 3级红宝石
			},
	[6] =   {
			{GiftItemID = 39920181, num = 2,}, -- 玄灵丹*2
			},
}
--界面上显示奖励物品的ICON表
local g_LandReward_GiftsIcons = { }

local g_LandReward_ExchangeGifts = {
--[1] = {GiftItemID = 39921274, num = 1,}, -- 秋高气爽礼盒
--[2] = {GiftItemID = 39921275, num = 1,}, -- 金风玉露礼盒
--[3] = {GiftItemID = 39921276, num = 1,}, -- 五谷丰登礼盒

[1] = {GiftItemID = 39921384, num = 1,},  -- 春意盎然礼盒
[2] = {GiftItemID = 39921385, num = 1,},  -- 春风送暖礼盒
[3] = {GiftItemID = 39921386, num = 1,},  -- 春光明媚礼盒
[4] = {GiftItemID = 39921387, num = 1,},  -- 春满人间礼盒
}

local g_ctrlItemAction = {}

function LandReward_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
end

function LandReward_OnLoad()
	g_LandReward_Frame_UnifiedPosition=LandReward_Frame:GetProperty("UnifiedPosition");
	
	g_LandReward_Button[1] = LandReward_Button01
	g_LandReward_Button[2] = LandReward_Button02
	g_LandReward_Frames[1] = LandReward_DengLuFrame
	g_LandReward_Frames[2] = LandReward_Exchange_Frame
		
	g_LandReward_GiftsButton[1] = LandReward_DengLu_Bk1_Button1
	g_LandReward_GiftsButton[2] = LandReward_DengLu_Bk2_Button1	
	g_LandReward_GiftsButton[3] = LandReward_DengLu_Bk3_Button1
	g_LandReward_GiftsButton[4] = LandReward_DengLu_Bk4_Button1
	g_LandReward_GiftsButton[5] = LandReward_DengLu_Bk5_Button1	
	g_LandReward_GiftsButton[6] = LandReward_DengLu_Bk6_Button1	
	
	--界面上显示奖励物品的ICON表
	g_LandReward_GiftsIcons =
	{
	[1] = {LandReward_DengLu_Bk1_Icon1, LandReward_DengLu_Bk1_Icon2, LandReward_DengLu_Bk1_Icon3, LandReward_DengLu_Bk1_Icon4, }, 
	[2] = {LandReward_DengLu_Bk2_Icon1, LandReward_DengLu_Bk2_Icon2, LandReward_DengLu_Bk2_Icon3, LandReward_DengLu_Bk2_Icon4, }, 
	[3] = {LandReward_DengLu_Bk3_Icon1, LandReward_DengLu_Bk3_Icon2, LandReward_DengLu_Bk3_Icon3, LandReward_DengLu_Bk3_Icon4, }, 
	[4] = {LandReward_DengLu_Bk4_Icon1, LandReward_DengLu_Bk4_Icon2, LandReward_DengLu_Bk4_Icon3, LandReward_DengLu_Bk4_Icon4, }, 
	[5] = {LandReward_DengLu_Bk5_Icon1, LandReward_DengLu_Bk5_Icon2, LandReward_DengLu_Bk5_Icon3, LandReward_DengLu_Bk5_Icon4, }, 
	[6] = {LandReward_DengLu_Bk6_Icon1, LandReward_DengLu_Bk6_Icon2, LandReward_DengLu_Bk6_Icon3, LandReward_DengLu_Bk6_Icon4, }, 
	}
	
	g_ctrlItemAction = 
	{
	[1] = LandReward_Exchange_Item1_Icon,
	[2] = LandReward_Exchange_Item2_Icon,
	[3] = LandReward_Exchange_Item3_Icon,
	[4] = LandReward_Exchange_Item4_Icon,
	}
end

-- OnEvent
function LandReward_OnEvent(event)

	if (event == "UI_COMMAND") and (tonumber(arg0) == 8925031) then	
		--打开界面
		g_AccountDay 	= Get_XParam_INT( 0 ); 
		for iGift = 1,table.getn(g_LandReward_Gifts) do
			if Get_XParam_INT( iGift ) ~= nil then
				g_IsGetGift[iGift] = Get_XParam_INT( iGift ); 
			else 
				g_IsGetGift[iGift] = 0
			end
		end
		g_LandReward_Button[1]:SetCheck(1)
		g_LandReward_Button[2]:SetCheck(0)
		
		LandReward_DengLuFrame:Show();
		LandReward_Exchange_Frame:Hide();
		
		LandReward_UpdateUI()	
		LandReward_UpdateRedPointInUI()	
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AddYongYanLog" )
			Set_XSCRIPT_ScriptID( 892473)
			Set_XSCRIPT_Parameter( 0, 13 )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
		
		this:Show();
	elseif (event == "UI_COMMAND") and (tonumber(arg0) == 8925032) then
		
		g_Fengyecount 	= Get_XParam_INT( 0 ); 
		
		LandReward_DengLuFrame:Hide();
		LandReward_Exchange_Frame:Show();
		
		g_LandReward_Button[1]:SetCheck(0)
		g_LandReward_Button[2]:SetCheck(1)
		
		local str = ScriptGlobal_Format("#{LJDL_170823_13}",tostring(g_Fengyecount))
		LandReward_Exchange_Text : SetText(str)	
		
		DataPool:Lua_ClearAccLoginActionItem();
			for i=0, table.getn(g_LandReward_ExchangeGifts)-1 do 
				DataPool:Lua_SetAccLoginActionItem( i, g_LandReward_ExchangeGifts[i+1].GiftItemID, g_LandReward_ExchangeGifts[i+1].num);
			end
		DataPool:Lua_UpdateAccLoginActionItem();
				
		for i=0, table.getn(g_LandReward_ExchangeGifts)-1 do 
			local theAction = EnumAction( i, "acclogin_item");
			if theAction:GetID() ~= 0 then
				g_ctrlItemAction[i+1]:SetActionItem( theAction:GetID() );                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
			else
				g_ctrlItemAction[i+1]:SetActionItem( -1 );
			end
		end

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "AddYongYanLog" )
			Set_XSCRIPT_ScriptID( 892473)
			Set_XSCRIPT_Parameter( 0, 14 )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
				
		this:Show();
	elseif event == "UPDATE_REDPOINT_IN_UI" and this:IsVisible() then
		LandReward_UpdateRedPointInUI()	
		return
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	elseif (event == "ADJEST_UI_POS" ) then
		LandReward_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		LandReward_Frame_On_ResetPos()
		
	end

end

function LandReward_UpdateRedPointInUI()	
	LandReward_Button01_Tips:Hide()
	if DataPool:Lua_IsRedPointInUIShow( 18 ) == 1 then
		LandReward_Button01_Tips:Show()
	end
end
--显示界面内容
function LandReward_UpdateUI()	
		
	for i=1, table.getn(g_LandReward_Gifts) do		
		--显示按钮
		if g_IsGetGift[i] == 0 then
			g_LandReward_GiftsButton[i]:Enable()
		else
			g_LandReward_GiftsButton[i]:Disable()
		end
	end
	local str = ScriptGlobal_Format("#{LJDL_170823_05}",tostring(g_AccountDay))
	LandReward_DengLu_InfoText :SetText(str)
	
    --将物品奖励加载到页面显示
    for i = 1,  table.getn(g_LandReward_GiftsIcons) do
    	for j = 1, table.getn(g_LandReward_GiftsIcons[i]) do
    		local	GiftItemID	=	-1
    		local	GiftItemNum	=	0
			if j > table.getn( g_LandReward_Gifts[i] ) then
    			g_LandReward_GiftsIcons[i][j]:Hide();
    		else
    			GiftItemID	=	g_LandReward_Gifts[i][j].GiftItemID
    			GiftItemNum	= 	g_LandReward_Gifts[i][j].num
    			local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
    			if theAction:GetID() ~= 0 then
    				g_LandReward_GiftsIcons[i][j]:SetActionItem(theAction:GetID());
    				g_LandReward_GiftsIcons[i][j]:Show();
    			end
    		end
    	end
    end	
end

function LandReward_Project_Clicked( btnId )

	if(btnId == g_LastClickedId) then
		for index=1,2 do
			if index==btnId then
				g_LandReward_Button[index]:SetCheck(1)
				g_LandReward_Frames[index]:Show();
			else
				g_LandReward_Button[index]:SetCheck(0)
				g_LandReward_Frames[index]:Hide();
			end	
		end
		return
	end
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
		for index=1,2 do
			if index==g_LastClickedId then
				g_LandReward_Button[index]:SetCheck(1)
				g_LandReward_Frames[index]:Show();
			else
				g_LandReward_Button[index]:SetCheck(0)
				g_LandReward_Frames[index]:Hide();
			end
		end
		PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
		return
	end
	g_ButtonLastTime = curTime;
	
	for index=1,2 do
		if index==btnId then
			g_LandReward_Button[index]:SetCheck(1)
			g_LandReward_Frames[index]:Show();
		else
			g_LandReward_Button[index]:SetCheck(0)
			g_LandReward_Frames[index]:Hide();
		end	
	end
	
	g_LastClickedId = btnId 
	
	if btnId == 1 then
		LandReward_GiftShow()
	elseif btnId == 2 then
		LandReward_Exchange_Show()
	else
		PushDebugMessage("error"); 
	end
	
	this:Show();
end

function LandReward_GiftShow()	
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenWindowRequest" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892503 );					-- 脚本编号
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
end

function LandReward_Exchange_Show()
	
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenWindowRequest" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892503 );					-- 脚本编号
		Set_XSCRIPT_Parameter(0,2)
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
end

function LandReward_DengLu_GetGift( btnId )

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GetLoginGift" )
			Set_XSCRIPT_ScriptID( 892503 )
			Set_XSCRIPT_Parameter(0,btnId)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	
end

function LandReward_Exchange_Click( btnId )

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ExchangeLoginGift" )
			Set_XSCRIPT_ScriptID( 892503 )
			Set_XSCRIPT_Parameter(0,btnId)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	
end

function LandReward_Frame_On_ResetPos()
  LandReward_Frame:SetProperty("UnifiedPosition", g_LandReward_Frame_UnifiedPosition);
end	

function LandReward_Close()
	g_LastClickedId = -1
	DataPool:Lua_ClearAccLoginActionItem();
	this:Hide();
end