local g_NationalDay_Fund_Frame_UnifiedPosition
local g_NationalDay_Fund_ServerTime;
local g_NationalDay_Fund_MemberShip =0;
local g_NationalDay_Fund_BtnStatus =0;
local g_NationalDay_Fund_NeedYuanBao =2580;
local g_NationalDay_Fund_Status = {    
};
local g_NationalDay_Fund_ContentButton = {}
--显示奖励物品配表
local g_NationalDay_Fund_Gifts = {
	[1] = 	{
			GiftItemID = 39921844, num = 1
		,},
	[2] =	{
			GiftItemID = 39921817, num = 55
		,},
	[3] =   {
			GiftItemID = 39921817, num = 55
		,},
	[4] = 	{
			GiftItemID = 39921817, num = 55
		,},
	[5] =	{
			GiftItemID = 39921817, num = 55
		,}, 
	[6] =	{
			GiftItemID = 39921818, num = 1
		,},
}

local g_NationalDay_Fund_Control ={
	ActionButton= {},
	Mark ={},
	Tips ={},
	NormalImage ={},
	FlashImage ={},
	Text={},
}

local g_NationDay_Fund_Text ={
    [1] = "#{GQJJ_190723_21}",
    [2] = "#{GQJJ_190723_21}",
    [3] = "#{GQJJ_190723_22}",
    [4] = "#{GQJJ_190723_23}",
    [5] = "#{GQJJ_190723_24}", 
}

local g_NationalDay_Fund_ScrollbarPosition;
local g_NationalDay_Fund_CurrentSelect = 0;
function NationalDay_Fund_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false) 
    this:RegisterEvent("PLAYER_LEAVE_WORLD") -- 离开场景
    this:RegisterEvent("ADJEST_UI_POS", false) -- 游戏窗口尺寸发生了变化
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false) -- 游戏分辨率发生了变化
    this:RegisterEvent("UNIT_LEVEL", false)
    this:RegisterEvent("PLAYER_ENTERING_WORLD", false) -- 进入游戏世界
end
--===============================================
-- OnEvent()
--===============================================
function NationalDay_Fund_OnEvent(event)
    if (event == "UI_COMMAND" and tonumber(arg0) == 89316601) then
        NationalDay_Fund_Open()
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 89316603) and this:IsVisible() then
        NationalDay_Fund_Refresh()
    elseif (event == "PLAYER_LEAVE_WORLD") then
        NationalDay_Fund_Close()
    elseif (event == "ADJEST_UI_POS") then
        NationalDay_Fund_On_ResetPos()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        NationalDay_Fund_On_ResetPos()
    elseif (event == "UNIT_LEVEL") then

    elseif (event == "PLAYER_ENTERING_WORLD") then -- 
        
    end
end

--===============================================
-- OnLoad()
--===============================================
function NationalDay_Fund_OnLoad()
	g_NationalDay_Fund_Frame_UnifiedPosition = NationalDay_FundFrame:GetProperty("UnifiedPosition") 

	g_NationalDay_Fund_Control.ActionButton[1] = NationalDay_Fund_Gift1
	g_NationalDay_Fund_Control.ActionButton[2] = NationalDay_Fund_Gift2
	g_NationalDay_Fund_Control.ActionButton[3] = NationalDay_Fund_Gift3
	g_NationalDay_Fund_Control.ActionButton[4] = NationalDay_Fund_Gift4
	g_NationalDay_Fund_Control.ActionButton[5] = NationalDay_Fund_Gift5 
	g_NationalDay_Fund_Control.ActionButton[6] = NationalDay_Fund_ListTopItem

	g_NationalDay_Fund_Control.Mark[1] = NationalDay_Fund_Gift1Mark
	g_NationalDay_Fund_Control.Mark[2] = NationalDay_Fund_Gift2Mark
	g_NationalDay_Fund_Control.Mark[3] = NationalDay_Fund_Gift3Mark
	g_NationalDay_Fund_Control.Mark[4] = NationalDay_Fund_Gift4Mark
	g_NationalDay_Fund_Control.Mark[5] = NationalDay_Fund_Gift5Mark 
	g_NationalDay_Fund_Control.Mark[6] = NationalDay_Fund_ListTopItemMark

	g_NationalDay_Fund_Control.Tips[1] = NationalDay_Fund_Gift1_Tips
	g_NationalDay_Fund_Control.Tips[2] = NationalDay_Fund_Gift2_Tips
	g_NationalDay_Fund_Control.Tips[3] = NationalDay_Fund_Gift3_Tips
	g_NationalDay_Fund_Control.Tips[4] = NationalDay_Fund_Gift4_Tips
	g_NationalDay_Fund_Control.Tips[5] = NationalDay_Fund_Gift5_Tips 
	g_NationalDay_Fund_Control.Tips[6] = NationalDay_Fund_ListTopItem_Tips

	g_NationalDay_Fund_Control.NormalImage[1] = NationalDay_Fund_Gift1Normal
	g_NationalDay_Fund_Control.NormalImage[2] = NationalDay_Fund_Gift2Normal
	g_NationalDay_Fund_Control.NormalImage[3] = NationalDay_Fund_Gift3Normal
	g_NationalDay_Fund_Control.NormalImage[4] = NationalDay_Fund_Gift4Normal
	g_NationalDay_Fund_Control.NormalImage[5] = NationalDay_Fund_Gift5Normal 
	g_NationalDay_Fund_Control.NormalImage[6] = NationalDay_Fund_ListTopItemBK_Normal

	g_NationalDay_Fund_Control.FlashImage[1] = NationalDay_Fund_Gift1Light
	g_NationalDay_Fund_Control.FlashImage[2] = NationalDay_Fund_Gift2Light
	g_NationalDay_Fund_Control.FlashImage[3] = NationalDay_Fund_Gift3Light
	g_NationalDay_Fund_Control.FlashImage[4] = NationalDay_Fund_Gift4Light
	g_NationalDay_Fund_Control.FlashImage[5] = NationalDay_Fund_Gift5Light 
	g_NationalDay_Fund_Control.FlashImage[6] = NationalDay_Fund_ListTopItemBK_Light

	g_NationalDay_Fund_Control.Text[1] = NationalDay_Fund_Gift1Text
	g_NationalDay_Fund_Control.Text[2] = NationalDay_Fund_Gift2Text
	g_NationalDay_Fund_Control.Text[3] = NationalDay_Fund_Gift3Text
	g_NationalDay_Fund_Control.Text[4] = NationalDay_Fund_Gift4Text
	g_NationalDay_Fund_Control.Text[5] = NationalDay_Fund_Gift5Text 


