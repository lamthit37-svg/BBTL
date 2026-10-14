local nRed=0;
local nGreen=0;
local nBlue=0;
local nAlpha = 255;
local nLumination = 0;
local g_ChangeBy = 0;
local g_Lumination_ChangeBy = 0;
local g_UINT_COLOR = 0;
local ItemID = {20307001, 20307002}; -- zchw
local CostMoney = 50000
local g_Original_Red = 0;
local g_Original_Green = 0;
local g_Original_Blue = 0;
local g_Original_Alpha = 0;
local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local g_Object = -1;

local g_SelectHairColor_Frame_UnifiedPosition;

local g_GXHHairColorText = {}
local g_GXHCount = 0
local g_GXHRed = {}
local g_GXHGreen = {}
local g_GXHBlue = {}
local g_GXHAlpha = {}
local g_GXHMaxCount = 20--一共有20个坑
local g_CurIndex = -1

local g_SelectHairColor_YuanbaoPay=1

local SelectHairColor_CameraHeight = 1		--摄影机高度
local SelectHairColor_CameraDistance = 2	--摄影机距离
local SelectHairColor_CameraPitch = 3		--摄影机角度
local g_SelectHairColor_CameraLevel = 0
local g_SelectHairColor_CameraPosition =
{
	[0] = {fHeight = 1.09, fDistance = 1.30, },
	[1] = {fHeight = 0.90, fDistance = 2.30, },
	[2] = {fHeight = 0.63, fDistance = 3.30, }, 
}

local g_SelectHairColor_SpecialPitch = 0.1

local g_SelectHairColor_SpecialCamera =
{
	[0] = {fHeight = 1.63, fDistance = 1.3, fPitch = 0.13, fXOffset = 0,},
	[1] = {fHeight = 1.8, fDistance = 1.4, fPitch = 0.15, fXOffset = 0},

}

local g_SelectHairColor_HeadCameraPosition = {Save = 0, fHeight = 1.09, fDistance = 1.30, fPitch = 0.13, fBigDistance = 1.90}

function SelectHairColor_PreLoad()
	this:RegisterEvent("UI_COMMAND", true);	
	this:RegisterEvent("OBJECT_CARED_EVENT", false);
	this:RegisterEvent("SEX_CHANGED", false);	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("REFRESH_HAIRCOLOR", false);
end

