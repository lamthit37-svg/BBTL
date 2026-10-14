
local PS_nSelectSubType = 1 --子类按钮选择， 依次从1到8
local PS_nSearchOrder = 1         --排序方式
local PS_ctrlPetSubBtns = {}
local PS_CboSearchItem = {}
local PS_ctrlPetActions = {}
local PS_ctrlItemActions = {}
local PS_ctrlEquipActions = {}
local PS_ctrlInfantCardActions = {}
local PS_ctrlPetTexts = {}
local PS_ctrlEquipTexts = {}
local PS_ctrlInfantCardTexts = {}
local PS_ctrlFurnitureTexts = {}
local PS_ctrlFurnitureActions = {}
local PS_nSelectTable = 2		--2 is item, 1 is pet, 3 is equip, 4 is infantcard

local PS_SearchTypeText={}
local PS_ctrlItemTexts = {}
local PS_ctrlItemChecks = {}

local PS_ItemCount_Show = 0 		-- 当前显示的物品数
local PS_ItemIndex_Show = {}		-- 显示的物品下标
local PS_ItemCount_Select = 0 	-- 当前选中的物品数
local PS_ItemIndex_Select = {} 	-- 选中的物品下标

local PS_ctrlEquipFlash = {}

local PS_ctrlInfantCardFlash = {}

local PS_btnPetDetails = {}

local PS_ctrlFurnitureFlash = {}



local PS_Cur_Select = 0  		--当前选中的商品
local PS_Page_Cur = 0		--本次查询的页数
local PS_Page_Total = 0	--本次查询总页数
local PS_G_SEARCHTYPE_FURNITURE = 5	--查询种类5家具

local PS_EquipTypeTrans = {}

local g_PS_ShopSearch_Frame_UnifiedXPosition;
local g_PS_ShopSearch_Frame_UnifiedYPosition;

function PS_ShopSearch_PreLoad()

	this:RegisterEvent("UPDATE_PLAYERSHOP_SEARCH");
	this:RegisterEvent("OPEN_PLAYERSHOP_SEARCH");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--更新搜索界面
	this:RegisterEvent("PS_UPDATE_OTHER_SHOP")
	
	this:RegisterEvent("CLOSE_WINDOW")
	this:RegisterEvent("PSSHOPSEARCH_CLEAR_MULTIBUY")
end



