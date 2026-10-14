local g_JinFengMiZang_Frame_UnifiedPosition;
local g_JinFengMiZang_Item_Index ={}
local g_TodayCount 			= 0;
local g_WanFaType 			= 0;		 --0默认玩法 1删除玩法 2 双倍玩法 3替换玩法
local g_LuckyItemIndex 	= {};
local g_JinFengYeCount 	= 0;
local g_SuiXinBiCount 		= 0;
local g_JinFengMiZang_ReplaceID 		= 0;
local g_LuckyItemPos 		= {}; 
local g_ItemList = {
	[0] = {
		[1]  = {itemid = 20310168, showid = 39920574, 	Group = 0,  num = 5,  }, 	--金蚕丝*5   
    	[2]  = {itemid = 20800033, showid = 39920946,   Group = 0,  num = 5,  }, 	--九天玉碎5           
    	[3]  = {itemid = 20700063, showid = 39920163, 	Group = 0,  num = 20, },   --离火*20      
    	[4]  = {itemid = 38000378, showid = 39920296, 	Group = 0,  num = 5,  },   --真元珀*5         
    	[5]  = {itemid = 20310178, showid = 39920092,   Group = 0,  num = 5,  }, 	--中级勾天彩*5
    	[6]  = {itemid = 30008034, showid = 39920394,	Group = 0,  num = 5,  }, 	----金刚砂    *5       
    	[7]  = {itemid = 38000807, showid = 39920334,	Group = 0,  num = 5,  }, 	--典籍注解*5            
    	[8]  = {itemid = 38000656, showid = 39920332,	Group = 0,  num = 5,  },	--悟灵珠 *5                      
    	[9]  = {itemid = 20700055, showid = 39920162,	Group = 0,  num = 20, }, 	--精金石*20       
    	[10] = {itemid = 20310175, showid = 39920089,	Group = 0,  num = 5,  }, 	--灵兽精魄  *5        
    	[11] = {itemid = 38001595, showid = 39921051,	Group = 0,  num = 5,  }, 	--缀梦灵石*5 
    	[12] = {itemid = 30503133, showid = 39920235,	Group = 0,  num = 5,  },   --千淬神玉  *5       
    	[13] = {itemid = 38000992, showid = 39920490,	Group = 0,  num = 5,  }, 	--虹耀石   *5       
    	[14] = {itemid = 38000571, showid = 39920329,	Group = 0,  num = 5,  }, 	--至尊强化精华  *5  
    	[15] = {itemid = 38000443, showid = 39920311,	Group = 0,  num = 5,  }, 	--幻魂丹       *5                
    	[16] = {itemid = 38000380, showid = 39920298,	Group = 0,  num = 5,  }, 	--真元精珀  *5         
    	[17] = {itemid = 30008130, showid = 30008130, 	Group = 0,  num = 1,  },   ----玄灵丹
    	[18] = {itemid = 50332009, showid = 50332009,	Group = 1,  num = 1,  },	--碎钻星尘·腰（3级）
    	[19] = {itemid = 38002214, showid = 39921415,	Group = 0,  num = 1,  }, 	--紫色真元    
    	[20] = {itemid = 50313004, showid = 39920126,   Group = 0,  num = 1,  }, 	--3级红宝石       
    	[21] = {itemid = 20502003, showid = 39920397,   Group = 0,  num = 1,  }, 	--3级秘银  
    	[22] = {itemid = 20501003, showid = 39920396,   Group = 0,  num = 1,  }, 	--3级棉布                  
    	[23] = {itemid = 10125235, showid = 39922000,   Group = 1,  num = 1,  }, 	--与君同        
    	[24] = {itemid = 38004357, showid = 38004357, 	Group = 0,  num = 5,  },   --良品残印集录   *5   
    	[25] = {itemid = 38004358, showid = 38004358, 	Group = 0,  num = 5,  }, 	--精品残印集录 *5   
    	[26] = {itemid = 38004804, showid = 38004804, 	Group = 0,  num = 20, },   --良品关系兑换券*20        
    	[27] = {itemid = 38004805, showid = 38004805, 	Group = 0,  num = 20, },   --精品关系兑换券*20    
    	[28] = {itemid = 10101031, showid = 39922765,   Group = 1,  num = 1,  }, 	--繁英帷下              
    	[29] = {itemid = 38006029, showid = 38006029,   Group = 1,  num = 1,  }, 	--枫露浓     
	},
	[1] = {
		[1]  = {itemid = 20310168, showid = 39920574, 	Group = 0,  num = 5, }, 	--金蚕丝*5   
		[2]  = {itemid = 20310161, showid = 20310161,   Group = 0,  num = 5, }, 	--魂冰珠*5           
		[3]  = {itemid = 38000837, showid = 38000837, 	Group = 0,  num = 10,},   --五艺残卷*10     
		[4]  = {itemid = 30503187, showid = 30503187, 	Group = 0,  num = 5, },   --中级根骨丹*5   
		[5]  = {itemid = 38000658, showid = 38000658,   Group = 0,  num = 1, }, 	--觉灵珠*1
		[6]  = {itemid = 30008034, showid = 39920394,	Group = 0,  num = 5, }, 	----金刚砂    *5       
		[7]  = {itemid = 38000807, showid = 39920334,	Group = 0,  num = 5, }, 	--典籍注解*5            
		[8]  = {itemid = 38000656, showid = 39920332,	Group = 0,  num = 5, },		--悟灵珠 *5                      
		[9]  = {itemid = 38000839, showid = 38000839,	Group = 0,  num = 2, }, 	--精金石*20       
		[10] = {itemid = 20310175, showid = 39920089,	Group = 0,  num = 5, }, 	--灵兽精魄  *5        
		[11] = {itemid = 38001595, showid = 39921051,	Group = 0,  num = 5, }, 	--五艺全卷*2   
		[12] = {itemid = 30503133, showid = 39920235,	Group = 0,  num = 5, },   --千淬神玉*5
		[13] = {itemid = 38000992, showid = 39920490,	Group = 0,  num = 5, }, 	--虹耀石   *5       
		[14] = {itemid = 38000571, showid = 39920329,	Group = 0,  num = 5, }, 	--至尊强化精华  *5  
		[15] = {itemid = 38000443, showid = 39920311,	Group = 0,  num = 5, }, 	--幻魂丹       *5                
		[16] = {itemid = 30700241, showid = 30700241,	Group = 0,  num = 5, }, 	--回天神石*5
		[17] = {itemid = 30008130, showid = 30008130, 	Group = 0,  num = 1, },   ----玄灵丹
		[18] = {itemid = 50332009, showid = 50332009,	Group = 1,  num = 1, },	--碎钻星尘·腰（3级）
		[19] = {itemid = 20500003, showid = 20500003,	Group = 0,  num = 1, }, 	--3级精铁    
		[20] = {itemid = 50313004, showid = 39920126,   Group = 0,  num = 1, }, 	--3级红宝石       
		[21] = {itemid = 20502003, showid = 39920397,   Group = 0,  num = 1, }, 	--3级秘银  
		[22] = {itemid = 20501003, showid = 39920396,   Group = 0,  num = 1, }, 	--3级棉布                  
		[23] = {itemid = 10125235, showid = 39922000,   Group = 1,  num = 1, }, 	--与君同        
		[24] = {itemid = 30503189, showid = 30503189, 	Group = 0,  num = 5, },   --珍兽融合丹*5 
		[25] = {itemid = 38005733, showid = 38005733, 	Group = 0,  num = 3, },   --润魂石随机礼包*3       
		[26] = {itemid = 30503020, showid = 30503020, 	Group = 0,  num = 2, },   --精品关系兑换券*20    
		[27] = {itemid = 10101031, showid = 39922765,   Group = 1,  num = 1, }, 	--繁英帷下              
		[28] = {itemid = 38006029, showid = 38006029,   Group = 1,  num = 1, }, 	--枫露浓   		
	}
}
local g_ItemList_Replace =  {
[1]  = {itemid = 38004903, showid = 39922845, }, --金枫季玲珑宝匣
[2]  = {itemid = 38004905, showid = 39922833, }, --四绘卷宝匣
}
local g_ItemAction 				= {}
local g_ItemAction_Animate	= {}
local g_ItemAction_Animate1={}
local g_ItemAction_Double = {}
--local g_ItemAction_Delete		= {}
--local g_ItemAction_Delete_Image		= {}
--local g_ItemAction_MengHong={}
--local g_ItemAction_Replace ={}
local g_SelectDelete_Button_Index = 0;

