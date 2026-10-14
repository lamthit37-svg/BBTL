-- 凤鸣商店 
-- 天荒商行 分页4
-- local g_FengmingShop_Frame_UnifiedXPosition
-- local g_FengmingShop_Frame_UnifiedYPosition 
local g_FengmingShop_listitem ={}
local g_FengmingShop_listctrl = {}
local g_FengmingShop_tabctrl = {}
local g_FengmingShop_Type = 0
local g_FengmingShop_CurPage = 1
local g_FengmingShop_TargetId = -1
local g_FengmingShop_PerPageCount = 15
local g_FengmingShop_isLFOwner = 0
local g_FengmingShop_isAnyOwner = 0
local g_FengmingShop_IsGuildTimeOK = 0

function FengmingShop_PreLoad()
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("UPDATE_FENGMINGSHOP",true)
	this:RegisterEvent("UPDATE_FENGMINGSHOP_DAIBI",false)
	this:RegisterEvent("UPDATE_YUANBAO",false);
end

function FengmingShop_OnLoad() 
	-- g_FengmingShop_Frame_UnifiedXPosition = FengmingShop_Frame:GetProperty("UnifiedXPosition") 
	-- g_FengmingShop_Frame_UnifiedYPosition = FengmingShop_Frame:GetProperty("UnifiedYPosition")

	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if( curWorldBank_UIPos ~= nil) then
        FengmingShop_Frame : SetProperty("UnifiedPosition", curWorldBank_UIPos )
    else
        Variable : SetVariable("WorldBank_UIPos", FengmingShop_Frame : GetProperty("UnifiedPosition"), 1)
	end

	g_FengmingShop_listctrl = {
	[1]={frame=FengmingShop_Item1Frame, action=FengmingShop_Item1, mask=FengmingShop_Item1_Mask, numtext=FengmingShop_Item1_BuyLimitNum,
			 nametext=FengmingShop_Item1Text, limitbk=FengmingShop_Item1_BuyLimitNumBK, limitimg=FengmingShop_Item1Info_Limit, needdaibi=FengmingShop_Item1Info_Dynamic},
	[2]={frame=FengmingShop_Item2Frame, action=FengmingShop_Item2, mask=FengmingShop_Item2_Mask, numtext=FengmingShop_Item2_BuyLimitNum,
			 nametext=FengmingShop_Item2Text, limitbk=FengmingShop_Item2_BuyLimitNumBK, limitimg=FengmingShop_Item2Info_Limit, needdaibi=FengmingShop_Item2Info_Dynamic},
	[3]={frame=FengmingShop_Item3Frame, action=FengmingShop_Item3, mask=FengmingShop_Item3_Mask, numtext=FengmingShop_Item3_BuyLimitNum,
			 nametext=FengmingShop_Item3Text, limitbk=FengmingShop_Item3_BuyLimitNumBK, limitimg=FengmingShop_Item3Info_Limit, needdaibi=FengmingShop_Item3Info_Dynamic},
	[4]={frame=FengmingShop_Item4Frame, action=FengmingShop_Item4, mask=FengmingShop_Item4_Mask, numtext=FengmingShop_Item4_BuyLimitNum,
			 nametext=FengmingShop_Item4Text, limitbk=FengmingShop_Item4_BuyLimitNumBK, limitimg=FengmingShop_Item4Info_Limit, needdaibi=FengmingShop_Item4Info_Dynamic},
	[5]={frame=FengmingShop_Item5Frame, action=FengmingShop_Item5, mask=FengmingShop_Item5_Mask, numtext=FengmingShop_Item5_BuyLimitNum,
			 nametext=FengmingShop_Item5Text, limitbk=FengmingShop_Item5_BuyLimitNumBK, limitimg=FengmingShop_Item5Info_Limit, needdaibi=FengmingShop_Item5Info_Dynamic},
	[6]={frame=FengmingShop_Item6Frame, action=FengmingShop_Item6, mask=FengmingShop_Item6_Mask, numtext=FengmingShop_Item6_BuyLimitNum,
			 nametext=FengmingShop_Item6Text, limitbk=FengmingShop_Item6_BuyLimitNumBK, limitimg=FengmingShop_Item6Info_Limit, needdaibi=FengmingShop_Item6Info_Dynamic},
	[7]={frame=FengmingShop_Item7Frame, action=FengmingShop_Item7, mask=FengmingShop_Item7_Mask, numtext=FengmingShop_Item7_BuyLimitNum,
			 nametext=FengmingShop_Item7Text, limitbk=FengmingShop_Item7_BuyLimitNumBK, limitimg=FengmingShop_Item7Info_Limit, needdaibi=FengmingShop_Item7Info_Dynamic},
	[8]={frame=FengmingShop_Item8Frame, action=FengmingShop_Item8, mask=FengmingShop_Item8_Mask, numtext=FengmingShop_Item8_BuyLimitNum,
			 nametext=FengmingShop_Item8Text, limitbk=FengmingShop_Item8_BuyLimitNumBK, limitimg=FengmingShop_Item8Info_Limit, needdaibi=FengmingShop_Item8Info_Dynamic},
	[9]={frame=FengmingShop_Item9Frame, action=FengmingShop_Item9, mask=FengmingShop_Item9_Mask, numtext=FengmingShop_Item9_BuyLimitNum,
			 nametext=FengmingShop_Item9Text, limitbk=FengmingShop_Item9_BuyLimitNumBK, limitimg=FengmingShop_Item9Info_Limit, needdaibi=FengmingShop_Item9Info_Dynamic},
	[10]={frame=FengmingShop_Item10Frame, action=FengmingShop_Item10, mask=FengmingShop_Item10_Mask, numtext=FengmingShop_Item10_BuyLimitNum,
			 nametext=FengmingShop_Item10Text, limitbk=FengmingShop_Item10_BuyLimitNumBK, limitimg=FengmingShop_Item10Info_Limit, needdaibi=FengmingShop_Item10Info_Dynamic},
	[11]={frame=FengmingShop_Item11Frame, action=FengmingShop_Item11, mask=FengmingShop_Item11_Mask, numtext=FengmingShop_Item11_BuyLimitNum,
			 nametext=FengmingShop_Item11Text, limitbk=FengmingShop_Item11_BuyLimitNumBK, limitimg=FengmingShop_Item11Info_Limit, needdaibi=FengmingShop_Item11Info_Dynamic},
	[12]={frame=FengmingShop_Item12Frame, action=FengmingShop_Item12, mask=FengmingShop_Item12_Mask, numtext=FengmingShop_Item12_BuyLimitNum,
			 nametext=FengmingShop_Item12Text, limitbk=FengmingShop_Item12_BuyLimitNumBK, limitimg=FengmingShop_Item12Info_Limit, needdaibi=FengmingShop_Item12Info_Dynamic},
	[13]={frame=FengmingShop_Item13Frame, action=FengmingShop_Item13, mask=FengmingShop_Item13_Mask, numtext=FengmingShop_Item13_BuyLimitNum,
			 nametext=FengmingShop_Item13Text, limitbk=FengmingShop_Item13_BuyLimitNumBK, limitimg=FengmingShop_Item13Info_Limit, needdaibi=FengmingShop_Item13Info_Dynamic},
	[14]={frame=FengmingShop_Item14Frame, action=FengmingShop_Item14, mask=FengmingShop_Item14_Mask, numtext=FengmingShop_Item14_BuyLimitNum,
			 nametext=FengmingShop_Item14Text, limitbk=FengmingShop_Item14_BuyLimitNumBK, limitimg=FengmingShop_Item14Info_Limit, needdaibi=FengmingShop_Item14Info_Dynamic},
	[15]={frame=FengmingShop_Item15Frame, action=FengmingShop_Item15, mask=FengmingShop_Item15_Mask, numtext=FengmingShop_Item15_BuyLimitNum,
			 nametext=FengmingShop_Item15Text, limitbk=FengmingShop_Item15_BuyLimitNumBK, limitimg=FengmingShop_Item15Info_Limit, needdaibi=FengmingShop_Item15Info_Dynamic},
	}
	g_FengmingShop_tabctrl = {
		[0]=FengmingShop_But1, 
		[1]=FengmingShop_But2,
		[2]=FengmingShop_But3,
	}
