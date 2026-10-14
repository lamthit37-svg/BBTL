
local g_Jueqing_Fuchi_nSelectIndex = 0;
local g_Jueqing_Fuchi_checkBox_icons = {} 
local g_Jueqing_Fuchi_checkBox_text = {} 
local g_Jueqing_Fuchi_checkBox_btn = {} 
local g_Jueqing_Fuchi_cTitle;
local g_Jueqing_Fuchi_cInfo;

local g_Jueqing_Fuchi_itemids = 
{
	[7] =  {{id=39923725,text ="#{JQGFC_220115_170}",},{id=39923727,text="#{JQGFC_220115_167}", num =4000,},{id=39923729, text="#{JQGFC_220115_167}",num=11000,}, },
	[8] =  {{id=39923725,text ="#{JQGFC_220115_170}",},{id=39923727,text="#{JQGFC_220115_167}", num =4000,},{id=39923729, text="#{JQGFC_220115_167}",num=11000,}, },
	[9] =  {{id=39923725,text ="#{JQGFC_220115_170}",},{id=39923727,text="#{JQGFC_220115_167}", num =4000,},{id=39923729, text="#{JQGFC_220115_167}",num=11000,}, },
	[10] = {{id=39923725,text ="#{JQGFC_220115_170}",},{id=39923727,text="#{JQGFC_220115_167}", num =4000,},{id=39923729, text="#{JQGFC_220115_167}",num=11000,}, },
	[11] = {{id=39923725,text ="#{JQGFC_220115_170}",},{id=39923727,text="#{JQGFC_220115_167}", num =4000,},{id=39923729, text="#{JQGFC_220115_167}",num=11000,}, },
	[12] = {{id=39923725,text ="#{JQGFC_220115_170}",},{id=39923727,text="#{JQGFC_220115_167}", num =4000,},{id=39923729, text="#{JQGFC_220115_167}",num=11000,}, },
	[13] = {{id=39923725,text ="#{JQGFC_220115_170}",},{id=39923727,text="#{JQGFC_220115_167}", num =4000,},{id=39923729, text="#{JQGFC_220115_167}",num=11000,}, },
	[14] = {{id=39923726,text ="#{JQGFC_220115_170}",},{id=39923728,text="#{JQGFC_220115_167}", num =4000,},{id=39923730, text="#{JQGFC_220115_167}",num=11000,}, },
	
	[15] = {{id=39923731,text ="#{JQGFC_220115_170}",},{id=39923733,text="#{JQGFC_220115_167}", num =4000,},{id=39923735, text="#{JQGFC_220115_167}",num=17000,}, },
	[16] = {{id=39923731,text ="#{JQGFC_220115_170}",},{id=39923733,text="#{JQGFC_220115_167}", num =4000,},{id=39923735, text="#{JQGFC_220115_167}",num=17000,}, },
	[17] = {{id=39923731,text ="#{JQGFC_220115_170}",},{id=39923733,text="#{JQGFC_220115_167}", num =4000,},{id=39923735, text="#{JQGFC_220115_167}",num=17000,}, },
	[18] = {{id=39923731,text ="#{JQGFC_220115_170}",},{id=39923733,text="#{JQGFC_220115_167}", num =4000,},{id=39923735, text="#{JQGFC_220115_167}",num=17000,}, },
	[19] = {{id=39923731,text ="#{JQGFC_220115_170}",},{id=39923733,text="#{JQGFC_220115_167}", num =4000,},{id=39923735, text="#{JQGFC_220115_167}",num=17000,}, },
	[20] = {{id=39923731,text ="#{JQGFC_220115_170}",},{id=39923733,text="#{JQGFC_220115_167}", num =4000,},{id=39923735, text="#{JQGFC_220115_167}",num=17000,}, },
	[21] = {{id=39923731,text ="#{JQGFC_220115_170}",},{id=39923733,text="#{JQGFC_220115_167}", num =4000,},{id=39923735, text="#{JQGFC_220115_167}",num=17000,}, },
	[22] = {{id=39923732,text ="#{JQGFC_220115_170}",},{id=39923734,text="#{JQGFC_220115_167}", num =4000,},{id=39923736, text="#{JQGFC_220115_167}",num=17000,}, },
	
	[23] = {{id=39923737,text ="#{JQGFC_220115_170}",},{id=39923738,text="#{JQGFC_220115_167}", num =6000,},{id=39923739, text="#{JQGFC_220115_167}",num=16500,}, },
	[24] = {{id=39923737,text ="#{JQGFC_220115_170}",},{id=39923738,text="#{JQGFC_220115_167}", num =6000,},{id=39923739, text="#{JQGFC_220115_167}",num=16500,}, },
	[25] = {{id=39923737,text ="#{JQGFC_220115_170}",},{id=39923738,text="#{JQGFC_220115_167}", num =6000,},{id=39923739, text="#{JQGFC_220115_167}",num=16500,}, },
	[26] = {{id=39923737,text ="#{JQGFC_220115_170}",},{id=39923738,text="#{JQGFC_220115_167}", num =6000,},{id=39923739, text="#{JQGFC_220115_167}",num=16500,}, },
	[27] = {{id=39923737,text ="#{JQGFC_220115_170}",},{id=39923738,text="#{JQGFC_220115_167}", num =6000,},{id=39923739, text="#{JQGFC_220115_167}",num=16500,}, },
	[28] = {{id=39923737,text ="#{JQGFC_220115_170}",},{id=39923738,text="#{JQGFC_220115_167}", num =6000,},{id=39923739, text="#{JQGFC_220115_167}",num=16500,}, },
	[29] = {{id=39923737,text ="#{JQGFC_220115_170}",},{id=39923738,text="#{JQGFC_220115_167}", num =6000,},{id=39923739, text="#{JQGFC_220115_167}",num=16500,}, },
	[30] = {{id=39923737,text ="#{JQGFC_220115_170}",},{id=39923738,text="#{JQGFC_220115_167}", num =6000,},{id=39923739, text="#{JQGFC_220115_167}",num=16500,}, },
} 
--===============================================
-- PreLoad()
--===============================================
function Jueqing_Fuchi_Select_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		--进场景关闭界面
end