local g_JinFengMiZang_Replace_TimerLength =2000
local g_JinFengMiZang_TickEnd_TimerLength =5000
local g_Steps = {4,25,8,3}					--步数列表
local g_Rates = {200,50,200,500}		--频率列表
local g_StepIndex1 	= 1;
local g_StepIndex2 	= 1;
local g_StepCur1 		= 1;
local g_StepCur2 		= 1;
local	g_Step1 		 	= 1;
local	g_Step2 		 	= 1;
local g_AddStep1 		= 0;
local g_AddStep2 		= 0;
local g_LucyItemPos1 = 0;
local g_LucyItemPos2 = 0;
local g_Tick1 = 0;
local g_Tick2 = 0;
local g_SuiXinBiNum = {10,20,15}		;
local g_jfmz_itemid =38002072
local g_jfmz_luckynum =0
local g_jfmz_luckydoubleflag =0
--===============================================
-- PreLoad()
--===============================================
function JinFengMiZang_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD")		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化 
	this:RegisterEvent("JINFENGMIZANG_CANCEL",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	
end

--===============================================
-- OnLoad()
--===============================================
function JinFengMiZang_OnLoad()
	g_JinFengMiZang_Frame_UnifiedPosition = JinFengMiZang_FrameNULL:GetProperty("UnifiedPosition")
	g_ItemAction[1] = JinFengMiZang_Pond_BK_Icon1;
	g_ItemAction[2] = JinFengMiZang_Pond_BK_Icon2;
	g_ItemAction[3] = JinFengMiZang_Pond_BK_Icon3;
	g_ItemAction[4] = JinFengMiZang_Pond_BK_Icon4;
	g_ItemAction[5] = JinFengMiZang_Pond_BK_Icon5;
	g_ItemAction[6] = JinFengMiZang_Pond_BK_Icon6;
	g_ItemAction[7] = JinFengMiZang_Pond_BK_Icon7;
	g_ItemAction[8] = JinFengMiZang_Pond_BK_Icon8;

	g_ItemAction_Animate[1] = JinFengMiZang_Pond_BK_Icon1_Image;
	g_ItemAction_Animate[2] = JinFengMiZang_Pond_BK_Icon2_Image;
	g_ItemAction_Animate[3] = JinFengMiZang_Pond_BK_Icon3_Image;
	g_ItemAction_Animate[4] = JinFengMiZang_Pond_BK_Icon4_Image;
	g_ItemAction_Animate[5] = JinFengMiZang_Pond_BK_Icon5_Image;
	g_ItemAction_Animate[6] = JinFengMiZang_Pond_BK_Icon6_Image;
	g_ItemAction_Animate[7] = JinFengMiZang_Pond_BK_Icon7_Image;
	g_ItemAction_Animate[8] = JinFengMiZang_Pond_BK_Icon8_Image;
	
	
	g_ItemAction_Animate1[1] = JinFengMiZang_Pond_BK_Icon1_2;
	g_ItemAction_Animate1[2] = JinFengMiZang_Pond_BK_Icon8_2;
	g_ItemAction_Animate1[3] = JinFengMiZang_Pond_BK_Icon7_2;
	g_ItemAction_Animate1[4] = JinFengMiZang_Pond_BK_Icon6_2;
	g_ItemAction_Animate1[5] = JinFengMiZang_Pond_BK_Icon5_2;
	g_ItemAction_Animate1[6] = JinFengMiZang_Pond_BK_Icon4_2;
	g_ItemAction_Animate1[7] = JinFengMiZang_Pond_BK_Icon3_2;
	g_ItemAction_Animate1[8] = JinFengMiZang_Pond_BK_Icon2_2;
	
	g_ItemAction_Animate2[1] = JinFengMiZang_Pond_BK_Icon1_2;
	g_ItemAction_Animate2[2] = JinFengMiZang_Pond_BK_Icon2_2;
	g_ItemAction_Animate2[3] = JinFengMiZang_Pond_BK_Icon3_2;
	g_ItemAction_Animate2[4] = JinFengMiZang_Pond_BK_Icon4_2;
	g_ItemAction_Animate2[5] = JinFengMiZang_Pond_BK_Icon5_2;
	g_ItemAction_Animate2[6] = JinFengMiZang_Pond_BK_Icon6_2;
	g_ItemAction_Animate2[7] = JinFengMiZang_Pond_BK_Icon7_2;
	g_ItemAction_Animate2[8] = JinFengMiZang_Pond_BK_Icon8_2; 

	
	g_ItemAction_Double[1] = JinFengMiZang_Pond_BK_Icon1_Img;
	g_ItemAction_Double[2] = JinFengMiZang_Pond_BK_Icon2_Img;
	g_ItemAction_Double[3] = JinFengMiZang_Pond_BK_Icon3_Img;
	g_ItemAction_Double[4] = JinFengMiZang_Pond_BK_Icon4_Img;
	g_ItemAction_Double[5] = JinFengMiZang_Pond_BK_Icon5_Img;
	g_ItemAction_Double[6] = JinFengMiZang_Pond_BK_Icon6_Img;
	g_ItemAction_Double[7] = JinFengMiZang_Pond_BK_Icon7_Img;
	g_ItemAction_Double[8] = JinFengMiZang_Pond_BK_Icon8_Img; 
end

--===============================================
-- OnEvent()
--===============================================
function JinFengMiZang_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 89288101) then
		JinFengMiZang_Open()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89288102 and this:IsVisible()  ) then 
		JinFengMiZang_Replace()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89288103 and this:IsVisible()  ) then		
		g_TodayCount 			= Get_XParam_INT( 2 ) 
		g_JinFengYeCount 		= Get_XParam_INT( 3 )
		g_jfmz_luckynum 		= Get_XParam_INT( 4 )
		g_jfmz_luckydoubleflag 	= Get_XParam_INT( 5 )
		JinFengMiZang_Cost_FengYe:SetText( ScriptGlobal_Format("#{JFMZ_180801_31}",g_JinFengYeCount) ) 
		JinFengMiZang_Pond_Numbertext:SetText( ScriptGlobal_Format("#{JFMZ_180801_20}",g_TodayCount) )	
		JinFengMiZang_Cost_Value_Text:SetText(ScriptGlobal_Format("#{JFMZ_220728_09}",g_jfmz_luckynum))
		JinFengMiZang_LuckyDraw_Return()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89288105 and this:IsVisible() ) then
		JinFengMiZang_LuckyDraw_End()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89288107 and this:IsVisible() ) then 
		JinFengMiZang_Pond_Button1:Enable();   
	elseif (event == "PLAYER_LEAVE_WORLD") then
		JinFengMiZang_Hide()
	elseif (event == "ADJEST_UI_POS") then
		JinFengMiZang_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		JinFengMiZang_On_ResetPos() 
	elseif ( event == "JINFENGMIZANG_CANCEL" ) then
		JinFengMiZang_Pond_Button1:Enable();   
	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		local item_count = PlayerPackage:CountAvailableItemByIDTable(g_jfmz_itemid)
		JinFengMiZang_Cost_FengYe:SetText( ScriptGlobal_Format("#{JFMZ_180801_31}",item_count) )
	end
