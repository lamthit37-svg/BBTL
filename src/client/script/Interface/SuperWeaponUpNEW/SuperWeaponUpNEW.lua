
local ObjCaredIDID = -1
local ObjCaredID = -1
local g_ItemPos = -1
local g_NewId = -1
local g_NeedMoney = -1
local MAX_OBJ_DISTANCE = 3.0
local g_Accept_Clicked_Num = 0
local g_Is92ShenQi = 0
local g_SuperIsWashed =0
--=========================================================
--常量定义
--=========================================================
--local MIN_MENPAI_IDX = 0
--local MAX_MENPAI_IDX = 8

function SuperWeaponUpNEW_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "OBJECT_CARED_EVENT" )
	this : RegisterEvent( "PACKAGE_ITEM_CHANGED" )
	this : RegisterEvent( "MONEY_CHANGE_EX" )
	this : RegisterEvent( "MONEYJZ_CHANGE_EX" )
	this : RegisterEvent( "UPDATE_SHENQIUP" )
	this : RegisterEvent( "RESUME_ENCHASE_GEM" )
	this : RegisterEvent( "NEW_DEBUGMESSAGE" )

	this : RegisterEvent( "SUPERATTR_UPDATE_RECOIN" )
	this : RegisterEvent( "SUPER_ATTR_RECOIN_CONFIRM_OK" )

end

function SuperWeaponUpNEW_OnLoad()
	SuperWeaponUpNEW_Hide_RadioText();
	g_SuperIsWashed =0
end


--=========================================================
--事件响应
--=========================================================
function SuperWeaponUpNEW_OnEvent( event )

	if event == "UI_COMMAND" and tonumber(arg0) == 19831114 then
		local targetId = Get_XParam_INT(0)
		ObjCaredID = DataPool : GetNPCIDByServerID( targetId )
		if ObjCaredID == -1 then
			--PushDebugMessage("server传过来的数据有问题。")
			return
		end
		ObjCaredIDID = targetId
		BeginCareObject_SuperWeaponUpNEW()
		SuperWeaponUpNEW_Clear(1)
		SuperWeaponUpNEW_MoneyUpdate()
		this : Show()
--	elseif (event == "UI_COMMAND" ) and tonumber(arg0) == 198311141 then

--		AnqiShuxingNEW_Update(g_ItemPos)

	elseif event == "MONEY_CHANGE_EX" then
		SuperWeaponUpNEW_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )

	elseif event == "MONEYJZ_CHANGE_EX" then
		SuperWeaponUpNEW_HaveNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )

	elseif event == "OBJECT_CARED_EVENT" then
		if( tonumber(arg0) ~= ObjCaredID ) then
			return
		end
		if( arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1=="destroy" ) then
			SuperWeaponUpNEW_Close()
		end

	elseif event == "RESUME_ENCHASE_GEM" then
		SuperWeaponUpNEW_Resume_Equip_Gem()

	elseif event == "PACKAGE_ITEM_CHANGED" then
		if( arg0~= nil and -1 == tonumber(arg0)) then
			return;
		end

		if tonumber(arg0) == g_ItemPos then
			SuperWeaponUpNEW_Resume_Equip_Gem()
		end

	elseif event == "UPDATE_SHENQIUP" then
		if arg0 ~= nil then
			SuperWeaponUpNEW_Update( arg0 )
		end
	--显示神器炼魂后的新属性
	elseif event == "SUPERATTR_UPDATE_RECOIN" then
		--更新重启的属性
	--	PushDebugMessage(tonumber(arg0))
		if arg0 ~= nil then
			SuperWeaponUpNEW_UpDateRecoin(arg0)
		end

	elseif event == "SUPER_ATTR_RECOIN_CONFIRM_OK" then
		if tonumber(arg1) == 1 then
			SuperWeaponUpNEW_Clear(1) --先把原来的清空了
			SuperWeaponUpNEW_Update(tonumber(arg0)) --再放上新的~
		elseif tonumber(arg1) == 0 then
			SuperWeaponUpNEW_Clear(1)
			this:Hide()
		elseif tonumber(arg1) == 2 then
			SuperWeaponUpNEW_Clear(1) --先把原来的清空了
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 198311141 then
		local bagpos = Get_XParam_INT(0)
		if bagpos ~= nil then
			SuperWeaponUpNEW_Clear(1)
			SuperWeaponUpNEW_Update( tonumber(bagpos) )
		end

	end

end

