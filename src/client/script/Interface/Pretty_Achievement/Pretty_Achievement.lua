local adjest_pos
local frame -- for achievement content
local choice_item
local last_choice
local selected_level1 = nil
local level1s = {} -- res
local save_position = -1
local res_names = 
{
    [1] = {
        ["desc"] = "Pretty_Achievement_CoinAItem1_Num",
        ["name"] = "Pretty_Achievement_CoinAItem1_Name",
        ["score"] = "Pretty_Achievement_CoinAItem1_Score",
        ["proc"] = "Pretty_Achievement_CoinAItem1_Process",
        ["icon"] = "Pretty_Achievement_CoinAItem1_Icon",
        ["arrow"] = "Pretty_Achievement_CoinAItem1_Button",
        ["ach"] = "Pretty_Achievement_CoinAItem1_ProcessImage",
    },
    [2] = {
        ["desc"] = "Pretty_Achievement_CoinAItem1_Num",
        ["name"] = "Pretty_Achievement_CoinAItem1_Name",
        ["score"] = "Pretty_Achievement_CoinAItem1_Score",
        ["proc"] = "Pretty_Achievement_CoinAItem1_Process",
        ["icon"] = "Pretty_Achievement_CoinAItem1_Icon",
        ["arrow"] = "Pretty_Achievement_CoinAItem1_Button",
        ["ach"] = "Pretty_Achievement_CoinAItem1_ProcessImage",
    },
    [3] = {
        ["desc"] = "Pretty_Achievement_CoinAItem2_Num",
        ["score"] = "Pretty_Achievement_CoinAItem2_Score",
        ["proc"] = "Pretty_Achievement_CoinAItem2_Process",
        ["ach"] = "Pretty_Achievement_CoinAItem2_ProcessImage",
    }
}

local proc_msg =
{
    [0] = "0/1",
    [1] = "1/1",
}
local list_name =
{
    [1] = "Pretty_Achievement_CoinAItem1",
    [2] = "Pretty_Achievement_CoinAItem1",
    [3] = "Pretty_Achievement_CoinAItem2",
}
local cur_list =
{
    -- level, ach_idx, ach
    -- icon, name, score(or sum), prog, status(for level1, opened or closed)
    -- desc
}
local item_list=
{
}
local bigItem_list=
{
--[cur_list.index]=[bigchidindex]
}
local smallItem_list=
{
}
local enum_level =
{
    common  = 1,
    catalog = 2,
    child   = 3,
}

local enum_ach =
{
    realized   = 1,
    unrealized = 0,
}

local enum_status =
{
    closed = false,
    opened = true,
}

local enum_choice =
{
    all       = 0,
    actived   = 1,
    unactived = 2,
}
local offset=9;
local enableClick=false;
local enableTips=true;
local function update_red_point()
    if DataPool:Lua_IsRedPointInUIShow(26) == 1 then
        Pretty_Achievement_Shop_tips:Show()
    else
        Pretty_Achievement_Shop_tips:Hide()
	end
end

local function clean()
	selected_level1 = nil
	last_choice = nil
	cur_list = {}
	choice_item:ResetList()
	choice_item:ResetText()
	choice_item:ResetLastSelectIndex()
	--:frame:Clear()
	item_list=	{}
	bigItem_list={}
	smallItem_list={}	
end

local body_images =
{
    "set:Pretty01 image:Logo_01",
    "set:Pretty01 image:Logo_02",
    "set:Pretty01 image:Logo_03",
    "set:Pretty01 image:Logo_04",
    "set:Pretty01 image:Logo_05",
    "set:Pretty01 image:Logo_06",
    "set:Pretty01 image:Logo_07",
    "set:Pretty01 image:Logo_08",
    "set:Pretty01 image:Logo_09",
    "set:Pretty01 image:Logo_10",
    "set:Pretty01 image:Logo_11",
}

