
--新宝石摘除 KK
local g_SplitGemEx_CareObj = -1
local g_SplitGemEx_Frame_UnifiedPosition
local g_SplitGemEx_Equip_ID = -1
local g_SplitGemEx_Equip_pos = -1
local g_SplitGemEx_Material_ID = -1
local g_SplitGemEx_Material_pos = -1
local g_SplitGemEx_Gems
local g_SplitGemEx_Selected = -1
local g_SplitGemEx_YuanbaoPay = 1
g_SplitGemEx_Material_Buy = -1
local g_SplitGemEx_npcSid = -1
local g_SplitGemEx_MatTab = {
	[1]=30900037,
	[2]=30900037,
	[3]=30900038,
	[4]=30900039,
	[5]=30900040,
	[6]=30900041,
	[7]=30900042,
	[8]=30900043,
	[9]=30900044,
}

-- 所有神器都可以打四孔 by lishilong 2016-8-23
local EQUIP_SHENQI_BEGIN = 10300000
local EQUIP_SHENQI_END = 10399999

--four hole 80~90equip
local g_SplitGemEx_four_80_ID = {
	10200018,10201018,10202018,10203018,10204018,10205018,10210018,10210038,10210058,10211018,
	10211038,10211058,10212018,10212038,10212058,10213018,10213038,10213058,10214018,10215018,
	10220019,10221019,10222019,10222033,10222034,10223019,10223033,10223034,10300004,10300006,
	10301000,10301198,10302004,10302006,10302008,10302010,10303000,10304004,10304006,10304008,
	10305004,10305006,10305008,10410025,10410033,10414841,10414842,10414843,10414844,10414851,
	10414852,10414853,10414854,10414861,10414862,10414863,10414864,10415841,10415842,10415843,
	10415844,10415851,10415852,10415853,10415854,10415861,10415862,10415863,10415864,10421841,
	10421842,10421843,10421844,10421851,10421852,10421853,10421854,10421861,10421862,10421863,
	10421864,10510017,10510047,10510077,10511007,10511037,10511067,10511117,10512017,10512047,
	10512077,10514007,10514017,10514037,10514047,10514067,10514077,10514117,10515027,10515057,
	10515087,10520027,10520057,10520087,10521007,10521017,10521027,10521037,10521047,10521057,
	10521067,10521077,10521087,10521117,10522007,10522037,10522067,10522117,10523017,10523047,
	10523077,10552027,10552057,10552087,10553007,10553027,10553037,10553057,10553067,10553087,
	10553117,10400075,10402075,10404072,10405071,10412081,10412083,10413084,10413086,10422122,
	10422124,10423047,10423049,10510092,10510093,10510094,10510095,10511094,10511095,10512090,
	10512091,10514101,10514102,10514103,10514104,10522099,10522100,10523099,10523100,10510120,
	10510121,10510122,10510123,10511120,10511121,10511122,10511123,10512120,10512121,10512122,
	10512123,10522120,10522121,10522122,10522123,10523120,10523121,10523122,10523123,
	10510137,10512137,10514137,10521137,10523137,		--唐门新增装备
	10510147,10512147,10514157,10521157,10523157,		--鬼谷新增装备
	10510152,10512152,10514172,10521172,10523172,		--桃花岛新增装备
	10510156,10512156,10514177,10521177,10523178,		--menpai14
	10510160,10512160,10514182,10521182,10523184,
}
--four hole 90+ equip
local g_SplitGemEx_four_ID = {

	10514091,10514092,10514093,10514094,10514095,10514096,10514097,10514098,10515090,10515091,
	10515092,10515093,10515094,10515095,10515096,10515097,10515098,10521090,10521091,10521092,
	10521093,10521094,10521095,10521096,10521097,10521098,10522090,10522091,10522092,10522093,
	10522094,10522095,10522096,10522097,10522098,10523090,10523091,10523092,10523093,10523094,
	10523095,10523096,10523097,10523098,10514090,
	-- 褚少微，2008.6.12。添加102神器极限打孔
	10300100,10300101,10300102, 10301100,10301101,10301102, 10301200,10301201,10301202,
	10302100,10302101,10302102, 10303100,10303101,10303102, 10303200,10303201,10303202,
	10304100,10304101,10304102, 10305100,10305101,10305102, 10305200,10305201,10305202,
	10422016,10423024,10422149,	10422150,
	--胡凯，2008.8.29。旧100套（五件套）及新96套开放极限打孔
	10510009,10510019,10510029,10510039,10510049,10510059,10510069,10510079,10510089,10511009,
	10511019,10511029,10511039,10511049,10511059,10511069,10511079,10511089,10512009,10512019,
	10512029,10512039,10512049,10512059,10512069,10512079,10512089,10513009,10513019,10513029,
	10513039,10513049,10513059,10513069,10513079,10513089,10511096,10512092,10520092,10522101,
	10523101,10511097,10512093,10520093,10522102,10523102,10511098,10512094,10520094,10522103,
	10523103,10511099,10512095,10520095,10522104,10523104,
	--胡凯，2008.9.18。90级以上（含90）生活技能产出的戒指，护符，肩开放极限打孔
	10215020,10222020,10223020,10222035,10222036,10223035,10223036,
	--胡凯，2008.11.11。90级以上（含90）手工装备开放极限打孔（鞋，腰带，护腕，手套，头盔，武器，护甲，项链）
	10200019,10200020,10201019,10201020,10202019,10202020,10203019,10203020,10204019,10204020,
	10205019,10205020,10210020,10210040,10210060,10213020,10213040,10213060,10212020,10212040,
	10212060,10211020,10211040,10211060,10214020,10221020,10220020,
	--zchw，2008-11-17  TT：41140 90门派套，92级神器开放第四孔
	10510008,10510038,10510068,
	10511018,10511028,10511048,10511058,10511078,10511088,10512008,10512038,
	10512068,10513008,10513018,10513028,10513038,10513048,10513058,10513068,
	10513078,10513088,10514028,10514058,10514088,10520018,10520028,10520048,
	10520058,10520078,10520088,10521028,10521058,10521088,10522018,10522048,
	10522078,10552008,10552038,10552068,10553008,10553018,10553038,10553048,
	10553068,10553078,
	--zchw 2008-11-26 TT：41771
	10410026, 10410027, 10410034, 10410035, 10423025, 10423026,
	--houzhifang 2008-12-22: dark
	10150001,10150002,
	10300005,10302005,10304005,10305005,
	--likun 2009-8-18
	10300103,10300104,10300105,10300106,10300107,10300108,10300109,10300110,10300111,10301103,
	10301104,10301105,10301106,10301107,10301108,10301109,10301110,10301111,10301203,10301204,
	10301205,10301206,10301207,10301208,10301209,10301210,10301211,10302103,10302104,10302105,
	10302106,10302107,10302108,10302109,10302110,10302111,10303103,10303104,10303105,10303106,
	10303107,10303108,10303109,10303110,10303111,10303203,10303204,10303205,10303206,10303207,
	10303208,10303209,10303210,10303211,10304103,10304104,10304105,10304106,10304107,10304108,
	10304109,10304110,10304111,10305103,10305104,10305105,10305106,10305107,10305108,10305109,
	10305110,10305111,10305203,10305204,10305205,10305206,10305207,10305208,10305209,10305210,
	10305211,
	--likun 2009-8-26
	10300007,	--赤焰九纹刀	96
	10301001,	--斩忧断愁枪	96
	10301199,	--弈天破邪杖	96
	10302007,	--含光弄影剑	96
	10302009,	--万仞龙渊剑	96
	10303001,	--转魂灭魄钩	96
	10304007,	--雷鸣离火扇	96
	10304009,	--雷鸣离火扇	96
	10305007,	--碎情雾影环	96
	10305009,	--天星耀阳环	96
	--zhanglei 2009-9-4
	10156001, --武魂：琉璃焰
	10156002, --武魂：御瑶盘
	--绑定武魂
	10156003,
	10156004,
	--以下为姑苏新装备
	10510118,	10510119,	10511119,	10512118,	10512119,	10513118,10513119,
	10514109, 10515109, 10521109,	10522109,	10523109, 10552118,10553118,
	--慕容神器
	10302011,10302200,10302201,10302202,10302203,10302204,10302205,
	10302206,10302207,10302208,10302209,10302210,10302211,
	--永恒钻戒，90级及以上开发极限打孔
	10422128,10422129,10422130,10422131,10422132,10422136,10422137,10422138,10422139,10422140,
	--重楼召 重楼归 guochenshu 2010-09-17 重楼返
	10422155,10423064,10420091,
	--（84235、84236、84237一起提交）【每周10新】90级宋辽装备开4孔·脚本修改
	10421941,10421942,10421943,10421944,10421951,10421952,10421953,10421954,10421961,10421962,10421963,10421964,
	10415941,10415942,10415943,10415944,10415951,10415952,10415953,10415954,10415961,10415962,10415963,10415964,
	10414941,10414942,10414943,10414944,10414951,10414952,10414953,10414954,10414961,10414962,10414963,10414964,
	--quyan 重楼链，真重楼链 2010.11.29
	--lilianhuan 新增不绑定的重楼链
	10420088,10420089,10420090,10420093,
	-- -_-!!!!kaibin for 添加少室山96套装可打孔
	10510124,10510125,10510126,10510127,10511124,10511125,10511126,10511127,10512124,10512125,10512126,10512127,
	10522124,10522125,10522126,10522127,10523124,10523125,10523126,10523127,
	10157001,10157002, --龙纹
	10422160,--变身戒指
	10415055,10415056, --modify by kaibin for 新重楼护肩
	10423076,10423077, --真重楼玉和真重楼戒
	10511138,10513138,10520138,10514149,10515149,			--唐门新增90+装备
	10521149,10522149,10523149,10522138,10523138,			----唐门新增90+装备
	10206023,10206024,10206025,10206026,10206027,10206028,10206029,10206030,10406006,10306004,10306005, --唐门装备
	10306006,10306007,10306008,10306009,10306010,10306011,10306012,10306013,10306014,10306015,10306016,10306017,10306018,	--唐门装备
	10306019,10306020,10306021,10306022,10306023,10306024,10306025,10306026,10306027,10306028,10306029,10306030,10306031,	--唐门装备
	10306032,10306033,10306034,10306035,10306036,10306037,10306038,10306039,10306040,10306041,					--唐门装备
	10510139,10511139,10512139,10513139,		--唐门100装备
	--kk 新重楼
	10410149,10410150,10410151,10410152,
	10411101,10411102,10411103,10411104,
	10412097,10412098,10412099,10412100,
	10413102,10413103,10413104,10413105,
	10414055,10414056,10414057,10414058,
	10421092,10421093,10421094,10421095,
	--lixiang	神器升星新装备开4孔
	10300400,10301400,10301401,10302400,10302401,10302402,10303400,10304400,
	10304401,10305400,10305401,10300401,10301402,10301403,10302403,10302404,
	10302405,10303401,10304402,10304403,10305402,10305403,10300402,10301404,
	10301405,10302406,10302407,10302408,10303402,10304404,10304405,10305404,
	10305405,10300403,10301406,10301407,10302409,10302410,10302411,10303403,
	10304406,10304407,10305406,10305407,10300404,10300405,10300406,10300407,
	10300408,10300409,10300410,10300411,10300412,10301408,10301409,10301410,
	10301411,10301412,10301413,10301414,10301415,10301416,10301417,10301418,
	10301419,10301420,10301421,10301422,10301423,10301424,10301425,10302412,
	10302413,10302414,10302415,10302416,10302417,10302418,10302419,10302420,
	10302421,10302422,10302423,10302424,10302425,10302426,10302427,10302428,
	10302429,10303404,10303405,10303406,10303407,10303408,10303409,10303410,
	10303411,10303412,10303413,10303414,10303415,10303416,10303417,10303418,
	10303419,10303420,10303421,10304408,10304409,10304410,10304411,10304412,
	10304413,10304414,10304415,10304416,10305408,10305409,10305410,10305411,
	10305412,10305413,10305414,10305415,10305416,10305417,10305418,10305419,
	10305420,10305421,10305422,10305423,10305424,10305425,10300413,10300414,
	10300415,10300416,10300417,10300418,10300419,10300420,10300421,10301426,
	10301427,10301428,10301429,10301430,10301431,10301432,10301433,10301434,
	10301435,10301436,10301437,10301438,10301439,10301440,10301441,10301442,
	10301443,10302430,10302431,10302432,10302433,10302434,10302435,10302436,
	10302437,10302438,10302439,10302440,10302441,10302442,10302443,10302444,
	10302445,10302446,10302447,10303422,10303423,10303424,10303425,10303426,
	10303427,10303428,10303429,10303430,10303431,10303432,10303433,10303434,
	10303435,10303436,10303437,10303438,10303439,10304417,10304418,10304419,
	10304420,10304421,10304422,10304423,10304424,10304425,10305426,10305427,
	10305428,10305429,10305430,10305431,10305432,10305433,10305434,10305435,
	10305436,10305437,10305438,10305439,10305440,10305441,10305442,10305443,
	10511148,10513148,10520148,10514169,10515169,			--鬼谷新增90+装备
	10521169,10522169,10523169,10522158,10523158,			----唐门新增90+装备
	10207023,10207024,10207025,10207026,10207027,10207028,10207029,10207030,10407006,10307004,10307005, --鬼谷装备
	10307006,10307007,10307008,10307009,10307010,10307011,10307012,10307013,10307014,10307015,10307016,10307017,10307018,	--鬼谷装备
	10307019,10307020,10307021,10307022,10307023,10307024,10307025,10307026,10307027,10307028,10307029,10307030,10307031,	--鬼谷装备
	10307032,10307033,10307034,10307035,10307036,10307037,10307038,10307039,10307040,10307041,					--鬼谷装备
	10510149,10511149,10512149,10513149,		--鬼谷100装备
	10511153,10513152,10520152,10522173,10523173,		--桃花岛
	10514174,10515174,10521174,10522175,10523175,			----桃花岛新增90+装备
	10208023,10208024,10208025,10208026,10208027,10208028,10208029,10208030,10408006,10308004,10308005, --桃花岛装备
	10308006,10308007,10308008,10308009,10308010,10308011,10308012,10308013,10308014,10308015,10308016,10308017,10308018,	--桃花岛装备
	10308019,10308020,10308021,10308022,10308023,10308024,10308025,10308026,10308027,10308028,10308029,10308030,10308031,	--桃花岛装备
	10308032,10308033,10308034,10308035,10308036,10308037,10308038,10308039,10308040,10308041,					--桃花岛装备
	10510153,10511154,10512153,10513153,		--桃花岛100装备	
	10511158,10513156,10520156,10522179,10523179,		--menpai14
	10514179,10515179,10521179,10522181,10523181,
	10216023,10216024,10216025,10216026,10216027,10216028,10216029,10216030,10416006,10316004,10316005,
	10316006,10316007,10316008,10316009,10316010,10316011,10316012,10316013,10316014,10316015,10316016,10316017,10316018,
	10316019,10316020,10316021,10316022,10316023,10316024,10316025,10316026,10316027,10316028,10316029,10316030,10316031,
	10316032,10316033,10316034,10316035,10316036,10316037,10316038,10316039,10316040,10316041,
	10510157,10511159,10512157,10513157,
	10511163,10513160,10522185,10520160,10523185,		--menpai15
	10514184,10515184,10521184,10522187,10523187,
	10217023,10217024,10217025,10217026,10217027,10217028,10217029,10217030,10417006,10317004,10317005,
	10317006,10317007,10317008,10317009,10317010,10317011,10317012,10317013,10317014,10317015,10317016,10317017,10317018,
	10317019,10317020,10317021,10317022,10317023,10317024,10317025,10317026,10317027,10317028,10317029,10317030,10317031,
	10317032,10317033,10317034,10317035,10317036,10317037,10317038,10317039,10317040,10317041,
	10510161,10511164,10512161,10513161,
	--Vega 2025.09.01。进阶后装备开放极限打孔
	10210091,10210092,10210093,10211091,10211092,10211093,10212097,10212098,10212099,10213091,
	10213092,10213093,10214031,10215031,10220031,10221031,10222037,10222038,10222039,10223037,
	10223038,10223039,
}

