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

  def Wiki.name_patch_analysis
    f1 = fat
    np = f1["NamePatches"]
    lines = np.content.lines.map(&:chomp).reject{|s|s==""}
    puts lines.size
    wiki_links = lines.select{|s|WikiText.isWikiLink(s)}
    tids = f1.tiddlers - [np]
    puts tids.size
    tids.reject! do |t|
      t.tiddler_links.any? { |s| !f1.referent(s) }
    end
    puts tids.size

    dwiki_links = wiki_links.select { |s| !f1.referent(s) }
    puts "", dwiki_links.size
    dmatches = dwiki_links.map do |wl|
      ts = tids.select do |t|
        t.tiddler_links.any? do |s|
          s == wl
        end
      end
      if ts.size > 0
        puts wl
        puts ts.size
        ts.map{|t| [wl,t.title]}
      else
        nil
      end
    end.compact
    puts dmatches.size

    puts "", wiki_links.size
    matches = wiki_links.map do |wl|
      ts = tids.select do |t|
        t.tiddler_links.any? do |s|
          !f1.referent(s) && s=~/(#{wl}\w|\w#{wl})/
        end
      end
      if ts.size > 0
        puts wl
        puts ts.size
        ts.map{|t| [wl,t.title]}
      else
        nil
      end
    end.compact
    puts matches.size
    [f1, wiki_links, matches, dmatches]
  end
end