function PS_ShopSearch_OnLoad()

	PS_ctrlPetSubBtns = 
	{
		[1] = {  ctrl = PS_ShopSearch_PetType1 , realIdx = 2, }, --5级可携带 
		[2] = {  ctrl = PS_ShopSearch_PetType2 , realIdx = 3, }, --45级可携带
		[3] = {  ctrl = PS_ShopSearch_PetType3 , realIdx = 4, }, --55级可携带
		[4] = {  ctrl = PS_ShopSearch_PetType4 , realIdx = 5, }, --65级可携带
		[5] = {  ctrl = PS_ShopSearch_PetType5 , realIdx = 6, }, --75级可携带
		[6] = {  ctrl = PS_ShopSearch_PetType6 , realIdx = 7, }, --85级可携带
		[7] = {  ctrl = PS_ShopSearch_PetType7 , realIdx = 8, }, --95级可携带
	}
	
	--按文档里的顺序，注意需要与HUMAN_EQUIP对应起来
	PS_EquipTypeTrans = 
	{
		[1] = 1, [2] = 3, [3] = 17, [4] = 16, [5] = 5,
		[6] = 7, [7] = 6, [8] = 8, [9] = 14, [10] = 2,
		[11] = 4, [12] = 9, [13] = 21,[14]=18,[15]=10,
		[16] = 20, [17] = 19,
	}

	
	PS_CboSearchItem = 
	{
		[1] = "#{YBSC_100111_69}",		--按单价从低至高排列
		[2] = "#{YBSC_100111_68}",		--按单价从高至低排列
	}
	
	PS_SearchTypeText = 
	{
		[1] = "#{JZSHYH_140214_18}",
		[2] = "#{JZSHYH_140214_17}",
		[3] = "#{JZSHYH_140214_19}",
		[4] = "#{SSDJ_1508010_01}",
		[5] = "#{JZFUR_061101_1}",
	}
	
	PS_ctrlPetActions = 
	{
		PS_ShopSearch_Pet1, PS_ShopSearch_Pet2,PS_ShopSearch_Pet3, PS_ShopSearch_Pet4,PS_ShopSearch_Pet5,
		PS_ShopSearch_Pet6,PS_ShopSearch_Pet7,PS_ShopSearch_Pet8,PS_ShopSearch_Pet9,PS_ShopSearch_Pet10,
	}
	
	PS_ctrlItemChecks = 
	{
		PS_ShopSearch_Item1_DX, PS_ShopSearch_Item2_DX, PS_ShopSearch_Item3_DX, PS_ShopSearch_Item4_DX, PS_ShopSearch_Item5_DX,
		PS_ShopSearch_Item6_DX, PS_ShopSearch_Item7_DX, PS_ShopSearch_Item8_DX, PS_ShopSearch_Item9_DX, PS_ShopSearch_Item10_DX,
	}
	
	PS_ctrlItemActions = 
	{
		PS_ShopSearch_Item1, PS_ShopSearch_Item2, PS_ShopSearch_Item3, PS_ShopSearch_Item4, PS_ShopSearch_Item5,
		PS_ShopSearch_Item6, PS_ShopSearch_Item7, PS_ShopSearch_Item8, PS_ShopSearch_Item9, PS_ShopSearch_Item10,
	}
	
	PS_ctrlEquipActions =
	{
		PS_ShopSearch_Equip1, PS_ShopSearch_Equip2, PS_ShopSearch_Equip3, PS_ShopSearch_Equip4, PS_ShopSearch_Equip5,
		PS_ShopSearch_Equip6, PS_ShopSearch_Equip7, PS_ShopSearch_Equip8, PS_ShopSearch_Equip9, PS_ShopSearch_Equip10,
	}
	
	PS_ctrlInfantCardActions =
	{
		PS_ShopSearch_Infant1, PS_ShopSearch_Infant2, PS_ShopSearch_Infant3, PS_ShopSearch_Infant4, PS_ShopSearch_Infant5,
		PS_ShopSearch_Infant6, PS_ShopSearch_Infant7, PS_ShopSearch_Infant8, PS_ShopSearch_Infant9, PS_ShopSearch_Infant10,
	}
	
	PS_ctrlFurnitureActions = 
	{
		PS_ShopSearch_BieYeFurniture1,PS_ShopSearch_BieYeFurniture2,PS_ShopSearch_BieYeFurniture3,PS_ShopSearch_BieYeFurniture4,PS_ShopSearch_BieYeFurniture5,
		PS_ShopSearch_BieYeFurniture6,PS_ShopSearch_BieYeFurniture7,PS_ShopSearch_BieYeFurniture8,PS_ShopSearch_BieYeFurniture9,PS_ShopSearch_BieYeFurniture10,
	}
	
	PS_ctrlItemTexts = 
	{
		[1]	= {PS_ShopSearch_Item1_Text_1, PS_ShopSearch_Item1_Text_2, PS_ShopSearch_Item1_Text_3, PS_ShopSearch_Item1_Text_4, PS_ShopSearch_Item1_Text_5, PS_ShopSearch_Item1_Text_6,},
		[2]	= {PS_ShopSearch_Item2_Text_1, PS_ShopSearch_Item2_Text_2, PS_ShopSearch_Item2_Text_3, PS_ShopSearch_Item2_Text_4, PS_ShopSearch_Item2_Text_5, PS_ShopSearch_Item2_Text_6,},
		[3]	= {PS_ShopSearch_Item3_Text_1, PS_ShopSearch_Item3_Text_2, PS_ShopSearch_Item3_Text_3, PS_ShopSearch_Item3_Text_4, PS_ShopSearch_Item3_Text_5, PS_ShopSearch_Item3_Text_6,},
		[4]	= {PS_ShopSearch_Item4_Text_1, PS_ShopSearch_Item4_Text_2, PS_ShopSearch_Item4_Text_3, PS_ShopSearch_Item4_Text_4, PS_ShopSearch_Item4_Text_5, PS_ShopSearch_Item4_Text_6,},
		[5]	= {PS_ShopSearch_Item5_Text_1, PS_ShopSearch_Item5_Text_2, PS_ShopSearch_Item5_Text_3, PS_ShopSearch_Item5_Text_4, PS_ShopSearch_Item5_Text_5, PS_ShopSearch_Item5_Text_6,},
		[6]	= {PS_ShopSearch_Item6_Text_1, PS_ShopSearch_Item6_Text_2, PS_ShopSearch_Item6_Text_3, PS_ShopSearch_Item6_Text_4, PS_ShopSearch_Item6_Text_5, PS_ShopSearch_Item6_Text_6,},
		[7]	= {PS_ShopSearch_Item7_Text_1, PS_ShopSearch_Item7_Text_2, PS_ShopSearch_Item7_Text_3, PS_ShopSearch_Item7_Text_4, PS_ShopSearch_Item7_Text_5, PS_ShopSearch_Item7_Text_6,},
		[8]	= {PS_ShopSearch_Item8_Text_1, PS_ShopSearch_Item8_Text_2, PS_ShopSearch_Item8_Text_3, PS_ShopSearch_Item8_Text_4, PS_ShopSearch_Item8_Text_5, PS_ShopSearch_Item8_Text_6,},
		[9]	= {PS_ShopSearch_Item9_Text_1, PS_ShopSearch_Item9_Text_2, PS_ShopSearch_Item9_Text_3, PS_ShopSearch_Item9_Text_4, PS_ShopSearch_Item9_Text_5, PS_ShopSearch_Item9_Text_6,},
		[10]	= {PS_ShopSearch_Item10_Text_1, PS_ShopSearch_Item10_Text_2, PS_ShopSearch_Item10_Text_3, PS_ShopSearch_Item10_Text_4, PS_ShopSearch_Item10_Text_5, PS_ShopSearch_Item10_Text_6,},
	}
	
	PS_ctrlPetTexts = 
	{
		[1] = {PS_ShopSearch_Pet1_Text_1,  PS_ShopSearch_Pet1_Text_2,  PS_ShopSearch_Pet1_Text_3,  PS_ShopSearch_Pet1_Text_4,},
		[2] = {PS_ShopSearch_Pet2_Text_1,  PS_ShopSearch_Pet2_Text_2,  PS_ShopSearch_Pet2_Text_3,  PS_ShopSearch_Pet2_Text_4,},
		[3] = {PS_ShopSearch_Pet3_Text_1,  PS_ShopSearch_Pet3_Text_2,  PS_ShopSearch_Pet3_Text_3,  PS_ShopSearch_Pet3_Text_4,},
		[4] = {PS_ShopSearch_Pet4_Text_1,  PS_ShopSearch_Pet4_Text_2,  PS_ShopSearch_Pet4_Text_3,  PS_ShopSearch_Pet4_Text_4,},
		[5] = {PS_ShopSearch_Pet5_Text_1,  PS_ShopSearch_Pet5_Text_2,  PS_ShopSearch_Pet5_Text_3,  PS_ShopSearch_Pet5_Text_4,},
		[6] = {PS_ShopSearch_Pet6_Text_1,  PS_ShopSearch_Pet6_Text_2,  PS_ShopSearch_Pet6_Text_3,  PS_ShopSearch_Pet6_Text_4,},
		[7] = {PS_ShopSearch_Pet7_Text_1,  PS_ShopSearch_Pet7_Text_2,  PS_ShopSearch_Pet7_Text_3,  PS_ShopSearch_Pet7_Text_4,},
		[8] = {PS_ShopSearch_Pet8_Text_1,  PS_ShopSearch_Pet8_Text_2,  PS_ShopSearch_Pet8_Text_3,  PS_ShopSearch_Pet8_Text_4,},
		[9] = {PS_ShopSearch_Pet9_Text_1,  PS_ShopSearch_Pet9_Text_2,  PS_ShopSearch_Pet9_Text_3,  PS_ShopSearch_Pet9_Text_4,},
		[10] = {PS_ShopSearch_Pet10_Text_1,  PS_ShopSearch_Pet10_Text_2,  PS_ShopSearch_Pet10_Text_3,  PS_ShopSearch_Pet10_Text_4,},
		
	}
	
	PS_ctrlEquipTexts = 
	{
		[1]  = {PS_ShopSearch_Equip1_Text_1,  PS_ShopSearch_Equip1_Text_2,  PS_ShopSearch_Equip1_Text_3, PS_ShopSearch_Equip1_Text_4, },
		[2]  = {PS_ShopSearch_Equip2_Text_1,  PS_ShopSearch_Equip2_Text_2,  PS_ShopSearch_Equip2_Text_3, PS_ShopSearch_Equip2_Text_4, },
		[3]  = {PS_ShopSearch_Equip3_Text_1,  PS_ShopSearch_Equip3_Text_2,  PS_ShopSearch_Equip3_Text_3, PS_ShopSearch_Equip3_Text_4, },
		[4]  = {PS_ShopSearch_Equip4_Text_1,  PS_ShopSearch_Equip4_Text_2,  PS_ShopSearch_Equip4_Text_3, PS_ShopSearch_Equip4_Text_4, },
		[5]  = {PS_ShopSearch_Equip5_Text_1,  PS_ShopSearch_Equip5_Text_2,  PS_ShopSearch_Equip5_Text_3, PS_ShopSearch_Equip5_Text_4, },
		[6]  = {PS_ShopSearch_Equip6_Text_1,  PS_ShopSearch_Equip6_Text_2,  PS_ShopSearch_Equip6_Text_3, PS_ShopSearch_Equip6_Text_4, },
		[7]  = {PS_ShopSearch_Equip7_Text_1,  PS_ShopSearch_Equip7_Text_2,  PS_ShopSearch_Equip7_Text_3, PS_ShopSearch_Equip7_Text_4, },
		[8]  = {PS_ShopSearch_Equip8_Text_1,  PS_ShopSearch_Equip8_Text_2,  PS_ShopSearch_Equip8_Text_3, PS_ShopSearch_Equip8_Text_4, },
		[9]  = {PS_ShopSearch_Equip9_Text_1,  PS_ShopSearch_Equip9_Text_2,  PS_ShopSearch_Equip9_Text_3, PS_ShopSearch_Equip9_Text_4, },
		[10]  = {PS_ShopSearch_Equip10_Text_1,  PS_ShopSearch_Equip10_Text_2,  PS_ShopSearch_Equip10_Text_3, PS_ShopSearch_Equip10_Text_4, },
		
	}
	
	PS_ctrlInfantCardTexts = 
	{
		[1]  = {PS_ShopSearch_Infant1_Text_1,  PS_ShopSearch_Infant1_Text_2,  PS_ShopSearch_Infant1_Text_3, PS_ShopSearch_Infant1_Text_4, },
		[2]  = {PS_ShopSearch_Infant2_Text_1,  PS_ShopSearch_Infant2_Text_2,  PS_ShopSearch_Infant2_Text_3, PS_ShopSearch_Infant2_Text_4, },
		[3]  = {PS_ShopSearch_Infant3_Text_1,  PS_ShopSearch_Infant3_Text_2,  PS_ShopSearch_Infant3_Text_3, PS_ShopSearch_Infant3_Text_4, },
		[4]  = {PS_ShopSearch_Infant4_Text_1,  PS_ShopSearch_Infant4_Text_2,  PS_ShopSearch_Infant4_Text_3, PS_ShopSearch_Infant4_Text_4, },
		[5]  = {PS_ShopSearch_Infant5_Text_1,  PS_ShopSearch_Infant5_Text_2,  PS_ShopSearch_Infant5_Text_3, PS_ShopSearch_Infant5_Text_4, },
		[6]  = {PS_ShopSearch_Infant6_Text_1,  PS_ShopSearch_Infant6_Text_2,  PS_ShopSearch_Infant6_Text_3, PS_ShopSearch_Infant6_Text_4, },
		[7]  = {PS_ShopSearch_Infant7_Text_1,  PS_ShopSearch_Infant7_Text_2,  PS_ShopSearch_Infant7_Text_3, PS_ShopSearch_Infant7_Text_4, },
		[8]  = {PS_ShopSearch_Infant8_Text_1,  PS_ShopSearch_Infant8_Text_2,  PS_ShopSearch_Infant8_Text_3, PS_ShopSearch_Infant8_Text_4, },
		[9]  = {PS_ShopSearch_Infant9_Text_1,  PS_ShopSearch_Infant9_Text_2,  PS_ShopSearch_Infant9_Text_3, PS_ShopSearch_Infant9_Text_4, },
		[10]  = {PS_ShopSearch_Infant10_Text_1,  PS_ShopSearch_Infant10_Text_2,  PS_ShopSearch_Infant10_Text_3, PS_ShopSearch_Infant10_Text_4, },
		
	}
	
	PS_ctrlFurnitureTexts = 
	{
		[1] = {PS_ShopSearch_BieYeFurniture1_Text_1,PS_ShopSearch_BieYeFurniture1_Text_2,PS_ShopSearch_BieYeFurniture1_Text_3,PS_ShopSearch_BieYeFurniture1_Text_4,		PS_ShopSearch_BieYeFurniture1_Text_5,PS_ShopSearch_BieYeFurniture1_Text_6, },
		[2] = {PS_ShopSearch_BieYeFurniture2_Text_1,PS_ShopSearch_BieYeFurniture2_Text_2,PS_ShopSearch_BieYeFurniture2_Text_3,PS_ShopSearch_BieYeFurniture2_Text_4,		PS_ShopSearch_BieYeFurniture2_Text_5,PS_ShopSearch_BieYeFurniture2_Text_6, },
		[3] = {PS_ShopSearch_BieYeFurniture3_Text_1,PS_ShopSearch_BieYeFurniture3_Text_2,PS_ShopSearch_BieYeFurniture3_Text_3,PS_ShopSearch_BieYeFurniture3_Text_4,		PS_ShopSearch_BieYeFurniture3_Text_5,PS_ShopSearch_BieYeFurniture3_Text_6, },
		[4] = {PS_ShopSearch_BieYeFurniture4_Text_1,PS_ShopSearch_BieYeFurniture4_Text_2,PS_ShopSearch_BieYeFurniture4_Text_3,PS_ShopSearch_BieYeFurniture4_Text_4,		PS_ShopSearch_BieYeFurniture4_Text_5,PS_ShopSearch_BieYeFurniture4_Text_6, },
		[5] = {PS_ShopSearch_BieYeFurniture5_Text_1,PS_ShopSearch_BieYeFurniture5_Text_2,PS_ShopSearch_BieYeFurniture5_Text_3,PS_ShopSearch_BieYeFurniture5_Text_4,		PS_ShopSearch_BieYeFurniture5_Text_5,PS_ShopSearch_BieYeFurniture5_Text_6, },
		[6] = {PS_ShopSearch_BieYeFurniture6_Text_1,PS_ShopSearch_BieYeFurniture6_Text_2,PS_ShopSearch_BieYeFurniture6_Text_3,PS_ShopSearch_BieYeFurniture6_Text_4,		PS_ShopSearch_BieYeFurniture6_Text_5,PS_ShopSearch_BieYeFurniture6_Text_6, },
		[7] = {PS_ShopSearch_BieYeFurniture7_Text_1,PS_ShopSearch_BieYeFurniture7_Text_2,PS_ShopSearch_BieYeFurniture7_Text_3,PS_ShopSearch_BieYeFurniture7_Text_4,		PS_ShopSearch_BieYeFurniture7_Text_5,PS_ShopSearch_BieYeFurniture7_Text_6, },
		[8] = {PS_ShopSearch_BieYeFurniture8_Text_1,PS_ShopSearch_BieYeFurniture8_Text_2,PS_ShopSearch_BieYeFurniture8_Text_3,PS_ShopSearch_BieYeFurniture8_Text_4,		PS_ShopSearch_BieYeFurniture8_Text_5,PS_ShopSearch_BieYeFurniture8_Text_6, },
		[9] = {PS_ShopSearch_BieYeFurniture9_Text_1,PS_ShopSearch_BieYeFurniture9_Text_2,PS_ShopSearch_BieYeFurniture9_Text_3,PS_ShopSearch_BieYeFurniture9_Text_4,		PS_ShopSearch_BieYeFurniture9_Text_5,PS_ShopSearch_BieYeFurniture9_Text_6, },
		[10] = {PS_ShopSearch_BieYeFurniture10_Text_1,PS_ShopSearch_BieYeFurniture10_Text_2,PS_ShopSearch_BieYeFurniture10_Text_3,PS_ShopSearch_BieYeFurniture10_Text_4, PS_ShopSearch_BieYeFurniture10_Text_5,PS_ShopSearch_BieYeFurniture10_Text_6,},
	}
	
	PS_ctrlItemFlash = 
	{
		PS_ShopSearch_Item1_Flash, PS_ShopSearch_Item2_Flash, PS_ShopSearch_Item3_Flash, PS_ShopSearch_Item4_Flash, PS_ShopSearch_Item5_Flash,
		PS_ShopSearch_Item6_Flash, PS_ShopSearch_Item7_Flash, PS_ShopSearch_Item8_Flash, PS_ShopSearch_Item9_Flash, PS_ShopSearch_Item10_Flash,
	}
	
	PS_ctrlPetFlash = 
	{
		PS_ShopSearch_Pet1_Flash,PS_ShopSearch_Pet2_Flash,PS_ShopSearch_Pet3_Flash,PS_ShopSearch_Pet4_Flash,PS_ShopSearch_Pet5_Flash,
		PS_ShopSearch_Pet6_Flash,PS_ShopSearch_Pet7_Flash,PS_ShopSearch_Pet8_Flash,PS_ShopSearch_Pet9_Flash,PS_ShopSearch_Pet10_Flash,
	}
	
	PS_ctrlEquipFlash = 
	{
		PS_ShopSearch_Equip1_Flash, PS_ShopSearch_Equip2_Flash, PS_ShopSearch_Equip3_Flash, PS_ShopSearch_Equip4_Flash, PS_ShopSearch_Equip5_Flash,
		PS_ShopSearch_Equip6_Flash, PS_ShopSearch_Equip7_Flash, PS_ShopSearch_Equip8_Flash, PS_ShopSearch_Equip9_Flash, PS_ShopSearch_Equip10_Flash,
	}
	
	PS_ctrlInfantCardFlash = 
	{
		PS_ShopSearch_Infant1_Flash, PS_ShopSearch_Infant2_Flash, PS_ShopSearch_Infant3_Flash, PS_ShopSearch_Infant4_Flash, PS_ShopSearch_Infant5_Flash,
		PS_ShopSearch_Infant6_Flash, PS_ShopSearch_Infant7_Flash, PS_ShopSearch_Infant8_Flash, PS_ShopSearch_Infant9_Flash, PS_ShopSearch_Infant10_Flash,
	}
	
	PS_ctrlFurnitureFlash = 
	{
		PS_ShopSearch_BieYeFurniture1_Flash,PS_ShopSearch_BieYeFurniture2_Flash,PS_ShopSearch_BieYeFurniture3_Flash,PS_ShopSearch_BieYeFurniture4_Flash,PS_ShopSearch_BieYeFurniture5_Flash,
		PS_ShopSearch_BieYeFurniture6_Flash,PS_ShopSearch_BieYeFurniture7_Flash,PS_ShopSearch_BieYeFurniture8_Flash,PS_ShopSearch_BieYeFurniture9_Flash,PS_ShopSearch_BieYeFurniture10_Flash,
	}	
	PS_btnPetDetails =
	{
		PS_ShopSearch_Pet1_btnDetail,PS_ShopSearch_Pet2_btnDetail,PS_ShopSearch_Pet3_btnDetail,PS_ShopSearch_Pet4_btnDetail,PS_ShopSearch_Pet5_btnDetail,
		PS_ShopSearch_Pet6_btnDetail,PS_ShopSearch_Pet7_btnDetail,PS_ShopSearch_Pet8_btnDetail,PS_ShopSearch_Pet9_btnDetail,PS_ShopSearch_Pet10_btnDetail,
	}
	
	
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_86}", 1)	--全部
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_99}", 2)	--1级~9级
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_114}", 3)	--10级~19级
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_115}", 4)	--20级~29级
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_116}", 5)	--30级~39级
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_117}", 6)	--40级~49级
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_118}", 7)	--50级~59级
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_119}", 8)	--60级~69级
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_100}", 9)	--70级~79级
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_101}", 10)	--80级~89级
	PS_ShopSearch_EquipType2:AddTextItem("#{YBSC_XML_102}", 11)	--90级~100级
	
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_86}", 1)	--全部
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_113}", 2)	--未鉴定
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_103}", 3)	--1星以上
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_104}", 4)	--2星以上
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_105}", 5)	--3星以上
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_106}", 6)	--4星以上
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_107}", 7)	--5星以上
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_108}", 8)	--6星以上
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_109}", 9)	--7星以上
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_110}", 10)	--8星以上
	PS_ShopSearch_EquipType3:AddTextItem("#{YBSC_XML_120}", 11)	--9星
	
	PS_ShopSearch_InfantBtn1:AddTextItem("#{SSDJ_1508010_06}", 1)	--全部
	PS_ShopSearch_InfantBtn1:AddTextItem("#{SSDJ_1508010_07}", 2)	--虚竹
	PS_ShopSearch_InfantBtn1:AddTextItem("#{SSDJ_1508010_08}", 3)	--萧峰
	PS_ShopSearch_InfantBtn1:AddTextItem("#{SSDJ_1508010_09}", 4)	--段誉
	PS_ShopSearch_InfantBtn1:AddTextItem("#{SSDJ_1508010_10}", 5)	--王语嫣
	
	PS_ShopSearch_InfantBtn2:AddTextItem("#{SSDJ_1508010_11}", 1)	--全部
	PS_ShopSearch_InfantBtn2:AddTextItem("#{SSDJ_1508010_12}", 2)	--神兵典籍
	PS_ShopSearch_InfantBtn2:AddTextItem("#{SSDJ_1508010_13}", 3)	--武决典籍
	PS_ShopSearch_InfantBtn2:AddTextItem("#{SSDJ_1508010_14}", 4)	--锦装典籍
	PS_ShopSearch_InfantBtn2:AddTextItem("#{SSDJ_1508010_15}", 5)	--轻功典籍
	PS_ShopSearch_InfantBtn2:AddTextItem("#{SSDJ_1508010_16}", 6)	--名饰典籍
	PS_ShopSearch_InfantBtn2:AddTextItem("#{SSDJ_1508010_17}", 7)	--名驹典籍
	
	PS_ShopSearch_InfantBtn3:AddTextItem("#{SSDJ_1508010_18}", 1)	--全部
	PS_ShopSearch_InfantBtn3:AddTextItem("#{SSDJ_1508010_19}", 2)	--绿色
	PS_ShopSearch_InfantBtn3:AddTextItem("#{SSDJ_1508010_20}", 3)	--蓝色
	PS_ShopSearch_InfantBtn3:AddTextItem("#{SSDJ_1508010_21}", 4)	--紫色
	PS_ShopSearch_InfantBtn3:AddTextItem("#{SSDJ_1508010_22}", 5)	--橙色
	
	
	PS_ShopSearch_BieYeFurnitureType1:AddTextItem("全部", 1)
	PS_ShopSearch_BieYeFurnitureType1:AddTextItem("庭院家具",2)
	PS_ShopSearch_BieYeFurnitureType1:AddTextItem("居室家具",3)
	
	PS_ShopSearch_BieYeFurnitureType2:AddTextItem("#{JZFUR_061101_5}",1)
	PS_ShopSearch_BieYeFurnitureType2:AddTextItem("#{JZFUR_061101_6}",2)
	PS_ShopSearch_BieYeFurnitureType2:AddTextItem("#{JZFUR_061101_7}",3)
	PS_ShopSearch_BieYeFurnitureType2:AddTextItem("#{JZFUR_061101_8}",4)
	PS_ShopSearch_BieYeFurnitureType2:AddTextItem("#{JZFUR_061101_9}",5)
	PS_ShopSearch_BieYeFurnitureType2:AddTextItem("#{JZFUR_061101_10}",6)
	PS_ShopSearch_BieYeFurnitureType2:AddTextItem("#{JZFUR_061101_11}",7)
	
	
	g_PS_ShopSearch_Frame_UnifiedXPosition = PS_ShopSearch_Frame : GetProperty("UnifiedXPosition");
	g_PS_ShopSearch_Frame_UnifiedYPosition = PS_ShopSearch_Frame : GetProperty("UnifiedYPosition");
	
	
