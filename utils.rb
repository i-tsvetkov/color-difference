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
  # Double quoted strings: /"([^\\"]|\\.)*"/
  # Single quoted strings: /'([^\\']|\\.)*'/
  # Color regex: /#(\h{3}){1,2}\b|\brgba?\([^()]+\)|\bhsla?\([^()]+\)/i
    # hex: /#(\h{3}){1,2}\b/
    # rgb/a: /\brgba?\([^()]+\)/
    # hsl/a: /\bhsla?\([^()]+\)/
  css = css.gsub(/\/\*.*?\*\//m, '')
  css.scan(/([^{}]+)\{(
            (?:[^{}"']|"(?:[^\\"]|\\.)*"|'(?:[^\\']|\\.)*')*
            (?:\#(?:\h{3}){1,2}\b|\brgba?\([^()]+\)|\bhsla?\([^()]+\))
            (?:[^{}"']|"(?:[^\\"]|\\.)*"|'(?:[^\\']|\\.)*')*
          )\}/ix).map do |selector, block|
    rules = block.scan(/(?:[^"';]|"(?:[^\\"]|\\.)*"|'(?:[^\\']|\\.)*')+
                       :(?:[^"';]|"(?:[^\\"]|\\.)*"|'(?:[^\\']|\\.)*')+/ix)
    rules.select!{ |r| r.gsub(/".*"|'.*'/, '').match(/\#(?:\h{3}){1,2}\b|\brgba?\([^()]+\)|\bhsla?\([^()]+\)/i) }
    rules.map!(&:strip)
    { selector: selector.strip, rules: rules }
  end
end

def get_color_css(css)
  get_classes_with_color(css).map do |c|
    ["#{c[:selector]} {\n\t", c[:rules].join(";\n\t"), ";\n}"].join
  end.join("\n\n")
end

def replace_colors(colors, color_rules)
  colors.map do |c|
    color_rules.key?(c[:to].downcase) ?
      { from: c[:from], to: color_rules[c[:to].downcase] } : c
  end
end

