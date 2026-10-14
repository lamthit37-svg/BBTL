local g_uitype = 1;
local g_serverScriptId = 311111;
local g_serverNpcId = -1;
local g_clientNpcId = -1;
local g_selidx = -1;						-- 当前选择的珍兽
local g_seledidx =-1;                   --  ||-__-为了珍兽鉴定成长率做的特殊处理，因为在受到UPDATE_PET_PAGE之后要把选择的珍兽信息清空，
                                        --        但是鉴定珍兽成长接下来还需要使用这个信息
local g_selidx_jns = -1;				-- 当前道具栏选择的技能书（目前道具栏只有一格）
local	g_selidx_ynd = -1;				-- 当前道具栏选择的延年丹（目前道具栏只有一格）

--因为在do的时候硬指定了action button的id是1，所以无法通过那个id来确定物品是否放到上面
--所以为每个需要物品的界面增加一个类似延年丹的实现方式
local g_selidx_lsd = -1; --炼兽丹
local g_selidx_zxd = -1; --转性丹
local g_selidx_htjz = -1; --还童卷轴

local g_stduySkill = false;			-- 是否已经学习技能
local MAX_OBJ_DISTANCE = 3.0;
local g_DefaultTxt = "请将要使用的道具拖拽到前面的道具框中。";
local g_tlvcostmoney = {};
local g_tbabaymoney = {};
local g_petSkillStudyMoreMoney = 990000

local PETSKILLSTUDY_ACCBTN = {};
local FUNCTION_ACCNAME = {};

local UITYPE_LIANSHOUDAN = 800107
local UITYPE_ZHUANXINGDAN = 800108
local CurUIType = -1       --800107为珍兽洗点界面

local g_PetSkillStudy_Frame_UnifiedPosition;


local g_PetSkillStudy_PetYanShou_YuanbaoPay=1
local g_PetSkillStudy_PetXiDian_YuanbaoPay=1

local INDEX_YANSHOU_ITEM =30606024
local INDEX_XIDIAN_ITEM  =30503021
g_PetSkillStudy_YanShou =-1
g_PetSkillStudy_XiDian =-1

function PetSkillStudy_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("UPDATE_PETSKILLSTUDY",true);
	this:RegisterEvent("REPLY_MISSION_PET",false);
	this:RegisterEvent("UPDATE_PET_PAGE",false);
	this:RegisterEvent("DELETE_PET",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false);	
--	this:RegisterEvent("CONFIRM_PETSKILLSTUDY");				-- 该事件在 MessageBox_Self 界面中的 PET_SKILL_STUDY_CONFIRM 事件中触发
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("BUY_ITEM",false)
end

function PetSkillStudy_OnLoad()
	PETSKILLSTUDY_ACCBTN[1] = {PetSkillStudy_Skill1, "", -1, ""}; --{ActionButton控件,索引的类型,索引值,功能的类型}
	--PETSKILLSTUDY_ACCBTN[2] = {PetSkillStudy_Skill2, "", -1, ""};
	--PETSKILLSTUDY_ACCBTN[3] = {PetSkillStudy_Skill3, "", -1, ""};
	
	--"S"		技能书学习
	--"R"		还童
	--"A"		寿命延长
	--"L"   	炼兽丹
	FUNCTION_ACCNAME = {"S", "R", "A"};
	g_tlvcostmoney = {
		[5]=1000,
		[15]=3000,
		[25]=5000,
		[35]=7000,
		[45]=9000,
		[55]=11000,
		[65]=13000,
		[75]=15000,
		[85]=17000,
		[95]=19000,
		[105]=21000,
	};
	g_tbabaymoney = {
		[5]=5000,
		[15]=6000,
		[20]=7000,
		[25]=7000,
		[35]=10000,
		[45]=15000,
		[55]=25000,
		[65]=40000,
		[75]=55000,
		[85]=70000,
		[95]=85000,
		[105]=100000,
	};
	
	g_PetSkillStudy_Frame_UnifiedPosition=PetSkillStudy_Frame:GetProperty("UnifiedPosition");
	
end

function PetSkillStudy_OnEvent(event)
	
	--调试用：打印点击控件后所发生的事件

	--PushDebugMessage(event);
	
	if ( event == "UI_COMMAND" ) then
		PetSkillStudy_OnUICommand(arg0);
	elseif( event == "UPDATE_PETSKILLSTUDY" and this:IsVisible()) then 
		PetSkillStudy_Update(arg0, arg1);
	elseif ( event == "REPLY_MISSION_PET" and this:IsVisible() ) then
		PetSkillStudy_Selected(tonumber(arg0));
	elseif ( event == "UPDATE_PET_PAGE" and this:IsVisible() ) then
		PetSkillStudy_Show();
		g_seledidx = g_selidx;
		if( g_selidx ~= -1 )then
			Pet:SetPetLocation(g_selidx,-1);
		end
		g_selidx = -1;
	elseif ( event == "DELETE_PET" and this:IsVisible() ) then
		PetSkillStudy_Hide();
	elseif ( event == "OBJECT_CARED_EVENT") then
		PetSkillStudy_CareEventHandle(arg0,arg1,arg2);
--	使用新的珍兽学习技能界面，此界面不再响应学习确认消息
--	elseif ( event == "CONFIRM_PETSKILLSTUDY") then
--		PetSkillStudy_ConfirmPetSkillStudy()

	elseif (event == "ADJEST_UI_POS" ) then
		PetSkillStudy_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		PetSkillStudy_Frame_On_ResetPos()
	elseif event == "BUY_ITEM" and this:IsVisible() then