end
--===============================================
-- OnEvent()
--===============================================
function JinFengMiZang_On_ResetPos()
	JinFengMiZang_FrameNULL:SetProperty("UnifiedPosition", g_JinFengMiZang_Frame_UnifiedPosition)
end
--===============================================
-- OnHide()
--===============================================
function JinFengMiZang_Hide()
	KillTimer("JinFengMiZang_Replace_Tick()")
	KillTimer("JinFengMiZang_LuckyDraw_Tick()") 
	KillTimer("JinFengMiZang_LuckyDraw_Tick_End()") 
	JinFengMiZang_OnClose()
	this:Hide()
end
function JinFengMiZang_OnClose()
	g_SelectDelete_Button_Index = 0;
	g_TodayCount 			= 0;
	g_WanFaType 			= 0; 
	g_JinFengYeCount 		= 0;
	g_SuiXinBiCount 		= 0; 
	g_StepIndex1 			= 1;
	g_StepCur1 				= 1;
	g_Step1 		 		= 1;
	g_AddStep1 				= 0;
	g_LucyItemPos1 			= 0;
	g_LuckyItemPos 			= {}
	g_LuckyItemIndex 		= {}
end
--===============================================
-- OnOpen()
--===============================================
function JinFengMiZang_Open()
	JinFengMiZang_Control_Initial() 
	g_TodayCount 			= Get_XParam_INT( 8 ) 
	local tmpLucky			= Get_XParam_INT( 10 )
	g_JinFengYeCount 		= Get_XParam_INT( 11 )
	g_jfmz_luckynum 		= Get_XParam_INT( 12 )  
	g_jfmz_luckydoubleflag 	= Get_XParam_INT( 13 )  
	
	g_LuckyItemIndex[1]= math.mod(tmpLucky,100)
	g_LuckyItemIndex[2]= math.mod(math.floor(tmpLucky/100),100)
	g_LuckyItemIndex[3]= math.mod(math.floor(tmpLucky/10000),100)
	g_LuckyItemIndex[4]= math.mod(math.floor(tmpLucky/1000000),100)
	
	--如果是替换玩法 找到下标
	for i = 1, 8 do
		g_JinFengMiZang_Item_Index[i] =  Get_XParam_INT( i - 1 ) 
		for j=1,4 do
			if g_LuckyItemIndex[j] == g_JinFengMiZang_Item_Index[i] then  
				g_LuckyItemPos[j] = i;
			end
		end
	end
	local iteminfo = {}
	local kajiType = KaJi:LuaFnGetKaJiType(101)
	if kajiType == 1 then
		iteminfo = g_ItemList[1]
	else
		iteminfo = g_ItemList[0]
	end
	
	--构造物品
	for  i = 1, 8 do
		local ItemID = iteminfo[ g_JinFengMiZang_Item_Index[i] ].showid
		local theAction = DataPool:CreateBindActionItemForShow(ItemID, iteminfo[ g_JinFengMiZang_Item_Index[i] ].num)
   		if theAction:GetID() ~= 0 then
   			g_ItemAction[i]:SetActionItem(theAction:GetID());
   			g_ItemAction[i]:Show();
   		end
	end
	--设置控件内容
	JinFengMiZang_Cost_FengYe:SetText( ScriptGlobal_Format("#{JFMZ_180801_31}",g_JinFengYeCount) ) 
	JinFengMiZang_Pond_Numbertext:SetText( ScriptGlobal_Format("#{JFMZ_180801_20}",g_TodayCount) )	 
	JinFengMiZang_Button_Help:Show()
	JinFengMiZang_Pond_BK2:Hide()
	JinFengMiZang_Pond_BK:Show() 
	JinFengMiZang_Pond_Button1:Enable()   
	JinFengMiZang_Cost_Value_Text:SetText(ScriptGlobal_Format("#{JFMZ_220728_09}",g_jfmz_luckynum))

	if g_jfmz_luckynum >= 10  then
		JinFengMiZang_zhongjiang_Value:Show()
	else
		JinFengMiZang_zhongjiang_Value:Hide()
	end 	
	
	local iteminfo = {}
	local kajiType = KaJi:LuaFnGetKaJiType(101)
	if kajiType == 1 then
		iteminfo = g_ItemList[1] 
		JinFengMiZang_Cost_FengYe_Icon:SetToolTip("#{JFMZ_180801_93}");
	else
		iteminfo = g_ItemList[0]	
		JinFengMiZang_Cost_FengYe_Icon:SetToolTip("#{JFMZ_220728_16}"); 
	end

	this:Show()
