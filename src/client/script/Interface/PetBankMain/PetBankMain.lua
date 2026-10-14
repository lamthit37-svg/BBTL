-------------------------------------------------------

--作     者：黄运洪

---创建时间： 2012-05-03

---功能：珍兽银行脚本

---修改：无

--Kevin add by petbank 2012-04-28


-----------------------------------------------------------

local PETBANK_CURRENT_SELECT = 0; --当前选中
local PETBANK_MAX_COUNT  =10 ;--银行容器的大小
local PETBANK_CURRENT_NUM =0; --银行现在存储量
local PETBANKMAX_CURRNET_SIZE =0 ;--当前珍兽银行的最大size
local MAX_OBJ_DISTANCE = 3.0;
local objCared = -1;

local PETBANK_AITYPE = {};

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

function PetBankMain_PreLoad()
	this:RegisterEvent("TOGLE_PETBANK"); --打开珍兽银行界面事件
	this:RegisterEvent("TOGLE_PETLIST_PETNUM_CHNAGE");
	this:RegisterEvent("TOGLE_PET_PAGE"); --更新选中事件
	--this:RegisterEvent("TOGLE_GETBANKSIZE_PETBANK"); --更新选中事件 
	this:RegisterEvent("OBJECT_CARED_EVENT",false); --界面敏感事件
	this:RegisterEvent("UPDATE_PET_PAGE");
	this:RegisterEvent("PLAYER_LEAVE_WORLD")	--进入场景关闭界面
end


function PetBankMain_OnLoad()

	PETBANK_AITYPE[0] = "胆小";
	PETBANK_AITYPE[1] = "谨慎";
	PETBANK_AITYPE[2] = "忠诚";
	PETBANK_AITYPE[3] = "精明";
	PETBANK_AITYPE[4] = "勇猛";

end

function PetBankMain_OnEvent(event)
     -- PushDebugMessage("event".. "  "..event) 
        if ( event == "TOGLE_PETBANK" ) then--打开珍兽银行界面事件
		local nMaxbanksize = tonumber(arg2)
  	 	if nMaxbanksize ~= nil and 0 < nMaxbanksize and nMaxbanksize <= 10 then
  	 	  PETBANKMAX_CURRNET_SIZE = nMaxbanksize
  	 	end
		local openpetbank = tonumber(arg3)
		if openpetbank ~= nil and openpetbank < 1 then
		return ;
		end
		 if(IsWindowShow("PetBankMain")) then
		  CloseWindow("PetBankMain", true);
		 end
		 if(IsWindowShow("VIP_Shop")) then
		  CloseWindow("VIP_Shop", true);
		 end
		 if(IsWindowShow("YouLongKa2")) then
		  CloseWindow("YouLongKa2", true);
		 end
			--关闭已打开界面
			if(IsWindowShow("TargetPet")) then
				CloseWindow("TargetPet", true);
			end	
			if(IsWindowShow("TargetPet2")) then
				CloseWindow("TargetPet2", true);
			end
			if(IsWindowShow("Pet")) then
				CloseWindow("Pet", true);
			end	
			if(IsWindowShow("BieYePetBar")) then
				CloseWindow("BieYePetBar", true);
			end	
			if(IsWindowShow("BieYePetBar_Awake")) then
			  CloseWindow("BieYePetBar_Awake", true);
			end
			
			if IsWindowShow("PetLianHua") then
			  CloseWindow("PetLianHua", true)
			end
			 
		 objCared = Bank:GetNpcId(); --套用bank的数据
		 this:CareObject(objCared, 1, "PetBankMain");
		 PetBankMain_UpDataPetList()
		 this:Show()
		 
		 	--关心商人Obj
		if( 0 > objCared ) then
			--Shop_Text:SetText("#{VIPTQ_110908_11}");	--先这样吧，有问题再修
			
			PetBankMain_Watch_Text:SetText("#{VIPTQ3_120517_29}")
			PetBankMain_StopWatch:SetProperty("Timer", tostring(5*60))
			PetBankMain_StopWatch:SetProperty("TextColor", "FF00FF00")
			PetBankMain_Watch_Text:Show()
			PetBankMain_StopWatch:Show()
		else
			PetBankMain_Watch_Text:Hide()
			PetBankMain_StopWatch:Hide()
		end
	elseif( event == "TOGLE_PETLIST_PETNUM_CHNAGE" ) then--打开珍兽银行界面事件
	 	PetBankMain_UpDataPetList();
	elseif( event == "UPDATE_PET_PAGE" ) then
	 	PetBankMain_UpDataPetList();
	elseif( event == "TOGLE_PET_PAGE" ) then--打开珍兽银行界面事件
	 	local nSelectArg0 = tonumber(arg0)
	 	local nPetCount = Pet:GetPet_Count_PetBank()
	 	if 0<=nSelectArg0  and nSelectArg0 < nPetCount then
	 	   PETBANK_CURRENT_SELECT = nSelectArg0
	 	end
	 	--elseif( event == "TOGLE_GETBANKSIZE_PETBANK" ) then--更新银行的大小
	 	--  local nPetBankSizeArg1 = tonumber(arg1)
  		--if nPetBankSizeArg1~=nil and 0< nPetBankSizeArg1 then
  		 -- PETBANKMAX_CURRNET_SIZE = nPetBankSizeArg1
  		--end
        elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			CloseWindow("PetBankMain", true);
			--取消关心
			this:CareObject(objCared, 0, "PetBankMain");
		end
		-------------------------------------------------------
	elseif (event == "PLAYER_LEAVE_WORLD") then
		PetBankMain_Close_Click()
	end
