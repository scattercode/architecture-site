-- Resolve cross-references to headings on *other* pages of a website.
--
-- Quarto resolves @sec-/@fig-/@tbl- references within one document (and
-- across a whole book), but a website page cannot see a heading that lives
-- on a sibling page, so the reference renders as "?@sec-id". When the pages
-- of a directory are also combined into one document (architecture/ and
-- complete.qmd, say), the same source must work both ways.
--
-- In HTML output, this filter looks at every reference whose target is not
-- defined on the current page, scans the Markdown files beside the document
-- for a heading carrying that ID, and emits a link to that page with the
-- heading's text (manual numbers stripped) as the link text. References
-- defined on the page are left for Quarto to number as usual, and
-- references that cannot be found anywhere are left for Quarto to report.

if not quarto.doc.is_format("html") then
  return {}
end

local function heading_text(line)
  local text = line:gsub("^#+%s*", ""):gsub("%s*{[^}]*}%s*$", "")
  text = text:gsub("^%d+[%.%d]*%.?%s+", "")
  return text
end

-- Headings with IDs in the sibling source files of the current document.
local function build_index()
  local index = {}
  local dir = pandoc.path.directory(quarto.doc.input_file)
  local ok, entries = pcall(pandoc.system.list_directory, dir)
  if not ok then return index end
  for _, name in ipairs(entries) do
    if name:match("%.q?md$") and not name:match("^_") then
      local f = io.open(pandoc.path.join({ dir, name }), "r")
      if f then
        local in_fence = false
        for line in f:lines() do
          if line:match("^%s*```") then
            in_fence = not in_fence
          elseif not in_fence and line:match("^#+%s") then
            local id = line:match("{#([%w%-_]+)[%s}]")
            if id and (id:match("^sec%-") or id:match("^fig%-") or id:match("^tbl%-")) then
              index[id] = { page = name:gsub("%.q?md$", ".html"), text = heading_text(line) }
            end
          end
        end
        f:close()
      end
    end
  end
  return index
end

-- Every identifier defined in this document (headers, divs, figures, tables).
local function local_ids(doc)
  local ids = {}
  doc:walk({
    Header = function(el) if el.identifier ~= "" then ids[el.identifier] = true end end,
    Div = function(el) if el.identifier ~= "" then ids[el.identifier] = true end end,
    Image = function(el) if el.identifier ~= "" then ids[el.identifier] = true end end,
    Table = function(el) if el.identifier ~= "" then ids[el.identifier] = true end end,
    CodeBlock = function(el)
      -- Executable cells declare their label as a comment option.
      local label = el.text:match("#|%s*label:%s*([%w%-_]+)")
      if label then ids[label] = true end
    end,
  })
  return ids
end

function Pandoc(doc)
  local ids = local_ids(doc)
  local index = nil
  return doc:walk({
    Cite = function(el)
      if #el.citations ~= 1 then return nil end
      local id = el.citations[1].id
      if not id:match("^sec%-") and not id:match("^fig%-") and not id:match("^tbl%-") then
        return nil
      end
      if ids[id] then return nil end
      if not index then index = build_index() end
      local target = index[id]
      if not target then return nil end
      return pandoc.Link(pandoc.Str(target.text), target.page .. "#" .. id)
    end,
  })
end
