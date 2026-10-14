--UI COMMAND ID 198122

local g_clientNpcId = -1;

local g_GoldTicket_TabelIndex = 40004517;

local g_Huoyuezhiduixian_GetMoney = 0 -- 今日已兑换金币和交子的值
local g_Huoyuezhiduixian_DuixianMax = 2500000
--兑现比率 活跃值*10000*Ratio->金
local g_Huoyuezhiduixian_DuixianRatio = 0.5;

local g_Huoyuezhiduixian_LimitMoney = 0
local g_Huoyuezhiduixian_LimitJiaoZi = 0

local g_Huoyuezhiduixian_MonthServer = 0

function Huoyuezhiduixian_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT");
	--this:RegisterEvent("UNIT_GUILDPOINT"); --帮贡界面没有实时刷新机制，人物属性和会员管理界面都没有

end

function Huoyuezhiduixian_OnLoad()
end

function Huoyuezhiduixian_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 198122) then
		if this : IsVisible() then									-- 如果界面开着，则不处理
			return
		end

		local npcObjId = Get_XParam_INT(0)
		g_clientNpcId = DataPool : GetNPCIDByServerID(npcObjId)
		if g_clientNpcId == -1 then
			PushDebugMessage("未发现 NPC")
			Huoyuezhiduixian_Close()
			return
		end

		this : CareObject( g_clientNpcId, 1, "Huoyuezhiduixian" )
		Huoyuezhiduixian_Clear()
		g_Huoyuezhiduixian_LimitMoney = Get_XParam_INT(1)
		g_Huoyuezhiduixian_LimitJiaoZi = Get_XParam_INT(2)
		g_Huoyuezhiduixian_GetMoney = Get_XParam_INT(3)
		g_Huoyuezhiduixian_MonthServer = Get_XParam_INT(4)

		Huoyuezhiduixian_Update()
		OpenWindow("Packet")--打开背包

		this : Show()
		
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_clientNpcId) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
			Huoyuezhiduixian_Close()
		end

--	elseif (event == "UNIT_GUILDPOINT" and this:IsVisible()) then
--
--		Huoyuezhiduixian_Moral_Value:SetProperty("DefaultEditBox", "True");
--		Huoyuezhiduixian_Moral_Value:SetSelected( 0, -1 )
--		Huoyuezhiduixian_Text1:SetText("#{BGCH_8901_23}"..tostring(Player:GetData("GUILDPOINT")))

	end

end

function Huoyuezhiduixian_Update()

		--introduce
		local info = ScriptGlobal_Format("#{XHYZ_XML_5}", g_Huoyuezhiduixian_GetMoney)
		Huoyuezhiduixian_Text4:SetText(info)

		--活跃值
		local nTodayPoint = Player:GetData("TODAYACTIVEPOINT")
		Huoyuezhiduixian_Text3:SetText("#{CKPS_260119_20}"..nTodayPoint)
		local nPoint, nJZPoint = PlayerPackage:GetGoldTickValueByIndex(g_GoldTicket_TabelIndex);		

		if g_Huoyuezhiduixian_MonthServer == 1 then
			--月卡服
			if nPoint > 0 then
				--有金优先显示金币
				Huoyuezhiduixian_Input_Frame1:Show()
				Huoyuezhiduixian_Input_Frame2:Hide()
			else
				Huoyuezhiduixian_Input_Frame1:Hide()
				Huoyuezhiduixian_Input_Frame2:Show()
			end
			--商会金币数量
			Huoyuezhiduixian_Text1:SetText("#{XHYZ_XML_8}".."#{_MONEY"..nPoint.."}")
			--商会交子数量
			Huoyuezhiduixian_Text5:Show()
			Huoyuezhiduixian_Text5:SetText("#{YKJY_251212_16}".."#{_EXCHG"..nJZPoint.."}")
			
			local lockMoney = 0
			local lockJiaoZi = 0
			--24小时锁金开关 未开
			if g_Huoyuezhiduixian_LimitMoney == -1 then
				--关，不处理
				Huoyuezhiduixian_Text1:SetToolTip("")
				Huoyuezhiduixian_Text5:SetToolTip("")
			else
				local tooltipMsg = ScriptGlobal_Format("#{CKPS_260119_22}", g_Huoyuezhiduixian_LimitMoney, nPoint-g_Huoyuezhiduixian_LimitMoney)
				Huoyuezhiduixian_Text1:SetToolTip(tooltipMsg)
				local tooltipMsgjz = ScriptGlobal_Format("#{CKPS_260119_23}", g_Huoyuezhiduixian_LimitJiaoZi, nJZPoint-g_Huoyuezhiduixian_LimitJiaoZi)
				Huoyuezhiduixian_Text5:SetToolTip(tooltipMsgjz)
			end
		else
			--常规服
			Huoyuezhiduixian_Input_Frame1:Show()
			Huoyuezhiduixian_Input_Frame2:Hide()
			Huoyuezhiduixian_Text5:Hide()
			--商会金币数量
			Huoyuezhiduixian_Text1:SetText("#{XHYZ_XML_8}".."#{_MONEY"..nPoint.."}")
			
			--测试用吧
			if nJZPoint > 0 then
				Huoyuezhiduixian_Input_Frame1:Hide()
				Huoyuezhiduixian_Input_Frame2:Show()
				--商会交子数量
				Huoyuezhiduixian_Text5:Show()
				Huoyuezhiduixian_Text5:SetText("#{YKJY_251212_16}".."#{_EXCHG"..nJZPoint.."}")
			end
			
			--24小时锁金开关 未开
	--		PushDebugMessage("g_Huoyuezhiduixian_LimitMoney="..g_Huoyuezhiduixian_LimitMoney.." nPoint="..nPoint)
			if g_Huoyuezhiduixian_LimitMoney == -1 then
				--关，不处理
				Huoyuezhiduixian_Text1:SetToolTip("")
				Huoyuezhiduixian_Text5:SetToolTip("")
			else
				local tooltipMsg = ScriptGlobal_Format("#{CKPS_260119_22}", g_Huoyuezhiduixian_LimitMoney, nPoint-g_Huoyuezhiduixian_LimitMoney)
				Huoyuezhiduixian_Text1:SetToolTip(tooltipMsg)
				if nJZPoint > 0 then
					local tooltipMsgjz = ScriptGlobal_Format("#{CKPS_260119_23}", g_Huoyuezhiduixian_LimitJiaoZi, nJZPoint-g_Huoyuezhiduixian_LimitJiaoZi)
					Huoyuezhiduixian_Text5:SetToolTip(tooltipMsgjz)
				else
					Huoyuezhiduixian_Text5:SetToolTip("")
				end
			end
		end

