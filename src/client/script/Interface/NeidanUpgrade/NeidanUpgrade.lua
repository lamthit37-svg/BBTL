

local NeidanUpgrade_Frame_UnifiedPosition;

local g_Neidan_index = -1
local g_NeidanBar_index = -1
local g_NeiDan_Num = -1
local g_NeiDanYuanYe = -1
local g_material_Num = -1

local g_InitList = 0
local g_NeiDanBarList = {}
local g_MaxNeiDanBarNum = 0
local g_MaxNeiDanBagSize = 60

local g_CurrentFilter = 0
local g_TabIndex = 0
local g_CareNpcID = -1

local g_MaterialList = {
    [0]=38007501,
    [1]=38007502,
    [2]=38007503,
}

local g_PND_Level_Image = {
	"set:PetNeidan image:Item1",
	"set:PetNeidan image:Item2",
	"set:PetNeidan image:Item3",
	"set:PetNeidan image:Item4",
	"set:PetNeidan image:Item5",
}
--!!!reloadscript =NeidanUpgrade
function NeidanUpgrade_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ON_SCENE_TRANS");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("ADJEST_UI_POS");
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED");
    this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
    this:RegisterEvent("NEIDAN_DAIBI_CHANGED", false);
    this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);

    this:RegisterEvent("OBJECT_CARED_EVENT")

    this:RegisterEvent("NEIDANUPGRADE_DROP");
    this:RegisterEvent("NEIDANUPGRADE_ENABLE");
    this:RegisterEvent("PACKET_NEIDAN_UPDATE");
end

function NeidanUpgrade_OnLoad()

	NeidanUpgrade_Frame_UnifiedPosition = NeidanUpgrade_Frame:GetProperty("UnifiedPosition");

    ZhenYuan_EquipImage = {
		"set:WM_Button2 image:Equip_Necklace",
		"set:WM_Button2 image:Equip_Ring",
		"set:WM_Button2 image:Equip_Ring",
		"set:WM_Button2 image:Equip_Wrist",
	}

    NeidanUpgrade_Left_Item3_Num:Hide();
    NeidanUpgrade_Left_Item4_Num:Hide();

    NeidanUpgrade_Left_Item1Name:Hide();
    NeidanUpgrade_Left_Item2Name:Hide();

    NeidanUpgrade_Left_Item1_IconJie:Hide();
    NeidanUpgrade_Left_Item2_IconJie:Hide();

    NeidanUpgrade_RightBind:ResetList();
    NeidanUpgrade_RightBind:AddTextItem("#{ZSSJ_230509_40}" ,4);	--全部
    NeidanUpgrade_RightBind:AddTextItem("#{ZSSJ_230509_43}" ,0);    --边缘
    NeidanUpgrade_RightBind:AddTextItem("#{ZSSJ_230509_42}" ,1);	--中层
    NeidanUpgrade_RightBind:AddTextItem("#{ZSSJ_230509_41}" ,2);    --核心

    NeidanUpgrade_RightBind:SetCurrentSelect(0);
    g_CurrentFilter = 4

    NeidanUpgrade_Landan:SetCheck(1)
end

