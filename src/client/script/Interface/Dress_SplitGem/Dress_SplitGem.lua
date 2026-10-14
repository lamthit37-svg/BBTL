local objCared = -1
local g_Object = -1
local MAX_OBJ_DISTANCE = 3.0
local Dress_Cloth = -1
local Dress_CHARM_QUALITY = -1
local Dress_GEM_ActButton={}
local Dress_GEM_Feng = {}
local Dress_GEM_Text = {}
local Dress_GEM_Tips = {}
local Dress_GEM_Animate = {}
local Dress_Button
local GEM_SELECTED = {}
local IsTip = 0
local g_Dress_SplitGem_Frame_UnifiedPosition;
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

function Dress_SplitGem_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);	
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);	
	this:RegisterEvent("UPDATE_DRESS_SPLITGEM");
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);
	this:RegisterEvent("OPEN_STALL_SALE")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OPEN_DRESSCLOTH")
end

function Dress_SplitGem_OnLoad()

	Dress_Button	 = Dress_SplitGem_RightClient1_Item --时装
	Dress_GEM_ActButton[1] = Dress_SplitGem_RightClient2_P1_Item			 --配饰1
	Dress_GEM_ActButton[2] = Dress_SplitGem_RightClient2_P2_Item
	Dress_GEM_ActButton[3] = Dress_SplitGem_RightClient2_P3_Item
	
	Dress_GEM_Feng[1] = Dress_SplitGem_RightClient2_P1_Item_Feng2
	Dress_GEM_Feng[2] = Dress_SplitGem_RightClient2_P2_Item_Feng2
	Dress_GEM_Feng[3] = Dress_SplitGem_RightClient2_P3_Item_Feng2

	Dress_GEM_Text[1] = Dress_SplitGem_RightClient2_P1_text2
	Dress_GEM_Text[2] = Dress_SplitGem_RightClient2_P2_text2
	Dress_GEM_Text[3] = Dress_SplitGem_RightClient2_P3_text2	
	
	Dress_GEM_Tips[1] = Dress_SplitGem_RightClient2_P1_Item_tips
	Dress_GEM_Tips[2] = Dress_SplitGem_RightClient2_P2_Item_tips
	Dress_GEM_Tips[3] = Dress_SplitGem_RightClient2_P3_Item_tips
	
	Dress_GEM_Animate[1] = Dress_SplitGem_RightClient2_P1_Item_Animate
	Dress_GEM_Animate[2] = Dress_SplitGem_RightClient2_P2_Item_Animate
	Dress_GEM_Animate[3] = Dress_SplitGem_RightClient2_P3_Item_Animate

	g_Dress_SplitGem_Frame_UnifiedPosition=Dress_SplitGem_Frame:GetProperty("UnifiedPosition");
end

function Dress_SplitGem_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0)==19851274 then
		this:Show()
		Dress_SplitGem_Clear()
		Dress_SplitGem_LeftFrame_FakeObject:SetFakeObject("DressEnchase_Player");
		Dress_SplitGem_TopFrame_Fenye3:SetCheck(1)
		local xx = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(xx);
		if objCared == -1 then
			return;
		end
		BeginCareObject_Dress_SplitGem(objCared)
	elseif ( event == "OPEN_DRESSCLOTH" ) then
		local type = tonumber( arg0 );
		if type == 3 and true ~= this:IsVisible() then
			Dress_SplitGem_CloseOtherWindows()
			this:Show()
			Dress_SplitGem_Clear()
			Dress_SplitGem_LeftFrame_FakeObject:SetFakeObject("DressEnchase_Player");
			Dress_SplitGem_TopFrame_Fenye3:SetCheck(1)
			local objCared = tonumber( Variable:GetVariable("DressClothNPCID") );
			if objCared == -1 then
				return;
			end
			g_Dress_SplitGem_Frame_UnifiedPosition=Variable:GetVariable("DressClothPos")
			Dress_SplitGem_Frame:SetProperty("UnifiedPosition", g_Dress_SplitGem_Frame_UnifiedPosition);
			BeginCareObject_Dress_SplitGem(objCared)			
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			
			--取消关心
			Dress_SplitGem_Cancel_Clicked()
		end
		
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then		
		--g_LastEquipID = -1;
	  --g_LastNeedItemID = -1;	  
		if( arg0~= nil and -1 == tonumber(arg0)) then
			return;
		end		

		if (Dress_Cloth == tonumber(arg0) ) then
				Dress_SplitGem_Clear()
				Dress_SplitGem_Update(23,tonumber(arg0),1)
				--Dress_SplitGem_Explain3:Hide();
		end
	elseif( event == "UPDATE_DRESS_SPLITGEM") then
		if arg0 ~= nil then
			Dress_SplitGem_Update(arg0,arg1,0);
		end
	elseif( event == "RESUME_ENCHASE_GEM_EX") then
		if(arg0~=nil and (tonumber(arg0) == 23 or tonumber(arg0) == 25)) then
			Resume_Dress_Split_Gem(tonumber(arg0))
			if(tonumber(arg0) == 25) then
					Dress_SplitGem_Explain3:Hide() 
			end
		end

	elseif ( event == "OPEN_STALL_SALE" and this:IsVisible() ) then
		--和摆摊界面互斥
		this:Hide()
		
	elseif (event == "ADJEST_UI_POS" ) then
		Dress_SplitGem_Frame_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Dress_SplitGem_Frame_On_ResetPos()

	end
	
		-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			Dress_SplitGem_Closed()
			return
		end
	end
	
	
