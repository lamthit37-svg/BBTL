--Infant_HeroChoice.lua

local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度

local g_CurSelInfantIndex= 0
local g_MaxInfantCount = 1
local g_targetId = -1

local g_HeroTypeMin = 1
local g_HeroTypeMax = 4

local g_HeroChoice_Frame_UnifiedXPosition;
local g_HeroChoice_Frame_UnifiedYPosition;


local g_Hero_Model_DataID = {
	[1] = 16544,
	[2] = 16545,
	[3] = 16546,
	[4] = 16547,
}

local g_HeroName = {
	[1] = "乔峰",
	[2] = "段誉",
	[3] = "虚竹",
	[4] = "王语嫣",
}

function Infant_HeroChoice_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	this:RegisterEvent("TOGGLE_UPDATE_INFANT");
	this:RegisterEvent("INFANT_HERO_CHOICE_CONFIRM")

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Infant_HeroChoice_OnLoad()
	-- 保存界面的默认相对位置
	g_HeroChoice_Frame_UnifiedXPosition	= Infat_HeroChoice_Frame:GetProperty("UnifiedXPosition");
	g_HeroChoice_Frame_UnifiedYPosition	= Infat_HeroChoice_Frame:GetProperty("UnifiedYPosition");
end

function Infant_HeroChoice_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 20131111 then
		local xx = Get_XParam_INT(0);
		g_targetId = DataPool : GetNPCIDByServerID(xx);
		if g_targetId == -1 then
			return
		end
		Infant_HeroChoice_BeginCareObject()
		Infant_HeroChoice_UpdateInfo()
		this:Show()

	elseif event == "UI_COMMAND" and tonumber(arg0) == 20131205 then
		Infant_HeroChoice_OnHiden()
	-- elseif (event=="TOGGLE_UPDATE_INFANT") then
	-- 	Infant_HeroChoice_UpdateInfo();
	elseif( event == "ADJEST_UI_POS" ) then
		Infant_HeroChoice_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		Infant_HeroChoice_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Infant_HeroChoice_OnHiden()
	end
end

function Infant_HeroChoice_UpdateInfo()
	-- 初始化四个英雄的模型
	Infant:InitHeroObj()
	
	Infat_HeroChoiceFrame_FakeObject1 : SetFakeObject( "" );
	Infant:SetHeroModel(1, g_Hero_Model_DataID[1])
	Infat_HeroChoiceFrame_FakeObject1 : SetFakeObject( "Hero_QiaoFeng" );
	FakeObj_SetCamera( "Hero_QiaoFeng", g_CameraHeight,0.6)
	FakeObj_SetCamera( "Hero_QiaoFeng", g_CameraDistance,4)
	FakeObj_RestoreCamera( "Hero_QiaoFeng" )
	
	Infat_HeroChoiceFrame_FakeObject2 : SetFakeObject( "" );
	Infant:SetHeroModel(2, g_Hero_Model_DataID[2])
	Infat_HeroChoiceFrame_FakeObject2 : SetFakeObject( "Hero_DuanYu" );
	FakeObj_SetCamera( "Hero_DuanYu", g_CameraHeight,0.6)
	FakeObj_SetCamera( "Hero_DuanYu", g_CameraDistance,4)
	FakeObj_RestoreCamera( "Hero_DuanYu" )

	Infat_HeroChoiceFrame_FakeObject3 : SetFakeObject( "" );
	Infant:SetHeroModel(3, g_Hero_Model_DataID[3])
	Infat_HeroChoiceFrame_FakeObject3 : SetFakeObject( "Hero_XuZhu" );
	FakeObj_SetCamera( "Hero_XuZhu", g_CameraHeight,0.6)
	FakeObj_SetCamera( "Hero_XuZhu", g_CameraDistance,4)
	FakeObj_RestoreCamera( "Hero_XuZhu" )

	Infat_HeroChoiceFrame_FakeObject4 : SetFakeObject( "" );
	Infant:SetHeroModel(4, g_Hero_Model_DataID[4])
	Infat_HeroChoiceFrame_FakeObject4 : SetFakeObject( "Hero_WangYuYan" );
	FakeObj_SetCamera( "Hero_WangYuYan", g_CameraHeight,0.6)
	FakeObj_SetCamera( "Hero_WangYuYan", g_CameraDistance,4)
	FakeObj_RestoreCamera( "Hero_WangYuYan" )
end

