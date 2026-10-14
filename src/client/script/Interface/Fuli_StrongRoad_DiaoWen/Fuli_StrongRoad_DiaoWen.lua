--超值反馈 双属性雕纹 誉满乾坤

---雕纹用的全局变量 begin
local Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS = {};
local Fuli_StrongRoad_DiaoWen_GetGift_DESCS = {};
local Fuli_StrongRoad_DiaoWen_GetGift_DESCS_EX ={}
local Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS_TIPS = {};
local Fuli_StrongRoad_DiaoWen_GetGift_Action = {};
local Fuli_StrongRoad_DiaoWen_03YeQian_Button = {};
local g_Levelnum = 4
local g_EquipCount = 8
local g_RebackText =
{
	[1] = "一",
	[2] = "二",
	[3] = "三",
	[4] = "四",
}
---雕纹用的全局变量 end

--誉满乾坤用的全局变量 begin
local g_ChengDan={0,0,0,0,0,0}
local Fuli_StrongRoad_Rebate_GetGolden_BUTTONS = {};
local Fuli_StrongRoad_Rebate_GetGolden_DESCS = {};
local Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX = {};
local Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS = {};
local Fuli_StrongRoad_Rebate_GetGolden_Action = {};
local Fuli_StrongRoad_Rebate_02YeQian_Button = {};
local GetGolden_BUTTONS = {};
local GetGolden_DESCS = {};
local GetGolden_DESCS_EX = {};
local GetGolden_BUTTONS_TIPS = {};
local GetGolden_Action = {};
local g_Rebate_Levelnum = 6
--誉满乾坤用的全局变量 end

--用于记录打开哪个页签 1是双属性雕纹 2是誉满乾坤
local g_OpenIndex = 1
local g_Fuli_StrongRoad_DiaoWen_Frame_UnifiedPosition;

local g_ButtonPos = {
											[1] = {x =0, y = 0, tipx =0, tipy =0},
											[2] = {x =0, y = 0, tipx =0, tipy =0},
											[3] = {x =0, y = 0, tipx =0, tipy =0},
											[4] = {x =0, y = 0, tipx =0, tipy =0},
											[5] = {x =0, y = 0, tipx =0, tipy =0},
											[6] = {x =0, y = 0, tipx =0, tipy =0},
											[7] = {x =0, y = 0, tipx =0, tipy =0},
										}

local CreateDate = 904691712			-- 2013年08月22日08:00:00

local nCharCreateDate = -1;
local g_bIsNewServerGiftsForLevelUpValid = 0
local g_bIsNewServerGiftsForLevelUpValid_2023 = 0
--===============================================
-- PreLoad()
--===============================================
function Fuli_StrongRoad_DiaoWen_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_StrongRoad_DIAOWEN")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--离开场景
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
	this:RegisterEvent("OPEN_CHAOZHIFANKUI")
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")
end

--===============================================
-- OnEvent()
--===============================================
function Fuli_StrongRoad_DiaoWen_OnEvent(event)
	--Fuli_StrongRoad_DiaoWen_Button5tips : Hide()
	if (event == "UI_COMMAND") and (tonumber(arg0) == 8909291) then
	--PushDebugMessage("diaowen")
		g_OpenIndex = 1
		Fuli_StrongRoad_DiaoWen_Open(2, 1)
	elseif (event == "UI_COMMAND") and (tonumber(arg0) == 8908922) then
		g_OpenIndex = 2
		Fuli_StrongRoad_Rebate_Open(1, 2)
	elseif (event == "UI_COMMAND") and (tonumber(arg0) == 20151204) then
		g_OpenIndex = 2
		Fuli_StrongRoad_Rebate_Open(2, 2)
	elseif (event == "UPDATE_StrongRoad_DIAOWEN") then
		if not this:IsVisible() then
			return
		end
		if g_OpenIndex == 1 then
			Fuli_StrongRoad_DiaoWen_Button02_Clicked()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Fuli_StrongRoad_DiaoWen_Close()
	elseif (event == "ADJEST_UI_POS") then
		Fuli_StrongRoad_DiaoWen_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Fuli_StrongRoad_DiaoWen_On_ResetPos()
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		if this:IsVisible() then
			Fuli_StrongRoad_DiaoWen_UpdateRedPointInUI()
		end
	elseif event == "OPEN_CHAOZHIFANKUI" then
		if(tonumber(arg0) == 0) then
			Fuli_StrongRoad_DiaoWen_On_ResetPos()
		else
			Fuli_StrongRoad_DiaoWen_On_SetLastPos()
		end
	--	this:Show()
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenChaoZhiFanKui" )
		Set_XSCRIPT_ScriptID( 890928 )
		Set_XSCRIPT_Parameter(0,0);
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	--	Fuli_StrongRoad_DiaoWen_Open(2, 1)
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 8889072 ) then
		nCharCreateDate = Get_XParam_INT( 8 );
		g_bIsNewServerGiftsForLevelUpValid = Get_XParam_INT( 9 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = 0
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 99847904 ) then
		nCharCreateDate = Get_XParam_INT( 0 );
		g_bIsNewServerGiftsForLevelUpValid_2023 = Get_XParam_INT( 1 );
		g_bIsNewServerGiftsForLevelUpValid = 0
	elseif event == "UPDATE_REDPOINT_IN_UI" then
		Fuli_StrongRoad_DiaoWen_Refresh_ButtonTips()
		
	end
end