end
function Huoyuezhiduixian_Cancel_Clicked()
	Huoyuezhiduixian_Close()
end

function Huoyuezhiduixian_Clear()

	Huoyuezhiduixian_Moral_Value2:SetProperty("DefaultEditBox", "True");
	Huoyuezhiduixian_Moral_Value3:SetProperty("DefaultEditBox", "True");
	Huoyuezhiduixian_Moral_Value:SetProperty("DefaultEditBox", "True");
	Huoyuezhiduixian_Moral_Value:SetSelected( 0, -1 )
	Huoyuezhiduixian_Moral_Value:SetText("0")
	Huoyuezhiduixian_Moral_Value2:SetText("0");
	Huoyuezhiduixian_Moral_Value3:SetText("0");
		
end

function Huoyuezhiduixian_Close()
	this:Hide()
	this:CareObject(g_clientNpcId, 0, "Huoyuezhiduixian")
	g_clientNpcId = -1
	Huoyuezhiduixian_Clear()
	
	Huoyuezhiduixian_Moral_Value2:SetProperty("DefaultEditBox", "False");
	Huoyuezhiduixian_Moral_Value3:SetProperty("DefaultEditBox", "False");
	Huoyuezhiduixian_Moral_Value:SetProperty("DefaultEditBox", "False");
end

function Huoyuezhiduixian_Count_Change()
	local str = Huoyuezhiduixian_Moral_Value:GetText()
	local strNumber = 0;

	if ( str == nil ) then
		return;
	elseif( str == "" ) then
		strNumber = 1;
	else
		strNumber = tonumber( str );
	end

	str = tostring( strNumber );
	Huoyuezhiduixian_Moral_Value:SetTextOriginal( str );
end

function Huoyuezhiduixian_CheckIfOK(idx)
	local nNum = nil;
	local szErr = nil ;
	local Ctl = nil;
	if(idx == 1)then
		nNum = tonumber(Huoyuezhiduixian_Moral_Value : GetText());
		Ctl = Huoyuezhiduixian_Moral_Value;
		szErr = "";
	elseif(idx == 2) then
		nNum = tonumber(Huoyuezhiduixian_Moral_Value2 : GetText());
		Ctl = Huoyuezhiduixian_Moral_Value2;
		szErr = "只允许输入小于100的值！";
	elseif(idx == 3) then
		nNum = tonumber(Huoyuezhiduixian_Moral_Value3 : GetText());
		Ctl = Huoyuezhiduixian_Moral_Value3;
		szErr = "只允许输入小于100的值！";
	end
	
	if (szErr == nil or Ctl == nil) then
		return
	end
	
	if (nNum == nil) then
		nNum = 0;
	end
	
	nNum = tostring(nNum);
	if(nNum ~= Ctl : GetText())then
		Ctl:SetText(nNum);
	end
