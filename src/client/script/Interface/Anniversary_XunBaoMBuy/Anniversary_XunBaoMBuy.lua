
local g_Anniversary_XunBaoMBuy_Frame_UnifiedPosition;  

local g_Anniversary_XunBaoMBuy_CurPool = 0
local g_Anniversary_XunBaoMBuy_CurItemIdx = 0
local g_Anniversary_XunBaoMBuy_itemid = -1
local g_Anniversary_XunBaoMBuy_itemcount = -1
local g_Anniversary_XunBaoMBuy_itemcost = -1
local g_Anniversary_XunBaoMBuy_nCurDB = -1
local g_Anniversary_XunBaoMBuy_surp = -1
local g_Anniversary_XunBaoMBuy_buyNum = 1
local g_Anniversary_XunBaoMBuy_MaxCount = 1

-- 单价 需要代币 拥有代币
local g_Anniversary_XunBaoMBuy_Str = {
[1] = {"#{ZNYR_210809_03}", "#{ZNYR_210809_09}", "#{ZNYR_210809_14}"},
[2] = {"#{ZNYR_210809_04}", "#{ZNYR_210809_10}", "#{ZNYR_210809_15}"},
[3] = {"#{ZNYR_210809_05}", "#{ZNYR_210809_11}", "#{ZNYR_210809_16}"},
[4] = {"#{ZNYR_210809_06}", "#{ZNYR_210809_12}", "#{ZNYR_210809_17}"},
}

function Anniversary_XunBaoMBuy_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	    
	-- 进入游戏世界
	this:RegisterEvent("PLAYER_ENTERING_WORLD",false)	
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);	 
end 

function Anniversary_XunBaoMBuy_OnLoad()
	g_Anniversary_XunBaoMBuy_Frame_UnifiedPosition	= Anniversary_XunBaoMBuy_Frame:GetProperty("UnifiedPosition"); 	 
end

function Anniversary_XunBaoMBuy_Frame_On_ResetPos()
  	Anniversary_XunBaoMBuy_Frame:SetProperty("UnifiedPosition", g_Anniversary_XunBaoMBuy_Frame_UnifiedPosition);
end

