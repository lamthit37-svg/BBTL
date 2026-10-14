
-- [ QUFEI 2007-10-15 15:31 UPDATE BugID 26358 ]

local EQUIP_BUTTONS;
local EQUIP_QUALITY = -1;
local Need_Item = 0
local Need_Money =0
local Need_Item_Count = 0
local Bore_Count=0
local g_objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local g_targetId = -1
local g_sel_price = -1

local g_nTotalPrice = 0
local g_nRepairLine = 0

local g_repair_type = 0
--0武器 1神器 2武魂

local EQUIP_SHENQI_BEGIN = 10300000
local EQUIP_SHENQI_END = 10399999
local g_SaveEquip = -1

local g_VIP_EquipRepair_SuperWeaponStartUpCommandList = 
{
	201208094, 201208093, 201208092, 201208091, 201208098
}

local g_VIP_EquipRepair_Frame_UnifiedPosition;
local EQUIP_ACTIONBUTTON ={}
local EQUIP_MASKBUTTON={}
local EQUIP_ANIMATEBTN={}
local g_ValidEquipPos={
1,15,14,3,5,4,6,11,12,13,
0,2,7,21,19,20,18
}
local g_CurSelect=-1


local ShenQi_BUTTONS;
local CaiLiao_BUTTONS;
local ShenQi_QUALITY = -1;
local CaiLiao_QUALITY = -1;


local Wuhun_BUTTONS;
local WuhunCailiao_BUTTONS;
local Wuhun_ID = -1;
local WuhunCailiao_ID = -1;

local needMoney;

local INDEX_Yanshoudan = 30700233 --延寿丹

local ShenQi_PARA_PRICE = -1

local shenfuid = 0
local shenfu_grade = -1

local g_VIP_EquipRepair_YuanBaoPay = 1

local g_VIP_MaxNum = 20;
local g_Object = -1;

local TimesLeftTips = {}

local PageList = {}
local g_nComfirmParam1 = -1
local g_nComfirmParam2 = -1
local g_nComfirmParam3 = -1
local g_bQuickRepair = 0

