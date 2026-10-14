--***********************************************************************************************************************************************
-- 复活界面		
--注意，此界面为复活专用，请不要用来做其他用途
--***********************************************************************************************************************************************
local Current_status = 0;
local Current_Quest = -1;
-------------------------------------------------------------------------------------------------------------------------------------------------
--
-- 此处定义需要保存数据的局部变量
--
local g_KillerGUID = "";
local g_KillerName = "";
local g_KillerZoneWorldID = -1;
--------------------------------------------------------
-- 当前对话框的操作类型
local g_Event;

local Event_Relive = 0;
local Event_Callof = 1;

local g_Relive_Frame_UnifiedXPosition = 0
local g_Relive_Frame_UnifiedYPosition = 0
--攻城战专用
local g_Relive_isgongcheng = 0
local g_Relive_gongchengtype = 0
local g_Relive_scencename =""


--获取聊天输入框的位置大小，死亡后模拟点击聊天输入框
local g_Chat_EditboxX= 0
local g_Chat_EditboxY = 0
local g_Chat_EditboxWidth = 0
local g_Chat_EditboxHeight = 0

local g_WuLinZhiDianResId_1 = 749
local g_WuLinZhiDianResId_2 = 750
local g_WuLinZhiDianResId_3 = 752
local g_IsShowFHQ = 0
local g_FHQID = 0
local g_FHQtime = 0
local g_IsShowCZPVP = 0
local g_CZPVPID = 0
local g_CZPVPtime = 0
local g_CZPVPRetime1 = 5
local g_CZPVPRetime2 = 5000
local g_relive_tjc_res = 878
local g_relive_Newsahxing_res = 1057
--***********************************************************************************************************************************************
--
-- OnLoad
--
--************************************************************************************************************************************************
function Relive_PreLoad()

	this:RegisterEvent("RELIVE_SHOW",true);
	this:RegisterEvent("RELIVE_HIDE",false);
	this:RegisterEvent("RELIVE_REFESH_TIME",fasle);
	this:RegisterEvent("UI_COMMAND");

	--拉人技能
	this:RegisterEvent("OPEN_CALLOF_PLAYER",true);
	this:RegisterEvent("RELIVE_MODIFY",true);
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("SHOW_ADDFOE_BUTTON",false);
	this:RegisterEvent("INVALID_ADDFOEBUTTON",false);
	this:RegisterEvent("REQ_CHAT_EDITBOX_POS_SIZE",true);
	this:RegisterEvent("ZDZD_AUTOGHOST",false)
end

function Relive_OnLoad()
	g_Relive_Frame_UnifiedXPosition = Relive_Frame:GetProperty("UnifiedXPosition")
	g_Relive_Frame_UnifiedYPosition = Relive_Frame:GetProperty("UnifiedYPosition")
end