end
--===============================================
-- Control Initial()
--===============================================
function JinFengMiZang_Control_Initial()
	for i = 1, 8 do
		 g_ItemAction[i]:SetActionItem( -1 );
		 g_ItemAction[i]:Show();
		 g_ItemAction_Animate[i]:Hide()
		 g_ItemAction_Animate1[i]:Hide() 
		 g_ItemAction_Double[i]:Hide()  
	end
end

--===============================================
-- Delete Button Click()
--===============================================
function JinFengMiZang_DeleteButton_Clicked() 
end

--===============================================
-- Double Button Click()
--===============================================
function JinFengMiZang_DoubleButton_Clicked()
	 
end

--===============================================
-- Change Button Click()
--===============================================
function JinFengMiZang_ChangeButton_Clicked( idx ) 
end

--===============================================
-- Require Replace Item  请求随机物品
--===============================================
function JinFengMiZang_Replace_Item(idx)  
end

--===============================================
-- DeleteButton SelectClicked() 删除玩法点击
--===============================================
function JinFengMiZang_DeleteButton_SelectClicked( Index )
 
end

--===============================================
-- Refresh When Replace() 替换刷新界面
--===============================================
function JinFengMiZang_Refresh_Replace( )
	for i = 1, 8 do
		 g_ItemAction[i]:Show();
		 g_ItemAction_Animate[i]:Hide() 
	end 
	for i =1 ,4 do 
		g_ItemAction_Animate[g_LuckyItemPos[i]]:Show() 
	
		local ItemID = g_ItemList_Replace[1 ].showid 
		if g_JinFengMiZang_ReplaceID == 2 then
			ItemID = g_ItemList_Replace[2].showid 
		end
		local iteminfo = {}
		local kajiType = KaJi:LuaFnGetKaJiType(101)
		if kajiType == 1 then
			iteminfo = g_ItemList[1]
		else
			iteminfo = g_ItemList[0]
		end

		local ItemNum =iteminfo[ g_LuckyItemIndex[i] ].num
		local theAction = DataPool:CreateActionItemForShow(ItemID, 1)
	 	if g_LuckyItemPos[i] == nil or g_LuckyItemPos[i]<= 0 or g_LuckyItemPos[i] > 8 then
	 		return
	 	end
		if theAction:GetID() ~= 0 then
			g_ItemAction[g_LuckyItemPos[i]]:SetActionItem(-1);
			g_ItemAction[g_LuckyItemPos[i]]:SetActionItem(theAction:GetID());
			g_ItemAction[g_LuckyItemPos[i]]:Show(); 
		end
	end
	SetTimer("JinFengMiZang","JinFengMiZang_Replace_Tick()", g_JinFengMiZang_Replace_TimerLength )

