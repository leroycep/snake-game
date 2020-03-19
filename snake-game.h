#ifndef SNAKE_2D_GAME_H
#define SNAKE_2D_GAME_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

void onInit(void);
void onMouseMove(int32_t x, int32_t y);
void onKeyDown(uint16_t scancode);
void onKeyUp(uint16_t scancode);
void onResize(void);
void update(double current_time, double delta);
void render(double alpha);
bool hasQuit(void);

#ifdef __cplusplus
} // extern "C"
#endif

extern uint16_t SCANCODE_ESCAPE;
extern uint16_t SCANCODE_W;
extern uint16_t SCANCODE_A;
extern uint16_t SCANCODE_S;
extern uint16_t SCANCODE_D;
extern uint16_t SCANCODE_LEFT;
extern uint16_t SCANCODE_RIGHT;
extern uint16_t SCANCODE_UP;
extern uint16_t SCANCODE_DOWN;
extern double MAX_DELTA_SECONDS;
extern double TICK_DELTA_SECONDS;
extern uint8_t QUIT;
extern uint8_t shouldQuit;

#endif // SNAKE_2D_GAME_H
