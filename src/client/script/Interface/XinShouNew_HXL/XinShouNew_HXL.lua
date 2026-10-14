local g_XinShouNew_HXL_Frame_UnifiedPosition;

local g_XinShouNew_HXL_BounsList=
{
	{ItemID=39922518,ItemTabIndex=38004534,Num=1,IsBind=1,ValueCost=140,MaxCount=1,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=8},
	-- {ItemID=39921378,ItemTabIndex=38002172,Num=1,IsBind=0,ValueCost=140,MaxCount=1,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=4}, --big bouns
	{ItemID=39925365,ItemTabIndex=38008615,Num=1,IsBind=0,ValueCost=140,MaxCount=1,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=4}, --big bouns
	{ItemID=39923116,ItemTabIndex=38004273,Num=20,IsBind=1,ValueCost=130,MaxCount=1,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=9},
	{ItemID=39921377,ItemTabIndex=38000437,Num=1,IsBind=0,ValueCost=130,MaxCount=1,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=3},
	{ItemID=39921381,ItemTabIndex=38002177,Num=1,IsBind=0,ValueCost=100,MaxCount=1,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=2},
	{ItemID=39920162,ItemTabIndex=20700055,Num=100,IsBind=0,ValueCost=40,MaxCount=3,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=5},
	{ItemID=39920396,ItemTabIndex=20501003,Num=1,IsBind=1,ValueCost=20,MaxCount=7,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=6},
	{ItemID=39920397,ItemTabIndex=20502003,Num=1,IsBind=1,ValueCost=20,MaxCount=7,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=7},
	{ItemID=39920977,ItemTabIndex=30900077,Num=1,IsBind=0,ValueCost=15,MaxCount=3,IsShowTimes=1,CountMD="MD_HAOXIA_GETBOUNS_COUNT1",CountIndex=1},
	{ItemID=39920329,ItemTabIndex=38000571,Num=1,IsBind=0,ValueCost=10,MaxCount=15,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT2",CountIndex=1}, 
	{ItemID=39920296,ItemTabIndex=38000378,Num=1,IsBind=0,ValueCost=2,MaxCount=75,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT2",CountIndex=2},
	{ItemID=39920163,ItemTabIndex=20700063,Num=2,IsBind=0,ValueCost=1,MaxCount=150,IsShowTimes=0,CountMD="MD_HAOXIA_GETBOUNS_COUNT2",CountIndex=3}, 
}

local g_XinShouNew_HXL_Text1 =
{
}

local g_XinShouNew_HXL_Text2 =
{
}

local g_XinShouNew_HXL_Icon =
{
}

local g_XinShouNew_HXL_BounsTypeNum = 11

local g_XinShouNew_Flag_2023 = 0

local g_XinShouNew_HXL_BK =
{
}
local g_XinShouNew_HX_BKPos = {}

local g_XinShouNew_HX_BKPos_DRJ = { 
[0] = {
		"{{0.000000,14.000000},{0.000000,40.000000}}",
		"{{0.000000,189.000000},{0.000000,40.000000}}",
		"{{0.000000,364.000000},{0.000000,40.000000}}",
		"{{0.000000,539.000000},{0.000000,40.000000}}",
		
		"{{0.000000,14.000000},{0.000000,132.000000}}",
		"{{0.000000,189.000000},{0.000000,132.000000}}",
		"{{0.000000,364.000000},{0.000000,132.000000}}",
		"{{0.000000,539.000000},{0.000000,132.000000}}",
		
		"{{0.000000,14.000000},{1.000000,-95.000000}}",
		"{{0.000000,189.000000},{1.000000,-95.000000}}",
		"{{0.000000,364.000000},{1.000000,-95.000000}}",
		"{{0.000000,539.000000},{1.000000,-95.000000}}",
	},
[1] = {
		nil,
		"{{0.000000,14.000000},{0.000000,40.000000}}",
		nil,
		"{{0.000000,189.000000},{0.000000,40.000000}}",
		
		"{{0.000000,364.000000},{0.000000,40.000000}}",
		"{{0.000000,539.000000},{0.000000,40.000000}}",
		"{{0.000000,14.000000},{0.000000,132.000000}}",
		"{{0.000000,189.000000},{0.000000,132.000000}}",
		
		"{{0.000000,364.000000},{0.000000,132.000000}}",
		"{{0.000000,539.000000},{0.000000,132.000000}}",
		"{{0.000000,14.000000},{1.000000,-95.000000}}",
		"{{0.000000,189.000000},{1.000000,-95.000000}}",
	},
[2] = { -- 1、3、5、6、12   
		[1] = nil,
		[2] = "{{0.000000,14.000000},{0.000000,40.000000}}",
		[3] = nil,
		[4] = "{{0.000000,189.000000},{0.000000,40.000000}}",
		[5] = nil,
		[6] = nil,
		[7] = "{{0.000000,364.000000},{0.000000,40.000000}}",
		[8] = "{{0.000000,539.000000},{0.000000,40.000000}}", 
		[9] = "{{0.000000,14.000000},{0.000000,132.000000}}",
		[10] = "{{0.000000,189.000000},{0.000000,132.000000}}",
		[11] = "{{0.000000,364.000000},{0.000000,132.000000}}", 
		[12] = nil,
		},
}	

--===============================================
-- PreLoad()
--===============================================
function XinShouNew_HXL_PreLoad()
	this:RegisterEvent("XINSHOUNEW_HEROERROAD_GETBOUNS_OPEN",true)
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HAOXIA_EXCHANGE_BOUNS_CONFIRM_OK",true)

end

--===============================================
-- OnEvent()
--===============================================
function XinShouNew_HXL_OnEvent(event)
	if (event == "XINSHOUNEW_HEROERROAD_GETBOUNS_OPEN"  ) then
		if this:IsVisible() then
			this:Hide()
			return
		end
		XinShouNew_HXL_Open()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 8926772 ) then
		local HaoxiaValue = Get_XParam_INT(1)
		local GetBounsTimes1 = Get_XParam_INT(2)
		local GetBounsTimes2 = Get_XParam_INT(3)
		local IsOpenUI = Get_XParam_INT(4)
		g_XinShouNew_Flag_2023 = Get_XParam_INT(5) 
		XinShouNew_HXL_Heroes_SetPos()
		XinShouNew_HXL_Update(HaoxiaValue,GetBounsTimes1,GetBounsTimes2)
		if IsOpenUI == 1 then
			if this:IsVisible() then
				this:Hide()
				return
			end
			XinShouNew_HXL_Open()
		end
	elseif  (event == "HAOXIA_EXCHANGE_BOUNS_CONFIRM_OK" ) then
		local nIndex = tonumber(arg0)
		local uitype = tonumber(arg1)
		if uitype == 1 then
			return
		end
		XinShouNew_HXL_Heroes_ExChange_OK(nIndex)

	elseif (event == "UI_COMMAND" and tonumber(arg0) == 8926773 ) then
		local ret = Get_XParam_INT(1)
		local nIndex = Get_XParam_INT(2)
		if ret == 1 then
			XinShouNew_HXL_OpenMessage(nIndex)
		end
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 8926771 ) then
		local HaoxiaValue = Get_XParam_INT(2)
		local strMsg = ScriptGlobal_Format( "#{XSJNH_180120_242}", HaoxiaValue)
		XinShouNew_HXL_Heroes_ExChangeFrame_Text:SetText(strMsg)

	end
