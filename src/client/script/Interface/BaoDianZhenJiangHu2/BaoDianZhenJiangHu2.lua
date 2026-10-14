--BaoDianZhenJiangHu2.lua
local g_BaoDianZhenJiangHu2_Frame_UnifiedPosition;
	
local g_nMaxButtonCount = 6;
local g_ctrlItemAction = {};
local g_ctrlItemText = {};
local g_ctrlGetButton = {};

local g_nMeiLiValue = 0;
local g_valGetPrizeFlag = {};
local g_ActionButton={};
	
local g_params = {
	[1] = {MeiLiValue=4000,  AwardItemCount = 25,  ItemValue = 1000},
	[2] = {MeiLiValue=12000, AwardItemCount = 55,  ItemValue = 2200},
	[3] = {MeiLiValue=20000, AwardItemCount = 65,  ItemValue = 2600},
	[4] = {MeiLiValue=30000, AwardItemCount = 85,  ItemValue = 3400},
	[5] = {MeiLiValue=45000, AwardItemCount = 143, ItemValue = 5720},
	[6] = {MeiLiValue=95000, AwardItemCount = 600, ItemValue = 24000},
	}
	
local g_Infant_HeroCardInfo =
{
	[0] = {Tips="#{KPLS_150527_30}", CardId={60000014,60004014,60007014,60008014,60006014,60005014} },--默认
	[1] = {Tips="#{KPLS_150527_26}", CardId={60000014,60004014,60007014,60008014,60006014,60005014} },--乔峰
	[2] = {Tips="#{KPLS_150527_28}", CardId={60101014,60104014,60107014,60108014,60106014,60105014} },--段誉
	[3] = {Tips="#{KPLS_150527_27}", CardId={60202014,60204014,60207014,60208014,60206014,60205014} },--虚竹
	[4] = {Tips="#{KPLS_150527_29}", CardId={60303014,60304014,60307014,60308014,60306014,60305014} },--王语嫣
}

function BaoDianZhenJiangHu2_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function BaoDianZhenJiangHu2_OnLoad()
	g_BaoDianZhenJiangHu2_Frame_UnifiedPosition=BaoDianZhenJiangHu2_Frame:GetProperty("UnifiedPosition");
		
	g_ctrlItemAction[1] = BaoDianZhenJiangHu2_BK1_Kapai01_Tu1;
	g_ctrlItemAction[2] = BaoDianZhenJiangHu2_BK1_Kapai02_Tu1;
	g_ctrlItemAction[3] = BaoDianZhenJiangHu2_BK1_Kapai03_Tu1;
	g_ctrlItemAction[4] = BaoDianZhenJiangHu2_BK1_Kapai04_Tu1;
	g_ctrlItemAction[5] = BaoDianZhenJiangHu2_BK1_Kapai05_Tu1;
	g_ctrlItemAction[6] = BaoDianZhenJiangHu2_BK1_Kapai06_Tu1;
	
	g_ctrlItemText[1] = BaoDianZhenJiangHu2_BK1_Kapai01_Text;
	g_ctrlItemText[2] = BaoDianZhenJiangHu2_BK1_Kapai02_Text;
	g_ctrlItemText[3] = BaoDianZhenJiangHu2_BK1_Kapai03_Text;
	g_ctrlItemText[4] = BaoDianZhenJiangHu2_BK1_Kapai04_Text;
	g_ctrlItemText[5] = BaoDianZhenJiangHu2_BK1_Kapai05_Text;
	g_ctrlItemText[6] = BaoDianZhenJiangHu2_BK1_Kapai06_Text;
	
	g_ctrlGetButton[1] = BaoDianZhenJiangHu2_BK1_Kapai01_Button1;
	g_ctrlGetButton[2] = BaoDianZhenJiangHu2_BK1_Kapai02_Button1;
	g_ctrlGetButton[3] = BaoDianZhenJiangHu2_BK1_Kapai03_Button1;
	g_ctrlGetButton[4] = BaoDianZhenJiangHu2_BK1_Kapai04_Button1;
	g_ctrlGetButton[5] = BaoDianZhenJiangHu2_BK1_Kapai05_Button1;
	g_ctrlGetButton[6] = BaoDianZhenJiangHu2_BK1_Kapai06_Button1;
	
	g_ActionButton[0] = BaoDianZhenJiangHu2_DianjiBK_Tu1;
	g_ActionButton[1] = BaoDianZhenJiangHu2_DianjiBK_Tu2;
	g_ActionButton[2] = BaoDianZhenJiangHu2_DianjiBK_Tu3;
	g_ActionButton[3] = BaoDianZhenJiangHu2_DianjiBK_Tu4;
	g_ActionButton[4] = BaoDianZhenJiangHu2_DianjiBK_Tu5;
	g_ActionButton[5] = BaoDianZhenJiangHu2_DianjiBK_Tu6;
