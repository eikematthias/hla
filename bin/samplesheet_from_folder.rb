#!/bin/env ruby

require 'optparse'
require 'ostruct'

### Define modules and classes here

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.banner = "Reads Fastq files from a folder and writes a sample sheet to STDOUT"
opts.separator ""
opts.on("-f","--folder", "=FOLDER","Folder to scan") {|argument| options.folder = argument }
opts.on("-s","--sanity", "Perform sanity check of md5 sums") { options.sanity = true }
opts.on("-h","--help","Display the usage information") {
 puts opts
 exit
}

opts.parse! 

abort "Folder not found (#{options.folder})" unless File.directory?(options.folder)

date = Time.now.strftime("%Y-%m-%d")
options.centre ? center = options.centre : center = "IKMB"

fastq_files = Dir["#{options.folder}/*_R*.fastq.gz"]

groups = fastq_files.group_by{|f| f.split("/")[-1].split(/_S[0-9]*_/)[0] }

warn "Building input sample sheet from FASTQ folder"
warn "Performing sanity check on md5sums" if options.sanity

options.platform ? sequencer = options.platform : sequencer = "NovaSeq6000"

puts "patientID;sampleID;libraryID;rgID;R1;R2"

#G00076-L2_S19_L003_R1_001.fastq.gz

individuals = []
samples = []

# group = the library id, may be split across lanes
groups.each do |group, files|

	warn "...processing library #{group}"

	pairs = files.group_by{|f| f.split("/")[-1].split(/_R[1,2]/)[0] }

	pairs.each do |p,reads|

        	left,right = reads.sort.collect{|f| File.absolute_path(f)}
	
		abort "This sample seems to not be a set of PE files! #{p}" unless left && right

		if options.sanity
			Dir.chdir(options.folder) {
				[left,right].each do |fastq|
					fastq_simple = fastq.split("/")[-1].strip
					raise "Aborting - no md5sum found for fastq file #{fastq}" unless File.exists?(fastq_simple + ".md5")
					status = `md5sum -c #{fastq_simple}.md5`
					raise "Aborting - failed md5sum check for #{fastq}" unless status.strip.include?("OK")
				end
			}
		end

		# H26247-L3_S1_L001_R1_001_fastqc.html
        	library = group.split("_S")[0]
        	sample = group.split("_S")[0]
		individual = group.split("-")[0]

		individuals << individual
		samples << sample

        	e = `zcat #{left} | head -n1 `
		header = e

        	instrument,run_id,flowcell_id,lane,tile,x,y = header.split(" ")[0].split(":")

		index = header.split(" ")[-1].split(":")[-1]
        	readgroup = flowcell_id + "." + lane + "." + library 

        	pgu = flowcell_id + "." + lane + "." + index

        	puts "Indiv_#{individual};Sample_#{sample};#{library};#{readgroup};#{left};#{right}"
	end
end


warn "Found: #{individuals.uniq.length} Patients."
warn "Found: #{samples.uniq.length} Samples."
warn "If these numbers do not seem right, please re-check the file naming and manually fix the samplesheet."

