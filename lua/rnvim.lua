local M = {}

local function is_in_netrw()
    return vim.bo.filetype == "netrw"
end

-- Utility: Get the absolute path of the current Netrw directory
local function get_netrw_cwd()
    return vim.fn.expand("%:p:h")
end

local function prompt_rename(old_name)
    return vim.fn.input(string.format("rename %s > ", old_name))
end

-- Core Function: Rename the current buffer file
function M.rename_current_file()
    if is_in_netrw() then
        return
    end

    local old_path = vim.fn.expand("%:p")   -- Absolute path of the current buffer file
    local dir_path = vim.fn.expand("%:p:h") -- Directory of the current buffer

    if old_path == "" then
        vim.notify("No file to rename", vim.log.levels.ERROR)
        return
    end

    local new_name = prompt_rename(vim.fn.expand("%:t"))
    if not new_name or new_name == "" then
        return
    end

    local new_path = dir_path .. "/" .. new_name
    if new_path == old_path then
        vim.notify("", vim.log.levels.WARN)
        return
    end

    local success, err = os.rename(old_path, new_path)
    if success then
        vim.cmd(string.format("edit %s", new_path))
        vim.notify("")
    else
        vim.notify(string.format(" Failed to rename: %s", err), vim.log.levels.ERROR)
    end
end

function M.rename_in_netrw()
    if not is_in_netrw() then
        return
    end

    local cwd = get_netrw_cwd()
    local old_name = vim.fn.expand("<cfile>")
    if old_name == "../" or old_name == "./" then
        vim.notify("", vim.log.levels.ERROR)
        return
    end

    local old_path = cwd .. "/" .. old_name
    local new_name = prompt_rename(old_name)
    if not new_name or new_name == "" then
        return
    end

    local new_path = cwd .. "/" .. new_name
    if new_path == old_path then
        vim.notify("", vim.log.levels.WARN)
        return
    end

    if vim.loop.fs_stat(new_path) then
        vim.notify(" File or directory already exists!", vim.log.levels.ERROR)
        return
    end

    -- Save current directory and cursor position
    local cursor_col = vim.fn.col(".")
    local current_directory = cwd

    local success, err = os.rename(old_path, new_path)
    if success then
        vim.cmd(string.format("lcd %s", current_directory))
        vim.cmd("edit .")

        if current_directory ~= get_netrw_cwd() then
            vim.cmd(string.format("Explore %s", current_directory))
        end

        -- Restore the cursor to the renamed item
        local files = vim.fn.getline(1, "$")
        for i, line in ipairs(files) do
            if line:find(new_name, 1, true) then
                vim.fn.cursor(i, cursor_col)
                break
            end
        end

        vim.notify("")
    else
        vim.notify(string.format(" Failed to rename: %s", err), vim.log.levels.ERROR)
    end
end

function M.setup()
    --vim.keymap.set("n", "<leader>rf", M.rename_current_file)
    --vim.keymap.set("n", "<leader>rn", M.rename_in_netrw)
end

return M