--===============================================
-- OnLoad()
--===============================================
function Jueqing_Fuchi_Select_OnLoad() 
	g_Jueqing_Fuchi_checkBox_icons[1] = Jueqing_Fuchi_Select_Lace1_Icon
	g_Jueqing_Fuchi_checkBox_icons[2] = Jueqing_Fuchi_Select_Lace2_Icon
	g_Jueqing_Fuchi_checkBox_icons[3] = Jueqing_Fuchi_Select_Lace3_Icon  

	g_Jueqing_Fuchi_checkBox_text[1] = Jueqing_Fuchi_Select_Lace1_text1
	g_Jueqing_Fuchi_checkBox_text[2] = Jueqing_Fuchi_Select_Giftbox_text1
	g_Jueqing_Fuchi_checkBox_text[3] = Jueqing_Fuchi_Select_Lace3_text1

	g_Jueqing_Fuchi_checkBox_btn[1] = Jueqing_Fuchi_Select_ReFresh_Btn
	g_Jueqing_Fuchi_checkBox_btn[2] = Jueqing_Fuchi_Select_ReFresh_Btn2
	g_Jueqing_Fuchi_checkBox_btn[3] = Jueqing_Fuchi_Select_ReFresh_Btn3
end

function Jueqing_Fuchi_Select_UpdateUI()
	Jueqing_Fuchi_Select_DragTitle:SetText("#{JQGFC_220115_166}")
	for i, v in pairs(g_Jueqing_Fuchi_checkBox_icons) do 
		local theAction = DataPool:CreateActionItemForShow(g_Jueqing_Fuchi_itemids[g_Jueqing_Fuchi_nSelectIndex][i].id, 1)
		if theAction:GetID() ~= 0 then
			v:SetActionItem(theAction:GetID());			
			g_Jueqing_Fuchi_checkBox_text[i]:SetText("#L"..theAction:GetName()) 
			v:Show();
		else
			v:SetActionItem(-1);
			v:Hide()
		end
		local num = g_Jueqing_Fuchi_itemids[g_Jueqing_Fuchi_nSelectIndex][i].num  		
		if num == nil then
			g_Jueqing_Fuchi_checkBox_btn[i]:SetText(g_Jueqing_Fuchi_itemids[g_Jueqing_Fuchi_nSelectIndex][i].text) 
		else			
			g_Jueqing_Fuchi_checkBox_btn[i]:SetText(ScriptGlobal_Format(g_Jueqing_Fuchi_itemids[g_Jueqing_Fuchi_nSelectIndex][i].text, num))
		end
	end
	 
end

--===============================================
-- OnEvent()
--===============================================
function Jueqing_Fuchi_Select_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 88892103 ) then
		g_Jueqing_Fuchi_nSelectIndex = tonumber(arg1)  
        if g_Jueqing_Fuchi_nSelectIndex == nil or g_Jueqing_Fuchi_nSelectIndex < 1 or g_Jueqing_Fuchi_itemids[g_Jueqing_Fuchi_nSelectIndex] == nil then
            Jueqing_Fuchi_Select_OnClose();
            return
        end
		if this:IsVisible() then
			Jueqing_Fuchi_Select_OnClose();
		else
			Jueqing_Fuchi_Select_UpdateUI()
			this:Show();
		end
	end 
	if event == "HIDE_ON_SCENE_TRANSED" then
		Jueqing_Fuchi_Select_OnClose()
	end
end

function Jueqing_Fuchi_Select_Buy(idx)    
	Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "BuyGift" ); 					-- 脚本函数名称
    Set_XSCRIPT_ScriptID( 888922 );											-- 脚本编号
    Set_XSCRIPT_Parameter( 0, g_Jueqing_Fuchi_nSelectIndex);	   
    Set_XSCRIPT_Parameter( 1, idx);	   
    Set_XSCRIPT_Parameter( 2, 0);	 
    Set_XSCRIPT_ParamCount( 3 ); 	-- 参数个数 
    Send_XSCRIPT() 
end

function Jueqing_Fuchi_Select_LingQu(idx)    
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name( "GetGift" ); 					-- 脚本函数名称
    Set_XSCRIPT_ScriptID( 888922 );											-- 脚本编号  
    Set_XSCRIPT_Parameter( 0, g_Jueqing_Fuchi_nSelectIndex);	 
    Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数  
    Send_XSCRIPT()	
end

function Jueqing_Fuchi_Select_OnClose() 
	this:Hide();
end
