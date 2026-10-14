local g_FengmingShop_MBuy_Frame_UnifiedPosition
local g_FengmingShop_MBuy_Shop_Type = 0
local g_FengmingShop_MBuy_ItemId = 0
local g_FengmingShop_MBuy_CurPage = 0
local g_FengmingShop_MBuy_ItemIndex = 0
local g_FengmingShop_MBuy_PerPageCount = 15
local g_FengmingShop_MBuy_TargetId = -1


local g_FengmingShop_MBuy_DaiBiType = 0
--===============================================
-- OnLoad()
--===============================================
function FengmingShop_MBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--逻辑相关的事件
	this:RegisterEvent("OPEN_FENGMINGSHOP_BUY",true)    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UPDATE_YUANBAO",false);
end

function FengmingShop_MBuy_OnLoad()
	g_FengmingShop_MBuy_Frame_UnifiedPosition	=	FengmingShop_MBuy_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function FengmingShop_MBuy_OnEvent( event )
	if event == "OPEN_FENGMINGSHOP_BUY" then
		g_FengmingShop_MBuy_TargetId = tonumber(arg0)
		g_FengmingShop_MBuy_Shop_Type = tonumber(arg1)
		g_FengmingShop_MBuy_CurPage = tonumber(arg2)
		g_FengmingShop_MBuy_ItemIndex = tonumber(arg3)
		if g_FengmingShop_MBuy_Shop_Type < 0 or g_FengmingShop_MBuy_Shop_Type > 2 then
			return
		end
		
		FengmingShop_MBuy_InputNumBK:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
		FengmingShop_MBuy_InputNumBK:SetText("1")					--默认输入为1   
		FengmingShop_MBuy_InputNumBK:SetSelected( 0, -1 ); 
		FengmingShop_MBuy_FreshWindow(g_FengmingShop_MBuy_ItemIndex) 
		objCared = DataPool : GetNPCIDByServerID(g_FengmingShop_MBuy_TargetId)
		this:CareObject(objCared, 1, "FengmingShop_MBuy");	
		this:Show()
	elseif event == "UPDATE_YUANBAO" then
		if g_FengmingShop_MBuy_DaiBiType == 2 then
			FengmingShop_MBuy_FreshWindow(g_FengmingShop_MBuy_ItemIndex) 
		end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengmingShop_MBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		FengmingShop_MBuy_Closed()
	elseif event == "ADJEST_UI_POS" then
		FengmingShop_MBuy_Frame_On_ResetPos() 		
	end
end

