-- Understory — Hyprland 0.56+

local terminal = "kitty"
local fileManager = "dolphin"
local menu = "vicinae toggle"
local mod = "SUPER"

-- The built-in Framework display. Unmatched external displays use Hyprland defaults.
hl.monitor({ output = "eDP-1", mode = "2880x1920@120", position = "0x0", scale = "1.6" })

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-- Make KDE/Qt applications use kdeglobals, including the Understory scheme.
hl.env("QT_QPA_PLATFORMTHEME", "kde")

hl.on("hyprland.start", function()
    local commands = {
        "hyprpaper",
        "waybar",
        "mako",
        "hypridle",
        "nm-applet --indicator",
        "vicinae server",
        "swayosd-server",
        "clipse -listen",
        "systemctl --user start hyprpolkitagent.service",
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
    }
    for _, command in ipairs(commands) do hl.exec_cmd(command) end
end)

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(66845aff)", "rgba(8ead73ff)" }, angle = 45 },
            inactive_border = "rgba(2b3127ff)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 0.96,
        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
            color = 0xaa11130f,
        },
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            vibrancy = 0.1,
        },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        focus_on_activate = true,
        background_color = 0xff181b16,
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            -- Physical clicks use touchpad button areas (bottom-right is right-click).
            clickfinger_behavior = false,
            disable_while_typing = true,
        },
    },
})

hl.curve("understoryEase", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("understoryOut", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "understoryEase" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "understoryOut", style = "popin 80%" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "understoryEase", style = "slide" })

hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + M", hl.dsp.exit())
hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + V", hl.dsp.exec_cmd("kitty --class clipse --title 'Understory Clipboard' clipse"))
hl.bind(mod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("makoctl restore"))

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
    hl.bind(mod .. " + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
end

for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

local screenshotSave = [[sh -c 'geometry=$(slurp) || exit 0; file="$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"; grim -g "$geometry" "$file" && wl-copy < "$file" && notify-send -i "$file" "Screenshot saved" "Saved to Pictures/Screenshots and copied"']]
local screenshotClipboard = [[sh -c 'geometry=$(slurp) || exit 0; grim -g "$geometry" - | wl-copy --type image/png && notify-send "Screenshot copied" "Paste it anywhere with Ctrl+V"']]
hl.bind("Print", hl.dsp.exec_cmd(screenshotSave))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd(screenshotClipboard))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --device amdgpu_bl1 --brightness raise"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --device amdgpu_bl1 --brightness lower"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --max-volume 100 --output-volume raise"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl prev"), { locked = true })
hl.bind("Caps_Lock", hl.dsp.exec_cmd("swayosd-client --caps-lock"), { locked = true, release = true, non_consuming = true })

hl.window_rule({ match = { class = "org.pulseaudio.pavucontrol" }, float = true })
hl.window_rule({ match = { class = "nm-connection-editor" }, float = true })
hl.window_rule({ match = { class = "clipse" }, float = true, size = { 720, 680 }, center = true })
