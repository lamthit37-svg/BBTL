--各个功能的Frame
local g_NationalDay_Frames = {}
local g_NationalDay_Frame_UnifiedPosition

--===============================================
-- 这一段是为了动态显示Button Tips ---------begin
--===============================================
local g_NationalDay_Event = {
    [1] = {text = "登陆有礼}", isShow = 0}, --双倍乐翻天
    [2] = {text = "七日献好礼", isShow = 0} --七日献好礼
}

--左侧Button 合集 加这个合集 是因为以后策划 想要某个特定的Button 上移
local g_NationalDay_Button = {}
local g_NationalDay_Tip = {}
local g_Button_StateTemp = {1, 1} --暂时的 后续改  先用
local g_Tips_StateTemp = {1, 1} --暂时的 后续改  先用

--国庆七日签到 Begin

local g_7HIT_TIMES = {
    [1] = {TIMES = 20221001},
    [2] = {TIMES = 20221002},
    [3] = {TIMES = 20221003},
    [4] = {TIMES = 20221004},
    [5] = {TIMES = 20221005},
    [6] = {TIMES = 20221006},
    [7] = {TIMES = 20221007}, 
}

--奖励图标
local g_7HITActionButton = {}
--领取按钮
local g_NationalDay_7HIT_Button = {}
--已领取 对号
local g_7HITActionButton_Mask = {}
--每天下红点
local g_NationalDay_7HIT_Red = {}
--补签图标
local g_NationalDay_7HIT_Resign = {}
--日期
local g_Xingqi = {}

local g_NationalDay_7Day_Gifts = {
    [1] = {GiftItemID = 39920397, num = 2},
    [2] = {GiftItemID = 39920394, num = 5},
    [3] = {GiftItemID = 30008130, num = 2},
    [4] = {GiftItemID = 39920396, num = 2},
    [5] = {GiftItemID = 30900130, num = 1},
    [6] = {GiftItemID = 38000945, num = 2},
    [7] = {GiftItemID = 38005180, num = 1}, 
}
local g_NationalDay_7Day_Data = {
    [1] = "#{DQDL_180814_09}",
    [2] = "#{DQDL_180814_10}",
    [3] = "#{DQDL_180814_11}",
    [4] = "#{DQDL_180814_12}",
    [5] = "#{DQDL_180814_13}",
    [6] = "#{DQDL_180814_14}",
    [7] = "#{DQDL_180814_15}", 
}
local g_NationalDay_7Day_Tips = {
    [1] = "#{DQDL_180814_16}",
    [2] = "#{DQDL_180814_41}",
    [3] = "#{DQDL_180814_42}",
    [4] = "#{DQDL_180814_43}",
    [5] = "#{DQDL_180814_44}",
    [6] = "#{DQDL_180814_45}",
    [7] = "#{DQDL_180814_46}", 
}
local nLocalNationalDay = {}

local g_DayTime = {
    [0] = {Month = "10", Day = "1"},
    [1] = {Month = "10", Day = "2"},
    [2] = {Month = "10", Day = "3"},
    [3] = {Month = "10", Day = "4"},
    [4] = {Month = "10", Day = "5"},
    [5] = {Month = "10", Day = "6"},
    [6] = {Month = "10", Day = "7"},  
}

--国庆七日签到 End
--===============================================
-- 这一段是为了动态显示Button Tips -----------end
--===============================================
--国庆芙蓉醉Begin

--树上花按钮
local g_NationalDay_Tree_Button = {}
--特殊花朵
local g_NationalDay_Tree_Button_WuXiang
--
local g_NationalDay_Tree_Button_Collect_One = {}
local g_NationalDay_Tree_Button_Collect_Two = {}
local g_NationalDay_Tree_UserState = 0
local g_NationalDay_Tree_HJZJ_Data = 0
local g_NationalDay_Tree_QiongJiangCount = 0
local g_NationalDay_Tree_QiongJiangCount_Help = 0
local g_NationalDay_Tree_ServerTime = 0
local g_NationalDay_Tree_FriendUserName = ""
local g_NationalDay_Tree_TreeState = {}
local g_NationalDay_Tree_WuXiangFlag = 0
local g_NationalDay_Tree_ContactState = 0
--   0未建立契约 1求助玩家 2协助玩家
local g_NationalDay_Tree_NoContactState = 0
local g_NationalDay_Tree_QiuZhuState = 1
local g_NationalDay_Tree_XieZhuState = 2

--   0花苞、1浮雪芙蓉、2粉妆芙蓉、3朱颜芙蓉、4已摘取
local g_NationalDay_Tree_HuaLei_info = 0
local g_NationalDay_Tree_Fuxue_info = 1 
local g_NationalDay_Tree_ZhuYan_info = 3
local g_NationalDay_Tree_KuWei_info = 4

--芙蓉醉时间戳
local g_NationalDay_DayCount = 8   --这次国庆是几天 
local g_NationalDay_Tree_HuoDong = {20251001, 20251019} --活动开始时间
local g_NationalDay_Tree_YuRe = {20180927, 20180930} --预热活动 时间  废弃
local g_NationalDay_Tree_WuXiang = {20251009, 20251019} --无相礼盒花朵时间
local g_NationalDay_Tree_YuYe = {20251001, 20251008} --使用玉液时间 浮雪Tips1
local g_NationalDay_Tree_FuXue = {20251009, 20251019} --浮雪Tips2 补领时间
local g_NationalDay_Tree_ButtonTime = {20251001, 20251008, 20251009, 20251019} --Button时间
local g_NationalDay_Tree_NoContactState_Time = {
    [1] = 20181001, --显示专用 --未签约
    [2] = 20181006, --显示专用 --未签约
    [3] = 20181007, --显示专用 --未签约
    [4] = 20181014 --显示专用 --未签约
}
local g_NationalDay_Tree_ContactState_Time = {
    [1] = 20181001, --显示专用 -- 签约
    [2] = 20181010, --显示专用 -- 签约
    [3] = 20181011, --显示专用 -- 签约
    [4] = 20181014 --显示专用 -- 签约
}

