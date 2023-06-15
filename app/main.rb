FPS = 60
HIGH_SCORE_FILE = "high-score.txt"

# Utils
# Pick a random number between from and to, inclusive
def utils_rand_from_range(from, to)
  rand((to - from) + 1) + from
end

# Eggs
def eggs_initialize(args)
  args.state.eggs ||= [egg_spawn(args), egg_spawn(args), egg_spawn(args)]
  #args.state.eggs.each { |egg| egg_animate(egg) }
end

def egg_spawn(args)
  args.state.egg_size ||= 32
  {
    x: 0,
    y: args.grid.h,
    w: args.state.egg_size,
    h: args.state.egg_size,
    path: 'sprites/egg/egg-0.png',
    vx: utils_rand_from_range(3, 8),
    vy: -utils_rand_from_range(5, 10),
    gravity: utils_rand_from_range(0.15, 0.25),
    elasticity: 0.8,
    captured: false
  }
end

def egg_animate(egg)
  index = 0.frame_index(count: 1, hold_for: 3, repeat: true)
  egg.path = "sprites/egg/egg-#{index}.png"
end

def eggs_move(args)
  args.state.eggs.each do |egg|
    # Update position based on velocity
    egg[:x] += egg[:vx]
    egg[:y] += egg[:vy]

    # apply gravity to vertical velocity
    egg[:vy] -= egg[:gravity];

    if egg[:x] <= 0
      egg[:x] = 0
      egg[:vx] *= -egg[:elasticity]
      egg[:vy] *= [-1, 1].sample
    end

    if egg[:x] >= args.grid.w - args.state.egg_size
      egg[:x] = args.grid.w - args.state.egg_size
      egg[:vx] *= -egg[:elasticity]
      egg[:vy] *= [-1, 1].sample
    end

    if egg[:y] <= 0
      egg[:y] = 0 # Prevent it from going below the ground
      egg[:vy] *= -egg[:elasticity] # Reverse direction and apply elasticity
      egg[:vx] *= [-1, 1].sample
    end
  end
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
  if args.state.player.x + args.state.player.w > args.grid.w
    args.state.player.x = args.grid.w - args.state.player.w
  end
  if args.state.player.x < 0
    args.state.player.x = 0
  end
  if moved
    args.state.player.moved = moved
  end
end

def animate_player(args, speed)
  index = 0.frame_index(count: 1, hold_for: speed, repeat: true)
  args.state.player.path = "sprites/henrietta/henrietta-#{index}.png"
end

def update_sprites(args)
  args.state.eggs.reject! { |egg| egg.captured }
  if args.state.player.moved
    animate_player(args, 1)
    args.state.player.moved = false
  else
    animate_player(args, 3)
  end
  args.outputs.sprites << [args.state.player, args.state.eggs]
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

def detect_collision(args)
  args.state.eggs.each do |egg|
    if args.geometry.intersect_rect?(egg, args.state.player, 5)
      args.audio[:target] = {input: "sounds/chicken.wav", looping: false }
      egg.captured = true
      args.state.score += 1
      args.state.eggs << egg_spawn(args)
    end
  end
end

def game_scene(args)
  args.audio[:music][:gain] = 0.2
  initialize_player(args)
  eggs_initialize(args)
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
  eggs_move(args)
  if args.inputs.keyboard.key_down.escape
    args.state.scene = "title"
    $gtk.reset
    return
  end
  detect_collision(args)
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
