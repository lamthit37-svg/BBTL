-- 图鉴卡的默认位置
local g_Handcard_Frame_UnifiedXPosition
local g_Handcard_Frame_UnifiedYPosition

local g_ClassStr = {
							"#{TLTJ_110114_11}"	,
							"#{TLTJ_110114_12}" ,
							"#{TLTJ_110114_13}"	,
							"#{TLTJ_110114_14}"	,
							}

local g_RaceTable_Card = {
							"set:Handbook1 image:HandCard_Logo_Monster"	,
							"set:Handbook1 image:HandCard_Logo_Pet" ,
							"set:Handbook1 image:HandCard_Logo_Ride"	,
							"set:Handbook1 image:HandCard_Logo_Dress"	,
							}

local g_CurrentClassIndex = -1
local g_CurrentTaotuIndex  = -1
local g_CurrentCardIndex = -1

local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度

--===============================================
-- OnLoad()
--===============================================
function Tujian_HandCard_PreLoad()

	this:RegisterEvent("TOGLE_TJHANDCARD");
	this:RegisterEvent("OPEN_TJHANDCARD");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("UPDATE_TJHANDBOOK")
	this:RegisterEvent("UPDATE_FAKE_OBJECT")
end

function Tujian_HandCard_OnLoad()

	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片资源为唯美版
		g_RaceTable_Card = {
							"set:WM_Tujian image:Monster"	,
							"set:WM_Tujian image:Pet" ,
							"set:WM_Tujian image:Ride"	,
							"set:WM_Tujian image:Equip"	,
							}
	end

	-- 保存图鉴卡界面的默认相对位置
	g_Handcard_Frame_UnifiedXPosition	= Handcard_Frame:GetProperty("UnifiedXPosition");
	g_Handcard_Frame_UnifiedYPosition	= Handcard_Frame:GetProperty("UnifiedYPosition");

	g_ClassStr = {
							"#{TLTJ_110114_11}"	,
							"#{TLTJ_110114_12}" ,
							"#{TLTJ_110114_13}"	,
							"#{TLTJ_110114_14}"	,
						}

	g_CurrentClassIndex = -1
	g_CurrentTaotuIndex  = -1
	g_CurrentCardIndex = -1

end


--===============================================
-- OnEvent()
--===============================================
function Tujian_HandCard_OnEvent( event )

	if ( event == "TOGLE_TJHANDCARD" ) then
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

	elseif( event == "OPEN_TJHANDCARD" ) then
		if arg0 ~= nil then
			local ClassIndex, TaotuIndex, CardIndex = DataPool:GetDirectory_TujianCard(tonumber(arg0))
			if ClassIndex ~= nil and TaotuIndex ~= nil and CardIndex ~= nil and
				 ClassIndex ~= -1 and TaotuIndex ~= -1 and CardIndex ~= -1 then
				this:Show()
				g_CurrentClassIndex = ClassIndex
				g_CurrentTaotuIndex  = TaotuIndex
				g_CurrentCardIndex = CardIndex
				ShowCard(ClassIndex, TaotuIndex, CardIndex);
			end
		end

	elseif( event == "ADJEST_UI_POS" ) then
		-- 更新界面位置
		Tujiancard_ResetPos()
	-- 游戏分辨率发生了变化
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		-- 更新界面位置
		Tujiancard_ResetPos()
	elseif( event == "UPDATE_TJHANDBOOK" ) then
		--切换场景后,Server会发包过来，说更新一下图鉴Book信息，图鉴Card也就顺便更新了。。
		if( this:IsVisible() ) then
			ShowCard(g_CurrentClassIndex, g_CurrentTaotuIndex, g_CurrentCardIndex)
		end
	elseif(event == "UPDATE_FAKE_OBJECT" and this:IsVisible() ) then
		--这个界面中包含好几个FakeObj，需要做下判断
		if arg0 == "MyTujian_NPCCard" and ( g_CurrentClassIndex == 0 or g_CurrentClassIndex == 1 ) then
			ShowCard(g_CurrentClassIndex, g_CurrentTaotuIndex, g_CurrentCardIndex)
		elseif arg0 == "MyTujian_HorseCard" and g_CurrentClassIndex == 2 then
			ShowCard(g_CurrentClassIndex, g_CurrentTaotuIndex, g_CurrentCardIndex)
		elseif arg0 == "DressTujianCard_Player" and g_CurrentClassIndex == 3 then
			ShowCard(g_CurrentClassIndex, g_CurrentTaotuIndex, g_CurrentCardIndex)
		end
	end
end

function Tujiancard_ResetPos()
	Handcard_Frame:SetProperty("UnifiedXPosition", g_Handcard_Frame_UnifiedXPosition);
	Handcard_Frame:SetProperty("UnifiedYPosition", g_Handcard_Frame_UnifiedYPosition);
end

