-- !!!reloadscript =bg_info
local COMPLETE_PER = 0;
local Last_Per = 0;

local g_loading_imageset = {
    {"BGLogin_0", "set:BGLogin_0_0 image:BGImg", "set:BGLogin_0_1 image:BGImg", "set:BGLogin_0_2 image:BGImg","set:BGLogin_0_3 image:BGImg"},
    {"BGLogin_1", "set:BGLogin_1_0 image:BGImg", "set:BGLogin_1_1 image:BGImg", "set:BGLogin_1_2 image:BGImg","set:BGLogin_1_3 image:BGImg"},
    {"BGLogin_2", "set:BGLogin_2_0 image:BGImg", "set:BGLogin_2_1 image:BGImg", "set:BGLogin_2_2 image:BGImg","set:BGLogin_2_3 image:BGImg"},
    {"BGLogin_3", "set:BGLogin_3_0 image:BGImg", "set:BGLogin_3_1 image:BGImg", "set:BGLogin_3_2 image:BGImg","set:BGLogin_3_3 image:BGImg"},
    {"BGLogin_4", "set:BGLogin_4_0 image:BGImg", "set:BGLogin_4_1 image:BGImg", "set:BGLogin_4_2 image:BGImg","set:BGLogin_4_3 image:BGImg"},
    {"BGLogin_5", "set:BGLogin_5_0 image:BGImg", "set:BGLogin_5_1 image:BGImg", "set:BGLogin_5_2 image:BGImg","set:BGLogin_5_3 image:BGImg"},
    {"BGLogin_6", "set:BGLogin_6_0 image:BGImg", "set:BGLogin_6_1 image:BGImg", "set:BGLogin_6_2 image:BGImg","set:BGLogin_6_3 image:BGImg"},
    {"BGLogin_7", "set:BGLogin_7_0 image:BGImg", "set:BGLogin_7_1 image:BGImg", "set:BGLogin_7_2 image:BGImg","set:BGLogin_7_3 image:BGImg"},
    {"BGLogin_8", "set:BGLogin_8_0 image:BGImg", "set:BGLogin_8_1 image:BGImg", "set:BGLogin_8_2 image:BGImg","set:BGLogin_8_3 image:BGImg"},
    {"BGLogin_9", "set:BGLogin_9_0 image:BGImg", "set:BGLogin_9_1 image:BGImg", "set:BGLogin_9_2 image:BGImg","set:BGLogin_9_3 image:BGImg"},
    {"BGLogin_10", "set:BGLogin_10_0 image:BGImg", "set:BGLogin_10_1 image:BGImg", "set:BGLogin_10_2 image:BGImg","set:BGLogin_10_3 image:BGImg"},
    {"BGLogin_11", "set:BGLogin_11_0 image:BGImg", "set:BGLogin_11_1 image:BGImg", "set:BGLogin_11_2 image:BGImg","set:BGLogin_11_3 image:BGImg"},
    {"BGLogin_12", "set:BGLogin_12_0 image:BGImg", "set:BGLogin_12_1 image:BGImg", "set:BGLogin_12_2 image:BGImg","set:BGLogin_12_3 image:BGImg"},
    {"BGLogin_13", "set:BGLogin_13_0 image:BGImg", "set:BGLogin_13_1 image:BGImg", "set:BGLogin_13_2 image:BGImg","set:BGLogin_13_3 image:BGImg"},
    {"BGLogin_14", "set:BGLogin_14_0 image:BGImg", "set:BGLogin_14_1 image:BGImg", "set:BGLogin_14_2 image:BGImg","set:BGLogin_14_3 image:BGImg"},
    {"BGLogin_15", "set:BGLogin_15_0 image:BGImg", "set:BGLogin_15_1 image:BGImg", "set:BGLogin_15_2 image:BGImg","set:BGLogin_15_3 image:BGImg"},
    {"BGLogin_16", "set:BGLogin_16_0 image:BGImg", "set:BGLogin_16_1 image:BGImg", "set:BGLogin_16_2 image:BGImg","set:BGLogin_16_3 image:BGImg"},
    {"BGLogin_17", "set:BGLogin_17_0 image:BGImg", "set:BGLogin_17_1 image:BGImg", "set:BGLogin_17_2 image:BGImg","set:BGLogin_17_3 image:BGImg"},
    {"BGLogin_18", "set:BGLogin_18_0 image:BGImg", "set:BGLogin_18_1 image:BGImg", "set:BGLogin_18_2 image:BGImg","set:BGLogin_18_3 image:BGImg"},
    {"BGLogin_19", "set:BGLogin_19_0 image:BGImg", "set:BGLogin_19_1 image:BGImg", "set:BGLogin_19_2 image:BGImg","set:BGLogin_19_3 image:BGImg"},
    {"BGLogin_20", "set:BGLogin_20_0 image:BGImg", "set:BGLogin_20_1 image:BGImg", "set:BGLogin_20_2 image:BGImg","set:BGLogin_20_3 image:BGImg"},
    {"BGLogin_31", "set:BGLogin_31_0 image:BGImg", "set:BGLogin_31_1 image:BGImg", "set:BGLogin_31_2 image:BGImg","set:BGLogin_31_3 image:BGImg"},
}
local g_loading_index = {}
--===============================================
-- OnLoad()
--===============================================
function bg_info_PreLoad()
    this:RegisterEvent("BGINFO_SHOW",true)
    this:RegisterEvent("BGINFO_CLOSE",false)
    this:RegisterEvent("NOTIFY_SCENECONFIG_LOST",true)