end



function PetBankMain_OnShown()

end

function PetBankMain_OnHidden()

end

--!!!reloadscript =PetBankMain
function PetBankMain_UpDataPetList()

	PetBankMain_List : ClearListBox();
	local nPetCount = Pet:GetPet_Count_PetBank()
	local nIsBaiShou = Pet:GetIsBaiShou()
	if(nIsBaiShou == 1) and (nPetCount > 0) then
		PetBankMain_Proficient_Text:Show()
	else
		PetBankMain_Proficient_Text:Hide()
	end
	PetBankMain_TheHaveList:SetText("#{ZSYH_120503_18}"..nPetCount.."/"..PETBANKMAX_CURRNET_SIZE) --ZSYH_120503_18 可存珍兽
	if nPetCount < 1 then
		PETBANK_CURRENT_SELECT = -1;
		PetBankMain_NeedLevel:SetText(" ") --可携带
	        PetBankMain_Level:SetText(" ") --等级
		PetBankMain_FakeObject : SetFakeObject( "" );
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_170}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_151}")				
		PetBankMain_ClearTypeAndJieduan()
		return;
	else 
	   local szCharName = Pet:GetPetList_Appoint_PetBank(PETBANK_CURRENT_SELECT);
	   if szCharName ==" " or szCharName ==nil then
		PETBANK_CURRENT_SELECT = Pet :GetFirstPetPosInBank_PetBank();
		--把银行背包数据更新了的操作告诉珍兽背包list
		Pet : PetBank_PetListSelectChange( tonumber(PETBANK_CURRENT_SELECT),0);
	   end
	    
	end
	--if PETBANK_CURRENT_SELECT < 0 then
	--  return;
