 : "${*// /+}"
linkYouTubeSearch1="https://www.youtube.com/results?search_query=${_}"

if [ ! -z "${linkYouTubeSearch1}" ]; then
    lynx -dump -listonly -nonumbers ${linkYouTubeSearch1} | grep watch |sort -u |grep -v list >list.list
fi
