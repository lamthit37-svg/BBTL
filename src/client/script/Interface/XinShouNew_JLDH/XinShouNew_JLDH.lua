local g_XinShouNew_JLDH_Frame_UnifiedPosition;

local g_XinShouNew_JLDH_BounsList=
{
	{ItemID=39923116,ItemTabIndex=38004273,Num=20,IsBind=1,ValueCost=130,MaxCount=1,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1_2023",CountIndex=1},
	{ItemID=39921377,ItemTabIndex=38000437,Num=1,IsBind=0,ValueCost=130,MaxCount=1,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1_2023",CountIndex=2},
	{ItemID=39921381,ItemTabIndex=38002177,Num=1,IsBind=0,ValueCost=100,MaxCount=1,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1_2023",CountIndex=3},
	{ItemID=39920162,ItemTabIndex=20700055,Num=100,IsBind=0,ValueCost=40,MaxCount=3,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT1_2023",CountIndex=4},
	{ItemID=39920396,ItemTabIndex=20501003,Num=1,IsBind=1,ValueCost=20,MaxCount=7,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT1_2023",CountIndex=5},
	{ItemID=39920397,ItemTabIndex=20502003,Num=1,IsBind=1,ValueCost=20,MaxCount=7,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT1_2023",CountIndex=6},
	{ItemID=39920977,ItemTabIndex=30900077,Num=1,IsBind=0,ValueCost=15,MaxCount=3,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1_2023",CountIndex=7},
	{ItemID=39920329,ItemTabIndex=38000571,Num=1,IsBind=0,ValueCost=10,MaxCount=15,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT1_2023",CountIndex=8},
	{ItemID=39920296,ItemTabIndex=38000378,Num=1,IsBind=0,ValueCost=2,MaxCount=75,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT1_2023",CountIndex=9},
	{ItemID=39920163,ItemTabIndex=20700063,Num=2,IsBind=0,ValueCost=1,MaxCount=150,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT2_2023",CountIndex=1},

}

local g_XinShouNew_JLDH_Text1 =
{
}

local g_XinShouNew_JLDH_Text2 =
{
}

local g_XinShouNew_JLDH_Icon =
{
}


--===============================================
-- PreLoad()
--===============================================
function XinShouNew_JLDH_PreLoad()
	this:RegisterEvent("XINSHOUNEW_HEROERROAD_GETBOUNS_OPEN",true)
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HAOXIA_EXCHANGE_BOUNS_CONFIRM_OK",true)

end

--===============================================
-- OnEvent()
--===============================================
function XinShouNew_JLDH_OnEvent(event)
	if (event == "XINSHOUNEW_HEROERROAD_GETBOUNS_OPEN"  ) then
		if this:IsVisible() then
			this:Hide()
			return
		end
		XinShouNew_JLDH_Open()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2303222 ) then
		local HaoxiaValue = Get_XParam_INT(1)
		local GetBounsTimes1 = Get_XParam_INT(2)
		local GetBounsTimes2 = Get_XParam_INT(3)
		local IsOpenUI = Get_XParam_INT(4)
		XinShouNew_JLDH_Update(HaoxiaValue,GetBounsTimes1,GetBounsTimes2)
		if IsOpenUI == 1 then
			if this:IsVisible() then
				this:Hide()
				return
			end
			XinShouNew_JLDH_Open()
		end
	elseif  (event == "HAOXIA_EXCHANGE_BOUNS_CONFIRM_OK" ) then
		local nIndex = tonumber(arg0)
		local uitype = tonumber(arg1)
		if uitype == 0 then
			return
		end
		XinShouNew_JLDH_Heroes_ExChange_OK(nIndex)

	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2303223 ) then
		local ret = Get_XParam_INT(1)
		local nIndex = Get_XParam_INT(2)
		if ret == 1 then
			XinShouNew_JLDH_OpenMessage(nIndex)
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 2303221 ) then
		local HaoxiaValue = Get_XParam_INT(2)
		local strMsg = ScriptGlobal_Format( "#{XSJNH_230209_76}", HaoxiaValue)
		XinShouNew_JLDH_Heroes_ExChangeFrame_Text:SetText(strMsg)

	end
end

--===============================================
-- OnLoad()
--===============================================
function XinShouNew_JLDH_OnLoad()
	g_XinShouNew_JLDH_Frame_UnifiedPosition = XinShouNew_JLDH_Frame:GetProperty("UnifiedPosition")
	XinShouNew_JLDH_SetUIPos()
end
--===============================================
-- SetButtonPos()
--===============================================
function XinShouNew_JLDH_SetUIPos()

--	g_XinShouNew_JLDH_Text1[1] = XinShouNew_JLDH_Heroes_ExChange1Item1_Text;
	g_XinShouNew_JLDH_Text1[1] = XinShouNew_JLDH_Heroes_ExChangeItem1_Text;
	g_XinShouNew_JLDH_Text1[2] = XinShouNew_JLDH_Heroes_ExChangeItem2_Text;
	g_XinShouNew_JLDH_Text1[3] = XinShouNew_JLDH_Heroes_ExChangeItem3_Text;
	g_XinShouNew_JLDH_Text1[4] = XinShouNew_JLDH_Heroes_ExChangeItem4_Text;
	g_XinShouNew_JLDH_Text1[5] = XinShouNew_JLDH_Heroes_ExChangeItem5_Text;
	g_XinShouNew_JLDH_Text1[6] = XinShouNew_JLDH_Heroes_ExChangeItem6_Text;
	g_XinShouNew_JLDH_Text1[7] = XinShouNew_JLDH_Heroes_ExChangeItem7_Text;
	g_XinShouNew_JLDH_Text1[8] = XinShouNew_JLDH_Heroes_ExChangeItem8_Text;
	g_XinShouNew_JLDH_Text1[9] = XinShouNew_JLDH_Heroes_ExChangeItem9_Text;
	g_XinShouNew_JLDH_Text1[10] = XinShouNew_JLDH_Heroes_ExChangeItem10_Text;

--	g_XinShouNew_JLDH_Text2[1] = XinShouNew_JLDH_Heroes_ExChange1Item1_Text1;
	g_XinShouNew_JLDH_Text2[1] = XinShouNew_JLDH_Heroes_ExChangeItem1_Text1;
	g_XinShouNew_JLDH_Text2[2] = XinShouNew_JLDH_Heroes_ExChangeItem2_Text1;
	g_XinShouNew_JLDH_Text2[3] = XinShouNew_JLDH_Heroes_ExChangeItem3_Text1;
	g_XinShouNew_JLDH_Text2[4] = XinShouNew_JLDH_Heroes_ExChangeItem4_Text1;
	g_XinShouNew_JLDH_Text2[5] = XinShouNew_JLDH_Heroes_ExChangeItem5_Text1;
	g_XinShouNew_JLDH_Text2[6] = XinShouNew_JLDH_Heroes_ExChangeItem6_Text1;
	g_XinShouNew_JLDH_Text2[7] = XinShouNew_JLDH_Heroes_ExChangeItem7_Text1;
	g_XinShouNew_JLDH_Text2[8] = XinShouNew_JLDH_Heroes_ExChangeItem8_Text1;
	g_XinShouNew_JLDH_Text2[9] = XinShouNew_JLDH_Heroes_ExChangeItem9_Text1;
	g_XinShouNew_JLDH_Text2[10] = XinShouNew_JLDH_Heroes_ExChangeItem10_Text1;

--	g_XinShouNew_JLDH_Icon[1] = XinShouNew_JLDH_Heroes_ExChange1Item1_Icon;
	g_XinShouNew_JLDH_Icon[1] = XinShouNew_JLDH_Heroes_ExChangeItem1_Icon;
	g_XinShouNew_JLDH_Icon[2] = XinShouNew_JLDH_Heroes_ExChangeItem2_Icon;
	g_XinShouNew_JLDH_Icon[3] = XinShouNew_JLDH_Heroes_ExChangeItem3_Icon;
	g_XinShouNew_JLDH_Icon[4] = XinShouNew_JLDH_Heroes_ExChangeItem4_Icon;
	g_XinShouNew_JLDH_Icon[5] = XinShouNew_JLDH_Heroes_ExChangeItem5_Icon;
	g_XinShouNew_JLDH_Icon[6] = XinShouNew_JLDH_Heroes_ExChangeItem6_Icon;
	g_XinShouNew_JLDH_Icon[7] = XinShouNew_JLDH_Heroes_ExChangeItem7_Icon;
	g_XinShouNew_JLDH_Icon[8] = XinShouNew_JLDH_Heroes_ExChangeItem8_Icon;
	g_XinShouNew_JLDH_Icon[9] = XinShouNew_JLDH_Heroes_ExChangeItem9_Icon;
	g_XinShouNew_JLDH_Icon[10] = XinShouNew_JLDH_Heroes_ExChangeItem10_Icon;

end
--===============================================
-- Close()
--===============================================
function XinShouNew_JLDH_Close()
	this:Hide()
end
--===============================================
-- ResetPos()
--===============================================
function XinShouNew_JLDH_On_ResetPos()
	XinShouNew_JLDH_Frame:SetProperty("UnifiedPosition", g_XinShouNew_JLDH_Frame_UnifiedPosition)
end

--===============================================
-- Open()
--===============================================
function  XinShouNew_JLDH_Open()
	--PushDebugMessage("open")
	local nCount = table.getn(g_XinShouNew_JLDH_BounsList)
--PushDebugMessage("nCount="..nCount)
	for i=1,nCount do
		local cost = g_XinShouNew_JLDH_BounsList[i].ValueCost
		local strMsg = ScriptGlobal_Format( "#{XSJNH_180120_239}", cost)
		g_XinShouNew_JLDH_Text1[i]:SetText(strMsg)
		
		-- local nSpecKaJi89 = Player : GetData("SPECKAJI89") 
		-- if g_XinShouNew_JLDH_BounsList[i].ItemID == 39921378 or g_XinShouNew_JLDH_BounsList[i].ItemID == 38006013 then
		-- 	if nSpecKaJi89 ~= nil and nSpecKaJi89 > 0 then 
		-- 		g_XinShouNew_JLDH_BounsList[i].ItemID = 38006013
		-- 		g_XinShouNew_JLDH_BounsList[i].ItemTabIndex = 38006013
		-- 	else
		-- 		g_XinShouNew_JLDH_BounsList[i].ItemID = 39921378
		-- 		g_XinShouNew_JLDH_BounsList[i].ItemTabIndex = 38002172
		-- 	end 
		-- end
		local theAction = DataPool:CreateActionItemForShow(g_XinShouNew_JLDH_BounsList[i].ItemID, g_XinShouNew_JLDH_BounsList[i].Num)
		g_XinShouNew_JLDH_Icon[i] : SetActionItem(theAction:GetID())

	end
	this:Show()
end

function XinShouNew_JLDH_GetSingleBounsTimes(param,nIndex)
	--接口待添加
	local nTimes = 0
	local ParamIndex = g_XinShouNew_JLDH_BounsList[nIndex].CountIndex
	local MD_forTimes =  g_XinShouNew_JLDH_BounsList[nIndex].CountMD

	if MD_forTimes == "MD_HAOXIA_GETBOUNS_COUNT1_2023" then
		if ParamIndex == 1 then
			nTimes = math.mod(param,10)
		elseif ParamIndex == 2 then
			local temp = math.mod(param,100)
			nTimes = math.floor(temp/10)
		elseif ParamIndex == 3 then
			local temp = math.mod(param,1000)
			nTimes = math.floor(temp/100)
		elseif ParamIndex == 4 then
			local temp = math.mod(param,10000)
			nTimes = math.floor(temp/1000)
		elseif ParamIndex == 5 then
			local temp = math.mod(param,100000)
			nTimes = math.floor(temp/10000)
		elseif ParamIndex == 6 then
			local temp = math.mod(param,1000000)
			nTimes = math.floor(temp/100000)
		elseif ParamIndex == 7 then
			local temp = math.mod(param,10000000)
			nTimes = math.floor(temp/1000000)
		elseif ParamIndex == 8 then
			local temp = math.mod(param,100000000)
			nTimes = math.floor(temp/10000000)
		elseif ParamIndex == 9 then
			local temp = math.mod(param,1000000000)
			nTimes = math.floor(temp/100000000)
		end
	end
	if MD_forTimes == "MD_HAOXIA_GETBOUNS_COUNT2_2023" then
		if paramIndex == 1 then
			nTimes = mod(param,1000)
		elseif paramIndex == 2 then
			local temp = mod(param,1000000)
			nTimes = floor(temp/1000)
		elseif paramIndex == 3 then
			local temp = mod(param,1000000000)
			nTimes = floor(temp/1000000)
		end
	end


	return nTimes
end

function XinShouNew_JLDH_Update(HaoxiaValue,GetBounsTimes1,GetBounsTimes2)

	local strMsg = ScriptGlobal_Format( "#{XSJNH_230209_76}", HaoxiaValue)
	XinShouNew_JLDH_Heroes_ExChangeFrame_Text:SetText(strMsg)


	local nCount = table.getn(g_XinShouNew_JLDH_BounsList)
	for i=1,nCount do
		local nMaxTimes = g_XinShouNew_JLDH_BounsList[i].MaxCount
		local GetBounsTimes = GetBounsTimes1
		if g_XinShouNew_JLDH_BounsList[i].CountMD == "MD_HAOXIA_GETBOUNS_COUNT1_2023" then
			GetBounsTimes = GetBounsTimes1
		end
		if g_XinShouNew_JLDH_BounsList[i].CountMD == "MD_HAOXIA_GETBOUNS_COUNT2_2023" then
			GetBounsTimes = GetBounsTimes2
		end

		local NowTimes = XinShouNew_JLDH_GetSingleBounsTimes(GetBounsTimes,i)
		local strMsg = ""
		if g_XinShouNew_JLDH_BounsList[i].IsShowTimes == 1 then
			strMsg = ScriptGlobal_Format( "#{XSJNH_180124_257}", NowTimes,nMaxTimes)
		end
		if g_XinShouNew_JLDH_BounsList[i].IsShowTimes == 0 then
			strMsg = "#{XSJNH_180125_259}"
		end
		g_XinShouNew_JLDH_Text2[i]:SetText(strMsg)

	end

end

function XinShouNew_JLDH_Heroes_ExChange_Clicked(nIndex)
	--PushDebugMessage("nIndex="..nIndex)
	if nIndex < 1 or nIndex > table.getn(g_XinShouNew_JLDH_BounsList) then
		return
	end
--	local itemname =PlayerPackage:GetItemName( g_XinShouNew_JLDH_BounsList[nIndex].ItemTabIndex )
--	local strMsg = ScriptGlobal_Format( "#{XSJNH_180131_271}", g_XinShouNew_JLDH_BounsList[nIndex].ValueCost,g_XinShouNew_JLDH_BounsList[nIndex].Num,itemname)
--	PushEvent("HAOXIA_EXCHANGE_BOUNS_CONFIRM", strMsg,nIndex);
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ExChangeBounsCheckForMessage_2023");
		Set_XSCRIPT_ScriptID(892677);
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();
end

function XinShouNew_JLDH_OpenMessage(nIndex)
	if nIndex < 1 or nIndex > table.getn(g_XinShouNew_JLDH_BounsList) then
		return
	end
	local itemname =PlayerPackage:GetItemName( g_XinShouNew_JLDH_BounsList[nIndex].ItemTabIndex )
	local strMsg = ScriptGlobal_Format( "#{XSJNH_180131_271}", g_XinShouNew_JLDH_BounsList[nIndex].ValueCost,g_XinShouNew_JLDH_BounsList[nIndex].Num,itemname)
	PushEvent("HAOXIA_EXCHANGE_BOUNS_CONFIRM", strMsg, nIndex, 1);
end

function XinShouNew_JLDH_Heroes_ExChange_OK(nIndex)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ExChangeBouns_2023");
		Set_XSCRIPT_ScriptID(892677);
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();
end