function NeidanUpgrade_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 99855201 then

        local operate = Get_XParam_INT(0);
        if operate == 0 then

            local npcObjId = Get_XParam_INT( 1 )
            if npcObjId >= 0 then
                NeidanUpgrade_BeginCareObject( npcObjId )
            end
            NeidanUpgrade_ChangeTabIndex(0);
            NeidanUpgrade_Open();

        elseif operate == 1 then

            g_NeiDan_Num = Get_XParam_INT(1);
            g_NeiDanYuanYe = Get_XParam_INT(2);
            local zero_count = Get_XParam_INT(3);
            local material_count = Get_XParam_INT(4);
            g_material_Num = Get_XParam_INT(5);
            local money = Get_XParam_INT(6);
            NeidanUpgrade_SetUpgradeData( g_NeiDan_Num, g_NeiDanYuanYe, zero_count, material_count, g_material_Num, money);

        elseif operate == 2 then

            local PosIndex = Get_XParam_INT(1);
            if PosIndex == -1 then
                NeidanUpgrade_ActionButtonClear(0);
                return;
            end

            local theNeiDanAction = DataPool:LuaFnGetNeiDanActionByPosIndex(PosIndex);
            for i = 1, g_MaxNeiDanBarNum do
               local bar = g_NeiDanBarList[i];
               local ctrlAction = bar:GetSubItem("NeidanUpgrade_Right_ItemOption");
               if theNeiDanAction:GetID() ~= 0 and ctrlAction:GetActionItem() ~= -1 and ctrlAction:GetActionItem() == theNeiDanAction:GetID() then
                    NeidanUpgrade_NeiDanRClicked(i);
                    break;
               end
            end

            if g_TabIndex == 0 then

                local data = DataPool:GetPlayerMission_DataRound(2727);
                NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data));

            elseif g_TabIndex == 1 then

                local data = DataPool:GetPlayerMission_DataRound(2729);
                NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data));

            elseif g_TabIndex == 2 then

                local data = DataPool:GetPlayerMission_DataRound(2728);
                NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data));

            end

        elseif operate == 3 then

            g_NeiDan_Num = Get_XParam_INT(1);
            g_NeiDanYuanYe = Get_XParam_INT(2);
            g_material_Num = Get_XParam_INT(3);
            PushEvent("NEIDANUPGRADE_CONFIRM", g_NeiDan_Num, g_Neidan_index, g_NeiDanYuanYe, g_material_Num);
        end

	elseif event == "NEIDANUPGRADE_DROP" then
        if arg0 ~= nil and arg1 ~= nil then
            if NeidanUpgrade_ActionCheck( 0,tonumber(arg0)) == 1 then
                NeidanUpgrade_SetNeiDanAction( tonumber(arg0), tonumber(arg1));
            else
                NeidanUpgrade_ActionButtonClear(0);
            end
        end


    elseif event == "NEIDANUPGRADE_ENABLE" then
        NeidanUpgrade_ActionButtonClear(0);
    elseif event == "NEIDAN_DAIBI_CHANGED" then

        local data = 0
        if g_TabIndex == 0 then

            data = DataPool:GetPlayerMission_DataRound(2727);
            NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data));

        elseif g_TabIndex == 1 then

            data = DataPool:GetPlayerMission_DataRound(2729);
            NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data));

        elseif g_TabIndex == 2 then

            data = DataPool:GetPlayerMission_DataRound(2728);
            NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data));

        end

        if g_NeiDanYuanYe > data then
            NeidanUpgrade_Left_Text9:SetText("#cff0000"..ScriptGlobal_Format("#{ZSSJ_230509_97}", g_NeiDanYuanYe))
        else
            NeidanUpgrade_Left_Text9:SetText("#G#e330000"..ScriptGlobal_Format("#{ZSSJ_230509_97}", g_NeiDanYuanYe))
        end

    elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then

        if NeidanUpgrade_Left_Item1:GetActionItem() == -1 and g_Neidan_index == -1 then
            return 0
        end

        local itemid = g_MaterialList[g_TabIndex]
        local action = DataPool:CreateActionItemForShow( itemid, 1 );
        if action:GetID() ~= 0 then
            NeidanUpgrade_Left_Item4:SetActionItem(action:GetID());

            local num = PlayerPackage:CountAvailableItemByIDTable(itemid)
            if num >= g_material_Num then
                NeidanUpgrade_Left_Item4_Num:SetText(ScriptGlobal_Format("#{ZSSJ_230509_28}", num, g_material_Num));
            else
                NeidanUpgrade_Left_Item4_Num:SetText(ScriptGlobal_Format("#{ZSSJ_230509_29}", num, g_material_Num));
            end
        end

    elseif event == "PACKET_NEIDAN_UPDATE" then

        if g_NeidanBar_index ~= -1 then
            g_NeiDanBarList[g_NeidanBar_index]:GetSubItem("NeidanUpgrade_Right_ItemOption"):Enable();
            local ActionId = g_NeiDanBarList[g_NeidanBar_index]:GetSubItem("NeidanUpgrade_Right_ItemOption"):GetActionItem();
            NeidanUpgrade_UpdatePacketAction();
            for i = 1, g_MaxNeiDanBarNum do
                local bar = g_NeiDanBarList[i];
                local ctrlAction = bar:GetSubItem("NeidanUpgrade_Right_ItemOption");
                if ctrlAction:GetActionItem() ~= -1 and ActionId == ctrlAction:GetActionItem() then
                    NeidanUpgrade_NeiDanRClicked(i);
                    break;
                end
             end
        else
            NeidanUpgrade_UpdatePacketAction();
        end

    elseif(event == "MONEY_CHANGE_EX") then
		NeidanUpgrade_Left_Currency5Num:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "MONEYJZ_CHANGE_EX") then
		NeidanUpgrade_Left_Currency4Num:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	elseif (event == "ADJEST_UI_POS") then
        NeidanUpgrade_Frame_On_ResetPos();
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        NeidanUpgrade_Frame_On_ResetPos();
    elseif (event == "ON_SCENE_TRANS") or (event == "PLAYER_LEAVE_WORLD") then
        NeidanUpgrade_Frame_Close();

    elseif event == "OBJECT_CARED_EVENT" and this:IsVisible() then
		if tonumber( arg0 ) ~= g_CareNpcID then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		local MAX_OBJ_DISTANCE = 3.0
		if arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
            NeidanUpgrade_StopCareObject()
            NeidanUpgrade_Frame_Close()
		end
	end

