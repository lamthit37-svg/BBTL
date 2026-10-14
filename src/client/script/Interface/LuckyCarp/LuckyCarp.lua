--=========================================================
-- 锦鲤榜
--=========================================================
--控件列表
local m_Controls = {} 				--控件列表
local g_Frame_UnifiedPosition
-- local g_BarList = {}

--滚动条的位置
local g_Position_Scroll = 0;

local g_LuckyCarp_Event = 
{
    -- 1 洛阳
    [1] = {begtime=20210422, endtime =20210512, level =30,},
    -- 2 苏州
    [2] = {begtime=20210422, endtime =20210512, level =30,},
    -- 3 大理
    [3] = {begtime=20210422, endtime =20210512, level =30,},

};

-- NPC寻路信息
local g_infoNPCGoto     = 
{
    [1] = {nSceneID = 0, nPosX = 295, nPosY = 259},--0 = 洛阳 A送花灯 
    [2] = {nSceneID = 2, nPosX = 134, nPosY = 244},--2 = 大理 B咏花词
    [3] = {nSceneID = 1, nPosX = 298, nPosY = 283},--1 = 苏州 C赏春红
}

local jlb_image = 
{  
    [1] = "SongHuaDeng_Title",--A送花灯
    [2] = "ShangChunHong_Title",--C赏春红
    [3] = "YongHuaCi_Title",--B咏花词 
    [4] = "DengRuZhou_Title",--D许灯愿
}

function LuckyCarp_PreLoad()

    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("ADJEST_UI_POS",false)           -- 游戏窗口尺寸发生了变化
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)		    -- 离开场景
    this:RegisterEvent("UPDATE_LUCKYCARP_NAME",false )

end

function LuckyCarp_OnLoad()

    m_Controls = 
    {
		m_Frame = LuckyCarp_Frame,
    }
    
    g_Frame_UnifiedPosition=m_Controls.m_Frame:GetProperty("UnifiedPosition")

end

function LuckyCarp_OnEvent(event)

    if ( event == "UI_COMMAND" and tonumber(arg0) == 88839001 ) then
        local isOn = Get_XParam_INT(0) --是否播放烟花
        if isOn == 1 then
            LuckyCarp_AmiateBig:Play(true)
            LuckyCarp_AmiateBig2:Play(true)
            LuckyCarp_AmiateBig3:Play(true)
            LuckyCarp_AmiateSmall:Play(true)
            LuckyCarp_AmiateSmall2:Play(true)
            LuckyCarp_AmiateSmall3:Play(true)
            LuckyCarp_Show()
            this:Show()
        else
            LuckyCarp_AmiateBig:Play(false)
            LuckyCarp_AmiateBig2:Play(false)
            LuckyCarp_AmiateBig3:Play(false)
            LuckyCarp_AmiateSmall:Play(false)
            LuckyCarp_AmiateSmall2:Play(false)
            LuckyCarp_AmiateSmall3:Play(false)
            LuckyCarp_Show()
            this:Show()
        end
    elseif (event == "ADJEST_UI_POS") then
		LuckyCarp_Frame_On_ResetPos()    
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
        LuckyCarp_Frame_On_ResetPos()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        LuckyCarp_OnClosed()
    elseif(event == "UPDATE_LUCKYCARP_NAME") then
        local jlb_data   = 
        { 
            [1] = {arg0,arg2,arg4,arg6,arg8,arg10,arg12,arg14,arg16,arg18},
            [2] = {arg1,arg3,arg5,arg7,arg9,arg11,arg13,arg15,arg17,arg19},
        }
        LuckyCarp_NAME_Update(jlb_data)
    end
    
end

function LuckyCarp_Frame_On_ResetPos()
    m_Controls.m_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--===============================================
-- Close()
--===============================================
function LuckyCarp_OnClosed()
	
	this:Hide()
end

function LuckyCarp_Help()
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("ShowHelpText")
        Set_XSCRIPT_ScriptID( 888388 )
        Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

function LuckyCarp_OnHiden()
    this:Hide()
end
--===============================================
-- 寻路
--===============================================
function LuckyCarp_Clicked( clickId )
    --clickId 1 = 2 = 3 = 点击寻路

    local subEvent  = g_LuckyCarp_Event[clickId]
    if nil == subEvent then
        PushDebugMessage("非法按钮")
        return
    end

    local nCurDay = DataPool:GetServerDayTime()
    if nCurDay < subEvent.begtime or nCurDay > subEvent.endtime then
            if clickId == 1 then
                PushDebugMessage("#{JLB_210311_13}")--A送花灯
            elseif clickId == 2 then
                PushDebugMessage("#{JLB_210311_25}")--B咏花词
            elseif clickId == 3 then
                PushDebugMessage("#{JLB_210311_26}")--C赏春红
            end  
        return
    end

    local nLevel = Player:GetLevel();
    if nLevel < 30 then
        PushDebugMessage("#{JLB_210311_14}")
        return
    end

    local bRet = AutoRunToTargetEx(g_infoNPCGoto[clickId].nPosX, g_infoNPCGoto[clickId].nPosY, g_infoNPCGoto[clickId].nSceneID)

    if 0 == bRet then
        PushDebugMessage("无法自动寻路")
        return
    end

    --PushDebugMessage("#{JSCE_200729_34}")
    --LuckyCarp_OnClosed() 

	return
end

function LuckyCarp_Show()
    DataPool:Lua_AskLuckyCarpRankName()
end

