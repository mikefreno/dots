-- Hyprland Lua Configuration
-- Migrated from legacy .conf format

------------------
---- MONITORS ----
------------------

hl.monitor({
    output   = "DP-3",
    mode     = "3840x2160@144",
    position = "0x0",
    scale    = 1,
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "thunar"
local ipc         = "qs -c noctalia-shell ipc call"
local menu        = ipc .. " launcher toggle"


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -c noctalia-shell --no-duplicate")
    hl.exec_cmd("pass-secret-service")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("~/code/actions-runner/run.sh")
    hl.exec_cmd("sudo nvidia-smi -i 0 -pl 200")
    hl.exec_cmd("~/.config/hypr/startup-app-launcher.sh")
    hl.exec_cmd("turn_off_lights")
    hl.exec_cmd("sshfs pan:/ServerStore /remote")
    hl.exec_cmd("hypridle")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_SIZE", "32")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1.5")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 8,
        gaps_out = 16,
        border_size = 4,
        resize_on_border = false,
        allow_tearing = true,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 16,
        rounding_power = 4,
        active_opacity   = 1.0,
        dim_inactive     = true,
        dim_strength     = 0.1,
        inactive_opacity = 0.95,

        shadow = {
            enabled      = true,
            range        = 8,
            render_power = 2,
            color        = 0x1a1a1aee,
        },

        blur = {
            enabled         = true,
            size            = 6,
            passes          = 3,
            new_optimizations = true,
            ignore_opacity  = true,
            xray            = false,
            noise           = 0.05,
            contrast        = 1.0,
            brightness      = 0.8,
            vibrancy        = 0.5,
            vibrancy_darkness = 0.5,
            popups          = true,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 3.94, bezier = "easeInOutCubic", style = "slidefade" })

-- Layout Configuration
hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_on_top = true,
    },
})

-- Misc Configuration
hl.config({
    misc = {
        force_default_wallpaper    = 1,
        disable_hyprland_logo      = true,
        disable_splash_rendering   = false,
        mouse_move_enables_dpms    = true,
        key_press_enables_dpms     = true,
        animate_manual_resizes     = true,
        animate_mouse_windowdragging = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout    = "us",
        kb_options   = "caps:escape",
        follow_mouse = 1,
        sensitivity  = 0,
        natural_scroll = true,

        touchpad = {
            disable_while_typing = true,
            scroll_factor        = 1.0,
        },
    },
})

hl.config({
    gestures = {
        workspace_swipe_distance         = 300,
        workspace_swipe_invert           = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio     = 0.5,
        workspace_swipe_create_new       = true,
    },
})

hl.config({
    cursor = {
        use_cpu_buffer   = 1,
        inactive_timeout = 30,
    },
})


-----------------------
---- PERMISSIONS ----
-----------------------

hl.config({
    ecosystem = {
        enforce_permissions = false,
    },
})


---------------------
---- WORKSPACES ----
---------------------

local tab_one   = "1"
local tab_two   = "2"
local tab_three = "3"
local tab_four  = "4"
local tab_five  = "5"
local tab_six   = "6"

hl.workspace_rule({
    workspace    = "1",
    default_name = tab_one,
    persistent   = true,
    is_default   = true,
})
hl.workspace_rule({
    workspace    = "2",
    default_name = tab_two,
    persistent   = true,
})
hl.workspace_rule({
    workspace    = "3",
    default_name = tab_three,
    persistent   = true,
})
hl.workspace_rule({
    workspace    = "4",
    default_name = tab_four,
    persistent   = true,
})
hl.workspace_rule({
    workspace    = "5",
    default_name = tab_five,
})
hl.workspace_rule({
    workspace    = "6",
    default_name = tab_six,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Core bindings
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind("CONTROL + SHIFT + " .. mainMod .. " + M", hl.dsp.exit())
hl.bind("SHIFT + " .. mainMod .. " + F", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(ipc .. " controlCenter toggle"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(ipc .. " settings toggle"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + S", hl.dsp.window.pin())
hl.bind("SHIFT + " .. mainMod .. " + S", hl.dsp.exec_cmd('hyprctl --batch "dispatch togglefloating active; dispatch resizeactive exact 30% 30%; dispatch moveactive exact 69% 5%; dispatch pin active"'))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("~/.config/hypr/show_desktop.sh"))
hl.bind("SHIFT + " .. mainMod .. " + B", hl.dsp.exec_cmd("hyprctl hyprsunset temperature 4100"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("hyprctl hyprsunset temperature 6000"))
hl.bind("SHIFT + " .. mainMod .. " + SPACE", function()
    hl.dsp.window.float({ action = "toggle" })
    hl.exec_cmd("hyprctl dispatch resizeactive exact 50% 50%")
end)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("zen-browser"))

-- Screenshot bindings
hl.bind("CONTROL + SHIFT + " .. mainMod .. " + 4", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind("ALT + SHIFT + " .. mainMod .. " + 4", hl.dsp.exec_cmd("hyprshot -m region"))

-- Window Swapping
hl.bind(mainMod .. " + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.window.swap({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.window.swap({ direction = "right" }))

-- Workspace Navigation
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = "name:" .. tab_one }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = "name:" .. tab_two }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = "name:" .. tab_three }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = "name:" .. tab_four }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = "name:" .. tab_five }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = "name:" .. tab_six }))

