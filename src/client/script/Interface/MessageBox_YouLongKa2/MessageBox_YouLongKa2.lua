local Server_Script_Function = ""
local Server_Script_ID =-1
local Server_Return_1 =-1
local Server_Return_2 =-1
local g_MessageBox_YouLongKa2_MaxNum = 20  --功能的最大数目
local g_MsgBox_YouLongKa2_FunUseTimes = {} --功能使用次数

local g_MessageBox_YouLongKa2_Dict = {		--便捷功能查询结果字典，flag：0，领取型；1，按次数的；0，无限次。type：1，快捷功能；2，道具奖励功能
	{flag=0, [0]="#{GJYLK_120517_123}", [1]="#{GJYLK_120517_123}",type=1},	--冻结/解冻双倍时间（不限次数功能）
	{flag=1, [0]="#{GJYLK_120517_121}", [1]="#{GJYLK_120517_145}",type=1},	--随身珍兽商店
	{flag=1, [0]="#{GJYLK_120517_120}", [1]="#{GJYLK_120517_143}",type=1},	--随身银行
	{flag=1, [0]="#{GJYLK_120517_121}", [1]="#{GJYLK_120517_144}",type=1},	--随身珍兽银行
	{flag=1, [0]="#{GJYLK_120517_86}", [1]="#{GJYLK_120517_94}",type=1},	--随身神器修理
	{flag=1, [0]="#{GJYLK_120517_118}", [1]="#{GJYLK_120517_141}",type=1},	--额外双倍经验

}

local g_Msg_Confirm_Dict = {		--便捷功能查询结果字典，flag：0，领取型；1，按次数的；0，无限次。type：1，快捷功能；2，道具奖励功能
	{flag=0, [0]="#{GJYLK_120517_129}", type=1},	--冻结/解冻双倍时间（不限次数功能）
	{flag=1, [0]="#{GJYLK_120517_128}", type=1},	--随身珍兽商店
	{flag=1, [0]="#{GJYLK_120517_127}", type=1},	--随身银行
	{flag=1, [0]="#{GJYLK_120517_138}", type=1},	--随身珍兽银行
	{flag=1, [0]="#{GJYLK_120517_126}", type=1},	--随身神器修理
	{flag=1, [0]="#{GJYLK_120517_125}", type=1},	--额外双倍经验
				 
}


local g_FrameInfo = -1    -- 201205149   注销

local g_Msg_YouLongKa2_CurIndex = 0
local g_Msg_YouLongKa2_ItemIndex_1 = 38000360
local g_Msg_YouLongKa2_ItemIndex_2 = 38000361

local g_Msg_Baibing_LeftTime = 0
local g_Msg_Baishou_LeftTime = 0

function MessageBox_YouLongKa2_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
end

function MessageBox_YouLongKa2_OnLoad()
	 --位置可随分辨率变化
end

