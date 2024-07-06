#!/bin/bash
# Copyright (c) [2024-2030] [WangGuoqi]
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# Version: 1.0.0
# Last modified: 2024-05-07
# Author: WangGuoQi
# Description: 
# 解析finalcut系列软件导出的xml，将里面关联的素材文件打包导出到指定为止
# 从分场的角度提供管理文件的方法
#修正有些电脑中无法获得正确路径的问题，dirname 命令失效
#修正&符号带来的错误
#230727 修正无法用tar命令压缩某些特殊字符文件
FullPath="$0"
Version=3.0.0
#获取完整路径删除最后的斜杠
ThisPath="${FullPath%[/]*}"
cd "$ThisPath"
echo "当前目录为：`pwd`"
echo "当前目录下文件有："
ls 
printf "\n\n"
clear
echo "当前的软件版本为${Version}"
#$0为包含文件名的文件完整路径
CurrentPrjFullPath="$0"
#获取脚本文件名称并删除路径信息
ProjectTempName="${CurrentPrjFullPath##*/}"
#获取下划线左边的项目名称
ProjectName="${ProjectTempName%[_]*}"
#定义执行拷贝还原到目标宿主机的程序名称
CopyFileName="${ProjectName}_AllFilesCopy.command"
######################################################这里可以更改###############################################
#定义压缩文件包存储位置
FileOutPutPath="/Volumes/${ProjectName}/${ProjectName}/08_Output/07_音乐输出"
#定义刨除的拷贝路径不能出现空行
NotInclude=$(cat  << "EOF"
这里输入不想拷贝的目录的名称，注意此行不能被删除
EOF
)
######################################################这里可以更改###############################################
#定义项目硬盘名称
WorkPath=~/.FasterXMLFilesAbstract
if [[ -d "${WorkPath}" ]];then
:
else
mkdir -p "${WorkPath}"
fi
#echo 清理
#清理临时工作文件夹
rm -rf ~/.FasterXMLFilesAbstract/*

PrjDiskPath="/Volumes/${ProjectName}"
TempDirName="${WorkPath}/`date +%Y-%m-%d_%H-%M-%S`_${RANDOM}_Temp"


mkdir -p "${TempDirName}"

#定义是否只拷贝音频
AudioOrAll=2
exit_delete(){
    rm -rf "${TempDirName}"
    exit 0
}

check_input_params() {
  local -a space_params=() # 初始化一个数组来存储包含空格的参数
  local -a slash_params=() # 初始化一个数组来存储包含斜杠的参数
  local -a colon_params=()  # 包含冒号的参数

  # 遍历所有输入参数
  for arg in "$@"; do
    if [[ "$arg" == *" "* ]]; then
      space_params+=("$arg")
    elif [[ "$arg" == *"/"* ]]; then
      slash_params+=("$arg")
    elif [[ "$arg" == *":"* ]]; then
      colon_params+=("$arg")
    fi
  done

  # 检查是否找到了包含空格、斜杠或冒号的参数
  if [ ${#space_params[@]} -ne 0 ]; then
    echo "以下文件名包含空格："
    for param in "${space_params[@]}"; do
      echo "$param"
    done
  fi

  if [ ${#slash_params[@]} -ne 0 ]; then
    echo "以下文件名包含斜杠："
    for param in "${slash_params[@]}"; do
      echo "$param"
    done
  fi

  if [ ${#colon_params[@]} -ne 0 ]; then
    echo "以下文件名包含斜杠："
    for param in "${colon_params[@]}"; do
      printf "%s" "${param//://}"
        echo 
    done
  fi

  # 如果找到了任何一种无效的参数，则执行退出前删除操作
  if [ ${#space_params[@]} -ne 0 ] || [ ${#slash_params[@]} -ne 0 ] || [ ${#colon_params[@]} -ne 0 ]; then
    echo -e "\033[31mxml文件名包含斜杠或空格，未提取任何文件，请注意检查\033[0m"
    return 1
  else
    
    # 脚本可以继续执行其他操作
    # ...
    return 0
  fi
}
#定义拷贝函数
copyMany(){
#定义旗标变量，判断是否为FCPX的xml文件,默认值为0表示为FCP7的xml文件,2表示为xmld文件
IFFCPXxml_Flag=0
InPutFileName="$1"
if [[ "${InPutFileName##*.}" == fcpxml ]];then
  IFFCPXxml_Flag=1
elif [[ "${InPutFileName##*.}" == fcpxmld ]];then
  IFFCPXxml_Flag=2
else
  IFFCPXxml_Flag=0
  #确认是FCPX的xml文件，旗标变量赋值为1
fi

#echo -e "\033[33m************开始提取 ${InPutFileName} 中的文件:************\033[0m"
#定义输出文件名
OutPutFileName=${InPutFileName%.*}_文件_`date +%Y-%m-%d_%H-%M-%S`

#判断是否存在同名文件夹
if [ ! -d "$OutPutFileName"  ];then
	true
else
	echo "文件夹:$OutPutFileName 已经存在，请重新输入"
	exit 8
fi

#echo "文件夹: $OutPutFileName 即将创建"
if [[ "$IFFCPXxml_Flag" == "0" ]];then
	#如果旗标为0证明是FCP7xml文件,则使用FCP7的文件提取方法
	cat "$InPutFileName" | grep "<pathurl>"|  sed -e '/<name>/d' | sed -e 's#^.*localhost##' |sed -e 's#</path.*$##g' > "${TempDirName}/$OutPutFileName-UnDecoded"
	elif [[ "$IFFCPXxml_Flag" == "2" ]];then
	cat "$InPutFileName/Info.fcpxml" | grep -E "src="  |  sed -e 's#^.*file://##' |sed -e s'#".*$##g' > "${TempDirName}/$OutPutFileName-UnDecoded"
	else
	#如果旗标为1证明是FCPXxml文件,则使用FCPX的文件提取方法
	cat "$InPutFileName" | grep -E "src="  |  sed -e 's#^.*file://##' |sed -e s'#".*$##g' > "${TempDirName}/$OutPutFileName-UnDecoded"
fi

#判断xml文件中是否有有效内容
IfXMLisEmpty=$(cat "${TempDirName}/$OutPutFileName-UnDecoded")
#echo $IfXMLisEmpty
if [[ ! -z $IfXMLisEmpty ]]; then
    true
else   
    printf "\033[31mxml文件中没有有效文件信息，无任何文件拷贝，注意检查\033[0m\n"
    rm -rf "${TempDirName}/$OutPutFileName-UnDecoded"
    return
fi

#文件完整路径信息提取URLdecode文件解码
while read filename;do
printf $(printf "%s" "${filename}" | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')"\n">>"${TempDirName}/$OutPutFileName-Decoded"
done < "${TempDirName}/$OutPutFileName-UnDecoded"
#&符号解码特殊处理有些文件路径名解码后会出现amp;字符,此代码将其全部删除
sed -i "" 's/amp;//g' "${TempDirName}/$OutPutFileName-Decoded"

#判断是否只拷贝音频并处理文件
if [[ "$AudioOrAll" == "2" ]];then
	#sed -i '/\.aif$\|\.AIF$\|\.aiff$\|\.AIFF$\|\.WAV$\|\.MP3$\|\.wav$\|\.mp3$\|\.m4a$/d' "$OutPutFileName-Decoded"
    grep -E '(\.aif|\.AIF|\.aiff|\.AIFF|\.WAV|\.MP3|\.wav|\.mp3|\.m4a)' "${TempDirName}/$OutPutFileName-Decoded" > tmpfile 
    mv tmpfile "${TempDirName}/$OutPutFileName-Decoded"
else
	true
fi

#删掉被排除的路径
while read linea;do
sed -i "" "\#${linea}#d"  "${TempDirName}/$OutPutFileName-Decoded"
done <<< "$(echo  "${NotInclude}")"
#去除空格段首段尾空格
grep -v '^\s*$' "${TempDirName}/$OutPutFileName-Decoded" > "${TempDirName}/$OutPutFileName-SpaceRemoved"


Tips_Ing=文件提取中
Index=1
# 初始化一个空数组来存储不可访问的文件
unprocessable_files=()


#开始正式拷贝文件
while read FullPathAndFileName;do
#获取文件名称
PureName="$(echo "${FullPathAndFileName##*/}")"
#获取文件存储路径,文件的暂存路径和文件的完整路径
DestFilePath=${OutPutFileName}${FullPathAndFileName%/*};
#按格式输出文件名
    if [[ -r "$FullPathAndFileName" ]]; then
        # 文件存在并且可读
        printf "%3s   %-20s  %-40s \n" "${Index}:" "$Tips_Ing" "${PureName}"
        mkdir -p "$DestFilePath"
        ditto "${FullPathAndFileName}" "${DestFilePath}"
        let Index++
                case "${FullPathAndFileName}" in
                    "${PrjDiskPath}"*)
                        true
                        ;;
                    *)
                        echo "${FullPathAndFileName}" >> "./${OutPutFileName}/不在项目硬盘文件列表.txt"
                        ;;
                esac
    else
        # 文件不存在或没有读取权限，将其添加到数组中
        unprocessable_files+=("$FullPathAndFileName")
    fi
done < "${TempDirName}/$OutPutFileName-SpaceRemoved"

#计数
let Index--
NumOfFileList=$(sed -n '$=' "${TempDirName}/$OutPutFileName-SpaceRemoved")
rm -f "${TempDirName}/$OutPutFileName-UnDecoded" "${TempDirName}/$OutPutFileName-SpaceRemoved" "${TempDirName}/$OutPutFileName-Decoded"
#清理临时文件

echo -e "${InPutFileName}中共有\033[32m${NumOfFileList}\033[0m个文件,实际\033[32m${Index}\033[0m个文件拷贝完成"

if [[ ${#unprocessable_files[@]} -ne 0 ]]; then
        echo -e "\033[1;31m以下文件无法访问或不存在请注意检查：\033[0m"
        for file in "${unprocessable_files[@]}"; do
            echo "$file"
        done
else
        echo "所有文件都已成功提取，准备压缩"
fi

if [[ "${Index}" == 0 ]];then
    printf "\033[31m${InPutFileName}中无任何文件拷贝成功，请注意检查xml文档是否有效\033[0m\n"
    
    return 9
else   
    true
fi
#准备目标拷贝程序
touch ./${OutPutFileName}/"${CopyFileName}"
cat > ./${OutPutFileName}/"${CopyFileName}"<< "EOF"
#!/bin/bash
#修正了文件名中含有多个空格的问题
FullPath="$0"
ThisPath="${FullPath%[/]*}"
cd "$ThisPath"
echo
echo "当前目录为：`pwd`"

CurrentPrjFullPath="$0"

ProjectTempName="${CurrentPrjFullPath##*/}"

