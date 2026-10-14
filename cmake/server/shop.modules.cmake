# shop: cửa hàng NPC của máy chủ (bảng cửa hàng, hàng cố định và ngẫu nhiên, tồn kho làm mới theo tick, mua, bán, mua lại,
# sửa, thu hồi phế phẩm). Không mạng, không database; dựa vào item (mẫu, kế hoạch túi và ví), dice và ids.
game_module(shop
    src/server/shop/types.cpp
    src/server/shop/tables.cpp
    src/server/shop/npc_shop.cpp
    src/server/shop/trade.cpp)
target_link_libraries(game_shop PUBLIC game_core game_ids game_dice game_item)
