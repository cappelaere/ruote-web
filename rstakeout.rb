#!/usr/local/bin/ruby -w

##
# Modified from http://www.pragmaticautomation.com/cgi-bin/pragauto.cgi/Monitor/StakingOutFileChanges.rdoc
#
# Watches files and runs a command when any of them are modified.
#
# If one argment is given, will run that command and watch app, lib, test, spec.
#
#   rstakeout "ruby test/functional/models/order.rb"
#   => watches app/**/* lib/**/* test/**/* spec/**/* stories/**/*
#
# Can use Ruby's Dir[] to get file glob. Quote your args to take advantage of this.
#
#  rstakeout 'rake test:recent' **/*.rb
#  => Only watches Ruby files one directory down
#
#  rstakeout 'rake test:recent' '**/*.rb'
#  => Watches all Ruby files in all directories and subdirectories

def growl(title, msg, img, pri=0, sticky="")
  system "growlnotify -n autotest --image ~/.autotest_images/#{img} -p #{pri} -m #{msg.inspect} #{title} #{sticky}"
end

def self.growl_fail(output)
  growl "FAIL", "#{output}", "fail.png", 2
end

def self.growl_pass(output)
  growl "Pass", "#{output}", "pass.png"
end

command = ARGV.shift
file_patterns_to_watch = (ARGV.length > 0 ? ARGV : ['app/**/*', 'config/**/*', 'lib/**/*', 'test/**/*', 'spec/**/*', 'stories/**/*'])

files = {}

file_patterns_to_watch.each do |arg|
  Dir[arg].each { |file|
    files[file] = File.mtime(file)
  }
end

puts "Watching #{files.keys.join(', ')} [#{files.keys.length}]\n\n"
puts "Will run: #{command}\n\n"

trap('INT') do
  puts "\nQuitting..."
  exit
end


loop do

  sleep 1

  changed_file, last_changed = files.find { |file, last_changed|
    File.mtime(file) > last_changed
  }

  if changed_file
    files[changed_file] = File.mtime(changed_file)
    puts "=> #{changed_file} changed, running #{command}"
    results = `#{command}`
    puts results

    if results.include? 'tests'
      output = results.slice(/(\d+)\s+tests?,\s*(\d+)\s+assertions?,\s*(\d+)\s+failures?(,\s*(\d+)\s+errors)?/)
      if output
        $~[3].to_i + $~[5].to_i > 0 ? growl_fail(output) : growl_pass(output)
      end
    else
      output = results.slice(/(\d+)\s+examples?,\s*(\d+)\s+failures?(,\s*(\d+)\s+not implemented)?/)
      if output
        $~[2].to_i > 0 ? growl_fail(output) : growl_pass(output)
      end
    end

    puts "=> done"
  end

end
