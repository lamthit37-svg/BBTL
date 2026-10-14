-- 2020q4汴京氛围主界面

local g_Frame_UnifiedPosition
local g_BJFW_ClueMF = {
	3041,        --汴京氛围线索1
	3042,        --汴京氛围线索2
	3043,        --汴京氛围线索3
	3044,        --汴京氛围线索4
	3045,        --汴京氛围线索5
	3046,        --汴京氛围线索6
	3047,        --汴京氛围线索7
	3048,        --汴京氛围线索8
	3049,        --汴京氛围线索9
	3050,        --汴京氛围线索10
	3051,        --汴京氛围线索11
	3052,        --汴京氛围线索12
	3053,        --汴京氛围线索13
	3054,        --汴京氛围线索14
	3055,        --汴京氛围线索15
	3056,        --汴京氛围线索16
	3057,        --汴京氛围线索17
	3058,        --汴京氛围线索18
}
local g_BJFW_ClueImag={}
--=========
-- PreLoad
--=========
function SpringFestival_BianJing_clue_PreLoad()
	
	this:RegisterEvent("BJFW_CLUEUI", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad
--=========
function SpringFestival_BianJing_clue_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_BianJing_clue_Frame:GetProperty("UnifiedPosition") 
	g_BJFW_ClueImag = {
		"set:Springnew25 image:LinLang_Title_Shiguahua",
		"set:Springnew25 image:LinLang_Title_Fanghuayou",
		"set:Springnew25 image:LinLang_Title_Shangqianshan",
		"set:Springnew25 image:LinLang_Title_Yuluxiang",
		"set:Springnew25 image:LinLang_Title_Jixiangcai",
		"set:Springnew25 image:LinLang_Title_Zenglongxian",
		"set:Springnew25 image:LinLang_Title_Guanchuncha",
		"set:Springnew25 image:LinLang_Title_Caixianye",
		"set:Springnew25 image:LinLang_Title_Pinxinming",
		"set:Springnew25 image:LinLang_Title_Wenchunhua",
		"set:Springnew25 image:LinLang_Title_Xunxianhui",
		"set:Springnew25 image:LinLang_Title_Shangchunshi",
		"set:Springnew25 image:LinLang_Title_Dianzhenqi",
		"set:Springnew25 image:LinLang_Title_Chuanqingyin",
		"set:Springnew25 image:LinLang_Title_Huiyizhai",
		"set:Springnew25 image:LinLang_Title_Zhenghexing",
	}
end

--=========
-- OnEvent
--=========
function SpringFestival_BianJing_clue_OnEvent(event)

	if event == "BJFW_CLUEUI" then

		SpringFestival_BianJing_clue_Update(tonumber(arg0))
		this:Show()
		this:Activate()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_BianJing_clue_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival_BianJing_clue_On_ResetPos()

	end

end

function SpringFestival_BianJing_clue_Update(nClueIdx)
	if g_BJFW_ClueMF[nClueIdx]==nil then
		return
	end
	SpringFestival_BianJing_clue_ClueName:SetProperty("Image", g_BJFW_ClueImag[nClueIdx] )
	if Pneuma:GetMF(g_BJFW_ClueMF[nClueIdx])==1 then
		local arrStr={"#{BJFW_210105_20}","#{BJFW_210105_212}","#{BJFW_210105_213}","#{BJFW_210105_214}",
									"#{BJFW_210105_215}","#{BJFW_210105_216}","#{BJFW_210105_217}","#{BJFW_210105_218}",
									"#{BJFW_210105_219}","#{BJFW_210105_220}","#{BJFW_210105_221}","#{BJFW_210105_222}",
									"#{BJFW_210105_223}","#{BJFW_210105_224}","#{BJFW_210105_225}","#{BJFW_210105_226}",
									}
		SpringFestival_BianJing_clue_Text:SetText(arrStr[nClueIdx])
	else
		local arrStr={"#{BJFW_210105_19}","#{BJFW_210105_171}","#{BJFW_210105_172}","#{BJFW_210105_173}",
									"#{BJFW_210105_174}","#{BJFW_210105_175}","#{BJFW_210105_176}","#{BJFW_210105_177}",
									"#{BJFW_210105_178}","#{BJFW_210105_179}","#{BJFW_210105_180}","#{BJFW_210105_181}",
									"#{BJFW_210105_182}","#{BJFW_210105_183}","#{BJFW_210105_184}","#{BJFW_210105_185}",
									}
		SpringFestival_BianJing_clue_Text:SetText(arrStr[nClueIdx])
	end
end
--=========
-- 重置
--=========
function SpringFestival_BianJing_clue_On_ResetPos()

	SpringFestival_BianJing_clue_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 关闭
--=========
function SpringFestival_BianJing_clue_CloseClicked()

	SpringFestival_BianJing_clue_OnHidden()
	this:Hide()
	
end

--=========
-- 隐藏
--=========
function SpringFestival_BianJing_clue_OnHidden()

end



