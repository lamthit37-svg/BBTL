-------------------------------------------------------
--家园兽栏界面
-----------------------------------------------------------

local MAX_OBJ_DISTANCE = 3.0;
local objCared = -1;

local MAX_JYSLPET_NUM = 3--家园兽栏最大容纳宝宝数
local CUR_JYSLPET_SIZE = 0--当前可容纳宝宝数
local CUR_JYSL_LEVEL = 0--当前家园兽栏等级

local MAX_JYPETBANK_NUM = 10--银行容器的大小
local CUR_JYPETBANK_SIZE = 0--当前珍兽银行的最大size
local CUR_JYPETBANK_SELECT = 0--默认选中第1个

local g_BieYePetBar_JYSLUIText = 
{
	[1] = {state1 = "#{JYSL_160518_09}", state2 = "#{JYSL_160518_81}", Train = "#{JYSL_160518_26}", Time = "#{JYSL_160518_35}", Finish = "#{JYSL_160518_38}", Exp = "#{JYSL_160518_29}", Promote = "#{JYSL_160518_32}", Star = "#{JYSL_160518_194}", Star1 = "#{JYSL_160518_192}", Train1 = "#{JYSL_160518_185}", Time1 = "#{JYSL_160518_190}", Exp1 = "#{JYSL_160518_187}", Promote1 = "#{JYSL_160518_243}", Retrieve="#{JYSL_160518_229}",},
	[2] = {state1 = "#{JYSL_160518_10}", state2 = "#{JYSL_160518_82}", Train = "#{JYSL_160518_27}", Time = "#{JYSL_160518_36}", Finish = "#{JYSL_160518_39}", Exp = "#{JYSL_160518_30}", Promote = "#{JYSL_160518_33}", Star = "#{JYSL_160518_194}", Star1 = "#{JYSL_160518_193}", Train1 = "#{JYSL_160518_186}", Time1 = "#{JYSL_160518_191}", Exp1 = "#{JYSL_160518_188}", Promote1 = "#{JYSL_160518_189}", Retrieve="#{JYSL_160518_230}",},
}

local g_BieYePetBar_JYSLLevel = 
{
	[1] = 1,
	[2] = 3,
	[3] = 5,
}

local g_BieYePetBar_JYSLUIName = 
{
	[1] = {BK="",Image="",Tu="",Name="",Level="",Train="",Time="",Exp="",Promote="",TrainText="",TimeText="",ExpText="",PromoteText="",Retrieve="",NeedLevel="",},
	[2] = {BK="",Image="",Tu="",Name="",Level="",Train="",Time="",Exp="",Promote="",TrainText="",TimeText="",ExpText="",PromoteText="",Retrieve="",NeedLevel="",},
	[3] = {BK="",Image="",Tu="",Name="",Level="",Train="",Time="",Exp="",Promote="",TrainText="",TimeText="",ExpText="",PromoteText="",Retrieve="",NeedLevel="",},
}

local g_BieYePetBar_LevelSelect = 
{
	[1] = {msg1="#{JYSL_160518_214}", msg2="#{JYSL_160518_220}", },
	[2] = {msg1="#{JYSL_160518_215}", msg2="#{JYSL_160518_221}", },
	[3] = {msg1="#{JYSL_160518_216}", msg2="#{JYSL_160518_222}", },
	[4] = {msg1="#{JYSL_160518_217}", msg2="#{JYSL_160518_223}", },
	[5] = {msg1="#{JYSL_160518_218}", msg2="#{JYSL_160518_224}", },
}

local BIEYEPETBAR_AITYPE = {};

--珍兽进阶 限制可携带等级55级以上的珍兽才可以进阶
local PET_JINJIE_LIMIT_BYTLVL = 55
local PET_JINJIELVL_PERGRADE	= 10
local PET_JINJIELVL_MAXGRADE	= 10

local g_NumToStrTable =
{
	"#{JJKHD_120808_64}",		--零
	"#{JJKHD_120808_65}",		--一
	"#{JJKHD_120808_66}",		--二
	"#{JJKHD_120808_67}",
	"#{JJKHD_120808_68}",		--四
	"#{JJKHD_120808_69}",
	"#{JJKHD_120808_70}",
	"#{JJKHD_120808_71}",
	"#{JJKHD_120808_72}",
	"#{JJKHD_120808_73}",
	"#{JJKHD_120808_74}",
}

function BieYePetBar_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false); --界面敏感事件
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false); --界面敏感事件
	-- 需要刷新数据的消息
	this:RegisterEvent("TOGLE_PETLIST_PETNUM_CHNAGE")	-- 珍兽数量变化
	this:RegisterEvent("DELETE_PET")					-- 珍兽删除
	this:RegisterEvent("UPDATE_PET_PAGE")				-- 珍兽信息刷新
	this:RegisterEvent("TOGLE_PETLIST_SELECT_CHNAGE")	-- 珍兽银行操作
	-- 互斥界面
	this:RegisterEvent("TOGLE_PETBANK") 				-- 打开珍兽银行界面事件
	this:RegisterEvent("TOGLE_PET_PAGE") 				-- 打开角色pet界面
end

