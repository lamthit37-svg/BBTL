-- 时装预购 + 二次购买

local g_Frame_UnifiedPosition

--当前页面 1是预购 2是尾款 3是二次购买
local g_SpringFestival_Fashion_CurPage = 1

local g_SpringFestival_Fashion_Page = {}

local g_SpringFestival_Fashion_Item1 = 39922041
local g_SpringFestival_Fashion_Item2 = 39922037

local g_SpringFestival_Fashion_bindID = 39922043
local g_SpringFestival_Fashion_unbindID = 39922042

local g_SpringFestival_Fashion_Cut = 0 
local g_SpringFestival_Fashion_SecCut = 0 
local g_SpringFestival_Fashion_Title = 0
local g_SpringFestival_Fashion_SecBuy = 0
local g_SpringFestival_Fashion_CurState = 0

local g_SpringFestival_Fashion_NumList = {
[0] = "set:Spring16 image:Yugou_0",
[1] = "set:Spring16 image:Yugou_1",
[2] = "set:Spring16 image:Yugou_2",
[3] = "set:Spring16 image:Yugou_3",
[4] = "set:Spring16 image:Yugou_4",
[5] = "set:Spring16 image:Yugou_5",
[6] = "set:Spring16 image:Yugou_6",
[7] = "set:Spring16 image:Yugou_7",
[8] = "set:Spring16 image:Yugou_8",
[9] = "set:Spring16 image:Yugou_9",
}

local g_SpringFestival_Fashion_CutList = {
[0] = "set:Spring16 image:Discount_0",
[1] = "set:Spring16 image:Discount_1",
[2] = "set:Spring16 image:Discount_2",
[3] = "set:Spring16 image:Discount_3",
[4] = "set:Spring16 image:Discount_4",
[5] = "set:Spring16 image:Discount_5",
[6] = "set:Spring16 image:Discount_6",
[7] = "set:Spring16 image:Discount_7",
[8] = "set:Spring16 image:Discount_8",
[9] = "set:Spring16 image:Discount_9",
}

local g_SpringFestival_Fashion_Image = {}

local g_SpringFestival_Fashion_ImageCost = {}

local g_SpringFestival_Fashion_ImageCost2 = {}

--=========
-- PreLoad
--=========
function SpringFestival_Fashion_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

--=========
-- OnLoad
--=========
function SpringFestival_Fashion_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_Fashion_Frame:GetProperty("UnifiedPosition") 
	
	g_SpringFestival_Fashion_Page = {
				SpringFestival_Fashion_Yugou, 
				SpringFestival_Fashion_WeiKuan, 
				SpringFestival_Fashion_Two
				}
	
	g_SpringFestival_Fashion_Image = {
		SpringFestival_Fashion_DiscountText1, SpringFestival_Fashion_DiscountText3, SpringFestival_Fashion_DiscountText2, 
	}
	
	g_SpringFestival_Fashion_ImageCost = {
		[1] = {SpringFestival_Fashion_List3, SpringFestival_Fashion_Number5_10, SpringFestival_Fashion_Number5_9, SpringFestival_Fashion_Number5_8, SpringFestival_Fashion_Number5_7, SpringFestival_Fashion_Number5_6},
		[2] = {SpringFestival_Fashion_List4, SpringFestival_Fashion_Number4_8, SpringFestival_Fashion_Number4_7, SpringFestival_Fashion_Number4_6, SpringFestival_Fashion_Number4_5}
	}
	
	g_SpringFestival_Fashion_ImageCost2 = {
		[1] = {SpringFestival_Fashion_List1, SpringFestival_Fashion_Number5_5, SpringFestival_Fashion_Number5_4, SpringFestival_Fashion_Number5_3, SpringFestival_Fashion_Number5_2, SpringFestival_Fashion_Number5_1},
		[2] = {SpringFestival_Fashion_List2, SpringFestival_Fashion_Number4_4, SpringFestival_Fashion_Number4_3, SpringFestival_Fashion_Number4_2, SpringFestival_Fashion_Number4_1}
	}
	
