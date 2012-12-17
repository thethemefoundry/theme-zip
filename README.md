theme-zip
=========

This script assumes:

* All your theme repositories are in the same parent folder
* Your **master** branch has been tagged and updated with the latest version (e.g. 2.3.1)
* Your theme repositories are all on the **master** branch.

To use this script:

1. Copy the contents of the `theme_package.rb` file.
2. Update the values for the ruby path, output_dir and themes_dir to match your local setup.
3. `cd` into the folder containing `theme_package.rb` and run:

    ./theme_package.rb anthem react_pro linen_pro

Find a nicely-named ZIP file in the output folder you specified in step 2 and enjoy!

Note: Before you can execute theme_package.rb, you'll need to set permissions to allow execution:

    chmod 755 theme_package.rb
