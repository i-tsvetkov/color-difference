class Color
  attr_accessor :r, :g, :b

  def initialize(rgb_hex)
    @r, @g, @b = rgb_hex.scan(/\h\h/).map(&:hex)
  end

  def diff(c)
    # calculating color difference using DeltaE(CIE76)
    l1, a1, b1 = c.to_lab
    l2, a2, b2 = self.to_lab
    deltaE = Math.sqrt((l2-l1)**2 + (a2-a1)**2 + (b2-b1)**2)
    return deltaE
  end

  def to_s
    '#' + [@r, @g, @b].map{ |x| "%02X" % x }.join
  end

  def to_xyz
    # conversion from RGB to XYZ
    r, g, b = [self.r/255.0, self.g/255.0, self.b/255.0]

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
end
