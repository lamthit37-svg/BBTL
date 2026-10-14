--Create By MD
local g_FrameInfo = -1				--当前窗口确认的类型
local g_FrameEvent = -1       --当前使用哪个窗口事件
local g_YIMIN_OBJ_DISTANCE = 3.0
local g_OderYimin_Gain_NPCID = -1
local FrameInfoList = {
	CONFIRM_ODERIMMIGRATION  = 1,				 	 -- 订制移民确认
	CONFIRM_ODERIMMIGRATION_SPOUSE  = 2,			 -- 定制移民夫妻 确认
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
function YiMinSP_ReadMe_PreLoad()
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("UI_COMMAND");
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

function YiMinSP_ReadMe_OnLoad()
	YiMinSP_ReadMe_Frame:SetProperty("AlwaysOnTop", "True");
end

function YiMinSP_ReadMeUpdateRect()
--	local nWidth, nHeight = YiMinSP_ReadMe_InfoWindow:GetWindowSize();
--	local nTitleHeight = 23;
--	local nBottomHeight = 25;
--	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
--	YiMinSP_ReadMe_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end

-- OnEvent
function YiMinSP_ReadMe_OnEvent(event)
	--******************************
	--建议：处理不同的event，请在读出参数后，将逻辑自己写在一个函数内
	--这样可以尽可能的使OnEvent函数能简洁一些不至于像MessageBox界面一样
	--注意：一定要先将参数读出来再传给自己写的函数
	--参考：event == "YBMARKET_UP_ITEM_COMFIRM"
	--*******************************
	if event == "SCENE_TRANSED" then
		if this:IsVisible()  then
			this:Hide()
		end
		return
	end

	if ( event == "OBJECT_CARED_EVENT" and this : IsVisible() ) then
        if( tonumber(arg0) ~= g_OderYimin_Gain_NPCID ) then
			return
		end
       		 --- 如果和NPC的距离大于一定的距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > g_YIMIN_OBJ_DISTANCE or arg1=="destroy") then
            	YiMinSP_ReadMe_Close()
		end

	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 202291302 ) then
		YiMinSP_ReadMe_Clear_Var()		
		local ImmgTime = Get_XParam_STR(0)	;	
		
		------------------------------------------------
		local npcObjID = Get_XParam_INT(0)	;
        	YiMinSP_ReadMe_BeginCareObject( npcObjID )	
		------------------------------------------------
		
		local msg =ScriptGlobal_Format( "#{FWQYM_160622_275}",ImmgTime)
		YiMinSP_ReadMe_Info_text:SetText( msg );	-- 设置内容
		YiMinSP_ReadMeUpdateRect();
		YiMinSP_ReadMe_BtnOK:SetProperty("Visible","False")
		YiMinSP_ReadMe_BtnCancel:SetProperty("Visible","False")
		YiMinSP_ReadMe_BtnQueDing:SetProperty("Visible","True")
		this:Show();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 202291303 ) then
		YiMinSP_ReadMe_Clear_Var()
		
		g_FrameVar[1]  = Get_XParam_INT(0) 
		g_FrameVar[2]  = Get_XParam_INT(1) --selfId
		g_FrameVar[3]  = Get_XParam_INT(2) --selfId
		g_FrameVar[4]  = Get_XParam_INT(3) --nDestWorldID
		
		
		------------------------------------------------
		g_FrameVar[5] = Get_XParam_INT(4)	;--nImmgFlag
		YiMinSP_ReadMe_BeginCareObject( g_FrameVar[5] )	 --targetId
		------------------------------------------------
		
		local targetName = Get_XParam_STR(0);
		local targetServerName = Get_XParam_STR(1)	;		
		local ImmgTime = Get_XParam_STR(2)	;		
			local msg =ScriptGlobal_Format( "#{DZYM_20230302_202}", targetServerName,ImmgTime)
			YiMinSP_ReadMe_DragTitle:SetText("#{DZYM_20230302_201}")
		YiMinSP_ReadMe_Info_text:SetText( msg );	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_ODERIMMIGRATION ;
		YiMinSP_ReadMeUpdateRect();
		DataPool:SetCanUseHotKey(0)
		YiMinSP_ReadMe_BtnOK:SetProperty("Visible","True")
		YiMinSP_ReadMe_BtnCancel:SetProperty("Visible","True")
		YiMinSP_ReadMe_BtnQueDing:SetProperty("Visible","False")
		this:Show();	
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 20230314 ) then
		YiMinSP_ReadMe_Clear_Var()
		
		g_FrameVar[1]  = Get_XParam_INT(0)
		g_FrameVar[2]  = Get_XParam_INT(1) --selfId
		g_FrameVar[3]  = Get_XParam_INT(2) --selfId
		g_FrameVar[4]  = Get_XParam_INT(3) --nDestWorldID
		------------------------------------------------
		g_FrameVar[5] = Get_XParam_INT(4)	; --nImmgFlag
		YiMinSP_ReadMe_EndCareObject( g_FrameVar[5] )	--targetID
		------------------------------------------------
		local targetName = Get_XParam_STR(0);
		local targetServerName = Get_XParam_STR(1)	;		
		local ImmgTime = Get_XParam_STR(2)	;		
		local msg =ScriptGlobal_Format( "#{DZYM_20230302_264}", targetServerName,ImmgTime)
		YiMinSP_ReadMe_Info_text:SetText( msg );	-- 设置内容
		g_FrameInfo = FrameInfoList.CONFIRM_ODERIMMIGRATION_SPOUSE ;
		YiMinSP_ReadMeUpdateRect();
		DataPool:SetCanUseHotKey(0)
		YiMinSP_ReadMe_BtnOK:SetProperty("Visible","True")
		YiMinSP_ReadMe_BtnCancel:SetProperty("Visible","True")
		YiMinSP_ReadMe_BtnQueDing:SetProperty("Visible","False")
		this:Show();
	end

