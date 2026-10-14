# bus: hàng đợi sự kiện gameplay theo tick (giết quái, vào vùng, đổi vật phẩm, nói chuyện, lên cấp) với thứ tự xả cố định.
game_module(bus src/server/bus/bus.cpp)
target_link_libraries(game_bus PUBLIC game_core game_ids)
