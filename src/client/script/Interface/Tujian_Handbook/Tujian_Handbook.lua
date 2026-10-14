-- 图鉴书的默认位置
local g_Handbook_Frame_UnifiedXPosition
local g_Handbook_Frame_UnifiedYPosition

local g_ClassStr = {
							"#{TLTJ_110114_11}"	,
							"#{TLTJ_110114_12}" ,
							"#{TLTJ_110114_13}"	,
							"#{TLTJ_110114_14}"	,
							}

local g_IsTeamOutLine_Class = {}
local g_IsTeamOutLine_Taotu = {}

local g_CardTitleTable = {
							"set:Handbook1 image:HandCard_Title_Monster"	,
							"set:Handbook1 image:HandCard_Title_Pet" ,
							"set:Handbook1 image:HandCard_Title_Ride"	,
							"set:Handbook1 image:HandCard_Title_Dress"	,
							}

local g_DirectTitle = "set:Handbook1 image:HandCard_Title_Intro"

local g_RaceTable_Book = {
							"set:Handbook1 image:HandCard_Logo_Monster"	,
							"set:Handbook1 image:HandCard_Logo_Pet" ,
							"set:Handbook1 image:HandCard_Logo_Ride"	,
							"set:Handbook1 image:HandCard_Logo_Dress"	,
							}

local g_DirectIconTable = {
							"#-40"	,
							"#-42"	,
							"#-43"	,
							"#-41"	,
							}
local g_TaotuIconSpin = "  "	--2个空格缩进
local g_CardIconSpin = "    "	--4个空格缩进

local g_CurrentClass_Clicked = 0
local g_CurrentTaotu_Clicked  = 0
local g_CurrentCard_Clicked = 0

local g_MaxNum_Class = 4
local g_MaxNum_TaotuInClass = 10
local g_MaxNum_CardInTaotu = 30

local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度

local g_Current_Clicked = -1;

--===============================================
-- OnLoad()
--===============================================
function Tujian_Handbook_PreLoad()

	this:RegisterEvent("TOGLE_TJHANDBOOK");
	this:RegisterEvent("OPEN_TJHANDBOOK");
	this:RegisterEvent("UPDATE_TJHANDBOOK");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("RESET_ALLUI")
	this:RegisterEvent("UPDATE_FAKE_OBJECT")
end

function Tujian_Handbook_OnLoad()

	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片资源为唯美版
		g_CardTitleTable = {
							"set:WM_Ach image:Guaiwutujian"	,
							"set:WM_Ach image:Zhenshoutujian" ,
							"set:WM_Ach image:Zuoqitujian"	,
							"set:WM_Ach image:Shizhuangtujian"	,
							}
		g_DirectTitle = "set:WM_Ach image:Shiyongshuoming"
		g_RaceTable_Book = {
							"set:WM_Tujian image:Monster"	,
							"set:WM_Tujian image:Pet" ,
							"set:WM_Tujian image:Ride"	,
							"set:WM_Tujian image:Equip"	,
							}
	end

	-- 保存图鉴书界面的默认相对位置
	g_Handbook_Frame_UnifiedXPosition	= Handbook_Frame:GetProperty("UnifiedXPosition");
	g_Handbook_Frame_UnifiedYPosition	= Handbook_Frame:GetProperty("UnifiedYPosition");

	g_ClassStr = {
							"#{TLTJ_110114_11}"	,
							"#{TLTJ_110114_12}" ,
							"#{TLTJ_110114_13}"	,
							"#{TLTJ_110114_14}"	,
						}

	g_CurrentClass_Clicked = 0
	g_CurrentTaotu_Clicked  = 0
	g_CurrentCard_Clicked = 0

	g_Current_Clicked = -1

	g_IsTeamOutLine_Class = {0, 0, 0, 0}
	g_IsTeamOutLine_Taotu = {
															{0,0,0,0,0,0,0,0,0,0},
															{0,0,0,0,0,0,0,0,0,0},
															{0,0,0,0,0,0,0,0,0,0},
															{0,0,0,0,0,0,0,0,0,0},
													}

	Tujian_Update(0, 0, 0, true, 0);

end


