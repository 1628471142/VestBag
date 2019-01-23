# encoding: utf-8
#!/usr/bin/ruby
require 'xcodeproj'
plist_path = './ExportOptions.plist'
plistHash = Xcodeproj::Plist.read_from_path(plist_path) #读取工程plist配置文件

plistHash['method'] = ARGV[0] #method
plistHash['signingCertificate'] = ARGV[1] #signingCertificate
plistHash['teamID'] = ARGV[2] #teamID
plistHash['provisioningProfiles'] = {ARGV[3] => ARGV[4]}
Xcodeproj::Plist.write_to_path(plistHash, plist_path) #覆盖修改工程plist配置文件
