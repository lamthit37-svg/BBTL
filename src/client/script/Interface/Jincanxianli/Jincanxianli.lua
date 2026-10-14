
local g_Jincanxianli_Frame_UnifiedPosition;
local Jincanxianli_g_nTotal = 9
local Jincanxianli_g_ButtonTotal = 6
local Jincanxianli_g_Buttons = {}
local Jincanxianli_g_ButtonTips = {}
local Jincanxianli_g_pos = ""
local Jincanxianli_g_Fanli_Phase=0;
local Jincanxianli_g_Fanli_TodayBuyed=0;
local Jincanxianli_g_Fanli_Index=0;
local Jincanxianli_g_Fanli_ActionItem={};
local Jincanxianli_g_Fanli_ActionItem_Mask={};
local Jincanxianli_g_Fanli_BackLight={};

local Jincanxianli_g_Desc6={
	[0] = "#{JSXL_230224_10}",
	[1] = "#{JSXL_230224_11}",
	[2] = "#{JSXL_230224_12}",
	[3] = "#{JSXL_230224_13}",
	[4] = "#{JSXL_230224_14}",
	}
	
--返利
local Jincanxianli_g_Fanli_Info={
	[0] = { BonusCount=0,  info="#{JSXL_230224_29}", info2="#{JSXL_230224_43}", image="set:Jincanxianli image:Level9"},
	[1] = { BonusCount=5,  info="#{JSXL_230224_30}", info2="#{JSXL_230224_44}", image="set:Jincanxianli image:Level1"},
	[2] = { BonusCount=11, info="#{JSXL_230224_31}", info2="#{JSXL_230224_45}", image="set:Jincanxianli image:Level2"},
	[3] = { BonusCount=18, info="#{JSXL_230224_32}", info2="#{JSXL_230224_46}", image="set:Jincanxianli image:Level3"},
	[4] = { BonusCount=27, info="#{JSXL_230224_33}", info2="#{JSXL_230224_47}", image="set:Jincanxianli image:Level4"},
	[5] = { BonusCount=42, info="#{JSXL_230224_34}", info2="#{JSXL_230224_48}", image="set:Jincanxianli image:Level5"},
	[6] = { BonusCount=57, info="#{JSXL_230224_35}", info2="#{JSXL_230224_49}", image="set:Jincanxianli image:Level6"},
	[7] = { BonusCount=72, info="#{JSXL_230224_36}", info2="#{JSXL_230224_50}", image="set:Jincanxianli image:Level7"},
	[8] = { BonusCount=87, info="#{JSXL_230224_37}", info2="#{JSXL_230224_51}", image="set:Jincanxianli image:Level8"},
}

function Jincanxianli_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("JINCANSI_BUY_UPDATE")
	this:RegisterEvent("PLAYER_LEAVE_WORLD",false)		-- 离开场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		-- 离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)			-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	        -- 游戏分辨率发生了变化
end

function Jincanxianli_OnLoad()
	g_Jincanxianli_Frame_UnifiedPosition = Jincanxianli_Frame:GetProperty("UnifiedPosition")
	for i = 1, Jincanxianli_g_ButtonTotal do
		Jincanxianli_g_Buttons[i] = _G[ "Jincanxianli_Frame1_Button"..i ]
		Jincanxianli_g_ButtonTips[i] = _G[ string.format("Jincanxianli_Frame1_Button%d_tips",i) ]
	end
	
	Jincanxianli_g_Fanli_ActionItem[1] = Jincanxianli_Fanli_Level_Get_Day1_Item;
	Jincanxianli_g_Fanli_ActionItem[2] = Jincanxianli_Fanli_Level_Get_Day2_Item;
	Jincanxianli_g_Fanli_ActionItem[3] = Jincanxianli_Fanli_Level_Get_Day3_Item;
	Jincanxianli_g_Fanli_ActionItem[4] = Jincanxianli_Fanli_Level_Get_Day4_Item;
	
	Jincanxianli_g_Fanli_ActionItem_Mask[1] = Jincanxianli_Fanli_Level_Get_Day1_Item_Mask;
	Jincanxianli_g_Fanli_ActionItem_Mask[2] = Jincanxianli_Fanli_Level_Get_Day2_Item_Mask;
	Jincanxianli_g_Fanli_ActionItem_Mask[3] = Jincanxianli_Fanli_Level_Get_Day3_Item_Mask;
	Jincanxianli_g_Fanli_ActionItem_Mask[4] = Jincanxianli_Fanli_Level_Get_Day4_Item_Mask;
	
	Jincanxianli_g_Fanli_BackLight[1] = Jincanxianli_Fanli_Level_Get_Day1_LightBK;
	Jincanxianli_g_Fanli_BackLight[2] = Jincanxianli_Fanli_Level_Get_Day2_LightBK;
	Jincanxianli_g_Fanli_BackLight[3] = Jincanxianli_Fanli_Level_Get_Day3_LightBK;
	Jincanxianli_g_Fanli_BackLight[4] = Jincanxianli_Fanli_Level_Get_Day4_LightBK;
			
	Jincanxianli_g_pos = Jincanxianli_Frame:GetProperty("UnifiedPosition")