#echo $ProjectTempName

ProjectName="${ProjectTempName%[_]*}"
#echo $ProjectName



DiskPath=/Volumes/"${ProjectName}"
echo
if [ ! -d "${DiskPath}"  ];then

echo "目标磁盘不存在，请插入名称为${ProjectName}的硬盘"
exit
elif [ -d "${DiskPath} 1"  ];then
echo "存在两块或以上的名称为:${ProjectName}的硬盘，"
echo "请弹出多余磁盘，确保只有一块目标磁盘挂载，否则无法正常拷贝！"
echo

exit
fi

#ls -l
echo

#定义函数
Tips_Skip="文件已经存在跳过拷贝"
Tips_Ing="拷贝中"
ShowName=showname

exist_num=0
copy_num=0

find ./Volumes/"${ProjectName}"/* -type f |sed -e '/.DS_Store/d'| sed -e '/filetreecopy.sh/d' > filelist.txt

#cat filelist.txt | sed -e "s#^./#$1/#"  > finallist.txt
sum=$(sed -n '$=' filelist.txt)
echo 共计有${sum}个文件准备拷贝
index=1
while read filepath;do
DestFileName=$(printf "%s" "$filepath" | sed -e "s#^.##")
SourceFileName=$(printf "%s" "$filepath" | sed -e "s#^.#$ThisPath#")
DestDir=${DestFileName%/*}
ShowName="$(echo "${DestFileName##*/}")"
#echo $SourceFileName
#echo $DestDir


		if [ -d "$DestDir"  ];then

			if [ ! -f "$DestFileName"  ];then
				printf "%3s   %-30s  %-40s \n" "${index}:" "$Tips_Ing" "${ShowName}" 
  				cp -a "${SourceFileName}" "${DestDir}"
				let copy_num++
				let index++
				#echo 不存在将拷贝
			else
				#echo -e "${index}:${DestFileName##*/}\t\t\t"文件已经存在跳过拷贝
				
				
				printf "%3s   %-30s \t %-1s \n" "${index}:" "$Tips_Skip" "${ShowName}"  
				let exist_num++
				let index++
				
			
			fi

		else
  			mkdir -p "$DestDir"
			  printf "%3s   %-30s  %-40s \n" "${index}:" "$Tips_Ing" "${ShowName}" 
			  #echo "${index}:${DestFileName##*/}  "拷贝中
			cp -a "${SourceFileName}" "${DestDir}"
			let copy_num++
			let index++
			#echo $destdir
			#echo $filename
		fi