end




--打开
function NeidanUpgrade_Open()

    if g_InitList == 0 then
        g_MaxNeiDanBarNum = g_MaxNeiDanBagSize

		for i = 1, g_MaxNeiDanBarNum do
			local bar = NeidanUpgrade_RightLace:AddChild("NeidanUpgrade_Right_Item");
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection");
			g_NeiDanBarList[i] = bar;
			bar:GetSubItem("NeidanUpgrade_Right_ItemOption"):SetEvent("MouseMove", string.format("NeidanUpgrade_NeiDanMouseMove(%d);", i));
			bar:GetSubItem("NeidanUpgrade_Right_ItemOption"):SetEvent("MouseRClick", string.format("NeidanUpgrade_NeiDanRClicked(%d);", i));
			bar:GetSubItem("NeidanUpgrade_Right_ItemOption"):SetProperty("DragAcceptName", "WE"..tostring(i));
			bar:GetSubItem("NeidanUpgrade_Right_ItemOption"):SetProperty("DraggingEnabled", "True");
            bar:GetSubItem("NeidanUpgrade_Right_ItemOption_IconJie"):Hide();
		end

		g_InitList = 1;
	end

    NeidanUpgrade_UpdatePacketAction();


    if g_TabIndex == 0 then

        local data = DataPool:GetPlayerMission_DataRound(2727)
        NeidanUpgrade_Left_Currency1:SetText("#{ZSSJ_230509_32}")
        NeidanUpgrade_Left_Currency2:SetText("#{ZSSJ_230509_35}")
        NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data))

    elseif g_TabIndex == 1 then

        local data = DataPool:GetPlayerMission_DataRound(2729)
        NeidanUpgrade_Left_Currency1:SetText("#{ZSSJ_230509_33}")
        NeidanUpgrade_Left_Currency2:SetText("#{ZSSJ_230509_36}")
        NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data))

    elseif g_TabIndex == 2 then

        local data = DataPool:GetPlayerMission_DataRound(2728)
        NeidanUpgrade_Left_Currency1:SetText("#{ZSSJ_230509_34}")
        NeidanUpgrade_Left_Currency2:SetText("#{ZSSJ_230509_37}")
        NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data))

    end
    NeidanUpgrade_Left_Text9:Hide()
    NeidanUpgrade_Left_Currency3Num:SetProperty("MoneyNumber",  tostring(0));
    NeidanUpgrade_Left_Currency5Num:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
    NeidanUpgrade_Left_Currency4Num:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

    this:Show();
end


function NeidanUpgrade_UpdatePacketAction()

    NeidanUpgrade_ActionButtonClear(3);

	local bar_index = 1;
	for	i = 1, g_MaxNeiDanBarNum do
		local bShow = 1;
		local posType = DataPool:LuaFnEnumPetNeiDanPosType(i - 1);
        local pnQual = DataPool:LuaFnEnumPetNeiDanpnQual(i - 1);
        if (posType ~= g_CurrentFilter and g_CurrentFilter ~= 4) or pnQual ~= g_TabIndex then
            bShow = 0;
        end
        if bShow == 1 then
            NeidanUpgrade_Right_SetPacketItem(i - 1, bar_index);
            bar_index = bar_index + 1;
        end
	end

end
function NeidanUpgrade_Right_SetPacketItem(posIndex, idx)

	if g_NeiDanBarList[idx] == nil then
		return;
	end

	local bar = g_NeiDanBarList[idx];
	bar:Show();

	local ctrlAction = bar:GetSubItem("NeidanUpgrade_Right_ItemOption");
	if ctrlAction ~= nil then
		ctrlAction:SetActionItem(-1);
		ctrlAction:SetProperty("DraggingEnabled", "True");
		local theNeiDanAction = DataPool:LuaFnEnumPlayerNeiDanAction(posIndex);
		if theNeiDanAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theNeiDanAction:GetID());
		end
	end

    local pnd_level = DataPool:LuaFnEnumPetNeiDanLevel(posIndex)
	if pnd_level >= 1 and pnd_level <= 5 then
        bar:GetSubItem("NeidanUpgrade_Right_ItemOption_IconJie"):SetProperty("Image", g_PND_Level_Image[pnd_level])
		bar:GetSubItem("NeidanUpgrade_Right_ItemOption_IconJie"):Show()
	end