end

--===============================================
-- OnLoad()
--===============================================
function XinShouNew_HXL_OnLoad()
	g_XinShouNew_HXL_Frame_UnifiedPosition = XinShouNew_HXL_Frame:GetProperty("UnifiedPosition")
	XinShouNew_HXL_SetUIPos()
end
--===============================================
-- SetButtonPos()
--===============================================
function XinShouNew_HXL_SetUIPos()

--	g_XinShouNew_HXL_Text1[1] = XinShouNew_HXL_Heroes_ExChange1Item1_Text;
	g_XinShouNew_HXL_Text1[1] = XinShouNew_HXL_Heroes_ExChangeItem1_Text;
	g_XinShouNew_HXL_Text1[2] = XinShouNew_HXL_Heroes_ExChangeItem2_Text;
	g_XinShouNew_HXL_Text1[3] = XinShouNew_HXL_Heroes_ExChangeItem3_Text;
	g_XinShouNew_HXL_Text1[4] = XinShouNew_HXL_Heroes_ExChangeItem4_Text;
	g_XinShouNew_HXL_Text1[5] = XinShouNew_HXL_Heroes_ExChangeItem5_Text;
	g_XinShouNew_HXL_Text1[6] = XinShouNew_HXL_Heroes_ExChangeItem6_Text;
	g_XinShouNew_HXL_Text1[7] = XinShouNew_HXL_Heroes_ExChangeItem7_Text;
	g_XinShouNew_HXL_Text1[8] = XinShouNew_HXL_Heroes_ExChangeItem8_Text;
	g_XinShouNew_HXL_Text1[9] = XinShouNew_HXL_Heroes_ExChangeItem9_Text;
	g_XinShouNew_HXL_Text1[10] = XinShouNew_HXL_Heroes_ExChangeItem10_Text;
	g_XinShouNew_HXL_Text1[11] = XinShouNew_HXL_Heroes_ExChangeItem11_Text;
	g_XinShouNew_HXL_Text1[12] = XinShouNew_HXL_Heroes_ExChangeItem12_Text;