end

function Jincanxianli_OnEvent(event)
	if event == "UI_COMMAND" and arg0 == "89098301" then
	
		local nOpType = Get_XParam_INT(0) --1,打开;2,刷新
		if nOpType == 1 then
			if this:IsVisible() then
				this:Hide()
				return
			else
				Jincanxianli_g_Fanli_Phase = Get_XParam_INT(1) 
				Jincanxianli_SiwtchPage( Jincanxianli_g_Fanli_Phase )
				if Jincanxianli_g_Fanli_Phase == 1 then
					Jincanxianli_Page1:Enable();
					Jincanxianli_Update()
				elseif Jincanxianli_g_Fanli_Phase == 2 then
					Jincanxianli_Page1:Disable();
				end
				Jincanxianli_Frame:SetProperty("UnifiedPosition",Jincanxianli_g_pos)
				this:Show()
			end
		end
		
		if this:IsVisible() then
			Jincanxianli_g_Fanli_Phase = Get_XParam_INT(1)
			Jincanxianli_g_Fanli_TodayBuyed = Get_XParam_INT(2) 
			Jincanxianli_g_Fanli_Index = Get_XParam_INT(3) 
			Jincanxianli_Fanli_Update();
		end
				
	elseif event == "JINCANSI_BUY_UPDATE" then
		Jincanxianli_Update()
		Jincanxianli_Fanli_Update();
	elseif (event == "PLAYER_LEAVE_WORLD") then
		Jincanxianli_OnClose()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Jincanxianli_OnClose()
	elseif (event == "ADJEST_UI_POS") then
		Jincanxianli_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Jincanxianli_On_ResetPos()
	end
end

--切换页面
function Jincanxianli_SiwtchPage( index )
	--Jincanxianli_Page1
	--Jincanxianli_Page2
	if index == 1 then
		Jincanxianli_Page1:SetCheck(1);
		Jincanxianli_Page2:SetCheck(0)
		Jincanxianli_Frame_Client:Show();
		Jincanxianli_Frame_Client2:Hide();
	elseif index == 2 then
		Jincanxianli_Page1:SetCheck(0);
		Jincanxianli_Page2:SetCheck(1)
		Jincanxianli_Frame_Client:Hide();
		Jincanxianli_Frame_Client2:Show();
	end
	
end


function Jincanxianli_Update()
	--前面五个
	for i = 1, Jincanxianli_g_ButtonTotal-1 do
		if DataPool:GetJinCanSi_Buy_Flag(i) == 0 then
			Jincanxianli_g_Buttons[i]:Enable()
			Jincanxianli_g_ButtonTips[i]:Hide()
		else
			Jincanxianli_g_Buttons[i]:Disable()
			Jincanxianli_g_ButtonTips[i]:Show()
		end
	end
	--最后一个
	local nCount = 0;
	for i=Jincanxianli_g_ButtonTotal, Jincanxianli_g_nTotal do
		nCount = nCount + DataPool:GetJinCanSi_Buy_Flag(i)
	end
	if nCount < (Jincanxianli_g_nTotal - Jincanxianli_g_ButtonTotal + 1) then
		Jincanxianli_g_Buttons[Jincanxianli_g_ButtonTotal]:Enable()
		Jincanxianli_g_ButtonTips[Jincanxianli_g_ButtonTotal]:Hide()
	else
		Jincanxianli_g_Buttons[Jincanxianli_g_ButtonTotal]:Disable()
		Jincanxianli_g_ButtonTips[Jincanxianli_g_ButtonTotal]:Show()
	end
	if Jincanxianli_g_Desc6[nCount] ~= nil then
		Jincanxianli_Frame1_Text6:SetText( Jincanxianli_g_Desc6[nCount] );
		Jincanxianli_Frame1_Text6_BuyProgress:SetText( ScriptGlobal_Format("#{JSXL_230224_39}",nCount) );
	end
