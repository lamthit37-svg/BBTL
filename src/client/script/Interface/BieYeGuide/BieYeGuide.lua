
g_tabs = {}
g_sub_titles = {}
g_sub_details = {}
g_sub_images = {}
g_current = 1
g_clientNpcId= -1

g_datas = {
	{
		{"#{JYGZ_160809_288}","","#{JYGZ_160809_289}"},
		{"#{JYGZ_160809_290}","","#{JYGZ_160809_291}"},
		{"#{JYGZ_160809_292}","","#{JYGZ_160809_293}"},
		{"#{JYGZ_160809_294}","","#{JYGZ_160809_295}"},
		{"#{JYGZ_160809_296}","","#{JYGZ_160809_297}"},
		{"#{JYGZ_160809_298}","","#{JYGZ_160809_299}"},
	},
	{
		{"#{JYGZ_160809_302}","","#{JYGZ_160809_303}"},
		{"#{JYGZ_160809_304}","","#{JYGZ_160809_305}"},
		{"#{JYGZ_160809_306}","","#{JYGZ_160809_307}"},
		{"#{JYGZ_160809_308}","","#{JYGZ_160809_309}"},
		{"#{JYGZ_160809_310}","","#{JYGZ_160809_311}"},
		{"#{JYGZ_160809_312}","","#{JYGZ_160809_313}"},
	},
	{
		{"#{JYGZ_160809_314}","","#{JYGZ_160809_315}"},
		{"#{JYGZ_160809_316}","","#{JYGZ_160809_317}"},
		{"#{JYGZ_160809_318}","","#{JYGZ_160809_319}"},
		{"#{JYGZ_160809_320}","","#{JYGZ_160809_321}"},
		{"#{JYGZ_160809_322}","","#{JYGZ_160809_323}"},
		{"#{JYGZ_160809_324}","","#{JYGZ_160809_325}"},
	},
	{
		{"#{JYGZ_160809_326}","","#{JYGZ_160809_327}"},
		{"#{JYGZ_160809_328}","","#{JYGZ_160809_329}"},
		{"#{JYGZ_160809_330}","","#{JYGZ_160809_331}"},
		{"#{JYGZ_160809_332}","","#{JYGZ_160809_333}"},
		{"#{JYGZ_160809_334}","","#{JYGZ_160809_335}"},
		{"#{JYGZ_160809_336}","","#{JYGZ_160809_337}"},
	},
	{
		{"#{JYGZ_160809_350}","","#{JYGZ_160809_351}"},
		{"#{JYGZ_160809_352}","","#{JYGZ_160809_353}"},
		{"#{JYGZ_160809_354}","","#{JYGZ_160809_355}"},
		{"#{JYGZ_160809_356}","","#{JYGZ_160809_357}"},
		{"#{JYGZ_160809_358}","","#{JYGZ_160809_359}"},
		{"#{JYGZ_160809_360}","","#{JYGZ_160809_361}"},
	},
	{
		{"#{JYGZ_160809_338}","","#{JYGZ_160809_339}"},
		{"#{JYGZ_160809_340}","","#{JYGZ_160809_341}"},
		{"#{JYGZ_160809_342}","","#{JYGZ_160809_343}"},
		{"#{JYGZ_160809_344}","","#{JYGZ_160809_345}"},
		{"#{JYGZ_160809_346}","","#{JYGZ_160809_347}"},
		{"#{JYGZ_160809_348}","","#{JYGZ_160809_349}"},
	},
	{
		{"#{JYGZ_171114_02}","","#{JYGZ_171114_03}"},
		{"#{JYGZ_171114_04}","","#{JYGZ_171114_05}"},
		{"#{JYGZ_171114_06}","","#{JYGZ_171114_07}"},
		{"#{JYGZ_171114_08}","","#{JYGZ_171114_09}"},
		{"#{JYGZ_171114_10}","","#{JYGZ_171114_11}"},
		{"#{JYGZ_171114_12}","","#{JYGZ_171114_13}"},
	},
}

function BieYeGuide_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ON_SCENE_TRANS")
end

function BieYeGuide_OnLoad()
	for i=1,7 do
		g_tabs[i] = _G["BieYeGuide_Toplist_Fenye"..i]
	end
	for i=1,7 do
		g_sub_titles[i] = _G[string.format("BieYeGuide_GuideFrame_Clinet%d_info",i)]
		g_sub_details[i] = _G[string.format("BieYeGuide_GuideFrame_Clinet%d_text",i)]
		g_sub_images[i] = _G[string.format("BieYeGuide_GuideFrame_Clinet%d_PRE_image",i)]
	end
end

function BieYeGuide_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 89187203 then
		g_clientNpcId = DataPool:GetNPCIDByServerID(Get_XParam_INT(0))
		BieYeGuide_Show()
	elseif event == "ON_SCENE_TRANS" then
		BieYeGuide_OnHide()
	end
end

function BieYeGuide_Show()
	this:CareObject( g_clientNpcId, 1, "BieYeGuide" )
	this:Show()
	BieYeGuide_Update()
end

function BieYeGuide_OnHide()
	this:CareObject( g_clientNpcId, 0, "BieYeGuide" )
	g_clientNpcId = -1
	g_current = 1
	this:Hide()
	if DataPool:Lua_IsHaveMission(1856) <= 0 and DataPool:Lua_IsMissionHaveDone(1856) <= 0 then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowJiaYuanYinDaoMission" )
		Set_XSCRIPT_ScriptID( 892365 )
		Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end

function BieYeGuide_PageUp()
	if g_current > 1 then
		g_current = g_current - 1
		BieYeGuide_Update()
	end
end

function BieYeGuide_PageDown()
	if g_current < table.getn(g_tabs) then
		g_current = g_current + 1
		BieYeGuide_Update()
	end
end

function BieYeGuide_Update()
	if g_current == 1 then
		BieYeGuide_PrePage:Disable();
	else
		BieYeGuide_PrePage:Enable();
	end
	if g_current == table.getn(g_tabs) then
		BieYeGuide_NextPage:Disable();
	else
		BieYeGuide_NextPage:Enable();
	end
	for i,tab in ipairs(g_tabs) do
		if i == g_current then
			tab:SetCheck(1)
		else
			tab:SetCheck(0)
		end
	end
	for i = 1, table.getn(g_sub_titles) do
		g_sub_titles[i]:SetText( g_datas[g_current][i][1]  )
		g_sub_details[i]:SetText( g_datas[g_current][i][3]  )
		local nImageI = g_current
		if g_current == 6 or g_current == 5 then
			nImageI = 11 - g_current
		end
		local setIdx = math.floor((nImageI-1)/2)+1
		local imgIdx = i + math.mod( nImageI - 1, 2 ) * 6
		g_sub_images[i]:SetProperty("Image", string.format( "set:BieYeGuide%02d image:BieYeGuide%02d_%d", setIdx, setIdx, imgIdx ) );
	end
end

function BieYeGuide_Switch(n)
	if n < 1 or n > table.getn(g_tabs) then
		return
	end
	g_current = n
	BieYeGuide_Update()
end