end

--=========
-- OnEvent
--=========
function SpringFestival_Fashion_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 89332401 then
	
		local bShow = Get_XParam_INT(0)
		if bShow == 1 then
			g_SpringFestival_Fashion_CurPage = Get_XParam_INT(1)
			
			g_SpringFestival_Fashion_Cut = Get_XParam_INT(2)
			
			g_SpringFestival_Fashion_SecCut = Get_XParam_INT(3)
			
			g_SpringFestival_Fashion_Title = Get_XParam_INT(4)
			
			g_SpringFestival_Fashion_SecBuy = Get_XParam_INT(5)
			
			g_SpringFestival_Fashion_CurState = Get_XParam_INT(6)
			
			SpringFestival_Fashion_Update()	
		elseif bShow == 2 then
			
			g_SpringFestival_Fashion_Cut = Get_XParam_INT(1)			
				
			SpringFestival_Fashion_UpdateDiKouValue()	
			
		else
			SpringFestival_Fashion_OnHiden()
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_Fashion_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival_Fashion_On_ResetPos()
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
	
		SpringFestival_Fashion_OnHiden();

	end

end

function SpringFestival_Fashion_UpdateDiKouValue()	

	if IsWindowShow("SpringFestival_Fashion") and g_SpringFestival_Fashion_CurPage == 1 then
	
		SpringFestival_Fashion_DiscountText6:Show()
		local str = ScriptGlobal_Format("#{SZYG_191126_140}", g_SpringFestival_Fashion_Cut)
		SpringFestival_Fashion_DiscountText6:SetText(str)
		
	end

	if IsWindowShow("SpringFestival_Fashion") and g_SpringFestival_Fashion_CurPage == 2 then
					
		local strmsg = ""
		strmsg = ScriptGlobal_Format("#{SZYG_191126_24}", g_SpringFestival_Fashion_Cut)
		SpringFestival_Fashion_DiscountText:SetText( strmsg )
			
		local nCost = 20000 - g_SpringFestival_Fashion_Cut
		if g_SpringFestival_Fashion_Cut == 0 then
			SpringFestival_Fashion_RewardBk2:SetProperty("UnifiedPosition","{{0.000000,110.000000},{1.000000,-74.000000}}")
			SpringFestival_Fashion_PriceText1:Hide()	
			SpringFestival_Fashion_PriceText2:Hide()
		else	
			SpringFestival_Fashion_RewardBk2:SetProperty("UnifiedPosition","{{0.000000,114.000000},{1.000000,-88.000000}}")
			SpringFestival_Fashion_PriceText1:Show()
			SpringFestival_Fashion_PriceText2:Show()
		end
		
		local nNum1 = math.mod( nCost, 10 )
		local nData = math.floor( nCost / 10 )
		local nNum2 = math.mod( nData, 10 )
		nData = math.floor( nData / 10 )
		local nNum3 = math.mod( nData, 10 )
		nData = math.floor( nData / 10 )
		local nNum4 = math.mod( nData, 10 )
		nData = math.floor( nData / 10 )
		local nNum5 = math.mod( nData, 10 )
		if nNum5 == 0 then
			-- 四位数
			g_SpringFestival_Fashion_ImageCost2[1][1]:Hide()
			g_SpringFestival_Fashion_ImageCost2[2][1]:Show()
			
			if g_SpringFestival_Fashion_NumList[nNum1] ~= nil then
				g_SpringFestival_Fashion_ImageCost2[2][2]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum1])
			end
			if g_SpringFestival_Fashion_NumList[nNum2] ~= nil then
				g_SpringFestival_Fashion_ImageCost2[2][3]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum2])
			end
			if g_SpringFestival_Fashion_NumList[nNum3] ~= nil then
				g_SpringFestival_Fashion_ImageCost2[2][4]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum3])
			end
			if g_SpringFestival_Fashion_NumList[nNum4] ~= nil then
				g_SpringFestival_Fashion_ImageCost2[2][5]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum4])
			end
		else
			-- 五位数
			g_SpringFestival_Fashion_ImageCost2[1][1]:Show()
			g_SpringFestival_Fashion_ImageCost2[2][1]:Hide()
			
			if g_SpringFestival_Fashion_NumList[nNum1] ~= nil then
				g_SpringFestival_Fashion_ImageCost2[1][2]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum1])
			end
			if g_SpringFestival_Fashion_NumList[nNum2] ~= nil then
				g_SpringFestival_Fashion_ImageCost2[1][3]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum2])
			end
			if g_SpringFestival_Fashion_NumList[nNum3] ~= nil then
				g_SpringFestival_Fashion_ImageCost2[1][4]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum3])
			end
			if g_SpringFestival_Fashion_NumList[nNum4] ~= nil then
				g_SpringFestival_Fashion_ImageCost2[1][5]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum4])
			end
			if g_SpringFestival_Fashion_NumList[nNum5] ~= nil then
				g_SpringFestival_Fashion_ImageCost2[1][6]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum5])
			end
		end	
	end
	
