--SpringFestival_Confirm.lua
local g_Frame_UnifiedPosition
local g_Text = ""
local g_Text2 = ""

-- 语云水（琵琶）、渺翠微（二胡）、闻折柳（笛子）、聆碧波（古筝）、惊风雷（大鼓）
-- local g_JinNang = {
	-- [1] = "#{SYCY_201225_140}",
	-- [2] = "#{SYCY_201225_141}",
	-- [3] = "#{SYCY_201225_142}",
	-- [4] = "#{SYCY_201225_143}",
	-- --[5] = "#{SYCY_201225_139}",
	-- [5] = "#{SYCY_201225_135}",
	-- [6] = "#{SYCY_201225_136}",
	-- [7] = "#{SYCY_201225_137}",
	-- [8] = "#{SYCY_201225_138}",
	-- --[10] = "#{SYCY_201225_144}",
	-- [9] = "#{SYCY_201225_155}",
	-- [10] = "#{SYCY_201225_156}",
	-- [11] = "#{SYCY_201225_157}",
	-- [12] = "#{SYCY_201225_158}",
	-- --[15] = "#{SYCY_201225_149}",
	-- [13] = "#{SYCY_201225_145}",
	-- [14] = "#{SYCY_201225_146}",
	-- [15] = "#{SYCY_201225_147}",
	-- [16] = "#{SYCY_201225_148}",
	-- --[20] = "#{SYCY_201225_154}",
	-- [17] = "#{SYCY_201225_150}",
	-- [18] = "#{SYCY_201225_151}",
	-- [19] = "#{SYCY_201225_152}",
	-- [20] = "#{SYCY_201225_153}",
	-- --[25] = "#{SYCY_201225_159}",
	
-- }

