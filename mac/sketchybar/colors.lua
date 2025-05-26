return {
  black      = 0xff0e0f16, -- crust
  white      = 0xffb5c1f1, -- text
  red        = 0xffea7183, -- red
  green      = 0xff96d382, -- green
  blue       = 0xff739df2, -- blue
  yellow     = 0xffeaca89, -- yellow
  orange     = 0xfff39967, -- peach
  magenta    = 0xfff2a7de, -- pink
  grey       = 0xff717997, -- overlay1
  transparent = 0x00000000,

  bar = {
    bg     = 0xff1E1E2E, -- surface0
    border = 0xff505469, -- surface1
  },
  popup = {
    bg     = 0xff2c2f40, -- surface0 with alpha
    border = 0xff505469  -- surface2
  },
  bg1 = 0xff141620, -- mantle
  bg2 = 0xff1a1c2a, -- base

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
