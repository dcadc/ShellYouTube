listDownload(){
    while IFS='' read -r line || [[ -n "${line}" ]]; do
	    export line
	    # ionice ./shell-youtube.sh -s "${line}"
		./shell-youtube.sh -s "${line}"
    done < list.list
}
