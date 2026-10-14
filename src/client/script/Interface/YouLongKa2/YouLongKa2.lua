local g_YouLongKa2_LeftBtnNum = 5
local g_YouLongKa2_CurIndex = 0
local g_YouLongKa2_ItemIndex_1 = 38000360
local g_YouLongKa2_ItemIndex_2 = 38000361
local g_YouLongKa2_IsLevelup = -1  --1表示升级，0表示注销
local g_YouLongKa2_MaxNum = 20		--功能的最大数目
local g_YouLongKa2_BKIcon = {}		--功能选项图标列表
local g_YouLongKa2_BKList = {}		--功能选项按钮列表
local g_YouLongKa2_BKWindow = {}    --功能选项列表

local g_YouLongKa2_FunUseTimes = {} --功能使用次数

local g_Baibing_LeftTime = 0
local g_Baishou_LeftTime = 0

local g_YouLongKa2_BKId = {		--用于保存按钮对应的功能ID
	0,0,0,0,0,0,0,0,
}

local g_YouLongKa2_Dict = {		--便捷功能查询结果字典，flag：0，领取型；1，按次数的；0，无限次。type：1，快捷功能；2，道具奖励功能
	{flag=0, [0]="#{GJYLK_120517_90}", [1]="#{GJYLK_120517_90}",type=1},	--冻结/解冻双倍时间（不限次数功能）
	{flag=1, [0]="#{GJYLK_120517_89}", [1]="#{GJYLK_120517_97}",type=1},	--随身珍兽商店
	{flag=1, [0]="#{GJYLK_120517_87}", [1]="#{GJYLK_120517_95}",type=1},	--随身银行
	{flag=1, [0]="#{GJYLK_120517_88}", [1]="#{GJYLK_120517_96}",type=1},	--随身珍兽银行
	{flag=1, [0]="#{GJYLK_120517_86}", [1]="#{GJYLK_120517_94}",type=1},	--随身神器修理
	{flag=1, [0]="#{GJYLK_120517_85}", [1]="#{GJYLK_120517_93}",type=1},	--额外双倍经验

}

local g_YouLongKa2_ImageList = {	--功能图标，目前12个
	"set:CircularTaskTool28 image:CircularTaskTool28_15",      --冻结/解冻双倍时间（不限次数功能）
	"set:TaskTools15 image:TaskTools15_8",		--随身珍兽商店
	"set:TaskTools15 image:TaskTools15_7",		--随身银行
	"set:TaskTools15 image:TaskTools15_16",		--随身珍兽银行
	"set:TaskTools15 image:TaskTools15_5",		--随身神器修理
	"",	                                        --额外双倍经验
}

local g_YouLongKa2_BKListText = {  --便捷功能按钮文字（按功能id排列）
	"#{GJYLK_120517_108}",
	"#{GJYLK_120517_109}",
	"#{GJYLK_120517_110}",
	"#{GJYLK_120517_111}",
	"#{GJYLK_120517_112}",
	"",

}

function YouLongKa2_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_DOUBLE_EXP")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function YouLongKa2_OnLoad()
	g_YouLongKa2_BKIcon[1] = YouLongKa2_BK1_Back
	g_YouLongKa2_BKIcon[2] = YouLongKa2_BK2_Back
	g_YouLongKa2_BKIcon[3] = YouLongKa2_BK3_Back
	g_YouLongKa2_BKIcon[4] = YouLongKa2_BK4_Back
	g_YouLongKa2_BKIcon[5] = YouLongKa2_BK5_Back
	g_YouLongKa2_BKIcon[6] = YouLongKa2_BK6_Back
	g_YouLongKa2_BKIcon[7] = YouLongKa2_BK7_Back
	g_YouLongKa2_BKIcon[8] = YouLongKa2_BK8_Back
	
	g_YouLongKa2_BKList[1] = YouLongKa2_BK1_Button
	g_YouLongKa2_BKList[2] = YouLongKa2_BK2_Button
	g_YouLongKa2_BKList[3] = YouLongKa2_BK3_Button
	g_YouLongKa2_BKList[4] = YouLongKa2_BK4_Button
	g_YouLongKa2_BKList[5] = YouLongKa2_BK5_Button
	g_YouLongKa2_BKList[6] = YouLongKa2_BK6_Button
	g_YouLongKa2_BKList[7] = YouLongKa2_BK7_Button
	g_YouLongKa2_BKList[8] = YouLongKa2_BK8_Button
	
	g_YouLongKa2_BKWindow[1] = YouLongKa2_BK1
	g_YouLongKa2_BKWindow[2] = YouLongKa2_BK2
	g_YouLongKa2_BKWindow[3] = YouLongKa2_BK3
	g_YouLongKa2_BKWindow[4] = YouLongKa2_BK4
	g_YouLongKa2_BKWindow[5] = YouLongKa2_BK5
	g_YouLongKa2_BKWindow[6] = YouLongKa2_BK6
	g_YouLongKa2_BKWindow[7] = YouLongKa2_BK7
	g_YouLongKa2_BKWindow[8] = YouLongKa2_BK8
	