local g_NationalDay_Tree_Image = {
    [1] = {
        --花苞
        [1] = {
            PushImage = "set:AppleTree1 image:Flower1_Pushed",
            NormalImage = "set:AppleTree1 image:Flower1_Normal",
            HoverImage = "set:AppleTree1 image:Flower1_Hover",
            DisabledImage = "set:AppleTree1 image:Flower1_Disabled",
            Tips = { 
                    [0] = "#{GQYJ_180818_153}",
                    [1] = "#{GQYJ_220817_05}",
                },            
        },
        --浮雪
        [2] = {
            PushImage = "set:AppleTree2 image:White1_Pushed",
            NormalImage = "set:AppleTree2 image:White1_Normal",
            HoverImage = "set:AppleTree2 image:White1_Hover",
            DisabledImage = "set:AppleTree2 image:White1_Disabled",
            Tips = { 
                [0] = "#{GQYJ_180818_160}",
                [1] = "#{GQYJ_220817_13}",
            },
            Tips1 ={ 
                [0] = "#{GQYJ_180818_160}",
                [1] = "#{GQYJ_220817_13}",
            }, 
            BuLingTips = { 
                [0] = "#{GQYJ_220817_52}",
                [1] = "#{GQYJ_220817_52}",
            },
        },
        --粉状
        [3] = {
            PushImage = "set:AppleTree2 image:Pink1_Pushed",
            NormalImage = "set:AppleTree2 image:Pink1_Normal",
            HoverImage = "set:AppleTree2 image:Pink1_Hover",
            DisabledImage = "set:AppleTree2 image:Pink1_Disabled",
            Tips = "#{GQYJ_180818_15}"
        },
        --朱颜
        [4] = {
            PushImage = "set:AppleTree3 image:Red1_Pushed",
            NormalImage = "set:AppleTree3 image:Red1_Normal",
            HoverImage = "set:AppleTree3 image:Red1_Hover",
            DisabledImage = "set:AppleTree3 image:Red1_Disabled",
            Tips = { 
                [0] = "#{GQYJ_180818_16}",
                [1] = "#{GQYJ_220817_20}",
            },
        },
        --已摘取
        [5] = {
            PushImage = "set:AppleTree1 image:HuaDi1",
            NormalImage = "set:AppleTree1 image:HuaDi1",
            HoverImage = "set:AppleTree1 image:HuaDi1",
            DisabledImage = "set:AppleTree1 image:HuaDi1",
            Tips = {"#{GQYJ_180818_17}"}
        }
    },
    [2] = {
        --花苞
        [1] = {
            PushImage = "set:AppleTree1 image:Flower2_Pushed",
            NormalImage = "set:AppleTree1 image:Flower2_Normal",
            HoverImage = "set:AppleTree1 image:Flower2_Hover",
            DisabledImage = "set:AppleTree1 image:Flower2_Disabled",
            Tips = { 
                [0]="#{GQYJ_180818_154}",
                [1]="#{GQYJ_220817_06}",
            }
        },
        --浮雪
        [2] = {
            PushImage = "set:AppleTree2 image:White2_Pushed",
            NormalImage = "set:AppleTree2 	 image:White2_Normal",
            HoverImage = "set:AppleTree2 image:White2_Hover",
            DisabledImage = "set:AppleTree2 image:White2_Disabled",            
            Tips = { 
                [0] = "#{GQYJ_180818_161}",
                [1] = "#{GQYJ_220817_14}",
            },
            Tips1 ={ 
                [0] = "#{GQYJ_180818_161}",
                [1] = "#{GQYJ_220817_14}",
            },
            BuLingTips = { 
                [0] = "#{GQYJ_220817_53}",
                [1] = "#{GQYJ_220817_53}",
            },

        },
        --粉状
        [3] = {
            PushImage = "set:AppleTree2 image:Pink2_Pushed",
            NormalImage = "set:AppleTree2 image:Pink2_Normal",
            HoverImage = "set:AppleTree2 image:Pink2_Hover",
            DisabledImage = "set:AppleTree2 image:Pink2_Disabled",
            Tips = "#{GQYJ_180818_167}"
        },
        --朱颜
        [4] = {
            PushImage = "set:AppleTree3 image:Red2_Pushed",
            NormalImage = "set:AppleTree3 image:Red2_Normal",
            HoverImage = "set:AppleTree3 image:Red2_Hover",
            DisabledImage = "set:AppleTree3 image:Red2_Disabled",
            Tips = { 
                [0] = "#{GQYJ_180818_173}",
                [1] = "#{GQYJ_220817_21}",
            },
        },
        --已摘取
        [5] = {
            PushImage = "set:AppleTree1 image:HuaDi2",
            NormalImage = "set:AppleTree1 image:HuaDi2",
            HoverImage = "set:AppleTree1 image:HuaDi2",
            DisabledImage = "set:AppleTree1 image:HuaDi2",
            Tips = {"#{GQYJ_180818_17}"}
        }
    },
    [3] = {
        --花苞
        [1] = {
            PushImage = "set:AppleTree1 image:Flower3_Pushed",
            NormalImage = "set:AppleTree1 image:Flower3_Normal",
            HoverImage = "set:AppleTree1 image:Flower3_Hover",
            DisabledImage = "set:AppleTree1 image:Flower3_Disabled",
            Tips = {
                [0]="#{GQYJ_180818_155}",
                [1]="#{GQYJ_220817_07}",
            },
        },
        --浮雪
        [2] = {
            PushImage = "set:AppleTree2 image:White3_Pushed",
            NormalImage = "set:AppleTree2 image:White3_Normal",
            HoverImage = "set:AppleTree2 image:White3_Hover",
            DisabledImage = "set:AppleTree2 image:White3_Disabled",
            Tips = {
                [0]="#{GQYJ_180818_162}",
                [1]="#{GQYJ_220817_15}",
            },
            Tips1 ={
                [0]="#{GQYJ_180818_162}",
                [1]="#{GQYJ_220817_15}",
            },
            BuLingTips={ 
                [0] = "#{GQYJ_220817_54}",
                [1] = "#{GQYJ_220817_54}",
            },
        },
        --粉状
        [3] = {
            PushImage = "set:AppleTree2 image:Pink3_Pushed",
            NormalImage = "set:AppleTree2 image:Pink3_Normal",
            HoverImage = "set:AppleTree2 image:Pink3_Hover",
            DisabledImage = "set:AppleTree2 image:Pink3_Disabled",
            Tips = "#{GQYJ_180818_168}"
        },
        --朱颜
        [4] = {
            PushImage = "set:AppleTree3 image:Red3_Pushed",
            NormalImage = "set:AppleTree3 image:Red3_Normal",
            HoverImage = "set:AppleTree3 image:Red3_Hover",
            DisabledImage = "set:AppleTree3 image:Red3_Disabled",
            Tips = {
                [0]="#{GQYJ_180818_174}",
                [1]="#{GQYJ_220817_22}",
            },
        },
        --已摘取
        [5] = {
            PushImage = "set:AppleTree1 image:HuaDi3",
            NormalImage = "set:AppleTree1 image:HuaDi3",
            HoverImage = "set:AppleTree1 image:HuaDi3",
            DisabledImage = "set:AppleTree1 image:HuaDi3",
            Tips = {"#{GQYJ_180818_17}"}
        }
    },
    [4] = {
        --花苞
        [1] = {
            PushImage = "set:AppleTree1 image:Flower2_Pushed",
            NormalImage = "set:AppleTree1 image:Flower2_Normal",
            HoverImage = "set:AppleTree1 image:Flower2_Hover",
            DisabledImage = "set:AppleTree1 image:Flower2_Disabled",
            Tips ={                
                [0]="#{GQYJ_180818_156}",
                [1]="#{GQYJ_220817_08}",
            }, 
        },
        --浮雪
        [2] = {
            PushImage = "set:AppleTree2 image:White2_Pushed",
            NormalImage = "set:AppleTree2 	 image:White2_Normal",
            HoverImage = "set:AppleTree2 image:White2_Hover",
            DisabledImage = "set:AppleTree2 image:White2_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_163}",
                [1]="#{GQYJ_220817_16}",
            },
            Tips1 ={                
                [0]="#{GQYJ_180818_163}",
                [1]="#{GQYJ_220817_16}",
            },
            BuLingTips={ 
                [0] = "#{GQYJ_220817_55}",
                [1] = "#{GQYJ_220817_60}",
            },
        },
        --粉状
        [3] = {
            PushImage = "set:AppleTree2 image:Pink2_Pushed",
            NormalImage = "set:AppleTree2 image:Pink2_Normal",
            HoverImage = "set:AppleTree2 image:Pink2_Hover",
            DisabledImage = "set:AppleTree2 image:Pink2_Disabled",
            Tips = "#{GQYJ_180818_169}"
        },
        --朱颜
        [4] = {
            PushImage = "set:AppleTree3 image:Red2_Pushed",
            NormalImage = "set:AppleTree3 image:Red2_Normal",
            HoverImage = "set:AppleTree3 image:Red2_Hover",
            DisabledImage = "set:AppleTree3 image:Red2_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_175}",
                [1]="#{GQYJ_220817_23}",
            },
        },
        --已摘取
        [5] = {
            PushImage = "set:AppleTree1 image:HuaDi2",
            NormalImage = "set:AppleTree1 image:HuaDi2",
            HoverImage = "set:AppleTree1 image:HuaDi2",
            DisabledImage = "set:AppleTree1 image:HuaDi2",
            Tips = {"#{GQYJ_180818_17}"}
        }
    },
    [5] = {
        --花苞
        [1] = {
            PushImage = "set:AppleTree1 image:Flower1_Pushed",
            NormalImage = "set:AppleTree1 image:Flower1_Normal",
            HoverImage = "set:AppleTree1 image:Flower1_Hover",
            DisabledImage = "set:AppleTree1 image:Flower1_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_157}",
                [1]="#{GQYJ_220817_09}",
            }, 
        },
        --浮雪
        [2] = {
            PushImage = "set:AppleTree2 image:White1_Pushed",
            NormalImage = "set:AppleTree2 image:White1_Normal",
            HoverImage = "set:AppleTree2 image:White1_Hover",
            DisabledImage = "set:AppleTree2 image:White1_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_164}",
                [1]="#{GQYJ_220817_17}",
            },
            Tips1 ={                
                [0]="#{GQYJ_180818_164}",
                [1]="#{GQYJ_220817_17}",
            },
            BuLingTips={ 
                [0] = "#{GQYJ_220817_56}",
                [1] = "#{GQYJ_220817_56}",
            },
        },
        --粉状
        [3] = {
            PushImage = "set:AppleTree2 image:Pink1_Pushed",
            NormalImage = "set:AppleTree2 image:Pink1_Normal",
            HoverImage = "set:AppleTree2 image:Pink1_Hover",
            DisabledImage = "set:AppleTree2 image:Pink1_Disabled",
            Tips = "#{GQYJ_180818_170}"
        },
        --朱颜
        [4] = {
            PushImage = "set:AppleTree3 image:Red1_Pushed",
            NormalImage = "set:AppleTree3 image:Red1_Normal",
            HoverImage = "set:AppleTree3 image:Red1_Hover",
            DisabledImage = "set:AppleTree3 image:Red1_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_176}",
                [1]="#{GQYJ_220817_24}",
            },
        },
        --已摘取
        [5] = {
            PushImage = "set:AppleTree1 image:HuaDi1",
            NormalImage = "set:AppleTree1 image:HuaDi1",
            HoverImage = "set:AppleTree1 image:HuaDi1",
            DisabledImage = "set:AppleTree1 image:HuaDi1",
            Tips = {"#{GQYJ_180818_17}"}
        }
    },
    [6] = {
        --花苞
        [1] = {
            PushImage = "set:AppleTree1 image:Flower3_Pushed",
            NormalImage = "set:AppleTree1 image:Flower3_Normal",
            HoverImage = "set:AppleTree1 image:Flower3_Hover",
            DisabledImage = "set:AppleTree1 image:Flower3_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_158}",
                [1]="#{GQYJ_220817_10}",
            }, 
        },
        --浮雪
        [2] = {
            PushImage = "set:AppleTree2 image:White3_Pushed",
            NormalImage = "set:AppleTree2 image:White3_Normal",
            HoverImage = "set:AppleTree2 image:White3_Hover",
            DisabledImage = "set:AppleTree2 image:White3_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_165}",
                [1]="#{GQYJ_220817_18}",
            },
            Tips1 ={                
                [0]="#{GQYJ_180818_165}",
                [1]="#{GQYJ_220817_18}",
            },
            BuLingTips={ 
                [0] = "#{GQYJ_220817_57}",
                [1] = "#{GQYJ_220817_61}",
            },
        },
        --粉状
        [3] = {
            PushImage = "set:AppleTree2 image:Pink3_Pushed",
            NormalImage = "set:AppleTree2 image:Pink3_Normal",
            HoverImage = "set:AppleTree2 image:Pink3_Hover",
            DisabledImage = "set:AppleTree2 image:Pink3_Disabled",
            Tips = "#{GQYJ_180818_171}"
        },
        --朱颜
        [4] = {
            PushImage = "set:AppleTree3 image:Red3_Pushed",
            NormalImage = "set:AppleTree3 image:Red3_Normal",
            HoverImage = "set:AppleTree3 image:Red3_Hover",
            DisabledImage = "set:AppleTree3 image:Red3_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_177}",
                [1]="#{GQYJ_220817_25}",
            },
        },
        --已摘取
        [5] = {
            PushImage = "set:AppleTree1 image:HuaDi3",
            NormalImage = "set:AppleTree1 image:HuaDi3",
            HoverImage = "set:AppleTree1 image:HuaDi3",
            DisabledImage = "set:AppleTree1 image:HuaDi3",
            Tips = {"#{GQYJ_180818_17}"}
        }
    },
    [7] = {
        --花苞
        [1] = {
            PushImage = "set:AppleTree1 image:Flower2_Pushed",
            NormalImage = "set:AppleTree1 image:Flower2_Normal",
            HoverImage = "set:AppleTree1 image:Flower2_Hover",
            DisabledImage = "set:AppleTree1 image:Flower2_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_159}",
                [1]="#{GQYJ_220817_11}",
            }, 
        },
        --浮雪
        [2] = {
            PushImage = "set:AppleTree2 image:White2_Pushed",
            NormalImage = "set:AppleTree2 	 image:White2_Normal",
            HoverImage = "set:AppleTree2 image:White2_Hover",
            DisabledImage = "set:AppleTree2 image:White2_Disabled",
            Tips ={                
                [0]="#{GQYJ_180818_166}",
                [1]="#{GQYJ_220817_19}",
            },
            Tips1 ={                
                [0]="#{GQYJ_180818_166}",
                [1]="#{GQYJ_220817_19}",
            },
            BuLingTips={ 
                [0] = "#{GQYJ_220817_58}",
                [1] = "#{GQYJ_220817_58}",
            },
        },
        --粉状
        [3] = {
            PushImage = "set:AppleTree2 image:Pink2_Pushed",
            NormalImage = "set:AppleTree2 image:Pink2_Normal",
            HoverImage = "set:AppleTree2 image:Pink2_Hover",
            DisabledImage = "set:AppleTree2 image:Pink2_Disabled",
            Tips = "#{GQYJ_180818_172}"
        },
        --朱颜
        [4] = {
            PushImage = "set:AppleTree3 image:Red2_Pushed",
            NormalImage = "set:AppleTree3 image:Red2_Normal",
            HoverImage = "set:AppleTree3 image:Red2_Hover",
            DisabledImage = "set:AppleTree3 image:Red2_Disabled",
            Tips = {                
                [0]="#{GQYJ_180818_178}",
                [1]="#{GQYJ_220817_26}",
            },
        },
        --已摘取
        [5] = {
            PushImage = "set:AppleTree1 image:HuaDi2",
            NormalImage = "set:AppleTree1 image:HuaDi2",
            HoverImage = "set:AppleTree1 image:HuaDi2",
            DisabledImage = "set:AppleTree1 image:HuaDi2",
            Tips = {"#{GQYJ_180818_17}"}
        }
    },    
    [8] = {
        --花苞
        [1] = {
            PushImage = "set:AppleTree1 image:Flower2_Pushed",
            NormalImage = "set:AppleTree1 image:Flower2_Normal",
            HoverImage = "set:AppleTree1 image:Flower2_Hover",
            DisabledImage = "set:AppleTree1 image:Flower2_Disabled",
            Tips = { 
                [0]="#{GQYJ_220817_30}",
                [1]="#{GQYJ_220817_30}",
            }
        },
        --浮雪
        [2] = {
            PushImage = "set:AppleTree2 image:White2_Pushed",
            NormalImage = "set:AppleTree2 	 image:White2_Normal",
            HoverImage = "set:AppleTree2 image:White2_Hover",
            DisabledImage = "set:AppleTree2 image:White2_Disabled",            
            Tips = { 
                [0] = "#{GQYJ_220817_31}",
                [1] = "#{GQYJ_220817_31}",
            },
            Tips1 ={ 
                [0] = "#{GQYJ_220817_31}",
                [1] = "#{GQYJ_220817_31}",
            },
            BuLingTips={ 
                [0] = "#{GQYJ_220817_59}",
                [1] = "#{GQYJ_220817_59}",
            },

        },
        --粉状
        [3] = {
            PushImage = "set:AppleTree2 image:Pink2_Pushed",
            NormalImage = "set:AppleTree2 image:Pink2_Normal",
            HoverImage = "set:AppleTree2 image:Pink2_Hover",
            DisabledImage = "set:AppleTree2 image:Pink2_Disabled",
            Tips = "#{GQYJ_180818_167}"
        },
        --朱颜
        [4] = {
            PushImage = "set:AppleTree3 image:Red2_Pushed",
            NormalImage = "set:AppleTree3 image:Red2_Normal",
            HoverImage = "set:AppleTree3 image:Red2_Hover",
            DisabledImage = "set:AppleTree3 image:Red2_Disabled",
            Tips = { 
                [0] = "#{GQYJ_220817_32}",
                [1] = "#{GQYJ_220817_32}",
            },
        },
        --已摘取
        [5] = {
            PushImage = "set:AppleTree1 image:HuaDi2",
            NormalImage = "set:AppleTree1 image:HuaDi2",
            HoverImage = "set:AppleTree1 image:HuaDi2",
            DisabledImage = "set:AppleTree1 image:HuaDi2",
            Tips = {"#{GQYJ_180818_17}"}
        }
    },
}
local g_NationalDay_Tree_Image_WuXiang = {
    [1] = {
        --花苞
        [1] = {
            PushImage = "set:AppleTree1 image:Flower4_Pushed",
            NormalImage = "set:AppleTree1 image:Flower4_Normal",
            HoverImage = "set:AppleTree1 image:Flower4_Hover",
            DisabledImage = "set:AppleTree1 image:Flower4_Disabled"
        },
        --
        [2] = {
            PushImage = "set:AppleTree3 image:Blue_Pushed",
            NormalImage = "set:AppleTree3 image:Blue_Normal",
            HoverImage = "set:AppleTree3 image:Blue_Hover",
            DisabledImage = "set:AppleTree3 image:Blue_Disabled"
        },
        --已摘取
        [3] = {
            PushImage = "set:AppleTree1 image:HuaDi4",
            NormalImage = "set:AppleTree1 image:HuaDi4",
            HoverImage = "set:AppleTree1 image:HuaDi4",
            DisabledImage = "set:AppleTree1 image:HuaDi4"
        }
    }
}
--国庆芙蓉醉End
local g_NationalDay_ButtonCDTime = 1 --按钮冷却时间
local g_NationalDay_ButtonLastTime = 0
local g_NationalDay_LastClickedId = -1 --上次选中的选项
local g_NationalDay_ServerTime = 0
--===============================================
-- PreLoad()
--===============================================
function NationalDay_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
    --this:RegisterEvent("OPEN_NATIONALDAY_2018",true)		--
    this:RegisterEvent("PLAYER_LEAVE_WORLD") -- 离开场景
    this:RegisterEvent("ADJEST_UI_POS", false) -- 游戏窗口尺寸发生了变化
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false) -- 游戏分辨率发生了变化
    this:RegisterEvent("UNIT_LEVEL", false)
    this:RegisterEvent("PLAYER_ENTERING_WORLD", false) -- 进入游戏世界
