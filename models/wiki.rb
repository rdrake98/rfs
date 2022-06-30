# wiki.rb

require 'splitter'

class Wiki < Splitter
  def advance_gen
    puts tiddlers.size
    open_tiddlers = self["DefaultTiddlers"].tiddlers_linked
    puts open_tiddlers.size
    marker = self["RejectBelowHere"]
    puts index = open_tiddlers.index(marker)
    open_tiddlers[index+1..-1].each { |t| delete(t.title) }
    puts tiddlers.size
    fat = Wiki.fat
    puts fat.tiddlers.size
    my_first = open_tiddlers[0]
    fat_first = fat[my_first.title]
    puts fat_first.references.map(&:title).join(" - ")
    puts my_first.title
    puts fat_first.titles_linked.join(" - ")
    write
    # `open #{new_name}`
  end

  def Wiki.name_patch_iterm
    f1 = fat
    np = f1["NamePatches"]
    lines = np.content.lines.map(&:chomp).reject{|s|s==""}
    puts lines.size
    iterm_lines = lines.select { |s| s[0].in? %w[e i j] }
    puts iterm_lines.size
    tids = f1.tiddlers - [f1["LinksLikeITerm"]]
    puts tids.size, ""

    iterm_lines.map do |il|
      cil = il[0].capitalize + il[1..-1]
      ts = tids.select { |t| t.tiddler_links.any? { |s| s == cil } }
      puts cil
      puts ts.size < 10 ?
        "- " + ts.map(&:to_link).join(" - ") :
        ts.size
      ts.map{|t| [il,t.title]}
    end
  end
end