function MessageBox_YouLongKa2_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 201205141 then  --确认使用月卡  
			g_FrameInfo = 201205141	
			MessageBox_YouLongKa2_UpdateFrame()		
			if g_Msg_YouLongKa2_CurIndex == g_Msg_YouLongKa2_ItemIndex_1 then  --银卡
				if SystemSetup:IsClassic() == 1 then
					MessageBox_YouLongKa2_Frame:SetProperty( "UnifiedSize","{{0.000000,292.000000},{0.000000,205.000000}}");
					MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", "277" );
					MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,0.000000},{0.000000,0.000000}}");
				else
					MessageBox_YouLongKa2_Frame:SetProperty( "UnifiedSize","{{0.000000,400.000000},{0.000000,205.000000}}");
					MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", "350" );
					MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,5.000000},{0.000000,5.000000}}");
				end
			else
				MessageBox_YouLongKa2_UpdateRect()
				if SystemSetup:IsClassic() == 1 then
					MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteWidth", tostring( 292 ) );
					local fh = tonumber(MessageBox_YouLongKa2_Text:GetProperty("AbsoluteHeight"))+85
					MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteHeight", tostring( fh ) );
					MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", "277" );
					MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,0.000000},{0.000000,0.000000}}");
				else
					MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteWidth", tostring( 400 ) );
					local fh = tonumber(MessageBox_YouLongKa2_Text:GetProperty("AbsoluteHeight"))+90
					MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteHeight", tostring( fh ) );
					MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", "350" );
					MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,5.000000},{0.000000,5.000000}}");
				end
			end
			
		    this:Show();
		end
		if tonumber(arg0) == 201205148 then  --月卡升级
			g_FrameInfo = 201205148
			MessageBox_YouLongKa2_UpdateFrame()
			local nWindowHeight = 165
			if SystemSetup:IsClassic() == 1 then
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteHeight", tostring( 165 ) );
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteWidth", tostring( 292 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", tostring( 277 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,0.000000},{0.000000,0.000000}}");
			else
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteWidth", tostring( 400 ) );
				local fh = tonumber(MessageBox_YouLongKa2_Text:GetProperty("AbsoluteHeight"))+90
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteHeight", tostring( fh ) );
				MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", tostring( 350 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,5.000000},{0.000000,5.000000}}");
			end
		    this:Show();
		end
		if tonumber(arg0) == 201205149 then  --注销
			g_FrameInfo = 201205149
			MessageBox_YouLongKa2_UpdateFrame()
			MessageBox_YouLongKa2_UpdateRect()
			if SystemSetup:IsClassic() == 1 then
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteWidth", tostring( 350 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", tostring( 335 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,0.000000},{0.000000,0.000000}}");
			else
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteWidth", tostring( 400 ) );
				local fh = tonumber(MessageBox_YouLongKa2_Text:GetProperty("AbsoluteHeight"))+90
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteHeight", tostring( fh ) );
				MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", tostring( 350 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,5.000000},{0.000000,5.000000}}");
			end
		    this:Show();
		end
		if tonumber(arg0) == 201205151 then  --冻结解冻双倍时间
			g_FrameInfo = 201205151
			MessageBox_YouLongKa2_UpdateFrame()
			local nWindowHeight = 165
			if SystemSetup:IsClassic() == 1 then
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteHeight", tostring( 145 ) );
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteWidth", tostring( 260 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", tostring( 245 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,0.000000},{0.000000,0.000000}}");
			else
				local fh = tonumber(MessageBox_YouLongKa2_Text:GetProperty("AbsoluteHeight"))+90
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteHeight", tostring( fh ) );
				MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteWidth", tostring( 400 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "MaxWidth", tostring( 350 ) );
				MessageBox_YouLongKa2_Text:SetProperty( "UnifiedPosition", "{{0.000000,5.000000},{0.000000,5.000000}}");
			end
		    this:Show();
		end
		if (event == "UI_COMMAND") and (arg0 == "201205145") then  --获取便捷功能使用次数
			local j = 0
			for i = 1, table.getn(g_MessageBox_YouLongKa2_Dict) do
				g_MsgBox_YouLongKa2_FunUseTimes[i] = { FunId = Get_XParam_INT(j), FunUseTimes = Get_XParam_INT(j+1)}
				j = j+2
			end    
		end
		if (event == "UI_COMMAND") and (arg0 == "201205144") then  --获取百兵精通剩余时间和百兽精通剩余时间
			g_Msg_Baibing_LeftTime =  Get_XParam_INT(2)
			g_Msg_Baishou_LeftTime =  Get_XParam_INT(2)
		end
	end
	if (event == "HIDE_ON_SCENE_TRANSED") then
		MessageBox_YouLongKa2_Cancel_Clicked()
	end
end

