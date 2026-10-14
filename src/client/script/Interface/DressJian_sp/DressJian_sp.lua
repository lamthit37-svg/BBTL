local g_DressJian_sp_dressNum = 10;
local g_DressJian_sp_CurSel = -1;
local g_DressJian_sp_Icon = "";
local g_DressJian_sp_bagPos = -1;
local g_DressJian_sp_DressVisualID ={};
local g_DressJian_sp_DressNames = {};
local g_DressJian_sp_DressRate = {};

-- 界面的默认相对位置
local g_DressJian_sp_Frame_UnifiedXPosition;
local g_DressJian_sp_Frame_UnifiedYPosition;

function DressJian_sp_PreLoad()

	this:RegisterEvent("OPEN_DRESSJIAN_SP_DLG");
	this:RegisterEvent("CLOSE_DRESSJIAN_SP_DLG");
	this:RegisterEvent("UPDATE_FAKE_OBJECT")
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function DressJian_sp_OnLoad()

	-- 保存界面的默认相对位置
	g_DressJian_sp_Frame_UnifiedXPosition	= DressJian_sp_Frame : GetProperty("UnifiedXPosition");
	g_DressJian_sp_Frame_UnifiedYPosition	= DressJian_sp_Frame : GetProperty("UnifiedYPosition");

end

function DressJian_sp_OnEvent(event)

	if ( event == "OPEN_DRESSJIAN_SP_DLG" ) then
	
		g_DressJian_sp_bagPos = tonumber(arg0);
		
		DressJian_sp_Init()
		
		this:Show();

	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
	
		this:Hide();
		g_DressJian_sp_CurSel = -1;
		g_DressJian_sp_Icon = "";
		g_DressJian_sp_bagPos = -1;
		g_DressJian_sp_DressVisualID ={};
		g_DressJian_sp_DressNames = {};
		g_DressJian_sp_DressRate = {};

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		DressJian_sp_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		DressJian_sp_Frame_On_ResetPos()

	elseif( event == "UPDATE_FAKE_OBJECT") then
		if (arg0 == "PlayerDressJian_sp" and this:IsVisible() ) then
			DressJian_sp_SetFakeCamera()
		end
		
	elseif (event == "CLOSE_DRESSJIAN_SP_DLG")	then
		DressJian_sp_OnHiden()
		
	end

end

function DressJian_sp_Init()

	g_DressJian_sp_CurSel = -1;
	DressJian_sp_List : ClearListBox();

	--------------------------------------------------
	for i = 0, g_DressJian_sp_dressNum do
		local nVisual, ndesc, nRate = DressReplaceColor:GetSpecialDressDesc(g_DressJian_sp_bagPos, i)
		g_DressJian_sp_DressVisualID[i] = nVisual;		
		g_DressJian_sp_DressNames[i] = ndesc
		g_DressJian_sp_DressRate[i] = nRate;
	end
	
	for i = 0 , g_DressJian_sp_dressNum do
		if g_DressJian_sp_DressVisualID[i] > 0 then
			DressJian_sp_List : AddItem(g_DressJian_sp_DressNames[i], i);
		end
	end
	
	DressJian_sp_FakeObject : DetachWindowEx()
	DressJian_sp_FakeObject : AttachWindowEx("PlayerDressJian_sp")
	SetFakeObjDataEx("PlayerDressJian_sp")
	
	-- 设置使用哪个模型
	DressReplaceColor : FittingOnDressByDressJian_Special(g_DressJian_sp_bagPos, g_DressJian_sp_DressVisualID[0])
	
	--DressJian_sp_SetFakeCamera();

end

function DressJian_sp_Onshow()
		
	-- 设置使用哪个模型
	DressReplaceColor : FittingOnDressByDressJian_Special(g_DressJian_sp_bagPos, g_DressJian_sp_DressVisualID[g_DressJian_sp_CurSel])

	--DressJian_sp_SetFakeCamera();
	
end

function DressJian_sp_SelectOneType( typeIdx )

	if(g_DressJian_sp_CurSel == typeIdx or typeIdx < 0 or typeIdx > g_DressJian_sp_dressNum) then
		return ;
	end
	
	g_DressJian_sp_CurSel = typeIdx;
	
	DressJian_sp_Onshow();
	
end

function DressJian_sp_List_Click()

	local typeIdx =  DressJian_sp_List : GetFirstSelectItem();
	DressJian_sp_SelectOneType( typeIdx );
	
end

----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左)
--
function DressJian_sp_Modle_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			DressJian_sp_FakeObject:RotateBeginEx("PlayerDressJian_sp", -0.3)
		--向左旋转结束
		else
			DressJian_sp_FakeObject:RotateEndEx()
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右)
--
function DressJian_sp_Modle_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			DressJian_sp_FakeObject:RotateBeginEx("PlayerDressJian_sp", 0.3)
		--向右旋转结束
		else
			DressJian_sp_FakeObject:RotateEndEx()
		end
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DressJian_sp_Frame_On_ResetPos()

	DressJian_sp_Frame : SetProperty("UnifiedXPosition", g_DressJian_sp_Frame_UnifiedXPosition);
	DressJian_sp_Frame : SetProperty("UnifiedYPosition", g_DressJian_sp_Frame_UnifiedYPosition);

end

function DressJian_sp_CloseOnclick()
	this : Hide() ;
end

function DressJian_sp_SetFakeCamera()

	local fHeight, fDistance, fPitch = DressJian_sp_FakeObject:GetCameraEx()
	fDistance = 7
	DressJian_sp_FakeObject:SetCameraEx(fHeight, fDistance, fPitch)
	
end

function DressJian_sp_OnHiden()

	DressJian_sp_List:ClearListBox()

	this:Hide()
	
	DressJian_sp_FakeObject:DetachWindowEx()
	
end