end

-- OnEvent
function BaoDianZhenJiangHu2_OnEvent(event)

	if (event == "UI_COMMAND") and (tonumber(arg0) == 2015052702) then
		g_nMeiLiValue = Get_XParam_INT(0)	--魅力值
		g_valGetPrizeFlag[1] = Get_XParam_INT(1)	--领取标记1
		g_valGetPrizeFlag[2] = Get_XParam_INT(2)	--领取标记2
		g_valGetPrizeFlag[3] = Get_XParam_INT(3)	--领取标记3
		g_valGetPrizeFlag[4] = Get_XParam_INT(4)	--领取标记4
		g_valGetPrizeFlag[5] = Get_XParam_INT(5)	--领取标记5
		g_valGetPrizeFlag[6] = Get_XParam_INT(6)	--领取标记6
		
		BaoDianZhenJiangHu2_UpdateUI();	
		
		if not this:IsVisible() then
			local InfantCount = Infant:GetInfantCount();
			local InfantType = 0;		--默认乔峰
			if InfantCount > 0 then
				InfantType = Infant:GetHeroType(0)
			end
			
			if g_Infant_HeroCardInfo[InfantType] ~= nil then
			
				BaoDianZhenJiangHu2_Frame_Info3_text2:SetText( g_Infant_HeroCardInfo[InfantType].Tips );
			
				DataPool:Lua_ClearBaoDian2ActionItem();
				for i=0, 5 do
					DataPool:Lua_SetBaoDian2ActionItem( i, g_Infant_HeroCardInfo[InfantType].CardId[i+1] );
				end
				DataPool:Lua_UpdateBaoDian2ActionItem();
			
				for i=0, 5 do
					local theAction = EnumAction( i, "baodian2_item");
					if theAction:GetID() ~= 0 then
						g_ActionButton[i]:SetActionItem( theAction:GetID() );
					else
						g_ActionButton[i]:SetActionItem( -1 );
					end
				end
			end
		end
		
		this:Show();
		
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		return;
	elseif (event == "ADJEST_UI_POS" ) then
		BaoDianZhenJiangHu2_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BaoDianZhenJiangHu2_Frame_On_ResetPos()
		
	end

end

--显示界面内容
function BaoDianZhenJiangHu2_UpdateUI()

	--魅力值
	BaoDianZhenJiangHu2_Frame_Info2:SetText( "#{KPLS_150527_13}"..tostring(g_nMeiLiValue) );
				
	for i=1, g_nMaxButtonCount do
		--显示文字
		if g_nMeiLiValue < g_params[i].MeiLiValue then
			g_ctrlItemText[i]:SetText( ScriptGlobal_Format("#{KPLS_150527_14}", g_params[i].MeiLiValue, g_params[i].AwardItemCount, g_params[i].ItemValue) );
		else
			g_ctrlItemText[i]:SetText( ScriptGlobal_Format("#{KPLS_150527_15}", g_params[i].MeiLiValue, g_params[i].AwardItemCount, g_params[i].ItemValue) );
		end
		
		--显示按钮
		if g_valGetPrizeFlag[i] == 1 then
			g_ctrlGetButton[i]:Disable()
		else
			g_ctrlGetButton[i]:Enable()
		end
	end

end

--三个领取按钮 btnId:1~3
function BaoDianZhenJiangHu2_OKClick( btnId )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetPrize" )
		Set_XSCRIPT_ScriptID( 891141 )
		Set_XSCRIPT_Parameter(0,btnId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

function BaoDianZhenJiangHu2_Close()
	DataPool:Lua_ClearBaoDian2ActionItem();
	this:Hide();
end

function BaoDianZhenJiangHu2_Frame_On_ResetPos()
  BaoDianZhenJiangHu2_Frame:SetProperty("UnifiedPosition", g_BaoDianZhenJiangHu2_Frame_UnifiedPosition);
end	