#!/bin/bash

path=$1

echo "#!/bin/bash

" > $1
chmod +x $1

nvim $1