--	end
	local num =0
	local bSelect =0
	local bHasPet =0;
	 local strToolTips = "";
	for i=1, PETBANK_MAX_COUNT do
			if 1==Pet:IsPresent_PetBank(i-1) then
				local	szPetName, xiedaiLevl,CurrentLevel,szOn = Pet:GetPetList_Appoint_PetBank(i-1);
				--兽栏特殊处理名字
				local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(i-1);
				if(szPetName~= "")then
				  	-- 珍兽不在背包里
					if ( szOn == "on_packa" ) then 
					        if (PlayerPackage:IsPetLock(i-1,1) == 1)  then
							local nRemainHour, nRemainMin, nRemainSec = Pet:GetJYSLPetRemainTime(JYSLOperTime,JYSLTimeStart)
							if nRemainHour > 0 or nRemainMin > 0 or nRemainSec > 0 then
								if JYSLOperType == 1 then
									szPetName = ScriptGlobal_Format( "#{JYSL_160518_09}", szPetName )
								elseif JYSLOperType == 2 then
									szPetName = ScriptGlobal_Format( "#{JYSL_160518_10}", szPetName )
								end	
							else
								if JYSLOperType == 1 then
									szPetName = ScriptGlobal_Format( "#{JYSL_160518_81}", szPetName )
								elseif JYSLOperType == 2 then
									szPetName = ScriptGlobal_Format( "#{JYSL_160518_82}", szPetName )
								end	
							end	
							local nUnlockElapsedTime = PlayerPackage:GetPUnlockElapsedTime_Pet(i-1 ,1);
							if( nUnlockElapsedTime == 0 ) then
								szPetName = szPetName.. "#-05";
								strToolTips =  "已加锁" ;
							else
								szPetName = szPetName.. "#-10";
								local strLeftTime = g_GetUnlockingStr(nUnlockElapsedTime);			
								strToolTips = strLeftTime ;
							end	
							PetBankMain_List:AddItem(szPetName, i-1);
							PetBankMain_List:SetItemTooltip( num, strToolTips );
							num = num +1
					        else
							local nRemainHour, nRemainMin, nRemainSec = Pet:GetJYSLPetRemainTime(JYSLOperTime,JYSLTimeStart)
							if nRemainHour > 0 or nRemainMin > 0 or nRemainSec > 0 then
								if JYSLOperType == 1 then
									szPetName = ScriptGlobal_Format( "#{JYSL_160518_09}", szPetName )
								elseif JYSLOperType == 2 then
									szPetName = ScriptGlobal_Format( "#{JYSL_160518_10}", szPetName )
								end	
							else
								if JYSLOperType == 1 then
									szPetName = ScriptGlobal_Format( "#{JYSL_160518_81}", szPetName )
								elseif JYSLOperType == 2 then
									szPetName = ScriptGlobal_Format( "#{JYSL_160518_82}", szPetName )
								end	
							end	
							PetBankMain_List : AddItem(szPetName, i-1);
							num = num +1
						end
						bHasPet =1
						if(i-1 ==  PETBANK_CURRENT_SELECT)then
						  bSelect =1
						end
					end
				 end
		         end
	end
	
	-- PushDebugMessage("num " .." " ..num ) --请选择要取出的珍兽
	if  -1<PETBANK_CURRENT_SELECT  and PETBANK_CURRENT_SELECT < PETBANK_MAX_COUNT and 1== bSelect then
	  local PetName , xiedaiLevel ,PetLevel = Pet:GetPetList_Appoint_PetBank(PETBANK_CURRENT_SELECT)
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
		PetBankMain_ClearTypeAndJieduan()
	  if(PetName~= "")then
	  	PetBankMain_NeedLevel:SetText(strNeedLevelColor..xiedaiLevel.."#{ZSYH_120503_47}") --ZSYH_120503_18  可携带
	  	PetBankMain_Level:SetText("#{ZSYH_120503_48}"..PetLevel) --等级
		PetBankMain_List : SetItemSelectByItemID(PETBANK_CURRENT_SELECT);
		PetBankMain_FakeObject : SetFakeObject( "" );
		Pet : SetModel_PetBank(PETBANK_CURRENT_SELECT);
		PetBankMain_FakeObject :SetFakeObject( "My_PetBank" );
		PetBankMain_UpdateTypeAndJieduan(xiedaiLevel)	
			local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(PETBANK_CURRENT_SELECT);
			if JYSLOperType == 1 then
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_166}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_167}")
			elseif JYSLOperType == 2 then
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_168}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_169}")
			else
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_170}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_151}")				
			end
		else	
		PetBankMain_List : SetItemSelectByItemID(-1);
	   	PetBankMain_NeedLevel:SetText("#c00FF00".."0".."#{ZSYH_120503_47}") --可携带
	  	PetBankMain_Level:SetText("#{ZSYH_120503_48}".."0") --等级
		PetBankMain_FakeObject : SetFakeObject( "" );
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_170}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_151}")				
	   end
	 else
		PETBANK_CURRENT_SELECT = Pet :GetFirstPetPosInBank_PetBank();
		--把银行背包数据更新了的操作告诉珍兽背包list
		Pet : PetBank_PetListSelectChange( tonumber(PETBANK_CURRENT_SELECT),0);
		local  PetName1 , xiedaiLevel1 ,PetLevel1 = Pet:GetPetList_Appoint_PetBank(PETBANK_CURRENT_SELECT)
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
		PetBankMain_ClearTypeAndJieduan()
		if bHasPet ==1 and PetName1~= "" then
		      	PetBankMain_NeedLevel:SetText(strNeedLevelColor1..xiedaiLevel1.."#{ZSYH_120503_47}") --ZSYH_120503_18  可携带
	  		PetBankMain_Level:SetText("#{ZSYH_120503_48}"..PetLevel1) --等级
			PetBankMain_List : SetItemSelectByItemID(PETBANK_CURRENT_SELECT);
			PetBankMain_FakeObject : SetFakeObject( "" );
			Pet : SetModel_PetBank(0); 
		        PetBankMain_FakeObject :SetFakeObject( "My_PetBank" );
			PetBankMain_UpdateTypeAndJieduan(xiedaiLevel1)	
			local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(PETBANK_CURRENT_SELECT);
			if JYSLOperType == 1 then
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_166}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_167}")
			elseif JYSLOperType == 2 then
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_168}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_169}")
			else
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_170}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_151}")				
			end		       
		else    
		        PetBankMain_List : SetItemSelectByItemID(-1);
		   	PetBankMain_NeedLevel:SetText("#c00FF00".."0".."#{ZSYH_120503_47}") --可携带
	  		PetBankMain_Level:SetText("#{ZSYH_120503_48}".."0") --等级
			PetBankMain_FakeObject : SetFakeObject( "" );
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_170}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_151}")				
		end
	 end 
	
	  --
