--家园换装
local MAX_OBJ_DISTANCE = 3.0;
local g_nMyBieYeStyle = 0
local g_nCurSelect = 0							-- 当前选择的编号
local g_nCurStyleStatus = 0 					-- 当前选择状态 0 未拥有，1 拥有不永久，2 永久
local g_BieYeStyleIndex = {}					-- 拥有风格ID
local g_BieYeStyleTime = {}						-- 拥有风格ID对应有效期
local g_BieYeStyleInfo = {}						-- 读表资源
local g_BieYeStyleButtonList = {}
local g_BieYeStyleFenye = 0

local objCared = -1
local g_BieYeButtonCDTime = 120
local g_BieYeLastClickTime = 0
local g_BieYeHuanZhuang_Frame_UnifiedPosition;

--物品在背包中的位置
local	g_posItem	= -1	
--==================================
-- BieYeHuanZhuang_PreLoad
--==================================
function BieYeHuanZhuang_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("BIEYESTYLEUPDATE")
end

--==================================
-- BieYeHuanZhuang_OnLoad
--==================================
function BieYeHuanZhuang_OnLoad()
	g_BieYeHuanZhuang_Frame_UnifiedPosition=BieYeHuanZhuang_Frame:GetProperty("UnifiedPosition");
	BieYeHuanZhuang_InitSourceInfo()
	BieYeHuanZhuangt_JiHuo_Button:SetText("#{JYHZ_170824_16}")
end

--==================================
-- BieYeHuanZhuang_OnEvent
--==================================
function BieYeHuanZhuang_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 201708261) then
		if (this:IsVisible()) then
			return
		end
		local xx = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(xx);
		if objCared == -1 then
			PushDebugMessage("server传过来的数据有问题。");
			return;
		end
		
		BieYeHuanZhuang_LoadData()
		BeginCareObject_BieYeHuanZhuang(objCared)
		
		this:Show();
		BieYeHuanZhuang_OnShown(1)
		BieYeHuanZhuang_SelButtonIndex(g_nMyBieYeStyle)
	elseif (event == "BIEYESTYLEUPDATE") then
		if (this:IsVisible()) then
			BieYeHuanZhuang_LoadData()
			BieYeHuanZhuang_OnShown(1)
			BieYeHuanZhuang_SelButtonIndex(g_nMyBieYeStyle)
		end
	elseif (event == "OBJECT_CARED_EVENT") then
		if(not this:IsVisible() ) then
			return;
		end
		if(tonumber(arg0) ~= objCared) then
			BieYeHuanZhuang_Close()
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then			
			--取消关心
			BieYeHuanZhuang_Close()
		end
		
	elseif (event == "ADJEST_UI_POS" ) then
		BieYeHuanZhuang_Frame_On_ResetPos()
	
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BieYeHuanZhuang_Frame_On_ResetPos()
	end
end

--==================================
-- 读表资源
--==================================
function BieYeHuanZhuang_InitSourceInfo()
	local index = 1
	local nId,nName,nDes,nIconPic,nIconPic2,nYardPic,nRoomPic
	while(true)
	do
		nId,nName,nDes,nIconPic,nIconPic2,nYardPic,nRoomPic,nYardComfort,nHouseComfort = BieYeUI:GetBieYeStyleInfo(index)
		if nId == -1 then
			break;
		else
			local value = {}
			value.nId = nId
			value.nName = nName
			value.nDes = nDes
			value.nIconPic = nIconPic
			value.nIconPic2 = nIconPic2
			value.nYardPic = nYardPic
			value.nRoomPic = nRoomPic
			value.nYardComfort = nYardComfort
			value.nHouseComfort = nHouseComfort
			g_BieYeStyleInfo[index] = value
			index = index + 1
		end
	end
end

--==================================
-- 载入家园风格数据 
--==================================
function BieYeHuanZhuang_LoadData()
	g_nMyBieYeStyle, g_BieYeStyleIndex[1], g_BieYeStyleTime[1],  g_BieYeStyleIndex[2], g_BieYeStyleTime[2], g_BieYeStyleIndex[3], g_BieYeStyleTime[3],
	 g_BieYeStyleIndex[4], g_BieYeStyleTime[4], g_BieYeStyleIndex[5], g_BieYeStyleTime[5], g_BieYeStyleIndex[6], g_BieYeStyleTime[6],
	  g_BieYeStyleIndex[7], g_BieYeStyleTime[7], g_BieYeStyleIndex[8], g_BieYeStyleTime[8], g_BieYeStyleIndex[9], g_BieYeStyleTime[9],
	   g_BieYeStyleIndex[10], g_BieYeStyleTime[10] = BieYeUI:GetBieYeStyleData()
end

function BieYeHuanZhuang_UpdateFenYe(FenYeIndex)
	g_BieYeStyleFenye = FenYeIndex
	if FenYeIndex == 1 then	--庭院
		BieYeHuanZhuang_FenYe1:SetCheck(1)
		BieYeHuanZhuang_FenYe2:SetCheck(0)
	elseif FenYeIndex == 2 then --居室
		BieYeHuanZhuang_FenYe1:SetCheck(0)
		BieYeHuanZhuang_FenYe2:SetCheck(1)
	end
