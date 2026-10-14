local EQUIP_BUTTONS;

local MATERIAL_BUTTONS;
local MATERIAL_QUALITY = -1;
local Need_Item = 0
local Need_Money =0
local Need_Item_Count = 0
local Bore_Count=-1
local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local costMoneyArray = {3000, 3600, 4200}
local g_Object = -1;
local Max_Dress_Bore_Count = 3
local Dress_Stiletto_CostItemIndex = -1;
local Dress_Cloth = -1
local Dress_GEM_ActButton = {}
local Dress_GEM_Feng = {}
local Dress_GEM_Text = {}
local Dress_GEM_Tips = {}

local g_FeiyuNewDressID = {
10126162,--	新锦衣卫嫣然
10126163,--	新锦衣卫红翡
10126164,--	新锦衣卫青蓝
}
local g_FeiyuDressStr = {
"#{FYYR_200610_34}",
"#{FYYR_200610_35}",
"#{FYYR_200610_36}",
}

local g_Dress_Stiletto_Frame_UnifiedPosition;

function Dress_Stiletto_PreLoad()

	this:RegisterEvent("DRESS_STILETTO_UPDATE");
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);
	this:RegisterEvent("OPEN_STALL_SALE")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OPEN_DRESSCLOTH")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);	
end

function Dress_Stiletto_OnLoad()
	EQUIP_BUTTONS = Dress_Stiletto_RightClient1_Item
	
	Dress_GEM_ActButton[1] = Dress_Stiletto_RightClient2_P1_Item
	Dress_GEM_ActButton[2] = Dress_Stiletto_RightClient2_P2_Item	
	Dress_GEM_ActButton[3] = Dress_Stiletto_RightClient2_P3_Item
	
	Dress_GEM_Feng[1] = Dress_Stiletto_RightClient2_P1_Item_Feng
	Dress_GEM_Feng[2] = Dress_Stiletto_RightClient2_P2_Item_Feng
	Dress_GEM_Feng[3] = Dress_Stiletto_RightClient2_P3_Item_Feng

	Dress_GEM_Text[1] = Dress_Stiletto_RightClient2_P1_text2
	Dress_GEM_Text[2] = Dress_Stiletto_RightClient2_P2_text2
	Dress_GEM_Text[3] = Dress_Stiletto_RightClient2_P3_text2	
	
	Dress_GEM_Tips[1] = Dress_Stiletto_RightClient2_P1_Item_tips
	Dress_GEM_Tips[2] = Dress_Stiletto_RightClient2_P2_Item_tips
	Dress_GEM_Tips[3] = Dress_Stiletto_RightClient2_P3_Item_tips
	
	g_Dress_Stiletto_Frame_UnifiedPosition=Dress_Stiletto_Frame:GetProperty("UnifiedPosition");
end

function Dress_Stiletto_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20091027) then
		local type = Get_XParam_INT(1);
		if type == 0 then
			Dress_Stiletto_CloseOtherWindows()	
			Dress_Stiletto_TopFrame_Fenye1:SetCheck(1)
			this:Show();
			-- 清空物品槽
			Dress_Stiletto_Clear();
			local xx = Get_XParam_INT(0);
			objCared = DataPool : GetNPCIDByServerID(xx);
			if objCared == -1 then
					return;
			end
			BeginCareObject_Dress_Stiletto(objCared)
			Dress_Stiletto_InitFakeObj()
		elseif type == 1 then  --更新一下界面
			Dress_Stiletto_Update('1',tostring( Dress_Cloth ))
			Dress_Stiletto_UpdateMoney()
		elseif type == 2 then  --打满了 摘下来
			Resume_Equip_Dress_Stiletto(1);
		end
	elseif ( event == "OPEN_DRESSCLOTH" ) then
		local type = tonumber( arg0 );
		if type == 1 and true ~= this:IsVisible() then
			Dress_Stiletto_CloseOtherWindows()	
			Dress_Stiletto_TopFrame_Fenye1:SetCheck(1)
			this:Show();
			-- 清空物品槽
			Dress_Stiletto_Clear();
			objCared = tonumber( Variable:GetVariable("DressClothNPCID") )
			g_Dress_Stiletto_Frame_UnifiedPosition = Variable:GetVariable("DressClothPos")
			if objCared == -1 then
					return;
			end
			BeginCareObject_Dress_Stiletto(objCared)
			Dress_Stiletto_InitFakeObj()		
			Dress_Stiletto_Frame:SetProperty("UnifiedPosition", g_Dress_Stiletto_Frame_UnifiedPosition);
		end		
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			
			--取消关心
			Dress_Stiletto_Cancel_Clicked()
		end

	elseif( event == "DRESS_STILETTO_UPDATE") then
		if arg0 == nil or arg1 == nil then
			return
		end 

		Dress_Stiletto_Update(tonumber(arg0),tonumber(arg1));		

	elseif( event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() ) then
		if(arg0~=nil and tonumber(arg0) == 1) then---xml里配置的是D1
			Resume_Equip_Dress_Stiletto(1);
		end
		
	elseif ( event == "OPEN_STALL_SALE" and this:IsVisible() ) then
		--和摆摊界面互斥
		this:Hide()
		
	elseif (event == "ADJEST_UI_POS" ) then
		Dress_Stiletto_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Dress_Stiletto_Frame_On_ResetPos()
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		Dress_Stiletto_RightFrame_FunClient_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));	
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		Dress_Stiletto_RightFrame_FunClient_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));	
	end
	
	-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			Dress_Stiletto_Close()
			return
		end
	end