local g_NeedItemBonus={	{sqid01=10300000, sqid02=10302000, sqid03=10304000, sqid04=10305000, sfid=30505800},
			{sqid01=10300001, sqid02=10302001, sqid03=10304001, sqid04=10305001, sfid=30505801},
			{sqid01=10300002, sqid02=10302002, sqid03=10304002, sqid04=10305002, sfid=30505802},
			{sqid01=10300003, sqid02=10302003, sqid03=10304003, sqid04=10305003, sfid=30505803},
			{sqid01=10300004, sqid02=10302004, sqid03=10304004, sqid04=10305004, sfid=30505804},
			{sqid01=10300005, sqid02=10302005, sqid03=10304005, sqid04=10305005, sfid=30505805},
			{sqid01=10300100, sqid02=10300100, sqid03=10300100, sqid04=10300100, sfid=30505806},		-- 褚少微
			{sqid01=10300101, sqid02=10300101, sqid03=10300101, sqid04=10300101, sfid=30505806},
			{sqid01=10300102, sqid02=10300102, sqid03=10300102, sqid04=10300102, sfid=30505806},
			{sqid01=10301100, sqid02=10301100, sqid03=10301100, sqid04=10301100, sfid=30505806},
			{sqid01=10301101, sqid02=10301101, sqid03=10301101, sqid04=10301101, sfid=30505806},
			{sqid01=10301102, sqid02=10301102, sqid03=10301102, sqid04=10301102, sfid=30505806},
			{sqid01=10301200, sqid02=10301200, sqid03=10301200, sqid04=10301200, sfid=30505806},
			{sqid01=10301201, sqid02=10301201, sqid03=10301201, sqid04=10301201, sfid=30505806},
			{sqid01=10301202, sqid02=10301202, sqid03=10301202, sqid04=10301202, sfid=30505806},
			{sqid01=10302100, sqid02=10302100, sqid03=10302100, sqid04=10302100, sfid=30505806},
			{sqid01=10302101, sqid02=10302101, sqid03=10302101, sqid04=10302101, sfid=30505806},
			{sqid01=10302102, sqid02=10302102, sqid03=10302102, sqid04=10302102, sfid=30505806},
			{sqid01=10303100, sqid02=10303100, sqid03=10303100, sqid04=10303100, sfid=30505806},
			{sqid01=10303101, sqid02=10303101, sqid03=10303101, sqid04=10303101, sfid=30505806},
			{sqid01=10303102, sqid02=10303102, sqid03=10303102, sqid04=10303102, sfid=30505806},
			{sqid01=10303200, sqid02=10303200, sqid03=10303200, sqid04=10303200, sfid=30505806},
			{sqid01=10303201, sqid02=10303201, sqid03=10303201, sqid04=10303201, sfid=30505806},
			{sqid01=10303202, sqid02=10303202, sqid03=10303202, sqid04=10303202, sfid=30505806},
			{sqid01=10304100, sqid02=10304100, sqid03=10304100, sqid04=10304100, sfid=30505806},
			{sqid01=10304101, sqid02=10304101, sqid03=10304101, sqid04=10304101, sfid=30505806},
			{sqid01=10304102, sqid02=10304102, sqid03=10304102, sqid04=10304102, sfid=30505806},
			{sqid01=10305100, sqid02=10305100, sqid03=10305100, sqid04=10305100, sfid=30505806},
			{sqid01=10305101, sqid02=10305101, sqid03=10305101, sqid04=10305101, sfid=30505806},
			{sqid01=10305102, sqid02=10305102, sqid03=10305102, sqid04=10305102, sfid=30505806},
			{sqid01=10305200, sqid02=10305200, sqid03=10305200, sqid04=10305200, sfid=30505806},
			{sqid01=10305201, sqid02=10305201, sqid03=10305201, sqid04=10305201, sfid=30505806},
			{sqid01=10305202, sqid02=10305202, sqid03=10305202, sqid04=10305202, sfid=30505806},
			--86级新神器
			{sqid01=10300006, sqid02=10301000, sqid03=10301198, sqid04=10302006, sfid=30505804},
			{sqid01=10302008, sqid02=10303000, sqid03=10304006, sqid04=10305006, sfid=30505804},
			{sqid01=10305008, sqid02=10304008, sqid03=10302010, sqid04=10304008, sfid=30505804},
			--新增86神器（升星）
			{sqid01=10300400, sqid02=10301400, sqid03=10301401, sqid04=10302400, sfid=30505804},
			{sqid01=10302401, sqid02=10302402, sqid03=10303400, sqid04=10304400, sfid=30505804},
			{sqid01=10304401, sqid02=10305400, sqid03=10305401, sqid04=10300401, sfid=30505804},
			{sqid01=10301402, sqid02=10301403, sqid03=10302403, sqid04=10302404, sfid=30505804},
			{sqid01=10302405, sqid02=10303401, sqid03=10304402, sqid04=10304403, sfid=30505804},
			{sqid01=10305402, sqid02=10305403, sqid03=10302405, sqid04=10301403, sfid=30505804},
			--96级新神器
			{sqid01=10300007, sqid02=10301001, sqid03=10301199, sqid04=10302007, sfid=30505805},
			{sqid01=10302009, sqid02=10303001, sqid03=10304007, sqid04=10305007, sfid=30505805},
			{sqid01=10305009, sqid02=10304009, sqid03=10302011, sqid04=10304009, sfid=30505805},
			--新增96神器（升星）
			{sqid01=10300402, sqid02=10301404, sqid03=10301405, sqid04=10302406, sfid=30505805},
			{sqid01=10302407, sqid02=10302408, sqid03=10303402, sqid04=10304404, sfid=30505805},
			{sqid01=10304405, sqid02=10305404, sqid03=10305405, sqid04=10300403, sfid=30505805},
			{sqid01=10301406, sqid02=10301407, sqid03=10302409, sqid04=10302410, sfid=30505805},
			{sqid01=10302411, sqid02=10303403, sqid03=10304406, sqid04=10304407, sfid=30505805},
			{sqid01=10305406, sqid02=10305407, sqid03=10304406, sqid04=10305405, sfid=30505805},
			--102级新神器
			{sqid01=10300103, sqid02=10300104, sqid03=10300105, sqid04=10300106, sfid=30505806},
			{sqid01=10300107, sqid02=10300108, sqid03=10300109, sqid04=10300110, sfid=30505806},
			{sqid01=10300111, sqid02=10301103, sqid03=10301104, sqid04=10301105, sfid=30505806},
			{sqid01=10301106, sqid02=10301107, sqid03=10301108, sqid04=10301109, sfid=30505806},
			{sqid01=10301110, sqid02=10301111, sqid03=10301203, sqid04=10301204, sfid=30505806},
			{sqid01=10301205, sqid02=10301206, sqid03=10301207, sqid04=10301208, sfid=30505806},
			{sqid01=10301209, sqid02=10301210, sqid03=10301211, sqid04=10302103, sfid=30505806},
			{sqid01=10302104, sqid02=10302105, sqid03=10302106, sqid04=10302107, sfid=30505806},
			{sqid01=10302108, sqid02=10302109, sqid03=10302110, sqid04=10302111, sfid=30505806},
			{sqid01=10303103, sqid02=10303104, sqid03=10303105, sqid04=10303106, sfid=30505806},
			{sqid01=10303107, sqid02=10303108, sqid03=10303109, sqid04=10303110, sfid=30505806},
			{sqid01=10303111, sqid02=10303203, sqid03=10303204, sqid04=10303205, sfid=30505806},
			{sqid01=10303206, sqid02=10303207, sqid03=10303208, sqid04=10303209, sfid=30505806},
			{sqid01=10303210, sqid02=10303211, sqid03=10304103, sqid04=10304104, sfid=30505806},
			{sqid01=10304105, sqid02=10304106, sqid03=10304107, sqid04=10304108, sfid=30505806},
			{sqid01=10304109, sqid02=10304110, sqid03=10304111, sqid04=10305103, sfid=30505806},
			{sqid01=10305104, sqid02=10305105, sqid03=10305106, sqid04=10305107, sfid=30505806},
			{sqid01=10305108, sqid02=10305109, sqid03=10305110, sqid04=10305111, sfid=30505806},
			{sqid01=10305203, sqid02=10305204, sqid03=10305205, sqid04=10305206, sfid=30505806},
			{sqid01=10305207, sqid02=10305208, sqid03=10305209, sqid04=10305210, sfid=30505806},
			{sqid01=10305211, sqid02=10302200, sqid03=10302201, sqid04=10302202, sfid=30505806},
  			{sqid01=10302203, sqid02=10302204, sqid03=10302205, sqid04=10302206, sfid=30505806},
			{sqid01=10302207, sqid02=10302208, sqid03=10302209, sqid04=10302210, sfid=30505806},
			{sqid01=10302211, sqid02=10302211, sqid03=10302211, sqid04=10302211, sfid=30505806},
			--	新增神器
			{sqid01=10300404, sqid02=10300405, sqid03=10300406, sqid04=10300407, sfid=30505806},
			{sqid01=10300408, sqid02=10300409, sqid03=10300410, sqid04=10300411, sfid=30505806},
			{sqid01=10300412, sqid02=10301408, sqid03=10301409, sqid04=10301410, sfid=30505806},
			{sqid01=10301411, sqid02=10301412, sqid03=10301413, sqid04=10301414, sfid=30505806},
			{sqid01=10301415, sqid02=10301416, sqid03=10301417, sqid04=10301418, sfid=30505806},
			{sqid01=10301419, sqid02=10301420, sqid03=10301421, sqid04=10301422, sfid=30505806},
			{sqid01=10301423, sqid02=10301424, sqid03=10301425, sqid04=10302412, sfid=30505806},
			{sqid01=10302413, sqid02=10302414, sqid03=10302415, sqid04=10302416, sfid=30505806},
			{sqid01=10302417, sqid02=10302418, sqid03=10302419, sqid04=10302420, sfid=30505806},
			{sqid01=10302421, sqid02=10302422, sqid03=10302423, sqid04=10302424, sfid=30505806},
			{sqid01=10302425, sqid02=10302426, sqid03=10302427, sqid04=10302428, sfid=30505806},
			{sqid01=10302429, sqid02=10303404, sqid03=10303405, sqid04=10303406, sfid=30505806},
			{sqid01=10303407, sqid02=10303408, sqid03=10303409, sqid04=10303410, sfid=30505806},
			{sqid01=10303411, sqid02=10303412, sqid03=10303413, sqid04=10303414, sfid=30505806},
			{sqid01=10303415, sqid02=10303416, sqid03=10303417, sqid04=10303418, sfid=30505806},
			{sqid01=10303419, sqid02=10303420, sqid03=10303421, sqid04=10304408, sfid=30505806},
			{sqid01=10304409, sqid02=10304410, sqid03=10304411, sqid04=10304412, sfid=30505806},
			{sqid01=10304413, sqid02=10304414, sqid03=10304415, sqid04=10304416, sfid=30505806},
			{sqid01=10305408, sqid02=10305409, sqid03=10305410, sqid04=10305411, sfid=30505806},
			{sqid01=10305412, sqid02=10305413, sqid03=10305414, sqid04=10305415, sfid=30505806},
			{sqid01=10305416, sqid02=10305417, sqid03=10305418, sqid04=10305419, sfid=30505806},
			{sqid01=10305420, sqid02=10305421, sqid03=10305422, sqid04=10305423, sfid=30505806},
			{sqid01=10305424, sqid02=10305425, sqid03=10300413, sqid04=10300414, sfid=30505806},
			{sqid01=10300415, sqid02=10300416, sqid03=10300417, sqid04=10300418, sfid=30505806},
			{sqid01=10300419, sqid02=10300420, sqid03=10300421, sqid04=10301426, sfid=30505806},
			{sqid01=10301427, sqid02=10301428, sqid03=10301429, sqid04=10301430, sfid=30505806},
			{sqid01=10301431, sqid02=10301432, sqid03=10301433, sqid04=10301434, sfid=30505806},
			{sqid01=10301435, sqid02=10301436, sqid03=10301437, sqid04=10301438, sfid=30505806},
			{sqid01=10301439, sqid02=10301440, sqid03=10301441, sqid04=10301442, sfid=30505806},
			{sqid01=10301443, sqid02=10302430, sqid03=10302431, sqid04=10302432, sfid=30505806},
			{sqid01=10302433, sqid02=10302434, sqid03=10302435, sqid04=10302436, sfid=30505806},
			{sqid01=10302437, sqid02=10302438, sqid03=10302439, sqid04=10302440, sfid=30505806},
			{sqid01=10302441, sqid02=10302442, sqid03=10302443, sqid04=10302444, sfid=30505806},
			{sqid01=10302445, sqid02=10302446, sqid03=10302447, sqid04=10303422, sfid=30505806},
			{sqid01=10303423, sqid02=10303424, sqid03=10303425, sqid04=10303426, sfid=30505806},
			{sqid01=10303427, sqid02=10303428, sqid03=10303429, sqid04=10303430, sfid=30505806},
			{sqid01=10303431, sqid02=10303432, sqid03=10303433, sqid04=10303434, sfid=30505806},
			{sqid01=10303435, sqid02=10303436, sqid03=10303437, sqid04=10303438, sfid=30505806},
			{sqid01=10303439, sqid02=10304417, sqid03=10304418, sqid04=10304419, sfid=30505806},
			{sqid01=10304420, sqid02=10304421, sqid03=10304422, sqid04=10304423, sfid=30505806},
			{sqid01=10304424, sqid02=10304425, sqid03=10305426, sqid04=10305427, sfid=30505806},
			{sqid01=10305428, sqid02=10305429, sqid03=10305430, sqid04=10305431, sfid=30505806},
			{sqid01=10305432, sqid02=10305433, sqid03=10305434, sqid04=10305435, sfid=30505806},
			{sqid01=10305436, sqid02=10305437, sqid03=10305438, sqid04=10305439, sfid=30505806},
			{sqid01=10305440, sqid02=10305441, sqid03=10305442, sqid04=10305443, sfid=30505806},
			--新门派神器
			{sqid01=10306000, sqid02=10306000, sqid03=10306000, sqid04=10306000, sfid=30505800},
			{sqid01=10306001, sqid02=10306001, sqid03=10306001, sqid04=10306001, sfid=30505801},
			{sqid01=10306002, sqid02=10306002, sqid03=10306002, sqid04=10306002, sfid=30505802},
			{sqid01=10306003, sqid02=10306003, sqid03=10306003, sqid04=10306003, sfid=30505803},
			{sqid01=10306004, sqid02=10306006, sqid03=10306008, sqid04=10306010, sfid=30505804},
			{sqid01=10306005, sqid02=10306007, sqid03=10306009, sqid04=10306011, sfid=30505805},
			{sqid01=10306012, sqid02=10306013, sqid03=10306014, sqid04=10306012, sfid=30505806},
			{sqid01=10306015, sqid02=10306016, sqid03=10306017, sqid04=10306018, sfid=30505806},
			{sqid01=10306019, sqid02=10306020, sqid03=10306021, sqid04=10306022, sfid=30505806},
			{sqid01=10306023, sqid02=10306023, sqid03=10306023, sqid04=10306023, sfid=30505806},
			{sqid01=10306024, sqid02=10306025, sqid03=10306026, sqid04=10306027, sfid=30505806},
			{sqid01=10306028, sqid02=10306029, sqid03=10306030, sqid04=10306031, sfid=30505806},
			{sqid01=10306032, sqid02=10306033, sqid03=10306034, sqid04=10306035, sfid=30505806},
			{sqid01=10306036, sqid02=10306037, sqid03=10306038, sqid04=10306039, sfid=30505806},
			{sqid01=10306040, sqid02=10306041, sqid03=10306041, sqid04=10306041, sfid=30505806},
			
			--新门派神器鬼谷
			{sqid01=10307000, sqid02=10307000, sqid03=10307000, sqid04=10307000, sfid=30505800},
			{sqid01=10307001, sqid02=10307001, sqid03=10307001, sqid04=10307001, sfid=30505801},
			{sqid01=10307002, sqid02=10307002, sqid03=10307002, sqid04=10307002, sfid=30505802},
			{sqid01=10307003, sqid02=10307003, sqid03=10307003, sqid04=10307003, sfid=30505803},
			{sqid01=10307004, sqid02=10307006, sqid03=10307008, sqid04=10307010, sfid=30505804},
			{sqid01=10307005, sqid02=10307007, sqid03=10307009, sqid04=10307011, sfid=30505805},
			{sqid01=10307012, sqid02=10307013, sqid03=10307014, sqid04=10307012, sfid=30505806},
			{sqid01=10307015, sqid02=10307016, sqid03=10307017, sqid04=10307018, sfid=30505806},
			{sqid01=10307019, sqid02=10307020, sqid03=10307021, sqid04=10307022, sfid=30505806},
			{sqid01=10307023, sqid02=10307023, sqid03=10307023, sqid04=10307023, sfid=30505806},
			{sqid01=10307024, sqid02=10307025, sqid03=10307026, sqid04=10307027, sfid=30505806},
			{sqid01=10307028, sqid02=10307029, sqid03=10307030, sqid04=10307031, sfid=30505806},
			{sqid01=10307032, sqid02=10307033, sqid03=10307034, sqid04=10307035, sfid=30505806},
			{sqid01=10307036, sqid02=10307037, sqid03=10307038, sqid04=10307039, sfid=30505806},
			{sqid01=10307040, sqid02=10307041, sqid03=10307041, sqid04=10307041, sfid=30505806},
			
			--新门派神器桃花岛
			{sqid01=10308000, sqid02=10308000, sqid03=10308000, sqid04=10308000, sfid=30505800},
			{sqid01=10308001, sqid02=10308001, sqid03=10308001, sqid04=10308001, sfid=30505801},
			{sqid01=10308002, sqid02=10308002, sqid03=10308002, sqid04=10308002, sfid=30505802},
			{sqid01=10308003, sqid02=10308003, sqid03=10308003, sqid04=10308003, sfid=30505803},
			{sqid01=10308004, sqid02=10308006, sqid03=10308008, sqid04=10308010, sfid=30505804},
			{sqid01=10308005, sqid02=10308007, sqid03=10308009, sqid04=10308011, sfid=30505805},
			{sqid01=10308012, sqid02=10308013, sqid03=10308014, sqid04=10308012, sfid=30505806},
			{sqid01=10308015, sqid02=10308016, sqid03=10308017, sqid04=10308018, sfid=30505806},
			{sqid01=10308019, sqid02=10308020, sqid03=10308021, sqid04=10308022, sfid=30505806},
			{sqid01=10308023, sqid02=10308023, sqid03=10308023, sqid04=10308023, sfid=30505806},
			{sqid01=10308024, sqid02=10308025, sqid03=10308026, sqid04=10308027, sfid=30505806},
			{sqid01=10308028, sqid02=10308029, sqid03=10308030, sqid04=10308031, sfid=30505806},
			{sqid01=10308032, sqid02=10308033, sqid03=10308034, sqid04=10308035, sfid=30505806},
			{sqid01=10308036, sqid02=10308037, sqid03=10308038, sqid04=10308039, sfid=30505806},
			{sqid01=10308040, sqid02=10308041, sqid03=10308041, sqid04=10308041, sfid=30505806},
			
			{sqid01=10316000, sqid02=10316000, sqid03=10316000, sqid04=10316000, sfid=30505800},
			{sqid01=10316001, sqid02=10316001, sqid03=10316001, sqid04=10316001, sfid=30505801},
			{sqid01=10316002, sqid02=10316002, sqid03=10316002, sqid04=10316002, sfid=30505802},
			{sqid01=10316003, sqid02=10316003, sqid03=10316003, sqid04=10316003, sfid=30505803},
			{sqid01=10316004, sqid02=10316006, sqid03=10316008, sqid04=10316010, sfid=30505804},
			{sqid01=10316005, sqid02=10316007, sqid03=10316009, sqid04=10316011, sfid=30505805},
			{sqid01=10316012, sqid02=10316013, sqid03=10316014, sqid04=10316012, sfid=30505806},
			{sqid01=10316015, sqid02=10316016, sqid03=10316017, sqid04=10316018, sfid=30505806},
			{sqid01=10316019, sqid02=10316020, sqid03=10316021, sqid04=10316022, sfid=30505806},
			{sqid01=10316023, sqid02=10316023, sqid03=10316023, sqid04=10316023, sfid=30505806},
			{sqid01=10316024, sqid02=10316025, sqid03=10316026, sqid04=10316027, sfid=30505806},
			{sqid01=10316028, sqid02=10316029, sqid03=10316030, sqid04=10316031, sfid=30505806},
			{sqid01=10316032, sqid02=10316033, sqid03=10316034, sqid04=10316035, sfid=30505806},
			{sqid01=10316036, sqid02=10316037, sqid03=10316038, sqid04=10316039, sfid=30505806},
			{sqid01=10316040, sqid02=10316041, sqid03=10316041, sqid04=10316041, sfid=30505806},
			
			--xinmenpai
			{sqid01=10317000, sqid02=10317000, sqid03=10317000, sqid04=10317000, sfid=30505800},
			{sqid01=10317001, sqid02=10317001, sqid03=10317001, sqid04=10317001, sfid=30505801},
			{sqid01=10317002, sqid02=10317002, sqid03=10317002, sqid04=10317002, sfid=30505802},
			{sqid01=10317003, sqid02=10317003, sqid03=10317003, sqid04=10317003, sfid=30505803},
			{sqid01=10317004, sqid02=10317006, sqid03=10317008, sqid04=10317010, sfid=30505804},
			{sqid01=10317005, sqid02=10317007, sqid03=10317009, sqid04=10317011, sfid=30505805},
			{sqid01=10317012, sqid02=10317013, sqid03=10317014, sqid04=10317012, sfid=30505806},
			{sqid01=10317015, sqid02=10317016, sqid03=10317017, sqid04=10317018, sfid=30505806},
			{sqid01=10317019, sqid02=10317020, sqid03=10317021, sqid04=10317022, sfid=30505806},
			{sqid01=10317023, sqid02=10317023, sqid03=10317023, sqid04=10317023, sfid=30505806},
			{sqid01=10317024, sqid02=10317025, sqid03=10317026, sqid04=10317027, sfid=30505806},
			{sqid01=10317028, sqid02=10317029, sqid03=10317030, sqid04=10317031, sfid=30505806},
			{sqid01=10317032, sqid02=10317033, sqid03=10317034, sqid04=10317035, sfid=30505806},
			{sqid01=10317036, sqid02=10317037, sqid03=10317038, sqid04=10317039, sfid=30505806},
			{sqid01=10317040, sqid02=10317041, sqid03=10317041, sqid04=10317041, sfid=30505806},
			--九星神器
			{sqid01=10300423, sqid02=10300424, sqid03=10300425, sqid04=10300426, sfid=30505806},
			{sqid01=10300427, sqid02=10300428, sqid03=10300429, sqid04=10300430, sfid=30505806},
			{sqid01=10300431, sqid02=10301444, sqid03=10301445, sqid04=10301446, sfid=30505806},
			{sqid01=10301447, sqid02=10301448, sqid03=10301449, sqid04=10301450, sfid=30505806},
			{sqid01=10301451, sqid02=10301452, sqid03=10301453, sqid04=10301454, sfid=30505806},
			{sqid01=10301455, sqid02=10301456, sqid03=10301457, sqid04=10301458, sfid=30505806},
			{sqid01=10301459, sqid02=10301460, sqid03=10301461, sqid04=10302449, sfid=30505806},
			{sqid01=10302450, sqid02=10302451, sqid03=10302452, sqid04=10302453, sfid=30505806},
			{sqid01=10302454, sqid02=10302455, sqid03=10302456, sqid04=10302457, sfid=30505806},
			{sqid01=10302458, sqid02=10302459, sqid03=10302460, sqid04=10302461, sfid=30505806},
			{sqid01=10302462, sqid02=10302463, sqid03=10302464, sqid04=10302465, sfid=30505806},
			{sqid01=10302466, sqid02=10303440, sqid03=10303441, sqid04=10303442, sfid=30505806},
			{sqid01=10303443, sqid02=10303444, sqid03=10303445, sqid04=10303446, sfid=30505806},
			{sqid01=10303447, sqid02=10303448, sqid03=10303449, sqid04=10303450, sfid=30505806},
			{sqid01=10303451, sqid02=10303452, sqid03=10303453, sqid04=10303454, sfid=30505806},
			{sqid01=10303455, sqid02=10303456, sqid03=10303457, sqid04=10304427, sfid=30505806},
			{sqid01=10304428, sqid02=10304429, sqid03=10304430, sqid04=10304431, sfid=30505806},
			{sqid01=10304432, sqid02=10304433, sqid03=10304434, sqid04=10304435, sfid=30505806},
			{sqid01=10305445, sqid02=10305446, sqid03=10305447, sqid04=10305448, sfid=30505806},
			{sqid01=10305449, sqid02=10305450, sqid03=10305451, sqid04=10305452, sfid=30505806},
			{sqid01=10305453, sqid02=10305454, sqid03=10305455, sqid04=10305456, sfid=30505806},
			{sqid01=10305457, sqid02=10305458, sqid03=10305459, sqid04=10305460, sfid=30505806},
			{sqid01=10305461, sqid02=10305462, sqid03=10306043, sqid04=10306044, sfid=30505806},
			{sqid01=10306045, sqid02=10306046, sqid03=10306047, sqid04=10306048, sfid=30505806},
			{sqid01=10306049, sqid02=10306050, sqid03=10306051, sqid04=10307043, sfid=30505806},
			{sqid01=10307044, sqid02=10307045, sqid03=10307046, sqid04=10307047, sfid=30505806},
			{sqid01=10307048, sqid02=10307049, sqid03=10307050, sqid04=10307051, sfid=30505806},
			{sqid01=10316043, sqid02=10316044, sqid03=10316045, sqid04=10316046, sfid=30505806},
			{sqid01=10316047, sqid02=10316048, sqid03=10316049, sqid04=10316050, sfid=30505806},
			{sqid01=10316051, sqid02=10316051, sqid03=10316051, sqid04=10316051, sfid=30505806},
			{sqid01=10317043, sqid02=10317044, sqid03=10317045, sqid04=10317046, sfid=30505806},
			{sqid01=10317047, sqid02=10317048, sqid03=10317049, sqid04=10317050, sfid=30505806},
			{sqid01=10317051, sqid02=10317051, sqid03=10317051, sqid04=10317051, sfid=30505806},
		}