end	

--=========
-- 打开
--=========
function SpringFestival_Fashion_Update()		

	this:Show()

	for i = 1, table.getn(g_SpringFestival_Fashion_Page) do
		if i == g_SpringFestival_Fashion_CurPage then
			g_SpringFestival_Fashion_Page[i]:Show()
		else
			g_SpringFestival_Fashion_Page[i]:Hide()
		end
	end
	
	if g_SpringFestival_Fashion_CurState == 1 then
		SpringFestival_Fashion_Time:Show()
		SpringFestival_Fashion_ArrowUp:Show()
		SpringFestival_Fashion_ArrowDown:Hide()		
	elseif g_SpringFestival_Fashion_CurState == 2 then
		SpringFestival_Fashion_Time:Show()
		SpringFestival_Fashion_ArrowUp:Hide()
		SpringFestival_Fashion_ArrowDown:Show()		
	else
		SpringFestival_Fashion_Time:Hide()
	end
	
	if g_SpringFestival_Fashion_CurPage == 1 then
		SpringFestival_Fashion_Time:Show()
		
		SpringFestival_Fashion_DiscountText6:Show()
		local str = ScriptGlobal_Format("#{SZYG_191126_140}", g_SpringFestival_Fashion_Cut)
		SpringFestival_Fashion_DiscountText6:SetText(str)
	
		local theAction = DataPool:CreateActionItemForShow(g_SpringFestival_Fashion_Item1, 1)
		if theAction:GetID() ~= 0 then
			SpringFestival_Fashion_Clothe1:SetActionItem(theAction:GetID());
		end

		local theAction = DataPool:CreateActionItemForShow(g_SpringFestival_Fashion_Item2, 1)
		if theAction:GetID() ~= 0 then
			SpringFestival_Fashion_Fond:SetActionItem(theAction:GetID());
		end
		
		if g_SpringFestival_Fashion_Title == 0 then
			SpringFestival_Fashion_RewardText1:SetProperty("UnifiedPosition","{{0.000000,10.000000},{0.000000,0.000000}}")
			SpringFestival_Fashion_RewardText2:Show()
			SpringFestival_Fashion_FreeText1:Show()
		else
			SpringFestival_Fashion_RewardText1:SetProperty("UnifiedPosition","{{0.000000,12.000000},{0.000000,8.000000}}")
			SpringFestival_Fashion_RewardText2:Hide()
			SpringFestival_Fashion_FreeText1:Hide()
		end
		
	elseif g_SpringFestival_Fashion_CurPage == 2 then
		SpringFestival_Fashion_Time:Show()
	
		local theAction = DataPool:CreateActionItemForShow(g_SpringFestival_Fashion_bindID, 1)
		if theAction:GetID() ~= 0 then
			SpringFestival_Fashion_Clothe2:SetActionItem(theAction:GetID());
		end
		
		SpringFestival_Fashion_UpdateDiKouValue()
		
		local curDay = tonumber(DataPool:GetServerDayTime());
		if g_SpringFestival_Fashion_CurState == 1 then
			SpringFestival_Fashion_RewardCover:Show()
		else
			SpringFestival_Fashion_RewardCover:Hide()
		end
		
	elseif g_SpringFestival_Fashion_CurPage == 3 then
		SpringFestival_Fashion_Time:Hide()
	
		local theAction = DataPool:CreateActionItemForShow(g_SpringFestival_Fashion_unbindID, 1)
		if theAction:GetID() ~= 0 then
			SpringFestival_Fashion_Clothe3:SetActionItem(theAction:GetID());
		end
		
		if g_SpringFestival_Fashion_SecCut == 0 or g_SpringFestival_Fashion_SecCut == 100 then
			SpringFestival_Fashion_RewardBk3:SetProperty("UnifiedPosition","{{0.000000,112.000000},{1.000000,-75.000000}}")
			SpringFestival_Fashion_PriceText3:Hide()
			SpringFestival_Fashion_PriceText4:Hide()
			SpringFestival_Fashion_DiscountText1:Hide()
			SpringFestival_Fashion_DiscountText2:Hide()
			SpringFestival_Fashion_DiscountText3:Hide()
			SpringFestival_Fashion_DiscountText5:Hide()
			SpringFestival_Fashion_NoDiscount:Show()
		else
			SpringFestival_Fashion_RewardBk3:SetProperty("UnifiedPosition","{{0.000000,114.000000},{1.000000,-88.000000}}")
			SpringFestival_Fashion_PriceText3:Show()
			SpringFestival_Fashion_PriceText4:Show()
			SpringFestival_Fashion_DiscountText1:Show()
			SpringFestival_Fashion_DiscountText2:Show()
			SpringFestival_Fashion_DiscountText3:Show()
			SpringFestival_Fashion_DiscountText5:Show()
			SpringFestival_Fashion_NoDiscount:Hide()
		
			local nfirst = math.floor(g_SpringFestival_Fashion_SecCut / 10)
			local nsecond = math.mod( g_SpringFestival_Fashion_SecCut, 10 )
			
			if nfirst == 0 then
				-- 一位数
				g_SpringFestival_Fashion_Image[2]:Show()
				g_SpringFestival_Fashion_Image[1]:Hide()
				g_SpringFestival_Fashion_Image[3]:Hide()
				
				if g_SpringFestival_Fashion_CutList[nsecond] ~= nil then
					g_SpringFestival_Fashion_Image[2]:SetProperty( "Image", g_SpringFestival_Fashion_CutList[nsecond])
				end
			else
				-- 两位数
				g_SpringFestival_Fashion_Image[1]:Show()
				g_SpringFestival_Fashion_Image[3]:Show()
				g_SpringFestival_Fashion_Image[2]:Show()
				
				if g_SpringFestival_Fashion_CutList[nsecond] ~= nil then
					g_SpringFestival_Fashion_Image[2]:SetProperty( "Image", g_SpringFestival_Fashion_CutList[nsecond])
				end
				
				if g_SpringFestival_Fashion_CutList[nfirst] ~= nil then
					g_SpringFestival_Fashion_Image[1]:SetProperty( "Image", g_SpringFestival_Fashion_CutList[nfirst])
				end
			end
		end
		
		if g_SpringFestival_Fashion_SecBuy == 1 then
			SpringFestival_Fashion_RewardButton3:Disable()
		else
			SpringFestival_Fashion_RewardButton3:Enable()
		end
		
		local nCost = math.floor(20000 * g_SpringFestival_Fashion_SecCut / 100)
		local nNum1 = math.mod( nCost, 10 )
		local nData = math.floor( nCost / 10 )
		local nNum2 = math.mod( nData, 10 )
		nData = math.floor( nData / 10 )
		local nNum3 = math.mod( nData, 10 )
		nData = math.floor( nData / 10 )
		local nNum4 = math.mod( nData, 10 )
		nData = math.floor( nData / 10 )
		local nNum5 = math.mod( nData, 10 )
		if nNum5 == 0 then
			-- 四位数
			g_SpringFestival_Fashion_ImageCost[1][1]:Hide()
			g_SpringFestival_Fashion_ImageCost[2][1]:Show()
			
			if g_SpringFestival_Fashion_NumList[nNum1] ~= nil then
				g_SpringFestival_Fashion_ImageCost[2][2]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum1])
			end
			if g_SpringFestival_Fashion_NumList[nNum2] ~= nil then
				g_SpringFestival_Fashion_ImageCost[2][3]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum2])
			end
			if g_SpringFestival_Fashion_NumList[nNum3] ~= nil then
				g_SpringFestival_Fashion_ImageCost[2][4]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum3])
			end
			if g_SpringFestival_Fashion_NumList[nNum4] ~= nil then
				g_SpringFestival_Fashion_ImageCost[2][5]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum4])
			end
		else
			-- 五位数
			g_SpringFestival_Fashion_ImageCost[1][1]:Show()
			g_SpringFestival_Fashion_ImageCost[2][1]:Hide()
			
			if g_SpringFestival_Fashion_NumList[nNum1] ~= nil then
				g_SpringFestival_Fashion_ImageCost[1][2]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum1])
			end
			if g_SpringFestival_Fashion_NumList[nNum2] ~= nil then
				g_SpringFestival_Fashion_ImageCost[1][3]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum2])
			end
			if g_SpringFestival_Fashion_NumList[nNum3] ~= nil then
				g_SpringFestival_Fashion_ImageCost[1][4]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum3])
			end
			if g_SpringFestival_Fashion_NumList[nNum4] ~= nil then
				g_SpringFestival_Fashion_ImageCost[1][5]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum4])
			end
			if g_SpringFestival_Fashion_NumList[nNum5] ~= nil then
				g_SpringFestival_Fashion_ImageCost[1][6]:SetProperty( "Image", g_SpringFestival_Fashion_NumList[nNum5])
			end
		end
	else
		SpringFestival_Fashion_OnHiden()
	end
	