end

--===============================================
-- Close()
--===============================================
function NationalDay_Fund_Close()
    this:Hide()
end
--===============================================
-- ResetPos()
--===============================================
function NationalDay_Fund_On_ResetPos()
    NationalDay_FundFrame:SetProperty("UnifiedPosition", g_NationalDay_Fund_Frame_UnifiedPosition)
end

--===============================================
-- Open()
--===============================================
function NationalDay_Fund_Open()
    this:Show() 
    NationalDay_Fund_Refresh()
end

function NationalDay_Fund_Refresh()
    
    g_NationalDay_Fund_ServerTime = Get_XParam_INT( 0 );
    g_NationalDay_Fund_MemberShip = Get_XParam_INT( 1 );
    g_NationalDay_Fund_BtnStatus  = Get_XParam_INT( 2 );
    
    for i = 1, 6 do
        g_NationalDay_Fund_Status[i] = Get_XParam_INT( i + 2 );
	end
	
	for i = 1, 6 do
		g_NationalDay_Fund_Control.Mark[i]:Hide()
		g_NationalDay_Fund_Control.Tips[i]:Hide()
		g_NationalDay_Fund_Control.FlashImage[i]:Hide()
	end
	
	for i = 1, 5 do
		g_NationalDay_Fund_Control.Text[i]:SetText(g_NationDay_Fund_Text[i])
	end
	 
	for i = 1, table.getn(g_NationalDay_Fund_Gifts) do
		--ActionButton
		local ItemID	=	g_NationalDay_Fund_Gifts[i].GiftItemID
		local ItemNum	= 	g_NationalDay_Fund_Gifts[i].num
		local theAction = 	DataPool:CreateActionItemForShow(ItemID, ItemNum)
		if theAction:GetID() ~= 0 and g_NationalDay_Fund_Control.ActionButton[i] ~= nil then
			g_NationalDay_Fund_Control.ActionButton[i]:SetActionItem(theAction:GetID())
			g_NationalDay_Fund_Control.ActionButton[i]:Show()
		end
		if i == 1 then
			NationalDay_Fund_Gift1Num:SetText(5200)
		end
		--未达成
		if g_NationalDay_Fund_Status[i] == 0 then
			g_NationalDay_Fund_Control.NormalImage[i]:Show()
		end
		--可领取
		if g_NationalDay_Fund_Status[i] == 1 then
			g_NationalDay_Fund_Control.FlashImage[i]:Show()
			g_NationalDay_Fund_Control.Tips[i]:Show()
			g_NationalDay_Fund_Control.NormalImage[i]:Hide()
		end
		--已领取
		if g_NationalDay_Fund_Status[i] == 2 then
			g_NationalDay_Fund_Control.Mark[i]:Show() 
			g_NationalDay_Fund_Control.NormalImage[i]:Show() 
		end
	end

	--购买
    if g_NationalDay_Fund_BtnStatus == 0 then 
		NationalDay_Fund_BuyBtn:Enable() 
		--设置图片
		NationalDay_Fund_BuyBtn:SetProperty("NormalImage", "set:NationalDay2 image:BuyBtn_Normal")
		NationalDay_Fund_BuyBtn:SetProperty("PushedImage", "set:NationalDay2 image:BuyBtn_Push")
		NationalDay_Fund_BuyBtn:SetProperty("HoverImage", "set:NationalDay2 image:BuyBtn_Hover") 
    elseif g_NationalDay_Fund_BtnStatus == 1 then 
		NationalDay_Fund_BuyBtn:SetProperty("DisabledImage", "set:NationalDay5 image:BuyBtn_Dis1") 
		NationalDay_Fund_BuyBtn:Disable()
    elseif g_NationalDay_Fund_BtnStatus == 2 then 
		NationalDay_Fund_BuyBtn:SetProperty("DisabledImage", "set:NationalDay5 image:BuyBtn_Dis2") 
		NationalDay_Fund_BuyBtn:Disable()
	end
	
end 
   

function NationalDay_Fund_GetGifts( Index )
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetPrize" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 893166 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, Index );		    -- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()
end
 

function NationalDay_Fund_Buy_Click()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "JoinMemberShip" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 893166 );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 0 );		        -- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()
end

function NationalDay_Fund_Help_Clicked()
    PushEvent("OPEN_NATIONAL_FUND_HELP")
end

function NationalDay_Fund_Shop_Click()
	-- 打开商店
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenNatiaonalShop")
		Set_XSCRIPT_ScriptID(893158) 
		Set_XSCRIPT_Parameter(0,1)
		Set_XSCRIPT_Parameter(1,1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
end