end

function YouLongKa2_OnEvent(event)
	if (event == "UI_COMMAND") and (arg0 == "201205143") then  --设置月卡服务状态
		local nServiceState = Get_XParam_INT(0)
		Player:SetServiceState(nServiceState)
	end
	
	if (event == "UI_COMMAND") and (arg0 == "201205144") then  --显示或隐藏该界面
		if Get_XParam_INT(0) == 0 then  --隐藏该界面
			YouLongKa2_Close()
		else
                       --显示该界面
            local year,mon,day = ANSI2TM(tonumber(Get_XParam_INT(1)))
			local name = Player:GetName()
			local str = ""

			if g_YouLongKa2_CurIndex == g_YouLongKa2_ItemIndex_1 then
				str = ScriptGlobal_Format("#{GJYLK_120517_113}",name,tostring(year),tostring(mon),tostring(day))
			else
				
				str = ScriptGlobal_Format("#{GJYLK_120517_114}",name,tostring(year),tostring(mon),tostring(day))
				--PushDebugMessage(str)
			end
			YouLongKa2_Text1:SetText(str)
			g_Baibing_LeftTime =  Get_XParam_INT(2)
			g_Baishou_LeftTime =  Get_XParam_INT(2)
			YouLongKa2_Update(1)
		    this:Show() 
		end

	end
	
	if (event == "UI_COMMAND") and (arg0 == "201205145") then  --获取便捷功能使用次数
		local j = 0
	    for i = 1, table.getn(g_YouLongKa2_Dict) do
			g_YouLongKa2_FunUseTimes[i] = { FunId = Get_XParam_INT(j), FunUseTimes = Get_XParam_INT(j+1)}
			j = j+2
	    end
	    
	end
	
	if (event == "UI_COMMAND") and (arg0 == "201205146") then  --获取当前使用的月卡索引
		g_YouLongKa2_CurIndex = Get_XParam_INT(0)
		Player:SetMCardIndex(Get_XParam_INT(0))
	end
	
	if (event == "UI_COMMAND") and (arg0 == "201205153") then  --获取服务截止时间
		local year,mon,day = ANSI2TM(tonumber(Get_XParam_INT(0)))
		local str = ScriptGlobal_Format("#{GJYLK_120517_81}",tostring(year),tostring(mon),tostring(day)) --醒目提示“升级成功”
		PushDebugMessage(str)
	end
	
	if ( event == "UPDATE_DOUBLE_EXP" )  then
		local DT = SystemSetup : GetDoubleExp("remaintime");
        YouLongKa2_Text3:SetProperty("Timer",DT);    
    end
	
	if ( event == "HIDE_ON_SCENE_TRANSED") then
		YouLongKa2_Close()
	end
end

