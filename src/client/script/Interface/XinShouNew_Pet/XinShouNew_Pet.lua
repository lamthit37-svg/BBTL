local g_XinShouNew_Pet_Frame_UnifiedPosition;
local g_nBagIndex = -1    		--背包中的位置 
local g_nItemIndex = -1   		--物品ID 
local g_nServerScriptID = -1    --服务器脚本号
local g_strServerFunName = ""   --服务器函数名
local g_nSelectID = -1    --选中pet
local g_nSelectPetID = -1    --选中pet

local g_strMsg = {
		[38002172] = {
			"#{LMLH_180123_13}",
			"#{LMLH_180123_15}",
			"#{LMLH_180123_14}",
			"#{LMLH_180123_16}",
		},
		[38006013] = {
			"#{BJKJ_220701_30}",
			"#{LMLH_180123_13}",
			"#{BJKJ_220701_39}",
			"#{LMLH_180123_14}",
		},
		[38006014] = {
			"#{LMLH_180123_13}",
			"#{LMLH_180123_15}",
			"#{LMLH_180123_14}",
			"#{LMLH_180123_16}",
		}, 							
	}

function XinShouNew_Pet_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("HAOXIA_PET_CONFIRM_OK");
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function XinShouNew_Pet_OnLoad()


	--7级选择
	XinShouNew_Pet_LQClinet1_ALLChoice:ComboBoxAddItem("尚未选择",0);
	XinShouNew_Pet_LQClinet1_ALLChoice:ComboBoxAddItem("忠诚性格",1);
	XinShouNew_Pet_LQClinet1_ALLChoice:ComboBoxAddItem("谨慎性格",2);
	--8级选择
	XinShouNew_Pet_LQClinet2_ALLChoice:ComboBoxAddItem("尚未选择",0);
	XinShouNew_Pet_LQClinet2_ALLChoice:ComboBoxAddItem("忠诚性格",1);
	XinShouNew_Pet_LQClinet2_ALLChoice:ComboBoxAddItem("谨慎性格",2);
	g_XinShouNew_Pet_Frame_UnifiedPosition=XinShouNew_Pet_Frame:GetProperty("UnifiedPosition");
end

function XinShouNew_Pet_OnEvent(event)
 
	if(event == "UI_COMMAND" and tonumber(arg0) == 892681) then
  
		g_nBagIndex = Get_XParam_INT(0)
		g_nItemIndex = Get_XParam_INT(1) 
		g_nServerScriptID = Get_XParam_INT(2)
 		g_strServerFunName = Get_XParam_STR(0)
    
   
   XinShouNew_Pet_LQClinet1_ALLChoice:SetCurrentSelect(0) 
   XinShouNew_Pet_LQClinet2_ALLChoice:SetCurrentSelect(0)   
   
	g_nSelectPetID  = -1  
	XinShouNew_Pet_OnShoW()
    this:Show();
  elseif event == "HIDE_ON_SCENE_TRANSED"  then
		this:Hide()
 	elseif event == "HAOXIA_PET_CONFIRM_OK"  then
		XinShouNew_Pet_OK()
	elseif (event == "ADJEST_UI_POS" ) then
		XinShouNew_Pet_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
  end
			
end


function XinShouNew_Pet_Close()
	this:Hide();
end

function XinShouNew_Pet_OnShoW()
	if g_nItemIndex == 38002172 then  -- 78
		XinShouNew_Pet_Info_text:SetText("#{LMLH_180123_05}")
		XinShouNew_Pet_Button1:SetText("#{LMLH_180123_06}")
		XinShouNew_Pet_Button2:SetText("#{LMLH_180123_07}") 
		XinShouNew_Pet_Pet1_image:SetProperty("Image", "set:XSYNewBK09 image:XSYNew_LMLH_1") 
		XinShouNew_Pet_Pet2_image:SetProperty("Image", "set:XSYNewBK09 image:XSYNew_LMLH_2")  
	elseif g_nItemIndex == 38006013 then -- 67 
		XinShouNew_Pet_Info_text:SetText("#{BJKJ_220701_24}")
		XinShouNew_Pet_Button1:SetText("#{BJKJ_220701_38}")
		XinShouNew_Pet_Button2:SetText("#{LMLH_180123_06}")		
		XinShouNew_Pet_Pet1_image:SetProperty("Image", "set:XSYNewBK11 image:XSYNew_WHLM6") 
		XinShouNew_Pet_Pet2_image:SetProperty("Image", "set:XSYNewBK09 image:XSYNew_LMLH_1")   
	elseif g_nItemIndex == 38006014 then -- 78 
		XinShouNew_Pet_Info_text:SetText("#{BJKJ_220701_25}")
		XinShouNew_Pet_Button1:SetText("#{LMLH_180123_06}")
		XinShouNew_Pet_Button2:SetText("#{LMLH_180123_07}")
		XinShouNew_Pet_Pet1_image:SetProperty("Image", "set:XSYNewBK09 image:XSYNew_LMLH_1") 
		XinShouNew_Pet_Pet2_image:SetProperty("Image", "set:XSYNewBK09 image:XSYNew_LMLH_2")    
	end
end

function XinShouNew_Pet_Select_OK(index)
	
	if index ~= 0 and index ~= 1 then
		return
	end
	
	if index == 0  then
		local szPet,nPet = XinShouNew_Pet_LQClinet1_ALLChoice:GetCurrentSelect();
		
		if nPet == 0 then
			PushDebugMessage("#{LMLH_180123_12}")
			return
		end
		
		if nPet == 1 then
			g_nSelectPetID = 1
		else
			g_nSelectPetID = 3
		end
		
	end
	
	if index == 1  then
		local szPet,nPet = XinShouNew_Pet_LQClinet2_ALLChoice:GetCurrentSelect();
		
		if nPet == 0 then
			PushDebugMessage("#{LMLH_180123_12}")
			return
		end
		
		if nPet == 1 then
			g_nSelectPetID = 2
		else
			g_nSelectPetID = 4
		end
		
	end
		
	PushEvent("HAOXIA_PET_CONFIRM", g_strMsg[g_nItemIndex][g_nSelectPetID]);
end

function XinShouNew_Pet_OK()
	
	if g_nSelectPetID < 1 or g_nSelectPetID > 4 then
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name(g_strServerFunName)
		Set_XSCRIPT_ScriptID(g_nServerScriptID)
		Set_XSCRIPT_Parameter(0,g_nBagIndex)
		Set_XSCRIPT_Parameter(1,g_nItemIndex)
		Set_XSCRIPT_Parameter(2,g_nSelectPetID)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT();
	
	this:Hide()
end


function XinShouNew_Pet_OnHiden()

 g_nBagIndex = -1    		--背包中的位置 
 g_nItemIndex = -1   		--物品ID 
 g_nServerScriptID = -1    --服务器脚本号
 g_strServerFunName = ""   --服务器函数名
 g_nSelectID = -1    --选中pet
 g_nSelectPetID = -1    --选中pet
	this:Hide();

end
--================================================
-- 恢复界面的默认相对位置
--================================================
function XinShouNew_Pet_Frame_On_ResetPos()
  XinShouNew_Pet_Frame:SetProperty("UnifiedPosition", g_XinShouNew_Pet_Frame_UnifiedPosition);
end