local g_VIP_EquipRepair_SuperWeaponStartUpCommandList = 
{
	201208094, 201208093, 201208092, 201208091, 201208098
}

local g_VIP_EquipRepair_14_pos 
local g_VIP_EquipRepair_15_pos 
local g_VIP_EquipRepair_16_pos 
local g_VIP_EquipRepair_17_pos 

function VIP_EquipRepair_PreLoad()

	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("UPDATE_EQUIP_REPAIR",true);--挪入
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);--挪出
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("REFRESH_EQUIP",false)--装备更新
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面

	this:RegisterEvent("UPDATE_VIPZHENGHE_EQUIP_REPAIR",true);	


	this:RegisterEvent("UPDATE_SHENQI_REPAIR");
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);

	this:RegisterEvent("OPEN_VIP_SHOP")	

	this:RegisterEvent("BUY_ITEM")				--快捷购买，更新界面	
	
	
end

function VIP_EquipRepair_OnLoad()
	EQUIP_BUTTONS = VIP_EquipRepair_Item
	
	EQUIP_ACTIONBUTTON={
	VIP_EquipRepair_1,VIP_EquipRepair_2,VIP_EquipRepair_3,VIP_EquipRepair_4,VIP_EquipRepair_5,VIP_EquipRepair_6,
	VIP_EquipRepair_7,VIP_EquipRepair_8,VIP_EquipRepair_9,VIP_EquipRepair_10,VIP_EquipRepair_11,VIP_EquipRepair_12,
	VIP_EquipRepair_13,VIP_EquipRepair_14,VIP_EquipRepair_15,VIP_EquipRepair_16,VIP_EquipRepair_17
	}
	EQUIP_MASKBUTTON={
	VIP_EquipRepair_1_Mask,VIP_EquipRepair_2_Mask,VIP_EquipRepair_3_Mask,VIP_EquipRepair_4_Mask,VIP_EquipRepair_5_Mask,
	VIP_EquipRepair_6_Mask,VIP_EquipRepair_7_Mask,VIP_EquipRepair_8_Mask,VIP_EquipRepair_9_Mask,VIP_EquipRepair_10_Mask,
	VIP_EquipRepair_11_Mask,VIP_EquipRepair_12_Mask,VIP_EquipRepair_13_Mask,VIP_EquipRepair_14_Mask,VIP_EquipRepair_15_Mask,
	VIP_EquipRepair_16_Mask,VIP_EquipRepair_17_Mask
	}
	EQUIP_ANIMATEBTN={
	VIP_EquipRepair_1_Animate,VIP_EquipRepair_2_Animate,VIP_EquipRepair_3_Animate,VIP_EquipRepair_4_Animate,VIP_EquipRepair_5_Animate,
	VIP_EquipRepair_6_Animate,VIP_EquipRepair_7_Animate,VIP_EquipRepair_8_Animate,VIP_EquipRepair_9_Animate,VIP_EquipRepair_10_Animate,
	VIP_EquipRepair_11_Animate,VIP_EquipRepair_12_Animate,VIP_EquipRepair_13_Animate,VIP_EquipRepair_14_Animate,VIP_EquipRepair_15_Animate,
	VIP_EquipRepair_16_Animate,VIP_EquipRepair_17_Animate
	}
	
	TimesLeftTips[0] = VIP_EquipRepair_LeftChance3
	TimesLeftTips[1] = VIP_EquipRepair_LeftChance
	TimesLeftTips[2] = VIP_EquipRepair_LeftChance2	
	
	PageList[0] = VIP_EquipRepair_Item_MainFunction
	PageList[1] = VIP_EquipRepair_Item_MainFunction2
	PageList[2] = VIP_EquipRepair_Item_MainFunction3
	
	g_VIP_EquipRepair_Frame_UnifiedPosition=VIP_EquipRepair_Frame:GetProperty("UnifiedPosition");
	
	ShenQi_BUTTONS = VIP_EquipRepair_Item
	CaiLiao_BUTTONS = VIP_EquipRepair_Rune_Item
	g_VIP_EquipRepair_YuanBaoPay = 1;
	VIP_EquipRepair_check:SetCheck(g_VIP_EquipRepair_YuanBaoPay)
	
	
	Wuhun_BUTTONS = VIP_EquipRepair_Item
	WuhunCailiao_BUTTONS = VIP_EquipRepair_Yanshoudan_Item
	
	g_VIP_EquipRepair_14_pos = VIP_EquipRepair_14:GetProperty("UnifiedPosition");
	g_VIP_EquipRepair_15_pos = VIP_EquipRepair_15:GetProperty("UnifiedPosition");
	g_VIP_EquipRepair_16_pos = VIP_EquipRepair_16:GetProperty("UnifiedPosition");
	g_VIP_EquipRepair_17_pos = VIP_EquipRepair_17:GetProperty("UnifiedPosition");
end

