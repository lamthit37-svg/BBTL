

local NeidanDowngrade_Frame_UnifiedPosition;

local g_Neidan_index = -1
local g_NeidanBar_index = -1

local g_InitList = 0
local g_NeiDanBarList = {}
local g_MaxNeiDanBarNum = 60

local g_CurrentFilter = 0
local g_CareNpcID = -1


local g_PND_Level_Image = {
	"set:PetNeidan image:Item1",
	"set:PetNeidan image:Item2",
	"set:PetNeidan image:Item3",
	"set:PetNeidan image:Item4",
	"set:PetNeidan image:Item5",
}

--!!!reloadscript =NeidanDowngrade
function NeidanDowngrade_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ON_SCENE_TRANS");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
	this:RegisterEvent("ADJEST_UI_POS");
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED");
    this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);

    this:RegisterEvent( "OBJECT_CARED_EVENT");

    this:RegisterEvent("NEIDANDOWNGRADE_DROP");
    this:RegisterEvent("NEIDANDOWNGRADE_ENABLE");
    this:RegisterEvent("PACKET_NEIDAN_UPDATE");
end

function NeidanDowngrade_OnLoad()

	NeidanDowngrade_Frame_UnifiedPosition = NeidanDowngrade_Frame:GetProperty("UnifiedPosition");

    ZhenYuan_EquipImage = {
		"set:WM_Button2 image:Equip_Necklace",
		"set:WM_Button2 image:Equip_Ring",
		"set:WM_Button2 image:Equip_Ring",
		"set:WM_Button2 image:Equip_Wrist",
	}

    NeidanDowngrade_RightBind:ResetList();
    NeidanDowngrade_RightBind:AddTextItem("#{ZSSJ_230509_40}" ,4);	--全部
    NeidanDowngrade_RightBind:AddTextItem("#{ZSSJ_230509_43}" ,0);  --边缘
    NeidanDowngrade_RightBind:AddTextItem("#{ZSSJ_230509_42}" ,1);	--中层
    NeidanDowngrade_RightBind:AddTextItem("#{ZSSJ_230509_41}" ,2);  --核心

    NeidanDowngrade_RightBind:SetCurrentSelect(0);
    g_CurrentFilter = 4
    NeidanDowngrade_Object2_Num:Hide();

    NeidanDowngrade_Object1_IconJie:Hide();

    NeidanDowngrade_Object1_ItemName:Hide();

end

function NeidanDowngrade_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 99855101 then

        local operate = Get_XParam_INT(0);
        if operate == 0 then

            local npcObjId = Get_XParam_INT( 1 )
            if npcObjId >= 0 then
                NeidanUpgrade_BeginCareObject( npcObjId )
            end
            NeidanDowngrade_Open();

        elseif operate == 1 then

            local neiDanNum = Get_XParam_INT(1);
            local materialNum = Get_XParam_INT(2);
            local material = Get_XParam_INT(3);
            local money = Get_XParam_INT(4);

            NeidanDowngrade_SetUpgradeData( neiDanNum, materialNum, material, money);


        elseif operate == 2 then
            NeidanDowngrade_ActionButtonClear(0);

        elseif operate == 3 then
            PushEvent( "NEIDANDOWNGRADE_CONFIRM", g_Neidan_index);
        end

	elseif event == "NEIDANDOWNGRADE_DROP" then
        if arg0 ~= nil and arg1 ~= nil then
            if NeidanDowngrade_ActionCheck( 0,tonumber(arg0)) == 1 then
                NeidanDowngrade_SetNeiDanAction( tonumber(arg0), tonumber(arg1));
            end
        end

    elseif event == "NEIDANDOWNGRADE_ENABLE" then

        NeidanDowngrade_ActionButtonClear(0);

    elseif event == "PACKET_NEIDAN_UPDATE" then

        NeidanDowngrade_ActionButtonClear(0);
        NeidanDowngrade_UpdatePacketAction();


    elseif(event == "MONEY_CHANGE_EX") then
		NeidanDowngrade_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "MONEYJZ_CHANGE_EX") then
		NeidanDowngrade_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	elseif (event == "ADJEST_UI_POS") then
        NeidanDowngrade_Frame_On_ResetPos();
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        NeidanDowngrade_Frame_On_ResetPos();
    elseif (event == "ON_SCENE_TRANS") or (event == "PLAYER_LEAVE_WORLD") then
        NeidanDowngrade_Frame_Close();

    elseif event == "OBJECT_CARED_EVENT" and this:IsVisible() then
		if tonumber( arg0 ) ~= g_CareNpcID then
			return
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		local MAX_OBJ_DISTANCE = 3.0
		if arg1 == "distance" and tonumber( arg2 ) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
            NeidanDowngrade_StopCareObject()
            NeidanDowngrade_Frame_Close()
		end
	end

end