end

function JinFengMiZang_Random( ) 
	local nIsContinue = 1
	while 0 < nIsContinue
	do  
		local nIndex = math.random(1,8) 
		if nIndex ~= g_LuckyItemPos and 
			nIndex ~= g_LuckyItemPos1 and 
			nIndex ~= g_LuckyItemPos2 and 
			nIndex ~= g_LuckyItemPos3 then
				if g_LuckyItemPos1 == 0 then
					g_LuckyItemPos1 = nIndex  
				elseif g_LuckyItemPos2 == 0 then
					g_LuckyItemPos2= nIndex  
				elseif g_LuckyItemPos3 == 0 then
					g_LuckyItemPos3 = nIndex  
				end 
				if 	g_LuckyItemPos1 >0 and
					g_LuckyItemPos2 >0 and
					g_LuckyItemPos3 >0 then
				 		nIsContinue = 0;
				end
			end 
	end
end
--===============================================
-- 替换下发消息逻辑
--===============================================
function JinFengMiZang_Replace()

	g_LuckyItemIndex[1] 			=	Get_XParam_INT( 0 ) 
	g_LuckyItemIndex[2] 			=	Get_XParam_INT( 1 ) 
	g_LuckyItemIndex[3] 			=	Get_XParam_INT( 2 ) 
	g_LuckyItemIndex[4] 			=	Get_XParam_INT( 3 ) 
	g_JinFengMiZang_ReplaceID		=	Get_XParam_INT( 4 )
	g_WanFaType					 	= 	3
	--如果是替换玩法 找到下标
	for i = 1, 8 do 
		for j=1,4 do
			if g_LuckyItemIndex[j] == g_JinFengMiZang_Item_Index[i] then  
				g_LuckyItemPos[j] = i;
			end
		end
	end

	JinFengMiZang_Refresh_Replace()
