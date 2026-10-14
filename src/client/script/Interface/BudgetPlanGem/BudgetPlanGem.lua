local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_BudgetPlanGemInfo_Table= {}
local g_DownPay_Data={}
local g_RePay_Data={}

local MAX_BUDGET_PLAN_GEM_COUNT = 4 --对应代码中的宏

local BP_GEM_POS_BAG =1;				--背包里面
local BP_GEM_POS_BANK=2;				--银行里面
local BP_GEM_POS_EQUIP=3;				--装备上 装备可以在人身上 也可以在背包里面（这个根据DB存储类型做区分吧，用fixattr的）
local BP_GEM_POS_WANBAO=4;			--万宝随身换，t_gemcontainer那部分
local g_bConfirm = -1				--二次确认框，弹出来了吗
--首付信息
local g_GemName=
{
	"红宝石","纯净黄晶石","纯净蓝晶石","纯净红晶石","纯净绿晶石",
	"黄冥石","蓝冥石","红冥石","绿冥石",
	"纯净黄玉","纯净皓石","纯净月光石","纯净碧玺",
	"血精石","紫玉","祖母绿","猫眼石","虎眼石",
	"绿宝石","变石","黄宝石","蓝宝石","石榴石",
	"尖晶石","黑宝石",
	
}
local g_GemLevel={"1级","2级","3级","4级","5级","6级","7级"}
local g_GemTypeList =
{
	[1] = 	{[4]={BPGem=50418004,Normal=50413004},[5]={BPGem=50518004,Normal=50513004},[6]={BPGem=50618004,Normal=50613004},[7]={BPGem=50718004,Normal=50713004}},--红宝石
	[2] = 	{[4]={BPGem=50407005,Normal=50402005},[5]={BPGem=50507005,Normal=50502005},[6]={BPGem=50607005,Normal=50602005},[7]={BPGem=50707005,Normal=50702005}},--纯净黄晶石
	[3] = 	{[4]={BPGem=50407006,Normal=50402006},[5]={BPGem=50507006,Normal=50502006},[6]={BPGem=50607006,Normal=50602006},[7]={BPGem=50707006,Normal=50702006}},--纯净蓝晶石
	[4] = 	{[4]={BPGem=50407007,Normal=50402007},[5]={BPGem=50507007,Normal=50502007},[6]={BPGem=50607007,Normal=50602007},[7]={BPGem=50707007,Normal=50702007}},--纯净红晶石
	[5] = 	{[4]={BPGem=50407008,Normal=50402008},[5]={BPGem=50507008,Normal=50502008},[6]={BPGem=50607008,Normal=50602008},[7]={BPGem=50707008,Normal=50702008}},--纯净绿晶石
	[6] = 	{[4]={BPGem=50426001,Normal=50421001},[5]={BPGem=50526001,Normal=50521001},[6]={BPGem=50626001,Normal=50621001},[7]={BPGem=50726001,Normal=50721001}},--黄冥石
	[7] = 	{[4]={BPGem=50426002,Normal=50421002},[5]={BPGem=50526002,Normal=50521002},[6]={BPGem=50626002,Normal=50621002},[7]={BPGem=50726002,Normal=50721002}},--蓝冥石
	[8] = 	{[4]={BPGem=50426003,Normal=50421003},[5]={BPGem=50526003,Normal=50521003},[6]={BPGem=50626003,Normal=50621003},[7]={BPGem=50726003,Normal=50721003}},--红冥石
	[9] = 	{[4]={BPGem=50426004,Normal=50421004},[5]={BPGem=50526004,Normal=50521004},[6]={BPGem=50626004,Normal=50621004},[7]={BPGem=50726004,Normal=50721004}},--绿冥石
	[10] = 	{[4]={BPGem=50417005,Normal=50412005},[5]={BPGem=50517005,Normal=50512005},[6]={BPGem=50617005,Normal=50612005},[7]={BPGem=50717005,Normal=50712005}},--纯净黄玉
	[11] = 	{[4]={BPGem=50417006,Normal=50412006},[5]={BPGem=50517006,Normal=50512006},[6]={BPGem=50617006,Normal=50612006},[7]={BPGem=50717006,Normal=50712006}},--纯净皓石
	[12] = 	{[4]={BPGem=50417007,Normal=50412007},[5]={BPGem=50517007,Normal=50512007},[6]={BPGem=50617007,Normal=50612007},[7]={BPGem=50717007,Normal=50712007}},--纯净月光石
	[13] = 	{[4]={BPGem=50417008,Normal=50412008},[5]={BPGem=50517008,Normal=50512008},[6]={BPGem=50617008,Normal=50612008},[7]={BPGem=50717008,Normal=50712008}},--纯净碧玺
	[14] = 	{[4]={BPGem=50418006,Normal=50413006},[5]={BPGem=50518006,Normal=50513006},[6]={BPGem=50618006,Normal=50613006},[7]={BPGem=50718006,Normal=50713006}},--血精石
	[15] = 	{[4]={BPGem=50408001,Normal=50403001},[5]={BPGem=50508001,Normal=50503001},[6]={BPGem=50608001,Normal=50603001},[7]={BPGem=50708001,Normal=50703001}},--紫玉
	[16] = 	{[4]={BPGem=50419001,Normal=50414001},[5]={BPGem=50519001,Normal=50514001},[6]={BPGem=50619001,Normal=50614001},[7]={BPGem=50719001,Normal=50714001}},--祖母绿	
	[17] = 	{[4]={BPGem=50406001,Normal=50401001},[5]={BPGem=50506001,Normal=50501001},[6]={BPGem=50606001,Normal=50601001},[7]={BPGem=50706001,Normal=50701001}},--猫眼石
	[18] = 	{[4]={BPGem=50406002,Normal=50401002},[5]={BPGem=50506002,Normal=50501002},[6]={BPGem=50606002,Normal=50601002},[7]={BPGem=50706002,Normal=50701002}},--虎眼石
	[19] = 	{[4]={BPGem=50418003,Normal=50413003},[5]={BPGem=50518003,Normal=50513003},[6]={BPGem=50618003,Normal=50613003},[7]={BPGem=50718003,Normal=50713003}},--绿宝石
	[20] = 	{[4]={BPGem=50409002,Normal=50404002},[5]={BPGem=50509002,Normal=50504002},[6]={BPGem=50609002,Normal=50604002},[7]={BPGem=50709002,Normal=50704002}},--变石
	[21] = 	{[4]={BPGem=50418001,Normal=50413001},[5]={BPGem=50518001,Normal=50513001},[6]={BPGem=50618001,Normal=50613001},[7]={BPGem=50718001,Normal=50713001}},--黄宝石
	[22] = 	{[4]={BPGem=50418002,Normal=50413002},[5]={BPGem=50518002,Normal=50513002},[6]={BPGem=50618002,Normal=50613002},[7]={BPGem=50718002,Normal=50713002}},--蓝宝石
	[23] = 	{[4]={BPGem=50416001,Normal=50411001},[5]={BPGem=50516001,Normal=50511001},[6]={BPGem=50616001,Normal=50611001},[7]={BPGem=50716001,Normal=50711001}},--石榴石
	[24] = 	{[4]={BPGem=50416002,Normal=50411002},[5]={BPGem=50516002,Normal=50511002},[6]={BPGem=50616002,Normal=50611002},[7]={BPGem=50716002,Normal=50711002}},--尖晶石
	[25] = 	{[4]={BPGem=50418005,Normal=50413005},[5]={BPGem=50518005,Normal=50513005},[6]={BPGem=50618005,Normal=50613005},[7]={BPGem=50718005,Normal=50713005}},--黑宝石
}
--
local g_GemPayStage={20,40,60,80}