--=========================================================
-- 二次确认框回调 ["Type"] "Ok"的返回值有"Ok"； ["Type"] "YesNo"的返回值有 "Yes" "No"
--=========================================================
function VIP_EquipRepair_OnComfirmedBack(strRet)
	if nil == strRet then
		return
	end

	g_bQuickRepair = 1

	if "Yes" == strRet or "Ok" == strRet then
		-- x805027_DoQuickRepairAllEquip( sceneId, selfId, targetId, nOpType, nYuanBaoPayFlag, nComfirmForShenQi )
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DoQuickRepairAllEquip")
			Set_XSCRIPT_ScriptID(805027)
			Set_XSCRIPT_Parameter(0, g_nComfirmParam1)
			Set_XSCRIPT_Parameter(1, g_nComfirmParam2)
			Set_XSCRIPT_Parameter(2, g_nComfirmParam3)
			-- nComfirmForShenQi 0 未二次确认 1 确认使用神魂液 2 确认不使用神魂液
			Set_XSCRIPT_Parameter(3, 1)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()	
	end

	if "No" == strRet then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("DoQuickRepairAllEquip")
			Set_XSCRIPT_ScriptID(805027)
			Set_XSCRIPT_Parameter(0, g_nComfirmParam1)
			Set_XSCRIPT_Parameter(1, g_nComfirmParam2)
			Set_XSCRIPT_Parameter(2, g_nComfirmParam3)
			-- nComfirmForShenQi 0 未二次确认 1 确认使用神魂液 2 确认不使用神魂液
			Set_XSCRIPT_Parameter(3, 2)
			Set_XSCRIPT_ParamCount(4)
		Send_XSCRIPT()	
	end
end

--=========================================================
-- 刷新装备修理线和一键修理钱数
--=========================================================
function VIP_EquipRepair_UpdateRepairLine(nTotalPrice, nRepairLine)

	if g_nRepairLine ~= nRepairLine then
		g_nRepairLine = nRepairLine	
	end

	VIP_EquipRepair_Number : SetText(g_nRepairLine)

	if g_nTotalPrice ~= nTotalPrice then
		g_nTotalPrice = nTotalPrice
	end

	local nGold, nSilver, nCopper = Bank:TransformCoin(g_nTotalPrice);

	local strMoney = ""

	if 0 ~= nGold then
		strMoney = tostring(nGold).."#-14"
	end

	if 0 ~= nSilver then
		strMoney = strMoney..tostring(nSilver).."#-15"
	end

	strMoney = strMoney..tostring(nCopper).."#-16"

	VIP_EquipRepair_YijianXiuli : SetToolTip( ScriptGlobal_Format("#{YJXLZB_20220818_04}", strMoney) )
end

--=========================================================
-- 修理线改变
--=========================================================
function VIP_EquipRepair_OnRepairLineChanged()
	local nCurRepairLine = tonumber(VIP_EquipRepair_Number : GetText())
	if nil == nCurRepairLine or nCurRepairLine < 0 then
		nCurRepairLine = 0
	end

	if nCurRepairLine ~= g_nRepairLine then
		-- x805027_SetEquipRepairLine( sceneId, selfId, nValue, targetId, bCurSelectedEquipIsEquiped, nCurSelectedEquipPos )
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("SetEquipRepairLine")
			Set_XSCRIPT_ScriptID(805027)
			Set_XSCRIPT_Parameter(0, nCurRepairLine)
			Set_XSCRIPT_Parameter(1, -1)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	end
end

--=========================================================
-- 快速一键修理
--=========================================================
function VIP_EquipRepair_OnQuickRepair()
	-- 执行一键修理 nOpType 1、普通一键修理 2、VIP一键修理
	-- nComfirmForShenQi 0 未二次确认 1 确认使用神魂液 2 确认不使用神魂液
	-- x805027_DoQuickRepairAllEquip( sceneId, selfId, targetId, nOpType, nYuanBaoPayFlag, nComfirmForShenQi )

	g_bQuickRepair = 1

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoQuickRepairAllEquip")
		Set_XSCRIPT_ScriptID(805027)
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_Parameter(1, 2)
		Set_XSCRIPT_Parameter(2, tonumber(VIP_EquipRepair_check:GetCheck()))
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()	
	
end

function VIP_EquipRepair_OnEvent(event)
	--PushDebugMessage(event)
	--g_Npc_Name =	Target:GetDialogNpcName();
	--	神器升星互斥
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 80502703 then
			local strMsg = Get_XParam_STR(0)
			g_nComfirmParam1 = Get_XParam_INT(0)
			g_nComfirmParam2 = Get_XParam_INT(1)
			g_nComfirmParam3 = Get_XParam_INT(2)
			-- ["Type"] "Ok" "YesNo"
			MessageBoxSelf3("VIP_EquipRepair_OnComfirmedBack", {["Content"] = strMsg,["Type"] = "YesNo", })
			return
		end

		if tonumber(arg0) == 810208171 then
			
			if Get_XParam_INT(0) ~= -1 then 
				return
			end
			
			if Get_XParam_INT(2)~= -1 then
				g_repair_type = Get_XParam_INT(2);
			else 
				VIP_EquipRepair_RefreshTimes();
				return
			end
			g_targetId = Get_XParam_INT(0);
			g_sel_price = Get_XParam_INT(1);

			VIP_EquipRepair_UpdateRepairLine(Get_XParam_INT(3), Get_XParam_INT(4))
			
			g_SaveEquip = -1
			
			if g_repair_type == 0 then 
			
				if  g_sel_price == -1 then
					
					VIP_EquipRepair_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
					VIP_EquipRepair_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))

					if g_targetId == -1 then
						VIP_EquipRepair_DragTitle:SetText("#{VIPTQ_120221_17}")
					else
						VIP_EquipRepair_DragTitle:SetText("#{INTERFACE_XML_92}")
						g_objCared = DataPool : GetNPCIDByServerID(g_targetId);
						if g_objCared == -1 then
							--PushDebugMessage("server传过来的数据有问题。");
							return;
						end
						BeginCareObject_VIP_EquipRepair()
					end
					VIP_EquipRepair_InitShowInEquip()
					this:Show();
				else
					if this:IsVisible() then
						--显示价钱
						VIP_EquipRepair_DemandMoney:SetProperty("MoneyNumber", g_sel_price)
						-- g_sel_price = -1
					end
				end
			
			elseif g_repair_type == 1 then --神器
			
				if ShenQi_QUALITY ~= -1 then
					ShenQi_BUTTONS : SetActionItem(-1);
					LifeAbility : Lock_Packet_Item(ShenQi_QUALITY,0);
					ShenQi_QUALITY = -1;
				end
				if CaiLiao_QUALITY ~= -1 then
					CaiLiao_BUTTONS : SetActionItem(-1)
					LifeAbility : Lock_Packet_Item(CaiLiao_QUALITY,0);
					CaiLiao_QUALITY = -1;
				end

				--VIP_EquipRepair_OK:Disable()				
				
				if g_VIP_EquipRepair_YuanBaoPay == 1 or g_VIP_EquipRepair_YuanBaoPay == 0 then
					VIP_EquipRepair_check:SetCheck(g_VIP_EquipRepair_YuanBaoPay)
				end
				VIP_EquipRepair_InitShowInEquip()
				this:Show();

			elseif g_repair_type == 2 then --武魂
				
				if g_VIP_EquipRepair_YuanBaoPay == 1 or g_VIP_EquipRepair_YuanBaoPay == 0 then
					VIP_EquipRepair_check:SetCheck(g_VIP_EquipRepair_YuanBaoPay)
				end
				VIP_EquipRepair_InitShowInEquip()
				this:Show();
			end	
						
		elseif 80502702 == tonumber(arg0) then
			-- 新增的刷新
			if this:IsVisible() then
				if -1 ~= Get_XParam_INT(1) then
					g_sel_price = Get_XParam_INT(1)
					VIP_EquipRepair_DemandMoney:SetProperty("MoneyNumber", g_sel_price)
				end

				VIP_EquipRepair_UpdateRepairLine(Get_XParam_INT(3), Get_XParam_INT(4))
			end
		else
			for i, tempValue in g_VIP_EquipRepair_SuperWeaponStartUpCommandList do
				if tonumber(arg0) == tempValue then					
					VIP_EquipRepair_Close();
					return;
				end
			end
		end
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		if arg0==nil or tonumber(arg0)==-1 then
			return
		end

		if g_SaveEquip ~= -1 and g_SaveEquip == tonumber(arg0) then
			g_CurSelect = VIP_EquipRepair_UpdateFail()
			g_SaveEquip = -1
		end
		if (g_CurSelect == tonumber(arg0) ) then

			VIP_EquipRepair_UpdateInBag(1,tonumber(arg0))
		end

	elseif( event == "UPDATE_VIPZHENGHE_EQUIP_REPAIR") then
		if arg0 ~= nil and arg1 ~= nil then
			VIP_EquipRepair_UpdateInBag(tonumber(arg0),tonumber(arg1));
		end

	elseif (event == "ADJEST_UI_POS" ) then
		VIP_EquipRepair_Frame_On_ResetPos()
		
	elseif (event == "OPEN_VIP_SHOP") then
		this:Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		VIP_EquipRepair_Frame_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif	( event == "MONEY_CHANGE_EX" and this:IsVisible()) then

		if g_repair_type == 0 then
			VIP_EquipRepair_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		elseif g_repair_type == 1 then
			VIP_EquipRepair_SelfMoney2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		elseif g_repair_type == 2 then
			VIP_EquipRepair_SelfMoney3:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		end	
	
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
			
		if g_repair_type == 0 then
			VIP_EquipRepair_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		elseif g_repair_type == 1 then
			VIP_EquipRepair_SelfJiaozi2:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		elseif g_repair_type == 2 then
			VIP_EquipRepair_SelfJiaozi3:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
		end		

		
	elseif event == "BUY_ITEM" and this:IsVisible() then	--快捷购买，更新界面
		local itemId = tonumber(arg1)

		if 1 == g_bQuickRepair then
			return
		end

		if itemId == 38000498 then
			VIP_EquipRepair_UpdateInBag(2,tonumber(PlayerPackage:GetBagPosByItemIndex(itemId)));	
		elseif itemId == INDEX_Yanshoudan then
			VIP_EquipRepair_UpdateInBag(2,tonumber(PlayerPackage:GetBagPosByItemIndex(itemId)));	
		end
	
	elseif( event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible()) then
		if(arg0~=nil and tonumber(arg0) == 36) then --右键清理武器框
			VIP_EquipRepair_Clear()
		elseif(arg0~=nil and tonumber(arg0) == 37) then--右键清理神魂液神符框
			VIP_EquipRepair_Yanshoudan_Item_RClick()
		elseif(arg0~=nil and tonumber(arg0) == 38) then--右键清理延寿丹框
			VIP_EquipRepair_Rune_Item_RClick()
		end
		
	end
	if (event=="REFRESH_EQUIP" and this:IsVisible()) then
		if g_CurSelect>100 then
			VIP_EquipRepair_Clear()
		end
		VIP_EquipRepair_InitShowInEquip()
		if g_SaveEquip ~= -1 then
			local retSel=VIP_EquipRepair_UpdateFail()
			g_SaveEquip=-1
			if retSel>100 then
				VIP_EquipRepair_ActionButton_Clk(math.mod(retSel,100))
			end
		end
	end