--***********************************************************************************************************************************************
--
-- 事件响应函数
--
--
--************************************************************************************************************************************************
function Relive_OnEvent(event)

	if ( event == "RELIVE_SHOW" ) then
		if (arg6 ~= nil) then
			g_KillerZoneWorldID = tonumber(arg6);
		else
			g_KillerZoneWorldID = -1
		end

		if tostring(arg4) ~= "" then--如果杀手名不为空
			g_KillerName = tostring(arg4)
			local killername = tostring(arg4)
			if g_KillerZoneWorldID ~= -1 and g_KillerZoneWorldID ~= DataPool:GetSelfZoneWorldID() then
				local servername = DataPool:GetServerName(g_KillerZoneWorldID)
				if servername ~= nil and servername ~= "" then
					if  Lua_GetAnonymousSceneInfo() == 0 then
						killername = killername.."@"..servername
					end	
				end
			end
			if Relive_IsNewshaxingScene() == 1 then
				Relive_Text1:SetText( "#{SWTS_20101029_02}"..tostring(arg3).."#{SWTS_20101029_13}" );
			else
				Relive_Text1:SetText( "#{SWTS_20101029_02}"..tostring(arg3).."#{SWTS_20101029_03}"..killername.."#{SWTS_20101029_04}" );
			end
		else
			Relive_Text1:SetText( "#{SWTS_20101029_02}"..tostring(arg3).."#{SWTS_20101029_13}" );
		end
		Relive_Text2:ClearAllElement();
		if tostring(arg7) ~= "" then--如果有死亡惩罚
			local szDesc = "#{SWTS_20101029_05}"
			if tostring(arg7) ~= "0" then--如果有经验惩罚
				szDesc = szDesc.."#{SWTS_20101029_06}"..tostring(arg7).."#{SWTS_20101029_17}"
			end
			if tostring(arg8) ~= "0" then--如果有金钱惩罚
				szDesc = szDesc.."#{SWTS_20101029_07}#{_MONEY"..tostring(arg8).."}。"
			end
			if tostring(arg9) ~= "" then--物品惩罚
				szDesc = szDesc..tostring(arg9)
			end
			if Relive_IsFYPVEScene() == 1 then
				Relive_Text2:AddTextElement(szDesc.."#r".."#{FYPVE_260108_96}")
			else
				Relive_Text2:AddTextElement(szDesc)
			end
		else
			if Relive_IsFYPVEScene() == 1 then
				Relive_Text2:AddTextElement("#{SWTS_20101029_14}".."#r".."#{FYPVE_260108_96}")
			else
				Relive_Text2:AddTextElement("#{SWTS_20101029_14}")
			end
		end

		if Relive_IsTJCPVPSceneResID() == 1 then
			Relive_Text2:AddTextElement("#{TJZF_230525_08}")
		end

		Relive_Time_Text : SetProperty("Timer",tostring(arg2));
		if (arg5 ~= nil) then
			g_KillerGUID = arg5;
		end


		--有复活按钮
		if ( arg0 == "1" ) then
			Relive_Fool_Button:Enable();
		--无复活按钮
		else
			Relive_Fool_Button:Disable();
		end
		--有复活按钮
		if ( arg1 == "1" ) then
			Relive_Relive_Button:Enable();
		--无复活按钮
		else
			Relive_Relive_Button:Disable();
		end
		--Added	by	lx	2011-5-15
		--添加仇敌按钮
		if ( arg0 == "2") then
			Relive_AddFoe_Button:Disable();
			Relive_AddFoe_Button:Show();
			Relive_Fool_Button:Hide();
		else
			Relive_AddFoe_Button:Disable();
			Relive_AddFoe_Button:Hide();
			Relive_Fool_Button:Show();
		end
		--lx	add	end

		Relive_Help:Disable();
		Relive_Close:Disable();
		Current_status = 0;
		Relive_Fool_Button:SetText("#{INTERFACE_XML_766}");--新手原地复活
		Relive_Release_Button:SetText("出窍");
		
		local nCurResId = GetSceneID()
		if g_WuLinZhiDianResId_1 == nCurResId or g_WuLinZhiDianResId_2 == nCurResId or g_WuLinZhiDianResId_3 == nCurResId then
			Relive_Release_Button:Disable()
		else
			Relive_Release_Button:Enable()
		end
		
		Relive_Relive_Button:SetText("复活");

		Relive_Text:SetText("#gFF0FA0复活");
		--复活旗
		Relive_FHQ:Hide()
		Relive_Frame2:Hide()
		if g_IsShowFHQ == 1 then
			Relive_Frame2:Show()
			Relive_FHQ:Show()
			Relive_FHQ_Btn:SetProperty("Disabled", "True");
			Relive_FHQ_Time:SetProperty("Timer",tostring(10));
			g_FHQtime = OSAPI:GetTickCount();
			Relive_FHQ_Text:SetText("#{FFZQ_220803_19}")
		end

		--PVP复活旗
		Relive_CZPVP:Hide()
		Relive_Frame3:Hide()
		if g_IsShowCZPVP == 1 then
			Relive_Frame3:Show()
			Relive_CZPVP:Show()
			Relive_CZPVP_Btn:SetProperty("Disabled", "True");
			Relive_CZPVP_Time:SetProperty("Timer",tostring(g_CZPVPRetime1));
			g_CZPVPtime = OSAPI:GetTickCount();
			Relive_CZPVP_Text:SetText("#{ZTPVP_260515_218}")
		end

		this:Show();
		g_Event = Event_Relive;

		if g_Relive_isgongcheng == 1 then --城战复活有cd特写

			if g_Relive_gongchengtype == 0 then
				local str = "#{BZTX_220705_336}"..g_Relive_scencename.."#{BZTX_220705_327}"
				Relive_Time_Text3:SetText(str)
				Relive_Time_Text4:SetProperty("Timer",tostring(30))
				Relive_Time_Text5:SetText("#{BZTX_220705_328}")
				Relive_Time_Text3: Show();
				Relive_Time_Text4: Show();
				Relive_Time_Text5: Show();
				Relive_Time_Text6: Hide();
				Relive_Time_Text7: Hide();
				Relive_Time_Text4_1:Hide()
				Relive_Rebirth_Button:Show()
			elseif (g_Relive_gongchengtype == 1) then
				-- 非城战时间 在自己帮会占的城内死亡
				Relive_Time_Text3:SetText("#{BZTX_220705_379}")
				--Relive_Time_Text4:SetProperty("Timer",tostring(30))
				--Relive_Time_Text5:SetText("#{BZTX_220705_328}")
				Relive_Time_Text3: Show();
				Relive_Time_Text4: Hide();
				Relive_Time_Text5: Hide();
				Relive_Time_Text6: Hide();
				Relive_Time_Text7: Hide();
				Relive_Time_Text4_1:Hide()
				Relive_Rebirth_Button:Show()
			end


			g_Relive_isgongcheng = 0

		else
			Relive_Time_Text3: Hide();
			Relive_Time_Text4: Hide();
			Relive_Time_Text4_1:Hide()
			Relive_Time_Text5: Hide();
			Relive_Time_Text6: Hide();
			Relive_Time_Text7: Hide();
			Relive_Rebirth_Button:Hide()
		end
		
	

		
		PushEvent("ASK_CHAT_EDITBOX_POS_SIZE")

	elseif ( event == "RELIVE_HIDE" ) then
		Current_status = 0;
		--Added	by	lx	2011-5-15
		Relive_AddFoe_Button:Disable();
		Relive_AddFoe_Button:Hide();
		--lx	add	end
		g_IsShowFHQ = 0
		Relive_FHQ:Hide()
		Relive_Frame2:Hide()

		g_IsShowCZPVP = 0
		Relive_CZPVP:Hide()
		Relive_Frame3:Hide()
		
		this:Hide();

	elseif ( event == "RELIVE_REFESH_TIME" ) then
	
		Relive_Time_Text : SetProperty("Timer",tostring(arg0));
		--Added	by	lx	2011-5-16
		Relive_AddFoe_Button:Disable();
		Relive_AddFoe_Button:Hide();
		--lx	add	end
		Current_status = 0;
	
		
	elseif ( event == "OPEN_CALLOF_PLAYER" )  then
		
		Relive_Text:SetText(arg0 .. "拉你过去，是否同意啊？");
			
		Relive_Release_Button:SetText("确定");
		Relive_Relive_Button:SetText("取消");

		Relive_Text:SetText("#gFF0FA0拉人");

		Relive_Time_Text:SetProperty("Timer",tostring( arg3 ));
		--Added	by	lx	2011-5-15
		Relive_AddFoe_Button:Disable();
		Relive_AddFoe_Button:Hide();
		Relive_FHQ:Hide()
		Relive_Frame2:Hide()
		Relive_CZPVP:Hide()
		Relive_Frame3:Hide()
		--lx	add	end
		this:Show()
		g_Event = Event_Callof;
	elseif( event == "RELIVE_MODIFY") then
		--T战场有自己的复活界面
		if ( Lua_IsInTXiongBa() == 1 ) then		
			return
		end
		local curSceneID = GetSceneID(); --zypvp有自己界面
		if curSceneID == 868 then
			return 
		end
		if curSceneID == 937 then
			return
		end
		-- 侠客Boss
		if curSceneID == 1018 then
			return
		end
		if TLCJ:IsInTLCJScene_Team() == 1 then
			return
		end
		--有复活按钮
		if ( arg0 == "1" ) then
			Relive_Fool_Button:Enable();
		--无复活按钮
		else
			Relive_Fool_Button:Disable();
		end
		--有复活按钮
		if ( arg1 == "1" ) then
			Relive_Relive_Button:Enable();
		--无复活按钮
		else
			Relive_Relive_Button:Disable();
		end
		
		--Added	by	lx	2011-5-15
		--添加仇敌按钮
		if ( arg0 == "2") then
			Relive_AddFoe_Button:Disable();
			Relive_AddFoe_Button:Show();
			Relive_Fool_Button:Hide();
		else
			Relive_AddFoe_Button:Disable();
			Relive_AddFoe_Button:Hide();
			Relive_Fool_Button:Show();
		end
		--lx	add	end

		Relive_Help:Disable();
		Relive_Close:Disable();
		Current_status = 0;
		Relive_Fool_Button:SetText("#{INTERFACE_XML_766}");--新手原地复活
		Relive_Release_Button:SetText("出窍");
		
		local nCurResId = GetSceneID()
		if g_WuLinZhiDianResId_1 == nCurResId or g_WuLinZhiDianResId_2 == nCurResId or g_WuLinZhiDianResId_3 == nCurResId then
			Relive_Release_Button:Disable()
		else
			Relive_Release_Button:Enable()
		end
		
		Relive_Relive_Button:SetText("复活");

		Relive_Text:SetText("#gFF0FA0复活");

		Relive_FHQ:Hide()
		Relive_Frame2:Hide()

		Relive_CZPVP:Hide()
		Relive_Frame3:Hide()

		this:Show();
		g_Event = Event_Relive;
	elseif (event == "ADJEST_UI_POS" ) then
		Relive_Frame_On_ResetPos();
		PushEvent("ASK_CHAT_EDITBOX_POS_SIZE")
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Relive_Frame_On_ResetPos();
		PushEvent("ASK_CHAT_EDITBOX_POS_SIZE")

	elseif	(event == "SHOW_ADDFOE_BUTTON") then
		Relive_AddFoe_Button:Enable();
	elseif (event == "INVALID_ADDFOEBUTTON") then
		Relive_AddFoe_Button:Disable();
	elseif ( event == "REQ_CHAT_EDITBOX_POS_SIZE" ) then
		g_Chat_EditboxX= tonumber(arg0)
		g_Chat_EditboxY = tonumber(arg1)
		g_Chat_EditboxWidth = tonumber(arg2)
		g_Chat_EditboxHeight = tonumber(arg3)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99820202 ) then
		g_IsShowFHQ = 1
		g_FHQID = Get_XParam_INT(0)
		if this:IsVisible() then
			Relive_Frame2:Show()
			Relive_FHQ:Show()
			Relive_FHQ_Btn:SetProperty("Disabled", "True");
			Relive_FHQ_Time:SetProperty("Timer",tostring(10));
			g_FHQtime = OSAPI:GetTickCount();
			Relive_FHQ_Text:SetText("#{FFZQ_220803_19}")
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 90002901 ) then
		g_IsShowCZPVP = 1
		g_CZPVPID = Get_XParam_INT(0)
		if this:IsVisible() then
			Relive_Frame3:Show()
			Relive_CZPVP:Show()
			Relive_CZPVP_Btn:SetProperty("Disabled", "True");
			Relive_CZPVP_Time:SetProperty("Timer",tostring(g_CZPVPRetime1));
			g_CZPVPtime = OSAPI:GetTickCount();
			Relive_CZPVP_Text:SetText("#{ZTPVP_260515_218}")
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20111116 then
		g_Relive_isgongcheng = 1
		g_Relive_gongchengtype = Get_XParam_INT(0)
		g_Relive_scencename = Get_XParam_STR(0)
	
	elseif (event == "ZDZD_AUTOGHOST") then
		Relive_Out_Ghost()
	end
