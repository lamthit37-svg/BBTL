local g_nBagIndex = -1    		--背包中的位置 
local g_nItemIndex = -1   		--物品ID 
local g_nServerScriptID = -1    --服务器脚本号
local g_strServerFunName = ""   --服务器函数名
local g_nSelectID = -1    --选中pet
local g_nSelectPetID = -1    --选中pet

local g_strMsg = {
												"#{ZBSJL_160826_10}",
												"#{ZBSJL_160826_08}",
												"#{ZBSJL_160826_11}",
												"#{ZBSJL_160826_09}",
											
										
											}

function CorpsMatch_Pet_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ZHENGBASAI_PET_CONFIRM_OK");

end

function CorpsMatch_Pet_OnLoad()


	--7级选择
	CorpsMatch_PetPick_Clinet1_ALLChoice:ComboBoxAddItem("尚未选择",0);
	CorpsMatch_PetPick_Clinet1_ALLChoice:ComboBoxAddItem("忠诚性格",1);
	CorpsMatch_PetPick_Clinet1_ALLChoice:ComboBoxAddItem("谨慎性格",2);
	--8级选择
	CorpsMatch_PetPick_Clinet2_ALLChoice:ComboBoxAddItem("尚未选择",0);
	CorpsMatch_PetPick_Clinet2_ALLChoice:ComboBoxAddItem("忠诚性格",1);
	CorpsMatch_PetPick_Clinet2_ALLChoice:ComboBoxAddItem("谨慎性格",2);
	
end

function CorpsMatch_Pet_OnEvent(event)

 
	if(event == "UI_COMMAND" and tonumber(arg0) == 20160829) then
  
		g_nBagIndex = Get_XParam_INT(0)
		g_nItemIndex = Get_XParam_INT(1)
  	g_nServerScriptID = Get_XParam_INT(2)
 		g_strServerFunName = Get_XParam_STR(0)
    
   
   CorpsMatch_PetPick_Clinet1_ALLChoice:SetCurrentSelect(0) 
   CorpsMatch_PetPick_Clinet2_ALLChoice:SetCurrentSelect(0)   
   
    g_nSelectPetID  = -1  
    this:Show();
  elseif event == "HIDE_ON_SCENE_TRANSED"  then
		this:Hide()
 	elseif event == "ZHENGBASAI_PET_CONFIRM_OK"  then
		CorpsMatch_Pet_OK()
  end
			
end


function CorpsMatch_Pet_Close()
	this:Hide();
end

function CorpsMatch_Pet_Select_OK(index)
	
	if index ~= 0 and index ~= 1 then
		return
	end
	
	if index == 0  then
		local szPet,nPet = CorpsMatch_PetPick_Clinet1_ALLChoice:GetCurrentSelect();
		
		if nPet == 0 then
			PushDebugMessage("#{ZBSJL_160826_19}")
			return
		end
		
		if nPet == 1 then
			g_nSelectPetID = 1
		else
			g_nSelectPetID = 3
		end
		
	end
	
	if index == 1  then
		local szPet,nPet = CorpsMatch_PetPick_Clinet2_ALLChoice:GetCurrentSelect();
		
		if nPet == 0 then
			PushDebugMessage("#{ZBSJL_160826_19}")
			return
		end
		
		if nPet == 1 then
			g_nSelectPetID = 2
		else
			g_nSelectPetID = 4
		end
		
	end
		
	PushEvent("ZHENGBASAI_PET_CONFIRM", g_strMsg[g_nSelectPetID]);
end

function CorpsMatch_Pet_OK()
	
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