end

--===============================================
-- 替换特效
--===============================================
function JinFengMiZang_Replace_Tick()
	for i=1,4 do
		g_ItemAction_Animate[g_LuckyItemPos[i]]:Hide()
	end
	KillTimer("JinFengMiZang_Replace_Tick()")
end
--===============================================
--抽奖点击
--===============================================
function JinFengMiZang_LuckyDraw_Clicked()

	if ( g_WanFaType == 1 ) and ( g_SelectDelete_Button_Index <=0 or g_SelectDelete_Button_Index > 8 )then
		PushDebugMessage("#{JFMZ_180801_58}")
		return
	end

	if ( g_WanFaType == 3 )   then
		for i=1 ,table.getn(g_LuckyItemIndex) do 
			if  (g_LuckyItemPos[i] == nil or g_LuckyItemPos[i] <=0 or g_LuckyItemPos[i] > 8 or g_LuckyItemIndex[i] <= 0 ) then
				return
			end
		end 
	end

	for i = 1, 8 do
		 g_ItemAction_Animate[i]:Hide() 
	end
	
	JinFengMiZang_Pond_Button1:Disable() 
	
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetLuckyItem_Begin" ); 					-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892881 );														-- 脚本编号
		Set_XSCRIPT_Parameter( 0, tonumber( 0 ) );										-- 参数一 玩法
		Set_XSCRIPT_Parameter( 1, tonumber( g_WanFaType ) );					-- 参数二 玩法
		Set_XSCRIPT_Parameter( 2, tonumber( g_SelectDelete_Button_Index ) );		-- 参数三 删除玩法 选择的位置
		Set_XSCRIPT_Parameter( 3, tonumber( 0 ) );										-- 参数四 双倍玩法 预留
		Set_XSCRIPT_Parameter( 4, tonumber( 0 ) );										-- 参数五 替换玩法 预留
		Set_XSCRIPT_ParamCount( 5 );															-- 参数个数
	Send_XSCRIPT()
	 
