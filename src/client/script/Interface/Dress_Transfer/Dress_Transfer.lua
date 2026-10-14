
local g_ObjServerID = -1
local g_Object = -1;

local m_ActionButton_DressGem_A = {}
local m_ActionButton_DressGem_B = {}

local m_DressBagIndex_A = -1
local m_DressBagIndex_B = -1

local m_ActionButton_Dress_A
local m_ActionButton_Dress_B

local m_Button_OK
local m_Text_Explain

local m_Bind_Confirmed = 0
local m_YuanbaoPay = 1

local m_Jian = -1
local g_Dress_Transfer_Frame_UnifiedPosition;

local g_FeiyuNewDressID = {
10126162,--	新锦衣卫嫣然
10126163,--	新锦衣卫红翡
10126164,--	新锦衣卫青蓝
}
local g_FeiyuDressStr = {
"#{FYYR_200610_34}",
"#{FYYR_200610_35}",
"#{FYYR_200610_36}",
}
--=========
--PreLoad==
--=========
function Dress_Transfer_PreLoad()
	this:RegisterEvent("OPEN_DRESS_TRANSFER")
	
	this:RegisterEvent("CLOSE_DRESS_TRANSFER")
	this:RegisterEvent("DRESS_TRANSFER_PUTIN_DRESS")
	this:RegisterEvent("DRESS_TRANSFER_REMOVE_DRESS")
	this:RegisterEvent("DRESS_TRANSFER_RCLICK")
	this:RegisterEvent("DRESS_TRANSFER_FITTING_HIDDEN")
	this:RegisterEvent("DRESS_TRANSFER_BIND_CONFIRMED")
	this:RegisterEvent("DRESS_TRANSFER_DONE")
	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("OPEN_DRESSCLOTH")	
	
	this:RegisterEvent("UI_COMMAND");
end

--=========
--OnLoad
--=========
function Dress_Transfer_OnLoad()

	m_ActionButton_Dress_A = Dress_Transfer_Special_Button
	m_ActionButton_Dress_B = Dress_Transfer_Special_Button5
	
	m_ActionButton_DressGem_A[1] = Dress_Transfer_Special_Button1
	m_ActionButton_DressGem_A[2] = Dress_Transfer_Special_Button2
	m_ActionButton_DressGem_A[3] = Dress_Transfer_Special_Button3
	
	m_ActionButton_DressGem_B[1] = Dress_Transfer_Special_Button6
	m_ActionButton_DressGem_B[2] = Dress_Transfer_Special_Button7
	m_ActionButton_DressGem_B[3] = Dress_Transfer_Special_Button8
	
	m_Button_OK = Dress_Transfer_OK
	m_Text_Explain = Dress_Transfer_shuoming1
	
	Dress_Transfer_Special_Button1_Feng:Hide()
	Dress_Transfer_Special_Button2_Feng:Hide()
	Dress_Transfer_Special_Button3_Feng:Hide()
	Dress_Transfer_Special_Button6_Feng:Hide()
	Dress_Transfer_Special_Button7_Feng:Hide()
	Dress_Transfer_Special_Button8_Feng:Hide()
	
	Dress_Transfer_Special_Button1_Feng_tips:Hide()
	Dress_Transfer_Special_Button2_Feng_tips:Hide()
	Dress_Transfer_Special_Button3_Feng_tips:Hide()
	Dress_Transfer_Special_Button6_Feng_tips:Hide()
	Dress_Transfer_Special_Button7_Feng_tips:Hide()
	Dress_Transfer_Special_Button8_Feng_tips:Hide()
	
	
	
	g_Dress_Transfer_Frame_UnifiedPosition=Dress_Transfer_Frame:GetProperty("UnifiedPosition");