function BieYePetBar_OnLoad()
	g_BieYePetBar_JYSLUIName[1].BK = BieYePetBar_PetBK1
	g_BieYePetBar_JYSLUIName[1].Image = BieYePetBar_PetBK1_Unable
	g_BieYePetBar_JYSLUIName[1].Tu = BieYePetBar_Pet_Tu1
	g_BieYePetBar_JYSLUIName[1].Name = BieYePetBar_PetName1
	g_BieYePetBar_JYSLUIName[1].Level = BieYePetBar_Petlevel1
	g_BieYePetBar_JYSLUIName[1].Train = BieYePetBar_PetTrain1_Text
	g_BieYePetBar_JYSLUIName[1].Time = BieYePetBar_Traintime1_Text
	g_BieYePetBar_JYSLUIName[1].Exp = BieYePetBar_TrainExp1_Text
	g_BieYePetBar_JYSLUIName[1].Promote = BieYePetBar_TrainLevel_Text--BieYePetBar_Promote1_Text
	--g_BieYePetBar_JYSLUIName[1].Star = BieYePetBar_TrainLevel_Text
	g_BieYePetBar_JYSLUIName[1].TrainText = BieYePetBar_PetTrain1
	g_BieYePetBar_JYSLUIName[1].TimeText = BieYePetBar_Traintime1
	g_BieYePetBar_JYSLUIName[1].ExpText = BieYePetBar_TrainExp1
	g_BieYePetBar_JYSLUIName[1].PromoteText = BieYePetBar_TrainLevel--BieYePetBar_Promote1
	--g_BieYePetBar_JYSLUIName[1].StarText = BieYePetBar_TrainLevel
	g_BieYePetBar_JYSLUIName[1].Retrieve = BieYePetBar_Retrieve1
	g_BieYePetBar_JYSLUIName[1].NeedLevel = BieYePetBar_NeedLevel1
	
	g_BieYePetBar_JYSLUIName[2].BK = BieYePetBar_PetBK2
	g_BieYePetBar_JYSLUIName[2].Image = BieYePetBar_PetBK2_Unable
	g_BieYePetBar_JYSLUIName[2].Tu = BieYePetBar_Pet_Tu2
	g_BieYePetBar_JYSLUIName[2].Name = BieYePetBar_PetName2
	g_BieYePetBar_JYSLUIName[2].Level = BieYePetBar_Petlevel2
	g_BieYePetBar_JYSLUIName[2].Train = BieYePetBar_PetTrain2_Text
	g_BieYePetBar_JYSLUIName[2].Time = BieYePetBar_Traintime2_Text
	g_BieYePetBar_JYSLUIName[2].Exp = BieYePetBar_TrainExp2_Text
	g_BieYePetBar_JYSLUIName[2].Promote = BieYePetBar_PetTrain2Level_Text--BieYePetBar_Promote2_Text
	--g_BieYePetBar_JYSLUIName[2].Star = BieYePetBar_PetTrain2Level_Text
	g_BieYePetBar_JYSLUIName[2].TrainText = BieYePetBar_PetTrain2
	g_BieYePetBar_JYSLUIName[2].TimeText = BieYePetBar_Traintime2
	g_BieYePetBar_JYSLUIName[2].ExpText = BieYePetBar_TrainExp2
	g_BieYePetBar_JYSLUIName[2].PromoteText = BieYePetBar_PetTrain2Level--BieYePetBar_Promote2
	--g_BieYePetBar_JYSLUIName[2].StarText = BieYePetBar_PetTrain2Level
	g_BieYePetBar_JYSLUIName[2].Retrieve = BieYePetBar_Retrieve2
	g_BieYePetBar_JYSLUIName[2].NeedLevel = BieYePetBar_NeedLevel2
	
	g_BieYePetBar_JYSLUIName[3].BK = BieYePetBar_PetBK3
	g_BieYePetBar_JYSLUIName[3].Image = BieYePetBar_PetBK3_Unable
	g_BieYePetBar_JYSLUIName[3].Tu = BieYePetBar_Pet_Tu3
	g_BieYePetBar_JYSLUIName[3].Name = BieYePetBar_PetName3
	g_BieYePetBar_JYSLUIName[3].Level = BieYePetBar_Petlevel3
	g_BieYePetBar_JYSLUIName[3].Train = BieYePetBar_PetTrain3_Text
	g_BieYePetBar_JYSLUIName[3].Time = BieYePetBar_Traintime3_Text
	g_BieYePetBar_JYSLUIName[3].Exp = BieYePetBar_TrainExp3_Text
	g_BieYePetBar_JYSLUIName[3].Promote = BieYePetBar_PetTrain3Level_Text--BieYePetBar_Promote3_Text
	--g_BieYePetBar_JYSLUIName[3].Star = BieYePetBar_PetTrain3Level_Text
	g_BieYePetBar_JYSLUIName[3].TrainText = BieYePetBar_PetTrain3
	g_BieYePetBar_JYSLUIName[3].TimeText = BieYePetBar_Traintime3
	g_BieYePetBar_JYSLUIName[3].ExpText = BieYePetBar_TrainExp3
	g_BieYePetBar_JYSLUIName[3].PromoteText = BieYePetBar_PetTrain3Level--BieYePetBar_Promote3
	--g_BieYePetBar_JYSLUIName[3].StarText = BieYePetBar_PetTrain2Level
	g_BieYePetBar_JYSLUIName[3].Retrieve = BieYePetBar_Retrieve3
	g_BieYePetBar_JYSLUIName[3].NeedLevel = BieYePetBar_NeedLevel3
	
	BIEYEPETBAR_AITYPE[0] = "胆小";
	BIEYEPETBAR_AITYPE[1] = "谨慎";
	BIEYEPETBAR_AITYPE[2] = "忠诚";
	BIEYEPETBAR_AITYPE[3] = "精明";
	BIEYEPETBAR_AITYPE[4] = "勇猛";