end

--===============================================
--抽奖 - 服务器返回
--===============================================
function JinFengMiZang_LuckyDraw_Return()

	g_LucyItemPos1  = Get_XParam_INT( 0 )  
	g_LucyItemPos2  = Get_XParam_INT( 1 )  
	g_StepIndex1		= 1;
	g_StepCur1			= 1;
	g_Step1			 	= 0;
	g_AddStep1			= g_LucyItemPos1 - 1 
	for i = 1, 8 do
		 g_ItemAction_Animate[i]:Hide()
	end
	
	for i = 1, 8 do
		 g_ItemAction_Animate1[i]:Hide()
	end
	
	for i = 1, 8 do
		g_ItemAction_Double[i]:Hide()
   	end
	g_ItemAction_Animate[g_StepCur1]:Show()
	g_Tick1 = 1
	g_Tick2 = 0
	if g_WanFaType == 2 then
		g_StepIndex2		= 1;
		g_StepCur2			= 1;
		g_Step2			 	= 0;
		g_AddStep2			= math.mod(  9 -  g_LucyItemPos2 ,8)     
		g_Tick2 = 1
		g_ItemAction_Animate1[g_StepCur2]:Show()
	end
	
	SetTimer("JinFengMiZang","JinFengMiZang_LuckyDraw_Tick()", g_Rates[g_StepIndex1] )
	--Lua_TDU_Log("SetTimer JinFengMiZang_LuckyDraw_Tick Begin")
end
--===============================================
--抽奖Tick
--===============================================
function JinFengMiZang_LuckyDraw_Tick()
	--Lua_TDU_Log("JinFengMiZang_LuckyDraw_Tick ::")
	if g_LucyItemPos1 > 0 and g_Tick1 ~= 0 then  
		g_ItemAction_Animate[g_StepCur1]:Hide()    
	end
	if g_LucyItemPos2 > 0 and g_Tick2 ~= 0 then
		g_ItemAction_Animate1[g_StepCur1]:Hide()    
	end
	g_StepCur1 = math.mod(g_StepCur1,8)+1;
	
	if g_LucyItemPos1 > 0 and g_Tick1 ~= 0 then 
		g_ItemAction_Animate[g_StepCur1]:Show() 
	end
	if g_LucyItemPos2 > 0 and g_Tick2 ~= 0  then
		g_ItemAction_Animate1[g_StepCur1]:Show() 
	end
	
	if g_Tick1 == 0  and  g_LucyItemPos1 > 0 then
		g_ItemAction_Animate[g_LucyItemPos1]:Show()   
	end
	if g_Tick2 == 0 and  g_LucyItemPos2 > 0 then
		g_ItemAction_Animate2[g_LucyItemPos2]:Show()   
	end
	
	g_Step1		= g_Step1 +1;
	g_Step2		= g_Step2 +1;
	if g_Step1 == g_Steps[g_StepIndex1] then

		if g_StepIndex1 < table.getn(g_Steps) then
			KillTimer("JinFengMiZang_LuckyDraw_Tick()")
			--Lua_TDU_Log("KillTimer JinFengMiZang_LuckyDraw_Tick()) g_StepIndex1 ::"..g_StepIndex1)
			g_StepIndex1 	= g_StepIndex1 + 1
			g_Step1			= 0;
			g_StepIndex2 	= g_StepIndex2 + 1
			g_Step2			= 0;
			SetTimer("JinFengMiZang","JinFengMiZang_LuckyDraw_Tick()", g_Rates[g_StepIndex1] )
			--Lua_TDU_Log("SetTimer JinFengMiZang_LuckyDraw_Tick g_StepIndex1 ::"..g_StepIndex1)
		end
	end

	if g_StepIndex1 == table.getn(g_Steps) and g_Step1 == g_Steps[g_StepIndex1] + g_AddStep1 and g_Tick1 ~=0 and  g_LucyItemPos1 > 0  then 
		g_Tick1 = 0  
		g_ItemAction_Animate[g_LucyItemPos1]:Show()   
		if math.floor(g_jfmz_luckydoubleflag/10) == 1 then
			for posi = 1, 8 do
				g_ItemAction_Animate[posi]:Show() 
			end
		elseif math.mod(g_jfmz_luckydoubleflag,10) == 1 then
			g_ItemAction_Double[g_LucyItemPos1]:Show()
		end
	end
	
	if g_StepIndex2 == table.getn(g_Steps) and g_Step2 == g_Steps[g_StepIndex2] + g_AddStep2 and g_Tick2 ~=0 and  g_LucyItemPos2 > 0 then 
		g_Tick2 = 0 
		--Lua_TDU_Log("  JinFengMiZang_LuckyDraw_Tick g_Tick2 = 0  ")
		g_ItemAction_Animate2[g_LucyItemPos2]:Show()   
	end	
	
	if g_Tick2 == 0 and g_Tick1 == 0 then
		--Lua_TDU_Log("KillTimer JinFengMiZang_LuckyDraw_Tick())")
		KillTimer("JinFengMiZang_LuckyDraw_Tick()") 
		JinFengMiZang_Tick_End() 
	end
