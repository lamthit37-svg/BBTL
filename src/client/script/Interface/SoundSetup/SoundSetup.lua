--- 保存当前设置
local curSoundSetupBackup = {}

--===============================================
-- OnLoad()
--===============================================
function SoundSetup_PreLoad()
	this:RegisterEvent("TOGLE_SOUNDSETUP",true);
	
	this:RegisterEvent("TOGLE_VIEWSETUP",false);
	this:RegisterEvent("TOGLE_INPUTSETUP",false);
	this:RegisterEvent("TOGLE_SYSTEMFRAME",false);
	this:RegisterEvent("TOGLE_GAMESETUP",false);
	this:RegisterEvent("TOGLE_CONTROLMODE",false)
    
	this:RegisterEvent("CHANGE_SOUND_SETUP",true);
	this:RegisterEvent("CLOSE_SETUP_WINDOW",false);

	--TiuSong - 唯美版配置
	this:RegisterEvent("TOGLE_VIEWSETUP_WM",false);
	this:RegisterEvent("TOGLE_INPUTSETUP_WM",false)
end

function SoundSetup_OnLoad()
end

--===============================================
-- OnEvent()
--===============================================
function SoundSetup_OnEvent(event)
	
	if ( event == "TOGLE_SOUNDSETUP" ) then
		local setupUnionPos = Variable:GetVariable("SetupUnionPos");
		if(setupUnionPos ~= nil) then
			SoundSetup_Frame:SetProperty("UnifiedPosition", setupUnionPos);
		end
        --- 每次打开该界面，都先对当前显示设置进行一下备份
        SoundSetup_Save_Cur_Setup()

		SoundSetup_MenuButtons_Reset()
		this:Show();
		SoundSetup_UpdateFrame();
        
        --- 设置没有修改任何配置
        SoundSetup_Config_UnChanged()

	elseif(event == "TOGLE_GAMESETUP" ) then
		this:Hide();
	elseif(event == "TOGLE_SYSTEMFRAME" ) then
		this:Hide();
	elseif(event == "TOGLE_VIEWSETUP" ) then
		this:Hide();
	elseif(event == "TOGLE_VIEWSETUP_WM") then
		this:Hide();
	elseif(event == "TOGLE_INPUTSETUP" ) then
		this:Hide();
	elseif(event == "TOGLE_INPUTSETUP_WM") then
		this:Hide();

	elseif(event == "TOGLE_CONTROLMODE") then
		this:Hide()

	elseif(event == "CHANGE_SOUND_SETUP" ) then
        if ( tonumber(arg0) == 0 ) then
            SoundSetup_YingYong_Clicked()
        else
            SoundSetup_Retrieve_Setup()
        end
    elseif event == "CLOSE_SETUP_WINDOW" then
        this:Hide()
	end

end


--===============================================
-- UpdateFrame()
--===============================================
function SoundSetup_UpdateFrame()
	
	local bDisableAllSound = Variable:GetVariable("DisableAllSound") == "1";
	local bEnableBG = Variable:GetVariable("EnableBGSound") == "1";
	local bEnable3D = Variable:GetVariable("Enable3DSound") == "1";
	local bEnableSK = Variable:GetVariable("EnableSKSound") == "1";
	local bEnableUI = Variable:GetVariable("EnableUISound") == "1";
	
	local fVolumeBG = tonumber(Variable:GetVariable("VOLUME_BG"));
	local fVolume3D = tonumber(Variable:GetVariable("VOLUME_3D"));
	local fVolumeSK = tonumber(Variable:GetVariable("VOLUME_SK"));
	local fVolumeUI = tonumber(Variable:GetVariable("VOLUME_UI"));
	if( bDisableAllSound ) then
		SoundSetup_Item1:SetCheck( 1 );
	else
		SoundSetup_Item1:SetCheck( 0 );
	end
	if( bEnableBG ) then
		SoundSetup_Item2:SetCheck( 1 );
	else
		SoundSetup_Item2:SetCheck( 0 );
	end

	if( bEnable3D ) then
		SoundSetup_Item3:SetCheck( 1 );
	else
		SoundSetup_Item3:SetCheck( 0 );
	end

	if( bEnableSK ) then
		SoundSetup_Item4:SetCheck( 1 );
	else
		SoundSetup_Item4:SetCheck( 0 );
	end

	if( bEnableUI ) then
		SoundSetup_Item5:SetCheck( 1 );
	else
		SoundSetup_Item5:SetCheck( 0 );
	end

	SoundSetup_Item2_Control:SetPosition(fVolumeBG);	
	SoundSetup_Item3_Control:SetPosition(fVolume3D);	
	SoundSetup_Item4_Control:SetPosition(fVolumeSK);	
	SoundSetup_Item5_Control:SetPosition(fVolumeUI);	