--===============================================
-- OnEvent()
--===============================================
function Tujian_Handbook_OnEvent( event )

	if ( event == "TOGLE_TJHANDBOOK" ) then
		if( arg0 == "2" ) then
			if( this:IsVisible() ) then
				this:Hide();
			else
				this:Show();
			end
		elseif ( arg0 == "1" ) then
			this:Show();
		else
			this:Hide();
		end
	elseif( event == "UPDATE_TJHANDBOOK" ) then

		local itempos = Handbook_Quest:GetCurrentFirstItem()
		Tujian_Update(g_CurrentClass_Clicked, g_CurrentTaotu_Clicked, g_CurrentCard_Clicked, true, itempos);

	elseif( event == "OPEN_TJHANDBOOK" ) then
		if arg0 == nil or arg1 == nil or arg2 == nil then
			return
		end

		local ClassFloor = tonumber(arg0)
		local TaotuFloor = tonumber(arg1)
		local CardFloor = tonumber(arg2)

		local ret = CheckFloorValue(ClassFloor, TaotuFloor, CardFloor)
		if ret == false then
			return
		end

		if ClassFloor == 0 or TaotuFloor == 0 or CardFloor == 0 then
			ClassFloor = 0
			TaotuFloor = 0
			CardFloor = 0
		end

		this:Show()
		if ClassFloor == 0 and TaotuFloor == 0 and CardFloor == 0 then  --如果是点击江湖指南链接按钮打开
				local itempos = Handbook_Quest:GetCurrentFirstItem()
				Tujian_Update(g_CurrentClass_Clicked, g_CurrentTaotu_Clicked, g_CurrentCard_Clicked, false, itempos);
		else --如果是从收集卡片里的连接按钮
			FreshOutLine()
			g_IsTeamOutLine_Class[ClassFloor] =  1
			g_IsTeamOutLine_Taotu[ClassFloor][TaotuFloor] = 1
			local itempos = Handbook_GetItemPos(ClassFloor, TaotuFloor, CardFloor)
			Tujian_Update(ClassFloor, TaotuFloor, CardFloor, true, itempos);
		end

	elseif( event == "ADJEST_UI_POS" ) then
		-- 更新界面位置
		Tujianbook_ResetPos()
	-- 游戏分辨率发生了变化
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 更新界面位置
		Tujianbook_ResetPos()
	elseif (event == "RESET_ALLUI") then
		FreshOutLine()
		g_CurrentClass_Clicked = 0
		g_CurrentTaotu_Clicked  = 0
		g_CurrentCard_Clicked = 0
	elseif(event == "UPDATE_FAKE_OBJECT" and this:IsVisible() ) then
		if( arg0 == "MyTujian_NPCBook" ) then
		--	local itempos = Handbook_Quest:GetCurrentFirstItem()
		--	Tujian_Update(g_CurrentClass_Clicked, g_CurrentTaotu_Clicked, g_CurrentCard_Clicked, true, itempos)
			Tujian_Handbook_UpdateCamera(0)
		elseif( arg0 == "MyTujian_HorseBook" ) then
			Tujian_Handbook_UpdateCamera(1)
		elseif( arg0 == "DressTujianBook_Player" ) then
			Tujian_Handbook_UpdateCamera(2)
		end
	end
end


function Tujian_Handbook_UpdateCamera(idx)

	local CardCameraDist = DataPool:GetTujianInfo_Card( g_CurrentClass_Clicked-1, g_CurrentTaotu_Clicked-1, g_CurrentCard_Clicked-1, "CAMERADIST");
	local CardCameraHeigt = DataPool:GetTujianInfo_Card( g_CurrentClass_Clicked-1, g_CurrentTaotu_Clicked-1, g_CurrentCard_Clicked-1, "CAMERAHEIGHT");
	local OBJTYPE = DataPool:GetTujianInfo_Card( g_CurrentClass_Clicked-1, g_CurrentTaotu_Clicked-1, g_CurrentCard_Clicked-1, "OBJTYPE");
	if idx == 0 then
		Handbook_MeshW : SetFakeObject( "" );
		Handbook_MeshW : SetFakeObject( "MyTujian_NPCBook" );
		NewFakeObj_SetCamera( "MyTujian_NPCBook", g_CameraDistance,tonumber(CardCameraDist));
		NewFakeObj_SetCamera( "MyTujian_NPCBook", g_CameraHeight,tonumber(CardCameraHeigt));
	elseif idx == 1 then
		Handbook_MeshW : SetFakeObject( "" );
		Handbook_MeshW : SetFakeObject( "MyTujian_HorseBook" );
		NewFakeObj_SetCamera( "MyTujian_HorseBook", g_CameraDistance,tonumber(CardCameraDist));
		NewFakeObj_SetCamera( "MyTujian_HorseBook", g_CameraHeight,tonumber(CardCameraHeigt));
	elseif idx == 2 then
		if OBJTYPE ~= -1 then
			Handbook_MeshW : SetFakeObject( "" );
			Handbook_MeshW : SetFakeObject( "DressTujianBook_Player" );
			NewFakeObj_SetCamera( "DressTujianBook_Player", g_CameraDistance,tonumber(CardCameraDist));
			NewFakeObj_SetCamera( "DressTujianBook_Player", g_CameraHeight,tonumber(CardCameraHeigt));
		end
	end

