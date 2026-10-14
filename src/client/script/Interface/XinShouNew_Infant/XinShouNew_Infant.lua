
local nSelectIndex = 0;
local checkBox_items = {}
local checkBox_icons = {}

local cTitle;
local cInfo;

local itemids = 
{
	[1] = {60008013,60108013,60208013,60308013},   --橙色名饰典籍礼盒
	[2] = {60005013,60105013,60205013,60305013},  --子女身法典籍礼盒
	[3] = {60008003,60108003,60208003,60308003},  
	[4] = {60004013,60104013,60204013,60304013},  
}

local boxType = 1;
--===============================================
-- PreLoad()
--===============================================
function XinShouNew_Infant_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

--===============================================
-- OnLoad()
--===============================================
function XinShouNew_Infant_OnLoad()
	checkBox_items[1] =  XinShouNew_Infant_Clinet1_iconAnimate;
	checkBox_items[2] =  XinShouNew_Infant_Clinet2_iconAnimate;
	checkBox_items[3] =  XinShouNew_Infant_Clinet3_iconAnimate;
	checkBox_items[4] =  XinShouNew_Infant_Clinet4_iconAnimate;
	checkBox_icons[1] = XinShouNew_Infant_Clinet1_icon
	checkBox_icons[2] = XinShouNew_Infant_Clinet2_icon
	checkBox_icons[3] = XinShouNew_Infant_Clinet3_icon
	checkBox_icons[4] = XinShouNew_Infant_Clinet4_icon
	cTitle = XinShouNew_Infant_DragTitle
	cInfo = XinShouNew_Infant_Info
	XinShouNew_Infant_UpdateUI()

end

function XinShouNew_Infant_UpdateUI()

	for i, v in pairs(checkBox_items) do 
		v:Hide()
	end
	for i, v in pairs(checkBox_icons) do 
		local theAction = DataPool:CreateActionItemForShow(itemids[boxType][i], 1)
		if theAction:GetID() ~= 0 then
			v:SetActionItem(theAction:GetID());
			v:Show();
		else
			v:SetActionItem(-1);
			v:Hide()
		end
	end
	
	if boxType == 2 then
		cTitle:SetText("#{YCLB_190819_40}")
		cInfo:SetText("#{YCLB_190819_41}")
	elseif boxType == 4 then
		cTitle:SetText("#{JQGFC_220115_95}")
		cInfo:SetText("#{JQGFC_220115_96}")
	end
end

--===============================================
-- OnEvent()
--===============================================
function XinShouNew_Infant_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 2018012701 ) then
		local bIsShow = Get_XParam_INT(0);
		boxType = 1;
		if bIsShow == 1 then
			XinShouNew_Infant_UpdateUI()
			this:Show();
		else
			XinShouNew_Infant_OnClose();
		end
	end
	
	if( event == "UI_COMMAND" and tonumber(arg0) == 50610401 ) then
		local bIsShow = Get_XParam_INT(0);
		boxType = 3;
		if bIsShow == 1 then
			XinShouNew_Infant_UpdateUI()
			this:Show();
		else
			XinShouNew_Infant_OnClose();
		end
	end
	
	if( event == "UI_COMMAND" and tonumber(arg0) == 91020909 ) then
		local bIsShow = Get_XParam_INT(0);
		boxType = 2;
		if bIsShow == 1 then
			XinShouNew_Infant_UpdateUI()
			this:Show();
		else
			XinShouNew_Infant_OnClose();
		end
	end
	
	if( event == "UI_COMMAND" and tonumber(arg0) == 88892401 ) then
		local bIsShow = Get_XParam_INT(0);
		boxType = 4;
		if bIsShow == 1 then
			XinShouNew_Infant_UpdateUI()
			this:Show();
		else
			XinShouNew_Infant_OnClose();
		end
	end

	if event == "HIDE_ON_SCENE_TRANSED" then
		Jueqing_Fuchi_Close()
	end
end

function XinShouNew_Infant_Confirm()
	if boxType == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnChildGiftCard" )
			Set_XSCRIPT_ScriptID( 892691 )
			Set_XSCRIPT_Parameter( 0, nSelectIndex )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	elseif boxType == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnSelectItem" )
			Set_XSCRIPT_ScriptID( 893245 )
			Set_XSCRIPT_Parameter( 0, nSelectIndex )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	elseif boxType == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnChildGiftCard" )
			Set_XSCRIPT_ScriptID( 506104 )
			Set_XSCRIPT_Parameter( 0, nSelectIndex )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	elseif boxType == 4 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnChildGiftCard" )
			Set_XSCRIPT_ScriptID( 888924 )
			Set_XSCRIPT_Parameter( 0, nSelectIndex )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
end

function XinShouNew_Infant_Select(nIndex)
	if checkBox_items[nSelectIndex] then 
		checkBox_items[nSelectIndex]:Hide();
	end
	nSelectIndex = nIndex;
	if checkBox_items[nSelectIndex] then 
		checkBox_items[nSelectIndex]:Show();
	end
end

function XinShouNew_Infant_OnClose()
	XinShouNew_Infant_Select(0)
	this:Hide();
end
