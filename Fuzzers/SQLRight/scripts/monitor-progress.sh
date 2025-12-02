#!/bin/bash
echo "monitor fuzzing progress..."
watch -n 10 "ls -la /home/sqlite/fuzzing/fuzz_root/outputs/ | wc -l"