done < filelist.txt
echo
echo 跳过${exist_num}个文件
echo 实际共拷贝${copy_num}个文件
echo
echo

rm  -rf "${ThisPath}"

rm -rf filelist.txt
EOF
chmod +x ./${OutPutFileName}/"${CopyFileName}"
#为拷贝程序赋予执行权限
#目标拷贝程序准备结束

#230727

echo "开始压缩文件："
DIRECTORY_TO_COMPRESS="${OutPutFileName}"

# 输出的 ZIP 文件名
OUTPUT_ZIP="${OutPutFileName}.zip"

# 开始压缩，并在后台运行
zip -rq "$OUTPUT_ZIP" "$DIRECTORY_TO_COMPRESS" &

# 获取压缩进程的 PID
ZIP_PID=$!

# 显示红色闪烁的提示信息
function show_waiting_message {
    while kill -0 $ZIP_PID 2>/dev/null; do
        # ANSI 转义代码：红色
        echo -ne "\r\033[31m压缩中\r\033[0m"
        
        # 清除当前行的文本
		sleep 1
        echo -ne "\r\033[31m请等待\r\033[0m"
		sleep 1
		echo -ne "\r              \r"
    done
}

# 在另一个后台进程中显示等待信息
show_waiting_message &
# 等待压缩进程结束
wait $ZIP_PID
# 使用 ANSI 转义代码：绿色
echo -ne "\r              \r"
echo -e "\033[32m压缩完成！\033[0m"
#检测输出文件夹是否存在如果没有则创建
if [ -d "${FileOutPutPath}"  ];then
  true
