local Dahua_Incom_Frame_UnifiedXPosition = 0
local Dahua_Incom_Frame_UnifiedYPosition = 0  
local Dahua_Incom_curtab        = 1
local Dahua_Incom_shop_iteminfo = { 
    [1] = { id=39910145, num=1, eye=0, costdaibi=3000,MDpos=2, MDLen=1, limit=1,},
    [2] = { id=38006875, num=1, eye=0, costdaibi=400, },
    [3] = { id=10192100, num=1, eye=0, costdaibi=340, MDpos=3, MDLen=1, limit=1,},
    [4] = { id=10101094, num=1, eye=0, costdaibi=450, MDpos=4, MDLen=1, limit=1,},
    [5] = { id=39910146, num=1, eye=0, costdaibi=300, MDpos=0, MDLen=2, limit=3,}, 
    [6] = { id=38006876, num=1, eye=0, costdaibi=150, MDpos=5, MDLen=1, limit=1,}, 
    [7] = { id=30103114, num=1, eye=0, costdaibi=75,  MDpos=6, MDLen=1, limit=1,}, 
    [8]=  { id=50331017, num=1, eye=1, costdaibi=250, },  
    [9]=  { id=50332017, num=1, eye=1, costdaibi=250, },  
    [10]= { id=50333017, num=1, eye=1, costdaibi=250, },  
    [11] ={ id=50131017, num=1, eye=1, costdaibi=10,  }, 
    [12] ={ id=50132017, num=1, eye=1, costdaibi=10,  }, 
    [13]= { id=50133017, num=1, eye=1, costdaibi=10,  }, 
    [14]= { id=38000992, num=1, eye=0, costdaibi=5,   },  
    [15]= { id=38006894, num=10,eye=0,  costdaibi=10, },  
    [16]= { id=38006894, num=1, eye=0, costdaibi=1,   },  
}
local Dahua_Incom_ChouJiang_imginfo = { 
    [1] = "set:HSLJ_01 image:HSLJ_Tiger",
    [2] = "set:HSLJ_01 image:HSLJ_Dragon",
    [3] = "set:HSLJ_01 image:HSLJ_Hawk",
    [4] = "set:HSLJ_01 image:HSLJ_Tiger",
    [5] = "set:HSLJ_01 image:HSLJ_Dragon",
}
local Dahua_Incom_ChouJiang_leiji_info = { 
    [1] = {id=39920147,num=5,text="#{DHLS_240611_18}"},
    [2] = {id=39920147,num=8,text="#{DHLS_240611_19}"},
    [3] = {id=39920147,num=10,text="#{DHLS_240611_20}"},
    [4] = {id=39920147,num=20,text="#{DHLS_240611_21}"}, 
}

local g_Dahua_Incom_needcishu = {5,10,20,40} 
local g_Dahua_Incom_Shop_CurPage=1
local g_Dahua_Incom_Shop_PerPageCount = 12
local g_Dahua_DaiBi          = 0
local g_Dahua_JiangQuan      = 0
local g_Dahua_ChouJiang_info = 0
local g_Dahua_Shop_info      = 0
local g_Dahua_ChouJiang_redpoint= {0,0}
local g_Dahua_Shop_redpoint= 0 
local g_Dahua_needjiangquan  = 1
local g_Dahua_ChouJiang_Ctl = {} 
local g_Dahua_Incom_ButtonCDTime = 1; --按钮冷却时间
local g_Dahua_Incom_ButtonLastTime = 0;
--*********************************
-- PreLoad
--*********************************
function Dahua_Incom_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND  
	this : RegisterEvent(" ADJEST_UI_POS",false)
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" );		-- 游戏分辨率发生了变化
	this : RegisterEvent( "GAMELOGIN_SELECTCHARACTER" );	-- 选择人物
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" );		-- 离开场景 
end