end

--===============================================
-- OnEvent()
--===============================================
function NationalDay_OnEvent(event)
    if (event == "UI_COMMAND" and tonumber(arg0) == 89291104) then --(event == "OPEN_NATIONALDAY_2018") or
        AskServerTimeAgain()
        local nIndex = Get_XParam_INT(0)
        NationalDay_Open(nIndex)
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 89291201) and this:IsVisible() then
        NationalDay_7Hit_UpdateInfo()
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 89293901) and this:IsVisible() then
        NationalDay_Tree_UpdateInfo()
    elseif (event == "UI_COMMAND" and tonumber(arg0) == 89291105) and this:IsVisible() then
        NationalDay_RefreshTips()
    elseif (event == "PLAYER_LEAVE_WORLD") then
        NationalDay_Close()
    elseif (event == "ADJEST_UI_POS") then
        NationalDay_On_ResetPos()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        NationalDay_On_ResetPos()
    elseif (event == "UNIT_LEVEL") then
    elseif (event == "PLAYER_ENTERING_WORLD") then -- 【新服欢乐月·升级送好礼&首冲超值赠】重新加载物品奖励
    end
end

--===============================================
-- OnLoad()
--===============================================
function NationalDay_OnLoad()
    g_NationalDay_Frame_UnifiedPosition = NationalDay_FrameNULL:GetProperty("UnifiedPosition")
    NationalDay_SetButtonPos()