local arrow_image = {
	[1] = {"set:Pretty01 image:BtnDown_Pushed", "set:Pretty01 image:BtnDown_Normal", "set:Pretty01 image:BtnDown_Hover"},
	[2] = {"set:Pretty01 image:BtnUp_Pushed", "set:Pretty01 image:BtnUp_Normal", "set:Pretty01 image:BtnUp_Hover"},
}

local function choice_default() --筛选框
    Pretty_Achievement_Choice:ResetList()
    Pretty_Achievement_Choice:ResetText()
    Pretty_Achievement_Choice:ResetLastSelectIndex()
    Pretty_Achievement_Choice:AddTextItem("#{WGPF_191106_54}", enum_choice.all)
    Pretty_Achievement_Choice:AddTextItem("#{WGPF_191106_55}", enum_choice.actived)
    Pretty_Achievement_Choice:AddTextItem("#{WGPF_191106_56}", enum_choice.unactived)
    Pretty_Achievement_Choice:SetCurrentSelect(enum_choice.all)
end

function Pretty_Achievement_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_WG_ACHIEVEMENT")
	this:RegisterEvent("UPDATE_WG_ACHIEVEMENT")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI",false)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Pretty_Achievement_OnLoad()
	adjest_pos = Pretty_Achievement_Frame:GetProperty("UnifiedPosition")
    frame = Pretty_Achievement_Lace --选择框
    
    level1s = --左边页签
    {
        Pretty_Achievement_Dress,
        Pretty_Achievement_Peishi,
        Pretty_Achievement_Decore,
        Pretty_Achievement_Zinv,
        Pretty_Achievement_ZuoQi,
        Pretty_Achievement_Futi,
        Pretty_Achievement_Pet,
        Pretty_Achievement_Hair,
        Pretty_Achievement_Face,
		Pretty_Achievement_Beigua,
		Pretty_Achievement_Toushi,
    }

    choice_item = Pretty_Achievement_Choice --默认选择框
    choice_default()
end

local function make_icon(icon)
    local ret
	if icon then
		local pos1, pos2 = string.find(icon, "._%d+$")
		if pos1 then
			local fn = string.sub(icon, 0, pos1)
			ret = string.format("set:%s image:%s", fn, icon)
		end
	end
	return ret 
end

local function left_show()
    local text = Pretty_Achievement_TopStage
    local cur = WGAch:GetCJMaxCur()
    assert(type(cur) == "table")
    local max_value = WGAch:GetMaxVal()
    if cur.cur_level == cur.max_level then
        text:SetText(ScriptGlobal_Format("#{WGPF_191106_14}", cur.cur_value, max_value))
        Pretty_Achievement_ScoreEXP:SetProgress(cur.cur_value, cur.cur_value)

    else
        text:SetText(ScriptGlobal_Format("#{WGPF_191106_13}", cur.cur_value, cur.max_value))
        Pretty_Achievement_ScoreEXP:SetProgress(cur.cur_value, cur.max_value)
    end

    local image_bk = Pretty_Achievement_ImageBk
    image_bk:SetProperty("Image", body_images[cur.cur_level] or "")
    
    if cur.cur_level >= cur.max_level then
        Pretty_Achievement_TopStageRank:Show()
        Pretty_Achievement_TopStageRank:SetText("#{WGPF_210226_51}")
    else
    	Pretty_Achievement_TopStageRank:Show()
    	local nextlvName = ScriptGlobal_Format("#{WGPF_210226_20}", WGAch:GetLvName(cur.cur_level+1))
    	Pretty_Achievement_TopStageRank:SetText(nextlvName)
    end
   
    update_red_point()
end

