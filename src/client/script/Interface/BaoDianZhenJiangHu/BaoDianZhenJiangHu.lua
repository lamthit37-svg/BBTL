
local g_BaoDianZhenJiangHu_Frame_UnifiedPosition;

local g_CurSelInfantIndex= 0
local g_bConfirm = 0				--二次确认框
	
local g_nMaxButtonCount = 7;
local g_ctrlItemAction = {};
local g_ctrlButtonTips = {};
local g_ctrlBuyButton = {};

local g_valBuyFlag = {};


local g_Infant_HeroCardInfo =
{
	[0] = {Tips="#{KPGM_150529_73}", CardId={60000014,60004014,60007014,60008014,60006014,60005014} },--默认
	[1] = {Tips="#{KPGM_150529_69}", CardId={60000014,60004014,60007014,60008014,60006014,60005014} },--乔峰
	[2] = {Tips="#{KPGM_150529_71}", CardId={60101014,60104014,60107014,60108014,60106014,60105014} },--段誉
	[3] = {Tips="#{KPGM_150529_70}", CardId={60202014,60204014,60207014,60208014,60206014,60205014} },--虚竹
	[4] = {Tips="#{KPGM_150529_72}", CardId={60303014,60304014,60307014,60308014,60306014,60305014} },--王语嫣
}

function BaoDianZhenJiangHu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BaoDianZhenJiangHu_OnLoad()
	g_BaoDianZhenJiangHu_Frame_UnifiedPosition=BaoDianZhenJiangHu_Frame:GetProperty("UnifiedPosition");
		
	g_ctrlItemAction[1] = BaoDianZhenJiangHu_DianjiBK_Tu1;
	g_ctrlItemAction[2] = BaoDianZhenJiangHu_DianjiBK_Tu2;
	g_ctrlItemAction[3] = BaoDianZhenJiangHu_DianjiBK_Tu3;
	g_ctrlItemAction[4] = BaoDianZhenJiangHu_DianjiBK_Tu4;
	g_ctrlItemAction[5] = BaoDianZhenJiangHu_DianjiBK_Tu5;
	g_ctrlItemAction[6] = BaoDianZhenJiangHu_DianjiBK_Tu6;
	
	g_ctrlButtonTips[1] = BaoDianZhenJiangHu_Frame1_Button1_tips;
	g_ctrlButtonTips[2] = BaoDianZhenJiangHu_Frame1_Button2_tips;
	g_ctrlButtonTips[3] = BaoDianZhenJiangHu_Frame1_Button3_tips;
	g_ctrlButtonTips[4] = BaoDianZhenJiangHu_Frame1_Button4_tips;
	g_ctrlButtonTips[5] = BaoDianZhenJiangHu_Frame1_Button5_tips;
	g_ctrlButtonTips[6] = BaoDianZhenJiangHu_Frame1_Button6_tips;
	g_ctrlButtonTips[7] = BaoDianZhenJiangHu_Frame1_Button7_tips;
	
	g_ctrlBuyButton[1] = BaoDianZhenJiangHu_Frame1_Button1;
	g_ctrlBuyButton[2] = BaoDianZhenJiangHu_Frame1_Button2;
	g_ctrlBuyButton[3] = BaoDianZhenJiangHu_Frame1_Button3;
	g_ctrlBuyButton[4] = BaoDianZhenJiangHu_Frame1_Button4;
	g_ctrlBuyButton[5] = BaoDianZhenJiangHu_Frame1_Button5;
	g_ctrlBuyButton[6] = BaoDianZhenJiangHu_Frame1_Button6;
	g_ctrlBuyButton[7] = BaoDianZhenJiangHu_Frame1_Button7;
end

-- OnEvent
function BaoDianZhenJiangHu_OnEvent(event)

	if (event == "UI_COMMAND") and (tonumber(arg0) == 2015053002) then
	
		for i = 1, g_nMaxButtonCount do
			g_valBuyFlag[i] = Get_XParam_INT(i-1)
		end 

		--根据玩家情况显示卡牌		
		if not this:IsVisible() then
			local InfantCount = Infant:GetInfantCount();
			local InfantType = 0;		--默认乔峰
			if InfantCount > 0 then
				InfantType = Infant:GetHeroType(0)
			end
				
			if g_Infant_HeroCardInfo[InfantType] ~= nil then
			
				BaoDianZhenJiangHu_Shuoming2_text2:SetText( g_Infant_HeroCardInfo[InfantType].Tips );
				
				DataPool:Lua_ClearBaoDian2ActionItem();
				for i=0, 5 do
						DataPool:Lua_SetBaoDian2ActionItem( i, g_Infant_HeroCardInfo[InfantType].CardId[i+1] );
				end
				DataPool:Lua_UpdateBaoDian2ActionItem();
				
				for i=0, 5 do
					local theAction = EnumAction( i, "baodian2_item");
					if theAction:GetID() ~= 0 then
						g_ctrlItemAction[i+1]:SetActionItem( theAction:GetID() );
					else
						g_ctrlItemAction[i+1]:SetActionItem( -1 );
					end
				end
			end
		end
		
		BaoDianZhenJiangHu_UpdateUI();	
		this:Show();
		
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	elseif (event == "ADJEST_UI_POS" ) then
		BaoDianZhenJiangHu_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BaoDianZhenJiangHu_Frame_On_ResetPos()
		
	end

end

--显示界面内容
function BaoDianZhenJiangHu_UpdateUI()	
		
	for i=1, g_nMaxButtonCount do		
		--显示按钮
		if g_valBuyFlag[i] == 0 then
			g_ctrlBuyButton[i]:Enable()
		else
			g_ctrlBuyButton[i]:Disable()
		end
	end

end

--N个购买
function BaoDianZhenJiangHu_OKClick( btnId )

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnBuybowenji" )
			Set_XSCRIPT_ScriptID( 891151 )
			Set_XSCRIPT_Parameter(0,btnId)
			Set_XSCRIPT_Parameter(1,0)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	
end

--打开子女卡牌超值回馈界面
function BaoDianZhenJiangHu_InfantCardRewardClick( )

		-- Clear_XSCRIPT()
			-- Set_XSCRIPT_Function_Name( "ClientAskOpen" )
			-- Set_XSCRIPT_ScriptID( 891429 )
			-- Set_XSCRIPT_ParamCount(0)
		-- Send_XSCRIPT()
		
		--this:Hide()
	
end

--打开子女技能
function BaoDianZhenJiangHu_InfantSkillClick( )

	if Player:GetLevel() < 50 then
		PushDebugMessage("#{KPGM_150529_64}");
		return 
	end
	
	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 then
		PushDebugMessage("#{KPGM_150529_65}");
		return 
	end
	
	local level = Infant:GetInfantLevel(0)
	if level < 91 then
		PushDebugMessage("#{KPGM_150529_66}")
		return
	end
	
	local heroType = Infant:GetHeroType(0)
	if heroType <= 0 then
		PushDebugMessage("#{KPGM_150529_67}")
		PushDebugMessage("#{KPGM_150529_75}")
		return
	end	
	
	PushEvent("SHOW_INFANTSKILL_INFO")
	--this:Hide()
	
end

function BaoDianZhenJiangHu_Frame_On_ResetPos()
  BaoDianZhenJiangHu_Frame:SetProperty("UnifiedPosition", g_BaoDianZhenJiangHu_Frame_UnifiedPosition);
end	

function BaoDianZhenJiangHu_Close()
	DataPool:Lua_ClearBaoDian2ActionItem();
	this:Hide();
end