end
--===============================================
-- SetButtonPos()
--===============================================
function NationalDay_SetButtonPos()
    g_NationalDay_Frames = {
        [1] = NationalDay_Client1,
        [2] = NationalDay_Client2
    }

    g_NationalDay_Button[1] = NationalDay_Buttontab01 --
    g_NationalDay_Button[2] = NationalDay_Buttontab02 --

    g_NationalDay_Tip[1] = NationalDay_Buttontab01_Tips
    g_NationalDay_Tip[2] = NationalDay_Buttontab02_Tips

    --7日签到 Begin
    g_7HITActionButton[1] = NationalDay_Page1_one
    g_7HITActionButton[2] = NationalDay_Page1_two
    g_7HITActionButton[3] = NationalDay_Page1_three
    g_7HITActionButton[4] = NationalDay_Page1_four
    g_7HITActionButton[5] = NationalDay_Page1_five
    g_7HITActionButton[6] = NationalDay_Page1_six
    g_7HITActionButton[7] = NationalDay_Page1_seven 
    --日期
    g_Xingqi[1] = NationalDay_oneText
    g_Xingqi[2] = NationalDay_twoText
    g_Xingqi[3] = NationalDay_threeText
    g_Xingqi[4] = NationalDay_fourText
    g_Xingqi[5] = NationalDay_fiveText
    g_Xingqi[6] = NationalDay_Page1_sixText
    g_Xingqi[7] = NationalDay_Page1_sevenText 
    
    --如果已经领取  显示
    g_7HITActionButton_Mask[1] = NationalDay_Page1_oneMark
    g_7HITActionButton_Mask[2] = NationalDay_Page1_twoMark
    g_7HITActionButton_Mask[3] = NationalDay_Page1_threeMark
    g_7HITActionButton_Mask[4] = NationalDay_Page1_fourMark
    g_7HITActionButton_Mask[5] = NationalDay_Page1_fiveMark
    g_7HITActionButton_Mask[6] = NationalDay_Page1_sixMark
    g_7HITActionButton_Mask[7] = NationalDay_Page1_sevenMark 
    --每天按钮小红点
    g_NationalDay_7HIT_Red[1] = NationalDay_one_ButtonTip
    g_NationalDay_7HIT_Red[2] = NationalDay_two_ButtonTip
    g_NationalDay_7HIT_Red[3] = NationalDay_three_ButtonTip
    g_NationalDay_7HIT_Red[4] = NationalDay_four_ButtonTip
    g_NationalDay_7HIT_Red[5] = NationalDay_five_ButtonTip
    g_NationalDay_7HIT_Red[6] = NationalDay_six_ButtonTip
    g_NationalDay_7HIT_Red[7] = NationalDay_seven_ButtonTip 
    --补签	图标
    g_NationalDay_7HIT_Resign[1] = NationalDay_Page1_oneResign
    g_NationalDay_7HIT_Resign[2] = NationalDay_Page1_twoResign
    g_NationalDay_7HIT_Resign[3] = NationalDay_Page1_threeResign
    g_NationalDay_7HIT_Resign[4] = NationalDay_Page1_fourResign
    g_NationalDay_7HIT_Resign[5] = NationalDay_Page1_fiveResign
    g_NationalDay_7HIT_Resign[6] = NationalDay_Page1_sixResign
    g_NationalDay_7HIT_Resign[7] = NationalDay_Page1_sevevResign 
    --领取
    g_NationalDay_7HIT_Button[1] = NationalDay_one_Button
    g_NationalDay_7HIT_Button[2] = NationalDay_two_Button
    g_NationalDay_7HIT_Button[3] = NationalDay_three_Button
    g_NationalDay_7HIT_Button[4] = NationalDay_four_Button
    g_NationalDay_7HIT_Button[5] = NationalDay_five_Button
    g_NationalDay_7HIT_Button[6] = NationalDay_six_Button
    g_NationalDay_7HIT_Button[7] = NationalDay_seven_Button 
    ----7日签到 End

    --芙蓉醉Begin 
    for i=1,g_NationalDay_DayCount do  
		if _G["AppleTree_Button"..i] == nil then
			continue;
		end
        g_NationalDay_Tree_Button[i]         =  _G["AppleTree_Button"..i] 
        g_NationalDay_Tree_Button[i]:Show()
    end  
    
    g_NationalDay_Tree_Button_Collect_One[1] = AppleTree_CollectButton
    g_NationalDay_Tree_Button_Collect_Two[1] = AppleTree_WaterButton

    g_NationalDay_Tree_Button_WuXiang = AppleTree_Button9
    --芙蓉醉End
