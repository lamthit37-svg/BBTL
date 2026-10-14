
local g_Frame_UnifiedPosition = nil
local g_ExeScript = 998353
local g_UICOMMAND = 99835301
local g_DefaultText = {
    "观尽漫山飞红叶，不及伊人半抬眸。",
    "我寄相思与烟雨，随风说与君相忆。",
    "尘世三千多繁琐，唯有相思最难说。",
    "春风小庙桃花新，桃花瓣瓣落我心。",
    "心如风雨不系舟，为伊长在湖中留。",
    "旧事总如青天远，陈情常似沧海深。",
    "惯取新酒醉花月，醒时犹念梦里人。",
    "愿将星河斟满怀，共叙相思无穷意。",
    "秋来琵琶雨打黄，仍携深情缓敲窗。",
    "此情风月也相关，鸳鸯比翼两相欢。",
    "同君沐雪立危楼，拟将此时作白头。",
    "少年不解春风意，挽袖涉水送蒹葭。",
    "若遇良人伴身侧，从此世间少颜色。",
    "两心更有千千结，此情怎会惧缘疏？",
    "既见君心定不负，谁言相思无归处。",
    "花辞枝叶不辞春，朱颜辞镜不辞心。",
    "孤衾有梦堪长夜，空枕何人伴良辰？",
    "曾于庭前酿海棠，海棠已满共君尝。",
    "人间多少相思物，不及佳人几回顾。",
    "相思最是牵我肠，夜夜垂首细思量。",
}
local g_DefaultTextMaxLengthChinese = 16
local g_UI_Items = {}

local g_RdTextIndex = 1

local g_Saved = 0
local g_otherPlayerServerObjID = 0
local g_isTeamLeader = 0
local g_HuaDengItemIndex = 0
local g_cachedWords = {
    myName = "",
    myWords = "",
    othersName = "",
    othersWords = "",
}
local g_notifyCloseWhenClosed = 1
-- local g_ItemImg = 
-- {
--     [1] = {set ="Calendar3" ,image="Level_1"},
-- 	[2] = {set ="Calendar3" ,image="Level_2"},
-- 	[3] = {set ="Calendar4" ,image="Level_3"},
-- 	[4] = {set ="Calendar4" ,image="Level_4"},
-- }

local function GetNextRdText()
    local maxNum = table.getn(g_DefaultText)
    g_RdTextIndex = g_RdTextIndex + 1
    if g_RdTextIndex > maxNum then
        g_RdTextIndex = 1
    end
    return g_DefaultText[g_RdTextIndex]
end