end


function NeidanUpgrade_SetUpgradeData( neiDanNum, exp, zero_count, material_count, itemNum, money)

    if NeidanUpgrade_Left_Item1:GetActionItem() == -1 and g_Neidan_index == -1 then
        return 0
    end

    local data = 0
    if g_TabIndex == 0 then
        data = DataPool:GetPlayerMission_DataRound(2727)
        NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data))
    elseif g_TabIndex == 1 then
        data = DataPool:GetPlayerMission_DataRound(2729)
        NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data))
    elseif g_TabIndex == 2 then
        data = DataPool:GetPlayerMission_DataRound(2728)
        NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data))
    end

    if exp > data then
        NeidanUpgrade_Left_Text9:SetText("#cff0000"..ScriptGlobal_Format("#{ZSSJ_230509_97}", exp))
    else
        NeidanUpgrade_Left_Text9:SetText("#G#e330000"..ScriptGlobal_Format("#{ZSSJ_230509_97}", exp))
    end


    if zero_count >= neiDanNum then
        NeidanUpgrade_Left_Item3_Num:SetText(ScriptGlobal_Format("#{ZSSJ_230509_28}", zero_count, neiDanNum))
    else
        NeidanUpgrade_Left_Item3_Num:SetText(ScriptGlobal_Format("#{ZSSJ_230509_29}", zero_count, neiDanNum))
    end

    local itemid = g_MaterialList[g_TabIndex]
    local action = DataPool:CreateActionItemForShow( itemid, 1 );
    if action:GetID() ~= 0 then
        NeidanUpgrade_Left_Item4:SetActionItem(action:GetID());
        if material_count >= itemNum then
            NeidanUpgrade_Left_Item4_Num:SetText(ScriptGlobal_Format("#{ZSSJ_230509_28}", material_count, itemNum));
        else
            NeidanUpgrade_Left_Item4_Num:SetText(ScriptGlobal_Format("#{ZSSJ_230509_29}", material_count, itemNum));
        end
    end

    NeidanUpgrade_Left_Currency3Num:SetProperty("MoneyNumber",  tostring(money));

    NeidanUpgrade_Left_Text9:Show();
    NeidanUpgrade_Left_Item3_Num:Show();
    NeidanUpgrade_Left_Item4_Num:Show();

end
function NeidanUpgrade_SetNeiDanAction( arg0, arg1)

    local pnd_name = DataPool:LuaFnGetPetNeiDanName(arg0);

    if arg1 ~= -1 then
        NeidanUpgrade_ActionButtonClear(0)
        g_NeidanBar_index = arg1;
        g_NeiDanBarList[g_NeidanBar_index]:GetSubItem("NeidanUpgrade_Right_ItemOption"):Disable();
    end

    local theDropAction = DataPool:LuaFnEnumPreviewNeiDanAction(1)
    if theDropAction:GetID() ~= 0 then
        NeidanUpgrade_Left_Item1:SetActionItem(theDropAction:GetID());
        g_Neidan_index = arg0;
    end

    local thesameAction = DataPool:LuaFnEnumPreviewNeiDanAction(2)
    if thesameAction:GetID() ~= 0 then
        NeidanUpgrade_Left_Item3:SetActionItem(thesameAction:GetID());
    end

    local theNextLevelAction = DataPool:LuaFnEnumPreviewNeiDanAction(0)
    if theNextLevelAction:GetID() ~= 0 then
        NeidanUpgrade_Left_Item2:SetActionItem(theNextLevelAction:GetID());
    end

    local level = DataPool:LuaFnEnumPetNeiDanLevelByPosIndex(tonumber(arg0))
    if level < 0 then
        return 0
    elseif level > 4 then
        return 0
    end

    NeidanUpgrade_Left_Item1Name:SetText(ScriptGlobal_Format("#{ZSSJ_230509_103}", level, pnd_name));
    NeidanUpgrade_Left_Item2Name:SetText(ScriptGlobal_Format("#{ZSSJ_230509_103}", level + 1, pnd_name));

    NeidanUpgrade_Left_Item1_IconJie:SetProperty("Image", g_PND_Level_Image[level])
    NeidanUpgrade_Left_Item2_IconJie:SetProperty("Image", g_PND_Level_Image[level + 1])

    if level == 0 then
        NeidanUpgrade_Left_Item1_IconJie:Hide()
    else
        NeidanUpgrade_Left_Item1_IconJie:Show()
    end

    NeidanUpgrade_Left_Item2_IconJie:Show()
    NeidanUpgrade_Left_Item1Name:Show()
    NeidanUpgrade_Left_Item2Name:Show()

    Clear_XSCRIPT();
        Set_XSCRIPT_Function_Name("OperateUI");
        Set_XSCRIPT_ScriptID(998552);
        Set_XSCRIPT_Parameter(0,0);
        Set_XSCRIPT_Parameter(1,arg0);
        Set_XSCRIPT_ParamCount(2);
    Send_XSCRIPT();


