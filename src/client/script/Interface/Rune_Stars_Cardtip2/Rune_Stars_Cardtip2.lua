--!!!reloadscript =Rune_Stars_Cardtip2

local g_left, g_top, g_right, g_bottom
local g_Type = 0
local g_MaxOrder = 5
local g_OrderBonusText = {
	{count = 4, order = 1,	no = "#{XZJC_200309_169}", yes = "#{XZJC_200309_170}"},
	{count = 4, order = 2,	no = "#{XZJC_200309_171}", yes = "#{XZJC_200309_172}"},
	{count = 4, order = 3,	no = "#{XZJC_200309_173}", yes = "#{XZJC_200309_174}"},
	{count = 4, order = 4,	no = "#{XZJC_200309_175}", yes = "#{XZJC_200309_176}"},
	{count = 4, order = 5,	no = "#{XZJC_200309_177}", yes = "#{XZJC_200309_178}"},
}

function Rune_Stars_Cardtip2_PreLoad()
	this:RegisterEvent("SHOW_XINGZHEN_SLOT_TIP",true)
end

function Rune_Stars_Cardtip2_OnLoad()	
	g_left = 0
	g_top  = 0
	g_right = 0
	g_bottom = 0
end										

function Rune_Stars_Cardtip2_OnEvent(event)
	
	if event == "SHOW_XINGZHEN_SLOT_TIP" then
		
		if tonumber(arg0) ~= 1 then
			this:Hide()
			return
		end
		g_Who = tonumber(arg1)
		g_XPos = tonumber(arg2)
		g_YPos = tonumber(arg3)
		Rune_Stars_Cardtip2_Update()		
		this:Show()
		
	end
			
end

function Rune_Stars_Cardtip2_Update()
	
	if g_Who == 1 then
		Rune_Stars_Cardtip2_UpdateOther()	
		return
	end
	local nLevel = Player:GetData("LEVEL")
	
	local nSlotActiveCount = 0
	local nLowLevel = g_MaxOrder
	
	for i = 1, 4 do
			local nXingJuanID = DataPool:LuaFnGetActivedXingJuanID(i)
			if nXingJuanID > 0 then
				nSlotActiveCount = nSlotActiveCount + 1
				local nOrder = DataPool:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
				
				if nOrder < nLowLevel then
					nLowLevel = nOrder
				end
			end
		end
	
	
	local bonus_tip = ""
	local bFirst = 1
	for i = 1, g_MaxOrder do
		
		local plus_text = g_OrderBonusText[i].no
		if nSlotActiveCount >= g_OrderBonusText[i].count and nLowLevel >= g_OrderBonusText[i].order then
			plus_text = g_OrderBonusText[i].yes
		end
		
		if bFirst == 0 then
			bonus_tip = bonus_tip.."#r"
		end
		bonus_tip = bonus_tip..plus_text
		bFirst = 0
	end
	Rune_Stars_Cardtip2_Text:SetText(bonus_tip)
	local ScreenWidth ,ScreenHeight = GetCurClientSize()
	
	local TipsWidth = Rune_Stars_Cardtip2_Text:GetProperty("AbsoluteWidth")
	local TipsHeight = Rune_Stars_Cardtip2_Text:GetProperty("AbsoluteHeight")
	g_XPos = g_XPos + 24
	if g_XPos + TipsWidth > ScreenWidth then
		g_XPos = g_XPos - TipsWidth - 24
	end
	if g_YPos + TipsHeight > ScreenHeight then 
		g_YPos = g_YPos - TipsHeight
	end
	
	Rune_Stars_Cardtip2:SetProperty("AbsoluteWidth",TipsWidth + 10)
	Rune_Stars_Cardtip2:SetProperty("AbsoluteHeight",TipsHeight + 15)
	Rune_Stars_Cardtip2:SetProperty("AbsoluteXPosition", g_XPos)
	Rune_Stars_Cardtip2:SetProperty("AbsoluteYPosition", g_YPos)
end

function Rune_Stars_Cardtip2_UpdateOther()

	local nLevel = CachedTarget:GetData("LEVEL",1)
	
	local nSlotActiveCount = 0
	local nLowLevel = g_MaxOrder
	
	for i = 1, 4 do
			local nXingJuanID = CachedTarget:LuaFnGetActivedXingJuanID(i)
			if nXingJuanID > 0 then
				nSlotActiveCount = nSlotActiveCount + 1
				local nOrder = CachedTarget:LuaFnGetXingJuanInfo(nXingJuanID, "Order")
				
				if nOrder < nLowLevel then
					nLowLevel = nOrder
			end
		end
	end
	
	
	local bonus_tip = ""
	local bFirst = 1
	for i = 1, g_MaxOrder do
		
		local plus_text = g_OrderBonusText[i].no
		if nSlotActiveCount == g_OrderBonusText[i].count and nLowLevel == g_OrderBonusText[i].order then
			plus_text = g_OrderBonusText[i].yes
		end
		
		if bFirst == 0 then
			bonus_tip = bonus_tip.."#r"
		end
		bonus_tip = bonus_tip..plus_text
		bFirst = 0
	end
	Rune_Stars_Cardtip2_Text:SetText(bonus_tip)
	local ScreenWidth ,ScreenHeight = GetCurClientSize()
	
	local TipsWidth = Rune_Stars_Cardtip2_Text:GetProperty("AbsoluteWidth")
	local TipsHeight = Rune_Stars_Cardtip2_Text:GetProperty("AbsoluteHeight")
	g_XPos = g_XPos + 24
	if g_XPos + TipsWidth > ScreenWidth then
		g_XPos = g_XPos - TipsWidth - 24
	end
	if g_YPos + TipsHeight > ScreenHeight then 
		g_YPos = g_YPos - TipsHeight
	end
	
	Rune_Stars_Cardtip2:SetProperty("AbsoluteWidth",TipsWidth + 10)
	Rune_Stars_Cardtip2:SetProperty("AbsoluteHeight",TipsHeight + 15)
	Rune_Stars_Cardtip2:SetProperty("AbsoluteXPosition", g_XPos)
	Rune_Stars_Cardtip2:SetProperty("AbsoluteYPosition", g_YPos)
end

function Rune_Stars_Cardtip2_OnHide()

end
