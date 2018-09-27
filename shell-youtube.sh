LD_LIBRARY_PATH="/usr/lib/phantomjs:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH
export QT_QPA_PLATFORM=offscreen
THISSCRIPT="$(readlink -f $0)"
SCRIPTPATH="$(dirname $THISSCRIPT)"
DOWNLOADPATH="${SCRIPTPATH}"

YouTubeTobeDownload=""
KejIntroLink="http://kej.tw/flvretriever/youtube.php?videoUrl="
LocalJS="${SCRIPTPATH}/save_page.js"
get_video_info="${DOWNLOADPATH}/get_video_info"
# Usage info
show_help() {
cat << EOF

Usage: ${0##*/} [-h] [-v] [-c] [-s Youtube URL source]...
use ${0##*/} utility to download m4a audio from youtube.

    -h              display this help and exit
    -v              verbose mode, show debug messages.
    -c              clean the SCRIPTPATH and exit
    -s SOURCE       source url of the video
    
EOF
}

genLocalJS(){
    cat << EOF > "${LocalJS}"
var system = require('system');
var page = require('webpage').create();
var gvi = require('fs').read(system.args[1]);

page.open(system.args[2], function(status)
{
    var txt = page.evaluate(function(s) {
        document.getElementById('videoInfo').innerHTML=s;
        getYouTubeUrl();
        // return document.getElementById('result_div').innerHTML;
        var tmp = "";
        dllink = document.getElementById('result_div').getElementsByTagName('a');
        for (i = 0; i < dllink.length; i++){
            // if (dllink[i].innerHTML.includes('audio only')){
            if (dllink[i].href.indexOf('mime=audio/mp4') >= 0){
                tmp = tmp /*+ dllink[i].plainText + " "*/ + dllink[i].href + "\n";
            }
        }
        return tmp;
    }, gvi);
     console.log(txt);
    phantom.exit();
});
EOF
}

urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
## JustinPutney ${*//+/ } will replace all + with space and ${_//%/\\x} will replace all % with \x. –
# pi@CISCO:~ $ urldecode() { : "${*}"; echo "${_#*t}"; }
# pi@CISCO:~ $ urldecode "http"
# tp

getElementById_attr_val() {
    local ElementId="${1}"
    local ElementAttr="${2}"
    if [ "x${3:0:4}" = "xhttp" ]; then
        : "$( curl ${3} 2>/dev/null  )"
    else
        : "${3}"
    fi
    : "${_#*$ElementId}";
    : "${_#*$ElementAttr}";
    : "${_#*\"}";
    : "${_%%\"*}";
    echo "${_}"
}

getGetVideoInfo() {
    local kej_full_link="${KejIntroLink}${YouTubeTobeDownload}"
    curl $( getElementById_attr_val \
            "linkVideoInfoURL" \
            "href" \
            "${KejIntroLink}${YouTubeTobeDownload}" \
    ) 2>/dev/null 1> "${get_video_info}"
}

getDownloadTitle() {
    urldecode $( \
    getElementById_attr_val \
            "meta" \
            "\&title\=" \
            "\"${1}" \
    )
}

main(){
    # Dump help if no arguments detected
    if [ $# -lt 1 ]; then
        show_help >&2
        exit 1
    fi

    # Main argument parser
    while getopts "hvs:c" opt; do
        case $opt in
            h)
                show_help
                exit 0
                ;;
            v)  verbose=$((verbose+1))
                ;;
            s)  YouTubeTobeDownload="${OPTARG}"
                ;;
            c)  echo "cleanning ${SCRIPTPATH} ..."
                find "${SCRIPTPATH}" -type f -name "*" ! -name "$(basename $THISSCRIPT)" | xargs rm -f
                exit 0
                ;;
            *)
                show_help >&2
                exit 1
                ;;
        esac
    done 

    shift "$((OPTIND-1))"   # Discard the options and sentinel --
     
    if [ -n "$*" ];then
        echo "${0##*/} : illegal option $@" >&2
        show_help >&2
        exit 1
    fi

    if [ ! -f "${LocalJS}" ]; then
        genLocalJS
    fi

    if ! command -v phantomjs > /dev/null 2>&1 ; then 
        echo "phantomjs does not exist, try"
        echo "    sudo apt-get install phantomjs"
        exit 1
    fi

    if ! command -v aria2c > /dev/null 2>&1 ; then 
        echo "aria2c does not exist, try"
        echo "    sudo apt-get install aria2"
        exit 1
    fi
    
    local kej_full_link="${KejIntroLink}${YouTubeTobeDownload}"
    getGetVideoInfo
    m4aDownloadLink=$( phantomjs "${LocalJS}" "${get_video_info}" "${kej_full_link}" )
    if [ "${#m4aDownloadLink}" -lt 1 ]; then
        echo "This video has no m4a format available to download, exiting..."
        exit 1
    fi
    m4aFilename="$(getDownloadTitle "${m4aDownloadLink}").m4a"
    
    aria2c -x16 -s16 -k 1M -c "${m4aDownloadLink}" -d "${DOWNLOADPATH}" -o "${m4aFilename}"
    exit 0
}

main $*

exit $?