end

--!!!reloadscript =BieYePetBar
function BieYePetBar_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 2016051911 ) then
		local objid = Get_XParam_INT(0)
		local banksize = Get_XParam_INT(1)
		local petsize = Get_XParam_INT(2)
		local curJYSLLevel = Get_XParam_INT(3)
		if objid ~= nil and objid ~= -1 then
			--关注npc
			objCared = DataPool : GetNPCIDByServerID(tonumber(objid))
			this:CareObject(objCared, 1, "BieYePetBar");
		end
		if banksize ~= nil and banksize > 0 and banksize <= MAX_JYPETBANK_NUM then
			--银行大小
			CUR_JYPETBANK_SIZE = tonumber(banksize) 			
		end
		if petsize ~= nil and petsize > 0 and petsize <= MAX_JYSLPET_NUM then
			--兽栏大小
			CUR_JYSLPET_SIZE = tonumber(petsize)
		end
		if curJYSLLevel ~= nil and curJYSLLevel > 0 then
			--兽栏等级
			CUR_JYSL_LEVEL = tonumber(curJYSLLevel)
		end
		--关闭已打开界面
		if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true);
		end	
		if(IsWindowShow("TargetPet2")) then
			CloseWindow("TargetPet2", true);
		end
		if(IsWindowShow("BieYePetBar_Train")) then
		  CloseWindow("BieYePetBar_Train", true);
		end	
		if(IsWindowShow("BieYePetBar_Tonic")) then
		  CloseWindow("BieYePetBar_Tonic", true);
		end	
		if(IsWindowShow("BieYePetBar_Awake")) then
		  CloseWindow("BieYePetBar_Awake", true);
		end
		if(IsWindowShow("PetBankMain")) then
			CloseWindow("PetBankMain", true);
		end
		if(IsWindowShow("Pet")) then
			CloseWindow("Pet", true);
		end

		--显示界面
		this:Show()
		--更新数据
		BieYePetBar_UpdateList()
	elseif ( event == "TOGLE_PETLIST_PETNUM_CHNAGE" or event == "DELETE_PET" 
			or event == "UPDATE_PET_PAGE" or event == "TOGLE_PETLIST_SELECT_CHNAGE") then
		if this:IsVisible() then
			--更新数据
			BieYePetBar_UpdateList()			
		end
	elseif ( event == "OBJECT_CARED_EVENT" ) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--关闭界面
			BieYePetBar_Close_Click()
		end	
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		--关闭界面
		BieYePetBar_Close_Click()
	-- 互斥界面
	elseif ( event == "TOGLE_PETBANK" or event == "TOGLE_PET_PAGE") then
		--关闭界面
		BieYePetBar_Close_Click()
	end
end

--清空兽栏
function BieYePetBar_ClearJYSLList()
	if CUR_JYSLPET_SIZE <= 0 or CUR_JYSLPET_SIZE > MAX_JYSLPET_NUM then
		return
	end
	
	for i=1, CUR_JYSLPET_SIZE do
		g_BieYePetBar_JYSLUIName[i].BK:Show()
		g_BieYePetBar_JYSLUIName[i].Image:Hide()
		g_BieYePetBar_JYSLUIName[i].Tu:SetProperty("Image", "");
		g_BieYePetBar_JYSLUIName[i].Name:SetText("")
		g_BieYePetBar_JYSLUIName[i].Level:SetText("")
		g_BieYePetBar_JYSLUIName[i].Train:SetText("")
		g_BieYePetBar_JYSLUIName[i].Time:SetText("")
		g_BieYePetBar_JYSLUIName[i].Exp:SetText("")
		g_BieYePetBar_JYSLUIName[i].Promote:SetText("")
		--g_BieYePetBar_JYSLUIName[i].Star:SetText("")
		g_BieYePetBar_JYSLUIName[i].TrainText:SetText("")
		g_BieYePetBar_JYSLUIName[i].TimeText:SetText("")
		g_BieYePetBar_JYSLUIName[i].ExpText:SetText("")
		g_BieYePetBar_JYSLUIName[i].PromoteText:SetText("")
		--g_BieYePetBar_JYSLUIName[i].StarText:SetText("")
		g_BieYePetBar_JYSLUIName[i].Retrieve:Hide()
		g_BieYePetBar_JYSLUIName[i].NeedLevel:Show()
		g_BieYePetBar_JYSLUIName[i].NeedLevel:SetText("#{JYSL_160518_227}")
	end
	for i=CUR_JYSLPET_SIZE+1, MAX_JYSLPET_NUM do
		g_BieYePetBar_JYSLUIName[i].BK:Hide()
		g_BieYePetBar_JYSLUIName[i].Image:Show()
	end
	
end