end
--===============================================
-- Close()
--===============================================
function NationalDay_Close()
    this:Hide()
end
--===============================================
-- ResetPos()
--===============================================
function NationalDay_On_ResetPos()
    NationalDay_FrameNULL:SetProperty("UnifiedPosition", g_NationalDay_Frame_UnifiedPosition)
end

--===============================================
-- Open()
--===============================================
function NationalDay_Open(index)
    for index = 1, table.getn(g_NationalDay_Event) do
        local event = g_NationalDay_Event[index]
        event.isShow = 0
    end

    for index = 1, table.getn(g_NationalDay_Button) do
        g_NationalDay_Button[index]:Hide()
    end

    local buttonId = 1
    for index = 1, table.getn(g_NationalDay_Event) do
        local isButtonShow = g_Button_StateTemp[index]
        local isTipsShow = g_Tips_StateTemp[index]
        local event = g_NationalDay_Event[index]
        if isButtonShow == 1 then
            g_NationalDay_Button[buttonId]:Hide()
            if isTipsShow == 1 then
                g_NationalDay_Tip[buttonId]:Hide()
            end
            event.isShow = 1
            buttonId = buttonId + 1
        end
    end
    NationalDay_Project_Clicked(index)

    this:Show()
end

--===============================================
-- Clicked() 找到真正的函数
--===============================================
function NationalDay_Project_Clicked(clickId)
    local curTime = OSAPI:GetTickCount()
    if (curTime - g_NationalDay_ButtonLastTime < g_NationalDay_ButtonCDTime * 1000) then
        for index = 1, table.getn(g_NationalDay_Button) do
            if index == g_NationalDay_LastClickedId then
                g_NationalDay_Button[index]:SetCheck(1)
            else
                g_NationalDay_Button[index]:SetCheck(0)
            end
        end
        PushDebugMessage("#{ZYPT_081127_2}") --不可连续点击，请稍等片刻后再点击
        return
    end
    g_NationalDay_ButtonLastTime = curTime

    local buttonId = 0
    for index = 1, table.getn(g_NationalDay_Event) do
        local event = g_NationalDay_Event[index]
        if event.isShow == 1 then
            buttonId = buttonId + 1
            if buttonId == clickId then
                g_EventIndex = index
                break
            end
        end
    end

    for index = 1, table.getn(g_NationalDay_Button) do
        if index == clickId then
            g_NationalDay_Button[index]:SetCheck(1)
        else
            g_NationalDay_Button[index]:SetCheck(0)
        end
    end
    g_NationalDay_LastClickedId = clickId

    for index = 1, table.getn(g_NationalDay_Frames) do
        if index ~= g_EventIndex then
            g_NationalDay_Frames[index]:Hide()
        else
            g_NationalDay_Frames[index]:Show()
        end
    end
    if g_EventIndex == 1 then
        NationalDay_7Hit_Show()
    elseif g_EventIndex == 2 then
        NationalDay_Tree_Show()
    else
        PushDebugMessage("return")
        return
    end
    this:Show()
end

--===============================================
-- 更新小红点
--===============================================
function NationalDay_RefreshTips()
    for index = 1, table.getn(g_NationalDay_Button) do
        local TipsState = Get_XParam_INT(index - 1)
        g_Tips_StateTemp[index] = TipsState
    end

    local buttonId = 1
    for index = 1, table.getn(g_NationalDay_Event) do
        local isButtonShow = g_Button_StateTemp[index]
        local isTipsShow = g_Tips_StateTemp[index]
        if isButtonShow == 1 then
            if isTipsShow == 1 then
                g_NationalDay_Tip[buttonId]:Hide()
            else
                g_NationalDay_Tip[buttonId]:Hide()
            end
            buttonId = buttonId + 1
        end
    end
end

--===============================================
-- 7日献好礼 -begin
--===============================================

function NationalDay_7Hit_Show()
    NationalDay_7Hit_UpdateButtonReq()
end

function NationalDay_7Hit_UpdateButtonReq()
    -- 执行脚本
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("RequestNatiaonal7DaySign") -- 脚本函数名称
    Set_XSCRIPT_ScriptID(892912) -- 脚本编号
    Set_XSCRIPT_ParamCount(0) -- 参数个数
    Send_XSCRIPT()
end

function NationalDay_7Hit_UpdateInfo()
    NationalDay_7Hit_FlushWindow()
end

function NationalDay_7Hit_FlushWindow()
    if g_NationalDay_LastClickedId == 1 then
        NationalDay_DragTitle:SetText("#{DQDL_180814_06}")
    end
 
    --创建奖励图标
    for i = 1, table.getn(g_NationalDay_7Day_Gifts) do
        local GiftItemID  = g_NationalDay_7Day_Gifts[i].GiftItemID
        local GiftItemNum = g_NationalDay_7Day_Gifts[i].num

        local theAction = DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
        
        if theAction:GetID() ~= 0 then
            if g_7HITActionButton[i] == nil then
                PushDebugMessage("i"..i.."nil")  
            else                
                g_7HITActionButton[i]:SetActionItem(-1)
                g_7HITActionButton[i]:SetActionItem(theAction:GetID())
                g_7HITActionButton[i]:Show()
            end
        end
    end

    g_NationalDay_ServerTime = Get_XParam_INT(0)
    for i = 1, table.getn(g_NationalDay_7Day_Gifts) do
        local temp = Get_XParam_INT(i) 
        nLocalNationalDay[i] = temp 
    end 
    --显示
    for i = 1, table.getn(g_NationalDay_7Day_Gifts) do
        local Status = nLocalNationalDay[i] 

        local curDay = g_NationalDay_ServerTime 
        g_Xingqi[i]:SetText(g_NationalDay_7Day_Data[i])
        if curDay == g_7HIT_TIMES[i].TIMES then --当天
            if Status > 0 then --已领取 		--不显示Tips
                g_NationalDay_7HIT_Button[i]:SetToolTip("#{DQDL_180814_47}") --Tips
                g_NationalDay_7HIT_Button[i]:SetText("#{SJFL_150608_59}") --已领取
                g_NationalDay_7HIT_Button[i]:Disable()
                g_7HITActionButton_Mask[i]:Show()
                g_NationalDay_7HIT_Red[i]:Hide()
            else --未领取
                g_NationalDay_7HIT_Button[i]:SetToolTip(g_NationalDay_7Day_Tips[i]) --Tips
                g_NationalDay_7HIT_Button[i]:SetText("#{SJFL_150608_58}") --领取
                g_NationalDay_7HIT_Button[i]:Enable()
                g_7HITActionButton_Mask[i]:Hide()
                g_NationalDay_7HIT_Red[i]:Show()
            end
            --补领图标
            g_NationalDay_7HIT_Resign[i]:Hide()
        elseif tonumber(curDay) > tonumber(g_7HIT_TIMES[i].TIMES) then --时间过了
            
            if Status > 0 then --已领取 		--不显示Tips
                g_NationalDay_7HIT_Button[i]:SetToolTip("#{DQDL_180814_47}") --Tips
                g_NationalDay_7HIT_Button[i]:SetText("#{SJFL_150608_59}") --已领取
                g_NationalDay_7HIT_Button[i]:Disable()
                g_7HITActionButton_Mask[i]:Show()
                g_NationalDay_7HIT_Red[i]:Hide()
                --补领图标
                g_NationalDay_7HIT_Resign[i]:Hide()
            else --未领取
                g_NationalDay_7HIT_Button[i]:SetText("#{SJFL_150608_60}") --领取
                g_NationalDay_7HIT_Button[i]:SetToolTip("#{DQDL_180814_17}") --Tips
                g_NationalDay_7HIT_Button[i]:Enable()
                g_7HITActionButton_Mask[i]:Hide()
                g_NationalDay_7HIT_Red[i]:Hide()
                --补领图标
                g_NationalDay_7HIT_Resign[i]:Show()
            end
        elseif curDay < g_7HIT_TIMES[i].TIMES then --时间未到
            g_NationalDay_7HIT_Button[i]:SetText("#{SJFL_150608_58}") --领取
            g_NationalDay_7HIT_Button[i]:SetToolTip(g_NationalDay_7Day_Tips[i]) --Tips
            g_NationalDay_7HIT_Button[i]:Enable()
            g_7HITActionButton_Mask[i]:Hide()
            --补领图标
            g_NationalDay_7HIT_Resign[i]:Hide()
            g_NationalDay_7HIT_Red[i]:Hide()
        end
    end
