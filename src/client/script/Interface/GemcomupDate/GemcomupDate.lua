--****************************
--雕纹拆解
--****************************
local MAX_OBJ_DISTANCE = 3.0
local g_CaredNpc = -1

--装备在背包中的位置
local g_GemcomupDate_Item = -1

local g_GemcomupDate_Frame_UnifiedPosition;

local g_GemcomupDate_Space = {}

local g_GemcomupDate_Selected = 0

local g_GemcomupDate_SubSel = 0

local g_npcObjId = -1
--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function GemcomupDate_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_GEM_LEVELUP")
	this:RegisterEvent("GEM_LEVELUP_UPDATE_UI")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--元宝
	this:RegisterEvent("UPDATE_YUANBAO", false);
	--拆解确认
	this:RegisterEvent("SURE_GEM_LEVELUP");
end

--=========================================================
-- 载入初始化
--=========================================================
function GemcomupDate_OnLoad()
	g_GemcomupDate_Item = -1

	g_GemcomupDate_Frame_UnifiedPosition=GemcomupDate_Frame:GetProperty("UnifiedPosition");
	g_GemcomupDate_Space={
	GemcomupDate_Space1,
	GemcomupDate_Space2,
	GemcomupDate_Space3,
	GemcomupDate_Space4
	}
end

--=========================================================
-- 事件处理
--=========================================================
function GemcomupDate_OnEvent(event)
	
	if (event == "UI_COMMAND" and tonumber(arg0) == 201408140) then
		g_npcObjId = tonumber(Variable:GetVariable("GemNPCObjId"));
		Variable:SetVariable("GemNPCObjId", "", 1)
--		if(npcObjId == nil) then
--			npcObjId = Get_XParam_INT( 0 )
--		end

		g_CaredNpc = DataPool : GetNPCIDByServerID(g_npcObjId);
		if g_CaredNpc == -1 then
				PushDebugMessage("Error!");
				return;
		end
		GemcomupDate_BeginCareObject()

		local GemUnionPos = Variable:GetVariable("GemUnionPos");
		if(GemUnionPos ~= nil) then
		  GemcomupDate_Frame:SetProperty("UnifiedPosition", GemUnionPos);
		end
		GemcomupDate_FenYe6:SetCheck(1)
		
		if NpcShop:GetGemLevelupDirectly()==0 then--不直接升级
			GemcomupDate_YuanBaoPay_Button:SetCheck(1);
		else
			GemcomupDate_YuanBaoPay_Button:SetCheck(0);
		end

		GemcomupDate_Clear()
		GemcomupDate_UpdateBasic()
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 201408141 and this:IsVisible()) then
		--刷新
		local itemPos = Get_XParam_INT( 0 )
		local gem_Index = Get_XParam_INT( 1 )
		local gem_subIndex = Get_XParam_INT( 2 )
		GemcomupDate_Update(itemPos)
		GemcomupDate_SelectedTwo(gem_Index,gem_subIndex)
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if (tonumber(arg0) ~= g_CaredNpc) then
			return
		end
		if ((arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE) or arg1=="destroy") then
			GemcomupDate_Close()
		end
	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if (arg0~= nil and -1 == tonumber(arg0)) then
			return
		end
		if (g_GemcomupDate_Item == tonumber(arg0)) then
			GemcomupDate_Resume_GemInfo()
		end
	elseif (event == "UPDATE_GEM_LEVELUP" and this:IsVisible() ) then
		if arg0 ~= nil then
			GemcomupDate_Update(arg0)
			GemcomupDate_UpdateBasic()
		end
	elseif (event == "GEM_LEVELUP_UPDATE_UI" and this:IsVisible() ) then
		GemcomupDate_Mjingshi_Button:SetCheck(0)
		GemcomupDate_Jingshi_Button:SetCheck(0)	
		if g_GemcomupDate_SubSel == 1 then
			GemcomupDate_Mjingshi_Button:SetCheck(1)
		end
		if g_GemcomupDate_SubSel == 2 then
			GemcomupDate_Jingshi_Button:SetCheck(1)	
		end
	elseif (event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible()) then
		if (arg0 ~= nil) then
			GemcomupDate_Resume_GemInfo()
			GemcomupDate_UpdateBasic()
		end
	--挪拽
	elseif (event == "ADJEST_UI_POS" ) then
		GemcomupDate_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		GemcomupDate_Frame_On_ResetPos()
	--元宝
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		GemcomupDate_UpdateBasic()
	end
