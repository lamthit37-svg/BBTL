local g_SpecialServer_MBuy_Frame_UnifiedPosition
local g_SpecialServer_MBuy_ItemIndex = 0 
local g_SpecialServer_MBuy_remain_num = 0 
local g_SpecialServer_MBuy_CurDaiBi = 0 
local g_SpecialServer_MBuy_gift = { 
    [1] = {
        id=10147013, num=1, costdaibi=1000, limit=1,
    },
    [7] = {
        id=20700063, num=1, costdaibi=5, limit=300,
    },
    [6] = {
        id=20700055, num=1, costdaibi=10, limit=150,
    },
    [5] = {
        id=20310168, num=1, costdaibi=25, limit=10,
    },
    [4] = {
        id=38001595, num=1, costdaibi=50, limit=10,
    },
    [3] = {
        id=20502003, num=1, costdaibi=500, limit=2,
    }, 
    [2] = {
        id=20501003, num=1, costdaibi=500, limit=2,
    }, 
}
local g_SpecialServer_objCared = -1;
--===============================================
-- OnLoad()
--===============================================
function SpecialServer_MBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	--逻辑相关的事件
	this:RegisterEvent("UI_COMMAND")
    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function SpecialServer_MBuy_OnLoad()
	g_SpecialServer_MBuy_Frame_UnifiedPosition	=	SpecialServer_MBuy_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function SpecialServer_MBuy_OnEvent( event )
    if ( event == "UI_COMMAND" and tonumber(arg0) == 99907901 ) then
        g_SpecialServer_MBuy_ItemIndex  = Get_XParam_INT(0)
        g_SpecialServer_MBuy_remain_num = Get_XParam_INT(1)
        g_SpecialServer_MBuy_CurDaiBi = Get_XParam_INT(2) 
        local g_SpecialServer_objCared = DataPool : GetNPCIDByServerID(tonumber(Get_XParam_INT(3)))
        this:CareObject(g_SpecialServer_objCared, 1, "SpecialServer_MBuy");
        if (this:IsVisible()) then  
            return
        end
        SpecialServer_MBuy_InputNumBK:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        SpecialServer_MBuy_InputNumBK:SetText("1")					--默认输入为1   
        SpecialServer_MBuy_InputNumBK:SetSelected( 0, -1 ); 
        SpecialServer_MBuy_FreshWindow() 
        this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		SpecialServer_MBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		SpecialServer_MBuy_Closed()
	elseif event == "ADJEST_UI_POS" then
        SpecialServer_MBuy_Frame_On_ResetPos() 		
    elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_SpecialServer_objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			--取消关心
			this:CareObject(g_SpecialServer_objCared, 0, "SpecialServer_MBuy");
		end	 
	end
end

--===============================================
--刷新界面信息
--===============================================
function SpecialServer_MBuy_FreshWindow() 
    local itemid = g_SpecialServer_MBuy_gift[g_SpecialServer_MBuy_ItemIndex].id
    local itemnum = g_SpecialServer_MBuy_gift[g_SpecialServer_MBuy_ItemIndex].num
    local costdaibi=g_SpecialServer_MBuy_gift[g_SpecialServer_MBuy_ItemIndex].costdaibi  
    local	theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
	if theAction:GetID() ~= 0 then
		SpecialServer_MBuy_Item:SetActionItem(theAction:GetID())
		SpecialServer_MBuy_Item:Show()
    end
    local	nBuyNum	=	0
	if SpecialServer_MBuy_InputNumBK:GetText() ~= '' then
        nBuyNum	=	tonumber(SpecialServer_MBuy_InputNumBK:GetText()) 
    end 
    SpecialServer_MBuy_Item_Mask:Hide()
    SpecialServer_MBuy_Item_Feibang:Hide()
    SpecialServer_MBuy_Item_BuyLimitNum:SetText(g_SpecialServer_MBuy_remain_num)
    SpecialServer_MBuy_ItemInfo_Text:SetText(DataPool:Lua_GetItemNameByIndex(itemid))
    SpecialServer_MBuy_ItemInfo_Lilianzhi2:SetText( ScriptGlobal_Format("#{TYCZ_240513_44}",costdaibi))
    SpecialServer_MBuy_CashNum:SetText(g_SpecialServer_MBuy_CurDaiBi)
    if g_SpecialServer_MBuy_CurDaiBi < costdaibi*nBuyNum then
        SpecialServer_MBuy_PriceNum:SetText("#cff0000"..costdaibi*nBuyNum)
    else
        SpecialServer_MBuy_PriceNum:SetText(costdaibi*nBuyNum)
    end
    if g_SpecialServer_MBuy_ItemIndex == 1 then
        SpecialServer_MBuy_Item_BuyLimit:SetImage("ActivitySchedule","ActivitySchedule_ShopTips_Forever")
    else
        SpecialServer_MBuy_Item_BuyLimit:SetImage("ActivitySchedule","ActivitySchedule_ShopTips_Week")
    end
end
 
--===============================================
--取出相应的物资
--===============================================
function SpecialServer_MBuy_OK_Clicked()
 
	local count = tonumber(SpecialServer_MBuy_InputNumBK:GetText())
	if count <= 0 then
		return
    end 
	SpecialServer_MBuy_BuyItem(g_SpecialServer_MBuy_ItemIndex, count)
	--隐藏界面
	this:Hide()					
end

function SpecialServer_MBuy_BuyItem(itemid,count)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "GetGift" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 999079 );											-- 脚本编号  
        Set_XSCRIPT_Parameter( 0, g_SpecialServer_MBuy_ItemIndex );	
        Set_XSCRIPT_Parameter( 1, count );		    
        Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数  
    Send_XSCRIPT()	
end
function SpecialServer_MBuy_GetBuyMaxNum() 
    local itemid = g_SpecialServer_MBuy_gift[g_SpecialServer_MBuy_ItemIndex].id
    local itemnum = g_SpecialServer_MBuy_gift[g_SpecialServer_MBuy_ItemIndex].num
    local costdaibi=g_SpecialServer_MBuy_gift[g_SpecialServer_MBuy_ItemIndex].costdaibi 
	--计算最大能领取数量 
    return HuoYueShopCalcMaxNumCanBuy(itemid,itemnum,1,g_SpecialServer_MBuy_CurDaiBi,costdaibi,1,g_SpecialServer_MBuy_remain_num,0,1)
end
function SpecialServer_MBuy_CalMax()    
	SpecialServer_MBuy_InputNumBK : SetText(SpecialServer_MBuy_GetBuyMaxNum())
end

function SpecialServer_MBuy_TextChanged() 
    SpecialServer_MBuy_FreshWindow(g_SpecialServer_MBuy_ItemIndex) 
end

function SpecialServer_MBuy_OnHidden()    
	this:Hide()
end
function SpecialServer_MBuy_CancelClicked()
	this:Hide()
end
--===============================================
--关闭界面
--===============================================
function SpecialServer_MBuy_Closed()
	this:Hide()
end
function SpecialServer_MBuy_Close_Clicked()
	this:Hide()
end
function SpecialServer_MBuy_Frame_On_ResetPos()
	 SpecialServer_MBuy_Frame:SetProperty("UnifiedPosition", g_SpecialServer_MBuy_Frame_UnifiedPosition)
end