--===============================================
-- PreLoad
--===============================================
function SplitGemEx_PreLoad()
	this:RegisterEvent("UI_COMMAND")
 	this:RegisterEvent("BUY_ITEM")
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
 	this:RegisterEvent("UPDATE_COMPOSE_GEM")
 	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("ITEM_CLICKED_SPLITGEMEX")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function SplitGemEx_OnLoad()
--~ 	EQUIP_BUTTON	= SplitGemEx_Item
--~ 	CHARM_BUTTON	= SplitGemEx_Gem4
--~ 	GEM_BUTTONS[1]	= SplitGemEx_Gem1
--~ 	GEM_BUTTONS[2]	= SplitGemEx_Gem2
--~ 	GEM_BUTTONS[3]	= SplitGemEx_Gem3
	g_SplitGemEx_Gems={
		[1]=SplitGemEx_Gem1,
		[2]=SplitGemEx_Gem2,
		[3]=SplitGemEx_Gem3,
		[4]=SplitGemEx_Gem4,
	}

	g_SplitGemEx_Frame_UnifiedPosition=SplitGemEx_Frame:GetProperty("UnifiedPosition")
end

function SplitGemEx_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 2013060603 then
		if arg1 == nil or tonumber(arg1) < 0 then return end
		g_SplitGemEx_CareObj=DataPool:GetNPCIDByServerID(tonumber(arg1))
		if g_SplitGemEx_CareObj<0 then return end
		g_SplitGemEx_npcSid = tonumber(arg1)
		BeginCareObject_SplitGemEx()
		SplitGemEx_Clear()
		SplitGemEx_Update()
		this:Show()

	elseif event == "BUY_ITEM" and this:IsVisible() then
		if g_SplitGemEx_Equip_ID > 0 and g_SplitGemEx_Material_Buy > 0 then
			local item = tonumber(arg1)
			if item < 30900037 or item > 30900044 then return end
			g_SplitGemEx_Material_Buy = -1
			SplitGemEx_UI_SetItem(2,PlayerPackage:GetBagPosByItemIndex(item),0)
		end
	elseif event == "PACKAGE_ITEM_CHANGED_EX" then
		if arg0 ~= nil and -1 == tonumber(arg0) then return end
		if g_SplitGemEx_Equip_pos == tonumber(arg0) then
			SplitGemEx_Clear()
			SplitGemEx_UI_SetItem(1,tonumber(arg0),0)
		end
		if g_SplitGemEx_Material_pos == tonumber(arg0) then
			local equip = g_SplitGemEx_Equip_pos
			SplitGemEx_Clear()
			SplitGemEx_UI_SetItem(1,equip,0)
		end
	elseif event == "UPDATE_COMPOSE_GEM" and this:IsVisible() then
		SplitGemEx_UI_SetItem(tonumber(arg0),tonumber(arg1),1)
 	elseif event == "RESUME_ENCHASE_GEM_EX" then
		if arg0 == nil then return end
		Resume_SplitGemEx(tonumber(arg0))
	elseif event == "ITEM_CLICKED_SPLITGEMEX" and this:IsVisible() then
		if arg0 == nil or arg1 == nil then return end
		SplitGemEx_UI_SetItem(tonumber(arg0),tonumber(arg1),1)
	elseif event == "ADJEST_UI_POS" then
		SplitGemEx_Frame_On_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		SplitGemEx_Frame_On_ResetPos()
	end

