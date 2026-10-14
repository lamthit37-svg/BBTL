--*********************
--真元主界面
--*********************

local ZhenYuanConvert_AbsAttrMask = 50

local ZhenYuanConvert_BagItems = {}

--真元包的位置
local ZhenYuanConvert_Bag	=	36
local ZhenYuanConvert_Size	=	24

local ZhenYuanConvert_SelectItem 		= -1
local ZhenYuanConvert_ConvertingItem 	= -1

local ZhenYuanConvert_CaredObjId = -1

local ZhenYuanConvert_CostTable = {
	[1] = 10,
	[2] = 20,
	[3] = 50,
	[4] = 100,
	[5] = 200,
	[6]	= 200,--数值待定
}

function ZhenYuanConvert_PreLoad()
	this:RegisterEvent("PNEUMAITEM_CHANGED")
	this:RegisterEvent("PNEUMALIST_CHANGED")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("PNEUMA_DRAG_TO_CONVERT")
	this:RegisterEvent("PNEUMA_EXPCHIP_CHANGED")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_WINDOW")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	
	this:RegisterEvent("TOGGLE_PNEUMA_UI")
	
	
end

function ZhenYuanConvert_OnLoad()
	
	for line=1,6 do
		for row=1,4 do
			ZhenYuanConvert_BagItems[(line-1)*4+row] = _G[string.format("ZhenYuanConvert_Space_Line%d_Row%d_button",line,row)]
		end
	end

end

function ZhenYuanConvert_OnEvent( event )
	if event == "PNEUMAITEM_CHANGED" or event=="PNEUMALIST_CHANGED" then
		if this:IsVisible() then
			ZhenYuanConvert_UpdateBag()
			ZhenYuanConvert_UpdateSelected()
		end
	elseif event == "PNEUMA_EXPCHIP_CHANGED" and this:IsVisible() then
		ZhenYuanConvert_tm_0005_Confraternity02_2:SetText( tostring( Pneuma:GetPneumaExp() ) )
	elseif event == "UI_COMMAND" and tonumber(arg0) == 890893 then
		if not this:IsVisible() then
			this:Show()
		end
		if( Get_XParam_INT_Count() < 2 ) then
			return
		end
		
		local servid = Get_XParam_INT(1)
		ZhenYuanConvert_CaredObjId = DataPool : GetNPCIDByServerID(servid)
		if ZhenYuanConvert_CaredObjId == -1 then
			return
		end
		
		CloseWindow( "Packet",true )
		
		this:CareObject( ZhenYuanConvert_CaredObjId, 1, "ZhenYuanConvert" )
		
		ZhenYuanConvert_UpdateType()
		ZhenYuanConvert_UpdateSelected()
		ZhenYuanConvert_UpdateBag()
		
	elseif event == "OBJECT_CARED_EVENT" then
		if not this:IsVisible() then
			return
		end
		if tonumber(arg0) ~= ZhenYuanConvert_CaredObjId then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if ( arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE ) or arg1=="destroy" then
			this:Hide()
		end
	elseif event == "PNEUMA_DRAG_TO_CONVERT" then	
		if tonumber(arg0) == -1 or ZhenYuanConvert_TestDrag( tonumber(arg0) ) == 1 then
			ZhenYuanConvert_ConvertingItem = tonumber(arg0)
		end
		ZhenYuanConvert_UpdateSelected()
		ZhenYuanConvert_UpdateBag()
	--与真元界面互斥
	elseif (event=="TOGGLE_PNEUMA_UI") or (event=="UI_COMMAND" and tonumber(arg0) == 80800799) then
		this:Hide()
	elseif event == "OPEN_WINDOW" and arg0 == "ZhenYuan" then
		this:Hide()
	end
end

function ZhenYuanConvert_UpdateBag()
	for i=1, ZhenYuanConvert_Size do
		local theAction,bLocked = Pneuma:EnumPneumaItem("pneuma", ZhenYuanConvert_Bag+i-1)
		if theAction:GetID() ~= 0 then
			ZhenYuanConvert_BagItems[i]:SetActionItem(theAction:GetID())
			if ZhenYuanConvert_ConvertingItem == (ZhenYuanConvert_Bag+i-1) then
				ZhenYuanConvert_BagItems[i]:Disable()
			else
				ZhenYuanConvert_BagItems[i]:Enable()
			end
		else
			ZhenYuanConvert_BagItems[i]:SetActionItem(-1)
		end
	end