end



--***********************************************************************************************************************************************
--
-- 点击出窍按钮
--
--
--************************************************************************************************************************************************
function Relive_Out_Ghost()

	if( g_Event == Event_Callof )  then
		Friend:CallOf("ok");
		this:Hide();
		Relive_FHQ_Clear()
		Relive_CZPVP_Clear()
	elseif(g_Event == Event_Relive)then
		if(Current_status == 1) then
			if(Current_Quest > -1) then
				QuestFrameMissionAbnegate(Current_Quest);
			end
			Relive_FHQ_Clear()
			Relive_CZPVP_Clear()
			this:Hide();
			return;
		else
			if Relive_IsTJCPVPSceneResID() == 1 then
				if DataPool:LuaFnIsCanReliveInTJCPVP() < 1 then
					return
				end
			end
			Player:SendReliveMessage_OutGhost();
		end
		
	end

end


--***********************************************************************************************************************************************
--
-- 点击复活按钮
--
--
--***********************************************************************************************************************************************
function Relive_Relive()

	if( g_Event == Event_Relive )  then
		if(Current_status == 1) then
			Relive_FHQ_Clear()
			Relive_CZPVP_Clear()
			this:Hide();
			return;
		else
			Player:SendReliveMessage_Relive();
		end;
		 
	elseif(g_Event == Event_Callof)then 
		Relive_FHQ_Clear()
		Relive_CZPVP_Clear()
		this:Hide();
	
	end