--打开
function NeidanDowngrade_Open()

    if g_InitList == 0 then
		for i = 1, g_MaxNeiDanBarNum do
			local bar = NeidanDowngrade_RightLace:AddChild("NeidanDowngrade_Right_Item");
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection");
			g_NeiDanBarList[i] = bar
			bar:GetSubItem("NeidanDowngrade_Right_ItemOption"):SetEvent("MouseMove", string.format("NeidanDowngrade_NeiDanMouseMove(%d);", i));
			bar:GetSubItem("NeidanDowngrade_Right_ItemOption"):SetEvent("MouseRClick", string.format("NeidanDowngrade_NeiDanRClicked(%d);", i));
			bar:GetSubItem("NeidanDowngrade_Right_ItemOption"):SetProperty("DragAcceptName", "WE"..tostring(i));
			bar:GetSubItem("NeidanDowngrade_Right_ItemOption"):SetProperty("DraggingEnabled", "True");
            bar:GetSubItem("NeidanDowngrade_Right_ItemOption_IconJie"):Hide();
		end

		g_InitList = 1;
	end

    NeidanDowngrade_UpdatePacketAction();

    NeidanDowngrade_DemandMoney:SetProperty("MoneyNumber",  tostring(0));
    NeidanDowngrade_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
    NeidanDowngrade_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));

    this:Show();
end


function NeidanDowngrade_UpdatePacketAction()

    NeidanDowngrade_ActionButtonClear(3);

	local bar_index = 1;
	for	i = 1, g_MaxNeiDanBarNum do
		local bShow = 1;
		local posType = DataPool:LuaFnEnumPetNeiDanPosType(i - 1);
        local pnQual = DataPool:LuaFnEnumPetNeiDanpnQual(i - 1);
        if (posType ~= g_CurrentFilter and g_CurrentFilter ~= 4) then
            bShow = 0;
        end
        if bShow == 1 then
            NeidanDowngrade_Right_SetPacketItem(i - 1, bar_index);
            bar_index = bar_index + 1;
        end
	end

end
function NeidanDowngrade_Right_SetPacketItem(posIndex, idx)

	if g_NeiDanBarList[idx] == nil then
		return;
	end

	local bar = g_NeiDanBarList[idx];
	bar:Show();

	local ctrlAction = bar:GetSubItem("NeidanDowngrade_Right_ItemOption");
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
		bar:GetSubItem("NeidanDowngrade_Right_ItemOption_IconJie"):Show()
		bar:GetSubItem("NeidanDowngrade_Right_ItemOption_IconJie"):SetProperty("Image", g_PND_Level_Image[pnd_level])
	end
end

function NeidanDowngrade_SetUpgradeData( neiDanNum, materialNum, material, money)

    local neiDanAction = DataPool:LuaFnEnumPreviewNeiDanAction(2);

    if neiDanAction:GetID() ~= 0 then
        NeidanDowngrade_Object2:SetActionItem(neiDanAction:GetID());
        NeidanDowngrade_Object2_Num:SetText("#W#e330000"..neiDanNum)
    end

    local materialAction = DataPool:CreateActionItemForShow(material, materialNum)

    if materialAction:GetID() ~= 0 then
        NeidanDowngrade_Object4:SetActionItem(materialAction:GetID());
    end



    NeidanDowngrade_DemandMoney:SetProperty("MoneyNumber",  tostring(money));
    NeidanDowngrade_Object2_Num:Show();
end
function NeidanDowngrade_SetNeiDanAction( arg0, arg1)

    if arg1 ~= -1 then

        NeidanDowngrade_ActionButtonClear(0)
        g_NeidanBar_index = arg1;
        g_NeiDanBarList[g_NeidanBar_index]:GetSubItem("NeidanDowngrade_Right_ItemOption"):Disable();

    end

    local level = DataPool:LuaFnEnumPetNeiDanLevelByPosIndex(tonumber(arg0))
    local theNeiDanAction = DataPool:LuaFnEnumPreviewNeiDanAction(1);
    if theNeiDanAction:GetID() ~= 0 then
        NeidanDowngrade_Object1:SetActionItem(theNeiDanAction:GetID());
        g_Neidan_index = arg0;

        if level >= 1 and level <= 5 then
            NeidanDowngrade_Object1_IconJie:SetProperty("Image", g_PND_Level_Image[level])
            NeidanDowngrade_Object1_IconJie:Show()
        end
    end

    local pnd_name = DataPool:LuaFnGetPetNeiDanName(arg0);

    NeidanDowngrade_Object1_ItemName:SetText(ScriptGlobal_Format("#{ZSSJ_230509_103}", level, pnd_name));
    NeidanDowngrade_Object1_ItemName:Show();

    Clear_XSCRIPT();
        Set_XSCRIPT_Function_Name("OperateUI");
        Set_XSCRIPT_ScriptID(998551);
        Set_XSCRIPT_Parameter(0,0);
        Set_XSCRIPT_Parameter(1,arg0);
        Set_XSCRIPT_ParamCount(2);
    Send_XSCRIPT();


