#!/bin/sh
journalctl -ef -b | grep --color=auto -iE "failed login|error|attack|unauth|sudo|passw"
