#!/bin/bash
#more file for this project at
#https://github.com/metalx1000/Radio-Transmissions

echo "Running Command:"
echo "morse2ascii data.wav 2>/dev/null"

echo -e "\nMessage:"
morse2ascii data.wav 2>/dev/null

echo -e "\n\nNote that everything is lower case and there are no new lines."

echo "running command:"
echo "cat data.log|morse"
cat data.log|morse