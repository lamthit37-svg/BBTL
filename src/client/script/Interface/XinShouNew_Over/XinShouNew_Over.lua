local g_XinShouNew_Over_Frame_UnifiedPosition;

--各个功能的Frame
local g_XinShouNew_Over_Frames =
{
}

--===============================================
-- 这一段是为了动态显示Button Tips ---------begin
--===============================================
local g_XinShouNew_Over_Event = {
	[1] = {text="首充超值赠", isShow=0,},	 		--首充超值赠
	[2] = {text="充值超值赠",isShow=0,},  		--充值超值赠
};

--左侧Button 合集 加这个合集 是因为以后策划 想要某个特定的Button 上移
local g_XinShouNew_Over_Button =
{
}
local g_XinShouNew_Over_Tip =
{
}
local g_Button_StateTemp = {1,1}  --暂时的 后续改  先用
local g_Tips_StateTemp = {0,0}  --暂时的 后续改  先用
--===============================================
-- 这一段是为了动态显示Button Tips -----------end
--===============================================

local g_XinShouNew_Over_ButtonCDTime = 1; --按钮冷却时间
local g_XinShouNew_Over_ButtonLastTime = 0;
local g_XinShouNew_Over_LastClickedId = -1; --上次选中的选项
local g_XinShouNew_Over_EventIndex = -1 --当前选中的选项
--===============================================
-- 首充
--===============================================
--首充奖励物品配表
local g_XinShouNew_Over_ShouChong_Gifts = {
	[1] =   {GiftItemID = 10155006, num = 1,},
	[2] =   {GiftItemID = 39920503, num = 3,},
	[3] =   {GiftItemID = 30900077, num = 2,},
}
--奖励物品配表、 
local g_XinShouNew_Over_ShouChong_GiftsIcons = {

}
local g_XinShouNew_Over_ShouChong_ButtonState =0;
--
local g_XinShouNew_Over_ShouChong_LoadFirstTime =1;

local g_XinShouNew_Over_IsXinShouNew2023 = 0

--===============首充2023
--首充奖励物品配表
local g_XinShouNew_Over_ShouChong2_Gifts_2023 = {
	[1] = {
		[1] =   {GiftItemID = 10155006, num = 1},
		[2] =   {GiftItemID = 39920503, num = 3},
		[3] =   {GiftItemID = 39920977, num = 2},
	},
	[2] = {
		[1] =   {GiftItemID = 39920085, num = 20},
		[2] =   {GiftItemID = 39920382, num = 1},
		[3] =   {GiftItemID = 39920181, num = 1},
	},
	[3] = {
		[1] =   {GiftItemID = 39920977, num = 1},
		[2] =   {GiftItemID = 39920181, num = 1},
		[3] =   {GiftItemID = 39924018, num = 1},
	},
}

local g_XinShouNew_Over_ShouChong2_Gifts_2606S = {
	[1] = {
		{GiftItemID = 10155006, num = 1,bind =1},{GiftItemID = 30900077, num = 2,bind =0},
		{GiftItemID = 20109003, num = 3,bind =1},
	},
	[2] = {
			{GiftItemID = 20310168, num = 20,bind =1},{GiftItemID = 38001554, num = 1,bind =0},
			{GiftItemID = 30008027, num = 1,bind =1},
		},
	[3] = {
			{GiftItemID = 30900077, num = 1,bind =1},{GiftItemID = 30008027, num = 1,bind =0},
			{GiftItemID = 10146616, num = 1,bind =1},
	},	
}
local g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 =1;
local g_XinShouNew_Over_ShouChong2_CurExch_2023 = 0
--奖励物品配表
local g_XinShouNew_Over_ShouChong2_GiftsIcons_2023 = {}
local g_XinShouNew_Over_ShouChong2_BKImg_2023 = {}
local g_XinShouNew_Over_ShouChong2_ButtonState_2023 =0;
--
local g_XinShouNew_Over_ShouChong2_LastShow_2023 =0;


local g_XinShouNew_Over_ShouChong_BkgL = ""
local g_XinShouNew_Over_ShouChong_BkgR = ""

