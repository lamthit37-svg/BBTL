
local ErrViewmode = 10;

local nowSettings = {}
local nowSettingsType = 0
local validCheckSetting = {}
--- 保存当前设置
local curViewSetupBackup = {}

 -- 速度优先1、均衡设置2、画质优先3、超高画质4
local defaultSetting = 3 		-- 恢复默认按钮使用
-- 更改此处需要同步修改 CVariableSystem::FitVideoOptionTypeClassic()
local settingSets = { 
		[3] =	{0,2,2,2}, 		--物体动画
		[4] =	{0,1,2,2},  	--人物阴影
		[6] =	{0,2,2,2},  	--角色动画
		[8] =	{0,1,2,2},  	--采样
		[9] =	{0,2,2,2},  	--粒子效果
		[10] =	{2,2,2,2},  	--模型显示
		[11] =	{0,0,0,0},  	--全屏泛光
		-- [14] =	{0,0,1,1},  	--遮挡半透
		[15] =	{0,0,0,0},  	--全屏模式
		[17] =	{0,1,1,1}, 		--模型特效
		[18] =	{0,0,0,1},  	--HDR
	}
local allSettings = {}
local settingByIndex = {}

--===============================================
-- OnLoad()
--===============================================
function ViewSetup_PreLoad()
	this:RegisterEvent("TOGLE_VIEWSETUP",true);

	this:RegisterEvent("TOGLE_INPUTSETUP",false);
	this:RegisterEvent("TOGLE_SYSTEMFRAME",false);
	this:RegisterEvent("TOGLE_SOUNDSETUP",false);
	this:RegisterEvent("TOGLE_GAMESETUP",false);

	this:RegisterEvent("CHANGE_VIEW_SETUP",true);
	this:RegisterEvent("CLOSE_SETUP_WINDOW",false);
	this:RegisterEvent("CHANGE_VIEW_SETUP_QUALITY", true)
end

