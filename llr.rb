require 'matrix'

module LLR
  def self.calculate(m)
    2 * (m.to_a.flatten.h - m.row_vectors.map(&:sum).h - m.column_vectors.map(&:sum).h)
  end
  
  def sum
    to_a.inject(0) { |sum, x| x = yield(x) if block_given?; sum ? sum + x : x }
  end
  
  def h
    total = sum.to_f
    sum { |x| x.zero? ? 0 : x * Math.log(x / total) }
  end
end

[Vector, Array].each { |klass| klass.send :include, LLR }