end
--=========
--OnEvent
--=========
function Dress_Transfer_OnEvent(event)
	
	if event == "OPEN_DRESS_TRANSFER" then
		local nObjServerID = tonumber( arg0 )
		local nObjCaredID = DataPool : GetNPCIDByServerID( nObjServerID )
		if nObjCaredID and nObjCaredID >= 0 then
			Dress_Transfer_CloseOtherWindows()
			g_ObjServerID = nObjServerID
			Dress_Transfer_Show()
			g_Object = nObjCaredID
			this:CareObject( nObjCaredID, 1)
			Dress_Transfer_InitFakeObj()
			Dress_Transfer_LeftFrame_FakeObject:SetFakeObject("DressEnchase_Player");
			Dress_Transfer_TopFrame_Fenye4:SetCheck(1)
		end
		return
	end

	if ( event == "OPEN_DRESSCLOTH" ) then
		local type = tonumber( arg0 );
		if type == 4 and true ~= this:IsVisible() then
			local nObjCaredID = tonumber( Variable:GetVariable("DressClothNPCID") )
			if nObjCaredID and nObjCaredID >= 0 then
				Dress_Transfer_CloseOtherWindows()
				g_ObjServerID = nObjServerID
				Dress_Transfer_Show()
				g_Object = nObjCaredID
				this:CareObject( nObjCaredID, 1)
				g_Dress_Transfer_Frame_UnifiedPosition = Variable:GetVariable("DressClothPos")
				Dress_Transfer_Frame:SetProperty("UnifiedPosition", g_Dress_Transfer_Frame_UnifiedPosition);
				Dress_Transfer_InitFakeObj()
				Dress_Transfer_LeftFrame_FakeObject:SetFakeObject("DressEnchase_Player");
				Dress_Transfer_TopFrame_Fenye4:SetCheck(1)
			end			
		end
		return
	end		
	
	if event == "DRESS_TRANSFER_PUTIN_DRESS"  and this:IsVisible() then
		if tonumber(arg0) ~= nil and tonumber(arg1) ~= nil then
			Dress_Transfer_OnItemDragedDropFromBag( tonumber(arg0) ,tonumber(arg1))
		end
		return
	end
	
	if event == "DRESS_TRANSFER_RCLICK"  and this:IsVisible() then
		if tonumber(arg0) ~= nil then
			Dress_Transfer_OnBagItemRClicked( tonumber(arg0) )
		end
		return
	end
	
	if event == "DRESS_TRANSFER_REMOVE_DRESS" and this:IsVisible() then
		if tonumber(arg0) ~= nil then
			Dress_Transfer_OnItemDragedDropAway( tonumber(arg0) )
		end
		return
	end
	
	if event == "DRESS_TRANSFER_FITTING_HIDDEN" and this:IsVisible() then
		Dress_Transfer_NoPreview()	
		return
	end
	
	if event == "DRESS_TRANSFER_BIND_CONFIRMED" and this:IsVisible() then
		m_Bind_Confirmed = 1	
		return
	end
	
	if event == "DRESS_TRANSFER_DONE" and this:IsVisible() then
		--关闭“配饰转移”试衣间
		if IsWindowShow("Dress_Transfer_Fitting") then
			CloseWindow("Dress_Transfer_Fitting", true)
		end
		Dress_Transfer_RestoreFakeObj()
		Dress_Transfer_InitFakeObj()		
		Dress_Transfer_CleanUp()
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
	
			-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			Dress_Transfer_OnCloseClicked()
			return
		end
	end

end
--UI恢复到第一次打开时的状态
function Dress_Transfer_Init()
	if m_YuanbaoPay == 1 or m_YuanbaoPay == 0 then
		Dress_Transfer_YuanBaoPay:SetCheck(m_YuanbaoPay)
	end
end
--=========
--Show UI
--=========
function Dress_Transfer_Show()
	
	Dress_Transfer_Init()
	this:Show()
	
end
--关闭 或 打开 UI时 ，清空一次
function Dress_Transfer_CleanUp()

	m_ActionButton_Dress_A:SetActionItem(-1)
	m_ActionButton_Dress_B:SetActionItem(-1)
	
	for i = 1 , 3 do
		m_ActionButton_DressGem_A[ i ]:SetActionItem(-1)
		m_ActionButton_DressGem_B[ i ]:SetActionItem(-1)
		m_ActionButton_DressGem_A[i]:SetProperty( "BackImage", "" )
		m_ActionButton_DressGem_B[i]:SetProperty( "BackImage", "" )
	end
	
	if m_DressBagIndex_A ~= -1 then
		LifeAbility : Lock_Packet_Item(m_DressBagIndex_A,0)
	end
	
	if m_DressBagIndex_B ~= -1 then
		LifeAbility : Lock_Packet_Item(m_DressBagIndex_B,0)
	end

	m_DressBagIndex_A = -1
	m_DressBagIndex_B = -1
	m_Button_OK:Disable()
	m_Text_Explain:SetText("")
	Dress_Transfer_zhuanyi:Disable()
	Dress_Transfer_zhuanyi:Show()
	Dress_Transfer_huifu:Hide()
	
	m_Bind_Confirmed = 0
	
