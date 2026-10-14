--暗器金翅翎羽重洗连击技能界面逻辑（客户端）
local MAX_OBJ_DISTANCE = 3.0;
local objCared = -1;
local g_Object = -1;
local g_CommandType = 1
local g_Dark_Bag_Index = -1
local g_Mainitem = 10155008
local g_ToLingYuCost = 50000
local g_skillDes = {"#{AQJJ_160127_124}","#{AQJJ_160127_125}","#{AQJJ_160127_126}","#{AQJJ_160127_127}","#{AQJJ_160127_128}"}
local g_proDes = {"#{AQJJ_160127_147}", "#{AQJJ_160127_148}", "#{AQJJ_160127_149}", "#{AQJJ_160127_150}", "#{ZZZB_150811_182}"}
local g_skillState = 0

local g_AutoSkill_TimerID = -1
local g_AutoSkillCount = 0


local g_icon_skilltype =
{
   [1] = "set:UIIcons image:Ice_Repellency_Normal",
   [2] = "set:UIIcons image:Fire_Repellency_Normal",
   [3] = "set:UIIcons image:Thunder_Repellency_Normal",
   [4] = "set:UIIcons image:Poison_Repellency_Normal",
   [5] = "set:UIIcons image:Hurt_Repellency_Normal",
}

function AnqiChongxi_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("UPDATE_ANQICHONGXI")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("LYDARK_SKILL_REFRESH")
	this:RegisterEvent("DARK_SKILL_RECOIN_CONFIRM_OK")
	this:RegisterEvent("AQLY_FLASH_COMFIRMOK")
end

function AnqiChongxi_OnLoad()
	
	AnqiChongxi_List1:AddTextItem("#{AQJJ_160127_181}" ,0)
	AnqiChongxi_List1:AddTextItem("#{AQJJ_160127_182}" ,1)
	AnqiChongxi_List1:AddTextItem("#{AQJJ_160127_183}" ,2)
	AnqiChongxi_List1:AddTextItem("#{AQJJ_160127_184}" ,3)
	AnqiChongxi_List1:AddTextItem("#{AQJJ_160127_185}" ,4)
	AnqiChongxi_List1:AddTextItem("#{AQJJ_160127_198}" ,5)
	AnqiChongxi_List1:SetCurrentSelect(0)
		
	AnqiChongxi_Zidong:SetText("#{AQJJ_160127_186}")
		
	AnqiChongxi_querengoumaiBind:SetProperty("Selected", "True")
end

