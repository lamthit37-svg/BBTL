
local objCared = -1;

local g_ChangeSex_From = -1;

local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度


local g_ChangeSex_Frame_UnifiedPosition;

function ChangeSex_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);


	-- FakeObject模型界面互斥
	this:RegisterEvent("OPEN_EQUIP");										-- 角色资料界面
	this:RegisterEvent("OPEN_DRESS_PAINT_FITTING");			-- 时装染色试衣间
	this:RegisterEvent("OPEN_DRESS_ENCHASE_FITTING");		-- 时装镶嵌试衣间
	this:RegisterEvent("YIGUI_OPEN");				-- 衣柜
	this:RegisterEvent("OPEN_SHOP_FITTING"); --试穿
	this:RegisterEvent("OPEN_YB_SHOP_FITTING")
	this:RegisterEvent("FASHION_DEPOT_OP", false);				-- 华裳阁


	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function ChangeSex_OnLoad()
g_ChangeSex_Frame_UnifiedPosition= ChangeSex_Frame:GetProperty("UnifiedPosition");
end


function ChangeSex_OnEvent(event)

	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ChangeSex_Close();
	end

	-- FakeObject模型界面互斥
	if ( event == "OPEN_EQUIP") or												-- 角色资料界面
		 (event == "OPEN_DRESS_PAINT_FITTING") or					-- 时装染色试衣间
		 (event == "OPEN_DRESS_ENCHASE_FITTING") or	-- 时装镶嵌试衣间
		 (event == "YIGUI_OPEN") or			-- 衣柜
		 (event == "OPEN_YB_SHOP_FITTING") or
		 (event == "OPEN_SHOP_FITTING") or --试穿
		 (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1 ) then --华裳阁
		if (this:IsVisible()) then
			ChangeSex_Close();
		end
	end

	if(event == "UI_COMMAND" and (tonumber(arg0) == 20120406 or tonumber(arg0) == 20210506)) then
		local targetid = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(targetid);

		if objCared == -1 then
			return;
		end
		this:CareObject(objCared, 1, "CHANGE_SEX_NEW");
		
		g_ChangeSex_From = tonumber(arg0)

		this:Show();

		ChangeSex_FakeObject_Left:SetFakeObject("");
		ChangeSex_FakeObject_Left:SetFakeObject("ChangeSex_PlayerNew0");
		ChangeSex_FakeObject_Right:SetFakeObject("");
		YiGui:SetChangeSexNewModle(1) --不想新弄了，借用下衣柜导出类
		ChangeSex_FakeObject_Right:SetFakeObject("ChangeSex_PlayerNew1");

		--FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		--FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	end

	if (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end

		--如果和商人的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			this:CareObject(objCared, 0, "CHANGE_SEX_NEW");
			this:Hide();
		end
	end

	if (event == "ADJEST_UI_POS" ) then
		ChangeSex_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ChangeSex_Frame_On_ResetPos()
	end


end

--关闭按钮
function ChangeSex_Close()
	--取消关心
	this:CareObject(objCared, 0, "CHANGE_SEX_NEW");
	this:Hide();
end


function ChangeSex_Accept_Clicked()
	if g_ChangeSex_From == 20210506 then
		--打开2次确认界面
		LuaConfirmChangeSex("#{ZXD_20120406_02}", "126", objCared)
		this:Hide();
		return
	end
	--打开2次确认界面
	LuaConfirmChangeSex("#{ZXD_20120406_02}", "30", objCared)
	this:Hide();
end






----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左) --变性前
--
function ChangeSex_TurnLeft_Left(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			ChangeSex_FakeObject_Left:RotateBegin(-0.3);
		--向左旋转结束
		else
			ChangeSex_FakeObject_Left:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右) --变性前
--
function ChangeSex_TurnRight_Left(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			ChangeSex_FakeObject_Left:RotateBegin(0.3);
		--向右旋转结束
		else
			ChangeSex_FakeObject_Left:RotateEnd();
		end
	end
end

--=======================================================================================
----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左) --变性后
--
function ChangeSex_TurnLeft_Right(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			ChangeSex_FakeObject_Right:RotateBegin(-0.3);
		--向左旋转结束
		else
			ChangeSex_FakeObject_Right:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右) --变性后
--
function ChangeSex_TurnRight_Right(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			ChangeSex_FakeObject_Right:RotateBegin(0.3);
		--向右旋转结束
		else
			ChangeSex_FakeObject_Right:RotateEnd();
		end
	end
end

function ChangeSex_Frame_On_ResetPos()
  ChangeSex_Frame:SetProperty("UnifiedPosition", g_ChangeSex_Frame_UnifiedPosition);
end

function ChangeSex_DoNothing()
end
