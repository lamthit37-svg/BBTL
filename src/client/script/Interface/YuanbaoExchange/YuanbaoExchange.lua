local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local Exchange_Rate = 1;
local g_Point = 0;
local g_Object = -1;
local g_YuanbaoExchange_Frame_UnifiedPosition;
local g_IsXinfu = 0
local g_SuiShenDuihuan =1

local g_XYZExchangeStart = 20130923  --充值返利活动 侠义值的显示时间
local g_XYZExchangeEnd = 20131023

function YuanbaoExchange_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OBJECT_CARED_EVENT",true);
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function YuanbaoExchange_OnLoad()
	g_YuanbaoExchange_Frame_UnifiedPosition=YuanbaoExchange_Frame:GetProperty("UnifiedPosition");
end

function YuanbaoExchange_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 2001 ) then
			if this:IsVisible() then
				YuanbaoExchange_Close();
				return
			end
			g_Object = Get_XParam_INT(0);
			if 0<= g_Object then --短窗口
				if SystemSetup:IsClassic() == 0 then
					YuanbaoExchange_Frame:SetProperty("UnifiedSize","{{0.000000,300.000000},{0.000000,322.000000}}");
				else
					YuanbaoExchange_Frame:SetProperty("UnifiedSize","{{0.000000,292.000000},{0.000000,292.000000}}");
				end
								YuanbaoExchange_Text2:SetText("")
				YuanbaoExchange_Cancel:SetText("")
				YuanbaoExchange2:SetText("")
					YuanbaoExchange_Cancel:SetText("")
				BeginCareObject_YuanbaoExchange(Target:GetServerId2ClientId(g_Object));
				g_SuiShenDuihuan = 0
			else --长窗口
				if SystemSetup:IsClassic() == 0 then
					YuanbaoExchange_Frame:SetProperty("UnifiedSize", "{{0.000000,300.000000},{0.000000,422.000000}}");
				else
					YuanbaoExchange_Frame:SetProperty("UnifiedSize", "{{0.000000,292.000000},{0.000000,379.000000}}");
				end
				YuanbaoExchange_Text2:SetText("")
				YuanbaoExchange2:SetText("#{ZXCZ_120717_43}")
			  g_SuiShenDuihuan = 1
			end
			YuanbaoExchange_Text2:SetText("#{INTERFACE_XML_527}")		
			YuanbaoExchange_Cancel:SetText("#{INTERFACE_XML_542}")
			YuanbaoExchange_Moral_Value:SetProperty("DefaultEditBox", "True");
			YuanbaoExchange_Moral_Value:SetSelected( 0, -1 );
			g_IsXinfu = Get_XParam_INT(2)
			if g_IsXinfu==1 then
				YuanbaoExchange:SetText("")
				YuanbaoExchange:SetText("#{XDHB_110311_12}")
			elseif g_IsXinfu == 2 then
				YuanbaoExchange:SetText("")
				YuanbaoExchange:SetText("#{XDHB_110311_13}")
			--YuanPeiLong - 开卡充值送好礼
			elseif g_IsXinfu == 3 then
				YuanbaoExchange:SetText("")
				YuanbaoExchange:SetText("#{LDZHSK_120319_45}")			
			elseif g_IsXinfu == 4 then
				YuanbaoExchange:SetText("")
				YuanbaoExchange:SetText("#{LDZHSK_120319_46}")		
				if Player:GetData("Is2606S") == 1 then
					YuanbaoExchange:SetText("#{QXF_260623_164}")		
				end		
			--End				
			else
				YuanbaoExchange:SetText("#{XDHB_110311_13}")
			end
			if IsTBFinalServer() >= 1 then
				--TODO,雄霸天下总决赛服务器,显示特殊Tips,求字典
				YuanbaoExchange:SetText("#{BHKF_150323_208}")
			end
			local ServerDayTime = DataPool:GetServerDayTime()
			if ServerDayTime >= g_XYZExchangeStart and ServerDayTime <= g_XYZExchangeEnd then
				--活动时间内
				local curXiayz = DataPool:GetPlayerMission_DataRound(876);
				local strXiayz = ScriptGlobal_Format("#{CZFLS_130816_1}", tostring(curXiayz))
				YuanbaoExchange_Text:SetText(strXiayz)
				YuanbaoExchange_Text:SetToolTip("#{CZFLS_130816_2}");
				YuanbaoExchange_Text:Show();
			else
				YuanbaoExchange_Text:SetText("")
				YuanbaoExchange_Text:SetToolTip("");
				YuanbaoExchange_Text:Hide();
			end
			
			YuanbaoExchange_OnShown();

			this:Show();
			YuanbaoExchange_Count_Change();
			YuanbaoExchange_Max:Disable()
			YuanbaoExchange_OK : Disable()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2003 ) then
		if(this:IsVisible()) then
			YuanbaoExchange_Moral_Value:SetProperty("DefaultEditBox", "True");
			YuanbaoExchange_Moral_Value:SetSelected( 0, -1 );
			--g_Point = Get_XParam_INT(0)/1000;
			g_Point = Get_XParam_UINT(0) / 10
			local nPLow = math.mod( Get_XParam_UINT(0), 10000 );
			local nPHigh = math.floor( (Get_XParam_UINT(0) - nPLow) / 10000 );
			--local strPoint = tostring(nPHigh)..tostring(math.floor(nPLow/10));
			--处理整数部分
			local strPoint = "";
			if ( nPHigh > 0 ) then
				strPoint = tostring(nPHigh)..string.format("%03d", math.floor(nPLow/10) );
			else
				strPoint = string.format("%d", math.floor(nPLow/10) );
			end
			--加上小数部分
			if( math.mod(nPLow, 10) > 0 ) then
				strPoint = strPoint.."."..math.mod(nPLow,10);
			end
			YuanbaoExchange_Text1 : SetText("您目前账户剩余点数："..strPoint );
			--专属点数
			local nExPoint = Get_XParam_UINT(1)/10;
			if nExPoint > 0 then
				local tipsPoint = ScriptGlobal_Format("#{YCDS_181201_01}", nExPoint)
				YuanbaoExchange_Text1:SetToolTip(tipsPoint);
			else
				YuanbaoExchange_Text1:SetToolTip("");
			end
			local point2YuanBao = g_Point/Exchange_Rate;
			if point2YuanBao < 0 then point2YuanBao = 0; end
			local tips = ScriptGlobal_Format("#{XDHYB_140915_01}", point2YuanBao)
			YuanbaoExchange_Text5 : SetText(tips)
			YuanbaoExchange_Max:Enable()
			YuanbaoExchange_OK:Enable()
			YuanbaoExchange_Moral_Value:Enable();
		end
	elseif ( event == "OBJECT_CARED_EVENT") then
		YuanbaoExchange_CareEventHandle(arg0,arg1,arg2);
	elseif ( event == "HIDE_ON_SCENE_TRANSED") then
		YuanbaoExchange_Close()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		YuanbaoExchange_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		YuanbaoExchange_Frame_On_ResetPos()
	end

