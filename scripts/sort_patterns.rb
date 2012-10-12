#!/usr/bin/env ruby
#
require 'rphylip'

# finds patterns (unique columns) and prints a new phylip file of given width containing only patterns
usage = "$0 phylip_file num_patterns"
raise usage unless ARGV.size == 2

phy = ARGV[0]
new_width = ARGV[1]

class Phylip
  attr_accessor :seqlen
  def shorten_seqs!(width)
    @seqs.map! do |seq|
      name, content = seq.split  
      name.to_s + " " + content[1..width.to_i].to_s
    end
    @seqlen = width.to_s
  end
  def find_unique_patterns
    seqs = []
    @seqs.each do |seq|
      name, content = seq.split
      seqs << content.split(//)
    end
    seqs.transpose.uniq.transpose
  end
  def find_unique_patterns_and_sort
    self.find_unique_patterns.transpose.sort.transpose.map{|a| a.join}
  end
end

p = Phylip.new phy

p.find_unique_patterns_and_sort.each do |pat|
  puts pat
end