end
--检查
function NeidanUpgrade_ActionCheck( type, arg0)

	local nLevel =Player:GetLevel();

    if nLevel < 60 then
        PushDebugMessage("#{ZSSJ_230509_44}")
        return 0;
    end

	if(DataPool:Lua_IsMissionHaveDone(3000) ~= 1) then
        PushDebugMessage("#{ZSSJ_230509_45}")
        return 0;
	end

    if type == 0 then

        local posType = DataPool:LuaFnGetPetNeiDanpnQualByPosIndex(tonumber(arg0));
        if posType ~= g_TabIndex then
            if g_TabIndex == 0 then
                PushDebugMessage("#{ZSSJ_230509_51}")
                return 0;
            elseif g_TabIndex == 1 then
                PushDebugMessage("#{ZSSJ_230509_52}")
                return 0;
            elseif g_TabIndex == 2 then
                PushDebugMessage("#{ZSSJ_230509_53}")
                return 0;
            end
        end


        local level = DataPool:LuaFnEnumPetNeiDanLevelByPosIndex(tonumber(arg0))
        if level < 0 then
            return 0
        elseif level >= 5 then
            PushDebugMessage("#{ZSSJ_230509_57}")
            return 0
        end

    elseif type == 1 then

		local itemID = PlayerPackage:GetItemTableIndex(arg0)

        if g_MaterialList[g_TabIndex] == nil then
            return 0;
        end

        if g_MaterialList[g_TabIndex] ~= itemID then

            if g_TabIndex == 0 then
                PushDebugMessage("#{ZSSJ_230509_51}")
                return 0;
            elseif g_TabIndex == 1 then
                PushDebugMessage("#{ZSSJ_230509_52}")
                return 0;
            elseif g_TabIndex == 2 then
                PushDebugMessage("#{ZSSJ_230509_53}")
                return 0;
            end
        end

    else
        return 0;
    end

    return 1
end
function NeidanUpgrade_ActionButtonClear(type)


    if type == 0 then
        --全清
        if g_NeidanBar_index ~= -1 then
            NeidanUpgrade_Left_Item1:SetActionItem(-1);
            g_NeiDanBarList[g_NeidanBar_index]:GetSubItem("NeidanUpgrade_Right_ItemOption"):Enable();
            g_NeidanBar_index = -1;
        end

        g_Neidan_index = -1;
        g_NeiDan_Num = -1;
        g_NeiDanYuanYe = -1;

        --卸下预览
        NeidanUpgrade_Left_Item2:SetActionItem(-1);
        --卸下相同内丹
        NeidanUpgrade_Left_Item3:SetActionItem(-1);
        --卸下材料
        NeidanUpgrade_Left_Item4:SetActionItem(-1);

        NeidanUpgrade_Left_Text9:Hide();
        NeidanUpgrade_Left_Item3_Num:Hide();
        NeidanUpgrade_Left_Item4_Num:Hide();

        NeidanUpgrade_Left_Item1Name:Hide();
        NeidanUpgrade_Left_Item2Name:Hide();

        NeidanUpgrade_Left_Item1_IconJie:Hide();
        NeidanUpgrade_Left_Item2_IconJie:Hide();

        NeidanUpgrade_Left_Currency3Num:SetProperty("MoneyNumber",  tostring(0));

    elseif type == 3 then

        for	i = 1, g_MaxNeiDanBarNum do

            if g_NeiDanBarList[i] == nil then
                return;
            end

	        local bar = g_NeiDanBarList[i];
            bar:GetSubItem("NeidanUpgrade_Right_ItemOption_IconJie"):Hide()
	        local ctrlAction = bar:GetSubItem("NeidanUpgrade_Right_ItemOption");
	        if ctrlAction ~= nil then
		        ctrlAction:SetActionItem(-1);
	        end
        end

    end