function ViewSetup_OnLoad()
	allSettings =
	{
		{index = 2, ctrltype = "slider" , docSize = 1, default = 0, ctrl = ViewSetup_Item2_Control 	,str = "fhj"},			--全屏抗锯齿			View_Fanhunjiao
		{index = 3, ctrltype = "slider" , docSize = 2, default = 2, ctrl = ViewSetup_Item3_Control 	,str = "wtdh"},			--物体动画				View_ObjectMove
		{index = 4, ctrltype = "slider" , docSize = 2, default = 2, ctrl = ViewSetup_Item1_Control 	,str = "rwyy"},			--人物阴影				View_HumanLightmap
		{index = 5, ctrltype = "slider" , docSize = 170, default = 50, ctrl = ViewSetup_Item10_Control 	,str = "ksfw"},		--显示模型数 可视范围	View_VisibleRangeLevelNew
		{index = 6, ctrltype = "slider" , docSize = 2, default = 2, ctrl = ViewSetup_Item11_Control 	,str = "dhgxzl"},	--角色动画				View_UpdateQuality
		{index = 8, ctrltype = "slider" , docSize = 2, default = 2, ctrl = ViewSetup_Item7_Control 	,str = "cy"},			--采样					View_TextureFiltering
		{index = 9, ctrltype = "slider" , docSize = 2, default = 2, ctrl = ViewSetup_Item14_Control 	,str = "txdjsz"},	--粒子效果				View_EffectLevel
		{index = 10, ctrltype = "slider" , docSize = 2, default = 2, ctrl = ViewSetup_Item17_Control 	,str = "mxxslj"},	--模型显示				View_ModelShowLogic
		{index = 11, ctrltype = "check" , docSize = 0, default = 0, ctrl = ViewSetup_Item_Check4 		,str = "qpfg"},		--全屏泛光				View_HDRFilter
		{index = 13, ctrltype = "check" , docSize = 0, default = 1, ctrl = ViewSetup_Item_Miwu 		,str = "miwu"},			--显示迷雾				View_EnableFog
		{index = 14, ctrltype = "check" , docSize = 0, default = 0, ctrl = ViewSetup_Item_Bantou 		,str = "zdbt"},		--遮挡半透				View_Transparency
		{index = 15, ctrltype = "check" , docSize = 0, default = 0, ctrl = ViewSetup_Item_Check7 		,str = "qpms"},		--全屏模式				View_FullScreen
		{index = 16, ctrltype = "check" , docSize = 0, default = 1, ctrl = ViewSetup_Item_Check5 		,str = "cztb"},		--垂直同步				View_Aplomb
		{index = 17, ctrltype = "check" , docSize = 0, default = 1, ctrl = ViewSetup_Item_Check16 		,str = "mxtx"},		--模型特效				View_ModelEffect
		{index = 18, ctrltype = "check" , docSize = 0, default = 0, ctrl = ViewSetup_Item_HDR 			,str = "hdr"},		--HDR					View_HDRFilter
		{index = 21, ctrltype = "slider" , docSize = 2, default = 0, ctrl = ViewSetup_TiMo_Control	,str = "lodtm"},		--替模模式 				View_InsteadModel
		-- {index = 22, ctrltype = "check" , docSize = 0, default = 1, ctrl = ViewSetup_Item_Check11		,str = "tksj"}, 	--天空视角 				View_UseSkyCamera
		{index = 23, ctrltype = "check" , docSize = 0, default = 1, ctrl = ViewSetup_Item_shijiao		,str = "sjbc"}, 	--视角保持 				Camera_RestoreView
		{index = 24, ctrltype = "check" , docSize = 0, default = 1, ctrl = ViewSetup_Item_Check_ShijJu	,str = "mrsj"}, 	--经典视距 				View_DefaultCamera
		{index = 25, ctrltype = "check" , docSize = 0, default = 0, ctrl = ViewSetup_Item_MARS			,str = "WaveWater"}, --Mars水-新水 			View_WaveWater
		{index = 26, ctrltype = "check" , docSize = 0, default = 0, ctrl = ViewSetup_Item_Checkfps		,str = "zhenlv"}, 	--高帧率(60帧) 			View_GaoZhenLv
	}
	for i, v in pairs(allSettings) do 
		if settingSets[v.index] then 
			v.default = settingSets[v.index][defaultSetting]
		end
		settingByIndex[v.index] = v;
		if v.ctrl and v.ctrltype == "slider" then 
			local stepSize = "1";
			if v.str == "mxxslj"then 
				stepSize = "2";
			end
			v.ctrl:SetProperty( "DocumentSize",tostring(v.docSize) );
			v.ctrl:SetProperty( "PageSize","0" );
			v.ctrl:SetProperty( "StepSize",stepSize );
		end
	end

	ViewSetup_Item15:ComboBoxAddItem("-当前-", 0);
	ViewSetup_Item15:ComboBoxAddItem("800X600", 1);
	ViewSetup_Item15:ComboBoxAddItem("1024X768", 2);
	ViewSetup_Item15:ComboBoxAddItem("1280X720", 3);
	ViewSetup_Item15:ComboBoxAddItem("1280X1024", 4);
	ViewSetup_Item15:ComboBoxAddItem("1920X1080", 5);

ViewSetup_ResetComboList(1)
end

--===============================================
-- OnEvent()
--===============================================
function ViewSetup_OnEvent(event)

	if ( event == "TOGLE_VIEWSETUP" ) then
		local setupUnionPos = Variable:GetVariable("SetupUnionPos");
		if(setupUnionPos ~= nil) then
			ViewSetup_Frame:SetProperty("UnifiedPosition", setupUnionPos);
		end
        --- 每次打开该界面，都先对当前显示设置进行一下备份
        ViewSetup_Save_Cur_Setup()
		ViewSetup_MenuButtons_Reset()
		this:Show();
		ViewSetup_UpdateFrame()
		--- 设置没有修改任何配置
		ViewSetup_Set_Setup_UnChanged()
		-- 每次打开显示设置 都要判断是否开启录制界面，因为控制不了下拉框按钮 只能控制下拉框的enable
		local isOpenRecorder = IsStartTLBBRecorderByMain()
		if isOpenRecorder >= 0 then
			--PushDebugMessage("开启录制 测试")
			ViewSetup_Item15:Disable();
		else
			--PushDebugMessage("没有开启录制 测试")
			ViewSetup_Item15:Enable();
		end
	elseif event == "TOGLE_SYSTEMFRAME" then
		this:Hide()
	elseif event == "TOGLE_SOUNDSETUP" then
		this:Hide()
	elseif event == "TOGLE_GAMESETUP" then
		this:Hide()
	elseif event == "TOGLE_INPUTSETUP" then
		this:Hide()
	elseif event == "CHANGE_VIEW_SETUP" then
        if ( tonumber(arg0) == 0 ) then
            ViewSetup_YingYong_Clicked()
        else
            ViewSetup_Retrieve_Setup()
        end
    elseif event == "CHANGE_VIEW_SETUP_QUALITY" then
    	ViewSetup_DirectChgQuality(tonumber(arg0))
    elseif event == "CLOSE_SETUP_WINDOW" then
        this:Hide()
	end