end

--=========
-- 关闭
--=========
function SpringFestival_Fashion_OnHiden()

	this:Hide()

end

--=========
-- 重置
--=========
function SpringFestival_Fashion_On_ResetPos()

	SpringFestival_Fashion_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 预购
--=========
function SpringFestival_Fashion_PrePay()

    Clear_XSCRIPT()
    	Set_XSCRIPT_Function_Name("OnFashionPrePay")
    	Set_XSCRIPT_ScriptID(893324)
    	Set_XSCRIPT_Parameter(0,1);
    	Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()		
	
end

--=========
-- 购买
--=========
function SpringFestival_Fashion_FinalPay()

    Clear_XSCRIPT()
    	Set_XSCRIPT_Function_Name("OnFashionFinalPay")
    	Set_XSCRIPT_ScriptID(893324)
    	Set_XSCRIPT_Parameter(0,1);
    	Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()		
	
end

--=========
-- 第二次购买
--=========
function SpringFestival_Fashion_SecondBuy()

    Clear_XSCRIPT()
    	Set_XSCRIPT_Function_Name("OnFashionSecondBuy")
    	Set_XSCRIPT_ScriptID(893324)
    	Set_XSCRIPT_Parameter(0,1);
    	Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()		
	
end

function SpringFestival_Fashion_Help( nIdx )

    Clear_XSCRIPT()
    	Set_XSCRIPT_Function_Name("OnShowFashionHelp")
    	Set_XSCRIPT_ScriptID(893324)
    	Set_XSCRIPT_Parameter(0, nIdx);
    	Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()		
	
end