end
function VIP_EquipRepair_UpdateFail() --武器修理失败
	
	if g_repair_type == 0 then
		local ActionEquip=nil
		if g_SaveEquip>100 then
			--装备位
			if g_ValidEquipPos[g_SaveEquip-100]==nil then
				return -1
			end
			ActionEquip=EnumAction(g_ValidEquipPos[g_SaveEquip-100], "equip")
		elseif g_SaveEquip>=0 then
			--背包位
			ActionEquip = EnumAction(g_SaveEquip, "packageitem")
		end
		if ActionEquip==nil then
			return -1
		end
		if ActionEquip:GetID() == 0 then
			return -1
		end

		local nDur = ActionEquip : GetEquipDur()
		if nDur < 1.0 then
			if g_CurSelect == -1 then
				local nTimes = ActionEquip : GetRemainRepairCount()
				if nTimes ~= 0 then
					return g_SaveEquip
				else
					PushDebugMessage("#{CZDYH_161122_11}")	--#H装备可修理次数为0，请增加可修理次数后再进行修理。	
				end
			end
		end
		return -1
	end
end
function VIP_EquipRepair_InitShowInEquip()
	local nShowButton = 1
	if Player:GetData("Is2606S") == 1 and (i == 14 or i == 15) then
		nShowButton = 0
	end
	for i=1,16 do
		local ActionEquip=EnumAction(g_ValidEquipPos[i], "equip")
		if ActionEquip:GetID()~=0 and nShowButton == 1 then
			EQUIP_ACTIONBUTTON[i]:SetActionItem(ActionEquip:GetID())
			if ActionEquip:GetEquipDur()<0.1 then
				EQUIP_MASKBUTTON[i]:Show()
			else
				EQUIP_MASKBUTTON[i]:Hide()
			end
			
		else
			EQUIP_MASKBUTTON[i]:Hide()
		end
		EQUIP_ANIMATEBTN[i]:Hide()
	end
	
	local ActionEquip=EnumAction(g_ValidEquipPos[17], "equip")
	if ActionEquip:GetID()~=0 then
		EQUIP_ACTIONBUTTON[17]:SetActionItem(ActionEquip:GetID())
		if (DataPool:GetKfsData("LIFE") < 15) then
			EQUIP_MASKBUTTON[17]:Show()
		else
			EQUIP_MASKBUTTON[17]:Hide()
		end
		
	else
		EQUIP_MASKBUTTON[17]:Hide()
	end
	EQUIP_ANIMATEBTN[17]:Hide()
	
	VIP_EquipRepair_FreshSonFrame()

	-- VIP_EquipRepair_Number : SetProperty("DefaultEditBox", "True")
	
	if Player:GetData("Is2606S") == 1 then
		VIP_EquipRepair_14:Hide()
		VIP_EquipRepair_15:Hide()
		VIP_EquipRepair_16:SetProperty("UnifiedPosition", g_VIP_EquipRepair_14_pos);
		VIP_EquipRepair_17:SetProperty("UnifiedPosition", g_VIP_EquipRepair_15_pos);
		VIP_EquipRepair_16_Animate:SetProperty("UnifiedPosition", g_VIP_EquipRepair_14_pos);
		VIP_EquipRepair_17_Animate:SetProperty("UnifiedPosition", g_VIP_EquipRepair_15_pos);
	else
		VIP_EquipRepair_14:Show()
		VIP_EquipRepair_15:Show()
		VIP_EquipRepair_16:SetProperty("UnifiedPosition", g_VIP_EquipRepair_16_pos);
		VIP_EquipRepair_17:SetProperty("UnifiedPosition", g_VIP_EquipRepair_17_pos);
		VIP_EquipRepair_16_Animate:SetProperty("UnifiedPosition", g_VIP_EquipRepair_16_pos);
		VIP_EquipRepair_17_Animate:SetProperty("UnifiedPosition", g_VIP_EquipRepair_17_pos);
	end
end

function VIP_EquipRepair_FreshSonFrame()
	
	VIP_EquipRepair_Clear()
	
	if g_repair_type == 0 then
		--local temp = mod(g_repair_type, 3)
		--PushDebugMessage(temp)	
		--PushDebugMessage("切换到武器")
		g_CurSelect=-1
		PageList[0]:SetProperty("Visible", "True");
		PageList[1]:SetProperty("Visible", "False");
		PageList[2]:SetProperty("Visible", "False");
						
		VIP_EquipRepair_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		VIP_EquipRepair_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))

	elseif g_repair_type == 1 then
		g_CurSelect=-1
		--PushDebugMessage("切换到神器")
		PageList[1]:SetProperty("Visible", "True");
		PageList[0]:SetProperty("Visible", "False");
		PageList[2]:SetProperty("Visible", "False");
		
		VIP_EquipRepair_SelfMoney2:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		VIP_EquipRepair_SelfJiaozi2:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))

	elseif g_repair_type == 2 then
		g_CurSelect=-1
		--PushDebugMessage("切换到武魂")
		PageList[2]:SetProperty("Visible", "True");
		PageList[1]:SetProperty("Visible", "False");
		PageList[0]:SetProperty("Visible", "False");
		
		VIP_EquipRepair_SelfMoney3:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		VIP_EquipRepair_SelfJiaozi3:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))

	end
	VIP_EquipRepair_RefreshTimes()
end


function VIP_EquipRepair_OnShown()
	VIP_EquipRepair_Clear()

end

function VIP_EquipRepair_Clear()

	if g_CurSelect>=0 then
		EQUIP_BUTTONS : SetActionItem(-1);
		if g_CurSelect>100 then
			EQUIP_ANIMATEBTN[g_CurSelect-100]:Hide()
		elseif g_CurSelect>=0 then
			LifeAbility : Lock_Packet_Item(g_CurSelect,0);
		end
		g_CurSelect=-1
	end

		VIP_EquipRepair_DemandMoney : SetProperty("MoneyNumber", 0);
		VIP_EquipRepair_Endurance_Num:SetText("")
		
	VIP_EquipRepair_WuhunClear()
	VIP_EquipRepair_ShenQiClear()

end

