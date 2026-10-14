--鬼市批量使用界面
--Author:XiongJiaCheng
--Time:2021-07-23
--g_ItemID:物品ID
--g_max：当前背包中g_ItemID最大数量

--控件列表
local m_Controls = {} 				--控件列表
local g_Frame_UnifiedPosition

local g_ItemID = -1

local g_max = 1 --最大使用数量
local defaultNum = 1 --默认使用数量

local g_objID = -1
local g_objCared = -1

local function clean()
    g_objID = -1
    g_objCared= -1

end

function GuiShi_Exchange_PreLoad()

    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("ADJEST_UI_POS",false)           -- 游戏窗口尺寸发生了变化
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		    -- 离开场景
	this:RegisterEvent("OBJECT_CARED_EVENT",false)

end

function GuiShi_Exchange_OnLoad()

    m_Controls = 
    {
		m_Frame = GuiShi_Exchange_Frame,
	}
    
    g_Frame_UnifiedPosition=m_Controls.m_Frame:GetProperty("UnifiedPosition")

end

function GuiShi_Exchange_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 40213301 ) then
		clean()
		g_objID = Get_XParam_INT(0) --targetId
		g_objCared = DataPool : GetNPCIDByServerID(tonumber(g_objID))
		if g_objCared == -1 then
			PushDebugMessage("server传过来的数据有问题。")
			return
		end
		if nil ~= g_objCared and g_objCared > 0 then
			this:CareObject(g_objCared, 1, "GuiShi_Exchange")
		end

		g_ItemID = Get_XParam_INT(1) --兑换物品ID
		g_max = Get_XParam_INT(2)	--可以使用最大数
		defaultNum = g_max --默认使用数量
		GuiShi_Exchange_NumberInput:SetText(defaultNum)

		-- 增加界面互斥关闭逻辑MessageBox_Self
		if(IsWindowShow("MessageBox_Self")) then
			CloseWindow("MessageBox_Self", true)
		end
		
		GuiShi_Exchange_Open(g_ItemID, g_max)
		OpenWindow("Packet")
		
    elseif (event == "ADJEST_UI_POS") then
		GuiShi_Exchange_Frame_On_ResetPos()    
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        GuiShi_Exchange_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
		GuiShi_Exchange_Close_Clicked()
	elseif ( event == "OBJECT_CARED_EVENT" and this:IsVisible() ) then
		if(tonumber(arg0) ~= g_objCared) then
			return
        end
		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
        if(arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy") then
            GuiShi_Exchange_Close_Clicked()
        end
    end
    
end

--===============================================
-- ResetPos()
--===============================================
function GuiShi_Exchange_Frame_On_ResetPos()
    m_Controls.m_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--===============================================
-- Show()
--===============================================
function GuiShi_Exchange_Open(g_ItemID, g_max)
	--物品名字
	--local itemname1 = DataPool:Lua_GetItemNameByIndex(38004042)	
	local itemname = DataPool:Lua_GetItemNameByIndex(g_ItemID)
	--#cfff263您当前拥有#G3级宝石碎片兑换券#cfff263的数量为#G%s0#cfff263个，可以兑换#G%s1#cfff263的数量为#G%s2#cfff263个。	
	GuiShi_Exchange_Info:SetText(ScriptGlobal_Format("#{HSBSSP_210714_01}",g_max,itemname,g_max)) 

	GuiShi_Exchange_NumberInput:SetProperty("DefaultEditBox", "True")
	GuiShi_Exchange_NumberInput:SetSelected(0, -1)

	this:Show()
end

--===============================================
-- 确定按键（回调各自函数）xjc
--===============================================
function GuiShi_Exchange_Buy_Clicked()
	if defaultNum <= 0 then
        PushDebugMessage("#{HSBSSP_210714_05}")
        return
	end
	this:Hide()
	
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("GUISHIClicked")
		Set_XSCRIPT_ScriptID(402133)
		Set_XSCRIPT_Parameter(0, g_ItemID)
		Set_XSCRIPT_Parameter(1, defaultNum)
		Set_XSCRIPT_Parameter(2, g_objID)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT();
	
	return

end

--===============================================
-- Close() xjc
--===============================================
function GuiShi_Exchange_Close_Clicked()
	if nil ~= g_objCared and g_objCared > 0 then
		this:CareObject(g_objCared, 0, "GuiShi_Exchange")
    end
    
	clean()
	
	this:Hide()
end

--===============================================
-- TextChanged() xjc
--===============================================
function GuiShi_Exchange_TextChanged()
	local nString = GuiShi_Exchange_NumberInput:GetText()
	
	--默认为MAX
    if nString == nil or nString == "" then
		defaultNum = 0
		--GuiShi_Exchange_NumberInput:SetText(defaultNum)
		return
	end

	local nBuysNum = tonumber(nString)
    if nBuysNum == nil then
		defaultNum = 0
		--GuiShi_Exchange_NumberInput:SetText(defaultNum)
		return
	end

	--小于0时
	if nBuysNum <= 0 then
		defaultNum = 1
		GuiShi_Exchange_NumberInput:SetText(defaultNum)
		return
	end
	
	--大于最大使用数量
    if nBuysNum > g_max then
        defaultNum = g_max
        GuiShi_Exchange_NumberInput:SetText(defaultNum)
        return
    end

	defaultNum = nBuysNum
	
end