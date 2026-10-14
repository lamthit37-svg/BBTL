local g_FrameInfo
local g_ClickOk
local g_ClickCancel

--切pk场景提示相关
local Server_Script_Function = "";
local Server_Script_ID = "";
local Server_Return = {0,0,0,0,0,0};
local Server_Return_Num = 0;

local PVPFLAG = { ACCEPTDUEL = 205, DuelGUID = "", DuelName = "" }

local FrameInfoList = {
LOGIN_PK_SCENE_CONFIRM = 0;--登陆提示场景类型
ENTER_PK_SCENE_CONFIRM = 1;--进入pk场景提示确认
}

local FrameSize_Original = 0
local AcceptBox_Blank_Orignial_Size = 0
local g_AcceptBox_Frame_UnifiedXPosition = 0
local g_AcceptBox_Frame_UnifiedYPosition = 0
--===============================================
-- OnLoad()
--===============================================
function AcceptBox_PreLoad()
    this:RegisterEvent("MSGBOX_ACCEPTDUEL", true);
    this:RegisterEvent("UI_COMMAND", true);
    	-- 游戏窗口尺寸发生了变化
		this:RegisterEvent("ADJEST_UI_POS",false);
    	-- 游戏分辨率发生了变化
		this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
		this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	--切场景
end

--===============================================
-- OnLoad()
--===============================================
function AcceptBox_OnLoad()
	FrameSize_Original = AcceptBox_Frame:GetProperty("AbsoluteSize")
    if 1 == SystemSetup:IsClassic() then
    	AcceptBox_Blank_Orignial_Size = AcceptBox_Blank:GetProperty("UnifiedSize")
    end
	g_AcceptBox_Frame_UnifiedXPosition = AcceptBox_Frame:GetProperty("UnifiedXPosition")
	g_AcceptBox_Frame_UnifiedYPosition = AcceptBox_Frame:GetProperty("UnifiedYPosition")
end

--===============================================
-- OnEvent()
--===============================================
function AcceptBox_OnEvent(event)
	
	-- 游戏分辨率发生了变化
	if (event == "ADJEST_UI_POS" ) then
		AcceptBox_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		AcceptBox_Frame_On_ResetPos()
		--切场景
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		if (g_FrameInfo == FrameInfoList.LOGIN_PK_SCENE_CONFIRM) then
			this:Hide()
		end
	end
	 
	 
	if this:IsVisible() then
		return
	end
	
    g_ClickOk = 0
    g_ClickCancel = 0
    g_FrameInfo = 0
    
	AcceptBox_ResetFrame();

	if ( event == "MSGBOX_ACCEPTDUEL" ) then
			AcceptBox_PageHeader_Name:SetText("#gFF0FA0决斗确认");
	    local Name = tostring( arg0 )
	    local GUID = tostring( arg1 )
	    PVPFLAG.DuelName = Name
	    PVPFLAG.DuelGUID = GUID
	    g_FrameInfo = PVPFLAG.ACCEPTDUEL;	    
	    local MsgText = "#c0000FF"..Name.."#W".."向您提出#cFF0000决斗#W，您是否同意？#r注意：在决斗中死亡将会有惩罚。"
	    AcceptBox_Text:SetText( MsgText )
	    this:Show();		
	end
	
	if event == "UI_COMMAND" then
	local commandIndex = tonumber(arg0)
		if commandIndex == 20100716 then
			if ( Get_XParam_INT_Count() < 1 ) then
				return
			end
			AcceptBox_Frame:SetProperty("AbsoluteSize", "w:265 h:182")
            if 1 == SystemSetup:IsClassic() then
			    AcceptBox_Blank:SetProperty("UnifiedSize", "{{1.000000,-54.000000},{0.000000,20.000000}}")
			else
				AcceptBox_Frame:SetProperty("AbsoluteSize", "w:305 h:196")
            end
			local pvpType = Get_XParam_INT(0)
			local msg = ""
			if pvpType == 2 then--加杀气场景
				msg = "#{QZDZ_100715_01}"
			elseif pvpType == 3 then --不加杀气场景
				msg = "#{QZDZ_100715_02}"
			elseif pvpType == 4 then --属地
				msg = Get_XParam_STR(0)
			end
			local sceneid = GetSceneID()
			if sceneid == 1016 then --XKSZ 侠客山庄场景特写
				msg = "#{XKSZ_250219_80}"
			end
			
			g_FrameInfo = FrameInfoList.LOGIN_PK_SCENE_CONFIRM
			AcceptBox_Text:SetText(msg)
			AcceptBox_OK_Button:Hide()
			AcceptBox_Cancel_Button:SetText("#{INTERFACE_XML_302}")
			this:Show()
		end
		
		if commandIndex == 20100717 then
			AcceptBox_Frame:SetProperty("AbsoluteSize", "w:265 h:192")
			g_FrameInfo = FrameInfoList.ENTER_PK_SCENE_CONFIRM
			Server_Script_Function = Get_XParam_STR(0)
			Server_Script_ID = Get_XParam_INT(0)
			szContent = Get_XParam_STR(1)
			AcceptBox_Text:SetText(szContent)
			Server_Return_Num = Get_XParam_INT_Count() - 1; 
			local i = 0;
			for i =1, Server_Return_Num do
				Server_Return[i] = Get_XParam_INT(i)
			end 
			--跨场景寻路已经处理过弹窗了
			if (IsAcrossSceneMoveto() == 1) then
				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name(Server_Script_Function);
					Set_XSCRIPT_ScriptID(Server_Script_ID);
					local i = 0;
					for i = 1, Server_Return_Num do
						Set_XSCRIPT_Parameter(i - 1,Server_Return[i]);
					end 
					Set_XSCRIPT_ParamCount(Server_Return_Num);
				Send_XSCRIPT();
				return
			end

			this:Show()
		end
		
		if commandIndex == 20141008 then
			AcceptBox_Frame:SetProperty("AbsoluteSize", "w:265 h:192")
			g_FrameInfo = FrameInfoList.ENTER_PK_SCENE_CONFIRM
			szContent = Get_XParam_STR(0)
			AcceptBox_Text:SetText(szContent)
			Server_Return_Num = Get_XParam_INT_Count(); 
			local i = 0;
			for i =1, Server_Return_Num do
				Server_Return[i] = Get_XParam_INT(i-1)
			end 
			
			Server_Script_Function="Transfer"
			Server_Script_ID=890902

			this:Show()
		end

	
	end

