#!/bin/bash
echo "Finding SUID Files"
find / -perm -u=s -type f -exec ls -la {} \; 2>/dev/null

echo "Finding SGID Files"
find / -perm -g=s -type f -exec ls -la {} \; 2>/dev/null
