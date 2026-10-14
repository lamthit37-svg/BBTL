
g_clientNpcId = -1
g_data = {}
g_TabIndex = 1
g_Tab2Index = 1
g_Tab3Index = 1



function BieYeBaseInfo_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SHOW_BIEYE_BASEINFO")
	this:RegisterEvent("SCENE_TRANSED")
end

function BieYeBaseInfo_OnLoad()

end

function BieYeBaseInfo_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 89187201 then
		g_clientNpcId = DataPool:GetNPCIDByServerID(Get_XParam_INT(0))
		g_data["use1"] = Get_XParam_INT(1)
		g_data["use2"] = Get_XParam_INT(2)
		g_data["hasAwake"] = Get_XParam_INT(3)
		BieYeUI:AskBieYeBaseInfo(0)
	elseif event == "SHOW_BIEYE_BASEINFO" then
		if not arg0 or type(arg0) ~= "string" then
			return
		end
		if arg0 == "FurnitureInfo" then
			if this:IsVisible() then
				BieYeBaseInfo_Update()
			end
		elseif arg0 == "show" then
			BieYeBaseInfo_Show()
		elseif arg0 == "UpdateGardner" then
			BieYeBaseInfo_UpdateGardnerInfo()
		end
	elseif event == "SCENE_TRANSED" then
		BieYeBaseInfo_Close()
	end
end

function BieYeBaseInfo_MakeCreateTime()
	local t = BieYeUI:GetBieYeBaseInfo("CreateTime")
	local y = math.floor( t / 100000000 )
	local m = math.mod( math.floor( t / 1000000 ), 100 )
	local d = math.mod( math.floor( t / 10000 ), 100 )
	
	local ret = "20"..y.."-"..m.."-"..d
	return ret
end

function BieYeBaseInfo_Close()
	this:CareObject( g_clientNpcId, 0, "BieYeBaseInfo" )
	g_clientNpcId = -1
	this:Hide()
end

function BieYeBaseInfo_TabSwitch(n)
	if n < 1 or n > 2 then
		return
	end
	g_TabIndex = n
	for i=1, 2 do
		_G["BieYeBaseInfo_InfoClint"..i]:Hide()
	end
	_G["BieYeBaseInfo_InfoClint"..n]:Show()
	if n == 2 then
		BieYeUI:AskBieYeBaseInfo(5)
	end
end

function BieYeBaseInfo_Tab2Switch(n)
	if n < 1 or n > 6 then
		return
	end
	g_Tab2Index = n
	g_Tab3Index = 1
	BieYeBaseInfo_UpdateTabShow()
	BieYeBaseInfo_UpdateBuildingInfo()
end

function BieYeBaseInfo_Tab3Switch(n)
	if n < 1 or n > 2 then
		return
	end
	g_Tab3Index = n
	BieYeBaseInfo_UpdateBuildingInfo()
end

function BieYeBaseInfo_MakeProductionStr( i )
	if i < 0 or i >= 5 then
		return ""
	end
	local nIndex = math.mod( i, 2 ) + 1
	local p1,p2,p3 = BieYeUI:GetBieYeBaseInfo("ProductInfo",i)
	if p1 == 0 or p1 == 1 then  --空闲
		if i < 2 then
			return ScriptGlobal_Format( "#{JYGZ_160523_125}", nIndex )
		elseif i < 4 then
			return ScriptGlobal_Format( "#{JYGZ_160523_133}", nIndex )
		else
			return "#{JYGZ_160523_140}"
		end
		return ""
	end
	local ProductName,lv,needYb = BieYeUI:GetMaterialOutputNameById(p3)
	if p1 == 2 then --成长期
		local t = ""
		if p2 >= 60 then
			t = string.format("%d小时%d分钟", math.floor( p2 / 60 ), math.mod( p2,60 ) )
		else
			if p2 == 0 then
				p2 = 1
			end
			t = p2.."分钟"
		end
		if i < 2 then 
			return ScriptGlobal_Format( "#{JYGZ_160523_126}", nIndex, ProductName, t )
		elseif i < 4 then
			return ScriptGlobal_Format( "#{JYGZ_160523_134}", nIndex, ProductName, t )
		else
			return ScriptGlobal_Format( "#{JYGZ_160523_141}", ProductName, t )
		end
		return ""
	end
	if p1 == 3 then --成熟期
		local t = ""
		if p2 >= 60 then
			t = string.format("%d小时%d分钟", math.floor( p2 / 60 ), math.mod( p2,60 ) )
		else
			if p2 == 0 then
				p2 = 1
			end
			t = p2.."分钟"
		end
		if needYb then
			if i < 2 then 
				return ScriptGlobal_Format( "#{JYGZ_160809_498}", nIndex, ProductName )
			elseif i < 4 then
				return ScriptGlobal_Format( "#{JYGZ_160809_499}", nIndex, ProductName )
			else
				return ScriptGlobal_Format( "#{JYGZ_160809_500}", ProductName )
			end
		else
			if i < 2 then 
				return ScriptGlobal_Format( "#{JYGZ_160523_127}", nIndex, ProductName, t )
			elseif i < 4 then
				return ScriptGlobal_Format( "#{JYGZ_160523_135}", nIndex, ProductName, t )
			else
				return ScriptGlobal_Format( "#{JYGZ_160523_142}", ProductName, t )
			end
		end
		return ""
	end
	if p1 == 4 then --衰败期
		if i < 2 then 
			return ScriptGlobal_Format( "#{JYGZ_160523_128}", nIndex, ProductName )
		elseif i < 4 then
			return ScriptGlobal_Format( "#{JYGZ_160523_136}", nIndex, ProductName )
		else
			return ScriptGlobal_Format( "#{JYGZ_160523_143}", ProductName )
		end
		return ""
	end
	return ""
