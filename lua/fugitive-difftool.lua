-- see https://github.com/tpope/vim-fugitive/issues/132#issuecomment-649516204
-- example of use
-- :Git! difftool --name-status master...
--
-- ! dont jump on the first entry in the quickfix list
-- by default difftool outputs one entry per hunk, --name-status one per file
-- which is better in this use case
--
-- another idea: same thing to browse the history of a file
local M = {}

-- Check if a ref:path/to/file exists from git POV
--- @param ref_colon_path string
--- @return boolean
local git_exists = function(ref_colon_path)
  local job_id = vim.fn.jobstart({ 'git', 'cat-file', '-e', ref_colon_path })

  local result = vim.fn.jobwait({ job_id })
  return #result == 1 and result[1] == 0
end

local new_scratch_buffer = function()
  vim.cmd('enew')
  vim.cmd('setlocal buftype=nofile bufhidden=hide noswapfile')
end

-- Open a file in the form of ref:/path/to_file. If the file doesn't exist in git
-- a new scratch buffer is created.
--- @param ref_and_file string
local open_git_ref_and_file = function(ref_and_file)
  if git_exists(ref_and_file) then
    vim.cmd('Ge ' .. ref_and_file)
  else
    new_scratch_buffer()
  end
end

--- @param offset number
local qf_advance_idx = function(offset)
  local idx = vim.fn.getqflist({ idx = 0 }).idx
  vim.fn.setqflist({}, 'a', { idx = idx + offset })
end

---@param idx number
local qf_set_idx = function(idx)
  vim.fn.setqflist({}, 'a', { idx = idx })
end

-- Remove all the windows keeping one window an eventually the quickfix window.
-- If the quickfix window had the focus. It is moved to another window.
local keep_one_window_and_eventually_qf_win = function()
  local not_qf = {}

  for _, window in ipairs(vim.fn.getwininfo()) do
    if window.quickfix == 0
    then
      table.insert(not_qf, window)
    end
  end

  local without_current = vim.tbl_filter(function(window)
    return window.winnr ~= vim.fn.winnr()
  end, not_qf)

  -- We want to keep one window. If these two tables have the same size:
  if #without_current == #not_qf then
    -- That mean the focus is on the quickfix window. We remove an arbitrary
    -- window for this list and make it the currently focused window.
    local new_focused = table.remove(without_current, 1)
    vim.api.nvim_set_current_win(new_focused.winid)
  end

  for _, window in ipairs(without_current) do
    vim.cmd('bdelete ' .. window.bufnr)
  end
end

M.git_cc = function()
  keep_one_window_and_eventually_qf_win()

  -- get the current entry in the quickfix list
  local idx = vim.fn.getqflist({ idx = 0 }).idx
  local qf_current = vim.fn.getqflist()[idx]
  if qf_current == nil then
    vim.notify('No quickfix list', vim.log.levels.WARN)
    return
  end

  -- open it
  open_git_ref_and_file(qf_current.module)
  vim.cmd('diffthis')

  -- get the others
  local qf_context = vim.fn.getqflist({ context = 0 }).context.items[idx].diff

  -- If qf_context contains more than one element, this probably doesn't work. I
  -- need to find an example when it is the case.
  for i = 1, #qf_context do
    local where
    if i == 1 then
      where = 'leftabove'
    else
      where = 'rightbelow'
    end
    vim.cmd(where .. ' vnew')

    -- `qf_context[i].module` is sometimes not usable with `cat-file`. For
    -- example when calling `Git! difftool master...`, we will get `git
    -- cat-file master...:path/to/file` which fails.
    --
    -- `filename` contains a fugitive URI, in order to check that file exists,
    -- we call `FugitiveParse` which returns something like hash:path/to/file
    local ref_and_file = vim.fn.FugitiveParse(qf_context[i].filename)[1]
    open_git_ref_and_file(ref_and_file)
    vim.cmd('diffthis')

    -- go to the previous window
    vim.cmd('wincmd p')
  end
end

M.git_cn = function()
  qf_advance_idx(1)

  M.git_cc()
end

M.git_cp = function()
  qf_advance_idx(-1)

  M.git_cc()
end

M.git_cfir = function()
  qf_set_idx(1)

  M.git_cc()
end

M.git_cla = function()
  local size = vim.fn.getqflist({ size = 0 }).size
  qf_set_idx(size)

  M.git_cc()
end

return M