end


--===============================================
-- ResetFrame
--===============================================
function AcceptBox_ResetFrame()
	AcceptBox_PageHeader_Name:SetText("")
	AcceptBox_OK_Button:Enable()
	AcceptBox_OK_Button:Show()
	AcceptBox_OK_Button:SetText("#{INTERFACE_XML_557}")
	AcceptBox_Cancel_Button:Enable()
	AcceptBox_Cancel_Button:Show()
	AcceptBox_Cancel_Button:SetText("#{INTERFACE_XML_542}")
	AcceptBox_Frame:SetProperty("AbsoluteSize", FrameSize_Original)
    if 1 == SystemSetup:IsClassic() then
	    AcceptBox_Blank:SetProperty("UnifiedSize", AcceptBox_Blank_Orignial_Size)
    end
end


--===============================================
-- 点击确定（IDOK）
--===============================================
function AcceptBox_OK_Clicked()
    if( PVPFLAG.ACCEPTDUEL == g_FrameInfo ) then
        DuelAccept( tostring( PVPFLAG.DuelName ),tostring( PVPFLAG.DuelGUID ), 1 )
    end
    
    if (FrameInfoList.ENTER_PK_SCENE_CONFIRM == g_FrameInfo) then
    	Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name(Server_Script_Function);
				Set_XSCRIPT_ScriptID(Server_Script_ID);
				local i = 0;
				for i = 1, Server_Return_Num do
					Set_XSCRIPT_Parameter(i - 1,Server_Return[i]);
				end 
				Set_XSCRIPT_ParamCount(Server_Return_Num);
			Send_XSCRIPT();
    end
    
	--[YuanPeiLong, 通天塔]
	if ( TongTianTa == g_FrameInfo ) then
    	Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name(Server_Script_Function);
				Set_XSCRIPT_ScriptID(Server_Script_ID);
				local i = 0;
				for i = 1, Server_Return_Num do
					Set_XSCRIPT_Parameter(i,Server_Return[i]);
				end 
				Set_XSCRIPT_ParamCount(Server_Return_Num);
		Send_XSCRIPT();
	end
	--End	
	
    g_ClickOk = 1
	this:Hide();
end

--===============================================
-- 放弃摆摊(IDCONCEL)
--===============================================
function AcceptBox_Cancel_Clicked(bClick)
    g_ClickCancel = 1
    
	--if( 0 == g_ClickOk ) then
	    if( 1 == bClick ) then
			if( PVPFLAG.ACCEPTDUEL == g_FrameInfo ) then
				DuelAccept( tostring( PVPFLAG.DuelName ), tostring( PVPFLAG.DuelGUID ), 0 )
			end
		end
	--end    
    
	this:Hide();
end

function AcceptBox_OnHide()
    if( 0 == g_ClickCancel ) then
        if( 0 == g_ClickOk ) then
            if( PVPFLAG.ACCEPTDUEL == g_FrameInfo ) then
                DuelAccept( tostring( PVPFLAG.DuelName ), tostring( PVPFLAG.DuelGUID ), 0 )
            end
        end
    end
    
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function AcceptBox_Frame_On_ResetPos()
	AcceptBox_Frame : SetProperty("UnifiedXPosition", g_AcceptBox_Frame_UnifiedXPosition);
	AcceptBox_Frame : SetProperty("UnifiedYPosition", g_AcceptBox_Frame_UnifiedYPosition);
end