end
 
--=========
-- Event
--=========
---   !!!reloadscript =FengmingShop
function FengmingShop_OnEvent(event) 
	if event == "UPDATE_FENGMINGSHOP" then   
		local inputtype = tonumber(arg0) 
		if inputtype < 0 or inputtype > 2 then
			return
		end
		g_FengmingShop_Type = inputtype
		-- g_FengmingShop_TargetId = tonumber(arg1) 
		g_FengmingShop_isLFOwner = tonumber(arg2)
		g_FengmingShop_isAnyOwner = tonumber(arg3)
		g_FengmingShop_IsGuildTimeOK = tonumber(arg4)

		-- local objCared = DataPool : GetNPCIDByServerID(g_FengmingShop_TargetId)
		-- this:CareObject(objCared, 1, "FengmingShop");
		g_FengmingShop_tabctrl[g_FengmingShop_Type]:SetCheck(1)
		FengmingShop_Open()
		this:Show()
	elseif event == "UPDATE_FENGMINGSHOP_DAIBI" then
		local curDaibiTotal = NpcShop:GetFengMingShopDaiBi()
		local infostr = ScriptGlobal_Format("#{FMSD_220705_21}", curDaibiTotal)
		FengmingShop_Currency1:SetText(infostr)
	elseif event == "UPDATE_YUANBAO" then
		local curYB = Player:GetData("YUANBAO")
		local infostr1 = ScriptGlobal_Format("#{FMSD_220705_55}", curYB)
		FengmingShop_Currency2:SetText(infostr1)
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		FengmingShop_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		FengmingShop_Close()
	elseif event == "ADJEST_UI_POS" then
    FengmingShop_On_ResetPos() 	
	end