local g_JinNang = {
	[1] = {itemid = 38005150, name = "#{SYCY_201225_249}", question = "#{SYCY_201225_250}", address = "#{SYCY_201225_251}", explain = "#{SYCY_201225_252}", tips = "#{SYCY_201225_253}"},
	[2] = {itemid = 38005151, name = "#{SYCY_201225_254}", question = "#{SYCY_201225_255}", address = "#{SYCY_201225_256}", explain = "#{SYCY_201225_257}", tips = "#{SYCY_201225_258}"},
	[3] = {itemid = 38005152, name = "#{SYCY_201225_259}", question = "#{SYCY_201225_260}", address = "#{SYCY_201225_261}", explain = "#{SYCY_201225_262}", tips = "#{SYCY_201225_263}"},
	[4] = {itemid = 38005153, name = "#{SYCY_201225_264}", question = "#{SYCY_201225_265}", address = "#{SYCY_201225_266}", explain = "#{SYCY_201225_267}", tips = "#{SYCY_201225_238}"},
	--[5] = "#{SYCY_201225_139}",
	[5] = {itemid = 38005145, name = "#{SYCY_201225_229}", question = "#{SYCY_201225_230}", address = "#{SYCY_201225_231}", explain = "#{SYCY_201225_232}", tips = "#{SYCY_201225_233}"},
	[6] = {itemid = 38005146, name = "#{SYCY_201225_234}", question = "#{SYCY_201225_235}", address = "#{SYCY_201225_236}", explain = "#{SYCY_201225_237}", tips = "#{SYCY_201225_238}"},
	[7] = {itemid = 38005147, name = "#{SYCY_201225_239}", question = "#{SYCY_201225_240}", address = "#{SYCY_201225_241}", explain = "#{SYCY_201225_242}", tips = "#{SYCY_201225_243}"},
	[8] = {itemid = 38005148, name = "#{SYCY_201225_244}", question = "#{SYCY_201225_245}", address = "#{SYCY_201225_246}", explain = "#{SYCY_201225_247}", tips = "#{SYCY_201225_248}"},
	--[10] = "#{SYCY_201225_144}",
	[9] = {itemid = 38005149, name = "#{SYCY_201225_309}", question = "#{SYCY_201225_310}", address = "#{SYCY_201225_311}", explain = "#{SYCY_201225_312}", tips = "#{SYCY_201225_313}"},
	[10] = {itemid = 38005154, name = "#{SYCY_201225_314}", question = "#{SYCY_201225_315}", address = "#{SYCY_201225_316}", explain = "#{SYCY_201225_317}", tips = "#{SYCY_201225_318}"},
	[11] = {itemid = 38005159, name = "#{SYCY_201225_319}", question = "#{SYCY_201225_320}", address = "#{SYCY_201225_321}", explain = "#{SYCY_201225_322}", tips = "#{SYCY_201225_323}"},
	[12] = {itemid = 38005164, name = "#{SYCY_201225_324}", question = "#{SYCY_201225_325}", address = "#{SYCY_201225_326}", explain = "#{SYCY_201225_327}", tips = "#{SYCY_201225_328}"},
	--[15] = "#{SYCY_201225_149}",
	[13] = {itemid = 38005155, name = "#{SYCY_201225_269}", question = "#{SYCY_201225_270}", address = "#{SYCY_201225_271}", explain = "#{SYCY_201225_272}", tips = "#{SYCY_201225_273}"},
	[14] = {itemid = 38005156, name = "#{SYCY_201225_274}", question = "#{SYCY_201225_275}", address = "#{SYCY_201225_276}", explain = "#{SYCY_201225_277}", tips = "#{SYCY_201225_278}"},
	[15] = {itemid = 38005157, name = "#{SYCY_201225_279}", question = "#{SYCY_201225_280}", address = "#{SYCY_201225_281}", explain = "#{SYCY_201225_282}", tips = "#{SYCY_201225_283}"},
	[16] = {itemid = 38005158, name = "#{SYCY_201225_284}", question = "#{SYCY_201225_285}", address = "#{SYCY_201225_286}", explain = "#{SYCY_201225_287}", tips = "#{SYCY_201225_288}"},
	--[20] = "#{SYCY_201225_154}",
	[17] = {itemid = 38005160, name = "#{SYCY_201225_289}", question = "#{SYCY_201225_290}", address = "#{SYCY_201225_291}", explain = "#{SYCY_201225_292}", tips = "#{SYCY_201225_293}"},
	[18] = {itemid = 38005161, name = "#{SYCY_201225_294}", question = "#{SYCY_201225_295}", address = "#{SYCY_201225_296}", explain = "#{SYCY_201225_297}", tips = "#{SYCY_201225_298}"},
	[19] = {itemid = 38005162, name = "#{SYCY_201225_299}", question = "#{SYCY_201225_300}", address = "#{SYCY_201225_301}", explain = "#{SYCY_201225_302}", tips = "#{SYCY_201225_303}"},
	[20] = {itemid = 38005163, name = "#{SYCY_201225_304}", question = "#{SYCY_201225_305}", address = "#{SYCY_201225_306}", explain = "#{SYCY_201225_307}", tips = "#{SYCY_201225_308}"},
	--[25] = "#{SYCY_201225_159}",
	
}


local g_WenXinYinQuest = {
	[1] = "#{SYCY_201225_198}",
	[2] = "#{SYCY_201225_199}",
	[3] = "#{SYCY_201225_200}",
	[4] = "#{SYCY_201225_201}",
	[5] = "#{SYCY_201225_202}",
}

local g_BingLiJieNPC = {
	[1] = "#{SYCY_201225_203}",
	[2] = "#{SYCY_201225_204}",
	[3] = "#{SYCY_201225_205}",
	[4] = "#{SYCY_201225_206}",
	[5] = "#{SYCY_201225_207}",
}

local g_WanLiStr = {
	[1] = "#{SYCY_201225_208}",
	[2] = "#{SYCY_201225_209}",
	[3] = "#{SYCY_201225_210}",
	[4] = "#{SYCY_201225_211}",
	--[5] = "#{SYCY_201225_114}",
	[5] = "#{SYCY_201225_212}",
	[6] = "#{SYCY_201225_213}",
	[7] = "#{SYCY_201225_214}",
	[8] = "#{SYCY_201225_215}",
	--[10] = "#{SYCY_201225_119}",
	[9] = "#{SYCY_201225_216}",
	[10] = "#{SYCY_201225_217}",
	[11] = "#{SYCY_201225_218}",
	[12] = "#{SYCY_201225_219}",
	--[15] = "#{SYCY_201225_124}",
	[13] = "#{SYCY_201225_220}",
	[14] = "#{SYCY_201225_221}",
	[15] = "#{SYCY_201225_222}",
	[16] = "#{SYCY_201225_223}",
	--[20] = "#{SYCY_201225_129}",
	[17] = "#{SYCY_201225_224}",
	[18] = "#{SYCY_201225_225}",
	[19] = "#{SYCY_201225_226}",
	[20] = "#{SYCY_201225_227}",
	--[25] = "#{SYCY_201225_134}",
}