end

function Huoyuezhiduixian_ResetSelect(idx)
	if(idx==1) then
		Huoyuezhiduixian_Moral_Value:SetSelected( 0, -1 );
	elseif(idx==2) then
		Huoyuezhiduixian_Moral_Value2:SetSelected( 0, -1 );
	else
		Huoyuezhiduixian_Moral_Value3:SetSelected( 0, -1 );
	end
end

function Huoyuezhiduixian_OK_Clicked()

	local nGlod = tonumber(Huoyuezhiduixian_Moral_Value:GetText());
	local nSilver = tonumber(Huoyuezhiduixian_Moral_Value2:GetText());
	local nCopperCoin = tonumber(Huoyuezhiduixian_Moral_Value3:GetText());
	
	if (nGlod == nil or nSilver == nil or nCopperCoin == nil) then
		PushDebugMessage("#{HYZ_091118_9}")
		return
	end
	
	local bAvailability, nMoney = Bank:GetInputMoney(nGlod, nSilver, nCopperCoin);
	if (bAvailability ~= true or nMoney <= 0) then
		PushDebugMessage("#{HYZ_091118_9}")
		return;
	end
	
	local nPoint, nJZPoint = PlayerPackage:GetGoldTickValueByIndex(g_GoldTicket_TabelIndex);
	local nTotalPoint = nPoint + nJZPoint

	if nTotalPoint == 0 then
		PushDebugMessage("#H您没有商会金票，无法进行兑换操作。")
		return
	end
	
	if nMoney > nTotalPoint then
		PushDebugMessage("#{HYZ_091118_15}")
		return
	end

	Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Huoyuezhiduixian" )
			Set_XSCRIPT_ScriptID( 889203 )
			Set_XSCRIPT_Parameter( 0, nMoney )
			Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	Huoyuezhiduixian_Close()
end

--=============================================
--
--=============================================
function Huoyuezhiduixian_Max_Clicked()

	local nShowMoney = 0
	local nPoint, nJZPoint = PlayerPackage:GetGoldTickValueByIndex(g_GoldTicket_TabelIndex);

	local lockMoney = g_Huoyuezhiduixian_LimitMoney
	local lockJiaoZi = g_Huoyuezhiduixian_LimitJiaoZi
	if lockMoney == -1 then
		lockMoney = 0
		lockJiaoZi = 0
	end

	if nPoint > 0 then
		nShowMoney = nPoint - lockMoney
	elseif nJZPoint > 0 then
		nShowMoney = nJZPoint - lockJiaoZi
	end

	local nLeftMoneyCanDuixian = g_Huoyuezhiduixian_DuixianMax - g_Huoyuezhiduixian_GetMoney
	if nShowMoney > nLeftMoneyCanDuixian then
		nShowMoney = nLeftMoneyCanDuixian
	end
	if nShowMoney < 0 then
		nShowMoney = 0
	end
	--剩余活跃值可兑换多少
	local nTodayPoint = Player:GetData("TODAYACTIVEPOINT")
	local nMoneyByActivePoint = math.floor(nTodayPoint*10000*g_Huoyuezhiduixian_DuixianRatio)
	nMoneyByActivePoint = nMoneyByActivePoint - g_Huoyuezhiduixian_GetMoney
	if nShowMoney > nMoneyByActivePoint then
		nShowMoney = nMoneyByActivePoint
	end

	local nGlod = math.floor(nShowMoney / 10000)
	local nSilver = math.floor( math.mod(nShowMoney / 100, 100) )
	local nCopperCoin = math.floor( math.mod(nShowMoney, 100) )
	
	Huoyuezhiduixian_Moral_Value2:SetProperty("DefaultEditBox", "True");
	Huoyuezhiduixian_Moral_Value3:SetProperty("DefaultEditBox", "True");
	Huoyuezhiduixian_Moral_Value:SetProperty("DefaultEditBox", "True");
	Huoyuezhiduixian_Moral_Value:SetSelected( 0, -1 );
	
	Huoyuezhiduixian_Moral_Value:SetText(tostring(nGlod))
	Huoyuezhiduixian_Moral_Value2:SetText(tostring(nSilver));
	Huoyuezhiduixian_Moral_Value3:SetText(tostring(nCopperCoin));
	
end


