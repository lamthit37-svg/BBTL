--RichFlip_BuyDice

local g_RichFlip_BuyDice_Frame_UnifiedPosition
local g_RichFlip_BuyDice_RequireYB = 200  
local g_RichFlip_BuyDice_MaxCount = 100
local g_RichFlip_BuyDice_DiceShowItemId = 39924834
local g_RichFlip_BuyDice_totalbuynum = 0
local g_RichFlip_BuyDice_maxbuynum = 1000

function RichFlip_BuyDice_PreLoad()
	this:RegisterEvent("LUCKYLINE_OPEN_BUYDICE",true)
	this:RegisterEvent("UI_COMMAND",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
end

function RichFlip_BuyDice_OnLoad()
	g_RichFlip_BuyDice_Frame_UnifiedPosition = RichFlip_BuyDice_Frame:GetProperty("UnifiedPosition")

end

function RichFlip_BuyDice_OnEvent(event)
	if event == "LUCKYLINE_OPEN_BUYDICE" then
		if this:IsVisible() then
			RichFlip_BuyDice_Close()
			return
		end
		g_RichFlip_BuyDice_totalbuynum = tonumber(arg0)
		this:Show()
		RichFlip_BuyDice_Open()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99944111 and this:IsVisible() ) then
		g_RichFlip_BuyDice_totalbuynum = Get_XParam_INT(0)
		--RichFlip_BuyDice_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		RichFlip_BuyDice_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		RichFlip_BuyDice_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		RichFlip_BuyDice_Close()
	elseif event == "UPDATE_YUANBAO" then
		RichFlip_BuyDice_CashNum:SetText("#L"..Player:GetData("YUANBAO"))
	end
	
end

function RichFlip_BuyDice_Open()
	RichFlip_BuyDice_ItemInfo_Price:SetText("#L"..tostring(g_RichFlip_BuyDice_RequireYB))
	RichFlip_BuyDice_CashNum:SetText("#{FPLS_240715_55}"..Player:GetData("YUANBAO"))
	RichFlip_BuyDice_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
	RichFlip_BuyDice_InputNum:SetText("1")					--默认输入为1   
	local theAction = DataPool:CreateActionItemForShow(g_RichFlip_BuyDice_DiceShowItemId, 1)
	if theAction:GetID() ~= 0 then
		RichFlip_BuyDice_Item:SetActionItem(theAction:GetID())
	end

end

function RichFlip_BuyDice_OK_Clicked()
	local count = tonumber(RichFlip_BuyDice_InputNum:GetText())
	if count == nil then
		PushDebugMessage("#{FPLS_240715_61}")
		return
	end
	if count <= 0 or count > g_RichFlip_BuyDice_MaxCount then
		PushDebugMessage("#{FPLS_240715_61}")
		return
	end 
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyCJDaibi" )
		Set_XSCRIPT_ScriptID( 999441 )
    	Set_XSCRIPT_Parameter(0,count)
		Set_XSCRIPT_Parameter(1,1)
    	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()	

end

function RichFlip_BuyDice_CalMax()
	local ybNum = Player:GetData("YUANBAO")
	local MaxCount =  math.floor(ybNum / g_RichFlip_BuyDice_RequireYB)
	local restCanBuynum = g_RichFlip_BuyDice_maxbuynum-g_RichFlip_BuyDice_totalbuynum

	if MaxCount > g_RichFlip_BuyDice_MaxCount then
		MaxCount = g_RichFlip_BuyDice_MaxCount
	end
	
	if restCanBuynum < MaxCount then
		MaxCount = restCanBuynum
	end
	
	RichFlip_BuyDice_PriceNum:SetText("#L"..tostring(MaxCount*g_RichFlip_BuyDice_RequireYB))

	-- RichFlip_BuyDice_InputNum:SetTextOriginal(tostring(MaxCount))
	RichFlip_BuyDice_InputNum:SetText(tostring(MaxCount))
end

function RichFlip_BuyDice_TextChanged()

	local num = tonumber(RichFlip_BuyDice_InputNum:GetText())
	-- if(num == nil or num < 0) then
	-- 	num = 1
	-- 	RichFlip_BuyDice_InputNum:SetText( tostring( num ) )
	-- end
	local ybNum = Player:GetData("YUANBAO")
	local MaxCount =  math.floor(ybNum / g_RichFlip_BuyDice_RequireYB)
	local restCanBuynum = g_RichFlip_BuyDice_maxbuynum-g_RichFlip_BuyDice_totalbuynum
	if MaxCount > g_RichFlip_BuyDice_MaxCount then
		MaxCount = g_RichFlip_BuyDice_MaxCount
	end
	if restCanBuynum < MaxCount then
		MaxCount = restCanBuynum
	end
	
	if num ~= nil then
		if(num > MaxCount) then
			num = MaxCount
			RichFlip_BuyDice_InputNum:SetText( tostring( num ) )
		end
		RichFlip_BuyDice_PriceNum:SetText("#L"..tostring(num*g_RichFlip_BuyDice_RequireYB))
	else
		RichFlip_BuyDice_PriceNum:SetText("#L0")
	end
	
end

function RichFlip_BuyDice_On_ResetPos()
	RichFlip_BuyDice_Frame:SetProperty("UnifiedPosition", g_RichFlip_BuyDice_Frame_UnifiedPosition)

end

function RichFlip_BuyDice_Close()
	this:Hide()
end

function RichFlip_BuyDice_Close_Clicked()
	this:Hide()
end

function RichFlip_BuyDice_OnHidden()
	RichFlip_BuyDice_Close()
end