--		PushDebugMessage("BUY_ITEM")
--		PushDebugMessage("g_selidx_ynd"..g_selidx_ynd)
--		PushDebugMessage("g_PetSkillStudy_YanShou"..g_PetSkillStudy_YanShou)
		if g_PetSkillStudy_YanShou > 0 then
			local item = tonumber(arg1)
			if item > 0 then
				if INDEX_YANSHOU_ITEM ~= item then 
					return 
				end
				local itemIdx = PlayerPackage:GetBagPosByItemIndex(item)
				if itemIdx >= 0 then
					g_PetSkillStudy_YanShou = -1
					PetSkillStudy_Update(1,itemIdx)
				end
			end
		end	
		if g_PetSkillStudy_XiDian > 0 then
			local item = tonumber(arg1)
			if item > 0 then
				if INDEX_XIDIAN_ITEM ~= item then 
					return 
				end
				local itemIdx = PlayerPackage:GetBagPosByItemIndex(item)
				if itemIdx >= 0 then
					g_PetSkillStudy_XiDian = -1
					PetSkillStudy_Update(1,itemIdx)
				end
			end
		end	
		
	end
end

function PetSkillStudy_OnUICommand(arg0)
	local op = tonumber(arg0);
	CurUIType = -1
	
	PetSkillStudy_Skill1:Show();--[tx47256]default behavor: itembox show	
	--调试用，判断按的哪个功能
	--PushDebugMessage(op);
	
	--珍兽技能学习、还童、延长寿命、驯养共用同一个界面
	if( op == 3 ) then   --延长珍兽寿命
		g_serverNpcId = Get_XParam_INT(0);
		g_clientNpcId = Target:GetServerId2ClientId(g_serverNpcId);

		this:CareObject(g_clientNpcId, 1, "PetSkillStudy");
		g_uitype = Get_XParam_INT(1);
		if( g_selidx ~= -1 )then
			Pet:SetPetLocation(g_selidx,-1);
		end
		g_selidx = -1;
		PetSkillStudy_Hide();							--为了避免使用不同功能时宠物和道具还存在，先关闭窗口，再重新打开窗口
		PetSkillStudy_Show();		
	
	--珍兽洗点	
	elseif( op == UITYPE_LIANSHOUDAN ) then
		g_serverNpcId = Get_XParam_INT(0);
		g_clientNpcId = Target:GetServerId2ClientId(g_serverNpcId);
		this:CareObject(g_clientNpcId, 1, "PetSkillStudy");
		CurUIType = op
		g_uitype = -1
		
		Variable:SetVariable("PetStudyType", tostring(g_uitype), 1)--[tx46111]
		PetSkillStudy_ShowReset() 
		
		PetSkillStudy_Blank_ButtonCheck2BK:Show(); 
		PetSkillStudy_Static3:SetText("")
		PetSkillStudy_SkillType_Text:SetText("#{ZSYH_170111_103}")
		
		
		PetSkillStudy_Blank_ButtonCheck2:SetCheck(g_PetSkillStudy_PetXiDian_YuanbaoPay);
		PetSkillStudy_Blank_ButtonCheck2BK:Show();
		PetSkillStudy_Blank_ButtonCheck2Text:SetText("#{ZSYH_170111_14}");
		PetSkillStudy_Blank_ButtonCheck2Text:SetToolTip("#{ZSYH_170111_15}"); 
		PetSkillStudy_SkillType_Text:SetText("#{ZSYH_170111_103}")
		
		
		if( g_selidx ~= -1 )then
			Pet:SetPetLocation(g_selidx,-1);
		end
		--谢鉷 47505 begin
		g_selidx = -1;
		--谢鉷 47505 end
		
	--elseif( op == UITYPE_ZHUANXINGDAN ) then
	--	g_serverNpcId = Get_XParam_INT(0);
	--	g_clientNpcId = Target:GetServerId2ClientId(g_serverNpcId);
	--	this:CareObject(g_clientNpcId, 1, "PetSkillStudy");
	--	CurUIType = UITYPE_ZHUANXINGDAN
	--	g_uitype = -1
	--	PetSkillStudy_ShowZhuanxingdan()
				
	elseif( op == 4 and 4 == g_uitype) then
		local needMoney = Get_XParam_INT(0);

		PetSkillStudy_Money:SetProperty("MoneyNumber", tostring(needMoney));
		PetSkillStudy_Accept:Enable();
	  PetSkillStudy_Skill1:Hide();	--[tx47256]				
	  PetSkillStudy_Blank_ButtonCheck1BK:Hide();
		PetSkillStudy_Blank_ButtonCheck2BK:Hide();
		PetSkillStudy_SkillType_Text:SetText("")
	elseif( op == 4 and 6 == g_uitype) then
		local strRate = Get_XParam_STR(1);
		local sRate = nil;

		if(nil == strRate) then
			strRate = "rat=1.0";
		end
		_,_,sRate = string.find(strRate, "rat=(%d+)");
		PetSkillStudy_ShowPetGrow(tonumber(sRate));
				
	  PetSkillStudy_Blank_ButtonCheck1BK:Hide();
		PetSkillStudy_Blank_ButtonCheck2BK:Hide();
		PetSkillStudy_SkillType_Text:SetText("")
	end
end

function PetSkillStudy_ShowReset()  --显示洗点界面
	--控件清除操作
	 
	PetSkillStudy_PetModel:SetFakeObject( "" );
	PetSkillStudy_Unlock();
	for i=1,1 do
			PETSKILLSTUDY_ACCBTN[i][1]: SetPushed(0);
			PETSKILLSTUDY_ACCBTN[i][1]: SetActionItem(-1);

			PETSKILLSTUDY_ACCBTN[i][2] = "";
			PETSKILLSTUDY_ACCBTN[i][3] = -1;
	end
	
	PetSkillStudy_SkillType_Text:SetText("#gFF0FA0珍兽洗点");
	PetSkillStudy_SkillType_Text:Show();
	PetSkillStudy_Accept:SetText("确认");
	PetSkillStudy_Accept:Enable();

	PetSkillStudy_Money:SetProperty("MoneyNumber", "");
	PetSkillStudy_Money:Hide()
	PetSkillStudy_Static3:SetText("无需消耗金钱")
	--PetSkillStudy_Money:Show();
	--PetSkillStudy_Static3:SetText("需要金钱");
	PetSkillStudy_MultiIMEEditBox:Hide();
	PetSkillStudy_Text1:SetText(g_DefaultTxt);
	PetSkillStudy_Text1:Show();
	
	PetSkillStudy_SetButtonAccName_Reset()
	 
	PetSkillStudy_Blank_ButtonCheck1BK:Hide();
	PetSkillStudy_Blank_ButtonCheck2BK:Hide();
		
	this:Show();
	Pet:ShowPetList(1);
