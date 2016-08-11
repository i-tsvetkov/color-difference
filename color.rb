class Color
  attr_accessor :r, :g, :b, :a

  INTEGER = /\s*([+-]?\d+)\s*/
  NUMBER  = /\s*([+-]?(?:\d*\.\d+|\d+)(?:[eE][+-]?\d+)?)\s*/
  PERCENTAGE = /\s*([+-]?(?:\d*\.\d+|\d+)(?:[eE][+-]?\d+)?)%\s*/

  def initialize(color)
    color = color.strip

    case color

    when /^#\h{8}$/
      @r, @g, @b, @a = color.scan(/\h\h/).map(&:hex)
      @a /= 255.0

    when /^#\h{6}$/
      @r, @g, @b = color.scan(/\h\h/).map(&:hex)

    when /^#\h{4}$/
      @r, @g, @b, @a = color.scan(/\h/).map{ |c| c * 2 }.map(&:hex)
      @a /= 255.0

    when /^#\h{3}$/
      @r, @g, @b = color.scan(/\h/).map{ |c| c * 2 }.map(&:hex)

    when /^rgb\(#{INTEGER},#{INTEGER},#{INTEGER}\)$/
      @r, @g, @b = normalize_colors($~.captures.map(&:to_i))

    when /^rgb\(#{PERCENTAGE},#{PERCENTAGE},#{PERCENTAGE}\)$/
      @r, @g, @b = percentages_to_rgb($~.captures.map(&:to_f))

    when /^hsl\(#{NUMBER},#{PERCENTAGE},#{PERCENTAGE}\)$/
      h, s, l = $~.captures.map(&:to_f)
      @r, @g, @b = hsl_to_rgb(h, s, l)

    when /^rgba\(#{INTEGER},#{INTEGER},#{INTEGER},#{NUMBER}\)$/
      @r, @g, @b = normalize_colors($~.captures.take(3).map(&:to_i))
      @a = normalize_alpha($~.captures.last.to_f)

    when /^rgba\(#{PERCENTAGE},#{PERCENTAGE},#{PERCENTAGE},#{NUMBER}\)$/
      @r, @g, @b = percentages_to_rgb($~.captures.map(&:to_f))
      @a = normalize_alpha($~.captures.last.to_f)

    when /^hsla\(#{NUMBER},#{PERCENTAGE},#{PERCENTAGE},#{NUMBER}\)$/
      h, s, l = $~.captures.take(3).map(&:to_f)
      @a = normalize_alpha($~.captures.last.to_f)
      @r, @g, @b = hsl_to_rgb(h, s, l)

    when 'transparent'
      @r = @g = @b = 0
      @a = 0.0

    when COLOR_NAMES_REGEX
      @r, @g, @b = COLOR_NAMES[color.downcase].scan(/\h\h/).map(&:hex)

    else
      @r = @g = @b = 0

    end

    @a ||= 1.0
  end

  def diff(c)
    # calculating color difference using DeltaE(CIE76)
    l1, a1, b1 = c.to_lab
    l2, a2, b2 = self.to_lab
    deltaE = Math.sqrt((l2-l1)**2 + (a2-a1)**2 + (b2-b1)**2)
    return deltaE
  end

  def self.transform_palette(from_colors, to_colors)
    from_colors = from_colors.map{ |c| { color: Color.new(c), src: c } }
    to_colors   = to_colors.map{ |c| Color.new(c) }
    palette = {}
    from_colors.each do |fc|
      from = fc[:src]
      to   = to_colors.min_by{ |tc| fc[:color].diff(tc) }
      to.a = fc[:color].a
      palette[from] = to.to_s
    end
    return palette
  end

  def light
    l, _, _ = self.to_lab
    return l
  end

  def to_s
    if @a == 1.0
      '#' + [@r, @g, @b].map{ |x| "%02X" % x }.join
    else
      "rgba(#@r,\s#@g,\s#@b,\s#{@a.round(2)})"
    end
  end

  def to_color_name
    COLOR_NAMES.key(self.to_s.downcase)
  end

  def to_xyz
    # conversion from RGB to XYZ
    r, g, b = [@r/255.0, @g/255.0, @b/255.0]

    r = (r > 0.04045) ? ((r+0.055)/1.055)**2.4 : r/12.92
    g = (g > 0.04045) ? ((g+0.055)/1.055)**2.4 : g/12.92
    b = (b > 0.04045) ? ((b+0.055)/1.055)**2.4 : b/12.92

    r *= 100
    g *= 100
    b *= 100

    x = r*0.4124 + g*0.3576 + b*0.1805
    y = r*0.2126 + g*0.7152 + b*0.0722
    z = r*0.0193 + g*0.1192 + b*0.9505

    return [x, y, z]
  end

  def to_lab
    # conversion from XYZ to CIE-L*ab
    x, y, z = self.to_xyz

    x /= 95.047
    y /= 100.000
    z /= 108.883

    x = (x > 0.008856) ? x ** (1.0/3) : (7.787*x) + (16.0/116)
    y = (y > 0.008856) ? y ** (1.0/3) : (7.787*y) + (16.0/116)
    z = (z > 0.008856) ? z ** (1.0/3) : (7.787*z) + (16.0/116)

    l = (116 * y) - 16
    a = 500 * (x - y)
    b = 200 * (y - z)

    return [l, a, b]
  end

  private

  def normalize_color(c)
    [0, [255, c].min].max
  end

  def normalize_percentage(p)
    [0, [100, p].min].max
  end

  def normalize_alpha(a)
    [0.0, [1.0, a].min].max
  end

  def normalize_colors(colors)
    colors.map{ |c| normalize_color(c) }
  end

  def percentages_to_rgb(percentages)
    percentages.map do |p|
      (normalize_percentage(p) * 255/100.0).round
    end
  end

  def hue_to_rgb(v1, v2, vH)
    vH += 1 if vH < 0
    vH -= 1 if vH > 1

    case
      when (6 * vH) < 1
        return (v1 + (v2 - v1) * 6 * vH)
      when (2 * vH) < 1
        return v2
      when (3 * vH) < 2
        return (v1 + (v2 - v1) * (2.0/3 - vH) * 6)
    end

    return v1
  end

  def hsl_to_rgb(h, s, l)
    h = (h % 360) / 360.0
    s = normalize_percentage(s) / 100.0
    l = normalize_percentage(l) / 100.0
    if s == 0
      r = l * 255
      g = l * 255
      b = l * 255
    else
      v2 = (l < 0.5) ? l * (1 + s) : (l + s) - (s * l)
      v1 = 2 * l - v2
      r = 255 * hue_to_rgb(v1, v2, h + (1.0/3))
      g = 255 * hue_to_rgb(v1, v2, h)
      b = 255 * hue_to_rgb(v1, v2, h - (1.0/3))
    end
    return [r, g, b].map(&:round)
  end

  COLOR_NAMES = {"aqua"=>"#00ffff",
                 "aliceblue"=>"#f0f8ff",
                 "antiquewhite"=>"#faebd7",
                 "black"=>"#000000",
                 "blue"=>"#0000ff",
                 "cyan"=>"#00ffff",
                 "darkblue"=>"#00008b",
                 "darkcyan"=>"#008b8b",
                 "darkgreen"=>"#006400",
                 "darkturquoise"=>"#00ced1",
                 "deepskyblue"=>"#00bfff",
                 "green"=>"#008000",
                 "lime"=>"#00ff00",
                 "mediumblue"=>"#0000cd",
                 "mediumspringgreen"=>"#00fa9a",
                 "navy"=>"#000080",
                 "springgreen"=>"#00ff7f",
                 "teal"=>"#008080",
                 "midnightblue"=>"#191970",
                 "dodgerblue"=>"#1e90ff",
                 "lightseagreen"=>"#20b2aa",
                 "forestgreen"=>"#228b22",
                 "seagreen"=>"#2e8b57",
                 "darkslategray"=>"#2f4f4f",
                 "darkslategrey"=>"#2f4f4f",
                 "limegreen"=>"#32cd32",
                 "mediumseagreen"=>"#3cb371",
                 "turquoise"=>"#40e0d0",
                 "royalblue"=>"#4169e1",
                 "steelblue"=>"#4682b4",
                 "darkslateblue"=>"#483d8b",
                 "mediumturquoise"=>"#48d1cc",
                 "indigo"=>"#4b0082",
                 "darkolivegreen"=>"#556b2f",
                 "cadetblue"=>"#5f9ea0",
                 "cornflowerblue"=>"#6495ed",
                 "mediumaquamarine"=>"#66cdaa",
                 "dimgray"=>"#696969",
                 "dimgrey"=>"#696969",
                 "slateblue"=>"#6a5acd",
                 "olivedrab"=>"#6b8e23",
                 "slategray"=>"#708090",
                 "slategrey"=>"#708090",
                 "lightslategray"=>"#778899",
                 "lightslategrey"=>"#778899",
                 "mediumslateblue"=>"#7b68ee",
                 "lawngreen"=>"#7cfc00",
                 "aquamarine"=>"#7fffd4",
                 "chartreuse"=>"#7fff00",
                 "gray"=>"#808080",
                 "grey"=>"#808080",
                 "maroon"=>"#800000",
                 "olive"=>"#808000",
                 "purple"=>"#800080",
                 "lightskyblue"=>"#87cefa",
                 "skyblue"=>"#87ceeb",
                 "blueviolet"=>"#8a2be2",
                 "darkmagenta"=>"#8b008b",
                 "darkred"=>"#8b0000",
                 "saddlebrown"=>"#8b4513",
                 "darkseagreen"=>"#8fbc8f",
                 "lightgreen"=>"#90ee90",
                 "mediumpurple"=>"#9370db",
                 "darkviolet"=>"#9400d3",
                 "palegreen"=>"#98fb98",
                 "darkorchid"=>"#9932cc",
                 "yellowgreen"=>"#9acd32",
                 "sienna"=>"#a0522d",
                 "brown"=>"#a52a2a",
                 "darkgray"=>"#a9a9a9",
                 "darkgrey"=>"#a9a9a9",
                 "greenyellow"=>"#adff2f",
                 "lightblue"=>"#add8e6",
                 "paleturquoise"=>"#afeeee",
                 "lightsteelblue"=>"#b0c4de",
                 "powderblue"=>"#b0e0e6",
                 "firebrick"=>"#b22222",
                 "darkgoldenrod"=>"#b8860b",
                 "mediumorchid"=>"#ba55d3",
                 "rosybrown"=>"#bc8f8f",
                 "darkkhaki"=>"#bdb76b",
                 "silver"=>"#c0c0c0",
                 "mediumvioletred"=>"#c71585",
                 "indianred"=>"#cd5c5c",
                 "peru"=>"#cd853f",
                 "chocolate"=>"#d2691e",
                 "tan"=>"#d2b48c",
                 "lightgray"=>"#d3d3d3",
                 "lightgrey"=>"#d3d3d3",
                 "thistle"=>"#d8bfd8",
                 "goldenrod"=>"#daa520",
                 "orchid"=>"#da70d6",
                 "palevioletred"=>"#db7093",
                 "crimson"=>"#dc143c",
                 "gainsboro"=>"#dcdcdc",
                 "plum"=>"#dda0dd",
                 "burlywood"=>"#deb887",
                 "lightcyan"=>"#e0ffff",
                 "lavender"=>"#e6e6fa",
                 "darksalmon"=>"#e9967a",
                 "palegoldenrod"=>"#eee8aa",
                 "violet"=>"#ee82ee",
                 "azure"=>"#f0ffff",
                 "honeydew"=>"#f0fff0",
                 "khaki"=>"#f0e68c",
                 "lightcoral"=>"#f08080",
                 "sandybrown"=>"#f4a460",
                 "beige"=>"#f5f5dc",
                 "mintcream"=>"#f5fffa",
                 "wheat"=>"#f5deb3",
                 "whitesmoke"=>"#f5f5f5",
                 "ghostwhite"=>"#f8f8ff",
                 "lightgoldenrodyellow"=>"#fafad2",
                 "linen"=>"#faf0e6",
                 "salmon"=>"#fa8072",
                 "oldlace"=>"#fdf5e6",
                 "bisque"=>"#ffe4c4",
                 "blanchedalmond"=>"#ffebcd",
                 "coral"=>"#ff7f50",
                 "cornsilk"=>"#fff8dc",
                 "darkorange"=>"#ff8c00",
                 "deeppink"=>"#ff1493",
                 "floralwhite"=>"#fffaf0",
                 "fuchsia"=>"#ff00ff",
                 "gold"=>"#ffd700",
                 "hotpink"=>"#ff69b4",
                 "ivory"=>"#fffff0",
                 "lavenderblush"=>"#fff0f5",
                 "lemonchiffon"=>"#fffacd",
                 "lightpink"=>"#ffb6c1",
                 "lightsalmon"=>"#ffa07a",
                 "lightyellow"=>"#ffffe0",
                 "magenta"=>"#ff00ff",
                 "mistyrose"=>"#ffe4e1",
                 "moccasin"=>"#ffe4b5",
                 "navajowhite"=>"#ffdead",
                 "orange"=>"#ffa500",
                 "orangered"=>"#ff4500",
                 "papayawhip"=>"#ffefd5",
                 "peachpuff"=>"#ffdab9",
                 "pink"=>"#ffc0cb",
                 "red"=>"#ff0000",
                 "seashell"=>"#fff5ee",
                 "snow"=>"#fffafa",
                 "tomato"=>"#ff6347",
                 "white"=>"#ffffff",
                 "yellow"=>"#ffff00",
                 "rebeccapurple"=>"#663399"}

  COLOR_NAMES_REGEX = Regexp.new('^(' + COLOR_NAMES.keys.join("|") + ')$', 'i')
end