function BudgetPlanGem_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("SHOW_BUDGETPLANGEMINFO_TABLE");

	this:RegisterEvent("BUDGETPLANINFO_DOWNPAYOKORCANCEL");

	this:RegisterEvent("BUDGETPLANINFO_REPAYOKORCANCEL");

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

function BudgetPlanGem_OnLoad()

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= BudgetPlanGem_warfare_Tips:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= BudgetPlanGem_warfare_Tips:GetProperty("UnifiedYPosition");

	g_BudgetPlanGemInfo_Table[1]={DownPay=BudgetPlanGem_Team0001_1,RePay=BudgetPlanGem_Team0002_1}
	g_BudgetPlanGemInfo_Table[2]={DownPay=BudgetPlanGem_Team0001_2,RePay=BudgetPlanGem_Team0002_2}
	g_BudgetPlanGemInfo_Table[3]={DownPay=BudgetPlanGem_Team0001_3,RePay=BudgetPlanGem_Team0002_3}
	g_BudgetPlanGemInfo_Table[4]={DownPay=BudgetPlanGem_Team0001_4,RePay=BudgetPlanGem_Team0002_4}

	g_DownPay_Data[1]={
						GemType = BudgetPlanGem_Team0001_1_SearchMode0001,
						GemLevel= BudgetPlanGem_Team0001_1_SearchMode0002,
						ButtonState=BudgetPlanGem_Team0001_1_warfare_draw3,
						Pic=BudgetPlanGem_Team0001_1_Confraternity06,
						Name =BudgetPlanGem_Team0001_1_Confraternity01_2,
						Price = BudgetPlanGem_Team0001_1_Confraternity02_2,
						DownPayPrice = BudgetPlanGem_Team0001_1_Confraternity03_2,
						RePayPrice = BudgetPlanGem_Team0001_1_Confraternity03_4,
						Info = BudgetPlanGem_Team0001_1_Confraternity05_1
					  }
	g_DownPay_Data[2]={
						GemType = BudgetPlanGem_Team0001_2_SearchMode0001,
						GemLevel= BudgetPlanGem_Team0001_2_SearchMode0002,
						ButtonState=BudgetPlanGem_Team0001_2_warfare_draw3,
						Pic=BudgetPlanGem_Team0001_2_Confraternity06,
						Name =BudgetPlanGem_Team0001_2_Confraternity01_2,
						Price = BudgetPlanGem_Team0001_2_Confraternity02_2,
						DownPayPrice = BudgetPlanGem_Team0001_2_Confraternity03_2,
						RePayPrice = BudgetPlanGem_Team0001_2_Confraternity03_4,
						Info = BudgetPlanGem_Team0001_2_Confraternity05_1
						}
	g_DownPay_Data[3]={
						GemType = BudgetPlanGem_Team0001_3_SearchMode0001,
						GemLevel= BudgetPlanGem_Team0001_3_SearchMode0002,
						ButtonState=BudgetPlanGem_Team0001_3_warfare_draw3,
						Pic=BudgetPlanGem_Team0001_3_Confraternity06,
						Name =BudgetPlanGem_Team0001_3_Confraternity01_2,
						Price = BudgetPlanGem_Team0001_3_Confraternity02_2,
						DownPayPrice = BudgetPlanGem_Team0001_3_Confraternity03_2,
						RePayPrice = BudgetPlanGem_Team0001_3_Confraternity03_4,
						Info = BudgetPlanGem_Team0001_3_Confraternity05_1
						}
	g_DownPay_Data[4]={
						GemType = BudgetPlanGem_Team0001_4_SearchMode0001,
						GemLevel= BudgetPlanGem_Team0001_4_SearchMode0002,
						ButtonState=BudgetPlanGem_Team0001_4_warfare_draw3,
						Pic=BudgetPlanGem_Team0001_4_Confraternity06,
						Name =BudgetPlanGem_Team0001_4_Confraternity01_2,
						Price = BudgetPlanGem_Team0001_4_Confraternity02_2,
						DownPayPrice = BudgetPlanGem_Team0001_4_Confraternity03_2,
						RePayPrice = BudgetPlanGem_Team0001_4_Confraternity03_4,
						Info = BudgetPlanGem_Team0001_4_Confraternity05_1
						}
	g_RePay_Data[1]={
						TopInfo = BudgetPlanGem_Team0002_1_00002_text001,
						ButtonState=BudgetPlanGem_Team0002_1_warfare_draw2,
						Pic = BudgetPlanGem_Team0002_12_Confraternity06,
						Name = BudgetPlanGem_Team0002_12_Confraternity01_2,
						Position = BudgetPlanGem_Team0002_12_Confraternity02_2,
						Price = BudgetPlanGem_Team0002_12_Confraternity03_2,
						Payed = BudgetPlanGem_Team0002_12_Confraternity04_2,
						Paying	= BudgetPlanGem_Team0002_12_Confraternity05_2,
						TailInfo = BudgetPlanGem_Team0002_12_Confraternity05_3
					}
	g_RePay_Data[2]={
						TopInfo = BudgetPlanGem_Team0002_2_00002_text001,
						ButtonState=BudgetPlanGem_Team0002_2_warfare_draw2,
						Pic = BudgetPlanGem_Team0002_22_Confraternity06,
						Name = BudgetPlanGem_Team0002_22_Confraternity01_2,
						Position = BudgetPlanGem_Team0002_22_Confraternity02_2,
						Price = BudgetPlanGem_Team0002_22_Confraternity03_2,
						Payed = BudgetPlanGem_Team0002_22_Confraternity04_2,
						Paying	= BudgetPlanGem_Team0002_22_Confraternity05_2,
						TailInfo = BudgetPlanGem_Team0002_22_Confraternity05_3
						}
	g_RePay_Data[3]={
						TopInfo = BudgetPlanGem_Team0002_3_00002_text001,
						ButtonState=BudgetPlanGem_Team0002_3_warfare_draw2,
						Pic = BudgetPlanGem_Team0002_32_Confraternity06,
						Name = BudgetPlanGem_Team0002_32_Confraternity01_2,
						Position = BudgetPlanGem_Team0002_32_Confraternity02_2,
						Price = BudgetPlanGem_Team0002_32_Confraternity03_2,
						Payed = BudgetPlanGem_Team0002_32_Confraternity04_2,
						Paying	= BudgetPlanGem_Team0002_32_Confraternity05_2,
						TailInfo = BudgetPlanGem_Team0002_32_Confraternity05_3
						}
	g_RePay_Data[4]={
						TopInfo = BudgetPlanGem_Team0002_4_00002_text001,
						ButtonState=BudgetPlanGem_Team0002_4_warfare_draw2,
						Pic = BudgetPlanGem_Team0002_42_Confraternity06,
						Name = BudgetPlanGem_Team0002_42_Confraternity01_2,
						Position = BudgetPlanGem_Team0002_42_Confraternity02_2,
						Price = BudgetPlanGem_Team0002_42_Confraternity03_2,
						Payed = BudgetPlanGem_Team0002_42_Confraternity04_2,
						Paying	= BudgetPlanGem_Team0002_42_Confraternity05_2,
						TailInfo = BudgetPlanGem_Team0002_42_Confraternity05_3
						}
