FPS = 60
HIGH_SCORE_FILE = "high-score.txt"

# Utils
#######
def utils_toggle_fullscreen(args)
  args.state.fullscreen = !args.state.fullscreen
  args.gtk.set_window_fullscreen(args.state.fullscreen)
end

# Pick a random number between from and to, inclusive
def utils_rand_from_range(from, to)
  rand((to - from) + 1) + from
end

# Eggs
#
#
def eggs_initialize(args)
  args.state.eggs ||= [eggs_spawn(args), eggs_spawn(args), eggs_spawn(args)]
  #args.state.eggs.each { |egg| egg_animate(egg) }
end

def eggs_spawn(args)
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

def eggs_animate(egg)
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
      eggs_crack(args, egg)
      egg[:y] = 0 # Prevent it from going below the ground
      egg[:vy] *= -egg[:elasticity] # Reverse direction and apply elasticity
      egg[:vx] *= [-1, 1].sample
    end
  end
end

def eggs_crack(args, egg)
  args.audio[:eggs_crack] = { input: "sounds/eggs-crack.wav", looping: false }
  #egg[:path] = "sprites/egg/egg-cracked.png"
end

def eggs_clear(args)
  args.state.eggs.reject! { |egg| egg.captured }
end

# Music
#######
def music_start(args)
  if args.state.tick_count == 1
    args.audio[:music] = { input: "sounds/music.ogg", looping: true, gain: 1.0 }
  end
end

def music_lower_volume(args)
  args.audio[:music][:gain] = 0.2
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

def draw_background(args)
  args.outputs.sprites << {
    x: 0,
    y: 0,
    w: args.grid.w,
    h: args.grid.h,
    path: 'sprites/hea-background.png'
  }
end

# Player
########
def player_initialize(args)
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

def player_cluck(args)
  args.audio[:target] = {input: "sounds/chicken.wav", looping: false, gain: 2.0}
end

def player_move(args)
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

def player_animate(args, speed)
  index = 0.frame_index(count: 1, hold_for: speed, repeat: true)
  args.state.player.path = "sprites/henrietta/henrietta-#{index}.png"
end

def player_fired?(args)
  args.inputs.keyboard.key_down.z ||
    args.inputs.keyboard.key_down.j ||
    args.inputs.controller_one.key_down.a ||
    args.inputs.keyboard.key_down.space
end

def update_sprites(args)
  eggs_clear(args)
  lives_clear(args)
  if args.state.player.moved
    player_animate(args, 1)
    args.state.player.moved = false
  else
    player_animate(args, 3)
  end
  args.outputs.sprites << [args.state.player, args.state.eggs, args.state.lives]
end

def update_labels(args)
  labels = []
  labels << {
    x: 40,
    y: args.grid.h - 40,
    text: "Score: #{args.state.score}",
    size_enum: 4,
  }
  args.outputs.labels << labels
end

def detect_collision(args)
  args.state.eggs.each do |egg|
    if args.geometry.intersect_rect?(egg, args.state.player, 5)
      player_cluck(args)
      egg.captured = true
      args.state.score += 1
      args.state.eggs << eggs_spawn(args)
    end
  end
end

# Lives
#
#
def lives_initialize(args)
  args.state.lives ||= [lives_spawn(args, 1), lives_spawn(args, 2), lives_spawn(args, 3)]
end

# Spawn a ❤️ sprite at the top right corner of the screen
def lives_spawn(args, offset)
  size = 32
  margin = 10
  gap_count = 4
  lives_count = 3
  {
    x: (args.grid.w - ((size + margin) * lives_count) - margin * gap_count) + ((size + margin) * offset),
    y: args.grid.h - size - margin,
    w: size,
    h: size,
    path: 'sprites/heart.png',
    burned: false
  }
end

def lives_clear(args)
  args.state.lives.reject! { |live| live.burned }
end

def lives_burn(args)
  args.state.lives.last.burned = true
end

# Game scene
#
#
def game_scene(args)
  music_lower_volume(args)
  player_initialize(args)
  eggs_initialize(args)
  args.state.score ||= 0
  lives_initialize(args)
  draw_background(args)
  if args.state.lives.empty?
    args.audio[:music].paused = true
    args.audio[:game_over] = { input: "sounds/game-over.wav", looping: false }
    args.state.scene = "game_over"
    return
  end
  player_move(args)
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
  utils_toggle_fullscreen(args) if args.inputs.keyboard.key_down.f
  args.state.high_score ||= args.gtk.read_file(HIGH_SCORE_FILE).to_i
  music_start(args)
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
