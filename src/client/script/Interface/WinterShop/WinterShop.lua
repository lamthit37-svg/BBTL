--WinterShop
local g_WinterShop_UnifiedPosition;

local WinterShop_Page= {}
local WinterShop_Button= {}
local WinterShop_ButtonTips = {}
local WinterShop_Text= {}
local WinterShop_Item_BK = {}
local WinterShop_Item_Btn = {}
local WinterShop_Item_Limit = {}
local WinterShop_Item_Eyesign = {}
local WinterShop_Item_Mask = {}
local WinterShop_Item_Name = {}
local WinterShop_Item_Icon = {}
local WinterShop_Item_Prize = {}
local WinterShop_Item_LimitImage = {}

local g_curpage = 0
local g_weekPoint = 0
local g_curhighstage = 0
local g_HardMode = 0
local g_daibi = 0
local g_weekdaibi = 0
local g_getrewardflag = {0,0,0}

local g_Max_Weekpoint = 2000

local g_wulin_stage = {
	[1] = {needstage = 30},
	[2] = {needstage = 50},
	[3] = {needstage = 70},
}

local g_Max_PageItem = 12
local g_ItemLimitCount = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}

function WinterShop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

end

function WinterShop_OnLoad()

	WinterShop_Page[1] = WinterShop_Page1
	WinterShop_Page[2] = WinterShop_Page2
	
	WinterShop_Button[1] = WinterShop_Client1_Reward1_Btn
	WinterShop_Button[2] = WinterShop_Client1_Reward2_Btn
	WinterShop_Button[3] = WinterShop_Client1_Reward3_Btn
		
	WinterShop_ButtonTips[1] = WinterShop_Client1_Reward1_Btn_Tips
	WinterShop_ButtonTips[2] = WinterShop_Client1_Reward2_Btn_Tips
	WinterShop_ButtonTips[3] = WinterShop_Client1_Reward3_Btn_Tips
	
	for i = 1, 12 do
		WinterShop_Item_BK[i] = _G["WinterShop_Client2_Item"..i.."BK"]
		WinterShop_Item_Btn[i] = _G["WinterShop_Client2_Item"..i]
		WinterShop_Item_Limit[i] = _G["WinterShop_Client2_Item"..i.."_BuyLimitNum"]
		WinterShop_Item_Eyesign[i] = _G["WinterShop_Client2_Item"..i.."_EyeSign"]
		WinterShop_Item_Mask[i] = _G["WinterShop_Client2_Item"..i.."_Mask"]
		WinterShop_Item_Name[i] = _G["WinterShop_Client2_ItemInfo"..i.."_Text"]
		WinterShop_Item_Prize[i] = _G["WinterShop_Client2_ItemInfo"..i.."_GB"]
		WinterShop_Item_LimitImage[i] = _G["WinterShop_Client2_ItemInfo"..i.."_Limit"]
		WinterShop_Item_Eyesign[i]:SetEvent("Clicked", "WinterShop_OpenDressPreview("..i..")")
		WinterShop_Item_Btn[i]:SetEvent("Clicked", "WinterShop_ItemClicked("..i..")")
	end
	
	g_WinterShop_UnifiedPosition = WinterShop_Frame:GetProperty("UnifiedPosition")
	
end

function WinterShop_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 99896801 ) then
		WinterShop_Reset()
		local operator = Get_XParam_INT(0)

		g_weekPoint = Get_XParam_INT(1)
		g_curhighstage = Get_XParam_INT(2)
		g_HardMode = Get_XParam_INT(3)
		g_daibi = Get_XParam_INT(4)
		g_weekdaibi = Get_XParam_INT(5)
		for i = 1, 3 do
			g_getrewardflag[i] = Get_XParam_INT(5+i)
		end
		if operator == 1 then
			g_curpage = 1
			WinterShop_Update()
		elseif operator == 2 and this:IsVisible() and g_curpage == 1 then
			WinterShop_Update()		
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99896805 ) then
	
		WinterShop_Reset()
		local operator = Get_XParam_INT(0)
		g_daibi = Get_XParam_INT(1)
		local count = Get_XParam_INT(2)
		for i = 1, count do
			g_ItemLimitCount[i] = Get_XParam_INT(2+i)
		end
		
		if operator == 1 then
			g_curpage = 2
			WinterShop_Update()
		elseif operator == 2 and this:IsVisible() and g_curpage == 2 then
			WinterShop_Update()		
		end		
	elseif (event == "ADJEST_UI_POS" ) then
		WinterShop_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WinterShop_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end
