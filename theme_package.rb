#!/Users/andy/.rvm/rubies/ruby-1.9.3-p0/bin/ruby

# Change path above to your ruby path ('which ruby')

require 'erb'
require 'fileutils'

# Add an unindent function to help with HEREDOC syntax
class String
  # Strip leading whitespace from each line that is the same as the
  # amount of whitespace on the first line of the string.
  # Leaves _additional_ indentation on later lines intact.
  def unindent
    gsub /^#{self[/\A\s*/]}/, ''
  end
end

def write_erb(erb_file)
  config = {}
  content = ERB.new(::File.binread(erb_file), nil, '-', '@output_buffer').result(binding)
  File.open(erb_file.sub('.erb', ''), 'w') do |file|
    file << content
  end
  FileUtils.rm(erb_file)
end

output_dir = File.expand_path('~/temp/theme_packages')
themes_dir = File.expand_path('~/repos/themes')

# Iterate through all command-line args
ARGV.each do |theme_path|
  theme_name = theme_path.sub('_pro', '') # 'react'

  # Grab the version number from the last tag
  version = `(cd #{themes_dir}/#{theme_path} && git describe --abbrev=0)`
  # Check if this is a forge theme by looking for the source directory
  is_forge = File.directory?("#{themes_dir}/#{theme_path}/source")
  commands = []

  if is_forge
    current_theme_dir = "#{themes_dir}/#{theme_path}"
    temp_dir_name = ".forge_temp"
    temp_build_dir = "#{current_theme_dir}/#{temp_dir_name}/#{theme_path}"
    sass_output_dir = "#{temp_build_dir}/assets/sass"

    forge_output_file = "#{current_theme_dir}/package/#{theme_path}.#{version.strip}.zip"

    commands << "rm -f #{forge_output_file}"
    commands << "forge build #{temp_build_dir}"
    # Create the directory we'll need to copy the Sass files to, as well as the zip output directory
    commands << "mkdir -p #{sass_output_dir} package"
    # Copy all of the source Sass files into the output directory we just created
    commands << "cp -r #{current_theme_dir}/source/assets/stylesheets/* #{sass_output_dir}"
    # Process each .erb file in the assets/sass directory we just created so we only package finished .scss files
    commands << (proc {
      glob_these = File.join(sass_output_dir, '**', '*.erb' )
      Dir.glob(glob_these).each do |file|
        puts "writing #{file}"
        write_erb(file)
      end
    })
    # Remove WordPress.com-specific stylesheets
    commands << "rm #{sass_output_dir}/_wpdotcom.scss"
    # Add the Compass configuration file to the Sass directory
    commands << (proc {
      File.open("#{sass_output_dir}/config.rb", 'w') do |file|
        file <<<<-DELIM.unindent
          # Require any additional compass plugins here.

          # Set this to the root of your project when deployed:
          http_path = "/"
          css_dir = "../.."
          sass_dir = "."
          images_dir = "../../images"
          javascripts_dir = "../../javascripts"

          # You can select your preferred output style here (can be overridden via the command line):
          # output_style = :expanded or :nested or :compact or :compressed

          # To enable relative paths to assets via compass helper functions. Uncomment:
          # relative_assets = true

          # To disable debugging comments that display the original location of your selectors. Uncomment:
          # line_comments = false


          # If you prefer the indented syntax, you might want to regenerate this
          # project again passing --syntax sass, or you can uncomment this:
          # preferred_syntax = :sass
          # and then run:
          # sass-convert -R --from scss --to sass sass scss && rm -rf sass && mv scss sass
        DELIM
      end
    })
    # Zip up the temporary folder we created
    commands << "cd #{temp_dir_name} && zip -r ../package/#{theme_path}.#{version.strip}.zip #{theme_path}"
    # Copy into the output directory
    commands << "cp -f #{forge_output_file} #{output_dir}/#{theme_path}.#{version.strip}.zip"
    # Remove temp directory we created
    commands << "rm -rf #{temp_dir_name}"
  else
    commands << "git archive --format=zip --output=#{output_dir}/#{theme_path}.#{version.strip}.zip --prefix=#{theme_path}/ master"
  end

  commands.each do |command|
    # String means it's a command-line command
    if command.is_a? String
      `(cd #{themes_dir}/#{theme_path} && #{command})`
      puts "cd #{themes_dir}/#{theme_path} && " + command
    # Otherwise, it's a Ruby proc that we need to run
    else
      command.call
    end
  end
end
