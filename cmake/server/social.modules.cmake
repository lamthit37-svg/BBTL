# social: lõi xã hội của tiến trình world (đội, bang, thành bang, quan hệ, thư, chat, xếp hạng, thông báo).
# Thuần: không mạng, không database; dùng table (đọc TSV), ids và protocol (tầng byte của khối bền).
game_module(social
    src/server/social/chat.cpp
    src/server/social/city.cpp
    src/server/social/codec.cpp
    src/server/social/guild.cpp
    src/server/social/limits.cpp
    src/server/social/mail.cpp
    src/server/social/notice.cpp
    src/server/social/rank.cpp
    src/server/social/relation.cpp
    src/server/social/team.cpp
    src/server/social/text.cpp
    src/server/social/wordfilter.cpp)
target_link_libraries(game_social PUBLIC game_core game_table game_ids game_protocol)