function AnqiChongxi_OnEvent(event)
	if (event == "AQLY_FLASH_COMFIRMOK" and this:IsVisible()) then
		AnqiChongxi_Auto_ClickedOK()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 8000342) then
		if g_AutoSkill_TimerID >= 0 then
				--关闭暗器自动重洗
				AnqiChongxi_CloseAutoFlash()
		end
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 8000343) then
		local str2, nIndex2 = AnqiChongxi_List1:GetCurrentSelect()
		PushEvent("AQLY_FLASH_COMFIRM",nIndex2 - 1)
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 800034) then
		g_CommandType = Get_XParam_INT(0)
		
		if this:IsVisible() then									-- 如果界面开着，则不处理
			AnqiChongxi_Close()
		end

		objCared = -1;
		local tempID = Get_XParam_INT(1);
		objCared = DataPool : GetNPCIDByServerID(tempID);

		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end

		AnqiChongxi_BeginCareObject(objCared)

		
		if g_CommandType == 11 then
			AnqiChongxi_InitDlg()
		end
	elseif (event == "UPDATE_ANQICHONGXI" and this:IsVisible()) then
		if arg0~= nil then
			AnqiChongxi_Update(arg0)
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			AnqiChongxi_Close()
		end
	elseif( (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and this:IsVisible()) then
		AnqiChongxi_UpdateMoneyDisp()
	elseif(event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible())then
		if(tonumber(arg0) == 174) then
			AnqiChongxi_Resume()
		end
	elseif (event == "LYDARK_SKILL_REFRESH") then
		AnqiChongxi_UpdateSkillDesc()
	elseif (event == "DARK_SKILL_RECOIN_CONFIRM_OK") then
		if tonumber(arg1) == 3 then
			AnqiChongxi_Close()
		end
	elseif(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil then
			if (g_Dark_Bag_Index == tonumber(arg0)) then
				DataPool:CleanLYDarkFreashSkillType()
				AnqiChongxi_UpdateSkillDesc()
			end
		end
	end
end

function AnqiChongxi_UpdateSkillDesc()
	local curDes1 = ""
	local curDes2 = ""
	local curDes3 = ""
	local curDes4 = ""
	local curDes5 = ""

	local curIcon1 = ""
	local curIcon2 = ""
	local curIcon3 = ""
	local curIcon4 = ""
	local curIcon5 = ""

	local reDes1 = ""
	local reDes2 = ""
	local reDes3 = ""
	local reDes4 = ""
	local reDes5 = ""

	local reIcon1 = ""
	local reIcon2 = ""
	local reIcon3 = ""
	local reIcon4 = ""
	local reIcon5 = ""

	local starAddPersent = 0
	local skillPersent,cuiduPersent = DataPool : GetLYDarkStarAddDataInBag(g_Dark_Bag_Index)
	if skillPersent ~= nil and skillPersent ~= -1 and cuiduPersent ~= nil and cuiduPersent ~= -1 then
		starAddPersent = skillPersent
	end
	if g_Dark_Bag_Index ~= -1 then
		local skid1,skid2,skid3,skid4,skid5 = DataPool:GetLYDarkSkillType(g_Dark_Bag_Index)
		if skid1 >= 0 and skid1 <= 4 then
			curDes1 = ScriptGlobal_Format(g_skillDes[1],10,starAddPersent,g_proDes[skid1+1])
			curIcon1 = g_icon_skilltype[skid1+1]
		end

		if skid2 >= 0 and skid2 <= 4 then
			curDes2 = ScriptGlobal_Format(g_skillDes[2],12,starAddPersent,g_proDes[skid2+1])
			curIcon2 = g_icon_skilltype[skid2+1]
		end

		if skid3 >= 0 and skid3 <= 4 then
			curDes3 = ScriptGlobal_Format(g_skillDes[3],15,starAddPersent,g_proDes[skid3+1])
			curIcon3 = g_icon_skilltype[skid3+1]
		end

		if skid4 >= 0 and skid4 <= 4 then
			curDes4 = ScriptGlobal_Format(g_skillDes[4],20,starAddPersent,g_proDes[skid4+1])
			curIcon4 = g_icon_skilltype[skid4+1]
		end

		if skid5 >= 0 and skid5 <= 4 then
			curDes5 = ScriptGlobal_Format(g_skillDes[5],30,starAddPersent,g_proDes[skid5+1])
			curIcon5 = g_icon_skilltype[skid5+1]
		end

		local rskid1,rskid2,rskid3,rskid4,rskid5 = DataPool:GetLYDarkFreashSkillType(g_Dark_Bag_Index)
		--PushDebugMessage("" .. rskid1 .. "," .. rskid2 .. "," .. rskid3 .. "," .. rskid4 .. ","  .. rskid5)
		if rskid1 >= 0 and rskid1 <= 4 then
			reDes1 = ScriptGlobal_Format(g_skillDes[1],10,starAddPersent,g_proDes[rskid1+1])
			reIcon1 = g_icon_skilltype[rskid1+1]
		end

		if rskid2 >= 0 and rskid2 <= 4 then
			reDes2 = ScriptGlobal_Format(g_skillDes[2],12,starAddPersent,g_proDes[rskid2+1])
			reIcon2 = g_icon_skilltype[rskid2+1]
		end

		if rskid3 >= 0 and rskid3 <= 4 then
			reDes3 = ScriptGlobal_Format(g_skillDes[3],15,starAddPersent,g_proDes[rskid3+1])
			reIcon3 = g_icon_skilltype[rskid3+1]
		end

		if rskid4 >= 0 and rskid4 <= 4 then
			reDes4 = ScriptGlobal_Format(g_skillDes[4],20,starAddPersent,g_proDes[rskid4+1])
			reIcon4 = g_icon_skilltype[rskid4+1]
		end

		if rskid5 >= 0 and rskid5 <= 4 then
			reDes5 = ScriptGlobal_Format(g_skillDes[5],30,starAddPersent,g_proDes[rskid5+1])
			reIcon5 = g_icon_skilltype[rskid5+1]
		end
		if rskid1 >= 0 and rskid1 <= 4 and
			rskid2 >= 0 and rskid2 <= 4 and
			rskid3 >= 0 and rskid3 <= 4 and
			rskid4 >= 0 and rskid4 <= 4 and
			rskid5 >= 0 and rskid5 <= 4 then
			AnqiChongxi_Frame_Button:Enable()
			g_skillState = 1
		else
			AnqiChongxi_Frame_Button:Disable()
			g_skillState = 0
		end

	end
	AnqiChongxi_Frame_Bk1_Text1_2 : SetText(curDes1)
	AnqiChongxi_Frame_Bk1_Text1_3 : SetText(curDes2)
	AnqiChongxi_Frame_Bk1_Text1_4 : SetText(curDes3)
	AnqiChongxi_Frame_Bk1_Text1_5 : SetText(curDes4)
	AnqiChongxi_Frame_Bk1_Text1_6 : SetText(curDes5)

	AnqiChongxi_Frame_Bk2_Text1_2 : SetText(reDes1)
	AnqiChongxi_Frame_Bk2_Text1_3 : SetText(reDes2)
	AnqiChongxi_Frame_Bk2_Text1_4 : SetText(reDes3)
	AnqiChongxi_Frame_Bk2_Text1_5 : SetText(reDes4)
	AnqiChongxi_Frame_Bk2_Text1_6 : SetText(reDes5)

	--图标
	AnqiChongxi_Frame_Bk1_Btn1_1:SetProperty("Image", curIcon1)
	AnqiChongxi_Frame_Bk1_Btn2_1:SetProperty("Image", curIcon2)
	AnqiChongxi_Frame_Bk1_Btn3_1:SetProperty("Image", curIcon3)
	AnqiChongxi_Frame_Bk1_Btn4_1:SetProperty("Image", curIcon4)
	AnqiChongxi_Frame_Bk1_Btn5_1:SetProperty("Image", curIcon5)

	AnqiChongxi_Frame_Bk2_Btn1_1:SetProperty("Image", reIcon1)
	AnqiChongxi_Frame_Bk2_Btn2_1:SetProperty("Image", reIcon2)
	AnqiChongxi_Frame_Bk2_Btn3_1:SetProperty("Image", reIcon3)
	AnqiChongxi_Frame_Bk2_Btn4_1:SetProperty("Image", reIcon4)
	AnqiChongxi_Frame_Bk2_Btn5_1:SetProperty("Image", reIcon5)
end

function AnqiChongxi_UpdateMoneyDisp()
	if g_Dark_Bag_Index ~= -1 then
		local playerMoney = Player:GetData("MONEY");
		local playerMoneyJZ = Player:GetData("MONEY_JZ");
		AnqiChongxi_DemandMoney:SetProperty("MoneyNumber", g_ToLingYuCost);
		AnqiChongxi_SelfJiaozi:SetProperty("MoneyNumber", playerMoneyJZ);
		AnqiChongxi_SelfMoney:SetProperty("MoneyNumber", playerMoney);
	end
end

function AnqiChongxi_InitDlg()
	--重洗暗器技能
	AnqiChongxi_Reset()
	AnqiChongxi_DemandMoney:SetProperty("MoneyNumber", 0)
	AnqiChongxi_SelfJiaozi:SetProperty("MoneyNumber", 0)
	AnqiChongxi_SelfMoney:SetProperty("MoneyNumber", 0)
	AnqiChongxi_querengoumaiBind:SetProperty("Selected", "True")
	this:Show()
end

--重洗按钮回调
function AnqiChongxi_OK_Clicked()
	--请先放入暗器。
	if (g_Dark_Bag_Index == -1) then
		PushDebugMessage("#{CXYH_140813_16}")
		return
	end

	local EquipPoint = LifeAbility : Get_Equip_Point(g_Dark_Bag_Index)
	if (EquipPoint ~= 17) then
		PushDebugMessage("#{AQJJ_160127_47}")
		return
	end

	local sCheck = AnqiChongxi_querengoumaiBind : GetProperty("Selected")
	local nCheck = 0
	if sCheck == "False" or sCheck == "false" then
		nCheck = 0
	elseif sCheck == "True" or sCheck == "true" then
		nCheck = 1
	end
	--暗器重洗
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("LingyuSkillReset")
		Set_XSCRIPT_ScriptID(260001)
		Set_XSCRIPT_Parameter(0,g_Dark_Bag_Index)
		Set_XSCRIPT_Parameter(1,nCheck)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--自动重洗条件回调
function AnqiChongxi_LineChanged(ind)
	local str2, nIndex2 = AnqiChongxi_List1:GetCurrentSelect()
	
	if nIndex2 > 0 then
		AnqiChongxi_Zidong : Enable()
		AnqiChongxi_Zidong_Animate:Play(true)
	else
		AnqiChongxi_Zidong : Disable()
		AnqiChongxi_Zidong_Animate:Play(false)
	end
end

--自动重洗按钮回调
function AnqiChongxi_Auto_Clicked()
	--请先放入需要重洗连击技能的金翅翎羽
	if (g_Dark_Bag_Index == -1) then
		PushDebugMessage("#{AQJJ_160127_180}")
		return
	end

	local EquipPoint = LifeAbility : Get_Equip_Point(g_Dark_Bag_Index)
	if (EquipPoint ~= 17) then
		PushDebugMessage("#{AQJJ_160127_180}")
		return
	end
	
	local str2, nIndex2 = AnqiChongxi_List1:GetCurrentSelect()
	if nIndex2 <= 0 then
		return
	end
	
	if g_AutoSkill_TimerID >= 0 then
		--关闭暗器自动重洗
		AnqiChongxi_CloseAutoFlash()
		PushDebugMessage("#{AQJJ_160127_196}")
	else
		--请求自动重洗
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("AskLingyuSkillAutoReset")
			Set_XSCRIPT_ScriptID(260001)
			Set_XSCRIPT_Parameter(0,g_Dark_Bag_Index)
			Set_XSCRIPT_Parameter(1,nIndex2 - 1)		--想要洗的属性
			Set_XSCRIPT_Parameter(2,g_AutoSkillCount)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
	end
	
end

--自动重洗二次确认OK
function AnqiChongxi_Auto_ClickedOK()
	g_AutoSkill_TimerID = SetTimer("AnqiChongxi","AnqiChongxi_Auto_Timeproc()", 300)
	AnqiChongxi_Zidong:SetText("#{AQJJ_160127_187}")
	AnqiChongxi_List1 : Disable()
	AnqiChongxi_OK : Disable()
end

--自动重洗proc
function AnqiChongxi_Auto_Timeproc()
	local str2, nIndex2 = AnqiChongxi_List1:GetCurrentSelect()
	if this:IsVisible() and nIndex2 > 0 then
		--暗器自动重洗
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("LingyuSkillAutoReset")
			Set_XSCRIPT_ScriptID(260001)
			Set_XSCRIPT_Parameter(0,g_Dark_Bag_Index)
			Set_XSCRIPT_Parameter(1,nIndex2 - 1)		--想要洗的属性
			Set_XSCRIPT_Parameter(2,g_AutoSkillCount)
			Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
		if g_AutoSkillCount <= 0 then
			g_AutoSkillCount = 1
		end
	else
		if g_AutoSkill_TimerID >= 0 then
			--关闭暗器自动重洗
			AnqiChongxi_CloseAutoFlash()
			PushDebugMessage("#{AQJJ_160127_196}")
		end
	end
end

--关闭界面按钮回调
function AnqiChongxi_CloseUI_Clicked()
	if g_Dark_Bag_Index ~= -1 and g_skillState == 1 then
		--关闭界面确认
		PushEvent("DARK_SKILL_RECOIN_CONFIRM",g_Dark_Bag_Index,3)
		return
	end

	AnqiChongxi_Close()
end

--取消按钮回调
function AnqiChongxi_Cancel_Clicked()
	if g_Dark_Bag_Index ~= -1 and g_skillState == 1 then
		--关闭界面确认
		PushEvent("DARK_SKILL_RECOIN_CONFIRM",g_Dark_Bag_Index,3)
		return
	end
	AnqiChongxi_Close()
end

--保存重洗后的效果按钮回调
function AnqiChongxi_Save_Clicked()
	--请先放入暗器。
	if (g_Dark_Bag_Index == -1) then
		PushDebugMessage("#{CXYH_140813_16}")
		return
	end

	local EquipPoint = LifeAbility : Get_Equip_Point(g_Dark_Bag_Index)
	if (EquipPoint ~= 17) then
		PushDebugMessage("#{AQJJ_160127_47}")
		return
	end

	--暗器重洗保存
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("LingyuSkillSave")
		Set_XSCRIPT_ScriptID(260001)
		Set_XSCRIPT_Parameter(0,g_Dark_Bag_Index)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--界面Hide回调
function AnqiChongxi_Clear()
	AnqiChongxi_Reset()
	AnqiChongxi_StopCareObject()
end

--元宝确认check回调
function AnqiChongxi_BindClicked()
	local sCheck = AnqiChongxi_querengoumaiBind : GetProperty("Selected")

	if sCheck == "False" or sCheck == "false" then
	elseif sCheck == "True" or sCheck == "true" then
	end
	
end

function AnqiChongxi_Update(Item_index)
	local i_index = tonumber(Item_index)
	local theAction = EnumAction(i_index, "packageitem");

	if theAction:GetID() ~= 0 then
		if PlayerPackage : GetItemTableIndex( i_index ) ~= g_Mainitem then
			PushDebugMessage("#{AQJJ_160127_47}")
			return
		end

		if i_index == g_Dark_Bag_Index then
			return
		end
		
		if g_AutoSkill_TimerID > 0 then
			PushDebugMessage("#{AQJJ_160127_188}")
			return
		end
		
		--界面清空
		AnqiChongxi_Reset()
		--设置ActionItem
		AnqiChongxi_Frame_Icon:SetActionItem(theAction:GetID());
		g_Dark_Bag_Index = i_index
		LifeAbility : Lock_Packet_Item(i_index,1)
		AnqiChongxi_OK:Enable()
		AnqiChongxi_List1 : Enable()
		AnqiChongxi_List1_Pic : SetToolTip("")
		AnqiChongxi_UpdateMoneyDisp()
		AnqiChongxi_UpdateSkillDesc()
	end

end

function AnqiChongxi_Reset()
	AnqiChongxi_Frame_Icon:SetActionItem(-1);
	LifeAbility : Lock_Packet_Item(g_Dark_Bag_Index,0);
	g_Dark_Bag_Index = -1
	AnqiChongxi_OK:Disable()
	AnqiChongxi_Frame_Button:Disable()
	DataPool:CleanLYDarkFreashSkillType()
	AnqiChongxi_UpdateSkillDesc()
	g_skillState = 0
	
	AnqiChongxi_List1:SetCurrentSelect(0)
	AnqiChongxi_List1 : Disable()
	AnqiChongxi_List1_Pic : SetToolTip("#{AQJJ_160127_180}")
	AnqiChongxi_Zidong : Disable()
	AnqiChongxi_Zidong_Animate:Play(false)
	if g_AutoSkill_TimerID >= 0 then
		AnqiChongxi_CloseAutoFlash()
	end
end

function AnqiChongxi_CloseAutoFlash()
	if g_AutoSkill_TimerID >= 0 then
			KillTimer(g_AutoSkill_TimerID)
			g_AutoSkill_TimerID = -1
			g_AutoSkillCount = 0
			AnqiChongxi_Zidong:SetText("#{AQJJ_160127_186}")
			AnqiChongxi_List1 : Enable()
			AnqiChongxi_OK : Enable()
	end
end

function AnqiChongxi_Close()
	AnqiChongxi_Reset()
	AnqiChongxi_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function AnqiChongxi_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "AnqiChongxi");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "AnqiChongxi")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function AnqiChongxi_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "AnqiChongxi");
		g_Object = -1;
	end
end

--=========================================================
--界面状态金钱显示清空
--=========================================================
function AnqiChongxi_Resume()
	if g_AutoSkill_TimerID > 0 then
		PushDebugMessage("#{AQJJ_160127_188}")
		return
	end
	AnqiChongxi_Reset()
	AnqiChongxi_DemandMoney:SetProperty("MoneyNumber", 0)
	AnqiChongxi_SelfJiaozi:SetProperty("MoneyNumber", 0)
	AnqiChongxi_SelfMoney:SetProperty("MoneyNumber", 0)
end
