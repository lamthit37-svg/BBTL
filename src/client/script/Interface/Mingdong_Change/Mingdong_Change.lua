
local g_Mingdong_Change_UnifiedPosition = nil
local g_ActionButton = {};
local g_ActionText = {};
local g_ItemIndex = {
	10146944,
	10141574,
	10141634,
	10141372,
	10141373,
	10141374,
	10141375,
};

function Mingdong_Change_PreLoad()

	this:RegisterEvent("UI_COMMAND")
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function Mingdong_Change_OnLoad()
	g_Mingdong_Change_UnifiedPosition = Mingdong_Change_Frame_BK:GetProperty("UnifiedPosition")

	g_ActionButton[1] = Mingdong_Change_Page_Lace1Item;
	g_ActionButton[2] = Mingdong_Change_Page_Lace2Item;
	g_ActionButton[3] = Mingdong_Change_Page_Lace3Item;
	g_ActionButton[4] = Mingdong_Change_Page_Lace4Item;
	g_ActionButton[5] = Mingdong_Change_Page_Lace5Item;
	g_ActionButton[6] = Mingdong_Change_Page_Lace6Item;
	g_ActionButton[7] = Mingdong_Change_Page_Lace7Item;
	
	g_ActionText[1] = Mingdong_Change_Page_Lace1Item_Tip;
	g_ActionText[2] = Mingdong_Change_Page_Lace2Item_Tip;
	g_ActionText[3] = Mingdong_Change_Page_Lace3Item_Tip;
	g_ActionText[4] = Mingdong_Change_Page_Lace4Item_Tip;
	g_ActionText[5] = Mingdong_Change_Page_Lace5Item_Tip;
	g_ActionText[6] = Mingdong_Change_Page_Lace6Item_Tip;
	g_ActionText[7] = Mingdong_Change_Page_Lace7Item_Tip;
end

--===============================================
-- OnEvent()
--===============================================
function Mingdong_Change_OnEvent(event)
	if (event == "UI_COMMAND")  and (tonumber(arg0) == 20141014)  then
		Mingdong_Change_Open();
		this:Show()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		Mingdong_Change_ResetPos()
	elseif(event == "ADJEST_UI_POS") then
		Mingdong_Change_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function Mingdong_Change_Open()
	for i=1, table.getn(g_ItemIndex) do
		local theAction = DataPool:CreateActionItemForShow(g_ItemIndex[i], 1)
		if theAction:GetID() ~= 0 then	
			g_ActionButton[i]:SetActionItem( theAction:GetID() )
			g_ActionText[i]:SetText( "#{MDJH_220613_09}"..theAction:GetName() )
		end
	end
end

function Mingdong_Change_ResetPos()
		Mingdong_Change_Frame_BK:SetProperty("UnifiedPosition",g_Mingdong_Change_UnifiedPosition)
end

function Mingdong_Change_OnHidden()
	this:Hide()
end