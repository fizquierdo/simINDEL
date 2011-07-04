#!/usr/bin/env ruby

require 'fileutils'
require 'rubygems'
require 'trollop'
require 'lib/indelible'

opts = Trollop::options do
  opt :ntaxa,               "Number of taxa",             :default => 10
  opt :nbases,              "Number of base pairs",       :default => 10
  opt :modelfile,           "GTR data from raxml output", :default => "" 
  opt :indelparams,         "POWER LAW [#{IMKEYS.join ','}]",:default => IMKEYS.map{|s| INDEL_MODEL_PARAMS[s.to_sym]}.join(",") 
  opt :guidetree,           "guide to simulate of evol",  :default => "" 
  opt :birth_death_params,  "[#{BDKEYS.join(",")}]",      :default => BDKEYS.map{|s| BDPARAMS[s.to_sym]}.join(",")
end
p opts
# control you have the options you need
raise "Coulnt find Indelible as #{INDELIBLE}" unless File.exists?(INDELIBLE)
puts "Starting simulation of #{opts[:ntaxa]} taxa and #{opts[:nbases]} base pairs" 
dirname = opts[:ntaxa].to_s + "_taxa"
wdir = "out/#{dirname}"
controlfile = "#{wdir}/control.txt"
FileUtils.mkdir_p(wdir)

# generate control file
cf = IndelibleControlFile.new(controlfile, opts[:ntaxa], opts[:nbases])
cf.load_modelfile(opts[:modelfile]) unless opts[:modelfile].empty?
cf.load_indel_params(opts[:indelparams]) unless opts[:indelparams].empty?
if opts[:guidetree].empty?
  cf.load_birth_death_params(opts[:birth_death_params])
else
  cf.load_newick_str(File.open(opts[:guidetree]).readlines[0].gsub(':0.0;', ";").chomp)
end
cf.to_file

#File.open(controlfile).readlines.each {|l| puts l}
Dir.chdir(wdir) do
  system("#{INDELIBLE} #{controlfile}")
end
puts "DONE, alignment TRUE.phy in #{wdir}" 
