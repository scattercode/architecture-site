-- Strip manual heading numbers ("1.", "2.3", "10.") from headings so
-- Quarto's own numbering applies cleanly. Source files keep their numbers
-- for wiki replication, where nothing numbers them automatically.
function Header(el)
  local first = el.content[1]
  if first and first.t == "Str" and first.text:match("^%d+[%.%d]*%.?$") then
    table.remove(el.content, 1)
    if el.content[1] and el.content[1].t == "Space" then
      table.remove(el.content, 1)
    end
  end
  return el
end
