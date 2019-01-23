# encoding: utf-8
#!/usr/bin/ruby
require 'xcodeproj'
plist_path = './FastLaneTestDemo/Info.plist'
plistHash = Xcodeproj::Plist.read_from_path(plist_path) #读取工程plist配置文件
if ARGV.size != 3
    puts "error:The params number is not match with 3"
    else
    plistHash['CFBundleDisplayName'] = ARGV[0] #appName
    plistHash['CFBundleIdentifier'] = ARGV[1] #bundleID
    plistHash['CustomDomainName'] = ARGV[2] #正式域名
    Xcodeproj::Plist.write_to_path(plistHash, plist_path) #覆盖修改工程plist配置文件
    puts "success!"
end