function Infant_HeroChoice_ChooseHero(index)
	if index < g_HeroTypeMin and index > g_HeroTypeMax then
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then		
		return
	end
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{YXPY_20131118_30}")
		return
	end
	--判断是否有子女
	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 then
		PushDebugMessage("#{YXPY_20131118_34}")
		PushDebugMessage("#{YXPY_20131118_35}")
		return
	end
	--是否达到91级
	local level = Infant:GetInfantLevel(g_CurSelInfantIndex)
	if level < 91 then
		PushDebugMessage("#{YXPY_20131118_36}")
		return
	end
	--是否已有英雄类型
	local heroType = Infant:GetHeroType(g_CurSelInfantIndex)
	if heroType == index then
		local str = ScriptGlobal_Format("#{YXPY_20131118_41}", g_HeroName[heroType])
		PushDebugMessage(str)
		return
	end
	if heroType ~= 0 then
		PushEvent( "INFANT_HERO_CHOICE_CONFIRM", index, 1 , g_targetId)	--已经选择过等级
		return
	elseif heroType == 0 then
		PushEvent( "INFANT_HERO_CHOICE_CONFIRM", index, 0 , g_targetId)	--未选择过等级
		return
	end
	-- Clear_XSCRIPT();
	-- 	Set_XSCRIPT_Function_Name("ChoseInfantHeroType");
	-- 	Set_XSCRIPT_ScriptID(890630);
	-- 	Set_XSCRIPT_Parameter(0,index);
	-- 	Set_XSCRIPT_ParamCount(1);
	-- Send_XSCRIPT();

end
--=============================================
--模型旋转
--=============================================
function Infant_HeroChoice_Hero1_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infat_HeroChoiceFrame_FakeObject1:RotateBegin(-0.3);
	--向左旋转结束
	else
		Infat_HeroChoiceFrame_FakeObject1:RotateEnd();
	end
end
function Infant_HeroChoice_Hero1_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infat_HeroChoiceFrame_FakeObject1:RotateBegin(0.3);
	--向右旋转结束
	else
		Infat_HeroChoiceFrame_FakeObject1:RotateEnd();
	end
end
function Infant_HeroChoice_Hero2_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infat_HeroChoiceFrame_FakeObject2:RotateBegin(-0.3);
	--向左旋转结束
	else
		Infat_HeroChoiceFrame_FakeObject2:RotateEnd();
	end
end
function Infant_HeroChoice_Hero2_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infat_HeroChoiceFrame_FakeObject2:RotateBegin(0.3);
	--向右旋转结束
	else
		Infat_HeroChoiceFrame_FakeObject2:RotateEnd();
	end
end
function Infant_HeroChoice_Hero3_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infat_HeroChoiceFrame_FakeObject3:RotateBegin(-0.3);
	--向左旋转结束
	else
		Infat_HeroChoiceFrame_FakeObject3:RotateEnd();
	end
end
function Infant_HeroChoice_Hero3_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infat_HeroChoiceFrame_FakeObject3:RotateBegin(0.3);
	--向右旋转结束
	else
		Infat_HeroChoiceFrame_FakeObject3:RotateEnd();
	end
end
function Infant_HeroChoice_Hero4_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infat_HeroChoiceFrame_FakeObject4:RotateBegin(-0.3);
	--向左旋转结束
	else
		Infat_HeroChoiceFrame_FakeObject4:RotateEnd();
	end
end
function Infant_HeroChoice_Hero4_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infat_HeroChoiceFrame_FakeObject4:RotateBegin(0.3);
	--向右旋转结束
	else
		Infat_HeroChoiceFrame_FakeObject4:RotateEnd();
	end
end
--================================================
-- 界面的默认相对位置
--================================================
function Infant_HeroChoice_ResetPos()
	Infat_HeroChoice_Frame:SetProperty("UnifiedXPosition", g_HeroChoice_Frame_UnifiedXPosition);
	Infat_HeroChoice_Frame:SetProperty("UnifiedYPosition", g_HeroChoice_Frame_UnifiedYPosition);
end

function Infant_HeroChoice_OnHiden()
	Infant_HeroChoice_StopCareObject()
	Infant:ClearHeroObj()
	this:Hide();
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function Infant_HeroChoice_BeginCareObject()
	this:CareObject(g_targetId, 1, "Infant_HeroChoice")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function Infant_HeroChoice_StopCareObject()
	this:CareObject(g_targetId, 0, "Infant_HeroChoice")
end