end


function PS_ShopSearch_OnEvent(event)
	if(event == "UPDATE_PLAYERSHOP_SEARCH") then
		PS_ShopSearch_Update(tonumber(arg0),tonumber(arg1))
	elseif( event == "OPEN_PLAYERSHOP_SEARCH") then
		if (IsWindowShow("PS_ShopList")) then
			CloseWindow("PS_ShopListQuick")
		end
		
		PS_ShopSearch_Check_Item4:SetCheck(1)
		if (arg0 and arg1) then
			if (arg2 and arg3) then
				PS_ShopSearch_Frame:SetProperty("UnifiedXPosition", arg2);
				PS_ShopSearch_Frame:SetProperty("UnifiedYPosition", arg3);
			end
		end
		
		objCared = PlayerShop:GetNpcId();
		this:CareObject(objCared, 1, "PS_ShopSearch");
		
		PS_ShopSearch_Show()
	elseif ( event == "ADJEST_UI_POS") then
		PS_ShopSearch_Frame_On_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED") then
		PS_ShopSearch_Frame_On_ResetPos()
	elseif ( event == "PS_UPDATE_OTHER_SHOP") then
		if this:IsVisible() then

			local strKey = PS_ShopSearch_ItemName:GetText()
			PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , strKey , PS_Page_Cur )
		end
	elseif (event == "CLOSE_WINDOW") then
		if this:IsVisible()  and tostring(arg0) == "PS_ShopSearch" then
			this:Hide()
		end
	elseif (event == "PSSHOPSEARCH_CLEAR_MULTIBUY") then
		if this:IsVisible() and PS_nSelectTable == 2 then
			PS_ShopSearch_ItemCheckClear()
		end	
	end
