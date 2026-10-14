
local g_Frame_UnifiedPosition;
local g_YaoTaStr =
{
	[1] = "#{JXPVP_170814_110}",
	[2] = "#{JXPVP_170814_111}",
	[3] = "#{JXPVP_170814_112}",
	[4] = "#{JXPVP_170814_113}",
	[5] = "#{JXPVP_170814_114}",
};

local g_YaoTaStr2 =
{
	[1] = "#{JXPVP_170814_147}",
	[2] = "#{JXPVP_170814_148}",
	[3] = "#{JXPVP_170814_149}",
	[4] = "#{JXPVP_170814_150}",
	[5] = "#{JXPVP_170814_151}",
};

local g_YaoTaStr3 =
{
	[1] = "#{JXPVP_170814_185}",
	[2] = "#{JXPVP_170814_186}",
	[3] = "#{JXPVP_170814_187}",
	[4] = "#{JXPVP_170814_188}",
	[5] = "#{JXPVP_170814_189}",
};

local g_YaoTaPic =
{
	[1] = "set:JiuxingPvp image:CityWarPVE_yiyuanjing",
	[2] = "set:JiuxingPvp image:CityWarPVE_yiyuanjing",
	[3] = "set:JiuxingPvp image:CityWarPVE_sanqinjing",
	[4] = "set:JiuxingPvp image:CityWarPVE_sanqinjing",
	[5] = "set:JiuxingPvp image:CityWarPVE_wudijing",
};

local g_nType = 0
local g_nCeng = 0

function KVK_ShengQiPVP_ZhiYing_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	
	this:RegisterEvent("SHENQIPVP_ZHIYIN_OPNE")	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
end

--=========
--OnLoad
--=========
function KVK_ShengQiPVP_ZhiYing_OnLoad()
	g_Frame_UnifiedPosition = KVK_ShengQiPVP_ZhiYing_Frame:GetProperty("UnifiedPosition")