end

--复活旗复活
function Relive_FHQRelive()

	local curTime = OSAPI:GetTickCount();
	if curTime - g_FHQtime < 10000 then
		local resttime = (10000 - (curTime - g_FHQtime))/1000
		PushDebugMessage(ScriptGlobal_Format("#{FFZQ_220803_24}", math.ceil(resttime)))
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("HerosNeverDie")
		Set_XSCRIPT_ScriptID(998202)
		Set_XSCRIPT_Parameter(0, g_FHQID)
		Set_XSCRIPT_ParamCount(1)			
	Send_XSCRIPT()	

end

--复活旗复活
function Relive_CZPVPRelive()

	local curTime = OSAPI:GetTickCount();
	if curTime - g_CZPVPtime < g_CZPVPRetime2 then
		local resttime = (g_CZPVPRetime2 - (curTime - g_CZPVPtime))/1000
		PushDebugMessage(ScriptGlobal_Format("#{ZTPVP_260515_220}", math.ceil(resttime)))
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("HerosNeverDie")
		Set_XSCRIPT_ScriptID(900029)
		Set_XSCRIPT_Parameter(0, g_CZPVPID)
		Set_XSCRIPT_ParamCount(1)			
	Send_XSCRIPT()	

end

--计时器＝0
function Relive_Time_Zero()
	if( g_Event == Event_Callof )  then
		Relive_FHQ_Clear()
		Relive_CZPVP_Clear()
		this:Hide();
	end;