--===============================================
-- 充值超值赠
--===============================================
local g_XinShouNew_Over_SuperSaveUp_LoadFirstTime = 1
local g_XinShouNew_Over_SuperSaveUp_ScrollbarPosition = 0
--显示奖励物品配表
local g_XinShouNew_Over_SuperSaveUp_Gifts = {
	[1] = 	{
			{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920977, num = 2,}
		,},
	[2] =	{
			{GiftItemID = 39921376, num = 1,},{GiftItemID = 39920977, num = 3,},{ GiftItemID = 39920181, num = 2,}		 
		,},
	[3] =   {
			{GiftItemID = 39920977, num = 4,},{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920298, num = 1,}	 
		,},
	[4] = 	{
			{GiftItemID = 39920397, num = 1,},{GiftItemID = 39920396, num = 1,},{ GiftItemID = 39920383, num = 1,}
		,},
	[5] =	{
			{GiftItemID = 39920181, num = 2,},{GiftItemID = 39920163, num = 100,},{ GiftItemID = 39920329, num = 5,}		 
		,},
	[6] =   {
			{GiftItemID = 39921379, num = 1,},{GiftItemID = 39920299, num = 1,},{GiftItemID = 39920490, num = 5,}	 
		,},
	[7] = 	{
			{GiftItemID = 39920181, num = 3,},{GiftItemID = 39920162, num = 100,},{ GiftItemID = 39920329, num = 10,}
		,},
	[8] =	{
			{GiftItemID = 39921360, num = 1,},{GiftItemID = 39920163, num = 200,},{ GiftItemID = 39920299, num = 2,}	 
		,},
	[9] =   {
			{GiftItemID = 39920181, num = 4,},{GiftItemID = 39920162, num = 200,},{GiftItemID = 39920329, num = 20,}	 
		,},
	[10] =   {
			{GiftItemID = 39921380, num = 1,},{GiftItemID = 39921668, num = 1,},{GiftItemID = 39920981, num = 1,}	 
		,},
}
--Button
local g_XinShouNew_Over_SuperSaveUp_Buttons = {
}
local g_XinShouNew_Over_SuperSaveUp_ButtonState = {
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
local g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition =
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
local g_XinShouNew_Over_SuperSaveUp_Cost =0;
local g_XinShouNew_Over_SuperSaveUp_Exch =0;
local g_XinShouNew_Over_SuperSaveUp_ContentButton = {}
local g_XinShouNew_Over_SuperSaveUp_CurrentSelect = 0;
--
--set:ZhizunHaoli","")
local g_XinShouNew_Over_LimitedSaveUp_GiftsImage = {
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

--
--===============================================
-- PreLoad()
--===============================================
function XinShouNew_Over_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("SHOUCHONGJIANGLI_XIN_OPEN",true)		--
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
	this:RegisterEvent("UNIT_LEVEL",false)			-- 【新服欢乐月·升级送好礼】刷新界面,玩家升级的时候需要刷新界面
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)		-- 进入游戏世界
end

--===============================================
-- OnEvent()
--===============================================
function XinShouNew_Over_OnEvent(event)
	if (event == "SHOUCHONGJIANGLI_XIN_OPEN") then
		--XinShouNew_Over_Open()
	elseif (event == "PLAYER_LEAVE_WORLD") then
		XinShouNew_Over_Close()
	elseif (event == "ADJEST_UI_POS") then
		XinShouNew_Over_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		XinShouNew_Over_On_ResetPos()
	elseif (event == "UNIT_LEVEL" ) then
	elseif (event == "PLAYER_ENTERING_WORLD" ) then				 
		g_XinShouNew_Over_ShouChong_LoadFirstTime =1;
		g_XinShouNew_Over_ShouChong2_LastShow_2023 = 0
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89267502) then
		--判断是不是新的afterxinshoucarnival
		g_XinShouNew_Over_IsXinShouNew2023 = Get_XParam_INT( 4 );
		XinShouNew_Over_Open(g_XinShouNew_Over_IsXinShouNew2023)
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 89267602) then   
		XinShouNew_Over_ShouChong_UpdateButtonState()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89269002 ) then  
	  XinShouNew_Over_SuperSaveUp_UpdateInfo()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89267503 ) then  
	  XinShouNew_Over_RefreshWindow()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 99841102) then   

		XinShouNew_Over_ShouChong2_UpdateButtonState()	
	end
end

--===============================================
-- OnLoad()
--===============================================
function XinShouNew_Over_OnLoad()
	g_XinShouNew_Over_Frame_UnifiedPosition = XinShouNew_Over_Frame:GetProperty("UnifiedPosition")
	XinShouNew_Over_SetButtonPos()
