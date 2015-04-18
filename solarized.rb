require './color.rb'
require './utils.rb'

solarized_colors = ["#002b36", "#073642", "#586e75", "#657b83",
                    "#839496", "#93a1a1", "#eee8d5", "#fdf6e3",
                    "#b58900", "#cb4b16", "#dc322f", "#d33682",
                    "#6c71c4", "#268bd2", "#2aa198", "#859900"]

solarized_inverted = { "#fdf6e3" => "#002b36",
                       "#eee8d5" => "#073642",
                       "#93a1a1" => "#586e75",
                       "#839496" => "#657b83",

                       "#002b36" => "#fdf6e3",
                       "#073642" => "#eee8d5",
                       "#586e75" => "#93a1a1",
                       "#657b83" => "#839496"
                     }

ARGF.argv.each do |file|
  if not File.exist?(file) or file.eql?("--invert")
    next
  end

  text = File.read(file)
  colors = text.scan(/#(?:\h{3}){1,2}\b|\brgba?\([^()]+\)|\bhsla?\([^()]+\)/i).uniq
  scheme = make_color_scheme(colors, solarized_colors)

  if ARGF.argv.include?("--invert")
    scheme = replace_colors(scheme, solarized_inverted)
  end

  # replace long strings before short ones
  scheme.sort_by!{ |c| -c[:from].length }

  scheme.each do |s|
    text.gsub!(s[:from], s[:to])
  end

  File.write(file, text)
end