--	g_XinShouNew_HXL_Text2[1] = XinShouNew_HXL_Heroes_ExChange1Item1_Text1;
	g_XinShouNew_HXL_Text2[1] = XinShouNew_HXL_Heroes_ExChangeItem1_Text1;
	g_XinShouNew_HXL_Text2[2] = XinShouNew_HXL_Heroes_ExChangeItem2_Text1;
	g_XinShouNew_HXL_Text2[3] = XinShouNew_HXL_Heroes_ExChangeItem3_Text1;
	g_XinShouNew_HXL_Text2[4] = XinShouNew_HXL_Heroes_ExChangeItem4_Text1;
	g_XinShouNew_HXL_Text2[5] = XinShouNew_HXL_Heroes_ExChangeItem5_Text1;
	g_XinShouNew_HXL_Text2[6] = XinShouNew_HXL_Heroes_ExChangeItem6_Text1;
	g_XinShouNew_HXL_Text2[7] = XinShouNew_HXL_Heroes_ExChangeItem7_Text1;
	g_XinShouNew_HXL_Text2[8] = XinShouNew_HXL_Heroes_ExChangeItem8_Text1;
	g_XinShouNew_HXL_Text2[9] = XinShouNew_HXL_Heroes_ExChangeItem9_Text1;
	g_XinShouNew_HXL_Text2[10] = XinShouNew_HXL_Heroes_ExChangeItem10_Text1;
	g_XinShouNew_HXL_Text2[11] = XinShouNew_HXL_Heroes_ExChangeItem11_Text1;
	g_XinShouNew_HXL_Text2[12] = XinShouNew_HXL_Heroes_ExChangeItem12_Text1;