end

--===============================================
-- Clear All Parameters
--===============================================
function SplitGemEx_Clear()
	Resume_SplitGemEx(1)
	Resume_SplitGemEx(2)
	g_SplitGemEx_Equip_ID = -1
	g_SplitGemEx_Equip_pos = -1
	g_SplitGemEx_Material_ID = -1
	g_SplitGemEx_Material_pos = -1
	g_SplitGemEx_Selected = -1
end

--===============================================
-- Set Item To SplitGemEx UI
--===============================================
function SplitGemEx_UI_SetItem(posUI,posBag,bMsg)
	if posUI < 1 or posUI > 2 then return end
	if bMsg < 0 or bMsg > 1 then return end
	local theAction = EnumAction(posBag, "packageitem")
	if theAction:GetID() ~= 0 then
		if posUI == 1 then
			--check equip point
			local equipPoint = LifeAbility:Get_Equip_Point(posBag)
			if equipPoint == -1 then return end
			if equipPoint == 8 or equipPoint == 9 or equipPoint == 10 then
				if bMsg == 0 then return end
				PushDebugMessage("#{BSLCYH_130529_25}")
				return
			elseif equipPoint == 16 then
				if bMsg == 0 then return end
				PushDebugMessage("#{BSLCYH_130529_54}")
				return
			end
			--check have gem
			local holecount = LifeAbility:GetEquip_HoleCount(posBag)
			local gemcount = LifeAbility:GetEquip_GemCount(posBag)
			if gemcount == 0 then
				if bMsg == 0 then return end
				PushDebugMessage("#{BSLCYH_130529_67}")
				return
			end
			--check equip lock
			if PlayerPackage:IsLock(posBag) == 1 then
				if bMsg == 0 then return end
				PushDebugMessage("#{BSLCYH_130529_76}")
				return
			end

			Resume_SplitGemEx(1)
			g_SplitGemEx_Equip_ID = theAction:GetID()
			g_SplitGemEx_Equip_pos = posBag
			LifeAbility:Lock_Packet_Item(posBag,1)
			SplitGemEx_Update()

		elseif posUI == 2 then
			--check equip ready
			if g_SplitGemEx_Equip_ID == -1 then
				if bMsg == 0 then return end
				PushDebugMessage("#{BSLCYH_130529_53}")
				return
			end
			--check gem selected
			if g_SplitGemEx_Selected == -1 then
				if bMsg == 0 then return end
				PushDebugMessage("#{BSLCYH_130529_50}")
				return
			end
			--check lock
			if PlayerPackage:IsLock(posBag) == 1 then
				if bMsg == 0 then return end
				PushDebugMessage("#{BSLCYH_130529_20}")
				return
			end
			--check Material level
			local gemlevel = LifeAbility:GetEquip_GemLevel(g_SplitGemEx_Equip_pos,g_SplitGemEx_Selected-1)
			if gemlevel < 1 or gemlevel > 9 then return end
			if PlayerPackage:GetItemTableIndex(posBag) < g_SplitGemEx_MatTab[gemlevel] then
				if bMsg == 0 then return end
				PushDebugMessage(ScriptGlobal_Format("#{BSLCYH_130529_49}",PlayerPackage:GetItemName(g_SplitGemEx_MatTab[gemlevel])))
				return
			end

			Resume_SplitGemEx(2)
			g_SplitGemEx_Material_ID = theAction:GetID()
			g_SplitGemEx_Material_pos = posBag
			LifeAbility:Lock_Packet_Item(g_SplitGemEx_Material_pos,1)
			SplitGemEx_Update()
		end
	else
		SplitGemEx_Clear()
		SplitGemEx_Update()
	end
