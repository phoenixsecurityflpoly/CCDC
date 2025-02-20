#!/bin/sh
random() {
    tr -dc "A-Za-z0-9" </dev/urandom | head -c 32
}

admins="
root
blueteam
alan.chen
anna.wilson
emily.chen
jack.harris
jeremy.rover
john.taylor
laura.harris
matthew.taylor
maxwell.starling
melissa.chen
william.wilson
"

regulars="
alan.harris
alan.taylor
amy.taylor
amy.wilson
ashley.lee
chris.harris
christine.wilson
danielle.wilson
dave.harris
emily.lee
heather.chen
james.taylor
jeff.taylor
julie.wilson
kathleen.chen
mark.wilson
michael.chen
rachel.harris
rachel.wilson
sarah.taylor
sharon.harris
terry.chen
terry.wilson
tiffany.harris
tiffany.wilson
tom.harris
tony.taylor
"

for user in $admins $regulars; do
    pass="$(random)"
    echo "$user:$pass"
    echo "$user:$pass" | chpasswd
done

for user in $regulars; do
    gpasswd -d "$user" wheel
done