function Valentine_interaction_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    this:RegisterEvent("QRJWORDSOPERATE", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Valentine_interaction_OnLoad()
    g_Frame_UnifiedPosition = Valentine_interaction_FrameNULL:GetProperty("UnifiedPosition")
    g_UI_Items.MyEditor = Valentine_interaction3
    --g_UI_Items.ItemImg = Valentine_interaction_Client1_Huadeng
    g_UI_Items.SaveBtn = Valentine_interaction_Baocun
    g_UI_Items.AcceptBtn = Valentine_interaction_Accept
    g_UI_Items.AcceptText = Valentine_interaction_Accept_Text
    g_UI_Items.OtherText = Valentine_interaction1
    g_UI_Items.RdTextBtn = Valentine_interaction_NextButton
    g_UI_Items.CustomBtn = Valentine_interaction_CustomButton

end

function Valentine_interaction_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
        local nOpt = Get_XParam_INT(0)
        if nOpt == 1 then
            --花灯道具打开界面
            Valentine_interaction_Open()
        elseif nOpt == 2 then
            --点击确定后 经过server x998353_OnAcceptSaveWords 返回 
            if g_HuaDengItemIndex < 1 or g_Saved ~= 1  then
                return 
            end
            local ts = string.format( "%d\t%s\t%s\t%s\t%s",g_HuaDengItemIndex,
            g_cachedWords.myName,
            g_cachedWords.myWords,
            g_cachedWords.othersName,
            g_cachedWords.othersWords
            )
            LuaSaveQRJWords(ts,g_HuaDengItemIndex)
        elseif nOpt == 3 then
            g_notifyCloseWhenClosed = 0
            Valentine_interaction_Close()
        elseif nOpt == 4 then
            g_cachedWords.othersWords = ""
            g_UI_Items.OtherText:SetText("")
            if g_isTeamLeader == 1 then
                g_UI_Items.AcceptText:SetText("#{QRJH_20221109_111}")
            end
        elseif nOpt == 5 then
            --对方关闭界面了 通知我
            g_notifyCloseWhenClosed = 0
            Valentine_interaction_Close()
        end
    elseif event == "QRJWORDSOPERATE" then
        local opt =  tonumber(arg0)
        if opt == 1 then
            --获得另一人的文字 刷新界面文字控件
            g_cachedWords.othersWords = arg1
            g_UI_Items.OtherText:SetText(arg1)
            if g_isTeamLeader == 1 then
                g_UI_Items.AcceptText:SetText("#{QRJH_20221109_110}")
            end

        elseif opt == 4 then
            --自己成功保存后的回调
            if g_isTeamLeader == 0 then
                g_UI_Items.AcceptText:SetText("#{QRJH_20221109_92}")
            end
            --g_UI_Items.SaveBtn:SetText("已保存")
            g_UI_Items.SaveBtn:Disable()
            g_Saved = 1
            g_UI_Items.MyEditor:SetProperty("DefaultEditBox", "False");
            PushDebugMessage("#{QRJH_20221109_130}")
        end

	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        Valentine_interaction_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
		Valentine_interaction_Close()
	end

end

function Valentine_interaction_CleanUp()
    g_Saved = 0
    g_RdTextIndex = 1
    g_otherPlayerServerObjID = 0
    g_isTeamLeader = 0
    g_HuaDengItemIndex = 0
    g_cachedWords.myName = ""
    g_cachedWords.myWords = ""
    g_cachedWords.othersName = ""
    g_cachedWords.othersWords = ""
    g_notifyCloseWhenClosed = 1
end

function Valentine_interaction_Open()
    Valentine_interaction_CleanUp()
    g_RdTextIndex = math.random(1 , table.getn(g_DefaultText) )
    local defaultText = g_DefaultText[g_RdTextIndex]
    g_UI_Items.MyEditor:Enable()
    g_UI_Items.MyEditor:SetText(defaultText)
    g_UI_Items.MyEditor:SetProperty("DefaultEditBox", "False");
    g_UI_Items.OtherText:SetText("")
    --g_UI_Items.SaveBtn:SetText("保存")
    g_UI_Items.SaveBtn:Enable()
    g_isTeamLeader = Get_XParam_INT(1)
    g_otherPlayerServerObjID = Get_XParam_INT(2)
    g_HuaDengItemIndex = Get_XParam_INT(3)
    g_cachedWords.othersName = Get_XParam_STR(0)
    g_cachedWords.myName =  Player:GetName()
    g_cachedWords.myWords = defaultText

    if g_isTeamLeader == 1 then
        g_UI_Items.AcceptBtn:Show()
        g_UI_Items.AcceptText:SetText("#{QRJH_20221109_111}")
    else
        g_UI_Items.AcceptBtn:Hide()
        g_UI_Items.AcceptText:SetText("")
    end
    -- if g_ItemImg[g_HuaDengItemIndex] then
    --     g_UI_Items.ItemImg:SetImage(g_ItemImg[g_HuaDengItemIndex].set,g_ItemImg[g_HuaDengItemIndex].image)
    -- end
    

    this:Show()
end

function Valentine_interaction_InputChange()
    if g_Saved ~= 1 then
        return 
    end
    --g_UI_Items.SaveBtn:SetText("保存")
    g_UI_Items.SaveBtn:Enable()
    g_Saved = 0
    if g_isTeamLeader == 0 then
        g_UI_Items.AcceptText:SetText("")
    end
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "NotifyInputChanged" )
    Set_XSCRIPT_Parameter(0,g_otherPlayerServerObjID);
    Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT()
end


function Valentine_interaction_CustomButton_Click()
    g_UI_Items.MyEditor:SetText("")
    g_UI_Items.MyEditor:SetProperty("DefaultEditBox", "True");
end

function Valentine_interaction_NextButton_Click()
    g_UI_Items.MyEditor:SetText(GetNextRdText())
    g_UI_Items.MyEditor:SetProperty("DefaultEditBox", "False");
end

function Valentine_interaction_Accept_Clicked()
    if g_cachedWords.othersWords == "" then
        PushDebugMessage("#{QRJH_20221109_93}")
        return 
    end
    if g_Saved ~= 1 then
        PushDebugMessage("#{QRJH_20221109_91}")
        return 
    end
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnAcceptSaveWords" )
    Set_XSCRIPT_Parameter(0,g_HuaDengItemIndex);
    Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT()
end

function Valentine_interaction_Baocun_Clicked()
    local customText = g_UI_Items.MyEditor:GetItemElementsString()
    if customText == "" then
        return 
    end
    if tonumber(string.len(customText)) > g_DefaultTextMaxLengthChinese *2 then
        PushDebugMessage("输入超过长度限制")
        return 
    end
    if g_otherPlayerServerObjID < 15000 then
        PushDebugMessage("页面数据错误")
        return 
    end
    g_cachedWords.myWords = customText 

    LuaSyncWordsToPlayer(customText,g_otherPlayerServerObjID)
end



-- function Valentine_interaction_OnClickedHelp()
--    	-- 借用一下别人的通道
--        PushEvent("CCSHOP_HELP", 139)
-- end


function Valentine_interaction_On_ResetPos()
    if (this:IsVisible()) then
        if (g_Frame_UnifiedPosition ~= nil) then
            Valentine_interaction_FrameNULL:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
        end
    end
end



function Valentine_interaction_OnHide()
    if g_notifyCloseWhenClosed ~= 1 then
        return 
    end
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "NotifyClosed" )
    Set_XSCRIPT_Parameter(0,g_otherPlayerServerObjID);
    Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT()
end

function Valentine_interaction_Close()
    this:Hide()
end 