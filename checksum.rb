require "fileutils"
require "digest/sha2"

# The curled script is pinned to a specific git commit **and** should remain so
# Update this ruby file when the script is updated and generate a new checksum.

unless File.exist?("prepare-core.sh")
  if !`which #{"curl"}`.empty?
    `curl -O https://raw.githubusercontent.com/GPGTools/GPGTools_Core/a6e90fa999a930/newBuildSystem/prepare-core.sh`
  elsif !`which #{"wget"}`.empty?
    `wget https://raw.githubusercontent.com/GPGTools/GPGTools_Core/a6e90fa999a930/newBuildSystem/prepare-core.sh`
  else
    puts "No download tool available! You must have cURL or wget available."
  end
end

if !File.exist?("prepare-core.sh")
  puts "Expected file does not exist. Please check your connection and try again."
else
  actual_checksum = Digest::SHA2.hexdigest( File.read("prepare-core.sh") )
  expected_checksum = "b84ceddd3c858bf72e7a5263fd8c67bd9dfe778e4b59a59c071ed772143418cd"

  puts "Expected Checksum = #{expected_checksum}"
  puts "Actual Checksum = #{actual_checksum}"

  if actual_checksum.include? expected_checksum
    puts "Secure Checksum Verification Successful"
    FileUtils.chmod 0755, "prepare-core.sh"
    system "bash", "-c", "./prepare-core.sh"
  else
    puts "Secure Checksum Verification Failed! DANGER!"
    FileUtils.rm_f "prepare-core.sh"
    exit 1
  end
end