function Anniversary_XunBaoMBuy_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" or event == "PLAYER_ENTERING_WORLD" ) then
		Anniversary_XunBaoMBuy_Close_Clicked();
	end
  
    -- 游戏窗口尺寸发生了变化
	if ( event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 更新背包界面位置
		Anniversary_XunBaoMBuy_Frame_On_ResetPos()
	end
		 
	-- 打开界面
	if (event == "UI_COMMAND" and tonumber(arg0) == 89340107) then 
		if this:IsVisible() then
			this:Hide();
		end
		
		g_Anniversary_XunBaoMBuy_CurPool = Get_XParam_INT(0) 
		g_Anniversary_XunBaoMBuy_CurItemIdx = Get_XParam_INT(1) 
		g_Anniversary_XunBaoMBuy_itemid = Get_XParam_INT(2) 
		g_Anniversary_XunBaoMBuy_itemcount = Get_XParam_INT(3) 
		g_Anniversary_XunBaoMBuy_itemcost = Get_XParam_INT(4) 
		g_Anniversary_XunBaoMBuy_nCurDB = Get_XParam_INT(5) 
		g_Anniversary_XunBaoMBuy_surp = Get_XParam_INT(6) 
		
		Anniversary_XunBaoMBuy_OnInitial(); 
		this:Show();
	end  
	
end 

function Anniversary_XunBaoMBuy_OnInitial()   

	local theAction = DataPool:CreateActionItemForShow(g_Anniversary_XunBaoMBuy_itemid, g_Anniversary_XunBaoMBuy_itemcount)
	if theAction:GetID() ~= 0 then
		Anniversary_XunBaoMBuy_Item:SetActionItem(theAction:GetID());
	end
	
	--道具信息
	local str = DataPool:Lua_GetItemNameByIndex(g_Anniversary_XunBaoMBuy_itemid)
	local namestr = ScriptGlobal_Format("#{ZNYR_210809_02}", str)
	Anniversary_XunBaoMBuy_ItemName:SetText( namestr )	
	if g_Anniversary_XunBaoMBuy_Str[g_Anniversary_XunBaoMBuy_CurPool] ~= nil then
		local pricestr = ScriptGlobal_Format(g_Anniversary_XunBaoMBuy_Str[g_Anniversary_XunBaoMBuy_CurPool][1], g_Anniversary_XunBaoMBuy_itemcost)
		Anniversary_XunBaoMBuy_ItemPrice:SetText(pricestr)
	else
		Anniversary_XunBaoMBuy_ItemPrice:SetText(g_Anniversary_XunBaoMBuy_itemcost)
	end
	
	--限量
	if g_Anniversary_XunBaoMBuy_surp > 0 then
		Anniversary_XunBaoMBuy_Item_BuyLimit:Show()
		Anniversary_XunBaoMBuy_Item_BuyLimitNumBK:Show()
		Anniversary_XunBaoMBuy_Item_BuyLimitNum:SetText(tostring(g_Anniversary_XunBaoMBuy_surp))
	else
		Anniversary_XunBaoMBuy_Item_BuyLimit:Hide()
		Anniversary_XunBaoMBuy_Item_BuyLimitNumBK:Hide()
	end
	
	--最大购买量
	g_Anniversary_XunBaoMBuy_MaxCount = math.floor(g_Anniversary_XunBaoMBuy_nCurDB/g_Anniversary_XunBaoMBuy_itemcost)
	if g_Anniversary_XunBaoMBuy_MaxCount <= 0 then
		g_Anniversary_XunBaoMBuy_MaxCount = 1
	end
	
	if g_Anniversary_XunBaoMBuy_surp > 0 and g_Anniversary_XunBaoMBuy_MaxCount > g_Anniversary_XunBaoMBuy_surp then
		g_Anniversary_XunBaoMBuy_MaxCount = g_Anniversary_XunBaoMBuy_surp
	end
	
	g_Anniversary_XunBaoMBuy_buyNum = 1	
		
	Anniversary_XunBaoMBuy_UpdateCurDBInfo( )
	
	Anniversary_XunBaoMBuy_ItemNumberInput:SetProperty("DefaultEditBox", "True");
	Anniversary_XunBaoMBuy_ItemNumberInput:SetText(tostring(g_Anniversary_XunBaoMBuy_buyNum));
	Anniversary_XunBaoMBuy_ItemNumberInput:SetSelected( 0, -1 );
	
end

function Anniversary_XunBaoMBuy_UpdateCurDBInfo( )
		
	--所需代币
	if g_Anniversary_XunBaoMBuy_Str[g_Anniversary_XunBaoMBuy_CurPool] ~= nil then
		Anniversary_XunBaoMBuy_Price:SetText(g_Anniversary_XunBaoMBuy_Str[g_Anniversary_XunBaoMBuy_CurPool][2])
	else
		Anniversary_XunBaoMBuy_Price:SetText("#{ZNYR_200302_67}")
	end
	local allcost = g_Anniversary_XunBaoMBuy_itemcost * g_Anniversary_XunBaoMBuy_buyNum
	local allcoststr = ScriptGlobal_Format("#{ZNYR_210809_13}", allcost)
	Anniversary_XunBaoMBuy_Price1:SetText( allcoststr )	
	
	--当前代币
	if g_Anniversary_XunBaoMBuy_Str[g_Anniversary_XunBaoMBuy_CurPool] ~= nil then
		Anniversary_XunBaoMBuy_Cash:SetText(g_Anniversary_XunBaoMBuy_Str[g_Anniversary_XunBaoMBuy_CurPool][3])
	else
		Anniversary_XunBaoMBuy_Cash:SetText("#{ZNYR_200302_68}")
	end
	
	local CurDBstr = 0
	if g_Anniversary_XunBaoMBuy_nCurDB >= allcost then
		CurDBstr = ScriptGlobal_Format("#{ZNYR_210809_19}", g_Anniversary_XunBaoMBuy_nCurDB)	-- 绿色 足
	else
		CurDBstr = ScriptGlobal_Format("#{ZNYR_210809_18}", g_Anniversary_XunBaoMBuy_nCurDB)	-- 红色 不足 
	end
	Anniversary_XunBaoMBuy_Cash1:SetText( CurDBstr )
	
end

function Anniversary_XunBaoMBuy_EditEnter()

	local numstr = Anniversary_XunBaoMBuy_ItemNumberInput:GetText()
	if numstr == nil then
		return
	end
		
	local num = tonumber(numstr)
	if num == 0 or num == nil then
		g_Anniversary_XunBaoMBuy_buyNum = 0	
		Anniversary_XunBaoMBuy_UpdateCurDBInfo( )
		return
	end
		
	if num < 0 then
		Anniversary_XunBaoMBuy_ItemNumberInput:SetText("0")
		num = 0
	end
	
	if(num > g_Anniversary_XunBaoMBuy_MaxCount) then
		num = g_Anniversary_XunBaoMBuy_MaxCount
		Anniversary_XunBaoMBuy_ItemNumberInput:SetText(tostring(num))
	end
	
	g_Anniversary_XunBaoMBuy_buyNum = num	
	Anniversary_XunBaoMBuy_UpdateCurDBInfo( )
	
end

function Anniversary_XunBaoMBuy_OnMax()

	g_Anniversary_XunBaoMBuy_buyNum = g_Anniversary_XunBaoMBuy_MaxCount
	Anniversary_XunBaoMBuy_ItemNumberInput:SetText(tostring(g_Anniversary_XunBaoMBuy_MaxCount))
	
	Anniversary_XunBaoMBuy_UpdateCurDBInfo( )
	
end

function Anniversary_XunBaoMBuy_OK_Clicked()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "AnniPreExchangeItem" )
		Set_XSCRIPT_ScriptID( 893401 )
		Set_XSCRIPT_Parameter(0, g_Anniversary_XunBaoMBuy_CurPool)
		Set_XSCRIPT_Parameter(1, g_Anniversary_XunBaoMBuy_CurItemIdx)
		Set_XSCRIPT_Parameter(2, g_Anniversary_XunBaoMBuy_buyNum)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()	
	
end

function Anniversary_XunBaoMBuy_Hidden()

	Anniversary_XunBaoMBuy_Item:SetActionItem(-1)

	Anniversary_XunBaoMBuy_ItemNumberInput:SetProperty("DefaultEditBox", "False");
	
end


function Anniversary_XunBaoMBuy_Close_Clicked()  
	
	this:Hide(); 
	
end 
 