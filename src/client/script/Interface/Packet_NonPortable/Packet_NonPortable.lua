--**************************
--临时背包
--**************************
--格子及其编号
local g_Packet_NonPortable_GRID_BUTTONS_NUM = 20;
local g_Packet_NonPortable_GRID_BUTTONS = {};
local g_Packet_NonPortable_TAB_BUTTONS_NUM = 5
local g_Packet_NonPortable_TAB_BUTTONS = {};
local g_Packet_NonPortable_Frame_UnifiedPosition
local g_Packet_NonPortable_Now_Open = 0
local g_Packet_NonPortable_bControlsInit = 0
local g_Packet_NonPortable_objCared = -1

function Packet_NonPortable_PreLoad()
	this:RegisterEvent("OPEN_WORLDITEMSTORE", true)
	this:RegisterEvent("UPDATE_WORLDITEMSTORE",false)
	this:RegisterEvent("UPDATE_WORLDITEMSTORE_LOCK",false)

	this:RegisterEvent("OBJECT_CARED_EVENT",false)

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 开始整理和结束整理
	this:RegisterEvent("BEGIN_PACKUP_WORLDITEMSTORE",false)
	this:RegisterEvent("END_PACKUP_WORLDITEMSTORE",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function Packet_NonPortable_OnLoad()
	g_Packet_NonPortable_TAB_BUTTONS[1] = Packet_NonPortable_CheckButton_1
	g_Packet_NonPortable_TAB_BUTTONS[2] = Packet_NonPortable_CheckButton_2
	g_Packet_NonPortable_TAB_BUTTONS[3] = Packet_NonPortable_CheckButton_3
	g_Packet_NonPortable_TAB_BUTTONS[4] = Packet_NonPortable_CheckButton_4
	g_Packet_NonPortable_TAB_BUTTONS[5] = Packet_NonPortable_CheckButton_5

	g_Packet_NonPortable_Frame_UnifiedPosition=Packet_NonPortable_Frame:GetProperty("UnifiedPosition");
end

function Packet_NonPortable_SetFramePos()
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
			Packet_NonPortable_Frame:SetProperty("UnifiedXPosition", "{0,"..(PacketXPos-440).."}");
			Packet_NonPortable_Frame:SetProperty("UnifiedYPosition", "{0,"..(PacketYPos+69).."}");--69=524-455
		elseif xmax-(PacketXPos+208)>dist then--临时背包放右侧
			Packet_NonPortable_Frame:SetProperty("UnifiedXPosition", "{0,"..(PacketXPos+208).."}");
			Packet_NonPortable_Frame:SetProperty("UnifiedYPosition", "{0,"..(PacketYPos+69).."}");
		else
			--默认位置
			Packet_NonPortable_Frame_On_ResetPos()
		end
	else
		--Packet 宽度261 高度464 x位置-261 y位置-580
		--TemPacket 宽度450 高度353 x位置-711 y位置-530
		local dist=450
		if PacketXPos>dist then--临时背包放左侧
			Packet_NonPortable_Frame:SetProperty("UnifiedXPosition", "{0,"..(PacketXPos-450).."}");
			Packet_NonPortable_Frame:SetProperty("UnifiedYPosition", "{0,"..(PacketYPos+50).."}");--50=580-530
		elseif xmax-(PacketXPos+261)>dist then--临时背包放右侧
			Packet_NonPortable_Frame:SetProperty("UnifiedXPosition", "{0,"..(PacketXPos+261).."}");
			Packet_NonPortable_Frame:SetProperty("UnifiedYPosition", "{0,"..(PacketYPos+50).."}");
		else
			--默认位置
			Packet_NonPortable_Frame_On_ResetPos()
		end
	end
	
	
end
function Packet_NonPortable_OnEvent(event)
	if ( event == "OPEN_WORLDITEMSTORE" ) then
		if(IsWindowShow("Packet_NonPortable")) then
			--this:Show()
			Packet_NonPortable_Update()
		else
			Packet_NonPortable_SetFramePos()
			Packet_NonPortable_InitSubControl()
			CloseWindow("Exchange", true)
			this:Show()

			g_Packet_NonPortable_objCared = Bank:GetWorldItemStoreNpcId()
			this:CareObject( g_Packet_NonPortable_objCared, 1, "Packet_NonPortable" )

			Packet_NonPortable_Update()
			Packet_NonPortable_ActionsList:Flash()
			OpenWindow("Packet")
		end
	elseif ( event == "UPDATE_WORLDITEMSTORE") then
		Packet_NonPortable_Update()
	elseif ( event == "UPDATE_WORLDITEMSTORE_LOCK") then
		Packet_NonPortable_Update()
	elseif (event == "OBJECT_CARED_EVENT") then
		if tonumber(arg0) ~= g_Packet_NonPortable_objCared then
			return
		end

		if arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy" then
			this:CareObject( g_Packet_NonPortable_objCared, 0, "Packet_NonPortable" )

			this:Hide()
		end
	end

	if (event == "ADJEST_UI_POS" ) then
		Packet_NonPortable_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Packet_NonPortable_Frame_On_ResetPos()
	--Disable“整理”
	elseif ( event == "BEGIN_PACKUP_WORLDITEMSTORE" )   then
		Packet_NonPortable_CleanButton:Disable()
	--Enable“整理”
	elseif ( event == "END_PACKUP_WORLDITEMSTORE" )	    then
		Packet_NonPortable_CleanButton:Enable()
	elseif(event == "HIDE_ON_SCENE_TRANSED" ) then
		this:CareObject( g_Packet_NonPortable_objCared, 0, "Packet_NonPortable" )

		this:Hide()
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Packet_NonPortable_Frame_On_ResetPos()
  Packet_NonPortable_Frame:SetProperty("UnifiedPosition", g_Packet_NonPortable_Frame_UnifiedPosition);
end

function Packet_NonPortable_InitSubControl()
	if g_Packet_NonPortable_bControlsInit==1 then
		return
	end
	g_Packet_NonPortable_bControlsInit=1
	for num=1, table.getn(g_Packet_NonPortable_GRID_BUTTONS) do
		g_Packet_NonPortable_GRID_BUTTONS[num]:SetActionItem(-1)
	end
	Packet_NonPortable_ActionsList:CleanAllElement("Packet_NonPortable")
	Packet_NonPortable_ActionsList:SetVertScrollbarHide()
	g_Packet_NonPortable_GRID_BUTTONS = {}
	--初始化20个
	for i=1,g_Packet_NonPortable_GRID_BUTTONS_NUM do
		local ItemBar = Packet_NonPortable_ActionsList:AddItemElement( "ActionButtonItem", "Packet_NonPortable", "", "")
		local ItemAcButton = ItemBar:GetLuaActionButton("Packet_NonPortable")
		ItemAcButton:SetProperty("DragAcceptName", "v"..tostring(i))--字母
		table.insert(g_Packet_NonPortable_GRID_BUTTONS,ItemAcButton);
	end
end

function Packet_NonPortable_CheckButton(idx)
	if idx == g_Packet_NonPortable_Now_Open then
		return
	end

	Bank:GetWorldItemStore(idx-1)
end

function Packet_NonPortable_Update()
	for i=1, g_Packet_NonPortable_GRID_BUTTONS_NUM do
		g_Packet_NonPortable_GRID_BUTTONS[i]:SetActionItem(-1);
		g_Packet_NonPortable_GRID_BUTTONS[i]:Enable();		
	end

	local tabnum = Bank:GetWorldItemStoreCnt()
	g_Packet_NonPortable_Now_Open = Bank:GetWorldItemStoreOpenIdx()+1
	for i = 1, g_Packet_NonPortable_TAB_BUTTONS_NUM do
		if i <= tabnum then
			g_Packet_NonPortable_TAB_BUTTONS[i]:Enable()
			if i == g_Packet_NonPortable_Now_Open then
				g_Packet_NonPortable_TAB_BUTTONS[i]:SetCheck(1)
			else
				g_Packet_NonPortable_TAB_BUTTONS[i]:SetCheck(0)
			end
		else
			g_Packet_NonPortable_TAB_BUTTONS[i]:Disable()
		end
	end

	local Lock_Flag = 0
	for i=1, g_Packet_NonPortable_GRID_BUTTONS_NUM  do
		local theAction, bLocked = Bank:EnumWorldItemStore(i-1);

		if theAction:GetID() ~= 0 then
			g_Packet_NonPortable_GRID_BUTTONS[i]:SetActionItem(theAction:GetID());
			if(bLocked == true) then
				g_Packet_NonPortable_GRID_BUTTONS[i]:Disable();
				Lock_Flag = 1
			else
				g_Packet_NonPortable_GRID_BUTTONS[i]:Enable();
			end
		else
			g_Packet_NonPortable_GRID_BUTTONS[i]:SetActionItem(-1);
		end
	end

	if Lock_Flag == 0 then
		Packet_NonPortable_CleanButton:Enable()
	else
		Packet_NonPortable_CleanButton:Disable()
	end
end

function Packet_NonPortable_EventElementButton1Click()

end
function Packet_NonPortable_EventElementMouseRClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if nIndex>=0 and g_Packet_NonPortable_GRID_BUTTONS[nIndex+1]~=nil then
		g_Packet_NonPortable_GRID_BUTTONS[nIndex+1]:DoAction()
	end
end

function Packet_NonPortable_OnHiden()
	this:CareObject( g_Packet_NonPortable_objCared, 0, "Packet_NonPortable" )

	this:Hide()
end

function Packet_NonPortable_CloseFunction()
	this:CareObject( g_Packet_NonPortable_objCared, 0, "Packet_NonPortable" )

	this:Hide()
end

function Packet_NonPortable_CleanButtonClk()
	Bank:WorldItemStorePackUp()
end

