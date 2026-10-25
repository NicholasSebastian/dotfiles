hl.monitor({ output = "DP-3", mode = "2560x1440@180", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@75", position = "2560x-240", scale = 1, transform = 3 })

hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", default = true })