end


--===============================================
-- UpdateFrame()
--===============================================
function ViewSetup_UpdateFrame()
	ViewSetup_Item15:SetCurrentSelect(0);
	for i, v in pairs(allSettings) do 
		local temp = SystemSetup:View_GetData( v.str );
		nowSettings[v.index] = temp;
		if v.ctrl ~= nil then 
			if v.ctrltype == "slider" then 
				if v.str == "ksfw" and temp == ErrViewmode then 
					--第一次默认为高
					v.ctrl:SetPosition(2);
				else
					v.ctrl:SetPosition(temp);
				end
				if v.index == 5 then
					local thumbPos = v.ctrl:GetThumbPositionX()
					ViewSetup_SetModleNum(temp + 10, thumbPos)
				end
			elseif v.ctrltype == "check" then 
				v.ctrl:SetCheck(temp);
			end
		end
	end

	ViewSetup_SpecialCamera_Check()
	ViewSetup_Sjbc_ClickEx()
	ViewSetup_GlobalQualityCheck();
end
function ViewSetup_SpecialCamera_Check()
	local special_type = SystemSetup:IsCameraSpecial()
	-- 1：PBR场景 2：新天外场景
	if 1==special_type or 2==special_type then
		ViewSetup_Item12_ShijJu_Text:SetToolTip("#{XSSZ_191130_15}")
	else
		ViewSetup_Item12_ShijJu_Text:SetToolTip("#{SJ_XML_02}")		--经典视距
	end
	if 1==special_type then
		ViewSetup_Item_Miwu_Text:SetToolTip("#{XSSZ_191130_15}")	
		ViewSetup_Item11_Text:SetToolTip("#{XSSZ_191130_15}")		
		ViewSetup_HDR_Text:SetToolTip("#{XSSZ_191130_15}")			
	else
		ViewSetup_Item_Miwu_Text:SetToolTip("#{INTERFACE_XML_1251}")--显示迷雾	
		ViewSetup_Item11_Text:SetToolTip("#{INTERFACE_XML_397}")	--全屏泛光		
		ViewSetup_HDR_Text:SetToolTip("#{XSYH_XML_26}")				--HDR
	end
end

--===============================================
-- ViewSetup_Accept_Clicked()
--===============================================
function ViewSetup_Accept_Clicked()
	ViewSetup_YingYong_Clicked()
	this:Hide();
end

--===============================================
-- SliderChanged
--===============================================
function ViewSetup_SliderChanged(nIndex)
	local tabinfo = settingByIndex[nIndex];
	if not tabinfo then 
		PushDebugMessage( "ViewSetup_SliderChanged allSettings is nil:"..(nIndex or "nil") )
		return
	end
	if tabinfo.ctrltype ~= "slider" then 
		PushDebugMessage( "ViewSetup_SliderChanged ctrltype is not slider:"..(nIndex or "nil") )
		return
	end
	if not tabinfo.ctrl then 
		PushDebugMessage( "ViewSetup_SliderChanged ctrl is nil:"..(nIndex or "nil") )
		return
	end
	local pos = tabinfo.ctrl:GetPosition();
	local thumbPos = tabinfo.ctrl:GetThumbPositionX()
	if pos == nowSettings[nIndex] then return end
	nowSettings[nIndex] = pos;
	ViewSetup_GlobalQualityCheck();
	ViewSetup_Set_Setup_Changed()
	
	if nIndex == 5 then
		ViewSetup_SetModleNum( math.floor(pos + 10), thumbPos )
	end
end