-- Move Window to Workspace
hl.bind("SHIFT + " .. mainMod .. " + 1", hl.dsp.window.move({ workspace = "name:" .. tab_one }))
hl.bind("SHIFT + " .. mainMod .. " + 2", hl.dsp.window.move({ workspace = "name:" .. tab_two }))
hl.bind("SHIFT + " .. mainMod .. " + 3", hl.dsp.window.move({ workspace = "name:" .. tab_three }))
hl.bind("SHIFT + " .. mainMod .. " + 4", hl.dsp.window.move({ workspace = "name:" .. tab_four }))
hl.bind("SHIFT + " .. mainMod .. " + 5", hl.dsp.window.move({ workspace = "name:" .. tab_five }))
hl.bind("SHIFT + " .. mainMod .. " + 6", hl.dsp.window.move({ workspace = "name:" .. tab_six }))

-- Move Window to Workspace (no follow)
hl.bind("ALT + 1", hl.dsp.window.move({ workspace = "name:" .. tab_one, follow = false }))
hl.bind("ALT + 2", hl.dsp.window.move({ workspace = "name:" .. tab_two, follow = false }))
hl.bind("ALT + 3", hl.dsp.window.move({ workspace = "name:" .. tab_three, follow = false }))
hl.bind("ALT + 4", hl.dsp.window.move({ workspace = "name:" .. tab_four, follow = false }))
hl.bind("ALT + 5", hl.dsp.window.move({ workspace = "name:" .. tab_five, follow = false }))
hl.bind("ALT + 6", hl.dsp.window.move({ workspace = "name:" .. tab_six, follow = false }))

-- Mouse Bindings
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("mouse:275", hl.dsp.exec_cmd("~/.config/hypr/workspace_cycle.sh -"), { non_consuming = true })
hl.bind("mouse:276", hl.dsp.exec_cmd("~/.config/hypr/workspace_cycle.sh +"), { non_consuming = true })

-- Layout Management
hl.bind(mainMod .. " + M", hl.dsp.layout("orientationnext"))
hl.bind(mainMod .. " + N", hl.dsp.focus({ workspace = "empty" }))

-- Multimedia Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(ipc .. " brightness increase"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(ipc .. " brightness decrease"), { locked = true, repeating = true })

-- Media Controls
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Resize submap
hl.bind("ALT + R", hl.dsp.submap("resize"))

hl.define_submap("resize", "reset", function()
    hl.bind("right", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
    hl.bind("left", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Window rules
hl.window_rule({
    name  = "ghostty-to-workspace-1",
    match = { class = "^com.mitchellh.ghostty$" },
    workspace = "1",
    no_initial_focus = false,
})

hl.window_rule({
    name  = "zen-to-workspace-2",
    match = { class = "^zen$" },
    workspace = "2",
    no_initial_focus = true,
})

hl.window_rule({
    name  = "communication-apps",
    match = { class = "^(org.mozilla.Thunderbird|obsidian|org.telegram.desktop|discord|vesktop)$" },
    workspace = "3",
    no_initial_focus = true,
})

hl.window_rule({
    name  = "gaming-apps",
    match = { class = "^(blender|steam|LM Studio|heroic)$" },
    workspace = "4",
    no_initial_focus = true,
})

hl.window_rule({
    name  = "media-apps",
    match = { class = "^(org.gnome.Podcasts|com.obsproject.Studio)$" },
    workspace = "5",
    no_initial_focus = true,
})

hl.window_rule({
    name  = "librepods-float",
    match = { class = "librepods" },
    float = true,
    size  = "20% 20%",
})

hl.window_rule({
    name  = "love-float",
    match = { class = "love" },
    float = true,
})

-- Layer rules
hl.layer_rule({
    name  = "blur-layers",
    match = { namespace = "^(leftbar|rofi|waybar|nwg-dock)" },
    blur  = true,
})

hl.layer_rule({
    name  = "noctalia",
    match = { namespace = "^noctalia-background-.*$" },
    ignore_alpha = 0.5,
    blur         = true,
    blur_popups  = true,
})


---------------
----  MISC  ----
---------------

-- Source colors file (hyprlang format)
hl.exec_cmd("hyprctl source /home/mike/.config/hypr/noctalia/noctalia-colors.conf")