end

function BudgetPlanGem_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		BudgetPlanGem_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		BudgetPlanGem_ResetPos()
	elseif(event == "SHOW_BUDGETPLANGEMINFO_TABLE") then
		g_bConfirm = -1
		BudgetPlanGem_InitAllGemInfo()
		this:Show();
	elseif(event == "BUDGETPLANINFO_DOWNPAYOKORCANCEL") then
		local nbConfirm = tonumber(arg0)
		if nbConfirm == 1 then
			g_bConfirm = 1
			local nIndex = tonumber(arg1)
			BudgetPlanGem_DownPayClick(nIndex)
		else
			g_bConfirm = -1
		end
	elseif(event == "BUDGETPLANINFO_REPAYOKORCANCEL") then
		local nbConfirm = tonumber(arg0)
		if nbConfirm == 1 then
			g_bConfirm = 1
			local nIndex = tonumber(arg1)
			BudgetPlanGem_RePayClick(nIndex)
		else
			g_bConfirm = -1
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function BudgetPlanGem_ResetPos()
	BudgetPlanGem_warfare_Tips:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BudgetPlanGem_warfare_Tips:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 设置还款状态的数据
--================================================
function BudgetPlanGem_SetDownPayData(nIndex)
	g_DownPay_Data[nIndex+1].Name:SetText("")
	--g_DownPay_Data[nIndex+1].ButtonState:SetText("")
	g_DownPay_Data[nIndex+1].ButtonState:SetToolTip("")
	g_DownPay_Data[nIndex+1].ButtonState:Disable()
	g_DownPay_Data[nIndex+1].Price:SetText("")
	g_DownPay_Data[nIndex+1].DownPayPrice:SetText("")
	g_DownPay_Data[nIndex+1].RePayPrice:SetText("")
	g_DownPay_Data[nIndex+1].Info:SetText("")
	g_DownPay_Data[nIndex+1].Pic:SetActionItem(-1)
	g_DownPay_Data[nIndex+1].GemType:ResetList()
	g_DownPay_Data[nIndex+1].GemLevel:ResetList()
	g_DownPay_Data[nIndex+1].GemType:AddTextItem("#{FQBS_140508_11}" ,0)
	g_DownPay_Data[nIndex+1].GemLevel:AddTextItem("#{FQBS_140508_12}" ,0)
	--g_DownPay_Data[nIndex+1].GemType:AddTextItem("" ,0)
	--g_DownPay_Data[nIndex+1].GemLevel:AddTextItem("" ,0)
	for i=1,25 do
		g_DownPay_Data[nIndex+1].GemType:AddTextItem(g_GemName[i] ,i)
	end
	for j=4,7 do
		g_DownPay_Data[nIndex+1].GemLevel:AddTextItem(g_GemLevel[j] ,j)
	end
	g_DownPay_Data[nIndex+1].GemType:SetCurrentSelect(0)
	g_DownPay_Data[nIndex+1].GemLevel:SetCurrentSelect(0)