end

function PS_ShopSearch_Frame_On_ResetPos()
	PS_ShopSearch_Frame : SetProperty("UnifiedXPosition", g_PS_ShopSearch_Frame_UnifiedXPosition);
	PS_ShopSearch_Frame : SetProperty("UnifiedYPosition", g_PS_ShopSearch_Frame_UnifiedYPosition);
end

function PS_ShopSearch_Update(curPage, totalPage)

	PS_Cur_Select = 0
	PS_ShopSearch_btnUpPage:Enable()
	PS_ShopSearch_btnDownPage:Enable()
	PS_ShopSearch_btnGo : Enable()
		
	if PS_nSelectTable == 2 then
	
		PS_ShopSearch_ItemInfoBk:Show()
		PS_ShopSearch_DX_Text:Show()
		PS_ShopSearch_DX:Show()
		PS_ShopSearch_DX:SetCheck(0)
		PS_ItemCount_Select = 0
		for i = 1,10 do
			PS_ItemIndex_Select[i] = 0
		end
		PS_ShopSearch_EquipInfoBk:Hide()
		PS_ShopSearch_PetInfoBk:Hide()
		PS_ShopSearch_InfantBk:Hide()
		PS_ShopSearch_BieYeFurnitureInfoBk:Hide()
		PS_ShopSearch_ClearItemList()
		for i = 1 ,10 do 
			local theAction = EnumAction( i - 1 , "playershop_cur_page")
			if theAction:GetID() ~= 0 then
				-- PushDebugMessage("fffffffffffffffff="..i)
				local pName ,pShopName, pShopID ,pCount ,pYB = PlayerShop:GetItemPSInfo( i - 1 )			
				if pName ~= nil and pShopID ~= nil and pCount ~= nil and pYB ~= nil and pCount > 0 then
					PS_ShopSearch_InsertItemList(i, pName, pShopName, pShopID,pCount, pYB)
					PS_ctrlItemActions[i]:SetActionItem(theAction:GetID())
					PS_ItemIndex_Show[i] = 1
					PS_ItemCount_Show = PS_ItemCount_Show + 1
				end
			end
		end	
	elseif PS_nSelectTable == 1 then
	
		PS_ShopSearch_ItemInfoBk:Hide()
		PS_ShopSearch_DX_Text:Hide()
		PS_ShopSearch_DX:Hide()
		PS_ShopSearch_EquipInfoBk:Hide()
		PS_ShopSearch_InfantBk:Hide()
		PS_ShopSearch_PetInfoBk:Show()
		PS_ShopSearch_BieYeFurnitureInfoBk:Hide()
		PS_ShopSearch_ClearPetList()
		for i = 1, 10 do
			local pName, pShopName, pShopID, pYB = PlayerShop:GetPetPSSearchInfo(i - 1)
			if pName ~= nil then
				local strHead = PlayerShop:GetPetPortraitByIndex(i - 1 , 0)
				local nEra = PlayerShop:GetPetEraCount(i - 1 , 0)
				if nEra == 1 then
					pName = "二代"..pName
				end
				PS_ShopSearch_InsertPetList(i, pName, pShopName, pShopID, pYB, strHead);
			end
		end
	elseif PS_nSelectTable == 3 then
	
		PS_ShopSearch_ItemInfoBk:Hide()
		PS_ShopSearch_DX_Text:Hide()
		PS_ShopSearch_DX:Hide()
		PS_ShopSearch_EquipInfoBk:Show()
		PS_ShopSearch_PetInfoBk:Hide()	
		PS_ShopSearch_InfantBk:Hide()
		PS_ClearEquipList()
		PS_ShopSearch_BieYeFurnitureInfoBk:Hide()
		
		for i = 1 ,10 do 
			local theAction = EnumAction( i - 1 , "playershop_cur_page")
			if theAction:GetID() ~= 0 then
				local pName , pShopName, pShopID ,pCount ,pYB = PlayerShop:GetItemPSInfo( i - 1 )			
				if pName ~= nil and pShopID ~= nil and pCount ~= nil and pYB ~= nil and pCount > 0 then
					PS_ShopSearch_InsertEquipList(i, pName, pShopName, pShopID,pCount, pYB)
					PS_ctrlEquipActions[i]:SetActionItem(theAction:GetID())
				end
			end
		end			
	elseif PS_nSelectTable == 4 then
	
		PS_ShopSearch_ItemInfoBk:Hide()
		PS_ShopSearch_DX_Text:Hide()
		PS_ShopSearch_DX:Hide()
		PS_ShopSearch_EquipInfoBk:Hide()
		PS_ShopSearch_PetInfoBk:Hide()	
		PS_ShopSearch_InfantBk:Show()
		PS_ShopSearch_BieYeFurnitureInfoBk:Hide()
		PS_ClearInfantCardList()
		
		
		for i = 1 ,10 do 
			local theAction = EnumAction( i - 1 , "playershop_cur_page")
			if theAction:GetID() ~= 0 then
				local pName , pShopName, pShopID ,pCount ,pYB = PlayerShop:GetItemPSInfo( i - 1 )			
				if pName ~= nil and pShopID ~= nil and pCount ~= nil and pYB ~= nil and pCount > 0 then
					PS_ShopSearch_InsertInfantCardList(i, pName, pShopName, pShopID,pCount, pYB)
					PS_ctrlInfantCardActions[i]:SetActionItem(theAction:GetID())
				end
			end
		end
	elseif PS_nSelectTable == PS_G_SEARCHTYPE_FURNITURE then
		PS_ShopSearch_ItemInfoBk:Hide()
		PS_ShopSearch_DX_Text:Hide()
		PS_ShopSearch_DX:Hide()
		PS_ShopSearch_EquipInfoBk:Hide()
		PS_ShopSearch_PetInfoBk:Hide()	
		PS_ShopSearch_InfantBk:Hide()
		PS_ShopSearch_BieYeFurnitureInfoBk:Show()		
		
		PS_ClearFurnitureList()
		
		for i = 1 ,10 do 
			local theAction = EnumAction( i - 1 , "playershop_cur_page")
			if theAction:GetID() ~= 0 then
				local pName , pShopName, pShopID ,pCount ,pYB = PlayerShop:GetItemPSInfo( i - 1 )			
				if pName ~= nil and pShopID ~= nil and pCount ~= nil and pYB ~= nil and pCount > 0 then
					PS_ShopSearch_InsertFurnitureList(i, pName, pShopName, pShopID,pCount, pYB)
					PS_ctrlFurnitureActions[i]:SetActionItem(theAction:GetID())
				end
			end
		end			
	end
	
	local strpage = curPage.."/"..totalPage
	PS_ShopSearch_lblSplitPage:SetText(strpage)
	
	PS_Page_Cur = curPage
	PS_Page_Total = totalPage
	
	if curPage == 1 or curPage == 0 then
		PS_ShopSearch_btnUpPage:Disable()
	end
	
	if curPage == totalPage then
		PS_ShopSearch_btnDownPage:Disable()
	end

	
