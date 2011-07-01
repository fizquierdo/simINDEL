#!/usr/bin/env ruby

require 'fileutils'
require 'rubygems'
require 'trollop'
require 'lib/indelible'

opts = Trollop::options do
  opt :ntaxa, "Number of taxa", :default => 10
  opt :nbases, "Number of base pairs", :default => 10
  opt :modelfile, "GTR data from raxml output", :default => "" 
  opt :indelparams, "POWER LAW [param,trunc,rate]", :default => "1.5,5,0.01" 
  opt :guidetree, "topology to guide the simulation of evol", :default => "" 
end
p opts
# control you have the options you need
raise "Coulnt find Indelible as #{INDELIBLE}" unless File.exists?(INDELIBLE)
indel_params = opts[:indelparams].split(",")
raise "INDEL info must be [param, trunc, rate]" unless indel_params.size == 3

puts "Starting simulation of #{opts[:ntaxa]} taxa and #{opts[:nbases]} base pairs" 
dirname = opts[:ntaxa].to_s + "_taxa"
wdir = "out/#{dirname}"
controlfile = "#{wdir}/control.txt"
FileUtils.mkdir_p(wdir)
cf = IndelibleControlFile.new(controlfile, opts[:ntaxa], opts[:nbases])
cf.load_modelfile(opts[:modelfile]) unless opts[:modelfile].empty?
cf.load_indelparams(indel_params)
cf.tree.newick_str = File.open(opts[:guidetree]).readlines[0].gsub(':0.0;', ";").chomp unless opts[:guidetree].empty?
cf.to_file
#File.open(controlfile).readlines.each {|l| puts l}
Dir.chdir(wdir) do
  system("#{INDELIBLE} #{controlfile}")
end
puts "DONE, alignment TRUE.phy in #{wdir}" 