--=========================================================
--确定按钮
--=========================================================
function SuperWeaponUpNEW_Buttons_Clicked()

	--判断电话密保和二级密码保护2012.6.11-LIUBO
	if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then
		return
	end
	-- 判断是否为安全时间2012.6.11-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

	if g_ItemPos ~= -1 and PlayerPackage : GetItemTableIndex( g_ItemPos ) > 0 then


    --Deleted By ChangHua 2010-03-01 TT:66410
    --神器被加锁时也可以进行升级操作
	--	if PlayerPackage : IsLock( g_ItemPos ) == 1 then
	--		PushDebugMessage( "物品不存在或者已加锁！" )
	--		return
	--	end

		--钱是否够....
		local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ") --交子普及 Vega
		if selfMoney < g_NeedMoney then
			PushDebugMessage( "#{CXYH_140813_40}" )
			return
		end

	local eqLevel = LifeAbility : Get_Equip_Level(g_ItemPos)--获取装备等级

	--PushDebugMessage(g_ItemPos)
	if eqLevel == nil then
		return
	end

	--PushDebugMessage("333"..eqLevel)
	if(eqLevel == 92) then
		if(SuperWeaponUpNEW_ModeSelect:GetCheck()==0 and SuperWeaponUpNEW_ModeSelect2:GetCheck() ==0) then
			PushDebugMessage("#{SXLH_101026_01}")--这个要不要配字典
			return
		end
	end

		if (g_ItemPos ~= -1) then
			local ItemID = PlayerPackage : GetItemTableIndex( g_ItemPos )
			if eqLevel and eqLevel == 92 then
				--30505817,30505908
				--因为92级的消耗的材料（即神兵符），没有在SuperWeanponUp.txt里面配置，所以在此单写了。先实现功能
					local MatLevel2,MatNum2,MatLevel3,MatNum3
					MatLevel2 = 30505817;--神兵符2级
					MatLevel3 = 30505908;--神兵符3级
					local nHaveNum2 = 0
					local nHaveNum3 = 0
					nHaveNum2 = Player :IsHaveItem(MatLevel2,MatNum2)
					nHaveNum3 = Player :IsHaveItem(MatLevel3,MatNum3)
					if (nHaveNum2 + nHaveNum3< 5) then--现在都是5，但都是从表里读的，还会变吗？
						PushDebugMessage( "#{CXYH_140813_39}" )
						return
					end
			else
            --Modified By ChangHua TT:76126 10/07/12 低级神器可以使用同等级或者更高级神兵符,优先使用低级
			local MatID1,MatNum1,MatID2,MatNum2,MatID3,MatNum3 = ShenqiUpgrade : GetShenqiUpMaterial( ItemID, 0 )
            local nHaveNum = 0
            local nHaveNum1 = 0
            local nHaveNum2 = 0
            local nHaveNum3 = 0
            if MatID1 == -1 then --策划表出现错误，应该assert
                return
            else
			    nHaveNum1 = Player : IsHaveItem( MatID1, MatNum1)
            end

            if MatID2 == -1 then --策划表出现错误，应该assert
                nHaveNum2 = 0
            else
			    nHaveNum2 = Player : IsHaveItem( MatID2, MatNum2)
            end
            if MatID3 == -1 then --策划表出现错误，应该assert
                nHaveNum3 = 0
            else
			    nHaveNum3 = Player : IsHaveItem( MatID3, MatNum3)
            end

            --注意，这里MatNum1,MatNum2,MatNum3 如果不等于-1，则为5
            nHaveNum = nHaveNum1 + nHaveNum2 + nHaveNum3
			if (nHaveNum < MatNum1) then
				PushDebugMessage( "#{CXYH_140813_39}" )
				return
			end
		end
		end

		if (g_Accept_Clicked_Num == 0) then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "ShenQiConfirm" )
				Set_XSCRIPT_ScriptID( 500505 )
				Set_XSCRIPT_Parameter( 0, g_ItemPos )
				Set_XSCRIPT_Parameter( 1, ObjCaredIDID )

				Set_XSCRIPT_ParamCount( 2 )
			Send_XSCRIPT()
			g_Accept_Clicked_Num = 1
		else
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name( "OnShenqiUpgrade" )
				Set_XSCRIPT_ScriptID( 500505 )
				Set_XSCRIPT_Parameter( 0, g_ItemPos )
				Set_XSCRIPT_Parameter( 1, ObjCaredIDID )
				--上面的if语句中，参数不用增加
				if( SuperWeaponUpNEW_ModeSelect:GetCheck() == 1) then
					g_Is92ShenQi = 1
				else
					g_Is92ShenQi = 0
				end
			--	PushDebugMessage(g_Is92ShenQi)
				Set_XSCRIPT_Parameter( 2, g_Is92ShenQi )
				Set_XSCRIPT_ParamCount( 3 )
			Send_XSCRIPT()
			--SuperWeaponUpNEW_Clear(1)
		--	SuperWeaponUpNEW_Hide_RadioText()
		end

	else
		PushDebugMessage( "#{CXYH_140813_38}" )
	end