end

--=========================================================
-- 更新基本显示信息
--=========================================================
function GemcomupDate_UpdateBasic()
	GemcomupDate_SelfYuanbao:SetText(tostring(Player:GetData("YUANBAO")));
end

--=========================================================
-- 重置界面
--=========================================================
function GemcomupDate_Clear()
	if g_GemcomupDate_Item ~= -1 then
		GemcomupDate_Special_Button:SetActionItem(-1)
		LifeAbility:Lock_Packet_Item(g_GemcomupDate_Item, 0)

		g_GemcomupDate_Item = -1
		GemcomupDate_Mjingshi_Button:Hide()
		GemcomupDate_Mjingshi_TXT:Hide()
		GemcomupDate_Jingshi_TXT:Hide()
		GemcomupDate_Jingshi_Button:Hide()
	end
	for i=1,4 do
		g_GemcomupDate_Space[i]:SetActionItem(-1)
		g_GemcomupDate_Space[i]:SetProperty( "BackImage", "" )
	end
--	GemcomupDate_UpdateBasic()
	GemcomupDate_Mjingshi_Button:Hide()
	GemcomupDate_Mjingshi_TXT:Hide()
	GemcomupDate_Jingshi_Button:Hide()
	GemcomupDate_Jingshi_TXT:Hide()

	GemcomupDate_NeedYuanbao:SetText("")
	g_GemcomupDate_SubSel = 0
	GemcomupDate_OK:Disable()
end

function GemcomupDate_OnHidden()
	GemcomupDate_Clear()
end

--- 判断是否是礼金宝石。这里使用了比较蛋疼的判断方法，就是名字里面是否有"·通"
function GemcomupDate_IsLiJinGem( nGemID )
    if nGemID == -1 then
        return 0
    end

    local gemName = DoubleGem:GetGemNamebyID( nGemID )
    if gemName == nil or gemName == "" then
        return 0
    end
		local specStr = "·红利"
    local sPos, ePos = string.find( gemName, specStr )
    if sPos == nil or ePos == nil then
        return 0
    end
    return 1
end

