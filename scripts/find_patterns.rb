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
end

p = Phylip.new phy
#p.shorten_seqs!(new_width)
#p.save_as(phy + "_w#{new_width}")

patterns = p.find_unique_patterns
num_patterns  = patterns.transpose.size 
raise "new width #{new_width} must be smaller than available patterns #{num_patterns}" unless new_width.to_i < num_patterns.to_i

puts "#{p.seqs.size} #{new_width}"
p.seqs.each_with_index do |seq,i|
  name, content = seq.split
  seqpatterns = patterns[i].join
  puts "#{name} #{seqpatterns[0...new_width.to_i]}" 
end