--: !!!reloadscript =Pretty_Achievement  proc ：进度条   ach：已经达成
local function cur_show(choice,fixscroll)
	clean_SmallItem();
    assert(selected_level1)
    local fix_choice 
    if not choice then
        fix_choice = enum_choice.all
    else
        fix_choice = choice
    end

    left_show()
	--hide_all_poplist()
    local all_cnt = 0
    local actived_cnt = 0
    
    local oldScrollPos = frame:GetScrollPosition()
  
    local res_name, res_name3
    local cnt = table.getn(cur_list)
    for idx = 1, cnt do
        local item = cur_list[idx]
		local one=nil
		local frameListCount=frame:GetListItemCount();
        --if item.level == enum_level.common then
        --    if item.ach == enum_ach.realized then
        --        actived_cnt = actived_cnt + 1
        --    end

        --    all_cnt = all_cnt + 1
        --end
        --if item.level == enum_level.catalog then
        --    actived_cnt = actived_cnt + item.sum_ach
        --    all_cnt = all_cnt + table.getn(item.children)
        --end
        
        if item.level == enum_level.common then
        	if item.ach == enum_ach.realized then
        		actived_cnt = actived_cnt + item.score
        	end
        	all_cnt = all_cnt + item.score
        end
        
        if item.level == enum_level.catalog then
        	for i = 1, table.getn(item.children) do
        		if item.children[i].ach == enum_ach.realized then
        			actived_cnt = actived_cnt + item.children[i].score
        		end
        	end
        	all_cnt = all_cnt + item.score
        end

        if fix_choice == enum_choice.actived then
            if item.level == enum_level.common then
                if item.ach ~= enum_ach.realized then
					if idx<=frameListCount and frameListCount>=1 then
						one=frame:GetListItemAt(idx);
						one:Hide()					
					end
					continue
                end
            end
            if item.level == enum_level.catalog then
                if item.sum_ach == 0 then
					if idx<=frameListCount and frameListCount>=1 then
						one=frame:GetListItemAt(idx);
						one:Hide()					
					end
                    continue
                end
            end
        end

        if fix_choice == enum_choice.unactived then
            if item.level == enum_level.common then
                if item.ach ~= enum_ach.unrealized then
					if idx<=frameListCount and frameListCount>=1 then
						one=frame:GetListItemAt(idx);
						one:Hide()					
					end
                    continue
                end
            end
            if item.level == enum_level.catalog then
                if item.sum_ach == item.sum_count then
					if idx<=frameListCount and frameListCount>=1 then
						one=frame:GetListItemAt(idx);
						one:Hide()					
					end
                    continue
                end
            end
        end			
		
		if idx<=frameListCount and frameListCount>=1 then
			 one=frame:GetListItemAt(idx);
			 one:Show()
		else
			 one = frame:AddChild(list_name[item.level])
		end
		if one == nil then		
			continue;
		end
         
        res_name = res_names[item.level]
		one:RemoveEvent( "MouseLClick" )
		
		one:SetEvent("MouseLClick", string.format("PA_OnButton(%d)", idx))
		
        one:GetSubItem(res_name["arrow"]):Hide()
        one:GetSubItem(res_name["name"]):SetText("#cffe1b8" .. item.name)
        one:GetSubItem(res_name["desc"]):SetText(item.desc)
        if item.level == enum_level.catalog then
        	one:GetSubItem(res_name["score"]):SetText("#cffe1b8" .. item.active_score .. "/" .. item.score)
        else
        	one:GetSubItem(res_name["score"]):SetText("#cffe1b8" .. item.score)
        end
        if item.level == enum_level.common then
            if item.ach == enum_ach.realized then
                one:GetSubItem(res_name["ach"]):Show()
                one:GetSubItem(res_name["proc"]):Hide()
            else
                one:GetSubItem(res_name["ach"]):Hide()
                one:GetSubItem(res_name["proc"]):Show()
            end
        end
        --:PushDebugMessage(make_icon(item.icon))
        local icon = make_icon(item.icon)
        one:GetSubItem(res_name["icon"]):SetProperty("Image", icon)
        one:GetSubItem(res_name["proc"]):SetText("#cffe1b8" .. proc_msg[item.ach])
        if item.level == enum_level.catalog then
            if item.sum_count == item.sum_ach then
                one:GetSubItem(res_name["ach"]):Show()
                one:GetSubItem(res_name["proc"]):Hide()
            else
                one:GetSubItem(res_name["ach"]):Hide()
                one:GetSubItem(res_name["proc"]):Show()
            end
            one:GetSubItem(res_name["proc"]):SetText("#cffe1b8" .. item.sum_ach .. "/" .. item.sum_count) -- fix
			
			local addcount = 0
			if item.typemerge == 1 then
				for k, v in pairs(item.children) do					
					if v.ach ~= enum_ach.realized then
						continue
					end
					if last_choice ~= enum_choice.unactived then
						addcount = addcount + 1
					end
				end
			end
            if item.status == enum_status.opened then
                one:GetSubItem(res_name["arrow"]):SetProperty("PushedImage" , arrow_image[2][1])
                one:GetSubItem(res_name["arrow"]):SetProperty("NormalImage" , arrow_image[2][2])
                one:GetSubItem(res_name["arrow"]):SetProperty("HoverImage" , arrow_image[2][3])
				
				if addcount <= 0 and item.typemerge == 1 then
					one:GetSubItem(res_name["arrow"]):Hide()
				else
					one:GetSubItem(res_name["arrow"]):Show()
				end

                for k, v in pairs(item.children) do
                    if last_choice == enum_choice.actived and
                        v.ach ~= enum_ach.realized
                    then
                        continue
                    end
                    if last_choice == enum_choice.unactived and
                        v.ach ~= enum_ach.unrealized
                    then
                        continue
                    end
					
					if item.typemerge == 1 and v.ach ~= enum_ach.realized then
                        continue
					end

                    local child = frame:AddChild(list_name[v.level])

                    res_name = res_names[v.level]
                    child:GetSubItem(res_name["desc"]):SetText(v.desc)
                    child:GetSubItem(res_name["score"]):SetText("#cffe1b8" .. v.score)
                    child:GetSubItem(res_name["proc"]):SetText("#cffe1b8" .. proc_msg[v.ach])
                    if v.ach == enum_ach.realized then
                        child:GetSubItem(res_name["ach"]):Show()
                        child:GetSubItem(res_name["proc"]):Hide()
                    else
                        child:GetSubItem(res_name["ach"]):Hide()
                        child:GetSubItem(res_name["proc"]):Show()
                    end
                end
            else
                one:GetSubItem(res_name["arrow"]):SetProperty("PushedImage" , arrow_image[1][1])
                one:GetSubItem(res_name["arrow"]):SetProperty("NormalImage" , arrow_image[1][2])
                one:GetSubItem(res_name["arrow"]):SetProperty("HoverImage" , arrow_image[1][3])
				
				if addcount <= 0 and item.typemerge == 1 then
					one:GetSubItem(res_name["arrow"]):Hide()
				else
					one:GetSubItem(res_name["arrow"]):Show()
				end
            end
        end
    end
	local frameCount=frame:GetListItemCount();
	if cnt<frameCount then
		for i=1, frameCount do
			if  i > cnt then
				local bar =	frame:GetListItemAt(i)
				bar:Hide()
			end
		end
	end					
	frame:RefreshLayout()
    if fixscroll == 1 then
    	frame:SetScrollPosition(oldScrollPos)
	else 
		frame:SetScrollPosition(0)
    end

    Pretty_Achievement_JinDu_Text:SetText(ScriptGlobal_Format("#{WGPF_191106_29}",
                                        actived_cnt,
                                        all_cnt))
	refresh_BigItemBtn();
