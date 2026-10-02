-- Unwrap links whose targets will not exist in the output, keeping the link
-- text as plain prose. Web links (http/https) are always left alone.
--
-- In PDF and Word output every relative link to another Markdown source file
-- is unwrapped: a single document cannot link to a page that is not in it.
-- (In a website, Quarto rewrites those links to the rendered pages, so they
-- are kept.)
--
-- In every format, links matching `house-unwrap-links` in the document or
-- project metadata are unwrapped too. The default list covers READMEs, the
-- whitepaper backlog and anything outside the repository:
--
--   house-unwrap-links:
--     - "README%.md$"
--     - "whitepapers%.md"
--     - "^%.%./%.%./"
--
-- Patterns are Lua patterns (so a literal dot is "%.").

local patterns = { "README%.md$", "whitepapers%.md", "^%.%./%.%./" }
local single_document = not quarto.doc.is_format("html")

local function read_patterns(meta)
  local list = meta["house-unwrap-links"]
  if list then
    patterns = {}
    for _, item in ipairs(list) do
      table.insert(patterns, pandoc.utils.stringify(item))
    end
  end
end

local function unwrap(el)
  local t = el.target
  if t:match("^https?://") or t:match("^mailto:") or t:match("^#") then
    return el
  end
  if single_document and t:match("%.q?md") then
    return el.content
  end
  for _, pat in ipairs(patterns) do
    if t:match(pat) then return el.content end
  end
  return el
end

return {
  { Meta = read_patterns },
  { Link = unwrap },
}