end
--===============================================
-- SetButtonPos()
--===============================================
function XinShouNew_Over_SetButtonPos()
	g_XinShouNew_Over_Frames =
	{
		[1] = XinShouNew_Over_SaveUp_RewardFrame,
		[2] = XinShouNew_Over_Supe_ValueFrame,
	}
	g_XinShouNew_Over_Button[1] 	= XinShouNew_Over_Button01; --
	g_XinShouNew_Over_Button[2] 	= XinShouNew_Over_Button02; --

	g_XinShouNew_Over_Tip[1] 		= XinShouNew_Over_Button01tips;
	g_XinShouNew_Over_Tip[2] 		= XinShouNew_Over_Button02tips;
	--首充
	g_XinShouNew_Over_ShouChong_GiftsIcons[1] = XinShouNew_Over_SaveUp_Right_ShowA;
	g_XinShouNew_Over_ShouChong_GiftsIcons[2] = XinShouNew_Over_SaveUp_Right_ShowB;
	g_XinShouNew_Over_ShouChong_GiftsIcons[3] = XinShouNew_Over_SaveUp_Right_ShowC;
	
	g_XinShouNew_Over_ShouChong2_GiftsIcons_2023[1] = XinShouNew_Over_SaveUp_Right_ShowA;
	g_XinShouNew_Over_ShouChong2_GiftsIcons_2023[2] = XinShouNew_Over_SaveUp_Right_ShowB;
	g_XinShouNew_Over_ShouChong2_GiftsIcons_2023[3] = XinShouNew_Over_SaveUp_Right_ShowC;
	
	g_XinShouNew_Over_ShouChong2_BKImg_2023[1] = XinShouNew_Over_SaveUpBK1
	g_XinShouNew_Over_ShouChong2_BKImg_2023[2] = XinShouNew_Over_SaveUpBK2
	g_XinShouNew_Over_ShouChong2_BKImg_2023[3] = XinShouNew_Over_SaveUpBK3
	
	g_XinShouNew_Over_ShouChong_BkgL = XinShouNew_Over_SaveUpBK_L
	g_XinShouNew_Over_ShouChong_BkgR = XinShouNew_Over_SaveUpBK_R
	
end
--===============================================
-- Close()
--===============================================
function XinShouNew_Over_Close()
	g_XinShouNew_Over_ShouChong_LoadFirstTime = 1
	g_XinShouNew_Over_ShouChong2_LastShow_2023 = 0
	g_XinShouNew_Over_LastClickedId = -1
	g_XinShouNew_Over_ButtonLastTime = 0;
	this:Hide()
end
--===============================================
-- ResetPos()
--===============================================
function XinShouNew_Over_On_ResetPos()
	XinShouNew_Over_Frame:SetProperty("UnifiedPosition", g_XinShouNew_Over_Frame_UnifiedPosition)
end

--===============================================
-- Open()
--===============================================
function  XinShouNew_Over_Open(isXinShouNew2023)
	for index=1,table.getn(g_XinShouNew_Over_Event) do
		local event = g_XinShouNew_Over_Event[index]
		event.isShow = 0
	end

	for index=1,table.getn(g_XinShouNew_Over_Button) do
		g_XinShouNew_Over_Button[index]:Hide()
	end
	for index=1,table.getn(g_Button_StateTemp) do 
			g_Button_StateTemp[index]			= Get_XParam_INT(index-1) 
	end
	
	for index=1,table.getn(g_Tips_StateTemp) do 
			g_Tips_StateTemp[index]				= Get_XParam_INT(index+2-1) 
	end
	
	local buttonId = 1
	for index=1,table.getn(g_XinShouNew_Over_Event) do
		local isButtonShow = g_Button_StateTemp[index]
		local isTipsShow   = g_Tips_StateTemp[index]
		local event  = g_XinShouNew_Over_Event[index]
		if isButtonShow == 1 then
			g_XinShouNew_Over_Button[buttonId]:SetText(event.text)
			g_XinShouNew_Over_Button[buttonId]:Hide()
			if isTipsShow == 1 then
				g_XinShouNew_Over_Tip[buttonId]:Hide()
			end
			event.isShow = 1
			buttonId = buttonId+1
		end
	end 
	
	--PushDebugMessage("XinShouNew_Over_Open "..isXinShouNew2023)
	--判断是不是新的afterxinshoucarnival
	if isXinShouNew2023 == 1 then
		XinShouNew_Over_Project_Clicked( 3 )
	else
		XinShouNew_Over_Project_Clicked( 1 )
	end

	this:Show()

end