function ViewSetup_SetModleNum(num, thumbPos)
	if num <= 10 or num >= 180 then
		ViewSetup_Item10_Text4:Hide()
	else
		ViewSetup_Item10_Text4:Show()
		ViewSetup_Item10_Text4:SetText(num)
	end
	ViewSetup_Item10_Text4:SetProperty("AbsoluteXPosition", thumbPos)
end

--===============================================
-- Default Setting
--===============================================
function ViewSetup_Default_Clicked()
	for i, v in pairs(allSettings) do 
		SystemSetup:View_SetData( v.str, v.default);
	end

	ViewSetup_UpdateFrame();
    ViewSetup_Set_Setup_Changed()
end

function ViewSetup_GlobalQualityCheck()
	local tmpType = 0
	for i=1 ,4 do
		if tmpType == 0 then
			tmpType = i
		else
			break;
		end
		for nIndex, v in pairs(settingSets) do 
			if v[i] ~= nowSettings[nIndex] then 
				tmpType = 0
				break;
			end
		end
	end

	nowSettingsType = tmpType
	if tmpType == 0 then
		ViewSetup_ResetComboList(0)
		ViewSetup_SelSettings:SetCurrentSelect(4)
	else
		ViewSetup_ResetComboList(1)
		ViewSetup_SelSettings:SetCurrentSelect(tmpType - 1)
	end
end

function ViewSetup_Res_Changed()
	--判断是否开启录制操作界面 这个函数 在第一次开启显示设置 以及 有设置改变的情况 才会执行
	local isOpenRecorder = IsStartTLBBRecorderByMain()
	if isOpenRecorder >= 0 then
		--PushDebugMessage("开启录制 测试")
		ViewSetup_Item15:Disable();
		return
	else
		--PushDebugMessage("没有开启录制 测试")
		ViewSetup_Item15:Enable();
	end
	ViewSetup_Item_Check7:SetCheck(0);

    ViewSetup_Set_Setup_Changed()
end

-- 更新视角保持复选框状态
function ViewSetup_Sjbc_ClickEx()

	-- 若天空视角打开，则视角保持显示
	-- if ViewSetup_Item_Check11:GetCheck() == 1 then
	-- 	ViewSetup_Item_shijiao:Show()
	-- 	ViewSetup_shijiao_Text:Show()
	-- -- 否则不显示视角保持复选框
	-- else
	-- 	ViewSetup_Item_shijiao:Hide()
	-- 	ViewSetup_shijiao_Text:Hide()
	-- end
end

function ViewSetup_DirectChgQuality(nIndex)
	if nowSettingsType == nIndex or nIndex >= 5 or nIndex < 1 then
		return
	end
	nowSettingsType = nIndex
	for i, v in pairs(settingSets) do 
		nowSettings[i] = v[nIndex]
		local tabinfo = settingByIndex[i];
		if tabinfo.ctrl then 
			if tabinfo.ctrltype == "slider" then 
				tabinfo.ctrl:SetPosition(v[nIndex]);
			elseif tabinfo.ctrltype == "check" then 
				tabinfo.ctrl:SetCheck(v[nIndex]);
			end
		end
	end
    ViewSetup_Set_Setup_Changed()
	ViewSetup_YingYong_Clicked()
end
function ViewSetup_SettingsSel()

	local str , nIndex = ViewSetup_SelSettings:GetCurrentSelect()

	if nowSettingsType == nIndex or nIndex == 5 then
		return
	end

	nowSettingsType = nIndex

	for i, v in pairs(settingSets) do 
		nowSettings[i] = v[nIndex]
		local tabinfo = settingByIndex[i];
		if tabinfo.ctrl then 
			if tabinfo.ctrltype == "slider" then 
				tabinfo.ctrl:SetPosition(v[nIndex]);
			elseif tabinfo.ctrltype == "check" then 
				tabinfo.ctrl:SetCheck(v[nIndex]);
			end
		end
	end

	ViewSetup_ResetComboList(1)
	ViewSetup_SelSettings:SetCurrentSelect(nowSettingsType - 1)
    ViewSetup_Set_Setup_Changed()
end

