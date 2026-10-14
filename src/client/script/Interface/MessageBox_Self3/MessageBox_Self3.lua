
local MessageBox_Self3_OK_Pos = ""
local MessageBox_Self3_Cancel_Pos = ""
local MessageBox_Self3_CbInfo = {}

local MessageBox_Self3_CaredObj = nil

local MessageBox_Self3_nTitleHeight = 23
local MessageBox_Self3_nBottomHeight = 25

function MessageBox_Self3_PreLoad()
  this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--离开场景关闭界面
  this:RegisterEvent("ADJEST_UI_POS",false)-- 游戏窗口尺寸发生了变化
  this:RegisterEvent("MESSAGE_BOX_SELF3",true)
  this:RegisterEvent("MESSAGE_BOX_SELF3_CLOSE",false)
end

function MessageBox_Self3_OnLoad()
  MessageBox_Self3_OK_Pos = MessageBox_Self3_OK_Button:GetProperty("UnifiedPosition")
  MessageBox_Self3_Cancel_Pos = MessageBox_Self3_Cancel_Button:GetProperty("UnifiedPosition")
  MessageBox_Self3_OK_Button:SetEvent("Clicked","MessageBox_Self3_OnOk()")
  MessageBox_Self3_Cancel_Button:SetEvent("Clicked","MessageBox_Self3_OnCancel()")
end

function MessageBox_Self3_OnEvent( event )
  if event == "MESSAGE_BOX_SELF3" then
    if arg4 == "Ok" then
      --MessageBox_Self3_OK_Button:SetProperty("UnifiedPosition",MessageBox_Self3_Cancel_Pos)
      MessageBox_Self3_Cancel_Button:Hide()
    elseif arg4 == "YesNo" then
      --MessageBox_Self3_OK_Button:SetProperty("UnifiedPosition",MessageBox_Self3_OK_Pos)
      MessageBox_Self3_Cancel_Button:Show()
    else
      return
    end
    MessageBox_Self3_CbInfo = { arg4, arg0, arg1 }
    MessageBox_Self3_Text:SetText( arg3 )
    MessageBox_Self3_OK_Button:SetText( arg5 )
    MessageBox_Self3_Cancel_Button:SetText( arg6 )
    if arg7 and tonumber(arg7) then
      -- PushDebugMessage("MessageBox care obj "..arg7)
      MessageBox_Self3_CaredObj = tonumber(arg7)
      if MessageBox_Self3_CaredObj < 0 then
        MessageBox_Self3_CaredObj = nil
      else
        this:CareObject(MessageBox_Self3_CaredObj, 1, "MessageBox_Self3")
      end
    end
    MessageBox_Self3_UpdateRect()
    this:Show()
    return
  elseif event == "HIDE_ON_SCENE_TRANSED" then
    MessageBox_Self3_OnHide()
  elseif event == "MESSAGE_BOX_SELF3_CLOSE" then
    MessageBox_Self3_OnHide()
  end
end

function  MessageBox_Self3_UpdateRect()
	local nWidth, nHeight = MessageBox_Self3_Text:GetWindowSize()
	local nWindowHeight = MessageBox_Self3_nTitleHeight + MessageBox_Self3_nBottomHeight + nHeight
	MessageBox_Self3_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) )
end

function MessageBox_Self3_OnOk()
  if MessageBox_Self3_CbInfo[1] == "Ok" then
    PushEvent( "MESSAGE_BOX_SELF3_CB", MessageBox_Self3_CbInfo[2], MessageBox_Self3_CbInfo[3], "Ok" )
  elseif MessageBox_Self3_CbInfo[1] == "YesNo" then
    PushEvent( "MESSAGE_BOX_SELF3_CB", MessageBox_Self3_CbInfo[2], MessageBox_Self3_CbInfo[3], "Yes" )
  end
  MessageBox_Self3_OnHide()
end

function MessageBox_Self3_OnCancel()
  if MessageBox_Self3_CbInfo[1] == "YesNo" then
    PushEvent( "MESSAGE_BOX_SELF3_CB", MessageBox_Self3_CbInfo[2], MessageBox_Self3_CbInfo[3], "No" )
  end
  MessageBox_Self3_OnHide()
end

function MessageBox_Self3_Frame_OnHiden()
  if MessageBox_Self3_CaredObj then
    this:CareObject(MessageBox_Self3_CaredObj, 0, "MessageBox_Self3")
    MessageBox_Self3_CaredObj = nil
  end
end

function MessageBox_Self3_OnHide()
  MessageBox_Self3_Frame_OnHiden()
  this:Hide()
end