function GemcomupDate_SelectedTwo(gem_Index, subIndex)
	if gem_Index < 1 or gem_Index > 4 then return end
	if subIndex < 0 or subIndex > 2 then return end--[0 1 2]

	if g_GemcomupDate_Item==-1 then
		return
	end
	if g_GemcomupDate_Space[gem_Index]:GetActionItem() == -1 then
		PushDebugMessage("#{BSSJ_140816_18}")
		return
	end
	--时装宝石
	local nGemType, nGemSubIndex = LifeAbility : GetEquip_GemTypeSubindex(g_GemcomupDate_Item,gem_Index-1)
	if nGemType==31 or nGemType==32 or nGemType==33 then
		PushDebugMessage("#{BSSJ_140816_19}")
		return
	end
	--红利石头
	local nGemID = LifeAbility : GetEquip_GemID(g_GemcomupDate_Item,gem_Index-1)
	if GemcomupDate_IsLiJinGem(nGemID) == 1 then
		PushDebugMessage( "#{BSSJ_140816_20}" )
		return
	end
	--分期
	if BudgetPlanGem:IsBudgetPlanGemByGemID(nGemID) == 1 then
		PushDebugMessage( "#{BSSJ_140816_21}" )
		return
	end
	--冥晶石
	if DoubleGem:IsDoubleGembyID(nGemID)==1 then
		--由于红利冥晶石的GemIndex违和，不能从GemIndex来得出从宝石等级，所以，只能根据宝石是否在GemLevelup.txt中有内容，来判断是否可以升级
		local nextGemID,nextGemYB,nextGemID2,nextGemYB2=LifeAbility:GetGemLevelupTBInfo(nGemID)
		if nextGemID>0 and nextGemID2>0 then
			if subIndex==2 then
				GemcomupDate_Mjingshi_Button:Show()
				GemcomupDate_Mjingshi_TXT:Show()
				GemcomupDate_Mjingshi_Button:SetCheck(0)
				GemcomupDate_Jingshi_TXT:Show()
				GemcomupDate_Jingshi_Button:Show()
				GemcomupDate_Jingshi_Button:SetCheck(1)
				g_GemcomupDate_SubSel=2
			else
				GemcomupDate_Mjingshi_Button:Show()
				GemcomupDate_Mjingshi_TXT:Show()
				GemcomupDate_Mjingshi_Button:SetCheck(1)
				GemcomupDate_Jingshi_TXT:Show()
				GemcomupDate_Jingshi_Button:Show()
				GemcomupDate_Jingshi_Button:SetCheck(0)
				g_GemcomupDate_SubSel=1
			end
		elseif nextGemID>0 then
			GemcomupDate_Mjingshi_Button:Show()
			GemcomupDate_Mjingshi_TXT:Show()
			GemcomupDate_Mjingshi_Button:SetCheck(1)
			GemcomupDate_Jingshi_TXT:Show()
			GemcomupDate_Jingshi_Button:Show()
			GemcomupDate_Jingshi_Button:SetCheck(0)
			g_GemcomupDate_SubSel=1
		elseif nextGemID2>0 then
			GemcomupDate_Mjingshi_Button:Show()
			GemcomupDate_Mjingshi_TXT:Show()
			GemcomupDate_Mjingshi_Button:SetCheck(0)
			GemcomupDate_Jingshi_TXT:Show()
			GemcomupDate_Jingshi_Button:Show()
			GemcomupDate_Jingshi_Button:SetCheck(1)
			g_GemcomupDate_SubSel=2
		else
			GemcomupDate_Mjingshi_Button:Hide()
			GemcomupDate_Mjingshi_TXT:Hide()
			GemcomupDate_Jingshi_TXT:Hide()
			GemcomupDate_Jingshi_Button:Hide()
--			PushDebugMessage("#{BSSJ_140816_22}")
			g_GemcomupDate_SubSel=0
			return
		end
	else
		GemcomupDate_Mjingshi_Button:Hide()
		GemcomupDate_Mjingshi_TXT:Hide()
		GemcomupDate_Jingshi_TXT:Hide()
		GemcomupDate_Jingshi_Button:Hide()
		--也不级别判断了，表里找到就算可以升级
		local nextGemID,nextGemYB,nextGemID2,nextGemYB2=LifeAbility:GetGemLevelupTBInfo(nGemID)
		if nextGemID<=0 then
--			PushDebugMessage( "#{BSSJ_140816_23}" )
			return
		end
	end
	g_GemcomupDate_Selected = gem_Index
	--selected Gem
	for i=1,4 do
		if i==g_GemcomupDate_Selected then
			g_GemcomupDate_Space[i]:SetPushed(1)
		else
			g_GemcomupDate_Space[i]:SetPushed(0)
		end
	end
	--如果单属性宝石，显示需求元宝量
	GemcomupDate_UpdateYBRequire()
	