end

function PS_ShopSearch_Show()

	PS_nSelectTable = 2
	PS_ShopSearch_ItemInfoBk:Show()
	PS_ShopSearch_DX_Text:Show()
	PS_ShopSearch_DX:Show()
	PS_ShopSearch_DX:SetCheck(0)
	PS_ItemCount_Select = 0
	for i = 1,10 do
		PS_ItemIndex_Select[i] = 0
	end
	PS_ShopSearch_EquipInfoBk:Hide()
	
	PS_ShopSearch_PetInfoBk:Hide();
	PS_ShopSearch_BieYeFurnitureInfoBk:Hide()
	
	PS_ShopSearch_SearchMode:ResetList()
	for i = 1, table.getn(PS_CboSearchItem) do
		PS_ShopSearch_SearchMode:AddTextItem(PS_CboSearchItem[i],i)
	end
	
	PS_ShopSearch_SearchMode:SetCurrentSelect(0)
	
	local str, nIndex = PS_ShopSearch_SearchMode:GetCurrentSelect()
	
	PS_nSearchOrder = nIndex
	
	PS_ShopSearch_ItemMode:ResetList()
	for i = 1, table.getn(PS_SearchTypeText) do
		PS_ShopSearch_ItemMode:AddTextItem(PS_SearchTypeText[i],i)
	end
	
	PS_ShopSearch_ItemMode:SetCurrentSelect(PS_nSelectTable - 1)
	
	for i = 1, table.getn(PS_ctrlItemFlash) do
		PS_ctrlItemFlash[i]:Hide()
	end
	
	PS_ShopSearch_ItemName:SetText("")
		
	PS_InitEquipListData()
	
	this:Show()
	
	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , "" , 1)
end

function PS_ShopSearch_Clicked()
		--测试数据
	local strKey = PS_ShopSearch_ItemName:GetText()
	
	--PS_ShopSearch_InitSelectSubType() 取消这个，否则先点排序后关键字会有问题

	
	-- PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , strKey , 1)
	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , strKey , 1)
end

function OnPS_ShopList_btnSubTypeClicked(index)
	    local realIdx = 0
		realIdx = PS_ctrlPetSubBtns[index].realIdx
		
		PS_nSelectSubType = realIdx
		
		PS_ShopSearch_ItemName:SetText("")
		PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , "" , 1)
	
end

function PS_ShopSearch_InitSelectSubType()
	if PS_nSelectTable == 3 then
		PS_nSelectSubType = 10101
	elseif PS_nSelectTable == 4 then
		PS_nSelectSubType = 10101
	elseif PS_nSelectTable == PS_G_SEARCHTYPE_FURNITURE then
		PS_nSelectSubType = 10101
	else
		PS_nSelectSubType = 1
	end
end

function PS_ShopSearch_SearchMode_Changed()
	local str, nIndex = PS_ShopSearch_SearchMode:GetCurrentSelect()
	
	PS_nSearchOrder = nIndex
	
	local strKey = PS_ShopSearch_ItemName:GetText()

	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , strKey , 1)
end

function PS_ShopSearch_ItemMode_Changed()
	local str, nIndex = PS_ShopSearch_ItemMode:GetCurrentSelect()
	
	--清空一下名称
	PS_ShopSearch_ItemName:SetText("")
	PS_nSelectTable = nIndex
	
	PS_ShopSearch_InitSelectSubType()
	
	if PS_nSelectTable == 3 then
		PS_ClearEquipList()
		PS_ChangeToEquipList( 1)
	elseif PS_nSelectTable == 1 then
		PS_ChangeToPetList( 1 )
	elseif PS_nSelectTable == 4 then
		PS_ClearInfantCardList()
		PS_ChangeToInfantCardList( 1)
	elseif PS_nSelectTable == PS_G_SEARCHTYPE_FURNITURE then
		PS_ClearFurnitureList()
		PS_ChangeToFurnitureList(1)
	
	end
	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , "" , 1)
	
	
end

function PS_InitEquipListData()
	PS_ShopSearch_EquipType1:ResetList()
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_86}", 1)	--全部
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_87}", 2)	--帽子
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_88}", 3)	--护肩
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_89}", 4)	--护腕
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_90}", 5)	--手套
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_91}", 6)	--腰带
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_92}", 7)	--鞋子
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_93}", 8)	--戒指
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_94}", 9)	--护符
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_95}", 10)	--武器
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_96}", 11)	--衣服
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_97}", 12)	--项链
	if Player:GetData("Is2606S") ~= 1 then
	PS_ShopSearch_EquipType1:AddTextItem("#{YBSC_XML_98}", 13)	--龙纹
	end
	PS_ShopSearch_EquipType1:AddTextItem("#{INTERFACE_XML_642}",14)
	PS_ShopSearch_EquipType1:AddTextItem("#{INTERFACE_XML_911}",15)
	PS_ShopSearch_EquipType1:AddTextItem("#{WBSS_120727_38}",16) --武魂
	PS_ShopSearch_EquipType1:AddTextItem("#{WBSS_120727_37}",17) --暗器
	
end

function PS_ClearEquipList()
	local i, j
	for i = 1, 10 do
		for j = 1, 3 do
			PS_ctrlEquipTexts[i][j]:SetText("")
		end
		PS_ctrlEquipTexts[i][4] : Hide()
		PS_ctrlEquipActions[i]:Hide()
	end
	
	for i = 1, table.getn(PS_ctrlEquipFlash) do
		PS_ctrlEquipFlash[i]:Hide()
	end
	
end

function PS_ClearInfantCardList()
	local i, j
	for i = 1, 10 do
		for j = 1, 3 do
			PS_ctrlInfantCardTexts[i][j]:SetText("")
		end
		PS_ctrlInfantCardTexts[i][4] : Hide()
		PS_ctrlInfantCardActions[i]:Hide()
	end
	
	for i = 1, table.getn(PS_ctrlInfantCardFlash) do
		PS_ctrlInfantCardFlash[i]:Hide()
	end
end


function PS_ClearFurnitureList()
	local i, j
	for i = 1, 10 do
		for j = 1, 4 do
			PS_ctrlFurnitureTexts[i][j]:SetText("")
		end
		PS_ctrlFurnitureTexts[i][5] : Hide()
		PS_ctrlFurnitureTexts[i][6] : Hide()
		PS_ctrlFurnitureActions[i]:Hide()
	end
	
	for i = 1, table.getn(PS_ctrlFurnitureFlash) do
		PS_ctrlFurnitureFlash[i]:Hide()
	end
end

function PS_ShopSearch_InsertEquipList(line, equipname, pShopName, pSeller, equipcount, prize)
	local i = line
	PS_ctrlEquipTexts[i][1]:SetText(equipname)
	PS_ctrlEquipTexts[i][2]:SetText(pShopName)
	PS_ctrlEquipTexts[i][3]:SetText(pSeller)
	-- PS_ctrlEquipTexts[i][4] : SetText(prize)
	PS_ctrlEquipTexts[i][4] : Show()
	PS_ctrlEquipTexts[i][4] : SetProperty("MoneyNumber", tostring(prize))
	PS_ctrlEquipActions[i]:Show()
end

function PS_ShopSearch_InsertInfantCardList(line, equipname, pShopName, pSeller, equipcount, prize)
	local i = line
	PS_ctrlInfantCardTexts[i][1]:SetText(equipname)
	PS_ctrlInfantCardTexts[i][2]:SetText(pShopName)
	PS_ctrlInfantCardTexts[i][3]:SetText(pSeller)
	-- PS_ctrlEquipTexts[i][4] : SetText(prize)
	PS_ctrlInfantCardTexts[i][4] : Show()
	PS_ctrlInfantCardTexts[i][4] : SetProperty("MoneyNumber", tostring(prize))
	PS_ctrlInfantCardActions[i]:Show()
end


function PS_ShopSearch_InsertFurnitureList(line, equipname, pShopName, pSeller, equipcount, prize)
	local i = line
	
	local perPrice = prize / equipcount
	if perPrice < 1 then
		perPrice = 1
	elseif perPrice > 200000000 then
		perPrice = 200000000
	end
	local itemPerYB = string.format("%d" , perPrice)
	
	PS_ctrlFurnitureTexts[i][1]:SetText(equipname)
	PS_ctrlFurnitureTexts[i][2]:SetText(pShopName)
	PS_ctrlFurnitureTexts[i][3]:SetText(pSeller)
	PS_ctrlFurnitureTexts[i][4]:SetText(equipcount)
	-- PS_ctrlEquipTexts[i][4] : SetText(prize)
	PS_ctrlFurnitureTexts[i][5] : Show()
	PS_ctrlFurnitureTexts[i][5] : SetProperty("MoneyNumber", tostring(itemPerYB))
	
	PS_ctrlFurnitureTexts[i][6] : Show()
	PS_ctrlFurnitureTexts[i][6] : SetProperty("MoneyNumber", tostring(prize))
	PS_ctrlFurnitureActions[i]:Show()