--===============================================
-- Clicked() 找到真正的函数
--===============================================
function XinShouNew_Over_Project_Clicked(clickId)
		
	local g_EventIndex = 1
	
	if(clickId == g_XinShouNew_Over_LastClickedId) then
		return
	end
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_XinShouNew_Over_ButtonLastTime < g_XinShouNew_Over_ButtonCDTime * 1000) then
   	for index=1,table.getn(g_XinShouNew_Over_Button) do
			if index==g_XinShouNew_Over_LastClickedId then
				g_XinShouNew_Over_Button[index]:SetCheck(1)
			else
				g_XinShouNew_Over_Button[index]:SetCheck(0)
			end
		end
   	PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
		return
	end
	g_XinShouNew_Over_ButtonLastTime = curTime;

	local buttonId = 0
	for index=1,table.getn(g_XinShouNew_Over_Event) do
		local event = g_XinShouNew_Over_Event[index]
		if event.isShow == 1 then
			buttonId = buttonId + 1
			if buttonId == clickId then
				g_EventIndex = index
				break
			end
		end
	end

	for index=1,table.getn(g_XinShouNew_Over_Button) do
		if index==clickId then
			g_XinShouNew_Over_Button[index]:SetCheck(1)
		else
			g_XinShouNew_Over_Button[index]:SetCheck(0)
		end
	end
	g_XinShouNew_Over_LastClickedId = clickId
	
	for index=1,table.getn(g_XinShouNew_Over_Frames) do
		if index~=g_EventIndex then
			g_XinShouNew_Over_Frames[index]:Hide()
		else
			g_XinShouNew_Over_Frames[index]:Show()
		end
	end 
	---if g_EventIndex==1 then
	---	XinShouNew_Over_ShouChong_Show() --首充超值赠
	---elseif g_EventIndex==2 then
	---	XinShouNew_Over_SuperSaveUp_Show() --充值赠好礼
	---elseif g_EventIndex==3 then
	---
	
	if clickId == 1 then
		XinShouNew_Over_ShouChong_Show() --首充超值赠
	elseif clickId==3 then
		XinShouNew_Over_ShouChong2_Show() --首充超值赠2023
	else
		return
	end
	this:Show()
end

--===============================================
--  
--===============================================
function XinShouNew_Over_RefreshWindow()
	--for index=1,table.getn(g_Button_StateTemp) do 
	--		g_Button_StateTemp[index]			= Get_XParam_INT(index-1) 
	--end
	
	for index=1,table.getn(g_Tips_StateTemp) do 
			g_Tips_StateTemp[index]				= Get_XParam_INT(index+2-1) 
	end
	
	local buttonId = 1
	for index=1,table.getn(g_XinShouNew_Over_Event) do
		local isButtonShow = g_Button_StateTemp[index]
		local isTipsShow   = g_Tips_StateTemp[index]
		local event  = g_XinShouNew_Over_Event[index]
		if isButtonShow == 1 then
			g_XinShouNew_Over_Button[buttonId]:SetText(event.text)
			g_XinShouNew_Over_Button[buttonId]:Hide()
			if isTipsShow == 1 then
				g_XinShouNew_Over_Tip[buttonId]:Hide()
			else
				g_XinShouNew_Over_Tip[buttonId]:Hide()
			end
			event.isShow = 1
			buttonId = buttonId+1
		end
	end
	 
end

--===============================================
-- 首充享好礼-begin
--===============================================

function XinShouNew_Over_ShouChong_Show(ShowTime)
	XinShouNew_Over_ShouChong_UpdateButtonReq();
	XinShouNew_Over_ShouChong_FlushWindow()		--在服务器数据返回之前,根据数据初始值,先初步构建界面
end
function XinShouNew_Over_ShouChong_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetSaveUpGiftsButtonState" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892676 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function XinShouNew_Over_ShouChong_UpdateButtonState()
	local ButtonState = Get_XParam_INT(0)
	g_XinShouNew_Over_ShouChong_ButtonState = ButtonState
	XinShouNew_Over_ShouChong_FlushWindow()
