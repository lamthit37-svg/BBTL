
local g_WindowType = -1    -- 0 : 自己  1 : 其他人
local g_ElementsIndex = -1

local 	g_JadeAnimate = { "BaoJianUI3_Jin" ,"BaoJianUI3_Shui" ,"BaoJianUI3_Mu" ,"BaoJianUI3_Huo" ,"BaoJianUI3_Tu"  }
local		g_JadeAnimateCtrl = {}
local		g_JadeIconCtrl = {}
local 	g_JadeText = {}

local g_TitleName = { "#{ZZZB_150811_126}" , "#{ZZZB_150811_128}","#{ZZZB_150811_127}","#{ZZZB_150811_129}","#{ZZZB_150811_130}" }
local g_ElementsImage = {

	"set:BaoJianUI image:BaoJianUI_00",
	"set:BaoJianUI image:BaoJianUI_01",
	"set:BaoJianUI image:BaoJianUI_02",
	"set:BaoJianUI image:BaoJianUI_03",
	"set:BaoJianUI1 image:BaoJianUI_04",
}

local 	g_JadeName =  {
			"#{ZZZB_150811_134}",
			"#{ZZZB_150811_136}",	
			"#{ZZZB_150811_135}",					
			"#{ZZZB_150811_137}",
			"#{ZZZB_150811_138}",
	}
	
local 	g_ElementsValueName = {
	
	[ 1 ] = { 
		"#{ZZZB_150811_166}",
		"#{ZZZB_150811_167}",
		"#{ZZZB_150811_168}",
		"#{ZZZB_150811_169}",
	},
	
	[ 2 ] = { 
		"#{ZZZB_150811_172}",
		"#{ZZZB_150811_173}",
		"#{ZZZB_150811_174}",
		"#{ZZZB_150811_175}",
		"#{ZZZB_150811_176}",
		"#{ZZZB_150811_177}",
		"#{ZZZB_150811_178}",
		"#{ZZZB_150811_179}",
	},
	
	[ 3 ] = { 
		"#{ZYYH_120824_19}",
	},
	
	[ 4 ] = { 
		"#{ZZZB_150811_182}",
		"#{ZZZB_150811_183}",
	},
	
	[ 5 ] = { 
		"#{ZYYH_120824_18}",
	},

}
	
--=========
--PreLoad==
--=========
function SelfBaoJian_Tips_PreLoad()
	this:RegisterEvent("SELF_FIVEELEMENTS_TIP_OPEN")
	this:RegisterEvent("TARGET_FIVEELEMENTS_TIP_OPEN")
	this:RegisterEvent("SELF_FIVEELEMENTS_TIP_CLOSE")
	this:RegisterEvent("TARGET_FIVEELEMENTS_TIP_CLOSE")
end
--=========
--OnLoad
--=========
function SelfBaoJian_Tips_OnLoad()

	g_JadeAnimateCtrl = {
	
		[ 1 ] = SelfBaoJian_Tips_Bk1_Animate1,
		[ 2 ] = SelfBaoJian_Tips_Bk2_Animate1,
		[ 3 ] = SelfBaoJian_Tips_Bk3_Animate1,
		[ 4 ] = SelfBaoJian_Tips_Bk4_Animate1,
		[ 5 ] = SelfBaoJian_Tips_Bk5_Animate1,
	}
	
	g_JadeIconCtrl = {
	
		[ 1 ] = SelfBaoJian_Tips_Bk1_Btn1,
		[ 2 ] = SelfBaoJian_Tips_Bk2_Btn1,
		[ 3 ] = SelfBaoJian_Tips_Bk3_Btn1,
		[ 4 ] = SelfBaoJian_Tips_Bk4_Btn1,
		[ 5 ] = SelfBaoJian_Tips_Bk5_Btn1,
	}
	
	g_JadeText[ 1 ] = SelfBaoJian_Tips_Bk1_Text
	g_JadeText[ 2 ] = SelfBaoJian_Tips_Bk2_Text
	g_JadeText[ 3 ] = SelfBaoJian_Tips_Bk3_Text
	g_JadeText[ 4 ] = SelfBaoJian_Tips_Bk4_Text
	g_JadeText[ 5 ] = SelfBaoJian_Tips_Bk5_Text
	
