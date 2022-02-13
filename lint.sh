#!/bin/sh

MINT="/usr/bin/env mint"

$MINT run swiftformat --lint --config .swiftformat .

formatstatus=$?

$MINT run swiftlint lint

lintstatus=$?

if [ $formatstatus -ne 0 ] || [ $lintstatus -ne 0 ]; then
	exit 1
fi