end
function XinShouNew_Over_ShouChong_FlushWindow()
	--如果是第一次调用此函数,需要将物品奖励加载到显示界面上
	if g_XinShouNew_Over_ShouChong_LoadFirstTime == 1 then

	---	XinShouNew_Over_SaveUp_Right_Button1:SetEvent("Clicked", "XinShouNew_Over_ShouChong_GetGiftsForCostYuanBao()")

		for i = 1,  table.getn(g_XinShouNew_Over_ShouChong_Gifts) do
			local GiftItemID	=		g_XinShouNew_Over_ShouChong_Gifts[i].GiftItemID
			local GiftItemNum	= 	g_XinShouNew_Over_ShouChong_Gifts[i].num
			local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
			if theAction:GetID() ~= 0 then
				g_XinShouNew_Over_ShouChong_GiftsIcons[i]:SetActionItem(theAction:GetID());
				g_XinShouNew_Over_ShouChong_GiftsIcons[i]:Show();
			end
		end
		--tongyong
		g_XinShouNew_Over_ShouChong_BkgL : SetProperty("Image","set:XSYNewBK01 image:XSYNewBK_ShouChong_L")
		g_XinShouNew_Over_ShouChong_BkgR : SetProperty("Image","set:XSYNewBK02 image:XSYNewBK_ShouChong_R")	
		
		g_XinShouNew_Over_ShouChong_LoadFirstTime = 0
	end
	
	XinShouNew_Over_SaveUpAllBK:Hide()
	
	if g_XinShouNew_Over_ShouChong_ButtonState == 0 then
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("NormalImage","set:XSYNew01 image:XSYNew_LKCZ_Normal")
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("HoverImage" ,"set:XSYNew01 image:XSYNew_LKCZ_Hover")
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("PushedImage","set:XSYNew01 image:XSYNew_LKCZ_Pushed")
		XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_180111_55}", 0))
		XinShouNew_Over_SaveUp_Right_Button1 : Enable()
	elseif g_XinShouNew_Over_ShouChong_ButtonState == 1 then
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("NormalImage","set:XSYNew01 image:XSYNew_LQCZJL_Normal")
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("HoverImage" ,"set:XSYNew01 image:XSYNew_LQCZJL_Hover")
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("PushedImage","set:XSYNew01 image:XSYNew_LQCZJL_Pushed")
		XinShouNew_Over_SaveUp_Right_Button1 : Show()
		XinShouNew_Over_SaveUp_Right_Button1 : Enable()
		XinShouNew_Over_SaveUp_Right_ConditionText:SetText("#{XSJNH_180111_56}")
	elseif g_XinShouNew_Over_ShouChong_ButtonState == 2 then
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("DisabledImage","set:XSYNew01 image:XSYNew_LQCZJL_Disabled")
		XinShouNew_Over_SaveUp_Right_Button1 : Disable()
		XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_180111_56}", 200))
	end
end
function XinShouNew_Over_ShouChong_GetGiftsForCostYuanBao()

	if g_XinShouNew_Over_IsXinShouNew2023 == 1 then
		XinShouNew_Over_ShouChong2_GetGiftsForCostYuanBao()
		return
	end

	--前往充值
	if g_XinShouNew_Over_ShouChong_ButtonState == 0 then
		local bflg =YuanbaoExange()
	  if bflg~= 1 then
	   return ;
	  end
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("AskOpenDuihuanWindow");
		Set_XSCRIPT_ScriptID(181000);
		--Set_XSCRIPT_Parameter(2,shopB);
		Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
		return
	end
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForSaveUp" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892676 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()
end
--===============================================
-- 首充享好礼 -end
--===============================================



function XinShouNew_Over_ShouChong2_Show(ShowTime)
	XinShouNew_Over_ShouChong2_UpdateButtonReq();
	XinShouNew_Over_ShouChong2_FlushWindow()		--在服务器数据返回之前,根据数据初始值,先初步构建界面
end
function XinShouNew_Over_ShouChong2_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetSaveUpGiftsButtonState_2023" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998411 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function XinShouNew_Over_ShouChong2_UpdateButtonState()
	local buttonState = Get_XParam_INT(0)
	local curLevel = Get_XParam_INT(1)
	local curExch = Get_XParam_INT(2)
	g_XinShouNew_Over_ShouChong2_ButtonState_2023 = buttonState
	g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 = curLevel
	g_XinShouNe_Over_ShouChong2_CurExch_2023 = curExch
		
	XinShouNew_Over_ShouChong2_FlushWindow()
end

