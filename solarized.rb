require './color.rb'

colors = ["#002b36", "#073642", "#586e75", "#657b83",
          "#839496", "#93a1a1", "#eee8d5", "#fdf6e3",
          "#b58900", "#cb4b16", "#dc322f", "#d33682",
          "#6c71c4", "#268bd2", "#2aa198", "#859900"]

mycolors = ["#000000", "#1a356e", "#29447E", "#2b55ad",
            "#2c5115", "#3b5998", "#3b6e22", "#4e5665",
            "#505c77", "#69a74e", "#6d84b4", "#87898c",
            "#8a9ac5", "#98c37d", "#999999", "#aaaaaa",
            "#cccccc", "#eceff5", "#f3f4f5", "#ffffff"]

colors.map!{ |c| Color.new(c) }
mycolors.map!{ |c| Color.new(c) }

theme = mycolors.map { |c|
  { :from => c.to_s, :to => colors.min_by{ |clr| c.diff(clr) }.to_s }
}

puts theme