end

--!!!reloadscript =Pretty_Achievement
function PA_Select_Lv1(lv)
    
    if selected_level1 ~= nil then
    	if selected_level1 == lv then
    		save_position = 1
    	else
    		save_position = 0
    	end
    end
    
    selected_level1 = (lv or selected_level1) or 0
		for k, v in pairs(level1s) do
        v:SetCheck(0)
    end
    level1s[selected_level1+1]:SetCheck(1)
		
		last_choice = 0
		
    cur_list = WGAch:GetCfgByLv(selected_level1)
    table.sort(cur_list,function(a, b) return a.weight > b.weight end)
    local cnt = table.getn(cur_list)
    for idx = 1, cnt do
        local item = cur_list[idx]

        if item.children ~= nil then
            local function sortTale(a, b)
                return a.weight > b.weight
            end
            table.sort(cur_list[idx].children,sortTale)
        end
    end

    assert(type(cur_list) == "table")
    
    choice_default()

    cur_show(enum_choice.all, save_position)

end

function PA_Choice()
    local _, idx = choice_item:GetCurrentSelect()
    last_choice = idx
    cur_show(idx, 0)
end

function Pretty_Achievement_OnEvent(event)
    if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 172001 then
            this:Show()
            PA_Select_Lv1()
        end
    elseif event == "OPEN_WG_ACHIEVEMENT" then
        this:Show()
        PA_Select_Lv1()
    elseif event == "UPDATE_WG_ACHIEVEMENT" then
        if this:IsVisible() == false then
            return
        end
        assert(selected_level1)
        PA_Select_Lv1()
    elseif event == "UPDATE_REDPOINT_IN_UI" then
    		 update_red_point()
    elseif event == "UPDATE_REDPOINT_IN_UI_EX" then
    		update_red_point()
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
            event == "VIEW_RESOLUTION_CHANGED" then
                Pretty_Achievement_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end