---!!!reloadscript =XinShouNew_Over
function XinShouNew_Over_ShouChong2_FlushWindow()
	
	if g_XinShouNew_Over_ShouChong2_LastShow_2023 == 0 then
		---XinShouNew_Over_SaveUp_Right_Button1:SetEvent("Clicked", "XinShouNew_Over_ShouChong2_GetGiftsForCostYuanBao()")
	end
	
	if g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 < 0 or g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 > 3 then
		g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 = 1
	end

	---XinShouNew_SaveUp2_Right_ConditionText:Hide()
	--如果是第一次调用此函数,需要将物品奖励加载到显示界面上
	if g_XinShouNew_Over_ShouChong2_LastShow_2023 == 0 or g_XinShouNew_Over_ShouChong2_LastShow_2023 ~= g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 then
		local GiftInfo = g_XinShouNew_Over_ShouChong2_Gifts_2023[g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023]
		if Player:GetData("Is2606S") == 1 then
			GiftInfo = g_XinShouNew_Over_ShouChong2_Gifts_2606S[g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023]
		end
		for i = 1,  table.getn(GiftInfo) do
			local GiftItemID	=	GiftInfo[i].GiftItemID
			local GiftItemNum	= 	GiftInfo[i].num
			local theAction = DataPool:CreateBindActionItemForShow(GiftItemID, GiftItemNum)
			if theAction:GetID() ~= 0 then
				g_XinShouNew_Over_ShouChong2_GiftsIcons_2023[i]:SetActionItem(theAction:GetID())
				g_XinShouNew_Over_ShouChong2_GiftsIcons_2023[i]:Show();
			end
		end
		g_XinShouNew_Over_ShouChong2_LastShow_2023 = g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023
		--tongyong
		g_XinShouNew_Over_ShouChong_BkgL : SetProperty("Image","set:XSYNewBK01 image:XSYNewBK_ShouChong_L")
		g_XinShouNew_Over_ShouChong_BkgR : SetProperty("Image","set:XSYNewBK02 image:XSYNewBK_ShouChong_R")	
	end

	for i = 1,3 do
		g_XinShouNew_Over_ShouChong2_BKImg_2023[i]:Hide()	
	end
	g_XinShouNew_Over_ShouChong2_BKImg_2023[g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023]:Show()	

	if g_XinShouNew_Over_ShouChong2_ButtonState_2023 == 0 then  --立刻兑换元宝
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("NormalImage","set:XSYNew01 image:XSYNew_LKCZ_Normal")
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("HoverImage" ,"set:XSYNew01 image:XSYNew_LKCZ_Hover")
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("PushedImage","set:XSYNew01 image:XSYNew_LKCZ_Pushed")
		if g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 == 1 then
			XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_180111_55}", 0))
		elseif g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 == 2 then
			XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_230209_07}", g_XinShouNe_Over_ShouChong2_CurExch_2023))
		elseif g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 == 3 then
			XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_230209_08}", g_XinShouNe_Over_ShouChong2_CurExch_2023))
		end

		XinShouNew_Over_SaveUp_Right_Button1 : Enable()
	elseif g_XinShouNew_Over_ShouChong2_ButtonState_2023 == 1 then  --领奖

		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("NormalImage","set:XSYNew01 image:XSYNew_LQCZJL_Normal")
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("HoverImage" ,"set:XSYNew01 image:XSYNew_LQCZJL_Hover")
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("PushedImage","set:XSYNew01 image:XSYNew_LQCZJL_Pushed")
		XinShouNew_Over_SaveUp_Right_Button1 : Show()
		XinShouNew_Over_SaveUp_Right_Button1 : Enable()
		if g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 == 1 then
			XinShouNew_Over_SaveUp_Right_ConditionText:SetText("#{XSJNH_180111_56}")
		elseif g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 == 2 then
			XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_230209_09}", 800))
		elseif g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 == 3 then
			XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_230209_10}", 1600))
		end
	elseif g_XinShouNew_Over_ShouChong2_ButtonState_2023 == 2 then  --不可用
		XinShouNew_Over_SaveUp_Right_Button1 : SetProperty("DisabledImage","set:XSYNew01 image:XSYNew_LQCZJL_Disabled")
		XinShouNew_Over_SaveUp_Right_Button1 : Disable()
		if g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 == 1 then
			XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_180111_56}", 200))
		elseif g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 == 2 then
			XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_230209_07}", 800))
		elseif g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 == 3 then
			XinShouNew_Over_SaveUp_Right_ConditionText:SetText(ScriptGlobal_Format("#{XSJNH_230209_10}", 1600))
		end
	end

end
function XinShouNew_Over_ShouChong2_GetGiftsForCostYuanBao()

	--前往充值
	if g_XinShouNew_Over_ShouChong2_ButtonState_2023 == 0 then
		local bflg =YuanbaoExange()
		if bflg~= 1 then
			return ;
		end
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("AskOpenDuihuanWindow");
		Set_XSCRIPT_ScriptID(181000);
		--Set_XSCRIPT_Parameter(2,shopB);
		Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
		return
	end
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForSaveUp_2023" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 998411 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );		-- 参数一
		Set_XSCRIPT_Parameter( 1, g_XinShouNew_Over_ShouChong2_CurGiftLevel_2023 );		-- 当前奖励等级
		Set_XSCRIPT_ParamCount( 2 );				-- 参数个数
	Send_XSCRIPT()
