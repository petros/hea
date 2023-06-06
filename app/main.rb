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

def initialize_player(args)
  size = 64
  args.state.player ||= {
    x: 120,
    y: 0,
    w: size,
    h: size,
    speed: 12,
    facing: :left,
  }
end

def draw_background(args)
  args.outputs.sprites << {
    x: 0,
    y: 0,
    w: args.grid.w,
    h: args.grid.h,
    path: 'sprites/hea-game-scene-background.png'
  }
end

def move_player(args)
  moved = false
  if args.inputs.left
    args.state.player.x -= args.state.player.speed
    moved = true
    if args.state.player.facing != :left
      args.state.player.flip_horizontally = false
      args.state.player.facing = :left
    end
  elsif args.inputs.right
    args.state.player.x += args.state.player.speed
    moved = true
    if args.state.player.facing != :right
      args.state.player.flip_horizontally = true
      args.state.player.facing = :right
    end
  end
  # if args.inputs.up
  #   args.state.player.y += args.state.player.speed
  #   moved = true
  # elsif args.inputs.down
  #   args.state.player.y -= args.state.player.speed
  #   moved = true
  # end
  if args.state.player.x + args.state.player.w > args.grid.w
    args.state.player.x = args.grid.w - args.state.player.w
  end
  if args.state.player.x < 0
    args.state.player.x = 0
  end
  # if args.state.player.y + args.state.player.h > args.grid.h
  #   args.state.player.y = args.grid.h - args.state.player.h
  # end
  # if args.state.player.y < 0
  #   args.state.player.y = 0
  # end
  if moved
    args.state.player.moved = moved
  end
end

def animate_player(args, speed)
  index = 0.frame_index(count: 1, hold_for: speed, repeat: true)
  args.state.player.path = "sprites/henrietta/henrietta-#{index}.png"
end

def update_sprites(args)
  if args.state.player.moved
    animate_player(args, 1)
    args.state.player.moved = false
  else
    animate_player(args, 3)
  end
  args.outputs.sprites << [args.state.player]
end

def update_labels(args)
  labels = []
  labels << {
    x: 40,
    y: args.grid.h - 40,
    text: "Score: #{args.state.score}",
    size_enum: 4,
  }
  labels << {
    x: args.grid.w - 40,
    y: args.grid.h - 40,
    text: "Lives: #{args.state.lives}",
    size_enum: 2,
    alignment_enum: 2,
  }
  args.outputs.labels << labels
end

def game_scene(args)
  initialize_player(args)
  args.state.score ||= 0
  args.state.lives ||= 3
  draw_background(args)
  if args.state.lives == 0
    args.audio[:music].paused = true
    args.audio[:game_over] = { input: "sounds/game-over.wav", looping: false }
    args.state.scene = "game_over"
    return
  end
  move_player(args)
  update_sprites(args)
  update_labels(args)
end

def game_over_scene(args)
  args.state.timer -= 1

  if !args.state.saved_high_score && args.state.score > args.state.high_score
    args.gtk.write_file(HIGH_SCORE_FILE, args.state.score.to_s)
    args.state.saved_high_score = true
  end

  labels = []
  labels << {
    x: 40,
    y: args.grid.h - 40,
    text: "Game Over!",
    size_enum: 10,
  }
  labels << {
    x: 40,
    y: args.grid.h - 90,
    text: "Score: #{args.state.score}",
    size_enum: 4,
  }
  labels << {
    x: 40,
    y: args.grid.h - 132,
    text: "Fire to restart",
    size_enum: 2,
  }
  if args.state.score > args.state.high_score
    labels << {
      x: 260,
      y: args.grid.h - 90,
      text: "New High Score!",
      size_enum: 3,
    }
  else
    labels << {
      x: 260,
      y: args.grid.h - 90,
      text: "Score to beat: #{args.state.high_score}",
      size_enum: 3,
    }
  end
  args.outputs.labels << labels
  if args.state.timer < -30 && player_fired?(args)
    $gtk.reset
  end
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

$gtk.reset