end
--刷新界面
function Dress_Transfer_Refresh()
	
	--关闭“配饰转移”试衣间
	if IsWindowShow("Dress_Transfer_Fitting") then
		CloseWindow("Dress_Transfer_Fitting", true)
	end
	
	--没有源装备直接清空
	if m_DressBagIndex_A == -1 then
		
		m_ActionButton_Dress_A:SetActionItem(-1)
		
		for i = 1 , 3 do
			m_ActionButton_DressGem_A[ i ]:SetActionItem(-1)
			m_ActionButton_DressGem_A[i]:SetProperty( "BackImage", "" )
		end	
	else
	
		local theAction_A = EnumAction(m_DressBagIndex_A, "packageitem")
		if theAction_A:GetID() == 0 then
			
			m_ActionButton_Dress_A:SetActionItem(-1)
		
			for i = 1 , 3 do
				m_ActionButton_DressGem_A[ i ]:SetActionItem(-1)
				m_ActionButton_DressGem_A[i]:SetProperty( "BackImage", "" )
			end
		else
		
			m_ActionButton_Dress_A:SetActionItem(theAction_A:GetID())
			LifeAbility : Lock_Packet_Item(m_DressBagIndex_A,1)
			
			if DataPool:Lua_DressGemListA_Update(m_DressBagIndex_A) == 1 then
				
				for i = 1 , 3 do
					
					m_ActionButton_DressGem_A[ i ]:SetActionItem(-1)
					
					local gemAction = EnumAction( i - 1 , "DressTransfer_Gem_A" )
					if gemAction:GetID() ~= 0 then
						m_ActionButton_DressGem_A[ i ]:SetActionItem(gemAction:GetID())
					end

				end
			
			end
		
		end
	
	end
		
	--没有目标装备直接清空
	if m_DressBagIndex_B == -1 then
		
		m_ActionButton_Dress_B:SetActionItem(-1)
		
		for i = 1 , 3 do
			m_ActionButton_DressGem_B[ i ]:SetActionItem(-1)
			m_ActionButton_DressGem_B[i]:SetProperty( "BackImage", "" )
		end
	else

		local theAction_B = EnumAction(m_DressBagIndex_B, "packageitem")
		if theAction_B:GetID() == 0 then
			
			m_ActionButton_Dress_B:SetActionItem(-1)
			
			for i = 1 , 3 do
				m_ActionButton_DressGem_B[ i ]:SetActionItem(-1)
				m_ActionButton_DressGem_B[i]:SetProperty( "BackImage", "" )
			end
			
		else

			m_ActionButton_Dress_B:SetActionItem(theAction_B:GetID())
			LifeAbility : Lock_Packet_Item(m_DressBagIndex_B,1)
			
			if DataPool:Lua_DressGemListB_Update(m_DressBagIndex_B) == 1 then
				
				for i = 1 , 3 do
					
					m_ActionButton_DressGem_B[ i ]:SetActionItem(-1)
					
					local gemAction = EnumAction( i - 1 , "DressTransfer_Gem_B" )
					
					if gemAction:GetID() ~= 0 then
						m_ActionButton_DressGem_B[ i ]:SetActionItem(gemAction:GetID())
					end

				end
			
			end
		
		end
	end
	
	
	
	
	if m_DressBagIndex_A ~= -1 and m_DressBagIndex_B ~= -1 then
		
		m_Button_OK:Enable()
		Dress_Transfer_zhuanyi:Enable()
		
		local nHoleCount_A = LifeAbility:GetEquip_HoleCount(m_DressBagIndex_A)
		local nHoleCount_B = LifeAbility:GetEquip_HoleCount(m_DressBagIndex_B)
	
		local nGemCount_A = LifeAbility:GetEquip_GemCount(m_DressBagIndex_A)
		local nGemCount_B = LifeAbility:GetEquip_GemCount(m_DressBagIndex_B)
		
		local bSamePosGem = 0
		for i = 1 , nHoleCount_A do
		
			local nGem_Type_A,_ = LifeAbility:GetEquip_GemTypeSubindex(m_DressBagIndex_A , i - 1)
			
			if nGem_Type_A > 0 then
				
				for j = 1 , nHoleCount_B do
				
					local nGem_Type_B,_ = LifeAbility:GetEquip_GemTypeSubindex(m_DressBagIndex_B , j - 1)
				
					if nGem_Type_A == nGem_Type_B then
						bSamePosGem = 1
					end
				
				end
			
			end
			
		end
		
		if bSamePosGem == 1 then
			m_Text_Explain:SetText("#{SZPSZY_160314_40}")
		else
			if (nHoleCount_B - nGemCount_B) < nGemCount_A then
				local strTemp = ScriptGlobal_Format("#{SZPSZY_160314_38}",tostring(nGemCount_A),tostring(nHoleCount_B - nGemCount_B))	
				m_Text_Explain:SetText(strTemp)
			else
				local strTemp = ScriptGlobal_Format("#{SZPSZY_160314_10}",tostring(nGemCount_A),tostring(nHoleCount_B - nGemCount_B))	
				m_Text_Explain:SetText(strTemp)
			end		
		end

		
	else
		m_Button_OK:Disable()
		m_Text_Explain:SetText("")
		Dress_Transfer_zhuanyi:Disable()
	end
	
	Dress_Transfer_zhuanyi:Show()
	Dress_Transfer_huifu:Hide()
	