function SelectHairColor_OnLoad()
	SelectHairColor_Red:SetProperty( "DocumentSize","1" );
	SelectHairColor_Red:SetProperty( "PageSize","0.1" );
	SelectHairColor_Red:SetProperty( "StepSize","0.1" );
	
	SelectHairColor_Green:SetProperty( "DocumentSize","1" );
	SelectHairColor_Green:SetProperty( "PageSize","0.1" );
	SelectHairColor_Green:SetProperty( "StepSize","0.1" );
	
	SelectHairColor_Blue:SetProperty( "DocumentSize","1" );
	SelectHairColor_Blue:SetProperty( "PageSize","0.1" );
	SelectHairColor_Blue:SetProperty( "StepSize","0.1" );
	
	SelectHairColor_Brightness:SetProperty( "DocumentSize","1" );
	SelectHairColor_Brightness:SetProperty( "PageSize","0.1" );
	SelectHairColor_Brightness:SetProperty( "StepSize","0.1" );
	
	g_GXHHairColorText[1] = 
	{
		Icon = SelectHairColor_OneIcon;
		Push = SelectHairColor_Item_One;
		Lock = SelectHairColor_ItemLock1;
		EquipImage = SelectHairColor_SuperListItemActionDef1;
		TryImage = SelectHairColor_SuperListItemActionTry1
	}	
	g_GXHHairColorText[2] = 
	{
		Icon = SelectHairColor_TwoIcon;
		Push = SelectHairColor_Item_Two;
		Lock = SelectHairColor_ItemLock2;
		EquipImage = SelectHairColor_SuperListItemActionDef2;
		TryImage = SelectHairColor_SuperListItemActionTry2
	}
	g_GXHHairColorText[3] = 
	{
		Icon = SelectHairColor_ThreeIcon;
		Push = SelectHairColor_Item_Three;
		Lock = SelectHairColor_ItemLock3;
		EquipImage = SelectHairColor_SuperListItemActionDef3;
		TryImage = SelectHairColor_SuperListItemActionTry3
	}
	g_GXHHairColorText[4] = 
	{
		Icon = SelectHairColor_FourIcon;
		Push = SelectHairColor_Item_Four;
		Lock = SelectHairColor_ItemLock4;
		EquipImage = SelectHairColor_SuperListItemActionDef4;
		TryImage = SelectHairColor_SuperListItemActionTry4
	}
	g_GXHHairColorText[5] = 
	{
		Icon = SelectHairColor_FiveIcon;
		Push = SelectHairColor_Item_Five;
		Lock = SelectHairColor_ItemLock5;
		EquipImage = SelectHairColor_SuperListItemActionDef5;
		TryImage = SelectHairColor_SuperListItemActionTry5
	}
	g_GXHHairColorText[6] = 
	{
		Icon = SelectHairColor_SixIcon;
		Push = SelectHairColor_Item_Six;
		Lock = SelectHairColor_ItemLock6;
		EquipImage = SelectHairColor_SuperListItemActionDef6;
		TryImage = SelectHairColor_SuperListItemActionTry6
	}	
	g_GXHHairColorText[7] = 
	{
		Icon = SelectHairColor_SevenIcon;
		Push = SelectHairColor_Item_Seven;
		Lock = SelectHairColor_ItemLock7;
		EquipImage = SelectHairColor_SuperListItemActionDef7;
		TryImage = SelectHairColor_SuperListItemActionTry7
	}
	g_GXHHairColorText[8] = 
	{
		Icon = SelectHairColor_EightIcon;
		Push = SelectHairColor_Item_Eight;
		Lock = SelectHairColor_ItemLock8;
		EquipImage = SelectHairColor_SuperListItemActionDef8;
		TryImage = SelectHairColor_SuperListItemActionTry8
	}
	g_GXHHairColorText[9] = 
	{
		Icon = SelectHairColor_NineIcon;
		Push = SelectHairColor_Item_Nine;
		Lock = SelectHairColor_ItemLock9;
		EquipImage = SelectHairColor_SuperListItemActionDef9;
		TryImage = SelectHairColor_SuperListItemActionTry9
	}
	g_GXHHairColorText[10] = 
	{
		Icon = SelectHairColor_TenIcon;
		Push = SelectHairColor_Item_Ten;
		Lock = SelectHairColor_ItemLock10;
		EquipImage = SelectHairColor_SuperListItemActionDef10;
		TryImage = SelectHairColor_SuperListItemActionTry10
	}
	g_GXHHairColorText[11] = 
	{
		Icon = SelectHairColor_ElevenIcon;
		Push = SelectHairColor_Item_Eleven;
		Lock = SelectHairColor_ItemLock11;
		EquipImage = SelectHairColor_SuperListItemActionDef11;
		TryImage = SelectHairColor_SuperListItemActionTry11
	}	
	g_GXHHairColorText[12] = 
	{
		Icon = SelectHairColor_TwelveIcon;
		Push = SelectHairColor_Item_Twelve;
		Lock = SelectHairColor_ItemLock12;
		EquipImage = SelectHairColor_SuperListItemActionDef12;
		TryImage = SelectHairColor_SuperListItemActionTry12
	}
	g_GXHHairColorText[13] = 
	{
		Icon = SelectHairColor_ThirteenIcon;
		Push = SelectHairColor_Item_Thirteen;
		Lock = SelectHairColor_ItemLock13;
		EquipImage = SelectHairColor_SuperListItemActionDef13;
		TryImage = SelectHairColor_SuperListItemActionTry13
	}
	g_GXHHairColorText[14] = 
	{
		Icon = SelectHairColor_FourteenIcon;
		Push = SelectHairColor_Item_Fourteen;
		Lock = SelectHairColor_ItemLock14;
		EquipImage = SelectHairColor_SuperListItemActionDef14;
		TryImage = SelectHairColor_SuperListItemActionTry14
	}
	g_GXHHairColorText[15] = 
	{
		Icon = SelectHairColor_FifteenIcon;
		Push = SelectHairColor_Item_Fifteen;
		Lock = SelectHairColor_ItemLock15;
		EquipImage = SelectHairColor_SuperListItemActionDef15;
		TryImage = SelectHairColor_SuperListItemActionTry15
	}
	g_GXHHairColorText[16] = 
	{
		Icon = SelectHairColor_SixteenIcon;
		Push = SelectHairColor_Item_Sixteen;
		Lock = SelectHairColor_ItemLock16;
		EquipImage = SelectHairColor_SuperListItemActionDef16;
		TryImage = SelectHairColor_SuperListItemActionTry16
	}	
	g_GXHHairColorText[17] = 
	{
		Icon = SelectHairColor_SeventeenIcon;
		Push = SelectHairColor_Item_Seventeen;
		Lock = SelectHairColor_ItemLock17;
		EquipImage = SelectHairColor_SuperListItemActionDef17;
		TryImage = SelectHairColor_SuperListItemActionTry17
	}
	g_GXHHairColorText[18] = 
	{
		Icon = SelectHairColor_EighteenIcon;
		Push = SelectHairColor_Item_Eighteen;
		Lock = SelectHairColor_ItemLock18;
		EquipImage = SelectHairColor_SuperListItemActionDef18;
		TryImage = SelectHairColor_SuperListItemActionTry18
	}
	g_GXHHairColorText[19] = 
	{
		Icon = SelectHairColor_NineteenIcon;
		Push = SelectHairColor_Item_Nineteen;
		Lock = SelectHairColor_ItemLock19;
		EquipImage = SelectHairColor_SuperListItemActionDef19;
		TryImage = SelectHairColor_SuperListItemActionTry19
	}
	g_GXHHairColorText[20] = 
	{
		Icon = SelectHairColor_TwentyIcon;
		Push = SelectHairColor_Item_Twenty;
		Lock = SelectHairColor_ItemLock20;
		EquipImage = SelectHairColor_SuperListItemActionDef20;
		TryImage = SelectHairColor_SuperListItemActionTry20
	}
	g_SelectHairColor_Frame_UnifiedPosition=SelectHairColor_Frame:GetProperty("UnifiedPosition");