end
--===============================================
-- Update Whole UI
--===============================================
function SplitGemEx_Update()
	--tab
	SplitGemEx_StilettoEx:SetCheck(0)
	SplitGemEx_EnchaseEx:SetCheck(0)
	SplitGemEx_SplitGemEx:SetCheck(1)
	SplitGemEx_SplitGemEx:Disable()
	--equip
	SplitGemEx_Item:SetActionItem(g_SplitGemEx_Equip_ID)
	--Material
	SplitGemEx_fu2:SetActionItem(g_SplitGemEx_Material_ID)
	--gem UI
	if g_SplitGemEx_Equip_ID > 0 then
		local _,_,_,holecount=LifeAbility:Stiletto_Preparation(g_SplitGemEx_Equip_pos, 1)
		LifeAbility:SplitGem_Update(g_SplitGemEx_Equip_pos)
		for i=1,4 do
			local nItemIndex = LifeAbility:GetSplitGem_GemIndex(i-1)	
			if nItemIndex ~= -1 then
				if BudgetPlanGem:IsBudgetPlanGemByGemID(nItemIndex) == 1 then
					local IsGemValid = BudgetPlanGem:GetBagItemIsValid(g_SplitGemEx_Equip_pos,i-1)
					local GemDueTime = BudgetPlanGem:GetBagItemDueTime(g_SplitGemEx_Equip_pos,i-1)
					local Action = LifeAbility:UpdateProductAction(i-1,nItemIndex,GemDueTime,IsGemValid)
					if Action and Action:GetID() ~= 0 then
							g_SplitGemEx_Gems[i]:SetActionItem(Action:GetID())
					else
							g_SplitGemEx_Gems[i]:SetActionItem(-1)
							g_SplitGemEx_Gems[i]:SetToolTip("#{BSLCYH_130529_14}")
					end
				else
					local nItemID = LifeAbility:GetSplitGem_Gem(i-1)
					if nItemID ~= -1 then
						ActionID = DataPool:EnumPlayerMission_ItemAction(nItemID)
						g_SplitGemEx_Gems[i]:SetActionItem(ActionID)
					else
						g_SplitGemEx_Gems[i]:SetActionItem(-1)
						g_SplitGemEx_Gems[i]:SetToolTip("#{BSLCYH_130529_14}")
					end
				end
			else
				g_SplitGemEx_Gems[i]:SetActionItem(-1)
				g_SplitGemEx_Gems[i]:SetToolTip("#{BSLCYH_130529_14}")
			end

			if i > holecount then
				g_SplitGemEx_Gems[i]:SetToolTip("#{BSLCYH_130529_12}")
				if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则设置图片资源为唯美版资源
					g_SplitGemEx_Gems[i]:SetProperty( "BackImage", "set:WM_CommonFrame1 image:Feng" )
				else									--否则设置为经典版资源
					g_SplitGemEx_Gems[i]:SetProperty( "BackImage", "set:Agname3 image:BaoShiCheckFeng" )
				end
				if i == 4 and not SplitGemEx_CanFour(g_SplitGemEx_Equip_pos) then
					g_SplitGemEx_Gems[i]:SetToolTip("#{BSLCYH_130529_13}")
				end
			end
		end
	else
		for i=1,4 do
			g_SplitGemEx_Gems[i]:SetActionItem(-1)
			g_SplitGemEx_Gems[i]:SetToolTip( "" )
			g_SplitGemEx_Gems[i]:SetProperty( "BackImage", "" )
		end
	end
	--selected Gem
	for i=1,4 do
		g_SplitGemEx_Gems[i]:SetPushed(0)
	end
	if g_SplitGemEx_Equip_ID > 0 and g_SplitGemEx_Selected > 0 then
		g_SplitGemEx_Gems[g_SplitGemEx_Selected]:SetPushed(1)
	end
	--need Material
	if g_SplitGemEx_Equip_ID > 0 and g_SplitGemEx_Selected > 0 then
		local gemlevel = LifeAbility:GetEquip_GemLevel(g_SplitGemEx_Equip_pos,g_SplitGemEx_Selected-1)
		if gemlevel < 1 or gemlevel > 9 then return end

		local action = DoubleGem:UpdateProductAction(g_SplitGemEx_MatTab[gemlevel])
		if action and action:GetID() ~= 0 then
			SplitGemEx_fu1:SetActionItem(action:GetID())
		end
	else
		SplitGemEx_fu1:SetActionItem(-1)
	end