end

--==================================
-- 根据分页显示界面
--==================================
function BieYeHuanZhuang_OnShown(FenYeIndex)
	BieYeHuanZhuang_UpdateFenYe(FenYeIndex)
	BieYeHuanZhuang_ShowButtonList()
end

function BieYeHuanZhuang_FenYeClick(FenYeIndex)
	BieYeHuanZhuang_OnShown(FenYeIndex)
	BieYeHuanZhuang_SelButtonIndex(g_nCurSelect)
end
--==================================
-- 显示buttonlist
--==================================
function BieYeHuanZhuang_ShowButtonList()
	BieYeHuanZhuang_ButtonList:CleanAllElement("BieYeHuanZhuang")
	g_BieYeStyleButtonList = {}
	for nIndex = 1,table.getn(g_BieYeStyleInfo) do
		BieYeStyle_AddButton(g_BieYeStyleInfo[nIndex])
	end
	BieYeHuanZhuang_ButtonList:Flash()
end

--==================================
-- BieYeStyle_AddButton 
--==================================
function BieYeStyle_AddButton(ButtonInfo)
	if(nil == ButtonInfo) then
		return
	end
	local ItemBar = BieYeHuanZhuang_ButtonList:AddItemElement("BieYeHuanZhuang", "LEFT", "BieYeHuanZhuang","" ,"")
	ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	ItemBar:SetText1("#gFF0FA0"..ButtonInfo.nName)
	
	--当前item状态 0 未拥有，1 拥有不永久，2 永久
	local nCurItemState = 0
	local strStyletime = "#{JYHZ_170824_11}"
	for i = 1, table.getn(g_BieYeStyleIndex) do
		if ButtonInfo.nId == g_BieYeStyleIndex[i] then
			if g_BieYeStyleTime[i] < 1 then
				nCurItemState = 2
				strStyletime = "#{JYHZ_170824_14}"
				break
			end
			nCurItemState = 1
			strStyletime = BieYeHuanZhuang_ShowTime(g_BieYeStyleTime[i])
			break
		end
	end
	
	--设置有效期
	ItemBar:SetText2(strStyletime)
	
	--设置续期按钮
	
	if nCurItemState == 2 then 
		ItemBar:SetButton1Hide()
	elseif nCurItemState == 1 then
		ItemBar:SetButton1Show()
		ItemBar:SetButton1State(true)
		ItemBar:SetButton1Text("#{JYHZ_170824_45}")
	else
		ItemBar:SetButton1Show()
		ItemBar:SetButton1Text("#{JYHZ_170824_15}")
		ItemBar:SetButton1State(true)
	end
	
	--设置图片
	local nIconPic = ButtonInfo.nIconPic2
	if nCurItemState > 0 then 
		nIconPic = ButtonInfo.nIconPic
	end
	local sPos,_ = string.find(nIconPic," ");
	local IconImageSet = string.sub(nIconPic,5,sPos-1);
	local IconIamge = string.sub(nIconPic,sPos+7)
	ItemBar:SetImage1(IconImageSet,IconIamge)
	
	--设置“使用中”图标
	if g_nMyBieYeStyle == ButtonInfo.nId then
		ItemBar:SetImage2Show()
	else
		ItemBar:SetImage2Hide()
	end
	
	--设置舒适度
	local strComfort = ""
	if nCurItemState == 2 then
		strComfort = ScriptGlobal_Format("#{JYHZ_170824_68}", ButtonInfo.nYardComfort, ButtonInfo.nHouseComfort)
	end
	if ButtonInfo.nYardComfort == 0 and ButtonInfo.nHouseComfort == 0 then
		strComfort = ""
	end
	ItemBar:SetText3(strComfort)

	table.insert(g_BieYeStyleButtonList,ItemBar)
end

--==================================
-- 点击botton
--==================================
function BieYeHuanZhuang_OnItemClick()

	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	BieYeHuanZhuang_UpdateFenYe(1)
	
	if nIndex >= 0 then
		BieYeHuanZhuang_SelButtonIndex(nIndex + 1)
		BieYeHuanZhuang_ButtonList:Flash()
	end
	
end

--==================================
-- 点击button响应 更新按钮
--==================================
function BieYeHuanZhuang_SelButtonIndex(nIndex)
		if(0 ~= g_nCurSelect ) and nil ~= g_BieYeStyleButtonList[g_nCurSelect] then
			g_BieYeStyleButtonList[g_nCurSelect]:SetBarButtonSelected(false)
		end
		if(0 ~= nIndex and nil ~= g_BieYeStyleButtonList[nIndex]) then
			g_BieYeStyleButtonList[nIndex]:SetBarButtonSelected(true)
		end	
		g_nCurSelect = nIndex
		BieYeHuanZhuang_OnSelButtonIndex(nIndex)
end