function MessageBox_YouLongKa2_UpdateFrame()
	if(g_FrameInfo == 201205141) then  --确认使用月卡  
		Server_Script_Function = Get_XParam_STR(0);
		Server_Script_ID = Get_XParam_INT(0); --脚本id
		Server_Return_1 = Get_XParam_INT(1);  --道具索引
		g_Msg_YouLongKa2_CurIndex = Get_XParam_INT(2);  --道具id
		local nIsService = Get_XParam_INT(3); --当前是否服务状态开启
		--PushDebugMessage(tostring(Get_XParam_INT(2))) 
		Player:SetMCardIndexShow(Get_XParam_INT(2))
		local str = ""
		local strTemp4 = ""
		local strTemp5 = ""
		local strTemp6 = ""
		local strTemp7 = ""
		if g_Msg_YouLongKa2_CurIndex == g_Msg_YouLongKa2_ItemIndex_1 then  --银卡
			strTemp4 = "#{GJYLK_120517_08}"
			strTemp6 = "#{GJYLK_120517_132}"
		else
			strTemp4 = "#{GJYLK_120517_05}" 
			strTemp5 = "#{GJYLK_120517_130}" 
			strTemp7 = "#{BSJT_130114_20}" 
			strTemp6 = "#{GJYLK_120517_131}"
		end

		local strTemp1 = ""
		local strTemp2 = ""
		local strTemp3 = ""		--快捷功能：限次和不限次的分开显示
		for i = 1, g_MessageBox_YouLongKa2_MaxNum do
			
			local funcId, funcType, funcMaxUseTimes = DataPool:GetMCardInfoShowByIdx(i-1)
			--PushDebugMessage("funcId") 
			--PushDebugMessage(funcId)
			if funcId and funcId >= 1 then
				--PushDebugMessage("1111111111111") 
				local strTemp = "#r"
				local strTemp_1 = ""
			
				if g_Msg_Confirm_Dict[funcId].flag == 1 then
					
					strTemp_1 = ScriptGlobal_Format(g_Msg_Confirm_Dict[funcId][0],tostring(funcMaxUseTimes))
				else
					strTemp_1 = g_Msg_Confirm_Dict[funcId][0]
				end
				
				strTemp = strTemp..strTemp_1
				
				if g_Msg_Confirm_Dict[funcId].type == 1 then
					if g_Msg_Confirm_Dict[funcId].flag == 1 then
						strTemp1 = strTemp1..strTemp
					else
						strTemp3 = strTemp3..strTemp
					end
				elseif g_Msg_Confirm_Dict[funcId].type == 2 then
					strTemp2 = strTemp2..strTemp
				end
			end
		end
		if nIsService == 1 then
		    if g_Msg_YouLongKa2_CurIndex == g_Msg_YouLongKa2_ItemIndex_1 then --银卡 
				str = strTemp4..strTemp1..strTemp3..strTemp2.."#r"..strTemp6
		    else
				str = strTemp4..strTemp1..strTemp3..strTemp2.."#r"..strTemp5.."#r"..strTemp7.."#r"..strTemp6
		    end
			
		else
			str = strTemp4..strTemp1..strTemp3..strTemp2.."#r"..strTemp5.."#r"..strTemp7
		end
		--PushDebugMessage("strTemp6"..strTemp6)
		MessageBox_YouLongKa2_Text:SetText(str);
		--MessageBox_YouLongKa2_Text:SetText("nnnnnnnnnnnnnnnnn");
		MessageBox_YouLongKa2_DragTitle:SetText("#{GJYLK_120517_149}");
	end
	if(g_FrameInfo == 201205148) then   --月卡升级
		
		Server_Script_Function = Get_XParam_STR(0);
		Server_Script_ID = Get_XParam_INT(0); --脚本id

		MessageBox_YouLongKa2_Text:SetText(Get_XParam_STR(1));
		MessageBox_YouLongKa2_DragTitle:SetText("#{GJYLK_120517_150}");

	end
	if(g_FrameInfo == 201205151) then  --冻结解冻双倍时间
		
		Server_Script_Function = Get_XParam_STR(0);
		Server_Script_ID = Get_XParam_INT(0); --脚本id
		Server_Return_1 = Get_XParam_INT(1); --targetId
		Server_Return_2 = Get_XParam_INT(2); --nTime

		MessageBox_YouLongKa2_Text:SetText(Get_XParam_STR(1));
		MessageBox_YouLongKa2_DragTitle:SetText("");

	end
	if(g_FrameInfo == 201205149) then  --确认注销
		Server_Script_Function = Get_XParam_STR(0);
		Server_Script_ID = Get_XParam_INT(0); --脚本id
		
		local str = "#{GJYLK_120517_117}"
		local strTemp1 = ""
		local strTemp2 = ""
		local strTemp3 = ""		--快捷功能：限次和不限次的分开显示
		for i = 1, g_MessageBox_YouLongKa2_MaxNum do
			local funcId, funcType, funcMaxUseTimes = DataPool:GetMCardInfoByIdx(i-1)
			if funcId and funcId >= 1 then
				local strTemp = "#r"
				local funcUsedTimes = -1
				for i = 1, table.getn(g_MessageBox_YouLongKa2_Dict) do
				    if g_MsgBox_YouLongKa2_FunUseTimes[i].FunId == funcId then
					    funcUsedTimes = g_MsgBox_YouLongKa2_FunUseTimes[i].FunUseTimes
					    break
				    end
				end
				if funcUsedTimes >=  funcMaxUseTimes then
					strTemp = strTemp..g_MessageBox_YouLongKa2_Dict[funcId][1]
				else			
					strTemp = strTemp..g_MessageBox_YouLongKa2_Dict[funcId][0]
				end
				if g_MessageBox_YouLongKa2_Dict[funcId].flag == 1 then
					strTemp = strTemp..(funcMaxUseTimes-funcUsedTimes).."/"..funcMaxUseTimes
				end
				
				if g_MessageBox_YouLongKa2_Dict[funcId].type == 1 then
					if g_MessageBox_YouLongKa2_Dict[funcId].flag == 1 then
						strTemp1 = strTemp1..strTemp
					else
						strTemp3 = strTemp3..strTemp
					end
				elseif g_MessageBox_YouLongKa2_Dict[funcId].type == 2 then
					strTemp2 = strTemp2..strTemp
				end
			end
		end
		
		local nBaibingDay = math.floor( g_Msg_Baibing_LeftTime/86400 )
		local nBaibingHour = math.mod(g_Msg_Baibing_LeftTime ,86400)/3600
		nBaibingHour = math.floor(nBaibingHour)
		local nBaishouDay = math.floor( g_Msg_Baishou_LeftTime/86400 )
		local nBaishouHour = math.mod(g_Msg_Baishou_LeftTime ,86400)/3600
		nBaishouHour = math.floor(nBaishouHour)
		local strTemp4 = ScriptGlobal_Format("#{GJYLK_120517_124}",tostring(nBaibingDay), tostring(nBaibingHour))
		local strTemp5 = ScriptGlobal_Format("#{BSJT_130114_02}",tostring(nBaishouDay), tostring(nBaishouHour))
		
		if DataPool:GetIsBaiBing() == 1 then
			str = str.."#r"..strTemp1..strTemp3.."#r"..strTemp2..strTemp4.."#r"
		else
			str = str.."#r"..strTemp1..strTemp3.."#r"..strTemp2
		end
		
		if Pet:GetIsBaiShou() == 1 then
			str = str..strTemp5.."#r"
		end
		
		str = str.."#r".."#{GJYLK_120517_92}"
		
		MessageBox_YouLongKa2_Text:SetText(str);
		MessageBox_YouLongKa2_DragTitle:SetText("#{GJYLK_120517_151}");
	end