end
 
--=========
-- 重置
--=========
function FengmingShop_On_ResetPos()

	-- FengmingShop_Frame:SetProperty("UnifiedXPosition", g_FengmingShop_Frame_UnifiedXPosition)
	-- FengmingShop_Frame:SetProperty("UnifiedYPosition", g_FengmingShop_Frame_UnifiedYPosition)

	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if( curWorldBank_UIPos ~= nil) then
        FengmingShop_Frame : SetProperty("UnifiedPosition", curWorldBank_UIPos )
	end

end

function FengmingShop_OnHiden()
    FengmingShop_Close()
end
--=========
-- 关闭
--=========
function FengmingShop_Close()
	CloseWindow( "FengmingShop_MBuy", true );
	g_FengmingShop_Type = 0
	g_FengmingShop_CurPage = 1
	this:Hide()
end

--=========
-- 打开
--=========
function FengmingShop_Open()

	-- 总界面控制
    -- 关闭其他所有界面组 页签高亮
	FengmingShop_CloseSameGroupWindow()
	
	local curDaibiTotal = NpcShop:GetFengMingShopDaiBi()

	local infostr = ScriptGlobal_Format("#{FMSD_220705_21}", curDaibiTotal)
	FengmingShop_Currency1:SetText(infostr)
	
	local curYB = Player:GetData("YUANBAO")
	local infostr1 = ScriptGlobal_Format("#{FMSD_220705_55}", curYB)
	FengmingShop_Currency2:SetText(infostr1)

	for i=1,g_FengmingShop_PerPageCount do
		g_FengmingShop_listctrl[i].frame:Hide()
	end

	local tblinfo= NpcShop:GetFengMingShopData(g_FengmingShop_Type,g_FengmingShop_CurPage, g_FengmingShop_PerPageCount)
	if type(tblinfo) ~= "table" then
		PushDebugMessage("error")
		return
	end 

	for i = 1, table.getn(tblinfo) do
		local itemid 	    = tblinfo[i].itemid
		local itemnum 	    = tblinfo[i].itemnum
		local itemname     = tblinfo[i].itemname
		local daibitype = tblinfo[i].daibitype
		local price      = tblinfo[i].price
		local limitweek     = tblinfo[i].limitweek
		local limitweek_self= tblinfo[i].limitweek_self
		local limitpermanent      = tblinfo[i].limitpermanent
		local limitpermanent_self = tblinfo[i].limitpermanent_self
		local byz = tblinfo[index].byzmin
		g_FengmingShop_listctrl[i].frame:Show()

		--PushDebugMessage("limitday = "..limitday.."  limitweek = "..limitweek.."limitmonth = "..limitmonth.."limitpermanent = "..limitpermanent)	
        --PushDebugMessage("limitday_self = "..limitday_self.."  limitweek_self = "..limitweek_self.."limitmonth_self = "..limitmonth_self.."limitpermanent_self = "..limitpermanent_self)	
		if limitweek > 0 then
			g_FengmingShop_listctrl[i].limitbk:Show()
			g_FengmingShop_listctrl[i].limitimg:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week")
			g_FengmingShop_listctrl[i].numtext:SetText(limitweek_self)
			if limitweek_self ~= 0 then
				g_FengmingShop_listctrl[i].limitbk:Show()
				g_FengmingShop_listctrl[i].mask:Hide()
			else
				g_FengmingShop_listctrl[i].limitbk:Hide()
				g_FengmingShop_listctrl[i].mask:Show()
			end
		elseif limitpermanent > 0 then
			g_FengmingShop_listctrl[i].limitbk:Show()
			g_FengmingShop_listctrl[i].limitimg:SetProperty("Image", "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever")
			g_FengmingShop_listctrl[i].numtext:SetText(limitpermanent_self)
			if limitpermanent_self ~= 0 then
				g_FengmingShop_listctrl[i].limitbk:Show()
				g_FengmingShop_listctrl[i].mask:Hide()
			else
				g_FengmingShop_listctrl[i].limitbk:Hide()
				g_FengmingShop_listctrl[i].mask:Show()
			end
		else
			g_FengmingShop_listctrl[i].limitbk:Hide()
			g_FengmingShop_listctrl[i].limitimg:SetProperty("Image", "")
			g_FengmingShop_listctrl[i].mask:Hide()
		end
		-- 道具展示区域
		
    local theAction = DataPool:CreateBindActionItemForShow(itemid, itemnum)
 --   local theAction = DataPool:CreateBindActionItemForShowWithMaxNum(itemid,itemnum,countLeft)
    if theAction:GetID() ~= 0 then
			g_FengmingShop_listctrl[i].action:SetActionItem(theAction:GetID())
		end
		g_FengmingShop_listctrl[i].nametext:SetText(DataPool:Lua_GetItemNameByIndex(itemid)) 
		if daibitype == 1 then
			g_FengmingShop_listctrl[i].needdaibi:SetText(ScriptGlobal_Format("#{FMSD_220705_20}",price))

			if itemid == 38007006 and g_FengmingShop_isAnyOwner == 0 then
				g_FengmingShop_listctrl[i].mask:Show()
			end
			if itemid == 38005074 or itemid == 38007007 then
				if g_FengmingShop_isLFOwner == 0 then
					g_FengmingShop_listctrl[i].mask:Show()
				end
			end
			if itemid == 38007925 and g_FengmingShop_IsGuildTimeOK == 0 then
				g_FengmingShop_listctrl[i].mask:Show()
			end
		elseif daibitype == 2 then
			g_FengmingShop_listctrl[i].needdaibi:SetText(ScriptGlobal_Format("#{FMSD_220705_58}",price))
		end
	end

  if g_FengmingShop_CurPage == 1 then
      FengmingShop_UpPage:Disable()
  else
      FengmingShop_UpPage:Enable()
  end
	local nTotalCount = NpcShop:GetFengMingShopTotalCount(g_FengmingShop_Type)
  if g_FengmingShop_CurPage*g_FengmingShop_PerPageCount >= nTotalCount then
      FengmingShop_DownPage:Disable()
  else
      FengmingShop_DownPage:Enable()
  end

  local npagecount = 0
  if nTotalCount <= g_FengmingShop_PerPageCount then
      npagecount = 1
  elseif math.mod(nTotalCount, g_FengmingShop_PerPageCount) == 0  then
      npagecount = math.floor(nTotalCount/g_FengmingShop_PerPageCount)
  else
      npagecount = math.floor(nTotalCount/g_FengmingShop_PerPageCount) + 1
  end
  FengmingShop_CurrentlyPage:SetText( ScriptGlobal_Format("#{FMSD_220705_24}",g_FengmingShop_CurPage, npagecount) )		