end
--从背包内右键点击
function Dress_Transfer_OnBagItemRClicked( iBagIndex )
	
	--源装备槽空着 ，相当于拖入源装备槽
	if m_DressBagIndex_A == -1 then
		Dress_Transfer_OnItemDragedDropFromBag( iBagIndex , 0)
		return
	else
		--源装备没空 ，相当于拖入目标装备槽
		Dress_Transfer_OnItemDragedDropFromBag( iBagIndex , 1)
		return
	end
	
end
--从背包拖拽到UI
function Dress_Transfer_OnItemDragedDropFromBag( iBagIndex , iSlotIdx)
	
	--拖到源装备槽
	if iSlotIdx == 0 then
		
		--不是时装
		if PlayerPackage:Lua_GetBagItemEquipPoint(iBagIndex) ~= 16 then
			PushDebugMessage("#{SZPSZY_160314_06}")	
			return		
		end
		
		--加锁
		if PlayerPackage:IsLock( iBagIndex ) == 1 then
			PushDebugMessage("#{SZPSZY_160314_07}")	
			return
		end
		
		--时装上没有配饰可以转移，无法进行放入
		local nHoleCount = LifeAbility:GetEquip_HoleCount(iBagIndex)
		if nHoleCount < 1 then
			PushDebugMessage("#{SZPSZY_160314_08}")	
			return		
		end
		
		--时装上没有配饰可以转移，无法进行放入
		local nGemCount = LifeAbility:GetEquip_GemCount(iBagIndex)
		if nGemCount < 1 then
			PushDebugMessage("#{SZPSZY_160314_08}")	
			return		
		end
		
		--释放原来的装备
		if m_DressBagIndex_A ~= -1 then
			LifeAbility : Lock_Packet_Item(m_DressBagIndex_A,0)
		end
		
		m_DressBagIndex_A = iBagIndex
		
		--刷新界面
		Dress_Transfer_Refresh()
		m_Bind_Confirmed = 0
		Dress_Transfer_UpdateFakeObj()
		
		return
		
	end
	
	--拖到目标装备槽
	if iSlotIdx == 1 then
		
		--不是时装
		if PlayerPackage:Lua_GetBagItemEquipPoint(iBagIndex) ~= 16 then
			--PushDebugMessage("#{SZPSZY_160314_06}")	
			PushDebugMessage("#{SZZH_170306_148}")	
			PushDebugMessage("#{SZZH_170306_140}")	
			return		
		end
		
		local equipValidity = LifeAbility:Get_Equip_Validity(iBagIndex)
		if equipValidity ~= -1 then
			PushDebugMessage("#{SZZH_170306_148}")	
			PushDebugMessage("#{SZZH_170306_140}")	
			return
		end
		
		--加锁
		if PlayerPackage:IsLock( iBagIndex ) == 1 then
			PushDebugMessage("#{SZPSZY_160314_07}")	
			return
		end
		
		--该时装上没有配饰点缀位，无法进行配饰转移
		local nHoleCount = LifeAbility:GetEquip_HoleCount(iBagIndex)
		if nHoleCount < 1 then
			PushDebugMessage("#{SZPSZY_160314_11}")	
			return		
		end
		
		--该时装上没有空的配饰点缀位，无法进行配饰转移
		local nGemCount = LifeAbility:GetEquip_GemCount(iBagIndex)
		if nGemCount >= nHoleCount then
			PushDebugMessage("#{SZPSZY_160314_22}")	
			return		
		end
		
		--释放原来的装备
		if m_DressBagIndex_B ~= -1 then
			LifeAbility : Lock_Packet_Item(m_DressBagIndex_B,0)
		end

		m_DressBagIndex_B = iBagIndex
		
		--刷新界面
		Dress_Transfer_Refresh()
		m_Bind_Confirmed = 0
		
		return

	end
	