else
  mkdir -p "${FileOutPutPath}"
fi
#230727
#230727	tar -czvf ${OutPutFileName}.tar.gz ${OutPutFileName}
mv ${OutPutFileName}.zip "${FileOutPutPath}"
#将压缩文件移动到目标地址
rm -rf ${OutPutFileName}
#删除临时文件夹
echo -e "输出文件压缩包在${FileOutPutPath}"
#osascript -e 'beep'
#osascript -e 'beep'
#osascript -e 'display dialog "音乐提取完毕，请注意查看！"'
#echo -e "\033[32m************${InPutFileName}文件提取完毕，请注意查看！************\033[0m"
echo
echo
open "${FileOutPutPath}"

}

#准备拷贝
number=65       #定义一个退出值

#如果有输入参数
IFxmlFileList="`ls | awk '{print $0}'`" 

#统计xml文件数量
XMLNum=0
while read XmlFile;do
        if [[ "$XmlFile" == *.xml ]] || [[ "$XmlFile" == *.fcpxml ]] || [[ "$XmlFile" == *.fcpxmld ]];then
                echo $XmlFile
                let XMLNum++
        else
                true
        fi
done <<< "$(echo "$IFxmlFileList")"

#未发现xml文件
if [[ "$XMLNum" == 0 ]] ;then
        clear
        echo -e "\033[31m未发现任何可用xml文件，请将xml文件放入此文件夹中\033[0m"
        exit 8
