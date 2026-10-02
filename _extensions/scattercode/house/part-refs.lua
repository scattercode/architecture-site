-- Cross-references to parts. Quarto numbers and resolves @sec- references
-- to chapters and sections, but parts have no label it can target. This
-- filter resolves @part-<dir> (the directory holding that part's chapters,
-- e.g. @part-qa-strategy) to "Part III", linked to the part's first chapter.
-- Part numbers are derived from the order of `- part:` entries in
-- _quarto.yml, so reordering the manifest renumbers every reference.
-- An unknown part is reported and rendered as "?@part-<dir>", matching
-- Quarto's own convention for unresolved cross-references.

local roman = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }

local parts = nil

local function load_parts()
  parts = {}
  local manifest = io.open("_quarto.yml", "r")
  if not manifest then return end
  local number, awaiting = 0, false
  for line in manifest:lines() do
    if line:match("^%s*%-%s*part:") then
      number = number + 1
      awaiting = true
    elseif awaiting then
      local path = line:match("^%s*%-%s*([%w%-_]+/[^%s]+%.q?md)%s*$")
      if path then
        awaiting = false
        local dir = path:match("^([^/]+)/")
        local id = nil
        local chapter = io.open(path, "r")
        if chapter then
          for text in chapter:lines() do
            if text:match("^# ") then
              id = text:match("{#([%w%-_]+)}")
              break
            end
          end
          chapter:close()
        end
        parts[dir] = { label = "Part " .. (roman[number] or tostring(number)), id = id }
      end
    end
  end
  manifest:close()
end

function Cite(el)
  if #el.citations ~= 1 then return nil end
  local key = el.citations[1].id:match("^part%-(.+)$")
  if not key then return nil end
  if not parts then load_parts() end
  local part = parts[key]
  if not part then
    io.stderr:write("WARNING: Unable to resolve part reference @part-" .. key .. "\n")
    return pandoc.Strong(pandoc.Str("?@part-" .. key))
  end
  local text = pandoc.Str(part.label)
  if part.id then
    return pandoc.Link(text, "#" .. part.id)
  end
  return text
end
