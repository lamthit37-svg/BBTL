/*
** 
** Standard mathematical library
** See Copyright Notice in lua.h
*/


#include <stdlib.h>
#include <math.h>

#define lmathlib_c

#include "lua.h"

#include "lauxlib.h"
#include "lualib.h"


#undef PI
#define PI (3.14159265358979323846)
#define RADIANS_PER_DEGREE (PI/180.0)



/*
** If you want Lua to operate in degrees (instead of radians),
** define USE_DEGREES
*/
#ifdef USE_DEGREES
#define FROMRAD(a)	((a)/RADIANS_PER_DEGREE)
#define TORAD(a)	((a)*RADIANS_PER_DEGREE)
#else
#define FROMRAD(a)	(a)
#define TORAD(a)	(a)
#endif


/*
** Khác gốc (bản dựng của dự án, xem NGUON.txt): hàm toán trả NaN theo x64 ở mọi nền tảng (luanum_settle: NaN của đối số
** thắng, không thì NaN âm "-1.#IND"), frexp theo MSVCR110, rand và srand là LCG của MSVCR110 (luanum_rand), phép tính cỡ
** khoảng của random quấn vòng bằng số học không dấu như x64, đối số tính tuần tự từ trái sang phải.
*/

static int math_abs (lua_State *L) {
  lua_pushnumber(L, fabs(luaL_checknumber(L, 1)));
  return 1;
}

static int math_sin (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(sin(TORAD(x)), x));
  return 1;
}

static int math_cos (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(cos(TORAD(x)), x));
  return 1;
}

static int math_tan (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(tan(TORAD(x)), x));
  return 1;
}

static int math_asin (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(FROMRAD(asin(x)), x));
  return 1;
}

static int math_acos (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(FROMRAD(acos(x)), x));
  return 1;
}

static int math_atan (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(FROMRAD(atan(x)), x));
  return 1;
}

static int math_atan2 (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_Number y = luaL_checknumber(L, 2);
  lua_pushnumber(L, luanum_settle2(FROMRAD(atan2(x, y)), x, y));
  return 1;
}

static int math_ceil (lua_State *L) {
  lua_pushnumber(L, ceil(luaL_checknumber(L, 1)));
  return 1;
}

static int math_floor (lua_State *L) {
  lua_pushnumber(L, floor(luaL_checknumber(L, 1)));
  return 1;
}

static int math_mod (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_Number y = luaL_checknumber(L, 2);
  lua_pushnumber(L, luanum_settle2(fmod(x, y), x, y));
  return 1;
}

static int math_sqrt (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(sqrt(x), x));
  return 1;
}

static int math_pow (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_Number y = luaL_checknumber(L, 2);
  lua_pushnumber(L, luanum_settle2(pow(x, y), x, y));
  return 1;
}

static int math_log (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(log(x), x));
  return 1;
}

static int math_log10 (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(log10(x), x));
  return 1;
}

static int math_exp (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  lua_pushnumber(L, luanum_settle1(exp(x), x));
  return 1;
}

static int math_deg (lua_State *L) {
  lua_pushnumber(L, luaL_checknumber(L, 1)/RADIANS_PER_DEGREE);
  return 1;
}

static int math_rad (lua_State *L) {
  lua_pushnumber(L, luaL_checknumber(L, 1)*RADIANS_PER_DEGREE);
  return 1;
}

static int math_frexp (lua_State *L) {
  int e = 0;
  lua_Number x = luaL_checknumber(L, 1);
  lua_Number mantissa = 0;
  /* MSVCR110: +0 và 0 cho cả -0; số vô hạn cho NaN âm và -1; NaN cho chính nó và -1 (đo trên LuaPlus.dll). */
  if (x == 0) mantissa = 0;
  else if (!isfinite(x)) { mantissa = luanum_settle1(x - x, x); e = -1; }
  else mantissa = frexp(x, &e);
  lua_pushnumber(L, mantissa);
  lua_pushnumber(L, e);
  return 2;
}

