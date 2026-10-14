--ZhenYuanGold.lua
local g_UnifiedPosition;
local ZhenYuanGold_BagItems = {}

local ZhenYuanGold_AbsAttrMask = 50

--真元包的位置
local ZhenYuanGold_Bag	=	36
local ZhenYuanGold_Size	=	24

local ZhenYuanGold_ConvertingItem 	= -1

local ZhenYuanGold_CaredObjId = -1
local ZhenYuanGold_OK_Confirm = 0
local ZhenYuanGold_SelectedItemName = ""

--	预加载
function ZhenYuanGold_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("PNEUMAITEM_CHANGED")
	this:RegisterEvent("PNEUMALIST_CHANGED")
	this:RegisterEvent("PNEUMA_DRAG_TO_SWITCHGOLD")
	this:RegisterEvent("TOGGLE_PNEUMA_UI")
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("PNEUMA_SWITCHGOLD_CONFIRM_OK")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
end

--	加载
function ZhenYuanGold_OnLoad()
	g_UnifiedPosition = ZhenYuanGold_Frame:GetProperty("UnifiedPosition")
		
	for line=1,6 do
		for row=1,4 do
			ZhenYuanGold_BagItems[(line-1)*4+row] = _G[string.format("ZhenYuanGold_Space_Line%d_Row%d_button",line,row)]
		end
	end
	
	for i = 1, ZhenYuanGold_Size do
		ZhenYuanGold_BagItems[i]:SetProperty("DragAcceptName", "B"..tostring(ZhenYuanGold_Bag+i-1))
	end
	ZhenYuanGold_LeftFrame_Item:SetProperty("DragAcceptName", "Z")
	
end

--	事件处理
function ZhenYuanGold_OnEvent(event)
	local objCared = DataPool:GetCurDialogNpcId();
	if event == "PNEUMAITEM_CHANGED" or event=="PNEUMALIST_CHANGED" then
		if this:IsVisible() then
			ZhenYuanGold_UpdateBag()
			ZhenYuanGold_UpdateSelected()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 88995701 then
		if not this:IsVisible() then
			this:Show()
		end
		if( Get_XParam_INT_Count() < 2 ) then
			return
		end
		local nZJFCount = Get_XParam_INT(0)
		ZhenYuanGold_Notice:SetText( ScriptGlobal_Format("#{CYZJ_150212_12}", nZJFCount ) );
			
		local servid = Get_XParam_INT(1)
		if servid >= 0 then
			ZhenYuanGold_CaredObjId = DataPool : GetNPCIDByServerID(servid)
			if ZhenYuanGold_CaredObjId ~= -1 then
				this:CareObject( ZhenYuanGold_CaredObjId, 1, "ZhenYuanGold" )
			end
			
			CloseWindow( "Packet",true )		
		end		
			
		ZhenYuanGold_ConvertingItem = -1
		ZhenYuanGold_UpdateSelected()
		ZhenYuanGold_UpdateBag()
		
	elseif (event == "PNEUMA_SWITCHGOLD_CONFIRM_OK") then
		ZhenYuanGold_OK_Confirm = 1
	elseif event == "ADJEST_UI_POS" then
		ZhenYuanGold_ResetPos();
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ZhenYuanGold_ResetPos();
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		this:CareObject(objCared, 0, "ZhenYuanGold");
		g_ObjCared = -1;
	elseif event == "OBJECT_CARED_EVENT" then
		if not this:IsVisible() then
			return
		end
		if tonumber(arg0) ~= ZhenYuanGold_CaredObjId then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if ( arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE ) or arg1=="destroy" then
			this:Hide()
		end
	elseif event == "PNEUMA_DRAG_TO_SWITCHGOLD" then	
		if tonumber(arg0) == -1 or ZhenYuanGold_TestDrag( tonumber(arg0) ) == 1 then
			ZhenYuanGold_ConvertingItem = tonumber(arg0)
		end
		ZhenYuanGold_UpdateSelected()
		ZhenYuanGold_UpdateBag()
	--与真元界面互斥
	elseif (event=="TOGGLE_PNEUMA_UI") or (event=="UI_COMMAND" and tonumber(arg0) == 80800799) then
		this:Hide()
	elseif event == "OPEN_WINDOW" and arg0 == "ZhenYuan" then
		this:Hide()
	end

