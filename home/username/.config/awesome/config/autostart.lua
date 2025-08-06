local spawn = require('awful.spawn')

local autostart = {}

local function spawn_once(cmd_name, cmd_full)
	spawn.easy_async({ 'pgrep', '-u', os.getenv('USER'), '-x', cmd_name }, function(_, _, _, exitcode)
		if exitcode ~= 0 then
			spawn(cmd_full)
		end
	end)
end

function autostart.init()
	local home = os.getenv('HOME')
	package.loaded['naughty.dbus'] = nil
	spawn_once('dunst', 'dunst')
	spawn_once('xsettingsd', 'xsettingsd')
	spawn({ 'pactl', 'set-source-volume', '@DEFAULT_SOURCE@', '150%' })
	spawn({ 'ksuperkey', '-e', 'Super_L=Alt_L|F2' })
	spawn({ 'ksuperkey', '-e', 'Super_R=Alt_L|F2' })
	spawn_once('picom', 'picom')
	spawn_once('lxqt-policykit-', 'lxqt-policykit-agent')
	spawn_once('xss-lock', { 'xss-lock', '-q', '-l', home .. '/.config/awesome/xss-lock-tsl.sh' })
	spawn({ 'xset', 's', 'off' })
	spawn({ 'xset', '-dpms' })
	spawn_once('thunderbird', 'thunderbird')
	spawn_once('mcontrolcenter', 'mcontrolcenter')
	spawn_once('legcord', 'legcord')
	-- Wayland version
	-- spawn_once("legcord", {"env", "OZONE_PLATFORM=wayland", "XDG_SESSION_TYPE=wayland", "DISCORD_DISABLE_GPU_SANDBOX=1", "DISCORD_ENABLE_WAYLAND_PIPEWIRE=1", "ELECTRON_OZONE_PLATFORM_HINT=auto", "legcord", "--no-sandbox", "--enable-zero-copy", "--ignore-gpu-blocklist", "--enable-gpu-rasterization", "--enable-native-gpu-memory-buffers", "--enable-features=WebRTCPipeWireCapturer,UseOzonePlatform,VaapiVideoDecoder", "--disable-features=UseChromeOSDirectVideoDecoder", "--ozone-platform=wayland", "--use-gl=desktop"})
	spawn_once('zalo', 'zalo')
	spawn_once('fcitx5', 'fcitx5')
	spawn.once({ 'bluetoothctl', 'power', 'off' })
end

return autostart
