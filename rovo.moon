string.starts_with = (str) => self\sub(1, #str) == str
string.strip = (str) => self\match "^#{str}*(.*%S)"
string.split = (delim) =>
  accu, pos = {}, 1
  if ""\find delim, 1
    self\gsub ".", ((x) -> table.insert accu, x)
  else
    while true
      first, last = self\find(delim, pos)
      if first then
        table.insert(accu, self\sub(pos, first - 1))
        pos = last + 1
      else
        table.insert(accu, self\sub(pos))
        break
  return accu

io.read_all = (fname) ->
  if f = io.open fname, "r"
    with f\read "*a"
      f\close!

term_color = {
  keys: {
    black:  30,
    red:    31,
    green:  32,
    yellow: 33,
    blue:   34,
    magenta:35,
    cyan:   36,
    white:  37,
    reset:  0,
  }
}

term_color.parse = (str) ->
  return "%{reset}#{str}%{reset}"\gsub "(%%{(.-)})", ((str) ->
    accu = {}
    for word in str\gmatch "%w+"
      table.insert accu, "%{\x1B[#{( ->
        if num = term_color.keys[word]
          return num
        else assert number, "Unknown key '#{word}'"
      )!}m%}"
    return table.concat(accu)
  )

prompt = {
  cwd: ( ->
    accu = { }
    cwd = os.getenv "PWD"
    if cwd\starts_with os.getenv "HOME"
      return term_color.parse "%{green}" .. cwd\gsub(os.getenv("HOME"), "~"
        )\gsub("/", "%%{reset}/%%{green}")
    else return term_color.parse os.getenv("PWD")\gsub "/", "%%{reset}/%%{red}"
  ),
  bat: ( ->
    capacity = tonumber(io.read_all("/sys/class/power_supply/BAT1/capacity"))
    color = "green"
    switch io.read_all("/sys/class/power_supply/BAT1/status")
      when "Charging\n" nil
      when "Discharging\n"
        color = "yellow" if capacity < 60
        color = "red" if capacity < 30
      else return nil
    return term_color.parse "%{#{color}}#{capacity}"
  ),
}

prompt.left = { prompt.cwd, ( -> return ">" ) }
prompt.right = { (-> return "<" ), prompt.bat }

print "
PROMPT=\'#{( ->
  accu = {}
  for _, part in pairs prompt.left
      if p = part!
        table.insert accu, p.." "
  return table.concat accu
)! }\'
RPROMPT=\'#{( ->
  accu = {}
  for _, part in pairs prompt.right
      if p = part!
        table.insert accu, " " .. p
  return table.concat accu
)!}\'"
