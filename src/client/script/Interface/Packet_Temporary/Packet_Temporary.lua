--**************************
--临时背包
--**************************
--格子及其编号
local GRID_BUTTONS_NUM = 120;
local GRID_BUTTONS = {};
local g_Packet_Temporary_Frame_UnifiedPosition
local g_bControlsInit = 0

function Packet_Temporary_PreLoad()
	this:RegisterEvent("OPEN_TEMBANK", true)
	this:RegisterEvent("UPDATE_TEMBANK",false)
	this:RegisterEvent("UPDATE_TEMBANK_LOCK",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 开始整理和结束整理
	this:RegisterEvent("BEGIN_PACKUP_TEMBANK",false)
	this:RegisterEvent("END_PACKUP_TEMBANK",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Packet_Temporary_OnLoad()
	g_Packet_Temporary_Frame_UnifiedPosition=Packet_Temporary_Frame:GetProperty("UnifiedPosition");
end

function Packet_Temporary_SetFramePos()
	local PacketUnionXPos = Variable:GetVariable("PacketUnionXPos");
	local PacketUnionYPos = Variable:GetVariable("PacketUnionYPos");
	if(PacketUnionXPos == nil or PacketUnionYPos ==nil) then
		return
	end

	local xi = string.find(PacketUnionXPos,"{")
	local xj = string.find(PacketUnionXPos,",")
	local xk = string.find(PacketUnionXPos,"}")
	local yi = string.find(PacketUnionYPos,"{")
	local yj = string.find(PacketUnionYPos,",")
	local yk = string.find(PacketUnionYPos,"}")
	if xi==nil or xj==nil or xk==nil or yi==nil or yj==nil or yk==nil then return	end;

	local xscale = string.sub(PacketUnionXPos,xi+1,xj-1)
	local xpos = string.sub(PacketUnionXPos,xj+1,xk-1)
	local yscale = string.sub(PacketUnionYPos,yi+1,yj-1)
	local ypos = string.sub(PacketUnionYPos,yj+1,yk-1)
	if xscale==nil or xpos==nil or yscale==nil or ypos==nil then return end;

--	local curResolution = Variable:GetVariable( "View_Resoution" );
	local xmax, ymax = GetCurClientSize()
	local PacketXPos=xscale*xmax + xpos	--绝对坐标
	local PacketYPos=yscale*ymax + ypos	--绝对坐

	if 1 == SystemSetup:IsClassic() then
		--Packet 宽度208 高度418 x位置-208 y位置-524
		--TemPacket 宽度370 高度300 x位置 y位置-455
		local dist=370
		if PacketXPos>dist then--临时背包放左侧
			Packet_Temporary_Frame:SetProperty("UnifiedXPosition", "{0,"..(PacketXPos-440).."}");
			Packet_Temporary_Frame:SetProperty("UnifiedYPosition", "{0,"..(PacketYPos+69).."}");--69=524-455
		elseif xmax-(PacketXPos+208)>dist then--临时背包放右侧
			Packet_Temporary_Frame:SetProperty("UnifiedXPosition", "{0,"..(PacketXPos+208).."}");
			Packet_Temporary_Frame:SetProperty("UnifiedYPosition", "{0,"..(PacketYPos+69).."}");
		else
			--默认位置
			Packet_Temporary_Frame_On_ResetPos()
		end
	else
		--Packet 宽度261 高度464 x位置-261 y位置-580
		--TemPacket 宽度450 高度353 x位置-711 y位置-530
		local dist=450
		if PacketXPos>dist then--临时背包放左侧
			Packet_Temporary_Frame:SetProperty("UnifiedXPosition", "{0,"..(PacketXPos-450).."}");
			Packet_Temporary_Frame:SetProperty("UnifiedYPosition", "{0,"..(PacketYPos+50).."}");--50=580-530
		elseif xmax-(PacketXPos+261)>dist then--临时背包放右侧
			Packet_Temporary_Frame:SetProperty("UnifiedXPosition", "{0,"..(PacketXPos+261).."}");
			Packet_Temporary_Frame:SetProperty("UnifiedYPosition", "{0,"..(PacketYPos+50).."}");
		else
			--默认位置
			Packet_Temporary_Frame_On_ResetPos()
		end
	end
	
	
end
function Packet_Temporary_OnEvent(event)
	if ( event == "OPEN_TEMBANK" ) then
		if(IsWindowShow("Packet_Temporary")) then
			Packet_Temporary_Update()
		else
			Packet_Temporary_SetFramePos()
			Packet_Temporary_InitSubControl()
			CloseWindow("Exchange", true)
			this:Show()
			Packet_Temporary_Update()
			Packet_Temporary_ActionsList:Flash()
		end
	elseif ( event == "UPDATE_TEMBANK") then
		Packet_Temporary_Update()
	elseif ( event == "UPDATE_TEMBANK_LOCK") then
		Packet_Temporary_Update()
	end
	if (event == "ADJEST_UI_POS" ) then
		Packet_Temporary_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Packet_Temporary_Frame_On_ResetPos()
	--Disable“整理”
	elseif ( event == "BEGIN_PACKUP_TEMBANK" )   then
		Packet_Temporary_CleanButton:Disable()
	--Enable“整理”
	elseif ( event == "END_PACKUP_TEMBANK" )	    then
		Packet_Temporary_CleanButton:Enable()
	elseif(event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Packet_Temporary_Frame_On_ResetPos()
  Packet_Temporary_Frame:SetProperty("UnifiedPosition", g_Packet_Temporary_Frame_UnifiedPosition);
end

function Packet_Temporary_InitSubControl()
	if g_bControlsInit==1 then
		return
	end
	g_bControlsInit=1
	for num=1, table.getn(GRID_BUTTONS) do
		GRID_BUTTONS[num]:SetActionItem(-1)
	end
	Packet_Temporary_ActionsList:CleanAllElement("Packet_Temporary")
	GRID_BUTTONS = {}
	--初始化120个
	for i=1,GRID_BUTTONS_NUM do
		local ItemBar = Packet_Temporary_ActionsList:AddItemElement( "ActionButtonItem", "Packet_Temporary", "", "")
		local ItemAcButton = ItemBar:GetLuaActionButton("Packet_Temporary")
		ItemAcButton:SetProperty("DragAcceptName", "p"..tostring(i))--字母
		table.insert(GRID_BUTTONS,ItemAcButton);
	end
end

function Packet_Temporary_Update()

	for i=1, GRID_BUTTONS_NUM do
		GRID_BUTTONS[i]:SetActionItem(-1);
		GRID_BUTTONS[i]:Enable();		
	end
	local Lock_Flag = 0
	for i=1, GRID_BUTTONS_NUM  do
		local theAction, bLocked = Bank:EnumTemItem(i-1);

		if theAction:GetID() ~= 0 then
			GRID_BUTTONS[i]:SetActionItem(theAction:GetID());
			if(bLocked == true) then
				GRID_BUTTONS[i]:Disable();
				Lock_Flag = 1
			else
				GRID_BUTTONS[i]:Enable();
			end
		else
			GRID_BUTTONS[i]:SetActionItem(-1);
		end
	end
	if Lock_Flag == 0 then
		Packet_Temporary_CleanButton:Enable()
	else
		Packet_Temporary_CleanButton:Disable()
	end

	-- 特写 鬼市内容显示特殊tips
	Packet_Temporary_UpdateTipsText()
end

function Packet_Temporary_EventElementButton1Click()

end
function Packet_Temporary_EventElementMouseRClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if nIndex>=0 and GRID_BUTTONS[nIndex+1]~=nil then
		GRID_BUTTONS[nIndex+1]:DoAction()
	end
end

function Packet_Temporary_OnHiden()
	PushEvent("CLOSE_TEMBANK")
end
function Packet_Temporary_CloseFunction()
	this:Hide()
end
function Packet_Temporary_CleanButtonClk()
	Bank:TemBankPackUp()
end

function Packet_Temporary_CleanAllItem()
	local itemCount = Bank:GetTemBankItemNum()

	if itemCount == 0 then
		PushDebugMessage("#{SSCK_180821_21}")
	else
		PushEvent("DROP_ALL_ITEM_IN_TEMBANK")
	end
end

function Packet_Temporary_MoveAllItemToPacket()
	local itemCount = Bank:GetTemBankItemNum()

	if itemCount == 0 then
		PushDebugMessage("#{SSCK_180821_32}")
	else
		Bank:MoveAllTemBankItemToPacket()
	end
end

--================================================
-- 特写 为了打开鬼市交易行显示新的TipText
--================================================
function Packet_Temporary_UpdateTipsText()
	Packet_Temporary_TipsText:SetText("#{SSCK_180821_03}")
end

function Packet_Temporary_HelpFunction()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "Packet_TemporaryHelp" )
		Set_XSCRIPT_ScriptID( 76 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end