--更新界面
function BieYePetBar_UpdateList()
	--显示标题
	BieYePetBar_DragTitle:SetText( ScriptGlobal_Format( "#{JYSL_160518_12}", CUR_JYSL_LEVEL ) )
		
	--列表清空
	BieYePetBar_List : ClearListBox();
	BieYePetBar_ClearJYSLList()
	
	--显示珍兽数量
	local nPetCount = Pet:GetPet_Count_PetBank()
	local nIsBaiShou = Pet:GetIsBaiShou()
	if(nIsBaiShou == 1) and (nPetCount > 0) then
		BieYePetBar_Model_Proficient_Text:Show()
	else
		BieYePetBar_Model_Proficient_Text:Hide()
	end
	BieYePetBar_TheHaveList:SetText("#{JYSL_160518_14}"..nPetCount.."/"..CUR_JYPETBANK_SIZE)
		
	--不存在珍兽则详细信息清空
	if nPetCount < 1 then
		CUR_JYPETBANK_SELECT = -1;
		BieYePetBar_Model_NeedLevel:SetText(" ") --可携带
	  BieYePetBar_Model_Level:SetText(" ") --等级
		Pet_ModelObject : SetFakeObject( "" );
		BieYePetBar_ClearTypeAndJieduan()
		return
	end	
	
	--默认选中第一个有效数据
	local szCharName = Pet:GetPetList_Appoint_PetBank(CUR_JYPETBANK_SELECT);
	if szCharName == nil or szCharName ==" " then
		CUR_JYPETBANK_SELECT = Pet:GetFirstPetPosInBank_PetBank();
		--把银行背包数据更新了的操作告诉珍兽背包list
		Pet : PetBank_PetListSelectChange( tonumber(CUR_JYPETBANK_SELECT),0);
  end

	--显示银行列表（含是否提升中）
	local num =0
	local bSelect =0
	local bHasPet =0;
	--刷新列表
	for i=1, MAX_JYPETBANK_NUM do
		if 1==Pet:IsPresent_PetBank(i-1) then
			--获得名字、携带等级、等级、状态
			local	szPetName, xiedaiLevl, CurrentLevel, szOn = Pet:GetPetList_Appoint_PetBank(i-1);
			--存在珍兽
			if(szPetName~= "")then
				--当前珍兽可显示
				if ( szOn == "on_packa" ) then 
					local szPetBankName = szPetName
					local strToolTips = ""
					--兽栏特殊处理名字
					local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(i-1);
					if JYSLOperType > 0 and JYSLOperType <= 2 then
						--修改名字
						--szPetBankName = szPetBankName.."#-14";--szPetBankName..g_BieYePetBar_JYSLUIText[JYSLOperType].Name
						--strToolTips = strToolTips.."兽栏中"
						--更新兽栏内容						
						if JYSLPos > 0 and JYSLPos <= MAX_JYSLPET_NUM then
							--强制显示 针对配偶家和自己家的兽栏等级不同特殊处理 只要有珍兽就显示详细信息
							g_BieYePetBar_JYSLUIName[JYSLPos].BK:Show()
							g_BieYePetBar_JYSLUIName[JYSLPos].Image:Hide()
							--头像
							local szPortraitName = Pet:GetPetBankPortraitByIndex(i-1)
							if szPortraitName ~= nil and szPortraitName ~= "" then
								g_BieYePetBar_JYSLUIName[JYSLPos].Tu:SetProperty("Image", tostring(szPortraitName));
							end
							--名字
							if szPetName ~= nil and szPetName ~= "" then
								g_BieYePetBar_JYSLUIName[JYSLPos].Name:SetText( ScriptGlobal_Format( "#{JYSL_160518_184}", szPetName ) )
							end
							--等级
							g_BieYePetBar_JYSLUIName[JYSLPos].Level:SetText(ScriptGlobal_Format( "#{JYSL_160518_25}", CurrentLevel ))
							--提升类型及时长
							g_BieYePetBar_JYSLUIName[JYSLPos].TrainText:SetText( g_BieYePetBar_JYSLUIText[JYSLOperType].Train1 )
							if JYSLLevel > 0 and JYSLLevel <= table.getn(g_BieYePetBar_LevelSelect) then
								if JYSLOperType == 1 then
									g_BieYePetBar_JYSLUIName[JYSLPos].Train:SetText( ScriptGlobal_Format( g_BieYePetBar_JYSLUIText[JYSLOperType].Train, g_BieYePetBar_LevelSelect[JYSLLevel].msg1, JYSLOperTime ) )
								elseif JYSLOperType == 2 then
									g_BieYePetBar_JYSLUIName[JYSLPos].Train:SetText( ScriptGlobal_Format( g_BieYePetBar_JYSLUIText[JYSLOperType].Train, g_BieYePetBar_LevelSelect[JYSLLevel].msg2, JYSLOperTime ) )
								end
							end
							--提升剩余时间
							local nRemainHour, nRemainMin, nRemainSec = Pet:GetJYSLPetRemainTime(JYSLOperTime,JYSLTimeStart)
							--修改珍兽银行中名字
							if nRemainHour > 0 or nRemainMin > 0 or nRemainSec > 0 then
								szPetBankName = ScriptGlobal_Format( g_BieYePetBar_JYSLUIText[JYSLOperType].state1, szPetBankName )
							else
								szPetBankName = ScriptGlobal_Format( g_BieYePetBar_JYSLUIText[JYSLOperType].state2, szPetBankName )
							end
							--更新显示的剩余时间--剩余时间，大于等于XX分钟01秒时，按照XX+1分钟来显示--2016.08.22
							if nRemainHour > 0 then
								if nRemainSec > 0 then
									nRemainMin = nRemainMin + 1
								end
								if nRemainMin == 60 then 
									nRemainMin = 0
									nRemainHour = nRemainHour + 1
								end
							elseif nRemainMin > 0 then
								if nRemainSec > 0 then
									nRemainMin = nRemainMin + 1
								end
								if nRemainMin == 60 then 
									nRemainMin = 0
									nRemainHour = 1
								end
							elseif nRemainSec > 0 then
								nRemainMin = 1
							end
							--显示剩余时间	
							g_BieYePetBar_JYSLUIName[JYSLPos].TimeText:SetText(g_BieYePetBar_JYSLUIText[JYSLOperType].Time1)
							if nRemainHour > 0 then
								g_BieYePetBar_JYSLUIName[JYSLPos].Time:SetText(ScriptGlobal_Format( "#{JYSL_160518_79}", nRemainHour, nRemainMin))
							elseif nRemainMin > 0 then
								g_BieYePetBar_JYSLUIName[JYSLPos].Time:SetText(ScriptGlobal_Format( "#{JYSL_160518_80}", nRemainMin))
							else
								g_BieYePetBar_JYSLUIName[JYSLPos].Time:SetText(g_BieYePetBar_JYSLUIText[JYSLOperType].Finish)
							end
							--提升可获得经验
							g_BieYePetBar_JYSLUIName[JYSLPos].ExpText:SetText( g_BieYePetBar_JYSLUIText[JYSLOperType].Exp1 )
							g_BieYePetBar_JYSLUIName[JYSLPos].Exp:SetText( ScriptGlobal_Format( g_BieYePetBar_JYSLUIText[JYSLOperType].Exp, JYSLGainValue ) )
							--提升等级
							g_BieYePetBar_JYSLUIName[JYSLPos].PromoteText:SetText( g_BieYePetBar_JYSLUIText[JYSLOperType].Promote1 )
							g_BieYePetBar_JYSLUIName[JYSLPos].Promote:SetText( ScriptGlobal_Format( g_BieYePetBar_JYSLUIText[JYSLOperType].Promote, JYSLGainLevel ) )
							if JYSLOperType == 1 and CurrentLevel == JYSLGainLevel then
								g_BieYePetBar_JYSLUIName[JYSLPos].Promote:SetText( "#{JYSL_160518_228}" )
							end
							--训练档次
							--g_BieYePetBar_JYSLUIName[JYSLPos].StarText:SetText( g_BieYePetBar_JYSLUIText[JYSLOperType].Star1 )
							--g_BieYePetBar_JYSLUIName[JYSLPos].Star:SetText( ScriptGlobal_Format( g_BieYePetBar_JYSLUIText[JYSLOperType].Star, JYSLLevel ) )
							--显示取回按钮
							g_BieYePetBar_JYSLUIName[JYSLPos].NeedLevel:Hide()
							g_BieYePetBar_JYSLUIName[JYSLPos].Retrieve:Show()
							g_BieYePetBar_JYSLUIName[JYSLPos].Retrieve:SetText(g_BieYePetBar_JYSLUIText[JYSLOperType].Retrieve)
						end
					end
					--加锁特殊处理名字
					if (PlayerPackage:IsPetLock(i-1,1) == 1)  then
						local nUnlockElapsedTime = PlayerPackage:GetPUnlockElapsedTime_Pet(i-1 ,1);
						if( nUnlockElapsedTime == 0 ) then
							szPetBankName = szPetBankName.. "#-05";
							strToolTips =  "已加锁" ;
						else
							szPetBankName = szPetBankName.. "#-10";
							local strLeftTime = g_GetUnlockingStr(nUnlockElapsedTime);			
							strToolTips = strLeftTime ;
						end
					end
					--显示名字
					BieYePetBar_List:AddItem(szPetBankName, i-1);
					BieYePetBar_List:SetItemTooltip( num, strToolTips );
					num = num +1	
					--标记存在珍兽及选中情况			
					bHasPet =1
					if(i-1 == CUR_JYPETBANK_SELECT)then
					  bSelect = 1
					end
				end
			end
		end
	end
	
	--处理选中情况
	if -1<CUR_JYPETBANK_SELECT and CUR_JYPETBANK_SELECT<MAX_JYPETBANK_NUM and 1== bSelect then
	  local PetName , xiedaiLevel ,PetLevel = Pet:GetPetList_Appoint_PetBank(CUR_JYPETBANK_SELECT)
		local strNeedLevelColor = "#c00FF00"
		local nTakeLevel_BaiShou = xiedaiLevel
		local nIsBaiShou = Pet:GetIsBaiShou()
		if(nIsBaiShou == 1) then
		  nTakeLevel_BaiShou = xiedaiLevel - 10
		    if nTakeLevel_BaiShou < 1 then
			  	nTakeLevel_BaiShou = 1
		  	end
		end
		if( nTakeLevel_BaiShou > Player:GetData( "LEVEL" ) )then
		  strNeedLevelColor="#cFF0000";
		end
		BieYePetBar_ClearTypeAndJieduan()
	  if(PetName~= "")then
	  	BieYePetBar_Model_NeedLevel:SetText(strNeedLevelColor..xiedaiLevel.."#{ZSYH_120503_47}") --可携带
	  	BieYePetBar_Model_Level:SetText("#{ZSYH_120503_48}"..PetLevel) --等级
			BieYePetBar_List : SetItemSelectByItemID(CUR_JYPETBANK_SELECT);
			Pet_ModelObject : SetFakeObject( "" );
			Pet:SetModel_JYSLPetBank(CUR_JYPETBANK_SELECT);
			Pet_ModelObject :SetFakeObject( "My_JYSLPetBank" );			
			BieYePetBar_UpdateTypeAndJieduan(xiedaiLevel)	
	  else	
			BieYePetBar_List : SetItemSelectByItemID(-1);
	   	BieYePetBar_Model_NeedLevel:SetText("#c00FF00".."0".."#{ZSYH_120503_47}") --可携带
	  	BieYePetBar_Model_Level:SetText("#{ZSYH_120503_48}".."0") --等级
			Pet_ModelObject : SetFakeObject( "" );
	   end
	else
		CUR_JYPETBANK_SELECT = Pet :GetFirstPetPosInBank_PetBank();
		--把银行背包数据更新了的操作告诉珍兽背包list
		Pet : PetBank_PetListSelectChange( tonumber(CUR_JYPETBANK_SELECT),0);
		local  PetName1 , xiedaiLevel1 ,PetLevel1 = Pet:GetPetList_Appoint_PetBank(CUR_JYPETBANK_SELECT)
		local strNeedLevelColor1 = "#c00FF00"
		local nTakeLevel_BaiShou1 = xiedaiLevel1
		local nIsBaiShou1 = Pet:GetIsBaiShou()
		if(nIsBaiShou1 == 1) then
			nTakeLevel_BaiShou1 = xiedaiLevel1 - 10
			if nTakeLevel_BaiShou1 < 1 then
				nTakeLevel_BaiShou1 = 1
			end
		end
		if( nTakeLevel_BaiShou1 > Player:GetData( "LEVEL" ) )then
			strNeedLevelColor1="#cFF0000";
		end
		BieYePetBar_ClearTypeAndJieduan()
		if bHasPet ==1 and PetName1~= "" then
		 	BieYePetBar_Model_NeedLevel:SetText(strNeedLevelColor1..xiedaiLevel1.."#{ZSYH_120503_47}") --可携带
	  	BieYePetBar_Model_Level:SetText("#{ZSYH_120503_48}"..PetLevel1) --等级
			BieYePetBar_List : SetItemSelectByItemID(CUR_JYPETBANK_SELECT);
			Pet_ModelObject : SetFakeObject( "" );
			Pet : SetModel_JYSLPetBank(0); --?????????????????????????????????????????????????????????????
		  Pet_ModelObject :SetFakeObject( "My_JYSLPetBank" );
			BieYePetBar_UpdateTypeAndJieduan(xiedaiLevel1)
		else    
		  BieYePetBar_List : SetItemSelectByItemID(-1);
		  BieYePetBar_Model_NeedLevel:SetText("#c00FF00".."0".."#{ZSYH_120503_47}") --可携带
	  	BieYePetBar_Model_Level:SetText("#{ZSYH_120503_48}".."0") --等级
			Pet_ModelObject : SetFakeObject( "" );
		end
	end 