end
function GemcomupDate_Selected(gem_Index)
	if gem_Index < 1 or gem_Index > 4 then return end

	if g_GemcomupDate_Item==-1 then
		return
	end
	if g_GemcomupDate_Space[gem_Index]:GetActionItem() == -1 then
		PushDebugMessage("#{BSSJ_140816_18}")
		return
	end
	--时装宝石
	local nGemType, nGemSubIndex = LifeAbility : GetEquip_GemTypeSubindex(g_GemcomupDate_Item,gem_Index-1)
	if nGemType==31 or nGemType==32 or nGemType==33 then
		PushDebugMessage("#{BSSJ_140816_19}")
		return
	end
	--红利石头
	local nGemID = LifeAbility : GetEquip_GemID(g_GemcomupDate_Item,gem_Index-1)
	if GemcomupDate_IsLiJinGem(nGemID) == 1 then
		PushDebugMessage( "#{BSSJ_140816_20}" )
		return
	end
	--分期
	if BudgetPlanGem:IsBudgetPlanGemByGemID(nGemID) == 1 then
		PushDebugMessage( "#{BSSJ_140816_21}" )
		return
	end
	--冥晶石
	if DoubleGem:IsDoubleGembyID(nGemID)==1 then
		--由于红利冥晶石的GemIndex违和，不能从GemIndex来得出从宝石等级，所以，只能根据宝石是否在GemLevelup.txt中有内容，来判断是否可以升级
		local nextGemID,nextGemYB,nextGemID2,nextGemYB2=LifeAbility:GetGemLevelupTBInfo(nGemID)
		if nextGemID>0 and nextGemID2>0 then
			GemcomupDate_Mjingshi_Button:Show()
			GemcomupDate_Mjingshi_TXT:Show()
			GemcomupDate_Mjingshi_Button:SetCheck(1)
			GemcomupDate_Jingshi_TXT:Show()
			GemcomupDate_Jingshi_Button:Show()
			GemcomupDate_Jingshi_Button:SetCheck(0)
			g_GemcomupDate_SubSel=1
		elseif nextGemID>0 then
			GemcomupDate_Mjingshi_Button:Show()
			GemcomupDate_Mjingshi_TXT:Show()
			GemcomupDate_Mjingshi_Button:SetCheck(1)
			GemcomupDate_Jingshi_TXT:Show()
			GemcomupDate_Jingshi_Button:Show()
			GemcomupDate_Jingshi_Button:SetCheck(0)
			g_GemcomupDate_SubSel=1
		elseif nextGemID2>0 then
			GemcomupDate_Mjingshi_Button:Show()
			GemcomupDate_Mjingshi_TXT:Show()
			GemcomupDate_Mjingshi_Button:SetCheck(0)
			GemcomupDate_Jingshi_TXT:Show()
			GemcomupDate_Jingshi_Button:Show()
			GemcomupDate_Jingshi_Button:SetCheck(1)
			g_GemcomupDate_SubSel=2
		else
			GemcomupDate_Mjingshi_Button:Hide()
			GemcomupDate_Mjingshi_TXT:Hide()
			GemcomupDate_Jingshi_TXT:Hide()
			GemcomupDate_Jingshi_Button:Hide()
			PushDebugMessage("#{BSSJ_140816_22}")
			g_GemcomupDate_SubSel=0
			return
		end
	else
		GemcomupDate_Mjingshi_Button:Hide()
		GemcomupDate_Mjingshi_TXT:Hide()
		GemcomupDate_Jingshi_TXT:Hide()
		GemcomupDate_Jingshi_Button:Hide()
		--也不级别判断了，表里找到就算可以升级
		local nextGemID,nextGemYB,nextGemID2,nextGemYB2=LifeAbility:GetGemLevelupTBInfo(nGemID)
		if nextGemID<=0 then
			PushDebugMessage( "#{BSSJ_140816_23}" )
			return
		end
	end
	g_GemcomupDate_Selected = gem_Index
	--selected Gem
	for i=1,4 do
		if i==g_GemcomupDate_Selected then
			g_GemcomupDate_Space[i]:SetPushed(1)
		else
			g_GemcomupDate_Space[i]:SetPushed(0)
		end
	end
	--如果单属性宝石，显示需求元宝量
	GemcomupDate_UpdateYBRequire()
end

function GemcomupDate_DoubleGem_Clicked(index)
	if index~=1 and index~=2 then return end
	--是否是双属性石头
	if g_GemcomupDate_Item==-1 then
		return
	end

	if g_GemcomupDate_Selected < 1 or g_GemcomupDate_Selected > 4 then return end
	local nGemID = LifeAbility : GetEquip_GemID(g_GemcomupDate_Item, g_GemcomupDate_Selected-1)
	if DoubleGem:IsDoubleGembyID(nGemID)~=1 then
		return
	end
	local nextGemID,nextGemYB,nextGemID2,nextGemYB2=LifeAbility:GetGemLevelupTBInfo(nGemID)
	if index==1 then
		if nextGemID>0 then
			g_GemcomupDate_SubSel=1
		else
			g_GemcomupDate_SubSel=2
			PushDebugMessage( "#{BSSJ_140816_56}" );
		end
	elseif index==2 then
		if nextGemID2>0 then
			g_GemcomupDate_SubSel=2
		else
			g_GemcomupDate_SubSel=1
			PushDebugMessage( "#{BSSJ_140816_55}" );
		end
	end
	GemcomupDate_Mjingshi_Button:SetCheck(0)
	GemcomupDate_Jingshi_Button:SetCheck(0)
	PushEvent( "GEM_LEVELUP_UPDATE_UI" );
	--更新元宝需求量
	GemcomupDate_UpdateYBRequire()