end

function ZhenYuanConvert_UpdateSelected()

	ZhenYuanConvert_UpdateDrag( ZhenYuanConvert_ConvertingItem )
	
	local isempty = 1
	if ZhenYuanConvert_ConvertingItem ~= -1 then
		local label1,label12,label3,label4,label5,label6,label7,label8 = Pneuma:GetPneumaConvertProperty( ZhenYuanConvert_ConvertingItem )
		if label1 then
			isempty = 0
			ZhenYuanConvert_Team001_3_4:SetText( label1 )
			ZhenYuanConvert_Team001_3_5:SetText( ScriptGlobal_Format("#{ZYZH_140618_10}", tostring(label12) ) )
			ZhenYuanConvert_Team001_3_6:SetText( ScriptGlobal_Format("#{ZYZH_140618_11}", label3 ) )
			ZhenYuanConvert_Team001_3_7:SetText( ScriptGlobal_Format("#{ZYZH_140618_12}", label4 ) )
			
			ZhenYuanConvert_Team001_5_4:SetText( label5 )
			ZhenYuanConvert_Team001_5_5:SetText( ScriptGlobal_Format("#{ZYZH_140618_10}", tostring(label6) ) )
			ZhenYuanConvert_Team001_5_6:SetText( ScriptGlobal_Format("#{ZYZH_140618_11}", label7 ) )
			ZhenYuanConvert_Team001_5_7:SetText( ScriptGlobal_Format("#{ZYZH_140618_12}", label8 ) )
			
			local quality = Pneuma:GetPneumaProperty( ZhenYuanConvert_ConvertingItem, 2 )
			
			ZhenYuanConvert_tm_0005_Confraternity01_2:SetText( tostring(ZhenYuanConvert_CostTable[quality]) )
		end
	end
		
	if isempty == 1 then
		ZhenYuanConvert_Team001_3_4:SetText( "" )
		ZhenYuanConvert_Team001_3_5:SetText( ScriptGlobal_Format("#{ZYZH_140618_10}","  ") )
		ZhenYuanConvert_Team001_3_6:SetText( ScriptGlobal_Format("#{ZYZH_140618_11}","  ") )
		ZhenYuanConvert_Team001_3_7:SetText( ScriptGlobal_Format("#{ZYZH_140618_12}","  ") )
		
		ZhenYuanConvert_Team001_5_4:SetText( "" )
		ZhenYuanConvert_Team001_5_5:SetText( ScriptGlobal_Format("#{ZYZH_140618_10}","  ") )
		ZhenYuanConvert_Team001_5_6:SetText( ScriptGlobal_Format("#{ZYZH_140618_11}","  ") )
		ZhenYuanConvert_Team001_5_7:SetText( ScriptGlobal_Format("#{ZYZH_140618_12}","  ") )
		
		ZhenYuanConvert_tm_0005_Confraternity01_2:SetText( "" )
	end
end


function ZhenYuanConvert_UpdateType()
	
	ZhenYuanConvert_warfare_DragTitle:SetText( "#{ZYZH_140618_07}" )
	ZhenYuanConvert_Team001_1_1:SetText( "#{ZYZH_140618_09}" )
	ZhenYuanConvert_Team001_3_1:SetText( "#{ZYZH_140618_13}" )
	
	ZhenYuanConvert_tm_0005_Confraternity01_1:SetText( "#{ZYZH_140618_14}" )
	ZhenYuanConvert_tm_0005_Confraternity02_1:SetText( "#{ZYZH_140618_15}" )
	
	ZhenYuanConvert_tm_0005_Confraternity01_2:SetText( "" )
	ZhenYuanConvert_tm_0005_Confraternity02_2:SetText( Pneuma:GetPneumaExp() )
	
	for i = 1, ZhenYuanConvert_Size do
		ZhenYuanConvert_BagItems[i]:SetProperty("DragAcceptName", "B"..tostring(ZhenYuanConvert_Bag+i-1))
	end
	ZhenYuanConvert_tm_0001_Confraternity06:SetProperty("DragAcceptName", "C")
	ZhenYuanConvert_tm_0001_Confraternity06:SetProperty("DraggingEnabled", "True")
	ZhenYuanConvert_ConvertingItem = -1
end