end

function BieYeBaseInfo_MakeShouLanStatusStr( i )
	local JYSLOperType,JYSLPos,JYSLLevel,JYSLOperTime,JYSLTimeStart,JYSLGainValue,JYSLGainLevel = Pet:GetJYSLPetList_Appoint_PetBank(i)
	local szPetName, xiedaiLevl, CurrentLevel, szOn = Pet:GetPetList_Appoint_PetBank(i)
	if JYSLOperType < 1 or JYSLOperType > 3 then
		if i == 1 and BieYeUI:GetBieYeBaseInfo("BuildingLevel",2) < 3 then
			return ScriptGlobal_Format("#{JYGZ_160523_154}",2)
		elseif i == 2 and BieYeUI:GetBieYeBaseInfo("BuildingLevel",2) < 5 then
			return ScriptGlobal_Format("#{JYGZ_160523_156}",3)
		else
			return ScriptGlobal_Format("#{JYGZ_160714_238}",i+1)
		end
	end

	local nRemainHour, nRemainMin, nRemainSec = Pet:GetJYSLPetRemainTime(JYSLOperTime,JYSLTimeStart)
	local totalRemain = nRemainHour * 24 * 3600 + nRemainMin * 60 + nRemainSec
	if nRemainHour == 0 and nRemainMin == 0 and totalRemain ~= 0 then
		nRemainMin = 1
	end
	if JYSLOperType == 1 then
		local typedic = {
			"#{JYSL_160518_214}",
			"#{JYSL_160518_215}",
			"#{JYSL_160518_216}",
			"#{JYSL_160518_217}",
			"#{JYSL_160518_218}"
		}
		if totalRemain > 0 then
			return ScriptGlobal_Format( "#{JYGZ_160523_151}", i+1, typedic[JYSLLevel], szPetName, nRemainHour.."小时"..nRemainMin.."分" )
		else
			return ScriptGlobal_Format( "#{JYGZ_160809_472}", i+1, typedic[JYSLLevel], szPetName )
		end
	elseif JYSLOperType == 2 then
		local typedic = {
			"#{JYSL_160518_220}",
			"#{JYSL_160518_221}",
			"#{JYSL_160518_222}",
			"#{JYSL_160518_223}",
			"#{JYSL_160518_224}"
		}
		if totalRemain > 0 then
			return ScriptGlobal_Format( "#{JYGZ_160523_152}", i+1, typedic[JYSLLevel], szPetName, nRemainHour.."小时"..nRemainMin.."分" )
		else
			return ScriptGlobal_Format( "#{JYGZ_160809_473}", i+1, typedic[JYSLLevel], szPetName )
		end
	end
	return " "
end

function BieYeBaseInfo_MakeShouLanTotalStr()
	local level = BieYeUI:GetBieYeBaseInfo("BuildingLevel",2)
	if level >= 5 then
		return "3/3"
	elseif level >= 3 then
		return "2/3"
	else
		return "1/3"
	end
end

function BieYeBaseInfo_Show()
	if g_clientNpcId ~= -1 then
		this:CareObject( g_clientNpcId, 1, "BieYeBaseInfo" )
	end
	if not this:IsVisible() then
		g_TabIndex = 1
		g_Tab2Index = 1
		g_Tab3Index = 1
	end
	if IsWindowShow( "BieYeBuildingManage" ) then
		CloseWindow( "BieYeBuildingManage", true )
	end
	BieYeBaseInfo_UpdateTabShow()
	BieYeBaseInfo_Update()
	this:Show()