end
--从ActionItem拖拽到Window之外
function Dress_Transfer_OnItemDragedDropAway( iSlotIdx )
	Dress_Transfer_NoDress( iSlotIdx )
end
--右键单击ActionItem
function Dress_Transfer_OnActionItemRClicked( iSlotIdx )
	Dress_Transfer_NoDress( iSlotIdx )
end
--UI没有装备的状态
function Dress_Transfer_NoDress( iSlotIdx )

	if iSlotIdx == 0 then
		
		if m_DressBagIndex_A ~= -1 then
			LifeAbility : Lock_Packet_Item(m_DressBagIndex_A,0)
		end

		m_DressBagIndex_A = -1
		Dress_Transfer_Refresh()
		m_Bind_Confirmed = 0
		
		Dress_Transfer_RestoreFakeObj()
		Dress_Transfer_InitFakeObj()
		
		return 
		
	end
	
	if iSlotIdx == 1 then
		
		if m_DressBagIndex_B ~= -1 then
			LifeAbility : Lock_Packet_Item(m_DressBagIndex_B,0)
		end

		m_DressBagIndex_B = -1
		Dress_Transfer_Refresh()
		m_Bind_Confirmed = 0
		
		Dress_Transfer_UpdateFakeObj()
		
		return 
		
	end
	
end
--=========
--OnOK
--=========
function Dress_Transfer_OnOKClicked()
	
	--没有源装备和目标装备
	if m_DressBagIndex_A == -1 or m_DressBagIndex_B == -1 then
		return	
	end
	
	--不是时装
	if PlayerPackage:Lua_GetBagItemEquipPoint(m_DressBagIndex_A) ~= 16 then
		return		
	end
	
	--不是时装
	if PlayerPackage:Lua_GetBagItemEquipPoint(m_DressBagIndex_B) ~= 16 then
		return		
	end
	
	local nHoleCount_A = LifeAbility:GetEquip_HoleCount(m_DressBagIndex_A)
	local nHoleCount_B = LifeAbility:GetEquip_HoleCount(m_DressBagIndex_B)
	
	local nGemCount_A = LifeAbility:GetEquip_GemCount(m_DressBagIndex_A)
	local nGemCount_B = LifeAbility:GetEquip_GemCount(m_DressBagIndex_B)
	
	if nHoleCount_A < 1 then
		return
	end
	
	--对不起，对应转移的目标时装点缀位孔位不足
	if nHoleCount_B - nGemCount_B < nGemCount_A then
		PushDebugMessage("#{SZPSZY_160314_27}")
		return
	end
	
	for i = 1 , nHoleCount_A do
		
		local nGem_Type_A,_ = LifeAbility:GetEquip_GemTypeSubindex(m_DressBagIndex_A , i - 1)
		
		if nGem_Type_A > 0 then
			
			for j = 1 , nHoleCount_B do
			
				local nGem_Type_B,_ = LifeAbility:GetEquip_GemTypeSubindex(m_DressBagIndex_B , j - 1)
			
				if nGem_Type_A == nGem_Type_B then
					PushDebugMessage("#{SZPSZY_160314_41}")
					return
				end
			
			end
		
		end
		
	end
	
	local bBuyConfirm = Dress_Transfer_YuanBaoPay:GetCheck()
	
	if m_Bind_Confirmed == 0 then
	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DressGemTransfer")
			Set_XSCRIPT_ScriptID(880049)
			Set_XSCRIPT_Parameter(0,m_DressBagIndex_A)
			Set_XSCRIPT_Parameter(1,m_DressBagIndex_B)
			Set_XSCRIPT_Parameter(2,1)
			Set_XSCRIPT_Parameter(3,tonumber(bBuyConfirm))
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
		
	else
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DressGemTransfer")
			Set_XSCRIPT_ScriptID(880049)
			Set_XSCRIPT_Parameter(0,m_DressBagIndex_A)
			Set_XSCRIPT_Parameter(1,m_DressBagIndex_B)
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_Parameter(3,tonumber(bBuyConfirm))
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()
	
	end
