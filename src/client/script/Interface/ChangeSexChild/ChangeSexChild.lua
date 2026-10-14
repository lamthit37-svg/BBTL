--Add By YuanPeiLong 20141121 [子女变性丹设计]

local objCared = -1;

local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度


local g_ChangeSexChild_Frame_UnifiedPosition;

function ChangeSexChild_PreLoad()
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
	
	this:RegisterEvent("TOGGLE_OPENT_INFANT")


	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function ChangeSexChild_OnLoad()
g_ChangeSexChild_Frame_UnifiedPosition= ChangeSexChild_Frame:GetProperty("UnifiedPosition");
end


function ChangeSexChild_OnEvent(event)

	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ChangeSexChild_Close();
	end

	-- FakeObject模型界面互斥
	-- if ( event == "OPEN_EQUIP") or												-- 角色资料界面
		 -- (event == "OPEN_DRESS_PAINT_FITTING") or					-- 时装染色试衣间
		 -- (event == "OPEN_DRESS_ENCHASE_FITTING") or	-- 时装镶嵌试衣间
		 -- (event == "YIGUI_OPEN") or			-- 衣柜
		 -- (event == "OPEN_YB_SHOP_FITTING") or
		 -- (event == "OPEN_SHOP_FITTING") then --试穿
	if ( event == "TOGGLE_OPENT_INFANT") or ( event == "OPEN_EQUIP") then
		if (this:IsVisible()) then
			ChangeSexChild_Close();
			return
		end
	end

	if(event == "UI_COMMAND" and tonumber(arg0) == 201411210) then
		
		ChangeSexChild_FakeObject_Left:RotateEnd();
		ChangeSexChild_FakeObject_Left : SetFakeObject( "" );
		
		ChangeSexChild_FakeObject_Right:RotateEnd();
		ChangeSexChild_FakeObject_Right : SetFakeObject( "" );		
		
		local targetid = Get_XParam_INT(0);
		objCared = DataPool : GetNPCIDByServerID(targetid);

		if objCared == -1 then
			return;
		end
		this:CareObject(objCared, 1, "CHANGE_SEXCHILD_NEW");

		this:Show();
		
		local InfantCount = Infant:GetInfantCount();
		local nStage = Infant:GetStage(0)
		
		Infant:SetInfantNewModel(0)
		ChangeSexChild_FakeObject_Left:SetFakeObject("");	
		ChangeSexChild_FakeObject_Left:SetFakeObject("ChangeSexChild_PlayerNew0");
		if nStage == 3 then
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew0", g_CameraHeight,0.7);
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew0", g_CameraDistance,4);
		else
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew0", g_CameraHeight,0.5);
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew0", g_CameraDistance,3);		
		end		
		--ChangeSexChild_FakeObject_Left:SetFakeObject("ChangeSexChild_PlayerNew0");	

		--ChangeSexChild_FakeObject_Right:SetFakeObject("");
		--Infant:SetInfantNewModel(0) --不想新弄了，借用下衣柜导出类
		--ChangeSexChild_FakeObject_Right:SetFakeObject("ChangeSex_PlayerNew1");
		ChangeSexChild_FakeObject_Right:SetFakeObject("ChangeSexChild_PlayerNew1");
		--ChangeSexChild_FakeObject_Right:SetFakeObject("ChangeSexChild_PlayerNew1");

		-- FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraHeight,0.5);
		-- FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraDistance,3);		
		if nStage == 3 then
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraHeight,0.7);
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraDistance,4);
		else
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraHeight,0.5);
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraDistance,3);		
		end			

		--FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		--FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	end

	if(event == "UI_COMMAND" and tonumber(arg0) == 201411211) then
		if (this:IsVisible()) then
		else
			return
		end

		ChangeSexChild_FakeObject_Left:RotateEnd();
		ChangeSexChild_FakeObject_Left : SetFakeObject( "" );
		
		ChangeSexChild_FakeObject_Right:RotateEnd();
		ChangeSexChild_FakeObject_Right : SetFakeObject( "" );		

		if objCared == -1 then
			return;
		end
		this:CareObject(objCared, 1, "CHANGE_SEXCHILD_NEW");

		this:Show();
		
		local InfantCount = Infant:GetInfantCount();
		local nStage = Infant:GetStage(0)
		
		Infant:SetInfantNewModel(0)
		ChangeSexChild_FakeObject_Left:SetFakeObject("");	
		ChangeSexChild_FakeObject_Left:SetFakeObject("ChangeSexChild_PlayerNew0");
		if nStage == 3 then
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew0", g_CameraHeight,0.7);
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew0", g_CameraDistance,4);
		else
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew0", g_CameraHeight,0.5);
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew0", g_CameraDistance,3);		
		end		
		--ChangeSexChild_FakeObject_Left:SetFakeObject("ChangeSexChild_PlayerNew0");	

		--ChangeSexChild_FakeObject_Right:SetFakeObject("");
		--Infant:SetInfantNewModel(0) --不想新弄了，借用下衣柜导出类
		--ChangeSexChild_FakeObject_Right:SetFakeObject("ChangeSex_PlayerNew1");
		ChangeSexChild_FakeObject_Right:SetFakeObject("ChangeSexChild_PlayerNew1");
		--ChangeSexChild_FakeObject_Right:SetFakeObject("ChangeSexChild_PlayerNew1");

		-- FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraHeight,0.5);
		-- FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraDistance,3);		
		if nStage == 3 then
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraHeight,0.7);
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraDistance,4);
		else
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraHeight,0.5);
			FakeObj_SetCamera( "ChangeSexChild_PlayerNew1", g_CameraDistance,3);		
		end			

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
			this:CareObject(objCared, 0, "CHANGE_SEXCHILD_NEW");
			this:Hide();
		end
	end

	if (event == "ADJEST_UI_POS" ) then
		ChangeSexChild_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ChangeSexChild_Frame_On_ResetPos()
	end


end

--关闭按钮
function ChangeSexChild_Close()
	--取消关心
	this:CareObject(objCared, 0, "CHANGE_SEXCHILD_NEW");
	this:Hide();
end


function ChangeSexChild_Accept_Clicked()
	--打开2次确认界面
	LuaConfirmChangeSexChild("#{HYD_141120_12}", "55", objCared)
	this:Hide();
end

----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左) --变性前
--
function ChangeSexChild_TurnLeft_Left(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			ChangeSexChild_FakeObject_Left:RotateBegin(-0.3);
		--向左旋转结束
		else
			ChangeSexChild_FakeObject_Left:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右) --变性前
--
function ChangeSexChild_TurnRight_Left(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			ChangeSexChild_FakeObject_Left:RotateBegin(0.3);
		--向右旋转结束
		else
			ChangeSexChild_FakeObject_Left:RotateEnd();
		end
	end
end

--=======================================================================================
----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左) --变性后
--
function ChangeSexChild_TurnLeft_Right(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			ChangeSexChild_FakeObject_Right:RotateBegin(-0.3);
		--向左旋转结束
		else
			ChangeSexChild_FakeObject_Right:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右) --变性后
--
function ChangeSexChild_TurnRight_Right(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			ChangeSexChild_FakeObject_Right:RotateBegin(0.3);
		--向右旋转结束
		else
			ChangeSexChild_FakeObject_Right:RotateEnd();
		end
	end
end

function ChangeSexChild_Frame_On_ResetPos()
  ChangeSexChild_Frame:SetProperty("UnifiedPosition", g_ChangeSexChild_Frame_UnifiedPosition);
end

function ChangeSexChild_DoNothing()
end