end

--================================================
-- 把界面切换到首付状态
--================================================
function BudgetPlanGem_ToDownPayState(nIndex)

	g_BudgetPlanGemInfo_Table[nIndex+1].DownPay:SetProperty("Visible" , "True" )
	g_BudgetPlanGemInfo_Table[nIndex+1].RePay:SetProperty("Visible" , "False" )
	BudgetPlanGem_SetDownPayData(nIndex)

end

--================================================
-- 设置还款状态的数据
--================================================
function BudgetPlanGem_SetRePayData(nIndex)
  local GemIndex = BudgetPlanGem:GetBudgetPlanGemInfoGemIndex(nIndex)
	if GemIndex == 0 then
		return
	end
	local GemName = DoubleGem:GetGemNamebyID(GemIndex)
	local	GemBuyPrice = BudgetPlanGem:GetBudgetPlanGemInfoBuyPrice(nIndex)
	local	GemDueTime = BudgetPlanGem:GetBudgetPlanGemInfoDueTime(nIndex)
	local	GemPayStage = BudgetPlanGem:GetBudgetPlanGemInfoPayStage(nIndex)
	local	GemPayPY = BudgetPlanGem:	GetBudgetPlanGemInfoPositionType(nIndex)
	local	GemPayP1 = BudgetPlanGem:GetBudgetPlanGemInfoPositionParm1(nIndex)
	local	GemPayP2 = BudgetPlanGem:GetBudgetPlanGemInfoPositionParm2(nIndex)

	local IsGemValid = BudgetPlanGem:IsBudgetPlanGemVild(nIndex)
	local strGemDueTime = ""
	if IsGemValid == 1 then
		local year,month,day = BudgetPlanGem:BudgetPlanGemDayTimeToYMD(GemDueTime)
		local	strYMD = year.."年"..month.."月"..day.."日"
		strGemDueTime = ScriptGlobal_Format("#{FQBS_140508_27}",strYMD)
	else
	 	strGemDueTime = "#{FQBS_140508_28}"
	 	GemDueTime = BudgetPlanGem:GetServerDayTime()
	end


	g_RePay_Data[nIndex+1].TopInfo:SetText(strGemDueTime)
	g_RePay_Data[nIndex+1].Name:SetText(GemName)
	local Positionstr = ""
	local IsGem = 0
	if GemPayPY == BP_GEM_POS_BAG then
		IsGem = PlayerPackage:IsGem(GemPayP1)
		Positionstr="#{FQBS_140508_21}"
		if IsGem == 0 then --不是宝石就是装备了
			local EquipName = PlayerPackage:GetBagItemName(GemPayP1)
			Positionstr = ScriptGlobal_Format("#{FQBS_140508_24}",EquipName)
		end
	elseif GemPayPY == BP_GEM_POS_BANK then
		IsGem = PlayerPackage:IsGemInBank(GemPayP1)
		Positionstr="#{FQBS_140508_22}"
		if IsGem == 0 then --不是宝石就是装备了
			local EquipName = PlayerPackage:GetBankItemName(GemPayP1)
			Positionstr = ScriptGlobal_Format("#{FQBS_140508_24}",EquipName)
		end
	elseif GemPayPY == BP_GEM_POS_EQUIP then
		local EquipName = PlayerPackage:GetEquipBagItemName(GemPayP1)
		Positionstr = ScriptGlobal_Format("#{FQBS_140508_24}",EquipName)
	end


	g_RePay_Data[nIndex+1].Position:SetText(Positionstr)--FQBS_140508_21
	g_RePay_Data[nIndex+1].Price:SetText(GemBuyPrice.."元宝")--FQBS_140508_25
	local GemPayed = math.mod(GemBuyPrice,5)+ (GemBuyPrice-math.mod(GemBuyPrice,5))*GemPayStage/100
	g_RePay_Data[nIndex+1].Payed:SetText(GemPayed.."元宝".."("..GemPayStage.."%)")--FQBS_140508_25
	g_RePay_Data[nIndex+1].Paying:ResetList()
	for i=1,4 do
		if ((g_GemPayStage[i] + GemPayStage) > 100) then
			break;
		end
		local nSelcetStage = ("支付"..(GemBuyPrice-math.mod(GemBuyPrice,5))*g_GemPayStage[i]/100).."元宝("..g_GemPayStage[i].."%)"
		g_RePay_Data[nIndex+1].Paying:AddTextItem(nSelcetStage,g_GemPayStage[i])
	end
	g_RePay_Data[nIndex+1].Paying:SetCurrentSelect(0)
	local PayingDueTime = BudgetPlanGem_GetPayingDueTime(GemDueTime,g_GemPayStage[1],IsGemValid)
	local strTailInfo =""
	if (g_GemPayStage[1]+GemPayStage) == 100 then
		local nCompleteGem = 0;
	 	for i=1,25 do
	 	 for j=4,7 do
	 	 	if g_GemTypeList[i][j].BPGem == GemIndex then
	 	 			nCompleteGem = g_GemTypeList[i][j].Normal
	 	 	end
	 	 end
	 	end
		strTailInfo = ScriptGlobal_Format("#{FQBS_140508_31}",DoubleGem:GetGemNamebyID(nCompleteGem))
	else
		local	year,month,day = BudgetPlanGem:BudgetPlanGemDayTimeToYMD(PayingDueTime)
		local	strYMD = year.."年"..month.."月"..day.."日"
		strTailInfo = ScriptGlobal_Format("#{FQBS_140508_30}",strYMD)
	end
	g_RePay_Data[nIndex+1].TailInfo:SetText(strTailInfo)
	local Action = BudgetPlanGem:UpdateProductAction(nIndex,GemIndex,GemDueTime,IsGemValid)
	if Action and Action:GetID() ~= 0 then
			g_RePay_Data[nIndex+1].Pic:SetActionItem(Action:GetID())
	else
			g_RePay_Data[nIndex+1].Pic:SetActionItem(-1)
	end
