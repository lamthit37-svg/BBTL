-------------------------------------------------------
--家园珍兽滋补界面
-----------------------------------------------------------

local MAX_OBJ_DISTANCE = 3.0;
local objCared = -1;

local g_BieYePetBar_Tonic_OperType = 2--家园珍兽提升界面类型 1 训练 2 滋补 3 觉醒
local g_BieYePetBar_Tonic_ResFood = 0--暂存当前家园食材
local g_BieYePetBar_Tonic_PetLevelMax = 0--珍兽最大等级

local g_BieYePetBar_Tonic_PetGuidH = 0--暂存当前选择的珍兽guid
local g_BieYePetBar_Tonic_PetGuidL = 0--暂存当前选择的珍兽guid

local g_BieYePetBar_Tonic_LevelMax = 5--建筑等级最大值
local g_BieYePetBar_Tonic_Level = 0--当前建筑等级

local g_BieYePetBar_Tonic_SelectLevel = -1--当前选择档位

local g_BieYePetBar_Tonic_OperData = 
{
	[1] = {needItem = {20,60,100,}, needMoney = {6700,20000,33000,}, value = {5000,15100,25200,} },
	[2] = {needItem = {22,66,110,}, needMoney = {7300,22000,36700,}, value = {5500,16600,27700,} },
	[3] = {needItem = {24,72,120,}, needMoney = {8000,24000,40000,}, value = {6000,18100,30300,} },
	[4] = {needItem = {26,78,130,}, needMoney = {8700,26000,43000,}, value = {6500,19700,32800,} },
	[5] = {needItem = {30,90,150,}, needMoney = {10000,30000,50000,}, value = {7500,22700,37800,} },
}

local g_BieYePetBar_Tonic_LevelSelect = 
{
	[1] = {strName="#{JYSL_160518_238}", strLevel="#{JYSL_160518_245}", },
	[2] = {strName="#{JYSL_160518_239}", strLevel="#{JYSL_160518_246}", },
	[3] = {strName="#{JYSL_160518_240}", strLevel="#{JYSL_160518_247}", },
	[4] = {strName="#{JYSL_160518_241}", strLevel="#{JYSL_160518_248}", },
	[5] = {strName="#{JYSL_160518_242}", strLevel="#{JYSL_160518_249}", },
}

local g_BieYePetBar_Tonic_JYSLUIText = 
{
	[1] = {text="#{JYSL_160518_63}",},
	[2] = {text="#{JYSL_160518_64}",},
	[3] = {text="#{JYSL_160518_65}",},
}

local g_BieYePetBar_Tonic_JYSLUIName = 
{
	[1] = {Time="",Cost="",Money="",Life="",},
	[2] = {Time="",Cost="",Money="",Life="",},
	[3] = {Time="",Cost="",Money="",Life="",},
}

function BieYePetBar_Tonic_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false); --界面敏感事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false); --界面敏感事件
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
end

function BieYePetBar_Tonic_OnLoad()
	g_BieYePetBar_Tonic_JYSLUIName[1].Time = BieYePetBar_Tonic_Level1
	g_BieYePetBar_Tonic_JYSLUIName[1].Cost = BieYePetBar_Tonic_Pet_Consume1_2
	g_BieYePetBar_Tonic_JYSLUIName[1].Money = BieYePetBar_Tonic_Jiaozi1_Money
	g_BieYePetBar_Tonic_JYSLUIName[1].Life = BieYePetBar_Tonic_Pet_Lifetime1

	g_BieYePetBar_Tonic_JYSLUIName[2].Time = BieYePetBar_Tonic_Level2
	g_BieYePetBar_Tonic_JYSLUIName[2].Cost = BieYePetBar_Tonic_Pet_Consume2_2
	g_BieYePetBar_Tonic_JYSLUIName[2].Money = BieYePetBar_Tonic_Jiaozi2_Money
	g_BieYePetBar_Tonic_JYSLUIName[2].Life = BieYePetBar_Tonic_Pet_Lifetime2

	g_BieYePetBar_Tonic_JYSLUIName[3].Time = BieYePetBar_Tonic_Level3
	g_BieYePetBar_Tonic_JYSLUIName[3].Cost = BieYePetBar_Tonic_Pet_Consume3_2
	g_BieYePetBar_Tonic_JYSLUIName[3].Money = BieYePetBar_Tonic_Jiaozi3_Money
	g_BieYePetBar_Tonic_JYSLUIName[3].Life = BieYePetBar_Tonic_Pet_Lifetime3
	
	BieYePetBar_Tonic_PetLevel_Select:ResetList()
	for i=1, table.getn(g_BieYePetBar_Tonic_LevelSelect) do
		BieYePetBar_Tonic_PetLevel_Select:AddTextItem(g_BieYePetBar_Tonic_LevelSelect[i].strName, i)
	end

