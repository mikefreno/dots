return {
black      = 0xff7b5d44,
white      = 0xff8f6f56,
red        = 0xffc14a4a,
green      = 0xff6c782e,
blue       = 0xff45707a,
yellow     = 0xffa96b2c,
orange     = 0xffc35e0a,
magenta    = 0xff945e80,
grey       = 0xff6e5949,
transparent = 0x00000000,
bar = {
bg     = 0xf0fbf1c7,
border = 0xffc9c19f,
},
popup = {
bg     = 0xfcfbf1c7,
border = 0xffc9c19f
},
bg1 = 0xfffbf1c7,
bg2 = 0xfff2e5bc,
with_alpha = function(color, alpha)
if alpha > 1.0 or alpha < 0.0 then return color end
return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
end,
}