end
 		
				
--=========
--OnEvent
--=========
function KVK_ShengQiPVP_ZhiYing_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 20170925 then
		local nType = tonumber(Get_XParam_INT(0))
		local nRestMin = tonumber(Get_XParam_INT(1))
		local nRestSec = tonumber(Get_XParam_INT(2))
		local nCeng = tonumber(Get_XParam_INT(3))
		local nXiangzCnt = tonumber(Get_XParam_INT(4))
		g_nType = nType
		g_nCeng = nCeng
		if nType == 0 then --妖塔界面刷新
			local nCurMin = math.mod( nRestMin, 10 )
			KVK_ShengQiPVP_ZhiYing_PageHeader2:SetText(g_YaoTaStr[nCeng])
			KVK_ShengQiPVP_ZhiYing_Image2Info1:SetText(g_YaoTaStr2[nCeng])

			local str = g_YaoTaStr3[nCeng]
			if nRestMin < 8 then
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_194}", 7-nRestMin,60-nRestSec)
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_191}", nXiangzCnt)
				str = str.."#r".."#{JXPVP_170814_195}"				
			elseif nRestMin>=8 and nRestMin<10 then
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_196}", 17-nRestMin,60-nRestSec)
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_191}", nXiangzCnt)
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_197}", 9-nRestMin,60-nRestSec,nXiangzCnt)
			elseif nRestMin>=10 and nRestMin<18 then
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_196}", 17-nRestMin,60-nRestSec)
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_191}", nXiangzCnt)
				str = str.."#r".."#{JXPVP_170814_195}"							
			elseif nRestMin>=18 and nRestMin<20 then
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_196}", 27-nRestMin,60-nRestSec)
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_191}", nXiangzCnt)
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_197}", 19-nRestMin,60-nRestSec,nXiangzCnt)				
			elseif nRestMin>=20 and nRestMin<28 then
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_196}", 27-nRestMin,60-nRestSec)
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_191}", nXiangzCnt)
				str = str.."#r".."#{JXPVP_170814_195}"				
			elseif nRestMin>=28 and nRestMin<30 then
				str = str.."#r".."#{JXPVP_170814_198}"	
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_191}", nXiangzCnt)
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_197}", 29-nRestMin,60-nRestSec,nXiangzCnt)					
			elseif nRestMin == 30 then
				str = str.."#r".."#{JXPVP_170814_198}"	
				str = str.."#r"..ScriptGlobal_Format("#{JXPVP_170814_191}", nXiangzCnt)
				str = str.."#r".."#{JXPVP_170814_214}"			
			end

			KVK_ShengQiPVP_ZhiYing_Image2Info2:SetText(str)

			if nRestSec < 10 then
				KVK_ShengQiPVP_ZhiYing_Image2Info3:SetText(ScriptGlobal_Format("#{JXPVP_170814_154}", 30-nRestMin,10-nRestSec))
			else 
				KVK_ShengQiPVP_ZhiYing_Image2Info3:SetText(ScriptGlobal_Format("#{JXPVP_170814_154}", 29-nRestMin,70-nRestSec))				
			end
			
		end
		
		if nType == 1 then --苍梧界面刷新
			KVK_ShengQiPVP_ZhiYing_PageHeader1:SetText("#{JXPVP_170814_105}")
			KVK_ShengQiPVP_ZhiYing_Image1Info1:SetText("#{JXPVP_170814_106}")
			KVK_ShengQiPVP_ZhiYing_Image1Info2:SetText("#{JXPVP_170814_192}")
		
		end
		return
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20170926 then	
		local nType = tonumber(Get_XParam_INT(0))
		g_nType = nType
		this:Show()
		if nType == 0 then --妖塔界面打开
			local nCeng = tonumber(Get_XParam_INT(1))
			KVK_ShengQiPVP_ZhiYing_BK1:Hide()
			KVK_ShengQiPVP_ZhiYing_BK2:Show()
			KVK_ShengQiPVP_ZhiYing_PageHeader1:SetText("")
			KVK_ShengQiPVP_ZhiYing_Image1:SetProperty("Image","");
			KVK_ShengQiPVP_ZhiYing_Image1Info1:SetText("")
			KVK_ShengQiPVP_ZhiYing_Image1Info2:SetText("")
			KVK_ShengQiPVP_ZhiYing_Image2:SetProperty("Image",g_YaoTaPic[nCeng]);	
			KVK_ShengQiPVP_ZhiYing_Image2Info3:SetToolTip("#{JXPVP_170814_199}");
		elseif nType == 1 then --苍梧界面打开
			KVK_ShengQiPVP_ZhiYing_BK1:Show()
			KVK_ShengQiPVP_ZhiYing_BK2:Hide()
			KVK_ShengQiPVP_ZhiYing_PageHeader2:SetText("")
			KVK_ShengQiPVP_ZhiYing_Image2:SetProperty("Image","");
			KVK_ShengQiPVP_ZhiYing_Image2Info1:SetText("")
			KVK_ShengQiPVP_ZhiYing_Image2Info2:SetText("")
			KVK_ShengQiPVP_ZhiYing_Image2Info3:SetText("")			
			KVK_ShengQiPVP_ZhiYing_Image1:SetProperty("Image","set:JiuxingPvp image:CityWarPVE_cangwumijing");
			KVK_ShengQiPVP_ZhiYing_PageHeader1:SetText("#{JXPVP_170814_105}")
			KVK_ShengQiPVP_ZhiYing_Image1Info1:SetText("#{JXPVP_170814_106}")
			KVK_ShengQiPVP_ZhiYing_Image1Info2:SetText("#{JXPVP_170814_192}")			
		end
		
	elseif ( event == "HIDE_ON_SCENE_TRANSED") then
		if IsInYaoTaServer() == 0 and IsInCangWuServer() == 0 then
			this:Hide()
		end
		return	
	elseif ( event == "SHENQIPVP_ZHIYIN_OPNE") then			
		if tonumber(arg0) == 1 then
			this:Show()
		else
			this:Hide()
		end
	elseif (event == "ADJEST_UI_POS" ) then
		KVK_ShengQiPVP_ZhiYing_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		KVK_ShengQiPVP_ZhiYing_ResetPos()				
	end
	
end

function KVK_ShengQiPVP_ZhiYing_Frame_Mini_Clicked()
	PushEvent("SHENQIPVP_ZHIYIN_OPNE",  0 ,g_nType,g_nCeng)
end


function KVK_ShengQiPVP_ZhiYing_ResetPos()
	KVK_ShengQiPVP_ZhiYing_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition);
end