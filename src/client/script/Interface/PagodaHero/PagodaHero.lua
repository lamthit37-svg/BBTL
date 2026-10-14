local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_PagodaHero_IsHuiliu;
local g_PagodaHero_TongpanTimes;
local g_PagodaHero_YaoshiTimes;
local g_PagodaHero_BaoTa =38001285 ;
local g_PagodaHero_BaoXiang = 38001286;

local g_PagodaHero_PrizeItemList = {}

function PagodaHero_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	
end

function PagodaHero_OnEvent(event)
	if event == "UI_COMMAND" and tonumber( arg0 ) == 89131201 then
		if ( Get_XParam_INT_Count() < 3 ) then
			return
		end
		g_PagodaHero_IsHuiliu = tonumber(Get_XParam_INT(0))
		g_PagodaHero_TongpanTimes = tonumber(Get_XParam_INT(1))
		g_PagodaHero_YaoshiTimes = tonumber(Get_XParam_INT(2))
		PagodaHero_OnShown()
	elseif( event == "ADJEST_UI_POS" ) then
		PagodaHero_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		PagodaHero_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function PagodaHero_OnLoad()
		-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= PagodaHero_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= PagodaHero_Frame:GetProperty("UnifiedYPosition");
	g_PagodaHero_PrizeItemList[1] = PagodaHero_Bk_JL1_Icon;
	g_PagodaHero_PrizeItemList[2] = PagodaHero_Bk_JL2_Icon;

end

function PagodaHero_OnShown()
	local isHuiliu = g_PagodaHero_IsHuiliu;
	local oddtimesTP = 3-g_PagodaHero_TongpanTimes;
	local oddtimesYS = 3-g_PagodaHero_YaoshiTimes;
	local strTP = ScriptGlobal_Format("#{BTZYH_150629_41}", oddtimesTP)
	local strYS = ScriptGlobal_Format("#{BTZYH_150629_41}", oddtimesYS)
	
	PagodaHero_Bk_JL1_Text:SetText(strTP);
	PagodaHero_Bk_JL2_Text:SetText(strYS);
		
	PagodaHero_UpdateActionItem()	
	
	this:Show();
end
function PagodaHero_HuiLiuClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("HuiliuGetBaoTa")
		Set_XSCRIPT_ScriptID(891312)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()		
end

function PagodaHero_HuoYueClicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("HuoyueGetBaoXiang")
		Set_XSCRIPT_ScriptID(891312)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()		
end
function PagodaHero_UpdateActionItem()
	DataPool:ClearPagodaHeroItem();
	DataPool:CreatePagodaHeroItem(g_PagodaHero_BaoTa, 0, 1);
	DataPool:CreatePagodaHeroItem(g_PagodaHero_BaoXiang, 1, 1);

	for i = 1, 2 do
		local theAction = EnumAction(i-1, "pagodahero_item");
		local id = theAction:GetID()
		if theAction:GetID() ~= 0 then
			g_PagodaHero_PrizeItemList[i]:Enable();
			g_PagodaHero_PrizeItemList[i]:SetActionItem(theAction:GetID())
		end
	end
end
--================================================
-- 界面的默认相对位置
--================================================
function PagodaHero_ResetPos()
	PagodaHero_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	PagodaHero_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function PagodaHero_OnClosed()
	this:Hide();
end
