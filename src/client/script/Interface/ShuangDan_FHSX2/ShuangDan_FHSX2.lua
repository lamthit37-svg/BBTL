--2021双旦集五福
-- 时装兑换

local g_Frame_UnifiedPosition = nil

local g_SpecialDay = 20221231
local g_EndDay = 20230104

local g_ItemId = 38006123
local g_CostNum1 = 1
local g_CostNum2 = 120

local g_LimitNum1 = 200
local g_LimitNum2 = 1

--=========
-- PreLoad()
--=========
function ShuangDan_FHSX2_PreLoad()
		this:RegisterEvent("FHSX_OPENUI", true)--打开or刷新界面
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
		this:RegisterEvent("ADJEST_UI_POS",false)
		this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

--=========
-- OnLoad()
--=========
function ShuangDan_FHSX2_OnLoad()	
		g_Frame_UnifiedPosition = ShuangDan_FHSX2_MainFrame:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function ShuangDan_FHSX2_OnEvent(event)
		if event == "FHSX_OPENUI" then		
				local bOpen = tonumber(arg0)
				local nPage = tonumber(arg1)
				if nPage ~= 2 then
						return
				end
				if bOpen ~= nil and bOpen == 1 then--开界面
						AskServerTimeAgain() 
						this:Show()
						ShuangDan_FHSX2_Update()
				else
						if( this:IsVisible() ) then--仅刷新
								ShuangDan_FHSX2_Update()
						end
				end			
		elseif event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() then	
				ShuangDan_FHSX2_UpdateDaiBi()--更新代币
		elseif event == "HIDE_ON_SCENE_TRANSED" then	
				ShuangDan_FHSX2_Close()	
		elseif event == "VIEW_RESOLUTION_CHANGED" then		
				ShuangDan_FHSX2_On_ResetPos()	
		elseif event == "ADJEST_UI_POS" then	
				ShuangDan_FHSX2_On_ResetPos()	
		end		
end

--=========
-- 重置
--=========
function ShuangDan_FHSX2_On_ResetPos()
		ShuangDan_FHSX2_MainFrame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 清数据
--=========
function ShuangDan_FHSX2_Clear()
end

--=========
-- 关闭界面
--=========
function ShuangDan_FHSX2_Close()
		ShuangDan_FHSX2_Clear()
		this:Hide()
end

--=========
-- 更新代币数量
--=========
function ShuangDan_FHSX2_UpdateDaiBi()

		-- 代币数量
		local nHaveNum = PlayerPackage:Lua_GetUnLockItemCount(g_ItemId)
		ShuangDan_FHSX2_DaiBi_Num:SetText( ScriptGlobal_Format("#{FHSX_211019_79}", nHaveNum) )	
			
		--小红点
		ShuangDan_FHSX2_Item2_Tips:Hide()
		local curDay = DataPool:GetServerDayTime()
		if curDay >= g_SpecialDay and curDay <= g_EndDay then--兑换时间
				if nHaveNum >= g_CostNum2 and DataPool:Lua_GetFHSXItemNum(1) < g_LimitNum2 then
						ShuangDan_FHSX2_Item2_Tips:Show()
				end
		end
		
end

--=========
-- 界面刷新
--=========
function ShuangDan_FHSX2_Update()
			
		-- 兑换道具
		if KaJi:LuaFnGetKaJiType(33) == 1 then
				ShuangDan_FHSX2_Item3_DuiHuan:Show()
				ShuangDan_FHSX2_Item1_DuiHuan:Hide()
		else
				ShuangDan_FHSX2_Item1_DuiHuan:Show()
				ShuangDan_FHSX2_Item3_DuiHuan:Hide()
		end
		ShuangDan_FHSX2_Item1_CostNum:SetText( ScriptGlobal_Format("#{FHSX_211019_78}", g_CostNum1) )
			
		-- 兑换礼盒
		ShuangDan_FHSX2_Item2_CostNum:SetText( ScriptGlobal_Format("#{FHSX_211019_78}", g_CostNum2) )

		-- 更新代币
		ShuangDan_FHSX2_UpdateDaiBi()
		
end	

--=========
-- 小问号
--=========
function ShuangDan_FHSX2_Help2()
		PushEvent("CCSHOP_HELP", 136)	
end
	
--=========
-- 商店兑换道具按钮
--=========
function ShuangDan_FHSX2_ItemClicked(nIndex)
		Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnBuy")
				Set_XSCRIPT_ScriptID(888836)
				Set_XSCRIPT_Parameter( 0, nIndex )
				Set_XSCRIPT_Parameter( 1, 0 )
				Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
end

--=========
-- 时装预览
-- 特写只有第二个需要预览
--=========
function ShuangDan_FHSX2_PreviewClicked()
	Clear_XSCRIPT()
			Set_XSCRIPT_ScriptID(888051)
			Set_XSCRIPT_Function_Name("DressPreview")
			Set_XSCRIPT_Parameter(0, 10126959)
			Set_XSCRIPT_Parameter(1, 163)
			Set_XSCRIPT_Parameter(2, 129)
			Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end