end

--清空性格和觉醒等级
function PetBankMain_ClearTypeAndJieduan()
	PetBankMain_Type:SetText("")
	PetBankMain_Type:SetToolTip("")
	PetBankMain_Jieduan:SetText("")
	PetBankMain_Jieduan:SetToolTip("")
end

--显示性格和觉醒等级
function PetBankMain_UpdateTypeAndJieduan(xiedaiLevel)
	if xiedaiLevel == nil or xiedaiLevel < 0 then
		return
	end
	if PETBANK_CURRENT_SELECT < 0 or PETBANK_CURRENT_SELECT >= PETBANK_MAX_COUNT then
		return
	end	

 	local nAI = Pet:GetAIType_PetBank(PETBANK_CURRENT_SELECT)
	if nAI ~= nil and nAI >= 0 and nAI <= 4 then
		local strAI =	PETBANK_AITYPE[nAI]
	 	PetBankMain_Type:SetText("#gFF8E92"..strAI)
		PetBankMain_Type:SetToolTip("#{INTERFACE_XML_857}")
	end

	local nJinJieGrade,nJinJieLevel = Pet:GetJinJieGradeAndLevel_PetBank(PETBANK_CURRENT_SELECT)
	if nJinJieGrade ~= nil and nJinJieGrade >= 0 and nJinJieLevel ~= nil and nJinJieLevel >= 0 then
		if xiedaiLevel < PET_JINJIE_LIMIT_BYTLVL then
			PetBankMain_Jieduan:SetText("#{JJKHD_120808_21}");
			PetBankMain_Jieduan:SetToolTip("#{JJKHD_120808_35}");
		elseif nJinJieGrade == PET_JINJIELVL_MAXGRADE then
			PetBankMain_Jieduan:SetText("#{JJKHD_120808_24}");
			PetBankMain_Jieduan:SetToolTip("#{JJKHD_120808_37}");
		elseif nJinJieGrade < PET_JINJIELVL_MAXGRADE then
			if g_NumToStrTable[nJinJieGrade + 1] ~= nil and g_NumToStrTable[nJinJieLevel + 1] ~= nil then
				local szCurJinJieInfo = ScriptGlobal_Format("#{JJKHD_120808_22}", g_NumToStrTable[nJinJieGrade + 1], g_NumToStrTable[nJinJieLevel + 1])
				PetBankMain_Jieduan:SetText(szCurJinJieInfo);
			end
			PetBankMain_Jieduan:SetToolTip("#{JJKHD_120808_36}");
		end
	end	

end

--
-- 旋转珍兽模型（向左)
--
function PetBankMain_TurnLeft(start)
	--向左旋转开始
	if(start==1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		PetBankMain_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		PetBankMain_FakeObject:RotateEnd();
	end
end

------------------------------------------------------------------------------------
----
--旋转珍兽模型（向右)
--
function PetBankMain_TurnRight(start)
	--向右旋转开始
	if( start==1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		PetBankMain_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		PetBankMain_FakeObject:RotateEnd();
	end
end

--
--从兽栏到银行操作 从银行到背包操作
function PetBankMain_Refuse_Click()
	if PETBANK_CURRENT_SELECT < 0 or PETBANK_CURRENT_SELECT >= PETBANK_MAX_COUNT then
		PushDebugMessage("#{JYSL_160518_140}")--请先选中一只珍兽。
		return
	end
	
	if(IsWindowShow("TargetPet2")) then
	 	CloseWindow("TargetPet2", true);
	end	
	
	local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(PETBANK_CURRENT_SELECT);
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
		local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(PETBANK_CURRENT_SELECT);
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
		Pet:SavePetIntoBank_PetBank(PETBANK_CURRENT_SELECT,0); --银行到背包
		 PETBANK_CURRENT_SELECT = Pet :GetFirstPetPosInBank_PetBank();
		--把银行背包数据更新了的操作告诉珍兽背包list
		Pet : PetBank_PetListSelectChange( tonumber(PETBANK_CURRENT_SELECT),0);
	end
	
end

--
--
--查看珍兽详细信息
function  PetBankMain_Choose_Click()
	if  -1<PETBANK_CURRENT_SELECT  and PETBANK_CURRENT_SELECT < PETBANK_MAX_COUNT then
		if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true);
		-- return;
		end
		if(IsWindowShow("TargetPet2")) then
		   CloseWindow("TargetPet2", true);
		end
		Pet:ShowTargetPet_PetBank(tonumber(PETBANK_CURRENT_SELECT))
	end
