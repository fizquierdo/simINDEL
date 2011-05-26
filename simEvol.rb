#!/usr/bin/env ruby
require 'fileutils'
class IndelibleControlFile
  def initialize(filename, ntaxa, nbases)
    insert_rate = 0.001
    controlfile = <<END_OF_CONTROLFILE
    [TYPE] NUCLEOTIDE 1 //  nucleotide simulation using algorithm from method 1

    [MODEL] simple_model
      [submodel]  GTR 0.2 0.4 0.6 0.8 1.2 //  GTR: a=0.2, b=0.4, c=0.6, d=0.8, e=1.2, f=1
      [statefreq] 0.20 0.25 0.25 0.30         //  pi_T, pi_C, pi_A, pi_G
      [indelmodel]  NB 0.5 1
      [insertrate]  #{insert_rate} 
      [deleterate]  #{insert_rate} 

    [TREE] random_tree
      [unrooted] #{ntaxa} 2.4 1.1 0.2566 0.34  // ntaxa birth death sample mut
      [seed] 2381242

    [PARTITIONS] simulated_gene
      [random_tree simple_model #{nbases}] // #base pairs

    [EVOLVE] simulated_gene 1 simulated_alignment
END_OF_CONTROLFILE
    File.open(filename, "w+") do |f|
      f.puts controlfile
    end
    filename
  end
end
# constants
INDELIBLE = "/home/izquiefo/software/indelible/INDELibleV1.03/src/indelible" 
# Generate alignments from random trees of n species and m base pairs
raise "USAGE: ruby #{__FILE__} num_of_species num_of_bps" unless ARGV.size == 2
raise "Coulnt find Indelible as #{INDELIBLE}" unless File.exists?(INDELIBLE)
ntaxa = ARGV[0]
nbases = ARGV[1]

puts "Starting simulation of #{ntaxa} taxa and #{nbases} base pairs" 
dirname = "#{ntaxa}_taxa"
wdir = "out/#{dirname}"
FileUtils.mkdir_p(wdir)
controlfile = IndelibleControlFile.new("#{wdir}/control.txt", ntaxa, nbases)
Dir.chdir(wdir) do
  #system("#{INDELIBLE} #{controlfile}")
end
puts "DONE, alignment TRUE.phy in #{wdir}" 

