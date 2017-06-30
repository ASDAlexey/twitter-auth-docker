#!/bin/bash
echo "Are you sure to proceed?"
	select yn in "Yes" "No"; do
	case $yn in
		Yes ) break;;
		No ) exit 130;;
	esac
done

