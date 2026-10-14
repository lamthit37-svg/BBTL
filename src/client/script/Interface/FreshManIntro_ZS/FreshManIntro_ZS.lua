
local g_FreshManIntro_ZS_Frame_UnifiedPosition;




local NEWBIEHELP_ZS_TUTORIAL =
{
[101] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_13}", image={   "set:Tpzs02_01_1 image:IntroImage1_1",
																										         "set:Tpzs02_01_2 image:IntroImage1_2",
																										         "set:Tpzs02_01_3 image:IntroImage1_3",
																										         "set:Tpzs02_01_3 image:IntroImage1_4",},},

[102] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_14}", image={ 	"set:Tpzs02_02_1 image:IntroImage1_1",
																									          "set:Tpzs02_02_2 image:IntroImage1_2",
																									          "set:Tpzs02_02_3 image:IntroImage1_3",
																									          "set:Tpzs02_02_3 image:IntroImage1_4",},},

[103] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_15}", image={ "set:Tpzs02_03_1 image:IntroImage1_1",
																										        "set:Tpzs02_03_2 image:IntroImage1_2",
																										        "set:Tpzs02_03_3 image:IntroImage1_3",
																										        "set:Tpzs02_03_3 image:IntroImage1_4",},},

[104] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_16}", image={ "set:Tpzs02_04_1 image:IntroImage1_1",
																									         "set:Tpzs02_04_2 image:IntroImage1_2",
																									         "set:Tpzs02_04_3 image:IntroImage1_3",
																									         "set:Tpzs02_04_3 image:IntroImage1_4",},},

[105] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_17}", image={  "set:Tpzs02_05_1 image:IntroImage1_1",
																									          "set:Tpzs02_05_2 image:IntroImage1_2",
																									          "set:Tpzs02_05_3 image:IntroImage1_3",
																									          "set:Tpzs02_05_3 image:IntroImage1_4",},},
																									          
[201] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_24}", image={   "set:Tpzs03_01_1 image:IntroImage1_1",
																										         "set:Tpzs03_01_2 image:IntroImage1_2",
																										         "set:Tpzs03_01_3 image:IntroImage1_3",
																										         "set:Tpzs03_01_3 image:IntroImage1_4",},},

[202] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_25}", image={ 	"set:Tpzs03_02_1 image:IntroImage1_1",
																									          "set:Tpzs03_02_2 image:IntroImage1_2",
																									          "set:Tpzs03_02_3 image:IntroImage1_3",
																									          "set:Tpzs03_02_3 image:IntroImage1_4",},},

[203] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_26}", image={ "set:Tpzs03_03_1 image:IntroImage1_1",
																										        "set:Tpzs03_03_2 image:IntroImage1_2",
																										        "set:Tpzs03_03_3 image:IntroImage1_3",
																										        "set:Tpzs03_03_3 image:IntroImage1_4",},},

[204] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_27}", image={ "set:Tpzs03_04_1 image:IntroImage1_1",
																									         "set:Tpzs03_04_2 image:IntroImage1_2",
																									         "set:Tpzs03_04_3 image:IntroImage1_3",
																									         "set:Tpzs03_04_3 image:IntroImage1_4",},},

[205] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_28}", image={  "set:Tpzs03_05_1 image:IntroImage1_1",
																									          "set:Tpzs03_05_2 image:IntroImage1_2",
																									          "set:Tpzs03_05_3 image:IntroImage1_3",
																									          "set:Tpzs03_05_3 image:IntroImage1_4",},},
																									          
[301] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_33}", image={   "set:Tpzs01_01_1 image:IntroImage1_1",
																										         "set:Tpzs01_01_2 image:IntroImage1_2",
																										         "set:Tpzs01_01_3 image:IntroImage1_3",
																										         "set:Tpzs01_01_3 image:IntroImage1_4",},},

[302] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_34}", image={ 	"set:Tpzs01_02_1 image:IntroImage1_1",
																									          "set:Tpzs01_02_2 image:IntroImage1_2",
																									          "set:Tpzs01_02_3 image:IntroImage1_3",
																									          "set:Tpzs01_02_3 image:IntroImage1_4",},},

[303] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_35}", image={ "set:Tpzs01_03_1 image:IntroImage1_1",
																										        "set:Tpzs01_03_2 image:IntroImage1_2",
																										        "set:Tpzs01_03_3 image:IntroImage1_3",
																										        "set:Tpzs01_03_3 image:IntroImage1_4",},},

[304] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_36}", image={ "set:Tpzs01_04_1 image:IntroImage1_1",
																									         "set:Tpzs01_04_2 image:IntroImage1_2",
																									         "set:Tpzs01_04_3 image:IntroImage1_3",
																									         "set:Tpzs01_04_3 image:IntroImage1_4",},},

[305] ={title = "#gFF0FA0#{GQGD_SSYZH_110913_37}", image={  "set:Tpzs01_05_1 image:IntroImage1_1",
																									          "set:Tpzs01_05_2 image:IntroImage1_2",
																									          "set:Tpzs01_05_3 image:IntroImage1_3",
																									          "set:Tpzs01_05_3 image:IntroImage1_4",},},

}

local now_tutorial_set = 0

--===============================================
-- OnLoad()
--===============================================
function FreshManIntro_ZS_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OPEN_FRESHMAN_INTRO");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function FreshManIntro_ZS_OnLoad()
	g_FreshManIntro_ZS_Frame_UnifiedPosition=FreshManIntro_ZS_Frame:GetProperty("UnifiedPosition");
end

function FreshManIntro_ZS_OnHiden()

end


--===============================================
-- OnEvent()
--===============================================
function FreshManIntro_ZS_OnEvent(event)	 
	if (event == "ADJEST_UI_POS" ) then
		FreshManIntro_ZS_Frame_On_ResetPos()
		-- 游戏分辨率发生了变化
		return
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
	 
		FreshManIntro_ZS_Frame_On_ResetPos()
		return
	end 
	if ( event == "UI_COMMAND" and tonumber(arg0) == 20110918 ) then
	-- PushDebugMessage( "Get_XParam_INT(0) ".. Get_XParam_INT(0)   );
		FreshManIntro_ZS_ReSetImage(  Get_XParam_INT(0) )
		return
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FreshManIntro_ZS_Frame_On_ResetPos()
	FreshManIntro_ZS_Frame:SetProperty("UnifiedPosition", g_FreshManIntro_ZS_Frame_UnifiedPosition);
end

function FreshManIntro_ZS_ReSetImage( transtabset )
	now_tutorial_set = transtabset
	return FreshManIntro_ZS_SetImage( );
end

function FreshManIntro_ZS_SetImage( )
	-- PushDebugMessage( "FreshManIntro_ZS_SetImage ".. now_tutorial_set   );
	if now_tutorial_set == 0 then
		return
	end
	local tutorialtab = NEWBIEHELP_ZS_TUTORIAL[now_tutorial_set]
	if(tutorialtab~=nil) then
		FreshManIntro_ZS_Image1:SetProperty("Image", tutorialtab.image[1])
		FreshManIntro_ZS_Image2:SetProperty("Image", tutorialtab.image[2])
		FreshManIntro_ZS_Image3:SetProperty("Image", tutorialtab.image[3])
		FreshManIntro_ZS_Image4:SetProperty("Image", tutorialtab.image[4])
		FreshManIntro_ZS_Text:SetText( tutorialtab.title );		
		this:Show();
		return 1
	else
		return 0
	end
end

function FreshManIntro_ZS_Close()
	this:Hide();
end

function FreshManIntro_ZS_Quit_Clicked()
	this:Hide();
end