end

function FengmingShop_Clicked(index)
    -- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	local nLevel = Player:GetLevel();
	if nLevel < 85  then        
		PushDebugMessage("#{FMSD_220705_26}")
		return
	end
	--跨周中 服务器检测
	local tblinfo= NpcShop:GetFengMingShopData(g_FengmingShop_Type,g_FengmingShop_CurPage, g_FengmingShop_PerPageCount)
	
	if type(tblinfo) ~= "table" or tblinfo[index]  == nil then
		PushDebugMessage("error")
		return
	end 
	local itemid 	    = tblinfo[index].itemid
	local itemnum 	    = tblinfo[index].itemnum
	local daibitype = tblinfo[index].daibitype
	local price     = tblinfo[index].price
	local limitweek     = tblinfo[index].limitweek
	local limitweek_self= tblinfo[index].limitweek_self
	local limitpermanent      = tblinfo[index].limitpermanent
	local limitpermanent_self = tblinfo[index].limitpermanent_self
	local byz = tblinfo[index].byzmin

	if  (limitweek > 0 and limitweek_self <= 0) or (limitpermanent > 0 and limitpermanent_self  <= 0) then
		PushDebugMessage("#{FMSD_220705_46}")
		return
	end
	if daibitype == 1 then
		if itemid == 38007006 and g_FengmingShop_isAnyOwner == 0 then
			PushDebugMessage("#{FMSD_220705_43}")
			return
		end
		if itemid == 38005074 or itemid == 38007007 then
			if g_FengmingShop_isLFOwner == 0 then
				PushDebugMessage("#{FMSD_220705_44}")
				return
			end
		end
		if itemid == 38007925 and g_FengmingShop_IsGuildTimeOK == 0 then
			if byz == 0 then
				PushDebugMessage("#{FMSD_220705_63}")
			else
				PushDebugMessage( ScriptGlobal_Format("#{FMSD_220705_42}", byz) )
			end
			return
		end
	end
	
	if CheckBuyMult() == 1 then
  	PushEvent("OPEN_FENGMINGSHOP_BUY",g_FengmingShop_TargetId, g_FengmingShop_Type, g_FengmingShop_CurPage, index )
  else
	local curDaibiTotal = 0
	if daibitype == 1 then
		curDaibiTotal = NpcShop:GetFengMingShopDaiBi()
		if curDaibiTotal < price then
				local infostr = ScriptGlobal_Format("#{FMSD_220705_47}", price)
				PushDebugMessage(infostr)
				return
			end
		elseif daibitype == 2 then
			curDaibiTotal = Player:GetData("YUANBAO")
			if curDaibiTotal < price then
				local infostr = ScriptGlobal_Format("#{FMSD_220705_56}", price)
				PushDebugMessage(infostr)
				return
			end
		else
			return
		end