end

function ZhenYuanGold_ItemBtnClicked(x,y)
	local nIndexPos = ZhenYuanGold_Bag+(x-1)*4+y-1
	if ZhenYuanGold_TestDrag( nIndexPos ) == 1 then
		ZhenYuanGold_ConvertingItem = nIndexPos
	end
	ZhenYuanGold_UpdateSelected()
	ZhenYuanGold_UpdateBag()
end

function ZhenYuanGold_TestDrag( nIndexPos )	
	local theAction = Pneuma:EnumPneumaItem("pneuma",  nIndexPos )
	local addtype 	= Pneuma:GetPneumaProperty( nIndexPos, 3 )
	local quality   = Pneuma:GetPneumaProperty( nIndexPos, 2 )
		
	if theAction:GetID() ~= 0 and addtype ~= -1 then
		--必须是橙色真元
		if quality ~= nil and quality ~= 5 then
			PushDebugMessage( "#{CYZJ_150212_13}" )
			return 0
		end
		
		--if ZhenYuanGold_TestLock( nIndexPos ) == 1 then
		--	PushDebugMessage( "#{CYZJ_150212_14}" )
		--	return 0
		--end
	else
		return 0
	end
	return 1
end

function ZhenYuanGold_TestLock( nPosIndex )
	local theAction,bLocked,_,nElapsedTime  = Pneuma:EnumPneumaItem( "pneuma", nPosIndex )
	if(theAction:GetID() == 0 ) then
		return 0
	end
	local unlocktime = Pneuma:GetPneumaItemProperty( nPosIndex, 8 )
	if unlocktime==nil then
		return 0
	end

	if unlocktime <= 0 then
		return 0
	elseif unlocktime > 1 and 259200>nElapsedTime then--正在解锁中
		return 1
	elseif unlocktime >1 and 259200<=nElapsedTime then--解锁完成，即未加锁
		return 0
	else
		return 1
	end
	return 0
end

function ZhenYuanGold_UpdateDrag( nIndexPos )

	if nIndexPos == -1 then
		ZhenYuanGold_LeftFrame_Item:SetActionItem(-1)
		ZhenYuanGold_RightFrame_Item:SetActionItem(-1)	
	else
		--待转换
		local theAction = Pneuma:SetPneumaBeforeSwitchGold( nIndexPos )
		if theAction and theAction:GetID() ~= 0 then
			ZhenYuanGold_LeftFrame_Item:SetActionItem(theAction:GetID())
		end
		--转换后
		theAction = Pneuma:SetPneumaAfterSwitchGold( nIndexPos )
		if theAction then
			ZhenYuanGold_RightFrame_Item:SetActionItem(theAction:GetID())
		end
	end
		
	ZhenYuanGold_OK_Confirm = 0;	
end

