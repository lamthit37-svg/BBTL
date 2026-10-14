--暗器金翅翎羽升星界面逻辑（客户端）
local MAX_OBJ_DISTANCE = 3.0;
local objCared = -1;
local g_Object = -1;
local g_CommandType = 1
local g_Dark_Bag_Index = -1
local g_MaxStar = 8						--可升级金翅翎羽最大星级
local g_Stars = {}
local g_Mainitem = 10155008
local g_StarUpCost = {500000,500000,500000,500000,500000,1000000,2000000,4000000}
local g_StarUpCostItem = {20800045,20800046}
local g_StarUpCostItemCount = {15,15,15,15,15,50,100,200}

function AnqiStarUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("UPDATE_ANQISTARUP")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function AnqiStarUp_OnLoad()
	g_Stars={
			AnqiStarUp_StaticPart_Star1,
			AnqiStarUp_StaticPart_Star2,
			AnqiStarUp_StaticPart_Star3,
			AnqiStarUp_StaticPart_Star4,
			AnqiStarUp_StaticPart_Star5,
			AnqiStarUp_StaticPart_Star6,
			AnqiStarUp_StaticPart_Star7,
			AnqiStarUp_StaticPart_Star8,
			AnqiStarUp_StaticPart_Star9,
	}
	for nIndex = 1,table.getn(g_Stars) do
		g_Stars[nIndex]:SetProperty("Animate", "Animate_Card_DarkStar")
		g_Stars[nIndex]:Show()
	end
end

