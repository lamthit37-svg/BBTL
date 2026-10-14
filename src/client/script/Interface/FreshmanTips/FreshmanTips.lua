local g_FreshmanTips_left = 0
local g_FreshmanTips_top = 0
local g_FreshmanTips_right = 0
local g_FreshmanTips_bottom = 0
local g_FreshmanTips_state = 0

local g_ItemList ={
										{num = 1, itemId = {10415054}, itemName = {"#{XRLJ_130717_2}"}},
										{num = 2, itemId = {10414054,10141451}, itemName = {"#{XRLJ_130717_3}","#{XRLJ_130717_4}"}},
										{num = 1, itemId = {10422152}, itemName = {"#{XRLJ_130717_5}"}},
										{num = 1, itemId = {10423060}, itemName = {"#{XRLJ_130717_6}"}},
										{num = 1, itemId = {10423061}, itemName = {"#{XRLJ_130717_7}"}},
										{num = 2, itemId = {30309984,30900059}, itemName = {"#{XRLJ_130717_8}","#{XRLJ_130717_9}"}},
										{num = 1, itemId = {30607000}, itemName = {"#{XRLJ_130717_10}"}},
										{num = 1, itemId = {10141034}, itemName = {"#{XRLJ_130717_11}"}},
										{num = 1, itemId = {10141024}, itemName = {"#{XRLJ_130717_12}"}},
										{num = 2, itemId = {30008002,31000006}, itemName = {"#{XRLJ_130717_13}","#{XRLJ_130717_14}"}},
	             		}
      
--===============================================
-- PreLoad()
--===============================================
function FreshmanTips_PreLoad()
	this:RegisterEvent("FRESHMAN_TIPS")
end

--===============================================
-- OnLoad()
--===============================================
function FreshmanTips_OnLoad()
	FreshmanTips_CleanData()
end

--===============================================
-- OnEvent()
--===============================================
function FreshmanTips_OnEvent( event )
	if event == "FRESHMAN_TIPS" then
		local open = tonumber(arg0)
		if open == 1 then
			FreshmanTips_CleanData()
			g_FreshmanTips_state 		= tonumber(arg1)
			g_FreshmanTips_left 		= arg2
			g_FreshmanTips_top 			= arg3
			g_FreshmanTips_right 		= arg4
			g_FreshmanTips_bottom 	= arg5
			FreshmanTips_Update()
			this:Show()
		elseif open == 0 then
			this:Hide()
		end
	end
end

--清空数据
function FreshmanTips_CleanData()
	g_FreshmanTips_state = 0
	g_FreshmanTips_left = 0
	g_FreshmanTips_top = 0
	g_FreshmanTips_right = 0
	g_FreshmanTips_bottom = 0
end

--获取物品数据
function FreshmanTips_GetItemData(index)
	if index <=0 or index > g_ItemList[g_FreshmanTips_state].num then
		return "",""
	end

	local nid = g_ItemList[g_FreshmanTips_state].itemId[index]
	local name,icon = LifeAbility : GetPrescr_Material(nid);
	icon = GetIconFullName(icon)
	if name == nil or name == "" or icon == nil or icon == "" then
		return "",""
	end
	name = g_ItemList[g_FreshmanTips_state].itemName[index]
	return name,icon
end

--数据更新显示
function FreshmanTips_Update()
	--crash消除
	if g_FreshmanTips_left == nil or g_FreshmanTips_top == nil or g_FreshmanTips_right == nil or g_FreshmanTips_bottom == nil or g_FreshmanTips_state == nil then 
		return
	end
	
	--当前奖励阶段
	if g_FreshmanTips_state <= 0 then 
		this:Hide()
		return
	end
	
	--界面显示内容
	local toDisplay = ""
	toDisplay = toDisplay .. ";FreshmanTips_Title";
					
	--标题
  --FreshmanTips_Title:SetText(#{XRLJ_130717_15})
  	
  --内容
  local num = g_ItemList[g_FreshmanTips_state].num
  if num == 2 then
		--大小
		toDisplay = toDisplay .. ";FreshmanTips_StaticPart";
		toDisplay = toDisplay .. ";FreshmanTips_StaticPart1";
		FreshmanTips_Frame:SetProperty("PageElements",  toDisplay);
		--FreshmanTips_Frame:SetProperty("AbsoluteSize", "w:220 h:180");
		FreshmanTips_Frame:PositionSelf(g_FreshmanTips_left, g_FreshmanTips_top, g_FreshmanTips_right, g_FreshmanTips_bottom)
	
		--物品1
		local name, icon = FreshmanTips_GetItemData(1)
		if name ~= "" and icon ~= "" then
	  	FreshmanTips_StaticPart_Icon:SetProperty( "Image", icon )
			FreshmanTips_StaticPart_Item:SetText( name )		
		end
		
		--物品2
		local name1, icon1 = FreshmanTips_GetItemData(2)
		if name1 ~= "" and icon1 ~= "" then
	  	FreshmanTips_StaticPart_Icon1:SetProperty( "Image", icon1 )
			FreshmanTips_StaticPart_Item1:SetText( name1 )		
		end		
  elseif num == 1 then
		--大小
		toDisplay = toDisplay .. ";FreshmanTips_StaticPart";
		FreshmanTips_Frame:SetProperty("PageElements",  toDisplay);
		--FreshmanTips_Frame:SetProperty("AbsoluteSize", "w:220 h:100");
		FreshmanTips_Frame:PositionSelf(g_FreshmanTips_left, g_FreshmanTips_top, g_FreshmanTips_right, g_FreshmanTips_bottom)

		--物品1
		local name, icon = FreshmanTips_GetItemData(1)
		if name ~= "" and icon ~= "" then
	  	FreshmanTips_StaticPart_Icon:SetProperty( "Image", icon )
			FreshmanTips_StaticPart_Item:SetText( name )		
		end
	else
		this:Hide()
		return
  end
end