function ZhenYuanGold_UpdateSelected()

	ZhenYuanGold_UpdateDrag( ZhenYuanGold_ConvertingItem )

	local isempty = 1
	if ZhenYuanGold_ConvertingItem ~= -1 then
		local label1,label12,label3,label4,label5,label6,label7,label8 = Pneuma:GetPneumaSwitchGoldProperty( ZhenYuanGold_ConvertingItem )
		if label1 then
			isempty = 0
			ZhenYuanGold_SelectedItemName = label1;
			ZhenYuanGold_LeftFrame_Name:SetText( label1 )
			ZhenYuanGold_LeftFrame_Level:SetText( ScriptGlobal_Format("#{CYZJ_150212_08}", tostring(label12) ) )
			ZhenYuanGold_LeftFrame_Desc:SetText( ScriptGlobal_Format("#{CYZJ_150212_09}", label3 ) )
			ZhenYuanGold_LeftFrame_Next:SetText( ScriptGlobal_Format("#{CYZJ_150212_10}", label4 ) )
			
			ZhenYuanGold_RightFrame_Name:SetText( label5 )
			ZhenYuanGold_RightFrame_Level:SetText( ScriptGlobal_Format("#{CYZJ_150212_08}", tostring(label6) ) )
			ZhenYuanGold_RightFrame_Desc:SetText( ScriptGlobal_Format("#{CYZJ_150212_09}", label7 ) )
			ZhenYuanGold_RightFrame_Next:SetText( ScriptGlobal_Format("#{CYZJ_150212_10}", label8 ) )

		end
	end

	if isempty == 1 then
		ZhenYuanGold_SelectedItemName = "";
		ZhenYuanGold_LeftFrame_Name:SetText( "" )
		ZhenYuanGold_LeftFrame_Level:SetText( ScriptGlobal_Format("#{CYZJ_150212_08}","  ") )
		ZhenYuanGold_LeftFrame_Desc:SetText( ScriptGlobal_Format("#{CYZJ_150212_09}","  ") )
		ZhenYuanGold_LeftFrame_Next:SetText( ScriptGlobal_Format("#{CYZJ_150212_10}","  ") )
		
		ZhenYuanGold_RightFrame_Name:SetText( "" )
		ZhenYuanGold_RightFrame_Level:SetText( ScriptGlobal_Format("#{CYZJ_150212_08}","  ") )
		ZhenYuanGold_RightFrame_Desc:SetText( ScriptGlobal_Format("#{CYZJ_150212_09}","  ") )
		ZhenYuanGold_RightFrame_Next:SetText( ScriptGlobal_Format("#{CYZJ_150212_10}","  ") )
		
	end

end

function ZhenYuanGold_UpdateBag()

	for i=1, ZhenYuanGold_Size do
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", ZhenYuanGold_Bag+i-1)
		if theAction:GetID() ~= 0 then
			ZhenYuanGold_BagItems[i]:SetActionItem(theAction:GetID())
			if ZhenYuanGold_ConvertingItem == (ZhenYuanGold_Bag+i-1) then
				ZhenYuanGold_BagItems[i]:Disable()
			else
				ZhenYuanGold_BagItems[i]:Enable()
			end
		else
			ZhenYuanGold_BagItems[i]:SetActionItem(-1)
		end
	end
end

--确定调用
function ZhenYuanGold_OnOk()
	
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{CYZJ_150212_15}")
		return
	end
	
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	
	local theAction = Pneuma:EnumPneumaItem("pneuma",  ZhenYuanGold_ConvertingItem )
	local addtype 	= Pneuma:GetPneumaProperty( ZhenYuanGold_ConvertingItem, 3 )
	local quality   = Pneuma:GetPneumaProperty( ZhenYuanGold_ConvertingItem, 2 )
		
	if theAction:GetID() == 0 or addtype == -1 then
		PushDebugMessage( "#{CYZJ_150212_16}" )
		return
	end
	
	--是否橙色真元
	local quality   = Pneuma:GetPneumaProperty( ZhenYuanGold_ConvertingItem, 2 )
	if quality ~= nil and quality ~= 5 then
		PushDebugMessage( "#{CYZJ_150212_17}" )
		return
	end	
		
	if ZhenYuanGold_OK_Confirm == 0 then
		local strType = "真元"
		if addtype > ZhenYuanGold_AbsAttrMask then
			strType = "魂元"
		end
		PushEvent("PNEUMA_SWITCHGOLD_CONFIRM", ZhenYuanGold_SelectedItemName, strType );
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnZhenYuanGoldConfirm")
			Set_XSCRIPT_ScriptID(889957)
			Set_XSCRIPT_Parameter(0,ZhenYuanGold_ConvertingItem)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		
		ZhenYuanGold_OK_Confirm = 0;
		
		--ZhenYuanGold_ConvertingItem = -1
		--ZhenYuanGold_UpdateSelected()
		--ZhenYuanGold_UpdateBag()
	end
	
end

function ZhenYuanGold_OnCancel()
	this:Hide()
end

function ZhenYuanGold_OnCancelSwitchGold()
	ZhenYuanGold_ConvertingItem = -1
	ZhenYuanGold_UpdateSelected()
	ZhenYuanGold_UpdateBag()
end

function ZhenYuanGold_ResetPos()
	ZhenYuanGold_Frame:SetProperty("UnifiedPosition", g_UnifiedPosition);
end