--	g_XinShouNew_HXL_Icon[1] = XinShouNew_HXL_Heroes_ExChange1Item1_Icon;
	g_XinShouNew_HXL_Icon[1] = XinShouNew_HXL_Heroes_ExChangeItem1_Icon;
	g_XinShouNew_HXL_Icon[2] = XinShouNew_HXL_Heroes_ExChangeItem2_Icon;
	g_XinShouNew_HXL_Icon[3] = XinShouNew_HXL_Heroes_ExChangeItem3_Icon;
	g_XinShouNew_HXL_Icon[4] = XinShouNew_HXL_Heroes_ExChangeItem4_Icon;
	g_XinShouNew_HXL_Icon[5] = XinShouNew_HXL_Heroes_ExChangeItem5_Icon;
	g_XinShouNew_HXL_Icon[6] = XinShouNew_HXL_Heroes_ExChangeItem6_Icon;
	g_XinShouNew_HXL_Icon[7] = XinShouNew_HXL_Heroes_ExChangeItem7_Icon;
	g_XinShouNew_HXL_Icon[8] = XinShouNew_HXL_Heroes_ExChangeItem8_Icon;
	g_XinShouNew_HXL_Icon[9] = XinShouNew_HXL_Heroes_ExChangeItem9_Icon;
	g_XinShouNew_HXL_Icon[10] = XinShouNew_HXL_Heroes_ExChangeItem10_Icon;
	g_XinShouNew_HXL_Icon[11] = XinShouNew_HXL_Heroes_ExChangeItem11_Icon;
	g_XinShouNew_HXL_Icon[12] = XinShouNew_HXL_Heroes_ExChangeItem12_Icon;

	g_XinShouNew_HXL_BK[1] = XinShouNew_HXL_Heroes_ExChangeItem1
	g_XinShouNew_HXL_BK[2] = XinShouNew_HXL_Heroes_ExChangeItem2
	g_XinShouNew_HXL_BK[3] = XinShouNew_HXL_Heroes_ExChangeItem3
	g_XinShouNew_HXL_BK[4] = XinShouNew_HXL_Heroes_ExChangeItem4
	g_XinShouNew_HXL_BK[5] = XinShouNew_HXL_Heroes_ExChangeItem5
	g_XinShouNew_HXL_BK[6] = XinShouNew_HXL_Heroes_ExChangeItem6
	g_XinShouNew_HXL_BK[7] = XinShouNew_HXL_Heroes_ExChangeItem7
	g_XinShouNew_HXL_BK[8] = XinShouNew_HXL_Heroes_ExChangeItem8
	g_XinShouNew_HXL_BK[9] = XinShouNew_HXL_Heroes_ExChangeItem9
	g_XinShouNew_HXL_BK[10] = XinShouNew_HXL_Heroes_ExChangeItem10
	g_XinShouNew_HXL_BK[11] = XinShouNew_HXL_Heroes_ExChangeItem11
	g_XinShouNew_HXL_BK[12] = XinShouNew_HXL_Heroes_ExChangeItem12

	for i = 1, table.getn(g_XinShouNew_HXL_BK) do
		g_XinShouNew_HX_BKPos[i] = g_XinShouNew_HXL_BK[i]:GetProperty("UnifiedPosition"); 
		Lua_TDU_Log("g_XinShouNew_HX_BKPos"..i..":"..g_XinShouNew_HX_BKPos[i]);
	end
end
--===============================================
-- Close()
--===============================================
function XinShouNew_HXL_Close()
	XinShouNew_HXL_Heroes_ReSetPos()
	this:Hide()
end
--===============================================
-- ResetPos()
--===============================================
function XinShouNew_HXL_On_ResetPos()
	XinShouNew_HXL_Frame:SetProperty("UnifiedPosition", g_XinShouNew_HXL_Frame_UnifiedPosition)
end

--===============================================
-- Open()
--===============================================
function  XinShouNew_HXL_Open()
	--PushDebugMessage("open")
	local nCount = table.getn(g_XinShouNew_HXL_BounsList)