--*********************************
-- OnLoad
--*********************************
function Dahua_Incom_OnLoad() 
    -- 保存界面的默认相对位置
	Dahua_Incom_Frame_UnifiedXPosition	= Dahua_Incom_Frame:GetProperty("UnifiedXPosition");
    Dahua_Incom_Frame_UnifiedYPosition	= Dahua_Incom_Frame:GetProperty("UnifiedYPosition"); 
    g_Dahua_ChouJiang_Ctl.imginfo = {}
    g_Dahua_ChouJiang_Ctl.imginfo[1] = Dahua_Incom_Image1
    g_Dahua_ChouJiang_Ctl.imginfo[2] = Dahua_Incom_Image2
    g_Dahua_ChouJiang_Ctl.imginfo[3] = Dahua_Incom_Image3
    g_Dahua_ChouJiang_Ctl.imginfo[4] = Dahua_Incom_Image4
    g_Dahua_ChouJiang_Ctl.imginfo[5] = Dahua_Incom_Image5
    g_Dahua_ChouJiang_Ctl.leiji_Text = {}
    g_Dahua_ChouJiang_Ctl.leiji_Text[1]   = Dahua_Incom_Stage_Button1_Text
    g_Dahua_ChouJiang_Ctl.leiji_Text[2]   = Dahua_Incom_Stage_Button2_Text
    g_Dahua_ChouJiang_Ctl.leiji_Text[3]   = Dahua_Incom_Stage_Button3_Text
    g_Dahua_ChouJiang_Ctl.leiji_Text[4]   = Dahua_Incom_Stage_Button4_Text
    g_Dahua_ChouJiang_Ctl.leiji_btn = {}
    g_Dahua_ChouJiang_Ctl.leiji_btn[1]   = Dahua_Incom_Stage_Button1
    g_Dahua_ChouJiang_Ctl.leiji_btn[2]   = Dahua_Incom_Stage_Button2
    g_Dahua_ChouJiang_Ctl.leiji_btn[3]   = Dahua_Incom_Stage_Button3
    g_Dahua_ChouJiang_Ctl.leiji_btn[4]   = Dahua_Incom_Stage_Button4
    g_Dahua_ChouJiang_Ctl.leiji_btn_ani = {}
    g_Dahua_ChouJiang_Ctl.leiji_btn_ani[1]   = Dahua_Incom_Stage_Button1Animate
    g_Dahua_ChouJiang_Ctl.leiji_btn_ani[2]   = Dahua_Incom_Stage_Button2Animate
    g_Dahua_ChouJiang_Ctl.leiji_btn_ani[3]   = Dahua_Incom_Stage_Button3Animate
    g_Dahua_ChouJiang_Ctl.leiji_btn_ani[4]   = Dahua_Incom_Stage_Button4Animate
    g_Dahua_ChouJiang_Ctl.leiji_btn_Check = {}
    g_Dahua_ChouJiang_Ctl.leiji_btn_Check[1]   = Dahua_Incom_Stage_Button1OK
    g_Dahua_ChouJiang_Ctl.leiji_btn_Check[2]   = Dahua_Incom_Stage_Button2OK
    g_Dahua_ChouJiang_Ctl.leiji_btn_Check[3]   = Dahua_Incom_Stage_Button3OK
    g_Dahua_ChouJiang_Ctl.leiji_btn_Check[4]   = Dahua_Incom_Stage_Button4OK
    g_Dahua_ChouJiang_Ctl.shop = {}
    g_Dahua_ChouJiang_Ctl.shop.Bk = {}
    g_Dahua_ChouJiang_Ctl.shop.Bk[1] = Dahua_Incom_BK1
    g_Dahua_ChouJiang_Ctl.shop.Bk[2] = Dahua_Incom_BK2
    g_Dahua_ChouJiang_Ctl.shop.Bk[3] = Dahua_Incom_BK3
    g_Dahua_ChouJiang_Ctl.shop.Bk[4] = Dahua_Incom_BK4
    g_Dahua_ChouJiang_Ctl.shop.Bk[5] = Dahua_Incom_BK5
    g_Dahua_ChouJiang_Ctl.shop.Bk[6] = Dahua_Incom_BK6
    g_Dahua_ChouJiang_Ctl.shop.Bk[7] = Dahua_Incom_BK7
    g_Dahua_ChouJiang_Ctl.shop.Bk[8] = Dahua_Incom_BK8
    g_Dahua_ChouJiang_Ctl.shop.Bk[9] = Dahua_Incom_BK9
    g_Dahua_ChouJiang_Ctl.shop.Bk[10] = Dahua_Incom_BK10
    g_Dahua_ChouJiang_Ctl.shop.Bk[11] = Dahua_Incom_BK11
    g_Dahua_ChouJiang_Ctl.shop.Bk[12] = Dahua_Incom_BK12
    g_Dahua_ChouJiang_Ctl.shop.Icon = {}
    g_Dahua_ChouJiang_Ctl.shop.Icon[1] = Dahua_Incom_BK1_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[2] = Dahua_Incom_BK2_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[3] = Dahua_Incom_BK3_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[4] = Dahua_Incom_BK4_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[5] = Dahua_Incom_BK5_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[6] = Dahua_Incom_BK6_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[7] = Dahua_Incom_BK7_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[8] = Dahua_Incom_BK8_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[9] = Dahua_Incom_BK9_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[10] = Dahua_Incom_BK10_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[11] = Dahua_Incom_BK11_Icon
    g_Dahua_ChouJiang_Ctl.shop.Icon[12] = Dahua_Incom_BK12_Icon
    g_Dahua_ChouJiang_Ctl.shop.LimitNum = {}
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[1] = Dahua_Incom_Item1LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[2] = Dahua_Incom_Item2LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[3] = Dahua_Incom_Item3LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[4] = Dahua_Incom_Item4LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[5] = Dahua_Incom_Item5LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[6] = Dahua_Incom_Item6LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[7] = Dahua_Incom_Item7LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[8] = Dahua_Incom_Item8LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[9] = Dahua_Incom_Item9LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[10] = Dahua_Incom_Item10LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[11] = Dahua_Incom_Item11LimitNumber
    g_Dahua_ChouJiang_Ctl.shop.LimitNum[12] = Dahua_Incom_Item12LimitNumber    
    g_Dahua_ChouJiang_Ctl.shop.Eye = {}
    g_Dahua_ChouJiang_Ctl.shop.Eye[1] =  Dahua_Incom_BK1_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[2] =  Dahua_Incom_BK2_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[3] =  Dahua_Incom_BK3_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[4] =  Dahua_Incom_BK4_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[5] =  Dahua_Incom_BK5_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[6] =  Dahua_Incom_BK6_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[7] =  Dahua_Incom_BK7_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[8] =  Dahua_Incom_BK8_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[9] =  Dahua_Incom_BK9_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[10] = Dahua_Incom_BK10_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[11] = Dahua_Incom_BK11_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.Eye[12] = Dahua_Incom_BK12_Icon_Eye
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK = {}
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[1] = Dahua_Incom_Item1LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[2] = Dahua_Incom_Item2LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[3] = Dahua_Incom_Item3LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[4] = Dahua_Incom_Item4LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[5] = Dahua_Incom_Item5LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[6] = Dahua_Incom_Item6LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[7] = Dahua_Incom_Item7LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[8] = Dahua_Incom_Item8LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[9] = Dahua_Incom_Item9LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[10] = Dahua_Incom_Item10LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[11] = Dahua_Incom_Item11LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[12] = Dahua_Incom_Item12LimitNumberBK
    g_Dahua_ChouJiang_Ctl.shop.Limitimg = {}
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[1] = Dahua_Incom_BK1_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[2] = Dahua_Incom_BK2_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[3] = Dahua_Incom_BK3_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[4] = Dahua_Incom_BK4_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[5] = Dahua_Incom_BK5_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[6] = Dahua_Incom_BK6_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[7] = Dahua_Incom_BK7_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[8] = Dahua_Incom_BK8_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[9] = Dahua_Incom_BK9_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[10] = Dahua_Incom_BK10_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[11] = Dahua_Incom_BK11_Icon_BuyLimit
    g_Dahua_ChouJiang_Ctl.shop.Limitimg[12] = Dahua_Incom_BK12_Icon_BuyLimit 
    g_Dahua_ChouJiang_Ctl.shop.ItemName = {}
    g_Dahua_ChouJiang_Ctl.shop.ItemName[1] = Dahua_Incom_BK1_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[2] = Dahua_Incom_BK2_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[3] = Dahua_Incom_BK3_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[4] = Dahua_Incom_BK4_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[5] = Dahua_Incom_BK5_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[6] = Dahua_Incom_BK6_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[7] = Dahua_Incom_BK7_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[8] = Dahua_Incom_BK8_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[9] = Dahua_Incom_BK9_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[10] = Dahua_Incom_BK10_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[11] = Dahua_Incom_BK11_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemName[12] = Dahua_Incom_BK12_ItemName
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney = {}
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[1] = Dahua_Incom_BK1_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[2] = Dahua_Incom_BK2_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[3] = Dahua_Incom_BK3_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[4] = Dahua_Incom_BK4_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[5] = Dahua_Incom_BK5_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[6] = Dahua_Incom_BK6_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[7] = Dahua_Incom_BK7_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[8] = Dahua_Incom_BK8_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[9] = Dahua_Incom_BK9_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[10] =Dahua_Incom_BK10_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[11] =Dahua_Incom_BK11_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.ItemMoney[12] =Dahua_Incom_BK12_ItemMoney
    g_Dahua_ChouJiang_Ctl.shop.Sellout = {}
    g_Dahua_ChouJiang_Ctl.shop.Sellout[1] = Dahua_Incom_BK1_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[2] = Dahua_Incom_BK2_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[3] = Dahua_Incom_BK3_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[4] = Dahua_Incom_BK4_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[5] = Dahua_Incom_BK5_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[6] = Dahua_Incom_BK6_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[7] = Dahua_Incom_BK7_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[8] = Dahua_Incom_BK8_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[9] = Dahua_Incom_BK9_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[10] = Dahua_Incom_BK10_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[11] = Dahua_Incom_BK11_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Sellout[12] = Dahua_Incom_BK12_SellOut
    g_Dahua_ChouJiang_Ctl.shop.Mask = {}
    g_Dahua_ChouJiang_Ctl.shop.Mask[1] = Dahua_Incom_BK1_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[2] = Dahua_Incom_BK2_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[3] = Dahua_Incom_BK3_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[4] = Dahua_Incom_BK4_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[5] = Dahua_Incom_BK5_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[6] = Dahua_Incom_BK6_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[7] = Dahua_Incom_BK7_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[8] = Dahua_Incom_BK8_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[9] = Dahua_Incom_BK9_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[10] = Dahua_Incom_BK10_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[11] = Dahua_Incom_BK11_Icon_Mask
    g_Dahua_ChouJiang_Ctl.shop.Mask[12] = Dahua_Incom_BK12_Icon_Mask