end

function YuanbaoExchange_OnShown()
	YuanbaoExchange_Clear();
	YuanbaoExchange_Update();
end

function YuanbaoExchange_Clear()
	YuanbaoExchange_Text1 : SetText("")
	YuanbaoExchange_Moral_Value : SetText("")
	YuanbaoExchange_Text3 : SetText("")
	YuanbaoExchange_Text1:SetToolTip("");
	g_Point = 0;
	Exchange_Rate = 1;
end

function YuanbaoExchange_Update()
	Exchange_Rate = Get_XParam_INT(1)/10

	YuanbaoExchange_Text1 : SetText("#cff0000#b剩余点数正在查询中，请稍候……")
	--YuanbaoExchange_Text4 : SetText("用户剩余点数可兑换元宝：")
	local tips = ScriptGlobal_Format("#{XDHYB_140915_01}", 0)
	YuanbaoExchange_Text5 : SetText(tips)
	YuanbaoExchange_Text3 : SetText("需要花费点数：0")

end

function YuanbaoExchange_OK_Clicked()
	local str = YuanbaoExchange_Moral_Value : GetText();

	--AxTrace(0,0,"YuanbaoExchange_OK_Clicked 1 "..tostring(str));

	if str == nil or str == "" then
		YuanbaoExchange_Text3 : SetText("需要花费点数：0")
		PushDebugMessage("请输入要兑换的元宝数额")
		return
	end

	if tonumber(str) > 500000 then
		PushDebugMessage("每次兑换的元宝数量最多为500000点，请输入小于等于500000点的数字。")
		return
	end
	if( tonumber(str) <= 0 ) then
		PushDebugMessage("每次兑换的元宝数量最少为1点，请输入大于等于1点的数字。")
		return
	end

	--AxTrace(0,0,"YuanbaoExchange_OK_Clicked 2");
	if IsTBFinalServer() >= 1 then
		--雄霸天下总决赛特殊服务器,调用特殊的服务器脚本函数
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("BuyYuanbao");
		Set_XSCRIPT_ScriptID(891051);
		Set_XSCRIPT_Parameter(0,tonumber(str));
		Set_XSCRIPT_Parameter(1,0);
		Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();

		YuanbaoExchange_Close();
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("BuyYuanbao");
		Set_XSCRIPT_ScriptID(181000);
		Set_XSCRIPT_Parameter(0,tonumber(str));
		Set_XSCRIPT_Parameter(1,tonumber(g_SuiShenDuihuan));
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
	YuanbaoExchange_Close();