end

function Dress_SplitGem_Clear()
	if(Dress_Cloth ~= -1) then
		LifeAbility : Lock_Packet_Item(Dress_Cloth,0);
		Dress_Cloth	= -1;
	end
	Dress_Button : SetActionItem(-1);
	Dress_SplitGem_LeftFrame_Jian:Hide()	
	Dress_SplitGem_LeftFrame_Text:SetText("")
	Dress_SplitGem_RestoreFakeObj()

	for i=1,3 do
			Dress_GEM_ActButton[i]:SetActionItem(-1);
			Dress_GEM_Feng[i]:SetProperty("Image","")
			Dress_GEM_Text[i]:SetText("")
			Dress_GEM_Tips[i]:SetToolTip("")		
			Dress_GEM_Tips[i]:Show()		
			Dress_GEM_Feng[i]:Show()
			Dress_GEM_Tips[i]:Show()
			Dress_GEM_Animate[i]:Hide()
			GEM_SELECTED[i] = -1
	end	
end

function BeginCareObject_Dress_SplitGem(objCared)
	g_Object = objCared;
	this:CareObject(g_Object, 1, "Dress_SplitGem");
end

function Dress_SplitGem_Cancel_Clicked()
	Dress_SplitGem_Closed()
end

function Dress_SplitGem_Closed()
	Dress_SplitGem_OnHiden()
	this:Hide()
end

function Dress_SplitGem_OnHiden()
	StopCareObject_Dress_SplitGem(objCared)
	Dress_SplitGem_Clear()
	Dress_SplitGem_LeftFrame_FakeObject:SetFakeObject("");

	if(IsWindowShow("DressJian") == true) then
		PushEvent( "CLOSE_DRESSJIAN_DLG")		
	end	
	
	return
end


function StopCareObject_Dress_SplitGem(objCaredId)
	this:CareObject(objCaredId, 0, "Dress_SplitGem");
	g_Object = -1;
end

function Dress_SplitGem_OnShown()
	Dress_SplitGem_Clear()
end

function Dress_SplitGem_Update(arg0,arg1,IsMessage)
	local ui_Index = tonumber(arg0)
	local bagPos = tonumber(arg1)
	
	local theActionItem = EnumAction(bagPos, "packageitem")
	if ui_Index == 23 then --时装
		if theActionItem:GetID() ~= 0 then
			local dressEquipPoint = LifeAbility : Get_Equip_Point_NoMsg(bagPos)
			if dressEquipPoint~=16 then
				PushDebugMessage("#{SZPR_091023_77}")
				return
			end
			local dress_GemNum = LifeAbility : GetEquip_GemCount(bagPos)
						
			if dress_GemNum > 3 or dress_GemNum<=0 then--有没有石头
				if IsMessage == 0 then
					PushDebugMessage("#{SZZH_170111_82}")
				end
				return
			end
			
			--将之前放入UI的物品解锁
			Dress_SplitGem_Clear()
			Dress_Cloth = bagPos
			Dress_Button:SetActionItem(theActionItem:GetID())
			LifeAbility : Lock_Packet_Item(Dress_Cloth,1)
			Dress_SplitGem_UpdateFakeObj()
		else
			Dress_SplitGem_Clear()
			return
		end
		
		--放上宝石	
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
							Dress_GEM_ActButton[i]:SetProperty("DraggingEnabled","True");
						else
							Dress_GEM_Text[i]:SetText("#{SZZH_170111_34}")
							Dress_GEM_Tips[i]:SetToolTip("#{SZZH_170111_33}")
							Dress_GEM_Tips[i]:Show()							
							Dress_GEM_Feng[i]:SetProperty("Image","set:BaoJianUI image:Dress_Feng")
						end
					end
				end
		end
							
	end	
end

function Resume_Dress_Split_Gem(index)
	if index ~= 23 then
		return
	end
	
	Dress_SplitGem_Clear()
end


function Dress_SplitGem_Selected(Gem_Index)
	if Dress_GEM_ActButton[Gem_Index]:GetActionItem() == -1 then
		return
	end
	
	if GEM_SELECTED[Gem_Index] ~= -1 then
		Dress_GEM_Animate[Gem_Index]:Hide()
		GEM_SELECTED[Gem_Index] = -1
	else
		Dress_GEM_Animate[Gem_Index]:Show()
		GEM_SELECTED[Gem_Index] = Gem_Index
	end

end