end

--================================================
-- 界面的默认相对位置
--================================================
function Dahua_Incom_ResetPos()
	Dahua_Incom_Frame:SetProperty("UnifiedXPosition", Dahua_Incom_Frame_UnifiedXPosition);
	Dahua_Incom_Frame:SetProperty("UnifiedYPosition", Dahua_Incom_Frame_UnifiedYPosition); 
end 

--**********************************
-- ONEvent
--**********************************
function Dahua_Incom_OnEvent( event ) 
    if ( event == "UI_COMMAND" and tonumber(arg0) == 50100201 ) then 
        Dahua_Incom_curtab = 1
        g_Dahua_DaiBi           = tonumber(Get_XParam_INT(0))
        g_Dahua_JiangQuan       = tonumber(Get_XParam_INT(1))
        g_Dahua_ChouJiang_info  = tonumber(Get_XParam_INT(2))
        g_Dahua_Shop_info       = tonumber(Get_XParam_INT(3))
        g_Dahua_ChouJiang_redpoint[1]  = tonumber(Get_XParam_INT(4))
        g_Dahua_Shop_redpoint       = tonumber(Get_XParam_INT(5))
        g_Dahua_Incom_Shop_CurPage  = 1
        Dahua_Incom_Open()   
        this:Show()
    elseif ( event == "UI_COMMAND" and tonumber(arg0) == 50100202 ) then  
        g_Dahua_DaiBi           = tonumber(Get_XParam_INT(0))
        g_Dahua_JiangQuan       = tonumber(Get_XParam_INT(1))
        g_Dahua_ChouJiang_info  = tonumber(Get_XParam_INT(2))
        g_Dahua_Shop_info       = tonumber(Get_XParam_INT(3))
        g_Dahua_ChouJiang_redpoint[1]  = tonumber(Get_XParam_INT(4))
        g_Dahua_Shop_redpoint       = tonumber(Get_XParam_INT(5))
        Dahua_Incom_Open()    
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Dahua_Incom_ResetPos() 
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Dahua_Incom_Close()   
	elseif event == "ADJEST_UI_POS" then
        Dahua_Incom_ResetPos() 	 
    end