end

--清空性格和觉醒等级
function BieYePetBar_ClearTypeAndJieduan()
	BieYePetBar_Model_Type:SetText("")
	BieYePetBar_Model_Type:SetToolTip("")
	BieYePetBar_Model_Jieduan:SetText("")
	BieYePetBar_Model_Jieduan:SetToolTip("")
end

--显示性格和觉醒等级
function BieYePetBar_UpdateTypeAndJieduan(xiedaiLevel)
	if xiedaiLevel == nil or xiedaiLevel < 0 then
		return
	end
	if CUR_JYPETBANK_SELECT < 0 or CUR_JYPETBANK_SELECT >= MAX_JYPETBANK_NUM then
		return
	end	

 	local nAI = Pet:GetAIType_PetBank(CUR_JYPETBANK_SELECT)
	if nAI ~= nil and nAI >= 0 and nAI <= 4 then
		local strAI =	BIEYEPETBAR_AITYPE[nAI]
	 	BieYePetBar_Model_Type:SetText("#gFF8E92"..strAI)
		BieYePetBar_Model_Type:SetToolTip("#{INTERFACE_XML_857}")
	end

	local nJinJieGrade,nJinJieLevel = Pet:GetJinJieGradeAndLevel_PetBank(CUR_JYPETBANK_SELECT)
	if nJinJieGrade ~= nil and nJinJieGrade >= 0 and nJinJieLevel ~= nil and nJinJieLevel >= 0 then
		if xiedaiLevel < PET_JINJIE_LIMIT_BYTLVL then
			BieYePetBar_Model_Jieduan:SetText("#{JJKHD_120808_21}");
			BieYePetBar_Model_Jieduan:SetToolTip("#{JJKHD_120808_35}");
		elseif nJinJieGrade == PET_JINJIELVL_MAXGRADE then
			BieYePetBar_Model_Jieduan:SetText("#{JJKHD_120808_24}");
			BieYePetBar_Model_Jieduan:SetToolTip("#{JJKHD_120808_37}");
		elseif nJinJieGrade < PET_JINJIELVL_MAXGRADE then
			if g_NumToStrTable[nJinJieGrade + 1] ~= nil and g_NumToStrTable[nJinJieLevel + 1] ~= nil then
				local szCurJinJieInfo = ScriptGlobal_Format("#{JJKHD_120808_22}", g_NumToStrTable[nJinJieGrade + 1], g_NumToStrTable[nJinJieLevel + 1])
				BieYePetBar_Model_Jieduan:SetText(szCurJinJieInfo);
			end
			BieYePetBar_Model_Jieduan:SetToolTip("#{JJKHD_120808_36}");
		end
	end	

