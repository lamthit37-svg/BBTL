# ledger: sổ cái nguyên tử (thu, trả, thưởng) trên ba cổng trừu tượng của một nhân vật; không biết túi hay ví cụ thể.
game_module(ledger src/server/ledger/ledger.cpp)
target_link_libraries(game_ledger PUBLIC game_core)