end

function NeidanUpgrade_NeiDanRClicked(idx)

    if g_NeiDanBarList[idx] :GetSubItem("NeidanUpgrade_Right_ItemOption"):GetActionItem() == -1 then
        return 0
    end

	if g_NeiDanBarList[idx] ~= nil then
		local ctrlAction = g_NeiDanBarList[idx]:GetSubItem("NeidanUpgrade_Right_ItemOption");
		if ctrlAction ~= nil then

            NeidanUpgrade_ActionButtonClear(0)

			ctrlAction:DoAction();
            g_NeidanBar_index = idx;
            g_NeiDanBarList[idx]:GetSubItem("NeidanUpgrade_Right_ItemOption"):Disable();

		end
	end

end
function NeidanUpgrade_NeiDanMouseMove(idx)

end




--下拉筛选
function NeidanUpgrade_RightBind_Selected()

	local _, nIndex = NeidanUpgrade_RightBind:GetCurrentSelect();
	if g_CurrentFilter == nIndex then
		return;
	end
	g_CurrentFilter = nIndex;
    NeidanUpgrade_UpdatePacketAction();

end

function NeidanUpgrade_UpgradeBtn_Clicked()

    Clear_XSCRIPT();
        Set_XSCRIPT_Function_Name("OperateUI");
        Set_XSCRIPT_ScriptID(998552);
        Set_XSCRIPT_Parameter(0,2);
        Set_XSCRIPT_Parameter(1,g_Neidan_index);
        Set_XSCRIPT_ParamCount(2);
    Send_XSCRIPT();

end

function NeidanUpgrade_ChangeTabIndex(index)

    g_TabIndex = index;

    if g_TabIndex == 0 then

        local data = DataPool:GetPlayerMission_DataRound(2727)
        NeidanUpgrade_Left_Currency1:SetText("#{ZSSJ_230509_32}")
        NeidanUpgrade_Left_Currency2:SetText("#{ZSSJ_230509_35}")
        NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data))

    elseif g_TabIndex == 1 then

        local data = DataPool:GetPlayerMission_DataRound(2729)
        NeidanUpgrade_Left_Currency1:SetText("#{ZSSJ_230509_33}")
        NeidanUpgrade_Left_Currency2:SetText("#{ZSSJ_230509_36}")
        NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data))

    elseif g_TabIndex == 2 then

        local data = DataPool:GetPlayerMission_DataRound(2728)
        NeidanUpgrade_Left_Currency1:SetText("#{ZSSJ_230509_34}")
        NeidanUpgrade_Left_Currency2:SetText("#{ZSSJ_230509_37}")
        NeidanUpgrade_Left_Text11:SetText(ScriptGlobal_Format("#{ZSSJ_230509_97}", data))

    end

    NeidanUpgrade_RightBind:SetCurrentSelect(0)
    g_CurrentFilter = 4;
    NeidanUpgrade_ActionButtonClear(0);
    NeidanUpgrade_UpdatePacketAction();
end




--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function NeidanUpgrade_BeginCareObject( objCaredId )
	g_CareNpcID = DataPool:GetNPCIDByServerID( objCaredId )
	if g_CareNpcID == -1 then
		this:Hide()
		return
	end

	this:CareObject( g_CareNpcID, 1, "NeidanUpgrade" )
	this:Hide()
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function NeidanUpgrade_StopCareObject()
	this:CareObject( g_CareNpcID, 0, "NeidanUpgrade" )
	g_CareNpcID = -1
end



function NeidanUpgrade_Frame_Close()

    NeidanUpgrade_ActionButtonClear(0);
    NeidanUpgrade_RightBind:SetCurrentSelect(0);
    g_CurrentFilter = 4;

    NeidanUpgrade_Landan:SetCheck(1);
    NeidanUpgrade_ChangeTabIndex(0);

    NeidanUpgrade_RightLace:RefreshLayout();
    NeidanUpgrade_RightLace:SetScrollPosition(0);
end

function NeidanUpgrade_Frame_On_ResetPos()

    NeidanUpgrade_Frame:SetProperty("UnifiedPosition", NeidanUpgrade_Frame_UnifiedPosition);

end