end
--**********************************
-- 关闭
--**********************************
function Dahua_Incom_Close()
    g_Dahua_Incom_Shop_CurPage =1
    this:Hide()
end 
--**********************************
-- 打开界面
--**********************************
function Dahua_Incom_Open()
    if Dahua_Incom_curtab == 1 then
        Dahua_Incom_Open_ChouJiang()
    else
        Dahua_Incom_Open_Shop()
    end
    Dahua_Incom_RefreshTips()
end 
--**********************************
-- tab按钮点击
--**********************************
function Dahua_Incom_TabClicked(idx)
    Dahua_Incom_curtab = idx
    Dahua_Incom_Open()
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("ClickTab")
        Set_XSCRIPT_ScriptID( 501002 )
        Set_XSCRIPT_Parameter( 0, idx ); 
        Set_XSCRIPT_ParamCount( 1 ); 
    Send_XSCRIPT() 
end
--**********************************
-- 抽奖界面显示
--**********************************
function Dahua_Incom_Open_ChouJiang()
    g_Dahua_ChouJiang_redpoint[1] = 0 
    g_Dahua_ChouJiang_redpoint[2] = 0
    Dahua_Incom_CheckButton1:SetCheck(1)
    Dahua_Incom_CheckButton2:SetCheck(0)
    Dahua_Incom_Client1:Show()
    Dahua_Incom_Client2:Hide() 
    Dahua_Incom_RefreshTips()       
    Dahua_Incom_JiangQuan:SetText(ScriptGlobal_Format("#{DHLS_240611_16}",g_Dahua_JiangQuan)) 
    Dahua_Incom_Client1_Daibi:SetText(ScriptGlobal_Format("#{DHLS_240611_46}",g_Dahua_DaiBi))
    for i = 1, table.getn(g_Dahua_ChouJiang_Ctl.imginfo) do
        g_Dahua_ChouJiang_Ctl.imginfo[i]:SetProperty("Image", Dahua_Incom_ChouJiang_imginfo[i]) 
    end 
    for i = 1, table.getn(g_Dahua_ChouJiang_Ctl.leiji_btn_ani) do
        g_Dahua_ChouJiang_Ctl.leiji_btn_ani[i]:Hide()
        g_Dahua_ChouJiang_Ctl.leiji_btn_Check[i]:Hide() 
        g_Dahua_ChouJiang_Ctl.leiji_btn[i]:Show()
        local tips = ScriptGlobal_Format("#{DHLS_240611_89}",Dahua_Incom_ChouJiang_leiji_info[i].num)
        g_Dahua_ChouJiang_Ctl.leiji_btn[i]:SetToolTip(tips)
    end
    local bret, ncur_leiji_cishu = GetBitValueInUINT(g_Dahua_ChouJiang_info, 0, 20)  
    Dahua_Incom_Stage_StageNum:SetText(ScriptGlobal_Format("#{DHLS_240611_22}",ncur_leiji_cishu))
    for i = 1, table.getn(g_Dahua_ChouJiang_Ctl.leiji_btn_ani) do
        local nbegpos   = 20
        local nret, nget_flag = GetBitValueInUINT(g_Dahua_ChouJiang_info, nbegpos+i, 1) 
        if nget_flag == 1 then
            g_Dahua_ChouJiang_Ctl.leiji_btn_Check[i]:Show()             
            local tips = ScriptGlobal_Format("#{DHLS_240611_90}",Dahua_Incom_ChouJiang_leiji_info[i].num)
            g_Dahua_ChouJiang_Ctl.leiji_btn_Check[i]:SetToolTip(tips)
            g_Dahua_ChouJiang_Ctl.leiji_btn[i]:Hide()
        end
        if ncur_leiji_cishu >= g_Dahua_Incom_needcishu[i] and nget_flag == 0 then
            g_Dahua_ChouJiang_Ctl.leiji_btn_ani[i]:Show() 
        end
    end 

    if g_Dahua_JiangQuan >= (1*g_Dahua_needjiangquan) then
        Dahua_Incom_ButtonOne_Tips:Show() 
    else
        Dahua_Incom_ButtonOne_Tips:Hide()
    end
    
    if g_Dahua_JiangQuan >= (10*g_Dahua_needjiangquan) then
        Dahua_Incom_ButtonTen_Tips:Show() 
    else
        Dahua_Incom_ButtonTen_Tips:Hide()
    end 