end

--关闭界面
function BieYePetBar_Close_Click()
	if(IsWindowShow("TargetPet")) then
		CloseWindow("TargetPet", true);
	end	
	if(IsWindowShow("TargetPet2")) then
		CloseWindow("TargetPet2", true);
	end	
	if(IsWindowShow("BieYePetBar_Train")) then
	  CloseWindow("BieYePetBar_Train", true);
	end	
	if(IsWindowShow("BieYePetBar_Tonic")) then
	  CloseWindow("BieYePetBar_Tonic", true);
	end	
	--if(IsWindowShow("BieYePetBar_Awake")) then
	  --CloseWindow("BieYePetBar_Awake", true);
	--end	
	if(IsWindowShow("BieYePetBar_List")) then
		CloseWindow("BieYePetBar_List", true);
	end
	this:Hide()
	--取消关心
	this:CareObject(objCared, 0, "BieYePetBar");
end

--旋转珍兽模型（向左)
function BieYePetBar_TurnLeft(start)
	--向左旋转开始
	if(start==1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Pet_ModelObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		Pet_ModelObject:RotateEnd();
	end
end

--旋转珍兽模型（向右)
function BieYePetBar_TurnRight(start)
	--向右旋转开始
	if( start==1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Pet_ModelObject:RotateBegin(0.3);
	--向右旋转结束
	else
		Pet_ModelObject:RotateEnd();
	end
end

--取回
function  BieYePetBar_Refuse_Click()
	if CUR_JYPETBANK_SELECT < 0 or CUR_JYPETBANK_SELECT >= MAX_JYPETBANK_NUM then
		PushDebugMessage("#{JYSL_160518_140}")--请先选中一只珍兽。
		return
	end
	
	if(IsWindowShow("TargetPet2")) then
	 	CloseWindow("TargetPet2", true)
	end	
	
	local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(CUR_JYPETBANK_SELECT)
	if JYSLOperType == 1 or JYSLOperType == 2 then--从兽栏到银行操作
		if JYSLPos <= 0 or JYSLPos > 3 then
			PushDebugMessage("#{JYSL_160518_141}")--这只珍兽没有在灵兽坊。
			return
		end	
		--取回操作
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "ClientAskShoulanOperationEnd" )
			Set_XSCRIPT_ScriptID(891939)
			Set_XSCRIPT_Parameter(0,objCared)
			Set_XSCRIPT_Parameter(1,JYSLPos)
			Set_XSCRIPT_Parameter(2,0)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()	
	else--从银行到背包操作
		--if(1~=IsWindowShow("PetBankList")) then
		 --  PushDebugMessage("珍兽列表界面已经关闭请先打开！") 
		 --  return ;
		--end
		local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(CUR_JYPETBANK_SELECT)
		if JYSLOperType > 0 then
			local msg = ""
			local nRemainHour, nRemainMin, nRemainSec = Pet:GetJYSLPetRemainTime(JYSLOperTime,JYSLTimeStart)
			if nRemainHour > 0 or nRemainMin > 0 or nRemainSec > 0 then
				if JYSLOperType == 1 then
					PushDebugMessage("#{JYSL_160518_05}")
				elseif JYSLOperType == 2 then
					PushDebugMessage("#{JYSL_160518_212}")
				end	
			else
				if JYSLOperType == 1 then
					PushDebugMessage("#{JYSL_160518_211}")
				elseif JYSLOperType == 2 then
					PushDebugMessage("#{JYSL_160518_213}")
				end	
			end		
			return
		end
		Pet:SavePetIntoBank_PetBank(CUR_JYPETBANK_SELECT,0); --银行到背包
		CUR_JYPETBANK_SELECT = Pet :GetFirstPetPosInBank_PetBank();
		--把银行背包数据更新了的操作告诉珍兽背包list
		Pet : PetBank_PetListSelectChange( tonumber(CUR_JYPETBANK_SELECT),0);
	end
	