--		local cancout= NpcShop:FengmingShopCalcMaxNumCanBuy(itemid,itemnum,g_FengmingShop_Type,curDaibiTotal,price,0,0,1,1)
--		if cancout <= 0 then
--			return
--		end
		if daibitype == 1 then
			-- #cfff263您将花费#G%s0#cfff263代币， 购买#G%s1#cfff263个#G%s2#cfff263，您确定吗？
			local strd = ScriptGlobal_Format( "#{FMSD_220705_50}",price,itemnum,DataPool:Lua_GetItemNameByIndex(itemid) )
			PushEvent("CONFIRM_FENGMINGSHOP_BUY",g_FengmingShop_TargetId, g_FengmingShop_Type, itemid, g_FengmingShop_CurPage, strd)
		elseif daibitype == 2 then
			local strd = ScriptGlobal_Format( "#{FMSD_220705_57}",price,itemnum,DataPool:Lua_GetItemNameByIndex(itemid) )
			PushEvent("CONFIRM_FENGMINGSHOP_BUY",g_FengmingShop_TargetId, g_FengmingShop_Type, itemid, g_FengmingShop_CurPage, strd)
		end
  end
end 

function FengmingShop_PageDown()
	if g_FengmingShop_CurPage*g_FengmingShop_PerPageCount < NpcShop:GetFengMingShopTotalCount(g_FengmingShop_Type) then
		g_FengmingShop_CurPage = g_FengmingShop_CurPage + 1
		FengmingShop_Open()
		if ( IsWindowShow( "FengmingShop_MBuy" ) ) then
			CloseWindow( "FengmingShop_MBuy", true );
		end
	end
end


function FengmingShop_PageUp()
	if g_FengmingShop_CurPage > 1 then
		g_FengmingShop_CurPage = g_FengmingShop_CurPage - 1
		FengmingShop_Open()
		if ( IsWindowShow( "FengmingShop_MBuy" ) ) then
			CloseWindow( "FengmingShop_MBuy", true );
		end
	end
end

