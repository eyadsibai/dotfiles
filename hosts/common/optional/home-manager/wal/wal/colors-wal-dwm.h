static const char norm_fg[] = "#d1ccd0";
static const char norm_bg[] = "#120d15";
static const char norm_border[] = "#928e91";

static const char sel_fg[] = "#d1ccd0";
static const char sel_bg[] = "#9B6768";
static const char sel_border[] = "#d1ccd0";

static const char urg_fg[] = "#d1ccd0";
static const char urg_bg[] = "#965E34";
static const char urg_border[] = "#965E34";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