--PushDebugMessage("nCount="..nCount)
	for i=1,nCount do
		local isShow = 1
		if Player:GetData("IsOriginalJD") == 1 then 
			if g_XinShouNew_HXL_BounsList[i].ItemTabIndex == 38004534 or g_XinShouNew_HXL_BounsList[i].ItemTabIndex == 38004273 then
				isShow = 0
			end
		end
		if Player:GetData("Is2606S") == 1 then 
			if i == 1 or i == 3 or i == 5 or i == 6 or i == 12 then
				isShow = 0
			end
		end
		if isShow == 1 then 
			local cost = g_XinShouNew_HXL_BounsList[i].ValueCost
			local strMsg = ScriptGlobal_Format( "#{XSJNH_180120_239}", cost)
			g_XinShouNew_HXL_Text1[i]:SetText(strMsg) 
			local theAction = DataPool:CreateActionItemForShow(g_XinShouNew_HXL_BounsList[i].ItemID, g_XinShouNew_HXL_BounsList[i].Num)
			g_XinShouNew_HXL_Icon[i] : SetActionItem(theAction:GetID())

		end
	end
	
	if g_XinShouNew_Flag_2023 == 1 then 
		XinShouNew_HXL_Heroes_ExChange1FrameBk_New:Show()
		XinShouNew_HXL_Heroes_ExChange1FrameBk_L:Hide()
		XinShouNew_HXL_Heroes_ExChange1FrameBk_R:Hide()
	else
		XinShouNew_HXL_Heroes_ExChange1FrameBk_New:Hide()
		XinShouNew_HXL_Heroes_ExChange1FrameBk_L:Show()
		XinShouNew_HXL_Heroes_ExChange1FrameBk_R:Show()
	end
	
	local XinShouNew_HX_BKPos = g_XinShouNew_HX_BKPos_DRJ[0]
	if Player:GetData("IsOriginalJD") == 1 then 
		XinShouNew_HX_BKPos = g_XinShouNew_HX_BKPos_DRJ[1]
	end 
	if Player:GetData("Is2606S") == 1 then 
		XinShouNew_HX_BKPos = g_XinShouNew_HX_BKPos_DRJ[2]
	end
	for i = 1, table.getn(g_XinShouNew_HXL_BK) do
		if XinShouNew_HX_BKPos[i] ~= nil then 
			g_XinShouNew_HXL_BK[i]:Show()
			g_XinShouNew_HXL_BK[i]:SetProperty("UnifiedPosition", XinShouNew_HX_BKPos[i]); 
			g_XinShouNew_HX_BKPos[i] = g_XinShouNew_HXL_BK[i]:GetProperty("UnifiedPosition"); 
		else
			g_XinShouNew_HXL_BK[i]:Hide()
			g_XinShouNew_HX_BKPos[i] = g_XinShouNew_HXL_BK[i]:GetProperty("UnifiedPosition"); 
		end
	end

	this:Show()
end

function XinShouNew_HXL_GetSingleBounsTimes(param,nIndex)
	--接口待添加
	local nTimes = 0
	local ParamIndex = g_XinShouNew_HXL_BounsList[nIndex].CountIndex
	local MD_forTimes =  g_XinShouNew_HXL_BounsList[nIndex].CountMD

	if MD_forTimes == "MD_HAOXIA_GETBOUNS_COUNT1" then
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
	if MD_forTimes == "MD_HAOXIA_GETBOUNS_COUNT2" then
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

function XinShouNew_HXL_Update(HaoxiaValue,GetBounsTimes1,GetBounsTimes2)

	local strMsg = ScriptGlobal_Format( "#{XSJNH_180120_242}", HaoxiaValue)
	if g_XinShouNew_Flag_2023 == 1 then
		strMsg = ScriptGlobal_Format( "#{XSJNH_230209_76}", HaoxiaValue)
	end
	XinShouNew_HXL_Heroes_ExChangeFrame_Text:SetText(strMsg)


	local nCount = table.getn(g_XinShouNew_HXL_BounsList)
	for i=1,nCount do
		local isShow = 1
		if Player:GetData("IsOriginalJD") == 1 then 
			if g_XinShouNew_HXL_BounsList[i].ItemTabIndex == 38004534 or g_XinShouNew_HXL_BounsList[i].ItemTabIndex == 38004273 then
				isShow = 0
			end
		end
		if Player:GetData("Is2606S") == 1 then 
			if i== 1 or i == 3 or i == 5 or i == 6 or i == 12 then
				isShow = 0
			end
		end
		if isShow == 1 then
		
		local nMaxTimes = g_XinShouNew_HXL_BounsList[i].MaxCount
		local GetBounsTimes = GetBounsTimes1
		if g_XinShouNew_HXL_BounsList[i].CountMD == "MD_HAOXIA_GETBOUNS_COUNT1" then
			GetBounsTimes = GetBounsTimes1
		end
		if g_XinShouNew_HXL_BounsList[i].CountMD == "MD_HAOXIA_GETBOUNS_COUNT2" then
			GetBounsTimes = GetBounsTimes2
		end

		local NowTimes = XinShouNew_HXL_GetSingleBounsTimes(GetBounsTimes,i)
		local strMsg = ""
		if g_XinShouNew_HXL_BounsList[i].IsShowTimes == 1 then
			strMsg = ScriptGlobal_Format( "#{XSJNH_180124_257}", NowTimes,nMaxTimes)
		end
		if g_XinShouNew_HXL_BounsList[i].IsShowTimes == 0 then
			strMsg = "#{XSJNH_180125_259}"
		end
		g_XinShouNew_HXL_Text2[i]:SetText(strMsg)

		end
	end