end

--===============================================
-- OnLoad()
--===============================================
function bg_info_OnLoad()    
    for i = 1, table.getn(g_loading_imageset) do 
        table.insert(g_loading_index, i)
    end
end

--===============================================
-- OnEvent()
--===============================================
function bg_info_OnEvent(event)    

    local w,h = GetCurClientSize()
    

    
    if ( event == "BGINFO_SHOW" ) then
    
    	if arg0 ~= nil and tonumber(arg0) == 1 then
			--微端，缺少资源
			BgInfo_WeiduanText:Show()
		else
			BgInfo_WeiduanText:Hide()
		end

		--已经可视直接return
		if this:IsVisible() then
			return
		end

       --BgInfo_Image:SetProperty( "UnifiedPosition", "{{0.000000,0.000000},{0.000000,0.000000}}" )
       --BgInfo_Image:SetProperty( "UnifiedSize", "{{0.000000,400.000000},{0.000000,300.000000}}" )
       --BgInfo_Image:SetProperty( "AbsolutePosition", "x:0 y:0" );
       --BgInfo_Image:SetProperty( "AbsoluteSize", "w:1280 h:1024" );
       
       local Rate = h / w;
       local PosX = 0
       local PosY = 0
       local Width = 0
       local Heigh = 0
       

       local StdW = 1024
       local StdH = 768
       
       if( Rate == 0.75 ) then    -- 4:3屏
           if( h > StdH ) then   --保持图片居中
               local offsetY = ( h - StdH ) / 2
               local offsetX = ( w - StdW ) / 2
               
               PosX = PosX + offsetX
               PosY = PosY + offsetY
                              
               Width = StdW
               Heigh = StdH
           else                 --否则按高来计算缩放比例
               local hRate = h / StdH
               Width = StdW * hRate
               Heigh = StdH * hRate
               PosX = ( w - Width ) / 2
               PosY = 0
               
           end       
           --Width = w
           --Heigh = h
           --PosX = 0
           --PosY = 0
       elseif( Rate < 0.75 ) then              --宽屏
           if( h > StdH ) then   --保持图片居中
               local offsetY = ( h - StdH ) / 2
               local offsetX = ( w - StdW ) / 2
               
               PosX = PosX + offsetX
               PosY = PosY + offsetY
                              
               Width = StdW
               Heigh = StdH
           else                 --否则按高来计算缩放比例
               local hRate = h / StdH
               Width = StdW * hRate
               Heigh = StdH * hRate
               PosX = ( w - Width ) / 2
               PosY = 0
               
           end
       elseif( Rate > 0.75 ) then              --窄屏(貌似一般情况下不会出现)
           if( w > StdW ) then   --保持图片居中
               local offsetY = ( h - StdH ) / 2
               local offsetX = ( w - StdW ) / 2
               
               PosX = PosX + offsetX
               PosY = PosY + offsetY
               Width = StdW
               Heigh = StdH
                          
           else
               local wRate = w / StdW
               Width = StdW * wRate
               Heigh = StdH * wRate
               PosX = 0
               PosY = ( h - Heigh ) / 2
                          
           end
       else
       end
       
       
       --<Property Name="Image" Value="set:BGLogin_0 image:BGImg" />
       local RandVal = g_loading_index[math.random(table.getn(g_loading_index))] --math.random( 0, 31 ) 
       --local strImg = string.format("set:BGLogin_%d image:BGImg", RandVal )
       --BgInfo_Image:SetProperty( "Image", strImg )
       
       local strImg0 = g_loading_imageset[RandVal][2] --string.format("set:BGLogin_%d_0 image:BGImg", RandVal )
       local strImg1 = g_loading_imageset[RandVal][3] --string.format("set:BGLogin_%d_1 image:BGImg", RandVal )
       local strImg2 = g_loading_imageset[RandVal][4] --string.format("set:BGLogin_%d_2 image:BGImg", RandVal )
       local strImg3 = g_loading_imageset[RandVal][5] --string.format("set:BGLogin_%d_3 image:BGImg", RandVal )
       
       if (BgInfo_Image_0:ResourceCheck(strImg0) == 1 and
       		 BgInfo_Image_1:ResourceCheck(strImg1) == 1 and
       		 BgInfo_Image_2:ResourceCheck(strImg2) == 1 and
       		 BgInfo_Image_3:ResourceCheck(strImg3) == 1) then
       	
       		BgInfo_Image_0:SetProperty( "Image", strImg0 )
       		BgInfo_Image_1:SetProperty( "Image", strImg1 )
       		BgInfo_Image_2:SetProperty( "Image", strImg2 )
       		BgInfo_Image_3:SetProperty( "Image", strImg3 )
       		
       else
              
       		BgInfo_Image_0:SetProperty( "Image", "set:BGLogin_2_0 image:BGImg" )
          BgInfo_Image_1:SetProperty( "Image", "set:BGLogin_2_1 image:BGImg" )
          BgInfo_Image_2:SetProperty( "Image", "set:BGLogin_2_2 image:BGImg" )
          BgInfo_Image_3:SetProperty( "Image", "set:BGLogin_2_3 image:BGImg" )
       end

       --BgInfo_Image_0:SetProperty( "Image", "set:BGLogin_0_0 image:BGImg" )
       --BgInfo_Image_1:SetProperty( "Image", "set:BGLogin_0_1 image:BGImg" )
       --BgInfo_Image_2:SetProperty( "Image", "set:BGLogin_0_2 image:BGImg" )
       --BgInfo_Image_3:SetProperty( "Image", "set:BGLogin_0_3 image:BGImg" )
       
       local strPos = string.format("x:%f y:%f", PosX, PosY);
       local strSize = string.format("w:%f h:%f", Width, Heigh );
       

 
              
       BgInfo_Image:SetProperty( "AbsolutePosition", strPos )
       BgInfo_Image:SetProperty( "AbsoluteSize", strSize )
       
       local strTextNum = GetDictionaryString( "LoadingText_0" )
       if nil ~= strTextNum then
           if "" ~= strTextNum then
               local TextNum = tonumber( strTextNum )
               if TextNum > 0 then
                  local RandText = math.random( 1, TextNum )
                  BgInfo_Text:SetText( "#{LoadingText_"..(RandText).."}" )
               end
           else
			   BgInfo_Text:SetText( "" )
           end
       end
       
       this:Show()
    end
    
    if ( event == "BGINFO_CLOSE" ) then
       this:Hide()
    end
    
    if event == "NOTIFY_SCENECONFIG_LOST" then
		if arg0 == nil then
			return
		end

		local completePer = tonumber(arg0)
		if completePer >= 100 then
			completePer = 99
			COMPLETE_PER=0
		elseif completePer == 0 and COMPLETE_PER==0 then
			BgInfo_WeiduanText:SetText("#{TLWD_120502_1}"..tostring(completePer).."%")
			SetTimer("bg_info","bg_info_OnTimerEvent()", 500)
			Last_Per=0
			return
		elseif completePer <= COMPLETE_PER then 
			return
		elseif COMPLETE_PER < 90 then
			KillTimer("bg_info_OnTimerEvent()")
		end
		
		if Last_Per < completePer then
			BgInfo_WeiduanText:SetText("#{TLWD_120502_1}"..tostring(completePer).."%")
			Last_Per=completePer
		end

  end
         
end

function bg_info_OnTimerEvent()
	COMPLETE_PER= COMPLETE_PER + math.random( 1, 10 )
	if COMPLETE_PER < 90 and Last_Per < COMPLETE_PER then
		BgInfo_WeiduanText:SetText("#{TLWD_120502_1}"..tostring(COMPLETE_PER).."%")
		Last_Per=COMPLETE_PER
	else
		KillTimer("bg_info_OnTimerEvent()")
	end
end