end

function SelectHairColor_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
	
		if ( tonumber(arg0) == 22 ) then
			
			local xx = Get_XParam_INT(0);
			objCared = DataPool : GetNPCIDByServerID(xx);

			if objCared == -1 then
				PushDebugMessage("server传过来的数据有问题");
				return;
			end

			if(IsWindowShow("Shop_Dresser")) then
				CloseWindow("Shop_Dresser", true);
			end
			if(IsWindowShow("SelectHairstyle")) then
				CloseWindow("SelectHairstyle", true);
			end

			if(IsWindowShow("SelectFacestyle")) then
				CloseWindow("SelectFacestyle", true);
			end
			
			PushEvent( "CLOSE_DRESSPREVIEW") 	
			PushEvent( "CLOSE_GEMEFFECTPREVIEW")
			if( this:IsVisible() and tonumber(g_Original_Red) and tonumber(g_Original_Green) and tonumber(g_Original_Blue) and tonumber(g_Original_Alpha) ) then
				DataPool : Change_MyHairColor(g_Original_Red,g_Original_Green,g_Original_Blue,g_Original_Alpha);
			end	
			BeginCareObject_SelectHairColor(objCared)
			-- local nExteriorHairColorIndex = Exterior:LuaFnGetExteriorHairColorIndex()
			-- g_Original_Red,g_Original_Green,g_Original_Blue,g_Original_Alpha = Exterior:LuaFnEnumExteriorHairColor(nExteriorHairColorIndex)

			SelectHairColor_OnShown();
			
		elseif ( tonumber(arg0) == 201203141 ) then
			if (not this:IsVisible() ) then
				return;
			end
			
			g_Original_Red = nRed;
			g_Original_Green = nGreen;
			g_Original_Blue  = nBlue;
			g_Original_Alpha = nAlpha;
			
			return;
		end

	elseif (event == "OBJECT_CARED_EVENT") then
		if(not this:IsVisible() ) then
			return;
		end
		
		if(tonumber(arg0) ~= objCared) then 
			Close_HairColor();
			return;
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then

			--取消关心
			-- SelectHairColor_Cancel_Clicked();
			Close_HairColor()
		end			
	end

	if event == "SEX_CHANGED" and  this:IsVisible() then
			SelectHairColor_Model : Hide();
			SelectHairColor_Model : Show();
			SelectHairColor_Model:SetFakeObject("Player_Head");
	end
	
	if (event == "ADJEST_UI_POS" ) then
		SelectHairColor_Frame_On_ResetPos()
	end 
  if (event == "VIEW_RESOLUTION_CHANGED") then
		SelectHairColor_Frame_On_ResetPos()
	end
			
	if (event == "REFRESH_HAIRCOLOR") then
		-- PushDebugMessage ("REFRESH_HAIRCOLOR = ")
		if (this:IsVisible()) then
				Refresh_HairColor()
		end
	end
	
	
	-- FakeObject模型界面互斥
	if ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  
	   ( event == "UI_COMMAND" and tonumber(arg0) == 2024082101 ) then   --时装预览
		if (this:IsVisible()) then
			Close_HairColor()	
			return
		end
	end		
	