--=========================================================
--reset
--=========================================================
function WinterShop_Reset()
	g_weekPoint = 0
	g_curhighstage = 0
	g_HardMode = 0
	g_daibi = 0
	g_weekdaibi = 0
	for i = 1 , 3 do
		g_getrewardflag[i] = 0
	end
end
--=========================================================
--选中页签
--=========================================================
function WinterShop_ButtonPage(index)
	for i = 1, 2 do
		if index == i then
			WinterShop_Page[i]:SetProperty("Selected", "True")
		else
			WinterShop_Page[i]:SetProperty("Selected", "False")
		end
	end
end

--=========================================================
--更新界面
--=========================================================
function WinterShop_Update()
	--WinterShop_Page1_Tips:Hide()
	WinterShop_Page2_Tips:Hide()
	
	if g_curpage == 1 then
		WinterShop_ButtonPage(1)
		WinterShop_Client1:Show()
		WinterShop_Client2:Hide()
		WinterShop_Update_Client1()
	else
		WinterShop_ButtonPage(2)
		WinterShop_Client1:Hide()
		WinterShop_Client2:Show()	
		WinterShop_Update_Client2()
	end
	
	this:Show()
end
--========================================================
--更新子页签
--=========================================================
function WinterShop_Update_Client1()
	local rewardflag = {1,1,1}
	--任务1
	if g_getrewardflag[1] == 1 then --已领取 置灰
		WinterShop_Client1_Reward1Text1BK:Show()
		WinterShop_Client1_Reward1Text2BK:Hide()
		WinterShop_Client1_Reward1Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_184}", g_weekPoint))
	else
		if g_weekPoint < g_Max_Weekpoint then
			WinterShop_Client1_Reward1Text1BK:Show()
			WinterShop_Client1_Reward1Text2BK:Hide()
			WinterShop_Client1_Reward1Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_186}", g_weekPoint))
			rewardflag[1] = 0
		else
			WinterShop_Client1_Reward1Text1BK:Hide()
			WinterShop_Client1_Reward1Text2BK:Show()
			WinterShop_Client1_Reward1Text2:SetText(ScriptGlobal_Format("#{DJWH_231201_185}", g_weekPoint))
		end		
	end
	--任务2
	if g_getrewardflag[2] == 1 then --已领取 置灰
		WinterShop_Client1_Reward2Text1BK:Show()
		WinterShop_Client1_Reward2Text2BK:Hide()
		WinterShop_Client1_Reward2Text3BK:Show()
		WinterShop_Client1_Reward2Text4BK:Hide()
		WinterShop_Client1_Reward2Text5BK:Show()
		WinterShop_Client1_Reward2Text6BK:Hide()
		WinterShop_Client1_Reward2Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_187}", g_curhighstage))
		WinterShop_Client1_Reward2Text3:SetText(ScriptGlobal_Format("#{DJWH_231201_190}", g_curhighstage))
		WinterShop_Client1_Reward2Text5:SetText(ScriptGlobal_Format("#{DJWH_231201_193}", g_curhighstage))		
	else
		if g_curhighstage < g_wulin_stage[1].needstage then
			WinterShop_Client1_Reward2Text1BK:Show()
			WinterShop_Client1_Reward2Text2BK:Hide()
			WinterShop_Client1_Reward2Text3BK:Show()
			WinterShop_Client1_Reward2Text4BK:Hide()
			WinterShop_Client1_Reward2Text5BK:Show()
			WinterShop_Client1_Reward2Text6BK:Hide()
			WinterShop_Client1_Reward2Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_189}", g_curhighstage))
			WinterShop_Client1_Reward2Text3:SetText(ScriptGlobal_Format("#{DJWH_231201_192}", g_curhighstage))
			WinterShop_Client1_Reward2Text5:SetText(ScriptGlobal_Format("#{DJWH_231201_195}", g_curhighstage))
			rewardflag[2] = 0
		elseif g_curhighstage < g_wulin_stage[2].needstage then
			WinterShop_Client1_Reward2Text1BK:Hide()
			WinterShop_Client1_Reward2Text2BK:Show()
			WinterShop_Client1_Reward2Text3BK:Show()
			WinterShop_Client1_Reward2Text4BK:Hide()
			WinterShop_Client1_Reward2Text5BK:Show()
			WinterShop_Client1_Reward2Text6BK:Hide()
			WinterShop_Client1_Reward2Text2:SetText(ScriptGlobal_Format("#{DJWH_231201_188}", g_curhighstage))
			WinterShop_Client1_Reward2Text3:SetText(ScriptGlobal_Format("#{DJWH_231201_192}", g_curhighstage))
			WinterShop_Client1_Reward2Text5:SetText(ScriptGlobal_Format("#{DJWH_231201_195}", g_curhighstage))	
		elseif g_curhighstage < g_wulin_stage[3].needstage then
			WinterShop_Client1_Reward2Text1BK:Show()
			WinterShop_Client1_Reward2Text2BK:Hide()
			WinterShop_Client1_Reward2Text3BK:Hide()
			WinterShop_Client1_Reward2Text4BK:Show()
			WinterShop_Client1_Reward2Text5BK:Show()
			WinterShop_Client1_Reward2Text6BK:Hide()
			WinterShop_Client1_Reward2Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_187}", g_curhighstage))
			WinterShop_Client1_Reward2Text4:SetText(ScriptGlobal_Format("#{DJWH_231201_191}", g_curhighstage))
			WinterShop_Client1_Reward2Text5:SetText(ScriptGlobal_Format("#{DJWH_231201_195}", g_curhighstage))
		else
			WinterShop_Client1_Reward2Text1BK:Show()
			WinterShop_Client1_Reward2Text2BK:Hide()
			WinterShop_Client1_Reward2Text3BK:Show()
			WinterShop_Client1_Reward2Text4BK:Hide()
			WinterShop_Client1_Reward2Text5BK:Hide()
			WinterShop_Client1_Reward2Text6BK:Show()
			WinterShop_Client1_Reward2Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_187}", g_curhighstage))
			WinterShop_Client1_Reward2Text3:SetText(ScriptGlobal_Format("#{DJWH_231201_190}", g_curhighstage))
			WinterShop_Client1_Reward2Text6:SetText(ScriptGlobal_Format("#{DJWH_231201_194}", g_curhighstage))		
		end
	end
	
	--任务3
	if g_getrewardflag[3] == 1 then --已领取 置灰
		WinterShop_Client1_Reward3Text1BK:Show()
		WinterShop_Client1_Reward3Text2BK:Hide()
		WinterShop_Client1_Reward3Text3BK:Show()
		WinterShop_Client1_Reward3Text4BK:Hide()
		if g_HardMode == 1 then
			WinterShop_Client1_Reward3Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_196}", 1))
			WinterShop_Client1_Reward3Text3:SetText(ScriptGlobal_Format("#{DJWH_231201_199}", 0))
		elseif g_HardMode == 2 then
			WinterShop_Client1_Reward3Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_196}", 1))
			WinterShop_Client1_Reward3Text3:SetText(ScriptGlobal_Format("#{DJWH_231201_199}", 1))
		end
	else
		if g_HardMode == 1 then
			WinterShop_Client1_Reward3Text1BK:Hide()
			WinterShop_Client1_Reward3Text2BK:Show()
			WinterShop_Client1_Reward3Text3BK:Show()
			WinterShop_Client1_Reward3Text4BK:Hide()
			WinterShop_Client1_Reward3Text2:SetText(ScriptGlobal_Format("#{DJWH_231201_197}", 1))
			WinterShop_Client1_Reward3Text3:SetText(ScriptGlobal_Format("#{DJWH_231201_201}", 0))
		elseif g_HardMode == 2 then
			WinterShop_Client1_Reward3Text1BK:Show()
			WinterShop_Client1_Reward3Text2BK:Hide()
			WinterShop_Client1_Reward3Text3BK:Hide()
			WinterShop_Client1_Reward3Text4BK:Show()
			WinterShop_Client1_Reward3Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_196}", 1))
			WinterShop_Reward3Text4:SetText(ScriptGlobal_Format("#{DJWH_231201_200}", 1))
		else 
			WinterShop_Client1_Reward3Text1BK:Show()
			WinterShop_Client1_Reward3Text2BK:Hide()
			WinterShop_Client1_Reward3Text3BK:Show()
			WinterShop_Client1_Reward3Text4BK:Hide()
			WinterShop_Client1_Reward3Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_198}", 0))
			WinterShop_Client1_Reward3Text3:SetText(ScriptGlobal_Format("#{DJWH_231201_201}", 0))
			rewardflag[3] = 0
		end
	end
	
	local isShowPageTips = 0
	for i = 1, 3 do
		if g_getrewardflag[i] == 1 then
			WinterShop_Button[i]:Disable()
			--WinterShop_Button[i]:SetText("已领取")
			WinterShop_ButtonTips[i]:Hide()
		else
			WinterShop_Button[i]:Enable()
			--WinterShop_Button[i]:SetText("领取奖励")
			if rewardflag[i] == 1 then --红点
				WinterShop_ButtonTips[i]:Show()
				isShowPageTips = 1
			else
				WinterShop_ButtonTips[i]:Hide()
			end
		end
	end
	if isShowPageTips == 1 then
		WinterShop_Page1_Tips:Show()
	else
		WinterShop_Page1_Tips:Hide()
	end
	
	WinterShop_Client1_CoinText:SetText(ScriptGlobal_Format("#{DJWH_231201_39}", g_daibi))
	
	WinterShop_Client1_Coin2Text:SetText(ScriptGlobal_Format("#{DJWH_231201_41}", g_weekdaibi))