--===============================================
-- OnLoad()
--===============================================
function Fuli_StrongRoad_DiaoWen_OnLoad()
	--以下是双属性雕纹的
	Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS[1] = Fuli_StrongRoad_DiaoWen_Frame2_Button0
	Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS[2] = Fuli_StrongRoad_DiaoWen_Frame2_Button1
	Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS[3] = Fuli_StrongRoad_DiaoWen_Frame2_Button2
	Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS[4] = Fuli_StrongRoad_DiaoWen_Frame2_Button3

	Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS_TIPS[1] = Fuli_StrongRoad_DiaoWen_Frame2_Button0_tips
	Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS_TIPS[2] = Fuli_StrongRoad_DiaoWen_Frame2_Button1_tips
	Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS_TIPS[3] = Fuli_StrongRoad_DiaoWen_Frame2_Button2_tips
	Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS_TIPS[4] = Fuli_StrongRoad_DiaoWen_Frame2_Button3_tips

	Fuli_StrongRoad_DiaoWen_GetGift_DESCS[1] = Fuli_StrongRoad_DiaoWen_Frame2_Text0_1
	Fuli_StrongRoad_DiaoWen_GetGift_DESCS[2] = Fuli_StrongRoad_DiaoWen_Frame2_Text1_1
	Fuli_StrongRoad_DiaoWen_GetGift_DESCS[3] = Fuli_StrongRoad_DiaoWen_Frame2_Text2_1
	Fuli_StrongRoad_DiaoWen_GetGift_DESCS[4] = Fuli_StrongRoad_DiaoWen_Frame2_Text3_1

	Fuli_StrongRoad_DiaoWen_GetGift_DESCS_EX[1] = Fuli_StrongRoad_DiaoWen_Frame2_Text0_2
	Fuli_StrongRoad_DiaoWen_GetGift_DESCS_EX[2] = Fuli_StrongRoad_DiaoWen_Frame2_Text1_2
	Fuli_StrongRoad_DiaoWen_GetGift_DESCS_EX[3] = Fuli_StrongRoad_DiaoWen_Frame2_Text2_2
	Fuli_StrongRoad_DiaoWen_GetGift_DESCS_EX[4] = Fuli_StrongRoad_DiaoWen_Frame2_Text3_2

	Fuli_StrongRoad_DiaoWen_GetGift_Action[1] = Fuli_StrongRoad_DiaoWen_Frame2_Icon0
	Fuli_StrongRoad_DiaoWen_GetGift_Action[2] = Fuli_StrongRoad_DiaoWen_Frame2_Icon1
	Fuli_StrongRoad_DiaoWen_GetGift_Action[3] = Fuli_StrongRoad_DiaoWen_Frame2_Icon2
	Fuli_StrongRoad_DiaoWen_GetGift_Action[4] = Fuli_StrongRoad_DiaoWen_Frame2_Icon3

	Fuli_StrongRoad_DiaoWen_03YeQian_Button[1] = Fuli_StrongRoad_DiaoWen_Button01
	Fuli_StrongRoad_DiaoWen_03YeQian_Button[2] = Fuli_StrongRoad_DiaoWen_Button02

	--以下是誉满乾坤的
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[1] = Fuli_StrongRoad_Rebate_Frame2_Button1
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[2] = Fuli_StrongRoad_Rebate_Frame2_Button2
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[3] = Fuli_StrongRoad_Rebate_Frame2_Button3
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[4] = Fuli_StrongRoad_Rebate_Frame2_Button4
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[5] = Fuli_StrongRoad_Rebate_Frame2_Button5
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[6] = Fuli_StrongRoad_Rebate_Frame2_Button0

	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[1] = Fuli_StrongRoad_Rebate_Frame2_Button1_tips
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[2] = Fuli_StrongRoad_Rebate_Frame2_Button2_tips
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[3] = Fuli_StrongRoad_Rebate_Frame2_Button3_tips
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[4] = Fuli_StrongRoad_Rebate_Frame2_Button4_tips
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[5] = Fuli_StrongRoad_Rebate_Frame2_Button5_tips
	Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[6] = Fuli_StrongRoad_Rebate_Frame2_Button0_tips

	Fuli_StrongRoad_Rebate_GetGolden_DESCS[1] = Fuli_StrongRoad_Rebate_Frame2_Text1_1
	Fuli_StrongRoad_Rebate_GetGolden_DESCS[2] = Fuli_StrongRoad_Rebate_Frame2_Text2_1
	Fuli_StrongRoad_Rebate_GetGolden_DESCS[3] = Fuli_StrongRoad_Rebate_Frame2_Text3_1
	Fuli_StrongRoad_Rebate_GetGolden_DESCS[4] = Fuli_StrongRoad_Rebate_Frame2_Text4_1
	Fuli_StrongRoad_Rebate_GetGolden_DESCS[5] = Fuli_StrongRoad_Rebate_Frame2_Text5_1
	Fuli_StrongRoad_Rebate_GetGolden_DESCS[6] = Fuli_StrongRoad_Rebate_Frame2_Text0_1

	Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[1] = Fuli_StrongRoad_Rebate_Frame2_Text1_2
	Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[2] = Fuli_StrongRoad_Rebate_Frame2_Text2_2
	Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[3] = Fuli_StrongRoad_Rebate_Frame2_Text3_2
	Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[4] = Fuli_StrongRoad_Rebate_Frame2_Text4_2
	Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[5] = Fuli_StrongRoad_Rebate_Frame2_Text5_2
	Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[6] = Fuli_StrongRoad_Rebate_Frame2_Text0_2

	Fuli_StrongRoad_Rebate_GetGolden_Action[1] = Fuli_StrongRoad_Rebate_Frame2_Icon0
	Fuli_StrongRoad_Rebate_GetGolden_Action[2] = Fuli_StrongRoad_Rebate_Frame2_Icon1
	Fuli_StrongRoad_Rebate_GetGolden_Action[3] = Fuli_StrongRoad_Rebate_Frame2_Icon2
	Fuli_StrongRoad_Rebate_GetGolden_Action[4] = Fuli_StrongRoad_Rebate_Frame2_Icon3
	Fuli_StrongRoad_Rebate_GetGolden_Action[5] = Fuli_StrongRoad_Rebate_Frame2_Icon4
	Fuli_StrongRoad_Rebate_GetGolden_Action[6] = Fuli_StrongRoad_Rebate_Frame2_Icon5

	Fuli_StrongRoad_Rebate_02YeQian_Button[1] = Fuli_StrongRoad_Rebate_Button1
	Fuli_StrongRoad_Rebate_02YeQian_Button[2] = Fuli_StrongRoad_Rebate_Button2
	Fuli_StrongRoad_Rebate_02YeQian_Button[3] = Fuli_StrongRoad_Rebate_Button3

	GetGolden_BUTTONS[1] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button1
	GetGolden_BUTTONS[2] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button2
	GetGolden_BUTTONS[3] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button3
	GetGolden_BUTTONS[4] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button4
	GetGolden_BUTTONS[5] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button5
	GetGolden_BUTTONS[6] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button0

	GetGolden_BUTTONS_TIPS[1] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button1_tips
	GetGolden_BUTTONS_TIPS[2] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button2_tips
	GetGolden_BUTTONS_TIPS[3] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button3_tips
	GetGolden_BUTTONS_TIPS[4] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button4_tips
	GetGolden_BUTTONS_TIPS[5] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button5_tips
	GetGolden_BUTTONS_TIPS[6] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Button0_tips

	GetGolden_DESCS[1] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text1_1
	GetGolden_DESCS[2] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text2_1
	GetGolden_DESCS[3] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text3_1
	GetGolden_DESCS[4] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text4_1
	GetGolden_DESCS[5] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text5_1
	GetGolden_DESCS[6] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text0_1

	GetGolden_DESCS_EX[1] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text1_2
	GetGolden_DESCS_EX[2] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text2_2
	GetGolden_DESCS_EX[3] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text3_2
	GetGolden_DESCS_EX[4] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text4_2
	GetGolden_DESCS_EX[5] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text5_2
	GetGolden_DESCS_EX[6] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Text0_2

	GetGolden_Action[1] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Icon0
	GetGolden_Action[2] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Icon1
	GetGolden_Action[3] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Icon2
	GetGolden_Action[4] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Icon3
	GetGolden_Action[5] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Icon4
	GetGolden_Action[6] = Fuli_StrongRoad_Shenmu_Frame_KunWu_Frame2_Icon5

	g_Fuli_StrongRoad_DiaoWen_Frame_UnifiedPosition = Fuli_StrongRoad_DiaoWen_Frame:GetProperty("UnifiedPosition")
	g_ButtonPos[1].x	= Fuli_StrongRoad_DiaoWen_Button3:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].y	= Fuli_StrongRoad_DiaoWen_Button3:GetProperty("UnifiedYPosition");
	g_ButtonPos[1].tipx	= Fuli_StrongRoad_DiaoWen_Button3tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[1].tipy	= Fuli_StrongRoad_DiaoWen_Button3tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[2].x	= Fuli_StrongRoad_DiaoWen_Button5:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].y	= Fuli_StrongRoad_DiaoWen_Button5:GetProperty("UnifiedYPosition");
	g_ButtonPos[2].tipx	= Fuli_StrongRoad_DiaoWen_Button5tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[2].tipy	= Fuli_StrongRoad_DiaoWen_Button5tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[3].x	= Fuli_StrongRoad_DiaoWen_Button7:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].y	= Fuli_StrongRoad_DiaoWen_Button7:GetProperty("UnifiedYPosition");
	g_ButtonPos[3].tipx	= Fuli_StrongRoad_DiaoWen_Button7tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[3].tipy	= Fuli_StrongRoad_DiaoWen_Button7tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[4].x	= Fuli_StrongRoad_DiaoWen_Button8:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].y	= Fuli_StrongRoad_DiaoWen_Button8:GetProperty("UnifiedYPosition");
	g_ButtonPos[4].tipx	= Fuli_StrongRoad_DiaoWen_Button8tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[4].tipy	= Fuli_StrongRoad_DiaoWen_Button8tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[5].x	= Fuli_StrongRoad_DiaoWen_Button9:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].y	= Fuli_StrongRoad_DiaoWen_Button9:GetProperty("UnifiedYPosition");
	g_ButtonPos[5].tipx	= Fuli_StrongRoad_DiaoWen_Button9tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[5].tipy	= Fuli_StrongRoad_DiaoWen_Button9tips:GetProperty("UnifiedYPosition");

	g_ButtonPos[6].x	= Fuli_StrongRoad_DiaoWen_Button10:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].y	= Fuli_StrongRoad_DiaoWen_Button10:GetProperty("UnifiedYPosition");
	g_ButtonPos[6].tipx	= Fuli_StrongRoad_DiaoWen_Button10tips:GetProperty("UnifiedXPosition");
	g_ButtonPos[6].tipy	= Fuli_StrongRoad_DiaoWen_Button10tips:GetProperty("UnifiedYPosition");
