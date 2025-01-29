local config = {}

config.keys = {"a", "s", "j", "k"}
config.columns = {200, 250, 300, 350}
config.hitSound = "/assets/sounds/hit-sound.mp3"
config.missSound = "/assets/sounds/miss-sound.wav"
config.noteSpeed = 300

config.hitWindows = {
    sick = 0.04,
    good = 0.08,
    ok = 0.15
}

config.hitSize = 50
config.hitZoneY = 350

return config
