--国庆系列 砍价界面

local g_NationalDay_KanJia_Frame_UnifiedPosition

local g_NationalDay_KanJia_Num = 0;
local g_NationalDay_KanJia_NumLimit = 400;

local g_NationalDay_KanJia_LowCut = 0;
local g_NationalDay_KanJia_Cut = 0;
local g_NationalDay_KanJia_KanJiaLing = 0;
local g_NationalDay_KanJia_ItemId = 0;
local g_NationalDay_KanJia_CurIndex = -1;

function NationalDay_KanJia_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	
end

function NationalDay_KanJia_OnLoad()

	g_NationalDay_KanJia_Frame_UnifiedPosition = NationalDay_KanJia_Frame:GetProperty("UnifiedPosition") 
	
end

--=========
-- Event
--=========
function NationalDay_KanJia_OnEvent(event) 
	if(event == "UI_COMMAND" and tonumber(arg0) == 89315802) then -- 
				
		g_NationalDay_KanJia_ItemId = Get_XParam_INT(0)
		if g_NationalDay_KanJia_ItemId == 0 then
			NationalDay_KanJia_Close()
			return
		end
		
		NationalDay_KanJia_Animate:Hide()
		
		g_NationalDay_KanJia_CurIndex = Get_XParam_INT(1)
		g_NationalDay_KanJia_LowCut = Get_XParam_INT(2)
		g_NationalDay_KanJia_Cut = Get_XParam_INT(3)
		g_NationalDay_KanJia_KanJiaLing = Get_XParam_INT(4) 
		
		NationalDay_KanJia_Open()
		this:Show()
		
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 89315805) then --播放特效
	
		if Get_XParam_INT(0) == 1 then
			NationalDay_KanJia_Animate:Show()
			NationalDay_KanJia_Animate:Play(true)
		end
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		NationalDay_KanJia_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		NationalDay_KanJia_Close()

	elseif event == "ADJEST_UI_POS" then

		NationalDay_KanJia_On_ResetPos()
		
	elseif(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil then
			NationalDay_KanJia_UpdateDataItem()		
		end
	
	end

end
 
--=========
-- 重置
--=========
function NationalDay_KanJia_On_ResetPos()

	NationalDay_KanJia_Frame:SetProperty("UnifiedPosition", g_NationalDay_KanJia_Frame_UnifiedPosition)

end

--=========
-- 关闭
--=========
function NationalDay_KanJia_Close() 

	this:Hide()
	
end

--=========
-- 砍价令
--=========
function NationalDay_KanJia_UpdateDataItem()	
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(38002871)
	local str = ScriptGlobal_Format("#{GQKJ_190722_102}", itemcount)
	NationalDay_KanJia_HaveNum:SetText(str)
	g_NationalDay_KanJia_KanJiaLing = tonumber(itemcount)	
		
	if g_NationalDay_KanJia_KanJiaLing == 0 then
		g_NationalDay_KanJia_Num = 0
		NationalDay_KanJia_ItemNumText:SetText("0")	
		NationalDay_KanJia_ItemNumText:Disable()
		NationalDay_KanJia_ItemNumText:SetProperty("DefaultEditBox", "False");
	else	
		NationalDay_KanJia_ItemNumText:SetText("1")
		NationalDay_KanJia_ItemNumText:Enable()
		NationalDay_KanJia_ItemNumText:SetProperty("DefaultEditBox", "True");
	end
end	

--=========
-- 打开
--=========
function NationalDay_KanJia_Open() 

	local theAction = DataPool:CreateActionItemForShow(g_NationalDay_KanJia_ItemId, 1)
	if theAction:GetID() ~= 0 then
		NationalDay_KanJia_Item:SetActionItem( theAction:GetID() );
	else
		NationalDay_KanJia_Item:SetActionItem( -1 );
	end
	
	local str = ScriptGlobal_Format("#{GQKJ_190722_190}", g_NationalDay_KanJia_LowCut / 10)
	--最低折扣
	NationalDay_KanJia_FloorNum:SetText(str)
	
	if g_NationalDay_KanJia_LowCut == g_NationalDay_KanJia_Cut then
		NationalDay_KanJia_FloorNum:Hide()
	else
		NationalDay_KanJia_FloorNum:Show()
	end
	
	--进度条
	NationalDay_KanJia_Progress:SetProgress((100-g_NationalDay_KanJia_Cut),(100-g_NationalDay_KanJia_LowCut))
	
	str = ScriptGlobal_Format("#{GQKJ_190722_189}", g_NationalDay_KanJia_Cut / 10)
	--当前折扣
	NationalDay_KanJia_SaleNum:SetText(str)
	
	local fX = 15 --NationalDay_KanJia_Progress:GetProperty("AbsoluteXPosition")
	local width = NationalDay_KanJia_Progress:GetProperty("AbsoluteWidth")
	local offX = fX + width * (100-g_NationalDay_KanJia_Cut) / (100-g_NationalDay_KanJia_LowCut)
	NationalDay_KanJia_SaleNum:SetProperty("AbsoluteXPosition", offX);	
	
	local item_name = DataPool:Lua_GetItemNameByIndex(g_NationalDay_KanJia_ItemId)
	NationalDay_KanJia_Name:SetText("#L"..item_name)
			
	if g_NationalDay_KanJia_KanJiaLing == 0 then
		g_NationalDay_KanJia_Num = 0
		NationalDay_KanJia_ItemNumText:SetText("0")		
		NationalDay_KanJia_ItemNumText:Disable()
		NationalDay_KanJia_ItemNumText:SetProperty("DefaultEditBox", "False");
	else
		NationalDay_KanJia_ItemNumText:Enable()
		NationalDay_KanJia_ItemNumText:SetText("1")
		NationalDay_KanJia_ItemNumText:SetProperty("DefaultEditBox", "True");
	end
	
	str = ScriptGlobal_Format("#{GQKJ_190722_102}", g_NationalDay_KanJia_KanJiaLing)
	NationalDay_KanJia_HaveNum:SetText(str)
	
end

--===============================================
-- +
--===============================================
function NationalDay_KanJia_Add_Clicked()

	local szNum = NationalDay_KanJia_ItemNumText:GetText();
	if szNum == "" then 
		szNum = "0"
	end

	local nNum = szNum + 1;
	
	if( nNum > g_NationalDay_KanJia_KanJiaLing )then
		nNum = g_NationalDay_KanJia_KanJiaLing
		if g_NationalDay_KanJia_KanJiaLing == 0 then
			PushDebugMessage("#{GQKJ_190722_214}")
		else
			PushDebugMessage("#{GQKJ_190722_99}")
		end
	end
	
	if( nNum > g_NationalDay_KanJia_NumLimit )then
		nNum = g_NationalDay_KanJia_NumLimit
		PushDebugMessage("#{GQKJ_190722_99}")
	end
		
	NationalDay_KanJia_ItemNumText:SetText(tostring(nNum));
	
	g_NationalDay_KanJia_Num = tonumber(nNum)

end

--===============================================
-- -
--===============================================
function NationalDay_KanJia_Desc_Clicked()

	local szNum = NationalDay_KanJia_ItemNumText:GetText();
	if szNum == "" then 
		szNum = "0"
	end
	
	local nNum = szNum - 1;

	if( nNum <= 0 )then
		if g_NationalDay_KanJia_KanJiaLing == 0 then
			nNum = 0
			PushDebugMessage("#{GQKJ_190722_214}")
		else
			nNum = 1
			PushDebugMessage("#{GQKJ_190722_100}")
		end
	end
	
	NationalDay_KanJia_ItemNumText:SetText(tostring(nNum));
	
	g_NationalDay_KanJia_Num = tonumber(nNum)

end

--===============================================
-- 最大
--===============================================
function NationalDay_KanJia_Max_Clicked()

	local num = tonumber(NationalDay_KanJia_ItemNumText:GetText())
	
	if g_NationalDay_KanJia_KanJiaLing > g_NationalDay_KanJia_NumLimit then
		NationalDay_KanJia_ItemNumText:SetText(tostring(g_NationalDay_KanJia_NumLimit))
		
		g_NationalDay_KanJia_Num = g_NationalDay_KanJia_NumLimit
	else	
		NationalDay_KanJia_ItemNumText:SetText(tostring(g_NationalDay_KanJia_KanJiaLing))
	
		g_NationalDay_KanJia_Num = g_NationalDay_KanJia_KanJiaLing
		
	end
	
	if g_NationalDay_KanJia_KanJiaLing == 0 then
		PushDebugMessage("#{GQKJ_190722_214}")
	elseif g_NationalDay_KanJia_Num == g_NationalDay_KanJia_KanJiaLing or g_NationalDay_KanJia_Num == g_NationalDay_KanJia_NumLimit then
		PushDebugMessage("#{GQKJ_190722_99}")
	end
	
end

--===============================================
-- 编辑
--===============================================
function NationalDay_KanJia_Changed()

	local szNum = NationalDay_KanJia_ItemNumText:GetText()
	local num = 1
	
	if szNum == nil then
		return
	elseif szNum == "" then
		num = 1
		NationalDay_KanJia_ItemNumText:SetText(tostring(num))
	elseif szNum == "0" then
		if g_NationalDay_KanJia_KanJiaLing ~= 0 then
			num = 1
			NationalDay_KanJia_ItemNumText:SetText(tostring(num))
		end
	else
		num = tonumber(szNum)
	end
	
	g_NationalDay_KanJia_Num = num
	
	if (num > g_NationalDay_KanJia_KanJiaLing and g_NationalDay_KanJia_KanJiaLing > 0) then
		g_NationalDay_KanJia_Num = g_NationalDay_KanJia_KanJiaLing
		NationalDay_KanJia_ItemNumText:SetText(tostring(g_NationalDay_KanJia_KanJiaLing))
	end	
	
	if (num > g_NationalDay_KanJia_NumLimit) then
		g_NationalDay_KanJia_Num = g_NationalDay_KanJia_NumLimit
		NationalDay_KanJia_ItemNumText:SetText(tostring(g_NationalDay_KanJia_NumLimit))
	end	
end

--===============================================
-- 砍价
--===============================================
function NationalDay_KanJia_Buy_Click()

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NatiaonalShopCut")
		Set_XSCRIPT_ScriptID(893158) 
		Set_XSCRIPT_Parameter(0, 1)  
		Set_XSCRIPT_Parameter(1, g_NationalDay_KanJia_CurIndex) 
		Set_XSCRIPT_Parameter(2, g_NationalDay_KanJia_Num) 
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end