end

-- 按钮1 点击事件
function YiMinSP_ReadMe_Bn1Click()

	if (g_FrameInfo == FrameInfoList.CONFIRM_ODERIMMIGRATION) then
	
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ImmigrationCallBack_After")
		Set_XSCRIPT_ScriptID(807014)
		Set_XSCRIPT_Parameter(0,g_FrameVar[3])
		Set_XSCRIPT_Parameter(1,g_FrameVar[4]) 
		Set_XSCRIPT_Parameter(2,g_FrameVar[5]) 
		Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	elseif (g_FrameInfo == FrameInfoList.CONFIRM_ODERIMMIGRATION_SPOUSE) then
	
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SpouseImmigrationCallBack")
		Set_XSCRIPT_ScriptID(807014)
		Set_XSCRIPT_Parameter(0,g_FrameVar[2])
		Set_XSCRIPT_Parameter(1,g_FrameVar[3])
		Set_XSCRIPT_Parameter(2,1)
		Set_XSCRIPT_Parameter(3,g_FrameVar[5])
		Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()	

	end

	this:Hide()

end
-- 按钮2 点击事件
function YiMinSP_ReadMe_Bn2Click()
	if (g_FrameInfo == FrameInfoList.CONFIRM_ODERIMMIGRATION_SPOUSE) then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SpouseImmigrationCallBack")
		Set_XSCRIPT_ScriptID(807014)
		Set_XSCRIPT_Parameter(0,g_FrameVar[2]) --selfId
		Set_XSCRIPT_Parameter(1,g_FrameVar[3]) --nDestWorldID
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_Parameter(3,g_FrameVar[5])--targetID
		Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()	

	end
	this:Hide();
end
function YiMinSP_ReadMe_OnHiden()
	if(IsWindowShow("AntiJDY")) then    --简单游互斥界面显示时，不激活快捷键 for 69994
	else
		DataPool:SetCanUseHotKey(1);
	end
	YiMinSP_ReadMe_Clear_Var()
end

function YiMinSP_ReadMe_Clear_Var()
	for i = 1,8 do
		g_FrameVar[i] = 0
	end
	g_FrameInfo = -1
end

function YiMinSP_ReadMe_BeginCareObject( careObjID )
    g_OderYimin_Gain_NPCID = DataPool : GetNPCIDByServerID( careObjID )
    if -1 == g_OderYimin_Gain_NPCID then
        return 
    end
    this:CareObject( g_OderYimin_Gain_NPCID, 1, "YiMinSP_ReadMe" )
end
function YiMinSP_ReadMe_EndCareObject( careObjID )
	if g_OderYimin_Gain_NPCID ~= nil and g_OderYimin_Gain_NPCID >= 0 then
        this:CareObject( g_OderYimin_Gain_NPCID, 0, "YiMinSP_ReadMe" )
    end
    g_OderYimin_Gain_NPCID = -1
end
function YiMinSP_ReadMe_Close()

    this:Hide()
end