function FengmingShop_ChangeShowTab(idx)
	if g_FengmingShop_Type == idx and g_FengmingShop_CurPage == 1 then
		return
	end
	if ( IsWindowShow( "FengmingShop_MBuy" ) ) then
		CloseWindow( "FengmingShop_MBuy", true );
	end
	g_FengmingShop_Type = idx
	g_FengmingShop_CurPage = 1
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnAskDataByType" ); 					-- 脚本函数名称
		Set_XSCRIPT_ScriptID( 889833 );											-- 脚本编号 
		Set_XSCRIPT_Parameter( 0, g_FengmingShop_TargetId );	
		Set_XSCRIPT_Parameter( 1, g_FengmingShop_Type );		 
		Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数
	Send_XSCRIPT()
end

function FengmingShop_PiliangClk()
	if ( IsWindowShow( "FengmingShop_MBuy" ) ) then
		CloseWindow( "FengmingShop_MBuy", true );
	end
	-- 进入批量购买状态
	PrepearBuyMult()
end

-- 天荒商行 分页4

-- SHZJ_241220_04	云锦行
-- SHZJ_241220_05	华玉集
-- SHZJ_241220_06	聚侠堂
-- SHZJ_241220_07	天荒商行
function FengmingShop_ChangeWorldBankPage(nPageIndex)

    FengmingShop_YunJin    :   SetCheck(0)
	FengmingShop_HuaYu     :   SetCheck(0)
	FengmingShop_JuXia     :   SetCheck(0)
	FengmingShop_TianHuang :   SetCheck(1)
	FengmingShop_XiaKe	   :   SetCheck(0)

	Variable : SetVariable("WorldBank_UIPos", FengmingShop_Frame : GetProperty("UnifiedPosition"), 1)

    if 1 == nPageIndex then
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "OnAskData_L" ); 	    -- 函数名
            Set_XSCRIPT_ScriptID( 888393 );						-- 脚本编号
            Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
        Send_XSCRIPT()
        return
    end

    if 2 == nPageIndex then
        PushEvent("OPEN_HUOYUESHOP_H")
        return
    end

    if 3 == nPageIndex then
        -- if Player:GetLevel() < 60 then        
        --     PushDebugMessage(ScriptGlobal_Format("#{PVPZH_220124_53}", 60))
        --     return
        -- end
        -- PushEvent("UPDATE_PVPSHOP_DAIBI1", 1, -1, 1)
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "FCOnAskDataByType" ); 					    -- 脚本函数名称
            Set_XSCRIPT_ScriptID( 888969 );											-- 脚本编号  
            Set_XSCRIPT_Parameter( 0, 1 );	
            Set_XSCRIPT_Parameter( 1, -1 );		     
            Set_XSCRIPT_ParamCount( 2 ); 	                                        -- 参数个数  
        Send_XSCRIPT()	
        return
    end

    if 4 == nPageIndex then
        -- Clear_XSCRIPT()
        --     Set_XSCRIPT_Function_Name( "OnAskDataByType" ); 					    -- 脚本函数名称
        --     Set_XSCRIPT_ScriptID( 889833 );											-- 脚本编号 
        --     Set_XSCRIPT_Parameter( 0, -1 );	
        --     Set_XSCRIPT_Parameter( 1, 0 );		 
        --     Set_XSCRIPT_ParamCount( 2 ); 	-- 参数个数
        -- Send_XSCRIPT()
        return
	end

	if 5 == nPageIndex then
		PushEvent("UI_COMMAND", 18201)
        return
    end
end

function FengmingShop_CloseSameGroupWindow()

	FengmingShop_On_ResetPos()

    CloseWindow("ActivitySchedule_Shop2", true)
    CloseWindow("ActivitySchedule_Shop", true)
    CloseWindow("Fenzheng_Shop", true)
	-- CloseWindow("FengmingShop", true)
	CloseWindow("Xiake_Shop", true)
    
    FengmingShop_YunJin    :   SetCheck(0)
	FengmingShop_HuaYu     :   SetCheck(0)
	FengmingShop_JuXia     :   SetCheck(0)
	FengmingShop_TianHuang :   SetCheck(1)
	FengmingShop_XiaKe	   :   SetCheck(0)

	local nXiaKe = Player:GetData("IsXiaKe") 
    if nXiaKe ~= 1 then
        FengmingShop_XiaKe:Hide()
    else
        FengmingShop_XiaKe:Show()
    end
end