----------------------
-- JieHunHuiKui_Prize2 ---
----------------------
local g_JieHunHuiKui_Prize2_UnifiedPosition = nil
local g_JieHunHuiKui_Prize2_CurIndex = 0

--礼盒信息
g_JieHunHuiKui_Prize2_Gift = 
{
	--礼盒id,烟花id,情诗恋曲id,情诗恋曲count,n选1的坐骑
	[1] = {giftId = 38001557, yhid = 30505193, qsid = 38001332, qscount = 1, daytime = 3, },
	[2] = {giftId = 38001558, yhid = 38001567, qsid = 38001332, qscount = 2, daytime = 7, },
	[3] = {giftId = 38001559, yhid = 38001175, qsid = 38001332, qscount = 3, daytime = 7, },
	[4] = {giftId = 38001560, yhid = 38001173, qsid = 38001332, qscount = 4, daytime = 15, },
	
	[5] = {giftId = 38002063, yhid = 30505193, qsid = 38001332, qscount = 1, daytime = 3, msg = ""},
	[6] = {giftId = 38002064, yhid = 38001567, qsid = 38001332, qscount = 2, daytime = 7, msg = "#{JHJL_170711_39}"},
	[7] = {giftId = 38002065, yhid = 38001175, qsid = 38001332, qscount = 3, daytime = 15, msg = "#{JHJL_170714_44}"},
	[8] = {giftId = 38002066, yhid = 38001173, qsid = 38001332, qscount = 4, daytime = 30, msg = "#{JHJL_170714_46}"},

	[9] = {giftId = 38002152, yhid = 30509158, qsid = 38001332, qscount = 1, daytime = 3, msg = ""},
	[10] = {giftId = 38002153, yhid = 38001567, qsid = 38001332, qscount = 2, daytime = 7, msg = "#{JHJL_170711_39}"},
	[11] = {giftId = 38002154, yhid = 38001175, qsid = 38001332, qscount = 3, daytime = 15, msg = "#{JHJL_170714_44}"},
	[12] = {giftId = 38002155, yhid = 38001173, qsid = 38001332, qscount = 4, daytime = 30, msg = "#{JHJL_170714_46}"},

}

function JieHunHuiKui_Prize2_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--===============================================
-- OnLoad()
--===============================================
function JieHunHuiKui_Prize2_OnLoad()
	g_JieHunHuiKui_Prize2_UnifiedPosition = JieHunHuiKui_Prize2_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function JieHunHuiKui_Prize2_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 89173901) then
		local snum = Get_XParam_INT(0)
		if (snum == nil) or (snum ~= 2) then--只用于二选一
			return
		end
		local index = Get_XParam_INT(1)
		if (index == nil) or (index < 1 or index > 12) then
			return
		end	

		if this:IsVisible() then
			JieHunHuiKui_Prize2_OnHiden()
		end
		g_JieHunHuiKui_Prize2_CurIndex = index
		JieHunHuiKui_Prize2_Show()
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		JieHunHuiKui_Prize2_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		JieHunHuiKui_Prize2_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		JieHunHuiKui_Prize2_OnHiden()
	end
end

function JieHunHuiKui_Prize2_ResetPos()
		JieHunHuiKui_Prize2_Frame:SetProperty("UnifiedPosition",g_JieHunHuiKui_Prize2_UnifiedPosition)
end

function JieHunHuiKui_Prize2_OnHiden()
	g_JieHunHuiKui_Prize2_CurIndex = 0
	this:Hide()
end

function JieHunHuiKui_Prize2_Show()		
	if g_JieHunHuiKui_Prize2_CurIndex == nil or g_JieHunHuiKui_Prize2_CurIndex < 1 or g_JieHunHuiKui_Prize2_CurIndex > 12 then
		return
	end
		
	local tGift = g_JieHunHuiKui_Prize2_Gift[g_JieHunHuiKui_Prize2_CurIndex]
	if tGift == nil then
		return
	end
	
	local strTitle = ScriptGlobal_Format("#{JHJL_160106_25}", PlayerPackage:GetItemName(tGift.giftId))
	JieHunHuiKui_Prize2_DragTitle:SetText(strTitle)
	
	local strMsg = ""
	if g_JieHunHuiKui_Prize2_CurIndex >=1 and g_JieHunHuiKui_Prize2_CurIndex <= 4 then
		strMsg = ScriptGlobal_Format("#{JHJL_160106_26}", 1, PlayerPackage:GetItemName(tGift.yhid), tGift.qscount)
	else
		strMsg = tGift.msg
	end
	JieHunHuiKui_Prize2_Info:SetText(strMsg)
	
	if g_JieHunHuiKui_Prize2_CurIndex >=9 and g_JieHunHuiKui_Prize2_CurIndex <= 12 then
		JieHunHuiKui_Prize2_Image1:SetProperty("Image", "set:PaySelectReward1 image:PaySelectReward1_1"); --极光羽翼
		--JieHunHuiKui_Prize2_Image2:SetProperty("Image", "set:PaySelectReward image:JieHunHuiKuiSelectPrize_2"); --天河灵鹊
		JieHunHuiKui_Prize2_Image2:SetProperty("Image", "set:PaySelectReward1 image:PaySelectReward1_5"); --金鞍映雪
	else --兼容旧礼盒
		JieHunHuiKui_Prize2_Image1:SetProperty("Image", "set:PaySelectReward image:JieHunHuiKuiSelectPrize_1");
		JieHunHuiKui_Prize2_Image2:SetProperty("Image", "set:PaySelectReward image:JieHunHuiKuiSelectPrize_2");
	end	
	
	local strItem1 = ""
	local strItem2 = ""
	if g_JieHunHuiKui_Prize2_CurIndex >=9 and g_JieHunHuiKui_Prize2_CurIndex <= 12 then
		strItem1 = ScriptGlobal_Format("#{JHJL_200722_01}", tGift.daytime)
		strItem2 = ScriptGlobal_Format("#{JHJL_160106_28}", tGift.daytime)
	else --兼容旧礼盒
		strItem1 = ScriptGlobal_Format("#{JHJL_160106_27}", tGift.daytime)
		strItem2 = ScriptGlobal_Format("#{JHJL_160106_28}", tGift.daytime)
	end

	JieHunHuiKui_Prize2_Button1:SetText(strItem1)
	JieHunHuiKui_Prize2_Button2:SetText(strItem2)
		
	this:Show()		
end

function JieHunHuiKui_Prize2_Select(index)
	if index < 1 or index > 2 then
		return
	end
	if g_JieHunHuiKui_Prize2_CurIndex == nil or g_JieHunHuiKui_Prize2_CurIndex < 1 or g_JieHunHuiKui_Prize2_CurIndex > 12 then
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(891739)
		Set_XSCRIPT_Parameter(0,g_JieHunHuiKui_Prize2_CurIndex)
		Set_XSCRIPT_Parameter(1,index)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
			
	JieHunHuiKui_Prize2_OnHiden()
end