end
--**********************************
-- 商店界面显示
--**********************************
function Dahua_Incom_Open_Shop()
    g_Dahua_Shop_redpoint = 0 
    Dahua_Incom_RefreshTips()
    Dahua_Incom_Client1:Hide()
    Dahua_Incom_Client2:Show()  
    Dahua_Incom_CheckButton1:SetCheck(0)
    Dahua_Incom_CheckButton2:SetCheck(1)
    for i = 1, table.getn(g_Dahua_ChouJiang_Ctl.shop.Bk) do
        g_Dahua_ChouJiang_Ctl.shop.Bk[i]:Hide()
    end
    local ncurbeg = (g_Dahua_Incom_Shop_CurPage-1)*g_Dahua_Incom_Shop_PerPageCount + 1  
    local curctlidx = 1
    for nbegidx = ncurbeg, table.getn(Dahua_Incom_shop_iteminfo) do 
        if curctlidx > g_Dahua_Incom_Shop_PerPageCount then
            break
        end
        g_Dahua_ChouJiang_Ctl.shop.Bk[curctlidx]:Show()
        local itemid    = Dahua_Incom_shop_iteminfo[nbegidx].id
        local itemnum   = Dahua_Incom_shop_iteminfo[nbegidx].num
        local needdaibi = Dahua_Incom_shop_iteminfo[nbegidx].costdaibi
        local nlimitnum = Dahua_Incom_shop_iteminfo[nbegidx].limit      
        local theAction = DataPool:CreateBindActionItemForShow(itemid, itemnum)
	    if theAction:GetID() ~= 0 then
            g_Dahua_ChouJiang_Ctl.shop.Icon[curctlidx]:SetActionItem(theAction:GetID())
            g_Dahua_ChouJiang_Ctl.shop.ItemName[curctlidx]:SetText(theAction:GetName())
        end 
        g_Dahua_ChouJiang_Ctl.shop.Sellout[curctlidx]:Hide()  
        g_Dahua_ChouJiang_Ctl.shop.Mask[curctlidx]:Hide()
        g_Dahua_ChouJiang_Ctl.shop.Limitimg[curctlidx]:Hide() 
        g_Dahua_ChouJiang_Ctl.shop.ItemMoney[curctlidx]:SetText(ScriptGlobal_Format("#{DHLS_240611_43}",needdaibi))  
        if Dahua_Incom_shop_iteminfo[nbegidx].MDpos ~= nil then
            local nres, ncurbuy = GetBitValueInUINT(g_Dahua_Shop_info, Dahua_Incom_shop_iteminfo[nbegidx].MDpos, Dahua_Incom_shop_iteminfo[nbegidx].MDLen)
            g_Dahua_ChouJiang_Ctl.shop.LimitNum[curctlidx]:Show()
            g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[curctlidx]:Show()
            g_Dahua_ChouJiang_Ctl.shop.Limitimg[curctlidx]:Show() 
            g_Dahua_ChouJiang_Ctl.shop.LimitNum[curctlidx]:SetText(nlimitnum-ncurbuy)
            if nlimitnum-ncurbuy <=0 then
                g_Dahua_ChouJiang_Ctl.shop.Sellout[curctlidx]:Show() 
                g_Dahua_ChouJiang_Ctl.shop.Mask[curctlidx]:Show()
            end
        else
            g_Dahua_ChouJiang_Ctl.shop.LimitNum[curctlidx]:Hide()
            g_Dahua_ChouJiang_Ctl.shop.LimitNumBK[curctlidx]:Hide()
        end  
       
        if Dahua_Incom_shop_iteminfo[nbegidx].eye == 1 then 
            g_Dahua_ChouJiang_Ctl.shop.Eye[curctlidx]:Show() 
        else
            g_Dahua_ChouJiang_Ctl.shop.Eye[curctlidx]:Hide() 
        end         
        curctlidx = curctlidx + 1 
    end   
    local npagecount = 0
    if table.getn(Dahua_Incom_shop_iteminfo) <= g_Dahua_Incom_Shop_PerPageCount then
        npagecount = 1
    elseif math.mod(table.getn(Dahua_Incom_shop_iteminfo), g_Dahua_Incom_Shop_PerPageCount) == 0  then
        npagecount = math.floor(table.getn(Dahua_Incom_shop_iteminfo)/g_Dahua_Incom_Shop_PerPageCount)
    else
        npagecount = math.floor(table.getn(Dahua_Incom_shop_iteminfo)/g_Dahua_Incom_Shop_PerPageCount) + 1
    end
    Dahua_Incom_PageNum:SetText( ScriptGlobal_Format("#{DHLS_240611_42}",g_Dahua_Incom_Shop_CurPage, npagecount) ) 
    Dahua_Incom_Daibi:SetText(ScriptGlobal_Format("#{DHLS_240611_46}",g_Dahua_DaiBi))