end
function PS_ShopSearch_InsertItemList(line, itemname,shopname,shopid , itemcount, itemYB)
	if itemcount <= 0 then
		return
	end
	
	local i = line
	local perPrice = itemYB / itemcount
	if perPrice < 1 then
		perPrice = 1
	elseif perPrice > 200000000 then
		perPrice = 200000000
	end
	local itemPerYB = string.format("%d" , perPrice)
	
	PS_ctrlItemTexts[i][1] : SetText(itemname)
	PS_ctrlItemTexts[i][2] : SetText(shopname)
	PS_ctrlItemTexts[i][3] : SetText(shopid)
	PS_ctrlItemTexts[i][4] : SetText(itemcount)
	
	-- PS_ctrlItemTexts[i][5] : SetText(itemPerYB)
	-- PS_ctrlItemTexts[i][6] : SetText(itemYB)
	PS_ctrlItemTexts[i][5] : Show()
	PS_ctrlItemTexts[i][6] : Show()

	PS_ctrlItemTexts[i][5] : SetProperty("MoneyNumber", tostring(itemPerYB))
	PS_ctrlItemTexts[i][6] : SetProperty("MoneyNumber", tostring(itemYB))
	PS_ctrlItemActions[i] : Show()
	PS_ctrlItemChecks[i] : Show()
	PS_ctrlItemChecks[i] : SetCheck(0)
end


function PS_ShopSearch_InsertPetList(line, petname, shopname, shopid, petprize,headStr)
	local i = line
	PS_ctrlPetTexts[i][1] : SetText(petname)
	PS_ctrlPetTexts[i][2] : SetText(shopname)
	PS_ctrlPetTexts[i][3] : SetText(shopid)
	-- PS_ctrlPetTexts[i][4] : SetText(petprize)
	PS_ctrlPetTexts[i][4] : Show()
	PS_ctrlPetTexts[i][4] : SetProperty("MoneyNumber", tostring(petprize))
	-- YbMarket_ctrlPetTexts[i][2] : SetText(petplayer)
	-- YbMarket_ctrlPetTexts[i][3] : SetText(petYB)
	-- YbMarket_PetViewBtn[i]:Show()
	-- YbMarket_ctrlPetActions[i] : Show()
	-- PS_ShopSearch_Pet1 : SetProperty("NormalImage", headStr)
	PS_ctrlPetActions[i] : Show()
	PS_ctrlPetActions[i] : SetProperty("NormalImage", headStr)
	PS_btnPetDetails[i] : Show()

	

end

-- 珍兽列表中， 查看按钮， 从1开始索引， 到10
function OnPS_ShopSearch_btnDetailClicked(index)
	if index > 0 and index <= 10 then
		PlayerShop:ShowPSCurPage_PetInfo(index - 1)
		--for i = 1 , 10 do
		--	YbMarket_ctrlPetActions[i]:SetPushed(0)
		--end
		--YbMarket_ctrlPetActions[index]:SetPushed(1)
		--YbMarket_Cur_Select = index
		
		-- OnYbMarket_AllBKClicked(index)
	end
end

function PS_ShopSearch_ClearItemList()
	local i, j
	for i =1, 10 do
		for j = 1, 4 do
			PS_ctrlItemTexts[i][j] : SetText("")
		end
		PS_ctrlItemTexts[i][5] : Hide()
		PS_ctrlItemTexts[i][6] : Hide()
		PS_ctrlItemActions[i] : Hide()
		PS_ctrlItemChecks[i] : Hide()
	end
	
	PS_ItemCount_Show = 0
	for i = 1,10 do
		PS_ItemIndex_Show[i] = 0
	end
		
	for i = 1, table.getn(PS_ctrlItemFlash) do
		PS_ctrlItemFlash[i]:Hide()
	end	
end

function PS_ShopSearch_ClearPetList()

	PS_ShopSearch_PetInfo:RemoveAllItem();
	local i, j
	for i =1, 10 do
		for j = 1, 3 do
			PS_ctrlPetTexts[i][j] : SetText("")
		end
		PS_ctrlPetTexts[i][4] : Hide()
		PS_ctrlPetActions[i] : Hide()
		PS_btnPetDetails[i]:Hide()
	end
	
	for i = 1, table.getn(PS_ctrlItemFlash) do
		PS_ctrlPetFlash[i]:Hide()
	end
end

--切换界面
function PS_ShopSearch_ChangeTabIndex(index)
	if index >= 0 and index < 3 then
		PushEvent("PS_OPEN_SHOPLIST", "PS_ShopSearch_Frame", tostring( index), PS_ShopSearch_Frame:GetProperty("UnifiedXPosition"), PS_ShopSearch_Frame:GetProperty("UnifiedYPosition"),-1)
		-- PushEvent("PS_OPEN_SHOPLIST")
	end
end

function PS_ShopSearch_Frame_OnHiden()
	PushEvent("CLOSE_CONFIRM_MULTIBUY", "PS_ShopSearch_Frame")
	this:Hide()
end

function OnPS_ShopList_btnUpPageClicked()
		local strKey = PS_ShopSearch_ItemName:GetText()
		PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , strKey , PS_Page_Cur - 1)
end
function OnPS_ShopList_btnDownPageClicked()
		local strKey = PS_ShopSearch_ItemName:GetText()
		PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , strKey , PS_Page_Cur + 1)

end

function OnPS_ShopSearch_AllBKClicked(index)
	if PS_nSelectTable == 1 then
		local pName, pShopName, pShopID, pPrize = PlayerShop:GetPetPSSearchInfo(index - 1)
		if pShopName == nil or pPrize == nil then
			return
		end
	else
		local pName ,pShopName, pShopID ,pCount ,pPrize = PlayerShop:GetItemPSInfo( index - 1 )
		if( pShopName == nil or pCount == nil or pPrize == nil ) then
			return
		end	
	end
	
	if PS_nSelectTable == 2 then--物品特写，后续代码不执行
		PS_ShopSearch_ItemCheck(index)	
		return
	end

	if PS_Cur_Select > 0 and PS_Cur_Select <= 10 then
		PS_ctrlItemFlash[PS_Cur_Select]:Hide()
		PS_ctrlPetFlash[PS_Cur_Select]:Hide()
		PS_ctrlEquipFlash[PS_Cur_Select]:Hide()
		PS_ctrlInfantCardFlash[PS_Cur_Select]:Hide()
		PS_ctrlFurnitureFlash[PS_Cur_Select]:Hide()
	end
	
	PS_Cur_Select = index
	
	if PS_nSelectTable == 2 then
		PS_ctrlItemFlash[index]:Show()
	elseif PS_nSelectTable == 1 then
		PS_ctrlPetFlash[index]:Show()
	elseif PS_nSelectTable == 4 then
		PS_ctrlInfantCardFlash[index]:Show()
	elseif PS_nSelectTable == PS_G_SEARCHTYPE_FURNITURE then
		PS_ctrlFurnitureFlash[index]:Show()
	else
		PS_ctrlEquipFlash[index]:Show()
		
	end
	
	
end


function OnPS_ShopList_btnBuyClicked()

	if PS_nSelectTable == 2 then--物品特写，后续代码不执行
		--物品选中
		if PS_ItemCount_Select <= 0 then
			PushDebugMessage("#{SHPLGM_150428_05}")--请选择您要购买的物品
			return
		end		
		--安全时间
		if ( tonumber( DataPool:GetLeftProtectTime() ) > 0 ) then
			PushDebugMessage( "#{SHPLGM_150428_06}" )
			return
		end
		--密保验证
		if ( CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 ) then
			return
		end
		--个数判断
		if PS_ItemCount_Select > 10 then
			PushDebugMessage("#{SHPLGM_150428_11}")--无法购买，每次最多只能购买10项物品
			return
		end	
		--只购买一件物品
		--if PS_ItemCount_Select == 1 then
			--local curSelect = 0
			--for i=1,10 do
				--if PS_ItemIndex_Select[i] == 1 then
					--curSelect = i
					--break
				--end
			--end
			--if curSelect <= 0 or curSelect > 10 then
				--PS_ItemCount_Select = 0
				--PS_ItemIndex_Select[curSelect] = 0
				--return
			--end
			--PlayerShop:SearchPageBuyItem(curSelect - 1, "item")
			--return
		--end	
		--购买多件物品
		for i=1,10 do
			PlayerShop:SetPageItemSelect(i-1, PS_ItemIndex_Select[i])
		end
		PlayerShop:SearchPageMultiBuyItem(0)
		return
	end


		
	if PS_nSelectTable == PS_G_SEARCHTYPE_FURNITURE then

		--物品选中
		if PS_Cur_Select <= 0 or PS_Cur_Select > 10 then
			PushDebugMessage("#{JZFUR_061101_13}")--请选择您要购买的物品
			return
		end		
		--安全时间
		if ( tonumber( DataPool:GetLeftProtectTime() ) > 0 ) then
			PushDebugMessage( "#{SHPLGM_150428_06}" )
			return
		end
		--密保验证
		if ( CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 ) then
			return
		end
		PushEvent("SHOPBUY_FURNITURE_CONFIRM", PS_Cur_Select)
		return
	end


	if PS_Cur_Select <= 0 or PS_Cur_Select > 10 then
		return
	end

	
	if PS_nSelectTable == 1 then	
		PlayerShop:SearchPageBuyItem(PS_Cur_Select - 1, "pet")
	else
		PlayerShop:SearchPageBuyItem(PS_Cur_Select - 1, "item")
	end
end