end
--========================================================
--更新子页签
--=========================================================
function WinterShop_Update_Client2()
	local curDay = tonumber(DataPool:GetServerDayTime());
	if(curDay > 20240324 and curDay < 20240327) then
		WinterShop_Page1_Tips:Hide()
	end
	
	local nCount = DataPool:LuaFnGetWinterShopInfoCount()
	if nCount > g_Max_PageItem then
		nCount = g_Max_PageItem
	end
	
	for i = 1, g_Max_PageItem do
		if i <= nCount then
			WinterShop_Item_BK[i]:Show()
			local nNeedDaibi, nItemID, nNum, nLimit, nLimitType = DataPool:LuaFnGetWinterShopInfo(i)
			if nNeedDaibi ~= nil and nNeedDaibi > 0 then
				local theAction = DataPool:CreateBindActionItemForShow( nItemID, nNum )
				WinterShop_Item_Btn[i]:SetActionItem(theAction:GetID())
				WinterShop_Item_Btn[i]:Enable()
			
				WinterShop_Item_Name[i]:SetText("#L"..theAction:GetName())
				WinterShop_Item_Limit[i]:Hide()
				WinterShop_Item_LimitImage[i]:Hide()
				WinterShop_Item_Mask[i]:Hide()
				
				if nLimit> 0 and nLimitType > 0 then
					local curLimit = g_ItemLimitCount[i]
					if curLimit >= 0 then
						local restlimit = nLimit-curLimit
						if restlimit == 0 then --售罄
							WinterShop_Item_Mask[i]:Show()
						end
						WinterShop_Item_Limit[i]:Show()
						WinterShop_Item_Limit[i]:SetText(restlimit)
					end
					WinterShop_Item_LimitImage[i]:Show()
				end
			
				WinterShop_Item_Prize[i]:SetText(ScriptGlobal_Format("#{DJWH_231201_62}",nNeedDaibi))
				WinterShop_Item_Eyesign[i]:Hide()
			end
		else
			WinterShop_Item_BK[i]:Hide()
		end
	end
	
	WinterShop_Client2_Text1:SetText(ScriptGlobal_Format("#{DJWH_231201_39}",g_daibi))
