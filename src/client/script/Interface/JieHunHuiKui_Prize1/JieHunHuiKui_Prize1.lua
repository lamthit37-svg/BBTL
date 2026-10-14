----------------------
-- JieHunHuiKui_Prize1 ----- !!!reloadscript =JieHunHuiKui_Prize1
----------------------
local g_JieHunHuiKui_Prize1_UnifiedPosition = nil
local g_JieHunHuiKui_Prize1_CurIndex = 0

--礼盒信息
g_JieHunHuiKui_Prize1_Gift = 
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

function JieHunHuiKui_Prize1_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--===============================================
-- OnLoad()
--===============================================
function JieHunHuiKui_Prize1_OnLoad()
	g_JieHunHuiKui_Prize1_UnifiedPosition = JieHunHuiKui_Prize1_Frame:GetProperty("UnifiedPosition")	
end

--===============================================
-- OnEvent()
--===============================================
function JieHunHuiKui_Prize1_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 89173901) then
		local snum = Get_XParam_INT(0)
		if (snum == nil) or (snum ~= 3) then--只用于三选一
			return
		end
		local index = Get_XParam_INT(1)
		if (index == nil) or (index < 1 or index > 12) then
			return
		end	
		if this:IsVisible() then
			JieHunHuiKui_Prize1_OnHiden()
		end
		g_JieHunHuiKui_Prize1_CurIndex = index
		JieHunHuiKui_Prize1_Show()
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		JieHunHuiKui_Prize1_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		JieHunHuiKui_Prize1_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		JieHunHuiKui_Prize1_OnHiden()
	end
end

function JieHunHuiKui_Prize1_ResetPos()
		JieHunHuiKui_Prize1_Frame:SetProperty("UnifiedPosition",g_JieHunHuiKui_Prize1_UnifiedPosition)
end

function JieHunHuiKui_Prize1_OnHiden()
	g_JieHunHuiKui_Prize1_CurIndex = 0
	this:Hide()
end

function JieHunHuiKui_Prize1_Show()		
	if g_JieHunHuiKui_Prize1_CurIndex == nil or g_JieHunHuiKui_Prize1_CurIndex < 1 or g_JieHunHuiKui_Prize1_CurIndex > 12 then
		return
	end
		
	local tGift = g_JieHunHuiKui_Prize1_Gift[g_JieHunHuiKui_Prize1_CurIndex]
	if tGift == nil then
		return
	end
	
	local strTitle = ScriptGlobal_Format("#{JHJL_160106_25}", PlayerPackage:GetItemName(tGift.giftId))
	JieHunHuiKui_Prize1_DragTitle:SetText(strTitle)
	
	local strMsg = ""
	if g_JieHunHuiKui_Prize1_CurIndex >=1 and g_JieHunHuiKui_Prize1_CurIndex <= 4 then
		strMsg = ScriptGlobal_Format("#{JHJL_160106_26}", 1, PlayerPackage:GetItemName(tGift.yhid), tGift.qscount)
	else
		strMsg = tGift.msg
	end
	JieHunHuiKui_Prize1_Info:SetText(strMsg)
		
	if g_JieHunHuiKui_Prize1_CurIndex >=9 and g_JieHunHuiKui_Prize1_CurIndex <=12 then 
		JieHunHuiKui_Prize1_Image1:SetProperty("Image", "set:PaySelectReward1 image:PaySelectReward1_1"); --极光羽翼
		--JieHunHuiKui_Prize1_Image2:SetProperty("Image", "set:PaySelectReward image:JieHunHuiKuiSelectPrize_2"); --天河灵鹊
		JieHunHuiKui_Prize1_Image2:SetProperty("Image", "set:PaySelectReward1 image:PaySelectReward1_5"); --金鞍映雪
		JieHunHuiKui_Prize1_Image3:SetProperty("Image", "set:PaySelectReward1 image:PaySelectReward1_4"); --玉枕兰舟
	else --兼容旧的礼盒
		JieHunHuiKui_Prize1_Image1:SetProperty("Image", "set:PaySelectReward image:JieHunHuiKuiSelectPrize_1");
		JieHunHuiKui_Prize1_Image2:SetProperty("Image", "set:PaySelectReward image:JieHunHuiKuiSelectPrize_2");
		JieHunHuiKui_Prize1_Image3:SetProperty("Image", "set:PaySelectReward image:JieHunHuiKuiSelectPrize_3"); --旋转木马	
	end	
				
	local strItem1 = ""
	local strItem2 = ""
	local strItem3 = ""
	if g_JieHunHuiKui_Prize1_CurIndex >=9 and g_JieHunHuiKui_Prize1_CurIndex <=12 then --新礼盒
		strItem1 = ScriptGlobal_Format("#{JHJL_200722_01}", tGift.daytime)
		strItem2 = ScriptGlobal_Format("#{JHJL_160106_28}", tGift.daytime)
		strItem3 = ScriptGlobal_Format("#{JHJL_160106_29}", tGift.daytime)
	else
		strItem1 = ScriptGlobal_Format("#{JHJL_160106_27}", tGift.daytime) --兼容旧礼盒
		strItem2 = ScriptGlobal_Format("#{JHJL_160106_28}", tGift.daytime)
		strItem3 = ScriptGlobal_Format("#{JHJL_180209_48}", tGift.daytime)  --旋转木马
	end
	JieHunHuiKui_Prize1_Button1:SetText(strItem1)
	JieHunHuiKui_Prize1_Button2:SetText(strItem2)
	JieHunHuiKui_Prize1_Button3:SetText(strItem3)
		
	this:Show()		
end

function JieHunHuiKui_Prize1_Select(index)
	if index < 1 or index > 3 then
		return
	end
	
	if g_JieHunHuiKui_Prize1_CurIndex == nil or g_JieHunHuiKui_Prize1_CurIndex < 1 or g_JieHunHuiKui_Prize1_CurIndex > 12 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientActivateOnce" )
		Set_XSCRIPT_ScriptID(891739)
		Set_XSCRIPT_Parameter(0,g_JieHunHuiKui_Prize1_CurIndex)
		Set_XSCRIPT_Parameter(1,index)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	

	JieHunHuiKui_Prize1_OnHiden()
end