end


--关闭珍兽银行界面
function PetBankMain_Close_Click()
	 this:Hide()
	 if(IsWindowShow("PetBankList")) then
		CloseWindow("PetBankList", true);
		--return;
	 end
	 if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true);
		--return;
	end
	
	if(IsWindowShow("TargetPet2")) then
			CloseWindow("TargetPet2", true);
	--	return;
	end
	
	 --取消关心
		this:CareObject(objCared, 0, "PetBankMain");
end



--list选中后的变化
function PetBankMain_List_Selected()
 local PETNUM = 0;
	PETNUM = PetBankMain_List :GetFirstSelectItem();
	local nPetCount = Pet : GetPet_Count_PetBank();
	if(PETNUM == PETBANK_CURRENT_SELECT) then
		return;
	end
	if(PETNUM < 0 and nPetCount > 0) then
		PETNUM = PETBANK_CURRENT_SELECT;
		return;
	end
	PETBANK_CURRENT_SELECT = PETNUM;
	local PetName ,TakeLevel,Level =Pet:GetPetList_Appoint_PetBank(PETBANK_CURRENT_SELECT);
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
	PetBankMain_ClearTypeAndJieduan()
	 if(PetName~= "")then
		PetBankMain_List : SetItemSelectByItemID(PETBANK_CURRENT_SELECT);
		PetBankMain_FakeObject : SetFakeObject( "" );
		Pet : SetModel_PetBank(PETNUM);
		PetBankMain_FakeObject : SetFakeObject( "My_PetBank" );
		--PetBankMain_NeedLevel:SetText(TakeLevel .."#{ZSYH_120503_47}") --携带等级
		PetBankMain_NeedLevel:SetText(strNeedLevelColor..TakeLevel.."#{ZSYH_120503_47}") --ZSYH_120503_18  可携带
		PetBankMain_Level:SetText("#{ZSYH_120503_48}"..Level)   --等级
		PetBankMain_UpdateTypeAndJieduan(TakeLevel)
			local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(PETBANK_CURRENT_SELECT);
			if JYSLOperType == 1 then
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_166}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_167}")
			elseif JYSLOperType == 2 then
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_168}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_169}")
			else
				PetBankMain_Refuse_Button:SetText("#{JYSL_160518_170}")
				PetBankMain_Refuse_Button:SetToolTip("#{JYSL_160518_151}")				
			end
	end
	--	把银行背包数据更新了的操作告诉珍兽背包list
	Pet : PetBank_PetListSelectChange( tonumber(PETBANK_CURRENT_SELECT),0);

end



--list右键查看
function PetBankMain_ShowTargetPet()
if  -1<PETBANK_CURRENT_SELECT  and PETBANK_CURRENT_SELECT < PETBANK_MAX_COUNT then
		if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true);
		return ;
	end
	local	PETNUM = PetBankMain_List:GetFirstSelectItem();
	if(PETNUM == PETBANK_CURRENT_SELECT) then
		   if(IsWindowShow("TargetPet2")) then
			CloseWindow("TargetPet2", true);
		   end	
		   Pet:ShowTargetPet_PetBank(PETBANK_CURRENT_SELECT)
		   return;
	 end

	if(PETNUM < 0 and nPetCount > 0) then
		PETNUM = PETBANK_CURRENT_SELECT;
		return;
	end
	PETBANK_CURRENT_SELECT = PETNUM;
	if(IsWindowShow("TargetPet2")) then
	   CloseWindow("TargetPet2", true);
	end
	  Pet:ShowTargetPet_PetBank(PETBANK_CURRENT_SELECT)
	end
end



--打开珍兽列表
function PetBankMain_OpenBagList_Click()

	if(IsWindowShow("PetBankList")) then
	  CloseWindow("PetBankList", true);
	   return;
	end
	OpenWindow( "PetBankList" );
end


function PetBank_StopWatch_TimeOut()
	PetBankMain_Close_Click()
	PushDebugMessage("#{VIPTQ3_120517_28}")
end