end
function SplitGemEx_CanFour(posBag)
	local bCanFour = false
	local equipItem = PlayerPackage:GetItemTableIndex(posBag)
	for _,i in g_SplitGemEx_four_80_ID do
		if i == equipItem then
			bCanFour = true
			break
		end
	end
	for _,i in g_SplitGemEx_four_ID do
		if i == equipItem then
			bCanFour = true
			break
		end
	end
	
	-- 所有神器都可以打四孔 by lishilong 2016-8-23
	if equipItem >= EQUIP_SHENQI_BEGIN and equipItem <= EQUIP_SHENQI_END then
		bCanFour = true
	end
	
	if PlayerPackage:IsBagItemDark(posBag) == 1 then
		bCanFour = true
	end
	
	if PlayerPackage:IsBagItemHXY(posBag) == 1 then
		bCanFour = true
	end
	return bCanFour
end
function SplitGemEx_Submit()

	if CheckPhoneMibaoAndMinorPassword() ~= 1 then return end
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

	if g_SplitGemEx_Equip_ID == -1 then
		PushDebugMessage("#{BSLCYH_130529_53}")
		return
	end

	if g_SplitGemEx_Selected == -1 then
		PushDebugMessage("#{BSLCYH_130529_50}")
		return
	end

	if g_SplitGemEx_Material_ID == -1 then
		local gemlevel = LifeAbility:GetEquip_GemLevel(g_SplitGemEx_Equip_pos,g_SplitGemEx_Selected-1)
		if gemlevel < 1 or gemlevel > 9 then return end

		if Player:GetData("LEVEL") < 15 then
			PushDebugMessage("#{BSLCYH_130529_144}")
			return
		end

		if SplitGemEx_YuanBaoPay_Button:GetCheck() == 0 then
			--不提示 自动购买
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("SplitGemEx_YuanbaoPay")
				Set_XSCRIPT_ScriptID(701614)
				Set_XSCRIPT_Parameter(0,g_SplitGemEx_MatTab[gemlevel])
				Set_XSCRIPT_Parameter(1,0)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
			return
		elseif SplitGemEx_YuanBaoPay_Button:GetCheck() == 1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("SplitGemEx_YuanbaoPay")
				Set_XSCRIPT_ScriptID(701614)
				Set_XSCRIPT_Parameter(0,g_SplitGemEx_MatTab[gemlevel])
				Set_XSCRIPT_Parameter(1,1)
				Set_XSCRIPT_ParamCount(2)
			Send_XSCRIPT()
			return
		else return end
	end

	LifeAbility:Do_SeparateGem(g_SplitGemEx_Equip_pos,g_SplitGemEx_Selected-1,g_SplitGemEx_Material_pos)