end
function PetSkillStudy_SetButtonAccName_Reset()  --显示洗点界面
	PETSKILLSTUDY_ACCBTN[1][1]:SetProperty("DragAcceptName", "T"..(1).."L" );
end

function PetSkillStudy_ShowZhuanxingdan() --转性丹界面
	--控件清除操作
	PetSkillStudy_PetModel:SetFakeObject( "" );
	PetSkillStudy_Unlock();
	for i=1,1 do
			PETSKILLSTUDY_ACCBTN[i][1]: SetPushed(0);
			PETSKILLSTUDY_ACCBTN[i][1]: SetActionItem(-1);

			PETSKILLSTUDY_ACCBTN[i][2] = "";
			PETSKILLSTUDY_ACCBTN[i][3] = -1;
	end
	
	PetSkillStudy_SkillType_Text:SetText("#gFF0FA0还童丹");
	PetSkillStudy_SkillType_Text:Show();
	PetSkillStudy_Accept:SetText("确认");
	PetSkillStudy_Accept:Enable();

	PetSkillStudy_Money:SetProperty("MoneyNumber", "");
	PetSkillStudy_Money:Hide()
	PetSkillStudy_Static3:SetText("")
	--PetSkillStudy_Money:Show();
	--PetSkillStudy_Static3:SetText("需要金钱");
	PetSkillStudy_MultiIMEEditBox:Hide();
	PetSkillStudy_Text1:SetText(g_DefaultTxt);
	PetSkillStudy_Text1:Show();
	
	PetSkillStudy_SetButtonAccName_Zhuanxingdan()
	this:Show();
	Pet:ShowPetList(1);
end
function PetSkillStudy_SetButtonAccName_Zhuanxingdan()  
	PETSKILLSTUDY_ACCBTN[1][1]:SetProperty("DragAcceptName", "T"..(1).."Z" );
end



function PetSkillStudy_Show()
	--local nPetCount = Pet : GetPet_Count();
	--local szPetName;
	

	--PushDebugMessage ("PetSkillStudy_Show")
	
	--控件清除操作
	--PetSkillStudy_PetList : ClearListBox();
	--如果不是刚学完技能，清除窗口中的珍兽及相关信息(珍兽技能学习后不清除)
	if (g_stduySkill == false) then
		PetSkillStudy_PetModel:SetFakeObject( "" );
		PetSkillStudy_Unlock();
		for i=1,1 do
			PETSKILLSTUDY_ACCBTN[i][1]: SetPushed(0);
			PETSKILLSTUDY_ACCBTN[i][1]: SetActionItem(-1);

			PETSKILLSTUDY_ACCBTN[i][2] = "";
			PETSKILLSTUDY_ACCBTN[i][3] = -1;
		end

		Pet:ClosePetSkillStudyMsgBox()
	end
	
	--获得全部珍兽列表
	--for	i=1, nPetCount do
	--	szPetName = Pet : GetPetList_Appoint(i-1);
	--	PetSkillStudy_PetList : AddItem(szPetName, i-1);
	--end
	
	--默认帮玩家选择第一只珍兽
	--if(0 ~= nPetCount) then
	--	Pet:SetSkillStudyModel(0);
	--	PetSkillStudy_PetList:SetItemSelectByItemID(0);
	--	PetSkillStudy_PetModel:SetFakeObject( "My_PetStudySkill" );
	--end
	
	Variable:SetVariable("PetStudyType", tostring(g_uitype), 1)
	
	
--	if(1 == g_uitype) then --普通技能学习
--		PetSkillStudy_SkillType_Text:SetText("#gFF0FA0普通技能学习");
--		PetSkillStudy_SkillType_Text:Show();
--		PetSkillStudy_Accept:SetText("学习");
--		PetSkillStudy_Accept:Enable();
--		
--		PetSkillStudy_Money:SetProperty("MoneyNumber", "");
--		PetSkillStudy_Money:Show();
--		PetSkillStudy_Static3:SetText("#{INTERFACE_XML_789}");
--		PetSkillStudy_MultiIMEEditBox:Hide();
--		PetSkillStudy_Text1:SetText(g_DefaultTxt);
--		PetSkillStudy_Text1:Show();
--		PetSkillStudy_SetButtonAccName();
		
	if(2 == g_uitype) then	--还童
		--PetSkillStudy_SkillType_Text:SetText("#gFF0FA0还童丹");
		--PetSkillStudy_SkillType_Text:Show();
		--PetSkillStudy_Accept:SetText("确认");
		--PetSkillStudy_Accept:Enable();

		--PetSkillStudy_Money:SetProperty("MoneyNumber", "");
		--PetSkillStudy_Money:Show();
		--PetSkillStudy_Static3:SetText("#{INTERFACE_XML_789}");
		--PetSkillStudy_MultiIMEEditBox:Hide();
		--PetSkillStudy_Text1:SetText(g_DefaultTxt);
		--PetSkillStudy_Text1:Show();
		--PetSkillStudy_SetButtonAccName();
		
	elseif(3 == g_uitype) then --延长寿命
		PetSkillStudy_SkillType_Text:SetText("#{ZSYH_170111_1}");
		PetSkillStudy_SkillType_Text:Show();
		PetSkillStudy_Accept:SetText("确认");
		PetSkillStudy_Accept:Enable();
		
		PetSkillStudy_Money:Hide();
		PetSkillStudy_Static3:SetText(""); 
		PetSkillStudy_MultiIMEEditBox:Hide();
		PetSkillStudy_Text1:SetText(g_DefaultTxt);
		PetSkillStudy_Text1:Show();
		PetSkillStudy_SetButtonAccName();
		PetSkillStudy_Blank_ButtonCheck1:SetCheck(g_PetSkillStudy_PetYanShou_YuanbaoPay);
		PetSkillStudy_Blank_ButtonCheck1BK:Show();
		PetSkillStudy_Blank_ButtonCheck1Text:SetText("#{ZSYH_170111_2}");
		PetSkillStudy_Blank_ButtonCheck1Text:SetToolTip("#{ZSYH_170111_3}"); 
		PetSkillStudy_SkillType_Text:SetText("#{ZSYH_170111_1}")
		
		if( IsWindowShow("Packet") ) == false then
			ToggleContainer()
		end
		 
		
	elseif(4 == g_uitype) then --珍兽驯养
		PetSkillStudy_SkillType_Text:SetText("#gFF0FA0驯养费");
		PetSkillStudy_SkillType_Text:Show();
		PetSkillStudy_Accept:SetText("驯养");
		PetSkillStudy_Accept:Disable();
		PetSkillStudy_Money:SetProperty("MoneyNumber", "");
		PetSkillStudy_Money:Show();
		PetSkillStudy_Static3:SetText("#{INTERFACE_XML_789}");
		PetSkillStudy_MultiIMEEditBox:Hide();
		PetSkillStudy_Text1:Hide();
		PetSkillStudy_Skill1:Hide();	--[tx47256]