end
--================================================
-- 把界面切换到还款状态
--================================================
function BudgetPlanGem_ToRePayState(nIndex)
	g_BudgetPlanGemInfo_Table[nIndex+1].RePay:SetProperty("Visible" , "True" )
	g_BudgetPlanGemInfo_Table[nIndex+1].DownPay:SetProperty("Visible" , "False" )
	BudgetPlanGem_SetRePayData(nIndex)
end
function BudgetPlanGem_InitAllGemInfo()

	local nCount = BudgetPlanGem:GetBudgetPlanGemInfoCount()
	if nCount > 4 then
		nCount = 4
	end
	for i=0,(nCount-1) do
		BudgetPlanGem_ToRePayState(i)
	end

	for i=nCount,3 do
		BudgetPlanGem_ToDownPayState(i)
	end
end

--================================================
-- 首付选择宝石
--================================================
function DownPay_GemSearch_Changed(nIndex)

	g_bConfirm = -1 --干掉确认状态
	 if not this:IsVisible() then
      return
   end

  local _, nType = g_DownPay_Data[nIndex].GemType:GetCurrentSelect()
	if nType<1 or nType >25 then
		return
	end

	local _, nLevel = g_DownPay_Data[nIndex].GemLevel:GetCurrentSelect()
	if nLevel<4 or nLevel >7 then
		return
	end
	local nGemIndex = g_GemTypeList[nType][nLevel].BPGem;
	if nGemIndex == nil then
		return
	end
	local GemName = DoubleGem:GetGemNamebyID(nGemIndex)
	g_DownPay_Data[nIndex].Name:SetText(GemName)
	local Price		= BudgetPlanGem:GetBudgetPlanGemPrice(nGemIndex)
	local DownPayPrice = math.floor(Price/5) + math.mod(Price,5)
	local RePayPeice = (Price - math.mod(Price,5))/5
	g_DownPay_Data[nIndex].Price:SetText(Price.."元宝")
	g_DownPay_Data[nIndex].DownPayPrice:SetText(DownPayPrice.."元宝(20%)")
	g_DownPay_Data[nIndex].RePayPrice:SetText(RePayPeice.."元宝(20%)")
	local nNormalGemIndex = g_GemTypeList[nType][nLevel].Normal;
	if nNormalGemIndex == nil then
		return
	end
		--为了显示这个时间。。。。。。
	
	local	NDayTime = BudgetPlanGem:GetServerDayTime()
	local	nServerDayTime = BudgetPlanGem_GetPayingDueTime(NDayTime,20,0)
	local year,month,day = BudgetPlanGem:BudgetPlanGemDayTimeToYMD(nServerDayTime)
	local	strYMD = year.."年"..month.."月"..day.."日"
	local NormalGemName = DoubleGem:GetGemNamebyID(nNormalGemIndex)
	local strTempInfo = ScriptGlobal_Format("#{FQBS_140508_17}",GemName,strYMD,NormalGemName)
	g_DownPay_Data[nIndex].Info:SetText(strTempInfo)
	local Action = BudgetPlanGem:UpdateProductAction((nIndex-1),nGemIndex,0,0)
	if Action and Action:GetID() ~= 0 then
			g_DownPay_Data[nIndex].Pic:SetActionItem(Action:GetID())
	else
			g_DownPay_Data[nIndex].Pic:SetActionItem(-1)
	end
	--g_DownPay_Data[nIndex].ButtonState:SetText("#{FQBS_140508_18}")
	g_DownPay_Data[nIndex].ButtonState:SetToolTip("#{FQBS_140508_71}")
	g_DownPay_Data[nIndex].ButtonState:Enable()
  --g_EquipBaoshizhaichu_Container_Gems[i] : SetActionItem( ActionID )
	--g_DownPay_Data[nIndex].Pic:SetActionItem(nGemIndex)