end

function Dress_Stiletto_OnShown()
	Dress_Stiletto_Clear()
end

function Dress_Stiletto_Clear()
	if(Dress_Cloth ~= -1) then
		LifeAbility : Lock_Packet_Item(Dress_Cloth,0);
		Dress_Cloth	= -1;
	end
	EQUIP_BUTTONS : SetActionItem(-1);
	Dress_Stiletto_RightFrame_FunClient_DemandMoney:SetProperty("MoneyNumber", 0);
	local nMoneyNow,nGold,nSilverCoin,nCopperCoin = Player:GetData("MONEY");
	Dress_Stiletto_RightFrame_FunClient_SelfMoney:SetProperty("MoneyNumber", tostring(nMoneyNow));
	Dress_Stiletto_RightFrame_FunClient_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))	
	Dress_Stiletto_LeftFrame_Jian:Hide()	
	Dress_Stiletto_LeftFrame_Text:SetText("")
	Dress_Stiletto_RestoreFakeObj()
	Dress_Stiletto_RightFrame_Intro:SetText("#{SZZH_170111_27}")
	
	for i=1,3 do
			Dress_GEM_ActButton[i]:SetActionItem(-1);
			Dress_GEM_Feng[i]:SetProperty("Image","")
			Dress_GEM_Text[i]:SetText("")
			Dress_GEM_ActButton[i]:SetToolTip("")
			Dress_GEM_Tips[i]:Hide()
			Dress_GEM_Feng[i]:Show()
	end	
end

