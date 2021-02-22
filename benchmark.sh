#! /bin/bash

if [ ${#} -lt 1 ] ; then
	echo "Specify benchmark subject."
	exit 1
fi

subject="${1}"
trials=10

if [ ${#} -eq 2 ] ; then
	trials=${2}
fi

timeFormat="time: %E, mem: %M"

bench() {
	program="${1}"
	benchInvokeCmd=$(sed -e 's/.*BENCH''_INVOKE_CMD://;t;d' ${program})
	if [ "x${benchInvokeCmd}" != "x" ] ; then
		echo "Testing program: ${program}..."
		benchBuildCmd=$(sed -e 's/.*BENCH''_BUILD_CMD://;t;d' ${program})
		benchVersionCmd=$(sed -e 's/.*BENCH''_VERSION_CMD://;t;d' ${program})
		if [ "x${benchBuildCmd}" != "x" ] ; then
			${benchBuildCmd}
		fi
		cores=$(nproc)
		for i in $(seq ${trials}) ; do
			core=$((${RANDOM} % ${cores}))
			benchResult=$(echo "" | taskset -c ${core} time -f "${timeFormat}" ${benchInvokeCmd} 2>&1 > /dev/null)
			echo "${benchResult}"
		done
		if [ "x${benchVersionCmd}" != "x" ] ; then
			version=$(sh -c "${benchVersionCmd}")
			echo "program ${program} version: ${version}"
		fi
	fi
}


if [ -d "${subject}" ] ; then
	find "${subject}" \! -path '*/.git*' -a \! -name '*~' -a \! -name '*.swp' -a -type f | while read target ; do
		bench ${target}
	done
elif [ -f "${subject}" ] ; then
	bench ${subject}
else
	echo "Benchmark subject does not exist (${subject})."
	exit 1
fi