end
--================================================
-- 还款选择付款额度
--================================================
function RePay_StageSearch_Changed(nIndex)

	g_bConfirm = -1 --干掉确认状态

	 if not this:IsVisible() then
      return
   end
  local GemIndex = BudgetPlanGem:GetBudgetPlanGemInfoGemIndex(nIndex-1)
	if GemIndex == 0 then
		return
	end
  local GemDueTime = BudgetPlanGem:GetBudgetPlanGemInfoDueTime(nIndex-1)
  local IsGemValid = BudgetPlanGem:IsBudgetPlanGemVild(nIndex-1)
	if IsGemValid ~= 1 then
	 	GemDueTime = BudgetPlanGem:GetServerDayTime()
	end
  local GemPayStage = BudgetPlanGem:GetBudgetPlanGemInfoPayStage(nIndex-1)
  local _, nSelcetStage =	g_RePay_Data[nIndex].Paying:GetCurrentSelect()
  local PayingDueTime =BudgetPlanGem_GetPayingDueTime(GemDueTime,nSelcetStage,IsGemValid)

	local strTailInfo =""

	if (nSelcetStage+GemPayStage) == 100 then
		local nCompleteGem = 0
	 	for i=1,25 do
	 	 for j=4,7 do
	 	 	if g_GemTypeList[i][j].BPGem == GemIndex then
	 	 			nCompleteGem = g_GemTypeList[i][j].Normal
	 	 	end
	 	 end
	 	end
		strTailInfo = ScriptGlobal_Format("#{FQBS_140508_31}",DoubleGem:GetGemNamebyID(nCompleteGem))
	else
		local year,month,day = BudgetPlanGem:BudgetPlanGemDayTimeToYMD(PayingDueTime)
		local	strYMD = year.."年"..month.."月"..day.."日"
		strTailInfo = ScriptGlobal_Format("#{FQBS_140508_30}",strYMD)
	end
	g_RePay_Data[nIndex].TailInfo:SetText(strTailInfo)