end


function SelectHairColor_OnShown()

	local name,icon = LifeAbility : GetPrescr_Material(ItemID[1]); -- zchw
	
	local nExteriorHairColorIndex = Exterior:LuaFnGetExteriorHairColorIndex()
	g_CurIndex = nExteriorHairColorIndex+1
	g_Original_Red,g_Original_Green,g_Original_Blue,g_Original_Alpha = Exterior:LuaFnEnumExteriorHairColor(nExteriorHairColorIndex)
	if (name == nil) then 
		PushDebugMessage("物品号错误！资源的问题，指给策划。");
		return;
	end
	
	nRed = g_Original_Red;
	nGreen = g_Original_Green;
	nBlue = g_Original_Blue;
	
	--yuanbaoPay
	if g_SelectHairColor_YuanbaoPay == 1 or g_SelectHairColor_YuanbaoPay == 0 then
		SelectHairColor_Expendable_Queren:SetCheck(g_SelectHairColor_YuanbaoPay)
	end
	
	SelectHairColor_Update();

	local i,j,curIcon
	for i=1,g_GXHMaxCount do
		g_GXHHairColorText[i].Icon : SetImageColor("00FFFFFF")
		g_GXHHairColorText[i].Push : SetPushed(0)
		g_GXHHairColorText[i].TryImage:Hide()
		g_GXHHairColorText[i].EquipImage:Hide()
	end

	g_GXHHairColorText[nExteriorHairColorIndex+1].Push : SetPushed(1)
	-- g_GXHHairColorText[g_CurIndex].Push : SetPushed(1)
	g_GXHCount =Exterior:LuaFnGetExteriorHairColorCount()
	-- PushDebugMessage ("g_GXHCount = "..tostring(g_GXHCount))

	for i=0,g_GXHCount-1 do		
		g_GXHRed[i],g_GXHGreen[i],g_GXHBlue[i],g_GXHAlpha[i] = Exterior:LuaFnEnumExteriorHairColor(i)
		curIcon = string.format("%02X",255)..string.format("%02X",g_GXHRed[i])..string.format("%02X",g_GXHGreen[i])..string.format("%02X",g_GXHBlue[i])
		g_GXHHairColorText[i+1].Icon : SetImageColor(curIcon)
		g_GXHHairColorText[i+1].Lock:Hide()
		g_GXHHairColorText[i+1].TryImage:Hide()
		g_GXHHairColorText[i+1].EquipImage:Hide()
		-- if nExteriorHairColorIndex == i then
		-- 	g_GXHHairColorText[i+1].EquipImage:Show()
		-- end

	end
	g_GXHHairColorText[nExteriorHairColorIndex+1].EquipImage:Show()
	
		
	this:Show();
end

-- 
function SelectHairColor_Expendable_Queren_Clicked() 
	g_SelectHairColor_YuanbaoPay = SelectHairColor_Expendable_Queren:GetCheck();
end