end

function GemcomupDate_UpdateYBRequire()
	GemcomupDate_OK:Disable()
	if g_GemcomupDate_Item==-1 then
		return
	end
	if g_GemcomupDate_Selected==-1 then
		return
	end
	if g_GemcomupDate_Space[g_GemcomupDate_Selected]:GetActionItem() == -1 then
		return
	end
	--
	local nGemID = LifeAbility : GetEquip_GemID(g_GemcomupDate_Item,g_GemcomupDate_Selected-1)
	if nGemID<=0 then
		return
	end
	if DoubleGem:IsDoubleGembyID(nGemID)==1 and g_GemcomupDate_SubSel==0 then
		return
	end
	local nextGemID,nextGemYB,nextGemID2,nextGemYB2=LifeAbility:GetGemLevelupTBInfo(nGemID)
	if DoubleGem:IsDoubleGembyID(nGemID)==1 and g_GemcomupDate_SubSel==2 then
		nextGemID=nextGemID2
		nextGemYB=nextGemYB2
	end
	GemcomupDate_NeedYuanbao:SetText(nextGemYB)
	GemcomupDate_OK:Enable()
end
--=========================================================
-- 更新界面
--=========================================================
function GemcomupDate_Update(itemIndex)
	local posBag = tonumber(itemIndex)--背包位置
	local theAction = EnumAction(posBag, "packageitem")

	if theAction:GetID() ~= 0 then
		-- 判断物品是否为装备
		--check equip point
		local equipPoint = LifeAbility:Get_Equip_Point(posBag)
		if equipPoint == -1 then--不是装备
--			PushDebugMessage("#{BSSJ_140816_53}")--#H只能放入装备。
			return
		elseif equipPoint == 8 or equipPoint == 9 or equipPoint == 10 then--骑乘、包裹等
			PushDebugMessage("#{BSSJ_140816_53}")--#H只能放入装备。
			return
		elseif equipPoint == 16 then--时装
			PushDebugMessage("#{BSSJ_140816_16}")--#H时装不能进行这个操作。
			return
		end

		--check have gem
		local holecount = LifeAbility:GetEquip_HoleCount(posBag)
		local gemcount = LifeAbility:GetEquip_GemCount(posBag)
		if gemcount == 0 then
			PushDebugMessage("#{BSSJ_140816_17}")
			return
		end
		--不做加锁判断

		-- 如果空格内已经有装备了, 替换之
		if g_GemcomupDate_Item ~= -1 then
			LifeAbility:Lock_Packet_Item(g_GemcomupDate_Item, 0)
		end
		GemcomupDate_Special_Button:SetActionItem(theAction:GetID())
		LifeAbility:Lock_Packet_Item(posBag, 1)
		g_GemcomupDate_Item = posBag

		--四个宝石位置映射
		local _,_,_,holecount=LifeAbility:Stiletto_Preparation(g_GemcomupDate_Item, 1)
		LifeAbility:SplitGem_Update(g_GemcomupDate_Item)
		for i=1,4 do
			local nItemIndex = LifeAbility:GetSplitGem_GemIndex(i-1)	
			if nItemIndex ~= -1 then
				if BudgetPlanGem:IsBudgetPlanGemByGemID(nItemIndex) == 1 then
					local IsGemValid = BudgetPlanGem:GetBagItemIsValid(g_GemcomupDate_Item,i-1)
					local GemDueTime = BudgetPlanGem:GetBagItemDueTime(g_GemcomupDate_Item,i-1)
					local Action = LifeAbility:UpdateProductAction(i-1,nItemIndex,GemDueTime,IsGemValid)
					if Action and Action:GetID() ~= 0 then
							g_GemcomupDate_Space[i]:SetActionItem(Action:GetID())
					else
							g_GemcomupDate_Space[i]:SetActionItem(-1)
							--g_GemcomupDate_Space[i]:SetToolTip("#{BSLCYH_130529_14}")
					end
				else
					local nItemID = LifeAbility:GetSplitGem_Gem(i-1)
					if nItemID ~= -1 then
						ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID)
						g_GemcomupDate_Space[i]:SetActionItem(ActionID)
					else
						g_GemcomupDate_Space[i]:SetActionItem(-1)
						--g_GemcomupDate_Space[i]:SetToolTip("#{BSLCYH_130529_14}")
					end
				end
			else
				g_GemcomupDate_Space[i]:SetActionItem(-1)
				--g_GemcomupDate_Space[i]:SetToolTip("#{BSLCYH_130529_14}")
			end

			if i > holecount then
