# ops: điều kiện và hiệu ứng ĐÓNG của gameplay (nhiệm vụ, hội thoại, NPC), đánh giá thuần trên góc nhìn nhân vật.
game_module(ops src/server/ops/ops.cpp src/server/ops/program.cpp)
target_link_libraries(game_ops PUBLIC game_core game_table game_ids)