end

function BieYeBaseInfo_GetCleanessFactor()
	local factor = "1"
	return factor
end

function BieYeBaseInfo_UpdateBuildingInfo()
	local strdict = { "", "" }
	if g_Tab2Index == 1 then
		local byLevel = BieYeUI:GetBieYeBaseInfo("BuildingLevel",0)
		local nXiaoWoCount = BieYeMengChong:GetBieYePutMengChongLimitByBieYeLevel()
		local MengChongOutNum = BieYeMengChong:GetBieYeXiaoWoCount()
		strdict = { ScriptGlobal_Format("#{JYGZ_160809_470}", byLevel, byLevel * 2, g_data.use1, byLevel * 1, g_data.use2 ,nXiaoWoCount,MengChongOutNum), "#{JYGZ_160809_471}" }
	elseif g_Tab2Index == 2 then
		local cangkuLevel = BieYeUI:GetBieYeBaseInfo("BuildingLevel",1)
		strdict = { ScriptGlobal_Format("#{JYGZ_160523_120}",cangkuLevel ).."\n"..ScriptGlobal_Format("#{JYGZ_160523_121}", cangkuLevel * 4 ), "#{JYGZ_160523_122}" }
	elseif g_Tab2Index == 3 then
		strdict = { 
			string.format("%s\n%s\n%s",
				ScriptGlobal_Format("#{JYGZ_160523_123}", BieYeUI:GetBieYeBaseInfo("BuildingLevel",4) ),
				BieYeBaseInfo_MakeProductionStr( 0 ),
				BieYeBaseInfo_MakeProductionStr( 1 )
			),
			"#{JYGZ_160523_130}"
		}
	elseif g_Tab2Index == 4 then
		strdict = { 
			string.format("%s\n%s\n%s",
				ScriptGlobal_Format("#{JYGZ_160523_131}", BieYeUI:GetBieYeBaseInfo("BuildingLevel",6) ),
				BieYeBaseInfo_MakeProductionStr( 2 ),
				BieYeBaseInfo_MakeProductionStr( 3 )
			),
			"#{JYGZ_160523_137}"
		}
	elseif g_Tab2Index == 5 then
		strdict = { 
			string.format("%s\n%s",
				ScriptGlobal_Format("#{JYGZ_160523_131}", BieYeUI:GetBieYeBaseInfo("BuildingLevel",3) ),
				BieYeBaseInfo_MakeProductionStr( 4 )
			),
			"#{JYGZ_160523_144}"
		}
	elseif g_Tab2Index == 6 then
		local awakestr = "#{JYGZ_160809_475}"
		if g_data.hasAwake == 1 then
			awakestr = "#{JYGZ_160809_474}"
		end
		strdict = { 
			string.format("%s\n%s\n%s\n%s\n%s\n%s",
				ScriptGlobal_Format( "#{JYGZ_160523_145}", BieYeUI:GetBieYeBaseInfo("BuildingLevel",2) ),
				BieYeBaseInfo_MakeShouLanStatusStr( 0 ),
				BieYeBaseInfo_MakeShouLanStatusStr( 1 ),
				BieYeBaseInfo_MakeShouLanStatusStr( 2 ),
				awakestr,
				"#{JYGZ_160809_501}"
			),
			"#{JYGZ_160809_476}"
		}
	end
	BieYeBaseInfo_BuildingInfo_des:SetText(strdict[g_Tab3Index])
end

function BieYeBaseInfo_UpdateTabShow()
	for i=1, 2 do
		if i == g_TabIndex then
			_G["BieYeBaseInfo_InfoTop_Btn"..i]:SetCheck(1)
		else
			_G["BieYeBaseInfo_InfoTop_Btn"..i]:SetCheck(0)
		end
	end
	for i=1, 6 do
		if i == g_Tab2Index then
			_G["BieYeBaseInfo_BuildingTop_Btn"..i]:SetCheck(1)
		else
			_G["BieYeBaseInfo_BuildingTop_Btn"..i]:SetCheck(0)
		end
	end
	for i=1, 2 do
		if i == g_Tab3Index then
			_G["BieYeBaseInfo_BuildingFenye_FY"..i]:SetCheck(1)
		else
			_G["BieYeBaseInfo_BuildingFenye_FY"..i]:SetCheck(0)
		end
	end
end

