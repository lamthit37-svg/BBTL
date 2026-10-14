# ipc: kênh bền hai chiều giữa các tiến trình máy chủ (gate, zone, world), loopback, bọc bằng khoá cụm.
# relay.cpp là khung gate ↔ zone dựng trên protocol.
game_module(ipc src/server/ipc/link.cpp src/server/ipc/relay.cpp)
target_link_libraries(game_ipc PUBLIC game_core game_net game_secure game_protocol)