function SelectHairColor_Update()


	if(g_ChangeBy == 0) then
		g_ChangeBy = 1;
	else
		return;
	end

	SelectHairColor_Red_NumericalValue : SetText(nRed);
	SelectHairColor_Red : SetPosition(nRed/200);
	
	SelectHairColor_Green_NumericalValue : SetText(nGreen);
	SelectHairColor_Green : SetPosition(nGreen/200);

	SelectHairColor_Blue_NumericalValue : SetText(nBlue);
	SelectHairColor_Blue :SetPosition(nBlue/200);

	
	local mySex = GetMySelfRaceId()
	if mySex > 1 or mySex < 0 then 
		mySex = 0
	end

	SelectHairColor_Model : SetFakeObject( "" )
	SelectHairColor_Model : SetFakeObject( "Player_Head" )
	FakeObj_RestoreCamera( "Player_Head" )
	
	FakeObj_SetCamera( "Player_Head", SelectHairColor_CameraPitch, g_SelectHairColor_SpecialPitch )
	
	if g_SelectHairColor_HeadCameraPosition ~= nil and g_SelectHairColor_HeadCameraPosition.Save < 1 then
		local fHeight, fDistance, fPitch = FakeObj_GetCamera("Player_Head")
		g_SelectHairColor_HeadCameraPosition.fHeight = fHeight
		g_SelectHairColor_HeadCameraPosition.fDistance = fDistance
		g_SelectHairColor_HeadCameraPosition.fPitch = fPitch
		g_SelectHairColor_HeadCameraPosition.Save = 1
	end

	-- 获取头饰ID
	local ornamentsHeadID = OrnamentsScript:GetOrnamentsUseID(1)
	if ornamentsHeadID > 0 and OrnamentsScript:IsBigOrnamentsHead(ornamentsHeadID) > 0 then
		-- 如果是大头ID，设置专门的摄像机位置
		FakeObj_SetCamera( "Player_Head", SelectHairColor_CameraDistance, g_SelectHairColor_HeadCameraPosition.fBigDistance )
	else
		FakeObj_SetCamera( "Player_Head", SelectHairColor_CameraDistance, g_SelectHairColor_HeadCameraPosition.fDistance )
	end

	local isIVMode = LuaFnGetCurModelState()

	local isIVMode = LuaFnGetCurModelState()
	if isIVMode == 1 then
		--local  fHeight, fDistance, fPitch = FakeObj_GetCamera( "Player_Head" )
		--PushDebugMessage("fHeight = "..fHeight.." fDistance = "..fDistance.." fPitch = "..fPitch)
		NewFakeObj_SetCamera_WithXOffset( "Player_Head", g_SelectHairColor_SpecialCamera[mySex].fHeight, 
														g_SelectHairColor_SpecialCamera[mySex].fDistance,
														g_SelectHairColor_SpecialCamera[mySex].fPitch,
														g_SelectHairColor_SpecialCamera[mySex].fXOffset )
	end	

	local Lumination = DataPool : Change_MyHairColor(nRed,nGreen,nBlue,nAlpha);
	
	SelectHairColor_Brightness_NumericalValue : SetText(Lumination);
	SelectHairColor_Brightness : SetPosition(Lumination / 240);
	
	g_ChangeBy = 0;
end

-- 点击染色按钮
function SelectHairColor_OK_Clicked()

	local color_r,color_g,color_b,color_a,Ogre_Color = DataPool:Change_RectifyColor(nRed,nGreen,nBlue,nAlpha);
	-- PushDebugMessage ("nRed = "..color_r)
	-- 得到玩家的金币和交子数目
	local nMoney = Player:GetData("MONEY")
	local nMoneyJZ = Player:GetData("MONEY_JZ")
	
	if (nMoney + nMoneyJZ) < 50000 then
		PushDebugMessage("金钱不足");
		-- SelectHairColor_Cancel_Clicked();
		-- Close_HairColor()
		return
	end

	-- 得到选择发色的亮度
	local Luminance = SelectHairColor_Brightness_NumericalValue:GetText()
	if(Luminance ~= nil and tonumber(Luminance) > 126 ) then
		PushDebugMessage("发色亮度不能大于126")
		
		-- 调试信息
		--PushDebugMessage ("nRed = "..nRed..", nGreen = "..nGreen..", nBlue = "..nBlue)
		--PushDebugMessage ("color_r = "..color_r..", color_g = "..color_g..", color_b = "..color_b)
		return;   	
	end

	-- 调试信息
	-- PushDebugMessage ("nRed = "..nRed..", nGreen = "..nGreen..", nBlue = "..nBlue)
	--PushDebugMessage ("color_r = "..color_r..", color_g = "..color_g..", color_b = "..color_b)
		
	-- 如果选择的发色亮度不超过126（此时，(color_r,color_g,color_b) = (-1,-1,-1)）
	if( tonumber(color_r) < 0 ) then
		-- PushDebugMessage ("nRed = "..nRed..", nGreen = "..nGreen..", nBlue = "..nBlue)
		-- PushDebugMessage ("g_Original_Red = "..g_Original_Red..", g_Original_Green = "..g_Original_Green..", g_Original_Blue = "..g_Original_Blue)
		-- 没有更改发色
		if(nRed == g_Original_Red and nGreen == g_Original_Green and nBlue == g_Original_Blue) then
			PushDebugMessage("请选择一种新发色。")
			return;
		end
		
		for i=0,g_GXHCount-1 do
			if(nRed == g_GXHRed[i] and nGreen == g_GXHGreen[i] and nBlue == g_GXHBlue[i]) then
				PushDebugMessage("#{GXHDZ_141121_42}")
				return;
			end
		end
		
		if g_GXHCount < g_GXHMaxCount then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("FinishAdjust");
				Set_XSCRIPT_ScriptID(801011);
				Set_XSCRIPT_Parameter(0,Ogre_Color);
				Set_XSCRIPT_Parameter(1,g_SelectHairColor_YuanbaoPay);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
		else --个性化满了 要更换
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("CheckDelandAddHairColor");
				Set_XSCRIPT_ScriptID(801011);
				Set_XSCRIPT_Parameter(0,Ogre_Color);
				Set_XSCRIPT_Parameter(1,g_SelectHairColor_YuanbaoPay);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
		end

	else

		nRed = color_r;
		nGreen = color_g;
		nBlue = color_b;
		nAlpha = color_a;
		SelectHairColor_Update();
		PushDebugMessage("发色亮度不能大于126")
		
	end
	
