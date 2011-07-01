#!/usr/bin/env ruby
#
# Takes a phylip an outputs a fasta alignment
# One repeated sequence will be removed from


unless ARGV.size == 1 then
  puts "Usage: #{$0} phylipfile "
  exit
end
phylip = ARGV[0]
raise "No Phylip File" unless File.exists?(phylip)
lno = 1
seq = String
name = String
File.open(phylip,"r").each_line do |line|
  if lno == 1 then
  else
    res = line.split.map{|s| s.to_s}
    name = res[0]
    seq = res[1]
    if name and name.length > 0 and seq and seq.length >0 then
      puts ">" << name.strip
      puts seq.strip
    else
      #raise "Name of seq missing in line #{lno}"
    end
  end
  lno += 1
end
