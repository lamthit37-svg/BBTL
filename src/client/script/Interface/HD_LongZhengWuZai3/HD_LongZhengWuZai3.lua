----------------------
-- HD_LongZhengWuZai3 ---
----------------------
local g_Cardlist = {}
local g_HD_LongZhengWuZai3_Frame_UnifiedPosition =nil;
--===============================================
-- PreLoad()
--===============================================
function HD_LongZhengWuZai3_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function HD_LongZhengWuZai3_OnLoad()
	g_Cardlist[1] = {
				cardid=38000263,
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_1",
				}
	g_Cardlist[2] = {
				cardid=38000264,
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_2",
				}
	g_Cardlist[3] = {
				cardid=38000265,
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_3",
				}
	g_Cardlist[4] = {
				cardid=38000266,
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_4",
				}
	g_Cardlist[5] = {
				cardid=38000267,
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_5",
				}
	g_Cardlist[6] = {
				cardid=38000268,
				NomalImage = "set:LongZhengWuZai1 image:LongZhengWuZai1_6",
				}
	g_Cardlist[7] = {
				cardid=38000269,
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_1",
				}
	g_Cardlist[8] = {
				cardid=38000270,
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_2",
				}
	g_Cardlist[9] = {
				cardid=38000271,
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_3",
				}
	g_Cardlist[10] = {
				cardid=38000272,
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_4",
				}
	g_Cardlist[11] = {
				cardid=38000273,
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_5",
				}
	g_Cardlist[12] = {
				cardid=38000274,
				NomalImage = "set:LongZhengWuZai2 image:LongZhengWuZai2_6",
				}
	g_Cardlist[13] = {
				cardid=38000275,
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_1",
				}
	g_Cardlist[14] = {
				cardid=38000276,
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_2",
				}
	g_Cardlist[15] = {
				cardid=38000277,
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_3",
				}
	g_Cardlist[16] = {
				cardid=38000278,
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_4",
				}
	g_Cardlist[17] = {
				cardid=38000279,
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_5",
				}
	g_Cardlist[18] = {
				cardid=38000280,
				NomalImage = "set:LongZhengWuZai3 image:LongZhengWuZai3_6",
				}
	g_Cardlist[19] = {
				cardid=38000281,
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_1",
				}
	g_Cardlist[20] = {
				cardid=38000282,
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_2",
				}
	g_Cardlist[21] = {
				cardid=38000283,
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_3",
				}
	g_Cardlist[22] = {
				cardid=38000284,
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_4",
				}
	g_Cardlist[23] = {
				cardid=38000285,
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_5",
				}
	g_Cardlist[24] = {
				cardid=38000286,
				NomalImage = "set:LongZhengWuZai4 image:LongZhengWuZai4_6",
				}
				
	--add:lby 20160229增加16张卡		
	g_Cardlist[25] = {
				cardid=38001578,
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_1",
				}
	g_Cardlist[26] = {
				cardid=38001579,
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_2",
				}
	g_Cardlist[27] = {
				cardid=38001580,
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_3",
				}
	g_Cardlist[28] = {
				cardid=38001581,
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_4",
				}
	g_Cardlist[29] = {
				cardid=38001582,
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_5",
				}
	g_Cardlist[30] = {
				cardid=38001583,
				NomalImage = "set:LongZhengWuZai9 image:LongZhengWuZai9_6",
				}
		--add:lby 20160229增加后十张卡
	
	g_Cardlist[31] = {
				cardid=38001584,
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_1",
				}
	g_Cardlist[32] = {
				cardid=38001585,
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_2",
				}
	g_Cardlist[33] = {
				cardid=38001586,
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_3",
				}
	g_Cardlist[34] = {
				cardid=38001587,
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_4",
				}
	g_Cardlist[35] = {
				cardid=38001588,
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_5",
				}
		g_Cardlist[36] = {
				cardid=38001589,
				NomalImage = "set:LongZhengWuZai10 image:LongZhengWuZai10_6",
				}
	g_Cardlist[37] = {
				cardid=38001590,
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_1",
				}
	g_Cardlist[38] = {
				cardid=38001591,
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_2",
				}
	g_Cardlist[39] = {
				cardid=38001592,
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_3",
				}
	g_Cardlist[40] = {
				cardid=38001593,
				NomalImage = "set:LongZhengWuZai11 image:LongZhengWuZai11_4",
				}						
				
	g_HD_LongZhengWuZai3_Frame_UnifiedPosition = HD_LongZhengWuZai3_Frame:GetProperty("UnifiedPosition")
end

--===============================================
-- OnEvent()
--===============================================
function HD_LongZhengWuZai3_OnEvent(event)

	if (event  == "UI_COMMAND") and (tonumber(arg0) == 20120204) then
		local itemid = Get_XParam_INT(0)
		HD_LongZhengWuZai3_ShowCard(itemid)
	elseif (event == "ADJEST_UI_POS") then
		HD_LongZhengWuZai3_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then	
		HD_LongZhengWuZai3_ResetPos()
	elseif (event ==  "HIDE_ON_SCENE_TRANSED") then
		HD_LongZhengWuZai3_Close()
	end
end

function HD_LongZhengWuZai3_ShowCard(itemid)
	--PushDebugMessage(itemid)
	for i = 1, 40 do
		if itemid == g_Cardlist[i].cardid then
			HD_LongZhengWuZai3_Image : SetProperty("Image",g_Cardlist[i].NomalImage)
		end
	end
	this:Show()
end

function HD_LongZhengWuZai3_ResetPos()
	HD_LongZhengWuZai3_Frame:SetProperty("UnifiedPosition",g_HD_LongZhengWuZai3_Frame_UnifiedPosition)
end

--===============================================
-- Close()
--===============================================
function HD_LongZhengWuZai3_Close()
	return this:Hide()
end