--				g_GemcomupDate_Space[i]:SetToolTip("#{BSLCYH_130529_12}")
				if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则设置图片资源为唯美版资源
					g_GemcomupDate_Space[i]:SetProperty( "BackImage", "set:WM_CommonFrame1 image:Feng" )
				else									--否则设置为经典版资源
					g_GemcomupDate_Space[i]:SetProperty( "BackImage", "set:Agname3 image:BaoShiCheckFeng" )
				end
--				if i == 4 and not SplitGemEx_CanFour(g_SplitGemEx_Equip_pos) then
--					g_GemcomupDate_Space[i]:SetToolTip("#{BSLCYH_130529_13}")
--				end
			end
		end
		
		--灰化升级按钮
	else
		GemcomupDate_Clear()
	end
	--检测灰化按钮
end

--=========================================================
-- 取出窗口内放入的物品
--=========================================================
function GemcomupDate_Resume_GemInfo()
	if this:IsVisible() then
		GemcomupDate_Clear()
	end
end

--=========================================================
-- 确定执行功能
--=========================================================
function GemcomupDate_Submit()
	-- 安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	if g_GemcomupDate_Item==-1 then
		return
	end
	--check equip point
	local equipPoint = LifeAbility:Get_Equip_Point(g_GemcomupDate_Item)
--	PushDebugMessage("equipPoint="..equipPoint)
	if equipPoint == -1 then--不是装备
		return
	elseif equipPoint == 8 or equipPoint == 9 or equipPoint == 10 then--骑乘、包裹等
		return
	elseif equipPoint == 16 then--时装
		PushDebugMessage("#{BSSJ_140816_24}")
		return
	end

	--check have gem
	local holecount = LifeAbility:GetEquip_HoleCount(g_GemcomupDate_Item)
	local gemcount = LifeAbility:GetEquip_GemCount(g_GemcomupDate_Item)
	if gemcount == 0 then
		PushDebugMessage("#{BSSJ_140816_25}")
		return
	end
	
	if g_GemcomupDate_Selected==-1 then
		return
	end
	if g_GemcomupDate_Space[g_GemcomupDate_Selected]:GetActionItem() == -1 then
		PushDebugMessage("#{BSSJ_140816_26}")
		return
	end
	--时装宝石
	local nGemType, nGemSubIndex = LifeAbility : GetEquip_GemTypeSubindex(g_GemcomupDate_Item,g_GemcomupDate_Selected-1)
	if nGemType==31 or nGemType==32 or nGemType==33 then
		PushDebugMessage("#{BSSJ_140816_27}")
		return
	end
	--红利石头
	local nGemID = LifeAbility : GetEquip_GemID(g_GemcomupDate_Item,g_GemcomupDate_Selected-1)
	if GemcomupDate_IsLiJinGem(nGemID) == 1 then
		PushDebugMessage( "#{BSSJ_140816_28}" )
		return
	end
	--分期
	if BudgetPlanGem:IsBudgetPlanGemByGemID(nGemID) == 1 then
		PushDebugMessage( "#{BSSJ_140816_29}" )
		return
	end
	--冥晶石
	local bIsDoubleGem=DoubleGem:IsDoubleGembyID(nGemID)
	local nextGemID,nextGemYB,nextGemID2,nextGemYB2=LifeAbility:GetGemLevelupTBInfo(nGemID)
	if bIsDoubleGem==1 then
		if g_GemcomupDate_SubSel==0 then
			PushDebugMessage("#{BSSJ_140816_30}")
			return
		end
		if g_GemcomupDate_SubSel==2 then
			nextGemID=nextGemID2
			nextGemYB=nextGemYB2
		end
		if nextGemID<=0 then
			PushDebugMessage("#{BSSJ_140816_35}")
			return
		end
	else
		if nextGemID<=0 then
			PushDebugMessage("#{BSSJ_140816_23}")
			return
		end
	end

	local nCurYB=tonumber(Player:GetData("YUANBAO"))
	if nCurYB<nextGemYB then
		PushDebugMessage("#{BSSJ_140816_51}")
		return
	end
	--元宝消费确认
	if (NpcShop:GetGemLevelupDirectly() == 0) then--不直接升级
		local gemNamePre = DoubleGem:GetGemNamebyID( nGemID )
		local gemNameNext = DoubleGem:GetGemNamebyID( nextGemID )
		local str = ScriptGlobal_Format( "#{BSSJ_140816_31}",tostring(gemNamePre), tostring(gemNameNext), nextGemYB )
		PushEvent( "SURE_GEM_LEVELUP", str, g_GemcomupDate_Item, g_GemcomupDate_Selected, g_GemcomupDate_SubSel)
		return
	end
	--消费上限放到Server端判断
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnAskGemLevelup")
		Set_XSCRIPT_ScriptID(290207)
		Set_XSCRIPT_Parameter(0, g_GemcomupDate_Item)
		Set_XSCRIPT_Parameter(1, g_GemcomupDate_Selected)
		Set_XSCRIPT_Parameter(2, g_GemcomupDate_SubSel)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()