end
--=========
--OnEvent
--=========
function SelfBaoJian_Tips_OnEvent(event)

	if event ==  "SELF_FIVEELEMENTS_TIP_OPEN" then
		
		g_WindowType = 0
		g_ElementsIndex = tonumber(arg0)
		local SetX = tonumber(arg1)
		local SetY = tonumber(arg2)
		local SetWidth = tonumber(arg3)
		local SetHeight = tonumber(arg4)
		SelfBaoJian_Tips_Update_Self()
		SelfBaoJian_Tips_AdjustPosition(SetX,SetY,SetWidth,SetHeight)
		this:Show()
		return
	end
	
	if event ==  "TARGET_FIVEELEMENTS_TIP_OPEN" then
		
		g_WindowType = 1
		g_ElementsIndex = tonumber(arg0)
		local SetX = tonumber(arg1)
		local SetY = tonumber(arg2)
		local SetWidth = tonumber(arg3)
		local SetHeight = tonumber(arg4)
		SelfBaoJian_Tips_Update_Other()
		SelfBaoJian_Tips_AdjustPosition(SetX,SetY,SetWidth,SetHeight)
		this:Show()
		return
	end
	
	if event ==  "SELF_FIVEELEMENTS_TIP_CLOSE" and this:IsVisible() then
		this:Hide()
		return
	end
	
	if event ==  "TARGET_FIVEELEMENTS_TIP_CLOSE" and this:IsVisible() then
		this:Hide()
		return
	end
	
end
--=========
--Update UI
--=========
function SelfBaoJian_Tips_Update_Self()
	
	if g_ElementsIndex >= 1 and g_ElementsIndex <= 5 then
		
		SelfBaoJian_Tips_Title:SetText(g_TitleName[ g_ElementsIndex ] )
		SelfBaoJian_Tips_Icon:SetProperty("Image" ,g_ElementsImage[ g_ElementsIndex ]  )
	
		local bElementsActive = Player:IsFiveElements_ElementsActive( g_ElementsIndex - 1 )
		local bElementsType	= Player:GetFiveElements_ElementsType( g_ElementsIndex - 1 )
		local bElementsLevel	= Player:GetFiveElements_ElementsLevel( g_ElementsIndex - 1 )
		
		if bElementsLevel > 0 then
			local strElementsLevel = ScriptGlobal_Format( "#{ZZZB_150811_283}", bElementsLevel)
			SelfBaoJian_Tips_Title1_Text:SetText(strElementsLevel)
			
			if g_ElementsIndex == 3 or g_ElementsIndex == 5 then
				
				local nElementsValue = DataPool:Lua_GetFiveElementsBaseValue( g_ElementsIndex - 1 )
				
				local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_285}", g_ElementsValueName[ g_ElementsIndex ][ 1 ] , nElementsValue )
				SelfBaoJian_Tips_Title1_Text1:SetText(nValueText)

			end
			
			if g_ElementsIndex == 1 or g_ElementsIndex == 2 or g_ElementsIndex == 4 then
				if g_ElementsValueName[ g_ElementsIndex ][ bElementsType ] ~= nil then
					
					local nElementsValue = DataPool:Lua_GetFiveElementsBaseValue( g_ElementsIndex - 1 )
					
					local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_285}", g_ElementsValueName[ g_ElementsIndex ][ bElementsType ] , nElementsValue )
					SelfBaoJian_Tips_Title1_Text1:SetText(nValueText)

				end
			end
	
		else
			local strElementsLevel = ScriptGlobal_Format( "#{ZZZB_150811_283}", "#{ZZZB_150811_332}")
			SelfBaoJian_Tips_Title1_Text:SetText(strElementsLevel)
			SelfBaoJian_Tips_Title1_Text1:SetText("#{ZZZB_150811_300}")
		end
		
		
		local nAllJadeExtend = 0
		
		if bElementsActive == 1 then
			
			for i = 1 , 5 do
					
				local bJadeType = Player:GetFiveElements_JadeType( g_ElementsIndex - 1  , i  - 1)
				
				g_JadeIconCtrl[ i ]:Hide()

				if bJadeType >= 0 and bJadeType < 5 then
					g_JadeAnimateCtrl[ i ]:Show()
					g_JadeAnimateCtrl[ i ]:SetProperty("Animate" , g_JadeAnimate[ bJadeType + 1 ])
					
					local nExtendValue = Player:GetFiveElements_JadeExtend( g_ElementsIndex - 1 ,  bJadeType)
					local strExtendValue = tostring(nExtendValue)
					if nExtendValue >= 0 then
						strExtendValue = "+"..strExtendValue
					end
					
					local jadeStr = ScriptGlobal_Format( g_JadeName[ bJadeType + 1 ], strExtendValue)
					g_JadeText[ i ]:SetText(jadeStr)
					
					nAllJadeExtend = nAllJadeExtend + nExtendValue
				end
		
			end
			
		else
			for i = 1 , 5 do
			
				g_JadeIconCtrl[ i ]:Show()
				g_JadeAnimateCtrl[ i ]:Hide()
				
				g_JadeText[ i ]:SetText("#{ZZZB_150811_133}")
				
			end
		end
		
		if nAllJadeExtend >= 0 then
			nAllJadeExtend = "+"..tostring(nAllJadeExtend)
		end
		local strAllExtend = ScriptGlobal_Format( "#{ZZZB_150811_132}", nAllJadeExtend)
		SelfBaoJian_Tips_Sum:SetText(strAllExtend)
		
	
		local nEquipExtend_1 = DataPool:Lua_GetEquipZhiZunExtend(1)
		local nEquipExtend_2 = DataPool:Lua_GetEquipZhiZunExtend(2)
		
		local nEquipExtendLevel_1 = DataPool:Lua_GetEquipZhiZunExtendLevel(1)
		local nEquipExtendLevel_2 = DataPool:Lua_GetEquipZhiZunExtendLevel(2)
		
		local strEquipExtend =  ScriptGlobal_Format( "#{ZZZB_150811_286}", tostring(nEquipExtend_1 + nEquipExtend_2) )
		SelfBaoJian_Tips_Bk6_Text:SetText(strEquipExtend)
		
		if nEquipExtendLevel_1 > 0 then
			local strEquipExtend_1 =  ScriptGlobal_Format( "#{ZZZB_150811_288}",  nEquipExtendLevel_1 , nEquipExtend_1)	
			SelfBaoJian_Tips_Bk6_Text1:SetText(strEquipExtend_1)
		else
			SelfBaoJian_Tips_Bk6_Text1:SetText("#{ZZZB_150811_287}")
		end
		
		if nEquipExtendLevel_2 > 0 then
			local strEquipExtend_2 =  ScriptGlobal_Format( "#{ZZZB_150811_290}", nEquipExtendLevel_2 , nEquipExtend_2)	
			SelfBaoJian_Tips_Bk6_Text2:SetText(strEquipExtend_2)
		else
			SelfBaoJian_Tips_Bk6_Text2:SetText("#{ZZZB_150811_289}")
		end

	
	else
	
	
	
	end

