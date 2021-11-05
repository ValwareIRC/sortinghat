import strformat

const
  colorPrefix* = "\x03"
  underline* = "\x1f"

type Color* = enum
  clrWhite = fmt"{colorPrefix}0"
  clrBlack = fmt"{colorPrefix}1"
  clrBlue = fmt"{colorPrefix}2"
  clrGreen = fmt"{colorPrefix}3"
  clrRed = fmt"{colorPrefix}4"
  clrBrown = fmt"{colorPrefix}5"
  clrMagenta = fmt"{colorPrefix}6"
  clrOrange = fmt"{colorPrefix}7"
  clrYellow = fmt"{colorPrefix}8"
  clrLightGreen = fmt"{colorPrefix}9"
  clrCyan = fmt"{colorPrefix}10"
  clrLightCyan = fmt"{colorPrefix}11"
  clrLightBlue = fmt"{colorPrefix}12"
  clrPink = fmt"{colorPrefix}13"
  clrGrey = fmt"{colorPrefix}14"
  clrLightGrey = fmt"{colorPrefix}15"
  clrDefault = fmt"{colorPrefix}99"

const rainbowColors* =
  {
    clrRed,
    clrOrange,
    clrYellow,
    clrGreen,
    clrBlue,
    clrMagenta,
    clrPink
  }