end

function MessageBox_YouLongKa2_OK_Clicked()
	if(g_FrameInfo == 201205141) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name(Server_Script_Function);
			Set_XSCRIPT_ScriptID(Server_Script_ID);
			Set_XSCRIPT_Parameter(0,Server_Return_1);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();		
	end
	if(g_FrameInfo == 201205148) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name(Server_Script_Function);
			Set_XSCRIPT_ScriptID(Server_Script_ID);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
	end
	if(g_FrameInfo == 201205151) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name(Server_Script_Function);
			Set_XSCRIPT_ScriptID(Server_Script_ID);
			Set_XSCRIPT_Parameter(0,Server_Return_1);
			Set_XSCRIPT_Parameter(1,Server_Return_2);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	end
	if(g_FrameInfo == 201205149) then
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name(Server_Script_Function);
			Set_XSCRIPT_ScriptID(Server_Script_ID);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
	end
    MessageBox_YouLongKa2_Cancel_Clicked()
end

function MessageBox_YouLongKa2_Cancel_Clicked()
    Server_Script_Function = ""
	Server_Script_ID =-1
	Server_Return_1 =-1
--	MessageBox_YouLongKa2_Text:SetText("");
	this:Hide();
end

function  MessageBox_YouLongKa2_UpdateRect()
	--PushDebugMessage("MessageBox_YouLongKa2_UpdateRect") 

	local nWidth, nHeight = MessageBox_YouLongKa2_Text:GetWindowSize();
	--PushDebugMessage("nHeight")
	--PushDebugMessage(nHeight)
	local nTitleHeight = 0;
	local nBottomHeight = 70;
	nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	MessageBox_YouLongKa2_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
end