--界面初始化
function YouLongKa2_Init()
	
	for i = 1, table.getn(g_YouLongKa2_BKIcon) do
		g_YouLongKa2_BKIcon[i]:SetProperty("Image", "")
		g_YouLongKa2_BKIcon[i]:Hide()
	end
	
	for i = 1, table.getn(g_YouLongKa2_BKList) do
		g_YouLongKa2_BKList[i]:SetText("")
		g_YouLongKa2_BKList[i]:Disable()
		g_YouLongKa2_BKList[i]:Hide()
	end
	
	for i = 1, table.getn(g_YouLongKa2_BKWindow) do
		g_YouLongKa2_BKWindow[i]:Hide()
	end
	g_YouLongKa2_IsLevelup =-1
	YouLongKa2_Lace3:Show()
	YouLongKa2_Text2:Show()
	YouLongKa2_Text3:Show()
	YouLongKa2_Lace1:Hide()
	YouLongKa2_Text4:Hide()
	YouLongKa2_Lace2:Hide()
	YouLongKa2_Text5:Hide()
	YouLongKa2_LevelUp_Button:Hide()
	YouLongKa2_LevelUp_Button:SetText("")
	YouLongKa2_Button01:SetCheck(0)
	YouLongKa2_Button02:SetCheck(0)
	YouLongKa2_Button03:SetCheck(0)
	YouLongKa2_Button04:SetCheck(0)
	YouLongKa2_Button05:SetCheck(0)
	
end