--		if( 0 ~= nPetCount ) then
--			PetSkillStudy_AskMoney(0);
--		end

	elseif(6 == g_uitype) then --珍兽生长率查询
		PetSkillStudy_SkillType_Text:SetText("#gFF0FA0成长查询");
		PetSkillStudy_SkillType_Text:Show();
		PetSkillStudy_Accept:SetText("查询");
		PetSkillStudy_Accept:Disable();

		PetSkillStudy_Money:SetProperty("MoneyNumber", "0");
		PetSkillStudy_Money:Show();
		PetSkillStudy_Static3:SetText("#{INTERFACE_XML_789}");
		PetSkillStudy_MultiIMEEditBox:Hide();
		PetSkillStudy_Text1:SetText("查询珍兽的成长率"); -- zchw
		PetSkillStudy_Text1:Show();
		PetSkillStudy_Skill1:Hide();	--[tx47256]
		
	elseif(7 == g_uitype) then --珍兽称号领取
		PetSkillStudy_SkillType_Text:SetText("#gFF0FA0珍兽称号领取");
		PetSkillStudy_SkillType_Text:Show();
		PetSkillStudy_Accept:SetText("确认");
		PetSkillStudy_Accept:Enable();
		PetSkillStudy_Money:Hide();
		PetSkillStudy_Static3:SetText("不需要消耗金钱");
		PetSkillStudy_MultiIMEEditBox:Hide();
		PetSkillStudy_Text1:SetText("请选择需要领取称号的珍兽。");
		PetSkillStudy_Text1:Show();
		PetSkillStudy_Skill1:Hide();	--[tx47256]			
	end
	
	if CurUIType == UITYPE_LIANSHOUDAN then
		PetSkillStudy_ShowReset()
		
		PetSkillStudy_Blank_ButtonCheck2BK:Show(); 
		PetSkillStudy_Static3:SetText("")
		PetSkillStudy_SkillType_Text:SetText("#{ZSYH_170111_103}")
		
		
		PetSkillStudy_Blank_ButtonCheck2:SetCheck(g_PetSkillStudy_PetXiDian_YuanbaoPay);
		PetSkillStudy_Blank_ButtonCheck2BK:Show();
		PetSkillStudy_Blank_ButtonCheck2Text:SetText("#{ZSYH_170111_14}");
		PetSkillStudy_Blank_ButtonCheck2Text:SetToolTip("#{ZSYH_170111_15}"); 
		PetSkillStudy_SkillType_Text:SetText("#{ZSYH_170111_103}")
		
	end
	
	--珍兽技能学习学习完后，删除道具栏中的技能书
--	if (1 == g_uitype) then
--		g_selidx_jns = -1;				--恢复为未选中道具栏中的技能书（只针对珍兽技能学习）
		--PushDebugMessage ("技能书已删除。")
--	end
	
	--珍兽延长寿命后，删除道具栏中的延年丹
	if (3 == g_uitype) then
		g_selidx_ynd = -1;
		--PushDebugMessage ("延年丹已删除。")
	end	
	if (CurUIType == UITYPE_LIANSHOUDAN) then
		g_selidx_lsd = -1;
		--PushDebugMessage ("炼兽丹已删除。")
	end	
	--if (3 == g_uitype) then
		--g_selidx_zxd = -1;
		--PushDebugMessage ("转性丹已删除。")
	--end	
	--if (2 == g_uitype) then
	--	g_selidx_htjz = -1;
		--PushDebugMessage ("还童卷轴已删除。")
	--end

	this:Show();
	Pet:ShowPetList(1);		-- 打开珍兽列表
end

function PetSkillStudy_SetButtonAccName()
	if(nil == FUNCTION_ACCNAME[g_uitype]) then
		for i=1,1 do
				PETSKILLSTUDY_ACCBTN[i][1]:SetProperty("DragAcceptName", "T"..i);
		end
	else
		for i=1,1 do
				PETSKILLSTUDY_ACCBTN[i][1]:SetProperty("DragAcceptName", "T"..i..FUNCTION_ACCNAME[g_uitype]);
		end
	end
end

function PetSkillStudy_Test()
	g_uitype = g_uitype + 1;
	if( g_uitype > 6 ) then
		g_uitype = 1;
	end
	PetSkillStudy_Show();
end