function ShowCard(ClassIndex, TaotuIndex, CardIndex)

  --加个判断，图鉴表中是否有这个卡片信息
	local bIsUsed = DataPool:GetTujianInfo_Card( ClassIndex, TaotuIndex, CardIndex, "ISUSED")
	if bIsUsed == false then
		return
	end

	-- 只有怪物有掉落描述
	if tonumber(ClassIndex) == 0 then
		Handcard_EX_BKG:Hide()
		if SystemSetup:IsClassic() == 0 then
			Handcard_BKG:Show()
		end
	else
		Handcard_EX_BKG:Show()
		if SystemSetup:IsClassic() == 0 then
			Handcard_BKG:Hide()
		end
	end


	--显示卡片的具体信息
	local CardName = DataPool:GetTujianInfo_Card( ClassIndex, TaotuIndex, CardIndex, "NAME");
	local TaotuName = DataPool:GetTujianInfo_Taotu( ClassIndex, TaotuIndex, "NAME");
	local TJDescribe = DataPool:GetTujianInfo_Card( ClassIndex, TaotuIndex, CardIndex, "TJDESCRIBE");
	local DLDescribe = DataPool:GetTujianInfo_Card( ClassIndex, TaotuIndex, CardIndex, "DLDESCRIBE");
	local IndexInTaotu = DataPool:GetTujianInfo_Card( ClassIndex, TaotuIndex, CardIndex, "INDEXINTAOTU");
	local CardNumInTaotu = DataPool:GetTujianInfo_Taotu( ClassIndex, TaotuIndex, "CARDNUM")
	local CardModelID = DataPool:GetTujianInfo_Card( ClassIndex, TaotuIndex, CardIndex, "MODELID");
	local CardCameraDist = DataPool:GetTujianInfo_Card( ClassIndex, TaotuIndex, CardIndex, "CAMERADIST");
	local CardCameraHeigt = DataPool:GetTujianInfo_Card( ClassIndex, TaotuIndex, CardIndex, "CAMERAHEIGHT");

	if CardName ~= nil then
		Handcard_Name:SetText(CardName)
	end

	if TaotuName ~= nil then
		Handcard_R_Setname:SetText(TaotuName)
	end

	if IndexInTaotu ~= nil and CardNumInTaotu ~= nil then
		Handcard_R_Cardname:SetText(tostring(IndexInTaotu).."/"..tostring(CardNumInTaotu))
	end

	if TJDescribe ~= nil then
		Handcard_Intro:SetText(TJDescribe)
	end

	if DLDescribe ~= nil then
		Handcard_Drop:SetText(DLDescribe)
	end

	if CardModelID ~= nil then
		if ClassIndex == 0 or ClassIndex == 1 then
			Handcard_MeshW : SetFakeObject( "" );
			DataPool:TujianCard_SetNPCModel(tonumber(CardModelID), 1)
			Handcard_MeshW : SetFakeObject( "MyTujian_NPCCard" );
			NewFakeObj_SetCamera( "MyTujian_NPCCard", g_CameraDistance,tonumber(CardCameraDist));
			NewFakeObj_SetCamera( "MyTujian_NPCCard", g_CameraHeight,tonumber(CardCameraHeigt));
		elseif ClassIndex == 2 then
			Handcard_MeshW : SetFakeObject( "" );
			DataPool:TujianCard_SetHorseModel(tonumber(CardModelID), 1)
			Handcard_MeshW : SetFakeObject( "MyTujian_HorseCard" );
			NewFakeObj_SetCamera( "MyTujian_HorseCard", g_CameraDistance,tonumber(CardCameraDist));
			NewFakeObj_SetCamera( "MyTujian_HorseCard", g_CameraHeight,tonumber(CardCameraHeigt));
		elseif ClassIndex == 3 then
			local OBJTYPE = DataPool:GetTujianInfo_Card( ClassIndex, TaotuIndex, CardIndex, "OBJTYPE");
			if OBJTYPE ~= -1 then
				Handcard_MeshW : SetFakeObject( "" );
				DataPool:TujianCard_SetDressModel(tonumber(CardModelID), 1, tonumber(OBJTYPE))
				Handcard_MeshW : SetFakeObject( "DressTujianCard_Player" );
				NewFakeObj_SetCamera( "DressTujianCard_Player", g_CameraDistance,tonumber(CardCameraDist));
				NewFakeObj_SetCamera( "DressTujianCard_Player", g_CameraHeight,tonumber(CardCameraHeigt));
			end
		end

	end

	--更换Handcard_Race
	local num_CardRacetable = table.getn(g_RaceTable_Card);
	if ClassIndex + 1 <= num_CardRacetable then
		local strImage = g_RaceTable_Card[ClassIndex + 1];
		Handcard_Race:SetProperty("Image", strImage);
	end

end

function TJHandCard_Close()
	this:Hide()
end

function Handcard_GotoBook()
	local IsShow = IsWindowShow("Tujian_Handbook")
	if IsShow == true then
		CloseWindow("Tujian_Handbook", true);
	end
	PushEvent("OPEN_TJHANDBOOK", g_CurrentClassIndex+1, g_CurrentTaotuIndex+1, g_CurrentCardIndex+1)
	this:Hide()
end