end

--===============================================
-- 首充享好礼2023 -end
--===============================================




--===============================================
-- 充值超值赠-begin
--===============================================
function XinShouNew_Over_SuperSaveUp_LoadControl()
end

function XinShouNew_Over_SuperSaveUp_Show()
	XinShouNew_Over_SuperSaveUp_UpdateButtonReq(); 
end
function XinShouNew_Over_SuperSaveUp_UpdateButtonReq()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetSuperSaveUpGiftsInfo" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892690 );				-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );				-- 参数个数
	Send_XSCRIPT()
end
function XinShouNew_Over_SuperSaveUp_UpdateInfo() 
	g_XinShouNew_Over_SuperSaveUp_Exch  = Get_XParam_INT(0)
	g_XinShouNew_Over_SuperSaveUp_Cost  = Get_XParam_INT(1)
	for i=1,table.getn(g_XinShouNew_Over_SuperSaveUp_ButtonState) do
		g_XinShouNew_Over_SuperSaveUp_ButtonState[i] = Get_XParam_INT(i+1)
	end
	g_XinShouNew_Over_SuperSaveUp_ScrollbarPosition = XinShouNew_Over_Supe_MianList:GetVertScrollbarPosition()
	XinShouNew_Over_SuperSaveUp_FlushWindow()
end
function XinShouNew_Over_SuperSaveUp_FlushWindow()
	XinShouNew_Over_SuperSaveUp_CleanActionItemInfo()
	XinShouNew_Over_Supe_MianList:CleanAllElement("XinShouNew_Over") 
	local nCurIndex = 0
	for i = 1,  table.getn(g_XinShouNew_Over_SuperSaveUp_Gifts) do
		local ItemBar = XinShouNew_Over_Supe_MianList:AddItemElement( "SupeValueButton", "LEFT", "XinShouNew_Over","" ,"")
		if ItemBar == nil then
			return
		end
		ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection")
		ItemBar:Setm_newImage(1,g_XinShouNew_Over_LimitedSaveUp_GiftsImage[i].Set, g_XinShouNew_Over_LimitedSaveUp_GiftsImage[i].Image)
		
		for j = 1,  table.getn(g_XinShouNew_Over_SuperSaveUp_Gifts[i]) do
			local itemButton  = 	ItemBar:GetLuaActionButton(j,"XinShouNew_Over")
			local GiftItemID	=		g_XinShouNew_Over_SuperSaveUp_Gifts[i][j].GiftItemID
			local GiftItemNum	= 	g_XinShouNew_Over_SuperSaveUp_Gifts[i][j].num
			local theAction 	= 	DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
			if theAction:GetID() ~= 0 then 
				itemButton:SetActionItem(theAction:GetID())
			end
		end
		
		if i == 1 then
			ItemBar:Setm_newImageHide(4)
		end
		--未达成
		if g_XinShouNew_Over_SuperSaveUp_ButtonState[i] == 0 then 
			--ItemBar:SetButton1Text("#{XSJNH_180111_75}")
			if g_XinShouNew_Over_SuperSaveUp_Exch < g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Exch then
				local Text1 = ScriptGlobal_Format("#{XSJNH_180111_71}", g_XinShouNew_Over_SuperSaveUp_Exch,g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Exch)
				ItemBar:Setm_newText(1,Text1)
			else
				local Text1 = ScriptGlobal_Format("#{XSJNH_180111_73}", g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Exch,g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Exch)
				ItemBar:Setm_newText(1,Text1)
			end
			if g_XinShouNew_Over_SuperSaveUp_Cost < g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Cost then
				local Text2 = ScriptGlobal_Format("#{XSJNH_180111_72}", g_XinShouNew_Over_SuperSaveUp_Cost,g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Cost)
				ItemBar:Setm_newText(2,Text2)
			else
				local Text2 = ScriptGlobal_Format("#{XSJNH_180111_74}", g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Cost,g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Cost)
				ItemBar:Setm_newText(2,Text2)
			end
			ItemBar:Setm_newImage(7,"CommonFrame34", "SignSummerButton_Weidacheng")
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImageShow(7)
		--可以领取
		elseif g_XinShouNew_Over_SuperSaveUp_ButtonState[i] == 1 then 
			--ItemBar:SetButton1Text("#{XSJNH_180111_79}")
			local Text1 = ScriptGlobal_Format("#{XSJNH_180111_73}", g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Exch,g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Exch)
			ItemBar:Setm_newText(1,Text1)
			local Text2 = ScriptGlobal_Format("#{XSJNH_180111_74}", g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Cost,g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Cost)
			ItemBar:Setm_newText(2,Text2)
			--ItemBar:SetButton1Show()
			ItemBar:Setm_newImageHide(7)
			--已经领取
			if nCurIndex == 0 then
				nCurIndex = i
			end
		elseif g_XinShouNew_Over_SuperSaveUp_ButtonState[i] == 2 then  
			local Text1 = ScriptGlobal_Format("#{XSJNH_180111_73}", g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Exch,g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Exch)
			ItemBar:Setm_newText(1,Text1)
			local Text2 = ScriptGlobal_Format("#{XSJNH_180111_74}", g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Cost,g_XinShouNew_Over_SuperSaveUp_GetGiftsCondition[i].Cost)
			ItemBar:Setm_newText(2,Text2)
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImage(7,"CommonFrame34", "SignSummerButton_Yilingqu")
			ItemBar:Setm_newImageShow(7)
		end
		table.insert(g_XinShouNew_Over_SuperSaveUp_ContentButton, ItemBar) 
	end
	 
	if nCurIndex ~= 0 and g_XinShouNew_Over_SuperSaveUp_LoadFirstTime == 1 then
		g_XinShouNew_Over_SuperSaveUp_LoadFirstTime = 0;
		g_XinShouNew_Over_SuperSaveUp_CurrentSelect = nCurIndex  
		XinShouNew_Over_SuperSaveUp_SetButtonSelected(nCurIndex)
		XinShouNew_Over_Supe_MianList:Flash()
		local curPos = XinShouNew_Over_SuperSaveUp_CalcListScrollPos(g_XinShouNew_Over_SuperSaveUp_CurrentSelect)
		XinShouNew_Over_Supe_MianList:SetVertScrollbarPosition(curPos)
	else
		XinShouNew_Over_Supe_MianList:Flash() 
		XinShouNew_Over_Supe_MianList:SetVertScrollbarPosition(g_XinShouNew_Over_SuperSaveUp_ScrollbarPosition)
	end