--左边栏按钮响应逻辑
function YouLongKa2_Update(num)
	if num < 1 or num > g_YouLongKa2_LeftBtnNum then
		return
	end
	YouLongKa2_Init()
	if num == 1 then	--便捷功能服务
		YouLongKa2_Button01:SetCheck(1)
		local idx = 1
		for i = 1, g_YouLongKa2_MaxNum do
			local funcId, funcType = DataPool:GetMCardInfoByIdx(i-1)
			if funcId and funcId >= 1 and funcType == 0 then

			    
				g_YouLongKa2_BKIcon[idx]:SetProperty("Image", g_YouLongKa2_ImageList[funcId])
				g_YouLongKa2_BKIcon[idx]:Show()
				
				g_YouLongKa2_BKList[idx]:SetText(g_YouLongKa2_BKListText[funcId])
				--g_YouLongKa2_BKList[idx]:SetToolTip(g_VIP_ShopToolTips[funcId])  --加ToolTip
				g_YouLongKa2_BKList[idx]:Enable()
				g_YouLongKa2_BKList[idx]:Show()
				g_YouLongKa2_BKId[idx] = funcId
				
				g_YouLongKa2_BKWindow[idx]:Show()
				
				idx = idx + 1
			end
		end
	
	elseif num == 3 then	--游龙卡升级
		YouLongKa2_Button03:SetCheck(1)
	    g_YouLongKa2_IsLevelup =1
	    if g_YouLongKa2_CurIndex == 38000360 then  --亮银卡
			YouLongKa2_LevelUp_Button:SetText("#{GJYLK_120517_74}")
			YouLongKa2_Lace2:Show()
			YouLongKa2_Text5:SetText("#{GJYLK_120517_73}")
			YouLongKa2_Text5:Show()
			YouLongKa2_LevelUp_Button:Show()
			
	    else  --紫金卡
			YouLongKa2_Lace2:Show()
			YouLongKa2_Text5:SetText("#{GJYLK_120517_75}")
			YouLongKa2_Text5:Show()
	    end
			
	elseif num == 2 then	--查询功能情况
		YouLongKa2_Button02:SetCheck(1)
		local name = Player:GetName()
		local str = ScriptGlobal_Format("#{GJYLK_120517_100}",name)
		local nBaibingDay = math.floor( g_Baibing_LeftTime/86400 )
		local nBaibingHour = math.mod(g_Baibing_LeftTime ,86400)/3600
		nBaibingHour = math.floor(nBaibingHour)
		local nBaishouDay = math.floor( g_Baishou_LeftTime/86400 )
		local nBaishouHour = math.mod(g_Baishou_LeftTime ,86400)/3600
		nBaishouHour = math.floor(nBaishouHour)
		
		local strTemp4 = ScriptGlobal_Format("#{GJYLK_120517_91}",tostring(nBaibingDay), tostring(nBaibingHour))
		local strTemp5 = ScriptGlobal_Format("#{BSJT_130114_01}",tostring(nBaishouDay), tostring(nBaishouHour))

		local strTemp1 = ""
		local strTemp2 = ""
		local strTemp3 = ""		--快捷功能：限次和不限次的分开显示
		for i = 1, g_YouLongKa2_MaxNum do
			local funcId, funcType, funcMaxUseTimes = DataPool:GetMCardInfoByIdx(i-1)
			if funcId and funcId >= 1 then
				local strTemp = "#r"
				local funcUsedTimes = -1
				for i = 1, table.getn(g_YouLongKa2_Dict) do
				    if g_YouLongKa2_FunUseTimes[i].FunId == funcId then
					    funcUsedTimes = g_YouLongKa2_FunUseTimes[i].FunUseTimes
					    break
				    end
				end
				if funcUsedTimes >=  funcMaxUseTimes then
					strTemp = strTemp..g_YouLongKa2_Dict[funcId][1]
				else			
					strTemp = strTemp..g_YouLongKa2_Dict[funcId][0]
				end
				if g_YouLongKa2_Dict[funcId].flag == 1 then
					strTemp = strTemp..(funcMaxUseTimes-funcUsedTimes).."/"..funcMaxUseTimes
				end
				
				if g_YouLongKa2_Dict[funcId].type == 1 then
					if g_YouLongKa2_Dict[funcId].flag == 1 then
						strTemp1 = strTemp1..strTemp
					else
						strTemp3 = strTemp3..strTemp
					end
				elseif g_YouLongKa2_Dict[funcId].type == 2 then
					strTemp2 = strTemp2..strTemp
				end
			end
		end
		
		if DataPool:GetIsBaiBing() == 1 then
			str = str.."#r"..strTemp1..strTemp3.."#r"..strTemp2..strTemp4
		else
			str = str.."#r"..strTemp1..strTemp3.."#r"..strTemp2
		end
		
		if Pet:GetIsBaiShou() == 1 then
			str = str.."#r"..strTemp5
		end

		YouLongKa2_Text4:ClearAllElement()
		YouLongKa2_Text4:AddTextElement(str)
		YouLongKa2_Text4:Show()
		YouLongKa2_Lace1:Show()
	
	elseif num == 4 then	--服务注销
		YouLongKa2_Button04:SetCheck(1)
		g_YouLongKa2_IsLevelup =0
		YouLongKa2_LevelUp_Button:SetText("#{GJYLK_120517_83}")
		YouLongKa2_Lace2:Show()
		YouLongKa2_Text5:SetText("#{GJYLK_120517_82}")
		YouLongKa2_Text5:Show()
		YouLongKa2_LevelUp_Button:Show()
		
	
	elseif num == 5 then	--关于便捷功能服务
		YouLongKa2_Button05:SetCheck(1)
		YouLongKa2_Text4:ClearAllElement()
		if g_YouLongKa2_CurIndex == g_YouLongKa2_ItemIndex_1 then
			--YouLongKa2_Text5:SetText("#{GJYLK_120517_102}")
			YouLongKa2_Text4:AddTextElement("#{GJYLK_120517_102}")
		else
			--YouLongKa2_Text5:SetText("#{GJYLK_120517_103}")
			YouLongKa2_Text4:AddTextElement("#{GJYLK_120517_103}")
		end

		YouLongKa2_Text4:Show()
		YouLongKa2_Lace1:Show()
		--YouLongKa2_Lace2:Show()
		--YouLongKa2_Text5:Show()
	end
	
	
end

--关闭界面
function YouLongKa2_Close()
	this:Hide()
end

--月卡升级响应
function YouLongKa2_LevelUp_Clicked()
    if g_YouLongKa2_IsLevelup == 1 then  --升级
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("IsCanLevelUp");
			Set_XSCRIPT_ScriptID(889678);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();	
    else                                 --注销
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("IsCanDeleteService");
			Set_XSCRIPT_ScriptID(889678);
			Set_XSCRIPT_ParamCount(0);
		Send_XSCRIPT();
		
    end
end

--功能按钮响应逻辑
function YouLongKa2_Btn_Clicked(num)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUseMonthCard")
		Set_XSCRIPT_ScriptID(889678)
		Set_XSCRIPT_Parameter(0, g_YouLongKa2_BKId[num])
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end