end


--保留新属性
function SuperWeaponUpNEW_Tihuan_Clicked()

	if g_SuperIsWashed ==1 then

 		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("DoRefreshSuperAttr");
			Set_XSCRIPT_ScriptID(500505);
			Set_XSCRIPT_Parameter(0,g_ItemPos);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
	end

		--设置重洗状态
	g_SuperIsWashed =0

--	SuperWeaponUpNEW_Clear(0)
--	SuperWeaponUpNEW_Update(g_ItemPos)
end



--=========================================================
--更新界面
--=========================================================
function SuperWeaponUpNEW_Update( pos_packet )
	local BagIndex = tonumber( pos_packet )
	local theAction = EnumAction( BagIndex, "packageitem" )

	if theAction : GetID() == 0 then
		return
	end

	--必须是可兑换的神器....
	local MenpaiID = Player : GetData( "MEMPAI" )
	local ItemID = PlayerPackage : GetItemTableIndex( BagIndex )
	if ItemID <= 0 then
		PushDebugMessage("这个物品不是可兑换的神器！")
		return
	end

	g_NewId, g_NeedMoney = ShenqiUpgrade : GetShenqiUpgradeInfo( ItemID, MenpaiID )
	if g_NewId == -1 then
		PushDebugMessage("#{CXYH_140813_37}")
		return
	end

		-- 如果空格内已经有对应物品了,需要弹一个二次确认……
	if g_ItemPos ~= -1 and BagIndex ~= g_ItemPos and  g_SuperIsWashed == 1  then
		SuperWeaponUpNEW_SendSuper_AttrConfirm(BagIndex,1)
		return
	end

	--更换ActionButton....
	if g_ItemPos ~= -1 then
		LifeAbility : Lock_Packet_Item( g_ItemPos, 0 )
	end
	LifeAbility : Lock_Packet_Item( BagIndex, 1 )
	SuperWeaponUpNEW_BeforeIcon : SetActionItem( theAction : GetID() )
	g_ItemPos = BagIndex
	SuperWeaponUpNEW_WantNum : SetProperty( "MoneyNumber", tostring( g_NeedMoney ) )
	g_Accept_Clicked_Num = 0

	local eqLevel = LifeAbility : Get_Equip_Level(BagIndex)--获取装备等级
	--PushDebugMessage(eqLevel)
	if(eqLevel == 92) then
		SuperWeaponUpNEW_Show_RadioText()
		--SuperWeaponUp_ModeSelect:SetCheck(1)
		--PushDebugMessage(SuperWeaponUp_ModeSelect:GetCheck())
	else
	  SuperWeaponUpNEW_Hide_RadioText()
	end

	local icon =  tostring(LifeAbility : Get_Item_Icon_Name(g_ItemPos))
	--PushDebugMessage("before="..icon)
	SuperWeaponUpNEW_AfterIcon:SetProperty("Image",icon)

	local num = theAction:GetEquipAttrCount()
	local str = ""
	for i = 0, num-1 do
		local tempstr = theAction:EnumEquipExtAttr(i)
		--	g_BeforeTextList[i]:SetText(tempstr)
		str = str..tempstr
		--	PushDebugMessage("tempstr="..tempstr.."/str="..str)
	end
	SuperWeaponUpNEW_BeforeAttrFirst:SetText(str)

	SuperWeaponUpNEW_OK:Enable();
end



--=========================================================
--重置界面
--=========================================================
function SuperWeaponUpNEW_Clear(cleanaction)
	--g_ItemPos = -1
	g_NewId = -1
	g_NeedMoney = -1
	g_SuperIsWashed =0
	g_Accept_Clicked_Num =0
	g_LongwenPropertyReset_Confirm = -1
	SuperWeaponUpNEW_OK:Disable()



	SuperWeaponUpNEW_BeforeAttrFirst:SetText("")
	SuperWeaponUpNEW_AfterAttrFirst:SetText("")
--	SuperWeaponUpNEW_OK:Disable()
	SuperWeaponUpNEW_AfterIcon:SetProperty("Image","")
	SuperWeaponUpNEW_Tihuan:Disable()
	if cleanaction == 1 then
		if g_ItemPos ~= -1 then
			SuperWeaponUpNEW_BeforeIcon:SetActionItem(-1)
			LifeAbility:Lock_Packet_Item(g_ItemPos, 0)
			g_ItemPos = -1
		end
	end
end


--=========================================================
--关闭
--=========================================================
function SuperWeaponUpNEW_Close()
	--关闭前也要来个二次确认
	if g_ItemPos ~= -1 and g_SuperIsWashed == 1  then
		SuperWeaponUpNEW_SendSuper_AttrConfirm(g_ItemPos,0)
		return
	end
	this : Hide()
	StopCareObject_SuperWeaponUpNEW()
	SuperWeaponUpNEW_Clear(1)