end
function XinShouNew_Over_SuperSaveUp_CleanActionItemInfo()
	local nListCount = table.getn(g_XinShouNew_Over_SuperSaveUp_ContentButton)
	if nListCount <= 0 then
		g_XinShouNew_Over_SuperSaveUp_ContentButton = {}
		return
	end
	for i = 1, nListCount do
		if nil ~= g_XinShouNew_Over_SuperSaveUp_ContentButton[i] then
			for j = 1, 3 do
				local itemButton = g_XinShouNew_Over_SuperSaveUp_ContentButton[i]:GetLuaActionButton(j,"XinShouNew_Over")
				if nil ~= itemButton then
					itemButton:SetActionItem(-1)
				end
			end
		end
	end 
	g_XinShouNew_Over_SuperSaveUp_ContentButton = {}
end
function XinShouNew_Over_SuperSaveUp_OnItemClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		XinShouNew_Over_SuperSaveUp_SetButtonSelected(nIndex + 1)
		XinShouNew_Over_Supe_MianList:Flash()
		g_XinShouNew_Over_SuperSaveUp_CurrentSelect = nIndex 
	end
	  
end

function XinShouNew_Over_SuperSaveUp_OnButton1Click()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) 
	if nIndex >= 0 then 
		XinShouNew_Over_SuperSaveUp_SetButtonSelected(nIndex + 1)
		XinShouNew_Over_Supe_MianList:Flash()
		g_XinShouNew_Over_SuperSaveUp_CurrentSelect = nIndex+1  
		XinShouNew_Over_SuperSaveUp_GetGiftsForCostYuanBao(g_XinShouNew_Over_SuperSaveUp_CurrentSelect)
	end
end
function XinShouNew_Over_SuperSaveUp_GetGiftsForCostYuanBao( Index )
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetGiftsForSuperSaveUp" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892690 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, Index );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );					-- 参数个数
	Send_XSCRIPT()
end
function XinShouNew_Over_SuperSaveUp_SetButtonSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_XinShouNew_Over_SuperSaveUp_ContentButton) do
		if nil ~= g_XinShouNew_Over_SuperSaveUp_ContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_XinShouNew_Over_SuperSaveUp_ContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_XinShouNew_Over_SuperSaveUp_ContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

function XinShouNew_Over_SuperSaveUp_CalcListScrollPos(SelectIdx)
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