else
        #发现xml文件
        echo '************请注意当前文件夹内有以上' $XMLNum '个xml文件************'
        echo
        # 显示提示信息
        echo -e "请在 \033[31m10秒\033[0m 内输入一个数字\033[32m（1-2）\033[0m选择相应选项，\033[32m默认选项为2\033[0m:"
        echo -e "1 - 拷贝全部文件"
        echo -e "\033[32m2 - 拷贝音频文件(默认选项)\033[0m"

        # 设置超时时间
        timeout=10

        # 设置默认选项
        default_choice=2

        # 循环直到用户选择1或2，或者超时
        while true; do
            # 提示用户输入
            echo "请输入相应数字选择:"

            # 使用read命令等待用户输入，设置超时
            read -t $timeout -r input

            # 检查read命令的返回状态
            if [ $? -ne 0 ]; then
                # 超时或用户直接按Enter键
                #echo "输入超时，默认选择$default_choice"
                    echo -e "输入超时，默认选择\033[32m2.拷贝音频文件\033[0m"
                    AudioOrAll=2
                break
            else
                # 检查用户输入
                case $input in
                    1)
                       AudioOrAll=1
                        echo -e "你选择了\033[33m1.拷贝全部文件\033[0m"
                        break
                        ;;
                    2)
                        AudioOrAll=2
                        echo -e "你选择了\033[32m2.拷贝音频文件\033[0m"
                        break
                        ;;
                    "")
                        # 用户直接按Enter键，没有输入任何内容
                        echo "直接回车，默认选择2"
                        AudioOrAll=2
                        break
                        ;;
                    *)
                        echo "输入无效，请输入1或2。"
                        ;;
                esac
            fi
        done
        
        countdown=5

        #read -p "${countdown}秒内开始拷贝" -t $countdown  wait_input
        
        

        echo "${countdown}秒内开始拷贝"

        # 循环打印倒计时
        while [ $countdown -gt 0 ]; do
            echo $countdown...
            sleep 1
            ((countdown--))
        done

        echo "开始拷贝"
        clear
        #开始拷贝
        NumOfXml=1
        while read XmlFile;do
                if [[ "$XmlFile" == *.xml ]] || [[ "$XmlFile" == *.fcpxml ]] || [[ "$XmlFile" == *.fcpxmld ]];then
                        #echo -e "\033[33m************开始提取 ${XmlFile} 中的文件:************\033[0m"
                        echo -e "提取第${NumOfXml}个${XmlFile}中的文件:"
                        if check_input_params "$XmlFile"; then
                        :
                        else
                        echo
                        let  NumOfXml++
                        continue
                        fi
                        copyMany "$XmlFile"
                        echo -ne "\r              \r"
                        echo
                        echo -ne "\r              \r"
                        let  NumOfXml++
                else
                        true
                fi
        done <<< "$(echo "$IFxmlFileList")"
#发现xml文件循环结束
fi

echo -e "\033[32m使用中有问题可到我的知乎留言\033[0m"
echo -e "\033[32m文件提取结束程序退出\033[0m"

exit_delete