end

function Jincanxianli_Fanli_Update()
	--得到等级
	local nFanliLevel = 0;
	for i = 2, Jincanxianli_g_nTotal do
		if DataPool:GetJinCanSi_Buy_Flag(i) == 1 then
			nFanliLevel = nFanliLevel + 1;
		end
	end
	
	--等级显示
	if Jincanxianli_g_Fanli_Info[nFanliLevel] == nil then
		return
	end
	
	Jincanxianli_Fanli_LevelBK:SetProperty( "Image", Jincanxianli_g_Fanli_Info[nFanliLevel].image );
	if Jincanxianli_g_Fanli_Phase == 1 then
		Jincanxianli_Fanli_Level_Info:SetText( Jincanxianli_g_Fanli_Info[nFanliLevel].info );
	else
		Jincanxianli_Fanli_Level_Info:SetText( Jincanxianli_g_Fanli_Info[nFanliLevel].info2 );
	end
	
	local bTodayCanBuy=0;
	for i=1, 4 do
		--展示道具
		local theAction = DataPool:CreateBindActionItemForShow(39924119, Jincanxianli_g_Fanli_Info[nFanliLevel].BonusCount)
	  if theAction:GetID() ~= 0 then
    	Jincanxianli_g_Fanli_ActionItem[i]:SetActionItem(theAction:GetID())
    end
    
    --是否已购买
		if i <= Jincanxianli_g_Fanli_Index then
			Jincanxianli_g_Fanli_ActionItem_Mask[i]:Show();
		else
			Jincanxianli_g_Fanli_ActionItem_Mask[i]:Hide();
		end
		
		--当前可购买
		if Jincanxianli_g_Fanli_Phase >= 2 and nFanliLevel > 0 and i==Jincanxianli_g_Fanli_Index+1-Jincanxianli_g_Fanli_TodayBuyed then
			Jincanxianli_g_Fanli_BackLight[i]:Show();
			bTodayCanBuy = 1;
		else
			Jincanxianli_g_Fanli_BackLight[i]:Hide();
		end
		
	end
	
	--小红点
	if bTodayCanBuy > 0 and Jincanxianli_g_Fanli_TodayBuyed == 0 then
		Jincanxianli_Fanli_Level_Get_Day_Select_Tips:Show();
		Jincanxianli_Page2_Tips:Show();
	else
		Jincanxianli_Fanli_Level_Get_Day_Select_Tips:Hide();
		Jincanxianli_Page2_Tips:Hide();
	end
	
	--购买按钮
	if Jincanxianli_g_Fanli_TodayBuyed >= 1 then
		Jincanxianli_Fanli_Level_Get_Day_Select:Hide();
		Jincanxianli_Fanli_Level_Get_Day_Got:Show()
	else
		Jincanxianli_Fanli_Level_Get_Day_Select:Show();
		Jincanxianli_Fanli_Level_Get_Day_Got:Hide()
	end
	
end

function Jincanxianli_OnBuy(idx)
	if idx < 1 or idx > Jincanxianli_g_nTotal then
		return
	end
	
	local nIndex = idx;
	if nIndex >= Jincanxianli_g_ButtonTotal then
		for i=Jincanxianli_g_ButtonTotal, Jincanxianli_g_nTotal do
			nIndex = nIndex + DataPool:GetJinCanSi_Buy_Flag(i);
		end
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnJinCanSi_Action")
		Set_XSCRIPT_ScriptID(890983)
		Set_XSCRIPT_Parameter(0,-1)
		Set_XSCRIPT_Parameter(1,nIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--index: 1~4
function Jincanxianli_Fanli_Level_Get_SelectClicked(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnJinCanSi_GetBonus")
		Set_XSCRIPT_ScriptID(890983)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Jincanxianli_OnClose()
	this:Hide()
end

function Jincanxianli_OnHide()

end

function Jincanxianli_OnHelp()
	PushEvent("CCSHOP_HELP", 189)
end

--===============================================
-- ResetPos()
--===============================================
function Jincanxianli_On_ResetPos()
	Jincanxianli_Frame:SetProperty("UnifiedPosition", g_Jincanxianli_Frame_UnifiedPosition)
end