function Dress_Stiletto_Update(pos1,pos0)
	local pos_packet,pos_ui;
	pos_packet = tonumber(pos0);
	pos_ui		 = tonumber(pos1)
	
	local theAction = EnumAction(pos_packet, "packageitem");
	if pos_ui == 1 then
		if theAction:GetID() ~= 0 then
			local ncount = LifeAbility : GetEquip_HoleCount(pos_packet)
			if ncount > 2 then 
				PushDebugMessage("#{SZPR_091023_35}")
				--Dress_Stiletto_Clear()
				return
			end
			
			Bore_Count = ncount
			--将之前加锁物品解锁
			Dress_Stiletto_Clear()

			--加锁
			EQUIP_BUTTONS:SetActionItem(theAction:GetID());
			Dress_Cloth = pos_packet;
			LifeAbility : Lock_Packet_Item(Dress_Cloth,1);
			Dress_StilettoJian_Update()
			Dress_Stiletto_RightFrame_FunClient_DemandMoney : SetProperty("MoneyNumber", tostring(costMoneyArray[Bore_Count+1]));
			Dress_Stiletto_UpdateFakeObj()
			Dress_Stiletto_RightFrame_Intro:SetText("#{SZZH_170111_27}"..ScriptGlobal_Format("#{SZZH_170216_134}",Bore_Count,3-Bore_Count))
			
			--设置DataPool中的m_vGemSeparateList
			local Dress_Bore_Count = LifeAbility : GetEquip_HoleCount(Dress_Cloth)		-- 得到时装上的宝石孔数目
			if not LifeAbility:SplitGem_Update(Dress_Cloth) then --设置失败
				for i=1,3 do
					Dress_GEM_ActButton[i] : SetActionItem(-1)
					Dress_GEM_Feng[i]:SetProperty("Image","set:BaoJianUI image:Dress_Feng")
				end
			else
				for i=1,3 do		
					nItemID = LifeAbility : GetSplitGem_Gem (i-1);
					local gemid = LifeAbility:GetEquip_GemID(Dress_Cloth , i-1)
					if nItemID ~= -1 then		
						ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID);
						local GemName = DoubleGem:GetGemNamebyID(gemid)

						Dress_GEM_ActButton[i] : SetActionItem(ActionID);
						Dress_GEM_Feng[i]:SetProperty("Image","")
						Dress_GEM_Text[i]:SetText(GemName)
						Dress_GEM_Tips[i]:SetToolTip(GemName)
						Dress_GEM_Tips[i]:Show()
	
					else
						Dress_GEM_ActButton[i] : SetActionItem(-1)
						if Dress_Bore_Count >= i then
							Dress_GEM_Feng[i]:SetProperty("Image","")
							Dress_GEM_Text[i]:SetText("#{SZZH_170111_36}")
							Dress_GEM_ActButton[i]:SetToolTip("#{SZZH_170111_35}")
							Dress_GEM_Tips[i]:Hide()
							Dress_GEM_Feng[i]:Hide()
							--Dress_GEM_ActButton[i]:SetProperty("DraggingEnabled","True");
						else
							Dress_GEM_Text[i]:SetText("#{SZZH_170111_34}")
							Dress_GEM_Tips[i]:SetToolTip("#{SZZH_170111_33}")
							Dress_GEM_Tips[i]:Show()
							Dress_GEM_Feng[i]:SetProperty("Image","set:BaoJianUI image:Dress_Feng")					
							Dress_GEM_Feng[i]:Show()	
						end
					end
				end
			end	

		else
			EQUIP_BUTTONS:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(Dress_Cloth,0);
			Dress_Cloth = -1;
			Dress_Stiletto_Money : SetProperty("MoneyNumber", "");

			return;
		end
	end
	
end

function Dress_Stiletto_Buttons_Clicked()
	if Dress_Cloth ~= -1 and Bore_Count ~= -1 then
		if Bore_Count > Max_Dress_Bore_Count-1 then
			PushDebugMessage("#{SZPR_091023_35}")
			return 
		end
		if Player:GetData("MONEY") + Player:GetData("MONEY_JZ") < costMoneyArray[Bore_Count+1] then
			PushDebugMessage("#{RXZS_090804_11}")
			return
		else

		local sCheck = Dress_Stiletto_cost : GetProperty("Selected")
		if sCheck == 'True' then
			IsTip = 1		
		elseif sCheck == 'False' then
			IsTip = 0
		end
				
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("OnDress_Stiletto");
				Set_XSCRIPT_ScriptID(830011);
				Set_XSCRIPT_Parameter(0,Dress_Cloth);
				Set_XSCRIPT_Parameter(1,IsTip);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
		end
	else
		PushDebugMessage("#{SZPR_091023_84}")
	end	
end

function Dress_Stiletto_Close()
	--将加锁物品解锁
	this:Hide();
	Dress_Stiletto_Clear();
	StopCareObject_Dress_Stiletto(objCared)
	Dress_Stiletto_LeftFrame_FakeObject:SetFakeObject("");

	if(IsWindowShow("DressJian") == true) then
		PushEvent( "CLOSE_DRESSJIAN_DLG")		
	end	
		
end

function Dress_Stiletto_Cancel_Clicked()
	Dress_Stiletto_Close();
	return;
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_Dress_Stiletto(objCaredId)

	g_Object = objCaredId;
	this:CareObject(g_Object, 1, "Dress_Stiletto");

end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_Dress_Stiletto(objCaredId)
	this:CareObject(objCaredId, 0, "Dress_Stiletto");
	g_Object = -1;

end

function Resume_Equip_Dress_Stiletto(nIndex)
	if( this:IsVisible() ) then	
		Dress_Stiletto_Clear()
	end	
end