function BieYeBaseInfo_Update()
	BieYeBaseInfo_TabSwitch(g_TabIndex)
	BieYeBaseInfo_Tab2Switch(g_Tab2Index)
	BieYeBaseInfo_Owner_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_101}", ""..BieYeUI:GetBieYeBaseInfo("MasterName") ) )
	BieYeBaseInfo_CreateTime_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_108}", BieYeBaseInfo_MakeCreateTime() ) )
	BieYeBaseInfo_CaiLiao1_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_157}",""..BieYeUI:GetBieYeBaseInfo("ResWoods") ) )
	BieYeBaseInfo_CaiLiao2_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_159}",""..BieYeUI:GetBieYeBaseInfo("ResFoods") ) )
	BieYeBaseInfo_CaiLiao3_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_161}",""..BieYeUI:GetBieYeBaseInfo("ResStones") ) )
	
	BieYeBaseInfo_YuanDingFree_des:SetText( "#{JYGZ_160809_455}" )
	BieYeBaseInfo_YuanDingNoFree_des:SetText( "#{JYGZ_160809_456}" )
	
	BieYeBaseInfo_JuShiShuShi_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_109}",""..BieYeUI:GetBieYeBaseInfo("HouseComfort") ) )
	BieYeBaseInfo_TingYuanShuShi_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_112}",""..BieYeUI:GetBieYeBaseInfo("YardComfort") ) )
	
	local a1,a2 = BieYeUI:GetBieYeBaseInfo("HouseFurniturePair")
	BieYeBaseInfo_JuShiJiaJu_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_110}",""..a1,""..a2 ) )
	a1,a2 = BieYeUI:GetBieYeBaseInfo("YardFurniturePair")
	BieYeBaseInfo_TingYuanJiaJu_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_113}",""..a1,""..a2 ) )
	
	BieYeBaseInfo_HomeLv_des:SetText( ScriptGlobal_Format("#{JYGZ_160523_104}",""..BieYeUI:GetBieYeBaseInfo("BuildingLevel",0) ) )
end

function BieYeBaseInfo_UpdateGardnerInfo()
	BieYeBaseInfo_YDFreeInfo1_des:SetText(BieYeBaseInfo_GetGardnerStr(0))
	BieYeBaseInfo_YDFreeInfo2_des:SetText(BieYeBaseInfo_GetGardnerStr(1))
	BieYeBaseInfo_YDNoFreeInfo1_des:SetText(BieYeBaseInfo_GetGardnerStr(2))
	BieYeBaseInfo_YDNoFreeInfo2_des:SetText(BieYeBaseInfo_GetGardnerStr(3))
	BieYeBaseInfo_YDNoFreeInfo3_des:SetText(BieYeBaseInfo_GetGardnerStr(4))
	BieYeBaseInfo_YDNoFreeInfo4_des:SetText(BieYeBaseInfo_GetGardnerStr(5))
end

function BieYeBaseInfo_GetGardnerStr(i)
	local str = "#{JYGZ_160809_457}"
	local WorkType,BuildingIndex, Remains, PlantType = BieYeUI:GetBieYeBaseInfo("GardnerInfo",i)
	local h,s = math.floor(Remains/60),math.mod(Remains,60)
	if h == 0 and s == 0 then
		s = 1
	end
	local t = ""
	if h == 0 then
		t = ""..s.."分钟"
	else
		t = ""..h.."小时"..s.."分钟"
	end
	if WorkType >= 4 and WorkType <= 9 then
		local buildingName = { [4]="#{JYGZ_160809_465}",[5]="#{JYGZ_160809_466}",[6]="#{JYGZ_160809_464}",[7]="#{JYGZ_160809_463}",[8]="#{JYGZ_160809_462}",[9]="#{JYGZ_160809_467}"}
		str = ScriptGlobal_Format( "#{JYGZ_160809_458}", buildingName[WorkType], t )
	elseif WorkType > 0 and WorkType <= 3 then
		local ProductName,lv = BieYeUI:GetMaterialOutputNameById(PlantType)
		if WorkType == 1 then
			str = ScriptGlobal_Format( "#{JYGZ_160809_461}", ProductName, t )
		elseif WorkType == 2 then
			str = ScriptGlobal_Format( "#{JYGZ_160809_460}", ProductName, t )
		elseif WorkType == 3 then
			str = ScriptGlobal_Format( "#{JYGZ_160809_459}", ProductName, t )
		end
	end
	return str
end

function BieYeBaseInfo_Close()
	this:Hide()
end

function BieYeBaseInfo_GetHelp(n)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnGetHelp")
		Set_XSCRIPT_ScriptID(891872)
		Set_XSCRIPT_Parameter(0,n)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT();
end