--选择不同珍兽时，设置不同的珍兽模型
function PetSkillStudy_Selected(selidx)
	--local selidx = PetSkillStudy_PetList:GetFirstSelectItem();
	
	--PushDebugMessage (selidx);
	
	if( -1 == selidx ) then
		return;
	end
	
	--珍兽已被其它界面选中
	if (Pet:GetPetLocation(selidx) ~= -1) then
		return;
	end

	if 2 == g_uitype or CurUIType == UITYPE_ZHUANXINGDAN or CurUIType == UITYPE_LIANSHOUDAN then	--还童，转性，洗点
		if PlayerPackage:IsPetLock(selidx) == 1 then
			PushDebugMessage("珍兽已加锁")
			return
		end
	end	
		
	--zchw
	if g_uitype == 2 then
		if Pet:IsPetHaveEquip(selidx) == 1 then
			PushDebugMessage("#{ZSZB_090211_18}")
			return
		end
		
		--有内丹限制操作 Vega
		if Pet:LuaFnIsPetEquipNeiDan(selidx) == 1 then
			PushDebugMessage("#{ZSND_230428_131}")
			return
		end
	end

	PetSkillStudy_PetModel:SetFakeObject("");
	Pet:SetSkillStudyModel(selidx);
	PetSkillStudy_PetModel:SetFakeObject( "My_PetStudySkill" );

	--珍兽打技能书....
	--如果当前书和宠都选好了....则计算是否是开新的手动技能格....如果是则多收钱....
--	if( 1 == g_uitype and g_sleidx ~= selidx) then
--		if Pet:CheckPetSkillStudyMoreMoneyMode( selidx, PETSKILLSTUDY_ACCBTN[1][3] ) == 1 then
--			PetSkillStudy_Money:SetProperty( "MoneyNumber", g_petSkillStudyMoreMoney );
--		else
--			local ptlv = Pet:GetTakeLevel(selidx);
--			local ptM = PetSkillStudy_GetTakeLevelCostMoney(ptlv);
--			PetSkillStudy_Money:SetProperty("MoneyNumber", tostring(ptM));
--		end
--	end
	
	if( 2 == g_uitype and g_sleidx ~= selidx) then
		local ptlv = Pet:GetTakeLevel(selidx);
		
		local saidx = -1;
		for i=1,1 do
			if(PETSKILLSTUDY_ACCBTN[i][1]:GetProperty("Checked") == "True") then
				saidx = i;
				break;
			end
		end
		
		local itemId = -1;
		if saidx ~= -1 then
			local bagIndex = PETSKILLSTUDY_ACCBTN[saidx][3];
			itemId = PlayerPackage:GetItemTableIndex(bagIndex);
		end
		
		local ptM = PetSkillStudy_GetTakeBabyCostMoney(ptlv, itemId);
		PetSkillStudy_Money:SetProperty("MoneyNumber", tostring(ptM));
	end	
	
	if( 4 == g_uitype ) then
		PetSkillStudy_AskMoney(selidx);
		PetSkillStudy_Accept:Disable();
	end
	
	if( 6 == g_uitype and g_selidx ~= selidx) then
		PetSkillStudy_Text1:SetText("查询珍兽成长率！");
		PetSkillStudy_Accept:Enable();
		PetSkillStudy_Money:SetProperty("MoneyNumber", "100");
		PetSkillStudy_Money:Show();
	end

	--切换珍兽的时候，释放上一个珍兽
	if(g_selidx ~= -1) then
		Pet:SetPetLocation(g_selidx,-1);
	end

	g_selidx = selidx;	--已经选好了珍兽
	Pet:SetPetLocation(g_selidx,13);
	Pet:ClosePetSkillStudyMsgBox()

end

function PetSkillStudy_AskMoney( selidx )

	if( -1 == selidx ) then
		return;
	end
	
	local hid,lid = Pet:GetGUID(selidx);

	Clear_XSCRIPT();
	Set_XSCRIPT_Function_Name("PetSkillStudy_Ask_Money");
	Set_XSCRIPT_ScriptID(g_serverScriptId);
	Set_XSCRIPT_Parameter(0,hid);
	Set_XSCRIPT_Parameter(1,lid);
	Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end

--根据选择的珍兽，显示相应的详细信息
--function PetSkillStudy_ShowTargetPet(selidx)
	--local selidx = PetSkillStudy_PetList:GetFirstSelectItem();
--	if( -1 == selidx ) then
--		return;
--	end
	
--	Pet:ShowTargetPet(selidx);
--end

----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function PetSkillStudy_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1) then
		PetSkillStudy_PetModel:RotateBegin(-0.3);
	--向左旋转结束
	else
		PetSkillStudy_PetModel:RotateEnd();
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function PetSkillStudy_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1) then
		PetSkillStudy_PetModel:RotateBegin(0.3);
	--向右旋转结束
	else
		PetSkillStudy_PetModel:RotateEnd();
	end
end

-- 更新珍兽学习界面的ActionButton
-- aidx  ActionButton的索引
-- pidx	 背包(Packge)内的物品索引
function PetSkillStudy_Update(aidxs, pidxs)

	--PushDebugMessage ("PetSkillStudy_Update")
	
	local aidx = tonumber(aidxs);
	local pidx = tonumber(pidxs);
	
	if(aidx < 1 or aidx > 1) then
		return;
	end
	
	--解除原来被锁定的物品
	if("package" == tostring(PETSKILLSTUDY_ACCBTN[aidx][2])) then
		Pet:SkillStudyUnlock(PETSKILLSTUDY_ACCBTN[aidx][3]);
	end
	
	--设置新的物品
	local action = EnumAction(pidx, "packageitem");
	if(action:GetID() ~= 0) then
		PETSKILLSTUDY_ACCBTN[aidx][1]:SetActionItem(action:GetID());
		PETSKILLSTUDY_ACCBTN[aidx][2] = "package";
		PETSKILLSTUDY_ACCBTN[aidx][3] = pidx;
	end
	
	if 2 == g_uitype and action:GetID() ~= 0 then
		local slidx = g_selidx;
		local ptlv = Pet:GetTakeLevel(slidx);
		local itemId = action:GetDefineID();
		local ptM = PetSkillStudy_GetTakeBabyCostMoney(ptlv, itemId);
		PetSkillStudy_Money:SetProperty("MoneyNumber", tostring(ptM));
	end
	
	if(1 == g_uitype or 3 == g_uitype or 2 == g_uitype or -1 == g_uitype ) then
		PETSKILLSTUDY_ACCBTN[1][1]:SetPushed(1);
	end

	--珍兽打技能书....
	--如果当前书和宠都选好了....则计算是否是开新的手动技能格....如果是则多收钱....