end

function SelectHairColor_Cancel_Clicked()
	DataPool : Change_MyHairColor(g_Original_Red,g_Original_Green,g_Original_Blue,g_Original_Alpha);
	g_CurIndex = -1
	SelectHairColor_Model : SetFakeObject( "" );
	StopCareObject_SelectHairColor(objCared)
	--关闭二次确认界面
	PushEvent("CONVENIENT_BUY_CONFIRM_CLOSE");
	-- Close_HairColor();
end

----------------------------------------------------------------------------------

--放大
function SelectHairColor_ZoomIn()
	if g_SelectHairColor_CameraLevel < 1  or g_SelectHairColor_CameraLevel > 2 then
		return
	end
	
	g_SelectHairColor_CameraLevel = g_SelectHairColor_CameraLevel - 1
	SelectHairColor_SetCameraPosition()

end

--缩小
function SelectHairColor_ZoomOut()

	if g_SelectHairColor_CameraLevel < 0  or g_SelectHairColor_CameraLevel > 1 then
		return
	end
	
	g_SelectHairColor_CameraLevel = g_SelectHairColor_CameraLevel + 1
	SelectHairColor_SetCameraPosition()
end

function SelectHairColor_SetCameraPosition()
	if g_SelectHairColor_CameraLevel > -1 and g_SelectHairColor_CameraLevel < 3 then
		FakeObj_SetCamera( "Player_Head", SelectHairColor_CameraHeight, g_SelectHairColor_CameraPosition[g_SelectHairColor_CameraLevel].fHeight )
		FakeObj_SetCamera( "Player_Head", SelectHairColor_CameraDistance, g_SelectHairColor_CameraPosition[g_SelectHairColor_CameraLevel].fDistance )
		FakeObj_RestoreCamera( "Player_Head" )
	end
end

-- 旋转人物头像模型（向左)
function Player_Hair_Color_Modle_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			SelectHairColor_Model:RotateBegin(-0.3);
		--向左旋转结束
		else
			SelectHairColor_Model:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右)
--
function Player_Hair_Color_Modle_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			SelectHairColor_Model:RotateBegin(0.3);
		--向右旋转结束
		else
			SelectHairColor_Model:RotateEnd();
		end
	end
end

-- 颜色条发生改变
function SelectHairColor_SliderChanged()
	local temp;
	if(g_ChangeBy == 0) then
		g_ChangeBy = 2;
	else
		return;
	end
	
	if(g_ChangeBy == 2) then
		temp = SelectHairColor_Red:GetPosition();
		nRed = temp* 200;
		SelectHairColor_Red_NumericalValue : SetText(nRed);
	
		temp = SelectHairColor_Green:GetPosition();
		nGreen = temp * 200;
		SelectHairColor_Green_NumericalValue : SetText(nGreen);
	
		temp = SelectHairColor_Blue:GetPosition();
		nBlue = temp * 200;
		SelectHairColor_Blue_NumericalValue : SetText(nBlue);
		local Lumination = DataPool : Change_MyHairColor(nRed,nGreen,nBlue,nAlpha);
		
		SelectHairColor_Brightness_NumericalValue : SetText(Lumination);
		SelectHairColor_Brightness : SetPosition(Lumination / 240);
	end
	g_ChangeBy = 0;