end 
--===============================================
--Tick完成 告知服务器 准备给物品
--===============================================
function JinFengMiZang_Tick_End()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetLuckyItem_End" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 892881 );								-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );									-- 参数个数
	Send_XSCRIPT()
end

--===============================================
--取消选择
--===============================================
function JinFengMiZang_Button_Cancel_Click()
	g_WanFaType = 0; 
	JinFengMiZang_Button_Help:Show()
	JinFengMiZang_Pond_BK2:Hide()
	JinFengMiZang_Pond_BK:Show() 
	for j = 1, 8 do 
		 g_ItemAction_Animate[j]:Hide() 
	end

	--还原替换ID
	for i=1 , table.getn(g_LuckyItemIndex) do 
	  if g_LuckyItemIndex[i] > 0 and g_LuckyItemIndex[i] <= table.getn( iteminfo ) then
		 local ItemID = iteminfo[g_LuckyItemIndex[i]].showid 
		 local ItemNum =iteminfo[ g_LuckyItemIndex[i] ].num
		 local theAction = DataPool:CreateActionItemForShow(ItemID, ItemNum)
		if g_LuckyItemPos[i] == nil or g_LuckyItemPos[i]<= 0 or g_LuckyItemPos[i] > 8 then
		 		return
		end
		 if theAction:GetID() ~= 0 then
			g_ItemAction[ g_LuckyItemPos[i] ]:SetActionItem(-1);
			g_ItemAction[ g_LuckyItemPos[i] ]:SetActionItem(theAction:GetID());
			g_ItemAction[ g_LuckyItemPos[i] ]:Show();
		 end
	  end
	end
end

--===============================================
--抽奖结束 关闭界面
--===============================================
function JinFengMiZang_LuckyDraw_End() 
	g_TodayCount 			=	Get_XParam_INT( 0 ) 
	g_JinFengYeCount 		= Get_XParam_INT( 1 ) 
	g_jfmz_luckynum 		= Get_XParam_INT( 2 )
	g_jfmz_luckydoubleflag	= Get_XParam_INT( 3 )
	JinFengMiZang_Cost_FengYe:SetText( ScriptGlobal_Format("#{JFMZ_180801_31}",g_JinFengYeCount) ) 
	JinFengMiZang_Pond_Numbertext:SetText( ScriptGlobal_Format("#{JFMZ_180801_20}",g_TodayCount) )	
	JinFengMiZang_Cost_Value_Text:SetText(ScriptGlobal_Format("#{JFMZ_220728_09}",g_jfmz_luckynum))
	JinFengMiZang_Pond_Button1:Disable()
	SetTimer("JinFengMiZang","JinFengMiZang_LuckyDraw_Tick_End()", g_JinFengMiZang_TickEnd_TimerLength )
end

--===============================================
--抽奖Tick结束 关闭界面
--===============================================
function JinFengMiZang_LuckyDraw_Tick_End()
	
	KillTimer("JinFengMiZang_LuckyDraw_Tick_End()") 
	JinFengMiZang_Pond_Button1:Enable()
	JinFengMiZang_Hide()
	--Lua_TDU_Log(" JinFengMiZang_LuckyDraw_Tick_End())")
end 
--===============================================
--帮助
--===============================================
function JinFengMiZang_Button_Help_Click()
	PushEvent("OPEN_JFMZ_HELP")
end 