end

--=========================================================
-- 关闭界面
--=========================================================
function GemcomupDate_Close()
	this:Hide()
	return
end

--=========================================================
-- 界面隐藏
--=========================================================
function GemcomupDate_OnHiden()
	StopCareObject_GemcomupDate()
	GemcomupDate_Clear()
	return
end

--=========================================================
-- 开始关心NPC，
-- 在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
-- 如果有的话，先取消已经有的“关心”
--=========================================================
function GemcomupDate_BeginCareObject()
	this:CareObject(g_CaredNpc, 1, "GemcomupDate")
	return
end

--=========================================================
-- 停止对某NPC的关心
--=========================================================
function StopCareObject_GemcomupDate()
	this:CareObject(g_CaredNpc, 0, "GemcomupDate")
	g_CaredNpc = -1
	return
end


function GemcomupDate_Frame_On_ResetPos()
  GemcomupDate_Frame:SetProperty("UnifiedPosition", g_GemcomupDate_Frame_UnifiedPosition);
end


function GemcomupDate_SpecialBTN_RBClicked()
	GemcomupDate_Resume_GemInfo()
end

function GemcomupDate_querengoumai_Clicked()

	if (NpcShop:GetGemLevelupDirectly() == 0)then--不直接升级
--		GemcomupDate_YuanBaoPay_Button:SetCheck(0);--直接升级
		NpcShop:SetGemLevelupDirectly(1)
	else
--		GemcomupDate_YuanBaoPay_Button:SetCheck(1)
		NpcShop:SetGemLevelupDirectly(0)
	end
end

function GemcomupDate_ChangeTabIndex(nIndex)

	if nIndex == 5 or nIndex == 4 or nIndex == 3 then
		if IsZbs2018SpeicalServer() >= 1 then
			PushDebugMessage("#{WCBS_180307_20}")
			return
		end
	end
	
	local nUI = 0
	if 1 == nIndex then
		nUI = 23
	elseif 2 == nIndex then
		nUI = 112236
	elseif 3 == nIndex then
		nUI = 112237
	elseif 4 == nIndex then
		nUI = 201210120
	elseif 5 == nIndex then
		nUI = 201210121
	elseif 6 == nIndex then
		return
	end
	if nUI ~= 0 then
		Variable:SetVariable("GemUnionPos", GemcomupDate_Frame:GetProperty("UnifiedPosition"), 1)
		Variable:SetVariable("GemNPCObjId", tostring(g_npcObjId), 1)
		PushEvent("UI_COMMAND", nUI)
		GemcomupDate_Close()
	end
end