function AnqiStarUp_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 800034) then
		
		g_CommandType = Get_XParam_INT(0)
		if g_CommandType == 15 then
			if this:IsVisible() then
				AnqiStarUp_Close()
			end
			return
		end
		
		if this:IsVisible() then
			AnqiStarUp_Close()
		end

		objCared = -1;
		local tempID = Get_XParam_INT(1);
		objCared = DataPool : GetNPCIDByServerID(tempID);

		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end
		
		AnqiStarUp_BeginCareObject(objCared)

		g_CommandType = Get_XParam_INT(0)
		if g_CommandType == 14 then
			AnqiStarUp_InitDlg()
		end
	elseif (event == "UPDATE_ANQISTARUP" and this:IsVisible()) then
		if arg0~= nil then
			AnqiStarUp_Update(arg0)
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			AnqiStarUp_Close()
		end
	elseif( (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and this:IsVisible()) then
		AnqiStarUp_UpdateMoneyDisp()
	elseif(event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible())then
		if(tonumber(arg0) == 175) then
			AnqiStarUp_Resume()
		end
	elseif(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil then
			if (g_Dark_Bag_Index == tonumber(arg0)) then
				local starLevel = DataPool:GetLYDarkStarInBag(g_Dark_Bag_Index)
				if starLevel >= 0 and starLevel < g_MaxStar then
					AnqiStarUp_ShowStars(starLevel)
				else
					AnqiStarUp_Resume()	
				end
			end
		end
	end
end

function AnqiStarUp_UpdateMoneyDisp()
	if g_Dark_Bag_Index ~= -1 then
		local playerMoney = Player:GetData("MONEY");
		local playerMoneyJZ = Player:GetData("MONEY_JZ");
		--暗器星级
		local starLevel = DataPool:GetLYDarkStarInBag(g_Dark_Bag_Index)
		if starLevel >= 0 and starLevel < g_MaxStar then
			AnqiStarUp_Money:SetProperty("MoneyNumber", g_StarUpCost[starLevel + 1])
		end
		AnqiStarUp_SelfJiaozi:SetProperty("MoneyNumber", playerMoneyJZ);
		AnqiStarUp_SelfMoney:SetProperty("MoneyNumber", playerMoney);
	end
end

function AnqiStarUp_InitDlg()
	--重洗暗器技能
	AnqiStarUp_Reset()
	AnqiStarUp_Money:SetProperty("MoneyNumber", 0)
	AnqiStarUp_SelfJiaozi:SetProperty("MoneyNumber", 0)
	AnqiStarUp_SelfMoney:SetProperty("MoneyNumber", 0)
	this:Show()
end

--确认进阶按钮回调
function AnqiStarUp_OK_Clicked()
	--请先放入暗器。
	if (g_Dark_Bag_Index == -1) then
		PushDebugMessage("#{AQJJ_160127_119}")
		return
	end

	local EquipPoint = LifeAbility : Get_Equip_Point(g_Dark_Bag_Index)
	if (EquipPoint ~= 17) then
		PushDebugMessage("#{AQJJ_160127_120}")
		return
	end
	
	--暗器升星
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("LingyuStarUp")
		Set_XSCRIPT_ScriptID(260001)
		Set_XSCRIPT_Parameter(0,g_Dark_Bag_Index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--取消按钮回调
function AnqiStarUp_Cancel_Clicked()
	AnqiStarUp_Close()
end

--关闭界面按钮回调
function AnqiStarUp_CloseUI_Clicked()
	AnqiStarUp_Close()
end

--界面Hide回调
function AnqiStarUp_Clear()
	AnqiStarUp_Reset()
	AnqiStarUp_StopCareObject()
end

function AnqiStarUp_Update(Item_index)
	local i_index = tonumber(Item_index)
	local theAction = EnumAction(i_index, "packageitem");

	if theAction:GetID() ~= 0 then
		if PlayerPackage : GetItemTableIndex( i_index ) ~= g_Mainitem then
			PushDebugMessage("#{AQJJ_160127_117}")
			return
		end
		
		local darkLv = PlayerPackage : GetBagItemDarkLevel(i_index)
		if darkLv < 90 then
			PushDebugMessage("#{AQJJ_160127_117}")
			return
		end
		
		local darkStar = DataPool:GetLYDarkStarInBag(i_index)
		if darkStar == nil or darkStar == -1 or darkStar >= g_MaxStar then
			PushDebugMessage("#{AQJJ_160127_118}")
			return
		end
		
		if i_index == g_Dark_Bag_Index then
			return
		end

		--界面清空
		AnqiStarUp_Reset()
		--设置ActionItem
		AnqiStarUp_Object:SetActionItem(theAction:GetID());
		g_Dark_Bag_Index = i_index
		LifeAbility : Lock_Packet_Item(i_index,1)
		AnqiStarUp_OK:Enable()
		AnqiStarUp_UpdateMoneyDisp()
		AnqiStarUp_ShowStars(darkStar)
	end

end

function AnqiStarUp_Reset()
	AnqiStarUp_Object:SetActionItem(-1);
	LifeAbility : Lock_Packet_Item(g_Dark_Bag_Index,0);
	g_Dark_Bag_Index = -1
	AnqiStarUp_OK:Disable()
	AnqiStarUp_ShowStars(0)
	AnqiStarUp_Info4:SetText("")
end

function AnqiStarUp_Close()
	AnqiStarUp_Reset()
	AnqiStarUp_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function AnqiStarUp_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "AnqiStarUp");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "AnqiStarUp")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function AnqiStarUp_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "AnqiStarUp");
		g_Object = -1;
	end
end

function AnqiStarUp_Resume()
	AnqiStarUp_Reset()
	AnqiStarUp_Money:SetProperty("MoneyNumber", 0)
	AnqiStarUp_SelfJiaozi:SetProperty("MoneyNumber", 0)
	AnqiStarUp_SelfMoney:SetProperty("MoneyNumber", 0)			
end

function AnqiStarUp_ShowStars(starCount)
	for nIndex = 1,table.getn(g_Stars) do
		if nIndex <= starCount then
			g_Stars[nIndex]:SetProperty("Animate", "Animate_Card_NoFlashStar")
		else
			g_Stars[nIndex]:SetProperty("Animate", "Animate_Card_DarkStar")
		end
	end
	
	if starCount >= 0 and starCount < g_MaxStar then
		local itemName = PlayerPackage:GetItemName(g_StarUpCostItem[1])
		local itemCount = g_StarUpCostItemCount[starCount + 1]
		local tips = ScriptGlobal_Format("#{AQJJ_160127_115}",itemCount,itemName)
		AnqiStarUp_Info4:SetText(tips)
	end
end