end

--查看珍兽详细信息
function  BieYePetBar_Choose_Click()
	if  -1<CUR_JYPETBANK_SELECT  and CUR_JYPETBANK_SELECT < MAX_JYPETBANK_NUM then
		if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true);
		end
		if(IsWindowShow("TargetPet2")) then
		   CloseWindow("TargetPet2", true);
		end
		Pet:ShowTargetPet_PetBank(tonumber(CUR_JYPETBANK_SELECT))
	end
end

--list选中后的变化
function BieYePetBar_List_Selected()
  local PETNUM = 0;
	PETNUM = BieYePetBar_List :GetFirstSelectItem();
	local nPetCount = Pet : GetPet_Count_PetBank();
	if(PETNUM == CUR_JYPETBANK_SELECT) then
		return;
	end
	if(PETNUM < 0 and nPetCount > 0) then
		PETNUM = CUR_JYPETBANK_SELECT;
		return;
	end
	CUR_JYPETBANK_SELECT = PETNUM;
	
	local PetName ,TakeLevel,Level =Pet:GetPetList_Appoint_PetBank(CUR_JYPETBANK_SELECT);
	local strNeedLevelColor = "#c00FF00"
	local nTakeLevel_BaiShou = TakeLevel
	local nIsBaiShou = Pet:GetIsBaiShou()
	if(nIsBaiShou == 1) then
		nTakeLevel_BaiShou = TakeLevel - 10
	    if nTakeLevel_BaiShou < 1 then
				nTakeLevel_BaiShou = 1
			end
	end
	if( nTakeLevel_BaiShou > Player:GetData( "LEVEL" ) )then
    strNeedLevelColor="#cFF0000";
	end
	BieYePetBar_ClearTypeAndJieduan()
	if(PetName ~= "")then
		BieYePetBar_List : SetItemSelectByItemID(CUR_JYPETBANK_SELECT);
		Pet_ModelObject : SetFakeObject( "" );
		Pet : SetModel_JYSLPetBank(PETNUM);
		Pet_ModelObject : SetFakeObject( "My_JYSLPetBank" );
	  BieYePetBar_Model_NeedLevel:SetText(strNeedLevelColor..TakeLevel.."#{ZSYH_120503_47}") --可携带
	  BieYePetBar_Model_Level:SetText("#{ZSYH_120503_48}"..Level) --等级
		BieYePetBar_UpdateTypeAndJieduan(TakeLevel)
	end
	
	--	把银行背包数据更新了的操作告诉珍兽背包list
	Pet : PetBank_PetListSelectChange( tonumber(CUR_JYPETBANK_SELECT),0);

