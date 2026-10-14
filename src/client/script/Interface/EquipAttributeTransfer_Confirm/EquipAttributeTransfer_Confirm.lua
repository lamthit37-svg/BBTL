local g_FrameInfo = -1				--当前窗口确认的类型
local FrameInfoList = {
	EQUIP_ATTRFUKE_CONFIRM					= 1,			--装备复刻二次确认 
}
--确认框缓存变量，用于点击确定和取消时做处理, 每个变量的意义，根据界面不同各不相同，请使用者用到时自己注释
local g_FrameVar = {
	[1] = 0,
	[2] = 0,
	[3] = 0,
	[4] = 0,
	[5] = 0,
	[6] = 0,
	[7] = 0,
	[8] = 0,
}
local g_Text = {
	[1] = "#{JTFK_1117_31}",
	[2] = "#{JTFK_1117_37}",
}

function EquipAttributeTransfer_Confirm_PreLoad()
	this:RegisterEvent("EQUIP_ATTRFUKE_CONFIRM")
	--切场景事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",true);
end

function EquipAttributeTransfer_Confirm_OnLoad()
	EquipAttributeTransfer_Confirm_Frame_sub:SetProperty("AlwaysOnTop", "True");
end

function EquipAttributeTransfer_Confirm_UpdateRect()
	local nWidth, nHeight = EquipAttributeTransfer_Confirm_InfoWindow:GetWindowSize();
	local nTitleHeight = 23;
	local nBottomHeight = 25;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	EquipAttributeTransfer_Confirm_Frame_sub:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end

-- OnEvent
function EquipAttributeTransfer_Confirm_OnEvent(event)
				
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		if this:IsVisible() then
			this:Hide()	
		end
	end			
	
	if ( event == "EQUIP_ATTRFUKE_CONFIRM") then
		EquipAttributeTransfer_Confirm_Clear_Var()
		g_FrameVar[1] = tonumber( arg0 )
		g_FrameVar[2] = tostring( arg1 )
		g_FrameVar[3] = tostring( arg2 )
		g_FrameVar[4] = tostring( arg3 )
		EquipAttributeTransfer_Confirm_Confirm()
	end

end

-- 按钮1 点击事件
function EquipAttributeTransfer_Confirm_Bn1Click()
	if (g_FrameInfo == FrameInfoList.EQUIP_ATTRFUKE_CONFIRM) then
		PushEvent("EQUIP_ATTRFUKE_SENDMSG")
	end
	this:Hide()
end
-- 按钮2 点击事件
function EquipAttributeTransfer_Confirm_Bn2Click()
	this:Hide();
end

function EquipAttributeTransfer_Confirm_Frame_OnHiden()
	
	EquipAttributeTransfer_Confirm_Clear_Var()
end

function EquipAttributeTransfer_Confirm_CleanUp()
	EquipAttributeTransfer_Confirm_Frame_sub:SetProperty( "UnifiedPosition", "{{0.500000,-173.000000},{0.500000,-118.000000}}" )
	EquipAttributeTransfer_Confirm_Button2:Hide();
	EquipAttributeTransfer_Confirm_Button1:Hide();
end

function EquipAttributeTransfer_Confirm_Clear_Var()
	for i = 1,8 do
		g_FrameVar[i] = 0
	end
	g_FrameInfo = -1
end

function EquipAttributeTransfer_Confirm_Confirm()
	g_FrameInfo = FrameInfoList.EQUIP_ATTRFUKE_CONFIRM 
	local strInfo 
	--if g_FrameVar[1] == 1 then
		strInfo = ScriptGlobal_Format(g_Text[g_FrameVar[1]], g_FrameVar[2], g_FrameVar[3], g_FrameVar[4])
	--else
		--strInfo = ScriptGlobal_Format("#{JTFK_1117_37}", g_FrameVar[2], g_FrameVar[3], g_FrameVar[4])
	--end
	
	EquipAttributeTransfer_Confirm_InfoWindow:SetText( strInfo );

	EquipAttributeTransfer_Confirm_Button1:Show()
	EquipAttributeTransfer_Confirm_Button1:SetText("");  --确定
	EquipAttributeTransfer_Confirm_Button1:Disable();

	EquipAttributeTransfer_Confirm_Watch:Show();
	EquipAttributeTransfer_Confirm_Watch:SetProperty("Timer", "5");

	EquipAttributeTransfer_Confirm_Button2:Show()
	EquipAttributeTransfer_Confirm_Button2:SetText("#{JTFK_1117_33}");  --取消

	EquipAttributeTransfer_Confirm_UpdateRect();
	this:Show();
end

function EquipAttributeTransfer_Confirm_TimeReach()
	--时间到了
	EquipAttributeTransfer_Confirm_Button1:Enable();
	EquipAttributeTransfer_Confirm_Button1:SetText("#{JTFK_1117_32}");  --确定
	EquipAttributeTransfer_Confirm_Watch:Hide();
end

function EquipAttributeTransfer_Confirm_Frame_OnHiden()
	this:Hide();
end