end
function NationalDay_OnClick(Key)
    AskServerTimeAgain()
    local curDay = tonumber(DataPool:GetServerDayTime())

    if 0 == nLocalNationalDay[Key] and curDay == g_7HIT_TIMES[Key].TIMES then --当天未领
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("GetPrize")
        Set_XSCRIPT_ScriptID(892912)
        Set_XSCRIPT_Parameter(0, Key)
        Set_XSCRIPT_Parameter(1, 0)
        Set_XSCRIPT_Parameter(2, 0)
        Set_XSCRIPT_ParamCount(3)
        Send_XSCRIPT()
    elseif nLocalNationalDay[Key] == 0 and curDay < g_7HIT_TIMES[Key].TIMES then --日期未到 未领取
        local Str = ScriptGlobal_Format("#{DQDL_180814_20}", g_DayTime[Key - 1].Day)
        PushDebugMessage(Str)
    elseif nLocalNationalDay[Key] == 1 and curDay >= g_7HIT_TIMES[Key].TIMES then --当天已领取
        PushDebugMessage("#{DQDL_180814_21}")
    elseif 0 == nLocalNationalDay[Key] and curDay > g_7HIT_TIMES[Key].TIMES then --未领 过期补领
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("GetPrize")
        Set_XSCRIPT_ScriptID(892912)
        Set_XSCRIPT_Parameter(0, Key)
        Set_XSCRIPT_Parameter(1, 1)
        Set_XSCRIPT_Parameter(2, 0)
        Set_XSCRIPT_ParamCount(3)
        Send_XSCRIPT()
    end
end

--===============================================
-- 7日献好礼 -end
--===============================================

--===============================================
-- 芙蓉醉 -begin
--===============================================

function NationalDay_Tree_Show()
    NationalDay_Tree_UpdateButtonReq()
end

function NationalDay_Tree_UpdateButtonReq()
    -- 执行脚本
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("RequestNatiaonalTree") -- 脚本函数名称
    Set_XSCRIPT_ScriptID(892939) -- 脚本编号
    Set_XSCRIPT_ParamCount(0) -- 参数个数
    Send_XSCRIPT()
end

function NationalDay_Tree_UpdateInfo()
    g_NationalDay_Tree_UserState = Get_XParam_INT(0)
    g_NationalDay_Tree_HJZJ_Data = Get_XParam_INT(1)
    for i = 1, g_NationalDay_DayCount do
        local temp = Get_XParam_INT(i + 1)
        g_NationalDay_Tree_TreeState[i] = temp
    end

    if g_NationalDay_Tree_UserState == g_NationalDay_Tree_XieZhuState then
        g_NationalDay_Tree_QiongJiangCount = 0
        g_NationalDay_Tree_QiongJiangCount_Help = Get_XParam_INT(g_NationalDay_DayCount+2)
    else
        g_NationalDay_Tree_QiongJiangCount = Get_XParam_INT(g_NationalDay_DayCount+2)
    end
    g_NationalDay_Tree_ServerTime = Get_XParam_INT(g_NationalDay_DayCount+3)
    g_NationalDay_Tree_WuXiangFlag = Get_XParam_INT(g_NationalDay_DayCount+4)
    g_NationalDay_Tree_ContactState = Get_XParam_INT(g_NationalDay_DayCount+5)
    g_NationalDay_Tree_FriendUserName = Get_XParam_STR(0)
    NationalDay_Tree_FlushWindow()
end