end


function Resume_SplitGemEx(nIndex)
	if not this:IsVisible() then return end
	if nIndex == 1 then
		if g_SplitGemEx_Equip_ID == -1 then return end
		LifeAbility:Lock_Packet_Item(g_SplitGemEx_Equip_pos,0)
		g_SplitGemEx_Equip_ID = -1
		g_SplitGemEx_Equip_pos = -1
		g_SplitGemEx_Selected = -1
		SplitGemEx_Update()
		if g_SplitGemEx_Material_ID == -1 then return end
		Resume_SplitGemEx(2)

	elseif nIndex == 2 then
		if g_SplitGemEx_Material_ID == -1 then return end
		LifeAbility:Lock_Packet_Item(g_SplitGemEx_Material_pos,0)
		g_SplitGemEx_Material_ID = -1
		g_SplitGemEx_Material_pos = -1
		SplitGemEx_Update()
	end
end
--===============================================
-- Click The Gem to Split
--===============================================
function SplitGemEx_Selected(gem_Index)
	if gem_Index < 1 or gem_Index > 4 then return end
	if g_SplitGemEx_Gems[gem_Index]:GetActionItem() == -1 then return end

	g_SplitGemEx_Selected = gem_Index
	Resume_SplitGemEx(2)
	SplitGemEx_Update()