end

function XinShouNew_HXL_Heroes_ExChange_Clicked(nIndex)
	--PushDebugMessage("nIndex="..nIndex)
	if nIndex < 1 or nIndex > table.getn(g_XinShouNew_HXL_BounsList) then
		return
	end
--	local itemname =PlayerPackage:GetItemName( g_XinShouNew_HXL_BounsList[nIndex].ItemTabIndex )
--	local strMsg = ScriptGlobal_Format( "#{XSJNH_180131_271}", g_XinShouNew_HXL_BounsList[nIndex].ValueCost,g_XinShouNew_HXL_BounsList[nIndex].Num,itemname)
--	PushEvent("HAOXIA_EXCHANGE_BOUNS_CONFIRM", strMsg,nIndex);
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ExChangeBounsCheckForMessage");
		Set_XSCRIPT_ScriptID(892677);
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();
end

function XinShouNew_HXL_OpenMessage(nIndex)
	if nIndex < 1 or nIndex > table.getn(g_XinShouNew_HXL_BounsList) then
		return
	end
	local itemname =PlayerPackage:GetItemName( g_XinShouNew_HXL_BounsList[nIndex].ItemTabIndex )
	local strMsg = ScriptGlobal_Format( "#{XSJNH_180131_271}", g_XinShouNew_HXL_BounsList[nIndex].ValueCost,g_XinShouNew_HXL_BounsList[nIndex].Num,itemname)
	if g_XinShouNew_Flag_2023 == 1 then 
		strMsg = ScriptGlobal_Format( "#{XSJNH_230209_77}", g_XinShouNew_HXL_BounsList[nIndex].ValueCost,g_XinShouNew_HXL_BounsList[nIndex].Num,itemname)
	end
	 		
	
	PushEvent("HAOXIA_EXCHANGE_BOUNS_CONFIRM", strMsg, nIndex, 0);
end

function XinShouNew_HXL_Heroes_ExChange_OK(nIndex)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ExChangeBouns");
		Set_XSCRIPT_ScriptID(892677);
		Set_XSCRIPT_Parameter(0,nIndex)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();
end


function XinShouNew_HXL_Heroes_SetPos()
	if g_XinShouNew_Flag_2023 == 0 then 
		return
	end
	 	
	for i = 3, table.getn(g_XinShouNew_HXL_BK) do 
		g_XinShouNew_HXL_BK[i]:SetProperty("UnifiedPosition",g_XinShouNew_HX_BKPos[i-2]); 
		Lua_TDU_Log("g_XinShouNew_HXL_BK"..i..":"..g_XinShouNew_HX_BKPos[i-2]);
	end

	g_XinShouNew_HXL_BK[1]:Hide()
	g_XinShouNew_HXL_BK[2]:Hide()
end

function XinShouNew_HXL_Heroes_ReSetPos()   
	for i = 1, table.getn(g_XinShouNew_HXL_BK) do
		g_XinShouNew_HXL_BK[i]:Show()
		g_XinShouNew_HXL_BK[i]:SetProperty("UnifiedPosition",g_XinShouNew_HX_BKPos[i]); 
		Lua_TDU_Log("g_XinShouNew_HX_BKPos"..i..":"..g_XinShouNew_HX_BKPos[i]);
	end 
end