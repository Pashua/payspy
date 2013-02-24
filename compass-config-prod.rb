require "susy"

# This enables debugging stuff for Fire-SASS and SASS-SourceMaps.
# sass_options = { :debug_info => true }

# Set this to the root of your project when deployed:
http_path = "/"

# Set this to the target directory where all CSS and other resource files should copied to.
css_dir = "temp/styles"

# Set this to the source directory (root) of all SCSS.
sass_dir = "src/styles"

# Destination of images.
images_dir = "temp/img"

# Base directory for sprite generators.
sprite_load_path = File.expand_path File.dirname(__FILE__)+"/src/img"

# You can select your preferred output style here (can be overridden via the command line):
output_style = :compressed

# To enable relative paths to assets via compass helper functions. Uncomment:
relative_assets = true

# To disable debugging comments that display the original location of your selectors. Uncomment:
line_comments = false