end

function SelfBaoJian_Tips_Update_Other()
	if g_ElementsIndex >= 1 and g_ElementsIndex <= 5 then
		
		SelfBaoJian_Tips_Title:SetText(g_TitleName[ g_ElementsIndex ] )
		SelfBaoJian_Tips_Icon:SetProperty("Image" ,g_ElementsImage[ g_ElementsIndex ]  )
	
		local bElementsActive = Player:IsOtherFiveElements_ElementsActive( g_ElementsIndex - 1 )
		local bElementsType	= Player:GetOtherFiveElements_ElementsType( g_ElementsIndex - 1 )
		local bElementsLevel	= Player:GetOtherFiveElements_ElementsLevel( g_ElementsIndex - 1 )
		
		if bElementsLevel > 0 then
			local strElementsLevel = ScriptGlobal_Format( "#{ZZZB_150811_283}", bElementsLevel)
			SelfBaoJian_Tips_Title1_Text:SetText(strElementsLevel)
			
			if g_ElementsIndex == 3 or g_ElementsIndex == 5 then
				
				local nElementsValue = DataPool:Lua_GetOtherFiveElementsBaseValue( g_ElementsIndex - 1 )
				
				local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_285}", g_ElementsValueName[ g_ElementsIndex ][ 1 ] , nElementsValue )
				SelfBaoJian_Tips_Title1_Text1:SetText(nValueText)

			end
			
			if g_ElementsIndex == 1 or g_ElementsIndex == 2 or g_ElementsIndex == 4 then
				if g_ElementsValueName[ g_ElementsIndex ][ bElementsType ] ~= nil then
					
					local nElementsValue = DataPool:Lua_GetOtherFiveElementsBaseValue( g_ElementsIndex - 1 )
					
					local nValueText = ScriptGlobal_Format( "#{ZZZB_150811_285}", g_ElementsValueName[ g_ElementsIndex ][ bElementsType ] , nElementsValue )
					SelfBaoJian_Tips_Title1_Text1:SetText(nValueText)

				end
			end
	
		else
			local strElementsLevel = ScriptGlobal_Format( "#{ZZZB_150811_283}", "#{ZZZB_150811_332}")
			SelfBaoJian_Tips_Title1_Text:SetText(strElementsLevel)
			SelfBaoJian_Tips_Title1_Text1:SetText("#{ZZZB_150811_300}")
		end
		
		
		local nAllJadeExtend = 0
		
		if bElementsActive == 1 then
			
			for i = 1 , 5 do
					
				local bJadeType = Player:GetOtherFiveElements_JadeType( g_ElementsIndex - 1  , i  - 1)
				
				g_JadeIconCtrl[ i ]:Hide()

				if bJadeType >= 0 and bJadeType < 5 then
					g_JadeAnimateCtrl[ i ]:Show()
					g_JadeAnimateCtrl[ i ]:SetProperty("Animate" , g_JadeAnimate[ bJadeType + 1 ])
					
					local nExtendValue = Player:GetOtherFiveElements_JadeExtend( g_ElementsIndex - 1 ,  bJadeType)
					local strExtendValue = tostring(nExtendValue)
					if nExtendValue >= 0 then
						strExtendValue = "+"..strExtendValue
					end
					
					local jadeStr = ScriptGlobal_Format( g_JadeName[ bJadeType + 1 ], strExtendValue)
					g_JadeText[ i ]:SetText(jadeStr)
					
					nAllJadeExtend = nAllJadeExtend + nExtendValue
				end
		
			end
			
		else
			for i = 1 , 5 do
			
				g_JadeIconCtrl[ i ]:Show()
				g_JadeAnimateCtrl[ i ]:Hide()
				
				g_JadeText[ i ]:SetText("#{ZZZB_150811_133}")
				
			end
		end
		
		if nAllJadeExtend >= 0 then
			nAllJadeExtend = "+"..tostring(nAllJadeExtend)
		end
		local strAllExtend = ScriptGlobal_Format( "#{ZZZB_150811_132}", nAllJadeExtend)
		SelfBaoJian_Tips_Sum:SetText(strAllExtend)
		
	
		local nEquipExtend_1 = DataPool:Lua_GetOtherEquipZhiZunExtend(1)
		local nEquipExtend_2 = DataPool:Lua_GetOtherEquipZhiZunExtend(2)
		
		local nEquipExtendLevel_1 = DataPool:Lua_GetOtherEquipZhiZunExtendLevel(1)
		local nEquipExtendLevel_2 = DataPool:Lua_GetOtherEquipZhiZunExtendLevel(2)
		
		local strEquipExtend =  ScriptGlobal_Format( "#{ZZZB_150811_286}", tostring(nEquipExtend_1 + nEquipExtend_2) )
		SelfBaoJian_Tips_Bk6_Text:SetText(strEquipExtend)
		
		if nEquipExtendLevel_1 > 0 then
			local strEquipExtend_1 =  ScriptGlobal_Format( "#{ZZZB_150811_288}",  nEquipExtendLevel_1 , nEquipExtend_1)	
			SelfBaoJian_Tips_Bk6_Text1:SetText(strEquipExtend_1)
		else
			SelfBaoJian_Tips_Bk6_Text1:SetText("#{ZZZB_150811_287}")
		end
		
		if nEquipExtendLevel_2 > 0 then
			local strEquipExtend_2 =  ScriptGlobal_Format( "#{ZZZB_150811_290}", nEquipExtendLevel_2 , nEquipExtend_2)	
			SelfBaoJian_Tips_Bk6_Text2:SetText(strEquipExtend_2)
		else
			SelfBaoJian_Tips_Bk6_Text2:SetText("#{ZZZB_150811_289}")
		end

	
	else
	
	
	
	end

end


--自动设置Tips位置
function SelfBaoJian_Tips_AdjustPosition(SetX,SetY,SetWidth,SetHeight)
	
	local TipsWidth = SelfBaoJian_Tips_Frame:GetProperty("AbsoluteWidth")
	local TipsHeight = SelfBaoJian_Tips_Frame:GetProperty("AbsoluteHeight")
	local ScreenWidth ,ScreenHeight = GetCurClientSize()
	
	if(SetX + SetWidth + TipsWidth > ScreenWidth) then
		SelfBaoJian_Tips_Frame:SetProperty("AbsoluteXPosition",SetX - TipsWidth)
	else
		SelfBaoJian_Tips_Frame:SetProperty("AbsoluteXPosition",SetX + SetWidth)
	end
	
	if(SetY + SetHeight + TipsHeight > ScreenHeight) then
		SelfBaoJian_Tips_Frame:SetProperty("AbsoluteYPosition",SetY - TipsHeight)
	else
		SelfBaoJian_Tips_Frame:SetProperty("AbsoluteYPosition",SetY + SetHeight)
	end
	
end