end

function BieYePetBar_Tonic_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 2016051912 ) then
		local ntype = Get_XParam_INT(1)
		--仅接收该类型界面消息
		if ntype ~= g_BieYePetBar_Tonic_OperType then
			return
		end
		--关闭已打开界面
		if(IsWindowShow("BieYePetBar_Train")) then
		  CloseWindow("BieYePetBar_Train", true);
		end	
		if(IsWindowShow("BieYePetBar_Tonic")) then
		  CloseWindow("BieYePetBar_Tonic", true);
		end	
		if(IsWindowShow("BieYePetBar_Awake")) then
		  CloseWindow("BieYePetBar_Awake", true);
		end	
		--打开界面
		local nShoulanLevel = Get_XParam_INT(2)
		if nShoulanLevel ~= nil and nShoulanLevel > 0 then
			--关注npc
			local objid = Get_XParam_INT(0)
			if objid ~= nil and objid ~= -1 then
				objCared = tonumber(objid)--DataPool : GetNPCIDByServerID(tonumber(objid))
				this:CareObject(objCared, 1, "BieYePetBar_Tonic");
			end
			--显示界面
			this:Show()
			--更新数据
			g_BieYePetBar_Tonic_Level = nShoulanLevel
			g_BieYePetBar_Tonic_ResFood = Get_XParam_INT(3)
			g_BieYePetBar_Tonic_PetGuidH = Get_XParam_INT(4)
			g_BieYePetBar_Tonic_PetGuidL = Get_XParam_INT(5)
			g_BieYePetBar_Tonic_PetLevelMax = Get_XParam_INT(6)
			BieYePetBar_Tonic_UpdateList()		
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2016051914 ) then
		if this:IsVisible() then
			BieYePetBar_Tonic_Close_Click()	
		end	
  elseif ( event == "OBJECT_CARED_EVENT" ) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--关闭界面
			BieYePetBar_Tonic_Close_Click()
		end	
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		--关闭界面
		BieYePetBar_Tonic_Close_Click()
	-- 金钱变更
	elseif event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX" then
		BieYePetBar_Tonic_MoneyUpdate()
	end
end

function BieYePetBar_Tonic_UpdateList()
	if g_BieYePetBar_Tonic_Level == nil or g_BieYePetBar_Tonic_Level <= 0 or g_BieYePetBar_Tonic_Level > g_BieYePetBar_Tonic_LevelMax then
		return
	end
	
	--检测珍兽有效性
	if g_BieYePetBar_Tonic_PetGuidH == nil or g_BieYePetBar_Tonic_PetGuidL == nil or g_BieYePetBar_Tonic_PetLevelMax <= 0 then
		return
	end
	local nListIndex = Pet:GetPetIndexByGUID_PetBank(g_BieYePetBar_Tonic_PetGuidH, g_BieYePetBar_Tonic_PetGuidL)
	if nListIndex == nil or nListIndex < 0 then
		return
	end
	
	--家园食材
	BieYePetBar_Tonic_Shicaitext:SetText(ScriptGlobal_Format( "#{JYSL_160518_89}", g_BieYePetBar_Tonic_ResFood ))
	--金钱
	BieYePetBar_Tonic_MoneyUpdate()
	
	--档位选择--当前兽栏等级
	BieYePetBar_Tonic_PetLevel_Select:SetCurrentSelect(g_BieYePetBar_Tonic_Level-1)
		
	--更新数据
	BieYePetBar_Tonic_UpdateData(g_BieYePetBar_Tonic_Level)			

end

--=========================================================
--金钱刷新
--=========================================================
function BieYePetBar_Tonic_MoneyUpdate()
	BieYePetBar_Tonic_Jiaozi_Money : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY_JZ")) )
	BieYePetBar_Tonic_Jinbi_Money : SetProperty( "MoneyNumber", tostring(Player:GetData("MONEY")) )
end