end

--===============================================
-- Close()
--===============================================
function Fuli_StrongRoad_DiaoWen_Close()
	this:Hide()
end

function Fuli_StrongRoad_DiaoWen_CloseClicked()
	Fuli_StrongRoad_DiaoWen_Close()
end


function Fuli_StrongRoad_DiaoWen_On_ResetPos()
	Fuli_StrongRoad_DiaoWen_Frame:SetProperty("UnifiedPosition", g_Fuli_StrongRoad_DiaoWen_Frame_UnifiedPosition)
end

function Fuli_StrongRoad_DiaoWen_On_SetLastPos()
	local SelfFuliUnionIPos = Variable:GetVariable("SelfFuliUIPos")
	if( SelfFuliUnionIPos ~= nil) then
		Fuli_StrongRoad_DiaoWen_Frame:SetProperty("UnifiedPosition", SelfFuliUnionIPos )
	end
end

--===============================================
-- 领取雕纹融合符
--===============================================
function Fuli_StrongRoad_DiaoWen_Frame2_GetGift(nlevel)
	if not this:IsVisible() then
		return
	end

	nlevel = nlevel - 1
	if nlevel < 4 or nlevel > 7 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnChaoZhiFanKuiGetGift")
		Set_XSCRIPT_ScriptID( 890928 )
		Set_XSCRIPT_Parameter(0,nlevel)
		Set_XSCRIPT_Parameter(1,890929)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("IsShowMainButton")
		Set_XSCRIPT_ScriptID( 890928 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--===============================================
-- 打开双属性雕纹界面
-- index1 表示页签1的哪个按钮选中状态
-- index3 表示页签3的哪个按钮选中状态
--===============================================
function Fuli_StrongRoad_DiaoWen_Open(index1, index3)
--PushDebugMessage("nCharCreateDate="..nCharCreateDate)
--PushDebugMessage("CreateDate="..CreateDate)

		local nShaoDang = 2
		local nOneDay = 3
		local nHuiGui 			= 4
		local nSuperSave		= 5
		local nZhanLing =6
			-- 角色创建日期
		if ( nCharCreateDate < CreateDate ) or  ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1)  then
			Fuli_StrongRoad_DiaoWen_Button3 : Hide();
			nShaoDang = nShaoDang-1
			nOneDay = nOneDay-1
			nHuiGui   = nHuiGui - 1
			nSuperSave = nSuperSave -1
			nZhanLing = nZhanLing -1
		--	return
		else
			Fuli_StrongRoad_DiaoWen_Button3 : Show();

		end

		local nLevel = Player:GetLevel();

		Fuli_StrongRoad_DiaoWen_Button5:Show()
		if ( nLevel < 60 ) then
			Fuli_StrongRoad_DiaoWen_Button5:Hide()
			nShaoDang = -1
			nOneDay = nOneDay-1
			nHuiGui   = nHuiGui - 1
			nSuperSave = nSuperSave -1
			nZhanLing = nZhanLing -1
		end

		nOneDay = -1
		if nOneDay == -1  then
			nHuiGui   = nHuiGui - 1
			nSuperSave = nSuperSave -1
			nZhanLing = nZhanLing -1
			Fuli_StrongRoad_DiaoWen_Button7:Hide()
		end
	    if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
	    	Fuli_StrongRoad_DiaoWen_Button8 : Show()
	    elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
	    	Fuli_StrongRoad_DiaoWen_Button8 : Hide()
	    	nHuiGui   = - 1
			nSuperSave = nSuperSave -1
			nZhanLing = nZhanLing -1
	    end

	    if DataPool:Lua_GetUpdateTipsFlag( 3 ) == 1 then
	    	Fuli_StrongRoad_DiaoWen_Button9 : Show()
	    elseif DataPool:Lua_GetUpdateTipsFlag( 3 ) == 0 then
	    	Fuli_StrongRoad_DiaoWen_Button9 : Hide()
			nSuperSave =-1;
			nZhanLing = nZhanLing -1
		end
		Fuli_StrongRoad_DiaoWen_Button10:Show()
		if ( nLevel < 30 ) then
			Fuli_StrongRoad_DiaoWen_Button10:Hide()
			nZhanLing = nZhanLing -1
		end

		if nShaoDang ~= -1 then
			Fuli_StrongRoad_DiaoWen_Button5:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].x);
			Fuli_StrongRoad_DiaoWen_Button5:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].y);
			Fuli_StrongRoad_DiaoWen_Button5tips:SetProperty("UnifiedXPosition", g_ButtonPos[nShaoDang].tipx);
			Fuli_StrongRoad_DiaoWen_Button5tips:SetProperty("UnifiedYPosition", g_ButtonPos[nShaoDang].tipy);

		end

		if nOneDay ~= -1 then
			Fuli_StrongRoad_DiaoWen_Button7:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].x);
			Fuli_StrongRoad_DiaoWen_Button7:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].y);
			Fuli_StrongRoad_DiaoWen_Button7tips:SetProperty("UnifiedXPosition", g_ButtonPos[nOneDay].tipx);
			Fuli_StrongRoad_DiaoWen_Button7tips:SetProperty("UnifiedYPosition", g_ButtonPos[nOneDay].tipy);

		end

		if nHuiGui ~= -1 then
			Fuli_StrongRoad_DiaoWen_Button8:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].x);
			Fuli_StrongRoad_DiaoWen_Button8:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].y);
			Fuli_StrongRoad_DiaoWen_Button8tips:SetProperty("UnifiedXPosition", g_ButtonPos[nHuiGui].tipx);
			Fuli_StrongRoad_DiaoWen_Button8tips:SetProperty("UnifiedYPosition", g_ButtonPos[nHuiGui].tipy);
		end


		if nSuperSave ~= -1 then
			Fuli_StrongRoad_DiaoWen_Button9:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].x);
			Fuli_StrongRoad_DiaoWen_Button9:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].y);
			Fuli_StrongRoad_DiaoWen_Button9tips:SetProperty("UnifiedXPosition", g_ButtonPos[nSuperSave].tipx);
			Fuli_StrongRoad_DiaoWen_Button9tips:SetProperty("UnifiedYPosition", g_ButtonPos[nSuperSave].tipy);
		end

		if nZhanLing ~= -1 then
			Fuli_StrongRoad_DiaoWen_Button10:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].x);
			Fuli_StrongRoad_DiaoWen_Button10:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].y);
			Fuli_StrongRoad_DiaoWen_Button10tips:SetProperty("UnifiedXPosition", g_ButtonPos[nZhanLing].tipx);
			Fuli_StrongRoad_DiaoWen_Button10tips:SetProperty("UnifiedYPosition", g_ButtonPos[nZhanLing].tipy);
		end

		for i = 1, g_Levelnum do
			local getFlag = Get_XParam_INT(i-1)
			local eCount = Get_XParam_INT(i+3)
			if getFlag ~= 1 then
				if eCount < g_EquipCount then
					eCount = "#cff0000"..eCount
				end
				Fuli_StrongRoad_DiaoWen_GetGift_DESCS[i]:SetText(ScriptGlobal_Format("#{JZJL_140816_29}", g_RebackText[i],g_EquipCount,i+3))
				Fuli_StrongRoad_DiaoWen_GetGift_DESCS_EX[i]:SetText(ScriptGlobal_Format("#{JZJL_140816_53}",eCount))
				--提示
				Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS[i]:SetToolTip(ScriptGlobal_Format("#{JZJL_140816_31}",g_RebackText[i]))
				--按钮
				Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS[i]:Enable()
				Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS_TIPS[i]:Hide()
			else
				Fuli_StrongRoad_DiaoWen_GetGift_DESCS[i]:SetText(ScriptGlobal_Format("#{JZJL_140816_30}", g_RebackText[i],2))
				Fuli_StrongRoad_DiaoWen_GetGift_DESCS_EX[i]:SetText("")
				Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS[i]:Disable()
				Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS_TIPS[i]:SetToolTip(ScriptGlobal_Format("#{JZJL_140816_32}", g_RebackText[i]))
				Fuli_StrongRoad_DiaoWen_GetGift_BUTTONS_TIPS[i]:Show()
			end
		end

		DataPool:Lua_UpdateShuangXingDiaoWenItem()
		for i = 0, g_Levelnum-1 do
				local theAction = EnumAction(i, "shuangxingdiaowen_item");
				if theAction:GetID() ~= 0 then
					Fuli_StrongRoad_DiaoWen_GetGift_Action[i+1]:SetActionItem(theAction:GetID());
				end
		end

		--设置选中状态
		Fuli_StrongRoad_DiaoWen_03YeQian_Button[1]:SetCheck(1)
		Fuli_StrongRoad_Rebate_02YeQian_Button[1]:SetCheck(0)
		Fuli_StrongRoad_Rebate_02YeQian_Button[2]:SetCheck(0)


	--	for i = 1, table.getn( Fuli_StrongRoad_DiaoWen_03YeQian_Button ) do
	--		if i == index3 then
	--			Fuli_StrongRoad_DiaoWen_03YeQian_Button[i]:SetCheck(1)
	--		else
	--			Fuli_StrongRoad_DiaoWen_03YeQian_Button[i]:SetCheck(0)
	--		end
	--	end
		if SystemSetup : IsClassic() == 1 then
			Fuli_StrongRoad_Rebate_Wenziqu:Hide()
			Fuli_StrongRoad_DiaoWen_Wenziqu:SetText("#{JZJL_140816_27}")
			Fuli_StrongRoad_DiaoWen_Wenziqu:Show()
		else
			Fuli_StrongRoad_Rebate_WenziquK:Hide()
			Fuli_StrongRoad_DiaoWen_Wenziqu:SetText("#{JZJL_140816_27}")
			Fuli_StrongRoad_DiaoWen_WenziquK:Show()
		end
	--	Fuli_StrongRoad_Rebate_02YeQian:Hide()
		Fuli_StrongRoad_Shenmu_Frame:Hide()
		Fuli_StrongRoad_DiaoWen_Frame2:Show()
		Fuli_StrongRoad_DiaoWen_DiaoWen_Qianyuan:Show()

		--先特写下吧 以后去掉
		Fuli_StrongRoad_Rebate_02YeQian_Button[1]:Show()
		Fuli_StrongRoad_Rebate_02YeQian_Button[2]:Show()
		Fuli_StrongRoad_Rebate_02YeQian_Button[3]:Hide()

		if Player:GetData("Is2606S") == 1 then
			Fuli_StrongRoad_Rebate_02YeQian_Button[1]:Hide()
			Fuli_StrongRoad_Rebate_02YeQian_Button[2]:Hide()
			Fuli_StrongRoad_Rebate_02YeQian_Button[3]:Hide()
		else
			Fuli_StrongRoad_Rebate_02YeQian_Button[1]:Show()
			Fuli_StrongRoad_Rebate_02YeQian_Button[2]:Show()
			Fuli_StrongRoad_Rebate_02YeQian_Button[3]:Hide()
		end
		Fuli_StrongRoad_DiaoWen_UpdateRedPointInUI()

		Fuli_StrongRoad_DiaoWen_Button1:SetCheck(0)
		Fuli_StrongRoad_DiaoWen_Button2:SetCheck(1)
		Fuli_StrongRoad_DiaoWen_Button3:SetCheck(0)
		Fuli_StrongRoad_DiaoWen_Button5:SetCheck(0)

		this:Show()