end

--================================================
-- 首付宝石
--================================================
function BudgetPlanGem_DownPayClick(nIndex)
	if not this:IsVisible() then
      return
   end

	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{YXPY_20131118_30}")
		return
	end

	local _, nType = g_DownPay_Data[nIndex].GemType:GetCurrentSelect()
	if nType<1 or nType >25 then
		return
	end

	local _, nLevel = g_DownPay_Data[nIndex].GemLevel:GetCurrentSelect()
	if nLevel<4 or nLevel >7 then
		return
	end

	if g_bConfirm == -1 then
		local nGemIndex = g_GemTypeList[nType][nLevel].BPGem;
		if nGemIndex == nil then
			return
		end
		local Price		= BudgetPlanGem:GetBudgetPlanGemPrice(nGemIndex)
		local DownPayPrice = math.floor( Price/5 ) + math.mod(Price,5)
		PushEvent("BUDGETPLANINFO_DOWNPAY",tonumber(nIndex) ,tonumber(nGemIndex),tonumber(DownPayPrice))--弹出确认框
		--g_bConfirm = 1
	elseif g_bConfirm == 1 then
		g_bConfirm = -1
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DownPayment")
		Set_XSCRIPT_ScriptID(290206)
		Set_XSCRIPT_Parameter(0,nType);
		Set_XSCRIPT_Parameter(1,nLevel);
		Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
