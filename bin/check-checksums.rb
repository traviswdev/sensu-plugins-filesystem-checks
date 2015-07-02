#! /usr/bin/env ruby
#
#   check-checksums
#
# DESCRIPTION:
#   Check the file against its checksum
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux, BSD
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   AJ Bourg <aj@ajbourg.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'digest'

class Checksum < Sensu::Plugin::Check::CLI
  option :files,
         description: 'Comma separated list of files to check.',
         short: '-f FILES',
         long: '--files FILES',
         required: true

  option :hash,
         description: 'The hash these files must hash as. If unspecified the files will be compared to the first file.',
         short: '-h SHA2HASH',
         long: '--hash SHA2HASH'

  option :warn_only,
         description: "Warn instead of critical if they don't match",
         short: '-w',
         long: '--warn-only',
         boolean: true

  def run
    files = config[:files].split(',')

    if files.length == 1 && !config[:hash]
      unknown 'We have nothing to compare this file with.'
    end

    hashfile = config[:hash] || Digest::SHA2.file(files.first).hexdigest

    # Added this part to allow reading a hash from a premade file
    # i.e. sha256sum filename | awk '{print $1}' > filename.sha256sum
    hash = IO.read(hashfile).chomp

    errors = []

    files.each do |file|
      if File.exist?(file)
        # Added .chomp to make sure newlines don't get in the way of comparisons
        file_hash = Digest::SHA2.file(file).hexdigest.chomp
        errors << "#{file} does not match" if file_hash != hash
      else
        errors << "#{file} does not exist"
      end
    end

    if errors.length > 0 && config[:warn_only]
      warning errors.join("\n")
    elsif errors.length > 0
      critical errors.join("\n")
    else
      ok 'Files match.'
    end
  end
end