--更新数据
function BieYePetBar_Tonic_UpdateData(nSelectLevel)
	if nSelectLevel == nil or nSelectLevel <= 0 or nSelectLevel > g_BieYePetBar_Tonic_LevelMax then
		return
	end
	if g_BieYePetBar_Tonic_Level == nil or g_BieYePetBar_Tonic_Level <= 0 or g_BieYePetBar_Tonic_Level > g_BieYePetBar_Tonic_LevelMax then
		return
	end
	
	--未改变选项
	if g_BieYePetBar_Tonic_SelectLevel == nSelectLevel then
		return
	end
	
	--超过当前等级对应的档位不允许哦~
	if nSelectLevel > g_BieYePetBar_Tonic_Level then
		--提示选项不可以更换
		local tip = g_BieYePetBar_Tonic_LevelSelect[g_BieYePetBar_Tonic_Level].strLevel
		local tips = ScriptGlobal_Format( "#{JYSL_160518_109}", g_BieYePetBar_Tonic_Level, tip )
		PushDebugMessage(tips)
		PushDebugMessage("#{JYSL_160518_253}")
		--上一次选项
		if g_BieYePetBar_Tonic_SelectLevel ~= nil and g_BieYePetBar_Tonic_SelectLevel > 0 and g_BieYePetBar_Tonic_SelectLevel <= g_BieYePetBar_Tonic_LevelMax then
			BieYePetBar_Tonic_PetLevel_Select:SetCurrentSelect(g_BieYePetBar_Tonic_SelectLevel-1)
		end
		return
	end

	local tItem = g_BieYePetBar_Tonic_OperData[nSelectLevel].needItem
	if tItem == nil then
		return
	end
	
	local tMoney = g_BieYePetBar_Tonic_OperData[nSelectLevel].needMoney
	if tMoney == nil then
		return
	end
	
	local tValue = g_BieYePetBar_Tonic_OperData[nSelectLevel].value
	if tValue == nil then
		return
	end
		
	--设置当前项
	g_BieYePetBar_Tonic_SelectLevel = nSelectLevel	
	
	--刷新列表
	for i=1, 3 do
		--时长及兽栏等级
		g_BieYePetBar_Tonic_JYSLUIName[i].Time:SetText( g_BieYePetBar_Tonic_JYSLUIText[i].text )
		--提升消耗
		g_BieYePetBar_Tonic_JYSLUIName[i].Cost:SetText(ScriptGlobal_Format( "#{JYSL_160518_55}", tItem[i] ))
		g_BieYePetBar_Tonic_JYSLUIName[i].Money:SetProperty("MoneyNumber", tostring(tMoney[i]))
		--提升可获得寿命
		g_BieYePetBar_Tonic_JYSLUIName[i].Life:SetText( ScriptGlobal_Format( "#{JYSL_160518_206}", tValue[i] ) )
	end		
end

--列表变化
function BieYePetBar_Tonic_SelectChanged()
	if g_BieYePetBar_Tonic_Level == nil or g_BieYePetBar_Tonic_Level <= 0 or g_BieYePetBar_Tonic_Level > g_BieYePetBar_Tonic_LevelMax then
		return
	end
	
	--获得当前选项
	local str,nIndex = BieYePetBar_Tonic_PetLevel_Select:GetCurrentSelect()
	--有效性判断
	if nIndex <= 0 or nIndex > g_BieYePetBar_Tonic_LevelMax then
		return
	end
	
	--更新数据
	BieYePetBar_Tonic_UpdateData(nIndex)	
	
end

--关闭界面
function BieYePetBar_Tonic_Close_Click()
	g_BieYePetBar_Tonic_ResFood = 0--暂存当前家园食材
	g_BieYePetBar_Tonic_PetLevelMax = 0--珍兽最大等级
	g_BieYePetBar_Tonic_PetGuidH = 0--暂存当前选择的珍兽guid
	g_BieYePetBar_Tonic_PetGuidL = 0--暂存当前选择的珍兽guid
	g_BieYePetBar_Tonic_Level = 0--当前建筑等级
	g_BieYePetBar_Tonic_SelectLevel = -1--当前选择档位

	this:Hide()
	--取消关心
	this:CareObject(objCared, 0, "BieYePetBar_Tonic");
end

--提升按钮
function BieYePetBar_Tonic_Promote_Click(nIndex)
	if nIndex == nil or nIndex <= 0 or nIndex > 3 then
		return
	end
	
	--提升操作
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientAskShoulanOperationConfirm" )
		Set_XSCRIPT_ScriptID(891939)
		Set_XSCRIPT_Parameter(0,g_BieYePetBar_Tonic_OperType)
		Set_XSCRIPT_Parameter(1,g_BieYePetBar_Tonic_PetGuidH)
		Set_XSCRIPT_Parameter(2,g_BieYePetBar_Tonic_PetGuidL)
		Set_XSCRIPT_Parameter(3,g_BieYePetBar_Tonic_SelectLevel)
		Set_XSCRIPT_Parameter(4,nIndex)
		Set_XSCRIPT_Parameter(5,0)
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()
end
