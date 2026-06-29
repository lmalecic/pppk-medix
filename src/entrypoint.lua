local w, h, err = term:get_size()

if not w or not h then
  io.stderr:write('mate requires an interactive terminal.\n')
  io.stderr:write('Run it with: docker compose run --rm app\n')
  if err then
    io.stderr:write('term:get_size failed: ' .. tostring(err) .. '\n')
  end
  os.exit(1)
end

package.path = 'src/?.lua;src/?/init.lua;' .. package.path

dofile('src/main.lua')
