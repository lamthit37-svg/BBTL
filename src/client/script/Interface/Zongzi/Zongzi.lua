local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;
local g_ZongziInfo_Table= {}
local g_Material_Frame = {}
local g_Material_Icon = {}
local g_Material_Num = {}
local g_Material_Mask = {}

local g_Zongzi_Flag = -1
local g_Material_Need = {}
local g_Material_Have = {}
local g_Material_ID = {}

local g_Zongzi_ID = {}

local g_check = 0

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

function Zongzi_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 切场景
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("OBJECT_CARED_EVENT",false);

end

function Zongzi_OnLoad()

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Zongzi_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Zongzi_Frame:GetProperty("UnifiedYPosition");

	-- 粽子的大图
	g_ZongziInfo_Table[1] = ZongZi_Frame_Tu1;
	g_ZongziInfo_Table[2] = ZongZi_Frame_Tu2;
	g_ZongziInfo_Table[3] = ZongZi_Frame_Tu3;

	-- 粽子的材料
	g_Material_Frame[1] = Zongzi_MaterialIcon1_Frame1;
	g_Material_Frame[2] = Zongzi_MaterialIcon1_Frame2;
	g_Material_Frame[3] = Zongzi_MaterialIcon2_Frame1;
	g_Material_Frame[4] = Zongzi_MaterialIcon2_Frame2;
	g_Material_Frame[5] = Zongzi_MaterialIcon2_Frame3;
	g_Material_Frame[6] = Zongzi_MaterialIcon3_Frame1;
	g_Material_Frame[7] = Zongzi_MaterialIcon3_Frame2;
	g_Material_Frame[8] = Zongzi_MaterialIcon3_Frame3;

	g_Material_Icon[1] = Zongzi_MaterialIcon1;
	g_Material_Icon[2] = Zongzi_MaterialIcon2;
	g_Material_Icon[3] = Zongzi_MaterialIcon3;
	g_Material_Icon[4] = Zongzi_MaterialIcon4;
	g_Material_Icon[5] = Zongzi_MaterialIcon5;
	g_Material_Icon[6] = Zongzi_MaterialIcon6;
	g_Material_Icon[7] = Zongzi_MaterialIcon7;
	g_Material_Icon[8] = Zongzi_MaterialIcon8;

	g_Material_Num[1] = Zongzi_MaterialIcon1_Amount1;
	g_Material_Num[2] = Zongzi_MaterialIcon1_Amount2;
	g_Material_Num[3] = Zongzi_MaterialIcon2_Amount1;
	g_Material_Num[4] = Zongzi_MaterialIcon2_Amount2;
	g_Material_Num[5] = Zongzi_MaterialIcon2_Amount3;
	g_Material_Num[6] = Zongzi_MaterialIcon3_Amount1;
	g_Material_Num[7] = Zongzi_MaterialIcon3_Amount2;
	g_Material_Num[8] = Zongzi_MaterialIcon3_Amount3;

	g_Material_Mask[1] = Zongzi_MaterialIcon1_Mask1;
	g_Material_Mask[2] = Zongzi_MaterialIcon1_Mask2;
	g_Material_Mask[3] = Zongzi_MaterialIcon2_Mask1;
	g_Material_Mask[4] = Zongzi_MaterialIcon2_Mask2;
	g_Material_Mask[5] = Zongzi_MaterialIcon2_Mask3;
	g_Material_Mask[6] = Zongzi_MaterialIcon3_Mask1;
	g_Material_Mask[7] = Zongzi_MaterialIcon3_Mask2;
	g_Material_Mask[8] = Zongzi_MaterialIcon3_Mask3;

	-- 选中粽子标识
	g_Zongzi_Flag = -1
	g_check = 0

	for i=1, 8 do
		g_Material_Need[i] = 1;
		g_Material_ID[i] = 0;
		g_Material_Have[i] = 0;
	end

	for i=1,3 do
		g_Zongzi_ID[i] = 0;
	end

end

function Zongzi_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Zongzi_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		Zongzi_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this : Hide()
		this:CareObject(objCared, 0, "Zongzi");
	elseif ( event == "UI_COMMAND") and (tonumber(arg0) == 20150529)  then
		if Get_XParam_INT(0) == 1 then
			--关注NPC
			objCared = Target:GetServerId2ClientId( tonumber( Get_XParam_INT(1)));
			Zongzi_Init();
		else
			g_check = 0
			Zongzi_FreshDate()
		end
		g_Zongzi_Flag = -1
		for i=1, 3 do
			g_ZongziInfo_Table[i]:SetPushed(0);
		end
		this : Show();

		this:CareObject(objCared, 1, "Zongzi");
	elseif (event == "OBJECT_CARED_EVENT") then
		--AxTrace(0, 0, "arg0"..arg0.." arg1"..arg1.." arg2"..arg2);
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();

			--取消关心
			this:CareObject(objCared, 0, "Zongzi");
		end
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Zongzi_ResetPos()
	Zongzi_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Zongzi_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--================================================