function PS_ShopSearch_btnGoClicked()

	--物品特写
	if PS_nSelectTable == 2 then
		if PS_ItemCount_Select ~= 1 then
			return
		else
			PS_Cur_Select = 0
			for i=1,10 do
				if PS_ItemIndex_Select[i] == 1 then
					PS_Cur_Select = i
					break
				end
			end
		end	
	end
		
	if PS_Cur_Select <= 0 or PS_Cur_Select > 10 then
		return
	end
	
	local pageindex = PS_ShopSearch_GetPageIndex(PS_nSelectTable);
	

	local shopid;
	
	if PS_nSelectTable == 1 then
		shopid = PS_ctrlPetTexts[PS_Cur_Select][3] : GetText()
	elseif PS_nSelectTable == 2 then
		shopid = PS_ctrlItemTexts[PS_Cur_Select][3] : GetText()
	elseif PS_nSelectTable == 3 then
		shopid = PS_ctrlEquipTexts[PS_Cur_Select][3] : GetText()
	elseif PS_nSelectTable == 4 then
		shopid = PS_ctrlInfantCardTexts[PS_Cur_Select][3] : GetText()
	elseif PS_nSelectTable == PS_G_SEARCHTYPE_FURNITURE then
		shopid = PS_ctrlFurnitureTexts[PS_Cur_Select][3] : GetText()
	end
	
	if shopid == nil or shopid =="" then
		return
	end
	if pageindex >= 0 and pageindex < 3 then
		PushEvent("PS_OPEN_SHOPLIST", "PS_ShopSearch_Frame", tostring( pageindex), PS_ShopSearch_Frame:GetProperty("UnifiedXPosition"), PS_ShopSearch_Frame:GetProperty("UnifiedYPosition"),tonumber(shopid))
		-- PushEvent("PS_OPEN_SHOPLIST")
	end
end

function PS_ShopSearch_GetPageIndex(nType)
	if nType == 1 then
		return 1
	elseif nType == 2 then
		return 0
	elseif nType == 3 then
		return 0
	elseif nType == 4 then
		return 0
	elseif nType == PS_G_SEARCHTYPE_FURNITURE then
		return 0
	end
end

function PS_ShopSearch_InfantCardType_Changed()
	
	local _, nEquipType1 = PS_ShopSearch_InfantBtn1:GetCurrentSelect()
	local _, nEquipType2 = PS_ShopSearch_InfantBtn2:GetCurrentSelect()
	local _, nEquipType3 = PS_ShopSearch_InfantBtn3:GetCurrentSelect()
	
	local nTempSubType = nEquipType1 * 10000 + nEquipType2 * 100 + nEquipType3
	if nTempSubType == PS_nSelectSubType then
		return
	end
	
	PS_nSelectSubType = nTempSubType
	PS_ClearInfantCardList()
	

	
	PS_ShopSearch_ItemName:SetText("")
	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , "" , 1)
	
end


function PS_ShopSearch_FurnitureType_ChangedMain()
	local _,nFurnitureType1 = PS_ShopSearch_BieYeFurnitureType1:GetCurrentSelect()
	local _,nFurnitureType2 = PS_ShopSearch_BieYeFurnitureType2:GetCurrentSelect()
	
	if nFurnitureType1 == 1 then
		PS_ShopSearch_BieYeFurnitureType1_1:ResetList()
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("全部",1)
		PS_ShopSearch_BieYeFurnitureType1_1:SetCurrentSelect(0)
		PS_ShopSearch_BieYeFurnitureType1_1:Disable()
		PS_ShopSearch_BieYeFurnitureType1_1_Pic:Show()
		PS_ShopSearch_BieYeFurnitureType1_1:Show()
	elseif nFurnitureType1 == 2 then
		PS_ShopSearch_BieYeFurnitureType1_1:ResetList()
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("全部",1)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_4}",2)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_5}",3)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_6}",4)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_7}",5)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_8}",6)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_9}",7)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_10}",8)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_11}",9)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_12}",10)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_13}",11)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_251}",12)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_295}",13)
		PS_ShopSearch_BieYeFurnitureType1_1:Enable()
		PS_ShopSearch_BieYeFurnitureType1_1_Pic:Hide()
		PS_ShopSearch_BieYeFurnitureType1_1:SetCurrentSelect(0)
		PS_ShopSearch_BieYeFurnitureType1_1:Show()
	
	elseif nFurnitureType1 == 3 then
		PS_ShopSearch_BieYeFurnitureType1_1:ResetList()
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("全部",1)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_14}",2)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_15}",3)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_16}",4)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_17}",5)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_18}",6)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_19}",7)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_20}",8)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_21}",9)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_22}",10)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_23}",11)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_24}",12)
		PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("#{BYFUR_160531_298}",13)
		PS_ShopSearch_BieYeFurnitureType1_1:Enable()
		PS_ShopSearch_BieYeFurnitureType1_1_Pic:Hide()		
		PS_ShopSearch_BieYeFurnitureType1_1:SetCurrentSelect(0)		
		PS_ShopSearch_BieYeFurnitureType1_1:Show()
	end
	
	
	local _,nFurnitureType3 = PS_ShopSearch_BieYeFurnitureType1_1:GetCurrentSelect()
	
	
	local nTempSubType = nFurnitureType1+nFurnitureType2*100+nFurnitureType3*10000
	if nTempSubType == PS_nSelectSubType then
		return
	end
	
	PS_nSelectSubType = nTempSubType
	PS_ClearFurnitureList()
	
	PS_ShopSearch_ItemName:SetText("")
	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , "" , 1)

end

function PS_ShopSearch_FurnitureType_Changed()

	local _,nFurnitureType1 = PS_ShopSearch_BieYeFurnitureType1:GetCurrentSelect()
	local _,nFurnitureType2 = PS_ShopSearch_BieYeFurnitureType2:GetCurrentSelect()
	local _,nFurnitureType3 = PS_ShopSearch_BieYeFurnitureType1_1:GetCurrentSelect()

	
	local nTempSubType = nFurnitureType1+nFurnitureType2*100+nFurnitureType3*10000
	if nTempSubType == PS_nSelectSubType then
		return
	end
	
	PS_nSelectSubType = nTempSubType
	PS_ClearFurnitureList()
	
	PS_ShopSearch_ItemName:SetText("")
	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , "" , 1)
	
end

function PS_ShopSearch_EquipType_Changed()
	
	local _, nEquipType1 = PS_ShopSearch_EquipType1:GetCurrentSelect()
	local _, nEquipType2 = PS_ShopSearch_EquipType2:GetCurrentSelect()
	local _, nEquipType3 = PS_ShopSearch_EquipType3:GetCurrentSelect()
	
	if PS_EquipTypeTrans[nEquipType1] == nil then
		return
	end
	
	nEquipType1 = PS_EquipTypeTrans[nEquipType1]
	
	local nTempSubType = nEquipType1 * 10000 + nEquipType2 * 100 + nEquipType3
	if nTempSubType == PS_nSelectSubType then
		return
	end
	
	-- local isCanDo = Auction:IsYBMarketCanSwitchPage()
	-- if isCanDo == 0 then
		-- nEquipType1 = math.floor(PS_nSelectSubType / 10000)
		-- nEquipType2 = math.mod(math.floor(PS_nSelectSubType/100), 100)
		-- nEquipType3 = math.mod(PS_nSelectSubType, 100)
		
		-- 这里nEquipType1是转换过的，需转回来
		-- local idx
		-- for i = 1, table.getn(PS_EquipTypeTrans) do
			-- if PS_EquipTypeTrans[i] == nEquipType1 then
				-- idx = i
				-- break
			-- end
		-- end
		-- PS_ShopSearch_EquipType1:SetCurrentSelect(idx-1)
		-- PS_ShopSearch_EquipType2:SetCurrentSelect(nEquipType2-1)
		-- PS_ShopSearch_EquipType3:SetCurrentSelect(nEquipType3-1)
		-- PushDebugMessage("#{YBSC_100111_40}")
		-- return
	-- end	
	
	PS_nSelectSubType = nTempSubType
	PS_ClearEquipList()
	

	
	PS_ShopSearch_ItemName:SetText("")
	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType,PS_nSearchOrder , "" , 1)
	
end


function PS_ShopSearch_btnReset_Clicked()
	--使用元宝交易市场的
	local isCanDo = Auction:IsYBMarketCanSwitchPage()
	if isCanDo == 0 then
		PushDebugMessage("#{YBSC_100111_40}")
		return
	end
	
	PS_nSearchOrder = 1
	PS_ShopSearch_SearchMode:SetCurrentSelect(0)
	PS_ShopSearch_ItemName:SetText("")
	
	if PS_nSelectTable == 2 then
		PS_nSelectSubType = 1
		PS_ShopSearch_ClearItemList()
		PS_ChangeToItemList( 1 )
	elseif PS_nSelectTable == 1 then
		PS_nSelectSubType = 1
		PS_ShopSearch_ClearPetList()
		PS_ChangeToPetList( 1 )
	elseif PS_nSelectTable == 4 then
		PS_nSelectSubType = 10101
		PS_ClearInfantCardList()
		PS_ChangeToInfantCardList( 1 )
	elseif PS_nSelectTable == PS_G_SEARCHTYPE_FURNITURE then
		PS_nSelectSubType = 10101
		PS_ClearFurnitureList();
		PS_ChangeToFurnitureList(1)
	else
		PS_nSelectSubType = 10101
		PS_ClearEquipList()
		PS_ChangeToEquipList( 1 )
	end
	
	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType , PS_nSearchOrder , "" , 1)

	
