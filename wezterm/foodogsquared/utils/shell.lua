local M = {}

function M.execute_nu(exe)
  return os.execute(M.nu(exe))
end

function M.nu(cmd)
  return string.format("nu -c %q", cmd)
end

function M.capture(cmd)
  local f = assert(io.popen(cmd, "r"))
  local s = assert(f:read("*a"))

  f:close()
  return s
end

function M.capture_nu(cmd)
  return M.capture(M.nu(cmd))
end

return M