end
 
--**********************************
-- 打开奖励预览界面
--**********************************
function Dahua_Incom_ChouJiang_RewardBtn_Clicked() 
    CloseWindow( "Dahua_Incom_Reward" , true);
    PushEvent("OPEN_DAHUA_GIFT_PREVIEW")
end
--**********************************
-- 预览时装
--**********************************
function Dahua_Incom_ChouJiang_Preview(Idx)  
    CloseWindow( "Dahua_Incom_Preview", true );

    if Idx == 1 then 
		PushEvent("OPEN_DAHUA_PREVIEW", 1, "set:Dahua_Incom_ShowImg image:Dahua_Incom_Show1") --附体
	end 
    
    if Idx == 2 then 
        Clear_XSCRIPT()
		    Set_XSCRIPT_ScriptID(888051)
		    Set_XSCRIPT_Function_Name("DressPreview")
		    Set_XSCRIPT_Parameter(0, 10127864)
		    Set_XSCRIPT_Parameter(1, 240)   --发型
		    Set_XSCRIPT_Parameter(2, 178)   --脸型
		    Set_XSCRIPT_ParamCount(3)
	    Send_XSCRIPT()
    end
    
    if Idx == 3 then
        PushEvent("OPEN_DAHUA_PREVIEW", 2, "set:Dahua_Incom_ShowImg image:Dahua_Incom_Show2")  --白骨鞭
    end
    
    if Idx == 4 then
        PushEvent("OPEN_DAHUA_PREVIEW", 3)  --混天玄戟
    end
    
    if Idx == 5 then 
        Pet:AnniversaryOpenPetJian( 36249 );
    end
    