end

--计时器＝0
function Relive_Time_ZeroFHQ()
	Relive_FHQ_Text:SetText("#{FFZQ_220803_43}")
	Relive_FHQ_Btn:SetProperty("Disabled", "False");

end

--计时器＝0
function Relive_Time_ZeroCZPVP()
	Relive_CZPVP_Text:SetText("#{ZTPVP_260515_221}")
	Relive_CZPVP_Btn:SetProperty("Disabled", "False");
end

--计时器＝0
function Relive_Time_ZeroCityWar()
	Relive_Time_Text4_1:Show()
	Relive_Time_Text4:Hide()

end


function Relive_Out_Fool()
	Player:SendReliveMessage_Fool();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Relive_Frame_On_ResetPos()
	Relive_Frame : SetProperty("UnifiedXPosition", g_Relive_Frame_UnifiedXPosition);
	Relive_Frame : SetProperty("UnifiedYPosition", g_Relive_Frame_UnifiedYPosition);
end

function Relive_AddFoe()
	if (g_KillerGUID ~= "" ) then
		if (g_KillerName ~= "") then
			local group = 0;
			local index = -1;
			group, index = DataPool:GetFriendByGUID(g_KillerGUID);
			if (group == 6 and index > -1) then
				DataPool:ThrowToList(tonumber(group), tonumber(index), tonumber(7), tonumber(g_KillerZoneWorldID));
			end
		end
	end
end

function Relive_BackGround_Click()
	local MouseX,MouseY = GetMousePos()

	if( MouseX > g_Chat_EditboxX and MouseX < g_Chat_EditboxX + g_Chat_EditboxWidth and MouseY > g_Chat_EditboxY and MouseY < g_Chat_EditboxY + g_Chat_EditboxHeight ) then
		Talk:SetEditboxActive()
	end
end

function Relive_FHQ_Clear()
	g_IsShowFHQ = 0
	g_FHQID = 0
	g_FHQtime = 0
end

function Relive_CZPVP_Clear()
	g_IsShowCZPVP = 0
	g_CZPVPID = 0
	g_CZPVPtime = 0
end

function Relive_CityWarFuHuo()
	local curSceneID = GetSceneID();
	if curSceneID == 851 or curSceneID == 852 or curSceneID == 853 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("FuHuo")
			Set_XSCRIPT_ScriptID(998165)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()	
	elseif curSceneID == 1020 or curSceneID == 1021 or curSceneID == 1022 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("FuHuo")
			Set_XSCRIPT_ScriptID(331159)
			Set_XSCRIPT_ParamCount(0)			
		Send_XSCRIPT()	
	end
end

function Relive_IsTJCPVPSceneResID()
	local curSceneID = GetSceneID()
	if curSceneID == g_relive_tjc_res then
		return 1
	end

	return 0
end


-- 是否新杀星副本
function Relive_IsNewshaxingScene()
	local curSceneID = GetSceneID()
	if curSceneID == g_relive_Newsahxing_res then
		return 1
	end
	return 0
end

function Relive_IsFYPVEScene()
	local ret = FYPVE:IsInFYPVEScene()
	if ret ~= nil and ret > 0 then
		return 1
	end

	return 0
end