function VIP_EquipRepair_UpdateInBag(pos0 ,pos1)
	local item_type = tonumber(pos0);	
	local pos_packet = tonumber(pos1);
	local theAction = EnumAction(pos_packet, "packageitem");
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)

	if item_type == 2 then --点击的是材料
	
		if g_repair_type == 1 then --修神器
	
			if theAction:GetID() ~= 0 then

				if ShenQi_QUALITY == -1 then
					PushDebugMessage("#{SQXL_030225_08}")
					--#H请先放入需要修理的神器。
					return
				end

				if ItemID == 38000498 or ItemID == 38000499 or (ItemID >= shenfuid and ItemID <= 30505806)then  --神魂液或者大于等级的神符

					--是否加锁
					if PlayerPackage:IsLock(pos_packet) == 1 then
						local strname = PlayerPackage:GetBagItemName( pos_packet )
						if strname == nil then
					return
					end
						local strdic = ScriptGlobal_Format("#{SQXL_030225_09}", strname)--#H%s0已被加锁，暂时无法用于修理神器，请解锁之后再行尝试
						PushDebugMessage(strdic)
						return
					end

					CaiLiao_BUTTONS:SetActionItem(theAction:GetID());
					if CaiLiao_QUALITY ~= -1 then
						LifeAbility : Lock_Packet_Item(CaiLiao_QUALITY,0);
					end
					--让之前的东西变亮
					CaiLiao_QUALITY = pos_packet;
					LifeAbility : Lock_Packet_Item(CaiLiao_QUALITY,1);
					--ShenQiRepair_OK:Enable()

				else
						local strdic = ""
						if shenfu_grade == 7 then
							strdic = "#{SQXL_160901_14}"
						else
							strdic = ScriptGlobal_Format("#{SQXL_030225_10}", shenfu_grade)--放入神魂液和对应等级神符的提示
						end						
						PushDebugMessage(strdic)
						
				end
				
			else

				CaiLiao_BUTTONS:SetActionItem(-1);
				LifeAbility : Lock_Packet_Item(CaiLiao_QUALITY,0);
				CaiLiao_QUALITY = -1;
				return;
			end
			
		elseif g_repair_type == 2 then --修武魂
	
			if Wuhun_ID == -1 then 
				PushDebugMessage("#{VIPSSXL_180814_33}") --请先放入需要修理的武魂。
				return
			end
			
			if theAction:GetID() ~= 0 then
				
					local itemID = PlayerPackage:GetItemTableIndex(pos_packet)
					if itemID ~=  INDEX_Yanshoudan then
						PushDebugMessage("#{WH_090729_36}") --此处只能放入武魂延寿丹。
						return
					end

					if PlayerPackage:IsLock( pos_packet ) == 1 then
						PushDebugMessage("#{WH_090729_07}")	--道具已上锁
						return
					end

				if WuhunCailiao_ID ~= -1 then
					LifeAbility : Lock_Packet_Item(WuhunCailiao_ID,0);
				end
				
				WuhunCailiao_BUTTONS:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				WuhunCailiao_ID = pos_packet
			else
					WuhunCailiao_BUTTONS:SetActionItem(-1);			
					LifeAbility : Lock_Packet_Item(WuhunCailiao_ID,0);		
					WuhunCailiao_ID = -1;
			end
		elseif g_repair_type == 0 then 	
			PushDebugMessage("#{VIPSSXL_180814_35}")
		end

	elseif item_type == 1 then --点击的是武器、神器、武魂

		if theAction:GetID() ~= 0 then
			local EquipPoint = LifeAbility:Get_Equip_Point(pos_packet)
			if EquipPoint == -1 or EquipPoint == 8 or EquipPoint == 9 or EquipPoint == 10 then --武魂的限制
				if EquipPoint ~= -1 then
					PushDebugMessage("#{VIPSSXL_180814_35}")
				end
				return
			end
			if EquipPoint==16 then
				PushDebugMessage("#{XHRYH_170614_51}")--#H时装不需要修理。
				return
			end
				
			local nEquipID = PlayerPackage : GetItemTableIndex(pos_packet)
			
			if nEquipID >= EQUIP_SHENQI_BEGIN and nEquipID <= EQUIP_SHENQI_END and PlayerPackage:IsBagItemKFS(pos_packet) ~= 1 then --点的是神器
				
				if(VIP_EquipRepair_RequestTimes(9) == 0) then
					PushDebugMessage(ScriptGlobal_Format("#{VIPSSXL_180814_28}", "#{VIPSSXL_180814_40}"))--您没有随身神器修理次数
					return
				end
				
				g_repair_type = 1;
				VIP_EquipRepair_FreshSonFrame() 
					
				for i, item in g_NeedItemBonus do
					if nEquipID == item.sqid01
						or nEquipID == item.sqid02
						or nEquipID == item.sqid03
						or nEquipID == item.sqid04 then
						
						shenfuid = item.sfid
								--新莽神符没有配等级，根据ID计算等级
						shenfu_grade = math.mod(shenfuid,10) + 1
						break
					end
				end
					
					
				-- 15级神器不需要修理 by lishilong 2016-8-23
				if 10300422 == nEquipID or 10302448 == nEquipID or 10304426 == nEquipID or 10316042 == nEquipID or 10317042 == nEquipID
										or 10305444 == nEquipID or 10306042 == nEquipID or 10307042 == nEquipID or 10308042 == nEquipID then
					PushDebugMessage("#{XSQSJ_160812_29}")--#H此神器不需要修理。
					return
				end

				local ShenQiPoint = LifeAbility:Get_Equip_Point(pos_packet)
				if ShenQiPoint == -1 or ShenQiPoint == 8 or ShenQiPoint == 9 or ShenQiPoint == 10
									or PlayerPackage:IsBagItemKFS(pos_packet) ==1 then --武魂的限制
					if ShenQiPoint ~= -1 then
						PushDebugMessage("此物品不需要修理。")
					end
					return
				end
				
				local nDurValue,nDurMaxValue = theAction:GetEquipDurValue()
				if nDurValue>=nDurMaxValue then
					PushDebugMessage("#{XHRYH_170614_58}")--#H此神器未受损伤，不需要修理。
					return
				end
				
				EQUIP_BUTTONS:SetActionItem(theAction:GetID());
				ShenQi_BUTTONS:SetActionItem(theAction:GetID());
				
				local strdic = ""
				if shenfu_grade == 7 then
					strdic = "#{SQXL_160901_13}"--#cfff2631瓶#G神魂液#cfff263或1个#G7级#cfff263的#G新莽神符#cfff263
				else
					strdic = ScriptGlobal_Format("#{SQXL_030225_05}", shenfu_grade) --需要1瓶神魂液或1个#{_ITEM%s0}#H
				end
				--ShenQiRepair_TiShi03:SetText( strdic );
				if ShenQi_QUALITY ~= -1 then
					LifeAbility : Lock_Packet_Item(ShenQi_QUALITY,0);
				end
					--让之前的东西变亮
				ShenQi_QUALITY = pos_packet;
				LifeAbility : Lock_Packet_Item(ShenQi_QUALITY,1);

						--材料拿下来
				if CaiLiao_QUALITY ~= -1 then
					CaiLiao_BUTTONS:SetActionItem(-1);
					LifeAbility : Lock_Packet_Item(CaiLiao_QUALITY,0);
					CaiLiao_QUALITY = -1;
				end
					
				return
					
				

			elseif PlayerPackage:IsBagItemKFS(pos_packet) == 1--[[nEquipID >= 10156001 and nEquipID <= 10156004--]] then  --修武魂
				local nAccLevel = DataPool:GetAccVipLevel();	
				if(VIP_EquipRepair_RequestTimes(18) == 0 and nAccLevel <= 5) then
					PushDebugMessage(ScriptGlobal_Format("#{VIPSSXL_180814_28}", "#{VIPSSXL_180814_41}"))--您没有武魂随身修理次数。
					return
				end
					g_repair_type = 2;
				
					VIP_EquipRepair_FreshSonFrame() 

						-- 寿命超过上限
						local curLife = PlayerPackage:GetBagKfsData(pos_packet, "LIFE")
						local maxLife = PlayerPackage:GetBagKfsData(pos_packet, "MAXLIFE")
						if curLife >= maxLife then
							if Wuhun_ID == pos_packet then
								Wuhun_BUTTONS:SetActionItem(-1);			
								LifeAbility : Lock_Packet_Item(pos_packet,0);		
								Wuhun_ID = -1;
								return
							end				
							PushDebugMessage("#{WHYH_161121_86}") --该武魂不需要延长寿命。
							return
						end			
					if Wuhun_ID ~= -1 then
						LifeAbility : Lock_Packet_Item(Wuhun_ID,0);
					end
					
					Wuhun_BUTTONS:SetActionItem(theAction:GetID());
					LifeAbility : Lock_Packet_Item(pos_packet,1);
					Wuhun_ID = pos_packet
					

					if Wuhun_ID ~= -1 then
						needMoney = 50000
					end
					if IsTBFinalServer() >= 1 then
						needMoney = 0
					end
					VIP_EquipRepair_DemandMoney3 : SetProperty("MoneyNumber", needMoney)
			
			else --修武器
			
				g_repair_type = 0;
					
				VIP_EquipRepair_FreshSonFrame() 
			
			
				--可修理次数是否为0
				local nTimes = theAction : GetRemainRepairCount()
				if nTimes==0 then
					PushDebugMessage("#{XHRYH_170614_53}")--#H装备可修理次数为0，请增加可修理次数后再进行修理。
					return
				end
				local curDur,MaxDur= theAction:GetEquipDurValue()
				if curDur>=MaxDur then
					PushDebugMessage("#{XHRYH_170614_54}")--#H物品没有损害，不用修理。
					return
				end
				local nAccLevel = DataPool:GetAccVipLevel();	
				if(VIP_EquipRepair_RequestTimes(7) == 0 and nAccLevel <= 5) then
					PushDebugMessage(ScriptGlobal_Format("#{VIPSSXL_180814_28}", "#{VIPSSXL_180814_39}"))--您没有装备随身修理次数。
					return
				end

				EQUIP_BUTTONS:SetActionItem(theAction:GetID());
				--让之前的东西变亮
				g_CurSelect = pos_packet
				LifeAbility : Lock_Packet_Item(pos_packet,1);
				if curDur<=10 then
					curDur="#cff0000"..curDur
				end
				local nValueText = ScriptGlobal_Format( "#{XHRYH_170608_16}", curDur, MaxDur )
				VIP_EquipRepair_Endurance_Num:SetText(nValueText)
				if ItemID < EQUIP_SHENQI_BEGIN or ItemID > EQUIP_SHENQI_END then
					-- Clear_XSCRIPT();
					-- Set_XSCRIPT_Function_Name("CalRepairPriceNew");
					-- Set_XSCRIPT_ScriptID(805027);
					-- Set_XSCRIPT_Parameter(0,math.floor(g_CurSelect/100));
					-- Set_XSCRIPT_Parameter(1,g_CurSelect);
					-- Set_XSCRIPT_Parameter(2,-1);
					-- Set_XSCRIPT_ParamCount(3);
					-- Send_XSCRIPT();

					Clear_XSCRIPT()
						Set_XSCRIPT_Function_Name("AskRefreshVIPEquipRepairUI")
						Set_XSCRIPT_ScriptID(805027)
						Set_XSCRIPT_Parameter(0, math.floor(g_CurSelect/100))
						Set_XSCRIPT_Parameter(1, g_CurSelect)
						Set_XSCRIPT_ParamCount(2)
					Send_XSCRIPT()
				end
				g_SaveEquip=-1
					
					
			end		
		else

			EQUIP_BUTTONS:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(g_CurSelect,0);
			g_CurSelect = -1;
		
			ShenQi_BUTTONS:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(ShenQi_QUALITY,0);
			ShenQi_QUALITY = -1;
			
			Wuhun_BUTTONS:SetActionItem(-1);			
			LifeAbility : Lock_Packet_Item(Wuhun_ID,0);		
			Wuhun_ID = -1;			
			
			g_SaveEquip=-1
			
		end

		
	end
end


