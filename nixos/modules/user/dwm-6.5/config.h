/* See LICENSE file for copyright and license details. */

/* appearance */
static unsigned       int borderpx        = 0;     /* border pixel of windows */
static unsigned       int snap            = 32;    /* snap pixel */
static const unsigned int gappih          = 6;     /* horiz inner gap between windows */
static const unsigned int gappiv          = 6;     /* vert inner gap between windows */
static const unsigned int gappoh          = 10;    /* horiz outer gap between windows and screen edge */
static const unsigned int gappov          = 10;    /* vert outer gap between windows and screen edge */
static const unsigned int systraypinning  = 0;     /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayonleft   = 0;     /* 0: systray in the right corner, >0: systray on left of status text */
static const unsigned int systrayspacing  = 2;     /* systray spacing */
static const          int scalepreview    = 4;     /* preview scaling (display w and h / scalepreview) */
static const          int previewbar      = 1;     /* show the bar in the preview window */
static const int systraypinningfailfirst  = 1;     /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray              = 1;     /* 0 means no systray */
static int showbar                        = 1;     /* 0 means no bar */
static int topbar                         = 1;     /* 0 means bottom bar */
static       int smartgaps                = 0;     /* 1 means no outer gap when there is only one window */
static const char *fonts[]    = { "monospace:size=10" };
static const char dmenufont[] = "monospace:size=10";
static char normbgcolor[]     = "#222222";
static char normbordercolor[] = "#444444";
static char normfgcolor[]     = "#bbbbbb";
static char selfgcolor[]      = "#eeeeee";
static char selbordercolor[]  = "#005577";
static char selbgcolor[]      = "#39363d";
static char *colors[][3]      = {
	/*               fg           bg           border   */
	[SchemeNorm] = { normfgcolor, normbgcolor, normbordercolor },
	[SchemeSel]  = { selfgcolor,  selbgcolor,  selbordercolor  },
};

#define ICONSIZE 16   /* icon size */
#define ICONSPACING 5 /* space between icon and title */

static const char *const autostart[] = {
  "sh", "-c", "hsetroot -cover ~/.dotfiles/wallpapers/aletiune_2.png", NULL,
  "sh", "-c", "~/.dotfiles/nixos/modules/user/dwm-6.5/bar/dwm_bar.sh", NULL,
	"picom", NULL,
	"nm-applet", NULL,
	NULL
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
    /* class       instance    title               tags mask     isfloating   monitor */
    { NULL,        NULL,   "Picture-in-Picture",    ~0,         1,           -1 },
    { NULL,        NULL,       "Zen Browser",       1 << 2,     0,           -1 },
    { "Gimp",      NULL,       NULL,                0,          1,           -1 },
    { "Firefox",   NULL,       NULL,                1 << 8,     0,           -1 },
    { "Spotify",   NULL,       NULL,                1 << 4,     0,           -1 },
    { "Steam",     NULL,       NULL,                1 << 3,     0,           -1 },
};

/* layout(s) */
static float mfact     = 0.50; /* factor of master area size [0.05..0.95] */
static int nmaster     = 1;    /* number of clients in master area */
static int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int attachbelow = 1;    /* 1 means attach after the currently active window */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

#define FORCE_VSPLIT 1  /* nrowgrid layout: force two clients to always split vertically */
#include "vanitygaps.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[\\]",     dwindle },
 	{ "[M]",      monocle },
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ NULL,       NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[]        = { "rofi", "-show", "drun", NULL };
static const char *termcmd[]         = { "kitty", NULL };
static const char *filescmd[]        = { "nautilus", NULL };
static const char *tempupcmd[]       = { "/bin/sh", "-c", "~/.dotfiles/nixos/modules/user/scripts/nightlight_warmer.sh", NULL };
static const char *tempdowncmd[]     = { "/bin/sh", "-c", "~/.dotfiles/nixos/modules/user/scripts/nightlight_cooler.sh", NULL };
static const char *printscreencmd[]  = { "/bin/sh", "-c", "~/.dotfiles/nixos/modules/user/scripts/screenshot.sh", NULL };