end

function FreshOutLine()
	g_IsTeamOutLine_Class = {0, 0, 0, 0}
	g_IsTeamOutLine_Taotu = {
														{0,0,0,0,0,0,0,0,0,0},
														{0,0,0,0,0,0,0,0,0,0},
														{0,0,0,0,0,0,0,0,0,0},
														{0,0,0,0,0,0,0,0,0,0},
													}
end


function CheckFloorValue(ClassFloor, TaotuFloor, CardFloor)
	if ClassFloor == nil or TaotuFloor == nil or CardFloor == nil then
		return false
	end

	if ClassFloor < 0 or ClassFloor > g_MaxNum_Class then
		return false
	end

	if TaotuFloor < 0 or TaotuFloor > g_MaxNum_TaotuInClass then
		return false
	end

	if CardFloor < 0 or CardFloor > g_MaxNum_CardInTaotu then
		return false
	end

	if CardFloor == 0 and ( TaotuFloor > 0 or CardFloor > 0 ) then
		return false
	end

	if TaotuFloor == 0 and CardFloor > 0 then
		return false
	end

	return true

end

function Tujianbook_ResetPos()
	Handbook_Frame:SetProperty("UnifiedXPosition", g_Handbook_Frame_UnifiedXPosition);
	Handbook_Frame:SetProperty("UnifiedYPosition", g_Handbook_Frame_UnifiedYPosition);
end


function TujianSelectChanged()
		local nSelIndex = Handbook_Quest:GetFirstSelectItem();
		local ClassFloor = math.floor( nSelIndex / 10000 );
		local ClassMod = math.mod( nSelIndex, 10000 )
		local TaotuFloor = math.floor( ClassMod / 100 );
		local CardFloor = math.mod( ClassMod, 100 )

		local needfresh = false
		if TaotuFloor == 0 and CardFloor == 0 then
			if(	g_IsTeamOutLine_Class[ClassFloor] == 1  ) then
				g_IsTeamOutLine_Class[ClassFloor] = 0
			else
				g_IsTeamOutLine_Class[ClassFloor] = 1
			end
			needfresh = true
		elseif CardFloor == 0 then
			if(	g_IsTeamOutLine_Taotu[ClassFloor][TaotuFloor] == 1  ) then
				g_IsTeamOutLine_Taotu[ClassFloor][TaotuFloor] = 0
			else
				g_IsTeamOutLine_Taotu[ClassFloor][TaotuFloor] = 1
			end
			needfresh = true
		end

		local itempos = Handbook_Quest:GetCurrentFirstItem()
		Tujian_Update(ClassFloor, TaotuFloor, CardFloor, needfresh, itempos)
end