function Pretty_Achievement_ResetPos()
    Pretty_Achievement_Frame:SetProperty("UnifiedPosition", adjest_pos)
end

function Pretty_Achievement_OnClosed()
    this:Hide()
    clean()
end

function Pretty_Achievement_OnHiden()
    Pretty_Achievement_OnClosed()
end

function PA_OnButton(idx)
    assert(idx)	
	local item = assert(cur_list[idx])
	if item.level ~= enum_level.catalog then
		return;
	end
	
	if enableClick then
		if enableTips then
			enableTips=false;
			PushDebugMessage( "#{WGPF_210226_52}" )			
		end			
		return;
	end
    
    if item.level == enum_level.catalog then
        item.status = not item.status	
		enableClick=true;
		SetTimer("Pretty_Achievement","Pretty_Achievement_SH_Timer()", 1000)
        cur_showlist(last_choice, 1,idx)
    end
end

function PA_Help()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(888051)
    Set_XSCRIPT_Function_Name("help")
    Set_XSCRIPT_Parameter(0, 1)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

function Pretty_Achievement_OpenShop()
    -- PushEvent("OPEN_WG_SHOP")
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(888051)
    Set_XSCRIPT_Function_Name("OpenShopUI")
    Set_XSCRIPT_Parameter(0, 1)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