--===============================================
-- 显示获奖名单
--===============================================
function LuckyCarp_NAME_Update(jlb_data)
    local num_tick = 0;
    LuckyCarp_Lace:Clear()

    if jlb_data[1][10] == "" then --灯如昼未上榜时
        for i = 1, 10 do
            local bar = LuckyCarp_Lace:AddChild("LuckyCarp_Item1")
            if jlb_data[1][i] == "" then --当前段位无人上榜
                bar:GetSubItem("LuckyCarp_PicLucky"):Hide();--上榜红花
                bar:GetSubItem("LuckyCarp_Item1_Name"):Hide();--用户名
                bar:GetSubItem("LuckyCarp_Item1_NameNO"):Show();--虚位以待
                bar:GetSubItem("LuckyCarp_PicBang"):Hide();--事件尾标
                bar:GetSubItem("LuckyCarp_AmiateBK"):Play(false);--框体特效动画
                -- g_BarList[i] = bar	
            else
                bar:GetSubItem("LuckyCarp_PicLucky"):Show();--上榜红花
                bar:GetSubItem("LuckyCarp_Item1_Name"):SetText("#L"..tostring(jlb_data[1][i]))
                bar:GetSubItem("LuckyCarp_Item1_Name"):Show();--用户名
                bar:GetSubItem("LuckyCarp_Item1_NameNO"):Hide();--虚位以待
                bar:GetSubItem("LuckyCarp_PicBang"):SetImage("LuckyCarp",jlb_image[jlb_data[2][i]+1])
                bar:GetSubItem("LuckyCarp_PicBang"):Show();--事件尾标
                bar:GetSubItem("LuckyCarp_AmiateBK"):Play(false);--框体特效动画
                if Player:GetName() == tostring(jlb_data[1][i]) then
                    bar:GetSubItem("LuckyCarp_AmiateBK"):Play(true);--框体特效动画
                end
                num_tick = num_tick + 1;
                -- g_BarList[i] = bar	
            end
        end
    else
        local bar = LuckyCarp_Lace:AddChild("LuckyCarp_Item1")
        bar:GetSubItem("LuckyCarp_PicLucky"):Show();--上榜红花
        bar:GetSubItem("LuckyCarp_Item1_Name"):SetText("#L"..tostring(jlb_data[1][10]))
        bar:GetSubItem("LuckyCarp_Item1_Name"):Show();--用户名
        bar:GetSubItem("LuckyCarp_Item1_NameNO"):Hide();--虚位以待
        bar:GetSubItem("LuckyCarp_PicBang"):SetImage("LuckyCarp",jlb_image[4])
        bar:GetSubItem("LuckyCarp_PicBang"):Show();--事件尾标
        bar:GetSubItem("LuckyCarp_AmiateBK"):Play(false);--框体特效动画
        if Player:GetName() == tostring(jlb_data[1][10]) then
            bar:GetSubItem("LuckyCarp_AmiateBK"):Play(true);--框体特效动画
        end
        num_tick = num_tick + 1;
    for i = 1, 9 do
            local bar = LuckyCarp_Lace:AddChild("LuckyCarp_Item1")
            if jlb_data[1][i] == "" then
                bar:GetSubItem("LuckyCarp_PicLucky"):Hide();--上榜红花
                bar:GetSubItem("LuckyCarp_Item1_Name"):Hide();--用户名
                bar:GetSubItem("LuckyCarp_Item1_NameNO"):Show();--虚位以待
                bar:GetSubItem("LuckyCarp_PicBang"):Hide();--事件尾标
                bar:GetSubItem("LuckyCarp_AmiateBK"):Play(false);--框体特效动画
                -- g_BarList[i] = bar	
            else
                bar:GetSubItem("LuckyCarp_PicLucky"):Show();--上榜红花
                bar:GetSubItem("LuckyCarp_Item1_Name"):SetText("#L"..tostring(jlb_data[1][i]))
                bar:GetSubItem("LuckyCarp_Item1_Name"):Show();--用户名
                bar:GetSubItem("LuckyCarp_Item1_NameNO"):Hide();--虚位以待
                bar:GetSubItem("LuckyCarp_PicBang"):SetImage("LuckyCarp",jlb_image[jlb_data[2][i]+1])
                bar:GetSubItem("LuckyCarp_PicBang"):Show();--事件尾标
                bar:GetSubItem("LuckyCarp_AmiateBK"):Play(false);--框体特效动画
                if Player:GetName() == tostring(jlb_data[1][i]) then
                    bar:GetSubItem("LuckyCarp_AmiateBK"):Play(true);--框体特效动画
                end
                num_tick = num_tick + 1;
                -- g_BarList[i] = bar	
            end
        end
    end

    LuckyCarp_TextLeftNum:SetText( ScriptGlobal_Format("#{JLB_210311_24}", num_tick))

    --设置滚动条位置
    for i = 1, 9 do
        if Player:GetName() == tostring(jlb_data[1][i]) then
            if i >= 5 and i < 8 then
                g_Position_Scroll = 4
                LuckyCarp_Lace:SetScrollPosition4Index(g_Position_Scroll)
            elseif i >= 8 then
                g_Position_Scroll = 5
                LuckyCarp_Lace:SetScrollPosition4Index(g_Position_Scroll)
            end
        end
    end

end

--===============================================
-- Tips
--===============================================
-- function LuckyCarp_Tips(jlb_data)
--     g_Anniversary_Guide_Button[index]:SetToolTip(event.btntips[i])
--     g_Anniversary_Guide_Button[index]:SetToolTip(event.btntips[i])
--     g_Anniversary_Guide_Button[index]:SetToolTip(event.btntips[i])
-- end