function Dress_Stiletto_Frame_On_ResetPos()
  Dress_Stiletto_Frame:SetProperty("UnifiedPosition", g_Dress_Stiletto_Frame_UnifiedPosition);
end

function Dress_StilettoJian_Update()

	local strdic;
	local nDressId = PlayerPackage : GetItemTableIndex( Dress_Cloth )
	if nDressId == g_FeiyuNewDressID[1] then
  		strdic = g_FeiyuDressStr[1]
	elseif nDressId == g_FeiyuNewDressID[2] then
		strdic = g_FeiyuDressStr[2]
	elseif nDressId == g_FeiyuNewDressID[3] then
		strdic = g_FeiyuDressStr[3]
	else
		local n_szDressDesc, nRate,MaterBind = DressReplaceColor : GetDressVisualInfo(Dress_Cloth)	
		if nRate == 23000 then
			strdic = ScriptGlobal_Format("#{SZRSYH_120912_10}", n_szDressDesc)
		elseif nRate == 14000 then
			strdic = ScriptGlobal_Format("#{SZRSYH_120912_11}", n_szDressDesc)
		elseif nRate == 1000 then
			strdic = ScriptGlobal_Format("#{SZRSYH_120912_12}", n_szDressDesc)
		elseif nRate == -1 then
			strdic = "#G"..n_szDressDesc
		end
	end
		
	Dress_Stiletto_LeftFrame_Jian:Show()
	Dress_Stiletto_LeftFrame_Text:SetText(strdic)
end

function Dress_Stiletto_InitFakeObj()
	Dress_Stiletto_LeftFrame_FakeObject:SetFakeObject("");
	Dress_Stiletto_LeftFrame_FakeObject:SetFakeObject("DressEnchase_Player");
end

function Dress_Stiletto_UpdateFakeObj()
	DressEnchasing : FittingOnDressNew (Dress_Cloth,-1,-1,-1)
end

function Dress_Stiletto_RestoreFakeObj()
	-- 恢复试衣前的装备参数
	DressEnchasing : RestoreDressEnchaseFitting()
end

function Dress_Stiletto_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			Dress_Stiletto_LeftFrame_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			Dress_Stiletto_LeftFrame_FakeObject:RotateEnd();
		end
	end
end

function Dress_Stiletto_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			Dress_Stiletto_LeftFrame_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			Dress_Stiletto_LeftFrame_FakeObject:RotateEnd();
		end
	end
end

function Dress_Stiletto_Clicked()
	local canPaint = DressReplaceColor:DressCanPaint(Dress_Cloth)
	if canPaint ~= 1 then
		PushDebugMessage("该时装不能染色，不能查看图鉴。")
		return
	end
	DressReplaceColor :DressOpenDressJian(Dress_Cloth);
end

function Dress_Stiletto_UpdateMoney()
	local Bore_Count = LifeAbility : GetEquip_HoleCount(Dress_Cloth)
	Dress_Stiletto_RightFrame_FunClient_DemandMoney : SetProperty("MoneyNumber", tostring(costMoneyArray[Bore_Count+1]));	
	local nMoneyNow,nGold,nSilverCoin,nCopperCoin = Player:GetData("MONEY");
	Dress_Stiletto_RightFrame_FunClient_SelfMoney:SetProperty("MoneyNumber", tostring(nMoneyNow));
	Dress_Stiletto_RightFrame_FunClient_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))		
end

function Dress_Stiletto_CloseOtherWindows()
	if(IsWindowShow("Dress_Enchase")) then
		CloseWindow("Dress_Enchase", true);
	end			
	if(IsWindowShow("Dress_Transfer")) then
		CloseWindow("Dress_Transfer", true);
	end			
	if(IsWindowShow("Dress_SplitGem")) then
		CloseWindow("Dress_SplitGem", true);
	end
		PushEvent( "CLOSE_DRESSPREVIEW") 	
		PushEvent( "CLOSE_GEMEFFECTPREVIEW")		
end

function Dress_Stiletto_FenYeClick(index)
	if index == 2 or index == 3 or index == 4 then
		Variable:SetVariable("DressClothPos", Dress_Stiletto_Frame:GetProperty("UnifiedPosition"), 1);
		Variable:SetVariable("DressClothNPCID", g_Object, 1);
		PushEvent("OPEN_DRESSCLOTH",index)	
	end
end