end


function PS_ChangeToItemList(isNeedResetSortMode)
	PS_ShopSearch_ItemInfoBk:Show()
	PS_ShopSearch_DX_Text:Show()
	PS_ShopSearch_DX:Show()
	PS_ShopSearch_DX:SetCheck(0)
	PS_ItemCount_Select = 0
	for i = 1,10 do
		PS_ItemIndex_Select[i] = 0
	end
	PS_ShopSearch_EquipInfoBk:Hide()
	PS_ShopSearch_PetInfoBk:Hide()
	PS_ShopSearch_InfantBk:Hide()
	PS_ShopSearch_BieYeFurnitureInfoBk:Hide()
	-- PS_HideAndInitAllSubButton()
	-- PS_ShowItemSubButton( isNeedResetSortMode )
	
end

function PS_ChangeToPetList(isNeedResetSortMode)
		PS_ShopSearch_ItemInfoBk:Hide()
		PS_ShopSearch_DX_Text:Hide()
		PS_ShopSearch_DX:Hide()
		PS_ShopSearch_EquipInfoBk:Hide()
		PS_ShopSearch_PetInfoBk:Show()
		PS_ShopSearch_InfantBk:Hide()
		PS_ShopSearch_BieYeFurnitureInfoBk:Hide()
		PS_ShowPetSubButton( isNeedResetSortMode )
end


function PS_ChangeToEquipList(isNeedResetSortMode)
		PS_ShopSearch_ItemInfoBk:Hide()
		PS_ShopSearch_DX_Text:Hide()
		PS_ShopSearch_DX:Hide()
		PS_ShopSearch_EquipInfoBk:Show()
		PS_ShopSearch_PetInfoBk:Hide()	
		PS_ShopSearch_InfantBk:Hide()
		PS_ShopSearch_BieYeFurnitureInfoBk:Hide()
		PS_ShowEquipSubButton( isNeedResetSortMode )
end

function PS_ShowEquipSubButton(isNeedResetSortMode)
	PS_ShopSearch_EquipType1:SetCurrentSelect(0)
	PS_ShopSearch_EquipType2:SetCurrentSelect(0)
	PS_ShopSearch_EquipType3:SetCurrentSelect(0)
end

function PS_ChangeToInfantCardList(isNeedResetSortMode)
		PS_ShopSearch_ItemInfoBk:Hide()
		PS_ShopSearch_DX_Text:Hide()
		PS_ShopSearch_DX:Hide()
		PS_ShopSearch_EquipInfoBk:Hide()
		PS_ShopSearch_PetInfoBk:Hide()	
		PS_ShopSearch_InfantBk:Show()
		PS_ShopSearch_BieYeFurnitureInfoBk:Hide()
		PS_ShowInfantCardSubButton( isNeedResetSortMode )
end

function PS_ChangeToFurnitureList(isNeedResetSortMode)
		PS_ShopSearch_ItemInfoBk:Hide()
		PS_ShopSearch_DX_Text:Hide()
		PS_ShopSearch_DX:Hide()
		PS_ShopSearch_EquipInfoBk:Hide()
		PS_ShopSearch_PetInfoBk:Hide()	
		PS_ShopSearch_InfantBk:Hide()
		PS_ShopSearch_BieYeFurnitureInfoBk:Show()
		
		
		PS_ShowFurnitureSubButton( isNeedResetSortMode )
		
		
end

function PS_ShowInfantCardSubButton(isNeedResetSortMode)
	PS_ShopSearch_InfantBtn1:SetCurrentSelect(0)
	PS_ShopSearch_InfantBtn2:SetCurrentSelect(0)
	PS_ShopSearch_InfantBtn3:SetCurrentSelect(0)
end

function PS_ShowFurnitureSubButton(isNeedResetSortMode)
	PS_ShopSearch_BieYeFurnitureType1:SetCurrentSelect(0)
	PS_ShopSearch_BieYeFurnitureType1_1:ResetList()
	PS_ShopSearch_BieYeFurnitureType1_1:AddTextItem("全部",1)
	PS_ShopSearch_BieYeFurnitureType1_1:SetCurrentSelect(0)
	PS_ShopSearch_BieYeFurnitureType1_1:Show()
	PS_ShopSearch_BieYeFurnitureType1_1:Disable()
	PS_ShopSearch_BieYeFurnitureType1_1_Pic:Show()
	PS_ShopSearch_BieYeFurnitureType2:SetCurrentSelect(0)
end

function PS_ShowPetSubButton(isNeedResetSortMode)
    if isNeedResetSortMode == 0 then
        return
    end
	
	for i = 1, table.getn(PS_ctrlPetSubBtns) do
		PS_ctrlPetSubBtns[i].ctrl : SetCheck(0)
	end	
	
end

function OnPS_ShopList_btnGotoPageClicked()

	PS_ShopSearch_ClearItemList()
	PS_ShopSearch_ClearPetList()
	PS_ClearEquipList()
	
	local strKey = PS_ShopSearch_ItemName:GetText()
	
	local pageNum = PS_ShopSearch_txtPage:GetText()
	if pageNum == nil or pageNum == "" then
		pageNum = 1
	end
	
	PlayerShop:PacketSend_Search(PS_nSelectTable , PS_nSelectSubType , PS_nSearchOrder , strKey , tonumber(pageNum))
	
end

function PS_ShopSearch_ItemCheck(index)
	if index < 1 or index > 10 then
		return
	end
	
	--判断当前选中状态
	local bCheck = PS_ItemIndex_Select[index]
	if bCheck == 1 then--已经选中的取消选中
		PS_ctrlItemFlash[index]:Hide()
		PS_ctrlItemChecks[index] : SetCheck(0)--取消选中
		PS_ItemIndex_Select[index] = 0
		PS_ItemCount_Select = PS_ItemCount_Select - 1--数量自减
		if PS_ItemCount_Select <= 1 then--单选的情况
			PS_ShopSearch_btnGo : Enable()--启用前往店铺
		else
			PS_ShopSearch_btnGo : Disable()--禁用前往店铺
		end
		if PS_ItemCount_Select ~= PS_ItemCount_Show then--不满足勾选上限
			PS_ShopSearch_DX:SetCheck(0)--取消全选
		end
	else	--未选中的进入勾选逻辑
		if PS_ItemCount_Select >= 10 then--超过勾选上限
			PushDebugMessage("#{SHPLGM_150428_01}")--勾选已达上限，每次最多可勾选10项物品。
			return
		else--可以选中
			PS_ctrlItemFlash[index]:Show()
			PS_ctrlItemChecks[index] : SetCheck(1)--选中
			PS_ItemIndex_Select[index] = 1
			PS_ItemCount_Select = PS_ItemCount_Select + 1--数量自增
			if PS_ItemCount_Select <= 1 then--单选的情况
				PS_ShopSearch_btnGo : Enable()--启用前往店铺
			else
				PS_ShopSearch_btnGo : Disable()--禁用前往店铺
			end
			if PS_ItemCount_Select == PS_ItemCount_Show then--达到勾选上限
				PS_ShopSearch_DX:SetCheck(1)--选中全选
			end
		end
	end
end

function OnPS_ShopSearch_ItemCheckAll()

	local bCheck = PS_ShopSearch_DX : GetCheck()
	if bCheck == 1 then--已经选中的取消选中
		--PS_ShopSearch_DX : SetCheck(0)--取消选中
		PS_ShopSearch_btnGo : Enable()--启用前往店铺
		PS_ItemCount_Select = 0--数量清空		
		for i=1,10 do--全部取消选中
			if PS_ItemIndex_Show[i] == 1 and PS_ItemIndex_Select[i] == 1 then
				PS_ctrlItemFlash[i] : Hide()
				PS_ctrlItemChecks[i] : SetCheck(0)--选中
				PS_ItemIndex_Select[i] = 0
			end
		end
	else	--未选中的进入勾选逻辑
		if PS_ItemCount_Show > 10 then--超过勾选上限
			PushDebugMessage("#{SHPLGM_150428_01}")--勾选已达上限，每次最多可勾选10项物品。
			return
		else--可以选中
			--PS_ShopSearch_DX : SetCheck(1)--选中全选
			PS_ShopSearch_btnGo : Disable()--禁用前往店铺
			PS_ItemCount_Select = PS_ItemCount_Show--数量设置
			for i=1,10 do--全部选中
				if PS_ItemIndex_Show[i] == 1 and PS_ItemIndex_Select[i] ~= 1 then
					PS_ctrlItemFlash[i] : Show()
					PS_ctrlItemChecks[i] : SetCheck(1)--选中
					PS_ItemIndex_Select[i] = 1
				end
			end
		end
	end
	
end

function PS_ShopSearch_ItemCheckClear()
	PS_ShopSearch_DX:SetCheck(0)--取消全选
		
	PS_ShopSearch_btnGo : Enable()--启用前往店铺
	PS_ItemCount_Select = 0--数量清空		
	for i=1,10 do--全部取消选中
		if PS_ItemIndex_Show[i] == 1 and PS_ItemIndex_Select[i] == 1 then
			PS_ctrlItemFlash[i] : Hide()
			PS_ctrlItemChecks[i] : SetCheck(0)--选中
			PS_ItemIndex_Select[i] = 0
		end
	end
	
	for i=1,10 do
		PlayerShop:SetPageItemSelect(i-1, 0)
	end
end
