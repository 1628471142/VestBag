#!/bin/bash
# 判断上一次的wget-log日志文件是否存在，存在则删除
wget_log_file="./wget-log"
if [ -f "$wget_log_file" ]; then
rm -rf $wget_log_file
fi

## 方便直接指定源文件夹，可以直接运行shell脚本
#cd /Users/a1/Desktop/Shell脚本

echo -e "请选择需要打包的任务代号\n任务：1 任务：2"

read task_id

if [ $task_id -ne "2" ] && [ $task_id -ne "1" ]; then
echo "******************提示：任务id不在可选范围内，默认打包第1条任务********************"
task_id="1"
fi

# =========================================固定参数=============================================
# 主机名称
user=`whoami`
# p12密码
p12_psw=''
# 钥匙串密码
keychain_psw='  '

# 工程名称
project_name="FastLaneTestDemo"

# .ipa文件打包缓存文件目录
tmp_dir="ipa_tmp"

# .ipa最终生成输出目录
ipa_dir="ipa"

# 配置plist
option_plist="ExportOptions.plist"

# =========================================请求参数=========================================
# 请求客户上传的参数
json_url="https://github.com/1628471142/BreadgeGame/raw/master/buildTest$task_id.json"
# wget -O ./configInfo.json $json_url
# 从网络直接读取
# json=`curl $url | jq '.'`
# 或者从网络下载json文件，从本地读取
#json=`cat configInfo.json`

# app名称
app_name=`cat configInfo.json | jq -r .app_name`
# 项目bundleID
bundleID=`cat configInfo.json | jq -r .bundle_id`
# 正式ip或域名
customDomainName=`cat configInfo.json | jq -r .customDomainName`
# 打包类型
method=`cat configInfo.json | jq -r .method`
# 证书类型开发或生产
cert_type='iPhone Distribution'

# 证书文件网络地址
cert_url=`cat configInfo.json | jq -r .cert_download_url`
# 描述文件网络地址
provisioning_url=`cat configInfo.json | jq -r .provisioning_download_url`
# logo资源文件网络地址
app_logo=`cat configInfo.json | jq -r .app_logo`

# 可选参数
# 版本号,CFBundleShortVersionString
version='1.0.1'
# 构建id,CFBundleVersion
build_id='1'
# 极光appkey
JPushKey=''
# 测试ip
testDomainName='' # 判断是否为空 ${#project_name}

# 运行ruby脚本替换info.plist中需要更换的参数
ruby info.rb $app_name $bundleID $customDomainName

# =========================================需要的资源文件下载及下载完成后的操作=========================================
# 描述文件
wget -O ./Download/AdhocProfile/AdHoc.mobileprovision $provisioning_url
# 生产证书
wget -O ./Download/DistributionCer/Distribution.p12 $cert_url
# AppLogo图片资源
wget -O ./Download/AppIcon/AppIcon.appiconset.zip $app_logo
# 解压下载的AppLogo至指定目录
unzip -o ./Download/AppIcon/AppIcon.appiconset.zip -d ./Download/AppIcon -x __MACOSX/*
# 替换原项目中的AppLogo文件
cp -a "./Download/AppIcon/AppIcon.appiconset/" "./$project_name/Assets.xcassets/AppIcon.appiconset/"

# 获取描述文件的UUID
mobileprovision_file="./Download/AdhocProfile/AdHoc.mobileprovision"
mobileprovision_uuid=`/usr/libexec/PlistBuddy -c "Print UUID" /dev/stdin <<< $(/usr/bin/security cms -D -i $mobileprovision_file)`
mobileprovision_teamID=`/usr/libexec/PlistBuddy -c "Print TeamIdentifier:0" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`
mobileprovision_teamname=`/usr/libexec/PlistBuddy -c "Print TeamName" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`
mobileprovision_Name=`/usr/libexec/PlistBuddy -c "Print Name" /dev/stdin <<< $(security cms -D -i $mobileprovision_file)`

# 解锁钥匙串，预设密码
security unlock-keychain -p $keychain_psw /Users/$user/Library/Keychains/login.keychain
# 导入p12证书到钥匙串
security import ./Download/DistributionCer/Distribution.p12 -k /Users/$user/Library/Keychains/login.keychain -P "$p12_psw" -T /usr/bin/codesign
# 导入描述文件
cp -a ${mobileprovision_file} ~/Library/MobileDevice/Provisioning\ Profiles/${mobileprovision_uuid}.mobileprovision

# 运行ruby脚本替换ExportOptions.plist中需要更换的参数 ps:加引号为了防止入参中存在空格，被识别为多个参数
ruby option.rb $method "$cert_type" $mobileprovision_teamID $bundleID "$mobileprovision_Name"


# archive 打包
xcodebuild archive -scheme $project_name -configuration Release -archivePath $tmp_dir/target.xcarchive CONFIGURATION_BUILD_DIR=$tmp_dir CODE_SIGN_IDENTITY="$cert_type: $mobileprovision_teamname" PROVISIONING_PROFILE=$mobileprovision_uuid PRODUCT_BUNDLE_IDENTIFIER="$bundleID"

# export 导出ipa包到$ipa_dir/$project_name.ipa
xcodebuild -exportArchive -archivePath $tmp_dir/target.xcarchive -exportPath $ipa_dir -exportOptionsPlist $option_plist

# move ipa & rename 移动和重命名生成的.ipa文件
mv $ipa_dir/"$project_name.ipa" $ipa_dir/$app_name.ipa

echo "--------build Finished: " $app_name

# clear temps 清除缓存文件夹
rm -rf $tmp_dir


# =========================================上传ipa=========================================
# 传输命令
ftp_user="test1"
ftp_host="45.40.253.117"
ftp_passwd="user2019"
ftp_port="22"
# 当前完整路径
cur_complete_file=`pwd`
# 待上传文件完整目录
location_file="$cur_complete_file/ipa/$app_name.ipa"
# 服务器已指定当前用户的根目录，测试指定目录为/usr/Ftptest
promote_file="./"
# 转码
#iconv -f UTF-8 -t GBK $location_file -o $location_file
# sftp连接服务器
expect<<-END
spawn sftp $ftp_user@$ftp_host
expect {
"(yes/no)?" {
send "yes\r"
}
"*assword:" {send "${ftp_passwd}\r"}
}
expect "sftp>"
# 上传命令
send "put $location_file $promote_file\r"
expect "sftp>"
send "quit\r"
END
echo "上传结束"

## post方式上传表单（缺点：可上传文件的大小受限）
#post_file="./ipa/$app_name.ipa"
#curl -F "upload=@$post_file" -F "type=ipa" "https://www.vduan.top/file/upload"

# 注意：当前是以app名称命名的ipa文件。其中可能包含中文，sftp命令不支持，ftp默认的文件名编码方式为GBK，iso-8859-1。且sftp目前暂未找到开放的方法修改文件名编码方式，故后边用app代号来命名ipa文件名
