-- Starts the session background programs once, skipping the ones already running.

local spawn = require('awful.spawn')

local autostart = {}

--- Spawns a program only when no matching process is already running.
-- @param cmd_name string Process name for pgrep, or the full command line if use_full_cmd is set.
-- @param cmd_full string|table Command passed to awful.spawn.
-- @param use_full_cmd boolean Match the whole command line instead of the executable name.
local function spawn_once(cmd_name, cmd_full, use_full_cmd)
	local pgrep_args = { 'pgrep', '-u', os.getenv('USER') }
	if use_full_cmd then
		table.insert(pgrep_args, '-f')
	else
		table.insert(pgrep_args, '-x')
	end
	table.insert(pgrep_args, cmd_name)

	spawn.with_line_callback(pgrep_args, {
		exit = function(_, code)
			if code ~= 0 then
				spawn(cmd_full)
			end
		end,
	})
end

--- Starts every background program of the session.
function autostart.init()
	spawn_once('xsettingsd', { 'xsettingsd' })
	spawn({ 'wpctl', 'set-volume', '@DEFAULT_AUDIO_SOURCE@', '150%' })
	spawn({ 'ksuperkey', '-e', 'Super_L=Alt_L|F2' })
	spawn({ 'ksuperkey', '-e', 'Super_R=Alt_L|F2' })
	spawn_once('picom', { 'picom' })
	spawn_once('polkit-gnome-au', { '/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1' })
	spawn_once('xss-lock', { 'xss-lock', '-q', '-l', os.getenv('HOME') .. '/.config/awesome/lock.sh' })
	spawn({ 'xset', 's', 'off' })
	spawn({ 'xset', '-dpms' })
	spawn_once('thunderbird', { 'thunderbird' })
	spawn_once('mcontrolcenter', { 'mcontrolcenter' })
	spawn_once('Discord', { 'equicord', '--disable-gpu' })
	-- Wayland version
	-- spawn_once("Discord", {"env", "OZONE_PLATFORM=wayland", "XDG_SESSION_TYPE=wayland", "DISCORD_DISABLE_GPU_SANDBOX=1", "DISCORD_ENABLE_WAYLAND_PIPEWIRE=1", "ELECTRON_OZONE_PLATFORM_HINT=auto", "equicord", "--no-sandbox", "--enable-zero-copy", "--ignore-gpu-blocklist", "--enable-gpu-rasterization", "--enable-native-gpu-memory-buffers", "--enable-features=WebRTCPipeWireCapturer,UseOzonePlatform,VaapiVideoDecoder", "--disable-features=UseChromeOSDirectVideoDecoder", "--ozone-platform=wayland", "--use-gl=desktop"}, true)
	spawn_once('fcitx5', { 'fcitx5' })
	spawn.once({ 'bluetoothctl', 'power', 'off' })
	spawn_once('xmousepastebloc', { 'xmousepasteblock' })
	spawn({ 'wmname', 'march7th' })
	spawn_once('zalo', { 'zalo', '--disable-gpu' })
end

return autostart
