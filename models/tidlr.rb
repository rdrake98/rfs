# tidlr.rb

require 'tiddler'

class Tidlr < Tiddler
  @@fixes = {
    "94": "Δ",
    "8C": "ʌ",
    "83": "ʃ",
    "92": "→",
    "91": "↑",
    "8A": "ʊ",

    B0: "°",
    BA: "º",
    A3: "£",
    F1: "ñ",
    AC: "€",
    E9: "é",
    AE: "®",
    A5: "¥",
    E7: "ç",
    B9: "¹",
    ED: "í",
    AB: "«",
    BB: "»",
    EA: "ê",
    BD: "½",
    E4: "ä",
    A9: "©",
    E8: "è",
    F6: "ö",
    FC: "ü",
    B7: "·",
    F8: "ø",
    E1: "á",
    B1: "α",
    C8: "ˈ",
    E6: "æ",
    EF: "ï",
    EE: "î",
    CF: "●",
    E0: "à",
    C9: "É",
    CC: "ˌ",
    D0: "ː",
    EB: "ë",
    F5: "õ",
    D3: "Ó",
    D7: "×",
    C0: "Ⓚ",
    F3: "ó",
    E2: "â",
    B2: "²",
    BC: "ʼ",
    FA: "ú",
    F4: "ô",
    F2: "ò",
    A7: "§",
    C5: "Å",
    C7: "Ç",
    BF: "ʿ",
    DC: "˜",
    A2: "¢",
    B8: "θ",
    C2: "ς",
    B3: "γ",
    B5: "ε",
    C6: "φ",
    C1: "ρ",
    E3: "ã",
    DF: "ß",
    E5: "å",

    # first found in tsnip in header or after comma
    A0: "",
    # first found before word
    AD: "",
    # first found after word
    FF: "",
    # can't solve in Guy Cross
    FD: "",
    # give up on Armenian and Japanese
    "80": "",
    "82": "",
    "97": "",
    # and some Greek
    C4: "",
  }

  def self.repair(line, lazy=false)
    line =~ /<\/div>/ # can be any regex
    line
  rescue
    line.scrub do |c|
      sym = c.inspect[3..4].to_sym
      replacement = @@fixes[sym] || (lazy ? "" : nil)
      # binding.pry if $dd && (!replacement || replacement == "")
      replacement || "??" # no nil now
    end
  end

  def self.div_text(file, line)
    div_text = ""
    begin
      div_text << line
      lazy = div_text.index("<div title=\"FunnyOldKeys\"") == 0
      line = Tidlr.repair(file.gets, lazy)
    end until line =~ /<\/div>/
    div_text << line
  end

  def splitdown
    (splitname || @title).downcase
  end

  def time_from(s)
    if s.size == 25
      Time.parse(s)
    else
      Time.new(s[0..3],s[4..5],s[6..7],s[8..9],s[10..11])
    end
  end
end