end
--=========
--OnCancel
--=========
function Dress_Transfer_OnCancelClicked()
	this:Hide()
end
--=========
--OnClose "X"
--=========
function Dress_Transfer_OnCloseClicked()
	Dress_Transfer_OnHiden()
	this:Hide()
end
--=========
--handle Hide Event
--=========
function Dress_Transfer_OnHiden()
	Dress_Transfer_RestoreFakeObj()
	Dress_Transfer_InitFakeObj()
	Dress_Transfer_LeftFrame_FakeObject:SetFakeObject("");
	
	Dress_Transfer_CleanUp()
	
	m_YuanbaoPay = Dress_Transfer_YuanBaoPay:GetCheck()
	
	if(IsWindowShow("DressJian") == true) then
		PushEvent( "CLOSE_DRESSJIAN_DLG")		
	end		
	
end
--预览
function Dress_Transfer_Preview()
	
	--没有源装备和目标装备
	if m_DressBagIndex_A == -1 or m_DressBagIndex_B == -1 then
		return	
	end
	
	--不是时装
	if PlayerPackage:Lua_GetBagItemEquipPoint(m_DressBagIndex_A) ~= 16 then
		return		
	end
	
	--不是时装
	if PlayerPackage:Lua_GetBagItemEquipPoint(m_DressBagIndex_B) ~= 16 then
		return		
	end
	
	local nHoleCount_A = LifeAbility:GetEquip_HoleCount(m_DressBagIndex_A)
	local nHoleCount_B = LifeAbility:GetEquip_HoleCount(m_DressBagIndex_B)
	
	local nGemCount_A = LifeAbility:GetEquip_GemCount(m_DressBagIndex_A)
	local nGemCount_B = LifeAbility:GetEquip_GemCount(m_DressBagIndex_B)
	
	if nHoleCount_A < 1 then
		return
	end
	
	--对不起，对应转移的目标时装点缀位孔位不足
	if (nHoleCount_B - nGemCount_B) < nGemCount_A then
		PushDebugMessage("#{SZPSZY_160314_27}")
		return
	end
	
	for i = 1 , nHoleCount_A do
		
		local nGem_Type_A,_ = LifeAbility:GetEquip_GemTypeSubindex(m_DressBagIndex_A , i - 1)
		
		if nGem_Type_A > 0 then
			
			for j = 1 , nHoleCount_B do
			
				local nGem_Type_B,_ = LifeAbility:GetEquip_GemTypeSubindex(m_DressBagIndex_B , j - 1)
			
				if nGem_Type_A == nGem_Type_B then
					PushDebugMessage("#{SZPSZY_160314_41}")
					return
				end
			
			end
		
		end
		
	end
	
	local nGemID_Fitting = { 0 , 0 , 0 }
	for i = 1 , 3 do
		
		m_ActionButton_DressGem_A[ i ]:SetActionItem(-1)
		m_ActionButton_DressGem_B[ i ]:SetActionItem(-1)
		
		local gemActionA = EnumAction( i - 1 , "DressTransfer_Gem_A" )
		if gemActionA:GetID() ~= 0 then
			m_ActionButton_DressGem_B[ i ]:SetActionItem(gemActionA:GetID())
		else
			local gemActionB = EnumAction( i - 1 , "DressTransfer_Gem_B" )
			if gemActionB:GetID() ~= 0 then
				m_ActionButton_DressGem_B[ i ]:SetActionItem(gemActionB:GetID())
			end
		end
			
		local nGem_ID_A = LifeAbility:GetEquip_GemID(m_DressBagIndex_A , i - 1)
		local nGem_ID_B = LifeAbility:GetEquip_GemID(m_DressBagIndex_B , i - 1)
			
		if nGem_ID_A > 0 then
			local gemAction = EnumAction( i - 1 , "DressTransfer_Gem_A" )
			if gemAction:GetID() ~= 0 then
				m_ActionButton_DressGem_B[ i ]:SetActionItem(gemAction:GetID())
			end
			nGemID_Fitting[ i ] = nGem_ID_A
		else
			local gemAction = EnumAction( i - 1 , "DressTransfer_Gem_B" )
			if gemAction:GetID() ~= 0 then
				m_ActionButton_DressGem_B[ i ]:SetActionItem(gemAction:GetID())
			end
			nGemID_Fitting[ i ] = nGem_ID_B				
		end
		
	end
	
	local nGemID_Fitting = { 0 , 0 , 0 }
	local nGemCount_Sum = 0
	for i = 1 , 3 do
		if nGemCount_Sum < 3 then
			local nGem_ID_A = LifeAbility:GetEquip_GemID(m_DressBagIndex_A , i - 1)	
			if nGem_ID_A > 0 then
				nGemCount_Sum = nGemCount_Sum + 1
				nGemID_Fitting[ nGemCount_Sum ] = nGem_ID_A
			end
		end
	end
	
	for i = 1 , 3 do
		if nGemCount_Sum < 3 then
			local nGem_ID_B = LifeAbility:GetEquip_GemID(m_DressBagIndex_B , i - 1)	
			if nGem_ID_B > 0 then
				nGemCount_Sum = nGemCount_Sum + 1
				nGemID_Fitting[ nGemCount_Sum ] = nGem_ID_B
			end
		end
	end
	
	Dress_Transfer_zhuanyi:Hide()
	Dress_Transfer_huifu:Show()
	
	--DressEnchasing:Lua_OpenDressTransferFitting(m_DressBagIndex_B, nGemID_Fitting[1],nGemID_Fitting[2],nGemID_Fitting[3])
	if DressEnchasing:Lua_FittingOnDressTransfer(m_DressBagIndex_B, nGemID_Fitting[1],nGemID_Fitting[2],nGemID_Fitting[3]) ~= 1 then
		DressEnchasing:Lua_FittingOnDressTransferOver()	
		return
	end
	Dress_Transfer_UpdateFakeObjB()	