local g_WanLiItem = {
	[1] = 38005155,
	[2] = 38005156,
	[3] = 38005157,
	[4] = 38005158,
	--[5] = 38005149,
	[5] = 38005150,
	[6] = 38005151,
	[7] = 38005152,
	[8] = 38005153,
	--[10] = 38005154,
	[9] = 38005145,
	[10] = 38005146,
	[11] = 38005147,
	[12] = 38005148,
	--[15] = 38005159,
	[13] = 38005160,
	[14] = 38005161,
	[15] = 38005162,
	[16] = 38005163,
	--[20] = 38005164,
	[17] = 38005149,
	[18] = 38005154,
	[19] = 38005159,
	[20] = 38005164,
--[25] = 38005169,
}

local g_Title = {
	[1] = "set:Spring33  image:MiQingYin_Wenxin_Word",
	[2] = "set:Spring33  image:MiQingYin_Xiangxue_Word",
	[3] = "set:Spring33  image:MiQingYin_Xunhui_Word",
}

local g_Explain = {
	[1] = "#{SYCY_201225_329}",
	[2] = "#{SYCY_201225_330}",
	[3] = "#{SYCY_201225_331}",
}
--=========
-- PreLoad()
--=========
function SpringFestival_Confirm_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function SpringFestival_Confirm_OnLoad()
	
	g_Frame_UnifiedPosition = SpringFestival_Confirm_Frame:GetProperty("UnifiedPosition")
	local from_to_info = "curve:Liner mode:Once duration:1 startx:1 starty:0 endx:0 endy:0"
	SpringFestival_Confirm_Cloud1:Tween_SetInfo("Alpha", from_to_info)
	--SpringFestival_Confirm_CloudRight:Tween_SetInfo("Alpha", from_to_info)
	SpringFestival_Confirm_Text:SetText("")
	SpringFestival_Confirm_InfoBK1:Hide()

end

--=========
-- Event
--=========
function SpringFestival_Confirm_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 88833406) then
	
		local nJinNangIndex = Get_XParam_INT(0)
	
		SpringFestival_Confirm_OpenJinNang(nJinNangIndex)
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 88833404) then
	
		local nSYCY_NOW_STAGE = Get_XParam_INT(0) -- 当前进度
		local nSYCY_NOW_STAGE_STATE = Get_XParam_INT(1) -- 当前进度完成度
		local nTalkMessageId = Get_XParam_INT(2)
		local nTalkNpcId = Get_XParam_INT(3)
		local nNeedItemId = Get_XParam_INT(4)
		local nXinJing = Get_XParam_INT(5)
	
		SpringFestival_Confirm_OpenXinJing(nSYCY_NOW_STAGE, nSYCY_NOW_STAGE_STATE, nTalkMessageId, nTalkNpcId, nNeedItemId, nXinJing)
				
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		SpringFestival_Confirm_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_Confirm_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		SpringFestival_Confirm_On_ResetPos()

	end
end


function SpringFestival_Confirm_Close()
	
	this:Hide()
end

--=========
-- 重置
--=========
function SpringFestival_Confirm_On_ResetPos()
	
	SpringFestival_Confirm_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end