end

function SoundSetup_UpdateToGame(theControl, varName)
	local bEnable = theControl:GetProperty("Selected")=="True";

	Variable:SetVariable(varName, (bEnable and "1") or "0", 0);
end


--===============================================
-- SoundSetup_Check_Clicked
--===============================================
function SoundSetup_Check_Clicked(nIndex)
	
	if(nIndex == 1)   then
		SoundSetup_Item1:SetCheck( 1 );
		local bEnable = SoundSetup_Item1:GetCheck();
		if(bEnable == 1 )  then
			SoundSetup_Item2:SetCheck( 0 );
			SoundSetup_Item3:SetCheck( 0 );
			SoundSetup_Item4:SetCheck( 0 );
			SoundSetup_Item5:SetCheck( 0 );
		end
		
	else
		SoundSetup_Item1:SetCheck( 0 );
	end
	
    SoundSetup_Set_Setup_Changed()
end

--===============================================
-- 背景
--===============================================
function SoundSetup_BackgroundMusic_Clicked()
end

--===============================================
-- 环境
--===============================================
function SoundSetup_EnvironmentalSound_Clicked()
end


--===============================================
-- 技能
--===============================================
function SoundSetup_SkillsSound_Clicked()
end


--===============================================
-- UI事件
--===============================================
function SoundSetup_ThingSound_Clicked()
end

--===============================================
-- 确定
--===============================================
function SoundSetup_Accept_Clicked()
    SoundSetup_YingYong_Clicked()
	this:Hide();
end

--===============================================
-- 取消
--===============================================
function SoundSetup_Cancel_Clicked()
    SoundSetup_Close_Clicked()
end

--恢复默认选项
function SoundSetup_Default_Clicked()

	Variable:SetVariable("DisableAllSound", "0", 0);
	Variable:SetVariable("EnableBGSound", "1", 0);
	Variable:SetVariable("Enable3DSound", "1", 0);
	Variable:SetVariable("EnableSKSound", "1", 0);
	Variable:SetVariable("EnableUISound", "1", 0);
	
	
	Variable:SetVariable("VOLUME_BG", 1.0, 0);
	Variable:SetVariable("VOLUME_3D", 1.0, 0);
	Variable:SetVariable("VOLUME_SK", 1.0, 0);
	Variable:SetVariable("VOLUME_UI", 1.0, 0);
	
	SoundSetup_UpdateFrame()
    SoundSetup_Set_Setup_Changed()
end

function SoundSetup_ViewSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", SoundSetup_Frame:GetProperty("UnifiedPosition"), 1);

    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 1, 0, "#{XTSZYH_111220_04}" )
    else
        SystemSetup:ViewSetup();
    end

end

function SoundSetup_SoundSetup_Clicked()
	
end

function SoundSetup_GameSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", SoundSetup_Frame:GetProperty("UnifiedPosition"), 1);
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 1, 2, "#{XTSZYH_111220_04}" )
    else
        SystemSetup:GameSetup()
    end
end

function SoundSetup_AcceSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", SoundSetup_Frame:GetProperty("UnifiedPosition"), 1);
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 1, 3, "#{XTSZYH_111220_04}" )
    else
        SystemSetup:InputSetup()
    end
end

function SoundSetup_WASD_Clicked()
	Variable:SetVariable("SetupUnionPos", SoundSetup_Frame:GetProperty("UnifiedPosition"), 1);
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 1, 3, "#{XTSZYH_111220_04}" )
    else
        SystemSetup:ControlModeSetup();
    end
end

function SoundSetup_MenuButtons_Reset()
	SoundSetup_MenuBox_ViewSetup	:SetCheck(0)
	SoundSetup_MenuBox_SoundSetup	:SetCheck(1)
	SoundSetup_MenuBox_GameSetup	:SetCheck(0)
	SoundSetup_MenuBox_AcceSetup	:SetCheck(0)
    if SystemSetup:IsClassic() == 0 then
        SoundSetup_MenuBox_WASD			:SetCheck(0)
    else
		SoundSetup_MenuBox_WASD:Hide()
	end
    SoundSetup_Set_Setup_Changed()
end