end

function YuanbaoExchange_Close()
	YuanbaoExchange_OnHiden();
	this:Hide()
end

function YuanbaoExchange_Cancel_Clicked()
	YuanbaoExchange_Close();
	return;
end

function YuanbaoExchange_OnHiden()
	StopCareObject_YuanbaoExchange(objCared)
	YuanbaoExchange_Clear()
	return
end

function YuanbaoExchange_CareEventHandle(careId, op, distance)
		if(nil == careId or nil == op or nil == distance) then
			return;
		end

		if(tonumber(careId) ~= g_clientNpcId) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
			YuanbaoExchange_Close();
		end
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_YuanbaoExchange(objCaredId)

	g_Object = objCaredId;
	--AxTrace(0,0,"LUA___CareObject g_Object =" .. g_Object );
	this:CareObject(g_Object, 1, "YuanbaoExchange");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_YuanbaoExchange(objCaredId)
	this:CareObject(objCaredId, 0, "YuanbaoExchange");
	g_Object = -1;

end

function YuanbaoExchange_Count_Change()
	local str = YuanbaoExchange_Moral_Value : GetText();
	local strNumber = 0;

	if ( str == nil ) then
		return;
	elseif( str == "" ) then
		strNumber = 0;
	else
		strNumber = tonumber( str );
	end
	str = tostring( strNumber );
	YuanbaoExchange_Moral_Value:SetTextOriginal( str );
	YuanbaoExchange_Text3 : SetText("需要花费点数："..tostring( Exchange_Rate * strNumber ) )
end

function YuanbaoExchange_Max_Clicked()
	local maxYuanBao = 500000;
	local point2YuanBao = g_Point/Exchange_Rate;
	if point2YuanBao < 0 then point2YuanBao = 0; end

	YuanbaoExchange_Moral_Value:SetProperty("ClearOffset", "True");
	if point2YuanBao > maxYuanBao then
		YuanbaoExchange_Moral_Value:SetText(tostring(maxYuanBao));
	else
		YuanbaoExchange_Moral_Value:SetText(tostring(point2YuanBao));
	end
	YuanbaoExchange_Moral_Value:SetProperty("CaratIndex", 1024);
end


--================================================
-- 恢复界面的默认相对位置
--================================================
function YuanbaoExchange_Frame_On_ResetPos()
  YuanbaoExchange_Frame:SetProperty("UnifiedPosition", g_YuanbaoExchange_Frame_UnifiedPosition);
end