--	if 1 == g_uitype and g_selidx ~= -1 and action:GetID() ~= 0 then
--		if Pet:CheckPetSkillStudyMoreMoneyMode( g_selidx, pidx ) == 1 then
--			PetSkillStudy_Money:SetProperty( "MoneyNumber", g_petSkillStudyMoreMoney );
--		else
--			local ptlv = Pet:GetTakeLevel(g_selidx);
--			local ptM = PetSkillStudy_GetTakeLevelCostMoney(ptlv);
--			PetSkillStudy_Money:SetProperty("MoneyNumber", tostring(ptM));
--		end
--	end

	--珍兽技能学习
--	if (1 == g_uitype) then
--		g_selidx_jns = 1			--将学习技能书拖进道具栏后，选中道具栏（当前道具栏只有1格，且只针对珍兽学习技能）
		--PushDebugMessage ("已放入技能书")
--	end
	
	--珍兽延长寿命
	if (3 == g_uitype) then
		g_selidx_ynd = 1			--将延年丹拖进道具栏后，选中道具栏（当前道具栏只有1格，且只针对珍兽延长寿命）
		--PushDebugMessage ("已放入珍兽延年丹")
	end	
	if (2 == g_uitype) then
		g_selidx_htjz = 1
	end	
	if (CurUIType == UITYPE_LIANSHOUDAN) then
		g_selidx_lsd = 1
	end	
	Pet:ClosePetSkillStudyMsgBox()

end

--处理ActionButton的点击
function PetSkillStudy_Btn_Click(aidx)
	if(aidx < 1 or aidx > 1) then
		return;
	end
	
	for i=1,1 do
		if( i == aidx ) then
			PETSKILLSTUDY_ACCBTN[i][1]:SetPushed(1);
		else
			PETSKILLSTUDY_ACCBTN[i][1]:SetPushed(0);
		end
	end
	
end

function PetSkillStudy_PetReset( PetIndex, ItemPos ) --珍兽洗点
	
	if (-1 == PetIndex ) then
		PushDebugMessage("#{ZSYH_170111_16}");
		return;
	end
	if(-1 == ItemPos ) then
		--local bagIndex, bindstate = PlayerPackage:FindFirstBindedItemIdxByIDTable( 30503021 )
		--if bagIndex == nil or bagIndex < 0 or bindstate == 0 then 
		local hid,lid = Pet:GetGUID(PetIndex);
		--	
		--end
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("PetSkillStudy_XiDian");
			Set_XSCRIPT_ScriptID(800107);
			Set_XSCRIPT_Parameter(0,g_PetSkillStudy_PetXiDian_YuanbaoPay);
			Set_XSCRIPT_Parameter(1,hid);
			Set_XSCRIPT_Parameter(2,lid);
			Set_XSCRIPT_ParamCount(3);
			Send_XSCRIPT(); 
	else
		local hid, lid = Pet:GetGUID(PetIndex);
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("ResetPetAttrPt");
		Set_XSCRIPT_ScriptID( 800107 );
		
		Set_XSCRIPT_Parameter(0,hid);
		Set_XSCRIPT_Parameter(1,lid);
		Set_XSCRIPT_Parameter(2,ItemPos);
		Set_XSCRIPT_ParamCount(3) 
		Send_XSCRIPT();
		PetSkillStudy_Hide()
	end  	
	 
end

function PetSkillStudy_Zhuanxingdan( PetIndex, ItemPos ) --珍兽洗点
	
	if (-1 == PetIndex ) then
		PushDebugMessage("请选择珍兽。");
		return;
	end
	if(-1 == ItemPos ) then
		PushDebugMessage("需要转性丹。");
		return;
	end
		
	local hid, lid = Pet:GetGUID(PetIndex);
	Clear_XSCRIPT();
	Set_XSCRIPT_Function_Name("ZhuanXingdian");
	Set_XSCRIPT_ScriptID( UITYPE_ZHUANXINGDAN );
	
	Set_XSCRIPT_Parameter(0,hid);
	Set_XSCRIPT_Parameter(1,lid);
	Set_XSCRIPT_Parameter(2,ItemPos);
	Set_XSCRIPT_ParamCount(3)
	
	Send_XSCRIPT();
	
end


--处理玩家确认要做的事情，根据g_uitype
function PetSkillStudy_Do()
	local saidx = -1;	--ActionButton选中的索引
	local slidx = g_selidx;	--ListBox选中的索引
	
	--祝凯 2007-8-17
	--目前只用了1个ActionButton就不要再循环查找当前到底激活的是哪个了....
	--非要这么弄的话....当失去焦点的时候就算放的有物品也会说没有物品了....
	--for i=1,1 do
	--	if(PETSKILLSTUDY_ACCBTN[i][1]:GetProperty("Checked") == "True") then
	--		saidx = i;
	--		break;
	--	end
	--end
	--直接说激活的是第1个ActionButton就行了....
	saidx = 1;
	--祝凯 2007-8-17

	--PushDebugMessage ("PetSkillStudy_Do " .. g_uitype);
	
	if CurUIType == UITYPE_LIANSHOUDAN then
		if (-1 == slidx) then
			PushDebugMessage("#{ZSYH_170111_16}");
			return;
		end
		
		--判断电话密保和二级密码保护2012.6.12-LIUBO
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
			return
		end
		-- 判断是否为安全时间2012.6.12-LIUBO
		if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
			PushDebugMessage("#{ZYXT_120528_16}")
			return
		end 
		PetSkillStudy_PetReset( slidx, PETSKILLSTUDY_ACCBTN[saidx][3] )
		
		return
	end

	if CurUIType == UITYPE_ZHUANXINGDAN then
		if (-1 == slidx) then
			PushDebugMessage("请选择珍兽。");
			return;
		end
		if(-1 == saidx) then
			PushDebugMessage("需要转性丹。");
			return;
		end
		PetSkillStudy_Zhuanxingdan( slidx, PETSKILLSTUDY_ACCBTN[saidx][3] )
		PetSkillStudy_Hide()
		return
	end
	
	--slidx = PetSkillStudy_PetList:GetFirstSelectItem();