function Tujian_Update(ClassFloor, TaotuFloor, CardFloor, needfresh, itempos)

		--if g_CurrentClass_Clicked == ClassFloor and
		--   g_CurrentTaotu_Clicked == TaotuFloor and
		--   g_CurrentCard_Clicked == CardFloor then
		--   return
		--end

		g_CurrentClass_Clicked = ClassFloor
		g_CurrentTaotu_Clicked = TaotuFloor
		g_CurrentCard_Clicked = CardFloor

		--显示目录
		if needfresh == true then

			--设置 当前收集卡片个数/总卡片个数
			local AllCardNum = DataPool:GetTujianInfo_All("ALLCARDNUM")
			local OwnCardNum = DataPool:GetTujianInfo_All("OWNCARDNUM")
			if AllCardNum ~= nil and OwnCardNum ~= nil then
				local str = tostring(OwnCardNum).."/"..tostring(AllCardNum)
				Handbook_L_CState2:SetText(str) ;
			end

			Handbook_Quest:ClearListBoxEx();
			for i = 1 , g_MaxNum_Class do
				--加入大类
				Handbook_AddClassItem(i)
				if(	g_IsTeamOutLine_Class[i] == 1  ) then
					for j = 1 , g_MaxNum_TaotuInClass do
						local bTaotuIsUsed = DataPool:GetTujianInfo_Taotu( i-1, j-1, "ISUSED")
						if bTaotuIsUsed == true then
							Handbook_AddTaotuItem(i , j)
						end
						if(	g_IsTeamOutLine_Taotu[i][j] == 1 and bTaotuIsUsed == true ) then
							for k = 1 , g_MaxNum_CardInTaotu do
								local bCardIsUsed = DataPool:GetTujianInfo_Card( i-1, j-1, k-1, "ISUSED")
								if bCardIsUsed == true then
									Handbook_AddCardItem(i , j, k)
								end
							end
						end
					end
				end
			end

			--调整位置
			Handbook_Quest:SetCurrentFirstItem(itempos);

		end


		--显示右边卡片
		if ClassFloor == 0 or TaotuFloor == 0 or CardFloor == 0 then
			--更换Handbook_R_Title
			Handbook_R_Title:SetProperty("Image", g_DirectTitle);

			--显示使用说明
			Handbook_Direction:SetText("#{TLTJ_110114_04}");
			Handbook_Direction:Show()
			Handbook_HideCardInterface()
			Handbook_Unknown:Hide()
		else
			--隐藏图鉴说明
			Handbook_Direction:Hide()
			--显示卡片
			Handbook_ShowCardItem(ClassFloor , TaotuFloor, CardFloor)
		end

end


function Handbook_GetItemPos(ClassFloor, TaotuFloor, CardFloor)
			--计算位置
			local ItemPos = -1;
			for i = 1 , ClassFloor do
				ItemPos = ItemPos + 1
				if(	ClassFloor == i  ) then
					for j = 1 , TaotuFloor do
						local bTaotuIsUsed = DataPool:GetTujianInfo_Taotu( i-1, j-1, "ISUSED")
						if bTaotuIsUsed == true then
							ItemPos = ItemPos + 1
						end
						if(	tonumber(TaotuFloor) == j and bTaotuIsUsed == true ) then
							for k = 1 , CardFloor do
								local bCardIsUsed = DataPool:GetTujianInfo_Card( i-1, j-1, k-1, "ISUSED")
								if bCardIsUsed == true then
									ItemPos = ItemPos + 1
								end
							end
						end
					end
				end
			end

			return ItemPos

end

--在目录中加入种类名字
function Handbook_AddClassItem(ClassFloor)
	local Pos = ClassFloor*10000;
	if ClassFloor < 1 or ClassFloor > 4 then
		return
	end

	local ClassIcon = ""
	--local num_DirectIconTable = table.getn(g_DirectIconTable);
	--if tonumber(ClassFloor) <= num_DirectIconTable then
	--	ClassIcon = g_DirectIconTable[tonumber(ClassFloor)];
	--end
	ClassIcon = "#-45"

	local TaotuNum = DataPool:GetTujianInfo_Class(ClassFloor-1, "TAOTUNUM")
	local OwnCardNum = DataPool:GetTujianInfo_Class(ClassFloor-1, "OWNCARDNUM")
	local CardNum = DataPool:GetTujianInfo_Class(ClassFloor-1, "CARDNUM")
	local str_Tongji = "("..tostring(OwnCardNum).."/"..tostring(CardNum)..")"

	if g_IsTeamOutLine_Class[ClassFloor] == 1 then
		Handbook_Quest:AddItem( ClassIcon.."#c000000- "..g_ClassStr[ClassFloor]..str_Tongji, Pos, "FFFFFFFF", 4)
	else
		Handbook_Quest:AddItem( ClassIcon.."#c000000+ "..g_ClassStr[ClassFloor]..str_Tongji, Pos, "FFFFFFFF", 4)
	end

end