function VIP_EquipRepair_Buttons_Clicked()  --点击修理按钮了

	g_bQuickRepair = 0

	if g_repair_type == 0 then  --武器
		
		if g_CurSelect==-1 then
			PushDebugMessage("#{XHRYH_170608_24}")--#H请先在界面选中一件已穿戴的装备或从背包内放入一件需要修理的装备。
			return
		end
		if g_CurSelect>100 then
			if g_ValidEquipPos[g_CurSelect-100]==nil then
				PushDebugMessage("#{XHRYH_170608_24}")
				return
			end
		end
		local ActionEquip=nil
		if g_CurSelect>100 then
			ActionEquip=EnumAction(g_ValidEquipPos[g_CurSelect-100], "equip")
		else
			ActionEquip=EnumAction(g_CurSelect, "packageitem")
		end
		--有效否
		if ActionEquip:GetID()==0 then
			PushDebugMessage("#{XHRYH_170608_24}")--#H请先在界面选中一件已穿戴的装备或从背包内放入一件需要修理的装备。
			return
		end
		--神器？
		local nEquipID=0
		if g_CurSelect>100 then
			nEquipID= ActionEquip:GetItemTableIndex()
		else
			nEquipID = PlayerPackage : GetItemTableIndex(g_CurSelect)--可以合并
		end
		--		if nEquipID >= EQUIP_SHENQI_BEGIN and nEquipID <= EQUIP_SHENQI_END then
		--			PushDebugMessage("#{XLSQ_20101209_01}")--#H这里无法修理神器，请找苏州（355，234）欧冶子进行修理。
		--			return
		--		end
		--可修理次数？
		local nTimes = ActionEquip:GetRemainRepairCount()
		if nTimes<=0 then
			PushDebugMessage("#{XHRYH_170608_26}")--#H请先增加该装备的可修理次数之后再来修理
			return
		end
		--钱够不？
		local playerMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
		if playerMoney<g_sel_price then
			local ValueTip = ScriptGlobal_Format( "#{XHRYH_170614_56}", g_sel_price )
			PushDebugMessage(ValueTip)
			return
		end
		local nAccLevel = DataPool:GetAccVipLevel();	
		if(VIP_EquipRepair_RequestTimes(7) == 0 and nAccLevel <=5) then
			PushDebugMessage(ScriptGlobal_Format("#{VIPSSXL_180814_28}", "#{VIPSSXL_180814_39}"))--您没有装备随身修理次数。
			return
		end

		if g_CurSelect>100 then
			-- Clear_XSCRIPT();
			-- 	Set_XSCRIPT_Function_Name("OnEquipRepairofEquip");
			-- 	Set_XSCRIPT_ScriptID(805027);
			-- 	Set_XSCRIPT_Parameter(0,1);
			-- 	Set_XSCRIPT_Parameter(1,-1);
			-- 	Set_XSCRIPT_Parameter(2,g_ValidEquipPos[g_CurSelect-100]);
			-- 	Set_XSCRIPT_ParamCount(3);
			-- Send_XSCRIPT();

			-- x805027_OnEquipRepairNew(sceneId, selfId, targetId, bEquipedEquip, nRepairEquipPos, nCaiLiaoPos, nYuanBaoPayFlag, nEnterID)
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnEquipRepairNew")
				Set_XSCRIPT_ScriptID(805027)
				Set_XSCRIPT_Parameter(0, -1)
				Set_XSCRIPT_Parameter(1, 1)
				Set_XSCRIPT_Parameter(2, g_ValidEquipPos[g_CurSelect-100])
				Set_XSCRIPT_Parameter(3, -1)
				Set_XSCRIPT_Parameter(4, 1)
				Set_XSCRIPT_Parameter(5, 1)
				Set_XSCRIPT_ParamCount(6)
			Send_XSCRIPT()
				
			g_SaveEquip = g_CurSelect
			VIP_EquipRepair_Clear();
		else
			-- Clear_XSCRIPT();
			-- 	Set_XSCRIPT_Function_Name("OnEquipRepair");
			-- 	Set_XSCRIPT_ScriptID(805027);
			-- 	Set_XSCRIPT_Parameter(0,1);
			-- 	Set_XSCRIPT_Parameter(1,-1);
			-- 	Set_XSCRIPT_Parameter(2,g_CurSelect);
			-- 	Set_XSCRIPT_ParamCount(3);
			-- Send_XSCRIPT();

			-- x805027_OnEquipRepairNew(sceneId, selfId, targetId, bEquipedEquip, nRepairEquipPos, nCaiLiaoPos, nYuanBaoPayFlag, nEnterID)
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("OnEquipRepairNew")
				Set_XSCRIPT_ScriptID(805027)
				Set_XSCRIPT_Parameter(0, -1)
				Set_XSCRIPT_Parameter(1, 0)
				Set_XSCRIPT_Parameter(2, g_CurSelect)
				Set_XSCRIPT_Parameter(3, -1)
				Set_XSCRIPT_Parameter(4, 1)
				Set_XSCRIPT_Parameter(5, 1)
				Set_XSCRIPT_ParamCount(6)
			Send_XSCRIPT()

			g_SaveEquip = g_CurSelect
			VIP_EquipRepair_Clear();
		end				
		
	elseif g_repair_type == 1 then  --神器
	
		if g_CurSelect == -1 and ShenQi_QUALITY == -1 then
			PushDebugMessage("#{XHRYH_170608_24}")--#H请先在界面选中一件已穿戴的装备或从背包内放入一件需要修理的装备。
			return
		end
		
		local nAccLevel = DataPool:GetAccVipLevel();
		if nAccLevel <= 2 then
			PushDebugMessage("您没有随身神器修理次数。")
			VIP_EquipRepair_ShenQiClear();
			return
		end
	
		if ShenQi_QUALITY ~= -1 then
			
			if g_CurSelect>100 then

					-- Clear_XSCRIPT();
					-- Set_XSCRIPT_Function_Name("OnEquipRepairofEquip");
					-- Set_XSCRIPT_ScriptID(805027);
					-- Set_XSCRIPT_Parameter(0,1);
					-- Set_XSCRIPT_Parameter(1,-1);--npcid
					-- Set_XSCRIPT_Parameter(2,g_ValidEquipPos[ShenQi_QUALITY-100]);
					-- Set_XSCRIPT_Parameter(3,CaiLiao_QUALITY);
					-- Set_XSCRIPT_Parameter(4,tonumber(VIP_EquipRepair_check:GetCheck()));
					-- Set_XSCRIPT_ParamCount(5);
					-- Send_XSCRIPT();

					-- x805027_OnEquipRepairNew(sceneId, selfId, targetId, bEquipedEquip, nRepairEquipPos, nCaiLiaoPos, nYuanBaoPayFlag, nEnterID)
					Clear_XSCRIPT()
						Set_XSCRIPT_Function_Name("OnEquipRepairNew")
						Set_XSCRIPT_ScriptID(805027)
						Set_XSCRIPT_Parameter(0, -1)
						Set_XSCRIPT_Parameter(1, 1)
						Set_XSCRIPT_Parameter(2, g_ValidEquipPos[ShenQi_QUALITY-100])
						Set_XSCRIPT_Parameter(3, CaiLiao_QUALITY)
						Set_XSCRIPT_Parameter(4, tonumber(VIP_EquipRepair_check:GetCheck()))
						Set_XSCRIPT_Parameter(5, 1)
						Set_XSCRIPT_ParamCount(6)
					Send_XSCRIPT()
					
					LifeAbility : Lock_Packet_Item(CaiLiao_QUALITY,0);
					if CaiLiao_QUALITY ~= -1 then
						VIP_EquipRepair_ShenQiClear();
						g_VIP_EquipRepair_YuanBaoPay = VIP_EquipRepair_check:GetCheck();		
					--this:Hide();
					end
				--g_SaveEquip = g_CurSelect
				--VIP_EquipRepair_Clear();
			-- [ QUFEI 2007-10-15 15:31 UPDATE BugID 26358 ]
			else
				-- Clear_XSCRIPT();
				-- 	Set_XSCRIPT_Function_Name("OnEquipRepair");
				-- 	Set_XSCRIPT_ScriptID(805027);
				-- 	Set_XSCRIPT_Parameter(0,1);
				-- 	Set_XSCRIPT_Parameter(1,-1);--npcid
				-- 	Set_XSCRIPT_Parameter(2,ShenQi_QUALITY);
				-- 	Set_XSCRIPT_Parameter(3,CaiLiao_QUALITY);
				-- 	Set_XSCRIPT_Parameter(4,tonumber(VIP_EquipRepair_check:GetCheck()));
				-- 	Set_XSCRIPT_ParamCount(5);
				-- Send_XSCRIPT();

				-- x805027_OnEquipRepairNew(sceneId, selfId, targetId, bEquipedEquip, nRepairEquipPos, nCaiLiaoPos, nYuanBaoPayFlag, nEnterID)
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name("OnEquipRepairNew")
					Set_XSCRIPT_ScriptID(805027)
					Set_XSCRIPT_Parameter(0, -1)
					Set_XSCRIPT_Parameter(1, 0)
					Set_XSCRIPT_Parameter(2, ShenQi_QUALITY)
					Set_XSCRIPT_Parameter(3, CaiLiao_QUALITY)
					Set_XSCRIPT_Parameter(4, tonumber(VIP_EquipRepair_check:GetCheck()))
					Set_XSCRIPT_Parameter(5, 1)
					Set_XSCRIPT_ParamCount(6)
				Send_XSCRIPT()

				--LifeAbility : Lock_Packet_Item(ShenQi_QUALITY,0);
				LifeAbility : Lock_Packet_Item(CaiLiao_QUALITY,0);
				if CaiLiao_QUALITY ~= -1 then
					VIP_EquipRepair_ShenQiClear();
					g_VIP_EquipRepair_YuanBaoPay = VIP_EquipRepair_check:GetCheck();		
				--this:Hide();
				end
			end
		else
			PushDebugMessage("#{SQXL_030225_08}")--请先放入需要修理的神器。
		end
		--VIP_EquipRepair_Clear()
	elseif g_repair_type == 2 then  --武魂

				-- 是否放入武魂
			if Wuhun_ID == -1 then
				PushDebugMessage("#{WHYH_161121_87}")
				return
			end

			if PlayerPackage:IsBagItemKFS( Wuhun_ID ) ~= 1 and g_ValidEquipPos[Wuhun_ID-100]~= 18 then
				PushDebugMessage("#{WHYH_161121_87}")--请先放入需要延长寿命的武魂，再进行该操作。
			return
			end
			
			-- 寿命超过上限
			local curLife;
			local maxLife;
			
			if g_CurSelect>100 then
				curLife = PlayerPackage:GetKfsDataOnEquip(Wuhun_ID, "LIFE")
				maxLife = PlayerPackage:GetKfsDataOnEquip(Wuhun_ID, "MAXLIFE")
			else
				curLife = PlayerPackage:GetBagKfsData(Wuhun_ID, "LIFE")
				maxLife = PlayerPackage:GetBagKfsData(Wuhun_ID, "MAXLIFE")
				
			end			
			

			if curLife >= maxLife then
				PushDebugMessage("#{WHYH_161121_86}") --该武魂不需要延长寿命。
				return
			end			

			-- 玩家身上的金钱是否足够
			local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")	

			if selfMoney < needMoney then
				PushDebugMessage("#{WHYH_161121_88}")  --对不起，你身上金钱不足，无法继续进行。
				return
			end

			if g_CurSelect>100 then

				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("Kfs_AddLifeNew");
					Set_XSCRIPT_ScriptID(809270);
					Set_XSCRIPT_Parameter(0,1);--vip
					Set_XSCRIPT_Parameter(1,g_ValidEquipPos[Wuhun_ID-100]);
					Set_XSCRIPT_Parameter(2,WuhunCailiao_ID);
					Set_XSCRIPT_Parameter(3,tonumber(VIP_EquipRepair_check:GetCheck()));
					Set_XSCRIPT_Parameter(4,1);
					Set_XSCRIPT_ParamCount(5);
				Send_XSCRIPT();
				
					LifeAbility : Lock_Packet_Item(WuhunCailiao_ID,0);
					if WuhunCailiao_ID ~= -1 then
						VIP_EquipRepair_WuhunClear();
						g_VIP_EquipRepair_YuanBaoPay = VIP_EquipRepair_check:GetCheck();		
					--this:Hide();
					end

			else

				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("Kfs_AddLifeNew");
					Set_XSCRIPT_ScriptID(809270);
					Set_XSCRIPT_Parameter(0,1);--vip
					Set_XSCRIPT_Parameter(1,Wuhun_ID);
					Set_XSCRIPT_Parameter(2,WuhunCailiao_ID);
					Set_XSCRIPT_Parameter(3,tonumber(VIP_EquipRepair_check:GetCheck()));
					Set_XSCRIPT_Parameter(4,0);
					Set_XSCRIPT_ParamCount(5);
				Send_XSCRIPT();

				LifeAbility : Lock_Packet_Item(WuhunCailiao_ID,0);
				if WuhunCailiao_ID ~= -1 then
					VIP_EquipRepair_WuhunClear();
					g_VIP_EquipRepair_YuanBaoPay = VIP_EquipRepair_check:GetCheck();		
				--this:Hide();
				end
			end		
			
	end

	VIP_EquipRepair_RefreshTimes();
	
end

function VIP_EquipRepair_Close()
	VIP_EquipRepair_Clear();
	StopCareObject_VIP_EquipRepair()
	

	g_VIP_EquipRepair_YuanBaoPay = VIP_EquipRepair_check:GetCheck();

	this:Hide()
end

function VIP_EquipRepair_Cancel_Clicked()
	VIP_EquipRepair_Close();
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_VIP_EquipRepair()
	this:CareObject(g_objCared, 1, "VIP_EquipRepair");
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_VIP_EquipRepair(g_objCaredId)

	this:CareObject(g_objCared, 0, "VIP_EquipRepair");
	g_objCared = -1;

end

function VIP_EquipRepair_Frame_On_ResetPos()
  VIP_EquipRepair_Frame:SetProperty("UnifiedPosition", g_VIP_EquipRepair_Frame_UnifiedPosition);
end

--待修理装备清理
function VIP_EquipRepair_Item_RClick()
	VIP_EquipRepair_Clear()
end

function VIP_EquipRepair_ActionButton_Clk(index)                                                       --点周围那圈actionbutton
	if g_ValidEquipPos[index]==nil then
		return
	end