--	if(1 == g_uitype) then
--		--普通技能学习
--		if (-1 == slidx) then
--			PushDebugMessage("请选择珍兽。");
--			return;
--		end
--		if(-1 == g_selidx_jns) then								-- 因为其他选项会使用saidx，为了不影响其他选项，这里使用只针对珍兽技能学习的g_selidx_jns
--			PushDebugMessage("需要技能书。");
--			return;
--		end
	if(2 == g_uitype) then
		--还童
		if (-1 == slidx) then
			PushDebugMessage("请选择珍兽。");
			return;
		end
		if(-1 == g_selidx_htjz) then
			PushDebugMessage("需要还童卷轴。");
			return;
		end
	elseif(3 == g_uitype) then
		--延长寿命
		if (-1 == slidx) then
			PushDebugMessage("#{ZSYSYH_130812_02}");
			return;
		end
		if(-1 == g_selidx_ynd) then								-- 因为其他选项会使用saidx，为了不影响其他选项，这里使用只针对珍兽延长寿命的g_selidx_ynd
			--PushDebugMessage("#{ZSSM_090113_01}");	-- "请放入珍兽延年丹。"
			--return;
		end
	elseif(4 == g_uitype) then
		--驯养
		if (-1 == slidx) then
			PushDebugMessage("请选择珍兽。");
			return;
		end
	else
		--这是啥
		--PetSkillStudy_Hide();
		--return;
	end
	
	--根据g_uitype来处理
	--延长寿命
	if(3 == g_uitype) then
		if g_selidx_ynd == -1 then
				--local bagIndex, bindstate = PlayerPackage:FindFirstBindedItemIdxByIDTable( 30606024 )
				--if bagIndex == nil or bagIndex < 0 or bindstate == 0 then 
				--	
				--else
				--	PushDebugMessage("#{ZSSM_090113_01}");
				--	return
				--end
				local hid,lid = Pet:GetGUID(slidx);
					Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("PetSkillStudy_YanShou");
					Set_XSCRIPT_ScriptID(g_serverScriptId);
					Set_XSCRIPT_Parameter(0,g_PetSkillStudy_PetYanShou_YuanbaoPay);
					Set_XSCRIPT_Parameter(1,hid);
					Set_XSCRIPT_Parameter(2,lid);
					Set_XSCRIPT_ParamCount(3);
					Send_XSCRIPT(); 
					return;
		else
			Pet:SkillStudy_Do(g_uitype, slidx, PETSKILLSTUDY_ACCBTN[saidx][3]); 
		end
		 
	--还童
	elseif(2 == g_uitype) then
		--local pM = Player:GetData("MONEY") + Player:GetData("MONEY_JZ") ;          --交子普及 Vega
		--local nM = tonumber(PetSkillStudy_Money:GetProperty("MoneyNumber"));

		--if( pM >= nM) then
		--        Pet:SkillStudy_Do(g_uitype, slidx, PETSKILLSTUDY_ACCBTN[saidx][3]);
		--else
		--	PushDebugMessage("金钱不够，无法还童");
		--	return;
		--end
	--驯养
	elseif(4 == g_uitype) then
		local pM = Player:GetData("MONEY") + Player:GetData("MONEY_JZ");	--交子普及 Vega
		local nM = tonumber(PetSkillStudy_Money:GetProperty("MoneyNumber"));

		if(100 == tonumber(Pet:GetHappy(slidx)) ) then	--and tonumber(Pet:GetHP(slidx)) == tonumber(Pet:GetMaxHP(slidx))
			PushDebugMessage("无需驯养");
			return;
		end
		
		if( pM >= nM) then
			local hid,lid = Pet:GetGUID(slidx);
			Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("PetSkillStudy_Domestication");
			Set_XSCRIPT_ScriptID(g_serverScriptId);
			Set_XSCRIPT_Parameter(0,hid);
			Set_XSCRIPT_Parameter(1,lid);
			Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
		else
			PushDebugMessage("金钱不够，无法驯养");
			return;
		end
	elseif(6 == g_uitype and -1 ~= slidx) then
		local hid,lid = Pet:GetGUID(slidx);
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnInquiryForGrowRate");
		Set_XSCRIPT_ScriptID(1050);
		Set_XSCRIPT_Parameter(0,hid);
		Set_XSCRIPT_Parameter(1,lid);
		Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
		return;
	elseif(7 == g_uitype and -1 ~= slidx) then
		local hid,lid = Pet:GetGUID(slidx);
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnAcceptPetTitle");
		Set_XSCRIPT_ScriptID(1031);
		Set_XSCRIPT_Parameter(0,g_serverNpcId);
		Set_XSCRIPT_Parameter(1,hid);
		Set_XSCRIPT_Parameter(2,lid);
		Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
		--需要关闭界面
		--return;
	end
	
	--还童或珍兽学习技能后窗口不关闭
	if (2 ~= g_uitype) and (1 ~= g_uitype) then
		PetSkillStudy_Hide();
	end
	
	--如果是珍兽学习技能
	--if (1 == g_uitype) then		
	--	Pet:ShowPetList(1)		--再次打开珍兽列表
	--end	
	Pet:SetPetLocation(g_selidx,-1);
end

--窗口隐藏前先将背包中被锁定的物品解锁
function PetSkillStudy_Unlock()
	for i=1,1 do
		if("package" == tostring(PETSKILLSTUDY_ACCBTN[i][2])) then
			Pet:SkillStudyUnlock(PETSKILLSTUDY_ACCBTN[i][3]);
		end
	end
	
	Pet:SkillStudy_MenPaiSkill_Clear();
end

--窗口隐藏函数
function PetSkillStudy_Hide()

	Pet:ClosePetSkillStudyMsgBox()

	this:CareObject(g_clientNpcId, 0, "PetSkillStudy");
	
	PetSkillStudy_Unlock();
	this:Hide();
	Pet:ShowPetList(-1);
	if( g_selidx ~= -1 )then
		Pet:SetPetLocation(g_selidx,-1);
	end
	g_selidx = -1;
	g_stduySkill = false;
	
	
	PetSkillStudy_Blank_ButtonCheck1BK:Hide();
	PetSkillStudy_Blank_ButtonCheck2BK:Hide();
	PetSkillStudy_SkillType_Text:SetText("")