function NationalDay_Tree_FlushWindow()
    if g_NationalDay_LastClickedId == 2 then
        NationalDay_DragTitle:SetText("#{GQYJ_180818_11}")
    end
    local g_Collect_Button =g_NationalDay_Tree_Button_Collect_One[1]
    local curDay = g_NationalDay_Tree_ServerTime
    JinFengMiZang_Cost_YuJianBK:Hide()
    --设置显示Button
    if curDay >= g_NationalDay_Tree_ButtonTime[1] and curDay <= g_NationalDay_Tree_ButtonTime[2] then
        g_NationalDay_Tree_Button_Collect_One[1]:Show()
		g_NationalDay_Tree_Button_Collect_Two[1]:Hide()
		AppleTree_Cost_QiongJiangBK:Show()
        g_Collect_Button = g_NationalDay_Tree_Button_Collect_One[1]
    elseif curDay >= g_NationalDay_Tree_ButtonTime[3] and curDay <= g_NationalDay_Tree_ButtonTime[4] then
        g_NationalDay_Tree_Button_Collect_One[1]:Hide()
        g_NationalDay_Tree_Button_Collect_Two[1]:Show()
        g_Collect_Button = g_NationalDay_Tree_Button_Collect_One[1]
        AppleTree_Cost_QiongJiangBK:Show()
    else
        return    
    end

    --琼浆数量
    JinFengMiZang_Cost_QiongJiang:SetText(
        ScriptGlobal_Format("#{GQYJ_180818_34}", g_NationalDay_Tree_QiongJiangCount)
    )
    
    AppleTree_BuLingButton:Hide()
    local is_set_buling_tips = 0
    --设置 村上春树 这界面要是和村上的小说一样好看就好了
    for i = 1, g_NationalDay_DayCount do
        local kajiType = KaJi:LuaFnGetKaJiType(110)
        -- 0花苞
        if g_NationalDay_Tree_TreeState[i] == g_NationalDay_Tree_HuaLei_info then
            g_NationalDay_Tree_Button[i]:SetToolTip(g_NationalDay_Tree_Image[i][1].Tips[kajiType])
            --设置图片
            g_NationalDay_Tree_Button[i]:SetProperty("NormalImage", g_NationalDay_Tree_Image[i][1].NormalImage)
            g_NationalDay_Tree_Button[i]:SetProperty("PushedImage", g_NationalDay_Tree_Image[i][1].PushImage)
            g_NationalDay_Tree_Button[i]:SetProperty("HoverImage", g_NationalDay_Tree_Image[i][1].HoverImage)
        end
        -- 1浮雪芙蓉
        if g_NationalDay_Tree_TreeState[i] == g_NationalDay_Tree_Fuxue_info then
            if curDay >= g_NationalDay_Tree_YuYe[1] and curDay <= g_NationalDay_Tree_YuYe[2] then
                g_NationalDay_Tree_Button[i]:SetToolTip(g_NationalDay_Tree_Image[i][2].Tips[kajiType])
            elseif curDay >= g_NationalDay_Tree_FuXue[1] and curDay <= g_NationalDay_Tree_FuXue[2] then
                g_NationalDay_Tree_Button[i]:SetToolTip(g_NationalDay_Tree_Image[i][2].Tips1[kajiType])
            end
            --设置图片
            g_NationalDay_Tree_Button[i]:SetProperty("NormalImage", g_NationalDay_Tree_Image[i][2].NormalImage)
            g_NationalDay_Tree_Button[i]:SetProperty("PushedImage", g_NationalDay_Tree_Image[i][2].PushImage)
            g_NationalDay_Tree_Button[i]:SetProperty("HoverImage", g_NationalDay_Tree_Image[i][2].HoverImage)
            if is_set_buling_tips == 0 and curDay >= g_NationalDay_Tree_FuXue[1] and curDay <= g_NationalDay_Tree_FuXue[2] then
                is_set_buling_tips = 1
                AppleTree_BuLingButton:Show()
                AppleTree_BuLingButton:SetToolTip(g_NationalDay_Tree_Image[i][2].BuLingTips[kajiType])
            end
        end 
        -- 3朱颜芙蓉
        if g_NationalDay_Tree_TreeState[i] == g_NationalDay_Tree_ZhuYan_info then
            g_NationalDay_Tree_Button[i]:SetToolTip(g_NationalDay_Tree_Image[i][4].Tips[kajiType])
            --设置图片
            g_NationalDay_Tree_Button[i]:SetProperty("NormalImage", g_NationalDay_Tree_Image[i][4].NormalImage)
            g_NationalDay_Tree_Button[i]:SetProperty("PushedImage", g_NationalDay_Tree_Image[i][4].PushImage)
            g_NationalDay_Tree_Button[i]:SetProperty("HoverImage", g_NationalDay_Tree_Image[i][4].HoverImage)
        end
        -- 4已摘取
        if g_NationalDay_Tree_TreeState[i] == g_NationalDay_Tree_KuWei_info then
            g_NationalDay_Tree_Button[i]:SetToolTip("")
            --设置图片
            g_NationalDay_Tree_Button[i]:SetProperty("NormalImage", g_NationalDay_Tree_Image[i][5].NormalImage)
            g_NationalDay_Tree_Button[i]:SetProperty("PushedImage", g_NationalDay_Tree_Image[i][5].PushImage)
            g_NationalDay_Tree_Button[i]:SetProperty("HoverImage", g_NationalDay_Tree_Image[i][5].HoverImage)
        end
    end
    --尚未参加花间酌酒活动
    if g_NationalDay_Tree_HJZJ_Data < curDay or curDay < g_NationalDay_Tree_HuoDong[1] then
        --今天已经参加了花间酌酒活动 
        g_Collect_Button:SetProperty("NormalImage", "set:AppleTree6 image:LiuLi_Normal")
        g_Collect_Button:SetProperty("PushedImage", "set:AppleTree6 image:LiuLi_Pushed")
        g_Collect_Button:SetProperty("HoverImage", "set:AppleTree6 image:LiuLi_Hover")
        g_Collect_Button:SetToolTip("#{GQYJ_180818_19}")
    else
        --g_Collect_Button:SetText("#{GQYJ_180818_23}")
        g_Collect_Button:SetProperty("NormalImage", "set:AppleTree3 image:btn1_Normal")
        g_Collect_Button:SetProperty("PushedImage", "set:AppleTree3 image:btn1_Pushed")
        g_Collect_Button:SetProperty("HoverImage", "set:AppleTree3 image:btn1_Hover")
        g_Collect_Button:SetToolTip("#{GQYJ_180818_24}")
    end
    --特殊花朵 8
    --时间未到
    if g_NationalDay_Tree_WuXiangFlag == 0 and curDay < g_NationalDay_Tree_WuXiang[1] then
        --时间到了 还未领取
        local kajiType = KaJi:LuaFnGetKaJiType(110)
	    if kajiType == 0 then 
            g_NationalDay_Tree_Button_WuXiang:SetToolTip("#{GQYJ_180818_108}")
	    else
            g_NationalDay_Tree_Button_WuXiang:SetToolTip("#{GQYJ_220817_12}")	
	    end
        g_NationalDay_Tree_Button_WuXiang:SetProperty("NormalImage", g_NationalDay_Tree_Image_WuXiang[1][1].NormalImage)
        g_NationalDay_Tree_Button_WuXiang:SetProperty("PushedImage", g_NationalDay_Tree_Image_WuXiang[1][1].PushImage)
        g_NationalDay_Tree_Button_WuXiang:SetProperty("HoverImage", g_NationalDay_Tree_Image_WuXiang[1][1].HoverImage)
    elseif
        curDay >= g_NationalDay_Tree_WuXiang[1] and curDay <= g_NationalDay_Tree_WuXiang[2] and
            g_NationalDay_Tree_WuXiangFlag == 0
     then
        --已经领取
        local kajiType = KaJi:LuaFnGetKaJiType(110)
	    if kajiType == 0 then 
            g_NationalDay_Tree_Button_WuXiang:SetToolTip("#{GQYJ_180818_139}")
	    else
            g_NationalDay_Tree_Button_WuXiang:SetToolTip("#{GQYJ_220817_27}")	
	    end
        g_NationalDay_Tree_Button_WuXiang:SetProperty("NormalImage", g_NationalDay_Tree_Image_WuXiang[1][2].NormalImage)
        g_NationalDay_Tree_Button_WuXiang:SetProperty("PushedImage", g_NationalDay_Tree_Image_WuXiang[1][2].PushImage)
        g_NationalDay_Tree_Button_WuXiang:SetProperty("HoverImage", g_NationalDay_Tree_Image_WuXiang[1][2].HoverImage)
    elseif g_NationalDay_Tree_WuXiangFlag == 1 then
        g_NationalDay_Tree_Button_WuXiang:SetToolTip("")
        g_NationalDay_Tree_Button_WuXiang:SetProperty("NormalImage", g_NationalDay_Tree_Image_WuXiang[1][3].NormalImage)
        g_NationalDay_Tree_Button_WuXiang:SetProperty("PushedImage", g_NationalDay_Tree_Image_WuXiang[1][3].PushImage)
        g_NationalDay_Tree_Button_WuXiang:SetProperty("HoverImage", g_NationalDay_Tree_Image_WuXiang[1][3].HoverImage)
    end

    --右侧说明文字
    if curDay >= g_NationalDay_Tree_YuRe[1] and curDay <= g_NationalDay_Tree_YuRe[2] then
        --未签约
        if g_NationalDay_Tree_UserState == g_NationalDay_Tree_NoContactState then
            AppleTree_Text:SetText("#{GQYJ_180818_26}")
            AppleTree_GotoButton:Hide()
            AppleTree_GotoButton:SetToolTip("#{GQYJ_180818_27}")
        elseif g_NationalDay_Tree_UserState == g_NationalDay_Tree_QiuZhuState then
            AppleTree_Text:SetText(ScriptGlobal_Format("#{GQYJ_180818_28}", g_NationalDay_Tree_FriendUserName))
            AppleTree_GotoButton:Hide()
        elseif g_NationalDay_Tree_UserState == g_NationalDay_Tree_XieZhuState then
            AppleTree_Text:SetText(ScriptGlobal_Format("#{GQYJ_180818_29}", g_NationalDay_Tree_FriendUserName))
            AppleTree_GotoButton:Hide()
        end
    end

    if curDay >= g_NationalDay_Tree_NoContactState_Time[1] and curDay <= g_NationalDay_Tree_NoContactState_Time[2] then
        --未签订契约
        if g_NationalDay_Tree_UserState == g_NationalDay_Tree_NoContactState then
            AppleTree_Text:SetText("#{GQYJ_180818_30}")
            AppleTree_GotoButton:Hide()
            AppleTree_GotoButton:SetToolTip("#{GQYJ_180818_31}")
        end
    end
    if curDay >= g_NationalDay_Tree_NoContactState_Time[3] and curDay <= g_NationalDay_Tree_NoContactState_Time[4] then
        AppleTree_Text:SetText("#{GQYJ_180818_32}")
        AppleTree_GotoButton:Hide()
    end

    if curDay >= g_NationalDay_Tree_ContactState_Time[1] and curDay <= g_NationalDay_Tree_ContactState_Time[2] then
        if g_NationalDay_Tree_UserState == g_NationalDay_Tree_QiuZhuState then
            AppleTree_Text:SetText(ScriptGlobal_Format("#{GQYJ_180818_28}", g_NationalDay_Tree_FriendUserName))
            AppleTree_GotoButton:Hide()
        elseif g_NationalDay_Tree_UserState == g_NationalDay_Tree_XieZhuState then
            AppleTree_Text:SetText(
                ScriptGlobal_Format(
                    "#{GQYJ_180818_94}",
                    g_NationalDay_Tree_FriendUserName,
                    g_NationalDay_Tree_QiongJiangCount_Help
                )
            )
            AppleTree_GotoButton:Hide()
        end
    end
    if curDay >= g_NationalDay_Tree_ContactState_Time[3] and curDay <= g_NationalDay_Tree_ContactState_Time[4] then
        if g_NationalDay_Tree_ContactState == 0 and g_NationalDay_Tree_UserState == g_NationalDay_Tree_XieZhuState then
            AppleTree_Text:SetText(ScriptGlobal_Format("#{GQYJ_180818_140}", g_NationalDay_Tree_FriendUserName))
            AppleTree_GotoButton:Hide()
        end
        if g_NationalDay_Tree_UserState == g_NationalDay_Tree_QiuZhuState and g_NationalDay_Tree_ContactState == 1 then
            AppleTree_Text:SetText("#{GQYJ_180818_32}")
            AppleTree_GotoButton:Hide()
        end
    end
    if curDay >= g_NationalDay_Tree_ContactState_Time[1] and curDay <= g_NationalDay_Tree_ContactState_Time[4] then
        if g_NationalDay_Tree_ContactState == 1 then
            AppleTree_Text:SetText("#{GQYJ_180818_32}")
            AppleTree_GotoButton:Hide()
        end
    end
    --玉剪数量
    --local YuJianCount = PlayerPackage:CountAvailableItemByIDTable(38002561)
    --JinFengMiZang_Cost_YuJian:SetText(ScriptGlobal_Format("#{GQYJ_180818_36}", YuJianCount ))