end
--取消预览
function Dress_Transfer_NoPreview()
	Dress_Transfer_zhuanyi:Show()
	Dress_Transfer_huifu:Hide()
	Dress_Transfer_Refresh()
	DressEnchasing:Lua_FittingOnDressTransferOver()	
	Dress_Transfer_UpdateFakeObj()
end

function Dress_Transfer_InitFakeObj()
	Dress_Transfer_LeftFrame_Jian:Hide()
	Dress_Transfer_LeftFrame_Text:SetText("")
	Dress_Transfer_LeftFrame_Text2:SetText("")
	m_Jian = -1
end

function Dress_Transfer_UpdateFakeObj()
	if m_DressBagIndex_A ~= -1 then
		DressEnchasing : FittingOnDressNew (m_DressBagIndex_A,-1,-1,-1)
		local strdic;
		local nDressId = PlayerPackage : GetItemTableIndex( m_DressBagIndex_A )
		if nDressId == g_FeiyuNewDressID[1] then
  		strdic = g_FeiyuDressStr[1]
		elseif nDressId == g_FeiyuNewDressID[2] then
			strdic = g_FeiyuDressStr[2]
		elseif nDressId == g_FeiyuNewDressID[3] then
			strdic = g_FeiyuDressStr[3]
		else
			local n_szDressDesc, nRate,MaterBind = DressReplaceColor : GetDressVisualInfo(m_DressBagIndex_A)	

			if nRate == 23000 then
				strdic = ScriptGlobal_Format("#{SZRSYH_120912_10}", n_szDressDesc)
			elseif nRate == 14000 then
				strdic = ScriptGlobal_Format("#{SZRSYH_120912_11}", n_szDressDesc)
			elseif nRate == 1000 then
				strdic = ScriptGlobal_Format("#{SZRSYH_120912_12}", n_szDressDesc)
			elseif nRate == -1 then
				strdic = "#G"..n_szDressDesc
			end
		end
		
		Dress_Transfer_LeftFrame_Jian:Show()
		Dress_Transfer_LeftFrame_Text:SetText(strdic)	
		Dress_Transfer_LeftFrame_Text2:SetText("#{SZZH_170111_95}")
		m_Jian = m_DressBagIndex_A
	else 
		Dress_Transfer_InitFakeObj()
	end
	