--===============================================
--刷新界面信息
--===============================================
function FengmingShop_MBuy_FreshWindow( index )
  local tblinfo= NpcShop:GetFengMingShopData(g_FengmingShop_MBuy_Shop_Type,g_FengmingShop_MBuy_CurPage,g_FengmingShop_MBuy_PerPageCount)
	if type(tblinfo) ~= "table" or tblinfo[index] == nil then
		PushDebugMessage("error11")
		return
	end 
	local itemid 	    = tblinfo[index].itemid
	local itemnum 	    = tblinfo[index].itemnum
	local itemname     = tblinfo[index].itemname
	local daibitype		= tblinfo[index].daibitype
	local price      = tblinfo[index].price
	local limitweek     = tblinfo[index].limitweek
	local limitweek_self= tblinfo[index].limitweek_self
	local limitpermanent      = tblinfo[index].limitpermanent
	local limitpermanent_self = tblinfo[index].limitpermanent_self

	g_FengmingShop_MBuy_ItemId = itemid
	local	nBuyNum	=	0
	if FengmingShop_MBuy_InputNumBK:GetText() ~= '' then
		nBuyNum	=	tonumber(FengmingShop_MBuy_InputNumBK:GetText())
	end 
	local	theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
	if theAction:GetID() ~= 0 then
		FengmingShop_MBuy_Item:SetActionItem(theAction:GetID())
		FengmingShop_MBuy_Item:Show()
	end
    
	local nhavenum = 0 
  if limitweek > 0 then 
		nhavenum = limitweek_self
  elseif limitpermanent > 0 then
		nhavenum = limitpermanent_self
  else
  	FengmingShop_MBuy_Item_BuyLimitNumBK:Hide()
    FengmingShop_MBuy_Item_Mask:Hide()
  end

  if (limitweek > 0 or limitpermanent > 0 ) then
    if nhavenum > 0 then
			FengmingShop_MBuy_Item_BuyLimitNum:SetText(nhavenum)
			FengmingShop_MBuy_Item_BuyLimitNumBK:Show()
			FengmingShop_MBuy_Item_Mask:Hide()
    else
			FengmingShop_MBuy_Item_BuyLimitNumBK:Hide()
    	FengmingShop_MBuy_Item_Mask:Show()
    end        
    if limitweek > 0 then
			FengmingShop_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week") 
    elseif limitpermanent > 0 then
			FengmingShop_MBuy_Item_BuyLimit:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever")  
    end
    FengmingShop_MBuy_Item_BuyLimit:Show()
  else
		FengmingShop_MBuy_Item_BuyLimitNumBK:Hide()
		FengmingShop_MBuy_Item_Mask:Hide()        
		FengmingShop_MBuy_Item_BuyLimit:Hide()
  end
  FengmingShop_MBuy_ItemInfo_Text:SetText(DataPool:Lua_GetItemNameByIndex(itemid))

	g_FengmingShop_MBuy_DaiBiType = daibitype
	if daibitype == 1 then
		FengmingShop_MBuy_Price:SetText("#{FMSD_220705_32}")
		FengmingShop_MBuy_Cash:SetText("#{FMSD_220705_33}")
		local curDaibiTotal = NpcShop:GetFengMingShopDaiBi()
		FengmingShop_MBuy_CashNum:SetText( "#cfff263"..curDaibiTotal )
		FengmingShop_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format("#{FMSD_220705_29}",price))
		if price*nBuyNum > curDaibiTotal or nBuyNum == 0 then 
			FengmingShop_MBuy_PriceNum:SetText( "#cff0000"..price*nBuyNum )
			FengmingShop_MBuy_Submit:Disable()
		else  
			FengmingShop_MBuy_PriceNum:SetText( "#G"..price*nBuyNum )
			FengmingShop_MBuy_Submit:Enable()
		end
	elseif daibitype == 2 then
		FengmingShop_MBuy_Price:SetText("#{FMSD_220705_59}")
		FengmingShop_MBuy_Cash:SetText("#{FMSD_220705_60}")
		local curDaibiTotal = Player:GetData("YUANBAO")
		FengmingShop_MBuy_CashNum:SetText( "#cfff263"..curDaibiTotal )
		FengmingShop_MBuy_ItemInfo_Lilianzhi2:SetText(ScriptGlobal_Format("#{FMSD_220705_55}",price))
		if price*nBuyNum > curDaibiTotal or nBuyNum == 0 then
			FengmingShop_MBuy_PriceNum:SetText( "#cff0000"..price*nBuyNum )
			FengmingShop_MBuy_Submit:Disable()
		else
			FengmingShop_MBuy_PriceNum:SetText( "#G"..price*nBuyNum )
			FengmingShop_MBuy_Submit:Enable()
		end
	end

end



--===============================================
--取出相应的物资
--===============================================
function FengmingShop_MBuy_OK_Clicked()
 
	local count = tonumber(FengmingShop_MBuy_InputNumBK:GetText())
	if count <= 0 then
		return
    end 
	FengmingShop_MBuy_BuyItem(g_FengmingShop_MBuy_ItemId, count)
	--隐藏界面
	this:Hide()					
end