end

--颜色值输入框中数值变化的事件
function Color_Change()
	local temp;
	

	if(g_ChangeBy == 0) then
		g_ChangeBy = 3;
	else
		return;
	end
	
	if(g_ChangeBy == 3) then
		temp = SelectHairColor_Red_NumericalValue:GetText();
		if(temp == "" ) then
			g_ChangeBy = 0;
			return;
		end;
		if(tonumber(temp) > 200) then
			temp = 200;
		end
		nRed = tonumber(temp);
		SelectHairColor_Red:SetPosition(temp/200);
		
		temp = SelectHairColor_Green_NumericalValue:GetText();
		if(temp == "" ) then
			g_ChangeBy = 0;
			return;
		end;
		if(tonumber(temp) > 200) then
			temp = 200;
		end
		nGreen = tonumber(temp);
		SelectHairColor_Green:SetPosition(temp/200);
		
		temp = SelectHairColor_Blue_NumericalValue:GetText();
		if(temp == "" ) then
			g_ChangeBy = 0;
			return;
		end;
		if(tonumber(temp) > 200) then
			temp = 200;
		end
		nBlue = tonumber(temp);
		SelectHairColor_Blue:SetPosition(temp/200);


		local Lumination = DataPool : Change_MyHairColor(nRed,nGreen,nBlue,nAlpha);
		
		SelectHairColor_Brightness_NumericalValue : SetText(Lumination);
		SelectHairColor_Brightness :SetPosition(Lumination / 240);
	end
	
	g_ChangeBy = 0;
end

function Text_Lost()
	SelectHairColor_Update()
end

function Close_HairColor()
	this:Hide();
end

-- Brightness亮度值输入框的值发生改变
function Lumination_Change()
	local temp;
	

	if(g_ChangeBy == 0) then
		g_ChangeBy = 4;
	else
		return;
	end
	
	if(g_ChangeBy == 4) then

		temp = SelectHairColor_Brightness_NumericalValue:GetText();
	
		if(temp == "" ) then
			g_ChangeBy = 0;
			return;
		end;
		if(tonumber(temp) > 240) then
			temp = 240;
		end
		
		SelectHairColor_Brightness_NumericalValue:SetText(temp)
		SelectHairColor_Brightness:SetPosition(temp/240);
				
		local color_r,color_g,color_b,color_a = DataPool:Change_GetColorLumination(nRed,nGreen,nBlue,nAlpha,temp);
		
		color_r,color_g,color_b,color_a,Lumination = Restrict_Color(color_r,color_g,color_b,color_a,Lumination)
		

		nRed = color_r;
		nGreen = color_g;
		nBlue = color_b;
		nAlpha = color_a;
		
		SelectHairColor_Red_NumericalValue : SetText(nRed);
		SelectHairColor_Red : SetPosition(nRed/200);
	
		SelectHairColor_Green_NumericalValue : SetText(nGreen);
		SelectHairColor_Green : SetPosition( nGreen/200);

		SelectHairColor_Blue_NumericalValue : SetText(nBlue);
		SelectHairColor_Blue : SetPosition(nBlue/200);
		
		local Lumination = DataPool : Change_MyHairColor(nRed,nGreen,nBlue,nAlpha);

	end
	
	g_ChangeBy = 0;
	
end

