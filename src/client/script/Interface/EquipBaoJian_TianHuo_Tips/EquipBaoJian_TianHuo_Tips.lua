
local 	g_ObjServerID = -1
local	g_WindowType = 0		-- 0 ：选择 1：切换

local 	g_ElementsValueName = {
	
		"#{ZZZB_150811_182}",
		"#{ZZZB_150811_183}",
		
	}
	
local 	g_EquipBaoJian_TianHuo_Tips_Frame_UnifiedXPosition
local	g_EquipBaoJian_TianHuo_Tips_Frame_UnifiedYPosition
local g_EquipBaoJian_TianHuo_YuanBaoPay = 1

--=========
--PreLoad==
--=========
function EquipBaoJian_TianHuo_Tips_PreLoad()
	
	this:RegisterEvent("FIVE_ELEMENTS_SELECTTYPE")
	this:RegisterEvent("FIVE_ELEMENTS_SWITCHTYPE")
	this:RegisterEvent("FIVEELEMENTS_UPDATE", false)
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end
--=========
--OnLoad
--=========
function EquipBaoJian_TianHuo_Tips_OnLoad()

	g_EquipBaoJian_TianHuo_Tips_Frame_UnifiedXPosition = EquipBaoJian_TianHuo_Tips_Frame:GetProperty("UnifiedXPosition")
	g_EquipBaoJian_TianHuo_Tips_Frame_UnifiedYPosition = EquipBaoJian_TianHuo_Tips_Frame:GetProperty("UnifiedYPosition")
	g_EquipBaoJian_TianHuo_YuanBaoPay = 1;
	
end
--=========
--OnEvent
--=========
function EquipBaoJian_TianHuo_Tips_OnEvent(event)

	if event == "FIVE_ELEMENTS_SELECTTYPE" then
		if tonumber(arg1) == 3 then
		
			local nObjServerID = tonumber( arg0 )
			local nObjCaredID = DataPool : GetNPCIDByServerID( nObjServerID )
			if nObjCaredID and nObjCaredID >= 0 then
				g_ObjServerID = nObjServerID
				EquipBaoJian_TianHuo_YuanBaoPay:Hide();
				EquipBaoJian_TianHuo_YuanBaoPay_TXT:Hide();
				this:Show()
				this:CareObject( nObjCaredID, 1)
				g_WindowType = 0
				EquipBaoJian_TianHuo_Tips_Update()
			end
		else
			this:Hide()		
		end
		return
	end
	
	if event == "FIVE_ELEMENTS_SWITCHTYPE" then
		if tonumber(arg1) == 3 then
		
			local nObjServerID = tonumber( arg0 )
			local nObjCaredID = DataPool : GetNPCIDByServerID( nObjServerID )
			if nObjCaredID and nObjCaredID >= 0 then
				g_ObjServerID = nObjServerID
				EquipBaoJian_TianHuo_YuanBaoPay:Show();
				EquipBaoJian_TianHuo_YuanBaoPay_TXT:Show();
				if g_EquipBaoJian_TianHuo_YuanBaoPay == 1 or g_EquipBaoJian_TianHuo_YuanBaoPay == 0 then
					EquipBaoJian_TianHuo_YuanBaoPay:SetCheck(g_EquipBaoJian_TianHuo_YuanBaoPay)
				end
				this:Show()
				this:CareObject( nObjCaredID, 1)
				g_WindowType = 1
				EquipBaoJian_TianHuo_Tips_Update()	
			end
		else
			this:Hide()		
		end
		return
	end
	
	if event == "FIVEELEMENTS_UPDATE"  and this:IsVisible() then
		EquipBaoJian_TianHuo_Tips_Update()
		return
	end
	
	if ( event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) and this:IsVisible() then
		EquipBaoJian_TianHuo_Tips_Frame_On_ResetPos()
		return
	end
	
end
--=========
--Update UI
--=========
function EquipBaoJian_TianHuo_Tips_Update()

	if g_WindowType == 0 then
	
		EquipBaoJian_TianHuo_Tips_DragTitle:SetText("#{ZZZB_150811_180}")
		EquipBaoJian_TianHuo_Tips_Info:SetText("#{ZZZB_150811_181}")
	
	elseif g_WindowType == 1 then
		
		EquipBaoJian_TianHuo_Tips_DragTitle:SetText("#{ZZZB_150811_202}")
		
		local bElementsType = Player:GetFiveElements_ElementsType( 3 )
		if bElementsType >= 1 and bElementsType <= 2 then
			local strTemp = ScriptGlobal_Format( "#{ZZZB_150811_203}", g_ElementsValueName[ bElementsType ] )
			EquipBaoJian_TianHuo_Tips_Info:SetText(strTemp)
		end
	
	end
	
end


--点击"X"
function EquipBaoJian_TianHuo_Tips_OnCloseClicked()

	this:Hide()
	
end

--点击“属性”
function EquipBaoJian_TianHuo_Tips_OnSelect(nIndex)

	if g_WindowType == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FiveElementsCohesion" )
			Set_XSCRIPT_ScriptID( 880039 )
			Set_XSCRIPT_Parameter( 0, g_ObjServerID ) 
			Set_XSCRIPT_Parameter( 1, nIndex ) 
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
		
		this:Hide()
	elseif g_WindowType == 1 then
		
		--判断是否为安全时间
		if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
			PushDebugMessage("#{ZZZB_150811_184}")
			return
		end

		if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			
			return
		end
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "FiveElementsTypeSwitch" )
			Set_XSCRIPT_ScriptID( 880039 )
			Set_XSCRIPT_Parameter( 0, 3 ) 
			Set_XSCRIPT_Parameter( 1, nIndex )
			Set_XSCRIPT_Parameter( 2, 1 ) 		--需要确认
			Set_XSCRIPT_Parameter( 3, tonumber(EquipBaoJian_TianHuo_YuanBaoPay:GetCheck()) )
			Set_XSCRIPT_ParamCount( 4 )
		Send_XSCRIPT()
		
	end
	
end

function EquipBaoJian_TianHuo_Tips_Frame_On_ResetPos()
	
	EquipBaoJian_TianHuo_Tips_Frame:SetProperty("UnifiedXPosition", g_EquipBaoJian_TianHuo_Tips_Frame_UnifiedXPosition)
	EquipBaoJian_TianHuo_Tips_Frame:SetProperty("UnifiedYPosition", g_EquipBaoJian_TianHuo_Tips_Frame_UnifiedYPosition)
	
end

function EquipBaoJian_TianHuo_Yuanbao_Click()
	if g_EquipBaoJian_TianHuo_YuanBaoPay == nil or g_EquipBaoJian_TianHuo_YuanBaoPay == 0 then
		g_EquipBaoJian_TianHuo_YuanBaoPay = 1;
	else
		g_EquipBaoJian_TianHuo_YuanBaoPay = 0;
	end
end