function Dress_SplitGem_Buttons_Clicked()

	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	local nSelectCnt = 0
	for i=1,3 do 
		if GEM_SELECTED[i] ~= -1 then
			nSelectCnt = nSelectCnt + 1
		end
	end
	if nSelectCnt == 0 then
		PushDebugMessage("#{SZZH_170111_84}")
		return
	end
	
	if Dress_Cloth == -1 then
		PushDebugMessage("#{SZPR_XML_74}")
		return
	end

	local sCheck = Dress_SplitGem_cost : GetProperty("Selected")
	if sCheck == 'True' then
		IsTip = 1		
	elseif sCheck == 'False' then
		IsTip = 0
	end
		
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(30503136)	
	if itemcount < nSelectCnt then
		if IsTip == 1 then
			PushEvent("CONFIRM_SPLITEGEM",nSelectCnt,nSelectCnt-itemcount)
		else
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("BuySplitFu");
				Set_XSCRIPT_ScriptID(830011);
				Set_XSCRIPT_Parameter(0,nSelectCnt-itemcount);			
				Set_XSCRIPT_ParamCount(1);
			Send_XSCRIPT();				
		end
		return
	end
	
	local nspace = Dress_SplitGem_SpaceNum()
	if nSelectCnt > nspace then
		PushDebugMessage(ScriptGlobal_Format("#{SZZH_170111_86}",nSelectCnt))
		return
	end
	for i=1,3 do 
		if GEM_SELECTED[i] ~= -1 then
			DressEnchasing : Do_Dress_SeparateGem(Dress_Cloth,i-1);
		end
	end
	
	local nDressIndex = PlayerPackage : GetItemTableIndex( Dress_Cloth )
	local szItemName = DataPool:Lua_GetItemNameByIndex(nDressIndex)

	PushDebugMessage(ScriptGlobal_Format("#{SZZH_170111_85}",szItemName,nSelectCnt))
	--DressEnchasing : Do_Dress_SeparateGem(Dress_Cloth,GEM_SELECTED-1,Dress_CHARM_QUALITY);
	--Resume_Dress_Split_Gem(23)--清空界面
	--Resume_Dress_Split_Gem(25)
	--Dress_CHARM_QUALITY = -1

end

function Dress_SplitGem_Frame_On_ResetPos()
  Dress_SplitGem_Frame:SetProperty("UnifiedPosition", g_Dress_SplitGem_Frame_UnifiedPosition);
end

function Dress_SplitGem_UpdateFakeObj()
	DressEnchasing : FittingOnDressNew (Dress_Cloth,-1,-1,-1)
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
		
	Dress_SplitGem_LeftFrame_Jian:Show()
	Dress_SplitGem_LeftFrame_Text:SetText(strdic)
end

function Dress_SplitGem_RestoreFakeObj()
	-- 恢复试衣前的装备参数
	DressEnchasing : RestoreDressEnchaseFitting()
end

function Dress_SplitGem_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			Dress_SplitGem_LeftFrame_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			Dress_SplitGem_LeftFrame_FakeObject:RotateEnd();
		end
	end
end

function Dress_SplitGem_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			Dress_SplitGem_LeftFrame_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			Dress_SplitGem_LeftFrame_FakeObject:RotateEnd();
		end
	end
end

function Dress_SplitGem_Clicked()
	local canPaint = DressReplaceColor:DressCanPaint(Dress_Cloth)
	if canPaint ~= 1 then
		PushDebugMessage("该时装不能染色，不能查看图鉴。")
		return
	end
	DressReplaceColor :DressOpenDressJian(Dress_Cloth);
end

function Dress_SplitGem_FenYeClick(index)
	if index == 1 or index == 2 or index == 4 then
		Variable:SetVariable("DressClothPos", Dress_SplitGem_Frame:GetProperty("UnifiedPosition"), 1);
		Variable:SetVariable("DressClothNPCID", g_Object, 1);
		PushEvent("OPEN_DRESSCLOTH",index)	
	end
end

function Dress_SplitGem_CloseOtherWindows()
	if(IsWindowShow("Dress_Stiletto")) then
		CloseWindow("Dress_Stiletto", true);
	end			
	if(IsWindowShow("Dress_Transfer")) then
		CloseWindow("Dress_Transfer", true);
	end			
	if(IsWindowShow("Dress_Enchase")) then
		CloseWindow("Dress_Enchase", true);
	end			
	
	PushEvent( "CLOSE_DRESSPREVIEW")
	PushEvent( "CLOSE_GEMEFFECTPREVIEW") 	
end

--- 得到当前材料包有多少空位
function Dress_SplitGem_SpaceNum()
  local CurrBagNum = DataPool:GetMatBag_Num()
  local curMatNum  = 0
	for i=1, CurrBagNum do
        local theAction,bLocked = PlayerPackage:EnumItem( "material", i-1 );
        if theAction : GetID() ~= 0 then
            curMatNum = curMatNum + 1
        end
    end
    return CurrBagNum - curMatNum
end