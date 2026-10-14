--Frozen_WheelCJMBuy

local g_Frozen_WheelCJMBuy_Frame_UnifiedPosition
local g_Frozen_WheelCJMBuy_RequireYB = 10  
local g_Frozen_WheelCJMBuy_DiceShowItemId = 39924231
local g_Frozen_WheelCJMBuy_totalbuynum = 0
local g_Frozen_WheelCJMBuy_maxbuynum = 10000


function Frozen_WheelCJMBuy_PreLoad()
	this:RegisterEvent("OPEN_SNOW_WhEElCJMBUY",true)
	this:RegisterEvent("UI_COMMAND",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
end

function Frozen_WheelCJMBuy_OnLoad()
	g_Frozen_WheelCJMBuy_Frame_UnifiedPosition = Frozen_WheelCJMBuy_Frame:GetProperty("UnifiedPosition")

end

function Frozen_WheelCJMBuy_OnEvent(event)
	if event == "OPEN_SNOW_WhEElCJMBUY" then
		if this:IsVisible() then
			Frozen_WheelCJMBuy_Close()
			return
		end
		g_Frozen_WheelCJMBuy_totalbuynum = tonumber(arg0)
		this:Show()
		Frozen_WheelCJMBuy_Open()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99950105 and this:IsVisible() ) then
		g_Frozen_WheelCJMBuy_totalbuynum = Get_XParam_INT(0)
		Frozen_WheelCJMBuy_HaveNum:SetText(ScriptGlobal_Format("#{BXZP_240911_126}", g_Frozen_WheelCJMBuy_totalbuynum))
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Frozen_WheelCJMBuy_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Frozen_WheelCJMBuy_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_WheelCJMBuy_Close()
	elseif event == "UPDATE_YUANBAO" then
		Frozen_WheelCJMBuy_CashNum:SetText("#L"..Player:GetData("YUANBAO"))
	end
	
end

function Frozen_WheelCJMBuy_Open()
	Frozen_WheelCJMBuy_CashNum:SetText("#L"..Player:GetData("YUANBAO"))
	Frozen_WheelCJMBuy_Item1_Cash:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	Frozen_WheelCJMBuy_Item1_Cash:SetText("1")					--默认输入为1 
	Frozen_WheelCJMBuy_HaveNum:SetText(ScriptGlobal_Format("#{BXZP_240911_126}", g_Frozen_WheelCJMBuy_totalbuynum))  
	--local theAction = DataPool:CreateActionItemForShow(g_Frozen_WheelCJMBuy_DiceShowItemId, 1)
	--if theAction:GetID() ~= 0 then
	--	Frozen_WheelCJMBuy_Item:SetActionItem(theAction:GetID())
	--end

end

function Frozen_WheelCJMBuy_GetClick()
	local count = tonumber(Frozen_WheelCJMBuy_Item1_Cash:GetText())
	if count == nil then
		PushDebugMessage("#{BXZP_240911_79}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuySnowCJDaibi" )
		Set_XSCRIPT_ScriptID( 999501 )
    	Set_XSCRIPT_Parameter(0,count)
		Set_XSCRIPT_Parameter(1,1)
    	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

function Frozen_WheelCJMBuy_CalMax()
	local ybNum = Player:GetData("YUANBAO")
	local MaxCount =  math.floor(ybNum / g_Frozen_WheelCJMBuy_RequireYB)
	local restCanBuynum = g_Frozen_WheelCJMBuy_maxbuynum-g_Frozen_WheelCJMBuy_totalbuynum

	if MaxCount > restCanBuynum then
		MaxCount = restCanBuynum
	end
	Frozen_WheelCJMBuy_PriceNum:SetText(ScriptGlobal_Format("#{BXZP_240911_73}", tostring(MaxCount*g_Frozen_WheelCJMBuy_RequireYB)))

	-- Frozen_WheelCJMBuy_InputNum:SetTextOriginal(tostring(MaxCount))
	Frozen_WheelCJMBuy_Item1_Cash:SetText(tostring(MaxCount))
end

function Frozen_WheelCJMBuy_TextChanged()

	local num = tonumber(Frozen_WheelCJMBuy_Item1_Cash:GetText())
	-- if(num == nil or num < 0) then
	-- 	num = 1
	-- 	Frozen_WheelCJMBuy_InputNum:SetText( tostring( num ) )
	-- end
	local ybNum = Player:GetData("YUANBAO")
	local MaxCount =  math.floor(ybNum / g_Frozen_WheelCJMBuy_RequireYB)
	local restCanBuynum = g_Frozen_WheelCJMBuy_maxbuynum-g_Frozen_WheelCJMBuy_totalbuynum

	if MaxCount > restCanBuynum then
		MaxCount = restCanBuynum
	end
	if num ~= nil then
		if(num > MaxCount) then
			num = MaxCount
			Frozen_WheelCJMBuy_Item1_Cash:SetText( tostring( num ) )
		end
		Frozen_WheelCJMBuy_PriceNum:SetText("#L"..tostring(num*g_Frozen_WheelCJMBuy_RequireYB))
	else
		Frozen_WheelCJMBuy_PriceNum:SetText("#L0")
	end
	
end

function Frozen_WheelCJMBuy_On_ResetPos()
	Frozen_WheelCJMBuy_Frame:SetProperty("UnifiedPosition", g_Frozen_WheelCJMBuy_Frame_UnifiedPosition)

end

function Frozen_WheelCJMBuy_Close()
	this:Hide()
end

function Frozen_WheelCJMBuy_Close_Clicked()
	this:Hide()
end

function Frozen_WheelCJMBuy_OnHidden()
	Frozen_WheelCJMBuy_Close()
end