end

function Dress_Transfer_UpdateFakeObjB()
	local strdic;
	local nDressId = PlayerPackage : GetItemTableIndex( m_DressBagIndex_B )
	if nDressId == g_FeiyuNewDressID[1] then
		strdic = g_FeiyuDressStr[1]
	elseif nDressId == g_FeiyuNewDressID[2] then
		strdic = g_FeiyuDressStr[2]
	elseif nDressId == g_FeiyuNewDressID[3] then
		strdic = g_FeiyuDressStr[3]
	else
		local n_szDressDesc, nRate,MaterBind = DressReplaceColor : GetDressVisualInfo(m_DressBagIndex_B)	
	
	
		if nRate == 23000 then
			strdic = ScriptGlobal_Format("#{SZRSYH_120912_10}", n_szDressDesc)
		elseif nRate == 14000 then
			strdic = ScriptGlobal_Format("#{SZRSYH_120912_11}", n_szDressDesc)
		elseif nRate == 1000 then
			strdic = ScriptGlobal_Format("#{SZRSYH_120912_12}", n_szDressDesc)
		elseif nRate == -1 then
			strdic = "#G"..n_szDressDesc
		end
	end
	
	Dress_Transfer_LeftFrame_Jian:Show()
	Dress_Transfer_LeftFrame_Text:SetText(strdic)	
	Dress_Transfer_LeftFrame_Text2:SetText("#{SZZH_170111_96}")
	m_Jian = m_DressBagIndex_B	
end

function Dress_Transfer_RestoreFakeObj()
	-- 恢复试衣前的装备参数
	DressEnchasing : RestoreDressEnchaseFitting()
end

function Dress_Transfer_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			Dress_Transfer_LeftFrame_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			Dress_Transfer_LeftFrame_FakeObject:RotateEnd();
		end
	end
end

function Dress_Transfer_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			Dress_Transfer_LeftFrame_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			Dress_Transfer_LeftFrame_FakeObject:RotateEnd();
		end
	end
end

function Dress_Transfer_Clicked()
	if m_Jian ~= -1 then
		local canPaint = DressReplaceColor:DressCanPaint(m_Jian)
		if canPaint ~= 1 then
			PushDebugMessage("该时装不能染色，不能查看图鉴。")
			return
		end	
		DressReplaceColor :DressOpenDressJian(m_Jian);
	else
		Dress_Transfer_LeftFrame_Jian:Hide()
	end
end

function Dress_Transfer_CloseOtherWindows()
	if(IsWindowShow("Dress_Enchase")) then
		CloseWindow("Dress_Enchase", true);
	end			
	if(IsWindowShow("Dress_Stiletto")) then
		CloseWindow("Dress_Stiletto", true);
	end			
	if(IsWindowShow("Dress_SplitGem")) then
		CloseWindow("Dress_SplitGem", true);
	end	
	PushEvent( "CLOSE_DRESSPREVIEW") 		
	PushEvent( "CLOSE_GEMEFFECTPREVIEW")		
end

function Dress_Transfer_FenYeClick(index)
	if index == 1 or index == 2 or index == 3 then
		Variable:SetVariable("DressClothPos", Dress_Transfer_Frame:GetProperty("UnifiedPosition"), 1);
		Variable:SetVariable("DressClothNPCID", g_Object, 1);
		PushEvent("OPEN_DRESSCLOTH",index)	
	end
end