end

--生成珍兽门派技能相关的action，并和ui上的button关联上
function PetSkillStudy_GenMenPaiSkill()
	--if(2 == g_uitype) then
	--	--生成action
	--	for i=2,4 do
	--		PETSKILLSTUDY_ACCBTN[i-1][2] = "menpai";
	--		PETSKILLSTUDY_ACCBTN[i-1][3] = Get_XParam_INT(i);
	--	end
	--	
	--	Pet:SkillStudy_MenPaiSkill_Created(PETSKILLSTUDY_ACCBTN[1][3],PETSKILLSTUDY_ACCBTN[2][3],PETSKILLSTUDY_ACCBTN[3][3]);
	--	
	--	--配置action
	--	for k=1,3 do
	--		local action = Pet:EnumPetSkill(-4444, k-1, "petskill");
	--		if(action:GetID() ~= 0) then
	--			PETSKILLSTUDY_ACCBTN[k][1]:SetActionItem(action:GetID());
	--		end		
	--	end
	--	
	--end
end

function PetSkillStudy_Frame_OnHiden()

	Pet:ClosePetSkillStudyMsgBox()
	PetSkillStudy_MultiIMEEditBox:SetProperty("DefaultEditBox", "False");
	this:CareObject(g_clientNpcId, 0, "PetSkillStudy");
	PetSkillStudy_Unlock();
	this:Hide();
	PetSkillStudy_PetModel:SetFakeObject("")
	Pet:ShowPetList(-1);
	Pet:SetPetLocation(g_selidx,-1);
	g_selidx = -1;
	g_stduySkill = false;
end

function PetSkillStudy_CareEventHandle(careId, op, distance)
		if(nil == careId or nil == op or nil == distance) then
			return;
		end
		
		if(tonumber(careId) ~= g_clientNpcId) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
			PetSkillStudy_Hide();
		end
end

function PetSkillStudy_ShowPetGrow(nGrowLevel)
	local strTbl = {"普通","优秀","杰出","卓越","完美"};
	if(nGrowLevel >= 1 and nGrowLevel <= table.getn(strTbl)) then
		if(strTbl[nGrowLevel]) then
			g_selidx = g_seledidx;
			if g_selidx == -1 or Pet:IsPresent(g_selidx) == false then
				return;
			end
			PetSkillStudy_PetModel:SetFakeObject("");
			Pet:SetSkillStudyModel(g_selidx);
			Pet:SetPetLocation(g_selidx,13);
			PetSkillStudy_PetModel:SetFakeObject( "My_PetStudySkill" );
			
			PetSkillStudy_Text1:SetText("这只珍兽的成长#R"..strTbl[nGrowLevel].."。");
			PetSkillStudy_Accept:Disable();
		end
	end
	PetSkillStudy_Skill1:Hide();	--[tx47256]	
end

function PetSkillStudy_GetTakeLevelCostMoney(ptlv)
	if(nil == ptlv) then return 0; end
	if(nil == g_tlvcostmoney[ptlv]) then return 0; end
	
	return g_tlvcostmoney[ptlv];
end

function PetSkillStudy_GetTakeBabyCostMoney(ptlv, itemId)
	if(nil == ptlv) then return 0; end
	if(nil == g_tbabaymoney[ptlv]) then return 0; end
	
	local costMoney = g_tbabaymoney[ptlv];
	

	
	--终级还童卷轴收费降至90%
	if itemId and itemId ~= -1 then

		if itemId == 30503011 or itemId == 30503012 then
			--珍兽还童卷轴/高级珍兽还童卷轴
		elseif itemId == 30503016 or itemId == 30503017 or itemId == 30503018 or itemId == 30503019 or itemId == 30503020 then
			--终级珍兽还童卷轴
			costMoney = (costMoney * 90) / 100;
			if costMoney <= 0 then
				costMoney = 1;
			end
		else
			--类似 还童丹：兔子
			costMoney = costMoney / 100;
			if costMoney <= 0 then
				costMoney = 1;
			end
		end
	end

	
	return costMoney;
end

--珍兽技能学习：两个不同类手动技能确认“学习”（该事件在 MessageBox_Self 界面中的 PET_SKILL_STUDY_CONFIRM 事件中触发）
function PetSkillStudy_ConfirmPetSkillStudy()

	--PushDebugMessage ("PetSkillStudy_ConfirmPetSkillStudy")

	local saidx = g_selidx_jns
	local slidx = g_selidx

	--当前是否是珍兽技能学习界面....
	if 1 ~= g_uitype then
		return
	end

	if (-1 == slidx) then
		PushDebugMessage("请选择珍兽。")
		return
	end

	if(-1 == saidx) then
		PushDebugMessage("需要技能书。")
		return
	end

	local pM = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")   --交子普及 Vega
	local nM = tonumber(PetSkillStudy_Money:GetProperty("MoneyNumber"))
	if pM < nM then
		PushDebugMessage("金钱不够，无法学习技能")
		return
	end

	Pet:SkillStudy_Do( g_uitype, slidx, PETSKILLSTUDY_ACCBTN[saidx][3] )

	g_stduySkill = true;	--已经学过技能
	--PushDebugMessage("调试信息：手动技能已学会。");

end

function PetSkillStudy_Frame_On_ResetPos()
  PetSkillStudy_Frame:SetProperty("UnifiedPosition", g_PetSkillStudy_Frame_UnifiedPosition);
end

function PetSkillStudy_Blank_Button1_Clicked() 
	g_PetSkillStudy_PetYanShou_YuanbaoPay = PetSkillStudy_Blank_ButtonCheck1:GetCheck();
end

function PetSkillStudy_Blank_Button2_Clicked() 
	g_PetSkillStudy_PetXiDian_YuanbaoPay = PetSkillStudy_Blank_ButtonCheck2:GetCheck();
end