end

--===============================================
-- Change Tab
--===============================================
function SplitGemEx_ChangeTab(nindex)
	if nindex < 1 or nindex > 3 then return end
	if nindex == 3 then return end

	this:Hide()
	if nindex == 1 then
		PushEvent("OPEN_STILETTOEX_UI", g_SplitGemEx_npcSid)
	elseif nindex == 2 then
		PushEvent("UI_COMMAND", 2013060602, g_SplitGemEx_npcSid)
	end
end
function SplitGemEx_OnShown()
	--pos
	local pos = Variable:GetVariable("Gem3UIpos")
	if pos == nil then return end
	SplitGemEx_Frame:SetProperty("UnifiedPosition", pos)
	--yuanbaoPay
	if g_SplitGemEx_YuanbaoPay == 1 or g_SplitGemEx_YuanbaoPay == 0 then
		SplitGemEx_YuanBaoPay_Button:SetCheck(g_SplitGemEx_YuanbaoPay)
	end
end
function SplitGemEx_OnHidden()
	g_SplitGemEx_YuanbaoPay = SplitGemEx_YuanBaoPay_Button:GetCheck()
	SplitGemEx_Clear()
	StopCareObject_SplitGemEx()
	Variable:SetVariable("Gem3UIpos", SplitGemEx_Frame:GetProperty("UnifiedPosition"), 1)
end
function BeginCareObject_SplitGemEx()
	this:CareObject(g_SplitGemEx_CareObj, 1, "SplitGemEx")
end

function StopCareObject_SplitGemEx()
	this:CareObject(g_SplitGemEx_CareObj, 0, "SplitGemEx")
end
function SplitGemEx_Frame_On_ResetPos()
  SplitGemEx_Frame:SetProperty("UnifiedPosition", g_SplitGemEx_Frame_UnifiedPosition)
end
