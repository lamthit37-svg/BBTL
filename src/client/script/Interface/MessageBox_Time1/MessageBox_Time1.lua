

local g_MessageBox_Time1_FrameInfo = -1;
local g_MessageBox_Time1_UnifiedPosition;

local MessageBox_Time1_FrameInfoList = {
	JIHESHAO_USE_CONFIRM = 1;	-- 群侠诏令
}

local Server_Script_ID = "";
local Server_Return_1 = 0;
local Server_Return_2 = 0;
local Server_Return_3 = 0;

local strMessageString = "";		--对话框字符
local strMessageData   = 0;			--对话框类型，用于提示什么得对话框
local strMessageArgs = 0;			--按钮参数
local strMessageType = "Normal";	--按钮风格
local strMessageArgs_2 = 0			--按钮参数2

--由于upvalue的限制，以后的变量请都共用此变量，设置之前MessageBox_Time1_ClearVar一次
local g_MessageBox_Time1_FrameVar = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}

--===============================================
-- OnLoad()
--===============================================
function MessageBox_Time1_PreLoad()

	this:RegisterEvent("UI_COMMAND",true);

	this:RegisterEvent( "ADJEST_UI_POS", true );
	this:RegisterEvent( "VIEW_RESOLUTION_CHANGED", true );
	this:RegisterEvent( "HIDE_ON_SCENE_TRANSED", true );
	this:RegisterEvent( "PLAYER_LEAVE_WORLD", true );

end

--===============================================
-- OnLoad()
--===============================================
function MessageBox_Time1_OnLoad()

	g_MessageBox_Time1_UnifiedPosition = MessageBox_Time1_Frame:GetProperty("UnifiedPosition");
  
end

--===============================================
-- OnEvent()
--===============================================
function MessageBox_Time1_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
		if g_MessageBox_Time1_FrameInfo == MessageBox_Time1_FrameInfoList.JIHESHAO_USE_CONFIRM then
			if this:IsVisible() then
				this:Hide()
			end
		end

		return 0
	end
	
	if ( event == "PLAYER_LEAVE_WORLD" ) then
		if g_MessageBox_Time1_FrameInfo == MessageBox_Time1_FrameInfoList.JIHESHAO_USE_CONFIRM then
			this:Hide();
		end

		return 0
	end
	
	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		MessageBox_Time1_Frame_On_ResetPos()
		return 0
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MessageBox_Time1_Frame_On_ResetPos()
		return 0
	end
	
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 99962801 then
			-- 群侠诏令			
			g_MessageBox_Time1_FrameVar[1] = Get_XParam_INT(0);
			g_MessageBox_Time1_FrameVar[2] = Get_XParam_INT(1);
			
			MessageBox_Time1_DragTitle:SetText( "#{SFDJ_240117_53}" );	-- 设置题目
			
			local str = Get_XParam_STR(0);
			MessageBox_Time1_Text:SetText( str );	-- 设置内容
			
			MessageBox_Time1_CancelLastOp( MessageBox_Time1_FrameInfoList.JIHESHAO_USE_CONFIRM );
			g_MessageBox_Time1_FrameInfo = MessageBox_Time1_FrameInfoList.JIHESHAO_USE_CONFIRM
			
			MessageBox_Time1_UpdateFrame()
			DataPool:SetCanUseHotKey(0)
		end
	end
	
	return 1
end

--===============================================
-- UpdateFrame
--===============================================
function MessageBox_Time1_UpdateFrame()
	
	MessageBox_Time1_OK_Button:Enable()
	MessageBox_Time1_OK_Button:Show()
	MessageBox_Time1_OK_Button:SetText("#{SFDJ_240117_90}")
	
	MessageBox_Time1_Cancel_Button:Enable()
	MessageBox_Time1_Cancel_Button:Show()
	MessageBox_Time1_Cancel_Button:SetText("#{SFDJ_240117_96}")

	MessageBox_Time1_UpdateRect();
			
	this:Show();
	
end

function MessageBox_Time1_UpdateRect()

	local nWidth, nHeight = MessageBox_Time1_Text:GetWindowSize();
	local nTitleHeight = 36;
	local nBottomHeight = 75;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	MessageBox_Time1_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
	
end

--===============================================
-- 点击确定（IDOK）
--===============================================
function MessageBox_Time1_OK_Clicked()

	if (MessageBox_Time1_FrameInfoList.JIHESHAO_USE_CONFIRM == g_MessageBox_Time1_FrameInfo) then  
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ActivateFromClient")
			Set_XSCRIPT_ScriptID(999628)
			Set_XSCRIPT_Parameter(0, g_MessageBox_Time1_FrameVar[1])
			Set_XSCRIPT_Parameter(1, g_MessageBox_Time1_FrameVar[2])
			Set_XSCRIPT_Parameter(2, 0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
		
	this:Hide();
end

--===============================================
-- 放弃摆摊(IDCONCEL)
--===============================================
function MessageBox_Time1_Cancel_Clicked( bClick )

	if (MessageBox_Time1_FrameInfoList.JIHESHAO_USE_CONFIRM == g_MessageBox_Time1_FrameInfo) then  
		
	end
	
	if( 1 == bClick ) then
		
    end
		
	this:Hide();

end

function MessageBox_Time1_OnHidden()

	DataPool:SetCanUseHotKey(1)
	MessageBox_Time1_ClearVar()
	
end

function MessageBox_Time1_StopWatch_TimeOut()

	MessageBox_Time1_OnHidden()
	this:Hide();
	
end

function MessageBox_Time1_Help()

	Helper:GotoHelper("*MessageBox_Self");
	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MessageBox_Time1_Frame_On_ResetPos()

	MessageBox_Time1_Frame:SetProperty("UnifiedPosition", g_MessageBox_Time1_UnifiedPosition);
  
end

function MessageBox_Time1_CancelLastOp( str )

	if(this:IsVisible() and str ~= g_MessageBox_Time1_FrameInfo) then
		MessageBox_Time1_Cancel_Clicked(0);
	end
	
end

function MessageBox_Time1_ClearVar()

	for i = 1,8 do
		g_MessageBox_Time1_FrameVar[i] = 0
	end
	
end