--==================================
-- 点击button响应 更新界面显示
--==================================
function BieYeHuanZhuang_OnSelButtonIndex(nIndex)
	g_nCurStyleStatus = 0 --0 未拥有，1 拥有不永久，2 永久
	for i = 1, table.getn(g_BieYeStyleIndex) do
		if nIndex == g_BieYeStyleIndex[i] then
			if g_BieYeStyleTime[i] < 1 then
				g_nCurStyleStatus = 2
				break
			end
			g_nCurStyleStatus = 1
			break
		end
	end
	
	if g_BieYeStyleFenye == 1 then
		BieYeHuanZhuang_image:SetProperty("Image", g_BieYeStyleInfo[nIndex].nYardPic)
	elseif g_BieYeStyleFenye == 2 then 
		BieYeHuanZhuang_image:SetProperty("Image", g_BieYeStyleInfo[nIndex].nRoomPic)
	end

end

--==================================
-- 点击激活或使用响应
--==================================
function BieYeHuanZhuang_OnActiveClick()
	if g_nCurStyleStatus > 0 then -- 使用
		if g_nMyBieYeStyle == g_nCurSelect then
			PushDebugMessage("#{JYHZ_170824_61}")
			return 
		end
		local curTime = OSAPI:GetTickCount()
		if ( curTime - g_BieYeLastClickTime < g_BieYeButtonCDTime * 1000) then
			local nStrTime = ScriptGlobal_Format("#{JYHZ_170824_67}", g_BieYeButtonCDTime - math.floor( (curTime - g_BieYeLastClickTime)/1000 ))
			PushDebugMessage(nStrTime)
			return
		end
		g_BieYeLastClickTime = curTime
	
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ChangeBieYeStyle");
			Set_XSCRIPT_ScriptID(892505);
			Set_XSCRIPT_Parameter(0, g_nCurSelect);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
		return
	end
	PushDebugMessage("#{JYHZ_170824_70}")
end


function BieYeHuanZhuang_DoActiveStyle( nStyle )
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ActiveBieYeStyleCheck");
		Set_XSCRIPT_ScriptID(892505);
		Set_XSCRIPT_Parameter(0, objCared);
		Set_XSCRIPT_Parameter(1, nStyle);
		Set_XSCRIPT_Parameter(2, 1);
		Set_XSCRIPT_Parameter(3, 1);
		Set_XSCRIPT_ParamCount(4);
	Send_XSCRIPT();
end

--==================================
-- 点击续期响应
--==================================
function BieYeHuanZhuang_OnExtendClick()
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))
	if nIndex >= 0 then
		nIndex = nIndex + 1
	else
		return
	end
	if not g_BieYeStyleInfo[nIndex] then
		return
	end
	
	--当前item状态 0 未拥有，1 拥有不永久，2 永久
	local nCurItemState = 0
	for i = 1, table.getn(g_BieYeStyleIndex) do
		if g_BieYeStyleInfo[nIndex].nId == g_BieYeStyleIndex[i] then
			if g_BieYeStyleTime[i] < 1 then
				nCurItemState = 2
				break
			end
			nCurItemState = 1
			break
		end
	end
	
	--点击激活走激活逻辑
	if nCurItemState == 0 then
		BieYeHuanZhuang_DoActiveStyle(nIndex)
		return
	end
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ExtendBieYeStyleCheck");
		Set_XSCRIPT_ScriptID(892505);
		Set_XSCRIPT_Parameter(0, objCared);
		Set_XSCRIPT_Parameter(1, nIndex);
		Set_XSCRIPT_Parameter(2, 2);
		Set_XSCRIPT_Parameter(3, 1);
		Set_XSCRIPT_ParamCount(4);
	Send_XSCRIPT();
end
--==================================
--关闭
--==================================
function BieYeHuanZhuang_Close()
	g_nCurSelect = 0
	g_nCurStyleStatus = 0
	StopCareObject_BieYeHuanZhuang(objCared)
	this:Hide();	
end

--==================================
--开始关心NPC
--==================================
function BeginCareObject_BieYeHuanZhuang(objCaredId)
	objCared = objCaredId;
	this:CareObject(objCared, 1, "BieYeHuanZhuang");
end

--==================================
--停止对某NPC的关心
--==================================
function StopCareObject_BieYeHuanZhuang(objCaredId)
	this:CareObject(objCaredId, 0, "BieYeHuanZhuang");
	objCared = -1;
end


function BieYeHuanZhuang_Frame_On_ResetPos()
  BieYeHuanZhuang_Frame:SetProperty("UnifiedPosition", g_BieYeHuanZhuang_Frame_UnifiedPosition);
end

--==================================
--计算显示时间
--==================================
function BieYeHuanZhuang_ShowTime(nTime)
	local str = ""
	-- 永久 
	if nTime < 1 then 
		str = "#{TXKS_170208_38}"
		return str
	end
	
	-- 计算日期
	local nYear = math.floor(nTime/1000000) + 2000
	local nMonth =  math.mod(math.floor(nTime/10000), 100)
	local nDay = math.mod(math.floor(nTime/100), 100)
	local nHour = math.mod(nTime, 100)
	
	str = ScriptGlobal_Format("#{TXKS_170208_37}", nYear.."年"..nMonth.."月"..nDay.."日"..nHour.."时")
	
	return str
end 


