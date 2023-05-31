FPS = 60
HIGH_SCORE_FILE = "high-score.txt"

# Pick a random number between from and to, inclusive
def rand_from_range(from, to)
  rand((to - from) + 1) + from
end

def start_music(args)
  if args.state.tick_count == 1
    args.audio[:music] = { input: "sounds/music.ogg", looping: true, gain: 1.0 }
  end
end

def toggle_fullscreen(args)
  args.state.fullscreen = !args.state.fullscreen
  args.gtk.set_window_fullscreen(args.state.fullscreen)
end

def player_fired?(args)
  args.inputs.keyboard.key_down.z ||
    args.inputs.keyboard.key_down.j ||
    args.inputs.controller_one.key_down.a ||
    args.inputs.keyboard.key_down.space
end

def title_scene(args)
  args.outputs.sprites << {
    x: 0,
    y: 0,
    w: args.grid.w,
    h: args.grid.h,
    path: 'sprites/hea-title-scene.png'
  }
  if player_fired?(args)
    args.audio[:game_over] = { input: "sounds/game-over.wav", looping: false }
    args.state.scene = "game"
    return
  end
  args.outputs.labels << build_centered_label(args,"Hit fire to play", 10, 100)
end

def build_centered_label(args, text, size_enum, y)
  w, h = args.gtk.calcstringbox(text, size_enum)
  x = (args.grid.w / 2) - (w / 2)
  {
    x: x,
    y: y,
    size_enum: size_enum,
    text: "Hit fire to play",
    r: 10,
    g: 10,
    b: 100,
  }
end

def print_high_score
  labels = []
  labels << {
    x: 480,
    y: args.grid.h - 220,
    size_px: 16,
    text: "Highscore: #{args.state.high_score}",
    r: 10,
    g: 10,
    b: 100,
  }
  args.outputs.labels << labels
end

def game_scene(args)

end

def tick args
  args.state.fullscreen ||= false
  toggle_fullscreen(args) if args.inputs.keyboard.key_down.f
  args.state.high_score ||= args.gtk.read_file(HIGH_SCORE_FILE).to_i
  start_music(args)
  args.state.scene ||= "title"
  if !args.inputs.keyboard.has_focus && args.state.tick_count != 0
    args.outputs.background_color = [0, 0, 0]
    args.outputs.labels << { x: 640, y: 360, text: "Game Paused (click to resume).", alignment_enum: 1, r: 255, g: 255, b: 255 }
    args.audio[:music].gain = 0 unless args.state.tick_count < 1
  else
    args.audio[:music].gain = 1 unless args.state.tick_count < 1
    send("#{args.state.scene}_scene", args)
  end
end