function ZhenYuanConvert_TestDrag( nIndexPos )	
	local theAction = Pneuma:EnumPneumaItem("pneuma",  nIndexPos )
	local addtype 	= Pneuma:GetPneumaProperty( nIndexPos, 3 )
	
	if theAction:GetID() ~= 0 and addtype ~= -1 then
		if ZhenYuanConvert_TestLock( nIndexPos ) == 1 then
			if addtype > ZhenYuanConvert_AbsAttrMask then
				PushDebugMessage( "#{ZYZH_140618_26}" )
			elseif addtype < ZhenYuanConvert_AbsAttrMask then
				PushDebugMessage( "#{ZYZH_140618_17}" )
			end
			return 0
		end
	else
		return 0
	end
	return 1
end

function ZhenYuanConvert_UpdateDrag( nIndexPos )

	if nIndexPos == -1 then
		ZhenYuanConvert_tm_0001_Confraternity06:SetActionItem(-1)
		ZhenYuanConvert_tm_0003_Confraternity06:SetActionItem(-1)	
	else
		--待转换
		local theAction = Pneuma:SetPneumaBeforeConvert( nIndexPos )
		if theAction and theAction:GetID() ~= 0 then
			ZhenYuanConvert_tm_0001_Confraternity06:SetActionItem(theAction:GetID())
		end
		--转换后
		theAction = Pneuma:SetPneumaAfterConvert( nIndexPos )
		if theAction then
			ZhenYuanConvert_tm_0003_Confraternity06:SetActionItem(theAction:GetID())
		end
	end
end

function ZhenYuanConvert_TestConvert()
	if ZhenYuanConvert_ConvertingItem < ZhenYuanConvert_Bag or ZhenYuanConvert_ConvertingItem >= ( ZhenYuanConvert_Bag + ZhenYuanConvert_Size ) then
		return 0
	end
	
	local quality = Pneuma:GetPneumaProperty( ZhenYuanConvert_ConvertingItem, 2 )
	local addtype = Pneuma:GetPneumaProperty( ZhenYuanConvert_ConvertingItem, 3 )
	if quality == -1 or addtype == -1 then
		return 0
	end
	
	if ZhenYuanConvert_CostTable[quality] > tonumber( Pneuma:GetPneumaExp() ) then
		if addtype < ZhenYuanConvert_AbsAttrMask then
			PushDebugMessage( "#{ZYZH_140618_20}" )
		elseif addtype > ZhenYuanConvert_AbsAttrMask then
			PushDebugMessage( "#{ZYZH_140618_29}" )
		end
		return 0
	end	
	return 1
end

function ZhenYuanConvert_OnShow()
	
end

--关闭调用
function ZhenYuanConvert_Close()
	this:Hide()
end

--确定调用
function ZhenYuanConvert_OnOk()
	if ZhenYuanConvert_TestConvert() == 0 then
		return
	end
	
	local addtype = Pneuma:GetPneumaProperty( ZhenYuanConvert_ConvertingItem, 3 )
	local nConvertType = 0
	if addtype == -1 then
		return
	elseif addtype < ZhenYuanConvert_AbsAttrMask then
		nConvertType = 0
	elseif addtype > ZhenYuanConvert_AbsAttrMask then
		nConvertType = 1
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnConvertConfirm")
		Set_XSCRIPT_ScriptID(890893)
		Set_XSCRIPT_Parameter(0,ZhenYuanConvert_ConvertingItem)
		Set_XSCRIPT_Parameter(1,nConvertType)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	
	ZhenYuanConvert_ConvertingItem = -1
	ZhenYuanConvert_UpdateSelected()
	ZhenYuanConvert_UpdateBag()
end

--取消调用
function ZhenYuanConvert_OnCancel()
	this:Hide()
end

function ZhenYuanConvert_OnConvertCancel()
	ZhenYuanConvert_ConvertingItem = -1
	ZhenYuanConvert_UpdateSelected()
	ZhenYuanConvert_UpdateBag()
end

function ZhenYuanConvert_ItemBtnClicked(x,y)
	local nIndexPos = ZhenYuanConvert_Bag+(x-1)*4+y-1
	if ZhenYuanConvert_TestDrag( nIndexPos ) == 1 then
		ZhenYuanConvert_ConvertingItem = nIndexPos
	end
	ZhenYuanConvert_UpdateSelected()
	ZhenYuanConvert_UpdateBag()
end

function ZhenYuanConvert_ItemBtnSubClicked(x,y)

end

function ZhenYuanConvert_TestLock( nPosIndex )
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