function ViewSetup_ResetComboList(nXX)

	ViewSetup_SelSettings:ResetList()
	ViewSetup_SelSettings:AddTextItem("#{XSYH_XML_7}",	1)			--速度优先
	ViewSetup_SelSettings:AddTextItem("#{XSYH_XML_8}",	2)			--均衡设置	默认配置
	ViewSetup_SelSettings:AddTextItem("#{XSYH_XML_9}",	3)			--画质优先
	ViewSetup_SelSettings:AddTextItem("#{XSYH_XML_10}",	4)			--超高画质

	if nXX == 0 then
		ViewSetup_SelSettings:AddTextItem("#{XSYH_XML_2}",5)			--自定义
	end
end

function ViewSetup_CheckSetting_Clicked(nIndex)
	if nIndex == 15 then 
		--全屏模式
		local temp = ViewSetup_Item_Check7:GetCheck();
		--这里判断是否开启录制操作界面
		local isOpenRecorder = IsStartTLBBRecorderByMain()
		if isOpenRecorder >= 0 then
			--PushDebugMessage("开启录制 测试")
			if temp == 1 then --手动设置全屏模式勾选项 保持和点击之前一致
				ViewSetup_Item_Check7:SetCheck(0);
			else
				ViewSetup_Item_Check7:SetCheck(1);
			end
			return
		end
		if(temp == 1) then
			ViewSetup_Item15:Disable();
		else
			ViewSetup_Item15:Enable();
		end
	elseif nIndex == 22 then 
		-- 天空视角
		ViewSetup_Sjbc_ClickEx()
	elseif nIndex == 11 then 
		-- 全屏泛光
		ViewSetup_Item_HDR:SetCheck(0);
		nowSettings[18] = 0
	elseif nIndex == 18 then 
		-- HDR
		ViewSetup_Item_Check4:SetCheck(0);
		nowSettings[11] = 0
	end
    ViewSetup_Set_Setup_Changed()
    ViewSetup_CheckSetting_ClickedEx( nIndex )
end

function ViewSetup_CheckSetting_ClickedEx(nIndex)
	local tabinfo = settingByIndex[nIndex];
	if not tabinfo then 
		PushDebugMessage( "ViewSetup_Check_Clicked allSettings is nil:"..(nIndex or "nil") )
		return
	end
	if tabinfo.ctrltype ~= "check" then 
		PushDebugMessage( "ViewSetup_Check_Clicked ctrltype is not check:"..(nIndex or "nil") )
		return
	end
	if not tabinfo.ctrl then 
		PushDebugMessage( "ViewSetup_Check_Clicked ctrl is nil:"..(nIndex or "nil") )
		return
	end
	nowSettings[tabinfo.index] = tabinfo.ctrl:GetCheck();
	ViewSetup_GlobalQualityCheck();
end

function ViewSetup_SetUp()
	--打开优化向导界面
	SystemSetup:OpenOptimize();
end

function ViewSetup_SoundSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", ViewSetup_Frame:GetProperty("UnifiedPosition"), 1);

    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 0, 1, "#{XTSZYH_111220_03}" )
    else
        SystemSetup:SoundSetup()
    end
end

function ViewSetup_GameSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", ViewSetup_Frame:GetProperty("UnifiedPosition"), 1);

    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 0, 2, "#{XTSZYH_111220_03}" )
    else
        SystemSetup:GameSetup()
    end
end

function ViewSetup_AcceSetup_Clicked()
	Variable:SetVariable("SetupUnionPos", ViewSetup_Frame:GetProperty("UnifiedPosition"), 1);

    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 0, 3, "#{XTSZYH_111220_03}" )
    else
        SystemSetup:InputSetup()
    end
end

function ViewSetup_MenuButtons_Reset()
	ViewSetup_MenuBox_ViewSetup	:SetCheck(1)
	ViewSetup_MenuBox_SoundSetup:SetCheck(0)
	ViewSetup_MenuBox_GameSetup	:SetCheck(0)
	ViewSetup_MenuBox_AcceSetup	:SetCheck(0)
end

function ViewSetup_UIScale_SliderChanged()
--	local posText = string.format("%0.2f" , ViewSetup_UIScale_Control:GetPosition() + 0.8)
--	ViewSetup_UIScale_Text1:SetText("缩放比例"..posText)
end

function ViewSetup_ViewSetup_Clicked()

end

