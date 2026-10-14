local g_ActivitySchedule_Choose_Frame_UnifiedPosition;  
local g_ActivitySchedule_Choose_Action ={    
}
local g_ActivitySchedule_Choose_Image ={    
}
local g_ActivitySchedule_Choose_Name ={    
}
local g_ActivitySchedule_Choose_Item ={
}
g_ActivitySchedule_Choose_Item[0] ={
    [1] = {id=20310168,num =5,},
    [2] = {id=38000378,num =3,}, -- 
    [3] = {id=20800033,num =5,},
    [4] = {id=38005288,num =2,},
}
g_ActivitySchedule_Choose_Item[1] ={
    [1] = {id=20310168,num =5,},
    [2] = {id=38001553,num =2,}, 
    [3] = {id=38000807,num =2,},
    [4] = {id=38005288,num =2,},
}
local g_ActivitySchedule_Choose_bagIndex = -1;
local g_ActivitySchedule_Choose_SelIndex = -1;
local g_ActivitySchedule_ItemType = -1;
function ActivitySchedule_Choose_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false); 
	this:RegisterEvent("ADJEST_UI_POS",false) 	 
end 

function ActivitySchedule_Choose_OnLoad()
    g_ActivitySchedule_Choose_Frame_UnifiedPosition	= ActivitySchedule_Choose_Frame:GetProperty("UnifiedPosition"); 
    g_ActivitySchedule_Choose_Action[1] = ActivitySchedule_Choose_Gift1_Icon	 
    g_ActivitySchedule_Choose_Action[2] = ActivitySchedule_Choose_Gift2_Icon	 
    g_ActivitySchedule_Choose_Action[3] = ActivitySchedule_Choose_Gift3_Icon	 
    g_ActivitySchedule_Choose_Action[4] = ActivitySchedule_Choose_Gift4_Icon	 
    g_ActivitySchedule_Choose_Image[1]  = ActivitySchedule_Choose_Gift1_Mask
    g_ActivitySchedule_Choose_Image[2]  = ActivitySchedule_Choose_Gift2_Mask
    g_ActivitySchedule_Choose_Image[3]  = ActivitySchedule_Choose_Gift3_Mask
    g_ActivitySchedule_Choose_Image[4]  = ActivitySchedule_Choose_Gift4_Mask
    g_ActivitySchedule_Choose_Name[1]  = ActivitySchedule_Choose_Gift1_Tips
    g_ActivitySchedule_Choose_Name[2]  = ActivitySchedule_Choose_Gift2_Tips
    g_ActivitySchedule_Choose_Name[3]  = ActivitySchedule_Choose_Gift3_Tips
    g_ActivitySchedule_Choose_Name[4]  = ActivitySchedule_Choose_Gift4_Tips
end

function ActivitySchedule_Choose_Frame_On_ResetPos()
  	ActivitySchedule_Choose_Frame:SetProperty("UnifiedPosition", g_ActivitySchedule_Choose_Frame_UnifiedPosition);
end

function ActivitySchedule_Choose_OnEvent(event)

	-- 离开游戏世界
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		ActivitySchedule_Choose_Close();
	end
  
    -- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		ActivitySchedule_Choose_Frame_On_ResetPos()
	end
		 
	--  
	if (event == "UI_COMMAND" and tonumber(arg0) == 88871501) then --Open
		if this:IsVisible() then
			ActivitySchedule_Choose_Close()
			return
		end 
		g_ActivitySchedule_ItemType = 0
		 ActivitySchedule_Choose_OnInitial(); 
		 this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 88871502) then --Open
		if this:IsVisible() then
			ActivitySchedule_Choose_Close()
			return
		end 
		
		g_ActivitySchedule_ItemType = 1
		ActivitySchedule_Choose_OnInitial(); 
		this:Show()
	end   
end 
----------------------------------------------------------------------------------
--
-- 关闭
--	
function ActivitySchedule_Choose_Close()  
	g_ActivitySchedule_Choose_bagIndex = -1;
	g_ActivitySchedule_Choose_SelIndex = -1;
	g_ActivitySchedule_ItemType = -1;
	this:Hide(); 
end 

function ActivitySchedule_Choose_OnInitial()    
	g_ActivitySchedule_Choose_bagIndex = -1;
	g_ActivitySchedule_Choose_SelIndex = -1;
	g_ActivitySchedule_Choose_bagIndex 	   = Get_XParam_INT(0) 
	if g_ActivitySchedule_Choose_Item[g_ActivitySchedule_ItemType] == nil then
		return
	end
    for i = 1, table.getn(g_ActivitySchedule_Choose_Item[g_ActivitySchedule_ItemType]) do
        local theAction = DataPool:CreateActionItemForShow(g_ActivitySchedule_Choose_Item[g_ActivitySchedule_ItemType][i].id, g_ActivitySchedule_Choose_Item[g_ActivitySchedule_ItemType][i].num)
	    if theAction:GetID() ~= 0 then
		    g_ActivitySchedule_Choose_Action[i]:SetActionItem(theAction:GetID());
		    g_ActivitySchedule_Choose_Action[i]:Show();
            g_ActivitySchedule_Choose_Name[i]:SetText(theAction:GetName())
        end
        g_ActivitySchedule_Choose_Image[i]:Hide()
    end	
end

function ActivitySchedule_Choose_Action_Click(index)
    for i = 1, table.getn(g_ActivitySchedule_Choose_Item[g_ActivitySchedule_ItemType]) do 
        g_ActivitySchedule_Choose_Image[i]:Hide()
    end	
    g_ActivitySchedule_Choose_Image[index]:Show()
    g_ActivitySchedule_Choose_SelIndex = index     
end

function ActivitySchedule_Choose_OnHiden()
    ActivitySchedule_Choose_Close()
end
function ActivitySchedule_Choose_Clicked()
	if g_ActivitySchedule_ItemType == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnChooseItem")
			Set_XSCRIPT_ScriptID(888715)
			Set_XSCRIPT_Parameter(0,g_ActivitySchedule_Choose_bagIndex); 
			Set_XSCRIPT_Parameter(1,g_ActivitySchedule_Choose_SelIndex); 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	elseif g_ActivitySchedule_ItemType == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnChooseItem")
			Set_XSCRIPT_ScriptID(888790)
			Set_XSCRIPT_Parameter(0,g_ActivitySchedule_Choose_bagIndex); 
			Set_XSCRIPT_Parameter(1,g_ActivitySchedule_Choose_SelIndex); 
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	end 
end
 