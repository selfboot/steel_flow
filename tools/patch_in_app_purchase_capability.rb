#!/usr/bin/env ruby
# XcodeGen 2.46 cannot serialize nested SystemCapabilities dictionaries.
# Patch the generated target metadata until the upstream issue is fixed.

path = File.expand_path("../SteelFlow.xcodeproj/project.pbxproj", __dir__)
contents = File.read(path)

target = contents.match(/^\s*([A-F0-9]{24}) \/\* SteelFlow \*\/ = \{\n\s*isa = PBXNativeTarget;/)
abort "error: SteelFlow native target was not found" unless target
target_id = target[1]

attributes_start = contents.index("\n\t\t\t\tTargetAttributes = {")
abort "error: TargetAttributes block was not found" unless attributes_start
attributes_end = contents.index("\n\t\t\t\t};", attributes_start + 1)
abort "error: TargetAttributes block is malformed" unless attributes_end

prefix = contents[0...attributes_start]
attributes = contents[attributes_start...attributes_end]
suffix = contents[attributes_end..]

entry_pattern = /(\n\t\t\t\t\t#{target_id} = \{\n)(.*?)(\n\t\t\t\t\t\};)/m
entry = attributes.match(entry_pattern)
abort "error: SteelFlow target attributes were not found" unless entry

unless entry[2].include?("com.apple.InAppPurchase")
  capability = <<~PBX.chomp
    \t\t\t\t\t\tSystemCapabilities = {
    \t\t\t\t\t\t\tcom.apple.InAppPurchase = {
    \t\t\t\t\t\t\t\tenabled = 1;
    \t\t\t\t\t\t\t};
    \t\t\t\t\t\t};
  PBX
  replacement = entry[1] + entry[2] + "\n" + capability + entry[3]
  attributes = attributes.sub(entry_pattern, replacement)
end

File.write(path, prefix + attributes + suffix)