static int math_ldexp (lua_State *L) {
  lua_Number x = luaL_checknumber(L, 1);
  int e = luaL_checkint(L, 2);
  lua_pushnumber(L, luanum_settle1(ldexp(x, e), x));
  return 1;
}



static int math_min (lua_State *L) {
  int n = lua_gettop(L);  /* number of arguments */
  lua_Number dmin = luaL_checknumber(L, 1);
  int i;
  for (i=2; i<=n; i++) {
    lua_Number d = luaL_checknumber(L, i);
    if (d < dmin)
      dmin = d;
  }
  lua_pushnumber(L, dmin);
  return 1;
}


static int math_max (lua_State *L) {
  int n = lua_gettop(L);  /* number of arguments */
  lua_Number dmax = luaL_checknumber(L, 1);
  int i;
  for (i=2; i<=n; i++) {
    lua_Number d = luaL_checknumber(L, i);
    if (d > dmax)
      dmax = d;
  }
  lua_pushnumber(L, dmax);
  return 1;
}


static int math_random (lua_State *L) {
  /* the `%' avoids the (rare) case of r==1, and is needed also because on
     some systems (SunOS!) `rand()' may return a value larger than RAND_MAX */
  lua_Number r = (lua_Number)(luanum_rand()%LUANUM_RAND_MAX) / (lua_Number)LUANUM_RAND_MAX;
  switch (lua_gettop(L)) {  /* check number of arguments */
    case 0: {  /* no arguments */
      lua_pushnumber(L, r);  /* Number between 0 and 1 */
      break;
    }
    case 1: {  /* only upper limit */
      int u = luaL_checkint(L, 1);
      luaL_argcheck(L, 1<=u, 1, "interval is empty");
      lua_pushnumber(L, (int)floor(r*u)+1);  /* int between 1 and `u' */
      break;
    }
    case 2: {  /* lower and upper limits */
      int l = luaL_checkint(L, 1);
      int u = luaL_checkint(L, 2);
      luaL_argcheck(L, l<=u, 2, "interval is empty");
      int span = (int)((unsigned int)u - (unsigned int)l + 1U);  /* u - l + 1 quấn vòng như x64 */
      lua_pushnumber(L, (int)((unsigned int)(int)floor(r*span) + (unsigned int)l));  /* int between `l' and `u' */
      break;
    }
    default: return luaL_error(L, "wrong number of arguments");
  }
  return 1;
}


static int math_randomseed (lua_State *L) {
  luanum_srand((unsigned int)luaL_checkint(L, 1));
  return 0;
}


static const luaL_reg mathlib[] = {
  {"abs",   math_abs},
  {"sin",   math_sin},
  {"cos",   math_cos},
  {"tan",   math_tan},
  {"asin",  math_asin},
  {"acos",  math_acos},
  {"atan",  math_atan},
  {"atan2", math_atan2},
  {"ceil",  math_ceil},
  {"floor", math_floor},
  {"mod",   math_mod},
  {"frexp", math_frexp},
  {"ldexp", math_ldexp},
  {"sqrt",  math_sqrt},
  {"min",   math_min},
  {"max",   math_max},
  {"log",   math_log},
  {"log10", math_log10},
  {"exp",   math_exp},
  {"deg",   math_deg},
  {"pow",   math_pow},
  {"rad",   math_rad},
  {"random",     math_random},
  {"randomseed", math_randomseed},
  {NULL, NULL}
};


/*
** Open math library
*/
LUALIB_API int luaopen_math (lua_State *L) {
  luaL_openlib(L, LUA_MATHLIBNAME, mathlib, 0);
  lua_pushliteral(L, "pi");
  lua_pushnumber(L, PI);
  lua_settable(L, -3);
  lua_pushliteral(L, "__pow");
  lua_pushcfunction(L, math_pow);
  lua_settable(L, LUA_GLOBALSINDEX);
  return 1;
}