function FengmingShop_MBuy_BuyItem(itemid,count)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyItem" ); 					-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 889833 );											-- 脚本编号 
		Set_XSCRIPT_Parameter( 0, g_FengmingShop_MBuy_TargetId );	
		Set_XSCRIPT_Parameter( 1, g_FengmingShop_MBuy_Shop_Type );		     
		Set_XSCRIPT_Parameter( 2, itemid );	 
		Set_XSCRIPT_Parameter( 3, count );
		Set_XSCRIPT_Parameter( 4, g_FengmingShop_MBuy_CurPage );
		Set_XSCRIPT_ParamCount( 5 ); 	-- 参数个数
	Send_XSCRIPT()	
end
function FengmingShop_MBuy_GetBuyMaxNum()
--	PushDebugMessage("g_FengmingShop_MBuy_ItemIndex="..g_FengmingShop_MBuy_ItemIndex)
	local tblinfo= NpcShop:GetFengMingShopData(g_FengmingShop_MBuy_Shop_Type,g_FengmingShop_MBuy_CurPage,g_FengmingShop_MBuy_PerPageCount)
	if type(tblinfo) ~= "table" or tblinfo[g_FengmingShop_MBuy_ItemIndex] == nil then
		PushDebugMessage("error222")
		return
	end 
	local itemid 	    = tblinfo[g_FengmingShop_MBuy_ItemIndex].itemid
	local itemnum 	    = tblinfo[g_FengmingShop_MBuy_ItemIndex].itemnum
	local daibitype     = tblinfo[g_FengmingShop_MBuy_ItemIndex].daibitype
	local price     = tblinfo[g_FengmingShop_MBuy_ItemIndex].price
	local limitweek     = tblinfo[g_FengmingShop_MBuy_ItemIndex].limitweek
	local limitweek_self= tblinfo[g_FengmingShop_MBuy_ItemIndex].limitweek_self
	local limitpermanent      = tblinfo[g_FengmingShop_MBuy_ItemIndex].limitpermanent
	local limitpermanent_self = tblinfo[g_FengmingShop_MBuy_ItemIndex].limitpermanent_self

	local ndaibicount   = 0
	if daibitype == 1 then
		ndaibicount = NpcShop:GetFengMingShopDaiBi()
	else
		ndaibicount = Player:GetData("YUANBAO")
	end
	local	nBuyNum	=	0
	
	local nislimit = 0
	local limitnum = 0
	if limitweek < 0 and limitpermanent < 0 then
		nislimit = 0
	elseif limitweek > 0 then
		nislimit = 1
		limitnum =limitweek_self
	elseif limitpermanent > 0 then
		nislimit = 1
		limitnum =limitpermanent_self   
	end 

	--计算最大能领取数量 
	local cancout= NpcShop:FengmingShopCalcMaxNumCanBuy(itemid,itemnum,g_FengmingShop_MBuy_Shop_Type,ndaibicount,price,nislimit,limitnum,0,1)
	if cancout > 0 then
		return cancout
	else
		return 1
	end
end
function FengmingShop_MBuy_CalMax()    
	FengmingShop_MBuy_InputNumBK : SetText(FengmingShop_MBuy_GetBuyMaxNum())
end

function FengmingShop_MBuy_TextChanged() 
	FengmingShop_MBuy_FreshWindow(g_FengmingShop_MBuy_ItemIndex) 
end

function FengmingShop_MBuy_OnHidden()    
	this:Hide()
end
function FengmingShop_MBuy_CancelClicked()
	this:Hide()
end
--===============================================
--关闭界面
--===============================================
function FengmingShop_MBuy_Closed()
	this:Hide()
end
function FengmingShop_MBuy_Close_Clicked()
	this:Hide()
end
function FengmingShop_MBuy_Frame_On_ResetPos()
	 FengmingShop_MBuy_Frame:SetProperty("UnifiedPosition", g_FengmingShop_MBuy_Frame_UnifiedPosition)
end