end
--**********************************
-- 获得累计奖励
--**********************************
function Dahua_Incom_ChouJiang_GetLeiJi_Clicked(idx)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("GetLeiJiGift")
        Set_XSCRIPT_ScriptID( 501006 )
        Set_XSCRIPT_Parameter( 0, idx ); 
        Set_XSCRIPT_ParamCount( 1 ); 
    Send_XSCRIPT() 
end
--**********************************
-- 抽奖
--**********************************
function Dahua_Incom_ChouJiang_Clicked(type)
    local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Dahua_Incom_ButtonLastTime < g_Dahua_Incom_ButtonCDTime * 1000) then 
   	    PushDebugMessage("#{DHLS_240611_33}"); --不可连续点击，请稍等片刻后再点击
		return
	end
    g_Dahua_Incom_ButtonLastTime = curTime;
    
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("ChouJiang")
        Set_XSCRIPT_ScriptID( 501006 )
        Set_XSCRIPT_Parameter( 0, type ); 
        Set_XSCRIPT_ParamCount( 1 ); 
    Send_XSCRIPT() 
end
--**********************************
-- 商店购买物品
--**********************************
function Dahua_Incom_Shop_BuyGift(idx)
    idx = (g_Dahua_Incom_Shop_CurPage-1)*g_Dahua_Incom_Shop_PerPageCount + idx
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("BuyItem")
        Set_XSCRIPT_ScriptID( 501004 )
        Set_XSCRIPT_Parameter( 0, idx ); 
        Set_XSCRIPT_Parameter( 1, 0 ); 
        Set_XSCRIPT_ParamCount( 2 ); 
    Send_XSCRIPT() 