end
--检查
function NeidanDowngrade_ActionCheck( type, arg0)

	local nLevel =Player:GetLevel();

    if nLevel < 60 then
        PushDebugMessage("#{ZSSJ_230509_44}")
        return 0;
    end

	if(DataPool:Lua_IsMissionHaveDone(3000) ~= 1) then
        PushDebugMessage("#{ZSSJ_230509_45}")
        return 0;
	end

    local level = DataPool:LuaFnEnumPetNeiDanLevelByPosIndex(tonumber(arg0))
    if level <= 0 then
        PushDebugMessage("#{ZSSJ_230509_87}")
        return 0
    end

    return 1
end
function NeidanDowngrade_ActionButtonClear(type)


    if type == 0 then
        --全清
        if g_NeidanBar_index ~= -1 then
            NeidanDowngrade_Object1:SetActionItem(-1);
            NeidanDowngrade_Object2:SetActionItem(-1);
            NeidanDowngrade_Object2_Num:Hide()
            NeidanDowngrade_Object4:SetActionItem(-1);
            g_NeiDanBarList[g_NeidanBar_index]:GetSubItem("NeidanDowngrade_Right_ItemOption"):Enable();
            g_NeidanBar_index = -1;
            g_Neidan_index = -1;
        end

        NeidanDowngrade_DemandMoney:SetProperty("MoneyNumber",  tostring(0));
        NeidanDowngrade_Object1_IconJie:Hide();
        NeidanDowngrade_Object1_ItemName:Hide();

    elseif type == 3 then

        for	i = 1, g_MaxNeiDanBarNum do

            if g_NeiDanBarList[i] == nil then
                return;
            end

	        local bar = g_NeiDanBarList[i];
            bar:GetSubItem("NeidanDowngrade_Right_ItemOption_IconJie"):Hide()
	        local ctrlAction = bar:GetSubItem("NeidanDowngrade_Right_ItemOption");
	        if ctrlAction ~= nil then
		        ctrlAction:SetActionItem(-1);
	        end
        end

    end

end

function NeidanDowngrade_NeiDanRClicked(idx)

    if g_NeiDanBarList[idx] :GetSubItem("NeidanDowngrade_Right_ItemOption"):GetActionItem() == -1 then
        return 0
    end

	if g_NeiDanBarList[idx] ~= nil then
		local ctrlAction = g_NeiDanBarList[idx]:GetSubItem("NeidanDowngrade_Right_ItemOption");
		if ctrlAction ~= nil then

            NeidanDowngrade_ActionButtonClear(0);

            local pnd_level = DataPool:LuaFnEnumPetNeiDanLevel(idx - 1)

            if pnd_level == 0 then
                PushDebugMessage("#{ZSSJ_230509_87}")
                return 0
            end

			ctrlAction:DoAction();
            g_NeidanBar_index = idx;
            g_NeiDanBarList[idx]:GetSubItem("NeidanDowngrade_Right_ItemOption"):Disable();
            

		end
	end

end
function NeidanDowngrade_NeiDanMouseMove(idx)

end




--下拉筛选
function NeidanDowngrade_RightBind_Selected()

	local _, nIndex = NeidanDowngrade_RightBind:GetCurrentSelect();
	if g_CurrentFilter == nIndex then
		return;
	end
	g_CurrentFilter = nIndex;
    NeidanDowngrade_UpdatePacketAction();

end

function NeidanDowngrade_UpgradeBtn_Clicked()

    Clear_XSCRIPT();
        Set_XSCRIPT_Function_Name("OperateUI");
        Set_XSCRIPT_ScriptID(998551);
        Set_XSCRIPT_Parameter(0,2);
        Set_XSCRIPT_Parameter(1,g_Neidan_index);
        Set_XSCRIPT_ParamCount(2);
    Send_XSCRIPT();

end


--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function NeidanDowngrade_BeginCareObject( objCaredId )
	g_CareNpcID = DataPool:GetNPCIDByServerID( objCaredId )
	if g_CareNpcID == -1 then
		this:Hide()
		return
	end

	this:CareObject( g_CareNpcID, 1, "NeidanDowngrade" )
	this:Hide()
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function NeidanDowngrade_StopCareObject()
	this:CareObject( g_CareNpcID, 0, "NeidanDowngrade" )
	g_CareNpcID = -1
end


function NeidanDowngrade_Frame_Close()

    NeidanDowngrade_ActionButtonClear(0);

    NeidanDowngrade_RightBind:SetCurrentSelect(0);
    g_CurrentFilter = 4;

    NeidanDowngrade_RightLace:RefreshLayout();
    NeidanDowngrade_RightLace:SetScrollPosition(0);

end

function NeidanDowngrade_Frame_On_ResetPos()

    NeidanDowngrade_Frame:SetProperty("UnifiedPosition", NeidanDowngrade_Frame_UnifiedPosition);

end