end

--========================================================
--关闭
--=========================================================
function WinterShop_Close()
	if ( IsWindowShow( "WinterShop_BatchBuy" ) ) then
		CloseWindow( "WinterShop_BatchBuy", true );
	end 
	if ( IsWindowShow( "WinterShopCoin_BatchBuy" ) ) then
		CloseWindow( "WinterShopCoin_BatchBuy", true );
	end 
	WinterShop_Reset()
	this:Hide()
end

function WinterShop_OnHidden()
	WinterShop_Close()
end
--=========================================================
--刷新位置
--=========================================================
function WinterShop_On_ResetPos()
	WinterShop_Frame:SetProperty("UnifiedPosition", g_WinterShop_UnifiedPosition);
end


function WinterShop_Help()
	PushEvent("CCSHOP_HELP", 205)
end

function WinterShop_Duihuan()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenYBDuihuanUI" )
		Set_XSCRIPT_ScriptID( 998968 )
		Set_XSCRIPT_Parameter(0,g_curpage)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()		
end

function WinterShop_GetReward(nIndex)
	if nIndex < 1 or nIndex > 3 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetHuoyueDaibi" )
		Set_XSCRIPT_ScriptID( 998968 )
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_Parameter(1,1)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()		
end

function WinterShop_PageClick(nIndex)
	if nIndex < 1 or nIndex > 2 then
		return
	end
	
	if nIndex == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenHuoyueUI" )
			Set_XSCRIPT_ScriptID( 998968 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif nIndex == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenDuiHuanItem" )
			Set_XSCRIPT_ScriptID( 998968 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()			
	end
end

function WinterShop_ItemClicked(nIndex)

	if nIndex < 1 or nIndex > g_Max_PageItem then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "DoExchange" )
		Set_XSCRIPT_ScriptID( 998968 )
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_Parameter(1,0)		
		Set_XSCRIPT_Parameter(2,1)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end