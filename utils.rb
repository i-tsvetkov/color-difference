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

# Return the CSS classes with color inside them
# Does NOT WORK with NESTED rules (e.g. @media)
def get_classes_with_color(css)
  # Double quoted strings: /"([^"]|\")*"/
  # Single quoted strings: /'([^']|\')*'/
  # Color regex: /#(\h{3}){1,2}\b|\brgba?\([^()]+\)|\bhsla?\([^()]+\)/i
    # hex: /#(\h{3}){1,2}\b/
    # rgb/a: /\brgba?\([^()]+\)/
    # hsl/a: /\bhsla?\([^()]+\)/
  css.scan(/[^{}]+\{
            (?:[^{}"']|"(?:[^"]|\")*"|'(?:[^']|\')*')*
            (?:\#(?:\h{3}){1,2}\b|\brgba?\([^()]+\)|\bhsla?\([^()]+\))
            (?:[^{}"']|"(?:[^"]|\")*"|'(?:[^']|\')*')*
           \}/ix)
end

