const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#120d15", /* black   */
  [1] = "#965E34", /* red     */
  [2] = "#9B6768", /* green   */
  [3] = "#B48970", /* yellow  */
  [4] = "#6F6E94", /* blue    */
  [5] = "#986D8C", /* magenta */
  [6] = "#A4919D", /* cyan    */
  [7] = "#d1ccd0", /* white   */

  /* 8 bright colors */
  [8]  = "#928e91",  /* black   */
  [9]  = "#965E34",  /* red     */
  [10] = "#9B6768", /* green   */
  [11] = "#B48970", /* yellow  */
  [12] = "#6F6E94", /* blue    */
  [13] = "#986D8C", /* magenta */
  [14] = "#A4919D", /* cyan    */
  [15] = "#d1ccd0", /* white   */

  /* special colors */
  [256] = "#120d15", /* background */
  [257] = "#d1ccd0", /* foreground */
  [258] = "#d1ccd0",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