#include <X11/XF86keysym.h>
static const char *volupcmd[]        = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+", NULL };
static const char *voldowncmd[]      = { "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-", NULL };
static const char *mutecmd[]         = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle", NULL };
static const char *micmutecmd[]      = { "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle", NULL };
static const char *briupcmd[]        = { "brightnessctl", "s", "10%+", NULL };
static const char *bridowncmd[]      = { "brightnessctl", "s", "10%-", NULL };
static const char *nextcmd[]         = { "playerctl", "next", NULL };
static const char *playpausecmd[]    = { "playerctl", "play-pause", NULL };
static const char *prevcmd[]         = { "playerctl", "previous", NULL };

/*
 * Xresources preferences to load at startup
 */
ResourcePref resources[] = {
	{ "normbgcolor",        STRING,  &normbgcolor },
	{ "normbordercolor",    STRING,  &normbordercolor },
	{ "normfgcolor",        STRING,  &normfgcolor },
	{ "selbgcolor",         STRING,  &selbgcolor },
	{ "selbordercolor",     STRING,  &selbordercolor },
	{ "selfgcolor",         STRING,  &selfgcolor },
	
	{ "color2",             STRING,  &selbgcolor },
	
	{ "borderpx",          	INTEGER, &borderpx },
	{ "snap",          		  INTEGER, &snap },
	{ "showbar",          	INTEGER, &showbar },
	{ "topbar",            	INTEGER, &topbar },
	{ "nmaster",          	INTEGER, &nmaster },
	{ "resizehints",       	INTEGER, &resizehints },
	{ "mfact",      	    	FLOAT,   &mfact },
};

#include "movestack.c"
static const Key keys[] = {
	/* modifier                     key        function        argument */
  { 0,                            XK_Print,  spawn,          {.v = printscreencmd } },
	{ MODKEY,                       XK_r,      spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_q,      spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_e,      spawn,          {.v = filescmd } },
	{ MODKEY|ShiftMask,             XK_Left,   moveresize,     {.v = "-25x 0y 0w 0h" } },
	{ MODKEY|ShiftMask,             XK_Down,   moveresize,     {.v = "0x 25y 0w 0h" } },
	{ MODKEY|ShiftMask,             XK_Up,     moveresize,     {.v = "0x -25y 0w 0h" } },
	{ MODKEY|ShiftMask,             XK_Right,  moveresize,     {.v = "25x 0y 0w 0h" } },
	{ MODKEY,                       XK_Left,   moveresize,     {.v = "0x 0y -25w 0h" } },
	{ MODKEY,                       XK_Down,   moveresize,     {.v = "0x 0y 0w 25h" } },
	{ MODKEY,                       XK_Up,     moveresize,     {.v = "0x 0y 0w -25h" } },
	{ MODKEY,                       XK_Right,  moveresize,     {.v = "0x 0y 25w 0h" } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
  { MODKEY,                       XK_l,      focusstack,     {.i = +1 } },
  { MODKEY,                       XK_h,      focusstack,     {.i = -1 } },
  { MODKEY,                       XK_u,      setmfact,       {.f = -0.05} },
  { MODKEY,                       XK_p,      setmfact,       {.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_h,      movestack,      {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_l,      movestack,      {.i = -1 } },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY|ShiftMask,             XK_q,      killclient,     {0} },
	{ MODKEY,                       XK_f,      setlayout,      {0} },
	{ MODKEY,                       XK_c,      togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
  { MODKEY,                       XK_F11,    spawn,          {.v = tempdowncmd } },
  { MODKEY,                       XK_F12,    spawn,          {.v = tempupcmd } },
  { 0, XF86XK_AudioRaiseVolume,              spawn,          {.v = volupcmd } },
  { 0, XF86XK_AudioLowerVolume,              spawn,          {.v = voldowncmd } },
  { 0, XF86XK_AudioMute,                     spawn,          {.v = mutecmd } },
  { 0, XF86XK_AudioMicMute,                  spawn,          {.v = micmutecmd } },
  { 0, XF86XK_MonBrightnessUp,               spawn,          {.v = briupcmd } },
  { 0, XF86XK_MonBrightnessDown,             spawn,          {.v = bridowncmd } },
  { 0, XF86XK_AudioNext,                     spawn,          {.v = nextcmd } },
  { 0, XF86XK_AudioPlay,                     spawn,          {.v = playpausecmd } },
  { 0, XF86XK_AudioPrev,                     spawn,          {.v = prevcmd } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_e,      quit,           {0} },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