--在目录中加入套图名字
function Handbook_AddTaotuItem(ClassFloor , TaotuFloor)
	local bIsUsed = DataPool:GetTujianInfo_Taotu( ClassFloor-1, TaotuFloor-1, "ISUSED")
	if bIsUsed == false then
		return
	end
	local TaotuName = DataPool:GetTujianInfo_Taotu( ClassFloor-1, TaotuFloor-1, "NAME");

	local TaotuIcon = ""
	--local num_DirectIconTable = table.getn(g_DirectIconTable);
	--if tonumber(ClassFloor) <= num_DirectIconTable then
	--	TaotuIcon = g_DirectIconTable[tonumber(ClassFloor)];
	--end
	TaotuIcon = "#-46"

	local TaotuName = DataPool:GetTujianInfo_Taotu( ClassFloor-1, TaotuFloor-1, "NAME");
	local OwnCardNum = DataPool:GetTujianInfo_Taotu( ClassFloor-1, TaotuFloor-1, "OWNCARDNUM");
	local CardNum = DataPool:GetTujianInfo_Taotu( ClassFloor-1, TaotuFloor-1, "CARDNUM");
	local str_Tongji = "("..tostring(OwnCardNum).."/"..tostring(CardNum)..")"

	local Pos = ClassFloor*10000 + TaotuFloor*100;

	if g_IsTeamOutLine_Taotu[ClassFloor][TaotuFloor] == 1 then
		Handbook_Quest:AddItem( g_TaotuIconSpin..TaotuIcon.."#c000000- "..TaotuName..str_Tongji , Pos , "FFFFFFFF", 4 );
	else
		Handbook_Quest:AddItem( g_TaotuIconSpin..TaotuIcon.."#c000000+ "..TaotuName..str_Tongji , Pos , "FFFFFFFF", 4 );
	end

end

--在目录中加入卡片名字
function Handbook_AddCardItem(ClassFloor , TaotuFloor, CardFloor)
	local bIsUsed = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "ISUSED")
	if bIsUsed == false then
		return
	end

	local CardIcon = ""
	local num_DirectIconTable = table.getn(g_DirectIconTable);
	if tonumber(ClassFloor) <= num_DirectIconTable then
		CardIcon = g_DirectIconTable[tonumber(ClassFloor)];
	end

	local CardName = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "NAME");
	local IsShowInDir = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "ISSHOWINDIR");
	local CardType = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "CARDTYPE");
	local IsHaveOwn = DataPool:GetTujianBit(tonumber(CardType))
	if IsHaveOwn ~= nil and IsHaveOwn == false then
		CardIcon = "#-44"
	end

	if IsShowInDir ~= nil and IsHaveOwn ~= nil and IsShowInDir <= 0 and IsHaveOwn == false then
		CardName = "???"
	end

	local Pos = ClassFloor*10000 + TaotuFloor*100 + CardFloor;
	Handbook_Quest:AddItem( g_CardIconSpin.."#c000000"..CardIcon..CardName , Pos, "FFFFFFFF", 4 );
end