end

--=========================================================
--界面隐藏
--=========================================================
function SuperWeaponUpNEW_OnHiden()
	StopCareObject_SuperWeaponUpNEW()
	SuperWeaponUpNEW_Clear(1)
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_SuperWeaponUpNEW()
	this : CareObject( ObjCaredID, 1, "SuperWeaponUpNEW" )
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_SuperWeaponUpNEW()
	this : CareObject( ObjCaredID, 0, "SuperWeaponUpNEW" )
	SuperWeaponUpNEW_Hide_RadioText()
end

--=========================================================
--右键点击ActionButton
--=========================================================
function SuperWeaponUpNEW_Resume_Equip_Gem()

	if g_ItemPos ~= -1 and g_SuperIsWashed == 1  then
		SuperWeaponUpNEW_SendSuper_AttrConfirm(g_ItemPos,2)
		return
	end

	if( this:IsVisible() ) then

		SuperWeaponUpNEW_Clear(1)
		SuperWeaponUpNEW_Hide_RadioText()

	end


end
function SuperWeaponUpNEW_Hide_RadioText()

			SuperWeaponUpNEW_ModeSelect:SetProperty("Visible","False");
			SuperWeaponUpNEW_ModelText:SetProperty("Visible","False");
			SuperWeaponUpNEW_ModeSelect2:SetProperty("Visible","False");
			SuperWeaponUpNEW_ModelText2:SetProperty("Visible","False");
			SuperWeaponUpNEW_ModeSelect:SetCheck(0)
			SuperWeaponUpNEW_ModeSelect2:SetCheck(0)
			SuperWeaponUpNEW_ModeSelect:Disable()
			SuperWeaponUpNEW_ModeSelect2:Disable()
end

function SuperWeaponUpNEW_Show_RadioText()

			SuperWeaponUpNEW_ModeSelect:SetProperty("Visible","true");
			SuperWeaponUpNEW_ModelText:SetProperty("Visible","true");
			SuperWeaponUpNEW_ModeSelect2:SetProperty("Visible","true");
			SuperWeaponUpNEW_ModelText2:SetProperty("Visible","true");
			SuperWeaponUpNEW_ModeSelect:SetCheck(0)
			SuperWeaponUpNEW_ModeSelect2:SetCheck(0)
			SuperWeaponUpNEW_ModeSelect:Enable()
			SuperWeaponUpNEW_ModeSelect2:Enable()
end

--显示炼魂后的新属性
function SuperWeaponUpNEW_UpDateRecoin(dataindex)
	local num =  DataPool : Lua_GetSuperRecoinNum();

	local str = ""
	for i = 0, num-1 do
		local tempstr = DataPool :Lua_GetSuperRecoinEnumAttr(i)
		str = str..tempstr
	end

	SuperWeaponUpNEW_AfterAttrFirst:SetText(str)
--	LongwenPropertyResetNEW_Baoliu:Enable()
	SuperWeaponUpNEW_Tihuan:Enable()

	local icon =  tostring(LifeAbility : Get_Item_Icon_NameByDataIndex(tonumber(dataindex)))

--	PushDebugMessage(icon)
		SuperWeaponUpNEW_AfterIcon:SetProperty("Image",icon)
	g_SuperIsWashed =1
end

--发送替换炼魂后属性的二次确认
function SuperWeaponUpNEW_SendSuper_AttrConfirm(nIndex,keepopen)
	PushEvent("SUPER_ATTR_RECOIN_CONFIRM",tostring(nIndex),tostring(keepopen))
end


function SuperWeaponUpNEW_TryClear()
	if g_ItemPos ~= -1 and g_SuperIsWashed == 1  then
		SuperWeaponUpNEW_SendSuper_AttrConfirm(g_ItemPos,2)
		return
	end

	SuperWeaponUpNEW_Clear(1) --先把原来的清空了

end
--右键点击取消
function SuperWeaponUpNEW_Item_cancel()
	if( this:IsVisible() ) then

	--关闭前也要来个二次确认
		if g_ItemPos ~= -1 and g_SuperIsWashed == 1  then
			SuperWeaponUpNEW_SendSuper_AttrConfirm(g_ItemPos,2)
			return
		end
	--	this : Hide()
			SuperWeaponUpNEW_Clear(1)
			SuperWeaponUpNEW_Hide_RadioText()

	end
end

function SuperWeaponUpNEW_MoneyUpdate()
		SuperWeaponUpNEW_HaveGoldNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
		SuperWeaponUpNEW_HaveNum : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
end
