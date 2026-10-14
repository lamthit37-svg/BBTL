# item: lõi vật phẩm và kinh tế thuần của máy chủ (mẫu vật phẩm, thể hiện, túi/kho/ví, sinh trang bị ngẫu nhiên, mặc/tháo,
# giá bán/sửa, bản ghi nhị phân). Không mạng, không database; chỉ dùng ids, dice, protocol (tầng byte) và core.
game_module(item
    src/server/item/types.cpp
    src/server/item/rows.cpp
    src/server/item/catalog.cpp
    src/server/item/limits.cpp
    src/server/item/roll.cpp
    src/server/item/factory.cpp
    src/server/item/inventory.cpp
    src/server/item/planner.cpp
    src/server/item/planner_equip.cpp
    src/server/item/price.cpp
    src/server/item/bonus.cpp
    src/server/item/codec.cpp)
target_link_libraries(game_item PUBLIC game_core game_ids game_dice game_protocol)