end

--===============================================
--点击花朵
--===============================================
function NationalDay_Tree_OnClick(Key)
    -- 执行脚本
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("GetPrize") -- 脚本函数名称
    Set_XSCRIPT_ScriptID(892939) -- 脚本编号
    Set_XSCRIPT_Parameter(0, Key) -- 索引
    Set_XSCRIPT_Parameter(1, 0) -- 是否
    Set_XSCRIPT_ParamCount(2) -- 参数个数
    Send_XSCRIPT()
end
--===============================================
--帮助
--===============================================
function NationalDay_Tree_Help_Click()
    PushEvent("OPEN_NATIONAL_TREE_HELP")
end

--===============================================
--玉液Button
--===============================================
function NationalDay_Tree_YuYe_Button_Click()
    local curDay = tonumber(DataPool:GetServerDayTime())
    if curDay < g_NationalDay_Tree_YuRe[1] or curDay > g_NationalDay_Tree_HuoDong[2] then
        PushDebugMessage("#{GQYJ_180818_20}")
        NationalDay_Close()
        return
    end
    if curDay < g_NationalDay_Tree_YuYe[1] or curDay > g_NationalDay_Tree_YuYe[2] then
        PushDebugMessage("#{GQYJ_180818_179}")
        return
    end
    --是否已经完成花间酌酒
    if g_NationalDay_Tree_HJZJ_Data < curDay then
        -- 执行脚本
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("LingQuYuYe") -- 脚本函数名称
        Set_XSCRIPT_ScriptID(892939) -- 脚本编号 
        Set_XSCRIPT_ParamCount(1) -- 参数个数
        Send_XSCRIPT() 
    elseif g_NationalDay_Tree_HJZJ_Data == curDay then
        -- 执行脚本
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("UseYuYe") -- 脚本函数名称
        Set_XSCRIPT_ScriptID(892939) -- 脚本编号
        Set_XSCRIPT_Parameter(0, 0) -- 是否
        Set_XSCRIPT_ParamCount(1) -- 参数个数
        Send_XSCRIPT()
    else
        return
    end
end

--===============================================
--琼浆Button
--===============================================
function NationalDay_Tree_QiongJiang_Button_Click()
    local curDay = tonumber(DataPool:GetServerDayTime())
    if curDay < g_NationalDay_Tree_YuRe[1] or curDay > g_NationalDay_Tree_HuoDong[2] then
        PushDebugMessage("#{GQYJ_180818_20}")
        NationalDay_Close()
        return
    end
    if curDay < g_NationalDay_Tree_HuoDong[1] or curDay > g_NationalDay_Tree_HuoDong[2] then
        PushDebugMessage("#{GQYJ_180818_41}")
        return
    end
    --是否拥有琼浆
    if g_NationalDay_Tree_QiongJiangCount <= 0 then
        PushDebugMessage("#{GQYJ_180818_49}")
        return
    end
    --使用琼浆
    -- 执行脚本
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("UseQiongJiang") -- 脚本函数名称
    Set_XSCRIPT_ScriptID(892939) -- 脚本编号
    Set_XSCRIPT_ParamCount(0) -- 参数个数
    Send_XSCRIPT()
end
function NationalDay_Tree_GotoButton_Click()
    curSceneID = GetSceneID()
    if 0 == curSceneID then
        AutoRunToTarget(266, 255)
    else
        AutoRunToTargetEx(266, 255, 0)
    end
    SetAutoRunTargetNPCName("苏曼卿")
    return
end

--===============================================
--点击无相灵石礼包
--===============================================
function NationalDay_Tree_OnClick_Sign()
    --特殊花朵 8

    local curDay = tonumber(DataPool:GetServerDayTime())
    --时间未到
    if g_NationalDay_Tree_WuXiangFlag == 0 and curDay < g_NationalDay_Tree_WuXiang[1] then
        --时间到了 还未领取
        PushDebugMessage("#{GQYJ_180818_116}")
        return
    elseif
        curDay >= g_NationalDay_Tree_WuXiang[1] and curDay <= g_NationalDay_Tree_WuXiang[2] and
            g_NationalDay_Tree_WuXiangFlag == 0
     then
        --已经领取
        -- 执行脚本
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("GetPrize_WuXiang") -- 脚本函数名称
        Set_XSCRIPT_ScriptID(892939) -- 脚本编号
        Set_XSCRIPT_ParamCount(0) -- 参数个数
        Send_XSCRIPT()
        return
    elseif g_NationalDay_Tree_WuXiangFlag == 1 then
        PushDebugMessage("#{GQYJ_180818_53}")
        return
    end
end
--===============================================
--补领
--===============================================
function NationalDay_Tree_BuLing_Button_Click()  
    -- 执行脚本
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("BuLing") -- 脚本函数名称
    Set_XSCRIPT_ScriptID(892939) -- 脚本编号
    Set_XSCRIPT_Parameter(0, 0) -- 是否
    Set_XSCRIPT_ParamCount(1) -- 参数个数
    Send_XSCRIPT()
    return 
end


--===============================================
-- 芙蓉醉 -end
--===============================================