end

--list右键查看
function BieYePetBar_ShowTargetPet()
	if -1 < CUR_JYPETBANK_SELECT and CUR_JYPETBANK_SELECT < MAX_JYPETBANK_NUM then
		--关闭已打开界面
		if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true);
			return ;
		end
		--查看当前选中
		local	PETNUM = BieYePetBar_List:GetFirstSelectItem();
		if(PETNUM == CUR_JYPETBANK_SELECT) then
			if(IsWindowShow("TargetPet2")) then
				CloseWindow("TargetPet2", true);
			end	
			Pet:ShowTargetPet_PetBank(CUR_JYPETBANK_SELECT)
			return;
		end
		--未选中则选中后打开
		if(PETNUM < 0 and nPetCount > 0) then
			PETNUM = CUR_JYPETBANK_SELECT;
			return;
		end
		CUR_JYPETBANK_SELECT = PETNUM;
		if(IsWindowShow("TargetPet2")) then
		   CloseWindow("TargetPet2", true);
		end
	  Pet:ShowTargetPet_PetBank(CUR_JYPETBANK_SELECT)
	end
end

--训练1、滋补2、觉醒3操作
function BieYePetBar_Promote_Click(nType)
	if nType == nil or nType <= 0 or nType > 2 then
		return
	end
	
	local nPetCount = Pet:GetPet_Count_PetBank()
	if nPetCount == nil or nPetCount <= 0 then
		PushDebugMessage("#{JYSL_160518_45}")
		if nType == 1 then
			PushDebugMessage("#{JYSL_160518_234}")
		elseif nType == 2 then
			PushDebugMessage("#{JYSL_160518_235}")
		end
		return
	end
	
	if CUR_JYPETBANK_SELECT < 0 or CUR_JYPETBANK_SELECT >= MAX_JYPETBANK_NUM then
		PushDebugMessage("#{JYSL_160518_46}")
		return
	end

	--提升操作
	local petGuidH,petGuidL = Pet:GetPetGUIDByIndex_PetBank(CUR_JYPETBANK_SELECT)
	if petGuidH == nil or petGuidL == nil then
		PushDebugMessage("#{JYSL_160518_46}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientAskShoulanOperationBegin" )
		Set_XSCRIPT_ScriptID(891939)
		Set_XSCRIPT_Parameter(0,objCared)
		Set_XSCRIPT_Parameter(1,nType)
		Set_XSCRIPT_Parameter(2,petGuidH)
		Set_XSCRIPT_Parameter(3,petGuidL)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end

--取回操作：nIndex代表哪个兽栏
function BieYePetBar_Retrieve_Click(nIndex)
	if nIndex == nil or nIndex <= 0 or nIndex > 3 then
		return
	end
	
	--取回操作
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ClientAskShoulanOperationEnd" )
		Set_XSCRIPT_ScriptID(891939)
		Set_XSCRIPT_Parameter(0,objCared)
		Set_XSCRIPT_Parameter(1,nIndex)
		Set_XSCRIPT_Parameter(2,0)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	

end