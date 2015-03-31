require './color.rb'

def make_color_scheme(from_colors, to_colors)
  from_colors = from_colors.map{ |c| { :src => c, :clr => Color.new(c) } }
  to_colors = to_colors.map{ |c| Color.new(c) }
  scheme = from_colors.map { |fc|
    { :from => fc[:src],
      :to   => to_colors.min_by{ |tc| fc[:clr].diff(tc) }.to_s
    }
  }
  return scheme
end

solarized_colors = ["#002b36", "#073642", "#586e75", "#657b83",
                    "#839496", "#93a1a1", "#eee8d5", "#fdf6e3",
                    "#b58900", "#cb4b16", "#dc322f", "#d33682",
                    "#6c71c4", "#268bd2", "#2aa198", "#859900"]

ARGF.argv.each do |file|
  if not File.exist?(file)
    next
  end

  text = File.read(file)
  colors = text.scan(/#(?:\h{3}){1,2}\b|\brgba?\([^()]+\)|\bhsla?\([^()]+\)/).uniq
  scheme = make_color_scheme(colors, solarized_colors)

  # replace long strings before short ones
  scheme.sort_by!{ |c| -c[:from].length }

  scheme.each do |s|
    text.gsub!(s[:from], s[:to])
  end

  File.write(file, text)
end