--	g_CurSelect=-1
	--当选==前选 返回
	if g_CurSelect==100+index then
		return
	end

	--当前选中的是否合乎要求
	--穿戴
	local ActionEquip=EnumAction(g_ValidEquipPos[index], "equip")
	if ActionEquip:GetID()~=0 then
	else
		PushDebugMessage("#{XHRYH_170608_25}")--#H您选中的装备未穿戴，请重新选择
		return
	end
	g_repair_type = 0;
	local nAccLevel = DataPool:GetAccVipLevel();	
	--神器否
	local nEquipID= ActionEquip:GetItemTableIndex()
	if nEquipID >= EQUIP_SHENQI_BEGIN and nEquipID <= EQUIP_SHENQI_END then	
		
		if(VIP_EquipRepair_RequestTimes(9) == 0) then
			PushDebugMessage(ScriptGlobal_Format("#{VIPSSXL_180814_28}", "#{VIPSSXL_180814_40}"))--您没有随身神器修理次数
			return
		end
		g_repair_type = 1;

	end
	--插入武魂否？
	if nEquipID >=10156001	 and nEquipID <= 10156004 then		
		if(VIP_EquipRepair_RequestTimes(18) == 0 and nAccLevel <=5) then
			PushDebugMessage(ScriptGlobal_Format("#{VIPSSXL_180814_28}", "#{VIPSSXL_180814_41}"))--您没有随身武魂修理次数
			return
		end	
		g_repair_type = 2;
	end

	VIP_EquipRepair_FreshSonFrame();

	if g_repair_type == 0 then

		if(VIP_EquipRepair_RequestTimes(7) == 0 and nAccLevel <=5) then
			PushDebugMessage(ScriptGlobal_Format("#{VIPSSXL_180814_28}", "#{VIPSSXL_180814_39}"))--您没有装备随身修理次数。
			return
		end		
		--可修理次数是否为0
		local nTimes = ActionEquip : GetRemainRepairCount()
		if nTimes==0 then
			PushDebugMessage("#{XHRYH_170614_53}")
			return
		end
		--耐久度满否
		local curDur,MaxDur= ActionEquip:GetEquipDurValue()
		if curDur>=MaxDur then
			PushDebugMessage("#{XHRYH_170608_27}")
			return
		end

		--可以放入了，清理记录
		if g_CurSelect>100 then
			EQUIP_ANIMATEBTN[g_CurSelect-100]:Hide()
		elseif g_CurSelect>=0 then
			--装备位取消
			LifeAbility : Lock_Packet_Item(g_CurSelect,0);
		end
		


		--放入逻辑
		g_CurSelect = index+100;
		EQUIP_ANIMATEBTN[index]:Show()
		EQUIP_BUTTONS:SetActionItem(ActionEquip:GetID());
		if curDur<=10 then
			curDur="#cff0000"..curDur
		end
		local nValueText = ScriptGlobal_Format( "#{XHRYH_170608_16}", curDur, MaxDur )
		VIP_EquipRepair_Endurance_Num:SetText(nValueText)

		--请求花费
		Clear_XSCRIPT();
		-- 	Set_XSCRIPT_Function_Name("CalRepairPriceNew");
		-- 	Set_XSCRIPT_ScriptID(805027);
		-- 	Set_XSCRIPT_Parameter(0,math.floor(g_CurSelect/100));--1表示装备位; 0表示背包位
		-- 	Set_XSCRIPT_Parameter(1,g_ValidEquipPos[index]);
		-- 	Set_XSCRIPT_Parameter(2,-1);
		-- 	Set_XSCRIPT_ParamCount(3);
		-- Send_XSCRIPT();

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskRefreshVIPEquipRepairUI")
			Set_XSCRIPT_ScriptID(805027)
			Set_XSCRIPT_Parameter(0, math.floor(g_CurSelect/100))
			Set_XSCRIPT_Parameter(1, g_ValidEquipPos[index])
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()

		g_SaveEquip=-1	
	
	elseif g_repair_type == 1 then --修神器
	
	
	
	

		for i, item in g_NeedItemBonus do
			if nEquipID == item.sqid01
			or nEquipID == item.sqid02
			or nEquipID == item.sqid03
			or nEquipID == item.sqid04 then
						
				shenfuid = item.sfid
				--新莽神符没有配等级，根据ID计算等级
				shenfu_grade = math.mod(shenfuid,10) + 1
				break
			end
		end
					
		if nEquipID < EQUIP_SHENQI_BEGIN or nEquipID > EQUIP_SHENQI_END then
			if shenfu_grade == 7 then
				PushDebugMessage("#{SQXL_160901_14}")--#H修理此神器，需要放入神魂液或7级的新莽神符
			else
				local strdic = ""
				strdic = ScriptGlobal_Format("#{SQXL_030225_10}", shenfu_grade)--#H修理此神器，需要放入神魂液或不低于%s0级的新莽神符
				PushDebugMessage(strdic)
			end
			return
		end
					
		-- 15级神器不需要修理 by lishilong 2016-8-23
		if 10300422 == nEquipID or 10302448 == nEquipID or 10304426 == nEquipID or 10316042 == nEquipID or 10317042 == nEquipID
			or 10305444 == nEquipID or 10306042 == nEquipID or 10307042 == nEquipID or 10308042 == nEquipID then
			PushDebugMessage("#{XSQSJ_160812_29}")--#H此神器不需要修理。
			return
		end

				
		local nDurValue,nDurMaxValue = ActionEquip:GetEquipDurValue()
		if nDurValue>=nDurMaxValue then
			PushDebugMessage("#{XHRYH_170614_58}")--#H此神器未受损伤，不需要修理。
			return
		end
		EQUIP_BUTTONS:SetActionItem(ActionEquip:GetID());

					

		local strdic = ""
		if shenfu_grade == 7 then
			strdic = "#{SQXL_160901_13}"--#cfff2631瓶#G神魂液#cfff263或1个#G7级#cfff263的#G新莽神符#cfff263
		else
			strdic = ScriptGlobal_Format("#{SQXL_030225_05}", shenfu_grade) --需要1瓶神魂液或1个#{_ITEM%s0}#H
		end
				
				
		--可以放入了，清理记录
		if g_CurSelect>100 then
			EQUIP_ANIMATEBTN[g_CurSelect-100]:Hide()
		elseif g_CurSelect>=0 then
			--装备位取消
			LifeAbility : Lock_Packet_Item(g_CurSelect,0);
		end

		--放入逻辑
		g_CurSelect = index+100;
		
		ShenQi_QUALITY = g_CurSelect;

		EQUIP_ANIMATEBTN[index]:Show()
		--EQUIP_BUTTONS:SetActionItem(ActionEquip:GetID());
		ShenQi_BUTTONS:SetActionItem(ActionEquip:GetID());
		
		return
		
	elseif g_repair_type == 2 then --修武魂
	
	
	-- 寿命超过上限
			local curLife = PlayerPackage:GetKfsDataOnEquip(nEquipID, "LIFE")
			local maxLife = PlayerPackage:GetKfsDataOnEquip(nEquipID, "MAXLIFE")
			if curLife >= maxLife then
				if m_Equip_Idx == nEquipID then
					Wuhun_BUTTONS:SetActionItem(-1);			
					LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);		
					m_Equip_Idx = -1;
					return
				end				
				PushDebugMessage("#{WHYH_161121_86}") --该武魂不需要延长寿命。
				return
			end			
	
	
			--可以放入了，清理记录
		if g_CurSelect>100 then
			EQUIP_ANIMATEBTN[g_CurSelect-100]:Hide()
		elseif g_CurSelect>=0 then
			--装备位取消
			LifeAbility : Lock_Packet_Item(g_CurSelect,0);
		end

		--放入逻辑
		g_CurSelect = index+100;
		
		Wuhun_ID = g_CurSelect;
		
		EQUIP_ANIMATEBTN[index]:Show()
		--EQUIP_BUTTONS:SetActionItem(ActionEquip:GetID());
		Wuhun_BUTTONS:SetActionItem(ActionEquip:GetID());
	
		needMoney = 50000;

		if IsTBFinalServer() >= 1 then
			needMoney = 0
		end
		
		VIP_EquipRepair_DemandMoney3 : SetProperty("MoneyNumber", needMoney)

		return
	end

end



function VIP_EquipRepair_ShenQiClear()

		if ShenQi_QUALITY ~= -1 then
			EQUIP_BUTTONS : SetActionItem(-1);
			ShenQi_BUTTONS: SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(ShenQi_QUALITY,0);
			ShenQi_QUALITY = -1;
		end
		if CaiLiao_QUALITY ~= -1 then
			CaiLiao_BUTTONS : SetActionItem(-1)
			LifeAbility : Lock_Packet_Item(CaiLiao_QUALITY,0);
			CaiLiao_QUALITY = -1;
		end

end


function VIP_EquipRepair_WuhunClear()
		
		if Wuhun_ID ~= -1 then
			EQUIP_BUTTONS : SetActionItem(-1);
			Wuhun_BUTTONS : SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(Wuhun_ID,0);
			Wuhun_ID = -1;
		end
		if WuhunCailiao_ID ~= -1 then
			WuhunCailiao_BUTTONS : SetActionItem(-1)
			LifeAbility : Lock_Packet_Item(WuhunCailiao_ID,0);
			WuhunCailiao_ID = -1;
		end
		needMoney = 0;
		VIP_EquipRepair_DemandMoney3 : SetProperty("MoneyNumber", needMoney)

end

function VIP_EquipRepair_Yanshoudan_Item_RClick()  --右键点击延寿丹释放
		if WuhunCailiao_ID ~= -1 then
			WuhunCailiao_BUTTONS : SetActionItem(-1)
			LifeAbility : Lock_Packet_Item(WuhunCailiao_ID,0);
			WuhunCailiao_ID = -1;
		end
end

function VIP_EquipRepair_Rune_Item_RClick()  --右键点击神魂液神符释放
	if CaiLiao_QUALITY ~= -1 then
		CaiLiao_BUTTONS : SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(CaiLiao_QUALITY,0);
		CaiLiao_QUALITY = -1;
	end
end



function VIP_EquipRepair_RefreshTimes()
	local MaxUseTimes = 0;
	local UsedTimes = 0;
	local func;
	local tipstr;
	
	if g_repair_type == 0 then 
		func = 7; --武器
		tipstr = "#{VIPSSXL_180814_39}"
	elseif g_repair_type == 1 then
		func = 9; --神器
		tipstr = "#{VIPSSXL_180814_40}"
	elseif g_repair_type == 2 then 
		func = 18; --武魂
		tipstr = "#{VIPSSXL_180814_41}"
	end
	
	local nAccLevel = DataPool:GetAccVipLevel();
	if nAccLevel == 0 or (nAccLevel <= 2 and func == 9) then
	
		MaxUseTimes = 0
		UsedTimes = 0

	else 
	
		for i = 1, g_VIP_MaxNum do --VIP最大功能数
			local funcId, funcType, funcMaxUseTimes, funcUsedTimes = DataPool:GetVipInfoByIdx(i-1)
			if funcId and funcId == func then
				MaxUseTimes = funcMaxUseTimes
				UsedTimes = funcUsedTimes
				--PushDebugMessage("MaxUseTimes"..MaxUseTimes.."UsedTimes"..UsedTimes)
				break
			end
		end
	end


	if MaxUseTimes == -1 then 
		TimesLeftTips[g_repair_type]: SetText(ScriptGlobal_Format("#{VIPSSXL_180814_36}", tipstr))
	elseif (MaxUseTimes-UsedTimes) == 0 then
		TimesLeftTips[g_repair_type]: SetText(ScriptGlobal_Format("#{VIPSSXL_180814_38}", tipstr, MaxUseTimes))
	else
		TimesLeftTips[g_repair_type]: SetText(ScriptGlobal_Format("#{VIPSSXL_180814_37}", tipstr, (MaxUseTimes-UsedTimes), MaxUseTimes))
	end 

end

function VIP_EquipRepair_RequestTimes(func)
	local MaxUseTimes = 0
	local UsedTimes = 0
	local nAccLevel = DataPool:GetAccVipLevel();
	if nAccLevel == 0 or (nAccLevel <= 2 and func == 9) then
	
		MaxUseTimes = 0
		UsedTimes = 0

	else 
		for i = 1, g_VIP_MaxNum do --VIP最大功能数
			local funcId, funcType, funcMaxUseTimes, funcUsedTimes = DataPool:GetVipInfoByIdx(i-1)
			if funcId and funcId == func then
				MaxUseTimes = funcMaxUseTimes
				UsedTimes = funcUsedTimes
				--PushDebugMessage("MaxUseTimes"..MaxUseTimes.."UsedTimes"..UsedTimes)
				break
			end
		end
	end	
	return (MaxUseTimes-UsedTimes)
end





