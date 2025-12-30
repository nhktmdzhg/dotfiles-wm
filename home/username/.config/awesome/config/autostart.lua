local spawn = require('awful.spawn')

local autostart = {}

local function spawn_once(cmd_name, cmd_full, use_full_cmd)
	local pgrep_args = { 'pgrep', '-u', os.getenv('USER') }
	if use_full_cmd then
		table.insert(pgrep_args, '-f')
	else
		table.insert(pgrep_args, '-x')
	end
	table.insert(pgrep_args, cmd_name)

	spawn.easy_async(pgrep_args, function(_, _, _, exitcode)
		if exitcode ~= 0 then
			spawn(cmd_full)
		end
	end)
end

function autostart.init()
	spawn_once('xsettingsd', 'xsettingsd')
	spawn({ 'wpctl', 'set-volume', '@DEFAULT_AUDIO_SOURCE@', '150%' })
	spawn({ 'ksuperkey', '-e', 'Super_L=Alt_L|F2' })
	spawn({ 'ksuperkey', '-e', 'Super_R=Alt_L|F2' })
	spawn_once('fastcompmgr', { 'fastcompmgr', '-r', '0', '-o', '0', '-l', '0', '-t', '0', '-C' })
	spawn_once('lxpolkit', 'lxpolkit')
	spawn_once('xss-lock', { 'xss-lock', '-q', '-l', os.getenv('HOME') .. '/.config/awesome/lock.sh' })
	spawn({ 'xset', 's', 'off' })
	spawn({ 'xset', '-dpms' })
	spawn_once('thunderbird', 'thunderbird')
	spawn_once('mcontrolcenter', 'mcontrolcenter')
	spawn_once('legcord/app.asar', 'legcord', true)
	-- Wayland version
	-- spawn_once("legcord/app.asar", {"env", "OZONE_PLATFORM=wayland", "XDG_SESSION_TYPE=wayland", "DISCORD_DISABLE_GPU_SANDBOX=1", "DISCORD_ENABLE_WAYLAND_PIPEWIRE=1", "ELECTRON_OZONE_PLATFORM_HINT=auto", "legcord", "--no-sandbox", "--enable-zero-copy", "--ignore-gpu-blocklist", "--enable-gpu-rasterization", "--enable-native-gpu-memory-buffers", "--enable-features=WebRTCPipeWireCapturer,UseOzonePlatform,VaapiVideoDecoder", "--disable-features=UseChromeOSDirectVideoDecoder", "--ozone-platform=wayland", "--use-gl=desktop"}, true)
	spawn_once('zalo', { 'zalo', '--disable-gpu' })
	spawn_once('fcitx5', 'fcitx5')
	spawn.once({ 'bluetoothctl', 'power', 'off' })
	spawn_once('xmousepastebloc', 'xmousepasteblock')
end

return autostart