-- 亮度条发生改变
function SelectHairColor_Lumination_Changed()
	local temp;
	

	if(g_ChangeBy == 0) then
		g_ChangeBy = 5;
	else
		return;
	end
	
	if(g_ChangeBy == 5) then
		temp = SelectHairColor_Brightness:GetPosition();
		local Lumination = temp * 240;

		SelectHairColor_Brightness_NumericalValue : SetText(Lumination);
		SelectHairColor_Brightness:SetPosition(Lumination/240);
	
		local color_r,color_g,color_b,color_a = DataPool:Change_GetColorLumination(nRed,nGreen,nBlue,nAlpha,Lumination);
		
		color_r,color_g,color_b,color_a,Lumination = Restrict_Color(color_r,color_g,color_b,color_a,Lumination)
		
	
		nRed = color_r;
		nGreen = color_g;
		nBlue = color_b;
		nAlpha = color_a;
		
		SelectHairColor_Red_NumericalValue : SetText(nRed);
		SelectHairColor_Red : SetPosition(nRed/200);
	
		SelectHairColor_Green_NumericalValue : SetText(nGreen);
		SelectHairColor_Green : SetPosition(nGreen/200);

		SelectHairColor_Blue_NumericalValue : SetText(nBlue);
		SelectHairColor_Blue : SetPosition(nBlue/200);
		
		local Lumination = DataPool : Change_MyHairColor(nRed,nGreen,nBlue,nAlpha);

	end
		
	g_ChangeBy = 0;
	
end


function BeginCareObject_SelectHairColor(objCaredId)

	g_Object = objCaredId;

	this:CareObject(g_Object, 1, "SelectHairColor");

end


function StopCareObject_SelectHairColor(objCaredId)
	this:CareObject(objCaredId, 0, "SelectHairColor");
	g_Object = -1;

end

-- 亮度改变 限制颜色跟随发生改变
function Restrict_Color(Red,Green,Blue,Alpha,Lumination)

	if Red > 200 then
		Red = 200
	end
	if Green > 200 then
		Green = 200
	end
	if Blue > 200 then
		Blue = 200
	end
	Lumination = DataPool : Change_MyHairColor(Red,Green,Blue,Alpha);
	
	return Red,Green,Blue,Alpha,Lumination
end

function SelectHairColor_Frame_On_ResetPos()
  SelectHairColor_Frame:SetProperty("UnifiedPosition", g_SelectHairColor_Frame_UnifiedPosition);
end



--点击icon
function FaSe_Clicked(nIndex)	
	-- PushDebugMessage("nIndex:"..tostring(nIndex))
	-- PushDebugMessage("g_GXHCount:"..tostring(g_GXHCount))
	if nIndex > g_GXHCount or nIndex < 1 then
		return
	end
	if g_GXHHairColorText[g_CurIndex] ~= nil then
		g_GXHHairColorText[g_CurIndex].TryImage:Hide()
	end
	g_CurIndex = nIndex
  	for j=1,g_GXHMaxCount do
		g_GXHHairColorText[j].Push : SetPushed(0)
		
	end
	g_GXHHairColorText[nIndex].Push : SetPushed(1)

	local nExteriorHairColorIndex = Exterior:LuaFnGetExteriorHairColorIndex()
	-- PushDebugMessage("nExteriorHairColorIndex:"..tostring(nExteriorHairColorIndex))
	-- PushDebugMessage("g_CurIndex:"..tostring(g_CurIndex))
	if nExteriorHairColorIndex ~= g_CurIndex -1 then
		g_GXHHairColorText[g_CurIndex].TryImage:Show()
	end


	nRed = g_GXHRed[nIndex-1]
	nGreen = g_GXHGreen[nIndex-1]
	nBlue = g_GXHBlue[nIndex-1]
	SelectHairColor_Update()
	
end

--点击更换按钮
function SelectHairColor_ChangeBtnClicked()
	-- PushDebugMessage("xtcccc")
	if g_CurIndex > g_GXHMaxCount or g_CurIndex < 1 then
  		return
	  end	
	  
	if g_GXHRed[g_CurIndex-1]==g_Original_Red and g_GXHGreen[g_CurIndex-1]==g_Original_Green and g_GXHBlue[g_CurIndex-1]==g_Original_Blue then
		PushDebugMessage("#{GXHDZ_141121_51}")
		return
	end

	nRed = g_GXHRed[g_CurIndex-1]
	nGreen = g_GXHGreen[g_CurIndex-1]
	nBlue = g_GXHBlue[g_CurIndex-1]
	SelectHairColor_Update()
	-- PushDebugMessage("xfafas")
  	Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("ChangeHairColor");
			Set_XSCRIPT_ScriptID(801011);
			Set_XSCRIPT_Parameter(0,g_CurIndex-1);
			Set_XSCRIPT_Parameter(1,0);
			Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();
end


function Refresh_HairColor()

	SelectHairColor_Model : SetFakeObject( "" );
	StopCareObject_SelectHairColor(objCared)

	SelectHairColor_OnShown()
end