end

--================================================
-- 还款宝石
--================================================
function BudgetPlanGem_RePayClick(nIndex)
	 if not this:IsVisible() then
      return
   end

   	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{YXPY_20131118_30}")
		return
	end

  local GemIndex = BudgetPlanGem:GetBudgetPlanGemInfoGemIndex(nIndex)
	if GemIndex == 0 then
		return
	end

	local _, nSelcetStage =	g_RePay_Data[nIndex+1].Paying:GetCurrentSelect()
	--
	local GemPayStage = BudgetPlanGem:GetBudgetPlanGemInfoPayStage(nIndex)
 	local GemBuyPrice	= BudgetPlanGem:GetBudgetPlanGemInfoBuyPrice(nIndex)
	--PushDebugMessage(g_bConfirm)
	if g_bConfirm == -1 then
		local nCompleteGem = 0
	 	for i=1,25 do
	 	 for j=4,7 do
	 	 	if g_GemTypeList[i][j].BPGem == GemIndex then
	 	 			nCompleteGem = g_GemTypeList[i][j].Normal
	 	 	end
	 	 end
	 	end
	 	if nCompleteGem == 0 then
	 		return
		end

		local GemDueTime = BudgetPlanGem:GetBudgetPlanGemInfoDueTime(nIndex)
		local IsGemValid = BudgetPlanGem:IsBudgetPlanGemVild(nIndex)
		if IsGemValid ~= 1 then
		 	GemDueTime = BudgetPlanGem:GetServerDayTime()
		end
 		
  	local nPayingDueTime =  BudgetPlanGem_GetPayingDueTime(GemDueTime,nSelcetStage,IsGemValid)
		local nPayingYuanBao =(GemBuyPrice-math.mod(GemBuyPrice,5))*nSelcetStage/100
		local ComStage = GemPayStage+nSelcetStage
		PushEvent("BUDGETPLANINFO_REPAY",tonumber(nIndex),tonumber(GemIndex),tonumber(nPayingYuanBao),tonumber(nSelcetStage),tonumber(nPayingDueTime),tonumber(nCompleteGem),tonumber(ComStage))--弹出确认框
	elseif g_bConfirm == 1 then
		g_bConfirm = -1
	  local	GemPayStage = BudgetPlanGem:GetBudgetPlanGemInfoPayStage(nIndex)
		local	GemPayPY = BudgetPlanGem:	GetBudgetPlanGemInfoPositionType(nIndex)
		local	GemPayP1 = BudgetPlanGem:GetBudgetPlanGemInfoPositionParm1(nIndex)
		local	GemPayP2 = BudgetPlanGem:GetBudgetPlanGemInfoPositionParm2(nIndex)

		local PayingStage = nSelcetStage + GemPayStage
		local StageParm = GemPayStage*1000 + PayingStage
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PayMoney")
		Set_XSCRIPT_ScriptID(290206)
		Set_XSCRIPT_Parameter(0,GemIndex);
		Set_XSCRIPT_Parameter(1,GemPayPY);
		Set_XSCRIPT_Parameter(2,GemPayP1);
		Set_XSCRIPT_Parameter(3,GemPayP2);
		Set_XSCRIPT_Parameter(4,StageParm);
		Set_XSCRIPT_Parameter(5,GemBuyPrice);
		Set_XSCRIPT_ParamCount(6)
		Send_XSCRIPT()
	end
end

function	BudgetPlanGem_GetPayingDueTime(Nowtime,Stage,OneDay)--首付和还款过期宝石需要-1天，啦啦啦~

	local nPayingDueTime =  Nowtime + (Stage)/20*30 -1 + OneDay
	if math.mod(nPayingDueTime,1000)>=365 then
		nPayingDueTime = (math.floor(nPayingDueTime/1000) + 1)*1000 + (math.mod(nPayingDueTime,1000)-365)
	end
	return nPayingDueTime
end