end
--**********************************
-- 购买代币-打开界面
--**********************************
function Dahua_Incom_BuyDaibi()
    CloseWindow( "Dahua_Incom_Buy", true );

    PushEvent("OPEN_DAHUA_BUY", g_Dahua_DaiBi)
end
--**********************************
-- 翻页上一页
--**********************************
function Dahua_Incom_PageDown()
    if g_Dahua_Incom_Shop_CurPage*g_Dahua_Incom_Shop_PerPageCount < table.getn(Dahua_Incom_shop_iteminfo) then
        g_Dahua_Incom_Shop_CurPage = g_Dahua_Incom_Shop_CurPage + 1
        Dahua_Incom_Open_Shop()
    end
end
--**********************************
-- 翻页下一页
--**********************************
function Dahua_Incom_PageUp()
    if g_Dahua_Incom_Shop_CurPage > 1 then
        g_Dahua_Incom_Shop_CurPage = g_Dahua_Incom_Shop_CurPage - 1
        Dahua_Incom_Open_Shop()
    end
end
--**********************************
-- 问号按钮
--**********************************
function Dahua_Incom_HelpClicked()     
	PushEvent("CCSHOP_HELP", 218)
end

function Dahua_Incom_FenJie_Clicked()    
    CloseWindow( "Dahua_Incom_Feipinhuishou", true );
 
	PushEvent("OPEN_DAHUA_INCOM_FEIPINHUISHOU")
end


function Dahua_Incom_RefreshTips()
    local bret, ncur_leiji_cishu = GetBitValueInUINT(g_Dahua_ChouJiang_info, 0, 20)  
    for i = 1, table.getn(g_Dahua_ChouJiang_Ctl.leiji_btn_ani) do
        local nbegpos   = 20
        local nret, nget_flag = GetBitValueInUINT(g_Dahua_ChouJiang_info, nbegpos+i, 1)  
        if ncur_leiji_cishu >= g_Dahua_Incom_needcishu[i] and nget_flag == 0 then 
            g_Dahua_ChouJiang_redpoint[2] = g_Dahua_ChouJiang_redpoint[2] + 1
        end
    end 

    if g_Dahua_JiangQuan >= (1*g_Dahua_needjiangquan) then 
        g_Dahua_ChouJiang_redpoint[2] = g_Dahua_ChouJiang_redpoint[2] + 1 
    end
    
    if g_Dahua_JiangQuan >= (10*g_Dahua_needjiangquan) then 
        g_Dahua_ChouJiang_redpoint[2] = g_Dahua_ChouJiang_redpoint[2] + 1 
    end 

    local isshow_minitip = 0
    local isshowbtn = 1 
    Dahua_Incom_CheckButton1_Tips:Hide()
    Dahua_Incom_CheckButton2_Tips:Hide()
    if g_Dahua_Shop_redpoint == 1 then
        Dahua_Incom_CheckButton2_Tips:Show()
        isshow_minitip = 1
    end
    if g_Dahua_ChouJiang_redpoint[1] >= 1 or g_Dahua_ChouJiang_redpoint[2] >= 1 then
        Dahua_Incom_CheckButton1_Tips:Show() 
        isshow_minitip = 1
    end 
    if isshow_minitip == 1 then 
        PushEvent("OPEN_DAHUA_MINITIPS", isshowbtn, 1)
    else
        PushEvent("OPEN_DAHUA_MINITIPS", isshowbtn, 0)
    end
end
function Dahua_Incom_Eye_Clicked(idx)      
    idx = (g_Dahua_Incom_Shop_CurPage-1)*g_Dahua_Incom_Shop_PerPageCount + idx      
    if Dahua_Incom_shop_iteminfo[idx].eye == 0 then
        return
    end
    PushEvent("OPEN_GEMEFFECTPREVIEW", Dahua_Incom_shop_iteminfo[idx].id)
end