--- 
function SoundSetup_YingYong_Clicked()
    if 0 == SystemSetup:GetIsConfigChanged( ) then
        return
    end

    -- 需要保存数据
	SoundSetup_UpdateToGame(SoundSetup_Item1, 	"DisableAllSound");
	SoundSetup_UpdateToGame(SoundSetup_Item2, 	"EnableBGSound");
	SoundSetup_UpdateToGame(SoundSetup_Item3, 	"Enable3DSound");
	SoundSetup_UpdateToGame(SoundSetup_Item4, 	"EnableSKSound");
	SoundSetup_UpdateToGame(SoundSetup_Item5, 	"EnableUISound");
			
	local fVolumeBG = SoundSetup_Item2_Control:GetPosition();
	local fVolume3D = SoundSetup_Item3_Control:GetPosition();
	local fVolumeSK = SoundSetup_Item4_Control:GetPosition();
	local fVolumeUI = SoundSetup_Item5_Control:GetPosition();

	Variable:SetVariable("VOLUME_BG", fVolumeBG, 0);
	Variable:SetVariable("VOLUME_3D", fVolume3D, 0);
	Variable:SetVariable("VOLUME_SK", fVolumeSK, 0);
	Variable:SetVariable("VOLUME_UI", fVolumeUI, 0);

	SoundSetup_YingYong:Disable()
    SystemSetup:SetIsConfigChanged( 0 )
    PushDebugMessage( "#{XTSZYH_111220_10}" )

end

function SoundSetup_Save_Cur_Setup()
    local vDisableAllSound = Variable:GetVariable("DisableAllSound")
	local vEnableBG        = Variable:GetVariable("EnableBGSound")
	local vEnable3D        = Variable:GetVariable("Enable3DSound")
	local vEnableSK        = Variable:GetVariable("EnableSKSound")
	local vEnableUI        = Variable:GetVariable("EnableUISound")
	
	local vVolumeBG        = Variable:GetVariable("VOLUME_BG")
	local vVolume3D        = Variable:GetVariable("VOLUME_3D")
	local vVolumeSK        = Variable:GetVariable("VOLUME_SK")
	local vVolumeUI        = Variable:GetVariable("VOLUME_UI")   

    curSoundSetupBackup[ "DisableAllSound" ] = vDisableAllSound
    curSoundSetupBackup[ "EnableBGSound"   ] = vEnableBG
    curSoundSetupBackup[ "Enable3DSound"   ] = vEnable3D
    curSoundSetupBackup[ "EnableSKSound"   ] = vEnableSK
    curSoundSetupBackup[ "EnableUISound"   ] = vEnableUI

    curSoundSetupBackup[ "VOLUME_BG" ] = vVolumeBG
    curSoundSetupBackup[ "VOLUME_3D" ] = vVolume3D
    curSoundSetupBackup[ "VOLUME_SK" ] = vVolumeSK
    curSoundSetupBackup[ "VOLUME_UI" ] = vVolumeUI
end

function SoundSetup_Retrieve_Setup()
    local vDisableAllSound = curSoundSetupBackup[ "DisableAllSound" ]
    local vEnableBG        = curSoundSetupBackup[ "EnableBGSound"   ]
    local vEnable3D        = curSoundSetupBackup[ "Enable3DSound"   ]
    local vEnableSK        = curSoundSetupBackup[ "EnableSKSound"   ]
    local vEnableUI        = curSoundSetupBackup[ "EnableUISound"   ]
    
    local vVolumeBG        = curSoundSetupBackup[ "VOLUME_BG" ]
    local vVolume3D        = curSoundSetupBackup[ "VOLUME_3D" ]
    local vVolumeSK        = curSoundSetupBackup[ "VOLUME_SK" ]
    local vVolumeUI        = curSoundSetupBackup[ "VOLUME_UI" ]

    Variable:SetVariable("DisableAllSound", vDisableAllSound, 0);
	Variable:SetVariable("EnableBGSound",   vEnableBG,        0);
	Variable:SetVariable("Enable3DSound",   vEnable3D,        0);
	Variable:SetVariable("EnableSKSound",   vEnableSK,        0);
	Variable:SetVariable("EnableUISound",   vEnableUI,        0);
	
	
	Variable:SetVariable("VOLUME_BG", tonumber(vVolumeBG), 0);
	Variable:SetVariable("VOLUME_3D", tonumber(vVolume3D), 0);
	Variable:SetVariable("VOLUME_SK", tonumber(vVolumeSK), 0);
	Variable:SetVariable("VOLUME_UI", tonumber(vVolumeUI), 0);

end

function SoundSetup_Set_Setup_Changed()
    SystemSetup:SetIsConfigChanged( 1 )
	SoundSetup_YingYong:Enable()
end

function SoundSetup_Close_Clicked()

    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 1, -1, "#{XTSZYH_111220_04}" )
    else
        this:Hide()
    end
end

function SoundSetup_Config_UnChanged()
    --- 设置当前没有任何修改
    SystemSetup:SetIsConfigChanged( 0 )
	--- 灰化掉应用按钮
	SoundSetup_YingYong:Disable()
end

--- 这里的sliderIdx是为了以后的扩展，这里不用
function SoundSetup_SliderChanged( sliderIdx )
    SoundSetup_Set_Setup_Changed()
end