--=========
-- 打开锦囊
--=========
function SpringFestival_Confirm_OpenJinNang(index)
	SpringFestival_Confirm_Client2:Show()
	SpringFestival_Confirm_Client1:Hide()
	SpringFestival_Confirm_Button:Hide()
	SpringFestival_Confirm_Animate:Play(false)
	SpringFestival_Confirm_Cloud1:Hide()
	
	SpringFestival_Confirm_JingNang_Icon:SetActionItem(-1)
	local theAction = DataPool:CreateActionItemForShow(g_JinNang[index].itemid, 1)
	if theAction:GetID() ~= 0 then
		SpringFestival_Confirm_JingNang_Icon:SetActionItem(theAction:GetID());
		SpringFestival_Confirm_JingNang_Icon:Show();
	end
	--SpringFestival_Confirm_CloudRight:Hide()
	--SpringFestival_Confirm_Frame_Title:SetText("#{SYCY_201225_20}")
	SpringFestival_Confirm_TitleName:SetProperty("Image", "set:Spring33  image:MiQingYin_Jingnang_Word")
	SpringFestival_Confirm_NameText:SetText(g_JinNang[index].name)
	SpringFestival_Confirm_JingNang_InfoText:SetText(g_JinNang[index].question)
	SpringFestival_Confirm_SellText:SetText(g_JinNang[index].address)
	SpringFestival_Confirm_ExplainText:SetText(g_JinNang[index].explain)
	SpringFestival_Confirm_InfoText2:SetText(g_JinNang[index].tips)
	
	this:Show()
	
end	

--=========
-- 打开心境
--=========
function SpringFestival_Confirm_OpenXinJing(nSYCY_NOW_STAGE, nSYCY_NOW_STAGE_STATE, nTalkMessageId, nTalkNpcId, nNeedItemId, nXinJing)
	
	SpringFestival_Confirm_Client2:Hide()
	SpringFestival_Confirm_Client1:Show()
	SpringFestival_Confirm_Button:Hide()
	SpringFestival_Confirm_Animate:Play(false)
	SpringFestival_Confirm_Cloud1:Hide()
	--SpringFestival_Confirm_CloudRight:Hide()
	--SpringFestival_Confirm_Frame_Title:SetText("#{SYCY_201225_21}")
	SpringFestival_Confirm_TitleName:SetProperty("Image", g_Title[nSYCY_NOW_STAGE])
	SpringFestival_Confirm_Text:SetText("")
	SpringFestival_Confirm_InfoBK1:Hide()
	if nXinJing == 0 then
		SpringFestival_Confirm_Button:Show()
		SpringFestival_Confirm_Cloud1:Show()
		--SpringFestival_Confirm_CloudRight:Show()
		SpringFestival_Confirm_Cloud1:Tween_Reset("Alpha", true)
		--SpringFestival_Confirm_CloudRight:Tween_Reset("Alpha", true)
	end
	if nSYCY_NOW_STAGE == 1 then
		--SpringFestival_Confirm_Text:SetText(g_WenXinYinQuest[nTalkMessageId])
		g_Text = g_WenXinYinQuest[nTalkMessageId]
	elseif nSYCY_NOW_STAGE == 2 then
		--SpringFestival_Confirm_Text:SetText(g_BingLiJieNPC[nTalkNpcId])
		g_Text = g_BingLiJieNPC[nTalkNpcId]
	elseif nSYCY_NOW_STAGE == 3 then
		--SpringFestival_Confirm_Text:SetText(g_WanLiStr[nNeedItemId])
		g_Text = g_WanLiStr[nNeedItemId]
	end
	g_Text2 = g_Explain[nSYCY_NOW_STAGE]
	this:Show()
	
end	


--=========
-- 
--=========
function SpringFestival_Confirm_Click(  )
	SpringFestival_Confirm_Button:Hide()
	--SpringFestival_Confirm_Animate:Play(true)
	SpringFestival_Confirm_Cloud1:Tween_Play("Alpha", true, true)
	--SpringFestival_Confirm_CloudRight:Tween_Play("Alpha", true, true)
	SetTimer("SpringFestival_Confirm","SpringFestival_Confirm_Timer()", 1*1000)
	
end

--=========
-- help
--=========
function SpringFestival_Confirm_HelpClick(  )
	
end

function SpringFestival_Confirm_Timer()
	
	SpringFestival_Confirm_Text:SetText(g_Text)
	SpringFestival_Confirm_InfoText1:SetText(g_Text2)
	SpringFestival_Confirm_InfoBK1:Show()
	KillTimer("SpringFestival_Confirm_Timer()")
		
	
end
	