function ViewSetup_YingYong_Clicked()
    if 0 == SystemSetup:GetIsConfigChanged( ) then
        return
    end

    --- 为什么这句话要放在这里，因为要求“您的设置已经生效”放在“部分设置需要重启”前面
    PushDebugMessage( "#{XTSZYH_111220_10}" )

    local tabResetGame = {
    	{Index = 16, strInfo = "垂直同步需要重启"},-- 垂直同步
	}
   --是否需要重新启动
    for i, v in pairs(tabResetGame) do 
   		local bNeedReset = false;
   		local tabinfo = settingByIndex[v.Index]
   		if tabinfo and tabinfo.ctrl then 
			bNeedReset = tonumber(SystemSetup:View_GetData(tabinfo.str)) ~= (tonumber(tabinfo.ctrl:GetCheck())); 
		end
		if bNeedReset then 
			PushDebugMessage(v.strInfo);
		end
    end

	for i, v in pairs(allSettings) do 
		if v.ctrl ~= nil then 
			if v.ctrltype == "slider" then 
				SystemSetup:View_SetData( v.str,v.ctrl:GetPosition() );
			elseif v.ctrltype == "check" then 
				SystemSetup:View_SetData( v.str,v.ctrl:GetCheck() );
			end
		else
			SystemSetup:View_SetData( v.str,nowSettings[v.index] );
		end
	end

	local bFullScreen = ViewSetup_Item_Check7:GetCheck();

	--当前非全屏
	if (bFullScreen ~= 1) then
		local thisRes, thisResIndex = ViewSetup_Item15:GetCurrentSelect();

		if(thisRes == "800X600") then
			Variable:SetVariable("View_Resoution", "", 0);
			Variable:SetVariable("View_Resoution", "800,600", 0);
		elseif(thisRes == "1024X768") then
			Variable:SetVariable("View_Resoution", "", 0);
			Variable:SetVariable("View_Resoution", "1024,768", 0);
		elseif(thisRes == "1280X720") then
			Variable:SetVariable("View_Resoution", "", 0);
			Variable:SetVariable("View_Resoution", "1280,720", 0);
		elseif(thisRes == "1280X1024") then
			Variable:SetVariable("View_Resoution", "", 0);
			Variable:SetVariable("View_Resoution", "1280,1024", 0);
		elseif(thisRes == "1920X1080") then
			Variable:SetVariable("View_Resoution", "", 0);
			Variable:SetVariable("View_Resoution", "1920,1080", 0);
		end
	end
    ViewSetup_YingYong:Disable()
    SystemSetup:SetIsConfigChanged( 0 )
	SystemSetup:Lua_ViewSetupToFile()
end

--- 保存当前游戏的设置
function ViewSetup_Save_Cur_Setup()
   	for i, v in pairs(allSettings) do 
		curViewSetupBackup[v.str] = SystemSetup:View_GetData(v.str);
	end
	--- 分辨率设置
    local resolution = Variable:GetVariable( "View_Resoution" );
    curViewSetupBackup[ "View_Resoution" ] = resolution;
end

--- 恢复之前的设置
function ViewSetup_Retrieve_Setup()
    for i, v in pairs(allSettings) do 
		SystemSetup:View_SetData(v.str, tonumber(curViewSetupBackup[v.str]));
	end
	--- 恢复分辨率设置
    local curResolution = Variable:GetVariable( "View_Resoution" );
    local bakResolution = curViewSetupBackup[ "View_Resoution" ]
    if curResolution ~= bakResolution and thisResIndex ~= 0 then
        Variable:SetVariable("View_Resoution", "", 0);
        Variable:SetVariable("View_Resoution", bakResolution, 0);
    end
end

function ViewSetup_Set_Setup_UnChanged()
    SystemSetup:SetIsConfigChanged( 0 )
	ViewSetup_YingYong:Disable()
end

function ViewSetup_Set_Setup_Changed()
    SystemSetup:SetIsConfigChanged( 1 )
	ViewSetup_YingYong:Enable()
end

function ViewSetup_Close_Clicked()
    if 1 == SystemSetup:GetIsConfigChanged() then
        PushEvent( "CONFIRM_SAVE_GAME_SETUP", 0, -1, "#{XTSZYH_111220_03}" )
    else
        this:Hide()
    end
end

function ViewSetup_Cancel_Clicked()
    ViewSetup_Close_Clicked()
end

function ViewSetup_OnHidden()
end