function cur_showlist(choice,fixscroll,idx)
	local item = cur_list[idx]
	
	local res_name
	local parent =frame:GetListItemAt(bigItem_list[idx]);
	if parent==nil then
		return; 
	end
	res_name = res_names[item.level]
	if item.level == enum_level.catalog then
		if item.sum_count == item.sum_ach then
			parent:GetSubItem(res_name["ach"]):Show()
			parent:GetSubItem(res_name["proc"]):Hide()
		else
			parent:GetSubItem(res_name["ach"]):Hide()
			parent:GetSubItem(res_name["proc"]):Show()
		end
		parent:GetSubItem(res_name["proc"]):SetText("#cffe1b8" .. item.sum_ach .. "/" .. item.sum_count) -- fix
		
		local addcount = 0
		if item.typemerge == 1 then
			for k, v in pairs(item.children) do					
				if v.ach ~= enum_ach.realized then
					continue
				end
				if last_choice ~= enum_choice.unactived then
					addcount = addcount + 1
				end
			end
		end
		if item.status == enum_status.opened then	
			parent:GetSubItem(res_name["arrow"]):SetProperty("PushedImage" , arrow_image[2][1])
			parent:GetSubItem(res_name["arrow"]):SetProperty("NormalImage" , arrow_image[2][2])
			parent:GetSubItem(res_name["arrow"]):SetProperty("HoverImage" , arrow_image[2][3])
			
			if addcount <= 0 and item.typemerge == 1 then
				parent:GetSubItem(res_name["arrow"]):Hide()
			else
				parent:GetSubItem(res_name["arrow"]):Show()	
			end		
			
			local pos=1;		
			for k, v in pairs(item.children) do
				if last_choice == enum_choice.actived and
					v.ach ~= enum_ach.realized
				then
					continue
				end
				if last_choice == enum_choice.unactived and
					v.ach ~= enum_ach.unrealized
				then
					continue
				end	
				
				if item.typemerge == 1 and v.ach ~= enum_ach.realized then
					continue
				end
																
				local child = frame:AddChild2Item(list_name[v.level],bigItem_list[idx]+pos-1)
				child:Show()
				res_name = res_names[v.level]
				child:GetSubItem(res_name["desc"]):SetText(v.desc)
				child:GetSubItem(res_name["score"]):SetText("#cffe1b8" .. v.score)
				child:GetSubItem(res_name["proc"]):SetText("#cffe1b8" .. proc_msg[v.ach])
				if v.ach == enum_ach.realized then
					child:GetSubItem(res_name["ach"]):Show()
					child:GetSubItem(res_name["proc"]):Hide()
				else
					child:GetSubItem(res_name["ach"]):Hide()
					child:GetSubItem(res_name["proc"]):Show()
				end
				pos=pos+1;
			end	
									
		else
			parent:GetSubItem(res_name["arrow"]):SetProperty("PushedImage" , arrow_image[1][1])
			parent:GetSubItem(res_name["arrow"]):SetProperty("NormalImage" , arrow_image[1][2])
			parent:GetSubItem(res_name["arrow"]):SetProperty("HoverImage" , arrow_image[1][3])
			 
			if addcount <= 0 and item.typemerge == 1 then
				parent:GetSubItem(res_name["arrow"]):Hide()
			else
				parent:GetSubItem(res_name["arrow"]):Show()	
			end
			
			for  k, v in pairs(item.children) do
				if last_choice == enum_choice.actived and
					v.ach ~= enum_ach.realized
				then
					continue
				end
				if last_choice == enum_choice.unactived and
					v.ach ~= enum_ach.unrealized
				then
					continue
				end	
				
				if item.typemerge == 1 and v.ach ~= enum_ach.realized then
					continue
				end
				
				frame:EraseChild(bigItem_list[idx]+1);
			end
		end			
    end
		
    if fixscroll == 1 then
    	frame:SetScrollPosition(oldScrollPos)
	else 
		frame:SetScrollPosition(0)
    end
	refresh_BigItemBtn();
end


function refresh_BigItemBtn()
	local frameListCount=frame:GetListItemCount();
	local index=1;	
	bigItem_list={};
	if frameListCount>0 then
		for i=1,frameListCount do
			local bar =	frame:GetListItemAt(i)
			if bar then
				local count=bar:GetListItemCount()
				if count<9 then
					--smallitem	
				else
					--bigitem
					if index<=table.getn(cur_list) then
						bigItem_list[index]=i;--position
						index=index+1
					end					
				end	
			end	
		end
	end
end

function clean_SmallItem()
	local cnt = table.getn(cur_list)
	for idx = 1, cnt do
		local itemdata = cur_list[idx]
		if itemdata.level == enum_level.catalog then
			itemdata.status = enum_status.closed				
		end
	end
	
	local frameListCount=frame:GetListItemCount();	
	if frameListCount>0 then
		for i=1,frameListCount do
			local bar =	frame:GetListItemAt(i)
			if bar then
				local count=bar:GetListItemCount()
				if count<9 then
					frame:EraseChild(i);										
					clean_SmallItem();
				end	
			end						
		end
	end		
		
end
	
function Pretty_Achievement_SH_Timer()
	enableClick=false;
	enableTips=true;
	KillTimer("Pretty_Achievement_SH_Timer()")
end	