
local g_InfantCardGift_Frame_UnifiedPosition;

local g_CurSelInfantIndex= 0
	
local g_nMaxButtonCount = 6;
local g_ctrlItemAction = {};
local g_ctrlButtonTips = {};
local g_ctrlBuyButton = {};
local g_ctrltimesText = {};
local g_BindItemId = 38000807

local g_LimitCount = 5

local g_GetDianJiCount = {
		[1] = 5,
		[2] = 15,
		[3] = 35,
		[4] = 60,
		[5] = 90,
		[6] = 2,
}

local g_valBuyFlag = {};

function InfantCardGift_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function InfantCardGift_OnLoad()
	g_InfantCardGift_Frame_UnifiedPosition=InfantCardGift_Frame:GetProperty("UnifiedPosition");
		
	g_ctrlItemAction[1] = InfantCardGift_Special_Icon1;
	g_ctrlItemAction[2] = InfantCardGift_Special_Icon2;
	g_ctrlItemAction[3] = InfantCardGift_Special_Icon3;
	g_ctrlItemAction[4] = InfantCardGift_Special_Icon4;
	g_ctrlItemAction[5] = InfantCardGift_Special_Icon5;
	g_ctrlItemAction[6] = InfantCardGift_Normal_Icon;
	
	g_ctrlButtonTips[1] = InfantCardGift_Special_Button1_tips;
	g_ctrlButtonTips[2] = InfantCardGift_Special_Button2_tips;
	g_ctrlButtonTips[3] = InfantCardGift_Special_Button3_tips;
	g_ctrlButtonTips[4] = InfantCardGift_Special_Button4_tips;
	g_ctrlButtonTips[5] = InfantCardGift_Special_Button5_tips;
	g_ctrlButtonTips[6] = InfantCardGift_Normal_Button_tips;
	
	g_ctrlBuyButton[1] = InfantCardGift_Special_Button1;
	g_ctrlBuyButton[2] = InfantCardGift_Special_Button2;
	g_ctrlBuyButton[3] = InfantCardGift_Special_Button3;
	g_ctrlBuyButton[4] = InfantCardGift_Special_Button4;
	g_ctrlBuyButton[5] = InfantCardGift_Special_Button5;
	g_ctrlBuyButton[6] = InfantCardGift_Normal_Button;
	
	g_ctrltimesText[1] = InfantCardGift_Special_times1;
	g_ctrltimesText[2] = InfantCardGift_Special_times2;
	g_ctrltimesText[3] = InfantCardGift_Special_times3;
	g_ctrltimesText[4] = InfantCardGift_Special_times4;
	g_ctrltimesText[5] = InfantCardGift_Special_times5;
	g_ctrltimesText[6] = InfantCardGift_Normal_times;
		
end

-- OnEvent
function InfantCardGift_OnEvent(event)

	if (event == "UI_COMMAND") and (tonumber(arg0) == 201512032) then
	
		for i = 1, g_nMaxButtonCount do
			g_valBuyFlag[i] = Get_XParam_INT(i-1)
		end 
				
		InfantCardGift_AllNumber:SetText( ScriptGlobal_Format("#{ZNHK_151201_17}", Get_XParam_INT(6)))
		--InfantCardGift_LuckyNumber:SetText( ScriptGlobal_Format("#{ZNHK_151201_18}", Get_XParam_INT(6)))
		
		DataPool:Lua_ClearInfantCardGiftActionItem();
		for i=0, g_nMaxButtonCount-1 do		
			DataPool:Lua_SetInfantCardGiftActionItem( i, g_BindItemId, g_GetDianJiCount[i+1] );
		end
		DataPool:Lua_UpdateInfantCardGiftActionItem();
				
		for i=0, g_nMaxButtonCount-1 do
			local theAction = EnumAction( i, "InfantCardGift_Item");
			if theAction:GetID() ~= 0 then
				g_ctrlItemAction[i+1]:SetActionItem( theAction:GetID() );
			else
				g_ctrlItemAction[i+1]:SetActionItem( -1 );
			end
		end
		
		InfantCardGift_UpdateUI();	
		this:Show();
		
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	elseif (event == "ADJEST_UI_POS" ) then
		InfantCardGift_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		InfantCardGift_Frame_On_ResetPos()
		
	end

end

--显示界面内容
function InfantCardGift_UpdateUI()	
		
	for i=1, g_nMaxButtonCount-1 do		
		g_ctrltimesText[i]:SetText( ScriptGlobal_Format("#{ZNHK_151201_31}", g_valBuyFlag[i]))
		--显示按钮
		if g_valBuyFlag[i] == 0 then
			g_ctrlBuyButton[i]:Enable()
			g_ctrlButtonTips[i]:Hide()
		else
			g_ctrlBuyButton[i]:Disable()
			g_ctrlButtonTips[i]:Show()
		end
	end
		
	g_ctrltimesText[g_nMaxButtonCount]:SetText( ScriptGlobal_Format("#{ZNHK_151201_30}", g_valBuyFlag[g_nMaxButtonCount]))
	
	if g_valBuyFlag[g_nMaxButtonCount] < g_LimitCount then
			g_ctrlBuyButton[g_nMaxButtonCount]:Enable()
			g_ctrlButtonTips[g_nMaxButtonCount]:Hide()
	else
			g_ctrlBuyButton[g_nMaxButtonCount]:Disable()
			g_ctrlButtonTips[g_nMaxButtonCount]:Show()
	end

end

--N个购买
function InfantCardGift_OKClick( btnId )

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnExChangeDianJi" )
			Set_XSCRIPT_ScriptID( 891726 )
			Set_XSCRIPT_Parameter(0,btnId)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	
end

function InfantCardGift_Frame_On_ResetPos()
  InfantCardGift_Frame:SetProperty("UnifiedPosition", g_InfantCardGift_Frame_UnifiedPosition);
end	

function InfantCardGift_CloseClicked()
	this:Hide();
end