end

function Fuli_StrongRoad_DiaoWen_01YeQianHK_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenChaoZhiFanKui")
		Set_XSCRIPT_ScriptID(890928)
		Set_XSCRIPT_Parameter(0,890929)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Fuli_StrongRoad_DiaoWen_01YeQianFB_Click()
	PushEvent( "OPEN_Fuli_StrongRoad_MONUMENT" )
	Fuli_StrongRoad_DiaoWen_Close()
end

--===============================================
-- 领取金丹
--===============================================
function Fuli_StrongRoad_Rebate_Frame2_GetGift(nIndex)
	if not this:IsVisible() then
      return
  end

  nIndex = nIndex + 4

  if nIndex < 4 or nIndex > 9 then
      return
  end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnChaoZhiFanKuiGetGift" )
		Set_XSCRIPT_ScriptID(890928)
		Set_XSCRIPT_Parameter(0,nIndex);
		Set_XSCRIPT_Parameter(1,890892);
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("IsShowMainButton")
		Set_XSCRIPT_ScriptID( 890928 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--===============================================
-- 领取金丹
--===============================================
function Fuli_StrongRoad_Rebate_Frame2_GetGiftEx(nIndex)
	if not this:IsVisible() then
      return
  end

  nIndex = nIndex + 4

  if nIndex < 4 or nIndex > 9 then
      return
  end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnChaoZhiFanKuiGetGift" )
		Set_XSCRIPT_ScriptID(890928)
		Set_XSCRIPT_Parameter(0,nIndex);
		Set_XSCRIPT_Parameter(1,891658);
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("IsShowMainButton")
		Set_XSCRIPT_ScriptID( 890928 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--===============================================
-- 打开誉满乾坤部分
-- index2 表示页签2的哪个按钮选中状态
-- index3 表示页签3的哪个按钮选中状态
--===============================================
function Fuli_StrongRoad_Rebate_Open(index2, index3)

	-- 角色创建日期
	if ( nCharCreateDate < CreateDate ) or  ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1)  then
		Fuli_StrongRoad_DiaoWen_Button3 : Hide();
	--	return
	else
		Fuli_StrongRoad_DiaoWen_Button3 : Show();
	end

	local ncurChengDan = Get_XParam_INT(0)
	local ncurLevel = Get_XParam_INT(1)
	local ncurPos = Get_XParam_INT(2)

	--PushDebugMessage("open")
	Fuli_StrongRoad_Shenmu_Frame:Show()
	Fuli_StrongRoad_DiaoWen_Frame2:Hide()
	Fuli_StrongRoad_DiaoWen_DiaoWen_Qianyuan:Hide()

	if index2 == 1 then
		for i = 1, g_Rebate_Levelnum do
		Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[i]:Enable();
		Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[i]:Hide()
	end

	if ncurLevel > 4 then
			--第4层已点全
			Fuli_StrongRoad_Rebate_GetGolden_DESCS[6]:SetText("#{JZJL_140816_261}")
			Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[6]:SetText(ScriptGlobal_Format("#{JZJL_140816_262}",4))
			Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[6]:SetToolTip("#{YMQK_140612_5}")
	elseif ncurLevel < 4 then
			--第4层未开启
			Fuli_StrongRoad_Rebate_GetGolden_DESCS[6]:SetText("#{JZJL_140816_261}")
			Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[6]:SetText(ScriptGlobal_Format("#{JZJL_140816_263}",0))
			Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[6]:SetToolTip("#{YMQK_140612_5}")
	else
			--第4层为当前层
		if ncurPos == ncurLevel then
				--已完成
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[6]:SetText("#{JZJL_140816_261}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[6]:SetText(ScriptGlobal_Format("#{JZJL_140816_262}",4))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[6]:SetToolTip("#{YMQK_140612_5}")
		else
				--未完成
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[6]:SetText("#{JZJL_140816_261}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[6]:SetText(ScriptGlobal_Format("#{JZJL_140816_263}",ncurPos))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[6]:SetToolTip("#{YMQK_140612_5}")
		end
	end

	if ncurLevel > 5 then
			--第5层已点全
			Fuli_StrongRoad_Rebate_GetGolden_DESCS[1]:SetText("#{JZJL_140816_268}")
			Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[1]:SetText(ScriptGlobal_Format("#{JZJL_140816_269}",5))
			Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[1]:SetToolTip("#{YMQK_140612_5}")
	elseif ncurLevel < 5 then
			--第5层未开启
			Fuli_StrongRoad_Rebate_GetGolden_DESCS[1]:SetText("#{JZJL_140816_268}")
			Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[1]:SetText(ScriptGlobal_Format("#{JZJL_140816_270}",0))
			Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[1]:SetToolTip("#{YMQK_140612_5}")
			--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[1]:Disable()
	else
			--第5层为当前层
		if ncurPos == ncurLevel then
				--已完成
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[1]:SetText("#{JZJL_140816_268}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[1]:SetText(ScriptGlobal_Format("#{JZJL_140816_269}",5))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[1]:SetToolTip("#{YMQK_140612_5}")
		else
				--未完成
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[1]:SetText("#{JZJL_140816_268}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[1]:SetText(ScriptGlobal_Format("#{JZJL_140816_270}",ncurPos))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[1]:SetToolTip("#{YMQK_140612_5}")
				--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[1]:Disable()
		end
	end

	if ncurLevel > 6 then
			--第6层已点全
			Fuli_StrongRoad_Rebate_GetGolden_DESCS[2]:SetText("#{JZJL_140816_271}")
			Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[2]:SetText(ScriptGlobal_Format("#{JZJL_140816_272}",6))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[2]:SetToolTip("#{YMQK_140612_49}")
	elseif ncurLevel < 6 then
			--第6层未开启
			Fuli_StrongRoad_Rebate_GetGolden_DESCS[2]:SetText("#{JZJL_140816_271}")
			Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[2]:SetText(ScriptGlobal_Format("#{JZJL_140816_273}",0))
			Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[2]:SetToolTip("#{YMQK_140612_49}")
			--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[2]:Disable()
	else
			--第6层为当前层
		if ncurPos == ncurLevel then
				--已完成
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[2]:SetText("#{JZJL_140816_271}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[2]:SetText(ScriptGlobal_Format("#{JZJL_140816_272}",6))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[2]:SetToolTip("#{YMQK_140612_49}")
		else
				--未完成
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[2]:SetText("#{JZJL_140816_271}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[2]:SetText(ScriptGlobal_Format("#{JZJL_140816_273}",ncurPos))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[2]:SetToolTip("#{YMQK_140612_49}")
				--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[2]:Disable()
		end
	end

	if ncurLevel > 7 then
			--第7层已点全
			Fuli_StrongRoad_Rebate_GetGolden_DESCS[3]:SetText("#{JZJL_140816_275}")
			Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[3]:SetText(ScriptGlobal_Format("#{JZJL_140816_276}",7))
			Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[3]:SetToolTip("#{YMQK_140612_49}")
	elseif ncurLevel < 7 then
			--第7层未开启
			Fuli_StrongRoad_Rebate_GetGolden_DESCS[3]:SetText("#{JZJL_140816_275}")
			Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[3]:SetText(ScriptGlobal_Format("#{JZJL_140816_277}",0))
			Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[3]:SetToolTip("#{YMQK_140612_49}")
			--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[3]:Disable()
	else
			--第7层为当前层
		if ncurPos == ncurLevel then
				--已完成
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[3]:SetText("#{JZJL_140816_275}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[3]:SetText(ScriptGlobal_Format("#{JZJL_140816_276}",7))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[3]:SetToolTip("#{YMQK_140612_49}")
		else
				--未完成
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[3]:SetText("#{JZJL_140816_275}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[3]:SetText(ScriptGlobal_Format("#{JZJL_140816_277}",ncurPos))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[3]:SetToolTip("#{YMQK_140612_49}")
				--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[3]:Disable()
			end
		end

		if ncurLevel > 8 then
				--第8层已点全
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[4]:SetText("#{JZJL_140816_278}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[4]:SetText(ScriptGlobal_Format("#{JZJL_140816_279}",8))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[4]:SetToolTip("#{YMQK_140612_49}")
		elseif ncurLevel < 8 then
				--第8层未开启
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[4]:SetText("#{JZJL_140816_278}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[4]:SetText(ScriptGlobal_Format("#{JZJL_140816_280}",0))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[4]:SetToolTip("#{YMQK_140612_49}")
				--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[4]:Disable()
		else
				--第8层为当前层
			if ncurPos == ncurLevel then
					--已完成
					Fuli_StrongRoad_Rebate_GetGolden_DESCS[4]:SetText("#{JZJL_140816_278}")
					Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[4]:SetText(ScriptGlobal_Format("#{JZJL_140816_279}",ncurPos))
					Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[4]:SetToolTip("#{YMQK_140612_49}")
			else
					--未完成
					Fuli_StrongRoad_Rebate_GetGolden_DESCS[4]:SetText("#{JZJL_140816_278}")
					Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[4]:SetText(ScriptGlobal_Format("#{JZJL_140816_280}",ncurPos))
					Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[4]:SetToolTip("#{YMQK_140612_49}")
					--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[4]:Disable()
			end
		end

		if ncurLevel > 9 then
				--第9层已点全
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[5]:SetText("#{JZJL_140816_281}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[5]:SetText(ScriptGlobal_Format("#{JZJL_140816_282}",9))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[5]:SetToolTip("#{YMQK_140612_49}")
		elseif ncurLevel < 9 then
				--第9层未开启
				Fuli_StrongRoad_Rebate_GetGolden_DESCS[5]:SetText("#{JZJL_140816_281}")
				Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[5]:SetText(ScriptGlobal_Format("#{JZJL_140816_283}",0))
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[5]:SetToolTip("#{YMQK_140612_49}")
				--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[5]:Disable()
		else
				--第9层为当前层
			if ncurPos == ncurLevel then
					--已完成
					Fuli_StrongRoad_Rebate_GetGolden_DESCS[5]:SetText("#{JZJL_140816_281}")
					Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[5]:SetText(ScriptGlobal_Format("#{JZJL_140816_282}",ncurPos))
					Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[5]:SetToolTip("#{YMQK_140612_49}")
			else
					--未完成
					Fuli_StrongRoad_Rebate_GetGolden_DESCS[5]:SetText("#{JZJL_140816_281}")
					Fuli_StrongRoad_Rebate_GetGolden_DESCS_EX[5]:SetText(ScriptGlobal_Format("#{JZJL_140816_283}",ncurPos))
					--Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[5]:Disable()
					Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[5]:SetToolTip("#{YMQK_140612_49}")
			end
		end

		for i = 1, g_Rebate_Levelnum-1 do
			if Get_XParam_INT(i+3) == 1 then
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[i]:Disable()
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[i]:SetToolTip("#{YMQK_140612_6}")
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[i]:Show()
			end
		end
		if Get_XParam_INT(3) == 1 then
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS[6]:Disable()
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[6]:SetToolTip("#{YMQK_140612_6}")
				Fuli_StrongRoad_Rebate_GetGolden_BUTTONS_TIPS[6]:Show()
		end

		DataPool:Lua_UpdateYuManQianKunBonusItem()
		for i = 0, g_Rebate_Levelnum-1 do
				local theAction = EnumAction(i, "ymqk_item");
				if theAction:GetID() ~= 0 then
					Fuli_StrongRoad_Rebate_GetGolden_Action[i+1]:SetActionItem(theAction:GetID());
				end
		end


		if SystemSetup : IsClassic() == 1 then
			Fuli_StrongRoad_DiaoWen_Wenziqu:Hide()
			Fuli_StrongRoad_Rebate_Wenziqu:SetText("#{JZJL_140816_46}")
			Fuli_StrongRoad_Rebate_Wenziqu:Show()
		else
			Fuli_StrongRoad_DiaoWen_WenziquK:Hide()
			Fuli_StrongRoad_Rebate_Wenziqu:SetText("#{JZJL_140816_46}")
			Fuli_StrongRoad_Rebate_WenziquK:Show()
		end
	--	Fuli_StrongRoad_Rebate_02YeQian:Show()
		Fuli_StrongRoad_DiaoWen_YeQian:Show()
		Fuli_StrongRoad_Shenmu_Frame_QianYuan:Show()
		Fuli_StrongRoad_Shenmu_Frame_KunWu:Hide()
		Fuli_StrongRoad_Shenmu_Frame:Show()
		Fuli_StrongRoad_DiaoWen_Frame2:Hide()
	elseif index2 == 2 then
		for i = 1, g_Rebate_Levelnum do
			GetGolden_BUTTONS[i]:Enable();
			GetGolden_BUTTONS_TIPS[i]:Hide()
		end

		if ncurLevel > 4 then
				--第4层已点全
				GetGolden_DESCS_EX[6]:SetText(ScriptGlobal_Format("#{YMQK_150914_09}",4))
				GetGolden_DESCS[6]:SetText("#{JZJL_151203_2}")
				GetGolden_BUTTONS[6]:SetToolTip("#{YMQK_150914_11}")
		elseif ncurLevel < 4 then
				--第4层未开启
				GetGolden_DESCS[6]:SetText("#{JZJL_151203_2}")
				GetGolden_DESCS_EX[6]:SetText(ScriptGlobal_Format("#{YMQK_150914_10}",0))
				GetGolden_BUTTONS[6]:SetToolTip("#{YMQK_150914_11}")
		else
				--第4层为当前层
			if ncurPos == ncurLevel then
					--已完成
					GetGolden_DESCS[6]:SetText("#{JZJL_151203_2}")
					GetGolden_DESCS_EX[6]:SetText(ScriptGlobal_Format("#{YMQK_150914_09}",4))
					GetGolden_BUTTONS[6]:SetToolTip("#{YMQK_150914_11}")
			else
					--未完成
					GetGolden_DESCS[6]:SetText("#{JZJL_151203_2}")
					GetGolden_DESCS_EX[6]:SetText(ScriptGlobal_Format("#{YMQK_150914_10}",ncurPos))
					GetGolden_BUTTONS[6]:SetToolTip("#{YMQK_150914_11}")
			end
		end

		if ncurLevel > 5 then
				--第5层已点全
				GetGolden_DESCS_EX[1]:SetText(ScriptGlobal_Format("#{YMQK_150914_14}",5))
				GetGolden_DESCS[1]:SetText("#{JZJL_151203_7}")
				GetGolden_BUTTONS[1]:SetToolTip("#{YMQK_150914_11}")
		elseif ncurLevel < 5 then
				--第5层未开启
				GetGolden_DESCS[1]:SetText("#{JZJL_151203_7}")
				GetGolden_DESCS_EX[1]:SetText(ScriptGlobal_Format("#{YMQK_150914_15}",0))
				GetGolden_BUTTONS[1]:SetToolTip("#{YMQK_150914_11}")
				--GetGolden_BUTTONS[1]:Disable()
		else
				--第5层为当前层
			if ncurPos == ncurLevel then
					--已完成
					GetGolden_DESCS[1]:SetText("#{JZJL_151203_7}")
					GetGolden_DESCS_EX[1]:SetText(ScriptGlobal_Format("#{YMQK_150914_14}",5))
					GetGolden_BUTTONS[1]:SetToolTip("#{YMQK_150914_11}")
			else
					--未完成
					GetGolden_DESCS[1]:SetText("#{JZJL_151203_7}")
					GetGolden_DESCS_EX[1]:SetText(ScriptGlobal_Format("#{YMQK_150914_15}",ncurPos))
					GetGolden_BUTTONS[1]:SetToolTip("#{YMQK_150914_11}")
					--GetGolden_BUTTONS[1]:Disable()
			end
		end

		if ncurLevel > 6 then
				--第6层已点全
				GetGolden_DESCS[2]:SetText("#{JZJL_151203_10}")
				GetGolden_DESCS_EX[2]:SetText(ScriptGlobal_Format("#{YMQK_150914_16}",6))
					GetGolden_BUTTONS[2]:SetToolTip("#{YMQK_150914_28}")
		elseif ncurLevel < 6 then
				--第6层未开启
				GetGolden_DESCS[2]:SetText("#{JZJL_151203_10}")
				GetGolden_DESCS_EX[2]:SetText(ScriptGlobal_Format("#{YMQK_150914_17}",0))
					GetGolden_BUTTONS[2]:SetToolTip("#{YMQK_150914_28}")
				--GetGolden_BUTTONS[2]:Disable()
		else
				--第6层为当前层
			if ncurPos == ncurLevel then
					--已完成
					GetGolden_DESCS[2]:SetText("#{JZJL_151203_10}")
					GetGolden_DESCS_EX[2]:SetText(ScriptGlobal_Format("#{YMQK_150914_16}",6))
					GetGolden_BUTTONS[2]:SetToolTip("#{YMQK_150914_28}")
			else
					--未完成
					GetGolden_DESCS[2]:SetText("#{JZJL_151203_10}")
					GetGolden_DESCS_EX[2]:SetText(ScriptGlobal_Format("#{YMQK_150914_17}",ncurPos))
					GetGolden_BUTTONS[2]:SetToolTip("#{YMQK_150914_28}")
					--GetGolden_BUTTONS[2]:Disable()
			end
		end

		if ncurLevel > 7 then
				--第7层已点全
				GetGolden_DESCS[3]:SetText("#{JZJL_151203_14}")
				GetGolden_DESCS_EX[3]:SetText(ScriptGlobal_Format("#{YMQK_150914_18}",7))
				GetGolden_BUTTONS[3]:SetToolTip("#{YMQK_150914_28}")
		elseif ncurLevel < 7 then
				--第7层未开启
				GetGolden_DESCS[3]:SetText("#{JZJL_151203_14}")
				GetGolden_DESCS_EX[3]:SetText(ScriptGlobal_Format("#{YMQK_150914_19}",0))
				GetGolden_BUTTONS[3]:SetToolTip("#{YMQK_150914_28}")
				--GetGolden_BUTTONS[3]:Disable()
		else
				--第7层为当前层
			if ncurPos == ncurLevel then
					--已完成
					GetGolden_DESCS[3]:SetText("#{JZJL_151203_14}")
					GetGolden_DESCS_EX[3]:SetText(ScriptGlobal_Format("#{YMQK_150914_18}",7))
					GetGolden_BUTTONS[3]:SetToolTip("#{YMQK_150914_28}")
			else
					--未完成
					GetGolden_DESCS[3]:SetText("#{JZJL_151203_14}")
					GetGolden_DESCS_EX[3]:SetText(ScriptGlobal_Format("#{YMQK_150914_19}",ncurPos))
					GetGolden_BUTTONS[3]:SetToolTip("#{YMQK_150914_28}")
					--GetGolden_BUTTONS[3]:Disable()
			end
		end

		if ncurLevel > 8 then
				--第8层已点全
				GetGolden_DESCS[4]:SetText("#{JZJL_151203_17}")
				GetGolden_DESCS_EX[4]:SetText(ScriptGlobal_Format("#{YMQK_150914_20}",8))
				GetGolden_BUTTONS[4]:SetToolTip("#{YMQK_150914_28}")
		elseif ncurLevel < 8 then
				--第8层未开启
				GetGolden_DESCS[4]:SetText("#{JZJL_151203_17}")
				GetGolden_DESCS_EX[4]:SetText(ScriptGlobal_Format("#{YMQK_150914_21}",0))
				GetGolden_BUTTONS[4]:SetToolTip("#{YMQK_150914_28}")
				--GetGolden_BUTTONS[4]:Disable()
		else
				--第8层为当前层
			if ncurPos == ncurLevel then
					--已完成
					GetGolden_DESCS[4]:SetText("#{JZJL_151203_17}")
					GetGolden_DESCS_EX[4]:SetText(ScriptGlobal_Format("#{YMQK_150914_20}",ncurPos))
					GetGolden_BUTTONS[4]:SetToolTip("#{YMQK_150914_28}")
			else
					--未完成
					GetGolden_DESCS[4]:SetText("#{JZJL_151203_17}")
					GetGolden_DESCS_EX[4]:SetText(ScriptGlobal_Format("#{YMQK_150914_21}",ncurPos))
					GetGolden_BUTTONS[4]:SetToolTip("#{YMQK_150914_28}")
					--GetGolden_BUTTONS[4]:Disable()
			end
		end

		if ncurLevel > 9 then
				--第9层已点全
				GetGolden_DESCS[5]:SetText("#{JZJL_151203_20}")
				GetGolden_DESCS_EX[5]:SetText(ScriptGlobal_Format("#{YMQK_150914_22}",9))
				GetGolden_BUTTONS[5]:SetToolTip("#{YMQK_150914_28}")
		elseif ncurLevel < 9 then
				--第9层未开启
				GetGolden_DESCS[5]:SetText("#{JZJL_151203_20}")
				GetGolden_DESCS_EX[5]:SetText(ScriptGlobal_Format("#{YMQK_150914_23}",0))
				GetGolden_BUTTONS[5]:SetToolTip("#{YMQK_150914_28}")
				--GetGolden_BUTTONS[5]:Disable()
		else
				--第9层为当前层
			if ncurPos == ncurLevel then
					--已完成
					GetGolden_DESCS[5]:SetText("#{JZJL_151203_20}")
					GetGolden_DESCS_EX[5]:SetText(ScriptGlobal_Format("#{YMQK_150914_22}",ncurPos))
					GetGolden_BUTTONS[5]:SetToolTip("#{YMQK_150914_28}")
			else
					--未完成
					GetGolden_DESCS[5]:SetText("#{JZJL_151203_20}")
					GetGolden_DESCS_EX[5]:SetText(ScriptGlobal_Format("#{YMQK_150914_23}",ncurPos))
					--GetGolden_BUTTONS[5]:Disable()
					GetGolden_BUTTONS[5]:SetToolTip("#{YMQK_150914_28}")
			end
		end

		for i = 1, g_Rebate_Levelnum-1 do
			if Get_XParam_INT(i+3) == 1 then
				GetGolden_BUTTONS[i]:Disable()
				GetGolden_BUTTONS_TIPS[i]:SetToolTip("#{JZJL_151203_6}")
				GetGolden_BUTTONS_TIPS[i]:Show()
			end
		end
		if Get_XParam_INT(3) == 1 then
				GetGolden_BUTTONS[6]:Disable()
				GetGolden_BUTTONS_TIPS[6]:SetToolTip("#{JZJL_151203_6}")
				GetGolden_BUTTONS_TIPS[6]:Show()
		end

		DataPool:Lua_UpdateYuManQianKunSecondBonusItem()
		for i = 0, g_Rebate_Levelnum-1 do
				local theAction = EnumAction(i, "ymqk2_item");
				if theAction:GetID() ~= 0 then
					GetGolden_Action[i+1]:SetActionItem(theAction:GetID());
				end
		end
		if SystemSetup : IsClassic() == 1 then
			Fuli_StrongRoad_DiaoWen_Wenziqu:Hide()
			Fuli_StrongRoad_Shenmu_Frame_KunWu_Wenziqu:SetText("#{JZJL_151203_1}")
			Fuli_StrongRoad_Shenmu_Frame_KunWu_Wenziqu:Show()
		else
			Fuli_StrongRoad_DiaoWen_WenziquK:Hide()
			Fuli_StrongRoad_Shenmu_Frame_KunWu_Wenziqu:SetText("#{JZJL_151203_1}")
			Fuli_StrongRoad_Shenmu_Frame_KunWu_Wenziqu:Show()
		end
	--	Fuli_StrongRoad_Rebate_02YeQian:Show()
		Fuli_StrongRoad_DiaoWen_YeQian:Show()
		Fuli_StrongRoad_Shenmu_Frame_QianYuan:Hide()
		Fuli_StrongRoad_Shenmu_Frame_KunWu:Show()
		Fuli_StrongRoad_Shenmu_Frame:Show()
		Fuli_StrongRoad_DiaoWen_Frame2:Hide()
	end


		--先特写下吧 以后去掉
		Fuli_StrongRoad_Rebate_02YeQian_Button[1]:Show()
		Fuli_StrongRoad_Rebate_02YeQian_Button[2]:Show()
		Fuli_StrongRoad_Rebate_02YeQian_Button[3]:Hide()

		--设置选中状态
		for i = 1, table.getn( Fuli_StrongRoad_Rebate_02YeQian_Button ) do
			if i == index2 then
				Fuli_StrongRoad_Rebate_02YeQian_Button[i]:SetCheck(1)
			else
				Fuli_StrongRoad_Rebate_02YeQian_Button[i]:SetCheck(0)
			end
		end

	--	for i = 1, table.getn( Fuli_StrongRoad_DiaoWen_03YeQian_Button ) do
	--		if i == index3 then
	--			Fuli_StrongRoad_DiaoWen_03YeQian_Button[i]:SetCheck(1)
	--		else
	--			Fuli_StrongRoad_DiaoWen_03YeQian_Button[i]:SetCheck(0)
	--		end
	--	end

		Fuli_StrongRoad_DiaoWen_03YeQian_Button[1]:SetCheck(0)

		Fuli_StrongRoad_DiaoWen_UpdateRedPointInUI()

		Fuli_StrongRoad_DiaoWen_Button1:SetCheck(0)
		Fuli_StrongRoad_DiaoWen_Button2:SetCheck(1)
		Fuli_StrongRoad_DiaoWen_Button3:SetCheck(0)

		this:Show()
end


--===============================================
-- 向服务器请求打开誉满乾坤
--===============================================
function Fuli_StrongRoad_DiaoWen_Button01_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenChaoZhiFanKui")
		Set_XSCRIPT_ScriptID(890928)
		Set_XSCRIPT_Parameter(0,890929)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--===============================================
-- 向服务器请求打开双属性雕纹
--===============================================
function Fuli_StrongRoad_DiaoWen_Button02_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenChaoZhiFanKui")
		Set_XSCRIPT_ScriptID(890928)
		Set_XSCRIPT_Parameter(0,890892)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--===============================================
-- 向服务器请求打开誉满乾坤第二页
--===============================================
function Fuli_StrongRoad_DiaoWen_Button03_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenChaoZhiFanKui")
		Set_XSCRIPT_ScriptID(890928)
		Set_XSCRIPT_Parameter(0,891658)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function Fuli_StrongRoad_DiaoWen_UpdateRedPointInUI()

--	Fuli_StrongRoad_DiaoWen_Button01tips:Hide()
--	Fuli_StrongRoad_DiaoWen_Button02tips:Hide()
--	Fuli_StrongRoad_Rebate_Button1tips:Hide()
--	Fuli_StrongRoad_Rebate_Button2tips:Hide()
--	Fuli_StrongRoad_Rebate_Button3tips:Hide()

	Fuli_StrongRoad_DiaoWen_Button1tips:Hide()
	Fuli_StrongRoad_DiaoWen_Button2tips:Hide()
	Fuli_StrongRoad_DiaoWen_Button3tips:Hide()
	Fuli_StrongRoad_DiaoWen_Button01tips:Hide()
	Fuli_StrongRoad_Rebate_Button1tips:Hide()
	Fuli_StrongRoad_Rebate_Button2tips:Hide()
	Fuli_StrongRoad_Rebate_Button3tips:Hide()

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button7tips : Hide()
	end

	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button8tips : Hide()
	end
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button8 : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
			-- 角色创建日期
		if ( nCharCreateDate < CreateDate ) or ( g_bIsNewServerGiftsForLevelUpValid == 1 or g_bIsNewServerGiftsForLevelUpValid_2023 == 1) then
			DataPool:Lua_SetRedPointInUIShow(39, 0)
			Fuli_StrongRoad_DiaoWen_Button3tips : Hide()
		else
			Fuli_StrongRoad_DiaoWen_Button3tips : Show()
		end
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button3tips : Hide()
	end


	if DataPool:Lua_IsRedPointInUIShow( 2 ) == 1 then

		Fuli_StrongRoad_DiaoWen_Button01tips:Show()

	end

--	if DataPool:Lua_IsRedPointInUIShow( 3 ) == 1 then

--		Fuli_StrongRoad_DiaoWen_Button02tips:Show()

--	end

	if DataPool:Lua_IsRedPointInUIShow( 10 ) == 1 then

		Fuli_StrongRoad_Rebate_Button1tips:Show()

	end

	if DataPool:Lua_IsRedPointInUIShow( 11 ) == 1 then

		Fuli_StrongRoad_Rebate_Button2tips:Show()

	end

	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		Fuli_StrongRoad_DiaoWen_Button5tips : Show()
	else
		Fuli_StrongRoad_DiaoWen_Button5tips : Hide()
	end

	-- 福利 累充
	if DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button9tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 4 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button9tips : Hide()
	end

	if DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button10tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 5 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button10tips : Hide()
	end

end


function Fuli_StrongRoad_DiaoWen_Button1_Click()
	OpenMonthlySign(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_StrongRoad_DiaoWen_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_StrongRoad_DiaoWen_Button2_Click()
end

function Fuli_StrongRoad_DiaoWen_Button3_Click()
	OpenQianKunDai(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_StrongRoad_DiaoWen_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_StrongRoad_DiaoWen_Button4_Click()

end

function Fuli_StrongRoad_DiaoWen_Button5_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 60 ) then
		PushDebugMessage("#{JFRW_170217_4}")
		return
	end

	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name("OpenDailyFuBen")
	--	Set_XSCRIPT_ScriptID(892428)
	--	Set_XSCRIPT_Parameter(0,0);
	--	Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT()

	OpenZhaoHui(1)

	Variable:SetVariable("SelfFuliUIPos", Fuli_StrongRoad_DiaoWen_Frame:GetProperty("UnifiedPosition"), 1)
end



function Fuli_StrongRoad_DiaoWen_Button7_Click()
	local nLevel = Player:GetLevel();
	if ( nLevel < 15 ) then
		PushDebugMessage("#{MRLB_170623_03}")
		return
	end
	Variable:SetVariable("SelfFuliUIPos", Fuli_StrongRoad_DiaoWen_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_StrongRoad_DiaoWen_Button8_Click()
	OpenHuiGui(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_StrongRoad_DiaoWen_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_StrongRoad_DiaoWen_Button9_Click()
	OpenSuperSaveUp(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_StrongRoad_DiaoWen_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_StrongRoad_DiaoWen_Button10_Click()
	local nLevel = Player:GetLevel();
	if( nLevel < 30 ) then
		PushDebugMessage("#{TLZL_190802_03}")
		return
	end
	OpenZhanLing(1)
	Variable:SetVariable("SelfFuliUIPos", Fuli_StrongRoad_DiaoWen_Frame:GetProperty("UnifiedPosition"), 1)
end

function Fuli_StrongRoad_DiaoWen_Refresh_ButtonTips()

	-- 更新小红点
	if DataPool:Lua_GetUpdateTipsFlag( 0 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button7tips : Hide()
	elseif DataPool:Lua_GetUpdateTipsFlag( 0 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button7tips : Hide()
	end

	-- 回归好礼
	if DataPool:Lua_GetUpdateTipsFlag( 1 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button8tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 1 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button8tips : Hide()
	end
	if DataPool:Lua_GetUpdateTipsFlag( 2 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button8 : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 2 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button8 : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 41 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button1tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 41 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button1tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 40 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button2tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 40 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button2tips : Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 39 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button3tips : Show()
	elseif DataPool:Lua_IsRedPointInUIShow( 39 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button3tips : Hide()
	end


	if DataPool:Lua_GetDailySeckillFlag() == 1 then
		Fuli_StrongRoad_DiaoWen_Button5tips : Show()
	else
		Fuli_StrongRoad_DiaoWen_Button5tips : Hide()
	end

	-- 福利 累充
	if DataPool:Lua_GetUpdateTipsFlag( 4 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button9tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 4 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button9tips : Hide()
	end
	if DataPool:Lua_GetUpdateTipsFlag( 5 ) == 1 then
		Fuli_StrongRoad_DiaoWen_Button10tips : Show()
	elseif DataPool:Lua_GetUpdateTipsFlag( 5 ) == 0 then
		Fuli_StrongRoad_DiaoWen_Button10tips : Hide()
	end
end