function Handbook_ShowCardItem(ClassFloor , TaotuFloor, CardFloor)

  --加个判断，图鉴表中是否有这个卡片信息
	local bIsUsed = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "ISUSED")
	if bIsUsed == false then
		return
	end

	--更换Handbook_R_Title，显示标题
	local num_CardTitletable = table.getn(g_CardTitleTable);
	if tonumber(ClassFloor) <= num_CardTitletable then
		local strImage = g_CardTitleTable[tonumber(ClassFloor)];
		Handbook_R_Title:SetProperty("Image", strImage);
	end

	--是否为收集过的卡片
	local CardType = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "CARDTYPE");
	local IsHaveOwn = DataPool:GetTujianBit(tonumber(CardType))
	if IsHaveOwn ~= nil and IsHaveOwn == true then
		Handbook_ShowCardInterface()
		Handbook_Unknown:Hide()
	else
		Handbook_HideCardInterface()
		Handbook_Unknown:Show()
		return
	end

	-- 只有怪物有掉落描述
	if tonumber(ClassFloor) == 1 then
		Handbook_EX_BKG:Hide()
		if SystemSetup:IsClassic() == 0 then
			Handbook_BKG:Show()
		end
	else
		Handbook_EX_BKG:Show()
		if SystemSetup:IsClassic() == 0 then
			Handbook_BKG:Hide()
		end
	end

	--显示卡片的具体信息
	local CardName = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "NAME");
	local TaotuName = DataPool:GetTujianInfo_Taotu( ClassFloor-1, TaotuFloor-1, "NAME");
	local TJDescribe = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "TJDESCRIBE");
	local DLDescribe = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "DLDESCRIBE");
	local IndexInTaotu = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "INDEXINTAOTU");
	local CardNumInTaotu = DataPool:GetTujianInfo_Taotu( ClassFloor-1, TaotuFloor-1, "CARDNUM")
	local CardModelID = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "MODELID");
	local CardCameraDist = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "CAMERADIST");
	local CardCameraHeigt = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "CAMERAHEIGHT");

	if CardName ~= nil then
		Handbook_Name:SetText(CardName)
	end

	if TaotuName ~= nil then
		Handbook_R_Setname:SetText(TaotuName)
	end

	if IndexInTaotu ~= nil and CardNumInTaotu ~= nil then
		Handbook_R_Cardname:SetText(tostring(IndexInTaotu).."/"..tostring(CardNumInTaotu))
	end

	if TJDescribe ~= nil then
		Handbook_Intro:SetText(TJDescribe)
	end

	if DLDescribe ~= nil then
		Handbook_Drop:SetText(DLDescribe)
	end

	if CardModelID ~= nil then
		if tonumber(ClassFloor) == 1 or tonumber(ClassFloor) == 2 then
			Handbook_MeshW : SetFakeObject( "" );
			DataPool:TujianBook_SetNPCModel(tonumber(CardModelID), 1)
			Handbook_MeshW : SetFakeObject( "MyTujian_NPCBook" );
			NewFakeObj_SetCamera( "MyTujian_NPCBook", g_CameraDistance,tonumber(CardCameraDist));
			NewFakeObj_SetCamera( "MyTujian_NPCBook", g_CameraHeight,tonumber(CardCameraHeigt));
		elseif tonumber(ClassFloor) == 3 then
			Handbook_MeshW : SetFakeObject( "" );
			DataPool:TujianBook_SetHorseModel(tonumber(CardModelID), 1)
			Handbook_MeshW : SetFakeObject( "MyTujian_HorseBook" );
			NewFakeObj_SetCamera( "MyTujian_HorseBook", g_CameraDistance,tonumber(CardCameraDist));
			NewFakeObj_SetCamera( "MyTujian_HorseBook", g_CameraHeight,tonumber(CardCameraHeigt));
		elseif tonumber(ClassFloor) == 4 then
			local OBJTYPE = DataPool:GetTujianInfo_Card( ClassFloor-1, TaotuFloor-1, CardFloor-1, "OBJTYPE");
			if OBJTYPE ~= -1 then
				DataPool:TujianBook_SetDressModel(tonumber(CardModelID), 1, tonumber(OBJTYPE))
				Handbook_MeshW : SetFakeObject( "" );
				Handbook_MeshW : SetFakeObject( "DressTujianBook_Player" );
				NewFakeObj_SetCamera( "DressTujianBook_Player", g_CameraDistance,tonumber(CardCameraDist));
				NewFakeObj_SetCamera( "DressTujianBook_Player", g_CameraHeight,tonumber(CardCameraHeigt));
			end
		end

	end

	--更换Handbook_Race
	local num_CardRacetable = table.getn(g_RaceTable_Book);
	if tonumber(ClassFloor) <= num_CardRacetable then
		local strImage = g_RaceTable_Book[tonumber(ClassFloor)];
		Handbook_Race:SetProperty("Image", strImage);
	end

end


function Handbook_HideCardInterface()
	Handbook_Done:Hide()
	Handbook_Name:Hide()
	Handbook_R_Setname:Hide()
	Handbook_R_Cardname:Hide()
	Handbook_Intro:Hide()
	Handbook_Drop:Hide()
	Handbook_Race:Hide()
	Handbook_Mesh:Hide()
	Handbook_Drop_BKG:Hide()
	Handbook_EX_BKG:Hide()
end


function Handbook_ShowCardInterface()
	Handbook_Done:Show()
	Handbook_Name:Show()
	Handbook_R_Setname:Show()
	Handbook_R_Cardname:Show()
	Handbook_Intro:Show()
	Handbook_Drop:Show()
	Handbook_Race:Show()
	Handbook_Mesh:Show()
	Handbook_Drop_BKG:Show()
	Handbook_EX_BKG:Show()
end

function TJHandbook_Close()
	PushDebugMessage("#{TLTJ_110223_17}")
	this:Hide()
end

function Handbook_OpenWordrefence()
	OpenWordrefence();
end