-- 初始化数据
--================================================
function Zongzi_Init()

	-- 普通粽子
	g_Zongzi_ID[1] = 38001260;
	g_Material_ID[1] = 38001256;
	g_Material_ID[2] = 38001257;

	-- 精品粽子
	g_Zongzi_ID[2] = 38001261;
	g_Material_ID[3] = 38001256;
	g_Material_ID[4] = 38001258;
	g_Material_ID[5] = 38001257;

	-- 特技粽子
	g_Zongzi_ID[3] = 38001262;
	g_Material_ID[6] = 38001256;
	g_Material_ID[7] = 38001259;
	g_Material_ID[8] = 38001257;

	g_check = 0

	Zongzi_FreshDate();

	for i=1,3 do
		local name,icon = LifeAbility : GetPrescr_Material(g_Zongzi_ID[i]);
		g_ZongziInfo_Table[i] : SetProperty("ShortImage",icon);
		g_ZongziInfo_Table[i] : Show();
	end

	DataPool:Lua_ClearZongziActionItem();
	for i=1, 3 do
			DataPool:Lua_SetZongziActionItem( i-1, g_Zongzi_ID[i] );
	end
	for i=4, 11 do
			DataPool:Lua_SetZongziActionItem( i-1, g_Material_ID[i-3] );
	end

	DataPool:Lua_UpdateZongziActionItem();
	for i=1, 3 do
		local theAction = EnumAction( i-1, "zongzi_item");
		if theAction:GetID() ~= 0 then
			g_ZongziInfo_Table[i]:SetActionItem( theAction:GetID() );
		else
			g_ZongziInfo_Table[i]:SetActionItem( -1 );
		end
	end

	for i=1, 8 do
		local theAction = EnumAction( i+2, "zongzi_item");
		if theAction:GetID() ~= 0 then
			g_Material_Icon[i]:SetActionItem( theAction:GetID() );
		else
			g_Material_Icon[i]:SetActionItem( -1 );
		end
	end

	for i=1, 3 do
		g_ZongziInfo_Table[i]:SetPushed(0);
	end

end

--================================================
-- 刷新物品数量
--================================================
function Zongzi_FreshDate()

	for i=1,8 do
		g_Material_Need[i] = 1;
		g_Material_Have[i] = PlayerPackage:CountAvailableItemByIDTable(g_Material_ID[i])
		g_Material_Num[i] : SetText("#e010101" .. g_Material_Have[i] .. "/" .."#e010101" .. g_Material_Need[i] );

		g_Material_Icon[i]:Show();

		if g_Material_Have[i] < g_Material_Need[i] then
			g_Material_Mask[i]:Show();
		else
			g_Material_Mask[i]:Hide();
		end
	end

end

--================================================
-- 粽子点击事件
--================================================
function Zongzi_Tu_clicked(Item_index)
	-- 给个默认值
	g_Zongzi_Flag = -1
	if Item_index >= 1 and Item_index <= 3 then
		g_Zongzi_Flag = Item_index
	end

	-- 刷新物品数量
	Zongzi_FreshDate();

	for i=1, 3 do
		if i == Item_index then
			g_ZongziInfo_Table[i]:SetPushed(1);
		else
			g_ZongziInfo_Table[i]:SetPushed(0);
		end
	end
end

--================================================
-- 关闭界面事件
--================================================
function Zongzi_Close()
	this:Hide();

	this:CareObject(objCared, 0, "Zongzi");
end

--================================================
-- 包粽子
--================================================
function Zongzi_AllMake_Clicked()

	-- 安全时间判断
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{LZZZ_150526_51}")
		return
	end

	-- 畅游+ 硬件密保 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	-- 未选粽子
	if g_Zongzi_Flag < 0 or g_Zongzi_Flag > 3 then
		PushDebugMessage("#{LZZZ_150526_56}")
		return
	end

	--材料够不够
	local Material_OK = 1
	if g_Zongzi_Flag == 1 then
		if g_Material_Have[1] < g_Material_Need[1] or g_Material_Have[2] < g_Material_Need[2] then
			Material_OK = -1
		end
	elseif g_Zongzi_Flag == 2 then
		if g_Material_Have[3] < g_Material_Need[3] or g_Material_Have[4] < g_Material_Need[4] or g_Material_Have[5] < g_Material_Need[5] then
			Material_OK = -1
		end
	elseif g_Zongzi_Flag == 3 then
		if g_Material_Have[6] < g_Material_Need[6] or g_Material_Have[7] < g_Material_Need[7] or g_Material_Have[8] < g_Material_Need[8] then
			Material_OK = -1
		end
	end
	if Material_OK == -1 then
		PushDebugMessage("#{LZZZ_150526_58}")
		return
	end

	--普通粽子给二次确认
	if g_Zongzi_Flag == 1 then --and g_check ~= 1 then
		g_check = 1;
		--GameProduceLogin : ShowMessageBox( "#{LZZZ_150526_57}", "YesNo", "-1")
		PushEvent("MAKEZONGZI_CONFIRM", tonumber(g_Zongzi_Flag))
		return
	end

	--空间够不够 服务器判断

	--好了 包吧
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("MakeZongzi");
		Set_XSCRIPT_ScriptID(891150);
		Set_XSCRIPT_Parameter(0,g_Zongzi_Flag);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();


end
