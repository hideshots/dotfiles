obs = obslua

local NOTIFICATION_ICON = "camera-video"

settings_cache = {
    enabled = true,
    app_name = "OBS Studio",
    timeout_ms = 2500,

    notify_recording = true,
    notify_streaming = true,
    notify_replay = true,
    notify_virtualcam = true,
    notify_screenshot = false
}

local function shell_escape(s)
    if s == nil then
        return "''"
    end
    s = tostring(s):gsub("'", "'\\''")
    return "'" .. s .. "'"
end

local function notify(title, body)
    if not settings_cache.enabled then
        return
    end

    local cmd = {
        "notify-send",
        "-a", shell_escape(settings_cache.app_name),
        "-i", shell_escape(NOTIFICATION_ICON),
        "-t", tostring(settings_cache.timeout_ms),
        shell_escape(title),
        shell_escape(body)
    }

    os.execute(table.concat(cmd, " ") .. " >/dev/null 2>&1 &")
end

local function handle_event(event)
    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED and settings_cache.notify_recording then
        notify("Recording started", "OBS has started recording.")
    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED and settings_cache.notify_recording then
        notify("Recording stopped", "OBS has stopped recording.")
    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_PAUSED and settings_cache.notify_recording then
        notify("Recording paused", "OBS recording is paused.")
    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_UNPAUSED and settings_cache.notify_recording then
        notify("Recording resumed", "OBS recording has resumed.")

    elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STARTED and settings_cache.notify_streaming then
        notify("Streaming started", "OBS has started streaming.")
    elseif event == obs.OBS_FRONTEND_EVENT_STREAMING_STOPPED and settings_cache.notify_streaming then
        notify("Streaming stopped", "OBS has stopped streaming.")

    elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STARTED and settings_cache.notify_replay then
        notify("Replay buffer started", "Replay buffer is now active.")
    elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_STOPPED and settings_cache.notify_replay then
        notify("Replay buffer stopped", "Replay buffer has stopped.")
    elseif event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED and settings_cache.notify_replay then
        notify("Replay saved", "Replay buffer clip has been written to disk.")

    elseif event == obs.OBS_FRONTEND_EVENT_VIRTUALCAM_STARTED and settings_cache.notify_virtualcam then
        notify("Virtual camera started", "OBS virtual camera is active.")
    elseif event == obs.OBS_FRONTEND_EVENT_VIRTUALCAM_STOPPED and settings_cache.notify_virtualcam then
        notify("Virtual camera stopped", "OBS virtual camera has stopped.")

    elseif event == obs.OBS_FRONTEND_EVENT_SCREENSHOT_TAKEN and settings_cache.notify_screenshot then
        notify("Screenshot taken", "OBS has saved a screenshot.")
    end
end

function script_description()
    return "Sends Linux desktop notifications for common OBS events: recording, streaming, replay buffer, virtual camera, and screenshots. Uses a hardcoded camera-video icon."
end

function script_properties()
    local props = obs.obs_properties_create()

    obs.obs_properties_add_bool(props, "enabled", "Enable notifications")
    obs.obs_properties_add_text(props, "app_name", "Application name", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_int(props, "timeout_ms", "Timeout (ms)", 500, 10000, 100)

    obs.obs_properties_add_bool(props, "notify_recording", "Recording")
    obs.obs_properties_add_bool(props, "notify_streaming", "Streaming")
    obs.obs_properties_add_bool(props, "notify_replay", "Replay buffer")
    obs.obs_properties_add_bool(props, "notify_virtualcam", "Virtual camera")
    obs.obs_properties_add_bool(props, "notify_screenshot", "Screenshots")

    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_bool(settings, "enabled", true)
    obs.obs_data_set_default_string(settings, "app_name", "OBS Studio")
    obs.obs_data_set_default_int(settings, "timeout_ms", 2500)

    obs.obs_data_set_default_bool(settings, "notify_recording", true)
    obs.obs_data_set_default_bool(settings, "notify_streaming", true)
    obs.obs_data_set_default_bool(settings, "notify_replay", true)
    obs.obs_data_set_default_bool(settings, "notify_virtualcam", true)
    obs.obs_data_set_default_bool(settings, "notify_screenshot", false)
end

function script_update(settings)
    settings_cache.enabled = obs.obs_data_get_bool(settings, "enabled")
    settings_cache.app_name = obs.obs_data_get_string(settings, "app_name")
    settings_cache.timeout_ms = obs.obs_data_get_int(settings, "timeout_ms")

    settings_cache.notify_recording = obs.obs_data_get_bool(settings, "notify_recording")
    settings_cache.notify_streaming = obs.obs_data_get_bool(settings, "notify_streaming")
    settings_cache.notify_replay = obs.obs_data_get_bool(settings, "notify_replay")
    settings_cache.notify_virtualcam = obs.obs_data_get_bool(settings, "notify_virtualcam")
    settings_cache.notify_screenshot = obs.obs_data_get_bool(settings, "notify_screenshot")
end

function script_load(settings)
    obs.obs_frontend_add_event_callback(handle_event)
end
